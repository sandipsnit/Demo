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
required = frozenset(['-adminRoleName'])
optional = frozenset(['-appStripe', '-policyDomainName','-displayName','-description'])
import jpsCmdHelp

argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])

if argmap == None:
    jpsCmdHelp.createAdminRoleHelp()
    exit()

appStripe = None
adminRoleName = argmap['adminRoleName']
policyDomainName = None
displayName = None
description = None
if 'appStripe' in argmap:
        appStripe = argmap['appStripe']
if 'policyDomain' in argmap:
        policyDomainName = argmap['policyDomainName']
if 'displayName' in argmap:
        displayName = argmap['displayName']
if 'description' in argmap:
        description = argmap['description']

connect()
import Opss
Opss.createAdminRole(appStripe=appStripe, policyDomainName=policyDomainName, adminRoleName=adminRoleName, displayName=displayName, description=description)

