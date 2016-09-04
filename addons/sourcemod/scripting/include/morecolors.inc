// MOAR COLORS
// By Dr. McKay ( Edited by Str1k3r )
// Inspired by: https://forums.alliedmods.net/showthread.php?t=96831

#if defined _colors_included
 #endinput
#endif
#define _colors_included

#include <regex>

#define MORE_COLORS_VERSION		"2.0"
#define MAX_MESSAGE_LENGTH		256

#define COLOR_RED				0xFF4040
#define COLOR_BLUE				0x99CCFF
#define COLOR_GRAY				0xCCCCCC
#define COLOR_GREEN				0x3EFF3E

#define GAME_DODS				0

#define MAX_COLORS 6

#define SERVER_INDEX 0
#define NO_INDEX -1
#define NO_PLAYER -2

enum Colors
{
 	Color_Default = 0,
	Color_Green,
	Color_Lightgreen,
	Color_Red,
	Color_Blue,
	Color_Olive
}

new String:CTag[][] = {"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
new String:CTagCode[][] = {"\x01", "\x04", "\x03", "\x03", "\x03", "\x05"};
new bool:CTagReqSayText2[] = {false, false, true, true, true, false};
new bool:CEventIsHooked = false;
new bool:CProfile_Colors[] = {true, true, false, false, false, false};
new CProfile_TeamIndex[] = {NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX};
new bool:CProfile_SayText2 = false;

new bool:CSkipList[MAXPLAYERS + 1];
new Handle:CTrie;
new CTeamColors[][] = {{0xCCCCCC, 0x4D7942, 0xFF4040}}; // Multi-dimensional array for games that don't support SayText2. First index is the game index (as defined by the GAME_ defines), second index is team. 0 = spectator, 1 = team1, 2 = team2

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client is not connected an error will be thrown.
 */
stock CPrintToChat(client, const String:message[], any:...) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	decl String:sGame[30];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "cstrike") && FindConVar("sv_shutdown_timeout_minutes") != INVALID_HANDLE)
	{
		CCheckTrie();
		decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 3);
		CReplaceColorCodes(buffer2);
		CSendMessage(client, buffer2);
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		decl String:szCMessage[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		Format(szBuffer, sizeof(szBuffer), "\x01%s", message);
		VFormat(szCMessage, sizeof(szCMessage), szBuffer, 3);
		
		new index = CFormat(szCMessage, sizeof(szCMessage));
		if (index == NO_INDEX)
		{
			PrintToChat(client, szCMessage);
		}
		else
		{
			CSendMessage(client, szCMessage, index);
			//CSayText2(client, index, szCMessage);
		}
	}
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 * 
 * @param client		Client index.
 * @param message		Message (formatting rules).
 * @noreturn
 */
stock CPrintToChatAll(const String:message[], any:...) {
	decl String:sGame[30];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "cstrike") && FindConVar("sv_shutdown_timeout_minutes") != INVALID_HANDLE)
	{
		CCheckTrie();
		decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
		for(new i = 1; i <= MaxClients; i++) {
			if(!IsClientInGame(i) || CSkipList[i]) {
				CSkipList[i] = false;
				continue;
			}
			SetGlobalTransTarget(i);
			Format(buffer, sizeof(buffer), "\x01%s", message);
			VFormat(buffer2, sizeof(buffer2), buffer, 2);
			CReplaceColorCodes(buffer2);
			CSendMessage(i, buffer2);
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i])
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), message, 2);
				CPrintToChat(i, szBuffer);
			}
			
			CSkipList[i] = false;
		}
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags and teamcolor tag.
 * 
 * @param client		Client index.
 * @param author		Author index whose color will be used for teamcolor tag.
 * @param message		Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:		If the client or author are not connected an error will be thrown
 */
