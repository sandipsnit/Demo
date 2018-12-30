"""
 Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the WLST implementation. Do not edit or move
this file because this may cause WLST commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WLST scripts to fail when you upgrade to a different version
of WLST. 
-------------------------------------------------------------------------------
MODIFIED (MM/DD/YY)
dbajpai  05/3/11  - Created. Installs JSF 2.0 shared library into a target 
                    domain if not present.
-------------------------------------------------------------------------------
"""
import os
import glob
import fnmatch
from java.util.jar import JarFile
from java.util.jar import Manifest
from java.util.jar import Attributes
from oracle.adfm.common.util import ScriptMessageHelper as ADFMScriptMessageHelper

try:
    addHelpCommandGroup("JarsVersion", "oracle.adfm.wlst.resources.ADFMWLSTHelp")
    addHelpCommand("exportJarVersions", "JarsVersion", online="false")
    addHelpCommand("exportApplicationJarVersions", "JarsVersion", online="true")
    addHelpCommand("exportApplicationSelectedJarVersions", "JarsVersion", online="true")
except WLSTException, e:
    # Ignore the exception and allow the commands to get loaded.
    pass

#*****************************************************************#
#       WLST Commands - Jars Version                              #
#*****************************************************************#

def exportJarVersions(path):
   jarsManifest = getjarsManifestFromDir()
   try:
      printAtPath(jarsManifest, path)
   except Exception, e:
      print e.getMessage()

def exportApplicationJarVersions(appName, path):
      adfGetApplicationRuntimeJars(appName, path)

def exportApplicationSelectedJarVersions(appName, path, *jars):
    args=buildJarsList(jars)
    if args != '':
        adfGetSelectedRuntimeJars(appName, path, args)
    else:
        adfGetApplicationDefaultSelectedRuntimeJars(appName, path)

# End Jars version Commands 

#*****************************************************************#
#                  Jars Version Helper                            #
#*****************************************************************#

def getjarsManifestFromDir():
   global jarsinfo
   jarsinfo = "Jar Path,Oracle-Version,Oracle-Label,Oracle-Builder,Oracle-BuildTimestamp,Specification-Version,Implementation-Version"
   jarsinfo = jarsinfo + "\n"
   oraclehome = java.lang.System.getProperty("COMMON_COMPONENTS_HOME")
   currentDir = str(oraclehome)+'/modules'  
   getJarsInfoFromDir(currentDir)
   return jarsinfo

def getJarsInfoFromDir(dirs):
   global jarsinfo 
   try:
      for afile in glob.glob( os.path.join(dirs,'*')):
         if os.path.isdir(afile):
            getJarsInfoFromDir(afile)
         else:
             if(fnmatch.fnmatch(afile,'*.jar')):
                jarFile = JarFile(afile)
                try:
                  strproperty = ""
                  jarManifest = Manifest(jarFile.getManifest())
                  mattr = jarManifest.getMainAttributes()
                  jarsinfo = jarsinfo + afile + ","
                  strproperty = mattr.getValue("Oracle-Version");
                  if strproperty is not None:
                     jarsinfo = jarsinfo + strproperty +","
                  else:  
                     jarsinfo = jarsinfo + ","
                  strproperty = mattr.getValue("Oracle-Label")
                  if strproperty is not None:
                     jarsinfo = jarsinfo + strproperty +","
                  else:
                     jarsinfo = jarsinfo + ","
                  strproperty = mattr.getValue("Oracle-Builder");
                  if strproperty is not None:
                     jarsinfo = jarsinfo + strproperty +","
                  else:
                     jarsinfo = jarsinfo + ","
                  strproperty = mattr.getValue("Oracle-BuildTimestamp")
                  if strproperty is not None:
                     jarsinfo = jarsinfo + strproperty +","
                  else:
                     jarsinfo = jarsinfo + ","
                  strproperty = mattr.getValue("Specification-Version")
                  if strproperty is not None:
                     jarsinfo = jarsinfo + strproperty +","
                  else: 
                     jarsinfo = jarsinfo + ","
                  strproperty = mattr.getValue("Implementation-Version")
                  if strproperty is not None:
                     jarsinfo = jarsinfo + strproperty +"\n" 
                  else:  
                     jarsinfo = jarsinfo + "\n"
                except Exception, ex:
                  jarsinfo = jarsinfo + afile + ",,,,,," + "\n"
                  pass
   except IOException, e: 
      print e.getMessage()
      pass


