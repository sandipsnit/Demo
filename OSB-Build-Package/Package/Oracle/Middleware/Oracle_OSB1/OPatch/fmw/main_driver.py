# Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      .py
#
#    DESCRIPTION
#    The file contains the definition of all generic routines and global vars.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#     MODIFIED   (MM/DD/YY)
#     akmaurya   06/23/10 - 9843128
#     supal      02/24/10 - Bug9291497: Fix variable spelling error
#     akmaurya   02/20/10 - SOA Composite support
#     supal      11/25/09 - Rolling HA patching
#     supal      11/16/09 - Optimize prereq checks and support classpath
#                           patches
#     supal      11/05/09 - Shared Oracle homes - separate domain roots
#     supal      10/30/09 - Virtual IPs and multiple Network Interfaces
#     supal      10/21/09 - Multi-App patch deployments
#     akmaurya   10/08/09 - Adding config/key
#     supal      09/07/09 - Common routines consolidation
#     supal      08/20/09 - Start/Stop and other improvements
#     supal      07/06/09 - Creation

import sys
import os
import socket as Pysocket

from java.net import NetworkInterface
from java.net import Inet6Address

from oracle.opatch.opatchfmw import FmwConstants

try:
   INITCOMMON
except NameError:
   INITCOMMON=None
  
if INITCOMMON == None:
  INITCOMMON = "initialized"
  print "Loading Main Driver file\n";

def isLocalHost( theAddr):
    if ((myHostname is not None) and (theAddr == myHostname)):
       return true
    if (theAddr == myHostFQDN):
       return true
    if (theAddr == myHostIPAddr):
       return true
    # If None of the simple addresses match then check all the interfaces
    theAddrIP = Pysocket.gethostbyname(theAddr)
    NetworkIfacesList = NetworkInterface.getNetworkInterfaces()
    for IfName in NetworkIfacesList:
        InetAddresses = IfName.getInetAddresses()
        for inetAddr in InetAddresses:
            if (inetAddr.getHostAddress() == theAddrIP):
               return true
    return false

env = os.environ
myHostname = env.get('HOSTNAME')
myHostIPAddr = Pysocket.gethostbyname(Pysocket.gethostname())
myHostFQDN = Pysocket.getfqdn()
print 'Python Version',sys.version
print 'Starting Fusion Middleware Patching Driver on ' + str(myHostname) + '/' + str(myHostFQDN) + '/' + str(myHostIPAddr) + ' [' + str(os.getcwd()) +']'

NetworkIfacesList = NetworkInterface.getNetworkInterfaces()
for IfName in NetworkIfacesList:
    print 'Interface name: ' + IfName.getDisplayName()
    InetAddresses = IfName.getInetAddresses()
    for inetAddr in InetAddresses:
        bIPV6 = bool(isinstance(inetAddr,Inet6Address))      # 'bool' suring it up for Python 2.3
        bLoopback = bool(inetAddr.isLoopbackAddress())
        bMultiCast = bool(inetAddr.isMulticastAddress())
        print '  IP Address is ' + inetAddr.getHostAddress() + ' [Multicast: ' + str(bMultiCast) + ' Loopback: ' + str(bLoopback) + ' IPV6: '+ str(bIPV6) + ']'

# First extract the OPatch variables
opatch_logfile = os.getenv(FmwConstants.OPATCH_LOG_NAME)

# Scripts where FMW patching Jython scripts live
opatch_scriptpath = os.getenv(FmwConstants.OPATCH_FMW_SCRIPTPATH)

# Load the scripts (first the basic one)
execfile(opatch_scriptpath + '/init_def.py')
initLogger(opatch_logfile)

execfile(opatch_scriptpath + '/start_stop.py')

execfile(opatch_scriptpath + '/application.py')

execfile(opatch_scriptpath + '/node_manager.py')

execfile(opatch_scriptpath + '/prereq.py')

# Need to find a way to append to OPatch logfile
# Perhaps this is a WLST ER request 
#redirect('opatchfmw_logfile.log', 'true')

