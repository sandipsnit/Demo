"""
 Copyright (c) 2009, 2013, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move
this file because this may cause WLST commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WLST scripts to fail when you upgrade to a different version
of WLST.

Oracle Fusion Middleware logging commands.

"""

import jarray
import os
import sys
import java.lang
from java.lang import Class
from java.lang import Exception
from java.io import File
from java.io import IOException
from java.net import URLClassLoader
from java.text import MessageFormat
from java.util import ArrayList
from java.util import HashMap
from java.util import Locale
from java.util import ResourceBundle
from javax.management import ObjectName
from types import ListType
from types import TupleType
from oracle.core.ojdl.logging import ODLLevel

oracle_logging_LogRuntime="oracle.logging:type=LogRuntime"
oracle_logging_LogConfig="oracle.logging:type=LogConfig"
oracle_logging_OvdLogConfig="oracle.as.ovd:type=component.loggingconfig,name=loggingconfig"

def oracle_logging_init_help():
    try:
        addHelpCommandGroup("fmw diagnostics","oracle.as.management.logging.messages.CommandHelp")
    except:
        pass
    addHelpCommand("getLogLevel", "fmw diagnostics", online="true")
    addHelpCommand("setLogLevel", "fmw diagnostics", online="true")
    addHelpCommand("listLoggers", "fmw diagnostics", online="true")
    addHelpCommand("configureLogHandler", "fmw diagnostics", online="true")
    addHelpCommand("listLogHandlers", "fmw diagnostics", online="true")
    addHelpCommand("listLogs", "fmw diagnostics", online="true", offline="true")
    addHelpCommand("displayLogs", "fmw diagnostics", online="true", offline="true")

def oracle_logging_getMsg(key, *args):
    try:
        rb = ResourceBundle.getBundle("oracle.as.management.logging.messages.Messages", Locale.getDefault(), Class.forName("oracle.as.management.logging.messages.Messages").getClassLoader())
        if rb.containsKey(key):
            msg = rb.getString(key)
            return MessageFormat.format(msg, jarray.array(args, java.lang.String))
    except:
        pass
    return key

def oracle_logging_NotConnected():
    print oracle_logging_getMsg("NOT-CONNECTED", "Weblogic")
    return None

def oracle_logging_eatDisplay(dummy):
    pass

def oracle_logging_hideDisplay():
    sys.displayhook = oracle_logging_eatDisplay

def oracle_logging_getObjName(target, isRuntime):
    if mbs is None:
        return oracle_logging_NotConnected()
    hasTarget = 1
    if target == None:
        hasTarget = 0
        target = serverName
    if target.startswith("ovd:"):
        i = target.find("/")
        if i < 0:
            raise WLSTException, oracle_logging_getMsg("INVALID-TARGET", str(target))
        inst = target[4:i]
        comp = target[i+1:]
        baseName = oracle_logging_OvdLogConfig + ",instance=" + inst + ",component=" + comp + ",Location=" + serverName
        isRuntime = 0
    elif isRuntime:
        baseName = oracle_logging_LogRuntime + ",name=" + target
    else:
        baseName = oracle_logging_LogConfig + ",ServerName=" + target
    try:
        objName = ObjectName(baseName)
    except:
        raise WLSTException, oracle_logging_getMsg("INVALID-TARGET", str(target))
    changedToDR = 0
    if not isRuntime:
        oracle_logging_cdDomainRuntime()
        changedToDR = 1
    if mbs.isRegistered(objName):
        return objName
    if isRuntime:
        if not changedToDR:
            oracle_logging_cdDomainRuntime()
        objName = ObjectName(baseName + ",Location=" + target)
        try:
            found = mbs.isRegistered(objName)
        except IOException:
            found = 0
        if found:
            return objName
    print oracle_logging_getMsg("MBEAN-NOT-FOUND", str(objName))
    return None

def oracle_logging_cdDomainRuntime():
    if isAdminServer == "true":
        if mbs.isRegistered(ObjectName("com.bea:Name=DomainRuntimeService,Type=weblogic.management.mbeanservers.domainruntime.DomainRuntimeServiceMBean")):
            return None
        cwd = pwd()
        cd("domainRuntime:/")
        return cwd
    raise WLSTException, oracle_logging_getMsg("WRONG-SERVER")

def oracle_logging_getExceptionMsg(t):
    setDumpStackThrowable(t)
    msg = t.getMessage()
    if msg == None:
        msg = str(t)
    return msg + "\n" + oracle_logging_getMsg("STACK-INFO", "dumpStack()")

def oracle_logging_getBool(v):
    return v and str(v).lower() != "false"

