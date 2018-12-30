@echo off
REM ############################################################################
REM # Copyright (c) 2002, 2012, Oracle and/or its affiliates.
REM #  All rights reserved.
REM # Shell Script Wrapper for perl
REM #
REM # $Id: rda.cmd,v 2.14 2012/01/02 14:11:56 mschenke Exp $
REM # ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/bin/rda.cmd,v 2.14 2012/01/02 14:11:56 mschenke Exp $
REM ############################################################################

setlocal

if not "%RDA_CWD%"=="" goto CHDIR
FOR %%D IN ("%CD%") DO set RDA_CWD=%%~sD
:CHDIR
set RDA_DIR=%~dps0.

set PERL_EXE=perl.exe

if not exist %SystemRoot%\SysWOW64 goto NOCMD
if exist %SystemRoot%\Sysnative\cmd.exe goto NOCMD
if not exist %SystemRoot%\system32\cmd.exe goto NOCMD
copy %SystemRoot%\system32\cmd.exe %RDA_CWD% >NUL 2>NUL

:NOCMD
if not exist "rda.cfg" goto CHKENG
set OPT="eol=# tokens=1,2 delims=="
for /F %OPT% %%I in (rda.cfg) do if "%%~J" NEQ "" set INI_%%I=%%~J
cd /d %RDA_DIR%
if "%INI_RDA_ENG%"=="" goto CHKPTH
if "%INI_RDA_EXE%"=="" goto DFTCWD
set RDA_EXE=%RDA_CWD%\%INI_RDA_EXE%
goto UPDEXE

:DFTCWD
set RDA_EXE=%RDA_CWD%\rda.exe
goto UPDEXE
:DFTDIR
set RDA_EXE=%RDA_DIR%\rda.exe
goto UPDEXE

:CHKENG
cd /d %RDA_DIR%
if not exist "engine\rda.cfg" goto CHKPTH
set OPT="eol=# tokens=1,2 delims=="
for /F %OPT% %%I in (engine\rda.cfg) do if "%%~J" NEQ "" set INI_%%I=%%~J
if "%INI_RDA_EXE%"=="" goto DFTDIR
set RDA_EXE=%RDA_DIR%\%INI_RDA_EXE%

:UPDEXE
if "%INI_RDA_ENG%"=="" goto CHKPTH
if not exist "engine\%INI_RDA_ENG%" goto CHKEXE
set RDA_ENG=%RDA_DIR%\engine\%INI_RDA_ENG%
"%RDA_ENG%" -X Upgrade engine "%RDA_EXE%" "%RDA_ENG%"
:CHKEXE
if not exist "%RDA_EXE%" goto CHKPTH
"%RDA_EXE%" %*
goto END

:CHKPTH
if not "%RDA_NO_NATIVE%"=="" goto CHKAPPS
FOR %%I IN (perl.exe) DO set PERL_DIR=%%~dp$PATH:I
if "%PERL_DIR%"=="" goto CHKAPPS
set PERL5OLD=%PERL5LIB%
set PERL5LIB=.
"%PERL_DIR%perl" -e "die 'too old' if $] < 5.005; use strict" >NUL 2>NUL
if NOT ERRORLEVEL 1 goto DBI
set PERL5LIB=%PERL5OLD%

:CHKAPPS
if "%ADPERLPRG%"=="" goto CHKHOME
"%ADPERLPRG%" -e "die 'too old' if $] < 5.005; use strict" >NUL 2>NUL
if ERRORLEVEL 1 goto CHHOME
set PERL_EXE=%ADPERLPRG%
set PERL5LIB=.;%PERL5LIB%
goto DBI

:CHKHOME
if not "%IAS_ORACLE_HOME%"=="" goto CHKIAS
if not "%ORACLE_HOME%"=="" goto CHKORA
FOR %%I IN (sqlplus.exe) DO set ORACLE_BIN=%%~dp$PATH:I...
if "%ORACLE_BIN%"=="..." goto FNDOCM1
set ORA_HOME=%ORACLE_BIN:\bin\...=%
goto CHKPERL

