"""
 Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the WSADMIN implementation. Do not edit or move
this file because this may cause WSADMIN commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WSADMIN scripts to fail when you upgrade to a different version
of WSADMIN. 
-------------------------------------------------------------------------------
MODIFIED (MM/DD/YY)
   rmasli 10/21/10 - XbranchMerge rmaslins_bug-10194875 from main
rmaslins  10/12/10 - #(10194875) Add support for rowLimit property.
rmaslins  03/24/10 - creation
-------------------------------------------------------------------------------
"""
import jarray

from jarray import array

from java.io import File

from java.lang import Boolean
from java.lang import Class
from java.lang import Object
from java.lang import RuntimeException
from java.lang import String
from java.lang import System
from java.lang import Void

from java.math import BigInteger

from java.util import ArrayList
from java.util import List
from java.util import Map
from java.util import Set

import ora_mbs
import ora_util
import OracleHelp

from oracle.adf.share.deploy.config import AdfConfigChildType
from oracle.adf.share.deploy.config import AdfConfigType

from oracle.deployment.configuration import OracleArchiveConfiguration
from oracle.deployment.configuration import OracleConfigBean

from oracle.adfm.lcm.deploy.spi.xml import ADFMDConfigType

from oracle.adfm.common.util import ScriptMessageHelper

from org.python.core import PyArray
from org.python.core import PyInteger
from org.python.core import PyLong
from org.python.core import PyString

from pprint import pformat

"""
-------------------------------------------------------------------------------
ADFMAdmin help support
-------------------------------------------------------------------------------
"""
def help(topic = None):
    m_name = 'ADFMAdmin'
    if topic == None:
        topic = m_name
    else:
        topic = m_name + '.' + topic
    return OracleHelp.help(topic)

"""
-------------------------------------------------------------------------------
ADFMDConfig operations
-------------------------------------------------------------------------------
"""
# This method returns a ADFMArchiveConfig object for the given source archive file.
# @sourceLocation - Location of the archive file.
def getADFMArchiveConfig(fromLocation):
    util = ADFMArchiveConfigUtility()
    util.required(fromLocation, 'fromLocation')
    params = jarray.array([fromLocation], Object)
    signature = jarray.array(['java.lang.String'], String)
    paramNames = jarray.array(['fromLocation'], String)
    util.validateDataTypes(params, signature, paramNames, 'getADFMArchiveConfig')
    return ADFMArchiveConfig(fromLocation)
    
class ADFMArchiveConfig:
    # Constructor.
    # @fromLocation - Complete path of the source archive file.
    def __init__ (self, fromLocation):
        try:
            self.__util = ADFMArchiveConfigUtility()
            self.__fromLocation = fromLocation
            fileInput = File(fromLocation)
            self.__archiveConfig = OracleArchiveConfiguration(fileInput)
            self.__adfmConfig = self.__getADFMConfig()
        except RuntimeException, e:
            self.__util.saveStackAndRaiseException(e, ScriptMessageHelper.getMessage("OPERATION_FAILED", "Archive Config"))

    # Set the jbo.SQLBuilder attribute.
    # @value - New value.
    def setDatabaseJboSQLBuilder(self, value=None):
        operation = "setDatabaseJboSQLBuilder"
        params = jarray.array([value], Object)
        signature = jarray.array(['java.lang.String'], String)
        paramNames = jarray.array(['value'], String)
        self.__util.validateDataTypes(params, signature, paramNames, operation)
        self.__adfmConfig.setDatabaseJboSQLBuilder(value)
        self.__util.printMessage("OPERATION_SUCCESSFUL", operation)

    # Get the jbo.SQLBuilder attribute.
    def getDatabaseJboSQLBuilder(self):
        return self.__adfmConfig.getDatabaseJboSQLBuilder()

    # Set the jbo.SQLBuilderClass attribute.
    # @value - New value.
    def setDatabaseJboSQLBuilderClass(self, value=None):
        operation = "setDatabaseJboSQLBuilderClass"
        params = jarray.array([value], Object)
        signature = jarray.array(['java.lang.String'], String)
        paramNames = jarray.array(['value'], String)
        self.__util.validateDataTypes(params, signature, paramNames, operation)
        self.__adfmConfig.setDatabaseJboSQLBuilderClass(value)
        self.__util.printMessage("OPERATION_SUCCESSFUL", operation)

    # Get the jbo.SQLBuilderClass attribute.
    def getDatabaseJboSQLBuilderClass(self):
        return self.__adfmConfig.getDatabaseJboSQLBuilderClass()

    # Set the rowLimit attribute.
    # @value - New value.
    def setDefaultRowLimit(self, value=None):
        operation = "setDefaultRowLimit"
        params = jarray.array([value], Object)
        signature = jarray.array(['long'], String)
        paramNames = jarray.array(['value'], String)
        self.__util.validateDataTypes(params, signature, paramNames, operation)
        self.__adfmConfig.setDefaultRowLimit(value)
        self.__util.printMessage("OPERATION_SUCCESSFUL", operation)

    # Get the rowLimit attribute.
    def getDefaultRowLimit(self):
        return self.__adfmConfig.getDefaultRowLimit()
        
    # If the target location is not mentioned here then the changes will be saved
    # in the same archive file. If the target location is mentioned here the changes
    # will be saved in the new archive. The original archive will not be changed.
    # @toLocation - Location of the target archive.
    def save(self, toLocation=None):
        params = jarray.array([toLocation], Object)
        signature = jarray.array(['java.lang.String'], String)
        paramNames = jarray.array(['toLocation'], String)
        self.__util.validateDataTypes(params, signature, paramNames, 'save')
        if toLocation == None or toLocation == self.__fromLocation:
            self.__archiveConfig.save()
            self.__util.printMessage("DCONFIG_SAVED", self.__fromLocation)
        else:
            targetInput = File(toLocation)
            self.__archiveConfig.save(targetInput)
            self.__util.printMessage("DCONFIG_SAVED", toLocation)

    # Private method to get the adfm config bean from the oracleconfig bean class.
    def __getADFMConfig(self):
        operation = "Archive config"
        adf_config_xml = 'adf/META-INF/adf-config.xml'
        configBean = self.__archiveConfig.getConfigBean(adf_config_xml)
        if configBean == None:
            raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("ADF_CONFIG_NOT_FOUND", operation)
        configBean.__class__ = AdfConfigType
        children = configBean.getAdfConfigChildBeans()
        for child in children:
            if isinstance(child, ADFMDConfigType):
                child.__class__ = ADFMDConfigType
                return child
        raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("ADFM_CONFIG_NOT_FOUND", operation)

