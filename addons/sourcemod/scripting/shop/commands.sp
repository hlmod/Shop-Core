Commands_OnSettingsLoad(Handle:kv)
{
	if (KvJumpToKey(kv, "Commands", false))
	{
		decl String:buffer[SHOP_MAX_STRING_LENGTH];
		
		KvGetString(kv, "Give_Credits", buffer, sizeof(buffer));
		TrimString(buffer);
		RegConsoleCmd(buffer, Commands_GiveCredits, "How many credits to give to players");
		
		KvGetString(kv, "Take_Credits", buffer, sizeof(buffer));
		TrimString(buffer);
		RegConsoleCmd(buffer, Commands_TakeCredits, "How many credits to take from players");
		
		KvGetString(kv, "Set_Credits", buffer, sizeof(buffer));
		TrimString(buffer);
		RegConsoleCmd(buffer, Commands_SetCredits, "How many credits to set to players");
		
		KvGetString(kv, "Main_Menu", buffer, sizeof(buffer));
		TrimString(buffer);
		
		decl String:part[64];
		new reloc_idx, var2;
		new row;
		while ((var2 = SplitString(buffer[reloc_idx], ",", part, sizeof(part))))
		{
			//reloc_idx += var2;
			if (var2 == -1)
			{
				strcopy(part, sizeof(part), buffer[reloc_idx]);
			}
			else
			{
				reloc_idx += var2;
			}
			
			TrimString(part);
			
			if (!part[0])
			{
				continue;
			}
			
			if (!row)
			{
				new start;
				if (!StrContains(part, "sm_", true))
				{
					start = 3;
				}
				strcopy(g_sChatCommand, sizeof(g_sChatCommand), part[start]);
			}
			
			RegConsoleCmd(part, Commands_Shop, "Open up main menu");
			
			if (var2 == -1)
			{
				break;
			}
			
			row++;
		}
		
		KvRewind(kv);
	}
}

public Action:Commands_Shop(client, argc)
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

public Action:Commands_GiveCredits(client, args)
{
	if (client && !(GetUserFlagBits(client) & g_iAdminFlags))
	{
		CPrintToChat(client, "%t", "NoAccessToCommand");
		return Plugin_Handled;
	}
	decl String:buffer[96];
	if (args < 2)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <userid|name|uniqueid> <credits>", buffer);
		return Plugin_Handled;
	}
	
	decl String:pattern[96], String:money[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, money, sizeof(money));
	
	decl targets[MaxClients], bool:ml;
	
	new imoney = StringToInt(money);
	
	new count = ProcessTargetString(pattern, client, targets, MaxClients, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);
	
	if (count < 1)
	{
		if (client)
		{
			CPrintToChat(client, "%t", "TargetNotFound", pattern);
		}
	}
	else
	{
		for (new i = 0; i < count; i++)
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

public Action:Commands_TakeCredits(client, args)
{
	if (client && !(GetUserFlagBits(client) & g_iAdminFlags))
	{
		CPrintToChat(client, "%t", "NoAccessToCommand");
		return Plugin_Handled;
	}
	decl String:buffer[96];
	if (args < 2)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <userid|name|uniqueid> <credits>", buffer);
		return Plugin_Handled;
	}
	
	decl String:pattern[96], String:money[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, money, sizeof(money));
	
	decl targets[MaxClients], bool:ml;
	
	new imoney = StringToInt(money);
	
	new count = ProcessTargetString(pattern, client, targets, MaxClients, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);
	
	if (count < 1)
	{
		if (client)
		{
			CPrintToChat(client, "%t", "TargetNotFound", pattern);
		}
	}
	else
	{
		for (new i = 0; i < count; i++)
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

public Action:Commands_SetCredits(client, args)
{
	if (client && !(GetUserFlagBits(client) & g_iAdminFlags))
	{
		CPrintToChat(client, "%t", "NoAccessToCommand");
		return Plugin_Handled;
	}
	decl String:buffer[96];
	if (args < 2)
	{
		GetCmdArg(0, buffer, sizeof(buffer));
		ReplyToCommand(client, "Usage: %s <userid|name|uniqueid> <credits>", buffer);
		return Plugin_Handled;
	}
	
	decl String:pattern[96], String:money[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, money, sizeof(money));
	
	decl targets[MaxClients], bool:ml;
	
	new imoney = StringToInt(money);
	
	new count = ProcessTargetString(pattern, client, targets, MaxClients, COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);
	
	if (count < 1)
	{
		if (client)
		{
			CPrintToChat(client, "%t", "TargetNotFound", pattern);
		}
	}
	else
	{
		for (new i = 0; i < count; i++)
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