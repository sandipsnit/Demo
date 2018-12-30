@echo off
REM ###########################################################################
REM #
REM # $Header: omsca.bat 17-apr-2008.10:22:36 rmaggarw Exp $
REM #
REM # Copyright (c) 2004, Oracle Corporation.  All rights reserved.
REM #
REM # PRODUCT
REM #       Oracle Enterprise Manager
REM #
REM # FILENAME
REM #       omsca.bat
REM #
REM # DESCRIPTION
REM #		Wrapper script for omsca.pl
REM #
REM # NOTES
REM # 
REM # MODIFIED   (MM/DD/YY)
REM #  rmaggarw   04/16/08 - Created
REM ################################################################################
REM #
setlocal

#
# Make sure certain environment variables are set
#

if not defined ORACLE_HOME (
echo "ORACLE_HOME undefined. You need to set ORACLE_HOME to your Oracle software directory\n"
    set errorlevel=1
    goto :EXIT
    )

if not exist %ORACLE_HOME%\jdk\bin (
echo "Java not found. You may need to set ORACLE_HOME to your Oracle software directory\n"
    set errorlevel=1
    goto :EXIT
    )


set JAVA_HOME=%ORACLE_HOME%\jdk

set PERL5LIB=%ORACLE_HOME%\perl\lib;%ORACLE_HOME%\perl\lib\site_perl;%ORACLE_HOME%\perl\site\lib;%PERL5LIB%

set PATH=%ORACLE_HOME%\%EMPERLOHBIN%;%ORACLE_HOME%\bin;%PATH%

%ORACLE_HOME%\perl\bin\perl -w %ORACLE_HOME%\bin\omsca.pl $*

endlocal

:EXIT
if defined NEED_EXIT_CODE exit %errorlevel%
