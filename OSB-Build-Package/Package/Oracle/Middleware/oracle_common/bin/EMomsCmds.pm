#Author: Kondayya Duvvuri
#Date Created : 05/13/2004
#Handles all the emctl options pertaining to oms.
#rrawat   03/03/08 -- bug 6857544 
#chyu     02/01/08 -- bug 6791995: update version to 11.1.0.2.0
#yulin    12/10/07 -- bug 6680522: update version to 11.1.0.1.0
#rpinnama 09/01/07 -- Add support for storing repos password in cred store
#arunkri  06/20/07 -- Add display width and level explicitely for table parsing logic to work.
#arunkri  06/20/07 -- Add display width and level explicitely for table parsing logic to work.
#ssherrif 12/26/06 -- Bug 5711715
#shianand 05/08/17 -- Bug 4911857. Moving SSO registration to SecureOMSCmds.pm
#neearora 05/08/17 -- Bug 4241177. Change implementation of getVersion 
#                     to read version from file. Added command
#                     emctl getversion oms    
#kduvvuri 04/07/28 -- add getVersion.
#shianand 05/05/23 -- fix bug 4216045.
#shianand 05/06/24 -- fix bug 4287567 Cutting over dcmctl to opmnctl in "emctl status oms".
#shianand 05/03/31 -- Refactoring Secure Commands.
#shianand 11/14/05  - fix secure status oms to status oms -secure [-omsurl <>]

package EMomsCmds;

use EmCommonCmdDriver;
use EmctlCommon;
use SecureOMSCmds;
use Text::Wrap;

# Asctl related initialization
my $mas_user;
my $mas_passwd;
my $mas_connurl = $ENV{'EM_MAS_CONN_URL'};
my $em_instance_name = $ENV{'EM_INSTANCE_NAME'};
my $mas_instance_name = $ENV{'EM_MAS_INSTANCE_NAME'};
my $oracle_instance = $ENV{'EM_INSTANCE_HOME'};
my $mas_instance_home = $ENV{'EM_MAS_INSTANCE_HOME'};
my $mas_farm_name = $ENV{'EM_FARM_NAME'};
my $mas_oracle_home = $ENV{'ORACLE_HOME'} ;
my $oc4j_name = $ENV{'EM_OC4J_NAME'};
my $ohs_name = $ENV{'EM_OHS_NAME'};
my $nrd_name = "nrd_name"; #hardcoding the name due to the bug 6927986
my $emctl_log = "$oracle_instance/OC4JComponent/$oc4j_name/sysman/log/emctl.log";

# Hash to get and check AdminServer status
my %statusHash = ();

# Classpath for calling java Emctl
my $CLASSPATH = "$ORACLE_HOME/jlib/adminserver.jar".
                "$cpSep$ORACLE_HOME/jlib/asctl.jar".
                "$cpSep$ORACLE_HOME/sysman/jlib/emcore_client.jar".
                "$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/admin.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxframework.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar".
                "$cpSep$ORACLE_HOME/jlib/dms.jar".
                "$cpSep$ORACLE_HOME/jlib/ojdl.jar".
                "$cpSep$ORACLE_HOME/jlib/ojdl2.jar".
                "$cpSep$ORACLE_HOME/jlib/ojdl-log4j.jar".
                "$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/lib/http_client.jar".
                "$cpSep$ORACLE_HOME/j2ee/home/lib/servlet.jar";

sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);
  return $self;
}

sub doIT {
   my $classname = shift;
   my $rargs = shift;
   my $result = $EMCTL_UNK_CMD;

   $argCount = @$rargs; 
   #print "doIT of EMomsCmds: self is $classname, args passed @$rargs\n";
   if ( $rargs->[1] eq "oms" )
   {
     #print "Processing <options> oms \n";

     if ( $rargs->[0] eq "start" )
     {
        startOMS($rargs->[2]);
        $result = $EMCTL_DONE;
     }
     elsif ( $rargs->[0] eq "stop" )
     {
        stopOMS();
        $result = $EMCTL_DONE;
     }
     elsif ( $rargs->[0] eq "status" )
     {
        if ($rargs->[2] eq "-secure")
        {
          my $exitCode = &SecureOMSCmds::secureStatus($rargs->[1], $rargs->[4]);
          my @retArray = ($EMCTL_DONE,$exitCode);
          return \@retArray;
        }
        $result = statusOMS($rargs);
     }
     elsif ( $rargs->[0] eq "config")
     {
       $result = configOMS($rargs);
     }
     elsif ( $rargs->[0] eq "setpasswd")
     {
       setReposPasswd();
       $result = $EMCTL_DONE;
     }
     elsif ( lc($rargs->[0]) eq "getversion")
     {
       getVersion();
       $result = $EMCTL_DONE;
     }
     elsif ( $rargs->[0] eq "getproperty" )
     {
       $result = getPropertyOMS($rargs);
     }
     elsif ( $rargs->[0] eq "setproperty" )
     {
       $result = setPropertyOMS($rargs);
     }
     elsif ( $rargs->[0] eq "removeproperty" )
     {
       $result = removePropertyOMS($rargs);
     }
     elsif ( $rargs->[0] eq "listallproperties" )
     {
       $result = listAllPropertiesOMS($rargs);
     }
     elsif ( $rargs->[0] eq "exportconfig" )
     {
       $result = exportConfigOMS($rargs);
     }
	 elsif ( $rargs->[0] eq "importconfig" )
     {
       $result = importConfigOMS($rargs);
     }
     elsif ( $rargs->[0] eq "getproxydetails" )
     {
       $result = getProxyDetailsOMS($rargs);
     }
     elsif ( $rargs->[0] eq "setproxydetails" )
     {
       $result = setProxyDetailsOMS($rargs);
     }
     elsif ( $rargs->[0] eq "removeproxydetails" )
     {
       $result = removeProxyDetailsOMS($rargs);
     }
     elsif ( $rargs->[0] eq "getmessagedetails" )
     {
       $result = getMessageDetailsOMS($rargs);
     }
   }

   return $result;
}







