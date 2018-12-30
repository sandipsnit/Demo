"""
 Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 
-------------------------------------------------------------------------------
Caution: This file is part of the WSADMIN implementation. Do not edit or move
this file because this may cause WSADMIN commands and scripts to fail. Do not
try to reuse the logic in this file or keep copies of this file because this
could cause your WSADMIN scripts to fail when you upgrade to a different version
of WSADMIN. 
-------------------------------------------------------------------------------
MODIFIED (MM/DD/YY)
glook  7/5/12  - Created. Updates ADF View shared library to include Batik jars

-------------------------------------------------------------------------------
"""

import OracleJRF

BATIK_CLASSPATH = '$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-anim.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-awt-util.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-bridge.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-codec.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-css.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-dom.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-extension.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-ext.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-gui-util.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-gvt.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-parser.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-script.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-svg-dom.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-svggen.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-swing.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-transcoder.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-util.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/batik-xml.jar;$ORACLE_HOME$/modules/oracle.adf.view_11.1.1/xml-apis-ext.jar'

APACHE_HTTP_CLASSPATH = '$ORACLE_HOME$/modules/org.apache.http.components.httpclient-4.1.2.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpclient-cache-4.1.2.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpcore-4.1.2.jar;$ORACLE_HOME$/modules/org.apache.http.components.httpmime-4.1.2.jar'

def updateADFLibrary(cellName, nodeName, serverName, libraryName='adf.oracle.domain.webapp', libraryImplVersion='1.0_11.1.1.2.0'):
    targetPath = OracleJRF.jrf_getServerPath(cellName, nodeName, serverName)

    adf_upgradeLibraries(targetPath, libraryName+'_'+libraryImplVersion)
    
    shouldUpdateConfig = 1
    OracleJRF.jrf_saveConfig(shouldUpdateConfig)

# End upgradeADF



#*****************************************************************#
#       Upgrade helpers                                           #
#*****************************************************************#

def adf_upgradeLibraries(targetPath, adfViewLibraryName='adf.oracle.domain.webapp_1.0_11.1.1.2.0'):

    # create a library class with the Batik classpath 
    batikLibrary = ADFJRFLibrary('batikLibrary', OracleJRF.jrf_convertLibPath(BATIK_CLASSPATH))
    
    # create a library class with the Apache HTTP classpath 
    apacheHttpLibrary = ADFJRFLibrary('apacheHttpLibrary', OracleJRF.jrf_convertLibPath(APACHE_HTTP_CLASSPATH))

    # append the Batik and Apache library classpath to the existing shared ADF webapp library
    libraryId = AdminConfig.getid(targetPath+'/Library:' + adfViewLibraryName + '/')
    prevClassPath = AdminConfig.showAttribute(libraryId, 'classPath')
    newClassPath = prevClassPath + ';' + batikLibrary.srcPath + ';' + apacheHttpLibrary.srcPath
    AdminConfig.modify(libraryId, [['classPath', newClassPath]])

# End adf_upgradeLibraries

#Define the class for library resource.

class ADFJRFLibrary:
    def __init__(self, name, srcPath):
        self.name = name
        self.srcPath = srcPath

