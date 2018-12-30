################################################################
# Caution: This file is part of the WLST implementation.
# Do not edit or move this file because this may cause
# WLST commands and scripts to fail. Do not try to reuse
# the logic in this file or keep copies of this file because
# this could cause your WLST scripts to fail when you
# upgrade to a different version of WLST.
#
# Copyright (c) 2009, Oracle and/or its affiliates. All rights reserved. 
################################################################

from java.io import *
from javax.management.openmbean import *
from java.util import ResourceBundle
from java.util import Locale
from java.text import MessageFormat
from jarray import zeros
import shutil
import os
import sys
import traceback
import time

sslconfigBundle = ResourceBundle.getBundle("oracle.security.sslconfig.mesg.SSLConfigWLSTMessages")

#######################################################
# This function adds command help
# (Internal function)
#######################################################

def addSSLConfigCommandHelp():
  try:
    addHelpCommandGroup("sslconfig", "sslconfig_wlst")
    addHelpCommand("getSSL", "sslconfig")
    addHelpCommand("configureSSL", "sslconfig")
    addHelpCommand("createKeyStore", "sslconfig")
    addHelpCommand("deleteKeyStore", "sslconfig")
    addHelpCommand("changeKeyStorePassword", "sslconfig")
    addHelpCommand("generateKey", "sslconfig")
    addHelpCommand("listKeyStoreObjects", "sslconfig")
    addHelpCommand("getKeyStoreObject", "sslconfig")
    addHelpCommand("exportKeyStoreObject", "sslconfig")
    addHelpCommand("removeKeyStoreObject", "sslconfig")
    addHelpCommand("importKeyStoreObject", "sslconfig")
    addHelpCommand("listKeyStores", "sslconfig")
    addHelpCommand("exportKeyStore", "sslconfig")
    addHelpCommand("importKeyStore", "sslconfig")
    addHelpCommand("createWallet", "sslconfig")
    addHelpCommand("deleteWallet", "sslconfig")
    addHelpCommand("changeWalletPassword", "sslconfig")
    addHelpCommand("addCertificateRequest", "sslconfig")
    addHelpCommand("addSelfSignedCertificate", "sslconfig")
    addHelpCommand("listWalletObjects", "sslconfig")
    addHelpCommand("getWalletObject", "sslconfig")
    addHelpCommand("exportWalletObject", "sslconfig")
    addHelpCommand("removeWalletObject", "sslconfig")
    addHelpCommand("importWalletObject", "sslconfig")
    addHelpCommand("listWallets", "sslconfig")
    addHelpCommand("exportWallet", "sslconfig")
    addHelpCommand("importWallet", "sslconfig")
  except (Exception), exc:
    return

#######################################################
# This function gets Keystore Mbean name
# (Internal function)
#######################################################

def getKeyStoreMBeanName(instName, compName, compType):
    str = String("oracle.as." + compType + ":type=component.keystore,name=keystore,instance=" + instName + ",component=" + compName)
    return str

#######################################################
# This function validates the component type
# (Internal function)
#######################################################

def _validateCompType(compType):
    if (compType == 'ovd'):
       msg = sslconfigBundle.getString("VALIDATE_COMP")
       print msg
       return 1

#######################################################
# This function invokes load() on component Mbean
# (Internal function)
#######################################################

def invokeLoadMBean(instName, compName):
    str = String("oracle.as.management.mbeans.register:type=component,name=" + compName + ",instance=" + instName)
    load_on = ObjectName(str)
    objs = jarray.array([],java.lang.Object)
    sigs = jarray.array([],java.lang.String)
    mbs.invoke(load_on, "load", objs, sigs)
    return

#######################################################
# This function invokes save() on component Mbean
# (Internal function)
#######################################################

def invokeSaveMBean(instName, compName):
    str = String("oracle.as.management.mbeans.register:type=component,name=" + compName + ",instance=" + instName)
    save_on = ObjectName(str)
    objs = jarray.array([],java.lang.Object)
    sigs = jarray.array([],java.lang.String)
    mbs.invoke(save_on, "save", objs, sigs)
    return

