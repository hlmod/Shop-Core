# How to create module

## Preparing
First of all you need to create a file with `.sp` extension, full documentation how to write plugins can be found on [SourceMod wiki](https://wiki.alliedmods.net/index.php/Category:SourceMod_Scripting)

!!! note
	For module creation all you need is [a library of shop](https://github.com/R1KO/Shop-Core/tree/master/addons/sourcemod/scripting/include) and all dependence files of it

!!! important "Very important"
	That you know [how to write basic plugins](https://wiki.alliedmods.net/Introduction_to_SourceMod_Plugins) before you try to write **module** for **Shop Core**

This is include file, that contains reference to another libs in our shop, just link it if you want to use shop natives.
```c
#include <shop>
```

Basic understand of the item types in shop.
Lets try to look into `shop.inc` file, what we see here.
```c
enum ItemType
{
	Item_None = 0,		/* < Can not be used */
	Item_Finite = 1,	/* < Can be used like a medkit */
	Item_Togglable = 2,	/* < Can be switched on or off */
	Item_BuyOnly = 3	/* < Only for buy */
}
```
That means, that item can be registered as one of the following types.

Each item has a category, that represented as `CategoryId` type and used as key for item attach to category.
!!! note
	Item cannot exist without category

## Steps to register item:
### Add check if shop is running to `OnPluginStart` and ready to register new categories/items
```
public void OnPluginStart()
{
	/* ... Here some code before ... */
	if (Shop_IsStarted()) Shop_Started(); // to be sure, that Shop is ready to register
}

public void Shop_Started()
{
	// Here we will register items
	// Shop_RegisterCategory, Shop_StartItem, ... natives
}

public void OnPluginEnd()
{
	/* ... Here some code before ... */
	Shop_UnregisterMe(); // To mark module as ready for unload himself from shop core. Because there are no garbage collector like in Java.
}
```
### Register a category via `Shop_RegisterCategory` native.
### Tell our shop core, that we trying to register new item to category.
  * Use `Shop_StartItem` native. Native return `true` if item can be registered, and false if that item is already registered and we stucked at names conflict.
### Next step is adding information for item via `Shop_SetInfo` native. Let's look at this in more detail.

```c
/**
 *	Sets the item information
 *	-
 *	@param name				Default display name
 *	@param description			Default description
 *	@param price				Item price. Can not be lower than sell_price
 *	@param sell_price			Item sell price. 0 to make item free and -1 to make it unsaleable. Can not be higher than price
 *	@param type				Item type. See ItemType enum
 *	@param value				Sets count if the item type is finite and sets duration if the item is togglable or non-togglable
 *	@param gold_price			Item price. Can be -1 to make in unbuyable for gold
 *	@param gold_sell_price			Item sell price. 0 to make item free and -1 to make it unsaleable. Can not be higher than price
 *	-
 *	@noreturn
*/
native void Shop_SetInfo(const char[] name, const char[] description, int price, int sell_price = -1, ItemType type, int value = 1, int gold_price = -1, int gold_sell_price = -1);
```

1. Example item with name `Item name`, description `Item description`, price **1000** credits, sell price **500** credits, with finite number of this item, in equivalent of **1** per purchase, unbuyable by gold (because of **-1**), and unsaleable by gold (because **-1**)
```c
Shop_SetInfo("Item name", "Item description", 1000, 500, Item_Finite, 1, -1, -1);
```
2. Example item with same name and description, but now buyable by **200** credits and **10** gold and __unsaleable__
```c
Shop_SetInfo("Item name", "Item description", 200, -1, Item_Finite, 1, 10, -1);
```
3. Example item with same name and description, but type is Toggleble with **duration of 1 week** (in minutes is 86400), buy price is **500** credits and sell price is **2 gold**
```c
Shop_SetInfo("Item name", "Item description", 500, -1, Item_Toggleble, 86400, -1, 2);
```

### Time to add callbacks for our module. (`Shop_SetCallbacks`)
```c
/**
 *	Sets the item callbacks
 *	-
 *	@param register				Callback called when the item is registered
 *	@param use_toggle			Callback called when the item is being used
 *	@param should				Callback called when the item is being displayed. Here you can stop displaying the item
 *	@param display				Callback called when the item is being displayed. Here you can change item display name
 *	@param description			Callback called when the item description is being displayed. Here you can change item description
 *	@param preview				Callback called when the item is previewing
 *	@param buy				Callback called when the item is being bought
 *	@param sell				Callback called when the item is being sold
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
```

!!! important
	To skip callbacks, that you don't want to use just put `_` on that position
	Shop_SetCallbacks(_, OnEquipItem);

1. First callback (`ItemRegister`) we can ignore, but it useful, when you need to get item id and save it anywhere in your script.
2. Second callback (`ItemUseToggleCallback`) we must use to process event when client is clicking on menu **item to use** it.
3. According to the documentation, there are 2 variants of that callback handling.
```h
typeset ItemUseToggleCallback
{
	function ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item); // For all items
	function ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed); // Only for togglable items
}
```
ShopAction can return those states:
```c
enum ShopAction
{
	Shop_Raw = 0, // do nothing
	Shop_UseOn = 1, // pass to process click
	Shop_UseOff = 2 // pass to process click, but if Item_Togglable, it turns off item and it Toggle status
}
```
### Callback named `OnEquipItem` must be declared like this.
This is example if the item is **NOT** togglable
```c
public ShopAction (int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item)
{
	// Do some stuff here with client
	return Shop_UseOn; // Mark item as toggled on (or used if finite)
}
```

* You can add `Shop_SetLuckChance` to setup luck chance for item

* You can add `Shop_SetHide` to setup is item hidden from **Buy Menu** or not.

* You can provide extra information about item.

```c
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
```

!!! note
	You must always specify `Shop_EndItem()` to mark item as ready to being registered by **core**.

!!! info
	More information will be added later