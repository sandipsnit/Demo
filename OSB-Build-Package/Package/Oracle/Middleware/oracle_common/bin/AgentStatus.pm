# 
# $Header: emagent/scripts/unix/AgentStatus.pm /st_emagent_10.2.0.5.3as11/3 2009/04/21 08:04:14 kganapat Exp $
#
# AgentStatus.pm
# 
# Copyright (c) 2002, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      AgentStatus.pm - Module that drives various emctl options for agent.
#
#    DESCRIPTION
#      Handles status,reload,upload,config,clearstate,blackout,resetTZ and
#      pingOMS
#      options of agent w.r.t emctl.
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    kganapat 04/16/09 - Fix hang issue with switchOMS
#    qding    04/15/09 - bug 8430055
#    kganapat 02/26/09 - Adding switchOMS
#    qding    02/07/09 - PID
#    nigandhi 01/09/09 - bug 7696444: preserving permissions for emd.properties
#    bkovuri  11/17/08 - XbranchMerge bkovuri_bug-6606532 from main
#    danili   09/04/08 - Xbranchmerge jaysmith_26388_emctl_dumpstate from main
#    bkovuri  07/14/08 - Backport bkovuri_bug-6621617 from main
#    danili   09/12/07 - Remove nmosudrsa functions for NT
#    danili   08/30/07 - 6206690: Add encryption feature to nmosudo
#    danili   08/30/07 - 6206690: Add encryption feature to nmosudo
#    danili   08/31/07  - XbranchMerge danili_bug-6206690 from main
#    vrajendr 08/16/07  - Backport vrajendr_bug-6216750 from main
#    svrrao   07/09/07  - Backport svrrao_bug-6141202 from main
#    njagathe 06/20/07  - Backport njagathe_bug-6135721 from main
#    shianand 12/02/05  - Backport shianand_bug-4511157 from main 
#    shianand 11/14/05  - fix secure status agent to status agent -secure [-omsurl <>] 
#    shianand 11/14/05  - fix bug 4429246 
#    neearora 08/24/05  - Bug 4241177. Added command emctl getversion agent 
#    kduvvuri 08/19/05  - review comments. 
#    kduvvuri 08/19/05  - bug 4560146. 
#    kduvvuri 08/05/05  - fix 4524126. 
#    kduvvuri 07/12/05  - convert status command to send exit back to top 
#                         level emctl.pl. 
#    njagathe 05/03/05  - Adding pingOMS 
#    kduvvuri 12/20/04  - resetTZ should check against, agent timezone offset. 
#    rpinnama 11/29/04  - Fill in the repository procedure name for updating 
#                         timezone region 
#    kduvvuri 10/03/04  - create the history section. 
#    kduvvuri 10/03/04  - bug 3811245
#    vnukal   09/17/04  - Add tracing.
#    kduvvuri 07/19/04  - fix reloadCEMD.
#    kduvvuri 05/05/04  - created.
#
package AgentStatus;
use EmCommonCmdDriver;
use EmctlCommon;
use EMAgent;
use SecureAgentCmds;
use IPC::Open3;
use File::Temp qw/ tempfile /;


sub new {
  my $classname = shift;
  my $self = { PID => -1 };
  bless ( $self, $classname);
  return $self;
}