#######################################################
# This function lists all listeners available for
# SSL configuration
#######################################################

def listListeners(instName, compName):
    str = String("oracle.as.management.mbeans.register:type=component,name=" + compName + ",instance=" + instName)
    mbean_on = ObjectName(str)
    arr = mbs.getAttribute(mbean_on,'SSLObjects')
    length = len(arr)
    for i in range(length):
	print arr[i]

#######################################################
# This function gets the SSL Mbean name for a component
# (Internal function)
#######################################################

def getSSLMBeanName(instName, compName, compType, endpoint):
    if (compType == 'ovd'):
       str = String("oracle.as." + compType + ":type=component.listenersconfig.sslconfig,name=" + endpoint + ",instance=" + instName + ",component=" + compName)
    else:
       str = String("oracle.as." + compType + ":type=component.sslconfig,name=" + endpoint + ",instance=" + instName + ",component=" + compName)
    return str

#######################################################
# This function gets the SSL parameters configured
#######################################################

def getSSL(instName, compName, compType, endpoint):
    updateGlobals()
    if (connected == 'true'):
      on = getSSLMBeanName(instName, compName, compType, endpoint)
      ssl_on = ObjectName(on)
      invokeLoadMBean(instName, compName)
      do = mbs.getAttribute(ssl_on,'SSLVersions')
      msg = sslconfigBundle.getString("SSLVERSIONS")
      obj = jarray.array([do],java.lang.Object)
      format = MessageFormat.format(msg, obj)
      print format
      do = mbs.getAttribute(ssl_on,'Ciphers')
      if (compType != 'webcache'):
	 msg = sslconfigBundle.getString("CIPHERS")
	 obj = jarray.array([do],java.lang.Object)
	 format = MessageFormat.format(msg, obj)
	 print format
      do = mbs.getAttribute(ssl_on,'AuthenticationType')
      msg = sslconfigBundle.getString("AUTHTYPE")
      obj = jarray.array([do],java.lang.Object)
      format = MessageFormat.format(msg, obj)
      print format
      do = mbs.getAttribute(ssl_on,'KeyStore')
      if (compType == "ovd"):
	 msg = sslconfigBundle.getString("KEYSTORE")
	 obj = jarray.array([do],java.lang.Object)
	 format = MessageFormat.format(msg, obj)
	 print format
      else:
	 msg = sslconfigBundle.getString("WALLET")
	 obj = jarray.array([do],java.lang.Object)
	 format = MessageFormat.format(msg, obj)
	 print format
      do = mbs.getAttribute(ssl_on,'TrustStore')
      if (compType == "ovd"):
	 msg = sslconfigBundle.getString("TRUSTSTORE")
	 obj = jarray.array([do],java.lang.Object)
	 format = MessageFormat.format(msg, obj)
	 print format
      do = mbs.getAttribute(ssl_on,'CertValidation')
      if (compType == 'ohs') or (compType == 'webcache'):
	 msg = sslconfigBundle.getString("CERTVALIDATION")
	 obj = jarray.array([do],java.lang.Object)
	 format = MessageFormat.format(msg, obj)
	 print format
      do = mbs.getAttribute(ssl_on,'CertValidationPath')
      if (compType == 'ohs') or (compType == 'webcache'):
	 msg = sslconfigBundle.getString("CERTVALIDATIONPATH")
	 obj = jarray.array([do],java.lang.Object)
	 format = MessageFormat.format(msg, obj)
	 print format
      do = mbs.getAttribute(ssl_on,'SSLEnabled')
      if (do == 0):
	 msg = sslconfigBundle.getString("SSLFALSE")
	 print msg
      else:
	 msg = sslconfigBundle.getString("SSLTRUE")
	 print msg
      attrNames = mbs.getAttribute(ssl_on, "SSLAttributeNames")
      attrValues = mbs.getAttribute(ssl_on, "SSLAttributeValues")
      if (attrNames != None):
	 length = len(attrNames)
	 x = 0
	 while x < length:
	    print attrNames[x] + "	 : " + attrValues[x]
	    msg = sslconfigBundle.getString("SSLATTR")
	    obj = jarray.array([attrNames[x], attrValues[x]],java.lang.Object)
	    format = MessageFormat.format(msg, obj)
	    print format
	    x += 1
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function configures the SSL parameters
#######################################################

