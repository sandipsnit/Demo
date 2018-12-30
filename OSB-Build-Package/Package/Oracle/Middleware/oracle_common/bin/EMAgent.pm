# $Header: emagent/scripts/unix/EMAgent.pm.template /stpl_gc_10.2.0.5.0_gen/1 2009/04/09 23:50:41 qding Exp $
#
# Copyright (c) 2001, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      EMAgent.pm - Perl Module to provide start, stop, status functionality
#
#    DESCRIPTION
#       This script provides the stop,status,debug functionality for 
#       the emwd and the emctl. Additionally it may hold other
#       states like the start time, its PID, thrashCount etc.
#
#    MODIFIED   (MM/DD/YY)
#      qding     04/06/09 - lrg 3840432, workaround the problem that gcore
#                           doesn't exist on hp prior to 11.31
#      svrrao    01/03/09 - Dont call USR2 for Windows
#      vnukal    12/06/08 - adding diag subroutines
#      svrrao    11/26/08 - Backport svrrao_bug-7553780 from main
#      svrrao    10/23/08 - XbranchMerge svrrao_bug-7444427 from main
#      bkovuri   09/10/08 - Backport bkovuri_bug-7307490 from main
#      danili    09/05/08 - Xbranchmerge svrrao_duppointers from main
#      apenmets  05/27/08 - Updating deleteExtraAgentCores to not count
#                           .threads
#      njagathe  06/02/08 - Update version to 10.2.0.5
#      qding     05/21/08 - Backport qding_bug-7045543 from main
#      danili    04/25/08 - 6978590: use gencore for aix
#      apenmets  01/31/08 - Merging Changes from stpl_emdb_main_aix
#      sunagarw  01/18/08 - Backport sunagarw_bug-6434147 from main
#      svrrao    10/29/07 - Adding gencore and lsof for AIX
#      neearora  05/23/07 - changed version to 10.2.0.4.0
#      njagathe  02/23/07 - Update version to 10.2.4.0.0
#      cvaishna  08/22/06 - fixing recalculation for EMAGENT_RECYCLE_MAXMEMORY
#      smodh     07/20/06 - change version to 10.2.0.3.0
#      smodh     07/20/06 - Backport smodh_bug_4769194_agent from main
#      smodh     12/11/05 - change version to 10.2.0.2.0 
#      vnukal    10/14/05 - deleting extra corefiles on Windows 
#      kduvvuri  07/12/05 - fix version string. 
#      sksaha    06/30/05 - Kill all threads based on pid on linux
#      sksaha    06/12/05 - Fix ls output in deleteExtraAgentCores 
#      sksaha    05/29/05 - Kill with signal 14 when hang detected 
#      vnukal    04/14/05 - fixing logic of computing maxmemory_limit 
#      vnukal    03/14/05 - Patch script callout 
#      sksaha    02/26/05 - Call debugCore for second core file generated 
#      vnukal    01/14/05 - fix conversion issue 
#      vnukal    01/10/05 - adaptable MAX MEMORY 
#      vnukal    12/28/04 - adding dump of tunable env vars 
#      sksaha    11/04/04 - use sAgentUtils 
#      sksaha    10/12/04 - Fix bug 3906405 : core file generation
#      kduvvuri  11/02/04 - You should check for 'Windows_NT' aswell as 
#                           MSWin32. 
#      kduvvuri  10/27/04 - fix dump file generation on windows as well. 
#      kduvvuri  10/26/04 - fix bug 3939606. 
#      kduvvuri  10/11/04 - bug 3835050, merge from linux port. 
#      vnukal    10/05/04 - nmupm launch only when neccasary 
#      kduvvuri  09/20/04 - fix bug 3841084, check for presence of lsof before 
#                           using it. 
#      kduvvuri  07/28/04 - Add getVersion. 
#      aaitghez  05/03/04 - bug 3358285, hang fix 
#      vnukal    03/16/04 - cr comments 
#      vnukal    03/16/04 - adding checkUploadConstraints 
#      rzkrishn  03/17/04 - going back to emdctl in stop 
#      rzkrishn  03/12/04 - Recycle functionality on windows 
#      mbhoopat  03/10/04 - linux porting exception 
#      aaitghez  02/19/04 - bug 3443139 
#      rlal      01/22/04 - Fix for bug 2988737 
#      rzkrishn  12/23/03 - review changes 
#      rzkrishn  12/22/03 - compute memIncrease 
#      rzkrishn  10/08/03 - remove extra cores. 
#      gachen    10/06/03 - redirect stderr in debug 
#      gachen    09/24/03 - generate core in mainsa 
#      dmshah    09/15/03 - 
#      dmshah    09/15/03 - Integration testing changes 
#      dmshah    09/11/03 - Adding Debug flag 
#      gachen    09/17/03 - add pfile/pstack/lsof to EMAgent 
#      vnukal    08/13/03 - fixing leading whitespace of ps o/p 
#      vnukal    08/07/03 - modify ps args to hit correct emagent 
#      rzkrishn  07/23/03 - get core always when hung
#      rzkrishn  07/22/03 - agent tells watch dog to act same as for HANG in abnormal state
#      dmshah    07/08/03 - Bug fixes from 401 branch
#      vnukal    06/17/03 - adding okToRestart method
#      dmshah    04/06/03 - dmshah_bug-2849086_mainsa
#      dmshah    03/20/03 - Only way to kill is SIGKILL
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#      dmshah    03/14/03 - Adding restart code
#      dmshah    03/13/03 - Bug fix 2849086 and moving PERL BIN
#      dmshah    03/11/03 - dmshah_em_watchdog
#      dmshah    03/09/03 - Making emctl start em compatible for VOBs
#      dmshah    03/06/03 - Adding debug core file logic
#      dmshah    03/03/03 - Fixing constructor syntax
#      dmshah    03/03/03 - Testing if..else block
#      dmshah    02/26/03 - Created.
#

