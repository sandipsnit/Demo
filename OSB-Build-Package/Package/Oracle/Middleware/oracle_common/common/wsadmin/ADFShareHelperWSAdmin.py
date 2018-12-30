"""
 Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WSADMIN implementation.  Do not edit or move
this file because this may cause WSADMIN commands and scripts to fail.  Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WSADMIN scripts to fail when you upgrade to a different
version of WSADMIN.

ADF share helper methods.

  MODIFIED (MM/DD/YY)
  amrashid  06/17/12 - XbranchMerge amrashid_bug-14169390 from main
  rmaslins  11/15/10 - XbranchMerge rmaslins_bug-8239542 from main
  rmaslins  11/10/10 - Added copyright notice and caution message.
  rmaslins  09/21/10 - XbranchMerge rmaslins_bug-10080394 from main
  rmaslins  04/09/10 - Creation.

"""

import jarray

from jarray import array
from java.lang import Object
from java.lang import String
from java.lang import Exception
from java.lang import RuntimeException

import oracle.adf.share.wlst.resources.Messages as AdfMessages
import java.text.MessageFormat as MsgFormat

from javax.management import Attribute

import ora_mbs
import ora_util

# Code for detecting syntax error, especially missing colons
def check():
    print 'File OK'

# Enable additional messages
def debugIsEnabled():
    return 0

# Returns an array of ObjectNames within the ADFConnections mbean for the appName application
def getExistingConnObjNames(ADFConnObjName, connectionType):
    objs = jarray.array([String(connectionType)], Object)
    strs = jarray.array(['java.lang.String'], String)
    connObjNameArray = ora_mbs.invoke(ADFConnObjName, 'listConnectionMBeans', objs, strs)
    return connObjNameArray

# Returns an ObjectName if a ADF Connection with the name connectionName and connectionType exists
def getConnObjName(ADFConnObjName, connectionName, connectionType):
    connObjNameArray = getExistingConnObjNames(ADFConnObjName, connectionType)
    searchStr = 'name=' + connectionName
    for j in range(len(connObjNameArray)):
        connstr = connObjNameArray[j].toString()
        if matchObjectNameElement(connstr, searchStr):
            return connObjNameArray[j]
    return None
    
# Returns true if a Connection MBean with name connectionName and type connectionType exists
def connMBeanExists(ADFConnObjName, connectionName, connectionType):
    connNames = customGetConnectionNames(ADFConnObjName, connectionType)
    return connectionName in connNames

# Returns a String array of connection names.
def customGetConnectionNames(ADFConnObjName, connectionType):
    objs = jarray.array([String(connectionType)], Object)
    strs = jarray.array(['java.lang.String'], String)
    try:
        connNames = ora_mbs.invoke(ADFConnObjName, 'getConnectionNames', objs, strs)
        return connNames
    except RuntimeException, e:
        printErrorInvokingGetConnectionNames()
        saveStackAndRaiseException(e, '')
    return None

def saveStackAndRaiseException(ex, message):
    # No dumpstack command is available in WSADMIN for now. Print the messages alone for now.
    errmsg = ex.getMessage() + message
    raise ora_util.OracleScriptingException, errmsg

# Messages

def printFormattedMessage(key, objs):
    replacedMessage = MsgFormat.format(AdfMessages.get(key), objs);
    print replacedMessage

def printADFConnectionUpdated(connectionName):
    objs = jarray.array([connectionName],String)
    printFormattedMessage(AdfMessages.CONN_UPDTD, objs)

def printADFConnectionUpdateErr(connectionName):
    objs = jarray.array([connectionName],String)
    printFormattedMessage(AdfMessages.CONN_UPDTD_ERR, objs)

def printNoADFConnectionMBean(appName):
    objs = jarray.array([appName], String)
    printFormattedMessage(AdfMessages.NO_CONN_MBEAN, objs)
    
def printConnectionAlreadyExists(connectionName):
    objs = jarray.array([connectionName], String)
    printFormattedMessage(AdfMessages.CONN_NAME_EXISTS, objs)

