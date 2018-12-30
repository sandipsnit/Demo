#
# asctl_common.py
#
# Copyright (c) 2001, 2007, Oracle. All rights reserved.  
#
#    NAME
#     asctl_common.py - <one-line expansion of the name>
#
#    DESCRIPTION
#      This script contains some common Jython functions that can be used
#      within asctl.
#
#    NOTES
#      For any variable listed in the "user-configurable common variables"
#      section, this script attempts to retrieve its value in the following
#      order:
#      1) as a command-line argument specified as:
#         --<VAR_NAME>=<VAR_VALUE>
#      2) from the environment
#
#    MODIFIED   (MM/DD/YY)
#    ramalhot    04/18/08 - 
#    arunkri     02/11/07 - 
#    mbhoopat    12/09/06 - 
#    ramalhot    11/29/06 - 
#    mbhoopat    11/20/06 - 
#    ramalhot    11/07/06 - 
#    hmodawel    10/27/06 - 
#    ramalhot    10/12/06 - 
#    cachung     08/22/06 - sync up apache_mats/src/asctl_common.py
#    cachung     08/14/06 - Add Mount point variable
#    cachung     08/10/06 - Add asctl deploy()
#    dsimone     08/15/06 - add oc4j ports
#    huizhao     08/14/06 - add new func getMultiPorts()
#    huizhao     08/12/06 - Add getMultiPorts and getPortString. Modify getPort to share the getPortString with getMultiPorts
#    kdclark     08/08/06 - fix to add Ip Address to getPorts
#    dsimone     06/27/06 - Use getPorts()
#    rbseshad    05/23/06 - Add WebCache port determination.
#    dsimone     05/09/06 - Temporary workaround for ports
#    dsimone     04/10/06 - Creation

import sys
import java.lang.System as System

# Needed for getRdsPort
rdsscript = oracleHome.getCanonicalPath() + '/scripts/rdsconfig.py'
execfile(rdsscript)

#
# Uses asctl getPorts() to figure out the port value of the given endpoint
# (fully specified path)  Returns the output by asctl.
#
def getPortString(endpoint_path):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer
  printMsg("getPorts(\"" + endpoint_path + "\")")

  # redirect asctl stdout to a String
  origStdOut = System.out
  byteArrayStream = ByteArrayOutputStream()
  System.setOut(PrintStream(byteArrayStream))
  getPorts(endpoint_path)

  # restore stdout
  System.setOut(origStdOut)
  resultString = byteArrayStream.toString()
  System.out.println(resultString)

  # figure out the port value based on the syntax of the getPorts() output...
  # a better way?
  portStartString = "| Name      | Dps Id    | Port      | Ip Address |"
  index = resultString.find(portStartString)
  new = resultString[index+len(portStartString) : len(resultString) - 1]

  return new

#
# Uses asctl getRdsPorts() to figure out the port value of the given endpoint
# (fully specified path)  Returns the first port output by asctl.
#
def getPort(endpoint_path):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer
  
  endport = getRdsPort(endpoint_path)
  endport=endport.lstrip()
  endport=endport.rstrip()
  if endport != None:
    return endport
  else:
    return ""

#
# Uses asctl getPorts() to figure out the port value of the given endpoint
# (fully specified path)  Returns the the key-value pair of port output by asctl.
# key = name, value = port No(index = 0 in the array) and dpsid(index = 1 in the array. 
#
def getMultiPorts(endpoint_path):
  from java.lang import String
  from java.util import StringTokenizer
  from java.util import HashMap
  from jarray import zeros 

  new = getPortString(endpoint_path)
  aHashMap = HashMap();
  # after the portStartString, the port value is the 3rd token
  st = StringTokenizer(new, "\n |")
  while st.hasMoreTokens():
    if st.countTokens() >= 3:
       aKey = st.nextToken()
       aStrArray = zeros(3, String);
       aStrArray.__setitem__(0,st.nextToken())
       aStrArray.__setitem__(1,st.nextToken())
       aHashMap.put(aKey, aStrArray);
    else:
       break
  
  return aHashMap

#
# prints the given message
#
def printLog(message):
  sys.stdout.write(message)

