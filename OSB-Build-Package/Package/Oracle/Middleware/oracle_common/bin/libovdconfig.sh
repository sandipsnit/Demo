#!/bin/sh

if [ "${ORACLE_HOME}" = "" ]; then
   echo 'Environment variable ORACLE_HOME is not set. Set $ORACLE_HOME and retry.'
   exit
fi

if [ ! -d "${ORACLE_HOME}" ]; then
   echo '$ORACLE_HOME directory does not exist.'
   exit
fi

if [ "${WL_HOME}" = "" ]; then
   if [ "${WAS_HOME}" = "" ]; then
      echo 'Environment variable WL_HOME/WAS_HOME is not set. Set $WL_HOME for Weblogic or $WAS_HOME for Websphere and retry.'
      exit
   fi
fi

if [ "${WL_HOME}" != "" ]; then
   if [ "${WAS_HOME}" != "" ]; then
      echo 'Both $WL_HOME and $WAS_HOME are set. Only one environment variable should be set.'
      exit
   fi
fi

if [ "${WL_HOME}" != "" ]; then
   if [ ! -d "${WL_HOME}" ]; then
      echo '${WL_HOME} does not exist.'
      exit
   else
      CLASSPATH=${WL_HOME}/server/lib/wljmxclient.jar;
   fi
fi

if [ "${WAS_HOME}" != "" ]; then
   if [ ! -d "${WAS_HOME}" ]; then
      echo '${WAS_HOME} does not exist.'
      exit
   else
      JAVA_HOME=${WAS_HOME}/java
      CLASSPATH=${WAS_HOME}/runtimes/com.ibm.ws.admin.client_7.0.0.jar;
   fi
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


CLASSPATH=${ORACLE_HOME}/../oracle_common/modules/oracle.jps_11.1.1/jps-manifest.jar:${ORACLE_HOME}/../oracle_common/modules/oracle.jps_11.1.1/jps-mbeans.jar:${ORACLE_HOME}/../oracle_common/modules/oracle.ovd_11.1.1/ovd.jar:${ORACLE_HOME}/../oracle_common/modules/oracle.ovd_11.1.1/plugins.jar:${ORACLE_HOME}/../oracle_common/modules/args4j-2.0.9.jar:${ORACLE_HOME}/../oracle_common/modules/oracle.xdk_11.1.0/xmlparserv2.jar:${ORACLE_HOME}/../oracle_common/modules/oracle.odl_11.1.1/ojdl.jar:${ORACLE_HOME}/../oracle_common/modules/oracle.dms_11.1.1/dms.jar:${CLASSPATH}:

exec ${JAVA_HOME}/bin/java ${JAVA_EXE_MODE} -classpath ${CLASSPATH} oracle.ods.virtualization.config.BootstrapConfig "$@"

