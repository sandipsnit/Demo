#!/usr/local/bin/perl
#
# $Header: emagent/scripts/unix/emctl.pl.template /st_emagent_10.2.0.1.0/17 2008/10/31 18:48:46 bkovuri Exp $
#
# emctl.pl
#
# Copyright (c) 2002, 2008, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      emctl.pl - Single controller script for various consoles and agent
#
#    DESCRIPTION
#      Single entry point script for controlling various consoles and agent
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    bkovuri     10/29/08 - Update copyright year - 7460158
#    sunagarw    08/14/08 - Get password from stdin
#    sunagarw    07/24/08 - Fix deploy to accept oms host:port
#    mgoodric    06/20/08 - moved dumpENV logic to LaunchEMagent.pm (per njagathe)
#    njagathe    06/02/08 - Update version to 10.2.0.5
#    mgoodric    05/12/08 - add debugging of LD_LIBRARY_PATH
#    sunagarw    03/11/08 - XbranchMerge sunagarw_bug-5550295 from main
#    neearora    05/23/07 - Update version to 10.2.0.4.0
#    njagathe    02/23/07 - Update version to 10.2.4.0.0
#    schoudha    12/20/06 - Bug-5726004-Change banner for emctl
#    njagathe    11/03/06 - Update copyright year
#    kduvvuri    08/02/06 - fix 4595924 - instantiate lib path.
#    jaysmith    08/04/06 - Backport kduvvuri_bug-4595924 from main
#    smodh       07/20/06 - change version to 10.2.0.3.0
#    smodh       07/20/06 - Backport smodh_bug_4769194_agent from main
#    misun       08/16/06 - update DB version number
#    kduvvuri    12/30/05 - XbranchMerge kduvvuri_bug-4893236 from main
#    smodh       12/11/05 - change version to 10.2.0.2.0
#    njagathe    10/27/05 - XbranchMerge njagathe_bug-4690651 from main
#    kduvvuri    07/25/05 - pass cmd arguments to banner.
#    vnukal      07/13/05 - desupporting /net base deploys
#    kduvvuri    07/12/05 - define result.
#    kduvvuri    07/12/05 - remove redundant call to getEMHome.
#    kduvvuri    07/12/05 - fix 3864990.
#    shianand    07/06/05  -
#    rzazueta    02/20/05  - Update versions
#    sksaha      01/05/05  - Fix bug-3958424 multi-word argument
#    kduvvuri    11/09/04  - exit with error code 100 on unknown command.
#    vnukal      09/17/04  - reaping pid on Windows
#    kduvvuri    08/23/04  - remove dead code.
#    djoly       08/18/04  - Break up cemd
#    kduvvuri    07/28/04  - add getVersion.
#    kduvvuri    07/26/04  - remove temp debugging.
#    kduvvuri    07/22/04  - set EMCTL_PLUG_AND_PLAY.
#    kduvvuri    07/19/04  - temp debugging.
#    kduvvuri    07/09/04  - export EXITFILE in the env.
#    aaitghez    06/08/04 -  bug 3656322. Cleanup perl warnings
#    kduvvuri    06/08/04 - activate plug and play only if EMCTL_PLUG_AND_PLAY
#                           is set.
#    kduvvuri    06/01/04 - activate dbconsole thru CONSOLE_CFG
#    njagathe    05/19/04 - Update for control agent
#    asawant     05/14/04 - Fix emctl setpasswd
#    djoly       05/14/04 - Update core reference
#    kduvvuri    05/12/04 - change the umask 037.(bug 3620254)
#    kduvvuri    05/10/04 - fix bug 3620254.
#    asawant     05/07/04 - add setpasswd verb to dbconsole and oms
#    kduvvuri    05/06/04 - introduce agent plug and play module.
#    jsutton     04/12/04 - fix AS Control name in output
#    gan         04/13/04 - check repository mode
#    rzazueta    03/22/04 - Fix 2809920: display help
#    jsutton     01/26/04 - issue w/ startup on heavily-loaded systems
#    vnukal      01/22/04 - fix started reporting behaviour
#    gachen      01/09/04 - access permission
#    kduvvuri    01/08/04 - unset PATH in reloadEMD only on non windows
#    njagathe    12/31/03 - bug-3343940. perl taint
#    aaitghez    12/29/03 - bug 3339329. add sysman/admin/scripts and bin to
#    ancheng     01/02/04 - change copyright text
#    aaitghez    12/23/03 - use delete not undef to unset env var
#    rzazueta    12/16/03 - Remove space in ps command arguments
#    vnukal      12/01/03 - creating service for DBConsole
#    rzazueta    12/01/03 - Deprecate password to shutdown DBConsole
#    vnukal      11/20/03 - error on agent down
#    vnukal      11/17/03 - cr comments
#    vnukal      11/14/03 - NFS install changes
#    jabramso    11/12/03 - EXE extension on nmei
#    jabramso    11/11/03 - copy ilint not error
#    jabramso    11/10/03 - move temp files back to cwd
#    rzazueta    11/05/03 - Fix bug 3164505: Deprecate password to shutdown
#    jabramso    11/05/03 - add check for missing ilint executable
#    rzazueta    11/04/03 - Fix bug 3174706: change status return codes
#    jabramso    11/04/03 - chdir ilint
#    jabramso    11/03/03 - NT Bug requires chdir for ilint
#    rzazueta    10/31/03 - Fix bug 3127435: net command path
#    njagathe    10/30/03 - Also unset REMOTE_EMDROOT
#    njagathe    10/29/03 - Allow AGENT_STATE to be computed instead of being
#    vnukal      10/22/03 - servicename not mandatory for dbconsole deploy
#    vnukal      10/20/03 - deploy actions moved to top
#    aaitghez    10/19/03 - bug 3201173
#    vnukal      10/10/03 - deploy functionality
#    rzazueta    10/14/03 - Fix bug 3146570
#    jsutton     10/15/03 - Fix iAS console control
#    rzazueta    10/06/03 - Fix bug 3119098: change banners and versions
#    jsutton     10/01/03 - Fix substitutions
#    aaitghez    09/30/03 - onde argument to getemhome
#    aaitghez    09/30/03 - change usage message
#    aaitghez    09/29/03 - review comments
#    aaitghez    09/26/03 - bug 3095057
#    rzazueta    09/30/03 - Add startifdown, remove restart iasconsole
#    dmshah      09/17/03 - Code review changes
#    dmshah      09/15/03 - Integration testing changes
#    dmshah      09/03/03 - Moving checkAboutPage to the DBConsole.pm module
#    jtrichar    09/02/03 - porting from 401: jsutton's startup backoff
#    echolank    08/22/03 - merge from 401 to main
#    kduvvuri    08/20/03 - fix config agent
#    rzazueta    08/11/03 - Better error message for bug 3044441
#    rzazueta    08/06/03 - Fix bug 3044441
#    rpinnama    08/06/03 - Support secure dbconsole
#    rzazueta    08/04/03 - Fix bug 3070285
#    kduvvuri    07/28/03 - move supportedTZ to emwd.pl.template.
#    dkapoor     07/07/03 - use admin instead of ias_admin
#    dmshah      07/21/03 - internal command syntax to start agent is "agent"
#    dmshah      07/21/03 - Bug fix 3054810
#    dmshah      07/18/03 - Fixing EMDROOT var
#    jabramso    07/21/03 - ilint args
#    dmshah      07/10/03 -
#    dmshah      07/09/03 - Testing changes
#    dmshah      07/08/03 - Adding NT svc hookup for emctl/emwd
#    dmshah      07/08/03 - Bug fixes from 401 branch
#    kduvvuri    07/08/03 - merge fix for 2949193
#    kduvvuri    06/19/03  - fix updateTZ getTZ options
#    kduvvuri    06/18/03 -  code review comments.
#    kduvvuri    06/17/03 - get rid of code that reads supportedtzs.lst
#    kduvvuri    06/17/03 - add emctl config agent updateTZ and  getTZ
#    dmshah      06/26/03 - opmnctl fixes
#    dmshah      06/23/03 - fix bug 3015053
#    szhu        06/23/03 - Do not use fork() on NT
#    jpyang      06/20/03 - 9.0.4 update
#    dmshah      06/14/03 -
#    dmshah      06/09/03 - Reworking emctl code
#    dmshah      05/19/03 - Increasing the started wait time from 60 secs to 180 secs
#    dmshah      05/27/03 - Explicitly close stdin for rsh execution
#    dmshah      05/05/03 - Updating banner for CFS-RAC
#    njagathe    05/14/03 - Add reload dynamicproperties usage
#    njagathe    05/13/03 - Fix passing of args
#    njagathe    05/12/03 - Pass subcmds for reload
#    rzkrishn    04/30/03 - review comments
#    rzkrishn    04/29/03 - adding clearstate
#    njagathe    04/22/03 - Allow subrequests of status agent
#    dmshah      04/09/03 - Removing hardcoded pid 1 from dbaconsole stop
#    dmshah      04/06/03 - Fixing implicit shell launch
#    dmshah      04/02/03 - Adding func for monitoring dbConsole
#    dmshah      04/02/03 - grabtrans 'dmshah_fix_2849086_2'
#    dmshah      04/08/03 - Removing hardcoded pid from stopSAC
#    dmshah      04/07/03 - Review comments
#    dmshah      04/07/03 - Checking for exact return code during start agent/em
#    rpinnama    03/31/03 - Check if TZ is a supported TZ
#    dkapoor     03/26/03 - use 512M for MstartEM_SA
#    dmshah      03/26/03 - Review comments
#    dmshah      03/25/03 - Adding code to deploy DBConsole for CFS
#    vnukal      02/26/03 - Override for starting w/o NT service
#    hakali      02/20/03 - use oc4j j2ee
#    itarashc    02/25/03 - comment for runILINT
#    itarashc    02/17/03 - add ilint
#    kduvvuri    02/13/03 - use system instead of exec when doing emdctl reload
#    kduvvuri    01/28/03 - changes to start and stop of NT service
#    kduvvuri    01/27/03 - add NT Specific Macros
#    dkapoor     02/05/03 - use variable is condition
#    dkapoor     01/31/03 - use sa_setup variable
#    hakali      01/22/03 - use config instead of policy
#    aaitghez    01/13/03 - change EM version string
#    rzkrishn    01/14/03 - calling nohup on emsubagent
#    rzkrishn    01/14/03 - review changes : emsubagent redirecting to nohup
#    rzkrishn    01/13/03 - adding start, status, stop functionality for EM subagent
#    hakali      01/16/03 - mainsa setup
#    rzkrishn    01/10/03 - review changes
#    rzkrishn    01/10/03 - copying the comments
#    rzkrishn    01/09/03 - bug 2742104
#    rzkrishn    01/09/03 - including nodelevel
#    djoly       01/06/03 - Add a couple of properties for ias
#    skini       12/30/02 - Pass standalone mode to ias console
#    njagathe    01/09/03 - Set JAVA_HOME to JRE_HOME for agent environment
#    dmshah      01/02/03 - fix bug 2732042
#    vnukal      12/16/02 - separate out agent state directory
#    skini       12/30/02 - Pass standalone mode to ias console
#    njagathe    12/19/02 - Add JRE_HOME variable and use in LD_LIBRARY_PATH etc
#    dmshah      12/16/02 - Fixing status agent
#    dmshah      12/18/02 - Fixing bug 2719514.secure oms falls through the loop
#    dmshah      12/15/02 -
#    dmshah      12/13/02 - fixing start em hang
#    dmshah      12/13/02 - Only status blackout can have 2 args
#    itarashc    12/13/02 -
#    dmshah      12/12/02 - dmshah_common_emctl_main
#    dmshah      12/12/02 - Fixing command set message
#    dmshah      12/12/02 - fixing displayHelp
#    dmshah      12/11/02 - Renamed from emctl.pl to emctl.pl.template
#    dmshah      12/09/02 - start em is supported
#    dmshah      12/05/02 - Creation
#

