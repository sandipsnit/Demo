#!/usr/bin/perl
# $Header: has/patch/auto_patch.pl /st_has_11.2.0.1.0/1 2009/11/05 17:28:34 ksviswan Exp $
#
# auto_patch.pl
# version 1
#
# Copyright (c) 2008, 2009, Oracle and/or its affiliates. All rights reserved. 
#
# CRS cluster patch script
#
#   NAME
#      auto_patch.pl - Auto patching script for Oracle Clusterware/RAC home.
#
#   DESCRIPTION
#      auto_patch.pl - Auto patching script for Oracle Clusterware/RAC home.
#
#
#   NOTES
#
# Documentation: usage output,
#   execute this script with -h option
#
# Change history:
#
#       MODIFIED   (MM/DD/YY)
#       akmaurya   12/03/09  - Fixed the path of patch112.pl
#       ksviswan   11/04/09  - XbranchMerge ksviswan_autopatch_impl1 from main
#       ksviswan   06/09/09  - opatch -auto support
#       ksviswan   05/25/09  - Platform support
#       ksviswan   05/15/09  - Add n-apply support and few enhancements.
#       ksviswan   05/12/09  - Add support for CRS bundle with db one-offs
#       ksviswan   11/04/08  - Add support for 11.1 CRS bundles
#       ksviswan   08/29/08  - Include Opatch version check
#       ksviswan   08/26/08  - Add support for patching ASM home
#       ksviswan   08/22/08  - Add OCM support.
#       ksviswan   08/18/08  - Add support for patching ohs installed by different users
#       ksviswan   08/14/08  - use srvctl from respective oh for resource start/stop actions
#       ksviswan   08/09/08  - incorporate SSH/RSH check
#       ksviswan   08/07/08  - Support patching Multiple Databases in oh
#       ksviswan   07/31/08  - Check if patch is already applied
#       ksviswan   07/29/08  - Support oracle home only patching
#       ksviswan   07/23/08  - Add patch validation 
#       ksviswan   07/15/08  - Incorporate logic for shared home patch
#       ksviswan   06/05/08  - adapt ora_crs_patch.pl for production use
#
#

use strict;
use Cwd;
use FileHandle;
use File::Basename;
use File::Spec;
use File::Copy;
use Sys::Hostname;

my $OS = `uname`;
chomp $OS;

my $unzip;
my $rsh;
my $ssh;
my $su;
my $sed;
my $echo;
my $mkdir;
my $cat;
my $rcp;
my $kill;
my $OLRLOC;
my $perlbin;

if ( $OS eq "Linux")
{
$unzip = "/usr/bin/unzip";
$rsh = "/usr/bin/rsh";
$ssh = "/usr/bin/ssh";
$su = "/bin/su";
$sed = "/bin/sed";
$echo = "/bin/echo";
$mkdir = "/bin/mkdir";
$cat = "/bin/cat";
$rcp = "/usr/bin/rcp";
$kill = "/bin/kill";
$OLRLOC = "/etc/oracle/olr.loc";
$perlbin = "/usr/bin/perl";
}
elsif ($OS eq "HP-UX")
{
$unzip = "/usr/local/bin/unzip";
$rsh = "/usr/bin/remsh";
$ssh = "/usr/bin/ssh";
$su =  "/usr/bin/su";
$sed = "/usr/bin/sed";
$echo = "/usr/bin/echo";
$mkdir = "/usr/bin/mkdir";
$cat = "/usr/bin/cat";
$rcp = "/usr/bin/rcp";
$kill = "/usr/bin/kill";
$OLRLOC = "/var/opt/oracle/olr.loc";
$perlbin = "/usr/bin/perl";
}
elsif ($OS eq "AIX" )
{
$unzip = "/usr/local/bin/unzip";
$rsh = "/usr/bin/rsh";
$ssh = "/usr/bin/ssh";
$su =  "/usr/bin/su";
$sed = "/usr/bin/sed";
$echo = "/usr/bin/echo";
$mkdir = "/usr/bin/mkdir";
$cat = "/usr/bin/cat";
$rcp = "/usr/bin/rcp";
$kill = "/usr/bin/kill";
$OLRLOC = "/etc/oracle/olr.loc";
$perlbin = "/usr/bin/perl";
}
elsif ( $OS eq "SunOS" )
{
$unzip = "/usr/bin/unzip";
$rsh = "/usr/bin/rsh";
$ssh = "/usr/local/bin/ssh";
$su =  "/usr/bin/su";
$sed = "/usr/bin/sed";
$echo = "/usr/bin/echo";
$mkdir = "/usr/bin/mkdir";
$cat = "/usr/bin/cat";
$rcp = "/usr/bin/rcp";
$kill = "/usr/bin/kill";
$OLRLOC = "/etc/oracle/olr.loc";
$perlbin = "/usr/bin/perl";
}
else
{
  die "ERROR: $OS is an Unknown Operating System\n";
}

my $pwd = $ENV{'PWD'}?$ENV{'PWD'}:getcwd();
my $crshome = "";
my @initargs = @ARGV;

# set own version
my $version = "2.0.0";
my $nlsLang="American_America.WE8ISO8859P1";

my $ohelp = "";
my $olog = "";
my $opatchfile = "";
my $opatchdir = "";
my $osimulate = "";
my $overbose = 0;
my $oversion = "";
my $ooh = "";
my $ooch = "";
my $ox = "";
my $oask = "";
my $oinventory = "";
my $oionly = "";
my $opatchn = "";
my $onodes = "";
my $orandom = "";
my $ochange = "";
my $olocal = "";
my $oclean = "";
my $oonerror = "";
my $ovfile = "";
my $owarmup = "";
my $obatch = "";
my $oint = "";
my $orollback = "";
my $opsilent = "";
my $overbose_n = "";
my $overbose_o = ""; 

my $optnameh = "help";
my $optnamehh = "hh";
my $optnamel = "log";
my $optnameoh = "oh";
my $optnameoch = "och";
my $optnamepatchf = "patchfile";
my $optnamepatchd = "patchdirectory";
my $optnamerollback = "rollback";
my $optnames = "simulate";
my $optnamev = "verbose";
my $optnameVV = "Version";
my $optnamex = "x";
my $optnamea = "ask";
my $optnameb = "batch";
my $optnamei = "inventory";
my $optnameint = "interactive";
my $optnameionly = "ionly";
my $optnamepatchn = "patchnumber";
my $optnamen = "nodes";
my $optnamer = "random";
my $optnamec = "change";
my $optnamelocal = "local";
my $optnameclean = "clean";
my $optnameon = "onerror";
my $optnamevf = "vfile";
my $optnamew = "warmup";
my $line = "";
my $ohline = "";
my $ohcount = 0;
my $sharedhome = "false";
my $stackrun = "";
my $stackruncount = 0;
my $patch_comp = "";
my $patch_ver = "";
my $patch_db_comp = "";
my $patch_db_ver = "";
my $local_node = "";
my $patchcrs = "";
my $iscrsonlypatch = "";
my $isrdbmsonlypatch = "";
my $crsbptype = "";
my $isrolling = "";
my $crspatchexist = "";
my $crspatchapplied = "";
my $crsnotconfigured = "";
my $ohpatchexist = "";
my $ohpatchapplied = "";
my $op_silent = "";
my $ocmrspfile = "";
my $asmcfg = "";
my $asmstop = "";
my $asm_home = "";
my $asmcount = 0;
my $ohexist = "";
my $opatch_ver = "";
my $napplydb = "";
my $napplypatch = "";
my $rdbmsids = "";
my $patchcount = 0;
my $stopcrs;
my $OS = `uname`;
chomp $OS;
my $isVendorCluster = 0;

# debug terminal output levels
my $tprint_askan = 2;        # 'ask' trace
my $tprint_chlog = 2;        # chown/chmod log errors
my $tprint_conf = 2;         # configuration detail
my $tprint_help = 1;         # detailed help output
my $tprint_options = 2;      # option values
my $tprint_ro = 0;           # 'run' command output
my $tprint_run = 2;          # 'run' trace
my $tprint_remote = 2;       # 'remote' trace
my $tprint_verify = 2;       # 'verify' trace
my $tprint_x = 2;            # '-x' trace
my $tprint_rollback = 0;     #  changes if -rollback specified

# warmup default
my $warmup_default = '60-120';

# sleep after stop crs
my $sstopcrs = 15;

# verification failure count
my $gvfail = 0;
my $g_startdir = "";
my $workload_pid = "";

my $goaway_r = "";
my $ask_skip = "";
my $ask_not = "";
my $ask_answer = "";

my $ORA_CRS_USER = "";
my $CRS_HOME = "";
my $ORA_CRS_HOME = "";
my $ORACLE_HOME = "";
my $RDBMS_HOME = "";
my $atahome = "";

my @ocp_nodes = ();
my @ocp_ohs = ();
my @ocp_patch_ohs = ();
my @ocp_ous = ();
my @ocp_databases = ();
my @ocp_nodes_topatch = ();
my @ocp_services = ();
my $ocp_patch_ohs_size = 0;
my $ocp_nodelist ="";
my $ocp_nodes_tplist = "";
my $ocp_ohlist = "";
my $ocp_dblist = "";
my $ocp_oulist = "";
my $ocp_srvlist = "";
my @patch_crs_info = ();
my @patch_oh_info = ();
my @crs_lsinfo = ();
my @oh_lsinfo = ();
my @crs_patchinfo = ();
my @oh_patchinfo = ();
my @tmp_ohlist = ();
my @tmp_ohlist1 = ();
my %ohdb = ();
my %dboh = ();
my %ohowner = ();
my @dbsinoh = ();
my @opatch_ver_info = ();
my @verinfo = ();

my $srvctl = "";
my $srvctl_oh = "";
my $crsctl = "";
my $crs_stat = "";
my $olsnodes = "";
my $opatch = "";
my $lsnodes = "";

#Set NLS_LANG to default
$ENV{"NLS_LANG"} = "$nlsLang";

my $pwd = $ENV{'PWD'}?$ENV{'PWD'}:getcwd();
my ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwuid( $< );
my $whoami = $name;
my $dev_null = "/dev/null";

my $patchfile = "";
my $patchdir = "";
my $log = "";
my $tmpf = "";
my $tmpfo ="";
my $why = "";
my $run_rpid = "";
my $iostep = "y";
my $iopd = "y";
my $ioop = "y";
my $iolsi = "y";
my $ionode = "y";
my $costep = "";
my $copd = "";
my $coop = "";
my $colsi = "";
my $conode = "";
my $ou = "";
my $oh = "";
my $cmd = "";
my $node = "";
my $db = "";
my $q2ask = "";
my $en = "";
my $innode = "";
my $gv = "";
my $nnn = 0;
my $atmcmt = <<"EOF";
 1    a subset of tests to run after patching each node
 2    all P0 tests
EOF


# START OUTPUT VERIFICATION DEFINITION
# uniq -c example: +      4 OK +  less blanks
my $t_sed_nonempty='s/^..*$//';
my $t_sed_empty='s/^.*$//';
my $t_egrep_empty='^ 1 $';
my $t_sed_noblanks='s/^[^ ][^ ]*$//';
my $t_egrep_allok='^[ 0]*[1-9][ 0-9]*OK *$';
my $t_sed_ok='s/^.*$//';
my $t_egrep_ok='^ *[1-9][0-9]*  *OK *$';
my $t_grep_default='^OK';
my $n='.*[0-9]* *';
my $s=' *';



my $sed_cat='s/shared//';
my $egrep_cat='^ 1 OK *\$';
my $grep_cat='^OK';

my $sed_atm="$t_sed_ok";
my $egrep_atm="$t_egrep_allok";

my $sed_olsnodes="$t_sed_noblanks";
my $egrep_olsnodes="$t_egrep_allok";

my $sed_lsi="$t_sed_ok";
my $egrep_lsi="$t_egrep_allok";

my $sed_srvctl_config="$t_sed_noblanks";
my $egrep_srvctl_config="$t_egrep_allok";

my $sed_srvctl_config_service='s/^.*PREF.*AVAIL.*$//';
my $egrep_srvctl_config_service='^ 1 $|^[ 0]*[1-9][ 0-9]*OKa *$';

my $sed_srvctl_config_db='s/^[^ ][^ ]* [^ ][^ ]* [^ ][^ ]*$//';
my $egrep_srvctl_config_db="$t_egrep_allok";

my $sed_srvctl_config_asm='s/^[^ ][^ ]* [^ ][^ ]*$//';
my $egrep_srvctl_config_asm="$t_egrep_allok";

my $sed_mkdir="$t_sed_empty";
my $egrep_mkdir='^ 1 $';

my $sed_rcp="$t_sed_ok";
my $egrep_rcp="$t_egrep_allok";

my $sed_unzip='s/^Archive:.*$//
s/^[ ]*creating:.*$//
s/^[ ]*inflating:.*$//
s/^[ ]*extracting:.*$//';

my $egrep_unzip="^${n}OKb${n}OKc${s}\$";

my $sed_srvctl_config_p="$sed_srvctl_config_db";
my $egrep_srvctl_config_p= "$t_egrep_allok";

my $sed_srvctl_stop_inst="$t_sed_empty";
my $egrep_srvctl_stop_inst="$t_egrep_empty";

my $sed_srvctl_stop_db="$t_sed_empty";
my $egrep_srvctl_stop_db="$t_egrep_empty";

my $sed_srvctl_start_db="$t_sed_empty";
my $egrep_srvctl_start_db="$t_egrep_empty";

my $sed_srvctl_start_service="$t_sed_empty";
my $egrep_srvctl_start_service="$t_egrep_empty";

my $sed_srvctl_start_inst="$t_sed_empty";
my $egrep_srvctl_start_inst="$t_egrep_empty";

my $sed_srvctl_stop_asm="$t_sed_empty";
my $egrep_srvctl_stop_asm="$t_egrep_empty";

my $sed_srvctl_stop_listener="$t_sed_empty";
my $egrep_srvctl_stop_listener="$t_egrep_empty";

my $sed_srvctl_start_listener="$t_sed_empty";
my $egrep_srvctl_start_listener="$t_egrep_empty";

my $sed_srvctl_stop_nodeapps='s/^CRS-[0-9][0-9]*: Could not stop resource .*ora.*\.lsnr.*$//';
my $egrep_srvctl_stop_nodeapps="^ 1 \$|^${n}OKa${s}\$";

my $sed_rmr="$t_sed_ok";
my $egrep_rmr="$t_egrep_allok";

my $sed_stop_oprocd = "$t_sed_ok";
my $egrep_stop_oprocd = "$t_egrep_allok";

my $sed_crsctl_stop_crs='s/^Stopping resources.*$//
s/^Resource or relatives are currently involved in another operation.*Retrying stop resources.*$//
s/^.*$//
s/^Successfully stopped .* resources.*$//
s/^Stopping .*$//
s/^Shutting down .* daemon\.$//
s/^Shutdown request successfully issued\.$//';

my $egrep_crsctl_stop_crs='^.*[0-9]* OKa [0-9]* OKb 1 OKc 1 OKd 1 OKe *$';

my $sed_crsctl_check_crs='s/.*healthy.*$//
s/.*healthy.*$//
s/.*healthy.*$//';

my $egrep_crsctl_check_crs='^.*[0-9]* OKa [0-9]* OKb 1 OKc 1 OKd 1 OKe *$';

my $sed_prerootpatch_crs='s/^.*ch.*cannot access .*opsm.mesg.*No such file or directory$//
s/^Checking to see if Oracle CRS stack is down\.\.\.$//
s/^Oracle CRS stack is down now\.$//';
my $egrep_prerootpatch_crs="^${n}OKa${n}OKb${s}1${s}OKc${s}\$|^${n}OKb${s}1${s}OKc${s}\$";

my $sed_prepatch_crs='s/^[^ ][^ ]* completed successfully\.$//
s/^Unable to determine value for.*$//'; 
my $egrep_prepatch_crs='^  *1  *OKa *$';

my $sed_prepatch_oh="$sed_prepatch_crs";
my $egrep_prepatch_oh="$egrep_prepatch_crs";

my $grep_rollback_crs='^XK';
my $sed_rollback_crs='s/^Invoking OPatch .*$//
s/^RollbackSession rolling back interim patch .*//
s/^User Responded with: Y$//
s/^User Responded with: [^Y].*$/XK_WRONG_1/
s/^Backing up files.*$//
s/^Verification exit code 0$//
s/^Patching component oracle\.crs.*$//
s/^RollbackSession removing interim patch .* from inventory$//
s/^The local system has been patched and can be restarted\.$//
s/.*error.*/XK_WRONG_1/i
s/^[^X].*$//
s/^$//';
my $egrep_rollback_crs="^${n}XKa${n}XKb${n}XKc${n}XKd${n}XKe${n}XKh${n}XKx${s}\$";

