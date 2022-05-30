#pragma semicolon 1

#include <sourcemod>
#include <shop>
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS

#define SHOP_VERSION "3.0E5"
#define SHOP_MYSQL_CHARSET "utf8mb4"

#pragma newdecls required
EngineVersion Engine_Version = Engine_Unknown;

int g_iMaxPageItems = 10;

int global_timer;
Panel panel_info;
ArrayList g_hSortArray;

ShopMenu iClMenuId[MAXPLAYERS+1];
int iClCategoryId[MAXPLAYERS+1];
int iClItemId[MAXPLAYERS+1];
int iPos[MAXPLAYERS+1];
bool bInv[MAXPLAYERS+1];

char g_sChatCommand[24];
char g_sDbPrefix[12] = "shop_";
bool is_started;

ConVar g_hAdminFlags;
int g_iAdminFlags;
ConVar g_hItemTransfer;
int g_iItemTransfer;
ConVar g_hConfirmBuy;
bool g_bConfirmBuy;
ConVar g_hConfirmSell;
bool g_bConfirmSell;
ConVar g_hConfirmTryLuck;
bool g_bConfirmTryLuck;

ConVar g_hHideCategoriesItemsCount;

#include "shop/colors.sp"
#include "shop/admin.sp"
#include "shop/commands.sp"
#include "shop/db.sp"
#include "shop/forwards.sp"
#include "shop/helpers.sp"
#include "shop/functions.sp"
#include "shop/item_manager.sp"
#include "shop/player_manager.sp"
#if defined _SteamWorks_Included
#include "shop/stats.sp"
#endif

public Plugin myinfo =
{
	name = "[Shop] Core",
	description = "An advanced in game market",
	author = "Shop Core Team",
	version = SHOP_VERSION,
	url = "http://www.hlmod.ru/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Shop_IsStarted", Native_IsStarted);
	CreateNative("Shop_UnregisterMe", Native_UnregisterMe);
	CreateNative("Shop_ShowItemPanel", Native_ShowItemPanel);
	CreateNative("Shop_OpenMainMenu", Native_OpenMainMenu);
	CreateNative("Shop_ShowCategory", Native_ShowCategory);
	CreateNative("Shop_ShowInventory", Native_ShowInventory);
	CreateNative("Shop_ShowItemsOfCategory", Native_ShowItemsOfCategory);

	Admin_CreateNatives();
	DB_CreateNatives();
	Functions_CreateNatives();
	ItemManager_CreateNatives();
	PlayerManager_CreateNatives();
	
	RegPluginLibrary("shop");
	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("SQL_SetCharset");

	MarkNativeAsOptional("GuessSDKVersion"); 
	MarkNativeAsOptional("GetEngineVersion");
	MarkNativeAsOptional("GetUserMessageType");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbAddString");

	return APLRes_Success;
}

public int Native_IsStarted(Handle plugin, int params)
{
	return IsStarted();
}

public int Native_UnregisterMe(Handle plugin, int params)
{
	ItemManager_UnregisterMe(plugin);
	Functions_UnregisterMe(plugin);
	Admin_UnregisterMe(plugin);

	return 0;
}

public int Native_ShowItemPanel(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	
	return ShowItemInfo(client, GetNativeCell(2));
}

public int Native_OpenMainMenu(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		ThrowNativeError(1, "Client index %d is not authorized in the shop!", client);
	}
	ShowMainMenu(client);

	return 0;
}

public int Native_ShowCategory(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		ThrowNativeError(1, "Client index %d is not authorized in the shop!", client);
	}
	return ShowCategories(client);
}

public int Native_ShowInventory(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		ThrowNativeError(1, "Client index %d is not authorized in the shop!", client);
	}
	return ShowInventory(client);
}

public int Native_ShowItemsOfCategory(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		ThrowNativeError(1, "Client index %d is not authorized in the shop!", client);
	}
	int category_id = GetNativeCell(2);
	if (!ItemManager_IsValidCategory(category_id))
	{
		ThrowNativeError(1, "Category id %d is invalid!", category_id);
	}
	return ShowItemsOfCategory(client, category_id, GetNativeCell(3));
}

public void OnPluginStart()
{
	g_iMaxPageItems = GetMaxPageItems(GetMenuStyleHandle(MenuStyle_Default));

	InitChat();
	DB_OnPluginStart();
	Forward_OnPluginStart();
	Functions_OnPluginStart();
	PlayerManager_OnPluginStart();
	ItemManager_OnPluginStart();
	
	global_timer = GetTime();
	
	CreateTimer(1.0, OnEverySecond, _, TIMER_REPEAT);
	
	LoadTranslations("shop.phrases");
	LoadTranslations("common.phrases");
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	CreateConfigs();
	Engine_Version = GetEngineVersion();
}

public void OnPluginEnd()
{
	PlayerManager_OnPluginEnd();
	ItemManager_OnPluginEnd();
}

public Action OnEverySecond(Handle timer)
{
	global_timer++;
	return Plugin_Continue;
}

void CreateConfigs()
{
	CreateConVar("sm_advanced_shop_version", SHOP_VERSION, "Shop plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	char sBuffer[PLATFORM_MAX_PATH];
	g_hAdminFlags = CreateConVar("sm_shop_admin_flags", "z", "Set flags for admin panel access. Set several flags if necessary. Ex: \"abcz\"");
	g_hAdminFlags.GetString(sBuffer, sizeof(sBuffer));
	g_iAdminFlags = ReadFlagString(sBuffer);
	g_hAdminFlags.AddChangeHook(OnConVarChange);
	
	g_hItemTransfer = CreateConVar("sm_shop_item_transfer_credits", "500", "How many credits an item transfer cost. Set -1 to disable the feature", 0, true, -1.0);
	g_iItemTransfer = g_hItemTransfer.IntValue;
	g_hItemTransfer.AddChangeHook(OnConVarChange);
	
	g_hHideCategoriesItemsCount = CreateConVar("sm_shop_category_items_hideamount", "0", "Hide amount of items in category", 0, true, 0.0, true, 1.0);

	g_hConfirmBuy = CreateConVar("sm_shop_confirm_buy", "1", "Enable confirm item purchase menu or not, Set this to 0 the client will purchase instantly after press buy button.", 0, true, 0.0, true, 1.0);
	g_bConfirmBuy = g_hConfirmBuy.BoolValue;
	g_hConfirmBuy.AddChangeHook(OnConVarChange);

	g_hConfirmSell = CreateConVar("sm_shop_confirm_sell", "1", "Enable confirm item selling menu or not, Set this to 0 the client will sell item instantly after press sell button.", 0, true, 0.0, true, 1.0);
	g_bConfirmSell = g_hConfirmSell.BoolValue;
	g_hConfirmSell.AddChangeHook(OnConVarChange);

	g_hConfirmTryLuck = CreateConVar("sm_shop_confirm_tryluck", "1", "Enable confirm try luck menu or not, Set this to 0 the client will try a luck instantly after press a button.", 0, true, 0.0, true, 1.0);
	g_bConfirmTryLuck = g_hConfirmTryLuck.BoolValue;
	g_hConfirmTryLuck.AddChangeHook(OnConVarChange);
	
	KeyValues kv_settings = new KeyValues("Settings");
	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "settings.txt");
	kv_settings.ImportFromFile(sBuffer);
	
	Admin_OnSettingsLoad(kv_settings);
	DB_OnSettingsLoad(kv_settings);
	Commands_OnSettingsLoad(kv_settings);
	
	delete kv_settings;
	
	AutoExecConfig(true, "shop", "shop");
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hAdminFlags)
	{
		g_iAdminFlags = ReadFlagString(newValue);
	}
	else if (convar == g_hItemTransfer)
	{
		g_iItemTransfer = convar.IntValue;
	}
	else if (convar == g_hConfirmBuy)
	{
		g_bConfirmBuy = convar.BoolValue;
	}
	else if (convar == g_hConfirmSell)
	{
		g_bConfirmSell = convar.BoolValue;
	}
	else
	{
		g_bConfirmTryLuck = convar.BoolValue;
	}
}

