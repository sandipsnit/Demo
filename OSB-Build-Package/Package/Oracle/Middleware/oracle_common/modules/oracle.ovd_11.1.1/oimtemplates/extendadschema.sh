#!/bin/sh

if [ "${ORACLE_HOME}" = "" ]; then
   echo 'Environment variable ORACLE_HOME is not set. Set $ORACLE_HOME and retry.'
   exit
fi

if [ ! -d "${ORACLE_HOME}" ]; then
   echo '$ORACLE_HOME directory does not exist.'
   exit
fi

if [ "${JAVA_HOME}" = "" ]; then
   JAVA_HOME=$ORACLE_HOME/jdk
   export JAVA_HOME
fi

if [ ! -d "${JAVA_HOME}" ]; then
   echo '$JAVA_HOME does not exist. Set JAVA_HOME and retry'
   exit
fi

OS_SOLARIS=SunOS
OS_HPUX=HP-UX

if [ "${PLATFORM}" = "${OS_SOLARIS}" -o "${PLATFORM}" = "${OS_HPUX}" ]; then
   JAVA_EXE_MODE="-d64"
   export JAVA_EXE_MODE
fi

CLASSPATH=${ORACLE_HOME}/../oracle_common/modules/oracle.ovd_11.1.1/ovd.jar:

exec ${JAVA_HOME}/bin/java ${JAVA_EXE_MODE} -classpath ${CLASSPATH} oracle.ods.virtualization.engine.util.ADSchemaExtendUtil "$@";
 
echo 'Completed extending AD schema.';

