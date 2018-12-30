#
# $Header: emagent/scripts/unix/EmctlCommon.pm.template /st_emagent_10.2.0.1.0/28 2009/01/15 23:25:45 nigandhi Exp $
#
# EmctlCommon.pm
#
# Copyright (c) 2002, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      EmctlCommon.pm - Common functionality used by emctl
#
#    DESCRIPTION
#      None.
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    nigandhi    01/09/09 - Bug 7696444: Preserving permissions on
#                           emd.properties
#    mgoodric    12/05/08 - add more debugging
#    mvajapey    11/25/08 - rollback changes from
#                           swexler_emctl_changes_ag_10.2.0.5
#    swexler     11/12/08 - delegate dbconsole
#    mgoodric    10/08/08 - fix dumpCMD to send STDERR to log file
#    mgoodric    08/11/08 - add yet more debugging info
#    mgoodric    06/22/08 - added dumpENV for debugging GRID_AGENT_VIEW
#    sunagarw    06/16/08 - Backport sunagarw_bug-5014908 from main
#    joyoon      06/05/08 - Add emcoreAgent.jar to classpath for setReposPasswd
#    bkovuri     04/10/08 - Backport bkovuri_bug-6927345 from main
#    bkovuri     06/05/08 - Backport bkovuri_bug-6927345 from main
#    kganapat    05/23/08 - Change the default values of
#                           EMAGENT_RECYCLE_MAXMEMORY
#    bkovuri     04/10/08 - Backport bkovuri_bug-6927345 from main
#    njagathe    02/15/08 - XbranchMerge dgiaimo_bug-4757344 from main
#    apenmets    01/07/08 - Updating changes from stpl_emdb_main_gen branch
#    svrrao      07/09/07 - Backport svrrao_bug-6141202 from main
#    njagathe    07/02/07 - Backport njagathe_bug-6157933 from main
#    njagathe    06/20/07 - Backport njagathe_bug-6135721 from main
#    dgiaimo     06/13/07 - Fixing backport bug.
#    njagathe    05/09/07 - XbranchMerge njagathe_revert_db11_changes from
#                           st_emagent_10.2.0.1.0
#    njagathe    05/06/07 - Add back ojdbc14.jar
#    njagathe    05/02/07 - XbranchMerge njagathe_jdbc_rename_db11 from
#                           st_emagent_10.2.0.3.1db11
#    vivsharm    04/24/07 - ojdbc14 jar has been sunset
#    dgiaimo     03/30/07 - Fixing bug 5912869
#    dgiaimo     04/05/07 - Backport dgiaimo_bug_5912869 from main
#    dgiaimo     03/30/07 - Fixing bug 5912869
#    cvaishna    03/20/07 - platform specific EMAGENT_RECYCLE_MAXMEMORY setting
#    cvaishna    03/21/07 - XbranchMerge cvaishna_bug-5942315 from main
#    aghanti     02/19/07 - Bug 5597298 - fixing issues caused due to install
#                           pathname containing the string 'port'
#    svrrao      10/10/06 - Porting Changes, platform specific EMAGENT_RECYCLE_MAXMEMORY setting
#    rsamaved    10/02/06 - dbconsole status url
#    cvaishna    08/18/06 - Fixing JVM recycle memory size on IA64
#    rsamaved    08/31/06 - dbconsole startup fix
#    vivsharm    05/16/06 - for OC4J 10.1.3 changes
#    smodh       02/20/06 - XbranchMerge smodh_jdbc_emagent from main
#    shianand    01/05/06 - Backport shianand_bug-4913221 from main
#    smodh       01/25/06 - Use ojdbc14.jar
#    shianand    12/20/05 - fix bug 4894781
#    kduvvuri    09/11/05 - add abbend file processing.
#    kmanicka    06/21/05 - remove emkey stuff
#    kduvvuri    08/19/05 - bug 4560146.
#    kmanicka    08/22/05 - fix /dev/null in configemkey
#    shianand    08/10/05 - fix bug 4543290
#    kduvvuri    08/05/05 - fix 4524126.
#    kmanicka    06/21/05 - add configEmKey
#    rkpandey    07/15/05 - Bug 4405286: Use File::Copy
#    sksaha      06/14/05 - Add entry for core signal
#    shianand    05/20/05 - fix bug 4354597
#    blivshit    05/19/05 - undo RAC nodename changes per RAC team request
#                           (venkat.maddali)
#    gan         03/25/05 - catch local host name
#    asawant     02/18/05 - Cut over single quote in WINReadPasswd
#    blivshit    02/18/05 - fix misspelled "topdir" to "topDir
#    aaitghez    01/26/05 - Porting changes to MAIN line
#    asawant     01/24/05 - getLocalHostName should work in OMS install.
#    blivshit    01/18/05 - fix NT bug for getLocalRacNode...need to strip
#                           both CR and LF
#    vnukal      01/10/05 - adaptable MAX MEMORY
#    kduvvuri    12/20/04 - add validateTZFix.
#    blivshit    12/10/04 - add File::spec declaration...this version of Perl
#                           needs it
#    blivshit    12/08/04 - change hostname to nodename for rac for oc4jHome
#    blivshit    12/08/04 - fix open3 problem with stdin
#    asawant     11/17/04 - getLocalHost errors must go to stderr
#    aaitghez    11/05/04 - bug 3871127. change timeouts
#    blivshit    10/27/04 - don't dump errors to stderr for calling lsnodes
#    blivshit    10/22/04 - use nodename instead of hostname for RAC for state
#                           directory
#    asawant     10/19/04 - Cut over EMHOSTNAME to ORACLE_HOSTNAME
#    vnukal      09/23/04 - reverting pidfile undefinition
#    vnukal      09/17/04 - pid file obsoletion
#    vnukal      09/15/04 - adding additional perl tracing
#    vnukal      09/13/04 - adding tracing routines
#    asawant     08/24/04 - Adding secure password reading on Windows
#    gan         08/18/04 - bug 3461755
#    kduvvuri    07/23/04 - fix getOC4Jhome.
#    kduvvuri    06/16/04 - add rotate file.
#    kduvvuri    06/15/04 - set arg to CONSOLE_CFG if no arg is passed to
#                           getEMOc4j_Home.
#    aaitghez    06/08/04 - bug 3656322. Cleanup perl warnings
#    kduvvuri    06/01/04 - create EM_INSTALL_TYPE variable.
#    asawant     05/14/04 - Fix emctl setpasswd
#
#

package EmctlCommon;
require Exporter;
use English;
use IPC::Open3;
use Symbol;
use File::Basename;
use File::Spec;
use Getopt::Long;
use File::Copy;
use File::Temp qw/ tempfile /;
use Config;
use POSIX qw( strftime );

