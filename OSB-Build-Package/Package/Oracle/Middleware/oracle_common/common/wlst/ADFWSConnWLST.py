"""
 Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the WLST implementation. Do not edit or move this file because this may cause
WLST commands and scripts to fail. Do not try to reuse the logic in this file or keep copies of this file
because this could cause your WLST scripts to fail when you upgrade to a different version of WLST.

Simple routines to create/list/delete WebServiceConnection


"""


try:
    addHelpCommandGroup("ADFWSConnection", "oracle.adf.share.wlst.resources.WlstHelp")
    addHelpCommand("createWebServiceConnection", "ADFWSConnection", offline="false")
    addHelpCommand("listWebServiceConnection", "ADFWSConnection", offline="false")
    addHelpCommand("deleteWebServiceConnection", "ADFWSConnection", offline="false")
except:
    #ignore the exception
    pass



#Create WebServiceConnection Command
# wsdlUrlStr : the WSDL URL string
# readerProp : optional wsdl reader properties 
#    ["wsdl.reader.proxy.host=proxy.my.com", "wsdl.reader.proxy.port=80"] 
#
# if wsconn is created and saved successfully, it will return a Map of 
# key is service name, value is List of port names
# for example: 
# {'PolicyReferenceEchoService': array(java.lang.String,['PolicyReferenceEchoPort1']) }
def createWebServiceConnection(appName, wsConnName, wsdlUrlStr, readerProp=['']):
    origDirectory = adf_Initialize()    
    if origDirectory is None:
        return None
    connectionType='WebServiceConnection'
    ret = {}
    try:
      args = {}
      args['WsdlUrl'] = wsdlUrlStr
      wsconnONStr = adf_customCreateConnection(appName, wsConnName, connectionType, args)
      if  wsconnONStr is None: 
          print 'Could not create a new connection!'
          adf_Restore(origDirectory)
          return None
      wsconnObjName = ObjectName(wsconnONStr)
      props = jarray.array(readerProp, java.lang.String)
      objs = jarray.array([java.lang.String(wsdlUrlStr), props], java.lang.Object)
      strs = jarray.array(['java.lang.String', '[Ljava.lang.String;'], java.lang.String) 
      mbs.invoke(wsconnObjName, 'provisionWSConnection', objs,  strs) 
      adf_saveConnections(appName)
      #model = mbs.getAttribute(wsconnObjName, 'Model')
      #print model
      print '\t', wsconnObjName 
      svcs = mbs.getAttribute(wsconnObjName, 'ServiceMBeans')
      for i in range(len(svcs)):
          svc = svcs[i]
          print '\t\t', svc 
          ports = mbs.getAttribute(svc, 'PortMBeans')
          ptlist = jarray.zeros(len(ports), java.lang.String)
          for j in range(len(ports)):
              port = ports[j]
              ptlist[j] = port.getKeyProperty('name')
              print '\t\t\t', port 
          ret[ svc.getKeyProperty('name') ] = ptlist 
    except Exception, ex:
       print ex.getMessage()
       ex.printStackTrace() 
    adf_Restore(origDirectory)
    return ret 


#List WebServiceConnection Command
def listWebServiceConnection(appName):
    origDirectory = adf_Initialize()
    if origDirectory is None:
        return
    connectionType='WebServiceConnection'
    adf_listConnections(appName, connectionType)
    adf_Restore(origDirectory)
  

#Delete WebServiceConnection Command
def deleteWebServiceConnection(appName, wsConnName):
    origDirectory = adf_Initialize()    
    if origDirectory is None:
        return
    connectionType='WebServiceConnection'
    try:
       adf_customDeleteConnection(appName, wsConnName, connectionType)
       adf_saveConnections(appName)
    except Exception, ex:
       print ex.getMessage()
       ex.printStackTrace() 
    adf_Restore(origDirectory)


