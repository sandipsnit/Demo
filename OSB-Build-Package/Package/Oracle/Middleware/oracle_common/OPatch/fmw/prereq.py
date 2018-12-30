# Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      prereq.py
#
#    DESCRIPTION
#    The file contains the definition of all generic routines fpr performing
#    Prereq operations.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#     MODIFIED   (MM/DD/YY)
#     supal      02/24/10 - Catch exception from Custom MBean access
#     supal      11/16/09 - Optimize prereq checks and support classpath
#                           patches
#     supal      11/05/09 - Shared Oracle homes - separate domain roots
#     supal      10/30/09 - Virtual IPs and multiple Network Interfaces
#     supal      10/23/09 - Admin Server Deployments
#     supal      09/27/09 - Need to work with various Node Manager Types and
#                           Blank Listen Addresses for Node Manager
#     supal      09/06/09 - More checks for Configuration corner cases
#     supal      08/31/09 - Shared Libraries check
#     supal      07/12/09 - Creation

import exceptions

def isServerRunningFromSharedOH( server_name, serverToHomeGUIDMap):
    server_commonHomeGuid = serverToHomeGUIDMap[server_name]
    if ((server_commonHomeGuid is not None) and (commonHomeGuid is not None) and
        (commonHomeGuid != '')):
       if (server_commonHomeGuid == str(commonHomeGuid)):
          return true
       else:
          return false
    else:
       return false

def __reconnectToAdminServer():
    try:
       if (connected == 'true' and isAdminServer == 'false'):
          disconnect() # from current Managed Server
       if ((myUserConfigFile is not None) and (len( myUserConfigFile) > 0)):  
          connect(userConfigFile=myUserConfigFile,userKeyFile=myUserKeyFile,url=admin_url)
       else:
          connect(admin_user, admin_password, admin_url)
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during (re)connection to Admin Server')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       sys.exit(FmwConstants.FMW_ADMINCONNECT_FAILED)

def __getServerDomainHomeAndCommonHomeGUID( srvName):
    try:
       if (adminServerName != srvName or isAdminServer == 'false'):
          srvHost = get('/Servers/' + srvName + '/ListenAddress')
          srvPort = get('/Servers/' + srvName + '/ListenPort')
          if (srvHost is None or srvHost == '' or srvPort is None or srvPort == 0):
             debugMsg('WebLogic Server \'' + srvName + '\' does not have Listen Endpoint configured')
             return None, None
          srvURL = 't3://' + srvHost + ':' + str(srvPort)
          # disconnect from the current Server
          if (connected == 'true'):
             disconnect()
          logMsg('Connecting to WebLogic Server \'' + srvName + '\' for domain \'' + domain_name + '\'')
          if ((myUserConfigFile is not None) and (len( myUserConfigFile) > 0)):  
             connect(userConfigFile=myUserConfigFile,userKeyFile=myUserKeyFile,url=srvURL,timeout='120000')
          else:
             connect(admin_user, admin_password, srvURL, timeout='120000')
       else:
          logMsg('Bypassing WebLogic Admin Server \'' + srvName + '\' for domain \'' + domain_name + '\'')
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during connection to WebLogic Server ' + srvName)
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       __reconnectToAdminServer()
       return None, None

    try:
       domainRoot = get('RootDirectory')
       myTree = currentTree()
       custom();
       cd('oracle.jrf.server/oracle.jrf.server:name=JRFService,type=oracle.jrf.JRFServerScopedServiceMBean')
       commonHomeGUID = get('CommonComponentsHomeGUID')
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('SEVERE: Exception: during JRF MBean navigation on WebLogic Server ' + srvName)
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       __reconnectToAdminServer()
       return None, None

    debugMsg('Domain Root for \'' + srvName + '\' is ' + domainRoot)
    debugMsg('Common Home OH GUID is ' + commonHomeGUID)

    myTree()
    return domainRoot, commonHomeGUID

