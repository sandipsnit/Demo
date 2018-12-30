# Caution: This file is part of the command scripting implementation. Do not edit or move
# this file because this may cause commands and scripts to fail. Do not
# try to reuse the logic in this file or keep copies of this file because this
# could cause your scripts to fail when you upgrade to a different version.

# Oracle JMX connector for JBoss

from java.lang import System
from java.util import Hashtable
from java.lang import String
import java.lang.Exception

from javax.management import MBeanServerConnection
from javax.management import Attribute
from javax.management.remote import JMXConnectorFactory
from javax.management.remote import JMXServiceURL
from javax.management.remote import JMXConnector
from javax.management.remote.rmi import RMIConnectorServer
from javax.rmi.ssl import SslRMIClientSocketFactory
from javax.rmi.ssl import SslRMIServerSocketFactory

import jarray
import ora_util
import ora_mbs
import cie.OracleHelp as OracleHelp

global _server
_server = None
global _isConnected
_isConnected = 0
global _jmxCon
_jmxCon = None

def getMbsInstance():
    return _server

def setSSLProperties(keyStore='', keyPass='', trustStore='', trustWord=''):
    System.setProperty('javax.net.ssl.keyStore', keyStore)
    System.setProperty('javax.net.ssl.keyStorePassword', keyPass)
    System.setProperty('javax.net.ssl.trustStore', trustStore)
    System.setProperty('javax.net.ssl.trustStorePassword', trustWord)

def connect(user='', cred='', host='localhost', port='19000',isSSL=0):
    #exmple: "service:jmx:rmi://localhost/jndi/rmi://localhost:19000/jmxrmi"
    urlString = 'service:jmx:rmi://' + host +'/jndi/rmi://' + host +':'+ port +'/jmxrmi'
    print urlString
    global _server
    global _jmxCon
    global _isConnected

    if not _jmxCon is None :
        return _server
        
    try:
        serviceUrl = JMXServiceURL(urlString)
        env = Hashtable()
        credentials = jarray.array([user, cred], String)
        env.put(JMXConnector.CREDENTIALS, credentials)

        if(isSSL):
            csf = SslRMIClientSocketFactory()
            ssf = SslRMIServerSocketFactory()
            env.put(RMIConnectorServer.RMI_CLIENT_SOCKET_FACTORY_ATTRIBUTE, csf)
            env.put(RMIConnectorServer.RMI_SERVER_SOCKET_FACTORY_ATTRIBUTE, ssf)
            env.put("com.sun.jndi.rmi.factory.socket", csf);

        _jmxCon = JMXConnectorFactory.newJMXConnector(serviceUrl, env)
        _jmxCon.connect()

        _server = _jmxCon.getMBeanServerConnection()

        _isConnected = 1

    except java.lang.Exception, e:
        global _jmxCon
        if not _jmxCon is None :
            _jmxCon.close()
            _jmxCon = None
        ora_util.raiseScriptingException(e)
        global _isConnected
        _isConnected = 0
        global _server
        _server = None
    return _server

def disconnect():
    global _server
    _server = None
    global _isConnected
    _isConnected = 0
    global _jmxCon
    if not _jmxCon is None :
        _jmxCon.close()
        _jmxCon = None

def isConnected():
    return _isConnected

def getOracleJMXConnector():
    return ora_mbs.makeObjectName("oracle.as.jmx:service=OracleJMXConnectorServer,protocol=rmi")

def help(cmd=None):
    _module = "OracleJMX"
    if cmd == None:
        cmd = _module
    else:
        cmd = _module + '.' + cmd
    return OracleHelp.help(cmd)

