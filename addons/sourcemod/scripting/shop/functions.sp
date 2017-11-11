#define FUNCTIONS_COMMISION 0
#define FUNCTIONS_CREDITS 1

#define FUNCTIONS_PLUGIN 0
#define FUNCTIONS_DISPLAY 1
#define FUNCTIONS_SELECT 2

new Handle:g_hTransCredits, g_iTransCredits, g_iTransMode;
new Handle:g_hLuckCredits, g_iLuckCredits;
new Handle:g_hLuckChance, g_iLuckChance;

new bool:g_bListenChat[MAXPLAYERS+1],
	g_iCreditsTransferTarget[MAXPLAYERS+1],
	g_iCreditsTransferAmount[MAXPLAYERS+1],
g_iCreditsTransferCommission[MAXPLAYERS+1];

new Handle:g_hFuncArray;

Functions_CreateNatives()
{
	g_hFuncArray = CreateArray(3);
	
	CreateNative("Shop_AddToFunctionsMenu", Functions_AddToMenuNative);
	CreateNative("Shop_RemoveFromFunctionsMenu", Functions_RemoveFromMenuNative);
	CreateNative("Shop_ShowFunctionsMenu", Functions_ShowMenuNative);
}

public Functions_AddToMenuNative(Handle:plugin, params)
{
	decl any:tmp[3];
	tmp[FUNCTIONS_PLUGIN] = plugin;
	tmp[FUNCTIONS_DISPLAY] = GetNativeCell(1);
	tmp[FUNCTIONS_SELECT] = GetNativeCell(2);
	
	PushArrayArray(g_hFuncArray, tmp);
}

public Functions_RemoveFromMenuNative(Handle:plugin, params)
{
	decl any:tmp[3];
	
	new index = -1;
	while ((index = FindValueInArray(g_hFuncArray, plugin)) != -1)
	{
		GetArrayArray(g_hFuncArray, index, tmp);
		if (tmp[FUNCTIONS_DISPLAY] == GetNativeCell(1) && tmp[FUNCTIONS_SELECT] == GetNativeCell(2))
		{
			RemoveFromArray(g_hFuncArray, index);
			return true;
		}
	}
	
	return false;
}

public Functions_ShowMenuNative(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	Functions_ShowMenu(client);
}

Functions_OnPluginStart()
{
	decl String:buffer[16];
	g_hTransCredits = CreateConVar("sm_shop_trans_credits", "%5", "Use % to make the transfer to cost the commision or without % to make it cost as the cvar set or -1 to disable this feature", 0, true, -1.0);
	GetConVarString(g_hTransCredits, buffer, sizeof(buffer));
	TrimString(buffer);
	if (buffer[0] == '%')
	{
		g_iTransMode = FUNCTIONS_COMMISION;
		g_iTransCredits = StringToInt(buffer[1]);
	}
	else
	{
		g_iTransMode = FUNCTIONS_CREDITS;
		g_iTransCredits = StringToInt(buffer);
	}
	HookConVarChange(g_hTransCredits, Functions_OnConVarChange);
	
	g_hLuckCredits = CreateConVar("sm_shop_luck_credits", "500", "How many credits the luck cost", 0, true, 0.0);
	g_iLuckCredits = GetConVarInt(g_hLuckCredits);
	HookConVarChange(g_hLuckCredits, Functions_OnConVarChange);
	
	g_hLuckChance = CreateConVar("sm_shop_luck_chance", "20", "How many chance the luck can be succeded", 0, true, 1.0, true, 100.0);
	g_iLuckChance = GetConVarInt(g_hLuckChance);
	HookConVarChange(g_hLuckChance, Functions_OnConVarChange);
}

public Functions_OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hTransCredits)
	{
		decl String:buffer[16];
		strcopy(buffer, sizeof(buffer), newValue);
		TrimString(buffer);
		if (buffer[0] == '%')
		{
			g_iTransMode = FUNCTIONS_COMMISION;
			g_iTransCredits = StringToInt(buffer[1]);
			if (g_iTransCredits > 99)
			{
				g_iTransCredits = 99;
			}
		}
		else
		{
			g_iTransMode = FUNCTIONS_CREDITS;
			g_iTransCredits = StringToInt(buffer);
		}
	}
	else if (convar == g_hLuckCredits)
	{
		g_iLuckCredits = StringToInt(newValue);
	}
	else if (convar == g_hLuckChance)
	{
		g_iLuckChance = StringToInt(newValue);
	}
}

