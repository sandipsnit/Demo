#implements listAttributes
#Author: divyasin
#Creation 10/26/2010

import sys

from sets import ImmutableSet as frozenset
required = frozenset(['-appStripe'])
optional = frozenset(['-hideBuiltIn'])
import jpsCmdHelp

argmap = jpsCmdHelp.verifyArgs(required, optional, sys.argv[1:])

if argmap == None:
    jpsCmdHelp.listAttributesHelp()
    exit()

appStripe = argmap['appStripe']
hideBuiltIn = None

if 'hideBuiltIn' in argmap:
        hideBuiltIn = argmap['hideBuiltIn']

connect()
import Opss
Opss.listAttributes(appStripe=appStripe, hideBuiltIn=hideBuiltIn)
