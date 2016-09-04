#define GIVE_CREDITS	0
#define TAKE_CREDITS	1
#define SET_CREDITS		2
#define GIVE_ITEMS		3
#define TAKE_ITEMS		4
#define ADD_PLAYERS		5

#define ADMINPANEL_PLUGIN 0
#define ADMINPANEL_DISPLAY 1
#define ADMINPANEL_SELECT 2

enum AdminEnum
{
	AdminOption = 0,
	AdminTarget,
	AdminCategory
};

new AdminEnum:g_iOpt[MAXPLAYERS+1][AdminEnum];

new Handle:count_menu;

new Handle:g_hAdminArray;

Admin_CreateNatives()
{
	g_hAdminArray = CreateArray(3);
	
	CreateNative("Shop_AddToAdminMenu", Admin_AddToMenuNative);
	CreateNative("Shop_RemoveFromAdminMenu", Admin_RemoveFromMenuNative);
	CreateNative("Shop_ShowAdminMenu", Admin_ShowAdminMenu);
}

public Admin_AddToMenuNative(Handle:plugin, params)
{
	decl any:tmp[3];
	tmp[ADMINPANEL_PLUGIN] = plugin;
	tmp[ADMINPANEL_DISPLAY] = GetNativeCell(1);
	tmp[ADMINPANEL_SELECT] = GetNativeCell(2);
	
	PushArrayArray(g_hAdminArray, tmp);
}

public Admin_RemoveFromMenuNative(Handle:plugin, params)
{
	decl any:tmp[3];
	
	new index = -1;
	while ((index = FindValueInArray(g_hAdminArray, plugin)) != -1)
	{
		GetArrayArray(g_hAdminArray, index, tmp);
		if (tmp[ADMINPANEL_DISPLAY] == GetNativeCell(1) && tmp[ADMINPANEL_SELECT] == GetNativeCell(2))
		{
			RemoveFromArray(g_hAdminArray, index);
			return true;
		}
	}
	
	return false;
}

public Admin_ShowAdminMenu(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	Admin_ShowMenu(client);
}

Admin_OnSettingsLoad(Handle:kv)
{
	count_menu = CreateMenu(Admin_MenuCount_Handler, MENU_ACTIONS_DEFAULT|MenuAction_Display);
	
	if (KvJumpToKey(kv, "Count_Menu", false))
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			SetMenuExitButton(count_menu, true);
			SetMenuExitBackButton(count_menu, true);
			
			decl String:amount[24], String:buffer[64];
			do
			{
				if (KvGetSectionName(kv, amount, sizeof(amount)))
				{
					KvGetString(kv, NULL_STRING, buffer, sizeof(buffer));
					if (amount[0] && buffer[0])
					{
						AddMenuItem(count_menu, amount, buffer);
					}
				}
			}
			while (KvGotoNextKey(kv, false));
		}
		KvRewind(kv);
	}
	
	if (!GetMenuItemCount(count_menu))
	{
		AddMenuItem(count_menu, "1", "1 credit");
		AddMenuItem(count_menu, "10", "10 credits");
		AddMenuItem(count_menu, "100", "Hundred credits");
		AddMenuItem(count_menu, "1000", "Thousand credits");
		AddMenuItem(count_menu, "10000", "10000 credits");
		AddMenuItem(count_menu, "100000", "100000 credits");
		AddMenuItem(count_menu, "1000000", "Million credits");
	}
}

public Admin_MenuCount_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Display :
		{
			new target = GetClientOfUserId(g_iOpt[param1][AdminTarget]);
			
			if (!target)
			{
				return;
			}
			
			switch (g_iOpt[param1][AdminOption])
			{
				case GIVE_CREDITS :
				{
					SetMenuTitle(menu, "%T\n%N (%d)\n ", "give_credits", param1, target, GetCredits(target));
				}
				case TAKE_CREDITS :
				{
					SetMenuTitle(menu, "%T\n%N (%d)\n ", "take_credits", param1, target, GetCredits(target));
				}
				case SET_CREDITS :
				{
					SetMenuTitle(menu, "%T\n%N (%d)\n ", "set_credits", param1, target, GetCredits(target));
				}
			}
		}
		case MenuAction_Select :
		{
			new target = GetClientOfUserId(g_iOpt[param1][AdminTarget]);
			
			if (!target)
			{
				CPrintToChat(param1, "target_left_game");
				Admin_ShowMenu(param1);
				return;
			}
			
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			switch (g_iOpt[param1][AdminOption])
			{
				case GIVE_CREDITS :
				{
					GiveCredits(target, StringToInt(info), true);
					Admin_ShowCreditsAmount(param1, GetMenuSelectionPosition());
				}
				case TAKE_CREDITS :
				{
					RemoveCredits(target, StringToInt(info), true);
					Admin_ShowCreditsAmount(param1, GetMenuSelectionPosition());
				}
				case SET_CREDITS :
				{
					SetCredits(target, StringToInt(info), true);
					Admin_ShowMenu(param1);
				}
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowTargetsMenu(param1);
			}
		}
	}
}

