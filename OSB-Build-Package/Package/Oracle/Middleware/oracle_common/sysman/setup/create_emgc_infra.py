#
# $Header: create_emgc_infra.py 08-jun-2008.23:55:07 smodh Exp $
#
# Copyright (c) 2004, 2008, Oracle. All rights reserved.  
#
#    NAME
#      create_emgc_infra.py
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    smodh      06/08/08 - Bug 7161732
#    smodh      04/18/08 - Modify AdminServer Memory
#    arunkri    04/06/08 - New exception format for setup check
#    jashukla   04/04/08 - 
#    smodh      03/24/08 - Bug 6902500
#    smodh      03/12/08 - add exit codes
#    arunkri    03/11/08 - Set duf ports if defined
#    smodh      02/15/08 - Move the setup_emgc_instance.py to create_emgc_infra & setup_emgc_infra.py
#    cvaishna   01/31/08 - Bug fix : 6791361
#    arunkri    01/21/08  - Add joclocal and jocremote ports
#    cvaishna   01/20/08 - Fixing addPortRange command
#    pchebrol   01/18/08  - Bug 6755586
#    ramalhot   01/17/08 - added couples of new jave parameter to avoid java GC
#    gfinklan   01/14/08 - Move adf-config
#    kvsingh    01/10/08 -  agent_download url fix
#    pchebrol   01/07/08 - Grant perms to oc4j_em/application/em/em/WEB-INF/lib/emCORE.jar
#                          as OC4J is loading this rather than the one in OH
#    dgiaimo    12/20/07 - Adding proxy credential information to java2.policy
#                          file.
#    arunkri    12/11/07 - Set OC4J ports from triage.
#    smodh      12/05/07 - Bugs 6636342, 6653837
#    joyoon     11/29/07 - 
#    jashukla   11/19/07 - 
#    dgiaimo    11/05/07 - Prompting for MAS password
#    rpinnama   10/30/07 - Add modifications to java2.policy required for using Credstore API
#    jashukla   09/19/07 - Use port range for oc4j
#    ramalhot   09/17/07 - added mds registration
#    smodh      09/07/07 - Bug 6405491, Bug 6236370 - Use setProcessStartParams()
#    jashukla   08/15/07 - 
#    gfinklan   08/09/07 - add removal of custrestr
#    lyang      07/30/07 - 
#    jashukla   06/12/07 - 
#    ramalhot   07/03/07 - set apache ports
#    lyang      04/23/07 - Change oc4jadmin password
#    lyang      04/23/07 - applied workaround for php5_module
#    lyang      04/19/07 - Use /j2ee/home/lib/oc4j-unsupported-api.jar
#    arunkri    04/03/07 - 
#    jashukla   03/19/07 - Remove ascontrol.ear from server.xml
#    jashukla   03/19/07 - 
#    arunkri    02/21/07 - Change instance detection logic
#    jashukla   02/22/07 - 
#    arunkri    02/14/07 - Add httpd_em.conf as hardcoded string
#    mbhoopat   03/01/07 - JSF 1.2 changes
#    arunkri    01/25/07 - Creation
#

# This script creates MAS Infrastructure for EM
import sys
import os
import java.util.Date as Date
import java.lang.System as System
import java.io.File as File
from java.lang import String
from java.io import PrintStream
from java.io import ByteArrayOutputStream
import getopt
import re

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

OHS_COMPONENT_TYPE = 'OHSComponent'
OC4J_COMPONENT_TYPE = 'OC4JComponent'
INSTANCE_NAME = 'instance_em'
OC4J_NAME = 'oc4j_em'
OHS_NAME = 'ohs_em'
OC4J_OHS_ROUTING_REL_NAME = 'em_rr'
EM_UPLOAD_DENY = 'none'
MAS_EXISTS='TRUE'
MULTI_OMS='FALSE'
CONNECTION_NAME = 'em'
oracle.sysman.install.mas_jocremote_port=''
oracle.sysman.install.mas_joclocal_port=''
oracle.sysman.install.mas_duf_port1=''
oracle.sysman.install.mas_duf_port2=''
MAS_JOCREMOTE_PORT=''
MAS_JOCLOCAL_PORT=''
MAS_DUF_PORT1=''
MAS_DUF_PORT2=''

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
   System.out.println('    asctl script setup_em_infra.py <options>')
   System.out.println('options:')
   System.out.println('    --configfile  Configuration file')
   System.out.println('    --outfile     Output file from setup_em_infra.py')
   System.out.println('    --cmdlog      File where output of each command will be stored')


