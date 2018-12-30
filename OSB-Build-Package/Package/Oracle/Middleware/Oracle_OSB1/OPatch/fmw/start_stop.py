# Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      start_stop.py
#
#
#    DESCRIPTION
#    The file contains the definition of all generic routines and global vars.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#     MODIFIED   (MM/DD/YY)
#     supal      02/24/10 - Bug9407522: a) Restore MBean tree if ServerLifeCycle 
#                           MBean access returns exception b) Use WA given by
#                           WLST team for accessing ServerLifeCycleRuntimes for
#                           issue caused by Bug9473168               
#     supal      11/25/09 - Rolling HA patching
#     supal      11/16/09 - Optimize prereq checks and support classpath
#                           patches
#     supal      10/21/09 - Admin Server deployments
#     supal      09/12/09 - Ensure servers are stopped
#     supal      08/19/09 - Rolling bounce of containers and start/stop
#     supal      07/12/09 - Creation

from oracle.opatch.opatchfmw import FmwConstants

import sys
import os
import time as PyTime
from datetime import datetime

#Return first item in sequence where test(item) == True 
def finditem(test, seq):
    for item in seq:
       if test(item):
         return true
    return false

def server_state(server_name):
    sstate = 'UNKNOWN'
    try :
        myTree = currentTree()
        domainRuntime()
        #cd( '/ServerLifeCycleRuntimes/' + server_name)
        #sstate = get('State')
        sstate = cmo.lookupServerLifeCycleRuntime(server_name).getState()
        myTree()
    except:
        debugMsg('Exception while trying to get ServerRuntimeMBean')
        myTree()
    return sstate

############################################################################
#  Start a single WLS Server
#   @param  server_name
############################################################################
def startSingleWLSServer(server_name):
    try:
       # Make sure we are connected to 
       # a) Admin Server before we issue the start command
       # b) If Admin Server has been brought down, make sure we can connect to Node Manager
       if (server_state(server_name) == 'ADMIN'):
          debugMsg('Server resume initiated at ' + str(datetime.now())) 
          resume(server_name,block='true')
          debugMsg('Server resume completed at ' + str(datetime.now())) 
       elif (server_state(server_name) != 'RUNNING'):
          debugMsg('Server start initiated at ' + str(datetime.now())) 
          start(server_name,'Server',block='true')
          debugMsg('Server start completed at ' + str(datetime.now())) 
       else:
          return FmwConstants.FMW_SERVER_ALREADYRUNNING
       return 0
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during Server start')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       return FmwConstants.FMW_STARTSERVER_FAILED

############################################################################
#  Stop a single WLS Server
#   @param  server_name
############################################################################
def stopSingleWLSServer(server_name):
    try:
       # Make sure we are connected to 
       # a) We bring down the server completely. The Domain Runtime should be
       #    notified of server state before we exit this routine. It appears
       #    that WLST unblocks before the Domain Runtime is notified hence we
       #    block here in addition to WLST block
       if (server_state(server_name) == 'RUNNING' or server_state(server_name) == 'ADMIN'):
          debugMsg('Server stop initiated at ' + str(datetime.now())) 
          shutdown(server_name,'Server',block='true')
          nWaits = 0
          while (nWaits < 5):
             nWaits = nWaits + 1
             # if NOT connected to Admin Server
             if (connected == 'false' or server_name == adminServerName):
                debugMsg (str(datetime.now()) + ' Giving Admin Server 10 secs shutdown grace time ...')
                PyTime.sleep(10)
                debugMsg (str(datetime.now()) + ' before Deep-Sixing it ...')
                try:
                   nmKill(server_name)
                except:
                   # Admin Server may not have been started using Node Manager
                   (c, i, tb) =  sys.exc_info()
                   logMsg('SEVERE: Exception: during Admin Server kill by Node Manager')
                   logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
                break
             srvState = server_state(server_name)
             if (srvState != 'SHUTDOWN' or srvState == 'RUNNING'):
                debugMsg (str(datetime.now()) + ' Waiting for server shutdown (' + str(nWaits*10) + ') secs - current state: ' + srvState)
                PyTime.sleep(10)
                continue
             else:
                break
          if (nWaits >= 5):
             if (connected == 'false' and server_state(server_name) != 'SHUTDOWN'):
                return FmwConstants.FMW_STOPSERVER_FAILED
          debugMsg('Server stop completed at ' + str(datetime.now())) 
       else:
          return FmwConstants.FMW_SERVER_NOTRUNNING
       return 0
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during Server stop')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       return FmwConstants.FMW_STOPSERVER_FAILED