Admin_ShowMenu(client, pos = 0)
{
	SetGlobalTransTarget(client);
	
	new Handle:menu = CreateMenu(Admin_Menu_Handler);
	
	decl String:title[128];
	FormatEx(title, sizeof(title), "%t", "admin_panel");
	OnMenuTitle(client, Menu_AdminPanel, title, title, sizeof(title));
	SetMenuTitle(menu, title);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	FormatEx(buffer, sizeof(buffer), "%t", "give_credits");
	AddMenuItem(menu, "a", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "take_credits");
	AddMenuItem(menu, "b", buffer);
	FormatEx(buffer, sizeof(buffer), "%t\n ", "set_credits");
	AddMenuItem(menu, "c", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "give_items");
	AddMenuItem(menu, "d", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "take_items");
	AddMenuItem(menu, "e", buffer);
	
	new size = GetArraySize(g_hAdminArray);
	
	if (size > 0)
	{
		decl any:tmp[3], String:id[16], String:display[64];
		display[0] = '\0';
		for (new i = 0; i < size; i++)
		{
			GetArrayArray(g_hAdminArray, i, tmp, sizeof(tmp));
			
			Call_StartFunction(tmp[ADMINPANEL_PLUGIN], tmp[ADMINPANEL_DISPLAY]);
			Call_PushCell(client);
			Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(display));
			Call_Finish();
			
			if (!display[0])
			{
				continue;
			}
			
			IntToString(i, id, sizeof(id));
			
			AddMenuItem(menu, id, display);
		}
	}
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
}

public Admin_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			switch (info[0])
			{
				case 'a' :
				{
					g_iOpt[param1][AdminOption] = GIVE_CREDITS;
				}
				case 'b' :
				{
					g_iOpt[param1][AdminOption] = TAKE_CREDITS;
				}
				case 'c' :
				{
					g_iOpt[param1][AdminOption] = SET_CREDITS;
				}
				case 'd' :
				{
					g_iOpt[param1][AdminOption] = GIVE_ITEMS;
				}
				case 'e' :
				{
					g_iOpt[param1][AdminOption] = TAKE_ITEMS;
				}
				default :
				{
					new bool:result = false;
					
					decl any:tmp[3];
					if (GetArrayArray(g_hAdminArray, StringToInt(info), tmp, sizeof(tmp)))
					{
						Call_StartFunction(tmp[ADMINPANEL_PLUGIN], tmp[ADMINPANEL_SELECT]);
						Call_PushCell(param1);
						Call_Finish(result);
					}
					
					if (!result)
					{
						Admin_ShowMenu(param1, GetMenuSelectionPosition());
					}
					
					return;
				}
			}
			
			if (!Admin_ShowTargetsMenu(param1))
			{
				CPrintToChat(param1, "no_targets");
				Admin_ShowMenu(param1, GetMenuSelectionPosition());
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

bool:Admin_ShowTargetsMenu(client, pos = 0)
{
	SetGlobalTransTarget(client);
	
	new Handle:menu = CreateMenu(Admin_TargetsMenu_Handler);
	if (!AddTargetsToMenu(menu, client, (g_iOpt[client][AdminOption] != GIVE_ITEMS && g_iOpt[client][AdminOption] != TAKE_ITEMS)))
	{
		CloseHandle(menu);
		return false;
	}
	
	SetMenuTitle(menu, "%t\n ", "select_target");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
	
	return true;
}

public Admin_TargetsMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
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
				CPrintToChat(param1, "target_left_game");
				Admin_ShowTargetsMenu(param1, GetMenuSelectionPosition());
				return;
			}
			
			g_iOpt[param1][AdminTarget] = userid;
			
			switch (g_iOpt[param1][AdminOption])
			{
				case GIVE_CREDITS, TAKE_CREDITS, SET_CREDITS :
				{
					Admin_ShowCreditsAmount(param1);
				}
				case GIVE_ITEMS, TAKE_ITEMS :
				{
					Admin_ShowCategories(param1);
				}
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowMenu(param1);
			}
		}
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
}

Admin_ShowCreditsAmount(client, pos = 0)
{
	DisplayMenuAtItem(count_menu, client, pos, MENU_TIME_FOREVER);
}

