#
#  $Header: emagent/scripts/unix/SecureAgentCmds.pm /st_emagent_10.2.0.5.3as11/3 2009/03/30 18:52:23 pchebrol Exp $
#
#
# Copyright (c) 2003, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      SecureAgentCmds.pm - Secure Agent Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    pchebrol    03/13/09 - Fix classpath
#    pchebrol    03/06/09 - Add secure fmagent
#    nigandhi    01/09/09 - bug 7696444: Preserve permissions on emd.properties
#    pchebrol    12/19/08 - Fix secure status when walletSrcUrl is https
#    mvajapey    11/25/08 - rollback changes from
#                           swexler_emctl_changes_ag_10.2.0.5
#    swexler     04/11/08 - fix
#    pchebrol    10/16/08 - Update Usage
#    pchebrol    09/19/08 - Bug 7385844
#    pchebrol    09/04/08 - Add addexternalcert verb
#    pchebrol    08/28/08 - Cutover to single invocation
#    danili      08/30/07 - 6206690: Add encryption feature to nmosudo
#    danili      08/31/07 - XbranchMerge danili_bug-6206690 from main
#    pchebrol    08/03/07 - Backport shianand_ag5121288 from main
#    shianand    11/07/06 - add diag for bug 5441209
#    shianand    11/07/06 - add diag for bug 5441209
#    svrrao      10/10/06 - Porting Changes, Fixing check hostname in certificate
#    shianand    07/21/06 - Backport shianand_ag4766676 from main 
#    shianand    12/02/05 - Backport shianand_ag4570579 from main 
#    shianand    11/10/05 - fix the password from command line 
#    shianand    12/02/05 - Backport shianand_bug-4511157 from main 
#    shianand    11/04/06 - fix bug 4766676 
#    shianand    11/14/05 - fix bug 4686120 
#    shianand    11/14/05 - fix bug 4481271 
#    shianand    11/14/05 - fix bug 4360441 
#    shianand    08/30/05 - 
#    shianand    07/11/05 - shianand_ref_ag
#    shianand    03/31/05 - Created
#
#

package SecureAgentCmds;

use English;
use strict;
use vars '*args';

use EmCommonCmdDriver;
use EmctlCommon;

use SecureUtil;

my $ORACLE_HOME     = $ENV{ORACLE_HOME};
my $EMDROOT         = $ENV{EMDROOT};
my $IS_WINDOWS      = "";
my $redirectStderr  = "2>&1";

my $agentMode       = &SecureUtil::getAgentMode();
my $emAgentHome     = &SecureUtil::getEMHome($agentMode);
my $securelog       = "$emAgentHome/sysman/log/secure.log";
SecureUtil::setLogFile($securelog);

SecureUtil::setDebug($ENV{EM_SECURE_VERBOSE});
my $debug = SecureUtil::getDebug;

my $cpSep  = ":";
my $OSNAME          = $^O;
if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
   $IS_WINDOWS="TRUE";
   $cpSep = ";";
}
else
{
   $IS_WINDOWS="FALSE";
}

sub new
{
  my $classname = shift;
  my $self = { };
  bless ($self, $classname);
  return $self;
}


sub doIT
{
  my $classname = shift;
  my $rargs     = shift;
  my $result    = $EMCTL_UNK_CMD; #Unknown command.

  my $argCount  = @$rargs;
  if ($argCount >= 2  && $rargs->[0] eq "secureold")
  {
    if($rargs->[1] eq "agent")
    {
       secureOld($rargs);
       $result = $EMCTL_DONE;
    }
    else
    {
       $result =  $EMCTL_UNK_CMD;
    }
  }
  elsif ($argCount >= 2  && $rargs->[0] eq "secure")
  {
    if($rargs->[1] eq "agent")
    {
       secure($rargs);
       $result = $EMCTL_DONE;
    }
    elsif($rargs->[1] eq "fmagent")
    {
       secureFMAgent($rargs);
       $result = $EMCTL_DONE;
    }
    elsif($rargs->[1] eq "add_trust_cert")
    {
       addTrustCert($rargs);
       $result = $EMCTL_DONE;
    }
    else
    {
       $result =  $EMCTL_UNK_CMD;
    }
  }
  elsif ($argCount >= 2  && $rargs->[0] eq "unsecure")
  {
    if($rargs->[1] eq "agent" || $rargs->[1] eq "fmagent")
    {
       unsecure($rargs);
       $result = $EMCTL_DONE;
    }
    else
    {
       $result =  $EMCTL_UNK_CMD;
    }
  }
  else
  {
    $result = $EMCTL_UNK_CMD;
  }
  return $result;
}

sub usage {
    print "Secure Agent Usage : \n";
    print "emctl secure fmagent -admin_host <host> -admin_port <port> -admin_user <username> [-admin_pwd <pwd>]\n";
    print "emctl unsecure fmagent -admin_host <host> -admin_port <port> -admin_user <username> [-admin_pwd <pwd>]\n";
    print "emctl secure add_trust_cert -trust_certs_loc <loc>\n\n";
}

