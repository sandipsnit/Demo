#
# $Header: setup_emgc_infra_common.py 10-jun-2008.04:10:25 smodh Exp $
#
# Copyright (c) 2004, 2008, Oracle. All rights reserved.  
#
#    NAME
#      setup_emgc_infra_common.py
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    smodh       06/10/08 - 
#    neearora    04/24/08 - set max perm gen size to 384 MB
#    jashukla    04/01/08 - Bug 6917474
#    smodh       03/28/08 - Bug 6921762
#    mgrumbac    03/21/08 - Remove adfc work-around flag
#    jashukla    03/07/08 - 
#    smodh       03/03/08 - Changes for Multi OMS setup
#    sreddy      02/27/08 - add -Doracle.sysman.util.logging.mode
#    vpedapat    02/25/08 - fix bug 6236370: Use setStartParams instead of
#                           modifying pcscomponent.xml
#    jashukla    02/22/08 - 
#    smodh       02/15/08 - Creation
#

# Common infrastructure setup script for EM

##############################
## Generic functions
#############################

def getPortString(endpoint_path):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer
  printMsg("getPorts(\"" + endpoint_path + "\")")

  # redirect asctl stdout to a String
  origStdOut = System.out
  byteArrayStream = ByteArrayOutputStream()
  System.setOut(PrintStream(byteArrayStream))
  getPorts(endpoint_path)

  # restore stdout
  System.setOut(origStdOut)
  resultString = byteArrayStream.toString()
  System.out.println(resultString)
  return resultString

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


def getStatusUsingStObj(status_obj, compname):
  from java.lang import String
  from java.io import PrintStream
  from java.io import ByteArrayOutputStream
  from java.util import StringTokenizer
  st = status_obj.get('statusList')
  s1 = st[0].get('processState')
  return s1


def runcmd(cmd):
    printMsg("Launching "+cmd)
    os.system(cmd)



#########################################
## Generic Functions to setup em infra
#########################################

def setup_ohs1(outfile):
    print "From setup_ohs1"
    line = get_httpd_em_tmpl()
    p1 = re.compile( '%EM_UPLOAD_HTTP_PORT%' , re.DOTALL)
    p2 = re.compile( '%EM_UPLOAD_DENY%' , re.DOTALL)
    p3 = re.compile( '%EM_VHOST%' , re.DOTALL)
    p4 = re.compile( '%ORACLE_HOME%' , re.DOTALL)
    p5 = re.compile( '%TIMEOUT%' , re.DOTALL)

    #for currentline in readlines:
    if p1.search(line):
        line = p1.sub(UPLOAD_HTTP_PORT, line)

    if p2.search(line):
        line = p2.sub(EM_UPLOAD_DENY, line)

    if p3.search(line):
        line = p3.sub(HOST_NAME, line)

    if p4.search(line):
        line = p4.sub(ORACLE_HOME, line)

    if p5.search(line):
        line = p5.sub(HTTP_SERVER_TIMEOUT, line)

    # Write to output file.
    write_file=open(outfile,'w')
    write_file.write(line)
    write_file.close()

