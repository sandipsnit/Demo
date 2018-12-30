#!/bin/sh

mypwd="`pwd`"

# Determine the location of this script...
# Note: this will not work if the script is sourced (. ./wsadmin.sh)
SCRIPTNAME=$0
case ${SCRIPTNAME} in
 /*)  SCRIPTPATH=`dirname "${SCRIPTNAME}"` ;;
  *)  SCRIPTPATH=`dirname "${mypwd}/${SCRIPTNAME}"` ;;
esac

# Set the ORACLE_HOME relative to this script...
ORACLE_HOME=`cd "${SCRIPTPATH}/../.." ; pwd`

# Set the MW_HOME relative to the ORACLE_HOME...
MW_HOME=`cd "${ORACLE_HOME}/.." ; pwd`
export MW_HOME

# Set the home directories...
. "${SCRIPTPATH}/setHomeDirs.sh"

# Add extensions
if [ -r "${SCRIPTPATH}"/setWsadminEnv.sh ]
then
  . "${SCRIPTPATH}"/setWsadminEnv.sh 
fi

# Delegate to the main script...
"${COMMON_COMPONENTS_HOME}/common/bin/wsadmin.sh" "$@"
