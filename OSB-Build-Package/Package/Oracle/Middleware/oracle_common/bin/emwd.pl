# $Header: emagent/scripts/unix/emwd.pl.template /st_emagent_10.2.0.1.0/6 2009/01/20 23:13:26 vnukal Exp $
#
#
# Copyright (c) 2001, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      emwd.pl - Perl script to provide the watchdog functionality for 
#                the Consoles and the agent
#
#    DESCRIPTION
#       This script provides the Process Monitor functionality for 
#       the console and the agents
#
#    USAGE
#      emwd <COMPONENT> <NOHUP FILENAME>
#      where the 
#        <COMPONENT> : Is either iASConsole or DBConsole or EMAgent 
#        <NOHUP>   : Is the nohup destination for the Command
#
#     Process Monitoring functionality
#      The process monitoring functionality is a two step process.
#      Step 1 : Check for the existence of the Process ID from the PID FILE. 
#               If success go to Step 2
#      Step 2 : Check for the "liveness" of the Process. 
#               The "liveness" is accomplished as follows :
#               a. If iASConsole or DBConsole
#                  Do HTTP get aboutApplication URL. 
#                   If succeed, process is alive go check for agent liveness 
#                   else step 3
#                  Do emdctl status agent. If agent is down go to step 4
#               b. if emagent
#                  Do emdctl status agent. If agent is down go to step 5.
#      Step 3 : Means that the console is down, agent status unknown[up or down]
#               Reap the child console process [using non-block waitpid]
#                   If normal exit, then we stop agent and exit...
#               If not normal exit...
#               Check for Console Thrashing. 
#               If not thrashing....
#                  Start Console.
#               If thrashing,
#                  bring both console+agent down
#                  exit
#      Step 4 : Means that the agent is down, console status unknown[up or down]
#               Reap the child agent process [using non-block waitpid]
#                       If normal exit, then we stop[kill] console[?] and exit..
#               If not normal exit...
#               Check for agent Thrashing. If not thrashing....
#                  Start Agent
#               If thrashing,
#                  bring both agent+console down.
#                  exit
#      Step 5 : Means that we care only about agent
#               Check for Thrashing. If not thrashing....
#               Start agent if down and the child reaper indicates abnormal exit.
#      Thrashing : If any process has to be restarted more than 3 times in last 10 minutes, it is thrashing.
#                  We will keep separate counters for iASConsole+agent, DBConsole+agent, agent only
#
#      Startup
#       If the Command is either iASConsole or DBConsole,
#          
#       emctl kicks off emwd for the appropriate processes [agent+Console] or 
#                                                          [agent]
#       
#       Then falls into the watchdog loop...
#
#       Starting Console+Agent
#
#             Check wether Console+Agent is running [emctl part]
#             If [Console+Agent] Running,
#                Ask to restart.
#                If restart
#                   Shutdown Console+Agent, restart Console+Agent
#               
#            If [Console only] or [Agent only] Running 
#             Ask to restart. 
#                If restart
#                   Shutdown Console+Agent, restart Console+Agent
#
#      Stop
#       emwd exits out of the loop when any child process exits normally....
#
#    MODIFIED   (MM/DD/YY)
#      vnukal    01/17/09 - removing perldumping
#      vnukal    12/05/08 - adding diag subroutines
#      svrrao    11/12/08 - Backport svrrao_bug-6905275 from main
#      sunagarw  04/15/08 - XbranchMerge sunagarw_bug_5923916 from main
#      swexler   01/31/08 - fix for windows taskkill 
#      vnukal    10/14/05 - deleting extra corefiles on Windows 
#      kduvvuri  09/11/05 - abbend support. 
#      sunagarw  09/09/05 - bug-4588159 Fixing reapChild for NT 
#      sksaha    07/04/05 - Add reapChildOnExit subroutine 
#      sksaha    06/13/05 - Check for agent self exit before checking for hang 
#      sksaha    05/27/05 - Restart process after hang or abnormaility 
#      sksaha    02/10/05 - Add sleep after debug call due to hang and before 
#                           reapchild 
#      sksaha    01/24/05 - Bug-3146096, enhance nohup messages 
#      kduvvuri  11/04/04 - fix bug 3985623 
#      vnukal    09/17/04 - reaping pid on Windows 
#      gan       09/13/04 - fix perl open syntex 
#      kduvvuri  08/24/04 - remove dead code. 
#      gan       08/19/04 - bug 3505491 
#      njagathe  08/03/04 - Stop complaining about not finding coredump for NT 
#      njagathe  08/03/04 - Core file name different on Linux 
#      kduvvuri  07/22/04 - set EMCTL_PLUG_AND_PLAY. 
#      kduvvuri  07/09/04 - export NOHUP_FILE in the env. 
#      kduvvuri  06/16/04 - move launch component into its own pacakge. 
#      kduvvuri  06/08/04 - have plug and play env variable. 
#      kduvvuri  06/01/04 - activate DBConsole. 
#      kduvvuri  05/06/04 - emctl plug and play for agent.
#      aaitghez  05/03/04 - bug 3358285, hang fix 
#      jsutton   03/05/04 - Make sure all EMDW_4.0.1 changes made it to AS10.0.2
#      njagathe  01/21/04 - Review comments 
#      njagathe  01/20/04 - Fix comment 
#      njagathe  01/20/04 - Wake up more often to check for exited processes 
#      mbhoopat  12/21/03 - Fix bug 3120377 
#      rzazueta  12/16/03 - Add hang detection timeout 
#      rzazueta  12/01/03 - Deprecate password to shutdown DBConsole 
#      kduvvuri  11/20/03 - accept time zones of the form [+,-]HH:MM 
#      kduvvuri  11/06/03 - check for supportedTZ, only if REPOSITORY_URL is 
#                           present.
#      rzazueta  11/05/03 - Fix bug 3164505: Deprecate password to shutdown IASConsole
#      gachen    11/05/03 - check rc before call reap again 
#      gachen    11/04/03 - 3227492: restart agent when hang
#      vnukal    10/15/03 - isalive on NT 
#      vnukal    10/14/03 - WIN:defaulting exitCode in reapChild 
#      njagathe  10/10/03 - Also check for process status 
#      njagathe  10/10/03 - Fix for bug 3006402 
#      kduvvuri  10/07/03 - change the location of supportedtzs.lst to 
#                           $ORACLE_HOME/sysman/admin.
#      rzazueta  09/28/03 - Fix bug 3164310 
#      dmshah    09/17/03 - 
#      dmshah    09/17/03 - Code review changes 
#      dmshah    09/15/03 - 
#      dmshah    09/15/03 - Integration testing changes 
#      dmshah    09/11/03 - Check for stack dump during stop 
#      dmshah    09/09/03 - 
#      kduvvuri  08/19/03 - fix bug 3099682. Update emd.properties in EMHOME 
#                           insteaad of ORACLE_HOME 
#      kduvvuri  07/28/03 - fix updateTZ. bug 2994615
#      kduvvuri  07/24/03 - exit, if can't determine the time zone region.
#      rzkrishn  07/22/03 - Agent telling watch dog to behave for its abnormal state as in HANG
#      dmshah    07/21/03 - internal command syntax to start agent is "agent"
#      dmshah    07/18/03 - Fixing save of PID on NT
#      dmshah    07/08/03 - Adding NT svc hookup for emctl/emwd
#      kduvvuri  07/08/03 - make a backup copy of emd.properties before 
#                           updating it with  'agentTZRegion'
#      kduvvuri  07/08/03   before lauching the agent search 
#                           emd.properties for the property agentTZRegion,
#                           if it not present update it with the value 
#                           obtained thru JAVA api  
#      dmshah    06/25/03 - Modifying emwd.pl for NT
#      szhu      06/18/03 - MAINSA setup on NT
#      vnukal    06/17/03 - adding okToRestart method
#      hsu       06/13/03 - add mem param
#      njagathe  06/12/03 - Create last run copy of nohup
#      dmshah    05/16/03 - grabtrans 'dmshah_fix_emagentdeploy_beta1'
#      dmshah    05/14/03 - 
#      dmshah    05/14/03 - For CFS-RAC, need to specify the jsputilloc
#      dmshah    05/06/03 - Adding extra property EMSTATE for CFS
#      dkapoor   04/25/03 - impl dynamic deploy
#      dmshah    04/17/03 - No thrashcount increment on process initiated restart
#      dmshah    04/08/03 - Modifying the startup for CFS
#      dmshah    04/06/03 - Fixing implicit shell launch
#      dmshah    04/02/03 - Adding func for monitoring dbConsole
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_oc4j_startup'
#      rpinnama  04/02/03 - rpinnama_bug-2835783_main
#      dmshah    04/07/03 - Review comments
#      dmshah    04/07/03 - Removing shell specific metacharacters while launching console
#      rpinnama  03/31/03 - Add -Djava.awt.headless while starting SA console
#      dmshah    03/28/03 - Additional timeout parameter for first time startup
#      dmshah    03/20/03 - Only way to kill is SIGKILL
#      dmshah    04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#      dmshah    03/18/03 - Adding separate print routine for core dump messages
#      jsutton   03/14/03 - Disco needs java2.policy
#      dmshah    03/13/03 - Bug fix 2849086 and moving PERL BIN
#      dmshah    03/11/03 - dmshah_em_watchdog
#      dmshah    03/10/03 - Adding extra print statements for tvmaq logs
#      dmshah    03/09/03 - Making emctl start em compatible for VOBs
#      dmshah    03/06/03 - Using signal 0 for process liveness
#      dmshah    03/03/03 - Correcting the nohup file locations
#      dmshah    03/03/03 - Fixing restartonHang
#      dmshah    02/26/03 - Adding code for monitoring processes
#      dmshah    02/19/03 - Created.

