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

new const PLUGIN_VERSION[] = "1.3";

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

new Float:g_flCvarDamage;

public plugin_init()
{
	register_plugin("Shop: Multiplier Damage", PLUGIN_VERSION, "w0w");
	register_dictionary("shop_multiplier_damage.txt");

	RegisterHookChain(RG_CSGameRules_RestartRound, "refwd_NewRound_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "refwd_PlayerKilled_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "refwd_PlayerTakeDamage_Pre", false);

	new pCvarCost = create_cvar("shop_multiplier_damage_cost", "50", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_MULTIPLIER_DAMAGE_COST"), true, 0.0);

	new pCvar;

	pCvar = create_cvar("shop_multiplier_damage_reset_flags", "abc", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_MULTIPLIER_DAMAGE_RESET_FLAGS"));
	hook_cvar_change(pCvar, "hook_CvarChange_ResetFlags");

	pCvar = create_cvar("shop_multiplier_damage", "2.0", FCVAR_NONE, GetCvarDesc("SHOP_CVAR_MULTIPLIER_DAMAGE_NUM"), true, 0.1);
	bind_pcvar_float(pCvar, g_flCvarDamage);

	AutoExecConfig(true, "shop_multiplier_damage", "shop");

	g_iItem = ShopPushItem(
		.name = GetCvarDesc("SHOP_MULTIPLIER_DAMAGE"),
		.cost = get_pcvar_num(pCvarCost),
		.access = ADMIN_ALL,
		.flags = IF_OnlyAlive,
		.discount = 0,
		.inventory = true,
		.strkey = "multiplier_damage",
		.cmd = "shop_multiplier_damage"
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

public refwd_PlayerKilled_Post(iVictim)
{
	if(g_iResetFlags & RESET_FLAG_KILLED)
		ShopRemoveUserItem(iVictim, g_iItem);
}

public refwd_PlayerTakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:flDamage, iBitsDamageType)
{
	if(iVictim == iAttacker || !is_user_connected(iAttacker))
		return HC_CONTINUE;

	if(ShopHasUserItem(iAttacker, g_iItem))
		SetHookChainArg(4, ATYPE_FLOAT, flDamage * g_flCvarDamage);

	return HC_CONTINUE;
}

public func_BuyItem(id, ShopItem:iItem, BuyState:iBuyState)
{
	if(iBuyState == Buy_OK)
		client_print(id, print_center, "%l", "SHOP_BOUGHT_MULTIPLIER_DAMAGE");

	return SHOP_CONTINUE;
}

public hook_CvarChange_ResetFlags(pCvar, const szOldValue[], const szNewValue[])
{
	g_iResetFlags = read_flags(szNewValue);
}