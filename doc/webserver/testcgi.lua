<%
local vars = 
{
	"CONTENT_LENGTH",
	"CONTENT_TYPE",
	"DOCUMENT_ROOT",
	"GATEWAY_INTERFACE",
	"HTTP_ACCEPT",
	"HTTP_ACCEPT_ENCODING",
	"HTTP_ACCEPT_CHARSET",
	"HTTP_ACCEPT_LANGUAGE",
	"HTTP_CONNECTION",
	"HTTP_COOKIE",
	"HTTP_HOST",
	"HTTP_REFERER",
	"HTTP_USER_AGENT",
	"PATH_INFO",
	"PATH_TRANSLATED",
	"QUERY_STRING",
	"REMOTE_ADDR",
-- 	"REMOTE_HOST",
-- 	"REMOTE_IDENT",
	"REMOTE_PORT",
-- 	"REMOTE_USER",
	"REQUEST_METHOD",
	"REQUEST_URI",
	"SCRIPT_FILENAME",
	"SCRIPT_NAME",
-- 	"SERVER_ADDR",
-- 	"SERVER_ADMIN",
-- 	"SERVER_NAME",
-- 	"SERVER_PORT",
-- 	"SERVER_PROTOCOL",
-- 	"SERVER_SIGNATURE",
-- 	"SERVER_SOFTWARE",
}
		
addbuffer("Content-Type: text/html\r\n\r\n")
%>
<html>
<body>

<table>
	<%for i = 1, #vars do%>
		<tr>
			<td>
				<%=vars[i]%>
			</td>
			<td>
				<%=Request:getEnv(vars[i])%>
			</td>
		</tr>
	<%end%>
</table>

</body>
</html>
