#
#  $Header: SecureStandaloneConsole.pm 14-mar-2005.07:58:25 shianand Exp $
#
#
# Copyright (c) 2003, 2005, Oracle. All rights reserved.  
#
#    NAME
#      Secure.pm - Secure Standalone Console Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    shianand   03/14/05 - fix bug 4199037 
#    shianand   03/13/05 - fix bug 4171514 
#    shianand   01/06/05 - bug 8020820 fix 
#    shianand   11/25/04 - Unsecure iasconsole bug fix 3134623 
#    rpinnama   08/20/04 - 
#    rpinnama   04/01/04 - Pass emHome to getAgentHostName 
#    rpinnama   09/29/03 - Copy internet cert from download dir 
#    rpinnama   08/26/03 - Use getConsoleClassPath 
#    caroy      08/18/03 - change from phaos.jar to ojpse_2_1_5.jar 
#    rpinnama   08/11/03 - 
#    rpinnama   07/24/03 - grabtrans 'rpinnama_fix_2996670'
#    ggilchri   05/14/03 - ggilchri_bug-2927444
#    ggilchri   05/12/03 - sed config and copy wallet
#    ggilchri   04/29/03 - generate local root key
#    created    02/06/03 - Created
#

use English;
use strict;

use SecureGenKeystore;
use Secure;

package SecureStandaloneConsole;

my $ORACLE_HOME    = $ENV{ORACLE_HOME};
my $EMDROOT        = $ENV{EMDROOT};
my $JAVA_HOME      = $ENV{JAVA_HOME};
my $JRE_HOME       = $ENV{JRE_HOME};
my $DEFAULT_CLASSPATH = $ENV{DEFAULT_CLASSPATH};
my $IS_WINDOWS     = "";
my $binExt         = "";
my $devNull        = "/dev/null";
my $cpSep          = ":";
my $OSNAME         = $^O;
my $redirectStderr = "2>&1";

if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $binExt = "\.exe";
 $devNull = "nul";
 $cpSep = ";";
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

  my $rc;

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";

  if (defined($_[4])) {
    $root_dc          = $_[4];
  }
  if (defined($_[5])) {
    $root_country     = $_[5];
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

  my $rootKeyPassword = $_[11];

  $rc = SecureRootKey::secureRootKey($securelog, $emConsoleMode, $thisDNSHost, 
                                     $emWalletsDir,
                                     $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email,
                                     $rootKeyPassword);
  return $rc;
}

# [] ----------------------------------------------------------------- []

sub genWallet 
{
  my $securelog              = $_[0];
  my $emConsoleMode          = $_[1];
  my $thisDNSHost            = $_[2];
  my $obfAgentWalletPassword = $_[3];
  my $rootKeyDir             = $_[4];
  my $rootKeyPassword        = $_[5];
  my $certName               = $_[6];
  my $walletType             = $_[7];

  my $rc;

  $rc = SecureGenWallet::secureGenWallet ($securelog, $emConsoleMode, 
                                          $walletType, $thisDNSHost, 
                                          $obfAgentWalletPassword, $rootKeyDir, 
					  $certName, $rootKeyPassword);
  return $rc;
}

# [] ----------------------------------------------------------------- []

