// #pragma newdecls required;
ArrayList h_arCategories;
StringMap h_trieCategories;
KeyValues h_KvItems;

/**
 * For SM 1.10
 * Items
 */
stock DataPackPos ITEM_DATAPACKPOS_REGISTER				= view_as<DataPackPos>(0);
stock DataPackPos ITEM_DATAPACKPOS_USE 					= view_as<DataPackPos>(1);
stock DataPackPos ITEM_DATAPACKPOS_SHOULD_DISPLAY		= view_as<DataPackPos>(2);
stock DataPackPos ITEM_DATAPACKPOS_DISPLAY				= view_as<DataPackPos>(3);
stock DataPackPos ITEM_DATAPACKPOS_DESC					= view_as<DataPackPos>(4);
stock DataPackPos ITEM_DATAPACKPOS_COMMON				= view_as<DataPackPos>(5);
stock DataPackPos ITEM_DATAPACKPOS_BUY					= view_as<DataPackPos>(6);
stock DataPackPos ITEM_DATAPACKPOS_SELL					= view_as<DataPackPos>(7);
stock DataPackPos ITEM_DATAPACKPOS_ELAPSE				= view_as<DataPackPos>(8);
stock DataPackPos ITEM_DATAPACKPOS_SELECT				= view_as<DataPackPos>(9);

/**
 * For SM 1.10
 * Categories
 */
stock DataPackPos CATEGORY_DATAPACKPOS_PLUGIN			= view_as<DataPackPos>(0);
stock DataPackPos CATEGORY_DATAPACKPOS_DISPLAY			= view_as<DataPackPos>(1);
stock DataPackPos CATEGORY_DATAPACKPOS_DESCRIPTION		= view_as<DataPackPos>(2);
stock DataPackPos CATEGORY_DATAPACKPOS_SHOULD_DISPLAY	= view_as<DataPackPos>(3);
stock DataPackPos CATEGORY_DATAPACKPOS_SELECT			= view_as<DataPackPos>(4);
stock DataPackPos CATEGORY_DATAPACKPOS_ITEMSCOUNT		= view_as<DataPackPos>(5);

void ItemManager_CreateNatives()
{
	h_arCategories = new ArrayList(ByteCountToCells(SHOP_MAX_STRING_LENGTH));
	h_trieCategories = new StringMap();
	h_KvItems = new KeyValues("Items");
	
	CreateNative("Shop_RegisterCategory", ItemManager_RegisterCategory);
	CreateNative("Shop_StartItem", ItemManager_StartItem);
	CreateNative("Shop_SetInfo", ItemManager_SetInfo);
	CreateNative("Shop_SetLuckChance", ItemManager_SetLuckChance);
	CreateNative("Shop_SetCustomInfo", ItemManager_SetCustomInfo);
	CreateNative("Shop_SetCustomInfoFloat", ItemManager_SetCustomInfoFloat);
	CreateNative("Shop_SetCustomInfoString", ItemManager_SetCustomInfoString);
	CreateNative("Shop_KvCopySubKeysCustomInfo", ItemManager_KvCopySubKeysCustomInfo);
	CreateNative("Shop_SetCallbacks", ItemManager_SetCallbacks);
	CreateNative("Shop_SetHide", ItemManager_SetHide);
	CreateNative("Shop_EndItem", ItemManager_EndItem);

	CreateNative("Shop_UnregisterItem", ItemManager_UnregisterItem);
	
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

	CreateNative("Shop_GetItemLuckChance", ItemManager_GetItemLuckChance);
	CreateNative("Shop_SetItemLuckChance", ItemManager_SetItemLuckChance);

	CreateNative("Shop_GetItemId", ItemManager_GetItemId);
	CreateNative("Shop_GetItemById", ItemManager_GetItemById);
	CreateNative("Shop_GetItemNameById", ItemManager_GetItemNameById);

	CreateNative("Shop_GetItemHide", ItemManager_GetItemHide);
	CreateNative("Shop_SetItemHide", ItemManager_SetItemHide);

	CreateNative("Shop_GetItemType", ItemManager_GetItemTypeNative);

	CreateNative("Shop_GetItemCategoryId", ItemManager_GetItemCategoryIdNative);
	
	CreateNative("Shop_IsItemExists", ItemManager_IsItemExistsNative);
	
	CreateNative("Shop_IsValidCategory", ItemManager_IsValidCategoryNative);
	
	CreateNative("Shop_GetCategoryId", ItemManager_GetCategoryIdNative);
	CreateNative("Shop_GetCategoryById", ItemManager_GetCategoryByIdNative);
	CreateNative("Shop_GetCategoryNameById", ItemManager_GetCategoryNameByIdNative);
	
	CreateNative("Shop_FillArrayByItems", ItemManager_FillArrayByItemsNative);
	CreateNative("Shop_FormatItem", ItemManager_FormatItemNative);
}

void ItemManager_OnPluginStart()
{
	RegServerCmd("sm_items_dump", ItemManager_Dump);
}

public Action ItemManager_Dump(int argc)
{
	KeyValuesToFile(h_KvItems, "addons/items.txt");
}

void ItemManager_OnPluginEnd()
{
	ItemManager_UnregisterMe(null, true);
}

void ItemManager_UnregisterMe(Handle plugin = null, bool plugin_end = false)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	h_KvItems.Rewind();
	if (!h_KvItems.GotoFirstSubKey())
		return;

	do
	{
		if (plugin != null && view_as<Handle>(h_KvItems.GetNum("plugin", 0)) != plugin) continue;
			
		h_KvItems.GetSectionName(buffer, sizeof(buffer));
		int item_id = StringToInt(buffer);
		// LogToFileEx("addons/sourcemod/shop.log", "Removed module %d", item_id);
		OnItemUnregistered(item_id);
		
		DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
		if (dpCallback != null)
			delete dpCallback;
		
		/*h_KvItems.Rewind();
		h_KvItems.DeleteKey( buffer);
		if (!h_KvItems.GotoFirstSubKey())
		{
			break;
		}*/
		
		
		// I don't know why, but DeleteThis method skips one keyvalue
		while (h_KvItems.DeleteThis() == 1)
		{
			if (plugin != null && view_as<Handle>(h_KvItems.GetNum("plugin", 0)) != plugin) break;
			
			h_KvItems.GetSectionName(buffer, sizeof(buffer));
			item_id = StringToInt(buffer);
			// LogToFileEx("addons/sourcemod/shop.log", "Removed module %d", item_id);
			OnItemUnregistered(item_id);
			
			dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
			if (dpCallback != null)
				delete dpCallback;
		}
	} while (h_KvItems.GotoNextKey());
	h_KvItems.Rewind();
	
	if (!plugin_end)																				 
	{
		StringMap trie;
		ArrayList array;
		for (int category_id = 0; category_id < h_arCategories.Length; category_id++)
		{
			h_arCategories.GetString(category_id, buffer, sizeof(buffer));
			if (!h_trieCategories.GetValue(buffer, trie)) continue;
			
			trie.GetValue("plugin_array", array);
			// LogToFileEx("addons/sourcemod/shop.log", "Category name: %s", buffer);
			int index = array.FindValue(plugin);
			if (index == -1)
			{
				if (plugin == null)
				{
					DataPack dp;
					for (int j = 1; j < array.Length; j+=2)
					{
						dp = array.Get(j);
						delete dp;
					}
					
					delete array;
					delete trie;
					h_trieCategories.Remove(buffer);
				}
				continue;
			}
			// Remove plugin handle
			array.Erase(index);
			
			// Delete datapack in category
			DataPack dp = view_as<DataPack>(array.Get(index));
			delete dp;
			array.Erase(index); // to remove datapack
			
			char cName[24];
			GetPluginFilename(plugin, cName, sizeof(cName));
			// LogToFileEx("addons/sourcemod/shop.log", "[%s] Deleted %s", cName, buffer);
			
			if (!array.Length)
			{
				delete array;
				delete trie;
				
				h_trieCategories.Remove(buffer);
			}
		}
	}
}