public void OnMapStart()
{
#if defined _SteamWorks_Included
	// Stats work
	if (LibraryExists("SteamWorks"))
		SteamWorks_SteamServersConnected();
#endif

	DB_OnMapStart();
	
	if (panel_info != null)
	{
		delete panel_info;
		panel_info = null;
	}
	
	if (g_hSortArray != null)
	{
		delete g_hSortArray;
		g_hSortArray = null;
	}
	
	char sBuffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "shop_info.txt");
	
	File hFile = OpenFile(sBuffer, "r");
	if (hFile != null)
	{
		if (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
		{
			if (sBuffer[0])
			{
				panel_info = new Panel();
				panel_info.DrawText(sBuffer);
		
				while (!hFile.EndOfFile() && hFile.ReadLine(sBuffer, sizeof(sBuffer)))
				{
					if (sBuffer[0])
					{
						panel_info.DrawText(sBuffer);
					}
				}
		
				panel_info.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
			}
		}
		
		delete hFile;
	}

	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "shop_sort.txt");
	
	hFile = OpenFile(sBuffer, "r");
	if (hFile != null)
	{
		g_hSortArray = new ArrayList(ByteCountToCells(SHOP_MAX_STRING_LENGTH));
		
		while (!hFile.EndOfFile() && hFile.ReadLine(sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);
			if (sBuffer[0])
			{
				g_hSortArray.PushString(sBuffer);
			}
		}
		
		if(!g_hSortArray.Length)
		{
			delete g_hSortArray;
			g_hSortArray = null;
		}

		delete hFile;
	}
}

public void OnMapEnd()
{
	Functions_OnMapEnd();
//	PlayerManager_OnMapEnd();
}

void ShowInfo(int client)
{
	if (panel_info != null)
	{
		SetGlobalTransTarget(client);
		
		char sBuffer[32];
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
		panel_info.CurrentKey = 1;
		panel_info.DrawItem(sBuffer, ITEMDRAW_CONTROL);
		
		panel_info.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
		panel_info.CurrentKey = g_iMaxPageItems;
		panel_info.DrawItem(sBuffer, ITEMDRAW_CONTROL);
		
		panel_info.Send(client, InfoHandle, MENU_TIME_FOREVER);
	}
}

public int InfoHandle(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			if (param2 == 1)
			{
				ShowMainMenu(param1);
			}
		}
	}

	return 0;
}

void DatabaseClear()
{
	PlayerManager_DatabaseClear();
}

stock bool IsInGame(int player_id)
{
	return PlayerManager_IsInGame(player_id);
}

void OnReadyToStart()
{
	if (!is_started)
	{
		is_started = true;
		
		Forward_NotifyShopLoaded();
	//	PlayerManager_OnReadyToStart();
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				OnClientPutInServer(client);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!IsStarted() || IsFakeClient(client))
	{
		return;
	}
	PlayerManager_OnClientPutInServer(client);
}

public void OnClientDisconnect_Post(int client)
{
	Functions_OnClientDisconnect_Post(client);
	PlayerManager_OnClientDisconnect_Post(client);
}

