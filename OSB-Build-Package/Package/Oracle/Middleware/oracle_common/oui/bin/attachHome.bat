@echo off
set CUR_DIR=%~DP0%
cd C:\Oracle\Middleware\oracle_common\\oui\\bin
.\setup.exe -noconsole -detachhome ORACLE_HOME=C:\Oracle\Middleware\oracle_common ORACLE_HOME_NAME=OH1744246877 %*
.\setup.exe -noconsole -attachhome ORACLE_HOME=C:\Oracle\Middleware\oracle_common  ORACLE_HOME_NAME=OH1744246877 %*
if NOT ERRORLEVEL 0  goto fail
goto success
:fail
echo 'AttachHome Failed'
goto end
:success
echo 'AttachHome Successful'
:end
echo "Please see Logs for further details"
cd %CUR_DIR%
