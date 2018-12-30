#  $Header:
#
# Copyright (c) 2001, 2008, Oracle. All rights reserved.  
#
#    NAME
#
#    DESCRIPTION
#
#    MODIFIED   (MM/DD/YY)
#       zmi    04/09/08 - bug 6952417.
#       yangwa 02/19/08 - 
#       yangwa 02/11/08 - bug 6778094.
#       yangwa 01/09/08 - bug 6734208
#       yangwa 10/31/07 - add a new cmd emctl get_connectors.
#       yangwa 10/19/07 - version is used for connector dir.
#       jashuk 09/21/07 - Uptake to tip0912
#       yangwa 09/20/07 - bug-6440276
#       yahuan 05/08/07 - change toplink.jar to toplink-core.jar
#       yahuan 03/21/07 - change classpath
#       minfan 02/07/07 - update ojdbc jar path to env var
#       mbhoop 02/09/07 - Adding emagentSDK.jar to classpath
#       zmi    01/08/07 - Switch JDBC lib to ojdbc14.jar. 
#       rbelav 12/11/06 - Bug 5582424.
#       zmi    08/16/06 - Created.

package EMconnectorCmds;
use EmCommonCmdDriver;
use EmctlCommon;
use Getopt::Long;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $MAS_CONN_URL = $ENV{"EM_MAS_CONN_URL"};
my $osType = get_osType();
my $syslib = "$ORACLE_HOME/lib"; 
my $sysjlib = "$ORACLE_HOME/jlib"; 
my $jlib = "$ORACLE_HOME/sysman/jlib";
my $jdbclib= "$ORACLE_HOME/jdbc/lib";
my $classpath = "";

my $server = "";
my $port = "";
my $sid = "";
my $reposUsername = "";
my $reposPasswd = "";
my $masUsername = "";
my $masPasswd = "";
my $connectionString = "";

if ($osType eq 'WIN') {
  $classpath = "$jlib/emCORE.jar;$syslib/dms.jar;$syslib/ojdl.jar;$jlib/emagentSDK.jar;$syslib/java/shared/oracle.toplink/11.1.1.0.0/toplink-core.jar;$syslib/xml.jar;$jlib/log4j-core.jar;$jdbclib/ojdbc5.jar;$syslib/xmlparserv2.jar;$syslib/servlet.jar;$ORACLE_HOME/j2ee/home/oc4j.jar;$ORACLE_HOME/lib/java/api/jaxb-api.jar";
}
else {
  $classpath = "$jlib/emCORE.jar:$jlib/emagentSDK.jar:$syslib/java/shared/oracle.toplink/11.1.1.0.0/toplink-core.jar:$syslib/xml.jar:$jlib/log4j-core.jar:$jdbclib/ojdbc5.jar:$syslib/xmlparserv2.jar:$syslib/servlet.jar:$ORACLE_HOME/j2ee/home/oc4j.jar:$ORACLE_HOME/lib/java/api/jaxb-api.jar";
}

sub get_osType
{
    if (( $^O eq "Windows_NT") ||
        ( $^O eq "MSWin32")) {
        return "WIN";
    }

    my $os = `uname -s`;
    my $ver = `uname -r`;
    chomp ($os);

    if ( $os eq "SunOS" ) {
        if ( chomp($ver) !~ /^4./ ) {
            return "SOL";
        }
    } elsif ( $os eq "HP-UX" ) {
        return "HP";
    } elsif ( $os eq "Linux" ) {
        return "LNX";
    } elsif ( $os eq "AIX" ) {
        return "AIX";
    } elsif ( $os eq "OSF1" ) {
        return "OSF1";
    } elsif ( $os eq "Darwin" ) {
        return "MAC OS X";
    } else {
        # Unsupported Operating System
        return -1;
    }
}

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
   #print "doIT of EMconnectorCmds: self is $classname, args passed @$rargs\n";
   if ( $rargs->[1] eq "connector" )
   {
     #print "Processing <options> connector \n";

     if ( $rargs->[0] eq "register_connector" )
     {
	 #print "Registering connector\n";
	 $rargs->[$argCount] = $ORACLE_HOME;
	 $result = registerConnector($rargs);
     }
     elsif ( $rargs->[0] eq "register_template" )
     {
	 #print "Registering template\n";
	 $result = registerT($rargs);
     }
     elsif ( $rargs->[0] eq "extract_jar" )
     {
	 #print "Extracting jar\n";
	 $rargs->[$argCount] = $ORACLE_HOME;
	 $result = extractJar($rargs);
     }
     elsif ( $rargs->[0] eq "get_connectors" )
     {
        #print "Get connectors\n";
        $result = get_connectors($rargs); 
     }
   }
   return $result;
}

