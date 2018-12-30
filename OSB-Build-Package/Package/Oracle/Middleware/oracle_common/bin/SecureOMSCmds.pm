#
#  $Header: SecureOMSCmds.pm 15-apr-2008.09:36:10 jashukla Exp $
#
#
# Copyright (c) 2003, 2008, Oracle. All rights reserved.  
#
#    NAME
#      SecureOMSCmds.pm - Secure OMS Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       jashukla 04/09/08 - 
#       pchebrol 04/08/08 - Bug 6953493 - remove obsolete code
#       pchebrol 03/31/08 - Bug 6924168 - deprecate asctl.pm
#       pchebrol 03/24/08 - Bug 6859693 - cut over lock/unlock cmds to call
#                           java API
#       smodh    03/04/08 - Changes for Multi OMS setup
#       pchebrol 02/27/08 - OMS bounced by the java class
#       jashukla 02/12/08 - setup sso mkdirp fix
#       pchebrol 02/11/08 - Deprecate secure10g
#       pchebrol 01/24/08 - Instance name not needed for setpwd
#       smodh    01/08/08 - Change location of emoms.properties
#       jashukla 12/26/07 - sso config changes
#       pchebrol 12/21/07 - Cutover setpwd to AddRegPwdCmd class
#       smodh    11/21/07 - 
#       dgiaimo  11/20/07 - Grabbing mas username/connection url from the
#                           environment, or prompting if not existing.
#       pchebrol 10/29/07 - Cutover to secure11goms
#       jashukla 10/24/07 - 
#       rpinnama 11/02/07 - 
#       pchebrol 07/23/07 - Fix bug 5256879 - include sysman in root password prompt
#       neearora 07/09/07 - 
#       shianand 04/10/07 - 
#       dgiaimo  04/12/07 - 
#       smodh    03/19/07 - Fix path for persist_doc.py & activate.py
#       smodh    03/19/07 - Fix path for persist_doc.py & activate.py
#    shianand    03/25/07 - secure 11g oms changes
#    shianand    01/25/07 - fix bug 5758794
#    smodh       12/15/06 - 
#    smodh       12/14/06 - Change OracleHome/sysman/log to
#                           InstanceHome/OC4JComponent/oc4j_em/sysman/log
#    mbhoopat    11/24/06 - /
#    mbhoopat    11/21/06 - 
#    ramalhot    11/16/06 - 
#    hmodawel    10/20/06 - for M7pcscomponent
#    rpinnama    10/26/06 - 
#    shianand    09/17/06 - ER 5121288 
#    shianand    09/25/06 - fix bug 5520464
#    shianand    07/02/06 - fix bug 5257991 
#    hmodawel    06/05/06 - removed dcmctl part 
#    shianand    11/04/06 - fix bug 4766676
#    shianand    01/03/06 - Moving SSO registration to SecureOMSCmds.pm 
#    shianand    01/03/06 - fix bug 4911857 
#    shianand    12/27/05 - fix bug 4895199 (fix open2 issue using command tokens)
#    shianand    12/27/05 - fix bug 4895199 (workaround) 
#    shianand    11/09/05 - fix the password from command line 
#    shianand    11/07/05 - fix bug 4570537 
#    shianand    11/06/05 - Fix bug 4570579 
#    shianand    11/14/05 - fix bug 4481271 
#    shianand    11/14/05 - fix bug 4360441 
#    shianand    08/08/05 - fix bug 4543785 
#    shianand    08/08/05 - fix bug 4516559 
#    shianand    09/06/05 - fix bug 4591108 
#    kmanicka    08/24/05 - check if emkey is configured
#    rkpandey    08/24/05 - Increased Apache default timeout 
#    shianand    07/23/05 - fix bug 3335221 
#    shianand    07/25/05 - fix bug 4509232 
#    shianand    07/15/05 - shianand_ref_core
#    shianand    03/31/05 - Created
#
#


package SecureOMSCmds;

use IPC::Open2;
use English;
use strict;
use vars '*args';