our @ISA    = qw(Exporter);
our @EXPORT = qw($EMDROOT $JAVA_HOME $JRE_HOME $ORACLE_HOME $CONSOLE_CFG
                 $EM_OC4J_OPTS $EMLOC_OVERRIDE $IASCONFIG_LOC $EM_TMP_DIR
                 $STATUS_PROCESS_OK $STATUS_NO_SUCH_PROCESS $STATUS_PROCESS_HANG
                 $STATUS_AGENT_NOT_READY $STATUS_AGENT_ABNORMAL $EMCTL_CORE_SIGNAL
                 $STATUS_PROCESS_PARTIAL $STATUS_PROCESS_UNKNOWN $PERL_BIN
                 $IAS_NOHUPFILE $IAS_URL $PID_FILE $EMD_HANG_CHECK_STATUS_TIME
                 $AGENT_NOHUPFILE $DB_NOHUPFILE $DB_URL $IN_VOB $IS_WINDOWS
                 $cpSep $binExt $devNull $EMAGENT_TIMESCALE
                 $NUMBER_AGENT_STATUS_RETRIES $EMAGENT_RECYCLE_SOFTLIMIT
                 $EMAGENT_RECYCLE_DAYS $EMAGENT_MEMCHECK_HOURS $OC4JLOC
                 $EMAGENT_RECYCLE_MAXMEMORY $EMAGENT_MAXMEM_INCREASE
                 $CFS_RAC $HOSTNAME $DEBUG_ENABLED &getEMAgentNameAndTZ
                 $INSTALL_TYPE_IAS $INSTALL_TYPE_CENTRAL $INSTALL_TYPE_AGENT
                 $INSTALL_TYPE_DB $TIME_BETWEEN_STATUS_CHECK $IAS_LOGDIR
                 &getOC4JHome &getEMHome &getWebUrl &getORMIPort &footer
                 &setReposPasswd &rotateFile &traceDebug &isOmsRecvDirSet
                 $EM_INSTALL_MODULE $EMCTL_UNK_CMD $EMCTL_BAD_USAGE $EMCTL_DONE
                 $FORMFACTOR_BASE $FORMFACTOR_FILE &getTimeouts &getTZFromJava
                 &testCEMDAvail &validateTZAgainstAgent &forceTZRegionValue
                 &updateBlackoutsXmlTS &writeToEMAbbendFile &dumpENV &dumpSHARED
                 $EM_ABBEND_MARKER $EM_EXIT_DONT_RESTART $EM_EXIT_THRASH
                 &getFilePermission &restoreFilePermissions);

# Some Global variables...
$EMCTL_DONE = 0;
$EMCTL_BAD_USAGE = 1;
$EMCTL_UNK_CMD = 2;
$EMCTL_CORE_SIGNAL = 9;       # Signal used to kill agent process on hang
$STATUS_PROCESS_OK = 0;       # Indicates that the process is up
$STATUS_NO_SUCH_PROCESS = 99; # Indicates that the process is not there
$STATUS_PROCESS_HANG = 98;    # Indicates that the process is up but unresponsive
$STATUS_PROCESS_UNKNOWN = 1;  # Indicates an unknown/indeterminate state
$STATUS_AGENT_NOT_READY = 4;  # Specific to agent...
$STATUS_AGENT_ABNORMAL  = 7;  # Agent tells watch dog to act same as for HANG
$STATUS_PROCESS_PARTIAL = 5;  # In dual mode system [Console+Agent], either console
                              # or agent is running.

# emctl log file variables
$EMCTL_LOGFILEHANDLE_OPENED = 0;
$EMCTL_LOGFILEHANDLE;

$EM_ABBEND_MARKER = "XXXXXXXXXXXXXXXX";
$EM_EXIT_DONT_RESTART = 55; #Watch dog exit code when told by the component to
                            #not restart it. Eg. Agent init failure.
$EM_EXIT_THRASH = 56;       #Watch dog exit code when there is a thrash.

# variable for catching local host name, rac node
$EM_LOCAL_HOST;
$EM_LOCAL_RAC;

if(defined($ENV{EMCTL_DEBUG}))
{
  $DEBUG_ENABLED = 1;
}
$EM_INSTALL_MODULE = "CompEM$ENV{CONSOLE_CFG}";


# setup the environment ...
$EMLOC_OVERRIDE = "";
$PERL_BIN = $ENV{PERL_BIN};
$OC4JLOC = "";

if(!defined($ENV{NUMBER_AGENT_STATUS_RETRIES}))
{
    $NUMBER_AGENT_STATUS_RETRIES = 2;
}
else
{
    $NUMBER_AGENT_STATUS_RETRIES = $ENV{NUMBER_AGENT_STATUS_RETRIES};
}

# The environment variable, EMAGENT_TIME_FOR_START_STOP
# determines how long the agent start or stop commands
# will wait for the agent to come up or go down.
if(!defined($ENV{EMAGENT_TIME_FOR_START_STOP}))
{
    $EMAGENT_TIME_FOR_START_STOP=120;
}
else
{
    $EMAGENT_TIME_FOR_START_STOP = $ENV{EMAGENT_TIME_FOR_START_STOP};
}

if( !defined($ENV{EMD_HANG_CHECK_STATUS_TIME}))
{
  $EMD_HANG_CHECK_STATUS_TIME = 300; # Timeout parameter for emdctl status...
}
else
{
  $EMD_HANG_CHECK_STATUS_TIME = $ENV{EMD_HANG_CHECK_STATUS_TIME};
}

$EM_OC4J_OPTS = $ENV{EM_OC4J_OPTS};
$IASCONFIG_LOC = $ENV{IASCONFIG_LOC};
$JAVA_HOME = $ENV{JAVA_HOME};
$JRE_HOME = $ENV{JRE_HOME};
$EMDROOT = $ENV{EMDROOT};
$ORACLE_HOME = $ENV{ORACLE_HOME};
$CONSOLE_CFG = $ENV{CONSOLE_CFG};

$INSTALL_TYPE_IAS = 0;
$INSTALL_TYPE_CENTRAL = 0;
$INSTALL_TYPE_AGENT = 0;
$INSTALL_TYPE_DB = 0;

#Values for HOST_SID_OFFSET_ENABLED : "" (unset), "host_sid", "host_only"
$HOST_SID_OFFSET_ENABLED = $ENV{HOST_SID_OFFSET_ENABLED};

if($CONSOLE_CFG eq "iasconsole")
{
  # Central Console aka OMS commands are *not* applicable
  # Agent and IASConsole is managed together by a single Process Monitor

  $INSTALL_TYPE_IAS = 1;
}
elsif($CONSOLE_CFG eq "central")
{
  # Central Console aka OMS commands are applicable
  # The Central agent is assumed to be in a different home
  # Since IAS is installed, IASConsole is present and
  # hence central=iasconsole+oms

  $INSTALL_TYPE_CENTRAL = 1;
}
elsif($CONSOLE_CFG eq "agent")
{
  # IASConsole and Central Console commands are *not* applicable

  $INSTALL_TYPE_AGENT = 1;
}
elsif($CONSOLE_CFG eq "dbconsole")
{
  # Same as iasconsole, only thing is dbconsole is now managed
  $INSTALL_TYPE_DB = 1;
}
else
{
  # Most likely in views. All commands are applicable, different
  # process monitors.
  $INSTALL_TYPE_CENTRAL = 1;
  $INSTALL_TYPE_AGENT = 1;
  $INSTALL_TYPE_IAS = 1;
  $INSTALL_TYPE_DB = 1;
  $IN_VOB = "TRUE";
}

$IS_WINDOWS = "";
$binExt = "";
$devNull = "/dev/null";
$cpSep = ":";

if( ($OSNAME eq "MSWin32") or ($OSNAME eq "Windows_NT") )
{
 $IS_WINDOWS = "TRUE";
 $binExt = "\.exe";
 $devNull = "nul";
 $cpSep = ";";
}
else
{
 $IS_WINDOWS = "FALSE";
}

