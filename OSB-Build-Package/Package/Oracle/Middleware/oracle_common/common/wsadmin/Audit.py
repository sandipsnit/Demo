################################################################
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

import Audit_Handler as handler
from java.util import HashMap
import ora_mbs
import OracleHelp

#######################################################
# This function adds command help
# (Internal function)
#######################################################

def addAuditCommandHelp():

    handler.addAuditCommanHelp();

#######################################################
# This function gets the audit policy settings
#######################################################

def getAuditPolicy(componentType = None, on = None):
    m = HashMap()
    m.put("componentType", componentType)
    if (on == None):
       on = getCompleteMBeanName()
    handler.getAuditPolicy(m, on)

#######################################################
# This function gets the audit repository settings
#######################################################

def getAuditRepository(on = None):
    if (on == None):
       on = getCompleteMBeanName()
    handler.getAuditRepository(on)

#######################################################
# This function sets the audit policy settings
#######################################################

def setAuditPolicy(on = None, componentType = None, filterPreset = None,addSpecialUsers = None,removeSpecialUsers = None,addCustomEvents = None,removeCustomEvents = None,maxDirSize = None,maxFileSize = None, andCriteria = None, orCriteria = None, componentEventsFile = None):
    from java.util import ArrayList
    from java.util import Set

    m = HashMap();
    m.put("componentType", componentType);
    m.put("audit.filterPreset", filterPreset)
    m.put("addSpecialUsers", addSpecialUsers)
    m.put("removeSpecialUsers", removeSpecialUsers)
    m.put("addCustomEvents", addCustomEvents)
    m.put("removeCustomEvents", removeCustomEvents)
    m.put("audit.maxDirSize", maxDirSize)
    m.put("audit.maxFileSize", maxFileSize)
    m.put("andCriteria", andCriteria)
    m.put("orCriteria", orCriteria)
    m.put("componentEventsFile", componentEventsFile)
    rmArgs = ArrayList()
    for k in m.keySet():
        if (m.get(k) is None) :
            rmArgs.add(k)
    for i in range(len(rmArgs)) :
        m.remove(rmArgs[i])

    if (on == None):
       on = getCompleteMBeanName()
    handler.setAuditPolicy(m, on)
    
#######################################################
# This function sets the audit repository settings
#######################################################

def setAuditRepository(on = None, switchToDB = None,dataSourceName = None,interval = None):
    m = HashMap()
    m.put("switchToDB", switchToDB)
    m.put("dataSourceName", dataSourceName)
    m.put("interval", interval)
    if (on == None):
       on = getCompleteMBeanName()
    handler.setAuditRepository(m, on)

###########################################################
# This function lists the audit events of a given component
###########################################################

def listAuditEvents(on = None, componentType = None):
    m = HashMap()
    m.put("componentType", componentType)
    if (on == None):
       on = getCompleteMBeanName()
    handler.listAuditEvents(m, on)

def exportAuditConfig(on = None, fileName = None, componentType = None):
    m = HashMap()
    m.put("fileName", fileName)
    m.put("componentType", componentType);
    if (on == None):
       on = getCompleteMBeanName()
    handler.exportAuditConfig(m, on)

def importAuditConfig(on = None, fileName = None, componentType = None):
    m = HashMap()
    m.put("fileName", fileName)
    m.put("componentType", componentType);
    if (on == None):
       on = getCompleteMBeanName()
    handler.importAuditConfig(m, on)

def getNonJavaEEAuditMBeanName(instName=None, compName=None, compType=None):
    if (compType == 'ovd'):
       str = String("oracle.as." + compType + ":type=component.auditconfig,name=auditconfig,instance=" + instName + ",component=" + compName)
    if (compType == 'oid'):
       str = String("oracle.as.management.mbeans.register:type=component.auditconfig,name=auditconfig1,instance=" + instName + ",component=" + compName)
    if (compType == 'WebCache'):
       str = String("oracle.as.management.mbeans:name=WebCacheAuditConfig,componentname=" + compName + ",instancename=" + instName + ",type=" + compType)
    if (compType == 'ohs'):
       str = String("oracle.as.management.mbeans.register:type=component,name=" + compName +",instance=" + instName +",child=AuditMBean,childtype=AuditProxy")
    return str

def help(topic = None):
  m_name = 'audit'
  if topic == None:
    topic = m_name
  else:
    topic = m_name + '.' + topic
  return OracleHelp.help(topic)

def getCompleteMBeanName():
    if(ora_mbs.isWebSphereND() == 1):
       on= AdminControl.completeObjectName('com.oracle.jps:type=JpsConfig,process=dmgr,*')
    else:
       on= AdminControl.completeObjectName('com.oracle.jps:type=JpsConfig,*')
    return on

def upgradeAuditDefinition(source = None, target = None, version = None):
    from java.util import HashMap
    m = HashMap()
    m.put("source", source);
    m.put("target", target);
    m.put("version", version);
    handler.upgradeAuditDefinitionImpl(m)

def createAuditDBView(on = None, fileName = None, componentType = None):
    m = HashMap()
    m.put("fileName", fileName)
    m.put("componentType", componentType);
    if (on == None):
       on = getCompleteMBeanName()
    handler.createAuditDBView(m, on)

def listAuditComponents(on = None, fileName = None):
    m = HashMap()
    m.put("fileName", fileName)
    if (on == None):
       on = getCompleteMBeanName()
    handler.listAuditComponents(m, on)

def registerAudit(on = None, xmlFile = None, xlfFile = None, componentType = None, mode = None):
    m = HashMap()
    m.put("xmlFile", xmlFile)
    m.put("xlfFile", xlfFile)
    m.put("componentType", componentType);
    m.put("mode", mode);
    if (on == None):
       on = getCompleteMBeanName()
    handler.registerAudit(m, on)

def deregisterAudit(on = None, componentType = None):
    m = HashMap()
    m.put("componentType", componentType);
    if (on == None):
       on = getCompleteMBeanName()
    handler.deregisterAudit(m, on)

handler.addAuditCommandHelp()