Functions_UnregisterMe(Handle:hPlugin)
{
	new index = -1;
	while ((index = FindValueInArray(g_hFuncArray, hPlugin)) != -1)
	{
		RemoveFromArray(g_hFuncArray, index);
	}
}

Functions_OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_bListenChat[i] = false;
		g_iCreditsTransferTarget[i] = 0;
		g_iCreditsTransferAmount[i] = 0;
		g_iCreditsTransferCommission[i] = 0;
	}
}

Functions_OnClientDisconnect_Post(client)
{
	g_bListenChat[client] = false;
	g_iCreditsTransferAmount[client] = 0;
	g_iCreditsTransferCommission[client] = 0;
	g_iCreditsTransferTarget[client] = 0;
}

Functions_ShowMenu(client, pos = 0)
{
	SetGlobalTransTarget(client);
	
	new credits = GetCredits(client);
	
	new Handle:menu = CreateMenu(Functions_Menu_Handler);
	
	decl String:buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t\n%t", "functions", "credits", credits);
	OnMenuTitle(client, Menu_Functions, buffer, buffer, sizeof(buffer));
	SetMenuTitle(menu, buffer);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	if (g_iTransCredits == -1)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "trans_credits", "trans_credits_disabled");
		AddMenuItem(menu, "a", buffer, ITEMDRAW_DISABLED);
	}
	else if (!g_iTransCredits)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "trans_credits");
		AddMenuItem(menu, "a", buffer);
	}
	else
	{
		switch (g_iTransMode)
		{
			case FUNCTIONS_COMMISION :
			{
				FormatEx(buffer, sizeof(buffer), "%t %t", "trans_credits", "trans_credits_commision", g_iTransCredits);
				AddMenuItem(menu, "a", buffer);
			}
			case FUNCTIONS_CREDITS :
			{
				FormatEx(buffer, sizeof(buffer), "%t %t", "trans_credits", "trans_credits_cost", g_iTransCredits);
				AddMenuItem(menu, "a", buffer, (credits < g_iTransCredits) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}
	}
	
	if (!g_iLuckCredits)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "try_luck", "luck_disabled");
		AddMenuItem(menu, "b", buffer, ITEMDRAW_DISABLED);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "try_luck", "luck_credits_chance", g_iLuckCredits, g_iLuckChance);
		AddMenuItem(menu, "b", buffer, (credits < g_iLuckCredits) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	new size = GetArraySize(g_hFuncArray);
	
	if (size > 0)
	{
		decl any:tmp[3], String:id[16], String:display[64];
		display[0] = '\0';
		for (new i = 0; i < size; i++)
		{
			GetArrayArray(g_hFuncArray, i, tmp, sizeof(tmp));
			
			Call_StartFunction(tmp[FUNCTIONS_PLUGIN], tmp[FUNCTIONS_DISPLAY]);
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

public Functions_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
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
					Functions_ShowCreditsTransferMenu(param1);
				}
				case 'b' :
				{
					Functions_SetupLuck(param1);
					Functions_ShowMenu(param1, GetMenuSelectionPosition());
				}
				default :
				{
					new bool:result = false;
					
					decl any:tmp[3];
					if (GetArrayArray(g_hFuncArray, StringToInt(info), tmp, sizeof(tmp)))
					{
						Call_StartFunction(tmp[FUNCTIONS_PLUGIN], tmp[FUNCTIONS_SELECT]);
						Call_PushCell(param1);
						Call_Finish(result);
					}
					
					if (!result)
					{
						Functions_ShowMenu(param1, GetMenuSelectionPosition());
					}
				}
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

bool:Functions_ShowCreditsTransferMenu(client)
{
	SetGlobalTransTarget(client);
	
	new credits = GetCredits(client);
	
	new Handle:menu = CreateMenu(Functions_MenuCreditsTransfer_Handler);
	
	decl String:buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t\n%t", "trans_credits", "credits", credits);
	OnMenuTitle(client, Menu_Functions, buffer, buffer, sizeof(buffer));
	SetMenuTitle(menu, buffer);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	
	if (!Functions_AddTargetsToMenu(menu, client))
	{
		CloseHandle(menu);
		Functions_ShowMenu(client);
		
		CPrintToChat(client, "%t", "no_targets");
		
		return false;
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return true;
}

public Functions_MenuCreditsTransfer_Handler(Handle:menu, MenuAction:action, param1, param2)
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
				Functions_ShowCreditsTransferMenu(param1);
				CPrintToChat(param1, "%t", "target_left_game");
				return;
			}
			
			Functions_SetupCreditsTransfer(param1, userid);
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Functions_ShowMenu(param1);
			}
		}
		case MenuAction_End :
		{
			CloseHandle(menu);
		}
	}
}

