"""
 Copyright (c) 2009, 2010, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the ojbst implementation. Do not edit or move
this file because this may cause ojbst commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your ojbst scripts to fail when you upgrade to a different version
of ojbst.
-------------------------------------------------------------------------------
chpatel 02/05/10 - creation
-------------------------------------------------------------------------------
"""

import OracleJMX
import ora_util
import cie.OracleHelp as OracleHelp

from oracle.j2ee.ws.mgmt.wlst import ListWebServices
from oracle.j2ee.ws.mgmt.wlst import ListWebServicePorts
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefs
from oracle.j2ee.ws.mgmt.wlst import ListAvailableWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import ListWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import AttachWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import EnableWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import DetachWebServicePolicy 
from oracle.j2ee.ws.mgmt.wlst import ConfigureWebService 
from oracle.j2ee.ws.mgmt.wlst import ConfigWebServicePolicyOverride 
from oracle.j2ee.ws.mgmt.wlst import AttachWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import EnableWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import DetachWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefStubProperties
from oracle.j2ee.ws.mgmt.wlst import SetWebServiceRefStubProperty 
from oracle.j2ee.ws.mgmt.wlst import SetWebServiceRefStubProperties
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceConfiguration
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefPortInfos

from java.lang import Exception
from java.util import ResourceBundle
_ws_ResourceBundle = ResourceBundle.getBundle("oracle.j2ee.ws.mgmt.wlst.resources.Messages")

def help(topic = None):
  m_name = 'WebServices'
  if topic == None:
    topic = m_name
  else:
    topic = m_name + '.' + topic
  return OracleHelp.help(topic)

# This command list WebServices information for an application or composite.
# @application The name of the application. e.g.: /domain/application#version
# @composite The name of SOA composite. e.g.: HelloWorld[1.0]
# @detail To list detail webservice with port info. default is false
def listWebServices(application=None, composite=None, detail=0):
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT", )
      print msg
      return  
  try:
    lws = ListWebServices(OracleJMX.getMbsInstance())
    if detail:
       lws.setMessageLevel(1)
    retValue = lws.execute(application , composite)
  except Exception, e:
    print e.getMessage()
  return

# This command list WebServices Port information for a WebServices. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite  
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
def listWebServicePorts(application, moduleName, moduleType, serviceName): 
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try: 
    lwsp = ListWebServicePorts(OracleJMX.getMbsInstance()) 
    retValue = lwsp.execute(application, serviceName, moduleType, moduleName) 
  except Exception, e:
    print e.getMessage()
  return 

# This command list WebServiceClients information for an application or composite.
# @application The name of the application. e.g.: /domain/application#version  
# @composite The name of SOA composite. e.g.: HelloWorld[1.0] 
# @detail To list detail webservice client with port info. default is false 
def listWebServiceClients(application=None, composite=None, detail=0): 
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return 
  try: 
    lwr = ListWebServiceRefs(OracleJMX.getMbsInstance())
    if detail:
       lwr.setMessageLevel(1) 
    retValue = lwr.execute(application , composite)
  except Exception, e:
    print e.getMessage()
  return 

