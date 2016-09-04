new Handle:h_KvClientItems[MAXPLAYERS+1];

new Handle:kv_data;
new String:data_path[PLATFORM_MAX_PATH];

new i_Id[MAXPLAYERS+1];
new iCredits[MAXPLAYERS+1];

new Handle:g_hTimerMethod, g_iTimerMethod;
new Handle:g_hStartCredits, g_iStartCredits;

PlayerManager_CreateNatives()
{
	CreateNative("Shop_IsAuthorized", PlayerManager_IsAuthorized);
	CreateNative("Shop_IsAdmin", PlayerManager_IsAdmin);
	CreateNative("Shop_GetClientId", PlayerManager_GetClientId);
	CreateNative("Shop_GetClientCredits", PlayerManager_GetClientCredits);
	CreateNative("Shop_SetClientCredits", PlayerManager_SetClientCredits);
	CreateNative("Shop_GiveClientCredits", PlayerManager_GiveClientCredits);
	CreateNative("Shop_TakeClientCredits", PlayerManager_TakeClientCredits);
	CreateNative("Shop_BuyClientItem", PlayerManager_BuyClientItem);
	CreateNative("Shop_UseClientItem", PlayerManager_UseClientItem);
	CreateNative("Shop_RemoveClientItem", PlayerManager_RemoveClientItem);
	CreateNative("Shop_GiveClientItem", PlayerManager_GiveClientItem);
	CreateNative("Shop_GetClientItemCount", PlayerManager_GetClientItemCount);
	CreateNative("Shop_SetClientItemCount", PlayerManager_SetClientItemCount);
	CreateNative("Shop_SetClientItemTimeleft", PlayerManager_SetClientItemTimeleft);
	CreateNative("Shop_GetClientItemTimeleft", PlayerManager_GetClientItemTimeleft);
	CreateNative("Shop_GetClientItemSellPrice", PlayerManager_GetClientItemSellPrice);
	CreateNative("Shop_IsClientItemToggled", PlayerManager_IsClientItemToggled);
	CreateNative("Shop_IsClientHasItem", PlayerManager_IsClientHasItem);
	CreateNative("Shop_ToggleClientItem", PlayerManager_ToggleClientItem);
	CreateNative("Shop_ToggleClientCategoryOff", PlayerManager_ToggleClientCategoryOff);
}

public PlayerManager_IsAuthorized(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return PlayerManager_IsAuthorizedIn(client);
}

public PlayerManager_IsAdmin(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return IsAdmin(client);
}

bool:PlayerManager_IsAuthorizedIn(client)
{
	return i_Id[client] != 0;
}

public PlayerManager_GetClientId(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return i_Id[client];
}

public PlayerManager_GetClientCredits(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return PlayerManager_GetCredits(client);
}

public PlayerManager_SetClientCredits(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	PlayerManager_SetCredits(client, GetNativeCell(2));
}

public PlayerManager_GiveClientCredits(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return GiveCredits(client, GetNativeCell(2), GetNativeCell(3));
}

public PlayerManager_TakeClientCredits(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return RemoveCredits(client, GetNativeCell(2), GetNativeCell(3));
}

public PlayerManager_BuyClientItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	return BuyItem(client, item_id, true);
}

public PlayerManager_UseClientItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	return UseItem(client, item_id, true);
}

public PlayerManager_RemoveClientItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	new count = GetNativeCell(3);
	
	return PlayerManager_RemoveItem(client, item_id, count);
}

public PlayerManager_GiveClientItem(Handle:plugin, numParams)
{
	decl client, String:item[SHOP_MAX_STRING_LENGTH];
	client = GetNativeCell(1);
	if (!CheckClient(client, item, sizeof(item)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, item);
	}

	decl item_id, String:sItemId[16], category_id, price, sell_price, count, duration, ItemType:type;
	item_id = GetNativeCell(2);

	IntToString(item_id, sItemId, sizeof(sItemId));

	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count, duration, type))
	{
		return false;
	}

	if(type == Item_Togglable)
	{
		duration = GetNativeCell(3);
	}
	else if(type == Item_Finite)
	{
		count = GetNativeCell(3);
	}

	PlayerManager_GiveItemEx(client, sItemId, category_id, price, sell_price, count, duration, type);

	return true;
}

public PlayerManager_GetClientItemCount(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	return PlayerManager_GetItemCount(client, item_id);
}

public PlayerManager_SetClientItemCount(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	PlayerManager_SetItemCount(client, item_id, GetNativeCell(3));
}

public PlayerManager_GetClientItemSellPrice(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	return PlayerManager_GetItemSellPrice(client, item_id);
}

public PlayerManager_SetClientItemTimeleft(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new timeleft = GetNativeCell(3);
	if (timeleft < 0)
	{
		timeleft = 0;
	}
	
	return PlayerManager_SetItemTimeleft(client, GetNativeCell(2), timeleft);
}

public PlayerManager_GetClientItemTimeleft(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	return PlayerManager_GetItemTimeleft(client, GetNativeCell(2));
}

public PlayerManager_IsClientItemToggled(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	return PlayerManager_IsItemToggled(client, item_id);
}

public PlayerManager_IsClientHasItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	return PlayerManager_ClientHasItem(client, item_id);
}

public PlayerManager_ToggleClientItem(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	new ToggleState:toggle = GetNativeCell(3);
	
	return ToggleItem(client, item_id, toggle, true);
}