// TODO replace to OnClientSayCommand
public Action Command_Say(int client, const char[] command, int argc)
{
	if(client > 0 && client <= MaxClients)
	{
		char text[192];
		if (!GetCmdArgString(text, sizeof(text)) || !text[0])
		{
			return Plugin_Continue;
		}
		StripQuotes(text);
		TrimString(text);
		
		if (Functions_OnClientSayCommand(client, text) != Plugin_Continue)
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void ShowMainMenu(int client, int pos = 0)
{
	Menu menu = new Menu(MainMenu_Handler);
	menu.ExitButton = true;
	menu.ExitBackButton =  false;
	
	char sBuffer[192];
	FormatEx(sBuffer, sizeof(sBuffer), "%T\n%T", "MainMenuTitle", client, "credits", client, PlayerManager_GetCredits(client));
	OnMenuTitle(client, Menu_Main, sBuffer, sBuffer, sizeof(sBuffer));
	menu.SetTitle(sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "buy", client);
	menu.AddItem("0", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%T\n ", "inventory", client);
	menu.AddItem("2", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%T\n ", "functions", client);
	menu.AddItem("3", sBuffer);
	
	if (panel_info != null)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T\n ", "info", client);
		menu.AddItem("4", sBuffer);
	}
	
	if (g_iAdminFlags != 0 && (GetUserFlagBits(client) & g_iAdminFlags) && GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "admin_panel", client);
		menu.AddItem("5", sBuffer);
	}
	
	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

public int MainMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End : delete menu;
		case MenuAction_Select :
		{
			char info[4];
			menu.GetItem(param2, info, sizeof(info));
			
			switch (info[0])
			{
				case '0':
				{
					if (!ShowCategories(param1))
					{
						ShowMainMenu(param1, GetMenuSelectionPosition());
						CPrintToChat(param1, "%t", "EmptyShop");
					}
				}
				case '2':
				{
					if (!ShowInventory(param1))
					{
						ShowMainMenu(param1, GetMenuSelectionPosition());
						CPrintToChat(param1, "%t", "EmptyInventory");
					}
				}
				case '3':
				{
					Functions_ShowMenu(param1);
				}
				case '4':
				{
					ShowInfo(param1);
				}
				case '5':
				{
					Admin_ShowMenu(param1);
				}
			}
		}
	}

	return 0;
}

bool ShowInventory(int client)
{
	Menu menu = new Menu(OnInventorySelect);
	if (!ItemManager_FillCategories(menu, client, Menu_Inventory))
	{
		delete menu;
		return false;
	}
	
	char title[128];
	FormatEx(title, sizeof(title), "%T\n%T", "inventory", client, "credits", client, PlayerManager_GetCredits(client));
	OnMenuTitle(client, Menu_Inventory, title, title, sizeof(title));
	menu.SetTitle(title);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	
	iClMenuId[client] = Menu_Inventory;
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public int OnInventorySelect(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			int category_id = StringToInt(info);
			
			if (!ItemManager_OnCategorySelect(param1, category_id, Menu_Inventory))
			{
				return 0;
			}

			if (!ShowItemsOfCategory(param1, StringToInt(info), true) && !ShowInventory(param1))
			{
				ShowMainMenu(param1);
				CPrintToChat(param1, "%t", "EmptyInventory");
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

bool ShowCategories(int client)
{
	Menu menu = new Menu(OnCategorySelect);
	
	if (!ItemManager_FillCategories(menu, client, Menu_Buy))
	{
		delete menu;
		return false;
	}
	
	char title[128];
	FormatEx(title, sizeof(title), "%T\n%T", "Shop", client, "credits", client, PlayerManager_GetCredits(client));
	OnMenuTitle(client, Menu_Buy, title, title, sizeof(title));
	menu.SetTitle(title);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	
	iClMenuId[client] = Menu_Buy;
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public int OnCategorySelect(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int category_id = StringToInt(info);
			
			if (!ItemManager_OnCategorySelect(param1, category_id, Menu_Buy))
			{
				return 0;
			}
			
			if (!ShowItemsOfCategory(param1, category_id, false) && !ShowCategories(param1))
			{
				ShowMainMenu(param1);
				CPrintToChat(param1, "%t", "EmptyShop");
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowMainMenu(param1);
			}
		}
		case MenuAction_End : delete menu;
	}

	return 0;
}

bool ShowItemsOfCategory(int client, int category_id, bool inventory, int pos = 0)
{
	Menu menu = new Menu(OnItemSelect, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);
	if (!ItemManager_FillItemsOfCategory(menu, client, client, category_id, inventory))
	{
		delete menu;
		return false;
	}
	char title[128];
	if (inventory)
	{
		FormatEx(title, sizeof(title), "%T\n%T", "inventory", client, "credits", client, PlayerManager_GetCredits(client));
		OnMenuTitle(client, Menu_Inventory, title, title, sizeof(title));
		iClMenuId[client] = Menu_Inventory;
	}
	else
	{
		FormatEx(title, sizeof(title), "%T\n%T", "Shop", client, "credits", client, PlayerManager_GetCredits(client));
		OnMenuTitle(client, Menu_Buy, title, title, sizeof(title));
		iClMenuId[client] = Menu_Buy;
	}
	
	menu.SetTitle(title);
	
	bInv[client] = inventory;
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	
	iClCategoryId[client] = category_id;
	
	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
	
	return true;
}

public int OnItemSelect(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			iPos[param1] = GetMenuSelectionPosition();

			ShopMenu shop_menu = (bInv[param1] ? Menu_Inventory : Menu_Buy);
			int value = StringToInt(info);
			
			Action result = Forward_OnItemSelect(param1, shop_menu, iClCategoryId[param1], value);
			
			if (result == Plugin_Handled || 
			((result == Plugin_Changed || result == Plugin_Continue) && !ShowItemInfo(param1, value)))
			{
				ShowItemsOfCategory(param1, iClCategoryId[param1], bInv[param1], iPos[param1]);
				Forward_OnItemSelected(param1, shop_menu, iClCategoryId[param1], value);
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (bInv[param1])
				{
					if (!ShowInventory(param1))
					{
						ShowMainMenu(param1);
						CPrintToChat(param1, "%t", "EmptyInventory");
					}
				}
				else if (!ShowCategories(param1))
				{
					ShowMainMenu(param1);
					CPrintToChat(param1, "%t", "EmptyShop");
				}
			}
		}
		case MenuAction_End : delete menu;
		case MenuAction_DrawItem :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			bool disabled;
			
			switch (Forward_OnItemDraw(param1, bInv[param1] ? Menu_Inventory : Menu_Buy, iClCategoryId[param1], StringToInt(info), disabled))
			{
				case Plugin_Continue:
				{
					disabled = false;
				}
				case Plugin_Handled, Plugin_Stop:
				{
					menu.RemoveItem(param2);
					return 0;
				}
			}
			if (disabled)
			{
				return ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_DisplayItem:
		{
			char info[16], sBuffer[SHOP_MAX_STRING_LENGTH];
			menu.GetItem(param2, info, sizeof(info), _, sBuffer, sizeof(sBuffer));
			
			bool result = Forward_OnItemDisplay(param1, bInv[param1] ? Menu_Inventory : Menu_Buy, iClCategoryId[param1], StringToInt(info), sBuffer, sBuffer, sizeof(sBuffer));
			
			switch (ItemManager_GetItemTypeEx(info))
			{
				case Item_Finite :
				{
					if (bInv[param1])
					{
						Format(sBuffer, sizeof(sBuffer), "%s (%d)", sBuffer, PlayerManager_GetItemCountEx(param1, info));
					}
					else
					{
						Format(sBuffer, sizeof(sBuffer), "[%d] %s (%d)", ItemManager_GetItemPriceEx(info), sBuffer, PlayerManager_GetItemCountEx(param1, info));
					}
					result = true;
				}
				case Item_BuyOnly :
				{
					if (!bInv[param1])
					{
						Format(sBuffer, sizeof(sBuffer), "[%d] %s", ItemManager_GetItemPriceEx(info), sBuffer);
						result = true;
					}
				}
				default:
				{
					if (!bInv[param1])
					{
						if (PlayerManager_ClientHasItemEx(param1, info))
						{
							int timeleft = PlayerManager_GetItemTimeleftEx(param1, info);
							if (timeleft > 0)
							{
								GetTimeFromStamp(info, sizeof(info), timeleft, param1);
								Format(sBuffer, sizeof(sBuffer), "[+] %s (%s)", sBuffer, info);
							}
							else
							{
								Format(sBuffer, sizeof(sBuffer), "[+] %s (%T)", sBuffer, "forever", param1);
							}
						}
						else
						{
							Format(sBuffer, sizeof(sBuffer), "[%d] %s", ItemManager_GetItemPriceEx(info), sBuffer);
						}
						result = true;
					}
					else
					{
						int timeleft = PlayerManager_GetItemTimeleftEx(param1, info);
						if (timeleft > 0)
						{
							GetTimeFromStamp(info, sizeof(info), timeleft, param1);
							Format(sBuffer, sizeof(sBuffer), "%s (%s)", sBuffer, info);
							result = true;
						}
					}
				}
			}
			if (result)
			{
				return RedrawMenuItem(sBuffer);
			}
		}
	}
	return 0;
}

#define BUTTON_BUY 1
#define BUTTON_SELL 2
#define BUTTON_PREVIEW 3
#define BUTTON_TOGGLE 4
#define BUTTON_USE 5
#define BUTTON_TRANSFER 6
#define BUTTON_BACK 8
#define BUTTON_EXIT 10

int iButton[MAXPLAYERS+1][11];

#define CONFIRM_YES 1
#define CONFIRM_NO 2

bool ShowItemInfo(int client, int item_id)
{
	Panel panel = ItemManager_CreateItemPanelInfo(client, item_id, bInv[client] ? Menu_Inventory : Menu_Buy);
	if (panel != null)
	{
		char sBuffer[SHOP_MAX_STRING_LENGTH], sItemId[16];
		IntToString(item_id, sItemId, sizeof(sItemId));
		
		bool isHidden = ItemManager_GetItemHideEx(sItemId);
		
		SetGlobalTransTarget(client);
		
		int credits = GetCredits(client);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "credits", credits);
		panel.SetTitle(sBuffer, false);
		
		ItemType type = ItemManager_GetItemTypeEx(sItemId);
		
		int button = 1;
		
		switch (type)
		{
			case Item_None :
			{
				if (PlayerManager_ClientHasItemEx(client, sItemId))
				{
					int timeleft = PlayerManager_GetItemTimeleftEx(client, sItemId);
					int sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
					if (timeleft > 0)
					{
						GetTimeFromStamp(sBuffer, sizeof(sBuffer), timeleft, client);
						Format(sBuffer, sizeof(sBuffer), "%t: %s", "timeleft", sBuffer);
						panel.DrawText(sBuffer);
						
						if (sell_price > -1)
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "absolute_sellprice", sell_price);
							panel.DrawText(sBuffer);
						}
						panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
					}
					if (sell_price > -1)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t [+%d]", "sell", sell_price);
						panel.DrawItem(sBuffer);
						iButton[client][button++] = BUTTON_SELL;
					}
					if (!isHidden)
					{
						switch (g_iItemTransfer)
						{
							case -1 :
							{
							}
							case 0 :
							{
								FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
								panel.DrawItem(sBuffer);
								iButton[client][button++] = BUTTON_TRANSFER;
							}
							default :
							{
								FormatEx(sBuffer, sizeof(sBuffer), "%t [%t: %d]", "transfer", "Price", g_iItemTransfer);
								panel.DrawItem(sBuffer, (credits < g_iItemTransfer) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
								iButton[client][button++] = BUTTON_TRANSFER;
							}
						}
					}
				}
				else if (!isHidden)
				{
					if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
						panel.DrawItem(sBuffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
						panel.DrawItem(sBuffer);
					}
					iButton[client][button++] = BUTTON_BUY;
				}
			}
			case Item_Finite :
			{
				int count = PlayerManager_GetItemCountEx(client, sItemId);
				FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "You have", count);
				panel.DrawText(sBuffer);
				
				panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
				
				if (!isHidden)
				{
					if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
						panel.DrawItem(sBuffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
						panel.DrawItem(sBuffer);
					}
					
					iButton[client][button++] = BUTTON_BUY;
				}
				if (count > 0)
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "use");
					panel.DrawItem(sBuffer);
					iButton[client][button++] = BUTTON_USE;
					
					int sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
					
					if (sell_price > -1)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t [+%d]", "sell", sell_price);
						panel.DrawItem(sBuffer);
						iButton[client][button++] = BUTTON_SELL;
					}
					if (!isHidden)
					{
						switch (g_iItemTransfer)
						{
							case -1 :
							{
							}
							case 0 :
							{
								FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
								panel.DrawItem(sBuffer);
								iButton[client][button++] = BUTTON_TRANSFER;
							}
							default :
							{
								FormatEx(sBuffer, sizeof(sBuffer), "%t [%t: %d]", "transfer", "Price", g_iItemTransfer);
								panel.DrawItem(sBuffer, (credits < g_iItemTransfer) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
								iButton[client][button++] = BUTTON_TRANSFER;
							}
						}
					}
				}
			}
			case Item_Togglable :
			{
				if (PlayerManager_ClientHasItemEx(client, sItemId))
				{
					int timeleft = PlayerManager_GetItemTimeleftEx(client, sItemId);
					int sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
					if (timeleft > 0)
					{
						GetTimeFromStamp(sBuffer, sizeof(sBuffer), timeleft, client);
						Format(sBuffer, sizeof(sBuffer), "%t: %s", "timeleft", sBuffer);
						panel.DrawText(sBuffer);
						
						if (sell_price > -1)
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "absolute_sellprice", sell_price);
							panel.DrawText(sBuffer);
						}
						panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
					}
					if (PlayerManager_IsItemToggledEx(client, sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "ToggleOff");
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "ToggleOn");
					}
					panel.DrawItem(sBuffer);
					iButton[client][button++] = BUTTON_TOGGLE;
					
					if (sell_price > -1)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t [+%d]", "sell", sell_price);
						panel.DrawItem(sBuffer);
						iButton[client][button++] = BUTTON_SELL;
					}
					
					if (!isHidden)
					{
						switch (g_iItemTransfer)
						{
							case -1 :
							{
							}
							case 0 :
							{
								FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
								panel.DrawItem(sBuffer);
								iButton[client][button++] = BUTTON_TRANSFER;
							}
							default :
							{
								FormatEx(sBuffer, sizeof(sBuffer), "%t [%t: %d]", "transfer", "Price", g_iItemTransfer);
								panel.DrawItem(sBuffer, (credits < g_iItemTransfer) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
								iButton[client][button++] = BUTTON_TRANSFER;
							}
						}
					}
				}
				else if (!isHidden)
				{
					if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
						panel.DrawItem(sBuffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
						panel.DrawItem(sBuffer);
					}
					iButton[client][button++] = BUTTON_BUY;
					
					if (ItemManager_CanPreview(item_id))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "preview");
						panel.DrawItem(sBuffer);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "preview_unavailable");
						panel.DrawItem(sBuffer, ITEMDRAW_DISABLED);
					}
					iButton[client][button++] = BUTTON_PREVIEW;
				}
			}
			case Item_BuyOnly :
			{
				if (!isHidden)
				{
					if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
						panel.DrawItem(sBuffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
						panel.DrawItem(sBuffer);
					}
					iButton[client][button++] = BUTTON_BUY;
				}
			}
		}
		
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		panel.CurrentKey = g_iMaxPageItems-2;
		iButton[client][g_iMaxPageItems-2] = BUTTON_BACK;
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
		panel.DrawItem(sBuffer, ITEMDRAW_CONTROL);
		
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		panel.CurrentKey = g_iMaxPageItems;
		iButton[client][g_iMaxPageItems] = BUTTON_EXIT;
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
		panel.DrawItem(sBuffer, ITEMDRAW_CONTROL);
		
		iClItemId[client] = item_id;
		
		panel.Send(client, ItemPanel_Handler, MENU_TIME_FOREVER);
		delete panel;
		
		return true;
	}
	return false;
}