my $grep_patch_crs='^XK';
my $sed_patch_crs='s/^Invoking OPatch .*$//
s/^ApplySession applying interim patch .*//
s/^User Responded with: Y$//
s/^User Responded with: [^Y].*$/XK_WRONG_1/
s/^Backing up files.*$//
s/^Verification exit code 0$//
s/^Patching component oracle\.crs.*$//
s/^ApplySession adding interim patch .* to inventory$//
s/^Inventory check OK.*$//
s/^Files check OK.*$//
s/^The local system has been patched and can be restarted\.$//
s/.*error.*/XK_WRONG_1/i
s/^[^X].*$//
s/^$//';
my $egrep_patch_crs="^${n}XKa${n}XKb${n}XKc${n}XKd${n}XKe${n}XKf${n}XKg${n}XKh${n}XKx${s}\$";

my $grep_rollback_oh='^XK';
my $sed_rollback_oh='s/^Invoking OPatch .*$//
s/^RollbackSession rolling back interim patch .*//
s/^User Responded with: Y$//
s/^User Responded with: [^Y].*$/XK_WRONG_1/
s/^Backing up files.*$//
s/^OPatch succeeded\.$//
s/^Patching component oracle\.rdbms.*$//
s/^RollbackSession removing interim patch .* from inventory$//
s/^The local system has been patched and can be restarted\.$//
s/.*error.*/XK_WRONG_1/i
s/^[^X].*$//
s/^$//';
my $egrep_rollback_oh="^${n}XKa${n}XKb${n}XKc${n}XKd${n}XKe${n}XKh${n}XKx${s}\$";

my $grep_patch_oh='^XK';
my $sed_patch_oh='s/^Invoking OPatch .*$//
s/^ApplySession applying interim patch .*//
s/^User Responded with: Y$//
s/^User Responded with: [^Y].*$/XK_WRONG_1/
s/^Backing up files.*$//
s/^OPatch succeeded\.$//
s/^Patching component oracle\.rdbms.*$//
s/^ApplySession adding interim patch .* to inventory$//
s/^Inventory check OK.*$//
s/^Files check OK.*$//
s/^The local system has been patched and can be restarted\.$//
s/.*error.*/XK_WRONG_1/i
s/^[^X].*$//
s/^$//';
my $egrep_patch_oh="^${n}XKa${n}XKb${n}XKc${n}XKd${n}XKe${n}XKf${n}XKg${n}XKh${n}XKx${s}\$";

my $sed_postpatch_crs='s/^Oracle CRS_ENV_FILE is not specified but using.*$//
s/^Oracle CRS_ENV_FILE is not specified$//
s/Oracle CRS_SCRIPT_FILE is not specified but using.*$//
s/Reading .*params\.[oc].*\.*$//
s/Parsing file [^ ][^ ]*$//
s/Verifying file [^ ][^ ]*$//
s/Skipping the missing file [^ ][^ ]*$//
s/Reapplying file permissions on [^ ][^ ]*$//';
my $egrep_postpatch_crs="^${n}OKa${n}OKb${n}OKc${n}OKd${s}\$|^${n}OKb${n}OKc${n}OKd${s}\$";

my $sed_postpatch_oh="$sed_postpatch_crs";
my $egrep_postpatch_oh="$egrep_postpatch_crs";

my $sed_postrootpatch_crs='s/^Checking to see if Oracle CRS stack is already up\.\.\.$//
s/^Checking to see if Oracle CRS stack is already starting$//
s/^Startup will be queued to init within .* seconds\.$//
s/^Waiting for the Oracle CRSD and EVMD to start$//
s/^WARNING: directory .*is not owned by root.*$//
s/^Oracle CRS stack installed and running under init\(1M\)$//';
my $egrep_postrootpatch_crs='^ *1 OKa 1 OKb 1 OKc [0-9]* OKd 1 OKe *$';

# later non-English installations?
my $sed_srvctl_start_service_inst='s/^.*Can not find a service member to start for service .*$//
s/^.*The service .* does not exist\.*$//
s/^.*Service .* is already running on instance .*$//
s/^.*Could not start resource.*$//
s/^.*Failed to start the service.*$//
s/^.*Resource or relatives are currently involved with another operation.*$//';
my $egrep_srvctl_start_service_inst="^ 1 \$|^${n}OKa${s}\$";
# END OUTPUT VERIFICATION DEFINITION


#get host name and strip off domain .
my $host = hostname();
$host =~ s!\..*!!;
my $ppath = "$0";
my $pname = basename( $ppath );
my $parameters = join "", @_;
my $pall = "$0 $parameters";
my ($filename, $dirs, $suffix) = fileparse( $ppath, qr/\.[^.]*/ );
my $timestamp = gentimeStamp();
my $dlname = "$pwd/opatchauto_$timestamp.log";
my $pfull = substr( $ppath, 0, 1 ) eq "/"?$ppath:"$pwd/$pname";
my $initcssd = "";
my $atainit = "";
my $os = `/bin/uname -a`;
if ( -f "/etc/rc.d/init.d/init.cssd" )
{
        $initcssd = "/etc/rc.d/init.d/init.cssd";
}
elsif ( -f "/etc/init.cssd" )
{
        $initcssd = "/etc/init.cssd";
}
elsif ( -f "/sbin/init.d/init.cssd" )
{
        $initcssd = "/sbin/init.d/init.cssd";
	$rsh = -f "/usr/bin/remsh"?"/usr/bin/remsh":$rsh;
}
elsif ( -f "/etc/init.d/init.cssd" )
{
        $initcssd = "/etc/init.d/init.cssd";
}

if ( -f "/etc/rc.d/init.d/init.ata" )
{
        $atainit = "/etc/rc.d/init.d/init.ata";
}
elsif ( -f "/etc/init.d/init.ata" )
{
        $atainit = "/etc/init.d/init.ata";
}
elsif ( -f "/etc/init.ata" )
{
        $atainit = "/etc/init.ata";
}
elsif ( -f "/sbin/init.d/init.ata" )
{
        $atainit = "/sbin/init.d/init.ata";
}

#Remove trailing white spaces in a string
sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# 1: [-v] validation only, no sleep
# 1: 25 or 25-30
# dosleep_error=y if invalid parameter
sub dosleep
{
	my $dosleep_v = $_[0];
	if ( "$dosleep_v" eq "-v" )
	{
		shift;
	}
	my $dosleep_a = $_[0];
	my $dosleep_error = "y";
	my @dosleep_s =();
	my $dosleep_s1 = 0;
	my $dosleep_s2 = 0;
	my $dosleep_adj = 0;
	my $dosleep_sleep = 0;
	$dosleep_error = "y";
	if ( $dosleep_a =~ m/^\d+$/ || $dosleep_a =~ m/^\d+\-\d+$/ )
	{
		@dosleep_s = split( /-/, $dosleep_a );
		$dosleep_s1 = $dosleep_s[0];
		$dosleep_s2 = @dosleep_s==2?$dosleep_s[1]:0;
		if ( $dosleep_s2 > 0 && $dosleep_s2 < $dosleep_s1 )
		{
			return $dosleep_error;
		}			
	}
	else
	{
		return $dosleep_error;
	}
	if ( $dosleep_s2 > 0 )
	{
		$dosleep_adj = $dosleep_s2 - $dosleep_s1 + 1;
		$dosleep_adj = roll( $dosleep_adj );
		$dosleep_s1 = $dosleep_s1 + $dosleep_adj - 1;
	}
	$dosleep_error = "";
	if ( "$dosleep_v" eq "-v" )
	{
		return $dosleep_error;
	}
	my $dosleep_slept = 0;
	report( '-n', 0, 0, "Sleeping $dosleep_s1 second(s)" );
	if ( $osimulate )
	{
		return $dosleep_error;
	}
	$SIG{'INT'} = 'goaway_sleep';
	$SIG{'QUIT'} = 'goaway_sleep';
	while ( $dosleep_s1 > 0 )
	{
		if ( $dosleep_s1 > 60 )
		{
			$dosleep_sleep = 60;
		}
		else
		{
			$dosleep_sleep = $dosleep_s1;
		}
		sleep $dosleep_sleep;
		if ( "$goaway_r" eq "sig" )
		{
			last;
		}
		$dosleep_s1 = $dosleep_s1 - 60;
		$dosleep_slept = $dosleep_slept + 1;
		if ( $dosleep_s1 < 0 )
		{
			last;
		}
		report( 0, 0, "slept $dosleep_slept minute(s), $dosleep_s1 second(s) left..." );
		$goaway_r = "";
		$SIG{'INT'} = 'goaway_int';
		$SIG{'QUIT'} = 'goaway_quit';
	} 
}


# 1: why
# [2]: verify id
# [3]: sed output
# verify_failure_r=retry for retry
sub verify_failure
{
	my $verify_failure_why = $_[0];
	my $verify_failure_r = "";
	my $verify_failure_lstr = "";
	my $msg = "";
	$gvfail++;
	if ( "$verify_failure_why" eq "output" )
	{
		shift;
		shift;
		$verify_failure_lstr = join " ", @_;
		if ( $verify_failure_lstr )
		{
			report( '-n', 0, 0, "Unexpected lines encountered:" );
			$msg = $verify_failure_lstr;
			report( 0, 0, $msg );
			report( 0, 0, "(end) Unexpected lines encountered" );
		}
	}
	if ( "$oonerror" eq "continue" )
	{
		report( 0, 0, "ignored because of -onerror continue, so continuing..." );
		return $verify_failure_r;
	}
	if ( "$oonerror" eq "abort" )
	{
		report( '-n', 0, 0, "aborting the script because of -onerror abort" );
		exit 1;
	}
	ask( 'verify', 'Action failed, do you want to retry it' );
	if ( ! $ask_skip )
	{
		report( '-n', 0, 0, 'Retrying failed action at user request' );
		$verify_failure_r = "retry";
		$gvfail--;
		return $verify_failure_r;
	}
	report( 0, 0, 'ignored at user request, continuing' );
	return $verify_failure_r;
}

sub arraycompare
{
	my ($first, $second) = @_;
	no warnings;  # silence spurious -w undef complaints
	return 0 unless @$first == @$second;
	for (my $i = 0; $i < @$first; $i++) {
	    return 0 if $first->[$i] ne $second->[$i];
	}
	return 1;
}

sub batch_substitute
{
	my $file = $_[0];
	my $exprstr = $_[1];
	my @exprs = ();
	my $expr = "";
	my @lines = ();
	my @tmplines = ();
	local *FP;
	@lines = ();
	if ( ! -f $file || -z $file || ! $exprstr )
	{
		return @lines;
	}
	unlink( "$file.sed" );
	copy( $file, "$file.sed" );
	$file = "$file.sed";
	@exprs = split( /\n/, $exprstr );
	foreach $expr ( @exprs )
	{
		`perl -i -pe "$expr" $file`;
	}
	open( FP, "<$file" ) or die "Cann't open $file.\n";
	@tmplines = <FP>;
	@lines = grep !/^\s+$/, @tmplines;
	close( FP );	
	unlink( $file );
	return @lines;
}

# 1: id
#    if $id=foo, $sed_foo must be defined
# 2: command output file name
#    with -s, ./id.out is used if exists
# 3: command exit code
# returns $verify_r=ok if OK, or retry, or error message
sub verify
{
	my $msg = join " ", @_;
	report( $tprint_verify, 0, "verify: invoke with $msg" );
	my $verify_id = $_[0];
	my $verify_f = $_[1];
	my $verify_exit = $_[2];
	my $verify_r = "";
	my $verify_var = "";
	my $verify_s = "";
	my @verify_x1 = ();
	my $verify_f_str ="";
	my $verify_x1_str ="";
	my @lines = ();
	my $res = "";
	my $verify_rc = "";
	local *FP;
	$verify_r = "";
	$verify_s = "";
        report( $tprint_verify, 0, "osimulate is  $osimulate" );
	if ( $osimulate )
	{
#		$verify_f = "$g_startdir/$verify_id.out";
		return $verify_r;
	}
	if ( $verify_exit != 0 )
	{
		$verify_r = "exit code $verify_exit";
		report( '-n', 0, 0, "verify failure: exit code $verify_exit for $verify_id" );
		$res = verify_failure( 'code' );
		if ( $res eq "retry" )
		{
			$verify_r = "retry";
		}
		return $verify_r;
	}
	if ( $verify_id eq "postpatch_crs" )
	{
		return "ok";
	}
	if ( ! -f $verify_f || ! -r $verify_f )
	{
		usage( "cannot read command output file $verify_f" );
	}
        report( $tprint_verify, 0, "verify_id is   $verify_id" );
        report( $tprint_verify, 0, "verify_f is   $verify_f" );
	if ( -z $verify_f )
	{
                report( $tprint_verify, 0, "deifned   $verify_f" );
		return $verify_r;
	}
	$verify_var = "sed_$verify_id";
	eval "\$verify_s=\$$verify_var";
	if ( ! $verify_s )
	{
		usage( "cannot verify $verify_id: $verify_var is undefined" );
	}
	@verify_x1 = batch_substitute( $verify_f, $verify_s );
	chomp @verify_x1;
	if ( @verify_x1 == 0 )
	{       if ( $verify_id eq "cat" )
                {
                  $sharedhome="true";
                }
                if ( $verify_id eq "crsctl_check_crs" )
                {
                  $stackrun="true";
                }
		report(  $tprint_verify, 0, "output verification successful for $verify_id" );
		$verify_r = "ok";
	}
	else
	{       
		$verify_r = "output verification failure";
                if ( $verify_id eq "cat" )
                {
                 $sharedhome="false";
                 return $verify_r;
                }
                if ( $verify_id eq "crsctl_check_crs" )
                {
                 $stackrun="false";
                 return $verify_r; 
                }
		report( '-n', 0, 0, "verify failure: output verification failure for $verify_id" );	
		open( FP, "<$verify_f" );
		@lines = <FP>;
		close( FP );
		$verify_f_str = join "", @lines;
		$verify_x1_str = join "", @verify_x1;
		$msg = <<"EOF";
:START output verification failure report for '$verify_id'
:START INPUT for '$verify_id'
:$verify_f_str
:END INPUT for '$verify_id'
:START exceptional lines for '$verify_id'
:$verify_x1_str
:END exceptional lines for '$verify_id'
:Note: for successful verification grep output is expected 
:      to be the same as grep input 
:      which is sorted and duplicate lines removed.
:END output verification failure report for '$verify_id'
EOF
		report( -1, '-n', $tprint_verify, 0, $msg );	
		$res = verify_failure( "output", $verify_id, $verify_x1_str );
		if ( $res eq "retry" )
		{
			$verify_r = "retry";
		}
	}
	return $verify_r;
}

# 1: comment
sub invent
{
	my $invent_how = $_[0];
	my $cmd ="";
	my $node = "";
	my $user = "";
	my $oh = "";
	my $nnn = 0;
	if ( "$oionly" eq "y" )
	{
		$invent_how = 'Instead of patching';
	}
	if ( "$oinventory" ne "y" && "$oionly" ne "y" )
	{
		#report( '-n', 0, 0, "$invent_how, not running opatch lsinventory because -i is not specified" );
		return;
	}
	ask( 'lsi', "$invent_how, run opatch lsinventory -detail for all ORACLE_HOMEs on node $node" );
	if ( $ask_skip )
	{
		report( '-n', 0, 0, "Skipping this action at user request" );
		if ( $oionly eq "y" )
		{
			report( '-n', 0, 0, "Exiting script because -ionly is specified" );
			exit 0;
		}
		return;
	}

	foreach $node (@ocp_nodes)
	{
		ask( 'lsi', "$invent_how, run opatch lsinventory for CRS_HOME on $node" );
		$cmd = "$opatch lsinventory -detail -oh $CRS_HOME";
		report( '-n', 0, 0, "$invent_how, will $ask_not run $cmd on $node" );
		run( '-v', 'lsi', $ask_skip, $ORA_CRS_USER, 'n', $cmd );
		$nnn = 0;
		foreach $oh (@ocp_ohs)
		{
			$user = $ocp_ous[$nnn];
			$nnn++;
			if ( $oh eq $CRS_HOME )
			{
				next;
			}
			$cmd = "$opatch lsinventory -detail -oh $oh";
			ask( 'lsi', "$invent_how, run opatch lsinventory for OH $oh on $node" );
			report( '-n', 0, 0, "$invent_how, will $ask_not run $cmd on $node" );
			run( '-v', 'lsi', $ask_skip, $user, 'n', $cmd );
		}
	}
	if ( $oionly eq "y" )
	{
		report( '-n', 0, 0, "Exiting script because -ionly is specified" );
		exit 0;
	}
}

