# OJBST implementation of ora_utils module. 
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

global _cachedhook
_cachedhook = None

def hideDisplay():
	cacheHook()
	import sys
	sys.displayhook = _quickPauseHook
	
def restoreDisplay():
	restoreHook()

# In OJBST, the script_handlers folder is automatically added to the path.
def addScriptHandlers():
	#this is a no-op in JBOSS
	return None
	
# OracleScriptingExceptions are used to wrap underlying Java Exceptions.
# This is done to clean up the display.
# The underlying exception can be accessed via the getCause() API.								
def raiseScriptingException(acause = None):
	ose = OracleScriptingException(acause.getMessage())
	ose.setCause(acause)
	raise ose

from org.python.core import PyString
class OracleScriptingException(Exception):
	cause = None
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return PyString(self.value)
	def getCause(self):
		return self.cause
	def setCause(self, acause):
		self.cause = acause

# undocumented  - internal API

def cacheHook():
	global _cachedhook
	if _cachedhook is None :
		import sys
		_cachedhook = sys.displayhook

def restoreHook():
	global _cachedhook 
	if not _cachedhook is None:
		import sys
		sys.displayhook = _cachedhook 

def _quickPauseHook(arg):
	restoreHook()
