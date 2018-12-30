#
#  $Header: Secure.pm 20-feb-2006.03:39:20 smodh Exp $
#
#
# Copyright (c) 2003, 2006, Oracle. All rights reserved.  
#
#    NAME
#      Secure.pm - Secure Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    smodh       02/20/06 - XbranchMerge smodh_jdbc_emagent from main 
#    smodh       01/25/06 - Use ojdbc14.jar 
#    shianand    07/26/05 - fix bug 4149565 
#    shianand    05/12/05 - fix bug 4360771
#    shianand    05/09/05 - fix bug 4356156 
#    shianand    05/05/05 - fix bug 4294700 
#    shianand    03/14/05 - fix bug 4199037 
#    shianand    03/13/05 - fix bug 4171514 
#    rzazueta    03/07/05 - Fix getEMHome for state agents 
#    shianand    12/31/04 - Unsecure DBConsole fix bug-3771842 
#    shianand    12/06/04 - Unsecure iasconsole bug fix 3134623 
#    rpinnama    12/07/04 - Fix 3704363
#    shianand    12/01/04 - Bug fix 3440956 
#    shianand    10/18/04 - Unsecure agent fix_3107941 
#    asawant     08/25/04 - Cuting over all password reads to use generic read 
#                           functionality. 
#    rpinnama    08/20/04 - Use emagentSDK.jar 
#    rpinnama    08/20/04 - Replace EMD ROOT with $ORACLE_HOME 
#    rpinnama    08/20/04 - Use httpd_em.conf from $ORACLE_HOME/sysman/config 
#    gan         08/16/04 - allow set https port 
#    rzkrishn    07/13/04 - using local var 
#    djoly       05/14/04 - Update core reference 
#    rpinnama    04/30/04 - Use a different secure log while calling out from 
#                           OMS 
#    rpinnama    04/01/04 - Fix getEMHome for iasconsole
#    rpinnama    02/13/04 - 
#    rpinnama    02/13/04 - Fix bug 3402177: For DBConsole use hostname 
#                           parameter if passed 
#    rzazueta    12/03/03 - Fix 3290080 
#    rzazueta    12/02/03 - use classes12.jar instead of classes12.zip 
#    rzazueta    11/14/03 - Add share.jar to the path 
#    rpinnama    10/23/03 - Down the ewallet.p12 from correct location 
#    lgloyd      10/16/03 - make w32 friendly 
#    rpinnama    10/06/03 - Use proper EM Home foe DBConsole 
#    rpinnama    09/29/03 - Add getKeyStoreDir 
#    rpinnama    09/22/03 - Fix dbconsole classpath 
#    rpinnama    08/27/03 - Get the classpath for dbconsole 
#    rpinnama    08/26/03 - Centralize the classpath 
#    caroy       08/18/03 - change from phaos.jar to ojpse_2_1_5.jar 
#    rpinnama    08/13/03 - Add REPLACE routine 
#    dsahrawa    08/04/03 - fix typo 
#    dsahrawa    07/31/03 - make secure lock/unlock work in perl
#    rpinnama    07/24/03 - grabtrans 'rpinnama_fix_2996670'
#    ggilchri    06/05/03 - enforce sysman password
#    aaitghez    03/13/03 - aaitghez_fix_stage_030306
#    ggilchri    03/03/03 - ggilchri_perl_sslsetup
#    ggilchri    02/17/03 - call sub modules for each op
#    dmshah      02/06/03 - Created
#

use English;
use strict;

use File::Copy;
use File::Path;

use SecureAgent;
use SecureOMS;
use SecureStandaloneConsole;
use SecureSetPwd;
use SecureStatus;
use SecureSync;
use SecureLock;
use SecureGenKeystore;

package Secure;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $EMDROOT           = $ENV{EMDROOT};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $JRE_HOME          = $ENV{JRE_HOME};
my $DEFAULT_CLASSPATH = $ENV{DEFAULT_CLASSPATH};
my $emUploadHTTPPort  = $ENV{EM_UPLOAD_PORT};
my $emUploadHTTPSPort = $ENV{EM_UPLOAD_HTTPS_PORT};
my $IS_WINDOWS        = "";
my $cpSep             = ":";

my $securelog         = "$ORACLE_HOME/sysman/log/secure.log";

my $OSNAME            = $^O;


if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $cpSep = ";";
}
else
{
 $IS_WINDOWS="FALSE";
}

