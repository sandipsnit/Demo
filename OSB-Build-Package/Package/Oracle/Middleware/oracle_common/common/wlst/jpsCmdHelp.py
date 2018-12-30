#This file has the help for the jps commands
#Author: ktippann
#	  26/09/11 - palrao fixed bug 12992996 upgradeOpss on ldap store should accept username/password
#         06/09/11 - divyasin fixed bug 11898972
#         05/10/11 - divyasin fixed bugs 10629354 and 10430091
#         01/14/11 - divyasin fixed bug 10353017
#         12/15/10 - divyasin updated syntax of createResourceType to make displayName, description and allowedActions optional parameters
#         11/11/10 - divyasin updated prototypes of listAttributes and listFunctions to have the parameter unhideBuiltIn instead of hideBuiltIn
#         11/02/10 - Lappanmu Added help for migratePoliciestoXACML
#         10/27/10 - divyasin added help for commands introduced by dw ps1
#         06/28/10 - palrao fixed bug 9811709
#         01/26/10 - added resourcetype commands help  
#         12/23/08 -  Changes made to support migration of only application policices through WLST by rpoviding a switch.
#         11/19/08 - lappanmu fix for bug 7569747
#         10/31/08 - lappanmu fixed bug 7475438 
#         07/23/08 - vigarg added help for migrateSecurityStore
#         07/07/08 - vigarg added help for policy store mgmt commands 
#Creation 07/01/08

def deleteCredHelp() :
    print "     Descrption: Given a map name and key this command lets you delete a credential.\n \
    Required Arguments: map and key \n \
    Syntax: deleteCred.py -map <mapname> -key <keyname> \n \
    Example: deleteCred.py -map map1 -key key1  \n"
 
def listCredHelp() :
    print "    Description: Lists Credential information given map and key names. A generic credential will not be listed.\n" \
          "    Syntax: listCred.py -map <map name> -key <key name> \n"\
          "    Example:listCred.py -map myMap -key myKey \n"

def createAdminRoleHelp() :
    print "    Description: Create a new Admin role with the given name. \n"\
          "    Syntax: createAdminRole.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> [-policyDomainName <policy domain name>] [-displayName <display name for admin role>] [-description <description for admin role>]\n"\
          "    Example: createAdminRole.py -appStripe myApplication -adminRoleName myAdminRole -policyDomainName myPolicyDomain -displayName MyAdminRole -description \"My first Resource type\" \n"
          
def deleteAdminRoleHelp() :
    print "    Description: Delete an admin role with the specified name. \n"\
          "    Syntax: deleteAdminRole.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> [-policyDomainName <policy domain name>]\n"\
          "    Example: deleteAdminRole.py -appStripe myApplication -adminRoleName myAdminRole -policyDomainName myPolicyDomain \n"

def listAdminRolesHelp() :
    print "    Description: List all admin roles defined in a given application/policy domain. \n"\
          "    Syntax: listAdminRoles.py [-appStripe <application stripe name>] [-policyDomainName <policy domain name>]\n"\
          "    Example: listAdminRoles.py -appStripe myApplication -policyDomainName myPolicyDomain \n"


def listAdminRoleMembersHelp() :
    print "    Description: Lists the principals granted to this administration role. \n"\
          "    Syntax: listAdminRoleMembers.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> [-policyDomainName <policy domain name>]\n"\
          "    Example: listAdminRoleMembers.py -appStripe myApplication -adminRoleName myAdminRole -policyDomainName myPolicyDomain \n"

def grantAdminRoleHelp() :
    print "    Description: Grant an Admin Role rights to a given principal. \n"\
          "    Syntax: grantAdminRole.py [appStripe <application stripe name>] -adminRoleName <new admin role name> -principalClass <member principal class> -principalName <member principal name>[-policyDomainName <policy domain name>]\n"\
          "    Example: grantAdminRole.py -appStripe myApplication -adminRoleName myAdminRole -principalClass com.example.xyzPrincipal -principalName manager -policyDomainName myPolicyDomain \n"

def revokeAdminRoleHelp() :
    print "    Description: Revoke an Admin Role rights from a given principal. \n"\
          "    Syntax: revokeAdminRole.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> -principalClass <member principal class> -principalName <member principal name>[-policyDomainName <policy domain name>]\n"\
          "    Example: revokeAdminRole.py -appStripe myApplication -adminRoleName myAdminRole -principalClass com.example.xyzPrincipal -principalName manager -policyDomainName myPolicyDomain \n"

def grantAdminResourceHelp() :
    print "    Description: Grant administrative resource actions to an admin role. \n"\
          "    Syntax: grantAdminResource.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> -adminResource <admin resource name> -action<admin action name> [-policyDomainName <policy domain name>]\n"\
          "    Example: grantAdminResource.py -appStripe myApplication -adminRoleName myAdminRole -adminResource APPLICATION_POLICY -action ALL(\"*\") -policyDomainName myPolicyDomain \n"