############################################################################
#  Start the Admin Server of the domain
#   @param  None
############################################################################
def startAdminServer():
    pass

############################################################################
#  Stop the Admin Server of the domain
#   @param  None
############################################################################
def stopAdminServer():
    pass

############################################################################
#  Start a list of WLS Servers
#   @param  server_list
############################################################################
def startMultipleWLSServers(server_list):
    failedStart = 0
    nNonStart = 0
    nNotFound = 0
    # Special case Admin Server
    srvs = cmo.getServers()
    for svrName in server_list:
       isFound = finditem(lambda srv: srv.getName() == svrName, srvs)
       if (not isFound):
          logMsg('Server \'' + svrName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else:
          logMsg('Starting server \'' + svrName + '\'')
          startCode = startSingleWLSServer(svrName) 
          if (startCode == FmwConstants.FMW_SERVER_ALREADYRUNNING):
             logMsg('Server \'' + svrName + '\' is already running')
             nNonStart = nNonStart + 1
          elif (startCode == FmwConstants.FMW_STARTSERVER_FAILED):
             failedStart = failedStart + 1
    if (len(server_list) == (failedStart + nNotFound)):
       sys.exit(FmwConstants.FMW_STARTSERVERS_FAILED) 
    if (len(server_list) == (nNonStart + nNotFound)):
       sys.exit(FmwConstants.FMW_NONETARGETS_STARTED) 
    if (failedStart > 0 or nNonStart > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STARTED) 

############################################################################
#  Stop a list of WLS Servers
#   @param  server_list
############################################################################
def stopMultipleWLSServers(server_list):
    failedStop = 0
    nNonStop = 0
    nNotFound = 0
    stopAdminServer = false
    srvs = cmo.getServers()
    for svrName in server_list:
       if (svrName == adminServerName):
          stopAdminServer = true
          continue
       isFound = finditem(lambda srv: srv.getName() == svrName, srvs)
       if (not isFound):
          logMsg('Server \'' + svrName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else:
          logMsg('Stopping server \'' + svrName + '\'')
          stopCode = stopSingleWLSServer(svrName)
          if (stopCode == FmwConstants.FMW_SERVER_NOTRUNNING):
             logMsg('Server \'' + svrName + '\' is not running')
             nNonStop = nNonStop + 1
          elif (stopCode == FmwConstants.FMW_STOPSERVER_FAILED):
             # Sometimes servers are in indeterminate state. We can try with Node Manager
             # and see if we can stop the server . We need to make sure that we can connect
             # to the Node Manager for the Managed Server host
             logMsg('Stopping server \'' + svrName + '\' using the Node Manager')
             (nmhostName, nmhostPort, nmSecurityType) = get_NodeManagerHostPortType(svrName)
             if (connect_NodeManager(nmhostName,nmhostPort,nmSecurityType,domainName,domainHome) == FmwConstants.FMW_NMCONNECT_FAILED):
                logMsg('Connection to Node Manager at ' + nmhostName + ':' + nmhostPort + ' failed')
                failedStop = failedStop + 1
             else:
                try:
                   logMsg('Killing server \'' + svrName + '\' using the Node Manager')
                   nmKill(svrName) 
                except:
                   failedStop = failedStop + 1
                   (c, i, tb) =  sys.exc_info()
                   logMsg('SEVERE: Exception: during server stop using Node Manager')
                   logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
             # Now disconnect from Node Manager - clean
             nmDisconnect() 
    if (stopAdminServer):
       # Perhaps we need to save some info about the Admin Server
       logMsg('Stopping Admin Server target \'' + adminServerName + '\' last')
       stopCode = stopSingleWLSServer(adminServerName)
       if (stopCode == FmwConstants.FMW_STOPSERVER_FAILED):
          failedStop = failedStop + 1
    if (len(server_list) == (failedStop + nNotFound)):
       sys.exit(FmwConstants.FMW_STOPSERVERS_FAILED) 
    if (len(server_list) == (nNonStop + nNotFound)):
       sys.exit(FmwConstants.FMW_NONETARGETS_STOPPED) 
    if (failedStop > 0 or nNonStop > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STOPPED) 

############################################################################
#  Start a single WLS Cluster
#   @param  cluster_name
############################################################################
def startSingleWLSCluster(cluster_name):
    try:
       start(cluster_name,'Cluster',block='true')
       return 0
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during Cluster start')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       return FmwConstants.FMW_STARTCLUSTER_FAILED
    pass

############################################################################
#  Stop a single WLS Cluster
#   @param  cluster_name
############################################################################
def stopSingleWLSCluster(cluster_name):
    try:
       shutdown(cluster_name,'Cluster',block='true')
       return 0
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during Cluster stop')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       return FmwConstants.FMW_STOPCLUSTER_FAILED

############################################################################
#  Start a list of WLS Clusters
#   @param  cluster_list
############################################################################
def startMultipleWLSClusters(cluster_list):
    failedStart = 0
    nNotFound = 0
    clsts = cmo.getClusters()
    for clsName in cluster_list:
       isFound = finditem(lambda clst: clst.getName() == clsName, clsts)
       if (not isFound):
          logMsg('Cluster \'' + clsName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else: 
          logMsg('Starting cluster \'' + clsName + '\'')
          startCode = startSingleWLSCluster(clsName)
          if (stopCode == FmwConstants.FMW_STARTCLUSTER_FAILED):
             failedStart = failedStart + 1
    if (len(cluster_list) == (failedStart + nNotFound)):
       sys.exit(FmwConstants.FMW_STARTCLUSTERS_FAILED) 
    if (failedStart > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STARTED) 

############################################################################
#  Stop a list of WLS Clusters
#   @param  cluster_list
############################################################################
def stopMultipleWLSClusters(cluster_list):
    failedStop = 0
    nNotFound = 0
    clsts = cmo.getClusters()
    for clsName in cluster_list:
       isFound = finditem(lambda clst: clst.getName() == clsName, clsts)
       if (not isFound):
          logMsg('Cluster \'' + clsName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else: 
          logMsg('Stopping cluster \'' + clsName + '\'')
          stopCode = stopSingleWLSCluster(clsName)
          if (stopCode == FmwConstants.FMW_STOPCLUSTER_FAILED):
             failedStop = failedStop + 1
    if (len(cluster_list) == (failedStop + nNotFound)):
       sys.exit(FmwConstants.FMW_STOPCLUSTERS_FAILED) 
    if (failedStop > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STOPPED) 

def bounceFMWApplication(theApp):
    debugMsg('Bounce the application \'' + theApp.name + '\'')
    sys.exit(FmwConstants.FMW_BOUNCEAPPLICATION_FAILED)

############################################################################
#  Serial bounce of the containers hosting the FMW Application
#   @param  theApp
############################################################################
def bounceFMWContainerSerial(theApp, alreadyBouncedList):
    debugMsg('Serial Bounce the containers hosting \'' + theApp.name + '\'')
    (failedStop, failedStart, stoppedList) = theApp.bounceContainerSerial(alreadyBouncedList)
    if (failedStop > 0 or failedStart > 0):
       logMsg('Bounce container(s) failed for \'' + theApp.name + '\'')
       return(FmwConstants.FMW_BOUNCECONTAINERS_FAILED, stoppedList)
    else:
       return(0, stoppedList)

############################################################################
#  Rolling bounce of the containers hosting the FMW Application
#   @param  theApp
#   @param  alreadyStoppedList 
############################################################################
def bounceFMWContainerRolling(theApp, alreadyBouncedList):
    debugMsg('Rolling Bounce the containers hosting \'' + theApp.name + '\'')
    (failedStop, failedStart, stoppedList) = theApp.bounceContainerRolling(alreadyBouncedList)
    if (failedStop > 0 or failedStart > 0):
       logMsg('Bounce container(s) failed for \'' + theApp.name + '\'')
       return(FmwConstants.FMW_BOUNCECONTAINERS_FAILED, stoppedList)
    else:
       return(0, stoppedList)

############################################################################
#  Bounce the Admin Server 
############################################################################
def bounceAdminServer():
    bFailedStop = false
    # We need to make sure that we can connect to the Node Manager for the Admin Server host
    (nmhostName, nmhostPort, nmSecurityType) = get_NodeManagerHostPortType(adminServerName)
    if (connect_NodeManager(nmhostName,nmhostPort,nmSecurityType,domainName,domainHome) == FmwConstants.FMW_NMCONNECT_FAILED):
       logMsg('Connection to Node Manager at ' + nmhostName + ':' + nmhostPort + ' failed')
       bFailedStop = true
    else:
       logMsg('Stopping Admin Server target \'' + adminServerName + '\' last')
       stopCode = stopSingleWLSServer(adminServerName)
       if (stopCode == FmwConstants.FMW_STOPSERVER_FAILED):
          bFailedStop = true

       # need to restart Admin Server
       ntries = 0
       startAdminServer_failed = false
       while (ntries < 3):
         ntries = ntries+ 1
         try:
            logMsg('Starting Admin Server target \'' + adminServerName + '\' first (using Node Manager) [try #' + str(ntries) + ']')
            nmStart(adminServerName, domainHome)
            startAdminServer_failed = false
            break
         except:
            (c, i, tb) =  sys.exc_info()
            logMsg('SEVERE: Exception: during Admin Server restart')
            logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
            startAdminServer_failed = true

       if (ntries == 3 and startAdminServer_failed):
          sys.exit(FmwConstants.FMW_ADMINSERVER_START_FAILED)

       # Now we need our Admin Server connection back
       try:
          logMsg('Connecting to Admin Server [after reboot] for domain ' + domain_name)
          if (connected == 'false'):
             if ((myUserConfigFile is not None) and (len( myUserConfigFile) > 0)):
                connect(userConfigFile=myUserConfigFile,userKeyFile=myUserKeyFile,url=admin_url)
             else:
                connect(admin_user, admin_password, admin_url)
       except:
          (c, i, tb) =  sys.exc_info()
          logMsg('SEVERE: Exception: during connection to Admin Server')
          logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
          sys.exit(FmwConstants.FMW_ADMINCONNECT_FAILED)

    # return the stop codes
    return bFailedStop

############################################################################
#  Serial bounce of local and servers sharing Middleware home
#   @param  serverToHomeGUIDMap 
#   @param  alreadyStoppedList 
############################################################################
def bounceLocalSharedMWHServersSerial(serverToHomeGUIDMap, alreadyStoppedList):
    debugMsg('Serial Bounce the local and Shared Middleware Home WLS servers')
    wlsServers = getMBean('/Servers').getServers()
    # Construct a list of all servers for this domain
    server_list = []
    for svr in wlsServers:
       svrName = svr.getName()
       server_list.append(svrName)

    stopAdminServer = false
    nfailedStart = 0
    nfailedStop = 0
    stopped_List = []
    excludeStart_List = []
    # First stop all of them ...
    for svrName in iter(server_list):
       svrHost = get('/Servers/' + svrName + '/ListenAddress')
       if (alreadyStoppedList is not None):
          if (alreadyStoppedList.count(svrName) > 0):
             debugMsg(' Bypassing server target \'' + svrName + ' ALREADY bounced on \'' +
                      svrHost + '\'')
             excludeStart_List.append(svrName)
             continue
       if (not (isLocalHost(svrHost) or isServerRunningFromSharedOH(svrName, serverToHomeGUIDMap))):
          debugMsg(' Bypassing remote server target \'' + svrName + ' configured on \'' + 
                   svrHost + '\'')
          excludeStart_List.append(svrName)
          continue
       elif (svrName == adminServerName):
          stopAdminServer = true
          excludeStart_List.append(svrName)
       else:
          logMsg('Stopping server \'' + svrName + '\'')
          stopCode = stopSingleWLSServer(svrName)
          if (stopCode == FmwConstants.FMW_SERVER_NOTRUNNING):
             logMsg('Server \'' + svrName + '\' is not running')
             excludeStart_List.append(svrName)
          elif (stopCode == FmwConstants.FMW_STOPSERVER_FAILED):
             nfailedStop = nfailedStop + 1
             excludeStart_List.append(svrName)
          else:
             stopped_List.append(svrName)

    # And, then at the end bounce the Admin Server ...
    if (stopAdminServer):
       bFailedStop = bounceAdminServer()
       if (bFailedStop):
          nfailedStop = nfailedStop + 1
       else:
          stopped_List.append(adminServerName)

    # Before, starting all of the others again ...
    for svrName in iter(server_list):
       if (excludeStart_List.count(svrName) > 0):
          continue
       else:
          logMsg('Starting server \'' + svrName + '\'')
          startCode = startSingleWLSServer(svrName) 
          if (startCode == FmwConstants.FMW_STARTSERVER_FAILED):
             nfailedStart = nfailedStart + 1

    if (nfailedStop > 0 or nfailedStart > 0):
       logMsg('Bounce container(s) failed for domain \'' + domainName + '\'')
       return(FmwConstants.FMW_BOUNCECONTAINERS_FAILED, stopped_List)
    else:
       return(0, stopped_List)

############################################################################
#  Rolling bounce of local and servers sharing Middleware home
#   @param serverToHomeGUIDMap 
#   @param alreadyStoppedList 
############################################################################
def bounceLocalSharedMWHServersRolling(serverToHomeGUIDMap, alreadyStoppedList):
    debugMsg('Rolling Bounce the local and Shared Middleware Home WLS servers')
    wlsServers = getMBean('/Servers').getServers()
    # Construct a list of all servers for this domain
    server_list = []
    for svr in wlsServers:
       svrName = svr.getName()
       server_list.append(svrName)

    stopAdminServer = false
    nfailedStart = 0
    nfailedStop = 0
    stopped_List = []

    for svrName in iter(server_list):
       svrHost = get('/Servers/' + svrName + '/ListenAddress')
       if (alreadyStoppedList is not None):
          if (alreadyStoppedList.count(svrName) > 0):
             debugMsg(' Bypassing server target \'' + svrName + ' ALREADY bounced on \'' +
                      svrHost + '\'')
             continue
       if (not (isLocalHost(svrHost) or isServerRunningFromSharedOH(svrName, serverToHomeGUIDMap))):
          debugMsg(' Bypassing remote server target \'' + svrName + ' configured on \'' + 
                   svrHost + '\'')
          continue
       if (svrName == adminServerName):
          stopAdminServer = true
          continue

       debugMsg(' Stopping local server target \'' + svrName + ' running on \'' +
                svrHost + '\'')
       retCode = stopSingleWLSServer(svrName)
       if (retCode == FmwConstants.FMW_STOPSERVER_FAILED):
          nfailedStop = nfailedStop + 1
       elif (retCode == FmwConstants.FMW_SERVER_NOTRUNNING):
          logMsg('Server \'' + svrName + '\' is not running')
       else:
          debugMsg(' Starting server target \'' + svrName + ' running on \'' +
                   svrHost + '\'')
          retCode = startSingleWLSServer(svrName)
          if (retCode == FmwConstants.FMW_STARTSERVER_FAILED):
             nfailedStart = nfailedStart + 1
          stopped_List.append(svrName)

    # And, then at the end bounce the Admin Server ...
    if (stopAdminServer):
       bFailedStop = bounceAdminServer()
       if (bFailedStop):
          nfailedStop = nfailedStop + 1
       else:
          stopped_List.append(adminServerName)

    if (nfailedStop > 0 or nfailedStart > 0):
       logMsg('Bounce container(s) failed for domain \'' + domainName + '\'')
       return(FmwConstants.FMW_BOUNCECONTAINERS_FAILED, stopped_List)
    else:
       return(0, stopped_List)

############################################################################
#  Start the list of FMW Applications
#   @param  app_list
############################################################################
def startMultipleFMWApplications(app_list):
    failedStart = 0
    nNotFound = 0
    apps = cmo.getAppDeployments()
    for appName in app_list:
       isFound = finditem(lambda app: app.getName() == appName, apps)
       if (not isFound):
          logMsg('Application \'' + appName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else: 
          logMsg('Starting application \'' + appName + '\'')
          theApp = Application(appName, None, None)
          if (theApp.startTheApplication() == FmwConstants.FMW_STARTAPPLICATION_FAILED):
             failedStart = failedStart + 1
    if (len(app_list) == (failedStart + nNotFound)):
       sys.exit(FmwConstants.FMW_STARTAPPLICATIONS_FAILED) 
    if (failedStart > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STARTED) 

############################################################################
#  Stop the list of FMW Applications
#   @param  app_list
############################################################################
def stopMultipleFMWApplications(app_list):
    failedStop = 0
    nNotFound = 0
    apps = cmo.getAppDeployments()
    for appName in app_list:
       isFound = finditem(lambda app: app.getName() == appName, apps)
       if (not isFound):
          logMsg('Application \'' + appName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else: 
          logMsg('Stopping application \'' + appName + '\'')
          theApp = Application(appName, None, None)
          if (theApp.stopTheApplication() == FmwConstants.FMW_STOPAPPLICATION_FAILED):
             failedStop = failedStop + 1
    if (len(app_list) == (failedStop + nNotFound)):
       sys.exit(FmwConstants.FMW_STOPAPPLICATIONS_FAILED) 
    if (failedStop > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STOPPED) 

############################################################################
#  Start the containers of a list of FMW Applications
#   @param  app_list
############################################################################
def startMultipleFMWContainers(app_list):
    failedStart = 0
    nNotFound = 0
    apps = cmo.getAppDeployments()
    for appName in app_list:
       isFound = finditem(lambda app: app.getName() == appName, apps)
       if (not isFound):
          logMsg('Application \'' + appName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else: 
          logMsg('Starting containers hosting application \'' + appName + '\'')
          theApp = Application(appName, None, None)
          if (theApp.startContainer(None, true) > 0):
             failedStart = failedStart + 1
    if (len(app_list) == (failedStart + nNotFound)):
       sys.exit(FmwConstants.FMW_STARTCONTAINERS_FAILED) 
    if (failedStart > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STARTED) 

############################################################################
#  Stop the containers of a list of FMW Applications
#   @param  app_list
############################################################################
def stopMultipleFMWContainers(app_list):
    failedStop = 0
    nNotFound = 0
    apps = cmo.getAppDeployments()
    for appName in app_list:
       isFound = finditem(lambda app: app.getName() == appName, apps)
       if (not isFound):
          logMsg('Application \'' + appName + '\' not found in this domain')
          nNotFound = nNotFound + 1
          continue
       else: 
          logMsg('Stopping containers hosting application \'' + appName + '\'')
          theApp = Application(appName, None, None)
          (nonStop, _, _) = theApp.stopContainer(true, None)
          if (nonStop > 0):
             failedStop = failedStop + 1
    if (len(app_list) == (failedStop + nNotFound)):
       sys.exit(FmwConstants.FMW_STOPCONTAINERS_FAILED) 
    if (failedStop > 0 or nNotFound > 0):
       sys.exit(FmwConstants.FMW_SOMETARGETS_STOPPED) 
    
def startFMWContainer(theApp):
    debugMsg('Start the containers hosting \'' + theApp.name + '\'')
    if (theApp.startContainer() > 0):
       logMsg('Start container failed for \'' + theApp.name + '\'')
       sys.exit(FmwConstants.FMW_STARTCONTAINERS_FAILED)

def stopFMWContainer(theApp):
    debugMsg('Stop the containers hosting \'' + theApp.name + '\'')
    if (theApp.stopContainer() > 0):
       logMsg('Stop container failed for \'' + theApp.name + '\'')
       sys.exit(FmwConstants.FMW_STOPCONTAINERS_FAILED)
