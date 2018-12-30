#!/bin/sh
#
# $Header: ade sccs line
#
# dfwhealthtestctl.sh
#
# Copyright (c) 2007, 2011, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      dfwhealthtestctl.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      This is the main script for performing operations using the
#      Diagnostics Engine. This script can be invoked with the "run",
#      "status","register","query", "report" and "help" verbs.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)  Comments
#       lwong   02/08/12  - Created

unset PARAMS
for i in "$@"
do
 # echo ${i}
 PARAMS="${PARAMS} \"${i}\""
done

#echo ${PARAMS}

# Initial settings
_binDir=/bin
_usrBinDir=/usr/bin


#
# Set the umask for all operations
umask 077

#
# Define commands that are explicit such that behavior of the commands is
# deterministic
#
AWK=${_binDir}/awk
CHMOD=${_binDir}/chmod
ECHO=${_binDir}/echo
ECHOE="${_binDir}/echo -e"
DIRNAME=${_usrBinDir}/dirname
TR=${_usrBinDir}/tr
MKDIRP="${_binDir}/mkdir -p"
MKDIR=${_binDir}/mkdir


# Verify JAVA_HOME is set
if [ x${JAVA_HOME} = "x" ]; then
 # JAVA_HOME is not set, error
 echo "ERROR: JAVA_HOME is not set."
 exit 1;
fi

# Verify MW_HOME is set
if [ x${MW_HOME} = "x" ]; then
  if [ x${BEA_HOME} != "x" ]; then
    MW_HOME="$BEA_HOME"
  else
    # MW_HOME is not set, error
    echo "ERROR: MW_HOME or BEA_HOME is not set."
    exit 1;
  fi
fi

if [ x${dtf_fs_diagbase} = "x" ]; then
    # dtf_fs_diagbase is not set, error
    echo "ERROR: dtf_fs_diagbase is not set."
    exit 1;
fi


# Extract the binary directory specification where this script resides.
# The enclosed code will come up with an absolute path.
#_diagBinDir=`$DIRNAME $0 | $TR -s '/'`
#_diagBinDir=`$ECHO $_diagBinDir | $AWK -f ${_diagBinDir}/strip_path.awk PWD=$PWD`
_diagBinDir=${MW_HOME}/oracle_common/common/bin
#echo "_diagBinDir=$_diagBinDir"

# Locate diag jar element
_moduleDir=${MW_HOME}/oracle_common/modules/oracle.dfwhealth_11.1.1
DFWHEALTH_JAR=$_moduleDir/dfwhealth.jar

# assume the lucene jar is in the bin directory for now
LUCENE_JAR=$_moduleDir/lucene-core-3.5.0.jar


if [ ! -f $DFWHEALTH_JAR ]
    then
  	$ECHO "ERROR: Unable to locate $DFWHEALTH_JAR"
else
        # It seems like the script is running in JRF label.
	# We will get jars from MW_HOME
	DMS_JAR=${MW_HOME}/oracle_common/inventory/Scripts/ext/jlib/dms.jar
	OJDL_JAR=${MW_HOME}/oracle_common/inventory/Scripts/ext/jlib/ojdl.jar
	ORAI18N_JAR=${MW_HOME}/oracle_common/oui/jlib/orai18n-collation.jar
	XML_JAR=${MW_HOME}/oracle_common/oui/jlib/xml.jar
	XML_PARSER_JAR=${MW_HOME}/oracle_common/ccr/lib/xmlparserv2.jar	
fi


if [ ! -f $DMS_JAR ]
then
  $ECHO "ERROR: Unable to locate $DMS_JAR"
  exit 1;
fi

if [ ! -f $ORAI18N_JAR ]
then
  $ECHO "ERROR: Unable to locate $ORAI18N_JAR"
  exit 1;
fi

if [ ! -f $XML_JAR ]
then
  $ECHO "ERROR: Unable to locate $XML_JAR"
  exit 1;
fi

if [ ! -f $XML_PARSER_JAR ]
then
  $ECHO "ERROR: Unable to locate $XML_PARSER_JAR"
  exit 1;
fi

if [ ! -f $OJDL_JAR ]
then
  $ECHO "ERROR: Unable to locate $OJDL_JAR"
  exit 1;
fi

#
# Construct CLASSPATH to invoke java
#
CLASSPATH="${DFWHEALTH_JAR}:${XML_PARSER_JAR}:${XML_JAR}:${DMS_JAR}:${OJDL_JAR}:${ORAI18N_JAR}:${LUCENE_JAR}"
#echo "CLASSPATH=$CLASSPATH"

#
# Set Java options
#
#config properties file - default is under bin
LOGCONFIGFILE="${_moduleDir}/config/dfwhealthlogging.xml"

if [ ! "x${DIAGLOGCONFIGFILE}" = "x" ]; then
   # The DIAGLOGCONFIGFILE environment variable is set. 
   LOGCONFIGFILE="${DIAGLOGCONFIGFILE}"
fi
# Verify that such a file does in fact exist.
if [ ! -f "$LOGCONFIGFILE" ]
then
    $ECHO "ERROR: Unable to locate logging configuration file $LOGCONFIGFILE"
    exit 1;
fi

#
# Check for JAVA_OPTIONS property
#
DIAG_JAVA_OPTIONS="-Djava.util.logging.config.class=oracle.core.ojdl.logging.LoggingConfiguration -Doracle.core.ojdl.logging.config.file=\"${LOGCONFIGFILE}\" -Doracle.dfw.healthtest.cli.skipoverridejpsconfigfile=true -Ddtf_fs_diagbase=${dtf_fs_diagbase} -Ddtf_report_hideparam=${dtf_report_hideparam}"

DIAG_JAVA_OPTIONS="${DIAG_JAVA_OPTIONS} ${JAVA_OPTIONS} -Doracle.dfw.healthtest.cli.basedir=${_diagBinDir}"

#echo "JAVA_OPTIONS=$JAVA_OPTIONS" 
#echo "DIAG_JAVA_OPTIONS=$DIAG_JAVA_OPTIONS" 




