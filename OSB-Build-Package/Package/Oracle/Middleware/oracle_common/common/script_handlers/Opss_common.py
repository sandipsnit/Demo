################################################################
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

from java.lang import Exception
from java.util import HashMap
from java.util import ResourceBundle
from java.util import Locale

from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
from oracle.security.jps import WlstResources

import ora_util
import ora_mbs
import Opss_handler


#######################################################
# This function adds command help
# (Internal function)
#######################################################

def addOpssCommandHelp() :
    try :
        Opss_handler.addOpssCommandHelp()
    except Exception, e :
        ora_util.raiseScriptingException(e)

opss_resourceBundle = ResourceBundle.getBundle("oracle.security.jps.WlstResources", Locale.getDefault(), WlstResources.getClassLoader())

#workaround for bug9697953, for the final approach, we filed bug 9704933
def getCompleteMBeanName(objname):
    if(ora_mbs.isJBoss()):
        on = objname
    elif(ora_mbs.isWebSphereND() == 1):
        on = AdminControl.completeObjectName(objname+',process=dmgr,*')
    elif(ora_mbs.isWebSphereAS() == 1):
        on = AdminControl.completeObjectName(objname+',*')
    else:
        on = objname
    return on
#######################################################
# This function create the administration role
#######################################################

def createAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, displayName=None, description=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("displayName", displayName)
    m.put("description",description)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.createAdminRoleImpl(m,on)


#######################################################
# This function delete admin role
#######################################################

def deleteAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.deleteAdminRole(m,on)


#######################################################
# This function lists admin roles
#######################################################

