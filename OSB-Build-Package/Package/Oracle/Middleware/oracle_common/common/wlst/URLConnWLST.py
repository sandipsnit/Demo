"""
 Copyright (c) 1998, 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move this file because this may cause
WLST commands and scripts to fail. Do not try to reuse the logic in this file or keep copies of this file
because this could cause your WLST scripts to fail when you upgrade to a different version of WLST.

Simple routines to create/list URL Connections
@author Namita Varma

"""
import oracle.adf.share.wlst.resources.Messages as AdfMessages

try:
    addHelpCommandGroup("ADFURLConnectionadmin", "oracle.adf.share.wlst.resources.WlstHelp")
    addHelpCommand("adf_createFileURLConnection", "ADFURLConnectionadmin", offline="false")
    addHelpCommand("adf_createHttpURLConnection", "ADFURLConnectionadmin", offline="false")
    addHelpCommand("adf_setURLConnectionAttributes", "ADFURLConnectionadmin", offline="false")
    addHelpCommand("adf_listURLConnection", "ADFURLConnectionadmin", offline="false")
except:
    #ignore the exception
    pass

# Code for detecting syntax error, especially missing colons
def adf_urlCheck():
    print 'File not broken'

#Function to check if param is not null or not empty
def adf_checkNotEmpty(param):
    if param is None:
        return false
    if len(param.strip())==0:
        return false
    return true
    
# Returns the user's directory if initialization is successful. Returns the null object if initialization fails.
def adf_Initialize():
    if mbs is None:
        adf_printNotConnected()
        return None
    #redirect('outputFile','false')
    origDirectory = pwd()
    domainRuntime()
    return origDirectory


#Print Not Connected
def adf_printNotConnected():
    print AdfMessages.get(AdfMessages.NOT_CONNECTED_TO_SERVER)
    

# URL args buildup
def adf_buildfileURLConnUserArgs(url):
    args={}
    if adf_checkNotEmpty(url): 
        args['URL']=url
    return args

# Http URL args buildup
def adf_buildHttpURLArgs(url,authenticationType,realm,user,password ):
    args={}
    if adf_checkNotEmpty(url): 
        args['URL']=url
    args['ChallengeAuthenticationType']=authenticationType
    args['AuthenticationRealm']=realm
    args['Username']=user
    args['Password']=password
    return args


#Create Http URL Connection Command
def adf_createHttpURLConnection(appName,name, url='',authenticationType='basic',realm='',user='',password=''):
    origDirectory = adf_Initialize()    
    if origDirectory is not None:
        connectionType='URLConnProvider'
    else:
        return
    userArg=adf_buildHttpURLArgs(url,authenticationType,realm,user,password)

    if adf_debugIsEnabled():
            print userArg
    adf_customCreateConnection(appName,name,connectionType,userArg)
    adf_saveConnections(appName)
    adf_Restore(origDirectory)


#Create File URL Connection Command
def adf_createFileURLConnection(appName,name, url=''):
    adf_printDebugMethodInfo('adf_createFileURLConnection', name)
    origDirectory = adf_Initialize()
    if origDirectory is not None:
        connectionType='URLConnProvider'
    else:
        return
    userArg=adf_buildfileURLConnUserArgs(url)
    if adf_debugIsEnabled():
        print userArg
    urluserArg={'ConnectionClassName':'oracle.adf.model.connection.url.FileURLConnection'}
    if adf_debugIsEnabled():
        print userArg
    adf_customCreateConnection(appName,name,connectionType,userArg)
    adf_setURLConnectionAttributes(appName, name, 'ConnectionClassName:oracle.adf.model.connection.url.FileURLConnection')
    adf_Restore(origDirectory)


#Create Http URL Connection Command
def adf_listURLConnection(appName):
    origDirectory = adf_Initialize()
    if origDirectory is not None:
        connectionType='URLConnProvider'
    else:
        return
    adf_listConnections(appName, connectionType)
    adf_Restore(origDirectory)

#Delete URL Connection Command
def adf_deleteURLConnection(appName,name):
    origDirectory = adf_Initialize()    
    if origDirectory is not None:
        connectionType='URLConnProvider'
    else:
        return
    adf_customDeleteConnection(appName,name,connectionType)
    adf_saveConnections(appName)
    adf_Restore(origDirectory)
  
# Set some URL Connection attributes
#adf_setURLConnectionAttributes('myapp','urlConn1','URL:http://www.oracle.com','ChallengeAuthenticationType:digest','AuthenticationRealm:XMLRealm') 
def adf_setURLConnectionAttributes(appName, connectionName, *attributes):
    adf_printDebugMethodInfo('adf_setURLConnectionAttributes', connectionName) 
    origDirectory = adf_Initialize()
    if adf_debugIsEnabled():
        print origDirectory
    if origDirectory is not None:
        connectionType='URLConnProvider'
    else:
        return
    urluserArg=adf_buildFieldCred(attributes)
    adf_customSetConnection(appName,connectionName,connectionType,urluserArg,true)
    adf_saveConnections(appName)
    adf_Restore(origDirectory)
  
