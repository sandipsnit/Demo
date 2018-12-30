#
#  $Header: SecureGenKeystore.pm 02-dec-2004.01:44:58 shianand Exp $
#
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      SecureGenKeystore.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       shianand 12/01/04 - Bug fix 3440956 
#       rpinnama 08/23/04 - Add DEBUG flags 
#       rpinnama 08/20/04  - 
#       aaitghez 06/08/04 -  bug 3656322. Cleanup perl warnings 
#       gan      03/11/04 - bug 3499151 
#       rpinnama 04/01/04 - Import bug 3499151
#       rpinnama 04/01/04 - Replace EMD_KEYSTORE_PASSWORD also
#       dsahrawa 01/23/04 - windows portability changes 
#       rzazueta 12/03/03 - Fix 3290080: Check before adding attributes to 
#                           http-web-site.xml
#       jpyang   11/11/03 - set shared=true for secure dbconsole mode 
#       rpinnama 10/06/03 - Use proper EM home for dbconsole 
#       rpinnama 09/22/03 - 
#       rpinnama 09/22/03 - Generate separate key store for dbconsole 
#       rpinnama 08/26/03 - Use getConsoleClassPath 
#       caroy    08/18/03 - change from phaos.jar to ojpse_2_1_5.jar 
#       rpinnama 08/13/03 - support configuring emd website 
#       rpinnama 08/05/03 - Use common routines 
#       rpinnama 07/30/03 - Fix em jar file
#       rpinnama 07/24/03 - grabtrans 'rpinnama_fix_2996670'
#       mbhoopat 06/02/03 - fix tempDir issue with nt
#       ggilchri 04/11/03 - ggilchri_sb_sta_sll
#       ggilchri 04/10/03 - create
#

use English;
use strict;

use Secure;

package SecureGenKeystore;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $EMDROOT           = $ENV{EMDROOT};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $IS_WINDOWS        ="";
my $tempDir           = "/tmp";
my $redirectStderr    = "2>&1";
my $emWalletsDir      = "$ORACLE_HOME/sysman/wallets";
my $OSNAME            = $^O;

my $initialKeystorePassword; # added for random em keystore password for dbconsole

if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $tempDir           = $ENV{TEMP};
 $redirectStderr = "";
}
else
{
 $IS_WINDOWS="FALSE";
}

# [] ----------------------------------------------------------------- []

