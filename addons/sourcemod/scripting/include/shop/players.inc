
/**
 *	Called when the plugin has loaded the player's data
 *
 *	@param client				Client index
 *
 *	@noreturn
 */
forward void Shop_OnAuthorized(int client);

/**
 *	Called when a menu is being titled
 *
 *	@param client				Client index to whom a menu is being titled
 *	@param menu_action			Menu that is being titled
 *	@param title				Current title is being set
 *	@param buffer				New title to set
 *	@param maxlength			Maxlength of the title
 *
 *	@return true to apply new value and false to ignore
 */
forward bool Shop_OnMenuTitle(int client, ShopMenu menu_action, const char[] title, char[] buffer, int maxlength);

/**
 *	Called when credits are being sent to a player
 *
 *	@param client				Client index who is sending credits
 *	@param target				Client index to whom credits being sent
 *	@param amount_give			Amount of credits being given to a target player. By reference
 *	@param amount_remove		Amount of credits being taken from performing player.
 *	@param amount_commission	Amount of credits the commission was set. By reference
 *	@param bPercent				Whether the commission was set by the percent By reference
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnCreditsTransfer(int client, int target, int &amount_give, int &amount_remove, int &amount_commission, bool bPercent);

/**
 *	Called when credits has been sent to a player
 *
 *	@param client				Client index who sent credits
 *	@param target				Client index to whom credits were sent
 *	@param amount_give			Amount of credits has been given to a target player
 *	@param amount_remove		Amount of credits has been taken from a performing player
 *	@param amount_commission	Amount of credits the commission was set
 *
 *	@noreturn
 */
forward void Shop_OnCreditsTransfered(int client, int target, int amount_give, int amount_remove, int amount_commission);

/**
 *	Called when a player is being set credits to
 *
 *	@param client				Client index who is being set to
 *	@param credits				Amount of credits a client is being set to. By reference
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher value is the admin index
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnCreditsSet(int client, int &credits, int by_who);

/**
 *	Called when a player has been set credits
 *
 *	@param client				Client index who is been set
 *	@param credits				Amount of credits a client is been set
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher value is the admin index
 *
 *	@noreturn
 */
forward void Shop_OnCreditsSet_Post(int client, int credits, int by_who);

/**
 *	Called when a player is being given credits to
 *
 *	@param client				Client index who is being given to
 *	@param credits				Amount of credits a client is being given to. By reference
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher values is the admin index
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnCreditsGiven(int client, int &credits, int by_who);

/**
 *	Called when a player has been given credits
 *
 *	@param client				Client index who is been given
 *	@param credits				Amount of credits a client is been given
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher values is the admin index
 *
 *	@return noreturn
 */
forward void Shop_OnCreditsGiven_Post(int client, int credits, int by_who);

/**
 *	Called when a player is being taken credits from
 *
 *	@param client				Client index who is being taken from
 *	@param credits				Amount of credits a client is being taken for. By reference
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher value is the admin index
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnCreditsTaken(int client, int &credits, int by_who);

/**
 *	Called when a player has been taken credits
 *
 *	@param client				Client index who is been taken
 *	@param credits				Amount of credits a client is been taken
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher value is the admin index
 *
 *	@return noreturn
 */
forward void Shop_OnCreditsTaken_Post(int client, int credits, int by_who);

/**
 *	Called when a player is being set gold to
 *
 *	@param client				Client index who is being set to
 *	@param amount				Amount of gold a client is being set to. By reference
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher value is the admin index
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnGoldSet(int client, int &amount, int by_who);

/**
 *	Called when a player is being given gold to
 *
 *	@param client				Client index who is being given to
 *	@param amount				Amount of gold a client is being given to. By reference
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher values is the admin index
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnGoldGiven(int client, int &amount, int by_who);

/**
 *	Called when a player is being taken gold from
 *
 *	@param client				Client index who is being taken from
 *	@param amount				Amount of gold a client is being taken for. By reference
 *	@param by_who				See CREDITS_BY_* definitions for more info and any higher value is the admin index
 *
 *	@return Plugin_Changed to apply new values. >= Plugin_Handled to block
 */
forward Action Shop_OnGoldTaken(int client, int &amount, int by_who);

/**
 *	Called when a player is trying to try a luck
 *
 *	@param client				Client index who is perfroming
 *
 *	@return true to allow performing and false to block
 */
forward bool Shop_OnClientLuckProcess(int client);

/**
 *	Called when a player is nearly to win an item
 *	-
 *	@param client				client index
 *	@param item_id				Item id
 *	@param luck_chance			luck chance (by reference)
 *	-
 *	@return Plugin_Changed to apply custom changes. >= Plugin_Handled to block, Plugin_Continue - to proceed without changes.
 */
