@echo off

setlocal

REM ###########################################################
REM # Figure out the directory where this script resides.
REM # Figure out base install directory.
REM # Assume the base install directory is one level up from where this
REM # script resides.
REM ###########################################################

set script_dir=%~f0
set base_dir=%script_dir:\bin\ua.bat=%
set script_dir=%script_dir:\ua.bat=%
set MW_HOME=%base_dir%\..

cd /d %script_dir%

REM ##########################################################
REM Get location of JRF
REM ##########################################################
if exist %base_dir%\modules set jrf_dir=..
if exist %MW_HOME%\oracle_common\modules set jrf_dir=..\..\oracle_common
if "%jrf_dir%" == "" goto :nojrf

REM ##########################################################
REM Execute WebLogic script to define WL_HOME if the script exists
REM ##########################################################
set wl_script1=%MW_HOME%\utils\config\10.3\setHomeDirs.cmd
if exist %wl_script1% CALL %wl_script1%

REM ##########################################################
REM Look for JAVA_HOME in the environment
REM ##########################################################
set SAVED_HOME=%JAVA_HOME%
set was_script=%MW_HOME%\oracle_common\common\bin\setWasHome.cmd
if exist %was_script% CALL %was_script%
if exist %WAS_HOME% set JAVA_HOME=%WAS_HOME%\java
set wl_script2=%WL_HOME%\common\bin\commEnv.cmd
if exist %wl_script2% CALL %wl_script2%
if exist %base_dir%\jdk\bin\java.exe set JAVA_HOME=%base_dir%\jdk

if not "%JAVA_HOME%" == "" goto :javahomefound
if not "%SAVED_HOME%" == "" set JAVA_HOME=%SAVED_HOME%
if "%JAVA_HOME%" == "" goto :nojavahome

:javahomefound

REM ##########################################################
REM Setting MAXPERMSIZE for SUN HOTSPOT
REM ##########################################################

set jdk_version_file=%base_dir%\upgrade\temp\jdk_version.log
"%JAVA_HOME%\bin\java.exe" -version >  %jdk_version_file%   2>&1
findstr /m "HotSpot" %jdk_version_file%

if %errorlevel% == 0 (
   set MAXPERMSIZE=-XX:MaxPermSize=128M
)

REM ##########################################################
REM Look for the SOA_HOME
REM ##########################################################
set CLASSPATH=%base_dir%\jlib\ua.jar
"%JAVA_HOME%\bin\java.exe" -DMW_HOME="%MW_HOME%" oracle.ias.upgrade.SoaFinder > soaloc.txt
SET /P SOA_HOME=<soaloc.txt

set PATH=%base_dir%\bin;%base_dir%\oui\lib\win32;%PATH%

REM ##########################################################
REM # Name of the Oracle JDBC driver
REM ##########################################################
SET OJDBC=%JRF_DIR%\modules\oracle.jdbc_11.1.1\ojdbc6dms.jar 

REM ##########################################################
REM # Name of the directory that contains the DataDirect JDBC drivers
REM ##########################################################
set WL_LIB=%JRF_DIR%\modules\datadirect_4.1
set FMW_DIR=%JRF_DIR%\modules\oracle.jrf_11.1.1
set DATADIRECT_WLS=%FMW_DIR%\fmwgenerictoken.jar;%WL_LIB%\wlsqlserver.jar;%WL_LIB%\wldb2.jar;%WL_LIB%\wlsybase.jar;%WL_LIB%\wlinformix.jar
set MYSQL_WLS=%WL_LIB%\mysql-connector-java-commercial-5.0.3-bin.jar
set MYSQL_JDBC=%$JRF_DIR%\modules\mysql-connector-java-commercial-5.1.17\mysql-connector-java-commercial-5.1.17-bin.jar

REM ##########################################################
REM # All paths to jars are relative to %script_dir%
REM ##########################################################

set mtplugins=..\jlib\netua.jar;..\jlib\modplsqlua.jar;..\jlib\portalua.jar;..\jlib\dipua.jar;..\jlib\webcacheua.jar;..\jlib\ohsua.jar;..\jlib\discoua.jar;..\jlib\formsua.jar;..\jlib\reportsua.jar;..\jlib\oifua.jar;..\jlib\odiua.jar;..\jlib\ovdua.jar;..\jlib\biua.jar;..\jlib\oamua.jar;..\jlib\oaamua.jar;..\jlib\ucmua.jar;..\jlib\bipua.jar;..\jlib\oimua.jar