isStartServerCmd = (commandCode == FmwConstants.FMW_SERVERSTART)

# Only in the case of Server Start can we live with Admin Server down
# cause user could be requesting start of the Admin Server itself as
# part of this start request. So how do we know this for a fact?
# We probably have to do offline processing ...

targetNames = targetList.split(FmwConstants.FMW_PARAMSEPARATOR)
if (deployList != None):
   deployCommands   = deployList.split(FmwConstants.FMW_PARAMSEPARATOR)
if (restartList != None):
   restartCommands  = restartList.split(FmwConstants.FMW_PARAMSEPARATOR)

if (targetNames != None):
   print targetNames
#if (deployList != None):
#   print deployCommands
#if (restartList != None):
#   print restartCommands

adminConnectRetcode = 0
try:
  logMsg('Connecting to Admin Server for domain ' + domain_name)
  if( (myUserConfigFile is not None) and (len( myUserConfigFile) > 0)):  
    connect(userConfigFile=myUserConfigFile,userKeyFile=myUserKeyFile,url=admin_url)
  else :
    connect(admin_user, admin_password, admin_url)
except:
  (c, i, tb) =  sys.exc_info()
  logMsg('SEVERE: Exception: during connection to Admin Server')
  logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
  adminConnectRetcode = FmwConstants.FMW_ADMINCONNECT_FAILED

if (adminConnectRetcode != 0):
   if (isStartServerCmd):
      readDomain(domain_home)
      sys.exit(FmwConstants.FMW_ADMINCONNECT_FAILED)
      pass  # offline ?
   else:
      sys.exit(FmwConstants.FMW_ADMINCONNECT_FAILED)
else:
   logMsg('Successfully connected to a WLS Server')
  
# Check if Domain name matches
domainName = get('Name')
if domainName != domain_name:
   logMsg('OPatch supplied Domain name \'' + domain_name + '\' is not the same as Config \'' + domainName + '\'')
   sys.exit(FmwConstants.FMW_DOMAINNAME_MISMATCH)
domainName = domain_name # Make it a string object

# Log if Domain Home matches (check with Dave Felts for dist. setups)
domainHome = get('RootDirectory')
if domainHome != domain_home:
   logMsg('OPatch supplied Domain directory \'' + domain_home + '\' is not the same as Config \'' + domainHome + '\'')
   sys.exit(FmwConstants.FMW_DOMAINHOME_MISMATCH)
domainHome = domain_home # Make it a string object

if (not isStartServerCmd and isAdminServer == 'false'):
   logMsg('SEVERE: Not connected to WebLogic Admin Server')
   logMsg('\'' + serverName + '\' is not an Admin Server for domain \'' + domainName + '\'')
   sys.exit(FmwConstants.FMW_NOT_ADMINSERVER)

adminServerName = get('AdminServerName')
#print adminServerName