use LWP::Simple;
use POSIX ":sys_wait_h"; # This gives us waitpid. 
use EmctlCommon;
use EMAgent;

use Config;
use POSIX ;
use File::Copy cp;
use File::Basename;

my @signame; # This is the signal table...

# Set up the signal table ...
# This does not seem to work...
# defined $Config{sig_name} || die "No sigs?";
# foreach $name (split(' ', $Config{sig_name})) 
# {
# 	$signame[$i] = $name;
# 	$i++;
#}


# Process states for the child processes ...
$PROCESS_OK=0;           # Process is okay [alive]
$PROCESS_EXIT_NORMAL=1;  # Process has exited normally...
$PROCESS_EXIT_SIGNAL=2;  # Process has exited due to signal
$PROCESS_DUMPED_CORE=3;  # Process has dumped core...

$CONSOLE_START_TIME = 0;
$AGENT_START_TIME = 0;

$EMWD_MONITOR_WAIT_TIME=30;
$EMWD_PROCESS_CHECK_FACTOR=10; # Check 10 times in every 30 seconds 

# Resolving the input command string ....
# Usage : perl emwd [iASConsole|DBConsole|emAgent] <nohup file>
# The input command string ...
my @COMMAND_STR=@ARGV;
my $COMMAND = lc($COMMAND_STR[0]);