package EMAgent;
require EMAgentPatch;
use strict;
use EmctlCommon;
use sAgentUtils;
use LWP::Simple;
use Time::Local;
use Config;

sub new
{
  my ($class) = @_;
  my $self =
  {
     PID => -1,
     name => undef,
     startTime => -1,
     thrashCount => 0,
     initialized => 0,
     printCounter => 0,
     lastMemChkTime => 0,
     lastUploadChkTime => 0,
     emHome => getEMHome("agent"),
     debug => 0,
     prevMemSize => 0,
     mamMemLimitSet => 0,
     memCheckImplemented => 1,
     patchObjRef => 0,
     lastTimeoutStamp => 0
  };

  # initialize PatchModule
  $self->{patchObjRef} = new EMAgentPatch();
  $self->{patchObjRef}->Initialize();
  
  bless $self, $class;
  return $self;
}

#
# Initialize 
# Ensure that the values are correct.
#
sub Initialize
{
  my $self = shift;
  my $inPID = shift;
  my $inStartTime = shift;
  my $debugFlag = shift;

  $self->{PID} = $inPID;
  $self->{startTime} = $inStartTime;
  $self->{thrashCount} = 0;
  $self->{name} = "EMAgent";
  $self->{initialized} = 1;
  $self->{printCounter} = 0;
  $self->{lastMemChkTime} = 0;
  $self->{lastUploadChkTime} = 0;
  $self->{prevMemSize} = 0;
  $self->{traceFileFound} = 1;
  $self->{lastTimeoutStamp} = 0;
  $self->{maxMemLimitSet} = 0;
  $self->{memCheckImplemented} = 1;
  $self->{debug} = $debugFlag if defined($debugFlag);

  if ($self->{debug}) {
    print("--EMAGENT_MEMCHECK_HOURS=$EMAGENT_MEMCHECK_HOURS\n");
    print("--EMAGENT_RECYCLE_DAYS=$EMAGENT_RECYCLE_DAYS\n");
    print("--EMAGENT_TIMESCALE=$EMAGENT_TIMESCALE\n");
    print("--EMAGENT_RECYCLE_MAXMEMORY=$EMAGENT_RECYCLE_MAXMEMORY\n");
    print("--EMAGENT_MAXMEM_INCREASE=$EMAGENT_MAXMEM_INCREASE\n");
  }

  #round about way of getting gmtime in seconds since 1900.
  my ($sec,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime(time);
  $self->{lastTimeoutStamp} = timegm($sec, $min, $hour,$mday,$mon,$year);

  return 1;
}

#
# status
# Checks the PID liveness test first and then uses the appropriate handler
# to check the about Page of the agent
#
sub status
{
  my($self) = @_;

  if($self->{initialized})
  {
      
      my $rc = 2;
      my $numStatusRetries = $NUMBER_AGENT_STATUS_RETRIES;
      my $patchRc = 0;

      $patchRc = $self->{patchObjRef}->status();

      if($patchRc != 1)
      {
        print "-- Patch status method returned error --\n";
        # Not sure what circumstances PatchModule status will return error.
        # Need to decide what actions need to occur in those circumstances.
      }

      while(($numStatusRetries > 0) &&
            (($rc eq 4) ||
             ($rc eq 7) ||
             ($rc eq 2)))
      {
          $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent ".
                                " $EMD_HANG_CHECK_STATUS_TIME >$devNull 2>&1");
          $rc >>= 8;
          $numStatusRetries = $numStatusRetries - 1;
      }
      
    if( $rc eq 3 )   #emAgent is UP and running...
    {
      $rc = $STATUS_PROCESS_OK;
    }
    elsif( $rc eq 4 )  #emAgent is UP but not ready... 
    { 
      $rc = $STATUS_AGENT_NOT_READY;
    }
    elsif( $rc eq 1 ) #emAgent process is dead...
    {
      $rc = $STATUS_NO_SUCH_PROCESS;
    }
    elsif( $rc eq 2 ) #emAgent is hanging ...
    {
       $rc = $STATUS_PROCESS_HANG;
    }
    elsif( $rc eq 7 ) #emAgent is in abnormal state ...
    {
       $rc = $STATUS_AGENT_ABNORMAL;
    }
    else
    {
       $rc = $STATUS_NO_SUCH_PROCESS; # This should not happen...
    }

    return $rc;
  }
}

