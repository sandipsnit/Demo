@echo off

setlocal

REM ###########################################################
REM # Set the base install directory (Oracle home directory).
REM # Assume the base install directory is one level up from where this
REM # script resides.
REM ###########################################################
set SCRIPT_DIR=%~f0
set BASE_DIR=%SCRIPT_DIR:\bin\psa.bat=%

REM ###########################################################
REM Set the middleware home directory.
REm Assume the middleware home directory is one level up from the base directory.
REM ###########################################################
set MW_HOME=%BASE_DIR%\..

REM ##########################################################
REM Set the JRF directory relative to the base dir
REM ##########################################################
if exist %BASE_DIR%\modules set JRF_DIR=%BASE_DIR%
if exist %MW_HOME%\oracle_common\modules set JRF_DIR=%MW_HOME%\oracle_common
if "%JRF_DIR%" == "" goto :nojrf

REM ##########################################################
REM Execute WebLogic script to define WL_HOME if the script exists
REM ##########################################################
set WL_SCRIPT1=%MW_HOME%\utils\config\10.3\setHomeDirs.cmd
if exist %WL_SCRIPT1% CALL %WL_SCRIPT1%

REM ##########################################################
REM Look for JAVA_HOME in the environment
REM ##########################################################
set SAVED_HOME=%JAVA_HOME%
set WAS_SCRIPT=%MW_HOME%\oracle_common\common\bin\setWasHome.cmd
if exist %WAS_SCRIPT% CALL %WAS_SCRIPT%
if exist %WAS_HOME% set JAVA_HOME=%WAS_HOME%\java
set WL_SCRIPT2=%WL_HOME%\common\bin\commEnv.cmd
if exist %WL_SCRIPT2% CALL %WL_SCRIPT2%
if exist %BASE_DIR%\jdk\bin\java.exe set JAVA_HOME=%BASE_DIR%\jdk

if not "%JAVA_HOME%" == "" goto :javahomefound
if not "%SAVED_HOME%" == "" set JAVA_HOME=%SAVED_HOME%
if "%JAVA_HOME%" == "" goto :nojavahome

:javahomefound
set PATH=%BASE_DIR%\bin;%PATH%

REM ##########################################################
REM Name of the directory that contains the DataDirect JDBC drivers
REM ##########################################################
set DATADIRECT=%JRF_DIR%\modules\datadirect_4.1

REM ##########################################################
REM # List of JDBC drivers
REM ##########################################################
set JDBC=%JRF_DIR%\modules\oracle.jdbc_11.1.1\ojdbc6dms.jar;%JRF_DIR%\modules\oracle.jrf_11.1.1\fmwgenerictoken.jar;%DATADIRECT%\wlsqlserver.jar;%DATADIRECT%\wldb2.jar;%DATADIRECT%\wlsybase.jar;%JRF_DIR%\modules\mysql-connector-java-commercial-5.1.17\mysql-connector-java-commercial-5.1.17-bin.jar;%BASE_DIR%\jlib\postgresql-8.4-701.jdbc4.jar

REM ##########################################################
REM # ODI standalone required
REM ##########################################################
set ODIDIR=%BASE_DIR%\oracledi.sdk\lib
set ODIMISC=%BASE_DIR%\odi_misc
set odidep=%ODIMISC%\ojmisc.jar;%ODIMISC%\help-share.jar;%ODIMISC%\ohj.jar;%ODIMISC%\oracle_ice.jar;%ODIMISC%\share.jar;%ODIMISC%\fmwgenerictokenjar;%ODIMISC%\wlsybase.jar;%ODIMISC%\wldb2.jar;%ODIMISC%\wlsqlserver.jar;%ODIDIR%\hsqldb.jar

REM ##########################################################
REM List of jars needed by the Upgrade Assistant framework
REM ##########################################################
set CLASSPATH=%BASE_DIR%\jlib\ua.jar;%BASE_DIR%\jlib\mrua.jar;%JDBC%;%JRF_DIR%\jlib\rcucommon.jar;%BASE_DIR%\jlib\jewt4.jar;%BASE_DIR%\jlib\SchemaVersion.jar;%JRF_DIR%\modules\oracle.odl_11.1.1\ojdl.jar;%JRF_DIR%\modules\oracle.dms_11.1.1\dms.jar;%JRF_DIR%\modules\oracle.bali.share_11.1.1\share.jar;%JRF_DIR%\modules\oracle.xdk_11.1.0\xmlparserv2.jar;%JRF_DIR%\modules\oracle.ldap_11.1.1\ojmisc.jar;%JRF_DIR%\modules\oracle.help_5.0\help-share.jar;%JRF_DIR%\modules\oracle.help_5.0\ohj.jar;%JRF_DIR%\modules\oracle.help_5.0\oracle_ice.jar;%ODIDEP%

"%JAVA_HOME%\bin\java.exe" -Xmx256m  -Dua.home="%BASE_DIR%" -Dua.wl.home="%WL_HOME%" -Dice.pilots.html4.ignoreNonGenericFonts=true -Dsun.java2d.noddraw=true -Dsun.lang.ClassLoader.allowArraySyntax=true oracle.ias.update.UpgradeDriver %*

goto :exit

:nojavahome
echo JAVA_HOME not found. Set the JAVA_HOME environment variable and rerun.
goto :exit

:nojrf
echo Location of Java Required Files (JRF) not found.

:exit
