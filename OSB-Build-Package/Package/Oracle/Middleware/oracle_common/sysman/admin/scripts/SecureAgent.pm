#
#  $Header: SecureAgent.pm 09-may-2005.03:13:10 shianand Exp $
#
#
# Copyright (c) 2003, 2005, Oracle. All rights reserved.  
#
#    NAME
#      Secure.pm - Secure Agent Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    shianand    05/09/05 - fix bug 4356156 
#    shianand    04/06/05 - fix bug 4249755 
#    shianand    03/13/05 - fix bug 4171514 
#    rzazueta    03/07/05 - Change CENTRAL to CENTRAL_AGENT 
#    shianand    10/18/04 - Unsecure agent fix_3107941 
#    rzkrishn    09/28/04 - add debug statements 
#    rzkrishn    08/27/04 - copy instead of rename 
#    rpinnama    08/20/04 - 
#    rzazueta    03/02/04 - change emdctl stop agent to emctl stop agent 
#    kduvvuri    01/26/04 - fix bug 3398999, use perl grep for portability 
#    dsahrawa    01/23/04 - windows portability changes 
#    rpinnama    10/15/03 - Fix secure agent to use statebased files 
#    rpinnama    10/10/03 - Remove the already secure check. Agent should be 
#                           able to resecure
#    rpinnama    10/06/03 - Use proper EM home for dbconsole 
#    rpinnama    08/29/03 - 
#    rpinnama    08/27/03 - Fix bug 3115545. Use JRE_HOME if one exists 
#    rpinnama    08/26/03 - Use getAgentClassPath 
#    rpinnama    08/13/03 - Add http_client.jar to all java invocations 
#    rpinnama    08/11/03 - Fix compilation 
#    dsahrawa    08/04/03 - bug 2836031 
#    rpinnama    08/05/03 - Use common routines 
#    rpinnama    07/24/03 - grabtrans 'rpinnama_fix_2996670'
#    ggilchri    05/12/03 - break out config function
#    ggilchri    05/07/03 - use English
#    ggilchri    03/03/03 - ggilchri_perl_sslsetup
#    ggilchri    02/17/03 - content
#    dmshah      02/06/03 - Created
#
#

use English;
use strict;

use Secure;

package SecureAgent;

my $ORACLE_HOME = $ENV{ORACLE_HOME};
my $EMDROOT     = $ENV{EMDROOT};

my $IS_WINDOWS="";
my $redirectStderr = "2>&1"; 
my $OSNAME  = $^O;

if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $redirectStderr = "";
}
else
{
 $IS_WINDOWS="FALSE";
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

  Secure::DEBUG (0, $securelog,"Configuring Agent for HTTPS in $emConsoleMode mode...");
  my $emHome = &Secure::getEMHome($emConsoleMode);

  my $propertiesFileOrig = "$emHome/sysman/config/emd.properties";
  my $propertiesFileNew  = "$emHome/sysman/config/emd.properties.$$";
  open(PROPFILE,$propertiesFileOrig) or die "Can not read EMD.PROPERTIES ($propertiesFileOrig)";
  my @emdURLlinesRead = grep /EMD_URL=http/, <PROPFILE>;
  close(PROPFILE) or die "Can not close EMD.PROPERTIES ($propertiesFileOrig)";
  my $numLinesEMDURL = scalar @emdURLlinesRead;
  if ( $numLinesEMDURL <= 0  )
  {
    Secure::DEBUG (0, $securelog,"Warning:\n");
    Secure::DEBUG (0, $securelog,"Unable to configure $propertiesFileOrig\n");
    Secure::DEBUG (0, $securelog,"You must set the EMD_URL and REPOSITORY_URL in\n");
    Secure::DEBUG (0, $securelog,"$propertiesFileOrig to use HTTPS\n");
  }
  else
  {
    if ( $em_upload_https_url eq "-1" )
    {
      # really should not be here if the OMS is not secure
      Secure::DEBUG (0, $securelog,"   Failed.\n");
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
      Secure::CP ($propertiesFileOrig, "$propertiesFileOrig.bak.$$");
      Secure::CP ($propertiesFileNew, $propertiesFileOrig);
      Secure::RM ($propertiesFileNew); 

      Secure::DEBUG (0, $securelog,"   Done.\n");

      ;# Sanity check
      if ($no_changes == 0) {
         $agentURLStringLog = "Warning: failed to reset set EMD_URL.";
         $configureAgentOk  = 1;
      } else {
        $agentURLStringLog  = "EMD_URL set in $propertiesFileOrig";
         $configureAgentOk  = 0;
      }
      Secure::DEBUG (0, $securelog,"$agentURLStringLog\n");
    }
    return $configureAgentOk;
  }
}

