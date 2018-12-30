"""
  This script can be used to configure OAM Authentication provider
  and OAM Identity Asserter.
"""

import sys

from weblogic.descriptor import BeanAlreadyExistsException
from java.lang import UnsupportedOperationException
from java.lang import Object
from java.lang.reflect import UndeclaredThrowableException
from javax.management import AttributeNotFoundException

# imports for resourcebundle
from java.util import ResourceBundle
from java.util import Locale
from java.text import MessageFormat
from jarray import zeros
from oracle.security.wls.oam.wlst.mesg import OAMAPMesgHelper
from oracle.security.wls.iap.wlst.mesg import OAMAPResourceBundle


def addOAMAPCommandHelp():
   addHelpCommandGroup("oamap","oam_ap")
   addHelpCommand("listOAMAuthnProviderParams", "oamap",online="true")
   addHelpCommand("updateOAMAuthenticator", "oamap", online="true")
   addHelpCommand("updateOAMIdentityAsserter", "oamap", online="true")
   addHelpCommand("createOAMAuthenticator", "oamap", online="true")
   addHelpCommand("createOAMIdentityAsserter", "oamap", online="true")
   addHelpCommand("deleteOAMAuthnProvider", "oamap", online="true")
  

def validateOAMParamValue(args,param):
   if args.has_key(param)== false:
      msg = OAMAPMesgHelper.getMessage(OAMAPResourceBundle.REQUIRED_PARAM_NOT_FOUND,param.replace("-",""));
      raise Exception (msg)


def validateOAMArguments(args):
   # validate the arguments
   # Following are Required arguments for all operations -
   # operation , user, pwd, host, port, provider name
   # Also these are the ONLY required parameters for LIST and DELETE operations

   validateOAMParamValue(args, OPERATION)
   validateOAMParamValue(args, USER)
   validateOAMParamValue(args, PWD)
   validateOAMParamValue(args, HOST)
   validateOAMParamValue(args, PORT)
   validateOAMParamValue(args, ATN_PROVIDER_NAME)

def startOAMTransaction():
  edit()
  startEdit()

def endOAMTransaction():
  save()
  activate(block="true")

    
#
#This command creates a new OAM Authentication Provider in the default security realm.
#
#@name - the name of the provider. If no name is passed , it takes a default value as OAMAuthenticator
def createOAMAuthenticator(name):
    # check if online mode
   if(connected != 'true'):
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG)
      raise Exception(OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG))
   
   if (name == None):
      name = "OAMAuthenticator"
   
   # ensure that we navigate to serverConfig node of this domain
   currentNode = pwd()
   if currentNode != 'serverconfig':
      cd ('serverConfig:/')
      
   try:
      startOAMTransaction()
      # get default realm in current domain
      realm = cmo.getSecurityConfiguration().getDefaultRealm()
      if (realm == None):
         raise Exception, "You need to execute this command from security configuration node."
         
      atnProviderMBean = realm.lookupAuthenticationProvider(name)
      #create a provider only if one doesn't exist already.
      if atnProviderMBean == None:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.CREATING_OAMAP_PROVIDER,name)
      
         oamATN = realm.createAuthenticationProvider(name,'oracle.security.wls.oam.providers.authenticator.OAMAuthenticator')
        
         #change the control flag of default authentication provider
         defaultATN = realm.lookupAuthenticationProvider('DefaultAuthenticator')
         if defaultATN != None:
            defaultATN.setControlFlag('SUFFICIENT')
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.CREATE_OAMAP_PROVIDER, name)
      else:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PROVIDER_EXISTS)
   finally:
      endOAMTransaction()      

#
#This command deletes the OAM Authentication provider
#
#@name - the name of the provider
def deleteOAMAuthnProvider(name):
   # check if command is being executed in online mode
   if(connected == 'true'):
      # ensure that we navigate to serverConfig node of this domain
      currentNode = pwd()
      if currentNode != 'serverconfig':
         cd ('serverConfig:/')
         
      try:
         startOAMTransaction()  
         # get default realm in current domain
         #print "Checking if Authentication Provider is configured in default realm."
         realm = cmo.getSecurityConfiguration().getDefaultRealm()
         if (realm == None):
            raise Exception, "You need to execute this command from security configuration node."
         atnProviderMBean = realm.lookupAuthenticationProvider(name)
         if atnProviderMBean == None:
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name)
            raise Exception, OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name)
         else:
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.DELETING_OAMAP_PROVIDER, name)
            realm.destroyAuthenticationProvider(atnProviderMBean)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.DELETE_OAMAP_PROVIDER, name)
      finally:
         endOAMTransaction()
   else:
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG)
      raise Exception(OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG))


