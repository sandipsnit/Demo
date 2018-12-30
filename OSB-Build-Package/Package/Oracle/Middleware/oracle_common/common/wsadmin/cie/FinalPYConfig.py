# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

import cie.ConfigUtilities as utils

from org.python.util import PythonInterpreter
from com.oracle.cie.was.wsadmin import WSAdminExtension

def cmd(name, *args):
  return WSAdminExtension.getInstance().runCmd(name, args)
#enddef -- cmd

def retrieveObject(key):
  return cmd("retrieveObject", key)

def storeObject(key, value):
  cmd("storeObject", key, value)

def copyFile(src, scope, wasRelativeDir, configGroup):
  cmd("copyFile", src, scope, wasRelativeDir, configGroup)

def setCurrentTemplate(tmplLoc = None):
  cmd("setCurrentTemplate", tmplLoc)

def clearCurrentTemplate():
  cmd("setCurrentTemplate", None)  