# This command to list all available OWSM policy URIs. 
# @category Optinal. The policy category. e.g.: 'security' , 'management'.    
# @subject Optional. The policy subject type. e.g.: 'server' or 'client' 
def listAvailableWebServicePolicies(category=None, subject=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try: 
    lwspy = ListAvailableWebServicePolicy(OracleJMX.getMbsInstance())
    retValue = lwspy.execute(category, subject)
  except Exception, e:
    print e.getMessage()
  return

# This command list WebServices Port Policy information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
def listWebServicePolicies(application, moduleName, moduleType, serviceName, subjectName):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try: 
    lwspp = ListWebServicePolicy(OracleJMX.getMbsInstance())
    retValue = lwspp.execute(application, serviceName, moduleType, moduleName, subjectName) 
  except Exception, e:
    print e.getMessage()
  return

# This command for WebServices Port PolicyAttachement 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
# @policyURI The policy name URI. e.g. "oracle/log_policy" 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def attachWebServicePolicy(application, moduleName, moduleType, serviceName, subjectName, policyURI, subjectType=None): 
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return  
  try: 
    awspp = AttachWebServicePolicy(OracleJMX.getMbsInstance()) 
    uris = [ policyURI ]      
    retValue = awspp.execute(application, serviceName, moduleType, moduleName, subjectName, uris)
  except Exception, e:
    print e.getMessage()
  return 

# This command for detach a WebServices Port Policy 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURI The list policy name URI. e.g. "oracle/Wss_username_token_service_policy"  
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def detachWebServicePolicy(application, moduleName, moduleType, serviceName, subjectName, policyURI, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return 
  try:
    dwspp = DetachWebServicePolicy(OracleJMX.getMbsInstance())
    uris = [ policyURI ]
    retValue = dwspp.execute(application, serviceName, moduleType, moduleName, subjectName, uris)
  except Exception, e:
    print e.getMessage()
  return 

# This command for enable or disable a WebServices Port Policy 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
# @policyURI The list policy name URI. e.g. "oracle/wss_username_token_service_policy" 
# @enable To enable or disable policy. e.g.: true or false. default is true. 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def enableWebServicePolicy(application, moduleName, moduleType, serviceName, subjectName, policyURI, enable='true', subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try:
    ewspp = EnableWebServicePolicy(OracleJMX.getMbsInstance())
    uris = [ policyURI ]
    retValue = ewspp.execute(application, serviceName, moduleType, moduleName, subjectName, uris, enable)
  except Exception, e:
    print e.getMessage()
  return 

# This command for attach a WebServiceClients PortInfo PolicyAttachement 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURI The policy name URI. e.g. "oracle/log_policy" 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def attachWebServiceClientPolicy(application, moduleName, moduleType, serviceRefName, subjectName, policyURI, subjectType=None): 
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try: 
    awrpp = AttachWebServiceRefPolicy(OracleJMX.getMbsInstance())
    uris = [ policyURI ]
    retValue = awrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, uris)
  except Exception, e:
    print e.getMessage()
  return 

# This command for detach a WebServiceClients PortInfo Policy 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURI The policy name URI. e.g. "oracle/Wss_username_token_client_policy"  
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def detachWebServiceClientPolicy(application, moduleName, moduleType, serviceRefName, subjectName, policyURI, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try: 
    dwrpp = DetachWebServiceRefPolicy(OracleJMX.getMbsInstance())
    uris = [ policyURI ]
    retValue = dwrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, uris)
  except Exception, e:
    print e.getMessage()
  return 

# This command for enable or disable a WebServiceClients PortInfo Policy 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURI The policy name URI. e.g. "oracle/Wss_username_token_client_policy" 
# @enable To enable or disable policy. e.g.: true or false. default is true. 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def enableWebServiceClientPolicy(application, moduleName, moduleType, serviceRefName, subjectName, policyURI, enable='true', subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try: 
    ewrpp = EnableWebServiceRefPolicy(OracleJMX.getMbsInstance())
    uris = [ policyURI ]
    retValue = ewrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, uris, enable)
  except Exception, e:
    print e.getMessage()
  return 

# This command to set and change WebServices/Port configuration information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name 
# @itemProperties The configuration items. e.g.:   
#         [("enable", "true"), ("enableMTOM", "true"), ("enableREST", "false"),
#          ("enableTestPage", "true"), ("enableSOAP", "true"), ("enableWSDL", "true"),
#          ("maxRequestSize", "8000")]  
def setWebServiceConfiguration(application, moduleName, moduleType, serviceName, subjectName, itemProperties):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return 
  try:
    cwsc = ConfigureWebService(OracleJMX.getMbsInstance())
    cwsc.setWebService(application, serviceName, moduleType, moduleName, subjectName)
    cwsc.setConfigProperties(itemProperties)
    retValue = cwsc.execute()
  except Exception, e:
    print e.getMessage()
  return 

