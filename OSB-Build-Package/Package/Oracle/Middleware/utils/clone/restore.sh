#!/bin/sh

JAVA_HOME=$1

if [ "$JAVA_HOME" = "" ] ; then
	echo "USAGE $0 <JAVA_HOME>"
	return 1
fi

# Note: this will not work if the script is sourced (. ./restore.sh)
mypwd="`pwd`"
SCRIPTNAME=$0
case ${SCRIPTNAME} in
 /*)  SCRIPTPATH=`dirname ${SCRIPTNAME}` ;;
  *)  SCRIPTPATH=`dirname ${mypwd}/${SCRIPTNAME}` ;;
esac
export SCRIPTPATH

"${JAVA_HOME}/bin/java" -jar ${SCRIPTPATH}/clone.jar -option=restore -cloneXML="${SCRIPTPATH}/clone.xml"

exit $?