def __check_NodeManagerConnectivity(server_name, bLocalOnly, domainRootMap, homeGuidMap, machinesCheckDoneList):
    bnonNMConfigure = false
    bnonNMMachineConfigure = false
    bnonSVRConfigure = false
    bnonConnects = false
    machineName = ''
    bNMMachineChecked = false
    try:
      (nmhostName, nmhostPort, nmSecurityType) = get_NodeManagerHostPortType(server_name)
    except exceptions.EnvironmentError, (errno, strerror):
      debugMsg('ExceptionNum: ' + str(errno) +', ExceptionMsg: ' + strerror)
      if (errno == FmwConstants.FMW_NO_MACHINES_CONFIGURED):
         bnonNMMachineConfigure = true
    if (bnonNMMachineConfigure):
       pass
    elif (nmhostName is None or nmhostPort is None or nmhostName == '' or nmhostPort == ''):
       debugMsg('The Machine on which WebLogic Server \'' + targetName + '\' is installed does not have the Node Manager Listen Address and/or Listen Port configured')
       bnonNMConfigure = true
       machineMBean = getMBean('/Servers/' + server_name).getMachine()
       machineName = machineMBean.getName() 
       bNMMachineChecked = true
    else:
       serverMBean = getMBean('/Servers/' + server_name)
       svrHost = serverMBean.getListenAddress()
       svrPort = serverMBean.getListenPort()
       machineMBean = serverMBean.getMachine()
       machineName = machineMBean.getName() 
       if (machinesCheckDoneList.count(machineName) > 0):  # already done!
          debugMsg('\'' + machineName + '\' - Node Manager connectivity already checked')
          pass
       elif (svrHost is None or svrHost == '' or svrPort is None or svrPort == 0):
          debugMsg('WebLogic Server \'' + server_name + '\' does not have Listen Endpoint configured')
          bnonSVRConfigure = true
          bnonConnects = true
       else:
          domainRoot = domainRootMap[server_name]
          if (connect_NodeManager(nmhostName,nmhostPort,nmSecurityType,domainName,domainRoot) == FmwConstants.FMW_NMCONNECT_FAILED):
             if (bLocalOnly):
                if (isLocalHost(nmhostName)):
                   bnonConnects = true
                # shared MWH/OH check
                elif isServerRunningFromSharedOH( server_name, homeGuidMap):
                   bnonConnects = true
             else:
                bnonConnects = true
          else:
             disconnect_NodeManager()
          bNMMachineChecked = true
    # return the validation results
    return bnonNMConfigure, bnonNMMachineConfigure, bnonSVRConfigure, bnonConnects, bNMMachineChecked, machineName

def prereq_Lifecycle_ClassPath(serversCheckDoneList, machinesCheckDoneList, wlsServerToDomainRootMap, wlsServerToHomeGUIDMap):
    nonNMConfigure = 0
    nonNMMachineConfigure = 0
    nonSVRConfigure = 0
    nonConnects = 0
    serverList_checked = []

    wlsServers = getMBean('/Servers').getServers()
    for target in wlsServers:
       targetName = target.getName()
       logMsg('Server Target - Name: \'' + targetName + '\'')
       if (serversCheckDoneList.count(targetName) > 0):  # already done!
          debugMsg('\'' + targetName + '\' - Node Manager connectivity already checked')
          continue
       (bnonNMConfigure,bnonNMMachineConfigure,bnonSVRConfigure,bnonConnects,bNMMachineChecked,machineName) = __check_NodeManagerConnectivity(targetName, true, wlsServerToDomainRootMap, wlsServerToHomeGUIDMap, machinesCheckDoneList)
       if (bnonNMMachineConfigure):
          nonNMMachineConfigure = nonNMMachineConfigure + 1
       if (bnonNMConfigure):
          nonNMConfigure = nonNMConfigure + 1
       if (bnonSVRConfigure):
          nonSVRConfigure = nonSVRConfigure + 1
       if (bnonConnects):
          nonConnects = nonConnects + 1
       if (bNMMachineChecked):
          if (machinesCheckDoneList.count(machineName) == 0):
             machinesCheckDoneList.append(machineName)
       serverList_checked.append(targetName)
    return serverList_checked, machinesCheckDoneList, nonSVRConfigure, nonNMMachineConfigure, nonNMConfigure, nonConnects

