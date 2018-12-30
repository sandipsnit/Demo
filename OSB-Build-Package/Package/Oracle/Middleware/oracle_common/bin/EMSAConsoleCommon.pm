#!/usr/local/bin/perl
#
# $Header: EMSAConsoleCommon.pm 31-aug-2006.14:58:36 rsamaved Exp $
#
# EMSAConsoleCommon.pm
#
# Copyright (c) 2002, 2004, Oracle. All rights reserved.  
#
#    NAME
#      EMSAConsoleCommon.pm - Functions common to IAS console and DBConsole.
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       rsamaved 08/31/06 - dbconsole startup fix
#       kduvvuri 10/06/04 - no need of 'use AgentLifeCycle'. 
#       kduvvuri 10/06/04 - align history. 
#       kduvvuri 08/30/04 - functions common to both IAS console and
#                           DBConsole.
#

package EMSAConsoleCommon;
use EmctlCommon;

sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);
  return $self;
}
#
# statusSAConsole
# 1) argument list
# First argument is the consoletype, second arg is the object to intialize,
# third arg is the product name.
#
sub statusSAConsole
{
  my $classname = shift;

  my ($consoleType, $console, $emProduct) = @_;
  
  my $result;
  my ($rc );

  $OMS_RECV_DIR_SET = EmctlCommon::isOmsRecvDirSet();
  if ($OMS_RECV_DIR_SET)
  {
    if ( -e "$PID_FILE" )
    {
      my($PID);
      open(PIDFILE, "<$PID_FILE");
      while(<PIDFILE>)
      {
        $PID = $_;
      }
      close(PIDFILE);

      chomp($PID);

      die "$emProduct is not running.\n"
            if ($PID eq "");
   
      #print "PID from statusSAConsole is $PID \n";
      $console->Initialize($PID, time(), $DEBUG_ENABLED);
      $console->setImageCacheInitialized();
      $rc = $console->status();
     
      if($rc == $STATUS_NO_SUCH_PROCESS)
      {
        print "$emProduct is not running. \n";
        EmctlCommon::footer();
        exit $rc;
      }
    }
    else
    {
      die "$emProduct is not running.\n";
    }
  }
  else
  {
    $emProduct = "EM Daemon";
  } 

  # We need to check the Agent process...
  $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
  $rc >>= 8;
 
  if( ($rc == 3) or ($rc == 4) ) 
  { 
    print "$emProduct is running. \n";
    EmctlCommon::footer();
    exit 0;
  }
  else 
  { 
    print "EM Daemon is not running.\n"; 
    EmctlCommon::footer();
    exit $rc;
  }
}

#
# statusSAConsole_Internal is called during SACConsole to 
# check for both IASConsole/DBConsole and Agent Process liveness
#
# statusSAConsole_Internal() does not print any messages ....
# The first argument is the implict classname, second argument is the
# instantiated object , either DBConsole or IASConsole.
#
sub statusSAConsole_Internal()
{
  $console = shift;

  if ( ref($console) )
  {
    $console = shift;
  }

  #print "dbg console is $console\n";
  my ($rc, $result);

  $OMS_RECV_DIR_SET = EmctlCommon::isOmsRecvDirSet();
  if ($OMS_RECV_DIR_SET) {
    # On slow systems, the PID_FILE may take time to be written out...
    unless( -e "$PID_FILE")
    {
      sleep 4;
    }

    if ( -e "$PID_FILE" )
    {
      my($PID);
      open(PIDFILE, "<$PID_FILE");
      while(<PIDFILE>)
      {
        $PID = $_;
      }
      close(PIDFILE);

      #print "PID from $PID_FILE from statusSAConsoole_Internal is $PID\n";
      chomp($PID);
      if( ($PID eq undef) or ($PID eq "") )
      {
        return $STATUS_NO_SUCH_PROCESS;
      }

      #The caller is supposed to instantiate the approriate object.
      #Either DBConsole or IASConsole.
      $console->Initialize($PID, time(), $DEBUG_ENABLED);
      $rc = $console->status();
     
      #print "return value from console->status is $rc\n";
      if( ($rc == $STATUS_NO_SUCH_PROCESS) or
          ($rc == $STATUS_PROCESS_HANG) )
      {
        #print " returnng from  console->status is $rc\n";
        return $rc;
      }
    }
    else {
      return $STATUS_NO_SUCH_PROCESS;
    }
  }
  else {
    # recv dir not set, check status of agent only
    $rc = $STATUS_PROCESS_OK;
  }
     
  if($rc == $STATUS_PROCESS_OK)
  {
    # We need to check the Agent process...
    #print " Checking agent status\n";
    $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
    $rc >>= 8;
 
    #print "return value from status agent from SAConsole_Interanl $rc\n";
    if( ($rc == 3) or ($rc == 4) ) 
    { 
      if ($OMS_RECV_DIR_SET) {
        #print "returning value $STATUS_PROCESS_OK from agent\n";
        return $STATUS_PROCESS_OK; 
      }
      else {
        if ($rc == 3) {
          # agent is started
          return $STATUS_PROCESS_OK;
        }
        elsif ($rc == 4) {
          # agent process is partially started
          return $STATUS_PROCESS_PARTIAL;
        }
      }
    }
    else 
    { 
      if ($OMS_RECV_DIR_SET) {
        # db console was started but agent could not be started
        return $STATUS_PROCESS_PARTIAL;
      }
      else {
        #agent is not started
        return $STATUS_PROCESS_UNKNOWN;
      }
    }
  }
}


#
# Subroutine to check if the existing DB Console/IASConsole is running
# Note: There used to be two separate functions checkEM_SAConsole and 
# checkSAConsole which did the same thing except for printing a different
# message. This function does the same thing except that the caller passes
# the message to be printed. 
#
sub checkSAConsole()
{
    $self = shift;
    $alreadyRunningMsg = shift;
    if ( -e "$PID_FILE" )
    {
       my($PID);
       open(PIDFILE, "<$PID_FILE");
       while(<PIDFILE>)
       {
         $PID = $_;
       }
       close(PIDFILE);

       chomp($PID);
       if( $PID ne undef )
       {
         if( (kill 0, $PID) )
         {
           print $alreadyRunningMsg;
	   exit 1;
         }
       }

       unlink("$PID_FILE");
    }
}

sub DESTROY {
    my $self = shift;
}


1;
