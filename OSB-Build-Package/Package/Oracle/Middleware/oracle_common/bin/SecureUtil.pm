#Author: Shivam Anand
#Date Created : 03/31/2005
#Contains all perl Secure Utilities.
#shianand - 27/7/2005 - fix bug 4149565
#shianand - 04/12/06 - fix bug 5158248
#shianand - 11/04/06 - fix bug 4766676
#shianand - 07/24/06 - fix bug 4571079 (remove mkwallet implmentation)
#shianand - 08/29/06 - fix bug 5491469 (include oracle/jlib/ojpse.jar in classpath)
#shianand - 08/29/06 - fix bug 5518632 (getConsole mode for 10.2 RAC DB)
#shianand - 09/25/06 - fix bug 5556081 

use English;
use strict;

use File::Copy;
use File::Path;
use IPC::Open2;

package SecureUtil;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $EMDROOT           = $ENV{EMDROOT};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $JRE_HOME          = $ENV{JRE_HOME};
my $DEFAULT_CLASSPATH = $ENV{DEFAULT_CLASSPATH};
my $emUploadHTTPPort  = $ENV{EM_UPLOAD_PORT};
my $emUploadHTTPSPort = $ENV{EM_UPLOAD_HTTPS_PORT};
my $IS_WINDOWS        = "";
my $cpSep             = ":";

my $tempDir           = "/tmp";
my $redirectStderr    = "2>&1";
my $emWalletsDir      = "$ORACLE_HOME/sysman/wallets";
my $emConfigDir       = "$ORACLE_HOME/sysman/config";

my $initialKeystorePassword;

my $OSNAME            = $^O;
if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $tempDir           = $ENV{TEMP};
 $redirectStderr = "";
 $cpSep = ";";
}
else
{
 $IS_WINDOWS="FALSE";
}

my $securelog         = "$ORACLE_HOME/sysman/log/secure.log";
my $debug             = "false";

sub setDebug
{
  $debug = $_[0];
  if($debug ne "")
  {
    $debug = "true";
  }
  else
  {
    $debug = "false";
  }
}

sub getDebug
{
  return $debug;
}

sub setLogFile
{
  if ($_[0] eq "")
  {
    $securelog = "$ORACLE_HOME/sysman/log/secure.log";
  }
  elsif (defined($_[0]))
  {
    $securelog = $_[0];
  }
}

