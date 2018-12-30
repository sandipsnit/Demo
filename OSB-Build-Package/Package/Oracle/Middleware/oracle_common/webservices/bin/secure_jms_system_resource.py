import sys
from java.lang import System
import getopt

# Arguments username/password are Admin username/password
# Argument url is Admin server t3 url
# Argument jmsSystemResource is JMS module (JMS system resource name) to be secured, e.g. JRFWSAsyncJmsModule or JRFWSAsyncJmsModule_<myCluster>
# Argument role is the security role with which to secure the JMS system resource. E.g. "OracleSystemRole". This role should already be available in your security realm. "OracleSystemRole" is available by default in WLS install for infrastructure JRF component.

def printUsage():
  print ' '
  print 'This online (connected mode) WLST script is for applying role based security policy to existing JMS system resource.'
  print '-----'
  print 'Usage'
  print '-----'
  print '<JAVA_HOME>/bin/java -classpath <weblogic.jar_location> weblogic.WLST ./secure_jms_system_resource.py --username <AdminUserName> --password <AdminPassword> --url <AdminServer_t3_url> --jmsSystemResource <JMSSystemResourceName> --role <SecurityRoleToUse>'
  print ' '

def createPolicy(atz, jmsSystemResourceName, rol):
  resourceId="type=<jms>, application="+ jmsSystemResourceName
  print resourceId
  if atz.policyExists(resourceId):
    print "Policy found for " + jmsSystemResourceName
    atz.removePolicy(resourceId)
    print "Policy removed for " + jmsSystemResourceName
      
  atz.createPolicy(resourceId,'Rol('+rol+')')
  #atz.createPolicy(resourceId,'Usr('+usr+')')
  print "Created security policy for " + jmsSystemResourceName + " using role "+rol


try:
    options,remainder = getopt.getopt(sys.argv[1:],'', ['username=', 'password=', 'url=', 'jmsSystemResource=', 'role='])
except getopt.error, msg:
    printUsage()
    sys.exit(2)

for opt, arg in options:
    if opt == '--username':
      username = arg
    elif opt == '--password':
      password = arg
    elif opt == '--url':
      url = arg
    elif opt == '--jmsSystemResource':
      jmsSystemResource = arg
    elif opt == '--role':
      role = arg

if username.isspace():
   print "Error: username argument not found."
   printUsage()
   sys.exit(2)

if password.isspace():
   print "Error: password argument not found."
   printUsage()
   sys.exit(2)

if url.isspace():
   print "Error: url argument not found."
   printUsage()
   sys.exit(2)

if jmsSystemResource.isspace():
   print "Error: jmsSystemResource argument not found."
   printUsage()
   sys.exit(2)

if role.isspace():
   print "Error: role argument not found."
   printUsage()
   sys.exit(2)

print ' '
print 'username: ',username
#print 'password: ',password
print 'url: ',url
print 'jmsSystemResource: ',jmsSystemResource
print 'role: ',role
print ' '

print "Begin: Applying security policy to the JMS system resource."

try:  
  connect(username, password, url)

  # Exit with error code 3 (non-zero meaning abnormal termination) if supplied JMS sytem resource is not found.
  suppliedJSR = getMBean("/JMSSystemResources/"+jmsSystemResource)
  if suppliedJSR is None:
    print "Error: Cannot continue. Could not find supplied jmsSystemResource "+jmsSystemResource
    disconnect()
    sys.exit(3)
  else:
    print "Found jmsSystemResource "+jmsSystemResource

  realm=cmo.getSecurityConfiguration().getDefaultRealm()
  atz=realm.lookupAuthorizer('XACMLAuthorizer')
  createPolicy(atz, jmsSystemResource, role)

  disconnect()
  print "End: Applying security policy to the JMS system resource."
  print ' '
  print "Security policy configuration can be viewed in Weblogic server Administration console at: Services -> Messaging -> JMS Modules -> <JMS Module> -> Security -> Policies"
  exit()

except:
  print "Error while applying security policy to the JMS system resource"
  dumpStack()