#
# Set up FCF

#
#
sub configFCF
{
  local (*args) = @_;
  if(@args < 2 || @args > 4)                    # -- we need atleast the enable option
  {
     return($EMCTL_BAD_USAGE);  
  }
  my  $count = 0;
  my $enable = -1;
  my $dbnodes="";
  for($count = 0; $count < @args; $count++)
  {
    if($args[$count] eq "-enable")
    {
      if($count == @args - 1)
      {
         return($EMCTL_BAD_USAGE);
      }
      if($args[$count + 1] eq "true")
      {
        $enable = 1;
      }
      elsif($args[$count + 1] eq "false")
      {
        $enable = 0;
      }
     else
     {
       return($EMCTL_BAD_USAGE);
     }
    }
    elsif($args[$count] eq "-dbnodes")
    {
      if($count == @args - 1){
        return($EMCTL_BAD_USAGE);
       }
      if($args[$count + 1] eq ""){
        return($EMCTL_BAD_USAGE);
       }
       else{
         $dbnodes = $args[$count + 1];
       }
    }
 }
 if($enable == 1)
 {
   if($dbnodes eq "")
   {
     return($EMCTL_BAD_USAGE);
   }
   else{
     return enableFCF($dbnodes);
   }
 }
 elsif($enable == 0){
   return disableFCF();
 }
 else{
   return($EMCTL_BAD_USAGE);
 }
}


#enable FCF
#argument is a string of nodes of the form h1:p1;h2:p2
#

sub enableFCF()
{
  my (@args) = @_;

  my $nodes=$args[0];
# if($args[0] =~ m/".*"/)
#  {
    #take out the ""
#    $nodes =~ tr/"/ /;
#  }
  checkAndSetMasInfo();

  my $scriptName = "$mas_oracle_home/sysman/setup/FCF.py";
  my $asctl_cmd = "asctl -oraclehome $mas_oracle_home script $scriptName  $nodes";

  system($asctl_cmd);
  
  if($? != 0)
  {
    print "Error in enabling FCF. Exiting..\n";
    return;
  }
  setproperty("emoms", "em.FastConnectionFailover", "true");
  
  print "Done Setting the OMS property for FCF \n";
  print "FCF Enalbled \n";

  if($? == 0)
  {
    return $EMCTL_DONE;
  }
  
}

sub disableFCF()
{

   checkAndSetMasInfo();
   print "Disabling FCF\n";
   
   my $property_name="em.FastConnectionFailover";
   my $property_type="emoms";
   my $property_value = "false";
  

   checkAndSetOracleInstance();
   setproperty($property_type, $property_name, $property_value);

   print "Disabled FCF\n";
   return ($EMCTL_DONE);
}








#
# startOMS
#
sub startOMS()
{
  write_to_file($emctl_log, "DEBUG    :: emctl start oms: Started");
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-Dmas.instance.home=$mas_instance_home ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Djava.net.preferIPv4Stack=true ".
              "oracle.sysman.emctl.oms.EmctlMain Start Oms -logfile $emctl_log -auth";

  open(STARTOMS, "|$javaCall");
  print STARTOMS "$mas_passwd\n";
  close(STARTOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl start oms: Completed");

}

#
# stopOMS
#
sub stopOMS()
{
  write_to_file($emctl_log, "DEBUG    :: emctl stop oms: Started");
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Djava.net.preferIPv4Stack=true ".
              "oracle.sysman.emctl.oms.EmctlMain Stop Oms -logfile $emctl_log -auth";

  open(STOPOMS, "|$javaCall");
  print STOPOMS "$mas_passwd\n";
  close(STOPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl stop oms: Completed");

}


#
# statusOMS
#
sub statusOMS()
{
  local (*args) = @_;
  $is_details = "-nodetails";

  shift(@args);                  # -- shift out status ...
  shift(@args);                  # -- shift out oms ...

  if(@args gt 1 || ($args[0] ne "" && $args[0] ne "-details"))
  {
    return($EMCTL_BAD_USAGE);
  }
  elsif($args[0] eq "-details")
  {
    $is_details = "-details";
  }

  write_to_file($emctl_log, "DEBUG    :: emctl status oms: Started");
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Djava.net.preferIPv4Stack=true ".
              "oracle.sysman.emctl.oms.EmctlMain Status Oms $is_details -logfile $emctl_log -auth";

  open(STATUSOMS, "|$javaCall"); 
  print STATUSOMS "$mas_passwd\n"; 
  close(STATUSOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl status oms: Completed");

  return($EMCTL_DONE);

}


#
# Config OMS takes
# 1) Array of arguments
#            emctl config oms sso ...
#
sub configOMS()
{
  local (*args) = @_;

  shift(@args);                  # -- shift out config...
  shift(@args);                  # -- shift out oms ...

  if ($args[0] eq "sso") #emctl config oms sso
  {
      shift(@args);                  # -- shift out sso ...
      my $exitCode = sso( \@args );
      my @retArray = ($EMCTL_DONE,$exitCode);
      return \@retArray;
  }
  elsif($args[0] eq "loader") # emctl config oms loader
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);                  # -- shift out loader
     $result = configLoader(\@args);
     return($result);
  }
  elsif($args[0] eq "store_repos_details") # emctl config oms store_repos_details
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);                  # -- shift out repos_details
     $result = storeRepositoryDetails(\@args);
     return($result);
  }
  elsif($args[0] eq "store_emkey_details") # emctl config oms store_emkey_details
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);                  # -- shift out repos_details
     $result = storeEMKeyDetails(\@args);
     return($result);
  }
  elsif($args[0] eq "setauth") # emctl config oms auth
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);                  # -- shift out repos_details
     $result = setauth_mode(\@args);
     return($result);
  }
  elsif($args[0] eq "-list_repos_details")
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);
     listReposDetails(\@args);
  }
  elsif($args[0] eq "-store_repos_details")
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);
     storeReposDetails(\@args);
  }
  elsif($args[0] eq "-change_repos_pwd")
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);
     changeReposPwd(\@args);
  }
  elsif($args[0] eq "-change_view_user_pwd")
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);
     changeReposSplUserPwd("MGMT_VIEW_FLAG", \@args);
  }
  elsif($args[0] eq "-change_dmql_eval_user_pwd")
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);
     changeReposSplUserPwd("DMQL_EVAL_FLAG", \@args);
  }
  elsif($args[0] eq "fcf")
  {
     my $result = $EMCTL_UNK_CMD;
     shift(@args);
     $result = configFCF(\@args);
     return ($result);
  }
 

  return($EMCTL_UNK_CMD);
  
}

