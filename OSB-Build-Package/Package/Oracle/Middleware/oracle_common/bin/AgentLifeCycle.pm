#
# $Header: emagent/scripts/unix/AgentLifeCycle.pm /st_emagent_10.2.0.1.0/6 2009/02/10 00:33:54 qding Exp $
#
# AgentLifeCycle.pm
#
# Copyright (c) 2002, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      AgentLifeCycle.pm - start and stop of the agent.
#
#    DESCRIPTION
#      Module that handles start and stop of the  agent using emctl.
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    qding    02/06/09 - lrg 3777308, try for EMAGENT_TIME_FOR_START_STOP
#                        seconds instead of times and forcefully kill agent if
#                        it keeps timing out
#    sunagarw 12/30/08 - fix asstart for windows
#    sunagarw 11/20/08 - XbranchMerge sunagarw_pcs_changes from main
#    sunagarw 08/01/08 - XbranchMerge njagathe_windows_non_service_start from
#                        main
#    sunagarw 06/16/08 - Backport sunagarw_bug-5014908 from main
#    njagathe 02/15/08 - XbranchMerge dgiaimo_bug-4757344 from main
#    kduvvuri 09/10/05 - process abbend file on unix platforms. 
#    kduvvuri 08/22/05 - align the headers. 
#    kduvvuri 08/19/05 - remove temp files. 
#    kduvvuri 08/05/05 - fix 4524126. 
#    vnukal   07/21/05 - returning exit code of stop/istop
#    kduvvuri 06/21/04 - align the help columns.
#    kduvvuri 07/09/04 - Add define for EXITFILE.
#    kduvvuri 05/05/04 - created.
#

package AgentLifeCycle;
use EmctlCommon;
use EmCommonCmdDriver;
use File::Temp qw/ tempfile /;
use POSIX ":sys_wait_h";
use IPC::Open3;
use Cwd;
use EMAgent;

sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);

  #cmdList is a list containing all the command implementors.
  #construct this some how..
  return $self;
}

sub doIT {
   my $classname = shift;
   my $rargs = shift;
   my $result = $EMCTL_DONE;

   # if 2nd arg is start agent, look for start and stop as the first args.
   if ( $rargs->[1] eq "agent" )
   {
     traceDebug("AgentLifeCycle.pm: Processing $rargs->[0] agent");
    
     if ( $rargs->[0] eq "start" )
     {
        startCEMD("start");
        return $EMCTL_DONE;
     }
     elsif ( $rargs->[0] eq "asstart" )
     {
        startCEMD("asstart");
        return $EMCTL_DONE;
     }
     elsif ( $rargs->[0] eq "stop" )
     {
        $result = stopCEMD();
	@retArray = ($EMCTL_DONE,$result);
        return \@retArray;
     }
     elsif ( $rargs->[0] eq "istop" )
     {
        $result = istopCEMD();
	@retArray = ($EMCTL_DONE,$result);
        return \@retArray;
     }
     elsif ( $rargs->[0] eq "asstop" )
     {
        $result = stopCEMD();
	@retArray = ($EMCTL_DONE,$result);
        return \@retArray;
     }
     else
     {
        return $EMCTL_UNK_CMD; 
     }
   }
   else
   {
     return $EMCTL_UNK_CMD;  #UNKNOWN_COMMAND.
   }
} 

sub usage {
  print "       emctl start | stop agent\n";
}