sub doIT {
   my $classname = shift;
   my $rargs = shift;
   my $result = $EMCTL_UNK_CMD; #Unknown command.

   my $argCount = @$rargs;

   if ( $argCount >= 2  && $rargs->[1] eq "agent" )
   {
     $action = $rargs->[0];
     traceDebug("AgentStatus.pm:Processing $action agent");
     if( $action eq "status" )
     {
        if ($rargs->[2] eq "-secure")
        {
          $exitCode = &SecureAgentCmds::secureStatus($rargs->[1], $rargs->[4]);
          @retArray = ($EMCTL_DONE,$exitCode);
          return \@retArray;
        }
        $exitCode = statusCEMD( $rargs);
        @retArray = ($EMCTL_DONE,$exitCode);
        return \@retArray;
     }
     elsif( $action eq "control" )
     {
        controlCEMD($rargs);
        return 0; #emctl done
     }
     elsif ( $action eq "upload" or $action eq "reload" or $action eq "pingOMS" )
     {
       reloadCEMD( $rargs );
       return 0;
     }
     elsif ($action eq "clearstate")
     {
       clearCEMDstate( $action);
       return 0;
     }
     elsif (lc($action) eq "resettz")
     {
       resetTZ();
       return 0;
     }
     elsif ($action eq "config")
     {
       configAgent($rargs);
       return 0;
     }
     elsif ( $action eq "istatus")
     {
       exit istatusCEMD();
     }
     elsif ( lc($action) eq "getversion")
     {
       EMAgent::getVersion();
       return $EMCTL_DONE;
     }
     elsif (lc($action) eq "dumpstate")
     {
       dumpState($rargs);
       return 0;
     }
     else
     {
        return $EMCTL_UNK_CMD;  #UNKNOWN_COMMAND.
     }
   }
   elsif ( $argCount >= 2 and  $rargs->[0] eq "set"  
                    and $rargs->[1] eq "credentials" )
   {
     traceDebug("AgentStatus.pm:emctl set credentials");
     shift @$rargs;
     $action = "config";
     $component = "agent";
     @args = ($action, $component, @$rargs);
     configAgent( \@args );
     return 0;
   }
   elsif ( $argCount >= 2 and $rargs->[1] eq "blackout" )
   {
      $action = $rargs->[0];
      traceDebug("AgentStatus.pm:Processing $action blackout");
      if ( $action eq "start" or $action eq "stop" )
      {
         if ( $argCount == 2 )
         {
            displayHelpBlackout();
            return 0; #originally it was displaying the help for whole system.
                   #I think conditon should cause a blackout specific message.
                   # BAD Usage..
         }
         else
         {
           $rc = blackoutCEMD( $rargs );
           $result = 0; #emctl done
         }
       }
       elsif ($action eq "status")
       {
          $rc = blackoutCEMD( $rargs );
          $result = 0; #emctl done
       }
       else
       {
          displayHelpBlackout();
          $result = 0; #DONE
       }
   }
   elsif ( ($argCount == 1 ) and ($rargs->[0] eq "reload" or
                                  $rargs->[0] eq "upload" or
                                  $rargs->[0] eq "pingOMS" ) )
   {
      # we should obsolete this usage.
      traceDebug("AgentStatus.pm:Processing $rargs->[0]");
      reloadCEMD($rargs);
      $result = $EMCTL_DONE;
   }
   elsif ($argCount == 2 and $rargs->[0]  eq "switchOMS")
   {
     switchOMS($rargs->[1]);
     return 0;
   }
   elsif ( $argCount == 1 and $rargs->[0] eq "verifykey")
   {
     verifyKey();
     return 0;
   }
   elsif ( $argCount == 1 and $rargs->[0] eq "gensudoprops")
   {
     genSudoProps();
     return 0;
   }
   elsif ( $argCount == 1 and $rargs->[0] eq "clearsudoprops")
   {
     clearSudoProps();
     return 0;
   }
   else
   {
     $result = $EMCTL_UNK_CMD; # UNK_CMD
   }
   return $result;
} 

sub statusCEMD()
{
  local (*args) = @_;
  shift(@args); # -- shift out "status"
  shift(@args); # -- shift out "agent"

  testCEMDAvail();
  my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
  close $fh; # closing to prevent file sharing violations on Windows

  print "---------------------------------------------------------------\n";
  $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent @args 2> $tmpfilename");
  $rc >>= 8;
  traceDebug("AgentStatus.pm:emdctl status returned $rc");

  if( $rc == 1 )
  {
    print "Agent is Not Running\n";
  }    
  elsif( $rc == 3 )
  {
    print "---------------------------------------------------------------\n";
    print "Agent is Running and Ready\n";
    $rc = 0;
  }
  elsif( $rc == 4 )
  {
    print "---------------------------------------------------------------\n";
    print "Agent is Running but Not Ready\n";
    $rc = 0;
  }
  elsif( $rc == 8 )
  {
    print "---------------------------------------------------------------\n";
    print "\n";
    $rc = 0;
  }
  elsif(9 == $rc)           # 9 represents usage error in nmectl
  {
    statusUsage();
  }
  else
  {
    traceDebug("AgentStatus.pm:Abnormal exit code.");
    open ($fh,"<$tmpfilename") or die "Error opening file $tmpfilename: $!\n";
    while (<$fh>) {
      print STDERR;
    }
    close $fh or warn "Error closing file $tmpfilename: $!\n";
  }
  unlink("$tmpfilename");
  return $rc;
}

