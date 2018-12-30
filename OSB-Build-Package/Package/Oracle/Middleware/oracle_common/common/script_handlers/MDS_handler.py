"""
 Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
This file defines the common utility methods to be used internally for 
MDS scripting commands. 
No platform-specific code should be added to this file.
-------------------------------------------------------------------------------
llu      03/12/11 - #(12979015) Improve multitenancy usability
dibhatta 10/04/11 - #10368255 backport from #(9346064 - llu) Addition for 
                    empty string and empty array element validation
llu      09/08/11 - Check null tenant name situation in printTenants
llu      12/20/10 - #(11073853) Add cust value support
llu      10/14/10 - #(10154988) Add excludeCustFor option to exportMetadata
llu      06/07/10 - Add update sandbox support
jhsi     05/26/10 - #(9749917) Remove line to import OracleHelp
llu      04/25/10 - Remote sandbox transfer support.
jhsi     04/01/10 - Creation.
-------------------------------------------------------------------------------
"""
import jarray
import sys

from jarray import array

from java.lang import Boolean
from java.lang import Class
from java.lang import Object
from java.lang import Exception
from java.lang import String
from java.lang import StringBuffer
from java.lang import System
from java.lang import Thread
from java.lang import Void

from java.util import ArrayList
from java.util import List
from java.util import Map
from java.util import Set

from javax.management import ObjectName

import ora_mbs
import ora_util

from oracle.mds.lcm.client import MDSAppInfo
from oracle.mds.lcm.client import MetadataTransferManager
from oracle.mds.lcm.client import TargetInfo
from oracle.mds.lcm.client import TransferParameters
from oracle.mds.lcm.client import ProgressObject
from oracle.mds.lcm.client import ProgressStatus

from oracle.mds.common.util import ScriptMessageHelper

from org.python.core import PyArray
from org.python.core import PyInteger
from org.python.core import PyString

from pprint import pformat

"""
-------------------------------------------------------------------------------
Private Utility methods
IMPORTANT: These methods are not exposed for external users. They are for internal
MDS use and can change for internal reasons. 
-------------------------------------------------------------------------------
"""
def isConnectedToServer(operation):
    if ( ora_mbs.isConnected() == 'false'):
		raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("NOT_CONNECTED_TO_SERVER", 'WebSphere', operation)

def executeMetadataTransferManagerOperation(application, node, server, mbeanOperation, params, signature, paramNames):
	isConnectedToServer(mbeanOperation)
	validateDataTypes(params, signature, paramNames, mbeanOperation)

	printMessage("START_OPERATION", mbeanOperation)
        try:
                mtm = createMetadataTransferManager()
                appInfo = MDSAppInfo(application)
                target = TargetInfo(server, node)
                transParams = createTransferParameters(params, paramNames)
                progress = None
                if (mbeanOperation == 'importMetadata'):
                        fromLoc = getParamValue(params, paramNames, 'fromLocation')
                        progress = mtm.importMetadata(appInfo, target, fromLoc, transParams)
                elif (mbeanOperation == 'exportMetadata'):
                        toLoc = getParamValue(params, paramNames, 'toLocation')
                        progress = mtm.exportMetadata(appInfo, target, toLoc, transParams)
                elif (mbeanOperation == 'updateSandboxMetadata'):
                        mbeanOperation = 'importSandboxMetadata';
                        fromLoc = getParamValue(params, paramNames, 'fromArchive')
                        sandboxName = getParamValue(params, paramNames, 'sandboxName')
                        progress = mtm.importSandboxMetadata(appInfo, target, fromLoc, sandboxName)
                elif (mbeanOperation == 'importSandboxMetadata'):
                        fromLoc = getParamValue(params, paramNames, 'fromArchive')
                        progress = mtm.importSandboxMetadata(appInfo, target, fromLoc, transParams)
                elif (mbeanOperation == 'exportSandboxMetadata'):
                        toLoc = getParamValue(params, paramNames, 'toArchive')
                        progress = mtm.exportSandboxMetadata(appInfo, target, toLoc, transParams)
                lastState = None
                while not (progress.isCompleted() or progress.isFailed()):
                        state = progress.getStatus().getState()
                        if state != lastState:
                                if lastState is not None:
                                        print ''
                                print progress.getStatus().getMessage(),
                                lastState = state
                        else:
                                print '.', # Trailing comma avoids new line
                        Thread.currentThread().sleep(100);
                print ''
                print progress.getStatus().getMessage()
                if progress.isFailed():
                        ex = progress.getException()
                        if ex is not None:
                                raise ex
                return progress.getResults()
        except Exception, e:
                tp,val,tb = sys.exc_info()
                print val
                saveStackAndRaiseException(e, ScriptMessageHelper.getMessage("OPERATION_FAILED", mbeanOperation))

