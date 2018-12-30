@ECHO OFF

@REM Temporary workaround:  normally use a hardcoded wls version (until the
@REM installer can substitute it for us); but for now, need to work with multiple
@REM versions.  Choose the highest avail.
IF EXIST "%MW_HOME%\utils\config\10.3.3.0\setHomeDirs.cmd" (
  SET WLS_VER=10.3.3.0
) ELSE IF EXIST "%MW_HOME%\utils\config\10.3.2.0\setHomeDirs.cmd" (
  SET WLS_VER=10.3.2.0
) ELSE IF EXIST "%MW_HOME%\utils\config\10.3.1.0\setHomeDirs.cmd" (
  SET WLS_VER=10.3.1.0
) ELSE (
  SET WLS_VER=10.3
)

IF EXIST "%MW_HOME%\utils\config\%WLS_VER%\setHomeDirs.cmd" (
  CALL "%MW_HOME%\utils\config\%WLS_VER%\setHomeDirs.cmd"
)

@REM Set common components home...
SET COMMON_COMPONENTS_HOME=%MW_HOME%\oracle_common
IF EXIST %COMMON_COMPONENTS_HOME% FOR %%i IN ("%MW_HOME%\oracle_common") DO SET COMMON_COMPONENTS_HOME=%%~fsi