# 
# Sub routine to start the CEMD
#
sub startCEMD
{
    my $startcmd = shift;

    my ($returnCode) = 1;
    $EMHOME = getEMHome($ENV{CONSOLE_CFG});

    traceDebug("AgentLifeCycle.pm: EMHOME is $EMHOME ");

    traceDebug("AgentLifeCycle.pm: service name is $ENV{AGENT_SERVICE_NAME} ");

    testCEMDAvail();

    if( ($IS_WINDOWS eq "TRUE" ) && ( $ENV{AGENT_SERVICE_NAME} ne "NOSERVICE"))
    {
       $returnCode = system("$ENV{WINDIR}\\system32\\net.exe start $ENV{AGENT_SERVICE_NAME}");
       $returnCode >>= 8;
       traceDebug("AgentLifeCycle.pm:Exiting with $returnCode");
       exit $returnCode;
    }

    #print "In StartCEMD \n";
    my($returnCode) = 0;

    local $curdir=cwd();      # get the current directory
    chomp($curdir);           # remove trailing spaces

    chdir("$EMHOME/sysman/emd");
    my($fh,$tmpfilename) = tempfile($UNLINK => 1, DIR => "$EM_TMP_DIR");
    close $fh; # closing to prevent file sharing violations on Windows

    my($rc) = 0xffff & system("$EMDROOT/bin/emdctl status agent >$tmpfilename 2>&1");
    $rc >>= 8;

    traceDebug("AgentLifeCycle.pm:status agent returned with retCode=$rc");
    if( $rc == 255) {
	open ($fh,"<$tmpfilename") or die "Error opening file $tmpfilename: $!\n";
	while (<$fh>) {
	    print STDERR;
	}
	close $fh or warn "Error closing file $tmpfilename: $!\n";
        unlink("$tmpfilename");
        exit -1;
    }

    unlink("$tmpfilename");

    if ( $rc < 2 )
    {
      # Start the agent and wait for 30 secs
      if( $startcmd ne "asstart") 
      {
	print "Starting agent ...";
      }
      else
      {
	print "Starting agent in process\n";
      }

      #put the marker in abbend file.
      $abendBeginTime = localtime();
      writeToEMAbbendFile("$EMHOME/sysman/log/agabend.log","$abendBeginTime");
      writeToEMAbbendFile("$EMHOME/sysman/log/agabend.log", "$EM_ABBEND_MARKER");
      
      # At the outset we need to fork, since we have to launch the
      # agent in a different process...
      # Don't fork for asstart command 
      if ($startcmd eq "asstart") 
      {
	#Need not fork
	traceDebug("AgentLifeCycle.pm:asstart launching agent in process");
      }
      elsif($IS_WINDOWS eq "TRUE")
      {
	  my($commandString) = "$PERL_BIN/perl $EMDROOT/bin/emwd.pl agent";
	  
	  #$NOHUP_FILE = $ENV{'NOHUP_FILE'};
	  
	  $CHILD_PROCESS = open3(gensym, ">&STDOUT", ">&STDERR", "$commandString");
      }
      else
      {
	$CHILD_PROCESS = fork();
      }

      if( $startcmd eq "asstart" or $CHILD_PROCESS == 0 )
      {
        if($IS_WINDOWS eq "TRUE")
        {
	  my($commandString) = "$PERL_BIN/perl $EMDROOT/bin/emwd.pl agent";
	  my($returnCode) = 0xffff & system("$commandString");
          $returnCode >>= 8;
          traceDebug("AgentLifeCycle.pm:Exiting with $returnCode");
          exit $returnCode;
        }
        else
        {
          # Need to close the STD handles
          close(STDIN);
          close(STDOUT);
          close(STDERR);

          # Assume the process group leadership...
          setpgrp(0, 0);


          $ENV{WATCHDOG_START_TIME}=time();
          #traceDebug("AgentLifeCycle.pm: Launching the watchdog process.");
          # Exec the emwd process ...
          exec("$PERL_BIN/perl $EMDROOT/bin/emwd.pl agent " .
               " $AGENT_NOHUPFILE ");
          exit 0;
        }
      }
      else 
      {
        local $tries=$EmctlCommon::EMAGENT_TIME_FOR_START_STOP;
      
        my $printFromAbend = 0;
        while( $tries > 0 )
        {
            #print "In parent, doing waipid on $CHILD_PROCESS\n";
	    if($IS_WINDOWS eq "TRUE")
	    {
		#check if process is alive
		$reaped = waitpid($CHILD_PROCESS, -1); # check without hanging
		$processStatus = $?;

		traceDebug("waitpid($CHILD_PROCESS) reaped=$reaped, processStatus=$processStatus");
		
		if($reaped != 0) 
		{
		    # process is not running. It could have exited normally or 
		    # ab.
		    traceDebug("Pid $cpid not found. reaped=$reaped, processStatus=$processStatus");

		    if($reaped == -1) 
		    {
			# we lost the xit code. somebody else reaped it.
			# we report normal exit as we don't want it restarted.
			traceDebug("Lost xit code. Assuming normal exit. processStatus=$processStatus");
		    } 
		    else 
		    {
			# value of reaped is usually the pid when process is reaped.
			my( $exit_value, $killed, $core_dumped ) = (0,0,0);
			$exit_value  = $processStatus >> 8;
			$core_dumped = $exit_value == 5;
			$killed      = $exit_value == 9;
			
			
			if ( ($exit_value == $EM_EXIT_DONT_RESTART) or 
			     ($exit_value == $EM_EXIT_THRASH) )
			{
			    $printFromAbend = 1;
			    last;
			}
		    }
		}
	    }
	    else
	    {
            $reaped = waitpid($CHILD_PROCESS, &WNOHANG);
            $processStatus = $? ;
            #print "processStatus=$processStatus, reaped=$reaped\n";
            if ( WIFEXITED($processStatus) )
            {
              $exitCode = WEXITSTATUS($processStatus);
	      traceDebug("AgentLifeCycle.pm:Watch dog processs id: $CHILD_PROCESS exited with an exit code of $exitCode");

              if ( ($exitCode == $EM_EXIT_DONT_RESTART) or 
                   ($exitCode == $EM_EXIT_THRASH) )
              {
                $printFromAbend = 1;
                last;
              }
            }
	    }
            sleep 1;

            $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$devNull 2>&1");
            $rc >>= 8;

            if ($rc == 3)
            {
                last; 
            }
            $tries = $tries-1;
            print ".";
        }
	traceDebug("AgentLifeCycle.pm: Exited loop with retCode=$rc");
        # print appropriate started or failed error message.
        if( $rc == 3 ) 
        { 
            print " started.\n"; 
            $returnCode = 0;
        }
        elsif ( $rc == 4 ) 
        { 
            print " started but not ready. \n"; 
            $returnCode = 0;
        } 
        else 
        { 
            print " failed.\n";
            if ( $printFromAbend == 1 )
            {
                printLastAbbendDetails("$EMHOME/sysman/log/agabend.log");
            }
            print "Consult the log files in: $EMHOME/sysman/log\n"; 
            $returnCode = 1;
        }
      }
    }
    else
    {
        print "Agent is already running\n";
        $returnCode = 0;
    }

    chdir("$curdir");

    exit $returnCode;
}