def createMetadataTransferManager():
        asPlatform = None
        if ora_mbs.isWebLogic():
                asPlatform = MetadataTransferManager.ASPlatform.WEBLOGIC
        elif ora_mbs.isWebSphereND():
                asPlatform = MetadataTransferManager.ASPlatform.WEBSPHERE
        elif ora_mbs.isWebSphereAS():
                asPlatform = MetadataTransferManager.ASPlatform.WEBSPHERE_AS
        elif ora_mbs.isJBoss():
                asPlatform = MetadataTransferManager.ASPlatform.JBOSS
        return MetadataTransferManager(ora_mbs.getMbsInstance(), asPlatform)

def createTransferParameters(params, paramNames):
	transParams = TransferParameters()
        i = 0;
        while i < len(paramNames):
                if paramNames[i] == 'docs':
                        transParams.setDocs(params[i])
                elif paramNames[i] == 'restrictCustTo':
                        transParams.setRestrictCustTo(params[i])
                elif paramNames[i] == 'excludeCustFor':
                        transParams.setExcludeCustFor(params[i])
                elif paramNames[i] == 'excludAllCust':
                        transParams.setExcludeAllCust(params[i])
                elif paramNames[i] == 'excludeBaseDocs':
                        transParams.setExcludeBaseDocs(params[i])
                elif paramNames[i] == 'excludeExtendedMetadata':
                        transParams.setExcludeExtendedMetadata(params[i])
                elif paramNames[i] == 'excludeUnmodifiedDocs':
                        transParams.setExcludeUnmodifiedDocs(params[i])
                elif paramNames[i] == 'excludeSeededDocs':
                        transParams.setExcludeSeededDocs(params[i])
                elif paramNames[i] == 'cancelOnException':
                        transParams.setCancelOnException(params[i])
                elif paramNames[i] == 'fromLabel':
                        transParams.setFromLabel(params[i])
                elif paramNames[i] == 'toLabel':
                        transParams.setToLabel(params[i])
                elif paramNames[i] == 'sandboxName':
                        transParams.setSandboxName(params[i])
                elif paramNames[i] == 'forceSBCreation':
                        transParams.setForceSBCreation(params[i])
                elif paramNames[i] == 'tenantName':
                        transParams.setTenantName(params[i])
                i = i + 1
        return transParams
                
def getParamValue(params, paramNames, paramName):
        value = None
        i = 0;
        while i < len(paramNames):
                if paramNames[i] == paramName:
                        value = params[i]
                        break
                i = i + 1
        return value

def convertStringToArray(str, paramName, operation):
	validateString(str, paramName, operation)
	if str is None:
		return None
	else:
                sb = StringBuffer(str)
                i = 0
                insideCustValue = 0
                while i < sb.length():
                        if sb.charAt(i) == '[':
                                insideCustValue = 1
                        elif sb.charAt(i) == ']':
                                insideCustValue = 0
                        elif insideCustValue == 0 and sb.charAt(i) == ',':
                                sb.setCharAt(i, ';')
                        i = i + 1
                newStr = String(sb)
                return jarray.array(newStr.split(';'), String)

def convertStringToList(str, paramName, operation):
	arr=convertStringToArray(str, paramName, operation)
	list = ArrayList()
	for ent in arr:
		list.add(ent)
	return list