use lib ("C:/Oracle/Middleware/oracle_common/bin");
use lib ("C:/Oracle/Middleware/oracle_common/sysman/admin/scripts");

use LWP::Simple;
use POSIX ":sys_wait_h";
# use Term::ReadKey; # We need to comment this out until PDC picks up Term
use LWP::UserAgent;
use HTTP::Response;
use HTML::TokeParser;
use URI;
use English;
use File::stat;
use File::Copy;
use Getopt::Std;

use EmctlCommon;

use EMAgent;
use EMDeploy;
use POSIX;

# setup the environment ...

umask 037;

my $EXIT_EMCTL_UNK_CMD = 100;
my $EXIT_EMCTL_BAD_USAGE = 101;
my $EXIT_EMCTL_NORMAL = 0;
my $result;
my $rresult;

$|=1; # Set AUTOFLUSH on

# bug fix 2603257
# Check for the euid with the uid obtained from stating this ...
# On Win NT, both $EUID and stat($0) should return 0 and hence this is a noop.
# REMOTE_EMDROOT is populated for NFS installs which usually has the owner of
# state directory different from the owner of the OUI installed EM home dir.

die "Cannot execute $0 since its userid does not match yours. \n" if (defined($ENV{REMOTE_EMDROOT}) && ($ENV{REMOTE_EMDROOT} eq "") && ( (stat($0))->uid ne $EUID ));

