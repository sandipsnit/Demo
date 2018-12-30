"""
 Copyright (c) 1998, 2013, Oracle and/or its affiliates. All rights reserved. 

Define JRF commands

Caution: This file is part of the WLST implementation. Do not edit or move this file because this may cause
WLST commands and scripts to fail. Do not try to reuse the logic in this file or keep copies of this file 
because this could cause your WLST scripts to fail when you upgrade to a different version of WLST.
"""

import os, sys

import java.io.File

import oracle.jrf.InternalJrfUtils
import oracle.jrf.i18n.JRFMessageBundleHelper
import oracle.jrf.i18n.JRFMessageID

import java.util.zip.ZipFile
import javax.xml.parsers.DocumentBuilderFactory

# Apply JRF components to the specified standalone server or cluster, or '*' for all servers, 
# except the components that are intended to target admin server only (i.e. <target>%AdminServer%</target>)

def applyJRF(target, domainDir=None, shouldUpdateDomain=true): 
    jrfConfigResources = jrf_getConfigResources()
    jrfComponents = jrfConfigResources[0]
    jrfAdminSrvOnlyComps = jrfConfigResources[1]
       
    if (domainDir):
        os.putenv('DOMAIN_HOME', domainDir)        
        if (cmo is None) and (connected == 'false'):        
            print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.READ_DOMAIN, [domainDir])
            readDomain(domainDir)
            
    if (cmo is None):
        raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.NO_DOMAIN_READ))
    
    jrf_check_install(jrfComponents[0][0], jrfComponents[0][1], os.getenv('DOMAIN_HOME'))
        
    if (connected == 'true' and shouldUpdateDomain):
        edit()
        startEdit()              
        
    cd('/')	
    if (target == '*'):    
        for cluster in cmo.getClusters():
            applyJRF(cluster.getName(), None,false) 
        for server in cmo.getServers():
            if server.getCluster() is None:
                applyJRF(server.getName(), None, false) 
        
        if (shouldUpdateDomain):
            if (connected == 'true'): 
                print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.UPDATE_DOMAIN, [domainDir, "online"])
                save()
                activate()
            else:
                print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.UPDATE_DOMAIN, [domainDir, "offline"])
                updateDomain()
                        
        return

    newTarget = target
    clusteredServers = []
    for server in cmo.getServers():
        if target == server.getName():
            jrf_copyConfigs(target)
            jrf_setDiagContextEnabled(target, connected)
            break
        elif not (server.getCluster() is None) and target == server.getCluster().getName():
            # apply to the cluster of the clustered server instead of the clustered server itself
            newTarget = server.getCluster().getName()
            clusteredServers.append(server)
            jrf_copyConfigs(server.getName())

    print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.TARGET_JRF_COMPONENTS, [newTarget])

    if (connected == 'true'):
        jrf_applyJRFOnline(newTarget, jrfComponents, jrfAdminSrvOnlyComps, shouldUpdateDomain, clusteredServers)
        if (shouldUpdateDomain == true):
            print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.UPDATE_DOMAIN, [domainDir, "online"])
            save()
            activate()         
        return
        
    cd('/')
    adminServerName = get('AdminServerName')     
    # retarget admin-server-only components to workaround wlst default targeting that auto targets 
    # components to all available targets in the modified domain when previous domain only has admin server.
    if (target == adminServerName): 
        for component in jrfAdminSrvOnlyComps:
            for server in cmo.getServers():
                unassign(component[0], component[1], 'Target', server.getName())   
            for cluster in cmo.getClusters():
                unassign(component[0], component[1], 'Target', cluster.getName())   
            assign(component[0], component[1], 'Target', adminServerName)            
        
    for component in jrfComponents:
        for clusteredServer in clusteredServers: 
            unassign(component[0], component[1], 'Target', clusteredServer.getName())    
        unassign(component[0], component[1], 'Target', newTarget)
        assign(component[0], component[1], 'Target', newTarget)

    if (shouldUpdateDomain and connected == 'false'): 
        print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.UPDATE_DOMAIN, [domainDir, "offline"])
        updateDomain()
# END: applyJRFToTarget(target)      

