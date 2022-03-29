
methodmap CategoryId < Handle
{
	// Registers new category id
	// 
	// @param category					Category unique name
	// @param name						Default category display name
	// @param description				Default category description
	// @param cat_display				Callback called on category being displayed
	// @param cat_desc					Callback called on category's description being displayed
	// @param cat_should				Callback called whether the category should be displayed to a player
	// @param cat_select				Callback called when a player is trying to select the category
	// @return					  		Category id of the category
	public native CategoryId(const char[] category, const char[] name, const char[] description, 
							 Shop_CategoryDisplayCallback cat_display=INVALID_FUNCTION, 
							 Shop_CategoryDescriptionCallback cat_desc=INVALID_FUNCTION,
							 Shop_CategoryShouldDisplayCallback cat_should=INVALID_FUNCTION,
							 Shop_CategorySelectCallback cat_select=INVALID_FUNCTION);

	// Gets category id of the category unique name
	// 
	// @param item						Category unique name to get id for
	// @return					  		Category id of the category
	public static CategoryId GetIdByName(const char[] category) {
		return Shop_GetCategoryId(category);
	}

	// Gets item id of the item unique name from category_id
	// 
	// @param item						Item unique name to get for
	// @return					  		Item id of the item
	public static native ItemId GetItemId(const char[] item);

	// Gets the category unique name by its id
	// 
	// @param buffer					Buffer to store the unique name
	// @param maxlength					Max length of the buffer
	// @return					  		True on success, false otherwise
	public native bool GetUniqueName(char[] buffer, int maxlength);

	// Gets the category name by its id
	// 
	// @param buffer					Buffer to store the unique name
	// @param maxlength					Max length of the buffer
	// @return					  		True on success, false otherwise
	public native bool GetName(char[] buffer, int maxlength);

	// Toggles all items of category off
	// 
	// @param client					Client index
	// @noreturn
	public void ToggleOff(int client) {
		Shop_ToggleClientCategoryOff(client, this);
	}

	// Whether the category is valid (registered)
	property bool Exist {
		public native get();
	}
}

