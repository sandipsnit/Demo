@ECHO OFF

SET JAVA_HOME=%1

IF "%JAVA_HOME%"=="" (
  ECHO "USAGE %0 <JAVA_HOME> <ARCHIVE_PATH>"
  GOTO :EOF
)

SET SCRIPTPATH=%~dp0
FOR %%i IN ("%SCRIPTPATH%") DO SET SCRIPTPATH=%%~fsi

"%JAVA_HOME%\bin\java" -jar %SCRIPTPATH%\clone.jar -option=clone -cloneXML="%SCRIPTPATH%\clone.xml" -archive="%2"

EXIT /B %ERRORLEVEL%
