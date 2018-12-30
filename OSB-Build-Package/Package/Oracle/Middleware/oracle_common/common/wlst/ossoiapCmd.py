"""
Caution: This file is part of the WLST implementation. Do not edit or move this file because this may cause
WLST commands and scripts to fail. Do not try to reuse the logic in this file or keep copies of this file because
this could cause your WLST scripts to fail when you upgrade to a different version of WLST. 

 Copyright (c) 2002, 2009, Oracle and/or its affiliates.All rights reserved. 
 
@author rkoul

rkoul  02/26/09  remove ldap attributes
rkoul  02/09/09  add headers and additonal messages
rkoul  12/15/08  modify parameters
rkoul  11/30/08  change command names
rkoul  11/26/08  creation

"""

import sys
import os
from javax.management import AttributeNotFoundException
from java.lang import ClassNotFoundException
from java.lang import NumberFormatException
from java.lang import Integer
from java.lang import String
from java.util import ResourceBundle
from java.util import Locale
from java.text import MessageFormat
from jarray import zeros

ossoResourceBundle = ResourceBundle.getBundle("oracle.security.wls.iap.wlst.mesg.OSSOIAPResourceBundle")

#####################################################
#Custom help commands for integrated WLST help
####################################################

def addOSSOIAPCommandHelp():
    addHelpCommandGroup("ossoiap","osso_iap")
    addHelpCommand("initOSSOConfig","ossoiap",online="true")
    addHelpCommand("updateOSSOProviderParams","ossoiap",online="true")
    addHelpCommand("listOSSOProviderParams","ossoiap",online="true")
    addHelpCommand("setDefaultAuthenticatorFlag","ossoiap",online="true")
    addHelpCommand("createOSSOProvider","ossoiap",online="true")
    addHelpCommand("deleteOSSOProvider","ossoiap",online="true")

################################################################
#This command connects to the admin server
#
#@username - WLS user used to connect to it
#@password - WLS user password
#@host - WLS host
#@port - WLS port
###############################################################

def initOSSOConfig(username,password,host,port):
   # validate the parameters 
   print 'username='  +username
   if(connected == 'false'):
     try:
       url = host + ":" + port
       connect(username, password, url)
     except WLSTException:
        #msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_OFFLINE_MESSAGE)
        #print 'No server is running at '+URL+', please start a new server'
	name="initOSSOConfig"
        msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
	obj = jarray.array([name],java.lang.Object)
	format = MessageFormat.format(msg,obj)
	print format
   else:
      return;

########################################################################
#start the transaction
########################################################################

def startOSSOTransaction():
  edit()
  startEdit()



###################################################################
#end the transaction
###################################################################

def endOSSOTransaction():
  save()
  activate(block="true")


#########################################################################
#This command updates the config parameters
#allows updates of multiple parameters in a single invocation
#@name = name of the assertion provider
#
#valid parameter name(s) is/are
#@flag         -  the control flag for the provider
#######################################################################################

def updateOSSOProviderParams(name=None,flag=None):
  
  if(connected == 'true'):     
   try:
    try:  
      if name != None:
         startOSSOTransaction()
       # TODO validate params first
         realm = cmo.getSecurityConfiguration().getDefaultRealm()
	 providerMBean = realm.lookupAuthenticationProvider(name.strip())
	 if providerMBean != None:
         # update the parameters
           validateOSSOParams(cflag=flag)
           if flag != None:
              providerMBean.setControlFlag(flag.strip())
         else:
           msg = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS)
	   msgcause = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_CAUSE)
	   msgaction = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_ACTION)
	   obj = jarray.array([name],java.lang.Object)
	   cobj = jarray.array([realm,name],java.lang.Object)
	   format = MessageFormat.format(msg,obj)
	   cformat = MessageFormat.format(msgcause,cobj)
	   print format
	   print cformat
	   print msgaction
        #endOSSOTransaction()
         #disconnect()
      else:
          msg = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET)
	  print msg
    except AttributeNotFoundException,ex:
      msg = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS)
      msgcause = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_CAUSE)
      msgaction = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_ACTION)
      obj = jarray.array([name],java.lang.Object)
      cobj = jarray.array([realm,name],java.lang.Object)
      format = MessageFormat.format(msg,obj)
      cformat = MessageFormat.format(msgcause,cobj)
      print format
      print cformat
      print msgaction
    except Exception, ex:
      name="updateOSSOProviderParams"
      msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
      obj = jarray.array([name],java.lang.Object)
      format = MessageFormat.format(msg,obj)
      print format
      exceptionMesg = ex.getMessage()
      exobj = jarray.array([exceptionMesg],java.lang.Object)
      exformat = MessageFormat(exceptionMesg,exobj)
      print exformat
      stackmsg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_STACK_TRACE_MESG)
      print stackmsg
      raise
   finally:
    endOSSOTransaction()
  else:
   msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_OFFLINE_MESG)
   print msg

################################################################################
#This command lists the values the config parameters
#the default invocation without any parameters
#displays all the parameters
#
#@name - the name of the IdentityAssertionProvider
#@param - the name of the parameter to be listed
#
#valid parameter names for "param" are
#@flag         -  the control flag for the provider
#@all          -  all the parameters
#@realm        -  the realm in which the provider is configured
#
##############################################################################

