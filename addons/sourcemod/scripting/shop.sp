#pragma semicolon 1

#include <sourcemod>
#include <shop>

#define GAME_UNDEFINED		0
#define GAME_CSS_34			1
#define GAME_CSS				2
#define GAME_CSGO				3

new Engine_Version = GAME_UNDEFINED;

new g_iExitButton = 10;

new global_timer;
new Handle:panel_info;
new Handle:g_hSortArray;

new ShopMenu:iClMenuId[MAXPLAYERS+1];
new iClCategoryId[MAXPLAYERS+1];
new iClItemId[MAXPLAYERS+1];
new iPos[MAXPLAYERS+1];
new bool:bInv[MAXPLAYERS+1];

new String:g_sChatCommand[24];
new String:g_sDbPrefix[12] = "shop_";
new bool:is_started;

new Handle:g_hAdminFlags, g_iAdminFlags;
new Handle:g_hItemTransfer, g_iItemTransfer;

#include "shop/colors.sp"
#include "shop/admin.sp"
#include "shop/commands.sp"
#include "shop/db.sp"
#include "shop/forwards.sp"
#include "shop/functions.sp"
#include "shop/helpers.sp"
#include "shop/item_manager.sp"
#include "shop/player_manager.sp"

public Plugin:myinfo =
{
	name = "[Shop] Core",
	description = "An advanced in game market",
	author = "FrozDark (Fork by R1KO)",
	// version = SHOP_VERSION,
	version = "3.0-[13-01-2017 Build]",
	url = "http://www.hlmod.ru/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
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

	Engine_Version = Helpers_GetCSGame();

	if (Engine_Version == GAME_CSGO)
	{
		g_iExitButton = 9;
	}
}

public Native_IsStarted(Handle:plugin, params)
{
	return IsStarted();
}

public Native_UnregisterMe(Handle:plugin, params)
{
	ItemManager_UnregisterMe(plugin);
}

public Native_ShowItemPanel(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	
	return ShowItemInfo(client, GetNativeCell(2));
}

public Native_OpenMainMenu(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		ThrowNativeError(1, "Client index %d is not authorized in the shop!", client);
	}
	ShowMainMenu(client);
}

public Native_ShowCategory(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	decl String:error[64];
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

public Native_ShowInventory(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	decl String:error[64];
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

public Native_ShowItemsOfCategory(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(1, error);
	}
	if (!PlayerManager_IsAuthorizedIn(client))
	{
		ThrowNativeError(1, "Client index %d is not authorized in the shop!", client);
	}
	new category_id = GetNativeCell(2);
	if (!ItemManager_IsValidCategory(category_id))
	{
		ThrowNativeError(1, "Category id %d is invalid!", category_id);
	}
	return ShowItemsOfCategory(client, category_id, GetNativeCell(3));
}

public OnPluginStart()
{
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
}

/*public OnAllPluginsLoaded()
{
	#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}

public OnLibraryAdded(const String:name[])
{
	#if defined _updater_included
	if (!strcmp(name, "updater"))
	{
        Updater_AddPlugin(UPDATE_URL);
	}
	#endif
}*/

public OnPluginEnd()
{
	PlayerManager_OnPluginEnd();
	ItemManager_OnPluginEnd();
}

public Action:OnEverySecond(Handle:timer)
{
	global_timer++;
}

CreateConfigs()
{
	CreateConVar("sm_advanced_shop_version", SHOP_VERSION, "Shop plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	decl String:sBuffer[PLATFORM_MAX_PATH];
	g_hAdminFlags = CreateConVar("sm_shop_admin_flags", "z", "Set flags for admin panel access. Set several flags if necessary. Ex: \"abcz\"");
	GetConVarString(g_hAdminFlags, sBuffer, sizeof(sBuffer));
	g_iAdminFlags = ReadFlagString(sBuffer);
	HookConVarChange(g_hAdminFlags, OnConVarChange);
	
	g_hItemTransfer = CreateConVar("sm_shop_item_transfer_credits", "500", "How many credits an item transfer cost. Set -1 to disable the feature", 0, true, -1.0);
	g_iItemTransfer = GetConVarInt(g_hItemTransfer);
	HookConVarChange(g_hItemTransfer, OnConVarChange);
	
	new Handle:kv_settings = CreateKeyValues("Settings");
	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "settings.txt");
	FileToKeyValues(kv_settings, sBuffer);
	
	Admin_OnSettingsLoad(kv_settings);
	DB_OnSettingsLoad(kv_settings);
	Commands_OnSettingsLoad(kv_settings);
	
	CloseHandle(kv_settings);
	
	AutoExecConfig(true, "shop", "shop");
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hAdminFlags)
	{
		g_iAdminFlags = ReadFlagString(newValue);
	}
	else if (convar == g_hItemTransfer)
	{
		g_iItemTransfer = StringToInt(newValue);
	}
}

