# Copyright (c) 2009, 2010, Oracle and/or its affiliates. All rights reserved. 
################################################################################
# Caution: This file is part of the WLST implementation. Do not edit or move   #
# this file because this may cause WLST commands and scripts to fail. Do not   #
# try to reuse the logic in this file or keep copies of this file because this #
# could cause your WLST scripts to fail when you upgrade to a different version# 
# of WLST.                                                                     #
################################################################################

import sys

from sets import ImmutableSet as frozenset
required = frozenset(['-permClass'])
optional = frozenset(['-appStripe', '-codeBaseURL', '-principalClass', '-principalName', '-permTarget', '-permActions'])
import jpsCmdHelp
argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])
if argmap == None:
	jpsCmdHelp.revokePermissionHelp()
	exit()

permClass = argmap['permClass']
appStripe = None
codeBaseURL = None
principalClass = None
principalName = None
permTarget = None
permActions = None
if 'appStripe' in argmap:
	appStripe = argmap['appStripe']
if 'codeBaseURL' in argmap:
	codeBaseURL = argmap['codeBaseURL']
if 'principalClass' in argmap:
	principalClass = argmap['principalClass']
if 'principalName' in argmap:
	principalName = argmap['principalName']
if 'permTarget' in argmap:
	permTarget = argmap['permTarget']
if 'permActions' in argmap:
	permActions = argmap['permActions']

connect()
import jpsWlstCmd 
jpsWlstCmd.revokePermission(appStripe=appStripe, codeBaseURL=codeBaseURL, principalClass=principalClass, principalName=principalName, permClass=permClass, permTarget=permTarget, permActions=permActions)


