/**************************************************************************
 *                             CS:GO COLORS                               *
 *                     Автор: Феникс(komashchenko)                        *
 *                            Version: 1.4                                *
 *                  http://zizt.ru/  http://hlmod.ru/                     *
 * 03.07.2014 - V1.0: Релиз                                               *
 * 13.10.2014 - V1.1: Обнова                                              *
 * 24.10.2014 - V1.2: Обнова                                              *
 * 17.11.2014 - V1.3: Исправление ошибок                                  *
 * 23.12.2015 - V1.4: Исправление ошибок, Обнова                          *
 **************************************************************************/

#define ZCOLOR 13
 
new const String:color_t[ZCOLOR][] = {"{DEFAULT}", "{RED}", "{LIGHTPURPLE}", "{GREEN}", "{LIME}", "{LIGHTGREEN}", "{LIGHTRED}", "{GRAY}", "{LIGHTOLIVE}", "{OLIVE}", "{LIGHTBLUE}", "{BLUE}", "{PURPLE}"};
new const String:color_c[ZCOLOR][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E"};

stock CPrintToChat(iClient, const String:message[], any:...)
{
	new a = strlen(message)+190, l;
	decl String:b[a], i;
	l = ReplaceString(b, VFormat(b, a, message, 3), "\n", "", false);
	for(i = 0; i < ZCOLOR; ++i) ReplaceString(b, a, color_t[i], color_c[i], false);
	if(l)
	{
		l++;
		decl String:s[l][192];
		for (new m = ExplodeString(b, "", s, l, 192), p = 0; p < m; p++) PrintToChat(iClient, " %s", s[p]);
	}
	else PrintToChat(iClient, " %s", b);
}

stock CPrintToChatAll(const String:message[], any:...)
{
	new a = strlen(message)+190, l;
	decl String:b[a];
	l = ReplaceString(b, VFormat(b, a, message, 2), "\n", "", false);
	for(i; i < ZCOLOR; i++) ReplaceString(b, a, color_t[i], color_c[i], false);
	if(l)
	{
		l++;
		decl String:s[l][192], m;
		for (m = ExplodeString(b, "", s, l, 192), p; p < m; p++) PrintToChatAll(" %s", s[p]);
	}
	else  PrintToChatAll(" %s", b);
}

stock CGOReplaceColorSay(String:text[], maxlength)
{
	for(i; i < ZCOLOR; i++) ReplaceString(text, maxlength, color_t[i], color_c[i], false);
}