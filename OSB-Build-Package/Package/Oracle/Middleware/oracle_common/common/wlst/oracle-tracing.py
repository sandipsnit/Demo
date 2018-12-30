"""
 Copyright (c) 2011, 2013, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move
this file because this may cause WLST commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WLST scripts to fail when you upgrade to a different version
of WLST.

Oracle Fusion Middleware tracing commands.

"""

import jarray
import sys
from types import ListType
from types import TupleType

def startTracing(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_startTracing(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def stopTracing(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_stopTracing(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def listActiveTraces(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_listActiveTraces(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def listTracingLoggers(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_listTracingLoggers(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def configureTracingLoggers(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_configureTracingLoggers(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def listTraceProviders(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_listTraceProviders(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def configureTraceProvider(**kws):
    oracle_tracing_checkConnected()
    try:
        cwd = pwd()
        oracle_tracing_cdDomainRuntime()
        return oracle_tracing_configureTraceProvider(**kws)
    finally:
        if cwd != None and len(cwd) > 0:
            cd(cwd)

def oracle_tracing_startTracing(**kws):
    import java.lang.Exception
    import java.lang.IllegalArgumentException
    import java.lang.Long
    import java.lang.NumberFormatException
    import java.lang.Object
    import java.lang.String
    import javax.management.ObjectName
    from oracle.core.ojdl.logging import ODLLevel
    validParams = ['target', 'level', 'attrName', 'attrValue', 'user', 'traceId', 'desc', 'duration', 'providerParams']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    level = kws.get("level")
    if level is None:
        raise WLSTException, oracle_tracing_getMsg("MISSING-ARG", "level")
    try:
        if len(level) > 0:
            ODLLevel.parse(level)
    except java.lang.IllegalArgumentException:
        raise WLSTException, oracle_tracing_getMsg("INVALID-LEVEL", level)
    user = kws.get("user")
    if not user is None:
        attrName = "USER_ID"
        attrValue = user
    else:
        attrName = kws.get("attrName")
        if attrName is None:
            raise WLSTException, oracle_tracing_getMsg("MISSING-ARG", "attrName")
        attrValue = kws.get("attrValue")
        if attrValue is None:
            raise WLSTException, oracle_tracing_getMsg("MISSING-ARG", "attrValue")
    traceId = kws.get("traceId")
    desc = kws.get("desc")
    duration = 0
    if kws.has_key("duration"):
        try:
            duration = java.lang.Long.parseLong(str(kws.get("duration")))
        except java.lang.NumberFormatException:
            raise WLSTException, oracle_tracing_getMsg("INVALID-DURATION", kws.get("duration"))

    mbean = oracle_tracing_getMBeanName()

    if kws.has_key("providerParams"):
        params = kws.get("providerParams")
        if not isinstance(params, types.DictType):
            raise WLSTException, oracle_tracing_getMsg("INVALID-PROVIDER-PARAMS")

        try:
            providers = mbs.invoke(mbean, "getTraceProviderInfo", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
        except java.lang.Exception, e:
            raise WLSTException, oracle_tracing_getExceptionMsg(e)        

        for k in params.keys():

            provider = None
            for p in providers:
                if p.get("name") == k:
                    provider = p
                    break

            if provider == None:
                raise WLSTException, oracle_tracing_getMsg("INVALID-TRACE-PROVIDER", k)
            
            v = params.get(k)
            if not isinstance(v, types.DictType):
                raise WLSTException, oracle_tracing_getMsg("INVALID-PROVIDER-PARAMS")

            validParams = []
            providerParams = provider.get("parameterInfo")
            if providerParams != None:
                for providerParam in providerParams:
                    validParams.append(providerParam.get("name"))
            
            for paramName in v.keys():
                if not paramName in validParams:
                    raise WLSTException, oracle_tracing_getMsg("INVALID-PROVIDER-PARAM", paramName, k)                
            
        providerParams = oracle_tracing_dict_dict_to_opentype(params)
    else:
        providerParams = None

    try:
        traceId = mbs.invoke(mbean, "startTracing", jarray.array([jarray.array(targets, javax.management.ObjectName), traceId, attrName, attrValue, level, java.lang.Long(duration), desc, providerParams], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'long', 'java.lang.String', 'javax.management.openmbean.TabularData'], java.lang.String))
        print oracle_tracing_getMsg("STARTED-TRACING", str(traceId))
        return traceId
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)

def oracle_tracing_stopTracing(**kws):
    import java.lang.Exception
    import java.lang.Object
    import java.lang.String
    import javax.management.ObjectName
    validParams = ['target', 'traceId', 'attrName', 'attrValue', 'user', 'stopAll', 'createIncident']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)
    stopAllKw = kws.get("stopAll")
    if stopAllKw == None or stopAllKw == 0 or str(stopAllKw).lower() == "false":
        stopAll = 0
    else:
        stopAll = 1        
    traceId = kws.get("traceId")
    user = kws.get("user")
    if not user is None:
        attrName = "USER_ID"
        attrValue = user
    else:
        attrName = kws.get("attrName")
        attrValue = kws.get("attrValue")
    if not stopAll and traceId == None and attrName == None and attrValue == None:
        raise WLSTException, oracle_tracing_getMsg("MISSING-ARGS", "stopTracing")
    if not stopAll and traceId != None and attrName != None:
        raise WLSTException, oracle_tracing_getMsg("INVALIDE-PARAMS", "traceId", "attrName/user")
    createIncident = oracle_tracing_getBool(kws.get("createIncident", 0))
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    mbean = oracle_tracing_getMBeanName()
    stopped = []
    try:
        activeTraces = mbs.invoke(mbean, "getActiveTraces", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
        for ti in activeTraces:
            match = stopAll \
                    or (traceId != None and traceId == ti.get("traceId")) \
                    or (attrName != None and attrValue != None and ti.get("attrName") == attrName and ti.get("attrValue") == attrValue) \
                    or (attrName != None and attrValue == None and ti.get("attrName") == attrName)
            if match:
                mbs.invoke(mbean, "stopTracing", jarray.array([jarray.array(targets, javax.management.ObjectName), ti.get("traceId"), createIncident], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;', 'java.lang.String', 'boolean'], java.lang.String))
                stopped.append(ti)
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)
    print oracle_tracing_getMsg("STOPPED-TRACING", str(len(stopped)))

    if createIncident:
        try:
            for ti in stopped:
                problemKey = "TRACE_ID:" + ti.get("traceId")
                dfwMBean = ObjectName("oracle.dfw:type=oracle.dfw.jmx.IncidentManagerProxyMXBean,name=IncidentManagerProxy")
                problemMap = mbs.getAttribute(dfwMBean, "Problems")
                selectedProblems = []
                for server in problemMap.keySet():
                    problems = problemMap.get(jarray.array(server,java.lang.String)).get("value")
                    for problem in problems:
                        if problemKey == problem.get("problemKey"):
                            selectedProblems.append((server[0], problem.get("problemId")))
                table = []
                for server_problem in selectedProblems:
                    server = server_problem[0]
                    problemId = server_problem[1]
                    incidents = mbs.invoke(dfwMBean, "getIncidents", jarray.array([server, problemId],java.lang.Object), jarray.array(["java.lang.String", "java.lang.String"],java.lang.String))   
                    for incident in incidents:
                        table.append([server,incident.get("incidentId")])
                if len(table) > 0:
                    print
                    print oracle_tracing_getMsg("TRACE-INCIDENT-CREATED", problemKey)
                    print
                    oracle_tracing_print_table(["Server", "Incident ID"], table)
                    print
                else:
                    print
                    print oracle_tracing_getMsg("TRACE-INCIDENT-NOT-CREATED", problemKey);
                    print
        except java.lang.Exception, e:
            print oracle_tracing_getMsg("TRACE-INCIDENT-ERROR", str(e))
    
    return stopped

def oracle_tracing_listActiveTraces(**kws):
    import java.lang.Exception
    import java.lang.String
    import java.lang.Object
    import java.text.SimpleDateFormat
    import javax.management.ObjectName
    validParams = ['target']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    mbean = oracle_tracing_getMBeanName()
    list = []
    try:
        list = mbs.invoke(mbean, "getActiveTraces", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)
    if len(list) > 0:
        sdf = java.text.SimpleDateFormat()
        table = []
        for ti in list:
            expTime = ""
            if ti.get("expirationTime") > 0:
                expTime = sdf.format(ti.get("expirationTime"))
            startTime = ""
            if ti.get("startTime") > 0:
                startTime = sdf.format(ti.get("startTime"))
            level = ti.get("level")
            if not isinstance(level, str):
                level = level.get("name")
            table.append([ti.get("traceId"), ti.get("attrName"), ti.get("attrValue"), level, startTime, expTime, ti.get("desc")])
        oracle_tracing_print_table(["Trace ID", "Attr. Name", "Attr. Value", "Level", "Start Time", "Exp. Time", "Description"], table)
    else:
        print oracle_tracing_getMsg("NO-TRACES")
    return list

def oracle_tracing_listTracingLoggers(**kws):
    import java.lang.Exception
    import java.lang.Object
    import java.lang.String
    import javax.management.ObjectName
    validParams = ['target', 'pattern']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    patterns = []
    patternStrings = kws.get("pattern")
    if patternStrings != None:
        if not (isinstance(patternStrings, ListType) or isinstance(patternStrings, TupleType)):
            patternStrings = [patternStrings]
        from java.util.regex import Pattern
        for pat in patternStrings:
            patterns.append(Pattern.compile(pat))
    mbean = oracle_tracing_getMBeanName()
    map = None
    try:
        map = mbs.invoke(mbean, "getTracingLoggers", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)
    table = []
    loggers = []
    ret = {}
    for m in map.values():
        k = m.get("key")
        v = m.get("value")
        if len(patterns) > 0:
            for pat in patterns:
                if pat.matcher(k).matches():
                    loggers.append(k)
                    ret[k] = v
        else:
            loggers.append(k)
            ret[k] = v
    if len(loggers) == 0:
        if len(patterns) > 0:
            print oracle_tracing_getMsg("NO-LOGGERS-MATCH")
        else:
            print oracle_tracing_getMsg("NO-LOGGER")
    else:
        loggers.sort()
        for l in loggers:
            table.append([l, ret[l]])
        oracle_tracing_print_table(["Logger", "Status"], table)
    return ret

def oracle_tracing_configureTracingLoggers(**kws):
    import java.lang.Exception
    import java.lang.Object
    import java.lang.String
    import java.util.regex.Pattern
    import javax.management.ObjectName
    validParams = ['target', 'pattern', 'action']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    action = kws.get("action")
    if action == None:
        raise WLSTException, oracle_tracing_getMsg("MISSING-ARG", "action")
    action = str(action).lower()
    if not (action == "enable" or action == "disable"):
        raise WLSTException, "Invalid value for parameter 'action': " + kws.get("action") + ". Expected 'enable' or 'disable'."
    patternStrings = kws.get("pattern")
    if patternStrings != None and ( not (isinstance(patternStrings, ListType) or isinstance(patternStrings, TupleType))):
        patternStrings = [patternStrings]
    patterns = []
    if patternStrings != None:
        for pat in patternStrings:
            try:
                patterns.append(java.util.regex.Pattern.compile(pat))
            except java.lang.Exception, e:
                raise WLSTException, oracle_tracing_getExceptionMsg(e)
    mbean = oracle_tracing_getMBeanName()
    map = None
    try:
        map = mbs.invoke(mbean, "getTracingLoggers", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)
    loggers = {}
    enable = action == "enable"
    for m in map.values():
        logger = m.get("key")
        status = m.get("value")
        if len(patterns) > 0:
            for pat in patterns:
                if pat.matcher(logger).matches():
                    loggers[logger] = enable
        else:
            loggers[logger] = enable
    if len(loggers) == 0:
        print oracle_tracing_getMsg("NO-LOGGERS-MATCH")
        return loggers
    try:
        td = oracle_tracing_dict_to_opentype(loggers)
        mbs.invoke(mbean, "configureTracingLoggers", jarray.array([jarray.array(targets, javax.management.ObjectName), td], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;', 'javax.management.openmbean.TabularData'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)
    print oracle_tracing_getMsg("CONF-LOGGERS", str(len(loggers)))
    return loggers

def oracle_tracing_listTraceProviders(**kws):
    import java.lang.Exception
    import java.lang.Object
    import java.lang.String
    import javax.management.ObjectName

    validParams = ['target', 'name']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)

    mbean = oracle_tracing_getMBeanName()
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    name = kws.get("name")

    providers = None
    enabledProviders = None
    try:
        providers = mbs.invoke(mbean, "getTraceProviderInfo", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
        enabledProviders = mbs.invoke(mbean, "getEnabledProviders", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)

    result = []
    for provider in providers:
        pName = provider.get("name")
        if name != None and len(name) > 0 and name != pName:
            continue
        result.append(provider)
        print "Name: " + pName
        print "Full Name: " + str(provider.get("userVisibleName"))
        if pName in enabledProviders:
            status = "enabled"
        else:
            status = "disabled"
        print "Status: " + status
        print "Description: " + str(provider.get("description"))
        params = provider.get("parameterInfo")
        if params != None and len(params) > 0:
            print "Provider Parameters:"
            header = ["Name", "Full name", "Type", "Description"]
            rows = []
            for param in params:
                rows.append([param.get("name"), param.get("userVisibleName"), param.get("type"), param.get("description")])
            oracle_tracing_print_table2(header, rows, 0, 3)
        print ""

    if name != None and len(result) == 0:
        raise WLSTException, oracle_tracing_getMsg("INVALID-TRACE-PROVIDER", name)

    return result

def oracle_tracing_configureTraceProvider(**kws):
    import java.lang.Exception
    import java.lang.Object
    import java.lang.String
    import javax.management.ObjectName

    validParams = ['target', 'name', 'action']
    for k in kws.keys():
        if not k in validParams:
            raise WLSTException, oracle_tracing_getMsg("UNEXPECTED-PARAM", k)

    mbean = oracle_tracing_getMBeanName()
    targets = oracle_tracing_getTargetNames(kws.get("target"))
    name = kws.get("name")
    if name == None:
        raise WLSTException, oracle_tracing_getMsg("MISSING-ARG", "name")
    action = kws.get("action")
    if action == None:
        raise WLSTException, oracle_tracing_getMsg("MISSING-ARG", "action")
    action = str(action)
    if not (action.lower() == "enable" or action.lower() == "disable"):
        raise WLSTException, oracle_tracing_getMsg("INVALID-PARAM-VALUE", "action", str(["enable","disable"]))

    providers = None
    enabledProviders = None
    try:
        providers = mbs.invoke(mbean, "getAvailableProviders", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
        enabledProviders = mbs.invoke(mbean, "getEnabledProviders", jarray.array([jarray.array(targets, javax.management.ObjectName)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)

    if not name in providers:
        raise WLSTException, oracle_tracing_getMsg("INVALID-TRACE-PROVIDER", name)
    changed = 0
    if action == "enable":
        if not name in enabledProviders:
            enabledProviders.append(name)
            changed = 1
        status = "enabled"
    else:
        if name in enabledProviders:
            enabledProviders.remove(name)
            changed = 1
        status = "disabled"
    try:
        if changed:
            mbs.invoke(mbean, "setEnabledProviders", jarray.array([jarray.array(targets, javax.management.ObjectName), jarray.array(enabledProviders, java.lang.String)], java.lang.Object), jarray.array(['[Ljavax.management.ObjectName;','[Ljava.lang.String;'], java.lang.String))
    except java.lang.Exception, e:
        raise WLSTException, oracle_tracing_getExceptionMsg(e)

    print "Trace provider " + str(name) + " is " + status

def oracle_tracing_getMBeanName():
    from javax.management import ObjectName
    name = ObjectName("oracle.tracing:type=TracingManagerMXBean")
    if not mbs.isRegistered(name):
        raise WLSTException, oracle_tracing_getMsg("TRACING-MBEAN-NOT-FOUND",str(name))
    return name                  
        
def oracle_tracing_getTargetNames(targets):
    from javax.management import ObjectName
    targetNames = []
    if targets is None:
        return targetNames
    if not (isinstance(targets, ListType) or isinstance(targets, TupleType)):
        targets = [targets]
    for target in targets:
        targetNames.append(ObjectName("com.bea:Type=Server,Name="+target))
    return targetNames

def oracle_tracing_cdDomainRuntime():
    from javax.management import ObjectName
    if isAdminServer == "true":
        if mbs.isRegistered(ObjectName("com.bea:Name=DomainRuntimeService,Type=weblogic.management.mbeanservers.domainruntime.DomainRuntimeServiceMBean")):
            return None
        cwd = pwd()
        cd("domainRuntime:/")
        return cwd
    raise WLSTException, oracle_tracing_getMsg("WRONG-SERVER")

def oracle_tracing_checkConnected():
    if mbs == None:
        raise WLSTException, oracle_tracing_getMsg("NOT-CONNECTED", "Weblogic")

def oracle_tracing_getMsg(key, *args):
    from java.lang import Class
    from java.lang import String
    from java.text import MessageFormat
    from java.util import Locale
    from java.util import ResourceBundle
    try:
        rb = ResourceBundle.getBundle("oracle.as.management.logging.messages.Messages", Locale.getDefault(), Class.forName("oracle.as.management.logging.messages.Messages").getClassLoader())
        if rb.containsKey(key):
            msg = rb.getString(key)
            return MessageFormat.format(msg, jarray.array(args, String))
    except:
        pass
    return key

def oracle_tracing_getExceptionMsg(t):
    setDumpStackThrowable(t)
    msg = t.getMessage()
    if msg == None:
        msg = str(t)
    return msg + "\n" + oracle_tracing_getMsg("STACK-INFO", "dumpStack()")

def oracle_tracing_print_table(header, rows):
    oracle_tracing_print_table2(header, rows, 1, 0);

def oracle_tracing_print_table2(header, rows, printBorder, offset):
    max = []
    for h in header:
        max.append(len(h))
    for r in rows:
        for i in range(0,len(r)):
            c = r[i]
            if c == None:
                c = ""
            if len(c) > max[i]:
                max[i] = len(c)
    colSep = "   "
    if printBorder:
        border = "".ljust(offset) + "".ljust(max[0]).replace(" ", "-")    
        for i in range(1,len(max)):
            border = border + "-+-" + "".ljust(max[i]).replace(" ","-")
        print border
        colSep = " | "
    line = "".ljust(offset) + header[0].ljust(max[0])
    for i in range(1,len(max)):
        line = line + colSep
        if i < len(max)-1:
            line = line + header[i].ljust(max[i])
        else:
            line = line + header[i]
    print line
    if printBorder:
        print border
    for r in rows:
        v = r[0]
        if v == None:
            v = ""
        line = "".ljust(offset) + v.ljust(max[0])
        for i in range(1, len(max)):
            v = r[i]
            if v == None:
                v = ""
            line = line + colSep
            if i < len(max)-1:
                line = line + v.ljust(max[i])
            else:
                line = line + v
        print line
        
def oracle_tracing_getBool(v):
    return v and str(v).lower() != "false"

def oracle_tracing_dict_to_opentype(dict):
    from java.lang import Boolean
    from java.lang import Object
    from java.lang import String
    from javax.management.openmbean import CompositeDataSupport
    from javax.management.openmbean import CompositeType
    from javax.management.openmbean import SimpleType
    from javax.management.openmbean import TabularDataSupport
    from javax.management.openmbean import TabularType
    typeName = "java.util.Map<java.lang.String, java.lang.Boolean>"
    keyValue = jarray.array(["key","value"],String)
    openTypes = jarray.array([SimpleType.STRING, SimpleType.BOOLEAN], SimpleType)
    rowType = CompositeType(typeName,typeName,keyValue,keyValue,openTypes)
    tabularType = TabularType(typeName,typeName,rowType,jarray.array(["key"],String));
    td = TabularDataSupport(tabularType)
    for k in dict.keys():
        v = dict[k]
        b = Boolean(v)
        cd = CompositeDataSupport(tabularType.getRowType(), keyValue, jarray.array([k,b], Object))
        td.put(cd)
    return td

# convert a dictionary of string to dictionaries (Map<String,Map<String,String>>) to open type 
def oracle_tracing_dict_dict_to_opentype(dict):
    from java.lang import Boolean
    from java.lang import Object
    from java.lang import String
    from javax.management.openmbean import CompositeDataSupport
    from javax.management.openmbean import CompositeType
    from javax.management.openmbean import OpenType
    from javax.management.openmbean import SimpleType
    from javax.management.openmbean import TabularDataSupport
    from javax.management.openmbean import TabularType
    innerTypeName = "java.util.Map<java.lang.String,java.lang.String>"
    keyValue = jarray.array(["key","value"],String)
    key = jarray.array(["key"],String)
    innerRowType = CompositeType(innerTypeName,innerTypeName,keyValue,keyValue, jarray.array([SimpleType.STRING,SimpleType.STRING],SimpleType))
    innerMapType = TabularType(innerTypeName,innerTypeName,innerRowType,key)
    outerTypeName = "java.util.Map<java.lang.String,"+str(innerTypeName)+">"
    outerRowType = CompositeType(outerTypeName,outerTypeName,keyValue,keyValue, jarray.array([SimpleType.STRING,innerMapType], OpenType))
    outerMapType = TabularType(outerTypeName,outerTypeName,outerRowType,key)
    td = TabularDataSupport(outerMapType)
    for k in dict.keys():
        innerTd = TabularDataSupport(innerMapType)
        innerDict = dict[k]
        for i in innerDict.keys():
            innerCd = CompositeDataSupport(innerMapType.getRowType(),keyValue, jarray.array([i, innerDict[i]], java.lang.Object))
            innerTd.put(innerCd)
        cd = CompositeDataSupport(outerMapType.getRowType(), keyValue, jarray.array([k, innerTd], Object))
        td.put(cd)
    return td


try:
    try:
        addHelpCommandGroup("fmw diagnostics","oracle.as.management.logging.messages.CommandHelp")
    except:
        pass
    addHelpCommand("startTracing", "fmw diagnostics", online="true")
    addHelpCommand("stopTracing", "fmw diagnostics", online="true")
    addHelpCommand("listActiveTraces", "fmw diagnostics", online="true")
    addHelpCommand("listTracingLoggers", "fmw diagnostics", online="true")
    addHelpCommand("configureTracingLoggers", "fmw diagnostics", online="true")
    addHelpCommand("listTraceProviders", "fmw diagnostics", online="true")
    addHelpCommand("configureTraceProvider", "fmw diagnostics", online="true")
except:
    pass
