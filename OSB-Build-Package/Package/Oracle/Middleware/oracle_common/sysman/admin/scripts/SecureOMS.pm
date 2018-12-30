#
#  $Header: SecureOMS.pm 24-may-2005.03:12:02 shianand Exp $
#
#
# Copyright (c) 2003, 2005, Oracle. All rights reserved.  
#
#    NAME
#      SecureOMS.pm - Secure OMS Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    shianand    05/24/05  - fix SSLWallet location in httpd_em.conf after lock 
#    shianand    05/05/05  - fix bug 4294700 
#    shianand    03/14/05  - fix bug 4199037 
#    shianand    03/13/05  - fix bug 4171514 
#    rpinnama    08/20/04  - Make emHome ORACLE_HOME 
#    rpinnama    08/20/04  - Remove references to EMD ROOT 
#    rpinnama    08/19/04  - Use httpd_em.conf from ORACLE_HOME 
#    aaitghez    06/08/04 -  bug 3656322. Cleanup perl warnings 
#    rpinnama    04/19/04 - Fix 3570867 : Use osslpassword on Windows as 
#                           iasobf.bat doesnt exist 
#    rpinnama    02/13/04 - Fix bug 3402177: For DBConsole use hostname 
#                           parameter if passed 
#    dsahrawa    01/23/04 - windows portability changes 
#    rzazueta    12/02/03 - Define emConsoleMode in SecureOMS 
#    rpinnama    10/06/03 - Use proper EM Home for dbconsole 
#    lgloyd      09/16/03 - obfuscate SSLWalletPassword 
#    rpinnama    09/04/03 - 
#    rpinnama    09/03/03 - Update opmn.xml and 
#    rpinnama    08/29/03 - use Secure::REPLACE to templatize httpd_em.conf 
#    rpinnama    08/26/03 - Use getConsoleClassPath 
#    caroy       08/18/03 - change from phaos.jar to ojpse_2_1_5.jar 
#    rpinnama    08/13/03 - Do not restart OMS at the end of securing it 
#    rpinnama    08/07/03 - Add more debug traces 
#    rpinnama    08/05/03 - Use common routines 
#    rpinnama    07/30/03 - Fix em.jar
#    rpinnama    07/24/03 - grabtrans 'rpinnama_fix_2996670'
#    rpinnama    06/23/03 - Propmt for sysman's password
#    ggilchri    05/07/03 - use English
#    ggilchri    04/24/03 - variable ports
#    aaitghez    03/13/03 - aaitghez_fix_stage_030306
#    ggilchri    03/03/03 - ggilchri_perl_sslsetup
#    ggilchri    03/03/03 - use sslsetup
#    dmshah      02/06/03 - Created
#

use English;
use strict;

use Secure;
use SecureRootKey;
use SecureGenWallet;
use SecureGenKeystore;
use EmctlCommon;

package SecureOMS;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $IS_WINDOWS        = "";
my $redirectStderr    = "2>&1";

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


# [] ----------------------------------------------------------------- []

sub genRootKey {
  my $securelog       = $_[0];
  my $emConsoleMode   = $_[1];
  my $thisDNSHost     = $_[2];
  my $emWalletsDir    = $_[3];
  
  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";

  if (defined($_[4])) {
    $root_dc     = $_[4];
  }
  if (defined($_[5])) {
    $root_country  = $_[5];
  }
  if (defined($_[6])) {
    $root_state       = $_[6];
  }
  if (defined($_[7])) {
    $root_loc         = $_[7];
  }
  if (defined($_[8])) {
    $root_org         = $_[8];
  }
  if (defined($_[9])) {
    $root_unit        = $_[9];
  }
  if (defined($_[10])) {
    $root_email       = $_[10];
  }

  my $rc = SecureRootKey::secureRootKey($securelog, $emConsoleMode, 
                                        $thisDNSHost, $emWalletsDir,
                                        $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email);
  return $rc;
}