#
# secureStatus takes
# 1) Array of arguments
#
sub secureStatus
{
  my $component    = $_[0];
  my $omsUrl       = $_[1];
  my $agentUrl     = "";

  my $httpsPortCmd = "";
  my $httpsPort    = "";
  my $statusAtOMS   = "false";
  my $statusAtAgent = "false";
  my $propFile;
  my $statusArgs;

  my $javaStr      = "";
  my $classPath    = "";
  my $rc;

  my $emAgentMode      = &SecureUtil::getAgentMode();
  my $emHome           = &SecureUtil::getEMHome($emAgentMode);
  my $emdPropFile      = "$emHome/sysman/config/emd.properties";
  my ($protocol,$machine,$port,$ssl);
  my %agentProps;

  if (-e "$ORACLE_HOME/sysman/config/emoms.properties")
  {
    $statusAtOMS = "true";
    $classPath   = &SecureUtil::getConsoleClassPath("");
    $propFile    = "$ORACLE_HOME/sysman/config/emoms.properties";
  }
  else
  {
    $statusAtOMS = "false";
    $classPath   = &SecureUtil::getAgentClassPath;
    $propFile    = "$ORACLE_HOME/sysman/config/emd.properties";
  }

  if ($omsUrl eq "")
  {
    if ($component eq "oms")
    {
      $statusAtAgent = "false";
    }
    elsif ($component eq "agent")
    {
      $statusAtAgent = "true";
      if ($emAgentMode ne "")
      {
        if ($emAgentMode eq "CENTRAL_AGENT")
        {
          %agentProps  = &SecureUtil::parseFile($emdPropFile);
          if (defined($agentProps{"REPOSITORY_URL"}))
          {
             $omsUrl = $agentProps{"REPOSITORY_URL"};
             if ($omsUrl =~ /https/)
             {
               ($protocol,$machine,$port,$ssl) = &SecureUtil::parseURL($agentProps{"emdWalletSrcUrl"});
               my @url = split(/:/, $omsUrl);
               my @upload_dir = split(/\//,$url[2]);
               $omsUrl ="$protocol:$url[1]:$port/$upload_dir[1]/$upload_dir[2]/\n";
               chomp($omsUrl);
             }
          }
        }
      }
      else
      {
        $statusAtAgent = "false";
      }
    }
  }
  else
  {
    if ($component eq "oms")
    {
      $statusAtAgent = "false";
    }
    if ($component eq "agent")
    {
      if ($emAgentMode ne "")
      {
        $statusAtAgent = "true";
      }
      else
      {
        $statusAtAgent = "false";
      }
    }
  }

  if ($statusAtAgent eq "true")
  {
    SecureUtil::USERINFO ("Checking the security status of the Agent at location set in $emdPropFile...");
    %agentProps  = &SecureUtil::parseFile($emdPropFile);
    ($protocol,$machine,$port,$ssl) = &SecureUtil::parseURL($agentProps{"EMD_URL"});
    SecureUtil::USERINFO ("  Done.\n");
    if($ssl eq "Y")
    {
       SecureUtil::USERINFO ("Agent is secure at HTTPS Port $port.\n");
    }
    else
    {
       SecureUtil::USERINFO ("Agent is unsecure at HTTP Port $port.\n");
    }
  }

   SecureUtil::USERINFO ("Checking the security status of the OMS at ");
  if ($omsUrl eq "")
  {
     SecureUtil::USERINFO ("location set in $propFile...");
    if ($statusAtOMS eq "true")
    {
      $statusArgs = "-localOMS";
    }
    else
    {
      $statusArgs = "";
    }
  } 
  else
  {
    SecureUtil::USERINFO ("$omsUrl...");
    $statusArgs = $omsUrl;
  }
  $javaStr = "$JAVA_HOME/bin/java ".
                   "-cp $classPath ".
                   "-DpropertiesFile=$propFile ".
                   "-Ddebug=$debug ".
                   "oracle.sysman.eml.sec.emd.GetSecPort $statusArgs ".
                   ">> $securelog";
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    SecureUtil::USERINFO ("  Done.\n");
    $httpsPortCmd = "$JAVA_HOME/bin/java ".
                    "-cp $classPath ".
                    "-DpropertiesFile=$propFile ".
                    "-Ddebug=$debug ".
                    "oracle.sysman.eml.sec.emd.GetSecPort $statusArgs";
    $httpsPort = `$httpsPortCmd`;
    $httpsPort =~ s/^\s+|\s+$//;
    SecureUtil::USERINFO ("OMS is secure on HTTPS Port $httpsPort\n");
  }
  else
  {
    if ( $rc eq 2 )
    {
      SecureUtil::USERINFO ("   Done.\n");
      SecureUtil::USERINFO ("OMS is running but has not been secured. No HTTPS Port available.\n");
    }
    else
    {
      SecureUtil::USERINFO ("   Failed.\n");
      SecureUtil::USERINFO ("Could not connect to the OMS.");
    }
  }
  return $rc;
}

sub secure
{
  local (*args) = @_;
  shift(@args);
  my $component = @args->[0];
  my $argCount  = scalar(@args);

  my $regPassword = "";
  my $passwdFile   = "";

  if($component ne "agent")
  {
    exit $EMCTL_BAD_USAGE;
  }
  my $emAgentMode = SecureUtil::getAgentMode;

  if ($emAgentMode eq "")
  {
    SecureUtil::USERINFO ("Cannot determine Agent type from emd.properties\n");
  }
  else
  {
    if ($emAgentMode ne "STANDALONE")
    {
      # perform secure agent setup using password
      secureAgent($args);
    }
    else
    {
      exit $EMCTL_BAD_USAGE;
    }
  }
}

