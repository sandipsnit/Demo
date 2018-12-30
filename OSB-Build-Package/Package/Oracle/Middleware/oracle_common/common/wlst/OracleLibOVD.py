"""
 Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

Caution: This file is part of the command scripting implementation. Do not edit
or move this file because this may cause commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your scripts to fail when you upgrade to a different version
"""

try:
  _oc = System.getProperty('COMMON_COMPONENTS_HOME')
  if _oc is not None:
    _sh = os.path.join(_oc, os.path.join('common', 'script_handlers'))
    if _sh not in sys.path:
      sys.path.append(_sh)
except:
  print "" #ignore the exception

import OracleLibOVD_handler as libovdhandler

def createLDAPAdapter(adapterName, root, host, port, remoteBase, isSecure=0, bindDN='', bindPasswd='', passCred='Always', contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.createLDAPAdapter(adapterName, root, host, port, remoteBase, isSecure, bindDN, bindPasswd, passCred, contextName)

def createJoinAdapter(adapterName, root, primaryAdapter, bindAdapter=None, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.createJoinAdapter(adapterName, root, primaryAdapter, bindAdapter, contextName)

def deleteAdapter(adapterName, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.deleteAdapter(adapterName, contextName)

def modifyLDAPAdapter(adapterName, attribute, value, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.modifyLDAPAdapter(adapterName, attribute, value, contextName)

def addLDAPHost(adapterName, host, port, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addLDAPHost(adapterName, host, port, contextName)

def removeLDAPHost(adapterName, host, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.removeLDAPHost(adapterName, host, contextName)

def addJoinRule(adapterName, secondary, condition, joinerType='Simple', contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addJoinRule(adapterName, secondary, condition, joinerType, contextName)

def removeJoinRule(adapterName, secondary, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.removeJoinRule(adapterName, secondary, contextName)

def addPlugin(pluginName, pluginClass, paramKeys, paramValues, adapterName='GlobalPlugin', contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addPlugin(pluginName, pluginClass, paramKeys, paramValues, adapterName, contextName)

def removePlugin(pluginName, adapterName='GlobalPlugin', contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.removePlugin(pluginName, adapterName, contextName)
  
def addPluginParam(pluginName, paramKeys, paramValues, adapterName='GlobalPlugin', contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addPluginParam(pluginName, paramKeys, paramValues, adapterName, contextName)

def removePluginParam(pluginName, paramKey, adapterName='GlobalPlugin', contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.removePluginParam(pluginName, paramKey, adapterName, contextName)

def listAdapters(contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.listAdapters(contextName)

def getAdapterDetails(adapterName, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.getAdapterDetails(adapterName, contextName)

def addMappingContext(mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addMappingContext(mappingContextId, contextName)

def deleteMappingContext(mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.deleteMappingContext(mappingContextId, contextName)

def listAllMappingContextIds(contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.listAllMappingContextIds(contextName)

def addDomainRule(srcDomain, destDomain, domainConstructRule, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addDomainRule(srcDomain, destDomain, domainConstructRule, mappingContextId, contextName)

def addAttributeRule(srcAttrs, srcObjectClass, srcAttrType, dstAttr, dstObjectClass, dstAttrType, mappingExpression, direction, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addAttributeRule(srcAttrs, srcObjectClass, srcAttrType, dstAttr, dstObjectClass, dstAttrType, mappingExpression, direction, mappingContextId, contextName)

def deleteDomainRule(srcDomain, destDomain, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.deleteDomainRule(srcDomain, destDomain, mappingContextId, contextName)

def deleteAttributeRule(srcAttrs, dstAttr, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.deleteAttributeRule(srcAttrs, dstAttr, mappingContextId, contextName)

def addDomainExclusionRule(domain, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addDomainExclusionRule(domain,mappingContextId, contextName)

def addAttributeExclusionRule(attribute, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.addAttributeExclusionRule(attribute, mappingContextId, contextName)

def deleteDomainExclusionRule(domain,mappingContextId,  contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.deleteDomainExclusionRule(domain, mappingContextId, contextName)

def deleteAttributeExclusionRule(attribute, mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.deleteAttributeExclusionRule(attribute, mappingContextId, contextName)

def listAttributeRules(mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.listAttributeRules(mappingContextId, contextName)

def listDomainRules(mappingContextId, contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.listDomainRules(mappingContextId, contextName)


def activateLibOVDConfigChanges(contextName='default'):
  libOVD_gotoDomainRuntime()
  libovdhandler.activateLibOVDConfigChanges(contextName)

#internal commands

def addLibOVDCommandHelp():
  libovdhandler.addLibOVDCommandHelp();

def libOVD_gotoDomainRuntime():
  currentNode = pwd()
  if (currentNode.find('domainRuntime') == -1):
    ctree = currentTree()
    domainRuntime()
    ora_mbs.setMbs(mbs)
    return ctree
  else:
    return None

addLibOVDCommandHelp()
  