# [] ----------------------------------------------------------------- []

sub genWallet {
  my $securelog            = $_[0];
  my $emConsoleMode        = $_[1];
  my $thisDNSHost          = $_[2];
  my $obfOMSWalletPassword = $_[3];
  my $rootKeyDir           = $_[4];
  my $omsCertName          = $_[5];
  my $walletType           = $_[6];
  my $obfEMRootPassword    = $_[7];

  my $rc = SecureGenWallet::secureGenWallet ($securelog, $emConsoleMode, $walletType, 
                                          $thisDNSHost, $obfOMSWalletPassword, 
                                          $rootKeyDir, $omsCertName, "", 
                                          $obfEMRootPassword);
  return $rc;
}

# [] ----------------------------------------------------------------- []

sub genKeyStore {
  my $securelog       = $_[0];
  my $emConsoleMode   = $_[1];
  my $thisDNSHost     = $_[2];
  my $rc = SecureGenKeystore::secureGenKeystore ($securelog, $emConsoleMode, 
                                              $thisDNSHost, "", "true");
  return $rc;
}

# [] ----------------------------------------------------------------- []

sub secureCentralOMS
{
  my (@args)            = @_;

  my $securelog         = "";
  my $emConsoleMode     = "";
  my $emUploadHTTPPort  = "";
  my $emUploadHTTPSPort = "";
  my $rootPassword      = "";
  my $regPassword       = "";
  my $slbHost           = "";
  my $omsReset          = "";

  my $rc;
  my $stopStatus;

  if (defined($args[0])) {
    $securelog         = $args[0];
  }
  if (defined($args[1])) {
    $emConsoleMode     = $args[1];
  }
  if (defined($args[2])) {
    $emUploadHTTPPort  = $args[2];
  }
  if (defined($args[3])) {
    $emUploadHTTPSPort = $args[3];
  }
  if (defined($args[4])) {
    $rootPassword      = $args[4];
  }
  if (defined($args[5])) {
    $regPassword       = $args[5];
  }
  if (defined($args[6])) {
    $slbHost           = $args[6];
  }
  if (defined($args[7])) {
    $omsReset          = $args[7];
  }

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";

  if (defined($args[8])) {
    $root_dc          = $args[8];
  }
  if (defined($args[9])) {
    $root_country     = $args[9];
  }
  if (defined($args[10])) {
    $root_state       = $args[10];
  }
  if (defined($args[11])) {
    $root_loc         = $args[11];
  }
  if (defined($args[12])) {
    $root_org         = $args[12];
  }
  if (defined($args[13])) {
    $root_unit        = $args[13];
  }
  if (defined($args[14])) {
    $root_email       = $args[14];
  }

  #my $dnsHostName = Secure::getServerName();
  my $dnsHostName = &EmctlCommon::getLocalHostName();

  if ($emConsoleMode eq "CENTRAL")
  {
    Secure::DEBUG (0, $securelog, "Stopping opmn processes...\n");
    $stopStatus = stopOMS($securelog);
    if ($stopStatus eq 0 or $stopStatus eq 1)
    {
      Secure::DEBUG (0, $securelog, "Securing central oms...\n");
      $rc = secureOMS($securelog, $emConsoleMode, $emUploadHTTPPort,
                      $emUploadHTTPSPort, $rootPassword, $regPassword,
                      $slbHost, $omsReset,
                      $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email,
                      $dnsHostName);
      if ($stopStatus eq 0)
      {
        Secure::DEBUG (0, $securelog, "Restarting opmn processes...\n");
        restartOMS($securelog);
      }
      return $rc;
    }
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Aborting secure oms...\n");
    exit 2;
  }
}

# [] ----------------------------------------------------------------- []