def revokeAdminResourceHelp() :
    print "    Description: Revoke Administrative resource actions from an admin role. \n"\
          "    Syntax: revokeAdminResource.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> -adminResource <admin resource name> -action<admin action name> [-policyDomainName <policy domain name>]\n"\
          "    Example: revokeAdminResource.py -appStripe myApplication -adminRoleName myAdminRole -adminResource APPLICATION_POLICY -action ALL(\"*\") -policyDomainName myPolicyDomain \n"


def listAdminResources() :
    print "    Description: Lists the Administrative resource actions for an admin role. \n"\
          "    Syntax: listAdminResources.py [-appStripe <application stripe name>] -adminRoleName <new admin role name> [-policyDomainName <policy domain name>]\n"\
          "    Example: listAdminResources.py -appStripe myApplication -adminRoleName myAdminRole -policyDomainName myPolicyDomain \n"


def createResourceTypeHelp() :
    print "    Description: Creates a ResourceType in a given application \n"\
          "    Syntax: createResourceType.py -appStripe <application stripe name> -resourceTypeName <new resourcetype name> [-displayName <display name for this resourcetype>] [-description <description for this resource type>] [-provider <provider for this resourcetype>] [-matcher<matcher class of this resource type>] [-allowedActions<comma separated list of allowed actions for this resource type> [-delimiter <delimiter of this applicaiton>]]\n"\
          "    Example: createResourceType.py -appStripe myApplication -resourceTypeName MyResourceType -displayName MyResource -description \"My first Resource type\" -provider xyz -matcher abc -allowedActions read,write -delimiter \",\" \n"

def createFunctionHelp() :
    print "    Description: Creates a function in a given application. \n"\
          "    Syntax: createFunction.py -appStripe <application stripe name> -functionName <Name of the function> [-displayName <diplay name>] [-description <description of the function>] -className <Name of the class to which the function belongs> -returnType <Return type of the function> [-paramTypes <Parameter types of the function delimited by ','>]\n"\
          "    Example: createFunction.py -appStripe myApplication -functionName MyFunction -displayName CONCATENATE -description \"A function representing concatenate operation on string\" -className MyClass -returnType oracle.security.jps.service.policystore.info.OpssString -paramTypes oracle.security.jps.service.policystore.info.OpssString,oracle.security.jps.service.policystore.info.OpssString \n"

def updateFunctionHelp() :
    print "    Description: Updates a function in a given application.\n"\
          "    Syntax: updateFunction.py -appStripe <application stripe name> -functionName <Name of the function> [-displayName <diplay name>] [-description <description of the function>] [-className <Name of the class to which the function belongs>] [-returnType <Return type of the function>] [-paramTypes <Parameter types of the function delimited by ','>]\n"\
          "    Example: updateFunction.py -appStripe myApplication -functionName MyFunction -displayName CONCATENATE -description \"A function representing concatenate operation on string\" -className MyClass -returnType oracle.security.jps.service.policystore.info.OpssString -paramTypes oracle.security.jps.service.policystore.info.OpssString,oracle.security.jps.service.policystore.info.OpssString\n"

def getFunctionHelp() :
    print "    Description: Prints a function in a given application.\n"\
          "    Syntax: getFunction.py -appStripe <application stripe name> -functionName <Name of the function>\n"\
          "    Example: getFunction.py -appStripe myApplication -functionName MyFunction\n"

def listFunctionsHelp() :
    print "    Description: Lists the functions present in a given application.\n"\
          "    Syntax: listFunctions.py -appStripe <application stripe name> [-hideBuiltIn <whether to hide built in functions>]\n"\
          "    Example: listFunctions.py -appStripe myApplication -hideBuiltIn true\n"

def deleteFunctionHelp() :
    print "    Description: Deletes a function in a given application.\n"\
          "    Syntax: deleteFunction.py -appStripe <application stripe name> -functionName <Name of the function>\n"\
          "    Example: deleteFunction.py -appStripe myApplication -functionName MyFunction\n"

def createAttributeHelp() :
    print "    Description: Creates an attribute for a given application. Default attributes are not supported.\n"\
          "    Syntax: createAttribute.py -appStripe <application stripe name> -attributeName <Name of the attribute> [-displayName <diplay name>] [-description <description of the attribute>] -type <class name of type> -category <either 'Dynamic' or 'Resource'> [-isSingle <whether attribute is single valued or not>] [-values <initial values of the attribute delimited by ','>]\n"\
          "    Example: createAttribute.py -appStripe myApplication -attributeName MyAttribute -displayName MyDisplayName -description MyDescription -type string -category dynamic -isSingle true -values sampleValue\n"

def updateAttributeHelp() :
    print "    Description: Updates an attribute for a given application. Default attributes are not supported.\n"\
          "    Syntax: updateAttribute.py -appStripe <application stripe name> -attributeName <Name of the attribute> [-displayName <diplay name>] [-description <description of the attribute>] [-values <initial values of the attribute delimited by ','>]\n"\
          "    Example: updateAttribute.py -appStripe myApplication -attributeName MyAttribute -displayName MyDisplayName -description MyDescription -values sampleValue1,sampleValue2\n"

def listAttributesHelp() :
    print "    Description: Lists the attributes present in a given application.\n"\
          "    Syntax: listAttributes.py -appStripe <application stripe name> [-hideBuiltIn <whether to hide built in attributes>]\n"\
          "    Example: listAttributes.py -appStripe myApplication -hideBuiltIn true\n"