public OnMapStart()
{
	DB_OnMapStart();
	
	if (panel_info != INVALID_HANDLE)
	{
		CloseHandle(panel_info);
		panel_info = INVALID_HANDLE;
	}
	
	if (g_hSortArray != INVALID_HANDLE)
	{
		CloseHandle(g_hSortArray);
		g_hSortArray = INVALID_HANDLE;
	}
	
	decl String:sBuffer[PLATFORM_MAX_PATH], Handle:hFile;
	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "shop_info.txt");
	
	hFile = OpenFile(sBuffer, "r");
	if (hFile != INVALID_HANDLE)
	{
		panel_info = CreatePanel();
		
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
		{
			if (sBuffer[0])
			{
				DrawPanelText(panel_info, sBuffer);
			}
		}
		
		DrawPanelItem(panel_info, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		CloseHandle(hFile);
	}

	Shop_GetCfgFile(sBuffer, sizeof(sBuffer), "shop_sort.txt");
	
	hFile = OpenFile(sBuffer, "r");
	if (hFile != INVALID_HANDLE)
	{
		g_hSortArray = CreateArray(ByteCountToCells(SHOP_MAX_STRING_LENGTH));
		
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);
			if (sBuffer[0])
			{
				PushArrayString(g_hSortArray, sBuffer);
			}
		}
		
		if(!GetArraySize(g_hSortArray))
		{
			CloseHandle(g_hSortArray);
			g_hSortArray = INVALID_HANDLE;
		}

		CloseHandle(hFile);
	}
}

public OnMapEnd()
{
	Functions_OnMapEnd();
	PlayerManager_OnMapEnd();
}

ShowInfo(client)
{
	if (panel_info != INVALID_HANDLE)
	{
		SetGlobalTransTarget(client);
		
		decl String:sBuffer[32];
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
		SetPanelCurrentKey(panel_info, 1);
		DrawPanelItem(panel_info, sBuffer, ITEMDRAW_CONTROL);
		
		DrawPanelItem(panel_info, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
		SetPanelCurrentKey(panel_info, g_iExitButton);
		DrawPanelItem(panel_info, sBuffer, ITEMDRAW_CONTROL);
		
		SendPanelToClient(panel_info, client, InfoHandle, MENU_TIME_FOREVER);
	}
}

public InfoHandle(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			if (param2 != 10)
			{
				ShowMainMenu(param1);
			}
		}
	}
}

DatabaseClear()
{
	PlayerManager_DatabaseClear();
}

bool:IsInGame(player_id)
{
	return PlayerManager_IsInGame(player_id);
}

OnReadyToStart()
{
	if (!is_started)
	{
		is_started = true;
		
		Forward_NotifyShopLoaded();
		PlayerManager_OnReadyToStart();
		
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				OnClientPutInServer(client);
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if (!IsStarted() || IsFakeClient(client))
	{
		return;
	}
	PlayerManager_OnClientPutInServer(client);
}

public OnClientDisconnect_Post(client)
{
	Functions_OnClientDisconnect_Post(client);
	PlayerManager_OnClientDisconnect_Post(client);
}

public Action:Command_Say(client, const String:command[], argc)
{
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	StripQuotes(text);
	TrimString(text);
	
	if (Functions_OnClientSayCommand(client, text) != Plugin_Continue)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

ShowMainMenu(client, pos = 0)
{
	new Handle:menu = CreateMenu(MainMenu_Handler);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, false);
	
	decl String:sBuffer[192];
	FormatEx(sBuffer, sizeof(sBuffer), "%T\n%T", "MainMenuTitle", client, "credits", client, PlayerManager_GetCredits(client));
	OnMenuTitle(client, Menu_Main, sBuffer, sBuffer, sizeof(sBuffer));
	SetMenuTitle(menu, sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "buy", client);
	AddMenuItem(menu, "0", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%T\n ", "inventory", client);
	AddMenuItem(menu, "2", sBuffer);
	
	FormatEx(sBuffer, sizeof(sBuffer), "%T\n ", "functions", client);
	AddMenuItem(menu, "3", sBuffer);
	
	if (panel_info != INVALID_HANDLE)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T\n ", "info", client);
		AddMenuItem(menu, "4", sBuffer);
	}
	
	if (g_iAdminFlags != 0 && (GetUserFlagBits(client) & g_iAdminFlags) && GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "admin_panel", client);
		AddMenuItem(menu, "5", sBuffer);
	}
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
}

public MainMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
		case MenuAction_Select :
		{
			decl String:info[4];
			GetMenuItem(menu, param2, info, sizeof(info));
			
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
}

bool:ShowInventory(client)
{
	new Handle:menu = CreateMenu(OnInventorySelect);
	if (!ItemManager_FillCategories(menu, client, true))
	{
		CloseHandle(menu);
		return false;
	}
	
	decl String:title[128];
	FormatEx(title, sizeof(title), "%T\n%T", "inventory", client, "credits", client, PlayerManager_GetCredits(client));
	OnMenuTitle(client, Menu_Inventory, title, title, sizeof(title));
	SetMenuTitle(menu, title);
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	iClMenuId[client] = Menu_Inventory;
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public OnInventorySelect(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));

			new category_id = StringToInt(info);
			
			if (!ItemManager_OnCategorySelect(param1, category_id, Menu_Inventory))
			{
				return;
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
			CloseHandle(menu);
		}
	}
}

bool:ShowCategories(client)
{
	new Handle:menu = CreateMenu(OnCategorySelect);
	
	if (!ItemManager_FillCategories(menu, client, false))
	{
		CloseHandle(menu);
		return false;
	}
	
	decl String:title[128];
	FormatEx(title, sizeof(title), "%T\n%T", "Shop", client, "credits", client, PlayerManager_GetCredits(client));
	OnMenuTitle(client, Menu_Buy, title, title, sizeof(title));
	SetMenuTitle(menu, title);
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	iClMenuId[client] = Menu_Buy;
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public OnCategorySelect(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new category_id = StringToInt(info);
			
			if (!ItemManager_OnCategorySelect(param1, category_id, Menu_Buy))
			{
				return;
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
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
}

bool:ShowItemsOfCategory(client, category_id, bool:inventory, pos = 0)
{
	new Handle:menu = CreateMenu(OnItemSelect, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);
	if (!ItemManager_FillItemsOfCategory(menu, client, client, category_id, inventory))
	{
		CloseHandle(menu);
		return false;
	}
	decl String:title[128];
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
	
	SetMenuTitle(menu, title);
	
	bInv[client] = inventory;
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	iClCategoryId[client] = category_id;
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
	
	return true;
}

public OnItemSelect(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			iPos[param1] = GetMenuSelectionPosition();
			if (!ShowItemInfo(param1, StringToInt(info)))
			{
				ShowItemsOfCategory(param1, iClCategoryId[param1], bInv[param1], iPos[param1]);
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
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
		case MenuAction_DrawItem :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new bool:disabled;
			
			switch (Forward_OnItemDraw(param1, bInv[param1] ? Menu_Inventory : Menu_Buy, iClCategoryId[param1], StringToInt(info), disabled))
			{
				case Plugin_Continue:
				{
					disabled = false;
				}
				case Plugin_Handled, Plugin_Stop:
				{
					RemoveMenuItem(menu, param2);
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
			decl String:info[16], String:sBuffer[SHOP_MAX_STRING_LENGTH];
			GetMenuItem(menu, param2, info, sizeof(info), _, sBuffer, sizeof(sBuffer));
			
			new bool:result = Forward_OnItemDisplay(param1, bInv[param1] ? Menu_Inventory : Menu_Buy, iClCategoryId[param1], StringToInt(info), sBuffer, sBuffer, sizeof(sBuffer));
			
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
							new timeleft = PlayerManager_GetItemTimeleftEx(param1, info);
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
						new timeleft = PlayerManager_GetItemTimeleftEx(param1, info);
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
#define BUTTON_BACK 7
#define BUTTON_EXIT 10

new iButton[MAXPLAYERS+1][11];

bool:ShowItemInfo(client, item_id)
{
	new Handle:panel = ItemManager_CreateItemPanelInfo(client, item_id, bInv[client] ? Menu_Inventory : Menu_Buy);
	if (panel != INVALID_HANDLE)
	{
		decl String:sBuffer[SHOP_MAX_STRING_LENGTH], String:sItemId[16];
		IntToString(item_id, sItemId, sizeof(sItemId));
		SetGlobalTransTarget(client);
		
		new credits = GetCredits(client);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n ", "credits", credits);
		SetPanelTitle(panel, sBuffer, false);
		
		new ItemType:type = ItemManager_GetItemTypeEx(sItemId);
		
		new button = 1;
		
		switch (type)
		{
			case Item_None :
			{
				if (PlayerManager_ClientHasItemEx(client, sItemId))
				{
					new timeleft = PlayerManager_GetItemTimeleftEx(client, sItemId);
					new sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
					if (timeleft > 0)
					{
						GetTimeFromStamp(sBuffer, sizeof(sBuffer), timeleft, client);
						Format(sBuffer, sizeof(sBuffer), "%t: %s", "timeleft", sBuffer);
						DrawPanelText(panel, sBuffer);
						
						if (sell_price > -1)
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "absolute_sellprice", sell_price);
							DrawPanelText(panel, sBuffer);
						}
						DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
					}
					if (sell_price > -1)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t [+%d]", "sell", sell_price);
						DrawPanelItem(panel, sBuffer);
						iButton[client][button++] = BUTTON_SELL;
					}
					switch (g_iItemTransfer)
					{
						case -1 :
						{
						}
						case 0 :
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
							DrawPanelItem(panel, sBuffer);
							iButton[client][button++] = BUTTON_TRANSFER;
						}
						default :
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t [%t: %d]", "transfer", "Price", g_iItemTransfer);
							DrawPanelItem(panel, sBuffer, (credits < g_iItemTransfer) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
							iButton[client][button++] = BUTTON_TRANSFER;
						}
					}
				}
				else
				{
					if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
						DrawPanelItem(panel, sBuffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
						DrawPanelItem(panel, sBuffer);
					}
					iButton[client][button++] = BUTTON_BUY;
				}
			}
			case Item_Finite :
			{
				new count = PlayerManager_GetItemCountEx(client, sItemId);
				FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "You have", count);
				DrawPanelText(panel, sBuffer);
				
				DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
				
				if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
					DrawPanelItem(panel, sBuffer, ITEMDRAW_DISABLED);
				}
				else
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
					DrawPanelItem(panel, sBuffer);
				}
				
				iButton[client][button++] = BUTTON_BUY;
				
				if (count > 0)
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "use");
					DrawPanelItem(panel, sBuffer);
					iButton[client][button++] = BUTTON_USE;
					
					new sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
					
					if (sell_price > -1)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t [+%d]", "sell", sell_price);
						DrawPanelItem(panel, sBuffer);
						iButton[client][button++] = BUTTON_SELL;
					}
					switch (g_iItemTransfer)
					{
						case -1 :
						{
						}
						case 0 :
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
							DrawPanelItem(panel, sBuffer);
							iButton[client][button++] = BUTTON_TRANSFER;
						}
						default :
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t [%t: %d]", "transfer", "Price", g_iItemTransfer);
							DrawPanelItem(panel, sBuffer, (credits < g_iItemTransfer) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
							iButton[client][button++] = BUTTON_TRANSFER;
						}
					}
				}
			}
			case Item_Togglable :
			{
				if (PlayerManager_ClientHasItemEx(client, sItemId))
				{
					new timeleft = PlayerManager_GetItemTimeleftEx(client, sItemId);
					new sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
					if (timeleft > 0)
					{
						GetTimeFromStamp(sBuffer, sizeof(sBuffer), timeleft, client);
						Format(sBuffer, sizeof(sBuffer), "%t: %s", "timeleft", sBuffer);
						DrawPanelText(panel, sBuffer);
						
						if (sell_price > -1)
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "absolute_sellprice", sell_price);
							DrawPanelText(panel, sBuffer);
						}
						DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
					}
					if (PlayerManager_IsItemToggledEx(client, sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "ToggleOff");
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "ToggleOn");
					}
					DrawPanelItem(panel, sBuffer);
					iButton[client][button++] = BUTTON_TOGGLE;
					
					if (sell_price > -1)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t [+%d]", "sell", sell_price);
						DrawPanelItem(panel, sBuffer);
						iButton[client][button++] = BUTTON_SELL;
					}
					switch (g_iItemTransfer)
					{
						case -1 :
						{
						}
						case 0 :
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
							DrawPanelItem(panel, sBuffer);
							iButton[client][button++] = BUTTON_TRANSFER;
						}
						default :
						{
							FormatEx(sBuffer, sizeof(sBuffer), "%t [%t: %d]", "transfer", "Price", g_iItemTransfer);
							DrawPanelItem(panel, sBuffer, (credits < g_iItemTransfer) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
							iButton[client][button++] = BUTTON_TRANSFER;
						}
					}
				}
				else
				{
					if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
						DrawPanelItem(panel, sBuffer, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
						DrawPanelItem(panel, sBuffer);
					}
					iButton[client][button++] = BUTTON_BUY;
					
					if (ItemManager_CanPreview(item_id))
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "preview");
						DrawPanelItem(panel, sBuffer);
					}
					else
					{
						FormatEx(sBuffer, sizeof(sBuffer), "%t", "preview_unavailable");
						DrawPanelItem(panel, sBuffer, ITEMDRAW_DISABLED);
					}
					iButton[client][button++] = BUTTON_PREVIEW;
				}
			}
			case Item_BuyOnly :
			{
				if (GetCredits(client) < ItemManager_GetItemPriceEx(sItemId))
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy_not");
					DrawPanelItem(panel, sBuffer, ITEMDRAW_DISABLED);
				}
				else
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%t", "buy");
					DrawPanelItem(panel, sBuffer);
				}
				iButton[client][button++] = BUTTON_BUY;
			}
		}
		
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		SetPanelCurrentKey(panel, g_iExitButton-2);
		iButton[client][g_iExitButton-2] = BUTTON_BACK;
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
		DrawPanelItem(panel, sBuffer, ITEMDRAW_CONTROL);
		
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		SetPanelCurrentKey(panel, g_iExitButton);
		iButton[client][10] = BUTTON_EXIT;
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
		DrawPanelItem(panel, sBuffer, ITEMDRAW_CONTROL);
		
		iClItemId[client] = item_id;
		
		SendPanelToClient(panel, client, ItemPanel_Handler, MENU_TIME_FOREVER);
		CloseHandle(panel);
		
		return true;
	}
	return false;
}

