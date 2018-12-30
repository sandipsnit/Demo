#
#  $Header: SecureLock.pm 24-may-2005.03:05:25 shianand Exp $
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
#       shianand 05/24/05  - fix SSLWallet location in httpd_em.conf after lock 
#       shianand 05/14/05  - fix bug 4365919 
#       rpinnama 08/20/04  - Replace EMD ROOT with ORACLE_HOME 
#       rpinnama 08/19/04  - Use httpd_em.conf from ORACLE_HOME 
#       aaitghez 06/08/04 -  bug 3656322. Cleanup perl warnings 
#       dsahrawa 01/23/04 - windows portability changes 
#       rpinnama 09/04/03 - Use configureOHS utility 
#       rpinnama 08/29/03 - Fix the checking for VirtualHost 
#       rpinnama 08/26/03 - Use getConsoleClassPath to get classpath 
#       rpinnama 08/05/03 - Use common routines 
#       dsahrawa 07/30/03 - fix for bug# 3048273
#       rpinnama 07/24/03 - grabtrans 'rpinnama_fix_2996670'
#       ggilchri 05/07/03 - use English
#       ggilchri 04/10/03 - create
#

use English;
use strict;

use Secure;
use EmctlCommon;

package SecureLock;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $IS_WINDOWS        ="";
my $redirectStderr    = "2>&1";
my $rc;

my $OSNAME            = $^O;
if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $redirectStderr = "";
}
else
{
 $IS_WINDOWS="FALSE";
}

sub secureLock
{
  my $secureLog = $_[0];
  my $lockStatus = $_[1];
  my $emUploadHTTPPort  = $_[2];
  my $emUploadHTTPSPort = $_[3];
  my $emUploadDeny = ($lockStatus eq "lock") ? "all" : "none";

  #my $thisDNSHost       = `hostname`;
  my $thisDNSHost       = &EmctlCommon::getLocalHostName();
  my $omsStatusCmd      = "";

  my $classPath         = &Secure::getConsoleClassPath("");

  $thisDNSHost       =~ s/^\s+|\s+$//;

  my $propFile = "$ORACLE_HOME/sysman/config/emoms.properties";
  my $httpEmConfTemplateFile = "$ORACLE_HOME/sysman/config/httpd_em.conf.template";
  my $httpEmConfFile         = "$ORACLE_HOME/sysman/config/httpd_em.conf";

  my @procStatus = `$ORACLE_HOME/dcm/bin/dcmctl getState -v -d`;
  my $ohsStatus = statusOHS (@procStatus);
  my $execStr = "";
  my $httpdStatus = "false";

  Secure::DEBUG(0, $secureLog, "Checking the security status of the OMS...");

  $omsStatusCmd = "$JAVA_HOME/bin/java ".
                  "-cp  $classPath ".
                  "-DpropertiesFile=$propFile ".
                  "oracle.sysman.eml.sec.GetSecPort -localOMS";

  Secure::DEBUG(2, $secureLog, "Executing .. $omsStatusCmd");

  my $statusOut =`$omsStatusCmd`;

  chop $statusOut;
  if ($statusOut eq "2")
  {
    Secure::DEBUG(0, $secureLog, "   Failed.\n");
    Secure::DEBUG(0, $secureLog, "OMS is not Secure. Use emctl secure oms before attempting to lock.\n");
    exit $statusOut;
  }
  elsif ($statusOut eq "1")
  {
    Secure::DEBUG(0, $secureLog, "   Failed.\n");
    Secure::DEBUG(0, $secureLog, "Unable to detect an OMS at the location set in $propFile\n");
    exit $statusOut;
  }
  else
  {
    Secure::DEBUG(0, $secureLog, "   Done.\n");
  }
   
  #
  # if we are already in the right lock or unlock mode dont do anything.
  #
  open(EMCONFH, $httpEmConfFile) || die "Could not open $httpEmConfFile\n";
  my $vhost = "\*:$emUploadHTTPPort";
  my $curLine;
  my $insideVH = 0;
  while(defined($curLine = <EMCONFH>) && ($insideVH == 0))
  {
    chop $curLine;
    if ($curLine =~ /^.*<VirtualHost\s+\*:$emUploadHTTPPort>/) 
    {
      $insideVH = 1;
    }
  }
  if ($insideVH == 0) 
  {
      Secure::DEBUG(0, $secureLog, "Parsing error. Virtual Host not found\n");
      exit -2;
  }
  
  Secure::DEBUG(2, $secureLog, "VirtualHost found..");

  my $insideUpload = 0;
  while(defined($curLine = <EMCONFH>) && ($insideUpload == 0))
  {
    chop $curLine;
    if ($curLine =~ /^.*<Location\s+\/em\/upload>/)
    {
      $insideUpload = 1;
    }
  }
  if ($insideUpload == 0)
  {
    Secure::DEBUG(0, $secureLog, "Parsing error. Location of upload section not found\n");
    exit -3;
  }

  Secure::DEBUG(2, $secureLog, "Location found..");
  
  my $denyValue = "";
  while(defined($curLine = <EMCONFH>) && ($denyValue eq ""))
  {
    chop $curLine;
    if ($curLine =~ /^.*Deny\s+from\s+(\w+)/)
    {
      $denyValue = $1;
    }
  }

  Secure::DEBUG(2, $secureLog, "Deny Value = $denyValue");
  if ($denyValue eq $emUploadDeny)
  {
    Secure::DEBUG(0, $secureLog, "OMS host $vhost already in $lockStatus mode\n");
    exit 0;
  }

  close(EMCONFH);

  # Get the existing wallet password from httpd_em.conf
  open(EMCONFH, $httpEmConfFile) || die "Could not open $httpEmConfFile\n";
  my $omsWalletPassword = "";
  while(defined($curLine = <EMCONFH>) && ($omsWalletPassword eq ""))
  {
    chop $curLine;
    if ($curLine =~ /^.*SSLWalletPassword\s+(\w+)/)
    {
        $omsWalletPassword = $1;
    }
  }
  close(EMCONFH);

  Secure::DEBUG(2, $secureLog, "Wallet Password = $omsWalletPassword");

  # stop httpd if needed
   if( $ohsStatus eq "Up" )
   {
      $rc = stopOHS ($secureLog);
      if ($rc eq 0)
      {
        $httpdStatus = "true";
      }
      else
      {
        exit -4;
      }
   }

  # update the httpd conf to restrict http upload
  Secure::DEBUG(0, $secureLog, "Updating HTTPS Virtual Host for Enterprise Manager OMS...");
  
  $rc = SecureOMS::configureOHS($secureLog, $emUploadHTTPSPort, $emUploadHTTPPort, 
                                $thisDNSHost, $omsWalletPassword, $emUploadDeny);
  if ($rc eq 0)
  {
    Secure::DEBUG (0, $secureLog, "   Done.\n");
    # start httpd if needed
    if ($httpdStatus eq "true")
    {
      $rc = startOHS($secureLog);
    }
  }
  else
  {
    Secure::DEBUG (0, $secureLog, "   Failed rc = $rc.\n");
    return $rc;
  }


  if  ("$lockStatus" eq "lock")
  {
    Secure::DEBUG(0, $secureLog, "OMS Locked. Agents must be Secure and upload over HTTPS Port $statusOut.\n");
  }
  else
  {
    Secure::DEBUG(0, $secureLog, "OMS Unlocked. Non Secure Agents may upload using HTTP.\n");
  }

  return $rc;
}