sub genAgentWallet 
{

  my $securelog       = $_[0];
  my $rootKeyDir      = $_[1];
  my $rootKeyPassword = $_[2];
  my $thisDNSHost     = $_[3];
  my $certName        = $_[4];

  my $rc;
  my $walletOk;
  my $agentKeyCmd;
  my $agentKey;
  my $agentKeyStoreCmd;
  my $obfAgentWalletCmd;
  my $obfAgentWalletPassword;
  
  my $emLibDir      = "$ORACLE_HOME/sysman/webapps/emd/WEB-INF/lib";
  my $emdWalletDest = "$ORACLE_HOME/sysman/config/server";

  #
  # Generate a random password (agent key) to be used for the Agent Oracle Wallet
  #
  Secure::DEBUG (0, $securelog, "Generating Standalone Console Agent Key...");
  $agentKeyCmd         = "$JAVA_HOME/bin/java ".
                         "-cp $DEFAULT_CLASSPATH".
                         "$cpSep$emLibDir/emd.jar ".
			 "oracle.sysman.util.crypt.Verifier -genPassword";

  $agentKey            = `$agentKeyCmd`;
  $agentKey            =~ s/^\s+|\s+$//;

  Secure::DEBUG (2, $securelog, "Agent key cmd = ". $agentKeyCmd );
  Secure::DEBUG (2, $securelog, "Agent key = ". $agentKey );
  Secure::DEBUGLN (0, $securelog, "   Done.");

  #
  # Store the Agent Key in repoconn.ora
  #
  Secure::DEBUG (0, $securelog, "Storing Standalone Console Agent Key...");
  $emdWalletDest = "$ORACLE_HOME/sysman/config/server";
  if (not -e $emdWalletDest)
  {
    Secure::DEBUG (1, $securelog, "Creating directory ". $emdWalletDest);
    Secure::MKDIRP ($emdWalletDest);
  }
  $agentKeyStoreCmd = "$JAVA_HOME/bin/java ".
                      "-cp $DEFAULT_CLASSPATH".
		      "$cpSep$ORACLE_HOME/jlib/ojmisc.jar".
		      "$cpSep$emLibDir/ojpse_2_1_5.jar".
		      "$cpSep$emLibDir/emd.jar ".
		      "-DemdWalletDest=$emdWalletDest ".
		      "-DORACLE_HOME=$ORACLE_HOME ".
		      "oracle.sysman.eml.sec.Obfuscate -storekey $agentKey";

  $rc = `$agentKeyStoreCmd`; 

  Secure::DEBUG (2, $securelog, "Agent key store cmd = $agentKeyStoreCmd ");
  Secure::DEBUG (2, $securelog, "Agent key store retval= $rc" );

  Secure::DEBUGLN (0, $securelog, "   Done.");

  #
  # Obtain the obfuscated agent key for Wallet encryption.. 
  #
  Secure::DEBUG (0, $securelog, "Generating Oracle Wallet for the Standalone Console Agent...");
  Secure::DEBUG (1, $securelog, "Generating key for Standalone Console Agent...");
  $obfAgentWalletCmd = "$JAVA_HOME/bin/java ".
                        "-cp $DEFAULT_CLASSPATH".
			"$cpSep$ORACLE_HOME/jlib/ojmisc.jar".
			"$cpSep$emLibDir/ojpse_2_1_5.jar".
			"$cpSep$emLibDir/emd.jar ".
			"-DORACLE_HOME=$ORACLE_HOME ".
			"oracle.sysman.eml.sec.Obfuscate -cypher $agentKey";

  $obfAgentWalletPassword = `$obfAgentWalletCmd`;
  $obfAgentWalletPassword       =~ s/^\s+|\s+$//;
  Secure::DEBUG (2, $securelog, "Obfuscate Wallet cmd = " . $obfAgentWalletCmd ); 
  Secure::DEBUG (2, $securelog, "Obfuscated Wallet pwd = " . $obfAgentWalletPassword ); 

  #
  # Use genwallet to make the Oracle Wallet that will be used by the Agent
  # to listen using SSL. Pass in OMS_CERT_NAME to be used if it has a value to
  # override the name given to the Agent in its certificate
  #
  if ($certName eq "")
  {
    $certName=$thisDNSHost;
  }

  Secure::DEBUG (1, $securelog, "Calling genWallet for StandAlone");

  $walletOk = genWallet ($securelog, "STANDALONE", $thisDNSHost, 
                         $obfAgentWalletPassword, $rootKeyDir, 
			 $rootKeyPassword, $certName, "agent");
  if ($walletOk eq 0)
  {
    Secure::DEBUGLN (0, $securelog, "   Done.");
  }
  return $walletOk
}