# This is specific to the EMAGENT
# Set EMAGENT_MEMCHECK_HOURS to 0 to skip memory check
#
if( !defined($ENV{EMAGENT_MEMCHECK_HOURS}))
{
  $EMAGENT_MEMCHECK_HOURS = 1;
}
else
{
  $EMAGENT_MEMCHECK_HOURS = $ENV{EMAGENT_MEMCHECK_HOURS};
}

if( !defined($ENV{EMAGENT_RECYCLE_MAXMEMORY}) )
{
  $EMAGENT_RECYCLE_MAXMEMORY = 512;
  if ( ($OSNAME eq "dec_osf") )
  {

    $EMAGENT_RECYCLE_MAXMEMORY = 1000;
  }
  if( ($OSNAME eq "linux") )
  {
    $EMAGENT_RECYCLE_MAXMEMORY = 512;

    #for Linux-On-Power
    $EMAGENT_RECYCLE_MAXMEMORY = 1000 if ( $Config{archname} =~ /ppc64-linux-thread-multi/ or $Config{'archname'} =~ m/ppc-linux/ );

    #for ia64-linux
    $EMAGENT_RECYCLE_MAXMEMORY = 1700 if ( $Config{archname} =~ /ia64-linux-thread-multi/ or $Config{'archname'} =~ m/ia64-linux/ );

    #for z-Linux
    my $z_uname = `uname -a`;
    $EMAGENT_RECYCLE_MAXMEMORY = 800 if ( $z_uname =~ m/s390x/i );
  }

  $EMAGENT_RECYCLE_SOFTLIMIT = "TRUE"; # when limit not specified explicitly
}
else
{
  $EMAGENT_RECYCLE_MAXMEMORY = $ENV{EMAGENT_RECYCLE_MAXMEMORY};
  $EMAGENT_RECYCLE_SOFTLIMIT = "FALSE"; #limit explicitly specified
}

if( !defined($ENV{EMAGENT_MAXMEM_INCREASE}))
{
  $EMAGENT_MAXMEM_INCREASE = 1;
}
else
{
  $EMAGENT_MAXMEM_INCREASE = $ENV{EMAGENT_MAXMEM_INCREASE};
}


if( !defined($ENV{EMAGENT_TIMESCALE}))
{
  $EMAGENT_TIMESCALE = 1;
}
else
{
  $EMAGENT_TIMESCALE = $ENV{EMAGENT_TIMESCALE};
}

if( !defined($ENV{WATCHDOG_START_TIME}))
{
  $WATCHDOG_START_TIME=0;
}
else
{
  $WATCHDOG_START_TIME= $ENV{WATCHDOG_START_TIME};
}

#
# Set EMAGENT_RECYCLE_DAYS to 0 to skip agent recycling based on time
#
if( !defined($ENV{EMAGENT_RECYCLE_DAYS}))
{
  $EMAGENT_RECYCLE_DAYS = 0;
}
else
{
  $EMAGENT_RECYCLE_DAYS = $ENV{EMAGENT_RECYCLE_DAYS};
}

# This checks wether the EM_CHECK_STATUS_INTERVAL is enabled or
# not. If it is enabled it is parsed here....
# By default, leave it to 0, so that status is checked every time the
# emwd wakes up. However for Enh. 3082538, the idea is to
# prolong the status check.

$TIME_BETWEEN_STATUS_CHECK = 0;

if( defined ($ENV{EM_CHECK_INTERVAL}) )
{
  my($multiplier, $SLEEP_TIME) = (1,30);

  my($EM_CHECK_INTERVAL) = $ENV{EM_CHECK_INTERVAL};

  if($EM_CHECK_INTERVAL =~ /[a-gi-ln-rt-zA-GI-LN-RT-Z]/)
  {
    die "Illegal character set defined for $EM_CHECK_INTERVAL. \n";
  }

  if($EM_CHECK_INTERVAL =~ /[sS]$/ )
  {
    my($num, undef) = split /[sS]/,$EM_CHECK_INTERVAL;
    $SLEEP_TIME = $num;
    $multiplier = 1;
  }
  elsif($EM_CHECK_INTERVAL =~ /[mM]$/ )
  {
    my($num, undef) = split /[mM]/,$EM_CHECK_INTERVAL;
    $SLEEP_TIME = $num;
    $multiplier = 60;
  }
  elsif($EM_CHECK_INTERVAL =~ /[hH]$/ )
  {
    my($num, undef) = split /[hH]/,$EM_CHECK_INTERVAL;
    $SLEEP_TIME = $num;
    $multiplier = 3600;
  }
  else
  {
    die "Illegal format defined for EM_CHECK_INTERVAL. Define <number>[sSmMhH] instead of $EM_CHECK_INTERVAL \n";
  }

  $TIME_BETWEEN_STATUS_CHECK = $SLEEP_TIME * $multiplier;

  if($TIME_BETWEEN_STATUS_CHECK < 0)
  {
     print "\nHealth Check for the current component is disabled vide env. variable EM_CHECK_INTERVAL. \n";
  }
}

