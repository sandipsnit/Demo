#!/bin/sh

#
# This script is called by the OracleAS Upgrade Assistant to
# stop Web Cache procecess in a standalone install from the
# companion CD where there is not OPMN to stop Web Cache.
#
# The Oracle home must be passed to this script.
#

if [ $# -eq 0 ];
then
  echo "The Oracle home path was not specified."
  exit 1
fi

ORACLE_HOME=$1
export ORACLE_HOME

$ORACLE_HOME/webcache/bin/webcachectl stop



