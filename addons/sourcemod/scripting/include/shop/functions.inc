/**
 *	Called when an item from functions menu is being displayed
 *	
 *	@param client				Client index an item is being shown to
 *	@param buffer			    Buffer to store display name
 *	@param maxlength		    Max length of the buffer
 *	
 *	@noreturn
*/
typedef Shop_FuncDisplay = function void (int client, char[] buffer, int maxlength);

/**
 *	Called when an item from functions menu is being selected
 *	
 *	@param client				Client index performing selection
 *	
 *	@return true to allow performing and false to block
*/
typedef Shop_FuncSelect = function bool (int client);

/**
 *	Adds an item to the functions menu
 *	
 *	@param callback_display		Callback when the item is being shown. Set display name in the callback
 *	@param callback_select		Callback when the item is being selected
 *	
 *	@noreturn
*/
native void Shop_AddToFunctionsMenu(Shop_FuncDisplay callback_display, Shop_FuncSelect callback_select);

/**
 *	Removes an item from the functions menu
 *	
 *	@param callback_display		Callback to remove
 *	@param callback_select		Callback to remove
 *	
 *	@return true on success, false otherwise
*/
native bool Shop_RemoveFromFunctionsMenu(Shop_FuncDisplay callback_display, Shop_FuncSelect callback_select);