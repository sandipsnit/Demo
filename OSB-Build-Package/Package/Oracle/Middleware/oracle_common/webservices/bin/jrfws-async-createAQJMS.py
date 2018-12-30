import sets
import sys
import getopt
import string

CF_NAME='CF_NAME'
CF_LOCAL_JNDI_NAME='CF_LOCAL_JNDI_NAME'
CF_TYPE='CF_TYPE'

REQ_DEST_NAME='REQ_DEST_NAME'
REQ_DEST_REMOTE_JNDI_NAME='REQ_DEST_REMOTE_JNDI_NAME'
REQ_DEST_LOCAL_JNDI_NAME='REQ_DEST_LOCAL_JNDI_NAME'
REQ_DEST_TYPE='REQ_DEST_TYPE'

RES_DEST_NAME='RES_DEST_NAME'
RES_DEST_REMOTE_JNDI_NAME='RES_DEST_REMOTE_JNDI_NAME'
RES_DEST_LOCAL_JNDI_NAME='RES_DEST_LOCAL_JNDI_NAME'
RES_DEST_TYPE='RES_DEST_TYPE'

DEFAULT_DATASOURCE_JNDI='jdbc/JRFWSAsyncDSAQ'

DEFAULT_AQ_MODULE_NAME='JRFWSAsyncJmsModuleAQ'
DEFAULT_AQ_FS_NAME='JRFWSAsyncJmsForeignServerAQ'

DEFAULT_REQ_DEST_LOCAL_JNDI_NAME='oracle.j2ee.ws.server.async.AQRequestQueue'
DEFAULT_RES_DEST_LOCAL_JNDI_NAME='oracle.j2ee.ws.server.async.AQResponseQueue'

DEFAULT_CF_LOCAL_JNDI_NAME='aqjms/AsyncWSAQConnectionFactory'

def printUsage():
        print "==========================================================================================="
        print ' '
        print "This offline WLST script creates and configures JMS resources required for JRF WS Async services to work with AQ JMS on a WebLogic domain."
        print "Note that corresponding JDBC datasource is required to be created and it's JNDI name needs to be an input to the JMS module's foreign server that is created by this script. If JDBC datasource's JNDI name is not the default datasource JNDI name used by this script, "+DEFAULT_DATASOURCE_JNDI+" then the JNDI name needs to be supplied to this script using datasource_jndi argument."
        print "Separate domain extension template is provided for creating the JDBC datasource."
        print ' '
        print '-----'
        print 'Usage:'
        print '-----'
        print ' '
        print '<JAVA_HOME>/bin/java -classpath <weblogic.jar_location_from_your_install> weblogic.WLST <ORACLE_HOME>/webservices/bin/jrfws-async-createAQJMS.py --domain_home <domain_home_dir> --targets <comma_separated_list_of_cluster_name(s)_and/or_non-clustered_server_name(s)_where_you_want_the_JMS_module_targeted> --connection_factory_local_jndi <connection_factory_local_jndi_name>  --datasource_jndi <jdbc_datasource_jndi_name> --destinations_remote_jndi_name_prefix <prefix_to_be_added_to_remote_jndi_name(s)_of_the_request_and_response_queues> --request_queue_jndi <request_queue_local_jndi_name> --response_queue_jndi <response_queue_local_jndi_name>'
        print ' '
        print "connection_factory_local_jndi argument is optional. If it is not supplied, default "+DEFAULT_CF_LOCAL_JNDI_NAME+" is used. This connection factory local JNDI name is the one that is supplied in the JRF WS Async service source(s) via Java annotation and the same is used by JRF WS Async runtime."
        print "datasource_jndi argument is optional. If it is not supplied, default "+DEFAULT_DATASOURCE_JNDI+" is used. Ensure that datasource JNDI name used by this script matches with the created/existing datasource's JNDI name."
        print "destinations_remote_jndi_name_prefix argument is optional. If it is not supplied, domain name is used as prefix as in request queue remote JNDI name will be <prefix>_AsyncWS_Request and response queue remote JNDI name will be <prefix>_AsyncWS_Response."
        print "request_queue_jndi argument is optional. If it is not supplied, default "+DEFAULT_REQ_DEST_LOCAL_JNDI_NAME+" is used. This request queue JNDI name is the one that is supplied in the JRF WS Async service source(s) via Java annotation and the same is used by JRF WS Async runtime."
        print "response_queue_jndi argument is optional. If it is not supplied, default "+DEFAULT_RES_DEST_LOCAL_JNDI_NAME+" is used. This response queue JNDI name is the one that is supplied in the JRF WS Async service source(s) via Java annotation and the same is used by JRF WS Async runtime."
        print ' '
        print "==========================================================================================="