def get_httpd_em_tmpl():
    httpd_em_conf = ( \
    r'<VirtualHost %EM_VHOST%_http_em_console_Endpoint>'+"\n" \
    r'    Timeout %TIMEOUT%'+"\n" \
    r'    <Location /em/upload>'+"\n" \
    r'        Order deny,allow'+"\n" \
    r'        Deny from %EM_UPLOAD_DENY%'+"\n" \
    r'        Allow from localhost'+"\n" \
    r'    </Location>'+"\n" \
    r'    <Location /em/jobrecv>'+"\n" \
    r'        Order deny,allow'+"\n" \
    r'        Deny from %EM_UPLOAD_DENY%'+"\n" \
    r'        Allow from localhost'+"\n" \
    r'    </Location>'+"\n" \
    r'##        ErrorLog "|%ORACLE_HOME%/Apache/Apache/bin/rotatelogs %ORACLE_HOME%/Apache/Apache/logs/error_log 43200" '+"\n" \
    r'##        TransferLog "|%ORACLE_HOME%/Apache/Apache/bin/rotatelogs %ORACLE_HOME%/Apache/Apache/logs/access_log 43200" '+"\n" \
    r'</VirtualHost>'+"\n" \
    r'<Location /em/upload>'+"\n" \
    r'    Order deny,allow'+"\n" \
    r'    Deny from %EM_UPLOAD_DENY%'+"\n" \
    r'    Allow from localhost'+"\n" \
    r'</Location>'+"\n" \
    r'<Location /em/jobrecv>'+"\n" \
    r'    Order deny,allow'+"\n" \
    r'    Deny from %EM_UPLOAD_DENY%'+"\n" \
    r'    Allow from localhost'+"\n" \
    r'</Location>'+"\n" \
    r''+"\n" \
    )
    return httpd_em_conf

def setup_ohs2(infile):
    readlines=open(infile,'r').readlines()
    listindex = -1

    for currentline in readlines:
        listindex = listindex + 1
        if re.match(r'\s*include\s+\"mod_oc4j.conf\"', currentline):
            readlines[listindex] = currentline+'\n#Include config file needed for Enterprise Manager\n'+'include \"httpd_em.conf\"\n'+'#Include agent_download.conf file\n'+'include \"agent_download.conf\"\n'
	#Comment php5_module
	if re.match(r'\s*LoadModule\s+php5_module',currentline):
	    readlines[listindex] = '#LoadModule php5_module modules/mod_php5.so\n' 

    # Write to output file.
    write_file=open(infile,'w')
    for line in readlines:
        write_file.write(line)

    write_file.close()

def connect_mas():
    logTime("Connect to MAS. Stop Recording Temporarily.")
    stopRecording()
    connect(user=MAS_ADMIN_USERNAME, password=MAS_ADMIN_PASSWORD, connURL=MAS_CONN_URL)
    f = cmdlog
    startRecording(file=f)
    logTime("Connect to MAS done. Start Recording Again.")

def start_ohs():
    logTime("Start ohs_em")
    stobj = start('/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OHS_NAME)
    st = getStatusUsingStObj(stobj, OHS_NAME)
    if st != "ALIVE":
       raise "Start of "+OHS_NAME+" failed"

    logTime("Start ohs_em done")
   
def oc4j_temp_file_locn():
    f1 = TMP_DIR + File.separator + "pcscomponent.xml"
    printMsg("Save file "+ f1)
    return f1


def edit_java2_policy(policy_file):
    print "In edit_java2_policy"
    #emCORE_jar_loc = INSTANCE_HOME + "/OC4JComponent/" + OC4J_NAME + "/applications/em/em/WEB-INF/lib/emCORE.jar"
    #emCORE_jar_loc_pds = INSTANCE_HOME + "/OC4JComponent/" + OC4J_NAME + "/applications/em/em.war/WEB-INF/lib/emCORE.jar"
    emCORE_jar_loc = ORACLE_HOME + "/sysman/jlib/emCORE.jar"
    write_file = open(policy_file, 'a')
    write_file.write('/* JPS/CSF Security Permisssions */\n')
    write_file.write('grant codebase "file:' + emCORE_jar_loc + '" {\n')
    write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore", "*";\n')
    write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.REPOS_DETAILS", "read";\n')
    write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.ENCR_DETAILS", "read";\n')
    write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.PROXY_INFO", "read";\n')
    write_file.write('};\n')
    #write_file.write('grant codebase "file:' + emCORE_jar_loc_pds + '" {\n')
    #write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore", "*";\n')
    #write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.REPOS_DETAILS", "read";\n')
    #write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.ENCR_DETAILS", "read";\n')
    #write_file.write('    permission oracle.security.jps.service.credstore.CredentialAccessPermission "credstoressp.credstore.EM.PROXY_INFO", "read";\n')
    #write_file.write('};\n')
    write_file.close()


def setup_oc4j():
    logTime("Setting up oc4j_em")
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OC4J_NAME)
    change_java_opts()
    startTxn()
    getDoc(name='java2.policy', location=TMP_DIR)
    fn = TMP_DIR + File.separator + "java2.policy"
    edit_java2_policy(fn)
    saveDoc(name='java2.policy', file=fn)
    commitTxn()
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    logTime("Setting up oc4j_em done")

