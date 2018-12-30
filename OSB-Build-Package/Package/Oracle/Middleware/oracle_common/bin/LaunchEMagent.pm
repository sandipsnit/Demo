#
# $Header: emagent/scripts/unix/LaunchEMagent.pm /st_emagent_10.2.0.1.0/16 2009/01/15 23:25:45 nigandhi Exp $
#
# LaunchEMagent.pm
#
# Copyright (c) 2002, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      LaunchEMagent.pm - Module that launches 'emagent'
#
#    DESCRIPTION
#      Module that launches emagent to be watched em watch dog, emwd.pl
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    nigandhi 01/09/09  - Bug 7696444: Preserve permissions on emd.properties
#    mgoodric 12/05/08  - add more debugging
#    mgoodric 12/04/08  - turn on LD_DEBUG
#    mgoodric 10/08/08  - restrict some debugging code to Linux
#    njagathe 08/20/08  - Backport njagathe_bug-7047440 from main
#    mgoodric 08/11/08  - add yet more debugging info
#    andyao   07/15/08  - change DHTML port
#    mgoodric 06/21/08  - use dumpENV for intermittent startup problem
#    sunagarw 06/16/08  - Backport sunagarw_bug-5014908 from main
#    njagathe 05/23/08  - Backport njagathe_bug-6938681 from main
#    andyao   07/24/07  - Add a dynamic port checker - project 23523, windows only
#    svrrao   07/09/07  - Backport svrrao_bug-6141202 from main
#    njagathe 12/21/06  - 5713382
#    njagathe 11/21/06  - XbranchMerge njagathe_bug-5646056 from main
#    njagathe 07/26/06  - Backport njagathe_bug-5329412 from main
#    njagathe 07/24/06  - Bug 5329412 - trust emd.properties content for
#                         agentTZ
#    kduvvuri 09/11/05  - write to abbend file.
#    kduvvuri 09/08/05  - debug stmt.
#    kduvvuri 09/07/05  - Checking newtzrgn.txt
#    kduvvuri 08/19/05  - fix bug 4560146.
#    kduvvuri 08/05/05  - fix 4524126.
#    kduvvuri 07/16/05  - don't validate timezone returned from java with
#                         agent, if there is no rep url.
#    kduvvuri 07/15/05  - fix 4481725.
#    sreddy   06/22/05  - Always set EMSTATE environment variable
#    vnukal   06/01/05  - Valgrind if env var set
#    vnukal   03/14/05  - Patch script callout
#    kduvvuri 12/20/04  - validateTZAgainstAgent moved to
#                         EmctlCommon.pm.template.
#    rpinnama 11/29/04  - Fill in the repository procedure name for updating
#                         timezone region
#    kduvvuri 10/04/04  - get rid of numtries. not used.
#    kduvvuri 10/03/04  - review comments.
#    kduvvuri 10/03/04  - fix headers again.
#    kduvvuri 10/03/04  - align the headers properly.
#    kduvvuri 10/03/04  - bug 3811245
#    vnukal   09/23/04  - Get rid of Exit file on Windows.
#    kduvvuri 05/05/04  - created.
#

package LaunchEMagent;
use EMAgent;
use AgentStatus;
use EmCommonCmdDriver;
use EmctlCommon;
use File::Copy cp;
use File::Temp qw/ tempfile /;
use IPC::Open3;
use Symbol qw(gensym);
use Socket;

$EMHOME = $ENV{'EMHOME'};
sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);

  return $self;
}

sub launchComp {
   my $classname = shift;
   my $rargs = shift;

   $emAgent = new EMAgent();

   $temp = launchAgent();
   @agentPID = @$temp;

   $emAgent->Initialize($agentPID[0], $agentPID[1], $DEBUG_ENABLED);
   $rLaunchFunc = \&launchAgent;
   @result = ($emAgent, $rLaunchFunc);
   return \@result;
}

