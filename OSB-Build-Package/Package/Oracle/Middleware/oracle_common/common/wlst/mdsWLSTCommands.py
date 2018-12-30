"""
 Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the WLST implementation. Do not edit or move
this file because this may cause WLST commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WLST scripts to fail when you upgrade to a different version
of WLST. 
-------------------------------------------------------------------------------
llu      08/03/12 - #(14379313) Check for None exception message in
                    saveStackAndRaiseException
llu      10/12/11 - Modify listTenants
dibhatta 10/04/11 - #10368255 backport from #(9346064 - llu) Add empty array 
                    element validation
                    Also add empty string validation on application name, 
                    server name, and application version
llu      07/10/11 - Add multi-tenancy support
erwang   07/05/11 - #(12712221) Add MySQL support
llu      08/10/10 - #(9346162) Trim application & server names before use
llu      08/09/10 - #(9981431) check connection in DomainRuntimeMBean commands
llu      12/20/10 - #(11073853) Add cust value support
llu      11/02/10 - #(9774745) Improved message for purgeMetadataLabels
llu      10/13/10 - #(10154988) Add excludeCustFor option to exportMetadata
                     Modify exportSandboxMetadata to export all cust by default
llu      08/03/10 - #(9801771) Show server info in the error message when
                     failing to find AppRuntimeMBean
llu      07/22/10 - #(9918833) Support optional parameters on
                     purgeMetadataLabels
llu      07/08/10 - #(9364201) hideDisplay of return values to avoid duplicate
                    display
jhsi     06/18/10 - #(9814140) Use java.util.Iterator.hasNext workaround.
llu      06/03/10 - #(9779822) Fix remote parameter check
llu      05/25/10 - Add updateSandbox support
llu      04/14/10 - Add remote sandbox transfer support.
llu      04/09/10 - Add sandbox import and export support.
veyunni  04/07/10 - purge labels support from domain runtime mbean
jhsi     04/01/10 - Remote import and export support.
llu      12/14/09 - Sparse transfer support.
llu      11/30/09 - Move ScriptMessageHelper from oracle.mds.wlst.util to
                    oracle.mds.script.util.
llu      11/02/09 - Use ScriptMessageHelper.
llu      04/09/10 - Add sandbox import and export support.
jhsi     04/01/10 - Remote import and export support.
llu      01/26/10 - Move ScriptMessageHelper from oracle.mds.script.util to
                    oracle.mds.common.util.
llu      06/26/09 - #(8565405) Support IBM DB2 vendor.
akrajend 02/13/09 - #(8247108) Ignore the exception raised by help command.
vyerrama 02/10/09 - #(8239652) Added the caution message.
vyerrama 01/08/09 - #(7694242) Fixed the error message display.
akrajend 12/08/08 - #(7641532) Uncomment the dconfig commands.
vyerrama 11/10/08 - #(7552684,7552661) Bug Fixes.
jhsi     11/11/08 - Execute DomainRuntimeMBean at location domainRuntime.
llu      11/11/08 - start domainruntime for domain runtime operations
llu      11/10/08 - Add import of python core classes
akrajend 11/10/08 - #(7552941) Use import statements for all Py
                    classes being used.
akrajend 10/30/08 - #(7514849) Add mds wlst commands to help menu.
                    #(7484154) If "targetservers" is given as null
                    don't default it to admin server.
llu      10/29/08 - Do not create sub dir in exportMetadata
akrajend 10/29/08 - #(7518523) Comment out DConfig commands till JRF team
                    fixes the classpath issue.
akrajend 10/14/08 - Fix the DConfig command validations.
akrajend 10/07/08 - Changed to use resource bundle for messages.
vyerrama 10/06/08 - Updated param names, added validations
akrajend 09/29/08 - Fix the error messages.
akrajend 09/11/08 - Added commands for MDS DConfig.
vyerrama 08/22/08 - creation
-------------------------------------------------------------------------------
"""

import ora_util
ora_util.addScriptHandlers()

from jarray import array

from java.io import File

from java.lang import Boolean
from java.lang import String
from java.lang import StringBuffer
from java.lang import Thread

from java.util import ArrayList
from java.util import Map
from java.util import Set

from javax.management.openmbean import *

from oracle.adf.share.deploy.config import AdfConfigChildType
from oracle.adf.share.deploy.config import AdfConfigType

from oracle.deployment.configuration import OracleArchiveConfiguration
from oracle.deployment.configuration import OracleConfigBean

from oracle.mds.config.util import MDSConnectionInfo
from oracle.mds.config.util import MDSRepositoryInfo