# [] ----------------------------------------------------------------- []

sub secureAgent
{
  my $securelog     = $_[0];
  my $emConsoleMode = $_[1];
  my $password      = $_[2];

  my $javaStr;
  my $classPath;
  my $rc;
  my $debug = $ENV{EM_SECURE_VERBOSE};
  my $emHome = &Secure::getEMHome($emConsoleMode);
  $securelog      = "$emHome/sysman/log/secure.log";

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

  if ($debug ne "")
  {
      $debug = "true";
  }
  else
  {
      $debug = "false";
  }

  $classPath = &Secure::getAgentClassPath;

  my $propfile = "$emHome/sysman/config/emd.properties";
  # No need to check if the agent is already secured.

  Secure::DEBUG (0, $securelog, "Stopping agent...\n");
  my $stopStatus = stopAgent($securelog);
  if ($stopStatus eq 0 or $stopStatus eq 1)
  {
    Secure::DEBUG (0, $securelog, "Securing agent...\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Aborting secure agent...\n");
    exit 2;
  }

  if (not (-e "$emHome/sysman/config/server"))
  {
    mkdir ("$emHome/sysman/config/server", 0755)
  }

  Secure::DEBUG (0, $securelog,"Requesting an HTTPS Upload URL from the OMS...");

  my $emUploadHTTPSURLCmd = "$JAVA_HOME/bin/java ".
                            "-cp $classPath ".
                            "-DpropertiesFile=$propfile ".
                            " -Ddebug=$debug ".
                            "oracle.sysman.eml.sec.GetSecPort -displayURL";

  Secure::DEBUG (2, $securelog,"Executing ... $emUploadHTTPSURLCmd");

  my $em_upload_https_url=`$emUploadHTTPSURLCmd`;

  my $verify_em_upload_https_url=$em_upload_https_url;
  $verify_em_upload_https_url=~ s/^\s+|\s+$//;

  Secure::DEBUG (1, $securelog,"OMS HTTPS URL ... $verify_em_upload_https_url");

  if ( $verify_em_upload_https_url eq "-1" )
  {
    Secure::DEBUG (0, $securelog,"   Failed.\n");
    Secure::DEBUG (0, $securelog,"The OMS is not set up for Enterprise Manager Security.\n");
    exit 3;
  }
  else
  {
    Secure::DEBUG (0, $securelog,"   Done.\n");
  }


  Secure::DEBUG (0, $securelog,"Requesting an Oracle Wallet and Agent Key from the OMS...");
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
	     " -DpropertiesFile=$propfile ".
             " -Ddebug=$debug ".
	     "oracle.sysman.eml.sec.GetWallet $password ".
             ">> $securelog";

  Secure::DEBUG (2, $securelog,"Executing ... $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog,"   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog,"   Failed.\n");
    if ( $rc eq 1 )
    {
      Secure::DEBUG (0, $securelog,"Failed to contact the OMS at the HTTP URL set in $propfile\n");
    }
    elsif ( $rc eq 2 )
    {
      Secure::DEBUG (0, $securelog,"Invalid Agent Registration Password.\n");
    }
    Secure::DEBUG (0, $securelog,"The Agent has not been secured.\n");
    exit 4;
  }

  # check if the URL is available
  Secure::DEBUG (0, $securelog,"Check if HTTPS Upload URL is accessible from the agent...");
  my $checkAvailUrlCmd = "$JAVA_HOME/bin/java ".
                         "-cp $classPath ".
                         " -DpropertiesFile=$propfile ".
                         " -Ddebug=$debug ".
                         "oracle.sysman.eml.sec.CheckURLAvailability ".
			 " $verify_em_upload_https_url >> $securelog $redirectStderr";

  Secure::DEBUG (2, $securelog,"Executing ... $checkAvailUrlCmd");

  my $availStatus = 0xfff & system($checkAvailUrlCmd);
  $availStatus >>= 8;
  if ($availStatus == 0) # passed
  {
    Secure::DEBUG (0, $securelog,"   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog,"   Failed.\n");
    Secure::DEBUG (0, $securelog,"The Agent has not been secured.\n");
    exit 5;
  }

  # configure the properties file
  configureAgent ($securelog, $emConsoleMode, $em_upload_https_url);

  if ($stopStatus eq 0)
  {
    Secure::DEBUG (0, $securelog, "Restarting agent...\n");
    restartAgent($securelog);
  }
}


