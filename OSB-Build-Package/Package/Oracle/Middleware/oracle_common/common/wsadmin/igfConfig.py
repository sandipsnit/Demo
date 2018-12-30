################################################################
# Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

import igfConfig_handler as igfhandler
import cie.OracleHelp as OracleHelp


def help(topic = None):
  m_name = 'igfconfig'
  if topic == None:
    topic = m_name
  else:
    topic = m_name + '.' + topic
  return OracleHelp.help(topic)

#
# CARML/Mapping Configuration
#

#######################################################
# This function lists all Entity Names in a CARML
#######################################################
def listAllIgfEntityNames(appName):
  igfhandler.listAllIgfEntityNamesImpl(appName)


#######################################################
# This function lists all the interactions in a CARML
#######################################################
def listAllIgfInteractions(appName):
  igfhandler.listAllIgfInteractionsImpl(appName)


#########################################################
# This function adds the attribute to CARML & Mapping file
#########################################################
def addIgfAttribute(appName, attrName, targetName, dataType, entities, interactions, isAddToFilter, params, paramVals):
  igfhandler.addIgfAttributeImpl(appName, attrName, targetName, dataType, entities, interactions, isAddToFilter, params, paramVals)


##############################################################################
# This function adds the attribute reference to the interacation(s) in a CARML
##############################################################################
def addIgfAttributeToInteraction(appName, attrName, interaction, entity):
  igfhandler.addIgfAttributeToInteractionImpl(appName, attrName, interaction, entity)


##############################################################
# This function deletes the attribute from CARML & Mapping file
##############################################################
def deleteIgfAttribute(appName, attrName):
  igfhandler.deleteIgfAttributeImpl(appName, attrName)


##############################################################
# This function modifies the attribute mapping in Mapping file
##############################################################
def modifyIgfMapping(appName, entityName, attrName, newTargetName):
  igfhandler.modifyIgfMappingImpl(appName, entityName, attrName, newTargetName)


#
# Identity Directory Configuration
#

#######################################################
# This function adds new entity in entity configuration
#######################################################
def addEntity(name, type, idAttr, create, modify, delete, search, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName):
  igfhandler.addEntity(name, type, idAttr, create, modify, delete, search, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName)

#######################################################################
# This function updates the entity's properties in entity configuration
#######################################################################
def updateEntity(name, type, idAttr, create, modify, delete, search, appName):
  igfhandler.updateEntity(name, type, idAttr, create, modify, delete, search, appName)

#######################################################
# This function adds new attribute for specified entity
#######################################################
def addAttributeRefForEntity(name, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName):
  igfhandler.addAttributeRefForEntity(name, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName)

######################################################
# This function removes attribute for specified entity
######################################################
def removeAttributeRefForEntity(name, attrRefName, appName):
  igfhandler.removeAttributeRefForEntity(name, attrRefName, appName)

######################################################
# This function deletes entity in entity configuration
######################################################
def deleteEntity(name, appName):
  igfhandler.deleteEntity(name, appName)

#################################################################
# This function adds new operation config in entity configuration
#################################################################
def addOperationConfig(entityName, propNames, propValues, appName):
  igfhandler.addOperationConfig(entityName, propNames, propValues, appName)

################################################################
# This function adds a new property for given operational config
################################################################
def addPropertyForOperationConfig(entityName, propName, propValue, appName):
  igfhandler.addPropertyForOperationConfig(entityName, propName, propValue, appName)

#################################################################
# This function removes the property for given operational config
#################################################################
def removePropertyForOperationConfig(entityName, propName, appName):
  igfhandler.removePropertyForOperationConfig(entityName, propName, appName)

###################################$######
# This function deletes operational config
##########################################
def deleteOperationConfig(entityName, appName):
  igfhandler.deleteOperationConfig(entityName, appName)

################################################################
# This function adds new entity relation in entity configuration
################################################################
def addEntityRelation(name, type, fromEntity, fromAttr, toEntity, toAttr, recursive, appName):
  igfhandler.addEntityRelation(name, type, fromEntity, fromAttr, toEntity, toAttr, recursive, appName)

###############################################################
# This function deletes entity relation in entity configuration
###############################################################
def deleteEntityRelation(name, appName):
  igfhandler.deleteEntityRelation(name, appName)

############################################################
# This function adds a new attribute in entity configuration
############################################################
def addAttributeInEntityConfig(name, datatype, description, readOnly, pwdAttr, appName):
  igfhandler.addAttributeInEntityConfig(name, datatype, description, readOnly, pwdAttr, appName)

###############################################################
# This function deletes the attribute from entity configuration
###############################################################
def deleteAttributeInEntityConfig(name, appName):
  igfhandler.deleteAttributeInEntityConfig(name, appName)

############################################################
# This function lists all attributes in entity configuration
############################################################
def listAllAttributeInEntityConfig(appName):
  igfhandler.listAllAttributeInEntityConfig(appName)

##########################################################
# This function lists all entities in entity configuration
##########################################################
def listAllEntityInEntityConfig(appName):
  igfhandler.listAllEntityInEntityConfig(appName)

#######################################################################
# This function adds new IdentityDirectory Service in IDS configuration
#######################################################################
def addIdentityDirectoryService(name, description, propNames, propValues):
  igfhandler.addIdentityDirectoryService(name, description, propNames, propValues)

####################################################################################
# This function deletes the specified IdentityDirectory Service in IDS configuration
####################################################################################
def deleteIdentityDirectoryService(name):
  igfhandler.deleteIdentityDirectoryService(name)

#########################################################################
# This function lists all IdentityDirectory Services in IDS configuration
#########################################################################
def listAllIdentityDirectoryService():
  igfhandler.listAllIdentityDirectoryService()

#########################################
# This function reloads IDS configuration
#########################################
def activateIDSConfigChanges():
  igfhandler.activateIDSConfigChanges()

