@echo off

set WLST_HOME=%OSB_HOME%\common\wlst

set WLST_PROPERTIES=%JAVA_OPTS%

call "%WL_HOME%\common\bin\wlst" %*
