import java.lang.System as System
import sys
import java.io.File as File
f = File(sys.argv[0])
execfile(f.getParent() + '/asctl_common.py')
printMsg("connect(user=\"" + EM_ADMIN_USERNAME + "\", password=\"" + EM_ADMIN_PASSWORD + "\", connURL=\""+EM_MAS_CONN_URL+"\")");
connect(user=EM_ADMIN_USERNAME, password=EM_ADMIN_PASSWORD, connURL=EM_MAS_CONN_URL)

#printMsg("cd(\"" + getVar("TOPO_PATH") + "\")");
#cd(getVar("TOPO_PATH"))

printMsg("activate()");
activate()