def deleteAttributeHelp() :
    print "    Description: Deletes an attribute for a given application.\n"\
          "    Syntax: deleteAttribute.py -appStripe <application stripe name> -attributeName <Name of the attribute>\n"\
          "    Example: deleteAttribute.py -appStripe myApplication -attributeName MyAttribute\n"

def updateResourceTypeHelp() :
    print "    Description: Updates a ResourceType for a given application.\n"\
          "    Syntax: updateResourceType.py -appStripe <application stripe name> -resourceTypeName <Name of the ResourceType> [-displayName <diplay name>] [-description <description of the ResourceType>] [-allowedActions <Allowed set of actions for ResourceType>] [-delimiter <delimiter for the ResourceType>] [-attributes <list of names of attributes>] [-provider <Provider of the ResourceType>] [-matcher <Matcher class for ResourceType>] [-hierarchicalResource <flag showing whether the resource type supports hierarchical resources> [-resourceNameDelimiter <delimiter for names of hierarchical resources>]]\n"\
          "    Example: updateResourceType.py -appStripe myApplication -resourceTypeName Printer -displayName PRINTER -description \"A ResourceType representing a Printer\" -allowedActions BWPrint,ColorPrint -delimiter \",\" -attributes attr1,attr2 -provider Printer -matcher com.printer.Printer -hierarchicalResource true -resourceNameDelmiter \\n"

def updateResourceHelp() :
    print "    Description: Updates Resource with the given resource name and resource type.\n"\
          "    Syntax: updateResource.py -appStripe <application stripe id> -resourceName <resourceName> -type <resourceType> [-displayName <displayName>] [-description <description>] [-attributes <list of attributes>]\n"\
          "    Example: updateResource.py -appStripe PsApp -resourceName sampleresource -type sampleRType -displayName SampleResource -description \"resource for a sample resource type\" -attributes singleValAttr:value;multiValAttr:value1,value2;-toRemoveAttr\n"

def createApplicationPolicyHelp() :
    print "    Description: Creates an application policy with the given name.\n"\
          "    Syntax: createApplicationPolicy.py -appStripe <application stripe name>\n"\
          "    Example: createApplicationPolicy.py -appStripe myApplication\n"

def createPolicyHelp() :
    print "    Description: Creates a policy for a given application.\n"\
          "    Syntax: createPolicy.py -appStripe <application stripe name> -policyName <Name of the policy> [-displayName <diplay name>] [-description <description of the policy>] -ruleExpression <rule expression to be evaluated for policy decision> {-entitlements <comma-separated permission set entry name(s)> | -resourceActions <comma-separated list of resource action(s)>} {-principals <comma-separated list of principals> | -codeSource <code-source as a string>} [-obligations <comma-separated list of obligations>] [-semantic <policy semantic>]\n"\
          "    Example: createPolicy.py -appStripe myApplication -policyName MyPolicy -displayName MyDisplayName -description MyDescription -ruleExpression \"rule1:grant: !(abc > -1162) && (c==2)&& (\"a String\" == aString)\" -resourceActions \"resType1:res1(act1, act2),resType2:res2(act1)\" -principals admin:com.example.MyPrincipal -obligations ob1(attr1,str1:\"a String\"),ob2(a2:attr2) -semantic or\n"

def updatePolicyHelp() :
    print "    Description: Updates a policy for a given application.\n"\
          "    Syntax: updatePolicy.py -appStripe <application stripe name> -policyName <Name of the policy> [-displayName <diplay name>] [-description <description of the policy>] [-ruleExpression <rule expression to be evaluated for policy decision>] [-entitlements <comma-separated permission set entry name(s)> | -resourceActions <comma-separated list of resource action(s)>] [-principals <comma-separated list of principals> | -codeSource <code-source as a string>] [-obligations <comma-separated list of obligations>]\n"\
          "    Example: updatePolicy.py -appStripe myApplication -policyName MyPolicy -displayName MyDisplayName -description MyDescription -ruleExpression \"rule1:grant: !(abc > -1162) && (c==2)&& (\"a String\" == aString)\" resourceActions resType1:res1(act1,act2),resType2:res2(act1) -principals admin:com.example.MyPrincipal -obligations ob1(attr1,str1:\"a String\"),ob2(a2:attr2) \n"

def listPoliciesHelp() :
    print "    Description: Lists the policies present in a given application.\n"\
          "    Syntax: listPolicies.py -appStripe <application stripe name>\n"\
          "    Example: listPolicies.py -appStripe myApplication\n"

def deletePolicyHelp() :
    print "    Description: Deletes a policy for a given application.\n"\
          "    Syntax: deletePolicy.py -appStripe <application stripe name> -policyName <Name of the policy>\n"\
          "    Example: deletePolicy.py -appStripe myApplication -policyName MyPolicy\n"

def getResourceTypeHelp() :
    print "    Description: Prints a ResourceType with the given name from a given application \n"\
          "    Syntax: getResourceType.py -appStripe <application stripe name> -resourceTypeName <new resourcetype name>\n"\
          "    Example: getResourceType.py -appStripe myApplication -resourceTypeName MyResourceType \n"