sub getLogFile
{
  return $securelog;
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

  my $oracleSid = "";
  my $topDir    = "";
  my $stateDir  = "";
  my $propState = "";

  if ($emConsoleMode eq "STANDALONE")
  {
    my $HOST_SID_OFFSET_ENABLED = $ENV{HOST_SID_OFFSET_ENABLED};

    if ($HOST_SID_OFFSET_ENABLED eq "host_sid")
    {
      $oracleSid = $ENV{ORACLE_SID};
      if ($oracleSid ne "")
      {
        $topDir = &EmctlCommon::getLocalHostName();
       
        #for 10.2 dbcontrol, use node name for RAC   
        if(substr($ENV{EMPRODVER},0,4) ne "10.1") 
        { 
          if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#")) 
          { 
             # if we are in RAC, use the local node name 
             $topDir = &EmctlCommon::getLocalRACNode(); 
             if ($topDir eq "") 
             { 
               $topDir = &EmctlCommon::getLocalHostName(); 
             } 
          } 
        }  

        $stateDir  = $topDir."_".$oracleSid;
        $propState = "$ORACLE_HOME/$stateDir/sysman/config/emoms.properties";
        if (-e $propState)
        {
          $emConsoleMode = "DBCONSOLE";      
        }
      }
    }
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

  DEBUG ("consoleMode =  $consoleMode");
  DEBUG ("emLibDir =  $emLibDir");

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

  DEBUG ("emLibDir =  $emLibDir");
  DEBUG ("emdroot =  $EMDROOT");

  # adding oracle_home/jlib/ojpse.jar from DB11 bug 5491469
  # keeping oracle_home/encryption/jlib/ojpse.jar for backward compatibility

  my $consoleClassPath = "$DEFAULT_CLASSPATH".
                   "$cpSep$ORACLE_HOME/jdbc/lib/ojdbc14.jar".
                   "$cpSep$ORACLE_HOME/oc4j/jdbc/lib/ojdbc14dms.jar".
                   "$cpSep$ORACLE_HOME/oc4j/lib/dms.jar".
                   "$cpSep$ORACLE_HOME/oc4j/jdbc/lib/orai18n.jar".
                   "$cpSep$ORACLE_HOME/jlib/uix2.jar".
                   "$cpSep$ORACLE_HOME/jlib/share.jar".
                   "$cpSep$ORACLE_HOME/jlib/ojmisc.jar".
                   "$cpSep$ORACLE_HOME/jlib/ojpse.jar".
                   "$cpSep$ORACLE_HOME/lib/xmlparserv2.jar".
                   "$cpSep$ORACLE_HOME/lib/emagentSDK.jar".
                   "$cpSep$ORACLE_HOME/encryption/jlib/ojpse.jar".
                   "$cpSep$ORACLE_HOME/jlib/http_client.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/lib/http_client.jar".
                   "$cpSep$ORACLE_HOME/modules/oracle.http_client_11.1.1.jar".
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

sub USERINFO 
{
  my $msg = $_[0];
  my $verbose_mode = $debug;
  write_to_file($securelog, "USERINFO ::$msg");
  print "$msg";
}

# [] ----------------------------------------------------------------- []

sub INFO 
{
  my $msg = $_[0];
  my $verbose_mode = $debug;
  write_to_file($securelog, "INFO     ::$msg");
}


# [] ----------------------------------------------------------------- []

sub DEBUG 
{
  my $msg = $_[0];
  my $verbose_mode = $debug;
  if ($verbose_mode eq "true")
  {
    write_to_file($securelog, "DEBUG    ::$msg");
  }
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

  DEBUG("Creating out file $out_file with in file = $in_file");
  DEBUG("Count Var names = $#var_names Values = $#var_values");

  for (my $i = 0; $i < @var_names; $i++)
  {
    DEBUG("Replacing [$var_names[$i]] with [$var_values[$i]]");
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

  DEBUG ("Concatenated $f1 to $f2");
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
     DEBUG ("Successfully Copied $f1 to $f2");
  }
  else
  {
     DEBUG ("Failed to copy $f1 to $f2 retval = $rc");
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
  DEBUG ("Creating directory $dir");
  return 0;
}


# [] ----------------------------------------------------------------- []

sub RMRF {
  my ($rmDir) = @_;
  File::Path::rmtree($rmDir);
  DEBUG ("Removed directory $rmDir");
  return 0;
}

# [] ----------------------------------------------------------------- []

sub RM {
  my ($rmFile) = @_;
  unlink $rmFile;
  DEBUG ("Removed file $rmFile");
  return 0;
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

  my $endDate                 = "010110";
  my $validityDays            = "360";
  my $keySize                 = "512";

  my $rootKeyCertFile = "";

  SecureUtil::setDebug($ENV{EM_SECURE_VERBOSE});
  $debug = SecureUtil::getDebug;

  my $classPath   = &SecureUtil::getConsoleClassPath($emConsoleMode);
  my $oc4jHome    = &SecureUtil::getOC4JHome($emConsoleMode);
  my $emHome      = &SecureUtil::getEMHome($emConsoleMode);

  my $emLibDir = "$ORACLE_HOME/sysman/webapps/emd/WEB-INF/lib";

  my $keystorePasswd = "$JAVA_HOME/bin/java ".
                         "-cp $classPath ".
                         "oracle.sysman.util.crypt.Verifier -genPassword";

  my $keystorePasswdKey = `$keystorePasswd`;
     $keystorePasswdKey =~ s/^\s+|\s+$//;

  DEBUG ("Key Store Password = $keystorePasswdKey ");

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

  SecureUtil::RMRF ($keystoreDir);
  SecureUtil::MKDIRP ($keystoreDir);

  #
  # use the downloaded root cert and rely on the secure OMS for certificate
  # generation.
  #
  $rootKeyCertFile = "$emHome/sysman/config/b64LocalCertificate.txt";
  INFO ("Not creating root wallet, using $rootKeyCertFile");

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
  INFO ("Key Generation ....\n");
  $execStr = "$JAVA_HOME/bin/keytool -genkey ".
             "-dname \"$serverDN\" ".
             "-keyalg $serverKeyAlg ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             "-keypass $serverKeyPassword ".
             "-validity $validityDays ".
             ">> $securelog $redirectStderr";

  DEBUG ("Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    INFO ("Done");
  }
  else
  {
    INFO ("Failed rc = $rc");
    return $rc;
  }

  #
  # Request for certificate..
  #
  INFO ("Request for certificate...");
  $execStr = "$JAVA_HOME/bin/keytool -certreq ".
             "-keyalg $serverKeyAlg ".
             "-file $serverCertReqFile ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             ">> $securelog $redirectStderr";
  DEBUG ("Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    INFO ("Done");
  }
  else
  {
    INFO ("Failed rc = $rc");
    return $rc;
  }

  INFO ("Certificate Generation ...");

  INFO ("Using OMS root key $useOMSRootKey");

  SecureUtil::CATFILE ($serverCertReqFile);

  $rootKeyDir = "$emWalletsDir/ca.$thisDNSHost";
  $javaStr = "$JAVA_HOME/bin/java ".
             " -cp $classPath ".
             "-DemConsoleMode=$emConsoleMode ".
             " -Ddebug=$debug ".
             "-DrootKeyDir=$rootKeyDir ".
             "-DORACLE_HOME=$ORACLE_HOME ".
             "-DrepositoryPropertiesFile=$emHome/sysman/config/emoms.properties ".
             "-Ddebug=$debug ".
             "oracle.sysman.eml.sec.fsc.FSWalletUtil ".
             "-gencert $serverCertReqFile $serverCertFile $rootKeyPassword ".
             ">> $securelog $redirectStderr";

  DEBUG ("Executing .. $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ($rc eq 0)
  {
    INFO ("Done");
  }
  else
  {
    INFO ("Failed to Generate Certificate. rc = $rc");
    return $rc
  }

  INFO ("Certificate obtained:\n");
  SecureUtil::CATFILE ($serverCertFile);

  # Import Root certificate.
  INFO ("Importing Root certificate ...\n");
  $execStr = "$JAVA_HOME/bin/keytool -import ".
             "-alias testrootca ".
             "-file $rootKeyCertFile ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             "-noprompt ".
             ">> $securelog $redirectStderr";
  DEBUG ("Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    INFO ("Done");
  }
  else
  {
    INFO ("Failed rc = $rc");
    return $rc;
  }


  # Import the certificate response to keystore
  INFO ("Importing Certificate Response ...");
  $execStr = "$JAVA_HOME/bin/keytool -import ".
             "-trustcacerts ".
             "-keyalg $serverKeyAlg ".
             "-file $serverCertFile ".
             "-keystore $keystoreFile ".
             "-storepass $serverStorePassword ".
             ">> $securelog $redirectStderr";

  DEBUG ("Executing ... $execStr");
  $rc = 0xffff & system($execStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    INFO ("Done");
  }
  else
  {
    INFO ("Failed rc = $rc");
    return $rc;
  }

  SecureUtil::RMRF ($serverCertReqFile);
  SecureUtil::RMRF ($serverCertFile);

  return 0;
}

# [] ----------------------------------------------------------------- []

sub configureEMKeyStore 
{

  my $securelog           = $_[0];
  my $emConsoleMode       = $_[1];

  my @linesRead;

  my $rc = 0;
  my $oc4jHome = &SecureUtil::getOC4JHome($emConsoleMode);
  my $emWebSiteFile = "$oc4jHome/config/http-web-site.xml";

  INFO ("Configuring key store in $emWebSiteFile");

  SecureUtil::CP("$emWebSiteFile", "$emWebSiteFile.$$");

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
         }
      }
      ;# Print the property line
      print(FILE $_);
    }
    close(FILE);
  } else {
    die "Can not write $emWebSiteFile";
  }

  INFO ("   Done.\n");

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

  DEBUG ("IN_VOB = $EmctlCommon::IN_VOB");

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


  INFO ("Configuring key store... ");
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
  $rc = SecureUtil::REPLACE($emdWebSiteTemplateFile, $emdWebSiteFile, \@var_names, \@var_values);

  if ($rc eq 0)
  {
    INFO ("   Done.\n");
  }
  else
  {
    INFO ("   Failed rc = $rc.\n");
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
    $emHome = &SecureUtil::getEMHome($emConsoleMode);
    $emWalletsDir = "$emHome/sysman/wallets";

    $emConfigDir = "$emHome/sysman/config";
  }
  else
  {
    $emHome = $ORACLE_HOME;
  }

  DEBUG ("SecureGenWallet : ConsoleMode = $emConsoleMode");
  DEBUG ("SecureGenWallet : walletType = $walletType");
  DEBUG ("SecureGenWallet : DNSHost = $thisDNSHost");

  #
  # make a new wallet for $thisDNSHost.
  #
  $rc = &SecureUtil::secureMakeServerWlt($emHome, $JAVA_HOME, $securelog, 
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
  INFO ("Agent Download dir = " .$agentDownloadDir);

  if (not (-e $agentDownloadDir))
  {
    SecureUtil::MKDIRP ($agentDownloadDir);
  }

  $emWalletFile="$emWalletsDir/$walletType.$thisDNSHost/ewallet.p12";
  if (not (-e $emWalletFile))
  {
    die "Missing $emWalletFile\n";
  }
  else
  {
    SecureUtil::CP ($emWalletFile, $agentDownloadDir);
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
    SecureUtil::CP ($emdLocalTrustCertFile, "$agentDownloadDir/b64LocalCertificate.txt");
    SecureUtil::CP ($emdLocalTrustCertFile, "$agentDownloadDir/b64InternetCertificate.txt");
  }

  $emdIntTrustCertFile="$emConfigDir/b64InternetCertificate.txt";
  if (not (-e $emdIntTrustCertFile))
  {
    die "The EMD local trust cert was not created in $emdIntTrustCertFile";
  }
  else
  {
    SecureUtil::APPEND ($emdIntTrustCertFile, "$agentDownloadDir/b64InternetCertificate.txt");
  }
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

  SecureUtil::setDebug($ENV{EM_SECURE_VERBOSE});
  $debug = SecureUtil::getDebug;

  my $classPath = &SecureUtil::getConsoleClassPath($emConsoleMode);

  if ($certName eq "")
  {
    $certName = $thisDNSHost;
  }
  $serverDN      = "cn=$certName";
  $serverCertDir = "$emWalletsDir/$walletType.$thisDNSHost";
  SecureUtil::MKDIRP ($serverCertDir);

  DEBUG ("Making server wallet for DN = $serverDN");

  $javaStr  = "$javaHome/bin/java ".
              "-cp $classPath ".
              "-DrootPassword=$obfEMRootPassword ".
              "-DemConsoleMode=$emConsoleMode ".
              " -Ddebug=$debug ".
              "-DORACLE_HOME=$oracleHome ".
              "-DrepositoryPropertiesFile=$oracleHome/sysman/config/emoms.properties ".
              "-Ddebug=$debug ".
              "oracle.sysman.eml.sec.WalletUtil ".
              "$serverDN $obfOMSWalletPassword $serverCertDir ".
              "$rootKeyDir $rootKeyPassword ".
              ">> $securelog $redirectStderr";

  DEBUG ("Executing ... $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  return $rc;
}


# [] ----------------------------------------------------------------- []

sub secureRootKey
{
  my $securelog       = $_[0];
  my $emConsoleMode   = $_[1];
  my $thisDNSHost     = $_[2];
  my $emWalletsDir    = $_[3];

  my $caDir   = "$emWalletsDir/ca.$thisDNSHost";
  SecureUtil::RMRF ($caDir);
  SecureUtil::MKDIRP ($caDir);

  SecureUtil::setDebug($ENV{EM_SECURE_VERBOSE});
  $debug = SecureUtil::getDebug;

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
  my $classPath = &SecureUtil::getConsoleClassPath($emConsoleMode);
  my $emHome    = &SecureUtil::getEMHome($emConsoleMode);
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
             "-Ddebug=$debug ".
             "oracle.sysman.eml.sec.GenRootCert $caDir $rootKeyPassword ".
             ">> $securelog";

  SecureUtil::DEBUG ("Executing .... $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;

  #
  # Copy the standard trust points to the CA directory for easy inclusion
  # into new wallets
  SecureUtil::CP( "$ORACLE_HOME/sysman/config/b64InternetCertificate.txt", $caDir );

  return $rc;
}

sub getSecPasswdFile
{
  my $passwdFile = $_[0];
  my @returnArray = ();

  open(SECPWDFILE, $passwdFile) || die "Could not open $passwdFile\n";
  my @linesRead = <SECPWDFILE>;
  close(SECPWDFILE);

  my $i = 0;
  my $passwdRead = "";
  foreach $_ (@linesRead)
  {
    $passwdRead = $_;
    chop($passwdRead);
    $returnArray[$i] = &SecureUtil::getDecypherPasswd($passwdRead);
    $i++;
  }
  return (\@returnArray);
}

sub getDecypherPasswd
{
  my $obfPassword    = $_[0];
  my $classPath      = "";
  my $decypherPasswd = "";

 my $emConsoleMode   = &SecureUtil::getConsoleMode(); 
 my $agentMode       = &SecureUtil::getAgentMode();

 if ($emConsoleMode eq "CENTRAL")
 {
   $classPath = &SecureUtil::getConsoleClassPath($emConsoleMode);
 }
 else
 {
  if ($agentMode eq "CENTRAL_AGENT")
  {
    $classPath = &SecureUtil::getAgentClassPath();
  }
  else
  {
    $classPath = &SecureUtil::getConsoleClassPath($emConsoleMode);
  }
 }

  local (*Reader, *Writer);
  my $pid = IPC::Open2::open2(\*Reader, \*Writer, "$JAVA_HOME/bin/java", "-cp","$classPath","-DORACLE_HOME=$ORACLE_HOME","-Ddebug=$debug","oracle.sysman.eml.sec.util.Obfuscate","-decypher");
  print Writer "$obfPassword\n";
  close Writer;
  while (<Reader>)
  {
    $decypherPasswd = $_;
  }
  close Reader;
  waitpid($pid, 0);
  chop($decypherPasswd);
  return $decypherPasswd;
}



# [] ----------------------------------------------------------------- []
1;

