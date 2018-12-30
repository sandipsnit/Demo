###############################################################################
#
# This script configures OPSS SSO Service Provider for OAM
#
# Change Log:
# ppovinec - 09/01/10 - Add impersonation triggers
# rturlapa - 09/09/09 - Fix OAM SSO service provider class name
# rturlapa - 08/10/09 - Fix syntax
# rturlapa - 07/23/09 - Creation
#
###############################################################################
def addOAMAPCommandHelp() :
 addHelpCommandGroup("oamapsso", "oam_ap")
 addHelpCommand("addOAMSSOProvider", "oamapsso", online="true")

def validateReqArgs(m, reqArgs) :
 from oracle.security.wls.oam.wlst.mesg import OAMAPMesgHelper
 from oracle.security.wls.iap.wlst.mesg import OAMAPResourceBundle

 for i in range(len(reqArgs)) :
  if (m.get(reqArgs[i]) is None) :
   msg = OAMAPMesgHelper.getMessage(OAMAPResourceBundle.REQUIRED_PARAM_NOT_FOUND, reqArgs[i])
   raise Exception(msg)

def addOAMSSOProvider(loginuri=None, logouturi=None, autologinuri=None, beginimpuri=None, endimpuri=None) :
 from oracle.security.jps.mas.mgmt.jmx.config import PortableMap
 from oracle.security.jps.mas.mgmt.jmx.util import JpsJmxConstants
 from oracle.security.jps.mas.mgmt.jmx.config import JpsConfigMBeanConstants
 from javax.management import MBeanException
 from javax.management.openmbean import CompositeData
 from java.util import ArrayList
 from java.util import HashMap

 import wlstModule

 m = HashMap()
 m.put("loginuri", loginuri)
 m.put("logouturi", logouturi)
 m.put("autologinuri", autologinuri)

 reqArgs = ArrayList()
 reqArgs.add('loginuri')

 validateReqArgs(m, reqArgs)

 loginURI = m.get('loginuri')

 authURI = HashMap()
 authURI.put(JpsConfigMBeanConstants.LOGIN_URL_PREFIX + JpsConfigMBeanConstants.FORM_AUTH,loginURI)
 authURI.put(JpsConfigMBeanConstants.LOGIN_URL_PREFIX + JpsConfigMBeanConstants.BASIC_AUTH,loginURI)
 authURI.put(JpsConfigMBeanConstants.LOGIN_URL_PREFIX + 'ANONYMOUS',loginURI)

 logoutURI = m.get('logouturi')
 if (logoutURI is not None) :
  authURI.put(JpsConfigMBeanConstants.LOGOUT_URL_PROP, logoutURI) 

 autologinURI = m.get('autologinuri')
 if (autologinURI is not None) :
  authURI.put(JpsConfigMBeanConstants.AUTO_LOGIN_URL_PROP, autologinURI) 
      
 if (beginimpuri is not None) :
  authURI.put(JpsConfigMBeanConstants.IMP_BEGIN_URL_PROP, beginimpuri) 

 if (endimpuri is not None) :
  authURI.put(JpsConfigMBeanConstants.IMP_END_URL_PROP, endimpuri) 
      
 authURIPM = PortableMap(authURI)

 authLevel = HashMap()
 authLevel.put(JpsConfigMBeanConstants.AUTH_LEVEL_PREFIX + 'ANONYMOUS',JpsConfigMBeanConstants.AUTH_LEVEL_ZERO)
 authLevel.put(JpsConfigMBeanConstants.AUTH_LEVEL_PREFIX + JpsConfigMBeanConstants.BASIC_AUTH,JpsConfigMBeanConstants.AUTH_LEVEL_ONE)
 authLevel.put(JpsConfigMBeanConstants.AUTH_LEVEL_PREFIX + JpsConfigMBeanConstants.FORM_AUTH,JpsConfigMBeanConstants.AUTH_LEVEL_TWO)

 authLevelPM = PortableMap(authLevel)
        
 serviceProps = HashMap()
 serviceProps.put(JpsConfigMBeanConstants.SSO_SERVICE_CLASS_PROP,'oracle.security.wls.oam.providers.sso.OAMSSOServiceProviderImpl')
 serviceProps.put(JpsConfigMBeanConstants.DEFAULT_AUTH_LEVEL_PROP,JpsConfigMBeanConstants.AUTH_LEVEL_TWO)
 serviceProps.put(JpsConfigMBeanConstants.TOKEN_TYPE_PROP,'OAMSSOToken')
 serviceProps.put(JpsConfigMBeanConstants.TOKEN_PROVIDER_CLASS_PROP,'oracle.security.jps.wls.internal.sso.WlsTokenProvider')
 servicePropsPM = PortableMap(serviceProps)

 try :
  wlstModule.domainRuntime()
  o = wlstModule.ObjectName(JpsJmxConstants.MBEAN_JPS_CONFIG_FUNCTIONAL)
  params = [None,authURIPM.toCompositeData(None),authLevelPM.toCompositeData(None),servicePropsPM.toCompositeData(None)]
  sign = ["java.lang.String","javax.management.openmbean.CompositeData","javax.management.openmbean.CompositeData","javax.management.openmbean.CompositeData"]
  wlstModule.mbs.invoke(o,"configureSSO", params, sign)
  wlstModule.mbs.invoke(o,"persist", None, None)
 except MBeanException, e :
  print e.getLocalizedMessage()
  raise e

try :
   addOAMAPCommandHelp()
except WLSTException, e :
   print e.getLocalizedMessage() 
