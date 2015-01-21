
/*
**	tek.lib.luahtml - Lua+HTML parser/decoding library
**	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
**	This file is licensed under the terms of the free MIT license.
*/

#include "luahtml_parser.h"

#define luahtml_topfile(L) ((FILE **) luaL_checkudata(L, 1, LUA_FILEHANDLE))


static FILE *luahtml_tofile (lua_State *L)
{
	FILE **f = luahtml_topfile(L);
	if (*f == NULL)
		luaL_error(L, "attempt to use a closed file");
	return *f;
}


static int luahtml_readstring(struct luahtml_utf8reader *rd)
{
	if (rd->srclen == 0)
		return -1;
	rd->srclen--;
	return *rd->src++;
}


static int luahtml_readfile(struct luahtml_utf8reader *rd)
{
	return fgetc(rd->file);
}


static int luahtml_load(lua_State *L)
{
	struct luahtml_readdata rd;
	const char *outfunc = luaL_checkstring(L, 2);
	const char *chunkname = luaL_checkstring(L, 3);
	int res;

	if (lua_isuserdata(L, 1))
	{
		rd.utf8.file = luahtml_tofile(L);
		rd.utf8.readchar = luahtml_readfile;
	}
	else
	{
		rd.utf8.src = (unsigned char *) lua_tolstring(L, 1, &rd.utf8.srclen);
		rd.utf8.readchar = luahtml_readstring;
	}

	rd.utf8.accu = 0;
	rd.utf8.numa = 0;
	rd.utf8.bufc = -1;
	rd.code_present = 0;

	rd.state = PARSER_UNDEF;
	strcpy((char *) rd.buf0, " ");
	strcat((char *) rd.buf0, outfunc);
	strcat((char *) rd.buf0, "(");
	rd.buf = rd.buf0 + strlen((char *) rd.buf0);

#if LUA_VERSION_NUM < 502
	res = lua_load(L, luahtml_readparsed, &rd, chunkname);
#else
	res = lua_load(L, luahtml_readparsed, &rd, chunkname, NULL);
#endif
	if (res == 0)
	{
#if LUA_VERSION_NUM >= 502
		lua_pushvalue(L, 4);
		lua_setupvalue(L, -2, 1);
#endif
		lua_pushboolean(L, rd.code_present);
		return 2;
	}

	lua_pushnil(L);
	lua_insert(L, -2);
	/* nil, message on stack */
	return 2;
}


static int luahtml_encode(lua_State *L)
{
	struct luahtml_readdata rd;
	char sbuf[16];
	luaL_Buffer b;
	int c;

	if (lua_isuserdata(L, 1))
	{
		rd.utf8.file = luahtml_tofile(L);
		rd.utf8.readchar = luahtml_readfile;
	}
	else
	{
		rd.utf8.src = (unsigned char *) lua_tolstring(L, 1, &rd.utf8.srclen);
		rd.utf8.readchar = luahtml_readstring;
	}

	luaL_buffinit(L, &b);

	rd.utf8.accu = 0;
	rd.utf8.numa = 0;
	rd.utf8.bufc = -1;

	while ((c = luahtml_readutf8(&rd.utf8)) >= 0)
	{
		switch(c)
		{
			case 34:
				luaL_addlstring(&b, "&quot;", 6);
				break;
			case 38:
				luaL_addlstring(&b, "&amp;", 5);
				break;
			case 60:
				luaL_addlstring(&b, "&lt;", 4);
				break;
			case 62:
				luaL_addlstring(&b, "&gt;", 4);
				break;
			default:
				if (/*c == 91 || c == 93 ||*/ c > 126)
				{
					sprintf(sbuf, "&#%03d;", c);
					luaL_addstring(&b, sbuf);
				}
				else
					luaL_addchar(&b, c);
		}
	}

	luaL_pushresult(&b);
	return 1;
}


static const luaL_Reg luahtml_lib[] =
{
	{ "load", luahtml_load },
	{ "encode", luahtml_encode },
	{ NULL, NULL }
};


int luaopen_tek_lib_luahtml(lua_State *L)
{
#if LUA_VERSION_NUM < 502
	luaL_register(L, "tek.lib.luahtml", luahtml_lib);
#else
	luaL_newlib(L, luahtml_lib);
#endif
	return 1;
}
