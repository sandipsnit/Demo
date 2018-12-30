#
#  $Header: SecureStatus.pm 17-may-2005.00:34:13 shianand Exp $
#
#
# Copyright (c) 2003, 2005, Oracle. All rights reserved.  
#
#    NAME
#      SecureStatus.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       shianand 05/13/05 - fix bug 4360771 
#       rpinnama 08/20/04 - Remove references to EMD ROOT 
#       rpinnama 08/26/03 - Use getConsoleClassPath and getAgentClassPath 
#       rpinnama 07/30/03 - Fix em.jar
#       rpinnama 07/24/03 - grabtrans 'rpinnama_fix_2996670'
#       ggilchri 05/07/03 - use English
#       ggilchri 04/10/03 - create
#

use English;
use strict;

use Secure;

package SecureStatus;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};

sub secureStatus
{
  my $securelog    = $_[0];
  my $component    = $_[1];
  my $omsUrl       = $_[2];
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

  my $emAgentMode      = &Secure::getAgentMode();
  my $emHome           = &Secure::getEMHome($emAgentMode);
  my $emdPropFile      = "$emHome/sysman/config/emd.properties";
  my ($protocol,$machine,$port,$ssl);
  my %agentProps;

  if (-e "$ORACLE_HOME/sysman/config/emoms.properties")
  {
    $statusAtOMS = "true";
    $classPath   = &Secure::getConsoleClassPath("");
    $propFile    = "$ORACLE_HOME/sysman/config/emoms.properties";
  }
  else
  {
    $statusAtOMS = "false";
    $classPath   = &Secure::getAgentClassPath;
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
          %agentProps  = &Secure::parseFile($emdPropFile);
          if (defined($agentProps{"REPOSITORY_URL"}))
          {
             $omsUrl = $agentProps{"REPOSITORY_URL"};
             if ($omsUrl =~ /https/)
             {
               ($protocol,$machine,$port,$ssl) = &Secure::parseURL($agentProps{"emdWalletSrcUrl"});
               my @url = split(/:/, $omsUrl);
               my @upload_dir = split(/\//,$url[2]);
               $omsUrl ="http:$url[1]:$port/$upload_dir[1]/$upload_dir[2]/\n";
               chomp($omsUrl);
             }
          }
        }
      }
      else
      { 
         Secure::DEBUG (0, $securelog, "Agent Mode Undefined.\n");
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
     Secure::DEBUG (0, $securelog, "Checking the security status of the Agent location set in $emdPropFile");
    %agentProps  = &Secure::parseFile($emdPropFile);
    ($protocol,$machine,$port,$ssl) = &Secure::parseURL($agentProps{"EMD_URL"});
     Secure::DEBUG (0, $securelog, "   Done.\n");
    if($ssl eq "Y")
    {
       Secure::DEBUG (0, $securelog, "Agent is secure at HTTPS port $port.\n");
    }
    else
    {
       Secure::DEBUG (0, $securelog, "Agent is unsecure at HTTP port $port.\n");
    }
  }

   Secure::DEBUG (0, $securelog, "Checking the security status of the OMS at ");
  if ($omsUrl eq "")
  {
     Secure::DEBUG (0, $securelog, "location set in $propFile...\n");
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
    Secure::DEBUG (0, $securelog, "$omsUrl...\n");
    $statusArgs = $omsUrl;
  }

  $javaStr = "$JAVA_HOME/bin/java ".
                   "-cp $classPath ".
                   "-DpropertiesFile=$propFile ".
                   "oracle.sysman.eml.sec.GetSecPort $statusArgs ".
                   ">> $securelog";
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
     Secure::DEBUG (0, $securelog, "   Done.\n");
    $httpsPortCmd = "$JAVA_HOME/bin/java ".
                    "-cp $classPath ".
                    "-DpropertiesFile=$propFile ".
                    "oracle.sysman.eml.sec.GetSecPort $statusArgs";
    $httpsPort = `$httpsPortCmd`;
    $httpsPort =~ s/^\s+|\s+$//;
     Secure::DEBUG (0, $securelog, "OMS is secure on HTTPS Port $httpsPort\n");
  }
  else
  {
    if ( $rc eq 2 )
    {
       Secure::DEBUG (0, $securelog, "   Done.\n");
       Secure::DEBUG (0, $securelog, "OMS is running but has not been secured. No HTTPS Port available.\n");
    }
    else
    {
       Secure::DEBUG (0, $securelog, "   Failed.\n");
       Secure::DEBUG (0, $securelog, "Could not connect to the OMS.");
    }
  }
  return $rc;
}

sub displaySecureStatusHelp
{
  print "Help!\n";
}

1;
