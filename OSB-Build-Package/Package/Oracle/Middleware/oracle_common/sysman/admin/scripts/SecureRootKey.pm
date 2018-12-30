#
#  $Header: SecureRootKey.pm 16-mar-2005.07:29:34 shianand Exp $
#
#
# Copyright (c) 2003, 2005, Oracle. All rights reserved.  
#
#    NAME
#      SecureRootKey.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    shianand    03/14/05 - fix bug 4199037 
#    shianand    03/03/05 - 
#    rpinnama    08/20/04 - Remove references to EMD ROOT 
#    rpinnama    10/10/03 - Support state based home for dbconsole 
#    rpinnama    08/26/03 - Use getConsoleClassPath 
#    caroy       08/18/03 - change from phaos.jar to ojpse_2_1_5.jar 
#    rpinnama    08/05/03 - Use common routines 
#    rpinnama    07/30/03 - Fix em.jar
#    rpinnama    07/24/03 - grabtrans 'rpinnama_fix_2996670'
#    ggilchri    05/07/03 - use English
#    ggilchri    04/11/03 - ggilchri_sb_sta_sll
#    ggilchri    03/03/03 - ggilchri_perl_sslsetup
#    ggilchri    02/17/03 - content
#    dmshah      02/06/03 - Created
#
#

use English;
use strict;

use Secure;

package SecureRootKey;

my $ORACLE_HOME = $ENV{ORACLE_HOME};
my $JAVA_HOME   = $ENV{JAVA_HOME};
my $IS_WINDOWS  ="";

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

sub secureRootKey
{
  my $securelog       = $_[0];
  my $emConsoleMode   = $_[1];
  my $thisDNSHost     = $_[2];
  my $emWalletsDir    = $_[3];

  my $caDir   = "$emWalletsDir/ca.$thisDNSHost";
  Secure::RMRF ($caDir);
  Secure::MKDIRP ($caDir);

  my $dc      = "com";
  my $country = "US";
  my $state   = "CA";
  my $loc     = "EnterpriseManager on $thisDNSHost";
  my $org     = "EnterpriseManager on $thisDNSHost";
  my $unit    = "EnterpriseManager on $thisDNSHost";
  my $email   = "Enterprise.Manager\@$thisDNSHost";


  if ($_[4] ne "") {
    $dc      = $_[4];
    chomp ($dc);
    if(length ($dc) gt 3)
    {
      $dc = substr($dc, 0, 2);
    }
    $dc =~ tr/A-Z/a-z/;
  }
  if ($_[5] ne "") {
    $country = $_[5];
    chomp ($country);
    if(length ($country) gt 2)
    {
      $country = substr($country, 0, 1);
    }
    $country =~ tr/a-z/A-Z/;
  }
  if ($_[6] ne "") {
    $state   = $_[6];
    chomp ($state);
    if(length ($state) gt 2)
    {
      $state = substr($state, 0, 1);
    }
    $state =~ tr/a-z/A-Z/;
  } 
  if ($_[7] ne "") {
    $loc     = $_[7];
    chomp ($loc);
  }
  if ($_[8] ne "") {
    $org     = $_[8];
    chomp ($org);
  }
  if ($_[9] ne "") {
    $unit    = $_[9];
    chomp ($unit);
  }
  if ($_[10] ne "") {
    $email   = $_[10];
    chomp ($email);
  }

  my $rootKeyPassword = $_[11];

  my $javaStr   = "";
  my $classPath = &Secure::getConsoleClassPath($emConsoleMode);
  my $emHome    = &Secure::getEMHome($emConsoleMode);
  my $rc;

  #
  # Call GenRootCert to mke the CA. This class accepts 1 or 2 args depending
  # on whether there already exists an override value for rootKeyPassword. If
  # there is not then GenRootCert will make a random password for the CA.
  #
  # Use Phaos to Generate a Root Key and Certificate in the given location.
  #

  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "-Desm.HOSTNAME=\"$thisDNSHost\" ".
             "-Desm.DC=\"$dc\" ".
             "-Desm.COUNTRY=\"$country\" ".
             "-Desm.STATE=\"$state\" ".
             "-Desm.LOC=\"$loc\" ".
             "-Desm.ORG=\"$org \" ".
             "-Desm.ORGUNIT=\"$unit\" ".
             "-Desm.EMAIL=\"$email\" ".
             "-DORACLE_HOME=$ORACLE_HOME ".
             "oracle.sysman.eml.sec.GenRootCert $caDir $rootKeyPassword ".
             ">> $securelog";

  Secure::DEBUG (2, $securelog, "Executing .... $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;

  #
  # Copy the standard trust points to the CA directory for easy inclusion
  # into new wallets
  Secure::CP( "$ORACLE_HOME/sysman/config/b64InternetCertificate.txt", $caDir );

  return $rc;
}


sub displaySecureRootKeyHelp
{
  print "Help!\n";
}

1;