public int ItemPanel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			bool has = ClientHasItem(param1, iClItemId[param1]);
			
			switch (iButton[param1][param2])
			{
				case BUTTON_BUY :
				{
					if (g_bConfirmBuy)
					{
						ConfirmBuy(param1, iClItemId[param1]);
					}
					else
					{
						BuyItem(param1, iClItemId[param1], false);
						ShowItemInfo(param1, iClItemId[param1]);
					}
				}
				case BUTTON_SELL :
				{
					if (has)
					{
						if (g_bConfirmSell)
						{
							ConfirmSell(param1, iClItemId[param1]);
						}
						else
						{
							SellItem(param1, iClItemId[param1]);
							ShowItemInfo(param1, iClItemId[param1]);
						}
					}
					if (bInv[param1] && PlayerManager_GetItemCount(param1, iClItemId[param1]) < 1)
					{
						if (!ShowItemsOfCategory(param1, iClCategoryId[param1], true, iPos[param1]) && !ShowInventory(param1))
						{
							ShowMainMenu(param1);
							CPrintToChat(param1, "%t", "EmptyInventory");
						}
					}
				}
				case BUTTON_PREVIEW :
				{
					if (!has)
					{
						PreviewItem(param1, iClItemId[param1]);
					}
					ShowItemInfo(param1, iClItemId[param1]);
				}
				case BUTTON_TOGGLE :
				{
					if (has)
					{
						ToggleItem(param1, iClItemId[param1], Toggle);
					}
					ShowItemInfo(param1, iClItemId[param1]);
				}
				case BUTTON_USE :
				{
					if (has)
					{
						UseItem(param1, iClItemId[param1], false);
					}
					ShowItemInfo(param1, iClItemId[param1]);
				}
				case BUTTON_TRANSFER :
				{
					if (has)
					{
						if (!SetupItemTransfer(param1))
						{
							CPrintToChat(param1, "%t", "no_targets");
							ShowItemInfo(param1, iClItemId[param1]);
						}
					}
					else
					{
						ShowItemInfo(param1, iClItemId[param1]);
					}
				}
				default:
				{
					if(param2 == g_iMaxPageItems-2)
					{
						switch (iClMenuId[param1])
						{
							case Menu_Buy :
							{
								if (!ShowItemsOfCategory(param1, iClCategoryId[param1], false, iPos[param1]) && !ShowCategories(param1))
								{
									ShowMainMenu(param1);
									CPrintToChat(param1, "%t", "EmptyShop");
								}
							}
							case Menu_Inventory :
							{
								if (!ShowItemsOfCategory(param1, iClCategoryId[param1], true, iPos[param1]) && !ShowInventory(param1))
								{
									ShowMainMenu(param1);
									CPrintToChat(param1, "%t", "EmptyInventory");
								}
							}
						}
					}
				}
			}
		}
	}

	return 0;
}