#
# stop
# Stops the Agent
#
sub stop
{
  my($self, $tries) = @_;
        
  if($self->{initialized})
  {
   # Relying on the fact that emdctl status never fails...     
   system("$EMDROOT/bin/emdctl stop agent >$devNull 2>&1 &");
   
   my $rc;
   if ($tries eq undef )
   {
      $tries = 30;
   }

   while( $tries gt 0 )
   {
      $tries--;

      $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent ".
            " $EMD_HANG_CHECK_STATUS_TIME >$devNull 2>&1");
      $rc >>= 8;

      if ($rc lt 2) # Agent stop succeeded...
      {
         last; 
      }
      
      if($tries gt 0)
      {
         sleep 1;
      }
   }

   if($rc ge 2) # Agent is still running
   {
     print "----- Failed to stop agent! -----\n";
     print "----- Attempting to kill $self->{name} : $self->{PID} -----\n";
     kill 9, $self->{PID}; # Force a SEGKILL ...
   }
   
   return $rc;
   
  }
}


#
# gatherProcessStatistics
# Gathers process Statistics like Memory size etc
#
sub gatherProcessStatistics
{
  my($self) = @_;
  if($self->{initialized})
  {
  }
}


#
# reInitialize
# Update after a restart, the PID and the start time are changed now
# and needs to be reflected.
# 
sub reInitialize
{
  my($self, $inPID, $inStartTime) = @_;        
  if($self->{initialized})
  {
     $self->{PID} = $inPID;
     $self->{startTime} = $inStartTime;
     $self->{printCounter} = 0;
     $self->{lastMemChkTime} = 0;
     $self->{lastUploadChkTime} = 0;
     $self->{prevMemSize} = 0;
     $self->{maxMemLimitSet} = 0;
     $self->{memCheckImplemented} = 1;
     $self->{traceFileFound} = 1;
     return 0;
  }
  else
  {
     return 1;
  }
}


#
# getThrashCount
# Returns the number of restarts that has occurred
#
sub getThrashCount
{
  my($self) = @_;
  if($self->{initialized})
  {
     return $self->{thrashCount};
  }
  else
  {
     return -1;
  }
}

#
# setThrashCount
# Reset routine for the setThrashCount
#
sub setThrashCount
{
  my($self, $inThrashCount) = @_;
  if($self->{initialized})
  {
     $self->{thrashCount} = $inThrashCount;
     return 0;
  }
  else 
  {
     return 1;
  }
}

#
# incThrashCount
# Increments the thrashCount by 1
#
sub incThrashCount
{
  my($self) = @_;
  if($self->{initialized})
  {
     $self->{thrashCount}++;
     return 0;
  }
  else 
  {
     return 1;
  }
}

#
# getPID
# Returns the PID for the IASConsole
# 
sub getPID
{
  my($self) = @_;
  if($self->{initialized})
  {
     return $self->{PID};
  }
  else
  {
     return -1;
  }
}

#
# getStartTime
# Returns the start time of the IASConsole
#
sub getStartTime
{
  my($self) = @_;
  if($self->{initialized})
  {
     return $self->{startTime};
  }
  else
  {
     return -1;
  }
}

#
# getName
# Returns the Name
#
sub getName
{
  my($self) = @_;
  if($self->{initialized})
  {
    return $self->{name};
  }
  else
  {
    return undef;
  }
}

