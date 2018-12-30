"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Define common handler for Oracle DMS commands for WebLogic and WebSphere

Caution: This file is part of the wsadmin implementation. Do not edit or move
this file because this may cause wsadmin commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your wsadmin scripts to fail when you upgrade to a different
version of wsadmin.

"""
from java.io import File
from java.io import FileWriter
from java.io import ObjectInputStream
from java.io import StringWriter
from java.lang import Class
from java.lang import Object
from java.lang import String
from java.lang import StringBuilder
from java.text import MessageFormat
from java.util import HashMap
from java.util import HashSet
from java.util import Locale 
from java.util import Map
from java.util import ResourceBundle
from javax.management import ReflectionException
from javax.management import InstanceNotFoundException
from javax.management import MBeanException
from javax.management import RuntimeMBeanException
from javax.management.openmbean import CompositeDataSupport
from javax.management.openmbean import CompositeType
from javax.management.openmbean import SimpleType
from javax.management.openmbean import TabularDataSupport
from javax.management.openmbean import TabularType
from types import DictionaryType
from types import ListType
from types import StringType
from types import TupleType

from oracle.as.management.streaming import MBeanInputStream
from oracle.dms.event.config import Destination
from oracle.dms.util import Time
from oracle.dms.util import ReadLine

import javax.management.openmbean
import java.lang
import jarray
import ora_help
import ora_mbs
import ora_util
import os
import sys
import random


# Event Tracing Constants
_indent = "   " # used in print formatting
PARAM_ID = "id"
PARAM_FILTER_ID = "filterid"
PARAM_DESTINATION_ID = "destinationid"
PARAM_NAME = "name"
PARAM_ETYPES = "etypes"
PARAM_CLASS = "class"
PARAM_PROPS = "props"
PARAM_CONDITION = "condition"
PARAM_SERVER = "server"
PARAM_ENABLE = "enable"

# streaming constant params
STRING_ARRAY_CLASS = Class.forName("[Ljava.lang.String;");
ZERO_LONG_ARRAY = jarray.array([0L], 'l')

def oracledms_init_help():
    try:
        # throw exception if called more than once
        ora_help.addHelpCommandGroup("fmw diagnostics", "oracle.as.management.logging.messages.CommandHelp")
    except:
        pass
    ora_help.addHelpCommand("displayMetricTableNames", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("dumpMetrics", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("displayMetricTables", "fmw diagnostics", online="true")
    
    # Event Tracing
    ora_help.addHelpCommand("listDMSEventConfiguration", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("enableDMSEventTrace", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("listDMSEventDestination", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("addDMSEventDestination", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("updateDMSEventDestination", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("removeDMSEventDestination", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("listDMSEventFilter", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("addDMSEventFilter", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("updateDMSEventFilter", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("removeDMSEventFilter", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("listDMSEventRoutes", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("addDMSEventRoute", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("updateDMSEventRoute", "fmw diagnostics", online="true")
    ora_help.addHelpCommand("removeDMSEventRoute", "fmw diagnostics", online="true")
    
    # internal command
    ora_help.addHelpCommand("reloadMetricRules", "fmw diagnostics")


def oracledms_getMsg_withBoundle(key, bundle, args=[]):
    try:
        rb = ResourceBundle.getBundle(bundle, Locale.getDefault(), Class.forName(bundle).getClassLoader())
        if rb.containsKey(key):
            msg = rb.getString(key)
            return MessageFormat.format(msg, jarray.array(args, String))
    except:
        pass
    return key

def oracledms_getMsg(key, *args):
    bundle = "oracle.as.management.logging.messages.Messages"
    return oracledms_getMsg_withBoundle(key, bundle, args)


def oracledms_help_internalCommand(cmd):
    """
    Display help for internal command.
    Names of internal commands should not be listed. But if you know the name of
    a internal command, you should be able to print help for the command.
    """
    bundle = "oracle.as.management.logging.messages.CommandHelp"
    return (oracledms_getMsg_withBoundle(cmd + "_description", bundle) +
            "\n" + oracledms_getMsg("SYNTAX") + ":\n\n" +
            oracledms_getMsg_withBoundle(cmd + "_syntax", bundle) +
            "\n" + oracledms_getMsg("EXAMPLE") + ":\n\n" +
            oracledms_getMsg_withBoundle(cmd + "_example", bundle))


def oracledmsVerifyConnect():
    if ora_mbs.isWebLogic():
        if mbs is None:
            raise WLSTException, oracledms_getMsg("NOT-CONNECTED", oracledms_getPlatformName())
    elif not ora_mbs.isConnected():
        raise AssertionError, oracledms_getMsg("NOT-CONNECTED", oracledms_getPlatformName())

def _oracledmsEventVerifyParameters(kws, validNames):
    if kws is not None:
        for key, value in kws.items():
            if key not in validNames:
                raise DmsError, oracledms_getMsg("UNEXPECTED-PARAM", key)
	    if key == PARAM_ENABLE:
	       if value != "true" and value !="false":
       	          raise DmsError, _oracledms_getETraceMsg("BAD-ENABLE")
	    # Needed for bug 9840128
            if type(value) != type('') :
	       if key != PARAM_PROPS and key != PARAM_ETYPES:
	          raise NameError, "unrecognised data type '" + str(type(value)) + "' for parameter '" + key + "'"


def oracledmsVerifyParameters(kws, validNames):
    if kws is not None:
        for key, value in kws.items():
            if key not in validNames:
                raise ValueError, oracledms_getMsg("UNEXPECTED-PARAM", key)


def oracledmsGetEnvRefreshAll():
    envNoCache = HashMap()
    envNoCache.put("oracle.dms.jmx.prefetch", "false")
    envNoCache.put("oracle.dms.jmx.querytype", "all")
    envNoCache.put("oracle.dms.jmx.usecache", "refreshall")
    envNoCache.put("oracle.dms.jmx.command", "true")
    return envNoCache


def oracledmsGetEnvNoCache():
    envNoCache = HashMap()
    envNoCache.put("oracle.dms.jmx.prefetch", "false")
    envNoCache.put("oracle.dms.jmx.querytype", "all")
    envNoCache.put("oracle.dms.jmx.usecache", "false")
    envNoCache.put("oracle.dms.jmx.command", "true")
    return envNoCache


def oracledmsGetEnvSchemaNoCache():
    envNoCache = HashMap()
    envNoCache.put("oracle.dms.jmx.prefetch", "false")
    envNoCache.put("oracle.dms.jmx.querytype", "schema")
    envNoCache.put("oracle.dms.jmx.usecache", "false")
    envNoCache.put("oracle.dms.jmx.command", "true")
    return envNoCache


def oracledmsGetAggreMBean():
    spies = ora_mbs.makeObjectName("oracle.dms:name=AggreSpy,type=Spy,*")
    dmsOraMbs = oracledmsGetOraMbs()
    set = dmsOraMbs.queryNames(spies, None);
    if set.size() > 0:
        return set.iterator().next()
    else:
        spies = ora_mbs.makeObjectName("oracle.dms:name=Spy,type=Spy,*")
        set = dmsOraMbs.queryNames(spies, None);
        if set.size() > 0:
            return set.iterator().next()
        else:
            raise AssertionError, oracledms_getMsg("SPYMBEAN-NOT-FOUND")


# name parameter name
# arg parameter value
def oracledmsGetArgumentList(name, value):
    if value is None:
        return None
    elif isinstance(value, StringType):
        return jarray.array([value], String)
    elif isinstance(value, ListType) or isinstance(value, TupleType):
        for v in value:
            if v is None:
                raise ValueError, oracledms_getMsg("NULL-PARAM", name)
        return jarray.array(value, String)
    else:
        raise ValueError, oracledms_getMsg("STRING-PARAM", name)


def _oracledmsEventHandleMBeanException(error):
    mesg=None
    if ora_mbs.isJBoss():
       mesg = error.getMessage()
       raise DmsError, mesg
    else:
       exp = error.getTargetException()
       if ora_mbs.isWebLogic():
           setDumpStackThrowable(exp)
       mesg = str(exp)
       raise DmsError, mesg + "\n" + oracledms_getMsg("STACK-INFO", "dumpStack()")


def oracledmsHandleException(error):
    mesg = None
    if isinstance(error, java.lang.Exception):
        mesg = error.getMessage()
    else:
        mesg = str(type(error)) + " " + str(error)
    if ora_mbs.isWebLogic():
        setDumpStackThrowable(error)
        mesg = mesg + "\n" + oracledms_getMsg("STACK-INFO", "dumpStack()")
        cause = None
        if isinstance(error, java.lang.Exception):
            cause = error.getCause()
        if cause is not None:
            from weblogic.socket import MaxMessageSizeExceededException
            if isinstance(cause, MaxMessageSizeExceededException):
                oracledmsPrintErrorMessage(oracledms_getMsg("LIMIT-METRICS"))
    exc_type, exc_value, exc_tb = sys.exc_info()
    raise RuntimeError, mesg, exc_tb


def oracledmsHandleMBeanException(error):
    exp = error.getTargetException()
    oracledmsHandleException(exp)


def oracledmsPrintErrorMessage(mesg):
    """
    bug #9577091 
    """
    if ora_mbs.isWebSphere():
        print mesg
    else:
        print >> sys.stderr, mesg


def oracledmsMetricTableToString(table):
    if table is None:
        return None;
    if table.containsKey("Table"):
        tableName = table.get("Table")
    if tableName is None or tableName.strip() == "":
        return ""
    buf = StringWriter()
    # print table name
    for c in tableName:
        buf.write('-')
    buf.write('\n')
    buf.write(tableName)
    buf.write('\n')
    for c in tableName:
        buf.write('-')
    buf.write('\n')
    rows = None 
    if table.containsKey("Rows"):
        rows = table.get("Rows")
    if rows is None:
        return buf.toString()
    
    schema = None
    if table.containsKey("Schema"):
        schema = table.get("Schema")
    
    rowCollection = rows.values()
    if rowCollection is None:
        return buf.toString()
    
    for row in rowCollection:
        buf.write('\n')
        columns = row.getCompositeType().keySet()
        for column in columns:
            value = row.get(column)
            if value is None:
                continue
            
            unit = None
            if schema is not None:
                cdesc = schema.get(jarray.array([column], String))
                if cdesc is not None and cdesc.containsKey("Unit"):
                    unit = cdesc.get("Unit")
            
            buf.write(column)
            buf.write(":\t")
            if value is None:
                buf.write("null")
            else:
                buf.write(str(value))
            if unit is not None and unit.strip() != "":
                buf.write('\t')
                buf.write(unit)
            buf.write('\n')
    
    return buf.toString()


def oracledmsNoOpDisplayHook(dummy):
    """
    no op display hook
    """
    pass


def oracledmsHideDisplayReturnValue():
    """
    hides the display of return value
    """
    sys.displayhook = oracledmsNoOpDisplayHook


def oracledmsLocationKey():
    """
    location property key in SpyMBean
    """
    if ora_mbs.isWebLogic():
        return "Location"
    elif ora_mbs.isWebSphere():
        return "process"
    elif ora_mbs.isJBoss():
        return "process"
    else:
        return "unknown"


def oracledmsGetOraMbs ():
    """
    platform generic get mbs object This is to workaround the problem
    if missing states in WebLogic ora_mbs module
    """
    if ora_mbs.isWebLogic():
        return mbs
    else:
        return ora_mbs.getMbsInstance()


def oracledmsGetOutputFile (kws):
    """
    prepare output file name
    """
    outputFileName = kws.get("outputfile")
    outputFile = None
    if outputFileName is not None:
        outputFile = File(outputFileName)
        if outputFile.exists() and not outputFile.canWrite():
            raise ValueError, oracledms_getMsg("FILE-NOT-WRITABLE", outputFileName)
    return outputFile


# start command implementation

def oracledmsDisplayMetricTableNames(kws):
    """
    display DMS metric table names
    """
    
    oracledmsVerifyConnect()
    oracledmsVerifyParameters(kws, ("servers", "outputfile"))
    spy = oracledmsGetAggreMBean()
    
    servers = kws.get("servers")
    serverArray = oracledmsGetArgumentList("servers", servers)

    outputFile = oracledmsGetOutputFile(kws)

    dmsOraMbs = oracledmsGetOraMbs()
    try:
        names = dmsOraMbs.invoke(spy, "getTableNames", 
            jarray.array([0L, 0L, serverArray, oracledmsGetEnvSchemaNoCache()],
                          Object),
            jarray.array(["java.lang.Long", "java.lang.Long",
                          "[Ljava.lang.String;",
                          "java.util.Map"], String))
        if outputFile is None:
            for name in names:
                print name
        else:
            fout = FileWriter(outputFile)
            try:
                for name in names:
                    fout.write(name)
                    fout.write("\n")
                    fout.flush()
            finally:
                fout.close()
            print oracledms_getMsg("WRITE-OUTPUT-FILE", outputFile.toString())
    except MBeanException, error:
        oracledmsHandleMBeanException(error)
    except ReflectionException, error:
        oracledmsHandleMBeanException(error)
    except RuntimeMBeanException, error:
        oracledmsHandleMBeanException(error)
    except Exception, error:
        oracledmsHandleException(error)

    ora_util.hideDisplay()
    return names


def oracledmsDumpMetrics(kws):
    """
    display internal DMS metrics
    """
    
    oracledmsVerifyConnect()
    oracledmsVerifyParameters(kws, ("servers", "format", "outputfile"))
    spy = oracledmsGetAggreMBean()
    
    servers = kws.get("servers")
    serverArray = oracledmsGetArgumentList("servers", servers)
    
    format = kws.get("format")
    if format is None:
        format = "raw"
    elif format != "raw" and format != "xml" and format != "pdml":
        raise ValueError, oracledms_getMsg("WRONG-FORMAT-VALUE")
    
    outputFile = oracledmsGetOutputFile(kws)

    querystring = "operation=get&value=true&units=true&description=true&format=" + format
    dmsOraMbs = oracledmsGetOraMbs()
    try:
        dumpHandle = dmsOraMbs.invoke(spy, "metricDumpHandle", 
            jarray.array([querystring, serverArray, oracledmsGetEnvRefreshAll()],
                          Object),
            jarray.array(["java.lang.String", "[Ljava.lang.String;",
                          "java.util.Map"], String))
        din = None
        try:
            din = MBeanInputStream(dumpHandle, dmsOraMbs, spy, 10000)
            odin = ReadLine.read(din)
            dump = odin.toString()
        finally:
            if din is not None:
                din.close()
        if outputFile is None:
            print dump
        else:
            fout = FileWriter(outputFile)
            try:
                fout.write(dump)
                fout.flush()
            finally:
                fout.close()
            print oracledms_getMsg("WRITE-OUTPUT-FILE", outputFile.toString())
    except MBeanException, error:
        oracledmsHandleMBeanException(error)
    except ReflectionException, error:
        oracledmsHandleMBeanException(error)
    except RuntimeMBeanException, error:
        oracledmsHandleMBeanException(error)
    except Exception, error:
        oracledmsHandleException(error)
    
    ora_util.hideDisplay()
    return dump


def oracledmsDisplayMetricTables(names, kws):
    """
    display DMS metric tables
    """
    
    oracledmsVerifyConnect()
    oracledmsVerifyParameters(kws, ("servers", "variables", "outputfile"))
    spy = oracledmsGetAggreMBean()
    
    servers = kws.get("servers")
    serverArray = oracledmsGetArgumentList("servers", servers)
    nameArray = oracledmsGetArgumentList("table names", names)
    
    variables = kws.get("variables")
    variableMap = None
    if variables is not None:
        if isinstance(variables, DictionaryType):
            variableMap = HashMap()
            for key, value in variables.items():
                variableMap.put(key, value)
        else:
            raise ValueError, oracledms_getMsg("WRONG-VARIABLE-VALUE")
 
    outputFile = oracledmsGetOutputFile(kws)

    dmsOraMbs = oracledmsGetOraMbs()
    try:
        tableHandle = dmsOraMbs.invoke(spy, "tableGroupsOpenTypeHandle", 
            jarray.array([jarray.array([nameArray], STRING_ARRAY_CLASS),
                          ZERO_LONG_ARRAY,
                          ZERO_LONG_ARRAY,
                          jarray.array([variableMap], Map), 
                          jarray.array([serverArray], STRING_ARRAY_CLASS),
                          jarray.array([oracledmsGetEnvNoCache()], Map)],
                         Object),
            jarray.array(["[[Ljava.lang.String;",
                          "[Ljava.lang.Long;",
                          "[Ljava.lang.Long;",
                          "[Ljava.util.Map;",
                          "[[Ljava.lang.String;",
                          "[Ljava.util.Map;"],
                         String))
        din = None
        try:
            din = MBeanInputStream(tableHandle, dmsOraMbs, spy, 10000)
            odin = ObjectInputStream(din)
            tabless = odin.readObject()
        finally:
            if din is not None:
                din.close()
    except MBeanException, error:
        oracledmsHandleMBeanException(error)
    except ReflectionException, error:
        oracledmsHandleMBeanException(error)
    except RuntimeMBeanException, error:
        oracledmsHandleMBeanException(error)
    except Exception, error:
        oracledmsHandleException(error)
    
    handled = HashSet();
    i = 0
    for tables in tabless:
        try:
            fout = None
            try:
                if outputFile is not None:
                    fout = FileWriter(outputFile)
                for table in tables:
                    if table is None:
                        if nameArray is not None and i < len(nameArray):
                            oracledmsPrintErrorMessage(oracledms_getMsg("METRIC-NOT-FOUND", nameArray[i]))
                    elif not handled.contains(table):
                        handled.add(table)
                        tablecontent = oracledmsMetricTableToString(table)
                        if fout is None:
                            print tablecontent
                        else:
                            fout.write(tablecontent)
                            fout.write("\n")
                            fout.flush()
                    i = i + 1
                if fout is not None:
                    print oracledms_getMsg("WRITE-OUTPUT-FILE", outputFile.toString())
            finally:
                if fout is not None:
                    fout.close()
        except Exception, error:
            oracledmsHandleException(error)
        ora_util.hideDisplay()
        return tables


def oracledmsReloadMetricRules(kws):
    """
    reload metric rules completely
    """
    
    oracledmsVerifyConnect()
    oracledmsVerifyParameters(kws, ())
    ret = []
    if ora_mbs.isWebLogic():
        current = pwd()
        try:
            domainRuntime()
        except:
            pass
    
    try:
        spyObjectName = ora_mbs.makeObjectName("oracle.dms:type=Spy,name=Spy,*")
        aggreSpyObjectName = ora_mbs.makeObjectName("oracle.dms:type=Spy,name=AggreSpy,*")
        dmsOraMbs = oracledmsGetOraMbs()
        spies = dmsOraMbs.queryNames(spyObjectName, None)
        aggreSpies = dmsOraMbs.queryNames(aggreSpyObjectName, None)
        allSpies = []
        if spies is not None:
            for spy in spies:
                allSpies.append(spy)
        # aggreSpy must be last
        if aggreSpies is not None:
            for spy in aggreSpies:
                allSpies.append(spy)
        if len(allSpies) ==0:
            raise AssertionError, oracledms_getMsg("SPYMBEAN-NOT-FOUND")
        locationKey = oracledmsLocationKey()
        for spy in allSpies:
            try:
                try:
                    results = dmsOraMbs.invoke(spy, "reloadMetricRules", 
                      jarray.array([oracledmsGetEnvSchemaNoCache()],
                                   Object),
                      jarray.array(["java.util.Map"], String))
                except MBeanException, error:
                    oracledmsHandleMBeanException(error)
                except ReflectionException, error:
                    oracledmsHandleMBeanException(error)
                except RuntimeMBeanException, error:
                    oracledmsHandleMBeanException(error)
                except Exception, error:
                    oracledmsHandleException(error)
                
                location = spy.getKeyProperty(locationKey)
                if results is None or len(results) == 0:
                    if location is None:
                        oracledmsPrintErrorMessage(oracledms_getMsg("NO-ADML"))
                    else:
                        oracledmsPrintErrorMessage(oracledms_getMsg("ADML-NOT-FOUND", location))
                else:
                    # results is an array of composite data with
                    # two fields, MetricRule and IsSuccess
                    for result in results:
                        ret.append(result)
                        name = result.get("MetricRule")
                        isSuccess = result.get("IsSuccess")
                        isWarning = result.get("IsWarning")
                        if not isSuccess:
                            oracledmsPrintErrorMessage(oracledms_getMsg("LOADED-ADML-FAILED", name))
                        elif isWarning:
                            print oracledms_getMsg("LOADED-ADML-WARNING", name)
                        else:
                            print oracledms_getMsg("LOADED-ADML", name)
                    if location is None:
                        print oracledms_getMsg("RELOADED-ADML")
                    else:
                        print oracledms_getMsg("RELOADED-SERVER-ADML", location)
                    print ""
            except RuntimeError, error:
                oracledmsPrintErrorMessage(str(error))
            except Exception, error:
                oracledmsPrintErrorMessage(error.getMessage())
    finally:
        if ora_mbs.isWebLogic():
            cd(current)
    ora_util.hideDisplay()
    return ret


def oracledms_getPlatformName():
    """
    get the name of platform
    """
    
    if ora_mbs.isWebLogic():
        return "Weblogic"
    elif ora_mbs.isWebSphere():
        return "WebSphere"
    elif ora_mbs.isJBoss():
        return "JBoss"
    raise "Invalid platform"


# Event Tracing

# Helper to extract ServerName from obj
def getServerNameFromObject(obj):
   server = None
   seq = obj.split(',')
   for x in seq:
      if x.find('ServerName') > -1 :
         serverSeq = x.split('=')
         server = serverSeq[1]
   return server

# helper to validate the type of a parameter is 'dictionary'
def _oracledmsValidateDictionary(d):
   if type(d) != type({}):
      raise DmsError, _oracledms_getETraceMsg("BAD-DICT")

# helper to validate the parameters in a dictionary
def _oracledmsVerifyProps(props, nameList):
   
   _oracledmsValidateDictionary(props)
   for key in nameList:
      if not props.has_key(key):
       	 raise DmsError, _oracledms_getETraceMsg("MISSING-PROP", key)


# helper to return a message
def _oracledms_getETraceMsg(key, *args):
   bundle = "oracle.dms.trace.TraceResourceBundle"
   a = oracledms_getMsg_withBoundle(key, bundle, args)
   ora_util.hideDisplay()
   return a

# helper to convert a string true/false to a numeric 1/0 that the version of
# Jython understands that is shipped with WAS. 
def _convertBoolToNum(bool):
   # check type is a string, and not already an int 
   # (which is what a boolean is represented as
   if type(bool) != type("string") and type(bool) != type(None):
       	raise DmsError, _oracledms_getETraceMsg("BAD-ENABLE")
   if bool == None:
      retVal = None
   elif bool == "true":
      retVal = 1
   else:
      retVal = 0
   
   return retVal

# helper to get mbs or ora_mbs (varies on different platforms)
def _getDmbs():
    dmbs = None
    try:
       dmbs = mbs
    except NameError:
       dmbs = ora_mbs
    return dmbs


#helper - print out two strings in column format
def _cprint(c1, c2):
    """
    Take two strings, and return a single string of two columns
    padded with spaces. The first column indented by 3
    """
    
    if c1 == None:
       c1 = " "
    if c2 == None:
       c2 = " "
    
    c1 = _indent + c1 # indent by 3 characters
    
    cwidth = 40 # columns width
    
    # if string would be larger than first column, trim it
    length1 = len(c1)
    if length1 > cwidth:
      c1 = c1[0:cwidth]
    length2 = len(c2)
    if length2 > cwidth:
      c2 = c2[0:cwidth]
    s1 = c1.ljust(cwidth) + c2.ljust(cwidth)
    print s1

# helper - main code to add a filter
def _addFilter(**kws):
    id = kws.get("id")
    name = kws.get("name")
    etypes = kws.get("etypes")
    props = kws.get("props")
    display = kws.get("display")	# true if output messages are to be displayed
    objectName = kws.get("objectName")
    serverName = kws.get("serverName")
    
    if id==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "id")
    if props==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "props")
    
    if _oracledmsFilterExists(objectName, id)==1:
       	raise DmsError, _oracledms_getETraceMsg("DUPE-FILTER", id, serverName)
    
    if props==None:
	props={}
    
    # add the filter
    jargs = _oracledms_buildJArgs(props)	# convert dict to HashMap
    dmbs = _getDmbs()
    try:
    	dmbs.invoke(objectName, "addFilter", jarray.array([id, name, etypes, jargs], java.lang.Object), jarray.array(["java.lang.String", "java.lang.String", "java.lang.String", "javax.management.openmbean.TabularData"], java.lang.String))
    	_oracledmsActivateDMSEventConfig(objectName)
        
	if display:
		print _oracledms_getETraceMsg("FILTER-ADDED", id, serverName)
    
    except MBeanException, error:
    	_oracledmsEventHandleMBeanException(error)
    except InstanceNotFoundException, error:
        raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    except RuntimeMBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except Exception, error:
        _oracledmsEventHandleMBeanException(error)

# helper - main code to add an event route
def _addRoute(**kws):
    
    filterid = kws.get("filterid")
    destinationid = kws.get("destinationid")
    enable = kws.get("enable")
    enable = _convertBoolToNum(enable)
    objectName = kws.get("objectName")
    serverName = kws.get("serverName")
    display = kws.get("display")
    
    # a None filterid is allowed. All DMS events are passed in this case
    if destinationid==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "destinationid")
    
    # check if route already exists in the config
    if _oracledmsEventRouteExists(objectName, filterid, destinationid) == 1:
       	raise DmsError, _oracledms_getETraceMsg("DUPE-ROUTE",  filterid, destinationid, serverName)
    # default to true, event-route enabled
    if enable==None:
	enable=1
    
    # add event route
    try:
        dmbs = _getDmbs()
    	dmbs.invoke(objectName, "addEventRoute", jarray.array([filterid, destinationid, enable], java.lang.Object), jarray.array(["java.lang.String", "java.lang.String", "boolean"], String))
    	_oracledmsActivateDMSEventConfig(objectName)
        
	if display:
		print _oracledms_getETraceMsg("ROUTE-ADDED", filterid, destinationid, serverName)
    except MBeanException, error:
    	_oracledmsEventHandleMBeanException(error)
    except InstanceNotFoundException, error:
        raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    except RuntimeMBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except Exception, error:
        _oracledmsEventHandleMBeanException(error)

# helper to get all event routes
def _oracledmsListAllEventRoutes(serverName, objectName, show):
    dmbs = _getDmbs()
    
    try:
       eventRoutes = dmbs.getAttribute(objectName,"AllEventRouteStatus")
    except MBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except InstanceNotFoundException, error:
        raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    except RuntimeMBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except Exception, error:
       _oracledmsEventHandleMBeanException(error)
    
    stringFormat = StringFormat()
    retVal = {}
    
    if eventRoutes:
        if show == 2:
           print _oracledms_getETraceMsg("EVENT-ROUTES")
        
    	values = eventRoutes.values()
        for v in values:
		dest = v.get("value").values()
		for d in dest:
			if show:
				print _indent + stringFormat._formatString("FILTER"), v.get("key")
				print _indent + stringFormat._formatString("DESTINATION"), d.get("key")
			if show:
				if d.get("value"):
					print _indent + stringFormat._formatString("ENABLED"), _oracledms_getETraceMsg("TRUE")
				else:
					print _indent + stringFormat._formatString("ENABLED"), _oracledms_getETraceMsg("FALSE")
                                print "\n"
                        
			existingDest={}
			# append any existing values for this key to the map
			# if they exist, together with the new value.
			# Otherwise add the new value
			if retVal.has_key(v.get("key")):
				existingDest = retVal.get(v.get("key"))
			existingDest.update({d.get("key"): d.get("value")})
			retVal.update({v.get("key"): existingDest})
    ora_util.hideDisplay()
    return retVal

# helper to update the destination
def _oracledmsUpdateDestination(destination, id, newName, newdClass, newProps):
    name = destination.getDestinationName()
    dclass = destination.getDestinationClassName()
    props = destination.getProperties()
    
    if name != newName and newName != None:
	destination.setDestinationName(newName)
    if dclass != newdClass and newdClass != None:
	destination.setDestinationClassName(newdClass)
    if props != newProps and newProps != None:
	# remove existing properties from Map
	keys=[]
        for key in props.keySet():
		keys.append(key)
	for key in keys:
        	destination.removeProperty(key)
        
	# add new properties from dict
       	for key,value in newProps.items():
               	destination.setProperty(key,value)
    
    ora_util.hideDisplay()
    return destination

# helper to get the condition String from the props dict
def _oracledmsGetCondition(props):
    condition=None
    if props != None:
    	for key,value in props.items():
    		if key.lower()=="condition":
			condition = value
			break
    
    ora_util.hideDisplay()
    return condition

# helper to update the filter
def _oracledmsUpdateFilter(objectName, filter, id, newName, newETypes, newProps):
    name = filter.get("filterName")
    if name != newName and newName != None:
	name = newName
    etypes = filter.get("eventTypes")
    if etypes != newETypes and newETypes != None:
        etypes = newETypes
    
    # get String condition from filter
    condition = None
    try:
        dmbs = _getDmbs()
    	condition = dmbs.invoke(objectName, "getFilterConditionAsString", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String))
    except MBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except Exception, error:
        _oracledmsEventHandleMBeanException(error)
    
    props = {}
    newCondition = _oracledmsGetCondition(newProps)
    
    if newProps==None:
	props={'condition':condition}
    if condition != newCondition and newCondition != None:
	props={'condition':newCondition}
    
    ora_util.hideDisplay()
    return name, etypes, props

#helper - handle an exception message
def _oracledms_getETraceExceptionMsg(t):
    msg = t.getMessage()
    if msg == None:
        msg = str(t)
    ora_util.hideDisplay()
    return msg + "\n" + _oracledms_getETraceMsg("STACK-INFO", "dumpStack()")

#helper - generate a unique filter id
def _oracledmsGenerateFilterID(objectName):
    max = 2147483646
    id = "auto" + str(random.randrange(1,max))
    while _oracledmsDestinationExists(objectName, id)==1:
    	id = random.randrange(1,max)
    ora_util.hideDisplay()
    return id

# helper to return a message
def _oracledms_getETraceMsg(key, *args):
    bundle = "oracle.dms.trace.TraceResourceBundle"
    a = oracledms_getMsg_withBoundle(key, bundle, args)
    ora_util.hideDisplay()
    return a

# helper to convert properties to tabular data
def  _oracledms_buildJArgs(args):
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
    
    ora_util.hideDisplay()
    return tabData

# helper to check if a specific route already exists in the config
def _oracledmsEventRouteExists(objectName, filterid, destinationid) :
    retVal=0
    
    try:
        dmbs = _getDmbs()
    	eventRoutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([destinationid,0], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
	if not eventRoutes.isEmpty():
    		values = eventRoutes.values()	# matching filters
        	for v in values:
    			if v.get("key") == filterid:
				retVal = 1
				break
    except MBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except Exception, error:
        _oracledmsEventHandleMBeanException(error)
    
    ora_util.hideDisplay()
    return retVal

# helper to check if filter already exists in the config
def _oracledmsFilterExists(objectName, id):
    try:
        dmbs = _getDmbs()
    	filter = dmbs.invoke(objectName, "getFilter", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String)) 
    	ora_util.hideDisplay()
    	if filter:
		return 1
    	else:
		return 0
    except MBeanException, error:
    	_oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except Exception, error:
        _oracledmsEventHandleMBeanException(error)

# helper to check if destination already exists in the config
def _oracledmsDestinationExists(objectName, id):
    try:
        dmbs = _getDmbs()
    	destination = dmbs.invoke(objectName, "getDestination", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String)) 
        ora_util.hideDisplay()
    	if destination:
		return 1
    	else:
		return 0
    except MBeanException, error:
    	_oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
        _oracledmsEventHandleMBeanException(error)
    except Exception, error:
       _oracledmsEventHandleMBeanException(error)

# helper to persist the configuration
def _oracledmsActivateDMSEventConfig(objectName):
        try:
	        dmbs = _getDmbs()
		dmbs.invoke(objectName, "activateConfiguration", None,None)
    	except MBeanException, error:
		raise error
    	except RuntimeMBeanException, error:
		raise error
    	except Exception, error:
        	_oracledmsEventHandleMBeanException(error)

#  Start of Event Trace main methods
def oracledmsEnableDMSEventTrace(obj,**kws):
    """
    Create a simple configuration in a single command

	enableDMSEventTrace(destinationid=<destinationid>, [etypes=<etypes>], [condition=<condition>], [server=<server>])

	Argument		Definition
	destinationid		The unique identifer for the specific destination. 
	                        Any existing destination is valid.
	                        Note: LoggerDestination is pre-seeded in dms_config.xml.
	etypes                  Optional. String containing a comma separated list of
	                        event/action pairs
	condition              	Optional. Condition to filter on. See 3.2.2.2 
	                        addFilter for details.
 				If no condition is specified, all DMS events will be 
			        passed
	server              	Optional. server to perform this operation on. 
                                Default to server currently connected to


    """
    _oracledmsEventVerifyParameters(kws, (PARAM_DESTINATION_ID, PARAM_ETYPES,PARAM_CONDITION, PARAM_SERVER))
    destinationid = kws.get("destinationid")
    etypes = kws.get("etypes")
    condition = kws.get("condition")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if destinationid==None:
        raise DmsError, _oracledms_getETraceMsg("MISSING-ARG", "destinationid")
    
    exists = _oracledmsDestinationExists(objectName, destinationid)
    
    if exists == 0:
       	raise DmsError, _oracledms_getETraceMsg("INVALID-DESTINATION",  destinationid, serverName)
    
    # add filter if a condition exists
    filterid = None	# pass all DMS events
    if condition:
    	filterid = _oracledmsGenerateFilterID(objectName)
    	name = "auto generated using enableEventTrace"
        
    	props = {'condition':condition}
    	_addFilter(id=filterid, name=name, etypes=etypes,  props=props, objectName=objectName, display=0, serverName=serverName)
    
    # add event route
    _addRoute(filterid=filterid, destinationid=destinationid, enable='true', objectName=objectName, display=0, serverName=serverName)
    _oracledmsActivateDMSEventConfig(objectName)
    print _oracledms_getETraceMsg("ROUTE-ENABLED", filterid, destinationid, serverName)

def oracledmsListDMSEventFilter(obj,**kws):
    """
    Return the configuration for specified filter, or list all filters if no id specified

	listDMSEventFilter([id=<id>],[server=<server>])

	Argument	Definition
	id		Optional. The unique identifer for the specific filter
	server 	        Optional. Server to perform this operation on. 
			Default to server currently connected to

	Return
	If an id is specified:-

	name, condition

	If an id is not specified:-

	{id: name}

	id		unique identifer for the specific filter
	name		name of the filter
	condition	string representation of the filters condition
	
    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_SERVER))
    id = kws.get("id")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    retVal={}
    stringFormat = StringFormat()
    
    if id:
       	filter = None
	
       	try:
       		filter = dmbs.invoke(objectName, "getFilter", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String))
    	except MBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except Exception, error:
       		_oracledmsEventHandleMBeanException(error)
	
	if filter:
       		name = filter.get("filterName")
		print stringFormat._formatString("ID") + id
		print stringFormat._formatString("NAME") + name
                
		etypes = filter.get("eventTypes")
                if etypes !=  None:
		   print stringFormat._formatString("EVENT_TYPES") + etypes
                
		condition = None
		dmbs = _getDmbs()
                
    		try:
			condition = dmbs.invoke(objectName, "getFilterConditionAsString", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String))
    		except MBeanException, error:
       			_oracledmsEventHandleMBeanException(error)
    		except RuntimeMBeanException, error:
       			_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
       			_oracledmsEventHandleMBeanException(error)
                
  		if condition != None:
			print stringFormat._formatString("PROPERTIES")
			print _indent + _indent + _oracledms_getETraceMsg("CONDITION") + " :"
                        print _indent + _indent + condition 
			ora_util.hideDisplay()
			return name, condition
		else:
			ora_util.hideDisplay()
			return name, None
	else:
        	raise DmsError, _oracledms_getETraceMsg("INVALID-FILTER", id, serverName)
	
    else:
        filters = None
	dmbs = _getDmbs()
	try:
		filters = dmbs.getAttribute(objectName,"Filters")
    	except MBeanException, error:
        	_oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
        	_oracledmsEventHandleMBeanException(error)
    	except Exception, error:
        	_oracledmsEventHandleMBeanException(error)
        
	if filters:
		_cprint( _oracledms_getETraceMsg("ID") , _oracledms_getETraceMsg("NAME"))
        	for filter in filters:
       			id = filter.get("filterId")
        		name = filter.get("filterName")
         		_cprint(id, name)
			retVal.update({id:name})
    
    ora_util.hideDisplay()
    return retVal