sub statusOHS()
{
  my (@args) = @_;
  my $count = scalar(@args);
  my @comp;

  my $i=0;
  while( $i < $count)
  {
     @comp = split /\s+/, $args[$i];
     if(($comp[1] =~ /HTTP/) || ($comp[2] =~ /HTTP/))
     {
        return $comp[3];
     }
     $i = $i + 1;
  }
}

sub startOHS
{
  my $secureLog = $_[0];
  Secure::DEBUG (0, $secureLog, "Starting the HTTP Server...");
  my $execStr = "$ORACLE_HOME/opmn/bin/opmnctl startproc type=ohs >> $secureLog $redirectStderr";
  $rc = 0xffff & system ($execStr);
  $rc >>= 8;
  if ($rc != 0)
  {
    Secure::DEBUG (0, $secureLog, "   Failed.\n");
  }
  else
  {
    Secure::DEBUG (0, $secureLog, "   Done.\n");
  }
  return $rc;
}

sub stopOHS
{
  my $secureLog = $_[0];
  Secure::DEBUG(0, $secureLog, "Stopping the HTTP Server...");
  my $execStr = "$ORACLE_HOME/opmn/bin/opmnctl stopproc type=ohs >> $secureLog $redirectStderr";
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ($rc != 0)
  {
     Secure::DEBUG(0, $secureLog, "  Failed\n");
     exit $rc;
  }
  else
  {
    Secure::DEBUG(0, $secureLog, "  Done.\n");
  }
  return $rc;
}


1;