bool:Admin_ShowCategories(client, pos = 0)
{
	SetGlobalTransTarget(client);
	
	new Handle:menu = CreateMenu(Admin_CategoriesMenu_Handler);
	if (!FillCategories(menu, client))
	{
		CPrintToChat(client, "%t", "EmptyShop");
		CloseHandle(menu);
		return false;
	}
	
	SetMenuTitle(menu, "%t\n ", "select_category");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
	
	return true;
}

public Admin_CategoriesMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(g_iOpt[param1][AdminTarget]);
			
			if (!target)
			{
				CPrintToChat(param1, "%t", "target_left_game");
				Admin_ShowTargetsMenu(param1, GetMenuSelectionPosition());
				return;
			}
			
			g_iOpt[param1][AdminCategory] = StringToInt(info);
			
			Admin_ShowItemsOfCategory(param1, g_iOpt[param1][AdminCategory]);
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowTargetsMenu(param1);
			}
		}
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
}

bool:Admin_ShowItemsOfCategory(client, category_id, pos = 0)
{
	SetGlobalTransTarget(client);
	
	new Handle:menu = CreateMenu(Admin_ItemsMenu_Handler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DrawItem|MenuAction_DisplayItem);
	if (!FillItemsOfCategory(menu, client, client, category_id))
	{
		CPrintToChat(client, "%t", "EmptyCategory");
		CloseHandle(menu);
		return false;
	}
	
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
	
	return true;
}

public Admin_ItemsMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Display :
		{
			switch (g_iOpt[param1][AdminOption])
			{
				case GIVE_ITEMS :
				{
					SetMenuTitle(menu, "%t\n ", "give_items");
				}
				case TAKE_ITEMS :
				{
					SetMenuTitle(menu, "%t\n ", "take_items");
				}
			}
		}
		case MenuAction_DrawItem  :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(g_iOpt[param1][AdminTarget]);
			
			new ItemType:type = GetItemTypeEx(info);
			
			if (type != Item_Finite && type != Item_BuyOnly)
			{
				switch (g_iOpt[param1][AdminOption])
				{
					case GIVE_ITEMS :
					{
						if (ClientHasItemEx(target, info))
						{
							return ITEMDRAW_DISABLED;
						}
					}
					case TAKE_ITEMS :
					{
						if (!ClientHasItemEx(target, info))
						{
							return ITEMDRAW_DISABLED;
						}
					}
				}
			}
		}
		case MenuAction_DisplayItem :
		{
			decl String:info[16], String:buffer[SHOP_MAX_STRING_LENGTH];
			GetMenuItem(menu, param2, info, sizeof(info), _, buffer, sizeof(buffer));
			
			new ItemType:type = GetItemTypeEx(info);
			
			if (type == Item_BuyOnly)
			{
				return 0;
			}
			
			new target = GetClientOfUserId(g_iOpt[param1][AdminTarget]);
			
			if (type == Item_Finite)
			{
				Format(buffer, sizeof(buffer), "%s (%d)", buffer, GetItemCountEx(target, info));
				return RedrawMenuItem(buffer);
			}
			switch (g_iOpt[param1][AdminOption])
			{
				case GIVE_ITEMS :
				{
					if (ClientHasItemEx(target, info))
					{
						Format(buffer, sizeof(buffer), "[+] %s", buffer);
						return RedrawMenuItem(buffer);
					}
				}
				case TAKE_ITEMS :
				{
					if (!ClientHasItemEx(target, info))
					{
						Format(buffer, sizeof(buffer), "[-] %s", buffer);
						return RedrawMenuItem(buffer);
					}
				}
			}
		}
		case MenuAction_Select :
		{
			decl String:info[16];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			new target = GetClientOfUserId(g_iOpt[param1][AdminTarget]);
			
			if (!target)
			{
				CPrintToChat(param1, "%t", "target_left_game");
				Admin_ShowMenu(param1);
				return 0;
			}
			
			switch (g_iOpt[param1][AdminOption])
			{
				case GIVE_ITEMS :
				{
					if (GiveItemEx(target, info))
					{
						CPrintToChat(param1, "%t", "give_item_success");
					}
				}
				case TAKE_ITEMS :
				{
					if (RemoveItemEx(target, info, (GetItemTypeEx(info) == Item_Finite) ? 1 : -1))
					{
						CPrintToChat(param1, "%t", "take_item_success");
					}
				}
			}
			
			Admin_ShowItemsOfCategory(param1, g_iOpt[param1][AdminCategory], GetMenuSelectionPosition());
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowCategories(param1);
			}
		}
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
	
	return 0;
}