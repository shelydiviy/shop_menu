/*
 * Author: https://t.me/twisternick
 *
 * Last update: 29.05.2019
 *
 */

#include <amxmodx>
#include <reapi>
#include <shopapi>

#pragma semicolon 1

new const PLUGIN_VERSION[] = "1.3";

/****************************************************************************************
****************************************************************************************/

// File name to log purchases
new const g_szLogFileName[] = "shop_purchases.log";

/****************************************************************************************
****************************************************************************************/

#define GetCvarDesc(%0) fmt("%L", LANG_SERVER, %0)

new bool:g_bShopBlocked;
new g_szLogFile[PLATFORM_MAX_PATH];
new g_iCvarLogs;
new g_iCvarAutoUnblock;

public plugin_init()
{
	register_plugin("Shop: Addon", PLUGIN_VERSION, "w0w");
	register_dictionary("shop_addon.txt");

	RegisterHookChain(RG_CSGameRules_RestartRound, "refwd_NewRound_Post", true);

	ShopRegisterEvent(Shop_OpenMenu, "func_Shop_OpenMenu", false);
	ShopRegisterEvent(Shop_ItemBuy, "func_Shop_ItemBuy", false);
	
	new pCvar;

	pCvar = create_cvar("shop_addon_logs", "1", FCVAR_NONE, GetCvarDesc("SHOP_ADDON_CVAR_LOGS"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_iCvarLogs);

	pCvar = create_cvar("shop_addon_auto_unblock", "1", FCVAR_NONE, GetCvarDesc("SHOP_ADDON_CVAR_AUTO_UNBLOCK"), true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_iCvarAutoUnblock);

	AutoExecConfig(true, "shop_addon", "shop");

	new szDir[PLATFORM_MAX_PATH];
	get_localinfo("amxx_logs", szDir, charsmax(szDir));
	formatex(g_szLogFile, charsmax(g_szLogFile), "%s/%s", szDir, g_szLogFileName);
}

public refwd_NewRound_Post()
{
	if(g_iCvarAutoUnblock)
		g_bShopBlocked = false;
}

public func_Shop_OpenMenu(id)
{
	if(g_bShopBlocked)
	{
		client_print_color(id, print_team_red, "%l", "SHOP_ADDON_ERROR_BLOCKED");
		return SHOP_BREAK;
	}
	return SHOP_CONTINUE;
}

public func_Shop_ItemBuy(id, ShopItem:iItem, BuyState:iBuyState)
{
	switch(iBuyState)
	{
		case Buy_NotEnoughMoney:
		{
			new szName[SHOP_MAX_ITEM_NAME_LENGTH], iCost;
			ShopGetItemInfo(id, iItem, szName, charsmax(szName), iCost, true);

			client_print_color(id, print_team_red, "%l", "SHOP_ADDON_ERROR_NOT_ENOUGH_MONEY", iCost - get_member(id, m_iAccount));
		}
		case Buy_PlayerDead: client_print_color(id, print_team_red, "%l", "SHOP_ADDON_ERROR_PLAYER_DEAD");
		case Buy_PlayerAlive: client_print_color(id, print_team_red, "%l", "SHOP_ADDON_ERROR_PLAYER_ALIVE");
		case Buy_AccessDenied: client_print_color(id, print_team_red, "%l", "SHOP_ADDON_ERROR_ACCESS_DENIED");
		case Buy_OK:
		{
			if(g_iCvarLogs)
			{
				new szName[SHOP_MAX_ITEM_NAME_LENGTH], iCost;
				ShopGetItemInfo(id, iItem, szName, charsmax(szName), iCost, true);

				new szAuthID[MAX_AUTHID_LENGTH], szIP[MAX_IP_LENGTH];
				get_user_authid(id, szAuthID, charsmax(szAuthID));
				get_user_ip(id, szIP, charsmax(szIP), 1);

				new iMoney = get_member(id, m_iAccount);

				log_to_file(g_szLogFile, "%l", "SHOP_ADDON_LOG_BUY", id, szAuthID, szIP, szName, iCost, iMoney, iMoney - iCost);
			}
		}
	}
}

/****************************************************************************************
****************************************************************************************/

public plugin_natives()
{
	register_native("shop_is_blocked",	"__shop_is_blocked");
	register_native("shop_set_block",	"__shop_set_block");
}

/**
 * Returns true if the shop is blocked, false otherwise.
 *
 * @return			true if it's blocked, false otherwise
 */
public __shop_is_blocked(iPlugin, iParams)
{
	return g_bShopBlocked;
}

/**
 * Sets or unsets the block of the shop.
 *
 * @param status	true to block, false to unblock
 *
 * @noreturn
 */
public __shop_set_block(iPlugin, iParams)
{
	enum { status = 1 };

	g_bShopBlocked = bool:get_param(status);
}