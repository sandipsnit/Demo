import sys
import getopt
import string

def printUsage():
        print 'This offline WLST script can be run against a cluster to create two JMS Uniform Distributed Queues required for JRF WS Asynchronous Services.'
        print ' '
        print '-----'
        print 'Usage'
        print '-----'
        print ' '
        print '<JAVA_HOME>/bin/java -classpath <weblogic.jar_location_from_your_install> weblogic.WLST <ORACLE_HOME>/webservices/bin/jrfws-async-createUDDs.py --domain_home <domain_home_dir> --cluster <your_cluster_name>'
        print ' '

def getCurrentJMSServerCnt():
        try:
          s = ls('/JMSServer')
          count = s.count("JRFWSAsyncJmsServer_auto")
          print 'Existing JRFWSAsyncJmsServer_auto JMSServer count in the domain is '+str(count)
          count = count + 1
        except:
          count = 1
          print 'No JRFWSAsyncJmsServer_auto JMSServers found in the domain.'
        return count

def createJMSServers(cluster, currentServerCnt):
        print ' '
        print "Creating JMS Servers for the cluster :- ", cluster
        s = ls('/Server')
        print ' '
        clustername = " "
        serverCnt = currentServerCnt
        for token in s.split("drw-"):
                token=token.strip().lstrip().rstrip()
                path="/Server/"+token
                cd(path)
                if not token == 'AdminServer' and not token == '':
                        clustername = get('Cluster')
                        print "Cluster Associated with the Server [",token,"] :- ",clustername
                        print ' '
                        searchClusterStr = cluster+":"
                        clusterNameStr = str(clustername)
                        print "searchClusterStr = ",searchClusterStr
                        print "clusterNameStr = ",clusterNameStr
                        if not clusterNameStr.find(searchClusterStr) == -1:
                                print token, " is associated with ", cluster
                                cd('/')

                                jmsServerName = 'JRFWSAsyncJmsServer_auto_'+str(serverCnt)

                                create(jmsServerName, 'JMSServer')
                                print "Created JMS Server :- ", jmsServerName
                                print ' '

                                fileStoreName = 'JRFWSAsyncFileStore_auto_'+str(serverCnt)
                                createFileStore(fileStoreName, token)
                                print "Created File Store :- ", fileStoreName
                                print ' '

                                assign('JMSServer', jmsServerName, 'Target', token)
                                print jmsServerName, " assigned to server :- ", token
                                print ' '

                                cd('/JMSServer/'+jmsServerName)
                                set ('PersistentStore', fileStoreName)

                                set ('MessagesMaximum', 200000)
                                print "messages-maximum quota of 200000 is set for JMS server by default. Reconfigure it for your environment as required."
                                print ' '

                                cd('/')

                                print jmsServerName, " assigned to FileStore :- ", fileStoreName
                                print ' '
                                serverCnt = serverCnt + 1

def createFileStore(storeName, serverName):
    create(storeName, 'FileStore')
    cd('/FileStore/'+storeName)
    set ('Target', serverName)
    set ('Directory', storeName)
    cd('/')

def createUniformDistributedQueue(subDeploymentName, destName, destJNDIName, errorDestination):
    print "Creating UniformDistributedQueue %s on SubDeployment %s" % (destName, subDeploymentName)

    udq = create(destName, 'UniformDistributedQueue')

    cd ('UniformDistributedQueue')
    cd (destName)

    set ('JNDIName', destJNDIName)
    set ('SubDeploymentName', subDeploymentName)

    if not errorDestination == None:
      dpo = create('dpoName','DeliveryParamsOverrides')
      dpo.setRedeliveryDelay(15*60*1000)
      print 'RedeliveryDelay set to '+str(15*60*1000)+' milliseconds for UniformDistributedQueue '+destName+'.'
      dfp = create('dfpName', 'DeliveryFailureParams')
      dfp.setRedeliveryLimit(100)
      print 'RedeliveryLimit set to 100 for UniformDistributedQueue '+destName+'.'
      dfp.setExpirationPolicy('Redirect')
      dfp.setErrorDestination(errorDestination)
      print 'ErrorDestination set to '+errorDestination.getName()+' for UniformDistributedQueue '+destName+'.'

    print 'UniformDistributedQueue '+destName+' created.'

    cd ('../..')
    return udq

def getClusterName(targetServer):
        targetServerStr = str(targetServer)
        s = ls('/Server')
        print ' '
        clustername = " "
        for token in s.split("drw-"):
                token=token.strip().lstrip().rstrip()
                path="/Server/"+token
                cd(path)
                if not token == 'AdminServer' and not token == '':
                        if not targetServerStr.find(token+":") == -1:
                                clustername = get('Cluster')
        return clustername