PlayerManager_OnPluginStart()
{
	HookEventEx("player_changename", PlayerManager_OnPlayerName);
	
	BuildPath(Path_SM, data_path, sizeof(data_path), "data/shop.txt");
	
	kv_data = CreateKeyValues("ShopData");
	if (FileToKeyValues(kv_data, data_path))
	{
		decl String:buffer[11];
		KvGetString(kv_data, "version", buffer, sizeof(buffer));
		if (buffer[0])
		{
			if (bool:(buffer[0] == '1'))
			{
				while (KvGotoFirstSubKey(kv_data))
				{
					KvDeleteThis(kv_data);
					KvRewind(kv_data);
				}
				KeyValuesToFile(kv_data, data_path);
			}
		}
	}
	
	g_hStartCredits = CreateConVar("sm_shop_start_credits", "0", "Start credits for a new player", 0, true, 0.0);
	g_iStartCredits = GetConVarInt(g_hStartCredits);
	HookConVarChange(g_hStartCredits, PlayerManager_OnConVarChange);
	
	g_hTimerMethod = CreateConVar("sm_shop_timer_method", "0", "Timing method to use for timed items. 0 time while using and 1 is real time", 0, true, 0.0, true, 1.0);
	g_iTimerMethod = GetConVarInt(g_hTimerMethod);
	HookConVarChange(g_hTimerMethod, PlayerManager_OnConVarChange);
}

PlayerManager_OnReadyToStart()
{
	KvSetString(kv_data, "version", SHOP_VERSION);
	KeyValuesToFile(kv_data, data_path);
}

public PlayerManager_OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hStartCredits)
	{
		g_iStartCredits = StringToInt(newValue);
	}
	else if (convar == g_hTimerMethod)
	{
		g_iTimerMethod = StringToInt(newValue);
	}
}

PlayerManager_OnMapEnd()
{
	KeyValuesToFile(kv_data, data_path);
}

PlayerManager_OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		PlayerManager_SaveInfo(i);
	}
	KeyValuesToFile(kv_data, data_path);
}

PlayerManager_TransferItem(client, target, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	new ItemType:type = GetItemTypeEx(sItemId);
	
	if (type == Item_Finite)
	{
		RemoveItemEx(client, sItemId);
		GiveItemEx(target, sItemId);
	}
	else
	{
		if (PlayerManager_IsItemToggledEx(client, sItemId))
		{
			PlayerManager_ToggleItemEx(client, sItemId, Shop_UseOff);
		}
		
		if (!KvJumpToKey(h_KvClientItems[client], sItemId))
		{
			return;
		}
		
		KvJumpToKey(h_KvClientItems[target], sItemId, true);
		KvCopySubkeys(h_KvClientItems[client], h_KvClientItems[target]);
		KvRewind(h_KvClientItems[client]);
		
		new timeleft = PlayerManager_GetItemTimeleftEx(client, sItemId);
		
		RemoveItemEx(client, sItemId);
		
		if (KvGetNum(h_KvClientItems[target], "method") == 1)
		{
			decl Handle:dp;
			new Handle:timer = CreateDataTimer(float(timeleft), PlayerManager_OnPlayerItemElapsed, dp);
			
			KvSetNum(h_KvClientItems[target], "timer", _:timer);
			WritePackCell(dp, target);
			WritePackCell(dp, item_id);
		}
	
		decl String:s_Query[256];
		FormatEx(s_Query, sizeof(s_Query), "INSERT INTO `%sboughts` (`player_id`, `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time`) VALUES \
											('%d', '%s', '%d', '%d', '%d', '%d', '%d', '%d');", g_sDbPrefix, i_Id[target], sItemId, KvGetNum(h_KvClientItems[target], "count"), KvGetNum(h_KvClientItems[target], "duration"), timeleft, KvGetNum(h_KvClientItems[target], "price"), KvGetNum(h_KvClientItems[target], "sell_price"), KvGetNum(h_KvClientItems[target], "buy_time"));
		TQueryEx(s_Query, DBPrio_High);
		
		new category_id = KvGetNum(h_KvClientItems[target], "category_id");
		
		KvRewind(h_KvClientItems[target]);
		
		decl String:sCat[16];
		IntToString(category_id, sCat, sizeof(sCat));
		StrCat(sCat, sizeof(sCat), "c");
		KvSetNum(h_KvClientItems[target], sCat, KvGetNum(h_KvClientItems[target], sCat, 0)+1);
	}
}

bool:PlayerManager_IsItemToggled(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_IsItemToggledEx(client, sItemId);
}

bool:PlayerManager_IsItemToggledEx(client, const String:sItemId[])
{
	decl String:sId[16];
	IntToString(i_Id[client], sId, sizeof(sId));
	
	new bool:result = false;
	
	if (!KvJumpToKey(kv_data, sId))
	{
		return result;
	}
	
	result = bool:(KvGetNum(kv_data, sItemId, 0) != 0);
	
	KvRewind(kv_data);
	
	return result;
}

bool:PlayerManager_ToggleItem(client, item_id, ShopAction:action, bool:load = false)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_ToggleItemEx(client, sItemId, action, load);
}

