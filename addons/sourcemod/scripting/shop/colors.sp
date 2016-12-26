#include <regex>

CPrintToChat(iClient, const String:sFormat[], any:...)
{
	decl String:sMessage[512];
	SetGlobalTransTarget(iClient);
	VFormat(sMessage, sizeof(sMessage), sFormat, 3);

	Format(sMessage, sizeof(sMessage), Engine_Version == GAME_CSGO ? " \x01%s":"\x01%s", sMessage);
	
	ReplaceString(sMessage, sizeof(sMessage), "\\n", "\n");
	ReplaceString(sMessage, sizeof(sMessage), "{DEFAULT}", "\x01", false);
	ReplaceString(sMessage, sizeof(sMessage), "{GREEN}", "\x04", false);
	
	switch(Engine_Version)
	{
		case GAME_CSS_34:
		{
			ReplaceString(sMessage, sizeof(sMessage), "{LIGHTGREEN}", "\x03", false);
			new iColor = ReplaceColors(sMessage, sizeof(sMessage));
			switch(iColor)
			{
				case -1:	SayText2(iClient, 0, sMessage);
				case 0:		SayText2(iClient, iClient, sMessage);
				default:
				{
					SayText2(iClient, FindPlayerByTeam(iColor), sMessage);
				}
			}
		}
		case GAME_CSS:
		{
			ReplaceString(sMessage, sizeof(sMessage), "#", "\x07");

			static Handle:hRegex, Handle:hColorsTrie;
	
			if(!hColorsTrie)
			{
				hColorsTrie = InitColors();
			}
	
			if(!hRegex)
			{
				hRegex = CompileRegex("{[a-zA-Z0-9]+}");
			}

			decl String:sColorName[32], iCursor, iColor, String:sBuffer[32];
			iCursor = 0;
			while(MatchRegex(hRegex, sMessage[iCursor]))
			{
				GetRegexSubString(hRegex, 0, sColorName, sizeof(sColorName));
				iCursor = StrContains(sMessage[iCursor], sColorName, true) + iCursor + 1;
				CStrToLower(sColorName);
				strcopy(sBuffer, sizeof(sBuffer), sColorName[1]);
				sBuffer[strlen(sBuffer)-1] = 0;

				if(GetTrieValue(hColorsTrie, sBuffer, iColor))
				{
					FormatEx(sBuffer, sizeof(sBuffer), "\x07%06X", iColor);
					ReplaceString(sMessage, sizeof(sMessage), sColorName, sBuffer, false);
				}
			}

			if(ReplaceString(sMessage, sizeof(sMessage), "{TEAM}", "\x03", false))
			{
				SayText2(iClient, iClient, sMessage);
			}
			else
			{
				ReplaceString(sMessage, sizeof(sMessage), "{LIGHTGREEN}", "\x03", false);
				SayText2(iClient, 0, sMessage);
			}
		}
		case GAME_CSGO:
		{
			static const	String:sColorName[][] =
							{
								"{RED}",
								"{LIME}",
								"{LIGHTGREEN}",
								"{LIGHTRED}",
								"{GRAY}",
								"{LIGHTOLIVE}",
								"{OLIVE}",
								"{LIGHTBLUE}",
								"{BLUE}", 
								"{PURPLE}"
							},
							String:sColorCode[][] =
							{
								"\x02",
							    "\x05",
							    "\x06",
							    "\x07",
							    "\x08",
							    "\x09",
							    "\x10",
							    "\x0B",
							    "\x0C",
							    "\x0E"
							};

			for(new i = 0; i < sizeof(sColorName); ++i)
			{
				ReplaceString(sMessage, sizeof(sMessage), sColorName[i], sColorCode[i], false);
			}

			if(ReplaceString(sMessage, sizeof(sMessage), "{TEAM}", "\x03", false))
			{
				SayText2(iClient, iClient, sMessage);
			}
			else
			{
				SayText2(iClient, 0, sMessage);
			}
		}
		default:
		{
			ReplaceString(sMessage, sizeof(sMessage), "#", "\x07");
			SayText2(iClient, 0, sMessage);
		}
	}
}

CStrToLower(String:sBuffer[])
{
	decl iLen, i;
	iLen = strlen(sBuffer);
	for(i = 0; i < iLen; ++i)
	{
		sBuffer[i] = CharToLower(sBuffer[i]);
	}
}

ReplaceColors(String:sMsg[], iMaxLength)
{
	if(ReplaceString(sMsg, iMaxLength, "{TEAM}",	"\x03", false))	return 0;

	if(ReplaceString(sMsg, iMaxLength, "{BLUE}",	"\x03", false))	return 3;
	if(ReplaceString(sMsg, iMaxLength, "{RED}",		"\x03", false))	return 2;
	if(ReplaceString(sMsg, iMaxLength, "{GRAY}",	"\x03", false))	return 1;

	return -1;
}