:CHKIAS
set ORA_HOME=%IAS_ORACLE_HOME%
goto UPDPATH

:CHKORA
set ORA_HOME=%ORACLE_HOME%

:UPDPATH
if "%ORA_HOME%"=="" goto FNDOCM1
set PATH=%ORA_HOME%\bin;%PATH%
:CHKPERL
if exist "%ORA_HOME%\Apache\perl\5.00503\bin\MSWin32-x86\perl.exe" goto A553
if exist "%ORA_HOME%\Apache\perl\5.00503\bin\MSWin32-x64\perl.exe" goto A553l
if exist "%ORA_HOME%\Apache\perl\5.00503\bin\MSWin32-IA64\perl.exe" goto A553w
if exist "%ORA_HOME%\perl\5.6.1\bin\MSWin32-x86\perl.exe" goto R561
if exist "%ORA_HOME%\perl\5.6.1\bin\MSWin32-x64\perl.exe" goto R561l
if exist "%ORA_HOME%\perl\5.6.1\bin\MSWin32-IA64\perl.exe" goto R561w
if exist "%ORA_HOME%\perl\5.8.3\bin\MSWin32-x86-multi-thread\perl.exe" goto R583
if exist "%ORA_HOME%\perl\5.8.3\bin\MSWin32-x64-multi-thread\perl.exe" goto R583l
if exist "%ORA_HOME%\perl\5.8.3\bin\MSWin32-IA64-multi-thread\perl.exe" goto R583w
if exist "%ORA_HOME%\perl\bin\perl.exe" goto R510

:FNDOCM1
set ENG_HOME=%~dps0..\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
if "%ORA_HOME%"=="" goto FNDOCM2
set ENG_HOME=%ORA_HOME%\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
set ENG_HOME=%ORA_HOME%\..\oracle_common\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
set ENG_HOME=%ORA_HOME%\..\utils\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
:FNDOCM2
if "%MW_HOME%"=="" goto FNDOCM3
set ENG_HOME=%MW_HOME%\oracle_common\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
set ENG_HOME=%MW_HOME%\utils\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
:FNDOCM3
if "%WL_HOME%"=="" goto FNDOCM4
set ENG_HOME=%WL_HOME%\..\oracle_common\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
set ENG_HOME=%WL_HOME%\..\utils\ccr\engines\Windows
if exist "%ENG_HOME%" goto CHKOCM
:FNDOCM4
if "%ORACLE_CONFIG_HOME%"=="" goto DSPERR
set CCR_PRP=%ORACLE_CONFIG_HOME%\ccr\config\collector.properties
if not exist "%CCR_PRP%" goto DSPERR
set CCR_BIN=
set OPT="eol=# tokens=1,2,* delims==\:"
for /F %OPT% %%I in (%CCR_PRP%) do if "%%I"=="ccr.binHome" set CCR_BIN=%%J:\%%K
if "%CCR_BIN%"=="" goto DSPERR
set ENG_HOME=%CCR_BIN%\engines\Windows
if not exist "%ENG_HOME%" goto DSPERR

:CHKOCM
if exist "%ENG_HOME%\perl\5.8.3\bin\MSWin32-x86-multi-thread\perl.exe" goto O583

:DSPERR
if "%ORACLE_HOME%"=="" goto NOHOME
if "%ORACLE_BIN%"=="..." goto NOHOME
@echo Error: Perl not found in the PATH or in known folder locations.
@echo Although the default RDA engine requires Perl, a compiled version without
@echo Perl requirements is available. Please download the platform-specific RDA
@echo engine from My Oracle Support and place it within the top folder of your
@echo RDA installation.
goto END
:NOHOME
@echo Error: ORACLE_HOME is not set
@echo Please set your ORACLE_HOME.
goto END