def jrf_check_install(compType, compName, domainDir):
    _typeToAttributeMap = jrf_getTypeToAttributeMap()
    compsAttribute = _typeToAttributeMap[compType]
    
    jrfComp = None
    if (connected == 'true'):
        jrfComp = getMBean('/' + compsAttribute + '/' + compName)
    else: 
        cd('/')
        allComps = get(compsAttribute)
        for comp in allComps:
            if compName == comp.getName():
                jrfComp = comp
                break
    if jrfComp is None:
        raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.NONE_JRF_EXTENDED_DOMAIN, ["applyJRF", str(domainDir)]))
        
def jrf_applyJRFOnline(target, allSrvsComps, adminSrvOnlyComps, shouldUpdateDomain=true, clusteredServers=[]):
    jrfTarget = getMBean('/Servers/' + target)
    
    if jrfTarget is None:
        jrfTarget = getMBean('/Clusters/' + target)
        
    if jrfTarget is None:        
        raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.NOT_FOUND_DOMAIN_TARGET, [target]))

    _typeToMbeanPathMap = {'AppDeployment':'AppDeployments', 'Library':'Libraries', 'StartupClass':'StartupClasses','ShutdownClass':'ShutdownClasses', 'WLDFSystemResource':'WLDFSystemResources'}       
    # target components to all servers and clusters
    for component in allSrvsComps:
        jrfMBeanPath = '/' + _typeToMbeanPathMap[component[0]] + '/' + component[1]
        jrfComp = getMBean(jrfMBeanPath)  
        if jrfComp is None:
            raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.JRF_COMPONENT_NOT_FOUND, [component[0], component[1]]))
        # remove targets that are cluster's members to support use-case: cluster is extended with a previously jrf-enabled server
        for server in clusteredServers:
            jrfComp.removeTarget(server)
            
        jrfComp.addTarget(jrfTarget)
        
    # target components  to admin server only
    for component in adminSrvOnlyComps:
        jrfMBeanPath = '/' + _typeToMbeanPathMap[component[0]] + '/' + component[1]
        jrfComp = getMBean(jrfMBeanPath)  
        if jrfComp is None:
            raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.JRF_COMPONENT_NOT_FOUND, [component[0], component[1]]))
        
        # remove all targets that might be added by fmwconfig auto targeting 
        currentTargets = []
        currentTargets.extend(jrfComp.getTargets())
        for removedTarget in currentTargets:
            jrfComp.removeTarget(removedTarget)
        
        cd('/')
        adminServName = get('AdminServerName')   
        adminServ = getMBean('/Servers/' + adminServName)
        jrfComp.addTarget(adminServ)        

# Copy server scoped config files from COMMON_COMPONENTS_HOME
def jrf_copyConfigs(serverName, domainPath=None):
    # get required envs    
    _COMMON_COMPONENTS_HOME = jrf_getCommonCompsHome()
    _DOMAIN_HOME = domainPath
    # load from config wizz's object store
    try:
        if _DOMAIN_HOME is None: 
            _DOMAIN_HOME = retrieveObject("DOMAIN_DIRECTORY")
    except (NameError):
        'ignore: retrieveObject() is not available'
    # load from OS, if not possible with config wizz (i.e variables does not exist or retrieveObject() is not available)
    try:
        if _DOMAIN_HOME is None:        
            _DOMAIN_HOME = os.getenv("DOMAIN_HOME")
    except (KeyError):        
        print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.ENV_NOT_SET, ["DOMAIN_HOME"])
        
    if _DOMAIN_HOME is None:
        raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.ENV_NOT_SET, ["DOMAIN_DIRECTORY, DOMAIN_HOME"])) 
    
    fmw_server_config_dir = _DOMAIN_HOME + "/config/fmwconfig/servers/" + serverName    
    print jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.COPY_CONFIG_FILES, [_COMMON_COMPONENTS_HOME + '/modules', fmw_server_config_dir])
    oracle.jrf.InternalJrfUtils.copyServerConfigTemplateToServerDir(java.io.File(_DOMAIN_HOME, 'config/fmwconfig'), java.io.File(_COMMON_COMPONENTS_HOME), java.io.File(fmw_server_config_dir))