bool:PlayerManager_ToggleItemEx(client, const String:sItemId[], ShopAction:action, bool:load = false, bool:ingore = false)
{
	decl String:sId[16];
	IntToString(i_Id[client], sId, sizeof(sId));
	
	if (!KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		return false;
	}
	
	new bool:result = false;
	
	new item_id = StringToInt(sItemId);
	
	KvJumpToKey(kv_data, sId, true);
	switch (action)
	{
		case Shop_UseOn :
		{
			if (load || KvGetNum(kv_data, sItemId, 0) == 0)
			{
				new duration = KvGetNum(h_KvClientItems[client], "duration");
				if (duration > 0)
				{
					new timeleft;
					if (KvGetNum(h_KvClientItems[client], "method") == 0)
					{
						timeleft = KvGetNum(h_KvClientItems[client], "timeleft");
						
						new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
						if (timer != INVALID_HANDLE)
						{
							KillTimer(timer);
						}
						
						decl Handle:dp;
						timer = CreateDataTimer(float(timeleft), PlayerManager_OnPlayerItemElapsed, dp);
						
						KvSetNum(h_KvClientItems[client], "timer", _:timer);
						WritePackCell(dp, client);
						WritePackCell(dp, item_id);
					}
					KvSetNum(h_KvClientItems[client], "started", global_timer);
					/*else
					{
						timeleft = KvGetNum(h_KvClientItems[client], "duration")+KvGetNum(h_KvClientItems[client], "buy_time")-global_timer;
					}*/
				}
				
				KvSetNum(kv_data, sItemId, 1);
				
				if (!ingore)
				{
					OnItemEquipped(client, item_id);
				}
				
				result = true;
			}
		}
		case Shop_UseOff :
		{
			if (load || KvGetNum(kv_data, sItemId, 0) != 0)
			{
				new duration = KvGetNum(h_KvClientItems[client], "duration");
				if (duration > 0)
				{
					if (KvGetNum(h_KvClientItems[client], "method") == 0)
					{
						new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
						if (timer != INVALID_HANDLE)
						{
							KillTimer(timer);
							KvSetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
						}
					}
					
					new started = KvGetNum(h_KvClientItems[client], "started");
					if (started)
					{
						new timeleft = KvGetNum(h_KvClientItems[client], "timeleft");
						KvSetNum(h_KvClientItems[client], "timeleft", timeleft-(global_timer-started));
					}
					KvSetNum(h_KvClientItems[client], "started", 0);
				}
				
				KvDeleteKey(kv_data, sItemId);
				if (!ingore)
				{
					OnItemDequipped(client, item_id);
				}
				
				result = true;
			}
		}
	}
	
	KvRewind(h_KvClientItems[client]);
	KvRewind(kv_data);
	
	return result;
}

public PlayerManager_ToggleClientCategoryOff(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new category_id = GetNativeCell(2);
	
	if (!KvGotoFirstSubKey(h_KvClientItems[client]))
	{
		return;
	}
	
	decl String:sId[16];
	IntToString(i_Id[client], sId, sizeof(sId));
	KvJumpToKey(kv_data, sId, true);
	
	decl String:sItemId[16];
	do
	{
		if (KvGetNum(h_KvClientItems[client], "category_id", -1) != category_id || !KvGetSectionName(h_KvClientItems[client], sItemId, sizeof(sItemId)))
		{
			continue;
		}
		
		new duration = KvGetNum(h_KvClientItems[client], "duration");
		
		if (duration > 0)
		{
			new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
			if (timer != INVALID_HANDLE)
			{
				if (KvGetNum(h_KvClientItems[client], "method") == 0)
				{
					KillTimer(timer);
					KvSetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
				}
			}
			new started = KvGetNum(h_KvClientItems[client], "started", 0);
			if (started)
			{
				new timeleft = KvGetNum(h_KvClientItems[client], "timeleft");
				
				KvSetNum(h_KvClientItems[client], "timeleft", timeleft-(global_timer-started));
				KvSetNum(h_KvClientItems[client], "started", 0);
			}
		}
		
		if (KvGetNum(kv_data, sItemId, 0) != 0)
		{
			KvRewind(h_KvClientItems[client]);
			OnItemDequipped(client, StringToInt(sItemId));
			KvJumpToKey(h_KvClientItems[client], sItemId);
			
			KvDeleteKey(kv_data, sItemId);
		}
	}
	while (KvGotoNextKey(h_KvClientItems[client]));
	
	KvRewind(h_KvClientItems[client]);
	KvRewind(kv_data);
}

