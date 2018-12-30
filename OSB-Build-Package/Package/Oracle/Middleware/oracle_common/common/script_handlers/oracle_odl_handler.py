"""
Copyright (c) 2009, 2011, Oracle and/or its affiliates. All rights reserved.

Caution: This file is part of the command scripting implementation.
Do not edit or move this file because this may cause commands and scripts
to fail. Do not try to reuse the logic in this file or keep copies of this
file because this could cause your scripts to fail when you upgrade to a
different version.

Oracle Fusion Middleware logging commands.

"""

import jarray
import sys
from types import DictType
from types import ListType
from types import TupleType

from java.lang import Exception
from java.lang import IllegalArgumentException
from java.lang import Object
from java.lang import String
from java.text import MessageFormat
from java.util import ArrayList
from java.util import HashMap
from java.util import ResourceBundle
from javax.management import ObjectName
from javax.management import Query

from oracle.as.management.logging.messages import Messages
from oracle.as.management.logging.tools import ConfigureLogHandlerCmd
from oracle.as.management.logging.tools import DisplayLogs
from oracle.as.management.logging.tools import ListLogHandlersCmd
from oracle.as.management.logging.tools import ListLogs
from oracle.core.ojdl.logging import ODLLevel

import ora_mbs
import ora_util

def getMsg(key, *args):
    try:
        rb = ResourceBundle.getBundle(Messages.getName())
        if rb.containsKey(key):
            msg = rb.getString(key)
            return MessageFormat.format(msg, jarray.array(args, String))
    except:
        pass
    return key

def getExceptionMsg(t):
    msg = t.getMessage()
    if msg == None:
        msg = str(t)
    return msg + "\n" + getMsg("STACK-INFO", "dumpStack()")

def getBool(v):
    return v and str(v).lower() != "false"

def NotConnected():
    print getMsg("NOT-CONNECTED", getPlatformName())
    return None

def convertToJava(kws):
    jkws = HashMap(kws.__len__())
    for k in kws.keys():
        v = kws[k]
        jv = v
        if isinstance(v, DictType):
            jv = HashMap(v.__len__())
            for i in v.keys():
                jv.put(i,v[i])
        if isinstance(v, ListType) or isinstance(v, TupleType):
            jv = ArrayList(v.__len__())
            for i in range(0, v.__len__()):
                jv.add(v[i])
        jkws.put(k, jv)
    return jkws

def listLoggers(**kws):
    if not ora_mbs.isConnected():
        return NotConnected()
    target = kws.get("target")
    if target == None:
        target = getDefaultTarget()
    runtime = getBool(kws.get("runtime", 1))
    if runtime:
        odlType = "LogRuntime"
    else:
        odlType = "LogConfig"
    mbeanName =  getMBeanName(target, odlType)
    if mbeanName == None:
        return None
    pattern = kws.get("pattern")
    ret = {}
    try:
        map = ora_mbs.invoke(mbeanName, "getLoggerLevels", jarray.array([pattern],String), jarray.array(['java.lang.String'], String))
    except Exception, e:
        raise WLSTException, getExceptionMsg(e)
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
        print getMsg("NO-LOGGERS")
        ora_util.hideDisplay()
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
    ora_util.hideDisplay()
    return ret

def getLogLevel(**kws):
    if not ora_mbs.isConnected():
        return NotConnected()
    target = kws.get("target")
    if target == None:
        target = getDefaultTarget()
    runtime = getBool(kws.get("runtime", 1))
    logger = kws.get("logger")
    if logger == None:
        print getMsg("MISSING-ARG", "logger")
        return None
    if runtime:
        odlType = "LogRuntime"
    else:
        odlType = "LogConfig"
    mbeanName = getMBeanName(target, odlType)
    if mbeanName == None:
        return None
    try:
        lev = ora_mbs.invoke(mbeanName, "getLoggerLevel", jarray.array([logger],String), jarray.array(['java.lang.String'], String))
    except Exception, e:
        raise Exception, getExceptionMsg(e)
    if lev == None:
        print getMsg("LOGGER-NOT-FOUND", str(logger))
    elif lev == "":
        print "<Inherited>"
    else:
        print lev
    ora_util.hideDisplay()
    return lev