stock CPrintToChatEx(client, author, const String:message[], any:...) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	if(author <= 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}
	if(!IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}
	decl String:sGame[30];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "csgo") && FindConVar("sv_shutdown_timeout_minutes") != INVALID_HANDLE)
	{
		CCheckTrie();
		decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		Format(buffer, sizeof(buffer), "\x01%s", message);
		VFormat(buffer2, sizeof(buffer2), buffer, 4);
		CReplaceColorCodes(buffer2, author);
		CSendMessage(client, buffer2, author);
	}
	else if (StrEqual(sGame, "csgo"))
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		decl String:szCMessage[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		Format(szBuffer, sizeof(szBuffer), "\x01%s", message);
		VFormat(szCMessage, sizeof(szCMessage), szBuffer, 4);
		
		new index = CFormat(szCMessage, sizeof(szCMessage), author);
		if (index == NO_INDEX)
		{
			PrintToChat(client, szCMessage);
		}
		else
		{
			CSendMessage(client, szCMessage, author);
			//CSayText2(client, author, szCMessage);
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
		decl String:szCMessage[MAX_MESSAGE_LENGTH];
		SetGlobalTransTarget(client);
		Format(szBuffer, sizeof(szBuffer), "\x01%s", message);
		VFormat(szCMessage, sizeof(szCMessage), szBuffer, 4);
		
		new index = CFormat(szCMessage, sizeof(szCMessage), author);
		if (index == NO_INDEX)
		{
			PrintToChat(client, szCMessage);
		}
		else
		{
			CSendMessage(client, szCMessage, author);
			//CSayText2(client, author, szCMessage);
		}
	}
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags and teamcolor tag.
 *
 * @param author	  Author index whose color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 * @noreturn
 * 
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock CPrintToChatAllEx(author, const String:message[], any:...) {
	if(author <= 0 || author > MaxClients) {
		ThrowError("Invalid client index %i", author);
	}
	if(!IsClientInGame(author)) {
		ThrowError("Client %i is not in game", author);
	}
	decl String:sGame[30];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "csgo") && FindConVar("sv_shutdown_timeout_minutes") != INVALID_HANDLE)
	{
		CCheckTrie();
		decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
		for(new i = 1; i <= MaxClients; i++) {
			if(!IsClientInGame(i) || IsFakeClient(i) || CSkipList[i]) {
				CSkipList[i] = false;
				continue;
			}
			SetGlobalTransTarget(i);
			Format(buffer, sizeof(buffer), "\x01%s", message);
			VFormat(buffer2, sizeof(buffer2), buffer, 3);
			CReplaceColorCodes(buffer2, author);
			CSendMessage(i, buffer2, author);
		}
	}
	else if (StrEqual(sGame, "csgo"))
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i])
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), message, 3);
				CPrintToChatEx(i, author, szBuffer);
			}
			
			CSkipList[i] = false;
		}
	}
	else
	{
		decl String:szBuffer[MAX_MESSAGE_LENGTH];
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i])
			{
				SetGlobalTransTarget(i);
				VFormat(szBuffer, sizeof(szBuffer), message, 3);
				CPrintToChatEx(i, author, szBuffer);
			}
			
			CSkipList[i] = false;
		}
	}
}

/**
 * Sends a SayText2 usermessage
 * 
 * @param client	Client to send usermessage to
 * @param message	Message to send
 * @noreturn
 */
stock CSendMessage(client, const String:message[], author=0) {
	if(author == 0) {
		author = client;
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:game[16];
	GetGameFolderName(game, sizeof(game));
	strcopy(buffer, sizeof(buffer), message);
	new UserMsg:index = GetUserMessageId("SayText2");
	if(index == INVALID_MESSAGE_ID) {
		if (StrEqual(game, "csgo") || (!StrEqual(game, "csgo") && FindConVar("sv_shutdown_timeout_minutes") == INVALID_HANDLE)) {
			//ReplaceCodes2(buffer, sizeof(buffer));
			ReplaceString(buffer, sizeof(buffer), "{black}", "", false);
			ReplaceString(buffer, sizeof(buffer), "{yellow}", "", false);
			ReplaceString(buffer, sizeof(buffer), "{white}", "", false);
			ReplaceString(buffer, sizeof(buffer), "{orange}", "", false);
		}
		else if(StrEqual(game, "dod")) {
			new team = GetClientTeam(author);
			if(team == 0) {
				ReplaceString(buffer, sizeof(buffer), "\x03", "\x04", false); // Unassigned gets green
			} else {
				decl String:temp[16];
				Format(temp, sizeof(temp), "\x07%06X", CTeamColors[GAME_DODS][team - 1]);
				ReplaceString(buffer, sizeof(buffer), "\x03", temp, false);
			}
		}
		PrintToChat(client, "%s", buffer);
		return;
	}
	else if (StrEqual(game, "csgo") || (!StrEqual(game, "csgo") && FindConVar("sv_shutdown_timeout_minutes") == INVALID_HANDLE))
	{
		ReplaceString(buffer, sizeof(buffer), "{black}", "", false);
		ReplaceString(buffer, sizeof(buffer), "{yellow}", "", false);
		ReplaceString(buffer, sizeof(buffer), "{white}", "", false);
		ReplaceString(buffer, sizeof(buffer), "{orange}", "", false);
		PrintToChat(client, "%s", buffer);
		return;
	}
	new Handle:buf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		PbSetInt(buf, "ent_idx", author);
		PbSetBool(buf, "chat", true);
		PbSetString(buf, "msg_name", buffer);
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
		PbAddString(buf, "params", "");
	} else {
		BfWriteByte(buf, author); // Message author
		BfWriteByte(buf, true); // Chat message
		BfWriteString(buf, buffer); // Message text
	}
	EndMessage();
}

/**
 * This function should only be used right in front of
 * CPrintToChatAll or CPrintToChatAllEx. It causes those functions
 * to skip the specified client when printing the message.
 * After printing the message, the client will no longer be skipped.
 * 
 * @param client   Client index
 * @noreturn
 */
stock CSkipNextClient(client) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	CSkipList[client] = true;
}