#internal functions
def __genTargetList(tgts):
    targets = []
    if tgts and tgts.strip():
        ts = tgts.strip().split(',')
        for t in ts:
          targets.append(t.strip())
    return targets

def __assertNotEmpty(aString, errorMessage):
    assert (aString and aString.strip()), errorMessage

def __checkCFType(cfType):
    if cfType!='ConnectionFactory' and cfType!='QueueConnectionFactory' and \
       cfType!='TopicConnectionFactory' and cfType!='XAConnectionFactory' and \
       cfType!='XAQueueConnectionFactory' and cfType!='XATopicConnectionFactory':
        raise SyntaxError, 'Wrong connection factory type: '+cfType

def __checkDestType(destType):
    if destType!='QUEUE' and destType!='TOPIC':
        raise SyntaxError, 'Wrong destination type: '+destType

def __checkDuplicate(keyName, isDuplicate):
    if isDuplicate:
        raise SyntaxError, 'Duplicate entry of key: '+keyName

def __parseCF(cfData):
    __assertNotEmpty(cfData, "Connection Factory definition is empty")
    cfData=cfData.strip()
    if not (cfData.startswith('{') and cfData.endswith('}')):
        raise SyntaxError, 'Connection Factory defintion must be enclosed in {}'
    cfData=cfData[1:len(cfData)-1]

    wlsCFName=''
    cfJndi=''
    cfType=''
 
    for item in cfData.split(','):
        (myKey, myValue)=item.split(':')
        if myKey==CF_NAME:
            __checkDuplicate(CF_NAME, wlsCFName)
            wlsCFName=myValue 
        elif myKey==CF_LOCAL_JNDI_NAME:
            __checkDuplicate(CF_LOCAL_JNDI_NAME, cfJndi)
            cfJndi=myValue
        elif myKey==CF_TYPE:
            __checkDuplicate(CF_TYPE, cfType)
            cfType=myValue
        else:
            raise SyntaxError, 'Unkown key in connection factory definition: '+ myKey

    return {CF_NAME:wlsCFName, CF_LOCAL_JNDI_NAME:cfJndi, CF_TYPE:cfType}

def __parseRequestDest(destData):
    __assertNotEmpty(destData, "Request destination definition is empty")
    destData=destData.strip()
    if not (destData.startswith('{') and destData.endswith('}')):
        raise SyntaxError, 'Request destination defintion must be enclosed in {}'
    destData=destData[1:len(destData)-1]

    wlsDestName=''
    destJndi=''
    aqDestName=''
    destType=''

    for item in destData.split(','):
        (myKey, myValue)=item.split(':')
        if myKey==REQ_DEST_NAME:
            __checkDuplicate(REQ_DEST_NAME, wlsDestName)
            wlsDestName=myValue
        elif myKey==REQ_DEST_REMOTE_JNDI_NAME:
            __checkDuplicate(REQ_DEST_REMOTE_JNDI_NAME, aqDestName)
            aqDestName=myValue
        elif myKey==REQ_DEST_TYPE:
            __checkDuplicate(REQ_DEST_TYPE, destType)
            destType=myValue
        elif myKey==REQ_DEST_LOCAL_JNDI_NAME:
            __checkDuplicate(REQ_DEST_LOCAL_JNDI_NAME, destJndi)
            destJndi=myValue
        else:
            raise SyntaxError, 'Unkown key in request destination definition: '+ myKey

    return {REQ_DEST_NAME:wlsDestName, REQ_DEST_REMOTE_JNDI_NAME:aqDestName, REQ_DEST_TYPE:destType, REQ_DEST_LOCAL_JNDI_NAME:destJndi}

