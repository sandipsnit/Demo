"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST and WAS implementation. Do not edit or 
move this file because this may cause WLST and WAS commands and scripts to 
fail. Do not try to reuse the logic in this file or keep copies of this file 
because this could cause your WLST and WAS scripts to fail when you upgrade 
to a different version of WLST or WAS.

Oracle Fusion Middleware logging commands.

"""

import jarray
import os
import sys
import java.lang
import java.io
import ora_help

from java.lang import StringBuffer
from java.lang import System
from java.lang import Object
from java.lang import Class
from java.lang import String
from java.text import MessageFormat
from java.io import File
from java.io import InputStreamReader
from java.io import FileOutputStream
from java.io import BufferedReader
from java.io import BufferedInputStream
from java.io import IOException
from java.util import HashMap
from java.util import Locale
from java.util import ResourceBundle
from javax.management import ObjectName
from javax.management import Attribute
from javax.management import AttributeList
from javax.management import InstanceNotFoundException
from javax.management import MBeanServerInvocationHandler
from javax.management.openmbean import CompositeDataSupport
from javax.management.openmbean import CompositeType
from javax.management.openmbean import SimpleType
from javax.management.openmbean import TabularDataSupport
from javax.management.openmbean import TabularType

from oracle.as.management.streaming import MBeanInputStream
from oracle.as.management.streaming import StreamingMBean
from oracle.dfw.resource import DiagnosticConstants


class Oracle_dfw_handler:
  """
  listADRHomes command
  """
  def listADRHomes(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER,))
    mbeanName = ObjectName(mbeanStr)
    homes =  mbs.getAttribute(mbeanName, "ADRHomes")
    return homes

  def formatListADRHomes(self, homes):
    buf = StringBuffer()
    for home in homes:
      buf.append(home)
      buf.append("\n")
    ret = buf.toString()

    return ret

  """
  listProblems command
  """
  def listProblems(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.ADRHOME))
    mbeanName = ObjectName(mbeanStr)
    home      = kws.get(self.ADRHOME)

    if home is None:
      problems =  mbs.getAttribute(mbeanName, "Problems")
    else:
      problems = mbs.invoke(mbeanName, "getProblems", jarray.array([home],
			     String), jarray.array(["java.lang.String"],String))

    return problems

  def formatListProblems(self, problems):
    return self._printProblemList(problems)


  def listIncidents(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.ADRHOME, self.PROBLEMID))
    incidentList = []
    mbeanName    = ObjectName(mbeanStr)
    problemId    = kws.get(self.PROBLEMID)
    home         = kws.get(self.ADRHOME)
      
    if problemId is None:
      if home is None:
	problems =  mbs.getAttribute(mbeanName, "Problems")
      else:
	problems = mbs.invoke(mbeanName, "getProblems",
		  jarray.array([home], String),
			jarray.array(["java.lang.String"],String))

      for problem in problems:
	problemId = problem.get("problemId")
	incidents = self._listIncidents(mbs, home, problemId, mbeanName)
	for incident in incidents:
	  incidentList.append(incident)
    else:
      incidents = self._listIncidents(mbs, home, problemId, mbeanName)
      for incident in incidents:
	incidentList.append(incident)

    incidentList.sort(self._compareIncidents)
    return incidentList

  def formatListIncidents(self, incidentList):
    return self._printIncidentList(incidentList)

  """
  showIncident command
  """
  def showIncident(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.ADRHOME, self.INCIDENTID))
    mbeanName  = ObjectName(mbeanStr)
    incidentId = kws.get(self.INCIDENTID)
    home       = kws.get(self.ADRHOME)

    if incidentId is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.INCIDENTID)

    if home is None:
      incident = mbs.invoke(mbeanName, "getIncident",
	    jarray.array([incidentId], String),
	    jarray.array(["java.lang.String"],String))
    else:
      incident = mbs.invoke(mbeanName, "getIncident",
	  jarray.array([home, incidentId], String),
	      jarray.array(["java.lang.String", "java.lang.String"],String))

    return incident

  def formatShowIncident(self, incident):
    return self._printIncident(incident)

  """
  createIncident command
  """
  def createIncident(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.MESSAGEID, self.ADRHOME, 
                  self.ECID, self.APPNAME, self.INCIDENTTIME, self.DESCRIPTION))
    mbeanName    = ObjectName(mbeanStr)
    messageId    = kws.get(self.MESSAGEID)
    home         = kws.get(self.ADRHOME)
    ecid         = kws.get(self.ECID)
    appName      = kws.get(self.APPNAME)
    incidentTime = kws.get(self.INCIDENTTIME)
    description  = kws.get(self.DESCRIPTION)

    if home is None:
      incident = mbs.invoke(mbeanName, "createIncident",
      jarray.array([incidentTime, messageId, ecid, description, appName],
					  String),
      jarray.array(["java.lang.String","java.lang.String","java.lang.String",
		     "java.lang.String", "java.lang.String"],String))
    else:
      incident = mbs.invoke(mbeanName, "createIncident",
      jarray.array([home, incidentTime, messageId, ecid,
	     description, appName], String),
      jarray.array(["java.lang.String", "java.lang.String","java.lang.String",
       "java.lang.String", "java.lang.String", "java.lang.String"],String))

    return incident

  def formatCreateIncident(self, incident):
    return self._printIncident(incident)

  """
  getIncidentFile command
  """
  def getIncidentFile(self, mbs, mbeanStr, streamStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.NAME, self.OUTPUTFILE,
                                           self.ADRHOME, self.INCIDENTID))
    mbeanName  = ObjectName(mbeanStr)
    name       = kws.get(self.NAME)
    outFile    = kws.get(self.OUTPUTFILE)
    home       = kws.get(self.ADRHOME)
    incidentId = kws.get(self.INCIDENTID)
    outStream  = None
    stream     = None
    buf        = None

    if name is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.NAME)
    if incidentId is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.INCIDENTID)

    if home is None:
      content = mbs.invoke(mbeanName, "getIncidentFileContents",
	 jarray.array([incidentId, name],java.lang.String),
	 jarray.array(["java.lang.String",
			  "java.lang.String"], java.lang.String))
    else:
      content = mbs.invoke(mbeanName, "getIncidentFileContents",
	 jarray.array([home, incidentId, name],java.lang.String),
	 jarray.array(["java.lang.String", "java.lang.String",
			  "java.lang.String"], java.lang.String))

    sbeanName  = ObjectName(streamStr)
    streamClass = Class.forName("oracle.as.management.streaming.StreamingMBean")
    streamBean  = MBeanServerInvocationHandler.newProxyInstance(mbs,
					sbeanName, streamClass, 1==0)
    stream = MBeanInputStream (content, streamBean)

    # output the content of the dump
    if outFile is None:
      reader = BufferedReader(InputStreamReader(stream))
      buf    = StringBuffer()

      line   = reader.readLine()
      while not line is None:
	buf.append(line)
	buf.append("\n")
	line = reader.readLine()

    else:
      outStream = FileOutputStream(outFile)
      reader    = BufferedInputStream(stream)
      buffer    = jarray.zeros(1024, 'b')
      bytesRead = reader.read(buffer)

      while bytesRead != -1:
	outStream.write(buffer, 0, bytesRead)
	bytesRead = reader.read(buffer)

      if not outStream is None:
	outStream.close()
    if not stream is None:
      stream.close()

    if  buf is None:
      return ""
    else:
      return buf.toString()

  def formatGetIncidentFile(self, incident):
    return incident

  """
  reloadCustomRules command
  """
  def reloadCustomRules(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.NAME))
    mbeanName    = ObjectName(mbeanStr)
    filename     = kws.get(self.NAME)

    return mbs.invoke(mbeanName, "reloadCustomRules",
                  jarray.array([filename], String),
                  jarray.array(["java.lang.String"],String))

  """
  formatReloadCustomRulesResult command
  """
  def formatReloadCustomRulesResult(self, result):
    errorsFound = None
    buf = StringBuffer()
    buf.append(self.oraDfwGetMsg(self.RELOAD_SUCCESS) + "\n\n")
    for entry in result.entrySet():
      if entry.getValue().get("value") is None:
        buf.append(entry.getValue().get("key") + "\n")
      else:
        errorsFound = "true"

    if errorsFound == "true":
      buf.append("\n" + self.oraDfwGetMsg(self.RELOAD_FAILURE) + "\n\n")
      for entry in result.entrySet():
        if entry.getValue().get("value") != None:
          buf.append(entry.getValue().get("key") + ":\n")
          buf.append(entry.getValue().get("value") + "\n\n")

    return buf.toString()

  """
  listDumps command
  """
  def listDumps(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.APPNAME))
    mbeanName = ObjectName(mbeanStr)
    appName   = kws.get(self.APPNAME)

    if appName is None:
      dumps =  mbs.getAttribute(mbeanName, "SystemDumps")
    else:
      dumps = mbs.invoke(mbeanName, "getApplicationDumps",
      jarray.array([appName], String),
      jarray.array(["java.lang.String"],String))

    list = []
    for dump in dumps:
	list.append(dump.get(self.NAME))

    return list

  def formatListDumps(self, dumps):
    return self._formatList(dumps, self.DESCRIBEDUMP_MSG)

  """
  describeDump Command
  """
  def describeDump(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.NAME, self.APPNAME))
    name = kws.get(self.NAME)

    if name is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.NAME)

    mbeanName = ObjectName(mbeanStr)
    appName   = kws.get(self.APPNAME)

    if appName is None:
      dumps =  mbs.getAttribute(mbeanName, "SystemDumps")
    else:
      dumps = mbs.invoke(mbeanName, "getApplicationDumps",
      jarray.array([appName], String),
      jarray.array(["java.lang.String"],String))

    for dump in dumps:
      dumpName = dump.get("name")
      if dumpName == name:
	return dump
    return None

  # format output for describeDump command
  def formatDescribeDump(self, dump):
    if dump is None:
      return None;

    buf = StringBuffer()

    mArg = dump.get("mandatoryArguments")
    oArg = dump.get("optionalArguments")

    buf.append("Name: " + dump.get("name"))
    buf.append("\n")
    buf.append("Description: " + dump.get("description"))
    buf.append("\n")
    buf.append("Run Mode: " + dump.get("runMode").lower())
    buf.append("\n")
    buf.append("Mandatory Arguments: ")
    buf.append("\n")
    if not mArg is None:
      buf.append("    Name \tType\t Description")
      buf.append("\n")
      for opt in mArg:
	argName = opt.get(jarray.array(["ARG_NAME"], String)).get("value")
	argType = opt.get(jarray.array(["ARG_TYPE"], String)).get("value")
	argDesc = opt.get(jarray.array(["ARG_DESCRIPTION"], String)).get("value")
	buf.append( "    " + argName + "\t" + argType + "\t " + argDesc)
	buf.append("\n")
    buf.append("Optional Arguments:")
    buf.append("\n")
    if not oArg is None:
      buf.append("    Name \tType\t Description")
      buf.append("\n")
      for opt in oArg:
	argName = opt.get(jarray.array(["ARG_NAME"], String)).get("value")
	argType = opt.get(jarray.array(["ARG_TYPE"], String)).get("value")
	argDesc = opt.get(jarray.array(["ARG_DESCRIPTION"], String)).get("value")
	buf.append("    " + argName + "\t" + argType + "\t " + argDesc)
	buf.append("\n")
    return buf.toString()

  """
  executeDump command
  """

  def executeDump(self, mbs, mbeanStr, streamStr, **kws):
    self._verifyParams(kws,  (self.SERVER, self.NAME, self.APPNAME, 
                   self.OUTPUTFILE, self.ARGS, self.INCIDENTID, self.ADRHOME,
                   self.ZIPOUTPUT))
    name = kws.get(self.NAME)

    if name is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.NAME)

    mbeanName  = ObjectName(mbeanStr)
    appName    = kws.get(self.APPNAME)
    outFile    = kws.get(self.OUTPUTFILE)
    args       = kws.get(self.ARGS)
    incidentId = kws.get(self.INCIDENTID)
    home       = kws.get(self.ADRHOME)
    zipOutput  = kws.get(self.ZIPOUTPUT)
    outStream  = None
    stream     = None
    buf        = None
    toZip      = 0

    if zipOutput is "true" or zipOutput is "TRUE" or zipOutput is 1:
      toZip = 1
    if toZip and outFile is None: 
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG_1, self.ZIPOUTPUT,
                                        self.OUTPUTFILE)

    jargs = self._buildJArgs(args)

    if home is None and incidentId is None:
      files = mbs.invoke(mbeanName, "executeDump",
	              jarray.array([name, appName, jargs],java.lang.Object),
                jarray.array(["java.lang.String", "java.lang.String",
	      "javax.management.openmbean.TabularData"],java.lang.String))
    elif home is None:
      files = mbs.invoke(mbeanName, "executeDump",
                jarray.array([name, appName, jargs, incidentId],java.lang.Object),
                jarray.array(["java.lang.String", "java.lang.String",
                "javax.management.openmbean.TabularData",
                "java.lang.String"],java.lang.String))
    else:
      files = mbs.invoke(mbeanName, "executeDump",
                jarray.array([name, appName, jargs, home, incidentId],java.lang.Object),
                jarray.array(["java.lang.String", "java.lang.String",
                "javax.management.openmbean.TabularData", "java.lang.String",
                "java.lang.String"],java.lang.String))

    if files is None:
      return None

    buf = StringBuffer()

    if incidentId != None:
      buf.append("Dump file")
      count = 0
      for file in files:
        if count == 0:
          buf.append(" ")
        else:
          buf.append(", ")
        printFile = String(file)
        idx1 = printFile.lastIndexOf('/') + 1
        buf.append(printFile.substring(idx1))
        count = count + 1
      buf.append(" added to incident ")
      buf.append(incidentId)
      buf.append("\n")


    if outFile != None:
      newLine   = String("\n").getBytes()
      outStream = FileOutputStream(outFile)
      buffer    = jarray.zeros(1024, 'b')

    sbeanName   = ObjectName(streamStr)
    streamClass = Class.forName("oracle.as.management.streaming.StreamingMBean")
    streamBean  = MBeanServerInvocationHandler.newProxyInstance(mbs,
					sbeanName, streamClass, 1==0)

    content = mbs.invoke(mbeanName, "getDumpContents",
         jarray.array([files, toZip], Object),
         jarray.array(["[Ljava.lang.String;", "boolean"], java.lang.String))

    stream = MBeanInputStream (content, streamBean)

    # output the content of the dump
    if outFile is None:
      reader = BufferedReader(InputStreamReader(stream))
      line = reader.readLine()
      while not line is None:
        buf.append(line)
        buf.append("\n")
        line = reader.readLine()
    else:
      reader    = BufferedInputStream(stream)
      bytesRead = reader.read(buffer)
      while bytesRead != -1:
        outStream.write(buffer, 0, bytesRead)
        bytesRead = reader.read(buffer)

    if not outStream is None:
      outStream.close()
    if not stream is None:
      stream.close()

    if buf is None:
      return ""
    else:
      return buf.toString()

  def formatExecuteDump(self, dump):
    return dump

  # get a translated message
  def oraDfwGetMsg(self, key, *args):
    try:
      bClass = Class.forName(self.ERRORFILE)
      rb = ResourceBundle.getBundle(self.ERRORFILE, Locale.getDefault(),
						   bClass.getClassLoader())
      if rb.containsKey(key):
	  msg = rb.getString(key)
      return MessageFormat.format(msg, jarray.array(args, java.lang.String))
    except Exception, ex:
      pass
    return key

  """
  isDumpSamplingEnabled command
  """
  def isDumpSamplingEnabled(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SERVER,))
    mbeanName = ObjectName(mbeanStr)
    #enabled = 0
    enabled = mbs.getAttribute(mbeanName, "DumpSamplingEnabled")
    #enabled = mbs.invoke(mbeanName, "isDumpSamplingEnabled",
    #    jarray.array([1], java.lang.Object),
    #    jarray.array(["boolean"], String))
    result = "false"
    if enabled:
        result = "true"
    return result

  """
  enableDumpSampling command
  """
  def enableDumpSampling(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.ENABLE, self.SERVER,))
    mbeanName = ObjectName(mbeanStr)
    enable = kws.get(self.ENABLE)

    if enable is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.ENABLE)
    mbs.invoke(mbeanName, "enableDumpSampling",
        jarray.array([enable], java.lang.Object),
        jarray.array(["boolean"], String))

    buf = StringBuffer()
    if enable:
      buf.append("Dump sampling enabled")
    else:
      buf.append("Dump sampling disabled")
    buf.append("\n")
    return buf.toString() 

  """
  addDumpSample command
  """
  def addDumpSample(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws, (self.SAMPLENAME, self.APPNAME, self.DIAGNOSTIC_DUMP_NAME,
                             self.SAMPLING_INTERVAL, self.ROTATION_COUT,
                             self.DUMP_IMPLICITLY, self.TO_APPEND, self.ARGS,
                             self.SERVER,))
    mbeanName = ObjectName(mbeanStr)
    name = kws.get(self.SAMPLENAME)
    appName = kws.get(self.APPNAME)
    diagnosticDumpName = kws.get(self.DIAGNOSTIC_DUMP_NAME)
    samplingInterval = kws.get(self.SAMPLING_INTERVAL)
    rotationCount = kws.get(self.ROTATION_COUT)
    dumpImplicitly = kws.get(self.DUMP_IMPLICITLY)
    toAppend = kws.get(self.TO_APPEND)
    args = kws.get(self.ARGS)

    if name is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.SAMPLENAME)
    if diagnosticDumpName is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.DIAGNOSTIC_DUMP_NAME)
    if samplingInterval is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.SAMPLING_INTERVAL)
    if rotationCount is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.ROTATION_COUT)
    if dumpImplicitly is None:
      dumpImplicitly = 1
    if toAppend is None:
      toAppend = 1 
    
    jargs = self._buildJArgs(args)
    mbs.invoke(mbeanName, "addDumpSample",
        jarray.array([name, diagnosticDumpName, appName, samplingInterval, rotationCount, dumpImplicitly, toAppend, jargs], java.lang.Object),
        jarray.array(["java.lang.String", "java.lang.String", "java.lang.String", "long", "long", "boolean", "boolean", "javax.management.openmbean.TabularData"], String))

    buf = StringBuffer()
    buf.append(name)
    buf.append(" is added")
    buf.append("\n")
    return buf.toString()

  """
  updateDumpSample command
  """
  def updateDumpSample(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws, (self.SAMPLENAME, self.APPNAME,
                             self.SAMPLING_INTERVAL, self.ROTATION_COUT,
                             self.DUMP_IMPLICITLY, self.TO_APPEND, self.ARGS,
                             self.SERVER,))

    updateAppName = 0
    updateSamplingInterval = 0
    updateRotationCount = 0
    updateDumpImplicitly = 0
    updateToAppend = 0
    updateArgs = 0

    mbeanName = ObjectName(mbeanStr)
    name = kws.get(self.SAMPLENAME)
    appName = kws.get(self.APPNAME)
    samplingInterval = kws.get(self.SAMPLING_INTERVAL)
    rotationCount = kws.get(self.ROTATION_COUT)
    dumpImplicitly = kws.get(self.DUMP_IMPLICITLY)
    toAppend = kws.get(self.TO_APPEND)
    args = kws.get(self.ARGS)

    if name is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.SAMPLENAME)
    if not appName is None:
      updateAppName = 1
    if not samplingInterval is None:
      updateSamplingInterval = 1
    else:
      samplingInterval = -1
    if not rotationCount is None:
      updateRotationCount = 1
    else:
      rotationCount = 1
    if not dumpImplicitly is None:
      updateDumpImplicitly = 1
    else:
      dumpImplicitly = 0
    if not toAppend is None:
      updateToAppend = 1
    else:
      toAppend = 0
    if not args is None:
      updateArgs = 1

    if not (updateAppName or updateSamplingInterval or updateRotationCount or updateDumpImplicitly or updateToAppend or updateArgs):
      raise DfwError, self.oraDfwGetMsg(self.MORE_ARGUMENTS_NEED, "updateDumpSample")

    jargs = self._buildJArgs(args)
    mbs.invoke(mbeanName, "updateDumpSample",
        jarray.array([name, appName, samplingInterval, rotationCount, dumpImplicitly, toAppend, jargs, updateAppName, updateSamplingInterval, updateRotationCount, updateDumpImplicitly, updateToAppend, updateArgs], java.lang.Object),
        jarray.array(["java.lang.String", "java.lang.String", "long", "long", "boolean", "boolean", "javax.management.openmbean.TabularData", "boolean", "boolean", "boolean", "boolean", "boolean", "boolean"], String))

    buf = StringBuffer()
    buf.append(name)
    buf.append(" is updated")
    buf.append("\n")
    return buf.toString()

  """
  removeDumpSample command
  """
  def removeDumpSample(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SAMPLENAME, self.SERVER,))
    mbeanName = ObjectName(mbeanStr)
    name = kws.get(self.SAMPLENAME)

    if name is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.SAMPLENAME)
    
    mbs.invoke(mbeanName, "removeDumpSample",
        jarray.array([name], java.lang.Object),
        jarray.array(["java.lang.String"], String))

    buf = StringBuffer()
    buf.append("Removed " + name + "\n")
    return buf.toString()

  """
  listDumpSamples command
  """
  def listDumpSamples(self, mbs, mbeanStr, **kws):
    self._verifyParams(kws,  (self.SAMPLENAME, self.SERVER,))

    mbeanName = ObjectName(mbeanStr)
    name = kws.get(self.SAMPLENAME)
    buf = StringBuffer()

    if name is None:
      dumpInfos= mbs.invoke(mbeanName, "listDumpSampleInfo", None, None)
      if not dumpInfos is None:
        for dumpInfo in dumpInfos:
          buf.append(self._printDumpSampleInfo(dumpInfo))
          buf.append("\n")
    else:
      dumpInfo = mbs.invoke(mbeanName, "listDumpSampleInfo",
                   jarray.array([name], java.lang.Object),
                   jarray.array(["java.lang.String"], String))
      if not dumpInfo is None:
        buf.append(self._printDumpSampleInfo(dumpInfo))
        buf.append("\n")

    return buf.toString()

  """
  getSamplingArchives command
  """

  def getSamplingArchives(self, mbs, mbeanStr, streamStr, **kws):
    self._verifyParams(kws, (self.SERVER, self.SAMPLENAME, self.OUTPUTFILE))
    outFile    = kws.get(self.OUTPUTFILE)

    if outFile is None:
      raise DfwError, self.oraDfwGetMsg(self.MISSING_ARG, self.OUTPUTFILE)

    mbeanName  = ObjectName(mbeanStr)
    name       = "dfw.samplingArchive"
    sampleName = kws.get(self.SAMPLENAME)
    outStream  = None
    stream     = None
    buf        = None
    toZip      = 1
    jargs      = None

    if sampleName is None:
      jargs = None
    else :
      typeName = "java.util.Map<java.lang.String, java.lang.String>"
      keyArr = ["key"]
      keyValue = ["key", "value"]
      openType = [SimpleType.STRING, SimpleType.STRING]
      rowType = CompositeType(typeName, typeName, keyValue, keyValue, openType)
      tabType = TabularType(typeName, typeName, rowType, keyArr)
      jargs = TabularDataSupport(tabType)
      map = HashMap(2)
      map.put("key","sampleName")
      map.put("value", sampleName)
      data = CompositeDataSupport(rowType, map)
      jargs.put(data)
   
    files = mbs.invoke(mbeanName, "executeDump",
              jarray.array([name, None, jargs],java.lang.Object),
              jarray.array(["java.lang.String", "java.lang.String",
      "javax.management.openmbean.TabularData"],java.lang.String))

    outStream = FileOutputStream(outFile)
    buffer    = jarray.zeros(8192, 'b')

    sbeanName   = ObjectName(streamStr)
    streamClass = Class.forName("oracle.as.management.streaming.StreamingMBean")
    streamBean  = MBeanServerInvocationHandler.newProxyInstance(mbs,
					sbeanName, streamClass, 1==0)

    content = mbs.invoke(mbeanName, "getDumpContents",
         jarray.array([files, toZip], Object),
         jarray.array(["[Ljava.lang.String;", "boolean"], java.lang.String))

    stream = MBeanInputStream (content, streamBean)

    # output the content of the dump
    reader    = BufferedInputStream(stream)
    bytesRead = reader.read(buffer)
    totalWrite = 0
    while bytesRead != -1:
      outStream.write(buffer, 0, bytesRead)
      totalWrite += bytesRead
      bytesRead = reader.read(buffer)

    if not outStream is None:
      outStream.close()
    if not stream is None:
      stream.close()

    buf = StringBuffer()
    buf.append("wrote ")
    buf.append(totalWrite)
    buf.append(" bytes to " + outFile + "\n")
    return buf.toString()

  """
  Private methods
  =======================================================================
  """

  # format and display the formation for an problem list
  def _printProblemList(self, problems):
    buf = StringBuffer()
    buf.append( "Problem Id \tProblem Key\n")
    for problem in problems:
      buf.append("\t" + problem.get("problemId") + "\t" + 
		     problem.get("problemKey") + "\n")
    return buf.toString()

  # retrieve a list of incidents associated with a particular problem id
  # from the server
  def _listIncidents(self, mbs, home, problemId, mbeanName):
    if home is None: 
      incidents = mbs.invoke(mbeanName, "getIncidents",
	      jarray.array([problemId], String),
			     jarray.array(["java.lang.String"],String))
    else:
      incidents = mbs.invoke(mbeanName, "getIncidents",
	  jarray.array([home, problemId], String),
	      jarray.array(["java.lang.String", "java.lang.String"],String))
    return incidents

  # compare incidents to sort by time stamp most recent listed first
  def _compareIncidents(self, incident1, incident2):
    date1 = incident1.get("timeOfIncident")
    date2 = incident2.get("timeOfIncident")

    return date1.compareTo(date2) * -1

  # format and display the formation for an incident
  def _printIncident(self, incident):
    if incident is None:
     return None

    buf = StringBuffer()

    errMsg    = incident.get("errorMessage")
    floodCont = incident.get("floodControlled")
    dumpFiles = incident.get("incidentFiles")


    buf.append("Incident Id: " + incident.get("incidentId"))
    buf.append("\n")
    buf.append("Problem Id: " + incident.get("problemId"))
    buf.append("\n")
    buf.append("Problem Key: " + incident.get("problemKey"))
    buf.append("\n")
    buf.append("Incident Time:")
    buf.append(incident.get("timeOfIncident"))
    buf.append("\n")
    buf.append("Error Message Id: ")
    buf.append(errMsg.get("messageId"))
    buf.append("\n")
    buf.append("Execution Context:")
    buf.append(incident.get("executionContextId"))
    buf.append("\n")
    if floodCont is 1:
      buf.append("Flood Controlled: true")
    else:
      buf.append("Flood Controlled: false")
    buf.append("\n")
    buf.append("Dump Files :")
    buf.append("\n")
    for file in dumpFiles:
      buf.append("   ")
      buf.append( file)
      buf.append("\n")
    return buf.toString()

  # format and display the formation for an incident list
  def _printIncidentList(self, incidents):
    buf = StringBuffer()
    buf.append("Incident Id \tProblem Key \t\t Incident Time\n")
    for incident in incidents:
      buf.append("\t" + incident.get("incidentId") + "\t" +
	 incident.get("problemKey") + "\t")
      buf.append(incident.get("timeOfIncident"))
      buf.append("\n")
    return buf.toString()

  # format and display the DumpSampleInfo for a DumpSample
  def _printDumpSampleInfo(self, dumpSampleInfo):
    if dumpSampleInfo is None:
     return None

    buf = StringBuffer()
    name                = dumpSampleInfo.get("sampleName")
    diagnosticDumpName  = dumpSampleInfo.get("diagnosticDumpName")
    appName             = dumpSampleInfo.get("appName")
    samplingInterval    = dumpSampleInfo.get("samplingInterval")
    rotationCount       = dumpSampleInfo.get("rotationCount")
    dumpedImplicitly    = dumpSampleInfo.get("dumpedImplicitly")
    toAppend            = dumpSampleInfo.get("toAppend")
    dumpArguments       = dumpSampleInfo.get("dumpArguments")

    buf.append("Name              : " + name)
    buf.append("\n")
    buf.append("Dump Name         : " + diagnosticDumpName)
    buf.append("\n")
    buf.append("Application Name  : ")
    if not appName is None:
      buf.append(appName)
    buf.append("\n")
    buf.append("Sampling Interval : ")
    buf.append(samplingInterval)
    buf.append("\n")
    buf.append("Rotation Count    : ")
    buf.append(rotationCount)
    buf.append("\n")
    buf.append("Dump Implicitly   : ")
    if dumpedImplicitly:
      buf.append("true")
    else:
      buf.append("false")
    buf.append("\n")
    buf.append("Append Samples    : ")
    if toAppend:
      buf.append("true")
    else:
      buf.append("false")
    buf.append("\n")
    buf.append("Dump Arguments    : ")
    if not dumpArguments is None:
      i = 0
      for arg in dumpArguments:
        if i > 0:
          buf.append(", ")
        buf.append(arg.get("name"))
        buf.append("=")
        buf.append(arg.get("value"))
        i = i + 1

    buf.append("\n")
    return buf.toString()

  def _formatList(self, dumps, msgKey):
    if not dumps is None:
      buf = StringBuffer()
      for dump in dumps:
	buf.append(dump)
	buf.append("\n")
      buf.append("\n" + self.oraDfwGetMsg(msgKey))
      return buf.toString()
    else:
      return ""


  def _getMsgConst(self, name):
    bClass = Class.forName(self.CONSTFILE)

    return bClass.getField(name).get(name)

    # create a TabularData object for the executeDump arguments
  def  _buildJArgs(self, args):
    if args is None:
      return None

    typeName = "java.util.Map<java.lang.String, java.lang.String>"
    keyArr = ["key"]
    keyValue = ["key", "value"]
    openType = [SimpleType.STRING, SimpleType.STRING]
    rowType = CompositeType(typeName, typeName, keyValue, keyValue, openType)
    tabType = TabularType(typeName, typeName, rowType, keyArr)
    tabData = TabularDataSupport(tabType)

    for key in args.keys():
      map = HashMap(2)
      map.put("key",key)
      map.put("value", args.get(key))
      data = CompositeDataSupport(rowType, map)
      tabData.put(data)

    return tabData

 
  def _verifyParams(self, kws, nameList):
    if kws is None:
      return None

    for key, value in kws.items():
      if key not in nameList:
	raise DfwError, self.oraDfwGetMsg(self.UNEXPECTED_PARAM, key)

  def __init__(self):
    # mbean objectNames
    self.INCIDENT_MANAGER="oracle.dfw:type=oracle.dfw.jmx.IncidentManagerMXBean,name=IncidentManager"
    self.DUMP_MANAGER="oracle.dfw:type=oracle.dfw.jmx.DumpManagerMXBean,name=DumpManager"
    self.STREAMER    = "oracle.dfw:type=oracle.dfw.jmx.Streaming,name=Streamer"
    self.DIAGNOSTICS_CONFIG = "oracle.dfw:type=oracle.dfw.jmx.DiagnosticsConfigMBean,name=DiagnosticsConfig"
    self.ERRORFILE = "oracle.dfw.resource.DiagnosticTranslation"
    self.CONSTFILE = "oracle.dfw.resource.DiagnosticConstants"
    self.MSGFILE   = "oracle.as.management.logging.messages.CommandHelp"

    # command line argument keys
    self.NAME         = "name"
    self.SAMPLENAME   = "sampleName"
    self.ADRHOME      = "adrHome"
    self.APPNAME      = "appName"
    self.INCIDENTID   = "id"
    self.PROBLEMID    = "id"
    self.OUTPUTFILE   = "outputFile"
    self.ZIPOUTPUT    = "zipOutput"
    self.ARGS         = "args"
    self.ECID         = "ecid"
    self.DESCRIPTION  = "description"
    self.MESSAGEID    = "messageId"
    self.INCIDENTTIME = "incidentTime"
    self.SERVER       = "server"
    self.ENABLE       = "enable"
    self.PERSIST      = "persist"
    self.DIAGNOSTIC_DUMP_NAME = "diagnosticDumpName" 
    self.SAMPLING_INTERVAL    = "samplingInterval"
    self.ROTATION_COUT        = "rotationCount"  
    self.DUMP_IMPLICITLY      = "dumpedImplicitly"
    self.TO_APPEND            = "toAppend"

    # message keys
    self.NOT_CONNECTED         = self._getMsgConst("DFW_WLST_NOT_CONNECTED")
    self.MISSING_ARG           = self._getMsgConst("DFW_WLST_MISSING_ARGUMENT")
    self.MISSING_ARG_1         = self._getMsgConst("DFW_WLST_MISSING_ARGUMENT_1")
    self.UNEXPECTED_PARAM      = self._getMsgConst("DFW_WLST_UNEXPECTED_PARAM")
    self.EXECUTEDUMP_IOEX      = self._getMsgConst("DFW_WLST_EXECUTEDUMP_IO")
    self.EXECUTEDUMP_EX        = self._getMsgConst("DFW_WLST_EXECUTEDUMP")
    self.INCIDENT_MGR_DISABLED = self._getMsgConst("DFW_WLST_INCIDENT_MGR_DISABLED")
    self.DESCRIBEDUMP_MSG      = self._getMsgConst("DFW_WLST_DESCRIBEDUMP_MSG")
    self.SERVER_NOT_FOUND      = self._getMsgConst("DFW_WLST_SERVER_NOT_FOUND")
    self.WRONG_SERVER          = self._getMsgConst("DFW_WLST_WRONG_SERVER")
    self.UNSUPPORTED_SERVER    = self._getMsgConst("DFW_WLST_UNSUPPORTED_SERVER")
    self.OAS_NOT_UP            = self._getMsgConst("DFW_WAS_ORACLEADMINSERVER_NOT_UP")
    self.MORE_ARGUMENTS_NEED   = self._getMsgConst("DFW_WLST_MORE_ARGUMENTS_NEED")
    self.MAN_SERVER            = self._getMsgConst("DFW_WLST_MAN_SERVER")
    self.RELOAD_SUCCESS        = self._getMsgConst("DFW_WLST_RELOAD_SUCCESS")
    self.RELOAD_FAILURE        = self._getMsgConst("DFW_WLST_RELOAD_FAILURE")
    
class DfwError(Exception):
 msg = ""
 def __init__(self, msg):
   self.msg = msg

 def getMsg(self):
   return self.msg

