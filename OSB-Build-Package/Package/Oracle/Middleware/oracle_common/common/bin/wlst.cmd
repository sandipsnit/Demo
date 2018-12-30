@ECHO OFF
SETLOCAL

@REM Determine the location of this script...
SET SCRIPTPATH=%~dp0
FOR %%i IN ("%SCRIPTPATH%") DO SET SCRIPTPATH=%%~fsi

@REM Set CURRENT_HOME...
FOR %%i IN ("%SCRIPTPATH%\..\..") DO SET CURRENT_HOME=%%~fsi

@REM Set the MW_HOME relative to the CURRENT_HOME...
FOR %%i IN ("%CURRENT_HOME%\..") DO SET MW_HOME=%%~fsi

@REM Set the home directories...
CALL "%SCRIPTPATH%\setHomeDirs.cmd"

@REM Set the DELEGATE_ORACLE_HOME to CURRENT_HOME if it's not set...
IF "%DELEGATE_ORACLE_HOME%"=="" (
  SET DELEGATE_ORACLE_HOME=%CURRENT_HOME%
)
SET ORACLE_HOME=%DELEGATE_ORACLE_HOME%

@REM Set the directory to get wlst commands from...
SET COMMON_WLST_HOME=%COMMON_COMPONENTS_HOME%\common\wlst
SET WLST_HOME=%COMMON_WLST_HOME%;%WLST_HOME%

@REM some scripts in the the WLST_HOME directory reference ORACLE_HOME
SET WLST_PROPERTIES=%WLST_PROPERTIES% -DORACLE_HOME=%ORACLE_HOME% -DCOMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME%

@REM Set the WLST extended env...
IF EXIST %COMMON_COMPONENTS_HOME%\common\bin\setWlstEnv.cmd CALL %COMMON_COMPONENTS_HOME%\common\bin\setWlstEnv.cmd

@REM Appending additional jar files to the CLASSPATH...
IF EXIST %COMMON_WLST_HOME%\lib FOR %%G IN (%COMMON_WLST_HOME%\lib\*.jar) DO (CALL :APPEND_CLASSPATH %%~FSG)

@REM Appending additional resource bundles to the CLASSPATH...
IF EXIST %COMMON_WLST_HOME%\resources FOR %%G IN (%COMMON_WLST_HOME%\resources\*.jar) DO (CALL :APPEND_CLASSPATH %%~FSG) 

@REM Delegate to the main script...
SET WLST_SCRIPT=%WL_HOME%\common\bin\wlst.cmd
GOTO LAUNCH_WLST

:APPEND_CLASSPATH
SET CLASSPATH=%CLASSPATH%;%1
GOTO :EOF

:LAUNCH_WLST
CALL "%WLST_SCRIPT%" %*
