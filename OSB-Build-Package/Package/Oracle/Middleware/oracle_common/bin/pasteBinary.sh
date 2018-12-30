#!/bin/sh
#
# pasteBinary.sh
#
# Copyright (c) 2010, 2013, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      pasteBinary.sh - Script to paste Oracle Middleware Home binaries
#
#    DESCRIPTION
#      This script is used to paste the Middleware Home binaries.
#      This script invokes the t2p implementation and has one mandatory parameter
#      to call the implementation.
#
#      -javaHome   -java home location.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#

# Declare variables for use
  args=$*
  isccpresent="false"
  isccpresentinjlib="false"
  d64option=""
  argsarray=""

  isjavahomeprovided="false";

# Help message for pasteBinary
 help() {
  echo "usage: pasteBinary.sh -javaHome java_home -archiveLoc archive_location -targetMWHomeLoc Middleware_home"
  echo "       [-invPtrLoc inventory_pointer_file] [-executeSysPrereqs true|false] [-ignoreDiskWarning true|false]"
  echo "       [-logDirLoc log_directory] [-silent true|false] [-ouiPram oui_session_variables]"
  echo ""
  echo "Try \"pasteBinary.sh -javaHome java_home  -help\"  for more information."
  exit 1
 }

# To validate javaHome value
 validate_java_home() {
  java_home="$1"
  if [ ! -d "${java_home}" ];then
    echo "Java home location is invalid as \"${java_home}\" did not exist."
    exit 1 ;
  fi
  if [ ! -f "$java_home/bin/java" ];then
    echo "Java home location is invalid as  \"${java_home}/bin/java\" did not exist."
    exit 1
  fi
 }


# Calculate the cmddir in order to discover cloningclient.jar
  cmddir=`/usr/bin/dirname $0`

  if [ "$cmddir" = "." ]; then
      cmddir=`pwd`;
  fi

# Replace relative path with fully qualified path.
  if [ ! "`echo $cmddir|/bin/grep '^/'`" ]; then
      cmddir=`pwd`/$cmddir;
  fi
  
# If number of argumnet is less than 1
 if [ "$#" -eq "0" ];then
  help
 fi
 
 
# Iterate through the command line parameters to check the mandatory params required to execute the cloningclient
  for tempvar
  do
  	#convert the argument to a lower case to make the comparison case insensitive 
  	tolowertempvar=`echo ${tempvar} | tr [A-Z] [a-z]`
  	
    # is argument -d64 
    if [ "${tempvar}" = "-d64" ];then
      d64option="-d64";
    
    # if previous argument was -javaHome
    elif [ "${ispreviousargjavahome}" = "true" ];then
      javahome="${tempvar}";
      # validate java home
      validate_java_home "${javahome}"
      # reset ispreviousargjavahome to false and set isjavahomeprovided to true  
      ispreviousargjavahome="false";
      isjavahomeprovided="true";
      argsarray="${argsarray}  ${tempvar}";

    elif [ ${tolowertempvar} = "-javahome" ];then
      # When ever -javaHome is passed, reset isjavahomeprovided and set ispreviousargjavahome
      ispreviousargjavahome="true";
      isjavahomeprovided="false";
      argsarray="${argsarray}  ${tempvar}";
    else
      argsarray="${argsarray}  ${tempvar}";
    fi
  done


# Finally check java home
  if [ "${isjavahomeprovided}" = "false" ];then
    help
  fi

# Calculate cloningclient location
  cclocation="$cmddir/cloningclient.jar";
  ccjliblocation="$cmddir/../jlib/cloningclient.jar";

# Check if the cloningclient is present in the current dir
  if [ -f "${cclocation}" ];then
   isccpresent="true"
  fi

# Check if the cloningclient is present in the lib dir
  if [ -f "${ccjliblocation}" ];then
   isccpresentinjlib="true"
  fi

  
# Exit if manadatory params for this script are not specified
  if [ "${isccpresentinjlib}" = "false" ];then
    if [ "${isccpresent}" = "false" ];then
      echo "File 'cloningclient.jar' is not present in the script directory. Place the 'cloningclient.jar' into the 'pasteBinary.sh' script directory. See the Fusion Middleware Documentation for details."
      exit 1
    fi
  fi

#bug-9905319
umask 027

# If Platform is SunOS or any one of HP platforms, then pass -d64 option
 PLATFORMID=`uname -a | awk '{{print $1}}'`

 if [ "$PLATFORMID" = "SunOS" ];then
  d64option="-d64";
 elif [ "$PLATFORMID" = "HP-UX" ];then
  d64option="-d64";
 fi
 
 if [ -f "${ccjliblocation}" ];then
  "${javahome}/bin/java" -mx512m ${T2P_JAVA_OPTIONS} ${d64option} -jar "${ccjliblocation}" applyClone -script pasteBinary ${argsarray}
 else
  "${javahome}/bin/java" -mx512m ${T2P_JAVA_OPTIONS} ${d64option} -jar "${cclocation}" applyClone -script pasteBinary ${argsarray}        
 fi
