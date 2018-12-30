@echo off
REM ######################################################################
REM #  Copyright (c) 2004 Oracle Corporation.  All rights reserved.
REM #
REM #  shgangul  5/21/04   Create and support
REM #                          -jdk, -jre, -oh
REM #  shgangul  6/21/04   Added support for OPATCH_DEBUG
REM #  shgangul  7/15/04   use jdk to invoke opatch, otherwise use jre
REM #  shgangul  7/16/04   Display the Java call for debug
REM #  phnguyen  7/19/04   Add ".\" to class path
REM #  shgangul  8/05/04   change opatch to oracle.opatch package
REM #  phnguyen  8/23/04   Support OPATCH_PLATFORM_ID
REM #  shgangul  8/27/04   add fallback schemes for jre/jdk
REM #  phnguyen  8/30/04   Print "OPatch Succeeded" if OK
REM #  shgangul  9/01/04   Further changes for jre/jdk priorities
REM #  shgangul  9/07/04   java not present in jdk/jre option, error out
REM #  shgangul  12/15/04  Supply PATH variable to java
REM #  vsriram   03/02/05  Introduce OPATCH_NO_FUSER to bypass fuser check
REM #  shgangul  02/02/05  Minor bug in parsing -jdk option
REM #  vsriram   03/08/05  Change the Opatch exit messages.
REM #  shgangul  03/15/05  Pass in properties to OPatch
REM #  shgangul  05/14/05  Add opatchprereq.jar and opatchutil.jar to CP 
REM #  shgangul  07/18/05  Do not pass PATH env var to OPatch JVM
REM #  vsriram   05/10/06  Return 0 as exit code, even for warnings.
REM #  vsriram   06/15/06  Put OPatch/jlib/xmlparserv2.jar in classPath.
REM #  vsriram   06/21/06  Look for jre 1.5 and then fall back to JDK.
REM #  vsriram   08/01/06  Remove dependency on xmlparserv2.
REM #  vsriram   08/17/06  Include opatchactions.jar in classpath
REM #  vsriram   11/12/06  Check for JRE first, then JDK and then oraparam
REM #  vganesan  01/04/08  Fix Bug sbmbhcb
REM #  vganesan  02/27/08  Pass %BASE% (running directory of 'opatch') as a property
REM #                      to java invocation. This is needed to locate ocm.zip in
REM #                      OPatch.
REM #  vganesan  03/04/08  Add OCM's emocmutl.jar to the classpath
REM #  phnguyen  05/14/08  CCR_INSTALL_DEFER_COLLECT=1 
REM #  phnguyen  09/09/09  No support for 'opatch auto'
REM #  vganesan  06/23/09  Add opatchext.jar to OPatch classpath
REM #  vganesan  09/15/09  Return exit code with /b switch
REM #  akmaurya  08/19/09  FMW Checks
REM #  supal     09/09/09  Better messages for MW/OH consistency check
REM #  supal     10/31/09  No mandatory MWH/OH
REM #  supal     11/11/09  Pass Common Home Location to OPatch
REM #  vganesan  12/24/09  Remove quotes from the Oracle Home
REM #  supal     04/06/10  Fix issue with non-FMW OH installs in MWH
REM ######################################################################

setlocal

REM # Set the base path
set BASE=%~DP0%

REM # No support for 'opatch auto'
if "%1" == "auto" goto AUTOERROR 

REM # Get ORACLE_HOME from environment variable "ORACLE_HOME"
set OH=%ORACLE_HOME%

REM # Get Middleware Home from environment variable "MW_HOME"
set MWH=%MW_HOME%

REM # Check for OPATCH_DEBUG env variable
set DEBUG=%OPATCH_DEBUG%

set DEBUGVAL=false
if "%DEBUG%" == "TRUE" (set DEBUGVAL=true) else if "%DEBUG%" == "true" (set DEBUGVAL=true)

REM # Set CCR_INSTALL_DEFER_COLLECT=1
set CCR_INSTALL_DEFER_COLLECT=1

REM # Look for OPATCH_PLATFORM_ID
set PLATFORM=%OPATCH_PLATFORM_ID%

REM # Look for ORACLE_OCM_SERVICE
set OCM_SERVICE=
if NOT "%ORACLE_OCM_SERVICE%" == "" set OCM_SERVICE=-Docm.endpoint=%ORACLE_OCM_SERVICE%

REM # Preserve the PATH environment variable
set PATHENV=%PATH%

REM # If -oh is specified, use it to over-ride env. var. ORACLE_HOME
set getOH=0

REM # Look for OPATCH_NO_FUSER env. variable
set NO_FUSER=%OPATCH_NO_FUSER%

