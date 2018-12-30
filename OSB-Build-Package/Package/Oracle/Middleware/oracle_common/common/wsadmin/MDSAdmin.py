"""
 Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the WSADMIN implementation. Do not edit or move
this file because this may cause WSADMIN commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WSADMIN scripts to fail when you upgrade to a different version
of WSADMIN. 
-------------------------------------------------------------------------------
llu      08/03/12 - #(14379313) Check for None exception message in
                    saveStackAndRaiseException
dibhatta 10/04/11 - #10368255 backport from #(9346064 - llu) Add empty string 
                    validation on application name, node name, and server name.
                    Also add empty array element validation
dibhatta 09/30/11 - #(10364917) Backport #(9981431) by llu to add 
                     isConnectedToServer check
                     DomainRuntimeBean to be consistent with WLST commands
llu      09/08/11 - Add multi-tenancy support
llu      12/20/10 - #(11073853) Add cust value support
llu      11/02/10 - #(9774745) Improved message for purgeMetadataLabels
llu      10/13/10 - #(10154988) Add excludeCustFor option to exportMetadata
                     Modify exportSandboxMetadata to export all cust by default
jhsi     10/12/10 - Sparse transfer support.
llu      08/10/10 - #(9346162) Trim application, node & server names before use
llu      08/03/10 - #(9801771) Show server info in the error message when
                     failing to find AppRuntimeMBean
llu      07/22/10 - #(9918833) Support optional parameters on
                     purgeMetadataLabels
llu      07/08/10 - #(9364201) hideDisplay of return values to avoid duplicate
                    display
llu      06/07/10 - Add update sandbox support.
llu      04/09/10 - Add sandbox import and export support.
veyunni  04/14/10 - purgeMetadataLabels support from the domain rt mbean
llu      04/09/10 - Add sandbox import and export support.
jhsi     04/08/10 - Add targetServers parameter
jhsi     04/01/10 - Remote import and export support.
llu      01/26/09 - Move ScriptMessageHelper from oracle.mds.script.util to
                    oracle.mds.common.util.
llu      01/19/09 - Exception & help support
llu      11/30/09 - Move ScriptMessageHelper from oracle.mds.wlst.util to
                    oracle.mds.script.util
llu      11/30/09 - #(9153615) Add isScriptMode support
llu      11/02/09 - WSADMIN support
akrajend 06/24/09 - creation
-------------------------------------------------------------------------------
"""
import MDS_handler

import jarray
import sys

from jarray import array

from java.io import File

from java.lang import Boolean
from java.lang import Class
from java.lang import Long
from java.lang import Object
from java.lang import RuntimeException
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
from javax.management.openmbean import CompositeData

import ora_mbs
import ora_util
import OracleHelp

from oracle.adf.share.deploy.config import AdfConfigChildType
from oracle.adf.share.deploy.config import AdfConfigType

from oracle.deployment.configuration import OracleArchiveConfiguration
from oracle.deployment.configuration import OracleConfigBean

from oracle.mds.config.util import MDSConnectionInfo
from oracle.mds.config.util import MDSRepositoryInfo