my $EM_OC4J_HOME=getOC4JHome($COMMAND);
$EMHOME=getEMHome($COMMAND);
$ENV{'EMHOME'} = $EMHOME;

printDebugMessage("emwd has resolved the Homes to $EM_OC4J_HOME and $EMHOME");

my ($STARTUP_TIMEOUT, $HANG_DETECTION_TIMEOUT) = getTimeouts($EMHOME);

# Assign NOHUP_FILE if not part of the command string ...
if ($NOHUP_FILE eq "")
{
  if($COMMAND eq "iasconsole")
  {
    $NOHUP_FILE = $IAS_NOHUPFILE;
  }
  elsif( $COMMAND eq "dbconsole")
  {
    $NOHUP_FILE = $DB_NOHUPFILE;
  }
  else
  {
    $NOHUP_FILE = $AGENT_NOHUPFILE;
  }
}
$ENV{'NOHUP_FILE'} = $NOHUP_FILE;

printDebugMessage("Nohup file for output is $NOHUP_FILE");

open(NOHUPFILE, ">>$NOHUP_FILE") || die "Could not write to $NOHUP_FILE \n";
select(NOHUPFILE);
$|=1; # Set AUTOFLUSH on

open(STDOUT, ">>&NOHUPFILE"); # Redirect the stdout & stderr to nohup
                                # dup filehandle
open(STDERR, ">>&NOHUPFILE");

$component = $ARGV[0];
$moduleName = "LaunchEM$component";
$reqPkg = "$moduleName"."\.pm";
require $reqPkg;

$obj = $moduleName->new();

$refComponents = $obj->launchComp(\@ARGV);
$exitCode = monitor($refComponents);
close(NOHUPFILE);

#porting note: For now exiting with '0' on windows. This should be changed
#when writing to abend file is implemented on windows.
if( $IS_WINDOWS eq "TRUE" )
{
  exit 0;
}
else
{
  exit $exitCode;
}