def deleteResourceTypeHelp() :
    print "    Description: Delete a ResourceType with the given name from a given application \n"\
          "    Syntax: deleteResourceType.py -appStripe <application stripe name> -resourceTypeName <new resourcetype name>\n"\
          "    Example: deleteResourceType.py -appStripe myApplication -resourceTypeName MyResourceType \n"

def createAppRoleHelp() :
    print "    Description: Creates an application Role for a given application \n"\
          "    Syntax: createAppRole.py -appStripe <application stripe name> -appRoleName <new application role name> \n"\
          "    Example: createAppRole.py -appStripe myApplication -appRoleName appAdministrator \n"

def deleteAppRoleHelp() :
    print "    Description: Deletes a given application Role for a given application \n"\
          "    Syntax: deleteAppRole.py -appStripe <application stripe name>  -appRoleName <application role name to be deleted> \n"\
          "    Example: deleteAppRole.py -appStripe myApplication -appRoleName appAdministrator \n"

def grantAppRoleHelp() :
    print "    Description: grants an application Role to a given principal \n"\
          "    Syntax: grantAppRole.py -appStripe <application stripe name> -appRoleName <application role name> -principalClass <member principal class> -principalName <member principal name> \n"\
          "    Example: grantAppRole.py -appStripe myApplication -appRoleName appAdministrator -principalClass com.example.xyzPrincipal -principalName manager \n"

def revokeAppRoleHelp() :
    print  "    Description: revokes an application Role from a given application \n"\
           "    Syntax: revokeAppRole.py -appStripe <application stripe name> -appRoleName <application role name> -principalClass <member principal class> -principalName <member principal name> \n"\
           "    Example: revokeAppRole.py -appStripe myApplication -appRoleName appAdministrator -principalClass com.example.xyzPrincipal -principalName manage \n"

def grantPermissionHelp() :
    print   "    Description: grant permission to a principal in application scoped/ global policies \n"\
            "    Syntax: grantPermission.py [-appStripe <application stripe if aplication policy>] [-codeBaseURL <url of code base if code based permissions>] [-principalClass <principal class> -principalName <principal name>] -permClass <permission class> [-permTarget <permission name/target if applicable>] [-permActions <comma separated perm actions>] \n"\
            "    Example1: grant permission to a principal in application policies: \n"\
            "              grantPermission.py -appStripe myApplication -principalClass oracle.security.jps.service.policystore.ApplicationRole -principalName appAdministrator -permClass java.security.AllPermission \n"\
            "    Example2: grant permission to a principal in global policies: \n"\
            "              grantPermission.py -principalClass oracle.security.jps.internal.core.principals.JpsXmlEnterpriseRoleImpl -principalname manager -permClass java.io.FilePermission -permTarget /resources/- permActions read,write \n"

def revokePermissionHelp() :
    print   "    Description: revoke permission from a principal in application scoped/global policies \n"\
            "    Syntax: revokePermission.py [-appStripe <application stripe if aplication policy>] [-codeBaseURL <url of code base if code based permissions>] [-principalClass <principal class> -principalName <principal name>] -permClass <permission class> [-permTarget <permission name/target if applicable>] [-permActions <comma separated perm actions>] \n"\
            "    Example1: revoke permission from a principal in application policies: \n"\
            "              revokePermission.py -appStripe myApplication -principalClass oracle.security.jps.service.policystore.ApplicationRole -principalName appAdministrator -permClass java.security.AllPermission \n"\
            "    Example2: revoke permission from a principal in global policies: \n"\
            "              revokePermission.py -principalClass oracle.security.jps.internal.core.principals.JpsXmlEnterpriseRoleImpl -principalName manager -permClass java.io.FilePermission -permTarget /resources/- permActions read,write \n"

def listAppRolesHelp() :
    print   "    Description: lists all application roles defined in a given application \n"\
            "    Syntax: listAppRoles.py -appStripe <application stripe name> \n"\
            "    Example: listAppRoles.py -appStripe myApplication \n"

def listPermissionsHelp() :
    print   "    Description: lists permissions assigned to the given principal in application scoped/ global policies \n"\
            "    Syntax: listPermissions.py [-appStripe <application stripe if aplication policy>] -principalClass <principal class> -principalName <principal name>\n"\
            "    Example1: list permissions assigned to a principal in application policies: \n"\
            "            listPermissions.py -appStripe myApplication -principalClass oracle.security.jps.service.policystore.ApplicationRole -principalName appAdministrator \n"\
            "    Example2: list permissions assigned to a principal in global policies: \n"\
            "           listPermissions.py -principalClass weblogic.security.principal.WLSGroupImpl -principalName Administrators  \n"

def listCodeSourcePermissionsHelp() :
    print   "    Description: lists permissions assigned to the given code source in application scoped/ global policies \n"\
            "    Syntax: listCodeSourcePermissions.py [-appStripe <application stripe if aplication policy>] -codeBaseURL <url of code base> \n"\
            "    Example1: list permissions assigned to a code source in application policies: \n"\
            "            listCodeSourcePermissions.py -appStripe myApplication -codeBaseURL file:/tmp/bea/user_projects/domains/jpsdomain/lib/jps-internal.jar \n"\
            "    Example2: list permissions assigned to a code source in global policies: \n"\
            "            listCodeSourcePermissions.py -codeBaseURL file:/tmp/bea/user_projects/domains/jpsdomain/lib/jps-internal.jar \n"
    