sub controlCEMD()
{
  local (*args) = @_;
  shift(@args); # -- shift out "control"
  shift(@args); # -- shift out "agent"

  testCEMDAvail();
  print "---------------------------------------------------------------\n";
  $rc = 0xffff & system("$EMDROOT/bin/emdctl @args");
  $rc >>= 8;
  if(9 == $rc)
  {
     usage;
  }
  traceDebug("AgentStatus.pm:emdctl @args returned $rc");
  exit $rc;
}

sub usage {

  statusUsage();
  reloadUsage();
  configUsage();

  print "        emctl resetTZ agent\n";
  print "        emctl resettzhost <hostname> <override_timezone>\n";
  print "        emctl getversion\n";
  print "        emctl updatechangets agent\n";
  print "        emctl dumpstate agent <component> . . .\n";
  print "        emctl gensudoprops\n";
  print "        emctl clearsudoprops\n";
  print "        emctl switchOMS <reposUrl>\n";
  print "        emctl verifykey\n";
  displayHelpBlackout();
}

#Displays specific help message for status agent

sub statusUsage()
{
   print "  Status Usage:\n";
   print "        emctl status agent\n";
   print "        emctl status agent -secure [-omsurl <http://<oms-hostname>:<oms-unsecure-port>/em/*>]\n";
  print "\n";
}

#Displays specific help message for reload agent

sub reloadUsage()
{
      print "  Reload Usage:\n";
      print "        emctl reload agent\n";
      print "        emctl reload agent dynamicproperties [<Target_name>:<Target_Type>]...\n";
      print "\n";
          
}

#Displays specific help message for config agent

sub configUsage()
{
      print "  Config Usage:\n";
      print "        emctl config agent <options>\n";
      print "        emctl config agent updateTZ\n";
      print "        emctl config agent getTZ\n";
      print "        emctl config agent credentials [<Target_name>[:<Target_Type>]]\n";
      print "\n";
}

# 
# sub reload agent
# takes
# 1) $action which is expected to be either reload or upload
#
sub reloadCEMD()
{
  local (*args) = @_;

  testCEMDAvail();
  if($IS_WINDOWS eq "TRUE") 
  {
    ;
  } 
  else
  {
    $ENV{PATH}="";
  }

  if ($EMDROOT =~ /(.*)/) {
      $EMDROOT = $1;
  }

  my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
  close $fh; # closing to prevent file sharing violations on Windows

  print "---------------------------------------------------------------\n";
  $rc = 0xffff & system("$EMDROOT/bin/emdctl status agent >$tmpfilename 2>&1");
  $rc >>= 8;

  traceDebug("AgentStatus.pm:emdctl status agent returned  $rc");
  if($rc == 255)
  {
    open ($fh,"<$tmpfilename") or die "Error opening file $tmpfilename: $!\n";
    while (<$fh>) {
      print STDERR;
    }
    close $fh or warn "Error closing file $tmpfilename: $!\n";
    unlink("$tmpfilename");
    exit -1;
  }
  
  unlink("$tmpfilename");

  if ($rc < 2) 
  { 
    traceDebug("AgentStatus.pm:Agent is not running. Just doing encrypt");
    print "Agent is Not Running\n";
    if($args[0] eq "reload")
    {
      system("$EMDROOT/bin/emdctl encrypt");
      exit 0;
    }
    exit -1;
  }

  my @newargs;
  foreach $my_arg (@args)
  {
      $my_arg =~ /(.*)/;
      push(@newargs, $1);
  }

  $rc = 0xffff & system("$EMDROOT/bin/emdctl @newargs");
  $rc >>= 8;
  if(9 == $rc)
  {
     reloadUsage();
  }
  traceDebug("AgentStatus.pm: emdctl @newargs returned with exit code $rc");

  exit $rc;
}