#
# monitor
# Accepts a reference table of the following format
# The following are subscripts
#    0               1             |baseCtr        
# console[0]     launchIASConsole  |  0
# emagent[2]     launchAgent       |  2
# [dbconsole][4] [launchDb]        |  4 [in future]
# 
# NOTE : ANY ADDITION OR SUBTRACTION OF COLUMNS TO THE ABOVE NEED TO BE
# REFLECTED IN $NUM_COLS variable below
#
# Takes the following sequence in a loop
# 1. sleeps for <m> seconds
# 2. Call status() on the component object.
# 3. If the status returns bad or no process state
# 4. reapChild
# 5. If the child has exited normally. Exit loop
# 6. If the child has died abnormally, call restartHandler on that comp
# 6. If the child has died abnormally and is in hung state.. 
#       call debughandler on that comp
# 7. Update PID and ThrashCount accordingly...
# 8. If the component is thrashing, exit after stopping the rest of the comps.
# Thrashing : 3 Restarts in 10 minutes.
#
sub monitor
{
  my ($input_array_ref) = @_;
  my $exitCode = 0;

  # Type cast the input array reference to the array itself.
  my( @components ) = @$input_array_ref;

  # Unfortunately, PERL does not provide true array of arrays.
  # Count the number of rows. (= components)
  # We divide the total by the number of columns...

  my($NUM_COLS) = 2;
  my($NUM_COMPONENTS) = (scalar(@components)/$NUM_COLS); 
 
  printDebugMessage("EMWD. Monitoring $NUM_COMPONENTS Components.");

  # Establish the offsets...
  my($object_offset, $restart_offset) = (0,1);
  my ($normalShutdown) = "FALSE";

  # marked all components as just started
  my @compJustStarted;
  for $i ( 0 .. ($NUM_COMPONENTS-1) ) 
  {
    $compJustStarted[$i] = 1;
  }

  my $checkIterMod = 0;

  while($NUM_COMPONENTS > 0)
  {
    # Sleep for the given amount of time ...
    sleep $EMWD_MONITOR_WAIT_TIME / $EMWD_PROCESS_CHECK_FACTOR ;

    $checkIterMod = ($checkIterMod + 1) % $EMWD_PROCESS_CHECK_FACTOR;
  
    if($checkIterMod == 0)
    {
      printDebugMessage("EMWD Checking status of components...");
    }
    else
    {
      printDebugMessage("EMWD Checking component processes... $checkIterMod");
    }
    
    # Iterate over the components,
    # Check for status
    # If status is not ok
    #    reapChild
    # Increment the thrashing count and if thrashes, prepare to exit.

    for($i=0, $baseCtr=0; $i < $NUM_COMPONENTS; $i++, $baseCtr+=2)
    { 
      my($objRef, $name, $pid, $rc);

      # Get the objectReference..      
      $objRef = $components[$baseCtr+$object_offset];
      
      $name = $objRef->getName();
      $pid=$objRef->getPID();

      printDebugMessage("EMWD. Checking Status for $name $pid");
      
      # Reap the child .... returns an array.
      # [0] : How the process exited [normal/signal/coredump].
      # [1] : Exit code/Signal Code
      local (*processExit) = reapChild( $pid, $name );

      my $timeout = $HANG_DETECTION_TIMEOUT;
      if ( $compJustStarted[$i] )
      {
        $timeout = $STARTUP_TIMEOUT;
      }

      my $timeoutForThisRun = $timeout;

      my $statusCheckStartTime = time;

      # Call the status
      $rc = $STATUS_PROCESS_OK;
      # If process looks good, only invoke component status once every 10 runs
      if (($pid != -1) && 
          (( $processExit[0] != $PROCESS_OK ) || ($checkIterMod == 0)))
      {
        $rc = $objRef->status();
        $timeout -= (time - $statusCheckStartTime); 
	#if(($IS_WINDOWS eq "TRUE") and ($name eq "EMAgent"))
        #{
	#  $objRef->checkDynPropsTimeout();
        #}
      }

      printDebugMessage("Status for $pid : ($processExit[0], $processExit[1]), $rc");

#      my $timeout = $ENV{EMWD_PROCESS_STATUS_TIMEOUT};
#      $timeout = 120 unless defined($timeout);

      # If the status of the process is Unknown, do a retry
      # until a timeout is reached ...
      while( ($rc == $STATUS_PROCESS_UNKNOWN) and
             ($timeout > 0))
      {
        $statusCheckStartTime = time;
        $rc = $objRef->status();
        $timeout -= (time - $statusCheckStartTime);

        sleep 10;
        $timeout -= 10; 
      }

      # If the status of the process is Hang, do a retry
      # until a timeout is reached...
      while( ($rc == $STATUS_PROCESS_HANG) and
             ($timeout > 0))
      {
        $statusCheckStartTime = time;
        $rc = $objRef->status();
        $timeout -= (time - $statusCheckStartTime); 
      }

      if($rc != $STATUS_PROCESS_OK)
      {
	  $rc = $STATUS_PROCESS_HANG if ($timeout <= 0 );
      }

      # If the status is no_process or process_hang ...
      if( ($rc == $STATUS_NO_SUCH_PROCESS) or
          ($rc == $STATUS_PROCESS_HANG) or 
          ($rc == $STATUS_AGENT_ABNORMAL) or
          ( $processExit[0] != $PROCESS_OK ) )
      {
         printMessage("Checking status of $name : $pid");

         # If the process is in hung / abnormal state, we need to call the debug routine..
         if ( ($processExit[0] == $PROCESS_OK) &&
              ( $rc == $STATUS_PROCESS_HANG ) || ( $rc == $STATUS_AGENT_ABNORMAL ) )
         {
           if ( $rc == $STATUS_PROCESS_HANG )
           {
             printMessage("Hang detected for $name : $pid");
             printMessage("Debugging component $name");
           }
           else
           {
             printMessage("Abnormality reported for $name : $pid");
             printMessage("Debugging component $name");
           }

           # Lets check if the process wasn't killed in the meantime
           (*processExit) = reapChild( $pid, $name );

           if($processExit[0] == $PROCESS_OK)
           {
             # Make 3 attempts to kill agent process on failure
             my $tries = 0;
             while( ($processExit[0] == $PROCESS_OK) and ($tries < 3) )
             {
               # debug routine is called...
               $objRef->debug(); 

               #Lets wait for some time for the process to be killed
               sleep 5;

               # Irrespective of how the process exited, since it is a hang we attempt to restart. 
               (*processExit) = reapChild( $pid, $name );
               $tries++;
             }
             if ($processExit[0] == $PROCESS_OK)
             {
               printMessage("Unable to kill hung process $name : $pid");

               # Call the subroutine that exits out each of the component
               stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);

               # Time to hang our boots and exit...
               printMessage("Exiting watchdog loop\n");
               $normalShutdown = "TRUE";
               $NUM_COMPONENTS = 0;
               last;
             }

             $processExit[0] = $PROCESS_EXIT_SIGNAL;
             $processExit[1] = $EMCTL_CORE_SIGNAL;
           }
         }
         
         # Note the current crash time ...
         my($currentCrashTime) = time;

         if( $processExit[0] == $PROCESS_EXIT_NORMAL )
         {
            my($tmpMsg) = $name." exited at ".localtime($currentCrashTime).
                          " with return value $processExit[1].";
            printMessage($tmpMsg);

            if( ($processExit[1] > 128) and ($processExit[1] <= 255) )
            {
              my($signalNum) = ($processExit[1] - 128);

              # A process hang might have killed the process with signum 9
              if( ($signalNum == 9) and 
                  ($rc != $STATUS_PROCESS_HANG) and
                  ($rc != $STATUS_AGENT_ABNORMAL) )  
              {
                 printMessage("$name has been forcibly killed.");
                 printMessage("Stopping other components.");
                      
                 # Call the subroutine that exits out each of the component
                 stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);
            
                 # Time to hang our boots and exit...
                 printMessage("Exiting watchdog loop\n");
                 $normalShutdown = "TRUE";
                 $NUM_COMPONENTS = 0;
                 last;
              }
              else
              {
                checkAndRenameCore($name, $pid, $objRef);
                
                $objRef->incThrashCount();
                printMessage("$name will be restarted because of core dump.");
              }
            } # End of signal check between 128 to 255
            elsif( ($processExit[1] == $EM_EXIT_DONT_RESTART) or ($processExit[1] == 0) )
            {
               if($processExit[1] == $EM_EXIT_DONT_RESTART) # This is agent initialization failure...
               {
                 printMessage("$name has exited due to initialization failure.");
                 printMessage("Stopping other components.");
                 $exitCode = $EM_EXIT_DONT_RESTART;
                      
                 # Call the subroutine that exits out each of the component
                 stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);
               }

               if($processExit[1] == 0) # Agent was shutdown normally
               {
                 printMessage("$name was shutdown normally.");
               }
      
               # Time to hang our boots and exit...
               printMessage("Exiting watchdog loop\n");
               $normalShutdown = "TRUE";
               $NUM_COMPONENTS = 0;
               last;
            }
            else
            {
               if( $processExit[1] == 3 )
               {
                 # The process has requested a restart...
                 printMessage("$name has requested a restart. Will be restarted.");
               }
            }
         }
         elsif( $processExit[0] == $PROCESS_EXIT_SIGNAL )
         {
            my($tmpMsg) = $name." exited at ".localtime($currentCrashTime).
                          " with signal ".$processExit[1];
            printMessage($tmpMsg);
                  
            if( ($processExit[1] != 9) and
                ($processExit[1] != 15) and ($processExit[1] != $EMCTL_CORE_SIGNAL) ) # Not a SIGKILL/SIGTERM Signal ..
            {
                checkAndRenameCore($name, $pid, $objRef);

                # Bump up the thrash count...
                $objRef->incThrashCount();
            
                my($tmpMsg) = $name." exit via signal ".$processExit[1].
                             " .Thrash count is ".$objRef->getThrashCount();
                printDebugMessage($tmpMsg);
                printMessage("$name will be restarted due to core dump(via signal $processExit[1]).");
            }
            else # We need to exit the rest on SIGKILL or SIGTERM signal
            {
              # debug kills a hung process by 9 or 15. We do restart if killed due to hang..
              if( ( $rc != $STATUS_PROCESS_HANG ) and
                  ( $rc != $STATUS_AGENT_ABNORMAL ) )
              {
                printMessage("$name has been forcibly killed.");
                printMessage("Stopping other components.");
                      
                # Call the subroutine that exits out each of the component
                stopComponents(\@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);
            
                # Time to hang our boots and exit...
                printMessage("Exiting watchdog loop\n");
                $normalShutdown = "TRUE";
                $NUM_COMPONENTS = 0;
                last;
              } 
              else
              {
                $objRef->incThrashCount();
                printMessage("$name either hung or in abnormal state.");
                printMessage("$name will be restarted/thrashed.");
              }
            }
         }
         elsif( $processExit[0] == $PROCESS_OK )
         {
           # We are in this situation only for a false alarm...
           # We drop to the bottom of the loop...
           $compJustStarted[$i] = 0;
           next;
         }
         else # The only likely hood is core dump ...
         {
            # But check for the dump core condition anyway ...
            if ($processExit[0] == $PROCESS_DUMPED_CORE)
            {
              # Bump up the thrash count...
              $objRef->incThrashCount();
 
              my($tmpMsg) = $name." exited at ".localtime($currentCrashTime).
                          " with return value ".$processExit[1];
              printMessage($tmpMsg);

              checkAndRenameCore($name, $pid, $objRef);

              # debug routine is called for non-emgent components.
	      # In EMAgent case debug routine takes two coredumps thinking it
	      # is a hang.
	      if($name ne "EMAgent") {
		  $objRef->debug();
	      }

              printMessage("$name will be restarted due to core dump.");

              # reapChild and ignore
              my ($ignore) = reapChildOnExit( $pid, $name );
            } # End of if dumped Core Check...
         }
         
         printDebugMessage("EMWD Checking for Thrash Scenario");
         
         # Check for the Thrash logic ...
         my ($timeCrashDelta);
         $timeCrashDelta = $currentCrashTime - ($objRef->getStartTime());
                                        
         # Thrash 3 times in 10 minutes if $timeoutForThisRun < 180 (3 minutes)
         # Otherwise, Thrash 3 times in $timeoutForThisRun+420 (7 minutes)
         # 420 = 90 (wait after startup) 
         #       + 30 (wait at beginning of while loop)
         #       + 120 (max time to return from first status check, HANG takes 2 min)
         #       + 120 (if status is called right before timeout expires inside HANG loop)
         #       + 60 (time to do other processing like reapChild, etc.) 
         # If more than x minutes than we start over. 
                                               
         my $maxThrashInterval = 600;   # The default
         if ($timeoutForThisRun >= 180)
         {
           $maxThrashInterval = $timeoutForThisRun + 420;
         }

         if( $timeCrashDelta > $maxThrashInterval )
         {
             # We reset the thrash count ...
             $objRef->setThrashCount(1);
         }
         
         if (($objRef->getThrashCount()) >= 3)
         {
           $normalShutdown = "FALSE";
           if ( $name eq "EMAgent" )
           {
             $message = "$name is Thrashing. Exiting watchdog";
             writeToEMAbbendFile("$EMHOME/sysman/log/agabend.log", 
                                  "$message");
             $exitCode = $EM_EXIT_THRASH;
           }
           printMessage("$name is Thrashing. Exiting loop.");
           
           # Shutdown the rest of the components
           # Call the subroutine that exits out each of the component
           stopComponents( \@components, $NUM_COLS, $NUM_COMPONENTS, $baseCtr);

           # Reset the loop...
           $NUM_COMPONENTS=0;
           last;
         }
         else
         {
           # Restart required.
           # Tag component to be restarted by setting PID to -1;
           $objRef->reInitialize(-1,0);
         }
      } # endif process not okay

      if($objRef->getPID() == -1)
      {
	# Indicates object needs to be restarted.
        if($objRef->okToRestart() eq "TRUE")
        {
          printMessage("Restarting $name.");
                 
          # We use the components restartHandler to restart the component
          # returns PID, StartTime
          my ($tmp, @restartInfo);
          $tmp = &{$components[$baseCtr+$restart_offset]}();
          @restartInfo = @$tmp;
          $objRef->reInitialize($restartInfo[0], $restartInfo[1]);
          $compJustStarted[$i] = 1;
        }
        # Either we did restart or did not. In both cases move to the
	# next process object
        next;
      }

      $compJustStarted[$i] = 0;

      # Check for restart request from the process
      my($recycleRequest) = $objRef->recycle();
      if($recycleRequest eq "TRUE")
      {
        printMessage("Received restart request from $name : $pid");
        printMessage("Stopping $name : $pid");

        # This is for agent so that it does not send updown signals
        $ENV{EMAGENT_SILENT_RECYCLE} = "TRUE";

        $objRef->stop(); # Try to stop the process.
        # reapChild and ignore
        my ($ignore) = reapChildOnExit( $pid, $name );

        # We use the components restartHandler to restart the component
        # returns PID, StartTime

        my ($tmp, @restartInfo);

        $tmp = &{$components[$baseCtr+$restart_offset]}();
        @restartInfo = @$tmp;
        $objRef->reInitialize($restartInfo[0], $restartInfo[1]);
        $objRef->setThrashCount(1);
        $compJustStarted[$i] = 1;
        $ENV{EMAGENT_SILENT_RECYCLE} = "";
      }

      printDebugMessage("Monitor alive.");
      
      # our chance to do additional stuff here... like ...
      #
      # gatherProcessStatistics
      $objRef->gatherProcessStatistics();

    } # end for loop


    if($NUM_COMPONENTS == 0)
    {
      if($normalShutdown eq "FALSE")
      {
        printMessage("Exited due to Thrash.");
      }
    }
    
  } # end while iteration ...
  return $exitCode;
} # end subroutine