# set the diagnostic context enabled property to the server
def jrf_setDiagContextEnabled(serverName, connected):
    if (connected == 'true'):
       #online mode command
       cd('/Servers/' + serverName + '/ServerDiagnosticConfig/' + serverName)
       cmo.setDiagnosticContextEnabled(true)
    else:
       #ofline mode command
       cd('/Server/' + serverName)
       create(serverName,'ServerDiagnosticConfig')
       cd('ServerDiagnosticConfig/' + serverName)
       set('DiagnosticContextEnabled','true')

#**********************************************************************************************#
#    Clone the resource deployment from source server to target server function                                     
#    domain: The wls domian name with full path.                                                                    
#            None value can be used if the domain has already been loaded in                                        
#    source: The string name of the server/cluster that you want to clone from.                                     
#            It should be a valid target from config.xml and should represent a single target.                      
#    target: The target server/cluster that will receive the source server's targets.                               
#            The target server must exist already.                                                                  
#    shouldUpdateDomain:                                                                                            
#            The optional true/false flag that controls how domain update is done, default value is true.           
#            When it is set to true, the function implicitly invokes the offline commands -                         
#            readDomain(), updateDomain() or online commands - edit(), startEdit(), save(),                         
#            activate(). When it is set to false, user must manually invoke those commands.                         
#**********************************************************************************************#

def cloneDeployments(domain, source, target, shouldUpdateDomain=true):
    # module types
    APP_DEPLOYMENT = 'AppDeployment'
    LIBRARY = 'Library'
    STARTUP_CLASS = 'StartupClass'
    SHUTDOWN_CLASS = 'ShutdownClass'
    JDBC_SYSTEM_RESOURCE = 'JDBCSystemResource'
    WLDF_SYSTEM_RESOURCE = 'WLDFSystemResource'
        
    if (connected == 'true'):
        if (shouldUpdateDomain):
            edit()
            startEdit()
    elif (cmo is None and domain != None):
        readDomain(domain)
    cd('/')
    jrf_cloneModule(APP_DEPLOYMENT, cmo.getAppDeployments(), source, target)
    jrf_cloneModule(LIBRARY, cmo.getLibraries(), source, target)
    jrf_cloneModule(STARTUP_CLASS, cmo.getStartupClasses(), source, target)
    jrf_cloneModule(SHUTDOWN_CLASS, cmo.getShutdownClasses(), source, target)
    jrf_cloneModule(JDBC_SYSTEM_RESOURCE, cmo.getJDBCSystemResources(), source, target)
    jrf_cloneModule(WLDF_SYSTEM_RESOURCE, cmo.getWLDFSystemResources(), source, target)
    if (shouldUpdateDomain):
        if (connected == 'true'):
            save()
            activate()
        else:
            updateDomain()

#*****************************************************************#
#            Clone the resource from source to target function    #
#*****************************************************************#
def jrf_cloneModule(type, modules, source, target):
    if modules is None:
        return
    for module in modules:
        targetList = jrf_getTargetList(module)
        if source in targetList:
            if (connected == 'true'):
                if not (target in targetList):
                    targetMBean = getMBean('/Servers/' + target)
                    if targetMBean is None:
                        targetMBean = getMBean('/Clusters/' + target)                    
                    if targetMBean is None:                        
                        raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.NOT_FOUND_DOMAIN_TARGET, [target]))
        
                    module.addTarget(targetMBean)
            else:
                if target in targetList:
                    unassign(type, module.getName(), 'Target', target)
                assign(type, module.getName(), 'Target', target)

#*****************************************************************#
#            Return module's target string list function          #
#*****************************************************************#
def jrf_getTargetList(module):
    targetList = []
    tgts = module.getTargets()
    if not (tgts is None):
        for target in tgts:
            targetList.append(target.getName())
    return targetList

def jrf_getTypeToAttributeMap():
    return {'AppDeployment':'AppDeployments', 'Library':'Libraries', 'StartupClass':'StartupClasses','ShutdownClass':'ShutdownClasses', 'WLDFSystemResource':'WLDFSystemResources'}

#*****************************************************************#
#       Add help for applyJRF and cloneDeployments                #
#*****************************************************************#
try:
    addHelpCommandGroup("jrf-config-help","jrf-config")
    addHelpCommand("applyJRF", "jrf-config-help")
    addHelpCommand("cloneDeployments","jrf-config-help") 
except (WLSTException), why:    
    print 'WARNING: ' + jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.FAIL_ADD_HELP, [str(why)])
    
