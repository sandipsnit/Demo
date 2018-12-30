@echo off

:: Get the OCM Home.
for %%i in (%~sf0\..) do set OCM_HOME=%%~dspi

:: Get parent of OCM Home
for %%i in (%~sf0\..\..) do set OCM_HOME_PARENT=%%~dspi

::
:: Java Home is set in JAVA_HOME_CCR when OCM is installed through OUI.
:: So use JAVA_HOME_CCR when it is available
::

set TEMP_JAVA_HOME=

if NOT "%JAVA_HOME_CCR%" == "" set TEMP_JAVA_HOME=%JAVA_HOME_CCR%
if NOT "%TEMP_JAVA_HOME%" == "" GOTO exec_OCMJarUtil

::
:: Java Home is set only in CCR_JAVA_HOME when livelink_packages.pl is called.
:: So use CCR_JAVA_HOME when it is available
::

if NOT "%CCR_JAVA_HOME%" == "" set TEMP_JAVA_HOME=%CCR_JAVA_HOME%
if NOT "%TEMP_JAVA_HOME%" == "" GOTO exec_OCMJarUtil


::
:: Get java home If java_home env variable is set.
::
if NOT "%JAVA_HOME%" == "" set TEMP_JAVA_HOME=%JAVA_HOME%
if NOT "%TEMP_JAVA_HOME%" == "" GOTO exec_OCMJarUtil

:: :::::::::::::::::::::::::::::::::::
::
:: AUTO DETECT JDK/JRE
::
:: :::::::::::::::::::::::::::::::::::

:: get java home from emocmutl.vbs if that script is available for this bat.
if not exist  %OCM_HOME%lib\emocmutl.vbs GOTO get_from_ocmhome
cscript //nologo %OCM_HOME%lib\emocmutl.vbs check_java_prereqs 
if NOT %ERRORLEVEL% == 0 exit /b %ERRORLEVEL%

:: Get Java Home
for /F "tokens=1-4 delims=," %%A in ('cscript //nologo %OCM_HOME%lib\emocmutl.vbs get_env') do set TEMP_JAVA_HOME=%%D
GOTO exec_OCMJarUtil

::
::get jdk/jre home from oracle home of ccr.
::
:get_from_ocmhome
if exist %OCM_HOME_PARENT%jre\bin\java.exe set TEMP_JAVA_HOME=%OCM_HOME_PARENT%jre

if exist %OCM_HOME_PARENT%jdk\bin\java.exe set TEMP_JAVA_HOME=%OCM_HOME_PARENT%jdk

:exec_OCMJarUtil
if "%TEMP_JAVA_HOME%" == "" echo "ERROR: Java Home is not found in ocmJarUtil.bat"
if "%TEMP_JAVA_HOME%" == "" exit 1

"%TEMP_JAVA_HOME%\bin\java.exe" -classpath %OCM_HOME%\bin OCMJarUtil %*