Functions_SetupCreditsTransfer(client, target_userid)
{
	g_bListenChat[client] = true;
	
	g_iCreditsTransferTarget[client] = target_userid;
	
	Functions_ShowPanel(client);
}

Functions_ShowPanel(client)
{
	new target = GetClientOfUserId(g_iCreditsTransferTarget[client]);
	if (!target)
	{
		Functions_OnClientDisconnect_Post(client);
		Functions_ShowCreditsTransferMenu(client);
		return;
	}
	
	new Handle:panel = CreatePanel();
	
	SetGlobalTransTarget(client);
	
	new credits = GetCredits(client);
	
	decl String:buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t\n%t", "trans_credits", "credits", credits);
	SetPanelTitle(panel, buffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	FormatEx(buffer, sizeof(buffer), "%N (%d)", target, GetCredits(target));
	DrawPanelText(panel, buffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	FormatEx(buffer, sizeof(buffer), "%t", "trans_credits_operation");
	DrawPanelText(panel, buffer);
	
	if (g_iCreditsTransferAmount[client] != 0)
	{
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		if (g_iCreditsTransferCommission[client] > 0)
		{
			FormatEx(buffer, sizeof(buffer), "%t", "credits_being_transfered", g_iCreditsTransferAmount[client]);
			DrawPanelText(panel, buffer);
			
			if (g_iTransMode == FUNCTIONS_COMMISION)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer_commission", g_iCreditsTransferCommission[client]);
				DrawPanelText(panel, buffer);
				
				FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer", g_iCreditsTransferAmount[client]-g_iCreditsTransferCommission[client]);
				DrawPanelText(panel, buffer);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer_price", g_iCreditsTransferCommission[client]);
				DrawPanelText(panel, buffer);
			}
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer", g_iCreditsTransferAmount[client]);
			DrawPanelText(panel, buffer);
		}
		
		new left = credits-g_iCreditsTransferAmount[client]-g_iCreditsTransferCommission[client];
		
		FormatEx(buffer, sizeof(buffer), "%t", "transfer_credits_left", left);
		DrawPanelText(panel, buffer);
	
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		if (left < 0)
		{
			FormatEx(buffer, sizeof(buffer), "%t", "need_positive", left * -1);
			DrawPanelText(panel, buffer);
		
			DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
			
			FormatEx(buffer, sizeof(buffer), "%t", "confirm");
			DrawPanelItem(panel, buffer, ITEMDRAW_DISABLED);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", "confirm");
			DrawPanelItem(panel, buffer);
		}
	}
	else
	{
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		FormatEx(buffer, sizeof(buffer), "%t", "confirm");
		DrawPanelItem(panel, buffer, ITEMDRAW_DISABLED);
	}
	
	FormatEx(buffer, sizeof(buffer), "%t", "cancel");
	DrawPanelItem(panel, buffer);
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	SetPanelCurrentKey(panel, g_iExitButton);
	FormatEx(buffer, sizeof(buffer), "%t", "Exit");
	DrawPanelItem(panel, buffer);
	
	SendPanelToClient(panel, client, Functions_PanelHandler, MENU_TIME_FOREVER);
	
	CloseHandle(panel);
}

public Functions_PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			switch (param2)
			{
				case 1 :
				{
					new target = GetClientOfUserId(g_iCreditsTransferTarget[param1]);
					
					if (!target)
					{
						Functions_OnClientDisconnect_Post(param1);
						Functions_ShowCreditsTransferMenu(param1);
						CPrintToChat(param1, "%t", "target_left_game");
						return;
					}
					
					decl amount_remove, amount_give;
					
					if (g_iTransMode == FUNCTIONS_COMMISION)
					{
						amount_remove = g_iCreditsTransferAmount[param1];
						amount_give = g_iCreditsTransferAmount[param1]-g_iCreditsTransferCommission[param1];
					}
					else
					{
						amount_remove = g_iCreditsTransferAmount[param1]+g_iCreditsTransferCommission[param1];
						amount_give = g_iCreditsTransferAmount[param1];
					}
					
					new dummy_remove = amount_remove;
					new dummy_give = amount_give;
					switch (OnCreditsTransfer(param1, target, amount_give, amount_remove))
					{
						case Plugin_Continue :
						{
							amount_remove = dummy_remove;
							amount_give = dummy_give;
						}
						case Plugin_Handled, Plugin_Stop :
						{
							Functions_OnClientDisconnect_Post(param1);
							Functions_ShowMenu(param1);
							return;
						}
					}
					
					RemoveCredits(param1, amount_remove, CREDITS_BY_TRANSFER);
					GiveCredits(target, amount_give, CREDITS_BY_TRANSFER);
					
					OnCreditsTransfered(param1, target, amount_give, amount_remove);
					
					CPrintToChat(param1, "%t", "TransferSuccess", amount_give, target);
					CPrintToChat(target, "%t", "ReceiveSuccess", amount_give, param1);
					
					Functions_OnClientDisconnect_Post(param1);
					Functions_ShowMenu(param1);
				}
				case 2 :
				{
					Functions_OnClientDisconnect_Post(param1);
					Functions_ShowMenu(param1);
				}
				case 10 :
				{
					Functions_OnClientDisconnect_Post(param1);
				}
			}
		}
		case MenuAction_Cancel :
		{
			if (g_bListenChat[param1])
			{
				Functions_ShowPanel(param1);
			}
		}
	}
}

