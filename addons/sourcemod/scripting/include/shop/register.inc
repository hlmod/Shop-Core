typedef Shop_CategoryDisplayCallback = function bool (int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen);
typedef Shop_CategoryDescriptionCallback = function bool (int client, CategoryId category_id, const char[] category, const char[] description, char[] buffer, int maxlen);
typedef Shop_CategoryShouldDisplayCallback = function bool (int client, CategoryId category_id, const char[] category);
typedef Shop_CategorySelectCallback = function bool (int client, CategoryId category_id, const char[] category, ShopMenu menu);

typeset Shop_ItemUseToggleCallback
{
	function ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item);
	function ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed);
}
typedef Shop_ItemRegister = function void (CategoryId category_id, const char[] category, const char[] item, ItemId item_id);
typedef Shop_ItemCommon = function void(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item);
typedef Shop_ItemShouldDisplayCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu);
typedef Shop_ItemDisplayCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen);
typedef Shop_ItemDescriptionCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, const char[] description, char[] buffer, int maxlen);

typeset Shop_ItemBuyCallback
{
	function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int price, int sell_price, int value);
	function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int price, int sell_price, int value, int gold_price, int gold_sell_price);
}

typeset Shop_ItemSellCallback
{
	function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price);
	function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price, int gold_sell_price);
}

/**
 *	Called when category registered at first time
 *  That means only once per unique name
 *	
 *	@param category_id		CategoryId of category
 *	@param name				Unique name of category
 *	
 *	@noreturn
*/
forward void Shop_OnCategoryRegistered(CategoryId category_id, const char[] name);

/**
 *	Registers new category id
 *	
 *	@param category				Category unique name
 *	@param name					Default category display name
 *	@param description			Default category description
 *	@param cat_display			Callback called on category being displayed
 *	@param cat_desc				Callback called on category's description being displayed
 *	@param cat_should			Callback called whether the category should be displayed to a player
 *	@param cat_select			Callback called when a player is trying to select the category
 *	
 *	@return Category id of the category
*/
native CategoryId Shop_RegisterCategory(const char[] category, const char[] name, const char[] description, 
								Shop_CategoryDisplayCallback cat_display=INVALID_FUNCTION, 
								Shop_CategoryDescriptionCallback cat_desc=INVALID_FUNCTION,
								Shop_CategoryShouldDisplayCallback cat_should=INVALID_FUNCTION,
								Shop_CategorySelectCallback cat_select=INVALID_FUNCTION);

/**
 *	Starts an item to register
 *	
 *	@param category_id			Category id to register an item for
 *	@param item					Item unique name
 *	
 *	@return true to success, false otherwise
*/
native bool Shop_StartItem(CategoryId category_id, const char[] item);

/**
 *	Sets the item information
 *	
 *	@param name					Default display name
 *	@param description			Default description
 *	@param price				Item price. Can not be lower than sell_price (on gold version can be lower and -1 for disable price by gold)
 *	@param sell_price			Item sell price. 0 to make item free and -1 to make it unsaleable by credits. Can not be higher than price
 *	@param type					Item type. See ItemType enum
 *	@param value				Sets count if the item type is finite and sets duration if the item is togglable or non-togglable
 *	@param gold_price			Item price. Can be -1 to make in unbuyable by gold
 *	@param gold_sell_price		Item sell price. 0 to make item free by gold price and -1 to disable sell by gold. Can not be higher than price
 *	
 *	@noreturn
*/
native void Shop_SetInfo(const char[] name, const char[] description, int price, int sell_price = -1, ItemType type, int value = 1, int gold_price = -1, int gold_sell_price = -1);

/**
 *	Sets the item luck chance.
 *	
 *	@param luck_chance			Luck chance to set. From 0 to 100. 0 can not be lucked and 100 is always lucked by the general chance set in cvar. Default item chance is 100
 *	
 *	@noreturn
*/
native void Shop_SetLuckChance(int luck_chance);

/**
 *	Sets the item callbacks
 *	
 *	@param register				Callback called when the item is registered
 *	@param use_toggle			Callback called when the item is being used
 *	@param should				Callback called when the item is being displayed. Here you can stop displaying the item
 *	@param display				Callback called when the item is being displayed. Here you can change item display name
 *	@param description			Callback called when the item description is being displayed. Here you can change item description
 *	@param preview				Callback called when the item is previewing
 *	@param buy					Callback called when the item is being bought
 *	@param sell					Callback called when the item is being sold
 *	@param elapse				Callback called when the item is elapsed
 *	
 *	@noreturn
*/
native void Shop_SetCallbacks(Shop_ItemRegister register=INVALID_FUNCTION,
							Shop_ItemUseToggleCallback use_toggle=INVALID_FUNCTION, 
							Shop_ItemShouldDisplayCallback should=INVALID_FUNCTION, 
							Shop_ItemDisplayCallback display=INVALID_FUNCTION, 
							Shop_ItemDescriptionCallback description=INVALID_FUNCTION, 
							Shop_ItemCommon preview=INVALID_FUNCTION,
							Shop_ItemBuyCallback buy=INVALID_FUNCTION,
							Shop_ItemSellCallback sell=INVALID_FUNCTION,
							Shop_ItemCommon elapse=INVALID_FUNCTION);

/**
 *	Allows to hide item in buy panel, givable only by native or admin panel
 *	
 *	@param state			true - hide, false - show
 *	
 *	@noreturn
*/
native void Shop_SetHide(bool state);

/**
 *	Sets item custom info
 *	
 *	@param info			Name of the key
 *	@param value			Value to set
 *	
 *	@noreturn
*/
native void Shop_SetCustomInfo(const char[] info, int value);

/**
 *	Sets item custom info
 *	
 *	@param info			Name of the key
 *	@param value			Value to set
 *	
 *	@noreturn
*/
native void Shop_SetCustomInfoFloat(const char[] info, float value);

/**
 *	Sets item custom info
 *	
 *	@param info			Name of the key
 *	@param value			Value to set
 *	
 *	@noreturn
*/
native void Shop_SetCustomInfoString(const char[] info, char[] value);

/**
 *	Copies sub keys of the given kv structure to the item
 *	
 *	@param info			Name of the key
 *	@param value			Value to set
 *	
 *	@noreturn
*/
native void Shop_KvCopySubKeysCustomInfo(KeyValues kv);

/**
 *	Copletes the item info structure and start to register. Can not be used before an item has been started to register
 *	
 *	@noparams
 *	
 *	@noreturn
*/
native void Shop_EndItem();
