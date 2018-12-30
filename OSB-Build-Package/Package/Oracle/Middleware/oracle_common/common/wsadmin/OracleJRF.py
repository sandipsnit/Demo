"""
 Copyright (c) 1998, 2013, Oracle and/or its affiliates. All rights reserved. 

Define JRF commands

Caution: This file is part of the wsadmin implementation. Do not edit or move this file because this may cause
wsadmin commands and scripts to fail. Do not try to reuse the logic in this file or keep copies of this file 
because this could cause your wsadmin scripts to fail when you upgrade to a different version of wsadmin.
"""

import os, AdminUtilities
import java.lang

#*******************************************************************
# Public: install JRF to a server for WAS ND Edition
#*******************************************************************
def applyJRFToServer(cellName, nodeName, serverName, shouldUpdateConfig=1):

    jrf_checkWasNDEdition(nodeName)

    targetPath = jrf_getServerPath(cellName, nodeName, serverName)
    targetId = jrf_getId(targetPath)
    # clustered server case
    clusterName = AdminConfig.showAttribute(targetId, 'clusterName')
    if clusterName != '' and clusterName != None:     
        applyJRFToCluster(cellName, clusterName, shouldUpdateConfig)
        return
    
    if jrf_isJRFInstalled(targetId):
        return

    print 'Apply JRF to server: ' + targetPath   
         
    # libraries
    for library in jrf_getLibraries():
        AdminConfig.create('Library', targetId, [['name',  library.name], ['classPath', library.srcPath]])
        
    # apps
    jrf_installApps(cellName, nodeName, serverName)

    # single JRF CustomService that manages JRF registered startup/shutdown classes    
    AdminConfig.create('CustomService', targetId, [['classname', 'oracle.jrf.was.WebSphereJRFCustomService'], ['enable', 'true'], ['classpath', ''], ['displayName', 'Oracle JRF Custom Service']])
    
    # JVM memory args and properties
    jrf_configJVM(cellName, nodeName, serverName)   
    
    # url providers, i.e mds url handler
    jrf_configURLProviders(targetId)
    
    # set ORACLE_JDBC_DRIVER_PATH variable 
    jrf_configOracleJDBCDriverPath(cellName, nodeName, serverName)

    #enable StartupBeansService
    jrf_enableStartupBeansService(cellName, nodeName, serverName)
      
    # copy server-scoped config files           
    jrf_copyServerConfigFiles(cellName, nodeName, serverName, 1)
   
    # set global listener property
    jrf_setGlobalListenersToServer(cellName, nodeName, serverName) 
    jrf_saveConfig(shouldUpdateConfig)
        
#*******************************************************************
# Internal: temporary functions  used for provisioning WAS AS (Base) Edition
# TODO:   delete when provisioning for AS edition is switched to use template
#*******************************************************************
def jrf_applyJRFToServerBaseEdition(cellName, nodeName, serverName, shouldUpdateConfig=1):

    jrf_checkWasBaseEdition(nodeName)

    targetPath = jrf_getServerPath(cellName, nodeName, serverName)
    targetId = jrf_getId(targetPath)

    if jrf_isJRFInstalled(targetId):
        return

    print 'Apply JRF to server: ' + targetPath
    # libraries
    for library in jrf_getLibraries():
        AdminConfig.create('Library', targetId, [['name',  library.name], ['classPath', library.srcPath]])

    # apps
    jrf_installAppsBaseEdition(cellName, nodeName, serverName)

    # single JRF CustomService that manages JRF registered startup/shutdown classes
    AdminConfig.create('CustomService', targetId, [['classname', 'oracle.jrf.was.WebSphereJRFCustomService'], ['enable', 'true'], ['classpath', ''], ['displayName', 'Oracle JRF Custom Service']])

    # JVM memory args and properties
    jrf_configJVM(cellName, nodeName, serverName)

    # url providers, i.e mds url handler
    jrf_configURLProviders(targetId)

    # set ORACLE_JDBC_DRIVER_PATH variable
    jrf_configOracleJDBCDriverPath(cellName, nodeName, serverName)

    #enable StartupBeansService
    jrf_enableStartupBeansService(cellName, nodeName, serverName)

    # copy server-scoped config files
    jrf_copyServerConfigFiles(cellName, nodeName, serverName, 0)

    jrf_saveConfig(shouldUpdateConfig)
        
