ConVar g_hTransCredits, g_hLuckCredits, g_hLuckChance;
bool g_bTransMode;
int g_iTransCredits;

bool g_bListenChat[MAXPLAYERS+1];
int g_iCreditsTransferTarget[MAXPLAYERS+1],
	g_iCreditsTransferAmount[MAXPLAYERS+1],
	g_iCreditsTransferCommission[MAXPLAYERS+1];

ArrayList g_hFuncArray;

void Functions_CreateNatives()
{
	g_hFuncArray = new ArrayList(1);
	
	CreateNative("Shop_AddToFunctionsMenu", Functions_AddToMenuNative);
	CreateNative("Shop_RemoveFromFunctionsMenu", Functions_RemoveFromMenuNative);
	CreateNative("Shop_ShowFunctionsMenu", Functions_ShowMenuNative);
}

public int Functions_AddToMenuNative(Handle plugin, int numParams)
{
	DataPack dp = new DataPack();
	dp.WriteCell(plugin);
	dp.WriteFunction(GetNativeFunction(1));
	dp.WriteFunction(GetNativeFunction(2));
	
	g_hFuncArray.Push(plugin);
	g_hFuncArray.Push(dp);
}

public int Functions_RemoveFromMenuNative(Handle plugin, int numParams)
{
	DataPack dp;
	
	int index = -1;
	while ((index = g_hFuncArray.FindValue(plugin)) != -1)
	{
		dp = g_hFuncArray.Get(index+1);
		dp.Reset();
		dp.ReadCell(); // plugin
		Function func_disp = dp.ReadFunction();
		Function func_select = dp.ReadFunction();
		if (func_disp == GetNativeFunction(1) && func_select == GetNativeFunction(2))
		{
			g_hFuncArray.Erase(index+1);
			g_hFuncArray.Erase(index);
			delete dp;
			return true;
		}
	}
	
	return false;
}

public int Functions_ShowMenuNative(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
		ThrowNativeError(SP_ERROR_NATIVE, error);
	
	Functions_ShowMenu(client);
}

void Functions_OnPluginStart()
{
	char buffer[16];
	g_hTransCredits = CreateConVar("sm_shop_trans_credits", "%5", "Use % to make the transfer to cost the commision or without % to make it cost as the cvar set or -1 to disable this feature", 0, true, -1.0);
	g_hTransCredits.GetString(buffer, sizeof(buffer));
	TrimString(buffer);
	if (buffer[0] == '%')
	{
		g_bTransMode = false;
		g_iTransCredits = StringToInt(buffer[1]);
	}
	else
	{
		g_bTransMode = true;
		g_iTransCredits = StringToInt(buffer);
	}
	g_hTransCredits.AddChangeHook(Functions_OnConVarChange);
	
	g_hLuckCredits = CreateConVar("sm_shop_luck_credits", "500", "How many credits the luck cost", 0, true, 0.0);
	g_hLuckChance = CreateConVar("sm_shop_luck_chance", "20", "How many chance the luck can be succeded", 0, true, 1.0, true, 100.0);
}

public void Functions_OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hTransCredits)
	{
		char buffer[16];
		strcopy(buffer, sizeof(buffer), newValue);
		TrimString(buffer);
		if (buffer[0] == '%')
		{
			g_bTransMode = false;
			g_iTransCredits = StringToInt(buffer[1]);
			if (g_iTransCredits > 99)
			{
				g_iTransCredits = 99;
			}
		}
		else
		{
			g_bTransMode = true;
			g_iTransCredits = StringToInt(buffer);
		}
	}
}

void Functions_UnregisterMe(Handle plugin)
{
	int index = -1;
	while ((index = g_hFuncArray.FindValue(plugin)) != -1)
	{
		delete view_as<Handle>(g_hFuncArray.Get(index+1));

		g_hFuncArray.Erase(index);
		g_hFuncArray.Erase(index);
	}
}

void Functions_OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bListenChat[i] = false;
		g_iCreditsTransferTarget[i] = 0;
		g_iCreditsTransferAmount[i] = 0;
		g_iCreditsTransferCommission[i] = 0;
	}
}

void Functions_OnClientDisconnect_Post(int client)
{
	g_bListenChat[client] = false;
	g_iCreditsTransferAmount[client] = 0;
	g_iCreditsTransferCommission[client] = 0;
	g_iCreditsTransferTarget[client] = 0;
}

