#!/bin/sh
#
# pasteConfig.sh
#
# Copyright (c) 2010, 2013, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      pasteConfig.sh - Script to paste Oracle component configuration
#
#    DESCRIPTION
#      This script is used to paste the Oracle component configuration.
#      This script invokes the t2p implementation and has two mandatory parameter
#      to call the implementation.
#
#      -javaHome   - java home location.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#

# Declare variables for use
  args=$*
  argsarray=""
  d64option=""

  isjavahomeprovided="false";

# Help message for pasteConfig
 help() {
  echo "usage: pasteConfig.sh -javaHome java_home -archiveLoc archive_location -movePlanLocation moveplan_file"
  echo "       -targetDomainLoc domain_home -targetMWHomeLoc Middleware_home -domainAdminPassword admin_password_file "
  echo "       [-appDir application_directory] [-logDirLoc log_directory] [-silent true|false]"
  echo "       (For J2EE Domain)"
  echo ""
  echo " or    pasteConfig.sh -javaHome java_home -archiveLoc archive_location -movePlanLocation moveplan_file"
  echo "       -targetNMHomeLoc nodeManager_home  -targetMWHomeLoc middleware_home"
  echo "       [-logDirLoc log_directory] [-silent true|false]"
  echo "       (For NodeManager)"
  echo ""
  echo " or    pasteConfig.sh -javaHome java_home -archiveLoc archive_location -movePlanLocation moveplan_file"
  echo "       -targetInstanceHomeLoc instance_home -targetInstanceName instance_name -targetOracleHomeLoc Oracle_home"
  echo "       [-domainHostName domain_host] [-domainPortNum domain_port] [-domainAdminUserName admin_user]"
  echo "       [-domainAdminPassword admin_password_file] [-logDirLoc log_directory] [-silent true|false]"
  echo "       (For ASInstance)"
  echo ""
  echo " or    pasteConfig.sh -javaHome java_home -archiveLoc archive_location -movePlanLocation moveplan_file"
  echo "       -targetComponentName comp_name -targetInstanceHomeLoc instance_home [-targetInstanceName instance_name]"
  echo "       [-targetOracleHomeLoc Oracle_home] [-domainHostName domain_host] [-domainPortNum domain_port]"
  echo "       [-domainAdminUserName admin_user] [-domainAdminPassword admin_password_file] [-logDirLoc log_directory] [-silent true|false]"
  echo "       (For System Component)"
  echo ""
  echo "Try \"pasteConfig.sh -javaHome java_home  -help\"  for more information."
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

    elif [ ${tolowertempvar} = "-javahome" ];then
      # When ever -javaHome is passed, reset isjavahomeprovided and set ispreviousargjavahome
      ispreviousargjavahome="true";
      isjavahomeprovided="false";
    else
      argsarray="${argsarray}  ${tempvar}";
    fi
  done


# Finally check java home
  if [ "${isjavahomeprovided}" = "false" ];then
    help
  fi

  if [ ! -f "$cmddir/../jlib/cloningclient.jar" ];then
    echo "This script is not executed from bin directory of Common Oracle home as cloningclient.jar is not available under jlib directory of Common Oracle home. Execute from bin directory."
    exit 1
  fi


 "${javahome}/bin/java" ${T2P_JAVA_OPTIONS} ${d64option} -jar "$cmddir/../jlib/cloningclient.jar" applyClone -script pasteConfig ${argsarray}