def __parseResponseDest(destData):
    __assertNotEmpty(destData, "Response destination definition is empty")
    destData=destData.strip()
    if not (destData.startswith('{') and destData.endswith('}')):
        raise SyntaxError, 'Response destination defintion must be enclosed in {}'
    destData=destData[1:len(destData)-1]

    wlsDestName=''
    destJndi=''
    aqDestName=''
    destType=''

    for item in destData.split(','):
        (myKey, myValue)=item.split(':')
        if myKey==RES_DEST_NAME:
            __checkDuplicate(RES_DEST_NAME, wlsDestName)
            wlsDestName=myValue
        elif myKey==RES_DEST_REMOTE_JNDI_NAME:
            __checkDuplicate(RES_DEST_REMOTE_JNDI_NAME, aqDestName)
            aqDestName=myValue
        elif myKey==RES_DEST_TYPE:
            __checkDuplicate(RES_DEST_TYPE, destType)
            destType=myValue
        elif myKey==RES_DEST_LOCAL_JNDI_NAME:
            __checkDuplicate(RES_DEST_LOCAL_JNDI_NAME, destJndi)
            destJndi=myValue
        else:
            raise SyntaxError, 'Unkown key in response destination definition: '+ myKey

    return {RES_DEST_NAME:wlsDestName, RES_DEST_REMOTE_JNDI_NAME:aqDestName, RES_DEST_TYPE:destType, RES_DEST_LOCAL_JNDI_NAME:destJndi}

#public functions
def createDataSource(host, port, sid, username, password, dsName, \
        dsJndiName, xa, \
        serverTargets, \
        clusterTargets): 

    __assertNotEmpty(dsName,'DataSource name is required to create DataSource')
    __assertNotEmpty(dsJndiName,'Datasource JNDI name is required to create DataSource')
    __assertNotEmpty(sid,'Oracle database sid is required to create DataSource')
    __assertNotEmpty(host,'Oracle host is required to create DataSource')

    if not username:
        username = raw_input('Enter Oracle database username:')
    __assertNotEmpty(username,'Oracle username is required to create DataSource')

    if not password:
        password =  raw_input('Enter Oracle database password:')
    __assertNotEmpty(password,'Oracle password is required to create DataSource')

    cd('/')
    create(dsName, 'JDBCSystemResource')
    cd('/JDBCSystemResource/%s' % (dsName))
    cmo.setDescriptorFileName('jdbc/'+dsName+'-jdbc.xml')

    cd('/JDBCSystemResource/%s/JdbcResource/%s' % (dsName,dsName))
    cmo.setName(dsName)
    create(dsName,'JDBCDataSourceParams')
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCDataSourceParams/NO_NAME_0' % (dsName,dsName))
    cmo.setJNDINames(jarray.array([String(dsJndiName)], String))
    cd('/JDBCSystemResource/%s/JdbcResource/%s' % (dsName,dsName))
    create(dsName,'JDBCDriverParams')
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCDriverParams/NO_NAME_0' % (dsName,dsName) )
    cmo.setUrl('jdbc:oracle:thin:@%s:%i:%s' % (host, port, sid) )

    if xa:
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
    else:
        cmo.setDriverName('oracle.jdbc.OracleDriver')

    set('PasswordEncrypted', password)
    cd('/JDBCSystemResource/%s/JdbcResource/%s' % (dsName,dsName) )
    create(dsName,'JDBCConnectionPoolParams')
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCConnectionPoolParams/NO_NAME_0' % (dsName,dsName) )
    cmo.setTestTableName('SQL SELECT 1 FROM DUAL\r\n')
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCDriverParams/NO_NAME_0' % (dsName,dsName))
    create(dsName,'Properties')
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0' % (dsName,dsName))
    create('user', 'Property')
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user' % (dsName,dsName) )
    cmo.setValue(username)
    cd('/JDBCSystemResource/%s/JdbcResource/%s/JDBCDataSourceParams/NO_NAME_0' % (dsName,dsName) )

    if xa:
        cmo.setGlobalTransactionsProtocol('TwoPhaseCommit')
    else:
        cmo.setGlobalTransactionsProtocol('None')

    cd('/')
    targets = __genTargetCSVList(serverTargets, clusterTargets)
    if not targets.isspace() and not len(targets)==0:
        assign('JDBCSystemResource', dsName, 'Target', targets)