public int ItemManager_RegisterCategory(Handle plugin, int numParams)
{
	char category[SHOP_MAX_STRING_LENGTH];
	StringMap trie;
	ArrayList array;
	
	GetNativeString(1, category, sizeof(category));
	TrimString(category);
	if (!category[0])
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No category specified!");
	}

	int index = h_arCategories.FindString(category);
	
	if (index == -1)
	{
		index = h_arCategories.PushString(category);
		Forward_OnCategoryRegistered(index, category);
	}
	
	if (h_trieCategories.GetValue(category, trie))
	{
		trie.GetValue("plugin_array", array);
		
		if (array.FindValue(plugin) != -1)
			return index;
	}
	else
	{
		trie = new StringMap();
		h_trieCategories.SetValue(category, trie);
		
		array = new ArrayList(1);
		
		char buffer[128];
		GetNativeString(2, buffer, sizeof(buffer));
		
		trie.SetValue("plugin_array", array);
		
		trie.SetString("name", buffer);
		GetNativeString(3, buffer, sizeof(buffer));
		
		trie.SetString("description", buffer);
	}
	
	DataPack dp = new DataPack();
	
	dp.WriteCell(plugin); // Handle of plugin that created category
	dp.WriteFunction(GetNativeFunction(4)); // Category display
	dp.WriteFunction(GetNativeFunction(5)); // Category description
	dp.WriteFunction(GetNativeFunction(6)); // Category should display
	dp.WriteFunction(GetNativeFunction(7)); // Category select
	dp.WriteCell(0); // Count of items in category
	
	array.Push(plugin);
	array.Push(dp);

	return index;
}

bool ItemManager_OnCategorySelect(int client, int category_id, ShopMenu menu)
{
	char category[SHOP_MAX_STRING_LENGTH];
	h_arCategories.GetString(category_id, category, sizeof(category));
	
	StringMap trie;
	ArrayList array;
	
	h_trieCategories.GetValue(category, trie);
	trie.GetValue("plugin_array", array);
	
	bool result = true;
	DataPack tmp = array.Get(1);// because on index 0 there are plugin handle
	if (tmp != null)
	{
		tmp.Reset(); // Deleting of Datapack in Shop_UnregisterMe()...
		
		Handle plugin = tmp.ReadCell();
		tmp.Position = CATEGORY_DATAPACKPOS_SELECT;
		
		Function func_Select = tmp.ReadFunction();
		if (IsCallValid(plugin, func_Select))
		{
			Call_StartFunction(plugin, func_Select);
			Call_PushCell(client);
			Call_PushCell(category_id);
			Call_PushString(category);
			Call_PushCell(menu);
			Call_Finish(result);
			
			if (!result)
				return false;
		}
	}
	
	return true;
}

int plugin_category_id = -1;
KeyValues plugin_kv;
ArrayList plugin_array;
char plugin_category[SHOP_MAX_STRING_LENGTH];
char plugin_item[SHOP_MAX_STRING_LENGTH];

public int ItemManager_StartItem(Handle plugin, int numParams)
{
	int category_id = GetNativeCell(1);
	
	if (!ItemManager_IsValidCategory(category_id))
		ThrowNativeError(SP_ERROR_NATIVE, "Category id %d is invalid", category_id);
	
	char item[SHOP_MAX_STRING_LENGTH];
	GetNativeString(2, item, sizeof(item));
	TrimString(item);
	if (!item[0])
		ThrowNativeError(SP_ERROR_NATIVE, "No item specified!");
	
	char buffer[SHOP_MAX_STRING_LENGTH];
	StringMap trie;
	ArrayList array;
	
	h_arCategories.GetString(category_id, buffer, sizeof(buffer));
	
	h_trieCategories.GetValue(buffer, trie);
	trie.GetValue("plugin_array", array);
	
	if (array.FindValue(plugin) == -1)
		ThrowNativeError(SP_ERROR_NATIVE, "This plugin didn't register the category id %d", category_id);
	
	h_KvItems.Rewind();
	if (h_KvItems.GotoFirstSubKey())
	{
		do
		{
			if (h_KvItems.GetNum("category_id", -1) != category_id) continue;
			
			h_KvItems.GetString("item", buffer, sizeof(buffer));
			
			if (StrEqual(buffer, item, false))
			{
				h_KvItems.Rewind();
				
				ThrowNativeError(SP_ERROR_NATIVE, "Item %s is already registered in the category id %d", item, category_id);
			}
		}
		while (h_KvItems.GotoNextKey());
		
		h_KvItems.Rewind();
	}
	
	plugin_category_id = category_id;
	h_arCategories.GetString(category_id, plugin_category, sizeof(plugin_category));
	strcopy(plugin_item, sizeof(plugin_item), item);
	
	plugin_kv = new KeyValues("ItemRegister");
	plugin_kv.SetNum("plugin", view_as<int>(plugin));
	plugin_kv.SetNum("category_id", category_id);
	plugin_kv.SetString("item", item);
	plugin_array = array;
	
	return true;
}

public int ItemManager_SetInfo(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	
	char buffer[128];
	
	GetNativeString(1, buffer, sizeof(buffer));
	plugin_kv.SetString("name", buffer);
	
	GetNativeString(2, buffer, sizeof(buffer));
	plugin_kv.SetString("description", buffer);
	
	int price = GetNativeCell(3);
	int sell_price = GetNativeCell(4);
	
	if (price < 0) price = 0;
	
	if (sell_price < -1) sell_price = -1;
	else if (sell_price > price) sell_price = price;
	
	ItemType type = GetNativeCell(5);
	
	plugin_kv.SetNum("price", price);
	plugin_kv.SetNum("type", view_as<int>(type));
	
	int value = GetNativeCell(6);
	
	if (type == Item_Finite || type == Item_BuyOnly)
	{
		if (value < 1) value = 1;
		plugin_kv.SetNum("sell_price", sell_price);
		plugin_kv.SetNum("count", value);
	}
	else
	{
		if (value < 0) value = 0;
		plugin_kv.SetNum("sell_price", sell_price);
		plugin_kv.SetNum("duration", value);
		plugin_kv.SetNum("count", 1);
	}
	
	plugin_kv.SetNum("hide", 0);
}

public int ItemManager_SetLuckChance(Handle plugin, int numParams)
{
	if (plugin_kv == null)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	}
	
	int iLuckChance = GetNativeCell(1);
	if (iLuckChance < 0)
	{
		iLuckChance = 0;
	}
	else if (iLuckChance > 100)
	{
		iLuckChance = 100;
	}
	plugin_kv.SetNum("luck_chance", iLuckChance);
}

public int ItemManager_SetCustomInfo(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	
	char info[SHOP_MAX_STRING_LENGTH];
	GetNativeString(1, info, sizeof(info));
	
	plugin_kv.JumpToKey("CustomInfo", true);
	plugin_kv.SetNum(info, GetNativeCell(2));
	plugin_kv.GoBack();
}

public int ItemManager_SetCustomInfoFloat(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	
	char info[SHOP_MAX_STRING_LENGTH];
	GetNativeString(1, info, sizeof(info));
	
	plugin_kv.JumpToKey("CustomInfo", true);
	plugin_kv.SetFloat(info, GetNativeCell(2));
	plugin_kv.GoBack();
}

