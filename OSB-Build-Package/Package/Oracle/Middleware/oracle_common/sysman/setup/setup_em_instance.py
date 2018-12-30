import sys
import re
import time
import java.util.Date as Date
import java.lang.System as System
import java.io.File as File
from java.io import PrintStream
from java.io import ByteArrayOutputStream
from java.lang import String

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

CONNECTION_NAME = 'em'

configfile = ""
cmdlog     = ""

##############################
## Generic functions
#############################

def getOptions():
    global argv
    global configfile
    global cmdlog
    global outfile

    opts = sys.argv[1:]
    a = len(opts)
    index = 0

    if(a == index):
        usage()
        sys.exit(0)

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
            sys.exit(0)


def usage():
   System.out.println('############################################')
   System.out.println('#               USAGE                      #')
   System.out.println('############################################')
   System.out.println('usage: ')
   System.out.println('    asctl script setup_em_instance.py <options>')
   System.out.println('options:')
   System.out.println('    --configfile  Configuration file')
   System.out.println('    --outfile     Output file from setup_em_instance.py')
   System.out.println('    --cmdlog      File where output of each command will be stored')

#
# Uses asctl getRdsPort() to figure out the port value of the given endpoint
# (fully specified path)  Returns the first port output by asctl.
#
def getPort(endpoint_path):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer

  endport=getRdsPort(endpoint_path)
  endport=endport.lstrip()
  endport=endport.rstrip()
  if endport != None:
     return endport
  else:
     raise "Error: Parsing port"
  return ""

def printMsg(message):
   sys.stderr.write(message + "\n")

def logTime(msg):
   a = Date()
   print a
   print msg

def set_vars():
    global MAS_ADMIN_USERNAME
    global MAS_ADMIN_PASSWORD
    global MAS_JMX_PORT
    global MAS_HOSTNAME
    global MAS_INSTANCE_HOME
    global MAS_CONN_URL
    global MAS_FARM_NAME
    global MAS_INSTANCE_NAME
    global MAS_OC4J_NAME
    global TEMP_DIR
    global ORACLE_HOME

    #First map the oracle.sysman.install variables to local names.
    MAS_JMX_PORT=oracle.sysman.install.mas_jmx_port
    MAS_HOSTNAME=oracle.sysman.install.mas_host_name
    MAS_INSTANCE_HOME=oracle.sysman.install.mas_instance_home
    MAS_FARM_NAME=oracle.sysman.install.farm_name
    MAS_INSTANCE_NAME=oracle.sysman.install.mas_instance_name
    MAS_OC4J_NAME=oracle.sysman.install.admin_oc4j_name
    TEMP_DIR=oracle.sysman.install.temp_dir
    ORACLE_HOME=oracle.sysman.install.oracle_home

    System.out.print("MAS Username: ")
    MAS_ADMIN_USERNAME = sys.stdin.readline()
    MAS_ADMIN_USERNAME = MAS_ADMIN_USERNAME.strip()
    MAS_ADMIN_PASSWORD = str(String((Password.readPassword("MAS Password: ")).getPassword()))

    MAS_CONN_URL = MAS_HOSTNAME+':'+str(MAS_JMX_PORT)



def init():
    #Reset exceptions
    lastException()
    logTime( "Starting EM MAS Setup")
    f = cmdlog
    startRecording(file=f)

def over():
    logTime( "End of EM MAS Setup")
    stopRecording()


def connect_mas():
    logTime("Connect to MAS")
    connect(user=MAS_ADMIN_USERNAME, password=MAS_ADMIN_PASSWORD, connURL=MAS_CONN_URL)
    logTime("Connect to MAS done")

def register_metadata_file_repos():
    logTime("Register Metadata File Repository")
    startTxn()
    registerMetadataFileRepository(name=CONNECTION_NAME, location=MAS_INSTANCE_HOME + "/dps")
    commitTxn()
    logTime("Register Metadata File Repository complete")