#
# gets the OHS HTTP port
#
def getOHSHTTPPort(instance_name, ohs_name):
  return getPort(instance_name + "/" +  ohs_name + "/http_main")

#
# gets the OHS SSL port
#
def getOHSHTTPSPort(instance_name, ohs_name):
  return -1

#
# Gets WebCache HTTP port
#
def getWXHTTPPort(instance_home, wx_name):
  return getWXPort('allocated port ', instance_home, wx_name)

#
# Determine WebCache ports from the below given logfile
# LogFile : <instance_home>/logs/MAS/agent/<wxname>~0
#
def getWXPort(wordOfInterest, instance_home, wx_name):
  file = open (instance_home + '/logs/MAS/agent/' + wx_name + '~0')
  line = file.readline()
  port = None
  temp_line = None
  while line:
    index = line.find(wordOfInterest)
    if index != -1:
      temp_line = line[index+len(wordOfInterest) : len(line) - 2]
      index = temp_line.find(":")
      port = temp_line[index+1 : len(temp_line)]
      return port
    line = file.readline()

#
# gets the OHS HTTP port
#
def getOC4JAJPPort(instance_name, oc4j_name):
  return getPort(instance_name + "/" +  oc4j_name + "/default-web-site:ajp")

#
# gets the OHS HTTP port
#
def getOC4JRMIPort(instance_name, oc4j_name):
  return getPort(instance_name + "/" +  oc4j_name + "/rmi")

#
# gets the OHS HTTP port
#
def getOC4JJMSPort(instance_name, oc4j_name):
  return getPort(instance_name + "/" +  oc4j_name + "/jms")
    
    
    
#
# retrieves the given variable value from the Jython command-line
# arguments, or the environment if not set as a command-line argument
#
def getVar(varName):
  for arg in sys.argv[1:]:
    argFlag = '--' + varName + '='
    if arg.startswith(argFlag):
      return arg[len(argFlag) : len(arg)]
  if System.getenv(varName) is not None:
    return System.getenv(varName)
  else:
    return ""

#
# prints the given message for debugging purposes
#
def printMsg(message):
  sys.stderr.write(message + "\n")

#
# prints messages to env file
#
#
# set all common variables
#
OHS_COMPONENT_TYPE = 'OHSComponent'
WX_COMPONENT_TYPE = 'WebCacheComponent'
OC4J_COMPONENT_TYPE = 'OC4JComponent'
SRCHOME = getVar('SRCHOME')
T_WORK = getVar('T_WORK')

#
# user-configurable common variables that can be retrieved from
# the environment or passed as Jython arguments
#
EM_MAS_INSTANCE_HOME = getVar('EM_MAS_INSTANCE_HOME')
EM_MAS_INSTANCE_NAME = getVar('EM_MAS_INSTANCE_NAME')
EM_INSTANCE_HOME = getVar('EM_INSTANCE_HOME')
EM_INSTANCE_NAME = getVar('EM_INSTANCE_NAME')
EM_FARM_NAME = getVar('EM_FARM_NAME')
EM_MAS_JMX_PORT = getVar('EM_MAS_JMX_PORT')
EM_MAS_CONN_URL = getVar('LONG_HOSTNAME')+":"+getVar('EM_MAS_JMX_PORT')
EM_ADMIN_USERNAME = getVar('EM_ADMIN_USERNAME')
EM_ADMIN_PASSWORD = getVar('EM_ADMIN_PASSWORD')
EM_OHS_NAME = getVar('EM_OHS_NAME')
EM_OC4J_NAME = getVar('EM_OC4J_NAME')
WX_NAME = getVar('WX_NAME')
EARFILE = getVar('EARFILE')
DEPLOY_URL = getVar('DEPLOY_URL')
OC4JADMIN_USER = getVar('OC4JADMIN_USER')
OC4JADMIN_PWD = getVar('OC4JADMIN_PWD')
APPNAME = getVar('APPNAME')
DEBUGLOG =getVar('DEBUGLOG')
MOUNT_PT = getVar('MOUNT_PT')
EM_PDS_ENABLED = getVar('EM_PDS_ENABLED')