if (commandCode == FmwConstants.FMW_PREREQLIFECYCLE):
   debugMsg('prereqLifeCycle Command received from OPatch')
   (serverToDomainRootMap, serverToHomeGUIDMap) = getServerDomainHomeAndCommonHomeGUIDMaps(targetNames)
   allServersCheckedList = []
   allMachinesCheckedList = []
   cnonSVRConfigure = 0
   cnonNMMachineConfigure = 0
   cnonNMConfigure = 0
   cnonConnects = 0
   for appName in targetNames:
      serversChecked = []
      nonSVRConfigure = 0
      nonNMMachineConfigure = 0
      nonNMConfigure = 0
      nonConnects = 0
      if (isApplicationConfigured(appName) == false):
         if (appName == FmwConstants.FMW_ANONYMOUS_APP):
            (serversChecked, allMachinesCheckedList, nonSVRConfigure, nonNMMachineConfigure, nonNMConfigure, nonConnects) = prereq_Lifecycle_ClassPath(allServersCheckedList, allMachinesCheckedList, serverToDomainRootMap, serverToHomeGUIDMap)
            pass
         else:
            # This patch is a bundle built using component striping 
            # The application pertaining to this component may not have
            # been configured in this domain but some other domain
            # Example domain created from WebCenter applications:
            #   Domain WC_DomainA  (contains Wiki and Discussions)
            #   Domain WC_DomainB  (conatins WebCenter)
            debugMsg(appName + ' application/library is NOT configured')
      else:
         theApp = Application(appName, serverToDomainRootMap, serverToHomeGUIDMap)
         (serversChecked, allMachinesCheckedList, nonSVRConfigure, nonNMMachineConfigure, nonNMConfigure, nonConnects) = prereq_Lifecycle_App(theApp, allServersCheckedList, allMachinesCheckedList)
      allServersCheckedList.extend(serversChecked)
      cnonSVRConfigure = cnonSVRConfigure + nonSVRConfigure
      cnonNMMachineConfigure = cnonNMMachineConfigure + nonNMMachineConfigure
      cnonNMConfigure = cnonNMConfigure + nonNMConfigure
      cnonConnects = cnonConnects + nonConnects

   if (cnonSVRConfigure > 0):
      logMsg('Some WebLogic servers are not configured with a Listen Address - Please check OPatch log for details')
      sys.exit(FmwConstants.FMW_CONFIGERROR_WLSLISTENADDR)
   if (cnonNMMachineConfigure > 0):
      logMsg('Some WebLogic Servers are not configured with Machines - Please check OPatch log for details')
      sys.exit(FmwConstants.FMW_CONFIGERROR_NOMACHINES)
   if (cnonNMConfigure > 0):
      logMsg('Some Node Managers are not configured with a Listen Address/Port - Please check OPatch log for details')
      sys.exit(FmwConstants.FMW_CONFIGERROR_NMHOSTPORT)
   if (cnonConnects > 0):
      logMsg('Some Node Managers couldn\'t be connected to - Please check OPatch log for details')
      sys.exit(FmwConstants.FMW_NMCONNECT_FAILED)
elif (commandCode == FmwConstants.FMW_PREREQDEPLOY):
   debugMsg('prereqDeploy Command received from OPatch')
   (nC,nNC,nNS,nNRS,nSC) = prereq_Deploy(targetNames)
   if (nNC == 0):
      logMsg('All applications/libraries are configured in this domain')
      if (len(targetNames) == nSC):
         logMsg('All applications/libraries are System Classpath artifacts')
         sys.exit(FmwConstants.FMW_ALLAPPS_ONCLASSPATH)
      if (nC == nNS):
         logMsg('All applications/libraries are configured \'NoStage\'')
         sys.exit(FmwConstants.FMW_ALL_NOSTAGE_APPS)
      else:
         if (nNRS > 0):
            logMsg('Some \'staged\' application containers are NOT running in the domain')
            sys.exit(FmwConstants.FMW_STAGEDAPPS_UNAVAILABLE)
         else:
            logMsg('All \'staged\' application containers are running in the domain')
            sys.exit(FmwConstants.FMW_ALLAPPS_CONFIG)
   elif (len(targetNames) > nNC):
      logMsg('Some applications/libraries are NOT configured in this domain')
      if (nC == nNS):
         logMsg('All configured applications/libraries are configured \'NoStage\'')
         sys.exit(FmwConstants.FMW_ALL_NOSTAGE_APPS)
      else:
         logMsg('Some applications/libraries are configured in this domain')
         if (nNRS > 0):
            logMsg('Some \'staged\' application containers are NOT running in the domain')
            sys.exit(FmwConstants.FMW_STAGEDAPPS_UNAVAILABLE)
         else:
            sys.exit(FmwConstants.FMW_SOMEAPPS_CONFIG)
   elif (len(targetNames) == nNC):
      logMsg('No applications/libraries are configured in this domain')
      sys.exit(FmwConstants.FMW_APPS_NOTCONFIGURED)
   else:
      debugMsg('Logic error - should be unreachable')