# 
# sub clearstate agent
# takes
# 1) $action which is expected to be clearstate
#
sub clearCEMDstate()
{
    local ($clearState) = @_;
    testCEMDAvail();
    $rc = 0xffff & system("$EMDROOT/bin/emdctl $clearState");
    $rc >>= 8;
    traceDebug("AgentStatus.pm:emdctl $clearState returned $rc");
    exit $rc;
}

#
# 
# sub updateChangeTS
#
sub dumpState()
{
    local (*args) = @_;
    shift(@args); # -- shift out "dumpstate"
    shift(@args); # -- shift out "agent"

    testCEMDAvail();
    $rc = 0xffff & system("$EMDROOT/bin/emdctl dumpstate agent @args");
    $rc >>= 8;
    traceDebug("AgentStatus.pm:emdctl dumpstate agent @args returned $rc");
    exit $rc;
}

# 
# sub gensudoprops
sub genSudoProps()
{
    $EMHOME = getEMHome();
    $ENV{EMSTATE} = $EMHOME if (!defined($ENV{EMSTATE}));

    $rc = 0xffff & system("$EMDROOT/bin/emdctl gensudoprops");
    $rc >>= 8;
    traceDebug("AgentStatus.pm:emdctl gensudoprops returned $rc");
    return $rc;
}

# sub switchOMS
# It makes agent to change its repository url with the given repository 
# url value
#
sub switchOMS()
{
    my $url    = $_[0];
    
    $EMHOME = getEMHome();

    $ENV{EMSTATE} = $EMHOME if (!defined($ENV{EMSTATE}));
    
    # Passing reposUrl value through STDOUT as switch_oms.pl expects this
    # value through STDIN
    my $pid=open3(\*WRITE, ">&STDOUT", ">&STDERR", "$PERL_BIN/perl $EMDROOT/bin/switch_oms.pl >> $EMHOME/sysman/log/emctl_switch_oms.log");

    print WRITE "reposUrl=$url\n";

    print WRITE "__*END*__\n";

    close WRITE;
    
    waitpid($pid, 0);

    my $rc =  0xffff & $?;
    $rc >>= 8;

    if($rc eq 0)
    {
      print ("SwitchOMS succeeded.\n");
    }
    else
    {
      print ("SwitchOMS failed with ret code $rc.\n");
    }
    return $rc;
}   

#
# sub verifykey
# It reports Key Mismatch, SSL Handshake error between emctl and agent, agent
# and OMS. 
#
sub verifyKey()
{
    $EMHOME = getEMHome();
    $ENV{EMSTATE} = $EMHOME if (!defined($ENV{EMSTATE}));

    testCEMDAvail();
    print("\n-----------------------------------------------------\n");
    $rc = 0xffff & system("$EMDROOT/bin/emdctl verifykey");
    print("\n-----------------------------------------------------\n");
    $rc >>= 8;
    if($rc == 8)
    {
      print("-----------------------------------------------------\n");
      print("\n");
      $rc = 0;
    }
    traceDebug("AgentStatus.pm:emdctl verifykey returned $rc");
    return $rc;
}

# 
# sub clearsudoprops
#
sub clearSudoProps()
{
    $EMHOME = getEMHome();
    $ENV{EMSTATE} = $EMHOME if (!defined($ENV{EMSTATE}));

    SecureUtil::RM ("${EMHOME}/sysman/config/nmosudo.props");
    $rc = 0xffff & system("$EMDROOT/bin/emdctl clearsudoprops");
    $rc >>= 8;
    traceDebug("AgentStatus.pm:emdctl clearsudoprops returned $rc");
    return $rc;
}

