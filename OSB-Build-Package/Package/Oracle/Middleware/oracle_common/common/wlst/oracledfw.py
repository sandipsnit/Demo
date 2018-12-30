"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move
this file because this may cause WLST commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WLST scripts to fail when you upgrade to a different version
of WLST.

Oracle Fusion Middleware logging commands.

"""

import os
import sys
import java.lang
from java.lang import Class
from java.lang import String
from java.lang import Exception
from java.io import IOException
from javax.management import ObjectName

from oracle.dfw.resource import DiagnosticConstants

import os,sys
_oc = java.lang.System.getProperty('COMMON_COMPONENTS_HOME')
_sh = os.path.join(_oc, 'common/script_handlers')
if _sh not in sys.path:
   sys.path.append(_sh)
from Oracle_dfw_handler import Oracle_dfw_handler
from Oracle_dfw_handler import DfwError


"""
listADRHomes command
"""
def listADRHomes(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      ret = handler.listADRHomes(mbs, mbeanStr, **kws)
      print handler.formatListADRHomes(ret)
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException, ex:
      print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
  finally:
    cd(cwd)

"""
listProblems command
"""
def listProblems(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      problems =  handler.listProblems(mbs, mbeanStr, **kws)
      print handler.formatListProblems(problems)
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException, ex:
      setDumpStackThrowable(ex)
      print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()
  finally:
    cd(cwd)


"""
listIncidents command
"""
def listIncidents(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr  = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      incidents = handler.listIncidents(mbs, mbeanStr, **kws)

      print handler.formatListIncidents(incidents)
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException, nex:
      print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
    except Exception, ex:
      print ex
  finally:
    cd(cwd)
  
"""
showIncident command
"""
def showIncident(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      incident =  handler.showIncident(mbs, mbeanStr, **kws)

      print handler.formatShowIncident(incident)
    except DfwError, ex:
      print ex.getMsg()
    except Exception, ex:
      print ex
  finally:
    cd(cwd)

"""
createIncident command
"""
def createIncident(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      incident = handler.createIncident(mbs, mbeanStr, **kws)
      print handler.formatCreateIncident(incident)
    except DfwError, ex:
      print ex.getMsg()
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()
  finally:
    cd(cwd)


"""
getIncidentFile command
"""
def getIncidentFile(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr  = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      streamStr = dfw._setMBeanServer(handler.STREAMER, server)

      incident =  handler.getIncidentFile(mbs, mbeanStr, streamStr, **kws)
      print handler.formatGetIncidentFile(incident)
    except DfwError, ex:
      print ex.getMsg()
    except IOException, ex:
      setDumpStackThrowable(ex)
      print handler.oraDfwGetMsg(dfw.EXECUTEDUMP_IOEX, 
			      "getIncidentFile",  kws.get(handler.OUTPUTFILE))
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()
      print handler.oraDfwGetMsg(dfw.EXECUTEDUMP_EX,  
                                          kws.get(handler.OUTPUTFILE))
  finally:
    cd(cwd)

"""
reloadCustomRules command
"""
def reloadCustomRules(**kws):
  dfw = Oracle_dfw()
  handler = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr  = dfw._setMBeanServer(handler.INCIDENT_MANAGER, server)
      result = handler.reloadCustomRules(mbs, mbeanStr, **kws)

      print handler.formatReloadCustomRulesResult(result)
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException, nex:
      print handler.oraDfwGetMsg(handler.INCIDENT_MGR_DISABLED, server)
    except Exception, ex:
      print ex
  finally:
    cd(cwd)

"""
listDumps command
"""
def listDumps(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setMBeanServer(handler.DUMP_MANAGER, server)
      dumps =  handler.listDumps(mbs, mbeanStr, **kws)
      print handler.formatListDumps(dumps)
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
  finally:
    cd(cwd)

"""
describeDump Command
"""
def describeDump(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setMBeanServer(handler.DUMP_MANAGER, server)
      dump     = handler.describeDump(mbs, mbeanStr, **kws)

      print handler.formatDescribeDump(dump)
    except DfwError, ex:
      print ex.getMsg()
  finally:
    cd(cwd)

"""
executeDump command
"""
def executeDump(**kws):
  dfw = Oracle_dfw()
  handler   = Oracle_dfw_handler()

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr  = dfw._setMBeanServer(handler.DUMP_MANAGER, server)
      streamStr = dfw._setMBeanServer(handler.STREAMER, server)
      dump      = handler.executeDump(mbs, mbeanStr, streamStr, **kws)

      print handler.formatExecuteDump(dump)
    except DfwError, ex:
      print ex.getMsg()
    except IOException, ex:
      setDumpStackThrowable(ex)
      print handler.oraDfwGetMsg(dfw.EXECUTEDUMP_IOEX, 
                                   "executeDump",  kws.get(handler.OUTPUTFILE))
    except MBeanException, ex:
      errMsg = String(ex.getMessage())
      incidentId = kws.get(handler.INCIDENTID)
      if incidentId is None:
	setDumpStackThrowable(ex)
	print errMsg
      else:
	print errMsg
	idx1 = errMsg.lastIndexOf('/') + 1
	idx2 = errMsg.indexOf('(') - 1
	if idx1 >= 0 and idx2 >= 0:
	  fname = errMsg.substring(idx1, idx2)
	  print "Dump file " + fname + " added to incident " + incidentId
	else:
	  setDumpStackThrowable(ex)
	  print errMsg
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()
      print handler.oraDfwGetMsg(dfw.EXECUTEDUMP_EX,  
                                            kws.get(handler.OUTPUTFILE))
  finally:
    cd(cwd)

"""
isDumpSamplingEnabled Command
"""
def isDumpSamplingEnabled(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setConfigMBeanServer(handler.DIAGNOSTICS_CONFIG, server)
      enabled  = handler.isDumpSamplingEnabled(mbs, mbeanStr, **kws)
      print enabled
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()
      print ex.getCause()

  finally:
    cd(cwd)

"""
enableDumpSampling Command
"""
def enableDumpSampling(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setConfigMBeanServer(handler.DIAGNOSTICS_CONFIG, server)
      result  = handler.enableDumpSampling(mbs, mbeanStr, **kws)
      print result
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()

  finally:
    cd(cwd)

"""
addDumpSample Command
"""
def addDumpSample(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setConfigMBeanServer(handler.DIAGNOSTICS_CONFIG, server)
      result  = handler.addDumpSample(mbs, mbeanStr, **kws)
      print result
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()

  finally:
    cd(cwd)

"""
updateDumpSample Command
"""
def updateDumpSample(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setConfigMBeanServer(handler.DIAGNOSTICS_CONFIG, server)
      result  = handler.updateDumpSample(mbs, mbeanStr, **kws)
      print result
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()

  finally:
    cd(cwd)

"""
removeDumpSample Command
"""
def removeDumpSample(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setConfigMBeanServer(handler.DIAGNOSTICS_CONFIG, server)
      result  = handler.removeDumpSample(mbs, mbeanStr, **kws)
      print result
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()

  finally:
    cd(cwd)

"""
listDumpSamples Command
"""
def listDumpSamples(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr = dfw._setConfigMBeanServer(handler.DIAGNOSTICS_CONFIG, server)
      result  = handler.listDumpSamples(mbs, mbeanStr, **kws)
      print result
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()

  finally:
    cd(cwd)

"""
getSamplingArchives Command
"""
def getSamplingArchives(**kws):
  dfw = Oracle_dfw()
  handler  = Oracle_dfw_handler()
  if not dfw._isConnected():
    return None

  cwd = pwd()
  server = kws.get(handler.SERVER)

  try:
    try:
      mbeanStr  = dfw._setMBeanServer(handler.DUMP_MANAGER, server)
      streamStr = dfw._setMBeanServer(handler.STREAMER, server)
      result    = handler.getSamplingArchives(mbs, mbeanStr, streamStr, **kws)
      print result
    except DfwError, ex:
      print ex.getMsg()
    except InstanceNotFoundException:
      print handler.oraDfwGetMsg(handler.SERVER_NOT_FOUND, server)
    except Exception, ex:
      setDumpStackThrowable(ex)
      print ex.getMessage()

  finally:
    cd(cwd)

"""
Class to incapsulate private constants and methods
"""
class Oracle_dfw:
  def __init__(self):
    # mbean objectNames
    self.DOMAIN_SERVER = "com.bea:Name=DomainRuntimeService,Type=weblogic.management.mbeanservers.domainruntime.DomainRuntimeServiceMBean"

    # resource bundles
    self.MSGFILE   = "oracle.as.management.logging.messages.CommandHelp"

    # message keys
    self.EXECUTEDUMP_IOEX      = DiagnosticConstants.DFW_WLST_EXECUTEDUMP_IO
    self.EXECUTEDUMP_EX        = DiagnosticConstants.DFW_WLST_EXECUTEDUMP

  #verify wlst is connected to the server
  def _isConnected(self):
    if mbs is None:
      handler   = Oracle_dfw_handler()
      print handler.oraDfwGetMsg(handler.NOT_CONNECTED, None)
      return false
    else:
      return true

  def _setMBeanServer(self, baseStr, server):
    if server is None:
      if isAdminServer == "true" and mbs.isRegistered(ObjectName(self.DOMAIN_SERVER)):
	return baseStr + ",Location=" + serverName
      else:
	return baseStr
    else:
      if isAdminServer == "true":
	domainRuntime()
	return baseStr + ",Location=" + server
      elif server == serverName:
	return baseStr
      else:
	handler = Oracle_dfw_handler()
	raise DfwError, handler.oraDfwGetMsg(handler.WRONG_SERVER)

   # to construct string for a ConfigMBean object
  def _setConfigMBeanServer(self, baseStr, server):
    if server is None:
      if isAdminServer == "true":
        if pwd() != "domainRuntime:/":
          domainRuntime()
        return baseStr + ",ServerName=" + serverName
      else:
        return baseStr
    else:
      if isAdminServer == "true":
        if pwd() != "domainRuntime:/":
          domainRuntime()
          retVal = baseStr + ",ServerName=" + str(server)
          return retVal
      elif server == serverName:
        return baseStr
      else:
        raise DfwError, handler.oraDfwGetMsg(handler.MAN_SERVER) 

  # define the help text
  def _initHelp(self):
    try:
      addHelpCommandGroup("fmw diagnostics", self.MSGFILE)
    except:
      pass
    addHelpCommand("getSamplingArchives", "fmw diagnostics", online="true")
    addHelpCommand("listADRHomes", "fmw diagnostics", online="true")
    addHelpCommand("listProblems", "fmw diagnostics", online="true")
    addHelpCommand("listIncidents", "fmw diagnostics", online="true")
    addHelpCommand("showIncident", "fmw diagnostics", online="true")
    addHelpCommand("createIncident", "fmw diagnostics", online="true")
    addHelpCommand("getIncidentFile", "fmw diagnostics", online="true")
    addHelpCommand("reloadCustomRules", "fmw diagnostics", online="true")    
    addHelpCommand("listDumps", "fmw diagnostics", online="true")
    addHelpCommand("describeDump", "fmw diagnostics", online="true")
    addHelpCommand("executeDump", "fmw diagnostics", online="true")
    addHelpCommand("isDumpSamplingEnabled", "fmw diagnostics", online="true")
    addHelpCommand("enableDumpSampling", "fmw diagnostics", online="true")
    addHelpCommand("addDumpSample", "fmw diagnostics", online="true")
    addHelpCommand("updateDumpSample", "fmw diagnostics", online="true")
    addHelpCommand("removeDumpSample", "fmw diagnostics", online="true")
    addHelpCommand("listDumpSamples", "fmw diagnostics", online="true")

"""
Help file initialization
"""
try:
  dfw = Oracle_dfw()
  dfw._initHelp()
except:
  pass