sub secureOMS
{
  my (@args)         = @_;

  my $securelog         = "";
  my $emConsoleMode     = "";
  my $emUploadHTTPPort  = "";
  my $emUploadHTTPSPort = "";
  my $rootPassword      = "";
  my $regPassword       = "";
  my $omsCertName       = "";
  my $resetKey          = "";


  my $obfRootPassword   = "";
  my $omsWalletPwdCmd   = "";
  my $omsWalletPassword = "";
  my $storeRootKey      = "";
  my $rootKeyDir        = "";
  my $javaStr           = "";
  my $execStr           = "";
  my $resetVerify       = "";
  my $rc;
  my @linesRead;
  my $no_changes = 0;
  my $walletOk;
  my @iasobfResultWords;
  my $iasobfResultLen;
  my $iasobfOMSWalletPassword;

  if (defined($args[0])) {
    $securelog         = $args[0];
  }
  if (defined($args[1])) {
    $emConsoleMode     = $args[1];
  }
  if (defined($args[2])) {
    $emUploadHTTPPort  = $args[2];
  }
  if (defined($args[3])) {
    $emUploadHTTPSPort = $args[3];
  }
  if (defined($args[4])) {
    $rootPassword      = $args[4];
  }
  if (defined($args[5])) {
    $regPassword       = $args[5];
  }
  if (defined($args[6])) {
    $omsCertName       = $args[6];
  }
  if (defined($args[7])) {
    $resetKey          = $args[7];
  }

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";
 
  my $dnsHostName  = ""; #added to get the qualified name of server bug 4294700
  my $thisDNSHost  = "";

  if (defined($args[8])) {
    $root_dc          = $args[8];
  }
  if (defined($args[9])) {
    $root_country     = $args[9];
  }
  if (defined($args[10])) {
    $root_state       = $args[10];
  }
  if (defined($args[11])) {
    $root_loc         = $args[11];
  }
  if (defined($args[12])) {
    $root_org         = $args[12];
  }
  if (defined($args[13])) {
    $root_unit        = $args[13];
  }
  if (defined($args[14])) {
    $root_email       = $args[14];
  }
  if (defined($args[15])) {
    $dnsHostName      = $args[15];
  }

  my $emHome            = &Secure::getEMHome($emConsoleMode);

  my $emLibDir          = "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib";
  my $emWalletsDir      = "$ORACLE_HOME/sysman/wallets";
  my $classPath         = &Secure::getConsoleClassPath($emConsoleMode);

  if ($dnsHostName ne "")
  {
    $thisDNSHost = $dnsHostName;
  }
  else
  {
    $thisDNSHost       = `hostname`;
    $thisDNSHost       =~ s/^\s+|\s+$//;
  }

  # If not certificate name is passed, default to  'hostname'
  if ($omsCertName eq "")
  {
    $omsCertName=$thisDNSHost;
  }

  if ($emConsoleMode eq "CENTRAL")
  {
    $emLibDir  = "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib";
  }
  else
  {
    $emLibDir  = "$ORACLE_HOME/sysman/webapps/emd/WEB-INF/lib";
  }

  $rootKeyDir = "$emWalletsDir/ca.$thisDNSHost";

  $storeRootKey = "true";

  Secure::DEBUG (2, $securelog, "Obfuscating rootPassword ... $rootPassword");
  my $obfRootPwdCmd = "$JAVA_HOME/bin/java ".
                      " -cp $classPath ".
		      "-DORACLE_HOME=$ORACLE_HOME ".
		      "oracle.sysman.eml.sec.Obfuscate -cypher $rootPassword";

  Secure::DEBUG (2, $securelog, "Executing cmd .. $obfRootPwdCmd ");
  $obfRootPassword = `$obfRootPwdCmd`;
  $obfRootPassword=~ s/^\s+|\s+$//;
  Secure::DEBUG (2, $securelog, "obfuscated root pwd = $obfRootPassword ");

  Secure::DEBUG (0, $securelog, "Checking Repository...");
  $javaStr = "$JAVA_HOME/bin/java ".
                   " -cp $classPath ".
                   "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
                   "oracle.sysman.eml.sec.InstallPassword ".
                   "-auth $rootPassword ".
                   ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing cmd .. $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 2 )
  {
    Secure::DEBUG (0, $securelog, "ERROR. Unable to contact the OMS Repository.\n");
    exit 2;
  }
  else
  {
    if ( $rc eq 0 )
    {
      Secure::DEBUG (0, $securelog, "   Done.\n");
    }
    else
    {
      Secure::DEBUG (0, $securelog, "   Invalid Password.\n");
      exit 2;
    }
  }

  #
  # check the store to see if a Root Key may already exist. This is true if 
  # we are able to find an existing Root Signing Certificate. If so, do not 
  # overwrite it without an explicit -reset.
  #
  Secure::DEBUG (0, $securelog, "Checking Repository for an existing Enterprise Manager Root Key...");
  $storeRootKey  = "true";
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DrootKeyDir=$rootKeyDir ".
             "-DrootPassword=$obfRootPassword ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.RepRootCert ".
             ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing cmd .. $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    $storeRootKey = "false";
    if( $resetKey eq "")
    {
      Secure::DEBUG (0, $securelog, "   Done.\n");
      Secure::DEBUG (1, $securelog, "Root Key in Repository will be reused.\n");
    }
    else
    {
      Secure::DEBUG (0, $securelog, "\n");
      Secure::DEBUG (0, $securelog, "WARNING! An Enterprise Manager Root Key already exists in\n");
      Secure::DEBUG (0, $securelog, "the Repository. This operation will replace your Enterprise\n");
      Secure::DEBUG (0, $securelog, "Manager Root Key.\n");
      Secure::DEBUG (0, $securelog, "");
      Secure::DEBUG (0, $securelog, "All existing Agents that use HTTPS will need to be\n");
      Secure::DEBUG (0, $securelog, "reconfigured if you proceed. Do you wish to continue and\n");
      Secure::DEBUG (0, $securelog, "overwrite your Root Key\n");
      Secure::DEBUG (0, $securelog, "(Y/N) ?\n");
      $resetVerify=<STDIN>;
      chomp ($resetVerify);
      if ($resetVerify eq "Y")
      { 
        Secure::DEBUG (0, $securelog, "");
        Secure::DEBUG (0, $securelog, "Are you sure ? Reset of the Enterprise Manager Root Key\n");
        Secure::DEBUG (0, $securelog, "will mean that you will need to reconfigure each Agent\n");
        Secure::DEBUG (0, $securelog, "that is associated with this OMS before they will be\n");
        Secure::DEBUG (0, $securelog, "able to upload any data to it. Monitoring of Targets\n");
        Secure::DEBUG (0, $securelog, "associated with these Agents will be unavailable until\n");
        Secure::DEBUG (0, $securelog, "after they are reconfigured.\n");
        Secure::DEBUG (0, $securelog, "(Y/N) ?\n");
        $resetVerify=<STDIN>;
        chomp ($resetVerify);
        if ($resetVerify eq "Y")
        {
          $storeRootKey = "true";
        }
        else
        {
          exit 0;
        }
      }
      else
      {
        exit 0;
      }
    }
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  if ($storeRootKey eq "true")
  {
    Secure::DEBUG (0, $securelog, "Generating Enterprise Manager Root Key (this takes a minute)...");
    my $rootKeyOk = genRootKey($securelog, $emConsoleMode, $thisDNSHost, $emWalletsDir,
                               $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email,
                               $obfRootPassword);
    if ($rootKeyOk eq 0)
    {
      Secure::DEBUG (0, $securelog, "   Done.\n");
    }
    else
    {
      Secure::DEBUG (0, $securelog, "Failed to create Enterprise Manager Root Key.\n");
      exit 2;
    }
  }

  #
  # save the CA Certificate in the location used by the Console for its
  # trustpoint during outbound java ssl connections
  #
  Secure::DEBUG (0, $securelog, "Fetching Root Certificate from the Repository...");
  my $b64TextFile = "$emHome/sysman/config/b64LocalCertificate.txt";
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DrootPassword=$obfRootPassword ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.RepRootCert ".
             "-saveCert $b64TextFile ".
             ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing cmd .. $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Failed. rc = $rc\n");
    exit $rc;
  }

  Secure::DEBUG (0, $securelog, "Generating Registration Password Verifier in the Repository...");
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DrootPassword=$obfRootPassword ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.InstallPassword ".
             "$regPassword ".
             ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing cmd .. $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Failed.\n");
    if ( $rc eq 2 )
    {
      Secure::DEBUG (0, $securelog, "The Agent Registration Password you supplied does not match the Verifier set in this Repository.\n");
    }
    exit $rc;
  }

  if ($emConsoleMode eq "CENTRAL")
  {
    #
    # Generate a random password to be used for the OMS Oracle Wallet
    #
    Secure::DEBUG (0, $securelog, "Generating Oracle Wallet Password for Enterprise Manager OMS...");
    $omsWalletPwdCmd = "$JAVA_HOME/bin/java ".
                       "-cp $classPath ".
		       "oracle.sysman.util.crypt.Verifier -genPassword";
    Secure::DEBUG (2, $securelog, "Executing cmd .. $javaStr");
    $omsWalletPassword = `$omsWalletPwdCmd`;
    $omsWalletPassword=~ s/^\s+|\s+$//;
    Secure::DEBUG (2, $securelog, "omsWalletPwd = $omsWalletPassword");
    Secure::DEBUG (0, $securelog, "   Done.\n");

    #
    # Obtain obfuscated values for the input passwords
    #
    Secure::DEBUG (0, $securelog, "Generating Oracle Wallet for Enterprise Manager OMS...");
    Secure::DEBUG (2, $securelog, "Obfuscating OMS wallet password...");
    my $obfOMSWalletPwdCmd = "$JAVA_HOME/bin/java ".
                             " -cp $classPath ".
			     "-DORACLE_HOME=$ORACLE_HOME ".
			     "oracle.sysman.eml.sec.Obfuscate -cypher $omsWalletPassword";

    Secure::DEBUG (2, $securelog, "Executing cmd .. $obfOMSWalletPwdCmd");
    my $obfOMSWalletPassword = `$obfOMSWalletPwdCmd`;
    $obfOMSWalletPassword=~ s/^\s+|\s+$//;
    Secure::DEBUG (2, $securelog, "Obfuscated omsWalletPwd = $obfOMSWalletPassword ");

    #
    # Use genwallet to make the Oracle Wallet that will be used by the OMS for
    # https upload. Pass in OMS_CERT_NAME to be used if it has a value to
    # override the name goven to the OMS in its certificate
    #
    $walletOk = genWallet ($securelog, $emConsoleMode, $thisDNSHost, 
                           $obfOMSWalletPassword, "rep", $omsCertName, 
                           "oms", $obfRootPassword);
    if ($walletOk eq 0)
    {
      Secure::DEBUG (0, $securelog, "   Done.\n");
    }

    #
    # Use genwallet to make another Oracle Wallet that may be used by iAS
    # for https browser access, just in case one does not exist and the user
    # has no current means to obtain one.
    #
    # Since we are offering a Wallet that may be used by Apache as a courtesy
    # in the event of one not exiting at all then it is ok to seed this wallet
    # with the default iAS HTTP Server Wallet Password, "welcome". If the user
    # decides to use this Wallet for their iAS Web Server then they should
    # change the password and configure their HTTP Server accordingly.
    #
    Secure::DEBUG (0, $securelog, "Generating Oracle Wallet for iAS HTTP Server...");
    my $IASWalletPassword="welcome";
    my $obfIASWalletPwdCmd = "$JAVA_HOME/bin/java ".
                             " -cp $classPath ".
			     "-DORACLE_HOME=$ORACLE_HOME ".
			     "oracle.sysman.eml.sec.Obfuscate -cypher $IASWalletPassword";
    Secure::DEBUG (2, $securelog, "Executing cmd .. $obfIASWalletPwdCmd");
    my $obfIASWalletPassword = `$obfIASWalletPwdCmd`;
    $obfIASWalletPassword=~ s/^\s+|\s+$//;
    Secure::DEBUG (2, $securelog, "Obfuscated IASWalletPwd = $obfIASWalletPassword ");

    $walletOk = genWallet ($securelog, $emConsoleMode, $thisDNSHost, 
                           $obfIASWalletPassword, "rep", $omsCertName, 
			   "ias", $obfRootPassword);
    if ($walletOk eq 0)
    {
      Secure::DEBUG (0, $securelog, "   Done.\n");
    }
  }

  #
  # save the upload https port number in emoms.properties
  #
  Secure::DEBUG (0, $securelog, "Updating HTTPS port in emoms.properties file...");
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.SetProperty $emUploadHTTPSPort ".
             ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing cmd .. $javaStr");
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "   Failed. rc = $rc\n");
    exit $rc;
  }

  if ($emConsoleMode eq "CENTRAL")
  {
    Secure::DEBUG (0, $securelog, "Generating HTTPS Virtual Host for Enterprise Manager OMS...");

    my $iasObfCmd = "$ORACLE_HOME/Apache/Apache/bin/iasobf ";

    if ("$IS_WINDOWS" eq "TRUE")
    {
      $iasObfCmd = "$ORACLE_HOME/Apache/Apache/bin/osslpassword.exe ";
    }


    # get ias obfuscated passsword from iasobf utility
    my $iasobfOMSWalletPwdCmd = "$iasObfCmd -p $omsWalletPassword";

    Secure::DEBUG (2, $securelog, "Executing cmd .. $iasobfOMSWalletPwdCmd");
    my $iasobfOMSWalletPwdCmdResult = `$iasobfOMSWalletPwdCmd`;

    # parse results for password (last string in results returned)
    @iasobfResultWords = split (/ /, $iasobfOMSWalletPwdCmdResult);
    $iasobfResultLen = @iasobfResultWords;
    $iasobfOMSWalletPassword = $iasobfResultWords[$iasobfResultLen-1];   
    $iasobfOMSWalletPassword=~ s/^\s+|\s+$//;
    
    Secure::DEBUG (2, $securelog, "Obfuscated iasobfOMSWalletPwd = $iasobfOMSWalletPassword ");

    $rc = configureOHS($securelog, $emUploadHTTPSPort, $emUploadHTTPPort, 
                       $thisDNSHost, $iasobfOMSWalletPassword, "none");

    if ($rc eq 0)
    {
      Secure::DEBUG (0, $securelog, "   Done.\n");
    }
    else
    {
      Secure::DEBUG (0, $securelog, "   Failed rc = $rc.\n");
      return $rc;
    }
  }
  else
  {
    #
    # This "OMS" is really a Standalone OC4J and needs a Keystore
    #
    Secure::DEBUG (0, $securelog, "Generating Java Keystore...");
    my $keyStoreOk = genKeyStore ($securelog, $emConsoleMode, $omsCertName);
    if (not $keyStoreOk eq 0)
    {
      Secure::DEBUG (0, $securelog, "   Failed.\n");
      exit $rc;
    }
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  return 0;
}