/**
 * Checks if the colors trie is initialized and initializes it if it's not (used internally)
 * 
 * @return			No return
 */
stock CCheckTrie() {
	if(CTrie == INVALID_HANDLE) {
		CTrie = InitColorTrie();
	}
}

/**
 * Replaces color tags in a string with color codes (used internally by CPrintToChat, CPrintToChatAll, CPrintToChatEx, and CPrintToChatAllEx
 *
 * @param buffer		String.
 * @param author		Optional client index to use for {teamcolor} tags, or 0 for none
 * @param removeTags	Optional boolean value to determine whether we're replacing tags with colors, or just removing tags, used by CRemoveTags
 * @param maxlen		Optional value for max buffer length, used by CRemoveTags
 * @noreturn
 * 
 * On error/Errors:		If the client index passed for author is invalid or not in game.
 */
stock CReplaceColorCodes(String:buffer[], author=0, bool:removeTags=false, maxlen=MAX_MESSAGE_LENGTH) {
	CCheckTrie();
	if(!removeTags) {
		ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	} else {
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}
	if(author != 0 && !removeTags) {
		if(author < 0 || author > MaxClients) {
			ThrowError("Invalid client index %i", author);
		}
		if(!IsClientInGame(author)) {
			ThrowError("Client %i is not in game", author);
		}
		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	}
	new cursor = 0;
	new value;
	decl String:tag[32], String:buff[32], String:output[maxlen];
	strcopy(output, maxlen, buffer);
	// Since the string's size is going to be changing, output will hold the replaced string and we'll search buffer
	
	new Handle:regex = CompileRegex("{[a-zA-Z0-9]+}");
	for(new i = 0; i < 1000; i++) { // The RegEx extension is quite flaky, so we have to loop here :/. This loop is supposed to be infinite and broken by return, but conditions have been added to be safe.
		if(MatchRegex(regex, buffer[cursor]) < 1) {
			CloseHandle(regex);
			strcopy(buffer, maxlen, output);
			return;
		}
		GetRegexSubString(regex, 0, tag, sizeof(tag));
		CStrToLower(tag);
		cursor = StrContains(buffer[cursor], tag, false) + cursor + 1;
		strcopy(buff, sizeof(buff), tag);
		ReplaceString(buff, sizeof(buff), "{", "");
		ReplaceString(buff, sizeof(buff), "}", "");
		
		if(!GetTrieValue(CTrie, buff, value)) {
			continue;
		}
		
		if(removeTags) {
			ReplaceString(output, maxlen, tag, "", false);
		} else {
			Format(buff, sizeof(buff), "\x07%06X", value);
			ReplaceString(output, maxlen, tag, buff, false);
		}
	}
	LogError("[MORE COLORS] Infinite loop broken.");
}

/**
 * Gets a part of a string
 * 
 * @param input			String to get the part from
 * @param output		Buffer to write to
 * @param maxlen		Max length of output buffer
 * @param start			Position to start at
 * @param numChars		Number of characters to return, or 0 for the end of the string
 * @noreturn
 */
stock CSubString(const String:input[], String:output[], maxlen, start, numChars=0) {
	new i = 0;
	for(;;) {
		if(i == maxlen - 1 || i >= numChars || input[start + i] == '\0') {
			output[i] = '\0';
			return;
		}
		output[i] = input[start + i];
		i++;
	}
}

/**
 * Converts a string to lowercase
 * 
 * @param buffer		String to convert
 * @noreturn
 */
stock CStrToLower(String:buffer[]) {
	new len = strlen(buffer);
	for(new i = 0; i < len; i++) {
		buffer[i] = CharToLower(buffer[i]);
	}
}

/**
 * Adds a color to the colors trie
 *
 * @param name			Color name, without braces
 * @param color			Hexadecimal representation of the color (0xRRGGBB)
 * @return				True if color was added successfully, false if a color already exists with that name
 */
stock bool:CAddColor(const String:name[], color) {
	CCheckTrie();
	new value;
	if(GetTrieValue(CTrie, name, value)) {
		return false;
	}
	decl String:newName[64];
	strcopy(newName, sizeof(newName), name);
	CStrToLower(newName);
	SetTrieValue(CTrie, newName, color);
	return true;
}

/**
 * Removes color tags from a message
 * 
 * @param message		Message to remove tags from
 * @param maxlen		Maximum buffer length
 * @noreturn
 */
stock CRemoveTags(String:message[], maxlength) {
	decl String:sGame[30];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "csgo") && FindConVar("sv_shutdown_timeout_minutes") != INVALID_HANDLE)
	{
		CReplaceColorCodes(message, 0, true, maxlength);
	}
	else if (StrEqual(sGame, "csgo"))
	{
		for (new i = 0; i < MAX_COLORS; i++)
		{
			ReplaceString(message, maxlength, CTag[i], "", false);
		}
	
		ReplaceString(message, maxlength, "{teamcolor}", "");
	}
	else
	{
		for (new i = 0; i < MAX_COLORS; i++)
		{
			ReplaceString(message, maxlength, CTag[i], "", false);
		}
	
		ReplaceString(message, maxlength, "{teamcolor}", "");
	}
}