#
# update emd.properties with agentTZRegion if it not already present.
# It it is already present, verify that it is a valid time zone and
# agrees with what is expected by the agent.
#
sub updateAgentTZIfNecessary()
{
  my $emdPropFile = getEmdPropFile();
  my $repURL = "";
  my $repURLFound = 0;
  my $tzRegion = "";
  my $tzRegionFound = 0;
  my $rc = 0;
  if (not (-e "$emdPropFile" ))
  {
     die "Missing emd.properties from EMHOME/sysman/config  \n";
  }

  #get existing file permissions
  my $emdPropFilePerm = getFilePermission($emdPropFile);

  ($tzRegion,$repURL) = getAgentTZAndRepURL();

  if( length( $repURL) > 0 )
  {
    $repURLFound = 1;
  }

  if( length( $tzRegion) > 0 )
  {
     $tzRegionFound = 1;
  }

  #If there is no repository url, we don't need to validate tzregion, but
  #we still need to have a value.
  if ( ($tzRegionFound == 1 ) && ( $repURLFound == 0 ) )
  {
    return;
  }

  #If the current tzRegion is UTC, and there is a $OH/sysman/admin/newtzrgn.txt file
  #that has a different value, update emd.properties with that value
  if( $tzRegion eq "UTC")
  {
    $newtzrgn = getTZFromTzRegionTxt();

    printDebugMessage("newtzrgn read from newtzrgn.txt ($newtzrgn)...");
    if ( (length($newtzrgn) > 0)   &&  ($tzRegion ne "$newtzrgn") )
    {
      printMessage("Updating agentTZRegion in $emdPropFile to value from newtzrgn.txt ($newtzrgn)...");
      #create a back up of emd.properites
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
      $year = $year+1900;
      $mon = $mon+1;
      my $backFile = sprintf "%s.%4d\-%02d\-%02d\-%02d\-%02d\-%02d", $emdPropFile,$year,$mon,$mday,$hour,$min,$sec;

      my($tempString) = "$emdPropFile copied to $backFile while updating the property  'agentTZRegion'";
      printMessage($tempString);
      cp($emdPropFile,$backFile);

      open(EMDPROP, ">> $emdPropFile");
      print EMDPROP "agentTZRegion=$newtzrgn\n";
      close EMDPROP;

      # Read back the value we just put in thru java.
      ($tzRegion,$repURL) = getAgentTZAndRepURL();
      printMessage("An agentTZregion of '$tzRegion' is installed in $emdPropFile.");
   }
  }

  #if there is a REPOSITORY_URL, the tzRegion has to be valid.
  #The following code makes sure that a valid time zone region is always
  #installed in emd.properties.

  if ( ($tzRegionFound == 1 )  && !supportedTZ($tzRegion) )
  {
    if(deprecatedTZ($tzRegion))
    {
      printMessage("TZ $tzRegion is now deprecated. If agent startup fails because the repository cannot understand it, use emctl resetTZ agent to pick up a new supported TZ.");
    }
    else
    {
    $message = "property 'agentTZregion' in '$emdPropFile' contains an invalid value of '$tzRegion'\.Agent start up can not proceed\."."This value might have been manually modified to be an incorrect value\."."This value needs to be set to one of the  values listed in '$EMDROOT/sysman/admin/supportedtzs\.lst'\. Execute 'emctl config agent getTZ' and see if this is an appropriate value.";

    writeToEMAbbendFile("$EMHOME/sysman/log/agabend.log", "$message");

    printMessage("property 'agentTZregion' in '$emdPropFile' contains an invalid value of '$tzRegion'\.Agent start up can not proceed\."."This value might have been manually modified to be an incorrect value\."."This value needs to be set to one of the  values listed in '$EMDROOT/sysman/admin/supportedtzs\.lst'\. Execute 'emctl config agent getTZ' and see if this is an appropriate value.");

    exit($EM_EXIT_DONT_RESTART);
    }
  }

  if ( $tzRegionFound == 0  )
  {
    printMessage("Property 'agentTZRegion' is  missing from  $emdPropFile. This is normal when the agent is started for the very first time.Updating it...");
    #create a back up of emd.properites
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year = $year+1900;
    $mon = $mon+1;
    my $backFile = sprintf "%s.%4d\-%02d\-%02d\-%02d\-%02d\-%02d", $emdPropFile,$year,$mon,$mday,$hour,$min,$sec;

    my($tempString) = "$emdPropFile copied to $backFile while updating the property  'agentTZRegion'";
    printMessage($tempString);
    cp($emdPropFile,$backFile);

    $rc = updateAgentTZRegion();

    #restore file permissions
    restoreFilePermissions($emdPropFilePerm, "$emdPropFile");

    if ( $rc == 1 )
    {
      $message = "Failed to update  the property 'agentTZRegion' in $emdPropFile.Needs to be manually updated.Execute 'emctl config agent getTZ' to see if this value is appropriate.";
      writeToEMAbbendFile("$EMHOME/sysman/log/agabend.log","$message");
      printMessage("Failed to update  the property 'agentTZRegion' in $emdPropFile.Needs to be manually updated.Execute 'emctl config agent getTZ' to see if this value is appropriate.");
      exit($EM_EXIT_DONT_RESTART);
    }
        # Read back  the value we just put in thru java.
    ($tzRegion,$repURL) = getAgentTZAndRepURL();
    printMessage("An agentTZregion of '$tzRegion' is installed in $emdPropFile.");
  }
  else
  {
    printDebugMessage("agentTZRegion already exists in $emdPropFile.");
  }

  #No need to validate further, if there is no REPOSITORY_URL.
  if ( $repURLFound == 0 )
  {
    return;
  }

  #if rep url is there, whether installing for the first time,or already
  #present , validate the tz offset corresponding to 'agentTZRegion'
  #in emd.properties against the value used by the agent.

  $rc = validateTZAgainstAgent($tzRegion);
  if ( $rc != 0 )
  {
    my $tzj = getTZFromJava();
    printMessage("Mismatch detected between timezone in env ($tzj) and in $emdPropFile ($tzRegion). Forcing value to latter..");
    $rc = forceTZRegionValue($tzRegion);
    if ( $rc != 0 )
    {
       $message = "The agentTZRegion value in $emdPropFile is not in agreement with what agent thinks it should be.Please verify your environment to make sure that TZ setting has not changed since the last start of the agent\.\n"."If you modified the timezone setting in the environment, please stop the agent and exectute 'emctl resetTZ agent' and also execute the script mgmt_target.set_agent_tzrgn(<agent_name>, <new_tz_rgn>) to get the value propagated to repository.";

       writeToEMAbbendFile("$EMHOME/sysman/log/agabend.log", $message);

       printMessage("The agentTZRegion value in $emdPropFile is not in agreement with what agent thinks it should be.Please verify your environment to make sure that TZ setting has not changed since the last start of the agent\.\n"."If you modified the timezone setting in the environment, please stop the agent and exectute 'emctl resetTZ agent' and also execute the script mgmt_target.set_agent_tzrgn(<agent_name>, <new_tz_rgn>) to get the value propagated to repository");
       exit($EM_EXIT_DONT_RESTART);  # dont' restart.
     }
  }
  else
  {
    printDebugMessage("agentTZRegion successfully validated.");
  }
}