sub secureGenKeystore
{
  my $securelog       = $_[0];
  my $emConsoleMode   = $_[1];
  my $thisDNSHost     = $_[2];
  my $rootKeyPassword = $_[3];
  my $useOMSRootKey   = $_[4];

  my $execStr;
  my $javaStr;
  my $rc;
  my $rootKeyDir;

  #my $initialKeystorePassword = "welcome";

  my $endDate                 = "010110";
  my $validityDays            = "360";
  my $keySize                 = "512";
  my $debug = $ENV{EM_SECURE_VERBOSE};

  my $rootKeyCertFile = "";

  my $classPath   = &Secure::getConsoleClassPath($emConsoleMode);
  my $oc4jHome    = &Secure::getOC4JHome($emConsoleMode);
  my $emHome      = &Secure::getEMHome($emConsoleMode);

  my $emLibDir = "$ORACLE_HOME/sysman/webapps/emd/WEB-INF/lib";
  my $cpSep    = ":";
  #my $keystorePasswd = "$JAVA_HOME/bin/java ".
  #                      "-cp $DEFAULT_CLASSPATH".
  #                      "$cpSep$emLibDir/emd.jar ".
  #                      "oracle.sysman.util.crypt.Verifier -genPassword";
 
  my $keystorePasswd = "$JAVA_HOME/bin/java ".
                         "-cp $classPath".
                         "$cpSep$emLibDir/emd.jar ".
                         "oracle.sysman.util.crypt.Verifier -genPassword";

  my $keystorePasswdKey = `$keystorePasswd`;
     $keystorePasswdKey =~ s/^\s+|\s+$//;

  Secure::DEBUG (2, $securelog, "Key Store Password = $keystorePasswdKey ");
  #Secure::DEBUG (0, $securelog, "Key Store Password = $keystorePasswdKey ");

  $initialKeystorePassword = $keystorePasswdKey;

  my $keystoreDir = "$oc4jHome/config/server";

  if ($debug ne "")
  {
      $debug = "true";
  }
  else
  {
      $debug = "false";
  }

  Secure::RMRF ($keystoreDir);
  Secure::MKDIRP ($keystoreDir);

  if ($useOMSRootKey eq "")
  {
    #
    # The assumed password for root wallet is always 'root'. The root wallet
    # is only used for signing the certificate in the default
    # keystore.test file
    #
    $rootKeyPassword = "root";
    $rootKeyCertFile = "$keystoreDir/b64certificate.txt";

    #
    # Make a new root wallet in KEYSTORE_DIR. used to sign
    # the certificate in keystore.test.
    #
    Secure::DEBUG (1, $securelog, "Creating root wallet for non-OMS mode");
    $execStr        = "$ORACLE_HOME/bin/mkwallet ".
                      "-R $rootKeyPassword $keystoreDir ".
		      "cn=$thisDNSHost $keySize $endDate >> $securelog $redirectStderr";

    Secure::DEBUG (2, $securelog, "Executing ... " . $execStr);
    $rc = 0xffff & system($execStr);
    $rc >>= 8;
    if ( $rc eq 0 )
    {
        Secure::DEBUG (1, $securelog, "Done");
    }
    else
    {
        Secure::DEBUG (1, $securelog, "Failed rc = $rc");
	return $rc;
    }
  }
  else
  {
    #
    # use the downloaded root cert and rely on the secure OMS for certificate
    # generation.
    #
    $rootKeyCertFile = "$emHome/sysman/config/b64LocalCertificate.txt";
    Secure::DEBUG (1, $securelog, "Not creating root wallet, using $rootKeyCertFile");
  }
  my $serverDN            = "cn=$thisDNSHost, o=Oracle";
  my $keystoreFile        = "$keystoreDir/keystore.test";
  my $serverCertReqFile   = "$keystoreDir/server.csr";
  my $serverCertFile      = "$keystoreDir/server.cer";
  my $serverKeyAlg        = "RSA";
  my $serverKeyPassword   = "$initialKeystorePassword";
  my $serverStorePassword = "$initialKeystorePassword";

  #
  # Generate key..
  #
  Secure::DEBUG (1, $securelog, "Key Generation ....\n");
  $execStr = "$JAVA_HOME/bin/keytool -genkey ".
             "-dname \"$serverDN\" ".
             "-keyalg $serverKeyAlg ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             "-keypass $serverKeyPassword ".
             "-validity $validityDays ".
             ">> $securelog $redirectStderr";

  Secure::DEBUG (2, $securelog, "Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (1, $securelog, "Done");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "Failed rc = $rc");
    return $rc;
  }

  #
  # Request for certificate..
  #
  Secure::DEBUG (1, $securelog, "Request for certificate...");
  $execStr = "$JAVA_HOME/bin/keytool -certreq ".
             "-keyalg $serverKeyAlg ".
             "-file $serverCertReqFile ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (1, $securelog, "Done");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "Failed rc = $rc");
    return $rc;
  }

  Secure::DEBUG (1, $securelog, "Certificate Generation ...");
  if ($useOMSRootKey eq "")
  {
    Secure::DEBUG (1, $securelog, "OMS root key is NULL");

    $execStr = "$ORACLE_HOME/bin/mkwallet -c ".
               "$rootKeyPassword $keystoreDir ".
               "$serverCertReqFile $serverCertFile >> $securelog $redirectStderr";

    Secure::DEBUG (2, $securelog, "Executing ... $execStr");
    $rc = 0xffff & system($execStr);
    $rc >>= 8;
    if ( $rc eq 0 )
    {
      Secure::DEBUG (1, $securelog, "Done");
    }
    else
    {
      Secure::DEBUG (1, $securelog, "Failed rc = $rc");
      return $rc;
    }
  }
  else
  {
    Secure::DEBUG (1, $securelog, "Using OMS root key $useOMSRootKey");

    Secure::CATFILE ($serverCertReqFile);

    $rootKeyDir = "$emWalletsDir/ca.$thisDNSHost";
    $javaStr = "$JAVA_HOME/bin/java ".
               " -cp $classPath ".
               "-DemConsoleMode=$emConsoleMode ".
               " -Ddebug=$debug ".
               "-DrootKeyDir=$rootKeyDir ".
               "-DORACLE_HOME=$ORACLE_HOME ".
               "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
               "oracle.sysman.eml.sec.WalletUtil ".
               "-gencert $serverCertReqFile $serverCertFile $rootKeyPassword ".
               ">> $securelog $redirectStderr";

    Secure::DEBUG (2, $securelog, "Executing .. $javaStr");

    $rc = 0xffff & system($javaStr);
    $rc >>= 8;
    if ($rc eq 0)
    {
      Secure::DEBUG (1, $securelog, "Done");
    }
    else
    {
      Secure::DEBUG (1, $securelog, "Failed to Generate Certificate. rc = $rc");
      return $rc
    }
  }
  Secure::DEBUG (1, $securelog, "Certificate obtained:\n");
  Secure::CATFILE ($serverCertFile);

  # Import Root certificate.
  Secure::DEBUG (1, $securelog, "Importing Root certificate ...\n");
  $execStr = "$JAVA_HOME/bin/keytool -import ".
             "-alias testrootca ".
             "-file $rootKeyCertFile ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             "-noprompt ".
             ">> $securelog $redirectStderr";
  Secure::DEBUG (2, $securelog, "Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (1, $securelog, "Done");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "Failed rc = $rc");
    return $rc;
  }


  # Import the certificate response to keystore
  Secure::DEBUG (1, $securelog, "Importing Certificate Response ...");
  $execStr = "$JAVA_HOME/bin/keytool -import ".
             "-trustcacerts ".
             "-keyalg $serverKeyAlg ".
             "-file $serverCertFile ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             ">> $securelog $redirectStderr";

  Secure::DEBUG (2, $securelog, "Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    Secure::DEBUG (1, $securelog, "Done");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "Failed rc = $rc");
    return $rc;
  }

  Secure::RMRF ($serverCertReqFile);
  Secure::RMRF ($serverCertFile);

  return 0;
}

