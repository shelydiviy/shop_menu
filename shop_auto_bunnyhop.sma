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

public plugin_init()
{
	register_plugin("Shop: Auto BunnyHop", PLUGIN_VERSION, "w0w");
	register_dictionary("shop_auto_bunnyhop.txt");

	RegisterHookChain(RG_CSGameRules_RestartRound, "refwd_NewRound_Post", true);
	RegisterHookChain(RG_CBasePlayer_Jump, "refwd_PlayerJump_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "refwd_PlayerKilled_Post", true);

	new pCvarCost = create_cvar("shop_auto_bunnyhop_cost", "50", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_AUTO_BUNNYHOP_COST"), true, 0.0);

	new pCvarFlags = create_cvar("shop_auto_bunnyhop_reset_flags", "abc", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_AUTO_BUNNYHOP_RESET_FLAGS"));
	hook_cvar_change(pCvarFlags, "hook_CvarChange_ResetFlags");

	AutoExecConfig(true, "shop_auto_bunnyhop", "shop");

	g_iItem = ShopPushItem(
		.name = GetCvarDesc("SHOP_AUTO_BUNNYHOP"),
		.cost = get_pcvar_num(pCvarCost),
		.access = ADMIN_ALL,
		.flags = IF_OnlyAlive,
		.discount = 0,
		.inventory = true,
		.strkey = "auto_bunnyhop",
		.cmd = "shop_auto_bunnyhop"
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

public refwd_PlayerJump_Pre(id)
{
	if(!ShopHasUserItem(id, g_iItem))
        return HC_CONTINUE;

	new const iFlags = get_entvar(id, var_flags);

	if(iFlags & FL_WATERJUMP || get_entvar(id, var_waterlevel) >= 2 || !(iFlags & FL_ONGROUND))
		return HC_CONTINUE;

	new Float:flVelocity[3];
	get_entvar(id, var_velocity, flVelocity);

	flVelocity[2] = 250.0;

	set_entvar(id, var_velocity, flVelocity);
	set_entvar(id, var_gaitsequence, 6);
	set_entvar(id, var_fuser2, 0.0);
	
	return HC_CONTINUE;
}

public refwd_PlayerKilled_Post(iVictim, iKiller, iGib)
{
	if(g_iResetFlags & RESET_FLAG_KILLED)
		ShopRemoveUserItem(iVictim, g_iItem);
}

public func_BuyItem(id, ShopItem:iItem, BuyState:iBuyState)
{
	if(iBuyState == Buy_OK)
		client_print(id, print_center, "%l", "SHOP_BOUGHT_AUTO_BUNNYHOP");
}

public hook_CvarChange_ResetFlags(pCvar, const szOldValue[], const szNewValue[])
{
	g_iResetFlags = read_flags(szNewValue);
}