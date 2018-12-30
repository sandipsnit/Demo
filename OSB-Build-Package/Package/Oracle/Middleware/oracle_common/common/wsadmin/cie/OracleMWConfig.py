# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

"""Oracle Middleware Configuration"""

import cie.ConfigUtilities as utils

from org.python.util import PythonInterpreter
from com.oracle.cie.was.wsadmin import WSAdminExtension
import cie.OracleHelp as OracleHelp

def init(namespace):
  WSAdminExtension.init(PythonInterpreter(namespace))

def cmd(name, *args):
  return WSAdminExtension.getInstance().runCmd(name, args)
#enddef -- cmd

def startConfig():
  cmd("startConfig")

def selectTemplate(path):
  cmd("selectTemplate", path)

def loadTemplates():
  cmd("loadTemplates")

def showTemplates():
  return cmd("showTemplates")

def endConfig():
  cmd("save")

def getChildren(type):
  return cmd("getChildren",type)

def create(type,atts):
  return cmd("create",type,atts)

def clone(wrapper,atts):
  return cmd("clone",wrapper,atts)

def list(type):
  return cmd("list", type)

def assign(type, name, wrapper, atts = []):
  cmd("assign", type, name, wrapper, atts)

def unassign(type, name, wrapper, atts = []):
  cmd("unassign", type, name, wrapper, atts)

def delete(wrapper):
  return cmd("delete",wrapper)

def getTypes():
  return cmd("getTypes")  

def getChildByName(type,name,scope = None):
  return cmd("getChildByName",type,name,scope)

def validateConfig(optionName):
  return cmd("validateConfig",optionName)

def setCurrentTemplate(tmplLoc = None):
  cmd("setCurrentTemplate", tmplLoc)

def clearCurrentTemplate():
  cmd("setCurrentTemplate", None)

def retrieveObject(key):
  return cmd("retrieveObject", key)

def storeObject(key, value):
  cmd("storeObject", key, value)

def copyFile(src, scope, wasRelativeDir, configGroup):
  cmd("copyFile", src, scope, wasRelativeDir, configGroup)

def registerOracleHomes(dmgrProfilePath = None):
  if dmgrProfilePath == None:
    cmd("registerOracleHomes")
  else:
    WSAdminExtension.getInstance().registerOracleHomes(dmgrProfilePath)

def help(topic = None):
  m_name = 'OracleMWConfig'
  if topic == None:
    topic = m_name
  else:
    topic = m_name + '.' + topic
  return OracleHelp.help(topic)

def dumpStack():
  WSAdminExtension.dumpStack()

def suppressException(suppress):
  WSAdminExtension.suppressException(suppress)