:A553
set PATH=%ORA_HOME%\Apache\perl\5.00503\bin\MSWin32-x86;%PATH%
set PERL5LIB=%ORA_HOME%\Apache\perl\5.00503\lib\MSWin32-x86;%ORA_HOME%\Apache\perl\5.00503\lib;.
goto DBI

:A553l
set PATH=%ORA_HOME%\Apache\perl\5.00503\bin\MSWin32-x64;%PATH%
set PERL5LIB=%ORA_HOME%\Apache\perl\5.00503\lib\MSWin32-x64;%ORA_HOME%\Apache\perl\5.00503\lib;.
goto DBI

:A553w
set PATH=%ORA_HOME%\Apache\perl\5.00503\bin\MSWin32-IA64;%PATH%
set PERL5LIB=%ORA_HOME%\Apache\perl\5.00503\lib\MSWin32-IA64;%ORA_HOME%\Apache\perl\5.00503\lib;.
goto DBI

:O583
set PATH=%ENG_HOME%\perl\5.8.3\bin\MSWin32-x86-multi-thread;%PATH%
set PERL5LIB=%ENG_HOME%\perl\5.8.3\lib\MSWin32-x86-multi-thread;%ENG_HOME%\perl\5.8.3\lib;%ENG_HOME%\perl\site\5.8.3\lib\MSWin32-x86-multi-thread;%ENG_HOME%\perl\site\5.8.3\lib;.
goto DBI

:R561
set PATH=%ORA_HOME%\perl\5.6.1\bin\MSWin32-x86;%PATH%
set PERL5LIB=%ORA_HOME%\perl\5.6.1\lib\MSWin32-x86;%ORA_HOME%\perl\5.6.1\lib;.
goto DBI

:R561l
set PATH=%ORA_HOME%\perl\5.6.1\bin\MSWin32-x64;%PATH%
set PERL5LIB=%ORA_HOME%\perl\5.6.1\lib\MSWin32-x64;%ORA_HOME%\perl\5.6.1\lib;.
goto DBI

:R561w
set PATH=%ORA_HOME%\perl\5.6.1\bin\MSWin32-IA64;%PATH%
set PERL5LIB=%ORA_HOME%\perl\5.6.1\lib\MSWin32-IA64;%ORA_HOME%\perl\5.6.1\lib;.
goto DBI

:R583
set PATH=%ORA_HOME%\perl\5.8.3\bin\MSWin32-x86-multi-thread;%PATH%
set PERL5LIB=%ORA_HOME%\perl\5.8.3\lib\MSWin32-x86-multi-thread;%ORA_HOME%\perl\5.8.3\lib;.
goto DBI

:R583l
set PATH=%ORA_HOME%\perl\5.8.3\bin\MSWin32-x64-multi-thread;%PATH%
set PERL5LIB=%ORA_HOME%\perl\5.8.3\lib\MSWin32-x64-multi-thread;%ORA_HOME%\perl\5.8.3\lib;.
goto DBI

:R583w
set PATH=%ORA_HOME%\perl\5.8.3\bin\MSWin32-IA64-multi-thread;%PATH%
set PERL5LIB=%ORA_HOME%\perl\5.8.3\lib\MSWin32-IA64-multi-thread;%ORA_HOME%\perl\5.8.3\lib;.
goto DBI

:R510
set PATH=%ORA_HOME%\perl\bin;%PATH%
set PERL5LIB=%ORA_HOME%\perl\lib;%ORA_HOME%\perl\site\lib;.
goto DBI

:DBI
if not "%RDA_NO_DBD_ORACLE%"=="" goto :EXEC
"%PERL_EXE%" -e "use DBI; use DBD::Oracle;" >NUL 2>NUL
if NOT ERRORLEVEL 1 goto EXEC
set RDA_NO_DBD_ORACLE=1

:EXEC
set PAGER=more
set RDA_NO_PAUSE=1

"%PERL_EXE%" rda.pl %*

:END
endlocal

if not "%1"=="" goto EXIT
pause
:EXIT
