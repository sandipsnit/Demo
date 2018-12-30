################################################################
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################
from java.util import ResourceBundle
from java.util import Locale
from java.util import ArrayList
from java.util import Set
from java.util import HashMap
from java.lang import String 
from java.io   import File
import ora_mbs
import ora_help
from oracle.security.jps import WlstResources
from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
from oracle.security.jps import JpsException
from javax.management import MBeanException

#######################################################
# This function adds command help
# (Internal function)
#######################################################
 
def addOpssCommandHelp():  
 try:
   ora_help.addHelpCommandGroup("opss","jpsWLSTResourceBundle")
   ora_help.addHelpCommand("createAdminRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("deleteAdminRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("listAdminRoles","opss", offline="false", online="true")
   ora_help.addHelpCommand("listAdminRoleMembers","opss", offline="false", online="true")
   ora_help.addHelpCommand("grantAdminRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("revokeAdminRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("grantAdminResource","opss", offline="false", online="true")
   ora_help.addHelpCommand("revokeAdminResource","opss", offline="false", online="true")
   ora_help.addHelpCommand("listAdminResources","opss", offline="false", online="true")
   ora_help.addHelpCommand("listCred","opss", offline="false", online="true")
   ora_help.addHelpCommand("createCred","opss", offline="false", online='true')
   ora_help.addHelpCommand("updateCred","opss", offline="false", online="true")
   ora_help.addHelpCommand("deleteCred","opss", offline="false", online="true")
   ora_help.addHelpCommand("listAppRoles","opss", offline="false", online="true")
   ora_help.addHelpCommand("createResourceType","opss", offline="false", online="true")
   ora_help.addHelpCommand("getResourceType","opss", offline="false", online="true")
   ora_help.addHelpCommand("deleteResourceType","opss", offline="false", online="true")
   ora_help.addHelpCommand("createAppRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("deleteAppRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("listAppRoleMembers","opss", offline="false", online="true")
   ora_help.addHelpCommand("grantAppRole","opss",offline="false", online="true")
   ora_help.addHelpCommand("revokeAppRole","opss", offline="false", online="true")
   ora_help.addHelpCommand("listPermissions","opss",offline="false", online="true")
   ora_help.addHelpCommand("listCodeSourcePermissions","opss",offline="false", online="true")
   ora_help.addHelpCommand("grantPermission","opss",offline="false", online="true")
   ora_help.addHelpCommand("revokePermission","opss",offline="false", online="true")
   ora_help.addHelpCommand("deleteAppPolicies","opss",offline="false", online="true")
   ora_help.addHelpCommand("migrateSecurityStore","opss", offline="true", online="false")
   ora_help.addHelpCommand("reassociateSecurityStore","opss",offline="false", online="true")
   ora_help.addHelpCommand("upgradeSecurityStore", "opss", offline="true", online="false")
   ora_help.addHelpCommand("modifyBootStrapCredential", "opss", offline="true", online="false")
   ora_help.addHelpCommand("patchPolicyStore", "opss", offline="true", online="false")
   ora_help.addHelpCommand("listKeyStores", "opss", offline="false", online="true")
   ora_help.addHelpCommand("createKeyStore", "opss", offline="false", online="true")
   ora_help.addHelpCommand("deleteKeyStore", "opss", offline="false", online="true")
   ora_help.addHelpCommand("changeKeyStorePassword", "opss", offline="false", online="true")
   ora_help.addHelpCommand("generateKeyPair", "opss", offline="false", online="true")
   ora_help.addHelpCommand("generateSecretKey", "opss", offline="false", online="true")
   ora_help.addHelpCommand("listKeyStoreAliases", "opss", offline="false", online="true")
   ora_help.addHelpCommand("changeKeyStoreKeyPassword", "opss", offline="false", online="true")
   ora_help.addHelpCommand("getKeyStoreCertificates", "opss", offline="false", online="true")
   ora_help.addHelpCommand("getKeyStoreSecretKeyProperties", "opss", offline="false", online="true")
   ora_help.addHelpCommand("exportKeyStoreCertificateRequest", "opss", offline="false", online="true")
   ora_help.addHelpCommand("exportKeyStoreCertificate", "opss", offline="false", online="true")
   ora_help.addHelpCommand("importKeyStoreCertificate", "opss", offline="false", online="true")
   ora_help.addHelpCommand("deleteKeyStoreEntry", "opss", offline="false", online="true")
   ora_help.addHelpCommand("listExpiringCertificates", "opss", offline="false", online="true")
   ora_help.addHelpCommand("exportKeyStore", "opss", offline="false", online="true")
   ora_help.addHelpCommand("importKeyStore", "opss", offline="false", online="true")
   ora_help.addHelpCommand("importEncryptionKey", "opss", offline="true", online="false")
   ora_help.addHelpCommand("exportEncryptionKey", "opss", offline="true", online="false")
   ora_help.addHelpCommand("restoreEncryptionKey", "opss", offline="true", online="false")
   ora_help.addHelpCommand("upgradeOpss", "opss", offline="true", online="false")
#  following commands are marked out for DW PS1 use, don't delete 
   ora_help.addHelpCommand("createFunction","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("getFunction","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("listFunctions","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("updateFunction","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("deleteFunction","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("createAttribute","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("updateAttribute","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("deleteAttribute","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("listAttributes","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("updateResourceType","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("updateResource","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("createApplicationPolicy","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("createPolicy","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("updatePolicy","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("listPolicies","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("deletePolicy","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("migratePoliciesToXacml","opss", offline="true", online="false")  # DWPS1 Specific
   ora_help.addHelpCommand("configureOESAdminServer","opss", offline="false", online="true")  # DWPS1 Specific
   ora_help.addHelpCommand("updateTrustServiceConfig","opss", offline="false", online="true")
   ora_help.addHelpCommand("listSecurityStoreInfo","opss", offline="true", online="false")
 except Exception, e:
    return
   

opss_resourceBundle = ResourceBundle.getBundle("oracle.security.jps.WlstResources", Locale.getDefault(), WlstResources.getClassLoader())



#######################################################
# Helper methods 
#######################################################

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



#######################################################
# Admin Role METHODS Start
#######################################################
def createAdminRoleImpl(m,on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),  m.get("displayName"), m.get("description")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "createAdminRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteAdminRoleImpl(m,on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray
 
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName")]
        sign = [STR_NAME, STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "deleteAdminRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def listAdminRoles(m,on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableAdminRole

    reqArgs = ArrayList()
    validateRequiredArgs(m, reqArgs)

    try:

        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName")]
        sign = ["java.lang.String", "java.lang.String"]
        adminRoles = ora_mbs.invoke(objectName, "listAdminRoles", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg +  e.getLocalizedMessage() + "\n"
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

def listAdminRoleMembers(m,on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
   
    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)

    try:

        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName")]
        sign = ["java.lang.String", "java.lang.String", "java.lang.String"]
        adminRoles = ora_mbs.invoke(objectName, "listAdminRoleMembers", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg +  e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

    if adminRoles != None:
        for r in adminRoles:
            print PortablePrincipal.from(r)
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_PRINCIPAL_NOT_FOUND)
        print msg

def grantAdminRole(m,on) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("principalName")
    reqArgs.add("principalClass")
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        pPl = None
        princType = opss_getPrincipalType(m.get("principalClass"))
        pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),pPl.toCompositeData(None)]
        sign = [STR_NAME, STR_NAME, STR_NAME, "javax.management.openmbean.CompositeData"]
        ora_mbs.invoke(objectName, "grantAdminRole", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def revokeAdminRole(m,on) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("principalName")
    reqArgs.add("principalClass")
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        pPl = None
        princType = opss_getPrincipalType(m.get("principalClass"))
        pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"),pPl.toCompositeData(None)]
        sign = [STR_NAME, STR_NAME, STR_NAME, "javax.management.openmbean.CompositeData"]
        ora_mbs.invoke(objectName, "revokeAdminRole", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def grantAdminResource(m,on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    reqArgs.add("adminResource")
    reqArgs.add("action")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"), m.get("adminResource"), m.get("action")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "grantAdminResource", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
 
def revokeAdminResource(m,on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    reqArgs.add("adminResource")
    reqArgs.add("action")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName"), m.get("adminResource"), m.get("action")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "revokeAdminResource", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def listAdminResources(m,on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableAdminResourceAction

    reqArgs = ArrayList()
    reqArgs.add("adminRoleName")
    validateRequiredArgs(m, reqArgs)

    try:

        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyDomainName"), m.get("adminRoleName")]
        sign = ["java.lang.String", "java.lang.String", "java.lang.String"]
        adminResources = ora_mbs.invoke(objectName, "listAdminResources", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg +  e.getLocalizedMessage() + "\n"
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
    





# LIST METHODS
#######################################################

#######################################################
# listCredImpl API
#######################################################

def listCredImpl(m,on) :
    from oracle.security.jps.mas.mgmt.jmx.credstore import PortableCredential         
    reqArgs = ArrayList()
    reqArgs.add("map")
    reqArgs.add("key")
    validateRequiredArgs(m, reqArgs)
    cred = None
    try:
        
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("map"), m.get("key")]
        sign = ["java.lang.String", "java.lang.String"]
        cred =  ora_mbs.invoke(objectName, "getPortableCredential", params, sign)
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


#######################################################
# listAppRoles API
#######################################################

def listAppRolesImpl(m,on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole   
   
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    try:
        
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe")]
        sign = ["java.lang.String"]
        appRoles = ora_mbs.invoke(objectName, "getAllApplicationRoles", params, sign)
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

#######################################################
# listAppRoleMembers API
#######################################################

def listAppRoleMembersImpl(m,on) :

    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableRoleMember
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    validateRequiredArgs(m, reqArgs)

    members = None

    try :
       
        objectName = ora_mbs.makeObjectName(on)
        pAr = PortableApplicationRole(m.get("appRoleName"), "", "", "", "")

        params = [m.get("appStripe"), pAr.toCompositeData(None)]
        sign = ["java.lang.String", "javax.management.openmbean.CompositeData"]
        members = ora_mbs.invoke(objectName, "getMembersForApplicationRole", params, sign)
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
    else:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_APP_NOT_FOUND)
        print msg + m.get("appStripe")


#######################################################
# listPermissions API
#######################################################

def listPermissionsImpl(m,on_global,on_app) :

    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    
    reqArgs = ArrayList()
    reqArgs.add("principalClass")
    reqArgs.add("principalName")
    validateRequiredArgs(m, reqArgs)

    try :
       
        p = PortablePrincipal(m.get("principalClass"), m.get("principalName"), PrincipalType.CUSTOM)
        if m.get("appStripe") is None:
            objectName = ora_mbs.makeObjectName(on_global)
            params = [p.toCompositeData(None)]
            sign = ["javax.management.openmbean.CompositeData"]
            perms =  ora_mbs.invoke(objectName, "getPermissions", params, sign)
        else:
            objectName = ora_mbs.makeObjectName(on_app)
            params = [m.get("appStripe"), p.toCompositeData(None)]
            sign = ["java.lang.String", "javax.management.openmbean.CompositeData"]
            perms = ora_mbs.invoke(objectName, "getPermissions", params, sign)
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

#######################################################
# listCodeSourcePermissions API
#######################################################

def listCodeSourcePermissionsImpl(m,on_global,on_app) :

    from oracle.security.jps.mas.mgmt.jmx.policy import PortableCodeSource
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission

    reqArgs = ArrayList()
    reqArgs.add("codeBaseURL")
    validateRequiredArgs(m, reqArgs)

    try :

        p = PortableCodeSource(m.get("codeBaseURL"))
        if m.get("appStripe") is None:
            objectName = ora_mbs.makeObjectName(on_global)
            params = [p.toCompositeData(None)]
            sign = ["javax.management.openmbean.CompositeData"]
            perms =  ora_mbs.invoke(objectName, "getCodeSourcePermissions", params, sign)
        else:
            objectName = ora_mbs.makeObjectName(on_app)
            params = [m.get("appStripe"), p.toCompositeData(None)]
            sign = ["java.lang.String", "javax.management.openmbean.CompositeData"]
            perms = ora_mbs.invoke(objectName, "getCodeSourcePermissions", params, sign)
        if perms is not None:
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

## resource start here
def createResourceImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("type")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name"), m.get("type"), m.get("displayName"), m.get("description")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "createResource", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def getResourceImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResource
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("type")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name"), m.get("type")]
        sign = [STR_NAME, STR_NAME, STR_NAME ]
        resource = ora_mbs.invoke(objectName, "getResource", params, sign)
        print PortableResource.from(resource)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteResourceImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResource
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("type")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name"), m.get("type")]
        sign = [STR_NAME, STR_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "deleteResource", params, sign)

    except MBeanException, e:
	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listResourcesImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResource
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"),  m.get("type")]
        sign = [STR_NAME, STR_NAME]
        resources = ora_mbs.invoke(objectName, "listResources", params, sign)
        for resource in resources:
            print PortableResource.from(resource)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
 	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listResourceActionsImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResourceActions
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("entitlementName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"),  m.get("entitlementName")]
        sign = [STR_NAME, STR_NAME]
        resourceActions = ora_mbs.invoke(objectName, "listResourceActions", params, sign)
        for resourceAction in resourceActions:
            print PortableResourceActions.from(resourceAction)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def updateResourceImpl(m, on) :
    from java.lang import String
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableAttribute
    from java.lang import IllegalArgumentException
    from javax.management.openmbean import CompositeData
    from java.lang import Boolean
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceName")
    reqArgs.add("type")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    compositeDataArray = []

    try :
        objectName = ora_mbs.makeObjectName(on)
        attributesString = m.get("attributes")
        anAttrPartsArray = None
        valuesArray = None
        tempBoolean = Boolean("false")
        if attributesString is not None and attributesString is not "":
            attributesArray = jarray.array (attributesString.split(';'), String)
            for anAttrStr in attributesArray:
                anAttrPartsArray = jarray.array (anAttrStr.split(':'), String)
                attrName = String(anAttrPartsArray[0])
                if len(anAttrPartsArray) is 1:
                    if attrName.startsWith("-"):
                        valuesArray = []
                        p = PortableAttribute(anAttrPartsArray[0], "", "", "", "", tempBoolean.booleanValue(), tempBoolean.booleanValue(), valuesArray)
                        compositeDataArray.append(p.toCompositeData(None))
                    else:
                        raise IllegalArgumentException ("Attribute " + anAttrStr + " is not in valid format")
                elif len(anAttrPartsArray) is 2:
                    valuesArray = jarray.array (anAttrPartsArray[1].split(','), String)
                    p = PortableAttribute(anAttrPartsArray[0], "", "", "", "", tempBoolean.booleanValue(), tempBoolean.booleanValue(), valuesArray)
                    compositeDataArray.append(p.toCompositeData(None))
                else:
                    raise IllegalArgumentException ("Attribute " + anAttrStr + " is not in valid format")
        params = [m.get("appStripe"), m.get("resourceName"), m.get("type"), m.get("displayName"), m.get("description"), jarray.array(compositeDataArray, CompositeData)]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, "[Ljavax.management.openmbean.CompositeData;"]
        ora_mbs.invoke(objectName, "updateResource", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
## resource end here

## custom function start here

def createFunctionImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("functionName")
    reqArgs.add("className")
    reqArgs.add("returnType")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    try :
        objectName = ora_mbs.makeObjectName(on)
        paramTypesString = m.get("paramTypes")
        paramTypesArray = None
        if paramTypesString is not None:
            paramTypesArray = jarray.array (paramTypesString.split(','), String)
        params = [m.get("appStripe"), m.get("functionName"), m.get("displayName"), m.get("description"), m.get("className"),
                     m.get("returnType"), paramTypesArray]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME]
        ora_mbs.invoke(objectName, "createFunction", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def getFunctionImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableFunction
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("functionName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("functionName")]
        sign = [STR_NAME, STR_NAME ]
        function = ora_mbs.invoke(objectName, "getFunction", params, sign)
        print PortableFunction.from(function)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteFunctionImpl(m, on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("functionName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("functionName")]
        sign = [STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "deleteFunction", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listFunctionsImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableFunction
    from java.util import ArrayList
    from java.lang import Boolean

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)
    hideBuiltIn = m.get("hideBuiltIn")
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        tmpbool = String(hideBuiltIn)
        tmp = Boolean(tmpbool)
        boolval = tmp.booleanValue()
        params = [m.get("appStripe"), boolval]
        sign = [STR_NAME, "boolean"]
        functions = ora_mbs.invoke(objectName, "listFunctions", params, sign)
        for function in functions:
            print PortableFunction.from(function)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def updateFunctionImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("functionName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"

    try :
        objectName = ora_mbs.makeObjectName(on)
        paramTypesString = m.get("paramTypes")
        paramTypesArray = None
        if paramTypesString is not None and paramTypesString is not "":
            paramTypesArray = jarray.array (paramTypesString.split(','), String)
        elif paramTypesString is not None and paramTypesString is "":
            paramTypesArray = []
        params = [m.get("appStripe"), m.get("functionName"), m.get("displayName"), m.get("description"), m.get("className"),
                     m.get("returnType"), paramTypesArray]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME]
        ora_mbs.invoke(objectName, "updateFunction", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
## custom function end here

## attribute start here

def createAttributeImpl(m, on) :
    from java.lang import String
    from java.lang import Boolean
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("attributeName")
    reqArgs.add("type")
    reqArgs.add("category")
    validateRequiredArgs(m, reqArgs)
    isSingle = m.get("isSingle")
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    try :
        objectName = ora_mbs.makeObjectName(on)
        tmpbool = String(isSingle)
        tmp = Boolean(tmpbool)
        boolval = tmp.booleanValue()
        params = [m.get("appStripe"), m.get("attributeName"), m.get("displayName"), m.get("description"), m.get("type"),
                     m.get("category"), boolval, None]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, "boolean", STRING_ARRAY_NAME]
        ora_mbs.invoke(objectName, "createAttribute", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def updateAttributeImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("attributeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("attributeName"), m.get("displayName"), m.get("description"), None]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME]
        ora_mbs.invoke(objectName, "updateAttribute", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteAttributeImpl(m, on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("attributeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("attributeName")]
        sign = [STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "deleteAttribute", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listAttributesImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableAttribute
    from java.util import ArrayList
    from java.lang import Boolean

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    hideBuiltIn = m.get("hideBuiltIn")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        tmpbool = String(hideBuiltIn)
        tmp = Boolean(tmpbool)
        boolval = tmp.booleanValue()
        params = [m.get("appStripe"), boolval]
        sign = [STR_NAME, "boolean"]
        attributes = ora_mbs.invoke(objectName, "listAttributes", params, sign)
        for attribute in attributes:
            print PortableAttribute.from(attribute)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

## attribute end here

## policy start here

def createPolicyImpl(m, on) :
    from java.lang import String
    from java.lang import IllegalArgumentException
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from java.util import ArrayList
    from javax.management.openmbean import CompositeData
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("policyName")
    reqArgs.add("ruleExpression")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    try :
        objectName = ora_mbs.makeObjectName(on)
        entitlementsString = m.get("entitlements")
        entitlementsArray = None
        if entitlementsString is not None:
            entitlementsArray = jarray.array (entitlementsString.split(','), String)
        portablePrincipalsStrString = m.get("principals")
        portablePrincipalsStrArray = None
        compositeDataArray = []
        tempStringArray = None
        if portablePrincipalsStrString is not None:
            portablePrincipalsStrArray = jarray.array (portablePrincipalsStrString.split(','), String)
            i = 0
            for portablePrincipalStr in portablePrincipalsStrArray:
                tempStringArray = jarray.array (portablePrincipalStr.split(':'), String)
                if len(tempStringArray) is 2:
                    p = PortablePrincipal(tempStringArray[1], tempStringArray[0], PrincipalType.CUSTOM)
                    compositeDataArray.append(p.toCompositeData(None))
                    i = i + 1
                else:
                    raise IllegalArgumentException (portablePrincipalStr + " is not a valid PortablePrincipal")
        print compositeDataArray
        params = [m.get("appStripe"), m.get("policyName"), m.get("displayName"), m.get("description"),
                     m.get("ruleExpression"), entitlementsArray, m.get("resourceActions"), 
                     jarray.array(compositeDataArray, CompositeData), m.get("codeSource"), m.get("obligations"), 
                     m.get("semantic")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME, STR_NAME,
                   "[Ljavax.management.openmbean.CompositeData;", STR_NAME, STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "createPolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def updatePolicyImpl(m, on) :
    from java.lang import String
    from java.lang import IllegalArgumentException
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from java.util import ArrayList
    from javax.management.openmbean import CompositeData
    from javax.management import RuntimeMBeanException
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("policyName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    try :
        objectName = ora_mbs.makeObjectName(on)
        entitlementsString = m.get("entitlements")
        entitlementsArray = None
        if entitlementsString is not None:
            entitlementsArray = jarray.array (entitlementsString.split(','), String)
        portablePrincipalsStrString = m.get("principals")
        portablePrincipalsStrArray = None
        compositeDataArray = []
        tempStringArray = None
        if portablePrincipalsStrString is not None:
            portablePrincipalsStrArray = jarray.array (portablePrincipalsStrString.split(','), String)
            i = 0
            for portablePrincipalStr in portablePrincipalsStrArray:
                tempStringArray = jarray.array (portablePrincipalStr.split(':'), String)
                if len(tempStringArray) is 2:
                    p = PortablePrincipal(tempStringArray[1], tempStringArray[0], PrincipalType.CUSTOM)
                    compositeDataArray.append(p.toCompositeData(None))
                    i = i + 1
                else:
                    raise IllegalArgumentException (portablePrincipalStr + " is not a valid PortablePrincipal")
        print compositeDataArray
        params = [m.get("appStripe"), m.get("policyName"), m.get("displayName"), m.get("description"),
                     m.get("ruleExpression"), entitlementsArray, m.get("resourceActions"), 
                     jarray.array(compositeDataArray, CompositeData), m.get("codeSource"), m.get("obligations")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME, STR_NAME,
                   "[Ljavax.management.openmbean.CompositeData;", STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "updatePolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deletePolicyImpl(m, on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("policyName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("policyName")]
        sign = [STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "deletePolicy", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listPoliciesImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePolicy
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe")]
        sign = [STR_NAME]
        policies = ora_mbs.invoke(objectName, "listPolicies", params, sign)
        for policy in policies:
            print PortablePolicy.from(policy)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

## policy end here

## permission set start here

def createEntitlementImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("resourceName")
    reqArgs.add("resourceType")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name"), m.get("displayName"), m.get("description"), m.get("resourceName"), m.get("resourceType"), m.get("actions")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "createEntitlement", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def getEntitlementImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermissionSet
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name")]
        sign = [STR_NAME, STR_NAME]
        permissionset = ora_mbs.invoke(objectName, "getEntitlement", params, sign)
        print PortablePermissionSet.from(permissionset)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteEntitlementImpl(m, on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name")]
        sign = [STR_NAME, STR_NAME]
        ora_mbs.invoke(objectName, "deleteEntitlement", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


def addResourceToEntitlementImpl(m, on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("resourceName")
    reqArgs.add("resourceType")
    reqArgs.add("actions")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name"), m.get("resourceName"), m.get("resourceType"), m.get("actions")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "addResourceToEntitlement", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def revokeResourceFromEntitlementImpl(m, on) :
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("resourceName")
    reqArgs.add("resourceType")
    reqArgs.add("actions")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("name"), m.get("resourceName"), m.get("resourceType"), m.get("actions")]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "revokeResourceFromEntitlement", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listEntitlementsImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermissionSet
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    grpArgs = ArrayList()
    grpArgs.add("resourceTypeName")
    grpArgs.add("resourceName") 
    validateGroupArgs(m, grpArgs)

    STR_NAME = "java.lang.String"

    try :
        pPl = None
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("resourceTypeName"), m.get("resourceName")]
        sign = [STR_NAME, STR_NAME, STR_NAME]
        permissions = ora_mbs.invoke(objectName, "listEntitlements", params, sign)
        for permission in permissions:
            print PortablePermissionSet.from(permission)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def grantEntitlementImpl(m, on) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("principalName")
    reqArgs.add("principalClass")
    reqArgs.add("entitlementName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        pPl = None
        princType = opss_getPrincipalType(m.get("principalClass"))
        pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("entitlementName"),pPl.toCompositeData(None)]
        sign = [STR_NAME, STR_NAME, "javax.management.openmbean.CompositeData"]
        ora_mbs.invoke(objectName, "grantEntitlement", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def revokeEntitlementImpl(m, on) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("principalName")
    reqArgs.add("principalClass")
    reqArgs.add("entitlementName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        pPl = None
        princType = opss_getPrincipalType(m.get("principalClass"))
        pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("entitlementName"),pPl.toCompositeData(None)]
        sign = [STR_NAME, STR_NAME, "javax.management.openmbean.CompositeData"]
        ora_mbs.invoke(objectName, "revokeEntitlement", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
## permission set end here

## resourcetype start here

def createResourceTypeImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        actionsArray = None
        actionsString = m.get("allowedActions")
        if actionsString is not None :
         actionsArray = jarray.array (actionsString.split(','), String)
        params = [m.get("appStripe"), m.get("resourceTypeName"), m.get("displayName"), m.get("description"), provider, matcher, actionsArray, delimiter ]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "createResourceType", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def getResourceTypeImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResourceType
    from java.util import ArrayList
    
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceTypeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("resourceTypeName")]
        sign = [STR_NAME, STR_NAME ]
        resourceType = ora_mbs.invoke(objectName, "getResourceType", params, sign)
        print PortableResourceType.from(resourceType)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def deleteResourceTypeImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResourceType
    from java.util import ArrayList
    
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceTypeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("resourceTypeName")]
        sign = [STR_NAME, STR_NAME ]
        ora_mbs.invoke(objectName, "deleteResourceType", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def listResourceTypesImpl(m, on) :
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableResourceType
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe")]
        sign = [STR_NAME]
        resourceTypes = ora_mbs.invoke(objectName, "listResourceTypes", params, sign)
        for resourceType in resourceTypes:
            print PortableResourceType.from(resourceType)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

def updateResourceTypeImpl(m, on) :
    from java.lang import String
    from java.util import ArrayList
    from java.lang import Boolean
    from java.lang import Character
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("resourceTypeName")
    validateRequiredArgs(m, reqArgs)
    STR_NAME = "java.lang.String"
    BOOL_NAME = "java.lang.Boolean"
    CHAR_NAME = "java.lang.Character" 
    STRING_ARRAY_NAME = "[Ljava.lang.String;"

    try :
        objectName = ora_mbs.makeObjectName(on)
        allowedActionsString = m.get("allowedActions")
        hierarchicalResource = None
        resourceNameDelimiter = None
        if not (m.get("hierarchicalResource") is  None) :
            validateBooleanValue("hierarchicalResource", m.get("hierarchicalResource"))
            hierarchicalResource = Boolean(m.get("hierarchicalResource"))
        if not (m.get("resourceNameDelimiter") is  None) :
            resourceNameDelimiter = Character(m.get("resourceNameDelimiter"))
        allowedActionsArray = None
        if allowedActionsString is not None:
            allowedActionsArray = jarray.array (allowedActionsString.split(','), String)
        attributesString = m.get("attributes")
        attributesArray = None
        if attributesString is not None:
            attributesArray = jarray.array (attributesString.split(','), String)
        params = [m.get("appStripe"), m.get("resourceTypeName"), m.get("displayName"), m.get("description"), 
                     allowedActionsArray, m.get("delimiter"), attributesArray, m.get("provider"),
                     m.get("matcher"), hierarchicalResource, resourceNameDelimiter]
        sign = [STR_NAME, STR_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME, STR_NAME, STRING_ARRAY_NAME, STR_NAME,
                   STR_NAME, BOOL_NAME, CHAR_NAME]
        ora_mbs.invoke(objectName, "updateResourceType", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
## resource type commands end here

###################################
# listAppStripesImpl API
###################################
def listAppStripesImpl(m, on):
    from oracle.security.jps.tools.utility import JpsWLSTUtil
    from oracle.security.jps import JpsException
    STR_NAME = "java.lang.String"
    try :
         connected = m.get("connected")
         if (connected == "true"):
           objectName = ora_mbs.makeObjectName(on)
           params = [m.get("regularExpression")]
           sign = [STR_NAME]
           appStripes = ora_mbs.invoke(objectName, "listAppStripes", params, sign)
         else:
           reqArgs = ArrayList()
           reqArgs.add("configFile")
           validateRequiredArgs(m, reqArgs)
           appStripes = JpsWLSTUtil.listAppStripesImpl(m)
         for appStripe in appStripes:
             print appStripe
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise



#######################################################
# createAppRoleImpl API
#######################################################

def createAppRoleImpl(m,on) :
    
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    validateRequiredArgs(m, reqArgs)

    try :        
        objectName = ora_mbs.makeObjectName(on)

        params = [m.get("appStripe"), m.get("appRoleName"), None, None, None]

        sign = ["java.lang.String", "java.lang.String", "java.lang.String", "java.lang.String", "java.lang.String"]
        ora_mbs.invoke(objectName, "createApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise



#######################################################
# createCredImpl API
#######################################################

def createCredImpl(m,on) :
    
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
        objectName = ora_mbs.makeObjectName(on)

        cd = pc.toCompositeData(None);
        params = [map, key, cd]
        sign = ["java.lang.String", "java.lang.String", "javax.management.openmbean.CompositeData"]
        
        ora_mbs.invoke(objectName, "setPortableCredential", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise



#######################################################
# createApplicationPolicyImpl API
#######################################################

def createApplicationPolicyImpl(m,on) :

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe")]
        sign = ["java.lang.String"]
        ora_mbs.invoke(objectName, "createApplicationPolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#######################################################
# deleteAppPoliciesImpl API
#######################################################

def deleteAppPoliciesImpl(m,on) :
    
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    try :        
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe")]
        sign = ["java.lang.String"]
        ora_mbs.invoke(objectName, "deleteApplicationPolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#######################################################
# deleteAppRolesImpl API
#######################################################

def deleteAppRolesImpl(m,on) :
   
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    validateRequiredArgs(m, reqArgs)

    try :
       
        objectName = ora_mbs.makeObjectName(on)
        params = [m.get("appStripe"), m.get("appRoleName")]

        sign = ["java.lang.String", "java.lang.String"]
        ora_mbs.invoke(objectName, "removeApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#######################################################
# deleteCredImpl API
#######################################################

def deleteCredImpl(m,on) :
    
    map = m.get("map")
    key = m.get("key")
    # Check if the required arguments were passed.
    reqArgs = ArrayList()
    reqArgs.add("map")
    reqArgs.add("key")
    validateRequiredArgs(m, reqArgs)
    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [map, key]
        sign = ["java.lang.String", "java.lang.String"]
        ora_mbs.invoke(objectName, "deleteCredential", params, sign)
    except MBeanException, e :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


#######################################################
# grantAppRoleImpl API
#######################################################

def grantAppRoleImpl(m,on) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableRoleMember
    from  oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    import jarray
    
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    reqArgs.add("principalClass")
    reqArgs.add("principalName")
    validateRequiredArgs(m, reqArgs)

    try :
        objectName = ora_mbs.makeObjectName(on)
        r = PortableApplicationRole(m.get("appRoleName"), "", "", "", m.get("appStripe"))
        princType = opss_getPrincipalType(m.get("principalClass")) 
	print princType
        pm = PortableRoleMember(m.get("principalClass"), m.get("principalName"), princType, m.get("appStripe"))
        marr = jarray.array([pm.toCompositeData(None)], CompositeData)
	print marr
        params = [m.get("appStripe"), r.toCompositeData(None), marr]

        sign = ["java.lang.String", "javax.management.openmbean.CompositeData", "[Ljavax.management.openmbean.CompositeData;"]
        ora_mbs.invoke(objectName, "addMembersToApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except Exception, e1:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
	print e1.getLocalizedMessage()
        raise e1

#######################################################
# grantPermissionImpl API
#######################################################

def grantPermissionImpl(m,on,obn) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableCodeSource
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrantee
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrant
    import jarray

    reqArgs = ArrayList()
    reqArgs.add("permClass")
    validateRequiredArgs(m, reqArgs)

    grpArgs = ArrayList()
    grpArgs.add("principalClass")
    grpArgs.add("principalName")
    validateGroupArgs(m, grpArgs)
    try :
        
        pPl = None
        if m.get("principalClass") is not None and m.get("principalName")is not None:
	    princType = opss_getPrincipalType(m.get("principalClass"))
            pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        pCs = PortableCodeSource(m.get("codeBaseURL"))
        pPlArray = None
        if pPl is not None:
            pPlArray = jarray.array([pPl], PortablePrincipal)
        pGe = PortableGrantee(pPlArray, pCs)
        pPm = PortablePermission(m.get("permClass"), m.get("permTarget"), m.get("permActions"))
        pGt = PortableGrant(pGe, jarray.array([pPm], PortablePermission))
        if m.get("appStripe") is None:
            objectName = ora_mbs.makeObjectName(on)
            params = [jarray.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["[Ljavax.management.openmbean.CompositeData;"]
            perms =  ora_mbs.invoke(objectName, "grantToSystemPolicy", params, sign)
        else:
            objectName = ora_mbs.makeObjectName(obn)
            params = [m.get("appStripe"), jarray.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["java.lang.String", "[Ljavax.management.openmbean.CompositeData;"]
            perms =  ora_mbs.invoke(objectName, "grantToApplicationPolicy", params, sign)

    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise



#######################################################
# revokeAppRoleImpl API
#######################################################

def revokeAppRoleImpl(m,on) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableApplicationRole
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableRoleMember
    from  oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType    
    import jarray   
    
    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("appRoleName")
    reqArgs.add("principalClass")
    reqArgs.add("principalName")
    validateRequiredArgs(m, reqArgs)

    try :
        
        objectName = ora_mbs.makeObjectName(on)
        r = PortableApplicationRole(m.get("appRoleName"), "", "", "", m.get("appStripe"))
        princType = opss_getPrincipalType(m.get("principalClass")) 
        pm = PortableRoleMember(m.get("principalClass"), m.get("principalName"), princType, m.get("appStripe"))
        marr = jarray.array([pm.toCompositeData(None)], CompositeData)
        params = [m.get("appStripe"), r.toCompositeData(None), marr]
        sign = ["java.lang.String", "javax.management.openmbean.CompositeData", "[Ljavax.management.openmbean.CompositeData;"]
        ora_mbs.invoke(objectName, "removeMembersFromApplicationRole", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#######################################################
# revokePermissionImpl API
#######################################################

def revokePermissionImpl(m,on,obn) :
    from javax.management.openmbean import CompositeData
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePrincipal
    from oracle.security.jps.mas.mgmt.jmx.policy.PortablePrincipal import PrincipalType
    from oracle.security.jps.mas.mgmt.jmx.policy import PortablePermission
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableCodeSource
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrantee
    from oracle.security.jps.mas.mgmt.jmx.policy import PortableGrant

    import jarray  
   
    reqArgs = ArrayList()
    reqArgs.add("permClass")
    validateRequiredArgs(m, reqArgs)
    grpArgs = ArrayList()
    grpArgs.add("principalClass")
    grpArgs.add("principalName")
    validateGroupArgs(m, grpArgs)

    try :
        pPl = None
        if m.get("principalClass") is not None and m.get("principalName")is not None:
	    princType = opss_getPrincipalType(m.get("principalClass"))
            pPl = PortablePrincipal(m.get("principalClass"), m.get("principalName"), princType)
        pCs = PortableCodeSource(m.get("codeBaseURL"))
        pPlArray = None
        if pPl is not None:
            pPlArray = jarray.array([pPl], PortablePrincipal)
        pGe = PortableGrantee(pPlArray, pCs)
        pPm = PortablePermission(m.get("permClass"), m.get("permTarget"), m.get("permActions"))
        pGt = PortableGrant(pGe, jarray.array([pPm], PortablePermission))
        if m.get("appStripe") is None:
            objectName = ora_mbs.makeObjectName(on)
            params = [jarray.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["[Ljavax.management.openmbean.CompositeData;"]
            ora_mbs.invoke(objectName, "revokeFromSystemPolicy", params, sign)
        else:
            objectName = ora_mbs.makeObjectName(obn)
            params = [m.get("appStripe"), jarray.array([pGt.toCompositeData(None)], CompositeData)]
            sign = ["java.lang.String", "[Ljavax.management.openmbean.CompositeData;"]
            ora_mbs.invoke(objectName, "revokeFromApplicationPolicy", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


#######################################################
# updateCredImpl API
#######################################################

def updateCredImpl(m,on) :
    import jarray

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
        objectName = ora_mbs.makeObjectName(on)
        cd = pc.toCompositeData(None);
        params = [map, key, cd]
        sign = ["java.lang.String", "java.lang.String", "javax.management.openmbean.CompositeData"]        
        ora_mbs.invoke(objectName, "resetPortableCredential", params, sign)
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#######################################################
# migratePoliciesToXacmlImpl API
#######################################################

def migratePoliciesToXacmlImpl(m) :
    from oracle.security.jps.tools.utility import JpsUtilMigrationTool
    
    reqArgs = ArrayList()
    reqArgs.add("src")
    reqArgs.add("dst")
    reqArgs.add("srcApp")
    reqArgs.add("configFile")
    validateRequiredArgs(m, reqArgs)
      
    try :
        mig = JpsUtilMigrationTool.executeXacmlMigrationCommand(m)
        print opss_resourceBundle.getString(WlstResources.MSG_WLST_XACML_EXPORT_DONE)
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

#######################################################
# migrateSecurityStoreImpl API
#######################################################

def migrateSecurityStoreImpl(m) :
    from oracle.security.jps.tools.utility import JpsUtilMigrationTool
    
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
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


#######################################################
# upgradeSecurityStoreImpl API
#######################################################

def upgradeSecurityStoreImpl(m) :
    from oracle.security.jps.tools.utility import JpsUtilUpgradeTool
    
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

#######################################################
# reassociateService API
#######################################################

#Mbean apis are called for reassociation of policy and credential store
def reassociateService(pm,o,s,join) :    
      
    params = [pm.toCompositeData(None), s] 
    sign = ["javax.management.openmbean.CompositeData","java.lang.String"]
    ora_mbs.invoke(o,"checkServiceSetUp", params, sign)
    msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_LDAP_SERVER_SETUP_DONE)
    print msg
    if  (join == "false") :
    	ora_mbs.invoke(o, "checkAndSeedSchema", None, None)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_LDAP_SCHEMA_SEEDED)
    	print msg 
    	ora_mbs.invoke(o, "migrateData", None, None)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_DATA_REASS_MIGRATED)
    	print msg
    	ora_mbs.invoke(o, "testJpsService", None, None)
    	msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_SERVICE_POST_MIGRATION_OK)
    	print msg
    	
    ora_mbs.invoke(o, "updateLDAPReassociationConfiguration", None, None)
    msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_JPS_CONFIGURATION_DONE)
    print msg

#######################################################
# reassociateSecurityStoreImpl API
#######################################################

def reassociateSecurityStoreImpl(m,on) :
    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap       
    from javax.management import RuntimeMBeanException
    import Opss as opss

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

    grpArgs2 = ArrayList()
    grpArgs2.add("jdbcurl")
    grpArgs2.add("dbUser")
    grpArgs2.add("dbPassword")
    grpArgs2.add("jdbcdriver")
    validateGroupArgs(m, grpArgs2)

    #join option implies, it is configuration only reassociation without migration
    join = None

    if (m.get("join") is  None) :
	join = "false"
        m.remove("join")
    else :
    	validateBooleanValue("join", m.get("join"))
	join = m.remove("join")

    internalParams = HashMap()

    try :
        #Navigate to the current domain. WLST inbuild tree command     
        o = ora_mbs.makeObjectName(on)     
        pm = PortableMap(m)
        #Reassociate the Policy Store
        s = "POLICY_STORE"               
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_POLICY_STORE_REASS_START)
        print msg
        reassociateService(pm,o,s,join)       
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_POLICY_STORE_REASS_END)
        print msg 
        
        #Reassociate credential store
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CRED_STORE_REASS_START)
        print msg
        s = "CREDENTIAL_STORE"
        reassociateService(pm,o,s,join)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_CRED_STORE_REASS_END)
        print msg
        
	#Reassociate keystore 
        try :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_KEY_STORE_REASS_START)
            print msg
            s = "KEY_STORE"
            reassociateService(pm,o,s,join)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_KEY_STORE_REASS_END)
            print msg
        except RuntimeMBeanException, rme:
            print rme.getLocalizedMessage() + "\n"

        #Reassociate audit store
        try :
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_AUDIT_STORE_REASS_START)
            print msg
            s = "AUDIT"
            reassociateService(pm,o,s,join)
            msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_AUDIT_STORE_REASS_END)
            print msg
        except RuntimeMBeanException, rme:
            print rme.getLocalizedMessage() + "\n"

        #persist the changes to jps-config.xml        
        ora_mbs.invoke(o, "persist", None, None)
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

#######################################################
# modifyBootStrapCredentialImpl API
#######################################################

def modifyBootStrapCredentialImpl(m) :
    #Check for required arguments
    from oracle.security.jps.tools.utility import JpsUtilModifyBootCredTool
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


#######################################################
# addBootStrapCredentialImpl API
#######################################################

def addBootStrapCredentialImpl(m) :
    #Check for required arguments
    from oracle.security.jps.tools.utility import JpsUtilAddBootCredTool
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

#######################################################
# patchPolicyStoreImpl API
#######################################################

def patchPolicyStoreImpl(m) :
    
    from oracle.security.jps.patch import PatchTool
    from oracle.security.jps.patch import PatchingException

    reqArgs = ArrayList()
    reqArgs.add(PatchTool.phase)
    reqArgs.add(PatchTool.patchDeltaFolder)
    reqArgs.add(PatchTool.productionJpsConfig)
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
        PatchTool.patchPolicyStore(m)
    except PatchingException, pe :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + pe.getLocalizedMessage() + "\n"
        raise pe
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise


#######################################################

#######################################################
# configureIdStoreImpl API                            #
#######################################################

def configureIdentityStoreImpl(on,ldapUrl,adminId,arrPassword,ldapType,subscriberName,userSearchBase,groupSearchBase,mp,checkLdapInst):
    from oracle.security.jps.mas.mgmt.jmx.config import JpsConfigMXBean
    from javax.management import MBeanException
    from jarray import array
    from java.lang import Object
    from java.lang import String
    from java.util import Properties
    from java.io import File
    from java.io import FileInputStream
    from oracle.security.jps.mas.mgmt.jmx.config import JpsConfigMBeanConstants
   
    
    STR_NAME = "java.lang.String"
    CHAR_ARRAY_NAME = "[C"
    STRING_ARRAY_NAME = "[Ljava.lang.String;"
    COMPOSITEDATA_NAME = "javax.management.openmbean.CompositeData"

    params = [None, ldapUrl, adminId, arrPassword, ldapType, subscriberName, userSearchBase, groupSearchBase, mp]
    sign = [STR_NAME, STR_NAME, STR_NAME, CHAR_ARRAY_NAME, STR_NAME, STR_NAME, STRING_ARRAY_NAME, STRING_ARRAY_NAME, COMPOSITEDATA_NAME]

    lParams = [ldapUrl,adminId,arrPassword]
    lSign = [STR_NAME,STR_NAME,CHAR_ARRAY_NAME]
    
    validateBooleanValue(JpsConfigMBeanConstants.CHECK_LDAP_INSTANCE, checkLdapInst)

    try :
          o = ora_mbs.makeObjectName(on)
          if (checkLdapInst == "true" ) :
           ora_mbs.invoke(o, 'testLDAPConnection', lParams,lSign)
          ora_mbs.invoke(o, 'configureLDAPIdentityStore', params, sign)
          ora_mbs.invoke(o, 'persist', None, None)
    except MBeanException, e:          
          msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
          print msg + e.getLocalizedMessage() + "\n"
          raise e
    except :
          msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
          print msg
          raise

########################################################
#  rollOverEncryptionKey 
########################################################
def rollOverEncryptionKeyImpl(m) :
    #Check for required arguments
    from oracle.security.jps.tools.utility import JpsUtilRollOverEncryptionKeyTool
    from oracle.security.jps import JpsException
    from java.util import ArrayList
    from java.lang import String
    from jarray import array

    reqArgs = ArrayList()
    reqArgs.add("jpsConfigFile")
    validateRequiredArgs(m, reqArgs)

    configFile = m.get("jpsConfigFile")

    try :
        JpsUtilRollOverEncryptionKeyTool.executeCommand(configFile)
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

########################################################
#  listKeyStores
########################################################

def listKeyStoresImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    appStripe = m.get("appStripe")

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    validateRequiredArgs(m, reqArgs)

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [appStripe]
        sign = ["java.lang.String"]
        arr = None
        arr = ora_mbs.invoke(objectName, "listKeyStores", params, sign)
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

########################################################
#  createKeyStore 
########################################################

def createKeyStoreImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.lang import Boolean
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        if (len(pwd) == 0):
            pwd = None
        tmpbool = String(permission)
        tmp = Boolean(tmpbool)
        boolval = tmp.booleanValue()
        params = [appStripe, name, pwd, boolval]
        sign = ["java.lang.String", "java.lang.String", "[C", "boolean"]
        ora_mbs.invoke(objectName, "createKeyStore", params, sign)
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

########################################################
#  deleteKeyStore 
########################################################
    
def deleteKeyStoreImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    appStripe = m.get("appStripe")
    name = m.get("name")
    password = m.get("password")

    reqArgs = ArrayList()
    reqArgs.add("appStripe")
    reqArgs.add("name")
    reqArgs.add("password")
    validateRequiredArgs(m, reqArgs)

    try :
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        params = [appStripe, name, pwd]
        sign = ["java.lang.String", "java.lang.String", "[C"]
        ora_mbs.invoke(objectName, "deleteKeyStore", params, sign)
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

########################################################
#  changeKeyStorePassword 
########################################################

def changeKeyStorePasswordImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        cpwd = String(currentpassword).toCharArray()
        npwd = String(newpassword).toCharArray()
        params = [appStripe, name, cpwd, npwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "[C"]
        ora_mbs.invoke(objectName, "changeKeyStorePassword", params, sign)
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

########################################################
#  generateKeyPair 
########################################################

def generateKeyPairImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.util import HashMap 
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = String(keypassword).toCharArray()
        keyprops = HashMap()
        keyprops.put("keySize", keysize)
        pm = PortableMap(keyprops)

        params = [appStripe, name, pwd, dn, pm.toCompositeData(None), alias, kpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "javax.management.openmbean.CompositeData", "java.lang.String", "[C"]
        ora_mbs.invoke(objectName, "createDemoCASignedCertificate", params, sign)
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

########################################################
#  generateSecretKey 
########################################################

def generateSecretKeyImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.util import HashMap 
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = String(keypassword).toCharArray()
        keyprops = HashMap()
        keyprops.put("keySize", keysize)
        keyprops.put("algorithm", algorithm)
        pm = PortableMap(keyprops)
        params = [appStripe, name, pwd, pm.toCompositeData(None), alias, kpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "javax.management.openmbean.CompositeData", "java.lang.String", "[C"]
        ora_mbs.invoke(objectName, "generateSecretKey", params, sign)
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

########################################################
#  listKeyStoreAliases 
########################################################

def listKeyStoreAliasesImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        params = [appStripe, name, pwd, type]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String"
]
        arr = None
        arr = ora_mbs.invoke(objectName, "listAliases", params, sign)
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

########################################################
#  changeKeyStoreKeyPassword 
########################################################

def changeKeyStoreKeyPasswordImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        ckpwd = String(currentkeypassword).toCharArray()
        nkpwd = String(newkeypassword).toCharArray()
        params = [appStripe, name, pwd, alias, ckpwd, nkpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C", "[C"]
        ora_mbs.invoke(objectName, "changeKeyPassword", params, sign)
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

########################################################
#  getKeyStoreCertificates 
########################################################

def getKeyStoreCertificatesImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = None
        params = [appStripe, name, pwd, alias, kpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
        arr = None
        arr = ora_mbs.invoke(objectName, "getCertificates", params, sign)
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

########################################################
#  getKeyStoreSecretKeyProperties 
########################################################

def getKeyStoreSecretKeyPropertiesImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = String(keypassword).toCharArray()
        params = [appStripe, name, pwd, alias, kpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
        list = None
        list = ora_mbs.invoke(objectName, "getSecretKeyProperties", params, sign)
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

########################################################
#  exportKeyStoreCertificateRequest 
########################################################

def exportKeyStoreCertificateRequestImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.io import FileOutputStream
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = String(keypassword).toCharArray()
        params = [appStripe, name, pwd, alias, kpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
        base64 = None
        base64 = ora_mbs.invoke(objectName, "exportCertificateRequest", params,sign)
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

########################################################
#  exportKeyStoreCertificate 
########################################################

def exportKeyStoreCertificateImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.io import FileOutputStream
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = None
        params = [appStripe, name, pwd, alias, kpwd, type]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C", "java.lang.String"]
        base64 = None
        base64 = ora_mbs.invoke(objectName, "exportCertificates", params,sign)
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

########################################################
#  importKeyStoreCertificate 
########################################################

def importKeyStoreCertificateImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.io import FileInputStream
    from jarray import zeros
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
        objectName = ora_mbs.makeObjectName(on)
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
        ora_mbs.invoke(objectName, "importCertificates", params,sign)
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

########################################################
#  deleteKeyStoreEntry 
########################################################

def deleteKeyStoreEntryImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        kpwd = String(keypassword).toCharArray()
        params = [appStripe, name, pwd, alias, kpwd]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "[C"]
        ora_mbs.invoke(objectName, "deleteKeyStoreEntry", params,sign)
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

########################################################
#  listExpiringCertificates 
########################################################

def listExpiringCertificatesImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.lang import Boolean
    from java.lang import Integer
    days = m.get("days")
    autorenew = m.get("autorenew")

    reqArgs = ArrayList()
    reqArgs.add("days")
    reqArgs.add("autorenew")
    validateRequiredArgs(m, reqArgs)

    try :
        objectName = ora_mbs.makeObjectName(on)
        tmp = Integer(days)
        numberOfDays = tmp.intValue()
        tmpbool = String(autorenew)
        tmp = Boolean(tmpbool)
        boolval = tmp.booleanValue()
        params = [numberOfDays, boolval]
        sign = ["int", "boolean"]
        outerlist = None
        outerlist = ora_mbs.invoke(objectName, "listExpiringCertificates", params,sign)
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
            print "Stripe = " + stripe
            print "Keystore = " + ksname
            print "Alias = " + alias
            print "Certificate status = " + status
            print "Expiration Date = " + expiry
            print '---------------------------------------------------'

########################################################
#  exportKeyStore 
########################################################

def exportKeyStoreImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.io import FileOutputStream
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        params = [appStripe, name, pwd, aliases, keypasswords, type]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String", "java.lang.String", "java.lang.String"]
        ksbytes = None
        ksbytes = ora_mbs.invoke(objectName, "exportKeyStore", params,sign)
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
            print msg + "\n"

########################################################
#  importKeyStore 
########################################################

def importKeyStoreImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList
    from java.lang import Boolean
    from jarray import zeros 
    from java.io import FileInputStream
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
        objectName = ora_mbs.makeObjectName(on)
        pwd = String(password).toCharArray()
        if (len(pwd) == 0):
            pwd = None
        tmpbool = String(permission)
        tmp = Boolean(tmpbool)
        boolval = tmp.booleanValue()

        fis = FileInputStream(filepath)
        num = fis.available()
        arr = zeros(num, 'b')
        fis.read(arr)
        fis.close()

        params = [appStripe, name, pwd, aliases, keypasswords, type, arr, boolval]
        sign = ["java.lang.String", "java.lang.String", "[C", "java.lang.String" , "java.lang.String", "java.lang.String", "[B", "boolean"]
        ora_mbs.invoke(objectName, "importKeyStore", params,sign)
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
        
########################################################
#  syncKeyStores 
########################################################
    
def syncKeyStoresImpl(m, on):
    from  oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
    from javax.management import MBeanException
    from java.util import ArrayList

    reqArgs = ArrayList()
    reqArgs.add("componentType")
    validateRequiredArgs(m, reqArgs)
    compType = m.get("componentType")
    compName = m.get("componentName")

    try :
        objectName = ora_mbs.makeObjectName(on)
        params = [compType, compName]
        sign = ["java.lang.String", "java.lang.String"]
        ora_mbs.invoke(objectName, "syncKeyStores", params, sign)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_SYNC_KS_DONE)
        print msg + "\n"
    except MBeanException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

########################################################
# ExportEncryptionKeyImpl
########################################################
def exportEncryptionKeyImpl(m):
    #Check for required arguments
    from oracle.security.jps.internal.tools.utility.cskey import ImportExportKeyUtility
    from jarray import array

    reqArgs = ArrayList()
    reqArgs.add("jpsConfigFile")
    reqArgs.add("keyFilePath")
    reqArgs.add("keyFilePassword")
    validateRequiredArgs(m, reqArgs)

    configFile = m.get("jpsConfigFile")
    keyFilePath   = m.get("keyFilePath")
    password   = m.get("keyFilePassword")

    carr = array(password,'c')

    try :
        ImportExportKeyUtility.exportFromBootStrapCred(keyFilePath, carr, configFile)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_EXPORT_CS_KEY_DONE)
        print msg + "\n"
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

########################################################
# ImportEncryptionKeyImpl
########################################################
def importEncryptionKeyImpl(m):
    #Check for required arguments
    from oracle.security.jps.internal.tools.utility.cskey import ImportExportKeyUtility
    from jarray import array

    reqArgs = ArrayList()
    reqArgs.add("jpsConfigFile")
    reqArgs.add("keyFilePath")
    reqArgs.add("keyFilePassword")
    validateRequiredArgs(m, reqArgs)

    configFile = m.get("jpsConfigFile")
    keyFilePath   = m.get("keyFilePath")
    password   = m.get("keyFilePassword")

    carr = array(password,'c')

    try :
        ImportExportKeyUtility.importToBootStrapCred(keyFilePath, carr, configFile)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_IMPORT_CS_KEY_DONE)
        print msg + "\n"        
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

########################################################
# restoreEncryptionKeyImpl
########################################################
def restoreEncryptionKeyImpl(m):
    #Check for required arguments
    from oracle.security.jps.internal.tools.utility.cskey import ImportExportKeyUtility

    reqArgs = ArrayList()
    reqArgs.add("jpsConfigFile")
    validateRequiredArgs(m, reqArgs)

    configFile = m.get("jpsConfigFile")

    try :
        ImportExportKeyUtility.restoreKey(configFile)
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_RESTORE_CS_KEY_DONE)
        print msg + "\n"
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise

########################################################
# upgradeOpssImpl
########################################################
def upgradeOpssImpl(m):
    from java.lang import Boolean
    from oracle.security.jps import JpsException
    from oracle.security.jps.upgrade.tools.utility import Upgrade

    print m

    jpsConfig = m.get("jpsConfig")
    jaznData = m.get("jaznData")
    auditStore = m.get("auditStore")
    jdbcDriver = m.get("jdbcDriver")
    url = m.get("url")
    user = m.get("user")
    password = m.get("password")
    upgradeJseStoreType = m.get("upgradeJseStoreType")
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


########################################################
# updateTrustServiceConfigImpl 
########################################################
def updateTrustServiceConfigImpl(m, on):
    from java.util import Properties
    from java.io import File
    from java.io import FileInputStream
    from oracle.security.jps.mas.mgmt.jmx.config import PortableMap    

    providerName = m.get("providerName")
    propsFile = m.get("propsFile")
    if (providerName is None) :
        providerName = "trust.provider.embedded"
    if (propsFile is None) :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_EMPTY_PROP_FILE)
        print msg
        raise Exception, msg

    props = Properties()
    props.load(FileInputStream(File(propsFile)))
    mp = PortableMap(props).toCompositeData(None)

    params = [None, providerName, mp]
    sign = ["java.lang.String", "java.lang.String", "javax.management.openmbean.CompositeData"] 
 
    try :
        o = ora_mbs.makeObjectName(on)
        ora_mbs.invoke(o, 'updateTrustServiceConfig', params, sign)
        ora_mbs.invoke(o, 'persist', None, None)
    except MBeanException, e:
          msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
          print msg + e.getLocalizedMessage() + "\n"
          raise e
    except :
          msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
          print msg
          raise


########################################################
# listSecurityStoreInfoImpl
########################################################
def listSecurityStoreInfoImpl(m) :
    #Check for required arguments
    from oracle.security.jps.tools.utility import JpsUtilListSecurityStoreInfoTool
    from oracle.security.jps import JpsException
    from java.util import ArrayList
    from java.lang import String
    from jarray import array

    reqArgs = ArrayList()
    reqArgs.add("domainConfig")
    validateRequiredArgs(m, reqArgs)

    configdir = m.get("domainConfig")

    try :
        infoMap = JpsUtilListSecurityStoreInfoTool.executeCommand(configdir)
        storeType = infoMap.get(JpsUtilListSecurityStoreInfoTool.STORE_TYPE)
        location = infoMap.get(JpsUtilListSecurityStoreInfoTool.LOCATION)
        username = infoMap.get(JpsUtilListSecurityStoreInfoTool.USER_NAME)
        storeTypeJse = infoMap.get(JpsUtilListSecurityStoreInfoTool.STORE_TYPE_JSE)
        locationJse = infoMap.get(JpsUtilListSecurityStoreInfoTool.LOCATION_JSE)
        usernameJse = infoMap.get(JpsUtilListSecurityStoreInfoTool.USER_NAME_JSE)
        print "For jps-config.xml"
        if (storeType != None):
            print "Store Type: " + storeType
        if (location != None):
            print "Location/Endpoint: " + location
        if (username != None):
            print "User: " + username
        print "For jps-config-jse.xml"
        if (storeTypeJse != None):
            print "Store Type: " + storeTypeJse
        if (locationJse != None):
            print "Location/Endpoint: " + locationJse
        if (usernameJse != None):
            print "User: " + usernameJse
    except JpsException, e:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
        print msg + e.getLocalizedMessage() + "\n"
        raise e
    except :
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_UNKNOWN_REASON)
        print msg
        raise