sub setReposPasswd()
{
  print "This command is deprecated. Use 'emctl config oms -change_repos_pwd' instead.\n";
}

sub listReposDetails()
{
    my $class_path = $CLASSPATH . 
                     "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                     "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar";

    my $cmd = "$JAVA_HOME/bin/java -cp $class_path " .
              "-Doracle.instance=$oracle_instance ".
              "-Doc4j.component.name=$oc4j_name ".
              "oracle.sysman.emctl.config.oms.ListReposDetails @args";

    $rc = 0xffff & system($cmd);
    $rc >>= 8;
    exit($rc);
}

sub storeReposDetails()
{
    my $class_path = $CLASSPATH .
                     "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                     "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar";

    my $cmd = "$JAVA_HOME/bin/java -cp $class_path " .
              "-Doracle.instance=$oracle_instance ".
              "-Doc4j.component.name=$oc4j_name ".
              "oracle.sysman.emctl.config.oms.StoreReposDetails @args";

    $rc = 0xffff & system($cmd);
    $rc >>= 8;
    exit($rc);
}

sub changeReposPwd()
{
    my $class_path = $CLASSPATH .
                     "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                     "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar";

    my $cmd = "$JAVA_HOME/bin/java -cp $class_path " .
              "-Doracle.instance=$oracle_instance ".
              "-Doc4j.component.name=$oc4j_name ".
              "oracle.sysman.emctl.config.oms.ChangeReposPwd @args";

    $rc = 0xffff & system($cmd);
    $rc >>= 8;
    exit($rc);
}

sub changeReposSplUserPwd()
{
    my $username = shift;
    my $class_path = $CLASSPATH .
                     "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                     "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar";

    my $cmd = "$JAVA_HOME/bin/java -cp $class_path " .
              "-Doracle.instance=$oracle_instance ".
              "-Doc4j.component.name=$oc4j_name ".
              "oracle.sysman.emctl.config.oms.ChangeReposSplUserPwd $username @args";

    $rc = 0xffff & system($cmd);
    $rc >>= 8;
    exit($rc);
}

sub setauth_mode()
{
  # Format ldap ....
  my $mode = $args[0];
  shift(@args);
print "mode $mode\n";
  if ($mode eq "ldap") 
  {
     return setup_ldap_auth(args);
  }
  elsif ($mode eq "repos") 
  {
      checkAndSetMasInfo();
      print "\nSetting up emoms.properties em.authmode ...";
      setproperty("emoms", "em.authmode", "repos_login_module");
      # em.authmode = repos_login_module
      print "\nEM Authentication setup completed successfully\n";
      return 0;
  }
  else
  {
      print "Invalid usage: pass additional argument ldap or repos\n";
      print "Use ldap : This will setup authentiation mode to use OID Store\n";
      print "UUsae repos: If current mode is set to use OID. This will revert it back to repository users\n";
      return 0;
  }
  return($EMCTL_UNK_CMD);
}

sub getauth_mode() 
{
   checkAndSetMasInfo();
   my @val = getproperty("emoms", "em.authmode");
   if (($val[0] eq "repos_login_module")  || ($val[0] eq ""))
   {
      print "Repository\n";
   }
   elsif ($val[0] eq "login-module") 
   {
      my @module = getproperty("emoms", "em.auth.login-module");
      print "Login Module $module[0]\n";
   }
   else {
      print "Error Occured\n";
   }
   return 0;
}
sub setup_ldap_auth()
{
  checkAndSetMasInfo();
  my $class_path = "$CLASSPATH".
                   "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar".
                   "$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar".
                   "$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar";

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $class_path ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Doracle.instance.home=$oracle_instance ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-Dmas.connurl=$mas_connurl ".
              "-Ddebug=true ".
              "oracle.sysman.emctl.config.oms.ConfigJpsLdapCmd @args ";

  #print "javaCall = $javaCall\n";

  print "Setting up jps-config.xml...";
  $rc = 0xffff & system($javaCall);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
      # set emoms props
      # em.authmode= login-module
      # em.auth.login-module= default
      print "\nSetting up emoms.properties em.authmode ...";
      setproperty("emoms", "em.authmode", "login-module");
      print "\nSetting up emoms.properties em.auth.login-module ...";
      setproperty("emoms", "em.auth.login-module", "LDAP");
      print "\nEM Authentication setup completed successfully\n";
  }
  else
  {
      print "Failed with rc = $rc\n";
  }

  return $EMCTL_DONE;
}

#
# Sets up the SSO
#
sub sso()
{
  local (*args) = @_;
  my $ret = &SecureOMSCmds::sso (\@args);
  return $ret;
}

