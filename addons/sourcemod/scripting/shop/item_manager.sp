new Handle:h_arCategories;
new Handle:h_trieCategories;
new Handle:h_KvItems;

#define CAT_PLUGIN 0
#define CAT_DISPLAY 1
#define CAT_DESC 2
#define CAT_SHOULD 3
#define CAT_SELECT 4
#define CAT_SIZE 5
#define CAT_MAX 6

ItemManager_CreateNatives()
{
	h_arCategories = CreateArray(ByteCountToCells(SHOP_MAX_STRING_LENGTH));
	h_trieCategories = CreateTrie();
	h_KvItems = CreateKeyValues("Items");
	
	CreateNative("Shop_RegisterCategory", ItemManager_RegisterCategory);
	CreateNative("Shop_StartItem", ItemManager_StartItem);
	CreateNative("Shop_SetInfo", ItemManager_SetInfo);
	CreateNative("Shop_SetCustomInfo", ItemManager_SetCustomInfo);
	CreateNative("Shop_SetCustomInfoFloat", ItemManager_SetCustomInfoFloat);
	CreateNative("Shop_SetCustomInfoString", ItemManager_SetCustomInfoString);
	CreateNative("Shop_KvCopySubKeysCustomInfo", ItemManager_KvCopySubKeysCustomInfo);
	CreateNative("Shop_SetCallbacks", ItemManager_SetCallbacks);
	CreateNative("Shop_SetCanLuck", ItemManager_SetCanLuck);
	CreateNative("Shop_EndItem", ItemManager_EndItem);
	
	CreateNative("Shop_GetItemCustomInfo", ItemManager_GetItemCustomInfo);
	CreateNative("Shop_SetItemCustomInfo", ItemManager_SetItemCustomInfo);
	
	CreateNative("Shop_GetItemCustomInfoFloat", ItemManager_GetItemCustomInfoFloat);
	CreateNative("Shop_SetItemCustomInfoFloat", ItemManager_SetItemCustomInfoFloat);
	
	CreateNative("Shop_GetItemCustomInfoString", ItemManager_GetItemCustomInfoString);
	CreateNative("Shop_SetItemCustomInfoString", ItemManager_SetItemCustomInfoString);
	CreateNative("Shop_KvCopySubKeysItemCustomInfo", ItemManager_KvCopySubKeysItemCustomInfo);
	
	CreateNative("Shop_GetItemPrice", ItemManager_GetItemPrice);
	CreateNative("Shop_SetItemPrice", ItemManager_SetItemPrice);
	
	CreateNative("Shop_GetItemSellPrice", ItemManager_GetItemSellPrice);
	CreateNative("Shop_SetItemSellPrice", ItemManager_SetItemSellPrice);
	
	CreateNative("Shop_GetItemValue", ItemManager_GetItemValue);
	CreateNative("Shop_SetItemValue", ItemManager_SetItemValue);
	
	CreateNative("Shop_GetItemId", ItemManager_GetItemId);
	CreateNative("Shop_GetItemById", ItemManager_GetItemById);
	CreateNative("Shop_GetItemNameById", ItemManager_GetItemNameById);
	
	CreateNative("Shop_GetItemCanLuck", ItemManager_GetItemCanLuck);
	CreateNative("Shop_SetItemCanLuck", ItemManager_SetItemCanLuck);
	
	CreateNative("Shop_GetItemCategoryId", ItemManager_GetItemCategoryIdNative);
	
	CreateNative("Shop_IsItemExists", ItemManager_IsItemExistsNative);
	CreateNative("Shop_GetItemType", ItemManager_GetItemTypeNative);
	
	CreateNative("Shop_IsValidCategory", ItemManager_IsValidCategoryNative);
	
	CreateNative("Shop_GetCategoryId", ItemManager_GetCategoryIdNative);
	CreateNative("Shop_GetCategoryById", ItemManager_GetCategoryByIdNative);
	CreateNative("Shop_GetCategoryNameById", ItemManager_GetCategoryNameByIdNative);
	
	CreateNative("Shop_FillArrayByItems", ItemManager_FillArrayByItemsNative);
	CreateNative("Shop_FormatItem", ItemManager_FormatItemNative);
}

ItemManager_OnPluginStart()
{
	RegServerCmd("sm_items_dump", ItemManager_Dump);
}

public Action:ItemManager_Dump(argc)
{
	KeyValuesToFile(h_KvItems, "addons/items.txt");
}

ItemManager_OnPluginEnd()
{
	ItemManager_UnregisterMe();
}

ItemManager_UnregisterMe(Handle:plugin = INVALID_HANDLE)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	if (KvGotoFirstSubKey(h_KvItems))
	{
		do
		{
			if (plugin != INVALID_HANDLE && Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE) != plugin) continue;
			
			KvGetSectionName(h_KvItems, buffer, sizeof(buffer));
			new item_id = StringToInt(buffer);
			
			//KvGetString(h_KvItems, "item", buffer, sizeof(buffer));
			OnItemUnregistered(item_id);
			
			while (KvDeleteThis(h_KvItems) == 1)
			{
				if (plugin != INVALID_HANDLE && Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE) != plugin) break;
				
				KvGetSectionName(h_KvItems, buffer, sizeof(buffer));
				item_id = StringToInt(buffer);
				
				OnItemUnregistered(item_id);
			}
		}
		while (KvGotoNextKey(h_KvItems));
		
		KvRewind(h_KvItems);
	}
	
	decl Handle:trie, Handle:array;
	for (new category_id = 0; category_id < GetArraySize(h_arCategories); category_id++)
	{
		GetArrayString(h_arCategories, category_id, buffer, sizeof(buffer));
		if (!GetTrieValue(h_trieCategories, buffer, trie)) continue;
		
		GetTrieValue(trie, "plugin_array", array);
		
		new index = FindValueInArray(array, plugin);
		if (index == -1) continue;
		
		RemoveFromArray(array, index);
		
		if (!GetArraySize(array))
		{
			CloseHandle(array);
			CloseHandle(trie);
			
			RemoveFromTrie(h_trieCategories, buffer);
		}
	}
}

