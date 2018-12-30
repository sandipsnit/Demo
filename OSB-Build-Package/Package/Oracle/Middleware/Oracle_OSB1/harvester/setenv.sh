#!/bin/sh


###  Product Home directories

case `uname -s` in
CYGWIN*)
  cd ..
  OSB_HOME="`cygpath -w $PWD`";
  cd ..
  OSB_HOME="`cygpath -w $PWD`";
;;
*)
  cd ..
  OSB_HOME="`pwd`";
  cd ..
  MW_HOME="`pwd`";
;;
esac
cd $OSB_HOME/harvester

. "$OSB_HOME/common/bin/setHomeDirs.sh"

export MW_HOME
export WL_HOME
export OSB_HOME


###  JAVA \ ANT settings

. "$WL_HOME/common/bin/commEnv.sh"
 
PATH="${MW_HOME}/modules/org.apache.ant_1.7.1/bin:$PATH"
export PATH


###  The Harvester Home directory

HARVESTER_HOME="$OSB_HOME/harvester"
export HARVESTER_HOME


###  System properties required by OSB

OSB_OPTS=
OSB_OPTS="$OSB_OPTS -Dweblogic.home=$WL_HOME"
OSB_OPTS="$OSB_OPTS -Dosb.home=$OSB_HOME"

JAVA_OPTS="$JAVA_OPTS $OSB_OPTS"
export JAVA_OPTS

ANT_OPTS="$ANT_OPTS $OSB_OPTS"
export ANT_OPTS


###  classpath separator
case `uname -s` in
CYGWIN*)
  CLASSPATHSEP=\;
;;
esac
if [ "${CLASSPATHSEP}" = "" ]; then
  CLASSPATHSEP=:
fi
export CLASSPATHSEP


###  classpath representing OSB

CLASSPATH="$CLASSPATH$CLASSPATHSEP$MW_HOME/modules/features/weblogic.server.modules_10.3.6.0.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$WL_HOME/server/lib/weblogic.jar"

CLASSPATH="$CLASSPATH$CLASSPATHSEP$MW_HOME/oracle_common/modules/oracle.http_client_11.1.1.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$MW_HOME/oracle_common/modules/oracle.xdk_11.1.0/xmlparserv2.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$MW_HOME/oracle_common/modules/oracle.webservices_11.1.1/orawsdl.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$MW_HOME/oracle_common/modules/oracle.wsm.common_11.1.1/wsm-dependencies.jar"

CLASSPATH="$CLASSPATH$CLASSPATHSEP$OSB_HOME/modules/features/osb.server.modules_11.1.1.7.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$OSB_HOME/soa/modules/oracle.soa.common.adapters_11.1.1/oracle.soa.common.adapters.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$OSB_HOME/lib/external/log4j_1.2.8.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$OSB_HOME/lib/alsb.jar"


### classpath for OER Harvester

CLASSPATH="$CLASSPATH$CLASSPATHSEP$HARVESTER_HOME/client.harvester-11.1.1.7.0.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$HARVESTER_HOME/client.harvester-osb.jar"
CLASSPATH="$CLASSPATH$CLASSPATHSEP$HARVESTER_HOME/L10N"

export CLASSPATH
