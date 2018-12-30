# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

"""Oracle Help"""

import cie.ConfigUtilities as utils

from com.oracle.cie.domain.script.help import Help

def init():
    Help.init()
  
def help(topic = None):
    return Help.getHelp().help(topic)
  
def setConsoleWidth(value):
    Help.getHelp().setConsoleWidth(value)

