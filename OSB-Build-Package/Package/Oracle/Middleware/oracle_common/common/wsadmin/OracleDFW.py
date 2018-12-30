"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the wsadmin/jboss implementation. Do not edit or 
move this file because this may cause wsadmin/jboss commands and scripts to 
fail. Do not try to reuse the logic in this file or keep copies of this file 
because this could cause your wsadmin/jboss scripts to fail when you upgrade 
to a different version of wsadmin/jboss.

Oracle Fusion Middleware logging commands.

"""

import cie.OracleHelp as OracleHelp
import jarray
import os
import sys
import java.lang
import ora_mbs
import ora_help
from java.lang import Class
from java.lang import String
from java.lang import StringBuffer
from java.util import Locale
from java.util import ResourceBundle
from javax.management import ObjectName
from javax.management import MBeanServerInvocationHandler
from javax.management import MBeanServerConnection
from javax.management import InstanceNotFoundException

ORACLEADMINSERVER = "OracleAdminServer"
DEPLOYMENTMANAGER = "dmgr"

JBOSS_SERVER = "jrfServer"

# mbean objectNames
WAS_SERVER  = "WebSphere:type=Server,processType=DeploymentManager,*"
WAS_MANAGED = "WebSphere:type=Server,processType=ManagedProcess,*"
WAS_OAS     = "WebSphere:type=Server,processType=ManagedProcess,process=OracleAdminServer,*"
    
MSGFILE     = "oracle.as.management.logging.messages.CommandHelp"

#replacement strings
F_ADMINSERVER = "AdminServer" 
R_ADMINSERVER = "DeploymentManager"
R_PREFIX      = "print OracleDFW."

errStr = ""
"""
listADRHomes command
"""
def listADRHomes(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr = _setMBeanServer(handler.INCIDENT_MANAGER, server)

    ret = handler.listADRHomes(_MBS(), mbeanStr, **kws)
    print handler.formatListADRHomes(ret)
    _hideDisplay()
    return ret
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except: 
    _printError(server)


"""
listProblems command
"""
def listProblems(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    mbeanStr = _setMBeanServer(handler.INCIDENT_MANAGER, server)

    problems =  handler.listProblems(_MBS(), mbeanStr, **kws)
    print handler.formatListProblems(problems)
    _hideDisplay()
    return problems
  except DfwError, ex:
    print ex.getMsg()
  except Exception, ex:
    print ex
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)

"""
listIncidents command
"""
def listIncidents(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr = _setMBeanServer(handler.INCIDENT_MANAGER, server)

    incidents =  handler.listIncidents(_MBS(), mbeanStr, **kws)
    print handler.formatListIncidents(incidents)
    _hideDisplay()
    return incidents
  except DfwError, ex:
    print ex.getMsg()
  except Exception, ex:
    print ex
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)


"""
showIncident command
"""
def showIncident(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    mbeanStr = _setMBeanServer(handler.INCIDENT_MANAGER, server)

    incident =  handler.showIncident(_MBS(), mbeanStr, **kws)
    print handler.formatShowIncident(incident)
    _hideDisplay()
    return incident
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)


"""
createIncident command
"""
def createIncident(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)
  try:
    mbeanStr = _setMBeanServer(handler.INCIDENT_MANAGER, server)

    incident = handler.createIncident(_MBS(), mbeanStr, **kws)
    print handler.formatCreateIncident(incident)
    _hideDisplay()
    return incident
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)


"""
getIncidentFile command
"""
def getIncidentFile(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr  = _setMBeanServer(handler.INCIDENT_MANAGER, server)
    streamStr = _setMBeanServer(handler.STREAMER, server)

    incident =  handler.getIncidentFile(_MBS(), mbeanStr, streamStr, **kws)
    print handler.formatGetIncidentFile(incident)
    _hideDisplay()
    return incident
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)


"""
reloadCustomRules command
"""
def reloadCustomRules(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr  = _setMBeanServer(handler.INCIDENT_MANAGER, server)
    result = handler.reloadCustomRules(_MBS(), mbeanStr, **kws)
    print handler.formatReloadCustomRulesResult(result)
    _hideDisplay()
    return result
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, nex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)

"""
listDumps command
"""
def listDumps(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr = _setMBeanServer(handler.DUMP_MANAGER, server)

    dumps =  handler.listDumps(_MBS(), mbeanStr, **kws)
    print handler.formatListDumps(dumps)
    _hideDisplay()
    return dumps
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)


"""
describeDump Command
"""
def describeDump(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print GetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr = _setMBeanServer(handler.DUMP_MANAGER, server)

    dump = handler.describeDump(_MBS(), mbeanStr, **kws)
    print handler.formatDescribeDump(dump)
    _hideDisplay()
    return dump
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)


"""
executeDump command
"""
def executeDump(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server = kws.get(handler.SERVER)

  try:
    mbeanStr  = _setMBeanServer(handler.DUMP_MANAGER, server)
    streamStr = _setMBeanServer(handler.STREAMER, server)

    dump = handler.executeDump(_MBS(), mbeanStr, streamStr, **kws)
    print handler.formatExecuteDump(dump)
    _hideDisplay()
    return dump
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  except:
    _printError(server)

def help(cmd=None):
    _module = "OracleDFW"
    if cmd == None:
        cmd = _module
    else:
        cmd = _module + '.' + cmd
    return OracleHelp.help(cmd)

"""
isDumpSamplingEnabled command
"""
def isDumpSamplingEnabled(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    wasHandler = Oracle_WAS_dfw()
    wasHandler._oracledfwVerifyConnect()
    serverName = wasHandler.oracledfwResolveServerName(server)
    mbeanStr = wasHandler.oracledfwGetConfigObjName(serverName, handler.DIAGNOSTICS_CONFIG)
    ret =  handler.isDumpSamplingEnabled(_MBS(), mbeanStr, **kws)
    print ret
    _hideDisplay()
    return ret 
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
enableDumpSampling command
"""
def enableDumpSampling(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    wasHandler = Oracle_WAS_dfw()
    wasHandler._oracledfwVerifyConnect()
    serverName = wasHandler.oracledfwResolveServerName(server)
    mbeanStr = wasHandler.oracledfwGetConfigObjName(serverName, handler.DIAGNOSTICS_CONFIG)
    result =  handler.enableDumpSampling(_MBS(), mbeanStr, **kws)
    print result
    _hideDisplay()
    return result 
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
addDumpSample command
"""
def addDumpSample(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    wasHandler = Oracle_WAS_dfw()
    wasHandler._oracledfwVerifyConnect()
    serverName = wasHandler.oracledfwResolveServerName(server)
    mbeanStr = wasHandler.oracledfwGetConfigObjName(serverName, handler.DIAGNOSTICS_CONFIG)
    result =  handler.addDumpSample(_MBS(), mbeanStr, **kws)
    print result
    _hideDisplay()
    return result
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
updateDumpSample command
"""
def updateDumpSample(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    wasHandler = Oracle_WAS_dfw()
    wasHandler._oracledfwVerifyConnect()
    serverName = wasHandler.oracledfwResolveServerName(server)
    mbeanStr = wasHandler.oracledfwGetConfigObjName(serverName, handler.DIAGNOSTICS_CONFIG)
    result =  handler.updateDumpSample(_MBS(), mbeanStr, **kws)
    print result
    _hideDisplay()
    return result
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
removeDumpSample command
"""
def removeDumpSample(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    wasHandler = Oracle_WAS_dfw()
    wasHandler._oracledfwVerifyConnect()
    serverName = wasHandler.oracledfwResolveServerName(server)
    mbeanStr = wasHandler.oracledfwGetConfigObjName(serverName, handler.DIAGNOSTICS_CONFIG)
    result =  handler.removeDumpSample(_MBS(), mbeanStr, **kws)
    print result
    _hideDisplay()
    return result
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
listDumpSamples command
"""
def listDumpSamples(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    wasHandler = Oracle_WAS_dfw()
    wasHandler._oracledfwVerifyConnect()
    serverName = wasHandler.oracledfwResolveServerName(server)
    mbeanStr = wasHandler.oracledfwGetConfigObjName(serverName, handler.DIAGNOSTICS_CONFIG)
    result =  handler.listDumpSamples(_MBS(), mbeanStr, **kws)
    print result
    _hideDisplay()
    return result
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
getSamplingArchives command
"""
def getSamplingArchives(**kws):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if not _isConnected():
    print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
    return

  server   = kws.get(handler.SERVER)
  try:
    mbeanStr  = _setMBeanServer(handler.DUMP_MANAGER, server)
    streamStr = _setMBeanServer(handler.STREAMER, server)

    result =  handler.getSamplingArchives(_MBS(), mbeanStr, streamStr, **kws)
    print result
    _hideDisplay()
    return result
  except DfwError, ex:
    print ex.getMsg()
  except InstanceNotFoundException, ex:
    print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  except:
    _printError(server)

"""
Private methods
=======================================================================
"""

# verify wsadmin/ojbst is connected to the server
def _isConnected():
  return ora_mbs.isConnected()

def _setMBeanServer(baseStr, server):
  if ora_mbs.isWebSphereND():
    return _setMBeanServer_WAS(baseStr, server)
  elif ora_mbs.isWebSphereAS():
    return _setMBeanServer_WAS(baseStr, server)
  elif ora_mbs.isJBoss():
    return _setMBeanServer_JBOSS(baseStr, server)
  return None



def _setMBeanServer_WAS(baseStr, server):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  global errStr

  dmgr    = AdminControl.completeObjectName(WAS_SERVER)
  process = ObjectName(dmgr).getKeyProperty("name")

  if process is None:
    dmgr    = AdminControl.completeObjectName(WAS_MANAGED)
    process = ObjectName(dmgr).getKeyProperty("name")

  if process == DEPLOYMENTMANAGER:
    oas    = AdminControl.completeObjectName(WAS_OAS)
    oasProc = ObjectName(oas).getKeyProperty("name")
    if oasProc is None:
      handler = Oracle_dfw_handler()
      raise DfwError, handler.oraDfwGetMsg(handler.OAS_NOT_UP, None)
    if server is None:
      process = ORACLEADMINSERVER
    else:
      process = server
  else:
    # if this isn't dmgr and the server name is not this server return error
    if server is not None and server != process:
      handler = Oracle_dfw_handler()
      raise DfwError,  _strFilter(handler.oraDfwGetMsg(handler.WRONG_SERVER))
      return

  # WAS AS edition is a single process, and so there is no process in the
  # string
  if process is None:
    queryName = baseStr + ",*"
  else:
    queryName = baseStr +  ",process=" + process +",*"

  objStr = AdminControl.queryNames(queryName)

  return objStr

def _setMBeanServer_JBOSS(baseStr, server):
  #print ora_mbs.queryNames(ObjectName("*:*"), None)
  if server is None:
    x =  ora_mbs.queryNames(ObjectName(baseStr), None).toArray()
    if len(x) == 0:
      return baseStr + ",ServerName=" + JBOSS_SERVER
    else:
      return baseStr
  else:
    str = baseStr + ",ServerName=" + server
    if server == JBOSS_SERVER:
      x =  ora_mbs.queryNames(ObjectName(str), None).toArray()
      if len(x) == 0:
        return baseStr
    return str;

def _printError(server):
  from Oracle_dfw_handler import Oracle_dfw_handler
  from Oracle_dfw_handler import DfwError

  handler = Oracle_dfw_handler()
  if str(sys.exc_info()[1]).find('InstanceNotFoundException') > -1: 
    if server is None:
      server = ORACLEADMINSERVER
    print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server) 
  else: 
    print str(sys.exc_info()[1])[41:] 

def _strFilter(str, cmd = None):
  str = str.replace(F_ADMINSERVER, R_ADMINSERVER)

  if cmd is not None:
    rStr = R_PREFIX + cmd
    str = str.replace(cmd, rStr)

  return str

def _eatDisplay(dummy):
    sys.displayhook = saved_displayhook

def _hideDisplay():
    global saved_displayhook
    saved_displayhook = sys.displayhook
    sys.displayhook = _eatDisplay

"""
Provides a MBeanServerConnection interface around ora_mbs object.
This class DOES NOT implement all MBeanServerConnection methods. An
exception will be thrown if a non-implemented method is invoked.
This was borrowed from OracleODL.py
"""
class _MBS(MBeanServerConnection):

    def getAttribute(self, name, attr):
        return ora_mbs.getAttribute(name, attr)

    def getAttributes(self, name, attrs):
        return ora_mbs.getAttributes(name, attrs)

    def invoke(self, name, operationName, params, signature):
        return ora_mbs.invoke(name, operationName, params, signature)

    def isRegistered(self, name):
        return ora_mbs.isRegistered(name)

    def queryNames(self, name, query):
        return ora_mbs.queryNames(name, query)

    def setAttribute(self, name, attr):
        return ora_mbs.setAttribute(name, attr)

    def setAttributes(self, name, attrs):
        return ora_mbs.setAttributes(name, attrs)

    def getMBeanInfo(self, name):
        return ora_mbs.getMBeanInfo(name)

"""
This class is copied from OracleDMS.py. These additional logic is for
supporting ConfigMBean which reqires connection to the domain MBean for R/W
operations.
"""
class Oracle_WAS_dfw:

   #
   # Initialize the instance of Oracle_dfw to use the functions relevant to the
   # environment in which it is running, and if the environment isn't supported
   # then raise an error saying as much!
   #

   def __init__(self):

     # For some environments and types of mbean there is a common
     # patten that can be applied to a server-independent mbean name
     # that will result in a server-specific mbean nmae. In order to
     # apply that basic pattern it is only required to list the
     # properties of the mbean name, that when given the value of 
     # the name of the server of interest, and applied to the
     # server-independent mbean name, yield a server-specific mbean name.
     # Those properties are listed in:
     #   mConfigMBeanNameDiscriminatingProperties
     #   mRuntimeMBeanNameDiscriminatingProperties
     # This pattern is not globally applicable, hence some further
     # specialization is implemented where necessary.

     if ora_mbs.isWebSphereND():
         # The rules for composing mbean names (runtime and config) are a tad
         # more complex than for WebSphereAS, and do not conform to the
         # abstract pattern used by the other server types, so we override
         # these methods with specialization.
         self.oracledfwGetConfigObjName   = self.oracledfwGetConfigObjNameWebSphereND
         self.oracledfwGetRuntimeObjName  = self.oracledfwGetRuntimeObjNameWebSphereND

         self.oracledfwGetLocalServerName = self.oracledfwGetLocalServerNameWebSphere
         self.oracledfwResolveServerName  = self.oracledfwResolveServerNameWebSphereND

     elif ora_mbs.isWebSphereAS():
         self.oracledfwGetGeneralObjName  = self.oracledfwGetGeneralObjNameWebSphereAS
         self.mConfigMBeanNameDiscriminatingProperties  = ["process"]
         self.mRuntimeMBeanNameDiscriminatingProperties = ["process"]

         self.oracledfwGetLocalServerName = self.oracledfwGetLocalServerNameWebSphere
         self.oracledfwResolveServerName  = self.oracledfwResolveServerNameWebSphereAS

     else:
       raise "Unsupported platform for Oracle_WAS_dfw: " + ora_mbs.getPlatform()

   #
   # !!! Functions applicable to all server types !!!
   #

   def _oracledfwVerifyConnect(self):
       from Oracle_dfw_handler import Oracle_dfw_handler
       from Oracle_dfw_handler import DfwError
       if ora_mbs.isConnected() == 0:       
           handler = Oracle_dfw_handler()
           raise DfwError,  _strFilter(handler.oraDfwGetMsg(handler.NOT_CONNECTED))

   # Generate the object name for a configuration mbean.
   def oracledfwGetConfigObjName(self, pServerName, pBaseName):
       return self.oracledfwGetGeneralObjName(
           self.mConfigMBeanNameDiscriminatingProperties,
           pServerName, pBaseName)

   # Generate the object name for a runtime mbean.
   def oracledfwGetRuntimeObjName(self, pServerName, pBaseName):
       return self.oracledfwGetGeneralObjName(
           self.mRuntimeMBeanNameDiscriminatingProperties,
           pServerName, pBaseName)

   #
   # !!! Functions applicable to WebSphere server types !!!
   #

   def oracledfwResolveServerNameWebSphereND(self,pServerName):

       #
       # WebSphereND rule: "server" is a legal parameter and can be anything,
       # but if not provided:
       #  if on the deployment manager we default to the OracleAdminServer
       #    (where stuff is more interesting than on dep mgr) 
       #  if on some other server we use the local server name
       #
       from Oracle_dfw_handler import Oracle_dfw_handler
       from Oracle_dfw_handler import DfwError

       if pServerName is None:
           if (self.oracledfwGetDeploymentManagerName()):
               retVal = ORACLEADMINSERVER # Not the local (dep mgr) name

               # Don't strictly need to do this here, but given that we're
               # defaulting the server name to something other than the
               # local server (which is clearly up 'cos w're connected to it)
               # we're choosing to halt early rather than late.
               oas = AdminControl.completeObjectName(WAS_OAS)
               if oas is None:
                   handler = Oracle_dfw_handler()
                   raise DfwError, handler.oraDfwGetMsg(handler.OAS_NOT_UP, None)

           else:
             retVal = self.oracledfwGetLocalServerName()
       else:
           retVal = pServerName

       return retVal

   def oracledfwResolveServerNameWebSphereAS(self,pServerName):

       #
       # WebSphereAS rule: "server" is an illegal parameter
       #

       from Oracle_dfw_handler import Oracle_dfw_handler
       from Oracle_dfw_handler import DfwError

       if pServerName is None:
           retVal = self.oracledfwGetLocalServerName()
       else:
           handler = Oracle_dfw_handler()
           raise DfwError, handler.oraDfwGetMsg(handler.UNSUPPORTED_SERVER, None)

       return retVal

   def oracledfwGetGeneralObjNameWebSphereAS (self, pDiscriminators, pServerName, pBaseName):

       # Single server case - if server name is provided it must match
       # the local server's name
       localServerName = self.oracledfwGetLocalServerName()
       if ((pServerName == None) or (pServerName == localServerName)):
           serverNameToUse = localServerName
       else:
           # This condition should have been caught before this method was called
           raise ValueError, ("In a WebSphereAS environment, pServerName "
             "must be None or it must match the local server's name.")

       pattern = pBaseName
       for discriminator in pDiscriminators:
           pattern = pattern + "," + discriminator + "=" + serverNameToUse

       # Last step is to have WAS complete the name
       retVal = AdminControl.completeObjectName(pattern + ",*")

       return retVal

   def oracledfwGetLocalServerNameWebSphere(self):

       retVal = None

       # This if-ladder mechanism for getting a server name works for both
       # WAS-ND and WAS-AS. It may appear a bit over the top for
       # the isWebSphereAS case but the current ora_mbs implementation
       # assumes a connection isWebSphereAS if that connection can not see
       # a server with "dmgr" as its name - thus connections to nodeagents
       # and other servers running in WAS-ND environments are flagged 
       # as WAS-AS to ora_mbs.
       #
       # General mechanism is to start at the highest level of a topology
       # and work down searching for a matching WebSphere:type=Server 
       # object name.

       deploymentManagerName = self.oracledfwGetDeploymentManagerName()
       if (deploymentManagerName):
           retVal = deploymentManagerName
       else:
           # Not connected to DeploymentManager.
           # Perhaps we're connected to NodeAgent then?
           nodeAgentObjectNameAsString = AdminControl.completeObjectName(
               "WebSphere:type=Server,processType=NodeAgent,*")
           if (nodeAgentObjectNameAsString):
               retVal = ObjectName(nodeAgentObjectNameAsString).getKeyProperty("name")
           else:
               # Not connected to DeploymentManager, or NodeAgent.
               # Perhaps we're connected to ManagedProcess then?
               managedProcessObjectNameAsString = AdminControl.completeObjectName(
                   "WebSphere:type=Server,processType=ManagedProcess,*")
               if (managedProcessObjectNameAsString):
                   retVal = ObjectName(managedProcessObjectNameAsString).getKeyProperty("name")
               else:
                   # Not connected to DeploymentManager, or NodeAgent or ManagedProcess
                   # Perhaps we're connected to an UnManagedProcess then?
                   unmanagedProcessObjectNameAsString =  AdminControl.completeObjectName(
                       "WebSphere:type=Server,processType=UnManagedProcess,*")
                   if (unmanagedProcessObjectNameAsString):
                       retVal = ObjectName(unmanagedProcessObjectNameAsString).getKeyProperty("name")

       return retVal

   def oracledfwGetDeploymentManagerName(self):

       retVal = None
       # There will be at most one of these mbeans, and only if run
       # on the node manager itself.
       nodeManagerObjectNameAsString = AdminControl.completeObjectName(WAS_SERVER)

       # nodeManagerObjectNameAsString may be the empty string
       if (nodeManagerObjectNameAsString):
           retVal = ObjectName(nodeManagerObjectNameAsString).getKeyProperty("name") 

       return retVal

   def oracledfwGetConfigObjNameWebSphereND(self, pServerName, pBaseName):

       retVal = None
       serverNameToUse = None

       deploymentManagerName = self.oracledfwGetDeploymentManagerName()

       # Network Deployment case
       if (deploymentManagerName):
           # if connected to the deployment manager then any server name
           # is fair game. Moreover, there is no shortcut even if the
           # user has named the local server - the server name still
           # has to be used.
           if (pServerName):
               serverNameToUse = pServerName
           else:
               serverNameToUse = self.oracledfwGetDeploymentManagerName()

           pattern = pBaseName + ",ServerName=" + serverNameToUse + ",process=" + deploymentManagerName

       else:
           # if connected to the something other than the deployment
           # manager, say, OracleAdminServer, or some other server or
           # process, then server name is not supported or if provided
           # must match the local server's name.
           localServerName = self.oracledfwGetLocalServerName()
           if ((pServerName == None) or (pServerName == localServerName)):
               serverNameToUse = localServerName
           else:
               # This condition should have been caught before this method was called
               raise ValueError, ("In a WebSphereND environment "
                 "not connected to the deployment manager, pServerName "
                 "must be None or match the local server's name.")

           pattern = pBaseName + ",process=" + serverNameToUse

       # Last step is to have WAS complete the name
       retVal = AdminControl.completeObjectName(pattern + ",*")

       return retVal

   def oracledfwGetRuntimeObjNameWebSphereND (self, pServerName, pBaseName):

       retVal = None
       serverNameToUse = None

       # Network Deployment case
       if (self.oracledfwGetDeploymentManagerName()):
           # if connected to the deployment manager then any server name
           # is fair game. Moreover, there is no shortcut even if the
           # user has named the local server - the server name still
           # has to be used.
           if (pServerName):
               serverNameToUse = pServerName
           else:
               serverNameToUse = self.oracledfwGetDeploymentManagerName()
       else:
           # if connected to the something other than the deployment
           # manager, say, OracleAdminServer, or some other server or
           # process, then server name is not supported or if provided
           # must match the local server's name.
           localServerName = self.oracledfwGetLocalServerName()
           if ((pServerName == None) or (pServerName == localServerName)):
               serverNameToUse = localServerName
           else:
               # This condition should have been caught before this method was called
               raise ValueError, ("In a WebSphereND environment "
                 "not connected to the deployment manager, pServerName "
                 "must be None or match the local server's name.")

       pattern = pBaseName + ",process=" + serverNameToUse

       # Last step is to have WAS complete the name
       retVal = AdminControl.completeObjectName(pattern + ",*")

       return retVal