def jrf_getI18nMessage(msg_id, msg_args=[]):
    return oracle.jrf.i18n.JRFMessageBundleHelper.msg.getString(msg_id, msg_args)


#********************************************************************************************************************
#  INTERNAL PUBLIC: upgrade configuration of an existing domain that was extended with a older JRF template version 
#                   to be in sync with the new JRF template version in the current install
#************************#*******************************************************************************************
def upgradeJRF(domainPath):
    if cmo != None:
       raise WLSTException("Detect open domain. Invoke closeDomain() prior to upradeJRF.") 
        
    readDomain(domainPath)
    if (cmo is None):
        dumpStack()
        return

    cd('/') 
    if jrf_isJRFUpToDate():
        closeDomain()
        print 'upgradeJRF: skip, JRF is up-to-date.'
        return
        
    if not jrf_isJRFInstalled():
        closeDomain()    
        print 'upgradeJRF: skip, no JRF found in the domain. Extend the domain with JRF template and use applyJRF instead of upgrade.'
        return
        
    _COMMON_COMPONENTS_HOME = jrf_getCommonCompsHome()
                   
    print 'upgradeJRF: BEGIN'                 

    # apply domain-scoped changes defined in upgrade template
    print 'Apply patch template'
    addTemplate(os.path.join(_COMMON_COMPONENTS_HOME, 'common/templates/applications/jrf_uprade_template_11.1.1.4.0.jar'))
    # fix domain with config groups upgrade template
    addTemplate(os.path.join(_COMMON_COMPONENTS_HOME, 'common/templates/applications/jrf_upgrade_config_groups_template_11.1.1.jar'))
   
    # apply target-scoped changes obtained from config.xml of the current version of template.       
    jrfTemplateJar = java.util.zip.ZipFile(os.path.join(_COMMON_COMPONENTS_HOME,'common/templates/applications/jrf_template_11.1.1.jar'))
    jrfEntry = jrfTemplateJar.getEntry('config/config.xml')
    jrfConfigXMLDom = jrf_getXmlDoccument(jrfTemplateJar.getInputStream(jrfEntry)) 
    jrfTemplateJar.close()
    
    jrf_upgradeApps(jrfConfigXMLDom)
    jrf_upgradeLibraries(jrfConfigXMLDom)    
    jrf_upgradeStartupClasses(jrfConfigXMLDom)
    jrf_upgradeShutdownClasses(jrfConfigXMLDom)
    jrf_upgrade_WLDFSystemResources(jrfConfigXMLDom)
    
    # not from template
    jrf_upgradeSetDiagContextEnabled()    
    
    jrf_upgradeConfigFiles(domainPath)
    
    updateDomain()    
    closeDomain()
    print 'upgradeJRF: FINISH'                 

#*****************************************************************#
#       Upgrade helpers                                           #
#*****************************************************************#
                               
def jrf_upgradeApps(jrfConfigXMLDom):
    adminServerName = get('AdminServerName') 
    
    i = 0
    tags = jrfConfigXMLDom.documentElement.getElementsByTagName('app-deployment')
    jrfCompNames =[]
    while i < tags.length:
        xmlElem = tags.item(i)
        i = i +1 
        compName = jrf_getSingleChildXMLElemValue(xmlElem, 'name')
        jrfCompNames.append(compName)
        
        if jrf_isComponentInstalled('AppDeployment', compName):
            continue
            
        print "Create AppDeployment \"" + compName + "\""
        
        compTarget = jrf_getSingleChildXMLElemValue(xmlElem,'target')
        compModuleType = jrf_getSingleChildXMLElemValue(xmlElem,'module-type')
        compSourcePath = jrf_getSingleChildXMLElemValue(xmlElem,'source-path')
        compSourcePath = jrf_convertPath(compSourcePath)
        compDeployOrder = jrf_getSingleChildXMLElemValue(xmlElem,'deployment-order')
        compSecureModel = jrf_getSingleChildXMLElemValue(xmlElem,'security-dd-model')                
        compStagingMode = jrf_getSingleChildXMLElemValue(xmlElem,'staging-mode')   

        newComp = create(compName, 'AppDeployment')
        jrf_upgrade_assignTargets('AppDeployment', compName, compTarget)   
        if not (compModuleType is None):
            newComp.setModuleType(compModuleType)
        if not (compSourcePath is None):
            newComp.setSourcePath(compSourcePath)
        if not (compDeployOrder is None):
            newComp.setDeploymentOrder(int(compDeployOrder))
        if not (compSecureModel is None):
            newComp.setSecurityDDModel(compSecureModel)
        if not (compStagingMode is None):
            newComp.setStagingMode(compStagingMode)

    # target resources from sub-templates
    jrf_targetCompsFromJRFSubTemplate('AppDeployment', jrfCompNames)            

