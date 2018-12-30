"""
 Copyright (c) 1998, 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move this file because this may cause
WLST commands and scripts to fail. Do not try to reuse the logic in this file or keep copies of this file
because this could cause your WLST scripts to fail when you upgrade to a different version of WLST.

This script holds all the helper functions for Webcenter Connections. 
@author Namita Varma
"""

import oracle.adf.share.wlst.resources.Messages as AdfMessages
import java.text.MessageFormat as MsgFormat

def adf_basicCheck():
    print 'File is syntactically correct'

def adf_debugIsEnabled():
    return false

# Returns an array of ObjectNames within the ADFConnections mbean for the appName application
def adf_getExistingConnObjNames(ADFConnObjName,connectionType):
    objs = jarray.array([java.lang.String(connectionType)],java.lang.Object)
    strs = jarray.array(['java.lang.String'],java.lang.String)
    connObjNameArray = mbs.invoke(ADFConnObjName,'listConnectionMBeans',objs,strs)
    return connObjNameArray

# Returns an ObjectName if a ADF Connection with the name connectionName and connectionType exists
def adf_getConnObjName(ADFConnObjName,connectionName,connectionType):
    connObjNameArray = adf_getExistingConnObjNames(ADFConnObjName,connectionType)
    searchStr = 'name='+connectionName
    for j in range(len(connObjNameArray)):
        connstr = connObjNameArray[j].toString()
        if adf_matchObjectNameElement(connstr, searchStr):
            return connObjNameArray[j]
    return None
    
# Returns true if a Connection MBean with name connectionName and type connectionType exists
def adf_connMBeanExists(ADFConnObjName,connectionName,connectionType):
    connNames = adf_customGetConnectionNames(ADFConnObjName,connectionType)
    if connectionName in connNames:
        return true
    return false

# Returns a String array of connection names.
def adf_customGetConnectionNames(ADFConnObjName,connectionType):
    objs = jarray.array([java.lang.String(connectionType)],java.lang.Object)
    strs = jarray.array(['java.lang.String'],java.lang.String)
    try:
        connNames = mbs.invoke(ADFConnObjName,'getConnectionNames',objs,strs)
        return connNames
    except WLSTException:
        adf_printErrorInvokingGetConnectionNames()
    return None


# Suppresses the display and returns an array of MBean Object Names that have the string 'oracle.adf.share.connections' 
def adf_getMBeanArray(appName):
    #redirect('outputFile','false')
    objname= ObjectName('*oracle.adf.share.connections:*')
    mbset = mbs.queryNames(objname,None)
    mbarray= mbset.toArray()
    return mbarray

# Returns the ADF Connections MBean's object name if it exists
def adf_getADFConn(mbeanarray,appName):
    searchADFandAppStr = 'name=ADFConnections,type=ADFConnections,Application='+appName
    for i in range(len(mbeanarray)):
        objnamestr = mbeanarray[i].toString()
        if objnamestr.find(searchADFandAppStr) >= 0:
            return mbeanarray[i]
    return None

# Messages

def adf_printFormattedMessage(key, objs):
    replacedMessage = MsgFormat.format(AdfMessages.get(key), objs);
    print replacedMessage

def adf_printADFConnectionUpdated(connectionName):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.CONN_UPDTD, objs)

def adf_printADFConnectionUpdateErr(connectionName):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.CONN_UPDTD_ERR, objs)

def adf_printNoADFConnectionMBean(appName):
    objs = jarray.array([appName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.NO_CONN_MBEAN, objs)
    
def adf_printConnectionAlreadyExists(connectionName):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.CONN_NAME_EXISTS, objs)


def adf_printErrorCreatingConn(connectionName):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.ERR_CREATE_CONN, objs)

def adf_printErrorSavingConns(appName):
    objs = jarray.array([appName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.ERR_SAVE_CONNS, objs)

def adf_printDebugMethodInfo(methodName, connectionName):
#   No translation this is for debug only
    if adf_debugIsEnabled():
        print 'In method ' + methodName + 'for connectionName '+ connectionName

def adf_printCreateSuccess(connectionName):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.CREATED_CONN, objs)

def adf_printDeleteSuccess(connectionName):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.CONN_DELETED, objs)