void ConfirmBuy(int client, int item_id)
{
	Panel panel = ItemManager_ConfirmItemPanelInfo(client, item_id, Menu_Buy, true);

	if (panel == null)
		return;

	char sBuffer[256], sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	SetGlobalTransTarget(client);
	
	int credits = GetCredits(client);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "credits", credits);
	panel.SetTitle(sBuffer, false);
	
	ItemType type = ItemManager_GetItemTypeEx(sItemId);

	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

	if(type == Item_Finite)
	{
		int count = PlayerManager_GetItemCountEx(client, sItemId);
		FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "You have", count);
		panel.DrawText(sBuffer);
		
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	}
		
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "You Buy Sure");
	panel.DrawText(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Yes");
	panel.DrawItem(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "No");
	panel.DrawItem(sBuffer);

	iClItemId[client] = item_id;
	
	panel.Send(client, BuyConfirmPanel_Handler, MENU_TIME_FOREVER);
	delete panel;
}

public int BuyConfirmPanel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			switch (param2)
			{
				case CONFIRM_YES :
				{
					BuyItem(param1, iClItemId[param1], false);
					ShowItemInfo(param1, iClItemId[param1]);
				}
				case CONFIRM_NO :
				{
					ShowItemInfo(param1, iClItemId[param1]);
				}
			}
		}
	}

	return 0;
}

void ConfirmSell(int client, int item_id)
{
	Panel panel = ItemManager_ConfirmItemPanelInfo(client, item_id, Menu_Buy, false);
	
	if (panel == null)
		return;

	char sBuffer[256], sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	SetGlobalTransTarget(client);
	
	int credits = GetCredits(client);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "credits", credits);
	panel.SetTitle(sBuffer, false);
	
	ItemType type = ItemManager_GetItemTypeEx(sItemId);

	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	if(type == Item_Finite)
	{
		int count = PlayerManager_GetItemCountEx(client, sItemId);
		FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "You have", count);
		panel.DrawText(sBuffer);
		
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	}

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "You Sell Sure");
	panel.DrawText(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Yes");
	panel.DrawItem(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "No");
	panel.DrawItem(sBuffer);
	
	iClItemId[client] = item_id;
	
	panel.Send(client, SellConfirmPanel_Handler, MENU_TIME_FOREVER);
	delete panel;
}

public int SellConfirmPanel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			switch (param2)
			{
				case CONFIRM_YES :
				{
					SellItem(param1, iClItemId[param1]);
					ShowItemInfo(param1, iClItemId[param1]);
				}
				case CONFIRM_NO :
				{
					ShowItemInfo(param1, iClItemId[param1]);
				}
			}
		}
		case MenuAction_End :
		{
			delete menu;
		}
	}

	return 0;
}

bool SetupItemTransfer(int client, int pos = 0)
{
	Menu menu = new Menu(Menu_TransItemHandler);
	
	if (!FillMenuByItemTransTarget(menu, client, iClItemId[client]))
	{
		delete menu;
		return false;
	}
	
	char title[128];
	FormatEx(title, sizeof(title), "%T", "ItemTransferMenu", client);
	OnMenuTitle(client, Menu_ItemTransfer, title, title, sizeof(title));
	menu.SetTitle(title);
	
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	
	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
	
	return true;
}