REM # All the OPatch properties to be passed in to Java
REM # Format for properties is abc=xyz
set PROPERTIES=

REM # If -jre or -jdk are specified, use it to launch opatch,
REM #   with -jdk > -jre.  And we expect there is a "bin/java" underneath
REM #   the value supplied
set getJRE=0
set getJDK=0

set JDK=
set JRE=
REM # If -mw_home is specified, use it for the next of the session 
REM # after verification of its integrity
set getMWHOME=0

set PARAMS=%*


:FORLOOP

if "%1" == "" goto DONELOOP

if NOT "%getMWHOME%" == "1" goto CHECK1
set MWH=%1
set getMWHOME=0

:CHECK1
if NOT "%getOH%" == "1" goto CHECK2 
set OH=%1
set getOH=0

:CHECK2
if NOT "%getJRE%" == "1" goto CHECK3 
set JRE=%1
set getJRE=0

:CHECK3
if NOT "%getJDK%" == "1" goto CHECKFMW2 
set JDK=%1
set getJDK=0

:CHECKFMW2
if NOT "%1" == "-mw_home" goto CHECK4
set getMWHOME=1

:CHECK4
if NOT "%1" == "-oh" goto CHECK5
set getOH=1

:CHECK5
if NOT "%1" == "-jre" goto CHECK6
set getJRE=1

:CHECK6
if NOT "%1" == "-jdk" goto FORCHECK 
set getJDK=1

:FORCHECK
shift
goto FORLOOP

:DONELOOP

if "%OH%" == "" goto CHECKFMW3
@REM Remove quotes

set OH=%OH:"=%
if NOT EXIST %OH%\NUL (
   echo The Oracle Home %OH% could not be located. Please give proper Oracle Home.
   echo OPatch returns with error code = 1
   set %ERRORLEVEL% = 1
   goto OPATCHDONE
) else (
   set C_ORACLE_HOME=%OH%
   if "%DEBUGVAL%" == "true" echo ORACLE_HOME is set at OPatch invocation
)

@REM Calculate Middleware Home simply by moving up IFF User set Oracle Home
for %%? in ("%C_ORACLE_HOME%\..") do set C_MW_HOME=%%~f?
goto CHECKFMW4

:CHECKFMW3
@REM Determine the location of this script...
SET SCRIPTPATH=%~DP0
FOR %%i IN ("%SCRIPTPATH%") DO SET SCRIPTPATH=%%~fsi

@REM Calculate the ORACLE_HOME relative to this script...
FOR %%i IN ("%SCRIPTPATH%\..\..") DO SET C_ORACLE_HOME=%%~fsi

@REM Set the MW_HOME relative to the ORACLE_HOME...
FOR %%i IN ("%C_ORACLE_HOME%\..") DO SET C_MW_HOME=%%~fsi

if "%DEBUGVAL%" == "true" echo ORACLE_HOME is NOT set at OPatch invocation

:CHECKFMW4
if "%MWH%" == "" goto CHECKFMW5
for %%a in (%MWH%.) do set MWH=%%~dpfa

:CHECKFMW5
@REM Check if this is really a FMW home - WebTier and some others create fake
@REM Middleware homes. If TRUE Middleware Home, we are guaranteed of the
@REM presence of registry.dat
@REM Note: A TRUE Middleware Home can be established ONLY by the WebLogic installer

set FMW_ERROR=0
if NOT EXIST %C_MW_HOME%\registry.dat goto CHECKFMW9

@REM Invoking the setHomeDirs.sh script to set the WebLogic environment
@REM Set the MW_HOME env variable temporarily for the following scripts
set SET_MW_HOME=%MW_HOME%
set MW_HOME=%C_MW_HOME%

if NOT EXIST %C_ORACLE_HOME%\common\bin\setHomeDirs.cmd goto CHECKFMW6
call "%C_ORACLE_HOME%\common\bin\setHomeDirs.cmd"

:CHECKFMW6
if "%DEBUGVAL%" == "true" echo WL_HOME is set by setHomeDirs.cmd script to %WL_HOME%

if "%WL_HOME%" == "" goto CHECKFMW6A

if NOT EXIST %WL_HOME%\NUL goto CHECKFMW6A

if NOT EXIST %WL_HOME%\common\bin\commEnv.cmd goto CHECKFMW6B

call %WL_HOME%\common\bin\commEnv.cmd

:CHECKFMW6A
set FMW_ERROR=-1
if "%DEBUGVAL%" == "true" (
   echo "Fusion Middleware Home maybe corrupted (WebLogic Home is not found)!"
   echo OPatch will proceed only if JVM launcher found
)
goto CHECKFMW7