sub secureOld
{
  local (*args) = @_;
  shift(@args);
  my $component = @args->[0];
  my $argCount  = scalar(@args);
  
  my $regPassword = "";
  my $passwdFile   = "";

  if ($component eq "agent")
  {
    if ($argCount eq 1)
    {
      $regPassword = &EmctlCommon::promptUserPasswd("Enter Agent Registration password : ");
    } 
    elsif ($argCount eq 2)
    {
        $regPassword = @args->[1];
    }
    elsif ($argCount eq 3)
    {
      if (@args->[1] eq "-passwd_file")
      {
        $passwdFile      = @args->[2];
       
        my $secPasswds    = SecureUtil::getSecPasswdFile($passwdFile);
        my @tempPasswds   = @$secPasswds;
        $regPassword      = $tempPasswds[0];
        if ($regPassword eq "")
        {
          SecureUtil::INFO ("Password File empty...   exiting.\n");
          exit $EMCTL_UNK_CMD;
        }
      }
    }
    else
    {
      exit $EMCTL_BAD_USAGE;
    }
  }
  my $emAgentMode = SecureUtil::getAgentMode;

  if ($emAgentMode eq "")
  {
    SecureUtil::USERINFO ("Cannot determine Agent type from emd.properties\n");
  }
  else
  {
    if ($emAgentMode ne "STANDALONE")
    {
      # perform secure agent setup using password
      secureAgentOld($securelog, $emAgentMode, $regPassword);
    }
    else
    {
      exit $EMCTL_BAD_USAGE;
    }
  }
}


sub addTrustCert
{
  local (*args) = @_;
  shift(@args);
  shift(@args);

  my $classPath = &SecureUtil::getAgentClassPath;
  my $emConsoleMode = SecureUtil::getAgentMode;
  my $emHome = &SecureUtil::getEMHome($emConsoleMode);
  my $rc;

  $securelog  = "$emHome/sysman/log/secure.log";
  SecureUtil::setLogFile($securelog);

  $classPath .= $cpSep . "$ORACLE_HOME/jlib/oraclepki.jar";
  $classPath .= $cpSep . "$ORACLE_HOME/jlib/osdt_core.jar";
  $classPath .= $cpSep . "$ORACLE_HOME/jlib/osdt_cert.jar";

  # Use appropriate JAVA Home
  # This check needs to be done only for scripts that run on agent.
  my $JAVA_HOME   = "";
  if (defined($ENV{JRE_HOME}))
  {
    $JAVA_HOME = $ENV{JRE_HOME};
  } 
  if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
  {
    if (defined($ENV{JAVA_HOME}))
    {
      $JAVA_HOME = $ENV{JAVA_HOME};
    }
    if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
    {
      if (-e "$EMDROOT/jre")
      {
        $JAVA_HOME="$EMDROOT/jre";
      }
      elsif (-e "$EMDROOT/jdk")
      {
        $JAVA_HOME="$EMDROOT/jdk";
      }
    }
  }
  die "Cannot determine JAVA_HOME\n" if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"));

  my $addTrustCertCmd = "$JAVA_HOME/bin/java -cp $classPath " .
                       "-DEMSTATE=$emHome " .
                       "-Ddebug=$debug " .
                       "oracle.sysman.emctl.secure.agent.AddTrustedCertToWallet @args";
  SecureUtil::DEBUG ("Executing ... $addTrustCertCmd");

  $rc = 0xffff & system($addTrustCertCmd);
  $rc >>= 8;

  exit $rc;
}

sub unsecure
{
  local (*args)     = @_;
  shift(@args);
  my $argCount      = scalar(@args);
  my $component     = @args->[0];
  my $emConsoleMode = SecureUtil::getConsoleMode;
  my $emAgentMode   = SecureUtil::getAgentMode;
  my $unsecPort     = "";

  if ($component eq "agent" || $component eq "fmagent")
  {
    if ($emAgentMode eq "")
    {
      SecureUtil::USERINFO ("Cannot determine Agent type from emd.properties\n");
      SecureUtil::DEBUG ("Cannot determine Agent type from emd.properties\n");
    }
    else
    {
      if ($emAgentMode eq "STANDALONE")
      {
        SecureUtil::USERINFO ("You must use emctl unsecure em/iasconsole\n");
        SecureUtil::DEBUG ("$emAgentMode Console.\n");
      }
      else
      {
        SecureUtil::DEBUG ("unsecure $component\n");
        shift(@args);
        while(scalar(@args) gt 0)
        {
           if($args[0] eq "-port")
           {
              shift(@args);
              $unsecPort = $args[0];
              shift(@args);
           }
           else
           {
              exit $EMCTL_UNK_CMD;
           }
        }
        unsecureAgent($emAgentMode, $securelog, $unsecPort);
      }
    }
  }
  else
  {
    exit  $EMCTL_BAD_USAGE;
  }
}



# [] ----------------------------------------------------------------- []