# install apps for managed server Base  edition
def jrf_installAppsBaseEdition(cellName, nodeName, serverName):
    for app in jrf_getApps():
        commonCompHome = jrf_getVariable('COMMON_COMPONENTS_HOME', 'Cell=' + cellName)
        appPath = app.srcPath.replace('${COMMON_COMPONENTS_HOME}', commonCompHome)
        AdminApp.install(appPath, ['-appname', app.name, '-cell', cellName, '-node', nodeName, '-server', serverName, '-usedefaultbindings'])

#*******************************************************************
# Public: install JRF to a cluster  - WAS ND edition
#*******************************************************************        
def applyJRFToCluster(cellName, clusterName, shouldUpdateConfig=1):
    
    # check target is admin server
    targetPath = jrf_getClusterPath(cellName, clusterName)
    targetId = jrf_getId(targetPath) 
    
    isJRFinstalled = jrf_isJRFInstalled(targetId)
    
    if not isJRFinstalled:
        print 'Apply JRF to cluster: ' + targetPath
        # libraries
        for library in jrf_getLibraries():
            AdminConfig.create('Library', targetId, [['name',  library.name], ['classPath', library.srcPath]])

        # apps        
        jrf_installApps(cellName, clusterName=clusterName)
    
    # settings that must be applied to member servers instead of the cluster
    # NOTE: still need to called to allow the case of extending a cluster with a new server
    for server in jrf_listAllServers():
        if clusterName == AdminConfig.showAttribute(server, 'clusterName'):
            nodeName = jrf_getNodeNameFromId(server)
            serverName = jrf_getNameFromId(server)  

            foundCustomService = 0
            for customService in jrf_listCustomServices(server):
                name = AdminConfig.showAttribute(customService, 'displayName')
                if name == 'Oracle JRF Custom Service':
                    foundCustomService = 1
                    break
            # it is new server, apply server settings
            if not foundCustomService:
                print 'Apply JRF to cluster\'s member: ' + serverName
                # single JRF CustomService that manages JRF registered startup/shutdown classes
                AdminConfig.create('CustomService', server, [['classname', 'oracle.jrf.was.WebSphereJRFCustomService'], ['enable', 'true'], ['classpath', ''], ['displayName', 'Oracle JRF Custom Service']])
        
                # JVM memory args and properties, must be set on each member server  
                jrf_configJVM(cellName, nodeName, serverName) 
                
                # url providers, i.e mds url handler
                jrf_configURLProviders(server)
				
                jrf_configOracleJDBCDriverPath(cellName, nodeName, serverName)

                #enable StartupBeansService
                jrf_enableStartupBeansService(cellName, nodeName, serverName)
                
                # copy server-scoped config files       
                jrf_copyServerConfigFiles(cellName, nodeName, serverName, 1)
                      
    
    jrf_saveConfig(shouldUpdateConfig)
    
#*****************************************************************************
# Public: install JRF to a managed server or cluster. 
# 'targetPath' is the containment path of a server or cluster.
#  e.g: '/Cell:DefaultCell/Node:DefaultCellFederatedNode/Server:server1'
#       '/Cell:DefaultCell/ServerCluster:cluser1'
# Default 'targetPath' is '*', meaning install JRF to all managed servers and clusters  
#*****************************************************************************        
def applyJRF(targetPath='*', shouldUpdateConfig=1):
    if targetPath == '*':
        # apply to all stand alone severs
        for cell in jrf_getList(AdminConfig.list('Cell')):
            cellName = jrf_getNameFromId(cell)
                                                    
            for server in jrf_listAppServers():
                clusterName = AdminConfig.showAttribute(server, 'clusterName')
                if clusterName is None or clusterName == '':     
                    nodeName = jrf_getNodeNameFromId(server)
                    serverName = jrf_getNameFromId(server)
                    applyJRFToServer(cellName, nodeName, serverName, 0)
        # apply to all clusters       
        for cluster in jrf_listClusters():
            cellName = cellName = jrf_getCellNameFromId(cluster)
            clusterName = jrf_getNameFromId(cluster)
            applyJRFToCluster(cellName, clusterName, 0)
    else:        
        targetId = jrf_getId(targetPath)                    
        if targetId.find('/clusters/') > 0:
            cellName = jrf_getCellNameFromId(targetId)
            clusterName = jrf_getNameFromId(targetId)
            applyJRFToCluster(cellName, clusterName, 0)
        elif targetId.find('/servers/') > 0:
            cellName = jrf_getCellNameFromId(targetId)
            nodeName = jrf_getNodeNameFromId(targetId)                
            serverName = jrf_getNameFromId(targetId)                
            applyJRFToServer(cellName, nodeName, serverName, 0)
        else:
            raise LookupError('Not found target: ' + targetId)
                
    jrf_saveConfig(shouldUpdateConfig)
      
