#implements deletePolicy
#Author: divyasin
#Creation 10/26/2010

import sys

from sets import ImmutableSet as frozenset
required = frozenset(['-appStripe', '-policyName'])
optional = frozenset([])
import jpsCmdHelp

argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])

if argmap == None:
    jpsCmdHelp.deletePolicyHelp()
    exit()

appStripe = argmap['appStripe']
policyName = argmap['policyName']

connect()
import Opss
Opss.deletePolicy(appStripe=appStripe, policyName=policyName)