def printMsg(message):
   sys.stderr.write(message + "\n")


def logTime(msg):
   a = Date()
   print a
   print msg

def writeToLog(string):
   fileHandle = open (outfile, 'a')
   fileHandle.write(string+'\n')
   fileHandle.close()

def writeToConfig(string):
   fileHandle = open (configfile, 'a')
   fileHandle.write(string+'\n')
   fileHandle.close()

#########################################
## Functions to setup em infra
#########################################
def init():
    #Reset exceptions
    lastException()
    logTime( "Starting EM MAS Infrastructure Creation")
    f = cmdlog
    startRecording(file=f)

def over():
    logTime( "End of EM MAS Infrastructure Creation")
    stopRecording()

def log_general():
    writeToLog('oracle.sysman.install.em_instance_name='+INSTANCE_NAME)
    writeToLog('oracle.sysman.install.em_instance_home='+INSTANCE_HOME)
    writeToLog('oracle.sysman.install.farm_name='+FARM_NAME)
    writeToConfig('oracle.sysman.install.em_instance_name = \''+INSTANCE_NAME+'\'')
    writeToConfig('oracle.sysman.install.mas_exists = \''+MAS_EXISTS+'\'')
    writeToConfig('oracle.sysman.install.oc4j_ohs_routing_rel_name = \''+OC4J_OHS_ROUTING_REL_NAME+'\'')

def log_all_info():
    log_general()

def check_instance_exists(instname):
    origStdOut = System.out
    byteArrayStream = ByteArrayOutputStream()
    System.setOut(PrintStream(byteArrayStream))
    ls(tn='/'+FARM_NAME,l=1)
    # restore stdout
    System.setOut(origStdOut)
    resultString = byteArrayStream.toString()
    resultString = resultString.replace('\n', '')
    #print resultString
    p1= re.compile('^.*?'+instname+'\s*?\|ASInstance\s*?(.*$)', re.DOTALL)
    m=p1.match(resultString)
    if m:
        print "Instance Exists"
        return 1
    else:
        print "Instance does not exist"
        return 0