#*******************************************************************
# JRF resources and config helpers 
#*******************************************************************        
#Define the class for app-deployment resource.
class JRFAppDeployment:
    def __init__(self, name, srcPath, target=''):
        self.name = name
        self.srcPath = srcPath
        self.target = target

#Define the class for library resource.
class JRFLibrary:
    def __init__(self, name, srcPath):
        self.name = name
        self.srcPath = srcPath
        
class JRFJvmProperty:
    def __init__(self, name, value):
        self.name = name
        self.value = value
           
# check if JRF is installed by looking for a matched jrf libary 
def jrf_isJRFInstalled(targetId, oracleHome='', wlHome=''):    
    jrfLibName = jrf_getLibraries()[0].name     
    for lib in  jrf_getList(AdminConfig.list('Library')):
        if jrfLibName == jrf_getNameFromId(lib):            
            libTargetStr = jrf_getLibTargetString(lib)
            if targetId.find(libTargetStr) > 0:
                return 1
    return 0  
     
def jrf_configOracleJDBCDriverPath(cellName, nodeName, serverName=0):
    if serverName:
        AdminTask.setVariable('[-scope ' + 'Cell=' + cellName + ',Node=' + nodeName + ',Server=' + serverName +  ' -variableName ORACLE_JDBC_DRIVER_PATH -variableValue ${COMMON_COMPONENTS_HOME}/modules/oracle.jdbc_11.1.1]')
    
    AdminTask.setVariable('[-scope ' + 'Cell=' + cellName + ',Node=' + nodeName + ' -variableName ORACLE_JDBC_DRIVER_PATH -variableValue ${COMMON_COMPONENTS_HOME}/modules/oracle.jdbc_11.1.1]')
  
# set jvm memory args and properties
def jrf_configJVM(cellName, nodeName, serverName):
    # memory args
    AdminTask.setGenericJVMArguments('[-nodeName ' + nodeName + ' -serverName ' + serverName + ' -genericJvmArguments \"-Xms256m -Xmx512m -XX:PermSize=128m -XX:MaxPermSize=512m\"]')
       
    # JVM properties
    for property in jrf_getJvmProperties():
        AdminTask.setJVMSystemProperties('[-nodeName ' + nodeName + ' -serverName ' + serverName + ' -propertyName ' + property.name + ' -propertyValue ' + property.value + ']')

# set URLProvider, i.e MDS URL handler
def jrf_configURLProviders(targetId):
    AdminConfig.create('URLProvider', targetId, '[[streamHandlerClassName "oracle.mds.net.protocol.oramds.Handler"] [classpath ""] [name "oramds protocol"] [isolatedClassLoader "false"] [nativepath ""] [description ""] [protocol "oramds"]]')

#enable StartupBeansService
def jrf_enableStartupBeansService(cellName, nodeName, serverName):
  sbs = AdminConfig.getid("/Cell:" + cellName + "/Node:" + nodeName + "/Server:" + serverName + "/PMEServerExtension:/StartupBeansService:/")
  AdminConfig.modify(sbs,  [['enable', 'true']])
  
# copy server-scoped config files
def jrf_copyServerConfigFiles(cellName, nodeName, serverName, isDistributedCell):
    if isDistributedCell:
        serverConfigDir = jrf_getDmgrServerConfigDir(cellName, nodeName, serverName)    
        serverTemplateDir = os.path.join(jrf_getDmgrDomainConfigDir(), 'server-config-template')
    else:
        serverConfigDir = jrf_getServerConfigDir(cellName, nodeName, serverName)    
        serverTemplateDir = os.path.join(jrf_getDomainConfigDir(cellName, nodeName), 'server-config-template')
    
    print 'Copy JRF server-scoped files from ' + serverTemplateDir + ' to ' + serverConfigDir        
    jrf_customCopyTree(serverTemplateDir, serverConfigDir , overwriteFile=0)                
 
def jrf_copyAndHandleWASConfigDir(srcDir,  dstDir, overwriteFile=0, filters=[]):               
    wasConfigDir = os.path.join(srcDir, 'was')
    jbossConfigDir = os.path.join(srcDir, 'jboss')
    if os.path.isdir(wasConfigDir):
        # copy was config dir, so that its files are used instead of the duplicates from the parent
        jrf_customCopyTree(src=wasConfigDir,  dst=dstDir, overwriteFile=0)
        # copy parent config dir (wls or commond config dir) to root, and exclude /was and /jboss subdir
        filters.append(wasConfigDir)
        filters.append(jbossConfigDir)
    else:
        filters.append(jbossConfigDir)
        
    jrf_customCopyTree(src=srcDir,  dst=dstDir, overwriteFile=0,  filterPaths=filters)                