public ItemPanel_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			new bool:has = ClientHasItem(param1, iClItemId[param1]);
			
			switch (iButton[param1][param2])
			{
				case BUTTON_BUY :
				{
					BuyItem(param1, iClItemId[param1], false);
					ShowItemInfo(param1, iClItemId[param1]);
				}
				case BUTTON_SELL :
				{
					if (has)
					{
						SellItem(param1, iClItemId[param1]);
					}
					if (bInv[param1] && PlayerManager_GetItemCount(param1, iClItemId[param1]) < 1)
					{
						if (!ShowItemsOfCategory(param1, iClCategoryId[param1], true, iPos[param1]) && !ShowInventory(param1))
						{
							ShowMainMenu(param1);
							CPrintToChat(param1, "%t", "EmptyInventory");
						}
					}
					else
					{
						ShowItemInfo(param1, iClItemId[param1]);
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
				case BUTTON_BACK :
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

bool:SetupItemTransfer(client, pos = 0)
{
	new Handle:menu = CreateMenu(Menu_TransItemHandler);
	
	if (!FillMenuByItemTransTarget(menu, client, iClItemId[client]))
	{
		CloseHandle(menu);
		return false;
	}
	
	decl String:title[128];
	FormatEx(title, sizeof(title), "%T", "ItemTransferMenu", client);
	OnMenuTitle(client, Menu_ItemTransfer, title, title, sizeof(title));
	SetMenuTitle(menu, title);
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
	
	return true;
}

new g_iItemTransTarget[MAXPLAYERS+1];
public Menu_TransItemHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new userid = StringToInt(info);
			new target = GetClientOfUserId(userid);
			
			if (!target)
			{
				SetupItemTransfer(param1);
				CPrintToChat(param1, "%t", "target_left_game");
				return;
			}
			new ItemType:type = GetItemType(iClItemId[param1]);
			if (type != Item_Finite && ClientHasItem(target, iClItemId[param1]))
			{
				SetupItemTransfer(param1, GetMenuSelectionPosition());
				CPrintToChat(param1, "%t", "already_has", target);
				return;
			}
			if (!ClientHasItem(param1, iClItemId[param1]))
			{
				ShowItemInfo(param1, iClItemId[param1]);
				CPrintToChat(param1, "%t", "no_item");
				return;
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
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
}

ShowTransItemInfo(client)
{
	new target = GetClientOfUserId(g_iItemTransTarget[client]);
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
	
	new Handle:panel = CreatePanel();
	
	decl String:sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "ItemTransferMenu2", target);
	SetPanelTitle(panel, sBuffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	GetCategoryDisplay(GetItemCategoryId(iClItemId[client]), client, category, sizeof(category));
	ItemManager_GetItemDisplay(iClItemId[client], client, item, sizeof(item));
	FormatEx(sBuffer, sizeof(sBuffer), "%s - %s", category, item);
	DrawPanelText(panel, sBuffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	if (GetItemType(iClItemId[client]) == Item_Finite)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%N: %d", target, PlayerManager_GetItemCount(target, iClItemId[client]));
		DrawPanelText(panel, sBuffer);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t: %d", "You have", PlayerManager_GetItemCount(client, iClItemId[client]));
		DrawPanelText(panel, sBuffer);
		
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	}
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "transfer");
	DrawPanelItem(panel, sBuffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	SetPanelCurrentKey(panel, 8);
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Back");
	DrawPanelItem(panel, sBuffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	SetPanelCurrentKey(panel, g_iExitButton);
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Exit");
	DrawPanelItem(panel, sBuffer);
	
	SendPanelToClient(panel, client, ItemTransPanel_Handler, MENU_TIME_FOREVER);
}

public ItemTransPanel_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			switch (param2)
			{
				case 1 :
				{
					new target = GetClientOfUserId(g_iItemTransTarget[param1]);
					if (!target)
					{
						ShowItemInfo(param1, iClItemId[param1]);
						CPrintToChat(param1, "%t", "target_left_game");
						return;
					}
					
					if (!Forward_OnItemTransfer(param1, target, iClItemId[param1]))
					{
						ShowItemInfo(param1, iClItemId[param1]);
						return;
					}
					
					PlayerManager_TransferItem(param1, target, iClItemId[param1]);
					
					RemoveCredits(param1, g_iItemTransfer, CREDITS_BY_BUY_OR_SELL);
					
					Forward_OnItemTransfered(param1, target, iClItemId[param1]);
					
					decl String:item[SHOP_MAX_STRING_LENGTH], String:category[SHOP_MAX_STRING_LENGTH];
					ItemManager_GetItemDisplay(iClItemId[param1], target, item, sizeof(item));
					ItemManager_GetCategoryDisplay(GetItemCategoryId(iClItemId[param1]), target, category, sizeof(category));
					CPrintToChat(target, "%t", "receive_item", param1, category, item);
					
					ShowTransItemInfo(param1);
				}
				case 8 :
				{
					SetupItemTransfer(param1);
				}
			}
		}
	}
}

bool:FillMenuByItemTransTarget(Handle:menu, client, item_id)
{
	new ItemType:type = GetItemType(item_id);
	
	new bool:result = false;
	
	decl String:userid[9], String:sBuffer[MAX_NAME_LENGTH+21];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsAuthorizedIn(i))
		{
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			
			if (type == Item_Finite)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%N (%d)", i, PlayerManager_GetItemCount(i, item_id));
				AddMenuItem(menu, userid, sBuffer);
			}
			else
			{
				if (ClientHasItem(i, item_id))
				{
					FormatEx(sBuffer, sizeof(sBuffer), "[+] %N", i);
					AddMenuItem(menu, userid, sBuffer, ITEMDRAW_DISABLED);
				}
				else
				{
					GetClientName(i, sBuffer, sizeof(sBuffer));
					AddMenuItem(menu, userid, sBuffer);
				}
			}
			
			result = true;
		}
	}
	
	return result;
}

