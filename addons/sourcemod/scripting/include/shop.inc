/**
	Library of the [Shop] Core v3
	Author: FrozDark
	www.hlmod.ru
 */

#if defined _shop_included
 #endinput
#endif
#define _shop_included

#define SHOP_MAX_STRING_LENGTH	64

enum CategoryId
{
	INVALID_CATEGORY = -1
}

enum ItemId
{
	INVALID_ITEM = 0
}

enum ItemType
{
	Item_None = 0,			// For nothing is used.
	Item_Finite = 1,		// Can only be used, they have quantity.
	Item_Togglable = 2,		// Can be toggleable, turn on or off.
	Item_BuyOnly = 3		// Can only be bought.
}

enum ToggleState
{
	Toggle,					// Toggleable in reverse position.
	Toggle_On,				// Turn on.
	Toggle_Off				// Turn off.
}

enum ShopAction
{
	Shop_Raw = 0,			// Cancel use or toggleable.
	Shop_UseOn = 1,			// Confirm Item Enablement.
	Shop_UseOff = 2			// Confirm item deactivation.
}

enum ShopMenu
{
	Menu_Main,				// Main menu (first menu by sm_shop command)
	Menu_Buy,				// Buy Menu.
	Menu_Inventory,			// Player Inventory.
	Menu_Functions,			// Shop menu functions.
	Menu_ExtraFunctions,	// Extra shop menu functions.
	Menu_AdminPanel,		// Admin panel in the menu.
	Menu_CreditsTransfer,	// Credit transfer menu.
	Menu_ItemTransfer		// Item transfer menu.
}

#define	IGNORE_FORWARD_HOOK	-5				//**< Param to set to avoid calling forward hook */
#define	CREDITS_BY_LUCK	-4					//**< Credits being processed by item luck */
#define	CREDITS_BY_TRANSFER	-3				//**< Credits being processed by credits transfer */
#define	CREDITS_BY_BUY_OR_SELL	-2			//**< Credits being processed by buying or selling an item */
#define	CREDITS_BY_NATIVE	-1				//**< Credits being processed by native */
#define	CREDITS_BY_COMMAND	0				//**< Credits being processed by server console or rcon command */
//**< Any higher value is admin index */

#include <shop/admin>
#include <shop/functions>
#include <shop/db>
#include <shop/items>
#include <shop/players>
#include <shop/register>
#include <shop/methodmaps>

/**
 *	Called when the shop is ready to register items.
 *
 *	@noparams
 *
 *	@noreturn
 */
forward void Shop_Started();

/**
 *	Checks whether the shop has been started.
 *
 *	@noparams
 *
 *	@return	True if the shop is already started, false otherwise.
 */
native bool Shop_IsStarted();

/**
 *	This must be called on PluginEnd. Fully unregisters the plugin. Unregisters items, categories and removes them from the shop and players' inventory.
 *
 *	@noparams
 *
 *	@noreturn
 */
native void Shop_UnregisterMe();

/**
 *	Get path to the main config folder of the Shop.
 *
 *	@param buffer			Buffer to store the path in.
 *	@param size				Max buffer length.
 *	@param file				File to retrieve the path for.
 *
 *	@noreturn
 */
stock void Shop_GetCfgFile(char[] buffer, int size, const char[] file)
{
	BuildPath(Path_SM, buffer, size, "configs/shop/%s", file);
}

