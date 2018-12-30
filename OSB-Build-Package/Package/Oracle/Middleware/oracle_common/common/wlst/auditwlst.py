################################################################
# Caution: This file is part of the WLST implementation. 
# Do not edit or move this file because this may cause 
# WLST commands and scripts to fail. Do not try to reuse 
# the logic in this file or keep copies of this file because 
# this could cause your WLST scripts to fail when you 
# upgrade to a different version of WLST. 
#
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

from javax.management import RuntimeMBeanException
from java.util import ResourceBundle
from java.util import Locale
from java.io import FileInputStream
from java.io import File
import jarray

#######################################################
# This function adds command help
# (Internal function)
#######################################################

def addAuditCommandHelp():
  try:
    addHelpCommandGroup("audit","audit_wlst")
    addHelpCommand("getAuditPolicy","audit")
    addHelpCommand("setAuditPolicy","audit")
    addHelpCommand("getAuditRepository","audit")
    addHelpCommand("setAuditRepository","audit")
    addHelpCommand("listAuditEvents","audit")
    addHelpCommand("importAuditConfig","audit")
    addHelpCommand("exportAuditConfig","audit")
    addHelpCommand("getNonJavaEEAuditMBeanName", "audit")
    addHelpCommand("upgradeAuditDefinition", "audit")
    addHelpCommand("createAuditDBView", "audit")
    addHelpCommand("listAuditComponents", "audit")
    addHelpCommand("registerAudit", "audit")
    addHelpCommand("deregisterAudit", "audit")
  except Exception, e:
    return

mAuditResourceBundle = ResourceBundle.getBundle("oracle.security.audit.mesg.AuditMBeanResource")

#######################################################
# This function gets the audit policy settings
#######################################################

def getAuditPolicy(componentType = None, on="com.oracle.jps:type=JpsConfig"):
    config = None    
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params = [componentType]
          sign = ["java.lang.String"]
          config = mbs.invoke(obn, "wlstAuditConfig", params, sign)
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

    if config != None:
       print config
    else:
       msg = mAuditResourceBundle.getString("MSG_WLST_CONFIG_NOT_FOUND")
       print msg

#######################################################
# This function gets the audit repository settings
#######################################################

def getAuditRepository(on="com.oracle.jps:type=JpsConfig"):
    config = None
    
    try:
       if (connected == 'true'):
         location = currentTree()
         if (on == "com.oracle.jps:type=JpsConfig"):
           domainRuntime()
         else:
           serverRuntime()
         obn = ObjectName(on)
         config = mbs.invoke(obn,"wlstAuditLoaderConfig",None,None)
         location()
       else:
         msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
         print msg
    except RuntimeMBeanException, e:
       location()
       msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
       print msg + e.getMessage() + "\n"
    except :
       msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
       print msg
       raise

    if config != None:
       print config
    else:
       msg = mAuditResourceBundle.getString("MSG_WLST_CONFIG_NOT_FOUND")
       print msg

#######################################################
# This function sets the audit policy settings
#######################################################
def setAuditPolicy(on="com.oracle.jps:type=JpsConfig", componentType = None, filterPreset = None,addSpecialUsers = None,removeSpecialUsers = None,addCustomEvents = None,removeCustomEvents = None,maxDirSize = None,maxFileSize = None, andCriteria = None, orCriteria = None, componentEventsFile = None):
    from java.util import HashMap
    from java.util import ArrayList
    from java.util import Set

    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap
    m = HashMap()
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
    
    pm = PortableMap(m)
    retval = None
    
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params = [componentType, pm.toCompositeData(None)]
          sign = ["java.lang.String", "javax.management.openmbean.CompositeData"]
          retval = mbs.invoke(obn, "wlstUpdateAuditPolicy", params, sign)
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

    if retval != None:
        print retval
        msg = mAuditResourceBundle.getString("MSG_WLST_SERVER_RESTART")
        print msg
    
#######################################################
# This function sets the audit repository settings
#######################################################

def setAuditRepository(on="com.oracle.jps:type=JpsConfig",switchToDB = None,dataSourceName = None,interval = None):
    retval = None
    
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params =[switchToDB,dataSourceName,interval]
          sign = ["java.lang.String", "java.lang.String", "java.lang.String"]
          retval = mbs.invoke(obn,"wlstUpdateAuditRepository",params,sign) 
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

    if retval != None:
        print retval
	if (retval.find("Audit Repository Information updated") != -1):
        	msg = mAuditResourceBundle.getString("MSG_WLST_SERVER_RESTART")
        	print msg

###########################################################
# This function lists the audit events of a given component
###########################################################