sub configLoader()
{
  my $sharedFlag, $loaderDir;
  my $no_restart = "false";
  my $is_Force = "false";

  if(@args lt 4)
  {
    return($EMCTL_BAD_USAGE);
  }
  if($args[0] eq "-shared")
  {
     shift(@args);                  # -- shift out -shared
     $sharedFlag = $args[0];
     shift(@args);
   }
  else 
  {
     return($EMCTL_BAD_USAGE);
   }

  if($args[0] eq "-dir")
  {
      shift(@args);                  # -- shift out -dir
      $loaderDir = $args[0];
      shift(@args);
   }
  else 
  {
     return($EMCTL_BAD_USAGE);
   }

  while(@args gt 0)
  {
    if($args[0] eq "-no_restart")
    {
       $no_restart = "true";
    }
    elsif($args[0] eq "-force")
    {
       $is_Force = "true";  
    }
    shift(@args);
  } 

  if ( not(-e $loaderDir))
  {
    print "Error $loaderDir does not exist\n";
    exit(1);
   }
  elsif (not(-w $loaderDir))
  {
     print "Error $loaderDir is not writable\n";
     exit(1);
   }

  if($sharedFlag eq "yes")
  {
    $sharedFlag = "sharedFilesystem";
  }
  elsif($sharedFlag eq "no")
  {
    $sharedFlag = "nonSharedFilesystem";
  }
  else
  {
     return($EMCTL_BAD_USAGE);
   }

  checkAndSetMasInfo();

  # Check if the current recv directory has any file pending upload
  if($is_Force eq "false")
  {

    my @result = getproperty("emoms", "ReceiveDir");
    my $curLoaderDir = $result[0];

    if($curLoaderDir eq "" and $result[1] ne "")
    {
      print "Following error occured while getting value for property ReceiveDir: \n";
      print "$result[1] \n";
      exit(1);
    }
    if( $curLoaderDir eq "")
    {
       $curLoaderDir = File::Spec->catfile("$oracle_instance","OC4JComponent","$oc4j_name","sysman","recv");
    }

    @result = getproperty("emoms", "em.loader.coordinationMethod");
    my $curSharedFlag = $result[0];

    if($curSharedFlag eq "" and $result[1] ne "")
    {
      print "Following error occured while getting value for property em.loader.coordinationMethod: \n";
      print "$result[1] \n";
      exit(1);
    }

    if($curSharedFlag eq "")
    {
      $curSharedFlag = "nonSharedFilesystem";
    }
 
    if((($curSharedFlag ne $sharedFlag) or ($curLoaderDir ne $loaderDir)) and
       (-e $curLoaderDir))
    {
      opendir(DIR, $curLoaderDir);
      LINE: while($FILE = readdir(DIR)) {
         next LINE if($FILE =~ /^\.\.?/);

         if(!(-d File::Spec->catfile("$curLoaderDir","$FILE")))
         {
           print "Error $curLoaderDir is not empty. Please upload these files or delete these files \n";
           exit(1);
         }
      }
    }
  } 
  # End check if files pending upload

  my $property_name = "em.loader.coordinationMethod";
  my $property_value = $sharedFlag;
  my $property_type = "emoms";

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
               "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain SetProperty Oms $property_name $property_value $property_type -logfile $emctl_log -auth 1>> $emctl_log";

  open(SETPROPOMS, "|$javaCall");
  print SETPROPOMS "$mas_passwd\n";
  close(SETPROPOMS);

  my $cmdStatus1 = $?;
  $cmdStatus1 = $cmdStatus1>>8;

  $property_name = "ReceiveDir";
  $property_value = $loaderDir;

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain SetProperty Oms $property_name $property_value $property_type -logfile $emctl_log -auth 1>> $emctl_log";

  open(SETPROPOMS, "|$javaCall");
  print SETPROPOMS "$mas_passwd\n";
  close(SETPROPOMS);

  my $cmdStatus2 = $?;
  $cmdStatus2 = $cmdStatus2>>8;

  if($cmdStatus1 == 0 && $cmdStatus2 == 0 )
  {
    if($no_restart eq "false")
    {
      print "The OMS needs to be bounced for changes to take affect. \n";
      print "Do you want to bounce the OMS now : (Y|N) ";
      my $prompt = <STDIN>;
      chomp($prompt);
      if( $prompt eq "" or $prompt eq "Y")
      {
        stopOMS();
        startOMS();
      }
    }
    return $EMCTL_DONE;
  }
  else
  {
    print "Error occured while configuring the loader. Oracle Management Server may be down.\n" ;
    print "Please check the log files.\n" ;
  }

  return $EMCTL_DONE;
}


sub storeRepositoryDetails()
{
  checkAndSetMasInfo();

  my $class_path = "$CLASSPATH".
                   "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar";

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $class_path ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Doracle.instance.home=$oracle_instance ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Ddebug=true ".
              "oracle.sysman.emctl.config.oms.StoreReposDetailsCmd @args ";

  #print "javaCall = $javaCall\n";

  $rc = 0xffff & system($javaCall);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
      print "Stored Repository details successfully\n";
  }
  else
  {
      print "Failed with rc = $rc\n";
  }

  return $EMCTL_DONE;
}

sub storeEMKeyDetails()
{
  checkAndSetMasInfo();

  my $class_path = "$CLASSPATH".
                   "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
                   "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar";

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $class_path ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Doracle.instance.home=$oracle_instance ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Ddebug=true ".
              "oracle.sysman.emctl.config.oms.StoreEMKeyInfoCmd @args ";

  # print "javaCall = $javaCall\n";

  $rc = 0xffff & system($javaCall);
  $rc >>= 8;
  if ( $rc eq 0 )
  {
      print "Stored EMKey details successfully\n";
  }
  else
  {
      print "Failed with rc = $rc\n";
  }

  return $EMCTL_DONE;
}