#
# debug
# Provides the Debug functionality
#
sub debug
{
  my($self) = @_;
  if($self->{initialized})
  {
    my ($tPid) = $self->{PID};
    my $EMHOME = $self->{emHome};
    my $rc = 0;
    my ($gcoreFile) = "$EMHOME"."/sysman/emd/core.hung"; #input to gcore.
    #gcore always appends 'pid' to the file name specified.
    #$coreFile contains the actual file name generated by gcore,
    my ($coreFile) = "$gcoreFile".".$tPid"; 
    my ($gcorebin)="/bin/gcore" ;
    my ($gcorecmd) = "$gcorebin"." -o "."$gcoreFile ".$tPid;;
    my($scriptFile) = "";

    #
    # Intimate the State Manager to perform a dump
    #
    if( ($^O eq "MSWin32") or ($^O eq "Windows_NT") )
    {
      ## We need some signal-based mechanism here to invoke dumpState
      ## Calling emdctl dumpState can hang, so not making a call here.
    }
    else
    {
      kill  'USR2', $self->{PID};
    }

    if($^O eq "linux")
    {
      $gcorebin="/usr/bin/gcore";
      $gcorecmd = "$gcorebin"." -o "."$gcoreFile ".$tPid;
    } #Add elsif here to create 'gcorebin' and gcorecmd' for any spl cases.

    #On windows and aix, dump file is generated with the actual file name 
    #specified. So, we use $coreFile which we generate by appending 'pid'.

    if( ($^O eq "MSWin32") or ($^O eq "Windows_NT") )
    {
      $gcorebin ="$EMDROOT/bin/userdump.exe";
      #the command is usedump.exe <pid> <filename>
      $gcorecmd = "$gcorebin"." $tPid $coreFile";
    }
    if(($^O eq "AIX") or ($^O eq "aix"))
    {
      $gcorebin="/usr/bin/gencore";
      $gcorecmd = "$gcorebin ".$tPid." $coreFile";
    } #Add elsif here to create 'gcorebin' and gcorecmd' for any spl cases.

    if ((! -e $gcorebin) and (($^O eq "HPUX") or ($^O eq "hpux")))
    {
      $scriptFile = "$EMHOME"."/sysman/emd/gencore";
      my($gdbbin) = "/opt/langtools/bin/gdb";
      open SCRIPT, ">$scriptFile" || print("Unable to open $scriptFile for writing");
      printf SCRIPT "attach $tPid\ndumpcore\nquit\n";
      close SCRIPT;
      $gcorecmd = "$gdbbin $EMDROOT/bin/emagent <$scriptFile";
    }

    #
    # generate gcore 
    #
    if (( -e $gcorebin ) or ($scriptFile ne ""))
    {
      print "----- ".localtime()."::generate first core file for diagnosis -----\n";
      $rc = 0xffff & system("$gcorecmd");
      $rc >>= 8;
      if($rc != 0)
      {
        # error running core dump command
        print "----- ".localtime()."::Error running $gcorecmd : $! \n";
      }

      # gdb generates core file in core.$pid format, rename it
      if ($scriptFile ne "")
      {
        my($gdbcorefile) = "$EMHOME"."/sysman/emd/core.$tPid";
        if (-e $gdbcorefile)
        {
          rename $gdbcorefile, $coreFile;
        }
      }

      my($currTime) = time();

      if( -e $coreFile )
      {
        rename $coreFile, $coreFile."_".$currTime;
        print "----- ".localtime()."::core file ".$coreFile."_".$currTime." generated -----\n";
        $self->debugCore( $coreFile."_".$currTime);
        $self->debugHang( $coreFile."_".$currTime);
      }

      #
      # sleep 10 seconds.
      #
      sleep 10;

      #
      # generate second gcore
      #
      print "----- ".localtime()."::generate second core file for diagnosis -----\n";
      $rc = 0xffff & system("$gcorecmd");
      $rc >>= 8;
      if($rc != 0)
      {
        # error running core dump command
        print "----- ".localtime()."::Error running $gcorecmd : $! \n";
      }

      # gdb generates core file in core.$pid format, rename it
      if ($scriptFile ne "")
      {
        my($gdbcorefile) = "$EMHOME"."/sysman/emd/core.$tPid";
        if (-e $gdbcorefile)
        {
          rename $gdbcorefile, $coreFile;
        }
      }

      if( -e $coreFile )
      {
        rename $coreFile, $coreFile."_".$currTime . "_10s_after" ;
        print "----- ".localtime()."::core file ".$coreFile."_".$currTime."_10s_after generated -----\n";
        $self->debugCore( $coreFile."_".$currTime."_10s_after");
        $self->debugHang( $coreFile."_".$currTime."_10s_after");
      } 
    }
    else
    {
      print "----- ".localtime()."::INFO Skipping core file generation for diagnosis. Binary '$gcorebin' does not exist \n";
    }

    unlink("$scriptFile") if (-e $scriptFile);
 
    #
    #  generate lsof to see the fd usage
    #
    if(($^O ne "MSWin32") && ($^O ne "Windows_NT"))
    {
      print "----- ".localtime()."::generate $coreFile.lsof.1 for diagnosis -----\n";
      if ( -r "/etc/SuSE-release" ) {
        system("/usr/bin/lsof -p $tPid > $coreFile.lsof.1 2>&1");
      }
      elsif  ( -r "/etc/redhat-release") {
        system("/usr/sbin/lsof -p $tPid > $coreFile.lsof.1 2>&1");
      }
      elsif ( -x "/usr/local/bin/lsof" )
      {
        system("/usr/local/bin/lsof -p $tPid > $coreFile.lsof.1 2>&1");
      }
      elsif ( -x "/usr/sbin/lsof" )
      {
        system("/usr/sbin/lsof -p $tPid > $coreFile.lsof.1 2>&1");
      }
    }

    print "----- Attempting to kill $self->{name} : $self->{PID} -----\n";
    if ( $^O eq "linux" )
    {
        # On Linux the threads of a process are represented as separate
        # processes on the OS, so we need to kill all the threads
        # which are obtained using ps.
        $self->killProcessAndThreads( $self->{PID} );
    }
    else
    {
       kill $EMCTL_CORE_SIGNAL, $self->{PID}; # Force a kill with SIGKILL ...
    }

    return 0;
  }
}