def listOSSOProviderParams(name=None,param="all"):
 
 operation="listOSSOProviderParams"
 try: 
   if(connected == 'true'):  
      if name != None:
         providerMBean = cmo.getSecurityConfiguration().getDefaultRealm().lookupAuthenticationProvider(name.strip())
	 if param != None:
	    param = param.strip()
	    
         if param == "all":
            providerPath = getPath(providerMBean)
            cd (providerPath)
            ls()
         elif param == "flag":
            value = providerMBean.getControlFlag()
	 elif param == "realm":
	    value = providerMBean.getRealm()
         else:
	    operation="listOSSOProviderParams"
            msg = ossoResourceBundle.getString(ossoResourceBundle.UNRECOGNIZED_PARAM_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.UNRECOGNIZED_PARAM)
	    msgcause = ossoResourceBundle.getString(ossoResourceBundle.UNRECOGNIZED_PARAM_CAUSE)
	    msgaction = ossoResourceBundle.getString(ossoResourceBundle.UNRECOGNIZED_PARAM_ACTION)
	    obj = jarray.array([param,operation],java.lang.Object)
	    format = MessageFormat.format(msg,obj)
	    print format
	    print msgcause
	    print msgaction
            return;
	 
	 if param != "all":
            print param + " = " + value + "\n"
      else:
	 msg = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET)
	 print msg
     # endOSSOTransaction()
   else:
      msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_OFFLINE_MESG)
      print msg
 except AttributeNotFoundException,ex:
   msg = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS)
   msgcause = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_CAUSE)
   msgaction = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_ACTION)
   obj = jarray.array([name],java.lang.Object)
   cobj = jarray.array([realm,name],java.lang.Object)
   format = MessageFormat.format(msg,obj)
   cformat = MessageFormat.format(msgcause,cobj)
   print format
   print cformat
   print msgaction
 except ClassNotFoundException, e:
   msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
   obj = jarray.array([operation],java.lang.Object)
   format = MessageFormat.format(msg,obj)
   print format
   exceptionMesg = e.getMessage()
   exobj = jarray.array([exceptionMesg],java.lang.Object)
   exformat = MessageFormat(exceptionMesg,exobj)
   print exformat
 except Exception, ex:
   msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
   obj = jarray.array([operation],java.lang.Object)
   format = MessageFormat.format(msg,obj)
   print format
   exceptionMesg = ex.getMessage()
   exobj = jarray.array([exceptionMesg],java.lang.Object)
   exformat = MessageFormat(exceptionMesg,exobj)
   print exformat
   stackmsg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_STACK_TRACE_MESG)
   print stackmsg
   raise

###########################################################################
#This command sets the control flag for the default authenticator
#
#@flag - the control flag
#if nothing is passed , the OPTIONAL flag is set
###########################################################################

def setDefaultAuthenticatorFlag(flag=None):
   
   operation="setDefaultAuthenticatorFlag"
   if(flag != None and flag != 'OPTIONAL' and flag != 'REQUIRED' and flag != 'REQUISITE' and flag != 'SUFFICIENT'):
     print 'Invalid Control Flag '+flag+ 'specified.'
     paramName = "flag"
     expected=" OPTIONAL"+"| REQUIRED"+"| REQUISITE"+"| SUFFICIENT "
     msg = ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE)
     msgcause = ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE_CAUSE)
     msgaction = ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE_ACTION)
     obj = jarray.array([expected,paramName,flag],java.lang.Object)
     format = MessageFormat.format(msg,obj)
     print format
     print msgcause
     print msgaction
     return;
     
   if(connected == 'true'):
    try: 
     try:
        startOSSOTransaction()
        realm = cmo.getSecurityConfiguration().getDefaultRealm()
        defaultATN = realm.lookupAuthenticationProvider('DefaultAuthenticator')
        if flag == None:
           flag = "OPTIONAL"
           #print 'No flag specified. Setting the default \'OPTIONAL\''
        defaultATN.setControlFlag(flag)
        #endOSSOTransaction()
     except WLSTException:
	msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
	obj = jarray.array([operation],java.lang.Object)
	format = MessageFormat.format(msg,obj)
	print format
	stackmsg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_STACK_TRACE_MESG)
	print stackmsg
    finally:	
     endOSSOTransaction()
   else:
     msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_OFFLINE_MESG)
     print msg
     return; 
     
#################################################################################
#
#This command creates a new OSSO Assertion provider in the configured realm
#
#@name - the name of the provider. If no name is passed , it takes a default value
#
##################################################################################