def printErrorCreatingConn(connectionName):
    objs = jarray.array([connectionName], String)
    printFormattedMessage(AdfMessages.ERR_CREATE_CONN, objs)

def printErrorSavingConns(appName):
    objs = jarray.array([appName], String)
    printFormattedMessage(AdfMessages.ERR_SAVE_CONNS, objs)

def printDebugMethodInfo(methodName, connectionName):
    # No translation this is for debug only
    if debugIsEnabled():
        print 'In method ' + methodName + 'for connectionName ' + connectionName

def printCreateSuccess(connectionName):
    objs = jarray.array([connectionName], String)
    printFormattedMessage(AdfMessages.CREATED_CONN, objs)

def printDeleteSuccess(connectionName):
    objs = jarray.array([connectionName], String)
    printFormattedMessage(AdfMessages.CONN_DELETED, objs)

def printSaveSuccess(appName):
    objs = jarray.array([appName], String)
    printFormattedMessage(AdfMessages.SAVED_CONNS, objs)

def printErrorInvokingGetConnectionNames():
    print 'Error invoking getConnectionNames'

def printErrorInvokingAddConnectionName():
    print 'Error invoking addConnectionName'

def printNoSuchApplication(appName):
    objs = jarray.array([appName], String)
    printFormattedMessage(AdfMessages.NO_APPLICATION_FOUND, objs)

def printNoSuchConnection(name):
    objs = jarray.array([connectionName], String)
    printFormattedMessage(AdfMessages.NO_CONN_FOUND, objs)

def printSetConnection(name):
    print 'Connection ' + name + ' is set'    

def printNoConnections(connectionType):
    print 'No connections of type ' + connectionType + ' Connections'

def printSetError(attr=''):
    if attr == '':
        print 'Error occurred while performing set'
    else:
        print 'Error occurred while performing set for attribute ' + attr

def printGetError(attr):
    print 'Error occurred while performing get for attribute ' + attr

def printInvalidURL():
    print 'URL specified is invalid'

# Returns true if successful, false otherwise.
def initialize():
    connected = ora_mbs is not None;
    if not connected:
        printNotConnected()
    return connected

# Returns an array of MBean Object Names that have the string 'oracle.adf.share.connections' 
def getMBeanArrayInADFConnections():
    objname = ora_mbs.makeObjectName('*oracle.adf.share.connections:*')
    try:
        mbset = ora_mbs.queryNames(objname,None)
        mbarray= mbset.toArray()
        return mbarray
    except:
        printErrorMBSQueryNames('*oracle.adf.share.connections:*')
    return None

def printErrorMBSQueryNames(str):
    print 'Error occurred while performing ora_mbs.queryNames(objname) for ' + str

def matchObjectNameElement(objNameStr, element):
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
def getADFConnectionObjName(mbeanarray, appName):
    nameADFConn = 'name=ADFConnections'
    typeADFConn = 'type=ADFConnections'
    appNameStr = 'Application=' + appName
    if debugIsEnabled():
        searchADFandAppStr = nameADFConn + "," + typeADFConn + "," + appNameStr
        print 'searchADFandAppStr = ' + searchADFandAppStr
    for i in range(len(mbeanarray)):
        objnamestr = mbeanarray[i].toString()
        if debugIsEnabled():
            print 'objnamestr = ' + objnamestr
        if matchObjectNameElement(objnamestr, nameADFConn):
            if matchObjectNameElement(objnamestr, typeADFConn):
                if matchObjectNameElement(objnamestr, appNameStr):
                    return mbeanarray[i]
    return None

