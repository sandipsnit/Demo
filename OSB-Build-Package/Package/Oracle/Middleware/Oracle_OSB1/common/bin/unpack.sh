#!/bin/sh

mypwd="`pwd`"

# Determine the location of this script...
# Note: this will not work if the script is sourced (. ./unpack.sh)
SCRIPTNAME=$0
case ${SCRIPTNAME} in
 /*)  SCRIPTPATH=`dirname "${SCRIPTNAME}"` ;;
  *)  SCRIPTPATH=`dirname "${mypwd}/${SCRIPTNAME}"` ;;
esac

# Set the ORACLE_HOME relative to this script...
ORACLE_HOME=`cd "${SCRIPTPATH}/../.." ; pwd`
export ORACLE_HOME

# Set the MW_HOME relative to the ORACLE_HOME...
MW_HOME=`cd "${ORACLE_HOME}/.." ; pwd`
export MW_HOME

# Set the home directories...
. "${SCRIPTPATH}/setHomeDirs.sh"

# Set the config jvm args...
CONFIG_JVM_ARGS="${CONFIG_JVM_ARGS} -DCOMMON_COMPONENTS_HOME='${COMMON_COMPONENTS_HOME}'"
export CONFIG_JVM_ARGS

# Delegate to the main script...
"${WL_HOME}/common/bin/unpack.sh" "$@"
