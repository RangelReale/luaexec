
/*
**	LuaHTML parser
**	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
**	This file is licensed under the terms of the free MIT license.
*/

#ifndef LUAHTML_PARSER_H
#define LUAHTML_PARSER_H

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#if defined(LUAHTML_STANDALONE)
#include <stdio.h>
typedef void *lua_State;
#else
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#endif

struct luahtml_utf8reader
{
	int (*readchar)(struct luahtml_utf8reader *);
	int accu, numa, min, bufc;
	const unsigned char *src;
	size_t srclen;
	FILE *file;
	void *udata;
};

typedef enum { PARSER_UNDEF = -1, PARSER_HTML, PARSER_OPEN1, PARSER_OPEN2,
PARSER_CODE, PARSER_VAR, PARSER_CLOSE } luahtml_parser_state_t;

struct luahtml_readdata
{
	/* buffer including " " .. outfunc .. "(": */
	unsigned char buf0[256];
	/* pointer into buf0 past outfunc: */
	unsigned char *buf;
	/* html+lua parser state: */
	luahtml_parser_state_t state;
	/* utf8 reader state: */
	struct luahtml_utf8reader utf8;
	/* code block encountered? */
	int code_present;
};

extern int luahtml_readutf8(struct luahtml_utf8reader *rd);
extern const char *luahtml_readparsed(lua_State *L, void *udata, size_t *sz);

#endif
