"""
 Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the command scripting implementation. Do not edit
or move this file because this may cause commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your scripts to fail when you upgrade to a different version
"""

import OracleLibOVD_handler as handler
import OracleHelp

def createLDAPAdapter(adapterName, root, host, port, remoteBase, isSecure=0, bindDN='', bindPasswd='', passCred='Always', contextName='default'):
  handler.createLDAPAdapter(adapterName, root, host, port, remoteBase, isSecure, bindDN, bindPasswd, passCred, contextName)

def createJoinAdapter(adapterName, root, primaryAdapter, bindAdapter=None, contextName='default'):
  handler.createJoinAdapter(adapterName, root, primaryAdapter, bindAdapter, contextName)

def deleteAdapter(adapterName, contextName='default'):
  handler.deleteAdapter(adapterName, contextName)

def modifyLDAPAdapter(adapterName, attribute, value, contextName='default'):
  handler.modifyLDAPAdapter(adapterName, attribute, value, contextName)

def addLDAPHost(adapterName, host, port, contextName='default'):
  handler.addLDAPHost(adapterName, host, port, contextName)

def removeLDAPHost(adapterName, host, contextName='default'):
  handler.removeLDAPHost(adapterName, host, contextName)

def addJoinRule(adapterName, secondary, condition, joinerType='Simple', contextName='default'):
  handler.addJoinRule(adapterName, secondary, condition, joinerType, contextName)

def removeJoinRule(adapterName, secondary, contextName='default'):
  handler.removeJoinRule(adapterName, secondary, contextName)

def addPlugin(pluginName, pluginClass, paramKeys, paramValues, adapterName='GlobalPlugin', contextName='default'):
  handler.addPlugin(pluginName, pluginClass, paramKeys, paramValues, adapterName, contextName)

def removePlugin(pluginName, adapterName='GlobalPlugin', contextName='default'):  handler.removePlugin(pluginName, adapterName, contextName)
  
def addPluginParam(pluginName, paramKeys, paramValues, adapterName='GlobalPlugin', contextName='default'):
  handler.addPluginParam(pluginName, paramKeys, paramValues, adapterName, contextName)

def removePluginParam(pluginName, paramKey, adapterName='GlobalPlugin', contextName='default'):
  handler.removePluginParam(pluginName, paramKey, adapterName, contextName)

def listAdapters(contextName='default'):
  handler.listAdapters(contextName)

def getAdapterDetails(adapterName, contextName='default'):
  handler.getAdapterDetails(adapterName, contextName)

def addMappingContext(mappingContextId, contextName='default'):
  handler.addMappingContext(mappingContextId, contextName)

def deleteMappingContext(mappingContextId, contextName='default'):
  handler.deleteMappingContext(mappingContextId, contextName)

def listAllMappingContextIds(contextName='default'):
  handler.listAllMappingContextIds(contextName)

def addDomainRule(srcDomain, destDomain, domainConstructRule, mappingContextId, contextName='default'):
  handler.addDomainRule(srcDomain, destDomain, domainConstructRule, mappingContextId, contextName)

def addAttributeRule(srcAttrs, srcObjectClass, srcAttrType, dstAttr, dstObjectClass, dstAttrType, mappingExpression, direction, mappingContextId, contextName='default'):
  handler.addAttributeRule(srcAttrs, srcObjectClass, srcAttrType, dstAttr, dstObjectClass, dstAttrType, mappingExpression, direction, mappingContextId, contextName)

def deleteDomainRule(srcDomain, destDomain, mappingContextId, contextName='default'):
  handler.deleteDomainRule(srcDomain, destDomain, mappingContextId, contextName)

def deleteAttributeRule(srcAttrs, dstAttr, mappingContextId, contextName='default'):
  handler.deleteAttributeRule(srcAttrs, dstAttr, mappingContextId, contextName)

def addDomainExclusionRule(domain, mappingContextId, contextName='default'):
  handler.addDomainExclusionRule(domain,mappingContextId, contextName)

def addAttributeExclusionRule(attribute, mappingContextId, contextName='default'):
  handler.addAttributeExclusionRule(attribute, mappingContextId, contextName)

def deleteDomainExclusionRule(domain,mappingContextId,  contextName='default'):
  handler.deleteDomainExclusionRule(domain, mappingContextId, contextName)

def deleteAttributeExclusionRule(attribute, mappingContextId, contextName='default'):
  handler.deleteAttributeExclusionRule(attribute, mappingContextId, contextName)

def listAttributeRules(mappingContextId, contextName='default'):
  handler.listAttributeRules(mappingContextId, contextName)

def listDomainRules(mappingContextId, contextName='default'):
  handler.listDomainRules(mappingContextId, contextName)


def activateLibOVDConfigChanges(contextName='default'):
  handler.activateLibOVDConfigChanges(contextName)


#internal commands
def help(topic = None):
  m_name = 'OracleLibOVDConfig'
  if topic == None:
    topic = m_name
  else:
    topic = m_name + '.' + topic
  return OracleHelp.help(topic)


  