def set_vars():
    logTime( "Setting variables")
    global FARM_NAME
    global MAS_ADMIN_USERNAME
    global MAS_ADMIN_PASSWORD
    global MAS_JMX_PORT
    global MAS_JOCLOCAL_PORT
    global MAS_JOCREMOTE_PORT
    global MAS_DUF_PORT1
    global MAS_DUF_PORT2
    global ORACLE_HOME
    global MAS_HOSTNAME
    global INSTANCE_DIR
    global INSTANCE_NAME
    global INSTANCE_HOME
    global MAS_CONN_URL
    global OC4J_OHS_ROUTING_REL_NAME
    global MAS_EXISTS
    global MULTI_OMS
    global TMP_DIR

    #First map the oracle.sysman.install variables to local names.
    FARM_NAME=oracle.sysman.install.farm_name
    MAS_JMX_PORT=oracle.sysman.install.mas_jmx_port
    if(oracle.sysman.install.mas_jocremote_port != ''):
      MAS_JOCREMOTE_PORT=oracle.sysman.install.mas_jocremote_port
    if(oracle.sysman.install.mas_joclocal_port != ''):
      MAS_JOCLOCAL_PORT=oracle.sysman.install.mas_joclocal_port
    if(oracle.sysman.install.mas_duf_port1 != ''):
      MAS_DUF_PORT1=oracle.sysman.install.mas_duf_port1
    if(oracle.sysman.install.mas_duf_port2 != ''):
      MAS_DUF_PORT2=oracle.sysman.install.mas_duf_port2
    ORACLE_HOME=oracle.sysman.install.oracle_home
    MAS_HOSTNAME=oracle.sysman.install.mas_host_name
    INSTANCE_DIR=oracle.sysman.install.em_instance_dir
    MAS_EXISTS=oracle.sysman.install.mas_exists
    TMP_DIR=oracle.sysman.install.temp_dir
    MULTI_OMS='FALSE'

    System.out.print("MAS Username: ")
    MAS_ADMIN_USERNAME = sys.stdin.readline()
    MAS_ADMIN_USERNAME = MAS_ADMIN_USERNAME.strip()
    MAS_ADMIN_PASSWORD = str(String((Password.readPassword("MAS Password: ")).getPassword()))

    MAS_CONN_URL = MAS_HOSTNAME+':'+str(MAS_JMX_PORT)
    if(MAS_EXISTS == 'TRUE'):
        index = 0
        inst_exists = 1
        inst_name = ''
        ext = ''
        f = cmdlog
        startRecording(file=f)
        connect_mas()
        stopRecording()
        while(inst_exists == 1):
            index = index+1
            inst_name = INSTANCE_NAME+ext
            inst_exists = check_instance_exists(inst_name)
            if(inst_exists == 1):
                ext = '_'+str(index)
                MULTI_OMS='TRUE'
            else:
                break

        INSTANCE_NAME = inst_name
        INSTANCE_HOME = INSTANCE_DIR+'/'+INSTANCE_NAME
        OC4J_OHS_ROUTING_REL_NAME = OC4J_OHS_ROUTING_REL_NAME+ext
        disconnect()
    else:
        INSTANCE_HOME = INSTANCE_DIR+'/'+INSTANCE_NAME
    logTime( "Setting variables done")

def create_instance():
    logTime( "Creating AS Instance")
    createInstance(name=INSTANCE_NAME, oracleinstance=INSTANCE_HOME)
    logTime( "AS Instance created")

def start_instance():
   logTime( "Starting AS Instance")
   startInstance(oracleinstance=INSTANCE_HOME, sp='-Xmx200m')
   logTime( "AS Instance started")

def create_mas_instance():
   logTime( "Creating EM MAS Instance: createMASInstance")
   fname = ORACLE_HOME + File.separator + "adminserver" + File.separator + "admin" + File.separator + "server" + File.separator + "templates" + File.separator + "default" + File.separator + "pcscomponent.xml"
   os.system("chmod 777 "+fname)
   modify_adminserver_memory(fname)
   os.system("chmod 555 "+fname)
   manageCommandWallet(set="true",location=TMP_DIR+"/"+FARM_NAME+".wallet", name="oracle.mas.admin.password", user=MAS_ADMIN_USERNAME)
   jmx_port=int(MAS_JMX_PORT);
   stopRecording()
   if((MAS_JOCLOCAL_PORT != '') and (MAS_JOCREMOTE_PORT != '')):
     joclocal_port=int(MAS_JOCLOCAL_PORT)
     jocremote_port=int(MAS_JOCREMOTE_PORT)
     createMASInstance(instance=INSTANCE_NAME, farm=FARM_NAME, oracleinstance=INSTANCE_HOME, jmxport=jmx_port, jocRemotePort=jocremote_port, jocLocalPort=joclocal_port, user=MAS_ADMIN_USERNAME, password=MAS_ADMIN_PASSWORD);
   else:
     createMASInstance(instance=INSTANCE_NAME, farm=FARM_NAME, oracleinstance=INSTANCE_HOME, jmxport=jmx_port, user=MAS_ADMIN_USERNAME,password=MAS_ADMIN_PASSWORD);
   f = cmdlog
   startRecording(file=f)
   logTime( "EM MAS Instance created")