public Action:PlayerManager_OnPlayerItemElapsed(Handle:timer, any:dp)
{
	ResetPack(dp);
	new client = ReadPackCell(dp);
	new item_id = ReadPackCell(dp);
	
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	decl String:s_Query[256];
	FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts` WHERE `player_id` = '%d' AND `item_id` = '%d';", g_sDbPrefix, i_Id[client], item_id);
	TQueryEx(s_Query, DBPrio_High);
	
	if (KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		new category_id = KvGetNum(h_KvClientItems[client], "category_id", -1);
		KvDeleteThis(h_KvClientItems[client]);
		
		KvRewind(h_KvClientItems[client]);
		
		IntToString(category_id, sItemId, sizeof(sItemId));
		StrCat(sItemId, sizeof(sItemId), "c");
		KvSetNum(h_KvClientItems[client], sItemId, KvGetNum(h_KvClientItems[client], sItemId, 0)-1);
	}
	
	OnPlayerItemElapsed(client, item_id);
}

stock bool:PlayerManager_CanPreviewEx(client, const String:sItemId[], &sec)
{
	if (!KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		return false;
	}
	
	new bool:result = false;
	
	sec = global_timer - KvGetNum(h_KvClientItems[client], "next_preview", 0);
	
	if (sec >= 0)
	{
		result = true;
		sec = global_timer+5;
		KvSetNum(h_KvClientItems[client], "next_preview", sec);
	}
	
	KvRewind(h_KvClientItems[client]);
	
	return result;
}

PlayerManager_GiveItemEx(client, const String:sItemId[], category_id, price, sell_price, count, duration, ItemType:type)
{
	KvJumpToKey(h_KvClientItems[client], sItemId, true);
	KvSetNum(h_KvClientItems[client], "category_id", category_id);
	KvSetNum(h_KvClientItems[client], "price", price);
	KvSetNum(h_KvClientItems[client], "sell_price", sell_price);
	new has = KvGetNum(h_KvClientItems[client], "count", 0);
	KvSetNum(h_KvClientItems[client], "count", has+count);
	KvSetNum(h_KvClientItems[client], "timeleft", duration);
	KvSetNum(h_KvClientItems[client], "duration", duration);
	KvSetNum(h_KvClientItems[client], "method", g_iTimerMethod);
	if (duration > 0 && (g_iTimerMethod != 0 || type == Item_None))
	{
		decl Handle:dp;
		new Handle:timer = CreateDataTimer(float(duration), PlayerManager_OnPlayerItemElapsed, dp);
		
		KvSetNum(h_KvClientItems[client], "timer", _:timer);
		WritePackCell(dp, client);
		WritePackCell(dp, StringToInt(sItemId));
	}
	KvSetNum(h_KvClientItems[client], "buy_time", global_timer);
	KvRewind(h_KvClientItems[client]);
	
	PlayerManager_ToggleItemEx(client, sItemId, Shop_UseOff, _, true);
	
	decl String:s_Query[256];
	if (has < 1)
	{
		decl String:sCat[16];
		IntToString(category_id, sCat, sizeof(sCat));
		StrCat(sCat, sizeof(sCat), "c");
		KvSetNum(h_KvClientItems[client], sCat, KvGetNum(h_KvClientItems[client], sCat, 0)+1);
		
		FormatEx(s_Query, sizeof(s_Query), "INSERT INTO `%sboughts` (`player_id`, `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time`) VALUES \
											('%d', '%s', '%d', '%d', '%d', '%d', '%d', '%d');", g_sDbPrefix, i_Id[client], sItemId, count, duration, duration, price, sell_price, global_timer);
		TQueryEx(s_Query, DBPrio_High);
	}
	else
	{
		FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `count` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, has+count, i_Id[client], sItemId);
		TQueryEx(s_Query, DBPrio_High);
	}
}

/*
PlayerManager_GiveItemEx(client, const String:sItemId[], category_id, price, sell_price, count, duration, ItemType:type)
{
	KvJumpToKey(h_KvClientItems[client], sItemId, true);
	KvSetNum(h_KvClientItems[client], "category_id", category_id);
	KvSetNum(h_KvClientItems[client], "price", price);
	KvSetNum(h_KvClientItems[client], "sell_price", sell_price);

	new has = KvGetNum(h_KvClientItems[client], "count", 0);
	KvSetNum(h_KvClientItems[client], "count", has+count);

	new has_timeleft = KvGetNum(h_KvClientItems[client], "timeleft", 0);
	KvSetNum(h_KvClientItems[client], "timeleft", has_timeleft+duration);

	new has_duration = KvGetNum(h_KvClientItems[client], "duration", 0);
	KvSetNum(h_KvClientItems[client], "duration", has_duration+duration);

	KvSetNum(h_KvClientItems[client], "method", g_iTimerMethod);
	if (duration > 0 && (g_iTimerMethod != 0 || type == Item_None))
	{
		decl Handle:dp;
		new Handle:timer = CreateDataTimer(float(duration), PlayerManager_OnPlayerItemElapsed, dp);
		
		KvSetNum(h_KvClientItems[client], "timer", _:timer);
		WritePackCell(dp, client);
		WritePackCell(dp, StringToInt(sItemId));
	}

	KvSetNum(h_KvClientItems[client], "buy_time", global_timer);
	KvRewind(h_KvClientItems[client]);
	
	PlayerManager_ToggleItemEx(client, sItemId, Shop_UseOff, _, true);
	
	decl String:s_Query[256];

	if(type == Item_Togglable)
	{
		if (has_timeleft)
		{
			FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `duration` = '%d', `timeleft` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, has_timeleft+duration, has_duration+duration, i_Id[client], sItemId);
			TQueryEx(s_Query, DBPrio_High);
		}
		else
		{
			IntToString(category_id, s_Query, 16);
			StrCat(s_Query, sizeof(s_Query), "c");
			KvSetNum(h_KvClientItems[client], s_Query, KvGetNum(h_KvClientItems[client], s_Query, 0)+1);
			
			FormatEx(s_Query, sizeof(s_Query), "INSERT INTO `%sboughts` (`player_id`, `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time`) VALUES \
												('%d', '%s', '%d', '%d', '%d', '%d', '%d', '%d');", g_sDbPrefix, i_Id[client], sItemId, count, duration, duration, price, sell_price, global_timer);
			TQueryEx(s_Query, DBPrio_High);
		}
	}
	else
	{
		if (has < 1)
		{
			IntToString(category_id, s_Query, 16);
			StrCat(s_Query, sizeof(s_Query), "c");
			KvSetNum(h_KvClientItems[client], s_Query, KvGetNum(h_KvClientItems[client], s_Query, 0)+1);

			FormatEx(s_Query, sizeof(s_Query), "INSERT INTO `%sboughts` (`player_id`, `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time`) VALUES \
												('%d', '%s', '%d', '%d', '%d', '%d', '%d', '%d');", g_sDbPrefix, i_Id[client], sItemId, count, duration, duration, price, sell_price, global_timer);
			TQueryEx(s_Query, DBPrio_High);
		}
		else
		{
			FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `count` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, has+count, i_Id[client], sItemId);
			TQueryEx(s_Query, DBPrio_High);
		}
	}
}
*/
PlayerManager_GetItemSellPrice(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_GetItemSellPriceEx(client, sItemId);
}

PlayerManager_GetItemSellPriceEx(client, const String:sItemId[])
{
	if (!KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		return -1;
	}
	
	new method = KvGetNum(h_KvClientItems[client], "method");
	
	new sell_price = KvGetNum(h_KvClientItems[client], "sell_price", -1);
	if (sell_price < 0)
	{
		KvRewind(h_KvClientItems[client]);
		return -1;
	}
	new duration = KvGetNum(h_KvClientItems[client], "duration", 0);
	if (duration < 1)
	{
		KvRewind(h_KvClientItems[client]);
		return sell_price;
	}
	
	new timeleft;
	if (method == 0)
	{
		new started = KvGetNum(h_KvClientItems[client], "started", 0);
		if (started)
		{
			timeleft = KvGetNum(h_KvClientItems[client], "timeleft", 0)-(global_timer-started);
		}
		else
		{
			timeleft = KvGetNum(h_KvClientItems[client], "timeleft", 0);
		}
	}
	else
	{
		timeleft = KvGetNum(h_KvClientItems[client], "buy_time", 0)+duration-global_timer;
	}
	
	KvRewind(h_KvClientItems[client]);

	new credits = sell_price;
	new dummy = credits;
	
	if (timeleft > 0)
	{
		credits = RoundToNearest(float(credits) * float(timeleft) / float(duration));
	}
	
	if (credits > sell_price)
	{
		credits = sell_price;
	}
	else if (credits < 0)
	{
		credits = RoundToNearest(float(dummy) / 2.0 * float(timeleft) / float(duration));
	}
	
	return credits;
}

PlayerManager_GetClientCategorySize(client, category_id)
{
	decl String:sCat[16];
	IntToString(category_id, sCat, sizeof(sCat));
	StrCat(sCat, sizeof(sCat), "c");
	
	return KvGetNum(h_KvClientItems[client], sCat);
}

stock bool:PlayerManager_RemoveItem(client, item_id, count = 1)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_RemoveItemEx(client, sItemId, count);
}

bool:PlayerManager_RemoveItemEx(client, const String:sItemId[], count = 1)
{
	if (!KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		return false;
	}
	
	decl String:s_Query[256];
	
	new bool:deleted = false, category_id;
	
	new left = KvGetNum(h_KvClientItems[client], "count", 1)-count;
	if (count < 1 || left < 1)
	{
		new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
		if (timer != INVALID_HANDLE)
		{
			KillTimer(timer);
		}
		
		category_id = KvGetNum(h_KvClientItems[client], "category_id", -1);
		KvDeleteThis(h_KvClientItems[client]);
		
		deleted = true;
		
		FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts` WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, i_Id[client], sItemId);
		TQueryEx(s_Query, DBPrio_High);
	}
	else
	{
		KvSetNum(h_KvClientItems[client], "count", left);
		
		FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `count` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, left, i_Id[client], sItemId);
		TQueryEx(s_Query, DBPrio_High);
	}
	
	KvRewind(h_KvClientItems[client]);
	
	if (deleted)
	{
		decl String:sCat[16];
		IntToString(category_id, sCat, sizeof(sCat));
		StrCat(sCat, sizeof(sCat), "c");
		KvSetNum(h_KvClientItems[client], sCat, KvGetNum(h_KvClientItems[client], sCat, 0)-1);
		
		PlayerManager_ToggleItem(client, StringToInt(sItemId), Shop_UseOff);
	}
	
	return true;
}
/*
stock bool:PlayerManager_GiveItem(client, item_id, count = 1)
{
	decl String:sItemId[16], category_id, price, sell_price, count2, duration, ItemType:type, String:item[SHOP_MAX_STRING_LENGTH];
	IntToString(item_id, sItemId, sizeof(sItemId));

	if (!ItemManager_GetItemInfoEx(sItemId, item, sizeof(item), category_id, price, sell_price, count2, duration, type))
	{
		return false;
	}

	PlayerManager_GiveItemEx(client, sItemId, category_id, price, sell_price, count, duration, type);

	return true;
}
*/
stock bool:PlayerManager_ClientHasItem(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_ClientHasItemEx(client, sItemId);
}

