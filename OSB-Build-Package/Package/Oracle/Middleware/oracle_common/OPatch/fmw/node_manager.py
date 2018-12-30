# Copyright (c) 2004, 2010, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      node_manager.py
#
#    DESCRIPTION
#    The file contains the definition of all generic routines and global vars.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#     MODIFIED   (MM/DD/YY)
#     akmaurya   06/22/10 - 9465690
#     supal      11/19/09 - Optimize prereq checks and support classpath
#                           patches
#     supal      10/20/09 - Admin Server deployments
#     supal      09/27/09 - Need to work with various Node Manager Types
#     supal      09/04/09 - More checks for Configuration corner cases
#     supal      07/08/09 - Creation

import sys
import os
import exceptions

def connect_NodeManager(nmhostName,nmhostPort,nmSecurityType,domainName,domainHome):
    #cd ('/SecurityConfiguration/' + domainName)
    try:
       logMsg('   Connecting to Node Manager at \'' + nmhostName +
              '\' on Port \'' + str(nmhostPort) + '\'')
       if( (myNMConfigFile is not None) and (len( myNMConfigFile) > 0)):     
          nmConnect( userConfigFile=myNMConfigFile,userKeyFile=myNMKeyFile,host=nmhostName,port=nmhostPort,domainName=domainName,domainDir=domainHome,nmType=nmSecurityType.lower())
       else: 
          nmConnect( nmUsername, nmPassword,nmhostName,nmhostPort,domainName,domainHome,nmType=nmSecurityType.lower())
       #nmConnect(get('NodeManagerUsername'),get('NodeManagerPassword'),nmhostName,nmhostPort,domainName,domainHome)
    except:
       (c, i, tb) =  sys.exc_info()
       logMsg('   SEVERE: Exception: during connection to Node Manager')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))
       return(FmwConstants.FMW_NMCONNECT_FAILED)

def disconnect_NodeManager():
     try:
       nmDisconnect()
     except:
       (c, i, tb) =  sys.exc_info()
       logMsg('   SEVERE: Exception: during disconnection to Node Manager')
       logMsg('   ExceptionName: ' + str(c) +', ExceptionCode: ' + str(i))

def get_NodeManagerHostPortType(svrName):
    machineMBean = getMBean('/Servers/' + svrName).getMachine()
    if (machineMBean is None):
       # WebLogic allows Servers to run without assigned machines.
       # OPatch cannot handle this Configuration corner case       
       raise exceptions.EnvironmentError(FmwConstants.FMW_NO_MACHINES_CONFIGURED,'No Machine configured for \'' + svrName + '\'')
    machineName = machineMBean.getName()
    logMsg('   WebLogic Cfg [Server Name: \'' + svrName + '\' Machine Name: \'' + machineName + '\']')
    nodeManagerMBean = getMBean('/Servers/' + svrName + '/Machine/' + machineName + '/NodeManager/' + machineName)
    hostName = nodeManagerMBean.getListenAddress()
    hostPort = nodeManagerMBean.getListenPort()
    nmSecurityType = nodeManagerMBean.getNMType()
    logMsg('   Node Manager [Machine Name: ' + hostName +
           ', Listen Port: ' + str(hostPort) + ', Type: ' + nmSecurityType + ']')
    return hostName, hostPort, nmSecurityType

class NodeManager:

    def isConnected(self):
       nmStatus()

    def connect(nm_user, nm_pw, nm_host, nm_port, domain_name, domain_home):
       nmStatus()

    # Without any parameters we will try to figure out the inputs required by 
    # Node Manager by navigating the MBean hierarchy
    def connect():
       env = os.environ
       myHostname = env.get('HOSTNAME')

    # If a hostname is given we will try to connect to the Node Manager on that
    # physical host
    def connect(hostname):
       nmStatus()

    def disconnect():
       nmDisconnect()

    def __init__(self):
       self._x = None
 