#
#Print the contents of abbend file since last marker on standard out.
#
sub printLastAbbendDetails()
{
  my $ag_abbend_file = $_[0];
  my $AG_ABBEND_LAST_RUN = "$ag_abbend_file" . ".lr";
  my @linesToPrint = ();

  open(ABBENDLRFILE, ">$AG_ABBEND_LAST_RUN");
  open(ABBENDRFILE, "<$ag_abbend_file");

  #Get last 4k bytes from abend file and write to abbend.lr
  seek (ABBENDRFILE, -4096, 2);
  while(read ABBENDRFILE, $buf, 4096) {
    print ABBENDLRFILE $buf;
  }

  close(ABBENDLRFILE);
  close(ABBENDRFILE);

  #Read all of abbend.lr into an array. pop the lines until abbend marker
  #is hit.
  open(ABBENDLRFILE,"<$AG_ABBEND_LAST_RUN") ;
  @abbendlines = <ABBENDLRFILE>;

  while ( $abbendline = pop @abbendlines )
  {
     chomp($abbendline);
     if ( $abbendline eq "$EM_ABBEND_MARKER" )
     {
        last;
     }
     push(@linesToPrint, "$abbendline");
  }

  #print the lines in reverse order.
  while( $lineToPrint = pop @linesToPrint )
  {
    print "$lineToPrint\n";
  }
  
}

