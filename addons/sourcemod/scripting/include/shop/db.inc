enum ShopDBType
{
	DB_Unknown,
	DB_MySQL,
	DB_SQLite
}

/**
 *	Get the database handle. Must be freed with CloseHandle()
 *
 *	@noparams
 *
 *	@return	Database Handle
*/
native Database Shop_GetDatabase();

/**
 *	Gets the database type. See ShopDBType enumeration
 *
 *	@noparams
 *
 *	@return	Database type
*/
native ShopDBType Shop_GetDatabaseType();

/**
 *	Get the database prefix
 *
 *	@param buffer				Buffer to store the prefix in
 *	@param maxlength			Max buffer length
 *
 *	@return	Number of bytes written
*/
native int Shop_GetDatabasePrefix(char[] buffer, int maxlength);