public ItemManager_RegisterCategory(Handle:plugin, numParams)
{
	decl String:category[SHOP_MAX_STRING_LENGTH], Handle:trie, Handle:array;
	
	GetNativeString(1, category, sizeof(category));
	TrimString(category);
	if (!category[0])
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No category specified!");
	}

	new index = FindStringInArray(h_arCategories, category);
	
	if (index == -1)
	{
		index = PushArrayString(h_arCategories, category);
	}
	
	if (GetTrieValue(h_trieCategories, category, trie))
	{
		GetTrieValue(trie, "plugin_array", array);
		
		if (FindValueInArray(array, plugin) != -1)
		{
			return index;
		}
	}
	else
	{
		trie = CreateTrie();
		SetTrieValue(h_trieCategories, category, trie);
		
		array = CreateArray(CAT_MAX);
		
		decl String:buffer[128];
		GetNativeString(2, buffer, sizeof(buffer));
		
		SetTrieValue(trie, "plugin_array", array);
		
		SetTrieString(trie, "name", buffer);
		GetNativeString(3, buffer, sizeof(buffer));
		
		SetTrieString(trie, "description", buffer);
	}
	
	decl any:tmp[CAT_MAX];
	tmp[CAT_PLUGIN] = plugin;
	tmp[CAT_DISPLAY] = GetNativeCell(4);
	tmp[CAT_DESC] = GetNativeCell(5);
	tmp[CAT_SHOULD] = GetNativeCell(6);
	tmp[CAT_SELECT] = GetNativeCell(7);
	tmp[CAT_SIZE] = 0;
	
	PushArrayArray(array, tmp);

	return index;
}

bool:ItemManager_OnCategorySelect(client, category_id, ShopMenu:menu)
{
	decl String:category[SHOP_MAX_STRING_LENGTH];
	GetArrayString(h_arCategories, category_id, category, sizeof(category));
	
	decl Handle:trie, Handle:array, any:tmp[CAT_MAX];
	
	GetTrieValue(h_trieCategories, category, trie);
	GetTrieValue(trie, "plugin_array", array);
	
	new bool:result = true;
	for (new i = 0; i < GetArraySize(array); i++)
	{
		GetArrayArray(array, i, tmp);
		
		if (tmp[CAT_SELECT] != INVALID_FUNCTION)
		{
			Call_StartFunction(tmp[CAT_PLUGIN], tmp[CAT_SELECT]);
			Call_PushCell(client);
			Call_PushCell(category_id);
			Call_PushString(category);
			Call_PushCell(menu);
			Call_Finish(result);
			
			if (!result)
			{
				return false;
			}
		}
	}
	
	return true;
}

new plugin_category_id = -1;
new Handle:plugin_kv;
new Handle:plugin_array;
new String:plugin_category[SHOP_MAX_STRING_LENGTH];
new String:plugin_item[SHOP_MAX_STRING_LENGTH];

public ItemManager_StartItem(Handle:plugin, numParams)
{
	new category_id = GetNativeCell(1);
	
	if (!ItemManager_IsValidCategory(category_id))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Category id %d is invalid", category_id);
	}
	
	decl String:item[SHOP_MAX_STRING_LENGTH];
	GetNativeString(2, item, sizeof(item));
	TrimString(item);
	if (!item[0])
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item specified!");
	}
	
	decl String:buffer[SHOP_MAX_STRING_LENGTH], Handle:trie, Handle:array;
	GetArrayString(h_arCategories, category_id, buffer, sizeof(buffer));
	
	GetTrieValue(h_trieCategories, buffer, trie);
	GetTrieValue(trie, "plugin_array", array);
	
	if (FindValueInArray(array, plugin) == -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "This plugin didn't register the category id %d", category_id);
	}
	
	if (KvGotoFirstSubKey(h_KvItems))
	{
		do
		{
			if (KvGetNum(h_KvItems, "category_id", -1) != category_id) continue;
			
			KvGetString(h_KvItems, "item", buffer, sizeof(buffer));
			
			if (StrEqual(buffer, item, false))
			{
				KvRewind(h_KvItems);
				
				ThrowNativeError(SP_ERROR_NATIVE, "Item %s is already registered in the category id %d", item, category_id);
			}
		}
		while (KvGotoNextKey(h_KvItems));
		
		KvRewind(h_KvItems);
	}
	
	plugin_category_id = category_id;
	GetArrayString(h_arCategories, category_id, plugin_category, sizeof(plugin_category));
	strcopy(plugin_item, sizeof(plugin_item), item);
	
	plugin_kv = CreateKeyValues("ItemRegister");
	KvSetNum(plugin_kv, "plugin", _:plugin);
	KvSetNum(plugin_kv, "category_id", category_id);
	KvSetString(plugin_kv, "item", item);
	plugin_array = array;
	
	return true;
}

public ItemManager_SetInfo(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	decl String:buffer[128];
	
	GetNativeString(1, buffer, sizeof(buffer));
	KvSetString(plugin_kv, "name", buffer);
	
	GetNativeString(2, buffer, sizeof(buffer));
	KvSetString(plugin_kv, "description", buffer);
	
	new price = GetNativeCell(3);
	new sell_price = GetNativeCell(4);
	
	if (price < 0) price = 0;
	
	if (sell_price < -1) sell_price = -1;
	else if (sell_price > price) sell_price = price;
	
	new ItemType:type = GetNativeCell(5);
	
	KvSetNum(plugin_kv, "price", price);
	KvSetNum(plugin_kv, "type", _:type);
	
	new value = GetNativeCell(6);
	
	if (type == Item_Finite || type == Item_BuyOnly)
	{
		if (value < 1) value = 1;
		KvSetNum(plugin_kv, "sell_price", sell_price);
		KvSetNum(plugin_kv, "count", value);
	}
	else
	{
		if (value < 0) value = 0;
		KvSetNum(plugin_kv, "sell_price", sell_price);
		KvSetNum(plugin_kv, "duration", value);
		KvSetNum(plugin_kv, "count", 1);
	}
	
	KvSetNum(plugin_kv, "can_luck", 1);
}

public ItemManager_SetCustomInfo(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	decl String:info[SHOP_MAX_STRING_LENGTH];
	GetNativeString(1, info, sizeof(info));
	
	KvJumpToKey(plugin_kv, "CustomInfo", true);
	KvSetNum(plugin_kv, info, GetNativeCell(2));
	KvGoBack(plugin_kv);
}

public ItemManager_SetCustomInfoFloat(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	decl String:info[SHOP_MAX_STRING_LENGTH];
	GetNativeString(1, info, sizeof(info));
	
	KvJumpToKey(plugin_kv, "CustomInfo", true);
	KvSetNum(plugin_kv, info, GetNativeCell(2));
	KvGoBack(plugin_kv);
}

public ItemManager_SetCustomInfoString(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	decl String:info[SHOP_MAX_STRING_LENGTH], String:value[256];
	GetNativeString(1, info, sizeof(info));
	GetNativeString(2, value, sizeof(value));
	
	KvJumpToKey(plugin_kv, "CustomInfo", true);
	KvSetString(plugin_kv, info, value);
	KvGoBack(plugin_kv);
}