def setLogLevel(**kws):
    if not ora_mbs.isConnected():
        return NotConnected()
    runtime = getBool(kws.get("runtime", 1))
    persist = getBool(kws.get("persist", 1))
    target = kws.get("target")
    if target == None:
        target = getDefaultTarget()    
    logger = kws.get("logger")
    level = kws.get("level")
    addLogger = getBool(kws.get("addLogger", 0))
    if logger is None:
        print getMsg("MISSING-ARG", "logger")
        return None
    if level is None:
        print getMsg("MISSING-ARG", "level")
        return None
    try:
        if len(level) > 0:
            ODLLevel.parse(level)
    except IllegalArgumentException:
        raise Exception, getMsg("INVALID-LEVEL", level)
    try:
        if runtime:
            mbeanName = getMBeanName(target, "LogRuntime")
            if mbeanName == None:
                return None
            currentLevel = ora_mbs.invoke(mbeanName, "getLoggerLevel", jarray.array([logger],String), jarray.array(['java.lang.String'], String))
            if currentLevel == None and not addLogger:
                raise Exception, getMsg("LOGGER-NOT-FOUND-USE-ADD-LOGGER", str(logger))
            ora_mbs.invoke(mbeanName, "setLoggerLevel", jarray.array([logger, level],String), jarray.array(['java.lang.String', 'java.lang.String'], String))
        if persist:
            mbeanName = getMBeanName(target, "LogConfig")
            if mbeanName == None:
                return None
            if not runtime:
                from java.util.regex import Pattern
                tdResult = ora_mbs.invoke(mbeanName, "getLoggerLevels", jarray.array([Pattern.quote(logger)],String), jarray.array(['java.lang.String'], String))
                # levelMap is represented as TabularData
                k = jarray.array([logger], String)
                if tdResult.size() == 1 and tdResult.containsKey(k):
                    currentLevel = tdResult.get(k).get("value")
                else:
                    currentLevel = None
            else:
                currentLevel = ""
            if currentLevel == None and not addLogger:
                raise Exception, getMsg("LOGGER-NOT-FOUND-USE-ADD-LOGGER", str(logger))
            ora_mbs.invoke(mbeanName, "setLoggerLevel", jarray.array([logger, level],String), jarray.array(['java.lang.String', 'java.lang.String'], String))
    except Exception, w:
        raise w
    except Exception, e:
        raise Exception, getExceptionMsg(e)

def listLogHandlers(**kws):
    if not ora_mbs.isConnected():
        return NotConnected()
    target = kws.get("target")
    if target == None:
        target = getDefaultTarget()
    mbeanName = getMBeanName(target, "LogConfig")
    if mbeanName == None:
        return None
    kws['mbs'] = ora_mbs.getMbsInstance()
    kws['serviceName'] = mbeanName
    jkws = convertToJava(kws)
    logHandlers = None
    try:
        logHandlers = ListLogHandlersCmd().executeCmd(jkws)
    except Exception, e:
        raise Exception, getExceptionMsg(e)
    ora_util.hideDisplay()
    return logHandlers

def configureLogHandler(**kws):
    if not ora_mbs.isConnected():
        return NotConnected()
    target = kws.get("target")
    if target == None:
        target = getDefaultTarget()
    mbeanName = getMBeanName(target, "LogConfig")
    if mbeanName == None:
        return None
    kws['mbs'] = ora_mbs.getMbsInstance()
    kws['serviceName'] = mbeanName
    jkws = convertToJava(kws)
    logHandlers = None
    try:
        logHandlers = ConfigureLogHandlerCmd().executeCmd(jkws)
    except Exception, e:
        raise Exception, getExceptionMsg(e)
    ora_util.hideDisplay()
    return logHandlers

def displayLogs(searchString=None, **kws):
    disconnected = kws.has_key('oracleInstance')
    if not disconnected:
        if not ora_mbs.isConnected():
            return NotConnected()
        kws['targetMap'] = getTargetMap(**kws)
        kws['mbs'] = ora_mbs.getMbsInstance()
    if not searchString == None:
        kws['searchString'] = searchString
    addPlatformParams(kws)    
    jkws = convertToJava(kws)
    ret = None
    try:
        ret = DisplayLogs().executeCmd(jkws)
    except Exception, e:
        raise Exception, getExceptionMsg(e)
    ora_util.hideDisplay()
    return ret

