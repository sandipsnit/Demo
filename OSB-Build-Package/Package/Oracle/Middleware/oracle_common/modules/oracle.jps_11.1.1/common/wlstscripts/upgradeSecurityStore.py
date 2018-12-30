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
required = frozenset(['-type'])
optional = frozenset(['-srcRealm', '-dst', '-srcJaznConfigFile', '-srcJaznDataFile', '-jpsConfigFile', '-users', '-dstJaznDataFile', '-resourceTypeFile', '-srcApp', '-jpsContext'])
import jpsCmdHelp
argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])
if argmap == None:
	jpsCmdHelp.UpgradeSecurityStoreHelp()
	exit()

type = argmap['type']
srcRealm = None
dst = None
srcJaznConfigFile = None
srcJaznDataFile = None
jpsConfigFile = None
users = None
dstJaznDataFile = None
resourceTypeFile = None
srcApp = None
jpsContext = None
if 'srcRealm' in argmap:
	srcRealm = argmap['srcRealm']
if 'dst' in argmap:
	dst = argmap['dst']
if 'srcJaznConfigFile' in argmap:
	srcJaznConfigFile = argmap['srcJaznConfigFile']
if 'srcJaznDataFile' in argmap:
	srcJaznDataFile = argmap['srcJaznDataFile']
if 'jpsConfigFile' in argmap:
	jpsConfigFile = argmap['jpsConfigFile']
if 'users' in argmap:
	users = argmap['users']
if 'dstJaznDataFile' in argmap:
	dstJaznDataFile = argmap['dstJaznDataFile']
if 'resourceTypeFile' in argmap:
	resourceTypeFile = argmap['resourceTypeFile']
if 'srcApp' in argmap:
	srcApp = argmap['srcApp']
if 'jpsContext' in argmap:
	jpsContext = argmap['jpsContext']

import jpsWlstCmd
jpsWlstCmd.upgradeSecurityStore(type=type, srcRealm=srcRealm, dst=dst, srcJaznConfigFile=srcJaznConfigFile, srcJaznDataFile=srcJaznDataFile, jpsConfigFile=jpsConfigFile, users=users, dstJaznDataFile=dstJaznDataFile, resourceTypeFile=resourceTypeFile, srcApp=srcApp)

