# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 
#
# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

"""CIE Configuration Handler"""

import cie.ConfigUtilities as utils

from com.oracle.cie.was.jython import WasConfig
from com.oracle.cie.was.jython import JvmConfig
from com.oracle.cie.was.jython import ConfigGroupsUpdater

def getWasConfig():
    utils.debug("ConfigHandler.getWasConfig() >")
    utils.debug("ConfigHandler initializing WasConfig")
    return WasConfig.getSerializedWasConfig();

def getSerializedWasConfig():
    utils.debug("ConfigHandler.getSerializedWasConfig() >")
    return WasConfig.getSerializedWasConfig();

def setWasConfig(objectString):
    utils.debug("ConfigHandler.setWasConfig() >")
    utils.debug("ConfigHandler Unmarshalling Object")
    WasConfig.setConfigWasCellSerialized(objectString);

def createConfigTypes(schema, parentId, type, ids):
    utils.debug("ConfigHandler.createConfigTypes() >")
    utils.debug("Creating config types " + type)
    WasConfig.getInstance().createConfigTypes(schema, parentId, type, ids);

def createNamedConfigTypes(schema, parentId, type, propName, ids):
    utils.debug("ConfigHandler.createConfigTypes() >")
    utils.debug("Creating config types " + type)
    WasConfig.getInstance().createConfigTypes(schema, parentId, type, propName, ids);

def createResourceAdapterConfigTypes(schema, filePath):
    utils.debug("ConfigHandler.createResourceAdapterConfigTypes() >")
    utils.debug("Creating ResourceAdapter config types ")
    WasConfig.getInstance().createResourceAdapterConfigTypes(schema, filePath);

def setConfigAttributes(id, attribs):
    utils.debug("ConfigHandler.setConfigAttributes() >")
    utils.debug("Setting attributes for " + id)
    WasConfig.getInstance().setConfigAttributes(id, attribs);

def setConfigAttribute(id, attribName, attribValue):
    utils.debug("ConfigHandler.setConfigAttribute() >")
    utils.debug("Setting attribute for " + id)
    WasConfig.getInstance().setConfigAttribute(id, attribName, attribValue);

def addConfigAttribute(id, attribName, attribValue):
    utils.debug("ConfigHandler.addConfigAttribute() >")
    utils.debug("Adding attribute for " + id)
    WasConfig.getInstance().addConfigAttribute(id, attribName, attribValue);

def getResourceAsString(resourcePath):
    utils.debug("ConfigHandler.getResourceAsString() >")
    return WasConfig.getResourceAsString(resourcePath);

def setJvmConfig(serverName, nodeName, configName, key, value):
    utils.debug("ConfigHandler.setJvmConfig() >")
    return JvmConfig.getInstance().setJvmConfig(serverName, nodeName, configName, key, value);

def getSerializedJvmConfig():
    utils.debug("ConfigHandler.getSerializedJvmConfig() >")
    return JvmConfig.getSerializedJvmConfig();

def updateConfigGroups(type, name, id):
    utils.debug("ConfigHandler.updateConfigGroups() >")
    return ConfigGroupsUpdater.updateConfigGroups(type, name, id);

def saveConfigGroups():
    utils.debug("ConfigHandler.saveConfigGroups() >")
    return ConfigGroupsUpdater.save();
