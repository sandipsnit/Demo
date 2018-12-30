#!/bin/sh
# Copyright (c) 2003, 2008, Oracle. All rights reserved.
%ABSOLUTE_JRE_LOCATION%/bin/java -Doracle.installer.timestamp=$1 -classpath %PROD_HOME%/jlib/OraInstaller.jar:%PROD_HOME%/jlib/ouica.jar:%PROD_HOME%/jlib/xmlparserv2.jar:%PROD_HOME%/jlib/srvm.jar oracle.sysman.oic.ConfigAssistant %ORACLE_HOME% $2 %PROD_HOME%