set mrplugins=..\jlib\PortalPlugin.jar;..\jlib\PcPlugin.jar;..\jlib\BIPlatformPlugin.jar;..\jlib\OaamPlugin.jar;;..\jlib\UcmPlugin.jar;;..\jlib\UrmPlugin.jar;..\jlib\OdiPlugin.jar;..\jlib\OidPlugin.jar;..\jlib\DiscovererPlugin.jar;..\jlib\MrcVersionPlugin.jar;..\jlib\postgresql-8.4-701.jdbc4.jar;%datadirect_wls%;%mysql_jdbc%;..\jlib\OimPlugin.jar

REM b2b dependency
set b2bdir=..\soa\modules\oracle.soa.b2b_11.1.1\b2b.jar
if exist %b2bdir% set b2bdep=%jrf_dir%\modules\oracle.adf.share.ca_11.1.1\adf-share-base.jar;%jrf_dir%\modules\oracle.adf.share_11.1.1\adflogginghandler.jar;%jrf_dir%\modules\oracle.ucp_11.1.0.jar;%jrf_dir%\modules\oracle.adf.model_11.1.1\jdev-cm.jar;..\soa\modules\oracle.soa.mgmt_11.1.1\soa-infra-mgmt.jar;..\soa\modules\oracle.soa.fabric_11.1.1\fabric-runtime.jar;%jrf_dir%\modules\oracle.fabriccommon_11.1.1\fabric-common.jar;..\soa\modules\oracle.soa.b2b_11.1.1\b2b.jar;%jrf_dir%\modules\oracle.adf.share_11.1.1\oracle-el.jar;%jrf_dir%\modules\oracle.adf.share_11.1.1\commons-el.jar;%jrf_dir%\modules\oracle.xdk_11.1.0\xml.jar;..\..\modules\javax.jms_1.1.1.jar;..\..\modules\javax.jsp_1.1.0.0_2-1.jar

REM oim dependencies
set oimdir=..\server\apps\oim.ear\APP-INF\lib

if exist %oimdir% set oimrecupg=%jrf_dir%\modules\oracle.adf.share_11.1.1\commons-el.jar;%jrf_dir%\modules\oracle.adf.share_11.1.1\oracle-el.jar;%oimdir%\iam-platform-auth-client.jar;%oimdir%\iam-platform-auth-server.jar;%oimdir%\iam-platform-context.jar;%oimdir%\iam-platform-kernel.jar;%oimdir%\xlVO.jar;%oimdir%\xlAPI.jar;%oimdir%\xlAuditor.jar;%oimdir%\xlDataObjectBeans.jar;%oimdir%\xlmap.xml;%oimdir%\xlCache.jar;%oimdir%\xlUtils.jar;%oimdir%\oscache.jar;..\server\ext\ucp.jar;%jrf_dir%\modules\oracle.adf.share.ca_11.1.1\adf-share-ca.jar;%jrf_dir%\modules\com.bea.core.apache.commons.logging_1.1.0.jar;%jrf_dir%\modules\com.oracle.ocm_1.0.0.0.jar;%jrf_dir%\jlib\share.jar
if exist %oimdir% set oimdep=%jrf_dir%\modules\oracle.adf.model_11.1.1\adfm.jar;%SOA_HOME%\soa\modules\oracle.rules_11.1.1\rulesdk2.jar;%SOA_HOME%\soa\modules\oracle.rules_11.1.1\rules.jar;%SOA_HOME%\soa\modules\oracle.soa.fabric_11.1.1\bpm-infra.jar;%SOA_HOME%\soa\modules\oracle.soa.workflow_11.1.1\bpm-services.jar;%jrf_dir%\soa\modules\commons-cli-1.1.jar;%jrf_dir%\soa\modules\oracle.soa.mgmt_11.1.1\soa-infra-mgmt.jar;%oimdir%\OIMServer.jar;%oimdir%\quartz-1.6.0.jar;%oimdir%\velocity-dep-1.4.jar;%oimdir%\velocity-tools-1.4.jar;%oimdir%\velocity-tools-generic-1.3.jar;%oimdir%\commons-logging.jar;%oimdir%\commons-dbcp-1.2.1.jar;..\server\ext\jakarta-commons\commons-pool-1.2.jar;..\server\ext\jakarta-commons\commons-collections-3.1.jar;%oimdir%\xlGenConnector.jar;%oimdir%\iam-platform-entitymgr.jar;%oimdir%\iam-platform-utils.jar;%oimdir%\spring.jar;%jrf_dir%\modules\oracle.idm_11.1.1\identityutils.jar;..\server\apps\oim.ear\iam-ejb.jar;%oimdir%\iam-platform-pluginframework.jar;%oimdir%\xlDataObjects.jar;%oimdir%\iam-platform-authz-service.jar;..\server\apps\oim.ear\admin.war\WEB-INF\lib\iam-features-identity.zip;..\server\features\iam-features-configservice.zip;..\server\features\iam-features-authzpolicydefn.zip;..\server\oes\oimpds.jar;%jrf_dir%\modules\oracle.nlsgdk_11.1.0\orai18n-service.jar;..\server\seed_data\lib\seedPolicyData.jar;..\server\seed_data\lib\seedRcuData.jar;%jrf_dir%\modules\oracle.adf.share.ca_11.1.1\adf-share-base.jar;%jrf_dir%\modules\oracle.adf.share_11.1.1\adflogginghandler.jar;%jrf_dir%\modules\oracle.ucp_11.1.0.jar;%MW_HOME%\modules\org.apache.ant_1.7.1\lib\ant.jar;%MW_HOME%\modules\org.apache.ant_1.7.1\lib\ant-launcher.jar

