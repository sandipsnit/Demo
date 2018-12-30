@echo off
set CUR_DIR=%~DP0%
cd C:\Oracle\Middleware\Oracle_OSB1\\oui\\bin
.\setup.exe -noconsole -detachhome ORACLE_HOME=C:\Oracle\Middleware\Oracle_OSB1 ORACLE_HOME_NAME=OH569619429 %*
if NOT ERRORLEVEL 0  goto fail
goto success
:fail
echo 'DetachHome Failed'
goto end
:success
echo 'DetachHome Successful'
:end
echo "Please see Logs for further details"
cd %CUR_DIR%