#
# blackout agent
# takes
# 1) Array of arguments
#
sub blackoutCEMD()
{
    local (*args) = @_;
    $EMHOME=getEMHome($CONSOLE_CFG);
    $uploadDir = "$EMHOME"."/sysman/emd/upload";
    $stateDir = "$EMHOME"."/sysman/emd/state";
    my $emdPropFile = "$EMHOME"."/sysman/config/emd.properties";

    testCEMDAvail();

    ($agentName,$tzRegion) = getEMAgentNameAndTZ("$emdPropFile");

    ## Disabling STDOUT
    open (FH, "/dev/null");
    select (FH);  # send STDOUT to FH

    $rcv = validateTZAgainstAgent($tzRegion);
    select (STDOUT);

    if ( $rcv != 0 )
    {
      my $tzj = getTZFromJava();

      traceDebug("Mismatch detected between timezone in env ($tzj) and in $emdPropFile ($tzRegion). Forcing value to latter..\n");

      $rcf = forceTZRegionValue($tzRegion);
      if ( $rcf != 0 )
      {
        $message = "The agentTZRegion value in $emdPropFile is not in agreement with what agent thinks it should be.Please verify your environment to make sure that TZ setting has not changed since the last start of the agent\.\n"."If you modified the timezone setting in the environment, please stop the agent and exectute 'emctl resetTZ agent' and also execute the script mgmt_target.set_agent_tzrgn(<agent_name>, <new_tz_rgn>) to get the value propagated to repository.";

        traceDebug("$message : \n");
        print("Blackout not Applied\n");
        exit $rcf;
      }
    }
    $rc = 0xffff & system("$EMDROOT/bin/emdctl @args");
    $rc >>= 8;
    if($rc ==  9 )
    {
      displayHelpBlackout();
    }
    traceDebug("AgentStatus.pm:emdctl @args returned $rc");
    exit $rc;
}

sub displayHelpBlackout()
{
    print " Blackout Usage : \n";
    print "       emctl start blackout <Blackoutname> [-nodeLevel] [<Target_name>[:<Target_Type>]].... [-d <Duration>]\n";
    print "       emctl stop blackout <Blackoutname>\n";
    print "       emctl status blackout [<Target_name>[:<Target_Type>]]....\n\n";   
    print "The following are valid options for blackouts\n";
    print "<Target_name:Target_type> defaults to local node target if not specified.\n";
    print "If -nodeLevel is specified after <Blackoutname>,the blackout will be applied to all targets";
   print " and any target list that follows will be ignored.\n ";
    print "Duration is specified in [days] hh:mm\n";
    print "\n";
}

#
# Config Agent takes
# 1) Array of arguments
#
# Original : emctl config console ...
#            emctl config addTarget ...
#            emctl config deleteTarget ...
#            emctl set credential ...
# Modified :
#            emctl config console ...
#            emctl config agent addTarget ...
#            emctl config agent deleteTarget ...
#            emctl config agent credential ...
#
sub configAgent()
{
  local (*args) = @_;

  if ($args[1] eq "agent") #emctl config agent
  {
    shift(@args);                  # -- shift out config...
    if ($args[1] eq "credentials") #emctl config agent credentials
    {
      shift(@args);                # -- shift out agent ...
      testCEMDAvail();

      $rc = 0xffff & system ("$EMDROOT/bin/emdctl set @args"); # emdctl set credential <args>
      $rc >>= 8;
      if(9 == $rc)
      {
         configUsage();
      } 
      traceDebug("AgentStatus.pm:emdctl set @args returned $rc");
      exit $rc;
    }
  }

  shift(@args);                     # -- shift out config or agent...

  delete($ENV{EMSTATE});
  delete($ENV{REMOTE_EMDROOT});
  $EMHOME= $ENV{EMHOME};
  traceDebug("AgentStatus.pm:EMHOME is $EMHOME");

  my $emdPropFile = "$EMHOME"."/sysman/config/emd.properties";
  my $emdPropFilePerm = getFilePermission($emdPropFile);

  $rc = 0xffff & system("${JRE_HOME}/bin/java -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar @args");

  #reset file permissions
  restoreFilePermissions($emdPropFilePerm, "$emdPropFile");

  $rc >>= 8;
  traceDebug("AgentStatus.pm: ${JRE_HOME}/bin/java -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar @args returned $rc");
  exit $rc;
}

#
# subroutine to status the cemd [internal]
#
sub istatusCEMD()
{
  testCEMDAvail();

  my($fh,$tmpfilename) = tempfile($UNLINK => 1, DIR => "$EM_TMP_DIR");
  close $fh; # closing to prevent file sharing violations on Windows
  my($status) = 0xffff & system("$EMDROOT/bin/emdctl status agent >$tmpfilename 2>&1");
  $status >>= 8;
  traceDebug("AgentStatus.pm:emdctl status agent returned $status");
  if($status == 255)
  {
    open ($fh,"<$tmpfilename") or die "Error opening file $tmpfilename: $!\n";
    while (<$fh>) {
      print STDERR;
    }
    close $fh or warn "Error closing file $tmpfilename: $!\n";
  }

  if (($status == 3) || ($status == 4))
  {
    open ($fh,"<$tmpfilename") or die "Error opening file $tmpfilename: $!\n";
    while (<$fh>) {
      if ($_ =~ /Agent Process ID/)
      {
        my($str, $pid) = split(/:/);
        $pid =~ s/^\s+|\s+$//g;
        $self->{PID} = $pid;
        last;
      }
    }
    close $fh or warn "Error closing file $tmpfilename: $!\n";
  }
  unlink("$tmpfilename");
  return $status;
}