# 1: hup|term|int|quit|sleep|exit to identify caller
# goaway_r = sig if $1 is sleep
sub goaway
{
	my $goaway_rc = "$?";
	my $goaway_how = $_[0];
	my $cmd = "";
	if ( $goaway_how eq "sleep" )
	{
		report( '-n', 0, 0, "sleep interrupted by a signal" );
		$goaway_r = "sig";
		return;
	}
	if ( $goaway_how eq "int" )
	{
		report( '-n', 0, 0, "received SIGINT, terminating" );
	}
	if ( $goaway_how eq "quit" )
	{
		report( '-n', 0, 0, "received SIGQUIT, terminating" );
	}
	if ( $goaway_how eq "hup" )
	{
		report( '-n', 0, 0, "received SIGHUP, terminating" );
	}
	if ( $goaway_how eq "term" )
	{
		report( '-n', 0, 0, "received SIGTERM, terminating" );
	}
	if ( $goaway_how ne "exit" && $goaway_rc == 0 )
	{
		$goaway_rc = 1;
	}
	if ( $goaway_how eq "exit" )
	{
		if ( $ox ne "y" )
		{
			report( '-n', 0, 0, "$pname terminating with exit code $goaway_rc" );
		}
		$SIG{'EXIT'} = '';	
	}

	if ( $ox ne "y" && $log && $goaway_how eq "exit" )
	{
		report( '-n', 0, 0, "Command failures detected: $gvfail" );
		print "see also $log";
	}
	exit $goaway_rc;
}

sub goaway_sleep
{
	goaway( 'sleep' );
}
sub goaway_int
{
	goaway( 'int' );
}
sub goaway_quit
{
	goaway( 'quit' );
}
sub goaway_hup
{
	goaway( 'hup' );
}
sub goaway_term
{
	goaway( 'term' );
}
sub goaway_exit
{
	goaway( 'exit' );
}


# 1: N
# return value is $roll_r
sub roll
{
	my $roll_in = $_[0];
	my $roll_r = int( rand $roll_in ) + 1;
	return $roll_r;
}

# 1...: values to shuffle
# return value is @shuffle_r
sub shuffle
{
	my @shuffle_in = @_;
	my $shuffle_n = @shuffle_in;
	my @shuffle_r = ();
	my @shuffle_tmp = ();
	my $shuffle_i = 0;
	my $shuffle_el = "";
	@shuffle_r = ();
	while ( $shuffle_n > 0 )
	{
		$shuffle_i = roll( $shuffle_n );
		$shuffle_el = $shuffle_in[$shuffle_i-1];
		push @shuffle_r, $shuffle_el;
		$shuffle_n--;
		@shuffle_tmp = grep !/$shuffle_el/, @shuffle_in;
		@shuffle_in = @shuffle_tmp;
	}
	return @shuffle_r;
}

# [-c a,b,c -d b] multiple choice mode
#   -c list of choices, -d default
# [-ns] answer 's' is not allowed
# [-yn] only y or n are allowed
# 1: kind
# 2... question, but for multiple choice mode:
# 2: question
# 3: comments
# answers: y n s N N1-N2 h, or an element of -c
# return $ask_skip='-s' and $ask_not=' NOT' if answered s
#        $ask_answer the choice for multiple choice mode
# Update: from now on 'n' is spelled 'abort', and 's' is spelled 'n'
sub ask
{
	my $msg = join " ", @_;
	my $ask_choice = $_[0];
	my $ask_default = "";
	my $ask_ns = "";
	my $ask_yn = "";
	my $ask_kind = "";
	my $ask_list = "";
	my $ask_clist = "";
	my $ask_a = "";
	my $ask_q = "";
	my $ask_cmd = "";
	my $ask_if = "";
	my $ask_p = "";
	my $ask_sure = "";
	if ( $ask_choice eq "-c" )
	{
		$ask_list = $_[1];
		$ask_clist = ",$ask_list,";
		if ( $_[2] ne "-d" )
		{
			usage( "Internal error, ask(),$msg" );
		}
		$ask_default = $_[3];
		shift;
		shift;
		shift;
		shift;
	}
	$ask_ns = $_[0];
	if ( $ask_ns eq "-ns" )
	{
		shift;
	}
	$ask_yn = $_[0];
	if ( $ask_yn eq "-yn" )
	{
		shift;
	}
	$ask_kind = $_[0];
	shift;
	$ask_skip = "";
	$ask_not = "";
	$ask_answer = "";
	$msg = join " ", @_;
	if ( "$ask_choice" eq "-c" )
	{
		$ask_q = $_[0];
		$ask_cmd = $_[1];
		$ask_answer = $ask_default;
	}
	else
	{
		$ask_q = $msg;
	}
	eval "\$ask_if=\$io$ask_kind";
	if ( "$ask_if" eq "n" )
	{
		report( $tprint_askan, 0, "ask: io$ask_kind=n, skipping $ask_q" );
		return;
	}
	if ( "$ask_ns" eq "-ns" )
	{
		$ask_p = "(y/abort/N/N1-N2/help)";
	}
	else
	{
		$ask_p = "(y/n/abort/N/N1-N2/help)";
	}
	if ( "$ask_yn" eq "-yn" )
	{
		$ask_p = "(y/abort)";
	}
	while ( 1 )
	{
		report( '-n', 0, 0, "$ask_q? $ask_p:" );
		if ( $ask_choice eq "-c" )
		{
			report( -1, 0, 0, ":  or select one of: $ask_list (default $ask_default)\n$ask_cmd" );
		}
		report( 0, 0, "" );
		$ask_a = <STDIN>;
		chomp $ask_a;
		report( $tprint_askan, 0, "User answers $ask_a" );
		if ( $ask_yn eq "-yn" && $ask_a ne "y" && $ask_a ne "abort" )
		{
			report( '-n', 0, 0, "Only y or abort answers allowed for this question" );
			next;
		}
		if ( $ask_choice eq "-c" && ( ! $ask_a || $ask_a eq "y" ) )
		{
			$ask_a = $ask_default;
		}
		$ask_answer = $ask_a;
		if ( $ask_a eq "y" )
		{
			last;
		}
		if ( $ask_a eq "abort" )
		{
			report( '-n', 0, 0, "Are you sure you want to abort the script now? (y/n):" );
			report( 0, 0, "");
			$ask_sure = <STDIN>;
			chomp $ask_sure;
			report( $tprint_askan, 0, "User answers $ask_sure" );
			if ( $ask_sure ne "y" )
			{
				report( '-n', 0, 0, "You are not sure, please try again" );
				next;
			}
			report( '-n', 0, 0, "Aborting $pname at user request" );
			exit 1;
		}
		if ( $ask_a eq "n" && $ask_ns eq "-ns" )
		{
			report( '-n', 0, 0, "Answering n is not allowed for this question" );
			next;
		}
		if ( $ask_a eq "n" )
		{
			$ask_skip = "-s";
			$ask_not = "NOT";
			last;
		}
		if ( $ask_a eq "help" )
		{
			$msg = <<"EOF";
:help requested
:
:Valid answers are:
:y       # perform requested action and continue the script
EOF
			report( -1, '-n', 0, 0, $msg );
			if ( $ask_ns ne "-ns" )
			{
				$msg = <<"EOF";
:n       # no, continue the script without performing requested action
EOF
				report( -1, '-n', 0, 0, $msg );
			}
			$msg = <<"EOF";
:abort   # terminate the script immediately, you will be asked for confirmation
:N       # sleep N seconds and ask again, example: 20
:N1-N2   # sleep random interval between N1 and N2 seconds inclusive 
:# and ask again
:# while sleeping a line of output is printed every minute
:#   indicating time slept and time remaining to sleep
:# sleep can be interrupted by ctrl-c and you will be asked again
:help    # to see this message
:        # the script will stay in the question and answer loop
:        #   until you answer y n or abort
EOF
			report( -1, '-n', 0, 0, $msg );
			if ( $ask_choice eq "-c" )
			{
				report( -1, 0, 0, ":  or select one of: $ask_list (default $ask_default)\n$ask_cmd" );
			}
			$msg = <<"EOF";
:All answers must be entered exactly as above.
:Examples of invalid answers: yes no skip h
EOF
			report( -1, 0, 0, $msg );
			next;
		}
		if ( $ask_choice eq "-c" && $ask_clist =~ m/,$ask_a,/ )
		{
			last;
		}
		if ( dosleep( $ask_a ) )
		{
			report( '-n', 0, 0, "Invalid answer: $ask_a" );
			next;
		}			
	}
}


