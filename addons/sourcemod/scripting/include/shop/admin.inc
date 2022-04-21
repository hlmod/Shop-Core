/**
 *	Called when an item from admin panel is being displayed
 *
 *	@param client				Client index an item is being shown to
 *	@param buffer			    Buffer to store display name
 *	@param maxlength		    Max length of the buffer
 *
 *	@noreturn
 */
typedef Shop_AdminDisplay = function void (int client, char[] buffer, int maxlength);

/**
 *	Called when an item from admin panel is being selected
 *
 *	@param client			    Client index performing selection
 *
 *	@return true to allow performing and false to block
 */
typedef Shop_AdminSelect = function bool (int client);

/**
 *	Adds an item to the admin panel
 *
 *	@param callback_display		Callback when the item is being shown. Set display name in the callback
 *	@param callback_select		Callback when the item is being selected
 *
 *	@noreturn
 */
native void Shop_AddToAdminMenu(Shop_AdminDisplay callback_display, Shop_AdminSelect callback_select);

/**
 *	Removes an item from the admin panel
 *
 *	@param callback_display		Callback to remove
 *	@param callback_select		Callback to remove
 *
 *	@return true on success, false otherwise
 */
native bool Shop_RemoveFromAdminMenu(Shop_AdminDisplay callback_display, Shop_AdminSelect callback_select);

/**
 *	Shows admin panel to a player
 *
 *	@param client				Client index to show to
 *  @error                      Invalid player index
 *
 *	@noreturn
 */
native void Shop_ShowAdminMenu(int client);