def addAQModuleTargets(moduleName, targets):
    cd('/')
    suppliedTargets = __genTargetList(targets)
    
    existingTargetNames = []
    cd('/JMSSystemResource/%s' % (moduleName) )
    existingTargets = cmo.getTargets()
    for existingTarget in existingTargets:
      existingTargetNames.append(existingTarget.getName())

    print('Existing targets for the JMS module: '+moduleName)
    print(existingTargetNames)
    print('Supplied targets for the JMS module: '+moduleName)
    print(suppliedTargets)

    combined = []
    combined.extend(existingTargetNames)
    combined.extend(suppliedTargets)

    # remove duplicates using Set
    targets = list(sets.Set(combined))

    print('Combined targets for the JMS module: '+moduleName)
    print(targets)

    listOfTargets = ''
    i = 0
    for target in targets:
      i = i + 1
      if (i == len(targets)):
        listOfTargets += str(target)
      else:
        listOfTargets += str(target) + ','
     
    if not len(listOfTargets)==0:
        assign('JMSSystemResource', moduleName, 'Target', listOfTargets)
    

def createAQModule(aqcfs, aqrequestdests, aqresponsedests, moduleName, fsName, \
                   dsJndiName, targets):
    __assertNotEmpty(moduleName,'JMS module name is required to create a module for AQ JMS')
    __assertNotEmpty(fsName,'JMS foreign server name is required to create a foreign server for AQJMS')
    __assertNotEmpty(dsJndiName,'Weblogic datasource JNDI name is required to create a foreign server for AQJMS') 

    #create JMSSystemResource
    cd('/')
    create(moduleName, 'JMSSystemResource')

    cd('/JMSSystemResource/%s' % (moduleName) )
    cmo.setDescriptorFileName('jms/'+moduleName+'-jms.xml')

    cd('/')
    if not targets.isspace() and not len(targets) == 0:
        assign('JMSSystemResource', moduleName, 'Target', targets)

    #create AQ foreign server
    cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0' % (moduleName) )
    create(fsName, 'ForeignServer')

    cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s' % (moduleName,fsName) )
    cmo.setDefaultTargetingEnabled(true)
    cmo.setInitialContextFactory('oracle.jms.AQjmsInitialContextFactory')
    create('datasource','JNDIProperty')

    cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s/JNDIProperty/NO_NAME_0' % (moduleName,fsName) )
    cmo.setKey('datasource')
    cmo.setValue(dsJndiName)

    # create AQ foreign server connection factory
    cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s' % (moduleName,fsName) )
    for cfData in aqcfs: 
        __assertNotEmpty(cfData[CF_NAME], 'Weblogic foreign connection factory name cannot be empty')
        __assertNotEmpty(cfData[CF_LOCAL_JNDI_NAME], 'Weblogic foreign connection factory jndi cannot be empty')
        __checkCFType(cfData[CF_TYPE]);

        create(cfData[CF_NAME], 'ForeignConnectionFactory')
        cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s/ForeignConnectionFactories/%s'\
           % (moduleName,fsName,cfData[CF_NAME]) )
        cmo.setLocalJNDIName(cfData[CF_LOCAL_JNDI_NAME])
        cmo.setRemoteJNDIName(cfData[CF_TYPE])

    # create AQ foreign server destination (request queue)
    cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s' % (moduleName,fsName) )
    for destData in aqrequestdests: 
        __assertNotEmpty(destData[REQ_DEST_NAME], 'Weblogic foreign destination name cannot be empty')
        __assertNotEmpty(destData[REQ_DEST_LOCAL_JNDI_NAME], 'Weblogic foreign destination jndi cannot be empty')
        __assertNotEmpty(destData[REQ_DEST_REMOTE_JNDI_NAME], 'AQ destination name cannot be empty')
        __checkDestType(destData[REQ_DEST_TYPE])

        create(destData[REQ_DEST_NAME],'ForeignDestination')
        cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s/ForeignDestinations/%s'\
           % (moduleName,fsName,destData[REQ_DEST_NAME]) )
        cmo.setLocalJNDIName(destData[REQ_DEST_LOCAL_JNDI_NAME])
        if destData[REQ_DEST_TYPE] == 'QUEUE':
            cmo.setRemoteJNDIName('Queues/'+destData[REQ_DEST_REMOTE_JNDI_NAME])
        else:
            cmo.setRemoteJNDIName('Topics/'+destData[REQ_DEST_REMOTE_JNDI_NAME])

    # create AQ foreign server destination (response queue)
    cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s' % (moduleName,fsName) )
    for destData in aqresponsedests:
        __assertNotEmpty(destData[RES_DEST_NAME], 'Weblogic foreign destination name cannot be empty')
        __assertNotEmpty(destData[RES_DEST_LOCAL_JNDI_NAME], 'Weblogic foreign destination jndi cannot be empty')
        __assertNotEmpty(destData[RES_DEST_REMOTE_JNDI_NAME], 'AQ destination name cannot be empty')
        __checkDestType(destData[RES_DEST_TYPE])

        create(destData[RES_DEST_NAME],'ForeignDestination')
        cd('/JMSSystemResource/%s/JmsResource/NO_NAME_0/ForeignServers/%s/ForeignDestinations/%s'\
           % (moduleName,fsName,destData[RES_DEST_NAME]) )
        cmo.setLocalJNDIName(destData[RES_DEST_LOCAL_JNDI_NAME])
        if destData[RES_DEST_TYPE] == 'QUEUE':
            cmo.setRemoteJNDIName('Queues/'+destData[RES_DEST_REMOTE_JNDI_NAME])
        else:
            cmo.setRemoteJNDIName('Topics/'+destData[RES_DEST_REMOTE_JNDI_NAME])