def listLogs(**kws):
    disconnected = kws.has_key('oracleInstance')
    if not disconnected:
        if not ora_mbs.isConnected():
            return NotConnected()
        kws['targetMap'] = getTargetMap(**kws)
        kws['mbs'] = ora_mbs.getMbsInstance()
    addPlatformParams(kws)
    jkws = convertToJava(kws)
    ret = None
    try:
        ret = ListLogs().executeCmd(jkws)
    except Exception, e:
        raise Exception, getExceptionMsg(e)
    ora_util.hideDisplay()
    return ret

def getTargetMap(**kws):
    if kws.has_key('target'):
        targets = kws['target']
        if not (isinstance(targets, ListType) or isinstance(targets, TupleType)):
            targets = [targets]
    else:
        targets = getServerNames()
    m = {}
    for t in targets:
        if t.find("opmn:") == 0:
            i = t.find('/')
            if i > 0:
                instance = t[5:i]
                component = t[i+1:len(t)]
            else:
                instance = t[5:i]
                component = None
            s = getProxyLogQueryMBeanName();
            if not ora_mbs.isRegistered(s):
                print getMsg("MBEAN-NOT-FOUND", s)
            m[getSystemComponentTargetObjName(instance, component)] = s
        else:
            i = t.find('/')
            if i > 0:
                server = t[0:i]
                app = t[i+1:len(t)]
            else:
                server = t
                app = None
            s = getMBeanName(server, "LogQuery")
            if s == '' or s == None:
                raise Exception, "Unable to find LogQueryMBean for target: " + str(t)
            m[getTargetObjName(server, app)] = s
    return m

def getMBeanName(target, odlType):
    if ora_mbs.isWebSphereND():
        return getMBeanName_WebSphereND(target, odlType)
    elif ora_mbs.isWebSphereAS():
        return getMBeanName_WebSphereAS(target, odlType)
    elif ora_mbs.isJBoss():
        return getMBeanName_JBoss(target, odlType)
    else:
        # should not happen
        raise "The command is not supported on platform: " + ora_mbs.getPlatform()

def getProxyLogQueryMBeanName():
    n = ObjectName("oracle.logging:type=LogQuery,name=ProxyLogQuery")
    if ora_mbs.isWebSphere():
        return getFullObjectName_WebSphere(n)
    return n

def getServerNames():
    if ora_mbs.isWebSphereND():
        return getServerNames_WebSphereND()
    elif ora_mbs.isWebSphereAS():
        return getServerNames_WebSphereAS()
    elif ora_mbs.isJBoss():
        return getServerNames_JBoss()
    else:
        # should not happen
        raise "The command is not supported on platform: " + ora_mbs.getPlatform()

def getTargetObjName(server, app):
    if ora_mbs.isWebSphere():
        return getTargetObjName_WebSphere(server, app)
    elif ora_mbs.isJBoss():
        return getTargetObjName_JBoss(server, app)
    else:
        # should not happen
        raise "The command is not supported on platform: " + ora_mbs.getPlatform()

def getSystemComponentTargetObjName(instance, server):
    if ora_mbs.isWebSphere():
        return getSystemComponentTargetObjName_WebSphere(instance, server)
    else:
        raise "System component targets are not supported on platform: " + ora_mbs.getPlatform()        

def getDefaultTarget():
    names = getServerNames()
    if len(names) == 1:
        return names[0]
    else:
        raise "Missing required argument: target"

def getPlatformName():
    if ora_mbs.isWebLogic():
        return "Weblogic"
    elif ora_mbs.isWebSphere():
        return "WebSphere"
    elif ora_mbs.isJBoss():
        return "JBoss"
    raise "Invalid platform"

#
# platform specific implementations
#