def start_mas():
   logTime( "Starting EM MAS Instance")
   startInstance(oracleinstance=INSTANCE_HOME, sp='-Xmx200m', masonly="true")
   logTime( "EM MAS Instance started")

def connect_mas():
    logTime("Connect to MAS. Stop Recording Temporarily.")
    stopRecording()
    connect(user=MAS_ADMIN_USERNAME, password=MAS_ADMIN_PASSWORD, connURL=MAS_CONN_URL)
    f = cmdlog
    startRecording(file=f)
    logTime("Connect to MAS done. Start Recording Again.")

def create_ohs():
    logTime("Creating ohs_em")
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    startTxn()
    createComponent(type=OHS_COMPONENT_TYPE, name=OHS_NAME)
    commitTxn()
    logTime("Create ohs_em complete")

def create_oc4j():
    logTime("Creating oc4j_em")
    fn = ORACLE_HOME + File.separator + "j2ee"+ File.separator + "home" + File.separator + "template" + File.separator + "server.xml"
    editServerXml(fn)
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    startTxn()
    createComponent(type=OC4J_COMPONENT_TYPE, name=OC4J_NAME)
    commitTxn()
    logTime("Creating oc4j_em done")

def editServerXml(infile):
    print "In editServerXml"
    input = open(infile, 'r')
    fullline = input.read()
    input.close()

    p1 = re.compile(r'(.*?)(<application name="ascontrol".*?ascontrol.ear.*?/>)(.*)', re.DOTALL)
    m = p1.match(fullline)
    if m:
        print "Ignoring ascontrol.ear line"
        write_file=open(infile,'w')
        outline = m.group(1)+m.group(3)
        write_file.write(outline)
        write_file.close()
    else:
        print "ascontrol.ear not found"

def modify_adminserver_memory(fn):
    logTime("Modifying AdminServer's memory")
    input = open(fn, 'r')
    fullline = input.read()
    input.close()

    p1 = re.compile( 'Xmx1000m' , re.DOTALL)
    if p1.search(fullline):
        fullline = p1.sub('Xmx512m', fullline)
        write_file=open(fn,'w')
        write_file.write(fullline)
        write_file.close()

    logTime("Modifying AdminServer's memory Done")


def register_mds():
    logTime("Registering MDS")
    startTxn()
    registerMetadataFileRepository(name=CONNECTION_NAME, location=INSTANCE_HOME + "/dps")
    commitTxn()
    logTime("Registering MDS done")

# MAS uses hardcoded duf ports with out checking for port conflicts.
# This is a hack to avaoid that till dynamic port allocation for duf
# ports is available in MAS.
def setup_duf_ports():
    logTime("Setting up DUF ports")
    if((MAS_DUF_PORT1 != '') and (MAS_DUF_PORT2 != '')):
      os.mkdir(INSTANCE_HOME+"/config/duf");
      outfile=INSTANCE_HOME+"/config/duf/duf.conf"
      write_file=open(outfile,'w')
      outline1="port="+MAS_DUF_PORT1+"\n"
      outline2="bdc_port="+MAS_DUF_PORT2+"\n"
      write_file.write(outline1)
      write_file.write(outline2)
      write_file.close()
    logTime("Setting up DUF ports done")

def setup():
    #Check for MAS instance existence and create if not.
    if(MAS_EXISTS == 'TRUE' or MULTI_OMS == 'TRUE'):
        connect_mas()
        create_instance()
        start_instance()
    else:
        create_mas_instance()
        setup_duf_ports()
        start_mas()
        connect_mas()
        register_mds()
    
    create_ohs()
    create_oc4j()
    status()

try:
    getOptions()
    execfile(configfile)
    set_vars()
    init()
    setup()
    log_all_info()
    over()
except :
    # collect the exception
    (c, i, tb) =  sys.exc_info()
    printMsg("!!!Got Exception: during create_emgc_infra.py")
    printMsg('Name of Exception: '+str(c))
    printMsg('Code of Exception: '+str(i))
    printMsg(str(tb))
    sys.exit(1)
    #collectException();