sub usage
{
    print "       emctl start| stop| setpasswd| getversion oms\n";
    print "       emctl status oms [-details]\n";
    print "       emctl status oms -secure [-omsurl <http://<oms-hostname>:<oms-unsecure-port>/em/*>]\n";
    print "       emctl config oms sso -host ssoHost -port ssoPort -sid ssoSid -pass ssoPassword -das dasURL -u user\n";
    print "       emctl config oms loader -shared <yes|no> -dir <loader dir>\n";
    print "       emctl config| status emkey <options>\n";
	print "\n";
    print "       emctl getproperty oms -name <emoms-property-name> [-type <emoms/emomslogging>]\n";
    print "       emctl setproperty oms -name <emoms-property-name> -value <new-property-value> [-type <emoms/emomslogging>]\n";
    print "       emctl removeproperty oms -name <emoms-property-name> [-type <emoms/emomslogging>]\n";
    print "       emctl listallproperties oms [-type <emoms/emomslogging>]\n";
    print "       emctl exportconfig oms [-dir <export dir>]\n";
    print "       emctl importconfig oms [-file <dmpfile>]\n";
    print "       emctl getproxydetails oms\n";
    print "       emctl setproxydetails oms\n";
    print "       emctl removeproxydetails oms\n";
    print "       emctl getmessagedetails oms -id=[EM-]#####\n";
    print "       emctl config oms -list_repos_details -mas_host <mas host> -mas_port <mas port> -mas_user <mas user> [-mas_pwd <mas pwd>]\n";
    print "       emctl config oms -store_repos_details -mas_host <mas host> -mas_port <mas port> -mas_user <mas user> [-mas_pwd <mas pwd>] [-repos_host <repos host> -repos_port <repos port> -repos_sid <repos sid> |-repos_conndesc <repos conndesc>] -repos_user <repos user> [-repos_pwd <repos pwd>] [-force]\n";
    print "       emctl config oms -change_repos_pwd -mas_host <mas host> -mas_port <mas port> -mas_user <mas user> [-mas_pwd <mas pwd>] [-new_pwd <new pwd>] [-use_sys_pwd -sys_pwd <sys pwd>]\n";
    print "       emctl config oms -change_view_user_pwd -mas_host <mas host> -mas_port <mas port> -mas_user <mas user> [-mas_pwd <mas pwd>] [-sysman_pwd <sysman pwd>] [-user_pwd <user pwd>]\n";
    print "       emctl config oms -change_dmql_eval_user_pwd -mas_host <mas host> -mas_port <mas port> -mas_user <mas user> [-mas_pwd <mas pwd>] [-sysman_pwd <sysman pwd>] [-user_pwd <user pwd>]\n";
    print "\n";
}

sub getVersion
{
  my $verStr = "       Enterprise Manager 11g OMS Version 11.1.0.2.0\n"; 

  my $inFile = "$ORACLE_HOME/sysman/config/emVersion.xml";
  if(-e $inFile) 
  {
    $CP = "$ORACLE_HOME/jdbc/lib/ojdbc5.jar$cpSep$ORACLE_HOME/jdbc/lib/nls_charset12.jar$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar$cpSep$ORACLE_HOME/dms/lib/dms.jar$cpSep$ORACLE_HOME/dms/lib/ojdl.jar$cpSep$ORACLE_HOME/lib/xmlparserv2.jar";
    $EMHOME = getEMHome($CONSOLE_CFG);

    $javaStr = "$JAVA_HOME/bin/java ".
               "-cp $CP ".
               "-DEMHOME=$EMHOME ".
               "-DORACLE_HOME=$ORACLE_HOME ".
               "oracle.sysman.emdrep.util.EMVersion $inFile";

    my @result = `$javaStr`;
    my $prodVer;
    my $coreVer;
 
    if (@result)
    {
      my $count = scalar(@result);
      my $i=0;
      while( $i < $count)
      {
        @comp = split /\s+/, $result[$i];
        if( lc($comp[0]) eq "productversion")
        {
          $prodVer = $comp[1];
        }
        elsif( lc($comp[0]) eq "coreversion")
        {
          $coreVer = $comp[1];
        }

        $i = $i + 1;
      }
      if($prodVer && $coreVer)
      {
        $verStr = "       Enterprise Manager ". $prodVer . " OMS Version ". $coreVer . "\n";
      }
    }
  }
  print $verStr; 
}

sub DESTROY {
    my $self = shift;
}

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


#
# getPropertyOMS
#   
sub getPropertyOMS()
{
  checkAndSetOracleInstance();
  write_to_file($emctl_log, "DEBUG    :: emctl getproperty oms: Started");

  local (*args) = @_;
  $property_type = "emoms";

  shift(@args);                  # -- shift out getproperty...
  shift(@args);                  # -- shift out oms ...

  if(@args lt 2 || @args gt 4)
  {
    return($EMCTL_BAD_USAGE);
  }

  my $property_name ;
  while (scalar(@args) gt 0)
  {
    if ($args[0] eq "-name")
    {
      shift(@args);
      $property_name = $args[0];
      shift(@args);
    }
    elsif ($args[0] eq "-type")
    {
      shift(@args);
      $property_type = $args[0];
      shift(@args);
    }
    else
    {
      return($EMCTL_BAD_USAGE);
    }
  }

  if($property_type eq "" || $property_name eq "")
  {
    return($EMCTL_BAD_USAGE);
  }
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain GetProperty Oms $property_name $property_type -logfile $emctl_log -auth";
    
  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl getproperty oms: Completed");

  return($EMCTL_DONE);

}