def oracledmsUpdateDMSEventDestination(obj,**kws):
    """
    Update any part of a destination in the Event Tracing configuration

	updateDMSEventDestination(id=<id>,[name=<name>],[class=<class>],[props= {'name': 'value'...}], [server=<server>])

	Argument	Definition
	Id		The unique identifer for the specific destination
	Name		Optional. Description of the destination
	class		The full classname of the Destination
	props		Optional. The name/value properties to use for the Destination. 
	                A property may not be removed, only updated or a new one added.
	server		Optional. server to perform this operation on. 
                        Default to server currently connected to


    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_NAME, PARAM_CLASS, PARAM_PROPS, PARAM_SERVER))
    
    id = kws.get("id")
    name = kws.get("name")
    dclass = kws.get("class")
    props = kws.get("props")
    if props != None:
       _oracledmsValidateDictionary(props)
    
    # Validate mandatory properties at some point in the future.
    # Uncomment this code when we have a way of detecting which mandatory properties 
    # a class has
    #if props != None:
       #_oracledmsVerifyProps(props, (PARAM_CONDITION,))
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if id==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "id")
    else:
       	currentDestination = None
	dmbs = _getDmbs()
       	try:
		currentDestination = dmbs.invoke(objectName, "getDestination", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String))
    	except MBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except Exception, error:
       		_oracledmsEventHandleMBeanException(error)
        
	if currentDestination != None:
		updatedDestination = _oracledmsUpdateDestination(currentDestination, id, name, dclass, props)	
    		# add the Destination to the config
 		try:
  			dmbs.invoke(objectName, "addDestination", jarray.array([updatedDestination], java.lang.Object), jarray.array(["oracle.dms.event.config.Destination"], String))
    			_oracledmsActivateDMSEventConfig(objectName)
    		except MBeanException, error:
        		_oracledmsEventHandleMBeanException(error)
    		except RuntimeMBeanException, error:
        		_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
        		_oracledmsEventHandleMBeanException(error)
                
		print _oracledms_getETraceMsg("DESTINATION-UPDATED", id, serverName)
	else:
		oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-DESTINATION", id, serverName))

def oracledmsUpdateDMSEventFilter(obj,**kws):
    """
    Update a filter in the Event Tracing configuration

	updateDMSEventFilter(id=<id>, [name=<name>], [etypes=<eventTypesString>], props= {'pname': 'pvalue'...}, [server=<server>])

	Argument	Definition
	name		Optional. name of the filter
	etypes          Optional. String containing a comma separated list of
	                event/action pairs. To  remove the etypes, use ''
	id		unique identifer for the specific filter
	props		Optional. Only one entry may exist.
        pname           The only valid pname is "condition"
        pvalue          A filter condition in the format of a string
			A property may not be removed, only updated.
	Server		Optional. server to perform this operation on. 
			Default to server currently connected to

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_NAME, PARAM_ETYPES, PARAM_PROPS, PARAM_SERVER))
    
    id = kws.get("id")
    name = kws.get("name")
    etypes =  kws.get("etypes")
    props = kws.get("props")
    if props != None:
       _oracledmsVerifyProps(props, (PARAM_CONDITION,))
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if id==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "id")
    
    currentFilter = None
    dmbs = _getDmbs()
    try:
    	currentFilter = dmbs.invoke(objectName, "getFilter", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String))
    except MBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except Exception, error:
       	_oracledmsEventHandleMBeanException(error)
    
    if currentFilter != None:
	newName, newEtypes, newProps = _oracledmsUpdateFilter(objectName, currentFilter, id, name, etypes, props)
        
    	# add the Filter to the config
    	jargs = _oracledms_buildJArgs(newProps)	# convert dict to HashMap
       	try:
    		dmbs.invoke(objectName, "addFilter", jarray.array([id, newName, newEtypes,jargs], java.lang.Object), jarray.array(["java.lang.String", "java.lang.String", "java.lang.String", "javax.management.openmbean.TabularData"], java.lang.String))
    		_oracledmsActivateDMSEventConfig(objectName)
    	except MBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except Exception, error:
       		_oracledmsEventHandleMBeanException(error)
        
	print _oracledms_getETraceMsg("FILTER-UPDATED", id, serverName)
    else:
	oracledmsPrintErrorMessage(_oracledms_getETraceMsg("INVALID-FILTER", id, serverName))