sub configureAgent {
  my $securelog           = $_[0];
  my $emConsoleMode       = $_[1];
  my $em_https_upload_url = $_[2];

  my $configureAgentOk = SecureAgent::configureAgent ($securelog, $emConsoleMode, 
                                                   $em_https_upload_url);
}

# [] ----------------------------------------------------------------- []

sub genKeyStore {
  my $securelog       = $_[0];
  my $emConsoleMode   = $_[1];
  my $thisDNSHost     = $_[2];
  my $rootKeyPassword = $_[3];

  my $rc;

  $rc = SecureGenKeystore::secureGenKeystore ($securelog, $emConsoleMode, 
                                              $thisDNSHost, $rootKeyPassword, 
					      "true");
  return $rc;
}

# [] ----------------------------------------------------------------- []

sub updateStandaloneConsoleURL 
{
  my $securelog       = $_[0];

  my $targetsFileOrig = "$ORACLE_HOME/sysman/emd/targets.xml";
  my $targetsFileNew  = "$ORACLE_HOME/sysman/emd/targets.xml.$$";

  Secure::DEBUG (1, $securelog,"updateStandaloneConsoleURL ...");

  open(FILE, $targetsFileOrig) or die "Can not read targets file($targetsFileOrig)";
  my @linesRead = <FILE>;
  close(FILE);

  ;# Walk the lines, and write to new file
  my $no_changes = 0;
  if ( open(FILE,">" . $targetsFileNew) )  {
    foreach $_ (@linesRead) {
      ;# Change HTTP with HTTPS
      if (/Property.*StandaloneConsoleURL/) {
        s/http\:/https\:/;
        $no_changes = 1;
      }
      ;# Print the property line
      print(FILE $_);
    }
    close(FILE);
  } else {
    die "Can not write new EMD.PROPERTIES ($targetsFileNew)";
  }

  if (! rename $targetsFileOrig, "$targetsFileOrig.bak.$$") {
    die "Could not rename targets file\n$!\n";
  }
  if (! rename $targetsFileNew, $targetsFileOrig) {
    die "Could not rename new targets file\n$!\n";
  }
  Secure::DEBUG (1, $securelog,"   Done.\n");
  return 0;
}


# [] ----------------------------------------------------------------- []