#
# setPropertyOMS
#
sub setPropertyOMS()
{
  checkAndSetOracleInstance();
  write_to_file($emctl_log, "DEBUG    :: emctl setproperty oms: Started");
    
  local (*args) = @_;
  $property_type = "emoms";
  
  shift(@args);                  # -- shift out setproperty...
  shift(@args);                  # -- shift out oms ...
  
  if(@args lt 4 || @args gt 6)
  {
    return($EMCTL_BAD_USAGE);
  }

  my $property_name, $property_value ;
  while (scalar(@args) gt 0)
  {
    if ($args[0] eq "-name")
    {
      shift(@args);
      $property_name = $args[0];
      shift(@args);
    }
    elsif ($args[0] eq "-value")
    {
      shift(@args);
      $property_value = $args[0];
      shift(@args);
    }
    elsif ($args[0] eq "-type")
    {
      shift(@args);
      $property_type = $args[0];
      if ($property_type eq "")
      {
        return($EMCTL_BAD_USAGE);
      }
      shift(@args);
    }
    else
    {
      return($EMCTL_BAD_USAGE);
    }
  }

  if($property_type eq "" || $property_value eq "" || $property_name eq "")
  {
    return($EMCTL_BAD_USAGE);
  }

  $property_value =~ s/(?<!\\)([\(\)])/\\$1/g ;
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain SetProperty Oms $property_name $property_value $property_type -logfile $emctl_log -auth";

  open(SETPROPOMS, "|$javaCall");
  print SETPROPOMS "$mas_passwd\n";
  close(SETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl setproperty oms: Completed");

  return($EMCTL_DONE);

}

#
# removePropertyOMS
# Usage : emctl removeproperty oms -name <property-name> [-type <emoms/emomslogging>]
#
sub removePropertyOMS()
{
  checkAndSetOracleInstance();
  write_to_file($emctl_log, "DEBUG    :: emctl removeproperty oms: Started");

  local (*args) = @_;
  $property_type = "emoms";

  shift(@args);                  # -- shift out removeproperty...
  shift(@args);                  # -- shift out oms ...

  if(@args lt 2 || @args gt 4)
  {
    return($EMCTL_BAD_USAGE);
  }

  my $property_name ;
  while (scalar(@args) gt 0)
  {
    if ($args[0] eq "-name")
    {
      shift(@args);
      $property_name = $args[0];
      shift(@args);
    }
    elsif ($args[0] eq "-type")
    {
      shift(@args);
      $property_type = $args[0];
      shift(@args);
    }
    else
    {
      return($EMCTL_BAD_USAGE);
    }
  }

  if($property_type eq "" || $property_name eq "")
  {
    return($EMCTL_BAD_USAGE);
  }
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain RemoveProperty Oms $property_name $property_type -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl removeproperty oms: Completed");

  return($EMCTL_DONE);

}

#
# listAllPropertiesOMS
# Usage : emctl listallproperties oms [-type <emoms/emomslogging>]
#
sub listAllPropertiesOMS()
{
  checkAndSetOracleInstance();
  write_to_file($emctl_log, "DEBUG    :: emctl listallproperties oms: Started");

  local (*args) = @_;
  $property_type = "emoms";

  shift(@args);                  # -- shift out listallproperties...
  shift(@args);                  # -- shift out oms ...

  if(@args gt 2)
  {
    return($EMCTL_BAD_USAGE);
  }

  while (scalar(@args) gt 0)
  {
    if ($args[0] eq "-type")
    {
      shift(@args);
      $property_type = $args[0];
      shift(@args);
    }
    else
    {
      return($EMCTL_BAD_USAGE);
    }
  }

  if($property_type eq "")
  {
    return($EMCTL_BAD_USAGE);
  }
  checkAndSetMasInfo();

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain ListAllProperties Oms $property_type -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl listallproperties oms: Completed");

  return($EMCTL_DONE);

}

#
# exportConfigOMS
# Usage : emctl exportconfig oms [-dir <export dir>]
#
sub exportConfigOMS()
{
  checkAndSetOracleInstance();
  write_to_file($emctl_log, "DEBUG    :: emctl exportconfig oms: Started");

  local (*args) = @_;
  #$property_type = "emoms";
  $file_in;
  $wallet_in;

  shift(@args);                  # -- shift out exportconfig
  shift(@args);                  # -- shift out oms ...

  if(@args gt 2)
  {
    return($EMCTL_BAD_USAGE);
  }

  if(@args lt 1)
  {
    print "Please specify an export directory.\n";
    return($EMCTL_BAD_USAGE);
  }

  while (scalar(@args) gt 0)
  {
    if ($args[0] eq "-dir")
    {
      shift(@args);
      $dir_in = $args[0];
      shift(@args);
    }
    else
    {
      return($EMCTL_BAD_USAGE);
    }
  }

  checkAndSetMasInfo();

  # get port info
  my $asctlcmd = "asctl -oraclehome $ORACLE_HOME listPorts -connurl $ENV{'EM_MAS_CONN_URL'} -user $ENV{'EM_MAS_ADMIN_USER'} -toponode /$ENV{'EM_FARM_NAME'}/$ENV{'EM_INSTANCE_NAME'}/$ENV{'EM_OHS_NAME'}";

  open(DAT, "$asctlcmd|");

  my $http;
  my $https;
  my $sec_console;
  my $unsec_console;

  while (<DAT>) {
      #print($curLine);
      if (/http_em_console_Endpoint/) 
      {
        my @res =  split(/\s*\|\s*/);
        $http= $res[1];
      }
      if (/https_em_upload_Endpoint/) 
      {
        my @res =  split(/\s*\|\s*/);
        $https= $res[1];
      }
      if (/http_ssl/) 
      {
        my @res =  split(/\s*\|\s*/);
        $sec_console= $res[1];
      }
      if (/http_main/) 
      {
        my @res =  split(/\s*\|\s*/); 
	$unsec_console= $res[1];
      }
  }
  close(DAT);

  my $ports = "$http,$https,$sec_console,$unsec_console";

  my $class_path = "$CLASSPATH".
      "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar";

  # Get repository password
  $repos_passwd = EmctlCommon::promptUserPasswd("Enter Enterprise Manager Root (SYSMAN) Password : ");

  # Get slb ports
  my $oc4jLoc                = $oracle_instance . "/OC4JComponent/" .$oc4j_name;
  my $httpEmConfFile         = "$oc4jLoc/sysman/config/httpd_em.conf";
  my $sslStart               = "<IfDefine SSL>";
  my $sslStop                = "<\/IfDefine>";
  my $emConsoleSLBPort = "";
  my $emConsoleHost = "";
  my @returnArray = ();

  open(EMCONFH, $httpEmConfFile) || die "Could not open $httpEmConfFile\n";
  my $curLine;
  my $insideSSL = 0;
  my $SSL = 0;
  while(defined($curLine = <EMCONFH>))
  {
    chop $curLine;
    #print($curLine);
    if ($curLine =~ /^.*VirtualHost\s([\w.-]+)?\_http+(\d+)?/)
    {
       #print("inside match loop: $1, $2 \n");
       $emConsoleHost = $1;
       if ($insideSSL == 1)
       {
         $emConsoleSLBPort = $2;
	 $SSL = 1;
       }
    }
    if ($curLine =~ /^$sslStart/) 
    {      $insideSSL = 1;
	   #print("inside ssl \n");
    }
    if ($curLine =~ /^$sslStop/)
    {
      $insideSSL = 0;
    }
  }
  close(EMCONFH);

  # call exportconfig command to get hostname in wallet
  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $class_path ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-DORACLE_HOME=$mas_oracle_home ".
	      "oracle.sysman.emctl.oms.EmctlMain ExportConfig Oms $emConsoleHost -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  print GETPROPOMS "$repos_passwd\n";
  close(GETPROPOMS);

  my $slb_keep = "n";
  my $response = 0;

  #if (($emConsoleSLBPort eq ""))
  #{
    while ($response != 1)
    {
      #local($Text::Wrap::columns) = 60;
      #print wrap("", "", "Export has determined that the OMS is not fronted by an SLB. Do you want to export the hostname \"$emConsoleHost\"? If you choose yes, the exported data can only be imported on a host named \"$emConsoleHost\". If you choose no, the exported data can be imported on any host but resecuring of all agents will be required. Please see the EM Advanced Configuration Guide for more details. y/n? ");               
      $slb_keep = <STDIN>;                                   
      chomp $slb_keep;
      lc $slb_keep;    

      if (($slb_keep eq "y") || ($slb_keep eq "n"))
      {
	$response = 1;
      }
      if ($response != 1)
      {
	print("Please enter y or n: ");
      }
    }
  #}

  my $sec = "$emConsoleHost,$emConsoleSLBPort,$slb_keep";
  #print("$sec\n");

  # call exportconfig command
  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $class_path ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-DORACLE_HOME=$mas_oracle_home ".
	      "oracle.sysman.emctl.oms.EmctlMain ExportConfig Oms $dir_in $ports $sec -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  print GETPROPOMS "$repos_passwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl exportconfig oms: Completed");

  return($EMCTL_DONE);

}

#
# importConfigOMS
# Usage : emctl importconfig oms [-file <dmpfile>]
#
sub importConfigOMS()
{
  checkAndSetOracleInstance();
  write_to_file($emctl_log, "DEBUG    :: emctl importconfig oms: Started");

  local (*args) = @_;
  #$property_type = "emoms";
  $file_in;
  #$wallet_in;

  shift(@args);                  # -- shift out importconfig...
  shift(@args);                  # -- shift out oms ...

  if(@args gt 3)
  {
    return($EMCTL_BAD_USAGE);
  }

  if(@args lt 1)
  {
    print "Please specify a file to import from.\n";
    return($EMCTL_BAD_USAGE);
  }

  while (scalar(@args) gt 0)
  {
    if ($args[0] eq "-file")
    {
      shift(@args);
      $file_in = $args[0];
      shift(@args);
    }

    #elsif ($args[0] eq "-wallet")
    #{
    #  shift(@args);
    #  $wallet_in = $args[0];
    #  shift(@args);
    #}
    else
    {
      return($EMCTL_BAD_USAGE);
    }
  }

  if($file_in eq "") #&& ($wallet_in eq ""))
  {
    return($EMCTL_BAD_USAGE);
  }

  checkAndSetMasInfo();

  my $class_path = "$CLASSPATH".
      "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
      "$cpSep$ORACLE_HOME/jlib/emConfigInstall.jar";

  # Get repository and agent registration passwords
  #$repos_passwd = EmctlCommon::promptUserPasswd("Enter Enterprise Manager Root (SYSMAN) Password : ");
  #$regPassword = EmctlCommon::promptUserPasswd("Enter Agent Registration password : ");

  # call importconfig command
  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $class_path ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-Doracle.instance.name=$em_instance_name ".
              "-Doracle.instance.oc4j.name=$oc4j_name ".
              "-Doracle.instance.ohs.name=$ohs_name ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain ImportConfig Oms $file_in -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  #print GETPROPOMS "$repos_passwd\n";
  #print GETPROPOMS "$regPassword\n";
  close(GETPROPOMS);

  print "Please bounce the OMS for changes to take effect.\n";
  write_to_file($emctl_log, "DEBUG    :: emctl importConfig oms: Completed");

  return($EMCTL_DONE);

}

# 
# getProxyDetailsOMS
#   
sub getProxyDetailsOMS()
{
  write_to_file($emctl_log, "DEBUG    :: emctl getproxydetails oms: Started");

  local (*args) = @_;

  shift(@args);                  # -- shift out getproxydetails...
  shift(@args);                  # -- shift out oms ...

  if(@args gt 0)
  {
    return($EMCTL_BAD_USAGE);
  }

  checkAndSetMasInfo();
  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Dapp.name=$app_name ".
              "-Djava.net.preferIPv4Stack=true ".
              "oracle.sysman.emctl.oms.EmctlMain GetProxyDetails Oms -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl getproxydetails oms: Completed");

  return($EMCTL_DONE);

}

