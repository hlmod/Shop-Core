Handle h_fwdOnAuthorized,
	h_fwdOnMenuTitle,
	h_fwdOnItemDisplay,
	h_fwdOnItemDescription,
	h_fwdOnItemDraw,
	h_fwdOnItemToggled,
	h_fwdOnItemElapsed,
	h_fwdOnItemBuy,
	h_fwdOnItemSell,
	h_fwdOnClientLuckProcess,
	h_fwdOnClientShouldLuckItem,
	h_fwdOnClientItemLucked,
	h_fwdOnItemTransfer,
	h_fwdOnItemTransfered,
	h_fwdOnCreditsTransfer,
	h_fwdOnCreditsTransfered,
	h_fwdOnCreditsSet,
	h_fwdOnCreditsGiven,
	h_fwdOnCreditsTaken,
	h_fwdOnCategoryRegistered;

void Forward_OnPluginStart()
{
	h_fwdOnAuthorized = CreateGlobalForward("Shop_OnAuthorized", ET_Ignore, Param_Cell);
	h_fwdOnMenuTitle = CreateGlobalForward("Shop_OnMenuTitle", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	h_fwdOnItemBuy = CreateGlobalForward("Shop_OnItemBuy", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef);
	h_fwdOnItemDraw = CreateGlobalForward("Shop_OnItemDraw", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
	h_fwdOnItemDisplay = CreateGlobalForward("Shop_OnItemDisplay", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	h_fwdOnItemDescription = CreateGlobalForward("Shop_OnItemDescription", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	h_fwdOnItemSell = CreateGlobalForward("Shop_OnItemSell", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell, Param_CellByRef);
	h_fwdOnItemToggled = CreateGlobalForward("Shop_OnItemToggled", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell);
	h_fwdOnItemElapsed = CreateGlobalForward("Shop_OnItemElapsed", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String);
	h_fwdOnClientLuckProcess = CreateGlobalForward("Shop_OnClientLuckProcess", ET_Hook, Param_Cell);
	h_fwdOnClientShouldLuckItem = CreateGlobalForward("Shop_OnClientShouldLuckItem", ET_Hook, Param_Cell, Param_Cell);
	h_fwdOnClientItemLucked = CreateGlobalForward("Shop_OnClientItemLucked", ET_Ignore, Param_Cell, Param_Cell);
	h_fwdOnItemTransfer = CreateGlobalForward("Shop_OnItemTransfer", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnItemTransfered = CreateGlobalForward("Shop_OnItemTransfered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnCreditsTransfer = CreateGlobalForward("Shop_OnCreditsTransfer", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Cell);
	h_fwdOnCreditsTransfered = CreateGlobalForward("Shop_OnCreditsTransfered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnCreditsSet = CreateGlobalForward("Shop_OnCreditsSet", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);
	h_fwdOnCreditsGiven = CreateGlobalForward("Shop_OnCreditsGiven", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);
	h_fwdOnCreditsTaken = CreateGlobalForward("Shop_OnCreditsTaken", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);
	h_fwdOnCategoryRegistered = CreateGlobalForward("Shop_OnCategoryRegistered", ET_Ignore, Param_Cell, Param_String);
}

bool Forward_OnItemTransfer(int client, int target, int item_id)
{
	bool result = true;
	
	Call_StartForward(h_fwdOnItemTransfer);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(item_id);
	Call_Finish(result);
	
	return result;
}

void Forward_OnItemTransfered(int client, int target, int item_id)
{
	Call_StartForward(h_fwdOnItemTransfered);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(item_id);
	Call_Finish();
}

Action Forward_OnCreditsTransfer(int client, int target, int &credits_give, int &credits_remove, int &credits_commission, bool bPercent)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsTransfer);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCellRef(credits_give);
	Call_PushCellRef(credits_remove);
	Call_PushCellRef(credits_commission);
	Call_PushCell(bPercent);
	Call_Finish(result);
	
	return result;
}

void Forward_OnCreditsTransfered(int client, int target, int credits_give, int credits_remove, int credits_commission)
{
	Call_StartForward(h_fwdOnCreditsTransfered);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(credits_give);
	Call_PushCell(credits_remove);
	Call_PushCell(credits_commission);
	Call_Finish();
}

bool Forward_OnClientLuckProcess(int client)
{
	bool result = true;
	
	Call_StartForward(h_fwdOnClientLuckProcess);
	Call_PushCell(client);
	Call_Finish(result);
	
	return result;
}

Action Forward_OnClientShouldLuckItem(int client, int item_id, int &iLuckChance)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnClientShouldLuckItem);
	Call_PushCell(client);
	Call_PushCell(item_id);
	Call_PushCellRef(iLuckChance);
	Call_Finish(result);
	
	return result;
}

void Forward_OnClientItemLucked(int client, int item_id)
{
	Call_StartForward(h_fwdOnClientItemLucked);
	Call_PushCell(client);
	Call_PushCell(item_id);
	Call_Finish();
}

Action Forward_OnItemDraw(int client, ShopMenu menu_action, int category_id, int item_id, bool &disabled)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnItemDraw);
	Call_PushCell(client);
	Call_PushCell(menu_action);
	Call_PushCell(category_id);
	Call_PushCell(item_id);
	Call_PushCellRef(disabled);
	Call_Finish(result);
	
	return result;
}

bool Forward_OnItemDisplay(int client, ShopMenu menu_action, int category_id, int item_id, const char[] display, char[] buffer, int maxlength)
{
	bool result = false;
	
	Call_StartForward(h_fwdOnItemDisplay);
	Call_PushCell(client);
	Call_PushCell(menu_action);
	Call_PushCell(category_id);
	Call_PushCell(item_id);
	Call_PushString(display);
	Call_PushStringEx(buffer, maxlength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlength);
	Call_Finish(result);
	
	if (!result)
	{
		strcopy(buffer, maxlength, display);
	}
	
	return result;
}

bool Forward_OnItemDescription(int client, ShopMenu menu_action, int category_id, int item_id, const char[] display, char[] buffer, int maxlength)
{
	bool result = false;
	
	Call_StartForward(h_fwdOnItemDescription);
	Call_PushCell(client);
	Call_PushCell(menu_action);
	Call_PushCell(category_id);
	Call_PushCell(item_id);
	Call_PushString(display);
	Call_PushStringEx(buffer, maxlength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlength);
	Call_Finish(result);
	
	if (!result)
	{
		strcopy(buffer, maxlength, display);
	}
	
	return result;
}

Action Forward_OnCreditsTaken(int client, int &credits, int by_who)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsTaken);
	Call_PushCell(client);
	Call_PushCellRef(credits);
	Call_PushCell(by_who);
	Call_Finish(result);
	
	return result;
}