sub killProcessAndThreads
{
  my($self, $pid) = @_;

  # First lets recursively kill the child threads ...
  my(@procs) = `/bin/ps -emlf`;
  my $proc = "";
  foreach $proc (@procs)
  {
    if ( $proc =~ m/$pid/ )
    {
      my @cols = split ( /\s+/ , $proc );

      # Check if parent id matches this pid, then kill the child
      if ( $pid == $cols[4] )
      {
        $self->killProcessAndThreads ( $cols[3] );
      }
    }
  }

  # Now lets kill the original thread
  kill $EMCTL_CORE_SIGNAL, $pid;
}


#
# debugHang
# DebugHang is called when the monitor detects a hang
#
sub debugHang
{
  my($self, $debugFile) = @_;
  my ($tPid) = $self->{PID};
  my ($pstackbin)="/usr/bin/pstack" ;
  my ($pstackcmd)="$pstackbin" . " ". $tPid ;
  my ($traceBack) = $debugFile.".traceback";
  my $rc = 0;
  
  if(($^O eq "HPUX") or ($^O eq "hpux"))
  {
    $pstackbin = "/usr/ccs/bin/pstack";
    $pstackcmd = "$pstackbin" . " ". $tPid ;
  }
  elsif (($^O eq "AIX") or ($^O eq "aix"))
  {
    $pstackbin = "/usr/bin/procstack";
    $pstackcmd = "$pstackbin" . " ". $tPid ;
  }
  
  if ( -e $pstackbin )
  {
    print "----- ".localtime()."::generate pstack file for diagnosis -----\n" if $DEBUG_ENABLED;
    open (TRACEBACK, ">>$traceBack") || print("Unable to open $traceBack file. $!");
    print TRACEBACK "\n #### PSTACK OUTPUT #### \n";
    close(TRACEBACK);

    $rc = 0xffff & system("$pstackcmd >> $traceBack");
    $rc >>= 8;
    if($rc != 0)
    {
      # error running core dump command
      print "----- ".localtime()."::Error running $pstackcmd : $! \n" if $DEBUG_ENABLED; 
    }
  }
}

# debugCore
# DebugCore is called when the monitor detects a core dump
# Parameter : CoreFile
#
sub debugCore
{
  my($self, $debugFile) = @_;
  sAgentUtils::sDebugCore($self, $debugFile);
}

#
# Delete extra cores.
#
sub deleteExtraAgentCores 
{
  my ($agentHome) = @_[0];
  my ($deletecores) = $agentHome."/sysman/emd/deletecores.tmp";
  my (@lines) ;
  my (@files) ;
  my ($count)  = 0;
  my ($LS) = "/bin/ls";
  
  if ( -e $LS ) 
  {
    # defaulting to 3 cores(core + .traceback)
    my ($maxCores) = 6; 
 
    if (defined($ENV{EMAGENT_MAX_CORES}))
    {
      $maxCores = $ENV{EMAGENT_MAX_CORES};
      $maxCores = $maxCores * 2;
    }

    @files = system ("$LS -tr $agentHome/sysman/emd/core* > $deletecores" );
 
    open (DELETECORES, $deletecores);
 
    while (<DELETECORES>)
    {
      chomp($_);
      push @lines, $_;
      $count++;
    }
    close (DELETECORES);
    unlink("$deletecores");
 
    if ( ($count + 2) <= $maxCores ) 
    {
      return;
    }
    else
    {
      my ($deleteCount) = $count + 2 - $maxCores;  
 
      while ($deleteCount > 0)
      {
        unlink(@lines[$deleteCount-1]);
        $deleteCount --;
      }
    }
  }
}

