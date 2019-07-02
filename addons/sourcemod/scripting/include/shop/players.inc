/**
 *	Gets a player's id for the database
 *	-
 *	@param client			Client index to get for
 *	-
 *	@return player id in the database or 0 if client doesn't in database
*/
native int Shop_GetClientId(int client);

/**
 *	Sets timeleft for an item. 0 to set no timelimit
 *	-
 *	@param client			Client index to set to
 *	@param item_id			Item id to set for
 *	@param timeleft			Timeleft to set. 0 to make it forever
 *	@param reset_duration	Reset duration
 *	-
 *	@return True on success and false it client has not this item
*/
native bool Shop_SetClientItemTimeleft(int client, ItemId item_id, int timeleft, bool reset_duration = true);

/**
 *	Gets timeleft for an item
 *	-
 *	@param client			Client index to get from
 *	@param item_id		Item id to get for
 *	-
 *	@return item timeleft in seconds. 0 if item has no timelimit
*/
native int Shop_GetClientItemTimeleft(int client, ItemId item_id);

/**
 *	Gets an absolute sell price for an item a player hold
 *	-
 *	@param client			Client index to get from
 *	@param item_id			Item id to get for
 *  @param isGold			True to retrieve gold value, false to get credits
 *	-
 *	@return sell price of the item
*/
native int Shop_GetClientItemSellPrice(int client, ItemId item_id, bool isGold = false);

/**
 *	Whether a player has toggled on an item
 *	-
 *	@param client			Client index to check to
 *	@param item_id		Item id to check
 *	-
 *	@return true if player has item toggled on and false otherwise
*/
native bool Shop_IsClientItemToggled(int client, ItemId item_id);

/**
 *	Whether a player has an item
 *	-
 *	@param client			Client index to check to
 *	@param item_id		Item id to check
 *	-
 *	@return true if player has item and false otherwise
*/
native bool Shop_IsClientHasItem(int client, ItemId item_id);

/**
 *	Toggles a client's item
 *	-
 *	@param client			Client index
 *	@param item_id		Item id to toggle
 *	@param toggle		Toggle state. See ToggleState enum
 *	-
 *	@return true on success and false otherwise
*/
native bool Shop_ToggleClientItem(int client, ItemId item_id, ToggleState toggle = Toggle);

/**
 *	Toggles all items of category off
 *	-
 *	@param client			Client index
 *	@param category_id		The category id
 *	-
 *	@noreturn
*/
native void Shop_ToggleClientCategoryOff(int client, CategoryId category_id);

/**
 *	Checks whether the player has been loaded from database
 *	-
 *	@param client	Client index to check
 *	-
	@return	True if the player loaded, false otherwise
*/
native bool Shop_IsAuthorized(int client);

/**
 *	Checks whether a player has access to admin panel
 *	-
 *	@param client	Client index to check
 *	-
	@return	True if the player has access, false otherwise
*/
native bool Shop_IsAdmin(int client);

/**
 *	Gives certain amount of credits to the player
 *	-
 *	@param client			Client index
 *	@param amount			Amount to give
 *	@param by_who			Optional param to set by who the credits being given from
 *	-
 *	@return	New amount of credits
*/
native int Shop_GiveClientCredits(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Takes certain amount of credits from the player
 *	-
 *	@param client			Client index
 *	@param amount			Amount to take
 *	@param by_who			Optional param to set by who the credits being given from
 *	-
 *	@return	New amount of credits
*/
native int Shop_TakeClientCredits(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Gets the amount of credits of the player
 *	-
 *	@param client			Client index
 *	-
 *	@return	Amount of credits a player has, -1 on failure
*/
native int Shop_GetClientCredits(int client);

/**
 *	Sets the amount of credits to the player
 *	-
 *	@param client			Client index
 *	@param credits			Amount of credits to set
 *	-
 *	@noreturn
*/
native void Shop_SetClientCredits(int client, int credits);

/**
 *	Gives certain amount of gold to the player
 *	-
 *	@param client			Client index
 *	@param amount			Amount to give
 *	@param by_who			Optional param to set by who the gold being given from
 *	-
 *	@return	New amount of gold
*/
native int Shop_GiveClientGold(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Takes certain amount of gold from the player
 *	-
 *	@param client			Client index
 *	@param amount			Amount to take
 *	@param by_who			Optional param to set by who the gold being given from
 *	-
 *	@return	New amount of gold
*/
native int Shop_TakeClientGold(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Gets the amount of gold of the player
 *	-
 *	@param client			Client index
 *	-
 *	@return	Amount of gold a player has, -1 on failure
*/
native int Shop_GetClientGold(int client);

/**
 *	Sets the amount of gold to the player
 *	-
 *	@param client			Client index
 *	@param amount			Amount of gold to set
 *	-
 *	@noreturn
*/
native void Shop_SetClientGold(int client, int amount);

/**
 *	Forces the player to buy the item from the shop
 *	-
 *	@param client			Client index
 *	@param item_id			The item id
 *	-
 *	@return	True if the player successfuly bought, false otherwise
*/
native bool Shop_BuyClientItem(int client, ItemId item_id);

/**
 *	Forces the player to sell the item from the inventory
 *	-
 *	@param client			Client index
 *	@param item_id			The item id
 *	-
 *	@return	True if the player successfuly sold, false otherwise
*/
native bool Shop_SellClientItem(int client, ItemId item_id);

/**
 *	Remove the item from the player's inventory
 *	-
 *	@param client			Client index
 *	@param item_id			The item id
 *	@param count			Number of count to remove
 *	-
 *	@return	True on success, false otherwise
*/
native bool Shop_RemoveClientItem(int client, ItemId item_id, int count = 0);

/**
 *	Gives the item from the player's inventory
 *	-
 *	@param client			Client index
 *	@param item_id			The item id
 *	@param value			Count if the item is finite and duration if the item is togglable or non-togglable.
 *	-
 *	@return	True on success, false otherwise
*/
native bool Shop_GiveClientItem(int client, ItemId item_id, int value = 1);

/**
 *	Get's count of an item a player has
 *	-
 *	@param client			Client index
 *	@param item_id			The item id
 *	-
 *	@return	Amount of item that player has
*/
native int Shop_GetClientItemCount(int client, ItemId item_id);

/**
 *	Set count of an item a player has
 *	-
 *	@param client			Client index
 *	@param item_id			The item id
 *	-
 *	@noreturn
*/
native void Shop_SetClientItemCount(int client, ItemId item_id, int count = 0);
/**
 *	Forces a player to use an item
 *	-
 *	@param client			Client index to force to
 *	@param item_id		Item id to force for
 *	-
 *	@return true on success and false otherwise
*/
native bool Shop_UseClientItem(int client, ItemId item_id);

/**
 * Returns the array with player item ids.
 * Must be freed via CloseHandle() / delete / Handle.Close().
 *
 * @param	client		Client index
 *
 * @return	ArrayList handle with item ids.
 * @error	Client is not connected/not loaded.
 * @note	If player has not items - array returned too, but empty.
 */
native ArrayList Shop_GetClientItems(int client);
