/*
 * Author: https://t.me/twisternick
 *
 * Last update: 27.05.2019
 *
 */

#include <amxmodx>
#include <reapi>
#include <shopapi>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.2";

/****************************************************************************************
****************************************************************************************/

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

new ShopItem:g_iItem;

enum (<<= 1)
{
	RESET_FLAG_DISCONNECTED = 1,
	RESET_FLAG_KILLED = 2,
	RESET_FLAG_ROUND_START
};

new g_iResetFlags = (RESET_FLAG_DISCONNECTED|RESET_FLAG_KILLED|RESET_FLAG_ROUND_START);
new g_iMode;

public plugin_init()
{
	register_plugin("Shop: Reload BpAmmo On Kill", PLUGIN_VERSION, "w0w");
	register_dictionary("shop_reload_bpammo_on_kill.txt");

	RegisterHookChain(RG_CSGameRules_RestartRound, "refwd_NewRound_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "refwd_PlayerKilled_Post", true);

	new pCvarCost = create_cvar("shop_reload_bpammo_on_kill_cost", "50", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_RELOAD_BPAMMO_ON_KILL_COST"), true, 0.0);

	new pCvar;

	pCvar = create_cvar("shop_reload_bpammo_on_kill_mode", "1", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_RELOAD_BPAMMO_ON_KILL_MODE"), true, 1.0, true, 2.0);
	bind_pcvar_num(pCvar, g_iMode);

	pCvar = create_cvar("shop_reload_bpammo_on_kill_reset_flags", "abc", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_RELOAD_BPAMMO_ON_KILL_RESET_FLAGS"));
	hook_cvar_change(pCvar, "hook_CvarChange_ResetFlags");

	AutoExecConfig(true, "shop_reload_bpammo_on_kill", "shop");

	g_iItem = ShopPushItem(
		.name = GetCvarDesc("SHOP_RELOAD_BPAMMO_ON_KILL"),
		.cost = get_pcvar_num(pCvarCost),
		.access = ADMIN_ALL,
		.flags = IF_OnlyAlive,
		.discount = 0,
		.inventory = true,
		.strkey = "reload_bpammo_on_kill",
		.cmd = "shop_reload_bpammo_on_kill"
	);

	ShopRegisterEvent(Shop_ItemBuy, "func_BuyItem", .this = true);
}

public client_disconnected(id)
{
	if(g_iResetFlags & RESET_FLAG_DISCONNECTED)
		ShopRemoveUserItem(id, g_iItem);
}

public refwd_NewRound_Post()
{
	if(g_iResetFlags & RESET_FLAG_ROUND_START)
		ShopRemoveUserItem(0, g_iItem);
}

public refwd_PlayerKilled_Post(iVictim, iKiller, iGib)
{
	if(g_iResetFlags & RESET_FLAG_KILLED)
		ShopRemoveUserItem(iVictim, g_iItem);

	if(iVictim != iKiller && is_user_connected(iKiller) && ShopHasUserItem(iKiller, g_iItem))
		func_GiveBpAmmo(iKiller);
}

func_GiveBpAmmo(id)
{
	new iWeapon = get_member(id, m_pActiveItem);
	new WeaponIdType:iId = get_member(iWeapon, m_iId);

	if(iWeapon == NULLENT || iId == WEAPON_KNIFE || iId == WEAPON_HEGRENADE || iId == WEAPON_FLASHBANG || iId == WEAPON_SMOKEGRENADE)
		return;

	rg_instant_reload_weapons(id, g_iMode == 1 ? 0 : iWeapon);
}

public func_BuyItem(id, ShopItem:iItem, BuyState:iBuyState)
{
	if(iBuyState == Buy_OK)
		client_print(id, print_center, "%l", "SHOP_BOUGHT_RELOAD_BPAMMO_ON_KILL");

	return SHOP_CONTINUE;
}

public hook_CvarChange_ResetFlags(pCvar, const szOldValue[], const szNewValue[])
{
	g_iResetFlags = read_flags(szNewValue);
}