bool:BuyItem(client, item_id, bool:by_native)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	decl category_id, price, sell_price, count, duration, ItemType:type, String:item[SHOP_MAX_STRING_LENGTH];
	
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}
	
	decl String:category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	new Action:result;
	
	new default_price = price;
	new default_sellprice = sell_price;
	new default_value;
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
		PlayerManager_GiveItemEx(client, sItemId, category_id, price, sell_price, count, duration, type);
	}
	
	RemoveCredits(client, price, CREDITS_BY_BUY_OR_SELL);
	
	return true;
}

bool:RemoveItemEx(client, const String:sItemId[], count = 1)
{
	if (IsItemToggledEx(client, sItemId))
	{
		ToggleItemEx(client, sItemId, Toggle_Off);
	}
	return PlayerManager_RemoveItemEx(client, sItemId, count);
}

bool:GiveItem(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return GiveItemEx(client, sItemId);
}

bool:GiveItemEx(client, const String:sItemId[])
{
	decl category_id, price, sell_price, count, duration, ItemType:type, String:item[SHOP_MAX_STRING_LENGTH];
	
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}
	
	if (type == Item_BuyOnly)
	{
		decl String:category[SHOP_MAX_STRING_LENGTH];
		ItemManager_GetCategoryById(category_id, category, sizeof(category));
		if (!ItemManager_OnItemBuyEx(client, category_id, category, StringToInt(sItemId), item, type, price, sell_price, (type == Item_Finite) ? count : duration))
		{
			return false;
		}
		return true;
	}
	
	PlayerManager_GiveItemEx(client, sItemId, category_id, price, sell_price, count, duration, type);
	
	return true;
}