def oracle_logging_listLoggers(**kws):
    target = kws.get("target")
    runtime = oracle_logging_getBool(kws.get("runtime", 1))
    pattern = kws.get("pattern")
    mbeanName = oracle_logging_getObjName(target, runtime)
    if mbeanName == None:
        return None
    ret = {}
    try:
        map = mbs.invoke(mbeanName, "getLoggerLevels", jarray.array([pattern],java.lang.String), jarray.array(['java.lang.String'], java.lang.String))
    except Exception, e:
        raise WLSTException, oracle_logging_getExceptionMsg(e)
    maxLen = 0
    loggers = []
    for entry in map.entrySet():
        logger = entry.getValue().get("key")
        level = entry.getValue().get("value")
        loggers.append(logger)
        ret[logger] = level
        if logger.__len__() > maxLen:
            maxLen = logger.__len__()
    if loggers.__len__() == 0:
        print oracle_logging_getMsg("NO-LOGGERS")
        oracle_logging_hideDisplay()
        return loggers
    loggers.sort()
    line = "".ljust(maxLen).replace(" ", "-") + "-+-" + "".ljust(16).replace(" ", "-")
    print line
    print "Logger".ljust(maxLen) + " | " + "Level".ljust(16)
    print line
    for logger in loggers:
        level = ret[logger]
        if logger == "":
            logger = "<root>"
        if level == "":
            level = "<Inherited>"
        print logger.ljust(maxLen) + " | " + level
    oracle_logging_hideDisplay()
    return ret