def configureSSL(instName, compName, compType, endpoint, filepath = None):
    updateGlobals()
    if (connected == 'true'):
      on = getSSLMBeanName(instName, compName, compType, endpoint)
      invokeLoadMBean(instName, compName)
      ssl_on = ObjectName(on)
      try:
	 if (filepath is None):
	     msg = sslconfigBundle.getString("NO_SSL_PROP")
	     print msg
	     props = Properties()
	     props.setProperty("Ciphers", "")
	     props.setProperty("SSLVersions", "")
	     if (compType == 'ohs') or (compType == 'webcache'):
		props.setProperty("KeyStore", "default")
		props.setProperty("TrustStore", "default")
	     elif (compType == 'ovd'):
		props.setProperty("KeyStore", "keys.jks")
		props.setProperty("TrustStore", "keys.jks")
	     else:
		props.setProperty("KeyStore", "")
		props.setProperty("TrustStore", "")
	     props.setProperty("CertValidation", "none")
	     props.setProperty("CertValidationPath", "")
	     props.setProperty("HostNameVerifier", "")
	     if (compType == 'oid'):
		props.setProperty("AuthenticationType", "None")
	     else:
		props.setProperty("AuthenticationType", "Server")
	     props.setProperty("SSLEnabled", "true")
	 else:
	     file = File(filepath)
	     if (file.isFile() == 0):
		 msg = sslconfigBundle.getString("INVALID_SSL_PROP")
		 print msg
		 return
	     else:
		 msg = sslconfigBundle.getString("USING_SSL_PROP")
		 obj = jarray.array([java.lang.String(filepath)],java.lang.Object)
		 format = MessageFormat.format(msg, obj)
		 print format
		 input = FileInputStream(filepath)
		 props = Properties()
		 props.load(input)
	 en = props.propertyNames()
	 sslVersions = props.getProperty('SSLVersions')
	 if (sslVersions != None):
	    sslVersions = String(sslVersions).trim()
	 if (sslVersions == ''):
	     sslVersions = None
	 ciphers = props.getProperty('Ciphers')
	 if (ciphers != None):
	    ciphers = String(ciphers).trim()
	 if (ciphers == ''):
	     ciphers = None
	 authType = props.getProperty('AuthenticationType')
	 if (authType != None):
	    authType = String(authType).trim()
	 if (authType == '') or (authType is None):
	     if (compType == 'oid'):
		authType = 'None'
	     else:
		authType = 'Server'
	 keystore = props.getProperty('KeyStore')
	 if (keystore != None):
	    keystore = String(keystore).trim()
	 if (keystore == '') or (keystore is None):
	     if (compType == 'oid'):
		keystore = None
	     elif (compType == 'ovd'):
		keystore = 'keys.jks'
	     else:
		keystore = 'default'
	 truststore = props.getProperty('TrustStore')
	 if (truststore != None):
	    truststore = String(truststore).trim()
	 if (truststore == '') or (truststore is None):
	     if (compType == 'oid'):
		truststore = None
	     elif (compType == 'ovd'):
		truststore = 'keys.jks'
	     else:
		truststore = 'default'
	 certValidation = props.getProperty('CertValidation')
	 if (certValidation != None):
	    certValidation = String(certValidation).trim()
	 if (certValidation == '') or (certValidation is None):
	     certValidation = 'none'
	 certValidationPath = props.getProperty('CertValidationPath')
	 if (certValidationPath != None):
	    certValidationPath = String(certValidationPath).trim()
	 if (certValidationPath == ''):
	     certValidationPath = None
	 hostNameVerifier = props.getProperty('HostNameVerifier')
	 if (hostNameVerifier != None):
	    hostNameVerifier = String(hostNameVerifier).trim()
	 if (hostNameVerifier == ''):
	     hostNameVerifier = None
	 temp = props.getProperty('SSLEnabled')
	 if (temp != None):
	    temp = String(temp).trim()
	 if (temp == '') or (temp is None):
	     temp = 'true'
	 sslEnabled = Boolean(temp)
	 itemNames = ['SSLVersions', 'Ciphers', 'AuthenticationType',
		      'KeyStore', 'TrustStore', 'SSLEnabled','CertValidation',
		      'CertValidationPath','HostNameVerifier',
		      'CustomName', 'CustomValue']
	 arrType = ArrayType(1, SimpleType.STRING)
	 itemTypes = jarray.array ([SimpleType.STRING,
			      SimpleType.STRING,
			      SimpleType.STRING,
			      SimpleType.STRING,
			      SimpleType.STRING,
			      SimpleType.BOOLEAN,
			      SimpleType.STRING,
			      SimpleType.STRING,
			      SimpleType.STRING,
			      arrType,
			      arrType], OpenType)
	 cType = CompositeType ("oracle.security.sslconfig.client.utils.SSLConfigProperties", "oracle.security.sslconfig.client.utils.SSLConfigProperties",
		itemNames,
		itemNames,
		itemTypes);
	 itemValues = [ sslVersions,
			ciphers,
			authType,
			keystore,
			truststore,
			sslEnabled,
			certValidation,
			certValidationPath,
			hostNameVerifier,
			None,
			None]
	 compData = CompositeDataSupport(cType, itemNames, itemValues)
	 attr = Attribute("SSLConfig", compData);
	 mbs.setAttribute(ssl_on, attr)
	 while (en.hasMoreElements() == 1):
	    val = en.nextElement()
	    value = props.getProperty(val)
	    if (val == 'SSLVersions'):
	       continue
	    elif (val == 'Ciphers'):
	       continue
	    elif (val == 'AuthenticationType'):
	       continue
	    elif (val == 'KeyStore'):
	       continue
	    elif (val == 'TrustStore'):
	       continue
	    elif (val == 'CertValidation'):
	       continue
	    elif (val == 'CertValidationPath'):
	       continue
	    elif (val == 'HostNameVerifier'):
	       continue
	    elif (val == 'SSLEnabled'):
	       continue
	    else:
		objs = jarray.array([java.lang.String(val),java.lang.String(value)],java.lang.Object)
		sigs = jarray.array(["java.lang.String","java.lang.String"],java.lang.String)
		mbs.invoke(ssl_on,"setSSLAttribute",objs,sigs)
	 invokeSaveMBean(instName, compName)
      except (Exception), exc:
	     raise exc
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function creates a JKS
#######################################################

