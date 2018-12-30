#!/bin/sh
#
# $Header: emagent/scripts/unix/patchnfs.sh /st_emagent_10.2.0.1.0/3 2009/01/20 04:47:45 sthergao Exp $
#
# patchnfs.sh
#
# Copyright (c) 2008, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      patchnfs.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    supal       01/17/09 - Add timestamps
#    sthergao    06/03/08 - Creation
#


OraHome=$ORACLE_HOME;
emState=$EMSTATE;


LogFile=$emState/sysman/log/nfsPatchPlug.log

date >> $LogFile
#$emState/bin/emctl stop agent >> $LogFile
#CommandStatus=$?

#echo $CommandStatus >> $LogFile


while [  -f $ORACLE_HOME/agentpatch/patchstarted ]
 do 
  sleep 30
  continue
 done


date >> $LogFile
$emState/bin/emctl start agent >> $LogFile
CommandStatus=$?
echo $CommandStatus>> $LogFile