sub configureAgent
{
  my $securelog           = $_[0];
  my $emConsoleMode       = $_[1];
  my $em_upload_https_url = $_[2];

  my $no_changes;
  my $configureAgentOk = 1;
  my $agentURLStringLog;

  SecureUtil::USERINFO ("Configuring Agent for HTTPS in $emConsoleMode mode...");
  my $emHome = &SecureUtil::getEMHome($emConsoleMode);

  my $propertiesFileOrig = "$emHome/sysman/config/emd.properties";
  my $propertiesFileNew  = "$emHome/sysman/config/emd.properties.$$";

  my $propertiesFileOrigPerm = getFilePermission($propertiesFileOrig);

  open(PROPFILE,$propertiesFileOrig) or die "Can not read EMD.PROPERTIES ($propertiesFileOrig)";
  my @emdURLlinesRead = grep /EMD_URL=http/, <PROPFILE>;
  close(PROPFILE) or die "Can not close EMD.PROPERTIES ($propertiesFileOrig)";
  my $numLinesEMDURL = scalar @emdURLlinesRead;
  if ( $numLinesEMDURL <= 0  )
  {
    SecureUtil::USERINFO ("Warning:\n");
    SecureUtil::USERINFO ("Unable to configure $propertiesFileOrig\n");
    SecureUtil::USERINFO ("You must set the EMD_URL and REPOSITORY_URL in\n");
    SecureUtil::USERINFO ("$propertiesFileOrig to use HTTPS\n");
  }
  else
  {
    if ( $em_upload_https_url eq "-1" )
    {
      # really should not be here if the OMS is not secure
      SecureUtil::USERINFO ("   Failed.\n");
    }
    else
    {
      open(FILE,$propertiesFileOrig) or die "Can not read EMD.PROPERTIES ($propertiesFileOrig)";
      my @linesRead = <FILE>;
      close(FILE);

      # 
      # If the Console type is STANDALONE (for iAS or DBA Studio) then there 
      # is no RESPOSITORY_URL for upload.
      #
      # If the Console type is DBCONSOLE then there is already a 
      # RESPOSITORY_URL and this should now change to https on the same
      # port because the Stand Alone OC4J will now be listening using https
      #
      # If the Console type is CENTRAL_AGENT then there is already a
      # RESPOSITORY_URL and this should now change to be the new url that is 
      # expected in the parameter list.
      #

      ;# Walk the lines, and write to new file
      $no_changes = 0;
      if ($emConsoleMode eq "STANDALONE")
      {
        # there is no need to modify REPOSITORY_URL with an
        # upload URL on a different https port for the Standalone Console
        if ( open(FILE,">" . $propertiesFileNew) )  {
           foreach $_ (@linesRead) {
             ;# Change HTTP with HTTPS
             if (/EMD_URL=http/) {
                s/http\:/https\:/;
                $no_changes = 1;
             }
             ;# Print the property line
             print(FILE $_);
           }
           close(FILE);
        } else {
          die "Can not write new EMD.PROPERTIES ($propertiesFileNew)";
        }
      }
      if ($emConsoleMode eq "DBCONSOLE")
      {
        # there is no need to modify REPOSITORY_URL with an
        # upload URL on a different https port for the Standalone Console
        if ( open(FILE,">" . $propertiesFileNew) )  {
           foreach $_ (@linesRead) {
             ;# Change HTTP with HTTPS
             if (/EMD_URL=http/) {
                s/http\:/https\:/;
                $no_changes = 1;
             }
             ;# Replace the REPOSITORY_URL property
             if (/REPOSITORY_URL=/) {
                s/http\:/https\:/;
             }
             ;# Print the property line
             print(FILE $_);
           }
           close(FILE);
        } else {
          die "Can not write new EMD.PROPERTIES ($propertiesFileNew)";
        }
      }
      if ($emConsoleMode eq "CENTRAL_AGENT")
      {
        if ( open(FILE,">" . $propertiesFileNew) )  {
           foreach $_ (@linesRead) {
             ;# Change HTTP with HTTPS
             if (/EMD_URL=http/) {
                s/http\:/https\:/;
                $no_changes = 1;
             }
             ;# Replace the REPOSITORY_URL property
             if (/REPOSITORY_URL=/) {
                $_ = "REPOSITORY_URL=$em_upload_https_url";
             }
             ;# Print the property line
             print(FILE $_);
           }
           close(FILE);
        } else {
          die "Can not write new EMD.PROPERTIES ($propertiesFileNew)";
        }
      }
      SecureUtil::CP ($propertiesFileOrig, "$propertiesFileOrig.bak.$$");
      SecureUtil::CP ($propertiesFileNew, $propertiesFileOrig);
      SecureUtil::RM ($propertiesFileNew); 

      #restore permissions on emd.properties
      restoreFilePermissions($propertiesFileOrigPerm, "$propertiesFileOrig");

      SecureUtil::USERINFO ("   Done.\n");

      ;# Sanity check
      if ($no_changes == 0) {
         $agentURLStringLog = "Warning: failed to reset set EMD_URL.";
         $configureAgentOk  = 1;
      } else {
        $agentURLStringLog  = "EMD_URL set in $propertiesFileOrig";
         $configureAgentOk  = 0;
      }
      SecureUtil::USERINFO ("$agentURLStringLog\n");
    }
    return $configureAgentOk;
  }
}

# [] ----------------------------------------------------------------- []

sub secureAgent
{
  local(*args) = @_;
  shift(@args);

  my $javaStr;
  my $classPath;
  my $rc;
  my $emConsoleMode = SecureUtil::getAgentMode;
  my $emHome = &SecureUtil::getEMHome($emConsoleMode);
  my $printDebugMsg;

  $securelog  = "$emHome/sysman/log/secure.log";
  SecureUtil::setLogFile($securelog);

  # Use appropriate JAVA Home
  # This check needs to be done only for scripts that run on agent.
  my $JAVA_HOME   = "";
  if (defined($ENV{JRE_HOME}))
  {
    $JAVA_HOME = $ENV{JRE_HOME};
  }
  if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
  {
    if (defined($ENV{JAVA_HOME}))
    {
      $JAVA_HOME = $ENV{JAVA_HOME};
    }
    if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
    {
      if (-e "$EMDROOT/jre")
      {
        $JAVA_HOME="$EMDROOT/jre";
      }
      elsif (-e "$EMDROOT/jdk")
      {
        $JAVA_HOME="$EMDROOT/jdk";
      }
    }
  }
  die "Cannot determine JAVA_HOME\n" if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"));

  $classPath = &SecureUtil::getAgentClassPath;

  my $propfile = "$emHome/sysman/config/emd.properties";

  my $propfilePerm = getFilePermission($propfile);

  my $stopStatus = stopAgent($securelog);
  if ($stopStatus eq 0 or $stopStatus eq 1)
  {
    SecureUtil::USERINFO ( "Securing agent...   Started.\n");
  }
  else
  {
    SecureUtil::USERINFO ( "Securing agent...   Aborted.\n");
    exit 2;
  }

  my $secureAgentCmd = "$JAVA_HOME/bin/java -cp $classPath " .
                       "-DEMSTATE=$emHome " .
                       "-Ddebug=$debug " .
                       "oracle.sysman.emctl.secure.agent.SecureAgentCmd @args";
  SecureUtil::DEBUG ("Executing ... $secureAgentCmd");

  $rc = 0xffff & system($secureAgentCmd);
  $rc >>= 8;

  #restore permissions on emd.properties
  restoreFilePermissions($propfilePerm, "$propfile");

  if ($stopStatus eq 0)
  {
    restartAgent($securelog);
  }

  if($rc != 0)
  {
    SecureUtil::DEBUG ("Securing of Agent failed with exit code: " + $rc);
    SecureUtil::USERINFO ( "Securing agent...   Failed.\n");
  }
  else
  {
    SecureUtil::USERINFO ( "Securing agent...   Successful.\n");

    # Generate nmosudo encryption keys
    &AgentStatus::genSudoProps();
  }

  exit $rc;
}