sub configureOHS
{
  my $securelog         = $_[0];
  my $emUploadHTTPSPort = $_[1];
  my $emUploadHTTPPort  = $_[2];
  my $thisDNSHost       = $_[3];
  my $omsWalletPassword = $_[4];
  my $emUploadDeny      = $_[5];

  my $rc = 0;

  Secure::DEBUG (1, $securelog, "Enabling SSL for Oracle HTTP Server ...");
  # Modify opmn.xml to ensure that OHS is started with ssl-enabled.
  $rc = enableSSLForOHS($securelog);
  if ($rc eq 0)
  {
    Secure::DEBUG (1, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "   Failed rc = $rc.\n");
    return $rc;
  }


  Secure::DEBUG (1, $securelog, "Generating HTTPS Virtual Host for Enterprise Manager OMS...");
  # Instantiate httpd_em.conf.template
  my $httpEmConfTemplateFile = "$ORACLE_HOME/sysman/config/httpd_em.conf.template";
  my $httpEmConfFile         = "$ORACLE_HOME/sysman/config/httpd_em.conf";

  my @var_names = ("&EM_UPLOAD_HTTPS_PORT&", "&EM_UPLOAD_HTTP_PORT&", "&ORACLE_HOME&",
                   "&THIS_DNS_HOST&", "&OMS_WALLET_PASSWORD&", 
		   "&EM_UPLOAD_DENY&", "&EM_VHOST&");

  my @var_values =("$emUploadHTTPSPort",     "$emUploadHTTPPort", "$ORACLE_HOME",
                   "$thisDNSHost", "$omsWalletPassword",
		   "$emUploadDeny", "$thisDNSHost");

  $rc = Secure::REPLACE($httpEmConfTemplateFile, $httpEmConfFile, \@var_names, \@var_values);

  if ($rc eq 0)
  {
    Secure::DEBUG (1, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "   Failed rc = $rc.\n");
    return $rc;
  }

  # Update DCM configuration
  # bug 3048273. inform DCM about config changes
  Secure::DEBUG(1, $securelog, "Updating DCM config info...");
  my $dcmCmd = "$ORACLE_HOME/dcm/bin/dcmctl updateconfig -ct ohs  >> $securelog $redirectStderr";
  $rc = 0xffff & system($dcmCmd);
  $rc >>= 8;
  if ($rc eq 0)
  {
    Secure::DEBUG(1, $securelog, "  Done.\n");
  }
  else
  {
    Secure::DEBUG(1, $securelog, "  Failed.\n");
    return $rc;
  }

  return $rc;
}

