
/*
**	LuaHTML parser
**	Written by Timm S. Mueller <tmueller at schulze-mueller.de>
**	This file is licensed under the terms of the free MIT license.
*/

#include "luahtml_parser.h"


static unsigned char *luahtml_encodeutf8(unsigned char *buf, int c)
{
	if (c < 128)
	{
		*buf++ = c;
	}
	else if (c < 2048)
	{
		*buf++ = 0xc0 + (c >> 6);
		*buf++ = 0x80 + (c & 0x3f);
	}
	else if (c < 65536)
	{
		*buf++ = 0xe0 + (c >> 12);
		*buf++ = 0x80 + ((c & 0xfff) >> 6);
		*buf++ = 0x80 + (c & 0x3f);
	}
	else if (c < 2097152)
	{
		*buf++ = 0xf0 + (c >> 18);
		*buf++ = 0x80 + ((c & 0x3ffff) >> 12);
		*buf++ = 0x80 + ((c & 0xfff) >> 6);
		*buf++ = 0x80 + (c & 0x3f);
	}
	else if (c < 67108864)
	{
		*buf++ = 0xf8 + (c >> 24);
		*buf++ = 0x80 + ((c & 0xffffff) >> 18);
		*buf++ = 0x80 + ((c & 0x3ffff) >> 12);
		*buf++ = 0x80 + ((c & 0xfff) >> 6);
		*buf++ = 0x80 + (c & 0x3f);
	}
	else
	{
		*buf++ = 0xfc + (c >> 30);
		*buf++ = 0x80 + ((c & 0x3fffffff) >> 24);
		*buf++ = 0x80 + ((c & 0xffffff) >> 18);
		*buf++ = 0x80 + ((c & 0x3ffff) >> 12);
		*buf++ = 0x80 + ((c & 0xfff) >> 6);
		*buf++ = 0x80 + (c & 0x3f);
	}
	return buf;
}


int luahtml_readutf8(struct luahtml_utf8reader *rd)
{
	int c;
	for (;;)
	{
		if (rd->bufc >= 0)
		{
			c = rd->bufc;
			rd->bufc = -1;
		}
		else
			c = rd->readchar(rd);

		if (c < 0)
			return c;

		if (c == 254 || c == 255)
			break;

		if (c < 128)
		{
			if (rd->numa > 0)
			{
				rd->bufc = c;
				break;
			}
			return c;
		}
		else if (c < 192)
		{
			if (rd->numa == 0)
				break;
			rd->accu <<= 6;
			rd->accu += c - 128;
			rd->numa--;
			if (rd->numa == 0)
			{
				if (rd->accu == 0 || rd->accu < rd->min ||
					(rd->accu >= 55296 && rd->accu <= 57343))
					break;
				c = rd->accu;
				rd->accu = 0;
				return c;
			}
		}
		else
		{
			if (rd->numa > 0)
			{
				rd->bufc = c;
				break;
			}

			if (c < 224)
			{
				rd->min = 128;
				rd->accu = c - 192;
				rd->numa = 1;
			}
			else if (c < 240)
			{
				rd->min = 2048;
				rd->accu = c - 224;
				rd->numa = 2;
			}
			else if (c < 248)
			{
				rd->min = 65536;
				rd->accu = c - 240;
				rd->numa = 3;
			}
			else if (c < 252)
			{
				rd->min = 2097152;
				rd->accu = c - 248;
				rd->numa = 4;
			}
			else
			{
				rd->min = 67108864;
				rd->accu = c - 252;
				rd->numa = 5;
			}
		}
	}
	/* bad char */
	rd->accu = 0;
	rd->numa = 0;
	return 65533;
}


static unsigned char *luahtml_outchar(lua_State *L, unsigned char *buf,
	luahtml_parser_state_t state, int c)
{
	if (state == PARSER_HTML)
	{
		if (c > 127 /*|| c == '[' || c == ']'*/)
			return buf + sprintf((char *) buf, "&#%02d;", c);
	}
	else if (state == PARSER_CODE)
	{
		if (c > 127)
			return luahtml_encodeutf8(buf, c);
	}
	else if (c > 127)
	{
#if !defined(LUAHTML_STANDALONE)
		luaL_error(L, "Non-ASCII character outside code or HTML context");
#else
		fprintf(stderr, "Non-ASCII character outside code or HTML context\n");
		exit(1);
#endif
	}
	*buf++ = c;
	return buf;
}