# Helper function for createXXXConnection 
def customCreateConnection(appName, connectionName, connectionType, userArg):
    printDebugMethodInfo('customCreateConnection', connectionName) 
    mbeanarray = getMBeanArrayInADFConnections()
    ADFConnObjName = getADFConnectionObjName(mbeanarray, appName)
    if ADFConnObjName is None:
        printNoADFConnectionMBean(appName)
        return None
    # Initialize the variable
    objNameStr = None
    # If a Connection MBean with that name already exists, abort the creation.
    if connMBeanExists(ADFConnObjName, connectionName, connectionType):
        printConnectionAlreadyExists(connectionName)
    else:
        objs = jarray.array([String(connectionType), String(connectionName)], Object)
        strs = jarray.array(['java.lang.String', 'java.lang.String'], String)
        try:
            connObjName = ora_mbs.invoke(ADFConnObjName, 'createConnection', objs, strs)
            objNameStr = connObjName.toString()
            printCreateSuccess(connectionName)
        except Exception, e:
            printErrorCreatingConn(connectionName)
            if debugIsEnabled():
                saveStackAndRaiseException(e, '')
            return None
    fromCreate = 1
    customSetConnection(appName, connectionName, connectionType, userArg, fromCreate)
    return objNameStr

# Helper function for setXXXConnection
def customSetConnection(appName, connectionName, connectionType, userArg, fromCreate):
    printDebugMethodInfo('customSetConnection', connectionName) 
    mbeanarray = getMBeanArrayInADFConnections()
    ADFConnObjName = getADFConnectionObjName(mbeanarray, appName)
    if ADFConnObjName is None:
        printNoADFConnectionMBean(appName)
        return
    # If a Connection MBean with that name exists, set the connection
    connObjName = getConnObjName(ADFConnObjName, connectionName, connectionType)
    if connObjName is None:
        printNoSuchConnection(connectionName)
        return
    for arg in userArg.items():
        argName = arg[0]
        argValue = arg[1]
        if debugIsEnabled():
            print 'argName = ' + argName
            print 'argValue = ' + argValue
        try:
            ora_mbs.setAttribute(connObjName, Attribute(argName, argValue))
        except Exception, e:
            printSetError(argName)
            if debugIsEnabled():
                saveStackAndRaiseException(e, '')
    if not fromCreate:
        printSetConnection(connectionName)
    
# Build a dictionary from fields
def buildFieldCred(fields):
    fieldDic = {}
    for f in fields:
        sepfieldList = f.split(':', 1)
        fieldName = sepfieldList[0]
        fieldValue = sepfieldList[1]
        if debugIsEnabled():
            print 'fieldName = ' + fieldName
            print 'fieldValue = ' + fieldValue
        fieldDic[fieldName] = fieldValue
    return fieldDic
    
# Save connections
def saveConnections(appName):
    printDebugMethodInfo('saveConnections', appName)
    mbeanarray = getMBeanArrayInADFConnections()
    ADFConnObjName = getADFConnectionObjName(mbeanarray, appName)
    if ADFConnObjName is None:
        printNoADFConnectionMBean(appName)
        return None
    objs = jarray.array([], Object)
    strs = jarray.array([], String)
    try:
        connObjName = ora_mbs.invoke(ADFConnObjName, 'save', objs, strs)
        printSaveSuccess(appName)
    except Exception, e:
        printErrorSavingConns(appName)
        if debugIsEnabled():
            saveStackAndRaiseException(e, '')
        return None

# Returns an ObjectName if a ADF Connection with the connectionType 
def listConnections(appName, connectionType):
    if appName is None:
        return
    objname = ora_mbs.makeObjectName('*oracle.adf.share.connections:type=ADFConnections,name=ADFConnections,Application=' + appName +',*')
    mbset = ora_mbs.queryNames(objname, None)
    if debugIsEnabled():
        print 'objname = ' + objname.toString()
        print 'mbset = ' + mbset.toString()
    mbarray= mbset.toArray()
    if mbarray is None:
        return
    for i in range(len(mbarray)):
        connList = getExistingConnObjNames(mbarray[i], connectionType)
        if connList is not None:
            for j in range(len(connList)):
                conn = connList[j]
                print conn.toString()
                if debugIsEnabled():
                    printURLAttributes(conn)