def jrf_upgradeLibraries(jrfConfigXMLDom):
    adminServerName = get('AdminServerName') 

    i = 0
    tags = jrfConfigXMLDom.documentElement.getElementsByTagName('library')
    jrfCompNames =[]
    while i < tags.length:
        xmlElem = tags.item(i)
        i = i +1     
    
        compName = jrf_getSingleChildXMLElemValue(xmlElem, 'name')
        jrfCompNames.append(compName)            
        
        if jrf_isComponentInstalled('Library', compName):
            continue
        
        print "Create Library \"" + compName + "\""
                
        compTarget = jrf_getSingleChildXMLElemValue(xmlElem,'target')
        compModuleType = jrf_getSingleChildXMLElemValue(xmlElem,'module-type')
        compSourcePath = jrf_getSingleChildXMLElemValue(xmlElem,'source-path')
        compSourcePath = jrf_convertPath(compSourcePath)        
        compSecureModel = jrf_getSingleChildXMLElemValue(xmlElem,'security-dd-model')                
        compStagingMode = jrf_getSingleChildXMLElemValue(xmlElem,'staging-mode')   

        newComp = create(compName, 'Library')
        jrf_upgrade_assignTargets('Library', compName, compTarget)   
        if not (compModuleType is None):
            newComp.setModuleType(compModuleType)
        if not (compSourcePath is None):
            newComp.setSourcePath(compSourcePath)
        if not (compSecureModel is None):
            newComp.setSecurityDDModel(compSecureModel)
        if not (compStagingMode is None):
            newComp.setStagingMode(compStagingMode)
            
    # target resources from sub-templates
    jrf_targetCompsFromJRFSubTemplate('Library', jrfCompNames)   
    
    
def jrf_upgradeStartupClasses(jrfConfigXMLDom):
    adminServerName = get('AdminServerName') 
    
    i = 0
    tags = jrfConfigXMLDom.documentElement.getElementsByTagName('startup-class')
    jrfCompNames =[]
    while i < tags.length:
        xmlElem = tags.item(i)
        i = i +1      

        compName = jrf_getSingleChildXMLElemValue(xmlElem, 'name')
        jrfCompNames.append(compName)
        
        if jrf_isComponentInstalled('StartupClass', compName):
            continue
        
        print "Create StartupClass \"" + compName + "\""
                
        compTarget = jrf_getSingleChildXMLElemValue(xmlElem,'target')
        compDeployOrder = jrf_getSingleChildXMLElemValue(xmlElem,'deployment-order')
        compClassName = jrf_getSingleChildXMLElemValue(xmlElem,'class-name')
        compFailIsFatal = jrf_getSingleChildXMLElemValue(xmlElem,'failure-is-fatal')
        compLoadBeforeAppDep = jrf_getSingleChildXMLElemValue(xmlElem,'load-before-app-deployments')                
        compLoadBeforeAppActivate = jrf_getSingleChildXMLElemValue(xmlElem,'load-before-app-activation')   

        newComp = create(compName, 'StartupClass')
        jrf_upgrade_assignTargets('StartupClass', compName, compTarget)   
        if not (compDeployOrder is None):
            newComp.setDeploymentOrder(int(compDeployOrder))
        if not (compClassName is None):
            newComp.setClassName(compClassName)
        if not (compFailIsFatal is None):
            newComp.setFailureIsFatal(bool(compFailIsFatal))
        if not (compLoadBeforeAppDep is None):
            newComp.setLoadBeforeAppDeployments(bool(compLoadBeforeAppDep))
        if not (compLoadBeforeAppActivate is None):
            newComp.setLoadBeforeAppActivation(bool(compLoadBeforeAppActivate))
    
    # target resources from sub-templates
    jrf_targetCompsFromJRFSubTemplate('StartupClass', jrfCompNames)
    
                