if exist %oimdir% set vacrulessoa=%jrf_dir%\modules\oracle.xdk_11.1.0\xml.jar;%jrf_dir%\modules\oracle.fabriccommon_11.1.1\fabric-common.jar;%jrf_dir%\modules\oracle.webservices_11.1.1\wsclient.jar;%SOA_HOME%\soa\modules\oracle.soa.fabric_11.1.1\oracle-soa-client-api.jar

set oimdep=%oimdep%;%oimrecupg%;%vacrulessoa%

REM odi dependencies
set odidir=..\oracledi.sdk\lib
set odimod=..\oracledi.sdk\modules
set odimisc=..\odi_misc
if exist %odidir% set odidep=%odimod%\oracle.jps_11.1.1\jps-api.jar;%odimod%\oracle.idm_11.1.1\identitystore.jar;%odidir%\ojdl.jar;%odimisc%\wlclient.jar;%odimisc%\dms.jar;%odimisc%\help-share.jar;%odimisc%\ohj.jar;%odimisc%\oracle_ice.jar;%odimisc%\xmlparserv2.jar;%odimisc%\orai18n-mapping.jar;%odimisc%\share.jar;%odimisc%\ojmisc.jar;%odimisc%\fmwgenerictoken.jar;%odimisc%\wlinformix.jar;%odimisc%\wlsybase.jar;%odimisc%\wldb2.jar;%odimisc%\wlsqlserver.jar;%odidir%\ant-commons-net.jar;%odidir%\bsf.jar;%odidir%\bsh-2.0b2.jar;%odidir%\commons-beanutils-1.7.0.jar;%odidir%\commons-collections-3.2.jar;%odidir%\commons-io-1.2.jar;%odidir%\commons-lang-2.2.jar;%odidir%\commons-logging-1.1.1.jar;%odidir%\eclipselink.jar;%odidir%\ess.jar;%odidir%\javolution.jar;%odidir%\odi-core.jar;%odidir%\oracle.ucp_11.1.0.jar;%odidir%\persistence.jar;%odidir%\spring-beans.jar;%odidir%\spring-context.jar;%odidir%\spring-core.jar;%odidir%\spring-dao.jar;%odidir%\spring-jdbc.jar;%odidir%\spring-jpa.jar;%odi_dir%\trove.jar;%odidir%;%odidir%\hsqldb.jar

REM ##########################################################
REM  vde.jar must be before weblogic.jar
REM  weblogic.jar must be before wlfullclient.jar
REM ##########################################################
set NEWJARS=%jrf_dir%\modules\oracle.odl_11.1.1\ojdl.jar;%jrf_dir%\modules\oracle.dms_11.1.1\dms.jar;%jrf_dir%\modules\oracle.bali.share_11.1.1\share.jar;%jrf_dir%\modules\oracle.ldap_11.1.1\ldapjclnt11.jar;;%jrf_dir%\modules\oracle.xdk_11.1.0\xmlparserv2.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-manifest.jar;%jrf_dir%\modules\oracle.iau_11.1.1\fmw_audit.jar;%jrf_dir%\modules\oracle.jmx_11.1.1\jmxframework.jar;%jrf_dir%\modules\oracle.jmx_11.1.1\jmxspi.jar;%jrf_dir%\modules\oracle.pki_11.1.1\oraclepki.jar;%jrf_dir%\modules\oracle.osdt_11.1.1\osdt_core.jar;%jrf_dir%\modules\oracle.osdt_11.1.1\osdt_cert.jar;%jrf_dir%\modules\oracle.idm_11.1.1\identitystore.jar;%jrf_dir%\modules\oracle.ldap_11.1.1\ojmisc.jar;..\..\modules\javax.management.j2ee_1.0.jar;..\upgrade\jlib\com.oracle.ws.http_client_1.1.0.0.jar;%jrf_dir%\modules\oracle.help_5.0\help-share.jar;%jrf_dir%\modules\oracle.help_5.0\ohj.jar;%jrf_dir%\modules\oracle.help_5.0\oracle_ice.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-wls.jar;..\ovd\jlib\vde.jar;%WL_HOME%\server\lib\weblogic.jar;%WL_HOME%\server\lib\consoleapp\APP-INF\lib\commons-codec-1.3.jar;%jrf_dir%\modules\oracle.osdt_11.1.1\osdt_xmlsec.jar;%jrf_dir%\modules\oracle.mds_11.1.1\mdsrt.jar;%jrf_dir%\modules\oracle.javacache_11.1.1\cache.jar;%jrf_dir%\modules\oracle.xmlef_11.1.1\xmlef.jar;%jrf_dir%\modules\oracle.jrf_11.1.1\jrf-api.jar