/**
 * Replies to a command with colors
 * 
 * @param client		Client to reply to
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CReplyToCommand(client, const String:message[], any:...) {
	decl String:buffer[MAX_MESSAGE_LENGTH * 2];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 3);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, buffer);
	} else {
		CPrintToChat(client, buffer);
	}
}

/**
 * Replies to a command with colors
 * 
 * @param client		Client to reply to
 * @param author		Client to use for {teamcolor}
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CReplyToCommandEx(client, author, const String:message[], any:...) {
	decl String:buffer[MAX_MESSAGE_LENGTH * 2];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), message, 4);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, buffer);
	} else {
		CPrintToChatEx(client, author, buffer);
	}
}

/**
 * Shows admin activity with colors
 * 
 * @param client		Client performing an action
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CShowActivity(client, const String:message[], any:...) {
	CCheckTrie();
	if(client < 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}
	if(client != 0 && !IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	CReplaceColorCodes(buffer2);
	ShowActivity(client, "%s", buffer2);
}

/**
 * Shows admin activity with colors
 * 
 * @param client		Client performing an action
 * @param tag			Tag to prepend to the message (color tags supported)
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CShowActivityEx(client, const String:tag[], const String:message[], any:...) {
	CCheckTrie();
	if(client < 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}
	if(client != 0 && !IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2);
	strcopy(buffer, sizeof(buffer), tag);
	CReplaceColorCodes(buffer);
	ShowActivityEx(client, tag, "%s", buffer2);
}

/**
 * Shows admin activity with colors
 * 
 * @param client		Client performing an action
 * @param tag			Tag to prepend to the message (color tags supported)
 * @param message		Message (formatting rules)
 * @noreturn
 */
