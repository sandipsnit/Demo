################################################################
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

try:
    _oc = System.getProperty('COMMON_COMPONENTS_HOME')
    if _oc is not None:
        _sh = os.path.join(_oc, os.path.join('common', 'script_handlers'))
        if _sh not in sys.path:
            sys.path.append(_sh)
except:
    print "" #ignore the exception

import Opss_handler as handler
from java.util import HashMap
from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
from oracle.security.jps import WlstResources
from java.util import ResourceBundle
from java.util import Locale
import ora_mbs


############################################
# This function exports policies to XACML 
############################################
def migratePoliciesToXacml(src=None, dst=None, srcApp=None, dstApp=None, configFile=None) :
    import wlstModule
    m = HashMap()
    m.put("src",src)
    m.put("dst",dst)
    m.put("srcApp",srcApp)
    m.put("dstApp",dstApp)
    m.put("configFile",configFile)
    handler.migratePoliciesToXacmlImpl(m)

#######################################################
# This function create the administration role
#######################################################

def createAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, displayName=None, description=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("displayName", displayName)
    m.put("description",description)
    wlstModule.domainRuntime()
    handler.createAdminRoleImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)


#######################################################
# This function delete admin role
#######################################################

def deleteAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    wlstModule.domainRuntime()
    handler.deleteAdminRoleImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)


#######################################################
# This function lists admin roles
#######################################################

