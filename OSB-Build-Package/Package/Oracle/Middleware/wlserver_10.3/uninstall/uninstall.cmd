@ECHO OFF
SETLOCAL

@REM Set WebLogic Home
set WL_HOME=%~dp0..
FOR %%i IN ("%WL_HOME%") DO SET WL_HOME=%%~fsi

(
  "C:\Oracle\Middleware\utils\uninstall\uninstall.exe" %*
  EXIT /B %ERRORLEVEL%
) 3<%0

ENDLOCAL
