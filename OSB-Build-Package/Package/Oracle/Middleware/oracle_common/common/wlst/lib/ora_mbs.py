# WLST implementation of ora_mbs module. 
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


import wlstModule as wlst
global _mbs
_mbs = None

# If a connection is established outside the 'wlst' namespace then
# the mbs must be explicitly passed in to the ora_mbs module via
# the setMbs() method. 
#
# WLST commands must explicitly call the setMbs() if they are to make
# use of the ora_mbs() online APIs.

def setMbs(arg):
	global _mbs
	_mbs = arg

def getMbsInstance():
	global _mbs
	if _mbs is None:
		_mbs = wlst.mbs
	return _mbs
	

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

## Additional helper API

def makeObjectName(objectNameString):
	import javax.management as _mgmt
	return _mgmt.ObjectName(objectNameString)

# note: cannot use wlst.connected if connection was established outside module
def isConnected():
	if getMbsInstance() is None : return 0
	else : return 1

def isScriptMode():
	if wlst.scriptMode == 'true' : return 1
	else : return 0
	
# platform API

def getPlatform():
	return 'WLS'

def getScriptingPlatform():
	return 'WLST'

def isWebSphere():
	return 0

def isWebLogic():
	return 1

def isJBoss(): 
	return 0

def isWebSphereAS():
	return 0

def isWebSphereND():
	return 0
