# Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      init_def.py
#
#    DESCRIPTION
#    The file contains the definition of all generic routines and global vars.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#     MODIFIED   (MM/DD/YY)
#     akmaurya   06/22/10 - 9465690
#     supal      11/26/09 - Rolling HA patching
#     supal      11/04/09 - In Windows, absent env vars are of None type
#     akmaurya   10/08/09 - Adding config/key
#     supal      08/19/09 - Enable OPatch logging
#     supal      07/06/09 - Creation

import sys
import os
import java.util.Date as Date
import java.lang.StringBuffer as StringBuffer

from oracle.opatch import OLogger
from oracle.opatch.opatchfmw import FmwConstants

def initLogger(logFile):
    OLogger.initSessionLogFileExternal(logFile)
    OLogger.printlnOnLog("Initialized OPatch log file " + logFile);
    #OLogger.disableConsoleOutput()

##############################
## logMsgTime(): This is the logging routine that prints message 
##           into the OPatch log file with a timestamp
##############################
def logMsgTime(msg):
    ts = StringBuffer('[FMWD:INFO] ').append(msg)
    print ts.toString()
    OLogger.logTime(ts) 

##############################
## logMsg(): This is the logging routine. It prints message 
##           into the OPatch log file
##############################
def logMsg(msg):
    lbuff = StringBuffer('[FMWD:INFO] ').append(msg)
    print lbuff.toString()
    OLogger.printlnOnLog(lbuff.toString()) 

##############################
## debugMsg(): This is the debugging routine. It prints message 
##           into the OPatch debug file
##############################
def debugMsg(msg):
    dbuff = StringBuffer('[FMWD:DEBUG] ').append(msg)
    print dbuff.toString()
    OLogger.debug(dbuff) 

##############################
## Populate all the global variables from environment
##############################

#Get the weblogic Home
wls_home = os.getenv(FmwConstants.FMW_WL_HOME)

#Get the Middleware Home
mw_home = os.getenv(FmwConstants.FMW_MW_HOME)

#Get the Common Home GUID
commonHomeGuid = os.getenv(FmwConstants.FMW_COMMONHOME_GUID)

#Managed Server Name
ms_name = os.getenv(FmwConstants.FMW_MS_NAME)

#Managed Server Host
ms_host = os.getenv(FmwConstants.FMW_MS_HOST)

#Managed Server HTTP port
ms_http_port = os.getenv(FmwConstants.FMW_MS_HTTP_PORT)

#Managed Server HTTPS port
ms_https_port = os.getenv(FmwConstants.FMW_MS_HTTPS_PORT)

#Admin Server Listen HTTP port
admin_http_port = os.getenv(FmwConstants.FMW_ADMIN_HTTP_PORT)

#Admin Server HTTPS port
admin_https_port = os.getenv(FmwConstants.FMW_ADMIN_HTTPS_PORT)

##Get the user/password 
debugMsg("Fetching Admin user/password")

admin_user = raw_input()
admin_password = raw_input()
nmUsername = raw_input()
nmPassword = raw_input()

#debugMsg('Admin Server User: ' + admin_user)
#debugMsg('Admin Server Password: ' + admin_password)

debugMsg("Done Fetching Admin user/password")

#Weblogic admin server username [Suprio: remove by Drop 2]
#admin_user = os.getenv(FmwConstants.FMW_ADMIN_USER)

#Weblogic admin server password [Suprio: remove by Drop 2]
#admin_password = os.getenv(FmwConstants.FMW_ADMIN_PASSWORD)

#Admin Server WLST Listen URL
admin_url = os.getenv(FmwConstants.FMW_ADMIN_URL)

# config file
myUserConfigFile = os.getenv( FmwConstants.FMW_USER_CONFIG_FILE);
# key file
myUserKeyFile = os.getenv( FmwConstants.FMW_USER_KEY_FILE);

# config file
myNMConfigFile = os.getenv( FmwConstants.FMW_NODE_MANAGER_CONFIG_FILE)
# key file
myNMKeyFile = os.getenv( FmwConstants.FMW_NODE_MANAGER_KEY_FILE)

#Domain Name
domain_name = os.getenv(FmwConstants.FMW_DOMAIN_NAME)

#Domain Home
domain_home = os.getenv(FmwConstants.FMW_DOMAIN_HOME)

#Applications Directory
apps_dir = os.getenv(FmwConstants.FMW_DOMAIN_APPSDIR)

#List of Applications
targetList = os.getenv(FmwConstants.FMW_TARGETS)

#List of Deploy Requests
deployList = os.getenv(FmwConstants.FMW_DEPLOYREQUEST)

#List of Restart Requests
restartList = os.getenv(FmwConstants.FMW_RESTARTREQUEST)

#What command to execute
commandCode = os.getenv(FmwConstants.FMW_COMMANDCODE)

#Whether a rolling bounce needs to be performed
isRolling = os.getenv(FmwConstants.FMW_ROLLINGINSTALLATION)

logMsgTime('Fetched following parameters from OPatch ')

logMsg('   FMW Driver Commandcode  : ' + str(commandCode))
logMsg('   Admin Server User       : ' + str(admin_user))
logMsg('   Admin Server Password   : *************')
logMsg('   Admin Server URL        : ' + str(admin_url))
logMsg('   Domain Name             : ' + str(domain_name))
logMsg('   Domain Home             : ' + str(domain_home))
logMsg('   Domain Apps directory   : ' + str(apps_dir))
logMsg('   Application/Target List : ' + str(targetList))
logMsg('   Oracle Common Home GUID : ' + str(commonHomeGuid))
logMsg('   Rolling Server bounce   : ' + str(isRolling))
if (deployList != None):
   logMsg('   Deploy Request List     : ' + deployList)
if (restartList != None):
   logMsg('   App/Target Restart List : ' + restartList)
if (myUserConfigFile != None):
   logMsg('   User Config file location : ' + myUserConfigFile)
if (myUserKeyFile != None):
   logMsg('   User Config Key file location : ' + myUserKeyFile)
