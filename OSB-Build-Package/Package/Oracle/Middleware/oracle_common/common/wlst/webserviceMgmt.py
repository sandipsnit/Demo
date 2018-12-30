"""
 Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the WLST implementation. Do not edit or move     
this file because this may cause WLST commands and scripts to fail. Do not     
try to reuse the logic in this file or keep copies of this file because this    
could cause your WLST scripts to fail when you upgrade to a different version   
of WLST.  
-------------------------------------------------------------------------------
micchen 05/08/09 - creation
-------------------------------------------------------------------------------
"""


from oracle.j2ee.ws.mgmt.wlst import ListWebServices
from oracle.j2ee.ws.mgmt.wlst import ListWebServicePorts
from oracle.j2ee.ws.mgmt.wlst import ListWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceConfiguration 
from oracle.j2ee.ws.mgmt.wlst import AttachWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import EnableWebServicePolicy
from oracle.j2ee.ws.mgmt.wlst import DetachWebServicePolicy 
from oracle.j2ee.ws.mgmt.wlst import ConfigureWebService 
from oracle.j2ee.ws.mgmt.wlst import ConfigWebServicePolicyOverride 
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefs
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefPortInfos
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefPolicy 
from oracle.j2ee.ws.mgmt.wlst import AttachWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import EnableWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import DetachWebServiceRefPolicy
from oracle.j2ee.ws.mgmt.wlst import ListWebServiceRefStubProperties
from oracle.j2ee.ws.mgmt.wlst import SetWebServiceRefStubProperty 
from oracle.j2ee.ws.mgmt.wlst import SetWebServiceRefStubProperties
from oracle.j2ee.ws.mgmt.wlst import ListAvailableWebServicePolicy 
from oracle.j2ee.ws.mgmt.wlst.resources import Messages 


from oracle.j2ee.ws.mgmt.server.mbean.portability.wls import WeblogicServerUtils
from oracle.j2ee.ws.mgmt.server.mbean.portability import ServerUtils
  
  
from javax.management import RuntimeMBeanException
from java.util import ResourceBundle
from java.util import Locale


try: 
   addHelpCommandGroup("WebServices", "oracle.j2ee.ws.mgmt.wlst.resources.wsWLSTHelp")
 
   addHelpCommand("listWebServices", "WebServices", offline="false") 
   addHelpCommand("listWebServicePorts", "WebServices", offline="false")
   addHelpCommand("listWebServicePolicies", "WebServices", offline="false")
   addHelpCommand("attachWebServicePolicy", "WebServices", offline="false")
   addHelpCommand("attachWebServicePolicies", "WebServices", offline="false")
   addHelpCommand("detachWebServicePolicy", "WebServices", offline="false")
   addHelpCommand("detachWebServicePolicies", "WebServices", offline="false")
   addHelpCommand("enableWebServicePolicy", "WebServices", offline="false")
   addHelpCommand("enableWebServicePolicies", "WebServices", offline="false")

   addHelpCommand("listWebServiceClients", "WebServices", offline="false")
   addHelpCommand("listWebServiceClientPorts", "WebServices", offline="false")
   addHelpCommand("listWebServiceClientPolicies", "WebServices", offline="false")
   addHelpCommand("attachWebServiceClientPolicy", "WebServices", offline="false")
   addHelpCommand("attachWebServiceClientPolicies", "WebServices", offline="false")
   addHelpCommand("detachWebServiceClientPolicy", "WebServices", offline="false")
   addHelpCommand("detachWebServiceClientPolicies", "WebServices", offline="false")
   addHelpCommand("enableWebServiceClientPolicy", "WebServices", offline="false") 
   addHelpCommand("enableWebServiceClientPolicies", "WebServices", offline="false")

   addHelpCommand("setWebServicePolicyOverride", "WebServices", offline="false")
   addHelpCommand("listWebServiceConfiguration", "WebServices", offline="false")
   addHelpCommand("setWebServiceConfiguration", "WebServices", offline="false")
   addHelpCommand("listWebServiceClientStubProperties", "WebServices", offline="false")
   addHelpCommand("setWebServiceClientStubProperties", "WebServices", offline="false")
   addHelpCommand("setWebServiceClientStubProperty", "WebServices", offline="false")
   addHelpCommand("listAvailableWebServicePolicies", "WebServices", offline="false")
   addHelpCommand("exportJRFWSApplicationPDD", "WebServices", offline="false")
   addHelpCommand("importJRFWSApplicationPDD", "WebServices", offline="false")
   addHelpCommand("savePddToAllAppInstancesInDomain", "WebServices", offline="false") 