int g_iItemTransTarget[MAXPLAYERS+1];
public int Menu_TransItemHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
			int userid = StringToInt(info);
			int target = GetClientOfUserId(userid);
			
			if (!target)
			{
				SetupItemTransfer(param1);
				CPrintToChat(param1, "%t", "target_left_game");
				return 0;
			}
			ItemType type = GetItemType(iClItemId[param1]);
			if (type != Item_Finite && ClientHasItem(target, iClItemId[param1]))
			{
				SetupItemTransfer(param1, GetMenuSelectionPosition());
				CPrintToChat(param1, "%t", "already_has", target);
				return 0;
			}
			if (!ClientHasItem(param1, iClItemId[param1]))
			{
				ShowItemInfo(param1, iClItemId[param1]);
				CPrintToChat(param1, "%t", "no_item");
				return 0;
			}
			
			g_iItemTransTarget[param1] = userid;
			ShowTransItemInfo(param1);
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowItemInfo(param1, iClItemId[param1]);
			}
		}
		case MenuAction_End : delete menu;
	}

	return 0;
}

void ShowTransItemInfo(int client)
{
	int target = GetClientOfUserId(g_iItemTransTarget[client]);
	if (!target)
	{
		ShowItemInfo(client, iClItemId[client]);
		CPrintToChat(client, "%t", "target_left_game");
		return;
	}
	if (!ClientHasItem(client, iClItemId[client]))
	{
		ShowItemInfo(client, iClItemId[client]);
		CPrintToChat(client, "%t", "no_item");
		return;
	}
	
	SetGlobalTransTarget(client);
	
	Panel panel = new Panel();
	
	char sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "ItemTransferMenu2", target);
	panel.SetTitle(sBuffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	GetCategoryDisplay(GetItemCategoryId(iClItemId[client]), client, category, sizeof(category));
	ItemManager_GetItemDisplay(iClItemId[client], client, item, sizeof(item));
	FormatEx(sBuffer, sizeof(sBuffer), "%s - %s", category, item);
	panel.DrawText(sBuffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	if (GetItemType(iClItemId[client]) == Item_Finite)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%N: %d", target, PlayerManager_GetItemCount(target, iClItemId[client]));
		panel.DrawText(sBuffer);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "You have", PlayerManager_GetItemCount(client, iClItemId[client]));
		panel.DrawText(sBuffer);
		
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	}
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
	panel.DrawItem(sBuffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	panel.CurrentKey = g_iMaxPageItems-2;
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
	panel.DrawItem(sBuffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	panel.CurrentKey = g_iMaxPageItems;
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
	panel.DrawItem(sBuffer);
	
	panel.Send(client, ItemTransPanel_Handler, MENU_TIME_FOREVER);
	delete panel;
}

public int ItemTransPanel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			switch (param2)
			{
				case 1 :
				{
					int target = GetClientOfUserId(g_iItemTransTarget[param1]);
					if (!target)
					{
						ShowItemInfo(param1, iClItemId[param1]);
						CPrintToChat(param1, "%t", "target_left_game");
						return 0;
					}
					
					if (!Forward_OnItemTransfer(param1, target, iClItemId[param1]))
					{
						ShowItemInfo(param1, iClItemId[param1]);
						return 0;
					}
					
					PlayerManager_TransferItem(param1, target, iClItemId[param1]);
					
					RemoveCredits(param1, g_iItemTransfer, CREDITS_BY_BUY_OR_SELL);
					
					Forward_OnItemTransfered(param1, target, iClItemId[param1]);
					
					char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
					ItemManager_GetItemDisplay(iClItemId[param1], target, item, sizeof(item));
					ItemManager_GetCategoryDisplay(GetItemCategoryId(iClItemId[param1]), target, category, sizeof(category));
					CPrintToChat(target, "%t", "receive_item", param1, category, item);
					
					ShowTransItemInfo(param1);
				}
				default :
				{
					if (param2 == g_iMaxPageItems-2)
					{
						SetupItemTransfer(param1);
					}
				}
			}
		}
	}

	return 0;
}

bool FillMenuByItemTransTarget(Menu menu, int client, int item_id)
{
	ItemType type = GetItemType(item_id);
	
	bool result = false;
	
	char userid[9], sBuffer[MAX_NAME_LENGTH+21];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsAuthorizedIn(i))
		{
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			
			if (type == Item_Finite)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%N (%d)", i, PlayerManager_GetItemCount(i, item_id));
				menu.AddItem(userid, sBuffer);
			}
			else
			{
				if (ClientHasItem(i, item_id))
				{
					FormatEx(sBuffer, sizeof(sBuffer), "[+] %N", i);
					menu.AddItem(userid, sBuffer, ITEMDRAW_DISABLED);
				}
				else
				{
					GetClientName(i, sBuffer, sizeof(sBuffer));
					menu.AddItem(userid, sBuffer);
				}
			}
			
			result = true;
		}
	}
	
	return result;
}

bool BuyItem(int client, int item_id, bool by_native)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	int category_id, price, sell_price, count, duration;
	ItemType type;
	char item[SHOP_MAX_STRING_LENGTH];
	
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}
	
	char category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	Action result;
	
	int default_price = price;
	int default_sellprice = sell_price;
	int default_value;
	switch (type)
	{
		case Item_None, Item_Togglable :
		{
			default_value = duration;
			result = Forward_OnItemBuy(client, category_id, category, item_id, item, type, price, sell_price, duration);
		}
		default:
		{
			default_value = count;
			result = Forward_OnItemBuy(client, category_id, category, item_id, item, type, price, sell_price, count);
		}
	}
	switch (result)
	{
		case Plugin_Continue:
		{
			price = default_price;
			sell_price = default_sellprice;
			switch (type)
			{
				case Item_None, Item_Togglable :
				{
					duration = default_value;
				}
				default:
				{
					count = default_value;
				}
			}
		}
		case Plugin_Handled, Plugin_Stop:
		{
			return false;
		}
	}
	
	if (GetCredits(client) < price)
	{
		if (!by_native)
		{
			CPrintToChat(client, "%t", "NotEnoughCredits");
		}
		return false;
	}
	
	if (!ItemManager_OnItemBuyEx(client, category_id, category, item_id, item, type, price, sell_price, (type == Item_Finite) ? count : duration))
	{
		return false;
	}
	
	if (type != Item_BuyOnly)
	{
		PlayerManager_GiveItemEx(client, sItemId, category_id, price, sell_price, count, duration, duration, type);
	}
	
	RemoveCredits(client, price, CREDITS_BY_BUY_OR_SELL);
	
	return true;
}

bool RemoveItemEx(int client, const char[] sItemId, int count = 1)
{
	if (IsItemToggledEx(client, sItemId))
	{
		ToggleItemEx(client, sItemId, Toggle_Off);
	}
	return PlayerManager_RemoveItemEx(client, sItemId, count);
}