def oracledmsUpdateDMSEventRoute(obj,**kws):
    """
    Update an event-route in the Event Tracing configuration

	updateDMSEventRoute([filterid=<filterid>], destinationid=<destinationid>, [enable=<enable>], [server=<server>])

	Argument         	Definition
	filterid               	Optional. The unique identifer for the filter to wire up to 
				destinationid. Default: None
	destinationid		The unique identifer for the destination to wire up to filterid
	enable			"true" or "false". Default to "true"
	server			Optional. server to perform this operation on. 
				Default to server currently connected to

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_FILTER_ID, PARAM_DESTINATION_ID, PARAM_ENABLE, PARAM_SERVER))
    
    filterid = kws.get("filterid")
    destinationid = kws.get("destinationid")
    enable = kws.get("enable")
    enable = _convertBoolToNum(enable)
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if destinationid==None:
        raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "destinationid")
    # check if route already exists in the config
    if _oracledmsEventRouteExists(objectName, filterid, destinationid) == 1:
    	# default to true, event-route enabled
    	if enable==None:
        	enable=1
	
	# add event route
	dmbs = _getDmbs()
        try:
    		dmbs.invoke(objectName, "addEventRoute", jarray.array([filterid, destinationid, enable], java.lang.Object), jarray.array(["java.lang.String", "java.lang.String", "boolean"], String))
    		_oracledmsActivateDMSEventConfig(objectName)
		print _oracledms_getETraceMsg("ROUTE-UPDATED", filterid, destinationid, serverName)
        except MBeanException, error:
                _oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
        	_oracledmsEventHandleMBeanException(error)
    	except Exception, error:
        	_oracledmsEventHandleMBeanException(error)
    else:
        raise DmsError, _oracledms_getETraceMsg("INVALID-ROUTE",  filterid, destinationid, serverName)

def oracledmsRemoveDMSEventDestination(obj,**kws):
    """
    Remove a destination from the Event Tracing configuration

	removeDMSEventDestination(id=<id>, [server='server']) 

	Argument	Definition
	id		The unique identifier for the specific destination
	server	        Optional. server to perform this operation on. 
                        Default to server currently connected to


    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_SERVER))
    
    id = kws.get("id")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if id==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "id")
    else:
       	if _oracledmsDestinationExists(objectName, id)==1:
		# check if an event route exists for filter
               	eventroutes = None
		try:
			eventroutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([id,0], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
       		except MBeanException, error:
               		_oracledmsEventHandleMBeanException(error)
    		except RuntimeMBeanException, error:
       			_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
       			_oracledmsEventHandleMBeanException(error)

		if not eventroutes.isEmpty():
       			raise DmsError, _oracledms_getETraceMsg("DESTINATION-ROUTE-EXISTS", id, serverName)
		else:
			try:
       				dmbs.invoke(objectName, "removeDestination", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String)) 
    				_oracledmsActivateDMSEventConfig(objectName)
				print _oracledms_getETraceMsg("DESTINATION-REMOVED", id, serverName)
       			except MBeanException, error:
               			_oracledmsEventHandleMBeanException(error)
    			except RuntimeMBeanException, error:
       				_oracledmsEventHandleMBeanException(error)
    			except Exception, error:
       				_oracledmsEventHandleMBeanException(error)
	else:
       		raise DmsError, _oracledms_getETraceMsg("INVALID-DESTINATION",  id, serverName)