sub secureFMAgent
{
  local (*args) = @_;
  shift(@args); 
  shift(@args);

  my $javaStr;
  my $classPath;
  my $rc;
  my $emConsoleMode = SecureUtil::getAgentMode;
  my $emHome = &SecureUtil::getEMHome($emConsoleMode);

  $securelog  = "$emHome/sysman/log/secure.log";
  SecureUtil::setLogFile($securelog);

  # Use appropriate JAVA Home
  # This check needs to be done only for scripts that run on agent.
  my $JAVA_HOME   = "";
  if (defined($ENV{JRE_HOME}))
  {
    $JAVA_HOME = $ENV{JRE_HOME};
  }
  if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
  {
    if (defined($ENV{JAVA_HOME}))
    {
      $JAVA_HOME = $ENV{JAVA_HOME};
    }
    if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
    {
      if (-e "$EMDROOT/jre")
      {
        $JAVA_HOME="$EMDROOT/jre";
      }
      elsif (-e "$EMDROOT/jdk")
      {
        $JAVA_HOME="$EMDROOT/jdk";
      }
    }
  }
  die "Cannot determine JAVA_HOME\n" if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"));

  $classPath = &SecureUtil::getAgentClassPath;
  $classPath .= $cpSep . "$ORACLE_HOME/jlib/oraclepki.jar";
  $classPath .= $cpSep . "$ORACLE_HOME/jlib/osdt_core.jar";
  $classPath .= $cpSep . "$ORACLE_HOME/jlib/osdt_cert.jar";
  $classPath .= $cpSep . "$ORACLE_HOME/sysman/jlib/wljmxclient.jar";
  $classPath .= $cpSep . "$ORACLE_HOME/jlib/wljmxclient.jar";

  my $propfile = "$emHome/sysman/config/emd.properties";

  my $propfilePerm = getFilePermission($propfile);

  my $stopStatus = stopAgent($securelog);
  if ($stopStatus eq 0 or $stopStatus eq 1)
  {
    SecureUtil::USERINFO ( "Securing agent...   Started.\n");
  }
  else
  {
    SecureUtil::USERINFO ( "Securing agent...   Aborted.\n");
    exit 2;
  }

  my $secureAgentCmd = "$JAVA_HOME/bin/java -cp $classPath " .
                       "-DEMSTATE=$emHome " .
                       "oracle.sysman.emctl.secure.agent.SecureFMAgentCmd @args";
  SecureUtil::DEBUG ("Executing ... $secureAgentCmd");

  $rc = 0xffff & system($secureAgentCmd);
  $rc >>= 8;

  #restore permissions on emd.properties
  restoreFilePermissions($propfilePerm, "$propfile");

  if ($stopStatus eq 0)
  {
    restartAgent($securelog);
  }

  if($rc != 0)
  {
    SecureUtil::DEBUG ("Securing of Agent failed with exit code: " + $rc);
    SecureUtil::USERINFO ( "Securing agent...   Failed.\n");
  }
  else
  {
    SecureUtil::USERINFO ( "Securing agent...   Successful.\n");

    # Generate nmosudo encryption keys
    &AgentStatus::genSudoProps();
  }

  exit $rc;
}

