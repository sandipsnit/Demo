"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move 
this file because this may cause WLST commands and scripts to fail. Do not 
try to reuse the logic in this file or keep copies of this file because this 
could cause your WLST scripts to fail when you upgrade to a different version 
of WLST. 

Defines DMS commands
"""

from java.lang import System
import os
import sys

def displayMetricTableNames(**kws):
    """
    display DMS metric table names
    """
    
    return oracledmsDisplayMetricTableNames(kws)


def dumpMetrics(**kws):
    """
    display internal DMS metrics
    """
    
    return oracledmsDumpMetrics(kws)


def displayMetricTables(*names, **kws):
    """
    display DMS metric tables
    """
    
    return oracledmsDisplayMetricTables(names, kws)


def reloadMetricRules(**kws):
    """
    reload metric rules completely
    """
    
    return oracledmsReloadMetricRules(kws)

# Event Tracing Commands

def listDMSEventConfiguration(**kws):
    """
    Give an overview of the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnect()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          return oracledmsListDMSEventConfiguration(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def enableDMSEventTrace(**kws):
    """
    Create a simple configuration in a single command
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsEnableDMSEventTrace(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def listDMSEventDestination(**kws):
    """
    Return the configuration for the specified destination, or all destinations if unspecified
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnect()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          return oracledmsListDMSEventDestination(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def addDMSEventDestination(**kws):
    """
    Add a new destination to the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsAddDMSEventDestination(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def updateDMSEventDestination(**kws):
    """
    Update any part of a destination in the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsUpdateDMSEventDestination(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def removeDMSEventDestination(**kws):
    """
    Remove a destination from the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsRemoveDMSEventDestination(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def listDMSEventFilter(**kws):
    """
    Return the configuration for specified filter, or list all filters if no id specified
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnect()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          return oracledmsListDMSEventFilter(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def addDMSEventFilter(**kws):
    """
    Add a new filter to the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsAddDMSEventFilter(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def updateDMSEventFilter(**kws):
    """
    Update a filter in the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsUpdateDMSEventFilter(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def removeDMSEventFilter(**kws):
    """
    Remove a filter from the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsRemoveDMSEventFilter(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)
   
def listDMSEventRoutes(**kws):
    """
    Return the event-routes from the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnect()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          return oracledmsListDMSEventRoutes(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)


def addDMSEventRoute(**kws):
    """
    Add an event-route to the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsAddDMSEventRoute(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def updateDMSEventRoute(**kws):
    """
    Update an event-route in the Event Tracing configuration
    
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsUpdateDMSEventRoute(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

def removeDMSEventRoute(**kws):
    """
    Remove an event-route from the Event Tracing configuration
    """

    serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
    cwd = pwd()

    try:
       try:
          Oracle_dms()._oracledmsVerifyConnectAdminServer()
          obj = Oracle_dms().oracledmsGetObjName(serverName)
          oracledmsRemoveDMSEventRoute(obj,**kws)
       except DmsError, e:
          oracledmsPrintErrorMessage(e.getMsg())
       except NameError, e:
          oracledmsPrintErrorMessage("NameError: " + str(e))
       except AttributeError, a:
          oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-TARGET", serverName))
       except WLSTException, e:
          raise DmsError, _oracledms_getETraceExceptionMsg(e)
       except Exception, ex:
          raise DmsError, _oracledms_getETraceExceptionMsg(ex)
    finally:
       if cwd != pwd():
          cd(cwd)

# temparory work around until an official way to load shared module
# load oracledms_handler by searching sys.path
_oc = System.getProperty('COMMON_COMPONENTS_HOME')
if _oc is not None:
    _sh = os.path.join(_oc, os.path.join('common', 'script_handlers'))
    if _sh not in sys.path:
        sys.path.append(_sh)
for _path in sys.path:
    _py = os.path.join(_path, 'oracledms_handler.py')
    if os.path.exists(_py):
        execfile(_py)
        break
try:
    oracledms_init_help()
except:
    pass


#__all__ = [displayMetricTableNames.__name__,
#           dumpMetrics.__name__,
#           displayMetricTables.__name__,]

class Oracle_dms:
   # helper to get the server name (sets the default to current server
   # connected to, if none specified)
   def oracledmsGetServerName(self,server):
      if server is None:
         server = serverName # serverName is a WLS parameter
      return server

   # helper to get the String to construct the MBean objectName
   def oracledmsGetObjName(self,server):
       self.baseStr = "oracle.dms.event.config:name=DMSEventConfigMBean,type=JMXEventConfig"
       if server is None:
         if isAdminServer == "true":
           if pwd() != "domainRuntime:/":
                   domainRuntime()
           return str(self.baseStr) + ",ServerName=" + serverName
         else:
           return str(self.baseStr)
       else:
         if isAdminServer == "true":
           if pwd() != "domainRuntime:/":
                   domainRuntime()
           retVal = str(self.baseStr) + ",ServerName=" + str(server)
           return retVal
         elif server == serverName:
           return self.baseStr
         else:
           raise DmsError, _oracledms_getETraceMsg("MAN-SERVER")

   def _oracledmsVerifyConnect(self):
      ora_mbs.setMbs(mbs) # required on WLS 
      if ora_mbs.isConnected() == 0:
         raise DmsError, oracledms_getMsg("NOT-CONNECTED", oracledms_getPlatformName())

   # helper to check online and connected to AdminServer, not a managed server
   def _oracledmsVerifyConnectAdminServer(self):
        self._oracledmsVerifyConnect()
        if isAdminServer != "true":
           raise DmsError, _oracledms_getETraceMsg("WRONG-SERVER")
