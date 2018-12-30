@ECHO OFF
SETLOCAL

SET JAVA_HOME=D:\OSB\Program
FOR %%i IN ("%JAVA_HOME%") DO SET JAVA_HOME=%%~fsi

SET JAVA=%1
IF DEFINED JAVA (
  SET JAVA=java
) ELSE (
  SET JAVA=javaw
)

set MEM_ARGS=-Xms256m -Xmx512m

"%JAVA_HOME%\bin\%JAVA%" %MEM_ARGS% -jar patch-client.jar %*

ENDLOCAL