sub enableSSLForOHS
{
  my $securelog       = $_[0];

  my $sslDisabled     = 0;
  my $rc              = 0;

  my $opmnConfigFileOrig = "$ORACLE_HOME/opmn/conf/opmn.xml";
  my $opmnConfigFileNew  = "$ORACLE_HOME/opmn/conf/opmn.xml.$$";

  Secure::DEBUG (1, $securelog,"Enabling SSL for OHS in opmn.xml ...");

  open(FILE, $opmnConfigFileOrig) or die "Can not read targets file($opmnConfigFileOrig)";
  my @linesRead = <FILE>;
  close(FILE);

  ;# Enable only if SSL is disabled.
  foreach $_ (@linesRead) 
  {
    if (/data.*start-mode.*ssl-disabled/) 
    {
       $sslDisabled = 1;
    }
  }

  if ($sslDisabled eq 1)
  {
    ;# Walk the lines, and write to new file
    if ( open(FILE,">" . $opmnConfigFileNew) )  
    {
      foreach $_ (@linesRead) 
      {
        ;# Change ssl-disabled to ssl-enabled
        if (/data.*start-mode.*ssl-disabled/) 
	{
          s/ssl-disabled/ssl-enabled/;
        }
        ;# Print the property line
        print(FILE $_);
      }
      close(FILE);
    } 
    else 
    {
      die "Can not write new OPMN.XML ($opmnConfigFileNew)";
    }

    if (! rename $opmnConfigFileOrig, "$opmnConfigFileOrig.bak.$$") 
    {
      die "Could not rename OPMN config file\n$!\n";
    }
    if (! rename $opmnConfigFileNew, $opmnConfigFileOrig) 
    {
      die "Could not rename new OPMN config file\n$!\n";
    }
  }
     
  Secure::DEBUG (1, $securelog,"   Done.\n");
  return $rc;
}