from oracle.mds.lcm.deploy.spi.xml import MDSDConfigType
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
MDSAdmin help support
-------------------------------------------------------------------------------
"""
def help(topic = None):
        m_name = 'MDSAdmin'
        if topic == None:
                topic = m_name
        else:
                topic = m_name + '.' + topic
        ora_util.restoreDisplay()
        return OracleHelp.help(topic)

"""
-------------------------------------------------------------------------------
MDSAppRuntimeMBean operations
-------------------------------------------------------------------------------
"""
# This command deletes the metadata for an application.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @docs Comma seperated list of documents or document name patterns that should be deleted
# @restrictCustTo Comma seperated list of customization document names or patterns 
# @excludeBaseDocs
# @excludeExtendedMetadata
# @cancelOnException
# @tenantName
def deleteMetadata(application, node, server, docs, restrictCustTo=None, excludeAllCust='false', excludeBaseDocs='false', excludeExtendedMetadata='false', cancelOnException='true', tenantName=None):
        operationName = 'deleteMetadata'
        required(application, 'application')
        required(server,'server')
        required(docs,'docs')
        params = jarray.array([convertStringToArray(docs, 'docs', operationName), convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), getBooleanFromArg(excludeAllCust), getBooleanFromArg(excludeBaseDocs), getBooleanFromArg(excludeExtendedMetadata), getBooleanFromArg(cancelOnException), tenantName], Object)
        signature = jarray.array(['[Ljava.lang.String;','[Ljava.lang.String;','boolean','boolean','boolean','boolean', 'java.lang.String'], String)
        paramNames = jarray.array(['docs', 'restrictCustTo', 'excludeAllCust', 'excludeBaseDocs', 'excludeExtendedMetadata', 'cancelOnException', 'tenantName'], String)
        retValue = executeAppRuntimeMBeanOperation(application, node, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        ora_util.hideDisplay()
        return retValue

# This command exports the sandbox metadata for an application.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @toArchive
# @sandboxName
# @restrictCustTo Comma seperated list of customization document names or patterns 
# @remote
# @tenantName
def exportSandboxMetadata(application, node, server, toArchive, sandboxName, restrictCustTo='%', remote='false', tenantName=None):
        operationName = 'exportSandboxMetadata'
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(toArchive,'toArchive')
        required(sandboxName,'sandboxName')
        params = jarray.array([toArchive, sandboxName, convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), tenantName], Object)
        signature = jarray.array(['java.lang.String','java.lang.String','[Ljava.lang.String;', 'java.lang.String'], String)
        paramNames = jarray.array(['toArchive', 'sandboxName', 'restrictCustTo', 'tenantName'], String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = MDS_handler.executeMetadataTransferManagerOperation(application, node, server, operationName, params, signature, paramNames)
        else:
                retValue = executeAppRuntimeMBeanOperation(application, node, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        ora_util.hideDisplay()
        return retValue

# This command imports the sandbox metadata to the applications db repository from a given archive.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @fromArchive
# @forceSBCreation
# @useExistingSandbox
# @sandboxName
# @remote
# @tenantName
def importSandboxMetadata(application, node, server, fromArchive, forceSBCreation='false', useExistingSandbox='false', sandboxName=None, remote='false', tenantName=None):
        operationName = 'importSandboxMetadata'
        transMgrOperationName = 'importSandboxMetadata'
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(fromArchive,'fromArchive')
        if getBooleanFromArg(useExistingSandbox) == Boolean('true') and sandboxName != None:
                params = jarray.array([fromArchive, sandboxName, tenantName], Object)
                signature = jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String'], String)
                paramNames = jarray.array(['fromArchive', 'sandboxName', 'tenantName'], String)
                transMgrOperationName = 'updateSandboxMetadata'
        else:
                params = jarray.array([fromArchive, getBooleanFromArg(forceSBCreation), tenantName], Object)
                signature = jarray.array(['java.lang.String', 'boolean', 'java.lang.String'], String)
                paramNames = jarray.array(['fromArchive', 'forceSBCreation', 'tenantName'], String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = MDS_handler.executeMetadataTransferManagerOperation(application, node, server, transMgrOperationName, params, signature, paramNames)
        else:
                retValue = executeAppRuntimeMBeanOperation(application, node, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        ora_util.hideDisplay()
        return retValue

# This command exports the metadata for an application.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @toLocation
# @docs Comma seperated list of documents or document name patterns that should be deleted
# @restrictCustTo Comma seperated list of customization document names or patterns 
# @excludeCustFor Comma seperated list of customization document names or patterns 
# @excludeAllCust
# @excludeBaseDocs
# @excludeExtendedMetadata
# @excludeSeededDocs
# @fromLabel
# @toLabel
# @remote
# @tenantName
def exportMetadata(application, node, server, toLocation, docs='/**', restrictCustTo=None, excludeCustFor=None, excludeAllCust='false', excludeBaseDocs='false', excludeExtendedMetadata='false', excludeSeededDocs='false', fromLabel=None, toLabel=None, remote='false', tenantName=None):
        operationName = 'exportMetadata'
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(toLocation,'toLocation')
        params = jarray.array([toLocation,getBooleanFromArg('false'), convertStringToArray(docs, 'docs', operationName), convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), convertStringToArray(excludeCustFor, 'excludeCustFor', operationName), getBooleanFromArg(excludeAllCust), getBooleanFromArg(excludeBaseDocs), getBooleanFromArg(excludeExtendedMetadata), getBooleanFromArg(excludeSeededDocs), fromLabel, toLabel, tenantName], Object)
        signature = jarray.array(['java.lang.String', 'boolean', '[Ljava.lang.String;', '[Ljava.lang.String;', '[Ljava.lang.String;', 'boolean', 'boolean', 'boolean', 'boolean', 'java.lang.String', 'java.lang.String', 'java.lang.String'], String)
        paramNames = jarray.array(['toLocation', 'createSubDir', 'docs', 'restrictCustTo', 'excludeCustFor', 'excludeAllCust', 'excludeBaseDocs', 'excludeExtendedMetadata', 'excludeSeededDocs', 'fromLabel', 'toLabel', 'tenantName'], String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = MDS_handler.executeMetadataTransferManagerOperation(application, node, server, operationName, params, signature, paramNames)
        else:       
                retValue = executeAppRuntimeMBeanOperation(application, node, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        ora_util.hideDisplay()
        return retValue

# This command imports the metadata to the applications repository from a given location.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @fromLocation
# @docs Comma seperated list of documents or document name patterns that should be deleted
# @restrictCustTo Comma seperated list of customization document names or patterns 
# @excludeAllCust
# @excludeBaseDocs
# @excludeExtendedMetadata
# @excludeUnmodifiedDocs
# @cancelOnException
# @remote
# @tenantName
def importMetadata(application, node, server, fromLocation, docs='/**', restrictCustTo=None, excludeAllCust='false', excludeBaseDocs='false', excludeExtendedMetadata='false', excludeUnmodifiedDocs='false', cancelOnException='true', remote='false', tenantName=None):
        operationName = 'importMetadata'
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(fromLocation,'fromLocation')
        params = jarray.array([fromLocation, convertStringToArray(docs, 'docs' ,operationName), convertStringToArray(restrictCustTo, 'restrictCustTo' ,operationName), getBooleanFromArg(excludeAllCust), getBooleanFromArg(excludeBaseDocs), getBooleanFromArg(excludeExtendedMetadata), getBooleanFromArg(excludeUnmodifiedDocs), getBooleanFromArg(cancelOnException), tenantName], Object)
        signature = jarray.array(['java.lang.String', '[Ljava.lang.String;','[Ljava.lang.String;','boolean','boolean','boolean','boolean','boolean', 'java.lang.String'], String)
        paramNames = jarray.array(['fromLocation', 'docs', 'restrictCustTo', 'excludeAllCust', 'excludeBaseDocs', 'excludeExtendedMetadata', 'excludeUnmodifiedDocs', 'cancelOnException', 'tenantName'], String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = MDS_handler.executeMetadataTransferManagerOperation(application, node, server, operationName, params, signature, paramNames)
        else:
                retValue = executeAppRuntimeMBeanOperation(application, node, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        ora_util.hideDisplay()
        return retValue

# This command imports the metadata from the MAR packaged with the application to the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed
# @force
def importMAR(application, node, server, force='true'):
        operationName = 'importMAR'
        required(application,'application')
        required(node,'node')
        required(server,'server')
        params=jarray.array([getBooleanFromArg(force)], Object)
        signature=jarray.array(['boolean'], String)
        paramNames = jarray.array(['force'],String)
        retValue = executeAppRuntimeMBeanOperation(application, node, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        ora_util.hideDisplay()
        return retValue

# This command creates a metadata label in the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @name
# @tenantName
def createMetadataLabel(application, node, server, name, tenantName=None):
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(name,'name')
        params = jarray.array([name, tenantName], Object)
        signature = jarray.array(['java.lang.String', 'java.lang.String'], String)
        paramNames = jarray.array(['name', 'tenantName'], String)
        retValue= executeAppRuntimeMBeanOperation(application, node, server, 'createMetadataLabel', params, signature, paramNames)
        printMessage("CREATED_METADATA_LABEL", retValue)
        ora_util.hideDisplay()
        return retValue

# This command deletes the metadata label in the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed 
# @name
# @tenantName
def deleteMetadataLabel(application, node, server, name, tenantName=None):
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(name,'name')
        params = jarray.array([name, tenantName], Object)
        signature = jarray.array(['java.lang.String', 'java.lang.String'], String)
        paramNames = jarray.array(['name', 'tenantName'], String)
        executeAppRuntimeMBeanOperation(application, node, server, 'deleteMetadataLabel', params, signature, paramNames)
        printMessage("DELETE_METADATA_LABEL", name)

# This command lists all the labels created in the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed
# @tenantName
def listMetadataLabels(application, node, server, tenantName=None):
        required(application,'application')
        required(node,'node')
        required(server,'server')
        params = jarray.array([tenantName], Object)
        signature = jarray.array(['java.lang.String'], String)
        paramNames = jarray.array(['tenantName'], String)
        labels=executeAppRuntimeMBeanOperation(application, node, server, 'listMetadataLabels', params, signature, paramNames)
        printMessage("LIST_METADATA_LABELS")
        if labels is None or len(labels) == 0:
                printMessage ("NO_MATCHING_METADATA_LABELS")
        else:
                printArray(labels)
        ora_util.hideDisplay()
        return labels

# This command promotes the metadata for a label to the tip.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed
# @name
# @tenantName
def promoteMetadataLabel(application, node, server, name, tenantName=None):
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(name,'name')
        params = jarray.array([name, tenantName], Object)
        signature = jarray.array(['java.lang.String', 'java.lang.String'], String)
        paramNames = jarray.array(['name', 'tenantName'], String)
        executeAppRuntimeMBeanOperation(application, node, server, 'promoteMetadataLabel', params, signature, paramNames)
        printMessage("PROMOTE_METADATA_LABEL", name)

# This command purges metadata from the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @node The node on which the target server is running 
# @server The target server on which this application is deployed
# @olderThan
def purgeMetadata(application, node, server, olderThan):
        required(application,'application')
        required(node,'node')
        required(server,'server')
        required(olderThan, 'olderThan')
        params= jarray.array([olderThan], Object)
        signature=jarray.array(['long'],String)
        paramNames = jarray.array(['olderThan'],String)
        message=executeAppRuntimeMBeanOperation(application, node, server, 'purgeMetadata', params, signature, paramNames)
        printMessage("METADATA_PURGED", None, message)
        ora_util.hideDisplay()
        return message

"""
-------------------------------------------------------------------------------
MDSDomainRuntimeMBean operations
-------------------------------------------------------------------------------
"""
# This command deregisters a DB metadata repository with the server.
# @name
def deregisterMetadataDBRepository(name):
        required(name,'name')
        params= jarray.array([name],Object)
        signature=jarray.array(['java.lang.String'],String)
        paramNames = jarray.array(['name'],String)
        executeDomainRuntimeMBeanOperation('deregisterMetadataDBRepository',params,signature, paramNames)
        printMessage("DEREGISTER_METADATA_REPOSITORY", name)

# This command registers a DB metadata repository with the server.
# @name
# @dbVendor
# @host
# @port
# @dbName
# @authAlias
# @user
# @password
# @targetServers
def registerMetadataDBRepository(name, dbVendor, host, port, dbName, authAlias=None, user=None, password=None, targetServers=None):
        operationName = 'registerMetadataDBRepository'
        mbeanMethodName = 'registerMetadataDBRepositoryWAS'
        required(name,'name')
        required(dbVendor,'dbVendor')
        required(host,'host')
        required(port,'port')
        required(dbName,'dbName')
        params= jarray.array([name, getDBVendorCode(dbVendor, operationName), host, port, dbName, authAlias, user, password, convertStringToArray(targetServers, 'targetServers', operationName)],Object)
        signature=jarray.array(['java.lang.String','int','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String','[Ljava.lang.String;'],String)
        paramNames = jarray.array(['name', 'dbVendor', 'host', 'port', 'dbName', 'authAlias', 'user', 'password', 'targets'],String)
        name=executeDomainRuntimeMBeanOperation(operationName, params, signature, paramNames, mbeanMethodName)
        printMessage("REGISTER_METADATA_REPOSITORY", name)
        ora_util.hideDisplay()
        return name

# This command creates a metadata partition in the repository specified by repository parameter.
# @repository
# @partition
def createMetadataPartition(repository, partition):
        required(repository,'repository')
        required(partition,'partition')
        params= jarray.array([repository, partition], Object)
        signature=jarray.array(['java.lang.String','java.lang.String'],String)
        paramNames = jarray.array(['repository', 'partition'],String)
        name=executeDomainRuntimeMBeanOperation('createMetadataPartition',params, signature, paramNames)
        msgparams=name + ',' + repository
        printMessage("CREATE_METADATA_PARTITION", msgparams)
        ora_util.hideDisplay()
        return name

# This command deletes a metadata partition in the repository specified by repository parameter.
# @repository
# @partition
def deleteMetadataPartition(repository, partition):
        required(repository,'repository')
        required(partition,'partition')
        params= jarray.array([repository, partition], Object)
        signature=jarray.array(['java.lang.String','java.lang.String'],String)
        paramNames = jarray.array(['repository', 'partition'],String)
        name=executeDomainRuntimeMBeanOperation('deleteMetadataPartition',params,signature, paramNames)
        msgparams=partition + ',' + repository
        printMessage("DELETE_METADATA_PARTITION", msgparams)
        ora_util.hideDisplay()
        return name

# This command purges the metadata labels matching the specified pattern and/or older than the specified time
# TODO: change olderThanMin from String to Integer once compatabilty is not an issue
# @repository
# @partition
# @namePattern
# @olderThanInMin
# @infoOnly
# @tenantName
def purgeMetadataLabels(repository, partition, namePattern=None, olderThanInMin='525600', infoOnly='false', tenantName=None):
        required(repository,'repository')
        required(partition,'partition')
        params = jarray.array([repository, partition, namePattern, Long(olderThanInMin), tenantName], Object)
        signature = jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String', 'long', 'java.lang.String'], String)
        paramNames = jarray.array(['repository', 'partition', 'namePattern', 'olderThanInMin', 'tenantName'], String)

        if namePattern == None:
                namePatternStr = '<Null>'
        else:
                namePatternStr = namePattern
        if tenantName == None:
                tenantNameStr = '<Null>'
        else:
                tenantNameStr = tenantName
        msgparams = " repository=" + repository + ',parititon=' + partition + ',namePattern=' + namePatternStr + ',olderThanInMin=' + olderThanInMin + ',tenantName=' + tenantNameStr + ': '

        if Boolean(infoOnly).booleanValue():
                cd=executeDomainRuntimeMBeanOperation('listMetadataLabels', params, signature, paramNames)
                printMessage("LIST_METADATA_LABELS_PATTERN", None, msgparams)
                if isinstance(cd, CompositeData):
                        labels = cd.get('labels')
                        if labels is None or len(labels) == 0:
                                printMessage ("NO_MATCHING_METADATA_LABELS")
                        else:
                                printValueFromCompositeData(labels, 'name')
                        ora_util.hideDisplay()
                        return labels
                ora_util.hideDisplay()
                return cd
        else:
                labels=executeDomainRuntimeMBeanOperation('purgeMetadataLabels', params, signature, paramNames)
                printMessage("PURGE_METADATA_LABELS", None, msgparams)
                if labels is None or len(labels) == 0:
                        printMessage ("NO_MATCHING_METADATA_LABELS")
                else:
                        printArray(labels)
                ora_util.hideDisplay()
                return labels


# This command deprovisions a tenant along with all of the content.
# @repository
# @partition
# @tenantName
def deprovisionTenant(repository, partition, tenantName):
        required(repository, 'repository')
        required(partition, 'partition')
        required(tenantName, 'tenantName')
        params = jarray.array([repository, partition, tenantName], Object)
        signature = jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String'], String)
        paramNames = jarray.array(['repository', 'partition', 'tenantName'], String)
        executeDomainRuntimeMBeanOperation('deprovisionTenant', params, signature, paramNames)
        MDS_handler.printMessage("DEPROVISION_TENANT", tenantName)

# This command lists all tenants
# @repository
# @partition
def listTenants(repository, partition):
        required(repository, 'repository')
        required(partition, 'partition')
        params = jarray.array([repository, partition], Object)
        signature = jarray.array(['java.lang.String', 'java.lang.String'], String)
        paramNames = jarray.array(['repository', 'partition'], String)
        tenants = executeDomainRuntimeMBeanOperation('listTenants', params, signature, paramNames)
        MDS_handler.printTenants(tenants)
        ora_util.hideDisplay()
        return tenants


"""
-------------------------------------------------------------------------------
MDSDConfig operations
-------------------------------------------------------------------------------
"""
class MDSArchiveConfig:
    # Constructor.
    # @fromLocation - Complete path of the source archive file.
    def __init__ (self, fromLocation):
        try:
          self.__fromLocation = fromLocation
          fileInput = File(fromLocation)
          self.__archiveConfig = OracleArchiveConfiguration(fileInput)
          self.__mdsConfig = self.__getMDSConfig()
        except RuntimeException, e:
             saveStackAndRaiseException(e, ScriptMessageHelper.getMessage("OPERATION_FAILED", "Archive Config"))

    # The application deployment target repository is set to use the given connection information.
    # If the adf-config already contains connection details for application metadata repository,
    # only the properties having non null values in the arguments will be updated in the configuration.
    # Otherwise, the user should provide the complete details for the application repository connection.
    # @repository - Name of the repository.
    # @partition - Name of the partition.
    # @type - Type of the connection. The value can be 'File' or 'DB'.
    # @jndi - Jndi path value if the connection type is 'DB'.
    # @path - Path string if the connectino type is 'File'.
    def setAppMetadataRepository(self, repository=None, partition=None, type=None, jndi=None, path=None):
        operation = "setAppMetadataRepository"
        params = jarray.array([repository, partition, type, jndi, path], Object)
        signature =jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String'],String)
        paramNames = jarray.array(['repository', 'partition', 'type', 'jndi', 'path'],String)
        validateDataTypes(params, signature, paramNames, operation)
        appRepos = self.__mdsConfig.getAppMetadataRepositoryInfo()
        if appRepos.getConnection() == None:
          if repository == None or partition == None or type == None:
            raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("PARMAS_FOR_NEW_APP_REPOS", operation)
        if type != None:
          type = String(type)
          if type.equalsIgnoreCase('DB') == 0 and type.equalsIgnoreCase('File') == 0:
            raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("CONNECTION_TYPE_NOT_CORRECT", operation)
          if appRepos.getConnection() == None or type.equalsIgnoreCase(appRepos.getConnection().getType()) == 0:
            if type.equalsIgnoreCase('DB') and jndi == None:
              raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("JNDI_PARAM_NOT_PROVIDED", operation)
            if type.equalsIgnoreCase('File') and path == None:
              raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("PATH_PARAM_NOT_PROVIDED", operation)
        nValues = MDSConnectionInfo(repository, type, partition, jndi, path)
        self.__mdsConfig.setAppMetadataRepository(nValues, 0)
        printMessage("OPERATION_SUCCESSFUL", operation)

    # Shared repository configuration mapped to the given namespace is changed to use the
    # connection information mentioned here. If the adf-config already contains connection
    # details for the mentioned namespace, only the properties having non null values in
    # the arguments will be updated in the configuration. Otherwise, the user should
    # provide the complete details for the repository connection. The namespaces mentioned
    # should not overlap. If the namespace is a new one or a overlaping namespace then the
    # namespace will not be updated.
    # For example, if there are two namespaces like /a and /a/b, the
    # namespace /a only should be mentioned here.
    # @namespace - Namespace for which the connection details should be set.
    # @repository - Name of the repository.
    # @partition - Name of the partition.
    # @type - Type of the connection. The value can be 'File' or 'DB'.
    # @jndi - Jndi path value if the connection type is 'DB'.
    # @path - Path string if the connectino type is 'File'.
    def setAppSharedMetadataRepository(self, namespace, repository=None, partition=None, type=None, jndi=None, path=None):
        operation = 'setAppSharedMetadataRepository'
        params= jarray.array([namespace, repository, partition, type, jndi, path], Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String'],String)
        paramNames = jarray.array(['namespace', 'repository', 'partition', 'type', 'jndi', 'path'],String)
        validateDataTypes(params, signature, paramNames, operation)
        required(namespace, 'namespace')
        sharedRepositories = self.__mdsConfig.getSharedMetadataRepositoryInfo()
        if len(sharedRepositories) == 0:
          raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("NO_SHARED_REPOS_MAPPING", operation)
        sharedRepos = None
        for repos in sharedRepositories:
           if repos.getNamespaces()[0] == namespace:
              sharedRepos = repos
              break
        if sharedRepos == None:
          raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("NAMESPACE_NOT_VALID", namespace, operation)
        if repos.getConnection() == None:
          if repository == None or partition == None or type == None:
            raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("PARMAS_FOR_NEW_SHARED_REPOS", namespace, operation)
        if type != None:
          type = String(type)
          if type.equalsIgnoreCase('DB') == 0 and type.equalsIgnoreCase('File') == 0:
            raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("CONNECTION_TYPE_NOT_CORRECT", operation)
          if repos.getConnection() == None or type.equalsIgnoreCase(repos.getConnection().getType()) == 0:
            if type.equalsIgnoreCase('DB') and jndi == None:
              raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("JNDI_PARAM_NOT_PROVIDED", operation)
            if type.equalsIgnoreCase('File') and path == None:
              raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("PATH_PARAM_NOT_PROVIDED", operation)
        newConnectionValue = MDSConnectionInfo(repository, type, partition, jndi, path)
        namespaces = jarray.array([namespace],Class.forName('java.lang.String'))
        newRepositoryValue = MDSRepositoryInfo(namespaces, newConnectionValue)
        newRepositoryValues = jarray.array([newRepositoryValue], Class.forName('oracle.mds.config.util.MDSRepositoryInfo'))
        self.__mdsConfig.setSharedMetadataRepositoryInfo(newRepositoryValues, 0)
        printMessage("OPERATION_SUCCESSFUL", operation)
    
    """
    #This getters methods can be used in development environment to test the implementation.
    def getAppMetadataRepository(self):
        appRepos = self.__mdsConfig.getAppMetadataRepositoryInfo()
        return self.__getReposInfo(appRepos)
        
    def getAppSharedMetadataRepository(self):
        sharedRepositories = self.__mdsConfig.getSharedMetadataRepositoryInfo()
        reposList = []
        for repos in sharedRepositories:
            reposList.append(self.__getReposInfo(repos))
        return reposList
    """

    # If the target location is not mentioned here then the changes will be saved
    # in the same archive file. If the target location is mentioned here the changes
    # will be saved in the new archive. The original archive will not be changed.
        # @targetLocation - Location of the target archive.
    def save(self, toLocation=None):
        params= jarray.array([toLocation], Object)
        signature=jarray.array(['java.lang.String'],String)
        paramNames = jarray.array(['toLocation'],String)
        validateDataTypes(params, signature, paramNames, 'save')
        if toLocation == None or toLocation == self.__fromLocation:
           self.__archiveConfig.save()
           printMessage("DCONFIG_SAVED", self.__fromLocation)
        else:
           targetInput = File(toLocation)
           self.__archiveConfig.save(targetInput)
           printMessage("DCONFIG_SAVED", toLocation)

    # Private method to get the mds config bean from the oracleconfig bean class.
    def __getMDSConfig(self):
        operation = "Archive config"
        adf_config_xml = 'adf/META-INF/adf-config.xml'
        configBean = self.__archiveConfig.getConfigBean(adf_config_xml)
        if configBean == None:
           raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("ADF_CONFIG_NOT_FOUND", operation)
        configBean.__class__ = AdfConfigType
        children = configBean.getAdfConfigChildBeans()
        for child in children:
             if isinstance(child, MDSDConfigType):
                    child.__class__ = MDSDConfigType
                    return child
        raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("MDS_CONFIG_NOT_FOUND", operation)
    
    """
    #Private method used to print the values of the repositories in the weblogic console.
    def __getReposInfo(self, repositoryInfo):
        namespaces = repositoryInfo.getNamespaces()
        conn = repositoryInfo.getConnection()
        info = None
        if conn == None:
           info = {"repository":None, "type":None, "partition":None, "jndi":None, "path":None, "namespaces":namespaces}
        else:
           type = conn.getType()
           repository = conn.getRepository()
           partition = conn.getPartition()
           jndi = conn.getJndi()
           path = conn.getPath()
           info = {"repository":repository, "type":type, "partition":partition, "jndi":jndi, "path":path, "namespaces":namespaces}
        #print info
        return info
    """

# This method returns a MDSArchiveConfig object for the given source archive file.
# @sourceLocation - Location of the archive file.
def getMDSArchiveConfig(fromLocation):
    required(fromLocation, 'fromLocation')
    params= jarray.array([fromLocation], Object)
    signature=jarray.array(['java.lang.String'],String)
    paramNames = jarray.array(['fromLocation'],String)
    validateDataTypes(params, signature, paramNames, 'getMDSArchiveConfig')
    ora_util.hideDisplay()
    return MDSArchiveConfig(fromLocation)

"""
-------------------------------------------------------------------------------
Private Utility methods
IMPORTANT: These methods are not exposed for external users. They are for internal
MDS use and can change for internal reasons. 
TODO: Move these util methods to an internal module and importe that module.
This file will be exposed to consumers and they should not use these util methods.
-------------------------------------------------------------------------------
"""
def isConnectedToServer(operation):
    if ( ora_mbs.isConnected() == 'false'):
                raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("NOT_CONNECTED_TO_SERVER", 'WebSphere', operation)

def getMDSMBean(name, mbeanOperation):
        isConnectedToServer(mbeanOperation)
        mdsName = ora_mbs.makeObjectName(name)
        beans = ora_mbs.queryNames(mdsName, None)
        if ( beans.size() > 0):
                return beans
        else:
                return None

def getMDSAppRuntimeMBean(application, node, server, mbeanOperation):
        application = String(application).trim()
        MDS_handler.checkForEmptyString(application, 'application', mbeanOperation)
        node = String(node).trim()
        MDS_handler.checkForEmptyString(node, 'node', mbeanOperation)
        server = String(server).trim()
        MDS_handler.checkForEmptyString(server, 'server', mbeanOperation)

        beanName = 'oracle.mds.lcm:name=MDSAppRuntime,type=MDSAppRuntime,Application=' + application + ',node='+ node +',process=' + server + ',*'
        bean = getMDSMBean(beanName, mbeanOperation)
        if bean is None:
                raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("MDS_APP_MBEAN_NOT_FOUND_IN_SERVER", jarray.array([application, mbeanOperation, server], String))
        elif bean.size() > 1:
                raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("WAS_MULTIPLE_APP_MBEAN_FOUND_IN_SERVER", jarray.array([application, mbeanOperation, server], String))
        else:
                return bean.iterator().next()

def getMDSDomainRuntimeMBean(mbeanOperation):
        bean = getMDSMBean('oracle.mds.lcm:name=MDSDomainRuntime,type=MDSDomainRuntime,*', mbeanOperation)
        if bean is None:
                raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("MDS_DOMAIN_MBEAN_NOT_FOUND", mbeanOperation)
        else:
                return bean.iterator().next()

def getBooleanFromArg(arg):
        if arg is None:
                return Boolean('false')
        else:
                return Boolean(arg)

def executeAppRuntimeMBeanOperation(application, node, server, mbeanOperation, params, signature, paramNames):
        isConnectedToServer(mbeanOperation)
        validateDataTypes(params, signature, paramNames, mbeanOperation)

        printMessage("START_OPERATION", mbeanOperation)
        beanName = getMDSAppRuntimeMBean(application, node, server, mbeanOperation)
        try:
                retValue = ora_mbs.invoke(beanName, mbeanOperation, params, signature)
                return retValue
        except:
                tp,val,tb = sys.exc_info()
                saveStackAndRaiseException(val, ScriptMessageHelper.getMessage("OPERATION_FAILED", mbeanOperation))

def executeDomainRuntimeMBeanOperation(mbeanOperation, params, signature, paramNames, mbeanMethodName=None):
        isConnectedToServer(mbeanOperation)
        validateDataTypes(params, signature, paramNames, mbeanOperation)
        printMessage("START_OPERATION", mbeanOperation)
        beanName = getMDSDomainRuntimeMBean(mbeanOperation)
        try:
                # If the mbeanMethodName is None, consider the mbeanOperation parameter string as mbean method name.
                if mbeanMethodName is None:
                        mbeanMethodName = mbeanOperation
                retValue = ora_mbs.invoke(beanName, mbeanMethodName, params, signature)
                return retValue
        except:
                tp,val,tb=sys.exc_info()
                saveStackAndRaiseException(val, ScriptMessageHelper.getMessage("OPERATION_FAILED", mbeanOperation))

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

def printValueFromCompositeData(val, key):
        if ora_mbs.isScriptMode() == 0:
                if val is None:
                        return
                if key is None:
                        return
                for i in range(len(val)):
                        if isinstance(val[i], CompositeData):
                                if val[i].containsKey(key):
                                        print val[i].get(key)

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

def getDBVendorCode(var, operation):
        required(var, 'dbVendor')
        if ( var.upper() == 'ORACLE'):
                return 0
        elif ( var.upper() == 'MSSQL'):
                return 1
        elif ( var.upper() == 'IBMDB2'):
                return 2
        else:
                raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("DB_VENDOR_NOT_CORRECT", operation)

def required(var, name):
        if (var == None):
                raise ora_util.OracleScriptingException, ScriptMessageHelper.getMessage("REQUIRED_PARAM_NOT_FOUND", name)

def saveStackAndRaiseException(ex, message):
        # No dumpstack command is available in WSADMIN for now. Print the messages alone for now.
        errmsg = ex.getMessage()
        if errmsg is None:
                errmsg = ex.toString()
        errmsg = errmsg + " " + message
        raise ora_util.OracleScriptingException, errmsg
