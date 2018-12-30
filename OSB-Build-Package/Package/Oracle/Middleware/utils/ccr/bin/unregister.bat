@echo off
set FILE="C:\Oracle\Middleware/utils/ccr/bin/configCCR.exe"
set MYCOMMAND=%FILE% -r
if exist %FILE% %MYCOMMAND%