class ADFMArchiveConfigUtility:
    """
    -------------------------------------------------------------------------------
    Private Utility methods
    IMPORTANT: These methods are not exposed for external users. They are for internal
    ADFM use and can change for internal reasons. 
    TODO: Move these util methods to an internal module and import that module.
    This file will be exposed to consumers and they should not use these util methods.
    These should probably be just module private, but some environments don't appear
    to respect the naming convention to enforce the privacy, nor static methods (wlst).
    -------------------------------------------------------------------------------
    """

    def getBooleanFromArg(self, arg):
        if arg is None:
            return Boolean('false')
        else:
            return Boolean(arg)

    def convertStringToArray(self, str, paramName, operation):
        self.validateString(str, paramName, operation)
        if str is None:
            return None
        else:
            return jarray.array(str.split(','), String)

    def convertStringToList(self, str, paramName, operation):
        arr = self.convertStringToArray(str, paramName, operation)
        list = ArrayList()
        for ent in arr:
            list.add(ent)
        return list

    def prettyPrintValue(self, val):
        if ora_mbs.isScriptMode() == 0:
            if val is None:
                return
            if isinstance(val, Map):
                entSt = val.entrySet()
                for ent in entSt:
                    print ent.getValue().get('value')

    def printArray(self, val):
        if ora_mbs.isScriptMode() == 0:
            if val is None:
                return
            for i in range(len(val)):
                print val[i]

    def printMessage(self, key, values=None, message=None):
        if ora_mbs.isScriptMode() == 0:
            params = self.convertStringToArray(values, 'values', 'printMessage')
            msg = ScriptMessageHelper.getMessage(key,params)
            if (message is not None):
                msg = msg + message
            print msg

    def validateDataTypes(self, params, sig, paramNames, operation):
        for i in range(len(sig)):
            if (sig[i] == '[Ljava.lang.String;'):
                self.validateArray(params[i], paramNames[i], operation)
            elif (sig[i] == 'java.lang.String'):
                self.validateString(params[i], paramNames[i], operation)
            elif (sig[i] == 'boolean'):
                self.validateBoolean(params[i], paramNames[i], operation)
            elif (sig[i] == 'int'):
                self.validateInteger(params[i], paramNames[i], operation)
            elif (sig[i] == 'long'):
                self.validateLong(params[i], paramNames[i], operation)
            elif (sig[i] == 'java.util.List'):
                self.validateList(params[i], paramNames[i], operation)

    def validateString(self, var, paramName, operation):
        if var is None:
            return
        elif isinstance(var, PyString):
            return
        else:
            tp = type(var)
            msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["String", paramName, str(tp), operation], Object))
            raise ora_util.OracleScriptingException, msg

    def validateArray(self, var, paramName, operation):
        if var is None:
            return
        elif isinstance(var, PyArray):
            return
        else:
            tp = type(var)
            msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["array of strings", paramName, str(tp), operation], Object))
            raise ora_util.OracleScriptingException, msg
    
    def validateInteger(self, var, paramName, operation):
        if var is None:
            return
        elif isinstance(var, PyInteger):
            return
        else:
            tp = type(var)
            msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["int", paramName, str(tp), operation], Object))
            raise ora_util.OracleScriptingException, msg

    def validateLong(self, var, paramName, operation):
        if var is None:
            return
        elif isinstance(var, PyInteger):
            return
        elif isinstance(var, PyLong):
            return
        elif isinstance(var, BigInteger):
            return
        else:
            tp = type(var)
            msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["long", paramName, str(tp), operation], Object))
            raise ora_util.OracleScriptingException, msg
            
    def validateBoolean(self, var, paramName, operation):
        self.validateInteger(var, paramName, operation)

    def validateList(self, var, paramName, operation):
        if var is None:
            return
        elif isinstance(var, List):
            return
        else:
            tp = type(var)
            msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["java.util.List", paramName, str(tp), operation], Object))
            raise ora_util.OracleScriptingException, msg

    def required(self, var, name):
        if (var == None):
            raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("REQUIRED_PARAM_NOT_FOUND", name)

    def saveStackAndRaiseException(self, ex, message):
        # No dumpstack command is available in WSADMIN for now. Print the messages alone for now.
        errmsg = ex.getMessage() + message
        raise ora_util.OracleScriptingException, errmsg