from oracle.mds.lcm.client import MDSAppInfo
from oracle.mds.lcm.client import MetadataTransferManager
from oracle.mds.lcm.client import TargetInfo
from oracle.mds.lcm.client import TransferParameters
from oracle.mds.lcm.client import ProgressObject
from oracle.mds.lcm.client import ProgressStatus
from oracle.mds.lcm.deploy.spi.xml import MDSDConfigType

from oracle.mds.common.util import ScriptMessageHelper

from org.python.core import PyArray
from org.python.core import PyInteger
from org.python.core import PyString
from org.python.core import PyLong

from pprint import pformat

import MDS_handler

try:
   addHelpCommandGroup("MDSrepositoryadmin", "oracle.mds.wlst.resources.MDSWLSTHelp")
   addHelpCommand("deleteMetadata", "MDSrepositoryadmin", offline="false")
   addHelpCommand("exportSandboxMetadata", "MDSrepositoryadmin", offline="false")
   addHelpCommand("importSandboxMetadata", "MDSrepositoryadmin", offline="false")
   addHelpCommand("exportMetadata", "MDSrepositoryadmin", offline="false")
   addHelpCommand("importMetadata", "MDSrepositoryadmin", offline="false")
   addHelpCommand("importMAR", "MDSrepositoryadmin", offline="false")
   addHelpCommand("createMetadataLabel", "MDSrepositoryadmin", offline="false")
   addHelpCommand("deleteMetadataLabel", "MDSrepositoryadmin", offline="false")
   addHelpCommand("listMetadataLabels", "MDSrepositoryadmin", offline="false")
   addHelpCommand("promoteMetadataLabel", "MDSrepositoryadmin", offline="false")
   addHelpCommand("purgeMetadata", "MDSrepositoryadmin", offline="false")
   addHelpCommand("deregisterMetadataDBRepository", "MDSrepositoryadmin", offline="false")
   addHelpCommand("registerMetadataDBRepository", "MDSrepositoryadmin", offline="false")
   addHelpCommand("purgeMetadataLabels", "MDSrepositoryadmin", offline="false")
   addHelpCommand("createMetadataPartition", "MDSrepositoryadmin", offline="false")
   addHelpCommand("deleteMetadataPartition", "MDSrepositoryadmin", offline="false")
   addHelpCommand("getMDSArchiveConfig", "MDSrepositoryadmin", online="false")
   addHelpCommand("deprovisionTenant", "MDSrepositoryadmin", offline="false")
   addHelpCommand("listTenants", "MDSrepositoryadmin", offline="false")
except WLSTException, e:
   # Ignore the exception and allow the commands to get loaded.
   pass

