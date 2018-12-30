@ECHO OFF
SETLOCAL

"C:\Oracle\Middleware\utils\quickstart\quickstart.cmd" install.dir="C:\Oracle\Middleware\wlserver_10.3" product.alias.id="WebLogic Platform" product.alias.version="10.3.6.0" %*

EXIT /B %ERRORLEVEL%

ENDLOCAL  