except Exception, ex:   
   pass

   
   

_ws_ResourceBundle = ResourceBundle.getBundle("oracle.j2ee.ws.mgmt.wlst.resources.Messages") 


"""
-------------------------------------------------------------------------------
WebService management  
-------------------------------------------------------------------------------
"""


# 
# private internal mbs control util tools
#
def _ws_gotoDomainRuntime():   
   currentNode = pwd()
   if (currentNode.find('domainRuntime') == -1): 
       ctree=currentTree()
       domainRuntime()
       return ctree
   else:
       return None
  
       
      
#
#      
def _ws_backtoOldTree(oldTree=None): 
  if (oldTree != None): 
      oldTree()
  return 


 
# This command list WebServices information for an application or composite.
# @application The name of the application. e.g.: /domain/application#version  
# @composite The name of SOA composite. e.g.: HelloWorld[1.0] 
# @detail To list detail webservice with port info. default is false 
def listWebServices(application=None, composite=None, detail=false): 
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()  
  try: 
    lws = ListWebServices(mbs)  
    if detail:
       lws.setMessageLevel(1) 
    retValue = lws.execute(application , composite)
  except Exception, ex:
     print ex.getMessage() 
  _ws_backtoOldTree(myOldTree)   
  return 
  
  
# This command list WebServices Port information for a WebServices. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite  
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
def listWebServicePorts(application, moduleName, moduleType, serviceName): 
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()   
  try: 
    lwsp = ListWebServicePorts(mbs) 
    retValue = lwsp.execute(application, serviceName, moduleType, moduleName) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree) 
  return 
    

# This command list WebServiceClients information for an application or composite.
# @application The name of the application. e.g.: /domain/application#version  
# @composite The name of SOA composite. e.g.: HelloWorld[1.0] 
# @detail To list detail webservice client with port info. default is false 
def listWebServiceClients(application=None, composite=None, detail=false): 
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    lwr = ListWebServiceRefs(mbs)  
    if detail:
       lwr.setMessageLevel(1) 
    retValue = lwr.execute(application , composite)
  except Exception, ex:
     print ex.getMessage()   
  _ws_backtoOldTree(myOldTree)
  return 
  
  
# This command list WebServiceClients Port information for an WebServices. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebService client name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
def listWebServiceClientPorts(application, moduleName, moduleType, serviceRefName): 
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()   
  try: 
    lwrp = ListWebServiceRefPortInfos(mbs) 
    retValue = lwrp.execute(application, serviceRefName, moduleType, moduleName) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
 
 

"""
-------------------------------------------------------------------------------
WebService policy attachment  
-------------------------------------------------------------------------------
"""    
 
# This command list WebServices Port Policy information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
def listWebServicePolicies(application, moduleName, moduleType, serviceName, subjectName):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    lwspp = ListWebServicePolicy(mbs) 
    retValue = lwspp.execute(application, serviceName, moduleType, moduleName, subjectName) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
  
  