def listAppRoleMembersHelp() :
    print   "    Description: list members of an application role \n"\
            "    Syntax: listAppRoleMembers.py -appStripe <application stripe name> -appRoleName <application role name> \n"\
            "    Example: listAppRoleMembers.py -appStripe myApplication -appRoleName appAdministrator \n"

def deleteAppPolicyHelp():
    print "    Description: delete policies specific to an application. \n"\
          "    Syntax: deleteAppPolicies.py -appStripe <application stripe name> \n"\
          "    Example: deleteAppPolicies.py -appStripe myApplication \n"         

def MigrateSecurityStoreHelp() :
    print   "Syntax: \n"\
            "migrateSecurityStore.py -type {credStore|policyStore|keyStore|globalPolicies}  -configFile <jps config file loc> -src sourceContext -dst destinationContext [-migrateIdStoreMapping  {true|false}] [-preserveAppRoleGuid {true|false}]\n"\
            "migrate identity store \n"\
            "migrateSecurityStore -type idStore -configFile <jps config file loc> -src sourceContext -dst destinationContext [-dstLdifFile LDIFFilePath] \n"\
            "migrate application specific policies \n"\
            "migrateSecurityStore -type appPolicies  -configFile <jps config file loc> -src sourceContext, -dst destinationContext, -srcApp sourceApplication [-dstApp destinationApplication,] [-overWrite {true|false}] [-migrateIdStoreMapping {true|false}]  [-preserveAppRoleGuid {true|false}] [-mode {lax}]  [-reportFile <report file location>] \n"\
            "migrate folder specific credentials \n"\
            "migrateSecurityStore -type folderCred [-srcFolder srcFolderName] [-srcConfigFile srcConfigFileLocation]  -configFile <jps config file loc> -src sourceContext -dst destinationContext [-dstFolder dstFolderName] [-overWrite {true|false}] \n"\
            "migrate stripe specific keystores \n"\
            "migrateSecurityStore -type stripeKeyStore [-srcStripe srcStripeName] [-srcConfigFile srcConfigFileLocation]  -configFile <jps config file loc> -src sourceContext -dst destinationContext [-dstStripe dstStripeName] [-overWrite {true|false}] \n"\
            "\n\n"\
            "DESCRIPTION \n"\
            "migrates identity store/ credential store/ policy store/ keystores/ application policies /global policies from one store to another.\n"\
            "The source store as well as the destination store could be of any type as defined by context.\n"\
            "In case of scope being idStore, if the destination store is of LDAP(OID/Embeded LDAP) type, and LDIF file will be created, at the defined location.\n"\
            "Entries will not be directly written to the LDAP server.\n"\
            "In case of scope being appPolicies, if migrateIdStoreMapping is false, then only application specific policies are migrated ignoring all identity store artifacts.\n"\
            "\n\n"\
            "EXAMPLES \n"\
            "This command will migrate identity store data to another identity store.\n"\
            "migrateSecurityStore -type idStore -configFile /folder/jps-config.xml -src sourceContext -dst destinationContext \n"\
            "\n"\
            "This command will migrate application specific policies in policy store to another policy store \n"\
            "migrateSecurityStore -type appPolicies -configFile /folder/jps-config.xml -src sourceContext -srcApp sourceApplication -dstApp destinationApplication -dst destinationContext \n"\
            "This command will migrate only application policies in policy store to another policy store ignoring the identity store artifacts \n"\
            "migrateSecurityStore -type appPolicies -configFile /folder/jps-config.xml -src sourceContext -srcApp sourceApplication -dstApp destinationApplication -dst destinationContext -migrateIdStoreMapping false \n"
             