sub checkonodes
{
	my $checkonodes_in = $_[0];
	my $checkonodes_a = $checkonodes_in;
	my $checkonodes_b = $checkonodes_in;
	$checkonodes_a =~ s/ //g;
	$checkonodes_b =~ s/[[\\&|(){};<>?]//g;
	if ( ! $checkonodes_a || "$checkonodes_b" ne "$checkonodes_in" )
	{
		usage( "Invalid -n value: $checkonodes_in" );
	}	
}


sub checkoname
{
	my $checkoname_u = $_[0];
	my $checkoname_n = $_[1];
	my $checkoname_a = "d$checkoname_u";
	$checkoname_a =~ s/[a-zV]//g;
	if ( $checkoname_a )
	{
		usage( "Bad option: $checkoname_u" );
	}
	my $checkoname_b = $checkoname_n;
	if ( $checkoname_b !~ m/^$checkoname_u/ )
	{
		usage( "Invalid option: $checkoname_u" );
	}
}

# report to stdout and log
# [-1]: remove the first character from each printed line
# [-n]: print newline before output
# -1 -n, not -n -1 !
# 1: terminal output level
# 2: log output level
#  will print if level >= -v value
# 3...: message
sub report
{
	my $report_1 = $_[0];
	if ( $report_1 eq "-1" )
	{
		shift;
	}
	my $report_n = $_[0];
	if ( $report_n eq "-n" )
	{
		shift;
	}
	my $report_tlevel = $_[0];
	my $report_llevel = $_[1];
	shift;
	shift;
	my $report_msg = join " ", @_;
	my $timestr = "";
	local *FP;
	if ( $report_1 eq "-1" )
	{
		$report_msg =~ s/^://;
	}
	if ( $report_tlevel <= $overbose )
	{
		if ( $report_n eq "-n" )
		{
			print "\n";
		}
		print "$report_msg\n";
	}
	if ( $log )
	{
		if ( $report_llevel <= $overbose )
		{
			open ( FP, ">>$log");
			if ( $report_n eq "-n" )
			{
				printf FP "%s", "\n";
			}
			$timestr = localtime();
			printf FP "%s:  %s\n", $timestr, $report_msg;
			close ( FP );
		}
	}
}

sub usage
{
	my $usage_parm = join " ", @_;
	if ( $usage_parm )
	{
		report( '-n', 0, 0, $usage_parm );
		report( 0, 0, "For help invoke 'opatch auto -h'"  );
		exit 1;
	}
	my $sed_hhh = 's/hello/OK/';
	my $egrep_hhh = '^ 1 OK *$';
	my $grep_hhh = '^OK';
	my $help_msg1 = <<"EOF";
:Usage: 
:    
:  opatch auto -h       # to see this message
:
:  This command must be run as root user and needs Opatch version
:  10.2.0.4.7 or above. 
:  Case 1 -  On each node of the CRS cluster in case of Non Shared CRS Home.
:  Case 2 -  On any one node of the CRS cluster is case of Shared CRS home.
:
:
EOF

my $help_msg2 = <<"EOF";
:All of the following forms must be run as root on each of the cluster nodes
:
:  1:
:
:  $pname -ionly [-n blank_delimited_node_list]
:    [-a interactive_option] [-l log_file_location] [-v verbose_level]
:    [-vf output_verification_file_name]
:
:# to run opatch lsinventory -detail and do nothing else
:# the command is run on all nodes for CRS_HOME and all ORACLE_HOMEs
:# so it may take a while
:
:  2:
:
:  $pname [-patchdir patch_directory] [-n blank_delimited_node_list]
:    [-r] [-c] [-i] [-batch|-int] [-onerror ask|abort|continue]
:    [-a interactive_option] [-l log_file_location] [-v verbose_level]
:    [-vf output_verification_file_name]
:    [-w N[-M]]
:
:# to patch the cluster using a patch that's already uncompressed
:
:  3:
:
:  $pname patchfile patch_archive_location
:    -patchdir patch_directory -patchnum patch_number
:    [-clean] [-local]
:    [-n blank_delimited_node_list]
:    [-r] [-c] [-i] [-batch|-int] [-onerror ask|abort|continue]
:    [-a interactive_option] [-l log_file_location] [-v verbose_level]
:    [-vf output_verification_file_name]
:    [-w N[-M]]
:
:# to patch the cluster using a compressed patch archive
:
:  4:
:
:  $pname -rollback
:    [-patchdir patch_directory] [-n blank_delimited_node_list]
:    [-r] [-c] [-i] [-batch|-int] [-onerror ask|abort|continue]
:    [-a interactive_option] [-l log_file_location] [-v verbose_level]
:    [-vf output_verification_file_name]
:    [-w N[-M]]
:
:# to rollback a previously installed patch which is still 
:  available uncompressed
:
:$pname options reference:
:
: See also examples in detailed help printed with $pname -hh
EOF
#FIXME - enable -a option if needed after tidying up the usage.
my $help_msg3 = <<"EOF";
: -a interactive_option
:            affects what questions, if any, you will be asked as
:            the script runs along. Possible values are:
:              all        # maximum interactivity
:              none       # no questions asked
:              suboption[,suboption]...
:                         # only questions controlled by listed suboptions
:    will be asked. Example: node,op,pd
:    Default:
:      node    if neither -batch nor -int is specified
:      all     if -int is specified
:      none    if -batch is specified
:    Supported suboptions are:
:      lsi     # ask before running opatch lsinventory
:                only matters if you also specify -i or -ionly
:      node    # ask if you want to continue, after patching each node
:                also controls all ATM test script related questions
:      op      # if NOT specified, opatch apply will use -silent option
:      pd      # ask for confirmation before writing to patch directory
:      step    # ask for confirmation for all other script actions
:    Valid answers to the questions are:
:      y       # perform requested action and continue the script
:      n       # no, continue the script without performing requested action
:      abort   # terminate the script immediately, 
:                you will be asked for confirmation
:      N       # sleep N seconds and ask again, example: 20
:      N1-N2   # sleep random interval between N1 and N2 seconds inclusive 
:              # and ask again
:              # while sleeping a line of output is printed every minute
:              #   indicating time slept and time remaining to sleep
:              # sleep can be interrupted by ctrl-c and you will be asked again
:              #   Note that ctrl-c entered outside of a sleep will abort
:              # the script
:      help    # to see help on valid answers
:              # the script will stay in the question and answer loop
:              #   until you answer y n or abort
:
:      All answers must be entered exactly as above.
:      Examples of invalid answers: yes no skip h and the empty string or blanks
:
:      Certain questions allow more choices in addition to those above,
:      others will not allow the 's' answer, or allow only y or n answer.
:      For each question the prompts and help output provide clear
:      indication as to which answers are supported.
:        Note that even with -a none the question related to command
:      outcome verification failure is still asked
:      so for completely silent mode invoke with
:                         -a none -onerror abort
:      or
:                         -a none -onerror continue
:      Note that option -a can't be used together with either
:      of -batch, -int
:
: -b   (-batch) Equivalent to -a none -onerror continue,
:      can not be used together with either of -a, -onerror, -int
:      
: -c         Allows user to change the order of nodes to patch.
:              Before proceeding to the next node you will be asked
:            for confirmation and given an opportunity to change the node name.
:              Similar procedure will apply when all nodes specified by -n
:            are exhausted.
:              It is expected that the nodenames you enter are cluster members
:            but no verification is done.
:
: -clean     Remove files and directories under the patch directory
:              before uncompressing the patch.
:            -clean can only be used if -patchfile is specified
:            The cleanup is dome as CRS user, not root.
:
: -h         help
EOF
my $help_msg4 = <<"EOF";
:
: -hh        detailed help
:
: -i         run opatch lsinventory -detail for CRS_HOME and each
:            ORACLE_HOME, on each node, before and after patching,
:            which takes lots of time
:              You will be asked for confirmation if suboption 'lsi' of -a
:            is in effect
:
: -int       (-interactive) Equivalent to -a all -onerror ask,
:            can not be used together with either of -a, -onerror, -b
:      
:
: -ionly     run opatch lsinventory -detail for CRS_HOME and each
:            ORACLE_HOME, on each node, which takes lots of time,
:            but do nothing else, no patching is performed.
:              You will be asked for confirmation if suboption 'lsi' of -a
:            is in effect
:
: -l log_file_location    default if you run it in the current directory:
:            $dlname
:            The log file contains everything you see on the terminal, and more.
:            Each log message contains a timestamp.
:
: -local     -local can only be used if -patchfile is specified
:              If -local is used, the patch directory is considered to be
:            node local storage and all related operations such as 
:            directory creation, cleanup and patch unzipping 
:            are performed on each cluster node.
:              If -local is not used, patch directory is considered to be shared
:            and all operations above are performed on the current node only.
:
:
:
: -onerror ask|abort|continue
:            Default: ask, unless -b is specified which sets -onerror continue
:            Determines the action which is performed when a command
:            appears to have terminated abnormally, based either on
:            non-zero exit code or command output verification failure.
:
:              ask        ask user what to do
:                         The question will be asked even with -a none,
:                         so for completely silent mode invoke with
:                         -a none -onerror abort
:                         or
:                         -a none -onerror abort
:              abort      terminate the script
:              continue   ignore the error and continue the script execution
:      Note that option -onerror can't be used together with either
:      of -batch, -int.
:
: -patchdir  patch_directory
:                         default is the current directory,
:            but must be specified explicitly if you use -patchfile
:              If -patchfile is not specified, the patch directory must be
:            available on each node under the same pathname with identical
:            directory contents. Whether it's shared or node local is 
:            irrelevant.
:              No validation whatsoever is done for patch directory contents.
:
:              If -patchfile is used you have to tell the script whether 
:            the patch directory is shared or node local by using
:            -local if necessary. 
:              If -patchfile is used, the directory will be created if necessary.
:              All patch directory write operations are done as CRS USER, 
:            not root.
:              Another important thing to consider is that when the patch is 
:            already uncompressed you want to specify -patchdir with
:            the patch number component: -patchdir /work/patch/5256865
:              On the other hand if you uncompress the patch you want
:            to specify a directory one level up because the patch
:            contains files in the form of 5256865/* so you invoke
:            $pname with something like
:
:            -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:              -patchnum 5256865 -patchdir /work/patch
:
:            The script will then
:            automatically switch to the right directory after uncompressing.
:
:            You should be very careful with -clean in this case because
:            an invocation like this will remove everything under /work/patch:
:
:            -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:              -patchnum 5256865 -patchdir /work/patch -clean
:
:            So the preferred way is to use a disposable -patchdir in this case:
:
:            -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:              -patchnum 5256865 -patchdir /tmp/patch -clean
:
:              Non-absolute pathnames for -patchdir are supported but
:            not encouraged.
:
: -patchfile patch_archive_location
:                         no default
:            If specified, you must also specify -patchn and -patchdir.
:              If -local is specified to indicate node local patch directory,
:            this file is considered to be on node local storage as well.
:              It's OK to keep the file on shared storage but in any case
:            it will be first copied, with rcp, to the patch directory
:            on each node, then uncompressed from there.
:              Non-absolute pathnames for -patchfile are supported but
:            not encouraged.
:
: -patchnum patch_number  no default, must be specified if and only if
:            you use either -patchfile or -rollback.
:              The value must correspond to the patch archive contents
:            but no validation is done.
:
:
EOF
my $help_msg5 = <<"EOF";
:PARAMETERS
:
:Patch Location
:              Path to the location for the patch. If the patch
:              location is not specified, then the current directory
:              is taken as the patch location
:OPTIONS
:
: -rollback    The patch will be rolled back, not applied
:
:
: -oh          comma seperated list of Oracle homes to patch
:              The default is all applicable Oracle  Homes.
:              use this option  to patch RDBMS homes where 
:              no database is registered. 
:
: -och         Path of Oracle Clusterware home.
:              use this option to patch only clusterware home
:              with stack down.Do not use this option with CRS
:              stack up. This only patches the Clusterware home
:              
:
EOF
my $help_msg6 = <<"EOF";       
: -v verbose_level        Terminal output level
:              Doesn't affect log output which always contains everything
:            you see on the terminal, and more.
:              Defaults to 0 which is usually sufficient.
:            1 is the same as 0 for all practical purposes
:            2 provides lots of output, essentially everything that normally
:              goes to log only, will be printed on he terminal as well.
:            anything over 2 is the same as 2
:
: -vf output_verification_file_name
:            allows some control over command output verification
:            process, try $pname -hh to see appropriate example(s)
:
: -V         Display program version and do nothing else
:
:
: -oh, -och, -s, -x       strictly for internal use,
:            try to use them if you are looking for trouble
:
EOF
my $help_msg7 = <<"EOF";
: Suggested mode of operation:
:
:# 1. apply the patch with the unzipped patch location
:     This applies the patch to all applicable homes on the machine
:
: opatch auto <Patch Location>
:
:# 2. Rollback the patch. 
:     This rolls back the patch from all the applicable homes on the machine
:
: opatch auto -rollback <Patch Location>
:
:# 3. apply the patch with -oh option
:     This option allows to apply patch on selective list of oracle homes
:
: opatch auto <Patch Location> -oh /ora/oh1,/ora/oh2,/ora/oh3
:
:# 4. apply the patch with -och option
:     This option is used to only patch the CRS home when 
:     Clusterware stack is down.
:
: opatch auto <Patch Location> -och /ora/ora_crs_home
: 
EOF
	report( '-1', '-n', 0, 0, $help_msg1.$help_msg5.$help_msg7 );

	$help_msg1 = <<"EOF";
: $pname doesn't have any arguments, just options
:   as far as user is concerned. Some forms of invocation with arguments
: are used internally.
:
: $pname options can be prefixed by - or -- and can be reasonably abbreviated
: Each option must be a separate shell argument.
: Each option argument must also be a separate shell argument.
: Valid examples: -v 2 -i -r 
:                 --verb 2 -i --r
:                 -verbose 2 -inventory -r
: Invalid examples:
:                -v2 
:                -ri
:                -virboze 2
:
: $pname option abbreviation and full names:
:   
:  Abbreviation      Full name
:
:  -a                -$optnamea
:  -b                -$optnameb
:  -c                -$optnamec
:  -clean            -$optnameclean
:  -i                -$optnamei
:  -int              -$optnameint
:  -ionly            -$optnameionly
:  -h                -$optnameh
:  -hh               -$optnamehh
:  -l                -$optnamel
:  -local            -$optnamelocal
:  -n                -$optnamen
:  -on               -$optnameon
:  -patchd           -$optnamepatchd
:  -patchf           -$optnamepatchf
:  -patchn           -$optnamepatchn
:  -r                -$optnamer
:  -rollback         -$optnamerollback
:  -v                -$optnamev
:  -vf               -$optnamevf
:  -V                -$optnameVV
:  -w                -$optnamew
:  -x                -$optnamex
:
:     Command output verification and its customization
:
: Each command has an identifier as far as output verification
: is concerned. The IDs are hardcoded in the script and are easily
: identifyable from the log. On output verification failure 
: the log will also contain enough information to troubleshoot the problem
: without looking into the script itself.
:   The verification is done using two variables with ID dependent
: names assignment to which is hardcoded in the script.
:   Consider an example where we want to verify the output of 'echo hello'
: and we use an ID of hhh. The variable assignment might look like this:
:
: sed_hhh='s/hello/OK/'  # a sed script
: egrep_hhh='^ 1 OK *\$'  # an egrep regular expression
: grep_hhh='^OK'         # a grep regular expression, used only after a failure
:                        #   to try to explain what went wrong
:
: The script performs the verification as follows:
:
: 1. echo hello | sed "$sed_hhh"
:    the result will be 'OK'
: 2. this result is passed to sort | uniq -c 
:    now we have something like '     1  OK   '
: 3. All newlines, if any, and extra blanks are removed
:    now we have ' 1 OK '
: 4. Output from the previous step is passed to egrep "$egrep_hhh"
: 5. Verification fails unless output from steps 3 and 4 are equal
: 6. If the verification failed, output of step one will be passed
:    to grep -v "$grep_hhh". If the resulting output contain any lines,
:    they are shown to the user as 'output line the script did not expect'
:
: The only way to customize output verification process is to specify
: the -vfile option such as:
:
: $pname ... -vfile vf.sh
:
: vf.sh is expected to be a file which contains reassignments for
: some of the sed_* and egrep_* values. It is sourced by the script
: with the equivalent of 
:
: . vf.sh
:
: so it must be a valid Bourne shell script. Additionally it must not
: produce any output or else $pname will report a failure.
:
: Sample vf.sh, invalid, bad shell syntax:
:
: sed_hhhh="abc"
:
: Sample vf.sh, invalid, produces output
:
: echo setting sed_hhhh.
: sed_hhhh='s/x/OK/'
:
: Sample vf.sh, invalid, bad sed syntax:
:
: sed_hhhh="abc"
:
: # note that this will not be rejected when sourcing vf.sh but rather
: # when the script gets to the actual validation
:
: Sample vf.sh, valid, allows both 'hello' and 'hi'
:  (the real thing wouldn't contain any leading blanks)
:
: sed_hhhh='
: s/hello/OK/
: s/hi/OK/
: '
:
:     ATM test script interface
:
: parameter(s)    description
:   1               run a subset of tests
:   2               run all P0 tests
:   3               start the workload
:   4               stop the workload
:
: The output of 1|2 invocations is saved in the standard $pname log file
: and the exit code is verified.
: The output of 3|4 invocations is saved in a separate log file
: which has the same base name and location as the standard log file
: but .atm.log as its extension
:
: Unless you specify -tsl none, $pname must be executed on ATM master node
: The test script is invoked on the same node, as CRS user.
:
: After starting the workload, and after patching each node, but before
: running tests, $pname will sleep to allow the workload to properly
: (re)balance over all nodes. The sleep period length is controlled
: by the -w option, default $warmup_default
:
:
:     $pname usage examples:
:     =====================
:
: Example 1:
: # show $pname version and do nothing else
: $pname -V
:
: Example 2:
: # the best way to run lsinventory is standalone in batch mode
: $pname -ionly -a none -l lsi.out
:
: Example 3a:
: # invoking $pname without parameters will make a semisilent
: # installation from the current directory which is expected to be
: # available on all cluster nodes with the same pathname and contents
:
: $pname 
:
: Example 3a-1:
: # same as above, illustrates the defaults for interactive options
: $pname -a node -onerror ask
:
: Example 3b:
: # add -a none and -onerror continue 
: # to get completely non-interactive application,
: # still from the current directory
:
: $pname -a none -onerror continue
:
: # which is equivalent to
:
: $pname -batch
:
: Example 3b-1:
: # like 3b but aborts on any error
:
: $pname -a none -onerror abort
:
: Example 3b-2:
: # here the only question that will be asked is to whether to continue
: # or abort if a command fails
:
: $pname -a none 
:
: Example 3b-3:
: # like 3b-1 but uses a customized output verification file
:
: $pname -a none -onerror abort -vf vf.sh
:
: Example 3c:
: # use -a node to get an application that asks questions only after
: # patching each node, this is the current default:
:
: $pname -a node
:
: Example 3c-1:
: # completely interactive form, all possible questions are asked,
: # used to be the default, until v 1.3.0:
:
: $pname -a all -onerror ask
:
: # here's a sample dialog which shows how you can make the script go to sleep
: # presumably to let you test the partially upgraded cluster in the meantime
: # It also illustrates some other dialog features
:
:
:Node strdr01 patched, continue? (y/abort/N/N1-N2/help):
:
:n
:
:Are you sure you want to abort the script now? (y/n):
:
:n
:
:You are not sure, please try again
:
:Node strdr01 patched, continue? (y/abort/N/N1-N2/help):
:
:5
:
:Sleeping 5 second(s), ctrl-c to wake up
:
:Node strdr01 patched, continue? (y/abort/N/N1-N2/help):
:
:1-5
:
:Sleeping 4 second(s), ctrl-c to wake up
:
:Node strdr01 patched, continue? (y/abort/N/N1-N2/help):
:
:600-1800
:
:Sleeping 653 second(s), ctrl-c to wake up
:slept 1 minute(s), 593 second(s) left, ctrl-c to wake up...
:slept 2 minute(s), 533 second(s) left, ctrl-c to wake up...
:
:sleep interrupted by a signal
:
:Node strdr01 patched, continue? (y/abort/N/N1-N2/help):
:
:y
:
:Patch node strdr02? (y/n/abort/N/N1-N2/help):
:
:
: Example 3c-2:
:
: # using custom test script location
:
: $pname -tsl /work/scripts/myscript.sh
:
:
: Example 3c-3:
:
: # disabling test script invocation
:
: $pname -tsl none
:
: Example 3c-3:
: # specifying non-default warmup period
:
: $pname -w 600-900
:
: Example 3d:
: # custom log name
:
: $pname -l p123456.log
:
: # here's a log excerpt:
:
: 2007-01-29 18:31:15.298590000 PST: User answers 'abort'
:
: 2007-01-29 18:31:15.798320000 PST: Are you sure you want to abort the script now? (y/n):
: 2007-01-29 18:31:16.045054000 PST:
: 2007-01-29 18:31:18.070659000 PST: User answers 'y'
:
: 2007-01-29 18:31:18.568391000 PST: Aborting ora_crs_patch.sh at user request
:
: 2007-01-29 18:31:19.061246000 PST: ora_crs_patch.sh terminating with exit code 1
:
: Example 3e:
: # specifying node list to patch:
:
: $pname -n 'strdr02 strdr04'
:
: Example 3f:
: # randomizing node order to patch, can be used with -n as well
:
: $pname -r
:
: # sample output excerpt:
:
: ORA_CRS_HOME is /oracle/CRSHome
: Oracle CRS user is ractest
: Cluster nodes are strdr01 strdr02 strdr03 strdr04
: Nodes to patch are strdr04 strdr03 strdr02 strdr01
:
: Example 3g:
: # allowing user to change node names to patch on the fly
:
: $pname -c
::
: # sample dialog that this option eventually invokes:
:
: Nodes to patch:  strdr01 strdr02 strdr03 strdr04
: Nodes patched :
:
: Next node to patch is strdr01, <Enter> to confirm or type node name to patch:
:  If you do enter nodename it must be in the cluster but no validation is done
:
: # and later
:
: Nodes to patch:  strdr01 strdr02 strdr03 strdr04
: Nodes patched :  strdr02
:
: No more nodes to patch, <Enter> to confirm or type node name to patch:
:  If you do enter nodename it must be in the cluster but no validation is done
:
: Example 3h:
: # suppose you want to run lsinventory before and after patching
:
: $pname -i
:
: Example 3i:
: # most of the above
:
: $pname -a node -l p123456.log -n 'strdr01 strdr02 strdr03' -r -c -i
:
: Example 4a:
: # use uncompressed patch in a directory different from current
: 
: $pname -patchdir /work/patch/5256865
:
: # note what the patchdir is expected to look like:
:
:# cd /work/patch/5256865
:# ls
:custom  etc  files  README.txt
:
: Examples 4[b-i]:
: # Example 4 modified with the extra options listed in Examples 3[b-h] above
:
: Example 5:
: # Uncompressing the patch into a shared directory:
:
: $pname -patchdir /work/patch/xxx
:   -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:   -patchnum 5256865
:
: Examples 5[b-i]:
: # Example 5 modified with the extra options listed in Examples 3[b-h] above
:
: Example 5j:
: # Restricts interactivity to questions related to patch directory writes
: # and confirmation after patching each node
:
: $pname -patchdir /work/patch/xxx -a pd,node
:   -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:   -patchnum 5256865
:
: Example 6:
: # uncompressing the patch into node local directory
: #   can be modified like in Examples 5* above
:
: $pname -patchdir /tmp/patch -local
:   -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:   -patchnum 5256865
:
: Example 7:
: # uncompressing the patch into node shared directory
: # with directory cleanup
: #   can be modified like in Examples 5* above
:
: $pname -patchdir /work/patch/xxx -clean
:   -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:   -patchnum 5256865
:
: Example 8:
: # uncompressing the patch into node local directory
: # with directory cleanup
: #   can be modified like in Examples 5* above
:
: $pname -patchdir /tmp/patch -local -clean
:   -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:   -patchnum 5256865
:
: # to illustrate the difference between -patchdir treatment 
: # with and without -patchfile, here's what the patch directory
: # will contain after patching
:
:/tmp/patch/p5256865_10202_Linux-x86-64.zip
:
:/tmp/patch/5256865:
:custom
:etc
:files
:README.txt
:
:
: Example 9
: # the patch is rolled back. In this case you specify -rollback,
: # -patchnum (required), and a combination of -patchfile and/or 
: # -patchdir in order to locate the patch. Even for rollback you still
: # need the patch because rolling back requires execution of
: # all pre/post patch scripts. 
:
: $pname -rollback -patchdir /tmp/patch -local -clean
:   -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
:   -patchnum 5256865
:
: # this example also shows that options used with patch application
: # can also be used with patch rollback
EOF
	report( '-1', '-n', $tprint_help, 0, $help_msg1 );
	exit 0;
}

sub checkoptarg
{
	my $checkoptarg_opt = $_[0];
	shift;
	my $parm = join " ", @_;
	if ( $parm !~ m/^-*/ )
	{
		usage( "option $checkoptarg_opt requires an argument" );
	}
}