stock CShowActivity2(client, const String:tag[], const String:message[], any:...) {
	CCheckTrie();
	if(client < 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
	}
	if(client != 0 && !IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
	}
	decl String:buffer[MAX_MESSAGE_LENGTH], String:buffer2[MAX_MESSAGE_LENGTH];
	Format(buffer, sizeof(buffer), "\x01%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 4);
	CReplaceColorCodes(buffer2);
	strcopy(buffer, sizeof(buffer), tag);
	CReplaceColorCodes(buffer);
	ShowActivity2(client, buffer, "%s", buffer2);
}

/**
 * Determines whether a color name exists
 * 
 * @param color			The color name to check
 * @return				True if the color exists, false otherwise
 */
stock bool:CColorExists(const String:color[]) {
	CCheckTrie();
	return GetTrieValue(CTrie, color, 0);
}

/**
 * Returns the hexadecimal representation of a client's team color (will NOT initialize the trie)
 *
 * @param client		Client to get the team color for
 * @return				Client's team color in hexadecimal, or green if unknown
 * On error/Errors:		If the client index passed is invalid or not in game.
 */
stock CGetTeamColor(client) {
	if(client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %i", client);
	}
	if(!IsClientInGame(client)) {
		ThrowError("Client %i is not in game", client);
	}
	new value;
	switch(GetClientTeam(client)) {
		case 1: {
			value = COLOR_GRAY;
		}
		case 2: {
			value = COLOR_RED;
		}
		case 3: {
			value = COLOR_BLUE;
		}
		default: {
			value = COLOR_GREEN;
		}
	}
	return value;
}

stock Handle:InitColorTrie() {
	new Handle:hTrie = CreateTrie();
	SetTrieValue(hTrie, "aliceblue", 0xF0F8FF);
	SetTrieValue(hTrie, "allies", 0x4D7942); // same as Allies team in DoD:S
	SetTrieValue(hTrie, "antiquewhite", 0xFAEBD7);
	SetTrieValue(hTrie, "aqua", 0x00FFFF);
	SetTrieValue(hTrie, "aquamarine", 0x7FFFD4);
	SetTrieValue(hTrie, "axis", 0xFF4040); // same as Axis team in DoD:S
	SetTrieValue(hTrie, "azure", 0x007FFF);
	SetTrieValue(hTrie, "beige", 0xF5F5DC);
	SetTrieValue(hTrie, "bisque", 0xFFE4C4);
	SetTrieValue(hTrie, "black", 0x000000);
	SetTrieValue(hTrie, "blanchedalmond", 0xFFEBCD);
	SetTrieValue(hTrie, "blue", 0x99CCFF); // same as BLU/Counter-Terrorist team color
	SetTrieValue(hTrie, "blueviolet", 0x8A2BE2);
	SetTrieValue(hTrie, "brown", 0xA52A2A);
	SetTrieValue(hTrie, "burlywood", 0xDEB887);
	SetTrieValue(hTrie, "cadetblue", 0x5F9EA0);
	SetTrieValue(hTrie, "chartreuse", 0x7FFF00);
	SetTrieValue(hTrie, "chocolate", 0xD2691E);
	SetTrieValue(hTrie, "community", 0x70B04A); // same as Community item quality in TF2
	SetTrieValue(hTrie, "coral", 0xFF7F50);
	SetTrieValue(hTrie, "cornflowerblue", 0x6495ED);
	SetTrieValue(hTrie, "cornsilk", 0xFFF8DC);
	SetTrieValue(hTrie, "crimson", 0xDC143C);
	SetTrieValue(hTrie, "cyan", 0x00FFFF);
	SetTrieValue(hTrie, "darkblue", 0x00008B);
	SetTrieValue(hTrie, "darkcyan", 0x008B8B);
	SetTrieValue(hTrie, "darkgoldenrod", 0xB8860B);
	SetTrieValue(hTrie, "darkgray", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgrey", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgreen", 0x006400);
	SetTrieValue(hTrie, "darkkhaki", 0xBDB76B);
	SetTrieValue(hTrie, "darkmagenta", 0x8B008B);
	SetTrieValue(hTrie, "darkolivegreen", 0x556B2F);
	SetTrieValue(hTrie, "darkorange", 0xFF8C00);
	SetTrieValue(hTrie, "darkorchid", 0x9932CC);
	SetTrieValue(hTrie, "darkred", 0x8B0000);
	SetTrieValue(hTrie, "darksalmon", 0xE9967A);
	SetTrieValue(hTrie, "darkseagreen", 0x8FBC8F);
	SetTrieValue(hTrie, "darkslateblue", 0x483D8B);
	SetTrieValue(hTrie, "darkslategray", 0x2F4F4F);
	SetTrieValue(hTrie, "darkslategrey", 0x2F4F4F);
	SetTrieValue(hTrie, "darkturquoise", 0x00CED1);
	SetTrieValue(hTrie, "darkviolet", 0x9400D3);
	SetTrieValue(hTrie, "deeppink", 0xFF1493);
	SetTrieValue(hTrie, "deepskyblue", 0x00BFFF);
	SetTrieValue(hTrie, "dimgray", 0x696969);
	SetTrieValue(hTrie, "dimgrey", 0x696969);
	SetTrieValue(hTrie, "dodgerblue", 0x1E90FF);
	SetTrieValue(hTrie, "firebrick", 0xB22222);
	SetTrieValue(hTrie, "floralwhite", 0xFFFAF0);
	SetTrieValue(hTrie, "forestgreen", 0x228B22);
	SetTrieValue(hTrie, "fuchsia", 0xFF00FF);
	SetTrieValue(hTrie, "fullblue", 0x0000FF);
	SetTrieValue(hTrie, "fullred", 0xFF0000);
	SetTrieValue(hTrie, "gainsboro", 0xDCDCDC);
	SetTrieValue(hTrie, "genuine", 0x4D7455); // same as Genuine item quality in TF2
	SetTrieValue(hTrie, "ghostwhite", 0xF8F8FF);
	SetTrieValue(hTrie, "gold", 0xFFD700);
	SetTrieValue(hTrie, "goldenrod", 0xDAA520);
	SetTrieValue(hTrie, "gray", 0xCCCCCC); // same as spectator team color
	SetTrieValue(hTrie, "grey", 0xCCCCCC);
	SetTrieValue(hTrie, "green", 0x3EFF3E);
	SetTrieValue(hTrie, "greenyellow", 0xADFF2F);
	SetTrieValue(hTrie, "haunted", 0x38F3AB); // same as Haunted item quality in TF2
	SetTrieValue(hTrie, "honeydew", 0xF0FFF0);
	SetTrieValue(hTrie, "hotpink", 0xFF69B4);
	SetTrieValue(hTrie, "indianred", 0xCD5C5C);
	SetTrieValue(hTrie, "indigo", 0x4B0082);
	SetTrieValue(hTrie, "ivory", 0xFFFFF0);
	SetTrieValue(hTrie, "khaki", 0xF0E68C);
	SetTrieValue(hTrie, "lavender", 0xE6E6FA);
	SetTrieValue(hTrie, "lavenderblush", 0xFFF0F5);
	SetTrieValue(hTrie, "lawngreen", 0x7CFC00);
	SetTrieValue(hTrie, "lemonchiffon", 0xFFFACD);
	SetTrieValue(hTrie, "lightblue", 0xADD8E6);
	SetTrieValue(hTrie, "lightcoral", 0xF08080);
	SetTrieValue(hTrie, "lightcyan", 0xE0FFFF);
	SetTrieValue(hTrie, "lightgoldenrodyellow", 0xFAFAD2);
	SetTrieValue(hTrie, "lightgray", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgrey", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgreen", 0x99FF99);
	SetTrieValue(hTrie, "lightpink", 0xFFB6C1);
	SetTrieValue(hTrie, "lightsalmon", 0xFFA07A);
	SetTrieValue(hTrie, "lightseagreen", 0x20B2AA);
	SetTrieValue(hTrie, "lightskyblue", 0x87CEFA);
	SetTrieValue(hTrie, "lightslategray", 0x778899);
	SetTrieValue(hTrie, "lightslategrey", 0x778899);
	SetTrieValue(hTrie, "lightsteelblue", 0xB0C4DE);
	SetTrieValue(hTrie, "lightyellow", 0xFFFFE0);
	SetTrieValue(hTrie, "lime", 0x00FF00);
	SetTrieValue(hTrie, "limegreen", 0x32CD32);
	SetTrieValue(hTrie, "linen", 0xFAF0E6);
	SetTrieValue(hTrie, "magenta", 0xFF00FF);
	SetTrieValue(hTrie, "maroon", 0x800000);
	SetTrieValue(hTrie, "mediumaquamarine", 0x66CDAA);
	SetTrieValue(hTrie, "mediumblue", 0x0000CD);
	SetTrieValue(hTrie, "mediumorchid", 0xBA55D3);
	SetTrieValue(hTrie, "mediumpurple", 0x9370D8);
	SetTrieValue(hTrie, "mediumseagreen", 0x3CB371);
	SetTrieValue(hTrie, "mediumslateblue", 0x7B68EE);
	SetTrieValue(hTrie, "mediumspringgreen", 0x00FA9A);
	SetTrieValue(hTrie, "mediumturquoise", 0x48D1CC);
	SetTrieValue(hTrie, "mediumvioletred", 0xC71585);
	SetTrieValue(hTrie, "midnightblue", 0x191970);
	SetTrieValue(hTrie, "mintcream", 0xF5FFFA);
	SetTrieValue(hTrie, "mistyrose", 0xFFE4E1);
	SetTrieValue(hTrie, "moccasin", 0xFFE4B5);
	SetTrieValue(hTrie, "navajowhite", 0xFFDEAD);
	SetTrieValue(hTrie, "navy", 0x000080);
	SetTrieValue(hTrie, "normal", 0xB2B2B2); // same as Normal item quality in TF2
	SetTrieValue(hTrie, "oldlace", 0xFDF5E6);
	SetTrieValue(hTrie, "olive", 0x9EC34F);
	SetTrieValue(hTrie, "olivedrab", 0x6B8E23);
	SetTrieValue(hTrie, "orange", 0xFFA500);
	SetTrieValue(hTrie, "orangered", 0xFF4500);
	SetTrieValue(hTrie, "orchid", 0xDA70D6);
	SetTrieValue(hTrie, "palegoldenrod", 0xEEE8AA);
	SetTrieValue(hTrie, "palegreen", 0x98FB98);
	SetTrieValue(hTrie, "paleturquoise", 0xAFEEEE);
	SetTrieValue(hTrie, "palevioletred", 0xD87093);
	SetTrieValue(hTrie, "papayawhip", 0xFFEFD5);
	SetTrieValue(hTrie, "peachpuff", 0xFFDAB9);
	SetTrieValue(hTrie, "peru", 0xCD853F);
	SetTrieValue(hTrie, "pink", 0xFFC0CB);
	SetTrieValue(hTrie, "plum", 0xDDA0DD);
	SetTrieValue(hTrie, "powderblue", 0xB0E0E6);
	SetTrieValue(hTrie, "purple", 0x800080);
	SetTrieValue(hTrie, "red", 0xFF4040); // same as RED/Terrorist team color
	SetTrieValue(hTrie, "rosybrown", 0xBC8F8F);
	SetTrieValue(hTrie, "royalblue", 0x4169E1);
	SetTrieValue(hTrie, "saddlebrown", 0x8B4513);
	SetTrieValue(hTrie, "salmon", 0xFA8072);
	SetTrieValue(hTrie, "sandybrown", 0xF4A460);
	SetTrieValue(hTrie, "seagreen", 0x2E8B57);
	SetTrieValue(hTrie, "seashell", 0xFFF5EE);
	SetTrieValue(hTrie, "selfmade", 0x70B04A); // same as Self-Made item quality in TF2
	SetTrieValue(hTrie, "sienna", 0xA0522D);
	SetTrieValue(hTrie, "silver", 0xC0C0C0);
	SetTrieValue(hTrie, "skyblue", 0x87CEEB);
	SetTrieValue(hTrie, "slateblue", 0x6A5ACD);
	SetTrieValue(hTrie, "slategray", 0x708090);
	SetTrieValue(hTrie, "slategrey", 0x708090);
	SetTrieValue(hTrie, "snow", 0xFFFAFA);
	SetTrieValue(hTrie, "springgreen", 0x00FF7F);
	SetTrieValue(hTrie, "steelblue", 0x4682B4);
	SetTrieValue(hTrie, "strange", 0xCF6A32); // same as Strange item quality in TF2
	SetTrieValue(hTrie, "tan", 0xD2B48C);
	SetTrieValue(hTrie, "teal", 0x008080);
	SetTrieValue(hTrie, "thistle", 0xD8BFD8);
	SetTrieValue(hTrie, "tomato", 0xFF6347);
	SetTrieValue(hTrie, "turquoise", 0x40E0D0);
	SetTrieValue(hTrie, "unique", 0xFFD700); // same as Unique item quality in TF2
	SetTrieValue(hTrie, "unusual", 0x8650AC); // same as Unusual item quality in TF2
	SetTrieValue(hTrie, "valve", 0xA50F79); // same as Valve item quality in TF2
	SetTrieValue(hTrie, "vintage", 0x476291); // same as Vintage item quality in TF2
	SetTrieValue(hTrie, "violet", 0xEE82EE);
	SetTrieValue(hTrie, "wheat", 0xF5DEB3);
	SetTrieValue(hTrie, "white", 0xFFFFFF);
	SetTrieValue(hTrie, "whitesmoke", 0xF5F5F5);
	SetTrieValue(hTrie, "yellow", 0xFFFF00);
	SetTrieValue(hTrie, "yellowgreen", 0x9ACD32);
	return hTrie;
}

// From colors lib [Author: Exvel]
/**
 * Replaces color tags in a string with color codes
 *
 * @param message   String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 * 
 * On error/Errors:   If there is more then one team color is used an error will be thrown.
 */
stock CFormat(String:message[], maxlength, author=NO_INDEX)
{
	/* Hook event for auto profile setup on map start */
	if (!CEventIsHooked)
	{
		CSetupProfile();
		HookEvent("server_spawn", CEvent_MapStart, EventHookMode_PostNoCopy);
		CEventIsHooked = true;
	}
	
	new iRandomPlayer = NO_INDEX;
	
	/* If author was specified replace {teamcolor} tag */
	if (author != NO_INDEX)
	{
		if (CProfile_SayText2)
		{
			ReplaceString(message, maxlength, "{teamcolor}", "\x03");
			iRandomPlayer = author;
		}
		/* If saytext2 is not supported by game replace {teamcolor} with green tag  */
		else
		{
			ReplaceString(message, maxlength, "{teamcolor}", CTagCode[Color_Green]);
		}
	}
	else
	{
		ReplaceString(message, maxlength, "{teamcolor}", "");
	}
	
	/* For other color tags we need a loop */
	for (new i = 0; i < MAX_COLORS; i++)
	{
		/* If tag not found - skip */
		if (StrContains(message, CTag[i]) == -1)
		{
			continue;
		}
		/* If tag is not supported by game replace it with green tag */
		else if (!CProfile_Colors[i])
		{
			ReplaceString(message, maxlength, CTag[i], CTagCode[Color_Green], false);
		}
		/* If tag doesn't need saytext2 simply replace */
		else if (!CTagReqSayText2[i])
		{
			ReplaceString(message, maxlength, CTag[i], CTagCode[i], false);
		}
		/* Tag needs saytext2 */
		else
		{
			/* If saytext2 is not supported by game replace tag with green tag */
			if (!CProfile_SayText2)
			{
				ReplaceString(message, maxlength, CTag[i], CTagCode[Color_Green], false);
			}
			/* sGame supports saytext2 */
			else 
			{
				/* If random player for tag wasn't specified replace tag and find player */
				if (iRandomPlayer == NO_INDEX)
				{
					/* Searching for valid client for tag */
					iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);
					
					/* If player not found replace tag with green color tag */
					if (iRandomPlayer == NO_PLAYER)
					{
						ReplaceString(message, maxlength, CTag[i], CTagCode[Color_Green]);
					}
					/* If player was found simply replace */
					else
					{
						ReplaceString(message, maxlength, CTag[i], CTagCode[i], false);
					}
					
				}
				/* If found another team color tag throw error */
				else
				{
					//ReplaceString(message, maxlength, CTag[i], "");
					ReplaceString(message, maxlength, CTag[i], CTagCode[Color_Green], false);
					//ThrowError("Using two team colors in one message is not allowed");
				}
			}
			
		}
	}
	
	return iRandomPlayer;
}