def UpgradeSecurityStoreHelp() :
    print  "syntax:\n"\
           "\n\n"\
           "upgrade XML identity store from 10.1.x to 11.1.1.1.0\n"\
           "upgradeSecurityStore.py -type xmlIdStore -jpsConfigFile <jps config file loc> -srcRealm <realm name> -srcJaznDataFile dataFile [-dst destinationContext]\n"\
           "upgrade XML policy store from 10.1.x to 11.1.1.1.0\n"\
           "upgradeSecurityStore.py -type xmlPolicyStore -jpsConfigFile <jps config file loc> -srcJaznDataFile dataFile  [-dst destinationContext]\n"\
           "upgrade OID policy store from 10.1.x to 11.1.1.1.0\n"\
           "upgradeSecurityStore.py -type oidPolicyStore -jpsConfigFile <jps config file loc> -srcJaznConigfFile configFile [-dst destinationContext]\n"\
           "upgrade XML credential store from 10.1.x to 11.1.1.1.0\n"\
           "upgradeSecurityStore.py -type xmlCredStore -jpsConfigFile <jps config file loc> -srcJaznDataFile dataFile -users realm1/user1,realm2/user2,.. [-dst destinationContext]\n"\
           "upgrade XML based application policies from 11.1.1.1.0 to 11.1.1.2.0\n"\
           "upgradeSecurityStore.py -type xmlAppPolicies -srcApp <applicationName> -jpsConfigFile <filepath> -srcJaznDataFile <dataFile> -dstJaznDataFile <dataFile> -resourceTypeFile <dataFile>\n"\
           "upgrade application policies in 11.1.1.1.0 based policy store to 11.1.1.2.0 format. The upgrade happens in-place and involves creation of resources corresponding to permissions\n"\
           "upgradeSecurityStore.py -type appPolicies [-srcApp <applicationName> -dst <destinationContext> -jpsConfigFile <filepath>].\n"\
           "\n"\
           "DESCRIPTION\n"\
           "\n\n"\
           "Migrates identity store/ policy store/credantial data from a one version based store to another version based store.\n"\
           "The destination store could be of any type as defined by the context. Source store is defined by the file location or in case of oidPolicyStore, by a config file where the policy store is configured.\n"\
           "\n"\
           "EXAMPLES\n"\
           "\n\n"\
           "This command will migrate 10.1.3 xml identity store data to a 11.1.1.1.0 xml identity store.\n"\
           "upgradeSecurityStore.py -type xmlIdStore -jpsConfigFile /folder/jps-config.xml -srcJaznDataFile /jazn-data.xml -srcRealm jazn.com -dst destinationContext\n"\
           "This command will migrate policies in 10.1.3 xml policy store to 11.1.1.1.0 policy store.\n"\
           "upgradeSecurityStore.py -type xmlPolicyStore -jpsConfigFile /folder/jps-config.xml -srcJaznDataFile /jazn-data.xml -dst destinationContext\n"\
           "This command will migrate policies in 10.1.3 OID policy store to 11.1.1.1.0 policy store.\n"\
           "upgradeSecurityStore.py -type oidPolicyStore -jpsConfigFile /folder/jps-config.xml -srcJaznConfigFile /jazn.xml -dst destinationContext\n"\
           "This command will migrate application policies in 11.1.1.1.0 XML policy store to 11.1.1.2.0 policy store\n"\
           "upgradeSecurityStore.py -type xmlAppPolicies -srcApp myApp -jpsConfigFile /folder/jps-config.xml -srcJaznDataFile /jazn-data.xml -dstJaznDataFile /dst/jazn-data.xml -resourceTypeFile /res/jazn-data.xml\n"\
           "This command will upgrade application policies in 11.1.1.1.0 based policy store to 11.1.1.2.0 format.\n"\
           "upgradeSecurityStore.py -type appPolicies, -srcApp myApp', -dst myContext -jpsConfigFile /folder/jps-config.xml.\n"\

def patchPolicyStoreHelp():
    print "Syntax: \n"\
          "\n\n"\
          "In analysis phase:\n"\
          "patchPolicyStore.py -phase analyze -baselineFile <location of file> -patchFile <location of file> -productionJpsConfig <location of file> -patchDeltaFolder <location of the folder> -baselineAppStripe <name of application stripe> [-productionAppStripe <name of application stripe>] [-patchAppStripe <name of application stripe>] [-ignoreEnterpriseMembersOfAppRole <boolean to indicate whether to generate the app role to enterprise relationship or not>] [-reportFile <location of report file>][-ignoreEnterpriseAppRoleMembershipConflicts <boolean to indicate whether to ignore the enterprise app role to membership conflicts or not>]"\
          "\n"\
          "In apply phase:\n"\
          "patchPolicyStore.py -phase apply -patchDeltaFolder <location of folder> -productionJpsConfig <location of file> -productionAppStripe <name of application stripe>"\
          "\n\n"\
          "DESCRIPTION\n"\
          "\n"\
          "Patches the production policy store with the changes introduced by new version of the policy store shipped. If such changes conflict with the customizations done in production, the conflicts are reported for the user to make decisions and apply accordingly.\n"\
          "The command has to be run in two phases: analyze and apply.\n"\
          "EXAMPLES\n"\
          "The following invocation reports changes to in the directory /tmp/delta:\n"\
          "patchPolicyStore.py -phase analyze -baselineFile /tmp/baseline/jazn-data.xml -patchFile /tmp/new/jazn-data.xml, -productionJpsConfig /tmp/jps-config.xml -patchDeltaFolder /tmp/delta -baselineAppStripe theOldApplication -productionAppStripe myApplication -patchAppStripe theNewApplication -ignoreEnterpriseMembersOfAppRole true \n"\
          "The following invocation applies the changes found in /tmp/delta to the policies in the stripe myApp of the LDAP domain store pointed to by the default context in the file /tmp/jps-config.xml:\n"\
          "patchPolicyStore.py -phase apply -patchDeltaFolder /tmp/delta -productionJpsConfig /tmp/jps-config.xml -productionAppStripe myApp\n"\
          "Alternatively -silent switch can also be used in conjunction with analyze mode. When this swtich is turned on during analyze mode and if analyze does not report any conflicts then, the changes are directly applied the policies in the stripe myApp of the LDAP domain store pointed to by the default context in the file /tmp/jps-config.xml:\n"\
          "patchPolicyStore.py -phase analyze -patchDeltaFolder /tmp/delta -productionJpsConfig /tmp/jps-config.xml -productionAppStripe myApp -silent true\n"\