def change_java_opts():
    logTime("Changing Start Params for oc4j_em")

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
        setStartParams(javaOptions=oldJavaOptions_1+' -Xmx512M -XX:MaxPermSize=384m -Doracle.sysman.util.logging.mode=jsdk_mode -Dhttp.file.allowAlias=true -Djava.awt.headless=true -Doc4j.userThreads=true -Doracle.mds.bypassCustRestrict=true -Dsun.rmi.dgc.server.gcInterval=600000 -Dsun.rmi.dgc.client.gcInterval=600000 '+OC4J_OPTS+' ');
        commitTxn()

    logTime("Changing Start Params for oc4j_em done")

def start_oc4j():
    logTime("Starting oc4j_em")
    stobj = start("/"+FARM_NAME+"/"+ INSTANCE_NAME+"/"+ OC4J_NAME)
    st = getStatusUsingStObj(stobj, OC4J_NAME)
    if st != "ALIVE":
       raise "Start of "+OC4J_NAME+" failed"

    logTime("Starting oc4j_em done") 

def configurePortRangeOhs():
    logTime("Starting to configure Port Range for http_main, http_ssl")
    compname = '/'+FARM_NAME+'/'+ INSTANCE_NAME+'/'+ OHS_NAME
    startTxn()
    cd(compname)
    listPortRanges()
    set_port_range(compname, 'http_main', 'http', int(CONSOLE_HTTP_PORT), int(CONSOLE_HTTP_PORT), 1)
    set_port_range(compname, 'http_ssl', 'https', int(CONSOLE_HTTPS_PORT), int(CONSOLE_HTTPS_PORT), 1)
    set_port_range(compname, 'http_dms', 'http', int(EM_HTTP_DMS_PORT_START), int(EM_HTTP_DMS_PORT_END), 1)
    cd(compname)
    listPortRanges()
    commitTxn()
    logTime("Configuring Port Range for http_main, http_ssl done")
    logTime("Starting to configure Port Range for http_main, http_ssl")

