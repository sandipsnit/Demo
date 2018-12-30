@echo off
set CUR_DIR=%~DP0%
cd %ORACLE_HOME%\\oui\\bin
.\setup.exe -noconsole -detachhome ORACLE_HOME=%ORACLE_HOME% ORACLE_HOME_NAME=%ORACLE_HOME_NAME% %*
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