def createResourceHelp() :
    print "    Description: Creates a Resource for a given resource name and resource type.\n"\
          "    Syntax: createResource.py -appStripe <application stripe id> -name <resourceName> -type <resourceType> [-displayName <displayName> -description <description>] \n"\
          "    Example: createResource.py -appStripe PsApp -name sampleresource -type sampleRType -displayName SampleResource -description \"resource for a sample resource type\" \n"

def getResourceHelp() :
    print "    Description: Prints the Resource of a given ResourceType. \n"\
          "    Syntax: getResource.py -appStripe <application stripe name> -name <resourceName> -type <Name of the ResourceType>\n"\
          "    Example: getResource.py  -appStripe myApplication -name LexPrinter -type Printer  \n"

def deleteResourceHelp() :
    print "    Description: Deletes the Resource of a given ResourceType. \n"\
          "    Syntax: deleteResource.py -appStripe <application stripe name> -name <Name of the Resource> -type <Name of the ResourceType> \n"\
          "    Example: deleteResource.py -appStripe myApplication -name LexPrinter -type Printer \n"
 

def listResourcesHelp() :
    print "    Description: Lists all the Resources of a given ResourceType.If the ResourceType is not mentioned then it lists all the Resources for the application policy.\n"\
          "    Syntax: listResources.py -appStripe <application stripe id>  -type <resourceType>  \n"\
          "    Example: listResources.py -appStripe myApplication  -type sampleRType  \n"

def listResourceActionsHelp() :
    print "    Description: Lists all the resource actions of a given EntitlementSet.\n"\
          "    Syntax: listResourceActions.py -appStripe <application stripe id>  -entitlementName <Name of the Entitlement>  \n"\
          "    Example: listResourceActions.py -appStripe myApplication  -entitlementName sampleEntitlement  \n"

def createEntitlementHelp() :
    print "    Description: Creates an Entitlement for a given Resource.\n"\
          "    Syntax: createEntitlement.py -appStripe <application stripe id>  -name <Name of the Entitlement>  -resourceName <resourceName> -resourceType <resourceTypeName> [-actions <actions> -displayName <displayName> -description <description>] \n"\
          "    Example: createEntitlement.py -appStripe myApplication  -name sampleESet -resourceName sampleResource -resourceType sampleRType -actions \"read,write\" -displayName SampleEntitlementSet -description \"entitlement set with sample resource\"  \n"

def getEntitlementHelp() :
    print "    Description: Prints the Entitlement of the given application stripe.\n"\
          "    Syntax: getEntitlement.py -appStripe <application stripe id>  -name <Name of the EntitlementSet> \n"\
          "    Example: getEntitlement.py -appStripe myApplication  -name sampleESet  \n"

def deleteEntitlementHelp() :
    print "    Description: Deletes the given Entitlement.\n"\
          "    Syntax: deleteEntitlement.py -appStripe <application stripe id>  -name <Name of the EntitlementSet> \n"\
          "    Example: deleteEntitlement.py -appStripe myApplication  -name sampleESet  \n"

def listEntitlementsHelp() :
    print "    Description: Lists all the Entitlements of the specified Resource and ResourceType.If the Resource and ResourceType is not specified then it lists all the EntitlementSets of the application policy.\n"\
          "    Syntax: listEntitlements.py -appStripe <application stripe id>  [-resourceTypeName <Name of the ResourceType> -resourceName <Name of the Resource>] \n"\
          "    Example: listEntitlements.py -appStripe myApplication  -resourceTypeName Printer -resourceName LexPrinter  \n"

def addResourceToEntitlementHelp() :
    print "    Description: Adds Resource to Entitlement.\n"\
          "    Syntax: addResourceToEntitlement.py -appStripe <application stripe id>  -name <Name of the Entitlement>  -resourceName <Name of the Resource> -resourceType <Name of the ResourceType> -actions <actions> \n"\
          "    Example: addResourceToEntitlement.py -appStripe myApplication  -name sampleESet  -resourceName LexPrinter -resourceType sampleRType -actions \"read,write\" \n"


def revokeResourceFromEntitlementHelp() :
    print "    Description:Revokes Resource from a Entitlement. \n"\
          "    Syntax: revokeResourceFromEntitlement.py -appStripe <application stripe id> -name <Name of the Entitlement>  -resourceName <Name of the Resource> -resourceType <Name of the ResourceType>  -actions <actions>\n"\
          "    Example: revokeResourceFromEntitlement.py -appStripe myApplication -name sampleESet -resourceName LexPrinter -resourceType Printer -actions \"read,write\"  \n"

def grantEntitlementHelp() :
    print "    Description: Grant an Entitlement to a given principal. \n"\
          "    Syntax: grantEntitlement.py -appStripe <application stripe name> -principalClass <principalClass> -principalName <principalName> -entitlementName <entitlementName>\n"\
          "    Example: grantEntitlement.py -appStripe myApplication -principalClass com.sample.xyzprincipal -principalName samplePrincipal -entitlementName sampleESet  \n"

