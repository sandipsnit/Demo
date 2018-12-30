# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################################
# Caution: This file is part of the WLST implementation. Do not edit or move   #
# this file because this may cause WLST commands and scripts to fail. Do not   #
# try to reuse the logic in this file or keep copies of this file because this #
# could cause your WLST scripts to fail when you upgrade to a different version# 
# of WLST.                                                                     #
################################################################################

from java.lang import String
from jarray import zeros
from java.io import File 
from java.io import FileInputStream
from java.util import HashMap
try:
    _oc = System.getProperty('COMMON_COMPONENTS_HOME')
    if _oc is not None:
        _sh = os.path.join(_oc, os.path.join('common', 'script_handlers'))
        if _sh not in sys.path:
            sys.path.append(_sh)

    import wlstModule
    wlstModule.addHelpCommandGroup("opss","jpsWLSTResourceBundle")
    wlstModule.addHelpCommand("listCred","opss",online="true")
    wlstModule.addHelpCommand("createAdminRole","opss",online="true")
    wlstModule.addHelpCommand("deleteAdminRole","opss",online="true")
    wlstModule.addHelpCommand("listAdminRoles","opss",online="true")
    wlstModule.addHelpCommand("listAdminRoleMembers","opss",online="true")
    wlstModule.addHelpCommand("grantAdminRole","opss",online="true")
    wlstModule.addHelpCommand("revokeAdminRole","opss",online="true")
    wlstModule.addHelpCommand("grantAdminResource","opss",online="true")
    wlstModule.addHelpCommand("revokeAdminResource","opss",online="true")
    wlstModule.addHelpCommand("listAdminResources","opss",online="true")
    wlstModule.addHelpCommand("createCred","opss",online="true")
    wlstModule.addHelpCommand("updateCred","opss",online="true")
    wlstModule.addHelpCommand("deleteCred","opss",online="true")
    wlstModule.addHelpCommand("createResourceType","opss",online="true")
    wlstModule.addHelpCommand("getResourceType","opss",online="true")
    wlstModule.addHelpCommand("deleteResourceType","opss",online="true")
    wlstModule.addHelpCommand("listAppRoles","opss",online="true")
    wlstModule.addHelpCommand("createAppRole","opss",online="true")
    wlstModule.addHelpCommand("deleteAppRole","opss",online="true")
    wlstModule.addHelpCommand("listAppRoleMembers","opss",online="true")
    wlstModule.addHelpCommand("grantAppRole","opss",online="true")
    wlstModule.addHelpCommand("revokeAppRole","opss",online="true")
    wlstModule.addHelpCommand("listPermissions","opss",online="true")
    wlstModule.addHelpCommand("listCodeSourcePermissions","opss",online="true")
    wlstModule.addHelpCommand("grantPermission","opss",online="true")
    wlstModule.addHelpCommand("revokePermission","opss",online="true")
    wlstModule.addHelpCommand("deleteAppPolicies","opss",online="true")
    wlstModule.addHelpCommand("migrateSecurityStore","opss",offline="true")
    wlstModule.addHelpCommand("reassociateSecurityStore","opss",online="true")
    wlstModule.addHelpCommand("upgradeSecurityStore", "opss",offline="true")
    wlstModule.addHelpCommand("modifyBootStrapCredential", "opss", offline="true")
    wlstModule.addHelpCommand("importEncryptionKey", "opss", offline="true")
    wlstModule.addHelpCommand("exportEncryptionKey", "opss", offline="true")
    wlstModule.addHelpCommand("restoreEncryptionKey", "opss", offline="true")
    wlstModule.addHelpCommand("patchPolicyStore", "opss", offline="true")
    wlstModule.addHelpCommand("listResourceTypes", "opss", online="true")
    wlstModule.addHelpCommand("getOpssService", "opss", online="true")
    wlstModule.addHelpCommand("listAppStripes", "opss", offline="true")
