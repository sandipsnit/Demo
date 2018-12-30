"""
 Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WSADMIN implementation.  Do not edit or move
this file because this may cause WSADMIN commands and scripts to fail.  Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WSADMIN scripts to fail when you upgrade to a different
version of WSADMIN.

Simple routines to create/list/delete WebServiceConnections
"""


import ADFShareHelperWSAdmin
import OracleHelp
import javax.management
import ora_mbs
import ora_util
import jarray

from jarray import array
from java.lang import Object
from java.lang import Exception
from java.lang import System
from java.lang import String
from java.lang import Boolean


_helper = ADFShareHelperWSAdmin


# help
def help(topic = None):
  m_name = 'ADFWSConnection'
  if topic == None:
     topic = m_name
  else:
     topic = m_name + '.' + topic
  return OracleHelp.help(topic)



#Create WebServiceConnection Command
# wsdlUrlStr : the WSDL URL string
# readerProp : optional wsdl reader properties 
#    ["wsdl.reader.proxy.host=proxy.my.com", "wsdl.reader.proxy.port=80"] 
#
# if wsconn is created and saved successfully, it will return a Map of 
# key is service name, value is List of port names
# for example: 
#  {'PolicyReferenceEchoService': array(java.lang.String,['PolicyReferenceEchoPort1']) }
def createWebServiceConnection(appName, wsConnName, wsdlUrlStr, readerProp=['']):
    if not _helper.initialize():
        return None
    connectionType='WebServiceConnection'
    ret = {}
    try:
      args = {}
      args['WsdlUrl'] = wsdlUrlStr
      wsconnONStr = _helper.customCreateConnection(appName, wsConnName, connectionType, args)
      if  wsconnONStr is None:
          print 'Could not create a new connection!'
          return None
      wsconnObjName = ora_mbs.makeObjectName(wsconnONStr)
      props = jarray.array(readerProp, String)
      objs = jarray.array([String(wsdlUrlStr), props], Object)
      strs = jarray.array(['java.lang.String', '[Ljava.lang.String;'], String)
      ora_mbs.invoke(wsconnObjName, 'provisionWSConnection', objs,  strs)
      _helper.saveConnections(appName)
      print '\t', wsconnObjName
      svcs = ora_mbs.getAttribute(wsconnObjName, 'ServiceMBeans')
      for i in range(len(svcs)):
          svc = svcs[i]
          print '\t\t', svc
          ports = ora_mbs.getAttribute(svc, 'PortMBeans')
          ptlist = jarray.zeros(len(ports), String)
          for j in range(len(ports)):
              port = ports[j]
              ptlist[j] = port.getKeyProperty('name')
              print '\t\t\t', port
          ret[ svc.getKeyProperty('name') ] = ptlist
    except Exception, ex:
       ora_util.raiseScriptingException(e)
    return ret



#List WebServiceConnection Command
def listWebServiceConnection(appName):
    if not _helper.initialize():
        return
    connectionType='WebServiceConnection'
    _helper.listConnections(appName, connectionType)



#Delete WebServiceConnection Command
def deleteWebServiceConnection(appName, wsConnName):
    if not _helper.initialize():
        return
    connectionType='WebServiceConnection'
    try:
       _helper.customDeleteConnection(appName, connectionName, connectionType)
       _helper.saveConnections(appName)
    except Exception, e:
       ora_util.raiseScriptingException(e)



