# Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      application.py
#
#    DESCRIPTION
#    The file contains the definition of all generic routines and global vars.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#     MODIFIED   (MM/DD/YY)
#     supal      11/25/09 - Rolling HA patching
#     supal      11/05/09 - Shared Oracle homes - separate domain roots
#     supal      10/30/09 - Virtual IPs and multiple Network Interfaces
#     supal      10/20/09 - Admin Server deployments
#     supal      09/12/09 - Shared library deployments
#     supal      09/07/09 - Common routines consolidation
#     supal      08/26/09 - Rolling bounce of containers
#     supal      07/06/09 - Creation

class Application:

    def redeploy( self):
        try:
           if (self.isLibrary):
              redeploy( self.name, libraryModule='true', timeout=120000)
           else:
              redeploy( self.name, timeout=120000)
           logMsg ('Redeployed the application/library ' + self.name)
           return 0
        except:
           (c, i, tb) =  sys.exc_info()
           logMsg('SEVERE: Exception: during application/library redeploy')
           logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
           return FmwConstants.FMW_REDEPLOY_FAILED

    def stopTheApplication( self):
        try:
           stopApplication( self.name, timeout=120000, block='true')
           logMsg ('Stopped the application ' + self.name)
           return 0
        except:
           (c, i, tb) =  sys.exc_info()
           logMsg('SEVERE: Exception: during application stop')
           logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
           return FmwConstants.FMW_STOPAPPLICATION_FAILED

    def startTheApplication( self):
        try:
           startApplication( self.name, timeout=120000, block='true')
           logMsg ('Started the application ' + self.name)
           return 0
        except:
           (c, i, tb) =  sys.exc_info()
           logMsg('SEVERE: Exception: during application start')
           logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
           return FmwConstants.FMW_STARTAPPLICATION_FAILED

    def stopContainer( self, ignoreLocalHostCheck, alreadyStoppedList):
        localHostOrSharedOHOnly = false
        exclude_list = []
        bounced_list = []
        if (self.stagingmode == 'nostage' and not ignoreLocalHostCheck):
           localHostOrSharedOHOnly = true
        if (localHostOrSharedOHOnly):
           logMsg('Stopping Application container(s) of \'' + self.name +
                  '\' only on local machine \'' + myHostFQDN + '\' and others sharing Oracle Home')
        else:
           logMsg('Stopping Application container(s) of \'' + self.name +
                  '\' on domain \'' + domainName + '\'')
        nNonStops = 0
        for target in self.targets:
            if (target.getType() == 'Server'):
               svrName = target.getName()
               svrHost = get('/Servers/' + svrName + '/ListenAddress')
               # Need some investigation about 'localhost' in listen address
               # as well as IP address, this needs some QA verification
               if (localHostOrSharedOHOnly):
                  if (not (isLocalHost(svrHost) or
                           isServerRunningFromSharedOH(svrName, self.serverToHomeGUIDMap))):
                     debugMsg(' Bypassing remote server target \'' + svrName + ' configured on \'' + 
                              svrHost + '\'')
                     continue
                  else:
                     pass
               else:
                  pass 
               if (alreadyStoppedList is not None):
                  if (alreadyStoppedList.count(svrName) > 0):
                     debugMsg(' Bypassing server target \'' + svrName + ' ALREADY bounced on \'' +
                              svrHost + '\'')
                     exclude_list.append(svrName)
                     continue
               # We are depending on the Admin Server to help with our bouncing
               # Hence, hold off the bounce of it for last
               if (svrName == adminServerName):
                  self.stopAdminServer = true
                  continue
               debugMsg(' Stopping local server target \'' + svrName + ' running on \'' +
                        svrHost + '\'')
               retcode = stopSingleWLSServer(svrName)
               if (retcode == FmwConstants.FMW_STOPSERVER_FAILED):
                  nNonStops = nNonStops + 1
               elif (retcode == FmwConstants.FMW_SERVER_NOTRUNNING):
                  exclude_list.append(svrName)
               else:
                  bounced_list.append(svrName)
            else:
               debugMsg(' Stopping servers of cluster target \'' + target.getName() + '\'')
               wlsServers = target.getServers()
               # Get all the servers of the Cluster and stop them 
               for svr in wlsServers:
                   svrName = svr.getName()
                   svrHost = get('/Servers/' + svrName + '/ListenAddress')
                   if (localHostOrSharedOHOnly):
                      if (not (isLocalHost(svrHost) or
                               isServerRunningFromSharedOH(svrName, self.serverToHomeGUIDMap))):
                         debugMsg(' Bypassing remote server target \'' + svrName + ' configured on \'' + 
                                  svrHost + '\'')
                         continue
                      else:
                         pass
                   else:
                      pass 
                   if (alreadyStoppedList is not None):
                      if (alreadyStoppedList.count(svrName) > 0):
                         debugMsg(' Bypassing server target \'' + svrName + ' ALREADY bounced on \'' +
                                  svrHost + '\'')
                         exclude_list.append(svrName)
                         continue
                   debugMsg(' Stopping local server target \'' + svrName + ' running on \'' +
                            svrHost + '\'')
                   retcode = stopSingleWLSServer(svrName)
                   if (retcode == FmwConstants.FMW_STOPSERVER_FAILED):
                      nNonStops = nNonStops + 1
                   elif (retcode == FmwConstants.FMW_SERVER_NOTRUNNING):
                      exclude_list.append(svrName)
                   else:
                      bounced_list.append(svrName)
        if (self.stopAdminServer):
           # We need to make sure that we can connect to the Node Manager for the Admin Server host
           # No error checks are needed as we already did that during preReq_Lifecycle
           (nmhostName, nmhostPort, nmSecurityType) = get_NodeManagerHostPortType(adminServerName)
           if (connect_NodeManager(nmhostName,nmhostPort,nmSecurityType,domainName,domainHome) == FmwConstants.FMW_NMCONNECT_FAILED):
              logMsg('Connection to Node Manager at ' + nmhostName + ':' + nmhostPort + ' failed')
              nNonStops = nNonStops + 1
              self.stopAdminServer = false
           else:
              debugMsg('Generating Admin Server boot identity and startup properties')
              nmGenBootStartupProps(adminServerName)
              debugMsg('Stopping Admin Server target \'' + adminServerName + '\' on \'' + nmhostName + '\' for domain \'' + domainName + '\' last')
              retcode = stopSingleWLSServer(adminServerName)
              if (retcode == FmwConstants.FMW_STOPSERVER_FAILED):
                 nNonStops = nNonStops + 1
              else:
                 bounced_list.append(adminServerName)
        return nNonStops, exclude_list, bounced_list

    def startContainer( self, excl_list, ignoreLocalHostCheck):
        localHostOrSharedOHOnly = false
        if (self.stagingmode == 'nostage' and not ignoreLocalHostCheck):
           localHostOrSharedOHOnly = true
        if (localHostOrSharedOHOnly):
           logMsg('Starting Application container(s) of \'' + self.name + '\' only on local machine \'' + myHostFQDN + '\'')
        else:
           logMsg('Starting Application container(s) of \'' + self.name + '\' on domain \'' + domainName + '\'')
        if (self.adminDeploy == true and self.stopAdminServer):
           # Perhaps we need to use the saved info about the Admin Server
           debugMsg('Admin Server system properties: ' + self.systemProperties)
           ntries = 0
           startAdminServer_failed = false
           while (ntries < 3):
             ntries = ntries+ 1
             try:
                logMsg('Starting Admin Server target \'' + adminServerName + '\' first (using Node Manager) [try #' + str(ntries) + ']')
                nmStart(adminServerName, domainHome)
                startAdminServer_failed = false
                break
                #startServer(adminServerName, domainName, admin_url, admin_user, admin_password, domainHome, 'true', 300000, systemProperties=self.systemProperties)
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
             if ((myUserConfigFile is not None) and (len( myUserConfigFile) > 0)): 
                connect(userConfigFile=myUserConfigFile,userKeyFile=myUserKeyFile,url=admin_url)
             else:
                connect(admin_user, admin_password, admin_url)
             # need to reconnect to MBean Server
             appDeploy = getMBean('/AppDeployments/' + self.name)
             if (appDeploy == None):
                appDeploy = getMBean('/Libraries/' + self.name)
                self.isLibrary = true
             self.targets = appDeploy.getTargets()
           except:
             (c, i, tb) =  sys.exc_info()
             logMsg('SEVERE: Exception: during connection to Admin Server')
             logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
             sys.exit(FmwConstants.FMW_ADMINCONNECT_FAILED)
        nNonStarts = 0
        for target in self.targets:
            if (target.getType() == 'Server'):
               svrName = target.getName()
               svrHost = get('/Servers/' + svrName + '/ListenAddress')
               if (localHostOrSharedOHOnly):
                  if (not (isLocalHost(svrHost) or
                           isServerRunningFromSharedOH(svrName, self.serverToHomeGUIDMap))):
                     debugMsg(' Bypassing remote server target \'' + svrName + ' configured on \'' + 
                              svrHost + '\'')
                     continue
                  else:
                     pass
               if (excl_list is not None):
                  if (excl_list.count(svrName) > 0):
                     debugMsg(' Bypassing server target \'' + svrName + ' NOT running/ALREADY bounced on \'' +
                              svrHost + '\'')
                     continue
               # We depend on the Admin Server to help with our bouncing
               # Hence, we already bounced it before this loop
               if (svrName == adminServerName):
                  continue
               debugMsg(' Starting server target \'' + svrName + ' running on \'' +
                        svrHost + '\'')
               retcode = startSingleWLSServer(svrName)
               if (retcode == FmwConstants.FMW_STARTSERVER_FAILED):
                  nNonStarts = nNonStarts + 1
            else:
               debugMsg(' Starting servers of cluster target \'' + target.getName() + '\'')
               wlsServers = target.getServers()
               # Get all the servers of the Cluster and stop them 
               for svr in wlsServers:
                   svrName = svr.getName()
                   svrHost = get('/Servers/' + svrName + '/ListenAddress')
                   if (localHostOrSharedOHOnly):
                      if (not (isLocalHost(svrHost) or
                               isServerRunningFromSharedOH(svrName, self.serverToHomeGUIDMap))):
                         debugMsg(' Bypassing remote server target \'' + svrName + ' configured on \'' + 
                                  svrHost + '\'')
                         continue
                      else:
                         pass
                   if (excl_list is not None):
                      if (excl_list.count(svrName) > 0):
                         debugMsg(' Bypassing server target \'' + svrName + ' NOT running on \'' +
                                  svrHost + '\'')
                         continue
                   debugMsg(' Starting server target \'' + svrName + ' running on \'' +
                            svrHost + '\'')
                   retcode = startSingleWLSServer(svrName)
                   if (retcode == FmwConstants.FMW_STARTSERVER_FAILED):
                      nNonStarts = nNonStarts + 1
        return nNonStarts

    def bounceContainerSerial ( self, alreadyStoppedList):
        debugMsg('Bouncing Application container(s) of \'' + self.name + '\' (serial)')
        nNoStop, nonStartList, stoppedList = self.stopContainer(false, alreadyStoppedList)
        nNoStart = self.startContainer(nonStartList, false)
        return nNoStop, nNoStart, stoppedList

    def bounceContainerRolling ( self, alreadyStoppedList):
        debugMsg('Bouncing Application container(s) of \'' + self.name + '\' (rolling)')
        localHostOrSharedOHOnly = false
        nNonStops = 0
        nNonStarts = 0
        bounceAdminServer = false
        bounced_list = []
        if (self.stagingmode == 'nostage'):
           localHostOrSharedOHOnly = true
        if (localHostOrSharedOHOnly):
           logMsg('Rolling bounce of Application container(s) of \'' + self.name +
                  '\' only on local machine \'' + myHostFQDN + '\'')
        else:
           logMsg('Rolling bounce of Application container(s) of \'' + self.name +
                  '\' on domain \'' + domainName + '\'')
        for target in self.targets:
            if (target.getType() == 'Server'):
               svrName = target.getName()
               svrHost = get('/Servers/' + svrName + '/ListenAddress')
               if (alreadyStoppedList is not None):
                  if (alreadyStoppedList.count(svrName) > 0):
                     debugMsg(' Bypassing server target \'' + svrName + ' ALREADY bounced on \'' +
                              svrHost + '\'')
                     continue
               svrState = server_state(svrName)
               if (svrState == 'RUNNING' or svrState == 'ADMIN'):
                  if (localHostOrSharedOHOnly):
                     if (not (isLocalHost(svrHost) or
                              isServerRunningFromSharedOH(svrName, self.serverToHomeGUIDMap))):
                        debugMsg(' Bypassing remote server target \'' + svrName + ' running on \'' + 
                                 svrHost + '\'')
                        continue
                     else:
                        pass
                  # We are depending on the Admin Server to help with our bouncing
                  # Hence, hold off the bounce of it for last
                  if (svrName == adminServerName):
                     bounceAdminServer = true
                     continue
                  debugMsg(' Stopping local server target \'' + svrName + ' running on \'' +
                           svrHost + '\'')
                  retcode = stopSingleWLSServer(svrName)
                  if (retcode == FmwConstants.FMW_STOPSERVER_FAILED):
                     nNonStops = nNonStops + 1
                  else:
                     debugMsg(' Starting server target \'' + svrName + ' running on \'' +
                              svrHost + '\'')
                     retcode = startSingleWLSServer(svrName)
                     if (retcode == FmwConstants.FMW_STARTSERVER_FAILED):
                        nNonStarts = nNonStarts + 1
                     bounced_list.append(svrName)
               else:
                  logMsg('Server target \'' + svrName + ' is not running on \'' +
                          svrHost + '\'')
            else:
               wlsServers = target.getServers()
               # Get running state of the servers of the Cluster 
               for svr in wlsServers:
                  svrName = svr.getName()
                  svrHost = get('/Servers/' + svrName + '/ListenAddress')
                  if (alreadyStoppedList is not None):
                     if (alreadyStoppedList.count(svrName) > 0):
                        debugMsg(' Bypassing server target \'' + svrName + ' ALREADY bounced on \'' +
                                 svrHost + '\'')
                        continue
                  svrState = server_state(svrName)
                  if (svrState == 'RUNNING' or svrState == 'ADMIN'):
                     if (localHostOrSharedOHOnly):
                        if (not (isLocalHost(svrHost) or
                                 isServerRunningFromSharedOH(svrName, self.serverToHomeGUIDMap))):
                           debugMsg(' Bypassing remote server target \'' + svrName + ' running on \'' + 
                                    svrHost + '\'')
                           continue
                        else:
                           pass
                     debugMsg(' Stopping local server target \'' + svrName + ' running on \'' +
                              svrHost + '\'')
                     retcode = stopSingleWLSServer(svrName)
                     if (retcode == FmwConstants.FMW_STOPSERVER_FAILED):
                        nNonStops = nNonStops + 1
                     else:
                        debugMsg(' Starting server target \'' + svrName + ' running on \'' +
                                 svrHost + '\'')
                        retcode = startSingleWLSServer(svrName)
                        if (retcode == FmwConstants.FMW_STARTSERVER_FAILED):
                           nNonStarts = nNonStarts + 1
                        bounced_list.append(svrName)
                  else:
                     logMsg('Server target \'' + svrName + ' is not running on \'' +
                            svrHost + '\'')
        if (bounceAdminServer):
           debugMsg('Bouncing Admin Server target \'' + svrName + '\'' + '\'' + svrHost + '\' last')
           # We need to make sure that we can connect to the Node Manager for the Admin Server host
           # No error checks are needed as we already did that during preReq_Lifecycle
           (nmhostName, nmhostPort, nmSecurityType) = get_NodeManagerHostPortType(adminServerName)
           if (connect_NodeManager(nmhostName,nmhostPort,nmSecurityType,domainName,domainHome) == FmwConstants.FMW_NMCONNECT_FAILED):
              logMsg('Connection to Node Manager at ' + nmhostName + ':' + nmhostPort + ' failed')
              nNonStops = nNonStops + 1
           else:
              debugMsg('Generating Admin Server boot identity and startup properties')
              nmGenBootStartupProps(adminServerName)
              debugMsg('Stopping Admin Server target \'' + adminServerName + '\' on \'' + nmhostName + '\' for domain \'' + domainName + '\' last')
              retcode = stopSingleWLSServer(adminServerName)
              if (retcode == FmwConstants.FMW_STOPSERVER_FAILED):
                 nNonStops = nNonStops + 1

           ntries = 0
           startAdminServer_failed = false
           while (ntries < 3):
             ntries = ntries+ 1
             try:
                logMsg('Starting Admin Server target \'' + adminServerName + '\' last (using Node Manager) [try #' + str(ntries) + ']')
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
             if ((myUserConfigFile is not None) and (len( myUserConfigFile) > 0)): 
                connect(userConfigFile=myUserConfigFile,userKeyFile=myUserKeyFile,url=admin_url)
             else:
                connect(admin_user, admin_password, admin_url)
             # need to reconnect to MBean Server
             appDeploy = getMBean('/AppDeployments/' + self.name)
             if (appDeploy == None):
                appDeploy = getMBean('/Libraries/' + self.name)
                self.isLibrary = true
             self.targets = appDeploy.getTargets()
             bounced_list.append(adminServerName)
           except:
             (c, i, tb) =  sys.exc_info()
             logMsg('SEVERE: Exception: during connection to Admin Server')
             logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
             sys.exit(FmwConstants.FMW_ADMINCONNECT_FAILED)

        return nNonStops, nNonStarts, bounced_list

    def allContainersUp( self):
        for target in self.targets:
            if (target.getType() == 'Server'):
               if (server_state(target.getName()) != 'RUNNING'):
                  return false
            else:
               wlsServers = target.getServers()
               # Get running state of the servers of the Cluster 
               for svr in wlsServers:
                  if (server_state(target.getName()) != 'RUNNING'):
                     return false
        return true

    def getDomainRootMap( self):
       return self.serverToDomainRootMap

    def getServerHomeGuidMap( self):
       return self.serverToHomeGUIDMap

    def getTargets( self):
       return self.targets

    def getServers( self):
       if (len(self.allServers) == 0):
          for target in self.getTargets():
              targetName = target.getName()
              if (target.getType() == 'Server'):
                 self.allServers.append(targetName)
              else:
                 wlsServers = target.getServers()
                 for svr in wlsServers:
                    targetName = svr.getName()
                    self.allServers.append(targetName)
       # Return the list of WLS servers on which the app is deployed
       return self.allServers

    def __init__(self, name, serverToDomainRootMap, serverToHomeGUIDMap):
       self.__inner_init(name)
       self.serverToDomainRootMap = serverToDomainRootMap
       self.serverToHomeGUIDMap = serverToHomeGUIDMap

    def __inner_init( self, name):
        self.name = name
        self.isLibrary = false
        self.systemProperties = ''
        appDeploy = getMBean('/AppDeployments/' + self.name)
        if (appDeploy == None):
           appDeploy = getMBean('/Libraries/' + self.name)
           self.isLibrary = true
        self.sourcePath = appDeploy.getAbsoluteSourcePath
        self.stagingmode = appDeploy.getStagingMode()
        if (isApplicationNoStage(name)):
            logMsg('\'' + name + '\' application is configured \'NoStage\'')
            self.stagingmode = 'nostage'
        self.appname = appDeploy.getApplicationName()
        self.version = appDeploy.getVersionIdentifier()
        self.targets = appDeploy.getTargets()
        self.adminDeploy = false
        self.stopAdminServer = false
        self.allServers = []
        logMsg('Application \'' + appDeploy.getName() + '\' deployed on:')
        for target in self.targets:
            isAdminServer = false
            targetName = target.getName()
            svrSpecial = ' [Managed Server]'
            if (target.getType() == 'Server'):
               if (adminServerName == targetName):
                  isAdminServer = true
                  self.adminDeploy = true
               else:
                  pass
            else:
               pass
            if (isAdminServer):
               svrSpecial = ' [Admin Server]'
               # Verify if Admin Server can be part of cluster/assumption for now is SA
               self.stagingmode == 'nostage'
               self.systemProperties = getMBean('/Servers/' + targetName + '/ServerStart/' + targetName).getStartupProperties().toString()
            if (target.getType() == 'Server'):
               logMsg('    Name: \'' + targetName + '\' TargetType: \'' + target.getType() + '\'' +
                      svrSpecial)
            else:
               logMsg('    Name: \'' + targetName + '\' TargetType: \'' + target.getType() + '\'') 
