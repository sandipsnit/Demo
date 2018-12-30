#!/bin/sh

WLST_HOME="$OSB_HOME/common/wlst"
export WLST_HOME

WLST_PROPERTIES="$JAVA_OPTS"
export WLST_PROPERTIES

"$WL_HOME/common/bin/wlst.sh" $*