# install apps for managed server and cluster  - WebSphere ND edition
def jrf_installApps(cellName, nodeName='', serverName='', clusterName=''):
    for app in jrf_getApps():        
        if clusterName != '':
            currentTarget = 'WebSphere:cell=' + cellName + ',cluster=' + clusterName
        else:
            currentTarget = 'WebSphere:cell=' + cellName + ',node=' + nodeName + ',server=' + serverName            
        
        if app.target != '%AdminServer%':
            targets = currentTarget      
            
            # include existing targets  
            for tmpSrv in jrf_listAllServers():
                tmpSrvName = jrf_getNameFromId(tmpSrv)
                tmpSrvNodeName = jrf_getNodeNameFromId(tmpSrv)
                tmpSrvCellName = jrf_getCellNameFromId(tmpSrv)
                tmpSrvTarget = 'WebSphere:cell=' + tmpSrvCellName + ',node=' + tmpSrvNodeName + ',server=' + tmpSrvName
            
                for appName in jrf_getList(AdminApp.list(tmpSrvTarget)):
                    if appName == app.name:
                        targets += '+' + tmpSrvTarget
                        
            for tmpCl in jrf_listClusters():
                tmpClName = jrf_getNameFromId(tmpCl)
                tmpClCellName = jrf_getCellNameFromId(tmpCl)
                tmpClTarget = 'WebSphere:cell=' + tmpClCellName + ',cluster=' + tmpClName
            
                for appName in jrf_getList(AdminApp.list(tmpClTarget)):
                    if appName == app.name:
                        targets += '+' + tmpClTarget                        

            AdminApp.edit(app.name, '[  -MapModulesToServers [[ .* .* ' + targets + ']]]' )

def jrf_saveConfig(shouldUpdateConfig):            
    if shouldUpdateConfig:
        print 'Save JRF changes'
        AdminConfig.save()
        
        
#*******************************************************************
# wsadmin helper functions 
#*******************************************************************
# Return value of the node's metadata property 'com.ibm.websphere.baseProductShortName'
# Return string is 'Base'  - AS Edition (single server) or 'ND' - Network Edition (multi-servers, cluster and HA)
def jrf_getWASProductShortName(nodeName):
    return AdminTask.getMetadataProperty('[-nodeName ' + nodeName + ' -propertyName com.ibm.websphere.baseProductShortName]')

def jrf_isWasNDEdition(nodeName):
    return 'ND' == jrf_getWASProductShortName(nodeName)

def jrf_isWasBaseEdition(nodeName):
    return 'Base' == jrf_getWASProductShortName(nodeName)

def jrf_checkWasNDEdition(nodeName):
    jrf_msg = 'Current product is not WebSphere Network Deployment Edition: com.ibm.websphere.baseProductShortName = ' + jrf_getWASProductShortName(nodeName)
    if jrf_isWasBaseEdition(nodeName):
        jrf_msg += '. Note that execution of applyJRF command is not required on WebSphere Base (single server) Edition when profile has been provisioned with JRF'
        raise EnvironmentError(jrf_msg)        
    elif not jrf_isWasNDEdition(nodeName):
        raise EnvironmentError(jrf_msg)

def jrf_checkWasBaseEdition(nodeName):
    if not jrf_isWasBaseEdition(nodeName):
        raise EnvironmentError('Current product is not WebSphere Base (single server) Edition: com.ibm.websphere.baseProductShortName = ' + jrf_getWASProductShortName(nodeName))

def jrf_isCellDistributed():
    _cell = AdminConfig.list("Cell")
    return 'DISTRIBUTED' == AdminConfig.showAttribute(_cell, 'cellType')
    
# return a list from string results, separate by new line - '/n'
def jrf_getList(stringResult):
    return AdminUtilities.convertToList(stringResult)

def jrf_getLibTargetString(libId):
    startIndex = libId.index('(') 
    endIndex = libId.rindex('|')    
    return libId[startIndex + 1 : endIndex]  

def jrf_listClusters():
    return jrf_getList(AdminConfig.list('ServerCluster'))

def jrf_listCustomServices(serverId):
    return jrf_getList(AdminConfig.list('CustomService', serverId))