"""
-------------------------------------------------------------------------------
MDSAppRuntimeMBean operations
-------------------------------------------------------------------------------
"""
# This command deletes the metadata for an application.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @docs Comma seperated list of documents or document name patterns that should be deleted
# @restrictCustTo Comma seperated list of customization document names or patterns 
# @excludeBaseDocs
# @excludeExtendedMetadata
# @cancelOnException
# @applicationVersion
# @tenantName
def deleteMetadata(application, server, docs, restrictCustTo=None, excludeAllCust='false', excludeBaseDocs='false', excludeExtendedMetadata='false', cancelOnException='true', applicationVersion=None, tenantName=None):
        operationName = 'deleteMetadata'
        required(application, 'application')
        required(server,'server')
        required(docs,'docs')
        params = jarray.array([convertStringToArray(docs, 'docs', operationName), convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), getBooleanFromArg(excludeAllCust), getBooleanFromArg(excludeBaseDocs), getBooleanFromArg(excludeExtendedMetadata), getBooleanFromArg(cancelOnException), tenantName], java.lang.Object)
        signature = jarray.array(['[Ljava.lang.String;','[Ljava.lang.String;','boolean','boolean','boolean','boolean', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['docs', 'restrictCustTo', 'excludeAllCust', 'excludeBaseDocs', 'excludeExtendedMetadata', 'cancelOnException', 'tenantName'], java.lang.String)
        retValue = executeAppRuntimeMBeanOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        hideDisplay()
        return retValue

# This command exports Sandbox metadata for an application.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @toArchive
# @sandboxName
# @restrictCustTo
# @applicationVersion
# @remote
# @tenantName
def exportSandboxMetadata(application, server, toArchive, sandboxName, restrictCustTo='%', applicationVersion=None, remote='false', tenantName=None):
        operationName = 'exportSandboxMetadata'
        required(application,'application')
        required(server,'server')
        required(toArchive,'toArchive')
        required(sandboxName,'sandboxName')
        params=jarray.array([toArchive, sandboxName, convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), tenantName], java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String', '[Ljava.lang.String;', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['toArchive', 'sandboxName', 'restrictCustTo', 'tenantName'], java.lang.String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = executeMetadataTransferManagerOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        else:       
                retValue = executeAppRuntimeMBeanOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        hideDisplay()
        return retValue

# This command imports Sandbox metadata to the applications db repository from a given archive.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @fromArchive
# @forceSBCreation
# @useExistingSandbox
# @sandboxName
# @applicationVersion
# @remote
# @tenantName
def importSandboxMetadata(application, server, fromArchive, forceSBCreation='false', useExistingSandbox='false', sandboxName=None, applicationVersion=None, remote='false', tenantName=None):
        operationName = 'importSandboxMetadata'
        transMgrOperationName = 'importSandboxMetadata'
        required(application,'application')
        required(server,'server')
        required(fromArchive,'fromArchive')
        if getBooleanFromArg(useExistingSandbox) == Boolean('true') and sandboxName != None:
                params=jarray.array([fromArchive, sandboxName, tenantName], java.lang.Object)
                signature=jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String'], java.lang.String)
                paramNames = jarray.array(['fromArchive', 'sandboxName', 'tenantName'], java.lang.String)
                transMgrOperationName = 'updateSandboxMetadata'
        else:
                params=jarray.array([fromArchive, getBooleanFromArg(forceSBCreation), tenantName], java.lang.Object)
                signature=jarray.array(['java.lang.String', 'boolean', 'java.lang.String'], java.lang.String)
                paramNames = jarray.array(['fromArchive', 'forceSBCreation', 'tenantName'], java.lang.String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = executeMetadataTransferManagerOperation(application, applicationVersion, server, transMgrOperationName, params, signature, paramNames)
        else:
                retValue = executeAppRuntimeMBeanOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        hideDisplay()
        return retValue

# This command exports the metadata for an application.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
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
# @applicationVersion
# @remote
# @tenantName
def exportMetadata(application, server, toLocation, docs='/**', restrictCustTo=None, excludeCustFor=None, excludeAllCust='false', excludeBaseDocs='false', excludeExtendedMetadata='false', excludeSeededDocs='false', fromLabel=None, toLabel=None, applicationVersion=None, remote='false', tenantName=None):
        operationName = 'exportMetadata'
        required(application,'application')
        required(server,'server')
        required(toLocation,'toLocation')
        params = jarray.array([toLocation,getBooleanFromArg('false'), convertStringToArray(docs, 'docs', operationName), convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), convertStringToArray(excludeCustFor, 'excludeCustFor', operationName), getBooleanFromArg(excludeAllCust), getBooleanFromArg(excludeBaseDocs), getBooleanFromArg(excludeExtendedMetadata), getBooleanFromArg(excludeSeededDocs), fromLabel, toLabel, tenantName], java.lang.Object)
        signature = jarray.array(['java.lang.String', 'boolean', '[Ljava.lang.String;', '[Ljava.lang.String;', '[Ljava.lang.String;', 'boolean', 'boolean', 'boolean', 'boolean', 'java.lang.String', 'java.lang.String', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['toLocation', 'createSubDir', 'docs', 'restrictCustTo', 'excludeCustFor', 'excludeAllCust', 'excludeBaseDocs', 'excludeExtendedMetadata', 'excludeSeededDocs', 'fromLabel', 'toLabel', 'tenantName'], java.lang.String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = executeMetadataTransferManagerOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        else:       
                retValue = executeAppRuntimeMBeanOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        hideDisplay()
        return retValue

# This command imports the metadata to the applications repository from a given location.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @fromLocation
# @docs Comma seperated list of documents or document name patterns that should be deleted
# @restrictCustTo Comma seperated list of customization document names or patterns 
# @excludeAllCust
# @excludeBaseDocs
# @excludeExtendedMetadata
# @excludeUnmodifiedDocs
# @cancelOnException
# @applicationVersion
# @remote
# @tenantName
def importMetadata(application, server, fromLocation, docs='/**', restrictCustTo=None, excludeAllCust='false', excludeBaseDocs='false', excludeExtendedMetadata='false', excludeUnmodifiedDocs='false', cancelOnException='true', applicationVersion=None, remote='false', tenantName=None):
        operationName = 'importMetadata'
        required(application,'application')
        required(server,'server')
        required(fromLocation,'fromLocation')
        params=jarray.array([fromLocation, convertStringToArray(docs, 'docs', operationName), convertStringToArray(restrictCustTo, 'restrictCustTo', operationName), getBooleanFromArg(excludeAllCust), getBooleanFromArg(excludeBaseDocs), getBooleanFromArg(excludeExtendedMetadata), getBooleanFromArg(excludeUnmodifiedDocs), getBooleanFromArg(cancelOnException), tenantName], java.lang.Object)
        signature=jarray.array(['java.lang.String', '[Ljava.lang.String;', '[Ljava.lang.String;', 'boolean', 'boolean', 'boolean', 'boolean', 'boolean', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['fromLocation', 'docs', 'restrictCustTo', 'excludeAllCust', 'excludeBaseDocs', 'excludeExtendedMetadata', 'excludeUnmodifiedDocs', 'cancelOnException', 'tenantName'], java.lang.String)
        retValue = None
        if getBooleanFromArg(remote) == Boolean('true'):
                retValue = executeMetadataTransferManagerOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        else:
                retValue = executeAppRuntimeMBeanOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        hideDisplay()
        return retValue

# This command imports the metadata from the MAR packaged with the application to the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @force
# @applicationVersion
def importMAR(application, server, force='true', applicationVersion=None):
        operationName = 'importMAR'
        required(application,'application')
        required(server,'server')
        params=jarray.array([getBooleanFromArg(force)], java.lang.Object)
        signature=jarray.array(['boolean'], java.lang.String)
        paramNames = jarray.array(['force'],java.lang.String)
        retValue = executeAppRuntimeMBeanOperation(application, applicationVersion, server, operationName, params, signature, paramNames)
        printMessage("OPERATION_COMPLETED_SUMMARY", operationName)
        prettyPrintValue(retValue)
        hideDisplay()
        return retValue

# This command creates a metadata label in the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @name
# @applicationVersion
# @tenantName
def createMetadataLabel(application, server, name, applicationVersion=None, tenantName=None):
        required(application,'application')
        required(server,'server')
        required(name,'name')
        params= jarray.array([name, tenantName],java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String'],java.lang.String)
        paramNames = jarray.array(['name', 'tenantName'], java.lang.String)
        retValue= executeAppRuntimeMBeanOperation(application, applicationVersion, server, 'createMetadataLabel', params, signature, paramNames)
        printMessage("CREATED_METADATA_LABEL", retValue)
        hideDisplay()
        return retValue

# This command deletes the metadata label in the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @name
# @applicationVersion
# @tenantName
def deleteMetadataLabel(application, server, name, applicationVersion=None, tenantName=None):
        required(application,'application')
        required(server,'server')
        required(name,'name')
        params= jarray.array([name, tenantName], java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['name', 'tenantName'], java.lang.String)
        executeAppRuntimeMBeanOperation(application, applicationVersion, server, 'deleteMetadataLabel', params, signature, paramNames)
        printMessage("DELETE_METADATA_LABEL", name)

# This command lists all the labels created in the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @applicationVersion
# @tenantName
def listMetadataLabels(application, server, applicationVersion=None, tenantName=None):
        required(application,'application')
        required(server,'server')
        params= jarray.array([tenantName], java.lang.Object)
        signature=jarray.array(['java.lang.String'], java.lang.String)
        paramNames = jarray.array(['tenantName'], java.lang.String)
        labels = executeAppRuntimeMBeanOperation(application, applicationVersion, server, 'listMetadataLabels', params, signature, paramNames)
        printMessage("LIST_METADATA_LABELS")
        if labels is None or len(labels) == 0:
                printMessage("NO_MATCHING_METADATA_LABELS")
        else:
                printArray(labels)
        hideDisplay()
        return labels

# This command promotes the metadata for a label to the tip.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @name
# @applicationVersion
# @tenantName
def promoteMetadataLabel(application, server, name, applicationVersion=None, tenantName=None):
        required(application,'application')
        required(server,'server')
        required(name,'name')
        params= jarray.array([name, tenantName],java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String'],java.lang.String)
        paramNames = jarray.array(['name', 'tenantName'], java.lang.String)
        executeAppRuntimeMBeanOperation(application, applicationVersion, server, 'promoteMetadataLabel', params, signature, paramNames)
        printMessage("PROMOTE_METADATA_LABEL", name)

# This command purges metadata from the application's repository.
# @application The name of the application for which the AppRuntimeMBeans is to be invoked
# @server
# @olderThan
# @applicationVersion
def purgeMetadata(application, server, olderThan, applicationVersion=None):
        required(application,'application')
        required(server,'server')
        required(olderThan, 'olderThan')
        params= jarray.array([olderThan], Object)
        signature=jarray.array(['long'],java.lang.String)
        paramNames = jarray.array(['olderThan'],java.lang.String)
        message=executeAppRuntimeMBeanOperation(application, applicationVersion, server, 'purgeMetadata', params, signature, paramNames)
        printMessage("METADATA_PURGED", None, message)
        hideDisplay()
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
        params= jarray.array([name],java.lang.Object)
        signature=jarray.array(['java.lang.String'],java.lang.String)
        paramNames = jarray.array(['name'],java.lang.String)
        executeDomainRuntimeMBeanOperation('deregisterMetadataDBRepository',params,signature, paramNames)
        printMessage("DEREGISTER_METADATA_REPOSITORY", name)

# This command registers a DB metadata repository with the server.
# @name
# @dbVendor
# @host
# @port
# @dbName
# @user
# @password
# @targetServers
def registerMetadataDBRepository(name, dbVendor, host, port, dbName, user, password, targetServers=None):
        operationName = 'registerMetadataDBRepository'
        required(name,'name')
        required(dbVendor,'dbVendor')
        required(host,'host')
        required(port,'port')
        required(dbName,'dbName')
        required(user,'user')
        required(password,'password')
        params= jarray.array([name, getDBVendorCode(dbVendor, operationName), host, port, dbName, user, password, convertStringToArray(targetServers, 'targetServers', operationName)],java.lang.Object)
        signature=jarray.array(['java.lang.String','int','java.lang.String','java.lang.String','java.lang.String','java.lang.String','java.lang.String', '[Ljava.lang.String;'],java.lang.String)
        paramNames = jarray.array(['name', 'dbVendor', 'host', 'port', 'dbName', 'user', 'password', 'targetServers'],java.lang.String)
        name=executeDomainRuntimeMBeanOperation(operationName, params, signature, paramNames)
        printMessage("REGISTER_METADATA_REPOSITORY", name)
        hideDisplay()
        return name

# This command creates a metadata partition in the repository specified by repository parameter.
# @repository
# @partition
def createMetadataPartition(repository, partition):
        required(repository,'repository')
        required(partition,'partition')
        params= jarray.array([repository, partition], java.lang.Object)
        signature=jarray.array(['java.lang.String','java.lang.String'],java.lang.String)
        paramNames = jarray.array(['repository', 'partition'],java.lang.String)
        name=executeDomainRuntimeMBeanOperation('createMetadataPartition',params, signature, paramNames)
        msgparams=name + ',' + repository
        printMessage("CREATE_METADATA_PARTITION", msgparams)
        hideDisplay()
        return name

# This command deletes a metadata partition in the repository specified by repository parameter.
# @repository
# @partition
def deleteMetadataPartition(repository, partition):
        required(repository,'repository')
        required(partition,'partition')
        params= jarray.array([repository, partition], java.lang.Object)
        signature=jarray.array(['java.lang.String','java.lang.String'],java.lang.String)
        paramNames = jarray.array(['repository', 'partition'],java.lang.String)
        name=executeDomainRuntimeMBeanOperation('deleteMetadataPartition',params,signature, paramNames)
        msgparams=partition + ',' + repository
        printMessage("DELETE_METADATA_PARTITION", msgparams)
        hideDisplay()
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
        params= jarray.array([repository, partition, namePattern, java.lang.Long(olderThanInMin), tenantName], java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String', 'long', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['repository', 'partition', 'namePattern', 'olderThanInMin', 'tenantName'], java.lang.String)

        if namePattern == None:
                namePatternStr = '<Null>'
        else:
                namePatternStr = namePattern
        if tenantName == None:
                tenantNameStr = '<Null>'
        else:
                tenantNameStr = tenantName
        msgparams = " repository=" + repository + ',parititon=' + partition + ',namePattern=' + namePatternStr + ',olderThanInMin=' + olderThanInMin + ',tenantName=' + tenantNameStr + ": "

        if Boolean(infoOnly).booleanValue():
                cd=executeDomainRuntimeMBeanOperation('listMetadataLabels', params, signature, paramNames)
                printMessage("LIST_METADATA_LABELS_PATTERN", None, msgparams)

                if isinstance(cd, CompositeData):
                        labels = cd.get('labels')
                        if labels is None or len(labels) == 0:
                                printMessage("NO_MATCHING_METADATA_LABELS")
                        else:
                                printValueFromCompositeData(labels, 'name')
                        hideDisplay()
                        return labels
                hideDisplay()
                return cd
        else:
                labels=executeDomainRuntimeMBeanOperation('purgeMetadataLabels', params, signature, paramNames)
                printMessage("PURGE_METADATA_LABELS", None, msgparams)
                if labels is None or len(labels) == 0:
                        printMessage("NO_MATCHING_METADATA_LABELS")
                else:
                        printArray(labels)
                hideDisplay()
                return labels


# This command deprovisions a tenant along with all of the content.
# @repository
# @partition
# @tenantName
def deprovisionTenant(repository, partition, tenantName):
        required(repository, 'repository')
        required(partition, 'partition')
        required(tenantName, 'tenantName')
        params= jarray.array([repository, partition, tenantName], java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['repository', 'partition', 'tenantName'], java.lang.String)
        executeDomainRuntimeMBeanOperation('deprovisionTenant', params, signature, paramNames)
        MDS_handler.printMessage("DEPROVISION_TENANT", tenantName)

# This command lists all tenants
# @repository
# @partition
def listTenants(repository, partition):
        required(repository, 'repository')
        required(partition, 'partition')
        params= jarray.array([repository, partition], java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String'], java.lang.String)
        paramNames = jarray.array(['repository', 'partition'], java.lang.String)
        tenants = executeDomainRuntimeMBeanOperation('listTenants', params, signature, paramNames)
        MDS_handler.printTenants(tenants)
        hideDisplay()
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
           if exitonerror == "true":
             saveStackAndRaiseException(e, ScriptMessageHelper.getMessage("OPERATION_FAILED", "Archive Config"))
           else:
             print e.getMessage()

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
        params = jarray.array([repository, partition, type, jndi, path], java.lang.Object)
        signature =jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String'],java.lang.String)
        paramNames = jarray.array(['repository', 'partition', 'type', 'jndi', 'path'],java.lang.String)
        validateDataTypes(params, signature, paramNames, operation)
        appRepos = self.__mdsConfig.getAppMetadataRepositoryInfo()
        if appRepos.getConnection() == None:
          if repository == None or partition == None or type == None:
            raise WLSTException, ScriptMessageHelper.getMessage("PARMAS_FOR_NEW_APP_REPOS", operation)
        if type != None:
          type = String(type)
          if type.equalsIgnoreCase('DB') == 0 and type.equalsIgnoreCase('File') == 0:
            raise WLSTException, ScriptMessageHelper.getMessage("CONNECTION_TYPE_NOT_CORRECT", operation)
          if appRepos.getConnection() == None or type.equalsIgnoreCase(appRepos.getConnection().getType()) == 0:
            if type.equalsIgnoreCase('DB') and jndi == None:
              raise WLSTException, ScriptMessageHelper.getMessage("JNDI_PARAM_NOT_PROVIDED", operation)
            if type.equalsIgnoreCase('File') and path == None:
              raise WLSTException, ScriptMessageHelper.getMessage("PATH_PARAM_NOT_PROVIDED", operation)
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
        params= jarray.array([namespace, repository, partition, type, jndi, path], java.lang.Object)
        signature=jarray.array(['java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String'],java.lang.String)
        paramNames = jarray.array(['namespace', 'repository', 'partition', 'type', 'jndi', 'path'],java.lang.String)
        validateDataTypes(params, signature, paramNames, operation)
        required(namespace, 'namespace')
        sharedRepositories = self.__mdsConfig.getSharedMetadataRepositoryInfo()
        if len(sharedRepositories) == 0:
          raise WLSTException, ScriptMessageHelper.getMessage("NO_SHARED_REPOS_MAPPING", operation)
        sharedRepos = None
        for repos in sharedRepositories:
           if repos.getNamespaces()[0] == namespace:
              sharedRepos = repos
              break
        if sharedRepos == None:
          raise WLSTException, ScriptMessageHelper.getMessage("NAMESPACE_NOT_VALID", namespace, operation)
        if repos.getConnection() == None:
          if repository == None or partition == None or type == None:
            raise WLSTException, ScriptMessageHelper.getMessage("PARMAS_FOR_NEW_SHARED_REPOS", namespace, operation)
        if type != None:
          type = String(type)
          if type.equalsIgnoreCase('DB') == 0 and type.equalsIgnoreCase('File') == 0:
            raise WLSTException, ScriptMessageHelper.getMessage("CONNECTION_TYPE_NOT_CORRECT", operation)
          if repos.getConnection() == None or type.equalsIgnoreCase(repos.getConnection().getType()) == 0:
            if type.equalsIgnoreCase('DB') and jndi == None:
              raise WLSTException, ScriptMessageHelper.getMessage("JNDI_PARAM_NOT_PROVIDED", operation)
            if type.equalsIgnoreCase('File') and path == None:
              raise WLSTException, ScriptMessageHelper.getMessage("PATH_PARAM_NOT_PROVIDED", operation)
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
        params= jarray.array([toLocation], java.lang.Object)
        signature=jarray.array(['java.lang.String'],java.lang.String)
        paramNames = jarray.array(['toLocation'],java.lang.String)
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
           raise WLSTException, ScriptMessageHelper.getMessage("ADF_CONFIG_NOT_FOUND", operation)
        configBean.__class__ = AdfConfigType
        children = configBean.getAdfConfigChildBeans()
        for child in children:
             if isinstance(child, MDSDConfigType):
                    child.__class__ = MDSDConfigType
                    return child
        raise WLSTException, ScriptMessageHelper.getMessage("MDS_CONFIG_NOT_FOUND", operation)
    
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
    params= jarray.array([fromLocation], java.lang.Object)
    signature=jarray.array(['java.lang.String'],java.lang.String)
    paramNames = jarray.array(['fromLocation'],java.lang.String)
    validateDataTypes(params, signature, paramNames, 'getMDSArchiveConfig')
    hideDisplay()
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
def isConnectedToWLS(operation):
    if (mbs is None):
                raise UserWarning, ScriptMessageHelper.getMessage("NOT_CONNECTED_TO_SERVER", 'Weblogic', operation)

def getMDSMBean(name, mbeanOperation):
        isConnectedToWLS(mbeanOperation)
        mdsName = ObjectName(name)
        beans = mbs.queryMBeans(mdsName, None)
        if ( beans.size() > 0):
                return beans
        else:
                return None

def getMDSAppRuntimeMBean(application, appVersion, server, mbeanOperation):
        application = String(application).trim()
        checkForEmptyString(application, 'application', mbeanOperation)
        server = String(server).trim()
        checkForEmptyString(server, 'server', mbeanOperation)
        applicationVersion = appVersion
        if ( appVersion is not None ):
                applicationVersion = String(appVersion).trim()
                checkForEmptyString(applicationVersion, 'applicationVersion', mbeanOperation)

        beanName = 'oracle.mds.lcm:name=MDSAppRuntime,type=MDSAppRuntime,Application=' + application 
        if ( applicationVersion is not None ):
                beanName = beanName + ',ApplicationVersion=' + applicationVersion

        srvName=serverName
        if ( server is not None ):
                srvName=server

        if ( isAdminServer == 'true') :
                beanName = beanName + ',Location=' + srvName + ',*'
        
        bean = getMDSMBean(beanName, mbeanOperation)
        if bean is None:
                raise UserWarning, ScriptMessageHelper.getMessage("MDS_APP_MBEAN_NOT_FOUND_IN_SERVER", jarray.array([application, mbeanOperation, server], String))
        elif bean.size() > 1:
                raise UserWarning, ScriptMessageHelper.getMessage("MULTIPLE_APP_MBEAN_FOUND_IN_SERVER", jarray.array([application, mbeanOperation, server], String))
        else:
                return bean.iterator().next().getObjectName()

def getMDSDomainRuntimeMBean(mbeanOperation):
        bean = getMDSMBean('oracle.mds.lcm:name=MDSDomainRuntime,type=MDSDomainRuntime', mbeanOperation)
        if bean is None:
                raise UserWarning, ScriptMessageHelper.getMessage("MDS_DOMAIN_MBEAN_NOT_FOUND", mbeanOperation)
        else:
                return bean.iterator().next().getObjectName()

def getBooleanFromArg(arg):
        if arg is None:
                return Boolean('false')
        else:
                return Boolean(arg)

def executeAppRuntimeMBeanOperation(application, applicationVersion, server, mbeanOperation, params, signature, paramNames):
        isConnectedToWLS(mbeanOperation)
        validateDataTypes(params, signature, paramNames, mbeanOperation)
        currentLoc=currentTree()
        if ( isAdminServer == 'true' ):
                domainRuntime()
        else:
                custom()

        printMessage("START_OPERATION", mbeanOperation)
        try:
                beanName = getMDSAppRuntimeMBean(application, applicationVersion, server, mbeanOperation)
                try:
                        retValue = mbs.invoke(beanName, mbeanOperation, params, signature)
                        return retValue
                except:
                        tp,val,tb = sys.exc_info()
                        saveStackAndRaiseException(val, ScriptMessageHelper.getMessage("OPERATION_FAILED", mbeanOperation))
        finally:
                currentLoc()

def executeDomainRuntimeMBeanOperation(mbeanOperation, params, signature, paramNames):
        isConnectedToWLS(mbeanOperation)
        validateDataTypes(params, signature, paramNames, mbeanOperation)
        if ( isAdminServer != 'true' ):
                raise WLSTException, ScriptMessageHelper.getMessage("NOT_AN_ADMIN_SERVER", mbeanOperation)
        currentLoc=currentTree()
        domainRuntime()

        printMessage("START_OPERATION", mbeanOperation)
        try:
                beanName = getMDSDomainRuntimeMBean(mbeanOperation)
                try:
                        retValue = mbs.invoke(beanName, mbeanOperation, params, signature)
                        return retValue
                except:
                        tp,val,tb=sys.exc_info()
                        saveStackAndRaiseException(val, ScriptMessageHelper.getMessage("OPERATION_FAILED", mbeanOperation))
        finally:
                currentLoc()

def executeMetadataTransferManagerOperation(application, applicationVersion, server, mbeanOperation, params, signature, paramNames):
        isConnectedToWLS(mbeanOperation)
        validateDataTypes(params, signature, paramNames, mbeanOperation)
        currentLoc=currentTree()
        if ( isAdminServer == 'true' ):
                domainRuntime()
        else:
                custom()

        printMessage("START_OPERATION", mbeanOperation)
        try:
                try:
                        mtm = MetadataTransferManager(mbs, MetadataTransferManager.ASPlatform.WEBLOGIC)
                        appInfo = MDSAppInfo(application, applicationVersion)
                        target = TargetInfo(server)
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
                except:
                        tp,val,tb = sys.exc_info()
                        saveStackAndRaiseException(val, ScriptMessageHelper.getMessage("OPERATION_FAILED", mbeanOperation))
        finally:
                currentLoc()
                
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
        if scriptMode == 'false':
                if val is None:
                        return
        
                if isinstance(val, Map):
                        entSt = val.entrySet()
                        itr = entSt.iterator()
                        while java.util.Iterator.hasNext(itr):
                                ent = itr.next()
                                print ent.getValue().get('value')


def printArray(val):
        if scriptMode == 'false':
                if val is None:
                        return
                for i in range(len(val)):
                        print val[i]

def printValueFromCompositeData(val, key):
        if scriptMode == 'false':
                if val is None:
                        return
                if key is None:
                        return
                for i in range(len(val)):
                        if isinstance(val[i], CompositeData):
                                if val[i].containsKey(key):
                                        print val[i].get(key)

def printMessage(key, values=None, message=None):
        if scriptMode == 'false':
                params=convertStringToArray(values, 'values','printMessage')
                msg=ScriptMessageHelper.getMessage(key,params)
                if (message is not None):
                        msg = msg + message
                print msg

def checkForEmptyString(var, paramName, operation):
        if String(var).equals(""):
                msg = ScriptMessageHelper.getMessage("PARAM_IS_EMPTY", jarray.array([paramName, operation], java.lang.Object))
                raise WLSTException, msg

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
                msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["String", paramName, str(tp), operation],java.lang.Object))
                raise WLSTException, msg

def validateArray(var, paramName, operation):
        if var is None:
                return
        elif isinstance(var, PyArray):
                for i in range(len(var)):
                        trimStr = String(var[i]).trim()
                        if String(trimStr).equals(""):
                                msg = ScriptMessageHelper.getMessage("PARAM_CONTAINS_EMPTY_ELEMENT", jarray.array([paramName, operation], java.lang.Object))
                                raise WLSTException, msg
                return
        else:
                tp=type(var)
                msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["array of strings", paramName, str(tp), operation],java.lang.Object))
                raise WLSTException, msg
        
def validateInteger(var, paramName, operation):
        if var is None:
                return
        elif isinstance(var, PyInteger):
                return
        else:
                tp=type(var)
                msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["int", paramName, str(tp), operation],java.lang.Object))
                raise WLSTException, msg

def validateBoolean(var, paramName, operation):
        validateInteger(var, paramName, operation)

def validateList(var, paramName, operation):
        if var is None:
                return
        elif isinstance(var, java.util.List):
                return
        else:
                tp = type(var)
                msg = ScriptMessageHelper.getMessage("PARAM_NOT_CORRECT", jarray.array(["java.util.List", paramName, str(tp), operation],java.lang.Object))
                raise WLSTException, msg

def getDBVendorCode(var, operation):
        required(var, 'dbVendor')
        if ( var.upper() == 'ORACLE'):
                return 0
        elif ( var.upper() == 'MSSQL'):
                return 1
        elif ( var.upper() == 'IBMDB2'):
                return 2
        elif ( var.upper() == 'MYSQL'):
                return 3
        else:
                raise WLSTException, ScriptMessageHelper.getMessage("DB_VENDOR_NOT_CORRECT", operation)

def required(var, name):
        if (var == None):
                raise WLSTException, ScriptMessageHelper.getMessage("REQUIRED_PARAM_NOT_FOUND", name)

def saveStackAndRaiseException(ex, message):
        setDumpStackThrowable(ex)
        errmsg = ex.getMessage()
        if errmsg is None:
                errmsg = ex.toString()
        errmsg = errmsg + " " + message + " Use dumpStack() to view the full stacktrace."
        raise WLSTException, errmsg