sub secureStandaloneConsole
{
  my $securelog    = $_[0];
  my $certName     = $_[1];
  my $emdHTTPSPort = $_[2];

  my $root_dc      = "";
  my $root_country = "";
  my $root_state   = "";
  my $root_loc     = "";
  my $root_org     = "";
  my $root_unit    = "";
  my $root_email   = "";


  if (defined($_[3])) {
    $root_dc      = $_[3];
  }
  if (defined($_[4])) {
    $root_country = $_[4];
  }
  if (defined($_[5])) {
    $root_state   = $_[5];
  }
  if (defined($_[6])) {
    $root_loc     = $_[6];
  }
  if (defined($_[7])) {
    $root_org     = $_[7];
  }
  if (defined($_[8])) {
    $root_unit    = $_[8];
  }
  if (defined($_[9])) {
    $root_email   = $_[9];
  }

  my $rc;
  my $javaStr;
  my $keyStoreOk;
  my $agentConfigOk;
  my $useOMSRootKey;
  my $rootKeyCmd;
  my $rootKeyPassword;
  my $rootKeyOk;
  my $agentDownloadDir;
  my $agentWalletFile;
  my $b64InternetCertFile;
  my $agentWalletOk;
  my $b64TextFile;
  my $emLibDir;

  my $emWalletsDir   = "$ORACLE_HOME/sysman/wallets";
  my $emConsoleMode  = "STANDALONE";

  my $emHome  = &Secure::getEMHome($emConsoleMode);

  my ($thisDNSHost, $thisAgentPort) = &Secure::getAgentHostname($emHome);

  my $rootKeyDir     = "$emWalletsDir/ca.$thisDNSHost";

  my $classPath      = &Secure::getConsoleClassPath($emConsoleMode);

  Secure::DEBUG (2, $securelog, "ConsoleMode = $emConsoleMode");
  Secure::DEBUG (2, $securelog, "EMDROOT = $EMDROOT");
  Secure::DEBUG (2, $securelog, "EMHome = $emHome");
  Secure::DEBUG (2, $securelog, "DNSHost = $thisDNSHost");
  Secure::DEBUG (2, $securelog, "AgentPort = $thisAgentPort");

  Secure::DEBUG (0, $securelog, "Stopping iasconsole...\n");
  my $stopStatus = stopStandaloneConsole($securelog);
  if ($stopStatus eq 0 or $stopStatus eq 1)
  {
    Secure::DEBUG (0, $securelog, "Securing iasconsole...\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Aborting secure iasconsole...\n");
    exit 2;
  }

  Secure::DEBUG (0, $securelog, "Generating Standalone Console Root Key (this takes a minute)...");
  $emLibDir            = "$ORACLE_HOME/sysman/webapps/emd/WEB-INF/lib";

  $rootKeyCmd          = "$JAVA_HOME/bin/java ".
                         " -cp $classPath ".
			 "oracle.sysman.util.crypt.Verifier -genPassword";
  $rootKeyPassword     = `$rootKeyCmd`;
  $rootKeyPassword     =~ s/^\s+|\s+$//;

  Secure::DEBUG (2, $securelog, "Root key Password cmd = $rootKeyCmd");
  Secure::DEBUG (2, $securelog, "Root key Password = $rootKeyPassword");

  $rootKeyOk = genRootKey ($securelog, $emConsoleMode, $thisDNSHost, 
                           $emWalletsDir,
                           $root_dc, $root_country, $root_state, $root_loc, $root_org, $root_unit, $root_email,
                           $rootKeyPassword);

  if ($rootKeyOk eq 0)
  {
    Secure::DEBUG (0, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (0, $securelog, "Failed to create Enterprise Manager Root Key.\n");
    exit 2;
  }
  #
  # save the CA Certificate in the location used by the Console for its
  # trustpoint during outbound java ssl connections
  #
  Secure::DEBUG (0, $securelog, "Fetching Standalone Console Root Certificate...");
  $b64TextFile = "$emHome/sysman/config/b64LocalCertificate.txt";
  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DemConsoleMode=$emConsoleMode ".
             "-DrootKeyDir=$rootKeyDir ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.RepRootCert -saveCert $b64TextFile ".
             ">> $securelog";
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

  $agentWalletOk = genAgentWallet ($securelog, $rootKeyDir, $rootKeyPassword, 
                                   $thisDNSHost, $certName);
  if (not $agentWalletOk eq 0)
  {
    Secure::DEBUG (0, $securelog, "Failed to generate Wallet for the Standalone Console Agent\n");
    exit $agentWalletOk;
  }
  else
  {
    # Copy wallet and b64 files from download directory..
    $agentDownloadDir = "$ORACLE_HOME/sysman/webapps/em/wallets/agent.$thisDNSHost";
    $agentWalletFile = "$agentDownloadDir/ewallet.p12";
    if (-e "$agentWalletFile")
    {
      Secure::CP ($agentWalletFile, "$ORACLE_HOME/sysman/config/server");
    }

    # We need to copy the b64InternetCertificate.txt from agentDownloadDir
    # which contains both local cert as well as internet certificate list
    $b64InternetCertFile = "$agentDownloadDir/b64InternetCertificate.txt";
    if (-e "$b64InternetCertFile")
    {
      Secure::CP ($b64InternetCertFile, "$ORACLE_HOME/sysman/config");
    }

    # No need to copy the Local certificate.
    # as a copy already exists in the sysman/config directory
  }
  # there is not http upload url for the Standalone Console Agent (iAS or DBA Studio)
  $agentConfigOk = configureAgent ($securelog, $emConsoleMode, "");

  if  (not $agentConfigOk eq 0)
  {
    Secure::DEBUG (0, $securelog, "Failed to configure the Standalone Console Agent\n");
  }

  $useOMSRootKey = "true";
  Secure::DEBUG (0, $securelog, "Generating Standalone Console Java Keystore...");
  $keyStoreOk    = genKeyStore ($securelog, $emConsoleMode, $thisDNSHost, 
                                $rootKeyPassword, $useOMSRootKey);
  if (not $keyStoreOk eq 0)
  {
    Secure::DEBUG (0, $securelog, "   Failed.\n");
    exit $rc;
  }
  Secure::DEBUG (0, $securelog, "   Done.\n");

  Secure::DEBUG (0, $securelog, "Configuring the website ...");
  $rc = SecureGenKeystore::configureEMDKeyStore($securelog, $emdHTTPSPort, "TRUE");
  Secure::DEBUG (0, $securelog, "   Done.\n");

  Secure::DEBUG (0, $securelog, "Updating targets.xml ... ");
  $rc = updateStandaloneConsoleURL($securelog);
  Secure::DEBUG (0, $securelog, "   Done.\n");

  if ($stopStatus eq 0)
  {
    Secure::DEBUG (0, $securelog, "Restarting iasconsole...\n");
    restartStandaloneConsole($securelog);
  }
}


sub unsecureStandaloneConsole
{
   my $securelog = $_[0];
   my $emConsoleMode = "STANDALONE";
   my $debug = $ENV{EM_SECURE_VERBOSE};
  
   my $classPath = &Secure::getAgentClassPath;
   my $emHome = &Secure::getEMHome($emConsoleMode);
   my $oc4jHome = &Secure::getOC4JHome($emConsoleMode);

   my $rc;
   my $stopStatus;

   if($debug ne "")
   {
      $debug = "true";
   }
   else
   {
      $debug = "false";
   }

   Secure::DEBUG (0, $securelog,"Configuring iasconsole for HTTP...\n");

   my $file = "$emHome/sysman/config/emd.properties";
   my $propfile = "$emHome/sysman/config/emd.properties"; 
   my $emWebSiteFile = "$ORACLE_HOME/sysman/j2ee/config/emd-web-site.xml";
   my $iasTargetfile = "$ORACLE_HOME/sysman/emd/targets.xml";
   
   Secure::DEBUG (2, $securelog,"Locating emd.properties file = $file.\n");
   Secure::DEBUG (2, $securelog,"Locating emd-web-site.xml file = $emWebSiteFile.\n");
   Secure::DEBUG (2, $securelog,"Locating target.xml file = $iasTargetfile.\n");

   open(PROPFILE,$propfile) or die "Can not read EMD.PROPERTIES ($propfile)";
   my @emdURLlinesRead = grep /EMD_URL=https:/, <PROPFILE>;
   close(PROPFILE) or die "Can not close EMD.PROPERTIES ($propfile)";

   my $numLinesEMDURL = scalar @emdURLlinesRead;
   if($numLinesEMDURL <= 0)
   {
      Secure::DEBUG (0, $securelog,"Already unsecured iasconsole...\n");
   }
   else
   {
      Secure::DEBUG (0, $securelog, "Stopping iasconsole...\n");
      $stopStatus = stopStandaloneConsole($securelog);
      if ($stopStatus eq 0 or $stopStatus eq 1)
      {
        Secure::DEBUG (0, $securelog, "Unsecuring iasconsole...\n");
      }
      else
      {
        Secure::DEBUG (0, $securelog, "Aborting unsecure iasconsole...\n");
        exit 2;
      }
      Secure::DEBUG (2, $securelog,"Changing secure url to unsecure url.\n");

      my $emd_check = 0;
      my $sec_check = 0;
      my $target_check = 0;
     
      #Changing the emd.properties file
      open(INFO, $file);
      my @emdlines = <INFO>;
      close(INFO) || die;
      open (EMDFILE, ">$file.$$") || die "Cannot write to $file.$$\n";
      foreach my $emdlineRead (@emdlines)
      {
         if($emdlineRead =~ /EMD_URL=https:/)
         {
            $emdlineRead =~ s/https\:/http\:/;
            $emd_check = 1;
            Secure::DEBUG (2, $securelog,"Configuring EMD_URL in $file.\n");
         }
         print EMDFILE "$emdlineRead";
      }
      close (EMDFILE) || die;

      #Changing the emd-web-site.xml file
      open(SECINFO, $emWebSiteFile) or die "Can not read $emWebSiteFile.";
      my @seclines = <SECINFO>;
      close(SECINFO)|| die;
      # Walk the lines, and write to new file
      open (SECFILE, ">$emWebSiteFile.$$") || die "Cannot write to $file.$$\n";
      foreach my $seclineRead (@seclines)
      {
         if($seclineRead =~ /<web-site host/)
         {
            if($seclineRead =~ /secure="true"/i)
            {
               $seclineRead =~ s/(TRUE|true)/false/;
               $sec_check = 1;
               Secure::DEBUG (2, $securelog,"Configuring secure mode in $emWebSiteFile.\n");
            }
            if($seclineRead =~ /secure="false"/i)
            {
               $sec_check = 1;
            }
         }
         print SECFILE "$seclineRead";
      }
      close(SECFILE)|| die;

      #Changing the target.xml file
      open(TARGETINFO, $iasTargetfile);
      my @targetlines = <TARGETINFO>;
      close(TARGETINFO) || die;
      # Walk the lines, and write to new file
      
      my $start_tag = 0;

      open (TARGETFILE, ">$iasTargetfile.$$") || die "Cannot write to $file.$$\n";
      foreach my $targetlineRead (@targetlines)
      {
         if($targetlineRead =~ /<Target TYPE="oracle_ias" NAME/)
         {
            $start_tag = 1;
         }
         if ($start_tag == 1 and $targetlineRead =~/<Property NAME="StandaloneConsoleURL" VALUE=\"https:/) 
         {
            $targetlineRead =~ s/https\:/http\:/;  
            Secure::DEBUG (2, $securelog,"Changing Standalone Console URL in $iasTargetfile ..\n");
            $target_check = 1;
            $start_tag = 0;  
         }
         print TARGETFILE "$targetlineRead";
      }
      close (TARGETFILE) || die;


      if($emd_check == 1 and $sec_check == 1 and $target_check == 1)
      {
         Secure::CP ("$file", "$file.bak.$$");
         Secure::CP ("$file.$$", $file);
         Secure::RM ("$file.$$");
         Secure::CP ("$emWebSiteFile", "$emWebSiteFile.bak.$$");
         Secure::CP ("$emWebSiteFile.$$", $emWebSiteFile);
         Secure::RM ("$emWebSiteFile.$$");
         Secure::CP ("$iasTargetfile", "$iasTargetfile.bak.$$");
         Secure::CP ("$iasTargetfile.$$", $iasTargetfile);
         Secure::RM ("$iasTargetfile.$$");
         Secure::DEBUG (0, $securelog,"IASCONSOLE is now unsecured...\n");
         $rc = 0;
      }
      else
      {
         Secure::RM ("$file.$$");
         Secure::RM ("$emWebSiteFile.$$");
         Secure::RM ("$iasTargetfile.$$");
         Secure::DEBUG (0, $securelog,"Configuration Failed...\n");
         $rc = 1;
      }
   }

   if ($stopStatus eq 0)
   {
     Secure::DEBUG (0, $securelog, "Restarting iasconsole...\n");
     restartStandaloneConsole($securelog);
   }
   return $rc;
}


sub stopStandaloneConsole
{
  my $rc;
  my $securelog        = $_[0];
  my $iasconStopStr    = "$ORACLE_HOME/bin/emctl stop iasconsole >> $securelog $redirectStderr";
  my $iasconStartStr   = "$ORACLE_HOME/bin/emctl start iasconsole >> $securelog $redirectStderr";
  my $iasconStatusStr  = "$ORACLE_HOME/bin/emctl status iasconsole >> $securelog $redirectStderr";

  $rc = 0xffff & system($iasconStatusStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    system($iasconStopStr);
    $rc = 0xffff & system($iasconStatusStr);
    $rc >>= 8;
    if ($rc eq 0)
    {
      Secure::DEBUG (0, $securelog,"Failed to stop iasconsole...\n");
      exit 2;
    }
    elsif ($rc eq 2)
    {
      Secure::DEBUG (0, $securelog,"IASCONSOLE successfully stopped...\n");
      return 0;
    }
    else
    {
      my $tries=30;
      while( $tries gt 0 )
      {
        sleep 1;
        $rc = 0xffff & system($iasconStatusStr);
        $rc >>= 8;
        if ($rc ne 2)
        {
          last;
        }
        $tries = $tries-1;
        print ".";
      }
      $rc = 0xffff & system($iasconStatusStr);
      $rc >>= 8;
      if ($rc eq 2)
      { 
        Secure::DEBUG (0, $securelog,"IASCONSOLE successfully stopped...\n");      
        return 0;
      }
      else
      {
        Secure::DEBUG (0, $securelog,"Failed to stop iasconsole...\n");
        Secure::DEBUG (2, $securelog,"Error: $rc...\n");       
        exit 2;
      }
    }
  }
  elsif ($rc eq 2)
  {
    Secure::DEBUG (0, $securelog,"IASCONSOLE is already stopped...\n");
    return 1;
  }
  else
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($iasconStatusStr);
      $rc >>= 8;
      if ($rc ne 2)
      {
        last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($iasconStatusStr);
    $rc >>= 8;
    if ($rc eq 2)
    { 
      Secure::DEBUG (0, $securelog,"IASCONSOLE successfully stopped...\n");        
      return 0;
    }
    else
    {
        Secure::DEBUG (0, $securelog,"Failed to stop iasconsole...\n");
        Secure::DEBUG (2, $securelog,"Error: $rc...\n");        
      exit 2;
    }
  }
}


sub restartStandaloneConsole
{
  my $rc;
  my $securelog        = $_[0];

  my $iasconStopStr    = "$ORACLE_HOME/bin/emctl stop iasconsole >> $securelog $redirectStderr";
  my $iasconStartStr   = "$ORACLE_HOME/bin/emctl start iasconsole >> $securelog $redirectStderr";
  my $iasconStatusStr  = "$ORACLE_HOME/bin/emctl status iasconsole >> $securelog $redirectStderr";

  system($iasconStartStr);
  $rc = 0xffff & system($iasconStatusStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    Secure::DEBUG (0, $securelog,"IASCONSOLE successfully restarted...\n");        
    return 0;
  }
  elsif ($rc eq 2)
  {
    Secure::DEBUG (0, $securelog,"Failed to restart iasconsole...\n");
    exit 2;
  }
  else
  {
    my $tries=30;
    while( $tries gt 0 )
    {
      sleep 1;
      $rc = 0xffff & system($iasconStatusStr);
      $rc >>= 8;
      if ($rc ne 0)
      {
        last;
      }
      $tries = $tries-1;
      print ".";
    }
    $rc = 0xffff & system($iasconStatusStr);
    $rc >>= 8;
    if ($rc eq 0)
    { 
      Secure::DEBUG (0, $securelog,"IASCONSOLE successfully restarted...\n");        
      return 0;
    }
    else
    {
        Secure::DEBUG (0, $securelog,"Failed to restart iasconsole...\n");
        Secure::DEBUG (2, $securelog,"Error: $rc...\n");        
      exit 2;
    }
  }
}



sub displaySecureStandaloneConsoleHelp
{
  print "Help!\n";
}

1;
