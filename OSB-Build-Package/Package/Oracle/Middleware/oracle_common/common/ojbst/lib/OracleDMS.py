"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Define Oracle DMS commands for wsadmin

Caution: This file is part of the wsadmin implementation. Do not edit or move
this file because this may cause wsadmin commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your wsadmin scripts to fail when you upgrade to a different
version of wsadmin.
"""

import oracledms_handler
import cie.OracleHelp as OracleHelp
import jarray
import os
import sys
import java.lang
import ora_mbs
import ora_util
from oracledms_handler import DmsError
from java.lang import System
from java.lang import Class
from java.lang import String
from java.lang import StringBuffer
from java.util import Locale
from java.util import ResourceBundle
from javax.management import ObjectName
from javax.management import MBeanServerInvocationHandler
from javax.management import MBeanServerConnection
from javax.management import InstanceNotFoundException

# WAS
ORACLEADMINSERVER = "OracleAdminServer"
DEPLOYMENTMANAGER = "dmgr"

# mbean objectNames
WAS_SERVER  = "WebSphere:type=Server,processType=DeploymentManager,*"
WAS_MANAGED = "WebSphere:type=Server,processType=ManagedProcess,*"
WAS_OAS     = "WebSphere:type=Server,processType=ManagedProcess,process=OracleAdminServer,*"

# JBOSS
JBOSS_SERVER = "jrfServer"
JBOSS_BASE = "oracle.dms.event.config:name=DMSEventConfigMBean,type=JMXEventConfig"

# start command implementation
def displayMetricTableNames(**kws):
    """
    display DMS metric table names
    """
    
    try:
        return oracledms_handler.oracledmsDisplayMetricTableNames(kws)
    except Exception, ex:
        if not ora_mbs.isConnected() and ora_mbs.isWebSphere():
            print str(ex)
        else:
            raise ex


def dumpMetrics(**kws):
    """
    display internal DMS metrics
    """
    
    try:
        return oracledms_handler.oracledmsDumpMetrics(kws)
    except Exception, ex:
        if not ora_mbs.isConnected() and ora_mbs.isWebSphere():
            print str(ex)
        else:
            raise ex


def displayMetricTables(*names, **kws):
    """
    display DMS metric tables
    """
    
    try:
        return oracledms_handler.oracledmsDisplayMetricTables(names, kws)
    except Exception, ex:
        if not ora_mbs.isConnected() and ora_mbs.isWebSphere():
            print str(ex)
        else:
            raise ex


def reloadMetricRules(**kws):
    """
    reload metric rules completely
    """
    
    try:
        return oracledms_handler.oracledmsReloadMetricRules(kws)
    except Exception, ex:
        if not ora_mbs.isConnected() and ora_mbs.isWebSphere():
            print str(ex)
        else:
            raise ex

# Event Tracing Commands

# Private
def _test():
   print "test method ran"

def _printError(server):
   if str(sys.exc_info()[1]).find('InstanceNotFoundException') > -1:
      server = Oracle_dms().oracledmsGetServerName(server)
      msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", server)
   else:
      msg =  str(sys.exc_info()[1])[41:]

   oracledms_handler.oracledmsPrintErrorMessage(msg)

# Public
def listDMSEventConfiguration(**kws):
    """
    Give an overview of the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       return oracledms_handler.oracledmsListDMSEventConfiguration(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
          oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)

