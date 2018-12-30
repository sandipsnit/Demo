#
# $Header: setup_emgc_infra_fresh.py 16-apr-2008.23:38:53 ramalhot Exp $
#
# Copyright (c) 2004, 2008, Oracle. All rights reserved.  
#
#    NAME
#      setup_emgc_infra_fresh.py
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    ramalhot    04/16/08 - 
#    arunkri     04/06/08 - New exception format for setup check
#    jashukla    04/01/08 - Bug 6917474
#    smodh       03/25/08 - Bug 6911837
#    smodh       03/12/08 - add exit codes
#    smodh       02/15/08 - Creation
#

# This script sets up MAS for EM
import sys
import os
import java.util.Date as Date
import java.lang.System as System
import java.io.File as File
import java.lang.Runtime as Runtime
import java.lang.Process as Process
from java.lang import String
from java.io import PrintStream
from java.io import ByteArrayOutputStream
import getopt
import re

# Needed for getRdsPort
rdsscript = oracleHome.getCanonicalPath() + '/scripts/rdsconfig.py'
execfile(rdsscript)

# Needed for oracle.sysman.emctl.util.passwd.Password class
EMAGENT_SDK_JAR = System.getenv('ORACLE_HOME') + '/sysman/jlib/emagentSDK.jar'
sys.path.append(EMAGENT_SDK_JAR)
addClassPath(EMAGENT_SDK_JAR)

from oracle.sysman.emctl.util.passwd import Password

#These classes are dummy classes defined to get the namespace oracle.sysman.install
#Input variables from include file will be in this format
class oracle:
  class sysman:
    class install:
      tmp=0

##
## Common variables.
##

INSTANCE_NAME = 'instance_em'
OC4J_NAME = 'oc4j_em'
OHS_NAME = 'ohs_em'
OC4J_OHS_ROUTING_REL_NAME = 'em_rr'
EM_UPLOAD_DENY = 'none'
MAS_EXISTS='TRUE'
oracle.sysman.install.oc4j_default_web_site_port=''
oracle.sysman.install.oc4j_http_web_site_port=''
oracle.sysman.install.oc4j_rmi_port=''
oracle.sysman.install.oc4j_rmis_port=''
oracle.sysman.install.oc4j_jms_port=''
oracle.sysman.install.oc4j_cluster_port=''
oracle.sysman.install.oc4j_iiop_port=''
oracle.sysman.install.oc4j_iiops_port=''
oracle.sysman.install.oc4j_iiops_mutual_auth_port=''
oracle.sysman.install.http_dms_port=''
EM_OC4J_DEF_WEB_SITE_PORT_START=6500
EM_OC4J_DEF_WEB_SITE_PORT_END=8500
EM_OC4J_HTTP_WEB_SITE_PORT_START=6500
EM_OC4J_HTTP_WEB_SITE_PORT_END=8500
EM_RMI_PORT_START=6500
EM_RMI_PORT_END=8500
EM_OC4J_RMIS_PORT_START=6500
EM_OC4J_RMIS_PORT_END=8500
EM_JMS_PORT_START=6500
EM_JMS_PORT_END=8500
EM_OC4J_CLUSTER_PORT_START=6500
EM_OC4J_CLUSTER_PORT_END=8500
EM_OC4J_IIOP_PORT_START=6500
EM_OC4J_IIOP_PORT_END=8500
EM_OC4J_IIOPS_PORT_START=6500
EM_OC4J_IIOPS_PORT_END=8500
EM_OC4J_IIOPS_MUT_AUTH_PORT_START=6500
EM_OC4J_IIOPS_MUT_AUTH_PORT_END=8500
EM_HTTP_DMS_PORT_START=6500
EM_HTTP_DMS_PORT_END=8500

configfile = ""
outfile    = ""
cmdlog     = ""

##############################
## Generic functions
#############################

def getOptions():
    global argv
    global configfile
    global outfile
    global cmdlog

    opts = sys.argv[1:]
    a = len(opts)
    index = 0

    if(a == index):
        usage()
        sys.exit(1)

    while index <= a-1:
        opt = opts[index]
        if opt in ("--configfile", "-configfile"):
            configfile = opts[index+1]
            index = index+2
        elif opt in ("--cmdlog", "-cmdlog"):
            cmdlog = opts[index+1]
            index = index+2
        elif opt in ("--outfile", "-outfile"):
            outfile = opts[index+1]
            index = index+2
        else:
            usage()
            sys.exit(1)