# run command as user on local host
# [async log] run asynchronously, append output and error to log,
#             pid returmed through run_rpid
# [-v id] verification id
# [-s] skip, don't run anything
# -v foo -s, not -s -v foo
# 1: user name
# 2: abort script if command fails and this is y
# 3... command
sub run
{
	my $parms = join " ", @_;
	my $run_alog = "";
	my $run_vid = "";
	my $run_1 = "";
	my $run_skip = "";
	my $run_user = "";
	my $run_abort = "";
	my $run_command = "";
	my $run_rc = "";
	my $ret = "";
	report( $tprint_run, 0, "run: invoked with $parms" );
	my $run_async = $_[0];
	if ( $run_async eq "-async" )
	{
		$run_alog = $_[1];
		shift;
		shift;
	}
	$run_vid = "";
	$run_1 = $_[0];
	if ( $run_1 eq "-v" )
	{
		$run_vid = $_[1];
		shift;
		shift;
	}
	if ( ! $_[0] )
	{
		shift;
	}
	$run_skip = $_[0];
	if ( $run_skip eq "-s" )
	{
		report( '-n', 0, 0, "will skip this action per user request" );
		return;
	}
	$run_user = $_[0];
	$run_abort = $_[1];
	shift;
	shift;
	$run_command = join " ", @_;
	if ( $run_async eq "-async" )
	{
		if ( $run_user eq "root" )
		{
			$run_rpid = `$osimulate $run_command >> $run_alog 2>&1 &
$echo \$!`;
		}
		else
                {
			$run_rpid = `$su $run_user -c \"$osimulate $run_command\" >> $run_alog 2>&1 &
$echo \$!`;
		}
		chomp $run_rpid;
		print "command started asynchronously, log is $run_alog\n";
		print "command pid is $run_rpid, log $run_alog\n";
		return;
		
	}
	while ( 1 )
	{
		if ( $run_user eq "root" )
		{
			system( "$osimulate $run_command >$tmpfo 2>&1" );
			$run_rc = "$?";
		}
		else
		{       
			system( "$su $run_user -c \"$osimulate $run_command\" >$tmpfo 2>&1" );

			$run_rc = "$?";
		}
		report( $tprint_run, 0, "run: exit code $run_rc after $run_command" );
		if ( ! $run_vid )
		{
			last;
		}
	 	$ret = verify( $run_vid, $tmpfo, $run_rc );
		if ( $ret eq "retry" )
		{
			next;
		}
		last;
	}
	report( $tprint_run, 0, "run: finish as $run_user $run_command" );
	if ( $run_abort eq "y" )
	{
		if ( "$run_rc" ne "0" )
		{
			usage( "Aborting because of exit code $run_rc as $run_user from $run_command" );
		}
	}

}

# run command on remote host as user
# [-v id]   output verification id
# [-s] skip, don't run anything
# -v foo -s, not -s -v foo
# 1: user
# 2: hostname
# 3: abort script if command fails and this is yes
#    isn't expected to work on all systems
# 4... command to run
sub remote
{
	my $remote_vu = "";
	my $remote_isv = "";
	my $remote_skip = "";
	my $remote_user = "";
	my $remote_host = "";
	my $remote_abort = "";
	my $remote_command = "";
	my $remote_torun = "";
	my $parms = join " ", @_;
	report( $tprint_remote, 0, "remote: invoked with $parms" );
	$remote_vu = "";
	$remote_isv = $_[0];
	if ( $remote_isv eq "-v" )
	{
		$remote_vu = $_[1];
		shift;
		shift;
	}
	$remote_skip = $_[0];
	if ( $remote_skip eq "-s" )
	{
		report( 0, 0, "will skip this action per user request" );
		return;
	}
	if ( ! $remote_skip )
	{
		shift;
	}
	$remote_user = $_[0];
	$remote_host = $_[1];
	$remote_abort = $_[2];
	shift;
	shift;
	shift;
	$remote_command = join " ", @_;

        #decide between ssh and rsh
        $cmd = "$su $ORA_CRS_USER -c  \"$ssh $host date\"";
        system("$cmd > $dev_null 2>&1");
        if ($?)
        {
         $cmd = "$su $ORA_CRS_USER -c  \"$rsh $host date\"";
         system("$cmd > $dev_null 2>&1");
         if ($?)
         {
          report( '-n', 0, 0, "SSH/RSH is not configured  across cluster nodes");
          exit 0;
         }
         else
         { 
          report( '-n', 0, 0, "SSH not configured, Using RSH for remote operations" );
	  $remote_torun = "$rsh $remote_host $pfull -x -v $overbose -oh $ORACLE_HOME";
         }
        }
        else
        {
         #report( '-n', 0, 0, "Using SSH for remote operations");
         $remote_torun = "$ssh $remote_host $pfull -x -v $overbose -oh $ORACLE_HOME";
        }
	$remote_torun = "$remote_torun -och $ORA_CRS_HOME";
        $remote_torun = "$remote_torun -patchn $opatchn";
	$remote_torun = "$remote_torun -patchdir $opatchdir $remote_command";
	if ( $remote_vu )
	{
		run( $remote_isv, $remote_vu, $remote_user, $remote_abort, "$remote_torun" );
	}
	else
	{
		run( $remote_user, $remote_abort, "$remote_torun" );
	}
	report( $tprint_remote, 0, "remote: finish on $remote_host as $remote_user $remote_command" );
}

# get ORA_CRS_HOME and ORA_CRS_USER
sub getoch
{
	my @parms = ();
	if ( ! -f $initcssd )
	{
		usage( "init.cssd script '$initcssd' not found" );
	}
	local *CSSD;
	open( CSSD, "<$initcssd" ) or die "Cann't open $initcssd";
	while ( <CSSD> )
	{
		if ( $_ =~ m/^ORA_CRS_HOME/ )
		{
			@parms = split( /=/, $_ );
			$ORA_CRS_HOME = $parms[1];
			chomp $ORA_CRS_HOME;
		}
		if ( $_ =~ m/^ORACLE_USER/ )
		{
			@parms = split( /=/, $_ );
			$ORA_CRS_USER = $parms[1];
			chomp $ORA_CRS_USER;
		}
		if ( $ORA_CRS_HOME && $ORA_CRS_USER )
		{
			last;
		}
	}
	if ( ! $ORA_CRS_HOME )
	{
		usage( "Failed to discover ORA_CRS_HOME in $initcssd" );
	}
	if ( ! $ORA_CRS_USER )
	{
		usage( "Failed to discover ORA_CRS_USER in $initcssd" );
	}
	$ORACLE_HOME = $ORA_CRS_HOME;
	$srvctl = "$ORA_CRS_HOME/bin/srvctl";
	$crsctl = "$ORA_CRS_HOME/bin/crsctl";
	$crs_stat = "$ORA_CRS_HOME/bin/crs_stat";
	$olsnodes = "$ORA_CRS_HOME/bin/olsnodes";
        $lsnodes  = "$ORA_CRS_HOME/bin/lsnodes";

        #check if clusterware is up on the node
        report( '-n', 0, 0, "Checking if Clusterware is up" );
        $cmd = "$crsctl check crs";
        run('-v', 'crsctl_check_crs', $ORA_CRS_USER,'n', $cmd );
        if (($stackrun eq "false") && (! $ooch))  
        {
         report( '-n', 0, 0, "Clusterware is not up on node $host. You have the following 2 options");
         report( '-n', 0, 0, "1. Start the Clusterware on this node and re-run the auto_patch tool");
         report( '-n', 0, 0, "2. OR Run the auto_patch tool with the -och <CRS_HOME_PATH> option and then invoke auto_patch tool with -oh <comma seperated ORALCE_HOME_LIST> to patch the RDBMS homes");
         exit 0;
        }          
 
	report( '-n', 0, 0, "Looking for configured cluster nodes" );
	run( '-v', 'olsnodes', 'root', 'y', $olsnodes );

	# ocp_nodes is the lst of discovered cluster nodes, its source is $olsnodes
	@ocp_nodes = `$olsnodes`;
	chomp @ocp_nodes;
	# ocp_nodes is the list of nodes to patch, its source is -n then $ocp_nodes
	$ocp_nodelist = join " ", @ocp_nodes;
	print "$ocp_nodelist\n";
	if ( $orandom )

	{
		@ocp_nodes = shuffle( @ocp_nodes );
	}
	if ( ! $onodes )
	{       report( '-n', 0, 0, "Getting Local node name" );
                run( '-v', 'olsnodes', 'root', 'y', "$olsnodes -l" );
                $local_node = `$olsnodes -l`;
                $local_node = trim($local_node);
		@ocp_nodes_topatch = $local_node;
		$ocp_nodes_tplist = join " ", @ocp_nodes_topatch;
	}
	else
	{
		@ocp_nodes_topatch = split( /\s+/, $onodes );
		$ocp_nodes_tplist = join " ", @ocp_nodes_topatch;
	}
}

