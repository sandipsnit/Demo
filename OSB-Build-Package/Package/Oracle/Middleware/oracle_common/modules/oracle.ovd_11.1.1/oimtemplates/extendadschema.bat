@echo off

IF "%ORACLE_HOME%x"=="x" GOTO OH_MISSING
IF NOT EXIST %ORACLE_HOME%\nul GOTO OH_NOTEXIST

IF "%JAVA_HOME%x" EQU "x" (
   SET JAVA_HOME=%ORACLE_HOME%\jdk
)

IF NOT EXIST %JAVA_HOME%\nul GOTO JAVA_HOME_NOTEXIST

SET CLASSPATH=%ORACLE_HOME%\..\oracle_common\modules\oracle.ovd_11.1.1\ovd.jar;

%JAVA_HOME%\bin\java -classpath %CLASSPATH% oracle.ods.virtualization.engine.util.ADSchemaExtendUtil %*

GOTO END

:OH_MISSING
   ECHO "Environment variable ORACLE_HOME is not set. Set $ORACLE_HOME and retry."
   GOTO END

:JAVA_HOME_NOTEXIST
   ECHO "JAVA_HOME directory does not exist."
   GOTO END

:END