def usage():
   System.out.println('############################################')
   System.out.println('#               USAGE                      #')
   System.out.println('############################################')
   System.out.println('usage: ')
   System.out.println('    asctl script setup_emgc_infra_fresh.py <options>')
   System.out.println('options:')
   System.out.println('    --configfile  Configuration file')
   System.out.println('    --outfile     Output file from setup_emgc_infra_fresh.py')
   System.out.println('    --cmdlog      File where output of each command will be stored')


def writeToLog(string):
   fileHandle = open (outfile, 'a')
   fileHandle.write(string+'\n')
   fileHandle.close()

##############################################
## Functions to setup em fresh infrastructure
##############################################

def init():
    #Reset exceptions
    lastException()
    logTime( "Starting EM MAS Infra Setup")
    f = cmdlog
    startRecording(file=f)

def over():
    logTime( "End of EM MAS Infra Setup")
    stopRecording()

def log_general():
    writeToLog('oracle.sysman.install.em_instance_name='+INSTANCE_NAME)
    writeToLog('oracle.sysman.install.em_instance_home='+INSTANCE_HOME)
    writeToLog('oracle.sysman.install.farm_name='+FARM_NAME)
    writeToLog('oracle.sysman.install.mas_exists='+MAS_EXISTS)

def log_oc4j_ports(compname):
    rmiport=getPort("/"+FARM_NAME+"/"+INSTANCE_NAME+"/"+compname+"/rmi")
    if rmiport != None:
        writeToLog('oracle.sysman.install.oc4j_rmi_port='+rmiport)
    else:
        raise "Could not get "+compname+" ports. "+compname+" may not be up"

def log_all_info():
    log_general()
    log_oc4j_ports(OC4J_NAME)
    #log_ohs_ports(OHS_NAME)


