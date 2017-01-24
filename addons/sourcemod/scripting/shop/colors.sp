#include <regex>

void CPrintToChat(int client, const char[] sFormat, any ...)
{
	char sMessage[512];
	SetGlobalTransTarget(client);
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
			int iColor = ReplaceColors(sMessage, sizeof(sMessage));
			switch(iColor)
			{
				case -1:	SayText2(client, 0, sMessage);
				case 0:		SayText2(client, client, sMessage);
				default:
				{
					SayText2(client, FindPlayerByTeam(iColor), sMessage);
				}
			}
		}
		case GAME_CSS:
		{
			ReplaceString(sMessage, sizeof(sMessage), "#", "\x07");

			Regex hRegex;
			StringMap hColorsTrie;
	
			if(!hColorsTrie)
			{
				InitColors(hColorsTrie);
			}
	
			if(!hRegex)
			{
				hRegex = new Regex("{[a-zA-Z0-9]+}");
			}
			
			int iCursor = 0, iColor;
			char sColorName[32], sBuffer[32];
			
			while(hRegex.Match(sMessage[iCursor]))
			{
				hRegex.GetSubString(0, sColorName, sizeof(sColorName));
				iCursor = StrContains(sMessage[iCursor], sColorName, true) + iCursor + 1;
				CStrToLower(sColorName);
				strcopy(sBuffer, sizeof(sBuffer), sColorName[1]);
				sBuffer[strlen(sBuffer)-1] = 0;

				if(hColorsTrie.GetValue(sBuffer, iColor))
				{
					FormatEx(sBuffer, sizeof(sBuffer), "\x07%06X", iColor);
					ReplaceString(sMessage, sizeof(sMessage), sColorName, sBuffer, false);
				}
			}

			if(ReplaceString(sMessage, sizeof(sMessage), "{TEAM}", "\x03", false))
			{
				SayText2(client, client, sMessage);
			}
			else
			{
				ReplaceString(sMessage, sizeof(sMessage), "{LIGHTGREEN}", "\x03", false);
				SayText2(client, 0, sMessage);
			}
		}
		case GAME_CSGO:
		{
			static char sColorName[][] =
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
							sColorCode[][] =
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

			for(int i = 0; i < sizeof(sColorName); ++i)
			{
				ReplaceString(sMessage, sizeof(sMessage), sColorName[i], sColorCode[i], false);
			}

			if(ReplaceString(sMessage, sizeof(sMessage), "{TEAM}", "\x03", false))
			{
				SayText2(client, client, sMessage);
			}
			else
			{
				SayText2(client, 0, sMessage);
			}
		}
		default:
		{
			ReplaceString(sMessage, sizeof(sMessage), "#", "\x07");
			SayText2(client, 0, sMessage);
		}
	}
}

void CStrToLower(char[] sBuffer)
{
	int iLen, i;
	iLen = strlen(sBuffer);
	for(i = 0; i < iLen; ++i)
	{
		sBuffer[i] = CharToLower(sBuffer[i]);
	}
}

int ReplaceColors(char[] sMsg, int iMaxLength)
{
	if(ReplaceString(sMsg, iMaxLength, "{TEAM}",	"\x03", false))	return 0;

	if(ReplaceString(sMsg, iMaxLength, "{BLUE}",	"\x03", false))	return 3;
	if(ReplaceString(sMsg, iMaxLength, "{RED}",		"\x03", false))	return 2;
	if(ReplaceString(sMsg, iMaxLength, "{GRAY}",	"\x03", false))	return 1;

	return -1;
}

int FindPlayerByTeam(int iTeam)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == iTeam) return i;
	}

	return 0;
}