use EmctlCommon;
use EmKeyCmds;
use SecureUtil;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $INSTANCE_HOME     = $ENV{EM_INSTANCE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $emUploadHTTPPort  = $ENV{EM_UPLOAD_PORT};
my $emUploadHTTPSPort = $ENV{EM_UPLOAD_HTTPS_PORT};
my $httpServerTimeout = "900";
my $IS_WINDOWS        = "";
my $redirectStderr    = "2>&1";
my $opmnRedirectLog   = "";

my $mas_user;
my $mas_passwd;
my $tempdir;
my $mas_connurl       = $ENV{'EM_MAS_CONN_URL'};
my $em_instance_name  = $ENV{'EM_INSTANCE_NAME'};
my $oc4j_name         = $ENV{'EM_OC4J_NAME'};
my $ohs_name          = $ENV{'EM_OHS_NAME'};
my $mas_farm_name     = $ENV{'EM_FARM_NAME'};
my $securelog         = "$INSTANCE_HOME/OC4JComponent/oc4j_em/sysman/log/secure.log";

my $debug;

my $OSNAME            = $^O;
if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS="TRUE";
 $opmnRedirectLog = "$devNull 2>&1";
}
else
{
 $IS_WINDOWS="FALSE";
 $opmnRedirectLog   = "$securelog 2>&1";
}

# SSO debug parameters
my $debugFlag = "";

# SSO host parameters
my $hostname = &EmctlCommon::getLocalHostName();
my $port     = "";
my $ohm      = $ORACLE_HOME;
my $domain   = "";

# SSO config file
my $configfile = "$ENV{'ORACLE_HOME'}/work/setup/httpd.conf";
my $propfile   = "$INSTANCE_HOME/OC4JComponent/oc4j_em/applications/em/META-INF/emoms.properties";
my $tempfile   = "temp.ssosetup";


# SSO server parameters - taken from command line
my $serverhost    = "";
my $serverport    = "";  # db port
my $serversid     = "";
my $serverpwd     = "";
my $serverwebport = "";
my $dasurl        = "";
my $ossoconf      = "";
my $serverschema  = "orasso"; # default value
my $user          = "";

sub initialize
{
  SecureUtil::setLogFile($securelog);

  SecureUtil::setDebug($ENV{EM_SECURE_VERBOSE});
  $debug = SecureUtil::getDebug;
}

sub new
{
  my $classname = shift;
  my $self = { };
  bless ($self, $classname);
  return $self;
}

sub doIT
{
  my $classname = shift;
  my $rargs     = shift;
  my $result    = $EMCTL_UNK_CMD; #Unknown command.

  initialize();

  my $argCount  = @$rargs;
  if ($argCount >= 2  && $rargs->[0] eq "secure")
  {
    if($rargs->[1] eq "oms")
    {
       secure11gOms($rargs);
       $result = $EMCTL_DONE;
    }
    elsif($rargs->[1] eq "sync")
    {
       secureSync();
       $result = $EMCTL_DONE;
    }
    elsif ($rargs->[1] eq "setpwd")
    {
      secureSetPwd ($rargs);
      $result = $EMCTL_DONE;
    }
    elsif ($rargs->[1] eq "lock" || $rargs->[1] eq "unlock")
    {
      secureLock($rargs);
      $result = $EMCTL_DONE;
    }
    else
    {
       $result = $EMCTL_UNK_CMD;
    }
  }
  else
  {
    $result = $EMCTL_UNK_CMD;
  }
  return $result;
} 

sub getSecureCmdsClassPath
{
    my $emConsoleMode = &SecureUtil::getConsoleMode;
    my $classPath     = &SecureUtil::getConsoleClassPath($emConsoleMode);

    $classPath .= "$cpSep$ORACLE_HOME/jlib/oraclepki.jar".
                  "$cpSep$ORACLE_HOME/jlib/osdt_cert.jar".
                  "$cpSep$ORACLE_HOME/jlib/osdt_core.jar".
                  "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
                  "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
                  "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar".
                  "$cpSep$ORACLE_HOME/sysman/jlib/emcore_client.jar".
                  "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxframework.jar".
                  "$cpSep$ORACLE_HOME/j2ee/home/lib/servlet.jar".
                  "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
                  "$cpSep$ORACLE_HOME/jlib/adminserver.jar".
                  "$cpSep$ORACLE_HOME/jlib/emConfigInstall.jar".
                  "$cpSep$ORACLE_HOME/jlib/ojdl.jar".
                  "$cpSep$ORACLE_HOME/jlib/dms.jar".
                  "$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar".
                  "$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar";

    return $classPath;
}


