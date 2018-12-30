#!/usr/local/bin/perl
#
# patch112.pl
#
# Copyright (c) 2007, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      patch112.pl - Auto patching tool for Oracle Clusterware/RAC home.
#
#    DESCRIPTION
#      patch112.pl -  Auto patching tool for Oracle Clusterware/RAC home.
#
#    MODIFIED   (MM/DD/YY)
#       ksviswan   05/08/09  - Implement 11.2 autopatching support 
#
#   NOTES
#
# Documentation: usage output,
#   execute this script with -h option
#
#

################ Documentation ################

# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  patch112.pl - Auto patching tool for Oracle Clusterware/RAC home.

=head1 SYNOPSIS

  patch112.pl -patchn <patch number> 
              -patchdir <patch directory>
              -paramfile <parameter-file>
              [-patchfile <patch zip file location>]
              [-ohs <oracle home location>]
              [-och <crs home location>]
              [-rollback]

  Options:

  -patchdir  patch_directory

             Default is the current directory,
             but must be specified explicitly if you use -patchfile
             If -patchfile is not specified, the patch directory must be
             available on each node under the same pathname with identical
             directory contents. Whether it's shared or node local is 
             irrelevant.

             If -patchfile is used, the directory will be created if necessary.
             All patch directory write operations are done as CRS USER, 
             not root.
             
             Another important thing to consider is that when the patch is 
             already uncompressed you want to specify -patchdir with
             the patch number component: -patchdir /work/patch/5256865
             On the other hand if you uncompress the patch you want
             to specify a directory one level up because the patch
             contains files in the form of 5256865/* so you invoke
             autopatch112.pl with something like

             -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
              -patchnum 5256865 -patchdir /work/patch

             The script will then
             automatically switch to the right directory after uncompressing.

             You should be very careful with -clean in this case because
             an invocation like this will remove everything under /work/patch:

             -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
              -patchnum 5256865 -patchdir /work/patch -clean

             So the preferred way is to use a disposable -patchdir in this case:

             -patchfile /work/patch/p5256865_10202_Linux-x86-64.zip
              -patchnum 5256865 -patchdir /tmp/patch -clean

             Non-absolute pathnames for -patchdir are supported but
             not encouraged.

   -patchfile patch_archive_location
 
            No Default.
            If specified, you must also specify -patchn and -patchdir.
              If -local is specified to indicate node local patch directory,
            this file is considered to be on node local storage as well.
              It's OK to keep the file on shared storage but in any case
            it will be first copied, with rcp, to the patch directory
            on each node, then uncompressed from there.
              Non-absolute pathnames for -patchfile are supported but
            not encouraged.

  -patchn patch_number  
          
            No default, must be specified if and only if
            you use either -patchfile or -rollback.
              The value must correspond to the patch archive contents
            but no validation is done.


  -rollback  

           the patch will be rolled back, not applied
           This option requires -patchnum

 -ohs     Databse home locations    

          comma_delimited_list_of_oralcehomes_to_patch
          The default is all applicable Oracle Homes.
          use this option  to patch RDBMS homes where
          no database is registered.

 -och     Grid infrastructure home location
          absolute path of crs home location. This is used
          to patch Clusterware home that are not configured

 -paramafile Grid infrastructure parameter file location
          Complete path of file specifying clusterware parameter values

                                          
=head1 DESCRIPTION


  This script automates the complete patching process for a Clusterware
  or RAC database home. This script must be run as root user and needs Opatch version
  10.2.0.3.3 or above. 
  Case 1 -  On each node of the CRS cluster in case of Non Shared CRS Home.
  Case 2 -  On any one node of the CRS cluster is case of Shared CRS home.          

=cut

################ End Documentation ################

use strict;
use English;
use Cwd;
use FileHandle;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Sys::Hostname;        
use Net::Ping;
use Getopt::Long;
use Pod::Usage;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
}

use crsconfig_lib;
require crsdelete;
require crspatch;


#Global variables
our $g_help = 0;

# pull all parameters defined in crsconfig_params and s_crsconfig_defs (if
# it exists) as variables in Perl
my $paramfile_default = catfile (dirname ($0), "crsconfig_params");

# pull all definitions in s_crsconfig_defs (if it exists) as variables in Perl
# this file might not exist for all platforms
my $defsfile = catfile (dirname ($0), "s_crsconfig_defs");
my $timestamp = gentimeStamp();
my $logfile  = catfile (dirname ($0), "log", "opatchauto$timestamp.log");


my $PARAM_FILE_PATH = $paramfile_default;
my $patchdir;
my $patchdbdir;
my $patchfile;
my $patchnum;
my $rollback;
my $ohome;
my $chome;
my $pwd = $ENV{'PWD'}?$ENV{'PWD'}:getcwd();
my %ohdb = ();
my %dboh = ();
my %ohowner = ();
my $OS = `uname`;
chomp $OS;
my $ORA_CRS_HOME;
my $ORA_CRS_USER;
my $patchType;
my $homeType;
my @dbhomes = ();
my ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwuid( $< );
my $crs_running;

#TBR
my $overbose;

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
}
else
{
  die "ERROR: $OS is an Unknown Operating System\n";
}

# the return code to give when the incorrect parameters are passed
my $usage_rc = 1;

GetOptions('patchdir=s'     => \$patchdir,
           'patchfile=s'    => \$patchfile,
           'patchnum=s'     => \$patchnum,
           'paramfile=s'    => \$PARAM_FILE_PATH,
           'rollback'       => \$rollback,
           'ohs=s'          => \$ohome,
           'och=s'          => \$chome,
           'help!'          => \$g_help) or pod2usage($usage_rc);


# Check validity of args
pod2usage(-msg => "Invalid extra options passed: @ARGV",
          -exitval => $usage_rc) if (@ARGV);


### Set this host name (lower case and no domain name)
our $HOST = tolower_host();
die "$!" if ($HOST eq "");

# Set the following vars appropriately for cluster env
### check if run as super user
our $SUPERUSER = check_SuperUser ();
if (!$SUPERUSER) {
  error("Insufficient privileges to execute this script");
  exit 1;
}

if ((! $patchdir) || (! $patchnum))
{
   error("-patchdir, -patchnum are Mandatory options");
   pod2usage(1);
}

my $cfg =
  crsconfig_lib->new(paramfile           => $PARAM_FILE_PATH,
                     osdfile             => $defsfile,
                     crscfg_trace        => TRUE,
                     crscfg_trace_file   => $logfile,
                     HOST                => $HOST,
                     );


#Subroutines used by this tool


#Remove trailing white spaces in a string
sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


sub parseOptions
{
   if    ($g_help)   { pod2usage(0); }

   if ( ! $patchdir )
   {
      $patchdir = $pwd;
      trace("using current directory $patchdir for patch directory");
   }

   if( ! $patchfile )
   {
      trace("No -patchfile specified, assuming the patch is already uncompressed" );
   }
 
   if ($ohome && $chome)
   {
      error("Can't specify -ohs with -och");
      pod2usage(1);
   }


}

sub createPatchdir
{
   my $cmd;
   my $status;

   #Create the patch directory
   if( $patchdir && ! -d $patchdir )
   {
       $cmd = "$mkdir -p $patchdir";
       trace( "Executing $cmd as $ORA_CRS_USER" );
       $status = run_as_user($ORA_CRS_USER, $cmd );
   }

}

sub unzipPatch
{
   my $rpatchfile = "";
   my $cmd = "";
   my $node;
   my $ask_skip;
   my @ocp_nodes_topatch;
   my $olocal;
   my $host;
   my $status;

 
   if ( $patchfile )
   {
      $cmd = "$unzip -o $patchfile -d $patchdir";
      trace( "Executing $cmd as $ORA_CRS_USER" );
      if (! -d "$patchdir/$patchnum") {
         $status = run_as_user($ORA_CRS_USER, $cmd );
      } else {
         trace("Patch already unzipped");
      }
   }
   trace( "Adding patch number $patchnum to patch directory $patchdir" );
   $patchdir = "$patchdir/$patchnum";
   if ( ! -d $patchdir )
   {
      error( "Patch directory $patchdir not found, likely error in -patchnum value $patchnum" );
      pod2usage(1);
   }
}

sub findPatchType
{
  #Determine the type of patch
  my $patchtype;
  my @cmdout;
  my @output;
  my @outp;
  my $rc;
  my $opatch = catfile ($ORA_CRS_HOME, "OPatch", "opatch");
  my $cmd = "$opatch query -get_patch_type $patchdir -oh $ORA_CRS_HOME";
  $rc = run_as_user2($ORA_CRS_USER, \@cmdout, $cmd );
  @output = grep(/This patch/, @cmdout);
  trace("output is @output");
  @outp = split(" ", $output[0]);
  $patchtype = $outp[4];
  trace ("Patch type is $patchtype");
  return $patchtype;
}


sub checkConflicts
{
   my $home = $_[0];
   my $rc;
   my @cmdout;
   my @output;
   my $cmd;
   my $opatch = catfile ($ORA_CRS_HOME, "OPatch", "opatch");
   
   my $status = FAILED;
 

   #Check if the patch is applicable
   if (($patchType =~ m/crs/) && ($homeType eq "DB")) {
      $patchdbdir = "$patchdir/custom/server/$patchnum";
      $cmd = "$opatch prereq CheckApplicable -ph $patchdbdir -oh $home";
   } else {  
      $cmd = "$opatch prereq CheckApplicable -ph $patchdir -oh $home";
   }

   $rc = run_as_user2($ORA_CRS_USER, \@output, $cmd);
 

   @cmdout = grep(/passed/, @output);

   if ((scalar(@cmdout) > 0) && ($rc == 0)) {
      $status = SUCCESS;
   } else {
      trace("This Patch is not applicable for $home");
      return $status;
   }

   #Check if there are patch conflicts.
   if (($patchType =~ m/crs/) && ($homeType eq "DB")) {
      $patchdbdir = "$patchdir/custom/server/$patchnum";
      $cmd = "$opatch prereq CheckConflictAgainstOH -ph $patchdbdir -oh $home";
   } else {
      $cmd = "$opatch prereq CheckConflictAgainstOH -ph $patchdir -oh $home";
   }
   $rc = run_as_user2($ORA_CRS_USER, \@output, $cmd);

   @cmdout = grep(/failed/, @output);

   # if scalar(@cmdout) > 0, we found the msg we were looking for
   if ((scalar(@cmdout) > 0) && ($rc == 0)) {
      $status = FAILED;
   } else {
      $status = SUCCESS;
   } 
   
   trace ("Check Conflict Status is $status"); 
   return $status;
}

sub getcrshome
{
  my $crsHome;

  if (! $chome) {
    $crsHome = s_get_olr_file ("crs_home")
  } else {
    $crsHome = $chome;
  }
  if (! -e $crsHome) {
     error("Clusterware home location $crsHome does not exist");
     exit 1;
  }
  return $crsHome;
}

sub getoracleowner
{ 
  my $oh = $_[0];
  my $getoh_ox = "$oh/bin/oracle";
  my $getoh_u;
  if (  -f $getoh_ox )
  {
     my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat( $getoh_ox );
     ($name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwuid( $uid );
     $getoh_u = $name;
     trace( "Oracle user for $oh is $getoh_u" );
  }
  else {
     error("unable to get oracle owner for $oh");
     exit 1;
  }
  return $getoh_u;
}
  
sub findHomes
{
  
        my @tmps = ();
        my $db = "";
        my $oh = "";
        my @ohs = ();
        my $getoh_ox = "";
        my $getoh_u = "";
        my $getoh_n = "";
        my @ocp_ohs = ();
        my @ocp_databases;
        my @ocp_ous;
        my $ocp_dblist;
        my $ocp_ohlist;
        my @tmp_ohlist;
        my @tmp_ohlist1; 
        my $ocp_oulist;

        if ($ohome)
        {
           @ocp_ohs = split( /\,/, $ohome);
        } elsif ($chome) {
           @ocp_ohs = $chome
        }         
        else
        {
      
        my $srvctl    = catfile ($ORA_CRS_HOME, "bin", "srvctl");

        trace( "Looking for configured databases on node $HOST" );
        @ocp_databases = `$srvctl config`;
        chomp @ocp_databases;
        $ocp_dblist = join " ", @ocp_databases;
        trace( "Databases configured on node $HOST are: $ocp_dblist" );
        trace( "Determining ORACLE_HOME paths for configured databases" );
        $ocp_ohlist = "";
        @ocp_ohs = ();
        foreach $db ( @ocp_databases )
        {
                #trace( "Looking at database $db" );
                @ohs = `$srvctl config database -d $db`;
                chomp @ohs;
                if ( @ohs == 0 )
                {
                        trace( "No ORACLE_HOME found for $db" );
                }
                else
                {
                        @tmps = grep(/Oracle home:/, @ohs);
                        trace("output is @tmps");
                        my ($dummy, $ohpath) = split( /\:/, $tmps[0] );
                        $dboh{$db} = trim($ohpath);
                        trace("Oracle home for database $db is $dboh{$db}");
                }
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

        foreach $oh (keys%ohdb)
        {
         trace( "Oracle Home $oh is configured with Database\(s\)\-\> $ohdb{$oh}");
        }

        }
        foreach $oh ( @ocp_ohs )
        {
          my $ohown = getoracleowner($oh);
          $ohowner{$oh} = $ohown;
        }
 trace("oracle home list is @ocp_ohs");
 return @ocp_ohs;
}


sub isSIHA
{
   my $ret= FAILED;
   my $local_only = s_get_config_key("ocr", "local_only");
   if ($local_only =~ m/true/i) {
      $ret = SUCCESS;
   }
   return $ret;
}
      
sub findHomeType
{
   my $home = $_[0];
   my $crshome;
   my $type;
   my $local_only = s_get_config_key("ocr", "local_only");
   $crshome = getcrshome();

   if (($home eq $crshome) && ($local_only =~ m/true/i)) {
     $type = "HA";
   } elsif (($home eq $crshome) && ($local_only =~ m/false/i)) {
     $type = "CRS";
   } else {
     $type = "DB";
   }

   return $type;
}

sub applyPatch
{
   my $home = $_[0];
   my $cmd = "";
   my $op_silent;
   my $status;
   my $opatch = catfile ($ORA_CRS_HOME, "OPatch", "opatch");
   if (($patchType =~ m/crs/) && ($homeType eq "DB")) {
      $patchdbdir = "$patchdir/custom/server/$patchnum";
      $cmd = "$opatch napply $patchdbdir -local $op_silent -oh $home -id $patchnum";
   } else {
      $cmd = "$opatch napply $patchdir -local $op_silent -oh $home -id $patchnum";
   }
   trace("Executing command $cmd as $ORA_CRS_USER");
   $status = run_as_user($ORA_CRS_USER, $cmd );
   trace("status of apply patch is $status");
}

sub rollbackPatch
{
   my $home = $_[0];
   my $op_silent;
   my $status;
   my $opatch = catfile ($ORA_CRS_HOME, "OPatch", "opatch");
   my $cmd = "$opatch rollback -local $op_silent -oh $home -id $patchnum";
   trace("Executing command $cmd as $ORA_CRS_USER");
   $status = run_as_user($ORA_CRS_USER, $cmd );
   trace("status of rollback patch is $status");

}

sub PerformDBPatch
{
  my $home = $_[0];
  my $ohown = $ohowner{$home};
  my $cmd;
  my $status;
  
  Stopdbhomeres($home);
  $cmd = "$patchdbdir/custom/scripts/prepatch.sh -dbhome $home";
  $status = run_as_user ($ohown, $cmd);
  if ($status == 0) {
     trace ("prepatch execution for DB home ... success");
     if ( $rollback ) {
     rollbackPatch($home);
     } else {
     applyPatch($home);
     }
  } else {
     error ("prepatch execution for DB home ... failed");
     exit 1;
  }

  $cmd = "$patchdbdir/custom/scripts/postpatch.sh -dbhome $home";
  $status = run_as_user ($ohowner{$home}, $cmd);
  if ($status == 0) {
      trace ("postpatch execution for DB home ... success");
      Startdbhomeres($home);
   } else {
      error ("postpatch execution for DB home ... failed");
      exit 1;
  }

}

sub gentimeStamp
{
  my ($sec, $min, $hour, $day, $month, $year) =
        (localtime) [0, 1, 2, 3, 4, 5];
  $month = $month + 1;
  $year = $year + 1900;

  my $ts = sprintf("%04d-%02d-%02d_%02d-%02d-%02d",$year, $month, $day, $hour, $min, $sec);
  return $ts;
}
   
##MAIN BODY

parseOptions();

$ORA_CRS_HOME = getcrshome();
$ORA_CRS_USER = getoracleowner($ORA_CRS_HOME);

createPatchdir();
unzipPatch();

$patchType = findPatchType();

#check if clusterware running
my $status = isSIHA();
if (! ($status == SUCCESS))
{
   $crs_running = check_service ("cluster", 2);
}

if ((! $crs_running) && (! $chome)) {
   print "Clusterware is either  not running or not configured. You have the following 2 options\n";
   print "1. Configure and Start the Clusterware on this node and re-run the tool\n";
   print "2. or Run the tool with the -och <CRS_HOME_PATH> option and then invoke  tool with -ohs <comma seperated ORALCE_HOME_LIST> to patch the RDBMS home\n"; 
   exit 1;
} 

@dbhomes = findHomes();

if (($patchType =~ m/crs/) && (! $ohome) && (! $chome))
{ 
   push (@dbhomes, $ORA_CRS_HOME);
}

foreach my $home (@dbhomes) {

  my $status;

  trace("Processing oracle home $home");
  $homeType = findHomeType($home);
  $status = checkConflicts ($home);     
  trace("Home type of $home is $homeType");
  trace("Status of conflict check  for $home is $status");
  if ($status == SUCCESS) 
  {
    if ($homeType eq "CRS")
    {
       if (! $chome) {
          unlockCRSHome();
       }
       if ( $rollback ) {
          rollbackPatch($home);
       } else {
          applyPatch($home);
       }
       if (! $chome) {
          CRSPatch();
       }
    }
    elsif ($homeType eq "HA")
    {
       if (! $chome) {
          unlockHAHome();
       }
       if ( $rollback ) {
         rollbackPatch($home);
       } else {
         applyPatch($home);
       }
       if (! $chome) {
          HAPatch();
       }
    } 
    else
    {
       trace("Performing DB patch");
       PerformDBPatch($home); 
    } 
  } else {
       error("Patch Apllicable/Conflict check failed for $home");
  }
}
0;
