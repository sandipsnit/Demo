@echo off
set CUR_DIR=%~DP0%
cd %ORACLE_HOME%\\oui\\bin
.\setup.exe -noconsole -detachhome ORACLE_HOME=%ORACLE_HOME% ORACLE_HOME_NAME=%ORACLE_HOME_NAME% %*
.\setup.exe -noconsole -attachhome ORACLE_HOME=%ORACLE_HOME%  ORACLE_HOME_NAME=%ORACLE_HOME_NAME% %*
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