# get ORACLE_HOMEs and users
sub getoh
{
	my @tmps = ();
	my $db = "";
	my $oh = "";
	my $getsrv_cmd = "";
	my @ohs = ();
	my @ocp_srvs = ();
	my $ocp_srvn = 0;
	my $getoh_ox = "";
	my $getoh_u = "";
	my $getoh_n = "";
	my $getoh_ata = "";
        #if ((! $ooh) && (! $ooch))
        if ($stackrun eq "true")
        {
	report( '-n', 0, 0, "Looking for configured databases on node $local_node" );
	run( '-v', 'srvctl_config', 'root', 'y', $srvctl, 'config' );
	@ocp_databases = `$srvctl config`;
	chomp @ocp_databases;
	$ocp_dblist = join " ", @ocp_databases;
	report( 0, 0, "Databases configured on node $local_node are: $ocp_dblist" );
	report( '-n', 0, 0, "Determining ORACLE_HOME paths for configured databases" );
	$ocp_ohlist = "";
	@ocp_ohs = ();
	foreach $db ( @ocp_databases )
	{
		#report( 0, 0, "Looking at database $db" );
		run( '-v', 'srvctl_config_db', 'root', 'y', "$srvctl config database -d $db" );
		@ohs = `$srvctl config database -d $db`;
		chomp @ohs;
		if ( @ohs == 0 )
		{
			report( 0, 0, "No ORACLE_HOME found for $db" );
		}
		else
		{
			@tmps = split( /\s+/, $ohs[0] );
                        $dboh{$db} = $tmps[2];
		}
		$getsrv_cmd = "$srvctl config service -d $db";
		report( 0, 0, "Retrieving configured services for Database $db" );
		run( '-v', 'srvctl_config_service', 'root', 'y', $getsrv_cmd );
		@ocp_srvs = `$getsrv_cmd`;
		chomp @ocp_srvs;
		$ocp_srvn = @ocp_srvs;
		report( 0, 0, "There are $ocp_srvn services configured for Database $db" );
		for ( my $nn=0; $nn<@ocp_srvs; $nn++ )
		{
			@tmps = split( /\s+/, $ocp_srvs[$nn] );
			$ocp_srvs[$nn] = $tmps[0];
		}
		$ocp_srvlist = join ",", @ocp_srvs;
		push @ocp_services, [@ocp_srvs];
	}
       
        #create hash oracle home to dbs
        foreach $db (keys%dboh)
        {
         if(defined($ohdb{$dboh{$db}})) {
         $ohdb{$dboh{$db}} = "$ohdb{$dboh{$db}}:$db";
         } else {
           $ohdb{$dboh{$db}} = "$db";
         }
        }                 
 
        #get unique oracle home list
        @ocp_ohs = keys%ohdb;

        #Add ASM oracle home
        run( '-v', 'srvctl_config_asm', 'root', 'y', "$srvctl config asm -n $host" );
        $asmcfg = `$srvctl config asm -n $host`;        
        if ((! $?) && ($asmcfg))
        {
         @tmps = split( /\s+/, $asmcfg );
         $asm_home = $tmps[1];
         print "asm home is $asm_home\n";
         foreach $oh (keys%ohdb)
         {
          if ($asm_home eq $oh)
          {
           ++$asmcount;
          }
         }
         if ($asmcount == 0)
         {
           push @ocp_ohs, $asm_home;
         }
        }

        foreach $oh (keys%ohdb)
        {
         report( '-n', 0, 0, "Oracle Home $oh is configured with Database\(s\)\-\> $ohdb{$oh}");
        }

	$ocp_oulist = "";
	@ocp_ous = ();
        if ($ooh)
        {
          @tmp_ohlist1 = split( /\,/, $ooh );
          foreach $line (@tmp_ohlist1)
          {
           if (!($line eq $ORA_CRS_HOME))
           {
            push @tmp_ohlist,$line;
           }
           else
           {
            $patchcrs = "true";
           }
          }
          @ocp_ohs = @tmp_ohlist;
        }
        else
        {
          @tmp_ohlist = @ocp_ohs;
        }
        }
	foreach $oh ( @ocp_ohs )
	{
		$getoh_ox = "$oh/bin/oracle";
		if (  -f $getoh_ox )
		{
			my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat( $getoh_ox );
			($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwuid( $uid );
			$getoh_u = $name;
			report( 0, 0, "Oracle user for $oh is $getoh_u" );
			$ocp_oulist = "$ocp_oulist $getoh_u";
			push @ocp_ous, $getoh_u; 
                        $ohowner{$oh} = $getoh_u;
		}
		else
		{
			usage( "Failed to locate oracle executable $getoh_ox. Check the Oracle Home Path supplied" );
		}
		
	}
	
}

#Get patch ids in case of n-apply patches
sub getPatchids
{
 my $searchdir = $_[0];
 my $ids;
 my $line;
 my $idx;

 my @dbids = <$searchdir/*>;
 foreach $line (@dbids)
 {
  chomp($line);
  if ( -d $line) {
   $idx++;
   my @temp = split(/\//, $line);
   $ids = $ids . $temp[-1] . ",";
  }
 }
 chop $ids;
 return ($idx, $ids);
}

#Check if CRS stack is running
sub checkCrsStack
{
 my $stat;
 
 my $status_cssd = system("crsctl check cssd");
 my $status_evmd = system("crsctl check evmd");
 my $status_crsd = system("crsctl check crsd");

 if ((! $status_cssd) &&
     (! $status_evmd) &&
     (! $status_crsd)) {
     $stat = 0;
 }
 else{
     $stat = 1;
 }
 return $stat;
}

#Check if CRS is configured on vendor cluster
sub checkVendor
{
 my $stat;
 
 my $status_vndr = system("$lsnodes > /dev/null 2>&1");
 if (! $status_vndr) {$stat = 1;}

 return $stat;
 
}

sub gentimeStamp
{
my ($sec, $min, $hour, $day, $month, $year) =
        (localtime) [0, 1, 2, 3, 4, 5];
$month = $month + 1;
$year = $year + 1900;

my $ts = sprintf("%04d-%02d-%02d_%02d:%02d:%02d",$year, $month, $day, $hour, $min, $sec);
return $ts;
}

# START script execution
# process options
$g_startdir = $pwd;
my $parms = join " ", @ARGV;
my $invoked = "$0 $parms";
my $ret = "";
my $inst = "";
my $p1 = "";
my @tmparray = ();
my $logdir = "";
my $msg = "";
my @tmps = ();
my @ocp_srvs = ();
my $after_patch_node = "";
my $patched_nodes = "";
my $srv_str = "";
$overbose = 0;
use Switch;
while ( $ARGV[0]  )
{
	my $parm = $ARGV[0];
	my $umparm = "d$parm";
	$umparm =~ s/^d-/d/; 
	$umparm =~ s/^d-/d/; 
	$umparm =~ s/^d//; 
	if ( "$parm" eq "$umparm" )
	{
		last;
	}
	if ( ! $umparm )
	{
		last;
	}
	switch ( $umparm ) 
	{
		case ['a','ask']
		{
			checkoname( $umparm, $optnamea );
			checkoptarg( $parm, $ARGV[1] );
			$oask = $ARGV[1];
			shift;
		}
		case ['b','batch']
		{
			checkoname( $umparm, $optnameb );
			$obatch = 'y';
		}
		case 'clean'
		{
			checkoname( $umparm, $optnameclean );
			$oclean = 'y';
		}
		case ['c','change']
		{
			checkoname( $umparm, $optnamec );
			$ochange = 'y';
		}
		case 'hh'
		{
			checkoname( $umparm, $optnamehh );
			$ohelp = 'y';
			$overbose = 1;
		}
		case 'h'
		{
			checkoname( $umparm, $optnameh );
			$ohelp = 'y';
		}
		case 'ionly'
		{
			checkoname( $umparm, $optnameionly ); 
			$oionly = 'y';
		}
		case ['int','interactive']
		{
			checkoname( $umparm, $optnameint );
			$oint = 'y';
		}
		case ['i','inventory']
		{
			checkoname( $umparm, $optnamei );
			$oinventory = 'y';
		}
		case 'local'
		{
			checkoname( $umparm, $optnamelocal );
			$olocal = 'y';
		}
		case ['l','log']
		{
			checkoname( $umparm, $optnamel );
			checkoptarg( $parm, $ARGV[1] );
			$olog = $ARGV[1];
			shift;
		}
		case ['n','nodes']
		{
			checkoname( $umparm, $optnamen );
                        checkoptarg( $parm, $ARGV[1] );
			checkonodes( $ARGV[1] );
                        $onodes = $ARGV[1];
                        shift;
		}
		case ['on','onerror']
		{
			checkoname( $umparm, $optnameon );
			checkoptarg( $parm, $ARGV[1] );
			$oonerror = $ARGV[1];
			shift;
		}
		case 'oh'
		{
			checkoname( $umparm, $optnameoh );
			checkoptarg( $parm, $ARGV[1] );
			$ooh = $ARGV[1];
			shift;
		}
		case 'och'
		{
			checkoname( $umparm, $optnameoch );
                        checkoptarg( $parm, $ARGV[1] );
			$ooch = $ARGV[1];
			shift;
		}
		case ['patchd','patchdir']
		{
			checkoname( $umparm, $optnamepatchd );
                        checkoptarg( $parm, $ARGV[1] );
			$opatchdir = $ARGV[1];
			shift;
		}
		case ['patchf','patchfile']
		{
			checkoname( $umparm, $optnamepatchf );
                        checkoptarg( $parm, $ARGV[1] );
			$opatchfile = $ARGV[1];
			shift;
		}
		case ['patchn','patchnum']
		{
			checkoname( $umparm, $optnamepatchn );
                        checkoptarg( $parm, $ARGV[1] );
			$opatchn = $ARGV[1];
			shift;
		}
		case 'rollback'
		{
			checkoname( $umparm, $optnamerollback );
			$orollback = 'y';
		}
		case ['r','random']
		{
			checkoname( $umparm, $optnamer );
			$orandom = 'y';
		}
		case ['s','simulate']
		{
			checkoname( $umparm, $optnames );
			$osimulate = "$echo simulate";
		}
		case 'vf'
		{
			checkoname( $umparm, $optnamevf );
                        checkoptarg( $parm, $ARGV[1] );
			$ovfile = $ARGV[1];
			report( 0, 0, "Warning: Not support -vf $ovfile" );
			shift;
		}
		case ['v','verbose']
		{
			checkoname( $umparm, $optnamev );
                        checkoptarg( $parm, $ARGV[1] );
			$overbose = $ARGV[1];
			$overbose_o = $parm;
			shift;
		}
		case 'V'
		{
			checkoname( $umparm, $optnameVV );
			$oversion = 'y';
		}
		case 'w'
		{
			checkoname( $umparm, $optnamew );
			checkoptarg( $parm, $ARGV[1] );
			$owarmup = $ARGV[1];
			shift;
		}
		case 'x'
		{
			checkoname( $umparm, $optnamex );
			$ox = 'y';
		}
		else
		{
			usage( "Unknown option $parm" );
		}
	}
	shift;
}

#Handle 11.2 case

if ( -f $OLRLOC)
{
  open (OLRCFGFILE, "<$OLRLOC") or die "Can't open $OLRLOC";
    while (<OLRCFGFILE>) {
        if (/^crs_home=(\S+)/) {
            $crshome = $1;
            last;
        }
    }
  close (OLRCFGFILE);
  my $parampath = "$crshome/crs/install/crsconfig_params";
  my $scriptpath = dirname($0);
  print ("Executing $perlbin $scriptpath/patch112.pl @initargs -paramfile $parampath");
  system("$perlbin $scriptpath/patch112.pl @initargs -paramfile $parampath");
  exit 1;
}

if (($ooch) && (-f "$ooch/bin/oracle"))
{
  my $parampath = "$ooch/crs/install/crsconfig_params";
  my $scriptpath = dirname($0);
  print ("Executing $perlbin $scriptpath/patch112.pl @initargs -paramfile $parampath");
  system("$perlbin $scriptpath/patch112.pl @initargs -paramfile $parampath");
  exit 1;
}
  
   
if ( $orollback )
{
	$tprint_rollback = 2;
	if ( ! $opatchn )
	{
		usage( "-patchnum is mandatory when -rollback is specified" );
	}
}
if ( $obatch )
{
	if ( $oint )
	{
		usage( "Can't specify -int and -batch together" );
	}
	if ( $oask )
	{
		usage( "Can't specify -ask and -batch together" );
	}
	if ( $oonerror )
	{
		usage( "Can't specify -onerror and -batch together" );
	}
	$oask = 'none';
	$oonerror = 'continue';
}
if ( $oint )
{
	if ( $oask )
	{
		usage( "Can't specify -ask and -int together" );
	}
	if ( $oonerror )
	{
		usage( "Can't specify -onerror and -int together" );
	}
	$oask = 'all';
	$oonerror = 'ask';
}
if ( ! $oonerror )
{
	$oonerror = 'ask';
}
if ( ! $oask )
{
	$oask = 'node';
}
if ( @ARGV != 0 && "$ox" ne "y" )
{
	$parms = join " ", @ARGV;
	usage( "This script does not require any parameters, you specified $parms." );
}
if ( "$oonerror" ne "ask" && "$oonerror" ne "abort" && "$oonerror" ne "continue" )
{
	usage( "Invalid -onerror value: $oonerror" );
}
if ( $ovfile && ( ! -f $ovfile || ! -r $ovfile ) )
{
	usage( "-vfile file not found: $ovfile or wrong permission." );
}

if ( ! $owarmup )
{
	$owarmup = $warmup_default;
}
$ret = dosleep( '-v', $owarmup );
if ( $ret )
{
	usage( "Invalid -w value $owarmup" );
}

# show version if requested
if ( "$oversion" eq "y" )
{
	print "$ppath version $version \n";
	exit 0
}
# verify verbose level
if ( ! $overbose )
{
	$overbose = 0;
}
$overbose_n =~ s/[0-9]//g;
if ( $overbose_n )
{
	usage( "option value for $overbose_o must be non-negative integer, not $overbose" );
}
# show help if requested
if ( "$ohelp" eq "y" )
{
	usage();
}
# verify root
if ( $whoami ne "root" && "$ox" ne "y" )
{
	usage( "This script must be executed by root" );
}

if ((! $opatchdir) || (! $opatchn))
{
 usage("-patchdir and -patchn are Mandatory options");
}

# process -x option
if( "$ox" eq "y" )
{
	if ( ! $ooh || ! $ooch || ! $opatchdir )
	{
		usage( "Internal error: no -oh or -och or -patchdir with -x" )
	}
	$ORACLE_HOME = $ooh;
	$RDBMS_HOME = $ooh;
	$ORA_CRS_HOME = $ooch;
	$CRS_HOME = $ooch;
	if ( "$ARGV[0]" ne "$mkdir" )
	{
		if ( -d $opatchdir )
		{
			chdir $opatchdir;
		}
		if ( $? != 0 )
		{
			usage( "Failed to cd $opatchdir" );
		}
	}
	report( $tprint_x, 0, "runing $pall" );
	report( $tprint_x, 0, "ORA_CRS_HOME=$ORA_CRS_HOME" );
	report( $tprint_x, 0, "ORACLE_HOME=$ORACLE_HOME" );
	$parms = join " ", @ARGV;
	report( $tprint_x, 0, "executing $parms" );
	system( "$osimulate $parms" );
	$ret = $?;
	report( $tprint_x, 0, "exit code $ret after executing $parms" );
	exit $ret;
}

if ( $opatchfile && ! $opatchn )
{
	usage( "Must specify -patchn with -patchfile" );
}
if ( $opatchfile && ! $opatchdir )
{
	usage( "Must specify -patchdir with -patchfile" );
}
if ( ! $opatchfile && $olocal )
{
	usage( "Can't specify -local without -patchfile" );
}
if ( ! $opatchfile && $oclean )
{
	usage( "Can't specify -clean without -patchfile" );
}
if ($ooch && $ooh)
{
        usage( "Can't specify -oh  with -och" );
}

# set up log and temporary files
if ( $olog )
{
	$log = $olog;
}
if ( ! $log )
{
	$log = $dlname;
}
# absolute path name
$p1 = substr( $log, 0 , 1 );
if ( "$p1" ne "/" )
{
	$log = "$pwd/$log";
}
print "$pname: log file is $log";
($filename, $dirs, $suffix) = fileparse( $log, qr/\.[^.]*/ );
$logdir = $dirs;
if ( ! ( -x $logdir && -w $logdir ) )
{
	$log = "";
	usage( "Cannot write log file directory $logdir, exiting" );
}
#$tsllog = "$dirs$filename.atm.log";
#unlink ( $tsllog );
$tmpf = "$dirs$filename.1.tmp";
open( FP, ">$tmpf" ) or die "Cann't create $tmpf\n";
close ( FP );
$tmpfo = "$dirs$filename.2.tmp";
open( FP, ">$tmpfo" ) or die "Cann't create $tmpfo\n";
close ( FP );
#$tmpfiles = "$tmpf $tmpfo";


# START real work 
$SIG{'INT'} = 'goaway_int';
$SIG{'QUIT'} = 'goaway_quit';
$SIG{'HUP'} = 'goaway_hup';
$SIG{'TERM'} = 'goaway_term';
$SIG{'EXIT'} = 'goaway_exit';

if ( "$oask" eq "none" )
{
	$iostep = "n";
	$iopd = "n";
	$ioop = "n";
	$iolsi = "n";
	$ionode = "n";
	
}
if ( $oask && "$oask" ne "all" && "$oask" ne "none" )
{
	$iostep = "n";
	$iopd = "n";
	$ioop = "n";
	$iolsi = "n";
	$ionode = "n";
	$gv = ",$oask,";
	if ( $gv =~ s/,step,/,/ )
	{
		$iostep = "y";
	}	
	if ( $gv =~ s/,pd,/,/ )
	{
		$iopd = "y";
	}	
	if ( $gv =~ s/,lsi,/,/ )
	{
		$iolsi = "y";
	}	
	if ( $gv =~ s/,node,/,/ )
	{
		$ionode = "y";
	}	
	if ( $gv =~ s/,op,/,/ )
	{
		$ioop = "y";
	}	
	if ( "$gv" ne "," )
	{
		usage( "Invalid value for -a: $oask" );
	}
}
if ( "$ioop" eq "y" )
{
	$opsilent = "";
}
else
{
	$opsilent = "-silent";
}

report( '-n', $tprint_options, 0, "invoked in $host:$g_startdir with $invoked" );
report( '-n', $tprint_options, 0, "script full path is $pfull" );

# later better simulate mode: list of suboptions
if ( "$iostep" eq "y" )
{
	$costep = "";
}
else
{
	$costep = " NOT";
}
if ( "$ioop" eq "y" )
{
	$coop = "";
}
else
{
	$coop = " NOT";
}
if ( "$iopd" eq "y" )
{
	$copd = "";
}
else
{
	$copd = " NOT";
}
if ( "$iolsi" eq "y" )
{
	$colsi = "";
}
else
{
	$colsi = " NOT";
}
if ( "$ionode" eq "y" )
{
	$conode = "";
}
else
{
	$conode = " NOT";
}
if(  $oinventory || $oionly )
{
	report( 0, 0, "$colsi asking before running opatch lsinventory");
}

# check if patch file exists
if ( $patchfile && ( ! -f $patchfile || ! -r $patchfile ) )
{
	usage( "Patch file $patchfile not found or wrong permission." );
}

# process -vf
if ( $ovfile )
{
	report( 0, 0, "Warning: Not support -vf $ovfile" );
}

# set up the environment
ask( '-ns', 'step', "Proceed to discover environment to patch" );
report( '-n', 0, 0, "Discovering environment to patch" );
if ( ! -f $initcssd )
{
 $crsnotconfigured = "true";
 $ORA_CRS_HOME=$ooh;
 print "In not configure $ORA_CRS_HOME\n";
 $initcssd = "$ORA_CRS_HOME/css/admin/init.cssd";
 my @parms = ();
 local *CSSD;
 open( CSSD, "<$initcssd" ) or die "Cann't open $initcssd";
 while ( <CSSD> )
 {
   if ( $_ =~ m/^ORACLE_USER/ )
   {
    @parms = split( /=/, $_ );
    $ORA_CRS_USER = $parms[1];
    chomp $ORA_CRS_USER;
   }
   if ( $ORA_CRS_HOME && $ORA_CRS_USER )
   {
    print "CRS not configured\n";
    last;
   }
 }
 @ocp_nodes_topatch = $host;
 $ocp_nodes_tplist = join " ", @ocp_nodes_topatch;
}
else
{
 getoch();
 getoh();
}


$CRS_HOME = $ORA_CRS_HOME;
$opatch = "$CRS_HOME/OPatch/opatch";

if ( ! -x $opatch )
{
	usage( "file $opatch not found" );
}

#check if we have the right version of opatch
$cmd = "$opatch version -oh $CRS_HOME";
run( 0, 0, 0, $ORA_CRS_USER, 'y', $cmd );

@opatch_ver_info = `$su $ORA_CRS_USER -c \"$opatch version -oh $CRS_HOME\"`;
foreach $line (@opatch_ver_info)
{
 if ($line =~ m/Version/) {
   @verinfo = split(':',$line,2);
   $opatch_ver  = trim($verinfo[1]);
   print "opatch version is $opatch_ver\n";
   last;
 }
}

@verinfo = split(/\./, $opatch_ver);

if (trim($verinfo[0])> 10) 
{
 report( '-n', 0, 0, "$opatch $opatch_ver is Valid Opatch Version" );
}
elsif ((trim($verinfo[0]) == 10) && (trim($verinfo[1]) >= 2) && (trim($verinfo[2]) >= 0) && (trim($verinfo[3]) >= 4) && (trim($verinfo[4]) >= 7))
{
 report( '-n', 0, 0, "$opatch $opatch_ver is Valid Opatch Version" );
}
elsif ((trim($verinfo[0]) == 10) && (trim($verinfo[1]) >= 2) && (trim($verinfo[2]) >= 0) && (trim($verinfo[3]) >=4) && (trim($verinfo[4]) >= 7))
{
 report( '-n', 0, 0, "$opatch $opatch_ver is Valid Opatch Version" );
}
else
{
 report( '-n', 0, 0, "$opatch $opatch_ver is Invalid. Must be version 10.2.0.4.7 or above" );
 exit 0;
}
                  

#check if opatch is bundled with OCM
if ( -e "$CRS_HOME/OPatch/ocm/bin/emocmrsp")
{
 report( 0, 0, "$opatch is bundled with OCM, Enter the absolute OCM response file path:" );
 $ocmrspfile = <STDIN>;
 chomp $ocmrspfile;
 if ( -e $ocmrspfile)
 {
  $op_silent = "-silent -ocmrf $ocmrspfile";
 }
 else
 {
  report( 0, 0, "Invalid response file path, To regenerate an OCM response file run $CRS_HOME/OPatch/ocm/bin/emocrmrsp");
  exit 0;
 }
}
else
{
 #report( 0, 0, "$opatch is not bundled with OCM" );
 $op_silent = "-silent";
}



report( 0, 0, "Oracle CRS user is $ORA_CRS_USER" );
report( 0, 0, "Cluster nodes are $ocp_nodelist" );
report( 0, 0, "Node to patch is $ocp_nodes_tplist" );
report( 0, 0, "Using $opatch for opatch" );


# later verify node equivalence, add 'trust' option
# later determine local vs shared homes, for now assuming local

# cd to patch directory if necessary
$patchfile = $opatchfile;
$patchdir = $opatchdir;

if ( ! $opatchdir )
{
	$patchdir = $pwd;
	report( '-n', $tprint_rollback, 0, "using current directory $patchdir for patch directory" );
}
# absolute path names
$p1 = substr( $patchdir, 0 , 1 );
if ( "$p1" ne "/" )
{
        $p1 = $pwd;
        $patchdir = "$p1/$patchdir";
}
if( $patchfile )
{
	$p1 = substr( $patchfile, 0 , 1 );
	if ( "$p1" ne "/" )
	{
        	$p1 = $pwd;
        	$patchfile = "$p1/$patchfile";
	}
}
if ( "$olocal" eq "y" )
{
	$en = " on each nodes";
}
else
{
	$en = "";
}
# create patch directory 
if( ( $patchdir && ! -d $patchdir ) || "$olocal" eq "y" )
{
	ask( 'pd', "Create patch directory $patchdir$en" );
	if ( ! $ask_skip )
	{
		$cmd = "$mkdir -p $patchdir";
		if ( "$olocal" eq "y" )
		{
			foreach $node ( @ocp_nodes_topatch )
			{
				report( '-n', 0, 0, "Executing $cmd on $node as $ORA_CRS_USER" );
				remote( '-v', 'mkdir', $ORA_CRS_USER, $node, 'n', $cmd );
			}
		}
		else
		{
			report( '-n', 0, 0, "Executing $cmd as $ORA_CRS_USER" );
			run( '-v', 'mkdir', $ORA_CRS_USER, 'n', $cmd );
		}
	}
	else
	{
		report( '-n', 0, 0, "Creating patch directory is skipped at user request" );
	} 
}

if ( ! -d $patchdir )
{
	usage( "Patch directory $patchdir not found" );
}
# clean up patch directory
if ( "$oclean" eq "y" )
{
	ask( 'pd', "Clean up patch directory $patchdir$en" );
	if ( ! $ask_skip )
	{
		$cmd = "rm -r $patchdir/\* $patchdir/.\[!.\]\*";
		if ( "$olocal" eq "y" )
		{
			foreach $node ( @ocp_nodes_topatch )
			{
				report( '-n', 0, 0, "Executing $cmd on $node as $ORA_CRS_USER" );
                                remote( '-v', 'rmr', $ORA_CRS_USER, $node, 'n', $cmd );
			}
		}
		else
		{
			report( '-n', 0, 0, "Executing $cmd on $host as $ORA_CRS_USER" );
                        run( '-v', 'rmr', $ORA_CRS_USER, 'n', $cmd );
		}
	}
	else
	{
		report( '-n', 0, 0, "Cleaning up patch directory is skipped at user request" );
	}
}

my $rpatchfile = "";
$unzip = -f $unzip?$unzip:"$ORA_CRS_HOME/bin/unzip";
# unzip patch
if ( $patchfile )
{
	ask( 'pd', "unzip $patchfile into $patchdir$en" );
	if (  $ask_skip )
	{
		report( '-n', 0, 0, "unzipping patch file is skipped at user request" );
	}
	else
	{
		if ( "$olocal" eq "y" )
		{
			foreach $node ( @ocp_nodes_topatch )
			{
				if ( "$node" ne "$host" )
				{
					$cmd = "$rcp $patchfile $node:$patchdir";
					report( '-n', 0, 0, "Executing $cmd as $ORA_CRS_USER" );
					run( '-v', 'rcp', $ORA_CRS_USER, 'n', $cmd );
				}
				$rpatchfile = basename( $patchfile );
				$rpatchfile = "$patchdir/$rpatchfile";
				$cmd = "$unzip -o $rpatchfile -d $patchdir";
				ask( 'pd', "unzip $rpatchfile into $patchdir on $node" );
				report( '-n', 0, 0, "Will$ask_not $cmd on $node as $ORA_CRS_USER" );
				remote( '-v', 'unzip', $ORA_CRS_USER, $node, 'n', $cmd ); 
			}
		}
		else
		{
			$cmd = "$unzip -o $patchfile -d $patchdir";
			report( '-n', 0, 0, "Executing $cmd as $ORA_CRS_USER" );
			run( '-v', 'unzip', $ORA_CRS_USER, 'n', $cmd );
		}
	}
	report( '-n', 0, 0, "Adding patch number $opatchn to patch directory $patchdir" );
	$patchdir = "$patchdir/$opatchn";
	if ( ! -d $patchdir )
	{
		usage( "Patch directory $patchdir not found, likely error in -patchnum value $opatchn" );
	}
}

invent( "Before patching" );
$patchdir = "$patchdir/$opatchn";
chdir "$patchdir";
if ( $? )
{
	usage( "Failed to cd patch directory $patchdir" );
}

### FOR EACH NODE

#get user specified homes to patch.
if ((! $ooh) || ($ooch))
{
 $patchcrs = "true";
}

#Determine the type of patch
if ((-e "$patchdir") && (-e "$patchdir/custom/server/$opatchn"))
{
 $crsbptype = "true";
}

if ($crsbptype)
{
 ($patchcount, $rdbmsids) = getPatchids("$patchdir/custom/server");
 if ($patchcount > 1) {$napplydb = "true";}
}
else
{
 ($patchcount, $rdbmsids) = getPatchids("$patchdir");
 if ($patchcount > 1) {$napplypatch = "true";}
}

#patch validation logic for non n-apply patches
if ( ! $napplypatch)
{
#Determine if the patch is rolling or not.
$cmd = "$opatch query -is_rolling_patch $patchdir -oh $CRS_HOME";
run( 0, 0, 0, $ORA_CRS_USER, 'y', $cmd );

@patch_crs_info = `$su $ORA_CRS_USER -c \"$opatch query -is_rolling_patch $patchdir -oh $CRS_HOME\"`;
foreach $line (@patch_crs_info)
{
 if (($line =~ m/rolling/) && ($line =~ m/true/)) {
  $isrolling = "true";
 }
}

#validate if patch is applicable for each of the homes.
$cmd = "$opatch query -get_component $patchdir -oh $CRS_HOME";
run( 0, 0, 0, $ORA_CRS_USER, 'y', $cmd );

@patch_crs_info = `$su $ORA_CRS_USER -c \"$opatch query -get_component $patchdir -oh $CRS_HOME\"`;
foreach $line (@patch_crs_info)
{
 if ($line =~ m/oracle\./) {
   ($patch_comp, $patch_ver) = split(':',$line,2);
   $patch_comp = trim($patch_comp);
   $patch_ver  = trim($patch_ver);
   if ((! $crsbptype) && ($patch_comp =~ m/oracle\.crs/))
   {
    $iscrsonlypatch = "true";
   }
   elsif ((! $crsbptype) && ($patch_comp =~ m/oracle\.rdbms/))
   {
    $isrdbmsonlypatch = "true";
   }
}
}

if ($crsbptype)
{
$cmd = "$opatch query -get_component $patchdir/custom/server/$opatchn -oh $CRS_HOME";
run( 0, 0, 0, $ORA_CRS_USER, 'y', $cmd );
@patch_oh_info = `$su $ORA_CRS_USER -c \"$opatch query -get_component $patchdir/custom/server/$opatchn -oh $CRS_HOME\"`;
}
else
{
$cmd = "$opatch query -get_component $patchdir -oh $CRS_HOME";
run( 0, 0, 0, $ORA_CRS_USER, 'y', $cmd );
@patch_oh_info = `$su $ORA_CRS_USER -c \"$opatch query -get_component $patchdir -oh $CRS_HOME\"`;
}

foreach $line (@patch_oh_info)
{
 if ($line =~ m/oracle\./) {
   ($patch_db_comp, $patch_db_ver) = split(':',$line,2);
   $patch_db_comp = trim($patch_db_comp);
   $patch_db_ver  = trim($patch_db_ver);
}
}

if (((! $ooh) || ($ooh && $patchcrs)) && (! $isrdbmsonlypatch))
{

 #validate CRS home
 @crs_lsinfo = `$su $ORA_CRS_USER -c \"$opatch lsinventory -match $patch_comp -oh $CRS_HOME\"`;
 foreach $line (@crs_lsinfo)
 {
  if (($line =~ m/$patch_comp/) && ($line =~ m/$patch_ver/)) {
   print "The patch is applicable for this CRS Home $CRS_HOME\n";
  }
 }

  #Check for patch conflict  in this CRS Home
  @crs_patchinfo = `$su $ORA_CRS_USER -c \"$opatch prereq CheckConflictAgainstOH -ph $patchdir -oh $CRS_HOME\"`;
  foreach $line (@crs_patchinfo)
  {
   if ($line =~ m/failed/) {
   $crspatchexist = "true";
   last;
   }
  }

  #Check if the patch is already applied in this CRS Home
  @crs_patchinfo = `$su $ORA_CRS_USER -c \"$opatch lsinventory -patch -oh $CRS_HOME\"`;
  foreach $line (@crs_patchinfo)
  {
   if (($line =~ m/$opatchn/) && ($line =~ m/applied/)) {
   $crspatchapplied = "true";
   last;
   }
  }
 
  if (($crspatchexist) && ($crspatchapplied) && (! $orollback))
  {
   report('-n', 0, 0, "The patch $opatchn is already applied in this CRS Home $CRS_HOME\n");
   $patchcrs = ""; 
  }
  elsif (($crspatchexist) && (! $crspatchapplied) && (! $orollback))
  {
   report('-n', 0, 0, "The patch $opatchn is conflicting with another patch in this CRS Home $CRS_HOME\n");
   $patchcrs = "";
  }

  if ((! $crspatchapplied) && ($orollback))
  {
   report('-n', 0, 0, "The patch $opatchn is not applied in  this CRS Home $CRS_HOME and cannot be rolled back\n");
   $patchcrs = "";
  }
}

#validate Oracle Homes associated with this CRS home.
foreach $ohline (@tmp_ohlist)
{
 my $ohver = "";
 @oh_lsinfo = `$su $ohowner{$ohline} -c \"$opatch lsinventory -oh $ohline\"`;
 #@oh_lsinfo = `$su $ORA_CRS_USER -c \"$opatch lsinventory -oh $ohline\"`;
 foreach $line (@oh_lsinfo)
 {
  my @tmpl = ();
  $line = trim($line);
  if ($line =~ m/Database/)
  {
   @tmpl = split(/ /, $line);
   $ohver =trim($tmpl[-1]);
  }
 }
 report('-n', 0, 0, "Oracle version for Oracle Home $ohline is $ohver");
 @oh_lsinfo = `$su $ohowner{$ohline} -c \"$opatch lsinventory -match $patch_db_comp -oh $ohline\"`;
 foreach $line (@oh_lsinfo)
 {
  $line = trim($line);
  if (($line =~ m/$patch_db_comp\ /) && ($line =~ m/$patch_db_ver/) && ($line =~ m/$ohver/)) {
   print "The patch is applicable for this Oracle Home $ohline\n";
   push @ocp_patch_ohs, $ohline;
   last;
  }
 }
}

$#tmp_ohlist = -1;

#Check if the patch is already applied in the Oracle Homes.
 foreach $ohline (@ocp_patch_ohs)
 {
  $ohpatchexist = "";
  $ohpatchapplied = "";
  @oh_patchinfo = `$su $ohowner{$ohline} -c \"$opatch prereq CheckConflictAgainstOH -ph $patchdir -oh $ohline\"`;
  foreach $line (@oh_patchinfo)
  {
   if ($line =~ m/failed/) {
   $ohpatchexist = "true";
   last;
   }
  }

  @oh_patchinfo = `$su $ohowner{$ohline} -c \"$opatch lsinventory -patch -oh $ohline\"`;
  foreach $line (@oh_patchinfo)
  {
   if (($line =~ m/$opatchn/) && ($line =~ m/applied/)) {
   $ohpatchapplied = "true";
   last;
   }
  } 

  if (($ohpatchexist) && ($ohpatchapplied ) && (! $orollback))
  {
   report('-n', 0, 0,"The patch $opatchn is already applied in this Oracle Home $ohline\n");
  }
  elsif (($ohpatchexist) && (! $ohpatchapplied ) && (! $orollback))
  {
   report('-n', 0, 0,"The patch $opatchn conflicts with another patch in Oracle Home $ohline");
   report('-n', 0, 0,"Execute opatch prereq CheckConflictAgainstOH -ph $patchdir -oh $ohline for more info");
  }  
  elsif ((! $ohpatchapplied) && ($orollback))
  {
  report('-n', 0, 0, "The patch $opatchn is not applied in  this Oracle Home $ohline and cannot be rolled back\n");
  }
  else
  {
   push @tmp_ohlist,$ohline;
  }
  ++$ohcount;
 }
}
else {
#n-apply support
my @patches = split(/\,/, $rdbmsids);
my $patchyes = "";
 foreach $ohline (@tmp_ohlist)
 { 
  foreach my $line (@patches)
  {
   my @patch_out = `$su $ORA_CRS_USER -c \"$opatch prereq checkApplicable -ph $patchdir/$line -oh $ohline\"`;
   foreach my $line1 (@patch_out)
   {
    if (($line1 =~ m/$line/) && ($line1 =~ m/passed/i))
    {
     $patchyes = "true";
     last;
    }
   }
  }
  if ($patchyes)  
  {
   print "The patch is applicable for this Oracle Home $ohline\n";
   push @ocp_patch_ohs, $ohline;
  }
 }
 $patchcrs = "";
}

@ocp_patch_ohs = @tmp_ohlist;
$ocp_patch_ohs_size = $#ocp_patch_ohs + 1;

if (($patchcrs) && ($asm_home) && (! $isrdbmsonlypatch))
{
 $asmstop ="true";
}

foreach $line (@ocp_patch_ohs)
{
 if ($line eq $asm_home)
 {
  $asmstop = "true";
 }
}


if ((! $patchcrs || $isrdbmsonlypatch) && ($ocp_patch_ohs_size == 0))
{
 report('-n', 0, 0, "No applicable patch actions for the homes. Exiting");
 exit 0;
}
 
# check sharedness
open(TEXT,">$CRS_HOME/a.txt");
printf TEXT "shared\n";
close (TEXT);
$cmd = "$cat $CRS_HOME/a.txt";
foreach $node ( @ocp_nodes)
{
  if ($node ne "$ocp_nodes_topatch[0]")
  {
  # report( '-n', 0, 0, "Executing $cmd on $node as $ORA_CRS_USER" );
   remote( '-v', 'cat', $ORA_CRS_USER, $node, 'n', $cmd );
  }
}
unlink("$CRS_HOME/a.txt");

#perform check specific for shared home
if ($sharedhome eq "true")
{
 report( '-n', 0, 0, "Detected Shared CRS Home");
 $cmd = "$crsctl check crs";
 foreach $node ( @ocp_nodes)
 {
  if ($node ne "$ocp_nodes_topatch[0]")
  {
   report( '-n', 0, 0, "Executing $cmd on $node as $ORA_CRS_USER" );
   remote( '-v', 'crsctl_check_crs', $ORA_CRS_USER, $node, 'n', $cmd );
   if ($stackrun eq "true")
   {
    report( '-n', 0, 0, "CRS stack is running on node $node" );
    ++$stackruncount;
   }
  }
 }
 if ($stackruncount > 0)
 {
 report( '-n', 0, 0, "Shutdown the CRS  on the above nodes with 'crsctl stop crs' and re-run patch tool");
 exit 0
 }
}

#check if it's vendor clusterware or not
$isVendorCluster = checkVendor();

foreach $node ( @ocp_nodes_topatch )
{
	if ( $after_patch_node )
	{
           print "My node is $node";
	}

	$after_patch_node = '';	
	if ( "$ochange" eq "y" )
	{
		report( '-n', 0, 0, "Nodes to patch: $ocp_nodes_tplist" );
		report( 0, 0, "Nodes patched : $patched_nodes" );
		report( '-n', 0, 0, "Next node to patch is $node, <Enter> to confirm or type node name to patch:" );
		report( 0, 0, "If you do enter nodename it must be in the cluster but no validation is done" );
		report( 0, 0, "" );
		$innode = <STDIN>;
		chomp $innode;
		report( $tprint_askan, 0, "User answers $innode" );
		if ( $innode )
		{
			report( '-n', 0, 0, "Next node to patch is set to $innode at user request" );
			$node = $innode;
		}
	}
	if ( $orollback )
	{
		$q2ask = "Rollback patch $opatchn on node $node";
	}
	else
	{
		$q2ask = "Patch node $node";
	}
	ask( 'node', $q2ask );
	if ( $ask_skip )
	{
		report( '-n', 0, 0, "Processing node $node is skipped at user request" );
		next;
	}

        if($orollback)
        {
         report( '-n', 0, 0, "rolling back patch $opatchn on node $node" );
        }
        else
        {
	 report( '-n', 0, 0, "Applying patch $opatchn on node $node" );
        }
	
        if (($crsnotconfigured) || ($stackrun eq "false"))
        {
         if ($patchcrs && (! $isrdbmsonlypatch))
         {
          $ORACLE_HOME = $ORA_CRS_HOME;
          $RDBMS_HOME = $ORA_CRS_HOME; 
          # patch crs home
          $cmd = "$patchdir/custom/scripts/prerootpatch.sh -crshome $CRS_HOME -crsuser $ORA_CRS_USER";
          ask( 'step', "execute prerootpatch.sh on $node" );
          report( '-n', 0, 0, "$ask_not Executing $cmd as root on $node" );
          run( '-v', 'prerootpatch_crs', $ask_skip, 'root', 'y', $cmd );

          # invoke prepatch  for crs home
          $cmd = "$patchdir/custom/scripts/prepatch.sh -crshome $CRS_HOME";
          ask( 'step', "execute prepatch.sh for CRS_HOME on $node" );
          report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
          run( '-v', 'prepatch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );

          if (  $orollback )
          {
                $cmd = "$opatch rollback -id $opatchn -local $opsilent -oh $CRS_HOME";
                ask( 'step', "rollback patch $opatchn for CRS_HOME on $node" );
                report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
                run( '-v', 'rollback_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
          }
          else
          {
                $cmd = "$opatch napply -local $op_silent -oh $CRS_HOME -id $opatchn";
                ask( 'step', "apply patch for CRS_HOME on $node" );
                report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
                run( '-v', 'patch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
          }
          
          # invoke postpatch  for crs home
          $cmd = "$patchdir/custom/scripts/postpatch.sh -crshome $CRS_HOME";
          ask( 'step', "Invoke postpatch.sh for $CRS_HOME on $node" );
          report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
          run( '-v', 'postpatch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );

         # invoke postrootpatch
          $cmd = "$patchdir/custom/scripts/postrootpatch.sh -crshome $CRS_HOME";
          ask( 'step', "Invoke postrootpatch.sh for $CRS_HOME on $node" );
          report( '-n', 0, 0, "$ask_not Executing $cmd as root on $node" );
          run( '-v', 'postrootpatch_crs', $ask_skip, 'root', 'y', $cmd );          
         }
        }
        else
        {	
        # stop instances
                if ($patchcrs && (! $isrdbmsonlypatch))
                {
		 foreach $db ( @ocp_databases )
		 {    
                        $oh = $dboh{$db}; 
                        $srvctl_oh = "$oh/bin/srvctl";
                        $ENV{ORACLE_HOME} = $oh;
			$cmd = "$srvctl config -p $db -n $node";
			run( '-v', 'srvctl_config_p', 'root', 'n', $cmd );
			$ret = `$srvctl config -p $db -n $node`;
			@tmps = split( /\s+/, $ret );
			$inst = $tmps[1];
			if ( $inst )
			{      
				$cmd = "$srvctl_oh stop instance -d $db -i $inst";
				ask( 'step', "Stop instances for db $db on $node" );
				report( '-n', 0, 0, "$ask_not stopping instance on $node with $cmd" );
				run( '-v', 'srvctl_stop_inst', $ask_skip, $ohowner{$oh}, 'n', $cmd );	
			}
		 }
                }
                else
                {
                 foreach $oh ( @ocp_patch_ohs )
                 {     
                       $srvctl_oh = "$oh/bin/srvctl";
                       $ENV{ORACLE_HOME} = $oh;
                       @dbsinoh = split(/:/,$ohdb{$oh});
                       foreach $db (@dbsinoh)
                       {
                        if (! $isrolling)
                        { 
                         $cmd = "$srvctl_oh stop database -d $db";
                         report( '-n', 0, 0, "$ask_not stopping database $db  with $cmd" );
                         run( '-v', 'srvctl_stop_db', $ask_skip, $ohowner{$oh}, 'n', $cmd );
                        }
                        else
                        {
                         $cmd = "$srvctl_oh config -p $db -n $node";
                         run( '-v', 'srvctl_config_p', $ohowner{$oh}, 'n', $cmd );
                         $ret = `$srvctl config -p $db -n $node`;
                         @tmps = split( /\s+/, $ret );
                         $inst = $tmps[1];
                         if ( $inst )
                         {
                                $cmd = "$srvctl_oh stop instance -d $db -i $inst";
                                ask( 'step', "Stop instances for db $db on $node" );
                                report( '-n', 0, 0, "$ask_not stopping instance on $node with $cmd" );
                                run( '-v', 'srvctl_stop_inst', $ask_skip, $ohowner{$oh}, 'n', $cmd );
                         }
                        }
                       }
                 }
                }
              
        if ($crsnotconfigured)
        {
         if ($patchcrs && (! $isrdbmsonlypatch))
        {
         $ORACLE_HOME = $ORA_CRS_HOME;
         $RDBMS_HOME = $ORA_CRS_HOME;

         # patch crs home
         if (  $orollback )
         {
                $cmd = "$opatch rollback -id $opatchn -local $opsilent -oh $CRS_HOME";
                ask( 'step', "rollback patch $opatchn for CRS_HOME on $node" );
                report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
                run( '-v', 'rollback_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
         }
         else
         {
                #$cmd = "$opatch apply -local $op_silent -oh $CRS_HOME";
                $cmd = "$opatch napply -local $op_silent -oh $CRS_HOME -id $opatchn";
                ask( 'step', "apply patch for CRS_HOME on $node" );
                report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
                run( '-v', 'patch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
         }
        }
        exit 0;
        }
      
		# stop ASM
                if (($asmstop) && ($asm_home))
                {
		 $cmd = "$srvctl stop asm -n $node";
		 ask( 'step', "Stop ASM on $node" );
		 report( '-n', 0, 0, "$ask_not stopping ASM on $node with $cmd" );
		 run( '-v', 'srvctl_stop_asm', $ask_skip, 'root', 'n', $cmd );
                }
		# stop listeners
		$cmd = "$srvctl stop listener -n $node";
		ask( 'step', "Stop listener on $node" );
		report( '-n', 0, 0, "$ask_not stopping listener on $node with $cmd" );
		run( '-v', 'srvctl_stop_listener', $ask_skip, $ORA_CRS_USER, 'n', $cmd );
                if ($patchcrs && (! $isrdbmsonlypatch))
                {
		 # stop nodeapps
		 $cmd = "$srvctl stop nodeapps -n $node";
		 ask( 'step', "Stop nodeapps on $node" );
		 report( '-n', 0, 0, "$ask_not stopping nodeapps on $node with $cmd" );
		 run( '-v', 'srvctl_stop_nodeapps', $ask_skip, $ORA_CRS_USER, 'n', $cmd );
                }

        if ($patchcrs && (! $isrdbmsonlypatch))
        {
	 if (( $os !~ m/Linux/ ) && (! $isVendorCluster))
	 {
		$cmd = "$ORA_CRS_HOME/bin/oprocd stop";
		ask( 'step', "Stop oprocd on $node" );
		report( '-n', 0, 0, "$ask_not stopping oprocd on $node with $cmd" );
		run( '-v', 'stop_oprocd', $ask_skip, 'root', 'y', $cmd );
	 }
	 # stop CRS
	 $cmd = "$crsctl stop crs";
	 ask( 'step', "Stop CRS on $node" );
	 report( '-n', 0, 0, "$ask_not shutting  down CRS stack on $node with $cmd" );
	 run( '-v', 'crsctl_stop_crs', $ask_skip, 'root', 'y', $cmd );
	 ask( 'step', "Sleep to allow CRS to stop completely, $sstopcrs seconds" );
	 if ( ! $ask_skip )
	 {
           #check if clusterware is up on the node
           my $sleepcount = 0;
           while (! $stopcrs)
           {
            dosleep( $sstopcrs );
            $stopcrs = checkCrsStack ();
            $sleepcount++;
            if ($sleepcount > 4) {
               report( '-n', 0, 0, "Failed to Stop CRS stack. Exiting");
               exit 1;
            }
           }
	 }

	 # invoke prerootpatch
	 $cmd = "$patchdir/custom/scripts/prerootpatch.sh -crshome $CRS_HOME -crsuser $ORA_CRS_USER";
	 ask( 'step', "execute prerootpatch.sh on $node" );
	 report( '-n', 0, 0, "$ask_not Executing $cmd as root on $node" );
	 run( '-v', 'prerootpatch_crs', $ask_skip, 'root', 'y', $cmd );
	
	 # invoke prepatch  for crs home 
         $cmd = "$patchdir/custom/scripts/prepatch.sh -crshome $CRS_HOME";
         ask( 'step', "execute prepatch.sh for CRS_HOME on $node" );
         report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );    
         run( '-v', 'prepatch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
        }
	# invoke prepatch  for oracle home(s)
        if($crsbptype)
        {
	 foreach $oh ( @ocp_patch_ohs )
	 {
		$ORACLE_HOME = $oh;
		$RDBMS_HOME = $oh;
		$ou = $ohowner{$oh};
		$cmd = "$patchdir/custom/server/*/custom/scripts/prepatch.sh -dbhome $oh";
		ask( 'step', "execute prepatch.sh for OH $oh on $node" );
		report( '-n', 0, 0, "$ask_not Executing $cmd as $ou on $node" );
		run( '-v', 'prepatch_oh', $ask_skip, $ou, 'y', $cmd );
	 }
        }
       
        if ($patchcrs && (! $isrdbmsonlypatch))
        {
	 $ORACLE_HOME = $ORA_CRS_HOME;
	 $RDBMS_HOME = $ORA_CRS_HOME;
	
	 # patch crs home
	 if (  $orollback )
	 {
		$cmd = "$opatch rollback -id $opatchn -local $opsilent -oh $CRS_HOME";
		ask( 'step', "rollback patch $opatchn for CRS_HOME on $node" );
		report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
		run( '-v', 'rollback_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
	 }
	 else
	 {
                $cmd = "$opatch napply -local $op_silent -oh $CRS_HOME -id $opatchn"; 
		ask( 'step', "apply patch for CRS_HOME on $node" );
		report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" ); 
		run( '-v', 'patch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
	 }
        }
	
	 # patch rdbms homes
         foreach $oh ( @ocp_patch_ohs )
         {
                $ORACLE_HOME = $oh;
                $RDBMS_HOME = $oh;
                $ou = $ohowner{$oh};
		if( $orollback )
		{
                        if (($crsbptype) || ($napplypatch))
                        {
			 $cmd = "$opatch nrollback -id $rdbmsids -local $opsilent -oh $oh";
                        }
                        else
                        {
                         $cmd = "$opatch rollback -id $opatchn -local $opsilent -oh $oh";
                        }
			ask( 'step', "rollback patch $opatchn for $oh on $node" );
	                report( '-n', 0, 0, "$ask_not Executing $cmd as $ou on $node" );
        	        run( '-v', 'rollback_oh', $ask_skip, $ou, 'y', $cmd ); 
		}
		else
		{       
                        if($crsbptype)
                        {
                         $cmd = "$opatch napply custom/server/ -local $op_silent -oh $oh -id $rdbmsids";
                        }
                        elsif ($napplypatch)
                        {
                         $cmd = "$opatch napply -skip_subset -skip_duplicate -local $op_silent -oh $oh";
                        }
                        else
                        {
                         $cmd = "$opatch apply -local $op_silent -oh $oh";
                        }
	                ask( 'step', "Patch OH $oh on $node" );
        	        report( '-n', 0, 0, "$ask_not Executing $cmd as $ou on $node" );
                	run( '-v', 'patch_oh', $ask_skip, $ou, 'y', $cmd );
		}
        }

        if ($patchcrs && (! $isrdbmsonlypatch))
        {
	 $ORACLE_HOME = $ORA_CRS_HOME;
         $RDBMS_HOME = $ORA_CRS_HOME;

	 # invoke postpatch  for crs home
	 $cmd = "$patchdir/custom/scripts/postpatch.sh -crshome $CRS_HOME";
	 ask( 'step', "Invoke postpatch.sh for $CRS_HOME on $node" );
	 report( '-n', 0, 0, "$ask_not Executing $cmd as $ORA_CRS_USER on $node" );
	 run( '-v', 'postpatch_crs', $ask_skip, $ORA_CRS_USER, 'y', $cmd );
        }
       
        
	# invoke postpatch  for oracle home(s)
        if ($crsbptype)
        {
         foreach $oh ( @ocp_patch_ohs )
         {
                $ORACLE_HOME = $oh;
                $RDBMS_HOME = $oh;
                $ou = $ohowner{$oh};
                $cmd = "$patchdir/custom/server/*/custom/scripts/postpatch.sh -dbhome $oh";
                ask( 'step', "Invoke postpatch.sh for OH $oh on $node" );
                report( '-n', 0, 0, "$ask_not Executing $cmd as $ou on $node" );
                run( '-v', 'postpatch_oh', $ask_skip, $ou, 'y', $cmd );
         }
        }
        if ($patchcrs && (! $isrdbmsonlypatch))
        {
         $ORACLE_HOME = $ORA_CRS_HOME;
         $RDBMS_HOME = $ORA_CRS_HOME;

	 # invoke postrootpatch
	 $cmd = "$patchdir/custom/scripts/postrootpatch.sh -crshome $CRS_HOME";
         ask( 'step', "Invoke postrootpatch.sh for $CRS_HOME on $node" );
         report( '-n', 0, 0, "$ask_not Executing $cmd as root on $node" );
         run( '-v', 'postrootpatch_crs', $ask_skip, 'root', 'y', $cmd );
	}
	$patched_nodes = "$patched_nodes $node";
	$after_patch_node = "$node";


        #restart asm  database and listener after ohome patching

        if ((! $patchcrs) || ($isrdbmsonlypatch)) 
        { 
          if (($asmstop) && ($asm_home))
          {
            $cmd = "$srvctl start asm -n $node";
            ask( 'step', "Start ASM on $node" );
            report( '-n', 0, 0, "$ask_not starting ASM on $node with $cmd" );
            run( '-v', 'srvctl_stop_asm', $ask_skip, 'root', 'n', $cmd );
          } 
          foreach $oh ( @ocp_patch_ohs )
          {          
                       $srvctl_oh = "$oh/bin/srvctl"; 
                       $ENV{ORACLE_HOME} = $oh;
                       @dbsinoh = split(/:/,$ohdb{$oh});
                       foreach $db (@dbsinoh)
                       {                        
                        if (! $isrolling)
                        {
                         $cmd = "$srvctl_oh start database -d $db";
                         report( '-n', 0, 0, "$ask_not starting database $db  with $cmd" );
                         run( '-v', 'srvctl_start_db', $ask_skip, $ohowner{$oh}, 'n', $cmd );
                        }
                        else
                        {
                         $cmd = "$srvctl_oh config -p $db -n $node";
                         run( '-v', 'srvctl_config_p', $ohowner{$oh}, 'n', $cmd );
                         $ret = `$srvctl config -p $db -n $node`;
                         @tmps = split( /\s+/, $ret );
                         $inst = $tmps[1];
                         if ( $inst )
                         {
                                $cmd = "$srvctl_oh start instance -d $db -i $inst";
                                ask( 'step', "Start instances for db $db on $node" );
                                report( '-n', 0, 0, "$ask_not Starting instance on $node with $cmd" );
                                run( '-v', 'srvctl_start_inst', $ask_skip, $ohowner{$oh}, 'n', $cmd );
                         }
                        }
                       }
                        # start listener
                        $cmd = "$srvctl start listener -n $node";
                        ask( 'step', "Start listener on $node" );
                        report( '-n', 0, 0, "$ask_not Starting listener on $node with $cmd" );
                        run( '-v', 'srvctl_start_listener', $ask_skip, $ORA_CRS_USER, 'n', $cmd );
          }	
        }

	# restart services
        if (($patchcrs || ($ocp_patch_ohs_size != 0)) && (! $isrdbmsonlypatch))
        {
	 $nnn = 0;
         my $ohown;
	 foreach $db ( @ocp_databases )
	 {
                $oh = $dboh{$db};
                if (($patchcrs) && ($ocp_patch_ohs_size == 0))
                {
                 $ohown = $ORA_CRS_USER;
                }
                else
                {
                 $ohown = $ohowner{$oh};
                }
                $srvctl_oh = "$oh/bin/srvctl";
                $ENV{ORACLE_HOME} = $oh;
		$cmd = "$srvctl config -p $db -n $node";
		run( '-v', 'srvctl_config_p', $ohown, 'n', $cmd );
		$ret = `$cmd`;
		@tmps = split( /\s+/, $ret );
		$inst = $tmps[1];
		@ocp_srvs = @{ $ocp_services[$nnn] };
		if ( $inst && @ocp_srvs > 0 )
		{
			$srv_str = join ",", @ocp_srvs;
			$cmd = "$srvctl_oh start service -d $db -s $srv_str -i $inst";
			ask( 'step', "Start services for db $db on $node" );
			report( '-n', 0, 0, "$ask_not Starting services for $db on $node" );	
			run( '-v', 'srvctl_start_service_inst', $ask_skip, $ohown, 'n', $cmd );
		}
		else
		{
			report( 0, 0, "no services for database $db configured on node $node" );
		}
		$nnn++;
		
	}
       }
       else
       {
         foreach $oh ( @ocp_patch_ohs )
         {
          $srvctl_oh = "$oh/bin/srvctl";
          $ENV{ORACLE_HOME} = $oh;
          @dbsinoh = split(/:/,$ohdb{$oh});
          foreach $db (@dbsinoh)
          {
           if (! $isrolling)
           {
           $cmd = "$srvctl_oh start service -d $db";
           report( '-n', 0, 0, "$ask_not starting services for database $db  with $cmd" );
           run( '-v', 'srvctl_start_service', $ask_skip, $ohowner{$oh}, 'n', $cmd );
           }
          }
         }
       }
      }
}


### END FOR EACH NODE
report( '-n', 0, 0, "List of patched nodes: $patched_nodes" );
if ($sharedhome eq "true")
{
 report( '-n', 0, 0, "Re-start CRS on all remote nodes with 'crsctl start crs' command");
}
invent( "After patching" );
unlink( $tmpf );
unlink( $tmpfo );
report( '-n', 0, 0, "$pname finished" );