def jrf_upgradeShutdownClasses(jrfConfigXMLDom):
    adminServerName = get('AdminServerName') 
    
    i = 0
    tags = jrfConfigXMLDom.documentElement.getElementsByTagName('shutdown-class')
    jrfCompNames =[]
    while i < tags.length:
        xmlElem = tags.item(i)
        i = i +1 
            
        compName = jrf_getSingleChildXMLElemValue(xmlElem, 'name')
        jrfCompNames.append(compName)
        
        if jrf_isComponentInstalled('ShutdownClass', compName):
            continue

        print "Create ShutdownClass \"" + compName + "\""          
        
        compTarget = jrf_getSingleChildXMLElemValue(xmlElem,'target')
        compDeployOrder = jrf_getSingleChildXMLElemValue(xmlElem,'deployment-order')
        compClassName = jrf_getSingleChildXMLElemValue(xmlElem,'class-name')

        newComp = create(compName, 'ShutdownClass')
        jrf_upgrade_assignTargets('ShutdownClass', compName, compTarget)   
        if not (compDeployOrder is None):
            newComp.setDeploymentOrder(int(compDeployOrder))
        if not (compClassName is None):
            newComp.setClassName(compClassName)
    
    # target resources from sub-templates
    jrf_targetCompsFromJRFSubTemplate('ShutdownClass', jrfCompNames)
                           
def jrf_upgrade_WLDFSystemResources(jrfConfigXMLDom):
    adminServerName = get('AdminServerName') 
    
    i = 0
    tags = jrfConfigXMLDom.documentElement.getElementsByTagName('wldf-system-resource')
    jrfCompNames =[]
    while i < tags.length:
        xmlElem = tags.item(i)
        i = i +1     

        compName = jrf_getSingleChildXMLElemValue(xmlElem, 'name')
        jrfCompNames.append(compName)
        
        if jrf_isComponentInstalled('WLDFSystemResource', compName):
            continue
        
        print "Create WLDFSystemResource \"" + compName + "\""
        
        compTarget = jrf_getSingleChildXMLElemValue(xmlElem,'target')
        compDescriptorFileName = jrf_getSingleChildXMLElemValue(xmlElem,'descriptor-file-name')
        compDeploymentPrincipalName = jrf_getSingleChildXMLElemValue(xmlElem,'deployment-principal-name')
        compDeployOrder = jrf_getSingleChildXMLElemValue(xmlElem,'deployment-order')
        compSourcePath = jrf_getSingleChildXMLElemValue(xmlElem,'source-path')
        compSourcePath = jrf_convertPath(compSourcePath)        
        compDescription = jrf_getSingleChildXMLElemValue(xmlElem,'description')

        newComp = create(compName, 'WLDFSystemResource')
        jrf_upgrade_assignTargets('WLDFSystemResource', compName, compTarget)   
        if not (compDescriptorFileName is None):
            newComp.setDescriptorFileName(compDescriptorFileName)
        if not (compDeploymentPrincipalName is None):
            newComp.setDeploymentPrincipalName(compDeploymentPrincipalName)      
        if not (compDeployOrder is None):
            newComp.setDeploymentOrder(int(compDeployOrder))                               
        if not (compSourcePath is None):
            newComp.setSourcePath(compSourcePath)            
        if not (compDescription is None):
            newComp.setDescription(compDescription)   
            
        # target resources from sub-templates
        jrf_targetCompsFromJRFSubTemplate('WLDFSystemResource', jrfCompNames)          
          
        
def jrf_upgradeSetDiagContextEnabled():
    for server in jrf_getJRFServerMBeans():
        serverName = server.getName()
        print "Set DiagnosticContextEnabled for server \"" + serverName + "\""
        jrf_setDiagContextEnabled(serverName, connected='false')
    cd('/')
       

def jrf_getCommonCompsHome():       
    jrfCommonCompsHome = retrieveObject("COMMON_COMPONENTS_HOME")
    if jrfCommonCompsHome is None:
        raise WLSTException(jrf_getI18nMessage(oracle.jrf.i18n.JRFMessageID.ENV_NOT_SET, ["COMMON_COMPONENTS_HOME"]))
               
    return jrfCommonCompsHome
    
def jrf_convertPath(aPath):
    if aPath is None:
        return None
    return aPath.replace('$ORACLE_HOME$', '$COMMON_COMPONENTS_HOME$')
   
    