# Helper function for deleteXXXConnection
def customDeleteConnection(appName, connectionName, connectionType):
    printDebugMethodInfo('customDeleteConnection', connectionName)
    mbeanarray = getMBeanArrayInADFConnections()
    ADFConnObjName = getADFConnectionObjName(mbeanarray, appName)
    if ADFConnObjName is None:
        printNoADFConnectionMBean(appName)
        return None
    # If a Connection MBean with that name exists, delete the connection
    connObjName = getConnObjName(ADFConnObjName, connectionName, connectionType)
    if connObjName is None:
        printNoSuchConnection(connectionName)
    else:
        objs = jarray.array([String(connectionName)], Object)
        strs = jarray.array(['java.lang.String'], String)
        try:
            ora_mbs.invoke(ADFConnObjName, 'removeConnection', objs, strs)
            printDeleteSuccess(connectionName)
        except Exception, e:
            printErrorDeletingConn(connectionName)
            if debugIsEnabled():
                saveStackAndRaiseException(e, '')
    return None


# Function to check if param is not null or not empty
def checkNotEmpty(param):
    return param is not None or len(param.strip()) > 0
    
# Print Not Connected
def printNotConnected():
    print AdfMessages.get(AdfMessages.NOT_CONNECTED_TO_SERVER)

# File URL args buildup
def buildFileURLConnUserArgs(url):
    args = {}
    if checkNotEmpty(url): 
        args['URL'] = url
    return args

# Http URL args buildup
def buildHttpURLArgs(url, authenticationType, realm, user, password):
    args = {}
    if checkNotEmpty(url): 
        args['URL'] = url
    args['ChallengeAuthenticationType'] = authenticationType
    args['AuthenticationRealm'] = realm
    args['Username'] = user
    args['Password'] = password
    return args

# Display a single URL connection attribute
def printAttribute(conn, name):
    if conn is None or name is None:
        return
    try:
        value = ora_mbs.getAttribute(conn, name)
        if value is not None:
            print name + ' = ' + value
    except:
        printGetError(name)

# Display URL connection attributes
def printURLAttributes(conn):
    printAttribute(conn, 'ConnectionName')
    printAttribute(conn, 'ConnectionType')
    printAttribute(conn, 'ConnectionClassName')
    printAttribute(conn, 'URL')
    printAttribute(conn, 'ChallengeAuthenticationType')
    printAttribute(conn, 'AuthenticationRealm')

#set connection reference element attributes
def setADFConnectionGenericAttr(appName, connType, connName, propName, propVal):
    printDebugMethodInfo('setADFConnectionGenericAttr', appName)
    mbeanarray = getMBeanArrayInADFConnections()
    ADFConnObjName = getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        printNoADFConnectionMBean(appName)
        return
   
    # check if connection MBean with that name exists.
    if connMBeanExists(ADFConnObjName,connName,connType):
        objs = jarray.array([String(connName), String(propName),String(propVal)],Object)
        strs = jarray.array(['java.lang.String','java.lang.String','java.lang.String'],String)
        try:
            ora_mbs.invoke(ADFConnObjName, 'updateADFConnectionGenericAttribute', objs, strs)
            saveConnections(appName)
            printADFConnectionUpdated(connName)
        except WLSTException:
            printADFConnectionUpdateErr(connName)

    else:
        printNoSuchConnection(connName)
        return
        
# Display ADF child connection generic attributes
def printADFConnectionGenericAttr(appName, connType, connName, propName):
    printDebugMethodInfo('printADFConnectionGenericAttr', appName)
    mbeanarray = getMBeanArrayInADFConnections()
    ADFConnObjName = getADFConnectionObjName(mbeanarray,appName)
    if ADFConnObjName is None:
        printNoADFConnectionMBean(appName)
        return
    
    # check if connection MBean with that name exists.
    if connMBeanExists(ADFConnObjName,connName,connType):
        objs = jarray.array([String(connName),String(propName)],Object)
        strs = jarray.array(['java.lang.String','java.lang.String'],String)
        try:
            value = ora_mbs.invoke(ADFConnObjName, 'getADFConnectionGenericAttribute', objs, strs)
            if value is not None:
               print propName + ' = ' + value
        except:
            printGetError(propName)
    else:
        printNoSuchConnection(connName)
        return        
