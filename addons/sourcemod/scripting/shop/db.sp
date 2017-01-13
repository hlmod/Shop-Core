new Handle:h_db;

new ShopDBType:db_type;

new Handle:backup_dp;

new iDays = -1;

DB_CreateNatives()
{
	CreateNative("Shop_GetDatabase", DB_GetDatabase);
	CreateNative("Shop_GetDatabasePrefix", DB_GetDatabasePrefix);
	CreateNative("Shop_GetDatabaseType", DB_GetDatabaseType);
}

public DB_GetDatabase(Handle:plugin, numParams)
{
	return _:CloneHandle(h_db, plugin);
}

public DB_GetDatabasePrefix(Handle:plugin, numParams)
{
	new bytes;
	
	SetNativeString(1, g_sDbPrefix, GetNativeCell(2), false, bytes);
	
	return bytes;
}

public DB_GetDatabaseType(Handle:plugin, numParams)
{
	return _:db_type;
}

DB_OnPluginStart()
{
	RegServerCmd("sm_shop_clear_db", DB_Command_Clear, "Clears database");
	
	backup_dp = CreateDataPack();
	DB_TryConnect();
}

DB_OnSettingsLoad(Handle:kv)
{
	KvGetString(kv, "db_prefix", g_sDbPrefix, sizeof(g_sDbPrefix), "shop_");
	TrimString(g_sDbPrefix);
}

DB_OnMapStart()
{
	iDays = -1;
}

