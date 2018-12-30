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
required = frozenset(['-type', '-src', '-dst', '-configFile'])
optional = frozenset(['-srcApp', '-dstApp', '-srcFolder', '-dstFolder', '-dstLdifFile', '-srcConfigFile', '-processPrivRole', '-resourceTypeFile', '-overWrite', '-migrateIdStoreMapping', '-preserveAppRoleGuid', '-reportFile', '-mode'])
import jpsCmdHelp
argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])
if argmap == None:
	jpsCmdHelp.MigrateSecurityStoreHelp()
	exit()

type = argmap['type']
src = argmap['src']
dst = argmap['dst']
configFile = argmap['configFile']
srcApp = None
dstApp = None
srcFolder = None
dstFolder = None
dstLdifFile = None
srcConfigFile = None
processPrivRole = None
resourceTypeFile = None
overWrite = None
migrateIdStoreMapping = None
preserveAppRoleGuid = None
reportFile = None
mode = None
if 'srcApp' in argmap:
	srcApp = argmap['srcApp']
if 'dstApp' in argmap:
	dstApp = argmap['dstApp']
if 'srcFolder' in argmap:
	srcFolder = argmap['srcFolder']
if 'dstFolder' in argmap:
	dstFolder = argmap['dstFolder']
if 'dstLdifFile' in argmap:
	dstLdifFile = argmap['dstLdifFile']
if 'srcConfigFile' in argmap:
	srcConfigFile = argmap['srcConfigFile']
if 'processPrivRole' in argmap:
	processPrivRole = argmap['processPrivRole']
if 'resourceTypeFile' in argmap:
	resourceTypeFile = argmap['resourceTypeFile']
if 'overWrite' in argmap:
	overWrite = argmap['overWrite']
if 'migrateIdStoreMapping' in argmap:
	migrateIdStoreMapping = argmap['migrateIdStoreMapping']
if 'preserveAppRoleGuid' in argmap:
	preserveAppRoleGuid = argmap['preserveAppRoleGuid']
if 'reportFile' in argmap:
	reportFile = argmap['reportFile']
if 'mode' in argmap:
	mode = argmap['mode']

import jpsWlstCmd
jpsWlstCmd.migrateSecurityStore(type=type, src=src, dst=dst, srcApp=srcApp, dstApp=dstApp, srcFolder=srcFolder, dstFolder=dstFolder, dstLdifFile=dstLdifFile, srcConfigFile=srcConfigFile, configFile=configFile, processPrivRole=processPrivRole, resourceTypeFile=resourceTypeFile, overWrite=overWrite, migrateIdStoreMapping=migrateIdStoreMapping, preserveAppRoleGuid=preserveAppRoleGuid, reportFile=reportFile, mode=mode)