def check_status_oc4j():
    logTime("Checking OC4J status -- start")
    stobj = status("/"+MAS_FARM_NAME+"/"+ MAS_INSTANCE_NAME+"/"+ MAS_OC4J_NAME)
    st = getStatusUsingStObj(stobj, MAS_OC4J_NAME)
    sleepCount = 3
    maxSleep = 300

    for sleepCount in range(1,maxSleep,sleepCount):
      if st != "ALIVE":
         time.sleep(3)
         print "Sleeping ... ", sleepCount
         stobj = status("/"+MAS_FARM_NAME+"/"+ MAS_INSTANCE_NAME+"/"+ MAS_OC4J_NAME)
         st = getStatusUsingStObj(stobj, MAS_OC4J_NAME)
      else:
         break

    logTime("Checking OC4J status -- done")

def getStatusUsingStObj(status_obj, compname):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer
  st = status_obj.get('statusList')
  s1 = st[0].get('processState')
  return s1

def edit_java2_policy(policy_file):
    print "In edit_java2_policy"
    write_file = open(policy_file, 'a')
    write_file.write('/* JPS/CSF Security Permisssions */\n')
    write_file.write('grant codebase "file:${oracle.home}/sysman/jlib/emCORE.jar" {\n')
    write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore", "*";\n')
    write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.PROXY_INFO", "read";\n')
    write_file.write('};\n')
    write_file.close()

def setup_oc4j():
    logTime("Setting up oc4j_em")
    cd ('/'+MAS_FARM_NAME+'/'+MAS_INSTANCE_NAME+'/'+MAS_OC4J_NAME)
    change_java_opts()
    startTxn()
    getDoc(name='java2.policy', location=TEMP_DIR)
    fn = TEMP_DIR + File.separator + "java2.policy"
    edit_java2_policy(fn)
    saveDoc(name='java2.policy', file=fn)
    commitTxn()
    cd ('/'+MAS_FARM_NAME+'/'+MAS_INSTANCE_NAME)
    logTime("Setting up oc4j_em done")

#currently this procedure does nothing 
#if some java options need to be changed 
#or some need to be added, then one can use this function
#look at setup_emgc_infra_common.py for example use.
def change_java_opts():
    printMsg("Changing Start Params for oc4j_em")
    
    startParamsObj = getStartParams()
    resultString = startParamsObj.get('java-options')
    if resultString == "":
        raise "Could not set Java options for OC4J."
    else:
        resultString = resultString.replace('\n', '')

        oldJavaOptions = resultString 
        startTxn()
        setStartParams(javaOptions=oldJavaOptions+' -Doracle.sysman.util.logging.mode=jsdk_mode ');
        commitTxn()

    printMsg("Changing Start Params for oc4j_em done")

def log_oc4j_ports(compname):
    rmiport=getPort("/"+MAS_FARM_NAME+"/"+MAS_INSTANCE_NAME+"/"+compname+"/rmi")
    if rmiport != None:
        writeToLog('oracle.sysman.install.oc4j_rmi_port='+rmiport)
    else:
        raise "Could not get "+compname+" ports. "+compname+" may not be up"

def writeToLog(string):
   fileHandle = open (outfile, 'a')
   fileHandle.write(string+'\n')
   fileHandle.close()


def oc4j_temp_file_locn():
    f1 = TEMP_DIR + File.separator + "pcscomponent.xml"
    printMsg("Save file "+ f1)
    return f1

def add_shared_library():
    psl(connurl=MAS_CONN_URL,password=MAS_ADMIN_PASSWORD,user=MAS_ADMIN_USERNAME,name='oracle.sysman.mds',version='1.0',target='/'+MAS_FARM_NAME+'/'+MAS_INSTANCE_NAME+'/'+MAS_OC4J_NAME,installCodeSource=ORACLE_HOME+'/sysman/jlib/emMDSSharedLibrary.jar')

try:
    getOptions()
    execfile(configfile)
    set_vars()
    init()
    connect_mas()
    setup_oc4j()
    register_metadata_file_repos()
    add_shared_library()
    check_status_oc4j()
    log_oc4j_ports(MAS_OC4J_NAME)
    over()
except :
    # collect the exception
    (c, i, tb) =  sys.exc_info()
    printMsg("!!!Got Exception:")
    printMsg('Name of Exception: '+str(c))
    printMsg('Code of Exception: '+str(i))
    printMsg(str(tb))