def listAdminRoles(appStripe=None, policyDomainName=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.listAdminRoles(m,on)


#########################################################################
# This function lists the principals granted to this administration role
#########################################################################

def  listAdminRoleMembers(appStripe=None, policyDomainName=None, adminRoleName=None) :
     m = HashMap()
     m.put("appStripe", appStripe)
     m.put("policyDomainName", policyDomainName)
     m.put("adminRoleName", adminRoleName)
     on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
     Opss_handler.listAdminRoleMembers(m,on)

#################################################################
# This function grants an admin role rights to a given principal.
#################################################################

def grantAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, principalClass=None, principalName=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.grantAdminRole(m,on)


###################################################################
# This function revokes an Admin Role rights from a given principal
###################################################################

def revokeAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, principalClass=None, principalName=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.revokeAdminRole(m,on)


#######################################################################
# This function grants administrative resource actions to an admin role
#######################################################################

def grantAdminResource(appStripe=None, policyDomainName=None, adminRoleName=None, adminResource=None, action=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("adminResource", adminResource)
    m.put("action", action)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.grantAdminResource(m,on)



#########################################################################
# This function revokes administrative resource actions to an admin role
#########################################################################

def revokeAdminResource(appStripe=None, policyDomainName=None, adminRoleName=None, adminResource=None, action=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("adminResource", adminResource)
    m.put("action", action)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.revokeAdminResource(m,on)




############################################################################
# This function lists the administrative resource actions for an admin role
############################################################################

def listAdminResources(appStripe=None, policyDomainName=None, adminRoleName=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    on = getCompleteMBeanName(JpsJmxConstans.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.listAdminResources(m,on)




#######################################################
# This function list the credentials
#######################################################

def listCred(map=None, key=None) :
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
    try :
        Opss_handler.listCredImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

############################################
# This function creates Resource
############################################
def createResource(appStripe=None, name=None, type=None, displayName=None, description=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("type",type)
    m.put("displayName",displayName)
    m.put("description",description)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.createResourceImpl(m,on)

############################################
# This function prints the resource
############################################
def getResource(appStripe=None, name=None, type=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("type",type)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.getResourceImpl(m,on)

#############################################
# This function deletes the resource
#############################################
def deleteResource(appStripe=None, name=None, type=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("type",type)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.deleteResourceImpl(m,on)

#############################################
# This function lists the resources
#############################################
def listResources(appStripe=None, type=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("type",type)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.listResourcesImpl(m,on)

#############################################
# This function lists the resource actions
#############################################
def listResourceActions(appStripe=None, entitlementName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("entitlementName",entitlementName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.listResourceActionsImpl(m,on)

#############################################
# This function lists the resource types
#############################################
def listResourceTypes(appStripe=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.listResourceTypesImpl(m,on)

############################################
# This function creates Permission Set
############################################
def createEntitlement(appStripe=None, name=None, resourceName=None, resourceType=None, actions=None, displayName=None, description=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("resourceName",resourceName)
    m.put("resourceType",resourceType)
    m.put("actions",actions)
    m.put("displayName",displayName)
    m.put("description",description)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.createEntitlementImpl(m,on)

############################################
# This function prints the permission set
############################################
def getEntitlement(appStripe=None, name=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.getEntitlementImpl(m,on)

#############################################
# This function deletes the permission set
#############################################
def deleteEntitlement(appStripe=None, name=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.deleteEntitlementImpl(m,on)

####################################################
# This function adds a member to the permission set
####################################################
def addResourceToEntitlement(appStripe=None, name=None, resourceName=None, resourceType=None, actions=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("resourceName",resourceName)
    m.put("resourceType",resourceType)
    m.put("actions",actions)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.addResourceToEntitlementImpl(m,on)

########################################################
# This function revokes a member from the permission set
########################################################
def revokeResourceFromEntitlement(appStripe=None, name=None, resourceName=None, resourceType=None, actions=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("name",name)
    m.put("resourceName",resourceName)
    m.put("resourceType",resourceType)
    m.put("actions",actions)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.revokeResourceFromEntitlementImpl(m,on)

#############################################
# This function lists all permission sets
#############################################
def listEntitlements(appStripe=None, resourceTypeName=None, resourceName=None, principalName=None, principalClass=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    m.put("resourceName",resourceName)
    m.put("principalName",principalName)
    m.put("principalClass",principalClass)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.listEntitlementsImpl(m,on)

######################################################
# This function grants a permission set to a principal
######################################################
def grantEntitlement(appStripe=None, principalName=None, principalClass=None, entitlementName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("principalName",principalName)
    m.put("principalClass",principalClass)
    m.put("entitlementName",entitlementName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.grantEntitlementImpl(m,on)

######################################################
# This function revokes a permission set from a principal
######################################################
def revokeEntitlement(appStripe=None, principalName=None, principalClass=None, entitlementName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("principalName",principalName)
    m.put("principalClass",principalClass)
    m.put("entitlementName",entitlementName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    Opss_handler.revokeEntitlementImpl(m,on)

#######################################################
# This function creates ResourceType
#######################################################
def createResourceType(appStripe=None, resourceTypeName=None, displayName=None, description=None, provider=None, matcher=None, allowedActions=None, delimiter=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("provider",provider)
    m.put("matcher",matcher)
    m.put("allowedActions",allowedActions)
    m.put("delimiter",delimiter)    
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :    
        Opss_handler.createResourceTypeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function prints ResourceType
#######################################################
def getResourceType(appStripe=None, resourceTypeName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)    
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.getResourceTypeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function deletes ResourceType
#######################################################
def deleteResourceType(appStripe=None, resourceTypeName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)    
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try : 
        Opss_handler.deleteResourceTypeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#############################################
# This function lists all the app stripes
#############################################
def listAppStripes(configFile=None, regularExpression=None):
    m = HashMap()
    m.put("configFile",configFile)
    m.put("regularExpression",regularExpression)
    on = None
    # If a configFile is provided, use that, otherwise connect to the server.
    if (configFile is None):
      m.put("connected", "true")
      on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
      Opss_handler.listAppStripesImpl(m,on)
    except Exception, e :
      ora_util.raiseScriptingException(e)

#######################################################
# This function list the approles
#######################################################

def listAppRoles(appStripe=None) :   
    m = HashMap()
    m.put("appStripe", appStripe)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listAppRolesImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function list the approle members
#######################################################

def listAppRoleMembers(appStripe=None, appRoleName=None) :   
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listAppRoleMembersImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)


############################################################
# This function list the permissions granted to a principal
############################################################

def listPermissions(appStripe=None, principalClass=None, principalName=None) :    
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
    obn = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listPermissionsImpl(m,on,obn)
    except Exception, e :
        ora_util.raiseScriptingException(e)

##############################################################
# This function list the permissions granted to a code source
##############################################################

def listCodeSourcePermissions(appStripe=None, codeBaseURL=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("codeBaseURL", codeBaseURL)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
    obn = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listCodeSourcePermissionsImpl(m,on,obn)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function creates an approle
#######################################################

def createAppRole(appStripe=None, appRoleName=None) :   
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.createAppRoleImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function creates a credential
#######################################################

def createCred(map=None, key=None, user=None, password=None, desc=None) :   
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    m.put("user", user)
    m.put("password", password)
    m.put("desc", desc)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
    try :
        Opss_handler.createCredImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function deletes an app policy
#######################################################

def deleteAppPolicies(appStripe=None) :  
    m = HashMap()
    m.put("appStripe", appStripe)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.deleteAppPoliciesImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function deletes an approle
#######################################################

def deleteAppRole(appStripe=None, appRoleName=None) :    
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.deleteAppRolesImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function deletes a credential
#######################################################

def deleteCred(map=None, key=None) :    
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
    try :
        Opss_handler.deleteCredImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function grants an approle
#######################################################

def grantAppRole(appStripe=None, appRoleName=None, principalClass=None, principalName=None) :   
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.grantAppRoleImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function grants a permission
#######################################################

def grantPermission(appStripe=None, principalClass=None, principalName=None, codeBaseURL=None, permClass=None, permTarget=None, permActions=None) :    
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    m.put("codeBaseURL", codeBaseURL)
    m.put("permClass", permClass)
    m.put("permTarget", permTarget)
    m.put("permActions", permActions)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
    obn = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.grantPermissionImpl(m,on,obn)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function revokes an approle
#######################################################

def revokeAppRole(appStripe=None, appRoleName=None, principalClass=None, principalName=None) :    
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.revokeAppRoleImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function revokes a permission
#######################################################

def revokePermission(appStripe=None, principalClass=None, principalName=None, codeBaseURL=None, permClass=None, permTarget=None, permActions=None ) :   
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    m.put("permClass", permClass)
    m.put("permTarget", permTarget)
    m.put("permActions", permActions)
    m.put("codeBaseURL", codeBaseURL)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
    obn = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.revokePermissionImpl(m,on,obn)
    except Exception, e :
        ora_util.raiseScriptingException(e) 

#######################################################
# This function updates a credential
#######################################################

def updateCred(map=None, key=None, user=None, password=None, desc=None) :    
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    m.put("user", user)
    m.put("password", password)
    m.put("desc", desc)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
    try :
        Opss_handler.updateCredImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function migrates the policies istore/global/apppolicy/policystore
###########################################################################

def migrateSecurityStore(type=None, src=None, dst=None, srcApp=None, dstApp=None, srcFolder=None, dstFolder=None, dstLdifFile=None, srcConfigFile=None, configFile=None, overWrite=None, processPrivRole=None, resourceTypeFile=None, migrateIdStoreMapping=None, preserveAppRoleGuid=None, mode=None, reportFile=None) :   
    m = HashMap()
    m.put("type", type)
    m.put("src", src)
    m.put("dst", dst)
    m.put("srcApp", srcApp)
    m.put("dstApp", dstApp)
    m.put("srcFolder", srcFolder)
    m.put("dstFolder", dstFolder)
    m.put("dstLdifFile", dstLdifFile)
    m.put("srcConfigFile", srcConfigFile)
    m.put("configFile", configFile)
    m.put("processPrivRole", processPrivRole)
    m.put("resourceTypeFile", resourceTypeFile)
    m.put("overWrite", overWrite)     
    m.put("migrateIdStoreMapping", migrateIdStoreMapping)
    m.put("preserveAppRoleGuids", preserveAppRoleGuid)
    m.put("mode",mode)
    m.put("reportFile", reportFile)
    try :
        Opss_handler.migrateSecurityStoreImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function upgraded the policies 
###########################################################################

def upgradeSecurityStore(type=None, srcRealm=None, dst=None, srcJaznConfigFile=None, srcJaznDataFile=None, jpsConfigFile=None, users=None, dstJaznDataFile=None, resourceTypeFile=None, srcApp=None, jpsContext=None) :   
    m = HashMap()
    m.put("type", type)
    m.put("srcRealm", srcRealm)
    m.put("dst", dst)
    m.put("srcJaznConfigFile", srcJaznConfigFile)
    m.put("srcJaznDataFile", srcJaznDataFile)
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("users", users)
    m.put("dstJaznDataFile", dstJaznDataFile)
    m.put("resourceTypeFile", resourceTypeFile)
    m.put("srcApp", srcApp)
    m.put("jpsContext", jpsContext)
    try :
        Opss_handler.upgradeSecurityStoreImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function reassociates
###########################################################################

def reassociateSecurityStore(domain=None, admin=None, password=None,ldapurl=None,servertype=None,jpsroot=None,join=None, datasourcename=None, jdbcurl=None, dbUser=None, dbPassword=None, jdbcdriver=None, odbcdsn=None) :    
    m = HashMap()
    m.put("domain", domain)
    m.put("admin", admin)
    m.put("password", password)
    m.put("ldapurl", ldapurl)
    m.put("servertype", servertype)
    m.put("jpsroot", jpsroot)
    m.put("join", join)
    m.put("datasourcename", datasourcename)
    m.put("jdbcurl", jdbcurl)
    m.put("dbUser", dbUser)
    m.put("dbPassword", dbPassword)
    m.put("jdbcdriver", jdbcdriver)
    m.put("odbcdsn", odbcdsn)

    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CONFIG_FUNCTIONAL)
    try :
        Opss_handler.reassociateSecurityStoreImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function modifies the boot strap credential
###########################################################################

def modifyBootStrapCredential(jpsConfigFile=None,username=None, password=None) :   
    m = HashMap()   
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("username", username)
    m.put("password", password)
    try :
        Opss_handler.modifyBootStrapCredentialImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function adds the boot strap credential
###########################################################################

def addBootStrapCredential(jpsConfigFile=None, map=None, key=None, username=None, password=None) :
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("map", map)
    m.put("key", key)
    m.put("username", username)
    m.put("password", password)
    try :
        Opss_handler.addBootStrapCredentialImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function modifies the boot strap credential
###########################################################################

def patchPolicyStore(phase=None, patchDeltaFolder=None, productionJpsConfig=None, baselineFile=None, patchFile=None, baselineAppStripe=None, productionAppStripe=None, patchAppStripe=None, silent=None, ignoreEnterpriseMembersOfAppRole=None, reportFile=None, ignoreEnterpriseAppRoleMembershipConflicts=None) :
    
    from oracle.security.jps.patch import PatchTool
    from oracle.security.jps.patch import PatchingException 
    m = HashMap()
    m.put(PatchTool.phase, phase)
    m.put(PatchTool.baselineFile, baselineFile)
    m.put(PatchTool.patchFile,patchFile)
    m.put(PatchTool.productionJpsConfig,productionJpsConfig)
    m.put(PatchTool.patchDeltaFolder,patchDeltaFolder)
    m.put(PatchTool.baselineAppStripe,baselineAppStripe)
    m.put(PatchTool.productionAppStripe,productionAppStripe)
    m.put(PatchTool.newlineAppStripe,patchAppStripe)
    m.put(PatchTool.silent,silent)
    m.put(PatchTool.ignoreEnterpriseMembersOfAppRole,ignoreEnterpriseMembersOfAppRole)
    m.put(PatchTool.reportFile, reportFile)
    m.put(PatchTool.ignoreEnterpriseAppRoleMembershipConflicts,ignoreEnterpriseAppRoleMembershipConflicts)
    try :
        return Opss_handler.patchPolicyStoreImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# This function configures identity store in default jps context
###########################################################################

def configIdStoreInternal(props=None) :
    import jarray
    from java.lang import Object
    from java.lang import String
    from java.util import ArrayList
    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap
    from oracle.security.jps.mas.mgmt.jmx.config import JpsConfigMBeanConstants
    
    args= ArrayList()

    ldapHost = props.remove(JpsConfigMBeanConstants.LDAP_HOST)    
    if (ldapHost is None) :
        args.add(JpsConfigMBeanConstants.LDAP_HOST)

    ldapPort = props.remove(JpsConfigMBeanConstants.LDAP_PORT)    
    if (ldapPort is None) :
        args.add(JpsConfigMBeanConstants.LDAP_PORT) 

    groupSearchBaseStr = props.remove(JpsConfigMBeanConstants.GROUP_SEARCH_BASES)
    if (groupSearchBaseStr is None) :
        args.add(JpsConfigMBeanConstants.GROUP_SEARCH_BASES)

    userSearchBaseStr = props.remove(JpsConfigMBeanConstants.USER_SEARCH_BASES)
    if (userSearchBaseStr is None) :
        args.add(JpsConfigMBeanConstants.USER_SEARCH_BASES)

    adminId = props.remove(JpsConfigMBeanConstants.ADMIN_ID)
    if (adminId is None) :
        args.add(JpsConfigMBeanConstants.ADMIN_ID)

    pwd = props.remove(JpsConfigMBeanConstants.ADMIN_PASS)
    if (pwd is None) :
        args.add(JpsConfigMBeanConstants.ADMIN_PASS)
  
    subscriberName = props.remove(JpsConfigMBeanConstants.SUBSCRIBER_NAME)

    ldapType = props.remove(JpsConfigMBeanConstants.LDAP_IDSTORE_TYPE)
    if (ldapType is None) :
        args.add(JpsConfigMBeanConstants.LDAP_IDSTORE_TYPE)

    argsarr=None
    for i in range(len(args)) :
        if(argsarr is None ) :
            argsarr = args[i]
        else :
            argsarr = argsarr + "," + args[i]

    if (len(args) > 0 ) :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_REQUIRED_ARG_MISSING)
        raise Exception, msg+str(argsarr)

    groupSearchBase = jarray.array([groupSearchBaseStr], String)
    arrPassword = jarray.array(pwd,'c')
    userSearchBase =  jarray.array ([userSearchBaseStr], String)

    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CONFIG_FUNCTIONAL)
    # remove 'ssl' from props as we don't want it to be in the ldap id store attributes.
    ssl = props.remove(JpsConfigMBeanConstants.SSL_LDAP)
    protocol = 'ldap://'
    if (ssl is not None and ssl.lower() == "true") :
        protocol = 'ldaps://'

    ldapUrl = str(protocol)+str(ldapHost)+':'+str(ldapPort)

    print 'ldapUrl: ' + str(ldapUrl)
    print 'adminId: ' + str(adminId)
    #Default dont check for ldap service instance. Only if the flag is set and the value is true do the check   
    checkLdapInst = props.remove(JpsConfigMBeanConstants.CHECK_LDAP_INSTANCE) 
    if (checkLdapInst is None ) :
      checkLdapInst = "false"

    mp = PortableMap(props).toCompositeData(None)
    try :
        Opss_handler.configureIdentityStoreImpl(on,ldapUrl,adminId,arrPassword,ldapType,subscriberName,userSearchBase,groupSearchBase,mp,checkLdapInst)
    except Exception, e :
        ora_util.raiseScriptingException(e)



def configureIdentityStore(propsFileLoc=None) :
    from java.util import Properties
    from java.io import File
    from java.io import FileInputStream

    if (propsFileLoc is None) :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_EMPTY_PROP_FILE)
        print msg 
        raise Exception, msg 
        
    props = Properties()
    props.load(FileInputStream(File(propsFileLoc)))
    configIdStoreInternal(props)

###########################################################################
# this function rolls over the OPSS encryption key 
###########################################################################

def rollOverEncryptionKey(jpsConfigFile=None) :
    m = HashMap()
    m.put("jpsConfigFile",jpsConfigFile)
    try :
        Opss_handler.rollOverEncryptionKeyImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# this function lists all keystores
###########################################################################

def listKeyStores(appStripe=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.listKeyStoresImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# this function creates a keystore 
###########################################################################

def createKeyStore(appStripe=None, name=None, password=None, permission=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("permission", permission)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.createKeyStoreImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
# this function deletes a keystore 
###########################################################################

def deleteKeyStore(appStripe=None, name=None, password=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.deleteKeyStoreImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function changes keystore password
###########################################################################

def changeKeyStorePassword(appStripe=None, name=None, currentpassword=None, newpassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("currentpassword", currentpassword)
    m.put("newpassword", newpassword)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.changeKeyStorePasswordImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function generates a key pair
###########################################################################

def generateKeyPair(appStripe=None, name=None, password=None, dn=None, keysize=None, alias=None, keypassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("dn", dn)
    m.put("keysize", keysize)
    m.put("alias", alias)
    m.put("keypassword", keypassword)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.generateKeyPairImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function generates a secret key
###########################################################################

def generateSecretKey(appStripe=None, name=None, password=None, algorithm=None, keysize=None, alias=None, keypassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("algorithm", algorithm)
    m.put("keysize", keysize)
    m.put("alias", alias)
    m.put("keypassword", keypassword)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.generateSecretKeyImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function lists keystore aliases 
###########################################################################

def listKeyStoreAliases(appStripe=None, name=None, password=None, type=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("type", type)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.listKeyStoreAliasesImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function changes keystore key password 
###########################################################################

def changeKeyStoreKeyPassword(appStripe=None, name=None, password=None, alias=None, currentkeypassword=None, newkeypassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    m.put("currentkeypassword", currentkeypassword)
    m.put("newkeypassword", newkeypassword)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.changeKeyStoreKeyPasswordImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function gets a keystore certificate 
###########################################################################

def getKeyStoreCertificates(appStripe=None, name=None, password=None, alias=None, keypassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.getKeyStoreCertificatesImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function gets keystore secret key properties 
###########################################################################

def getKeyStoreSecretKeyProperties(appStripe=None, name=None, password=None, alias=None, keypassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    m.put("keypassword", keypassword)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.getKeyStoreSecretKeyPropertiesImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function generates and exports a certificate request 
###########################################################################

def exportKeyStoreCertificateRequest(appStripe=None, name=None, password=None,alias=None, keypassword=None, filepath=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    m.put("keypassword", keypassword)
    m.put("filepath", filepath)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.exportKeyStoreCertificateRequestImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function exports a BASE64 encoded certificate, trusted certificate 
###########################################################################

def exportKeyStoreCertificate(appStripe=None, name=None, password=None,alias=None, keypassword=None, type=None, filepath=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    m.put("type", type)
    m.put("filepath", filepath)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.exportKeyStoreCertificateImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function imports a BASE64 encoded certificate, trusted certificate 
###########################################################################

def importKeyStoreCertificate(appStripe=None, name=None, password=None,alias=None, keypassword=None, type=None, filepath=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    m.put("keypassword", keypassword)
    m.put("type", type)
    m.put("filepath", filepath)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.importKeyStoreCertificateImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function imports a BASE64 encoded certificate, trusted certificate 
###########################################################################

def deleteKeyStoreEntry(appStripe=None, name=None, password=None,alias=None, keypassword=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("alias", alias)
    m.put("keypassword", keypassword)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.deleteKeyStoreEntryImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function lists all expiring certificates and optionally renews them 
###########################################################################

def listExpiringCertificates(days=None, autorenew=None) :
    m = HashMap()
    m.put("days", days)
    m.put("autorenew", autorenew)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.listExpiringCertificatesImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function exports the keystore into file 
###########################################################################

def exportKeyStore(appStripe=None, name=None, password=None,aliases=None, keypasswords=None, type=None, filepath=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("aliases", aliases)
    m.put("keypasswords", keypasswords)
    m.put("type", type)
    m.put("filepath", filepath)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.exportKeyStoreImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################
#  this function imports a keystore from file 
###########################################################################

def importKeyStore(appStripe=None, name=None, password=None,aliases=None, keypasswords=None, type=None, permission=None, filepath=None) :
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("name", name)
    m.put("password", password)
    m.put("aliases", aliases)
    m.put("keypasswords", keypasswords)
    m.put("type", type)
    m.put("permission", permission)
    m.put("filepath", filepath)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
    try :
        Opss_handler.importKeyStoreImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function creates custom function
#######################################################
def createFunction (appStripe=None, functionName=None, displayName=None, description=None, className=None, returnType=None, paramTypes=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    m.put("className",className)
    m.put("returnType",returnType)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("paramTypes", paramTypes)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.createFunctionImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function prints the custom function
#######################################################
def getFunction (appStripe=None, functionName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.getFunctionImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function lists the custom functions
#######################################################
def listFunctions (appStripe=None, hideBuiltIn=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    if (hideBuiltIn is None):
      m.put("hideBuiltIn", "true")
    else:
      m.put("hideBuiltIn",hideBuiltIn)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listFunctionsImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function deletes the custom function
#######################################################
def deleteFunction (appStripe=None, functionName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.deleteFunctionImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function updates the custom function
#######################################################
def updateFunction (appStripe=None, functionName=None, displayName=None, description=None, className=None, returnType=None, paramTypes=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("functionName",functionName)
    m.put("className",className)
    m.put("returnType",returnType)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("paramTypes", paramTypes)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.updateFunctionImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function creates attribute
#######################################################
def createAttribute (appStripe=None, attributeName=None, displayName=None, description=None, type=None, category=None, isSingle=None, values=None) :
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
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.createAttributeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function lists the attributes
#######################################################
def listAttributes (appStripe=None, hideBuiltIn=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    if (hideBuiltIn is None):
      m.put("hideBuiltIn", "true")
    else:
      m.put("hideBuiltIn",hideBuiltIn)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listAttributesImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function deletes the attribute
#######################################################
def deleteAttribute (appStripe=None, attributeName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("attributeName",attributeName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.deleteAttributeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function updates the attribute
#######################################################
def updateAttribute (appStripe=None, attributeName=None, displayName=None, description=None, values=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("attributeName",attributeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("values", values)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.updateAttributeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function updates the resource type
#######################################################
def updateResourceType (appStripe=None, resourceTypeName=None, displayName=None, description=None, allowedActions=None, delimiter=None, attributes=None, provider=None, matcher=None, hierarchicalResource=None, resourceNameDelimiter=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("allowedActions",allowedActions)
    m.put("provider",provider)
    m.put("attributes",attributes)
    m.put("resourceNameDelimiter",resourceNameDelimiter)
    m.put("hierarchicalResource",hierarchicalResource)
    m.put("delimiter",delimiter)
    m.put("matcher",matcher)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.updateResourceTypeImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

#######################################################
# This function updates the resource
#######################################################
def updateResource(appStripe=None, resourceName=None, type=None, displayName=None, description=None, attributes=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceName",resourceName)
    m.put("type",type)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("attributes",attributes)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.updateResourceImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

############################################
# This function creates policy
############################################
def createPolicy (appStripe=None, policyName=None, displayName=None, description=None, ruleExpression=None, entitlements=None, resourceActions=None, principals=None, codeSource=None, obligations=None, semantic=None) :
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
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.createPolicyImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

############################################
# This function updates the policy
############################################
def updatePolicy (appStripe=None, policyName=None, displayName=None, description=None, ruleExpression=None, entitlements=None, resourceActions=None, principals=None, codeSource=None, obligations=None) :
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
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.updatePolicyImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

############################################
# This function lists the policies
############################################
def listPolicies (appStripe=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.listPoliciesImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

############################################
# This function deletes the policy
############################################
def deletePolicy (appStripe=None, policyName=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("policyName",policyName)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.deletePolicyImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

############################################
# This function creates application policy
############################################
def createApplicationPolicy (appStripe=None) :
    m = HashMap()
    m.put("appStripe",appStripe)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
    try :
        Opss_handler.createApplicationPolicyImpl(m,on)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###########################################################################

############################################
# This function migrates policies to XACML
############################################
def migratePoliciesToXacml(src=None, dst=None, srcApp=None, dstApp=None, configFile=None) :
    m = HashMap()
    m.put("src",src)
    m.put("dst",dst)
    m.put("srcApp",srcApp)
    m.put("dstApp",dstApp)
    m.put("configFile",configFile)    
    try :
        Opss_handler.migratePoliciesToXacmlImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)
############################################################
# This function Exports encryption key from bootstrap cs
############################################################
def exportEncryptionKey(jpsConfigFile=None, keyFilePath=None, keyFilePassword=None):
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("keyFilePath", keyFilePath)
    m.put("keyFilePassword", keyFilePassword)
    try :
        Opss_handler.exportEncryptionKeyImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)
############################################################
# This function Imports encryption key to bootstrap cs
############################################################
def importEncryptionKey(jpsConfigFile=None, keyFilePath=None, keyFilePassword=None):
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("keyFilePath", keyFilePath)
    m.put("keyFilePassword", keyFilePassword)
    try :
        Opss_handler.importEncryptionKeyImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)
#########################################################
# This function restores the encryption key
########################################################
def restoreEncryptionKey(jpsConfigFile=None):
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    try :
        Opss_handler.restoreEncryptionKeyImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)
#########################################################

############################################
# This function upgrades the jps-config.xml, policy store and audit store
############################################
def upgradeOpss(jpsConfig=None, jaznData=None, auditStore=None, jdbcDriver=None, url=None, user=None, password=None, upgradeJseStoreType=None):
    m = HashMap()
    m.put("jpsConfig", jpsConfig)
    m.put("jaznData", jaznData)
    m.put("auditStore", auditStore)
    m.put("jdbcDriver", jdbcDriver)
    m.put("url", url)
    m.put("user", user)
    m.put("password",password)
    m.put("upgradeJseStoreType",upgradeJseStoreType)
    try :
        Opss_handler.upgradeOpssImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

###################################################
# This function updates trust service configuration
###################################################
def updateTrustServiceConfig (providerName=None, propsFile=None) :
    m = HashMap()
    m.put("providerName", providerName)
    m.put("propsFile", propsFile)
    on = getCompleteMBeanName(JpsJmxConstants.MBEAN_JPS_CONFIG_FUNCTIONAL)
    try:
        Opss_handler.updateTrustServiceConfigImpl(m, on)
    except Exception, e :
        ora_util.raiseScriptingException(e) 

#######################################################
# This function lists security store type, location and user-name
#######################################################
def listSecurityStoreInfo(domainConfig=None) :
    m = HashMap()
    m.put("domainConfig",domainConfig)
    try :
        Opss_handler.listSecurityStoreInfoImpl(m)
    except Exception, e :
        ora_util.raiseScriptingException(e)

