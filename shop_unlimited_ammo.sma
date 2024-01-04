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

new const PLUGIN_VERSION[] = "1.4";

/****************************************************************************************
****************************************************************************************/

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)
#define rg_set_weapon_ammo(%0,%1) set_member(%0, m_Weapon_iClip, %1)

new ShopItem:g_iItem;

enum (<<= 1)
{
	RESET_FLAG_DISCONNECTED = 1,
	RESET_FLAG_KILLED = 2,
	RESET_FLAG_ROUND_START
};

new g_iResetFlags = (RESET_FLAG_DISCONNECTED|RESET_FLAG_KILLED|RESET_FLAG_ROUND_START);

public plugin_init()
{
	register_plugin("Shop: Unlimited Ammo", PLUGIN_VERSION, "w0w");
	register_dictionary("shop_unlimited_ammo.txt");

	RegisterHookChain(RG_CSGameRules_RestartRound, "refwd_NewRound_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "refwd_PlayerKilled_Post", true);

	// the number 1 means refilling when left 1 ammo
	register_event("CurWeapon", "Event_CurWeapon", "be", "3=1");

	new pCvarCost = create_cvar("shop_unlimited_ammo_cost", "50", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_UNLIMITED_AMMO_COST"), true, 0.0);

	new pCvarFlags = create_cvar("shop_unlimited_ammo_reset_flags", "abc", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_UNLIMITED_AMMO_RESET_FLAGS"));
	hook_cvar_change(pCvarFlags, "hook_CvarChange_ResetFlags");

	AutoExecConfig(true, "shop_unlimited_ammo", "shop");

	g_iItem = ShopPushItem(
		.name = GetCvarDesc("SHOP_UNLIMITED_AMMO"),
		.cost = get_pcvar_num(pCvarCost),
		.access = ADMIN_ALL,
		.flags = IF_OnlyAlive,
		.discount = 0,
		.inventory = true,
		.strkey = "unlimited_ammo",
		.cmd = "shop_unlimited_ammo"
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
}

public Event_CurWeapon(id)
{
	if(!ShopHasUserItem(id, g_iItem))
		return PLUGIN_CONTINUE;

	enum { weapon = 2 };

	new iWeapon = read_data(weapon);

	new iClip = rg_get_weapon_info(iWeapon, WI_GUN_CLIP_SIZE);

	if(iClip < 0)
		return PLUGIN_CONTINUE;

	rg_set_weapon_ammo(get_member(id, m_pActiveItem), iClip + 1);

	return PLUGIN_CONTINUE;
}

public func_BuyItem(id, ShopItem:iItem, BuyState:iBuyState)
{
	if(iBuyState == Buy_OK)
		client_print(id, print_center, "%l", "SHOP_BOUGHT_UNLIMITED_AMMO");

	return SHOP_CONTINUE;
}

public hook_CvarChange_ResetFlags(pCvar, const szOldValue[], const szNewValue[])
{
	g_iResetFlags = read_flags(szNewValue);
}