def oracledmsListDMSEventDestination(obj,**kws):
    """
    Return the configuration for the specified destination, or all destinations if unspecified

	listDMSEventDestination([id=<id>],[server=<server>])

	Argument	Definition
	id		Optional. The unique identifier for the specific destination 
	server	        Optional. Server to perform this operation on. 
                        Default to server currently connected to


	Return
	If an id is specified:-
	name, classname, {props}

	If an id is not specified:-
	{id, name}

	id		The unique identifier for the specific destination 
	name		Description of the destination
	class		The full classname of the Destination
	props		The name/value properties to use for the Destination


    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_SERVER))
    id = kws.get("id")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    stringFormat = StringFormat()
    
    if id:
	destination = None
        try:
           destination = dmbs.invoke(objectName, "getDestination", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String)) 
        except MBeanException, error:
           _oracledmsEventHandleMBeanException(error)
        except RuntimeMBeanException, error:
           _oracledmsEventHandleMBeanException(error)
        except Exception, error:
           _oracledmsEventHandleMBeanException(error)
        
	if destination:
		name = destination.getDestinationName()                
 		classname = destination.getDestinationClassName()
		print  _indent + stringFormat._formatString("ID") + id
		if name==None:
			print _indent + stringFormat._formatString("NAME")
		else:
			print _indent + stringFormat._formatString("NAME") + name
                
		print _indent + stringFormat._formatString("CLASS") + classname

                classDescription = destination.getDestinationClassNameDescription()
                if classDescription is not None:
                   print _indent + stringFormat._formatString("CLASS_INFO") + classDescription
                
		properties = destination.getProperties()
		props={}
                
		if properties:
			print _indent + stringFormat._formatString("PROPERTIES")
			_cprint(_indent + _oracledms_getETraceMsg("NAME"), _oracledms_getETraceMsg("VALUE"))
		for key in properties.keySet():
			_cprint(_indent + key, properties.get(key))
			props.update({key: properties.get(key)})
		ora_util.hideDisplay()
		return name, classname, props
	else:
       		raise DmsError, _oracledms_getETraceMsg("INVALID-DESTINATION", id, serverName)
    else:
	retVal = {}
	destinations = None
	
	try:
    		destinations = dmbs.getAttribute(objectName,"Destinations")
       	except MBeanException, error:
               	_oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except InstanceNotFoundException, error:
       		raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
        except Exception, error:
                _oracledmsEventHandleMBeanException(error)
        
    	for destination in destinations:
       		id = destination.getDestinationId()
       		name = destination.getDestinationName()
		print _indent + stringFormat._formatString("ID") + id
                
		if name==None:
			print _indent + stringFormat._formatString("NAME")
		else:
			print _indent + stringFormat._formatString("NAME") + name
                
                print"\n"
		retVal.update({id: name})
        
	ora_util.hideDisplay()
	return retVal

def oracledmsListDMSEventRoutes(obj,**kws):
    """
    Return the event-routes from the Event Tracing configuration

	listDMSEventRoutes([filterid=<filterid>],[destinationid=<destinationid>],[server=<server>])

	Argument		Definition
	filterid		Optional. The unique identifer for the specific filter
                                To specify a null filterid, use 'null'
	destinationid		Optional. The unique identifer for the specific destination
	server			Optional. server to perform this operation on. 
				Default to server currently connected to

	Note: Both a destinationid and filterid may not be specified

	Return

	If a filterid is specified:-
	{destinationid: enabled}

	If a destinationid is specified:-
	{filterid: enabled}

	If no id's are specified:-
	{filterid: {destinationid: enabled}}

	filterid		unique identifer for every filter associated with destinationid
	destinationid		unique identifer for every destination associated with filterid
	enabled			true/false

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_FILTER_ID, PARAM_DESTINATION_ID, PARAM_SERVER))
    
    #expect "null" for a null filterid
    #return an empty dictionary if no event-route found
    filterid = kws.get("filterid")
    destinationid = kws.get("destinationid")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj) 
    serverName = getServerNameFromObject(obj)
    retVal = {}
    eventRoutes = None
    stringFormat = StringFormat()
    
    if filterid and destinationid:
       	raise DmsError, _oracledms_getETraceMsg("FILTER-OR-DEST")
    elif (filterid and not destinationid) or (filterid=="null" and not destinationid):
	if filterid == "null":
		filterid=None
	# allows for a null filterid
       	try:
		eventRoutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([filterid,1], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
       	except MBeanException, error:
               	_oracledmsEventHandleMBeanException(error)
    	except RuntimeMBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
        except Exception, error:
           _oracledmsEventHandleMBeanException(error)
	
	if not eventRoutes.isEmpty():
               	values = eventRoutes.values()
               	for v in values:
			print _indent + stringFormat._formatString("FILTER") + filterid
			print _indent + stringFormat._formatString("DESTINATION") + v.get("key")
			if v.get("value"):
				print _indent + stringFormat._formatString("ENABLED")+  _oracledms_getETraceMsg("TRUE")
			else:
				print _indent + stringFormat._formatString("ENABLED")+ _oracledms_getETraceMsg("FALSE")
                        
			retVal.update({v.get("key"): v.get("value")})
                        print "\n"
	else:
        	oracledmsPrintErrorMessage(_oracledms_getETraceMsg("FILTER-ROUTE-NOT-EXIST", filterid, serverName))
        
    elif destinationid and not filterid:
        
       	try:
		eventRoutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([destinationid,0], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
       	except MBeanException, error:
               	_oracledmsEventHandleMBeanException(error)
    	except InstanceNotFoundException, error:
       		raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    	except RuntimeMBeanException, error:
       		_oracledmsEventHandleMBeanException(error)
    	except Exception, error:
       		_oracledmsEventHandleMBeanException(error)
	
	if not eventRoutes.isEmpty():
             	values = eventRoutes.values()
               	for v in values:
			print _indent + stringFormat._formatString("FILTER") + v.get("key")
			print _indent + stringFormat._formatString("DESTINATION") + destinationid
			if v.get("value"):
				print _indent + stringFormat._formatString("ENABLED")+ _oracledms_getETraceMsg("TRUE")
			else:
				print _indent + stringFormat._formatString("ENABLED")+ _oracledms_getETraceMsg("FALSE")
			retVal.update({v.get("key"): v.get("value")})
	else:
        	oracledmsPrintErrorMessage(_oracledms_getETraceMsg("DESTINATION-ROUTE-NOT-EXIST", destinationid, serverName))
    else: # no filterid or destinationid specified
    	retVal = _oracledmsListAllEventRoutes(serverName, objectName, 1)
    
    ora_util.hideDisplay()
    return retVal

def oracledmsListDMSEventConfiguration(obj,**kws):
    """
    Give an overview of the Event Tracing configuration

	listDMSEventConfiguration([server=<server]]      

	Argument Definition
	server	 Optional. Server to perform this operation on. Default to server currently connected 
                 to


	Return
	({filter: {destination:enabled}}, [filters-no-route], [destinations-no-route])

	filter			filter associated with an event route
	destination		associated destination(s) for filter
	enabled			true/false
	filters-no-route	filters with no event-route
	destinations-no-route	destinations with no event-route
    """
    
    
    _oracledmsEventVerifyParameters(kws, (PARAM_SERVER,))
    
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    # all event routes
    allRoutes = _oracledmsListAllEventRoutes(serverName, objectName, 2)
    
    #for all filters, check if any exist without an event route
    erFilter = []
    print _oracledms_getETraceMsg("FILTER-NO-ROUTE")
    
    try:
    	filters = dmbs.getAttribute(objectName,"Filters")
    except MBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except Exception, error:
       	_oracledmsEventHandleMBeanException(error)
    
    if filters:
    	for filter in filters:
    		id = filter.get("filterId")
                
		eventRoutes = None
               	try:
    			eventRoutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([id,1], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
       		except MBeanException, error:
               		_oracledmsEventHandleMBeanException(error)
    		except RuntimeMBeanException, error:
       			_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
       			_oracledmsEventHandleMBeanException(error)
                
		if eventRoutes.isEmpty():
			print _indent, id
			erFilter.append(id)
    
    #for all destinations, check if any exist without an event route
    erDestination = []
    print "\n"
    print _oracledms_getETraceMsg("DESTINATION-NO-ROUTE")
    
    destinations = None
    try:
    	destinations = dmbs.getAttribute(objectName,"Destinations")
    except MBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except RuntimeMBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except Exception, error:
       	_oracledmsEventHandleMBeanException(error)
    
    if destinations != None:
	for destination in destinations:
       		id = destination.getDestinationId()
   		eventRoutes = None
                
		try:
			eventRoutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([id,0], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
        	except MBeanException, error:
               		_oracledmsEventHandleMBeanException(error)
    		except InstanceNotFoundException, error:
        		raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    		except RuntimeMBeanException, error:
        		_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
        		_oracledmsEventHandleMBeanException(error)
		if eventRoutes.isEmpty():
			print _indent, id
			erDestination.append(id)
    
    ora_util.hideDisplay()
    return allRoutes, erFilter, erDestination

def oracledmsAddDMSEventDestination(obj,**kws):
    """
    Add a new destination to the Event Tracing configuration

	addDMSEventDestination(id=<id>,[name=<name>],class=<class>,[props= {'name': 'value'...}], [server=<server>])

	Argument	Definition
	Id		The unique identifer for the specific destination
	Name		Optional. Description of the destination
	class		The full classname of the Destination
	props		Optional. The name/value properties to use for the Destination
	Server		Optional. server to perform this operation on. 
			Default to server currently connected to


    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_NAME, PARAM_CLASS, PARAM_PROPS, PARAM_SERVER))
    
    id = kws.get("id")
    name = kws.get("name")
    dclass = kws.get("class")
    props = kws.get("props")
    if props != None:
       _oracledmsValidateDictionary(props)
    
    # Validate mandatory properties at some point in the future.
    # Uncomment this code when we have a way of detecting which mandatory properties 
    # a class has
    #if props != None:
       #_oracledmsVerifyProps(props, (PARAM_CONDITION,))
    
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if id==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "id")
    if dclass==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG", "class")
    
    # check if id already exists in the config
    if _oracledmsDestinationExists(objectName, id)==1:
       	raise DmsError, _oracledms_getETraceMsg("DUPE-DESTINATION",  id, serverName)
    
    if props==None:
	props={}
    
    # construct a Destination object
    d = Destination(id, dclass)
    if name:
    	d.setDestinationName(name)
    if len(props) > 0:
	for key,value in props.items():
		d.setProperty(key,value)	
    
    # add the Destination to the config
    try:
    	dmbs.invoke(objectName, "addDestination", jarray.array([d], java.lang.Object), jarray.array(["oracle.dms.event.config.Destination"], String))
    	_oracledmsActivateDMSEventConfig(objectName)
	print _oracledms_getETraceMsg("DESTINATION-ADDED", id, serverName)
    except MBeanException, error:
    	_oracledmsEventHandleMBeanException(error)
    except InstanceNotFoundException, error:
       	raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    except RuntimeMBeanException, error:
       	_oracledmsEventHandleMBeanException(error)
    except Exception, error:
       	_oracledmsEventHandleMBeanException(error)

def oracledmsAddDMSEventFilter(obj,**kws):
    """
    Add a new filter to the Event Tracing configuration

	addDMSEventFilter(id=<id>, [name=<name>], [etypes=<eventTypesString>], props= {'props-name': 'value'...}, [server=<server>])

	Argument	Definition

	id		unique identifer for the specific filter 
	name	        Optional. name of the filter
	etypes          Optional. String containing a comma separated list of
	                event/action pairs.
	props-name	name of the filter property. 
	                "condition" is the only valid property currently, and only one condition 
                        may exist
	value	        value of the property of the filter. 
	server	        Optional. server to perform this operation on. 
                        Default to server currently connected to

	Syntax: props-name: condition
	<type> [<operator> <condition>]
                       
	Argument          	Definition

	<condition>		a condition may have a nested condition
	<type>		        <nountype> | <context> 
	<operator>		Optional. "AND" | "OR"

	Syntax: : props-name: condition: <type>
	<nountype> | <context>

	<nountype>
	Each Sensor, with its associated metrics is organized in a hierarchy according to Nouns.
	A <nountype> is a name that reflects the set of metrics being collected. 
	For example JDBC could be a <nountype>.

	NOUNTYPE <nountype-operator> <value>

	Note: With the exception of <value>, all arguments are case insensitive. 
              They are shown in mixed case for readability.
	
	Argument       		Definition
	<nountype-operator>	"equals"| "starts_with" | "contains" | "not_equals"
	equals			Operator. Only filters if context <name> equals <value>
	starts_with		Operator. Only filters if context <name> starts_with <value>
	contains		Operator. Only filters if context <name> contains <value>
	not_equals		Operator. Only filters if context <name> does not equal <value>
<value>                		The name of the <nountype> to filter on. 
	                        Any object for which we want to measure performance data.

	<context>
	An ExecutionContext is an association of:
	ECID (ExecutionContext ID), RID (Relationsip ID), Maps of Values
	The <context> allows the data stored in the Map of Values in the ExecutionContext, 
        to be inspected and used by the filter.  
        For example, if the map contains the key "user" then a filter could filter requests 
        with "user" equal to "bruce".

	CONTEXT <name> <context-operator> [<value>] [IGNORECASE=true|false] [DATATYPE="string|long|double"]
	Note: With the exception of <value>, all arguments are case insensitive. 
              They are shown in mixed case for readability.

	Argument                Definition
	<context-operator>	"equals" | "starts_with" | "contains" | "not_equals" | "is_null" | 
                                "gt" | "le" | "ge"
	equals		        Operator. Only filters if context <name> equals <value>
	starts_with		Operator. Only filters if context <name> starts_with <value>
	contains		Operator. Only filters if context <name> contains <value>
	not_equals		Operator. Only filters if context <name> does not equal <value>
	is_null		        Operator. Only filters if the <value> of context <name> is null. 
	lt			Operator. Only filters if context <name> is less than <value>
	gt			Operator. Only filters if context <name> is greater than <value>
	le			Operator. Only filters if context <name> is less than or equal 
                                to <value>
	ge			Operator. Only filters if context <name> is greater than or equal 
                                to <value>
	<name>			<context> to filter on
	<value>			The value of the  <context> to filter on. 
				This value is required for all <context-operator> except is_null
	IGNORECASE	        Optional. If this is specified in a condition, then the case of 
                                the value is ignored
	DATATYPE		Optional. default is string. "string|long|double"

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_NAME, PARAM_ETYPES, PARAM_PROPS, PARAM_SERVER))
    
    id = kws.get("id")
    name = kws.get("name")
    etypes = kws.get("etypes")
    props = kws.get("props")
    # a comma is required in the list with one item,
    # otherwise each letter will be validated and not the word
    _oracledmsVerifyProps(props, (PARAM_CONDITION,))
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    # add the filter
    _addFilter(id=id, name=name, etypes=etypes, props=props, objectName=objectName, display=1, serverName=serverName)

def oracledmsRemoveDMSEventFilter(obj,**kws):
    """
    Remove a filter from the Event Tracing configuration

	removeDMSEventFilter(id=<id>, [server=<server>])

	Argument	Definition
	id            	The unique identifer for the specific destination
	server		Optional. server to perform this operation on. 
			Default to server currently connected to

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_ID, PARAM_SERVER))
    
    id = kws.get("id")
    server = kws.get("server")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if id==None:
       	raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "id")
    else:
       	if _oracledmsFilterExists(objectName, id)==1:
		# check if an event route exists for filter
		eventRoutes = None
     		try:
			eventRoutes = dmbs.invoke(objectName, "getEventRouteStatus", jarray.array([id,1], java.lang.Object), jarray.array(["java.lang.String", "boolean"], String))
       		except MBeanException, error:
               		_oracledmsEventHandleMBeanException(error)
    		except RuntimeMBeanException, error:
       			_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
       			_oracledmsEventHandleMBeanException(error)
                
		if not eventRoutes.isEmpty():
       			raise DmsError, _oracledms_getETraceMsg("FILTER-ROUTE-EXISTS",id, serverName)
		else:
			try:
       				dmbs.invoke(objectName, "removeFilter", jarray.array([id], java.lang.String), jarray.array(["java.lang.String"], String)) 
    				_oracledmsActivateDMSEventConfig(objectName)
				print _oracledms_getETraceMsg("FILTER-REMOVED", id, serverName)
       			except MBeanException, error:
               			_oracledmsEventHandleMBeanException(error)
    			except InstanceNotFoundException, error:
       				raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    			except RuntimeMBeanException, error:
       				_oracledmsEventHandleMBeanException(error)
    			except Exception, error:
       				_oracledmsEventHandleMBeanException(error)
	else:
       		raise DmsError, _oracledms_getETraceMsg("INVALID-FILTER",  id, serverName)

def oracledmsAddDMSEventRoute(obj,**kws):
    """
    Add an event-route to the Event Tracing configuration

	addDMSEventRoute([filterid=<filterid>], destinationid=<destinationid>, [enable=<enable>], [server=<server>])

	Argument       	Definition
	filterid      	Optional. The unique identifer for the filter to wire up to destinationid. 
                        To specify a null filterid, use 'null' or don't use
                        the filterid argument. Both work.
			If not specified, all DMS events will pass through
	destinationid 	The unique identifer for the destination to wire up to filterid
	enable  	"true"|"false". default to "true"
	server		Optional. server to perform this operation on. 
			Default to server currently connected to

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_FILTER_ID, PARAM_DESTINATION_ID, PARAM_ENABLE, PARAM_SERVER))
    
    filterid = kws.get("filterid")
    if filterid == "null":
       filterid=None
    
    destinationid = kws.get("destinationid")
    enable = kws.get("enable")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    _addRoute(filterid=filterid, destinationid=destinationid, enable=enable, objectName=objectName, display=1, serverName=serverName)

