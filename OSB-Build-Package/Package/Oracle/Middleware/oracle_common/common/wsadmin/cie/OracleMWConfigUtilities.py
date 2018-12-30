# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

from com.oracle.cie.was.wsadmin import WSAdminExtension
import cie.OracleMWConfig as OracleMWConfig
import cie.OracleHelp as OracleHelp
import java

####################################
#    setEndPointHostUsingObject    #
####################################
def setEndPointHostUsingObject(serverObject, endPointName, hostValue):
  if serverObject != None:
    listenerAddress = serverObject.getChildren('ListenerAddress')
    if listenerAddress != None and len(listenerAddress) > 0:
      endPoints = listenerAddress[0].getChildren(endPointName)
      if endPoints != None and len(endPoints) > 0:
        endPoints[0].setValue('Host', hostValue)
        print "Host Name " + hostValue + " for " + endPointName + " is set."
#enddef--setEndPointHostUsingObject

####################################
#    setEndPointHostUsingName      #
####################################
def setEndPointHostUsingName(serverName,nodeName,endPointName,hostValue):
  serverObject = OracleMWConfig.getChildByName('Server',serverName,nodeName)
  setEndPointHostUsingObject(serverObject,endPointName,hostValue)
#enddef--setEndPointHostUsingName

####################################
#    setEndPointPortUsingObject    #
####################################
def setEndPointPortUsingObject(serverObject, endPointName, portValue):
  if serverObject != None:
    listenerAddress = serverObject.getChildren('ListenerAddress')
    if listenerAddress != None and len(listenerAddress) > 0:
      endPoints = listenerAddress[0].getChildren(endPointName)
      if endPoints != None and len(endPoints) > 0:
        endPoints[0].setValue('Port', portValue)
        print "Port " + portValue + " for a " + endPointName + " is set."
#enddef--setEndPointPortUsingObject

####################################
#    setEndPointPortUsingName      #
####################################
def setEndPointPortUsingName(serverName,nodeName,endPointName,portValue):
  serverObject = OracleMWConfig.getChildByName('Server',serverName,nodeName)
  setEndPointPortUsingObject(serverObject,endPointName,portValue)
#enddef--setEndPointPortUsingName

####################################
#    getEndPointHostUsingObject    #
####################################
def getEndPointHostUsingObject(serverObject, endPointName):
  if serverObject != None:
    listenerAddress = serverObject.getChildren('ListenerAddress')
    if listenerAddress != None and len(listenerAddress) > 0:
      endPoints = listenerAddress[0].getChildren(endPointName)
      if endPoints != None and len(endPoints) > 0:
        return endPoints[0].getValue('Host')
  return None
#enddef--getEndPointHostUsingObject

####################################
#    getEndPointHostUsingName      #
####################################
def getEndPointHostUsingName(serverName, nodeName, endPointName):
  serverObject = OracleMWConfig.getChildByName('Server', serverName, nodeName)
  return getEndPointHostUsingObject(serverObject, endPointName)
#enddef--getEndPointHostUsingName

####################################
#    getEndPointPortUsingObject    #
####################################
def getEndPointPortUsingObject(serverObject, endPointName):
  if serverObject != None:
    listenerAddress = serverObject.getChildren('ListenerAddress')
    if listenerAddress != None and len(listenerAddress) > 0:
      endPoints = listenerAddress[0].getChildren(endPointName)
      if endPoints != None and len(endPoints) > 0:
        return endPoints[0].getValue('Port')
  return None
#enddef--getEndPointPortUsingObject

####################################
#    getEndPointPortUsingName      #
####################################
def getEndPointPortUsingName(serverName, nodeName, endPointName):
  serverObject = OracleMWConfig.getChildByName('Server', serverName, nodeName)
  return getEndPointPortUsingObject(serverObject, endPointName)
#enddef--getEndPointPortUsingName

####################################
#    showEndPointsUsingObject      #
####################################
def showEndPointsUsingObject(serverObject):
  if serverObject != None:
    listenerAddress = serverObject.getChildren('ListenerAddress')
    if listenerAddress != None and len(listenerAddress) > 0:
      return listenerAddress[0].show()
  return None
#enddef--showEndPointsUsingObject

####################################
#    showEndPointsUsingName        #
####################################
def showEndPointsUsingName(serverName, nodeName):
  serverObject = OracleMWConfig.getChildByName('Server', serverName, nodeName)
  return showEndPointsUsingObject(serverObject)
#enddef--showEndPointsUsingName