def adf_printSaveSuccess(appName):
    objs = jarray.array([appName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.SAVED_CONNS, objs)

def adf_printErrorInvokingGetConnectionNames():
    print 'Error invoking getConnectionNames'

def adf_printErrorInvokingAddConnectionName():
    print 'Error invoking addConnectionName'

def adf_printNoSuchApplication(appName):
    objs = jarray.array([appName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.NO_APPLICATION_FOUND, objs)

def adf_printNoSuchConnection(name):
    objs = jarray.array([connectionName],java.lang.String)
    adf_printFormattedMessage(AdfMessages.NO_CONN_FOUND, objs)

def adf_printSetConnection(name):
    print 'Connection '+name+' is set'    

def adf_printNoConnections(connectionType):
    print 'No connections of type '+ connectionType+' Connections'

def adf_printSetError(attr=''):
    if attr=='':
        print 'Error occured while performing set'
    else:
        print 'Error occured while performing set for attribute '+attr

def adf_printGetError(attr):
    print 'Error occured while performing get for attribute '+attr

def adf_invalidURL():
    print 'URL specified is invalid'


# Returns the user's directory if initialization is successful. Returns the null object if initialization fails.
def adf_Initialize():
    if mbs is None:
        adf_printNotConnected()
        return None
    #redirect('outputFile','false')
    origDirectory = pwd()
    domainRuntime()
    return origDirectory

# Restore the user context. If origDirectory is null because of failed initalization, does nothing
def adf_Restore(origDirectory):
    if origDirectory is None:
        return
    #stopRedirect()
    cd(origDirectory)


# Suppresses the display and returns an array of MBean Object Names that have the string 'oracle.adf.share.connections' 
def adf_getMBeanArrayInADFConnections():
    objname= ObjectName('*oracle.adf.share.connections:*')
    try:
        mbset = mbs.queryNames(objname,None)
        mbarray= mbset.toArray()
        return mbarray
    except WLSTException:
        adf_printErrorMBSQueryNames('*oracle.adf.share.connections:*')
    return None

def adf_printErrorMBSQueryNames(str):
    print 'Error occured while performing mbs.queryNames(objname) for '+str

def adf_matchObjectNameElement(objNameStr, element):
    start = objNameStr.find(element)
    finish = -1
    if (start > 0) and (objNameStr[start - 1] != ","):
        start = -1
    if start >= 0:
        finish = objNameStr.find(",", start)
        if finish < 0:
            finish = len(objNameStr)
    return (start >= 0) and (finish == (start + len(element)))

# Returns the ADF Connections MBean's object name if it exists
def adf_getADFConnectionObjName(mbeanarray,appName):
    nameADFConn = 'name=ADFConnections'
    typeADFConn = 'type=ADFConnections'
    appNameStr = 'Application='+appName
    if adf_debugIsEnabled():
        searchADFandAppStr = nameADFConn + "," + typeADFConn + "," + appNameStr
        print 'searchADFandAppStr = ' + searchADFandAppStr
    for i in range(len(mbeanarray)):
        objnamestr = mbeanarray[i].toString()
        if adf_debugIsEnabled():
            print "objnamestr = " + objnamestr
        if adf_matchObjectNameElement(objnamestr, nameADFConn):
            if adf_matchObjectNameElement(objnamestr, typeADFConn):
                if adf_matchObjectNameElement(objnamestr, appNameStr):
                    return mbeanarray[i]
    return None

# Helper function for createXXXConnection 
def adf_customCreateConnection(appName,connectionName,connectionType,userArg):
    adf_printDebugMethodInfo('adf_customCreateConnection', connectionName) 
    mbeanarray = adf_getMBeanArrayInADFConnections()
    ADFConnObjName = adf_getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        adf_printNoADFConnectionMBean(appName)
        return None
    # Initialize the variable
    objNameStr = None
    # If a Connection MBean with that name already exists, abort the creation.
    if adf_connMBeanExists(ADFConnObjName,connectionName,connectionType):
        adf_printConnectionAlreadyExists(connectionName)
    else:
        objs = jarray.array([java.lang.String(connectionType),java.lang.String(connectionName)],java.lang.Object)
        strs = jarray.array(['java.lang.String','java.lang.String'],java.lang.String)
        try:
            connObjName=mbs.invoke(ADFConnObjName,'createConnection',objs,strs)
            objNameStr = connObjName.toString()
            adf_printCreateSuccess(connectionName)
        except WLSTException:
            adf_printErrorCreatingConn(connectionName)
            return None
    adf_customSetConnection(appName,connectionName,connectionType,userArg,true) 
    return  objNameStr

# Helper function for setXXXConnection
def adf_customSetConnection(appName,connectionName,connectionType,userArg,fromCreate):
    adf_printDebugMethodInfo('adf_customSetConnection', connectionName) 
    mbeanarray = adf_getMBeanArrayInADFConnections()
    ADFConnObjName = adf_getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        adf_printNoADFConnectionMBean(appName)
        return
    
    # If a Connection MBean with that name exists, set the connection
    connObjName = adf_getConnObjName(ADFConnObjName,connectionName,connectionType)
    if connObjName is None:
        adf_printNoSuchConnection(connectionName)
        return
    for arg in userArg.items():
        if adf_debugIsEnabled():
            print arg[0]
            print arg[1]
        try:
            mbs.setAttribute(connObjName,Attribute(arg[0],arg[1]))
        except WLSTException:
            printSetError(arg[0])
    if not fromCreate:
        adf_printSetConnection(connectionName)

# Helper function for deleteXXXConnection
def adf_customDeleteConnection(appName,connectionName,connectionType):
    adf_printDebugMethodInfo('adf_customDeleteConnection', connectionName) 
    mbeanarray = adf_getMBeanArrayInADFConnections()
    ADFConnObjName = adf_getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        adf_printNoADFConnectionMBean(appName)
        return None
    
    # If a Connection MBean with that name exists, delete the connection
    connObjName = adf_getConnObjName(ADFConnObjName,connectionName,connectionType)
    if connObjName is None:
        adf_printNoSuchConnection(connectionName)
    else:
        objs = jarray.array([java.lang.String(connectionName)],java.lang.Object)
        strs = jarray.array(['java.lang.String'],java.lang.String)
        try:
            mbs.invoke(ADFConnObjName,'removeConnection',objs,strs)
            adf_printDeleteSuccess(connectionName)
        except WLSTException:
            adf_printErrorDeletingConn(connectionName)

    return None
    
#Build a dictionary from fields
def adf_buildFieldCred(fields):
    fieldDic ={}
    for f in fields:
        sepfieldList = f.split(':',1)
        fieldName=sepfieldList[0]
        fieldValue=sepfieldList[1]
        if adf_debugIsEnabled():
            print fieldName
            print fieldValue
        fieldDic[fieldName]=fieldValue
    return fieldDic
    
# Save connections
def adf_saveConnections(appName):
    adf_printDebugMethodInfo('adf_saveConnections', appName) 
    mbeanarray = adf_getMBeanArrayInADFConnections()
    ADFConnObjName = adf_getADFConnectionObjName(mbeanarray, appName)
    if ADFConnObjName is None:
        adf_printNoADFConnectionMBean(appName)
        return None
    objs = jarray.array([], java.lang.Object)
    strs = jarray.array([], java.lang.String)
    try:
        connObjName = mbs.invoke(ADFConnObjName, 'save', objs, strs)
        adf_printSaveSuccess(appName)
    except WLSTException:
        adf_printErrorSavingConns(appName)
        return None
    
# Returns an ObjectName if a ADF Connection with the connectionType 
def adf_listConnections(appName,connectionType):
    if appName is None:
        return
    objname= ObjectName('*oracle.adf.share.connections:type=ADFConnections,name=ADFConnections,Application=' + appName + ',*')
    mbset = mbs.queryNames(objname,None)
    if adf_debugIsEnabled():
        print 'objname = ' + objname.toString()
        print 'mbset = ' + mbset.toString()
    mbarray= mbset.toArray()
    if mbarray is None:
        return
    for i in range(len(mbarray)):
        connList = adf_getExistingConnObjNames(mbarray[i], connectionType)
        if connList is not None:
            for j in range(len(connList)):
                conn = connList[j]
                print conn.toString()
                if adf_debugIsEnabled():
                    adf_printURLAttributes(conn)
                    
def adf_setADFConnectionGenericAttr(appName, connType, connName, propName, propVal):
    adf_printDebugMethodInfo('adf_setADFConnectionGenericAttr', appName)
    mbeanarray = adf_getMBeanArrayInADFConnections()
    ADFConnObjName = adf_getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        adf_printNoADFConnectionMBean(appName)
        return
    
    # check if connection MBean with that name exists.
    if adf_connMBeanExists(ADFConnObjName,connName,connType):
        objs = jarray.array([java.lang.String(connName), java.lang.String(propName),java.lang.String(propVal)],java.lang.Object)
        strs = jarray.array(['java.lang.String','java.lang.String','java.lang.String'],java.lang.String)
        try:
            mbs.invoke(ADFConnObjName, 'updateADFConnectionGenericAttribute', objs, strs)
            adf_saveConnections(appName)
            adf_printADFConnectionUpdated(connName)
        except WLSTException:
            adf_printADFConnectionUpdateErr(connName)    
            
    else:
        adf_printNoSuchConnection(connName)
        return
        
# Display ADF child connection generic attributes
def adf_printADFConnectionGenericAttr(appName, connType, connName, propName):
    adf_printDebugMethodInfo('adf_printADFConnectionGenericAttr', appName)
    mbeanarray = adf_getMBeanArrayInADFConnections()
    ADFConnObjName = adf_getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        adf_printNoADFConnectionMBean(appName)
        return
    
    # check if connection MBean with that name exists.
    if adf_connMBeanExists(ADFConnObjName,connName,connType):
        objs = jarray.array([java.lang.String(connName),java.lang.String(propName)],java.lang.Object)
        strs = jarray.array(['java.lang.String','java.lang.String'],java.lang.String)
        try:
            value = mbs.invoke(ADFConnObjName, 'getADFConnectionGenericAttribute', objs, strs)
            if value is not None:
               print propName + ' = ' + value
        except:
            adf_printGetError(propName)
    else:
        adf_printNoSuchConnection(connName)
        return        

# Display a single URL connection attribute
def adf_printAttribute(conn, name):
    if conn is None or name is None:
        return
    try:
        value = mbs.getAttribute(conn, name)
        if value is not None:
            print name + ' = ' + value
    except:
        adf_printGetError(name)

# Display URL connection attributes
def adf_printURLAttributes(conn):
    adf_printAttribute(conn, 'ConnectionName')
    adf_printAttribute(conn, 'ConnectionType')
    adf_printAttribute(conn, 'ConnectionClassName')
    adf_printAttribute(conn, 'URL')
    adf_printAttribute(conn, 'ChallengeAuthenticationType')
    adf_printAttribute(conn, 'AuthenticationRealm')