const char *luahtml_readparsed(lua_State *L, void *udata, size_t *sz)
{
	struct luahtml_readdata *rd = udata;
	luahtml_parser_state_t news = rd->state;
	int c;

	while ((c = luahtml_readutf8(&rd->utf8)) >= 0)
	{
		switch (news)
		{
			case PARSER_UNDEF:
				if (c == '<')
				{
					news = PARSER_OPEN1;
					continue;
				}
				rd->state = PARSER_HTML;
				rd->buf[0] = '[';
				rd->buf[1] = '[';
				*sz = luahtml_outchar(L, rd->buf + 2, rd->state, c) - rd->buf0;
				return (char *) rd->buf0;

			case PARSER_HTML:
				if (c == '<')
				{
					news = PARSER_OPEN1;
					continue;
				}
				break;

			case PARSER_OPEN1:
				if (c == '%')
				{
					news = PARSER_OPEN2;
					continue;
				}
				rd->buf[0] = '<';
				rd->buf[1] = c;
				*sz = 2;
				return (char *) rd->buf;

			case PARSER_OPEN2:
				if (c == '=')
				{
					if (rd->state == PARSER_UNDEF)
					{
						rd->state = PARSER_VAR;
						*sz = rd->buf - rd->buf0;
						return (char *) rd->buf0;
					}
					rd->state = PARSER_VAR;
					strcpy((char *) rd->buf, "]])");
					memcpy(rd->buf + 3, rd->buf0, rd->buf - rd->buf0);
					*sz = 3 + rd->buf - rd->buf0;
					return (char *) rd->buf;
				}

				if (rd->state == PARSER_UNDEF)
					rd->state = PARSER_CODE;
				else
				{
					rd->state = PARSER_CODE;
					rd->buf[0] = ']';
					rd->buf[1] = ']';
					rd->buf[2] = ')';
					rd->buf[3] = ' ';
					rd->buf[4] = c;
					*sz = 5;
					return (char *) rd->buf;
				}
				break;

			case PARSER_VAR:
			case PARSER_CODE:
				if (c == '%')
				{
					rd->code_present = 1;
					news = PARSER_CLOSE;
					continue;
				}
				break;

			case PARSER_CLOSE:
				if (c == '>')
				{
					size_t len;
					if (rd->state == PARSER_CODE)
					{
						rd->state = PARSER_HTML;
						rd->buf[0] = '[';
						rd->buf[1] = '[';
						*sz = rd->buf + 2 - rd->buf0;
						return (char *) rd->buf0;
					}
					rd->state = PARSER_HTML;
					strcpy((char *) rd->buf, " or \"nil\")");
					memcpy(rd->buf + 10, rd->buf0, rd->buf - rd->buf0);
					len = 10 + rd->buf - rd->buf0;
					rd->buf[len++] = '[';
					rd->buf[len++] = '[';
					*sz = len;
					return (char *) rd->buf;
				}
				rd->buf[0] = '%';
				rd->buf[1] = c;
				*sz = 2;
				return (char *) rd->buf;
		}

		*sz = luahtml_outchar(L, rd->buf, rd->state, c) - rd->buf;
		return (char *) rd->buf;
	}

	rd->state = PARSER_UNDEF;
	if (news == PARSER_HTML)
	{
		*sz = 4;
		return "]]) ";
	}

	return NULL;
}


#if defined(LUAHTML_STANDALONE)

#include <unistd.h>

static int luahtml_readstdin(struct luahtml_utf8reader *rd)
{
	unsigned char buf[1];
	ssize_t rdlen = read(STDIN_FILENO, &buf, 1);
	if (rdlen == 0) return EOF;
	return buf[0];
}

int main(int argc, char **argv)
{
	size_t outlen;
	unsigned char *bufptr;
	struct luahtml_readdata rd;
	const char *outcmd = "print";
	if (argc >= 2)
		outcmd = argv[1];
	
	rd.utf8.file = STDIN_FILENO;
	rd.utf8.readchar = luahtml_readstdin;
	rd.utf8.accu = 0;
	rd.utf8.numa = 0;
	rd.utf8.bufc = -1;
	rd.state = PARSER_UNDEF;
	strcpy((char *) rd.buf0, " ");
	strcat((char *) rd.buf0, outcmd);
	strcat((char *) rd.buf0, "(");
	rd.buf = rd.buf0 + strlen((char *) rd.buf0);
	while ((bufptr = (unsigned char *) luahtml_readparsed(NULL, &rd, &outlen)))
	{
		write(STDOUT_FILENO, bufptr, outlen);
	}

	return 0;
}

#endif