public SharedPlugin __pl_shop =
{
	name = "shop",
	file = "shop.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_shop_SetNTVOptional()
{
	MarkNativeAsOptional("Shop_IsStarted");
	MarkNativeAsOptional("Shop_UnregisterMe");
	MarkNativeAsOptional("Shop_UnregisterItem");
	MarkNativeAsOptional("Shop_ShowItemPanel");
	MarkNativeAsOptional("Shop_OpenMainMenu");
	MarkNativeAsOptional("Shop_ShowCategory");
	MarkNativeAsOptional("Shop_ShowInventory");
	MarkNativeAsOptional("Shop_ShowItemsOfCategory");
	MarkNativeAsOptional("Shop_GetDatabase");
	MarkNativeAsOptional("Shop_GetDatabasePrefix");

	MarkNativeAsOptional("Shop_ShowAdminMenu");
	MarkNativeAsOptional("Shop_AddToAdminMenu");
	MarkNativeAsOptional("Shop_RemoveFromAdminMenu");

	MarkNativeAsOptional("Shop_ShowFunctionsMenu");
	MarkNativeAsOptional("Shop_AddToFunctionsMenu");
	MarkNativeAsOptional("Shop_RemoveFromFunctionsMenu");

	MarkNativeAsOptional("Shop_RegisterCategory");
	MarkNativeAsOptional("Shop_StartItem");
	MarkNativeAsOptional("Shop_SetInfo");
	MarkNativeAsOptional("Shop_SetLuckChance");
	MarkNativeAsOptional("Shop_SetCallbacks");
	MarkNativeAsOptional("Shop_SetCustomInfo");
	MarkNativeAsOptional("Shop_SetCustomInfoFloat");
	MarkNativeAsOptional("Shop_SetCustomInfoString");
	MarkNativeAsOptional("Shop_KvCopySubKeysCustomInfo");
	MarkNativeAsOptional("Shop_EndItem");

	MarkNativeAsOptional("Shop_GetItemCustomInfo");
	MarkNativeAsOptional("Shop_SetItemCustomInfo");
	MarkNativeAsOptional("Shop_GetItemCustomInfoFloat");
	MarkNativeAsOptional("Shop_SetItemCustomInfoFloat");
	MarkNativeAsOptional("Shop_GetItemCustomInfoString");
	MarkNativeAsOptional("Shop_SetItemCustomInfoString");
	MarkNativeAsOptional("Shop_KvCopySubKeysItemCustomInfo");
	MarkNativeAsOptional("Shop_GetItemPrice");
	MarkNativeAsOptional("Shop_SetItemPrice");
	MarkNativeAsOptional("Shop_GetItemGoldPrice");
	MarkNativeAsOptional("Shop_SetItemGoldPrice");
	MarkNativeAsOptional("Shop_GetItemSellPrice");
	MarkNativeAsOptional("Shop_SetItemSellPrice");
	MarkNativeAsOptional("Shop_GetItemGoldSellPrice");
	MarkNativeAsOptional("Shop_SetItemGoldSellPrice");
	MarkNativeAsOptional("Shop_GetItemLuckChance");
	MarkNativeAsOptional("Shop_SetItemLuckChance");
	MarkNativeAsOptional("Shop_GetItemValue");
	MarkNativeAsOptional("Shop_SetItemValue");
	MarkNativeAsOptional("Shop_IsItemExists");
	MarkNativeAsOptional("Shop_IsValidCategory");
	MarkNativeAsOptional("Shop_GetItemId");
	MarkNativeAsOptional("Shop_GetItemById");
	MarkNativeAsOptional("Shop_GetItemType");
	MarkNativeAsOptional("Shop_GetItemCategoryId");
	MarkNativeAsOptional("Shop_GetCategoryId");
	MarkNativeAsOptional("Shop_GetCategoryById");
	MarkNativeAsOptional("Shop_GetCategoryNameById");
	MarkNativeAsOptional("Shop_FillArrayByItems");
	MarkNativeAsOptional("Shop_FormatItem");
	MarkNativeAsOptional("Shop_GetClientItems");

	MarkNativeAsOptional("Shop_GetClientId");
	MarkNativeAsOptional("Shop_SetClientItemTimeleft");
	MarkNativeAsOptional("Shop_GetClientItemTimeleft");
	MarkNativeAsOptional("Shop_GetClientItemSellPrice");
	MarkNativeAsOptional("Shop_IsClientItemToggled");
	MarkNativeAsOptional("Shop_IsClientHasItem");
	MarkNativeAsOptional("Shop_ToggleClientItem");
	MarkNativeAsOptional("Shop_ToggleClientCategoryOff");
	MarkNativeAsOptional("Shop_IsAuthorized");
	MarkNativeAsOptional("Shop_IsAdmin");
	MarkNativeAsOptional("Shop_GiveClientCredits");
	MarkNativeAsOptional("Shop_TakeClientCredits");
	MarkNativeAsOptional("Shop_GetClientCredits");
	MarkNativeAsOptional("Shop_SetClientCredits");
	MarkNativeAsOptional("Shop_GiveClientGold");
	MarkNativeAsOptional("Shop_TakeClientGold");
	MarkNativeAsOptional("Shop_GetClientGold");
	MarkNativeAsOptional("Shop_SetClientGold");
	MarkNativeAsOptional("Shop_GiveClientItem");
	MarkNativeAsOptional("Shop_BuyClientItem");
	MarkNativeAsOptional("Shop_SellClientItem");
	MarkNativeAsOptional("Shop_RemoveClientItem");
	MarkNativeAsOptional("Shop_GetClientItemCount");
	MarkNativeAsOptional("Shop_UseClientItem");
	MarkNativeAsOptional("Shop_SetHide");
	MarkNativeAsOptional("Shop_GetClientItems");

	MarkNativeAsOptional("CategoryId.CategoryId");
	MarkNativeAsOptional("CategoryId.NewItem");
	MarkNativeAsOptional("CategoryId.GetItemId");
	MarkNativeAsOptional("CategoryId.GetByUnique");
	MarkNativeAsOptional("CategoryId.GetUniqueName");
	MarkNativeAsOptional("CategoryId.GetDisplayName");
	MarkNativeAsOptional("CategoryId.ToggleOff");
	MarkNativeAsOptional("CategoryId.Exist.get");

	MarkNativeAsOptional("ItemId.GetCustomInfo");
	MarkNativeAsOptional("ItemId.SetCustomInfo");
	MarkNativeAsOptional("ItemId.GetCustomInfoFloat");
	MarkNativeAsOptional("ItemId.SetCustomInfoFloat");
	MarkNativeAsOptional("ItemId.GetCustomInfoString");
	MarkNativeAsOptional("ItemId.SetCustomInfoString");
	MarkNativeAsOptional("ItemId.KvCopyCustomInfo");
	MarkNativeAsOptional("ItemId.GetUniqueName");
	MarkNativeAsOptional("ItemId.GetDisplayName");
	MarkNativeAsOptional("ItemId.Format");
	MarkNativeAsOptional("ItemId.Give");
	MarkNativeAsOptional("ItemId.Buy");
	MarkNativeAsOptional("ItemId.Sell");
	MarkNativeAsOptional("ItemId.Use");
	MarkNativeAsOptional("ItemId.Remove");
	MarkNativeAsOptional("ItemId.GetCount");
	MarkNativeAsOptional("ItemId.SetCount");
	MarkNativeAsOptional("ItemId.SetTimeLeft");
	MarkNativeAsOptional("ItemId.GetTimeLeft");
	MarkNativeAsOptional("ItemId.GetSellPrice");
	MarkNativeAsOptional("ItemId.IsToggled");
	MarkNativeAsOptional("ItemId.IsHas");
	MarkNativeAsOptional("ItemId.Toggle");
	MarkNativeAsOptional("ItemId.CategoryId.get");
	MarkNativeAsOptional("ItemId.Price.get");
	MarkNativeAsOptional("ItemId.Price.set");
	MarkNativeAsOptional("ItemId.SellPrice.get");
	MarkNativeAsOptional("ItemId.SellPrice.set");
	MarkNativeAsOptional("ItemId.Value.get");
	MarkNativeAsOptional("ItemId.Value.set");
	MarkNativeAsOptional("ItemId.LuckChange.get");
	MarkNativeAsOptional("ItemId.LuckChange.set");
	MarkNativeAsOptional("ItemId.Hide.get");
	MarkNativeAsOptional("ItemId.Hide.set");
	MarkNativeAsOptional("ItemId.ItemType.get");
	MarkNativeAsOptional("ItemId.Exist.get");

}
#endif