sub getEMAgentNameAndTZ
{
  ($emdPropFile) = @_;
  my ($EMDPROP,$emdPropLine,$tzRegion,$propValue,$propName,$remain,$found,$emdURL,$agentName);

  $repURL = "";
  $tzRegion = "";

  open(EMDPROP,"< $emdPropFile" ) or die "Fatal error can not open:$emdPropFile to look for the property  'agentTZRegion': $!";

  while ($emdPropLine = <EMDPROP>) {
    chomp($emdPropLine);
    #strip all leading  white space characters.
    $emdPropLine =~ s/^\s*//;

    if( ($emdPropLine =~ /^\#/ ) || ( length($emdPropLine) <= 0 ) ) {
    #print "discarding  \"$emdPropLine\" ,since it is a comment \n";
       next;
    }
    ($propName, $propValue , $remain) = split(/\=/ , $emdPropLine , 3);
    #remove leading and trailing white space.
    $propName =~ s/\s*$//;
    $propValue =~ s/^\s*//;
    $propValue =~ s/\s*$//;
    $lengthPropName = length($propName);
    $lengthPropValue = length($propValue);
    if ( ($lengthPropName) > 0  && ($lengthPropValue > 0 ))
    {
       if ( $propName eq "agentTZRegion" )
       {
         $tzRegion = $propValue;
       }
       if ( ($propName eq "EMD_URL") )
       {
         $emdURL = $propValue;
         if( $emdURL =~ /(.*https?\:\/\/)(.*)(\/emd\/main)/)
         {
           $agentName = $2;
         }
       }
    }
  }
  close(EMDPROP);
  return("$agentName","$tzRegion");
}

sub getTZFromJava
{
  my $rc = 0;
  my $tzret = undef;

  my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
  close $fh; # closing to prevent file sharing violations on Windows

  $rc = 0xffff & system("$JRE_HOME/bin/java -DORACLE_HOME=$EMDROOT -DEMHOME=$EMHOME -jar $ORACLE_HOME/jlib/emConfigInstall.jar getSupportedTZ > $tmpfilename 2>&1");
  $rc >>= 8;
  if ($rc == 0 )
  {
    open ($fh,"<$tmpfilename");
    while (<$fh>) {
      $tzret = $_;
    }
    close $fh;
  }

  chop($tzret);
  unlink("$tmpfilename");
  if ($rc != 0)
  {
    printMessage("Failed to get TZ from getSupportedTZ, rc = $rc\n");
  }
  return $tzret;
}

sub forceTZRegionValue
{
  my ($tzRegion) = @_;
  my $rc = 0;

  if($IS_WINDOWS ne "TRUE")
  {
    my ($validTZ, $tzj) = isTZequivalent($tzRegion);

    if ( $validTZ eq "false" )
    {
         printMessage("Could not force timezone value to \"$tzRegion\". Found \"$tzj\" instead..");
         $rc = 1;
    }
    else
    {
      $rc = validateTZAgainstAgent($tzRegion);
    }
  }
  else
  {
    $rc = 1;
  }
  return $rc;
}
# Check If Time Zone is deprecated in supportedtzs.lst and return equivalent timezone from tzmappings.lst.

sub isTZequivalent
{
    my ($tzRegion) = @_;
    $ENV{TZ} = $tzRegion;
    my $tzj = getTZFromJava();
    my $validTZ = "false";

    if($tzRegion ne $tzj)
    {
      my $pathEnv = $ENV{'ORACLE_HOME'};
      my $pathSuppTz = File::Spec->catfile($pathEnv, "sysman","admin","supportedtzs.lst");
      open (FH1, "<$pathSuppTz");

      while($line = <FH1>)
      {
        if($line = ~m/deprecated $tzRegion/)
        {
           my $pathTzMapping = File::Spec->catfile($pathEnv, "sysman","admin","tzmappings.lst");
           open (FH2, "<$pathTzMapping");

           while($line = <FH2>)
           {
              if($line =~ m/$tzRegion=$tzj/)
              {
                 $validTZ = "true";
                 last;
              }
           }
        }
      }
   }
   else
   {
      $validTZ = "true";
   }
  return ($validTZ, $tzj);
}
#Validates the timezone in emd.properties with that of  agent's time zone.
#
sub validateTZAgainstAgent
{
  my ($tzRegion) = @_;
  my $rc = 0;

  #validate what is in emd.properties is in conformance with
  #what the agent thinks it should be.
  my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
  close $fh; # closing to prevent file sharing violations on Windows
  $rc = 0xffff & system("$EMDROOT/bin/emdctl validateTZ agent  $tzRegion > $tmpfilename 2>&1");

  if ( $rc != 0 )
  {
     open ($fh,"<$tmpfilename");
     while (<$fh>) {
       printMessage ("$_");
     }
     close $fh;
  }
  unlink("$tmpfilename");
  return $rc;
}

#Updates the timestamps in blackouts.xml to match shift in timezone
#
sub updateBlackoutsXmlTS
{
  my ($oldtzRegion, $tzRegion) = @_;
  my $rc = 0;

  #update timestamps in blackouts.xml from values in the old timezone region to
  #values in the new timezone region
  my($fh,$tmpfilename) = tempfile(UNLINK => 1, DIR => "$EM_TMP_DIR");
  close $fh; # closing to prevent file sharing violations on Windows
  $rc = 0xffff & system("$EMDROOT/bin/emdctl updateBlkoutTS agent $oldtzRegion $tzRegion > $tmpfilename 2>&1");

  if ( $rc != 0 )
  {
     open ($fh,"<$tmpfilename");
     while (<$fh>) {
       printMessage ("$_");
     }
     close $fh;
  }
  unlink("$tmpfilename");
  return $rc;
}

sub printMessage()
{
 my ($message) = @_;
 print "----- ".localtime()."::".$message." -----\n";
}
# Sets the FORMFACTOR_BASE and FORMFACTOR_FILE.
# For shutting down without the password, both admin.jar and
# oc4j.jar handshake on <dir>/opmn/conf/.formfactor file.
# For our standalone consoles, the <dir> is $emHome/sysman
# i.e., the .formfactor is stored in $emHome/sysman/opmn/conf
# and we establish that directory here.
#
sub setFormFactor
{
  my $emHome = shift;

  $formFactorLocation = "$emHome/sysman/opmn/conf";
  $FORMFACTOR_BASE = "$emHome/sysman";  # This is exported out to emctl/emwd/pm's.
  $FORMFACTOR_FILE = "$formFactorLocation/.formfactor"; # exported to emctl

  -e "$FORMFACTOR_BASE" or mkdir "$FORMFACTOR_BASE";
  -e "$FORMFACTOR_BASE/opmn" or mkdir "$FORMFACTOR_BASE/opmn";
  -e "$formFactorLocation" or mkdir "$emHome/sysman/opmn/conf";
}

# Returns the OC4JHome for the given console type.
sub getOC4JHome
{
 my $consoleType = shift;

 my $oc4jHome = "$EMDROOT/sysman/j2ee"; # default for view...

 if (lc($consoleType) eq "agent" or lc($CONSOLE_CFG) eq "agent" )
 {
   # OC4J is not applicable for agent alone. hence returning
   # empty string for OC4J home.
   $oc4jHome = "";
   return $oc4jHome;
 }
 elsif(lc($consoleType) eq "iasconsole") # OC4JHOME for iasconsole
 {
   #Assume a defined OC4JHome
   $oc4jHome = "$EMDROOT/sysman/j2ee"; # This should be a no op...
 }
 elsif(lc($consoleType) eq "dbconsole") # OC4JHOME for dbconsole
 {
    $oc4jHome = "$ORACLE_HOME/oc4j/j2ee/OC4J_DBConsole";

    # For DBConsole, OC4J HOME is an offset of hostname_sid
    my $oracleSid = $ENV{ORACLE_SID};
    if($HOST_SID_OFFSET_ENABLED eq "host_sid")
    {
       die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);

      # Grok the current hostname and create the hostname_sid offset to
      # location. We may use a java api here to get the host and domainname.
      my $topDir = &getLocalHostName();

      #  for 10.2 dbcontrol, use node name for RAC
      if(substr($ENV{EMPRODVER},0,4) ne "10.1")
      {
        if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
        {
          # if we are in RAC, use the local node name
          $topDir = &getLocalRACNode();

          if ($topDir eq "") {
              print "RAC node name not found, defaulting to local host name\n" if $DEBUG_ENABLED;
              $topDir = &getLocalHostName();
         }
        }
      }

      $oc4jHome = $oc4jHome."_".$topDir."_".$oracleSid;
    }
 }
 else # If the console type oms.
 {
    # This is the default ...
    $oc4jHome = "$EMDROOT/sysman/j2ee";
 }

 die "OC4J Configuration issue. $oc4jHome not found. \n" unless( -e "$oc4jHome" );

 print "OC4J HOME ==================  $oc4jHome\n"  if $DEBUG_ENABLED;

 return $oc4jHome;
}

