@REM
@REM setWlstEnvExtns.cmd
@REM
@REM Copyright (c) 2008, 2013 Oracle and/or its affiliates.All rights reserved. 
@REM
@REM   NAME
@REM      setWlstEnvExtns.cmd - Calls out to WLST environment-setting scripts
@REM
@REM   DESCRIPTION
@REM      Calls out to classpath-setting scripts that configure the
@REM	classpath for WLST commands.
@REM
@REM    NOTES
@REM      This script is called by wlst.cmd to in turn call out to 
@REM	scripts that set up the classpath for the WLST commands
@REM 	that belong to various components and products.
@REM

SET CURRENT_COMMON_COMPONENTS_HOME=%COMMON_COMPONENTS_HOME%

IF "%COMMON_COMPONENTS_HOME%"=="" (
  SET COMMON_COMPONENTS_HOME=%ORACLE_HOME%
) ELSE (
  IF NOT EXIST "%COMMON_COMPONENTS_HOME%" SET COMMON_COMPONENTS_HOME=%ORACLE_HOME%
)

IF "%CURRENT_HOME%"=="%COMMON_COMPONENTS_HOME%" (
	@REM JRF WLST Environment setting
	IF EXIST %COMMON_COMPONENTS_HOME%\common\bin\setWlstEnv.cmd (
		CALL %COMMON_COMPONENTS_HOME%\common\bin\setWlstEnv.cmd
	)
)

IF "%CURRENT_HOME%"=="%ORACLE_HOME%" (
	@REM SOA WLST Environment setting
	IF EXIST %ORACLE_HOME%\common\bin\setSOAWlstEnv.cmd (
		CALL %ORACLE_HOME%\common\bin\setSOAWlstEnv.cmd
	)

	@REM WC WLST Environment setting
	IF EXIST %ORACLE_HOME%\common\bin\setWebCenterWlstEnv.cmd (
		CALL %ORACLE_HOME%\common\bin\setWebCenterWlstEnv.cmd
	)

	@REM OWLCS WLST Environment setting
	IF EXIST %ORACLE_HOME%\common\bin\setOWLCSWlstEnv.cmd (
		CALL %ORACLE_HOME%\common\bin\setOWLCSWlstEnv.cmd
	)
)

SET COMMON_COMPONENTS_HOME=%CURRENT_COMMON_COMPONENTS_HOME%
