
@REM copyConfig.cmd
@REM
@REM Copyright (c) 2010, 2013, Oracle and/or its affiliates. All rights reserved. 
@REM
@REM    NAME
@REM      copyConfig.cmd - Script to copy Oracle component configuration
@REM
@REM    DESCRIPTION
@REM      This script is used to create the archive of an Oracle component configuration.
@REM      This script invokes the t2p implementation and has one mandatory parameter
@REM      to call the implementation.
@REM
@REM      -javaHome   - java home location.
@REM
@REM    NOTES
@REM      <other useful comments, qualifications, etc.>
@REM

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET COMMON_HOME_TEMP=%~dp0\..
CALL :COMMONHOMESETTER %COMMON_HOME_TEMP%


SET RETURN_CODE=0

set "tmpargs=%*"
if !tmpargs!=="" goto help


set JAVAHOMEFLAG=false
set ISJRE_DIR=false
set JRE_DIR=
SET ARGS=

FOR %%X in (%*) do (
	IF /i "!ISJRE_DIR!"=="true" (		
		FOR %%i IN (%%X) DO SET JRE_DIR=%%~dpfsi
		set ISJRE_DIR=false
	) ELSE IF /i "%%X"=="-javahome" (
		set JAVAHOMEFLAG=true
		set ISJRE_DIR=true
	) ELSE (
                SET ARGS=!ARGS! %%X
        )
)

IF /i "%JAVAHOMEFLAG%"=="false" (
	goto paramsincorrect
) ELSE IF "%JRE_DIR%"=="" (
	goto paramsincorrect
)

if NOT exist "%JRE_DIR%\bin\java.exe" (
	echo  Java Home location is invalid as "%JRE_DIR%\bin\java.exe" does not exist.
        SET RETURN_CODE=1
	goto end	
)

if NOT exist "%COMMON_HOME%\jlib\cloningclient.jar" (
	echo This script is not executed from bin directory of Common Oracle home as cloningclient.jar is not available under jlib directory of Common Oracle home. Execute from bin directory.
        SET RETURN_CODE=1
	goto end	
)

:invokeCloningClient
set ERRORLEVEL=
"%JRE_DIR%\bin\java.exe" %T2P_JAVA_OPTIONS% -jar "%COMMON_HOME%\jlib\cloningclient.jar" createClone -script copyConfig %ARGS%
SET RETURN_CODE=%ERRORLEVEL%
goto end

:COMMONHOMESETTER %TEMP_CH%
SETLOCAL ENABLEEXTENSIONS
ENDLOCAL&SET COMMON_HOME=%~f1&goto :EOF

:paramsincorrect
echo Command Line parameter -javaHome ^<java home location^> is mandatory
SET RETURN_CODE=1
goto help

:help
echo usage: copyConfig.cmd -javaHome java_home -archiveLoc archive_location -sourceDomainLoc domain_home -sourceMWHomeLoc Middleware_home
echo        -domainHostName domain_host -domainPortNum domain_port -domainAdminUserName admin_user -domainAdminPassword admin_password_file
echo        [-mdsDataImport true^|false] [-mdsDataExport true^|false] [-opssDataExport true^|false] [-additionalParams additional_parameters]
echo        [-logDirLoc log_directory] [-silent true^|false]
echo        (For J2EE Domain)
echo.
echo  or    copyConfig.cmd -javaHome java_home -archiveLoc archive_location -sourceNMHomeLoc nodemanager_home
echo        [-logDirLoc log_directory] [-silent true^|false]
echo        (For NodeManager)
echo.
echo  or    copyConfig.cmd -javaHome java_home -archiveLoc archive_location  -sourceInstanceHomeLoc instance_home
echo        [-logDirLoc log_directory] [-silent true^|false]
echo        (For ASInstance)
echo.
echo  or    copyConfig.cmd -javaHome java_home -archiveLoc archive_location  -sourceInstanceHomeLoc instance_home -sourceComponentName component_name
echo        [-logDirLoc log_directory] [-silent true^|false]
echo        (For System Component)
echo.
echo Try "copyConfig.cmd -javaHome java_home  -help"  for more information
goto end


:end
EXIT /B %RETURN_CODE%