sub usage
{
  print "Secure OMS Usage : \n";
  print "emctl secure oms [-mas_pwd <mas pwd>] [-sysman_pwd <sysman password>] [-reg_pwd <registration password>] [-passwd_file <abs file loc>]\n";
  print "\t-host <hostname>] [-reset] [-secure_port <secure_port>] [-slb_port <slb port>]\n";
  print "\t[-root_dc <root_dc>] [-root_country <root_country>] [-root_state <root_state>] [-root_loc <root_loc>]\n";
  print "\t[-root_org <root_org>] [-root_unit <root_unit>] [-root_email <root_email>]\n";
  print "emctl secure setpwd  [-mas_pwd <mas pwd>] [-sysman_pwd <sysman password>] [-reg_pwd <registration password>]\n";
  print "emctl secure sync\n";
  print "emctl secure lock -mas_user <mas user> [-mas_pwd <mas pwd>]\n";
  print "emctl secure unlock -mas_user <mas user> [-mas_pwd <mas pwd>]\n\n";
}


sub secure11gOms
{
    local (*args) = @_;
    shift(@args);
    my $component = @args->[0];
    shift(@args);

    my $rc;
    my $classPath = &getSecureCmdsClassPath;
 
    SecureUtil::USERINFO ("Securing oms...  Started\n");
    my $secureCmd = "$JAVA_HOME/bin/java ".
                        "-cp $classPath ".
                        "-DORACLE_HOME=$ORACLE_HOME ".
                        "-Doracle.instance=$INSTANCE_HOME ".
                        "-Dmas.connurl=$mas_connurl " .
                        "-Doracle.instance.name=$em_instance_name " .
                        "-Doc4j.component.name=$oc4j_name " .
                        "-Dohs.component.name=$ohs_name " .
                        "-Ddebug=$debug ".
                        "oracle.sysman.emctl.secure.oms.SecureOMSCmds @args";

    SecureUtil::DEBUG ("Securing OMS ... $secureCmd");

    $rc = 0xffff & system($secureCmd);
    $rc >>= 8;

    if ( $rc eq 0 )
    {
        SecureUtil::USERINFO ("Securing oms... Successful\n");
    }
    else
    {
         SecureUtil::USERINFO ("Securing oms... Failed\n");
         exit $rc;
    }

    return $rc;
}


#
# secureSync takes
# 1) Array of arguments
#
sub secureSync
{
  local (*args) = @_;
  shift(@args);
  shift(@args);
  my $javaStr   = "";
  my $classPath = "";
  my $rc;

  $classPath = &SecureUtil::getConsoleClassPath("");

  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath".
             "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
             "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
             "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar ".
             "-DrepositoryPropertiesFile=$INSTANCE_HOME/OC4JComponent/oc4j_em/applications/em/META-INF/emoms.properties ".
             "-Ddebug=$debug ".
             "oracle.sysman.eml.sec.rep.InstallPassword -auth ".
             ">> $securelog";

  SecureUtil::DEBUG ("Executing ... $javaStr");

  open(SETPWD, "|$javaStr");
  print SETPWD "nopassword\n";
  close(SETPWD);

  $rc = 0xffff & $?;
  $rc >>= 8;
  if (not $rc eq 2 )
  {
    SecureUtil::USERINFO ("   Done.\n");
  }
  else
  {
    SecureUtil::USERINFO ("   Failed.\n");
  }
  return $rc;
}




#
# secureSetPwd takes
# 1) Array of arguments
#
sub secureSetPwd
{
  local (*args) = @_;
  shift(@args);
  shift(@args);
  
  my $classPath = &getSecureCmdsClassPath;
  my $rc;

  my $addRegPwdCmd = "$JAVA_HOME/bin/java ".
                        "-cp $classPath ".
                        "-DORACLE_HOME=$ORACLE_HOME ".
                        "-Doracle.instance=$INSTANCE_HOME ".
                        "-Dmas.connurl=$mas_connurl " .
                        "-Doc4j.component.name=$oc4j_name " .
                        "-Ddebug=$debug ".
                        "oracle.sysman.emctl.secure.oms.AddRegPwdCmd @args";

  SecureUtil::USERINFO ("Adding registration password\n");
  SecureUtil::DEBUG ("Executing ... $addRegPwdCmd");

  $rc = 0xffff & system($addRegPwdCmd);
  $rc >>= 8;

  if($rc eq 0)
  {
     SecureUtil::USERINFO ("Agent Registration Password added succesfully.\n");
  }
  elsif($rc eq 1)
  {
     SecureUtil::USERINFO ("Failed to add Agent Registration Password.\n");
  }
  else
  {
     SecureUtil::USERINFO ("Invalid Input.\n");
  }

  return $rc;
}



