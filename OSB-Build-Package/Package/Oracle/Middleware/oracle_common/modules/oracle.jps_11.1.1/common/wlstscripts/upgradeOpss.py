# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################################
# Caution: This file is part of the WLST implementation. Do not edit or move   #
# this file because this may cause WLST commands and scripts to fail. Do not   #
# try to reuse the logic in this file or keep copies of this file because this #
# could cause your WLST scripts to fail when you upgrade to a different version#
# of WLST.                                                                     #
################################################################################

import sys

from sets import ImmutableSet as frozenset
required = frozenset(['-jpsConfig', '-jaznData'])
optional = frozenset(['-auditStore', '-jdbcDriver', '-url', '-user', '-password'])
import jpsCmdHelp

argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])

if argmap == None:
    jpsCmdHelp.upgradeHelp()
    exit()

jpsConfig = argmap['jpsConfig']
jaznData = argmap['jaznData']
auditStore = None
jdbcDriver = None
url = None
user = None
password = None
upgradeJseStoreType = None

if 'auditStore' in argmap:
        auditStore = argmap['auditStore']
if 'jdbcDriver' in argmap:
        jdbcDriver = argmap['jdbcDriver']
if 'url' in argmap:
        url = argmap['url']
if 'user' in argmap:
        user = argmap['user']
if 'password' in argmap:
        password = argmap['password']
if 'upgradeJseStoreType' in argmap:
        upgradeJseStoreType = argmap['upgradeJseStoreType']

import jpsWlstCmd
jpsWlstCmd.upgradeOpss(jpsConfig=jpsConfig, jaznData=jaznData, auditStore=auditStore, jdbcDriver=jdbcDriver, url=url, user=user, password=password, upgradeJseStoreType=upgradeJseStoreType)
