# WLST implementation of ora_utils module. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.
# 
# This is an internal API to be used only by ORACLE scripting implementations and is not 
# supported for general use.
#
# The ora_utils module provides APIs for managing the display of exceptions and to control the
# printing of return values from methods.


import wlstModule as wlst

# hideDisplay() is called before a return statement if we want to turn off the automatic
# printing of return types. This is useful when the return type is a list, array, or object type,
# since the default printing is not pretty.
# In WLST, if your method calls the domainRuntime() method, this method already invokes hideDisplay()
def hideDisplay():
	wlst.hideDisplay()

def restoreDisplay():
	wlst.restoreDisplay()
	
# Invoking addScriptHandlers() will add the script_handlers directory to the path and
# load its modules.
def addScriptHandlers():
	import java.lang.System
	import os
	import sys
	#add common components script handlers, if required
	_cch = java.lang.System.getProperty('COMMON_COMPONENTS_HOME')
	_shh = os.path.join(_cch, 'common/script_handlers')
	if not (_shh in sys.path):
		sys.path.append(_shh)	
	# add oracle home script handlers, if required.
	_oh = java.lang.System.getProperty('ORACLE_HOME')
	_oh_shh = os.path.join(_oh, 'common/script_handlers')
	if not (_oh_shh in sys.path):
		sys.path.append(_oh_shh)		
			
# OracleScriptingExceptions are used to wrap underlying Java Exceptions.
# This is done to clean up the display.
# The underlying exception can be accessed via the getCause() API.								
def raiseScriptingException(acause = None):
	ose = OracleScriptingException(acause.getMessage())
	ose.setCause(acause)
	wlst.setDumpStackThrowable(acause)
	raise ose

from org.python.core import PyString
class OracleScriptingException(wlst.WLSTException):
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return PyString(self.value)
	def getCause(self):
		return self.cause
	def setCause(self, acause):
		self.cause = acause