# get the action, component and argument count ...

$action = $ARGV[0];

$component = $ARGV[1];

# Handle multi-word arguments by enclosing them in double-quotes
$i=0;
foreach (@ARGV)
{
  if($ARGV[$i] =~ / /)
  {
    $ARGV[$i] = "\"" . $ARGV[$i] . "\"";
  }
  $i++;
}

if (lc($component) eq "em")
{
  $component = "iasconsole";
}

$argCount = scalar(@ARGV);


if (defined($ENV{EMSTATE}) && $ENV{EMSTATE} eq "")
{
    delete($ENV{EMSTATE});
}

# The following deploy block needs to be at the top to avoid a circular
# dependency between deploy actions AND directory presence validation.
if($action eq "deploy")
{
    if (($component eq "agent") or
        ($component eq "dbconsole"))
    {
       my $rc = deploy( \@ARGV );
       exit $rc;
    }
    else
    {
        printDeployUsage();
        exit 1;
    }
}

$EM_OC4J_HOME = getOC4JHome($component);
$EMHOME = getEMHome($CONSOLE_CFG);

print "OC4J home for $component is : $EM_OC4J_HOME.\n" if $DEBUG_ENABLED;
print "EM home for $component is : $EMHOME.\n" if $DEBUG_ENABLED;