def revokeEntitlementHelp() :
    print "    Description: Revoke Entitlement from a given principal. \n"\
          "    Syntax: revokeEntitlement.py -appStripe <application stripe name> -principalClass <principalClass> -principalName <principalName> -entitlementName <entitlementName>\n"\
          "    Example: revokeEntitlement.py -appStripe myApplication -principalClass com.sample.xyzprincipal -principalName samplePrincipal -entitlementName sampleESet  \n"


def listResourceTypesHelp() :
    print "    Description:  Lists all the ResourceTypes for a given application stripe.\n"\
          "    Syntax: listResourceTypes.py -appStripe <application stripe name>  \n"\
          "    Example: listResourceTypes.py -appStripe myApplication  \n"


def listAppStripesHelp() :
    print "    Description: Lists all the app stripes in a policy store configured in the config file. If the regular expression is mentioned, it lists all the app stripes matching the regular expression.If the config file is not mentioned then the command expects to be connected to a server.\n"\
          "    Syntax: listAppStripes.py [-configFile <Location of jps-config file>, -regularExpression <regular expression>]\n"\
          "    Example: listAppStripes.py -configFile jps-config.xml -regularExpression .\n"

def upgradeHelp():
    print "Syntax: upgradeOpss.py -jpsConfig <full path filename for jps-config.xml> -jaznData <full path filename for  OOTB JAZN data file> [-auditStore <full path filename for OOTB audit-store.xml file> -jdbcDriver <jdbc driver> -url <jdbc/ldap url> -user <jdbc/ldap user> -password <jdbc/ldap password> -upgradeJseStoreType <true | false>]\n"\
          "Description: Upgrade jps-config.xml, policy store and audit store \n"\
          "Example: upgradeOpss.py -jpsConfig /config/jps-config.xml -jaznData /upgrade/system-jazn-data.xml -auditStore /upgrade/audit-store.xml -jdbcDriver oracle.jdbc.driver.OracleDriver -url jdbc:oracle:thin:@localhost:5521:testdb -user opss -password welcome -upgradeJseStoreType true \n"

def migratePoliciesToXacmlHelp():
    print "    Description: migrate OPSS Policies from any supported PolicyStore like XML,LDAP or DB to XACML. \n"\
          "    Syntax: migratePoliciesToXacml.py -src <source context> -dst <destination context> -srcApp <source application name> [-dstApp <destination application name> ] -configFile <Location of Configuration file> \n"\
          "    Example: migratePoliciesToXacml.py -src srcContext -dst dstContext -srcApp PsTestApp -dstApp NewApp -configFile /config/jps-config.xml \n"  

def listSecurityStoreInfoHelp() :
    print "    Description: Lists the store-type, location and user-name.\n"\
          "    Syntax: listSecurityStoreInfo.py -domainConfig <absolute path of config directory>\n"\
          "    Example: -domainConfig /net/adc2110085/scratch/divyasin/view_storage/divyasin_entsec_config/work/utp/testout/functional/jps/wls-jrfServer/config/fmwconfig\n"

from java.util import Locale
from java.util import ResourceBundle
from oracle.security.jps import WlstResources

opss_resourceBundle = ResourceBundle.getBundle("oracle.security.jps.WlstResources", Locale.getDefault(), WlstResources.getClassLoader())

def verifyArgs(required, optional, args):
    if (len(args) >= 1):
        if (args[0] == "-help" or args[0] == "-h"):
            return None

    isval = False
    opcode = None
    argmap = {}
    for i in range(len(args)):
        #Expecting a parameter.
        if not isval:
            #Is the parameter recognized?
            if ((args[i] in required) or (args[i] in optional)):
                opcode = args[i].lstrip('-')
                #Is the parameter repeated?
                if opcode not in argmap:
                    isval = True
                else:
                    msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_ARG_REPEATED)
                    raise Exception, msg + args[i]
            #Was it an parameter argument?
            elif (not args[i].startswith('-')):
                msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_COMMAND_FAILED)
                raise Exception, msg + 'Parameter expected, Found value: ' + args[i]
            else:
                msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_ARG_UNSUPPORTED)
                raise Exception, msg + args[i]
        #Expecting value for the parameter.
        else:
            #Is it a value argument?
            if (not args[i].startswith('-') or opcode == "allowedActions" or opcode == "attributes" or opcode == "resourceActions" or opcode == "obligations" or opcode == "principals"):
                argmap[opcode] = args[i]
                isval = False
            else:
                msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_ARG_NOVAL)
                raise Exception, msg + '-' + opcode

    #Check if last argument is a parameter or a value.
    if isval:
        msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_ARG_NOVAL) + '-' + opcode
        raise Exception, msg

    missing = False
    msg = opss_resourceBundle.getString(WlstResources.MSG_WLST_REQUIRED_ARG_MISSING)
    for opt in required:
        if opt.lstrip('-') not in argmap:
            if not missing:
                msg += opt
            else:
                msg += ', ' + opt
            missing = True

    if missing:
        raise Exception, msg

    return argmap

