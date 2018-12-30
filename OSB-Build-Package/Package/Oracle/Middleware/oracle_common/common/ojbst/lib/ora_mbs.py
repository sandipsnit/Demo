# OJBST implementation of ora_mbs module
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.
# 
# This is an internal API to be used only by ORACLE scripting implementations and is not 
# supported for general use.
#
# The ora_mbs module provides a partial implementation of the MBeanServerConnection interface
# and provides uniform access to the online modes of WLST, WSADMIN and OJBST. 
#
# Additional APIs are provided to determine the current platform.

from java.lang import System
from java.util import Properties
from javax.naming import InitialContext
from javax.management import NotificationListener,ObjectName,MBeanInfo,MBeanAttributeInfo

global _server_
_server_ = None
global _isConnected_
_isConnected_ = 0


# setMbs is used in the event that another MBeanServerConnection needs to be supplied
# other than the one obtained through the connect() API
def setMbs(arg):
	global _server_
	_server_ = arg

# will default to the OracleJMX mbs instance if it is available when nothing else has
# been set
def getMbsInstance():
	import OracleJMX
	global _server_
	if _server_ is None:
		setMbs(OracleJMX.getMbsInstance())			
	return _server_

## Standard JMX MBeanServer API
def getAttribute(name, attribute):
	return getMbsInstance().getAttribute(name, attribute)

def getAttributes(name, attributes):
	return getMbsInstance().getAttributes(name, attributes)

def getDefaultDomain():
	return getMbsInstance().getDefaultDomain()	

def getMBeanCount():
	return getMbsInstance().getMBeanCount()

def getMBeanInfo(name):
	return getMbsInstance().getMBeanInfo(name)

def invoke(name, operationname, params, signature):
	return getMbsInstance().invoke(name, operationname, params, signature)

def isRegistered(name):
	return getMbsInstance().isRegistered(name)	

def queryNames(name, query):
	return getMbsInstance().queryNames(name, query)

def queryMBeans(name, query):
	return getMbsInstance().queryMBeans(name, query)
          
def setAttribute(name, attribute):
	getMbsInstance().setAttribute(name, attribute)

def setAttributes(name, attributes):
	return getMbsInstance().setAttributes(name, attributes)
	
def isScriptMode():
	smprop = System.getProperty('ojbst.isScriptMode')
	if smprop == 'true' : return 1 
	else : return 0


def makeObjectName(objectNameString):
	import javax.management as _mgmt
	return _mgmt.ObjectName(objectNameString)

# platform API - extended to match the ServerPlatformSupport API from JRF
		
def getPlatform():
	return 'JBOSS'

def getScriptingPlatform():
	return 'OJBST'

def isWebSphere():
	return 0

def isWebLogic():
	return 0

def isJBoss(): 
	return 1

def isWebSphereAS():
	return 0

def isWebSphereND():
	return 0

## Basic connection API for community edition - 
#  It is recommended to use the OracleJMX connection methods instead of these
#
# Use OracleJMX.connect() to form a connection via OracleJMX
def connect(user='', cred='', url='jnp://localhost:1099'):
	props = Properties(System.getProperties())
	props.put("java.naming.security.principal", user)
	props.put("java.naming.security.credentials", cred)
	props.put("java.naming.provider.url", url)
	props.put("java.naming.factory.initial", "org.jnp.interfaces.NamingContextFactory")
	props.put("java.naming.factory.url.pkgs","org.jboss.naming:org.jnp.interfaces")	
	ctx = InitialContext(props)
	adapterName = "jmx/invoker/RMIAdaptor"
	global _server_
	_server_ = ctx.lookup(adapterName)
	ctx.close()
	global _isConnected_
	_isConnected_ = 1
	return _server_
	
# Use OracleJMX.disconnect() to sever a connection via OracleJMX
def disconnect():
	global _server_
	_server_ = None
	global _isConnected_
	_isConnected_ = 0

# Use the OracleJMX.isConnected() API
def isConnected():
	import OracleJMX
        if OracleJMX.isConnected() :
		return OracleJMX.isConnected()
	global _isConnected_
	return _isConnected_