# Returns the EMHome for the given console type
sub getEMHome
{
    my $consoleType = shift;

    # If the consoleType is undef. default to iasConsole
    $consoleType = "$CONSOLE_CFG" unless defined ($consoleType);
    $consoleType = lc($consoleType);

    my $emHome = $EMDROOT;

    if($consoleType eq "iasconsole")
    {
        # We initialize the IAS_NOHUPFILE and LOG Dir here...
        $IAS_NOHUPFILE = "$emHome/sysman/log/em.nohup";
        $IAS_LOGDIR = "$emHome/sysman/log";
        $IAS_LOGFILE = "$emHome/sysman/log/em.log";
        $PID_FILE = "$emHome/emctl.pid";
    }
    elsif($consoleType eq "dbconsole") # EMHome for dbconsole
    {
        # EMSTATE env. var. is set from the script in the em state only bin
        # directory emctl [during NFS installs of state only agents].
        if ( $ENV{EMSTATE} ne "" )
        {
            $emHome = $ENV{EMSTATE};
        }
        elsif ( $HOST_SID_OFFSET_ENABLED eq "host_sid" )
        {
            my $oracleSid = $ENV{ORACLE_SID};
            die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);

            my $topDir = &getLocalHostName();

            if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
            {
                # if we are in RAC, use the local node name
                $topDir = &getLocalRACNode();

                if ($topDir eq "") {
                    print "RAC node name not found, defaulting to local host name\n" if $DEBUG_ENABLED;
                    $topDir = &getLocalHostName();
                }
            }

            $emHome = $ORACLE_HOME."/".$topDir."_".$oracleSid;

            $ENV{EMSTATE} = $emHome; # Promote EMSTATE to the env.
        }
        else
        {
            $emHome = $EMDROOT;
        }

        $DB_NOHUPFILE = "$emHome/sysman/log/emdb.nohup";
        $PID_FILE = "$emHome/emctl_sa.pid";
    }
    else
    {
        # This is the default in all cases except for MAINSA and dbconsole mode
        $emHome = $EMDROOT;

        {
            my $topDir = &getLocalHostName();

            print "EM HOME ROOT:  ".$ORACLE_HOME."/".$topDir."\n" if $DEBUG_ENABLED;

            if ( defined($ENV{EMSTATE}) && $ENV{EMSTATE} ne "" )
            {
                $emHome = $ENV{EMSTATE};
            }
            elsif( $HOST_SID_OFFSET_ENABLED eq "host_sid" )
            {
                my $oracleSid = $ENV{ORACLE_SID};
                die "Environment variable ORACLE_SID not defined. Please define it. \n" unless defined ($oracleSid);

                #use Sys::Hostname;
                #use Net::Domain qw(hostdomain);
                #my $localHost = hostname().".".hostdomain();

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
        }
    }

    #EM_TMP_DIR is valid only after a call to getEMHome.
    $EM_TMP_DIR = "$emHome";
    # Nohup file when only the agent is running.
    $AGENT_NOHUPFILE = "$emHome/sysman/log/emagent.nohup";
    $PID_FILE = "$emHome/emctl.pid";
    die "EM Configuration issue. $emHome not found. \n" unless( -e "$emHome" );

    setFormFactor($emHome);

    print "EMHOME ==================  $emHome\n"  if $DEBUG_ENABLED;
    return $emHome;
}

sub getWebUrl
{
  my $oc4jHome = shift;
  my $emHome = shift;
  my $consoleType = shift;
  $consoleType = lc($consoleType);

  # Ideally we should return the URL for the agent/central oms..
  if(($consoleType eq "agent") or ($consoleType eq "central"))
  {
    return "NULL";
  }

  # Check for the correctness of the oc4jHome location....
  die "Unable to define a url from undefined webapp config location.\n" unless defined($oc4jHome);

  die "Unable to locate web application configuration from $oc4jHome. \n" unless (-e $oc4jHome);

  # Check for the correctness of the emHome location
  die "Unable to locate the EM Application configuration. \n " unless defined($emHome);
  die "Unable to locate the EM Application configuration. \n" unless (-e $emHome);

  # Set up the DB URL here...
  my $consolePort = "NULL";
  my $isSecure = "false";
  my $protocol = "http";

  if ($consoleType eq "iasconsole")
  {
    if( -e "$oc4jHome/config/emd-web-site.xml")
    {
      print "Obtaining OC4J Listen Port from $oc4jHome/config/emd-web-site.xml \n" if $DEBUG_ENABLED;
      open(WEBSITECONFIG, "<$oc4jHome/config/emd-web-site.xml");
    }
    else
    {
      die "Unable to determine console port. $oc4jHome/config/emd-web-site.xml not found. $! \n";
    }
  }
  else
  {
    if( -e "$oc4jHome/config/em-web-site.xml")
    {
      print "Obtaining OC4J Listen Port from $oc4jHome/config/em-web-site.xml \n" if $DEBUG_ENABLED;
      open(WEBSITECONFIG, "<$oc4jHome/config/em-web-site.xml");
    }
    elsif( -e "$oc4jHome/config/http-web-site.xml")
    {
      print "Obtaining OC4J Listen Port from $oc4jHome/config/http-web-site.xml \n" if $DEBUG_ENABLED;
      open(WEBSITECONFIG, "<$oc4jHome/config/http-web-site.xml");
    }
    else
    {
      die "Unable to determine console port. $oc4jHome/config/*web-site.xml not found. $! \n";
    }
  }

  my $isProcessingCommentLine = 0;
  my $isMultilineWebSiteTag = 0;
  my $foundPortTag = 0;
  my $foundSecureTag = 0;

  my @xLines = <WEBSITECONFIG>;
  close (WEBSITECONFIG);

  for (my $i = 0; $i < scalar(@xLines); $i++)
  {
    my $line = $xLines[$i];

    if( !$foundPortTag || !$foundSecureTag)
    {
      if($line =~ /\s*\<\!\-\-/)
      {
        #print "\n MATCHED COMMENT LINE START \n";
        if($line !~ /.*\-\-\>/)
        {
          $isProcessingCommentLine = 1;
          #print "\n MULTILINE COMMENT PROCESSING START\n";
        }
        else
        {
          #print " COMMENT LINE END FOUND \n";
        }
      }
      elsif($isProcessingCommentLine)
      {
        if($line =~ /.*\-\-\>/)
        {
          $isProcessingCommentLine = 0;
          #print " MULTILINE COMMENT PROCESSING ENDS \n";
        }
        else
        {
          #print " MULTILINE COMMENT PROCESSING CONTINUES\n";
        }
      }
      elsif($line =~ /\s*\<web\-site/)
      {
        if($line !~ /.*\>/)
        {
          $isMultilineWebSiteTag = 1;
        }
        if($line =~ /port=/)
        {
          #print "\nMatch found on SAME line for port\n";
          my(undef, $portLine) = split /port="/,$line;
          ($consolePort, undef) = split /"/,$portLine;
          $foundPortTag = 1;
        }
        if($line =~ /secure=/)
        {
          #print "\nMatch found on SAME line for secure\n";
          my(undef, $secureLine) = split /secure="/,$line;
          ($isSecure, undef) = split /"/,$secureLine;
          $foundSecureTag = 1;
        }
      }
      elsif($isMultilineWebSiteTag)
      {
        if($line =~ /.*\>/)
        {
          $isMultilineWebSiteTag = 0;
        }
        if($line =~ /port=/)
        {
          #print "\nMatch found on DIFFERENT line for port\n";
          my(undef, $portLine) = split /port="/,$line;
          ($consolePort, undef) = split /"/,$portLine;
          $foundPortTag = 1;
        }
        if($line =~ /secure=/)
        {
          #print "\nMatch found on DIFFERENT line for secure\n";
          my(undef, $secureLine) = split /secure="/,$line;
          ($isSecure, undef) = split /"/,$secureLine;
          $foundSecureTag = 1;
        }
      }
    }
  }

  if(lc($isSecure) eq "true")
  {
    $protocol = "https";
  }

  if($consolePort eq "NULL")
  {
    die "Could not determine the correct port. \n";
  }

  -e "$emHome/sysman/config/emd.properties" or die "Unable to determine local host vide $emHome/sysman/config/emd.properties : $!\n";

  open(EMDPROPERTIES, "<$emHome/sysman/config/emd.properties");

  my $hostName;
  while(<EMDPROPERTIES>)
  {
    $emdProp = "EMD_URL";
    if ($consoleType eq "dbconsole" ) {
        # Use REPOSITORY_URL for dbconsole to handle remote OMS
        # configurations for RAC.
        $emdProp = "REPOSITORY_URL";
    }

    if(/^(\s*$emdProp)/) # Search for emdProp
    {
      my (undef, $value) = /([^=]+)\s*=\s*(.+)/;
      my (undef,$machine,undef) = ($value =~ /([^:]+):\/\/([^:]+):([0-9]+)\/.*/);

      if (! defined($machine) )
      {
        die "Unable to determine local host from URL $_ . \n";
      }
      else
      {
          $hostName = $machine;
      }
    }
  }

  close (EMDPROPERTIES);

  my $url = "$protocol://$hostName:$consolePort";
  $url = $url."/em/console/aboutApplication" if ($consoleType eq "dbconsole");
  $url = $url."/emd/console/aboutApplication" if ($consoleType eq "iasconsole");

  return $url;
}