stock bool:PlayerManager_ClientHasItemEx(client, const String:sItemId[])
{
	new bool:result = KvJumpToKey(h_KvClientItems[client], sItemId);
	KvRewind(h_KvClientItems[client]);
	
	/*if ()
	{
		result = bool:(KvGetNum(h_KvClientItems[client], "count", 0) > 0);
		KvRewind(h_KvClientItems[client]);
	}*/
	
	return result;
}

bool:PlayerManager_SetItemTimeleft(client, item_id, timeleft)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_SetItemTimeleftEx(client, sItemId, timeleft);
}

bool:PlayerManager_SetItemTimeleftEx(client, const String:sItemId[], timeleft)
{
	if (!KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		return false;
	}
	
	new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
	}
	
	if (timeleft < 1)
	{
		timer = INVALID_HANDLE;
	}
	else if (timer != INVALID_HANDLE)
	{
		decl Handle:dp;
		timer = CreateDataTimer(float(timeleft), PlayerManager_OnPlayerItemElapsed, dp);
		WritePackCell(dp, client);
		WritePackCell(dp, StringToInt(sItemId));
	}
	else
	{
		timer = INVALID_HANDLE;
	}
	
	KvSetNum(h_KvClientItems[client], "timer", _:timer);

	new duration = KvGetNum(h_KvClientItems[client], "duration");
	if(timeleft)
	{
		if (duration < timeleft)
		{
			duration = timeleft;
			KvSetNum(h_KvClientItems[client], "duration", duration);
		}
		
		KvSetNum(h_KvClientItems[client], "timeleft", timeleft);
	}
	else
	{
		duration = timeleft;
		KvSetNum(h_KvClientItems[client], "duration", 0);
	}

	KvSetNum(h_KvClientItems[client], "timeleft", timeleft);

	decl String:s_Query[512];
	FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `duration` = '%d', `timeleft` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, duration, timeleft, i_Id[client], sItemId);
	TQueryEx(s_Query, DBPrio_High);
	
	KvRewind(h_KvClientItems[client]);
	
	return true;
}