def getMBeanName_WebSphereND(target, odlType):
    baseName = "oracle.logging:type=" + odlType
    if target == None:
        raise "Parameter target is required on this platform"
    if odlType == "LogConfig":
        dmgr = AdminControl.completeObjectName("WebSphere:type=Server,processType=DeploymentManager,*")
        dmgrName=ObjectName(dmgr).getKeyProperty("name")
        baseName = baseName + ",process="+dmgrName + ",ServerName=" + target
    else:
        baseName = baseName + ",process=" + target
    baseName = baseName + ",*"
    names = ora_mbs.queryNames(ObjectName(baseName), Query.not(ObjectName("oracle.logging:type=LogQuery,name=ProxyLogQuery,*")))
    if names.size() == 0:
        print getMsg("MBEAN-NOT-FOUND", baseName)
    if names.size() == 1:
        return names.iterator().next()
    for n in names:
        if n.getKeyProperty("ServerName") == target:
            return n
    raise Exception, getMsg("MBEAN-NOT-FOUND", baseName)

def getMBeanName_WebSphereAS(target, odlType):
    baseName = "oracle.logging:type=" + odlType
    if target != None:
        baseName = baseName + ",process=" + target
    baseName = baseName + ",*"
    names = ora_mbs.queryNames(ObjectName(baseName), Query.not(ObjectName("oracle.logging:type=LogQuery,name=ProxyLogQuery,*")))
    if names.size() != 1:
        raise Exception, getMsg("MBEAN-NOT-FOUND", baseName)
    return names.iterator().next()

def getMBeanName_JBoss(target, odlType):
    baseName = "oracle.logging:type=" + odlType
    if target == None:
        target = ora_mbs.getAttribute(ObjectName("jboss.system:type=ServerConfig"), "ServerName")
    baseName = baseName + ",ServerName=" + target
    return ObjectName(baseName)

def getServerNames_WebSphereND():
    serverNames = []
    for n in ora_mbs.queryNames(ObjectName("WebSphere:type=Server,processType=DeploymentManager,*"), None).toArray():
        serverNames.append(n.getKeyProperty('name'))
    for n in ora_mbs.queryNames(ObjectName("WebSphere:type=Server,processType=ManagedProcess,*"), None).toArray():
        serverNames.append(n.getKeyProperty('name'))
    return serverNames

def getServerNames_WebSphereAS():
    serverNames = []
    for n in ora_mbs.queryNames(ObjectName("WebSphere:type=Server,processType=UnManagedProcess,*"), None).toArray():
        serverNames.append(n.getKeyProperty('name'))
    return serverNames

def getServerNames_JBoss():
    serverName = ora_mbs.getAttribute(ObjectName("jboss.system:type=ServerConfig"), "ServerName")
    return [serverName]

def getTargetObjName_WebSphere(server, app):
    if app == None:
        n=AdminControl.completeObjectName("WebSphere:type=Server,name="+server+",*")
        if n == '' or n == None:
            raise Exception, "Invalid target: " + str(server) 
        return ObjectName(n)
    else:
        n=AdminControl.completeObjectName("WebSphere:type=Application,name="+app+",process=" + server + ",*")
        if n == '' or n == None:
            raise Exception, "Invalid target: " + str(server) + "/" + str(app) 
        return ObjectName(n)

def getTargetObjName_JBoss(server, app):
    if app == None:
        return ObjectName("jboss.management.local:name=Local,j2eeType=J2EEServer,server=" + str(server))
    else:
        return ObjectName("jboss.management.local:j2eeType=J2EEApplication,name=" + str(app))

# add platform specific parameters to the keyword list
def addPlatformParams(kws):
    if not kws.has_key('platform'):
        kws['platform'] = getPlatformName()

def getSystemComponentTargetObjName_WebSphere(instance, component):
    if component == None:
        n=AdminControl.completeObjectName("oracle.as.management.mbeans.register:instance="+instance+",*")
        if n == '' or n == None:
            raise Exception, "Invalid target: opmn:" + str(instance)
        return ObjectName(n)
    else:
        n=AdminControl.completeObjectName("oracle.as.management.mbeans.register:instance="+instance+",component="+component+",*")
        if n == '' or n == None:
            raise Exception, "Invalid target: opmn:" + str(instance) + "/" + str(component)
        return ObjectName(n)
    
def getFullObjectName_WebSphere(name):
    fullname = AdminControl.completeObjectName(str(name)+",*")
    if fullname == '' or fullname == None:
        raise Exception, "Invalid ObjectName: " + str(name)
    return ObjectName(fullname);