#This command updates OAM Authentication Provider parameters.
#allows updates of multiple parameters in a single invocation
#@name = name of the authentication provider
#
#valid parameter names are
#@accessGateName        - The name of the AccessGate used by the provider. REQUIRED.
#@accessGatePwd         - The password of the AccessGate used by the provider, REQUIRED if given in AccessGate entry.
#@pAccessServer         - The name of the primary access server. It must conform to the format host:port, REQUIRED.
#@sAccessServer         - The name of the secondary access server. It must conform to the format host:port, OPTIONAL.
#@transportSecurity     - The mode of communication between AccessGate and Oracle Access Server, REQUIRED.
#@keystorePwd           - The password to access the key store, REQUIRED if transportSecurity is simple mode.
#@keystorePath          - The absolute path of JKS key store used for SSL communication between the provider
#                         and the OAM Access Server, REQUIRED if transportSecurity is simple mode.
#@simpleModePassphrase  - The password shared by AccessGate and Access Server for simple communication mode,
#                         REQUIRED if transportSecurity is simple mode.
#@truststorePath        - The absolute path of JKS trust store used for SSL communication between the provider and
#                         the OAM Access Server, REQUIRED if transportSecurity is simple mode.
#                         used to protect Oracle WebLogic Server resources.
#@poolMaxConnections    - The maximum number of Oracle Access server connections in connection pool, OPTIONAL.
#@poolMinConnections    - The minimum number of Oracle Access server connections in connection pool, OPTIONAL.
#@controlFalg           - JAAS Control Flag to set up login dependencies between Authentication providers, OPTIONAL. Allowed vales are
#                         REQUIRED, SUFFICIENT, REQUISITE, OPTIONAL.
#@useRetNameAsPrincipal - Specifies whether we should use the user name retrieved from the OAM as the Principal in the Subject.
#@appDomain             - Species the name of application domain.
   

def updateOAMAuthenticator(name=None, accessGateName=None, accessGatePwd=None,
      pAccessServer=None, sAccessServer=None, transportSecurity=None,
      keystorePwd=None, keystorePath=None, simpleModePassphrase=None, truststorePath=None,
      poolMaxConnections=None, poolMinConnections=None,
      useRetNameAsPrincipal=None, controlFalg=None, appDomain=None):

   # check if command is being executed in online mode
   if(connected == 'false'):
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG)
      raise Exception(OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG))
    
   # ensure that we navigate to serverConfig node of this domain
   currentNode = pwd()
   if currentNode != 'serverconfig':
      cd ('serverConfig:/')
      
   try:
      startOAMTransaction()
      # continue if executing command in online mode.
      # get the default Authentication provider mbean
      realm = cmo.getSecurityConfiguration().getDefaultRealm()
      if (realm == None):
         print "You need to execute this command from security configuration node."
         raise  Exception,"You need to execute this command from security configuration node." 
      providerMBean = realm.lookupAuthenticationProvider(name.strip())
      if providerMBean == None:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name)
         raise Exception, OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name) 
      
      try:
         # update the parameters
         if accessGateName != None:
            providerMBean.setAccessGateName(accessGateName.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "accessGateName")
         if accessGatePwd != None:
            providerMBean.setAccessGatePassword(accessGatePwd.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "accessGatePwd")
         if pAccessServer != None:
            providerMBean.setPrimaryAccessServer(pAccessServer.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "pAccessServer")
         if sAccessServer != None:
            providerMBean.setSecondaryAccessServer(sAccessServer.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "sAccessServer")
         if transportSecurity != None:
            providerMBean.setTransportSecurity(transportSecurity.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "transportSecurity")
         if poolMaxConnections != None:
            if PyInteger != type(poolMaxConnections):
               poolMaxConnections = poolMaxConnections.strip()
               poolMaxConnections = Integer.valueOf(poolMaxConnections)
            providerMBean.setMaximumAccessServerConnectionsInPool(poolMaxConnections)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "poolMaxConnections")
         if poolMinConnections != None:
            if PyInteger != type(poolMinConnections):
               poolMinConnections = poolMinConnections.strip()
               poolMinConnections = Integer.valueOf(poolMinConnections)
            providerMBean.setMinimumAccessServerConnectionsInPool(poolMinConnections)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "poolMaxConnections")
         if keystorePwd != None:
            providerMBean.setKeyStorePassPhrase(keystorePwd.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "keystorePwd")
         if keystorePath != None:
            providerMBean.setKeyStore(keystorePath.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "keystorePath")
         if simpleModePassphrase != None:
            providerMBean.setSimpleModePassPhrase(simpleModePassphrase.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "simpleModePassphrase")
         if truststorePath != None:
            providerMBean.setTrustStore(truststorePath.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "truststorePath")
         if controlFalg != None:
            providerMBean.setControlFlag(controlFalg)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "controlFalg")
         if useRetNameAsPrincipal != None:
            providerMBean.setUseRetreivedUsernameAsPrincipal(Boolean.valueOf(useRetNameAsPrincipal))
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "UseRetreivedUsernameAsPrincipal")
         if appDomain != None:
            providerMBean.setApplicationDomain(appDomain.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "appDomain")
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_SUCCESS, "Update")
      except Exception, ex:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_FAILURE, "Update")
         raise
   finally:
      endOAMTransaction()