bool:SellItem(client, item_id)
{
	if (!PlayerManager_ClientHasItem(client, item_id))
	{
		return false;
	}
	
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	decl category_id, price, sell_price, count, duration, ItemType:type, String:item[SHOP_MAX_STRING_LENGTH];
	
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}
	
	sell_price = PlayerManager_GetItemSellPriceEx(client, sItemId);
	
	if (sell_price < 0)
	{
		return false;
	}
	
	decl String:category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	new default_sellprice = sell_price;
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

PreviewItem(client, item_id)
{
	ItemManager_SetupPreview(client, item_id);
}

bool:ToggleItem(client, item_id, ToggleState:toggle, bool:by_native = false, bool:load = false)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ToggleItemEx(client, sItemId, toggle, by_native, load);
}

bool:ToggleItemEx(client, const String:sItemId[], ToggleState:toggle, bool:by_native = false, bool:load = false)
{
	if (!PlayerManager_ClientHasItemEx(client, sItemId))
	{
		return false;
	}
	new ShopAction:action = ItemManager_OnUseToggleItemEx(client, sItemId, by_native, toggle);
	if (action == Shop_Raw)
	{
		return false;
	}
	return PlayerManager_ToggleItemEx(client, sItemId, action, load);
}

bool:UseItem(client, item_id, bool:by_native)
{
	if (!PlayerManager_ClientHasItem(client, item_id))
	{
		return false;
	}
	new ShopAction:action = ItemManager_OnUseToggleItem(client, item_id, false, Toggle, true);
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

OnAuthorized(client)
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

OnItemRegistered(item_id)
{
	PlayerManager_OnItemRegistered(item_id);
}

OnItemUnregistered(item_id)
{
	PlayerManager_OnItemUnregistered(item_id);
}

GetItemCountEx(client, const String:sItemId[])
{
	return PlayerManager_GetItemCountEx(client, sItemId);
}

OnMenuTitle(client, ShopMenu:menu_action, const String:title[], String:sBuffer[], maxlength)
{
	Forward_OnMenuTitle(client, menu_action, title, sBuffer, maxlength);
}

GetItemDurationEx(const String:sItemId[])
{
	return ItemManager_GetItemDurationEx(sItemId);
}

ItemType:GetItemType(item_id)
{
	return ItemManager_GetItemType(item_id);
}

ItemType:GetItemTypeEx(const String:sItemId[])
{
	return ItemManager_GetItemTypeEx(sItemId);
}

GetRandomIntEx(min, max)
{
	return Helpers_GetRandomIntEx(min, max);
}

bool:ClientHasItem(client, item_id)
{
	return PlayerManager_ClientHasItem(client, item_id);
}

bool:ClientHasItemEx(client, const String:sItemId[])
{
	return PlayerManager_ClientHasItemEx(client, sItemId);
}

GetClientCategorySize(client, category_id)
{
	return PlayerManager_GetClientCategorySize(client, category_id);
}

GetCredits(client)
{
	return PlayerManager_GetCredits(client);
}

SetCredits(client, credits, bool:by_admin = false)
{
	PlayerManager_SetCredits(client, credits);
	
	if (by_admin)
	{
		CPrintToChat(client, "%t", "set_you_credits", credits);
	}
}

RemoveCredits(client, credits, by_who)
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
		new dummy = credits;
		
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
	
	if (by_who > 0)
	{
		CPrintToChat(client, "%t", "take_you_credits", credits);
	}
	
	return credits;
}