PlayerManager_GetItemTimeleft(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_GetItemTimeleftEx(client, sItemId);
}

PlayerManager_GetItemTimeleftEx(client, const String:sItemId[])
{
	if (!KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		return 0;
	}
	
	new timeleft = 0;
	
	new duration = KvGetNum(h_KvClientItems[client], "duration");
	if (duration > 0)
	{
		new method = KvGetNum(h_KvClientItems[client], "method");
		if (method == 0)
		{
			timeleft = KvGetNum(h_KvClientItems[client], "timeleft");
			new started = KvGetNum(h_KvClientItems[client], "started", 0);
			if (started)
			{
				timeleft = timeleft-(global_timer-started);
			}
		}
		else
		{
			timeleft = KvGetNum(h_KvClientItems[client], "buy_time", 0)+duration-global_timer;
		}
	}
	
	KvRewind(h_KvClientItems[client]);
	
	return timeleft;
}

PlayerManager_GetItemCount(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return PlayerManager_GetItemCountEx(client, sItemId);
}

PlayerManager_GetItemCountEx(client, const String:sItemId[])
{
	new result = 0;
	
	if (KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		result = KvGetNum(h_KvClientItems[client], "count");
		KvRewind(h_KvClientItems[client]);
	}
	
	return result;
}

PlayerManager_SetItemCount(client, item_id, count)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	KvRewind(h_KvClientItems[client]);
	if (KvJumpToKey(h_KvClientItems[client], sItemId))
	{
		KvSetNum(h_KvClientItems[client], "count", count);
		KvRewind(h_KvClientItems[client]);
		
		decl String:s_Query[256];
		FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `count` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, count, i_Id[client], sItemId);
		TQueryEx(s_Query, DBPrio_High);
	}
}

public PlayerManager_OnPlayerName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !i_Id[client]) return;
	
	decl String:newname[MAX_NAME_LENGTH], String:buffer[65], String:s_Query[256];
	GetEventString(event, "newname", newname, sizeof(newname));
	EscapeString(newname, buffer, sizeof(buffer));
	FormatEx(s_Query, sizeof(s_Query), "UPDATE `%splayers` SET `name` = '%s' WHERE `id` = '%i';", g_sDbPrefix, buffer, i_Id[client]);
	TQueryEx(s_Query, DBPrio_Low);
}

PlayerManager_DatabaseClear()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i_Id[i] != 0)
		{
			PlayerManager_ClearPlayer(i);
			PlayerManager_OnClientPutInServer(i);
		}
	}
}

bool:PlayerManager_IsInGame(player_id)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i_Id[i] != 0 && i_Id[i] == player_id)
		{
			return true;
		}
	}
	return false;
}

PlayerManager_OnClientPutInServer(client)
{
	if (h_KvClientItems[client] == INVALID_HANDLE)
	{
		h_KvClientItems[client] = CreateKeyValues("Items");
	}
	
	decl String:auth[22];
	GetClientAuthString(client, auth, sizeof(auth), false);
	
	decl String:s_Query[256];
	if (db_type == DB_MySQL)
	{
		FormatEx(s_Query, sizeof(s_Query), "SELECT `money`, `id` FROM `%splayers` WHERE `auth` REGEXP '^STEAM_[0-9]:%s$';", g_sDbPrefix, auth[8]);
	}
	else
	{
		FormatEx(s_Query, sizeof(s_Query), "SELECT `money`, `id` FROM `%splayers` WHERE `auth` = '%s';", g_sDbPrefix, auth);
	}
	
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, GetClientSerial(client));
	WritePackString(dp, auth);
	WritePackCell(dp, 0);
	
	TQuery(PlayerManager_AuthorizeClient, s_Query, dp, DBPrio_Low);
}

public PlayerManager_AuthorizeClient(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	if (owner == INVALID_HANDLE)
	{
		CloseHandle(dp);
		TryConnect();
		return;
	}
	
	if (hndl == INVALID_HANDLE || error[0])
	{
		CloseHandle(dp);
		LogError("PlayerManager_AuthorizeClient: %s", error);
		return;
	}
	
	ResetPack(dp);
	new serial = ReadPackCell(dp);
	new client = GetClientFromSerial(serial);
	if (!client)
	{
		CloseHandle(dp);
		return;
	}
	decl String:auth[22];
	ReadPackString(dp, auth, sizeof(auth));
	new try = ReadPackCell(dp);
	
	switch (try)
	{
		case 0 :
		{
			decl String:name[MAX_NAME_LENGTH], String:buffer[65];
			GetClientName(client, name, sizeof(name));
			EscapeString(name, buffer, sizeof(buffer));
			
			decl String:s_Query[256];
			if (!SQL_FetchRow(hndl))
			{
				ResetPack(dp, true);
				WritePackCell(dp, serial);
				WritePackString(dp, auth);
				WritePackCell(dp, 1);
				WritePackCell(dp, g_iStartCredits);
				
				FormatEx(s_Query, sizeof(s_Query), "INSERT INTO `%splayers` (`name`, `auth`, `money`, `lastconnect`) VALUES ('%s', '%s', '%d', '%d');", g_sDbPrefix, buffer, auth, g_iStartCredits, global_timer);
				TQuery(PlayerManager_AuthorizeClient, s_Query, dp, DBPrio_Low);
				
				return;
			}
			iCredits[client] = SQL_FetchInt(hndl, 0);
			i_Id[client] = SQL_FetchInt(hndl, 1);
			
			PlayerManager_LoadClientItems(client);
			
			FormatEx(s_Query, sizeof(s_Query), "UPDATE `%splayers` SET `name` = '%s', `lastconnect` = '%d' WHERE `id` = '%i';", g_sDbPrefix, buffer, global_timer, i_Id[client]);
			TQueryEx(s_Query, DBPrio_Low);
		}
		case 1 :
		{
			iCredits[client] = ReadPackCell(dp);
			i_Id[client] = SQL_GetInsertId(hndl);
		}
	}
	CloseHandle(dp);
	
	OnAuthorized(client);
}

