
#define SHOP_ITEM(%0) view_as<ShopItem>(%0)
#define SHOP_ITEM_ID(%0) view_as<ItemId>(%0)

const ShopItem SHOP_INVALID_ITEM = SHOP_ITEM(INVALID_ITEM);

methodmap ShopItem __nullable__
{
	property int Price
	{
		public get() { return Shop_GetItemPrice(SHOP_ITEM_ID(this)); }
		public set(int iPrice) { Shop_SetItemPrice(SHOP_ITEM_ID(this), iPrice); }
	}
	property int SellPrice
	{
		public get() { return Shop_GetItemSellPrice(SHOP_ITEM_ID(this)); }
		public set(int iSellPrice) { Shop_SetItemSellPrice(SHOP_ITEM_ID(this), iSellPrice); }
	}
	property int GoldPrice
	{
		public get() { return Shop_GetItemGoldPrice(SHOP_ITEM_ID(this)); }
		public set(int iPrice) { Shop_SetItemGoldPrice(SHOP_ITEM_ID(this), iPrice); }
	}
	property int GoldSellPrice
	{
		public get() { return Shop_GetItemGoldSellPrice(SHOP_ITEM_ID(this)); }
		public set(int iSellPrice) { Shop_SetItemGoldSellPrice(SHOP_ITEM_ID(this), iSellPrice); }
	}
	property int LuckChance
	{
		public get() { return Shop_GetItemLuckChance(SHOP_ITEM_ID(this)); }
		public set(int iLuckChance) { Shop_SetItemLuckChance(SHOP_ITEM_ID(this), iLuckChance); }
	}
	property int Value
	{
		public get() { return Shop_GetItemValue(SHOP_ITEM_ID(this)); }
		public set(int iValue) { Shop_SetItemValue(SHOP_ITEM_ID(this), iValue); }
	}
	property ItemType Type
	{
		public get() { return Shop_GetItemType(SHOP_ITEM_ID(this)); }
	}
	property bool CanLuck
	{
		public get() { return Shop_GetItemCanLuck(SHOP_ITEM_ID(this)); }
		public set(bool bCanLuck) { Shop_SetItemCanLuck(SHOP_ITEM_ID(this), bCanLuck); }
	}
	property bool Hide
	{
		public get() { return Shop_GetItemHide(SHOP_ITEM_ID(this)); }
		public set(bool bHide) { Shop_SetItemHide(SHOP_ITEM_ID(this), bHide); }
	}
	property CategoryId CategoryID
	{
		public get() { return Shop_GetItemCategoryId(SHOP_ITEM_ID(this)); }
	}

	public bool IsExists()
	{
		return Shop_IsItemExists(SHOP_ITEM_ID(this));
	}

	public static ShopItem GetItem(CategoryId category_id, const char[] item)
	{
		return Shop_GetItemId(category_id, item);
	}

	public int GetName(char[] buffer, int maxlength)
	{
		return Shop_GetItemById(SHOP_ITEM_ID(this), buffer, maxlength);
	}

	public int GetDisplayName(char[] buffer, int maxlength)
	{
		return Shop_GetItemNameById(SHOP_ITEM_ID(this), buffer, maxlength);
	}

	public int GetCustomInfo(const char[] info, int defaultvalue = 0)
	{
		return Shop_GetItemCustomInfo(SHOP_ITEM_ID(this), info, defaultvalue);
	}

	public bool FormatItem(int client, ShopMenu menu, char[] buffer, int maxlength)
	{
		return Shop_FormatItem(client, SHOP_ITEM_ID(this), menu, buffer, maxlength);
	}

	public bool ShowPanel(int client)
	{
		return Shop_ShowItemPanel(client, SHOP_ITEM_ID(this));
	}
};

#define SHOP_CATEGORY(%0) view_as<ShopCategory>(%0)
#define SHOP_CATEGORY_ID(%0) view_as<CategoryId>(%0)

methodmap ShopCategory __nullable__
{
	public static ShopCategory GetID(const char[] category)
	{
		return Shop_GetCategoryId(category);
	}

	public int GetName(char[] buffer, int maxlength)
	{
		return Shop_GetCategoryById(SHOP_CATEGORY_ID(this), buffer, maxlength);
	}

	public int GetDisplayName(char[] buffer, int maxlength)
	{
		return Shop_GetCategoryNameById(SHOP_CATEGORY_ID(this), buffer, maxlength);
	}

	public bool ShowItems(int client, bool inventory = false)
	{
		return Shop_ShowItemsOfCategory(client, SHOP_CATEGORY_ID(this, inventory);
	}
};
