@echo off
::
::  Copyright (c) 2005, 2008, Oracle. All rights reserved.  
::     
::     NAME
::       emocmrsp - OCM Install Config Response Generator
::  
::     DESCRIPTION
::       This script is invoked by the user to create the response
::       file for silent installations of OCM.
:: 
::     Note
::       From a design/convention point, variables local to functions are
::       prefixed with a '_' character. Global Variables are prefixed with
::       'G_' and are entirely in upper case (The exception to this rule
::       are environment variables that are meant to abstract OS Commands
::       e.g. SED, CUT, ...)
:: 
::       Functions are listed in alphabetical order and precede the flow
::       of logic.
::     
::     EXIT CODES
::       0 - Success
::       1 - Prerequisite failure
::       2 - Invalid argument specified
::       3 - Invalid Usage
::       7 - Missing command qualifier value
::       11 - Unexpected Installation failure

:: ++
::  Construct the CCR installation directory root based upon the bin
::  directory being a child.
::  Extract the binary directory specification where this script resides. 
::  The enclosed code will come up with an absolute path. 
:: --

for %%i in (%~sf0\..) do set OCM_HOME=%%~dspi

:: Do some cmd line processing; store %* in a separate variable
:: cmd line option -calledFromC is passed only when called from
:: a C program.

set CMD_LINE_ARGS=
set CALLED_FROM_C=0
:setArgs
 if ""%1""=="""" goto doneSetArgs
 if ""%1""=="""-calledFromC""" (set CALLED_FROM_C=1) & shift & goto setArgs
 set CMD_LINE_ARGS=%CMD_LINE_ARGS% %1
 shift
 goto setArgs
:doneSetArgs

:: If we have been called from C, we exit the command processor too
:: otherwise we just exit this script (exit /b)
cscript //nologo %OCM_HOME%lib\emocmutl.vbs check_java_prereqs 
set ERRCODE=%ERRORLEVEL%
if NOT %ERRCODE% == 0 if %CALLED_FROM_C% == 1 exit %ERRCODE%
if NOT %ERRCODE% == 0 exit /b %ERRCODE%

for /F "tokens=1-4 delims=," %%A in ('cscript //nologo %OCM_HOME%lib\emocmutl.vbs get_env') do set __ORACLE_HOME=%%A
for /F "tokens=1-4 delims=," %%A in ('cscript //nologo %OCM_HOME%lib\emocmutl.vbs get_env') do set __CCR_HOME=%%B
if NOT "%ORACLE_CCR_DEV%" == "" ( for /F "tokens=1-4 delims=," %%A in ('cscript //nologo %OCM_HOME%lib\emocmutl.vbs get_env') do set CCR_CONFIG_HOME=%%C )
for /F "tokens=1-4 delims=," %%A in ('cscript //nologo %OCM_HOME%lib\emocmutl.vbs get_env') do set __JAVA_HOME=%%D

set __OCM_ENDPOINT=
if NOT "%ORACLE_OCM_SERVICE%" == "" set __OCM_ENDPOINT=-Docm.endpoint=%ORACLE_OCM_SERVICE%

set __OCM_LOG=
if NOT "%CCR_DEBUG%" == "" set __OCM_LOG=-DOCM_LOG_LEVEL=DEBUG

set __ORACLE_CCR_TESTS=
IF NOT "%ORACLE_CCR_TESTS%" == "" set __ORACLE_CCR_TESTS=-DORACLE_CCR_TESTS=%ORACLE_CCR_TESTS%

set __OCH_HOME=
if NOT "%ORACLE_CONFIG_HOME%" == "" set __OCH=-DORACLE_CONFIG_HOME=%ORACLE_CONFIG_HOME%

::  Use the OH as CCR_CONFIG_HOME to force the use of config parameters strictly
::  from the binary home, unless CCR_CONFIG_HOME has been set by the caller.
%__JAVA_HOME%\bin\java.exe %__OCM_LOG% %__OCM_ENDPOINT% %__ORACLE_CCR_TESTS% -DOCM_ROOT=%OCM_HOME% -DORACLE_HOME=%__ORACLE_HOME% -DCCR_CONFIG_HOME=%CCR_CONFIG_HOME% %__OCH% -jar %OCM_HOME%lib\emocmclnt.jar %CMD_LINE_ARGS%