def jrf_getNameFromId(idString):
    return AdminConfig.showAttribute(idString, 'name')
      
def jrf_getNodeNameFromId(targetId):
    nodeStr = ('/nodes/')
    startIndex = targetId.index(nodeStr ) + len(nodeStr)
    endInex = targetId.index("/", startIndex )
    return targetId[startIndex : endInex ]

def jrf_getCellNameFromId(targetId): 
    cellStr = ('cells/')
    startIndex = targetId.index(cellStr ) + len(cellStr)
    endInex = targetId.index("/", startIndex )
    return targetId[startIndex : endInex ]

    
def jrf_getNodeProfilePath(nodeName):
    return AdminTask.showVariables('[-variableName USER_INSTALL_ROOT -scope Node=' + nodeName + ']')      

def jrf_listNodes(includeDmgrNode=0):   
    nodeList = jrf_getList(AdminConfig.list('Node'))
    if includeDmgrNode:
        return nodeList

    dmgrId = jrf_getDmgrServer()
    
    startIndex = dmgrId.index('dmgr(') 
    endIndex = dmgrId.rindex('/servers/')    
    dmgrNodeString = dmgrId[startIndex + 5 : endIndex]
    
    noDmgrNodeList = []
    for nodeId in nodeList:   
        if nodeId.find(dmgrNodeString) < 0:
            noDmgrNodeList.append(nodeId)
    return noDmgrNodeList

# the return list does not include the deployment manager server    
def jrf_listAppServers(nodeName=''): 
    cmdArg = '[-serverType APPLICATION_SERVER'
    if nodeName != '':
        cmdArg += ' -nodeName ' + nodeName
    return jrf_getList(AdminTask.listServers(cmdArg + ']')) 

def jrf_listAllServers(): 
    return jrf_getList(AdminTask.listServers())    

def jrf_getOracleAdminServerName():
    return 'OracleAdminServer'

def jrf_getOracleAdminServer():
    for server in jrf_listAppServers():
        if jrf_getOracleAdminServerName() == jrf_getNameFromId(server):
            return server
    raise LookupError(jrf_getOracleAdminServerName())  

def jrf_getVariable(varName, scopeStr):
    varValue = AdminTask.showVariables('[-variableName ' + varName + ' -scope ' + scopeStr + ']')
    if varValue == '':
        raise LookupError('Variable: ' + varName + ' not found in scope: ' + scopeStr)
    return varValue    
    
def jrf_isDmgrServer(serverId):
    return 'dmgr' == jrf_getNameFromId(serverId)
    
def jrf_getDmgrServer():
    serversString = AdminTask.listServers()
    serverList = jrf_getList(serversString)
    for serverId in serverList:
        if serverId.startswith('dmgr('):
            return serverId
    raise LookupError('dmgr')  
    
def jrf_getDmgrNode():   
    dmgrSrv = jrf_getDmgrServer()
    cellName = jrf_getCellNameFromId(dmgrSrv)
    nodeName = jrf_getNodeNameFromId(dmgrSrv)    
    return jrf_getId('/Cell:'+ cellName + '/Node:' + nodeName)
       
def jrf_getDmgrProfilePath():
    return jrf_getNodeProfilePath(jrf_getNodeNameFromId(jrf_getDmgrServer())) 

def jrf_getServerConfigDir(cellName, nodeName, serverName):
    return os.path.join(jrf_getNodeProfilePath(nodeName), 'config/cells/' + cellName + '/nodes/' + nodeName + '/servers/' + serverName + '/fmwconfig')

def jrf_getDmgrServerConfigDir(cellName, nodeName, serverName):
    return os.path.join(jrf_getDmgrProfilePath(), 'config/cells/' + cellName + '/nodes/' + nodeName + '/servers/' + serverName + '/fmwconfig')

def jrf_getDmgrDomainConfigDir():
    dmgrSrv = jrf_getDmgrServer()
    return jrf_getDomainConfigDir(jrf_getCellNameFromId(dmgrSrv), jrf_getNodeNameFromId(dmgrSrv))

def jrf_getDomainConfigDir(cellName, nodeName):
    return os.path.join(jrf_getNodeProfilePath(nodeName), 'config/cells/' + cellName + '/fmwconfig')

def jrf_getId(targetPath):
    targetId = AdminConfig.getid(targetPath)    
    if targetId == '':
        raise LookupError('Target not found: ' + targetPath)
    return targetId

def jrf_getClusterPath(cellName, clusterName):
    return '/Cell:' + cellName + '/ServerCluster:' + clusterName