def setupAQJMS(aqModName, aqFSName, dsJNDI, aqTgts, cfDetails, requestDestDetails, responseDestDetails):
    myCFList=[]
    myRequestDestList=[]
    myResponseDestList=[]

    #myDBHost=myValue
    #myDBPort=Integer.parseInt(myValue)
    #myDBSid=myValue
    #myDBUser=myValue
    #myDBPass=myValue
    #myDSName=myValue
    #myDSJndi=myValue
    #myDSXA=Integer.parseInt(myValue)
    #myDSSvrTgts=myValue
    #myDSClsTgts=myValue

    myAQModName=aqModName
    myAQFSName=aqFSName
    myDSJndi=dsJNDI
    myAQTgts=aqTgts

    myCFList.append(__parseCF(cfDetails))
    myRequestDestList.append(__parseRequestDest(requestDestDetails))
    myResponseDestList.append(__parseResponseDest(responseDestDetails))

    # Not creating datasource in this script. Domain extension template will be provided for that.
    # Reason is that domain extension template has better support for creating datasources, 
    # for example, it provides a facility to create multi datasource and add generic datasources under it.
    #createDataSource(host=myDBHost, port=myDBPort, sid=myDBSid, username=myDBUser, password=myDBPass, \
    #                  dsName=myDSName, dsJndiName=myDSJndi, xa=myDSXA, \
    #                 serverTargets=myDSSvrTgts, clusterTargets=myDSClsTgts)

    moduleExists = 0
    s1 = ls('/')
    for token1 in s1.split("drw-"):
       if moduleExists == 1:
         break
       token1=token1.strip().lstrip().rstrip()
       if token1 == 'JMSSystemResource':
          s2 = ls('/JMSSystemResource')
          for token2 in s2.split("drw-"):
            token2=token2.strip().lstrip().rstrip()
            if token2 == myAQModName:
              print(myAQModName+' JMSSystemResource found')
              moduleExists = 1
              break 
          
    if moduleExists == 0:
      print('Creating JMSSystemResource by name '+myAQModName+' on this domain.')
      createAQModule(aqcfs=myCFList, aqrequestdests=myRequestDestList, aqresponsedests=myResponseDestList, moduleName=myAQModName, fsName=myAQFSName,\
                   dsJndiName=myDSJndi, targets=myAQTgts)
    else:
      print('JMSSystemResource by name '+myAQModName+' already exists on this domain. It will not be created but supplied targets (comma-separated list of cluster and/or non-clustered server names) will be added to the list of JMSSystemResource targets.')
      addAQModuleTargets(moduleName=myAQModName, targets=myAQTgts)


