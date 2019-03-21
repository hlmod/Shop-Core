Database h_db;

ShopDBType db_type;

DataPack backup_dp;

int iDays = -1;

void DB_CreateNatives()
{
	CreateNative("Shop_GetDatabase", DB_GetDatabase);
	CreateNative("Shop_GetDatabasePrefix", DB_GetDatabasePrefix);
	CreateNative("Shop_GetDatabaseType", DB_GetDatabaseType);
}

public int DB_GetDatabase(Handle plugin, int numParams)
{
	return view_as<int>(CloneHandle(h_db, plugin));
}

public int DB_GetDatabasePrefix(Handle plugin, int numParams)
{
	int bytes;
	
	SetNativeString(1, g_sDbPrefix, GetNativeCell(2), false, bytes);
	
	return bytes;
}

public int DB_GetDatabaseType(Handle plugin, int numParams)
{
	return view_as<int>(db_type);
}

void DB_OnPluginStart()
{
	RegServerCmd("sm_shop_clear_db", DB_Command_Clear, "Clears database");
	
	backup_dp = new DataPack();
	DB_TryConnect();
}

void DB_OnSettingsLoad(KeyValues kv)
{
	kv.GetString("db_prefix", g_sDbPrefix, sizeof(g_sDbPrefix), "shop_");
	TrimString(g_sDbPrefix);
}

void DB_OnMapStart()
{
	iDays = -1;
}