void Functions_ShowMenu(int client, int pos = 0)
{
	SetGlobalTransTarget(client);
	
	int credits = GetCredits(client);
	
	Menu menu = CreateMenu(Functions_Menu_Handler);
	
	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t\n%t", "functions", "credits", credits);
	OnMenuTitle(client, Menu_Functions, buffer, buffer, sizeof(buffer));
	menu.SetTitle(buffer);
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	
	if (g_iTransCredits == -1)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "trans_credits", "trans_credits_disabled");
		menu.AddItem("a", buffer, ITEMDRAW_DISABLED);
	}
	else if (!g_iTransCredits)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "trans_credits");
		menu.AddItem("a", buffer);
	}
	else if (!g_bTransMode)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "trans_credits", "trans_credits_commision", g_iTransCredits);
		menu.AddItem("a", buffer);
	}	
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "trans_credits", "trans_credits_cost", g_iTransCredits);
		menu.AddItem("a", buffer, (credits < g_iTransCredits) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	if (g_hLuckCredits.IntValue == 0)
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "try_luck", "luck_disabled");
		menu.AddItem("b", buffer, ITEMDRAW_DISABLED);
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t %t", "try_luck", "luck_credits_chance", g_hLuckCredits.IntValue, g_hLuckChance.IntValue);
		menu.AddItem("b", buffer, (credits < g_hLuckCredits.IntValue) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	
	int size = g_hFuncArray.Length;
	
	if (size > 0)
	{
		DataPack dp;
		char id[16], display[64];
		display[0] = '\0';
		for (int i = 1; i < size; i+=2)
		{
			dp = g_hFuncArray.Get(i);
			dp.Reset();
			Handle plugin = dp.ReadCell();
			Function callback = dp.ReadFunction();
			Call_StartFunction(plugin, callback);
			Call_PushCell(client);
			Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(sizeof(display));
			Call_Finish();
			
			if (!display[0])
				continue;
			
			IntToString(i, id, sizeof(id));
			
			menu.AddItem(id, display);
		}
	}
	
	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

public int Functions_Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));
			
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
					bool result = false;
					
					DataPack dp = g_hFuncArray.Get(StringToInt(info));
					if (dp != null)
					{
						dp.Reset();
						Handle plugin = dp.ReadCell();
						dp.Position += view_as<DataPackPos>(9); // skip func_display
						Function func_select = dp.ReadFunction();
						Call_StartFunction(plugin, func_select);
						Call_PushCell(param1);
						Call_Finish(result);
					}
					
					if (!result)
						Functions_ShowMenu(param1, GetMenuSelectionPosition());
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
		case MenuAction_End : delete menu;
	}
}

bool Functions_ShowCreditsTransferMenu(int client)
{
	SetGlobalTransTarget(client);
	
	int credits = GetCredits(client);
	
	Menu menu = CreateMenu(Functions_MenuCreditsTransfer_Handler);
	
	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t\n%t", "trans_credits", "credits", credits);
	OnMenuTitle(client, Menu_Functions, buffer, buffer, sizeof(buffer));
	menu.SetTitle(buffer);
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	
	if (!Functions_AddTargetsToMenu(menu, client))
	{
		delete menu;
		Functions_ShowMenu(client);
		
		CPrintToChat(client, "%t", "no_targets");
		
		return false;
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	return true;
}

public int Functions_MenuCreditsTransfer_Handler(Menu menu, MenuAction action, int param1, int param2)
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
		case MenuAction_End : delete menu;
	}
}

void Functions_SetupCreditsTransfer(int client, int target_userid)
{
	g_bListenChat[client] = true;
	
	g_iCreditsTransferTarget[client] = target_userid;
	
	Functions_ShowPanel(client);
}

void Functions_ShowPanel(int client)
{
	int target = GetClientOfUserId(g_iCreditsTransferTarget[client]);
	if (!target)
	{
		Functions_OnClientDisconnect_Post(client);
		Functions_ShowCreditsTransferMenu(client);
		return;
	}
	
	Panel panel = new Panel();
	
	SetGlobalTransTarget(client);
	
	int credits = GetCredits(client);
	
	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "%t\n%t", "trans_credits", "credits", credits);
	panel.SetTitle(buffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	FormatEx(buffer, sizeof(buffer), "%N (%d)", target, GetCredits(target));
	panel.DrawText(buffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	FormatEx(buffer, sizeof(buffer), "%t", "trans_credits_operation");
	panel.DrawText(buffer);
	
	if (g_iCreditsTransferAmount[client] != 0)
	{
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		if (g_iCreditsTransferCommission[client] > 0)
		{
			FormatEx(buffer, sizeof(buffer), "%t", "credits_being_transfered", g_iCreditsTransferAmount[client]);
			panel.DrawText(buffer);
			
			if (g_bTransMode == false)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer_commission", g_iCreditsTransferCommission[client]);
				panel.DrawText(buffer);
				
				FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer", g_iCreditsTransferAmount[client]-g_iCreditsTransferCommission[client]);
				panel.DrawText(buffer);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer_price", g_iCreditsTransferCommission[client]);
				panel.DrawText(buffer);
			}
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", "credits_to_transfer", g_iCreditsTransferAmount[client]);
			panel.DrawText(buffer);
		}
		
		int left = credits-g_iCreditsTransferAmount[client]-g_iCreditsTransferCommission[client];
		
		FormatEx(buffer, sizeof(buffer), "%t", "transfer_credits_left", left);
		panel.DrawText(buffer);
	
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		if (left < 0)
		{
			FormatEx(buffer, sizeof(buffer), "%t", "need_positive", left * -1);
			panel.DrawText(buffer);
		
			panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
			
			FormatEx(buffer, sizeof(buffer), "%t", "confirm");
			panel.DrawItem(buffer, ITEMDRAW_DISABLED);
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), "%t", "confirm");
			panel.DrawItem(buffer);
		}
	}
	else
	{
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		
		FormatEx(buffer, sizeof(buffer), "%t", "confirm");
		panel.DrawItem(buffer, ITEMDRAW_DISABLED);
	}
	
	FormatEx(buffer, sizeof(buffer), "%t", "cancel");
	panel.DrawItem(buffer);
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	panel.CurrentKey = g_iExitButton;
	FormatEx(buffer, sizeof(buffer), "%t", "Exit");
	panel.DrawItem(buffer);
	
	panel.Send(client, Functions_PanelHandler, MENU_TIME_FOREVER);
	
	delete panel;
}

