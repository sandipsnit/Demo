################################################################
# Copyright (c) 2009, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

try:
    _oc = System.getProperty('COMMON_COMPONENTS_HOME')
    if _oc is not None:
        _sh = os.path.join(_oc, os.path.join('common', 'script_handlers'))
        if _sh not in sys.path:
            sys.path.append(_sh)
except:
    print "" #ignore the exception

import igfConfig_handler as igfhandler
import ora_mbs


def addIGFCommandHelp():
  igfhandler.addIGFCommandHelpImpl();

addIGFCommandHelp()


#######################################################
# Helper methods
#######################################################
def igfConfig_gotoDomainRuntime():
  currentNode = pwd()
  if (currentNode.find('domainRuntime') == -1):
    ctree = currentTree()
    domainRuntime()
    ora_mbs.setMbs(mbs)
    return ctree
  else:
    return None


#
# CARML/Mapping Configuration
#

#######################################################
# This function lists all Entity Names in a CARML
#######################################################
def listAllIgfEntityNames(appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.listAllIgfEntityNamesImpl(appName)


#######################################################
# This function lists all the interactions in a CARML
#######################################################
def listAllIgfInteractions(appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.listAllIgfInteractionsImpl(appName)


#########################################################
# This function adds the attribute to CARML & Mapping file
#########################################################
def addIgfAttribute(appName, attrName, targetName, dataType, entities, interactions, isAddToFilter, params, paramVals):
  igfConfig_gotoDomainRuntime()
  igfhandler.addIgfAttributeImpl(appName, attrName, targetName, dataType, entities, interactions, isAddToFilter, params, paramVals)


##############################################################################
# This function adds the attribute reference to the interacation(s) in a CARML
##############################################################################
def addIgfAttributeToInteraction(appName, attrName, interaction, entity):
  igfConfig_gotoDomainRuntime()
  igfhandler.addIgfAttributeToInteractionImpl(appName, attrName, interaction, entity)


##############################################################
# This function deletes the attribute from CARML & Mapping file
##############################################################
def deleteIgfAttribute(appName, attrName):
  igfConfig_gotoDomainRuntime()
  igfhandler.deleteIgfAttributeImpl(appName, attrName)


##############################################################
# This function modifies the attribute mapping in Mapping file
##############################################################
def modifyIgfMapping(appName, entityName, attrName, newTargetName):
  igfConfig_gotoDomainRuntime()
  igfhandler.modifyIgfMappingImpl(appName, entityName, attrName, newTargetName)


#
# Identity Directory Configuration
#

#######################################################
# This function adds new entity in entity configuration
#######################################################
def addEntity(name, type, idAttr, create, modify, delete, search, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.addEntity(name, type, idAttr, create, modify, delete, search, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName)

#######################################################################
# This function updates the entity's properties in entity configuration
#######################################################################
def updateEntity(name, type, idAttr, create, modify, delete, search, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.updateEntity(name, type, idAttr, create, modify, delete, search, appName)

#######################################################
# This function adds new attribute for specified entity
#######################################################
def addAttributeRefForEntity(name, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.addAttributeRefForEntity(name, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName)

######################################################
# This function removes attribute for specified entity
######################################################
def removeAttributeRefForEntity(name, attrRefName, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.removeAttributeRefForEntity(name, attrRefName, appName)

######################################################
# This function deletes entity in entity configuration
######################################################
def deleteEntity(name, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.deleteEntity(name, appName)

#################################################################
# This function adds new operation config in entity configuration
#################################################################
def addOperationConfig(entityName, propNames, propValues, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.addOperationConfig(entityName, propNames, propValues, appName)

################################################################
# This function adds a new property for given operational config
################################################################
def addPropertyForOperationConfig(entityName, propName, propValue, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.addPropertyForOperationConfig(entityName, propName, propValue, appName)

#################################################################
# This function removes the property for given operational config
#################################################################
def removePropertyForOperationConfig(entityName, propName, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.removePropertyForOperationConfig(entityName, propName, appName)

###################################$######
# This function deletes operational config
##########################################
def deleteOperationConfig(entityName, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.deleteOperationConfig(entityName, appName)

################################################################
# This function adds new entity relation in entity configuration
################################################################
def addEntityRelation(name, type, fromEntity, fromAttr, toEntity, toAttr, recursive, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.addEntityRelation(name, type, fromEntity, fromAttr, toEntity, toAttr, recursive, appName)

###############################################################
# This function deletes entity relation in entity configuration
###############################################################
def deleteEntityRelation(name, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.deleteEntityRelation(name, appName)

############################################################
# This function adds a new attribute in entity configuration
############################################################
def addAttributeInEntityConfig(name, datatype, description, readOnly, pwdAttr, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.addAttributeInEntityConfig(name, datatype, description, readOnly, pwdAttr, appName)

###############################################################
# This function deletes the attribute from entity configuration
###############################################################
def deleteAttributeInEntityConfig(name, appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.deleteAttributeInEntityConfig(name, appName)

############################################################
# This function lists all attributes in entity configuration
############################################################
def listAllAttributeInEntityConfig(appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.listAllAttributeInEntityConfig(appName)

##########################################################
# This function lists all entities in entity configuration
##########################################################
def listAllEntityInEntityConfig(appName):
  igfConfig_gotoDomainRuntime()
  igfhandler.listAllEntityInEntityConfig(appName)

#######################################################################
# This function adds new IdentityDirectory Service in IDS configuration
#######################################################################
def addIdentityDirectoryService(name, description, propNames, propValues):
  igfConfig_gotoDomainRuntime()
  igfhandler.addIdentityDirectoryService(name, description, propNames, propValues)

####################################################################################
# This function deletes the specified IdentityDirectory Service in IDS configuration
####################################################################################
def deleteIdentityDirectoryService(name):
  igfConfig_gotoDomainRuntime()
  igfhandler.deleteIdentityDirectoryService(name)

#########################################################################
# This function lists all IdentityDirectory Services in IDS configuration
#########################################################################
def listAllIdentityDirectoryService():
  igfConfig_gotoDomainRuntime()
  igfhandler.listAllIdentityDirectoryService()

#########################################
# This function reloads IDS configuration
#########################################
def activateIDSConfigChanges():
  igfConfig_gotoDomainRuntime()
  igfhandler.activateIDSConfigChanges()