# [] ----------------------------------------------------------------- []

sub configureEMKeyStore 
{

  my $securelog           = $_[0];
  my $emConsoleMode       = $_[1];

  my @linesRead;

  my $rc = 0;
  my $oc4jHome = &Secure::getOC4JHome($emConsoleMode);
  my $emWebSiteFile = "$oc4jHome/config/http-web-site.xml";

  Secure::DEBUG (1, $securelog, "Configuring key store in $emWebSiteFile");

  Secure::CP("$emWebSiteFile", "$emWebSiteFile.$$");

  open(FILE, $emWebSiteFile) or die "Can not read $emWebSiteFile";
  @linesRead = <FILE>;
  close(FILE);

  my $endTagFound = 0;

  ;# Walk the lines, and write to new file
  if ( open(FILE,">" . $emWebSiteFile) )  {
    foreach $_ (@linesRead) {
      if (/<web-site /) {
         if (/secure\s*=\s*".*"/) {
            s/secure\s*=\s*".*"/secure="TRUE"/;          
         }
         else {
            s/>/ secure="TRUE">/;
         }
      }
      if (/<web-app application="em" /){
         if (/shared\s*=\s*".*"/) {
            s/shared\s*=\s*".*"/shared="true"/;          
         }
         else {
            s/\/>/ shared="true" \/>/;
         }
      }
      if (/<ssl-config needs-client-auth=/) {
         my $change_key_line = "\t<ssl-config needs-client-auth=\"false\" keystore=\"server/keystore.test\" keystore-password=\"$initialKeystorePassword\" />\n";
		 $_=$change_key_line;
         $endTagFound = 1;
      }
      if (/<\/web-site>/) {
         if ($endTagFound == 0) {
			    my $change_key_line = "\t<ssl-config needs-client-auth=\"false\" keystore=\"server/keystore.test\" keystore-password=\"$initialKeystorePassword\" />\n<\/web-site>\n";
		        $_=$change_key_line;
                #print (FILE "\t<ssl-config needs-client-auth=\"false\" keystore=\"server/keystore.test\" keystore-password=\"welcome\" />\n");
         }
      }
      ;# Print the property line
      print(FILE $_);
    }
    close(FILE);
  } else {
    die "Can not write $emWebSiteFile";
  }

  Secure::DEBUG (1, $securelog, "   Done.\n");

  return 0;
}