sub stopOMS()
{
  my $rc;
  my $securelog     = $_[0];
  my $omsStopStr    = "$ORACLE_HOME/opmn/bin/opmnctl stopall >> $securelog $redirectStderr";
  my $omsStartStr   = "$ORACLE_HOME/opmn/bin/opmnctl startall >> $securelog $redirectStderr";
  my $omsStatusStr  = "$ORACLE_HOME/opmn/bin/opmnctl status >> $securelog $redirectStderr";

  $rc = 0xffff & system($omsStatusStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    system($omsStopStr);
    $rc = 0xffff & system($omsStatusStr);
    $rc >>= 8;
    if ($rc eq 0)
    {
      Secure::DEBUG (0, $securelog,"Failed to stop opmn processes...\n");
      exit 2;
    }
    elsif ($rc eq 2)
    {
      Secure::DEBUG (0, $securelog,"OPMN processes successfully stopped...\n");          
      return 0;
    }
    else
    {
      my $tries=30;
      while( $tries gt 0 )
      {
        sleep 1;
        $rc = 0xffff & system($omsStatusStr);
        $rc >>= 8;
        if ($rc ne 2)
        {
          last;
        }
        $tries = $tries-1;
        print ".";
      }
      $rc = 0xffff & system($omsStatusStr);
      $rc >>= 8;
      if ($rc eq 2)
      {
        Secure::DEBUG (0, $securelog,"OPMN processes successfully stopped...\n");      
        return 0;
      }
      else
      {
        Secure::DEBUG (0, $securelog,"Failed to stop opmn processes...\n");
        Secure::DEBUG (2, $securelog,"Error: $rc...\n");     
        exit 2;
      }
    }
  }
  elsif ($rc eq 2)
  {
    Secure::DEBUG (0, $securelog,"OPMN processes already stopped...\n");            
    return 1;
  }
  else
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($omsStatusStr);
      $rc >>= 8;
      if ($rc ne 2)
      {
        last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($omsStatusStr);
    $rc >>= 8;
    if ($rc eq 2)
    {
      Secure::DEBUG (0, $securelog,"OPMN processes successfully stopped...\n");      
      return 0;
    }
    else
    {
      Secure::DEBUG (0, $securelog,"Failed to stop opmn processes...\n");
      Secure::DEBUG (2, $securelog,"Error: $rc...\n");   
      exit 2;
    }
  }
}

