# Wrapper API for WSADMIN and WLST utilities
# From within platform-neutral code, import ora_util, and use this API to access
# platform utilities


# these methods are for hiding and restoring display
global _cachedhook
_cachedhook = None

def hideDisplay():
	cacheHook()
	import sys
	sys.displayhook = _quickPauseHook
	
def restoreDisplay():
	restoreHook()

# end hide/restore display commands


def addScriptHandlers():
	#this is a no-op in WSADMIN
	return None
							
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

### internal - not public API
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

