@ECHO OFF
SETLOCAL

@REM Determine the location of this script...
SET SCRIPTPATH=%~dp0
FOR %%i IN ("%SCRIPTPATH%") DO SET SCRIPTPATH=%%~fsi

@REM Set the ORACLE_HOME relative to this script...
FOR %%i IN ("%SCRIPTPATH%\..\..") DO SET ORACLE_HOME=%%~fsi

@REM Set the MW_HOME relative to the ORACLE_HOME...
FOR %%i IN ("%ORACLE_HOME%\..") DO SET MW_HOME=%%~fsi

@REM Set the home directories...
CALL "%SCRIPTPATH%\setHomeDirs.cmd"

@REM Set the config jvm args...
SET CONFIG_JVM_ARGS=%CONFIG_JVM_ARGS% -DCOMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME%

@REM Delegate to the main script...
CALL "%WL_HOME%\common\bin\unpack.cmd" %*

ENDLOCAL