forward Action Shop_OnClientShouldLuckItemChance(int client, ItemId item_id, int &luck_chance);

/**
 *	Called when a player has won an item
 *
 *	@param client				Client index who has won
 *	@param item_id				Item id of the item
 *
 *	@noreturn
 */
forward void Shop_OnClientItemLucked(int client, ItemId item_id);

/**
 *	Gets a player's id for the database
 *
 *	@param client				Client index to get for
 *  @error                      Invalid player index
 *
 *	@return player id in the database or 0 if client doesn't in database
 */
native int Shop_GetClientId(int client);

/**
 *	Sets timeleft for an item. 0 to set no timelimit
 *
 *	@param client				Client index to set to
 *	@param item_id				Item id to set for
 *	@param timeleft				Timeleft to set. 0 to make it forever
 *	@param reset_duration		Reset duration
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return True on success and false it client has not this item
 */
native bool Shop_SetClientItemTimeleft(int client, ItemId item_id, int timeleft, bool reset_duration = true);

/**
 *	Gets timeleft for an item
 *
 *	@param client				Client index to get from
 *	@param item_id				Item id to get for
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return item timeleft in seconds. 0 if item has no timelimit
 */
native int Shop_GetClientItemTimeleft(int client, ItemId item_id);

/**
 *	Gets an absolute sell price for an item a player hold
 *
 *	@param client				Client index to get from
 *	@param item_id				Item id to get for
 *  @param isGold				True to retrieve gold value, false to get credits
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return sell price of the item
 */
native int Shop_GetClientItemSellPrice(int client, ItemId item_id, bool isGold = false);

/**
 *	Whether a player has toggled on an item
 *
 *	@param client				Client index to check to
 *	@param item_id				Item id to check
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return true if player has item toggled on and false otherwise
 */
native bool Shop_IsClientItemToggled(int client, ItemId item_id);

/**
 *	Whether a player has an item
 *
 *	@param client				Client index to check to
 *	@param item_id				Item id to check
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return true if player has item and false otherwise
 */
native bool Shop_IsClientHasItem(int client, ItemId item_id);

/**
 *	Toggles a client's item
 *
 *	@param client				Client index
 *	@param item_id				Item id to toggle
 *	@param toggle				Toggle state. See ToggleState enum
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return true on success and false otherwise
 */
native bool Shop_ToggleClientItem(int client, ItemId item_id, ToggleState toggle = Toggle);

/**
 *	Toggles all items of category off
 *
 *	@param client				Client index
 *	@param category_id			The category id
 *  @error                      Invalid player index
 *	@error						Invalid CategoryId
 *
 *	@noreturn
 */
native void Shop_ToggleClientCategoryOff(int client, CategoryId category_id);

/**
 *	Checks whether the player has been loaded from database
 *
 *	@param client				Client index to check
 *  @error                      Invalid player index
 *
	@return	True if the player loaded, false otherwise
 */
native bool Shop_IsAuthorized(int client);

/**
 *	Checks whether a player has access to admin panel
 *
 *	@param client				Client index to check
 *  @error                      Invalid player index
 *
	@return	True if the player has access, false otherwise
 */
native bool Shop_IsAdmin(int client);

/**
 *	Gives certain amount of credits to the player
 *
 *	@param client				Client index
 *	@param amount				Amount to give
 *	@param by_who				Optional param to set by who the credits being given from
 *  @error                      Invalid player index
 *
 *	@return	New amount of credits
 */