def listAuditEvents(componentType = None, on="com.oracle.jps:type=JpsConfig"):
    events = None
    
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params = [componentType]
          sign = ["java.lang.String"]
          events = mbs.invoke(obn, "wlstAuditEvents", params, sign)
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

    if events != None:
        print events
    else:
        msg = mAuditResourceBundle.getString("MSG_WLST_EVENTS_NOT_FOUND")
        print msg

def exportAuditConfig(fileName = None, componentType = None, on="com.oracle.jps:type=JpsConfig"):
    audconfig = None
    
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params = [componentType]
          sign = ["java.lang.String"]
          audconfig = mbs.invoke(obn, "wlstExportAuditConfig", params, sign)
          location()
          f = open(fileName,'w')
          f.write(audconfig)
          f.close()
          if audconfig != None:
            print audconfig
          else:
            msg = mAuditResourceBundle.getString("MSG_WLST_CONFIG_NOT_FOUND")
            print msg
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except IOError:
        msg = mAuditResourceBundle.getString("MSG_WLST_CANT_OPEN")
        print msg + fileName
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

def importAuditConfig(fileName = None, componentType = None, on="com.oracle.jps:type=JpsConfig"):
    audconfig = None
    
    retval = None
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          f = open(fileName,'r')
          audconfig = f.read()
          f.close()
          params = [audconfig, componentType]
          sign = ["java.lang.String", "java.lang.String"]
          retval = mbs.invoke(obn,"wlstImportAuditConfig",params,sign)
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except IOError:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_CANT_OPEN")
        print msg + fileName
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

    if retval != None:
      print retval

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

def upgradeAuditDefinition(source = None, target = None, version = None):
    from java.util import HashMap
    m = HashMap()
    m.put("source", source);
    m.put("target", target);
    m.put("version", version);
    upgradeAuditDefinitionImpl(m)

def upgradeAuditDefinitionImpl(m):
    from oracle.security.audit.tools import AuditSchemaUpgradeTool
    from oracle.security.audit import AuditException
    try:
        AuditSchemaUpgradeTool.upgrade(m)
    except AuditException, e:
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
        raise e

def createAuditDBView(fileName = None, componentType = None, on="com.oracle.jps:type=JpsConfig"):
    mapping = None

    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params = [componentType]
          sign = ["java.lang.String"]
          mapping = mbs.invoke(obn, "createAuditDBView", params, sign)
          location()
          f = open(fileName,'w')
          f.write(mapping)
          f.close()
          if mapping != None:
            print mapping 
          else:
            msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
            print msg
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except IOError:
        msg = mAuditResourceBundle.getString("MSG_WLST_CANT_OPEN")
        print msg + fileName
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

def listAuditComponents(fileName = None, on="com.oracle.jps:type=JpsConfig"):
    compList = None

    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          compList = mbs.invoke(obn, "listAuditComponents", None, None)
          location()
          f = open(fileName,'w')
          f.write(compList)
          f.close()
          if compList != None:
            print compList 
          else:
            msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
            print msg
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise

def getByteArray(fileUrl):
  file = File(fileUrl);
  inputStream = FileInputStream(file)
  length = file.length()
  bytes = jarray.zeros(length, 'b')
  #Read in the bytes
  offset = 0
  numRead = 0
  while offset<length:
      if numRead>= 0:
          numRead=inputStream.read(bytes, offset, length-offset)
          offset = offset + numRead
  return bytes

def registerAudit(xmlFile = None, xlfFile = None, componentType = None, mode = None, on="com.oracle.jps:type=JpsConfig"):
    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          byteXml = None
          byteXlf = None

          if xmlFile != None:
             byteXml = getByteArray(xmlFile);
          if xlfFile != None:
             byteXlf = getByteArray(xlfFile);
          params = [byteXml, byteXlf, componentType, mode]
          sign = ["[B", "[B", "java.lang.String", "java.lang.String"]
          mbs.invoke(obn,"registerAudit", params, sign)
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except IOError:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_CANT_OPEN")
        print msg + fileName
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")

        print msg
        raise

def deregisterAudit(componentType = None, on="com.oracle.jps:type=JpsConfig"):

    try:
        if (connected == 'true'):
          location = currentTree()
          if (on == "com.oracle.jps:type=JpsConfig"):
            domainRuntime()
          else:
            serverRuntime()
          obn = ObjectName(on)
          params = [componentType]
          sign = ["java.lang.String"]
          mbs.invoke(obn,"deregisterAudit", params, sign)
          location()
        else:
          msg = mAuditResourceBundle.getString("MSG_WLST_CONNECT")
          print msg
    except RuntimeMBeanException, e:
        location()
        msg = mAuditResourceBundle.getString("MSG_WLST_COMMAND_FAILED")
        print msg + e.getMessage() + "\n"
    except :
        msg = mAuditResourceBundle.getString("MSG_WLST_UNKNOWN_REASON")
        print msg
        raise


addAuditCommandHelp()