new num_rows;
public Action:DB_Command_Clear(argc)
{
	if (h_db == INVALID_HANDLE || !IsStarted())
	{
		PrintToServer("[Shop] Database is not ready! Try again later");
		DB_TryConnect();
		
		return Plugin_Handled;
	}
	
	if (argc == 0 && iDays == -1)
	{
		iDays = 0;
		
		PrintToServer("[Shop] Full database clear. Type sm_shop_clear_db 'ok' to process the query or 'deny' to cancel the process!");
	}
	else
	{
		decl String:sDays[8];
		GetCmdArg(1, sDays, sizeof(sDays));
		
		if (iDays != -1)
		{
			if (StrEqual(sDays, "ok", false))
			{
				decl String:s_Query[128];
				if (iDays == 0)
				{
					if (db_type == DB_MySQL)
					{
						FormatEx(s_Query, sizeof(s_Query), "TRUNCATE TABLE `%sboughts`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
						num_rows++;
						
						FormatEx(s_Query, sizeof(s_Query), "TRUNCATE TABLE `%splayers`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
						num_rows++;
					}
					else
					{
						FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
						num_rows++;
						
						FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%splayers`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
						num_rows++;
					}
					
					PrintToServer("[Shop] Full clearing database...");
				}
				else
				{
					FormatEx(s_Query, sizeof(s_Query), "SELECT `id` FROM `%splayers` WHERE %d - `lastconnect` > %d;", g_sDbPrefix, global_timer, iDays*86400);
					DB_TQuery(DB_Clear, s_Query, iDays);
					num_rows++;
					
					PrintToServer("[Shop] Clearing database from inactive players for more than %d %s!", iDays, (iDays == 1) ? "day" : "days");
				}
				
				iDays = -1;
			}
			else if (StrEqual(sDays, "deny", false))
			{
				iDays = -1;
				
				PrintToServer("[Shop] Database clear denied!");
			}
			else
			{
				if (iDays == 0)
				{
					PrintToServer("[Shop] Current clearing option is set to - Full database clear");
					PrintToServer("[Shop] This will also delete all data of players that are currently on the server");
				}
				else
				{
					PrintToServer("[Shop] Current clearing option is set to - Clear from inactive players for more than %d %s!", iDays, (iDays == 1) ? "day" : "days");
				}
				PrintToServer("[Shop] Type sm_shop_clear_db 'ok' to process the query or 'deny' to cancel the process!");
			}
			
			return Plugin_Handled;
		}
		
		new days = StringToInt(sDays);
		
		if (days < 1)
		{
			PrintToServer("[Shop] Days can not be less than 1!");
			
			return Plugin_Handled;
		}
		
		iDays = days;
		PrintToServer("[Shop] Database clear from players that are inactive for more than %d %s!", iDays, (iDays == 1) ? "day" : "days");
		PrintToServer("[Shop] Type sm_shop_clear_db 'ok' to process the query or 'deny' to cancel the process!");
	}
	
	return Plugin_Handled;
}

public DB_Clear(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (num_rows) num_rows--;
	
	if (error[0])
	{
		LogError("DB_Clear %d: %s", data, error);
		return;
	}
	
	if (!num_rows)
	{
		switch (data)
		{
			case -1 :
			{
				PrintToServer("[Shop] Database is cleared!");
				return;
			}
			case 0 :
			{
				DatabaseClear();
				PrintToServer("[Shop] Database is fully cleared!");
				return;
			}
		}
		
		if (SQL_GetRowCount(hndl) > 0)
		{
			decl String:s_Query[128], id;
			while (SQL_FetchRow(hndl))
			{
				id = SQL_FetchInt(hndl, 0);
				
				if (!IsInGame(id))
				{
					FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts` WHERE `player_id` = '%d';", g_sDbPrefix, id);
					DB_TQuery(DB_Clear, s_Query, -1);
					num_rows++;
					
					FormatEx(s_Query, sizeof(s_Query), "DELETE FROM `%splayers` WHERE `id` = '%d';", g_sDbPrefix, id);
					DB_TQuery(DB_Clear, s_Query, -1);
					num_rows++;
				}
			}
		}
		else
		{
			PrintToServer("[Shop] Database is already clear from inactive players for more than %d %s!", data, (data == 1) ? "day" : "days");
		}
	}
}

new bool:isLoading;
DB_TryConnect()
{
	if (isLoading)
	{
		return;
	}
	if (h_db != INVALID_HANDLE)
	{
		isLoading = false;
		return;
	}
	
	isLoading = true;
	
	PrintToServer("[Shop] Trying to connect!");
	
	if (SQL_CheckConfig("shop"))
	{
		SQL_TConnect(DB_Connect, "shop", 1);
	}
	else
	{
		decl String:error[256];
		error[0] = '\0';
		
		h_db = SQLite_UseDatabase("shop", error, sizeof(error));
		
		DB_Connect(h_db, h_db, error, 2);
	}
}

public Action:DB_ReconnectTimer(Handle:timer)
{
	if (h_db == INVALID_HANDLE)
	{
		DB_TryConnect();
	}
}

new Handle:upgrade_dp;
new Handle:insert_dp;
public DB_Connect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	h_db = hndl;
	
	if (h_db == INVALID_HANDLE)
	{
		LogError("DB_Connect %d: %s", data, error);
		CreateTimer(15.0, DB_ReconnectTimer);
		isLoading = false;
		return;
	}
	if (error[0])
	{
		LogError("DB_Connect %d: %s", data, error);
	}

	decl String:driver[16];
	switch (data)
	{
		case 1 :
		{
			SQL_GetDriverIdent(owner, driver, sizeof(driver));
		}
		default :
		{
			SQL_ReadDriver(owner, driver, sizeof(driver));
		}
	}
	
	if (StrEqual(driver, "mysql", false))
	{
		db_type = DB_MySQL;
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		db_type = DB_SQLite;
	}
	else
	{
		SetFailState("DB_Connect: Driver \"%s\" is not supported!", driver);
	}
	
	decl String:s_Query[256];
	if (db_type == DB_MySQL)
	{
		DB_TQueryEx("SET NAMES 'utf8'");
		DB_TQueryEx("SET CHARSET 'utf8'");

		if (GetFeatureStatus(FeatureType_Native, "SQL_SetCharset") == FeatureStatus_Available)
		{
			SQL_SetCharset(h_db, "utf8");
		}

		DB_TQuery(DB_GlobalTimer, "SELECT UNIX_TIMESTAMP()", _, DBPrio_High);
		
		FormatEx(s_Query, sizeof(s_Query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '%sboughts';", g_sDbPrefix);
		DB_TQuery(DB_CheckTable, s_Query);
	}
	else
	{
		global_timer = GetTime();
		
		FormatEx(s_Query, sizeof(s_Query), "PRAGMA TABLE_INFO(%sboughts);", g_sDbPrefix);
		DB_TQuery(DB_CheckTable, s_Query);
	}
}

public DB_GlobalTimer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (error[0])
	{
		LogError("DB_GlobalTimer: %s", error);
	}
	
	if (hndl == INVALID_HANDLE || !SQL_HasResultSet(hndl))
	{
		DB_TQuery(DB_GlobalTimer, "SELECT UNIX_TIMESTAMP()");
		return;
	}
	
	SQL_FetchRow(hndl);
	global_timer = SQL_FetchInt(hndl, 0);
}

public DB_CheckTable(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (error[0])
	{
		LogError("DB_CheckTable: %s", error);
		CloseHandle(h_db);
		h_db = INVALID_HANDLE;
		CreateTimer(15.0, DB_ReconnectTimer);
		isLoading = false;
		return;
	}
	
	decl String:s_Query[256];
	if (db_type == DB_MySQL)
	{
		if (!SQL_HasResultSet(hndl) || !SQL_FetchRow(hndl) || SQL_FetchInt(hndl, 0) < 1)
		{
			FormatEx(s_Query, sizeof(s_Query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '%sitems';", g_sDbPrefix);
			DB_TQuery(DB_CheckTable2, s_Query);
			
			return;
		}
	}
	else if (!SQL_GetRowCount(hndl))
	{
		FormatEx(s_Query, sizeof(s_Query), "PRAGMA TABLE_INFO(%sitems);", g_sDbPrefix);
		DB_TQuery(DB_CheckTable2, s_Query);
		
		return;
	}
	
	DB_RunBackup();
	
	OnReadyToStart();
}

public DB_CheckTable2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (error[0])
	{
		LogError("DB_CheckTable2: %s", error);
		CloseHandle(h_db);
		h_db = INVALID_HANDLE;
		CreateTimer(15.0, DB_ReconnectTimer);
		isLoading = false;
		return;
	}
	
	if (SQL_GetRowCount(hndl) > 0)
	{
		if (db_type == DB_MySQL)
		{
			if (SQL_FetchRow(hndl) && SQL_FetchInt(hndl, 0) > 0)
			{
				DB_UpgradeToNewVersion();
				return;
			}
		}
		else
		{
			DB_UpgradeToNewVersion();
			return;
		}
	}
	
	DB_CreateTables();
}

DB_CreateTables()
{
	decl String:s_Query[512];
	if (db_type == DB_MySQL)
	{
		FormatEx(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sboughts` (\
							  `player_id` int(5) NOT NULL,\
							  `item_id` int(5) NOT NULL,\
							  `count` int(4) NOT NULL,\
							  `duration` int(8) NOT NULL,\
							  `timeleft` int(8) NOT NULL,\
							  `buy_price` int(5) NOT NULL,\
							  `sell_price` int(5) NOT NULL,\
							  `buy_time` int(10)\
							) ENGINE=InnoDB DEFAULT CHARSET=utf8;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 1);
		
		FormatEx(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sitems` (\
							  `id` int(5) NOT NULL AUTO_INCREMENT,\
							  `category` varchar(64) NOT NULL,\
							  `item` varchar(64) NOT NULL,\
							  PRIMARY KEY (`id`)\
							) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 2);
		
		FormatEx(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%splayers` (\
							  `id` int(5) NOT NULL AUTO_INCREMENT,\
							  `name` varchar(32) NOT NULL DEFAULT 'unknown',\
							  `auth` varchar(22) NOT NULL,\
							  `money` int(12) NOT NULL,\
							  `lastconnect` int(10),\
							  PRIMARY KEY (`id`), \
								UNIQUE KEY `auth` (`auth`) \
							) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 3);
	}
	else
	{
		FormatEx(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sboughts` (\
							  `player_id` NUMERIC NOT NULL,\
							  `item_id` INTEGER NOT NULL,\
							  `count` NUMERIC NOT NULL,\
							  `duration` INTEGER NOT NULL,\
							  `timeleft` NUMERIC NOT NULL,\
							  `buy_price` INTEGER NOT NULL,\
							  `sell_price` NUMERIC NOT NULL,\
							  `buy_time` NUMERIC NOT NULL);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 1);
		
		FormatEx(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sitems` (\
							  `id` INTEGER PRIMARY KEY AUTOINCREMENT,\
							  `category` VARCHAR NOT NULL,\
							  `item` VARCHAR NOT NULL);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 2);
		
		FormatEx(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%splayers` (\
							  `id` INTEGER PRIMARY KEY AUTOINCREMENT,\
							  `name` VARCHAR DEFAULT 'unknown',\
							  `auth` VARCHAR UNIQUE ON CONFLICT IGNORE,\
							  `money` NUMERIC DEFAULT '0',\
							  `lastconnect` INTEGER NOT NULL);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 3);
	}
	
	isLoading = false;
}

public DB_OnPlayersTableLoad(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (error[0])
	{
		LogError("DB_OnPlayersTableLoad %d: %s", data, error);
		CloseHandle(h_db);
		h_db = INVALID_HANDLE;
		CreateTimer(15.0, DB_ReconnectTimer);
		return;
	}
	
	if (data != 3)
	{
		return;
	}
	
	if (db_type == DB_MySQL)
	{
		DB_TQueryEx("SET NAMES 'utf8'");
		DB_TQueryEx("SET CHARSET 'utf8'");
	}
	
	if (upgrade_dp != INVALID_HANDLE)
	{
		DB_RunUpgrade();
	}
	else
	{
		OnReadyToStart();
	}
}

stock DB_FastQuery(const String:query[])
{
	if (h_db == INVALID_HANDLE)
	{
		new Handle:dp = CreateDataPack();
		WritePackCell(dp, _:DB_ErrorCheck);
		WritePackString(dp, query);
		WritePackCell(dp, 0);
		WritePackCell(dp, _:DBPrio_Normal);
		
		WritePackCell(backup_dp, _:dp);
		
		return;
	}
	
	SQL_LockDatabase(h_db);
	SQL_FastQuery(h_db, query);
	SQL_UnlockDatabase(h_db);
}

DB_TQuery(SQLTCallback:callback, const String:query[], any:data = 0, DBPriority:prio = DBPrio_Normal)
{
	if (h_db == INVALID_HANDLE)
	{
		DataPack dp = new DataPack();
		dp.WriteFunction(callback);
		dp.WriteString(query);
		dp.WriteCell(data);
		dp.WriteCell(prio);
		
		WritePackCell(backup_dp, dp);
		
		return;
	}
	SQL_TQuery(h_db, callback, query, data, prio);
}

DB_TQueryEx(const String:query[], DBPriority:prio = DBPrio_Normal)
{
	if (h_db == INVALID_HANDLE)
	{
		DataPack dp = new DataPack();
		dp.WriteFunction(DB_ErrorCheck);
		dp.WriteString(query);
		dp.WriteCell(0);
		dp.WriteCell(prio);
		
		WritePackCell(backup_dp, _:dp);
		
		return;
	}
	SQL_TQuery(h_db, DB_ErrorCheck, query, _, prio);
}

DB_EscapeString(const String:string[], String:buffer[], maxlength, &written=0)
{
	SQL_EscapeString(h_db, string, buffer, maxlength, written);
}

DB_RunBackup()
{
	decl String:buffer[256], Handle:dp, SQLTCallback:callback, any:data, DBPriority:prio;
	
	ResetPack(backup_dp);
	while (IsPackReadable(backup_dp, 1))
	{
		dp = Handle:ReadPackCell(backup_dp);
		
		callback = view_as<SQLTCallback>(ReadPackFunction(dp));
		ReadPackString(dp, buffer, sizeof(buffer));
		data = ReadPackCell(dp);
		prio = DBPriority:ReadPackCell(dp);
		
		CloseHandle(dp);
		
		DB_TQuery(callback, buffer, data, prio);
	}
	ResetPack(backup_dp, true);
}

stock bool:DB_IsConnected()
{
	return (h_db != INVALID_HANDLE);
}

public DB_ErrorCheck(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (error[0])
	{
		LogError("DB_ErrorCheck: %s", error);
	}
}

DB_UpgradeToNewVersion()
{
	PrintToServer("[Shop] Started upgrading to version 2!");
	
	decl String:s_Query[256];
	
	if (db_type == DB_MySQL)
	{
		FormatEx(s_Query, sizeof(s_Query), "ALTER IGNORE TABLE `%splayers` ADD `lastconnect` int(10) NOT NULL DEFAULT '0';", g_sDbPrefix);
	}
	else
	{
		FormatEx(s_Query, sizeof(s_Query), "ALTER TABLE `%splayers` ADD `lastconnect` NUMERIC NOT NULL DEFAULT '0'", g_sDbPrefix);
	}
	DB_TQueryEx(s_Query);
	
	FormatEx(s_Query, sizeof(s_Query), "SELECT * FROM `%sitems`;", g_sDbPrefix);
	DB_TQuery(DB_UgradeState_1, s_Query);
}

public DB_UgradeState_1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (error[0])
	{
		LogError("DB_UgradeState_1: %s", error);
		DB_CreateTables();
		return;
	}
	
	PrintToServer("[Shop] Reading old tables...");
	
	upgrade_dp = CreateDataPack();
	insert_dp = CreateDataPack();
	
	new bool:got_categories;
	decl String:category[64], String:item[64], String:buffer[2048], id, String:part[128];
	while (SQL_FetchRow(hndl))
	{
		id = SQL_FetchInt(hndl, 0);
		for (new i = 1; i < SQL_GetFieldCount(hndl); i++)
		{
			SQL_FieldNumToName(hndl, i, category, sizeof(category));
			
			if (!got_categories)
			{
				SQL_LockDatabase(h_db);
				FormatEx(buffer, sizeof(buffer), "SELECT `item` FROM `%s`;", category);
				new Handle:hQuery = SQL_Query(h_db, buffer);
				if (hQuery != INVALID_HANDLE)
				{
					while (SQL_FetchRow(hQuery))
					{
						SQL_FetchString(hQuery, 0, item, sizeof(item));
						
						FormatEx(buffer, sizeof(buffer), "INSERT INTO `%sitems` (`category`, `item`) VALUES ('%s', '%s');", g_sDbPrefix, category, item);
						WritePackString(insert_dp, buffer);
					}
					CloseHandle(hQuery);
				}
				SQL_UnlockDatabase(h_db);
			}
			
			SQL_FetchString(hndl, i, buffer, sizeof(buffer));
			
			new num, itemId[256], count[256], duration[256], item_id;
			
			new reloc_idx = 0, var2 = 0;
			while ((var2 = SplitString(buffer[reloc_idx], ",", part, sizeof(part))) != -1)
			{
				reloc_idx += var2;
				if (!part[0]) continue;
				
				new ture = FindCharInString(part, '-');
				if (ture != -1)
				{
					ture++;
					strcopy(item, ture, part);
					
					item_id = StringToInt(item);
					duration[item_id] = StringToInt(part[ture]);
				}
				else
				{
					item_id = StringToInt(part);
				}
				if (count[item_id] == 0)
				{
					itemId[num++] = item_id;
				}
				count[item_id]++;
			}
			
			for (new x = 0; x < num; x++)
			{
				FormatEx(buffer, sizeof(buffer), "INSERT INTO `%sboughts` (`player_id`, `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time`) VALUES \
												('%d', (SELECT `id` FROM `%sitems` WHERE `category` = '%s' AND `item` = (SELECT `item` FROM `%s` WHERE `id` = '%d')), '%d', '%d', '%d', '0', '-1', '%d');", 
												g_sDbPrefix, id, g_sDbPrefix, category, category, itemId[x], count[itemId[x]], duration[itemId[x]], duration[itemId[x]], global_timer);
				WritePackString(upgrade_dp, buffer);
			}
		}
		
		got_categories = true;
	}
	
	FormatEx(buffer, sizeof(buffer), "DROP TABLE `%sitems`;", g_sDbPrefix);
	DB_TQueryEx(buffer, DBPrio_High);
	
	DB_CreateTables();
}

new num_queries;
DB_RunUpgrade()
{
	PrintToServer("[Shop] Running queries...");
	
	decl String:buffer[256];
	
	ResetPack(insert_dp);
	while (IsPackReadable(insert_dp, 1))
	{
		ReadPackString(insert_dp, buffer, sizeof(buffer));
		DB_TQuery(DB_UgradeState_2, buffer);
		num_queries++;
	}
	CloseHandle(insert_dp);
	insert_dp = INVALID_HANDLE;
}

new num_queries2;
public DB_UgradeState_2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	num_queries--;
	
	if (error[0])
	{
		LogError("DB_UgradeState_2: %s", error);
	}
	
	if (num_queries > 0)
	{
		return;
	}
	
	decl String:buffer[512];
	
	ResetPack(upgrade_dp);
	
	while (IsPackReadable(upgrade_dp, 1))
	{
		ReadPackString(upgrade_dp, buffer, sizeof(buffer));
		DB_TQuery(DB_UgradeState_3, buffer, DBPrio_High);
		num_queries2++;
	}
	
	CloseHandle(upgrade_dp);
	upgrade_dp = INVALID_HANDLE;
}

public DB_UgradeState_3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	num_queries2--;
	
	if (error[0])
	{
		LogError("DB_UgradeState_3: %s", error);
	}
	
	if (num_queries2 > 0)
	{
		return;
	}
	
	PrintToServer("[Shop] Upgrade to version 2 completed!");
	
	OnReadyToStart();
}