def jrf_getCluster(cellName, clusterName):
    return jrf_getId(jrf_getClusterPath(cellName, clusterName))

def jrf_getServerPath(cellName, nodeName, serverName):
    return '/Cell:'+ cellName + '/Node:' + nodeName + '/Server:' + serverName  

def jrf_getServer(cellName, nodeName, serverName):
    return jrf_getId(jrf_getServerPath(cellName, nodeName, serverName))


# copy cell and server scoped config files - used by the template
def jrf_copyDomainConfigFiles(fmwDomainConfigDir, commonCompsHome):
    jrfModules = os.path.join(commonCompsHome, "modules")
    fmwServerConfigTemplateDir = os.path.join(fmwDomainConfigDir , 'server-config-template')

    print("copy cell-scoped config files from " + jrfModules + " to " + fmwDomainConfigDir)
    for compDirName in os.listdir(jrfModules):
        compDomainDir = os.path.join(jrfModules, compDirName);
        compDomainDir = os.path.join(compDomainDir, "domain_config");
        compServerDir = os.path.join(jrfModules, compDirName)
        compServerDir = os.path.join(compServerDir, "server_config")
        if os.path.exists(compDomainDir):
            jrf_copyAndHandleWASConfigDir(compDomainDir, fmwDomainConfigDir)
        if os.path.exists(compServerDir):
            #filter out adml server config to avoid duplicate copies.
            adml_filter = []
            if compDirName == 'oracle.em_11.1.1':
               adml_filter.append(os.path.join(compServerDir, 'adml'))
            jrf_copyAndHandleWASConfigDir(compServerDir, fmwServerConfigTemplateDir, filters=adml_filter)

#*******************************************************************
# Customized file I/O functions 
#*******************************************************************
def jrf_copyfileobj(fsrc, fdst, length=16*1024):
    """copy data from file-like object fsrc to file-like object fdst"""
    while 1:
        buf = fsrc.read(length)
        if not buf:
            break
        fdst.write(buf)

def jrf_copyfile_win(src, dst):
    """Copy data from src to dst"""
    fsrc = None
    fdst = None
    try:
        fsrc = open(src, 'rb')
        fdst = open(dst, 'wb')
        jrf_copyfileobj(fsrc, fdst)
    finally:
        if fdst:
            fdst.close()
        if fsrc:
            fsrc.close()

def jrf_copyfile_unix(src, dst):
    os.system('cp -p ' + src + ' ' + dst)

def iswindows(): 
  osname = java.lang.System.getProperty( "os.name" ) 
  return osname.lower().find("win") > -1 

def jrf_copyfile(src, dst):
    """Copy data from src to dst"""
    if iswindows(): 
       jrf_copyfile_win(src, dst)
    else:
       jrf_copyfile_unix(src, dst)

def jrf_customCopyTree(src, dst, symlinks=0, overwriteFile=1, filterPaths=[]):
    """Custom copy file or directory recursively from src to dst"""    
    for skippedPath in filterPaths:
        if os.path.samefile(skippedPath, src):
            return
                
    if not os.path.exists(dst):
        os.makedirs(dst)
    names = os.listdir(src)
    for name in names:
        srcname = os.path.join(src, name)
        dstname = os.path.join(dst, name)
        try:
            if os.path.isdir(srcname):
                jrf_customCopyTree(srcname, dstname, symlinks, overwriteFile, filterPaths)
            elif symlinks and os.path.islink(srcname):
                linkto = os.readlink(srcname)
                os.symlink(linkto, dstname)
            elif overwriteFile or (not os.path.exists(dstname)):
                jrf_copyfile(srcname, dstname)
        except (IOError), why:
            print "Can't copy %s to %s: %s" % (`srcname`, `dstname`, str(why))   


