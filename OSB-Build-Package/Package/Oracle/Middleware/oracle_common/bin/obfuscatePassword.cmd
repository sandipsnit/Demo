
@REM obfuscatedPassword.cmd
@REM
@REM Copyright (c) 2010, 2013, Oracle and/or its affiliates. All rights reserved. 
@REM
@REM    NAME
@REM      obfuscatedPassword.cmd - Script to obfsucate password
@REM
@REM    DESCRIPTION
@REM      This script is used to create obfuscated password file. 
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
set ARCHIVEFLAG=false

FOR %%X in (%*) do (
    IF /i "%%X"=="-help" (
        echo "This script is used to create an obfuscated password file for use within the T2P framework."
        echo "It takes a single mandatory argument, '-javaHome' pointing to the absolute location of the Java home directory."
        goto end
    ) ELSE IF /i "!ISJRE_DIR!"=="true" (		
		FOR %%i IN (%%X) DO SET JRE_DIR=%%~dpfsi
		set ISJRE_DIR=false
	) ELSE IF /i "%%X"=="-javahome" (
		set JAVAHOMEFLAG=true
		set ISJRE_DIR=true
	)  ELSE (
		@REM if any other arguments is given, then error out by showing the usage
      	echo Unsupported argument %%X
      	goto paramsincorrect
	)
)


FOR %%X in (%*) do (
	IF /i "%%X"=="-al" (
		set ARCHIVEFLAG=true
		
	) ELSE IF /i "%%X"=="-archiveLocation" (
		set ARCHIVEFLAG=true
		
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

if NOT exist "%COMMON_HOME%\jlib\obfuscatepassword.jar" (
	echo This script is not executed from bin directory of Common Oracle home as obfuscatepassword.jar is not available under jlib directory of Common Oracle home. Execute from bin directory.
	SET RETURN_CODE=1
	goto end	
)

:invokeObfuscatePassword
set ERRORLEVEL=
"%JRE_DIR%\bin\java.exe" %T2P_JAVA_OPTIONS% -jar "%COMMON_HOME%\jlib\obfuscatepassword.jar"
SET RETURN_CODE=%ERRORLEVEL%
goto end


:COMMONHOMESETTER %TEMP_CH%
SETLOCAL ENABLEEXTENSIONS
ENDLOCAL&SET COMMON_HOME=%~f1&goto :EOF

:paramsincorrect
SET RETURN_CODE=1
goto help

:help
echo usage: obfuscatepassword.cmd -javaHome java_home
goto end


:end
EXIT /B %RETURN_CODE%
