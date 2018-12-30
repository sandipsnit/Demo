#!/bin/sh
#
# $Header: ade sccs line
#
# dfwhealthtestctl.sh
#
# Copyright (c) 2007, 2011, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      dfwhealthtestctl.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      This is the main script for performing operations using the
#      Diagnostics Engine. This script can be invoked with the "run",
#      "status","register","query", "report" and "help" verbs.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)  Comments
#       lwong   02/06/12  - add lucene jar
#       lwong   09/21/11  - add new library dependency
#       lwong   09/15/11  - remove $AVR usage and strip_path.awk dependency
#       lwong   09/08/11  - Created

source dfwhealthtestcommon.sh

#######################
## Launch DiagControl 
##
cmd="$JAVA_HOME/bin/java -classpath \"${CLASSPATH}\" ${DIAG_JAVA_OPTIONS} oracle.dfw.healthtest.cli.DiagControl $PARAMS"

#echo "cmd=$cmd"
eval $cmd

exitCode=$?
exit $exitCode



