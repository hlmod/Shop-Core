void Commands_OnSettingsLoad(KeyValues kv)
{
	if (kv.JumpToKey("Commands", false))
	{
		char buffer[SHOP_MAX_STRING_LENGTH];
		
		kv.GetString("Give_Credits", buffer, sizeof(buffer));
		TrimString(buffer);
		RegConsoleCmd(buffer, Commands_GiveCredits, "How many credits to give to players");
		
		kv.GetString("Take_Credits", buffer, sizeof(buffer));
		TrimString(buffer);
		RegConsoleCmd(buffer, Commands_TakeCredits, "How many credits to take from players");
		
		kv.GetString("Set_Credits", buffer, sizeof(buffer));
		TrimString(buffer);
		RegConsoleCmd(buffer, Commands_SetCredits, "How many credits to set to players");
		
		kv.GetString("Main_Menu", buffer, sizeof(buffer));
		TrimString(buffer);
		
		char part[64];
		int reloc_idx, var2;
		int row;
		while ((var2 = SplitString(buffer[reloc_idx], ",", part, sizeof(part))))
		{
			if (var2 == -1)
				strcopy(part, sizeof(part), buffer[reloc_idx]);
			else
				reloc_idx += var2;
			
			TrimString(part);
			
			if (!part[0])
				continue;
			
			if (!row)
			{
				int start;
				if (!StrContains(part, "sm_", true))
				{
					start = 3;
				}
				strcopy(g_sChatCommand, sizeof(g_sChatCommand), part[start]);
			}
			
			RegConsoleCmd(part, Commands_Shop, "Open up main menu");
			
			if (var2 == -1)
				break;
			
			row++;
		}
		
		kv.Rewind();
	}
}

public Action Commands_Shop(int client, int args)
{
	if (!client)
	{
		return Plugin_Continue;
	}
	
	if (!IsAuthorizedIn(client))
	{
		CPrintToChat(client, "%t", "DataLoading");
		return Plugin_Handled;
	}
	
	ShowMainMenu(client);
	
	return Plugin_Handled;
}

public Action Commands_GiveCredits(int client, int args)
{
	if (client && !(GetUserFlagBits(client) & g_iAdminFlags))
	{
		CPrintToChat(client, "%t", "NoAccessToCommand");
		return Plugin_Handled;
	}
	char buffer[96];
	if (args < 2)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <userid|name|uniqueid> <credits>", buffer);
		return Plugin_Handled;
	}
	
	char pattern[96], money[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, money, sizeof(money));
	
	int[] targets = new int[MaxClients];
	bool ml;
	
	int imoney = StringToInt(money);
	
	int count = ProcessTargetString(pattern, client, targets, MaxClients, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);
	
	if (count < 1)
	{
		if (client)
		{
			CPrintToChat(client, "%t", "TargetNotFound", pattern);
		}
	}
	else
	{
		for (int i = 0; i < count; i++)
		{
			if (targets[i] != client && !CanUserTarget(client, targets[i])) continue;
			
			GiveCredits(targets[i], imoney, client);
		}
		if (ml)
		{
			Format(buffer, sizeof(buffer), "%T", buffer, client);
		}
		if (client)
		{
			CPrintToChat(client, "%t", "give_credits_success", imoney, buffer);
		}
	}
	
	return Plugin_Handled;
}

public Action Commands_TakeCredits(int client, int args)
{
	if (client && !(GetUserFlagBits(client) & g_iAdminFlags))
	{
		CPrintToChat(client, "%t", "NoAccessToCommand");
		return Plugin_Handled;
	}
	char buffer[96];
	if (args < 2)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <userid|name|uniqueid> <credits>", buffer);
		return Plugin_Handled;
	}
	
	char pattern[96], money[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, money, sizeof(money));
	
	int[] targets = new int[MaxClients];
	bool ml;
	
	int imoney = StringToInt(money);
	
	int count = ProcessTargetString(pattern, client, targets, MaxClients, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);
	
	if (count < 1)
	{
		if (client)
		{
			CPrintToChat(client, "%t", "TargetNotFound", pattern);
		}
	}
	else
	{
		for (int i = 0; i < count; i++)
		{
			if (targets[i] != client && !CanUserTarget(client, targets[i])) continue;
			
			RemoveCredits(targets[i], imoney, client);
		}
		if (ml)
		{
			Format(buffer, sizeof(buffer), "%T", buffer, client);
		}
		if (client)
		{
			CPrintToChat(client, "%t", "remove_credits_success", imoney, buffer);
		}
	}
	
	return Plugin_Handled;
}

public Action Commands_SetCredits(int client, int args)
{
	if (client && !(GetUserFlagBits(client) & g_iAdminFlags))
	{
		CPrintToChat(client, "%t", "NoAccessToCommand");
		return Plugin_Handled;
	}
	char buffer[96];
	if (args < 2)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <userid|name|uniqueid> <credits>", buffer);
		return Plugin_Handled;
	}
	
	char pattern[96], money[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, money, sizeof(money));
	
	int[] targets = new int[MaxClients];
	bool ml;
	
	int imoney = StringToInt(money);
	
	int count = ProcessTargetString(pattern, client, targets, MaxClients, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);
	
	if (count < 1)
	{
		if (client)
		{
			CPrintToChat(client, "%t", "TargetNotFound", pattern);
		}
	}
	else
	{
		for (int i = 0; i < count; i++)
		{
			if (targets[i] != client && !CanUserTarget(client, targets[i])) continue;
			
			SetCredits(targets[i], imoney, true);
		}
		if (ml)
		{
			Format(buffer, sizeof(buffer), "%T", buffer, client);
		}
		if (client)
		{
			CPrintToChat(client, "%t", "set_credits_success", imoney, buffer);
		}
	}
	
	return Plugin_Handled;
}