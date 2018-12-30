@ECHO OFF
REM This script assumes WL_HOME is set to the product directory which is the
REM target of the uninstall before this script it called.

SETLOCAL

@REM Set JAVA HOME
set  JAVA_HOME=D:\OSB\Program
FOR %%i IN ("%JAVA_HOME%") DO SET JAVA_HOME=%%~fsi

@REM Set BEA Home
SET BEAHOME=C:\Oracle\Middleware
FOR %%i IN ("%BEAHOME%") DO SET BEA_HOME=%%~fsi

SET JAVA=%1
IF DEFINED JAVA (
  SET JAVA=java
) ELSE (
  SET JAVA=javaw
)

"%JAVA_HOME%\bin\%JAVA%" %JAVA_VM% -Xmx256m -Djava.library.path="%BEAHOME%\utils\uninstall" -Dhome.dir="%BEAHOME%" -Dinstall.dir="%WL_HOME%" -jar "%BEAHOME%\utils\uninstall\uninstall.jar" %*

SET RC=%ERRORLEVEL%

SET CMD_EXIT=%USE_CMD_EXIT%
IF DEFINED CMD_EXIT (
  EXIT %RC%
) ELSE (
  EXIT /B %RC%
)

ENDLOCAL