def createOSSOProvider(name=None):
 operation="createOSSOProvider"
 if(connected == 'true'):
   try: 
     try:
        startOSSOTransaction()
        if (name == None):
           name = "OSSOAssertionProvider"
           #print 'No ProviderName specified. Setting the default '+name
	   msg = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET)
	   print msg	  
	realm = cmo.getSecurityConfiguration().getDefaultRealm()
        isProvider = realm.lookupAuthenticationProvider(name.strip())
        if (isProvider == None):
           ossoATN = realm.createAuthenticationProvider(name, 'oracle.security.wls.iap.OSSOIdentityAsserter')
           #print 'Setting the control flag of the Assertion provider to OPTIONAL'
	   ossoATN.setControlFlag('OPTIONAL')
	   defaultATN = realm.lookkupAuthenticationProvider('Default Authenticator')
           if defaultATN != None:
              #print 'Setting the control flag of Default Authenticator to OPTIONAL'
	      defaultATN.setControlFlag('OPTIONAL') 
	   msg = ossoResourceBundle.getString(ossoResourceBundle.CREATE_OSSOIAP_PROVIDER)
	   obj = jarray.array([name],java.lang.Object)
	   format = MessageFormat.format(msg,obj)
	   print format
        else:
	   msg = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_EXISTS_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_EXISTS)
	   msgcause = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_EXISTS)
	   msgaction = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_EXISTS_ACTION)
	   cobj = jarray.array([name,realm],java.lang.Object)
	   cformat = MessageFormat.format(msgcause,cobj)
	   print msg
	   print cformat
	   print msgaction
     except ClassNotFoundException, e:
	msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
	obj = jarray.array([operation],java.lang.Object)
	format = MessageFormat.format(msg,obj)
	print format
	exceptionMesg = e.getMessage()
	exobj = jarray.array([exceptionMesg],java.lang.Object)
	exformat = MessageFormat(exceptionMesg,exobj)
	print exformat
     except WLSTException:
	msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
	obj = jarray.array([operation],java.lang.Object)
	format = MessageFormat.format(msg,obj)
	print format
	stackmsg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_STACK_TRACE_MESG)
	print stackmsg					
	raise
     except Exception, ex:
	msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
	obj = jarray.array([operation],java.lang.Object)
	format = MessageFormat.format(msg,obj)
	print format
	exceptionMesg = ex.getMessage()
	exobj = jarray.array([exceptionMesg],java.lang.Object)
	exformat = MessageFormat(exceptionMesg,exobj)
	print exformat
	stackmsg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_STACK_TRACE_MESG)
	print stackmsg
				   
   finally:
     endOSSOTransaction()
 else:
     msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_OFFLINE_MESG)
     print msg
     return;
	  
########################################################################
#
#This command deltes the OSSO Assertion provider
#
#@name - the name of the provider
#######################################################################

def deleteOSSOProvider(name=None):
   operation="deleteOSSOProvider"
   if (name == None):
     msg = ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.PROVIDER_NAME_NOT_SET)
     print msg	  
     return;
         
   if(connected == 'true'):
    try:
     try:
        startOSSOTransaction()
        realm = cmo.getSecurityConfiguration().getDefaultRealm()
        ossoATN = realm.lookupAuthenticationProvider(name.strip())
        if ossoATN != None:
	   msg = ossoResourceBundle.getString(ossoResourceBundle.DELETE_OSSOIAP_PROVIDER)
	   obj = jarray.array([name],java.lang.Object)
	   format = MessageFormat.format(msg,obj)
	   print format
           realm.destroyAuthenticationProvider(ossoATN)
           #endOSSOTransaction()
        else:
	   msg = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS)
	   msgcause = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS)
	   msgaction = ossoResourceBundle.getString(ossoResourceBundle.NO_SUCH_PROVIDER_EXISTS_ACTION)
	   cobj = jarray.array([realm,name],java.lang.Object)
	   cformat = MessageFormat.format(msgcause,cobj)
	   print msg
	   print cformat
	   print msgaction
     except WLSTException:
	msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_FAILURE)
	obj = jarray.array([operation],java.lang.Object)
	format = MessageFormat.format(msg,obj)
	print format
	stackmsg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_STACK_TRACE_MESG)
	print stackmsg
	raise
    finally:
           endOSSOTransaction()
   else:
     msg = ossoResourceBundle.getString(ossoResourceBundle.GENERIC_OFFLINE_MESG)
     print msg
     return;

################################################
# Utility Method
################################################

def validateOSSOParams(cflag=None,error="false"):
 operation="updateOSSOProviderParams:validateParams"
     
 if cflag != None:
   cflag=cflag.strip()
   if(cflag != 'OPTIONAL' and cflag != 'REQUIRED' and cflag != 'REQUISITE' and cflag != 'SUFFICIENT'):
     msg = ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE_MSGID)+":"+ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE)
     msgcause = ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE_CAUSE)
     msgaction = ossoResourceBundle.getString(ossoResourceBundle.VALIDATION_FAILURE_ACTION)
     expected = " OPTIONAL | REQUIRED | REQUISITE | SUFFICIENT "
     paramName = "flag"
     passed = cflag
     obj = jarray.array([expected,paramName,passed],java.lang.Object)
     format = MessageFormat.format(msg,obj)
     error="true"
     
 if error == "true":
  print format
  print msgcause
  print msgaction
  raise Exception(format)


try:
 addOSSOIAPCommandHelp()
except WLSTException, e:
 print e.getMessage()
