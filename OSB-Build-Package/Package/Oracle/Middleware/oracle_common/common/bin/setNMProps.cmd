@REM
@REM setNMProps.cmd
@REM
@REM Copyright (c) 2008, 2013 Oracle and/or its affiliates.All rights reserved. 
@REM
@REM    NAME
@REM      setNMProps.cmd - <set node manager properties>
@REM
@REM    DESCRIPTION
@REM      Run this script to append required properties to the
@REM	nodemanager.properties file. These properties can also be appended
@REM	manually, or provided as command-line arguments. 
@REM
@REM    NOTES
@REM      StartScriptEnabled=true property is required for managed servers
@REM	to receive proper classpath and command arguments.
@REM	The file containing the properties is nm.required.properties
@REM
@REM

ECHO OFF
@REM SET ORACLE_HOME and MW_HOME relative to this script. Do not move this script.

SET SCRIPTPATH=%~dp0
FOR %%i IN ("%SCRIPTPATH%") DO SET SCRIPTPATH=%%~fsi
FOR %%i IN ("%SCRIPTPATH%\..\..") DO SET ORACLE_HOME=%%~fsi
FOR %%i IN ("%ORACLE_HOME%\..") DO SET MW_HOME=%%~fsi

@REM Set WL_HOME and NM_HOME based on MW_HOME. If you are not using default locations
@REM you must edit the variables below 

@REM INVOKE SCRIPT TO SET THE WL_HOME
CALL %SCRIPTPATH%\setHomeDirs.cmd

FOR %%i IN ("%WL_HOME%") DO SET WL_HOME=%%~fsi
SET NM_HOME=%WL_HOME%\common\nodemanager

@REM Appending properties to the nodemanager.properties file overrides them

@REM If the file does not exist, copy over the minimal property set
IF NOT EXIST %NM_HOME%\nodemanager.properties (
	ECHO File nodemanager.properties not found. Copying required properties file.
	COPY %SCRIPTPATH%\nm.required.properties %NM_HOME%\nodemanager.properties
	GOTO :EOF
)  
@REM If any of the required properties are missing, append all of them

FIND "StartScriptEnabled=true" %NM_HOME%\nodemanager.properties > NUL
IF ERRORLEVEL 1 GOTO :APPEND

ECHO Required properties already set. File nodemanager.properties not modified.

GOTO :EOF

:APPEND
ECHO Appending required nodemanager.properties
TYPE %SCRIPTPATH%\nm.required.properties >> %NM_HOME%\nodemanager.properties