bool GiveItem(int client, int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return GiveItemEx(client, sItemId);
}

bool GiveItemEx(int client, const char[] sItemId)
{
	int category_id, price, sell_price, count, duration;
	ItemType type;
	char item[SHOP_MAX_STRING_LENGTH];
	
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}

	switch (type)
	{
		case Item_BuyOnly :
		{
			char category[SHOP_MAX_STRING_LENGTH];
			ItemManager_GetCategoryById(category_id, category, sizeof(category));
			if (!ItemManager_OnItemBuyEx(client, category_id, category, StringToInt(sItemId), item, type, price, sell_price, (type == Item_Finite) ? count : duration))
			{
				return false;
			}
			return true;
		}
		case Item_None, Item_Togglable :
		{
			if (ClientHasItemEx(client, sItemId))
			{
				return false;
			}
		}
	}
	
	PlayerManager_GiveItemEx(client, sItemId, category_id, price, sell_price, count, duration, duration, type);
	
	return true;
}

bool SellItem(int client, int item_id)
{
	if (!PlayerManager_ClientHasItem(client, item_id))
	{
		return false;
	}
	
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	int category_id, price, sell_price, count, duration;
	ItemType type;
	char item[SHOP_MAX_STRING_LENGTH];
	
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}
	
	sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
	
	if (sell_price < 0)
	{
		return false;
	}
	
	char category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	int default_sellprice = sell_price;
	switch (Forward_OnItemSell(client, category_id, category, item_id, item, type, sell_price))
	{
		case Plugin_Continue :
		{
			sell_price = default_sellprice;
		}
		case Plugin_Handled, Plugin_Stop:
		{
			return false;
		}
	}
	
	if (!ItemManager_OnItemSellEx(client, category_id, category, item_id, item, type, sell_price))
	{
		return false;
	}
	
	PlayerManager_RemoveItemEx(client, sItemId);
	
	switch (type)
	{
		case Item_None, Item_Togglable :
		{
			OnPlayerItemElapsed(client, item_id, false);
		}
	}
	
	GiveCredits(client, sell_price, CREDITS_BY_BUY_OR_SELL);
	
	return true;
}

void PreviewItem(int client, int item_id)
{
	ItemManager_SetupPreview(client, item_id);
}

bool ToggleItem(int client, int item_id, ToggleState toggle, bool by_native = false, bool load = false)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ToggleItemEx(client, sItemId, toggle, by_native, load);
}

bool ToggleItemEx(int client, const char[] sItemId, ToggleState toggle, bool by_native = false, bool load = false)
{
	if (!PlayerManager_ClientHasItemEx(client, sItemId))
	{
		return false;
	}
	ShopAction action = ItemManager_OnUseToggleItemEx(client, sItemId, by_native, toggle);
	if (action == Shop_Raw)
	{
		return false;
	}
	return PlayerManager_ToggleItemEx(client, sItemId, action, load);
}

bool UseItem(int client, int item_id, bool by_native)
{
	if (!PlayerManager_ClientHasItem(client, item_id))
	{
		return false;
	}
	ShopAction action = ItemManager_OnUseToggleItem(client, item_id, false, Toggle, true);
	if (action != Shop_Raw)
	{
		return PlayerManager_RemoveItem(client, item_id);
	}
	if (by_native)
	{
		return true;
	}
	return false;
}

void OnAuthorized(int client)
{
	Forward_OnAuthorized(client);
	if (g_sChatCommand[0])
	{
		CPrintToChat(client, "%t", "DataLoaded", g_sChatCommand);
	}
	else
	{
		CPrintToChat(client, "%t", "DataLoaded2");
	}
}

void OnItemRegistered(int item_id)
{
	PlayerManager_OnItemRegistered(item_id);
}

void OnItemUnregistered(int item_id)
{
	PlayerManager_OnItemUnregistered(item_id);
}

int GetItemCountEx(int client, const char[] sItemId)
{
	return PlayerManager_GetItemCountEx(client, sItemId);
}

void OnMenuTitle(int client, ShopMenu menu_action, const char[] title, char[] sBuffer, int maxlength)
{
	Forward_OnMenuTitle(client, menu_action, title, sBuffer, maxlength);
}

int GetItemDurationEx(const char[] sItemId)
{
	return ItemManager_GetItemDurationEx(sItemId);
}

ItemType GetItemType(int item_id)
{
	return ItemManager_GetItemType(item_id);
}

ItemType GetItemTypeEx(const char[] sItemId)
{
	return ItemManager_GetItemTypeEx(sItemId);
}

int GetRandomIntEx(int min, int max)
{
	return Helpers_GetRandomIntEx(min, max);
}

bool ClientHasItem(int client, int item_id)
{
	return PlayerManager_ClientHasItem(client, item_id);
}

bool ClientHasItemEx(int client, const char[] sItemId)
{
	return PlayerManager_ClientHasItemEx(client, sItemId);
}

int GetClientCategorySize(int client, int category_id)
{
	return PlayerManager_GetClientCategorySize(client, category_id);
}

int GetCredits(int client)
{
	return PlayerManager_GetCredits(client);
}

bool SetCredits(int client, int credits, int by_who)
{
	if (credits < 1)
	{
		return false;
	}

	if (by_who != IGNORE_FORWARD_HOOK)
	{
		int dummy = credits;
		
		switch (Forward_OnCreditsSet(client, credits, by_who))
		{
			case Plugin_Continue :
			{
				credits = dummy;
			}
			case Plugin_Handled, Plugin_Stop :
			{
				return false;
			}
		}
	}

	PlayerManager_SetCredits(client, credits);

	Forward_OnCreditsSet_Post(client, credits, by_who);
	
	if (by_who > 0)
	{
		CPrintToChat(client, "%t", "set_you_credits", credits);
	}
	
	return true;
}

int RemoveCredits(int client, int credits, int by_who)
{
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		return -1;
	}
	if (credits < 1)
	{
		return 0;
	}
	
	if (by_who != IGNORE_FORWARD_HOOK)
	{
		int dummy = credits;
		
		switch (Forward_OnCreditsTaken(client, credits, by_who))
		{
			case Plugin_Continue :
			{
				credits = dummy;
			}
			case Plugin_Handled, Plugin_Stop :
			{
				return 0;
			}
		}
	}
	
	PlayerManager_RemoveCredits(client, credits);
	
	Forward_OnCreditsTaken_Post(client, credits, by_who);
	
	if (by_who > 0)
	{
		CPrintToChat(client, "%t", "take_you_credits", credits);
	}
	
	return credits;
}

