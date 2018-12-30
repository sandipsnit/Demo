#!/bin/sh
# This script assumes WL_HOME is set to the product directory which is the
# target of the uninstall before this script it called.

# Set JAVA Home
JAVA_HOME="D:/OSB/Program"

# Set BEA Home
BEAHOME="C:/Oracle/Middleware"

"${JAVA_HOME}/bin/java" ${JAVA_VM} -Xmx256m -Djava.library.path="${BEAHOME}/utils/uninstall" -Dhome.dir="${BEAHOME}" -Dinstall.dir="${WL_HOME}" -jar "${BEAHOME}/utils/uninstall/uninstall.jar" $*

exit $?