sub stopCEMD
{
  my($returnCode) = 0;
  testCEMDAvail();

  if(($IS_WINDOWS eq "TRUE" ) && ($ENV{AGENT_SERVICE_NAME} ne "NOSERVICE"))
  {
    $returnCode = system("$ENV{WINDIR}\\system32\\net.exe stop $ENV{AGENT_SERVICE_NAME}");
    $returnCode >>= 8;
    traceDebug("AgentLifeCycle.pm:Exiting with $returnCode");
    exit $returnCode;
  }
  else
  {
    return istopCEMD();
  }
}

#
# Issues the stop for CEMD and active waits $EMAGENT_TIME_FOR_START_STOP secs
# to check wether the agent was stopped or not.
#
sub istopCEMD()
{
    $agentStatObj = AgentStatus->new();
    my($rc) = $agentStatObj->istatusCEMD();
    traceDebug("AgentLifeCycle.pm:istatusCEMD returned $rc");
    if( $rc == 255) {
      return 7;
    }
    elsif( $rc == 1) {
      print "Agent is Not Running\n";
    }
    elsif ( $rc == 3 or $rc == 4 )
    {
        my $agentPid = $agentStatObj->getPID();
        print "Stopping agent ...";

        my($fh,$tmpfilename) = tempfile($UNLINK => 1, DIR => "$EM_TMP_DIR");
        close $fh; # closing to prevent file sharing violations on Windows

        $rc = 0xffff & system("$EMDROOT/bin/emdctl stop agent >$tmpfilename 2>&1");
        $rc >>= 8;

        traceDebug("AgentLifeCycle.pm:emdctl stop agent returned $rc");
        if($rc != 4)
        {
          print "\nStop agent failed\n";
          open ($fh,"<$tmpfilename") or die "Error opening file $tmpfilename: $!\n";
          while (<$fh>) {
            print STDERR;
          }
          close $fh or warn "Error closing file $tmpfilename: $!\n";
          unlink("$tmpfilename");
          return 1;
        }
        
        unlink("$tmpfilename");

        # ping the status of agent for no more than EMAGENT_TIME_FOR_START_STOP
        # times and no more than EMAGENT_TIME_FOR_START_STOP seconds
        # if agent doesn't shutdown by then and connect attempt timed out
        # kill the agent process forcefully.

        local $tries=$EmctlCommon::EMAGENT_TIME_FOR_START_STOP;
        my $beginTime = time();
        my ($currTime, $elapsedTime);
        my($rc);
        while( $tries > 0 )
        {
           sleep 1;

           $rc = $agentStatObj->istatusCEMD();
           if ($rc < 2)
           {
              last; 
           }
           $currTime = time();
           $elapsedTime = $currTime - $beginTime;
           if ($elapsedTime > $EmctlCommon::EMAGENT_TIME_FOR_START_STOP)
           {
             last;
           }
           $tries = $tries-1;
           print ".";
        }
        traceDebug("AgentLifeCycle.pm:exited loop with $rc");
        # print appropriate started or failed error message.
        if( $rc < 2 ) 
        { 
          print " stopped.\n"; 
          return 0;
        }
        if ($rc == 2)
        {
          # do it only for Solaris in 10.2.0.5
          if ($^O eq "solaris")
          {
            # last connect timed out. kill the agent process
            traceDebug("Attempts to stop agent timed out. Generating core dumps and kill the agent.");
            $emagentObj = EMAgent->new();
            $emagentObj->Initialize($agentPid, time(), 0);
            $emagentObj->debug();
          }
        }
        else 
        { 
          print " failed.\n"; 
          return 1;
        }
    }
 
    return 0;
}


1;
