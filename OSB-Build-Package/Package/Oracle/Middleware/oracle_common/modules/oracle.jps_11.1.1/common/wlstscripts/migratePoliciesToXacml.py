
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
required = frozenset(['-src', '-dst', '-srcApp','-configFile'])
optional = frozenset(['-dstApp'])
import jpsCmdHelp
argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])
if argmap == None:
	jpsCmdHelp.migratePoliciesToXacmlHelp()
	exit()

src = argmap['src']
dst = argmap['dst']
configFile = argmap['configFile']
srcApp = argmap['srcApp']
dstApp = None


if 'dstApp' in argmap:
	dstApp = argmap['dstApp']

import Opss
Opss.migratePoliciesToXacml(src=src, dst=dst, srcApp=srcApp, dstApp=dstApp,configFile=configFile)