PlayerManager_LoadClientItems(client)
{
	decl String:s_Query[256];
	FormatEx(s_Query, sizeof(s_Query), "SELECT `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time` FROM `%sboughts`, `%sitems` WHERE `id` = `item_id` AND `player_id` = '%i';", g_sDbPrefix, g_sDbPrefix, i_Id[client]);
	TQuery(PlayerManager_GetItemsFromDB, s_Query, GetClientSerial(client), DBPrio_Low);
}

public PlayerManager_GetItemsFromDB(Handle:owner, Handle:hndl, const String:error[], any:serial)
{
	if (owner == INVALID_HANDLE)
	{
		TryConnect();
		return;
	}
	
	if (hndl == INVALID_HANDLE || error[0])
	{
		LogError("PlayerManager_GetItemsFromDB: %s", error);
		return;
	}
	
	new client = GetClientFromSerial(serial);
	if (!client)
	{
		return;
	}
	
	decl String:sItemId[16], String:s_Query[256];
	while (SQL_FetchRow(hndl))
	{
		new item_id = SQL_FetchInt(hndl, 0);
		new buy_time = SQL_FetchInt(hndl, 6);
		new duration = SQL_FetchInt(hndl, 2);
		new timeleft = SQL_FetchInt(hndl, 3);
		
		if (duration > 0 && ((g_iTimerMethod == 0 && timeleft < 1) || (g_iTimerMethod != 0 && global_timer - buy_time > duration)))
		{
			FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts` WHERE `player_id` = '%d' AND `item_id` = '%d';", g_sDbPrefix, i_Id[client], item_id);
			TQueryEx(s_Query, DBPrio_High);
			continue;
		}
		
		IntToString(item_id, sItemId, sizeof(sItemId));
		
		if (!IsItemExistsEx(sItemId)) continue;
		
		if (duration < 1)
		{
			duration = GetItemDurationEx(sItemId);
			timeleft = duration;
			if (duration > 0)
			{
				new total = global_timer+duration-buy_time;
				FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `duration` = '%d', `timeleft` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%d';", g_sDbPrefix, total, timeleft, i_Id[client], item_id);
				TQueryEx(s_Query, DBPrio_High);
			}
		}
		
		new category_id = GetItemCategoryIdEx(sItemId);
		
		if (KvJumpToKey(h_KvClientItems[client], sItemId))
		{
			new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
			if (timer != INVALID_HANDLE)
			{
				KillTimer(timer);
				KvSetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
			}
		}
		else
		{
			decl String:cat_count[16];
			IntToString(category_id, cat_count, sizeof(cat_count));
			StrCat(cat_count, sizeof(cat_count), "c");
			KvSetNum(h_KvClientItems[client], cat_count, KvGetNum(h_KvClientItems[client], cat_count, 0)+1);
			
			KvJumpToKey(h_KvClientItems[client], sItemId, true);
		}
		
		KvSetNum(h_KvClientItems[client], "category_id", category_id);
		KvSetNum(h_KvClientItems[client], "count", SQL_FetchInt(hndl, 1));
		KvSetNum(h_KvClientItems[client], "duration", duration);
		KvSetNum(h_KvClientItems[client], "timeleft", timeleft);
		KvSetNum(h_KvClientItems[client], "price", SQL_FetchInt(hndl, 4));
		KvSetNum(h_KvClientItems[client], "sell_price", SQL_FetchInt(hndl, 5));
		KvSetNum(h_KvClientItems[client], "method", g_iTimerMethod);
		KvSetNum(h_KvClientItems[client], "buy_time", buy_time);
		if (duration > 0 && (g_iTimerMethod != 0 || GetItemTypeEx(sItemId) == Item_None))
		{
			decl Handle:dp;
			new Handle:timer = CreateDataTimer(float(buy_time+duration-global_timer), PlayerManager_OnPlayerItemElapsed, dp);
			
			KvSetNum(h_KvClientItems[client], "timer", _:timer);
			WritePackCell(dp, client);
			WritePackCell(dp, item_id);
		}
		KvRewind(h_KvClientItems[client]);
		
		if (PlayerManager_IsItemToggledEx(client, sItemId))
		{
			ToggleItem(client, item_id, Toggle_On, true, true);
		}
	}
}

PlayerManager_ClearPlayer(client)
{
	if (h_KvClientItems[client] != INVALID_HANDLE)
	{
		CloseHandle(h_KvClientItems[client]);
		h_KvClientItems[client] = INVALID_HANDLE;
	}
	i_Id[client] = 0;
	iCredits[client] = 0;
}

PlayerManager_OnClientDisconnect_Post(client)
{
	if (!i_Id[client]) return;
	
	PlayerManager_SaveInfo(client, true);
	
	PlayerManager_ClearPlayer(client);
}

PlayerManager_SaveInfo(client, bool:cleartimer = false)
{
	if (!i_Id[client]) return;
	
	decl String:s_Query[256], timeleft, String:sItemId[16];
	FormatEx(s_Query, sizeof(s_Query), "UPDATE `%splayers` SET `money` = '%d' WHERE `id` = '%d';", g_sDbPrefix, iCredits[client], i_Id[client]);
	TQueryEx(s_Query, DBPrio_High);
	
	if (KvGotoFirstSubKey(h_KvClientItems[client]))
	{
		do
		{
			if (!KvGetSectionName(h_KvClientItems[client], sItemId, sizeof(sItemId)))
			{
				continue;
			}
			
			new duration = KvGetNum(h_KvClientItems[client], "duration");
			if (KvGetNum(h_KvClientItems[client], "method") == 0)
			{
				timeleft = KvGetNum(h_KvClientItems[client], "timeleft");
				new started = KvGetNum(h_KvClientItems[client], "started", 0);
				if (started)
				{
					timeleft = timeleft-(global_timer-started);
				}
			}
			else
			{
				timeleft = KvGetNum(h_KvClientItems[client], "buy_time", 0)+duration-global_timer;
			}
			
			if (cleartimer)
			{
				new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
				if (timer != INVALID_HANDLE)
				{
					KillTimer(timer);
					KvSetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
				}
			}
			
			FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `count` = '%d', `duration` = '%d', `timeleft` = '%d', `buy_price` = '%d', `sell_price` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, KvGetNum(h_KvClientItems[client], "count", 1), duration, timeleft, KvGetNum(h_KvClientItems[client], "price"), KvGetNum(h_KvClientItems[client], "sell_price"), i_Id[client], sItemId);
			TQueryEx(s_Query, DBPrio_High);
		}
		while (KvGotoNextKey(h_KvClientItems[client]));
		
		KvRewind(h_KvClientItems[client]);
	}
}

PlayerManager_OnItemRegistered(item_id)
{
	decl String:s_Query[256];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!i_Id[client]) continue;
		
		FormatEx(s_Query, sizeof(s_Query), "SELECT `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time` FROM `%sboughts` WHERE `item_id` = '%i' AND `player_id` = '%i';", g_sDbPrefix, item_id, i_Id[client]);
		TQuery(PlayerManager_GetItemsFromDB, s_Query, GetClientSerial(client), DBPrio_Low);
	}
}

PlayerManager_OnItemUnregistered(item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	decl String:s_Query[256];
	
	new category_id = -1;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!i_Id[client]) continue;
		
		if (KvJumpToKey(h_KvClientItems[client], sItemId))
		{
			new duration = KvGetNum(h_KvClientItems[client], "duration");
			new started = KvGetNum(h_KvClientItems[client], "started", 0);
			new timeleft = KvGetNum(h_KvClientItems[client], "timeleft");
			
			if (started)
			{
				timeleft = timeleft-(global_timer-started);
				
				new Handle:timer = Handle:KvGetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
				if (timer != INVALID_HANDLE)
				{
					KillTimer(timer);
					KvSetNum(h_KvClientItems[client], "timer", _:INVALID_HANDLE);
				}
			}
			
			FormatEx(s_Query, sizeof(s_Query), "UPDATE `%sboughts` SET `count` = '%d', `duration` = '%d', `timeleft` = '%d', `buy_price` = '%d', `sell_price` = '%d' WHERE `player_id` = '%d' AND `item_id` = '%s';", g_sDbPrefix, KvGetNum(h_KvClientItems[client], "count", 1), duration, timeleft, KvGetNum(h_KvClientItems[client], "price"), KvGetNum(h_KvClientItems[client], "sell_price"), i_Id[client], sItemId);
			TQueryEx(s_Query, DBPrio_High);
			
			category_id = KvGetNum(h_KvClientItems[client], "category_id", -1);
			
			KvDeleteThis(h_KvClientItems[client]);
			KvRewind(h_KvClientItems[client]);
			
			IntToString(category_id, sItemId, sizeof(sItemId));
			StrCat(sItemId, sizeof(sItemId), "c");
			KvSetNum(h_KvClientItems[client], sItemId, KvGetNum(h_KvClientItems[client], sItemId, 0)-1);
			
			//NotifyItemOff(client, item_id);
		}
	}
}

PlayerManager_GetCredits(client)
{
	return iCredits[client];
}

stock PlayerManager_SetCredits(client, credits)
{
	if (credits < 0)
	{
		credits = 0;
	}
	iCredits[client] = credits;
	
	decl String:s_Query[256];
	FormatEx(s_Query, sizeof(s_Query), "UPDATE `%splayers` SET `money` = '%d' WHERE `id` = '%d';", g_sDbPrefix, iCredits[client], i_Id[client]);
	TQueryEx(s_Query, DBPrio_High);
}

PlayerManager_GiveCredits(client, credits)
{
	iCredits[client] += credits;
	
	decl String:s_Query[256];
	FormatEx(s_Query, sizeof(s_Query), "UPDATE `%splayers` SET `money` = '%d' WHERE `id` = '%d';", g_sDbPrefix, iCredits[client], i_Id[client]);
	TQueryEx(s_Query, DBPrio_High);
}

PlayerManager_RemoveCredits(client, credits)
{
	iCredits[client] -= credits;
	if (iCredits[client] < 0)
	{
		iCredits[client] = 0;
	}
	
	decl String:s_Query[256];
	FormatEx(s_Query, sizeof(s_Query), "UPDATE `%splayers` SET `money` = '%d' WHERE `id` = '%d';", g_sDbPrefix, iCredits[client], i_Id[client]);
	TQueryEx(s_Query, DBPrio_High);
}