public ItemManager_KvCopySubKeysCustomInfo(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	new Handle:kv = GetNativeCell(1);
	KvGetNum(kv, "___SD__");
	
	KvJumpToKey(plugin_kv, "CustomInfo", true);
	KvCopySubkeys(kv, plugin_kv);
	KvGoBack(plugin_kv);
}

public ItemManager_SetCallbacks(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	KvSetNum(plugin_kv, "callback_register", GetNativeCell(1));
	KvSetNum(plugin_kv, "callback_use", GetNativeCell(2));
	KvSetNum(plugin_kv, "callback_should", GetNativeCell(3));
	KvSetNum(plugin_kv, "callback_display", GetNativeCell(4));
	KvSetNum(plugin_kv, "callback_description", GetNativeCell(5));
	KvSetNum(plugin_kv, "callback_preview", GetNativeCell(6));
	KvSetNum(plugin_kv, "callback_buy", GetNativeCell(7));
	KvSetNum(plugin_kv, "callback_sell", GetNativeCell(8));
	KvSetNum(plugin_kv, "callback_elapse", GetNativeCell(9));
}

public ItemManager_SetCanLuck(Handle:plugin, numParams)
{
	if (plugin_kv == INVALID_HANDLE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	KvSetNum(plugin_kv, "can_luck", GetNativeCell(1));
}

public ItemManager_EndItem(Handle:plugin, numParams)
{
	new ItemType:type = ItemType:KvGetNum(plugin_kv, "type", _:Item_None);
	
	if (type != Item_None && type != Item_BuyOnly && any:KvGetNum(plugin_kv, "callback_use", _:INVALID_FUNCTION) == INVALID_FUNCTION)
	{
		CloseHandle(plugin_kv);
		
		plugin_category_id = -1;
		plugin_kv = INVALID_HANDLE;
		plugin_array = INVALID_HANDLE;
		plugin_category[0] = '\0';
		plugin_item[0] = '\0';
		
		ThrowNativeError(SP_ERROR_NATIVE, "Using item type other than none, ItemUseToggle callback must to be set");
	}
	if (type == Item_BuyOnly && any:KvGetNum(plugin_kv, "callback_buy", _:INVALID_FUNCTION) == INVALID_FUNCTION)
	{
		CloseHandle(plugin_kv);
		
		plugin_category_id = -1;
		plugin_kv = INVALID_HANDLE;
		plugin_array = INVALID_HANDLE;
		plugin_category[0] = '\0';
		plugin_item[0] = '\0';
		
		ThrowNativeError(SP_ERROR_NATIVE, "Using item type BuyOnly, OnBuy callback must to be set");
	}
	
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, plugin_category_id);
	WritePackCell(dp, KvGetNum(plugin_kv, "plugin", _:INVALID_HANDLE));
	WritePackCell(dp, KvGetNum(plugin_kv, "callback_register", _:INVALID_FUNCTION));
	WritePackString(dp, plugin_category);
	WritePackString(dp, plugin_item);
	WritePackCell(dp, _:plugin_kv);
	WritePackCell(dp, _:plugin_array);
	WritePackCell(dp, 0);
	
	KvRewind(plugin_kv);
	
	decl String:s_Query[256];
	FormatEx(s_Query, sizeof(s_Query), "SELECT `id` FROM `%sitems` WHERE `category` = '%s' AND `item` = '%s';", g_sDbPrefix, plugin_category, plugin_item);
	
	TQuery(ItemManager_OnItemRegistered, s_Query, dp, DBPrio_High);
	
	plugin_category_id = -1;
	plugin_kv = INVALID_HANDLE;
	plugin_array = INVALID_HANDLE;
	plugin_category[0] = '\0';
	plugin_item[0] = '\0';
}

public ItemManager_OnItemRegistered(Handle:owner, Handle:hndl, const String:error[], any:dp)
{
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	
	ResetPack(dp);
	new category_id = ReadPackCell(dp);
	new Handle:plugin = Handle:ReadPackCell(dp);
	new Function:callback = Function:ReadPackCell(dp);
	ReadPackString(dp, category, sizeof(category));
	ReadPackString(dp, item, sizeof(item));
	new Handle:kv = Handle:ReadPackCell(dp);
	new Handle:array = Handle:ReadPackCell(dp);
	new try = ReadPackCell(dp);
	
	if (!try)
	{
		if (!IsPluginValid(plugin))
		{
			CloseHandle(kv);
			CloseHandle(dp);
			
			return;
		}
	}
	
	if (error[0])
	{
		LogError("ItemManager_OnItemRegistered: %s", error);
	}
	if (hndl == INVALID_HANDLE)
	{
		CloseHandle(dp);
		return;
	}
	
	new id;
	switch (try)
	{
		case 0 :
		{
			if (!SQL_FetchRow(hndl))
			{
				decl String:s_Query[256];
				FormatEx(s_Query, sizeof(s_Query), "INSERT INTO `%sitems` (`category`, `item`) VALUES ('%s', '%s');", g_sDbPrefix, category, item);
				
				ResetPack(dp, true);
				WritePackCell(dp, category_id);
				WritePackCell(dp, _:plugin);
				WritePackCell(dp, _:callback);
				WritePackString(dp, category);
				WritePackString(dp, item);
				WritePackCell(dp, _:kv);
				WritePackCell(dp, _:array);
				WritePackCell(dp, 1);
				
				TQuery(ItemManager_OnItemRegistered, s_Query, dp);
				
				return;
			}
			
			id = SQL_FetchInt(hndl, 0);
		}
		case 1 :
		{
			id = SQL_GetInsertId(hndl);
		}
	}
	
	CloseHandle(dp);
	
	decl String:buffer[16];
	IntToString(id, buffer, sizeof(buffer));
	
	KvJumpToKey(h_KvItems, buffer, true);
	KvCopySubkeys(kv, h_KvItems);
	KvRewind(h_KvItems);
	
	CloseHandle(kv);
	
	new index = FindValueInArray(array, plugin);
	
	decl any:tmp[CAT_MAX];
	GetArrayArray(array, index, tmp);
	tmp[CAT_SIZE]++;
	SetArrayArray(array, index, tmp);
	
	//OnItemRegistered(category_id, item, id);
	OnItemRegistered(id);
	
	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushString(item);
		Call_PushCell(id);
		Call_Finish();
	}
}

