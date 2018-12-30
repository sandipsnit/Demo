################################################################
# Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 
################################################################

from java.lang import Exception
from java.lang import Object
from java.lang import String
from java.lang import Boolean
import jarray
import ora_help
import ora_mbs

TYPE_STRING = "java.lang.String"
TYPE_STRING_ARRAY = "[Ljava.lang.String;"
TYPE_BOOLEAN = "java.lang.Boolean"
TYPE_BOOLEAN_ARRAY = "[Ljava.lang.Boolean;"


###########################
# Helper Methods
###########################

#MBean name is different for diff app servers, so modify the name accordingly
def getIGFMBeanObject(name):
  if(ora_mbs.isWebSphereND() == 1):
    on = AdminControl.completeObjectName(name+',process=dmgr,*')
  elif(ora_mbs.isWebSphereAS() == 1):
    on = AdminControl.completeObjectName(name+',*')
  else:
    on = name
  objectName = ora_mbs.makeObjectName(on)
  return objectName



##############################
# Command Implementation
##############################

# This function lists all Entity Names in a CARML
def listAllIgfEntityNamesImpl(appName):
  carmlObj = getIGFMBeanObject('com.oracle.igf:name=CarmlConfig_' + appName + ',type=Xml')
  objs1 = jarray.array([], Object)
  sigs1 = jarray.array([], String)
  interactions = ora_mbs.invoke(carmlObj, 'listAllEntityNames', objs1, sigs1)
  length = len(interactions)
  print '%-7s\n' % ('EntityNames')
  for i in range(length):
     print '%-7s' % (interactions[i])


# This function lists all the interactions in a CARML
def listAllIgfInteractionsImpl(appName):
  carmlObj = getIGFMBeanObject('com.oracle.igf:name=CarmlConfig_' + appName + ',type=Xml')
  objs1 = jarray.array([], Object)
  sigs1 = jarray.array([], String)
  interactions = ora_mbs.invoke(carmlObj, 'listAllInteractions', objs1, sigs1)
  length = len(interactions)
  print '%-25s\t%-20s\t%-7s\n' % ('InteractionName','InteractionType','EntityName')
  for i in range(length):
     splitVals = interactions[i].split(",")
     print '%-25s\t%-20s\t%-7s' % (splitVals[0], splitVals[1], splitVals[2])


# This function adds the attribute to CARML & Mapping file
def addIgfAttributeImpl(appName, attrName, targetName, dataType, entities, interactions, isAddToFilter, params, paramVals):
  carmlObj = getIGFMBeanObject('com.oracle.igf:name=CarmlConfig_' + appName + ',type=Xml')
  mappingObj = getIGFMBeanObject('com.oracle.igf:name=MappingConfig_' + appName + ',type=Xml')
  objs1 = jarray.array([attrName, targetName, dataType, entities, interactions, isAddToFilter, params, paramVals], Object)
  sigs1 = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING], String)
  res = ora_mbs.invoke(carmlObj, 'addAttributeWLST', objs1, sigs1)
  res = ora_mbs.invoke(mappingObj, 'addAttributeWLST', objs1, sigs1)


# This function adds the attribute reference to the interacation(s) in a CARML
def addIgfAttributeToInteractionImpl(appName, attrName, interaction, entity):
  carmlObj = getIGFMBeanObject('com.oracle.igf:name=CarmlConfig_' + appName + ',type=Xml')
  objs1 = jarray.array([attrName, interaction, entity], Object)
  sigs1 = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING], String)
  res = ora_mbs.invoke(carmlObj, 'addAttributeToInteraction', objs1, sigs1)


# This function deletes the attribute from CARML & Mapping file
def deleteIgfAttributeImpl(appName, attrName):
  carmlObj = getIGFMBeanObject('com.oracle.igf:name=CarmlConfig_' + appName + ',type=Xml')
  mappingObj = getIGFMBeanObject('com.oracle.igf:name=MappingConfig_' + appName + ',type=Xml')
  objs1 = jarray.array([attrName], Object)
  sigs1 = jarray.array([TYPE_STRING], String)
  ora_mbs.invoke(carmlObj, 'deleteAttribute', objs1, sigs1)
  ora_mbs.invoke(mappingObj, 'deleteAttribute', objs1, sigs1)


# This function modifies the attribute mapping in Mapping file
def modifyIgfMappingImpl(appName, entityName, attrName, newTargetName):
  mappingObj = getIGFMBeanObject('com.oracle.igf:name=MappingConfig_' + appName + ',type=Xml')
  objs1 = jarray.array([entityName, attrName, newTargetName], Object)
  sigs1 = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING], String)
  try :
    res = ora_mbs.invoke(mappingObj, 'modifyMapping', objs1, sigs1)
  except MBeanException, e :
    print e.getMessage() + "\n"

