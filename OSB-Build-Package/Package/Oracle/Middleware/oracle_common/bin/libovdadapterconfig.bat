@echo off

IF "%ORACLE_HOME%x"=="x" GOTO OH_MISSING
IF NOT EXIST %ORACLE_HOME%\nul GOTO OH_NOTEXIST

IF "%WL_HOME%x" EQU "x" (
   IF "%WAS_HOME%x" EQU "x" (
   GOTO WL_WAS_MISSING
   )
)

IF "%WL_HOME%x" NEQ "x" (
   IF "%WAS_HOME%x" NEQ "x" (
   GOTO WL_WAS_EXIST
   )
)

IF "%WL_HOME%x" NEQ "x" (
   IF NOT EXIST %WL_HOME%\nul (
      GOTO WL_HOME_NOTEXIST
   )
      SET CLASSPATH=%WL_HOME%\server\lib\wljmxclient.jar;
)
   
IF "%WAS_HOME%x" NEQ "x" (
   IF NOT EXIST %WAS_HOME%\nul (
      GOTO WAS_HOME_NOTEXIST
   )
      SET CLASSPATH=%WAS_HOME%\runtimes\com.ibm.ws.admin.client_7.0.0.jar;
      SET JAVA_HOME=%WAS_HOME%\java
)
   
IF "%JAVA_HOME%x" EQU "x" (
   SET JAVA_HOME=%ORACLE_HOME%\jdk
)

IF NOT EXIST %JAVA_HOME%\nul GOTO JAVA_HOME_NOTEXIST

SET CLASSPATH=%ORACLE_HOME%\..\oracle_common\modules\oracle.jps_11.1.1\jps-manifest.jar;%ORACLE_HOME%\..\oracle_common\modules\oracle.jps_11.1.1\jps-mbeans.jar;%ORACLE_HOME%\..\oracle_common\modules\oracle.ovd_11.1.1\ovd.jar;%ORACLE_HOME%\..\oracle_common\modules\oracle.ovd_11.1.1\plugins.jar;%ORACLE_HOME%\..\oracle_common\modules\args4j-2.0.9.jar;%ORACLE_HOME%\..\oracle_common\modules\oracle.xdk_11.1.0\xmlparserv2.jar;%ORACLE_HOME%\..\oracle_common\modules\oracle.odl_11.1.1\ojdl.jar;%ORACLE_HOME%\..\oracle_common\modules\oracle.dms_11.1.1\dms.jar;%CLASSPATH%;

%JAVA_HOME%\bin\java -classpath %CLASSPATH% oracle.ods.virtualization.config.TemplateAdapter %*

GOTO END

:OH_MISSING
   ECHO "Environment variable ORACLE_HOME is not set. Set $ORACLE_HOME and retry."
   GOTO END

:OH_NOTEXIST
   ECHO "ORACLE_HOME directory does not exist."
   GOTO END

:JAVA_HOME_NOTEXIST
   ECHO "JAVA_HOME directory does not exist."
   GOTO END

:WL_HOME_NOTEXIST
   ECHO "WL_HOME does not exist."
   GOTO END

:WAS_HOME_NOTEXIST
   ECHO "WAS_HOME does not exist."
   GOTO END

:WL_WAS_MISSING
   ECHO "Environment variable WL_HOME/WAS_HOME is not set. Set WL_HOME for Weblogic or WAS_HOME for Websphere and retry."
   GOTO END

:WL_WAS_EXIST
   ECHO "Both WL_HOME and WAS_HOME are set. Only one environment variable should be set."
   GOTO END

:END