int GiveCredits(int client, int credits, int by_who)
{
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		return -1;
	}
	if (credits < 1)
	{
		return 0;
	}
	
	if (by_who != IGNORE_FORWARD_HOOK)
	{
		int dummy = credits;
		
		switch (Forward_OnCreditsGiven(client, credits, by_who))
		{
			case Plugin_Continue :
			{
				credits = dummy;
			}
			case Plugin_Handled, Plugin_Stop :
			{
				return 0;
			}
		}
	}
	
	PlayerManager_GiveCredits(client, credits);

	Forward_OnCreditsGiven_Post(client, credits, by_who);
	
	if (by_who > 0)
	{
		CPrintToChat(client, "%t", "give_you_credits", credits);
	}
	
	return credits;
}

bool IsAuthorizedIn(int client)
{
	return PlayerManager_IsAuthorizedIn(client);
}

bool IsAdmin(int client)
{
	return view_as<bool>(GetUserFlagBits(client) & g_iAdminFlags);
}

bool FillCategories(Menu menu, int source_client, ShopMenu shop_menu, bool showAll = false)
{
	return ItemManager_FillCategories(menu, source_client, shop_menu, showAll);
}

bool FillItemsOfCategory(Menu menu, int client, int source_client, int category_id, bool showAll = false)
{
	return ItemManager_FillItemsOfCategory(menu, client, source_client, category_id, _, showAll);
}

int GetItemCategoryId(int item_id)
{
	return ItemManager_GetItemCategoryId(item_id);
}

int GetItemCategoryIdEx(char[] sItemId)
{
	return ItemManager_GetItemCategoryIdEx(sItemId);
}

bool AddTargetsToMenu(Menu menu, int source_client, bool credits = false)
{
	return Helpers_AddTargetsToMenu(menu, source_client, credits);
}

bool IsItemToggledEx(int client, const char[] sItemId)
{
	return PlayerManager_IsItemToggledEx(client, sItemId);
}

stock bool IsItemExists(int item_id)
{
	return ItemManager_IsItemExists(item_id);
}

bool IsItemExistsEx(char[] sItemId)
{
	return ItemManager_IsItemExistsEx(sItemId);
}

bool IsStarted()
{
	return is_started;
}

void OnPlayerItemElapsed(int client, int item_id, bool notify = true)
{
	ItemManager_OnPlayerItemElapsed(client, item_id);
	
	if (PlayerManager_IsItemToggled(client, item_id))
	{
		OnItemDequipped(client, item_id);
	}
	
	char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	GetCategoryDisplay(GetItemCategoryId(item_id), client, category, sizeof(category));
	GetItemDisplay(item_id, client, item, sizeof(item));
	
	if (notify)
	{
		CPrintToChat(client, "%t", "ItemElapsed", category, item);
	}
}

bool OnItemDisplay(int client, ShopMenu menu_action, int category_id, int item_id, const char[] display, char[] sBuffer, int maxlength)
{
	return Forward_OnItemDisplay(client, menu_action, category_id, item_id, display, sBuffer, maxlength);
}

bool OnItemPricesDisplay(int client, ShopMenu menu_action, int category_id, const char[] category, int item_id, const char[] item, int &price, int &sell_price)
{
	return Forward_OnItemPricesDisplay(client, menu_action, category_id, category, item_id, item, price, sell_price);
}

bool OnItemDescription(int client, ShopMenu menu_action, int category_id, int item_id, const char[] display, char[] sBuffer, int maxlength)
{
	return Forward_OnItemDescription(client, menu_action, category_id, item_id, display, sBuffer, maxlength);
}

void CallItemElapsedForward(int client, int category_id, char[] category, int item_id, char[] item)
{
	Forward_OnItemElapsed(client, category_id, category, item_id, item);
}

stock int FillArrayByItems(ArrayList array)
{
	return ItemManager_FillArrayByItems(array);
}

bool GetCategoryDisplay(int category_id, int source_client, char[] sBuffer, int maxlength)
{
	return ItemManager_GetCategoryDisplay(category_id, source_client, sBuffer, maxlength);
}

bool GetItemDisplay(int item_id, int source_client, char[] sBuffer, int maxlength)
{
	return ItemManager_GetItemDisplay(item_id, source_client, sBuffer, maxlength);
}

void OnItemEquipped(int client, int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	int category_id, price, sell_price, count, duration;
	ItemType type;
	char item[SHOP_MAX_STRING_LENGTH];
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return;
	}
	char category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	Forward_OnItemToggled(client, category_id, category, item_id, item, Toggle_On);
}

void OnItemDequipped(int client, int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	int category_id, price, sell_price, count, duration;
	ItemType type;
	char item[SHOP_MAX_STRING_LENGTH];
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return;
	}
	char category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	Forward_OnItemToggled(client, category_id, category, item_id, item, Toggle_Off);
}

int GetItemLuckChance(int item_id)
{
	return ItemManager_GetLuckChance(item_id);
}

bool OnClientLuckProcess(int client)
{
	return Forward_OnClientLuckProcess(client);
}

Action OnClientShouldLuckItemChance(int client, int item_id, int &iLuckChance)
{
	return Forward_OnClientShouldLuckItemChance(client, item_id, iLuckChance);
}

void OnClientItemLucked(int client, int item_id)
{
	Forward_OnClientItemLucked(client, item_id);
}

Action OnCreditsTransfer(int client, int target, int &credits_give, int &credits_remove, int &credits_commission, bool bPercent)
{
	return Forward_OnCreditsTransfer(client, target, credits_give, credits_remove, credits_commission, bPercent);
}

void OnCreditsTransfered(int client, int target, int credits_give, int credits_remove, int credits_commission)
{
	Forward_OnCreditsTransfered(client, target, credits_give, credits_remove, credits_commission);
}

void TryConnect()
{
	DB_TryConnect();
}

bool IsCallValid(Handle plugin, Function ptrFunction) {
	return (
		ptrFunction != INVALID_FUNCTION &&
		Helpers_IsPluginValid(plugin)
	);
}

bool IsPluginValid(Handle plugin)
{
	return Helpers_IsPluginValid(plugin);
}

void GetTimeFromStamp(char[] sBuffer, int maxlength, int timestamp, int source_client)
{
	Helpers_GetTimeFromStamp(sBuffer, maxlength, timestamp, source_client);
}

stock void FastQuery(const char[] query)
{
	DB_FastQuery(query);
}

void TQuery(SQLQueryCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
	DB_TQuery(callback, query, data, prio);
}

void TQueryEx(const char[] query, DBPriority prio = DBPrio_Normal)
{
	DB_TQueryEx(query, prio);
}

void EscapeString(const char[] string, char[] sBuffer, int maxlength, int &written = 0)
{
	DB_EscapeString(string, sBuffer, maxlength, written);
}

bool CheckClient(int client, char[] error, int length)
{
	return Helpers_CheckClient(client, error, length);
}