GiveCredits(client, credits, by_who)
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
		new dummy = credits;
		
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
	
	if (by_who > 0)
	{
		CPrintToChat(client, "%t", "give_you_credits", credits);
	}
	
	return credits;
}

bool:IsAuthorizedIn(client)
{
	return PlayerManager_IsAuthorizedIn(client);
}

bool:IsAdmin(client)
{
	return bool:(GetUserFlagBits(client) & g_iAdminFlags);
}

bool:FillCategories(Handle:menu, source_client, bool:inventory = false)
{
	return ItemManager_FillCategories(menu, source_client, inventory);
}

bool:FillItemsOfCategory(Handle:menu, client, source_client, category_id)
{
	return ItemManager_FillItemsOfCategory(menu, client, source_client, category_id);
}

GetItemCategoryId(item_id)
{
	return ItemManager_GetItemCategoryId(item_id);
}

GetItemCategoryIdEx(String:sItemId[])
{
	return ItemManager_GetItemCategoryIdEx(sItemId);
}

bool:AddTargetsToMenu(Handle:menu, source_client, bool:credits = false)
{
	return Helpers_AddTargetsToMenu(menu, source_client, credits);
}

bool:IsItemToggledEx(client, const String:sItemId[])
{
	return PlayerManager_IsItemToggledEx(client, sItemId);
}