sub getORMIPort
{
  my $oc4jHome = shift;

  -e "$oc4jHome/config/rmi.xml" or die "Unable to determine RMI Port vide $oc4jHome/config/rmi.xml : $! \n";

  my $rmiPort = "NULL";

  open(RMICONFIG, "<$oc4jHome/config/rmi.xml");
  while(<RMICONFIG>)
  {
    if(/^(\s*<\s*rmi-server)/)
    {
         #
         # Old tag in rmi.xml (OC4J 9.0.4) was:
         # <rmi-server port="1932">
         #
         # New tag in rmi.xml (OC4J 10.1.3) is:
         # <rmi-server xmlns:xsi="http://a/b/c-d" xsi:text="http://x.y.z/a/b/c-d_0.e" port="1818" ssl-port="1818" schema-major-version="10" schema-minor-version="0">
         #
         # New logic:
         # 1) Split the rmi-server tag on ---> <space>port=<double-quote>
         # 2) Take the 2nd token which has <port-number><double-quote> and then the rest of the tag.
         # 3) Split this string on double quote.
         # 4) Take the first token after this split
         # 5) Token 1 = port number
         #
         my @split_1 = split(" port=\"", $_);
         my $port_part = $split_1[1];
         my @split_2 = split("\"", $port_part);
         $rmiPort = $split_2[0];
     die "ormi port value $rmiPort is erroneous.\n" unless ($rmiPort > 0);
    }
   }
   close(RMICONFIG);

   die "Could not decipher ORMI port from $oc4jHome/config/rmi.xml. It is set to $rmiPort" if ($rmiPort eq "NULL");

   return $rmiPort;
}

#
# Returns the startup and hang timeouts defined in emoms.properties.
# If they're not defined in emoms.properties or if its values are less than the
# default values, then it returns the default values.
# Default value for startupTimeout is 8 minutes
# Default value for hangTimeout is 6 minutes
#
sub getTimeouts
{
  my $emHome = shift;
  my $startupTimeout;
  my $hangTimeout;
  my $defaultStartupTimeout = 480;
  my $defaultHangTimeout = 360;

  if( ! -e "$emHome/sysman/config/emoms.properties")
  {
    $startupTimeout = $defaultStartupTimeout;   # default timeout
    $hangTimeout =  $defaultHangTimeout;   # default timeout

    #Changes for ia64-linux and tru64 and lnx390

    $hangTimeout = 600 if ($OSNAME eq "dec_osf" or $Config{archname} =~ /s390x-linux/);

    my @rarray = ($startupTimeout, $hangTimeout);
    return @rarray;
  }

  -e "$emHome/sysman/config/emoms.properties" or die "Unable to locate file $emHome/sysman/config/emoms.properties : $!\n";

  open(EMOMSPROPERTIES, "<$emHome/sysman/config/emoms.properties");

  while(<EMOMSPROPERTIES>)
  {
    if(/^(\s*emctl.watchdog.startup_timeout)/) # Search for emctl.watchdog.startup_timeout...
    {
      my (undef, $value) = /([^=]+)\s*=\s*([0-9]+).*/;

      if ( defined($value) )
      {
        $startupTimeout = $value;
        if ( defined($hangTimeout) )
        {
          last;              #exit the loop, both timeouts have been read
        }
      }
    }

    if(/^(\s*emctl.watchdog.hang_timeout)/) # Search for emctl.watchdog.hang_timeout...
    {
      my (undef, $value) = /([^=]+)\s*=\s*([0-9]+).*/;

      if ( defined($value) )
      {
        $hangTimeout = $value;
        if ( defined($startupTimeout) )
        {
          last;              #exit the loop, both timeouts have been read
        }
      }
    }
  } # end of while loop

  close (EMOMSPROPERTIES);

  if (!defined($startupTimeout) or $startupTimeout<$defaultStartupTimeout)
  {
     $startupTimeout = $defaultStartupTimeout;   # default timeout
  }

  if (!defined($hangTimeout) or $hangTimeout< $defaultHangTimeout)
  {
     $hangTimeout =  $defaultHangTimeout;   # default timeout

     #Changes for ia64-linux and tru64 and lnx390

     $hangTimeout = 600 if (($OSNAME eq "dec_osf" or $Config{archname} =~ /s390x-linux/) and $hangTimeout<600);

  }

  if ($DEBUG_ENABLED)
  {
    print "Startup timeout: $startupTimeout \n";
    print "Hang detection timeout: $hangTimeout \n";
  }

  my @rarray = ($startupTimeout, $hangTimeout);
  return @rarray;
}

# get the RAC local node by calling lsnodes or the Oracle version of that
sub getLocalRACNode
{
  return ($EM_LOCAL_RAC) if (defined $EM_LOCAL_RAC);

  my $localNode = "";
  my $cmd;
  my $lsnodesDir;

  if (defined($ENV{CRS_HOME}) and ($ENV{CRS_HOME} ne "#CRS_HOME#"))
  {
     $lsnodesDir = $ENV{CRS_HOME}."/bin/olsnodes"."$binExt";
  } else {
     $lsnodesDir = $ORACLE_HOME."/bin/lsnodes"."$binExt";
  }
  $cmd = "$lsnodesDir"." -l";

  print "CRSHOME:  ".$ENV{CRS_HOME}."\n" if $DEBUG_ENABLED;
  print "lsnodes CMD:  ".$cmd."\n" if $DEBUG_ENABLED;

  if (not -e "$lsnodesDir")
  {
     print "Missing ".$lsnodesDir." for RAC\n" if $DEBUG_ENABLED;
  } else {
    my ($pid, $cmdout, $cmderr, $cmdstatus);
    local *NULL;
    my $null_file = File::Spec->devnull();
    open (NULL, $null_file) or confess("Cannot read from $null_file: + $!");

    $pid =  open3("<&NULL", $cmdout, $cmderr, "$cmd");
    $pid = waitpid $pid, 0;
    $cmdstatus = ($? >> 8);

    #  PORTING NOTE:  for NT, need to strip both CR and LF !!!
    chomp($localNode = <$cmdout>);
    $localNode =~ s/^\s+|\s+$//;

    print "OUT: *".$localNode."*\n" if $DEBUG_ENABLED;
    print "ERROR: ".<$cmderr>."\n" if $DEBUG_ENABLED;

    close($cmdout);
    close($cmderr);

    if ($cmdstatus != 0) {
        print "lsnodes command failed!  Status: ".$cmdstatus."\n" if $DEBUG_ENABLED;
        $localNode = "";
    }
  }

  $EM_LOCAL_RAC = $localNode;

  return $localNode;
}