sub secureAgentOld
{
  my $securelog     = $_[0];
  my $emConsoleMode = $_[1];
  my $password      = $_[2];

  my $javaStr;
  my $classPath;
  my $rc;
  my $emHome = &SecureUtil::getEMHome($emConsoleMode);
  my $printDebugMsg;

  $securelog  = "$emHome/sysman/log/secure.log";
  SecureUtil::setLogFile($securelog);

  # Use appropriate JAVA Home
  # This check needs to be done only for scripts that run on agent.
  my $JAVA_HOME   = "";
  if (defined($ENV{JRE_HOME}))
  {
    $JAVA_HOME = $ENV{JRE_HOME};
  }
  if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
  {
    if (defined($ENV{JAVA_HOME}))
    {
      $JAVA_HOME = $ENV{JAVA_HOME};
    }
    if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
    {
      if (-e "$EMDROOT/jre")
      {
        $JAVA_HOME="$EMDROOT/jre";
      }
      elsif (-e "$EMDROOT/jdk")
      {
        $JAVA_HOME="$EMDROOT/jdk";
      }
    }
  }
  die "Cannot determine JAVA_HOME\n" if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"));

  $classPath = &SecureUtil::getAgentClassPath;

  my $propfile = "$emHome/sysman/config/emd.properties";
  # No need to check if the agent is already secured.

  #SecureUtil::USERINFO ( "Stopping agent...\n");
  my $stopStatus = stopAgent($securelog);
  if ($stopStatus eq 0 or $stopStatus eq 1)
  {
    SecureUtil::USERINFO ( "Securing agent...   Started.\n");
  }
  else
  {
    SecureUtil::USERINFO ( "Securing agent...   Aborted.\n");
    exit 2;
  }

  if (not (-e "$emHome/sysman/config/server"))
  {
    mkdir ("$emHome/sysman/config/server", 0755)
  }

  SecureUtil::USERINFO ("Requesting an HTTPS Upload URL from the OMS...");

  my $emUploadHTTPSURLCmd = "$JAVA_HOME/bin/java ".
                            "-cp $classPath ".
                            "-DpropertiesFile=$propfile ".
                            "-Ddebug=false ".
                            "oracle.sysman.eml.sec.emd.GetSecPort -displayURL";

  SecureUtil::DEBUG ("Executing ... $emUploadHTTPSURLCmd");

  my $em_upload_https_url=`$emUploadHTTPSURLCmd`;

  my $verify_em_upload_https_url=$em_upload_https_url;
  $verify_em_upload_https_url=~ s/^\s+|\s+$//;

  SecureUtil::INFO ("OMS HTTPS URL ... $verify_em_upload_https_url");

  if ( $verify_em_upload_https_url eq "-1" )
  {
    SecureUtil::USERINFO ("   Failed.\n");
    SecureUtil::USERINFO ("The OMS is not set up for Enterprise Manager Security.\n");
    exit 3;
  }
  else
  {
    SecureUtil::USERINFO ("   Done.\n");
  }

  SecureUtil::USERINFO ("Requesting an Oracle Wallet and Agent Key from the OMS...");
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DpropertiesFile=$propfile ".
             "-Ddebug=$debug ".
             "oracle.sysman.eml.sec.emd.GetWallet -pwd ".
             ">> $securelog";

  SecureUtil::DEBUG ("Executing ... $javaStr");
  
  open(SETPWD, "|$javaStr");
  print SETPWD "$password\n";
  close(SETPWD);

  $rc = 0xffff & $?;
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    SecureUtil::USERINFO ("   Done.\n");
  }
  else
  {
    SecureUtil::USERINFO ("   Failed.\n");
    if ( $rc eq 1 )
    {
      SecureUtil::USERINFO ("Failed to contact the OMS at the HTTP URL set in $propfile\n");
    }
    elsif ( $rc eq 2 )
    {
      SecureUtil::USERINFO ("Invalid Agent Registration Password.\n");
    }
    SecureUtil::USERINFO ("The Agent has not been secured.\n");
    exit 4;
  }

  # check if the URL is available
  SecureUtil::USERINFO ("Check if HTTPS Upload URL is accessible from the agent...");
  my $checkAvailUrlCmd = "$JAVA_HOME/bin/java ".
                         "-cp $classPath ".
                         "-DpropertiesFile=$propfile ".
                         "-Ddebug=$debug ".
                         "oracle.sysman.eml.sec.emd.CheckURLAvailability ".
                         " $verify_em_upload_https_url >> $securelog $redirectStderr";

  SecureUtil::DEBUG ("Executing ... $checkAvailUrlCmd");

  my $availStatus = 0xfff & system($checkAvailUrlCmd);
  $availStatus >>= 8;
  if ($availStatus == 0) # passed
  {
    SecureUtil::USERINFO ("   Done.\n");
  }
  else
  {
    SecureUtil::USERINFO ("   Failed.\n");
    SecureUtil::USERINFO ("The Agent has not been secured.\n");
    exit 5;
  }

  SecureUtil::INFO ("Checking issuer hostname in the certificate...");
  my $checkHostDnCmd = "$JAVA_HOME/bin/java ".
                         "-cp $classPath ".
                         "-DpropertiesFile=$propfile ".
                         "-Ddebug=$debug ".
                         "oracle.sysman.eml.sec.emd.AuthRepUrl -authConn ".
                         " $verify_em_upload_https_url $redirectStderr;";

  SecureUtil::DEBUG ("Executing ... $checkHostDnCmd\n");
  my $hostDn = `$checkHostDnCmd`;
  $rc = 0xffff & $?;
  $rc >>= 8;
  SecureUtil::INFO ("AuthRepUrl ret $rc.\n");
  if ($rc == 0) # passed
  {
    SecureUtil::INFO ("   Done.\n");
    SecureUtil::INFO ("Host DN : $hostDn\n");
  }
  else
  {
    SecureUtil::INFO ("   Failed.\n");
    SecureUtil::INFO ("Failed Host DN : $hostDn\n");
    
    SecureUtil::INFO ("Retry AuthRepUrl...");

    $hostDn = `$checkHostDnCmd`;
    $rc = 0xffff & $?;
    $rc >>= 8;
    if ($rc == 0) # passed
    {
       SecureUtil::INFO ("   Done.\n");
       SecureUtil::INFO ("Retry AuthRepUrl successful. Host DN : $hostDn\n");
    }
    else
    {
       SecureUtil::INFO ("   Failed.\n");
       SecureUtil::INFO ("Retry AuthRepUrl failed. Host DN : $hostDn\n");
    exit 6;
    }
  }

  $em_upload_https_url = &getRepUrl ($hostDn, $em_upload_https_url);
  SecureUtil::INFO ("URL of Certificate issuing OMS - $em_upload_https_url.\n");

  # configure the properties file
  configureAgent ($securelog, $emConsoleMode, $em_upload_https_url);

  # Generate nmosudo encryption keys
  &AgentStatus::genSudoProps();

  SecureUtil::USERINFO ( "Securing agent...   Successful.\n");
  if ($stopStatus eq 0)
  {
    #SecureUtil::USERINFO ( "Restarting agent...\n");
    restartAgent($securelog);
  }
}