#
# checkAndRenameCore
# Checks for the core file and renames appropriately
# Parameters
# PID : The process Id of the child process
sub checkAndRenameCore()
{
   my ($name, $pid, $objRef) = @_;

   printMessage("$name has exited due to an internal error");

   if( ($^O eq "MSWin32") or ($^O eq "Windows_NT") )
   {
	my ($agentHome) = $EMHOME;
	my ($coreFileDir) = $agentHome."/sysman/emd/";

	opendir(DIR,$coreFileDir) or return;
        #filtering files starting with core
	@coreFileList = grep { /^core.*/ && -f "$coreFileDir/$_"  } readdir(DIR);
	closedir(DIR);
        foreach $coreFile (@coreFileList) 
	{
	    my(undef, undef, $ftype) = fileparse($coreFile,qr{\..*});

            if( $ftype eq ".dmp")
	    {
		#$coreFile = $coreFileDir.$filename;
                my($trcbkFile) = $coreFile.".traceback";
                if(!( -e $trcbkFile))
		{
		    $objRef->debugCore( $coreFile );
		}
	    }
	}

        #deleteExtraAgentCores
	sAgentUtils::deleteExtraAgentCores_Win($EMHOME);
        # no renaming required on Windows. Core files are generated
        # with TS info

	return;
   }

   printMessage(" - checking for corefile at $EMHOME/sysman/emd");

   my $coreFile;
   my @coreLocs = ( "$EMHOME/sysman/emd/core", 
                    "$EMHOME/sysman/emd/core.$pid",
                    "$EMDROOT/bin/core" );
   my $coreFileFound = 0;

   foreach $coreFile (@coreLocs)
   {
     # We move the core as component name+localtime...
     if( -e $coreFile)
     {
        my($tmpMsg) = $name." coredump found at ".$coreFile;
        printCoreDbgMsg($tmpMsg);

        my($appender) = $name."_".time();
        my($destFile) = "$EMHOME/sysman/emd/core_".$appender;
        rename $coreFile, $destFile;

        printCoreDbgMsg("Core file moved to $destFile");
               
        $objRef->debugCore( $destFile );

        $coreFileFound = 1;
        last;
     }
   }
   if ( !$coreFileFound)
   {
      printDebugMessage("$name coredump not found!!");
   }
}