def processCluster(myCluster):
    cd('/')

    # Create new JMSSystemResource for this cluster
    create('JRFWSAsyncJmsModule_'+myCluster,'JMSSystemResource')
    cd ('/JMSSystemResource/JRFWSAsyncJmsModule_'+myCluster)
    cmo.setDescriptorFileName('jms/jrfwsasyncjmsmodule_'+myCluster+'-jms.xml')
    set ('Target',myCluster)

    # List of JMS servers from domain
    cd ('/JMSServer')
    jmsServers = ls('c', returnMap='true')

    # Get JRFWSAsyncJmsServer_auto JMS servers for myCluster
    myJMSServers = []
    for jmsServer in jmsServers:
      if jmsServer.find('JRFWSAsyncJmsServer_auto') == 0:
        cd('/JMSServer/'+jmsServer)
        targetServers = cmo.getTargets()
        for targetServer in targetServers:
          cName = getClusterName(targetServer)
          if cName is not None:
            if cName.getName() == myCluster:
              myJMSServers.append(jmsServer)

    cd ('/JMSSystemResource/JRFWSAsyncJmsModule_'+myCluster)

    # Create a common cluster-wide SubDeployment for myCluster
    subName = 'JRFWSAsyncSubDeployment_'+myCluster
    print "Creating SubDeployment %s" % (subName)
    create (subName, 'SubDeployment')
    cd ('SubDeployment')
    cd (subName)

    listOfJMSServers = ''
    # Add JRFWSAsyncJMSServer(s) to the created common SubDeployment (comma-separated list of JMSServers)
    i = 0
    for myJMSServer in myJMSServers:
      i = i + 1
      if (i == len(myJMSServers)):
        listOfJMSServers += myJMSServer
      else:
        listOfJMSServers += myJMSServer + ','

    cd ('/JMSSystemResource/JRFWSAsyncJmsModule_'+myCluster)
    cd ('SubDeployment')
    cd (subName)
    set ('Target', listOfJMSServers)
    cd ('../..')
    cd ('JmsResource/NO_NAME_0')


    # Create request and response error UniformDistributedQueues first.
    requestErrorQ = createUniformDistributedQueue(subName,"JRFWSAsyncRequestErrorQueue_"+myCluster,"oracle.j2ee.ws.server.async.DefaultRequestErrorQueue", None)
    responseErrorQ = createUniformDistributedQueue(subName,"JRFWSAsyncResponseErrorQueue_"+myCluster,"oracle.j2ee.ws.server.async.DefaultResponseErrorQueue", None)
    
    # Create request and response UniformDistributedQueues and target them to common SubDeployment.
    createUniformDistributedQueue(subName,"JRFWSAsyncRequestQueue_"+myCluster,"oracle.j2ee.ws.server.async.DefaultRequestQueue", requestErrorQ)
    createUniformDistributedQueue(subName,"JRFWSAsyncResponseQueue_"+myCluster,"oracle.j2ee.ws.server.async.DefaultResponseQueue", responseErrorQ)

    cd ('../..')



try:
        options,remainder = getopt.getopt(sys.argv[1:],'', ['cluster=', 'domain_home='])
except getopt.error, msg:
        printUsage()
        sys.exit()

for opt, arg in options:
    if opt == '--cluster':
        cluster = arg
    elif opt == '--domain_home':
        domain_home= arg

if domain_home.isspace():
   printUsage()
   sys.exit()

if cluster.isspace():
   printUsage()
   sys.exit()

print ' '
print 'Domain Home: ',domain_home
print 'Cluster: ', cluster
print ' '

readDomain(domain_home)

# If JRFWSAsync JMSSystemResource already exists on this cluster, print error and do nothing.
try:
  cd ('/JMSSystemResource/JRFWSAsyncJmsModule_'+cluster)
  print "Error: JMS system resource JRFWSAsyncJmsModule_"+cluster+" detected on cluster "+cluster +". Remove all JRFWSAsync JMS resources from this cluster and retry or use this script on a newly created cluster."

except:
  createJMSServers(cluster, getCurrentJMSServerCnt())
  processCluster(cluster)

  print "Done with JRF WS Async JMS Uniform Distributed Queue configuration for the cluster %s" % (cluster)

  print ' '
  print ("*** Saving domain ***")

  updateDomain()
  print ("*** Domain saved successfully ***")

  #dumpStack()