void SayText2(int client, int iAuthor = 0, const char[] sMessage)
{
	int[] clients = new int[1];
	clients[0] = client;
	
	Handle hBuffer;
	hBuffer = StartMessage("SayText2", clients, 1, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
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

void InitColors(StringMap &hColorsTrie)
{
	hColorsTrie = new StringMap();
	hColorsTrie.SetValue("aliceblue", 0xF0F8FF);
	hColorsTrie.SetValue("allies", 0x4D7942); // same as Allies team in DoD:S
	hColorsTrie.SetValue("antiquewhite", 0xFAEBD7);
	hColorsTrie.SetValue("aqua", 0x00FFFF);
	hColorsTrie.SetValue("aquamarine", 0x7FFFD4);
	hColorsTrie.SetValue("axis", 0xFF4040); // same as Axis team in DoD:S
	hColorsTrie.SetValue("azure", 0x007FFF);
	hColorsTrie.SetValue("beige", 0xF5F5DC);
	hColorsTrie.SetValue("bisque", 0xFFE4C4);
	hColorsTrie.SetValue("black", 0x000000);
	hColorsTrie.SetValue("blanchedalmond", 0xFFEBCD);
	hColorsTrie.SetValue("blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	hColorsTrie.SetValue("blueviolet", 0x8A2BE2);
	hColorsTrie.SetValue("brown", 0xA52A2A);
	hColorsTrie.SetValue("burlywood", 0xDEB887);
	hColorsTrie.SetValue("cadetblue", 0x5F9EA0);
	hColorsTrie.SetValue("chartreuse", 0x7FFF00);
	hColorsTrie.SetValue("chocolate", 0xD2691E);
	hColorsTrie.SetValue("community", 0x70B04A); // same as Community item quality in TF2
	hColorsTrie.SetValue("coral", 0xFF7F50);
	hColorsTrie.SetValue("cornflowerblue", 0x6495ED);
	hColorsTrie.SetValue("cornsilk", 0xFFF8DC);
	hColorsTrie.SetValue("crimson", 0xDC143C);
	hColorsTrie.SetValue("cyan", 0x00FFFF);
	hColorsTrie.SetValue("darkblue", 0x00008B);
	hColorsTrie.SetValue("darkcyan", 0x008B8B);
	hColorsTrie.SetValue("darkgoldenrod", 0xB8860B);
	hColorsTrie.SetValue("darkgray", 0xA9A9A9);
	hColorsTrie.SetValue("darkgreen", 0x006400);
	hColorsTrie.SetValue("darkkhaki", 0xBDB76B);
	hColorsTrie.SetValue("darkmagenta", 0x8B008B);
	hColorsTrie.SetValue("darkolivegreen", 0x556B2F);
	hColorsTrie.SetValue("darkorange", 0xFF8C00);
	hColorsTrie.SetValue("darkorchid", 0x9932CC);
	hColorsTrie.SetValue("darkred", 0x8B0000);
	hColorsTrie.SetValue("darksalmon", 0xE9967A);
	hColorsTrie.SetValue("darkseagreen", 0x8FBC8F);
	hColorsTrie.SetValue("darkslateblue", 0x483D8B);
	hColorsTrie.SetValue("darkslategray", 0x2F4F4F);
	hColorsTrie.SetValue("darkturquoise", 0x00CED1);
	hColorsTrie.SetValue("darkviolet", 0x9400D3);
	hColorsTrie.SetValue("deeppink", 0xFF1493);
	hColorsTrie.SetValue("deepskyblue", 0x00BFFF);
	hColorsTrie.SetValue("dimgray", 0x696969);
	hColorsTrie.SetValue("dodgerblue", 0x1E90FF);
	hColorsTrie.SetValue("firebrick", 0xB22222);
	hColorsTrie.SetValue("floralwhite", 0xFFFAF0);
	hColorsTrie.SetValue("forestgreen", 0x228B22);
	hColorsTrie.SetValue("fuchsia", 0xFF00FF);
	hColorsTrie.SetValue("fullblue", 0x0000FF);
	hColorsTrie.SetValue("fullred", 0xFF0000);
	hColorsTrie.SetValue("gainsboro", 0xDCDCDC);
	hColorsTrie.SetValue("genuine", 0x4D7455); // same as Genuine item quality in TF2
	hColorsTrie.SetValue("ghostwhite", 0xF8F8FF);
	hColorsTrie.SetValue("gold", 0xFFD700);
	hColorsTrie.SetValue("goldenrod", 0xDAA520);
	hColorsTrie.SetValue("gray", 0xCCCCCC); // same as spectator team color
	hColorsTrie.SetValue("grey", 0xCCCCCC);
	hColorsTrie.SetValue("green", 0x3EFF3E);
	hColorsTrie.SetValue("greenyellow", 0xADFF2F);
	hColorsTrie.SetValue("haunted", 0x38F3AB); // same as Haunted item quality in TF2
	hColorsTrie.SetValue("honeydew", 0xF0FFF0);
	hColorsTrie.SetValue("hotpink", 0xFF69B4);
	hColorsTrie.SetValue("indianred", 0xCD5C5C);
	hColorsTrie.SetValue("indigo", 0x4B0082);
	hColorsTrie.SetValue("ivory", 0xFFFFF0);
	hColorsTrie.SetValue("khaki", 0xF0E68C);
	hColorsTrie.SetValue("lavender", 0xE6E6FA);
	hColorsTrie.SetValue("lavenderblush", 0xFFF0F5);
	hColorsTrie.SetValue("lawngreen", 0x7CFC00);
	hColorsTrie.SetValue("lemonchiffon", 0xFFFACD);
	hColorsTrie.SetValue("lightblue", 0xADD8E6);
	hColorsTrie.SetValue("lightcoral", 0xF08080);
	hColorsTrie.SetValue("lightcyan", 0xE0FFFF);
	hColorsTrie.SetValue("lightgoldenrodyellow", 0xFAFAD2);
	hColorsTrie.SetValue("lightgray", 0xD3D3D3);
	hColorsTrie.SetValue("lightgreen", 0x99FF99);
	hColorsTrie.SetValue("lightpink", 0xFFB6C1);
	hColorsTrie.SetValue("lightsalmon", 0xFFA07A);
	hColorsTrie.SetValue("lightseagreen", 0x20B2AA);
	hColorsTrie.SetValue("lightskyblue", 0x87CEFA);
	hColorsTrie.SetValue("lightslategray", 0x778899);
	hColorsTrie.SetValue("lightsteelblue", 0xB0C4DE);
	hColorsTrie.SetValue("lightyellow", 0xFFFFE0);
	hColorsTrie.SetValue("lime", 0x00FF00);
	hColorsTrie.SetValue("limegreen", 0x32CD32);
	hColorsTrie.SetValue("linen", 0xFAF0E6);
	hColorsTrie.SetValue("magenta", 0xFF00FF);
	hColorsTrie.SetValue("maroon", 0x800000);
	hColorsTrie.SetValue("mediumaquamarine", 0x66CDAA);
	hColorsTrie.SetValue("mediumblue", 0x0000CD);
	hColorsTrie.SetValue("mediumorchid", 0xBA55D3);
	hColorsTrie.SetValue("mediumpurple", 0x9370D8);
	hColorsTrie.SetValue("mediumseagreen", 0x3CB371);
	hColorsTrie.SetValue("mediumslateblue", 0x7B68EE);
	hColorsTrie.SetValue("mediumspringgreen", 0x00FA9A);
	hColorsTrie.SetValue("mediumturquoise", 0x48D1CC);
	hColorsTrie.SetValue("mediumvioletred", 0xC71585);
	hColorsTrie.SetValue("midnightblue", 0x191970);
	hColorsTrie.SetValue("mintcream", 0xF5FFFA);
	hColorsTrie.SetValue("mistyrose", 0xFFE4E1);
	hColorsTrie.SetValue("moccasin", 0xFFE4B5);
	hColorsTrie.SetValue("navajowhite", 0xFFDEAD);
	hColorsTrie.SetValue("navy", 0x000080);
	hColorsTrie.SetValue("normal", 0xB2B2B2); // same as Normal item quality in TF2
	hColorsTrie.SetValue("oldlace", 0xFDF5E6);
	hColorsTrie.SetValue("olive", 0x9EC34F);
	hColorsTrie.SetValue("olivedrab", 0x6B8E23);
	hColorsTrie.SetValue("orange", 0xFFA500);
	hColorsTrie.SetValue("orangered", 0xFF4500);
	hColorsTrie.SetValue("orchid", 0xDA70D6);
	hColorsTrie.SetValue("palegoldenrod", 0xEEE8AA);
	hColorsTrie.SetValue("palegreen", 0x98FB98);
	hColorsTrie.SetValue("paleturquoise", 0xAFEEEE);
	hColorsTrie.SetValue("palevioletred", 0xD87093);
	hColorsTrie.SetValue("papayawhip", 0xFFEFD5);
	hColorsTrie.SetValue("peachpuff", 0xFFDAB9);
	hColorsTrie.SetValue("peru", 0xCD853F);
	hColorsTrie.SetValue("pink", 0xFFC0CB);
	hColorsTrie.SetValue("plum", 0xDDA0DD);
	hColorsTrie.SetValue("powderblue", 0xB0E0E6);
	hColorsTrie.SetValue("purple", 0x800080);
	hColorsTrie.SetValue("red", 0xFF4040); // same as RED/Terrorist team color
	hColorsTrie.SetValue("rosybrown", 0xBC8F8F);
	hColorsTrie.SetValue("royalblue", 0x4169E1);
	hColorsTrie.SetValue("saddlebrown", 0x8B4513);
	hColorsTrie.SetValue("salmon", 0xFA8072);
	hColorsTrie.SetValue("sandybrown", 0xF4A460);
	hColorsTrie.SetValue("seagreen", 0x2E8B57);
	hColorsTrie.SetValue("seashell", 0xFFF5EE);
	hColorsTrie.SetValue("selfmade", 0x70B04A); // same as Self-Made item quality in TF2
	hColorsTrie.SetValue("sienna", 0xA0522D);
	hColorsTrie.SetValue("silver", 0xC0C0C0);
	hColorsTrie.SetValue("skyblue", 0x87CEEB);
	hColorsTrie.SetValue("slateblue", 0x6A5ACD);
	hColorsTrie.SetValue("slategray", 0x708090);
	hColorsTrie.SetValue("snow", 0xFFFAFA);
	hColorsTrie.SetValue("springgreen", 0x00FF7F);
	hColorsTrie.SetValue("steelblue", 0x4682B4);
	hColorsTrie.SetValue("strange", 0xCF6A32); // same as Strange item quality in TF2
	hColorsTrie.SetValue("tan", 0xD2B48C);
	hColorsTrie.SetValue("teal", 0x008080);
	hColorsTrie.SetValue("thistle", 0xD8BFD8);
	hColorsTrie.SetValue("tomato", 0xFF6347);
	hColorsTrie.SetValue("turquoise", 0x40E0D0);
	hColorsTrie.SetValue("unique", 0xFFD700); // same as Unique item quality in TF2
	hColorsTrie.SetValue("unusual", 0x8650AC); // same as Unusual item quality in TF2
	hColorsTrie.SetValue("valve", 0xA50F79); // same as Valve item quality in TF2
	hColorsTrie.SetValue("vintage", 0x476291); // same as Vintage item quality in TF2
	hColorsTrie.SetValue("violet", 0xEE82EE);
	hColorsTrie.SetValue("wheat", 0xF5DEB3);
	hColorsTrie.SetValue("white", 0xFFFFFF);
	hColorsTrie.SetValue("whitesmoke", 0xF5F5F5);
	hColorsTrie.SetValue("yellow", 0xFFFF00);
	hColorsTrie.SetValue("yellowgreen", 0x9ACD32);
}