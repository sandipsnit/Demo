# WLST implementation of ora_help module
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.
# 
# This is an internal API to be used only by ORACLE scripting implementations and is not 
# supported for general use.
#

import wlstModule as wlst	

def addHelpCommandGroup(groupName, resourceBundleName):
	wlst.addHelpCommandGroup(groupName, resourceBundleName)
	
def addHelpCommand(commandName, groupName, offline='false', online='false'):
	wlst.addHelpCommand(commandName, groupName, offline, online)
	