public ItemManager_GetItemCustomInfo(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new result = GetNativeCell(3);
	
	if (KvJumpToKey(h_KvItems, "CustomInfo"))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		result = KvGetNum(h_KvItems, buffer, result);
	}
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_SetItemCustomInfo(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bool:result = false;
	
	if (KvJumpToKey(h_KvItems, "CustomInfo", true))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		KvSetNum(h_KvItems, buffer, GetNativeCell(3));
		
		result = true;
	}
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_KvCopySubKeysItemCustomInfo(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bool:result = false;
	
	new Handle:origin_kv = GetNativeCell(2);
	KvGetNum(origin_kv, "___SD__");
	
	if (KvJumpToKey(h_KvItems, "CustomInfo", true))
	{
		KvCopySubkeys(origin_kv, h_KvItems);
		
		result = true;
	}
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_GetItemCustomInfoFloat(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new Float:result = GetNativeCell(3);
	
	if (KvJumpToKey(h_KvItems, "CustomInfo"))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		result = KvGetFloat(h_KvItems, buffer, result);
	}
	
	KvRewind(h_KvItems);
	
	return _:result;
}

public ItemManager_SetItemCustomInfoFloat(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bool:result = false;
	
	if (KvJumpToKey(h_KvItems, "CustomInfo", true))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		KvSetNum(h_KvItems, buffer, GetNativeCell(3));
		
		result = true;
	}
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_GetItemCustomInfoString(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bytes = 0;
	
	if (KvJumpToKey(h_KvItems, "CustomInfo"))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		
		new size = GetNativeCell(4);
		
		decl String:defvalue[size];
		GetNativeString(5, defvalue, size);
		KvGetString(h_KvItems, buffer, defvalue, size, defvalue);
		
		SetNativeString(3, defvalue, size, true, bytes);
	}
	
	KvRewind(h_KvItems);
	
	return bytes;
}

public ItemManager_SetItemCustomInfoString(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bool:result = false;
	
	if (KvJumpToKey(h_KvItems, "CustomInfo", true))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		
		decl String:value[256];
		GetNativeString(3, value, sizeof(value));
		KvSetString(h_KvItems, buffer, value);
		
		result = true;
	}
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_GetItemPrice(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new result = KvGetNum(h_KvItems, "price", 0);
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_SetItemPrice(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new price = GetNativeCell(2);
	if (price < 0)
	{
		price = 0;
	}
	if (KvGetNum(h_KvItems, "sell_price", -1) > price)
	{
		KvSetNum(h_KvItems, "sell_price", price);
	}
	
	KvSetNum(h_KvItems, "price", price);
	KvRewind(h_KvItems);
}

public ItemManager_GetItemSellPrice(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new result = KvGetNum(h_KvItems, "sell_price", -1);
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_SetItemSellPrice(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new price = KvGetNum(h_KvItems, "price");
	new sell_price = GetNativeCell(2);
	if (sell_price > price)
	{
		sell_price = price;
	}
	else if (sell_price < -1)
	{
		sell_price = -1;
	}
	KvSetNum(h_KvItems, "sell_price", sell_price);
	
	KvRewind(h_KvItems);
}

public ItemManager_GetItemValue(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new ItemType:type = ItemType:KvGetNum(h_KvItems, "type", _:Item_Finite);
	
	new result = 0;
	
	if (type == Item_Finite || type == Item_BuyOnly)
	{
		result = KvGetNum(h_KvItems, "count", 1);
	}
	else
	{
		result = KvGetNum(h_KvItems, "duration", 0);
	}
	
	KvRewind(h_KvItems);
	
	return result;
}

public ItemManager_SetItemValue(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new ItemType:type = ItemType:KvGetNum(h_KvItems, "type", _:Item_Finite);
	
	new value = GetNativeCell(2);
	
	switch (type)
	{
		case Item_Finite :
		{
			if (value < 1)
			{
				value = 1;
			}
			
			KvSetNum(h_KvItems, "count", value);
		}
		case Item_BuyOnly :
		{
		}
		default :
		{
			if (value < 0)
			{
				value = 0;
			}
			
			KvSetNum(h_KvItems, "duration", value);
		}
	}
	
	KvRewind(h_KvItems);
}

public ItemManager_GetItemId(Handle:plugin, numParams)
{
	decl String:item[SHOP_MAX_STRING_LENGTH], String:buffer[SHOP_MAX_STRING_LENGTH];
	
	new category_id = GetNativeCell(1);
	GetNativeString(2, item, sizeof(item));
	
	new item_id = -1;
	
	if (KvGotoFirstSubKey(h_KvItems))
	{
		do
		{
			if (KvGetNum(h_KvItems, "category_id", -1) != category_id) continue;
			
			KvGetString(h_KvItems, "item", buffer, sizeof(buffer));
			
			if (StrEqual(buffer, item, false))
			{
				KvGetSectionName(h_KvItems, buffer, sizeof(buffer));
				
				item_id = StringToInt(buffer);
				
				break;
			}
		}
		while (KvGotoNextKey(h_KvItems));
		
		KvRewind(h_KvItems);
	}
	
	return item_id;
}

public ItemManager_GetItemById(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bytes = 0;
	
	new size = GetNativeCell(3);
	decl String:item[size];
	
	KvGetString(h_KvItems, "item", item, size);
	SetNativeString(2, item, size, true, bytes);
	
	KvRewind(h_KvItems);
	
	return bytes;
}

public ItemManager_GetItemNameById(Handle:plugin, numParams)
{
	decl String:buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!KvJumpToKey(h_KvItems, buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	new bytes = 0;
	
	new size = GetNativeCell(3);
	decl String:item[size];
	
	KvGetString(h_KvItems, "name", item, size);
	SetNativeString(2, item, size, true, bytes);
	
	KvRewind(h_KvItems);
	
	return bytes;
}

public ItemManager_GetItemCanLuck(Handle:plugin, numParams)
{
	decl String:sItemId[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), sItemId, sizeof(sItemId));

	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", sItemId);
	}
	
	new bool:bResult = bool:KvGetNum(h_KvItems, "can_luck", 1);
	
	KvRewind(h_KvItems);

	return bResult;
}

public ItemManager_SetItemCanLuck(Handle:plugin, numParams)
{
	decl String:sItemId[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), sItemId, sizeof(sItemId));

	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", sItemId);
	}

	KvSetNum(h_KvItems, "can_luck", GetNativeCell(2));
	
	KvRewind(h_KvItems);
}

public ItemManager_GetItemCategoryIdNative(Handle:plugin, numParams)
{
	return ItemManager_GetItemCategoryId(GetNativeCell(1));
}

public ItemManager_IsItemExistsNative(Handle:plugin, numParams)
{
	return ItemManager_IsItemExists(GetNativeCell(1));
}

public ItemManager_GetItemTypeNative(Handle:plugin, numParams)
{
	return _:ItemManager_GetItemType(GetNativeCell(1));
}

public ItemManager_IsValidCategoryNative(Handle:plugin, numParams)
{
	return ItemManager_IsValidCategory(GetNativeCell(1));
}