:CHECKFMW6B
set FMW_ERROR=-2
if "%DEBUGVAL%" == "true" (
   echo "Fusion Middleware Home maybe corrupted (Common Env Script missing or Not executable)!"
   echo OPatch will proceed only if JVM launcher found
)
goto CHECKFMW7

:CHECKFMW7
set MW_HOME=%SET_MW_HOME%

if "%MWH%" == "" set MWH=%C_MW_HOME% 
if "%OH%" == "" set OH=%C_ORACLE_HOME%

@REM We will use the JDK used by WebLogic unless user knows better and wants to override
if NOT "%JDK%" == "" goto CHECKFMW8
if NOT "%JRE%" == "" goto CHECKFMW8

set JDK=%JAVA_HOME%

:CHECKFMW8
set JRE_MEMORY_OPTIONS=%MEM_ARGS% %JVM_D64%
set JAVA_VM_OPTION=

if "%JAVA_VENDOR%" == "Oracle" goto CHECKFMW9
if "%JAVA_VENDOR%" == "HP" goto CHECKFMW9
if "%JAVA_VENDOR%" == "Sun" goto CHECKFMW9

set JAVA_VM_OPTION=-client

goto INVOKEJAVA

:CHECKFMW9
REM # If Oracle Home not set, error out
if NOT "%OH%" == "" goto INVOKEJAVA
if NOT EXIST %C_ORACLE_HOME%\oui (
   echo The Oracle Home %C_ORACLE_HOME% is not OUI based home. Please give proper Oracle Home.
   echo OPatch returns with error code = 1
   set %ERRORLEVEL% = 1
   goto OPATCHDONE
)
set OH=%C_ORACLE_HOME%

:INVOKEJAVA
set CP=%OH%\oui\jlib

REM # Use ORACLE_HOME to set Java CLASS_PATH
REM # default location
set JAVA=

REM # Use JDK if supplied
if NOT "%JAVA%" == "" goto CHECKJRE
if "%JDK%" == "" goto CHECKJRE
REM if NOT EXIST %JDK%\bin\java.exe goto CHECKJRE
set JAVA=%JDK%\bin\java.exe
REM if EXIST %JAVA% goto JAVATEST
goto JAVATEST
REM set JAVA=

:CHECKJRE
REM # Use JRE if supplied
if NOT "%JAVA%" == "" goto CHECKOHJRE
if "%JRE%" == "" goto CHECKOHJRE
REM if NOT EXIST %JRE%\bin\java.exe goto CHECKOHJRE
set JAVA=%JRE%\bin\java.exe
REM if EXIST %JAVA% goto JAVATEST
goto JAVATEST
REM set JAVA=

:CHECKOHJRE
REM # Use OH\jre\*, it should be 1.5 or above
if NOT "%JAVA%" == "" goto CHECKOHJDK
set JRE_HIGH=
if NOT EXIST %OH%\jre goto CHECKOHJDK
for /F "usebackq tokens=1" %%A in (`dir /ON /B %OH%\jre`) do set JRE_HIGH=%%A
if "%JRE_HIGH%" == "" goto CHECKOHJDK
set JRE_HIGH_FIRST=
set JRE_HIGH_SECOND=
for /F "tokens=1,2 delims=." %%A in ("%JRE_HIGH%") do set JRE_HIGH_FIRST=%%A
for /F "tokens=1,2 delims=." %%A in ("%JRE_HIGH%") do set JRE_HIGH_SECOND=%%B
if "%JRE_HIGH_FIRST%" LSS "1" goto CHECKOHJDK
if "%JRE_HIGH_SECOND%" LSS "5" goto CHECKOHJDK
set JAVA=%OH%\jre\%JRE_HIGH%\bin\java.exe
if EXIST %JAVA% goto JAVATEST
set JAVA=

:CHECKOHJDK
REM # Check for jdk location inside OH
if NOT "%JAVA%" == "" goto CHECKORAPARAM
if NOT EXIST %OH%\jdk\bin\java.exe goto CHECKORAPARAM
set JAVA=%OH%\jdk\bin\java.exe
if EXIST %JAVA% goto JAVATEST
set JAVA=

:CHECKORAPARAM
REM # Last option is to look inside oraparam.ini for JRE_LOCATION
if NOT "%JAVA%" == "" goto JAVATEST
if NOT EXIST %OH%\oui\oraparam.ini goto JAVATEST
set JRE_LOCATION=
for /F "usebackq tokens=2 delims==" %%A in (`findstr "JRE_LOCATION=" %OH%\oui\oraparam.ini`) do set JRE_LOCATION=%%A
if "%JRE_LOCATION%" == "" goto JAVATEST
set ABS_PATH=
for /F "eol=\ tokens=1" %%A in ("%JRE_LOCATION%") do set ABS_PATH=%%A
if "%ABS_PATH%" == "" goto JAVAABSPATH
for /F "tokens=1,2 delims=:" %%A in ("%JRE_LOCATION%") do set ABS_PATH=%%B
if NOT "%ABS_PATH%" == "" goto JAVAABSPATH
set JAVA=%OH%\oui\bin\%JRE_LOCATION%\bin\java.exe
goto JAVATEST