sub secure
{
  my (@args) = @_;
  my $argCount   = scalar(@args);
  my $component  = $_[0];
  my $regPassword  = "";  # agent reg password
  my $rootPassword = "";  # SYSMAN password
  my $omsSLBHost   = "";  # OMS Host or SLB host in SLB env
  my $omsReset     = "";   # Whether to reset root password
  my $emConsoleMode = "CENTRAL"; # default to central

  my $authPassword = "";
  my $newPassword  = "";
  my $omsUrl       = "";
  my $thisDNSHost  = "";
  my $agentCertName = "";

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";

  if ($component eq "agent")
  {
    # get password(*) either from the args or interactive
    if ($argCount eq 1)
    {
      $regPassword = 
        &EmctlCommon::promptUserPasswd("Enter Agent Registration password : ");
    } 
    elsif ($argCount eq 2)
    {
      $regPassword=$_[1];
    }
    else
    {
      &USAGE;
      exit 1;
    }
    secureAgent($regPassword);
  }
  elsif ($component eq "oms")
  {
    # get em root password, registration password(*), [host] and [reset] either 
    # from the args or interactive 
    if ($argCount eq 1)
    {
      $rootPassword=&EmctlCommon::promptUserPasswd(
                                 "Enter Enterprise Manager Root Password : ");
      $regPassword=&EmctlCommon::promptUserPasswd(
                                 "Enter Agent Registration password : ");
    }
    else
    {
      shift (@args);
      $rootPassword  = "";
      $regPassword   = "";
      $omsSLBHost    = "";
      $omsReset      = "";
      
         
     #now process  parameters -sysman_pwd -reg_pwd -host, -reset and -secure_port
     #if -sysman_pwd or -reg_pwd missing, prompt user
     while (scalar(@args) gt 0)
     {
       if ($args[0] eq "-sysman_pwd")
       {
          shift(@args);
          $rootPassword       = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-reg_pwd")
       {
          shift(@args);
          $regPassword       = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-host")
       {
          shift(@args);
          $omsSLBHost       = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-reset")
       {
          $omsReset      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-secure_port")
       {
          shift(@args);
          $emUploadHTTPSPort      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_dc")
       {
          shift(@args);
          $root_dc      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_country")
       {
          shift(@args);
          $root_country      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_state")
       {
          shift(@args);
          $root_state      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_loc")
       {
          shift(@args);
          $root_loc      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_org")
       {
          shift(@args);
          $root_org      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_unit")
       {
          shift(@args);
          $root_unit      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_email")
       {
          shift(@args);
          $root_email      = $args[0];
          shift(@args);
       }
       else
       {
          &USAGE;
          exit 1;
       }
     }
     if ($rootPassword eq "")
     {
       $rootPassword=&EmctlCommon::promptUserPasswd(
                                  "Enter Enterprise Manager Root Password : ");
     }
     if ($regPassword eq "")
     {
       $regPassword=&EmctlCommon::promptUserPasswd(
                                  "Enter Agent Registration password : ");
     }
    }
    $emConsoleMode = &getConsoleMode;
    my $portsRef = &getOMSPorts;
    my @tempPorts = @$portsRef;
    $emUploadHTTPPort = $tempPorts[0];
      
    if ($emConsoleMode eq "")
    {
      print "Cannot determine Console type from oms.properties\n";
    }
    elsif ($emUploadHTTPPort eq "")
    {
      print "Cannot determine console http port from httpd_em.conf\n";
    }
    else
    {
      if ($emConsoleMode eq "STANDALONE")
      {
        print ("You must use emctl secure em to secure an iAS or ");
        print ("a DBA Studio\n");
        print ("Standalone Console.\n");
      }
      else
      { 
        if ($emUploadHTTPSPort eq "")
        {
          $emUploadHTTPSPort = "4888";
        }
        secureOMS($emConsoleMode, $emUploadHTTPPort, $emUploadHTTPSPort, 
                  $rootPassword, $regPassword, $omsSLBHost, $omsReset,
                  $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
      }
    }
  }
  elsif ($component eq "setpwd")
  {
    # get auth password(*) and new password(*) from the args
    shift (@args);
    $authPassword = $args[0];
    $newPassword  = $args[1];

    secureSetPwd ($authPassword, $newPassword);
  }
  elsif ($component eq "status")
  {
    if ($args[1] eq "oms" or $args[1] eq "agent")
    {
      # get [oms url] from the args
      shift (@args);
      $omsUrl = $args[1];
      secureStatus($args[0], $omsUrl);
    }
    else
    {
      &USAGE;
      exit 1;
    }
  }
  elsif ($component eq "sync")
  {
    # no args
    &secureSync;
  }
  elsif ($component eq "lock" || $component eq "unlock")
  {
    my $portsRef = &getOMSPorts;
    ($emUploadHTTPPort, $emUploadHTTPSPort) = @$portsRef;
        
    secureLock($component, $emUploadHTTPPort, $emUploadHTTPSPort);
  }
  elsif ($component eq "genkeystore")
  {
    # get [dns host] from the args
    shift (@args);
    $thisDNSHost = $args[0];

    secureGenKeystore ($thisDNSHost);
  }
  elsif ($component eq "genwallet")
  {
    shift(@args);
    my $agentHostName     = $args[0];
    my $obfWalletPassword = $args[1];
     
    my $retVal;

    # NOTE : Use a different secure log. Otherwise, the emctl secure genwallet callout
    #        from OMS will fail with "The file is being accesses by another process" 
    #        If this is not done, both agent secure process and OMS
    #        try to redirect their output to the same log file
    #        Also, two agent trying to secure at the same time (multiple secure genwallet callouts)
    #        also will have problem if the same securelog file is used.
    $securelog = "$ORACLE_HOME/sysman/wallets/agent.$agentHostName/secure.log";

    $retVal = SecureGenWallet::secureGenWallet ($securelog, "CENTRAL", "agent",
                                                $agentHostName, $obfWalletPassword, 
						"rep", $agentHostName);
    exit $retVal;
  }
  elsif ($component eq "em")
  {
    # get [dns host] from the args
    shift (@args);
    #$agentCertName = $args[0];

    while (scalar(@args) gt 0)
     {
       if ($args[0] eq "-host")
       {
          shift(@args);
          $agentCertName = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_dc")
       {
          shift(@args);
          $root_dc      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_country")
       {
          shift(@args);
          $root_country      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_state")
       {
          shift(@args);
          $root_state      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_loc")
       {
          shift(@args);
          $root_loc      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_org")
       {
          shift(@args);
          $root_org      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_unit")
       {
          shift(@args);
          $root_unit      = $args[0];
          shift(@args);
       }
       elsif ($args[0] eq "-root_email")
       {
          shift(@args);
          $root_email      = $args[0];
          shift(@args);
       }
       else
       {
          &USAGE;
          exit 1;
       }
     }

    if ($emUploadHTTPSPort eq "")
    {
        $emUploadHTTPSPort = "1810";
    }
    # $emUploadHTTPSPort is not used
    secureStandaloneConsole ($agentCertName, $emUploadHTTPSPort,
                             $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
  }
  elsif ($component eq "dbconsole")
  {
    # get [dns host] from the args

    # get em root password, registration password(*), [host] and [reset] either 
    # from the args or interactive 
    if ($argCount eq 1)
    {
      $rootPassword = 
        &EmctlCommon::promptUserPasswd(
                                  "Enter Enterprise Manager Root password : ");

      $regPassword = 
        &EmctlCommon::promptUserPasswd(
                                   "Enter Agent Registration password : ");

      print "Enter a Hostname for this OMS : ";
      $omsSLBHost=<STDIN>;
      chomp ($omsSLBHost);
      print "\n";
    }
    else
    {
      shift(@args);

      #if (defined($args[0])) {
      # $rootPassword  = $args[0];
      #}
      #if (defined($args[1])) {
      # $regPassword   = $args[1];
      #}
      #if (defined($args[2])) {
      # $omsSLBHost       = $args[2];
      #}
      #if (defined($args[3])) {
      # $omsReset      = $args[3];
      #}

       while (scalar(@args) gt 0)
       {
         if ($args[0] eq "-sysman_pwd")
         {
            shift(@args);
            $rootPassword       = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-reg_pwd")
         {
            shift(@args);
            $regPassword       = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-host")
         {
            shift(@args);
            $omsSLBHost       = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-reset")
         {
            $omsReset      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_dc")
         {
            shift(@args);
            $root_dc      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_country")
         {
            shift(@args);
            $root_country      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_state")
         {
            shift(@args);
            $root_state      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_loc")
         {
            shift(@args);
            $root_loc      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_org")
         {
            shift(@args);
            $root_org      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_unit")
         {
            shift(@args);
            $root_unit      = $args[0];
            shift(@args);
         }
         elsif ($args[0] eq "-root_email")
         {
            shift(@args);
            $root_email      = $args[0];
            shift(@args);
         }
         else
         {
            &USAGE;
            exit 1;
         }
       }
       if ($rootPassword eq "")
       {
         $rootPassword=&EmctlCommon::promptUserPasswd(
                       "Enter Enterprise Manager Root Password : ");
       }
       if ($regPassword eq "")
       {
         $regPassword=&EmctlCommon::promptUserPasswd(
                      "Enter Agent Registration password : ");
       }
       if ($omsSLBHost eq "")
       {
         print "Enter a Hostname for this OMS : ";
         $omsSLBHost=<STDIN>;
         chomp ($omsSLBHost);
         print "\n";
       }
    }
    $emConsoleMode = "DBCONSOLE";

    if ($emUploadHTTPPort eq "")
    {
      $emUploadHTTPPort = "1820";
    }
    if ($emUploadHTTPSPort eq "")
    {
      $emUploadHTTPSPort = "1820";
    }
   # $emUploadHTTPPort and $emUploadHTTPSPort are not used.
    secureDBConsole($emConsoleMode, $emUploadHTTPPort, $emUploadHTTPSPort, 
                    $rootPassword, $regPassword, $omsSLBHost, $omsReset,
                    $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);

  }
  else
  {
    &USAGE;
    exit 1;
  }
}

#
#unsecure takes argument  (agent, iasconsole/em, dbconsole)
#
sub unsecure
{
   my (@args) = @_;
   my $argCount   = scalar(@args);
   my $component  = $_[0];
   my $emConsoleMode = &getConsoleMode; 
   my $emAgentMode = &getAgentMode; 

   if ($component eq "agent")
   {
      if ($emAgentMode eq "")
      {
          Secure::DEBUG (0, $securelog,"Cannot determine Agent type from emd.properties\n");
          Secure::DEBUG (2, $securelog,"Cannot determine Agent type from emd.properties\n");
      }
      else
      {
         if ($emAgentMode eq "STANDALONE")
         {
            Secure::DEBUG (0, $securelog,"You must use emctl unsecure em/iasconsole\n");
            Secure::DEBUG (2, $securelog,"$emAgentMode Console.\n");
         }
         else
         {
            Secure::DEBUG (2, $securelog,"unsecure $component\n");
            SecureAgent::unsecureAgent($emAgentMode, $securelog);
         }
      }
   }
   elsif ($component eq "em" or $component eq "iasconsole")
   {
      if ($emAgentMode eq "")
      {
         Secure::DEBUG (0, $securelog,"Cannot determine Agent type from emd.properties\n");
      }
      else
      {
         if ($emAgentMode eq "STANDALONE")
         {
            Secure::DEBUG (2, $securelog,"unsecure $component\n");
            SecureStandaloneConsole::unsecureStandaloneConsole($securelog);
         }
         else
         {
            Secure::DEBUG (0, $securelog,"You must use emctl unsecure agent\n");
         }
      }
   }
   elsif ($component eq "dbconsole")
   {
      if ($emConsoleMode eq "")
      {
         Secure::DEBUG (0, $securelog,"Cannot determine Agent type from emd.properties\n");
      }
      else
      {
         if ($emConsoleMode eq "STANDALONE")
         {
            Secure::DEBUG (2, $securelog,"unsecure $component\n");
            unsecureDBConsole($emConsoleMode);
         }
         else
         {
            Secure::DEBUG (0, $securelog,"You must use emctl unsecure em/iasconsole or agent\n");
            Secure::DEBUG (2, $securelog,"$emAgentMode Console\n");
         }
      }
   }
   else
   {
      &USAGE;
      exit 1;
   }
}


#
# secureAgent takes
# 1) Array of arguments
#
sub secureAgent
{
  my (@args)     = @_;
  my $password      = $args[0];

  my($emAgentMode) = &getAgentMode;

  if ($emAgentMode eq "")
  {
    print "Cannot determine Agent type from emd.properties\n";
  }
  else
  {
    if ($emAgentMode eq "STANDALONE")
    {
      print ("You must use emctl secure em to secure an iAS or ");
      print ("a DBA Studio\n");
      print ("Standalone Console.\n");
    }
    else
    {
      # perform secure agent setup using password
      SecureAgent::secureAgent($securelog, $emAgentMode, $password);
    }
  }
}

#
# secureOMS takes
# 1) Array of arguments
#
sub secureOMS
{
  my (@args)         = @_;

  my $emConsoleMode      = "";
  my $emUploadHTTPPort   = "";
  my $emUploadHTTPSPort  = "";
  my $rootPassword       = "";
  my $regPassword        = "";
  my $slbHost            = "";
  my $omsReset           = "";

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";

  my $rc;
 
  if (defined($args[0])) {
    $emConsoleMode     = $args[0];
  }
  if (defined($args[1])) {
    $emUploadHTTPPort  = $args[1];
  }
  if (defined($args[2])) {
    $emUploadHTTPSPort = $args[2];
  }
  if (defined($args[3])) {
    $rootPassword      = $args[3];
  }
  if (defined($args[4])) {
    $regPassword       = $args[4];
  }
  if (defined($args[5])) {
    $slbHost           = $args[5];
  }
  if (defined($args[6])) {
    $omsReset         = $args[6];
  }
  if (defined($args[7])) {
    $root_dc          = $args[7];
  }
  if (defined($args[8])) {
    $root_country     = $args[8];
  }
  if (defined($args[9])) {
    $root_state       = $args[9];
  }
  if (defined($args[10])) {
    $root_loc         = $args[10];
  }
  if (defined($args[11])) {
    $root_org         = $args[11];
  }
  if (defined($args[12])) {
    $root_unit        = $args[12];
  }
  if (defined($args[13])) {
    $root_email       = $args[13];
  }


  # perform secure oms setup using password
  if ($emConsoleMode eq "CENTRAL")
  {
    $rc = SecureOMS::secureCentralOMS($securelog, $emConsoleMode, $emUploadHTTPPort, 
                                      $emUploadHTTPSPort, $rootPassword, $regPassword, 
                                      $slbHost, $omsReset,
                                      $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
  }
  else
  {
    $rc = SecureOMS::secureOMS($securelog, $emConsoleMode, $emUploadHTTPPort, 
                               $emUploadHTTPSPort, $rootPassword, $regPassword, 
                               $slbHost, $omsReset,
                               $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
  }
  return $rc;
}

#
# secureSetPwd takes
# 1) Array of arguments
#
sub secureSetPwd
{
  my (@args)    = @_;
  my $authPassword = $args[0];
  my $newPassword  = $args[1];

  SecureSetPwd::secureSetPwd ($securelog, $authPassword, $newPassword);
}

#
# secureStatus takes
# 1) Array of arguments
#
sub secureStatus
{
  my (@args) = @_;
  my $component = $args[0];
  my $omsUrl    = $args[1];

  SecureStatus::secureStatus ($securelog, $component, $omsUrl);
}

#
# secureSync takes
# 1) Array of arguments
#
sub secureSync {
  SecureSync::secureSync ($securelog);
}

#
# secureLock takes
# 1) Array of arguments
#
sub secureLock {
  my(@args) = @_;
  my $lockStatus = $args[0];
  my $emUploadHTTPPort = $args[1];
  my $emUploadHTTPSPort = $args[2];
  
  SecureLock::secureLock ($securelog, $lockStatus, $emUploadHTTPPort, $emUploadHTTPSPort);
}

#
# secureGenKeystore takes
# 1) Array of arguments
#
sub secureGenKeystore {
  my (@args)   = @_;
  my $thisDNSHost = $args[0];

  SecureGenKeystore::secureGenKeystore ($securelog, "STANDALONE", 
                                        $thisDNSHost, "root");
}

#
# secureStandaloneConsole takes
# 1) Array of arguments
#
sub secureStandaloneConsole {
  my (@args)     = @_;
  my $agentCertName      = $args[0];
  my $emUploadHTTPSPort  = $args[1];

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";


  if (defined($args[2])) {
    $root_dc          = $args[2];
  }
  if (defined($args[3])) {
    $root_country     = $args[3];
  }
  if (defined($args[4])) {
    $root_state       = $args[4];
  }
  if (defined($args[5])) {
    $root_loc         = $args[5];
  }
  if (defined($args[6])) {
    $root_org         = $args[6];
  }
  if (defined($args[7])) {
    $root_unit        = $args[7];
  }
  if (defined($args[8])) {
    $root_email       = $args[8];
  }

  SecureStandaloneConsole::secureStandaloneConsole ($securelog,
                                                    $agentCertName,
                                                    $emUploadHTTPSPort,
                                                    $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
}

sub secureDBConsole
{
  my (@args)     = @_;

  my $emConsoleMode     = $args[0];
  my $emUploadHTTPPort  = $args[1];
  my $emUploadHTTPSPort = $args[2];
  my $rootPassword      = $args[3];
  my $regPassword       = $args[4];
  my $omsSLBHost        = $args[5];
  my $omsReset          = $args[6];

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";

  if (defined($args[7])) {
    $root_dc          = $args[7];
  }
  if (defined($args[8])) {
    $root_country     = $args[8];
  }
  if (defined($args[9])) {
    $root_state       = $args[9];
  }
  if (defined($args[10])) {
    $root_loc         = $args[10];
  }
  if (defined($args[11])) {
    $root_org         = $args[11];
  }
  if (defined($args[12])) {
    $root_unit        = $args[12];
  }
  if (defined($args[13])) {
    $root_email       = $args[13];
  }

  my $obfRootPassword;
  my $agentWalletPwdCmd = "";
  my $agentWalletPassword = "";
  my $obfAgentWalletPwdCmd = "";
  my $obfAgentWalletPassword = "";
  my $agentDownloadDir = "";
  my $agentWalletFile = "";
  my $b64InternetCertFile = "";

  my $emHome        = &getEMHome($emConsoleMode);

  my $emConfigDir   = "$emHome/sysman/config";
  my $emWalletsDir  = "$emHome/sysman/wallets";


  my $javaStr;
  my $classPath;
  my $rc;


  Secure::DEBUG (0, $securelog, "Stopping dbconsole...\n");
  my $stopStatus = stopDBConsole();
  if ($stopStatus eq 0 or $stopStatus eq 1)
  {
    Secure::DEBUG (0, $securelog, "Securing dbconsole...\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Aborting secure dbconsole...\n");
    exit 2;
  }

  DEBUG (1, $securelog, "Securing DB Console");
  DEBUG (1, $securelog, "HTTP Port = $emUploadHTTPPort");
  DEBUG (1, $securelog, "HTTPS Port = $emUploadHTTPSPort");
  DEBUG (1, $securelog, "DNS Host = $omsSLBHost");

  my ($agentHost, $agentPort) = &getAgentHostname($emHome);
  Secure::DEBUG (2, $securelog, "agentHost = $agentHost ");
  Secure::DEBUG (2, $securelog, "agentPort = $agentPort ");

  $classPath = &getConsoleClassPath($emConsoleMode);

  # If no hostname is explicitly passed in, use the agent host 
  # to generate key store.
  if ($omsSLBHost eq "")
  {
    $omsSLBHost=$agentHost;
  }

  $rc = secureOMS($emConsoleMode, $emUploadHTTPPort, $emUploadHTTPSPort, 
                  $rootPassword, $regPassword, $omsSLBHost, $omsReset,
                  $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "Securing OMS ...   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Securing OMS ...   Failed.\n");
    exit $rc;
  }

  my $obfRootPwdCmd = "$JAVA_HOME/bin/java ".
                      "-cp $classPath ".
		      "-DORACLE_HOME=$ORACLE_HOME ".
		      "oracle.sysman.eml.sec.Obfuscate -cypher $rootPassword";

  Secure::DEBUG (2, $securelog, "Executing cmd .. $obfRootPwdCmd ");
  $obfRootPassword = `$obfRootPwdCmd`;
  $obfRootPassword=~ s/^\s+|\s+$//;


  # Store it in repository and agent

  DEBUG (0, $securelog, "Generating Oracle Wallet Password for Agent....");
  $agentWalletPwdCmd = "$JAVA_HOME/bin/java ".
                       "-cp $classPath ".
		       "oracle.sysman.util.crypt.Verifier -genPassword";
  DEBUG (2, $securelog, "Executing cmd .. $agentWalletPwdCmd");
  $agentWalletPassword = `$agentWalletPwdCmd`;
  $agentWalletPassword=~ s/^\s+|\s+$//;
  Secure::DEBUG (2, $securelog, "agentWalletPwd = $agentWalletPassword");

  DEBUG (1, $securelog, "Obfuscating OMS wallet password...");
  $obfAgentWalletPwdCmd = "$JAVA_HOME/bin/java ".
                          "-cp $classPath ".
			  "-DORACLE_HOME=$ORACLE_HOME ".
			  "oracle.sysman.eml.sec.Obfuscate -cypher $agentWalletPassword";

  DEBUG (2, $securelog, "Executing cmd .. $obfAgentWalletPwdCmd");
  $obfAgentWalletPassword = `$obfAgentWalletPwdCmd`;
  $obfAgentWalletPassword=~ s/^\s+|\s+$//;
  DEBUG (2, $securelog, "Obfuscated AgentWalletPwd = $obfAgentWalletPassword ");
  DEBUG (0, $securelog, "   Done.\n");

  # Generate wallet for agent..
  DEBUG (0, $securelog, "Generating wallet for Agent ... ");
  SecureGenWallet::secureGenWallet($securelog, "DBCONSOLE", "agent", 
                                   $agentHost, $obfAgentWalletPassword, "rep", $agentHost);
  DEBUG (0, $securelog, "   Done.\n");

  # Copy the wallet to config/server directory for agent use.
  DEBUG (0, $securelog, "Copying the wallet for agent use... ");
  if (not (-e "$emConfigDir/server"))
  {
    mkdir ("$emConfigDir/server", 0755)
  }

  # Copy wallet and b64 files from download directory..
  $agentDownloadDir = "$ORACLE_HOME/oc4j/j2ee/oc4j_applications/applications/em/em/wallets/agent.$agentHost";
  $agentWalletFile = "$agentDownloadDir/ewallet.p12";
  if (-e "$agentWalletFile")
  {
    Secure::CP ($agentWalletFile, "$emHome/sysman/config/server");
  }

  # We need to copy the b64InternetCertificate.txt from agentDownloadDir
  # which contains both local cert as well as internet certificate list
  $b64InternetCertFile = "$agentDownloadDir/b64InternetCertificate.txt";
  if (-e "$b64InternetCertFile")
  {
    Secure::CP ($b64InternetCertFile, "$emHome/sysman/config");
  }

  # No need to copy the Local certificate.
  # as a copy already exists in the sysman/config directory


  DEBUG (0, $securelog, "   Done.\n");


  # Store the agent key in repository
  DEBUG (0, $securelog, "Storing agent key in repository...");
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrootPassword=$obfRootPassword ".
             "-DORACLE_HOME=$ORACLE_HOME ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.AgentKeyUtil -storeinrep ".
             " $agentHost $agentPort $obfAgentWalletPassword >> $securelog";
  Secure::DEBUG (2, $securelog, "Executing... $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Failed.\n");
    exit $rc;
  }


  # Store the agent key on agent
  DEBUG (0, $securelog, "Storing agent key for agent ...");
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DORACLE_HOME=$ORACLE_HOME ".
             "-DpropertiesFile=$emHome/sysman/config/emd.properties ".
             "oracle.sysman.eml.sec.AgentKeyUtil -storetoagent ".
             " $obfAgentWalletPassword >> $securelog";
  Secure::DEBUG (2, $securelog, "Executing... $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Failed.\n");
    exit $rc;
  }


  DEBUG (0, $securelog, "Configuring Agent... \n");
  $rc = SecureAgent::configureAgent($securelog, "DBCONSOLE", "");
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "Configuring Agent ...   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Configuring Agent ...   Failed.\n");
    exit $rc;
  }

  DEBUG (0, $securelog, "Configuring Key store..");
  $rc = SecureGenKeystore::configureEMKeyStore($securelog, $emConsoleMode);
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Failed.\n");
    exit $rc;
  }

  if ($stopStatus eq 0)
  {
    Secure::DEBUG (0, $securelog, "Restarting dbconsole...\n");
    restartDBConsole();
  }

  return 0;
}


#
#unsecureDBConsole
#
sub unsecureDBConsole
{
   my $rc;
   my (@args)        = @_;
   my $emConsoleMode = "DBCONSOLE";
   my $debug         = $ENV{EM_SECURE_VERBOSE};
   my $classPath     = &Secure::getAgentClassPath;
   my $emHome        = &Secure::getEMHome($emConsoleMode);
   my $oc4jHome      = &Secure::getOC4JHome($emConsoleMode);

   my $stopStatus;

   if($debug ne "")
   {
      $debug = "true";
   }
   else
   {
      $debug = "false";
   }

   Secure::DEBUG (0, $securelog,"Configuring DBConsole for HTTP...\n");
   
   my $file = "$emHome/sysman/config/emd.properties";
   my $propfile = "$emHome/sysman/config/emd.properties";
   my $emWebSiteFile = "$oc4jHome/config/http-web-site.xml";

   Secure::DEBUG (2, $securelog,"Locating emd.properties file = $file\n");
   Secure::DEBUG (2, $securelog,"Locating http-web-site.xml file = $emWebSiteFile\n");

   open(PROPFILE,$propfile) or die "Can not read EMD.PROPERTIES ($propfile)";
   my @emdURLlinesRead = grep /EMD_URL=https:/, <PROPFILE>;
   close(PROPFILE) or die "Can not close EMD.PROPERTIES ($propfile)";

   my $numLinesEMDURL = scalar @emdURLlinesRead;
   if($numLinesEMDURL <= 0)
   {
      Secure::DEBUG (0, $securelog,"DBConsole is already unsecured.\n");
   }
   else
   {
      Secure::DEBUG (0, $securelog, "Stopping dbconsole...\n");
      $stopStatus = stopDBConsole();
      if ($stopStatus eq 0 or $stopStatus eq 1)
      {
         Secure::DEBUG (0, $securelog, "Unsecuring dbconsole...\n");
      }
      else
      {
         Secure::DEBUG (0, $securelog, "Aborting unsecure dbconsole...\n");
         exit 2;
      }

      Secure::DEBUG (2, $securelog,"Changing secure url to unsecure url.\n");

      my $emd_check_url = 0;
      my $rep_check_url = 0;
      my $sec_check = 0;
      my $verify_em_upload_http_url = "";

      open(SECINFO, $emWebSiteFile) or die "Can not read $emWebSiteFile";
      my @seclines = <SECINFO>;
      close(SECINFO)|| die;
      # Walk the lines, and write to new file
      open (SECFILE, ">$emWebSiteFile.$$") || die "Cannot write to $file.$$\n";
      foreach my $seclineRead (@seclines)
      {
         if($seclineRead =~ /<web-site port/)
         {
            if($seclineRead =~ /secure="true"/i)
            {
               $seclineRead =~ s/(TRUE|true)/false/;
               $sec_check = 1;
               Secure::DEBUG (2, $securelog,"Configuring http-web-site.xml file.\n");
            }
            if($seclineRead =~ /secure="false"/i)
            {
               $sec_check = 1;
            }
         }
         print SECFILE "$seclineRead";
      }
      close(SECFILE)|| die;

      if ($sec_check == 1)
      {
         open(INFO, $file);
         my @emdlines = <INFO>;
         close(INFO) || die;
         open (EMDFILE, ">$file.$$") || die "Cannot write to $file.$$\n";
         # Walk the lines, and write to new file
         foreach my $emdlineRead (@emdlines)
         {
             if($emdlineRead =~ /REPOSITORY_URL=https:/)
             {
                $emdlineRead =~ s/https\:/http\:/;
                $verify_em_upload_http_url = $emdlineRead;
                chomp($verify_em_upload_http_url);
                $verify_em_upload_http_url =~ s/REPOSITORY_URL=http\:/http\:/;
                $rep_check_url = 1;
             }
             if($emdlineRead =~ /EMD_URL=https:/)
             {
                Secure::DEBUG (2, $securelog,"Check EMD_URL = $emdlineRead\n");
                $emdlineRead =~ s/https\:/http\:/;
                $emd_check_url = 1;
             }
             print EMDFILE "$emdlineRead";
         }
         close (EMDFILE) || die;

         if ($rep_check_url == 1 and $emd_check_url == 1) 
         {
             Secure::CP ("$file", "$file.bak.$$");
             Secure::CP ("$file.$$", $file);
             Secure::RM ("$file.$$");
             Secure::CP ("$emWebSiteFile", "$emWebSiteFile.bak.$$");
             Secure::CP ("$emWebSiteFile.$$", $emWebSiteFile);
             Secure::RM ("$emWebSiteFile.$$");
             Secure::DEBUG (0, $securelog,"DBCONSOLE is now unsecured...\n");
             $rc = 0;
         }
         else
         {
             Secure::RM ("$file.$$");
             Secure::RM ("$emWebSiteFile.$$");
             Secure::DEBUG (0, $securelog,"Configuration Failed...\n");
             $rc = 1;
         }
      }
   }

  if ($stopStatus eq 0)
  {
    Secure::DEBUG (0, $securelog, "Restarting dbconsole...\n");
    restartDBConsole();
  }

  return $rc;
}


sub stopDBConsole
{
  my $rc;
  my $redirectStderr    = "2>&1";

  my $dbStopStr    = "$ORACLE_HOME/bin/emctl stop dbconsole >> $securelog $redirectStderr";
  my $dbStartStr   = "$ORACLE_HOME/bin/emctl start dbconsole >> $securelog $redirectStderr";
  my $dbStatusStr  = "$ORACLE_HOME/bin/emctl status dbconsole >> $securelog $redirectStderr";

  $rc = 0xffff & system($dbStatusStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    system($dbStopStr);
    $rc = 0xffff & system($dbStatusStr);
    $rc >>= 8;
    if ($rc eq 0)
    {
      Secure::DEBUG (0, $securelog,"Failed to stop dbconsole...\n");
      exit 2;
    }
    elsif ($rc eq 2)
    {
      Secure::DEBUG (0, $securelog,"DBCONSOLE successfully stopped...\n");
      return 0;
    }
    else
    {
      my $tries=30;
      while( $tries gt 0 )
      {
        sleep 1;
        $rc = 0xffff & system($dbStatusStr);
        $rc >>= 8;
        if ($rc ne 2)
        {
          last;
        }
        $tries = $tries-1;
        print ".";
      }
      $rc = 0xffff & system($dbStatusStr);
      $rc >>= 8;
      if ($rc eq 2)
      { 
        Secure::DEBUG (0, $securelog,"DBCONSOLE successfully stopped...\n");      
        return 0;
      }
      else
      {
        Secure::DEBUG (0, $securelog,"Failed to stop dbconsole...\n");
        Secure::DEBUG (2, $securelog,"Error: $rc...\n");       
        exit 2;
      }
    }
  }
  elsif ($rc eq 2)
  {
    Secure::DEBUG (0, $securelog,"DBCONSOLE already stopped...\n");
    return 1;
  }
  else
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($dbStatusStr);
      $rc >>= 8;
      if ($rc ne 2)
      {
        last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($dbStatusStr);
    $rc >>= 8;
    if ($rc eq 2)
    { 
      Secure::DEBUG (0, $securelog,"DBCONSOLE successfully stopped...\n");      
      return 0;
    }
    else
    {
      Secure::DEBUG (0, $securelog,"Failed to stop dbconsole...\n");
      Secure::DEBUG (2, $securelog,"Error: $rc...\n");     
      exit 2;
    }
  }
}


sub restartDBConsole
{
  my $rc;
  my $redirectStderr    = "2>&1";

  my $dbStopStr    = "$ORACLE_HOME/bin/emctl stop dbconsole >> $securelog $redirectStderr";
  my $dbStartStr   = "$ORACLE_HOME/bin/emctl start dbconsole >> $securelog $redirectStderr";
  my $dbStatusStr  = "$ORACLE_HOME/bin/emctl status dbconsole >> $securelog $redirectStderr";

  system($dbStartStr);
  $rc = 0xffff & system($dbStatusStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    Secure::DEBUG (0, $securelog,"DBCONSOLE successfully restarted...\n");  
    return 0;
  }
  elsif ($rc eq 2)
  {
    Secure::DEBUG (0, $securelog,"Failed to restart dbconsole...\n");  
    exit 2;
  }
  else
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($dbStatusStr);
      $rc >>= 8;
      if ($rc ne 0)
      {
        last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($dbStatusStr);
    $rc >>= 8;
    if ($rc eq 0)
    { 
      Secure::DEBUG (0, $securelog,"DBCONSOLE successfully restarted...\n");      
      return 0;
    }
    else
    {
      Secure::DEBUG (0, $securelog,"Failed to restart dbconsole...\n");
      Secure::DEBUG (2, $securelog,"Error: $rc...\n");       
      exit 2;
    }
  }
}



#
# get http port for the console from httpd_em.conf file. We are looking for 
# the port for the  <VirtualHost *:port> which is not in <IfDefine SSL>
# </IfDefine> block. Also look for https port
#
sub getOMSPorts {
  my(@args) = @_;
  my $httpEmConfFile         = "$ORACLE_HOME/sysman/config/httpd_em.conf";
  my $sslStart               = "<IfDefine SSL>";
  my $sslStop                = "<\/IfDefine>";
  my $emConsoleHttpPort = "";
  my $emConsoleHttpsPort = "";
  my @returnArray = ();

  open(EMCONFH, $httpEmConfFile) || die "Could not open $httpEmConfFile\n";
  my $curLine;
  my $insideSSL = 0;
  while(defined($curLine = <EMCONFH>))
  {
    chop $curLine;
    if ($curLine =~ /^.*<VirtualHost\s+\*:(\d+)>/)
    {
       if ($insideSSL == 0)
       {
         $emConsoleHttpPort = $1;
       }
       else
       {
         $emConsoleHttpsPort = $1;
       }
    }
    if ($curLine =~ /^$sslStart/) 
    {
      $insideSSL = 1;
    }
    if ($curLine =~ /^$sslStop/)
    {
      $insideSSL = 0;
    }
  }
  close(EMCONFH);

  Secure::DEBUG (2, $securelog, 
              "Http upload port from httpd_em.conf is $emConsoleHttpPort\n");
  Secure::DEBUG (2, $securelog, 
              "Https upload port from httpd_em.conf is $emConsoleHttpsPort\n");

  (@returnArray) = ($emConsoleHttpPort, $emConsoleHttpsPort);
  return (\@returnArray);
  
}

#
# Get the type of OMS that is to be secured. It is one of the following:
#
#   "CENTRAL"    - a central OMS using a Repository.
#   "DBCONSOLE"  - a standalone oc4j usiing a repository
#   "STANDALONE" - a standalone oc4j without a repository.
#
sub getConsoleMode {
  my (@args) = @_;

  my $propertiesFile      = "$ORACLE_HOME/sysman/config/emoms.properties";
  my $consoleModeProperty = "oracle.sysman.emSDK.svlt.ConsoleMode";

  my %omsProps;
# 
# if there is no emoms.properties then this is an iAS Standalone Console
# using a Stand Alone OC4J
#  -> "STANDALONE"
#
# if there is an emoms.properties but no ConsoleMode then this is a 
# a Central OMS using an iAS Core
#  -> "CENTRAL"
#
# if there is an emoms.properties and it has a ConsoleMode set to
# dbStandalone then this is a DBA Studio Standalone Console
# using a Stand Alone OC4J
#  -> "STANDALONE"
#
# if there is an emoms.properties and it has a ConsoleMode set to
# standalone then this is a Database Standalone Console using a
# Stand Alone OC4J with a local Agent and Repository
#  -> "DBCONSOLE"
#
# if there is an emoms.properties and it has a ConsoleMode set to
# some other value then we don't know what this is..
#
  my $emConsoleMode = "";
  if (-e $propertiesFile)
  {
    %omsProps = &parseFile($propertiesFile);
    if (defined($omsProps{$consoleModeProperty}))
    {
      my $propValue = $omsProps{$consoleModeProperty};
      if ($propValue eq "dbStandalone")
      {
        $emConsoleMode = "STANDALONE";
      }
      if ($propValue eq "standalone")
      {
        $emConsoleMode = "DBCONSOLE";
      }
    }
    else
    {
      $emConsoleMode = "CENTRAL";
    }
  }
  else
  {
    $emConsoleMode = "STANDALONE";
  }
  return $emConsoleMode;
}

sub getConsoleClassPath
{
  my (@args) = @_;
  my $consoleMode = $args[0];
  my $emLibDir    = "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib";
  my $emJarFile   = "emCORE.jar";

  if ($consoleMode eq "")
  {
    # If not specified, calculate it.
    $consoleMode = &getConsoleMode;
  }

  Secure::DEBUG (2, $securelog, "consoleMode =  $consoleMode");
  Secure::DEBUG (2, $securelog, "emLibDir =  $emLibDir");

  if ($consoleMode eq "CENTRAL")
  {
    $emLibDir  = "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib";
    $emJarFile = "emCORE.jar"
  }
  elsif ($consoleMode eq "DBCONSOLE")
  {
    $emLibDir  = "$EMDROOT/sysman/jlib";
    $emJarFile = "emCORE.jar"
  }
  elsif ($consoleMode eq "STANDALONE")
  {
    $emLibDir  = "$EMDROOT/sysman/webapps/emd/WEB-INF/lib";
    $emJarFile = "emd.jar"
  }

  Secure::DEBUG (2, $securelog, "emLibDir =  $emLibDir");
  Secure::DEBUG (2, $securelog, "emdroot =  $EMDROOT");

  my $consoleClassPath = "$DEFAULT_CLASSPATH".
                   "$cpSep$ORACLE_HOME/jdbc/lib/ojdbc14.jar".
                   "$cpSep$ORACLE_HOME/jlib/uix2.jar".
                   "$cpSep$ORACLE_HOME/jlib/share.jar".
		   "$cpSep$ORACLE_HOME/jlib/ojmisc.jar".
                   "$cpSep$ORACLE_HOME/lib/xmlparserv2.jar".
                   "$cpSep$ORACLE_HOME/lib/emagentSDK.jar".
                   "$cpSep$ORACLE_HOME/encryption/jlib/ojpse_2_1_5.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/lib/http_client.jar".
                   "$cpSep$emLibDir/log4j-core.jar".
		   "$cpSep$EMDROOT/sysman/jlib/emagentSDK.jar".
                   "$cpSep$emLibDir/$emJarFile";

  return $consoleClassPath;
}

sub getOC4JHome
{
  my (@args) = @_;
  my $consoleMode = $args[0];

  my $oc4jHomeDir = "";

  if ($consoleMode eq "")
  {
    # If not specified, calculate it.
    $consoleMode = &getConsoleMode;
  }

  if ($consoleMode eq "CENTRAL")
  {
  }
  elsif ($consoleMode eq "DBCONSOLE")
  {
    $oc4jHomeDir = &EmctlCommon::getOC4JHome("dbconsole");
  }
  elsif ($consoleMode eq "STANDALONE")
  {
    $oc4jHomeDir = &EmctlCommon::getOC4JHome("iasconsole");
  }

  return $oc4jHomeDir;
}

sub getEMHome
{
  my (@args) = @_;
  my $consoleMode = $args[0];

  my $emHome = "";

  # For OMS and agent, use ORACLE_HOME
  # For DBConsole, use EmctlCommom.getHome as it gets the $OH/host_sid home
  # For IASConsole, use EmctlCommon.getHome.
  if (($consoleMode eq undef) || ($consoleMode eq "") )
  {
    $emHome = $ORACLE_HOME;
  }
  elsif ($consoleMode eq "DBCONSOLE")
  {
    $emHome = &EmctlCommon::getEMHome("dbconsole");
  }
  elsif ($consoleMode eq "STANDALONE")
  {
    $emHome = &EmctlCommon::getEMHome("iasconsole");
  }
  elsif ($consoleMode eq "CENTRAL_AGENT")
  {
    $emHome = &EmctlCommon::getEMHome("agent");
  }
  else
  {
    $emHome = $ORACLE_HOME;
  }

  return $emHome;
}


#
# Get the type of Agent that is to be secured. It is one of the following:
#
#   "CENTRAL_AGENT"    - an Agent uploading metrics to an OMS / Repository.
#   "STANDALONE" - a local Agent belonging to a Standalone Console.
#
sub getAgentMode 
{
  my (@args) = @_;

  my $propertiesFile      = "$EMDROOT/sysman/config/emd.properties";
  my $agentModeProperty   = "REPOSITORY_URL";
  my $emAgentMode         = "";
  my %agentProps;

  if (-e $propertiesFile)
  {
    %agentProps = &parseFile($propertiesFile);
    if (defined($agentProps{$agentModeProperty}))
    {
      my $propValue = $agentProps{$agentModeProperty};
      if (not $propValue eq "")
      {
        # a value for the REPOSITORY_URL means a Central Agent
        $emAgentMode = "CENTRAL_AGENT";
      }
      else
      {
        # no value for the REPOSITORY_URL means a Standalone Agent
        $emAgentMode = "STANDALONE";
      }
    }
    else
    {
      # no REPOSITORY_URL means a Standalone Agent
      $emAgentMode = "STANDALONE";
    }
  }
  return $emAgentMode;
}

sub getAgentHostname 
{
  my (@args)         = @_;
  my $emHome = $args[0];
  my $propertiesFile = "$emHome/sysman/config/emd.properties";
  my $emdUrlProperty = "EMD_URL";
  my $emdUrl         = "";
  my $agentHostname  = "";
  my $agentPort  = "";

  if (-e $propertiesFile)
  {
    my (%agentProps) = &parseFile($propertiesFile);
    if (defined($agentProps{$emdUrlProperty}))
    {
      $emdUrl = $agentProps{$emdUrlProperty};
      my ($protocol,$machine,$port,$ssl) = parseURL($emdUrl);
      $agentHostname = $machine;
      $agentPort = $port;
    }
  }
  return ($agentHostname, $agentPort);
}

sub getAgentClassPath 
{
  my (@args)         = @_;
  my $propertiesFile = "$EMDROOT/sysman/config/emd.properties";
  my $classPathProperty = "CLASSPATH";
  my $agentClassPath = "";

  if (-e $propertiesFile)
  {
    my (%agentProps) = &parseFile($propertiesFile);
    if (defined($agentProps{$classPathProperty}))
    {
      $agentClassPath = $agentProps{$classPathProperty};
    }
  }
  return $agentClassPath;
}

sub getServerName
{
  my $dnsHostName = "";

  my $httpEmConfFile = "$ORACLE_HOME/sysman/config/httpd_em.conf";
  open(INFO, $httpEmConfFile);
  my @lines = <INFO>;
  close(INFO) || die "Cannot open $httpEmConfFile.";

  foreach my $readline (@lines)
  {
    if(!($readline =~ /^\#/) and !($readline =~ /^\s+$/))
    {
      if($readline =~ /ServerName/)
      {
        my $pattern = '^\s+(\S+)\s+(\S+)';
        if ($readline =~ /$pattern/)
        {
          $dnsHostName = $2;
          chomp($dnsHostName);
          last;
        }
      }
    }
  }
  return $dnsHostName;
}



sub USAGE {
  print "Usage :\n";
  print "secure oms  -sysman_pwd <sysman password> -reg_pwd <registration password> [-host <hostname>] [-reset] [-secure_port <secure_port>]\n";
  print "\t[-root_dc <root_dc>] [-root_country <root_country>] [-root_state <root_state>]\n";
  print "\t[-root_loc <root_loc>] [-root_org <root_org>] [-root_unit <root_unit>] [-root_email <root_email>]\n";

  print "secure agent   <registration password>\n";
  
  print "secure em\n";
  print "\t[-host <host>] [-root_dc <root_dc>] [-root_country <root_country>]\n";
  print "\t[-root_state <root_state>] [-root_loc <root_loc>] [-root_org <root_org>]\n";
  print "\t[-root_unit <root_unit>] [-root_email <root_email>]\n";

  print "secure dbconsole  -sysman_pwd <sysman password> -reg_pwd <registration password> [-host <hostname>] [-reset]\n";
  print "\t[-root_dc <root_dc>] [-root_country <root_country>] [-root_state <root_state>] [-root_loc <root_loc>]\n";
  print "\t[-root_org <root_org>] [-root_unit <root_unit>] [-root_email <root_email>]\n";
  
  print "secure setpwd  <sysman  password> <registration password>\n";
  print "secure status oms/agent [oms http url]\n";
  print "secure lock | unlock\n";
  print "\n"
}

# Utilities
# [] ----------------------------------------------------------------- []

sub parseURL 
{
 ($_) = @_;
 
  my $ssl = " ";
  my ($protocol,$machine,$port) = /([^:]+):\/\/([^:]+):([0-9]+)\/.*/;
  if (! defined($protocol) ) {
     $protocol = "na";
     $machine  = "na";
     $port     = "na";
  } else {
    $protocol = lc $protocol;
    if (! defined($port) ) {
       $port = 80;
    }
    if ($protocol eq "https") {
       $ssl = "Y";
    }
  }
  return ($protocol,$machine,$port,$ssl);
}

# [] ----------------------------------------------------------------- []

sub parseFile 
{
  my($fname) = @_;
  my %lprop;

  if (! -T $fname ) {
     print "File $fname is not a text file\n";
     next;
  }
  open(FILE,$fname) or die "Can not read file: $fname\n$!\n";
  while (<FILE>) {
    ;# Remove leading and traling whitespaces
    s/^\s+|\s+$//;
    s/#.*$//g;

    ;# Validate each non-empty line
    if (! /^$/) {
       my($name,$value) = /([^=]+)\s*=\s*(.+)/;
       if (defined($name) && defined($value)) {
          $name  =~ s/^\s+|\s+$//g;
          $value =~ s/^\s+|\s+$//g;
          $lprop{$name} = $value;
       }
    }
  }
  close(FILE);

  ;# Return success
  return %lprop;
}

# [] ----------------------------------------------------------------- []

sub write_to_file 
{

  my($fname,$msg) = @_;

  chomp($msg);
  if ( open(OUTPUT_FILE,">>" . $fname) )  {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    if ($year<=1000) { $year += 1900;}
    $mon += 1;
    my $prefix = sprintf("%02d-%02d-%4d %02d:%02d:%02d",
                              $mday,$mon,$year,$hour,$min,$sec);
    
    printf(OUTPUT_FILE "[%s] %s\n",$prefix, $msg);
    close(OUTPUT_FILE);
  }
}

# [] ----------------------------------------------------------------- []

sub DEBUG 
{
  my($level,$fname,$msg) = @_;

  my $verbose_mode = $ENV{EM_SECURE_VERBOSE};

  # If level == 2 and EM_SECURE_VERBOSE="true" 
  # write to file..
  if ( ( ($level == 2) && ($verbose_mode ne "") ) ||
       ($level < 2) )
  {
      write_to_file($fname, $msg);
  }

  if ($level eq 0)
  {
    print "$msg";
  }
}

# [] ----------------------------------------------------------------- []

sub DEBUGLN 
{
  my($level,$fname,$msg) = @_;

  DEBUG($level, $fname, "$msg\n");
}

# [] ----------------------------------------------------------------- []

sub REPLACE
{
  my (@args)  = @_;

  my $in_file = $args[0];
  my $out_file = $args[1];
  my @var_names = @{$args[2]};
  my @var_values = @{$args[3]};

  # my ($in_file, $out_file, *var_names, *var_values) = @_;

  DEBUG(2, $securelog, "Creating out file $out_file with in file = $in_file");
  DEBUG(2, $securelog, "Count Var names = $#var_names Values = $#var_values");

  for (my $i = 0; $i < @var_names; $i++)
  {
    DEBUG(2, $securelog, "Replacing [$var_names[$i]] with [$var_values[$i]]");
  }

  # backup the existing out_file
  CP($out_file, "$out_file.bak.$$");

  open(INFILE, "$in_file") || die "Could not open $in_file\n";
  open(OUTFILE, ">$out_file") || die "Could not open $out_file\n";

  #loop through in_file and do substitutions
  while(<INFILE>)
  {
    for(my $i = 0; $i < @var_names; $i++)
    {
      $_ =~ s/$var_names[$i]/$var_values[$i]/g;
    }
    print OUTFILE;
  }
  close(INFILE);
  close(OUTFILE);

  return 0;
}

# [] ----------------------------------------------------------------- []

sub APPEND
{
  # Append f1 to f2.
  my ($f1, $f2) = @_;

  CAT(">>", $f1, $f2);

  return 0;
}

# [] ----------------------------------------------------------------- []

sub CAT 
{
  # Concatenate f1 to f2.
  my ($direct, $f1, $f2) = @_;

  my @linesRead;

  open(FILE, $f1) or die "Can not read $f1";
  @linesRead = <FILE>;
  close(FILE);

  if ( open(FILE, $direct . $f2) )  
  {
    foreach $_ (@linesRead) 
    {
      print(FILE $_);
    }
    close(FILE);
  } 
  else 
  {
    die "Can not write $f2";
  }

  DEBUG (2, $securelog, "Concatenated $f1 to $f2");
  return 0;
}

# [] ----------------------------------------------------------------- []

sub CATFILE 
{
  my ($my_filename) = @_;

  return 0;
}

# [] ----------------------------------------------------------------- []

sub CP {
  my ($f1, $f2) = @_;
  my $rc = File::Copy::copy($f1, $f2);

  if ($rc eq 1)
  {
     DEBUG (2, $securelog, "Successfully Copied $f1 to $f2");
  }
  else
  {
     DEBUG (2, $securelog, "Failed to copy $f1 to $f2 retval = $rc");
  }
  return 0;
}

# [] ----------------------------------------------------------------- []

sub ECHO {
  my($direct,$my_filename,$msg) = @_;

  if ( open(FILE,$direct . $my_filename) )  {
    printf(FILE "%s\n",$msg);
    close(FILE);
  } else {
    print "$msg\n";
  }
}

# [] ----------------------------------------------------------------- []

sub MKDIRP {
  my ($dir) = @_;
  File::Path::mkpath($dir); 
  DEBUG (2, $securelog, "Creating directory $dir");
  return 0;
}


# [] ----------------------------------------------------------------- []

sub RMRF {
  my ($rmDir) = @_;
  File::Path::rmtree($rmDir);
  DEBUG (2, $securelog, "Removed directory $rmDir");
  return 0;
}

# [] ----------------------------------------------------------------- []

sub RM {
  my ($rmFile) = @_;
  unlink $rmFile;
  DEBUG (2, $securelog, "Removed file $rmFile");
  return 0;
}

# [] ----------------------------------------------------------------- []
1;