native int Shop_GiveClientCredits(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Takes certain amount of credits from the player
 *
 *	@param client				Client index
 *	@param amount				Amount to take
 *	@param by_who				Optional param to set by who the credits being given from
 *  @error                      Invalid player index
 *
 *	@return	New amount of credits
 */
native int Shop_TakeClientCredits(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Gets the amount of credits of the player
 *
 *	@param client				Client index
 *  @error                      Invalid player index
 *
 *	@return	Amount of credits a player has, -1 on failure
 */
native int Shop_GetClientCredits(int client);

/**
 *	Sets the amount of credits to the player
 *
 *	@param client				Client index
 *	@param credits				Amount of credits to set
 *  @error                      Invalid player index
 *
 *	@noreturn
 */
native void Shop_SetClientCredits(int client, int credits);

/**
 *	Gives certain amount of gold to the player
 *
 *	@param client				Client index
 *	@param amount				Amount to give
 *	@param by_who				Optional param to set by who the gold being given from
 *  @error                      Invalid player index
 *
 *	@return	New amount of gold
 */
native int Shop_GiveClientGold(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Takes certain amount of gold from the player
 *
 *	@param client				Client index
 *	@param amount				Amount to take
 *	@param by_who				Optional param to set by who the gold being given from
 *  @error                      Invalid player index
 *
 *	@return	New amount of gold
 */
native int Shop_TakeClientGold(int client, int amount, int by_who = CREDITS_BY_NATIVE);

/**
 *	Gets the amount of gold of the player
 *
 *	@param client				Client index
 *  @error                      Invalid player index
 *
 *	@return	Amount of gold a player has, -1 on failure
 */
native int Shop_GetClientGold(int client);

/**
 *	Sets the amount of gold to the player
 *
 *	@param client				Client index
 *	@param amount				Amount of gold to set
 *  @error                      Invalid player index
 *
 *	@noreturn
 */
native void Shop_SetClientGold(int client, int amount);

/**
 *	Forces the player to buy the item from the shop
 *
 *	@param client				Client index
 *	@param item_id				The item id
 *  @error                      Invalid player index
 *
 *	@return	True if the player successfully bought, false otherwise
 */
native bool Shop_BuyClientItem(int client, ItemId item_id);

/**
 *	Forces the player to sell the item from the inventory
 *
 *	@param client				Client index
 *	@param item_id				The item id
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return	True if the player successfully sold, false otherwise
 */
native bool Shop_SellClientItem(int client, ItemId item_id);

/**
 *	Remove the item from the player's inventory
 *
 *	@param client				Client index
 *	@param item_id				The item id
 *	@param count				Number of count to remove
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return	True on success, false otherwise
 */
native bool Shop_RemoveClientItem(int client, ItemId item_id, int count = 0);

/**
 *	Gives the item from the player's inventory
 *
 *	@param client				Client index
 *	@param item_id				The item id
 *	@param value				Count if the item is finite and duration if the item is togglable or non-togglable.
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return	True on success, false otherwise
 */
native bool Shop_GiveClientItem(int client, ItemId item_id, int value = 1);

/**
 *	Get's count of an item a player has
 *
 *	@param client				Client index
 *	@param item_id				The item id
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return	Amount of item that player has
 */
native int Shop_GetClientItemCount(int client, ItemId item_id);

/**
 *	Set count of an item a player has
 *
 *	@param client				Client index
 *	@param item_id				The item id
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@noreturn
 */
native void Shop_SetClientItemCount(int client, ItemId item_id, int count = 0);
/**
 *	Forces a player to use an item
 *
 *	@param client				Client index to force to
 *	@param item_id				Item id to force for
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return true on success and false otherwise
 */
native bool Shop_UseClientItem(int client, ItemId item_id);

/**
 *	Returns the array with player item ids.
 *	@note You must close the Handle yourself.
 *	@note If player has not items - array returned too, but empty.
 *
 *	@param client				Client index
 *  @error                      Invalid player index
 *
 *	@return	ArrayList handle with item ids.
 */
native ArrayList Shop_GetClientItems(int client);

/**
 *	Shows a player an item's panel
 *
 *	@param client				Client index
 *	@param item_id				Item id of the item
 *  @error                      Invalid player index
 *	@error						Invalid ItemId
 *
 *	@return true if a panel has been shown, false otherwise
 */
native bool Shop_ShowItemPanel(int client, ItemId item_id);

/**
 *	Opens main menu for a player
 *
 *	@param client				Client index
 *  @error                      Invalid player index
 *
 *	@noreturn
 */
native void Shop_OpenMainMenu(int client);

/**
 *	Shows a player categories of the shop
 *
 *	@param client				Client index
 *  @error                      Invalid player index
 *
 *	@return true if categories has been shown, false otherwise
 */
native bool Shop_ShowCategory(int client);

/**
 *	Shows a player his inventory
 *
 *	@param client				Client index
 *  @error                      Invalid player index
 *
 *	@return true if the inventory has been shown, false otherwise
 */
native bool Shop_ShowInventory(int client);

/**
 *	Shows a player items of a category
 *
 *	@param client				Client index
 *	@param category_id			Category id to show
 *	@param inventory			To show items of his inventory
 *  @error                      Invalid player index
 *	@error						Invalid CategoryId
 *
 *	@return true if the items has been shown, false otherwise
 */
native bool Shop_ShowItemsOfCategory(int client, CategoryId category_id, bool inventory = false);

/**
 *	Shows functions menu to a player
 *
 *	@param client				Client index to show to
 *  @error                      Invalid player index
 *
 *	@noreturn
 */
native void Shop_ShowFunctionsMenu(int client);