public int ItemManager_SetCustomInfoString(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	
	char info[SHOP_MAX_STRING_LENGTH], value[256];
	GetNativeString(1, info, sizeof(info));
	GetNativeString(2, value, sizeof(value));
	
	plugin_kv.JumpToKey("CustomInfo", true);
	plugin_kv.SetString(info, value);
	plugin_kv.GoBack();
}

public int ItemManager_KvCopySubKeysCustomInfo(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	
	KeyValues kv = GetNativeCell(1);
	kv.GetNum("___SD__");
	
	plugin_kv.JumpToKey("CustomInfo", true);
	KvCopySubkeys(kv, plugin_kv);
	plugin_kv.GoBack();
}

public int ItemManager_SetCallbacks(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");

	DataPack hPack = new DataPack();
	hPack.WriteFunction(GetNativeFunction(1));
	hPack.WriteFunction(GetNativeFunction(2));
	hPack.WriteFunction(GetNativeFunction(3));
	hPack.WriteFunction(GetNativeFunction(4));
	hPack.WriteFunction(GetNativeFunction(5));
	hPack.WriteFunction(GetNativeFunction(6));
	hPack.WriteFunction(GetNativeFunction(7));
	hPack.WriteFunction(GetNativeFunction(8));
	hPack.WriteFunction(GetNativeFunction(9));
	if(numParams > 9)
		hPack.WriteFunction(GetNativeFunction(10));
	else 
		hPack.WriteFunction(INVALID_FUNCTION);

	plugin_kv.SetNum("callbacks", view_as<int>(hPack));
}

public int ItemManager_SetHide(Handle plugin, int numParams)
{
	if (plugin_kv == null)
		ThrowNativeError(SP_ERROR_NATIVE, "No item is being registered");
	
	plugin_kv.SetNum("hide", GetNativeCell(1));
}

public int ItemManager_EndItem(Handle plugin, int numParams)
{
	ItemType type = view_as<ItemType>(plugin_kv.GetNum("type", 0)); // by default ItemType_None
	
	DataPack dpCallback = view_as<DataPack>(plugin_kv.GetNum("callbacks", 0));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_USE;
	Function func_use = dpCallback.ReadFunction();
	if (type != Item_None && type != Item_BuyOnly && func_use == INVALID_FUNCTION)
	{
		delete plugin_kv;
		
		plugin_category_id = -1;
		plugin_kv = null;
		plugin_array = null;
		plugin_category[0] = '\0';
		plugin_item[0] = '\0';
		
		ThrowNativeError(SP_ERROR_NATIVE, "Using item type other than none, ItemUseToggle callback must to be set");
	}
	
	dpCallback.Position = ITEM_DATAPACKPOS_BUY;
	Function func_buy = dpCallback.ReadFunction();
	if (type == Item_BuyOnly && func_buy == INVALID_FUNCTION)
	{
		delete plugin_kv;
		
		plugin_category_id = -1;
		plugin_kv = null;
		plugin_array = null;
		plugin_category[0] = '\0';
		plugin_item[0] = '\0';
		
		ThrowNativeError(SP_ERROR_NATIVE, "Using item type BuyOnly, OnBuy callback must to be set");
	}
	
	dpCallback.Position = ITEM_DATAPACKPOS_REGISTER;
	Function func_register = dpCallback.ReadFunction();
	
	DataPack dp = new DataPack();
	dp.WriteCell(plugin_category_id);
	dp.WriteCell(view_as<Handle>(plugin_kv.GetNum("plugin", 0)));
	dp.WriteFunction(func_register);
	dp.WriteString(plugin_category);
	dp.WriteString(plugin_item);
	dp.WriteCell(plugin_kv);
	dp.WriteCell(plugin_array);
	dp.WriteCell(0);
	
	plugin_kv.Rewind();
	
	char s_Query[256];
	h_db.Format(s_Query, sizeof(s_Query), "SELECT `id` FROM `%sitems` WHERE `category` = '%s' AND `item` = '%s' LIMIT 1;", g_sDbPrefix, plugin_category, plugin_item);
	
	TQuery(ItemManager_OnItemRegistered, s_Query, dp);
	
	plugin_category_id = -1;
	plugin_kv = null;
	plugin_array = null;
	plugin_category[0] = '\0';
	plugin_item[0] = '\0';
}

public int ItemManager_UnregisterItem(Handle plugin, int numParams)
{
	char item[SHOP_MAX_STRING_LENGTH];
	int item_id = GetNativeCell(1);

	Format(item, sizeof(item), "%i", item_id);

	h_KvItems.Rewind();
	if(!h_KvItems.JumpToKey(item))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", item);

	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
	if(dpCallback != null)
		delete dpCallback;
	
	OnItemUnregistered(item_id);
	
	h_KvItems.DeleteThis();
	h_KvItems.Rewind();
}

public int ItemManager_OnItemRegistered(Handle owner, Handle hndl, const char[] error, DataPack dp)
{
	char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	
	dp.Reset();
	int category_id = dp.ReadCell();
	Handle plugin = view_as<Handle>(dp.ReadCell());
	Function callback = dp.ReadFunction();
	dp.ReadString(category, sizeof(category));
	dp.ReadString(item, sizeof(item));
	KeyValues kv = view_as<KeyValues>(dp.ReadCell());
	ArrayList array = view_as<ArrayList>(dp.ReadCell());
	int iTry = dp.ReadCell();
	
	if (!iTry)
	{
		if (!IsPluginValid(plugin))
		{
			delete kv;
			delete dp;
			
			return;
		}
	}
	
	if (error[0])
	{
		LogError("ItemManager_OnItemRegistered: %s", error);
	}
	if (hndl == null)
	{
		delete dp;
		return;
	}
	
	int id;
	switch (iTry)
	{
		case 0:
		{
			if (!SQL_FetchRow(hndl))
			{
				char s_Query[256];
				h_db.Format(s_Query, sizeof(s_Query), "INSERT INTO `%sitems` (`category`, `item`) VALUES ('%s', '%s');", g_sDbPrefix, category, item);
				
				dp.Reset(true);
				dp.WriteCell(category_id);
				dp.WriteCell(plugin);
				dp.WriteFunction(callback);
				dp.WriteString(category);
				dp.WriteString(item);
				dp.WriteCell(kv);
				dp.WriteCell(array);
				dp.WriteCell(1);
				
				TQuery(ItemManager_OnItemRegistered, s_Query, dp);
				
				return;
			}
			
			id = SQL_FetchInt(hndl, 0);
		}
		case 1:
		{
			id = SQL_GetInsertId(hndl);
		}
	}
	
	delete dp;
	
	char buffer[16];
	IntToString(id, buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	h_KvItems.JumpToKey(buffer, true);
	KvCopySubkeys(kv, h_KvItems);
	h_KvItems.Rewind();
	
	delete kv;
	
	int index = array.FindValue(plugin);
	DataPack tmp = view_as<DataPack>(array.Get(index+1));
	if (tmp != null)
	{
		tmp.Reset();
		
		DataPack new_tmp = new DataPack();
		
		new_tmp.WriteCell(tmp.ReadCell());
		new_tmp.WriteFunction(tmp.ReadFunction());
		new_tmp.WriteFunction(tmp.ReadFunction());
		new_tmp.WriteFunction(tmp.ReadFunction());
		new_tmp.WriteFunction(tmp.ReadFunction());
		new_tmp.WriteCell(tmp.ReadCell() + 1);
		
		delete tmp;
		
		array.Set(index+1, new_tmp);
	}
	
	OnItemRegistered(id);
	
	if (IsCallValid(plugin, callback))
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushString(item);
		Call_PushCell(id);
		Call_Finish();
	}
}

