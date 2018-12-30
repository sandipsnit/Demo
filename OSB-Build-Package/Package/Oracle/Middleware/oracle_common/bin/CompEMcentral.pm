# $Header: CompEMcentral.pm 28-mar-2008.02:09:15 neearora Exp $
#
# Copyright (c) 2001, 2008, Oracle. All rights reserved.  
#
#    NAME
#      CompEMcentral.pm - module that implements all emctl options for central
#      install.
#
#    DESCRIPTION
#       Top level module that implements the emctl options for 'central' install
#
#    MODIFIED   (MM/DD/YY)
#       neearora 03/28/08 - bug 6889015
#       jashukla 11/27/07 - replace jdbc14 with odjcb5.jar
#       djoly    11/15/07 - remove old ascontrol support
#       dgiaimo  04/11/07 - Finishing refactoring
#       dgiaimo  03/06/07 - Removing INSTALL_TYPE_* references
#       denath   03/07/07 - Bug fix 5920273. Added and Initialized EMDiag
#                           module.
#       neearora 02/22/07 - fixed path of emVersion.xml
#       mbhoopat 02/15/07 - Adding ojdl.jar and dms.jar to classpath
#       snathan  01/29/07 - removing UpdateOmsConfig
#       zmi      01/03/07 - Add connector package.
#       ssherrif 12/26/06 - Fixing path to emVersion.xml after M8, Bug 5711715
#       snathan  09/06/06 - 
#       rdabbott 07/28/06 - fix header
#       tsubrama 08/01/06 - adding UpdateOmsConfig
#       smodh    01/20/06 - Replace classes12.jar with ojdbc14.jar 
#       shianand 11/14/05 - fix bug 4514168
#       kmanicka 08/22/05 - add EmKeyCmds
#       neearora 08/17/05 - Bug 4241177. Implemented banner
#       shianand 07/09/05 - Refactoring Secure Commands 
#       rkpandey 08/24/04 - Type Registry Added 
#      kduvvuri  05/05/2004 - Created. 
#      kduvvuri 04/07/28/2004 - add getVersion.
#

package CompEMcentral;
use EMomsCmds;
use EmKeyCmds;
use AgentStatus;
use AgentMisc;
use AgentDeploy;
use AgentSubAgent;
use EMAgent;
use EmCommonCmdDriver;
use EmctlCommon;
use RegisterTType;
use File::Copy cp;
use SecureOMSCmds;
use EMconnectorCmds;
use EMDiag;

$EMHOME=getEMHome();
$ENV{'EMHOME'} = $EMHOME;
$EM_OC4J_HOME=getOC4JHome();

sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);
  #cmdList is a list containing all the command implementors.
  $self->{cmds} = [ EMomsCmds->new(), 
                    AgentStatus->new(),AgentMisc->new(),
                    AgentSubAgent->new(),AgentDeploy->new(),
                    RegisterTType->new(),
                    EmKeyCmds->new(),
                    EMconnectorCmds->new(),
                    EMDiag->new(),
                    SecureOMSCmds->new() ] ;
  return $self;
}

sub doIT {
   my $self = shift;
   #print "from sub routine doIT of agent.pm ,  @_\n";
   $refCmds = $self->{cmds};
   $cmdDriver = EmCommonCmdDriver->new();  
   $result = $cmdDriver->doIT($refCmds, \@_);
   return $result;
}

sub usage {
  #print "this is usage from CompEMcentral.pm\n";
  print "   Oracle Enterprise Manager 11g Grid Control commands:\n";
  my $self = shift;
  $refCmds = $self->{cmds};
  $cmdDriver = EmCommonCmdDriver->new();
  $result = $cmdDriver->usage($refCmds, \@_); 
}

sub getVersion {
  #print "this is Version from CompEMcentral.pm\n";
  my $self = shift;
  $refVars = [ EMomsCmds->new(), EMAgent->new() ];
  $cmdDriver = EmCommonCmdDriver->new();
  $result = $cmdDriver->getVersion($refVars, \@_);
}

