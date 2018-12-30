# WSADMIN implementation of ora_mbs module.
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

global _mbs
_mbs = None

global _isND
_isND = None

# setMBs is required in WLST and OJBST but not in WSADMIN - AdminControl must be used
# as the underlying MBeanServerConnection - in WSADMIN the setMbs() is a no-op.
def setMbs(arg):
	return None
	
def getMbsInstance():
	global _mbs
	if _mbs is None:
		_mbs = _MBS()
	return _mbs

## Standard JMX MBeanServer API - delegates to MBSInstance
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
	#WSADMIN docs are not clear on this.
	return getMbsInstance().queryMBeans(name, query)		

def setAttribute(name, attribute):
	getMbsInstance().setAttribute(name, attribute)

def setAttributes(name, attributes):
	return getMbsInstance().setAttributes(name, attributes)

#############

## Additional helper API
def makeObjectName(objectNameString):
	import javax.management as _mgmt
	return _mgmt.ObjectName(objectNameString)

## returns 1 or 0 rather than 'true' or 'false'
def isConnected():
	try:
		getMbsInstance().getHost()
		return 1
	except:
		return 0	

## returns 1 or 0 rather than 'true' or 'false'	
def isScriptMode():
	import java.lang.System
	cmndline = java.lang.System.getProperty('sun.java.command')
	cmnd_mode = cmndline.find('-c ')
	file_mode = cmndline.find('-f ')
	if (cmnd_mode != -1) or (file_mode != -1): return 1
	else : return 0

# platform API 

def getPlatform():
	return 'WAS'

def getScriptingPlatform():
	return 'WSADMIN'

def isWebSphere():
	return 1

def isWebLogic():
	return 0

def isJBoss(): 
	return 0

def isWebSphereAS():
	return not isWebSphereND()

def isWebSphereND():
	global _isND
	if _isND is None:
		try:
			import OracleJRF
			OracleJRF.jrf_getDmgrServer()
			_isND = 1
		except:
			_isND = 0
	return _isND

# Note that the _MBS class provides only a partial implementation of the 
# MBeanServerConnection interface (that which is provided by AdminControl).
# Invocation of non-supported MBeanServerConnection methods will result
# in an exception. 
#
# A wrapper class is required here to allow the MBS to be accessed as an
# object - the API of AdminControl does not exactly match the expected 
# JMX API.

from javax.management import MBeanServerConnection
class _MBS(MBeanServerConnection):
	def getAttribute(self, name, attribute):
		return AdminControl.getAttribute_jmx(name, attribute)

	def getAttributes(self, name, attributes):
		return AdminControl.getAttributes_jmx(name, attributes)

	def getDefaultDomain(self):
		return AdminControl.getDefaultDomain()	

	def getMBeanCount(self):
		return AdminControl.getMBeanCount()

	def getMBeanInfo(self, name):
		return AdminControl.getMBeanInfo_jmx(name)

	def invoke(self, name, operationname, params, signature):
		return AdminControl.invoke_jmx(name, operationname, params, signature)

	def isRegistered(self, name):
		return AdminControl.isRegistered_jmx(name)	

	def queryNames(self, name, query):
		return AdminControl.queryNames_jmx(name, query)

	def queryMBeans(self, name, query):
		#WSADMIN docs are not clear on this.
		return AdminControl.queryMBeans(name.toString(), query)		

	def setAttribute(self, name, attribute):
		AdminControl.setAttribute_jmx(name, attribute)

	def setAttributes(self, name, attributes):
		return AdminControl.setAttributes_jmx(name, attributes)
	
	def getHost(self):
		return AdminControl.getHost()
		