#
# recycle
# Checks wether the current process requires a recycle or not.
# 
sub recycle
{
  my($self) = @_;        
  if($self->{initialized} == 0)
  {
      return "FALSE";
  }

  my $rc = "FALSE";

  $rc = $self->checkMemConstraints();
  if ($rc eq "TRUE") {
      return $rc;
  }
  
  $rc = $self->checkUploadConstraints();
  
  return $rc;
}

sub checkMemConstraints
{

  my($self) = @_;        
  if($self->{initialized} == 0)
  {
      return "FALSE";
  }

  my($recycleInterval,$recycleSecs);
  my($memCheckInterval) = $EMAGENT_MEMCHECK_HOURS * 3600;
  my($currTime) = time();
  my($implemented) = 0;
  my($vmSize) = 0;

  $recycleSecs = 3600/$EMAGENT_TIMESCALE;
  $recycleInterval = $EMAGENT_RECYCLE_DAYS * 24 * $recycleSecs;

  # Restart the agent every $EMAGENT_RECYCLE_DAYS. Default is never
  if($recycleInterval > 0 ) {
    my($timeSinceStart) = $currTime - $self->{startTime};
    if($timeSinceStart > $recycleInterval)
      {
        my($timeSinceStart_hour) = $timeSinceStart / 3600;
        print "--- Recycling process. Up for $timeSinceStart_hour hours ---\n";
        return "TRUE";
      }
  }

  if($self->{lastMemChkTime} == 0) # this check acting as first time flag
    {
      $self->{lastMemChkTime} = $currTime;
      ($implemented, $vmSize) = $self->getVMUsage();
      $self->{prevMemSize} = $vmSize/1024; # Convert to MB
      print(localtime()." -- First VM size is $vmSize\n") if ($self->{debug});
      print(localtime()." -- MemCheck implemented is $implemented\n") if ($self->{debug});
      $self->{memCheckImplemented} = $implemented;

      print("Recycle Agent functionality disabled as VMSize checking not implemented on this platform ($^O)\n") if ($implemented == 0);

      return "FALSE";
    }

  if($self->{memCheckImplemented} == 0 || $memCheckInterval <= 0) {
    return "FALSE";
  }


  my($timeSinceStarted) = $currTime - $self->{startTime};

  if(($self->{maxMemLimitSet} == 0) && ($timeSinceStarted >= 300)) {

    $self->{maxMemLimitSet} = 1;

    if($EMAGENT_RECYCLE_SOFTLIMIT eq "TRUE") {
      ($implemented, $vmSize) = $self->getVMUsage();

      $self->{prevMemSize} = $vmSize/1024;
      print(localtime()." VMSize after 5 min is $self->{prevMemSize}\n") if ($self->{debug});
      # Set computedSize = current + 100MB
      my $computedSize = ($vmSize + 102400)/1024;
      print(localtime()." Computed size is $computedSize\n") if ($self->{debug});
      # Set the maxmemory to larger of computedSize & EMAGENT_RECYCLE_MAXMEMORY
      if( !defined($EMAGENT_RECYCLE_MAXMEMORY) )
      {
          $EMAGENT_RECYCLE_MAXMEMORY = $computedSize;
      }
      elsif ( $EMAGENT_RECYCLE_MAXMEMORY < $computedSize )
      {
          $EMAGENT_RECYCLE_MAXMEMORY = $computedSize;
      }
    }

    print(localtime()." EMAGENT_RECYCLE_MAXMEMORY set to $EMAGENT_RECYCLE_MAXMEMORY\n") if ($self->{debug});

  }

  my($timeSinceLastCheck) = $currTime - $self->{lastMemChkTime};

  if($timeSinceLastCheck < $memCheckInterval)
    {
      return "FALSE";
    }

  $self->{lastMemChkTime} = $currTime;
  
  ($implemented, $vmSize) = $self->getVMUsage();
      
  if ($implemented == 1)
    {
      $vmSize = $vmSize/1024; # Change to MB

      print(localtime()." Current Agent vmSize is $vmSize MB\n") if($self->{debug});
      if( $vmSize > $EMAGENT_RECYCLE_MAXMEMORY )
        {
          my $memIncrease = $vmSize - $self->{prevMemSize} ;
          print(localtime()." Memory Increase is $memIncrease\n") if($self->{debug});
          if ($memIncrease > $EMAGENT_MAXMEM_INCREASE) 
            {
              print "--- Recycling process. VMSize is $vmSize MB increased by $memIncrease MB in past $EMAGENT_MEMCHECK_HOURS ---\n";
              return "TRUE";
            }
        }
      $self->{prevMemSize} = $vmSize;
    }
  
  return "FALSE";
}


