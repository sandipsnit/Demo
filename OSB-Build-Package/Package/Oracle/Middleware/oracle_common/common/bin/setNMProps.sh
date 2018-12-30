#!/bin/sh
#
# setNMProps.sh
#
# Copyright (c) 2008, 2013, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      setNMProps.sh - <set node manager properties>
#
#    DESCRIPTION
#      Run this script to append required properties to the
#	nodemanager.properties file. These properties can also be appended
#	manually, or provided as command-line arguments. 
#
#    NOTES
#      StartScriptEnabled=true property is required for managed servers
#	to receive proper classpath and command arguments.
#	The file containing the properties is nm.required.properties
#
#
mypwd="`pwd`"

# Note: this will not work if the script is sourced (. ./wlst.sh)
SCRIPTNAME=$0
case ${SCRIPTNAME} in
 /*)  SCRIPTPATH=`dirname ${SCRIPTNAME}` ;;
  *)  SCRIPTPATH=`dirname ${mypwd}/${SCRIPTNAME}` ;;
esac

# Set the ORACLE_HOME relative to this script...
ORACLE_HOME=`cd ${SCRIPTPATH}/../.. ; pwd`
export ORACLE_HOME

MW_HOME=`cd ${ORACLE_HOME}/.. ; pwd`
export MW_HOME

#Invoking the setHomeDirs.sh script to set the WL_HOME variable
. "${SCRIPTPATH}/setHomeDirs.sh"

#set up NodeManager home - edit if not the default location
NM_HOME="${WL_HOME}/common/nodemanager"
NM_FILE="${NM_HOME}/nodemanager.properties"

#Check to see if the properties file exists
if [ ! -f $NM_FILE ]; then
	echo "File nodemanager.properties not found. Copying required properties file."
	cp  ${SCRIPTPATH}/nm.required.properties $NM_FILE
	chmod 666 ${SCRIPTPATH}/nm.required.properties $NM_FILE
else
	#Check to see if required property is present	
	if grep -c "StartScriptEnabled=true" $NM_FILE >> /dev/null; then 
		echo "Required properties already set. File nodemanager.properties not modified."
	else
		echo "Appending required nodemanager.properties"
		cat ${SCRIPTPATH}/nm.required.properties >> $NM_FILE
	fi
fi

