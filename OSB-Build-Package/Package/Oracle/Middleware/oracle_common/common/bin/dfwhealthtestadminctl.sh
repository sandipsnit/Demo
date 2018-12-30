#!/bin/sh
#
# $Header: ade sccs line
#
# dfwhealthtestadminctl.sh
#
# Copyright (c) 2007, 2011, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      dfwhealthtestadminctl.sh - administrator CLI command script
#
#    DESCRIPTION
#      This is the main script for performing operations using the
#      Diagnostics Engine. This script can be invoked with the "register",
#      "unregister","index" verbs.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)  Comments
#       lwong   02/20/12  - Created

source dfwhealthtestcommon.sh

#######################
## Launch DiagControl 
##
cmd="$JAVA_HOME/bin/java -classpath \"${CLASSPATH}\" ${DIAG_JAVA_OPTIONS} oracle.dfw.healthtest.cli.DiagControl $PARAMS clitype=admin"

#echo "cmd=$cmd"
eval $cmd

exitCode=$?
exit $exitCode