if (lc($component) eq "iasconsole")
{
  $IAS_URL = getWebUrl($EM_OC4J_HOME, $EMHOME, $component);
}
elsif(lc($component) eq "dbconsole")
{
  $DB_URL = getWebUrl($EM_OC4J_HOME, $EMHOME, $component);
}

print "URL for $component is : $DB_URL |  $IAS_URL \n" if $DEBUG_ENABLED;

$ENV{'EMHOME'} = $EMHOME;
$reqPkg = "$EM_INSTALL_MODULE"."\.pm";
require $reqPkg;

$componentObj = $EM_INSTALL_MODULE->new(@ARGV);

if ( $componentObj->can('banner') )
{
  $componentObj->banner(\@ARGV);
}
else
{
  banner();
}

if ( $argCount == 1 && lc($ARGV[0]) eq "getversion" )
{
  $componentObj->getVersion();
  exit ($EXIT_EMCTL_NORMAL);
}

$rresult = $componentObj->doIT(@ARGV);

$resultType = ref($rresult);

if ( $resultType eq "ARRAY" )
{
  #Got a reference to an array
  $result = $rresult->[0];
  $exitCode = $rresult->[1];
}
else
{
  $result = $rresult;
  $exitCode = $EXIT_EMCTL_NORMAL;
}

if ( $result == $EMCTL_UNK_CMD )  #UNKNOWN_COMMAND
{
   $componentObj->usage();
   exit($EXIT_EMCTL_UNK_CMD);
}

if ( $result == $EMCTL_BAD_USAGE )
{
  exit($EXIT_EMCTL_BAD_USAGE);
}

exit($exitCode) ;


# subroutine to display banner
sub banner()
{
  my( $banner_add ) = "";
  if( $CFS_RAC )
  {
    $banner_add = "CFS-RAC Configuration.";
  }

  if($IN_VOB eq "TRUE")
  {
     print "Oracle Enterprise Manager 10g Release 5 Grid Control 10.2.0.5.0 ".$banner_add." \n";
  }
  elsif( $INSTALL_TYPE_IAS )
  {
     print "Oracle 10g Application Server Control 10.1.2.0.0 ".$banner_add." \n";
  }
  elsif( $INSTALL_TYPE_AGENT or $INSTALL_TYPE_CENTRAL )
  {
     print "Oracle Enterprise Manager 10g Release 5 Grid Control 10.2.0.5.0 ".$banner_add." \n";
  }
  elsif( $INSTALL_TYPE_DB )
  {
     print "Oracle Enterprise Manager 11g Database Control Release 11.1.0.0.0 ".$banner_add." \n";
  }
  print "Copyright (c) 1996, 2009 Oracle Corporation.  All rights reserved.\n";
  print "$DB_URL\n" if ($INSTALL_TYPE_DB and defined($DB_URL));
  print "$IAS_URL \n" if ($INSTALL_TYPE_IAS and defined($IAS_URL));

  if($DEBUG_ENABLED)
  {
    print "NOHUP Files are $AGENT_NOHUPFILE | $DB_NOHUPFILE | $IAS_NOHUPFILE \n";
  }
}