def jrf_upgradeConfigFiles(domainPath):    
    # delete  server-config-template dir, so that it will be recreated with up-to-date files later
    oracle.jrf.InternalJrfUtils.delete(java.io.File(domainPath, 'config/fmwconfig/server-config-template'))
    
    # copy server-scoped config files from server-config-template that will be recreated if not exist implicitly
    for jrfServer in jrf_getJRFServerMBeans():
        jrf_copyConfigs(jrfServer.getName(), domainPath)    
            
def jrf_isComponentInstalled(compType, compName):
    return jrf_getMBean(compType, compName) != None
    
def jrf_isJRFInstalled():
    return jrf_isComponentInstalled('StartupClass', 'JRF Startup Class')
    
def jrf_isJRFUpToDate():
    # check if all jrf components of the current version that are used by applyJRF are installed
    jrfConfigResources = jrf_getConfigResources()
    jrfComponents = jrfConfigResources[0]
    jrfAdminSrvOnlyComps = jrfConfigResources[1]
    
    for component in jrfComponents:
        if not jrf_isComponentInstalled(component[0], component[1]):
            return 0
  
    for component in jrfAdminSrvOnlyComps:
        if not jrf_isComponentInstalled(component[0], component[1]):
            return 0
                            
    return 1
              

# get mbean of a JRF supported type
def jrf_getMBean(compType, compName):
    _typeToAttributeMap = {'AppDeployment':'AppDeployments', 'Library':'Libraries', 'StartupClass':'StartupClasses','ShutdownClass':'ShutdownClasses', 'WLDFSystemResource':'WLDFSystemResources'}
    compsAttribute = _typeToAttributeMap[compType]    
    cd('/') 
    for comp in get(compsAttribute):
        if compName == comp.getName():
            return comp
    return None                

def jrf_getXmlDoccument(inStream):
    dbf = javax.xml.parsers.DocumentBuilderFactory.newInstance()
    dbf.setValidating(0)
    dbf.setNamespaceAware(0)

    db = dbf.newDocumentBuilder()
    xmlDom  = db.parse(inStream)       
    inStream.close()
    
    return xmlDom  
                
def jrf_upgrade_assignTargets(sourceType, sourceName,  xmlTarget):
    cd('/')
    adminServerName = get('AdminServerName') 
    for jrfTarget in jrf_getJRFTargetMBeans(): 
        if jrfTarget.getName() != adminServerName and xmlTarget == '%AdminServer%':
            continue

        print "Target " + sourceType + " \"" + sourceName + "\" to JRF \"" + jrfTarget.getName() + "\""
        unassign(sourceType, sourceName, 'Target', jrfTarget.getName())   
        assign(sourceType, sourceName, 'Target', jrfTarget.getName())   

def jrf_targetCompsFromJRFSubTemplate(compType, jrfCompNames):    
    jrfConfigResources = jrf_getConfigResources()
    jrfComponents = jrfConfigResources[0]
    jrfAdminSrvOnlyComps = jrfConfigResources[1]
    
    # obtain list of components sub-templates = list from applyJRF command - list from config.xml of jrf template
    jrfSubTemplateComps = []
    for component in jrfComponents:
        if compType == component[0]:
            matchJRFTemplateComp = 0
            for jrfCompName in jrfCompNames:
                if jrfCompName == component[1]:
                    matchJRFTemplateComp = 1
                    break
            if not matchJRFTemplateComp:
                jrfSubTemplateComps.append([component[0], component[1], None])                    
    for component in jrfAdminSrvOnlyComps:
        if compType == component[0]:
            matchJRFTemplateComp = 0
            for jrfCompName in jrfCompNames:
                if jrfCompName == component[1]:
                    matchJRFTemplateComp = 1
                    break
            if not matchJRFTemplateComp:
                jrfSubTemplateComps.append([component[0], component[1], '%AdminServer%'])
                
    if len(jrfSubTemplateComps) > 0:
        print "Target " + compType + " instances from sub-templates:"    
        for subComp in jrfSubTemplateComps:
            jrf_upgrade_assignTargets(subComp[0], subComp[1], subComp[2])   
                                            
                                                               
# return array of all jrf servers and/or clusters
def jrf_getJRFTargetMBeans():
    return jrf_getMBean('StartupClass', 'JRF Startup Class').getTargets()
    