# Gets the canonocal hostname of localhost for DBConsole.
# Overriding variable ORACLE_HOSTNAME is looked up in the java code itself...
sub getLocalHostName
{
  return $EM_LOCAL_HOST if (defined $EM_LOCAL_HOST) ;

  # Because in a GC install we don't ship emConfigInstall.jar (the one
  # available in $OH/jlib is from the IAS install and is old) we use
  # TargetInstaller from emCORE.jar. Note that in a DBConsole install we will
  # continue to use emConfigInstall.jar because emCORE.jar is not available
  # in $OH/j2ee/OC4J_EM...
  my $localHostCmd = "$JAVA_HOME/bin/java -DORACLE_HOME=$EMDROOT ".
                     "-classpath ".
                     "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib/emCORE.jar".
                     "$cpSep".
                     "$ORACLE_HOME/sysman/jlib/log4j-core.jar".
                     "$cpSep".
                     "$ORACLE_HOME/jlib/emConfigInstall.jar ".
                     "oracle.sysman.emSDK.conf.TargetInstaller getlocalhost";


  my $localHost = `$localHostCmd`;

  chomp($localhost);
  $localHost =~ s/^\s+|\s+$//;

  if ($DEBUG_ENABLED)
  {
    print("Hostname: '$localHost'\n");
  }

  $EM_LOCAL_HOST = $localHost;

  return($localHost);
}

# subroutine to display footer
sub footer()
{
  $EMHOME = getEMHome($ENV{CONSOLE_CFG});
  print "------------------------------------------------------------------\n";
  print "Logs are generated in directory $EMHOME/sysman/log \n";
}

######################################################################
# WINReadPasswd()
# prompt: The message to be displayed before the password is read
# return: user input
# Comment: Do not call this routine directly, instead call promptUserPasswd().
# This routine is only for Windows systems only.
######################################################################
sub WINReadPasswd
{
  my ($prompt) = @_;
  my $passwd = "";
  my $lineCnt = 0;
  my $finaPwd;
  my $cs = $clsSeparator;

  my $emConsoleMode = &SecureUtil::getConsoleMode();
  my $emAgentMode   = &SecureUtil::getAgentMode();
  my $CLASSPATH     = "$ORACLE_HOME/sysman/jlib/emagentSDK.jar";

  if ($emConsoleMode ne "")
  {
    $CLASSPATH = &SecureUtil::getConsoleClassPath($emConsoleMode);
  }
  else
  {
    if ($emAgentMode ne "")
    {
      $CLASSPATH = &SecureUtil::getAgentClassPath();
    }
  }

  eval
  {
    open GETPWD, "$JAVA_HOME/bin/java -classpath $CLASSPATH " .
                 "oracle.sysman.util.winUtil.WinUtil -readPasswd " .
                 "\"$prompt\" -invertFileHandles |";
    while(<GETPWD>)
    {
      $passwd .= $_;
      $lineCnt++;
    };
  };
  if($passwd eq "")
  {
    die("Failed executing java!\n");
  }

  unless(($lineCnt == 1) && (($finalPwd) = $passwd =~ m/Password='(.*)'\n$/o))
  {
    die("Failed parsing password returned from Java.\n$passwd\n");
  }
  return($finalPwd);
}


# Added to fix bug 4894781 for Internal Process Synchronization of
# OUI Java process and emctl command's Java process
sub WINReadPasswds
{
  my (@prompt)    = @_;
  my $promptlen   = scalar(@prompt);
  my $promptArgs  = "";

  for($i = 0; $i < $promptlen; $i++)
  {
    chomp($prompt[$i]);
    $promptArgs .= " \"$prompt[$i]\" ";
  }

  my @passwd ;
  my @finaPwd;
  my $cs      = $clsSeparator;
  my $lineCnt = 0;

  my $emConsoleMode = &SecureUtil::getConsoleMode();
  my $emAgentMode   = &SecureUtil::getAgentMode();
  my $CLASSPATH     = "$ORACLE_HOME/sysman/jlib/emagentSDK.jar";

  if ($emConsoleMode ne "")
  {
    $CLASSPATH = &SecureUtil::getConsoleClassPath($emConsoleMode);
  }
  else
  {
    if ($emAgentMode ne "")
    {
      $CLASSPATH = &SecureUtil::getAgentClassPath();
    }
  }
  eval
  {
    open GETPWD, "$JAVA_HOME/bin/java -classpath $CLASSPATH " .
                 "oracle.sysman.util.winUtil.WinUtil -readPasswds " .
                 "-invertFileHandles $promptArgs |";
    while(<GETPWD>)
    {
      $passwd[$lineCnt] = $_;
      $lineCnt++;
    }
  };

  if(@passwd eq "" and $lineCnt <$promptlen )
  {
    die("Failed executing java!\n");
  }

  for ($i = 0; $i < $promptlen; $i++)
  {
    chomp ($passwd[$i]);
    if ($passwd[$i] =~ m/Password:$i='(.*)'/)
    {
      $finalPwd[$i] = $1;
    }

  }
  return(@finalPwd);
}



######################################################################
# promptUserPasswd()
# prompt for user/passwd input
# return: user input
# Comment: This is how it should look once we get Win32::Console in the
#          standard perl distribution.
#            my $STDIN = new Win32::Console(STD_INPUT_HANDLE);
#            defined($STDIN) or die "Failed to create Win32::Console object!\n";
#            my $origMode = $STDIN->Mode();
#            $STDIN->Mode(&ENABLE_LINE_INPUT | &ENABLE_PROCESSED_INPUT);
#            $password=<STDIN>;
#            $STDIN->Mode($origMode);
#          ---
#          Alternatively, if we get ReadKey() (also Win32 specific):
#            ReadMode('noecho');
#            $password = ReadLine(0);
#            ReadMode('normal');
######################################################################
sub promptUserPasswd
{
   my ($prompt) = @_;
   my $password;
   if($IS_WINDOWS eq "FALSE")
   {
     print $prompt;
     system "stty -echo";
     $password = <STDIN>;
     system "stty echo";
     print "\n";
   }
   else
   {
     $password = WINReadPasswd($prompt);
   }
   chomp ($password);
   return $password;
}


# Added to fix bug 4894781 for Internal Process Synchronization of
# OUI Java process and emctl command's Java process
sub promptUserPasswds
{
   my (@prompt)  = @_;
   my $len = scalar(@prompt);
   my @password;

   if($IS_WINDOWS eq "FALSE")
   {
     for ($j = 0; $j < $len; $j++)
     {
       $password[$j] = promptUserPasswd($prompt[$j]);
     }
   }
   else
   {
     @password = WINReadPasswds(@prompt);
   }
   return @password;
}