#
# getPID
# returns teh PID for emagent process
#
sub getPID
{
  return $self->{PID};
}

#resets the agent time zone setting in emd.properties. Also clears the
#state directory,upload directory. 
sub resetTZ()
{
  $EMHOME=getEMHome($CONSOLE_CFG);
  $uploadDir = "$EMHOME"."/sysman/emd/upload";
  $stateDir = "$EMHOME"."/sysman/emd/state";
  my $emdPropFile = "$EMHOME"."/sysman/config/emd.properties";
  my $emdPropFilePerm = getFilePermission($emdPropFile);
  $status = istatusCEMD();
  if( $status == 1 )
  {
       
      $retVal1 = clearDirContents($uploadDir);
      $retVal2 = clearDirContents($stateDir);
      if( ($retVal1 == 1 ) || ($retVal2 == 1) )
      {
        print("Some files in $uploadDir or $stateDir couldn't be removed.Delete them manually and rerun the command.\n");
        exit(1);
      }

      # Store the old timezone region for later comparision
      ($agentName,$oldtzRegion) = getEMAgentNameAndTZ("$emdPropFile");
      my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
      close $fh; # closing to prevent file sharing violations on Windows
      print ("Updating $emdPropFile...\n");
      $rc = 0xffff & system("$JRE_HOME/bin/java -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar updateTZ > $tmpfilename 2>&1");
      
      #reset file permissions
      restoreFilePermissions($emdPropFilePerm, "$emdPropFile");

      $rc >>= 8;
      if ($rc == 1 )
      {
          open ($fh,"<$tmpfilename");
          while (<$fh>) {
              print("$_");
          }
          close $fh;

        print("resetTZ:Failed to update  the property 'agentTZRegion' in $emdPropFile.Needs to be manually updated.Execute 'emctl config agent getTZ' to see if this value is appropriate.");
        unlink("$tmpfilename");
        exit(1);
      }
      unlink("$tmpfilename");
      ($agentName,$tzRegion) = getEMAgentNameAndTZ("$emdPropFile");

      if ( $oldtzRegion ne $newtzRegion)
      {
    updateBlackoutsXmlTS($oldtzRegion, $tzRegion);
      }

      $rc = validateTZAgainstAgent($tzRegion);
      if ( $rc != 0 )
      {
        print("resetTZ failed.\n");
        print("The agentTZRegion in:\n");
        print("$emdPropFile\n"); 
        print("is not in agreement with what the agent thinks it should be.\n"); 
        print("Fix your environment.\n");
        print("Pick a TZ value that corresponds to time zone settings listed in:\n");
        print("$EMDROOT/sysman/admin/supportedtzs.lst\n");      
        exit($rc);
      }

      print("Successfully updated $emdPropFile.\n");
      print("Login as the em repository user and run the  script:\n");
      print("exec mgmt_target.set_agent_tzrgn(\'$agentName\',\'$tzRegion\')\n");
      print("and commit the changes\n");
      print("This can be done for example by logging into sqlplus and doing\n");
      print("SQL> exec mgmt_target.set_agent_tzrgn(\'$agentName\',\'$tzRegion\')\n");
      print("SQL> commit\n");
      exit(0);
  }
  else
  {
    print("Agent is running. Stop the agent and rerun the command.\n");
    exit(1);
  }
}

sub clearDirContents()
{
  my ($dirname) = @_;
  my $retVal = 0;
  
  opendir(DIR, $dirname) or die "Delete the files manually from dir $dirname,can't opendir $dirname: $!";
  while (defined($filename = readdir(DIR))) {
    $filename = "$dirname"."/$filename";
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

1;