#This command updates OAM Identity Assertion Provider parameters.
#allows updates of multiple parameters in a single invocation
#@name = name of the Identity Assertion provider
#
#valid parameter names are
#@accessGateName        - The name of the AccessGate used by the provider, OPTIONAL. 
#@accessGatePwd         - The password of the AccessGate used by the provider, OPTIONAL
#@pAccessServer         - The name of the primary access server. It must conform to the format host:port, OPTIONAL.
#@sAccessServer         - The name of the secondary access server. It must conform to the format host:port, OPTIONAL.
#@transportSecurity     - The mode of communication between AccessGate and Oracle Access Server, OPTIONAL.
#@keystorePwd           - The password to access the key store, OPTIONAL, used only if transportSecurity is simple mode.
#@keystorePath          - The absolute path of JKS key store used for SSL communication between the provider
#                         and the OAM Access Server, OPTIONAL, used only if transportSecurity is simple mode.
#@simpleModePassphrase  - The password shared by AccessGate and Access Server for simple communication mode,
#                         OPTIONAL, used only if transportSecurity is simple mode.
#@truststorePath        - The absolute path of JKS trust store used for SSL communication between the provider and
#                         the OAM Access Server, OPTIONAL used only if transportSecurity is simple mode.
#                         used to protect Oracle WebLogic Server resources.
#@poolMaxConnections    - The maximum number of Oracle Access server connections in connection pool, OPTIONAL.
#@poolMinConnections    - The minimum number of Oracle Access server connections in connection pool, OPTIONAL.
#@controlFalg           - JAAS Control Flag to set up login dependencies between Authentication providers, OPTIONAL. Allowed vales are
#                         REQUIRED, SUFFICIENT, REQUISITE, OPTIONAL.
#@ssoHeaderName         - The name of header to be asserted.  
#@appDomain             - Specifies the name of application domain, optional.