sub getVMUsage
{
  my($self) = @_;        
  if($self->{initialized} == 0)
  {
      return "FALSE";
  }

  my($implemented) = 0;
  my($vmSize) = 0;
  my($pid) = 0;

  $pid = $self->{PID};

  $ENV{UNIX95} = "XPG4" if($^O eq "hpux");
  
  if(($^O eq "SunOS") or ($^O eq "solaris") or ($^O eq "linux") or
     ($^O eq "aix") or ($^O eq "hpux") or ($^O eq "darwin"))
    {
      my($tpid,$pvmSize) = (`ps -p $pid -o "pid,vsz"`)[1] =~ m/(\w+)\s+(\w+)/g;
      
      return "FALSE" if($pid != $tpid);
      
      chomp($pvmSize);
      
      $vmSize = $pvmSize;
      
      $implemented = 1;
    }
  elsif (($^O eq "MSWin32") or ($^O eq "Windows_NT"))
    {
      my($result) = (`$EMDROOT/bin/nmupm procInfo $pid`);
      
      my($tpid,$cpu,$pvmSize,$resmSize,$remain) = split(/\|/, $result, 5);
      
      chomp($pvmSize);
      
      $vmSize = $pvmSize;
      
      $implemented = 1;
    }
  elsif ($^O eq "dec_osf")
    {
      my $ignore = '';
      my($tpid,$pvmSize) = (`ps -p $pid -o "pid,vsz"`)[1] =~ m/(\w+)\s+(.*)/g;
      
      return "FALSE" if($pid != $tpid);
      
      chomp($pvmSize);
      
      $vmSize = $pvmSize;
      
      $implemented = 1;
      
      # The memory usage on Tru64 is given with the size suffix
      # (e.g. 2.04M). This should be parsed and converted to KB.

      if ($vmSize =~ /K/) # KB
      {
        ($vmSize, $ignore) = split('K', $vmSize);
      }
      elsif ($vmSize =~ /M/) # MB
      {
        ($vmSize, $ignore) = split('M', $vmSize);
        $vmSize *= 1024;
      }
      elsif ($vmSize =~ /G/) # GB
      {
        ($vmSize, $ignore) = split('G', $vmSize);
        $vmSize *= 1024 * 1024;
      }
    }

  return ($implemented, $vmSize);
}  

sub checkUploadConstraints
{
    my($self) = @_;        
    if($self->{initialized} == 0)
    {
        return "FALSE";
    }

    my ($rc) = "FALSE"; # donot recycle
    
    my $currTime = time();
    my($uploadCheckInterval) = $EMAGENT_MEMCHECK_HOURS * 3600;

    if($uploadCheckInterval <= 0)
    {
        return "FALSE";
    }

    if($self->{lastUploadChkTime} == 0)
    {
        $self->{lastUploadChkTime} = $currTime;
        return "FALSE";
    }
    
    my($timeSinceLastCheck) = $currTime - $self->{lastUploadChkTime};
    if($timeSinceLastCheck < $uploadCheckInterval)
    {
        return "FALSE";
    }
    $self->{lastUploadChkTime} = $currTime;

    # checking status of the upload dat files
    # errors.dat
    # severity.dat
    # rawdata0.dat and up

    $rc = checkFileTimeStamp($currTime,$self->{emHome}."/sysman/emd/upload/errors.dat");
    if( $rc eq "TRUE") { return $rc };
    # will not match rawdata.dat, but only numbered rawdata0 and up files
    # will also match filenames like rawdata0bar.dat, but doubt such filenames
    # will exist.
    my($nextRawdataFile);
    while(defined($nextRawdataFile=glob($self->{emHome}."/sysman/emd/upload/rawdata[0-9]*.dat")))
    {
        $rc = checkFileTimeStamp($currTime, $nextRawdataFile);
        if( $rc eq "TRUE") { return $rc };
    } 
    $rc = checkFileTimeStamp($currTime,$self->{emHome}."/sysman/emd/upload/severity.dat");
     return $rc
}