# This command list WebServiceClients PortInfo Policy information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
def listWebServiceClientPolicies(application, moduleName, moduleType, serviceRefName, subjectName):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    lwrpp = ListWebServiceRefPolicy(mbs) 
    retValue = lwrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()  
  try: 
    awspp = AttachWebServicePolicy(mbs) 
    uris = [ policyURI ]      
    retValue = awspp.execute(application, serviceName, moduleType, moduleName, subjectName, uris)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    awspp = AttachWebServicePolicy(mbs)     
    retValue = awspp.execute(application, serviceName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    dwspp = DetachWebServicePolicy(mbs)  
    uris = [ policyURI ]   
    retValue = dwspp.execute(application, serviceName, moduleType, moduleName, subjectName, uris)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    dwspp = DetachWebServicePolicy(mbs)     
    retValue = dwspp.execute(application, serviceName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
def enableWebServicePolicy(application, moduleName, moduleType, serviceName, subjectName, policyURI, enable=true, subjectType=None):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    ewspp = EnableWebServicePolicy(mbs)  
    uris = [ policyURI ]   
    retValue = ewspp.execute(application, serviceName, moduleType, moduleName, subjectName, uris, enable)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
def enableWebServicePolicies(application, moduleName, moduleType, serviceName, subjectName, policyURIs, enable=true, subjectType=None):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    ewspp = EnableWebServicePolicy(mbs)     
    retValue = ewspp.execute(application, serviceName, moduleType, moduleName, subjectName, policyURIs, enable)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return 
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    awrpp = AttachWebServiceRefPolicy(mbs) 
    uris = [ policyURI ]    
    retValue = awrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, uris)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    awrpp = AttachWebServiceRefPolicy(mbs)     
    retValue = awrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    dwrpp = DetachWebServiceRefPolicy(mbs)  
    uris = [ policyURI ]   
    retValue = dwrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, uris)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    dwrpp = DetachWebServiceRefPolicy(mbs)     
    retValue = dwrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, policyURIs)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
def enableWebServiceClientPolicy(application, moduleName, moduleType, serviceRefName, subjectName, policyURI, enable=true, subjectType=None):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    ewrpp = EnableWebServiceRefPolicy(mbs)  
    uris = [ policyURI ]   
    retValue = ewrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, uris, enable)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
def enableWebServiceClientPolicies(application, moduleName, moduleType, serviceRefName, subjectName, policyURIs, enable=true, subjectType=None): 
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return 
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    ewrpp = EnableWebServiceRefPolicy(mbs)     
    retValue = ewrpp.execute(application, serviceRefName, moduleType, moduleName, subjectName, policyURIs, enable)
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
  
  
  
"""
-------------------------------------------------------------------------------
WebService configuration   
-------------------------------------------------------------------------------
"""    
 
 
# This command to list WebServices/Port configuration information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceName The WebService name of the application or composite name 
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
# @Deprecated 
def listWebServiceConfiguration(application, moduleName, moduleType, serviceName, subjectName=None):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    lwsc = ListWebServiceConfiguration(mbs) 
    retValue = lwsc.execute(application, serviceName, moduleType, moduleName, subjectName) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
# @Deprecated 
def setWebServiceConfiguration(application, moduleName, moduleType, serviceName, subjectName, itemProperties):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    cwsc = ConfigureWebService(mbs) 
    cwsc.setWebService(application, serviceName, moduleType, moduleName, subjectName)  
    cwsc.setConfigProperties(itemProperties)   
    retValue = cwsc.execute()  
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
  
   

# This command to list WebServiceClients PortInfo Stub Properties information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name    
def listWebServiceClientStubProperties(application, moduleName, moduleType, serviceRefName, subjectName):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    lwrpsp = ListWebServiceRefStubProperties(mbs) 
    retValue = lwrpsp.execute(application, serviceRefName, moduleType, moduleName, subjectName) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return
  
  
# This command to configure all WebServiceClients PortInfo Stub Properties information. 
# @application The name of the application. e.g.: /domain/application#version    
# @serviceRefName The WebServiceClient name of the application or composite name
# @moduleType The module type can be web or soa 
# @moduleName The web module name or SOA composite name. e.g.: HelloWorld[1.0] 
# @subjectName The policy subject, port or operation name   
# @properties The stub properties. e.g.:  [("ROLE","ADMIN"), ("myprop","myval")]     
def setWebServiceClientStubProperties(application, moduleName, moduleType, serviceRefName, subjectName, properties): 
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return 
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    swrpsp = SetWebServiceRefStubProperties(mbs)  
    retValue = swrpsp.execute(application, serviceRefName, moduleType, moduleName, subjectName, properties) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    swrpsp = SetWebServiceRefStubProperty(mbs)  
    retValue = swrpsp.execute(application, serviceRefName, moduleType, moduleName, subjectName, propName, propValue) 
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
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
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime() 
  try: 
    cwsc = ConfigWebServicePolicyOverride(mbs) 
    cwsc.setWebService(application, serviceName, moduleType, moduleName, subjectName)  
    cwsc.setPolicyOverride(policyURI, properties)    
    retValue = cwsc.execute()  
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
   
  
  