public int Functions_PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			switch (param2)
			{
				case 1 :
				{
					int target = GetClientOfUserId(g_iCreditsTransferTarget[param1]);
					
					if (!target)
					{
						Functions_OnClientDisconnect_Post(param1);
						Functions_ShowCreditsTransferMenu(param1);
						CPrintToChat(param1, "%t", "target_left_game");
						return;
					}
					
					int amount_remove, amount_give;
					
					if (g_bTransMode == false)
					{
						amount_remove = g_iCreditsTransferAmount[param1];
						amount_give = g_iCreditsTransferAmount[param1]-g_iCreditsTransferCommission[param1];
					}
					else
					{
						amount_remove = g_iCreditsTransferAmount[param1]+g_iCreditsTransferCommission[param1];
						amount_give = g_iCreditsTransferAmount[param1];
					}
					
					int dummy_remove = amount_remove;
					int dummy_give = amount_give;
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

Action Functions_OnClientSayCommand(int client, const char[] text)
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
		Functions_OnClientDisconnect_Post(client); // call this, if transaction revoked.
		CPrintToChat(client, "%t", "IncorrectCredits");
		return Plugin_Handled;
	}
	
	// I don't know why, but sourcemod allowes negative values for send. So this KOCTbIJIb must fix this.
	g_iCreditsTransferAmount[client] = Helpers_Math_Abs(g_iCreditsTransferAmount[client]);
	
	if (g_iCreditsTransferAmount[client] > GetCredits(client))
	{
		g_iCreditsTransferAmount[client] = GetCredits(client);
	}
	
	if (g_bTransMode == false)
	{
		g_iCreditsTransferCommission[client] = g_iCreditsTransferAmount[client] * g_iTransCredits / 100;
	}
	else
	{
		g_iCreditsTransferCommission[client] = g_iTransCredits;
	}
	
	Functions_ShowPanel(client);
	
	return Plugin_Handled;
}

void Functions_SetupLuck(int client)
{
	if (!OnLuckProcess(client))
	{
		return;
	}

	ArrayList hArray;
	int size;
	hArray = Shop_CreateArrayOfItems(size);
	SortADTArray(hArray, Sort_Random, Sort_Integer);
	
	if (!size)
	{
		delete hArray;
		
		CPrintToChat(client, "%t", "EmptyShop");
		
		return;
	}
	
	int item_id;
	
	int dummy;
	ItemType type;
	for (int i = 0; i < size; ++i)
	{
		dummy = hArray.Get(i);
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
	
	delete hArray;
	
	if (!item_id)
	{
		CPrintToChat(client, "%t", "NothingToLuck");
		
		return;
	}

	if (GetRandomIntEx(1, 100) > g_hLuckChance.IntValue)
	{
		RemoveCredits(client, g_hLuckCredits.IntValue, CREDITS_BY_LUCK);
		
		CPrintToChat(client, "%t", "Looser");
		
		return;
	}
	
	if (!OnItemLuck(client, item_id))
	{
		return;
	}
	
	RemoveCredits(client, g_hLuckCredits.IntValue, CREDITS_BY_LUCK);
	
	GiveItem(client, item_id);
	
	OnItemLucked(client, item_id);
	
	char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	GetCategoryDisplay(GetItemCategoryId(item_id), client, category, sizeof(category));
	GetItemDisplay(item_id, client, item, sizeof(item));
	
	CPrintToChat(client, "%t", "Lucker", category, item);
}

stock bool Functions_AddTargetsToMenu(Menu menu, int filter_client)
{
	bool result = false;
	
	char userid[9], buffer[MAX_NAME_LENGTH+21];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != filter_client && IsAuthorizedIn(i))
		{
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			FormatEx(buffer, sizeof(buffer), "%N (%d)", i, GetCredits(i));
			
			menu.AddItem(userid, buffer);
			
			result = true;
		}
	}
	
	return result;
}