stock bool:Helpers_IsPluginValid(Handle:plugin)
{
	/* Check if the plugin handle is pointing to a valid plugin. */
	new Handle:hIterator = GetPluginIterator();
	new bool:bIsValid = false;
	
	while (MorePlugins(hIterator))
	{
		if (plugin == ReadPlugin(hIterator))
		{
			bIsValid = true;
			break;
		}
	}
	
	CloseHandle(hIterator);
	return bIsValid;
}

stock bool:Helpers_CheckClient(client, String:error[], length)
{
	if (client < 1 || client > MaxClients)
	{
		FormatEx(error, length, "Client index %i is invalid", client);
		return false;
	}
	else if (!IsClientInGame(client))
	{
		FormatEx(error, length, "Client index %i is not in game", client);
		return false;
	}
	else if (IsFakeClient(client))
	{
		FormatEx(error, length, "Client index %i is a bot", client);
		return false;
	}
	
	error[0] = '\0';
	
	return true;
}

stock Helpers_GetTimeFromStamp(String:buffer[], maxlength, timestamp, source_client = LANG_SERVER)
{
	if (timestamp > 31536000)
	{
		new years = timestamp / 31536000;
		new days = timestamp / 86400 % 365;
		if (days > 0)
		{
			FormatEx(buffer, maxlength, "%d%T %d%T", years, "y.", source_client, days, "d.", source_client);
		}
		else
		{
			FormatEx(buffer, maxlength, "%d%T", years, "y.");
		}
		return;
	}
	if (timestamp > 86400)
	{
		new days = timestamp / 86400 % 365;
		new hours = (timestamp / 3600) % 24;
		if (hours > 0)
		{
			FormatEx(buffer, maxlength, "%d%T %d%T", days, "d.", source_client, hours, "h.", source_client);
		}
		else
		{
			FormatEx(buffer, maxlength, "%d%T", days, "d.", source_client);
		}
		return;
	}
	else
	{
		new Hours = (timestamp / 3600);
		new Mins = (timestamp / 60) % 60;
		new Secs = timestamp % 60;
		
		if (Hours > 0)
		{
			FormatEx(buffer, maxlength, "%02d:%02d:%02d", Hours, Mins, Secs);
		}
		else
		{
			FormatEx(buffer, maxlength, "%02d:%02d", Mins, Secs);
		}
	}
}

stock bool:Helpers_AddTargetsToMenu(Handle:menu, source_client, bool:credits = false)
{
	new bool:result = false;
	
	decl String:userid[9], String:buffer[MAX_NAME_LENGTH+21];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsAuthorizedIn(i) && (i == source_client || CanUserTarget(source_client, i)))
		{
			IntToString(GetClientUserId(i), userid, sizeof(userid));
			if (credits)
			{
				FormatEx(buffer, sizeof(buffer), "%N (%d)", i, GetCredits(i));
			}
			else
			{
				GetClientName(i, buffer, sizeof(buffer));
			}
			
			AddMenuItem(menu, userid, buffer);
			
			result = true;
		}
	}
	
	return result;
}

stock Helpers_GetRandomIntEx(min, max)
{
	new random = GetURandomInt();
	
	if (!random)
		random++;
		
	new number = RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
	
	return number;
}