def createKeyStore(instName, compName, compType, name, passwd):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       objs = [name, password]
       sigs = ["java.lang.String","[C"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"createKeyStore",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("KS_CREATED")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function creates a wallet
#######################################################

def createWallet(instName, compName, compType, name, passwd):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       objs = [name, password]
       sigs = ["java.lang.String","[C"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"createKeyStore",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("W_CREATED")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function deletes a JKS
#######################################################

def deleteKeyStore(instName, compName, compType, name):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       objs = [name]
       sigs = ["java.lang.String"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"deleteKeyStore",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("KS_DELETED")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function deletes a wallet
#######################################################

def deleteWallet(instName, compName, compType, name):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       objs = [name]
       sigs = ["java.lang.String"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"deleteKeyStore",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("W_DELETED")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function changes a JKS password
#######################################################

def changeKeyStorePassword(instName, compName, compType, name, old, new):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       oldpw = java.lang.String(old).toCharArray()
       newpw = java.lang.String(new).toCharArray()
       objs = [name, oldpw, newpw]
       sigs = ["java.lang.String","[C", "[C"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"changeKeyStorePassword",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("KS_PW_CHANGE")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function changes a wallet password
#######################################################

def changeWalletPassword(instName, compName, compType, name, old, new):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       oldpw = java.lang.String(old).toCharArray()
       newpw = java.lang.String(new).toCharArray()
       objs = [name, oldpw, newpw]
       sigs = ["java.lang.String","[C", "[C"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"changeKeyStorePassword",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("W_PW_CHANGE")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function generates a key-pair in JKS
#######################################################

def generateKey(instName, compName, compType, name, passwd, DN, keysize, alias, algorithm="RSA"):
    updateGlobals()
    if (connected == 'true'):
       if (algorithm != 'RSA'):
	  msg = sslconfigBundle.getString("INVALID_ALGO")
	  print msg
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       tmp = Integer(keysize)
       size = tmp.intValue()
       objs = [name, password, DN, size, alias]
       sigs = ["java.lang.String","[C", "java.lang.String", "int", "java.lang.String"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"addCertificateRequest",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("KS_GENERATE_KEY")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function generates a CSR in wallet
#######################################################

def addCertificateRequest(instName, compName, compType, name, passwd, DN, keysize):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       tmp = Integer(keysize)
       size = tmp.intValue()
       objs = [name, password, DN, size, None]
       sigs = ["java.lang.String","[C", "java.lang.String", "int", "java.lang.String"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"addCertificateRequest",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("W_GENERATE_CSR")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function generates a self-signed cert in wallet
#######################################################

def addSelfSignedCertificate(instName, compName, compType, name, passwd, DN = None, keysize="1024"):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       tmp = Integer(keysize)
       size = tmp.intValue()
       objs = [name, password, DN, size, None]
       sigs = ["java.lang.String","[C", "java.lang.String", "int", "java.lang.String"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"addSelfSignedCertificate",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("W_SELFSIGNED")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg


#######################################################
# This function lists the contents of a JKS
#######################################################

def listKeyStoreObjects(instName, compName, compType, name, passwd, type):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'Certificate') and (type != 'TrustedCertificate'):
	   msg = sslconfigBundle.getString("INVALID_KS_OBJECT")
	   print msg
       else:
	   objs = [name, password, type]
	   sigs = ["java.lang.String","[C", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   superlist = mbs.invoke(ks_on,"listKeyStoreObject",objs,sigs)
	   length = len(superlist)
	   print '------------------------------------------------------'
	   for i in range(length):
	       list = superlist[i]
	       DN = list[0]
	       alias = list[1]
	       msg = sslconfigBundle.getString("INDEX")
	       obj = jarray.array([java.lang.Integer(i)],java.lang.Object)
	       format = MessageFormat.format(msg, obj)
	       print format
	       msg = sslconfigBundle.getString("DN")
	       obj = jarray.array([java.lang.String(DN)],java.lang.Object)
	       format = MessageFormat.format(msg, obj)
	       print format
	       msg = sslconfigBundle.getString("ALIAS")
	       obj = jarray.array([java.lang.String(alias)],java.lang.Object)
	       format = MessageFormat.format(msg, obj)
	       print format
	       print '------------------------------------------------------'
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function lists the contents of a wallet
#######################################################

def listWalletObjects(instName, compName, compType, name, passwd, type):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'CertificateRequest') and (type != 'Certificate') and (type != 'TrustedCertificate'):
	   msg = sslconfigBundle.getString("INVALID_W_OBJECT")
	   print msg
       else:
	   objs = [name, password, type]
	   sigs = ["java.lang.String","[C", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   superlist = mbs.invoke(ks_on,"listKeyStoreObject",objs,sigs)
	   length = len(superlist)
	   print '------------------------------------------------------'
	   for i in range(length):
	       list = superlist[i]
	       DN = list[0]
	       msg = sslconfigBundle.getString("INDEX")
	       obj = jarray.array([java.lang.Integer(i)],java.lang.Object)
	       format = MessageFormat.format(msg, obj)
	       print format
	       msg = sslconfigBundle.getString("DN")
	       obj = jarray.array([java.lang.String(DN)],java.lang.Object)
	       format = MessageFormat.format(msg, obj)
	       print format
	       print '------------------------------------------------------'
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function gets the details of a JKS object
#######################################################

def getKeyStoreObject(instName, compName, compType, name, passwd, type, index):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       tmp = Integer(index)
       ind = tmp.intValue()
       ks_on = ObjectName(on)
       if (type == 'Certificate'):
	   tmp = Boolean(false)
	   bool = tmp.booleanValue()
	   objs = [name, password, ind, bool]
	   sigs = ["java.lang.String","[C", "int", "boolean"]
	   cert = mbs.invoke(ks_on,"showCertificate",objs,sigs)
	   print cert
       elif (type == 'TrustedCertificate'):
	   tmp = Boolean(true)
	   bool = tmp.booleanValue()
	   objs = [name, password, ind, bool]
	   sigs = ["java.lang.String","[C", "int", "boolean"]
	   cert = mbs.invoke(ks_on,"showCertificate",objs,sigs)
	   print cert
       else:
	   msg = sslconfigBundle.getString("INVALID_KS_OBJECT")
	   print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function gets the details of a wallet object
#######################################################

def getWalletObject(instName, compName, compType, name, passwd, type, index):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       tmp = Integer(index)
       ind = tmp.intValue()
       ks_on = ObjectName(on)
       if (type == 'CertificateRequest'):
	   objs = [name, password, ind]
	   sigs = ["java.lang.String","[C", "int"]
	   invokeLoadMBean(instName, compName)
	   arr = mbs.invoke(ks_on,"showCertificateRequest",objs,sigs)
	   tmp = arr[0]
	   if (tmp != None):
	      msg = sslconfigBundle.getString("SUBJECT")
	      obj = jarray.array([java.lang.String(arr[0])],java.lang.Object)
	      format = MessageFormat.format(msg, obj)
	      print format
	      msg = sslconfigBundle.getString("KEYSIZE")
	      obj = jarray.array([java.lang.String(arr[1])],java.lang.Object)
	      format = MessageFormat.format(msg, obj)
	      print format
	      msg = sslconfigBundle.getString("ALGORITHM")
	      obj = jarray.array([java.lang.String(arr[2])],java.lang.Object)
	      format = MessageFormat.format(msg, obj)
	      print format
	   else:
	      msg = sslconfigBundle.getString("NO_CSR")
	      print msg
       elif (type == 'Certificate'):
	   tmp = Boolean(false)
	   bool = tmp.booleanValue()
	   objs = [name, password, ind, bool]
	   sigs = ["java.lang.String","[C", "int", "boolean"]
	   cert = mbs.invoke(ks_on,"showCertificate",objs,sigs)
	   print cert
       elif (type == 'TrustedCertificate'):
	   tmp = Boolean(true)
	   bool = tmp.booleanValue()
	   objs = [name, password, ind, bool]
	   sigs = ["java.lang.String","[C", "int", "boolean"]
	   cert = mbs.invoke(ks_on,"showCertificate",objs,sigs)
	   print cert
       else:
	   msg = sslconfigBundle.getString("INVALID_W_OBJECT")
	   print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function exports a JKS object
#######################################################

def exportKeyStoreObject(instName, compName, compType, name, passwd, type, path, alias):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'CertificateRequest') and (type != 'Certificate') and (type != 'TrustedCertificate') and (type != 'TrustedChain'):
	   msg = sslconfigBundle.getString("INVALID_KS_OBJECT")
	   print msg
       else:
	   objs = [name, password, alias, None, type]
	   sigs = ["java.lang.String","[C", "java.lang.String", "java.lang.String", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   base64 = mbs.invoke(ks_on,"exportKeyStoreObject",objs,sigs)
	   if (base64 != None):
	      arr = java.lang.String(base64).getBytes()
	      fos = FileOutputStream(path + File.separator + "base64.txt")
	      fos.write(arr)
	      fos.flush()
	      fos.close()
	      msg = sslconfigBundle.getString("KS_EXPORT_OBJ")
	      print msg
	   else:
	      msg = sslconfigBundle.getString("NO_KS_OBJECT")
	      print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function exports a wallet object
#######################################################

def exportWalletObject(instName, compName, compType, name, passwd, type, path, DN):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'CertificateRequest') and (type != 'Certificate') and (type != 'TrustedCertificate') and (type != 'TrustedChain'):
	   msg = sslconfigBundle.getString("INVALID_W_OBJECT")
	   print msg
       else:
	   objs = [name, password, None, DN, type]
	   sigs = ["java.lang.String","[C", "java.lang.String", "java.lang.String", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   base64 = mbs.invoke(ks_on,"exportKeyStoreObject",objs,sigs)
	   if (base64 != None):
	      arr = java.lang.String(base64).getBytes()
	      fos = FileOutputStream(path + File.separator + "base64.txt")
	      fos.write(arr)
	      fos.flush()
	      fos.close()
	      msg = sslconfigBundle.getString("W_EXPORT_OBJ")
	      print msg
	   else:
	      msg = sslconfigBundle.getString("NO_W_OBJECT")
	      print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function removes a JKS object
#######################################################

def removeKeyStoreObject(instName, compName, compType, name, passwd, type, alias = None):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'Certificate') and (type != 'TrustedCertificate') and (type != 'TrustedAll'):
	   msg = sslconfigBundle.getString("INVALID_KS_OBJECT")
	   print msg
       else:
	   objs = [name, password, alias, None, type]
	   sigs = ["java.lang.String","[C", "java.lang.String", "java.lang.String", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   base64 = mbs.invoke(ks_on,"removeKeyStoreObject",objs,sigs)
	   invokeSaveMBean(instName, compName)
	   msg = sslconfigBundle.getString("KS_REMOVE_OBJ")
	   print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function removes a wallet object
#######################################################

def removeWalletObject(instName, compName, compType, name, passwd, type, DN = None):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'CertificateRequest') and (type != 'Certificate') and (type != 'TrustedCertificate') and (type != 'TrustedAll'):
	   msg = sslconfigBundle.getString("INVALID_W_OBJECT")
	   print msg
       else:
	   objs = [name, password, None, DN, type]
	   sigs = ["java.lang.String","[C", "java.lang.String", "java.lang.String", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   base64 = mbs.invoke(ks_on,"removeKeyStoreObject",objs,sigs)
	   invokeSaveMBean(instName, compName)
	   msg = sslconfigBundle.getString("W_REMOVE_OBJ")
	   print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function imports a JKS object
#######################################################

def importKeyStoreObject(instName, compName, compType, name, passwd, type, filepath, alias):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'Certificate') and (type != 'TrustedCertificate'):
	   msg = sslconfigBundle.getString("INVALID_KS_OBJECT")
	   print msg
       else:
	   fis = FileInputStream(filepath)
	   num = fis.available()
	   arr = zeros(num, 'b')
	   fis.read(arr)
	   fis.close()
	   base64 = java.lang.String(arr)
	   objs = [name, password, alias, base64, type]
	   sigs = ["java.lang.String","[C", "java.lang.String", "java.lang.String", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   base64 = mbs.invoke(ks_on,"importKeyStoreObject",objs,sigs)
	   invokeSaveMBean(instName, compName)
	   msg = sslconfigBundle.getString("KS_IMPORT_OBJ")
	   print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function imports a wallet object
#######################################################

def importWalletObject(instName, compName, compType, name, passwd, type, filepath):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       if (type != 'Certificate') and (type != 'TrustedCertificate') and (type != 'TrustedChain'):
	   msg = sslconfigBundle.getString("INVALID_W_OBJECT")
	   print msg
       else:
	   fis = FileInputStream(filepath)
	   num = fis.available()
	   arr = zeros(num, 'b')
	   fis.read(arr)
	   fis.close()
	   base64 = java.lang.String(arr)
	   objs = [name, password, None, base64, type]
	   sigs = ["java.lang.String","[C", "java.lang.String", "java.lang.String", "java.lang.String"]
	   ks_on = ObjectName(on)
	   invokeLoadMBean(instName, compName)
	   base64 = mbs.invoke(ks_on,"importKeyStoreObject",objs,sigs)
	   invokeSaveMBean(instName, compName)
	   msg = sslconfigBundle.getString("W_IMPORT_OBJ")
	   print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function lists all JKS
#######################################################

def listKeyStores(instName, compName, compType):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       map = mbs.invoke(ks_on,"listKeyStores",None,None)
       msg = sslconfigBundle.getString("NAME")
       print msg
       print '----'
       for key in map:
           arr = array(key, java.lang.String)
           values = map[arr]
           coll = values.values()
           iter2 = coll.iterator()
           tmpkey = iter2.next()
           print tmpkey
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function lists all wallets and their type
#######################################################

def listWallets(instName, compName, compType):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       map = mbs.invoke(ks_on,"listKeyStores",None,None)
       msg = sslconfigBundle.getString("NAME-AL")
       print msg
       print '-----------------------------------------------'
       for key in map:
           arr = array(key, java.lang.String)
           values = map[arr]
           coll = values.values()
           iter2 = coll.iterator()
           tmpkey = iter2.next()
           tmpval = iter2.next()
           if (tmpval == "true"):
              al = "false"
           else:
              al = "true"
           msg = sslconfigBundle.getString("NAME-AL-VAL")
           obj = jarray.array([tmpkey, al],java.lang.Object)
           format = MessageFormat.format(msg, obj)
           print format
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function exports a JKS to file
#######################################################

def exportKeyStore(instName, compName, compType, name, passwd, path):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       objs = [name, password]
       sigs = ["java.lang.String","[C"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       list = mbs.invoke(ks_on,"exportKeyStore",objs,sigs)
       fos = FileOutputStream(path + File.separator + name)
       fos.write(list[0])
       fos.flush()
       fos.close()
       msg = sslconfigBundle.getString("KS_EXPORT")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function exports a wallet to file
#######################################################

def exportWallet(instName, compName, compType, name, passwd, path):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       objs = [name, password]
       sigs = ["java.lang.String","[C"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       list = mbs.invoke(ks_on,"exportKeyStore",objs,sigs)
       length = len(list)
       if (length == 1):
	  fos = FileOutputStream(path + File.separator + "cwallet.sso")
	  fos.write(list[0])
	  fos.flush()
	  fos.close()
       else:
	  fos = FileOutputStream(path + File.separator + "ewallet.p12")
	  fos.write(list[0])
	  fos.flush()
	  fos.close()
	  fos = FileOutputStream(path + File.separator + "cwallet.sso")
	  fos.write(list[1])
	  fos.flush()
	  fos.close()
       msg = sslconfigBundle.getString("W_EXPORT")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function imports a JKS from file
#######################################################

def importKeyStore(instName, compName, compType, name, passwd, filepath):
    updateGlobals()
    if (connected == 'true'):
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       fis = FileInputStream(filepath)
       num = fis.available()
       arr = zeros(num, 'b')
       fis.read(arr)
       fis.close()
       objs = [name, password, arr]
       sigs = ["java.lang.String","[C", "[B"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"importKeyStore",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("KS_IMPORT")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# This function imports a wallet from file
#######################################################

def importWallet(instName, compName, compType, name, passwd, filepath):
    updateGlobals()
    if (connected == 'true'):
       retval = _validateCompType(compType)
       if (retval == 1):
	  return
       on = getKeyStoreMBeanName(instName, compName, compType)
       password = java.lang.String(passwd).toCharArray()
       fis = FileInputStream(filepath)
       num = fis.available()
       arr = zeros(num, 'b')
       fis.read(arr)
       fis.close()
       objs = [name, password, arr]
       sigs = ["java.lang.String","[C", "[B"]
       ks_on = ObjectName(on)
       invokeLoadMBean(instName, compName)
       mbs.invoke(ks_on,"importKeyStore",objs,sigs)
       invokeSaveMBean(instName, compName)
       msg = sslconfigBundle.getString("W_IMPORT")
       print msg
    else:
       msg = sslconfigBundle.getString("NOT_CONNECTED")
       print msg

#######################################################
# Load the command help
#######################################################

def testMap():
    updateGlobals()
    map = HashMap
    map.put('a','true')
    map.put('b','false')
    for keys in map:
        val = map.get(keys)
        print keys + " : " + val

addSSLConfigCommandHelp()