:JAVAABSPATH
set JAVA=%JRE_LOCATION%\bin\java.exe
goto JAVATEST

REM # Java executable exists and has execute permission, exit otherwise
:JAVATEST
if NOT "%JAVA%" == "" goto JAVATEST1
echo Java could not be located. OPatch cannot proceed!
set %ERRORLEVEL% = 1
goto OPATCHDONE

:JAVATEST1
if EXIST %JAVA% goto CALLOPATCH
if %FMW_ERROR% == -1 echo Fusion Middleware Home is corrupted (WebLogic Home is not found)!
if %FMW_ERROR% == -2 echo Fusion Middleware Home is corrupted (Common Env Script missing or Not executable)!
echo %JAVA% could not be located. OPatch cannot proceed!
set %ERRORLEVEL% = 1
goto OPATCHDONE

REM echo.
REM echo.
REM echo Path to Java binary    %JAVA%
REM echo Classpath for java     %CP%
REM echo Oracle Home to be used %OH%
REM echo.
REM echo.

:CALLOPATCH
if NOT "%DEBUGVAL%" == "true" goto CALLOPATCHNODEBUG
echo %JAVA% %JAVA_VM_OPTION% %JRE_MEMORY_OPTIONS% -cp %BASE%\ocm\lib\emocmutl.jar;%BASE%\ocm\lib\emocmclnt.jar;%CP%\OraInstaller.jar;%CP%\OraPrereq.jar;%CP%\share.jar;%CP%\srvm.jar;%CP%\orai18n-mapping.jar;%CP%\xmlparserv2.jar;%BASE%jlib\opatch.jar;%BASE%jlib\opatchutil.jar;%BASE%jlib\opatchprereq.jar;%BASE%jlib\opatchext.jar;%BASE%jlib\opatchfmw.jar;%BASE%jlib\opatchactions.jar;%WEBLOGIC_CLASSPATH%;.\;. -DOPatch.ORACLE_HOME=%OH% -DOPatch.DEBUG=%DEBUGVAL% -DOPatch.RUNNING_DIR=%BASE%  -DOPatch.MW_HOME=%MWH% -DOPatch.WL_HOME=%WL_HOME% -DOPatch.COMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME% %OCM_SERVICE% oracle/opatch/OPatch %PARAMS%

:CALLOPATCHNODEBUG
%JAVA% %JAVA_VM_OPTION% %JRE_MEMORY_OPTIONS% -cp "%BASE%\ocm\lib\emocmutl.jar;%BASE%\ocm\lib\emocmclnt.jar;%CP%\OraInstaller.jar;%CP%\OraPrereq.jar;%CP%\share.jar;%CP%\srvm.jar;%CP%\orai18n-mapping.jar;%CP%\xmlparserv2.jar;%BASE%jlib\opatch.jar;%BASE%jlib\opatchutil.jar;%BASE%jlib\opatchprereq.jar;%BASE%jlib\opatchext.jar;%BASE%jlib\opatchfmw.jar;%BASE%jlib\opatchactions.jar;%WEBLOGIC_CLASSPATH%;.\;." -DOPatch.ORACLE_HOME=%OH% -DOPatch.DEBUG=%DEBUGVAL% -DOPatch.RUNNING_DIR=%BASE% -DOPatch.MW_HOME=%MWH% -DOPatch.WL_HOME=%WL_HOME% -DOPatch.COMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME% %OCM_SERVICE% oracle/opatch/OPatch %PARAMS% 
:OPATCHDONE
set RESULT=%ERRORLEVEL%
if "%ERRORLEVEL%" == "0" goto SUCCEXIT
if "%ERRORLEVEL%" LSS "201" goto FAILEXIT
if "%ERRORLEVEL%" GTR "203" goto WARNEXIT
echo.
echo OPatch stopped on request.
set RESULT=0
goto EXIT

:WARNEXIT
if "%ERRORLEVEL%" GTR "210" goto FAILEXIT
echo.
echo OPatch completed with warnings.
set RESULT=0
goto EXIT

:FAILEXIT
echo.
echo OPatch failed with error code = %RESULT%
goto EXIT

:SUCCEXIT
echo.
echo OPatch succeeded.
goto EXIT

:AUTOERROR
echo.
echo 'opatch auto' is not available on Windows.
goto EXIT

:EXIT
exit /b %RESULT%

