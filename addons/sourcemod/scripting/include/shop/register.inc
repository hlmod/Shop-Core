typedef CategoryDisplayCallback = function bool (int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen);
typedef CategoryDescriptionCallback = function bool (int client, CategoryId category_id, const char[] category, const char[] description, char[] buffer, int maxlen);
typedef CategoryShouldDisplayCallback = function bool (int client, CategoryId category_id, const char[] category);
typedef CategorySelectCallback = function bool (int client, CategoryId category_id, const char[] category, ShopMenu menu);

typeset ItemUseToggleCallback
{
	function ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item);
	function ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed);
}
typedef ItemRegister = function void (CategoryId category_id, const char[] category, const char[] item, ItemId item_id);
typedef ItemCommon = function void(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item);
typedef ItemShouldDisplayCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu);
typedef ItemDisplayCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen);
typedef ItemDescriptionCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, const char[] description, char[] buffer, int maxlen);
typedef ItemBuyCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int price, int sell_price, int value, int gold_price, int gold_sell_price);
typedef ItemSellCallback = function bool (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price, int gold_sell_price);

/**
 *	Registers new category id
 *	-
 *	@param category				Category unique name
 *	@param name					Default category display name
 *	@param description			Default category description
 *	@param cat_display			Callback called on category being displayed
 *	@param cat_desc				Callback called on category's description being displayed
 *	@param cat_should			Callback called whether the category should be displayed to a player
 *	@param cat_select			Callback called when a player is trying to select the category
 *	-
 *	@return Category id of the category
*/
native CategoryId Shop_RegisterCategory(const char[] category, const char[] name, const char[] description, 
								CategoryDisplayCallback cat_display=INVALID_FUNCTION, 
								CategoryDescriptionCallback cat_desc=INVALID_FUNCTION,
								CategoryShouldDisplayCallback cat_should=INVALID_FUNCTION,
								CategorySelectCallback cat_select=INVALID_FUNCTION);

/**
 *	Starts an item to register
 *	-
 *	@param category_id			Category id to register an item for
 *	@param item					Item unique name
 *	-
 *	@return true to success, false otherwise
*/
native bool Shop_StartItem(CategoryId category_id, const char[] item);

/**
 *	Sets the item information
 *	-
 *	@param name					Default display name
 *	@param description			Default description
 *	@param price				Item price. Can not be lower than sell_price
 *	@param sell_price			Item sell price. 0 to make item free and -1 to make it unsaleable. Can not be higher than price
 *	@param type					Item type. See ItemType enum
 *	@param value				Sets count if the item type is finite and sets duration if the item is togglable or non-togglable
 *	@param gold_price			Item price. Can be -1 to make in unbuyable for gold
 *	@param gold_sell_price		Item sell price. 0 to make item free and -1 to make it unsaleable. Can not be higher than price
 *	-
 *	@noreturn
*/
native void Shop_SetInfo(const char[] name, const char[] description, int price, int sell_price = -1, ItemType type, int value = 1, int gold_price = -1, int gold_sell_price = -1);

/**
 *	Sets the item luck chance.
 *	-
 *	@param luck_chance			Luck chance to set. From 0 to 100. 0 can not be lucked and 100 is always lucked by the general chance set in cvar. Default item chance is 100
 *	-
 *	@noreturn
*/
native void Shop_SetLuckChance(int luck_chance);

/**
 *	Sets the item callbacks
 *	-
 *	@param register				Callback called when the item is registered
 *	@param use_toggle			Callback called when the item is being used
 *	@param should				Callback called when the item is being displayed. Here you can stop displaying the item
 *	@param display				Callback called when the item is being displayed. Here you can change item display name
 *	@param description			Callback called when the item description is being displayed. Here you can change item description
 *	@param preview				Callback called when the item is previewing
 *	@param buy					Callback called when the item is being bought
 *	@param sell					Callback called when the item is being sold
 *	@param elapse				Callback called when the item is elapsed
 *	-
 *	@noreturn
*/
native void Shop_SetCallbacks(ItemRegister register=INVALID_FUNCTION,
							ItemUseToggleCallback use_toggle=INVALID_FUNCTION, 
							ItemShouldDisplayCallback should=INVALID_FUNCTION, 
							ItemDisplayCallback display=INVALID_FUNCTION, 
							ItemDescriptionCallback description=INVALID_FUNCTION, 
							ItemCommon preview=INVALID_FUNCTION,
							ItemBuyCallback buy=INVALID_FUNCTION,
							ItemSellCallback sell=INVALID_FUNCTION,
							ItemCommon elapse=INVALID_FUNCTION);


/**
 *	Устанавливет возможность получения предмета в "Испытать удачу"
 *	-
 *	@param bCanLuck			true - можно, false - нет
 *	-
 *	@noreturn
*/
native void Shop_SetCanLuck(bool bCanLuck);

/**
 *	Позволяет скрыть предмет из списка покупок. Выдача только через админ-панель
 *	-
 *	@param state			true - спрятать, false - нет
 *	-
 *	@noreturn
*/
native void Shop_SetHide(bool state);

/**
 *	Sets item custom info
 *	-
 *	@param info			Name of the key
 *	@param value			Value to set
 *	-
 *	@noreturn
*/
native void Shop_SetCustomInfo(const char[] info, int value);

/**
 *	Sets item custom info
 *	-
 *	@param info			Name of the key
 *	@param value			Value to set
 *	-
 *	@noreturn
*/
native void Shop_SetCustomInfoFloat(const char[] info, float value);

/**
 *	Sets item custom info
 *	-
 *	@param info			Name of the key
 *	@param value			Value to set
 *	-
 *	@noreturn
*/
native void Shop_SetCustomInfoString(const char[] info, char[] value);

/**
 *	Copies sub keys of the given kv structure to the item
 *	-
 *	@param info			Name of the key
 *	@param value			Value to set
 *	-
 *	@noreturn
*/
native void Shop_KvCopySubKeysCustomInfo(KeyValues kv);

/**
 *	Copletes the item info structure and start to register. Can not be used before an item has been started to register
 *	-
 *	@noparams
 *	-
 *	@noreturn
*/
native void Shop_EndItem();