#
# registerConnector
#
sub registerConnector()
{
  print("Registering connector ...\n");
  my $javaStr = "";

  my $deployfile = "";

    GetOptions (
        'dd=s' => \$deployfile,
        's=s' => \$server,
        'p=s' => \$port,
        'sid=s' => \$sid,
        'repos_user=s' => \$reposUsername,
        'repos_pwd=s' => \$reposPasswd,
        'mas_user=s' => \$masUsername,
        'mas_pwd=s' => \$masPasswd,
        'cs=s' => \$connectionString
    );
    if((not $connectionString) && (not $server || not $port || not $sid)){
        print "Connection string or <server, port, sid> required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $connectionString){
        $connectionString="//$server:$port/$sid";
    }
    
    if (not $deployfile){
        print "Connector Deployment Descriptor File (full path) : ";
        $deployfile = <STDIN>;
        chomp $deployfile;
    }
    if(not $deployfile){
        print "Connector Deployment Descriptor File required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $reposUsername){
        print "Enterprise Manager Repository Username : ";
        $reposUsername = <STDIN>;
        chomp $reposUsername;
    }
    if(not $reposUsername){
        print "Enterprise Manager Repository Username required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $reposPasswd){
        print "Enterprise Manager Repository Password : ";
        system("stty -echo");
        $reposPasswd = <STDIN>;
        chomp $reposPasswd;
        system("stty echo");
        print "\n";
    }
    if(not $reposPasswd){
        print "Enterprise Manager Repository Password required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $masUsername){
        print "MAS Username : ";
        $masUsername = <STDIN>;
        chomp $masUsername;
    }
    if(not $masUsername){
        print "MAS Username required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $masPasswd){
        print "MAS Passwrod : ";
        system("stty -echo");
        $masPasswd = <STDIN>;
        chomp $masPasswd;
        system("stty echo");
        print "\n";
    }
    if(not $masPasswd){
        print "MAS Password required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
  $javaStr = "$JAVA_HOME/bin/java ".
      "-cp $classpath".
      "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
      "$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxframework.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/lib/servlet.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
      "$cpSep$ORACLE_HOME/jlib/adminserver.jar".
      "$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar ".
      "-DORACLE_HOME=$ORACLE_HOME ".
      "-DMAS_CONN_URL=$MAS_CONN_URL ".
      "-DREPOS_USERNAME=$reposUsername ".
      "-DREPOS_PASSWORD=$reposPasswd ".
      "-DMAS_USERNAME=$masUsername ".
      "-DMAS_PASSWORD=$masPasswd ".
      "-DCONNECTION_STRING=$connectionString ".
      "oracle.sysman.connector.registry.api.ConnectorControl ".
      "register_connector $deployfile";
  
  $status = system($javaStr);
  $status = $status >> 8;
  return $status;
}

#
# registerT
#
sub registerT()
{
  print("Registering template ...\n");
  my $javaStr = "";

  my $xmlfile = "";
  my $connectorTypeName = "";
  my $connectorName = "";
  my $templateName = "";
  my $internalName = "";
  my $templateType = "";
  my $description = "";

    GetOptions (
        't=s' => \$xmlfile,
        's=s' => \$server,
        'p=s' => \$port,
        'sid=s' => \$sid,
        'repos_user=s' => \$reposUsername,
        'repos_pwd=s' => \$reposPasswd,
        'cs=s' => \$connectionString,
        'ctname=s' => \$connectorTypeName,
        'cname=s' => \$connectorName,
        'iname=s' => \$internalName,
        'tname=s' => \$templateName,
        'ttype=s' => \$templateType,
        'd=s' => \$description
    );
    
    if((not $connectionString) && (not $server || not $port || not $sid)){
        print "Connection string or <server, port, sid> required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $connectionString){
        $connectionString="//$server:$port/$sid";
    }
    
    if (not $xmlfile){
        print "Template File (full path) : ";
        $xmlfile = <STDIN>;
        chomp $xmlfile;
    }
    if(not $xmlfile){
        print "Template File required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $reposUsername){
        print "Enterprise Manager Repository Username : ";
        $reposUsername = <STDIN>;
        chomp $reposUsername;
    }
    if(not $reposUsername){
        print "Enterprise Manager Repository Username required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $reposPasswd){
        print "Enterprise Manager Repository Password : ";
        system("stty -echo");
        $reposPasswd = <STDIN>;
        chomp $reposPasswd;
        system("stty echo");
        print "\n";
    }
    if(not $reposPasswd){
        print "Enterprise Manager Repository Password required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $connectorTypeName){
        print "Connector Type Name : ";
        $connectorTypeName = <STDIN>;
        chomp $connectorTypeName;
    }
    if(not $connectorTypeName){
        print "Connector Type Name required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $connectorName){
        print "Connector Name : ";
        $connectorName = <STDIN>;
        chomp $connectorName;
    }
    if(not $connectorName){
        print "Connector Name required.\n";
        return($EMCTL_BAD_USAGE);
    }

    if(not $internalName){
        print "Template Internal Name : ";
        $internalName = <STDIN>;
        chomp $internalName;
    }
    if(not $internalName){
        print "Template Internal Name required.\n";
        return($EMCTL_BAD_USAGE);
    }
        
    if(not $templateName){
        print "Template Name Displayed : ";
        $templateName = <STDIN>;
        chomp $templateName;
    }
    if(not $templateName){
        print "Template Name Displayed required.\n";
        return($EMCTL_BAD_USAGE);
    }    

    if(not $templateType){
        print "Template Type : ";
        $templateType = <STDIN>;
        chomp $templateType;
    }
    if(not $templateType){
        print "Template Type required.\n";
        return($EMCTL_BAD_USAGE);
    }    
    
    if(not $description){
        print "Description : ";
        $description = <STDIN>;
        chomp $description;
    } 
    
  $javaStr = "$JAVA_HOME/bin/java ".
      "-cp $classpath ".
      "-DORACLE_HOME=$ORACLE_HOME ".
      "-DREPOS_USERNAME=$reposUsername ".
      "-DREPOS_PASSWORD=$reposPasswd ".
      "-DCONNECTION_STRING=$connectionString ".
      "oracle.sysman.connector.registry.api.ConnectorControl ".
      "register_template $xmlfile $connectorTypeName $connectorName $templateName $internalName $templateType $description";

  $status = system($javaStr);
  $status = $status >> 8;
  return $status;
}

#
# extractJar
#
sub extractJar()
{
  my $javaStr = "";
  my $deployfile = "";
  my $jarFile = "";

  print("\nExtracting jar ...\n");
  
  GetOptions (
        'jar=s' => \$jarFile,
        'dd=s' => \$deployfile
    );
    
  if (not $jarFile){
    print "Connector Jar File (full path) : ";
    $jarFile = <STDIN>;
    chomp $jarFile;
  }
  if(not $jarFile){
    print "Connector Jar File required.\n";
    return($EMCTL_BAD_USAGE);
  }
  if(not $deployfile){
    print "Connector Deployment Descriptor File (file name) : ";
    $deployfile = <STDIN>;
    chomp $deployfile;
  }
  if(not $deployfile){
    print "Connector Deployment Descriptor File required.\n";
    return($EMCTL_BAD_USAGE);
  }

  $javaStr = "$JAVA_HOME/bin/java ".
      "-cp $classpath ".
      "-DORACLE_HOME=$ORACLE_HOME ".
      "oracle.sysman.connector.registry.api.ConnectorControl ".
      "extract_jar $jarFile $deployfile";
    
    print "\n";

  $status = system($javaStr);
  $status = $status >> 8;
  return $status;
}

#
#get_connectors
#emctl get_connectors connector [-s <server>] [-p <port>] [-sid <database sid>] 
#      [-repos_user <repos username>] [-repos_pwd <repos password>] 
#      [-mas_user <mas username>] [-mas_pwd <mas password>]
#
sub get_connectors(){

    my $javaStr = "";
    
    GetOptions (
        's=s' => \$server,
        'p=s' => \$port,
        'sid=s' => \$sid,
        'repos_user=s' => \$reposUsername,
        'repos_pwd=s' => \$reposPasswd,
        'mas_user=s' => \$masUsername,
        'mas_pwd=s' => \$masPasswd,
        'cs=s' => \$connectionString,
    );
    
   if((not $connectionString) && (not $server || not $port || not $sid)){
        print "Connection string or <server, port, sid> required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $connectionString){
        $connectionString="//$server:$port/$sid";
    }
    
    if(not $reposUsername){
        print "Enterprise Manager Repository Username : ";
        $reposUsername = <STDIN>;
        chomp $reposUsername;
    }
    if(not $reposUsername){
        print "Enterprise Manager Repository Username required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $reposPasswd){
        print "Enterprise Manager Repository Password : ";
        system("stty -echo");
        $reposPasswd = <STDIN>;
        chomp $reposPasswd;
        system("stty echo");
        print "\n";
    }
    if(not $reposPasswd){
        print "Enterprise Manager Repository Password required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $masUsername){
        print "MAS Username : ";
        $masUsername = <STDIN>;
        chomp $masUsername;
    }
    if(not $masUsername){
        print "MAS Username required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
    if(not $masPasswd){
        print "MAS Passwrod : ";
        system("stty -echo");
        $masPasswd = <STDIN>;
        chomp $masPasswd;
        system("stty echo");
        print "\n";
    }
    if(not $masPasswd){
        print "MAS Password required.\n";
        return($EMCTL_BAD_USAGE);
    }
    
  $javaStr = "$JAVA_HOME/bin/java ".
      "-cp $classpath".
      "$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar".
      "$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxframework.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/lib/servlet.jar".
      "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
      "$cpSep$ORACLE_HOME/jlib/adminserver.jar".
      "$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar ".
      "-DORACLE_HOME=$ORACLE_HOME ".
      "-DMAS_CONN_URL=$MAS_CONN_URL ".
      "-DREPOS_USERNAME=$reposUsername ".
      "-DREPOS_PASSWORD=$reposPasswd ".
      "-DMAS_USERNAME=$masUsername ".
      "-DMAS_PASSWORD=$masPasswd ".
      "-DCONNECTION_STRING=$connectionString ".
      "oracle.sysman.connector.registry.api.ConnectorControl ".
      "get_connectors";
    
    $status = system($javaStr);
    $status = $status >> 8;
    return $status;
}

sub usage
{
    print "EM Connector Commands Usage : \n";
    register_connector_usage();
    register_template_usage();
    extract_jar_uasge();
}

sub register_connector_usage()
{
    print "\temctl register_connector connector [-dd <connectorType.xml>] [-cs <connection string>] [-s <server>] [-p <port>] [-sid <database sid>] [-repos_user <repos username>] [-repos_pwd <repos password>] [-mas_user <mas username>] [-mas_pwd <mas password>]\n";
    print "\t\t-dd\t\tConnector Deployment Descriptor File(full path)\n";
    print "\t\t-cs\t\tConnection String\n";
    print "\t\t-s\t\tDatabase Server\n";
    print "\t\t-p\t\tDatabase Listener Port\n";
    print "\t\t-sid\t\tDabase SID\n";
    print "\t\t-repos_user\tEnterprise Manager Repository Username\n";
    print "\t\t-repos_pwd\tEnterprise Manager Repository Password\n";
    print "\t\t-mas_user\tMAS Username\n";
    print "\t\t-mas_pwd\tMAS Password\n";
    print "\n";
}

sub register_template_usage()
{
    print "\temctl register_template connector [-t <template.xml>] [-cs <connection string>] [-s <server>] [-p <port>] [-sid <database sid>] [-repos_user <repos username>] [-repos_pwd <repos password>] [-ctname <connectorTypeName>] [-cname <connectorName>] [-iname <internalName>] [-tname <templateName>] [-ttype <templateType>] [-d <description>]\n";
    print "\t\t-t\t\tTemplate(full path)\n";
    print "\t\t-cs\t\tConnection String\n";
    print "\t\t-s\t\tDatabase Server\n";
    print "\t\t-p\t\tDatabase Listener Port\n";
    print "\t\t-sid\t\tDabase SID\n";
    print "\t\t-repos_user\tEnterprise Manager Repository Username\n";
    print "\t\t-repos_pwd\tEnterprise Manager Repository Password\n";
    print "\t\t-ctname\t\tConnector Type Name\n";
    print "\t\t-cname\t\tConnector Name\n";
    print "\t\t-iname\t\tTemplate Internal Name\n";
    print "\t\t-tname\t\tTemplate Name Displayed\n";
    print "\t\t-ttype\t\tTemplate Type\n";
    print "\t\t\t<templateType> 1 - inbound transformation\n";
    print "\t\t\t<templateType> 2 - outbound transformation\n";
    print "\t\t\t<templateType> 3 - XML outbound transformation\n";
    print "\t\t-d\t\tDescription\n";
    print "\n";
}

sub extract_jar_uasge()
{
    print "\temctl extract_jar connector [-jar <jarfile>] [-dd <connectorType.xml>]\n";
    print "\t\t-jar\t\tConnector Jar File(full path)\n";
    print "\t\t-dd\t\tConnector Deployment Descriptor File\n";
    print "\n";
}

sub DESTROY {
    my $self = shift;
}

1;
#    