def oracledmsRemoveDMSEventRoute(obj,**kws):
    """
    Remove an event-route from the Event Tracing configuration

	removeDMSEventRoute([filterid=<filterid>], destinationid=<destinationid>], [server=<server>])

	Argument          Definition
	filterid          Optional. The unique identifer for the filter to wire up to destinationid. 
                          To specify a null filterid, use 'null' or don't use
                          the filterid argument. Both work.
			  Default to None.
	destinationid     The unique identifer for the destination to wire up to filterid
	server            Optional. server to perform this operation on. 
			  Default to server currently connected to

    """
    
    _oracledmsEventVerifyParameters(kws, (PARAM_FILTER_ID, PARAM_DESTINATION_ID, PARAM_SERVER))
    
    filterid = kws.get("filterid")
    if filterid == "null":
       filterid = None
    
    destinationid = kws.get("destinationid")
    dmbs = _getDmbs()
    objectName = ora_mbs.makeObjectName(obj)
    serverName = getServerNameFromObject(obj)
    
    if destinationid==None:
        raise DmsError, _oracledms_getETraceMsg("MISSING-ARG",  "destinationid")
    else:
       	if _oracledmsEventRouteExists(objectName, filterid, destinationid)==1:
		try:
    			dmbs.invoke(objectName, "removeEventRoute", jarray.array([filterid, destinationid], java.lang.String), jarray.array(["java.lang.String", "java.lang.String"], String))
    			_oracledmsActivateDMSEventConfig(objectName)
			print _oracledms_getETraceMsg("ROUTE-REMOVED", filterid, destinationid, serverName)
       		except MBeanException, error:
               		_oracledmsEventHandleMBeanException(error)
    		except InstanceNotFoundException, error:
       			raise DmsError, _oracledms_getETraceMsg("INVALID-TARGET", serverName)
    		except RuntimeMBeanException, error:
       			_oracledmsEventHandleMBeanException(error)
    		except Exception, error:
       			_oracledmsEventHandleMBeanException(error)
	else:
       		raise DmsError, _oracledms_getETraceMsg("INVALID-ROUTE",  filterid, destinationid, serverName)

