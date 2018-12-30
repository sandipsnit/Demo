#
#  $Header: EmKeyCmds.pm 27-feb-2008.07:43:19 pchebrol Exp $
#
#
# Copyright (c) 2003, 2008, Oracle. All rights reserved.  
#
#    NAME
#      EmKeyCmds.pm - Secure OMS Perl Module
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    pchebrol    02/27/08 - Bug 6826173 - Prompt mas username
#    pchebrol    12/11/07 - Cut over to oracle.sysman.emctl.config.oms.EMKeyCmds class
#    rpinnama    11/01/07 - Support reading sensitive properties
#    smodh       12/14/06 - pass instanceDir to be used by EmKeyUtil.java
#    shianand    09/25/06 - fix bug 5520464
#    shianand    09/08/06 - fix bug 5518632 (fix configuring of emkey for RAC DB)
#    shianand    07/08/06 - fix bug 5375475
#    shianand    04/12/06 - fix bug 5158248 
#    smodh       01/20/06 - Replace classes12.jar with ojdbc14.jar 
#    kmanicka    08/30/05 - kmanicka_emkey_fix2
#    kmanicka    21/08/05 - Created
#
#


package EmKeyCmds;

use English;
use strict;
use vars '*args';

use EmCommonCmdDriver;
use EmctlCommon;
use Getopt::Long;


my $INSTANCE_HOME     = $ENV{EM_INSTANCE_HOME};
my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $mas_connurl       = $ENV{'EM_MAS_CONN_URL'};
my $oc4j_name         = $ENV{'EM_OC4J_NAME'};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $isRacNode         = "false";
my $racStateDir       = "";

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

    my $argCount  = @$rargs;
    if ($argCount >= 2  && $rargs->[1] eq "emkey" &&
                 ($rargs->[0] eq "config" || $rargs->[0] eq "status"))
    {
        if($rargs->[2] eq "-help")
        {
            usage();
            exit(0);
        }
        my $extra_options = "";
        if($rargs->[0] eq "status")
        {
            $extra_options = "-status";
        }
        shift(@$rargs);
        shift(@$rargs);
        my $JAVA_STRING = getEmKeyJavaString();
        my $RUN_STRING = "$JAVA_STRING $extra_options @$rargs";

        my $rc = 0xffff & system($RUN_STRING);
        $rc >>= 8;

        exit($rc);
    }
    else
    {
        return $EMCTL_UNK_CMD;
    }
}

sub usage
{
  print "Em Key Commands Usage : \n";
  print "emctl status emkey [-sysman_pwd <pwd>] [-mas_user <username> -mas_pwd <pwd>]\n";
  print "emctl config emkey -copy_to_credstore [-from_file <filename> | -sysman_pwd <pwd>] [-mas_user <username> -mas_pwd <pwd>]\n";
  print "emctl config emkey -copy_to_repos [-from_file <filename> | -mas_user <username> -mas_pwd <pwd>] [-sysman_pwd <pwd>]\n";
  print "emctl config emkey -remove_from_repos [-sysman_pwd <pwd>]\n";
  print "emctl config emkey -copy_to_file <filename> [-from_repos -sysman_pwd <pwd> | -mas_user <username> -mas_pwd <pwd>] \n";
  print "\n";
}

sub getEmKeyJavaString
{
  my $emConsoleMode = &SecureUtil::getConsoleMode();
  my $CLASSPATH     = &SecureUtil::getConsoleClassPath($emConsoleMode);
 
  my $emHome = "";

  if ($isRacNode eq "true")
  {
    $emHome = $racStateDir;
  } 
  else
  {
    $emHome = &SecureUtil::getEMHome($emConsoleMode);
  }

  my $JAVA_STRING = "$JAVA_HOME/bin/java -classpath $CLASSPATH". 
                    "$cpSep$ORACLE_HOME/sysman/jlib/emcore_client.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxframework.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/lib/jmxspi.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/jps-api.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/jps-mas.jar".
                    "$cpSep$ORACLE_HOME/j2ee/home/lib/servlet.jar".
                    "$cpSep$ORACLE_HOME/jlib/adminserver.jar ".
                    "-DORACLE_HOME=$ORACLE_HOME ".
                    "-Doracle.instance=$INSTANCE_HOME ".
                    "-Dmas.connurl=$mas_connurl " .
                    "-Doc4j.component.name=$oc4j_name " .
                    "oracle.sysman.emctl.config.oms.EMKeyCmds ";
  return $JAVA_STRING;
}


1;