# Generated function that returns all JRF JVM properties
def jrf_getJvmProperties():
    jvmProperties = []
    jvmProperties.append(JRFJvmProperty('common.components.home', '${COMMON_COMPONENTS_HOME}'))
    jvmProperties.append(JRFJvmProperty('jrf.version', '11.1.1'))
    jvmProperties.append(JRFJvmProperty('org.apache.commons.logging.Log', 'org.apache.commons.logging.impl.Jdk14Logger'))
    jvmProperties.append(JRFJvmProperty('java.protocol.handler.pkgs', 'oracle.mds.net.protocol'))
    jvmProperties.append(JRFJvmProperty(' igf.arisidbeans.carmlloc', '${ORACLE_DOMAIN_CONFIG_DIR}/carml'))
    jvmProperties.append(JRFJvmProperty(' igf.arisidstack.home', '${ORACLE_DOMAIN_CONFIG_DIR}/arisidprovider'))
    jvmProperties.append(JRFJvmProperty('oracle.server.config.dir', '${USER_INSTALL_ROOT}/config/cells/${CELL}/nodes/${NODE}/servers/${SERVER}/fmwconfig'))
    jvmProperties.append(JRFJvmProperty('oracle.domain.config.dir', '${ORACLE_DOMAIN_CONFIG_DIR}'))
    jvmProperties.append(JRFJvmProperty('ws.ext.dirs', '${COMMON_COMPONENTS_HOME}/modules/oracle.jrf_11.1.1/jrf-was.jar'))
    jvmProperties.append(JRFJvmProperty('oracle.admin.server.name', '${ORACLE_ADMIN_SERVER_NAME}'))
    jvmProperties.append(JRFJvmProperty('was.cell.name', '${WAS_CELL_NAME}'))
    jvmProperties.append(JRFJvmProperty('client.encoding.override', 'UTF-8'))
    jvmProperties.append(JRFJvmProperty('oracle.security.jps.config', '${ORACLE_DOMAIN_CONFIG_DIR}/jps-config.xml'))
    jvmProperties.append(JRFJvmProperty('com.ibm.wsspi.security.web.webAuthReq', 'persisting'))
    jvmProperties.append(JRFJvmProperty('oracle.deployed.app.dir', '${USER_INSTALL_ROOT}/installedApps/${CELL}'))
    jvmProperties.append(JRFJvmProperty('oracle.deployed.app.ext', '.ear/-'))
    return jvmProperties

# Generated function that returns all JRF app-deployment resource instances.
def jrf_getApps():
    appArray = []
    appArray.append(JRFAppDeployment('FMW Welcome Page Application_11.1.0.0.0', '${COMMON_COMPONENTS_HOME}/modules/oracle.jrf_11.1.1/fmw-welcome.ear', '%AdminServer%'))
    appArray.append(JRFAppDeployment('DMS Application_11.1.1.1.0', '${COMMON_COMPONENTS_HOME}/modules/oracle.dms_11.1.1/dms-was.ear', ''))
    appArray.append(JRFAppDeployment('Dmgr DMS Application_11.1.1.1.0', '${COMMON_COMPONENTS_HOME}/modules/oracle.dms_11.1.1/dms-was.ear', '%dmgr%'))
    appArray.append(JRFAppDeployment('wsil-nonwls', '${COMMON_COMPONENTS_HOME}/modules/oracle.webservices_11.1.1/wsil-nonwls.ear', ''))
    return appArray

# Generated function that returns all JRF library resource instances.
def jrf_convertLibPath(libPath):
    return libPath.replace('$ORACLE_HOME$', '${COMMON_COMPONENTS_HOME}')

