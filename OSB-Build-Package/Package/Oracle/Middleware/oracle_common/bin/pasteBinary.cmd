
@REM pasteBinary.cmd
@REM
@REM Copyright (c) 2010, 2013, Oracle and/or its affiliates. All rights reserved. 
@REM
@REM    NAME
@REM      pasteBinary.cmd - Script to paste Oracle Middleware Home binary
@REM
@REM    DESCRIPTION
@REM     This script is used to paste the Middleware Home binaries.
@REM     This script invokes the t2p implementation and has one mandatory parameter
@REM     to call the implementation.
@REM
@REM     -javaHome   - java home location.
@REM
@REM    NOTES
@REM      <other useful comments, qualifications, etc.>
@REM

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

SET RETURN_CODE=0

set "tmpargs=%*"
if !tmpargs!=="" goto help


:: set variables
set JAVAHOMEFLAG=false
set ISJRE_DIR=false
set JRE_DIR=
set ISCCPRESENTINJLIB=false
SET ARGS=
SET TEMP_LOC=
set tdtd=tmp
set ttrn=none
SET CWD_TEMP=%~dp0
CALL :CWDSETTER %CWD_TEMP%


:: validate the presence of cloningclient.jar in jlib
IF exist "%CWD%\..\jlib\cloningclient.jar" (
    set ISCCPRESENTINJLIB=true
)

:: validate the presence of cloningclient.jar
IF "%ISCCPRESENTINJLIB%"=="false" (
  IF NOT exist "%CWD%\cloningclient.jar" (
	echo  File 'cloningclient.jar' is not present in the script directory. Place the 'cloningclient.jar' into the 'pasteBinary.cmd' script directory. See the Fusion Middleware Documentation for details.
	goto end
  )
)


:: iterate through the arguments passed and set teh requires var and falgs
FOR %%X in (%*) do (
	IF /i "!ISJRE_DIR!"=="true" (
		FOR %%i IN (%%X) DO SET JRE_DIR=%%~dpfsi
		set ISJRE_DIR=false
                SET ARGS=!ARGS! !JRE_DIR!
	) ELSE IF /i "%%X"=="-javahome" (
		set JAVAHOMEFLAG=true
		set ISJRE_DIR=true
                SET ARGS=!ARGS! %%X
	) ELSE (
		SET ARGS=!ARGS! %%X
	)
)

:: validate JAVA HOME
IF /i "%JAVAHOMEFLAG%"=="false" (
	goto paramsincorrect
) ELSE IF "%JRE_DIR%"=="" (
	goto paramsincorrect
)

IF NOT exist "%JRE_DIR%\bin\java.exe" (
	echo  Java Home location is invalid as "%JRE_DIR%\bin\java.exe" does not exist.
        SET RETURN_CODE=1
	goto end	
)

:invokeCloningClient
SET ERRORLEVEL=
IF %ISCCPRESENTINJLIB%==true (
  "%JRE_DIR%\bin\java.exe" -mx512m %T2P_JAVA_OPTIONS% -jar "%CWD%\..\jlib\cloningclient.jar" applyClone -script pasteBinary %ARGS%
) ELSE (
  "%JRE_DIR%\bin\java.exe" -mx512m %T2P_JAVA_OPTIONS% -jar "%CWD%\cloningclient.jar" applyClone -script pasteBinary %ARGS%
)
SET RETURN_CODE=%ERRORLEVEL%
goto end

:CWDSETTER %TEMP_CH%
SETLOCAL ENABLEEXTENSIONS
ENDLOCAL&SET CWD=%~f1&goto :EOF


:paramsincorrect
SET RETURN_CODE=1
goto help

:help
echo usage: pasteBinary.cmd -javaHome java_home -archiveLoc archive_location -targetMWHomeLoc Middleware_home
echo        [-invPtrLoc inventory_pointer_file] [-executeSysPrereqs true^|false] [-ignoreDiskWarning true^|false]
echo        [-logDirLoc log_directory] [-silent true^|false] [-ouiPram oui_session_variables]
echo.
echo Try "pasteBinary.cmd -javaHome java_home  -help"  for more information.
goto end


:end
EXIT /B %RETURN_CODE%
