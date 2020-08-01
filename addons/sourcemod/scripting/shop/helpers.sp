stock bool Helpers_IsPluginValid(Handle plugin)
{
	/* Check if the plugin handle is pointing to a valid plugin. */
	Handle hIterator = GetPluginIterator();
	bool bIsValid = false;
	
	while (MorePlugins(hIterator))
	{
		if (plugin == ReadPlugin(hIterator))
		{
			bIsValid = (GetPluginStatus(plugin) == Plugin_Running);
			break;
		}
	}
	
	delete hIterator;
	return bIsValid;
}

stock bool Helpers_CheckClient(int client, char[] error, int length)
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

stock void Helpers_GetTimeFromStamp(char[] buffer, int maxlength, int timestamp, int source_client = LANG_SERVER)
{
	if (timestamp > 31536000)
	{
		int years = timestamp / 31536000;
		int days = timestamp / 86400 % 365;
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
		int days = timestamp / 86400 % 365;
		int hours = (timestamp / 3600) % 24;
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
		int Hours = (timestamp / 3600);
		int Mins = (timestamp / 60) % 60;
		int Secs = timestamp % 60;
		
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

stock bool Helpers_AddTargetsToMenu(Menu menu, int source_client, bool credits = false)
{
	bool result = false;
	
	char userid[9], buffer[MAX_NAME_LENGTH+21];
	for (int i = 1; i <= MaxClients; i++)
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
			
			menu.AddItem(userid, buffer);
			
			result = true;
		}
	}
	
	return result;
}

stock int Helpers_GetRandomIntEx(int min, int max)
{
	int random = GetURandomInt();
	
	if (!random)
		random++;
		
	int number = RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
	
	return number;
}

/**
 * Makes a negative integer number to a positive integer number.
 * This is faster than Sourcemod's native FloatAbs() for integers.
 * Use FloatAbs() for Float numbers.
 *
 * @param number		A number that can be positive or negative.
 * @return				Positive number.
 */
stock int Helpers_Math_Abs(int value)
{
	return (value ^ (value >> 31)) - (value >> 31);
}

/**
 * 
 */
void Helpers_ClearArrayWithChatReason(ArrayList hArray, int client, const char[] str)
{
	delete hArray;
	CPrintToChat(client, "%t", str);
}