public ItemManager_GetCategoryIdNative(Handle:plugin, numParams)
{
	decl String:category[SHOP_MAX_STRING_LENGTH];
	GetNativeString(1, category, sizeof(category));
	
	return ItemManager_GetCategoryId(category);
}

public ItemManager_GetCategoryByIdNative(Handle:plugin, numParams)
{
	new category_id = GetNativeCell(1);
	
	decl String:category[SHOP_MAX_STRING_LENGTH];
	new bool:result = ItemManager_GetCategoryById(category_id, category, sizeof(category));
	SetNativeString(2, category, GetNativeCell(3));
	
	return result;
}

public ItemManager_GetCategoryNameByIdNative(Handle:plugin, numParams)
{
	new category_id = GetNativeCell(1);
	
	decl String:category[SHOP_MAX_STRING_LENGTH];
	if(ItemManager_GetCategoryById(category_id, category, sizeof(category)))
	{
		decl Handle:trie;
		if (GetTrieValue(h_trieCategories, category, trie))
		{
			decl String:name[128];
			GetTrieString(trie, "name", name, sizeof(name));
			SetNativeString(2, name, GetNativeCell(3));
			return true;
		}
	}
	
	return false;
}

public ItemManager_FillArrayByItemsNative(Handle:plugin, numParams)
{
	new Handle:h_Array = GetNativeCell(1);
	if (!IsValidHandle(h_Array))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Handle is invalid!");
	}
	ClearArray(h_Array);
	return ItemManager_FillArrayByItems(h_Array);
}

public ItemManager_FormatItemNative(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	decl String:error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	new item_id = GetNativeCell(2);
	
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	new ShopMenu:menu = GetNativeCell(3);
	if (menu == Menu_Inventory && !ClientHasItemEx(client, sItemId))
	{
		return false;
	}
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return false;
	}
	
	new category_id = KvGetNum(h_KvItems, "category_id");
	
	decl String:display[SHOP_MAX_STRING_LENGTH], String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	GetArrayString(h_arCategories, category_id, category, sizeof(category));
	
	new Handle:h_plugin = Handle:KvGetNum(h_KvItems, "plugin");
	
	KvGetString(h_KvItems, "name", display, sizeof(display));
	new Function:callback_display = Function:KvGetNum(h_KvItems, "callback_display", _:INVALID_FUNCTION);
	
	KvRewind(h_KvItems);
	
	ItemManager_OnItemDisplay(h_plugin, callback_display, client, category_id, category, item_id, item, (menu == Menu_Inventory) ? Menu_Inventory : Menu_Buy, _, display, display, sizeof(display));
	
	SetNativeString(4, display, GetNativeCell(5));
	
	return true;
}

bool:ItemManager_GetCanLuck(item_id)
{
	decl String:sItemId[SHOP_MAX_STRING_LENGTH], bool:bResult;
	IntToString(item_id, sItemId, sizeof(sItemId));

	if (KvJumpToKey(h_KvItems, sItemId))
	{
		bResult = bool:(KvGetNum(h_KvItems, "can_luck", 1));
	}

	KvRewind(h_KvItems);

	return bResult;
}

bool:ItemManager_FillCategories(Handle:menu, source_client, bool:inventory = false)
{
	decl String:category[SHOP_MAX_STRING_LENGTH], String:display[128], String:buffer[SHOP_MAX_STRING_LENGTH], String:description[SHOP_MAX_STRING_LENGTH],
	Handle:trie, Handle:array, Handle:hCategoriesArray, any:tmp[CAT_MAX], String:sCatId[16], iSize, x, i, index;
	
	new bool:result = false;
	
	hCategoriesArray = CloneArray(h_arCategories);
	
	if(g_hSortArray != INVALID_HANDLE)
	{
		iSize = GetArraySize(g_hSortArray);
		if(iSize)
		{
			x = 0;
			for(i = 0; i < iSize; ++i)
			{
				GetArrayString(g_hSortArray, i, category, sizeof(category));
				index = FindStringInArray(hCategoriesArray, category);
				if(index != -1 && index != x)
				{
					SwapArrayItems(hCategoriesArray, index, x);

					++x;
				}
			}
		}
	}

	iSize = GetArraySize(hCategoriesArray);
	for (i = 0; i < iSize; ++i)
	{
		GetArrayString(hCategoriesArray, i, category, sizeof(category));
		index = FindStringInArray(h_arCategories, category);
		if (!GetTrieValue(h_trieCategories, category, trie)) continue;
		if (inventory)
		{
			x = GetClientCategorySize(source_client, index);
			if (x < 1)
			{
				continue;
			}
		}
		else
		{
			x = 0;
		}

		GetTrieValue(trie, "plugin_array", array);
		
		new bool:should_display = true, any:on_display[2] = {INVALID_FUNCTION, ...}, any:on_desc[2] = {INVALID_FUNCTION, ...};
		for (new s = 0; s < GetArraySize(array); s++)
		{
			GetArrayArray(array, s, tmp);
			
			if (tmp[CAT_SHOULD] != INVALID_FUNCTION)
			{
				Call_StartFunction(tmp[CAT_PLUGIN], tmp[CAT_SHOULD]);
				Call_PushCell(source_client);
				Call_PushCell(i);
				Call_PushString(category);
				Call_Finish(should_display);
				if (!should_display)
				{
					break;
				}
			}
			if (on_display[0] == INVALID_FUNCTION)
			{
				on_display[0] = tmp[CAT_PLUGIN];
				on_display[1] = tmp[CAT_DISPLAY];
			}
			if (on_desc[0] == INVALID_FUNCTION)
			{
				on_desc[0] = tmp[CAT_PLUGIN];
				on_desc[1] = tmp[CAT_DESC];
			}
			
			if (!inventory)
			{
				x += tmp[CAT_SIZE];
			}
		}
		if (!should_display)
		{
			continue;
		}
		
		GetTrieString(trie, "name", buffer, sizeof(buffer));
		ItemManager_OnCategoryDisplay(on_display[0], on_display[1], source_client, index, category, buffer, display, sizeof(display));
		
		description[0] = '\0';
		GetTrieString(trie, "description", buffer, sizeof(buffer));
		ItemManager_OnCategoryDescription(on_desc[0], on_desc[1], source_client, index, category, buffer, description, sizeof(description));
		
		if (description[0])
		{
			Format(display, sizeof(display), "%s (%i)\n%s\n", display, x, description);
		}
		else
		{
			Format(display, sizeof(display), "%s (%i)\n", display, x);
		}
		
		IntToString(index, sCatId, sizeof(sCatId));
		AddMenuItem(menu, sCatId, display);
		result = true;
	}
	
	CloseHandle(hCategoriesArray);
	
	return result;
}

