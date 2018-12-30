import os

#****************************************************************************
#
#****************************************************************************
def replaceOSBServerModuleVersion(setDomainEnvFileName, modulePath, replacePath):

  try:
    input = open(setDomainEnvFileName)
    configuration = input.read()
    input.close()
  except:
    print "Open file: " + setDomainEnvFileName + " failed.\n"
    return

  replaceStartIndex = configuration.index(modulePath)
  preReplace = configuration[:replaceStartIndex]
  postReplace = configuration[replaceStartIndex:]
  postReplaceIndex = postReplace.index(".jar");
  postReplace = postReplace[postReplaceIndex:]

  newConfiguration = preReplace + replacePath + postReplace
  try:
    replaceFile = open(setDomainEnvFileName, 'w')
    replaceFile.write(newConfiguration)
    replaceFile.close()
  except:
    print "Failed to write file: " + setDomainEnvFileName + "\n"
    return

#****************************************************************************
#
#****************************************************************************
def addEndorsedXSLTLib(setDomainEnvSh):

  try:
    input = open(setDomainEnvSh)
    configuration = input.read()
    input.close()
  except:
    print "Open file: " + setDomainEnvSh + " failed.\n"
    return

  commEnvCmd = "commEnv.sh"
  replaceStartIndex = configuration.index(commEnvCmd) + 10
  preInsert = configuration[:replaceStartIndex]
  postInsert = configuration[replaceStartIndex:]

  endorsedXSLTLib = "\n\n\nPLATFORM_TYPE=`uname -s`\n" + "case ${PLATFORM_TYPE} in\n" + "  AIX)\n" + "    EXTRA_JAVA_PROPERTIES=\"${EXTRA_JAVA_PROPERTIES} -Djavax.xml.datatype.DatatypeFactory=org.apache.xerces.jaxp.datatype.DatatypeFactoryImpl -Djava.endorsed.dirs=${ALSB_HOME}/lib/external/org.apache.xalan\"\n" + "    export EXTRA_JAVA_PROPERTIES\n" + "    ;;\n\n" + "  LINUX|Linux)\n" + "    arch=`uname -m`\n" + "    if [ \"${arch}\" = \"s390x\" ]; then\n" + "      EXTRA_JAVA_PROPERTIES=\"${EXTRA_JAVA_PROPERTIES} -Djavax.xml.datatype.DatatypeFactory=org.apache.xerces.jaxp.datatype.DatatypeFactoryImpl -Djava.endorsed.dirs=${ALSB_HOME}/lib/external/org.apache.xalan\"\n" + "      export EXTRA_JAVA_PROPERTIES\n" + "    fi\n" + "    ;;\n" + "  *)\n" + "    ;;\n" + "esac\n\n\n"

  newConfiguration = preInsert + endorsedXSLTLib + postInsert
  try:
    replaceFile = open(setDomainEnvSh, 'w')
    replaceFile.write(newConfiguration)
    replaceFile.close()
  except:
    print "Failed to write file: " + setDomainEnvSh + "\n"
    return

#****************************************************************************
#
#****************************************************************************
def replaceCoherenceRef(newConfiguration, mwHome):

  replaceStartIndex = newConfiguration.index("<name>Coherence") + 6
  preReplace = newConfiguration[:replaceStartIndex]
  postReplace = newConfiguration[replaceStartIndex:]
  postReplaceIndex = postReplace.index("</name>")
  postReplace = postReplace[postReplaceIndex:]

  postNameReplaceIndex = postReplace.index("<source-path>") + 13
  postNameReplace = postReplace[:postNameReplaceIndex]

  postSourcePathReplaceIndex = postReplace.index("</source-path>")
  postSourcePathReplace = postReplace[postSourcePathReplaceIndex:]

  postLibraryIndex = postSourcePathReplace.index("</library>\n")
  postSourcePathReplace = postSourcePathReplace[:postLibraryIndex]

  postStagingModeIndex = postReplace.index("</library>\n")
  postStagingMode = postReplace[postStagingModeIndex:]

  return preReplace + "oracle.jrf.coherence#3@11.1.1" + postNameReplace + mwHome + "/oracle_common/modules/oracle.jrf_11.1.1/jrf-coherence.jar" + postSourcePathReplace + "  <staging-mode>nostage</staging-mode>\n  " + postStagingMode


