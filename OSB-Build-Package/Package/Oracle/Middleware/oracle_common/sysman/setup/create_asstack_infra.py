#
# $Header: create_asstack_infra.py 08-jun-2008.23:55:07 smodh Exp $
#
# Copyright (c) 2004, 2008, Oracle. All rights reserved.  
#
#    NAME
#      create_asstack_infra.py
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    smodh       06/08/08 - Bug 7161732
#    smodh       04/23/08 - 
#    ramalhot    04/17/08 - 
#    smodh       04/18/08 - Modify AdminServer Memory
#    arunkri     04/06/08 - New exception format for setup check
#    smodh       04/03/08 - bug 6940376
#    jashukla    04/01/08 - Bug 6917474
#    smodh       03/24/08 - Bug 6902500
#    arunkri     03/12/08 - Add duf port setting
#    smodh       03/12/08 - add exit codes
#    smodh       02/27/08 - Creation
#

# This script creates AS Stack Infrastructure for EM
import sys
import os
import java.util.Date as Date
import java.lang.System as System
import java.io.File as File
from java.lang import String
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
INSTANCE_NAME = 'instance_mas'
OC4J_NAME = 'oc4j_admin'
OHS_NAME = 'ohs_em'
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
   System.out.println('    asctl script create_asstack_infra.py <options>')
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

def getStatusUsingStObj(status_obj, compname):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer
  st = status_obj.get('statusList')
  s1 = st[0].get('processState')
  return s1


#########################################
## Functions to setup em infra
#########################################
def init():
    #Reset exceptions
    lastException()
    logTime( "Starting EM MAS (ASStack) Infrastructure Creation")
    f = cmdlog
    startRecording(file=f)

def over():
    logTime( "End of EM MAS (ASStack) Infrastructure Creation")
    stopRecording()

def log_general():
    #writeToLog('oracle.sysman.install.em_instance_name='+INSTANCE_NAME)
    #writeToLog('oracle.sysman.install.em_instance_home='+INSTANCE_HOME)
    writeToLog('oracle.sysman.install.farm_name='+FARM_NAME)
    #writeToConfig('oracle.sysman.install.em_instance_name = \''+INSTANCE_NAME+'\'')

def log_all_info():
    log_general()

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
    global DEV_MODE
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
    DEV_MODE=oracle.sysman.install.dev_mode
    TMP_DIR=oracle.sysman.install.temp_dir
    System.out.print("MAS Username: ")
    MAS_ADMIN_USERNAME = sys.stdin.readline()
    MAS_ADMIN_USERNAME = MAS_ADMIN_USERNAME.strip()
    MAS_ADMIN_PASSWORD = str(String((Password.readPassword("MAS Password: ")).getPassword()))

    MAS_CONN_URL = MAS_HOSTNAME+':'+str(MAS_JMX_PORT)
    INSTANCE_HOME = INSTANCE_DIR+'/'+INSTANCE_NAME
    logTime( "Setting variables done")

def create_instance():
    logTime( "Creating AS Instance")
    createInstance(name=INSTANCE_NAME, instance=INSTANCE_NAME, oracleinstance=INSTANCE_HOME)
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
     createMASInstance(instance=INSTANCE_NAME, farm=FARM_NAME, oracleinstance=INSTANCE_HOME, jmxport=jmx_port, jocRemotePort=jocremote_port, jocLocalPort=joclocal_port, user=MAS_ADMIN_USERNAME,password=MAS_ADMIN_PASSWORD);
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
    logTime("Creating oc4j_admin")
    fn = ORACLE_HOME + File.separator + "j2ee"+ File.separator + "home" + File.separator + "template" + File.separator + "server.xml"
    editServerXml(fn)
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    startTxn()
    createComponent(type=OC4J_COMPONENT_TYPE, name=OC4J_NAME)
    commitTxn()
    logTime("Creating oc4j_admin done")

def setup_oc4j():
    logTime("Setting up oc4j_admin")
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OC4J_NAME)
    change_java_opts()
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    logTime("Setting up oc4j_admin done")

def change_java_opts():
    logTime("Changing Start Params for oc4j_admin")

    startParamsObj = getStartParams()
    resultString = startParamsObj.get('java-options')
    if resultString == "":
        raise "Could not set Java options for OC4J."
    else:
        resultString = resultString.replace('\n', '')

        oldJavaOptions = resultString
        logTime("Older Java Options are : " + oldJavaOptions)
        oldJavaOptions_1 = oldJavaOptions.replace('-mx1024M',' ').replace('-XX:MaxPermSize=128m',' ')
        startTxn()
        setStartParams(javaOptions=oldJavaOptions_1+' -Xmx256M -XX:MaxPermSize=128m ');
        commitTxn()

    logTime("Changing Start Params for oc4j_admin done")

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

def register_mds():
    logTime("Registering MDS")
    startTxn()
    registerMetadataFileRepository(name=CONNECTION_NAME, location=INSTANCE_HOME + "/dps")
    commitTxn()
    logTime("Registering MDS done")

def start_oc4j():
    logTime("Starting oc4j_admin")
    stobj = start("/"+FARM_NAME+"/"+ INSTANCE_NAME+"/"+ OC4J_NAME)
    st = getStatusUsingStObj(stobj, OC4J_NAME)
    if st != "ALIVE":
       raise "Start of "+OC4J_NAME+" failed"
  
    logTime("Starting oc4j_admin done") 

def runcmd(cmd):
    printMsg("Launching "+cmd)
    os.system(cmd)

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
    create_mas_instance()
    setup_duf_ports()
    start_mas()
    connect_mas()
    create_oc4j()
    setup_oc4j()
    register_mds()
    
    if(DEV_MODE == 'TRUE'):
        create_ohs()
    else:
        start_oc4j()

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
    printMsg("!!!Got Exception: during create_asstack_infra.py")
    printMsg('Name of Exception: '+str(c))
    printMsg('Code of Exception: '+str(i))
    printMsg(str(tb))
    sys.exit(1)
    #collectException();