def updateOAMIdentityAsserter(name=None, accessGateName=None, accessGatePwd=None,
      pAccessServer=None, sAccessServer=None, transportSecurity=None,
      keystorePwd=None, keystorePath=None, simpleModePassphrase=None, truststorePath=None,
      poolMaxConnections=None, poolMinConnections=None,
      controlFalg=None,ssoHeaderName=None, appDomain=None):

   # check if command is being executed in online mode
   if(connected == 'false'):
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG)
      raise Exception(OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG))
    
   # ensure that we navigate to serverConfig node of this domain
   currentNode = pwd()
   if currentNode != 'serverconfig':
      cd ('serverConfig:/')
      
   try:
      startOAMTransaction()
      # continue if executing command in online mode.
      # get the default Authentication provider mbean
      realm = cmo.getSecurityConfiguration().getDefaultRealm()
      if (realm == None):
         print "You need to execute this command from security configuration node."
         raise  Exception,"You need to execute this command from security configuration node." 
      providerMBean = realm.lookupAuthenticationProvider(name.strip())
      if providerMBean == None:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name)
         raise Exception, OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name) 
      
      try:
         # update the parameters
         if accessGateName != None:
            providerMBean.setAccessGateName(accessGateName.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "accessGateName")
         if accessGatePwd != None:
            providerMBean.setAccessGatePassword(accessGatePwd.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "accessGatePwd")
         if pAccessServer != None:
            providerMBean.setPrimaryAccessServer(pAccessServer.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "pAccessServer")
         if sAccessServer != None:
            providerMBean.setSecondaryAccessServer(sAccessServer.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "sAccessServer")
         if transportSecurity != None:
            providerMBean.setTransportSecurity(transportSecurity.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "transportSecurity")
         if poolMaxConnections != None:
            if PyInteger != type(poolMaxConnections):
               poolMaxConnections = poolMaxConnections.strip()
               poolMaxConnections = Integer.valueOf(poolMaxConnections)
            providerMBean.setMaximumAccessServerConnectionsInPool(poolMaxConnections)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "poolMaxConnections")
         if poolMinConnections != None:
            if PyInteger != type(poolMinConnections):
               poolMinConnections = poolMinConnections.strip()
               poolMinConnections = Integer.valueOf(poolMinConnections)
            providerMBean.setMinimumAccessServerConnectionsInPool(poolMinConnections)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "poolMaxConnections")
         if keystorePwd != None:
            providerMBean.setKeyStorePassPhrase(keystorePwd.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "keystorePwd")
         if keystorePath != None:
            providerMBean.setKeyStore(keystorePath.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "keystorePath")
         if simpleModePassphrase != None:
            providerMBean.setSimpleModePassPhrase(simpleModePassphrase.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "simpleModePassphrase")
         if truststorePath != None:
            providerMBean.setTrustStore(truststorePath.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "truststorePath")
         if controlFalg != None:
            providerMBean.setControlFlag(controlFalg)
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "controlFalg")
         if ssoHeaderName != None:
            providerMBean.setSSOHeaderName(ssoHeaderName.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "SSOHeaderName")
         if appDomain != None:
            providerMBean.setApplicationDomain(appDomain.strip())
            print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PARAM_UPDATE_SUCCESS, "appDomain")
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_SUCCESS, "Update")
      except Exception, ex:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_FAILURE, "Update")
         raise
   finally:
      endOAMTransaction()



def listOAMAuthnProviderParams(name):
   if(connected == 'false'):
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG)
      raise Exception, OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG);
   
   # ensure that we navigate to serverConfig node of this domain
   currentNode = pwd()
   if currentNode != 'serverconfig':
      cd ('serverConfig:/')
      
   try:
      # get the default Authentication provider mbean
      #print "Looking for Authentication Provider."
      realm = cmo.getSecurityConfiguration().getDefaultRealm()
      if (realm == None):
         print "You need to execute this command from security configuration node."
         return
      providerMBean = realm.lookupAuthenticationProvider(name.strip())
      if providerMBean == None:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name)
         raise Exception, OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS, name)         
      providerPath = getPath(providerMBean)
      #print "Listing Authentication Provider parameters"
      cd (providerPath)
      ls()
   except AttributeNotFoundException, ex:
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.NO_SUCH_PROVIDER_EXISTS,name)
      raise
   except Exception, e:
      raise


#
#This command creates a new OAM Identity Asserter in the default security realm.
#
#@name - the name of the provider. If no name is passed , it takes a default value as OAMAuthenticator
def createOAMIdentityAsserter(name):
    # check if online mode
   if(connected != 'true'):
      print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG)
      raise Exception(OAMAPMesgHelper.getMessage(OAMAPResourceBundle.GENERIC_OFFLINE_MESG))

   if (name == None):
      name = "OAMIdentityAsserter"

   # ensure that we navigate to serverConfig node of this domain
   currentNode = pwd()
   if currentNode != 'serverconfig':
      cd ('serverConfig:/')

   try:
      startOAMTransaction()
      # get default realm in current domain
      realm = cmo.getSecurityConfiguration().getDefaultRealm()
      if (realm == None):
         raise Exception, "You need to execute this command from security configuration node."

      atnProviderMBean = realm.lookupAuthenticationProvider(name)
      #create a provider only if one doesn't exist already.
      if atnProviderMBean == None:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.CREATING_OAMAP_PROVIDER,name)

         oamATN = realm.createAuthenticationProvider(name,'oracle.security.wls.oam.providers.asserter.OAMIdentityAsserter')
         #oamATN.setControlFlag('REQUIRED')

         #change the control flag of default authentication provider
         defaultATN = realm.lookupAuthenticationProvider('DefaultAuthenticator')
         if defaultATN != None:
            defaultATN.setControlFlag('SUFFICIENT')
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.CREATE_OAMAP_PROVIDER, name)
      else:
         print OAMAPMesgHelper.getMessage(OAMAPResourceBundle.PROVIDER_EXISTS)
   finally:
      endOAMTransaction()

try:
   addOAMAPCommandHelp()
except WLSTException, e:
   print e.getMessage()