methodmap ItemId < Handle
{
	// Gets an item custom info
	// 
	// @param item_id					Item id
	// @param info						Info key to get
	// @param defaultvalue				Optional default value to use if the key is not found
	// @return					 		Integer value of the key
	public native int GetCustomInfo(const char[] info, int defaultvalue = 0);

	// Sets an item custom info
	// 
	// @param item_id					Item id
	// @param info						Info key to get
	// @param value						Value to set
	// @return					  		true on success, false otherwise
	public native bool SetCustomInfo(const char[] info, int value);

	// Gets an item custom info
	// 
	// @param item_id					Item id
	// @param info						Info key to get
	// @param defaultvalue				Optional default value to use if the key is not found
	// @return					  		Float value of the key
	public native float GetCustomInfoFloat(const char[] info, float defaultvalue = 0.0);

	// Sets an item custom info
	// 
	// @param item_id					Item id
	// @param info						Info key to get
	// @param value						Value to set
	// @return					  		true on success, false otherwise
	public native bool SetCustomInfoFloat(const char[] info, float value);

	// Gets an item custom info
	// 
	// @param item_id					Item id
	// @param info						Info key to get
	// @param buffer					Buffer to store the value in
	// @param maxlength					Max length of the buffer
	// @param defaultvalue				Optional default value to use if the key is not found
	// @return					  		Number of bytes written
	public native int GetCustomInfoString(const char[] info, char[] buffer, int maxlength, const char[] defaultvalue = "");

	// Sets an item custom info
	// 
	// @param item_id					Item id
	// @param info						Info key to get
	// @param value						Value to set
	// @return					  		true on success, false otherwise
	public native bool SetCustomInfoString(const char[] info, const char[] value);

	// Copies SubKeys of a KeyValue structure to the item info
	// 
	// @param item_id					Item id
	// @param kv						KeyValue structure to copy
	// @return					  		true on success, false otherwise
	public native bool KvCopyCustomInfo(KeyValues kv);

	// Gets the item unique name by its id
	// 
	// @param buffer					Buffer to store the unique name
	// @param maxlength					Max length of the buffer
	// @return					  		Number of bytes written
	public native int GetUniqueName(char[] buffer, int maxlength);

	// Gets the item  name by its id
	// 
	// @param buffer					Buffer to store the unique name
	// @param maxlength					Max length of the buffer
	// @return					  		Number of bytes written
	public native int GetName(char[] buffer, int maxlength);

	// Gets the item's category id
	//
	// @return					  		Category id or INVALID_CATEGORY if category is not set or item id is invalid
	public native CategoryId GetCategoryId();

	// Formats item display name to use in menu
	//
	// @param client					Client index to get format for
	// @param menu						Menu to get formatted for
	// @param buffer					Buffer to store the result in
	// @param maxlength					Max length of the buffer
	// @return					  		True if item formatted, false if param menu is Menu_Inventory and the player has not this item and the item is not formatted
	public bool Format(int client, ShopMenu menu, char[] buffer, int maxlength) {
		return Shop_FormatItem(client, this, menu, buffer, maxlength);
	}

	// Gives the item from the player's inventory
	//
	// @param client					Client index
	// @param value						Count if the item is finite and duration if the item is togglable or non-togglable.
	// @return							True on success, false otherwise
	public bool Give(int client, int value = 1) {
		return Shop_GiveClientItem(client, this, value);
	}

	// Forces the player to buy the item from the shop
	// 
	// @param client					Client index
	// @return							True if the player successfuly bought, false otherwise
	public bool Buy(int client) {
		return Shop_BuyClientItem(client, this);
	}

	// Forces the player to sell the item from the inventory
	// 
	// @param client					Client index
	// @return							True if the player successfuly sold, false otherwise
	public bool Sell(int client) {
		return Shop_SellClientItem(client, this);
	}

	// Forces a player to use an item
	// 
	// @param client					Client index to force to
	// @return 							true on success and false otherwise
	public bool Use(int client) {
		return Shop_UseClientItem(client, this);
	}

	// Remove the item from the player's inventory
	// 
	// @param client					Client index
	// @param count						Number of count to remove
	// @return							True on success, false otherwise
	public bool Remove(int client, int count = 0) {
		return Shop_RemoveClientItem(client, this, count);
	}

	// Get's count of an item a player has
	// 
	// @param client					Client index
	// @return							Amount of item that player has
	public int GetCount(int client) {
		return Shop_GetClientItemCount(client, this);
	}

	// Set count of an item a player has
	// 
	// @param client					Client index
	// @noreturn
	public void SetCount(int client, int count = 0) {
		Shop_SetClientItemCount(client, this, count);
	}
	
	// Sets timeleft for an item. 0 to set no timelimit
	// 
	// @param client					Client index to set to
	// @param timeleft					Timeleft to set. 0 to make it forever
	// @param reset_duration			Reset duration
	// @return 							True on success and false it client has not this item
	public bool SetTimeLeft(int client, int timeleft, bool reset_duration = true) {
		return Shop_SetClientItemTimeleft(client, this, timeleft, reset_duration);
	}

	// Gets timeleft for an item
	// 
	// @param client					Client index to get from
	// @return 							item timeleft in seconds. 0 if item has no timelimit
	public int GetTimeLeft(int client) {
		return Shop_GetClientItemTimeleft(client, this);
	}

	// Gets an absolute sell price for an item a player hold
	// 
	// @param client					Client index to get from
	// @param isGold					True to retrieve gold value, false to get credits
	// 		
	// @return 							sell price of the item
	public int GetSellPrice(int client, bool isGold = false) {
		return Shop_GetClientItemSellPrice(client, this, isGold);
	}

	// Whether a player has toggled on an item
	// 
	// @param client					Client index to check to
	// @return 							true if player has item toggled on and false otherwise
	public bool IsToggled(int client) {
		return Shop_IsClientItemToggled(client, this);
	}
	
	// Whether a player has an item
	// 
	// @param client					Client index to check to
	// @return 							true if player has item and false otherwise
	public bool IsHas(int client) {
		return Shop_IsClientHasItem(client, this);
	}

	// Toggles a client's item
	// 
	// @param client					Client index
	// @param toggle					Toggle state. See ToggleState enum
	// @return 							true on success and false otherwise
	public bool Toggle(int client, ToggleState toggle = Toggle) {
		return Shop_ToggleClientItem(client, this, toggle);
	}

	// Gets the item's category id
	property CategoryId CategoryId {
		public native get();
	}

	// Get or set an item credits price
	property int Price {
		public native get();
		public native set(int value);
	}

	// Get or set an item credits sell price
	property int SellPrice {
		public native get();
		public native set(int value);
	}

	// Get or set an item count if item is finite 
	// and duration if item is togglable or non-togglable (-1 if duration is unlimited)
	property int Value {
		public native get();
		public native set(int value);
	}

	// Get or set an item luck chance (0-100)
	property int LuckChange {
		public native get();
		public native set(int value);
	}

	// Get or set feature "Hide"
	property bool Hide {
		public native get();
		public native set(bool value);
	}

	// Gets the item type. See ItemType enumeration
	property ItemType Type {
		public native get();
	}
	
	// Whether the item is exists (registered)
	property bool Exist {
		public native get();
	}
}