#
#unsecureAgent
#
sub unsecureAgent
{
   my $rc;
   my $unsecport = "";
   my $debug = $ENV{EM_SECURE_VERBOSE}; 
   my $securelog = $_[1];

   my $emHome = &Secure::getEMHome($_[0]);
   my $classPath = &Secure::getAgentClassPath;

   my $stopStatus;
   $securelog      = "$emHome/sysman/log/secure.log";
   
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

   if ($debug ne "")
   {
      $debug = "true";
   }
   else
   {
      $debug = "false";
   }

   Secure::DEBUG (0, $securelog,"Configuring Agent for HTTP...\n");

   my $file = "$emHome/sysman/config/emd.properties";
   my $propfile = "$emHome/sysman/config/emd.properties";

   Secure::DEBUG (2, $securelog,"Reading properties from $propfile\n");

   open(PROPFILE,$propfile) or die "Can not read EMD.PROPERTIES ($propfile)";
   my @emdURLlinesRead = grep /EMD_URL=https:/, <PROPFILE>;
   close(PROPFILE) or die "Can not close EMD.PROPERTIES ($propfile)";

   my $numLinesEMDURL = scalar @emdURLlinesRead;
   if($numLinesEMDURL <= 0)
   {
      Secure::DEBUG (0, $securelog,"Agent is already unsecured.\n");
   }
   else
   {
      Secure::DEBUG (0, $securelog, "Stopping agent...\n");
      $stopStatus = stopAgent($securelog);
      if ($stopStatus eq 0 or $stopStatus eq 1)
      {
         Secure::DEBUG (0, $securelog, "Unsecuring agent...\n");
      }
      else
      {
         Secure::DEBUG (0, $securelog, "Aborting unsecure agent...\n");
         exit 2;
      }

      Secure::DEBUG (2, $securelog,"Changing secure url to unsecure url.\n");
      my $em_upload_http_url; #this is used to check that given url is available

      open(INFO, $file);
      my @lines = <INFO>;
      close(INFO) || die;

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
            if($readline =~ /emdWalletSrcUrl=/)
            {
               my @details = split(/:/,$readline);
               my @checkport = split(/\//,@details[2]);
               $unsecport = @checkport[0];
               Secure::DEBUG (2, $securelog,"Valid OMS HTTP Port.$unsecport\n");
            }
         }
      }

      my @rep_url = split(/:/, $em_upload_http_url);
      my @rep_upload_dir = split(/\//,$rep_url[2]);
      $em_upload_http_url ="REPOSITORY_URL=http:@rep_url[1]:$unsecport/$rep_upload_dir[1]/$rep_upload_dir[2]/\n";

      my $verify_em_upload_http_url = "http:@rep_url[1]:$unsecport/$rep_upload_dir[1]/$rep_upload_dir[2]/";
      Secure::DEBUG (2, $securelog,"Check REPOSITORY_URL = $verify_em_upload_http_url.\n");

      my $checkAvailUrlCmd = "$JAVA_HOME/bin/java ".
                             "-cp $classPath ".
                             " -DpropertiesFile=$propfile ".
                             " -Ddebug=$debug ".
                             "oracle.sysman.eml.sec.CheckURLAvailability ".
                             " $verify_em_upload_http_url >> $securelog $redirectStderr";

      Secure::DEBUG (2, $securelog,"Executing ... $checkAvailUrlCmd");
     
      my $availStatus = 0xfff & system($checkAvailUrlCmd);
      $availStatus >>= 8;
      if ($availStatus == 0) #Passed
      {
          Secure::DEBUG (2, $securelog,"OMS http url open.\n");
          
          open (NEWFILE, ">$file.$$") || die "Cannot write to $file.$$\n";
          foreach my $readline (@lines)
          {
             if($readline =~ /REPOSITORY_URL=https:/)
             {
                Secure::DEBUG (2, $securelog,"Configured REPOSITORY_URL = $readline.\n");
                $readline = $em_upload_http_url;
             }
             if($readline =~ /EMD_URL=https:/)
             {
                Secure::DEBUG (2, $securelog,"Configured EMD_URL = $readline.\n");
                $readline =~ s/https\:/http\:/;
             }

             print NEWFILE "$readline";
          }

          close (NEWFILE) || die;
          
          Secure::CP ("$file", "$file.bak.$$");
          Secure::CP ("$file.$$", $file);
          Secure::RM ("$file.$$");
          Secure::DEBUG (0, $securelog,"Agent is now unsecured...\n");
          $rc = 0;
      }
      else
      {
          Secure::DEBUG (0, $securelog,"OMS Upload URL - $verify_em_upload_http_url is locked or unavailable.\n");
          Secure::RM ("$file.$$");
          Secure::DEBUG (0, $securelog,"Unsecuring Agent...  Failed.\n");
          $rc = 1;
      }
   }

   if ($stopStatus eq 0)
   {
     Secure::DEBUG (0, $securelog, "Restarting agent...\n");
     restartAgent($securelog);
   }
   return $rc;
}


