@echo off

@rem Copyright (c) 2009, Oracle and/or its affiliates. All rights reserved. 

setlocal

@rem Determine the location of this script...
set SCRIPTPATH=%~dp0
for %%i in ("%SCRIPTPATH%") do set SCRIPTPATH=%%~fsi

@rem Set MW_HOME relative to this script if not set elsewhere...
if not defined MW_HOME set MW_HOME=%SCRIPTPATH%\..\..\..
for %%i in ("%MW_HOME%") do set MW_HOME=%%~fsi

@rem Set COMMON_COMPONENTS_HOME relative to this script if not set elsewhere...
if not defined COMMON_COMPONENTS_HOME set COMMON_COMPONENTS_HOME=%SCRIPTPATH%\..\..
for %%i in ("%COMMON_COMPONENTS_HOME%") do set COMMON_COMPONENTS_HOME=%%~fsi

if not defined WAS_HOME (
  if exist %COMMON_COMPONENTS_HOME%\common\bin\setWasHome.cmd call %COMMON_COMPONENTS_HOME%\common\bin\setWasHome.cmd
  if not defined WAS_HOME (
    echo WAS_HOME is not set
    exit /b 1
  )
)
for %%i in ("%WAS_HOME%") do set WAS_HOME=%%~fsi
if not exist %WAS_HOME%\lib\startup.jar (
  echo WAS_HOME is not a valid WebSphere directory:  %WAS_HOME%
  exit /b 1
)

set JAVA_HOME=%WAS_HOME%\java

set MODULES=%COMMON_COMPONENTS_HOME%\modules
if not defined CIE_MODULES set CIE_MODULES=%MODULES%
if not defined CIE_L10N_MODULES set CIE_L10N_MODULES=%CIE_MODULES%

set JDBC_DRIVER_CLASSPATH=%MODULES%\oracle.jdbc_11.1.1\ojdbc6dms.jar;%MODULES%\oracle.odl_11.1.1\ojdl.jar;%MODULES%\oracle.dms_11.1.1\dms.jar;%DB_DRIVER_CLASSPATH%

set CIE_CLASSPATH=%CIE_MODULES%\com.oracle.cie.config-was-patch_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.de_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.es_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.fr_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.it_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.ja_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.ko_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.pt.BR_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.zh.CN_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.zh.TW_7.2.0.0.jar;%CIE_MODULES%\com.oracle.cie.config-was_7.2.0.0.jar;%CIE_MODULES%\com.oracle.cie.config-was-schema_7.0.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.de_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.es_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.fr_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.it_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.ja_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.ko_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.pt.BR_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.zh.CN_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.zh.TW_7.2.0.0.jar;%CIE_MODULES%\com.oracle.cie.config_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.de_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.es_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.fr_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.it_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.ja_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.ko_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.pt.BR_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.zh.CN_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.zh.TW_6.1.0.0.jar;%CIE_MODULES%\com.oracle.cie.wizard_6.1.0.0.jar;%CIE_MODULES%\com.oracle.cie.oui_1.3.0.0.jar;%CIE_MODULES%\com.oracle.cie.xmldh_2.5.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.de_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.es_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.fr_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.it_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.ja_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.ko_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.pt.BR_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.zh.CN_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.zh.TW_6.4.0.0.jar;%CIE_MODULES%\com.oracle.cie.comdev_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.de_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.es_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.fr_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.it_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.ja_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.ko_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.pt.BR_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.zh.CN_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf.zh.TW_5.3.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wlw-plaf_5.3.0.0.jar;%MODULES%\com.oracle.cie.security_1.0.0.0\com.oracle.cie.encryption_1.0.0.0.jar;%CIE_MODULES%\com.bea.core.xml.xmlbeans_2.1.0.0_2-5-1.jar;%CIE_MODULES%\javax.xml.stream_1.1.1.0.jar;%JDBC_DRIVER_CLASSPATH%

if exist %SCRIPTPATH%\setWasConfigEnv.cmd call %SCRIPTPATH%\setWasConfigEnv.cmd
if defined WASCONFIG_CLASSPATH (
  set CLASSPATH=%CIE_CLASSPATH%;%WASCONFIG_CLASSPATH%
) else (
  set CLASSPATH=%CIE_CLASSPATH%
)

set CIE_LIBS=%COMMON_COMPONENTS_HOME%\common\wsadmin

call :TmpDir
if not defined CIE_TMPDIR for /L %%i in (1, 1, 3) do call :TmpDir %%i
if not defined CIE_TMPDIR (
  echo Unable to create tmp directory
  goto :eof
) 

call %JAVA_HOME%\bin\java %CONFIG_JVM_ARGS% -DMW_HOME=%MW_HOME% -DWAS_HOME=%WAS_HOME% -DCOMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME% -Dcom.oracle.cie.libs=%CIE_LIBS% -DCIE_TMPDIR=%CIE_TMPDIR%\tmp com.oracle.cie.wizard.WizardController %*

rmdir /q /s %CIE_TMPDIR%
goto :eof

:TmpDir
if defined CIE_TMPDIR goto :eof
set DIRNAME=%TEMP%\omwc%RANDOM%
if exist %DIRNAME% goto :eof
mkdir %DIRNAME%
if errorlevel 1 (
  echo Error creating tmp directory
  goto :eof
)
echo Y| cacls %DIRNAME% /g %USERDOMAIN%\%USERNAME%:f >nul:
mkdir %DIRNAME%\tmp
if errorlevel 1 (
  rmdir /q /s %DIRNAME%
  echo Problem creating secure tmp directory
  goto :eof
)
set CIE_TMPDIR=%DIRNAME%
