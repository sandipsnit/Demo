REM Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
REM All rights reserved. 
"D:\OSB\Program\jre\bin\java" -classpath "C:\Oracle\Middleware\oracle_common\oui\jlib\OraInstallerNet.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\OraInstaller.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\xmlparserv2.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\srvm.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\emCfg.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\share.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\ojmisc.jar;C:\Oracle\Middleware\oracle_common\oui\jlib\xml.jar" oracle.sysman.oii.oiic.OiicRunConfig C:\Oracle\Middleware\oracle_common\oui %* 
exit /b %ERRORLEVEL%