sub restartOMS
{
  my $rc;
  my $securelog     = $_[0];
  my $omsStopStr    = "$ORACLE_HOME/opmn/bin/opmnctl stopall >> $securelog $redirectStderr";
  my $omsStartStr   = "$ORACLE_HOME/opmn/bin/opmnctl startall >> $securelog $redirectStderr";
  my $omsStatusStr  = "$ORACLE_HOME/opmn/bin/opmnctl status >> $securelog $redirectStderr";

  system($omsStartStr);
  $rc = 0xffff & system($omsStatusStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    Secure::DEBUG (0, $securelog,"OPMN processes successfully restarted...\n");      
    return 0;
  }
  elsif ($rc eq 2)
  {
    Secure::DEBUG (0, $securelog,"Failed to restart opmn processes...\n");  
    exit 2;
  }
  else
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($omsStatusStr);
      $rc >>= 8;
      if ($rc ne 0)
      {
        last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($omsStatusStr);
    $rc >>= 8;
    if ($rc eq 0)
    {
      Secure::DEBUG (0, $securelog,"OPMN processes successfully restarted...\n");    
      return 0;
    }
    else
    {
      Secure::DEBUG (0, $securelog,"Failed to restart opmn processes...\n");
      Secure::DEBUG (0, $securelog,"Error: $rc...\n");    
      exit 2;
    }
  }
}


sub displaySecureOMSHelp
{
  print "Help!\n";
}

1;