Action Forward_OnCreditsSet(int client, int &credits, int by_who)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsSet);
	Call_PushCell(client);
	Call_PushCellRef(credits);
	Call_PushCell(by_who);
	Call_Finish(result);
	
	return result;
}

Action Forward_OnCreditsGiven(int client, int &credits, int by_who)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsGiven);
	Call_PushCell(client);
	Call_PushCellRef(credits);
	Call_PushCell(by_who);
	Call_Finish(result);
	
	return result;
}

void Forward_OnAuthorized(int client)
{
	Call_StartForward(h_fwdOnAuthorized);
	Call_PushCell(client);
	Call_Finish();
}

void Forward_OnItemElapsed(int client, int category_id, const char[] category, int item_id, const char[] item)
{
	Call_StartForward(h_fwdOnItemElapsed);
	Call_PushCell(client);
	Call_PushCell(category_id);
	Call_PushString(category);
	Call_PushCell(item_id);
	Call_PushString(item);
	Call_Finish();
}

void Forward_OnItemToggled(int client, int category_id, const char[] category, int item_id, const char[] item, ToggleState toggle)
{
	Call_StartForward(h_fwdOnItemToggled);
	Call_PushCell(client);
	Call_PushCell(category_id);
	Call_PushString(category);
	Call_PushCell(item_id);
	Call_PushString(item);
	Call_PushCell(toggle);
	Call_Finish();
}

void Forward_NotifyShopLoaded()
{
	Handle plugin;
	
	Handle myhandle = GetMyHandle();
	Handle hIter = GetPluginIterator();
	
	while (MorePlugins(hIter))
	{
		plugin = ReadPlugin(hIter);
		
		if (plugin == myhandle || GetPluginStatus(plugin) != Plugin_Running)
		{
			continue;
		}
		
		Function func = GetFunctionByName(plugin, "Shop_Started");
		
		if (IsCallValid(plugin, func))
		{
			Call_StartFunction(plugin, func);
			Call_Finish();
		}
	}
	
	delete hIter;
}

void Forward_OnMenuTitle(int client, ShopMenu menu_action, const char[] title, char[] buffer, int maxlength)
{
	bool result = false;
	
	Call_StartForward(h_fwdOnMenuTitle);
	Call_PushCell(client);
	Call_PushCell(menu_action);
	Call_PushString(title);
	Call_PushStringEx(buffer, maxlength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlength);
	Call_Finish(result);
	
	if (!result)
		strcopy(buffer, maxlength, title);
	
	StrCat(buffer, maxlength, "\n ");
}

Action Forward_OnItemBuy(int client, int category_id, const char[] category, int item_id, const char[] item, ItemType type, int &price, int &sell_price, int &value)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnItemBuy);
	Call_PushCell(client);
	Call_PushCell(category_id);
	Call_PushString(category);
	Call_PushCell(item_id);
	Call_PushString(item);
	Call_PushCell(type);
	Call_PushCellRef(price);
	Call_PushCellRef(sell_price);
	Call_PushCellRef(value);
	Call_Finish(result);
	
	return result;
}

Action Forward_OnItemSell(int client, int category_id, const char[] category, int item_id, const char[] item, ItemType type, int &sell_price)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnItemSell);
	Call_PushCell(client);
	Call_PushCell(category_id);
	Call_PushString(category);
	Call_PushCell(item_id);
	Call_PushString(item);
	Call_PushCell(type);
	Call_PushCellRef(sell_price);
	Call_Finish(result);
	
	return result;
}

void Forward_OnCategoryRegistered(int category_id, const char[] category)
{
	Call_StartForward(h_fwdOnCategoryRegistered);
	Call_PushCell(category_id);
	Call_PushString(category);
	Call_Finish();
}