####################################
#          showServer              #
####################################
def showServer(serverName, nodeName):
  server = OracleMWConfig.getChildByName('Server', serverName, nodeName)
  if server != None:
    return server.show()
#enddef--showServer

####################################
#     setFileStoreDirectory        #
####################################
def setFileStoreDirectory(type, clusterName, busName, directory):
  clusters = OracleMWConfig.getChildren('ServerCluster')
  found = 0
  for cluster in clusters:
    clsName = cluster.getValue("Name")
    if clsName == clusterName:
      found = 1

  if found == 0:
    print "Unsupported operation for " + clusterName + ", sharable directory can be set only on cluster."
    return

  buses = OracleMWConfig.getChildren('SIBus')
  for bus in buses:
    busNm = bus.getValue('Name')
    members = bus.getChildren('BusMember')
    for member in members:
      targets =  member.getChildren('Target')
      engines = member.getChildren('BusMessagingEngine')
      cls = targets[0].getValue("Cluster")
      if cls == clusterName and busName==busNm:
        for eng in engines:
          fileStore = eng.getChildren("FileStore")
          if len(fileStore) > 0:
            fileStore[0].setValue(type,directory)
#enddef--setFileStoreDirectory

####################################
#        setLogDirectory           #
####################################
def setLogDirectory(clusterName, busName, directory):
  setFileStoreDirectory("LogDirectory", clusterName, busName, directory)
#enddef--setLogDirectory

####################################
#   setPermanentStoreDirectory     #
####################################
def setPermanentStoreDirectory(clusterName, busName, directory):
  setFileStoreDirectory("PermanentStoreDirectory", clusterName, busName, directory)
#enddef--setPermanentStoreDirectory

####################################
#   setTemporaryStoreDirectory     #
####################################
def setTemporaryStoreDirectory(clusterName,busName, directory):
  setFileStoreDirectory("TemporaryStoreDirectory", clusterName, busName, directory)
#enddef--setTemporaryStoreDirectory

####################################
#      getFileStoreDirectory       #
####################################
def getFileStoreDirectory(type, clusterName, busName):
  clusters = OracleMWConfig.getChildren('ServerCluster')
  found = 0
  for cluster in clusters:
    clsName = cluster.getValue("Name")
    if clsName == clusterName:
      found = 1

  if found == 0:
    print "Unsupported operation for " + clusterName + ", sharable directory is present only on cluster."
    return
    
  buses = OracleMWConfig.getChildren('SIBus')
  for bus in buses:
    busNm = bus.getValue('Name')
    members = bus.getChildren('BusMember')
    for member in members:
      targets =  member.getChildren('Target')
      engines = member.getChildren('BusMessagingEngine')
      cls = targets[0].getValue("Cluster")
      if cls == clusterName and busName==busNm:
        for eng in engines:
          fileStore = eng.getChildren("FileStore")
          if len(fileStore) > 0:
            return fileStore[0].getValue(type)
 #enddef--getFileStoreDirectory

####################################
#        getLogDirectory           #
####################################
def getLogDirectory(clusterName, busName):
  return getFileStoreDirectory("LogDirectory", clusterName, busName)
#enddef--getLogDirectory

####################################
#    getPermanentStoreDirectory    #
####################################
def getPermanentStoreDirectory(clusterName, busName):
  return getFileStoreDirectory("PermanentStoreDirectory", clusterName, busName)
#enddef--getPermanentStoreDirectory

####################################
#    getTemporaryStoreDirectory    #
####################################
def getTemporaryStoreDirectory(clusterName, busName):
  return getFileStoreDirectory("TemporaryStoreDirectory", clusterName, busName)
#enddef--getTemporaryStoreDirectory

####################################
#      getJdbcDatasourceNames      #
####################################
def getJdbcDatasourceNames():
  jdbcWrapperList = OracleMWConfig.getChildren('JDBC')
  datasourceNames = []
  for ds in jdbcWrapperList:
    name = ds.getValue('Name')
    type = ds.getValue('Type')
    if type == "Normal":
      datasourceNames.append(name)
  return datasourceNames
#enddef--getJdbcDatasourceNames

####################################
#   getJdbcSchemaComponentNames    #
####################################
def getJdbcSchemaComponentNames():
  jdbcWrapperList = OracleMWConfig.getChildren('JDBC')
  schemaNames = []
  for ds in jdbcWrapperList:
    name = ds.getValue('Name')
    type = ds.getValue('Type')
    if type == "Schema":
      schemaNames.append(name)
  return schemaNames
#enddef--getJdbcSchemaComponentNames