# return list of jrf standalone and/or clustered servers    
def jrf_getJRFServerMBeans():
    jrfServerBeans = []
    cd('/')
    for jrfTargetBean in jrf_getJRFTargetMBeans():  
        jrfTargetName = jrfTargetBean.getName()  
        for server in cmo.getServers():
            srvCluster = server.getCluster()
            if jrfTargetName == server.getName() or (srvCluster !=  None and  srvCluster.getName() == jrfTargetName):
                jrfServerBeans.append(server)
    return jrfServerBeans
        
def jrf_getSingleChildXMLElemValue(parentElem, childTag):
    childElems = parentElem.getElementsByTagName(childTag)
    if childElems != None and childElems.getLength() > 0:
        return childElems.item(0).getFirstChild().getNodeValue()
    return None

def jrf_getConfigResources():
    jrfComponents = []
    jrfAdminSrvOnlyComps = []     

    # Generated from JRF template: jrf_template_11.1.1.jar
    jrfAdminSrvOnlyComps.append(['AppDeployment', 'FMW Welcome Page Application#11.1.0.0.0'])
    jrfComponents.append(['AppDeployment', 'DMS Application#11.1.1.1.0'])
    jrfComponents.append(['AppDeployment', 'wsil-wls'])

    jrfComponents.append(['Library', 'oracle.wsm.seedpolicies#11.1.1@11.1.1'])
    jrfComponents.append(['Library', 'oracle.jsp.next#11.1.1@11.1.1'])
    jrfComponents.append(['Library', 'oracle.dconfig-infra#11@11.1.1.1.0'])
    jrfComponents.append(['Library', 'orai18n-adf#11@11.1.1.1.0'])
    jrfComponents.append(['Library', 'oracle.adf.dconfigbeans#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'oracle.pwdgen#11.1.1@11.1.1.2.0'])
    jrfComponents.append(['Library', 'oracle.jrf.system.filter'])
    jrfComponents.append(['Library', 'adf.oracle.domain#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'adf.oracle.businesseditor#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'oracle.adf.management#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'adf.oracle.domain.webapp#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'jsf#1.2@1.2.9.0'])
    jrfComponents.append(['Library', 'jstl#1.2@1.2.0.1'])
    jrfComponents.append(['Library', 'UIX#11@11.1.1.1.0'])
    jrfComponents.append(['Library', 'ohw-rcf#5@5.0'])
    jrfComponents.append(['Library', 'ohw-uix#5@5.0'])
    jrfComponents.append(['Library', 'oracle.adf.desktopintegration.model#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'oracle.adf.desktopintegration#1.0@11.1.1.2.0'])

    jrfComponents.append(['ShutdownClass', 'JOC-Shutdown'])
    jrfComponents.append(['ShutdownClass', 'DMSShutdown'])

    jrfComponents.append(['StartupClass', 'JRF Startup Class'])
    jrfComponents.append(['StartupClass', 'JPS Startup Class'])
    jrfComponents.append(['StartupClass', 'ODL-Startup'])
    jrfComponents.append(['StartupClass', 'AWT Application Context Startup Class'])
    jrfComponents.append(['StartupClass', 'JMX Framework Startup Class'])
    jrfComponents.append(['StartupClass', 'Web Services Startup Class'])
    jrfComponents.append(['StartupClass', 'JOC-Startup'])
    jrfComponents.append(['StartupClass', 'DMS-Startup'])

    jrfComponents.append(['WLDFSystemResource', 'Module-FMWDFW'])

    # Generated from JRF dependent template: oracle.biadf_template_11.1.1.jar

    jrfComponents.append(['Library', 'oracle.bi.adf.model.slib#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'oracle.bi.adf.view.slib#1.0@11.1.1.2.0'])
    jrfComponents.append(['Library', 'oracle.bi.adf.webcenter.slib#1.0@11.1.1.2.0'])




    # Generated from JRF dependent template: oracle.bicomposer.slib.stub_template_11.1.1.jar

    jrfComponents.append(['Library', 'oracle.bi.jbips#11.1.1@0.1'])
    jrfComponents.append(['Library', 'oracle.bi.composer#11.1.1@0.1'])



    return [jrfComponents, jrfAdminSrvOnlyComps]