#
# Reaps the child process on exit, and ensures that 
# we don't have a defunct process lying around.
# This subroutine should ONLY be called when reaping 
# a process which is already killed or waiting to be killed. 
#
sub reapChildOnExit()
{
  my($cpid, $name) = @_;

  # Reap the process status of an exited process
  local (*processExit) = reapChild( $cpid, $name );

  my $retries = 3;

  while ($processExit[0] == $PROCESS_OK)
  {
    $retries--;
    if ($retries <= 0)
    {
      printMessage ("Failed to reap child process $name : $cpid");
      return 1;
    }

    printDebugMessage("reapChildOnExit: $name process ($cpid) still alive. Trying again ...");
    sleep 5;
    (*processExit) = reapChild( $cpid, $name );
  }

  return 0;
}

#
# reapChild
# Reaps the Child process. 
# The child process can be under following status
# alive 
# exited
#    exited due to normal shutdown
#    exited due to SIGQUIT signal
#    exited after core dump
# Parameters
# PID : The process Id of the child process
# Returns Array [0][1]
#   Array Element [0] is 
#       PROCESS_OK : If the process is okay
#       PROCESS_EXIT_NORMAL : If the process has exited normally
#       PROCESS_EXIT_SIGNAL : If the process exit is due to signal 
#       PROCESS_DUMPED_CORE : If the process has dumped core
#   Array Element [1] is 
#       PROCESS_OK : If the process is okay
#       exit code of the process if PROCESS_EXIT_NORMAL
#       signal that caused process death if PROCESS_EXIT_SIGNAL
#       PROCESS_DUMPED_CORE if PROCESS_DUMPED_CORE
sub reapChild()
{
  my($cpid, $name) = @_;

  # timeout for the waitpid... 
  my ($timeOut, $processStatus) = (0,0);
  my ($reaped, @status);

  if($cpid == -1)
  {
    @status = ($PROCESS_OK, $PROCESS_OK);      
    return (\@status);
  }

  if($IS_WINDOWS eq "TRUE")
  {
    #check if process is alive
    $reaped = waitpid($cpid, -1); # check without hanging
    $processStatus = $?;

    printDebugMessage("waitpid($cpid) reaped=$reaped, processStatus=$processStatus");

    if($reaped == 0) {
	# '0' indicates process is still running.
	@status = ($PROCESS_OK, $PROCESS_OK);
	return (\@status);
    }	

    # process is not running. It could have exited normally or ab.
    printMessage("Pid $cpid not found. reaped=$reaped, processStatus=$processStatus");
    if($reaped == -1) {
	# we lost the xit code. somebody else reaped it.
	# we report normal exit as we don't want it restarted.
	printMessage("Lost xit code. Assuming normal exit. processStatus=$processStatus");
	@status = ($PROCESS_EXIT_NORMAL, 0);
    } else {
	# value of reaped is usually the pid when process is reaped.
        my( $exit_value, $killed, $core_dumped ) = (0,0,0);
        $exit_value  = $processStatus >> 8;
        $core_dumped = $exit_value == 5;
        $killed      = $exit_value == 9;

        if($core_dumped == 0 and $killed == 0)
        {
          # On Windows, consider signal 1, HANGUP, as normal exit
          # This is because we use the taskkill command to kill 
          # processes on windows, and the taskkill command will
          # result in a process with signal HANGUP
          if ($exit_value == 1)
          {
  	        $exit_value = 0;
          }

            @status = ($PROCESS_EXIT_NORMAL, $exit_value);
        }
        elsif($killed == 1) # The process was signaled to exit.
        {
          @status = ($PROCESS_EXIT_SIGNAL, $exit_value );
        }
        elsif($core_dumped == 1)
        {
          printMessage("ProcessStatus is $processStatus. Process core dumped.");
          @status = ($PROCESS_DUMPED_CORE, $exit_value);
        }
        else 
        {
          printDebugMessage("ProcessStatus is $processStatus. Assuming normal exit.");
          @status = ($PROCESS_EXIT_NORMAL, $processStatus);
        }
    }
    return (\@status);
  }

  # waitpid returns processid that is reaped and sets $? to the wait 
  # status of the defunct process. This status is two 8-bits in one 
  # 16-bit number. The high byte is the exit value of the process. 
  # The low 7 bits represent the number of the signal that 
  # killed the process, with the 8th bit indicating whether a core 
  # dump occurred

  $reaped = waitpid($cpid, WNOHANG);
  $processStatus = $?;
  printDebugMessage("waitpid($cpid) reaped=$reaped, processStatus=$processStatus");
  $OSNAME = $Config{'osname'};
  if($reaped == -1)  
  {
    # we lost the xit code. somebody else reaped it.
    # we report normal exit as we don't want it restarted.
   printMessage("Lost xit code. Assuming normal exit. processStatus=$processStatus");
   @status = ($PROCESS_EXIT_NORMAL, 0);
  }
  elsif ($reaped == 0)  # ...the child process is alive and kicking
  {
    @status = ($PROCESS_OK, $PROCESS_OK);      
  }
  elsif(WIFEXITED($processStatus)) # The process exited normally...
  {
    @status = ($PROCESS_EXIT_NORMAL, WEXITSTATUS($processStatus) );
  }
  elsif(WIFSIGNALED($processStatus)) # The process was signaled to exit...
  {
    # Note: This handles both core-dump and signal in Unixes
    $signal = WTERMSIG($processStatus); 
    if ( $OSNAME eq "aix" && $processStatus > 128)
    { # On AIX, WTERMSIG works incorrectly
      # This should start working later 5.8.5+.
      # Till then temp. workaround.
      $signal = $processStatus - 128;
    }
    @status = ($PROCESS_EXIT_SIGNAL, $signal );      
  }
  else # The only possibility now is a core dump ...
  {
    if( $processStatus == -1 )
    {
       printDebugMessage("Process Status is $processStatus. This is a false alarm.");
       @status = ($PROCESS_OK, $PROCESS_OK);
    }
    else
    {
      # Process might have core dumped or waitpid raised a false alarm...
      # The dump cored bit is the LSB
      my($dumped_core) = $processStatus & 0x80;
      $dumped_core = ($dumped_core >> 7) && 1;
      $signal = WTERMSIG($processStatus);
      if ( $OSNAME eq "aix" && $processStatus > 128)
      { # On AIX, WTERMSIG works incorrectly
        $signal = $processStatus - 128;
      }

      if($dumped_core == 1)
      {
        printMessage("ProcessStatus is $processStatus. Process core dumped.");
        @status = ($PROCESS_DUMPED_CORE, $signal);    
      }
      else # Indicates a false alarm ...
      {
        printDebugMessage("ProcessStatus is $processStatus. This is a false alarm.");
        @status = ($PROCESS_OK, $signal);            
      }
    }
  }

  printDebugMessage("reapChild pid=$cpid, status = $status[0], $status[1]\n");
  
  return (\@status);     
}