def enableDMSEventTrace(**kws):
    """
    Create a simple configuration in a single command
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsEnableDMSEventTrace(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def listDMSEventDestination(**kws):
    """
    Return the configuration for the specified destination, or all destinations if unspecified
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       return oracledms_handler.oracledmsListDMSEventDestination(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg =  oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def addDMSEventDestination(**kws):
    """
    Add a new destination to the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsAddDMSEventDestination(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg =  oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def updateDMSEventDestination(**kws):
    """
    Update any part of a destination in the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsUpdateDMSEventDestination(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg =  oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def removeDMSEventDestination(**kws):
    """
    Remove a destination from the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsRemoveDMSEventDestination(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def listDMSEventFilter(**kws):
    """
    Return the configuration for specified filter, or list all filters if no id specified
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       return oracledms_handler.oracledmsListDMSEventFilter(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)

def addDMSEventFilter(**kws):
    """
    Add a new filter to the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsAddDMSEventFilter(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)

def updateDMSEventFilter(**kws):
    """
    Update a filter in the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsUpdateDMSEventFilter(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg =  oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def removeDMSEventFilter(**kws):
    """
    Remove a filter from the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsRemoveDMSEventFilter(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def listDMSEventRoutes(**kws):
    """
    Return the event-routes from the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       return oracledms_handler.oracledmsListDMSEventRoutes(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def addDMSEventRoute(**kws):
    """
    Add an event-route to the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsAddDMSEventRoute(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg =  oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)

def updateDMSEventRoute(**kws):
    """
    Update an event-route in the Event Tracing configuration
    
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsUpdateDMSEventRoute(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg = oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)

def removeDMSEventRoute(**kws):
    """
    Remove an event-route from the Event Tracing configuration
    """

    try:
       dms = Oracle_dms()
       dms._oracledmsVerifyConnect()
       serverName = Oracle_dms().oracledmsGetServerName(kws.get("server"))
       obj = dms.oracledmsGetObjName(serverName)
       oracledms_handler.oracledmsRemoveDMSEventRoute(obj,**kws)
    except NameError, e:
       oracledms_handler.oracledmsPrintErrorMessage("NameError: " + str(e))
    except InstanceNotFoundException, ex:
       msg =  oracledms_handler._oracledms_getETraceMsg("INVALID-TARGET", serverName)
       oracledms_handler.oracledmsPrintErrorMessage(msg)
    except DmsError, e:
       oracledms_handler.oracledmsPrintErrorMessage(e.getMsg())
    except Exception, ex:
       raise DmsError, oracledms_handler._oracledms_getETraceExceptionMsg(ex)
    except:
       _printError(serverName)


def help(cmd=None):
    """
    help for the module
    """
    
    _module = "OracleDMS"
    if cmd == None:
        cmd = _module
    elif cmd == "reloadMetricRules":
        mesg = oracledms_handler.oracledms_help_internalCommand(cmd)
        print mesg
        ora_util.hideDisplay()
        return mesg
    else:
        cmd = _module + '.' + cmd
    return OracleHelp.help(cmd)


try:
    oracledms_handler.oracledms_init_help()
except:
    pass

class Oracle_dms:
   
   # helper to get the server name (sets the default if none specified)
   def oracledmsGetServerName(self,server):

     # if no server specified default to OracleAdminServer if WAS-ND
     # and JBOSS_SERVER for JBoss.
     # on WAS-AS and JBoss, the server parameter is not supported,
     # and an exception will be raised if server is specified.

     if server is None:
        if ora_mbs.isWebSphereND():
           server = ORACLEADMINSERVER # default to AdminServer
        elif ora_mbs.isWebSphereAS():
           serverString = AdminControl.completeObjectName("WebSphere:type=Server,processType=UnManagedProcess,*")
           # should only be one server for WAS AS
           server = ObjectName(serverString).getKeyProperty("name")
        elif ora_mbs.isJBoss():
	   server = JBOSS_SERVER
     elif ora_mbs.isWebSphereAS() or ora_mbs.isJBoss():
        raise DmsError, oracledms_handler._oracledms_getETraceMsg("UNSUPPORTED-SERVER")

     return server
   
   # helper to get the String to construct the MBean objectName
   def oracledmsGetObjName(self,server):
     if ora_mbs.isWebSphereND():
       return self._setMBeanServer_WAS(server)
     elif ora_mbs.isWebSphereAS():
       return self._setMBeanServer_WAS(server)
     elif ora_mbs.isJBoss():
       return self._setMBeanServer_JBOSS(server)
     return None
   
   def _setMBeanServer_WAS(self, server):
      self.dmgr    = AdminControl.completeObjectName(WAS_SERVER)
      self.process = ObjectName(self.dmgr).getKeyProperty("name") #e.g. dmgr
      
      if self.process == DEPLOYMENTMANAGER:
        self.oas = AdminControl.completeObjectName(WAS_OAS)
        self.oasProc = ObjectName(self.oas).getKeyProperty("name")
        
        if self.oasProc is None:
          raise DmsError, oracledms_handler._oracledms_getETraceMsg("OAS_NOT_UP")
        
        server = self.oracledmsGetServerName(server)
      
      self.baseStr = "oracle.dms.event.config:type=JMXEventConfig,name=DMSEventConfigMBean"
      # taken from DFW. Not seen a case where no process, but just in case
      if self.process is None:
         self.queryName = self.baseStr + ",*"
      else:
         self.queryName = self.baseStr +  ",process=" + self.process + ",ServerName=" + server + ",*"
      
      self.objStr = AdminControl.queryNames(self.queryName)
      return self.objStr
   
   def _setMBeanServer_JBOSS(self, server):
      oname = JBOSS_BASE + ",ServerName=" + self.oracledmsGetServerName(server)
      return oname
   
   def _oracledmsVerifyConnect(self):
      if ora_mbs.isConnected() == 0:
         raise DmsError, oracledms_handler.oracledms_getMsg("NOT-CONNECTED", oracledms_handler.oracledms_getPlatformName())
