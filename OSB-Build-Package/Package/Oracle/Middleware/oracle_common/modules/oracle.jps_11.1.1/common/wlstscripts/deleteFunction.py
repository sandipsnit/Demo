#implements deleteFunction
#Author: divyasin
#Creation 10/26/2010

import sys

from sets import ImmutableSet as frozenset
required = frozenset(['-appStripe', '-functionName'])
optional = frozenset([])
import jpsCmdHelp

argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])

if argmap == None:
    jpsCmdHelp.deleteFunctionHelp()
    exit()

appStripe = argmap['appStripe']
functionName = argmap['functionName']

connect()
import Opss
Opss.deleteFunction(appStripe=appStripe, functionName=functionName)