int num_rows;
public Action DB_Command_Clear(int argc)
{
	if (h_db == null || !IsStarted())
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
		char sDays[8];
		GetCmdArg(1, sDays, sizeof(sDays));
		
		if (iDays != -1)
		{
			if (StrEqual(sDays, "ok", false))
			{
				char s_Query[128];
				if (iDays == 0)
				{
					if (db_type == DB_MySQL)
					{
						h_db.Format(s_Query, sizeof(s_Query), "TRUNCATE TABLE `%sboughts`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);

						h_db.Format(s_Query, sizeof(s_Query), "TRUNCATE TABLE `%splayers`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);

						h_db.Format(s_Query, sizeof(s_Query), "TRUNCATE TABLE `%stoggles`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
					}
					else
					{
						h_db.Format(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
						
						h_db.Format(s_Query, sizeof(s_Query), "DELETE FROM `%splayers`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);

						h_db.Format(s_Query, sizeof(s_Query), "DELETE FROM `%stoggles`;", g_sDbPrefix);
						DB_TQuery(DB_Clear, s_Query, iDays);
					}

					num_rows += 3;
					PrintToServer("[Shop] Full clearing database...");
				}
				else
				{
					h_db.Format(s_Query, sizeof(s_Query), "DELETE FROM `%sboughts` WHERE `player_id` IN (SELECT `id` FROM `%splayers` WHERE %d - `lastconnect` > %d);", g_sDbPrefix, g_sDbPrefix, global_timer, iDays*86400);
					DB_TQuery(DB_Clear, s_Query, iDays);

					h_db.Format(s_Query, sizeof(s_Query), "DELETE FROM `%stoggles` WHERE `player_id` IN (SELECT `id` FROM `%splayers` WHERE %d - `lastconnect` > %d);", g_sDbPrefix, g_sDbPrefix, global_timer, iDays*86400);
					DB_TQuery(DB_Clear, s_Query, iDays);

					h_db.Format(s_Query, sizeof(s_Query), "DELETE FROM `%splayers` WHERE %d - `lastconnect` > %d;", g_sDbPrefix, global_timer, iDays*86400);
					DB_TQuery(DB_Clear, s_Query, iDays);
					num_rows += 3;

					PrintToServer("[Shop] Clearing database from inactive players for more than %d %s!", iDays, (iDays == 1) ? "day" : "days");
				}
				
				iDays = -1;
			}
			else if (StrEqual(sDays, "deny", false))
			{
				iDays = -1;
				
				PrintToServer("[Shop] Database clear canceled!");
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
		
		int days = StringToInt(sDays);
		
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

public void DB_Clear(Database db, DBResultSet results, const char[] error, any data)
{
	if (num_rows) num_rows--;
	if (error[0])
	{
		LogError("DB_Clear %d: %s", data, error);
		return;
	}

	if (num_rows) return;
	if (data == 0)
	{
		DatabaseClear();
		PrintToServer("[Shop] Database is fully cleared!");
	}
	else
	{
		PrintToServer("[Shop] Database is cleared!");
	}
}

bool isLoading;
void DB_TryConnect()
{
	if (isLoading)
	{
		return;
	}
	if (h_db != null)
	{
		isLoading = false;
		return;
	}
	
	isLoading = true;
	
	PrintToServer("[Shop] Trying to connect!");
	
	if (SQL_CheckConfig("shop"))
	{
		Database.Connect(DB_Connect, "shop", 1);
	}
	else
	{
		char error[256];
		error[0] = '\0';
		
		h_db = SQLite_UseDatabase("shop", error, sizeof(error));
		
		DB_Connect(h_db, error, 2);
	}
}

public Action DB_ReconnectTimer(Handle timer)
{
	if (h_db == null)
	{
		DB_TryConnect();
	}
}

DataPack upgrade_dp;
DataPack insert_dp;
public void DB_Connect(Database db, const char[] error, any data)
{
	h_db = db;
	
	if (h_db == null)
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

	char driver[16];
	DBDriver dbdriver = db.Driver;
	dbdriver.GetIdentifier(driver, sizeof(driver));
	
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
	
	char s_Query[256];
	if (db_type == DB_MySQL)
	{
		DB_TQueryEx("SET NAMES 'utf8'");
		DB_TQueryEx("SET CHARSET 'utf8'");

		if (GetFeatureStatus(FeatureType_Native, "SQL_SetCharset") == FeatureStatus_Available)
		{
			h_db.SetCharset("utf8");
		}

		DB_TQuery(DB_GlobalTimer, "SELECT UNIX_TIMESTAMP()", _, DBPrio_High);
		
		h_db.Format(s_Query, sizeof(s_Query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '%sboughts';", g_sDbPrefix);
		DB_TQuery(DB_CheckTable, s_Query);
	}
	else
	{
		global_timer = GetTime();
		
		h_db.Format(s_Query, sizeof(s_Query), "PRAGMA TABLE_INFO(%sboughts);", g_sDbPrefix);
		DB_TQuery(DB_CheckTable, s_Query);
	}
}

public void DB_GlobalTimer(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0])
	{
		LogError("DB_GlobalTimer: %s", error);
	}
	
	if (results == null || !results.HasResults)
	{
		DB_TQuery(DB_GlobalTimer, "SELECT UNIX_TIMESTAMP()");
		return;
	}
	
	results.FetchRow();
	global_timer = results.FetchInt(0);
}

public void DB_CheckTable(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0])
	{
		LogError("DB_CheckTable: %s", error);
		delete h_db;
		h_db = null;
		CreateTimer(15.0, DB_ReconnectTimer);
		isLoading = false;
		return;
	}
	
	char s_Query[256];
	if (db_type == DB_MySQL)
	{
		if (!results.HasResults || !results.FetchRow() || results.FetchInt(0) < 1)
		{
			h_db.Format(s_Query, sizeof(s_Query), "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '%sitems';", g_sDbPrefix);
			DB_TQuery(DB_CheckTable2, s_Query);
			
			return;
		}
	}
	else if (!results.RowCount)
	{
		h_db.Format(s_Query, sizeof(s_Query), "PRAGMA TABLE_INFO(%sitems);", g_sDbPrefix);
		DB_TQuery(DB_CheckTable2, s_Query);
		
		return;
	}
	
	DB_RunBackup();
	
//	OnReadyToStart();
	DB_CreateTables();
}

public void DB_CheckTable2(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0])
	{
		LogError("DB_CheckTable2: %s", error);
		delete h_db;
		h_db = null;
		CreateTimer(15.0, DB_ReconnectTimer);
		isLoading = false;
		return;
	}
	
	if (results.RowCount > 0)
	{
		if (db_type == DB_MySQL)
		{
			if (results.FetchRow() && results.FetchInt(0) > 0)
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

void DB_CreateTables()
{
	char s_Query[512];
	if (db_type == DB_MySQL)
	{
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sboughts` (\
							  `player_id` int NOT NULL,\
							  `item_id` int NOT NULL,\
							  `count` int NOT NULL,\
							  `duration` int NOT NULL,\
							  `timeleft` int NOT NULL,\
							  `buy_price` int NOT NULL,\
							  `sell_price` int NOT NULL,\
							  `buy_time` int\
							) ENGINE=InnoDB DEFAULT CHARSET=utf8;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 1);
		
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sitems` (\
							  `id` int NOT NULL AUTO_INCREMENT,\
							  `category` varchar(64) NOT NULL,\
							  `item` varchar(64) NOT NULL,\
							  PRIMARY KEY (`id`)\
							) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 2);
		
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%splayers` (\
							  `id` int NOT NULL AUTO_INCREMENT,\
							  `name` varchar(32) NOT NULL DEFAULT 'unknown',\
							  `auth` varchar(22) NOT NULL,\
							  `money` int NOT NULL,\
							  `lastconnect` int,\
							  PRIMARY KEY (`id`), \
								UNIQUE KEY `auth` (`auth`) \
							) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 3);
		
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%stoggles` (\
							  `id` int NOT NULL AUTO_INCREMENT,\
							  `player_id` int NOT NULL,\
							  `item_id` int NOT NULL,\
							  `state` tinyint NOT NULL DEFAULT 0,\
							  PRIMARY KEY (`id`) \
							) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 4);
	}
	else
	{
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sboughts` (\
							  `player_id` NUMERIC NOT NULL,\
							  `item_id` INTEGER NOT NULL,\
							  `count` NUMERIC NOT NULL,\
							  `duration` INTEGER NOT NULL,\
							  `timeleft` NUMERIC NOT NULL,\
							  `buy_price` INTEGER NOT NULL,\
							  `sell_price` NUMERIC NOT NULL,\
							  `buy_time` NUMERIC NOT NULL);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 1);
		
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%sitems` (\
							  `id` INTEGER PRIMARY KEY AUTOINCREMENT,\
							  `category` VARCHAR NOT NULL,\
							  `item` VARCHAR NOT NULL);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 2);
		
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%splayers` (\
							  `id` INTEGER PRIMARY KEY AUTOINCREMENT,\
							  `name` VARCHAR DEFAULT 'unknown',\
							  `auth` VARCHAR UNIQUE ON CONFLICT IGNORE,\
							  `money` NUMERIC DEFAULT '0',\
							  `lastconnect` INTEGER NOT NULL);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 3);
		
		h_db.Format(s_Query, sizeof(s_Query), "CREATE TABLE IF NOT EXISTS `%stoggles` (\
							  `id` INTEGER PRIMARY KEY AUTOINCREMENT,\
							  `player_id` INTEGER NOT NULL,\
							  `item_id` INTEGER NOT NULL,\
							  `state` INTEGER NOT NULL DEFAULT 0);", g_sDbPrefix);
		DB_TQuery(DB_OnPlayersTableLoad, s_Query, 4);
	}
	
	isLoading = false;
}

public void DB_OnPlayersTableLoad(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0])
	{
		LogError("DB_OnPlayersTableLoad %d: %s", data, error);
		delete h_db;
		h_db = null;
		CreateTimer(15.0, DB_ReconnectTimer);
		return;
	}
	
	if (data != 4)
	{
		return;
	}
	
	if (db_type == DB_MySQL)
	{
		DB_TQueryEx("SET NAMES 'utf8'");
		DB_TQueryEx("SET CHARSET 'utf8'");
	}
	
	if (upgrade_dp != null)
	{
		DB_RunUpgrade();
	}
	else
	{
		OnReadyToStart();
	}
}

stock void DB_FastQuery(const char[] query)
{
	if (h_db == null)
	{
		DataPack dp = new DataPack();
		dp.WriteFunction(DB_ErrorCheck);
		dp.WriteString(query);
		dp.WriteCell(0);
		dp.WriteCell(view_as<int>(DBPrio_Normal));
		
		backup_dp.WriteCell(dp);
		
		return;
	}
	
	SQL_LockDatabase(h_db);
	SQL_FastQuery(h_db, query);
	SQL_UnlockDatabase(h_db);
}

void DB_TQuery(SQLQueryCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
	if (h_db == null)
	{
		DataPack dp = new DataPack();
		dp.WriteFunction(callback);
		dp.WriteString(query);
		dp.WriteCell(data);
		dp.WriteCell(prio);
		
		backup_dp.WriteCell(dp);
		
		return;
	}
	h_db.Query(callback, query, data, prio);
}

void DB_TQueryEx(const char[] query, DBPriority prio = DBPrio_Normal)
{
	if (h_db == null)
	{
		DataPack dp = new DataPack();
		dp.WriteFunction(DB_ErrorCheck);
		dp.WriteString(query);
		dp.WriteCell(0);
		dp.WriteCell(prio);
		
		backup_dp.WriteCell(dp);
		
		return;
	}
	h_db.Query(DB_ErrorCheck, query, _, prio);
}

void DB_EscapeString(const char[] string, char[] buffer, int maxlength, int &written=0)
{
	h_db.Escape(string, buffer, maxlength, written);
}

void DB_RunBackup()
{
	char buffer[256];
	DataPack dp;
	SQLQueryCallback callback;
	any data;
	DBPriority prio;
	
	backup_dp.Reset();
	while (IsPackReadable(backup_dp, 1))
	{
		dp = backup_dp.ReadCell();
		
		callback = view_as<SQLQueryCallback>(dp.ReadFunction());
		dp.ReadString(buffer, sizeof(buffer));
		data = dp.ReadCell();
		prio = view_as<DBPriority>(dp.ReadCell());
		
		delete dp;
		
		DB_TQuery(callback, buffer, data, prio);
	}
	backup_dp.Reset(true);
}

stock bool DB_IsConnected()
{
	return (h_db != null);
}

public void DB_ErrorCheck(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0])
	{
		LogError("DB_ErrorCheck: %s", error);
	}
}

void DB_UpgradeToNewVersion()
{
	PrintToServer("[Shop] Started upgrading to version 2!");
	
	char s_Query[256];
	
	if (db_type == DB_MySQL)
	{
		h_db.Format(s_Query, sizeof(s_Query), "ALTER IGNORE TABLE `%splayers` ADD `lastconnect` int(10) NOT NULL DEFAULT '0';", g_sDbPrefix);
	}
	else
	{
		h_db.Format(s_Query, sizeof(s_Query), "ALTER TABLE `%splayers` ADD `lastconnect` NUMERIC NOT NULL DEFAULT '0'", g_sDbPrefix);
	}
	DB_TQueryEx(s_Query);
	
	h_db.Format(s_Query, sizeof(s_Query), "SELECT * FROM `%sitems`;", g_sDbPrefix);
	DB_TQuery(DB_UgradeState_1, s_Query);
}

public void DB_UgradeState_1(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0])
	{
		LogError("DB_UgradeState_1: %s", error);
		DB_CreateTables();
		return;
	}
	
	PrintToServer("[Shop] Reading old tables...");
	
	upgrade_dp = new DataPack();
	insert_dp = new DataPack();
	
	bool got_categories;
	char category[64], item[64], buffer[2048], part[128];
	int id;
	while (results.FetchRow())
	{
		id = results.FetchInt(0);
		for (int i = 1; i < results.FieldCount; i++)
		{
			results.FieldNumToName(i, category, sizeof(category));
			
			if (!got_categories)
			{
				SQL_LockDatabase(h_db);
				h_db.Format(buffer, sizeof(buffer), "SELECT `item` FROM `%s`;", category);
				DBResultSet hQuery = SQL_Query(h_db, buffer);
				if (hQuery != null)
				{
					while (hQuery.FetchRow())
					{
						hQuery.FetchString(0, item, sizeof(item));
						
						h_db.Format(buffer, sizeof(buffer), "INSERT INTO `%sitems` (`category`, `item`) VALUES ('%s', '%s');", g_sDbPrefix, category, item);
						insert_dp.WriteString(buffer);
					}
					delete hQuery;
				}
				SQL_UnlockDatabase(h_db);
			}
			
			results.FetchString(i, buffer, sizeof(buffer));
			
			int num, item_id;
			char itemId[256], count[256], duration[256];
			
			int reloc_idx = 0, var2 = 0;
			while ((var2 = SplitString(buffer[reloc_idx], ",", part, sizeof(part))) != -1)
			{
				reloc_idx += var2;
				if (!part[0]) continue;
				
				int ture = FindCharInString(part, '-');
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
			
			for (int x = 0; x < num; x++)
			{
				h_db.Format(buffer, sizeof(buffer), "INSERT INTO `%sboughts` (`player_id`, `item_id`, `count`, `duration`, `timeleft`, `buy_price`, `sell_price`, `buy_time`) VALUES \
												('%d', (SELECT `id` FROM `%sitems` WHERE `category` = '%s' AND `item` = (SELECT `item` FROM `%s` WHERE `id` = '%d')), '%d', '%d', '%d', '0', '-1', '%d');", 
												g_sDbPrefix, id, g_sDbPrefix, category, category, itemId[x], count[itemId[x]], duration[itemId[x]], duration[itemId[x]], global_timer);
				upgrade_dp.WriteString(buffer);
			}
		}
		
		got_categories = true;
	}
	
	h_db.Format(buffer, sizeof(buffer), "DROP TABLE `%sitems`;", g_sDbPrefix);
	DB_TQueryEx(buffer, DBPrio_High);
	
	DB_CreateTables();
}

int num_queries;
void DB_RunUpgrade()
{
	PrintToServer("[Shop] Running queries...");
	
	char buffer[256];
	
	insert_dp.Reset();
	while (IsPackReadable(insert_dp, 1))
	{
		insert_dp.ReadString(buffer, sizeof(buffer));
		DB_TQuery(DB_UgradeState_2, buffer);
		num_queries++;
	}
	delete insert_dp;
	insert_dp = null;
}

int num_queries2;
public void DB_UgradeState_2(Database db, DBResultSet results, const char[] error, any data)
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
	
	char buffer[512];
	
	upgrade_dp.Reset();
	
	while (IsPackReadable(upgrade_dp, 1))
	{
		upgrade_dp.ReadString(buffer, sizeof(buffer));
		DB_TQuery(DB_UgradeState_3, buffer, DBPrio_High);
		num_queries2++;
	}
	
	delete upgrade_dp;
	upgrade_dp = null;
}

public void DB_UgradeState_3(Database db, DBResultSet results, const char[] error, any data)
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