#****************************************************************************
#
#****************************************************************************
def insertStagingMode(configuration, name, endTag):

  startIdx = configuration.index(name)
  preStart = configuration[:startIdx]
  postStart = configuration[startIdx:]
  insertStartIdx = postStart.index(endTag);
  preInsert = postStart[:insertStartIdx]
  postInsert = postStart[insertStartIdx:]

  return preStart + preInsert + "  <staging-mode>nostage</staging-mode>\n  " + postInsert

#****************************************************************************
#
#****************************************************************************
def fixConfigFile(configFile, mwHome):

  try:
    import codecs
    input = codecs.open(configFile, mode='r', encoding='utf-8')
    configuration = input.read()
    input.close()
  except:
    print "Open config.xml failed.\n"
    return

  # app-deployment: ALSB Cluster Singleton Marker Application
  newConfiguration = insertStagingMode(configuration, "ALSB Cluster Singleton Marker Application", "</app-deployment>")

  # app-deployment: ALSB Domain Singleton Marker Application
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Domain Singleton Marker Application", "</app-deployment>")

  # app-deployment: ALSB Framework Starter Application
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Framework Starter Application", "</app-deployment>")

  # app-deployment: ALSB Coherence Cache Provider
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Coherence Cache Provider", "</app-deployment>")

  # app-deployment: XBus Kernel
  newConfiguration = insertStagingMode(newConfiguration, "XBus Kernel", "</app-deployment>")

  # app-deployment: ALSB UDDI Manager
  newConfiguration = insertStagingMode(newConfiguration, "ALSB UDDI Manager", "</app-deployment>")

  # app-deployment: ALSB Subscription Listener
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Subscription Listener", "</app-deployment>")

  # app-deployment: JMS Reporting Provider
  newConfiguration = insertStagingMode(newConfiguration, "JMS Reporting Provider", "</app-deployment>")

  # app-deployment: Message Reporting Purger
  newConfiguration = insertStagingMode(newConfiguration, "Message Reporting Purger", "</app-deployment>")

  # app-deployment: Ftp Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "Ftp Transport Provider", "</app-deployment>")

  # app-deployment: SFTP Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "SFTP Transport Provider", "</app-deployment>")

  # app-deployment: Email Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "Email Transport Provider", "</app-deployment>")

  # app-deployment: File Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "File Transport Provider", "</app-deployment>")

  # app-deployment: MQ Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "MQ Transport Provider", "</app-deployment>")

  # app-deployment: EJB Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "EJB Transport Provider", "</app-deployment>")

  # app-deployment: Tuxedo Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "Tuxedo Transport Provider", "</app-deployment>")

  # app-deployment: ALDSP Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "ALDSP Transport Provider", "</app-deployment>")

  # app-deployment: SB Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "SB Transport Provider", "</app-deployment>")

  # app-deployment: WS Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "WS Transport Provider", "</app-deployment>")

  # app-deployment: WS Transport Async Applcation
  newConfiguration = insertStagingMode(newConfiguration, "WS Transport Async Applcation", "</app-deployment>")

  # app-deployment: FLOW Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "FLOW Transport Provider", "</app-deployment>")

  # app-deployment: BPEL 10g Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "BPEL 10g Transport Provider", "</app-deployment>")

  # app-deployment: JCA Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "JCA Transport Provider", "</app-deployment>")

  # app-deployment: JEJB Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "JEJB Transport Provider", "</app-deployment>")

  # app-deployment: SOA-DIRECT Transport Provider
  newConfiguration = insertStagingMode(newConfiguration, "SOA-DIRECT Transport Provider", "</app-deployment>")

  # app-deployment: ALSB Routing
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Routing", "</app-deployment>")

  # app-deployment: ALSB Transform
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Transform", "</app-deployment>")

  # app-deployment: ALSB Publish
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Publish", "</app-deployment>")

  # app-deployment: ALSB Logging
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Logging", "</app-deployment>")

  # app-deployment: ALSB Resource
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Resource", "</app-deployment>")

  # app-deployment: ALSB WSIL
  newConfiguration = insertStagingMode(newConfiguration, "ALSB WSIL", "</app-deployment>")

  # app-deployment: ServiceBus_Console
  newConfiguration = insertStagingMode(newConfiguration, "ServiceBus_Console", "</app-deployment>")

  # app-deployment: ALSB Test Framework
  newConfiguration = insertStagingMode(newConfiguration, "ALSB Test Framework", "</app-deployment>")

  # library: Coherence#3.5.2@v3.5.2b463
  newConfiguration = replaceCoherenceRef(newConfiguration, mwHome)

  # library: coherence-l10n#11.1.1@11.1.1
  newConfiguration = insertStagingMode(newConfiguration, "coherence-l10n", "</library>")

  # library: ftptransport-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "ftptransport-l10n", "</library>")

  # library: sftptransport-l10n#3.0@3.0
  newConfiguration = insertStagingMode(newConfiguration, "sftptransport-l10n", "</library>")

  # library: emailtransport-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "emailtransport-l10n", "</library>")

  # library: filetransport-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "filetransport-l10n", "</library>")

  # library: mqtransport-l10n#3.0@3.0
  newConfiguration = insertStagingMode(newConfiguration, "mqtransport-l10n", "</library>")

  # library: mqconnection-l10n#3.0@3.0
  newConfiguration = insertStagingMode(newConfiguration, "mqconnection-l10n", "</library>")

  # library: ejbtransport-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "ejbtransport-l10n", "</library>")

  # library: tuxedotransport-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "tuxedotransport-l10n", "</library>")

  # library: aldsp_transport-l10n#3.0@3.0
  newConfiguration = insertStagingMode(newConfiguration, "aldsp_transport-l10n", "</library>")

  # library: wstransport-l10n#2.6@2.6
  newConfiguration = insertStagingMode(newConfiguration, "wstransport-l10n", "</library>")

  # library: flow-transport-l10n#3.0@3.0
  newConfiguration = insertStagingMode(newConfiguration, "flow-transport-l10n", "</library>")

  # library: bpel10gtransport-l10n#3.1@3.1
  newConfiguration = insertStagingMode(newConfiguration, "bpel10gtransport-l10n", "</library>")

  # library: jcatransport-l10n#3.1@3.1
  newConfiguration = insertStagingMode(newConfiguration, "jcatransport-l10n", "</library>")

  # library: wsif#11.1.1@11.1.1
  newConfiguration = insertStagingMode(newConfiguration, "<name>wsif#11", "</library>")

  # library: JCAFrameworkImpl#11.1.1@11.1.1
  newConfiguration = insertStagingMode(newConfiguration, "JCAFrameworkImpl#11", "</library>")

  # library: jejbtransport-l10n#3.2@3.2
  newConfiguration = insertStagingMode(newConfiguration, "jejbtransport-l10n", "</library>")

  # library: jejbtransport-jar#3.2@3.2
  newConfiguration = insertStagingMode(newConfiguration, "jejbtransport-jar", "</library>")

  # library: soatransport-l10n#11.1.1.2.0@11.1.1.2.0
  newConfiguration = insertStagingMode(newConfiguration, "soatransport-l10n", "</library>")

  # library: stage-utils#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "stage-utils", "</library>")

  # library: sbconsole-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "sbconsole-l10n", "</library>")

  # library: xbusrouting-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "xbusrouting-l10n", "</library>")

  # library: xbustransform-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "xbustransform-l10n", "</library>")

  # library: xbuspublish-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "xbuspublish-l10n", "</library>")

  # library: xbuslogging-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "xbuslogging-l10n", "</library>")

  # library: testfwk-l10n#2.5@2.5
  newConfiguration = insertStagingMode(newConfiguration, "testfwk-l10n", "</library>")

  # library: com.bea.wlp.lwpf.console.app#10.3.0@10.3.0
  newConfiguration = insertStagingMode(newConfiguration, "com.bea.wlp.lwpf.console.app", "</library>")

  # library: com.bea.wlp.lwpf.console.web#10.3.0@10.3.0
  newConfiguration = insertStagingMode(newConfiguration, "com.bea.wlp.lwpf.console.web", "</library>")

  # library: wlp-lookandfeel-web-lib#10.3.0@10.3.0
  newConfiguration = insertStagingMode(newConfiguration, "wlp-lookandfeel-web-lib", "</library>")

  # library: wlp-light-web-lib#10.3.0@10.3.0
  newConfiguration = insertStagingMode(newConfiguration, "wlp-light-web-lib", "</library>")

  # library: wlp-framework-common-web-lib#10.3.0@10.3.0
  newConfiguration = insertStagingMode(newConfiguration, "wlp-framework-common-web-lib", "</library>")

  # library: wlp-framework-struts-1.2-web-lib#10.3.0@10.3.0
  newConfiguration = insertStagingMode(newConfiguration, "wlp-framework-struts-1.2-web-lib", "</library>")

  # library: struts-1.2#1.2@1.2.9
  newConfiguration = insertStagingMode(newConfiguration, "<name>struts-1.2", "</library>")

  # library: beehive-netui-1.0.1-10.0#1.0@1.0.2.2
  newConfiguration = insertStagingMode(newConfiguration, "<name>beehive-netui-1.0.1-10.0", "</library>")

  # library: beehive-netui-resources-1.0.1-10.0#1.0@1.0.2.2
  newConfiguration = insertStagingMode(newConfiguration, "beehive-netui-resources-1.0.1-10.0", "</library>")

  # library: beehive-controls-1.0.1-10.0-war#1.0@1.0.2.2
  newConfiguration = insertStagingMode(newConfiguration, "beehive-controls-1.0.1-10.0-war", "</library>")

  # library: weblogic-controls-10.0-war#10.0@10.2
  newConfiguration = insertStagingMode(newConfiguration, "weblogic-controls-10.0-war", "</library>")

  # library: wls-commonslogging-bridge-war#1.0@1.1
  newConfiguration = insertStagingMode(newConfiguration, "wls-commonslogging-bridge-war", "</library>")

  # library: jstl#1.2@1.2.0.1
  newConfiguration = insertStagingMode(newConfiguration, "<name>jstl", "</library>")

  try:
    import codecs
    replaceFile = codecs.open(configFile, mode='w', encoding='utf-8')
    replaceFile.write(newConfiguration)
    replaceFile.close()
  except:
    print "Failed to write config.xml\n"
    return


#****************************************************************************
#
#****************************************************************************
print ''

props = os.environ
try:
  domainHome = props['DOMAIN_HOME']
except:
  print ' ERROR: Environment variable DOMAIN_HOME is not set.'
  exit()

try:
  mwHome = props['MW_HOME']
except:
  print ' ERROR: Environment variable MW_HOME is not set.'
  exit()

setDomainEnvCmd = "%s/bin/setDomainEnv.cmd" % (domainHome)
if os.path.isfile(setDomainEnvCmd):
  modulePath = "\\modules\\features\\osb.server.modules_11.1.1.3"
  replacePath = "\\lib\\osb-server-modules-ref"
  replaceOSBServerModuleVersion(setDomainEnvCmd, modulePath, replacePath)

setDomainEnvSh = "%s/bin/setDomainEnv.sh" % (domainHome)
modulePath = "/modules/features/osb.server.modules_11.1.1.3"
replacePath = "/lib/osb-server-modules-ref"
replaceOSBServerModuleVersion(setDomainEnvSh, modulePath, replacePath)
addEndorsedXSLTLib(setDomainEnvSh)

configFile = "%s/config/config.xml" % (domainHome)
fixConfigFile(configFile, mwHome)

print ''
print 'Done!'