elif (commandCode == FmwConstants.FMW_REALDEPLOY):
   debugMsg('Deploy Command received from OPatch')
   nNonDeploy = 0
   for appName in targetNames:
      if (isApplicationConfigured(appName) == false):
         logMsg(appName + ' application/library is NOT configured')
      else:
         theApp = Application(appName, None, None)
         logMsg('Redeploying application/library: \'' + appName + '\'')
         if (theApp.redeploy() == FmwConstants.FMW_REDEPLOY_FAILED):
            nNonDeploy = nNonDeploy + 1
   if (len(targetNames) == nNonDeploy):
      sys.exit(FmwConstants.FMW_APPS_REDEPLOY_FAILED)
   if (nNonDeploy > 0):
      sys.exit(FmwConstants.FMW_SOMEAPPS_DEPLOYED)
elif (commandCode == FmwConstants.FMW_APPLICATIONBOUNCE):
   debugMsg('Application Bounce Command received from OPatch')
   for appName in targetNames:
     theApp = Application(appName, None, None)
     bounceFMWApplication(theApp)
elif (commandCode == FmwConstants.FMW_CONTAINERBOUNCE):
   errCode = 0
   allBouncedList = []
   debugMsg('Container Bounce Command received from OPatch')
   (serverToDomainRootMap, serverToHomeGUIDMap) = getServerDomainHomeAndCommonHomeGUIDMaps(targetNames)
   for appName in targetNames:
     retCode = 0
     stopList = []
     if (appName == FmwConstants.FMW_ANONYMOUS_APP):
        if (isRolling == 'true'):
           (retCode, stopList) = bounceLocalSharedMWHServersRolling(serverToHomeGUIDMap, allBouncedList)
        else:
           (retCode, stopList) = bounceLocalSharedMWHServersSerial(serverToHomeGUIDMap, allBouncedList)
     elif (isApplicationConfigured(appName) == true):
        theApp = Application(appName, serverToDomainRootMap, serverToHomeGUIDMap)
        if (isRolling == 'true'):
           (retCode, stopList) = bounceFMWContainerRolling(theApp, allBouncedList)
        else:
           (retCode, stopList) = bounceFMWContainerSerial(theApp, allBouncedList)
     if (retCode != 0):
        errCode = retCode
     # Add bounced servers to allBouncedList
     allBouncedList.extend(stopList)
   sys.exit(errCode)
elif (commandCode == FmwConstants.FMW_APPLICATIONSTOP):
   debugMsg('Application Stop Command received from OPatch')
   stopMultipleFMWApplications(targetNames)
elif (commandCode == FmwConstants.FMW_CONTAINERSTOP):
   debugMsg('Container Stop Command received from OPatch')
   stopMultipleFMWContainers(targetNames)
elif (commandCode == FmwConstants.FMW_SERVERSTOP):
   debugMsg('Server Stop Command received from OPatch')
   stopMultipleWLSServers(targetNames)
elif (commandCode == FmwConstants.FMW_CLUSTERSTOP):
   debugMsg('Cluster Stop Command received from OPatch')
   stopMultipleWLSClusters(targetNames)
elif (commandCode == FmwConstants.FMW_APPLICATIONSTART):
   debugMsg('Application Start Command received from OPatch')
   startMultipleFMWApplications(targetNames)
elif (commandCode == FmwConstants.FMW_CONTAINERSTART):
   debugMsg('Container Start Command received from OPatch')
   startMultipleFMWContainers(targetNames)
elif (commandCode == FmwConstants.FMW_SERVERSTART):
   debugMsg('Server Start Command received from OPatch')
   startMultipleWLSServers(targetNames)
elif (commandCode == FmwConstants.FMW_CLUSTERSTART):
   debugMsg('Cluster Start Command received from OPatch')
   startMultipleWLSClusters(targetNames)
else:
   logMsg('Unknown Command received from OPatch')
