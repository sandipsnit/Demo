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
required = frozenset(['-phase', '-patchDeltaFolder', '-productionJpsConfig'])
optional = frozenset(['-baselineFile', '-patchFile', '-baselineAppStripe', '-productionAppStripe', '-patchAppStripe', '-silent', '-ignoreEnterpriseMembersOfAppRole', '-reportFile', '-ignoreEnterpriseAppRoleMembershipConflicts'])
import jpsCmdHelp

argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])

if argmap == None:
    jpsCmdHelp.patchPolicyStoreHelp()
    exit()

phase = argmap['phase']
baselineFile = None
patchFile = None
productionJpsConfig = argmap['productionJpsConfig']
patchDeltaFolder = argmap['patchDeltaFolder']
baselineAppStripe = None
productionAppStripe = None
patchAppStripe = None
silent = "false"
ignoreEnterpriseMembersOfAppRole = None
reportFile = None
ignoreEnterpriseAppRoleMembershipConflicts = None

if 'baselineFile' in argmap:
    baselineFile = argmap['baselineFile']
if 'patchFile' in argmap:
    patchFile = argmap['patchFile']
if 'baselineAppStripe'in argmap:
    baselineAppStripe = argmap['baselineAppStripe']
if 'productionAppStripe' in argmap:
    productionAppStripe = argmap['productionAppStripe']
if 'patchAppStripe' in argmap:
    patchAppStripe = argmap['patchAppStripe']
if 'silent' in argmap:
    silent = argmap['silent']
if 'ignoreEnterpriseMembersOfAppRole' in argmap:
    ignoreEnterpriseMembersOfAppRole = argmap['ignoreEnterpriseMembersOfAppRole']
if 'reportFile' in argmap:
    reportFile = argmap['reportFile']
if 'ignoreEnterpriseAppRoleMembershipConflicts' in argmap:
    ignoreEnterpriseAppRoleMembershipConflicts = argmap['ignoreEnterpriseAppRoleMembershipConflicts']    

import jpsWlstCmd
jpsWlstCmd.patchPolicyStore(phase=phase, patchDeltaFolder=patchDeltaFolder, productionJpsConfig=productionJpsConfig, baselineFile=baselineFile, patchFile=patchFile, baselineAppStripe=baselineAppStripe, productionAppStripe=productionAppStripe, patchAppStripe=patchAppStripe, silent=silent, ignoreEnterpriseMembersOfAppRole=ignoreEnterpriseMembersOfAppRole, reportFile=reportFile, ignoreEnterpriseAppRoleMembershipConflicts=ignoreEnterpriseAppRoleMembershipConflicts)