# 
# stopComponents
# Helper that takes the components array, the current component's base
# where the problem occurred and the number of columns [added/sub to base] and 
# stop() all components other than current component.
#
sub stopComponents
{
   local( *comps, $numCols, $numComponents, $baseCtr) = @_;

   my($bbase) = $baseCtr-$numCols;
   my($fbase) = $baseCtr+$numCols;
   my($maxElements) = ($numCols * $numComponents);

   while($bbase >= 0)
   {
     $objRef = $comps[$bbase];

     my ($name) = $objRef->getName();
     printMessage("EMWD Stopping $name.");

     $objRef->stop();
     $bbase-=$numCols;
   }
   
   while($fbase < $maxElements)
   {
     $objRef = $comps[$fbase];

     my ($name) = $objRef->getName();
     print localtime()."::EMWD Stopping $name \n";

     $objRef->stop();
     $fbase+=$numCols;
   }

   printDebugMessage("Stopped all other components.");
   printMessage("Commiting Process death.");

   # Commenting out the following. Since this seems to kill the oratst
   # and hence the short regression itself...
   # setpgrp(0, 0); # Become the process group leader...
   # kill -9, 0;  # Kill itself and all its subprocess....
}


#
# copyLastRunDetails
# Makes a copy of the most recent contents of the nohup file
#
sub copyLastRunDetails()
{
  my $NOHUP_LASTRUN = $NOHUP_FILE . ".lr";
  
  open(NOHUPLRFILE, ">$NOHUP_LASTRUN");
  open(NOHUPRFILE, "<$NOHUP_FILE");

  seek (NOHUPRFILE, -4096, 2);
  while(read NOHUPRFILE, $buf, 4096) {
    print NOHUPLRFILE $buf;
  }

  close(NOHUPRFILE);
  close(NOHUPLRFILE);
}


#
# printMessage
# prints EMWD trace messages
# The general format is 
# ------ <localtime>::<message> ----- \n
#
sub printMessage()
{
 my ($message) = @_;
 print "----- ".localtime()."::".$message." -----\n";
}

#
# printCoreDbgMsg
# prints EMWD trace relating to the core files
# The general format is 
# ----- <localtime>::<message> \n
#
sub printCoreDbgMsg()
{
 my ($message) = @_;
 print "----- ".localtime()."::".$message."\n";
}

#
# printDebugMessage
# prints the EMWD Debug message
# Note use this subroutine to debug the EMWD only
# Checks for the DEBUG_ENABLED flag...
#
sub printDebugMessage()
{
 my ($message) = @_;
 print "### ".localtime()."::".$message." ### \n" if $DEBUG_ENABLED;
} 