# [] ----------------------------------------------------------------- []

sub configureEMDKeyStore
{
  my $securelog           = $_[0];
  my $emHTTPSPort         = $_[1];
  my $emSecureEnabled     = $_[2];

  my $rc = 0;
  my $emShipHomeStart;
  my $emShipHomeEnd;

  Secure::DEBUG (2, $securelog, "IN_VOB = $EmctlCommon::IN_VOB");

  if ($EmctlCommon::IN_VOB eq "TRUE")
  {
    $emShipHomeStart = "  ";
    $emShipHomeEnd   = "  ";
  }
  else
  {
    $emShipHomeStart = "-->";
    $emShipHomeEnd   = "<!--";
  }


  Secure::DEBUG (1, $securelog, "Configuring key store... ");
  my $emdWebSiteTemplateFile = "$ORACLE_HOME/sysman/j2ee/config/emd-web-site.xml.template";
  my $emdWebSiteFile         = "$ORACLE_HOME/sysman/j2ee/config/emd-web-site.xml";

  # Get the port being used..
  $emHTTPSPort = &getCurrentWebSitePort($emdWebSiteFile);

  my @var_names = ('%EM_IAS_CONSOLE_PORT%', '%EMD_SECURE%', 
                   '%EMD_KEYSTORE_FILE%', '%EMD_KEYSTORE_PASSWORD%',
                   '%EM_SHIPHOME_ONLY_START%', '%EM_SHIPHOME_ONLY_END%',
                   '%EM_SSL_ENABLE_START%', '%EM_SSL_ENABLE_END%');
  my @var_values =("$emHTTPSPort", "$emSecureEnabled", 
                   "keystore.test", "$initialKeystorePassword",
                   $emShipHomeStart, $emShipHomeEnd,
                   '-->', '<!--');
  $rc = Secure::REPLACE($emdWebSiteTemplateFile, $emdWebSiteFile, \@var_names, \@var_values);

  if ($rc eq 0)
  {
    Secure::DEBUG (1, $securelog, "   Done.\n");
  }
  else
  {
    Secure::DEBUG (1, $securelog, "   Failed rc = $rc.\n");
  }
  return $rc;
}


sub getCurrentWebSitePort
{
  my (@args)            = @_;
  my $websiteConfigFile = $args[0];
  my $portLine          = "";
  my $websitePort       = "";

  if (open(WEBSITECONFIG, "<$websiteConfigFile"))
  {
    while(<WEBSITECONFIG>)
    {
      if(/port/)
      {
        (undef, $portLine) = split /port="/,$_;
        ($websitePort, undef) = split /"/,$portLine;
      }
    }   # Loop till the end of the file to swizzle out any $_ variables...
    close (WEBSITECONFIG);
  }
  else
  {
     die "Unable to determine website port. $websiteConfigFile does not exists";
  }

  return $websitePort;
}



  
sub displaySecureGenKeystore
{
  print "Help!\n";
}

1;