def prettyPrintValue(val):
	if ora_mbs.isScriptMode() == 0:
		if val is None:
			return
		if isinstance(val, Map):
			entSt = val.entrySet()
			for ent in entSt:
				print ent.getValue().get('value')

def printArray(val):
	if ora_mbs.isScriptMode() == 0:
		if val is None:
			return
		for i in range(len(val)):
			print val[i]

def printTenants(tenants):
        if ora_mbs.isScriptMode() == 0:
                if tenants is None or len(tenants) == 0:
                        printMessage("NO_TENANTS")
                print "TenantId                      TenantName"
                print "--------------------------------------------------"
                for i in range(len(tenants)):
                        tenantName = tenants[i].get("tenantName")
                        tenantID = String.valueOf(tenants[i].get("tenantId"))
                        numSpaces = 1
                        idLen = len(tenantID)
                        if idLen < 30:
                                numSpaces = 30 - idLen
                        spaces = ""
                        for j in range(numSpaces):
                                spaces = spaces + " "
                        if tenantName is None:
                                print tenantID + spaces + "<null>"
                        else:
                                print tenantID + spaces + tenantName

def printMessage(key, values=None, message=None):
	if ora_mbs.isScriptMode() == 0:
		params=convertStringToArray(values, 'values','printMessage')
		msg=ScriptMessageHelper.getMessage(key,params)
		if (message is not None):
			msg = msg + message
		print msg

def checkForEmptyString(var, paramName, operation):
        if String(var).equals(""):
                msg = ScriptMessageHelper.getMessage("PARAM_IS_EMPTY", jarray.array([paramName, operation], Object))
                raise ora_util.OracleScriptingException, msg

def validateDataTypes(params, sig, paramNames, operation):
	for i in range(len(sig)):
		if ( sig[i] == '[Ljava.lang.String;' ):
			validateArray(params[i], paramNames[i], operation)
		elif (sig[i] == 'java.lang.String'):
			validateString(params[i], paramNames[i], operation)
		elif (sig[i] == 'boolean'):
			validateBoolean(params[i], paramNames[i], operation)
		elif (sig[i] == 'int'):
			validateInteger(params[i], paramNames[i], operation)
		elif (sig[i] == 'java.util.List'):
			validateList(params[i], paramNames[i], operation)

def validateString(var, paramName, operation):
	if var is None:
		return
	elif isinstance(var, PyString):
		return
	else:
		tp = type(var)
		msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["String", paramName, str(tp), operation],Object))
		raise ora_util.OracleScriptingException, msg

def validateArray(var, paramName, operation):
	if var is None:
		return
	elif isinstance(var, PyArray):
		for i in range(len(var)):
			trimStr = String(var[i]).trim()
			if String(trimStr).equals(""):
				msg = ScriptMessageHelper.getMessage("PARAM_CONTAINS_EMPTY_ELEMENT", jarray.array([paramName, operation], Object))
				raise ora_util.OracleScriptingException, msg
		return
	else:
		tp=type(var)
		msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["array of strings", paramName, str(tp), operation],Object))
		raise ora_util.OracleScriptingException, msg
	
def validateInteger(var, paramName, operation):
	if var is None:
		return
	elif isinstance(var, PyInteger):
		return
	else:
		tp=type(var)
		msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["int", paramName, str(tp), operation],Object))
		raise ora_util.OracleScriptingException, msg

def validateBoolean(var, paramName, operation):
	validateInteger(var, paramName, operation)

def validateList(var, paramName, operation):
	if var is None:
		return
	elif isinstance(var, List):
		return
	else:
		tp = type(var)
		msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["java.util.List", paramName, str(tp), operation],Object))
		raise ora_util.OracleScriptingException, msg

def saveStackAndRaiseException(ex, message):
	# No dumpstack command is available in WSADMIN for now. Print the messages alone for now.
	errmsg = ex.getMessage() + message
	raise ora_util.OracleScriptingException, errmsg