# 
# setProxyDetailsOMS
#   
sub setProxyDetailsOMS()
{
  write_to_file($emctl_log, "DEBUG    :: emctl setproxydetails oms: Started");

  local (*args) = @_;

  shift(@args);                  # -- shift out setproxydetails...
  shift(@args);                  # -- shift out oms ...

  if(@args gt 0)
  {
    return($EMCTL_BAD_USAGE);
  }

  checkAndSetMasInfo();

  my $proxyHost;
  my $protxyPort;
  my $proxyRealm;
  my $dontProxyFor;
  my $proxyUser;
  my $proxyPwd;

  print STDOUT "Please provide the following proxy details.\n";
  print STDOUT "Proxy Host: ";
  chomp($proxyHost = <STDIN>);
  print STDOUT "Proxy Port: ";
  chomp($proxyPort = <STDIN>);
  print STDOUT "Proxy Realm: ";
  chomp($proxyRealm = <STDIN>);
  print STDOUT "Don't Proxy For: ";
  chomp($dontProxyFor = <STDIN>);
  print STDOUT "Proxy Username: ";
  chomp($proxyUser = <STDIN>);
  $proxyPwd = EmctlCommon::promptUserPasswd("Proxy Password: ");

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Dapp.name=$app_name ".
              "-Djava.net.preferIPv4Stack=true ".
              "oracle.sysman.emctl.oms.EmctlMain SetProxyDetails Oms \"$proxyHost\" \"$proxyPort\" \"$proxyRealm\" \"$dontProxyFor\" \"$proxyUser\" -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n".
                   "$proxyPwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl setproxydetails oms: Completed");

  return($EMCTL_DONE);

}

