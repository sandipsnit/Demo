import sys;

EM_MAS_USERNAME = ""
EM_MAS_USERPASSWORD = ""
EM_MAS_CONN_URL = ""
EM_INSTANCE_NAME = ""
EM_COMP_NAME = ""
EM_MAS_JMX_PORT = ""
EM_MAS_HOSTNAME = ""

def usage():
	sys.stderr.write("asctl script install_get_ports.py [--EM_MAS_USERNAME username] [--EM_MAS_USERPASSWORD password] [--EM_MAS_HOSTNAME hostname] [--EM_MAS_JMX_PORT port] [--EM_INSTANCE_NAME name] [--EM_COMP_NAME comp]\n")

def getOpts():
	global argv
	global EM_MAS_USERNAME 
	global EM_MAS_USERPASSWORD 
	global EM_MAS_JMX_PORT
	global EM_MAS_HOSTNAME
	#global EM_MAS_CONN_URL
	global EM_INSTANCE_NAME 
	global EM_COMP_NAME

	opts = sys.argv[1:]
	a = len(opts)
	index = 0

	if(a == index):
		usage()
		sys.exit(0)

	while index <= a-1:
		opt = opts[index]
		if opt in ("--EM_MAS_USERNAME", "-EM_MAS_USERNAME"):
			EM_MAS_USERNAME = opts[index+1]
			index = index+2
		elif opt in ("--EM_MAS_USERPASSWORD", "-EM_MAS_USERPASSWORD"):
			EM_MAS_USERPASSWORD = opts[index+1]
			index = index+2
		elif opt in ("--EM_MAS_HOSTNAME", "-EM_MAS_HOSTNAME"):
			EM_MAS_HOSTNAME = opts[index+1]
			index = index+2
		elif opt in ("--EM_MAS_JMX_PORT", "-EM_MAS_JMX_PORT"):
			EM_MAS_JMX_PORT = opts[index+1]
			index = index+2
		elif opt in ("--EM_INSTANCE_NAME", "-EM_INSTANCE_NAME"):
			EM_INSTANCE_NAME = opts[index+1]
			index = index+2
		elif opt in ("--EM_COMP_NAME", "-EM_COMP_NAME"):
			EM_COMP_NAME = opts[index+1]
			index = index+2
		else:
			usage()
			sys.exit(0)

getOpts()
EM_MAS_CONN_URL = EM_MAS_HOSTNAME + ":" + EM_MAS_JMX_PORT
#sys.stderr.write(EM_MAS_CONN_URL+ "\n")
#sys.stderr.write(EM_MAS_USERNAME+ "\n")
#sys.stderr.write(EM_MAS_USERPASSWORD + "\n")
#sys.stderr.write(EM_INSTANCE_NAME + "\n")
#sys.stderr.write(EM_COMP_NAME + "\n")

connect(user=EM_MAS_USERNAME, password=EM_MAS_USERPASSWORD, connURL=EM_MAS_CONN_URL);
cd(EM_INSTANCE_NAME + '/' + EM_COMP_NAME);
listPorts();