#
# secureStatus takes
# 1) Array of arguments
#

sub secureStatus
{
  my $component    = $args[0];
  my $omsUrl       = $args[1];
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

  my $emAgentMode      = &SecureUtil::getAgentMode();
  my $emHome           = &SecureUtil::getEMHome($emAgentMode);
  my $emdPropFile      = "$emHome/sysman/config/emd.properties";
  my ($protocol,$machine,$port,$ssl);
  my %agentProps;

  if (-e "$INSTANCE_HOME/OC4JComponent/oc4j_em/applications/em/META-INF/emoms.properties")
  {
    $statusAtOMS = "true";
    $classPath   = &SecureUtil::getConsoleClassPath("");
    $propFile    = "$INSTANCE_HOME/OC4JComponent/oc4j_em/applications/em/META-INF/emoms.properties";
  }
  else
  {
    $statusAtOMS = "false";
    $classPath   = &SecureUtil::getAgentClassPath;
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
          %agentProps  = &SecureUtil::parseFile($emdPropFile);
          if (defined($agentProps{"REPOSITORY_URL"}))
          {
             $omsUrl = $agentProps{"REPOSITORY_URL"};
             if ($omsUrl =~ /https/)
             {
               ($protocol,$machine,$port,$ssl) = &SecureUtil::parseURL($agentProps{"emdWalletSrcUrl"});
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
    SecureUtil::USERINFO ("Checking the security status of the Agent at location set in $emdPropFile...");
    %agentProps  = &SecureUtil::parseFile($emdPropFile);
    ($protocol,$machine,$port,$ssl) = &SecureUtil::parseURL($agentProps{"EMD_URL"});
    SecureUtil::USERINFO ("  Done.\n");
    if($ssl eq "Y")
    {
       SecureUtil::USERINFO ("Agent is secure at HTTPS Port $port.\n");
    }
    else
    {
       SecureUtil::USERINFO ("Agent is unsecure at HTTP Port $port.\n");
    }
  }

   SecureUtil::USERINFO ("Checking the security status of the OMS at ");
  if ($omsUrl eq "")
  {
     SecureUtil::USERINFO ("location set in $propFile...");
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
    SecureUtil::USERINFO ("$omsUrl...");
    $statusArgs = $omsUrl;
  }
  $javaStr = "$JAVA_HOME/bin/java ".
                   "-cp $classPath".
                   "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar ".
                   "-DpropertiesFile=$propFile ".
                   "-Ddebug=$debug ".
                   "oracle.sysman.eml.sec.emd.GetSecPort $statusArgs ".
                   ">> $securelog";
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
    SecureUtil::USERINFO ("  Done.\n");
    $httpsPortCmd = "$JAVA_HOME/bin/java ".
                    "-cp $classPath".
                    "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar ".
                    "-DpropertiesFile=$propFile ".
                    "-Ddebug=$debug ".
                    "oracle.sysman.eml.sec.emd.GetSecPort $statusArgs";
    $httpsPort = `$httpsPortCmd`;
    $httpsPort =~ s/^\s+|\s+$//;
    SecureUtil::USERINFO ("OMS is secure on HTTPS Port $httpsPort\n");
  }
  else
  {
    if ( $rc eq 2 )
    {
      SecureUtil::USERINFO ("   Done.\n");
      SecureUtil::USERINFO ("OMS is running but has not been secured. No HTTPS Port available.\n");
    }
    else
    {
      SecureUtil::USERINFO ("   Failed.\n");
      SecureUtil::USERINFO ("Could not connect to the OMS.");
    }
  }
  return $rc;
}


sub secureLock
{
    local (*args) = @_;
    shift(@args); 
    #To pass -lock or -unlock to LockOMSCmd
    my $lockMode = "-" . $args[0]; 
    shift(@args);

    my $rc;
    my $classPath = &getSecureCmdsClassPath;
    my $lockCmd = "$JAVA_HOME/bin/java ".
                  "-cp $classPath ".
                  "-DORACLE_HOME=$ORACLE_HOME ".
                  "-Doracle.instance=$INSTANCE_HOME ".
                  "-Dmas.connurl=$mas_connurl " .
                  "oracle.sysman.emctl.secure.oms.LockOMSCmd $lockMode @args";

    $rc = 0xffff & system($lockCmd);
    $rc >>= 8;
    exit $rc;
}

sub getOc4jLoc
{
   return $ENV{"EM_INSTANCE_HOME"} . "/OC4JComponent/" . $ENV{"EM_OC4J_NAME"};
}

#
# get http port for the console from httpd_em.conf file. We are looking for 
# the port for the  <VirtualHost *:port> which is not in <IfDefine SSL>
# </IfDefine> block. Also look for https port
#
sub getOMSPorts() {
  my (@args) = @_;
  my $host = $args[0];
  if($host eq "")
  {
    $host = $serverhost ;
  }
  my $asctlcmd = "asctl -oraclehome $ORACLE_HOME listPortRanges -connurl $ENV{'EM_MAS_CONN_URL'} -user $ENV{'EM_MAS_ADMIN_USER'} -toponode /$ENV{'EM_FARM_NAME'}/$ENV{'EM_INSTANCE_NAME'}/$ENV{'EM_OHS_NAME'}";
  my $http;
  my $https;
  open(DAT, "$asctlcmd|");
  while (<DAT>) {
        if (/($host)_http_em_console_Endpoint/) {
        my @res =  split(/\|/);
        $http= $res[2];
        }
        if (/($host)_https_em_upload_Endpoint/) {
        my @res =  split(/\|/);
        $https= $res[2];
        }
  }
  close(DAT);

  my @returnArray = ();
  (@returnArray) = ($http, $https);
  return (\@returnArray);

}

#
# get http port for the console from httpd_em.conf file. We are looking for 
# the port for the  <VirtualHost *:port> which is not in <IfDefine SSL>
# </IfDefine> block. Also look for https port
#
sub getOMSPorts2 {
  my(@args) = @_;
  #TODO - ideally we should get the doc from ohs comp
  my $oc4jLoc                = getOc4jLoc();
  my $httpEmConfFile         = "$oc4jLoc/sysman/config/httpd_em.conf";
  my $sslStart               = "<IfDefine SSL>";
  my $sslStop                = "<\/IfDefine>";
  my $emConsoleHttpPort = "";
  my $emConsoleHttpsPort = "";
  my @returnArray = ();

  open(EMCONFH, $httpEmConfFile) || die "Could not open $httpEmConfFile\n";
  my $curLine;
  my $insideSSL = 0;
  while(defined($curLine = <EMCONFH>))
  {
    chop $curLine;
    if ($curLine =~ /^.*<VirtualHost\s+\*:(\d+)>/)
    {
       if ($insideSSL == 0)
       {
         $emConsoleHttpPort = $1;
       }
       else
       {
         $emConsoleHttpsPort = $1;
       }
    }
    if ($curLine =~ /^$sslStart/) 
    {
      $insideSSL = 1;
    }
    if ($curLine =~ /^$sslStop/)
    {
      $insideSSL = 0;
    }
  }
  close(EMCONFH);

  SecureUtil::DEBUG (
              "Http upload port from httpd_em.conf is $emConsoleHttpPort\n");
  SecureUtil::DEBUG (
              "Https upload port from httpd_em.conf is $emConsoleHttpsPort\n");

  (@returnArray) = ($emConsoleHttpPort, $emConsoleHttpsPort);
  return (\@returnArray);
  
}


sub sso
{
  local (*args) = @_;
  my $retVal    = "";
  parsecommand(@args);
  $port = (SecureOMSCmds::getOMSPorts())->[0];
  verifyparams();
  modifyconfig(@args);
  # Must exit here as this gets called as a require from emctl.pl
  return $retVal;
}


# get command line options
sub parsecommand()
{
    @args = @_;
    while ($#args > 0)
    {
      $_ = shift(@args);
      
      # mendatory arguments
      if (/^-mas_user/)
      {
          $mas_user = shift(@args);
      }
      elsif (/^-ossoconf/)
      {
          $ossoconf = shift(@args);
      }
      elsif (/^-tempdir/)
      {
          $tempdir = shift(@args);
      }
      elsif (/^-dasurl/)
      {
          $dasurl = shift(@args);
      }
      else
      {
          print "\nERROR: Unknown argument: $_\n\n";
          printusage();
          exit;
      }
    }
}

sub printusage()
{
    print "Usage:\n";
    print "       emctl config oms sso -mas_user <mas_user> -ossoconf <ossoconf> -tempdir <tempdir> -dasurl <dasurl> \n";
    print "       mas_user: MAS administrative username\n";
    print "       ossoconf: osso.conf file path\n";
    print "       tempdir: Temporari directory location\n";
    print "       dasurl:  DAS URL\n";
    print "Example:\n";
    print "       emctl config oms sso -mas_user admin -ossoconf /tmp/osso.conf -tempdir /tmp -dasurl http://somehost.domain.com:7777/ \n";
}

# read parameters from a file
# - not used
sub readparam()
{
    my ($file) = @_;
    SecureUtil::USERINFO ("Read parameters from $file\n");
    open(PARAMFILE, "<$file") || die "Cannot open $file\n";
    while (<PARAMFILE>)
    {
      /^OracleHome=(.*)/ && ($ohm = $1);
      /^Hostname=(.*)/ && ($hostname = $1);
      /^HostPort=(.*)/ && ($port = $1);
      /^HostDomain=(.*)/ && ($domain = $1);
      /^User=(.*)/ && ($user = $1);
      /^ConfigFile=(.*)/ && ($configfile = $1);
      /^PropertyFile=(.*)/ && ($propfile = $1);
      /^ServerHost=(.*)/ && ($serverhost = $1);
      /^ServerPort=(.*)/ && ($serverport = $1);
      /^ServerSid=(.*)/ && ($serversid = $1);
      /^ServerSchema=(.*)/ && ($serverschema = $1);
      /^ServerPwd=(.*)/ && ($serverpwd = $1);
      /^ServerWebPort=(.*)/ && ($serverwebport = $1);
    }
}

# get params from Apache configuration file
# - not used
sub getParameters()
{
    $ENV{DOC_NAME}="httpd.conf";
    $ENV{TOPO_PATH}="$ENV{EM_INSTANCE_NAME}/$ENV{EM_OHS_NAME}";
    $ENV{SAVE_DIR}="$ENV{'ORACLE_HOME'}/work/setup";
    $ENV{SAVE_LOC}="$ENV{SAVE_DIR}/$ENV{DOC_NAME}";
    #
    mkdir -p $ENV{SAVE_DIR};
    system("$ENV{ORACLE_HOME}/bin/asctl script $ENV{SRCHOME}/emcore/scripts/asctl/get_doc.py");
    my $port2 = "";
    SecureUtil::USERINFO ("Get parameters from $configfile\n");
    open(CONFFILE, "<$configfile") || die "Cannot open $configfile\n";

    while (<CONFFILE>) {
        # - get the last line (none ssl)
        if(/^ServerName (.*)/) {
            $hostname = $1;
            print "hostname=$hostname\n";
            $_ = $hostname;
            if($hostname =~ /^[\w_-]+\.(.*)/) { $domain=$1;}
        }
        if($port !~ /\d+/) {
            /^Listen (\d+)/ &&  ($port = $1);
            /^Port (\d+)/ &&    ($port2 = $1);
        }
        if($user !~ /\w/) {
            /^User (.*)/ && ($user = $1);
        }
    }
    close(CONFFILE);

    if ($port !~ /\d+/) {
        $port = $port2;
    }
}

# get the values if not set in parameter files
sub verifyparams()
{
    SecureUtil::DEBUG ("Verifing parameters...");
    if ($mas_user eq "") 
    {
        printusage();
        exit;
    }
    if ($ossoconf eq "") 
    {
        printusage();
        exit;
    }
    if ($tempdir eq "") 
    {
        printusage();
        exit;
    }
    if ($dasurl eq "") 
    {
        printusage();
        exit;
    }

    if($hostname =~ /^[\w_-]+\.(.*)/)
    {
      $domain=$1;
    }

    if ($domain eq "")
    { 
        print "domain name empty - $hostname must be a fully qualified host name" ;
        exit;
    }
}

# Modify Apache configuration file
sub modifyconfig()
{
    my @args = @_;
    my $classpath         = &SecureUtil::getConsoleClassPath("");
    my $cmdargs = "-mas_user $mas_user -ossoconf $ossoconf -tempdir $tempdir  -domain $domain -dasurl $dasurl ";
    my $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $classpath:$ENV{ORACLE_HOME}/jlib/adminserver.jar ".
              "-DORACLE_HOME=$ORACLE_HOME ".
              "-Doracle.instance.home=$INSTANCE_HOME ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-Dmas.connurl=$mas_connurl ".
              "-Dmas.farmname=$mas_farm_name ".
              "-Ddebug=true ".
              "oracle.sysman.emctl.config.oms.ConfigSSO $cmdargs";

  #print "javaCall = $javaCall\n";

  print "Setting up SSO Configuration ...\n";
  my $rc = 0xffff & system($javaCall);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
     print "SSO Setup completed successfully. Please restart OMS\n";
     return 0;
  }
  print "SSO Setup failed. Please check log.\n";
  return 1;
}

# Not used
sub modifyconfig2()
{
    my $savedir = "$ENV{ORACLE_HOME}/work/setup";
    my $cmd = "";
    SecureUtil::MKDIRP ($savedir);

    print "Copying osso.conf file to its final destination\n";
    # First Copy osso.conf file to destination
    $cmd = "$ENV{ORACLE_HOME}/bin/asctl -oraclehome $ENV{ORACLE_HOME} saveDoc -connurl $ENV{EM_MAS_CONN_URL} -oracleinstance $ENV{EM_INSTANCE_NAME} -name osso.conf -type osso-conf-file -file $ossoconf -toponode $ENV{EM_INSTANCE_NAME}/$ENV{EM_OHS_NAME}";
SecureUtil::DEBUG( "$cmd\n");
    system($cmd);
    # Copy this file till we figure out how to regiser osso.conf file
    #copy($ossoconf, "$ENV{EM_INSTANCE_HOME}/config/OHSComponent/$ENV{EM_OHS_NAME}/osso.conf");


    # Create mod_osso.conf file
    print "Generating mod_osso.conf\n";
    open (DAT, ">$savedir/mod_osso.conf");
    print DAT "LoadModule osso_module modules/mod_osso.so\n";
    print DAT "\n";
    print DAT "\<IfModule mod_osso.c\>\n";
    print DAT "   OssoIpCheck off\n";
    print DAT "   OssoIdleTimeout off\n";
    print DAT "   OssoConfigFile osso.conf\n";
    print DAT "\<\/IfModule\>\n";
    close DAT;

    # Save mod_osso.conf file
    print "Saving mod_osso.conf using ASCTL\n";
    $cmd = "$ENV{ORACLE_HOME}/bin/asctl -oraclehome $ENV{ORACLE_HOME} saveDoc -connurl $ENV{EM_MAS_CONN_URL} -oracleinstance $ENV{EM_INSTANCE_NAME} -name mod_osso.conf -file $savedir/mod_osso.conf -toponode $ENV{EM_INSTANCE_NAME}/$ENV{EM_OHS_NAME}";
    SecureUtil::DEBUG( "Running $cmd\n");
    system($cmd);


    # get httpd.conf 
    print "Getting httpd.conf from MAS\n";
    $cmd = "$ENV{ORACLE_HOME}/bin/asctl -oraclehome $ENV{ORACLE_HOME} getDoc -connurl $ENV{EM_MAS_CONN_URL} -oracleinstance $ENV{EM_INSTANCE_NAME} -name httpd.conf -location $savedir -toponode $ENV{EM_INSTANCE_NAME}/$ENV{EM_OHS_NAME}";
    SecureUtil::DEBUG( "$cmd\n") ;
    system($cmd);

    #Edit httpd.conf to enable mod_osso.conf
    print "Editing httpd.conf \n";
    my $configfile = "$savedir/httpd.conf";
  
    SecureUtil::USERINFO ("Modifying HTTP configuration file...\n");
    open(CONFFILE, "<$configfile") || die "Cannot open $configfile\n";
    my @arr = (<CONFFILE>);
    close CONFFILE;

    my $i = 0;
    my $change = 0;
    for($i=0; $i<=$#arr; $i++)
    {
      if($arr[$i] =~ m/^\s*#include\s+\"conf\/mod_osso.conf\"/)
      {
	$arr[$i] = "include \"conf\/mod_osso.conf\"\n";
          $change=1;
      }
    }
    open (CONFFILE, ">$configfile") || die "Cannot open $configfile\n";
    print CONFFILE @arr;
    close CONFFILE;

    # Save httpd.conf
    print "Saving httpd.conf \n";
    $cmd = "$ENV{ORACLE_HOME}/bin/asctl -oraclehome $ENV{ORACLE_HOME} saveDoc -connurl $ENV{EM_MAS_CONN_URL} -oracleinstance $ENV{EM_INSTANCE_NAME} -name httpd.conf -file $savedir/httpd.conf -toponode $ENV{EM_INSTANCE_NAME}/$ENV{EM_OHS_NAME}";
    SecureUtil::DEBUG($cmd);
    system($cmd);

    if ($change == 1)
    {
      SecureUtil::DEBUG ("$configfile has been modified.\n");
      SecureUtil::USERINFO ("   Done.\n");
    }
    else
    {
      SecureUtil::DEBUG ("$configfile has already been set to enable SSO.\n");
      SecureUtil::USERINFO ("   Done.\n");
    }
}

#
# Modify EM Console configuration file
#
sub modifyprop()
{

    # Set oracle.sysman.emSDK.sec.DirectoryAuthenticationType = SSO
    # Set oracle.sysman.emSDK.sec.sso.DASHostUrl = $dasurl
    # oracle.sysman.emSDK.sec.sso.Domain = $domain
    &EMomsCmds::checkAndSetMasInfo();
    print "Setting OMS Property oracle.sysman.emSDK.sec.DirectoryAuthenticationType\n";
    &EMomsCmds::setproperty("emoms", "oracle.sysman.emSDK.sec.DirectoryAuthenticationType", "SSO");
    print "Setting OMS Property oracle.sysman.emSDK.sec.sso.DASHostUrl\n";
    &EMomsCmds::setproperty("emoms", "oracle.sysman.emSDK.sec.sso.DASHostUrl", $dasurl);
    print "Setting OMS Property oracle.sysman.emSDK.sec.sso.Domain\n";
    &EMomsCmds::setproperty("emoms", "oracle.sysman.emSDK.sec.sso.Domain", $domain);
}

sub registersso()
{
    my $cmd  = "$ohm/jdk/bin/java -jar $ohm/sso/lib/ossoreg.jar -oracle_home_path $ohm";
    my $arg1 = "-host $serverhost -port $serverport -sid $serversid -schema $serverschema -pass $serverpwd";
    my $arg2 = "-site_name $hostname:$port -success_url http://$hostname:$port/osso_login_success"; 
    my $arg3 = "-logout_url  http://$hostname:$port/osso_logout_success";
    my $arg4 = "-cancel_url http://$hostname:$port/ -home_url http://$hostname:$port/";
    my $arg5 = "-config_mod_osso TRUE -u $user -sso_server_version v1.2";
    
    $cmd = "$cmd $arg1 $arg2 $arg3 $arg4 $arg5";
    SecureUtil::USERINFO ("Registering to SSO server, please wait...\n");
    SecureUtil::DEBUG ($cmd);
    my $rc = 0xffff & system($cmd);
    my $exitVal = $rc >> 8;
    if($exitVal)
    {
      SecureUtil::USERINFO ("Failed. Error:$exitVal\n");
      SecureUtil::DEBUG ("Failed executing $cmd.\n[$?;$exitVal;$!]\n");
    }
    else
    {
      SecureUtil::USERINFO ("   Done.\n");
    }
    return $exitVal;
}

sub debug()
{
    my($msg) = @_;
    print "DEBUG: $msg\n" unless !$debugFlag;
}


sub displaySecureOMSCmdsHelp
{
  print "Help!\n";
}

sub checkAndSetMasInfo()
{
  if(!defined($ENV{'EM_MAS_ADMIN_USER'}) ||
     !defined($ENV{'EM_MAS_ADMIN_PASSWD'}))
  {
    print STDOUT "MAS Username: ";
    chomp($ENV{'EM_MAS_ADMIN_USER'} = <STDIN>);
    $ENV{'EM_MAS_ADMIN_PASSWD'} = EmctlCommon::promptUserPasswd("MAS Password: ");
  }

  $mas_user = $ENV{'EM_MAS_ADMIN_USER'};
  $mas_passwd = $ENV{'EM_MAS_ADMIN_PASSWD'};
}

1;