def addEntity(name, type, idAttr, create, modify, delete, search, attrRefNames, attrRefFilters, attrRefDefaultFetches, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    attrRefNamesArr = jarray.array(attrRefNames.split("|"),String)
    attrRefFiltersArr = jarray.array(attrRefFilters.split("|"),String)
    attrRefDefaultFetchesArr = jarray.array(attrRefDefaultFetches.split("|"),String)
    objArray = jarray.array([name, type, idAttr, create, modify, delete, search, attrRefNamesArr, attrRefFiltersArr, attrRefDefaultFetchesArr], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, "boolean", "boolean", "boolean", "boolean", TYPE_STRING_ARRAY, TYPE_STRING_ARRAY, TYPE_STRING_ARRAY], String)
    ora_mbs.invoke(objName, 'addEntity', objArray, sigArray)

def updateEntity(name, type, idAttr, create, modify, delete, search, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name, type, idAttr, create, modify, delete, search], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, "boolean", "boolean", "boolean", "boolean"], String)
    ora_mbs.invoke(objName, 'updateEntity', objArray, sigArray)

def addAttributeRefForEntity(name, attrRefName, attrRefFilter, attrRefDefaultFetch, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name, attrRefName, attrRefFilter, attrRefDefaultFetch], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING], String)
    ora_mbs.invoke(objName, 'addAttributeRefForEntity', objArray, sigArray)

def removeAttributeRefForEntity(name, attrRefName, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name, attrRefName], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING], String)
    ora_mbs.invoke(objName, 'removeAttributeRefForEntity', objArray, sigArray)

def deleteEntity(name, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name], Object)
    sigArray = jarray.array([TYPE_STRING], String)
    ora_mbs.invoke(objName, 'deleteEntity', objArray, sigArray)

def addOperationConfig(entityName, propNames, propValues, appName):
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    propNameArr = jarray.array(propNames.split("|"),String)
    propValueArr = jarray.array(propValues.split("|"),String)
    objArray = jarray.array([appName, entityName, propNameArr, propValueArr], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING_ARRAY, TYPE_STRING_ARRAY], String)
    ora_mbs.invoke(objName, 'addOperationConfig', objArray, sigArray)

def addPropertyForOperationConfig(entityName, propName, propValue, appName):
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    objArray = jarray.array([appName, entityName, propName, propValue], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING], String)
    ora_mbs.invoke(objName, 'addPropertyForOperationConfig', objArray, sigArray)

def removePropertyForOperationConfig(entityName, propName, appName):
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    objArray = jarray.array([appName, entityName, propName], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING], String)
    ora_mbs.invoke(objName, 'removePropertyForOperationConfig', objArray, sigArray)


def deleteOperationConfig(entityName, appName):
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    objArray = jarray.array([appName, entityName], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING], String)
    ora_mbs.invoke(objName, 'deleteOperationConfig', objArray, sigArray)

def addEntityRelation(name, type, fromEntity, fromAttr, toEntity, toAttr, recursive, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name, type, fromEntity, fromAttr, toEntity, toAttr, recursive], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, TYPE_STRING, "boolean"], String)
    ora_mbs.invoke(objName, 'addEntityRelation', objArray, sigArray)

def deleteEntityRelation(name, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name], Object)
    sigArray = jarray.array([TYPE_STRING], String)
    ora_mbs.invoke(objName, 'deleteEntityRelation', objArray, sigArray)

def addAttributeInEntityConfig(name, datatype, description, readOnly, pwdAttr, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name, datatype, description, readOnly, pwdAttr], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING, "boolean", "boolean"], String)
    ora_mbs.invoke(objName, 'addAttributeInEntityConfig', objArray, sigArray)