stock bool:IsItemExists(item_id)
{
	return ItemManager_IsItemExists(item_id);
}

bool:IsItemExistsEx(String:sItemId[])
{
	return ItemManager_IsItemExistsEx(sItemId);
}

bool:IsStarted()
{
	return is_started;
}

OnPlayerItemElapsed(client, item_id, bool:notify = true)
{
	ItemManager_OnPlayerItemElapsed(client, item_id);
	
	if (PlayerManager_IsItemToggled(client, item_id))
	{
		OnItemDequipped(client, item_id);
	}
	
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	GetCategoryDisplay(GetItemCategoryId(item_id), client, category, sizeof(category));
	GetItemDisplay(item_id, client, item, sizeof(item));
	
	if (notify)
	{
		CPrintToChat(client, "%t", "ItemElapsed", category, item);
	}
}

bool:OnItemDisplay(client, ShopMenu:menu_action, category_id, item_id, const String:display[], String:sBuffer[], maxlength)
{
	return Forward_OnItemDisplay(client, menu_action, category_id, item_id, display, sBuffer, maxlength);
}

bool:OnItemDescription(client, ShopMenu:menu_action, category_id, item_id, const String:display[], String:sBuffer[], maxlength)
{
	return Forward_OnItemDescription(client, menu_action, category_id, item_id, display, sBuffer, maxlength);
}

CallItemElapsedForward(client, category_id, String:category[], item_id, String:item[])
{
	Forward_OnItemElapsed(client, category_id, category, item_id, item);
}

stock FillArrayByItems(Handle:array)
{
	return ItemManager_FillArrayByItems(array);
}

bool:GetCategoryDisplay(category_id, source_client, String:sBuffer[], maxlength)
{
	return ItemManager_GetCategoryDisplay(category_id, source_client, sBuffer, maxlength);
}

bool:GetItemDisplay(item_id, source_client, String:sBuffer[], maxlength)
{
	return ItemManager_GetItemDisplay(item_id, source_client, sBuffer, maxlength);
}

OnItemEquipped(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	decl category_id, price, sell_price, count, duration, ItemType:type, String:item[SHOP_MAX_STRING_LENGTH];
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return;
	}
	decl String:category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	Forward_OnItemToggled(client, category_id, category, item_id, item, Toggle_On);
}

OnItemDequipped(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	decl category_id, price, sell_price, count, duration, ItemType:type, String:item[SHOP_MAX_STRING_LENGTH];
	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return;
	}
	decl String:category[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	
	Forward_OnItemToggled(client, category_id, category, item_id, item, Toggle_Off);
}

bool:OnLuckProcess(client)
{
	return Forward_OnLuckProcess(client);
}

bool:OnItemLuck(client, item_id)
{
	return Forward_OnItemLuck(client, item_id);
}

OnItemLucked(client, item_id)
{
	Forward_OnItemLucked(client, item_id);
}

Action:OnCreditsTransfer(client, target, &credits_give, &credits_remove)
{
	return Forward_OnCreditsTransfer(client, target, credits_give, credits_remove);
}

OnCreditsTransfered(client, target, credits_give, credits_remove)
{
	Forward_OnCreditsTransfered(client, target, credits_give, credits_remove);
}

TryConnect()
{
	DB_TryConnect();
}

bool:IsPluginValid(Handle:plugin)
{
	return Helpers_IsPluginValid(plugin);
}

GetTimeFromStamp(String:sBuffer[], maxlength, timestamp, source_client)
{
	Helpers_GetTimeFromStamp(sBuffer, maxlength, timestamp, source_client);
}

stock FastQuery(const String:query[])
{
	DB_FastQuery(query);
}

TQuery(SQLTCallback:callback, const String:query[], any:data, DBPriority:prio = DBPrio_Normal)
{
	DB_TQuery(callback, query, data, prio);
}

TQueryEx(const String:query[], DBPriority:prio = DBPrio_Normal)
{
	DB_TQueryEx(query, prio);
}

EscapeString(const String:string[], String:sBuffer[], maxlength, &written = 0)
{
	DB_EscapeString(string, sBuffer, maxlength, written);
}

bool:CheckClient(client, String:error[], length)
{
	return Helpers_CheckClient(client, error, length);
}