def setup_ohs():
    logTime("Setting up ohs_em")
    global HOST_NAME
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    HOST_NAME=getTopologyAttribute('PrimaryHostName')
    f = File(sys.argv[0])
    cd ('/'+FARM_NAME)
    createAccessPoint(name=HOST_NAME+'_http_em_console', hostname=HOST_NAME, port=UPLOAD_HTTP_PORT, protocol='http')
    createAccessPoint(name=HOST_NAME+'_https_em_upload', hostname=HOST_NAME, port=UPLOAD_HTTPS_PORT, protocol='http')
    assignAccessPoint(accessPoint=HOST_NAME+'_http_em_console', comp='/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OHS_NAME)
    assignAccessPoint(accessPoint=HOST_NAME+'_https_em_upload', comp='/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OHS_NAME)

    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OHS_NAME)
    setup_ohs1(TMP_DIR+File.separator+'httpd_em.conf')
    # register httpd_em.conf with MAS first.
    startTxn()
    saveDoc(name='httpd_em.conf', file=TMP_DIR+'/'+'httpd_em.conf')
    saveDoc(name='agent_download.conf', file=ORACLE_HOME+'/'+'sysman'+'/'+'config'+'/'+'agent_download.conf')
    getDoc(name="httpd.conf", location=TMP_DIR);
    setup_ohs2(TMP_DIR+File.separator+"httpd.conf")
    saveDoc(name='httpd.conf', file=TMP_DIR+File.separator+"httpd.conf")
    commitTxn()
    configurePortRangeOhs()
    cd ('/'+FARM_NAME+'/'+INSTANCE_NAME)
    logTime("Setting up ohs_em done")

def setup_routing():
    logTime("Setting up routing relations")
    startTxn()
    createRoutingRelationship(name=OC4J_OHS_ROUTING_REL_NAME, endpoint='/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OC4J_NAME+'/'+'default-web-site', from='/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OHS_NAME, to='/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OC4J_NAME)
    commitTxn()
    logTime("Setting up routing relations done")


def set_port_range(comppath, porttype, protocol, lp, hp, remove_old_range):
    cd(comppath+'/'+porttype)
    if (remove_old_range == 1) :
        origStdOut = System.out
        byteArrayStream = ByteArrayOutputStream()
        System.setOut(PrintStream(byteArrayStream))
        # run listPortRanges
        listPortRanges()
        # restore stdout
        System.setOut(origStdOut)
        resultString = byteArrayStream.toString()
        resultString = resultString.replace('\n', '')
        print resultString
        #p1=re.compile('^.*?\s*'+porttype+'\s*\|\s*\|\s*(\d+)\s*\|\s*(\d+).*$', re.DOTALL)
        p1= re.compile('^.*?'+porttype+'\s*?\|\s*?\|\s*(\d+)\s*\|\s*(\d+)(.*$)', re.DOTALL)
        m=p1.match(resultString)
        if m:
            lowport=int(m.group(1))
            highport = int(m.group(2))
            removePortRange(low=lowport,high=highport)
            addPortRange(low=lp,high=hp)
        else:
            raise "Could not get port ranges."
    else:
        addPortRange(low=lp,high=hp)
    

def change_port_ranges_for_oc4j():
    compname = '/'+FARM_NAME+'/'+ INSTANCE_NAME+'/'+ OC4J_NAME
    startTxn()
    cd(compname)
    listPortRanges()
    set_port_range(compname, 'default-web-site', 'ajp', int(EM_OC4J_DEF_WEB_SITE_PORT_START), int(EM_OC4J_DEF_WEB_SITE_PORT_END), 0)
    set_port_range(compname, 'http-web-site', 'http', int(EM_OC4J_HTTP_WEB_SITE_PORT_START), int(EM_OC4J_HTTP_WEB_SITE_PORT_END), 1)
    set_port_range(compname, 'rmi', 'rmi', int(EM_RMI_PORT_START), int(EM_RMI_PORT_END), 0)
    set_port_range(compname, 'rmis', 'rmis', int(EM_OC4J_RMIS_PORT_START), int(EM_OC4J_RMIS_PORT_END), 0)
    set_port_range(compname, 'jms', 'jms', int(EM_JMS_PORT_START), int(EM_JMS_PORT_END), 0)
    set_port_range(compname, 'iiop', 'iiop', int(EM_OC4J_IIOP_PORT_START), int(EM_OC4J_IIOP_PORT_END), 0)
    set_port_range(compname, 'iiops', 'iiops', int(EM_OC4J_IIOPS_PORT_START), int(EM_OC4J_IIOPS_PORT_END), 0)
    set_port_range(compname, 'iiops-mutual-auth', 'iiops', int(EM_OC4J_IIOPS_MUT_AUTH_PORT_START), int(EM_OC4J_IIOPS_MUT_AUTH_PORT_END), 0)
    cd(compname)
    listPortRanges()
    commitTxn()


def add_shared_library():
     psl(connurl=MAS_CONN_URL,password=MAS_ADMIN_PASSWORD,user=MAS_ADMIN_USERNAME,name='oracle.sysman.mds',version='1.0',target='/'+FARM_NAME+'/'+INSTANCE_NAME+'/'+OC4J_NAME,installCodeSource=ORACLE_HOME+'/sysman/jlib/emMDSSharedLibrary.jar')