sub banner {
  my $relVer = "11.1.0.2.0";
  my $prodVer = "11g";
  my $coreVer;
  my $beginYear = "1996";
  my $endYear = "2008";

  my $inFile = "$ORACLE_HOME/sysman/config/emVersion.xml";

  if(-e $inFile)
  {
    $CP = getClassPath();

    $javaStr = "$JAVA_HOME/bin/java ".
               "-cp $CP ".
               "-DEMHOME=$EMHOME ".
               "-DORACLE_HOME=$ORACLE_HOME ".
               "oracle.sysman.emdrep.util.EMVersion $inFile";

    my @result = `$javaStr`;

    if (@result)
    {
      my $count = scalar(@result);
      my $i=0;
      while( $i < $count)
      {
        @comp = split /\s+/, $result[$i];
        if( lc($comp[0]) eq "releaseversion")
        {
          $relVer = $comp[1];
        }
        elsif( lc($comp[0]) eq "productversion")
        {
          $prodVer = $comp[1];
        }
        elsif( lc($comp[0]) eq "coreversion")
        {
          $coreVer = $comp[1];
        }
        elsif( lc($comp[0]) eq "copyrightbeginningyear")
        {
          $beginYear = $comp[1];
        }
        elsif( lc($comp[0]) eq "copyrightendingyear")
        {
          $endYear = $comp[1];
        }
        $i = $i + 1;
      }
    }
  }
  print "Oracle Enterprise Manager ".$prodVer." Release ".$relVer." ".$banner_add." \n";  
  print "Copyright (c) ".$beginYear.", ".$endYear ." Oracle Corporation.  All rights reserved.\n";
  print "$DB_URL\n" if (defined($DB_URL));
  print "$IAS_URL \n" if (defined($IAS_URL));

  if($DEBUG_ENABLED)
 {
    print "NOHUP Files are $AGENT_NOHUPFILE | $DB_NOHUPFILE | $IAS_NOHUPFILE \n";
  }
}

sub getWebUrl {
  # Ideally we should return the URL for the agent/central oms..
  return "NULL";
}

sub getOC4JHome {
 $oc4jHome = "$EMDROOT/sysman/j2ee";

# die "OC4J Configuration issue. $oc4jHome not found. \n" unless( -e "$oc4jHome" );

 print "OC4J HOME ==================  $oc4jHome\n"  if $DEBUG_ENABLED;

 return $oc4jHome;
}

sub validateOC4JHomeExists {
  $oc4jHome = getOC4JHome();

  die "OC4J Configuration issue. $oc4jHome not found. \n" unless( -e "$oc4jHome" );
}

sub getClassPath {
  $classPath = "$ORACLE_HOME/jdbc/lib/ojdbc5.jar$cpSep".
               "$ORACLE_HOME/jdbc/lib/nls_charset12.jar$cpSep".
               "$ORACLE_HOME/sysman/jlib/emagentSDK.jar$cpSep".
               "$ORACLE_HOME/sysman/jlib/emCORE.jar$cpSep".
               "$ORACLE_HOME/sysman/jlib/log4j-core.jar$cpSep".
               "$ORACLE_HOME/sysman/jlib/emCORE.jar$cpSep".
               "$ORACLE_HOME/lib/xmlparserv2.jar$cpSep".
               "$ORACLE_HOME/dms/lib/ojdl.jar$cpSep".
               "$ORACLE_HOME/dms/lib/dms.jar";

  return $classPath;
}

sub getEMHome {
  my $emHome = $EMDROOT;
  my $topDir = &EmctlCommon::getLocalHostName();

  print "EM HOME ROOT:  ".$ORACLE_HOME."/".$topDir."\n" if $DEBUG_ENABLED;

  if ( defined($ENV{EMSTATE}) && $ENV{EMSTATE} ne "" )
  {
    $emHome = $ENV{EMSTATE};
  }
  elsif( $HOST_SID_OFFSET_ENABLED eq "host_sid" )
  {
    my $oracleSid = $ENV{ORACLE_SID};
    die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);

    $emHome = $ORACLE_HOME."/".$topDir."_".$oracleSid;
    $ENV{EMSTATE} = $emHome;
  }
  elsif( $HOST_SID_OFFSET_ENABLED eq "host_only" )
  {
    $emHome = $ORACLE_HOME."/".$topDir;
    $ENV{EMSTATE} = $emHome;
  }
  else # Reinforcing the default ...
  {
    $emHome = $EMDROOT;
  }

  #EM_TMP_DIR is valid only after a call to getEMHome.
  $EM_TMP_DIR = "$emHome";
  # Nohup file when only the agent is running.
  $AGENT_NOHUPFILE="$emHome/sysman/log/emagent.nohup";
  $PID_FILE="$emHome/emctl.pid";
#  die "EM Configuration issue. $emHome not found. \n" unless( -e "$emHome" );

  &EmctlCommon::setFormFactor($emHome);

  print "EMHOME ==================  $emHome\n"  if $DEBUG_ENABLED;
  return $emHome;
}

sub validateEMHomeExists {
  $emHome = getEMHome();

  die "EM Configuration issue. $emHome not found. \n" unless( -e "$emHome" );
}

1;
