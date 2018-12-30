@ECHO OFF

SET JAVA_HOME=%1

IF "%JAVA_HOME%"=="" (
  ECHO "USAGE %0 <JAVA_HOME>"
  GOTO :EOF
)

SET SCRIPTPATH=%~dp0
FOR %%i IN ("%SCRIPTPATH%") DO SET SCRIPTPATH=%%~fsi

"%JAVA_HOME%\bin\java" -jar %SCRIPTPATH%\clone.jar -option=restore -cloneXML="%SCRIPTPATH%\clone.xml"

EXIT /B %ERRORLEVEL%
