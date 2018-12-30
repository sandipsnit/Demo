#
#  $Header: SecureMakeServerWlt.pm 23-aug-2004.18:56:09 rpinnama Exp $
#
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      SecureMakeServerWlt.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       rpinnama 08/23/04 - Add DEBUG flags 
#       rpinnama 08/20/04 - Remove references to EMDROOT 
#       dsahrawa 01/23/04 - windows portability changes 
#       rpinnama 10/06/03 - Use proper db home 
#       rpinnama 08/26/03 - Use getConsoleClassPath 
#       caroy    08/18/03 - change from phaos.jar to ojpse_2_1_5.jar 
#       rpinnama 08/05/03 - Use common routines 
#       rpinnama 07/30/03 - Fix em jar file
#       rpinnama 07/24/03 - grabtrans 'rpinnama_fix_2996670'
#       ggilchri 05/07/03 - use English
#       ggilchri 04/11/03 - ggilchri_sb_sta_sll
#       ggilchri 04/10/03 - create
#


use English;
use strict;


package SecureMakeServerWlt;

my $IS_WINDOWS        ="";
my $redirectStderr    = "2>&1";

my $OSNAME            = $^O;


if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
}
else
{
 $IS_WINDOWS="FALSE";
}

# [] ----------------------------------------------------------------- []

sub secureMakeServerWlt
{
  my $oracleHome           = $_[0];
  my $javaHome             = $_[1];
  my $securelog            = $_[2];
  my $emConsoleMode        = $_[3];
  my $walletType           = $_[4];
  my $rootKeyDir           = $_[5];
  my $emWalletsDir         = $_[6];
  my $thisDNSHost          = $_[7];
  my $obfOMSWalletPassword = $_[8];
  my $certName             = $_[9];
  my $rootKeyPassword      = $_[10];
  my $obfEMRootPassword    = $_[11];

  my $serverDN = "";
  my $serverCertDir = "";
  my $javaStr = "";
  my $rc;

  my $classPath = &Secure::getConsoleClassPath($emConsoleMode);

  my $debug = $ENV{EM_SECURE_VERBOSE};
  if ($debug ne "")
  {
      $debug = "true";
  }
  else
  {
      $debug = "false";
  }

  if ($certName eq "")
  {
    $certName = $thisDNSHost;
  }
  $serverDN      = "cn=$certName";
  $serverCertDir = "$emWalletsDir/$walletType.$thisDNSHost";
  Secure::MKDIRP ($serverCertDir);

  Secure::DEBUG (2, $securelog, "Making server wallet for DN = $serverDN");

  $javaStr  = "$javaHome/bin/java ".
              "-cp $classPath ".
              "-DrootPassword=$obfEMRootPassword ".
              "-DemConsoleMode=$emConsoleMode ".
              " -Ddebug=$debug ".
              "-DORACLE_HOME=$oracleHome ".
              "-DrepositoryPropertiesFile=$oracleHome/sysman/config/emoms.properties ".
              "oracle.sysman.eml.sec.WalletUtil ".
              "$serverDN $obfOMSWalletPassword $serverCertDir ".
              "$rootKeyDir $rootKeyPassword ".
              ">> $securelog $redirectStderr";

  Secure::DEBUG (2, $securelog, "Executing ... $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  return $rc;
}

sub displaySecureMakeServerWlt
{
  print "Help!\n";
}

1;