def printAtPath(versions, path):
   try:
      writer1 = FileWriter(path)
      out1 = PrintWriter(writer1)
      out1.println(versions)
      out1.close()
   except IOException, e:
      print e.getMessage()   

      
def adfGetApplicationRuntimeJars(appName, path):    
    objname= ObjectName('*oracle.adf.share.config:name=ADFConfig,type=ADFConfig,Application='+appName+',*')
    check = adfIsConnected()
    if check is None:
       return
    else:
       mbset = mbs.queryNames(objname,None)
       if adf_debugIsEnabled():
           print 'objname = ' + objname.toString()
           print 'mbset = ' + mbset.toString()
       mbarray= mbset.toArray()
       if len(mbarray) - 1 < 0:
           print ADFMScriptMessageHelper.getMessage("APP_NOT_DEPLOYED_ON_SERVER")
           return
       for i in range(len(mbarray)):
          runtimeJarsCSV = getADFConfigObjNamesForRuntimeJars(mbarray[i])
       try:
           printAtPath(runtimeJarsCSV, path)
       except IOException, e:
           print e.getMessage()

def getADFConfigObjNamesForRuntimeJars(ADFConfigObjName):     
    connObjNameArray = mbs.invoke(ADFConfigObjName,'retrieveRuntimeJarManifestInfoCSV',None,None)
    return connObjNameArray

def adfGetSelectedRuntimeJars(appName, path, args):    
    objname= ObjectName('*oracle.adf.share.config:name=ADFConfig,type=ADFConfig,Application='+appName+',*')
    check = adfIsConnected()
    if check is None:
       return
    else:
       mbset = mbs.queryNames(objname,None)
       if adf_debugIsEnabled():
           print 'objname = ' + objname.toString()
           print 'mbset = ' + mbset.toString()
       mbarray= mbset.toArray()
       if len(mbarray) - 1 < 0:
              print ADFMScriptMessageHelper.getMessage("APP_NOT_DEPLOYED_ON_SERVER")
              return
       for i in range(len(mbarray)):
          runtimeJarsCSV = getADFConfigObjNamesForSelectedRuntimeJars(mbarray[i],args)
       try:
           printAtPath(runtimeJarsCSV, path)
       except IOException, e:
           print e.getMessage()

def getADFConfigObjNamesForSelectedRuntimeJars(ADFConfigObjName,selectedJarsList):     
    objs = jarray.array([java.lang.String(selectedJarsList)],java.lang.Object)
    strs = jarray.array(['java.lang.String'],java.lang.String)
    connObjNameArray = mbs.invoke(ADFConfigObjName,'retrieveSelectedRuntimeJarManifestInfoCSV',objs,strs)
    return connObjNameArray

def adfGetApplicationDefaultSelectedRuntimeJars(appName, path):    
    objname= ObjectName('*oracle.adf.share.config:name=ADFConfig,type=ADFConfig,Application='+appName+',*')
    check = adfIsConnected()
    if check is None:
       return
    else:
       mbset = mbs.queryNames(objname,None)
       if adf_debugIsEnabled():
           print 'objname = ' + objname.toString()
           print 'mbset = ' + mbset.toString()
       mbarray= mbset.toArray()
       if len(mbarray) - 1 < 0:
              print ADFMScriptMessageHelper.getMessage("APP_NOT_DEPLOYED_ON_SERVER")
              return
       for i in range(len(mbarray)):
           runtimeJarsCSV = getADFConfigObjNamesForDefaultSelectedJars(mbarray[i])
       try:
           printAtPath(runtimeJarsCSV, path)
       except IOException, e:
           print e.getMessage()

def getADFConfigObjNamesForDefaultSelectedJars(ADFConfigObjName):     
    connObjNameArray = mbs.invoke(ADFConfigObjName,'retrieveSelectedRuntimeJarManifestInfoCSV',None,None)
    return connObjNameArray


def buildJarsList(fields):
    args = ""
    for f in fields:     
        args = args + f + ";"
    return args   
            
def adfIsConnected():
   if mbs is None:
      print ADFMScriptMessageHelper.getMessage("CONNECT_TO_THE_SERVER")
      return None
   else:
      origDirectory = pwd()
      return origDirectory