bool:ItemManager_GetCategoryDisplay(category_id, source_client, String:buffer[], maxlength)
{
	decl Handle:trie, Handle:array, any:tmp[CAT_MAX], String:category[SHOP_MAX_STRING_LENGTH];
	
	GetArrayString(h_arCategories, category_id, category, sizeof(category));
	if (!GetTrieValue(h_trieCategories, category, trie))
	{
		return false;
	}
	GetTrieValue(trie, "plugin_array", array);
	
	new any:on_display[2] = {INVALID_FUNCTION, ...};
	for (new s = 0; s < GetArraySize(array); s++)
	{
		GetArrayArray(array, s, tmp);
		
		if (on_display[0] == INVALID_FUNCTION)
		{
			on_display[0] = tmp[CAT_PLUGIN];
			on_display[1] = tmp[CAT_DISPLAY];
		}
	}
	
	GetTrieString(trie, "name", buffer, maxlength);
	ItemManager_OnCategoryDisplay(on_display[0], on_display[1], source_client, category_id, category, buffer, buffer, maxlength);
	
	return true;
}

bool:ItemManager_GetItemDisplay(item_id, source_client, String:buffer[], maxlength)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return false;
	}
	
	new category_id = KvGetNum(h_KvItems, "category_id");
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin");
	
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	
	GetArrayString(h_arCategories, category_id, category, sizeof(category));
	KvGetString(h_KvItems, "item", item, sizeof(item));
	KvGetString(h_KvItems, "name", buffer, maxlength);
	new Function:callback_display = Function:KvGetNum(h_KvItems, "callback_display", _:INVALID_FUNCTION);
	KvRewind(h_KvItems);
	
	ItemManager_OnItemDisplay(plugin, callback_display, source_client, category_id, category, item_id, item, Menu_Buy, _, buffer, buffer, maxlength);
	
	return true;
}

bool:ItemManager_FillItemsOfCategory(Handle:menu, client, source_client, category_id, bool:inventory = false)
{
	new bool:result = false;
	if (KvGotoFirstSubKey(h_KvItems))
	{
		decl String:sItemId[16], String:display[SHOP_MAX_STRING_LENGTH], String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
		GetArrayString(h_arCategories, category_id, category, sizeof(category));
		do
		{
			if (KvGetNum(h_KvItems, "category_id", -1) != category_id || !KvGetSectionName(h_KvItems, sItemId, sizeof(sItemId)) || (inventory && !ClientHasItemEx(client, sItemId)))
			{
				continue;
			}
			
			KvGetString(h_KvItems, "item", item, sizeof(item));
			
			new item_id = StringToInt(sItemId);
			
			new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin");
			
			KvGetString(h_KvItems, "name", display, sizeof(display));
			new Function:callback_display = Function:KvGetNum(h_KvItems, "callback_display", _:INVALID_FUNCTION);
			new Function:callback_should = Function:KvGetNum(h_KvItems, "callback_should", _:INVALID_FUNCTION);
			
			KvRewind(h_KvItems);
			
			if (!ItemManger_OnItemShouldDisplay(plugin, callback_should, source_client, category_id, category, item_id, item, inventory ? Menu_Inventory : Menu_Buy)) continue;
			
			new bool:disabled = false;
			if (!ItemManager_OnItemDisplay(plugin, callback_display, source_client, category_id, category, item_id, item, inventory ? Menu_Inventory : Menu_Buy, disabled, display, display, sizeof(display)))
			{
				disabled = false;
			}
			
			KvJumpToKey(h_KvItems, sItemId);
			
			AddMenuItem(menu, sItemId, display, disabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			
			result = true;
		}
		while (KvGotoNextKey(h_KvItems));
		
		KvRewind(h_KvItems);
	}
	
	return result;
}

Handle:ItemManager_CreateItemPanelInfo(source_client, item_id, ShopMenu:menu_act)
{
	new Handle:panel;
	
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return panel;
	}
	
	new category_id = KvGetNum(h_KvItems, "category_id");
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin");
	
	decl String:buffer[256], String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	
	GetArrayString(h_arCategories, category_id, category, sizeof(category));
	KvGetString(h_KvItems, "item", item, sizeof(item));
	KvGetString(h_KvItems, "name", buffer, sizeof(buffer));
	new Function:callback = Function:KvGetNum(h_KvItems, "callback_display", _:INVALID_FUNCTION);
	
	KvRewind(h_KvItems);
	
	ItemManager_OnItemDisplay(plugin, callback, source_client, category_id, category, item_id, item, menu_act, _, buffer, buffer, sizeof(buffer));
	
	OnItemDisplay(source_client, menu_act, category_id, item_id, buffer, buffer, sizeof(buffer));
	
	KvJumpToKey(h_KvItems, sItemId);
	
	panel = CreatePanel();
	DrawPanelText(panel, buffer);
	
	SetGlobalTransTarget(source_client);
	/*switch (ItemType:KvGetNum(h_KvItems, "type", _:Item_None))
	{
		case Item_None :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %t", "Type", "None");
		}
		case Item_Finite :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %t", "Type", "Finite");
		}
		case Item_Togglable :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %t", "Type", "Togglable");
		}
		case Item_BuyOnly :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %t", "Type", "BuyOnly");
		}
	}
	DrawPanelText(panel, buffer);*/
	
	new price = KvGetNum(h_KvItems, "price");
	new sell_price = KvGetNum(h_KvItems, "sell_price");
	
	if (price < 1)
	{
		FormatEx(buffer, sizeof(buffer), "%t: %t", "Price", "Free");
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t: %d", "Price", price);
	}
	DrawPanelText(panel, buffer);
	if (sell_price < 0)
	{
		FormatEx(buffer, sizeof(buffer), "%t: %t", "Sell Price", "Unsaleable");
	}
	else
	{
		FormatEx(buffer, sizeof(buffer), "%t: %d", "Sell Price", sell_price);
	}
	DrawPanelText(panel, buffer);
	
	switch (ItemType:KvGetNum(h_KvItems, "type", _:Item_None))
	{
		case Item_Finite :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %d", "Count", KvGetNum(h_KvItems, "count", 1));
			DrawPanelText(panel, buffer);
		}
		case Item_None, Item_Togglable :
		{
			new duration = KvGetNum(h_KvItems, "duration", 0);
			if (duration < 1)
			{
				FormatEx(buffer, sizeof(buffer), "%t: %t", "duration", "forever");
			}
			else
			{
				GetTimeFromStamp(buffer, sizeof(buffer), duration, source_client);
				Format(buffer, sizeof(buffer), "%t: %s", "duration", buffer);
			}
			DrawPanelText(panel, buffer);
		}
	}
	
	KvGetString(h_KvItems, "description", buffer, sizeof(buffer));
	callback = Function:KvGetNum(h_KvItems, "callback_description", _:INVALID_FUNCTION);
	
	KvRewind(h_KvItems);
	
	ItemManager_OnItemDescription(plugin, callback, source_client, category_id, category, item_id, item, menu_act, buffer, buffer, sizeof(buffer));
	OnItemDescription(source_client, menu_act, category_id, item_id, buffer, buffer, sizeof(buffer));
	
	TrimString(buffer);
	if (buffer[0])
	{
		DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		DrawPanelText(panel, buffer);
	}
	
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	return panel;
}