def prereq_Lifecycle_App(app, serversCheckDoneList, machinesCheckDoneList):
    nonNMConfigure = 0
    nonNMMachineConfigure = 0
    nonSVRConfigure = 0
    nonConnects = 0
    # In PS1 we will have a JRF Mbean attribute which will indicate if the
    # Oracle Home is shared (well it will return the HOME_GUID and we will 
    # have to write some Guid comparison code).
    # OPatch will obtain the Guid of the Oracle Home being patched from the MBean
    # If the Guid from remote m/c equal to the one passed from OPatch then it is a 
    # shared Oracle Home. When that feature appears in WLS/FMW, we will have to verify 
    # that Node Manager is accessible NOT only on the local node BUT ALSO on all nodes
    # which have the Middleware Home mounted as a NFS share.
    localHostOnly = false
    serverList_checked = []
    if (app.stagingmode == 'nostage'):
       localHostOnly = true
    wlsTargets = app.getTargets()
    wlsServerToDomainRootMap = app.getDomainRootMap()
    wlsServerToHomeGUIDMap = app.getServerHomeGuidMap()

    for target in wlsTargets:
       targetName = target.getName()
       if (target.getType() == 'Server'):
          logMsg('Server Target - Name: \'' + targetName + '\'')
          if (serversCheckDoneList.count(targetName) > 0):  # already done!
             debugMsg('\'' + targetName + '\' - Node Manager connectivity already checked')
             continue
          (bnonNMConfigure,bnonNMMachineConfigure,bnonSVRConfigure,bnonConnects,bNMMachineChecked,machineName) = __check_NodeManagerConnectivity(targetName, localHostOnly, wlsServerToDomainRootMap, wlsServerToHomeGUIDMap, machinesCheckDoneList)
          if (bnonNMMachineConfigure):
             nonNMMachineConfigure = nonNMMachineConfigure + 1
          if (bnonNMConfigure):
             nonNMConfigure = nonNMConfigure + 1
          if (bnonSVRConfigure):
             nonSVRConfigure = nonSVRConfigure + 1
          if (bnonConnects):
             nonConnects = nonConnects + 1
          if (bNMMachineChecked):
             if (machinesCheckDoneList.count(machineName) == 0):
                machinesCheckDoneList.append(machineName)
          serverList_checked.append(targetName)
       else:
          logMsg('Cluster Target - Name: \'' + targetName + '\'')
          wlsServers = target.getServers()
          # Get all the machines of the Cluster and test NM connectivity 
          for svr in wlsServers:
             targetName = svr.getName()
             if (serversCheckDoneList.count(targetName) > 0):  # already done!
                debugMsg('\'' + targetName + '\' - Node Manager connectivity already checked')
                continue
             (bnonNMConfigure,bnonNMMachineConfigure,bnonSVRConfigure,bnonConnects,bNMMachineChecked,machineName) = __check_NodeManagerConnectivity(targetName, localHostOnly, wlsServerToDomainRootMap, wlsServerToHomeGUIDMap, machinesCheckDoneList)
             if (bnonNMMachineConfigure):
                nonNMMachineConfigure = nonNMMachineConfigure + 1
             if (bnonNMConfigure):
                nonNMConfigure = nonNMConfigure + 1
             if (bnonSVRConfigure):
                nonSVRConfigure = nonSVRConfigure + 1
             if (bnonConnects):
                nonConnects = nonConnects + 1
             if (bNMMachineChecked):
                if (machinesCheckDoneList.count(machineName) == 0):
                   machinesCheckDoneList.append(machineName)
             serverList_checked.append(targetName)
    return serverList_checked, machinesCheckDoneList, nonSVRConfigure, nonNMMachineConfigure, nonNMConfigure, nonConnects

def isApplicationConfigured(appName):
    appDeploy = getMBean('/AppDeployments/' + appName)
    if (appDeploy == None):
       appDeploy = getMBean('/Libraries/' + appName)
       if (appDeploy == None):
          return false
       else:
          return true
    else:
       return true

