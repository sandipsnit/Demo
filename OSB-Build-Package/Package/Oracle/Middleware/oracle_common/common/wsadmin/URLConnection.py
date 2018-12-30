"""
 Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WSADMIN implementation.  Do not edit or move
this file because this may cause WSADMIN commands and scripts to fail.  Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WSADMIN scripts to fail when you upgrade to a different
version of WSADMIN.

Simple routines to create/list URL Connections
"""

import oracle.adf.share.wlst.resources.Messages as AdfMessages

import ADFShareHelperWSAdmin
import OracleHelp

_helper = ADFShareHelperWSAdmin

# Help support
def help(topic = None):
    m_name = 'URLConnection'
    if topic == None:
        topic = m_name
    else:
        topic = m_name + '.' + topic
    return OracleHelp.help(topic)

# Code for detecting syntax error, especially missing colons
def check():
    print 'File OK'

# Create Http URL Connection Command
def createHttpURLConnection(appName, name, url='', authenticationType='basic', realm='', user='', password=''):
    if not _helper.initialize():
        return
    connectionType = 'URLConnProvider'
    userArg = _helper.buildHttpURLArgs(url, authenticationType, realm, user, password)
    if _helper.debugIsEnabled():
        print userArg
    _helper.customCreateConnection(appName, name, connectionType, userArg)
    _helper.saveConnections(appName)

# Create File URL Connection Command
def createFileURLConnection(appName, name, url=''):
    _helper.printDebugMethodInfo('createFileURLConnection', name)
    if not _helper.initialize():
        return
    connectionType='URLConnProvider'
    userArg = _helper.buildFileURLConnUserArgs(url)
    if _helper.debugIsEnabled():
        print userArg
    _helper.customCreateConnection(appName, name, connectionType, userArg)
    attributes = 'ConnectionClassName:oracle.adf.model.connection.url.FileURLConnection'
    setURLConnectionAttributes(appName, name, attributes)


# List URL Connection Command
def listURLConnection(appName):
    if not _helper.initialize():
        return
    connectionType = 'URLConnProvider'
    _helper.listConnections(appName, connectionType)

# Delete URL Connection Command
def deleteURLConnection(appName, connectionName):
    if not _helper.initialize():
        return
    connectionType = 'URLConnProvider'
    _helper.customDeleteConnection(appName, connectionName, connectionType)
    _helper.saveConnections(appName)
  
# Set some URL Connection attributes
# setURLConnectionAttributes('myapp', 'urlConn1', 'URL:http://www.oracle.com', 'ChallengeAuthenticationType:digest', 'AuthenticationRealm:XMLRealm') 
def setURLConnectionAttributes(appName, connectionName, *attributes):
    _helper.printDebugMethodInfo('setURLConnectionAttributes', connectionName) 
    if not _helper.initialize():
        return
    connectionType = 'URLConnProvider'
    userArg = _helper.buildFieldCred(attributes)
    if _helper.debugIsEnabled():
        print userArg
    fromCreate = 1
    _helper.customSetConnection(appName, connectionName, connectionType, userArg, fromCreate)
    _helper.saveConnections(appName)

# Aliases for naming consistency with slightly more verbose wlst method names
adf_createHttpURLConnection = createHttpURLConnection
adf_createFileURLConnection = createFileURLConnection
adf_listURLConnection = listURLConnection
adf_setURLConnectionAttributes = setURLConnectionAttributes