Action:Functions_OnClientSayCommand(client, const String:text[])
{
	if (!g_bListenChat[client])
	{
		return Plugin_Continue;
	}
	
	if (StrEqual(text, "cancel", false))
	{
		Functions_OnClientDisconnect_Post(client);
		Functions_ShowCreditsTransferMenu(client);
	}
	
	g_iCreditsTransferAmount[client] = StringToInt(text);
	
	if(g_iCreditsTransferAmount[client] < 2)
	{
		CPrintToChat(client, "%t", "IncorrectCredits");
		return Plugin_Handled;
	}
	
	if (g_iCreditsTransferAmount[client] > GetCredits(client))
	{
		g_iCreditsTransferAmount[client] = GetCredits(client);
	}
	
	switch (g_iTransMode)
	{
		case FUNCTIONS_COMMISION :
		{
			g_iCreditsTransferCommission[client] = g_iCreditsTransferAmount[client] * g_iTransCredits / 100;
		}
		case FUNCTIONS_CREDITS :
		{
			g_iCreditsTransferCommission[client] = g_iTransCredits;
		}
	}
	
	Functions_ShowPanel(client);
	
	return Plugin_Handled;
}

Functions_SetupLuck(client)
{
	if (!OnLuckProcess(client))
	{
		return;
	}

	decl Handle:hArray, size;
	hArray = Shop_CreateArrayOfItems(size);
	SortADTArray(hArray, Sort_Random, Sort_Integer);
	
	if (!size)
	{
		CloseHandle(hArray);
		
		CPrintToChat(client, "%t", "EmptyShop");
		
		return;
	}
	
	new item_id;
	
	decl i, dummy, ItemType:type;
	for (i = 0; i < size; ++i)
	{
		dummy = GetArrayCell(hArray, i);
		type = GetItemType(dummy);
		
		if (type != Item_Finite && type != Item_BuyOnly && ClientHasItem(client, dummy))
		{
			continue;
		}
		
		if(ItemManager_GetCanLuck(dummy) == false)
		{
			continue;
		}

		item_id = dummy;
		
		break;
	}
	
	CloseHandle(hArray);
	
	if (!item_id)
	{
		CPrintToChat(client, "%t", "NothingToLuck");
		
		return;
	}

	if (GetRandomIntEx(1, 100) > g_iLuckChance)
	{
		RemoveCredits(client, g_iLuckCredits, CREDITS_BY_LUCK);
		
		CPrintToChat(client, "%t", "Looser");
		
		return;
	}
	
	if (!OnItemLuck(client, item_id))
	{
		return;
	}
	
	RemoveCredits(client, g_iLuckCredits, CREDITS_BY_LUCK);
	
	GiveItem(client, item_id);
	
	OnItemLucked(client, item_id);
	
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	GetCategoryDisplay(GetItemCategoryId(item_id), client, category, sizeof(category));
	GetItemDisplay(item_id, client, item, sizeof(item));
	
	CPrintToChat(client, "%t", "Lucker", category, item);
}

stock bool:Functions_AddTargetsToMenu(Handle:menu, filter_client)
{
	new bool:result = false;
	
	decl String:userid[9], String:buffer[MAX_NAME_LENGTH+21];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != filter_client && IsAuthorizedIn(i))
		{
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			FormatEx(buffer, sizeof(buffer), "%N (%d)", i, GetCredits(i));
			
			AddMenuItem(menu, userid, buffer);
			
			result = true;
		}
	}
	
	return result;
}