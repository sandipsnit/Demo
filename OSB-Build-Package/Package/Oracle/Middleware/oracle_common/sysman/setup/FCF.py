#Author bhupchan

#This Jython script is called from within the EMoms.pm by enableFCF function

#! /usr/bin/python

import os
import re
import java.lang.System as System
import java.lang.Runtime as Runtime
import java.io.ByteArrayOutputStream as ByteArrayOutputStream
import java.io.PrintStream as PrintStream
import java.lang.String
import sys

#Global variable name for the NRD Component
# This has benn hardcoded because fo the bug 6927986.
NRD_NAME = 'nrd'
FARM_NAME=os.environ.get('EM_FARM_NAME');
INSTANCE_NAME=os.environ.get('EM_INSTANCE_NAME');

def create_nrd():
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME )
  startTxn()
  createComponent(name=NRD_NAME, type='NRDComponent')
  commitTxn()


def start_nrd():
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME + '/' + NRD_NAME)
  startTxn()
  start()
  commitTxn()

def assign_port_nrd():
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME + '/' + NRD_NAME + '/' + 'nrd_listen')
  startTxn() 
  assignPort()
  commitTxn()

def configure_nrd(ons_nodes):
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME + '/' + NRD_NAME)
  node_list = ons_nodes.split(";")
  num_nodes = len(node_list)
  i = 0
  while i < num_nodes :
    str = "'" + node_list[i] + "'"
    startTxn()
    addNRDNode(node=node_list[i])
    commitTxn()

    i = i + 1
 
def get_nrd_port():
  origStdOut = System.out
  byteArrayStream = ByteArrayOutputStream()
  System.setOut(PrintStream(byteArrayStream));
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME + '/' + NRD_NAME + '/' + 'nrd_listen')
  startTxn()
  listPorts() 
  commitTxn()
  #restore stdout
  System.setOut(origStdOut)
  resultString = byteArrayStream.toString()
  resultArray = resultString.split("\n")
  i = 0
  n = resultArray.__len__()
  nrd_port = "";
  p1 = re.compile(".*nrd_listen\s*\|.*")
  while i < n:
    result = p1.match(resultArray[i])
    if result:
      info = resultArray[i].split("|");
      nrd_port = info[1]
    i = i + 1
  return nrd_port


def restart_nrd():
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME + '/' + NRD_NAME)
  startTxn()
  restart()
  commitTxn()

 
def is_nrd_present():
  origStdOut = System.out
  byteArrayStream = ByteArrayOutputStream()
  System.setOut(PrintStream(byteArrayStream));
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME )
  startTxn()
  ls(l=1) 
  commitTxn()
  #restore stdout
  System.setOut(origStdOut)
  resultString = byteArrayStream.toString()
  resultArray = resultString.split("\n")
  i = 0
  n = resultArray.__len__()
  nrd_exists = 0
  p1 = re.compile(".*NRDComponent\s*")
  while i < n:
    result = p1.match(resultArray[i])
    if result:
      nrd_exists = 1
      arr = resultArray[i].split()
      print "NRDComponent Name = "+arr[0]+"\n"
      NRD_NAME = arr[0];
      return nrd_exists
    i = i + 1  
  return nrd_exists
 
def get_nrd_status():
  origStdOut = System.out
  byteArrayStream = ByteArrayOutputStream()
  System.setOut(PrintStream(byteArrayStream));
  cd ('/' + FARM_NAME + '/' + INSTANCE_NAME + '/' + NRD_NAME )
  startTxn()
  status()
  commitTxn()
  #restore stdout
  System.setOut(origStdOut)
  resultString = byteArrayStream.toString()
  resultArray = resultString.split("\n")
  i = 0
  n = resultArray.__len__()
  nrd_alive = 0
  while i < n:
  
    p1 = re.compile("^\s*NRDComponent.*nrd.*ALIVE")
    result = p1.match(resultArray[i])
    if result:
      nrd_alive = 1;
    
    i = i + 1

  return nrd_alive; 

try:
  mas_user = os.environ.get('EM_MAS_ADMIN_USER');
  mas_passwd = os.environ.get( 'EM_MAS_ADMIN_PASSWD');
  mas_connurl = os.environ.get('EM_MAS_CONN_URL');


  connect(user=mas_user, password=mas_passwd, connURL=mas_connurl);
  
  if is_nrd_present() == 0 :
    print "NRDComponent does not exist\n"
    create_nrd()
  
  else:
    print "NRDCompoent exists\n"

  print "Checking the status of the NRDComponent\n"

  if get_nrd_status() == 0:
    print "NRDComponent Not Alive. Starting it..\n";
    start_nrd()
  else:
    print "NRDComponent is Alive\n";
    print "Assigning port to the NRDComponent\n";   
    assign_port_nrd()

  print "Configuring NRDComponent\n";

  configure_nrd(sys.argv[1])

  print "NRDConfiguration Done\n";

  print "Getting NRDComponent Port\n";

  nrd_port = get_nrd_port()

  print "Got the nrd_port as " + nrd_port + "\n";

  print "Restarting the NRDComponent\n";

  restart_nrd()

  print "NRDComponent Restarted\n";

  print "RAC Database Nodes  should also be configured for enabling FCF. Following line should be added to the ons.config file in all the RAC Database Nodes \n";
  print "\n nodes=<hostname>:<port>\n";
  print " where \n";
  print "\n hostname is the host for OMS and port is the NRD Port which is " + nrd_port + "\n";
  
except:
#collect the exception
  (c, i, tb) = sys.exc_info()
  print"!!!Got Exception"
  print 'Exception name: '+str(c)
  print 'Exception code: '+str(i)
  print str(tb)
  System.exit(1)

