@ECHO OFF
SETLOCAL

rem current middle-ware version
set MW_VER=11.1.1

rem
rem where am I?
rem
set TOOLHOME=%~dp0\..
set TOOLROOT=%~dp0\..\..

rem Locate Java
if (%ORACLE_HOME%) == () goto :check_javahome

if exist %ORACLE_HOME%\jdk\bin\java.exe goto :setjava_orahome

:check_javahome
if (%JAVA_HOME%) == () goto :check_toolhome
 if exist %JAVA_HOME%\bin\java.exe (
    goto :locate_jars
 ) else (
    goto :error_badjavahome
 )

:check_toolhome
if not exist %TOOLHOME%\jdk\bin\java.exe goto :error_nojava
set JAVA_HOME=%TOOLHOME%\jdk
goto :locate_jars

:setjava_orahome
set JAVA_HOME=%ORACLE_HOME%\jdk
goto :locate_jars

:error_badjavahome
echo "ERROR: No Java"
echo "JAVA_HOME should point to valid Java runtime"
goto :exit


:error_nojava
echo "ERROR: No Java"
echo "%TOOLHOME%\jdk or JAVA_HOME should point to valid Java runtime"
goto :exit

rem
rem determine the location of jar files
rem

:locate_jars
if not exist %TOOLROOT%\oracle_common goto :check_srchome
  rem oracle_common exists
  set MW_MOD=%TOOLROOT%\oracle_common\modules
  set PKILOC=%MW_MOD%\oracle.pki_%MW_VER%
  set OSDTLOC=%MW_MOD%\oracle.osdt_%MW_VER%
  set MISCLOC=%TOOLHOME%\jlib
  goto set_jars

:check_srchome
if (%SRCHOME%) == () goto :check_orahome
  rem SRCHOME is defined
  set PROD_DIST=%SRCHOME%\entsec\dist\oracle.jrf.opss\modules
  set PKILOC=%PROD_DIST%\oracle.pki_%MW_VER%
  set OSDTLOC=%PROD_DIST%\oracle.osdt_%MW_VER%
  set MISCLOC=%SRCHOME%\entsec\dist\oracle.jrf.opss\modules\oracle.ldap_%MW_VER%
  goto :set_jars

:check_orahome
if (%ORACLE_HOME%) == () goto :no_orahome
if not exist %ORACLE_HOME% goto :no_orahome
  set OJLIB=%ORACLE_HOME%\jlib
  set PKILOC=%OJLIB%
  set OSDTLOC=%OJLIB%
  set MISCLOC=%OJLIB%
  goto :set_jars

:no_orahome
  set OJLIB=%TOOLHOME%\jlib
  set PKILOC=%OJLIB%
  set OSDTLOC=%OJLIB%
  set MISCLOC=%OJLIB%

:set_jars
set PKI=%PKILOC%\oraclepki.jar
set OSDT_CORE=%OSDTLOC%\osdt_core.jar
set OSDT_CERT=%OSDTLOC%\osdt_cert.jar
set OJMISC=%MISCLOC%\ojmisc.jar

:run_tool
%JAVA_HOME%\bin\java -classpath %PKI%;%OJMISC%;%OSDT_CORE%;%OSDT_CERT% oracle.security.pki.textui.OraclePKITextUI %*

goto :exit

:exit
endlocal