def jrf_getLibraries():
    libArray = []
    libArray.append(JRFLibrary('oracle.wsm.seedpolicies_11.1.1_11.1.1', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.wsm.policies_11.1.1/wsm-seed-policies.jar')))
    libArray.append(JRFLibrary('oracle.jsp.next_11.1.1_11.1.1', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.jsp_11.1.1/ojsp.jar')))
    libArray.append(JRFLibrary('oracle.dconfig-infra_11_11.1.1.1.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.dconfig-infra_11.1.1.jar')))
    libArray.append(JRFLibrary('orai18n-adf_11_11.1.1.1.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.nlsgdk_11.1.0/orai18n-adf.jar')))
    libArray.append(JRFLibrary('oracle.adf.dconfigbeans_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.adf.dconfigbeans_11.1.1.jar')))
    libArray.append(JRFLibrary('oracle.pwdgen_11.1.1_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.pwdgen_11.1.1/pwdgen.jar')))
    libArray.append(JRFLibrary('adf.oracle.domain_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/features/adf.model_11.1.1.jar;$ORACLE_HOME$/modules/oracle.adf.businesseditor_11.1.1/adf-businesseditor-settings.jar;$ORACLE_HOME$/modules/oracle.adf.businesseditor_11.1.1/adf-businesseditor-model.jar')))
    libArray.append(JRFLibrary('jsf_1.2_1.2.9.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.jsf_1.2.9/glassfish.jsf_1.0.0.0_1-2-15.jar;$ORACLE_HOME$/modules/oracle.jsf_1.2.9/glassfish.jstl_1.2.0.1.jar;$ORACLE_HOME$/modules/oracle.jsf_1.2.9/javax.jsf_1.1.0.0_1-2.jar')))
    libArray.append(JRFLibrary('adf.oracle.domain.webapp_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-dt-at-rt.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-dynamic-faces.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-faces-changemanager-rt.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-faces-databinding-dt-core.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-faces-databinding-rt.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-faces-templating-dt-core.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-faces-templating-dtrt.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-richclient-api-11.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-richclient-automation-11.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-richclient-impl-11.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-share-web.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/adf-view-databinding-dt-core.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-databindings.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-faces.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-facesbindings.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-jclient.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-trinidad.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-utils.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/dvt-databinding-dt-core.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/trinidad-api.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/trinidad-impl.jar;$ORACLE_HOME$/modules/oracle.adf.controller_11.1.1/adf-controller.jar;$ORACLE_HOME$/modules/oracle.adf.controller_11.1.1/adf-controller-api.jar;$ORACLE_HOME$/modules/oracle.adf.controller_11.1.1/adf-controller-rt-common.jar;$ORACLE_HOME$/modules/oracle.adf.pageflow_11.1.1/adf-pageflow-dtrt.jar;$ORACLE_HOME$/modules/oracle.adf.pageflow_11.1.1/adf-pageflow-fwk.jar;$ORACLE_HOME$/modules/oracle.adf.pageflow_11.1.1/adf-pageflow-impl.jar;$ORACLE_HOME$/modules/oracle.adf.pageflow_11.1.1/adf-pageflow-rc.jar;$ORACLE_HOME$/modules/velocity-dep-1.4.jar;$ORACLE_HOME$/modules/oracle.facesconfigdt_11.1.1/facesconfigmodel.jar;$ORACLE_HOME$/modules/oracle.facesconfigdt_11.1.1/taglib.jar;$ORACLE_HOME$/modules/oracle.bali.share_11.1.1/share.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/jewt4.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/inspect4.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/bundleresolver.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-anim.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-awt-util.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-bridge.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-codec.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-css.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-dom.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-ext.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-extension.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-gui-util.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-gvt.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-parser.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-script.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-svg-dom.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-svggen.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-swing.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-transcoder.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-util.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-xml.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/xml-apis-ext.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpclient-4.1.2.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpclient-cache-4.1.2.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpcore-4.1.2.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpmime-4.1.2.jar')))
    libArray.append(JRFLibrary('adf.oracle.businesseditor_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.adf.businesseditor_11.1.1/adf-businesseditor.jar')))
    libArray.append(JRFLibrary('UIX_11_11.1.1.1.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.uix_11.1.1/uix2.jar;$ORACLE_HOME$/modules/oracle.uix_11.1.1/uixadfrt.jar;$ORACLE_HOME$/modules/oracle.uix_11.1.1/uix2tags.jar')))
    libArray.append(JRFLibrary('oracle.adf.management_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.adf.management_11.1.1/adf-em-config.jar')))
    libArray.append(JRFLibrary('ohw-rcf_5_5.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.help_5.0/help-share.jar;$ORACLE_HOME$/modules/oracle.help_5.0/ohw-rcf.jar;$ORACLE_HOME$/modules/oracle.help_5.0/ohw-share.jar')))
    libArray.append(JRFLibrary('oracle.adf.desktopintegration.model_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/features/adf.desktopintegration.model_11.1.1.jar')))
    libArray.append(JRFLibrary('oracle.adf.desktopintegration_1.0_11.1.1.2.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.adf.desktopintegration_11.1.1/adf-desktop-integration.jar')))
    libArray.append(JRFLibrary('ohw-uix_5_5.0', jrf_convertLibPath('$ORACLE_HOME$/modules/oracle.help_5.0/help-share.jar;$ORACLE_HOME$/modules/oracle.help_5.0/ohw-uix.jar;$ORACLE_HOME$/modules/oracle.help_5.0/ohw-share.jar')))
    return libArray

# Generated function that returns all global listeners defined for WebSphere.
def jrf_getGlobalListeners():
    return "oracle.dms.was.DMSServletRequestListener"

# set the global listener to the managed server.
def jrf_setGlobalListenersToServer(cellName, nodeName, serverName):
     if jrf_getGlobalListeners() != '':
        serverId = jrf_getId(jrf_getServerPath(cellName, nodeName, serverName))
        serverWebContainer = AdminConfig.list("WebContainer", serverId )
        AdminConfig.create("Property", serverWebContainer, '[[validationExpression ""]  [name "listeners"]  [value ' + jrf_getGlobalListeners() + '] [required "false"]]')