def deleteAttributeInEntityConfig(name, appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objArray = jarray.array([name], Object)
    sigArray = jarray.array([TYPE_STRING], String)
    ora_mbs.invoke(objName, 'deleteAttributeInEntityConfig', objArray, sigArray)

def listAllAttributeInEntityConfig(appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objs2 = jarray.array([], Object)
    sigs2 = jarray.array([], String)
    attributes = ora_mbs.invoke(objName, 'listAllAttributeInEntityConfig', objs2, sigs2)
    length = len(attributes)
    print '%-7s\n' % ('Attributes')
    for i in range(length):
       print '%-7s' % (attributes[i])

def listAllEntityInEntityConfig(appName):
    objs1 = jarray.array([appName, "entity.config"], Object)
    sigs1 = jarray.array([TYPE_STRING, TYPE_STRING], String)
    idsObj = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    entityConfig = ora_mbs.invoke(idsObj, 'getPropertyForIdentityDirectory', objs1, sigs1)
    objName = getIGFMBeanObject('com.oracle.igf:name=' + entityConfig + ',type=Xml.EntityConfig')
    objs2 = jarray.array([], Object)
    sigs2 = jarray.array([], String)
    entities = ora_mbs.invoke(objName, 'listAllEntityInEntityConfig', objs2, sigs2)
    length = len(entities)
    print '%-7s\n' % ('Entities')
    for i in range(length):
       print '%-7s' % (entities[i])

def addIdentityDirectoryService(name, description, propNames, propValues):
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    propNameArr = jarray.array(propNames.split("|"),String)
    propValueArr = jarray.array(propValues.split("|"),String)
    objArray = jarray.array([name, description,propNameArr, propValueArr], Object)
    sigArray = jarray.array([TYPE_STRING, TYPE_STRING, TYPE_STRING_ARRAY, TYPE_STRING_ARRAY], String)
    ora_mbs.invoke(objName, 'addIdentityDirectoryService', objArray, sigArray)

def deleteIdentityDirectoryService(name):
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    objArray = jarray.array([name], Object)
    sigArray = jarray.array([TYPE_STRING], String)
    ora_mbs.invoke(objName, 'deleteIdentityDirectoryService', objArray, sigArray)

def activateIDSConfigChanges():
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    objArray = jarray.array([], Object)
    sigArray = jarray.array([], String)
    ora_mbs.invoke(objName, 'activateChanges', objArray, sigArray)

def listAllIdentityDirectoryService():
    objName = getIGFMBeanObject('com.oracle.igf:name=IDSConfig,type=Xml')
    objs1 = jarray.array([], Object)
    sigs1 = jarray.array([], String)
    identityStoreServices = ora_mbs.invoke(objName, 'listAllIdentityDirectoryService', objs1, sigs1)
    length = len(identityStoreServices)
    print '%-7s\n' % ('IdentityDirectoryService')
    for i in range(length):
       print '%-7s' % (identityStoreServices[i])



def addIGFCommandHelpImpl():
  try:
    ora_help.addHelpCommandGroup("igfconfig", "igfconfig_wlst")
    ora_help.addHelpCommandGroup("idsconfig", "igfconfig_wlst")
    ora_help.addHelpCommand("listAllIgfInteractions", "igfconfig")
    ora_help.addHelpCommand("listAllIgfEntityNames", "igfconfig")
    ora_help.addHelpCommand("deleteIgfAttribute", "igfconfig")
    ora_help.addHelpCommand("modifyIgfMapping", "igfconfig")
    ora_help.addHelpCommand("addIgfAttributeToInteraction", "igfconfig")
    ora_help.addHelpCommand("addIgfAttribute", "igfconfig")

    ora_help.addHelpCommand("addAttributeInEntityConfig", "idsconfig")
    ora_help.addHelpCommand("deleteAttributeInEntityConfig", "idsconfig")
    ora_help.addHelpCommand("addEntity", "idsconfig")
    ora_help.addHelpCommand("updateEntity", "idsconfig")
    ora_help.addHelpCommand("addAttributeRefForEntity", "idsconfig")
    ora_help.addHelpCommand("removeAttributeRefForEntity", "idsconfig")
    ora_help.addHelpCommand("deleteEntity", "idsconfig")
    ora_help.addHelpCommand("addOperationConfig", "idsconfig")
    ora_help.addHelpCommand("addPropertyForOperationConfig", "idsconfig")
    ora_help.addHelpCommand("removePropertyForOperationConfig", "idsconfig")
    ora_help.addHelpCommand("deleteOperationConfig", "idsconfig")
    ora_help.addHelpCommand("addEntityRelation", "idsconfig")
    ora_help.addHelpCommand("deleteEntityRelation", "idsconfig")
    ora_help.addHelpCommand("listAllAttributeInEntityConfig", "idsconfig")
    ora_help.addHelpCommand("listAllEntityInEntityConfig", "idsconfig")
    ora_help.addHelpCommand("addIdentityDirectoryService", "idsconfig")
    ora_help.addHelpCommand("deleteIdentityDirectoryService", "idsconfig")
    ora_help.addHelpCommand("listAllIdentityDirectoryService", "idsconfig")
    ora_help.addHelpCommand("activateIDSConfigChanges", "idsconfig")
  except (Exception), exc:
    return