#main function
if __name__ == 'main':
    try:
        options,remainder = getopt.getopt(sys.argv[1:],'', ['domain_home=', 'targets=', 'connection_factory_local_jndi=', 'datasource_jndi=', 'destinations_remote_jndi_name_prefix=', 'request_queue_jndi=', 'response_queue_jndi='])
    except getopt.error, msg:
        printUsage()
        sys.exit()

    domain_home = ''
    targets = ''
    connection_factory_local_jndi = ''
    datasource_jndi = ''
    destinations_remote_jndi_name_prefix = ''
    request_queue_jndi = ''
    response_queue_jndi = ''

    for opt, arg in options:
      if opt == '--domain_home':
        domain_home = arg
      elif opt == '--targets':
        targets = arg
      elif opt == '--connection_factory_local_jndi':
        connection_factory_local_jndi = arg
      elif opt == '--datasource_jndi':
        datasource_jndi = arg
      elif opt == '--destinations_remote_jndi_name_prefix':
        destinations_remote_jndi_name_prefix = arg
      elif opt == '--request_queue_jndi':
        request_queue_jndi = arg
      elif opt == '--response_queue_jndi':
        response_queue_jndi = arg

    if len(domain_home.strip()) == 0:
      print 'domain_home argument must be supplied.'
      printUsage()
      sys.exit()

    if len(targets.strip()) == 0:
      print 'targets argument must be supplied (for example, cluster name).'
      printUsage()
      sys.exit()

    if len(connection_factory_local_jndi.strip()) == 0:
      connection_factory_local_jndi = DEFAULT_CF_LOCAL_JNDI_NAME

    if len(datasource_jndi.strip()) == 0:
      datasource_jndi = DEFAULT_DATASOURCE_JNDI 

    if len(request_queue_jndi.strip()) == 0:
      request_queue_jndi  = DEFAULT_REQ_DEST_LOCAL_JNDI_NAME

    if len(response_queue_jndi.strip()) == 0:
      response_queue_jndi = DEFAULT_RES_DEST_LOCAL_JNDI_NAME

    print ' '
    print 'Below arguments will get used: '
    print 'domain_home: ', domain_home
    print 'targets: ', targets
    print 'connection_factory_local_jndi: ', connection_factory_local_jndi
    print 'datasource_jndi: ', datasource_jndi
    print 'request_queue_jndi: ', request_queue_jndi
    print 'response_queue_jndi: ', response_queue_jndi

    readDomain(domain_home)

    tokenList = domain_home.split('/')
    #print(tokenList)
    lastToken = tokenList[len(tokenList)-1]
    if len(lastToken.strip()) == 0:
      domainName = tokenList[len(tokenList)-2]
    else:
      domainName = lastToken.strip()
    print('Domain name: '+domainName)

    if len(destinations_remote_jndi_name_prefix.strip()) == 0:
      destinations_remote_jndi_name_prefix = domainName
      print('Domain name '+domainName+' will be prefixed to the request and response queue remote JNDI name(s). E.g. '+domainName+'_AsyncWS_Request.')
    else:
      print(destinations_remote_jndi_name_prefix+' will be prefixed to the request and response queue remote JNDI name(s). E.g. '+destinations_remote_jndi_name_prefix+'_AsyncWS_Request.')

    failed=1
    try:
        setupAQJMS(DEFAULT_AQ_MODULE_NAME, \
                   DEFAULT_AQ_FS_NAME, \
                   datasource_jndi, \
                   targets, \
                   '{CF_NAME:AQCF,CF_LOCAL_JNDI_NAME:'+connection_factory_local_jndi+',CF_TYPE:QueueConnectionFactory}', \
                   '{REQ_DEST_NAME:AsyncWS_Request,REQ_DEST_LOCAL_JNDI_NAME:'+request_queue_jndi+',REQ_DEST_REMOTE_JNDI_NAME:'+destinations_remote_jndi_name_prefix+'_AsyncWS_Request,REQ_DEST_TYPE:QUEUE}', \
                   '{RES_DEST_NAME:AsyncWS_Response,RES_DEST_LOCAL_JNDI_NAME:'+response_queue_jndi+',RES_DEST_REMOTE_JNDI_NAME:'+destinations_remote_jndi_name_prefix+'_AsyncWS_Response,RES_DEST_TYPE:QUEUE}')

        print ("Saving domain.")
        updateDomain()
        print ("Domain saved successfully.")

        failed=0 
    finally:
        if failed:
            undo('false','y')