def listAdminRoles(appStripe=None, policyDomainName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    wlstModule.domainRuntime()
    handler.listAdminRoles(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)


#########################################################################
# This function lists the principals granted to this administration role
#########################################################################

def  listAdminRoleMembers(appStripe=None, policyDomainName=None, adminRoleName=None) :
     import wlstModule
     m = HashMap()
     m.put("appStripe",appStripe)
     m.put("policyDomainName", policyDomainName)
     m.put("adminRoleName", adminRoleName)
     wlstModule.domainRuntime()
     handler.listAdminRoleMembers(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)




#################################################################
# This function grants an admin role rights to a given principal.
#################################################################

def grantAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, principalClass=None, principalName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    wlstModule.domainRuntime()
    handler.grantAdminRole(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)




###################################################################
# This function revokes an Admin Role rights from a given principal
###################################################################

def revokeAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, principalClass=None, principalName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    wlstModule.domainRuntime()
    handler.revokeAdminRole(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)




#######################################################################
# This function grants administrative resource actions to an admin role
#######################################################################

def grantAdminResource(appStripe=None, policyDomainName=None, adminRoleName=None, adminResource=None, action=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("adminResource", adminResource)
    m.put("action", action)
    wlstModule.domainRuntime()
    handler.grantAdminResource(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)





#########################################################################
# This function revokes administrative resource actions to an admin role
#########################################################################

def revokeAdminResource(appStripe=None, policyDomainName=None, adminRoleName=None, adminResource=None, action=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("adminResource", adminResource)
    m.put("action", action)
    wlstModule.domainRuntime()
    handler.revokeAdminResource(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)



############################################################################
# This function lists the administrative resource actions for an admin role
############################################################################

def listAdminResources(appStripe=None, policyDomainName=None, adminRoleName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    wlstModule.domainRuntime()
    handler.listAdminResources(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)




############################################
# This function creates Resource
############################################
def createResource(appStripe=None, name=None, type=None, displayName=None, description=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("type",type)
    m.put("displayName",displayName)
    m.put("description",description)
    wlstModule.domainRuntime()
    handler.createResourceImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function prints the resource
############################################
def getResource(appStripe=None, name=None, type=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("type",type)
    wlstModule.domainRuntime()
    handler.getResourceImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function deletes the resource
#############################################
def deleteResource(appStripe=None, name=None, type=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("type",type)
    wlstModule.domainRuntime()
    handler.deleteResourceImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function lists the resources
#############################################
def listResources(appStripe=None, type=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("type",type)
    wlstModule.domainRuntime()
    handler.listResourcesImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function lists the resource actions
#############################################
def listResourceActions(appStripe=None, entitlementName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("entitlementName",entitlementName)
    wlstModule.domainRuntime()
    handler.listResourceActionsImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function updates the resource
############################################
def updateResource(appStripe=None, resourceName=None, type=None, displayName=None, description=None, attributes=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceName",resourceName)
    m.put("type",type)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("attributes",attributes)
    wlstModule.domainRuntime()
    handler.updateResourceImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function lists the resource types
#############################################
def listResourceTypes(appStripe=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    wlstModule.domainRuntime()
    handler.listResourceTypesImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function creates Permission Set
############################################
def createEntitlement(appStripe=None, name=None, resourceName=None, resourceType=None, actions=None, displayName=None, description=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("resourceName",resourceName)
    m.put("resourceType",resourceType)
    m.put("actions",actions)
    m.put("displayName",displayName)
    m.put("description",description)
    wlstModule.domainRuntime()
    handler.createEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function prints the permission set
############################################
def getEntitlement(appStripe=None, name=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    wlstModule.domainRuntime()
    handler.getEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function deletes the permission set
#############################################
def deleteEntitlement(appStripe=None, name=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    wlstModule.domainRuntime()
    handler.deleteEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

####################################################
# This function adds a member to the permission set
####################################################
def addResourceToEntitlement(appStripe=None, name=None, resourceName=None, resourceType=None, actions=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("resourceName",resourceName)
    m.put("resourceType",resourceType)
    m.put("actions",actions)
    wlstModule.domainRuntime()
    handler.addResourceToEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

########################################################
# This function revokes a member from the permission set
########################################################
def revokeResourceFromEntitlement(appStripe=None, name=None, resourceName=None, resourceType=None, actions=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("resourceName",resourceName)
    m.put("resourceType",resourceType)
    m.put("actions",actions)
    wlstModule.domainRuntime()
    handler.revokeResourceFromEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function lists all permission sets
#############################################
def listEntitlements(appStripe=None, resourceTypeName=None, resourceName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    m.put("resourceName",resourceName)
    wlstModule.domainRuntime()
    handler.listEntitlementsImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

######################################################
# This function grants a permission set to a principal
######################################################
def grantEntitlement(appStripe=None, principalName=None, principalClass=None, entitlementName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("principalName",principalName)
    m.put("principalClass",principalClass)
    m.put("entitlementName",entitlementName)
    wlstModule.domainRuntime()
    handler.grantEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

######################################################
# This function revokes a permission set from a principal
######################################################
def revokeEntitlement(appStripe=None, principalName=None, principalClass=None, entitlementName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("principalName",principalName)
    m.put("principalClass",principalClass)
    m.put("entitlementName",entitlementName)
    wlstModule.domainRuntime()
    handler.revokeEntitlementImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

#############################################
# This function lists all the app stripes
#############################################
def listAppStripes(configFile=None, regularExpression=None):
    import wlstModule
    m = HashMap()
    m.put("configFile",configFile)
    m.put("regularExpression",regularExpression)
    if (configFile is None):
      wlstModule.domainRuntime()
      m.put("connected", "true")
    handler.listAppStripesImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function creates custom function
############################################
def createFunction (appStripe=None, functionName=None, displayName=None, description=None, className=None, returnType=None, paramTypes=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    m.put("className",className)
    m.put("returnType",returnType)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("paramTypes", paramTypes)
    wlstModule.domainRuntime()
    handler.createFunctionImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function prints the custom function
############################################
def getFunction (appStripe=None, functionName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    wlstModule.domainRuntime()
    handler.getFunctionImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function lists the custom functions
############################################
def listFunctions (appStripe=None, hideBuiltIn=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    if (hideBuiltIn is None):
      m.put("hideBuiltIn", "true")
    else:
      m.put("hideBuiltIn",hideBuiltIn)
    wlstModule.domainRuntime()
    handler.listFunctionsImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function deletes the custom function
############################################
def deleteFunction (appStripe=None, functionName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    wlstModule.domainRuntime()
    handler.deleteFunctionImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function updates the custom function
############################################
def updateFunction (appStripe=None, functionName=None, displayName=None, description=None, className=None, returnType=None, paramTypes=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    m.put("className",className)
    m.put("returnType",returnType)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("paramTypes", paramTypes)
    wlstModule.domainRuntime()
    handler.updateFunctionImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function creates attribute
############################################
def createAttribute (appStripe=None, attributeName=None, displayName=None, description=None, type=None, category=None, isSingle=None, values=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("attributeName",attributeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("type", type)
    m.put("category", category)
    if (isSingle is None):
      m.put("isSingle", "true")
    else:
      m.put("isSingle",isSingle)
    m.put("values", values)
    wlstModule.domainRuntime()
    handler.createAttributeImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function updates the attribute
############################################
def updateAttribute (appStripe=None, attributeName=None, displayName=None, description=None, values=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("attributeName",attributeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("values", values)
    wlstModule.domainRuntime()
    handler.updateAttributeImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function deletes the attribute
############################################
def deleteAttribute (appStripe=None, attributeName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("attributeName",attributeName)
    wlstModule.domainRuntime()
    handler.deleteAttributeImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function lists the attributes
############################################
def listAttributes (appStripe=None, hideBuiltIn=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    if (hideBuiltIn is None):
      m.put("hideBuiltIn", "true")
    else:
      m.put("hideBuiltIn",hideBuiltIn)
    wlstModule.domainRuntime()
    handler.listAttributesImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function updates the resource type
############################################
def updateResourceType (appStripe=None, resourceTypeName=None, displayName=None, description=None, allowedActions=None, delimiter=None, attributes=None, provider=None, matcher=None, hierarchicalResource=None, resourceNameDelimiter=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("allowedActions", allowedActions)
    m.put("delimiter",delimiter)
    m.put("attributes",attributes)
    m.put("provider",provider)
    m.put("matcher",matcher)
    m.put("hierarchicalResource", hierarchicalResource)
    m.put("resourceNameDelimiter",resourceNameDelimiter)
    wlstModule.domainRuntime()
    handler.updateResourceTypeImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function creates application policy
############################################
def createApplicationPolicy (appStripe=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    wlstModule.domainRuntime()
    handler.createApplicationPolicyImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function creates policy
############################################
def createPolicy (appStripe=None, policyName=None, displayName=None, description=None, ruleExpression=None, entitlements=None, resourceActions=None, principals=None, codeSource=None, obligations=None, semantic=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyName",policyName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("ruleExpression", ruleExpression)
    m.put("entitlements",entitlements)
    m.put("resourceActions",resourceActions)
    m.put("principals",principals)
    m.put("codeSource", codeSource)
    m.put("obligations", obligations)
    m.put("semantic",semantic)
    wlstModule.domainRuntime()
    handler.createPolicyImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function updates the policy
############################################
def updatePolicy (appStripe=None, policyName=None, displayName=None, description=None, ruleExpression=None, entitlements=None, resourceActions=None, principals=None, codeSource=None, obligations=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyName",policyName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("ruleExpression", ruleExpression)
    m.put("entitlements",entitlements)
    m.put("resourceActions",resourceActions)
    m.put("principals",principals)
    m.put("codeSource", codeSource)
    m.put("obligations", obligations)
    wlstModule.domainRuntime()
    handler.updatePolicyImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function deletes the policy
############################################
def deletePolicy (appStripe=None, policyName=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyName",policyName)
    wlstModule.domainRuntime()
    handler.deletePolicyImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################
# This function lists the policies
############################################
def listPolicies (appStripe=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    wlstModule.domainRuntime()
    handler.listPoliciesImpl(m,JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    

###########################################################
# This function lists permissions granted to a code source
###########################################################
def listCodeSourcePermissions(appStripe=None, codeBaseURL=None) :
    import wlstModule
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("codeBaseURL",codeBaseURL)
    wlstModule.domainRuntime()
    handler.listCodeSourcePermissionsImpl(m, JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE, JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

############################################################
# This function Exports encryption key from bootstrap cs
############################################################
def exportEncryptionKey(jpsConfigFile=None, keyFilePath=None, keyFilePassword=None):
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("keyFilePath", keyFilePath)
    m.put("keyFilePassword", keyFilePassword)
    handler.exportEncryptionKeyImpl(m)
############################################################
# This function Imports encryption key to bootstrap cs
############################################################
def importEncryptionKey(jpsConfigFile=None, keyFilePath=None, keyFilePassword=None):
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("keyFilePath", keyFilePath)
    m.put("keyFilePassword", keyFilePassword)
    handler.importEncryptionKeyImpl(m)
############################################################
# This function Imports encryption key to bootstrap cs
############################################################
def restoreEncryptionKey(jpsConfigFile=None):
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    handler.restoreEncryptionKeyImpl(m)

############################################################
# This function updates trust service provider configuration
############################################################
def updateTrustServiceConfig (providerName=None, propsFile=None) :
    import wlstModule
    m = HashMap()
    m.put("providerName", providerName)
    m.put("propsFile", propsFile)
    wlstModule.domainRuntime()
    handler.updateTrustServiceConfigImpl(m, JpsJmxConstants.MBEAN_JPS_CONFIG_FUNCTIONAL) 

##################################################
# This function rolls over the OPSS encryption key
##################################################
def rollOverEncryptionKey (jpsConfigFile=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    handler.rollOverEncryptionKeyImpl(m)

############################################
# This function lists security store type, location and user-name
############################################
def listSecurityStoreInfo(domainConfig=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("domainConfig", domainConfig)
    handler.listSecurityStoreInfoImpl(m)