sub updateAgentTZRegion
{
      my $rc = 0;

      my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
      close $fh; # closing to prevent file sharing violations on Windows

      $rc = 0xffff & system("$JRE_HOME/bin/java -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar updateTZ > $tmpfilename 2>&1");
      $rc >>= 8;
      if ($rc == 1 )
      {
          open ($fh,"< $tmpfilename");
          while (<$fh>) {
              printMessage ("$_");
          }
          close $fh;

      }
      unlink("$tmpfilename");
      return $rc;

}

sub getTZFromTzRegionTxt
{
  my $newtzrgnFile = "$ENV{ORACLE_HOME}/sysman/admin/newtzrgn.txt";
  my $newtzrgn = "";
  if ( -e "$newtzrgnFile" )
  {
    open(NEWTZRGNPROP,"< $newtzrgnFile" ) or die "Fatal error can not open:$newtzrgnFile to look for the property  'agentTZRegion': $!";
    $newtzrgn = <NEWTZRGNPROP>;
    chomp($newtzrgn);
    close(NEWTZRGNPROP);
  }
  return "$newtzrgn";
}
sub getAgentTZAndRepURL
{
  my ($emdPropFile,$EMDPROP,$emdPropLine,$tzRegion,$propValue,$propName,$remain,$found,$repURL);

  $repURL = "";
  $tzRegion = "";

  $emdPropFile = getEmdPropFile();

  open(EMDPROP,"< $emdPropFile" ) or die "Fatal error can not open:$emdPropFile to look for the property  'agentTZRegion': $!";

  while ($emdPropLine = <EMDPROP>) {
    chomp($emdPropLine);
    #strip all leading  white space characters.
    $emdPropLine =~ s/^\s*//;

    if( ($emdPropLine =~ /^\#/ ) || ( length($emdPropLine) <= 0 ) ) {
    #print "discarding  \"$emdPropLine\" ,since it is a comment \n";
       next;
    }
    ($propName, $propValue , $remain) = split(/\=/ , $emdPropLine , 3);
    #remove leading and trailing white space.
    $propName =~ s/\s*$//;
    $propValue =~ s/^\s*//;
    $propValue =~ s/\s*$//;
    $lengthPropName = length($propName);
    $lengthPropValue = length($propValue);
    if ( ($lengthPropName) > 0  && ($lengthPropValue > 0 ))
    {
       if ( $propName eq "agentTZRegion" )
       {
         $tzRegion = $propValue;
       }
       if ( ($propName eq "REPOSITORY_URL") )
       {
         $repURL = $propValue;
       }
    }
  }
  close(EMDPROP);
  return("$tzRegion","$repURL");
}


sub getAgentTZFromAgentStmp
{
  my ($agntstmpFile,$AGNTSTMP,$agntstmpLine,$tzRegion,$propValue,$propName,$remain,$found);

  $tzRegion = "";

  $agntStmpFile = getAgtStmpFile();

  open(AGNTSTMP,"< $agntStmpFile" ) or return "";

  while ($agntStmpLine = <AGNTSTMP>) {
    chomp($agntStmpLine);
    #strip all leading  white space characters.
    $agntStmpLine =~ s/^\s*//;

    if( ($agntStmpLine =~ /^\#/ ) || ( length($agntStmpLine) <= 0 ) ) {
    #print "discarding  \"$agntStmpLine\" ,since it is a comment \n";
       next;
    }
    ($propName, $propValue , $remain) = split(/\=/ , $agntStmpLine , 3);
    #remove leading and trailing white space.
    $propName =~ s/\s*$//;
    $propValue =~ s/^\s*//;
    $propValue =~ s/\s*$//;
    $lengthPropName = length($propName);
    $lengthPropValue = length($propValue);
    if ( ($lengthPropName) > 0  && ($lengthPropValue > 0 ))
    {
       if ( $propName eq "agentTZRegion" )
       {
         $tzRegion = $propValue;
       }
    }
  }
  close(AGNTSTMP);
  return "$tzRegion";
}

sub getEmdPropFile {
  return "$EMHOME/sysman/config/emd.properties";
}

sub getAgtStmpFile {
  return "$EMHOME/sysman/emd/agntstmp.txt";
}

sub supportedTZ
{
    my ($inpTZ) = @_;
    my $found = 0;

    my $tzRead;

   # if the timzezone region is of the form [+,-]HH:MM , accept it.
   if ( $inpTZ =~ /^[+-][0-2][0-9]:[0-5][0-9]$/ ) {
     $found = 1;
   }
   else
   {
    open (INFILE, "$ENV{EMDROOT}/sysman/admin/supportedtzs.lst");

    while (<INFILE>) {
        $tzRead = $_;
        # Remove the new line.
        chomp($tzRead);

        ## Trim the tzRead..
        for ($tzRead)
        {
            s/^\s+//;
            s/\s+$//;
        }

        if (/^#/) {
            next;
        }

        if ($tzRead eq $inpTZ) {
            $found = 1;
        }
#    print "TZ = $inpTZ, Read = $tzRead. Found = $found.\n";
    }

    close INFILE;
   } # else time zone in not HH:MM format.

    return $found;
}

sub deprecatedTZ
{
    my ($inpTZ) = @_;
    my $found = 0;

    my $tzRead;

   {
    open (INFILE, "$ENV{EMDROOT}/sysman/admin/supportedtzs.lst");

    while (<INFILE>) {
        $tzRead = $_;
        # Remove the new line.
        chomp($tzRead);

        ## Trim the tzRead..
        for ($tzRead)
        {
            s/^\s+//;
            s/\s+$//;
        }

        if (!/^#deprecated /) {
            next;
        }

        $tzRead =~ s/^#deprecated //;

        if ($tzRead eq $inpTZ) {
            $found = 1;
        }
    }

    close INFILE;
   }

    return $found;
}
#
# launchAgent
# Launches the Agent Process in a different process space
# Additionally, it stats the process for 30 tries before giving up.
#
# Returns
# Array {
#            PID, # Process id of the child process which execs the emagent
#            startTime # Starttime [or failure time]
#       }
#
sub launchAgent()
{
  updateAgentTZIfNecessary();
  my @returnArray = ();

  # Check for any core dumps ...
  if ( -e "$EMHOME/sysman/emd/core" )
  {
     # Move the corefile...
     printMessage("Detected Core File. Moving core file to core.0");
     rename "$EMHOME/sysman/emd/core", "$EMHOME/sysman/emd/core.0";
  }

  #copyLastRunDetails();

  $ENV{EMSTATE} = $EMHOME if (!defined($ENV{EMSTATE}));

  # At the outset we need to fork, since we have to launch the
  # agent in a different process...

  processAnyTZChange();

  my $EMAGENT_CHILD_PROCESS;
  if($IS_WINDOWS eq "TRUE")
  {
    my($commandString) = "$EMDROOT/bin/emagent";

    $NOHUP_FILE = $ENV{'NOHUP_FILE'};

    # Point the TMP env variable at our upload directory. _tmpname uses
    # TMP if set to create temporary files.
    $ENV{TMP} = "$EMHOME/sysman/emd/upload/";

    # point EMAGENT_DHTML_PORT to the next available port starting.
    # This is used in DHTML fetchlet (windows only, project 23523)
    if ($ENV{EMAGENT_DHTML_PORT} eq "")
    {
      # Per http://tools.ietf.org/html/rfc2750#ref-IANA-CONSIDERATIONS
      # numbers in the range 49152-53247 are allocated as vendor
      # specific (one per vendor) by First Come First Serve, and numbers
      # 53248-65535 are reserved for private use and are not assigned by IANA.
      #
      # To avoid collisions with other programs who might do something similar,
      # we pick a higher value for the starting candidiate.
      $ENV{EMAGENT_DHTML_PORT} = selectNextPort(54000);
    }

    # Change current directory to sysman/emd so cores are generated at that
    # location and are easier to find in cust env.
    chdir("$EMHOME/sysman/emd");

    $EMAGENT_CHILD_PROCESS = open3(gensym, ">&STDOUT", ">&STDERR", "$commandString");
  }
  else
  {
    $EMAGENT_CHILD_PROCESS = fork();
  }

  if( $EMAGENT_CHILD_PROCESS == 0 )
  {
      # This is the child process...
      # Set JAVA_HOME env variable to the contents of JRE_HOME
      $ENV{JAVA_HOME} = $JRE_HOME;

      # Change current directory to sysman/emd so cores are generated at that
      # location and are easier to find in cust env.
      chdir("$EMHOME/sysman/emd");

      #sleep for x secs to represent the delayed launch of emagent proc
      if (defined $ENV{TEST_SLEEP_FOR_SLOW_WATCHDOG})
      {
        my $test_sleep = $ENV{TEST_SLEEP_FOR_SLOW_WATCHDOG};
        sleep $test_sleep;
      }

      my $agentExecTime = time();
      my $timeElapased = $agentExecTime - $EmctlCommon::WATCHDOG_START_TIME;

      if ($EmctlCommon::WATCHDOG_START_TIME > 0)
      {
        if (($EmctlCommon::EMAGENT_TIME_FOR_START_STOP > 0)
            and ($timeElapased > $EmctlCommon::EMAGENT_TIME_FOR_START_STOP))
        {
          my $displayMsg = "Execing EMAgent process is taking longer than expected " .
                        $EmctlCommon::EMAGENT_TIME_FOR_START_STOP . " secs.";
          printMessage($displayMsg);
        }
        printMessage("Time elapsed between Launch of Watchdog process and execing EMAgent is $timeElapased secs");
      }

      if($DEBUG_ENABLED) {
        my $EMCTL_ENV_FILE = $ENV{EMCTL_ENV_FILE};
        system("env | sort > $EMCTL_ENV_FILE.3");
        system("diff $EMCTL_ENV_FILE $EMCTL_ENV_FILE.3 > ${EMCTL_ENV_FILE}.diff2");
        printDebugMessage("Env changes prior to agent launch recorded in ${EMCTL_ENV_FILE}.diff2");
        unlink("$EMCTL_ENV_FILE.3");
      }

      # This is the child process...
      # exec the cmd directly otherwise exec launches the cmd via shell.
      my($launchAgent) = ("$ENV{VALGRIND_LOC} $EMDROOT/bin/emagent");
      #if ($DEBUG_ENABLED) {
        if ($^O =~ m/linux/i) {
          my @libs = ('libnnz10.so','libclntsh.so','libclntsh.so.10.1','libnmemso.so');
          dumpSHARED(@libs);
          dumpENV();
        }
      #}
      exec ( $launchAgent );
      exit 0;
  }
  else
  {
    # This is the parent process ...
    $startTime = time; # Record the time of launching the console...

    my($tempString) = "Agent Launched with PID " . $EMAGENT_CHILD_PROCESS .
                      " at time " . localtime($startTime);
    printMessage($tempString);

    (@returnArray) = ($EMAGENT_CHILD_PROCESS, $startTime);

    return (\@returnArray);
  }
}

sub processAnyTZChange()
{
  my ($oldTZ, $curTZ, $curRepUrl, $uploadDir, $stateDir, $retVal1, $retVal2);
  $oldTZ = getAgentTZFromAgentStmp();
  ($curTZ, $curRepUrl) = getAgentTZAndRepURL();

  # Logic only applies if there is an old tz
  if(($oldTZ ne "") && ($oldTZ ne $curTZ))
  {
    $uploadDir = "$EMHOME" . "/sysman/emd/upload";
    $stateDir = "$EMHOME" . "/sysman/emd/state";
    $retVal1 = clearDirContents($uploadDir);
    $retVal2 = clearDirContents($stateDir);
    if( ($retVal1 == 1 ) || ($retVal2 == 1) )
    {
       printMessage("Some files in $uploadDir or $stateDir couldn't be removed.");
    }

  }
}


#Kondayya, move these to EmctlCommon.
#
# printMessage
# prints EMWD trace messages
# The general format is
# ------ <localtime>::<message> ----- \n
#
sub printMessage()
{
 my ($message) = @_;
 print "----- " . localtime() . "::" . $message . " -----\n";
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
 print "----- " . localtime() . "::" . $message . "\n";
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
 print "### " . localtime() . "::" . $message . " ### \n" if $DEBUG_ENABLED;
}

# finds the next available port
# aborts after 100 tries.
sub selectNextPort() {

    my ($port) = @_;
    my $max_tries = 100; #XXX
    while ($max_tries-- > 0) {
      if (portAvailable($port)) {
        return $port;
      } else {
        $port++;
      }
    }

    return -1;
}

# checks to see if the given port is available or not.
sub portAvailable() {
    my $port = shift;
    local *S;

    my $proto = getprotobyname('tcp');

    socket(S, Socket::PF_INET(),
           Socket::SOCK_STREAM(), $proto) || return 0;
    setsockopt(S, Socket::SOL_SOCKET(),
               Socket::SO_REUSEADDR(),
               pack("l", 1)) || return 0;

    if (bind(S, Socket::sockaddr_in($port, Socket::INADDR_ANY()))) {
        close S;
        return 1;
    }
    else {
        return 0;
    }
}

sub clearDirContents()
{
  my ($dirname) = @_;
  my $retVal = 0;

  opendir(DIR, $dirname) or die "Delete the files manually from dir $dirname,can't opendir $dirname: $!";
  while (defined($filename = readdir(DIR))) {
    $filename = "$dirname" . "/$filename";
    if ( -f $filename)
    {
      $rc = unlink($filename);
      if( $rc != 1)
      {
        print("Unable to delete the file $filename. Need to manually delete this file.\n");
        $retVal = 1;
      }
    }
  }
  closedir(DIR);

  return $retVal;
}

# All modules return something. By convention it is :
1;
# -------------------------------- End of Program ------------------------------

