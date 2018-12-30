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

set MODULES=%COMMON_COMPONENTS_HOME%\modules
if not defined CIE_MODULES set CIE_MODULES=%MODULES%
if not defined CIE_L10N_MODULES set CIE_L10N_MODULES=%CIE_MODULES%

set CIE_CLASSPATH=%CIE_MODULES%\com.oracle.cie.config-was-patch_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.de_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.es_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.fr_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.it_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.ja_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.ko_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.pt.BR_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.zh.CN_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config-was.zh.TW_7.2.0.0.jar;%CIE_MODULES%\com.oracle.cie.config-was_7.2.0.0.jar;%CIE_MODULES%\com.oracle.cie.config-was-schema_7.0.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.de_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.es_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.fr_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.it_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.ja_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.ko_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.pt.BR_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.zh.CN_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.config.zh.TW_7.2.0.0.jar;%CIE_MODULES%\com.oracle.cie.config_7.2.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.de_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.es_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.fr_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.it_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.ja_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.ko_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.pt.BR_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.zh.CN_6.1.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.wizard.zh.TW_6.1.0.0.jar;%CIE_MODULES%\com.oracle.cie.wizard_6.1.0.0.jar;%CIE_MODULES%\com.oracle.cie.oui_1.3.0.0.jar;%CIE_MODULES%\com.oracle.cie.xmldh_2.5.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.de_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.es_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.fr_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.it_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.ja_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.ko_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.pt.BR_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.zh.CN_6.4.0.0.jar;%CIE_L10N_MODULES%\com.oracle.cie.comdev.zh.TW_6.4.0.0.jar;%CIE_MODULES%\com.oracle.cie.comdev_6.4.0.0.jar;%MODULES%\com.oracle.cie.security_1.0.0.0\com.oracle.cie.encryption_1.0.0.0.jar;%CIE_MODULES%\com.bea.core.xml.xmlbeans_2.1.0.0_2-5-1.jar;%CIE_MODULES%\javax.xml.stream_1.1.1.0.jar

set CIE_LIBS=%COMMON_COMPONENTS_HOME%\common\wsadmin

if exist %SCRIPTPATH%\setWsadminEnv.cmd call %SCRIPTPATH%\setWsadminEnv.cmd

call :TmpDir
if not defined CIE_TMPDIR for /L %%i in (1, 1, 3) do call :TmpDir %%i
if not defined CIE_TMPDIR (
  echo Unable to create tmp directory
  goto :eof
) 

set TMP_PROPFILE=%CIE_TMPDIR%\tmp\omwconfig.properties
>  %TMP_PROPFILE% echo # CIE Config Properties.
>> %TMP_PROPFILE% echo # wsadmin properties.
>> %TMP_PROPFILE% echo com.ibm.ws.scripting.defaultLang=jython
>> %TMP_PROPFILE% echo com.ibm.ws.scripting.connectionType=NONE
if defined WSADMIN_CLASSPATH (
  >> %TMP_PROPFILE% echo com.ibm.ws.scripting.classpath=%CIE_CLASSPATH:\=\\%;\
  >> %TMP_PROPFILE% echo %WSADMIN_CLASSPATH:\=\\%
) else (
  >> %TMP_PROPFILE% echo com.ibm.ws.scripting.classpath=%CIE_CLASSPATH:\=\\%
)
>> %TMP_PROPFILE% echo wsadmin.script.libraries=%CIE_LIBS:\=\\%;%WSADMIN_SCRIPT_LIBRARIES:\=\\%
>> %TMP_PROPFILE% echo # CIE properties.
>> %TMP_PROPFILE% echo com.oracle.cie.libs=%CIE_LIBS:\=\\%
>> %TMP_PROPFILE% echo WAS_HOME=%WAS_HOME:\=\\%
>> %TMP_PROPFILE% echo MW_HOME=%MW_HOME:\=\\%
>> %TMP_PROPFILE% echo COMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME:\=\\%
>> %TMP_PROPFILE% echo CIE_TMP=%CIE_TMPDIR:\=\\%\\tmp
if defined CIE_LOG >> %TMP_PROPFILE% echo oracle.cie.log=%CIE_LOG:\=\\%
if defined CIE_LOG_PRIORITY >> %TMP_PROPFILE% echo oracle.cie.log.priority=%CIE_LOG_PRIORITY%

call %WAS_HOME%\bin\wsadmin.bat -profile %CIE_LIBS%\OracleMWConfigLoader.py -p %TMP_PROPFILE% %*

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