public int ItemManager_GetItemCustomInfo(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));

	if (!h_KvItems.JumpToKey(buffer))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);

	int result = GetNativeCell(3);

	if (h_KvItems.JumpToKey("CustomInfo"))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		result = h_KvItems.GetNum(buffer, result);
	}

	h_KvItems.Rewind();

	return result;
}

public int ItemManager_SetItemCustomInfo(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	bool result = false;
	
	if (h_KvItems.JumpToKey("CustomInfo", true))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		h_KvItems.SetNum(buffer, GetNativeCell(3));
		
		result = true;
	}
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_KvCopySubKeysItemCustomInfo(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	
	bool result = false;
	
	KeyValues origin_kv = GetNativeCell(2);
	origin_kv.GetNum("___SD__");
	
	if (h_KvItems.JumpToKey("CustomInfo", true))
	{
		KvCopySubkeys(origin_kv, h_KvItems);
		
		result = true;
	}
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_GetItemCustomInfoFloat(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	
	float result = GetNativeCell(3);
	
	if (h_KvItems.JumpToKey("CustomInfo"))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		result = h_KvItems.GetFloat(buffer, result);
	}
	
	h_KvItems.Rewind();
	
	return view_as<int>(result);
}

public int ItemManager_SetItemCustomInfoFloat(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	
	bool result = false;
	
	if (h_KvItems.JumpToKey("CustomInfo", true))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		h_KvItems.SetFloat(buffer, GetNativeCell(3));
		
		result = true;
	}
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_GetItemCustomInfoString(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	int bytes = 0;
	
	if (h_KvItems.JumpToKey("CustomInfo"))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		
		int size = GetNativeCell(4);
		
		char[] defvalue = new char[size];
		GetNativeString(5, defvalue, size);
		h_KvItems.GetString(buffer, defvalue, size, defvalue);
		
		SetNativeString(3, defvalue, size, true, bytes);
	}
	
	h_KvItems.Rewind();
	
	return bytes;
}

public int ItemManager_SetItemCustomInfoString(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	bool result = false;
	
	if (h_KvItems.JumpToKey("CustomInfo", true))
	{
		GetNativeString(2, buffer, sizeof(buffer));
		
		char value[256];
		GetNativeString(3, value, sizeof(value));
		h_KvItems.SetString(buffer, value);
		
		result = true;
	}
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_GetItemPrice(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	int result = h_KvItems.GetNum("price", 0);
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_SetItemPrice(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	int price = GetNativeCell(2);
	if (price < 0)
	{
		price = 0;
	}
	if (h_KvItems.GetNum("sell_price", -1) > price)
	{
		h_KvItems.SetNum("sell_price", price);
	}
	
	h_KvItems.SetNum("price", price);
	h_KvItems.Rewind();
}

public int ItemManager_GetItemSellPrice(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	int result = h_KvItems.GetNum("sell_price", -1);
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_SetItemSellPrice(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	int price = h_KvItems.GetNum("price");
	int sell_price = GetNativeCell(2);
	if (sell_price > price)
	{
		sell_price = price;
	}
	else if (sell_price < -1)
	{
		sell_price = -1;
	}
	h_KvItems.SetNum("sell_price", sell_price);
	
	h_KvItems.Rewind();
}

public int ItemManager_GetItemValue(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	ItemType type = view_as<ItemType>(h_KvItems.GetNum("type", 1)); // by default ItemType_Finite
	
	int result = 0;
	
	if (type == Item_Finite || type == Item_BuyOnly)
	{
		result = h_KvItems.GetNum("count", 1);
	}
	else
	{
		result = h_KvItems.GetNum("duration", 0);
	}
	
	h_KvItems.Rewind();
	
	return result;
}

public int ItemManager_SetItemValue(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	ItemType type = view_as<ItemType>(h_KvItems.GetNum("type", 1)); // by default ItemType_Finite
	
	int value = GetNativeCell(2);
	
	switch (type)
	{
		case Item_Finite :
		{
			if (value < 1)
			{
				value = 1;
			}
			
			h_KvItems.SetNum("count", value);
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
			
			h_KvItems.SetNum("duration", value);
		}
	}
	
	h_KvItems.Rewind();
}

public int ItemManager_GetItemLuckChance(Handle plugin, int numParams)
{
	return ItemManager_GetLuckChance(GetNativeCell(1));
}

public int ItemManager_SetItemLuckChance(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	}
	
	int iLuckChance = GetNativeCell(2);
	if (iLuckChance < 0)
	{
		iLuckChance = 0;
	}
	else if (iLuckChance > 100)
	{
		iLuckChance = 100;
	}
	
	h_KvItems.SetNum("luck_chance", iLuckChance);
	h_KvItems.Rewind();
}

public int ItemManager_GetItemId(Handle plugin, int numParams)
{
	char item[SHOP_MAX_STRING_LENGTH], buffer[SHOP_MAX_STRING_LENGTH];
	
	int category_id = GetNativeCell(1);
	GetNativeString(2, item, sizeof(item));
	
	int item_id = view_as<int>(INVALID_ITEM);
	
	h_KvItems.Rewind();
	if (h_KvItems.GotoFirstSubKey())
	{
		do
		{
			if (h_KvItems.GetNum("category_id", -1) != category_id) continue;
			
			h_KvItems.GetString("item", buffer, sizeof(buffer));
			
			if (StrEqual(buffer, item, false))
			{
				h_KvItems.GetSectionName(buffer, sizeof(buffer));
				
				item_id = StringToInt(buffer);
				
				break;
			}
		}
		while (h_KvItems.GotoNextKey());
		
		h_KvItems.Rewind();
	}
	
	return item_id;
}

public int ItemManager_GetItemById(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	
	int bytes = 0;
	
	int size = GetNativeCell(3);
	char[] item = new char[size];
	
	h_KvItems.GetString("item", item, size);
	SetNativeString(2, item, size, true, bytes);
	
	h_KvItems.Rewind();
	
	return bytes;
}

public int ItemManager_GetItemTypeNative(Handle plugin, int numParams)
{
	return view_as<int>(ItemManager_GetItemType(GetNativeCell(1)));
}

public int ItemManager_GetItemNameById(Handle plugin, int numParams)
{
	char buffer[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), buffer, sizeof(buffer));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(buffer))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", buffer);
	
	int bytes = 0;
	
	int size = GetNativeCell(3);
	char[] item = new char[size];
	
	h_KvItems.GetString("name", item, size);
	SetNativeString(2, item, size, true, bytes);
	
	h_KvItems.Rewind();
	
	return bytes;
}

public int ItemManager_GetItemHide(Handle plugin, int numParams)
{
	char sItemId[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), sItemId, sizeof(sItemId));

	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", sItemId);

	return ItemManager_GetItemHideEx(sItemId);
}

bool ItemManager_GetItemHideEx(const char[] sItemId)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId)) return false;
	
	bool bResult = view_as<bool>(h_KvItems.GetNum("hide", 0));
	h_KvItems.Rewind();
	return bResult;
}

public int ItemManager_SetItemHide(Handle plugin, int numParams)
{
	char sItemId[SHOP_MAX_STRING_LENGTH];
	IntToString(GetNativeCell(1), sItemId, sizeof(sItemId));

	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		ThrowNativeError(SP_ERROR_NATIVE, "Item id %s is invalid", sItemId);

	h_KvItems.SetNum("hide", GetNativeCell(2));
	
	h_KvItems.Rewind();
}