class StringFormat:
    def __init__(self):
       #self.MAX_STRING_LENGTH = 0
       # message id's for translatable strings used in output formatting
       sList = []
       sList.append(_oracledms_getETraceMsg("FILTER"))
       sList.append(_oracledms_getETraceMsg("DESTINATION"))
       sList.append(_oracledms_getETraceMsg("NAME"))
       sList.append(_oracledms_getETraceMsg("EVENT_TYPES"))
       sList.append(_oracledms_getETraceMsg("PROPERTIES"))
       sList.append(_oracledms_getETraceMsg("CONDITION"))
       sList.append(_oracledms_getETraceMsg("ID"))
       sList.append(_oracledms_getETraceMsg("VALUE"))
       sList.append(_oracledms_getETraceMsg("CLASS"))
       self.MAX_STRING_LENGTH = self._maxLength(sList)
    
    #helper - determine max length of translatable string used in formatting display o/p
    def _maxLength(self, sList):
       """
       Take a list of strings, and return the length of the largest in the list
       """
       sMax = 0
       for v in sList:
          if len(v) > sMax:
             sMax = len(v)
       
       return sMax
    
    #helper - accept an unformatted string and return a string appended with 
    #         space +  colon, with the correct padding of spaces, such that 
    #         the formatting on screen
    #         of all identifying strings looks nice
    def _formatString(self, s):
       s  = _oracledms_getETraceMsg(s)
       retVal = s.ljust(self.MAX_STRING_LENGTH) + " : "
       return retVal

class DmsError(Exception):
    def __init__(self, msg):
        self.msg = msg
    
    def getMsg(self):
        return self.msg
    
    def __str__(self):
        return repr(self.msg)