/**
 * Founds a random player with specified team
 *
 * @param color_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock CFindRandomPlayerByTeam(color_team)
{
	if (color_team == SERVER_INDEX)
	{
		return 0;
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == color_team)
			{
				return i;
			}
		}	
	}

	return NO_PLAYER;
}

/**
 * Sends a SayText2 usermessage to a client
 *
 * @param message   Client index
 * @param maxlength   Author index
 * @param message   Message
 * @return			  No return.
 */
/*stock CSayText2(client, author, const String:message[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, message);
	EndMessage();
}*/

/**
 * Creates game color profile 
 * This function must be edited if you want to add more games support
 *
 * @return			  No return.
 */
stock CSetupProfile()
{
	decl String:szGameName[30];
	GetGameFolderName(szGameName, sizeof(szGameName));
	
	if (StrEqual(szGameName, "cstrike", false))
	{
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;
		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;
		CProfile_SayText2 = true;
	}
	else if (StrEqual(szGameName, "tf", false))
	{
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;		
		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 2;
		CProfile_TeamIndex[Color_Blue] = 3;
		CProfile_SayText2 = true;
	}
	else if (StrEqual(szGameName, "left4dead", false) || StrEqual(szGameName, "left4dead2", false))
	{
		CProfile_Colors[Color_Lightgreen] = true;
		CProfile_Colors[Color_Red] = true;
		CProfile_Colors[Color_Blue] = true;
		CProfile_Colors[Color_Olive] = true;		
		CProfile_TeamIndex[Color_Lightgreen] = SERVER_INDEX;
		CProfile_TeamIndex[Color_Red] = 3;
		CProfile_TeamIndex[Color_Blue] = 2;
		CProfile_SayText2 = true;
	}
	else if (StrEqual(szGameName, "hl2mp", false))
	{
		/* hl2mp profile is based on mp_teamplay convar */
		if (GetConVarBool(FindConVar("mp_teamplay")))
		{
			CProfile_Colors[Color_Red] = true;
			CProfile_Colors[Color_Blue] = true;
			CProfile_Colors[Color_Olive] = true;
			CProfile_TeamIndex[Color_Red] = 3;
			CProfile_TeamIndex[Color_Blue] = 2;
			CProfile_SayText2 = true;
		}
		else
		{
			CProfile_SayText2 = false;
			CProfile_Colors[Color_Olive] = true;
		}
	}
	else if (StrEqual(szGameName, "dod", false))
	{
		CProfile_Colors[Color_Olive] = true;
		CProfile_SayText2 = false;
	}
	/* Profile for other games */
	else
	{
		if (GetUserMessageId("SayText2") == INVALID_MESSAGE_ID)
		{
			CProfile_SayText2 = false;
		}
		else
		{
			CProfile_Colors[Color_Red] = true;
			CProfile_Colors[Color_Blue] = true;
			CProfile_TeamIndex[Color_Red] = 2;
			CProfile_TeamIndex[Color_Blue] = 3;
			CProfile_SayText2 = true;
		}
	}
}