sub printDeployUsage()
{
  if($IS_WINDOWS eq "TRUE")
  {
    print <<DEPLOYUSAGE

    Deploy has two options :

        emctl deploy agent [-n <NTServiceName>] [-u <NTServiceUsername>] [-p <NTServicePassword>] [-s <install-password>] [-o <omshostname:consoleSrvPort>] [-S] <deploy-dir> <deploy-hostname>:<port> <source-hostname>

        emctl deploy dbconsole [-n <NTServiceName>] [-u <NTServiceUsername>] [-p <NTServicePassword>] [-s <install-password>] <deploy-dir> <deploy-hostname>:<port> <source-hostname> <sid>

      [agent|dbconsole] :
          'agent' creates and deploys only the agent.
          'dbconsole' creates and deploys both the agent and the dbconsole.
      [-s <password>]:
          Install password for securing agent.
      [-S ]:
          Password will be provided in STDIN.
      [-n <NTServiceName>]:
          The name of the Windows Service to create for the deployment. If
          not specified no service is created.
      [-u <NTServiceUsername>]:
      [-p <NTServicePassword>]:
          Credentials of the Windows Service. The deployed agent/dbconsole
          will run with these credentials.
      [-o <omshostname:consoleSrvPort>]:
          The OMS Hostname and console servlet port.
          Choose the unsecured port.
      <deploy-dir> :
          Directory to create the shared(state-only) installation
      <deploy-hostname:port> :
          Hostname and port of the shared(state-only) installation.
          Choose unused port.
      <source-hostname> :
          The hostname of the source install.
          Typically the machine where EM is installed. This is searched and
          replaced in targets.xml by the hostname provided in
          argument <deploy-hostname:port>.
      <sid> :
          The instance of the remote database. Only specified when
          deploying "dbconsole".

DEPLOYUSAGE
}
else
{
    print <<DEPLOYUSAGE

    Deploy has two options:

        emctl deploy agent [-s <install-password>] [-o <omshostname:consoleSrvPort>] [-S] <deploy-dir> <deploy-hostname>:<port> <source-hostname>

        emctl deploy dbconsole [-s <install-password>] <deploy-dir> <deploy-hostname>:<port> <source-hostname> <sid>

      [agent|dbconsole] :
          'agent' creates and deploys only the agent.
          'dbconsole' creates and deploys both the agent and the dbconsole.
      [-s <password>]:
          Install password for securing agent.
      [-S ]:
          Password will be provided in STDIN.
      [-o <omshostname:consoleSrvPort>]:
          The OMS Hostname and console servlet port.
          Choose the unsecured port.
      <deploy-dir> :
          Directory to create the shared(state-only) installation
      <deploy-hostname:port> :
          Hostname and port of the shared(state-only) installation.
          Choose unused port.
      <source-hostname> :
          The hostname of the source install.
          Typically the machine where EM is installed. This is searched and
          replaced in targets.xml by the hostname provided in
          argument <deploy-hostname:port>.
      <sid> :
          The instance of the remote database. Only specified when
          deploying "dbconsole".

DEPLOYUSAGE
}

}


#
# deploy Agent takes
# 1) Array of arguments
#
#            emctl deploy agent [-m rac] [-p <password>] <deploy-dir> <deployhostname:port> <hostname> <sid>
#
sub deploy()
{
  local (*args) = @_;

  shift(@args); # -- shift out "deploy"
  $mode = shift(@args);

  getopts('bn:u:p:s:o:S');

  my ($stateDir, $hostPort, $srcHost, $sid, $sourceEMDROOT,$replaceEMDROOT);

  if($mode eq "agent")
  {
    if(@args < 3)
    {
      print STDERR "Incorrect number of arguments.\n";
      printDeployUsage();
      exit -1;
    }

    ($stateDir, $hostPort, $srcHost) = ($args[0],$args[1],$args[2]);

  }
  elsif($mode eq "dbconsole")
  {
    if(@args < 4)
    {
        print STDERR "Incorrect number of arguments.\n";
        printDeployUsage();
        exit -1;
    }

    ($stateDir, $hostPort, $srcHost, $sid) =
        ($args[0],$args[1],$args[2],$args[3]);

  }
  else
  {
      printDeployUsage();
      exit -1;
  }

  $sourceEMDROOT = $EMDROOT;
  $replaceEMDROOT = $EMDROOT;

  -e "$sourceEMDROOT" or die "EMDROOT location: $sourceEMDROOT does not exist";

  my $deployObj = new EMDeploy();
  $deployObj->doDeploy($mode, $stateDir, $hostPort, $srcHost, $sid, $sourceEMDROOT, $replaceEMDROOT, $opt_s, $opt_n, $opt_u, $opt_p, $opt_o, $opt_S, $opt_b);
}

# -------------------------------- End of Program ------------------------------