####################################
#            showJdbc              #
####################################
def showJdbc(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.show()
#enddef--showJdbc

####################################
#          validateJdbc            #
####################################
def validateJdbc(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.validate()
#enddef--validateJdbc

####################################
#         setJdbcUsername          #
####################################
def setJdbcUsername(jdbcInstanceName, username):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None and jdbcWrapper.getValue('Type') == 'Normal':
     jdbcWrapper.setValue('Username', username)
  if jdbcWrapper != None and jdbcWrapper.getValue('Type') == 'Schema':
     jdbcWrapper.setValue('SchemaOwner', username)
#enddef--setJdbcUsername

####################################
#         getJdbcUsername          #
####################################
def getJdbcUsername(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None and jdbcWrapper.getValue('Type') == 'Normal':
     return jdbcWrapper.getValue('Username')
  if jdbcWrapper != None and jdbcWrapper.getValue('Type') == 'Schema':
     return jdbcWrapper.getValue('SchemaOwner')
#enddef--getJdbcUsername

####################################
#         setJdbcPassword          #
####################################
def setJdbcPassword(jdbcInstanceName, password):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None and jdbcWrapper.getValue('Type') == 'Normal':
     jdbcWrapper.setValue('Password', password)
  if jdbcWrapper != None and jdbcWrapper.getValue('Type') == 'Schema':
     jdbcWrapper.setValue('SchemaPassword', password)
#enddef--setJdbcPassword

####################################
#       setJdbcServerName          #
####################################
def setJdbcServerName(jdbcInstanceName, serverName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.setValue('ServerName', serverName)
#enddef--setJdbcServerName

####################################
#       getJdbcServerName          #
####################################
def getJdbcServerName(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('ServerName')
#enddef--getJdbcServerName

####################################
#       setJdbcPortNumber          #
####################################
def setJdbcPortNumber(jdbcInstanceName, portNumber):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.setValue('PortNumber', portNumber)
#enddef--setJdbcPortNumber

####################################
#       getJdbcPortNumber          #
####################################
def getJdbcPortNumber(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('PortNumber')
#enddef--getJdbcPortNumber

####################################
#      setJdbcDatabaseName         #
####################################
def setJdbcDatabaseName(jdbcInstanceName, databaseName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.setValue('DatabaseName', databaseName)
#enddef--setJdbcDatabaseName

####################################
#      getJdbcDatabaseName         #
####################################
def getJdbcDatabaseName(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('DatabaseName')
#enddef--getJdbcDatabaseName

####################################
#      setJdbcDriverVendor         #
####################################
def setJdbcDriverVendor(jdbcInstanceName, databaseType):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.setValue('DatabaseType', databaseType)
#enddef--setJdbcDriverVendor

####################################
#      getJdbcDriverVendor         #
####################################
def getJdbcDriverVendor(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('DatabaseType')
#enddef--getJdbcDriverVendor

####################################
#        setJdbcDriverXa           #
####################################
def setJdbcDriverXa(jdbcInstanceName, isXa):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.setValue('IsXa', isXa)
#enddef--setJdbcDriverXa

####################################
#        getJdbcDriverXa           #
####################################
def getJdbcDriverXa(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('IsXa')
#enddef--getJdbcDriverXa

####################################
#   setJdbcIsOracleInstanceType    #
####################################
def setJdbcIsOracleInstanceType(jdbcInstanceName, isOracleInctanceType):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  vendor = jdbcWrapper.getValue("DatabaseType")
  if 'Oracle' != vendor:
    return
  if jdbcWrapper != None:
     jdbcWrapper.setValue('IsOracleInstanceType', isOracleInctanceType)
#enddef--setJdbcIsOracleInstanceType

####################################
#   getJdbcIsOracleInstanceType    #
####################################
def getJdbcIsOracleInstanceType(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('IsOracleInstanceType')
#enddef--getJdbcIsOracleInstanceType

####################################
#      setJdbcRacServiceName       #
####################################
def setJdbcRacServiceName(jdbcInstanceName, racServiceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    jdbcWrapper.setValue('RacService', racServiceName)
#enddef--setJdbcRacServiceName

####################################
#      getJdbcRacServiceName       #
####################################
def getJdbcRacServiceName(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('RacService')
#enddef--getJdbcRacServiceName

####################################
#       setJdbcRacHostsPorts       #
####################################
def setJdbcRacHostsPorts(jdbcInstanceName, racHostPortList):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)  
  isRac = jdbcWrapper.getValue("IsRac")  
  if 'true' != isRac:
    return
  if jdbcWrapper == None:
    return
  
  hosts = ''
  ports = ''
  for hp in racHostPortList:
    host_port = hp.split(':')
    if hosts == '':
      hosts = host_port[0]
    else:
      hosts = hosts + ':' + host_port[0]
        
    if ports == '':
      ports = host_port[1]
    else:
      ports = ports + ':' + host_port[1]

  jdbcWrapper.setValue('ServerName', hosts)
  jdbcWrapper.setValue('PortNumber', ports)
#enddef--setJdbcRacHostsPorts

####################################
#        createDatasource          #
####################################
def createDatasource(attributeList):
  return OracleMWConfig.create('JDBC', attributeList)
#enddef--createDatasource

####################################
#        deleteDatasource          #
####################################
def deleteDatasource(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  return OracleMWConfig.delete(jdbcWrapper)
#enddef--deleteDatasource

####################################
# convertJdbcNormalDatasourceToRAC #
####################################
def convertJdbcNormalDatasourceToRAC(jdbcInstanceName, racServiceName, hostPortList):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  isRac = jdbcWrapper.getValue("IsRac")
  if 'true' == isRac:
    return
  if jdbcWrapper != None:
    jdbcWrapper.setValue('IsRac', 'true')
    jdbcWrapper.setValue('RacService', racServiceName)
    setJdbcRacHostsPorts(jdbcInstanceName, hostPortList)
#enddef--convertJdbcNormalDatasourceToRAC

####################################
# convertJdbcRACToNormalDatasource #
####################################
def convertJdbcRACToNormalDatasource(jdbcInstanceName, databaseType, isXa, host, port):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  isRac = jdbcWrapper.getValue("IsRac")
  if 'true' != isRac:
    return
  if jdbcWrapper != None:
    jdbcWrapper.setValue('IsRac', 'false')
    jdbcWrapper.setValue('DatabaseType', databaseType)    
    jdbcWrapper.setValue('IsXa', isXa)
    jdbcWrapper.setValue('ServerName', host)
    jdbcWrapper.setValue('PortNumber', port)
#enddef--convertJdbcRACToNormalDatasource

####################################
#           getJdbcURL             #
####################################
def getJdbcURL(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('URL')
#enddef--getJdbcURL

####################################
#       getJdbcDriverClass         #
####################################
def getJdbcDriverClass(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('DriverClass')
#enddef--getJdbcDriverClass
  
####################################
#       getJdbcInstanceType        #
####################################
def getJdbcInstanceType(jdbcInstanceName):
  jdbcWrapper = OracleMWConfig.getChildByName('JDBC', jdbcInstanceName)
  if jdbcWrapper != None:
    return jdbcWrapper.getValue('Type')
#enddef--getJdbcInstanceType

####################################
#               help               #
####################################
def help(topic = None):
  m_name = 'OracleMWConfigUtilities'
  if topic == None:
    topic = m_name
  else:
    topic = m_name + '.' + topic
  return OracleHelp.help(topic)
#enddef--help

####################################
#          getNodeByServer         #
####################################
def getNodeByServer(serverName):
  if WSAdminExtension.isInConfigurationState():
    servers = OracleMWConfig.getChildren('Server')
    if servers != None:
      for server in servers:
        name = server.getValue("Name")
        if name == serverName:
          return server.getValue("NodeName")
  else:
    lineSeparator = java.lang.System.getProperty('line.separator')
    nodes = AdminConfig.list("Node").split(lineSeparator)
    for node in nodes:
      servers = AdminConfig.list('Server', node).split(lineSeparator)
      for server in servers:
        name = AdminConfig.showAttribute(server, "name")
        if name == serverName:
          return AdminConfig.showAttribute(node, "name")
#enddef--getNodeByServer

####################################
#           getNodeByHost          #
####################################
def getNodeByHost(hostName):
  lineSeparator = java.lang.System.getProperty('line.separator')
  nodes = AdminConfig.list("Node").split(lineSeparator)
  for node in nodes:
    servers = AdminConfig.list('Server', node).split(lineSeparator)
    dmgrNode = 0
    for server in servers:
      if AdminConfig.showAttribute(server, "serverType") == "DEPLOYMENT_MANAGER":
        dmgrNode = 1
    if dmgrNode == 0:
      host = AdminConfig.showAttribute(node, "hostName")
      if host == hostName:
        return AdminConfig.showAttribute(node, "name")
#enddef--getNodeByHost

####################################
#           getLocalNode           #
####################################
def getLocalNode():
  host = java.net.InetAddress.getLocalHost().getCanonicalHostName();
  return getNodeByHost(host)
#enddef--getLocalNode