def listLoggers(**kws):
    try:
        cwd = pwd()
        return oracle_logging_listLoggers(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def oracle_logging_getLogLevel(**kws):
    target = kws.get("target")
    runtime = oracle_logging_getBool(kws.get("runtime", 1))
    logger = kws.get("logger")
    if logger == None:
        print oracle_logging_getMsg("MISSING-ARG", "logger")
        return None
    mbeanName = oracle_logging_getObjName(target, runtime)
    if mbeanName == None:
        return None
    try:
        lev = mbs.invoke(mbeanName, "getLoggerLevel", jarray.array([logger],java.lang.String), jarray.array(['java.lang.String'], java.lang.String))
    except Exception, e:
        raise WLSTException, oracle_logging_getExceptionMsg(e)
    if lev == None:
        print oracle_logging_getMsg("LOGGER-NOT-FOUND", str(logger))
    elif lev == "":
        print "<Inherited>"
    else:
        print lev
    oracle_logging_hideDisplay()
    return lev


def getLogLevel(**kws):
    try:
        cwd = pwd()
        return oracle_logging_getLogLevel(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def oracle_logging_setLogLevel(**kws):
    runtime = oracle_logging_getBool(kws.get("runtime", 1))
    persist = oracle_logging_getBool(kws.get("persist", 1))
    target = kws.get("target")
    logger = kws.get("logger")
    level = kws.get("level")
    addLogger = oracle_logging_getBool(kws.get("addLogger", 0))
    if logger is None:
        print oracle_logging_getMsg("MISSING-ARG", "logger")
        return None
    if level is None:
        print oracle_logging_getMsg("MISSING-ARG", "level")
        return None
    try:
        if len(level) > 0:
            ODLLevel.parse(level)
    except java.lang.IllegalArgumentException:
        raise WLSTException, oracle_logging_getMsg("INVALID-LEVEL", level)
    try:
        if runtime:
            mbeanName = oracle_logging_getObjName(target, 1)
            if mbeanName == None:
                return None
            currentLevel = mbs.invoke(mbeanName, "getLoggerLevel", jarray.array([logger],java.lang.String), jarray.array(['java.lang.String'], java.lang.String))
            if currentLevel == None and not addLogger:
                raise WLSTException, oracle_logging_getMsg("LOGGER-NOT-FOUND-USE-ADD-LOGGER", str(logger))
            mbs.invoke(mbeanName, "setLoggerLevel", jarray.array([logger, level],java.lang.String), jarray.array(['java.lang.String', 'java.lang.String'], java.lang.String))
        if persist:
            mbeanName = oracle_logging_getObjName(target, 0)
            if mbeanName == None:
                return None
            if not runtime:
                from java.util.regex import Pattern
                tdResult = mbs.invoke(mbeanName, "getLoggerLevels", jarray.array([Pattern.quote(logger)],java.lang.String), jarray.array(['java.lang.String'], java.lang.String))
                # levelMap is represented as TabularData
                k = jarray.array([logger], java.lang.String)
                if tdResult.size() == 1 and tdResult.containsKey(k):
                    currentLevel = tdResult.get(k).get("value")
                else:
                    currentLevel = None
            else:
                currentLevel = ""
            if currentLevel == None and not addLogger:
                raise WLSTException, oracle_logging_getMsg("LOGGER-NOT-FOUND-USE-ADD-LOGGER", str(logger))
            mbs.invoke(mbeanName, "setLoggerLevel", jarray.array([logger, level],java.lang.String), jarray.array(['java.lang.String', 'java.lang.String'], java.lang.String))
    except WLSTException, w:
        raise w
    except Exception, e:
        raise WLSTException, oracle_logging_getExceptionMsg(e)

def oracle_logging_getODLClass(odlClassName):
    return Class.forName(odlClassName)

def setLogLevel(**kws):
    try:
        cwd = pwd()
        oracle_logging_setLogLevel(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

# convert command keyword list to Java Map
def oracle_logging_convertToJava(kws):
    jkws = HashMap(kws.__len__())
    for k in kws.keys():
        v = kws[k]
        jv = v
        if isinstance(v, ListType) or isinstance(v, TupleType):
            jv = ArrayList(v.__len__())
            for i in range(0, v.__len__()):
                jv.add(v[i])
        jkws.put(k, jv)
    return jkws

def displayLogs(searchString=None, **kws):
    cwd = None
    try:
        disconnected = kws.has_key('oracleInstance')
        if not disconnected:
            if mbs == None:
                return oracle_logging_NotConnected()
            cwd = oracle_logging_cdDomainRuntime()
            kws['mbs']=mbs
        if not searchString == None:
            kws['searchString'] = searchString
        jkws = oracle_logging_convertToJava(kws)
        try:
            dlClass = oracle_logging_getODLClass("oracle.as.management.logging.tools.DisplayLogs")
            if dlClass == None:
                return None
            oracle_logging_hideDisplay()
            return dlClass.getMethod("executeCmd", jarray.array([java.util.Map], java.lang.Class)).invoke(dlClass.newInstance(), jarray.array([jkws], java.lang.Object))
        except Exception, e:
            raise WLSTException, oracle_logging_getExceptionMsg(e)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def listLogs(**kws):
    cwd = None
    try:
        disconnected = kws.has_key('oracleInstance')
        if not disconnected:
            if mbs == None:
                return oracle_logging_NotConnected()
            cwd = oracle_logging_cdDomainRuntime()
            kws['mbs']=mbs
        jkws = oracle_logging_convertToJava(kws)
        try:
            llClass = oracle_logging_getODLClass("oracle.as.management.logging.tools.ListLogs")
            if llClass == None:
                return None
            oracle_logging_hideDisplay()
            return llClass.getMethod("executeCmd", jarray.array([java.util.Map], java.lang.Class)).invoke(llClass.newInstance(), jarray.array([jkws], java.lang.Object))
        except Exception, e:
            raise WLSTException, oracle_logging_getExceptionMsg(e)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)
        
def oracle_logging_listLogHandlers(**kws):
    if mbs == None:
        return oracle_logging_NotConnected()
    target = kws.get("target")
    mbeanName = oracle_logging_getObjName(target, 0)
    kws['mbs']=mbs
    if mbeanName == None:
        return None
    kws['serviceName'] = mbeanName
    jkws = oracle_logging_convertToJava(kws)
    try:
        llClass = oracle_logging_getODLClass("oracle.as.management.logging.tools.ListLogHandlersCmd")
        if llClass == None:
            return None
        oracle_logging_hideDisplay()
        return llClass.getMethod("executeCmd", jarray.array([java.util.Map], java.lang.Class)).invoke(llClass.newInstance(), jarray.array([jkws], java.lang.Object))
    except Exception, e:
        raise WLSTException, oracle_logging_getExceptionMsg(e)

def listLogHandlers(**kws):
    try:
        cwd = pwd()
        return oracle_logging_listLogHandlers(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def oracle_logging_configureLogHandler(**kws):
    if mbs == None:
        return oracle_logging_NotConnected()
    target = kws.get("target")
    mbeanName = oracle_logging_getObjName(target, 0)
    kws['mbs']=mbs
    if mbeanName == None:
        return None
    kws['serviceName'] = mbeanName
    jkws = oracle_logging_convertToJava(kws)
    try:
        llClass = oracle_logging_getODLClass("oracle.as.management.logging.tools.ConfigureLogHandlerCmd")
        if llClass == None:
            return None
        oracle_logging_hideDisplay()
        return llClass.getMethod("executeCmd", jarray.array([java.util.Map], java.lang.Class)).invoke(llClass.newInstance(), jarray.array([jkws], java.lang.Object))
    except Exception, e:
        raise WLSTException, oracle_logging_getExceptionMsg(e)

def configureLogHandler(**kws):
    try:
        cwd = pwd()
        return oracle_logging_configureLogHandler(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

try:
    oracle_logging_init_help()
except:
    pass

