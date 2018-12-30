#!/bin/sh

# Temporary workaround:  normally use a hardcoded wls version (until the
# installer can substitute it for us); but for now, need to work with multiple
# versions.  Choose the highest avail.
if [ -f "${MW_HOME}/utils/config/10.3.3.0/setHomeDirs.sh" ] ; then
  WLS_VER=10.3.3.0
elif [ -f "${MW_HOME}/utils/config/10.3.2.0/setHomeDirs.sh" ] ; then
  WLS_VER=10.3.2.0
elif [ -f "${MW_HOME}/utils/config/10.3.1.0/setHomeDirs.sh" ] ; then
  WLS_VER=10.3.1.0
else
  WLS_VER=10.3
fi

. "${MW_HOME}/utils/config/${WLS_VER}/setHomeDirs.sh"

# Set common components home...
COMMON_COMPONENTS_HOME="${MW_HOME}/oracle_common"
if [ -d "${COMMON_COMPONENTS_HOME}" ] ; then
  COMMON_COMPONENTS_HOME=`cd "${MW_HOME}/oracle_common" ; pwd`
fi
export COMMON_COMPONENTS_HOME