public Action:CEvent_MapStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CSetupProfile();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		CSkipList[i] = false;
	}
}

stock ReplaceCodes2(String:buffer[], author=0, bool:removeTags=false, maxlen=MAX_MESSAGE_LENGTH) {
	CCheckTrie();
	if(!removeTags) {
		ReplaceString(buffer, maxlen, "{default}", "\x01", false);
	} else {
		ReplaceString(buffer, maxlen, "{default}", "", false);
		ReplaceString(buffer, maxlen, "{teamcolor}", "", false);
	}
	if(author != 0 && !removeTags) {
		if(author < 0 || author > MaxClients) {
			ThrowError("Invalid client index %i", author);
		}
		if(!IsClientInGame(author)) {
			ThrowError("Client %i is not in game", author);
		}
		ReplaceString(buffer, maxlen, "{teamcolor}", "\x03", false);
	}
	new cursor = 0;
	//new value;
	decl String:tag[32], String:buff[32], String:output[maxlen];
	strcopy(output, maxlen, buffer);
	// Since the string's size is going to be changing, output will hold the replaced string and we'll search buffer
	
	new Handle:regex = CompileRegex("{[a-zA-Z0-9]+}");
	for(new i = 0; i < 1000; i++) { // The RegEx extension is quite flaky, so we have to loop here :/. This loop is supposed to be infinite and broken by return, but conditions have been added to be safe.
		if(MatchRegex(regex, buffer[cursor]) < 1) {
			CloseHandle(regex);
			strcopy(buffer, maxlen, output);
			return;
		}
		GetRegexSubString(regex, 0, tag, sizeof(tag));
		CStrToLower(tag);
		cursor = StrContains(buffer[cursor], tag, false) + cursor + 1;
		strcopy(buff, sizeof(buff), tag);
		ReplaceString(buff, sizeof(buff), "{", "");
		ReplaceString(buff, sizeof(buff), "}", "");
		
		//if(!GetTrieValue(CTrie, buff, value)) {
			//continue;
		//}
		
		if (StrEqual(buff, "green") || StrEqual(buff, "default") || StrEqual(buff, "lightgreen") || StrEqual(buff, "red") || StrEqual(buff, "blue") || StrEqual(buff, "olive"))
		{
			continue;
		}
		
		if(removeTags) {
			ReplaceString(output, maxlen, tag, "", false);
		} else {
			Format(buff, sizeof(buff), "");
			ReplaceString(output, maxlen, tag, buff, false);
		}
	}
	LogError("[MORE COLORS] Infinite loop broken.");
}

stock Handle:StartMessageExOne(UserMsg:msg, client, flags=0)
{
    new players[1];
    players[0] = client;

    return StartMessageEx(msg, players, 1, flags);
}