FindPlayerByTeam(iTeam)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == iTeam) return i;
	}

	return 0;
}

SayText2(iClient, iAuthor = 0, const String:sMessage[])
{
	decl iClients[1], Handle:hBuffer;
	iClients[0] = iClient;
	hBuffer = StartMessage("SayText2", iClients, 1, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(Engine_Version == GAME_CSGO)
	{
		PbSetInt(hBuffer, "ent_idx", iAuthor);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", sMessage);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	}
	else
	{
		BfWriteByte(hBuffer, iAuthor);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, sMessage);
	}
	EndMessage();
}

Handle:InitColors()
{
	new Handle:hColorsTrie = CreateTrie();
	SetTrieValue(hColorsTrie, "aliceblue", 0xF0F8FF);
	SetTrieValue(hColorsTrie, "allies", 0x4D7942); // same as Allies team in DoD:S
	SetTrieValue(hColorsTrie, "antiquewhite", 0xFAEBD7);
	SetTrieValue(hColorsTrie, "aqua", 0x00FFFF);
	SetTrieValue(hColorsTrie, "aquamarine", 0x7FFFD4);
	SetTrieValue(hColorsTrie, "axis", 0xFF4040); // same as Axis team in DoD:S
	SetTrieValue(hColorsTrie, "azure", 0x007FFF);
	SetTrieValue(hColorsTrie, "beige", 0xF5F5DC);
	SetTrieValue(hColorsTrie, "bisque", 0xFFE4C4);
	SetTrieValue(hColorsTrie, "black", 0x000000);
	SetTrieValue(hColorsTrie, "blanchedalmond", 0xFFEBCD);
	SetTrieValue(hColorsTrie, "blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	SetTrieValue(hColorsTrie, "blueviolet", 0x8A2BE2);
	SetTrieValue(hColorsTrie, "brown", 0xA52A2A);
	SetTrieValue(hColorsTrie, "burlywood", 0xDEB887);
	SetTrieValue(hColorsTrie, "cadetblue", 0x5F9EA0);
	SetTrieValue(hColorsTrie, "chartreuse", 0x7FFF00);
	SetTrieValue(hColorsTrie, "chocolate", 0xD2691E);
	SetTrieValue(hColorsTrie, "community", 0x70B04A); // same as Community item quality in TF2
	SetTrieValue(hColorsTrie, "coral", 0xFF7F50);
	SetTrieValue(hColorsTrie, "cornflowerblue", 0x6495ED);
	SetTrieValue(hColorsTrie, "cornsilk", 0xFFF8DC);
	SetTrieValue(hColorsTrie, "crimson", 0xDC143C);
	SetTrieValue(hColorsTrie, "cyan", 0x00FFFF);
	SetTrieValue(hColorsTrie, "darkblue", 0x00008B);
	SetTrieValue(hColorsTrie, "darkcyan", 0x008B8B);
	SetTrieValue(hColorsTrie, "darkgoldenrod", 0xB8860B);
	SetTrieValue(hColorsTrie, "darkgray", 0xA9A9A9);
	SetTrieValue(hColorsTrie, "darkgreen", 0x006400);
	SetTrieValue(hColorsTrie, "darkkhaki", 0xBDB76B);
	SetTrieValue(hColorsTrie, "darkmagenta", 0x8B008B);
	SetTrieValue(hColorsTrie, "darkolivegreen", 0x556B2F);
	SetTrieValue(hColorsTrie, "darkorange", 0xFF8C00);
	SetTrieValue(hColorsTrie, "darkorchid", 0x9932CC);
	SetTrieValue(hColorsTrie, "darkred", 0x8B0000);
	SetTrieValue(hColorsTrie, "darksalmon", 0xE9967A);
	SetTrieValue(hColorsTrie, "darkseagreen", 0x8FBC8F);
	SetTrieValue(hColorsTrie, "darkslateblue", 0x483D8B);
	SetTrieValue(hColorsTrie, "darkslategray", 0x2F4F4F);
	SetTrieValue(hColorsTrie, "darkturquoise", 0x00CED1);
	SetTrieValue(hColorsTrie, "darkviolet", 0x9400D3);
	SetTrieValue(hColorsTrie, "deeppink", 0xFF1493);
	SetTrieValue(hColorsTrie, "deepskyblue", 0x00BFFF);
	SetTrieValue(hColorsTrie, "dimgray", 0x696969);
	SetTrieValue(hColorsTrie, "dodgerblue", 0x1E90FF);
	SetTrieValue(hColorsTrie, "firebrick", 0xB22222);
	SetTrieValue(hColorsTrie, "floralwhite", 0xFFFAF0);
	SetTrieValue(hColorsTrie, "forestgreen", 0x228B22);
	SetTrieValue(hColorsTrie, "fuchsia", 0xFF00FF);
	SetTrieValue(hColorsTrie, "fullblue", 0x0000FF);
	SetTrieValue(hColorsTrie, "fullred", 0xFF0000);
	SetTrieValue(hColorsTrie, "gainsboro", 0xDCDCDC);
	SetTrieValue(hColorsTrie, "genuine", 0x4D7455); // same as Genuine item quality in TF2
	SetTrieValue(hColorsTrie, "ghostwhite", 0xF8F8FF);
	SetTrieValue(hColorsTrie, "gold", 0xFFD700);
	SetTrieValue(hColorsTrie, "goldenrod", 0xDAA520);
	SetTrieValue(hColorsTrie, "gray", 0xCCCCCC); // same as spectator team color
	SetTrieValue(hColorsTrie, "grey", 0xCCCCCC);
	SetTrieValue(hColorsTrie, "green", 0x3EFF3E);
	SetTrieValue(hColorsTrie, "greenyellow", 0xADFF2F);
	SetTrieValue(hColorsTrie, "haunted", 0x38F3AB); // same as Haunted item quality in TF2
	SetTrieValue(hColorsTrie, "honeydew", 0xF0FFF0);
	SetTrieValue(hColorsTrie, "hotpink", 0xFF69B4);
	SetTrieValue(hColorsTrie, "indianred", 0xCD5C5C);
	SetTrieValue(hColorsTrie, "indigo", 0x4B0082);
	SetTrieValue(hColorsTrie, "ivory", 0xFFFFF0);
	SetTrieValue(hColorsTrie, "khaki", 0xF0E68C);
	SetTrieValue(hColorsTrie, "lavender", 0xE6E6FA);
	SetTrieValue(hColorsTrie, "lavenderblush", 0xFFF0F5);
	SetTrieValue(hColorsTrie, "lawngreen", 0x7CFC00);
	SetTrieValue(hColorsTrie, "lemonchiffon", 0xFFFACD);
	SetTrieValue(hColorsTrie, "lightblue", 0xADD8E6);
	SetTrieValue(hColorsTrie, "lightcoral", 0xF08080);
	SetTrieValue(hColorsTrie, "lightcyan", 0xE0FFFF);
	SetTrieValue(hColorsTrie, "lightgoldenrodyellow", 0xFAFAD2);
	SetTrieValue(hColorsTrie, "lightgray", 0xD3D3D3);
	SetTrieValue(hColorsTrie, "lightgreen", 0x99FF99);
	SetTrieValue(hColorsTrie, "lightpink", 0xFFB6C1);
	SetTrieValue(hColorsTrie, "lightsalmon", 0xFFA07A);
	SetTrieValue(hColorsTrie, "lightseagreen", 0x20B2AA);
	SetTrieValue(hColorsTrie, "lightskyblue", 0x87CEFA);
	SetTrieValue(hColorsTrie, "lightslategray", 0x778899);
	SetTrieValue(hColorsTrie, "lightsteelblue", 0xB0C4DE);
	SetTrieValue(hColorsTrie, "lightyellow", 0xFFFFE0);
	SetTrieValue(hColorsTrie, "lime", 0x00FF00);
	SetTrieValue(hColorsTrie, "limegreen", 0x32CD32);
	SetTrieValue(hColorsTrie, "linen", 0xFAF0E6);
	SetTrieValue(hColorsTrie, "magenta", 0xFF00FF);
	SetTrieValue(hColorsTrie, "maroon", 0x800000);
	SetTrieValue(hColorsTrie, "mediumaquamarine", 0x66CDAA);
	SetTrieValue(hColorsTrie, "mediumblue", 0x0000CD);
	SetTrieValue(hColorsTrie, "mediumorchid", 0xBA55D3);
	SetTrieValue(hColorsTrie, "mediumpurple", 0x9370D8);
	SetTrieValue(hColorsTrie, "mediumseagreen", 0x3CB371);
	SetTrieValue(hColorsTrie, "mediumslateblue", 0x7B68EE);
	SetTrieValue(hColorsTrie, "mediumspringgreen", 0x00FA9A);
	SetTrieValue(hColorsTrie, "mediumturquoise", 0x48D1CC);
	SetTrieValue(hColorsTrie, "mediumvioletred", 0xC71585);
	SetTrieValue(hColorsTrie, "midnightblue", 0x191970);
	SetTrieValue(hColorsTrie, "mintcream", 0xF5FFFA);
	SetTrieValue(hColorsTrie, "mistyrose", 0xFFE4E1);
	SetTrieValue(hColorsTrie, "moccasin", 0xFFE4B5);
	SetTrieValue(hColorsTrie, "navajowhite", 0xFFDEAD);
	SetTrieValue(hColorsTrie, "navy", 0x000080);
	SetTrieValue(hColorsTrie, "normal", 0xB2B2B2); // same as Normal item quality in TF2
	SetTrieValue(hColorsTrie, "oldlace", 0xFDF5E6);
	SetTrieValue(hColorsTrie, "olive", 0x9EC34F);
	SetTrieValue(hColorsTrie, "olivedrab", 0x6B8E23);
	SetTrieValue(hColorsTrie, "orange", 0xFFA500);
	SetTrieValue(hColorsTrie, "orangered", 0xFF4500);
	SetTrieValue(hColorsTrie, "orchid", 0xDA70D6);
	SetTrieValue(hColorsTrie, "palegoldenrod", 0xEEE8AA);
	SetTrieValue(hColorsTrie, "palegreen", 0x98FB98);
	SetTrieValue(hColorsTrie, "paleturquoise", 0xAFEEEE);
	SetTrieValue(hColorsTrie, "palevioletred", 0xD87093);
	SetTrieValue(hColorsTrie, "papayawhip", 0xFFEFD5);
	SetTrieValue(hColorsTrie, "peachpuff", 0xFFDAB9);
	SetTrieValue(hColorsTrie, "peru", 0xCD853F);
	SetTrieValue(hColorsTrie, "pink", 0xFFC0CB);
	SetTrieValue(hColorsTrie, "plum", 0xDDA0DD);
	SetTrieValue(hColorsTrie, "powderblue", 0xB0E0E6);
	SetTrieValue(hColorsTrie, "purple", 0x800080);
	SetTrieValue(hColorsTrie, "red", 0xFF4040); // same as RED/Terrorist team color
	SetTrieValue(hColorsTrie, "rosybrown", 0xBC8F8F);
	SetTrieValue(hColorsTrie, "royalblue", 0x4169E1);
	SetTrieValue(hColorsTrie, "saddlebrown", 0x8B4513);
	SetTrieValue(hColorsTrie, "salmon", 0xFA8072);
	SetTrieValue(hColorsTrie, "sandybrown", 0xF4A460);
	SetTrieValue(hColorsTrie, "seagreen", 0x2E8B57);
	SetTrieValue(hColorsTrie, "seashell", 0xFFF5EE);
	SetTrieValue(hColorsTrie, "selfmade", 0x70B04A); // same as Self-Made item quality in TF2
	SetTrieValue(hColorsTrie, "sienna", 0xA0522D);
	SetTrieValue(hColorsTrie, "silver", 0xC0C0C0);
	SetTrieValue(hColorsTrie, "skyblue", 0x87CEEB);
	SetTrieValue(hColorsTrie, "slateblue", 0x6A5ACD);
	SetTrieValue(hColorsTrie, "slategray", 0x708090);
	SetTrieValue(hColorsTrie, "snow", 0xFFFAFA);
	SetTrieValue(hColorsTrie, "springgreen", 0x00FF7F);
	SetTrieValue(hColorsTrie, "steelblue", 0x4682B4);
	SetTrieValue(hColorsTrie, "strange", 0xCF6A32); // same as Strange item quality in TF2
	SetTrieValue(hColorsTrie, "tan", 0xD2B48C);
	SetTrieValue(hColorsTrie, "teal", 0x008080);
	SetTrieValue(hColorsTrie, "thistle", 0xD8BFD8);
	SetTrieValue(hColorsTrie, "tomato", 0xFF6347);
	SetTrieValue(hColorsTrie, "turquoise", 0x40E0D0);
	SetTrieValue(hColorsTrie, "unique", 0xFFD700); // same as Unique item quality in TF2
	SetTrieValue(hColorsTrie, "unusual", 0x8650AC); // same as Unusual item quality in TF2
	SetTrieValue(hColorsTrie, "valve", 0xA50F79); // same as Valve item quality in TF2
	SetTrieValue(hColorsTrie, "vintage", 0x476291); // same as Vintage item quality in TF2
	SetTrieValue(hColorsTrie, "violet", 0xEE82EE);
	SetTrieValue(hColorsTrie, "wheat", 0xF5DEB3);
	SetTrieValue(hColorsTrie, "white", 0xFFFFFF);
	SetTrieValue(hColorsTrie, "whitesmoke", 0xF5F5F5);
	SetTrieValue(hColorsTrie, "yellow", 0xFFFF00);
	SetTrieValue(hColorsTrie, "yellowgreen", 0x9ACD32);
	
	return hColorsTrie;
}