sub stopAgent
{
  my $rc;
  my $securelog       = $_[0];
  my $agentStatusStr  = "$EMDROOT/bin/emdctl status agent >> $securelog $redirectStderr";
  my $agentStopStr    = "$ORACLE_HOME/bin/emctl stop agent >> $securelog $redirectStderr";
  my $agentStartStr   = "$ORACLE_HOME/bin/emctl start agent >> $securelog $redirectStderr";

  $rc = 0xffff & system($agentStatusStr);
  $rc >>= 8;
  if ($rc eq 3)
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
    if ($rc eq 3)
    {
      Secure::DEBUG (0, $securelog,"Failed to stop agent...\n");
      exit 2;
    }
    elsif ($rc eq 1)
    {
      Secure::DEBUG (0, $securelog,"Agent successfully stopped...\n");
      return 0;
    }
    else
    {
      Secure::DEBUG (0, $securelog,"Failed to stop agent...\n");
      Secure::DEBUG (2, $securelog,"Error: $rc...\n");
      exit 2;
    }
  }
  elsif ($rc eq 1)
  {
    Secure::DEBUG (0, $securelog,"Agent is already stopped...\n");
    return 1;
  }
  else
  {
    Secure::DEBUG (0, $securelog,"Failed to stop agent...\n");
    Secure::DEBUG (2, $securelog,"Error: $rc...\n");
    exit 2;
  }
}


sub restartAgent
{
  my $rc;
  my $securelog       = $_[0];
  my $agentStatusStr  = "$EMDROOT/bin/emdctl status agent >> $securelog $redirectStderr";
  my $agentStopStr    = "$ORACLE_HOME/bin/emctl stop agent >> $securelog $redirectStderr";
  my $agentStartStr   = "$ORACLE_HOME/bin/emctl start agent >> $securelog $redirectStderr";

  system($agentStartStr);
  $rc = 0xffff & system($agentStatusStr);
  $rc >>= 8;
  if ($rc eq 3)
  {
    Secure::DEBUG (0, $securelog,"Agent successfully restarted...\n");
    return 0;
  }
  elsif ($rc eq 1)
  {
    Secure::DEBUG (0, $securelog,"Failed to restart agent...\n");
    exit 2;
  }
  else
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
      Secure::DEBUG (0, $securelog,"Agent successfully restarted...\n");
      return 0;
    }
    else
    {
      Secure::DEBUG (0, $securelog,"Failed to restart agent...\n");
      Secure::DEBUG (2, $securelog,"Error: $rc...\n");
      exit 2;
    }
  }
}


sub displaySecureAgentHelp
{
  print "Help!\n";
}

1;
