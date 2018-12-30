#!/usr/local/bin/perl
#
#  $Header: SecureGenWallet.pm 26-aug-2004.22:03:36 rpinnama Exp $
#
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      SecureGenWallet.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       rpinnama 08/26/04 - Pass DBCONSOLE to getEMHome 
#       rpinnama 08/20/04 - Use ORACLE_HOME from ENV 
#       dsahrawa 01/23/04 - windows portability changes 
#       rpinnama 10/23/03 - Use proper oracleHome for dbconsole 
#       rpinnama 10/06/03 - Use proper EM home for dbconsole 
#       rpinnama 09/29/03 - Use APPEND 
#       rpinnama 09/22/03 - 
#       rpinnama 09/03/03 - Avoid using EM_STANDALONE 
#       rpinnama 08/13/03 - Check for standalone 
#       rpinnama 08/05/03 - use strict and also use common routines
#       ggilchri 04/22/03 - ggilchri_genwallet_perl_callout_main
#       ggilchri 04/11/03 - ggilchri_sb_sta_sll
#       ggilchri 04/10/03 - create.
#

use English;
use strict;

use Secure;
use SecureMakeServerWlt;

package SecureGenWallet;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $emConfigDir       = "$ORACLE_HOME/sysman/config";


# [] ----------------------------------------------------------------- []

sub secureGenWallet
{
  my $securelog            = $_[0];
  my $emConsoleMode        = $_[1];
  my $walletType           = $_[2];
  my $thisDNSHost          = $_[3];
  my $obfOMSWalletPassword = $_[4];
  my $rootKeyDir           = $_[5];
  my $certName             = $_[6];
  my $rootKeyPassword      = $_[7];
  my $obfEMRootPassword    = $_[8];

  my $emWalletsDir         = "$ORACLE_HOME/sysman/wallets";
  my $agentDownloadDir     = "";
  my $emdIntTrustCertFile  = "";
  my $emdLocalTrustCertFile = "";
  my $emHome               = "";
  my $emWalletFile         = "";
  my $rc;

  if ($emConsoleMode eq "DBCONSOLE")
  {
    $emHome = &Secure::getEMHome($emConsoleMode);
    $emWalletsDir = "$emHome/sysman/wallets";

    $emConfigDir = "$emHome/sysman/config";
  }
  else
  {
    $emHome = $ORACLE_HOME;
  }

  Secure::DEBUG (1, $securelog, "SecureGenWallet : ConsoleMode = $emConsoleMode");
  Secure::DEBUG (1, $securelog, "SecureGenWallet : walletType = $walletType");
  Secure::DEBUG (1, $securelog, "SecureGenWallet : DNSHost = $thisDNSHost");

  #
  # make a new wallet for $thisDNSHost. 
  #
  $rc = SecureMakeServerWlt::secureMakeServerWlt($emHome, $JAVA_HOME, $securelog, 
                                 $emConsoleMode, $walletType, $rootKeyDir, $emWalletsDir, 
				 $thisDNSHost, $obfOMSWalletPassword, $certName, 
				 $rootKeyPassword, $obfEMRootPassword);

  #
  # stage the new wallet and the trust points to be accessible over
  # the ~/wallets/emd console URL in iAS
  #
  if ($emConsoleMode eq "CENTRAL")
  {
    $agentDownloadDir="$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/wallets/$walletType.$thisDNSHost";
  }
  elsif ($emConsoleMode eq "DBCONSOLE")
  {
    $agentDownloadDir="$ORACLE_HOME/oc4j/j2ee/oc4j_applications/applications/em/em/wallets/$walletType.$thisDNSHost";
  }
  else
  {
    $agentDownloadDir="$ORACLE_HOME/sysman/webapps/em/wallets/$walletType.$thisDNSHost";
  }
  Secure::DEBUG (1, $securelog, "Agent Download dir = " .$agentDownloadDir);

  if (not (-e $agentDownloadDir))
  {
    Secure::MKDIRP ($agentDownloadDir);
  }

  $emWalletFile="$emWalletsDir/$walletType.$thisDNSHost/ewallet.p12";
  if (not (-e $emWalletFile))
  {
    die "Missing $emWalletFile\n";
  }
  else
  {
    Secure::CP ($emWalletFile, $agentDownloadDir);
  }

  #
  # Pick up the OMS Root CA Certificate from the Oracle Home as this will
  # have been placed here during emctl secure oms ..
  #
  $emdLocalTrustCertFile="$emConfigDir/b64LocalCertificate.txt";
  if (not (-e $emdLocalTrustCertFile))
  {
    die "The EMD local trust cert was not created in $emdLocalTrustCertFile";
  }
  else
  {
    #
    # set up both the b64Local and b64Internet to have the trust point of the
    # console cert signing authority. The console may need to be monitored just
    # like a remote https site on the internet
    #
    Secure::CP ($emdLocalTrustCertFile, "$agentDownloadDir/b64LocalCertificate.txt");
    Secure::CP ($emdLocalTrustCertFile, "$agentDownloadDir/b64InternetCertificate.txt");
  }

  $emdIntTrustCertFile="$emConfigDir/b64InternetCertificate.txt";
  if (not (-e $emdIntTrustCertFile))
  {
    die "The EMD local trust cert was not created in $emdIntTrustCertFile";
  }
  else
  {
    Secure::APPEND ($emdIntTrustCertFile, "$agentDownloadDir/b64InternetCertificate.txt");
  }
}

sub displaySecureGenWallet
{
  print "Help!\n";
}

1;