# 
# removeProxyDetailsOMS
#   
sub removeProxyDetailsOMS()
{
  write_to_file($emctl_log, "DEBUG    :: emctl removeproxydetails oms: Started");

  local (*args) = @_;

  shift(@args);                  # -- shift out removeproxydetails...
  shift(@args);                  # -- shift out oms ...

  if(@args gt 0)
  {
    return($EMCTL_BAD_USAGE);
  }

  checkAndSetMasInfo();
  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "-Dapp.name=$app_name ".
              "-Djava.net.preferIPv4Stack=true ".
              "oracle.sysman.emctl.oms.EmctlMain RemoveProxyDetails Oms -logfile $emctl_log -auth";

  open(GETPROPOMS, "|$javaCall");
  print GETPROPOMS "$mas_passwd\n";
  close(GETPROPOMS);

  write_to_file($emctl_log, "DEBUG    :: emctl removeproxydetails oms: Completed");

  return($EMCTL_DONE);

}


# 
# getMessageDetailsOMS
#   
sub getMessageDetailsOMS()
{
  write_to_file($emctl_log, "DEBUG    :: emctl getmessagedetails oms: Started");

  local (*args) = @_;

  shift(@args);                  # -- shift out getmessagedetails...
  shift(@args);                  # -- shift out oms ...

  my $class_path = "$CLASSPATH".
                   "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar";

  my $oc4jLoc = $oracle_instance . "/OC4JComponent/" . $oc4j_name;

  my $cmd = "$JAVA_HOME/bin/java -cp $class_path " .
#            "-DBASE_DIR=$oracle_instance/OC4JComponent/$oc4j_name ".
            "-DORACLE_HOME=$mas_oracle_home ".
            "-DBASE_DIR=$oc4jLoc ".
            "oracle.sysman.emctl.logging.GetMessageDetails @args";

  system($cmd);

  write_to_file($emctl_log, "DEBUG    :: emctl getmessagedetails oms: Completed");

  return($EMCTL_DONE);

}

sub checkAndSetOracleInstance()
{
  if($oc4j_name ne "oc4j_em")
  {
    $oracle_instance = $ENV{'EM_MAS_INSTANCE_HOME'};
    $emctl_log = "$oracle_instance/OC4JComponent/$oc4j_name/sysman/log/emctl.log";
  }
}

sub setproperty()
{
  my $property_type = shift;
  my $property_name = shift;
  my $property_value = shift;

  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
               "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain SetProperty Oms $property_name $property_value $property_type -logfile $emctl_log -auth 1>> $emctl_log";

  open(SETPROPOMS, "|$javaCall");
  print SETPROPOMS "$mas_passwd\n";
  close(SETPROPOMS);

  my $cmdStatus1 = $?;
  $cmdStatus1 = $cmdStatus1>>8;
  return $cmdStatus1;
}

sub getproperty()
{
  my $property_type = shift;
  my $property_name = shift;
  my @returnValues;
  my $ignore_error = 0;
  my $errorBuf = "";

  
  my $log = "$oracle_instance/OC4JComponent/$oc4j_name/sysman/log/temp.log";
  unlink ($log);
  $javaCall = "$JAVA_HOME/bin/java ".
              "-cp $CLASSPATH ".
              "-Dmas.user=$mas_user ".
              "-Dmas.connurl=$mas_connurl ".
              "-Doracle.instance=$oracle_instance ".
              "-DORACLE_HOME=$mas_oracle_home ".
              "oracle.sysman.emctl.oms.EmctlMain GetProperty Oms $property_name $property_type -logfile $emctl_log -auth > $log 2>$log";
   
  #open(LOG, ">> $emctl_log");
  open(GETPROPOMS, "| $javaCall  ");
  print GETPROPOMS "$mas_passwd\n";
  close(GETPROPOMS);

  open(LOG, "<$log");
  my $ret = "";
  while (<LOG>) 
  {
     #print LOG $_;
     if (/OMS Property Value = /) 
     {
          my @res =  split(/=/,$_);
          $ret = $res[1];
          $ignore_error = 1;
     }
     elsif (/No Such Property exists/)
     {
          $ignore_error = 1;
     }
     else
     {
          $errorBuf = $errorBuf . $_;
     }
  }
  close(LOG);
  unlink ($log);
  chomp($ret);

  if($ignore_error == 1)
  {
    $errorBuf = "";
  }

  push(@returnValues,trim($ret));
  push(@returnValues,$errorBuf);

  return @returnValues;
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
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
