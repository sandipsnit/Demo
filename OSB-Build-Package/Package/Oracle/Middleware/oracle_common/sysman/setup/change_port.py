import java.lang.System as System
import sys
import re

# Needed for getRdsPort
rdsscript = oracleHome.getCanonicalPath() + '/scripts/rdsconfig.py'
execfile(rdsscript)

def getPort(endpoint_path):
  endport=getRdsPort(endpoint_path)
  endport=endport.lstrip()
  endport=endport.rstrip()
  if endport != None:
     return endport
  else:
     raise "Error: Parsing port"
  return ""

EM_ADMIN_USERNAME=System.getenv('EM_ADMIN_USERNAME')
EM_ADMIN_PASSWORD=System.getenv('EM_ADMIN_PASSWORD')
EM_MAS_CONN_URL=System.getenv('EM_MAS_CONN_URL')
TOPO_PATH=System.getenv('TOPO_PATH')
NEW_PORT=System.getenv('NEW_PORT')

connect(user=EM_ADMIN_USERNAME, password=EM_ADMIN_PASSWORD, connURL=EM_MAS_CONN_URL)
OLD_PORT=getPort(TOPO_PATH)
cd(TOPO_PATH)
removePortRange(low=int(OLD_PORT),high=int(OLD_PORT))
addPortRange(low=int(NEW_PORT),high=int(NEW_PORT))
cd('..') 
start() 