def set_vars():
    a = Date()
    print a
    print "Setting Variables"
    global FARM_NAME
    global MAS_ADMIN_USERNAME
    global MAS_ADMIN_PASSWORD
    global MAS_JMX_PORT
    global TMP_DIR
    global ORACLE_HOME
    global OC4J_OPTS
    global UPLOAD_HTTP_PORT
    global UPLOAD_HTTPS_PORT
    global CONSOLE_HTTP_PORT
    global CONSOLE_HTTPS_PORT
    global MAS_HOSTNAME
    global HTTP_SERVER_TIMEOUT
    global INSTANCE_DIR
    global INSTANCE_NAME
    global INSTANCE_HOME
    global MAS_CONN_URL
    global OC4J_OHS_ROUTING_REL_NAME
    global MAS_EXISTS
    global DEV_MODE
    global PDS_MODE
    global EM_OC4J_DEF_WEB_SITE_PORT_START
    global EM_OC4J_DEF_WEB_SITE_PORT_END
    global EM_OC4J_HTTP_WEB_SITE_PORT_START
    global EM_OC4J_HTTP_WEB_SITE_PORT_END
    global EM_RMI_PORT_START
    global EM_RMI_PORT_END
    global EM_OC4J_RMIS_PORT_START
    global EM_OC4J_RMIS_PORT_END
    global EM_JMS_PORT_START
    global EM_JMS_PORT_END
    global EM_OC4J_CLUSTER_PORT_START
    global EM_OC4J_CLUSTER_PORT_END
    global EM_OC4J_IIOP_PORT_START
    global EM_OC4J_IIOP_PORT_END
    global EM_OC4J_IIOPS_PORT_START
    global EM_OC4J_IIOPS_PORT_END
    global EM_OC4J_IIOPS_MUT_AUTH_PORT_START
    global EM_OC4J_IIOPS_MUT_AUTH_PORT_END
    global EM_HTTP_DMS_PORT_START
    global EM_HTTP_DMS_PORT_END

    #First map the oracle.sysman.install variables to local names.
    FARM_NAME=oracle.sysman.install.farm_name
    MAS_JMX_PORT=oracle.sysman.install.mas_jmx_port
    TMP_DIR=oracle.sysman.install.temp_dir
    ORACLE_HOME=oracle.sysman.install.oracle_home
    OC4J_OPTS=oracle.sysman.install.oc4j_opts
    UPLOAD_HTTP_PORT=oracle.sysman.install.http_upload_port
    UPLOAD_HTTPS_PORT=oracle.sysman.install.https_upload_port
    CONSOLE_HTTP_PORT=oracle.sysman.install.http_console_port
    CONSOLE_HTTPS_PORT=oracle.sysman.install.https_console_port
    MAS_HOSTNAME=oracle.sysman.install.mas_host_name
    HTTP_SERVER_TIMEOUT=oracle.sysman.install.http_server_timeout
    INSTANCE_NAME=oracle.sysman.install.em_instance_name
    INSTANCE_DIR=oracle.sysman.install.em_instance_dir
    MAS_EXISTS=oracle.sysman.install.mas_exists
    DEV_MODE=oracle.sysman.install.dev_mode
    PDS_MODE=oracle.sysman.install.pds_mode
    OC4J_OHS_ROUTING_REL_NAME=oracle.sysman.install.oc4j_ohs_routing_rel_name
    if(oracle.sysman.install.oc4j_default_web_site_port != ''):
      EM_OC4J_DEF_WEB_SITE_PORT_START=EM_OC4J_DEF_WEB_SITE_PORT_END=oracle.sysman.install.oc4j_default_web_site_port
    if(oracle.sysman.install.oc4j_http_web_site_port != ''):
      EM_OC4J_HTTP_WEB_SITE_PORT_START=EM_OC4J_HTTP_WEB_SITE_PORT_END=oracle.sysman.install.oc4j_http_web_site_port
    if(oracle.sysman.install.oc4j_rmi_port != ''):
      EM_RMI_PORT_START=EM_RMI_PORT_END=oracle.sysman.install.oc4j_rmi_port
    if(oracle.sysman.install.oc4j_rmis_port != ''):
      EM_OC4J_RMIS_PORT_START=EM_OC4J_RMIS_PORT_END=oracle.sysman.install.oc4j_rmis_port
    if(oracle.sysman.install.oc4j_jms_port != ''):
      EM_JMS_PORT_START=EM_JMS_PORT_END=oracle.sysman.install.oc4j_jms_port
    if(oracle.sysman.install.oc4j_cluster_port != ''):
      EM_OC4J_CLUSTER_PORT_START=EM_OC4J_CLUSTER_PORT_END=oracle.sysman.install.oc4j_cluster_port
    if(oracle.sysman.install.oc4j_iiop_port != ''):
      EM_OC4J_IIOP_PORT_START=EM_OC4J_IIOP_PORT_END=oracle.sysman.install.oc4j_iiop_port
    if(oracle.sysman.install.oc4j_iiops_port != ''):
      EM_OC4J_IIOPS_PORT_START=EM_OC4J_IIOPS_PORT_END=oracle.sysman.install.oc4j_iiops_port
    if(oracle.sysman.install.oc4j_iiops_mutual_auth_port != ''):
      EM_OC4J_IIOPS_MUT_AUTH_PORT_START=EM_OC4J_IIOPS_MUT_AUTH_PORT_END=oracle.sysman.install.oc4j_iiops_mutual_auth_port
    if(oracle.sysman.install.http_dms_port != ''):
      EM_HTTP_DMS_PORT_START=EM_HTTP_DMS_PORT_END=oracle.sysman.install.http_dms_port
    System.out.print("MAS Username: ")
    MAS_ADMIN_USERNAME = sys.stdin.readline()
    MAS_ADMIN_USERNAME = MAS_ADMIN_USERNAME.strip()
    MAS_ADMIN_PASSWORD = str(String((Password.readPassword("MAS Password: ")).getPassword()))

    MAS_CONN_URL = MAS_HOSTNAME+':'+str(MAS_JMX_PORT)
    INSTANCE_HOME = INSTANCE_DIR+'/'+INSTANCE_NAME

    a = Date()
    print a
    print "Setting Variables done"

def connect_mas():
    logTime("Connect to MAS. Stop Recording Temporarily.")
    stopRecording()
    connect(user=MAS_ADMIN_USERNAME, password=MAS_ADMIN_PASSWORD, connURL=MAS_CONN_URL)
    f = cmdlog
    startRecording(file=f)
    logTime("Connect to MAS done. Start Recording Again.")


def setup():
    connect_mas()
    # Setup oc4j & ohs for EM.
    change_port_ranges_for_oc4j()
    setup_oc4j()
    add_shared_library()
    setup_ohs()
    setup_routing()
    if(PDS_MODE == 'TRUE'):
      start_ohs()
      start_oc4j()

    status()

try:
    getOptions()
    execfile(configfile)
    set_vars()
    execfile(ORACLE_HOME+'/sysman/setup/setup_emgc_infra_common.py')
    init()
    setup()
    log_all_info()
    over()
except :
    # collect the exception
    (c, i, tb) =  sys.exc_info()
    sys.stderr.write("!!!Got Exception: \n")
    sys.stderr.write("Name of Exception: "+str(c)+"\n")
    sys.stderr.write("Code of Exception: "+str(i)+"\n")
    sys.stderr.write(str(tb)+"\n")
    sys.exit(1)
    #collectException();

