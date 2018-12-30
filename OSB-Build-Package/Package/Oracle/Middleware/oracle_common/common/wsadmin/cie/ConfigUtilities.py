# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

"""Common Configuration Utilities"""

import com.oracle.cie.was.wsadmin.WSAdminExtension as AdminExt

# print levels
LEVELS = {"ERROR" : 1, "INFO" : 3, "DEBUG" : 4 }

# current message level
_level = LEVELS["INFO"]

def setLevel(level):
  global _level
  _level = LEVELS[level]

def error(msg = ""):
  printMessage(msg, "ERROR")

def info(msg = ""):
  printMessage(msg, "INFO")

def debug(msg = ""):
  printMessage(msg, "DEBUG")

def printMessage(msg, level):
  AdminExt.log(msg, level)
  if LEVELS[level] <= _level:
    print msg

def getI18nString(key, *args):
  return AdminExt.getI18nString(key, args)