public int ItemManager_GetItemCategoryIdNative(Handle plugin, int numParams)
{
	return ItemManager_GetItemCategoryId(GetNativeCell(1));
}

public int ItemManager_IsItemExistsNative(Handle plugin, int numParams)
{
	return ItemManager_IsItemExists(GetNativeCell(1));
}

public int ItemManager_IsValidCategoryNative(Handle plugin, int numParams)
{
	return ItemManager_IsValidCategory(GetNativeCell(1));
}

public int ItemManager_GetCategoryIdNative(Handle plugin, int numParams)
{
	char category[SHOP_MAX_STRING_LENGTH];
	GetNativeString(1, category, sizeof(category));
	
	return ItemManager_GetCategoryId(category);
}

public int ItemManager_GetCategoryByIdNative(Handle plugin, int numParams)
{
	int category_id = GetNativeCell(1);
	
	char category[SHOP_MAX_STRING_LENGTH];
	bool result = ItemManager_GetCategoryById(category_id, category, sizeof(category));
	SetNativeString(2, category, GetNativeCell(3));
	
	return result;
}

public int ItemManager_GetCategoryNameByIdNative(Handle plugin, int numParams)
{
	int category_id = GetNativeCell(1);
	
	char category[SHOP_MAX_STRING_LENGTH];
	if(ItemManager_GetCategoryById(category_id, category, sizeof(category)))
	{
		StringMap trie;
		if (h_trieCategories.GetValue(category, trie))
		{
			char name[128];
			trie.GetString("name", name, sizeof(name));
			SetNativeString(2, name, GetNativeCell(3));
			return true;
		}
	}
	
	return false;
}

public int ItemManager_FillArrayByItemsNative(Handle plugin, int numParams)
{
	ArrayList h_Array = GetNativeCell(1);
	if (h_Array == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Handle is invalid!");
	
	ClearArray(h_Array);
	return ItemManager_FillArrayByItems(h_Array);
}

public int ItemManager_FormatItemNative(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	
	int item_id = GetNativeCell(2);
	
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	ShopMenu menu = GetNativeCell(3);
	if (menu == Menu_Inventory && !ClientHasItemEx(client, sItemId))
	{
		return false;
	}
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
	{
		return false;
	}
	
	int category_id = h_KvItems.GetNum("category_id");
	
	char display[SHOP_MAX_STRING_LENGTH], category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	h_arCategories.GetString(category_id, category, sizeof(category));
	
	Handle h_plugin = view_as<Handle>(h_KvItems.GetNum("plugin"));
	
	h_KvItems.GetString("name", display, sizeof(display));
	
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Can't format, callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_DISPLAY;
	Function callback_display = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	ItemManager_OnItemDisplay(h_plugin, callback_display, client, category_id, category, item_id, item, (menu == Menu_Inventory) ? Menu_Inventory : Menu_Buy, _, display, display, sizeof(display));
	
	SetNativeString(4, display, GetNativeCell(5));
	
	return true;
}

bool ItemManager_FillCategories(Menu menu, int source_client, bool inventory = false, bool showAll = false)
{
	char category[SHOP_MAX_STRING_LENGTH], display[128], buffer[SHOP_MAX_STRING_LENGTH], description[SHOP_MAX_STRING_LENGTH];
	StringMap trie;
	ArrayList array, hCategoriesArray;
	char sCatId[16];
	int iSize, x, i, index;
	ShopMenu shop_menu = (showAll ? Menu_Inventory : Menu_Buy);
	
	bool result = false;
	
	hCategoriesArray = h_arCategories.Clone();
	
	if(g_hSortArray != null)
	{
		iSize = g_hSortArray.Length;
		if(iSize)
		{
			x = 0;
			for(i = 0; i < iSize; ++i)
			{
				g_hSortArray.GetString(i, category, sizeof(category));
				index = hCategoriesArray.FindString(category);
				if(index != -1 && index != x)
				{
					hCategoriesArray.SwapAt(index, x);

					++x;
				}
			}
		}
	}

	iSize = hCategoriesArray.Length;
	for (i = 0; i < iSize; ++i)
	{
		hCategoriesArray.GetString(i, category, sizeof(category));
		index = h_arCategories.FindString(category);
		if (!h_trieCategories.GetValue(category, trie)) continue;
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

		trie.GetValue("plugin_array", array);
		bool should_display = true;
		Handle on_display_hndl = null, on_desc_hndl = null;
		Function on_display_func = INVALID_FUNCTION, on_desc_func = INVALID_FUNCTION;
		
		for (int j = 1; j < array.Length; j+=2)
		{
			DataPack dp = array.Get(j);
			
			if (dp != null)
			{
				dp.Reset();
				
				Handle cat_plugin = dp.ReadCell(); // Handle of plugin that created category
				Function func_display = dp.ReadFunction(); // Category display
				Function func_desc = dp.ReadFunction(); // Category description
				Function func_should = dp.ReadFunction(); // Category should display
				dp.Position = CATEGORY_DATAPACKPOS_ITEMSCOUNT; // to skip Category select
				int icat_size = dp.ReadCell(); // Real count of items in category
				
				if (!showAll)
				{
					/* Temporary modification */
					// Count of not hidden items
					ArrayList items = ItemManager_GetItemIdArrayFromPlugin(cat_plugin);
					icat_size = 0;
					char cItemid[5];
					for (int k = 0; k < items.Length; k++)
					{
						IntToString(items.Get(k), cItemid, sizeof(cItemid));
						if (!ItemManager_GetItemHideEx(cItemid))
							icat_size++;
					}
					
					delete items;
				}
			
				if (IsCallValid(cat_plugin, func_should))
				{
					Call_StartFunction(cat_plugin, func_should);
					Call_PushCell(source_client);
					Call_PushCell(i);
					Call_PushString(category);
					Call_PushCell(shop_menu);
					Call_Finish(should_display);
					if (!should_display)
					{
						break;
					}
				}
				if (on_display_hndl == null)
				{
					on_display_hndl = cat_plugin;
					on_display_func = func_display;
				}
				if (on_desc_hndl == null)
				{
					on_desc_hndl = cat_plugin;
					on_desc_func = func_desc;
				}
				
				if (!inventory)
				{
					x += icat_size;
				}
			}
		}
		// Hide category if 0 items available
		if (!should_display || x == 0)
		{
			continue;
		}
		
		trie.GetString("name", buffer, sizeof(buffer));
		ItemManager_OnCategoryDisplay(on_display_hndl, on_display_func, source_client, index, category, buffer, display, sizeof(display), shop_menu);
		
		description[0] = '\0';
		trie.GetString("description", buffer, sizeof(buffer));
		ItemManager_OnCategoryDescription(on_desc_hndl, on_desc_func, source_client, index, category, buffer, description, sizeof(description), shop_menu);
		
		if (showAll || g_hHideCategoriesItemsCount.BoolValue)
		{
			Format(display, sizeof(display), "%s (%i)", display, x);
		}
		
		if (description[0])
		{
			Format(display, sizeof(display), "%s\n%s\n", display, description);
		}
		
		IntToString(index, sCatId, sizeof(sCatId));
		menu.AddItem(sCatId, display);
		result = true;
	}
	
	delete hCategoriesArray;
	
	return result;
}

bool ItemManager_GetCategoryDisplay(int category_id, int source_client, char[] buffer, int maxlength)
{
	StringMap trie;
	ArrayList array;
	char category[SHOP_MAX_STRING_LENGTH];
	
	h_arCategories.GetString(category_id, category, sizeof(category));
	if (!h_trieCategories.GetValue(category, trie))
	{
		return false;
	}
	trie.GetValue("plugin_array", array);
	
	Handle on_display_hndl = null;
	Function on_display_func = INVALID_FUNCTION;
	DataPack dp = array.Get(1); // Because we need datapack to get
	
	if (dp != null)
	{
		// TODO make this easier via DataPack.Position
		dp.Reset();
		
		Handle cat_plugin = dp.ReadCell(); // Handle of plugin that created category
		Function func_display = dp.ReadFunction(); // Category display
	
		if (on_display_hndl == null)
		{
			on_display_hndl = cat_plugin;
			on_display_func = func_display;
		}
	}
	
	trie.GetString("name", buffer, maxlength);
	ItemManager_OnCategoryDisplay(on_display_hndl, on_display_func, source_client, category_id, category, buffer, buffer, maxlength, iClMenuId[source_client]);
	
	return true;
}

bool ItemManager_GetItemDisplay(int item_id, int source_client, char[] buffer, int maxlength)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
	{
		return false;
	}
	
	int category_id = h_KvItems.GetNum("category_id");
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin"));
	
	char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	
	h_arCategories.GetString(category_id, category, sizeof(category));
	h_KvItems.GetString("item", item, sizeof(item));
	h_KvItems.GetString("name", buffer, maxlength);
	
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_DISPLAY;
	Function callback_display = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	ItemManager_OnItemDisplay(plugin, callback_display, source_client, category_id, category, item_id, item, Menu_Buy, _, buffer, buffer, maxlength);
	
	return true;
}