######################################################################
# setReposPasswd()
#   Set the repostory password in emoms.properties. The password is obfuscated
# before it is written to the file.
######################################################################
sub setReposPasswd()
{
  $EMHOME = getEMHome($ENV{CONSOLE_CFG});
  $CLASSPATH = "$ORACLE_HOME/sysman/jlib/emCORE.jar"."$cpSep".
               "$ORACLE_HOME/sysman/jlib/emcoreAgent.jar"."$cpSep".
               "$ORACLE_HOME/sysman/jlib/emagentSDK.jar"."$cpSep".
               "$ORACLE_HOME/sysman/jlib/log4j-core.jar"."$cpSep".
               "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib/emCORE.jar"."$cpSep".
               "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib/emagentSDK.jar"."$cpSep".
               "$ORACLE_HOME/j2ee/OC4J_EM/applications/em/em/WEB-INF/lib/log4j-core.jar"."$cpSep".
               "$ORACLE_HOME/jlib/ojmisc.jar"."$cpSep".
               "$ORACLE_HOME/jdbc/lib/ojdbc14.jar"."$cpSep".
               "$ORACLE_HOME/oc4j/jdbc/lib/ojdbc14dms.jar"."$cpSep".
               "$ORACLE_HOME/oc4j/lib/dms.jar"."$cpSep".
               "$ORACLE_HOME/oc4j/jdbc/lib/orai18n.jar";

  my $newPasswd = promptUserPasswd("Please enter new repository password: ");
  if($newPasswd eq '')
  {
    # User hit enter without typing anything
    die "Invalid password!\n";
  }
  open(SETPWD, "| $JAVA_HOME/bin/java -classpath $CLASSPATH ".
                  "-DEMSTATE=$EMHOME oracle.sysman.emSDK.conf.ConfigManager ".
                  "-setPasswd >$devNull");
  print SETPWD "$newPasswd";
  close(SETPWD);
  print("Repository password successfully updated.\n");
}

sub rotateFile
{
    my ($i,$file, $maxbakups,$tmpfile,$tmpfile2);
    ($file, $maxbakups) = @_;

    if( -e $file.".".$maxbakups )
    {
        unlink ($file.".".$maxbakups);
    }

    for($i = $maxbakups -1 ; $i >= 1 ;$i--)
    {
        my $nextindex = $i + 1;
        $tmpfile = $file.".".$i;
        $tmpfile2 = $file.".".$nextindex;

        if( -e $tmpfile)
        {
            rename($tmpfile,$tmpfile2);
        }
    }
    copy($file,$file."."."1");
}

sub traceDebug
{
 my ($message) = @_;

 if(not defined $EMCTL_LOGFILE) {
   $EMCTL_LOGFILE = getEMHome()."/sysman/log/emctl.log";
 }

 if($EMCTL_LOGFILEHANDLE_OPENED == 0) {
   $EMCTL_LOGFILEHANDLE_OPENED = 1;
   unless(open ($EMCTL_LOGFILEHANDLE,">> $EMCTL_LOGFILE")) {
     warn "Unable to open file for logging. $EMCTL_LOGFILE: $!\n";
     return;
   }
 }

 print $EMCTL_LOGFILEHANDLE "$PID :: ".localtime()."::".$message."\n";
}

sub writeToEMAbbendFile
{
  my ($abbendFile, $message ) = @_;

  open(ABBENDFILE, ">> $abbendFile") || return;
  print ABBENDFILE "$message\n";
  close ABBENDFILE;
}

#
# Write ENV variable values to $T_WORK/$PROGRAM_NAME.log
# Usage: dumpENV('LD_LIBRARY_PATH','ORACLE_HOME',..);
#
sub dumpENV {
  my (@variables) = @_;
  if (defined $ENV{'T_WORK'}) {
    my $name = File::Basename::basename($0);
    my $logfile = "$ENV{'T_WORK'}/${name}.log";
    open(T_WORK, ">> $logfile") || return;
    printf(T_WORK "%s %s\n", strftime("%Y-%m-%d %H:%M:%S", gmtime), join(' ', $name, @ARGV));
    @variables = keys %ENV unless (@variables);
    foreach my $variable (sort @variables) {
      printf(T_WORK "%s=%s\n", $variable, $ENV{$variable});
    }
    close(T_WORK);
  }
}

#
# Timestamp and write the output of a command to $T_WORK/$PROGRAM_NAME.log
# Usage: dumpCMD($cmd, $logfile);
#
sub dumpCMD($$) {
  my ($cmd, $logfile) = @_;
  open(T_WORK, ">> $logfile") || return;
  printf(T_WORK "%s %s\n", strftime("%Y-%m-%d %H:%M:%S", gmtime), $cmd);
  close(T_WORK);
  system("$cmd >> $logfile 2>&1");
}

#
# Write Shared Library info to $T_WORK/$PROGRAM_NAME.log
# Usage: dumpSHARED('libnnz10.so',..);
#
sub dumpSHARED {
  my (@libraries) = @_;
  if (defined $ENV{'T_WORK'}) {
    my $name = File::Basename::basename($0);
    my $logfile = "$ENV{'T_WORK'}/${name}.log";
    my $cmd = "ldd $EMDROOT/bin/emagent";
    dumpCMD($cmd, $logfile);
    foreach my $library (@libraries) {
      $cmd = "ldd $EMDROOT/lib/$library";
      dumpCMD($cmd, $logfile);
      $cmd = "ls -l $EMDROOT/lib/$library";
      dumpCMD($cmd, $logfile);
      $cmd = "ls -lL $EMDROOT/lib/$library";
      dumpCMD($cmd, $logfile);
    }
  }
}

#
# Sub routine to test the availibility of CEMD
#
sub testCEMDAvail()
{
    if ((not -e "$EMDROOT/bin/emdctl"."$binExt") or  (not -e "$EMDROOT/bin/emagent"."$binExt"))
    {
        die "Missing either emdctl$binExt or emagent$binExt from $EMDROOT/bin.\n";
    }
    # Change current directory to sysman/emd so cores are generated at that
    # location and are easier to find in cust env.
    chdir("$EMHOME/sysman/emd");
}

# Determine if omsRecvDir is set in emd.properties
# If it is, return 1
# If it is present but commented, return 0
#
# Note: currently if omsRecvDir is not present, return 1
#       This is temporary until omsRecvDir is set in
#       emd.properties out-of-box.
#
sub isOmsRecvDirSet
{
    my ($emHome) = getEMHome();
    $filename = "$emHome/sysman/config/emd.properties";
    -e "$filename" or die "Unable to locate file $filename : $!\n";

    if ($DEBUG_ENABLED) {
        print ("isOmsRecvDirSet: emd properties filename = $filename\n");
    }

    open (EMD_PROP, $filename);
    @lines = <EMD_PROP>;

    $recvDirSet = 0;
    $recvDirCommented = 0;

    foreach $line (@lines) {
        if ($line =~ /^\#+ *omsRecvDir/) {
            # omsRecvDir set but commented
            $recvDirCommented = 1;
        }
        elsif ($line =~ /^ *omsRecvDir/) {
            # omsRecvDir set
            $recvDirSet = 1;
        }
    }

    if (!$recvDirCommented && !$recvDirSet) {
        # omsRecvDir not present, return 1 to support current default
        # Todo: when omsRecvDir is set in emd.properties by default,
        #       need to return 0 here
        $recvDirSet = 1;
    }

    close (EMD_PROP);

    return $recvDirSet;
}

#gets file permissions
sub getFilePermission
{
  my $filename=shift;
  my $mode = 0;

  if($IS_WINDOWS eq "FALSE")
  {  
    $mode = (stat($filename))[2];
    $mode &= 0777;
  }

  return $mode;
}

#chmod
sub restoreFilePermissions
{
  my $perm=shift;
  my $filename=shift;

  if($IS_WINDOWS eq "FALSE")
  {
    chmod $perm, "$filename";
  }
}


# All modules return something. By convention it is :
1;
# -------------------------------- End of Program ------------------------------

