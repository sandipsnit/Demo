################################################################
# Copyright (c) 2010, Oracle and/or its affiliates. All rights reserved. 
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