bool ItemManager_FillItemsOfCategory(Menu menu, int client, int source_client, int category_id, bool inventory = false, bool showAll = false)
{
	bool result = false;
	h_KvItems.Rewind();
	if (h_KvItems.GotoFirstSubKey())
	{
		char sItemId[16], display[SHOP_MAX_STRING_LENGTH], category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
		h_arCategories.GetString(category_id, category, sizeof(category));
		do
		{
			bool isHidden = view_as<bool>(h_KvItems.GetNum("hide", 0));
			if (h_KvItems.GetNum("category_id", -1) != category_id || !h_KvItems.GetSectionName(sItemId, sizeof(sItemId)) || (inventory && !ClientHasItemEx(client, sItemId)))
			{
				continue;
			}
			
			if (!inventory && !showAll && isHidden) continue;
			
			h_KvItems.GetString("item", item, sizeof(item));
			
			int item_id = StringToInt(sItemId);
			
			Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin"));
			
			h_KvItems.GetString("name", display, sizeof(display));
			
			DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
			if (dpCallback == null)
				ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
			
			dpCallback.Position = ITEM_DATAPACKPOS_DISPLAY;
			Function callback_display = dpCallback.ReadFunction();
			
			dpCallback.Position = ITEM_DATAPACKPOS_SHOULD_DISPLAY;
			Function callback_should = dpCallback.ReadFunction();
			
			h_KvItems.Rewind();
			
			bool bShouldDisplay = ItemManager_OnItemShouldDisplay(plugin, callback_should, source_client, category_id, category, item_id, item, inventory ? Menu_Inventory : Menu_Buy);
			
			bool disabled = false;
			if (!ItemManager_OnItemDisplay(plugin, callback_display, source_client, category_id, category, item_id, item, inventory ? Menu_Inventory : Menu_Buy, disabled, display, display, sizeof(display)))
			{
				disabled = false;
			}
			
			h_KvItems.JumpToKey(sItemId);
			
			if (bShouldDisplay)
				menu.AddItem(sItemId, display, disabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			
			result = true;
		}
		while (h_KvItems.GotoNextKey());
		
		h_KvItems.Rewind();
	}
	
	return result;
}

Panel ItemManager_CreateItemPanelInfo(int source_client, int item_id, ShopMenu menu_act)
{
	Panel panel;
	
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
	{
		return panel;
	}
	
	int category_id = h_KvItems.GetNum("category_id");
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin"));
	
	char buffer[256], category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	
	h_arCategories.GetString(category_id, category, sizeof(category));
	h_KvItems.GetString("item", item, sizeof(item));
	h_KvItems.GetString("name", buffer, sizeof(buffer));
	
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_SELECT;
	Function callback = dpCallback.ReadFunction();
	
	if(!ItemManager_OnItemSelect(plugin, callback, source_client, category_id, category, item_id, item, menu_act))
	{
		return panel;
	}

	dpCallback.Position = ITEM_DATAPACKPOS_DISPLAY;
	callback = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	ItemManager_OnItemDisplay(plugin, callback, source_client, category_id, category, item_id, item, menu_act, _, buffer, buffer, sizeof(buffer));
	
	OnItemDisplay(source_client, menu_act, category_id, item_id, buffer, buffer, sizeof(buffer));
	
	h_KvItems.JumpToKey(sItemId);
	
	panel = new Panel();
	panel.DrawText(buffer);
	
	SetGlobalTransTarget(source_client);
	
	int price = h_KvItems.GetNum("price");
	int sell_price = h_KvItems.GetNum("sell_price");
	
	if (price < 1)
		FormatEx(buffer, sizeof(buffer), "%t: %t", "Price", "Free");
	else
		FormatEx(buffer, sizeof(buffer), "%t: %d", "Price", price);
	panel.DrawText(buffer);
	if (sell_price < 0)
		FormatEx(buffer, sizeof(buffer), "%t: %t", "Sell Price", "Unsaleable");
	else
		FormatEx(buffer, sizeof(buffer), "%t: %d", "Sell Price", sell_price);
	panel.DrawText(buffer);
	
	switch (view_as<ItemType>(h_KvItems.GetNum("type", 0))) // by default it will be ItemType_None
	{
		case Item_Finite :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %d", "Count", h_KvItems.GetNum("count", 1));
			panel.DrawText(buffer);
		}
		case Item_None, Item_Togglable :
		{
			int duration = h_KvItems.GetNum("duration", 0);
			if (duration < 1)
				FormatEx(buffer, sizeof(buffer), "%t: %t", "duration", "forever");
			else
			{
				GetTimeFromStamp(buffer, sizeof(buffer), duration, source_client);
				Format(buffer, sizeof(buffer), "%t: %s", "duration", buffer);
			}
			panel.DrawText(buffer);
		}
	}
	
	h_KvItems.GetString("description", buffer, sizeof(buffer));
	
	dpCallback.Position = ITEM_DATAPACKPOS_DESC;
	callback = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	ItemManager_OnItemDescription(plugin, callback, source_client, category_id, category, item_id, item, menu_act, buffer, buffer, sizeof(buffer));
	OnItemDescription(source_client, menu_act, category_id, item_id, buffer, buffer, sizeof(buffer));
	
	TrimString(buffer);
	if (buffer[0])
	{
		panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
		panel.DrawText(buffer);
	}
	
	panel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	return panel;
}