set bidir=..\bifoundation
if exist %bidir% set BIMBEANS=..\bifoundation\jlib\biconfigmbeans.jar;..\bifoundation\jlib\biconfigmbeans-metaobjs.jar
if exist %bidir% set ADMINMBEANS=..\bifoundation\admin\provisioning\adminservicesmbeans.jar
if exist %bidir% set BIEEMBEANS=..\bifoundation\jlib\oracle-bi-public.jar;..\bifoundation\jlib\oracle-bi-shared.jar

set CSFJARS=%jrf_dir%\modules\oracle.jps_11.1.1\jps-common.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-manifest.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-ee.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-mbeans.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jacc-spi.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-internal.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-api.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-platform.jar;%jrf_dir%\modules\oracle.jps_11.1.1\jps-unsupported-api.jar;..\bifoundation\admin\provisioning\bisecurityprovision.jar

REM ##########################################################
REM %odidep% must be before %mrplugins%
REM ##########################################################
set CLASSPATH=%BIEEMBEANS%;%ADMINMBEANS%;%BIMBEANS%;%CSFJARS%;%NEWJARS%;..\jlib\netcfg.jar;..\jlib\ua.jar;..\jlib\mrua.jar;%mtplugins%;%odidep%;%mrplugins%;%b2bdep%;%oimdep%;..\jlib\jewt4.jar;..\oui\jlib\OraInstaller.jar;..\oui\jlib\srvm.jar;..\jlib\SchemaVersion.jar;..\webservices\lib\jaxrpc-api.jar;..\assistants\opca\jlib\opca.jar;..\portal\jlib\ptlshare.jar;..\portal\jlib\portaltools.jar;..\adfp\lib\wce.jar;..\ldap\odi\jlib\sync.jar;..\ldap\odi\jlib\madintegrator.jar;..\ohs\lib\ohs.jar;..\opmn\lib\iasprovision.jar;..\opmn\lib\optic.jar;..\opmn\lib\nonj2eembeans.jar;..\opmn\lib\opmneditor.jar;..\opmn\lib\wlfullclient.jar;..\lib\java\shared\args4j\2.0.9\args4j-2.0.9.jar;..\oam\server\lib\ojmisc.jar;..\ucm\idc\jlib\idcupgrade.jar;..\clients\bipublisher\xdo-server.jar;..\clients\bipublisher\xdo-core.jar;..\clients\bipublisher\versioninfo.jar;..\clients\bipublisher\i18nAPI_v3.jar;..\common\SharedServices\11.1.2.0\lib\quartz.jar;..\clients\bipublisher\gson-1.3.jar;%OJDBC%

REM # Adding -Dbam.reuseDumpfile=true will cause BAM to upgrade skip the export
REM # of 10g data from the source database, and skip creating the dumpfile. 
REM # Instead, BAM will just do the import again, reusing the existing logfile and 
REM # running Morpheus again.  This can save many hours in error recovery cases.

"%JAVA_HOME%\bin\java.exe" %MAXPERMSIZE% -Xms512m  -Xmx512m  -Dua.home="%base_dir%" -Dua.mw.home="%MW_HOME%" -Dua.wl.home="%WL_HOME%" -Doracle.installer.oui_loc="%base_dir%\oui" -Dice.pilots.html4.ignoreNonGenericFonts=true -Dsun.java2d.noddraw=true -Dsun.lang.ClassLoader.allowArraySyntax=true oracle.ias.upgrade.UpgradeDriver %*

goto :exit

:nojavahome
echo JAVA_HOME not found. Set the JAVA_HOME environment variable and rerun.
goto :exit

:nojrf
echo Location of Java Required Files (JRF) not found.

:exit