stock ItemManager_GetCategoryId(const String:category[])
{
	return FindStringInArray(h_arCategories, category);
}

stock bool:ItemManager_GetCategoryById(category_id, String:category[], maxlength)
{
	if (!ItemManager_IsValidCategory(category_id))
	{
		return false;
	}
	GetArrayString(h_arCategories, category_id, category, maxlength);
	return true;
}

stock bool:ItemManager_IsItemExists(item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_IsItemExistsEx(sItemId);
}

stock bool:ItemManager_IsItemExistsEx(const String:sItemId[])
{
	new bool:result = false;
	result = KvJumpToKey(h_KvItems, sItemId);
	KvRewind(h_KvItems);
	return result;
}

stock ItemManager_GetItemDuration(item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_GetItemDurationEx(sItemId);
}

ItemManager_GetItemDurationEx(const String:sItemId[])
{
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return 0;
	}
	
	new duration = KvGetNum(h_KvItems, "duration", 0);
	KvRewind(h_KvItems);
	
	return duration;
}

bool:ItemManager_GetItemInfoEx(const String:sItemId[], String:item[], maxlength, &category_id, &price, &sell_price, &count, &duration, &ItemType:type)
{
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return false;
	}
	
	KvGetString(h_KvItems, "item", item, maxlength);
	category_id = KvGetNum(h_KvItems, "category_id", -1);
	price = KvGetNum(h_KvItems, "price", 0);
	sell_price = KvGetNum(h_KvItems, "sell_price", -1);
	count = KvGetNum(h_KvItems, "count", 1);
	duration = KvGetNum(h_KvItems, "duration", 0);
	type = ItemType:KvGetNum(h_KvItems, "type", _:Item_None);
	
	KvRewind(h_KvItems);
	
	return true;
}

ItemManager_GetItemPriceEx(const String:sItemId[])
{
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return 0;
	}
	
	new result = KvGetNum(h_KvItems, "price", 0);
	
	KvRewind(h_KvItems);
	
	return result;
}

stock ItemManager_GetItemSellPriceEx(const String:sItemId[])
{
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return -1;
	}
	
	new result = KvGetNum(h_KvItems, "sell_price", -1);
	
	KvRewind(h_KvItems);
	
	return result;
}

stock ItemManager_GetItemCategoryId(item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_GetItemCategoryIdEx(sItemId);
}

stock ItemManager_GetItemCategoryIdEx(const String:sItemId[])
{
	new result = -1;
	if (KvJumpToKey(h_KvItems, sItemId))
	{
		result = KvGetNum(h_KvItems, "category_id", -1);
		KvRewind(h_KvItems);
	}
	return result;
}

stock ItemType:ItemManager_GetItemType(item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	new ItemType:type = Item_None;
	if (KvJumpToKey(h_KvItems, sItemId))
	{
		type = ItemType:KvGetNum(h_KvItems, "type", _:Item_None);
		KvRewind(h_KvItems);
	}
	return type;
}

stock ItemType:ItemManager_GetItemTypeEx(const String:sItemId[])
{
	new ItemType:type = Item_None;
	if (KvJumpToKey(h_KvItems, sItemId))
	{
		type = ItemType:KvGetNum(h_KvItems, "type", _:Item_None);
		KvRewind(h_KvItems);
	}
	return type;
}

ItemManager_FillArrayByItems(Handle:array)
{
	new num = 0;
	
	if (KvGotoFirstSubKey(h_KvItems))
	{
		decl String:sItemId[16];
		do
		{
			if (KvGetSectionName(h_KvItems, sItemId, sizeof(sItemId)))
			{
				PushArrayCell(array, StringToInt(sItemId));
				num++;
			}
		}
		while (KvGotoNextKey(h_KvItems));
		
		KvRewind(h_KvItems);
	}
	
	return num;
}

ItemManager_OnPlayerItemElapsed(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return;
	}
	
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE);
	if (plugin == INVALID_HANDLE)
	{
		return;
	}
	new Function:callback_elapse = Function:KvGetNum(h_KvItems, "callback_elapse", _:INVALID_FUNCTION);
	new Function:callback_use = Function:KvGetNum(h_KvItems, "callback_use", _:INVALID_FUNCTION);
	
	new category_id = KvGetNum(h_KvItems, "category_id", -1);
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	KvGetString(h_KvItems, "item", item, sizeof(item));
	
	KvRewind(h_KvItems);
	
	CallItemElapsedForward(client, category_id, category, item_id, item);
	
	if (callback_elapse != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback_elapse);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_Finish();
	}
	
	if (callback_use != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback_use);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_PushCell(true);
		Call_PushCell(true);
		Call_Finish();
	}
}

stock ItemManager_OnUseToggleCategory(client, category_id)
{
	if (!KvGotoFirstSubKey(h_KvItems))
	{
		return;
	}
	
	decl String:sItemId[16];
	decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
	do
	{
		if (KvGetNum(h_KvItems, "category_id", -1) != category_id || !KvGetSectionName(h_KvItems, sItemId, sizeof(sItemId)))
		{
			continue;
		}
		
		ToggleItemCategoryOffEx(client, sItemId);
		
		new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE);
		new Function:callback = Function:KvGetNum(h_KvItems, "callback_use", _:INVALID_FUNCTION);
		
		if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
		{
			ItemManager_GetCategoryById(category_id, category, sizeof(category));
			KvGetString(h_KvItems, "item", item, sizeof(item));
			
			KvRewind(h_KvItems);
		
			Call_StartFunction(plugin, callback);
			Call_PushCell(client);
			Call_PushCell(category_id);
			Call_PushString(category);
			Call_PushCell(StringToInt(sItemId));
			Call_PushString(item);
			Call_PushCell(true);
			Call_PushCell(true);
			Call_Finish();
			
			KvJumpToKey(h_KvItems, sItemId);
		}
	}
	while (KvGotoNextKey(h_KvItems));
	
	KvRewind(h_KvItems);
}