# This listAppStripes command works for both offline and online
    wlstModule.addHelpCommand("createResource", "opss", online="true")
    wlstModule.addHelpCommand("getResource", "opss", online="true")
    wlstModule.addHelpCommand("deleteResource", "opss", online="true")
    wlstModule.addHelpCommand("listResources", "opss", online="true")
    wlstModule.addHelpCommand("listResourceActions", "opss", online="true")
    wlstModule.addHelpCommand("createEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("getEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("deleteEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("listEntitlements", "opss", online="true")
    wlstModule.addHelpCommand("addResourceToEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("revokeResourceFromEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("grantEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("revokeEntitlement", "opss", online="true")
    wlstModule.addHelpCommand("upgradeOpss", "opss", offline="true")
    wlstModule.addHelpCommand("addBootStrapCredential", "opss", offline="true")
#  following commands are marked out for DW PS1 use, don't delete, note: no trailing spaces in each line    
    wlstModule.addHelpCommand("createFunction", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("getFunction", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("listFunctions", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("updateFunction", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("deleteFunction", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("updateResource", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("updateResourceType","opss",online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("createAttribute", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("listAttributes", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("updateAttribute", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("deleteAttribute", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("createPolicy", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("listPolicies", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("updatePolicy", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("deletePolicy", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("createApplicationPolicy", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("migratePoliciesToXacml", "opss", online="false")  # DWPS1 Specific
    wlstModule.addHelpCommand("configureOESAdminServer", "opss", online="true")  # DWPS1 Specific
    wlstModule.addHelpCommand("updateTrustServiceConfig", "opss", online="true")
    wlstModule.addHelpCommand("listSecurityStoreInfo", "opss", offline="true")
except:
    print "" #ignore the exception

from java.util import ResourceBundle
from oracle.security.jps import WlstResources
from java.util import Locale

opss_resourceBundle = ResourceBundle.getBundle("oracle.security.jps.WlstResources", Locale.getDefault(), WlstResources.getClassLoader())


def validateRequiredArgs(args, reqArgs) :
    for i in range(len(reqArgs)) :
        if (args.get(reqArgs[i]) is None ) :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_REQUIRED_ARG_MISSING)
            print msg + reqArgs[i]
            raise Exception, msg + reqArgs[i]

def validateConflictingArgs(args, arg1, arg2) :
    if (args.get(arg1) is not None and args.get(arg2) is not None) :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CONFLICTING_ARG)
        print msg + arg1 + ", " + arg2
        raise Exception, msg + arg1 + ", " + arg2 

def validateGroupArgs(args, grp) :
    found = 0
    for i in range(len(grp)) :
        if (args.get(grp[i])) :
            found = found + 1
    if (found != 0 and found != len(grp)) :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_GROUP_ARG_MISSING)
        print msg + grp.toString()
        raise Exception, msg + grp.toString()

def validateBooleanValue(arg, value) :
     if  not (value.lower() == "true" or value.lower() == "false") :
         print  arg + " " + opss_resourceBundle.getString(WlstResources.MSG_WLST_BOOLEAN_ARG)
         raise Exception, arg + " " +  opss_resourceBundle.getString(WlstResources.MSG_WLST_BOOLEAN_ARG)

def validateFileExistence(filepath) :
     fl = File(filepath)
     if (not fl.exists()):
	     msg = opss_resourceBundle.getString(WlstResources.MSG_FILE_NON_EXISTENT)
	     print filepath + " " + msg
	     raise Exception, filepath + " " + msg

def createCredObj(user, password, desc) :
    from oracle.security.jps.mas.mgmt.jmx.credstore import PortablePasswordCredential
    #Create Password Credential object
    pc = PortablePasswordCredential(user, password, desc)
    return pc

def opss_getPrincipalType(className):
        from  oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
        princType = None
        if (className == "oracle.security.jps.service.policystore.ApplicationRole"):
            princType = PrincipalType.APP_ROLE
        elif (className == "weblogic.security.principal.WLSUserImpl"):
                princType = PrincipalType.ENT_USER
        elif (className == "weblogic.security.principal.WLSGroupImpl"):
                princType = PrincipalType.ENT_ROLE
        else:
            princType = PrincipalType.CUSTOM
        return princType 


def listCredImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.credstore import PortableCredential
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.lang import String 
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("map")
    reqArgs.add("key")
    validateRequiredArgs(m, reqArgs)
    cred = None
    try:
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
        params = [m.get("map"), m.get("key")]
        sign = ["java.lang.String", "java.lang.String"]
        cred = wlstModule.mbs.invoke(on, "getPortableCredential", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg +  e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

    if cred != None:
        credObject = PortableCredential.from(cred)
        print credObject
        print "PASSWORD:" + String.valueOf(credObject.getPassword())
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CRED_NOT_FOUND)
        print msg

def listCred(map=None, key=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    listCredImpl(m)

def listAppRolesImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    try:
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe")]
        sign = ["java.lang.String"]
        appRoles = wlstModule.mbs.invoke(on, "getAllApplicationRoles", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg +  e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

    if appRoles != None:
        for r in appRoles:
            print PortableApplicationRole.from(r)
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_APP_NOT_FOUND)
        print msg + m.get("appStripe")

# function end
def createAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, displayName=None, description=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("displayName", displayName)
    m.put("description", description)
    createAdminRoleImpl(m)


def createAdminRoleImpl(m) :
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    appStripe = m.get("appStripe")
    policyDomainName = m.get("adminRoleName")
    displayName = m.get("displayName")
    description = m.get("description")
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [appStripe, policyDomainName, m.get("adminRoleName"),  displayName, description]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME]
        wlstModule.mbs.invoke(on, "createAdminRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise



def listAdminRoles(appStripe=None, policyDomainName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    listAdminRolesImpl(m)

def listAdminRolesImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableAdminRole
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    adminRoles = None
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("policyDomainName")]
        sign = [STR_NAME, STR_NAME]
        adminRoles=wlstModule.mbs.invoke(on, "listAdminRoles", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
    
    if adminRoles != None:
        for r in adminRoles:
            print PortableAdminRole.from(r)
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_ADMIN_ROLE_NOT_FOUND)
        print msg

def listAdminRoleMembers(appStripe=None, policyDomainName=None, adminRoleName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    listAdminRoleMembersImpl(m)

def listAdminRoleMembersImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    members = None
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName")]
        sign = [STR_NAME, STR_NAME, STR_NAME]
        members = wlstModule.mbs.invoke(on, "listAdminRoleMembers", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
    
    if members != None:
        for r in members:
            print PortablePrincipal.from(r)
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_PRINCIPAL_NOT_FOUND)
        print msg

def revokeAdminResource(appStripe=None, policyDomainName=None, adminRoleName=None, adminResource=None, action=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("adminResource", adminResource)
    m.put("action", action)
    revokeAdminResourceImpl(m)

def revokeAdminResourceImpl(m) :
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    reqArgs.add("adminResource")
    reqArgs.add("action")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),m.get("adminResource"), m.get("action")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME]
        wlstModule.mbs.invoke(on, "revokeAdminResource", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def grantAdminResource(appStripe=None, policyDomainName=None, adminRoleName=None, adminResource=None, action=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("adminResource", adminResource)
    m.put("action", action)
    grantAdminResourceImpl(m)


def grantAdminResourceImpl(m) :
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    reqArgs.add("adminResource")
    reqArgs.add("action")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),m.get("adminResource"), m.get("action")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME]
        wlstModule.mbs.invoke(on, "grantAdminResource", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise





def revokeAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, principalClass=None, principalName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    revokeAdminRoleImpl(m)

def revokeAdminRoleImpl(m) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    reqArgs.add("principalName")
    reqArgs.add("principalClass")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    members = None
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        pPl = None
        princType = opss_getPrincipalType(m.get("principalClass"))
        pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),pPl.toCompositeData(None)]
        sign = [STR_NAME, STR_NAME, STR_NAME, "javax.management.openmbean.CompositeData"]
        wlstModule.mbs.invoke(on, "revokeAdminRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def grantAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None, principalClass=None, principalName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    grantAdminRoleImpl(m)

def grantAdminRoleImpl(m) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    reqArgs.add("principalName")
    reqArgs.add("principalClass")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    members = None
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        pPl = None
        princType = opss_getPrincipalType(m.get("principalClass"))
        pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),pPl.toCompositeData(None)]
        sign = [STR_NAME, STR_NAME, STR_NAME, "javax.management.openmbean.CompositeData"]
        wlstModule.mbs.invoke(on, "grantAdminRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listAdminResources(appStripe=None, policyDomainName=None, adminRoleName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    listAdminResourcesImpl(m)

def listAdminResourcesImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableAdminResourceAction
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    adminResources = None
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName")]
        sign = [STR_NAME, STR_NAME, STR_NAME]
        adminResources=wlstModule.mbs.invoke(on, "listAdminResources", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

    if adminResources != None:
        for r in adminResources:
            print PortableAdminResourceAction.from(r)
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_ADMIN_RESOURCE_NOT_FOUND)
        print msg
 


def deleteAdminRole(appStripe=None, policyDomainName=None, adminRoleName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("policyDomainName", policyDomainName)
    m.put("adminRoleName", adminRoleName)
    deleteAdminRoleImpl(m)

def deleteAdminRoleImpl(m) :
    from java.lang import String
    from java.util import ArrayList
    import jarray
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    policyDomainName=  m.get("policyDomainName")
    STR_NAME = "java.lang.String"
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), policyDomainName, m.get("adminRoleName")]
        sign = [STR_NAME, STR_NAME, STR_NAME]
        wlstModule.mbs.invoke(on, "deleteAdminRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise





def listAppRoles(appStripe=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    listAppRolesImpl(m)

def listAppRoleMembersImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableRoleMember
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    validateRequiredArgs(m, reqArgs)

    members = None

    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        pAr = PortableApplicationRole(m.get("appRoleName"), "", "", "", "")

        params = [m.get("appStripe"), pAr.toCompositeData(None)]
        sign = ["java.lang.String", "javax.management.openmbean.CompositeData"]
        members = wlstModule.mbs.invoke(on, "getMembersForApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

    if members != None:
        for m in members:
            print PortableRoleMember.from(m)

def listAppRoleMembers(appStripe=None, appRoleName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    listAppRoleMembersImpl(m)

def listPermissionsImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("principalClass")
    reqArgs.add("principalName")
    validateRequiredArgs(m, reqArgs)
    try :
        wlstModule.domainRuntime()
        p = PortablePrincipal(m.get("principalClass"), m.get("principalName"), PrincipalType.CUSTOM)
        if m.get("appStripe") is None:
            o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
            params = [p.toCompositeData(None)]
            sign = ["javax.management.openmbean.CompositeData"]
            perms =  wlstModule.mbs.invoke(o, "getPermissions", params, sign)
        else:
            o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
            params = [m.get("appStripe"), p.toCompositeData(None)]
            sign = ["java.lang.String", "javax.management.openmbean.CompositeData"]
            perms =  wlstModule.mbs.invoke(o, "getPermissions", params, sign)
        for p in perms:
            print PortablePermission.from(p)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

# function ends
def listPermissions(appStripe=None, principalClass=None, principalName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    listPermissionsImpl(m)

## resourcetype start here

def createResourceTypeImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.lang import String
    from java.util import ArrayList
    import wlstModule
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceTypeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    
    provider = m.get("provider")
    matcher = m.get("matcher")
    delimiter = m.get("delimiter")

    try :
        obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        actionsArray = None
        actionsString = m.get("allowedActions")
        if actionsString is not None :
          actionsArray = jarray.array (actionsString.split(','), String)
        params = [m.get("appStripe"), m.get("resourceTypeName"), m.get("displayName"), m.get("description"), provider, matcher, actionsArray, delimiter ]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME, STR_NAME ]
        wlstModule.domainRuntime()
        wlstModule.mbs.invoke(obn, "createResourceType", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        #print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def createResourceType(appStripe=None, resourceTypeName=None, displayName=None, description=None, provider=None, matcher=None, allowedActions=None, delimiter=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    m.put("displayName",displayName)
    m.put("description",description)
    m.put("provider",provider)
    m.put("matcher",matcher)
    m.put("allowedActions",allowedActions)
    m.put("delimiter",delimiter)
    createResourceTypeImpl(m)



def getResourceTypeImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResourceType
    from java.util import ArrayList
    import wlstModule

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceTypeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("resourceTypeName")]
        sign = [STR_NAME, STR_NAME ]
        wlstModule.domainRuntime()
        resourceType = wlstModule.mbs.invoke(obn, "getResourceType", params, sign)
        print PortableResourceType.from(resourceType)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def getResourceType(appStripe=None, resourceTypeName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    getResourceTypeImpl(m)

    
def deleteResourceTypeImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResourceType
    from java.util import ArrayList
    import wlstModule

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceTypeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        params = [m.get("appStripe"), m.get("resourceTypeName")]
        sign = [STR_NAME, STR_NAME ]
        wlstModule.domainRuntime()
        wlstModule.mbs.invoke(obn, "deleteResourceType", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteResourceType(appStripe=None, resourceTypeName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe",appStripe)
    m.put("resourceTypeName",resourceTypeName)
    deleteResourceTypeImpl(m)
## resource type commands end here

def createAppRoleImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants;
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    validateRequiredArgs(m, reqArgs)
    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

        params = [m.get("appStripe"), m.get("appRoleName"), None, None, None]

        sign = ["java.lang.String", "java.lang.String", "java.lang.String", "java.lang.String", "java.lang.String"]
        wlstModule.mbs.invoke(on, "createApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

# function ends

def createAppRole(appStripe=None, appRoleName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    createAppRoleImpl(m)

def createCredImpl(m) :
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    map = m.get("map")
    key = m.get("key")
    user = m.get("user")
    password = m.get("password")
    desc = m.get("desc")

    reqArgs = ArrayList()
    reqArgs.add("map")
    reqArgs.add("key")
    reqArgs.add("user")
    reqArgs.add("password")
    validateRequiredArgs(m, reqArgs)

    try :
        pc = createCredObj(user, password, desc)
        obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)

        cd = pc.toCompositeData(None);
        params = [map, key, cd]
        sign = ["java.lang.String", "java.lang.String", "javax.management.openmbean.CompositeData"]
        wlstModule.domainRuntime()
        wlstModule.mbs.invoke(obn, "setPortableCredential", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def createCred(map=None, key=None, user=None, password=None, desc=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    m.put("user", user)
    m.put("password", password)
    m.put("desc", desc)
    createCredImpl(m)


def deleteAppPoliciesImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

        params = [m.get("appStripe")]

        sign = ["java.lang.String"]
        wlstModule.mbs.invoke(on, "deleteApplicationPolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteAppPolicies(appStripe=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    deleteAppPoliciesImpl(m)

def deleteAppRolesImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    validateRequiredArgs(m, reqArgs)

    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)

        params = [m.get("appStripe"), m.get("appRoleName")]

        sign = ["java.lang.String", "java.lang.String"]
        wlstModule.mbs.invoke(on, "removeApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteAppRole(appStripe=None, appRoleName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    deleteAppRolesImpl(m)

def deleteCredImpl(m) :
    from javax.management import MBeanException
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from java.util import ArrayList
    import wlstModule
    map = m.get("map")
    key = m.get("key")
    # Check if the required arguments were passed.
    reqArgs = ArrayList()
    reqArgs.add("map")
    reqArgs.add("key")
    validateRequiredArgs(m, reqArgs)
    try :
        wlstModule.domainRuntime()
        obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
        params = [map, key]
        sign = ["java.lang.String", "java.lang.String"]
        wlstModule.mbs.invoke(obn, "deleteCredential", params, sign)
    except MBeanException, e :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteCred(map=None, key=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    deleteCredImpl(m)

def grantAppRoleImpl(m) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableRoleMember
    from  oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    reqArgs.add("principalClass")
    reqArgs.add("principalName")
    validateRequiredArgs(m, reqArgs)

    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        r = PortableApplicationRole(m.get("appRoleName"), "", "", "", m.get("appStripe"))

        princType = opss_getPrincipalType(m.get("principalClass"))
        
        pm = PortableRoleMember(m.get("principalClass"), m.get("principalName"), princType, m.get("appStripe"))
        marr = wlstModule.array([pm.toCompositeData(None)], CompositeData)
        params = [m.get("appStripe"), r.toCompositeData(None), marr]

        sign = ["java.lang.String", "javax.management.openmbean.CompositeData", "[Ljavax.management.openmbean.CompositeData;"]
        wlstModule.mbs.invoke(on, "addMembersToApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def grantAppRole(appStripe=None, appRoleName=None, principalClass=None, principalName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    grantAppRoleImpl(m)

def grantPermissionImpl(m) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableCodeSource
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrantee
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrant
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("permClass")
    validateRequiredArgs(m, reqArgs)

    grpArgs = ArrayList()
    grpArgs.add("principalClass")
    grpArgs.add("principalName")
    validateGroupArgs(m, grpArgs)
    try :
        wlstModule.domainRuntime()
        pPl = None
        if m.get("principalClass") is not None and m.get("principalName")is not None:
            princType = opss_getPrincipalType(m.get("principalClass"))
            pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        pCs = PortableCodeSource(m.get("codeBaseURL"))
        pPlArray = None
        if pPl is not None:
            pPlArray = wlstModule.array([pPl], PortablePrincipal)
        pGe = PortableGrantee(pPlArray, pCs)
        pPm = PortablePermission(m.get("permClass"), m.get("permTarget"), m.get("permActions"))
        pGt = PortableGrant(pGe, wlstModule.array([pPm], PortablePermission))
        if m.get("appStripe") is None:
            o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
            params = [wlstModule.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["[Ljavax.management.openmbean.CompositeData;"]
            perms =  wlstModule.mbs.invoke(o, "grantToSystemPolicy", params, sign)
        else:
            o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
            params = [m.get("appStripe"), wlstModule.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["java.lang.String", "[Ljavax.management.openmbean.CompositeData;"]
            perms =  wlstModule.mbs.invoke(o, "grantToApplicationPolicy", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def grantPermission(appStripe=None, principalClass=None, principalName=None, codeBaseURL=None, permClass=None, permTarget=None, permActions=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    m.put("codeBaseURL", codeBaseURL)
    m.put("permClass", permClass)
    m.put("permTarget", permTarget)
    m.put("permActions", permActions)
    grantPermissionImpl(m)

def revokeAppRoleImpl(m) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableRoleMember
    from  oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    reqArgs.add("principalClass")
    reqArgs.add("principalName")
    validateRequiredArgs(m, reqArgs)

    try :
        wlstModule.domainRuntime()
        on = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
        r = PortableApplicationRole(m.get("appRoleName"), "", "", "", m.get("appStripe"))

        princType = opss_getPrincipalType(m.get("principalClass"))
 
        pm = PortableRoleMember(m.get("principalClass"), m.get("principalName"), princType, m.get("appStripe"))
        marr = wlstModule.array([pm.toCompositeData(None)], CompositeData)
        params = [m.get("appStripe"), r.toCompositeData(None), marr]

        sign = ["java.lang.String", "javax.management.openmbean.CompositeData", "[Ljavax.management.openmbean.CompositeData;"]
        wlstModule.mbs.invoke(on, "removeMembersFromApplicationRole", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def revokeAppRole(appStripe=None, appRoleName=None, principalClass=None, principalName=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("appRoleName", appRoleName)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    revokeAppRoleImpl(m)

def revokePermissionImpl(m) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableCodeSource
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrantee
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrant
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    reqArgs = ArrayList()
    reqArgs.add("permClass")
    validateRequiredArgs(m, reqArgs)

    grpArgs = ArrayList()
    grpArgs.add("principalClass")
    grpArgs.add("principalName")
    validateGroupArgs(m, grpArgs)

    try :
        wlstModule.domainRuntime()
        pPl = None
        if m.get("principalClass") is not None and m.get("principalName")is not None:
	    princType = opss_getPrincipalType(m.get("principalClass"))
            pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        pCs = PortableCodeSource(m.get("codeBaseURL"))
        pPlArray = None
        if pPl is not None:
            pPlArray = wlstModule.array([pPl], PortablePrincipal)
        pGe = PortableGrantee(pPlArray, pCs)
        pPm = PortablePermission(m.get("permClass"), m.get("permTarget"), m.get("permActions"))
        pGt = PortableGrant(pGe, wlstModule.array([pPm], PortablePermission))
        if m.get("appStripe") is None:
            o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_GLOBAL_POLICY_STORE)
            params = [wlstModule.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["[Ljavax.management.openmbean.CompositeData;"]
            wlstModule.mbs.invoke(o, "revokeFromSystemPolicy", params, sign)
        else:
            o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_APPLICATION_POLICY_STORE)
            params = [m.get("appStripe"), wlstModule.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["java.lang.String", "[Ljavax.management.openmbean.CompositeData;"]
            wlstModule.mbs.invoke(o, "revokeFromApplicationPolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def revokePermission(appStripe=None, principalClass=None, principalName=None, codeBaseURL=None, permClass=None, permTarget=None, permActions=None ) :
    from java.util import HashMap
    m = HashMap()
    m.put("appStripe", appStripe)
    m.put("principalClass", principalClass)
    m.put("principalName", principalName)
    m.put("permClass", permClass)
    m.put("permTarget", permTarget)
    m.put("permActions", permActions)
    m.put("codeBaseURL", codeBaseURL)
    revokePermissionImpl(m)

def updateCredImpl(m) :
    #Check for required arguments
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    import wlstModule
    map = m.get("map")
    key = m.get("key")
    user = m.get("user")
    password = m.get("password")
    desc = m.get("desc")

    reqArgs = ArrayList()
    reqArgs.add("map")
    reqArgs.add("key")
    reqArgs.add("user")
    reqArgs.add("password")
    validateRequiredArgs(m, reqArgs)
    
    try :
        pc = createCredObj(user, password, desc)
        obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_CREDENTIAL_STORE)
        cd = pc.toCompositeData(None);
        params = [map, key, cd]
        sign = ["java.lang.String", "java.lang.String", "javax.management.openmbean.CompositeData"]
        wlstModule.domainRuntime()
        wlstModule.mbs.invoke(obn, "resetPortableCredential", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def updateCred(map=None, key=None, user=None, password=None, desc=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("map", map)
    m.put("key", key)
    m.put("user", user)
    m.put("password", password)
    m.put("desc", desc)
    updateCredImpl(m)

def migrateSecurityStoreImpl(m) :
    from oracle.security.jps.tools.utility import JpsUtilMigrationTool
    from oracle.security.jps import JpsException
    from java.util import ArrayList
    reqArgs = ArrayList()
    reqArgs.add("type")
    reqArgs.add("src")
    reqArgs.add("dst")
    reqArgs.add("configFile")
    validateRequiredArgs(m, reqArgs)
    grpArgs = ArrayList()
    grpArgs.add("processPrivRole")
    grpArgs.add("resourceTypeFile")
    validateGroupArgs(m, grpArgs)


    validateConflictingArgs(m, "dstLdifFile", "srcApp")
    validateConflictingArgs(m, "dstLdifFile", "dstApp")
    if not (m.get("processPrivRole") is  None) :
       validateBooleanValue("processPrivRole", m.get("processPrivRole"))
    if not (m.get("overWrite") is  None) :
       validateBooleanValue("overWrite", m.get("overWrite"))
    if not (m.get("preserveAppRoleGuids") is  None) :
       validateBooleanValue("preserveAppRoleGuids", m.get("preserveAppRoleGuids"))
    try :
        mig = JpsUtilMigrationTool.executeCommand(m)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_DATA_MIGRATED)
    	print msg
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def migrateSecurityStore(type=None, src=None, dst=None, srcApp=None, dstApp=None, srcFolder=None, dstFolder=None, srcStripe=None, dstStripe=None, dstLdifFile=None, srcConfigFile=None, configFile=None, overWrite=None, processPrivRole=None, resourceTypeFile=None, migrateIdStoreMapping=None, preserveAppRoleGuid=None, reportFile=None, mode=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("type", type)
    m.put("src", src)
    m.put("dst", dst)
    m.put("srcApp", srcApp)
    m.put("dstApp", dstApp)
    m.put("srcFolder", srcFolder)
    m.put("dstFolder", dstFolder)
    m.put("srcStripe", srcStripe)
    m.put("dstStripe", dstStripe)
    m.put("dstLdifFile", dstLdifFile)
    m.put("srcConfigFile", srcConfigFile)
    m.put("configFile", configFile)
    m.put("processPrivRole", processPrivRole)
    m.put("resourceTypeFile", resourceTypeFile)
    m.put("overWrite", overWrite)     
    m.put("migrateIdStoreMapping", migrateIdStoreMapping)
    m.put("preserveAppRoleGuids", preserveAppRoleGuid)
    m.put("reportFile", reportFile)
    m.put("mode",mode)
    m.put("opss_wlst_migration","true")
    migrateSecurityStoreImpl(m)

def upgradeSecurityStoreImpl(m) :
    from oracle.security.jps.tools.utility import JpsUtilUpgradeTool
    from oracle.security.jps import JpsException
    from java.util import ArrayList
    reqArgs = ArrayList()
    reqArgs.add("type")
    reqArgs.add("jpsConfigFile")
    validateRequiredArgs(m, reqArgs)
    
    validateConflictingArgs(m, "srcJaznConfigFile", "srcJaznDataFile")
    
    try :
        mig = JpsUtilUpgradeTool.executeCommand(m)
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def upgradeSecurityStore(type=None, srcRealm=None, dst=None, srcJaznConfigFile=None, srcJaznDataFile=None, jpsConfigFile=None, users=None, dstJaznDataFile=None, srcApp=None, resourceTypeFile=None, jpsContext=None) :
    from java.util import HashMap
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
    upgradeSecurityStoreImpl(m)

#Mbean apis are called for reassociation of policy ,credential store and keystore
def reassociateService(wlstModule,pm,o,s,join,internalParams) :    
    #import wlstModule    
    params = [pm.toCompositeData(None), s] 
    sign = ["javax.management.openmbean.CompositeData","java.lang.String"]
    wlstModule.mbs.invoke(o,"checkServiceSetUp", params, sign)
    msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_LDAP_SERVER_SETUP_DONE)
    print msg
    if  (join == "false") :
    	wlstModule.mbs.invoke(o, "checkAndSeedSchema", None, None)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_LDAP_SCHEMA_SEEDED)
    	print msg 
    	wlstModule.mbs.invoke(o, "migrateData", None, None)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_DATA_REASS_MIGRATED)
    	print msg
    	wlstModule.mbs.invoke(o, "testJpsService", None, None)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_SERVICE_POST_MIGRATION_OK)
    	print msg
        
    if (internalParams.get("keyFilePassword") is not None) :
        wlstModule.mbs.invoke(o, "SetOptionalReassociationConfigParam", ["keyFilePassword",  array(internalParams.get("keyFilePassword"), 'c')], ["java.lang.String", "[C"])

    wlstModule.mbs.invoke(o, "updateLDAPReassociationConfiguration", None, None)
    msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_JPS_CONFIGURATION_DONE)
    print msg

    
def reassociateSecurityStoreImpl(m) :
    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap       
    from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from javax.management import RuntimeMBeanException
    from java.util import ArrayList
    from java.util import Set
    from java.util import HashMap

    import wlstModule

    #Remove empty arguments
    rmArgs = ArrayList()
    for k in m.keySet():
        if (m.get(k) is None) :
            rmArgs.add(k)
    for i in range(len(rmArgs)) :
        m.remove(rmArgs[i])

    #Construct the required and optional argurments for the script
    reqArgs = ArrayList()
    reqArgs.add("domain")
    reqArgs.add("servertype")
    reqArgs.add("jpsroot")

    servertype = m.get("servertype")
    if (servertype == "DB_ORACLE" or servertype == "DB_DERBY") :
        reqArgs.add("datasourcename")
    elif (servertype == "OID") :
        reqArgs.add("admin")
        reqArgs.add("password")
        reqArgs.add("ldapurl")
    else :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_INVALID_STORE_TYPE)
        print msg + servertype
        raise Exception, msg + servertype

    #validate if all the required args are passed through the commandline. Else inform the user
    #about the missing or conflict arguments
    validateRequiredArgs(m, reqArgs) 
    validateConflictingArgs(m, "ldapurl", "datasourcename")

    #check and validate if the group attribute information is passed
    grpArgs = ArrayList()
    grpArgs.add("admin")
    grpArgs.add("password")
    validateGroupArgs(m, grpArgs)

    grpArgs1 = ArrayList()
    grpArgs1.add("keyFilePath")
    grpArgs1.add("keyFilePassword")
    validateGroupArgs(m, grpArgs1)

    grpArgs2 = ArrayList()
    grpArgs2.add("jdbcurl")
    grpArgs2.add("dbUser")
    grpArgs2.add("dbPassword")
    grpArgs2.add("jdbcdriver")
    validateGroupArgs(m, grpArgs2)

    internalParams = HashMap()    

    #join option implies, it is configuration only reassociation without migration
    join = None

    if (m.get("join") is  None) :
	join = "false"
        m.remove("join")
        #TODO check if arguments not valid without join mode are specified 
    else :
    	validateBooleanValue("join", m.get("join"))
	join = m.remove("join")
        if (m.get("keyFilePath") is not None) :
           from oracle.security.jps.internal.tools.utility.cskey  import ImportExportKeyParamValidator
           ImportExportKeyParamValidator.validatewalletFilePath(m.get("keyFilePath"), true)
           # this will validate if the key is present, and password supplied is authentic
           ImportExportKeyParamValidator.validateWalletContainsKeys(m.get("keyFilePath"), m.get("keyFilePassword"))
           internalParams.put("keyFilePassword", m.get("keyFilePassword"))
           m.remove("keyFilePassword");

    try :
        #Navigate to the current domain. WLST inbuild tree command 
	wlstModule.domainRuntime()        
        o =  wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_CONFIG_FUNCTIONAL)        
        pm = PortableMap(m)
        #Reassociate the Policy Store
        s = "POLICY_STORE"               
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_POLICY_STORE_REASS_START)
        print msg
        reassociateService(wlstModule,pm,o,s,join,internalParams)       
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_POLICY_STORE_REASS_END)
        print msg 
        
        #Reassociate credential store
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CRED_STORE_REASS_START)
        print msg
        s = "CREDENTIAL_STORE"
        reassociateService(wlstModule,pm,o,s,join,internalParams)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CRED_STORE_REASS_END)
        print msg

        #Reassociate keystore
        try :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_KEY_STORE_REASS_START)
            print msg
            s = "KEY_STORE"
            reassociateService(wlstModule,pm,o,s,join,internalParams)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_KEY_STORE_REASS_END)
            print msg
        except RuntimeMBeanException, rme:
            print rme.getLocalizedMessage() + "\n"

        #Reassociate audit store
        try :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_AUDIT_STORE_REASS_START)
            print msg
            s = "AUDIT"
            reassociateService(wlstModule,pm,o,s,join,internalParams)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_AUDIT_STORE_REASS_END)
            print msg
        except RuntimeMBeanException, rme:
            print rme.getLocalizedMessage() + "\n"

        #persist the changes to jps-config.xml        
        wlstModule.mbs.invoke(o, "persist", None, None)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CONFIG_CHANGE_REASS)
        print msg

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

# reassociateSecurityStoreImp function ends

def reassociateSecurityStore(domain=None, admin=None, password=None,ldapurl=None,servertype=None,jpsroot=None,join=None, datasourcename=None, keyFilePath=None, keyFilePassword=None, jdbcurl=None, dbUser=None, dbPassword=None, jdbcdriver=None, odbcdsn=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("domain", domain)
    m.put("admin", admin)
    m.put("password", password)
    m.put("ldapurl", ldapurl)
    m.put("servertype", servertype)
    m.put("jpsroot", jpsroot)
    m.put("join", join)
    m.put("datasourcename", datasourcename)
    m.put("keyFilePath", keyFilePath)
    m.put("keyFilePassword", keyFilePassword)
    m.put("jdbcurl", jdbcurl)
    m.put("dbUser", dbUser)
    m.put("dbPassword", dbPassword)
    m.put("jdbcdriver", jdbcdriver)
    m.put("odbcdsn", odbcdsn)
    reassociateSecurityStoreImpl(m)


#end of reassociateSecurityStore command

# begining of modifyBootStrapCredential
def modifyBootStrapCredentialImpl(m) :
    #Check for required arguments
    from oracle.security.jps.tools.utility import JpsUtilModifyBootCredTool
    from oracle.security.jps import JpsException
    from java.util import ArrayList
    from java.lang import String
    from jarray import array
   
    reqArgs = ArrayList()
    reqArgs.add("jpsConfigFile")
    reqArgs.add("username")
    reqArgs.add("password")
    validateRequiredArgs(m, reqArgs)
    
    configfile = m.get("jpsConfigFile")
    username   = m.get("username")
    password   = m.get("password")
  
    carr = array(password,'c')
    
    try :
        JpsUtilModifyBootCredTool.executeCommand(configfile,username,carr)
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
    

def modifyBootStrapCredential(jpsConfigFile=None,username=None, password=None) :
    from java.util import HashMap
    m = HashMap()   
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("username", username)
    m.put("password", password)   
    modifyBootStrapCredentialImpl(m)

#modifyBootStrapCredentail function ends

# begining of addBootStrapCredential
def addBootStrapCredentialImpl(m) :
    #Check for required arguments
    from oracle.security.jps.tools.utility import JpsUtilAddBootCredTool
    from oracle.security.jps import JpsException
    from java.util import ArrayList
    from java.lang import String
    from jarray import array

    reqArgs = ArrayList()
    reqArgs.add("jpsConfigFile")
    reqArgs.add("map")
    reqArgs.add("key")
    reqArgs.add("username")
    reqArgs.add("password")
    validateRequiredArgs(m, reqArgs)

    configfile = m.get("jpsConfigFile")
    map        = m.get("map")
    key        = m.get("key")
    username   = m.get("username")
    password   = m.get("password")

    carr = array(password,'c')

    try :
        JpsUtilAddBootCredTool.executeCommand(configfile,map,key,username,carr)
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def addBootStrapCredential(jpsConfigFile=None, map=None, key=None, username=None, password=None) :
    from java.util import HashMap
    m = HashMap()
    m.put("jpsConfigFile", jpsConfigFile)
    m.put("map", map)
    m.put("key", key)
    m.put("username", username)
    m.put("password", password)
    addBootStrapCredentialImpl(m)

#addBootStrapCredentail function ends

def patchPolicyStoreImpl(m) :
    from java.util import ArrayList
    from oracle.security.jps.patch import PatchTool
    from oracle.security.jps.patch import PatchingException
    reqArgs = ArrayList()
    reqArgs.add(PatchTool.phase)
    reqArgs.add(PatchTool.patchDeltaFolder)
    reqArgs.add(PatchTool.productionJpsConfig)
    phase = m.get(PatchTool.phase)
    if (phase != None) :
        if (phase == 'analyze') :
           reqArgs.add(PatchTool.baselineAppStripe)
        elif (phase == 'apply') :
           reqArgs.add(PatchTool.productionAppStripe)
    validateRequiredArgs(m, reqArgs)    
    silent = m.get(PatchTool.silent)
    ignoreEnterpriseMembersOfAppRole = m.get(PatchTool.ignoreEnterpriseMembersOfAppRole)
    ignoreEnterpriseAppRoleMembershipConflicts = m.get(PatchTool.ignoreEnterpriseAppRoleMembershipConflicts)
    if silent is None :
	m.put(PatchTool.silent,"false")
    else :
	validateBooleanValue(PatchTool.silent,silent)
    if ignoreEnterpriseMembersOfAppRole is not None :
        validateBooleanValue(PatchTool.ignoreEnterpriseMembersOfAppRole,ignoreEnterpriseMembersOfAppRole)
    if ignoreEnterpriseAppRoleMembershipConflicts is not None :
        validateBooleanValue(PatchTool.ignoreEnterpriseAppRoleMembershipConflicts,ignoreEnterpriseAppRoleMembershipConflicts)
	
    try :
        return PatchTool.patchPolicyStore(m)
    except PatchingException, pe :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + pe.getLocalizedMessage() + "\n"
        raise pe
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def patchPolicyStore(phase=None, patchDeltaFolder=None, productionJpsConfig=None, baselineFile=None, patchFile=None, baselineAppStripe=None, productionAppStripe=None, patchAppStripe=None, silent=None, ignoreEnterpriseMembersOfAppRole=None, reportFile=None, ignoreEnterpriseAppRoleMembershipConflicts=None) :
    from java.util import HashMap
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
    m.put(PatchTool.ignoreEnterpriseAppRoleMembershipConflicts,ignoreEnterpriseAppRoleMembershipConflicts)
    m.put(PatchTool.reportFile, reportFile)
    print m
    return patchPolicyStoreImpl(m)

def upgradeOpss(jpsConfig=None, jaznData=None, auditStore=None, jdbcDriver=None, url=None, user=None, password=None, upgradeJseStoreType=None):
    from java.lang import System
    System.setProperty("oracle.security.opss.platform.type", "WEBLOGIC");
    System.setProperty("jps.xml.schema.validation.disabled", "true");    
    from oracle.security.jps import JpsException
    from oracle.security.jps.upgrade.tools.utility import Upgrade
    m = HashMap()
    m.put("jpsConfig", jpsConfig)
    m.put("jaznData", jaznData)
    m.put("auditStore",auditStore)
    m.put("jdbcDriver",jdbcDriver)
    m.put("url",url)
    m.put("user",user)
    m.put("password",password)
    m.put("upgradeJseStoreType",upgradeJseStoreType)
    print m
    reqArgs = ArrayList()
    reqArgs.add("jpsConfig")
    reqArgs.add("jaznData")
    validateRequiredArgs(m, reqArgs)
    if upgradeJseStoreType is not None :
        validateBooleanValue("upgradeJseStoreType", upgradeJseStoreType) 
    try :
        msg = opss_resourceBundle.getString(WlstResources.MSG_UPGRADE_BEGIN)
        print msg
        Upgrade.upgrade(jpsConfig, jaznData, auditStore, jdbcDriver, url, user, password, Boolean.parseBoolean(upgradeJseStoreType))
        msg = opss_resourceBundle.getString(WlstResources.MSG_UPGRADE_END)
        print msg
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#################################################################
# to get handle of keystore service command object
#################################################################

def getOpssService(name=None):
    from java.util import HashMap
    m = HashMap()
    m.put("name", name)
    return getOpssServiceImpl(m)

def getOpssServiceImpl(m):
    from java.util import ArrayList
    import wlstModule

    name = m.get("name")
    reqArgs = ArrayList()
    reqArgs.add("name")
    validateRequiredArgs(m, reqArgs)
    
    if (name == 'KeyStoreService'):
        return FKS()
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_INVALID_SERVICE_NAME)
        print msg
        return None

class FKS:    

    # command to list help
    def help(self, command=None):
        help_Bundle = ResourceBundle.getBundle("jpsWLSTResourceBundle", Locale.getDefault(), WlstResources.getClassLoader())
        if (command is None):
           # invoke the overall help for keystore cmds
           msg = help_Bundle.getString("keystoreCmdHelp")
        else:
            if (command == 'listKeyStores'):
               msg = help_Bundle.getString("listKeyStoresHelp")
            elif (command == 'changeKeyPassword'):
               msg = help_Bundle.getString("changeKeyPasswordHelp")
            elif (command == 'changeKeyStorePassword'):
               msg = help_Bundle.getString("changeKeyStorePasswordHelp")
            elif (command == 'createKeyStore'):
               msg = help_Bundle.getString("createKeyStoreHelp")
            elif (command == 'deleteKeyStore'):
               msg = help_Bundle.getString("deleteKeyStoreHelp")
            elif (command == 'deleteKeyStoreEntry'):
               msg = help_Bundle.getString("deleteKeyStoreEntryHelp")
            elif (command == 'exportKeyStore'):
               msg = help_Bundle.getString("exportKeyStoreHelp")
            elif (command == 'exportKeyStoreCertificate'):
               msg = help_Bundle.getString("exportKeyStoreCertificateHelp")
            elif (command == 'exportKeyStoreCertificateRequest'):
               msg = help_Bundle.getString("exportKeyStoreCertificateRequestHelp")
            elif (command == 'generateKeyPair'):
               msg = help_Bundle.getString("generateKeyPairHelp")
            elif (command == 'generateSecretKey'):
               msg = help_Bundle.getString("generateSecretKeyHelp")
            elif (command == 'getKeyStoreCertificates'):
               msg = help_Bundle.getString("getKeyStoreCertificates")
            elif (command == 'getKeyStoreSecretKeyProperties'):
               msg = help_Bundle.getString("getKeyStoreSecretKeyPropertiesHelp")
            elif (command == 'importKeyStore'):
               msg = help_Bundle.getString("importKeyStoreHelp")
            elif (command == 'importKeyStoreCertificate'):
               msg = help_Bundle.getString("importKeyStoreCertificateHelp")
            elif (command == 'listExpiringCertificates'):
               msg = help_Bundle.getString("listExpiringCertificatesHelp")
            elif (command == 'listKeyStoreAliases'):
               msg = help_Bundle.getString("listKeyStoreAliases")
            else:
               msg = opss_resourceBundle.getString(WlstResources.MSG_INVALID_COMMAND_NAME)
        print msg
             

    # command to list keystores
    def listKeyStoresImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        
        appStripe = m.get("appStripe")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            params = [appStripe]
            sign = ["java.lang.String"]
            arr = None
            wlstModule.domainRuntime()        
            arr = wlstModule.mbs.invoke(obn, "listKeyStores", params, sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (arr != None):
            length = len(arr)
            for i in range(length):
                print arr[i]

    def listKeyStores(self, appStripe=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        self.listKeyStoresImpl(m)

# command to create keystore

    def createKeyStoreImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        permission = m.get("permission")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("permission")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            if (len(pwd) == 0):
                pwd = None
            params = [appStripe, name, pwd, permission]
            sign = ["java.lang.String", "java.lang.String", "[C", "boolean"]
            wlstModule.domainRuntime()        
            wlstModule.mbs.invoke(obn, "createKeyStore", params, sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CREATE_KS_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

    def createKeyStore(self, appStripe=None, name=None, password=None, permission=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("permission", permission)
        self.createKeyStoreImpl(m)

    # command to delete keystore

    def deleteKeyStoreImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            params = [appStripe, name, pwd]
            sign = ["java.lang.String", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "deleteKeyStore", params, sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_DELETE_KS_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

    def deleteKeyStore(self, appStripe=None, name=None, password=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        self.deleteKeyStoreImpl(m)

    # command to change keystore password

    def changeKeyStorePasswordImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        currentpassword = m.get("currentpassword")
        newpassword = m.get("newpassword")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("currentpassword")
        reqArgs.add("newpassword")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            cpwd = String(currentpassword).toCharArray()
            npwd = String(newpassword).toCharArray()
            params = [appStripe, name, cpwd, npwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "[C"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "changeKeyStorePassword", params, sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CHANGE_KS_PWD_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise


    def changeKeyStorePassword(self, appStripe=None, name=None, currentpassword=None, newpassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("currentpassword", currentpassword)
        m.put("newpassword", newpassword)
        self.changeKeyStorePasswordImpl(m)

    # command to create demo CA signed certificate

    def generateKeyPairImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from oracle.security.jps.mas.mgmt.jmx.config import PortableMap       
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        dn = m.get("dn")
        keysize = m.get("keysize")
        alias = m.get("alias")
        keypassword = m.get("keypassword")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("dn")
        reqArgs.add("keysize")
        reqArgs.add("alias")
        reqArgs.add("keypassword")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = String(keypassword).toCharArray()
            keyprops = HashMap()
            keyprops.put("keySize", keysize) 
            pm = PortableMap(keyprops)

            params = [appStripe, name, pwd, dn, pm.toCompositeData(None), alias, kpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "javax.management.openmbean.CompositeData", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "createDemoCASignedCertificate", params, sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CREATE_KP_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

    def generateKeyPair(self, appStripe=None, name=None, password=None, dn=None, keysize=None, alias=None, keypassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("dn", dn)
        m.put("keysize", keysize)
        m.put("alias", alias)
        m.put("keypassword", keypassword)
        self.generateKeyPairImpl(m)

    # command to generate secret key

    def generateSecretKeyImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from oracle.security.jps.mas.mgmt.jmx.config import PortableMap       
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        algorithm = m.get("algorithm")
        keysize = m.get("keysize")
        alias = m.get("alias")
        keypassword = m.get("keypassword")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("algorithm")
        reqArgs.add("keysize")
        reqArgs.add("alias")
        reqArgs.add("keypassword")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = String(keypassword).toCharArray()
            keyprops = HashMap()
            keyprops.put("keySize", keysize) 
            keyprops.put("algorithm", algorithm) 
            pm = PortableMap(keyprops)
            params = [appStripe, name, pwd, pm.toCompositeData(None), alias, kpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "javax.management.openmbean.CompositeData", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "generateSecretKey", params, sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CREATE_SK_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise


    def generateSecretKey(self, appStripe=None, name=None, password=None, algorithm=None, keysize=None, alias=None, keypassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("algorithm", algorithm)
        m.put("keysize", keysize)
        m.put("alias", alias)
        m.put("keypassword", keypassword)
        self.generateSecretKeyImpl(m)

    # command to list keystore aliases

    def listKeyStoreAliasesImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        type = m.get("type")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("type")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            params = [appStripe, name, pwd, type]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String"]
            wlstModule.domainRuntime()
            arr = None
            arr = wlstModule.mbs.invoke(obn, "listAliases", params, sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (arr != None):
            length = len(arr)
            for i in range(length):
                print arr[i]


    def listKeyStoreAliases(self, appStripe=None, name=None, password=None, type=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("type", type)
        self.listKeyStoreAliasesImpl(m)

    # command to change key password

    def changeKeyPasswordImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")
        currentkeypassword = m.get("currentkeypassword")
        newkeypassword = m.get("newkeypassword")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        reqArgs.add("currentkeypassword")
        reqArgs.add("newkeypassword")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            ckpwd = String(currentkeypassword).toCharArray()
            nkpwd = String(newkeypassword).toCharArray()
            params = [appStripe, name, pwd, alias, ckpwd, nkpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C", "[C"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "changeKeyPassword", params, sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CHANGE_KEY_PWD_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise


    def changeKeyPassword(self, appStripe=None, name=None, password=None, alias=None, currentkeypassword=None, newkeypassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        m.put("currentkeypassword", currentkeypassword)
        m.put("newkeypassword", newkeypassword)
        self.changeKeyPasswordImpl(m)

    # command to get keystore certificate, trusted certificate or cert chain

    def getKeyStoreCertificatesImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = None
            params = [appStripe, name, pwd, alias, kpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            arr = None
            arr = wlstModule.mbs.invoke(obn, "getCertificates", params, sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (arr != None):
            length = len(arr)
            for i in range(length):
                print arr[i]


    def getKeyStoreCertificates(self, appStripe=None, name=None, password=None,  alias=None, keypassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        self.getKeyStoreCertificatesImpl(m)

    # command to get secret key properties

    def getKeyStoreSecretKeyPropertiesImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")
        keypassword = m.get("keypassword")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        reqArgs.add("keypassword")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = String(keypassword).toCharArray()
            params = [appStripe, name, pwd, alias, kpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            list = None
            list = wlstModule.mbs.invoke(obn, "getSecretKeyProperties", params, sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (list != None):
            print '-------------------------------------------------------'
            algo = list[0]
            msg = "Algorithm = "
            print msg + algo
            print '-------------------------------------------------------'


    def getKeyStoreSecretKeyProperties(self, appStripe=None, name=None, password=None, alias=None, keypassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        m.put("keypassword", keypassword)
        self.getKeyStoreSecretKeyPropertiesImpl(m)

    # command to export certificate request

    def exportKeyStoreCertificateRequestImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")
        keypassword = m.get("keypassword")
        filepath = m.get("filepath")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        reqArgs.add("keypassword")
        reqArgs.add("filepath")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = String(keypassword).toCharArray()
            params = [appStripe, name, pwd, alias, kpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            base64 = None
            base64 = wlstModule.mbs.invoke(obn, "exportCertificateRequest", params, sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (base64 != None):
            arr = String(base64).getBytes()
            fl = File(filepath)
            fdir = fl.getParentFile()
            if (fdir.exists()):
                fos = FileOutputStream(filepath)
                fos.write(arr)
                fos.flush()
                fos.close()
                msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CERT_REQ_EXPORTED)
                print msg
            else:
                msg = opss_resourceBundle.getString(WlstResources.MSG_FILE_NON_EXISTENT)
                print msg
        else:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CERT_REQ_FAILED)
            print msg

    def exportKeyStoreCertificateRequest(self, appStripe=None, name=None, password=None, alias=None, keypassword=None, filepath=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        m.put("keypassword", keypassword)
        m.put("filepath", filepath)
        self.exportKeyStoreCertificateRequestImpl(m)

    # command to export certificate, trusted certificate or certificate chain

    def exportKeyStoreCertificateImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")
        type = m.get("type")
        filepath = m.get("filepath")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        reqArgs.add("type")
        reqArgs.add("filepath")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = None
            params = [appStripe, name, pwd, alias, kpwd, type]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C", "java.lang.String"]
            wlstModule.domainRuntime()
            base64 = None
            base64 = wlstModule.mbs.invoke(obn, "exportCertificates", params,sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (base64 != None):
            arr = String(base64).getBytes()
            fl = File(filepath)
            fdir = fl.getParentFile()
            if (fdir.exists()):
                fos = FileOutputStream(filepath)
                fos.write(arr)
                fos.flush()
                fos.close()
                msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CERT_EXPORTED)
                print msg
            else:
                msg = opss_resourceBundle.getString(WlstResources.MSG_FILE_NON_EXISTENT)
                print msg
        else:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_CERT_FAILED)
            print msg


    def exportKeyStoreCertificate(self, appStripe=None, name=None, password=None,alias=None, keypassword=None, type=None, filepath=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        m.put("type", type)
        m.put("filepath", filepath)
        self.exportKeyStoreCertificateImpl(m)

    # command to import certificate, trusted certificate or certificate chain

    def importKeyStoreCertificateImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")
        keypassword = m.get("keypassword")
        type = m.get("type")
        filepath = m.get("filepath")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        reqArgs.add("keypassword")
        reqArgs.add("type")
        reqArgs.add("filepath")
        validateRequiredArgs(m, reqArgs)
        validateFileExistence(filepath)
        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = String(keypassword).toCharArray()
            

            fis = FileInputStream(filepath)
            num = fis.available()
            arr = zeros(num, 'b')
            fis.read(arr)
            fis.close()
            base64 = String(arr)

            params = [appStripe, name, pwd, alias, kpwd, type, base64]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C", "java.lang.String", "java.lang.String"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "importCertificates", params,sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_IMPORT_CERT_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

    def importKeyStoreCertificate(self, appStripe=None, name=None, password=None,alias=None, keypassword=None, type=None, filepath=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        m.put("keypassword", keypassword)
        m.put("type", type)
        m.put("filepath", filepath)
        self.importKeyStoreCertificateImpl(m)

    # command to delete keystore entry

    def deleteKeyStoreEntryImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        alias = m.get("alias")
        keypassword = m.get("keypassword")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("alias")
        reqArgs.add("keypassword")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            kpwd = String(keypassword).toCharArray()
            params = [appStripe, name, pwd, alias, kpwd]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "deleteKeyStoreEntry", params,sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_DELETE_ENTRY_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

    def deleteKeyStoreEntry(self, appStripe=None, name=None, password=None,alias=None, keypassword=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("alias", alias)
        m.put("keypassword", keypassword)
        self.deleteKeyStoreEntryImpl(m)

    # command to list expiring certificates and optionally renew them

    def listExpiringCertificatesImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        days = m.get("days")
        autorenew = m.get("autorenew")

        reqArgs = ArrayList()
        reqArgs.add("days")
        reqArgs.add("autorenew")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            tmp = Integer(days)        
            numberOfDays = tmp.intValue()
            params = [numberOfDays, autorenew]
            sign = ["int", "boolean"]
            wlstModule.domainRuntime()
            outerlist = None
            outerlist = wlstModule.mbs.invoke(obn, "listExpiringCertificates", params,sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (outerlist != None):
            length = len(outerlist)
            for i in range(length):
                certinfo = outerlist[i]
                stripe = certinfo[0]
                ksname = certinfo[1]
                alias = certinfo[2]
                status = certinfo[3]
                expiry = certinfo[4]
                print '---------------------------------------------------'
                print "App Stripe = " + stripe
                print "Keystore = " + ksname 
                print "Alias = " + alias
                print "Certificate status = " + status
                print "Expiration Date = " + expiry
                print '---------------------------------------------------'

    def listExpiringCertificates(self, days=None, autorenew=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("days", days)
        m.put("autorenew", autorenew)
        self.listExpiringCertificatesImpl(m)

    # command to export keystore 

    def exportKeyStoreImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        aliases = m.get("aliases")
        keypasswords = m.get("keypasswords")
        type = m.get("type")
        filepath = m.get("filepath")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("aliases")
        reqArgs.add("keypasswords")
        reqArgs.add("type")
        reqArgs.add("filepath")
        validateRequiredArgs(m, reqArgs)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            params = [appStripe, name, pwd, aliases, keypasswords, type]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "java.lang.String", "java.lang.String"]
            wlstModule.domainRuntime()
            ksbytes = None
            ksbytes = wlstModule.mbs.invoke(obn, "exportKeyStore", params,sign)
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

        if (ksbytes != None):
            fl = File(filepath)
            fdir = fl.getParentFile()
            if (fdir.exists()):
                fos = FileOutputStream(filepath)
                fos.write(ksbytes)
                fos.flush()
                fos.close()
                msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_EXPORT_KS_DONE)
                print msg + "\n"
            else:
                msg = opss_resourceBundle.getString(WlstResources.MSG_FILE_NON_EXISTENT)
                print msg


    def exportKeyStore(self, appStripe=None, name=None, password=None,aliases=None, keypasswords=None, type=None, filepath=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("aliases", aliases)
        m.put("keypasswords", keypasswords)
        m.put("type", type)
        m.put("filepath", filepath)
        self.exportKeyStoreImpl(m)

    # command to import key store

    def importKeyStoreImpl(self, m):
        from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
        from javax.management import MBeanException
        from java.util import ArrayList
        import wlstModule
        appStripe = m.get("appStripe")
        name = m.get("name")
        password = m.get("password")
        aliases = m.get("aliases")
        keypasswords = m.get("keypasswords")
        type = m.get("type")
        permission = m.get("permission")
        filepath = m.get("filepath")

        reqArgs = ArrayList()
        reqArgs.add("appStripe")
        reqArgs.add("name")
        reqArgs.add("password")
        reqArgs.add("aliases")
        reqArgs.add("keypasswords")
        reqArgs.add("type")
        reqArgs.add("permission")
        reqArgs.add("filepath")
        validateRequiredArgs(m, reqArgs)
        validateFileExistence(filepath)

        try :
            obn = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_KEY_STORE)
            pwd = String(password).toCharArray()
            if (len(pwd) == 0):
                pwd = None

            fis = FileInputStream(filepath)
            num = fis.available()
            arr = zeros(num, 'b')
            fis.read(arr)
            fis.close()

            params = [appStripe, name, pwd, aliases, keypasswords, type, arr, permission]
            sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String" , "java.lang.String", "java.lang.String", "[B", "boolean"]
            wlstModule.domainRuntime()
            wlstModule.mbs.invoke(obn, "importKeyStore", params,sign)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_FKS_IMPORT_KS_DONE)
            print msg + "\n"
        except MBeanException, e:
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
            print msg + e.getLocalizedMessage() + "\n"
            raise e
        except :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
            print msg
            raise

    def importKeyStore(self, appStripe=None, name=None, password=None,aliases=None, keypasswords=None, type=None, permission=None, filepath=None) :
        from java.util import HashMap
        m = HashMap()
        m.put("appStripe", appStripe)
        m.put("name", name)
        m.put("password", password)
        m.put("aliases", aliases)
        m.put("keypasswords", keypasswords)
        m.put("type", type)
        m.put("permission", permission)
        m.put("filepath", filepath)
        self.importKeyStoreImpl(m)