def isApplicationNoStage(appName):
    appDeploy = getMBean('/AppDeployments/' + appName)
    # what about AdminServer deployments (confirm Dave Felts/Mark Nelson)
    if (appDeploy == None):
       appDeploy = getMBean('/Libraries/' + appName)
       if (appDeploy == None):
          return false
       else:
          pass
    if (appDeploy.getStagingMode() == 'nostage'):
       return true
    else:
       deployTargets = appDeploy.getTargets()
       targetCount = 0
       adminDeploy = false
       for target in deployTargets:
           targetCount = targetCount + 1
           if (target.getType() == 'Server'):
              if (adminServerName == target.getName()):
                 adminDeploy = true
           else:
              pass
       if (targetCount == 1 and adminDeploy):
          return true  # Deployed only on Admin Server
       else:
          return false 
  
def prereq_Deploy(applicationNames):
    nNonStaged = 0
    nConfigureds = 0
    nNonConfigureds = 0
    nNonRunningStaged = 0
    nSysClassPathApp = 0
    for appName in applicationNames:
      if (isApplicationConfigured(appName)):
         if (isApplicationNoStage(appName)):
            logMsg('\'' + appName + '\' application is configured \'NoStage\'')
            nNonStaged = nNonStaged + 1
         else:
            logMsg('\'' + appName + '\' application is configured \'Stage\'')
            theApp = Application(appName)
            if (not theApp.allContainersUp()):
               nNonRunningStaged = nNonRunningStaged + 1
         nConfigureds = nConfigureds + 1
      elif (appName == FmwConstants.FMW_ANONYMOUS_APP):
         nSysClassPathApp = nSysClassPathApp + 1
      else:
         logMsg('\'' + appName + '\' application is Not configured')
         nNonConfigureds = nNonConfigureds + 1
    if (nNonConfigureds > 0):
       logMsg('Some Applications are not configured in this domain - Please check OPatch log for details')
    return nConfigureds, nNonConfigureds, nNonStaged, nNonRunningStaged, nSysClassPathApp

def getServerDomainHomeAndCommonHomeGUIDMaps( applicationNames):
    # Construct a list of all servers on which these apps are deployed
    server_list = []
    for appName in applicationNames:
       if (isApplicationConfigured(appName)):
          appDeploy = getMBean('/AppDeployments/' + appName)
          if (appDeploy == None):
             appDeploy = getMBean('/Libraries/' + appName)
          wlsTargets = appDeploy.getTargets()
          for target in wlsTargets:
             if (target.getType() == 'Server'):
                svrName = target.getName()
                if (server_list.count(svrName) == 0):  # include if not there
                   server_list.append(svrName)
             else:
                wlsServers = target.getServers()
                for svr in wlsServers:
                   svrName = svr.getName()
                   if (server_list.count(svrName) == 0):  # include if not there
                      server_list.append(svrName)
       elif (appName == FmwConstants.FMW_ANONYMOUS_APP):
          wlsServers = cmo.getServers()
          for svr in wlsServers:
             svrName = svr.getName()
             if (server_list.count(svrName) == 0):  # include if not there
                server_list.append(svrName)
       else:
          pass

    # Get the Domain Root and Home GUID mappings
    domainRoot = ''
    homeGuid = ''
    serverToDomainRootMap = {}
    serverToHomeGUIDMap = {}
    for svrName in iter(server_list):
       (domainRoot, homeGuid) = __getServerDomainHomeAndCommonHomeGUID(svrName)
       if (domainRoot is None):
          serverToDomainRootMap[svrName] = domainHome
       else:
          serverToDomainRootMap[svrName] = domainRoot
       serverToHomeGUIDMap[svrName] = homeGuid

    # Be connected to The one and only MBean and Controlling Server
    if (connected == 'true' and isAdminServer == 'false'):
       __reconnectToAdminServer()

    return serverToDomainRootMap, serverToHomeGUIDMap
