stock const char API_KEY[] = "e34fa2f3adb922bf76fb7b06807caa3c";
stock const char URL[] = "http://stats.tibari.ru/api/v1/add_server";

/* Stats pusher */
public int SteamWorks_SteamServersConnected()
{
	int iIp[4];
	
	// Get ip
	if (SteamWorks_GetPublicIP(iIp))
	{
		Handle plugin = GetMyHandle();
		if (GetPluginStatus(plugin) == Plugin_Running)
		{
			char cBuffer[256], cVersion[12];
			GetPluginInfo(plugin, PlInfo_Version, cVersion, sizeof(cVersion));
			FormatEx(cBuffer, sizeof(cBuffer), "%s", URL);
			Handle hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, cBuffer);
			FormatEx(cBuffer, sizeof(cBuffer), "key=%s&ip=%d.%d.%d.%d&port=%d&version=%s", API_KEY, iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, cVersion);
			SteamWorks_SetHTTPRequestRawPostBody(hndl, "application/x-www-form-urlencoded", cBuffer, sizeof(cBuffer));
			SteamWorks_SendHTTPRequest(hndl);
			delete hndl;
		}
	}
}