#
#unsecureAgent
#
sub unsecureAgent
{
   my $rc;
   my $securelog = $_[1];
   my $unsecport = $_[2];
   my $emHome    = &SecureUtil::getEMHome($_[0]);
   my $classPath = &SecureUtil::getAgentClassPath;

   my $stopStatus;

   $securelog  = "$emHome/sysman/log/secure.log";
   SecureUtil::setLogFile($securelog);

   # Delete nmosudo encryption keys
   &AgentStatus::clearSudoProps();

   #Use appropriate JAVA Home
   #This check needs to be done only for scripts that run on agent.
   my $JAVA_HOME   = "";
   if(defined($ENV{JRE_HOME}))
   {
      $JAVA_HOME = $ENV{JRE_HOME};
   }
   if(($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
   {
      if(defined($ENV{JAVA_HOME}))
      {
         $JAVA_HOME = $ENV{JAVA_HOME};
      }
         if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"))
         {
            if (-e "$EMDROOT/jre")
            {
               $JAVA_HOME="$EMDROOT/jre";
            }
            elsif (-e "$EMDROOT/jdk")
            {
               $JAVA_HOME="$EMDROOT/jdk";
            }
         }
   }
   die "Cannot determine JAVA_HOME\n" if (($JAVA_HOME eq "") || (! -e "$JAVA_HOME/bin"));

   SecureUtil::USERINFO ("Checking Agent for HTTP...");

   my $file = "$emHome/sysman/config/emd.properties";
   my $propfile = "$emHome/sysman/config/emd.properties";

   my $propfilePerm = getFilePermission($file);

   SecureUtil::DEBUG ("Reading properties from $propfile\n");

   open(PROPFILE,$propfile) or die "Can not read EMD.PROPERTIES ($propfile)";
   my @emdURLlinesRead = grep /EMD_URL=https:/, <PROPFILE>;
   close(PROPFILE) or die "Can not close EMD.PROPERTIES ($propfile)";
   
   SecureUtil::USERINFO ("   Done.\n");

   my $numLinesEMDURL = scalar @emdURLlinesRead;
   if($numLinesEMDURL <= 0)
   {
      SecureUtil::USERINFO ("Agent is already unsecured.\n");
   }
   else
   {
      #SecureUtil::USERINFO ( "Stopping agent...\n");
      $stopStatus = stopAgent($securelog);
      if ($stopStatus eq 0 or $stopStatus eq 1)
      {
         SecureUtil::USERINFO ( "Unsecuring agent...   Started.\n");
      }
      else
      {
         SecureUtil::USERINFO ( "Unsecuring agent...   Aborted.\n");
         exit 2;
      }

      SecureUtil::DEBUG ("Changing secure url to unsecure url.\n");
      my $em_upload_http_url; #this is used to check that given url is available

      open(USERINFO, $file);
      my @lines = <USERINFO>;
      close(USERINFO) || die;

      #Getting the unsecure http port from the emdWalletSrcUrl which communicates
      #with the oms on the unsecure port
      foreach my $readline (@lines)
      {
         if(!($readline =~ /^\#/) and !($readline =~ /^\s+$/))
         {
            if($readline =~ /REPOSITORY_URL=https:/)
            {
               chomp($readline);
               $em_upload_http_url = $readline;
            }
            #use value specified for -port option as unsec port if it is specified
            #else if emdWalletSrcUrl is http url, get port by parsing it
            #else, query the oms for unsecure port. 
            if($unsecport eq "" && $readline =~ /emdWalletSrcUrl=/)
            {
               if($readline =~ /emdWalletSrcUrl=http:/)
               {
                  my @details = split(/:/,$readline);
                  my @checkport = split(/\//,@details[2]);
                  $unsecport = @checkport[0];
                  SecureUtil::DEBUG ("Valid OMS HTTP Port: $unsecport.\n");
               }
               elsif($readline =~ /emdWalletSrcUrl=https:/)
               {
                   my @tempArr = split(/=/,$readline);
                   my $walletsUrl = $tempArr[1];
                   chomp($walletsUrl);
                   my $getHTTPPortcmd = "$JAVA_HOME/bin/java ".
                            "-cp $classPath ".
                            "-DEMSTATE=$emHome ".
                            "-DpropertiesFile=$propfile ".
                            "-Ddebug=false ".
                            "oracle.sysman.emctl.secure.agent.GetUnsecPort $walletsUrl";

                   SecureUtil::DEBUG ("Executing ... $getHTTPPortcmd");
                    my $rcGetUnsecPort = 0xffff & system("$getHTTPPortcmd 1>> $securelog 2>> $devNull");
                    $rcGetUnsecPort >>= 8;
                    if($rcGetUnsecPort ne 0)
                    {
                       SecureUtil::USERINFO (" Failed to find HTTP port of OMS.\n");
                       restoreAgentStatusAndExit($stopStatus,$securelog,3);
                    }
                    $unsecport =`$getHTTPPortcmd`;
                    chomp($unsecport);
               }
            }
         }
      }

      my @rep_url = split(/:/, $em_upload_http_url);
      my @rep_upload_dir = split(/\//,$rep_url[2]);
      $em_upload_http_url ="REPOSITORY_URL=http:@rep_url[1]:$unsecport/$rep_upload_dir[1]/$rep_upload_dir[2]/\n";

      my $verify_em_upload_http_url = "http:@rep_url[1]:$unsecport/$rep_upload_dir[1]/$rep_upload_dir[2]/";
      SecureUtil::DEBUG ("Check REPOSITORY_URL = $verify_em_upload_http_url.\n");

      my $checkAvailUrlCmd = "$JAVA_HOME/bin/java ".
                             "-cp $classPath ".
                             " -DpropertiesFile=$propfile ".
                             " -Ddebug=$debug ".
                             "oracle.sysman.eml.sec.emd.CheckURLAvailability ".
                             " $verify_em_upload_http_url >> $securelog $redirectStderr";

      SecureUtil::DEBUG ("Executing ... $checkAvailUrlCmd");
     
      my $availStatus = 0xfff & system($checkAvailUrlCmd);
      $availStatus >>= 8;
      if ($availStatus == 0) #Passed
      {
          SecureUtil::DEBUG ("OMS http url open.\n");
          
          open (NEWFILE, ">$file.$$") || die "Cannot write to $file.$$\n";
          foreach my $readline (@lines)
          {
             if($readline =~ /REPOSITORY_URL=https:/)
             {
                SecureUtil::DEBUG ("Configured REPOSITORY_URL = $readline.\n");
                $readline = $em_upload_http_url;
             }
             if($readline =~ /EMD_URL=https:/)
             {
                SecureUtil::DEBUG ("Configured EMD_URL = $readline.\n");
                $readline =~ s/https\:/http\:/;
             }

             print NEWFILE "$readline";
          }

          close (NEWFILE) || die;
          
          SecureUtil::CP ("$file", "$file.bak.$$");
          SecureUtil::CP ("$file.$$", $file);
          SecureUtil::RM ("$file.$$");

          #restore permissions on emd.properties
          restoreFilePermissions($propfilePerm, "$file");

          SecureUtil::USERINFO ( "Agent is now unsecured...   Done.\n");
          SecureUtil::USERINFO ( "Unsecuring agent...   Ended.\n");
          $rc = 0;
      }
      else
      {
          SecureUtil::USERINFO ("OMS Upload URL - $verify_em_upload_http_url is locked or unavailable.\n");
          SecureUtil::RM ("$file.$$");
          SecureUtil::USERINFO ("Unsecuring Agent...  Failed.\n");
          $rc = 1;
      }
   }

   if ($stopStatus eq 0)
   {
     #SecureUtil::USERINFO ( "Restarting agent...\n");
     restartAgent($securelog);
   }
   return $rc;
}


sub stopAgent
{
  my $rc;
  my $securelog       = $_[0];
  my $agentStatusStr  = "$EMDROOT/bin/emdctl status agent 1>> $securelog 2>> $devNull";
  my $agentStopStr    = "$ORACLE_HOME/bin/emctl stop agent 1>> $securelog 2>> $devNull";
  my $agentStartStr   = "$ORACLE_HOME/bin/emctl start agent 1>> $securelog 2>> $devNull";

  $rc = 0xffff & system($agentStatusStr);
  $rc >>= 8;
  if ($rc eq 3 or $rc eq 4)
  {
    system($agentStopStr);
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($agentStatusStr);
      $rc >>= 8;
      if ($rc lt 2)
      {
         last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($agentStatusStr);
    $rc >>= 8;
    if ($rc eq 3 or $rc eq 4)
    {
      SecureUtil::USERINFO ("Failed to stop agent...\n");
      exit 2;
    }
    elsif ($rc eq 1)
    {
      SecureUtil::USERINFO ("Agent successfully stopped...   Done.\n");
      return 0;
    }
    else
    {
      SecureUtil::USERINFO ("Failed to stop agent...\n");
      SecureUtil::DEBUG ("Error: $rc...\n");
      exit 2;
    }
  }
  elsif ($rc eq 1)
  {
    SecureUtil::USERINFO ("Agent is already stopped...   Done.\n");
    return 1;
  }
  else
  {
    SecureUtil::USERINFO ("Failed to stop agent...\n");
    SecureUtil::DEBUG ("Error: $rc...\n");
    exit 2;
  }
}


sub restartAgent
{
  my $rc;
  my $securelog       = $_[0];
  my $agentStatusStr  = "$EMDROOT/bin/emdctl status agent 1>> $securelog 2>> $devNull";
  my $agentStopStr    = "$ORACLE_HOME/bin/emctl stop agent 1>> $securelog 2>> $devNull";
  my $agentStartStr   = "$ORACLE_HOME/bin/emctl start agent 1>> $securelog 2>> $devNull";

  system($agentStartStr);
  $rc = 0xffff & system($agentStatusStr);
  $rc >>= 8;
  if ($rc eq 3)
  {
    SecureUtil::USERINFO ("Agent successfully restarted...   Done.\n");
    return 0;
  }
  elsif ($rc eq 1)
  {
    SecureUtil::USERINFO ("Failed to restart agent...\n");
    exit 2;
  }
  elsif ($rc eq 4)
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($agentStatusStr);
      $rc >>= 8;
      if ($rc ne 3)
      {
         last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($agentStatusStr);
    $rc >>= 8;
    if ($rc eq 3)
    {
      SecureUtil::USERINFO ("Agent successfully restarted...   Done.\n");
      return 0;
    }
    else
    {
      SecureUtil::USERINFO ("Failed to restart agent...\n");
      SecureUtil::DEBUG ("Error: $rc...\n");
      exit 2;
    }
  }
  else
  {
    SecureUtil::USERINFO ("Failed to restart agent...\n");
    SecureUtil::DEBUG ("Error: $rc...\n");
    exit 2;
  }
}

sub getRepUrl
{
  my $args        = $_[0];
  my $sec_rep_url = $_[1];
  chomp($sec_rep_url);
  my $retUrl = "$sec_rep_url\n";

  my ($protocol,$machine,$port,$ssl) = &SecureUtil::parseURL($sec_rep_url);

  if ($args ne "")
  {
    my @omsHostDn = split (/=/, $args);
    chomp( @omsHostDn[1]); 
    if ($machine ne @omsHostDn[1])
    {
      my @upload_url = split(/:/,$sec_rep_url);
      if ($ssl eq "Y")
      {
        $retUrl = "https://@omsHostDn[1]:@upload_url[2]\n";
      } 
    }
  }
  return $retUrl;
}


sub displaySecureAgentHelp
{
  print "Help!\n";
}

1;