Panel ItemManager_ConfirmItemPanelInfo(int source_client, int item_id, ShopMenu menu_act, bool isBuy)
{
	Panel panel;
	
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
	{
		return panel;
	}
	
	int category_id = h_KvItems.GetNum("category_id");
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin"));
	
	char buffer[256], category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	
	h_arCategories.GetString(category_id, category, sizeof(category));
	h_KvItems.GetString("item", item, sizeof(item));
	h_KvItems.GetString("name", buffer, sizeof(buffer));
	
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_SELECT;
	Function callback = dpCallback.ReadFunction();
	
	if(!ItemManager_OnItemSelect(plugin, callback, source_client, category_id, category, item_id, item, menu_act))
	{
		return panel;
	}

	dpCallback.Position = ITEM_DATAPACKPOS_DISPLAY;
	callback = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	ItemManager_OnItemDisplay(plugin, callback, source_client, category_id, category, item_id, item, menu_act, _, buffer, buffer, sizeof(buffer));
	
	OnItemDisplay(source_client, menu_act, category_id, item_id, buffer, buffer, sizeof(buffer));
	
	h_KvItems.JumpToKey(sItemId);
	
	panel = new Panel();
	panel.DrawText(buffer);
	
	SetGlobalTransTarget(source_client);
	
	int price = h_KvItems.GetNum("price");
	int sell_price = h_KvItems.GetNum("sell_price");
	
	if(isBuy)
	{
		if (price < 1)
			FormatEx(buffer, sizeof(buffer), "%t: %t", "Price", "Free");
		else
			FormatEx(buffer, sizeof(buffer), "%t: %d", "Price", price);
		panel.DrawText(buffer);
	}
	
	else
	{
		if(sell_price > 0)
		{
			FormatEx(buffer, sizeof(buffer), "%t: %d", "Sell Price", sell_price);
			panel.DrawText(buffer);
		}
	}
	
	switch (view_as<ItemType>(h_KvItems.GetNum("type", 0))) // by default it will be ItemType_None
	{
		case Item_Finite :
		{
			FormatEx(buffer, sizeof(buffer), "%t: %d", "Count", h_KvItems.GetNum("count", 1));
			panel.DrawText(buffer);
		}
		case Item_None, Item_Togglable :
		{
			int duration = h_KvItems.GetNum("duration", 0);
			if (duration < 1)
				FormatEx(buffer, sizeof(buffer), "%t: %t", "duration", "forever");
			else
			{
				GetTimeFromStamp(buffer, sizeof(buffer), duration, source_client);
				Format(buffer, sizeof(buffer), "%t: %s", "duration", buffer);
			}
			panel.DrawText(buffer);
		}
	}	
	return panel;
}

stock int ItemManager_GetCategoryId(const char[] category)
{
	return h_arCategories.FindString(category);
}

stock bool ItemManager_GetCategoryById(int category_id, char[] category, int maxlength)
{
	if (!ItemManager_IsValidCategory(category_id))
	{
		return false;
	}
	h_arCategories.GetString(category_id, category, maxlength);
	return true;
}

stock bool ItemManager_IsItemExists(int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_IsItemExistsEx(sItemId);
}

stock bool ItemManager_IsItemExistsEx(const char[] sItemId)
{
	bool result = false;
	h_KvItems.Rewind();
	result = h_KvItems.JumpToKey(sItemId);
	h_KvItems.Rewind();
	return result;
}

stock int ItemManager_GetItemDuration(int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_GetItemDurationEx(sItemId);
}

int ItemManager_GetItemDurationEx(const char[] sItemId)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return 0;
	
	int duration = h_KvItems.GetNum("duration", 0);
	h_KvItems.Rewind();
	
	return duration;
}

bool ItemManager_GetItemInfoEx(const char[] sItemId, char[] item, int maxlength, int &category_id, int &price, int &sell_price, int &count, int &duration, ItemType &type)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
	{
		return false;
	}
	
	h_KvItems.GetString("item", item, maxlength);
	category_id = h_KvItems.GetNum("category_id", -1);
	price = h_KvItems.GetNum("price", 0);
	sell_price = h_KvItems.GetNum("sell_price", -1);
	count = h_KvItems.GetNum("count", 1);
	duration = h_KvItems.GetNum("duration", 0);
	type = view_as<ItemType>(h_KvItems.GetNum("type", 0));
	
	h_KvItems.Rewind();
	
	return true;
}

int ItemManager_GetLuckChance(int item_id)
{
	char sItemid[16];
	IntToString(item_id, sItemid, sizeof(sItemid));
	
	return ItemManager_GetLuckChanceEx(sItemid);
}

int ItemManager_GetLuckChanceEx(const char[] sItemId)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
	{
		return 0;
	}
	
	int result = h_KvItems.GetNum("luck_chance", 100);
	
	h_KvItems.Rewind();
	
	return result;
}


int ItemManager_GetItemPriceEx(const char[] sItemId)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return 0;
	
	int result = h_KvItems.GetNum("price", 0);
	
	h_KvItems.Rewind();
	
	return result;
}

stock int ItemManager_GetItemSellPriceEx(const char[] sItemId)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return -1;
	
	int result = h_KvItems.GetNum("sell_price", -1);
	
	h_KvItems.Rewind();
	
	return result;
}

stock int ItemManager_GetItemCategoryId(int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_GetItemCategoryIdEx(sItemId);
}

stock int ItemManager_GetItemCategoryIdEx(const char[] sItemId)
{
	int result = -1;
	h_KvItems.Rewind();
	if (h_KvItems.JumpToKey(sItemId))
	{
		result = h_KvItems.GetNum("category_id", -1);
		h_KvItems.Rewind();
	}
	return result;
}

stock ItemType ItemManager_GetItemType(int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	ItemType type = Item_None;
	h_KvItems.Rewind();
	if (h_KvItems.JumpToKey(sItemId))
	{
		type = view_as<ItemType>(h_KvItems.GetNum("type", 0)); // by default ItemType_None
		h_KvItems.Rewind();
	}
	return type;
}

stock ItemType ItemManager_GetItemTypeEx(const char[] sItemId)
{
	ItemType type = Item_None;
	h_KvItems.Rewind();
	if (h_KvItems.JumpToKey(sItemId))
	{
		type = view_as<ItemType>(h_KvItems.GetNum("type", 0)); // default as ItemType_None
		h_KvItems.Rewind();
	}
	return type;
}

int ItemManager_FillArrayByItems(ArrayList array)
{
	int num = 0;
	
	h_KvItems.Rewind();
	if (h_KvItems.GotoFirstSubKey())
	{
		char sItemId[16];
		do
		{
			if (h_KvItems.GetSectionName(sItemId, sizeof(sItemId)))
			{
				array.Push(StringToInt(sItemId));
				num++;
			}
		}
		while (h_KvItems.GotoNextKey());
		
		h_KvItems.Rewind();
	}
	
	return num;
}

void ItemManager_OnPlayerItemElapsed(int client, int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return;
	
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin", 0));
	if (plugin == null)
		return;
	 
	DataPack dpCallback = dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_ELAPSE;
	Function callback_elapse = dpCallback.ReadFunction();
	
	dpCallback.Position = ITEM_DATAPACKPOS_USE;
	Function callback_use = dpCallback.ReadFunction();
	
	int category_id = h_KvItems.GetNum("category_id", -1);
	char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	ItemManager_GetCategoryById(category_id, category, sizeof(category));
	h_KvItems.GetString("item", item, sizeof(item));
	
	h_KvItems.Rewind();
	
	CallItemElapsedForward(client, category_id, category, item_id, item);
	
	if (IsCallValid(plugin, callback_elapse))
	{
		Call_StartFunction(plugin, callback_elapse);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(item_id);
		Call_PushString(item);
		Call_Finish();
	}
	
	if (IsCallValid(plugin, callback_use))
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

stock void ItemManager_OnUseToggleCategory(int client, int category_id)
{
	h_KvItems.Rewind();
	if (!h_KvItems.GotoFirstSubKey())
		return;
	
	char sItemId[16], category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
	do
	{
		if (h_KvItems.GetNum("category_id", -1) != category_id || !h_KvItems.GetSectionName(sItemId, sizeof(sItemId)))
			continue;
		
		ToggleItemCategoryOffEx(client, sItemId);
		
		Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin", 0));
		
		DataPack dpCallback = dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
		if (dpCallback == null)
			ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
		
		dpCallback.Position = ITEM_DATAPACKPOS_USE;
		Function callback = dpCallback.ReadFunction();
		
		if (IsCallValid(plugin, callback))
		{
			ItemManager_GetCategoryById(category_id, category, sizeof(category));
			h_KvItems.GetString("item", item, sizeof(item));
			
			h_KvItems.Rewind();
		
			Call_StartFunction(plugin, callback);
			Call_PushCell(client);
			Call_PushCell(category_id);
			Call_PushString(category);
			Call_PushCell(StringToInt(sItemId));
			Call_PushString(item);
			Call_PushCell(true);
			Call_PushCell(true);
			Call_Finish();
			
			h_KvItems.JumpToKey(sItemId);
		}
	}
	while (h_KvItems.GotoNextKey());
	
	h_KvItems.Rewind();
}

stock ShopAction ItemManager_OnUseToggleItem(int client, int item_id, bool by_native = false, ToggleState toggle = Toggle, bool ignore = false)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	return ItemManager_OnUseToggleItemEx(client, sItemId, by_native, toggle, ignore);
}