stock ShopAction:ItemManager_OnUseToggleItem(client, item_id, bool:by_native = false, ToggleState:toggle = Toggle, bool:ignore = false)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_OnUseToggleItemEx(client, sItemId, by_native, toggle, ignore);
}

stock ShopAction:ItemManager_OnUseToggleItemEx(client, const String:sItemId[], bool:by_native = false, ToggleState:toggle = Toggle, bool:ignore = false)
{
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return Shop_Raw;
	}
	
	if (!ignore && ItemType:KvGetNum(h_KvItems, "type", _:Item_None) != Item_Togglable)
	{
		KvRewind(h_KvItems);
		return Shop_Raw;
	}
	
	new item_id = StringToInt(sItemId);
	
	new ShopAction:action = Shop_Raw;
	
	decl String:item[SHOP_MAX_STRING_LENGTH];
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE);
	new Function:callback = Function:KvGetNum(h_KvItems, "callback_use", _:INVALID_FUNCTION);
	new category_id = KvGetNum(h_KvItems, "category_id", -1);
	
	KvGetString(h_KvItems, "item", item, sizeof(item));
	
	KvRewind(h_KvItems);
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		decl String:category[SHOP_MAX_STRING_LENGTH];
		ItemManager_GetCategoryById(category_id, category, sizeof(category));
		
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		if (by_native)
		{
			switch (toggle)
			{
				case Toggle :
				{
					Call_PushCell(IsItemToggledEx(client, sItemId));
				}
				case Toggle_On :
				{
					Call_PushCell(false);
				}
				case Toggle_Off :
				{
					Call_PushCell(true);
				}
			}
		}
		else
		{
			Call_PushCell(IsItemToggledEx(client, sItemId));
		}
		Call_PushCell(false);
		Call_Finish(action);
	}
	
	return action;
}

ItemManager_SetupPreview(client, item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	ItemManager_SetupPreviewEx(client, sItemId);
}

bool:ItemManager_CanPreview(item_id)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return false;
	}
	
	new bool:result = bool:(Function:KvGetNum(h_KvItems, "callback_preview", _:INVALID_FUNCTION) != INVALID_FUNCTION);
	
	KvRewind(h_KvItems);
	
	return result;
}

ItemManager_SetupPreviewEx(client, const String:sItemId[])
{
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return;
	}
	
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE);
	new Function:callback = Function:KvGetNum(h_KvItems, "callback_preview", _:INVALID_FUNCTION);
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		new category_id = KvGetNum(h_KvItems, "category_id", -1);
		
		decl String:category[SHOP_MAX_STRING_LENGTH], String:item[SHOP_MAX_STRING_LENGTH];
		ItemManager_GetCategoryById(category_id, category, sizeof(category));
		KvGetString(h_KvItems, "item", item, sizeof(item));
		
		KvRewind(h_KvItems);
		
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(StringToInt(sItemId));
		Call_PushString(item);
		Call_Finish();
	}
	
	KvRewind(h_KvItems);
}

bool:ItemManager_OnItemBuyEx(client, category_id, const String:category[], item_id, const String:item[], ItemType:type, price, sell_price, value)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return false;
	}
	
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE);
	new Function:callback = Function:KvGetNum(h_KvItems, "callback_buy", _:INVALID_FUNCTION);
	
	KvRewind(h_KvItems);
	
	new bool:result = true;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_PushCell(type);
		Call_PushCell(price);
		Call_PushCell(sell_price);
		Call_PushCell(value);
		Call_Finish(result);
	}
	
	return result;
}

bool:ItemManager_OnItemSellEx(client, category_id, const String:category[], item_id, const String:item[], ItemType:type, sell_price)
{
	decl String:sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	if (!KvJumpToKey(h_KvItems, sItemId))
	{
		return false;
	}
	
	new Handle:plugin = Handle:KvGetNum(h_KvItems, "plugin", _:INVALID_HANDLE);
	new Function:callback = Function:KvGetNum(h_KvItems, "callback_sell", _:INVALID_FUNCTION);
	
	KvRewind(h_KvItems);
	
	new bool:result = true;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_PushCell(type);
		Call_PushCell(sell_price);
		Call_Finish(result);
	}
	
	return result;
}

bool:ItemManger_OnItemShouldDisplay(Handle:plugin, Function:callback, client, category_id, const String:category[], item_id, const String:item[], ShopMenu:menu)
{
	new bool:result = true;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_PushCell(menu);
		Call_Finish(result);
	}
	
	return result;
}

bool:ItemManager_OnItemDisplay(Handle:plugin, Function:callback, client, category_id, const String:category[], item_id, const String:item[], ShopMenu:menu, &bool:disabled = false, const String:name[], String:buffer[], maxlen)
{
	new bool:result = false;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_PushCell(menu);
		Call_PushCellRef(disabled);
		Call_PushString(name);
		Call_PushStringEx(buffer, maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(maxlen);
		Call_Finish(result);
	}
	
	if (!result)
	{
		strcopy(buffer, maxlen, name);
	}
	
	return result;
}

bool:ItemManager_OnItemDescription(Handle:plugin, Function:callback, client, category_id, const String:category[], item_id, const String:item[], ShopMenu:menu, const String:description[], String:buffer[], maxlen)
{
	new bool:result = false;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_PushCell(menu);
		Call_PushString(description);
		Call_PushStringEx(buffer, maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(maxlen);
		Call_Finish(result);
	}
	
	if (!result)
	{
		strcopy(buffer, maxlen, description);
	}
	
	return result;
}

bool:ItemManager_OnCategoryDisplay(Handle:plugin, Function:callback, client, category_id, const String:category[], const String:name[], String:category_buffer[], category_maxlen)
{
	new bool:result = false;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushString(name);
		Call_PushStringEx(category_buffer, category_maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(category_maxlen);
		Call_Finish(result);
	}
	
	if (!result)
	{
		strcopy(category_buffer, category_maxlen, name);
	}
	
	return result;
}

bool:ItemManager_OnCategoryDescription(Handle:plugin, Function:callback, client, category_id, const String:category[], const String:desc[], String:desc_buffer[], desc_maxlen)
{
	new bool:result = false;
	
	if (plugin != INVALID_HANDLE && callback != INVALID_FUNCTION)
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushString(desc);
		Call_PushStringEx(desc_buffer, desc_maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(desc_maxlen);
		Call_Finish(result);
	}
	
	if (!result)
	{
		strcopy(desc_buffer, desc_maxlen, desc);
	}
	
	return result;
}

bool:ItemManager_IsValidCategory(category_id)
{
	if (category_id < 0 || category_id >= GetArraySize(h_arCategories))
	{
		return false;
	}
	
	return true;
}