# This command to list all available OWSM policy URIs. 
# @category Optinal. The policy category. e.g.: 'security' , 'management'.    
# @subject Optional. The policy subject type. e.g.: 'server' or 'client' 
def listAvailableWebServicePolicies(category=None, subject=None):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()  
  try: 
    lwspy = ListAvailableWebServicePolicy(mbs)     
    retValue = lwspy.execute(category, subject)  
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
    
    
   
# This command is to export a JRF WS Application PDD jar file  
# @application The the JRF WS application. e.g.: /domain/application#version  
#    Use fully name path to uniquely identify application runtime instance
# @pddJarFileName Optional. The PDD jar file name. e.g.: '/tmp/mywspdd.jar' 
# @Deprecated 
def exportJRFWSApplicationPDD(application, pddJarFileName=None):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()  
  try: 
     if (application == None):
         print "No application specified!"
         return
     
     if (application.find('soa-infra') >= 0): 
         print "Cannot export SOA!"
         return
     
     lws = ListWebServices(mbs)      
     appList = lws.getApplications(application , None)
     
     if (appList.size() == 0):
         print "No application found!"
         return
     
     if (appList.size() > 1):
         print "Multiple applcation runtime instance found. Please use fully specified name."
         return
         
     applicationRuntimeON = appList[0]          
     svrUtils = WeblogicServerUtils(mbs)  
     retValue = svrUtils.exportApplicationPDD(applicationRuntimeON, pddJarFileName) 
     print retValue 
     
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
   
     
# This command is to import JRF WS Application PDD from an exported pdd jar file  
# @application The JRF WS application. e.g.: /domain/application#version  
#    Use fully name path to uniquely identify application runtime instance
# @pddJarFileName The PDD jar file name. e.g.: '/tmp/mywspdd.jar' 
# @Deprecated 
def importJRFWSApplicationPDD(application, pddJarFileName):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()  
  try: 
     if (application == None):
         print "No application specified!"
         return
     
     if (application.find('soa-infra') >= 0): 
         print "Cannot export SOA!"
         return
     
     lws = ListWebServices(mbs)      
     appList = lws.getApplications(application , None)
     
     if (appList.size() == 0):
         print "No application found!"
         return
     
     if (appList.size() > 1):
         print "Multiple applcation runtime instance found. Please use fully specified name."
         return
         
     applicationRuntimeON = appList[0]          
     svrUtils = WeblogicServerUtils(mbs)  
     svrUtils.importApplicationPDD(applicationRuntimeON, pddJarFileName) 
         
     print "application ", application, " PDD has been reset, please restart application now to uptake changes!" 
     
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
   


# This command is to import and save the previously exported PDD jar file  
# to all the application instances in the connected domain 
# @applicationName The name of the JRF WS application. e.g.: application#version  
# @pddJarFileName The PDD jar file name. e.g.: '/tmp/mywspdd.jar' 
# @restartApp Optional. Restart the application automatically. Default is true.
# @Deprecated 
def savePddToAllAppInstancesInDomain(applicationName, pddJarFileName, restartApp=true):  
  if (connected != 'true'):
      msg = _ws_ResourceBundle.getString("ERROR_MSG_WLST_NOT_CONNECT")
      print msg
      return
  myOldTree=_ws_gotoDomainRuntime()  
  try: 
     if (applicationName == None):
         print "No application name specified!"
         return
     
     if (applicationName.find('soa-infra') >= 0): 
         print "Cannot export SOA!"
         return
     
     lws = ListWebServices(mbs)      
     appList = lws.getApplications(applicationName , None)
     
     if (appList.size() == 0):
         print "No application found!"
         return
                 
                 
     for appON in appList:     
         print "saving pdd to ", appON      
         svrUtils = WeblogicServerUtils(mbs) 
         svrUtils.importApplicationPDD(appON, pddJarFileName) 
      
      
     if (restartApp == true):  
         print "restarting application ", applicationName 
         stopApplication(applicationName) 
         startApplication(applicationName) 
     else:
         print "application ", applicationName, " PDD has been reset, please restart application now to uptake changes!" 
          
          
  except Exception, ex:
     print ex.getMessage()  
  _ws_backtoOldTree(myOldTree)
  return 
   
      