# This command to configure/reset a WebServiceClients PortInfo Stub Property information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
# @propName The stub property name. e.g.: 'keystore.recipient.alias' 
# @propValue The stub property value. e.g.:  'orakey'. A blank "" value to remove the property.    
def setWebServiceClientStubProperty(application, moduleName, moduleType, serviceRefName, subjectName, propName, propValue=None):  
  if (OracleJMX.isConnected() != 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try:
    swrpsp = SetWebServiceRefStubProperty(OracleJMX.getMbsInstance())
    retValue = swrpsp.execute(application, serviceRefName, moduleType, moduleName, subjectName, propName, propValue)
  except Exception, e:
    print e.getMessage()
  return
  
 

# This command to set and change WebServices/Port Policy Override information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name  
# @policyURI The policyURI for which the override properties applied.
# @properties The policy override properties. e.g.:  [("ROLE","ADMIN"), ("myprop","myval")]   
def setWebServicePolicyOverride(application, moduleName, moduleType, serviceName, subjectName, policyURI, properties):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_OJBST_NOT_CONNECT")
      print msg
      return
  try:
    cwsc = ConfigWebServicePolicyOverride(OracleJMX.getMbsInstance())
    cwsc.setWebService(application, serviceName, moduleType, moduleName, subjectName)
    cwsc.setPolicyOverride(policyURI, properties)
    retValue = cwsc.execute()
  except Exception, e:
    print e.getMessage()
  return 

# This command for WebServices Port PolicyAttachement with multiple polices 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
# @policyURIs The list of policy name URI. e.g. 
#       ["oracle/log_policy", "oracle/wss_username_token_service_policy"]  
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def attachWebServicePolicies(application, moduleName, moduleType, serviceName, subjectName, policyURIs, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    awspp = AttachWebServicePolicy(OracleJMX.getMbsInstance())     
    retValue = awspp.execute(application, serviceName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, e:
    print e.getMessage()
  return

# This command for WebServiceClients PortInfo PolicyAttachement with multiple polices 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
# @policyURIs The list of policy name URI. e.g. 
#             ["oracle/log_policy",  "oracle/Wss_username_token_client_policy"] 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def attachWebServiceClientPolicies(application, moduleName, moduleType, serviceRefName, subjectName, policyURIs, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    awrpp = AttachWebServiceRefPolicy(OracleJMX.getMbsInstance())
    retValue = awrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, e:
    print e.getMessage()
  return 

# This command for detach WebServices Port Policy with multiple polices 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURIs The list policy name URI. e.g. ["oracle/log_policy",  "oracle/Wss_username_token_service_policy"] 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def detachWebServicePolicies(application, moduleName, moduleType, serviceName, subjectName, policyURIs, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    dwspp = DetachWebServicePolicy(OracleJMX.getMbsInstance())
    retValue = dwspp.execute(application, serviceName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, e:
    print e.getMessage()
  return

# This command for detach WebServiceClients PortInfo Policy with multiple polices 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURIs The list of policy name URI. e.g. ["oracle/log_policy",  "oracle/Wss_username_token_client_policy"] 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def detachWebServiceClientPolicies(application, moduleName, moduleType, serviceRefName, subjectName, policyURIs, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    dwrpp = DetachWebServiceRefPolicy(OracleJMX.getMbsInstance())
    retValue = dwrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, e:
    print e.getMessage()
  return

# This command for enable or disable WebServices Port Policy with multiple polices 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite  
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURIs The list policy name URI. e.g. ["oracle/log_policy","oracle/wss_username_token_service_policy"]  
# @enable To enable or disable policy. e.g.: true or false. default is true. 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def enableWebServicePolicies(application, moduleName, moduleType, serviceName, subjectName, policyURIs, enable=1, subjectType=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    ewspp = EnableWebServicePolicy(OracleJMX.getMbsInstance())
    retValue = ewspp.execute(application, serviceName, moduleType, moduleName, subjectName, policyURIs, enable)
  except Exception, e:
    print e.getMessage()
  return

# This command for enable or disable WebServiceClients PortInfo Policy with multiple polices 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @policyURIs The list  ofpolicy name URI. e.g. ["oracle/log_policy",  "oracle/Wss_username_token_client_policy"]  
# @enable To enable or disable policy. e.g.: true or false. default is true. 
# @subjectType The policy subject type 'P' or 'O'. Default is 'P' for port.
def enableWebServiceClientPolicies(application, moduleName, moduleType, serviceRefName, subjectName, policyURIs, enable=1, subjectType=None): 
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    ewrpp = EnableWebServiceRefPolicy(OracleJMX.getMbsInstance())
    retValue = ewrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, policyURIs, enable)
  except Exception, e:
    print e.getMessage()
  return

# This command list WebServiceClients PortInfo Policy information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
def listWebServiceClientPolicies(application, moduleName, moduleType, serviceRefName, subjectName):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    lwrpp = ListWebServiceRefPolicy(OracleJMX.getMbsInstance())
    retValue = lwrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName) 
  except Exception, e:
    print e.getMessage()
  return

# This command list WebServiceClients Port information for an WebServices. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebService client name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
def listWebServiceClientPorts(application, moduleName, moduleType, serviceRefName): 
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return
  try: 
    lwrp = ListWebServiceRefPortInfos(OracleJMX.getMbsInstance()) 
    retValue = lwrp.execute(application, serviceRefName, moduleType, moduleName) 
  except Exception, e:
    print e.getMessage()
  return  

# This command to list WebServiceClients PortInfo Stub Properties information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
def listWebServiceClientStubProperties(application, moduleName, moduleType, serviceRefName, subjectName):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return 
  try: 
    lwrpsp = ListWebServiceRefStubProperties(OracleJMX.getMbsInstance()) 
    retValue = lwrpsp.execute(application, serviceRefName, moduleType, moduleName, subjectName) 
  except Exception, e:
    print e.getMessage()
  return

# This command to list WebServices/Port configuration information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
def listWebServiceConfiguration(application, moduleName, moduleType, serviceName, subjectName=None):  
  if (OracleJMX.isConnected() == 0):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WSADMIN_NOT_CONNECT")
      print msg
      return 
  try: 
    lwsc = ListWebServiceConfiguration(OracleJMX.getMbsInstance()) 
    retValue = lwsc.execute(application, serviceName, moduleType, moduleName, subjectName) 
  except Exception, e:
    print e.getMessage()
  return 
