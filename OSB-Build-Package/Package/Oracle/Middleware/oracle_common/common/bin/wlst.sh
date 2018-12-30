#!/bin/sh

mypwd="`pwd`"

case `uname -s` in
Windows_NT*)
  CLASSPATHSEP=\;
;;
CYGWIN*)
  CLASSPATHSEP=\;
;;
*)
  CLASSPATHSEP=:
;;
esac

# Determine the location of this script...
# Note: this will not work if the script is sourced (. ./wlst.sh)
SCRIPTNAME=$0
case ${SCRIPTNAME} in
 /*)  SCRIPTPATH=`dirname "${SCRIPTNAME}"` ;;
  *)  SCRIPTPATH=`dirname "${mypwd}/${SCRIPTNAME}"` ;;
esac

# Set CURRENT_HOME...
CURRENT_HOME=`cd "${SCRIPTPATH}/../.." ; pwd`
export CURRENT_HOME

# Set the MW_HOME relative to the CURRENT_HOME...
MW_HOME=`cd "${CURRENT_HOME}/.." ; pwd`
export MW_HOME

# Set the home directories...
. "${SCRIPTPATH}/setHomeDirs.sh"

# Set the DELEGATE_ORACLE_HOME to CURRENT_HOME if it's not set...
ORACLE_HOME="${DELEGATE_ORACLE_HOME:=${CURRENT_HOME}}"
export DELEGATE_ORACLE_HOME ORACLE_HOME

# Set the directory to get wlst commands from...
COMMON_WLST_HOME="${COMMON_COMPONENTS_HOME}/common/wlst"
WLST_HOME="${COMMON_WLST_HOME}${CLASSPATHSEP}${WLST_HOME}"
export WLST_HOME

# Some scripts in WLST_HOME reference ORACLE_HOME
WLST_PROPERTIES="${WLST_PROPERTIES} -DORACLE_HOME='${ORACLE_HOME}' -DCOMMON_COMPONENTS_HOME='${COMMON_COMPONENTS_HOME}'"
export WLST_PROPERTIES

# Set the WLST extended env...  
if [ -f "${COMMON_COMPONENTS_HOME}"/common/bin/setWlstEnv.sh ] ; then
  . "${COMMON_COMPONENTS_HOME}"/common/bin/setWlstEnv.sh
fi

# Appending additional jar files to the CLASSPATH...
if [ -d "${COMMON_WLST_HOME}/lib" ] ; then
  for file in "${COMMON_WLST_HOME}"/lib/*.jar ; do
    CLASSPATH="${CLASSPATH}${CLASSPATHSEP}${file}"
  done
fi

# Appending additional resource bundles to the CLASSPATH...
if [ -d "${COMMON_WLST_HOME}/resources" ] ; then
  for file in "${COMMON_WLST_HOME}"/resources/*.jar ; do
    CLASSPATH="${CLASSPATH}${CLASSPATHSEP}${file}"
  done 
fi

export CLASSPATH

# Delegate to the main script...
"${WL_HOME}/common/bin/wlst.sh" "$@"