stock ShopAction ItemManager_OnUseToggleItemEx(int client, const char[] sItemId, bool by_native = false, ToggleState toggle = Toggle, bool ignore = false)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return Shop_Raw;
	
	if (!ignore && view_as<ItemType>(h_KvItems.GetNum("type", 0)) != Item_Togglable) // by default ItemType_None
	{
		h_KvItems.Rewind();
		return Shop_Raw;
	}
	
	int item_id = StringToInt(sItemId);
	
	ShopAction action = Shop_Raw;
	
	char item[SHOP_MAX_STRING_LENGTH];
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin", 0));
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_USE;
	Function callback = dpCallback.ReadFunction();
	
	int category_id = h_KvItems.GetNum("category_id", -1);
	
	h_KvItems.GetString("item", item, sizeof(item));
	
	h_KvItems.Rewind();
	
	if (IsCallValid(plugin, callback))
	{
		char category[SHOP_MAX_STRING_LENGTH];
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

void ItemManager_SetupPreview(int client, int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	ItemManager_SetupPreviewEx(client, sItemId);
}

bool ItemManager_CanPreview(int item_id)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return false;
	
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks", 0));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_COMMON;
	
	bool result = view_as<bool>(dpCallback.ReadFunction() != INVALID_FUNCTION);
	
	h_KvItems.Rewind();
	
	return result;
}

void ItemManager_SetupPreviewEx(int client, const char[] sItemId)
{
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return;
	
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin", 0));

	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_COMMON;
	Function callback = dpCallback.ReadFunction();
	
	if (IsCallValid(plugin, callback))
	{
		int category_id = h_KvItems.GetNum("category_id", -1);
		
		char category[SHOP_MAX_STRING_LENGTH], item[SHOP_MAX_STRING_LENGTH];
		ItemManager_GetCategoryById(category_id, category, sizeof(category));
		h_KvItems.GetString("item", item, sizeof(item));
		
		h_KvItems.Rewind();
		
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushCell(StringToInt(sItemId));
		Call_PushString(item);
		Call_Finish();
	}
	
	h_KvItems.Rewind();
}

bool ItemManager_OnItemBuyEx(int client, int category_id, const char[] category, int item_id, const char[] item, ItemType type, int price, int sell_price, int value)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return false;
		
	bool isHidden = view_as<bool>(h_KvItems.GetNum("hide", 0));
	if (isHidden) return false; // make hidden items unbuyable
	
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin", 0));
	
	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_BUY;
	Function callback = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	bool result = true;
	
	if (IsCallValid(plugin, callback))
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

bool ItemManager_OnItemSellEx(int client, int category_id, const char[] category, int item_id, const char[] item, ItemType type, int sell_price)
{
	char sItemId[16];
	IntToString(item_id, sItemId, sizeof(sItemId));
	
	h_KvItems.Rewind();
	if (!h_KvItems.JumpToKey(sItemId))
		return false;
	
	Handle plugin = view_as<Handle>(h_KvItems.GetNum("plugin", 0));

	DataPack dpCallback = view_as<DataPack>(h_KvItems.GetNum("callbacks"));
	if (dpCallback == null)
		ThrowNativeError(SP_ERROR_NATIVE, "Callbacks for this item not found");
	
	dpCallback.Position = ITEM_DATAPACKPOS_SELL;
	Function callback = dpCallback.ReadFunction();
	
	h_KvItems.Rewind();
	
	bool result = true;
	
	if (IsCallValid(plugin, callback))
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

bool ItemManager_OnItemShouldDisplay(Handle plugin, Function callback, int client, int category_id, const char[] category, int item_id, const char[] item, ShopMenu menu)
{
	bool result = true;
	
	if (IsCallValid(plugin, callback))
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

bool ItemManager_OnItemDisplay(Handle plugin, Function callback, int client, int category_id, const char[] category, int item_id, const char[] item, ShopMenu menu, bool &disabled = false, const char[] name, char[] buffer, int maxlen)
{
	bool result = false;
	
	if (IsCallValid(plugin, callback))
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

bool ItemManager_OnItemSelect(Handle plugin, Function callback, int client, int category_id, const char[] category, int item_id, const char[] item, ShopMenu menu)
{
	bool result = true;
	
	if (IsCallValid(plugin, callback))
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

bool ItemManager_OnItemDescription(Handle plugin, Function callback, int client, int category_id, const char[] category, int item_id, const char[] item, ShopMenu menu, const char[] description, char[] buffer, int maxlen)
{
	bool result = false;
	
	if (IsCallValid(plugin, callback))
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

bool ItemManager_OnCategoryDisplay(Handle plugin, Function callback, int client, int category_id, const char[] category, const char[] name, char[] category_buffer, int category_maxlen, ShopMenu menu)
{
	bool result = false;
	
	if (IsCallValid(plugin, callback))
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushString(name);
		Call_PushStringEx(category_buffer, category_maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(category_maxlen);
		Call_PushCell(menu);
		Call_Finish(result);
	}
	
	if (!result)
	{
		strcopy(category_buffer, category_maxlen, name);
	}
	
	return result;
}

bool ItemManager_OnCategoryDescription(Handle plugin, Function callback, int client, int category_id, const char[] category, const char[] desc, char[] desc_buffer, int desc_maxlen, ShopMenu menu)
{
	bool result = false;
	
	if (IsCallValid(plugin, callback))
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(client);
		Call_PushCell(category_id);
		Call_PushString(category);
		Call_PushString(desc);
		Call_PushStringEx(desc_buffer, desc_maxlen, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(desc_maxlen);
		Call_PushCell(menu);
		Call_Finish(result);
	}
	
	if (!result)
	{
		strcopy(desc_buffer, desc_maxlen, desc);
	}
	
	return result;
}

bool ItemManager_IsValidCategory(int category_id)
{
	if (category_id < 0 || category_id >= h_arCategories.Length)
	{
		return false;
	}
	
	return true;
}

ArrayList ItemManager_GetItemIdArrayFromPlugin(Handle plugin)
{
	if (plugin != null)
	{
		ArrayList array = new ArrayList(1);
		KeyValues kv = new KeyValues("kv");
		h_KvItems.Rewind();
		KvCopySubkeys(h_KvItems, kv);
		
		if (kv.GotoFirstSubKey())
		{
			char cSection[5];
			do
			{
				if (kv.GetSectionName(cSection, sizeof(cSection)))
				{
					if (plugin == view_as<Handle>(kv.GetNum("plugin", 0)))
						array.Push(StringToInt(cSection));
				}
			} while (kv.GotoNextKey());
		}
		
		delete kv;
		return array;
	}
	
	return null;
}
