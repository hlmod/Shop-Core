new Handle:h_fwdOnAuthorized,
	Handle:h_fwdOnMenuTitle,
	Handle:h_fwdOnItemDisplay,
	Handle:h_fwdOnItemDescription,
	Handle:h_fwdOnItemDraw,
	Handle:h_fwdOnItemToggled,
	Handle:h_fwdOnItemElapsed,
	Handle:h_fwdOnItemBuy,
	Handle:h_fwdOnItemSell,
	Handle:h_fwdOnLuckProcess,
	Handle:h_fwdOnItemLuck,
	Handle:h_fwdOnItemLucked,
	Handle:h_fwdOnItemTransfer,
	Handle:h_fwdOnItemTransfered,
	Handle:h_fwdOnCreditsTransfer,
	Handle:h_fwdOnCreditsTransfered,
	Handle:h_fwdOnCreditsGiven,
Handle:h_fwdOnCreditsTaken;

Forward_OnPluginStart()
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
	h_fwdOnLuckProcess = CreateGlobalForward("Shop_OnLuckProcess", ET_Hook, Param_Cell);
	h_fwdOnItemLuck = CreateGlobalForward("Shop_OnItemLuck", ET_Hook, Param_Cell, Param_Cell);
	h_fwdOnItemLucked = CreateGlobalForward("Shop_OnItemLucked", ET_Ignore, Param_Cell, Param_Cell);
	h_fwdOnItemTransfer = CreateGlobalForward("Shop_OnItemTransfer", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnItemTransfered = CreateGlobalForward("Shop_OnItemTransfered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnCreditsTransfer = CreateGlobalForward("Shop_OnCreditsTransfer", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef);
	h_fwdOnCreditsTransfered = CreateGlobalForward("Shop_OnCreditsTransfered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	h_fwdOnCreditsGiven = CreateGlobalForward("Shop_OnCreditsGiven", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);
	h_fwdOnCreditsTaken = CreateGlobalForward("Shop_OnCreditsTaken", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);
}

bool:Forward_OnItemTransfer(client, target, item_id)
{
	new bool:result = true;
	
	Call_StartForward(h_fwdOnItemTransfer);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(item_id);
	Call_Finish(result);
	
	return result;
}

Forward_OnItemTransfered(client, target, item_id)
{
	Call_StartForward(h_fwdOnItemTransfered);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(item_id);
	Call_Finish();
}

Action:Forward_OnCreditsTransfer(client, target, &credits_give, &credits_remove)
{
	new Action:result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsTransfer);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCellRef(credits_give);
	Call_PushCellRef(credits_remove);
	Call_Finish(result);
	
	return result;
}

Forward_OnCreditsTransfered(client, target, credits_give, credits_remove)
{
	Call_StartForward(h_fwdOnCreditsTransfered);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(credits_give);
	Call_PushCell(credits_remove);
	Call_Finish();
}

bool:Forward_OnLuckProcess(client)
{
	new bool:result = true;
	
	Call_StartForward(h_fwdOnLuckProcess);
	Call_PushCell(client);
	Call_Finish(result);
	
	return result;
}

bool:Forward_OnItemLuck(client, item_id)
{
	new bool:result = true;
	
	Call_StartForward(h_fwdOnItemLuck);
	Call_PushCell(client);
	Call_PushCell(item_id);
	Call_Finish(result);
	
	return result;
}

Forward_OnItemLucked(client, item_id)
{
	Call_StartForward(h_fwdOnItemLucked);
	Call_PushCell(client);
	Call_PushCell(item_id);
	Call_Finish();
}

Action:Forward_OnItemDraw(client, ShopMenu:menu_action, category_id, item_id, &bool:disabled)
{
	new Action:result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnItemDraw);
	Call_PushCell(client);
	Call_PushCell(menu_action);
	Call_PushCell(category_id);
	Call_PushCell(item_id);
	Call_PushCellRef(disabled);
	Call_Finish(result);
	
	return result;
}

bool:Forward_OnItemDisplay(client, ShopMenu:menu_action, category_id, item_id, const String:display[], String:buffer[], maxlength)
{
	new bool:result = false;
	
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

bool:Forward_OnItemDescription(client, ShopMenu:menu_action, category_id, item_id, const String:display[], String:buffer[], maxlength)
{
	new bool:result = false;
	
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

Action:Forward_OnCreditsTaken(client, &credits, by_who)
{
	new Action:result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsTaken);
	Call_PushCell(client);
	Call_PushCellRef(credits);
	Call_PushCell(by_who);
	Call_Finish(result);
	
	return result;
}

Action:Forward_OnCreditsGiven(client, &credits, by_who)
{
	new Action:result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnCreditsGiven);
	Call_PushCell(client);
	Call_PushCellRef(credits);
	Call_PushCell(by_who);
	Call_Finish(result);
	
	return result;
}

Forward_OnAuthorized(client)
{
	Call_StartForward(h_fwdOnAuthorized);
	Call_PushCell(client);
	Call_Finish();
}

Forward_OnItemElapsed(client, category_id, const String:category[], item_id, const String:item[])
{
	Call_StartForward(h_fwdOnItemElapsed);
	Call_PushCell(client);
	Call_PushCell(category_id);
	Call_PushString(category);
	Call_PushCell(item_id);
	Call_PushString(item);
	Call_Finish();
}

Forward_OnItemToggled(client, category_id, const String:category[], item_id, const String:item[], ToggleState:toggle)
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

Forward_NotifyShopLoaded()
{
	decl Handle:plugin;
	
	new Handle:myhandle = GetMyHandle();
	new Handle:hIter = GetPluginIterator();
	
	while (MorePlugins(hIter))
	{
		plugin = ReadPlugin(hIter);
		
		if (plugin == myhandle || GetPluginStatus(plugin) != Plugin_Running)
		{
			continue;
		}
		
		new Function:func = GetFunctionByName(plugin, "Shop_Started");
		
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_Finish();
		}
	}
	
	CloseHandle(hIter);
}

Forward_OnMenuTitle(client, ShopMenu:menu_action, const String:title[], String:buffer[], maxlength)
{
	new bool:result = false;
	
	Call_StartForward(h_fwdOnMenuTitle);
	Call_PushCell(client);
	Call_PushCell(menu_action);
	Call_PushString(title);
	Call_PushStringEx(buffer, maxlength, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(maxlength);
	Call_Finish(result);
	
	if (!result)
	{
		strcopy(buffer, maxlength, title);
	}
	StrCat(buffer, maxlength, "\n ");
}

Action:Forward_OnItemBuy(client, category_id, const String:category[], item_id, const String:item[], ItemType:type, &price, &sell_price, &value)
{
	new Action:result = Plugin_Continue;
	
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

Action:Forward_OnItemSell(client, category_id, const String:category[], item_id, const String:item[], ItemType:type, &sell_price)
{
	new Action:result = Plugin_Continue;
	
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