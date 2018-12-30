import sys
import getopt
import string


def getServers(cluster):
	svrList = ls('/Servers', returnMap='true', returnType='a')
        serversStr = " "
        print ' '
        clustername = " "
        for token in svrList:
                token=token.strip().lstrip().rstrip()
                if not token == '' and not token == 'AdminServer':
                        cd('/Servers/'+token)
                        clustername = get('Cluster')
                        searchClusterStr = cluster+","
                        clusterNameStr = str(clustername)
                        if not clusterNameStr.find(searchClusterStr) == -1:
                                serversStr = serversStr+ token + ","
        print "Servers for Cluster :- ", cluster , " is :- ", serversStr
        return serversStr


def getPort(managedServerName, managedServersStr):
	port = " "
	for token in managedServersStr.split(","):
                token=token.strip().lstrip().rstrip()
                if not token == '':
			tokenArr = token.split(":")
			if tokenArr[0] == managedServerName:
				port = tokenArr[1]
	return port

def ifExcludeServer(server, excludeServersStr):
	exclude = "false"
	for token in excludeServersStr.split(","):
                token=token.strip().lstrip().rstrip()
                if not token == '':
			if token == server:
				exclude = "true"
			
	return exclude

def trim(trimstr):
        return trimstr.strip().lstrip().rstrip()

discoverer_port=clusterName=managed_server=exclude_server=distribute_mode=hosts=" "

print " "
input = raw_input("Enter Hostnames (eg host1,host2) : ")
input = trim(input)
if not input == "":
	hosts = input

clusterOption = 'y'
print " "
input  = raw_input("Do you want to specify a cluster name (y/n) <y>")
input = trim(input)
if not input == "":
        clusterOption = input

if clusterOption == 'y' or clusterOption == 'Y':
	print " "
	input  = raw_input("Enter Cluster Name : ")
	input = trim(input)
	if not input == "":
        	clusterName = input


	print " "
	input  = raw_input("Enter Discover Port : ")
	input = trim(input)
	if not input == "":
        	discoverer_port = input

else:
	print " "
	input  = raw_input("Enter Managed Server and Discover Port (eg WLS_Spaces1:9999, WLS_Spaces2:9999) : ")
	input = trim(input)
	if not input == "":
        	managed_server = input


print " "
distribute_mode='true'
input  = raw_input("Enter Distribute Mode (true|false) <"+distribute_mode+"> : ")
input = trim(input)
if not input == "":
        distribute_mode = input


excludeOption = 'n'
print " "
input  = raw_input("Do you want to exclude any server(s) from JOC configuration (y/n) <n>")
input = trim(input)
if not input == "":
        excludeOption = input

if excludeOption == 'y' or excludeOption == 'Y':
	print " "
	input  = raw_input("Exclude Managed Server List (eg Server1,Server2) : ")
	input = trim(input)
	if not input == "":
        	exclude_server = input


if not clusterName.isspace():
	print "*** Cluster option is specified, JOC will be configured for all the Managed Server in the Cluster ", clusterName, " at the port ", discoverer_port

	serverListStr = getServers(clusterName)	
	
	serverArr=[]

 	for token in serverListStr.split(","):
                token=token.strip().lstrip().rstrip()	
		if not token == '':
			serverArr.append(java.lang.String(token))

	print serverArr

	hostsArr=[]

 	for hostname in hosts.split(","):
                hostname=hostname.strip().lstrip().rstrip()	
		if not hostname  == '':
			hostsArr.append(java.lang.String(hostname))

	print hostsArr


 	for token in serverListStr.split(","):
                token=token.strip().lstrip().rstrip()	
		if not token == '':
			print ' '
			print "Configuring JOC for server :- ", token
			domainCustom()
			serverPath = "/oracle.joc/oracle.joc:type=JOCConfig,ServerName="+token
			cd (serverPath)
			set("DiscoverPort", int(discoverer_port))
			set("DiscoverList", array(hostsArr, java.lang.String))

			exclude = ifExcludeServer(token, exclude_server)
			if exclude == "true":
				print "Server :- ", token, " will be excluded, setting DistributeMode to false"
				set("DistributeMode", false)
			elif exclude == "false":
				set("DistributeMode", true)

			if distribute_mode == "false":
				set("DistributeMode", false)
			
			ls()


if not managed_server.isspace():
	print "*** JOC will be configured to all the specified Managed Servers"

	serverArr=[]
        for token in managed_server.split(","):
                token=token.strip().lstrip().rstrip()
                if not token == '':
			tokenArr = token.split(":")
                        serverArr.append(java.lang.String(tokenArr[0]))

        print serverArr
	print ' '

	hostsArr=[]

 	for hostname in hosts.split(","):
                hostname=hostname.strip().lstrip().rstrip()	
		if not hostname  == '':
			hostsArr.append(java.lang.String(hostname))

	print hostsArr

	for managedServerStr in serverArr:
		print ' '
                print "Configuring JOC for server :- ", managedServerStr
                domainCustom()
                serverPath = "/oracle.joc/oracle.joc:type=JOCConfig,ServerName="+ str(managedServerStr)

                cd (serverPath)
		portStr = getPort(str(managedServerStr), managed_server)
		print "Discoverer port for Managed Server :- ", managedServerStr ," is ", portStr
                set("DiscoverPort", int(portStr))
                set("DiscoverList", array(hostsArr, java.lang.String))

		exclude = ifExcludeServer(token, exclude_server)
		if exclude == "true":
			print "Server :- ", token, " will be excluded, setting DistributeMode to false"
			set("DistributeMode", false)
		elif exclude == "false":
			set("DistributeMode", true)

		if distribute_mode == "false":
			set("DistributeMode", false)
		ls()