sub checkFileTimeStamp
{
    my ($currTimeSecs, $fileToCheck) = @_;

    my ($year,$month,$day,$hour,$minute,$second)=(0,0,0,0,0,0);

    if (! -e $fileToCheck) {
        return "FALSE" ;
    }
    
    unless ( open (FILETOPARSE,"<$fileToCheck")) {
        print "-- Unable to open file $fileToCheck --\n";
        return "FALSE";
    }
    
    while (<FILETOPARSE>) {
        # finding first occurence will give us the earliest timestamp
        if (/COLLECTION_TIMESTAMP/)
        {
            ($year,$month,$day,$hour,$minute,$second) = /(\d+)\-(\d+)\-(\d+)\W+(\d+):(\d+):(\d+)/ ;
            last;
        }
    }
    close FILETOPARSE;

    if( $year == 0) {
        # we did not hit any timestamp string
        return "FALSE";
    }
        
    # month is 0...11 so subtracting by 1
    my $timeStampSecs = timelocal($second,$minute,$hour,$day,$month-1,$year);

    # currentTime greater than 24 hours of the earliest timestamp found in
    # file
    if ($currTimeSecs > ($timeStampSecs + (24*60*60))) {
        print "-- Timestamp ($year,$month,$day,$hour,$minute,$second) of file $fileToCheck is more than 24 hours old. Current Time is ".localtime;
        return "TRUE";
    }
    else {
        return "FALSE";
    }
    return "FALSE";
}
#
# okToRestart
# Determines if sufficient resources or conditions exist for the component
# to be started
# 
sub okToRestart
{

  my($self) = @_;
  if($self->{initialized})
  {
    if(($^O eq "SunOS") or ($^O eq "solaris")) {

      my $rc;
    
      # agentok script returns 0 when it is Ok to start the agent. Non-zero
      # return code otherwise.  
      $rc = 0xffff & system("$EMDROOT/bin/agentok.sh >$devNull 2>&1");
      $rc >>= 8;

      if($rc != 0) # Insufficient resources exist.
      {
        if (($self->{printCounter} % 120) == 0) {
          print "---- Insufficient resources exist to restart agent -----\n";
          $self->{printCounter} = 0;
        }
        $self->{printCounter} ++;
        return "FALSE";
      }
    }
  }
  else
  {
    return undef;
  }

  return "TRUE";
}

sub getVersion
{
    print "       Enterprise Manager 10g Agent Version 10.2.0.5.0\n";
}

sub checkDynPropsTimeout {
  my($self) = @_;
  if($self->{initialized})
  {
    my ($tPid) = $self->{PID};
    my $EMHOME = $self->{emHome};
    my $rc = 0;

    if($self->{traceFileFound}==0) {
      return;
  }

    my ($year,$month,$day,$hour,$minute,$second)=(0,0,0,0,0,0);

    my $fileToCheck = $EMHOME."/sysman/log/emagent.trc";

    if (! -e $fileToCheck) {
      print "----- ".localtime()."checkDynPropsTimeout:: file not found $fileToCheck\n";
      $self->{traceFileFound} = 0;
      return;
    }

    unless ( open (FILETOPARSE,"<$fileToCheck")) {
        print "-- Unable to open file $fileToCheck --\n";
        return;
    }
    
    while (<FILETOPARSE>) {
        # finding first occurence will give us the earliest timestamp
        if (/TIMEOUT reached in computing dynamic properties for target/)
        {
            ($year,$month,$day,$hour,$minute,$second) = /(\d+)\-(\d+)\-(\d+)\W+(\d+):(\d+):(\d+)/ ;
        }
    }
    close FILETOPARSE;

    if( $year == 0) {
        # we did not hit any timestamp string
        return;
    }

    # month is 0...11 so subtracting by 1
    my $timeStampSecs = timegm($second,$minute,$hour,$day,$month-1,$year);
    if($timeStampSecs > $self->{lastTimeoutStamp})
    {
      my @agentChildren = `ps -o "pid ppid comm" | grep $tPid`;
      $self->{lastTimeoutStamp} = $timeStampSecs;
      my $num=0;
      my $entry;
      foreach $entry (@agentChildren)
      {
	my ($pid, $ppid, $arg) = split(' ',$entry);
	$arg = lc($arg);
	if($ppid == $tPid &&  $arg eq "perl")
	{
	  $num++;
	  my $targetDumpFile = $EMHOME."/sysman/emd/perl_".$timeStampSecs."_".$num.".dmp";
	  if(-e "$EMDROOT/bin/userdump.exe") 
	  {
	      system("$EMDROOT/bin/userdump.exe $pid $targetDumpFile");
	  }
	  else {
	      print "------".localtime()."$EMDROOT/bin/userdump.exe not found while trying to dump Process (pid=$pid)\n";
	  }
	}
      }
    }
  }
}


1;
