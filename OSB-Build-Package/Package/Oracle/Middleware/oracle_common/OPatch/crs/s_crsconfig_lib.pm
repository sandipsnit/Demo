#!/usr/local/bin/perl
# 
# $Header: has/install/crsconfig/s_crsconfig_lib.pm /unix/70 2009/10/27 21:38:22 anutripa Exp $
#
# s_crsconfig_lib.pm
# 
# Copyright (c) 2007, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      s_crsconfig_lib.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    sujkumar    09/22/09 - Add IPD/OS related changes
#    dpham       09/14/09 - XbranchMerge dpham_bug-8484319 from
#                           st_has_11.2.0.1.0
#    dpham       09/04/09 - /etc/oracle is removed only if it's empty (8798767)
#    hchau       08/21/09 - Bug 8716580, 8276914. Unset TNS_ADMIN and
#                           ORACLE_BASE env vars in the ENV file.
#    dpham       08/21/09 - XbranchMerge dpham_bug-8776078 from
#                           st_has_11.2.0.1.0
#    dpham       08/19/09 - XbranchMerge dpham_bug-8395346 from main
#    dpham       08/19/09 - XbranchMerge dpham_bug-8726265 from
#                           st_has_11.2.0.1.0
#    hchau       08/17/09 - Sync comment on ENV VAR file syntax from
#                           crswrapexec.pl
#    dpham       08/17/09 - Add 'return' to no-op functions
#    dpham       08/10/09 - XbranchMerge dpham_bug8762050 from
#                           st_has_11.2.0.1.0
#    dpham       08/04/09 - Fix 'signal 2' issue (bug 8762050
#    dpham       07/31/09 - Fix bug 8395346
#    dpham       07/15/09 - XbranchMerge dpham_bug-8664938 from main
#    dpham       07/09/09 - 'crs_stat' should be used to check if it's runnnig in 10.1
#    dpham       07/08/09 - zero out ocr device only if it's not on ASM
#			  - Add new blank line before add daemon in inittab
#    hchau       07/07/09 - Bug 8657323. Fix TZ not retrieved correctly from
#                           ORACLE_OWNER
#    dpham       06/30/09 - Print error in s_copyOCRLoc() only if it failed to copy
#    ksviswan    06/24/09 - Fix Bug 8626827 and 8630938
#    dpham       06/22/09 - Capture error output from cluutil.
#			  - Remove extra 'print' statement from s_run_as_user2
#    dpham       06/17/09 - Add logic to remove /etc/oratab
#    vmanivel    06/16/09 - Bug 8582457
#    dpham       06/16/09 - Remove 'set ocrconfig_loc to srvconfig_loc' in 
#			    s_validateOCR for 9i
#    dpham       06/15/09 - Add ocrconfig_loc3 and ocrconfig_loc4 check in s_validateOCR
#    dpham       06/01/09 - 'cluutil' should be run as oracle owner
#			  - s_removeGPnPprofile() should only remove contents
#    dpham       05/31/09 - Change msg in s_isRAC_appropriate()
#    nvira       05/28/09 - specify --allmatches option to cvuqdisk rpm -e
#                           command
#    jgrout      05/22/09 - Fix bug 8540887
#    dpham       05/20/09 - Add s_copyOCRLoc & s_removeGPnPprofile
#    jgrout      05/11/09 - Use "crsctl start has" instead of "ohasd reboot &"
#    dpham       05/11/09 - Add s_is92ConfigExists
#    dpham       04/27/09 - Add s_houseCleaning
#                         - Add an arguement to s_remove_itab
#    spavan      04/22/09 - fix bug8424504 - Mask old RPM removal error
#    dpham       04/15/09 - Add s_createLocalOnlyOCR
#    ksviswan    04/15/09 - XbranchMerge ksviswan_rootmisc_fixes from
#                           st_has_11.2beta2
#    ksviswan    04/13/09 - Remove ocr.loc on lastnode for all storage type
#    dpham       04/08/09 - XbranchMerge dpham_bug-8412144 from main
#    dpham       04/07/09 - XbranchMerge dpham_bug-8400917 from main
#    dpham       04/07/09 - Fix s_crsconfig_$HOST_env file.
#    dpham       04/02/09 - Check OldCrsStack for 10.1
#    dpham       03/27/09 - Add comments in s_createConfigEnvFile
#    spavan      03/25/09 - fix bug7700245
#    dpham       03/20/09 - Return to caller if failed in s_validateOCR
#    dpham       03/15/09 - Do not remove contents from OCR device if it's on ASM
#			  - Fix /tmp/.oracle & /var/tmp/.oracle
#    dpham       02/23/09 - Remove /etc/oracle if it's empty
#    dpham       02/22/09 - Modify s_get_olr_file to eccept arguement
#    dpham       02/04/09 - Add s_isRAC_appropriate to check for rac_on/rac_off
#    dpham       01/09/09 - Rename s_setParentDir2Root to s_setParentDirOwner
#                         - Change its functionality so that it should be able
#                           to handle any dir and any owner.
#    dpham       01/05/09 - Remove single quote from LANGUAGE_ID
#    ksviswan    12/29/08 - Add s_check_OldCrsStack
#    hchau       12/12/08 - Add 'DO NOT TOUCH' comment in config env file
#                         - Fix config env file name
#    ksviswan    11/19/08 - Add s_ResetOLR for SIHA
#    dpham       11/14/08 - Add s_checkOracleCM
#                         - Add s_createConfigEnvFile for Time Zone
#    dpham       10/23/08 - Add s_start_ocfs_driver
#    dpham       10/14/08 - Add s_ResetVotedisks
#    jleys       08/17/08 - Start OHASD as user for SIHA
#    jleys       10/02/08 - Add leading 0 to chmod in s_Reset_OCR
#    dpham       08/28/08 - add s_setParentDir2Root  
#    khsingh     08/04/08 - add API to change owners on CRS files
#    khsingh     07/31/08 - fix s_clean_rcdirs
#    jleys       06/01/08 - Do not start ohasd using s_run_as_user
#    jgrout      05/21/08 - Restore explicit OHASD fork to avoid
#                           security issues in crsctl start has
#    hkanchar    05/04/08 - Fix getOldCrsHome
#    dpham       04/28/08 - Add new subroutines for root deconfig 
#    ysharoni    04/22/08 - rc fix for run_as_user2
#    jgrout      04/04/08 - Fix bug 6897603
#    hkanchar    03/30/08 - Move somepart of upgrade code to OSDS
#    srisanka    03/25/08 - bug 6915812: replace check for file/dir with check
#                           for existence of path
#    jgrout      03/21/08 - Create OHASD autostart and run files
#    srisanka    03/18/08 - handle stdout/stderr
#    ysharoni    02/21/08 - add run_as_user2
#    jtellez     02/17/08 - check for inittab exitance
#    jtellez     02/17/08 - bug 6822192: fix perms on init files
#    srisanka    02/14/08 - add OSD setup APIs
#    srisanka    01/31/08 - add s_isLink() API
#    srisanka    01/28/08 - use s_get_config_key()
#    srisanka    01/09/08 - Creation
#
use File::Copy;
use POSIX qw(tmpnam);
use Cwd;

@ns_dir    = ("/var/tmp/.oracle","/tmp/.oracle");
$dev_null  = "/dev/null";
$cmd_chgrp = "/bin/chgrp";
my $FSSEP  = "/";
my ($ARCHIVE, $INITD, $ENVMT);

if ($OSNAME eq 'linux') {
   $INITD   = '/etc/init.d';
   $ARCHIVE = '/usr/bin/ar';
   $ENVMT   = '/usr/bin/env';
} elsif ($OSNAME eq 'solaris') {
   $INITD   = '/etc/init.d';
   $ARCHIVE = '/usr/ccs/bin/ar';
   $ENVMT   = '/usr/bin/env';
} elsif ($OSNAME eq 'hpux') {
   $INITD   = '/sbin/init.d';
   $ARCHIVE = '/usr/ccs/bin/ar';
   $ENVMT   = "/bin/env";
} elsif ($OSNAME eq 'aix') {
   $INITD   = '/etc';
   $ARCHIVE = '/usr/ccs/bin/ar -X64';
   $ENVMT   = '/usr/bin/env';
} elsif ($OSNAME eq 'dec_osf') {
   $INITD   = '/sbin/init.d';
   $ARCHIVE = '/usr/bin/ar';
   $ENVMT   = '/usr/bin/env';
}

####---------------------------------------------------------
#### Function for checking and returning Super User name
# ARGS : 0
sub s_check_SuperUser
{
    my $superUser = "root";

    trace ("Checking for super user privileges");

    my $program="this script";

    # get user-name
    my $usrname = getpwuid ($<);
    if ($usrname ne $superUser) {
        error ("You must be logged in as $superUser to run $program.");
        error ("Log in as $superUser and rerun $program.");
        return "";
    }

    trace ("User has super user privileges");

    return $superUser;
}

####---------------------------------------------------------
#### Function for setting user and group on a specified path
# ARGS : 3
# ARG1 : Oracle owner
# ARG2 : Oracle group 
# ARG3 : file
sub s_set_ownergroup
{
    my ($owner, $group, $file) = @_;

    if (!$owner) {
        error ("Null value passed for Oracle owner");
        return $FAILED;
    }

    if (!$group) {
        error ("Null value passed for group name");
        return $FAILED;
    }

    if (!$file) {
        error ("Null value passed for file or directory path");
        return $FAILED;
    }

    if (!(-e $file)) {
        error ("The path \"" . $file . "\" does not exist");
        return $FAILED;
    }

    my $uid = getpwnam ($owner);
    my $gid = getgrnam ($group);
    if ($DEBUG) {
	trace("Setting owner ($owner:$uid) and group ($group:$gid) on file $file");
    }

    chown ($uid, $gid, $file) or return $FAILED;

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for resetting owner and permissions of CRS home dirs/files
# ARGS : 4
# ARG1 : Oracle owner
# ARG2 : Oracle group
# ARG3 : perms
# ARG4 : directory path
sub s_reset_crshome
{
    ($owner, $group, $perms, $basedir) = @_;

    if (!$owner) {
        error ("Null value passed for Oracle owner");
        return $FAILED;
    }

    if (!$group) {
        error ("Null value passed for group name");
        return $FAILED;
    }

    if (!$perms) {
        error ("Null value passed for file permission");
        return $FAILED;
    }

    $permarg = $perms;
    $userid  = getpwnam ($owner);
    $groupid = getgrnam ($group);

    finddepth (\&reset_perms, $basedir);

    if (! is_dev_env()) {
       # reset owner/group of basedir and its parent dir to ORACLE_OWNER/DBA

      if ($DEBUG) {
	trace("Setting owner ($owner:$userid), group ($group:$groupid), and permissions ($perms) on file $_\n");
      }

       s_setParentDirOwner ($owner, $basedir);
    }

    sub reset_perms
    {
      #Set Oracle Binary permissions to 6755
      if ($_ eq "oracle")
      {
       $perms = "6755";
      }
      else
      {
       $perms = $permarg;
      }

      chown ($userid, $groupid, $_);
      chmod (oct ($perms), $_);
    }

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for setting permissions on a specified path
# ARGS : 2
# ARG1 : permissions
# ARG3 : file/dir
sub s_set_perms
{
    my ($perms, $file) = @_;

    if (!$perms) {
        error ("Null value passed for permissions");
        return $FAILED;
    }

    if (!$file) {
        error ("Null value passed for file or directory path");
        return $FAILED;
    }

    if (!(-e $file)) {
        error ("The path \"" . $file . "\" does not exist");
        return "$FAILED";
    }

    if ($DEBUG) { trace ("Setting permissions ($perms) on file/dir $file"); }

    chmod (oct ($perms), $file) or return $FAILED;

    return $SUCCESS;
}

####---------------------------------------------------------
#### Functions for copying script to init directory
# ARGS : 2
# ARG1 : init script name
# ARG2 : destination file
sub s_copy_to_initdir
{
    my $sourcefile = $_[0];
    my $destfile = $_[1];

    if (!$sourcefile) {
        error ("The init script file name passed is null");
        return $FAILED;
    }

    if (!(-f $sourcefile)) {
        error ("The init script file \"" . $sourcefile . "\" does not exist");
        return $FAILED;
    }

    trace ("init file = " . $sourcefile);

    trace ("Copying file " . $sourcefile . " to " . $ID . " directory");
    copy ($sourcefile, catfile ($ID, $destfile)) or return $FAILED;

    trace ("Setting " . $destfile . " permission in " . $ID . " directory");
    s_set_perms ("0755", catfile ($ID, $destfile)) or return $FAILED;
    return $SUCCESS;
}

####---------------------------------------------------------
#### Functions for copying script to init directory
# ARGS : 1
# ARG1 : init script name
# ARG1 : dest name
sub s_copy_to_rcdirs
{
    my $sourcefile = $_[0];
    my $destfile = $_[1];

    if (!$sourcefile) {
        error ("The init script file name passed is null");
        return $FAILED;
    }

    if (!(-f $sourcefile)) {
        error ("The init script file \"" . $sourcefile . "\" does not exist");
        return $FAILED;
    }

    trace ("init file = " . $sourcefile);

    # Copy to init dir
    trace ("Copying file " . $sourcefile . " to " . $ID . " directory");
    copy ($sourcefile, catfile ($ID, $destfile)) or return $FAILED;
    trace ("Setting " . $destfile . " permission in " . $ID . " directory");
    s_set_perms ("0755", catfile ($ID, $destfile)) or return $FAILED;

    # Create a link to the file in the init dir
    my @RCSDIRLIST = split (/ /, $RCSDIR);
    foreach my $rc (@RCSDIRLIST) {
        trace ("Removing \"" . $rc . "/" . $RC_START . $destfile . "\"");
        s_remove_file ("$rc/$RC_START$destfile");
        trace ("Creating a link \"" . catfile ($rc, "$RC_START$destfile") .
               "\" pointing to " . catfile ($ID, $destfile));
        symlink (catfile ($ID, $destfile), catfile($rc, "$RC_START$destfile"))
            or return $FAILED;
    }

    my @RCKDIRLIST = split (/ /, $RCKDIR);
    foreach my $rc (@RCKDIRLIST) {
        trace ("Removing \"" . $rc . "/" . $RC_KILL . $destfile . "\"");
        s_remove_file ("$rc/$RC_KILL$destfile");  
        trace ("Creating a link \"" . catfile ($rc, "$RC_KILL$destfile") .
               "\" pointing to " . catfile ($ID, $destfile));
        symlink (catfile ($ID, $destfile), catfile ($rc, "$RC_KILL$destfile"))
            or return $FAILED;
    }

    trace ("The file " . $destfile .
           " has been successfully linked to the RC directories");

    return $SUCCESS;
}

####---------------------------------------------------------
#### Functions for removing script from rc directories
# ARGS : 1
# ARG1 : init script name
sub s_clean_rcdirs
{
    my $file = $_[0];

    if (!$file) {
        error ("Null value passed for init script file name");
        return $FAILED;
    }

    trace ("Init file = " . $file);
    trace ("Removing \"" . $file . "\" from RC dirs");

    #remove old ones
    if ($RCALLDIR) {
        my ($rc, $rcStartFile, $rcKillFile, $rcKillOldFile);
        my @RCALLDIRLIST = split (/ /, $RCALLDIR);

        foreach $rc (@RCALLDIRLIST) {
            if ($RC_START) {
                $rcStartFile = catfile ($rc, "$RC_START$file");
                s_remove_file ("$rcStartFile");
            }

            if ($RC_KILL) {
                $rcKillFile = catfile ($rc, "$RC_KILL$file");
                s_remove_file ("$rcKillFile");
            }

            if ($RC_KILL_OLD) {
                $rcKillOldFile = catfile ($rc, "$RC_KILL_OLD$file");
                s_remove_file ("$rcKillOldFile");
            }
        }
    }
}

####---------------------------------------------------------
#### Function for adding CRS entries to inittab
# ARGS : 0
sub s_add_itab
{
    my $INITTAB_CH = catfile ($ORA_CRS_HOME, "crs", "install", "inittab");
    if (-e $INITTAB_CH) {

        unless (open (ITAB, "<$IT")) {
            error ("Can't open $IT for reading: $!");
            return $FAILED;
        }
        unless (open (ITABNOCRS, ">$IT.no_crs")) {
            error ("Can't open $IT.no_crs for writing: $!");
            return $FAILED;
        }

        # Remove ohasd from inittab
        while (<ITAB>) {
            if (!($_ =~ /init.ohasd/)) {
                print ITABNOCRS "$_";
            }
        }
        close (ITABNOCRS);
        close (ITAB);
        trace("Created backup $IT.no_crs");

        unless (copy ("$IT.no_crs", "$IT.tmp")) {
            error ("Can't copy $IT.no_crs to $IT.tmp: $!");
            return $FAILED;
        }

        unless (open (CRSITAB, "<$INITTAB_CH")) {
            error ("Can't open $INITTAB_CH for reading: $!");
            return $FAILED;
        }

        unless (open (ITABTMP, ">>$IT.tmp")) {
            error ("Can't open $IT.tmp for append: $!");
            return $FAILED;
        }

        trace ("Appending to $IT.tmp:");
        while (<CRSITAB>) {
            print ITABTMP "\n";
            print ITABTMP "$_";
            trace ("$_");
        }
        close (ITABTMP);
        close (CRSITAB);
        trace ("Done updating $IT.tmp");

        unless (copy ("$IT.tmp", "$IT.crs")) {
            error("Can't copy $IT.tmp to $IT.crs: $!");
            return $FAILED;
        }
        trace("Saved $IT.crs");

        unless (move ("$IT.tmp", $IT)) {
            error("Can't move $IT.tmp to $IT: $!");
            return $FAILED;
        }
        trace("Installed new $IT");
    } else {
        error("$INITTAB_CH does not exist.");
        return $FAILED;
    }

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for removing CRS entries from inittab
# ARGS : 1 - match pattern for inittab entries
sub s_remove_itab
{
    my $match_pattern = $_[0];
    trace ("itab entries=$itab_entries");

    unless (open (ITAB, "<$IT")) {
        print "Can't open $IT for reading: $!";
        return $FAILED;
    }
    unless (open (ITABTMP, ">$IT.tmp")) {
        print "Can't open $IT.tmp for writing: $!";
        return $FAILED;
    }

    while (<ITAB>) {
        if (!($_ =~ /init.($match_pattern)/)) {
            print ITABTMP "$_";
        }
    }
    close (ITABTMP);
    close (ITAB);

    unless (copy ("$IT.tmp", "$IT.no_crs")) {
        print "Can't copy $IT.tmp to $IT.no_crs: $!";
        return $FAILED;
    }

    unless (move ("$IT.tmp", $IT)) {
        print "Can't move $IT.tmp to $IT: $!";
        return $FAILED;
    }

    return $SUCCESS;
}
#
####-----------------------------------------------------------------------
#### Function for performing clusterwide one-time setup
# ARGS: 0
sub s_first_node_tasks
{
    # no-op on Linux
    return $SUCCESS;
}

####-----------------------------------------------------------------------
#### Function for performing Linux-specific setup
# ARGS: 0
sub s_osd_setup
{
    # no-op on Linux
    return $SUCCESS;
}

####-----------------------------------------------------------------------
#### Function for checking if CRS is already configured
# ARGS: 2
# ARG1: hostname
# ARG2: crs user
sub s_check_CRSConfig
{
    my $hostname = $_[0];
    my $crsuser = $_[1];

    my $SCRDIR = catfile ($SCRBASE, $hostname);
    my $FATALFILE = catfile ($SCRDIR, $crsuser, "cssfatal");
    if ((-f $FATALFILE) && (-f $OCRCONFIG)) {
        trace ("Oracle CRS stack is already configured and will be " .
               "running under init \(1M\)");
        return $TRUE;
    } else {
        trace ("Oracle CRS stack is not configured yet");
        return $FALSE;
    }
}

####-----------------------------------------------------------------------
#### Function for validating olr.loc file and creating it if does not exist
# ARGS: 2
# ARG1 : Complete path of OLR location
# ARG2 : CRS Home
sub s_validate_olrconfig
{
    my $olrlocation = $_[0];
    my $crshome     = $_[1];

    trace ("Validating " . $OLRCONFIG .
           " file for OLR location " . $olrlocation);

    ## @todo Check existing olr.loc file. If it exists, then check value of
    #  olrconfig_loc property. If it's same as the one passed on the call
    #  then go ahead. Else, throw an error msg and quit the installation.
    if (-f $OLRCONFIG) {
        trace ("$OLRCONFIG already exists. Backing up " . $OLRCONFIG .
               " to " . $OLRCONFIG . ".orig");
        # Need to remove this once the @todo is implemented.
        copy ($OLRCONFIG, $OLRCONFIG . ".orig") or return $FAILED;
    }

    open (OLRCFGFILE, ">$OLRCONFIG") or return $FAILED;
    print OLRCFGFILE "olrconfig_loc=$olrlocation\n";
    print OLRCFGFILE "crs_home=$crshome\n";
    close (OLRCFGFILE);

    #FIXME: This should be moved to add_olr_ocr_vdisks_locs
    if ($CFG->UPGRADE)
    {
       if (is_dev_env()) {
          s_set_ownergroup ($ORACLE_OWNER, $ORA_DBA_GROUP, $OLRCONFIG);
          s_set_perms ("0644", $OLRCONFIG) ;
       } else {
          s_set_ownergroup ($SUPERUSER, $ORA_DBA_GROUP, $OLRCONFIG);
          s_set_perms ("0644", $OLRCONFIG) ;
       }
       trace("Done setting permissions on file $OLRCONFIG");
    }

    return $SUCCESS;
}

sub s_get_olr_file
#-------------------------------------------------------------------------------
# Function:  Get key from olr.loc
# Args    :  1 - key
# Returns :  Key's value
#-------------------------------------------------------------------------------
{
    my $key = $_[0];
    my $ret = "";

    if (!(-r $OLRCONFIG)) {
        error ("Either " . $OLRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }
    trace("olrconfig is $OLRCONFIG");
    trace("key passed is $key");
    open (OLRCFGFILE, "<$OLRCONFIG") or return $ret;
    while (<OLRCFGFILE>) {
        if (/^$key=(\S+)/) {
            $ret = $1;
            last;
        }
    }
    close (OLRCFGFILE);
    trace("return value is $ret");
    return $ret;
}

####---------------------------------------------------------
#### Function for validating ocr.loc file
# ARGS: 2
# ARG1 : ocrlocations
# ARG2 : isHas
sub s_validate_ocrconfig
{
    my $ocrlocations = $_[0];
    my $isHas        = $_[1];

    trace ("Validating OCR locations in " . $OCRCONFIG);

    trace ("Checking for existence of " . $OCRCONFIG);
    if (-f $OCRCONFIG) {
        trace ("Backing up " . $OCRCONFIG . " to " . $OCRCONFIG . ".orig");
        copy ($OCRCONFIG, $OCRCONFIG . ".orig") or return $FAILED;
    }

    my ($ocrlocation,
        $ocrmirrorlocation,
        $ocrlocation3,
        $ocrlocation4,
        $ocrlocation5) = split (/\s*,\s*/, $ocrlocations);

    open (OCRCFGFILE, ">$OCRCONFIG") or return $FAILED;

    trace ("Setting ocr location " . $ocrlocation);
    print OCRCFGFILE "ocrconfig_loc=$ocrlocation\n";

    if ($ocrmirrorlocation) {
        trace ("Setting ocr mirror location " . $ocrmirrorlocation);
        print OCRCFGFILE "ocrmirrorconfig_loc=$ocrmirrorlocation\n";
    }

    if ($ocrlocation3) {
        trace ("Setting ocr location3 " . $ocrlocation3);
        print OCRCFGFILE "ocrconfig_loc3=$ocrlocation3\n";
    }

    if ($ocrlocation4) {
        trace ("Setting ocr location4 " . $ocrlocation4);
        print OCRCFGFILE "ocrconfig_loc4=$ocrlocation4\n";
    }

    if ($ocrlocation5) {
        trace ("Setting ocr location5 " . $ocrlocation5);
        print OCRCFGFILE "ocrconfig_loc5=$ocrlocation5\n";
    }

    if ($isHas) {
        print OCRCFGFILE "local_only=TRUE\n";
    } else {
        print OCRCFGFILE "local_only=FALSE\n";
    }

    close (OCRCFGFILE);

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for retrieving OCR location from ocr.loc
# ARGS: 0
sub s_get_ocrdisk
{
    my $ret = "";

    if (!(-r $OCRCONFIG)) {
        error ("Either " . $OCRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("ocr", "ocrconfig_loc");

    return $ret;
}

####---------------------------------------------------------
#### Function for returning OCR mirror location from ocr.loc
# ARGS: 0
sub s_get_ocrmirrordisk
{
    my $ret = "";

    if (!(-r $OCRCONFIG)) {
        error ("Either " . $OCRCONFIG . " does not exist or is not readable");
        error ("Make sure the file exists and it has read and execute access");
        return $ret;
    }

    $ret = s_get_config_key ("ocr", "ocrmirrorconfig_loc");

    return $ret;
}

####---------------------------------------------------------
#### Validating OCR locations based on existing ocr settings
# ARGS: 3
# ARG1 : Path for Oracle CRS home
# ARG2 : Cluster name
# ARG3 : Comma separated OCR locations
sub s_validateOCR
{
    my $crshome        = $_[0];
    my $clustername    = $_[1];
    my $ocrlocations   = $_[2];
    my $status         = $SUCCESS;
    my $OCR_SYNC_FILE  = catfile ($crshome, "srvm", "admin", $OCRLOC);
    my $OCR_CDATA_DIR  = catfile ($crshome, "cdata");
    my $OCR_BACKUP_DIR = catfile ($crshome, "cdata", $clustername);

    my $SRVCONFIG_LOC = "";
    if (-f $SRVCONFIG) {
        trace ("Checking repository used for 9i installations");

        # srvConfig.loc file exists and repository location is
        $SRVCONFIG_LOC = s_get_config_key ("srv", "srvconfig_loc");

        if ($SRVCONFIG_LOC eq "/dev/null") {
            # 9.x srvconfig_loc is already invalidated. So ignore it
            # # take the location entered by user to populate ocr.loc
            $SRVCONFIG_LOC = "";
        }
    }

    ##Checking the OCR locations used by 10gR1 or previous 10gR2
    #installations
    my $OCRCONFIG_LOC = "";
    my $OCRMIRRORCONFIG_LOC = "";
    my $OCRCONFIG_LOC3 = "";
    my $OCRCONFIG_LOC4 = "";
    my $OCRCONFIG_LOC5 = "";

    if (-f $OCRCONFIG) {
        trace ("Retrieving OCR location used by previous installations");
        # ocr.loc file exists and ocr location set here is
        $OCRCONFIG_LOC       = s_get_config_key ("ocr", "ocrconfig_loc");
        $OCRMIRRORCONFIG_LOC = s_get_config_key ("ocr", "ocrmirrorconfig_loc");
        $OCRCONFIG_LOC3      = s_get_config_key ("ocr", "ocrconfig_loc3");
        $OCRCONFIG_LOC4      = s_get_config_key ("ocr", "ocrconfig_loc4");
        $OCRCONFIG_LOC5      = s_get_config_key ("ocr", "ocrconfig_loc5");
    }

    my $OCRFILE = $OCRCONFIG;

    trace ("Checking if OCR sync file exists");

    if (-f $OCR_SYNC_FILE) {
        trace ("$OCR_SYNC_FILE exists");
        ##Checking the OCR locations used by existing nodes in the cluster
        my $NEW_OCR_FILE = "";
        my $NEW_OCRMIRROR_FILE = "";
        my $NEW_OCRMIRROR_LOC3 = "";
        my $NEW_OCRMIRROR_LOC4 = "";
        my $NEW_OCRMIRROR_LOC5 = "";

        open (OCRSYNCFILE, "<$OCR_SYNC_FILE");

        while (<OCRSYNCFILE>) {
            if (/^ocrconfig_loc=(\S+)/) {
                $NEW_OCR_FILE = $1;
            }
            if (/^ocrmirrorconfig_loc=(\S+)/) {
                $NEW_OCRMIRROR_FILE = $1;
            }
            if (/^ocrconfig_loc3=(\S+)/) {
                $NEW_OCRMIRROR_LOC3 = $1;
            }
            if (/^ocrconfig_loc4=(\S+)/) {
                $NEW_OCRMIRROR_LOC4 = $1;
            }
            if (/^ocrconfig_loc5=(\S+)/) {
                $NEW_OCRMIRROR_LOC5 = $1;
            }
        }
        close (OCRSYNCFILE);

        trace ("NEW_OCR_FILE=$NEW_OCR_FILE");
        trace ("NEW_OCRMIRROR_FILE=$NEW_OCRMIRROR_FILE");
        trace ("NEW_OCRMIRROR_LOC3=$NEW_OCRMIRROR_LOC3");
        trace ("NEW_OCRMIRROR_LOC4=$NEW_OCRMIRROR_LOC4");
        trace ("NEW_OCRMIRROR_LOC5=$NEW_OCRMIRROR_LOC5");

        $ocrlocations = $NEW_OCR_FILE;

        if ($NEW_OCRMIRROR_FILE) {
            $ocrlocations = "$ocrlocations,$NEW_OCRMIRROR_FILE";
        }
        if ($NEW_OCRMIRROR_LOC3) {
            $ocrlocations = "$ocrlocations,$NEW_OCRMIRROR_LOC3";
        }
        if ($NEW_OCRMIRROR_LOC4) {
            $ocrlocations = "$ocrlocations,$NEW_OCRMIRROR_LOC4";
        }
        if ($NEW_OCRMIRROR_LOC5) {
            $ocrlocations = "$ocrlocations,$NEW_OCRMIRROR_LOC5";
        }

        trace ("OCR locations (obtained from $OCR_SYNC_FILE) = $ocrlocations");
    } else {
        ##Syncing of OCR disks is not required
        trace ("No need to sync OCR file");
    }

    my ($OCR_LOCATION,$OCR_MIRROR_LOCATION,$OCR_MIRROR_LOC3,
	$OCR_MIRROR_LOC4,$OCR_MIRROR_LOC5) = split (/\s*,\s*/, $ocrlocations);

    trace ("OCR_LOCATION=$OCR_LOCATION");
    trace ("OCR_MIRROR_LOCATION=$OCR_MIRROR_LOCATION");
    trace ("OCR_MIRROR_LOC3=$OCR_MIRROR_LOC3");
    trace ("OCR_MIRROR_LOC4=$OCR_MIRROR_LOC4");
    trace ("OCR_MIRROR_LOC5=$OCR_MIRROR_LOC5");
    trace ("Current OCR location= $OCRCONFIG_LOC");
    trace ("Current OCR mirror location= $OCRMIRRORCONFIG_LOC");
    trace ("Current OCR mirror loc3=$OCRCONFIG_LOC3");
    trace ("Current OCR mirror loc4=$OCRCONFIG_LOC4");
    trace ("Current OCR mirror loc5=$OCRCONFIG_LOC5");
    trace ("Verifying current OCR settings with user entered values");

    if ($OCRCONFIG_LOC) {
        if ($OCR_LOCATION ne $OCRCONFIG_LOC) {
            error ("Current Oracle Cluster Registry location " .
                   "\"$OCRCONFIG_LOC\" in \"$OCRFILE\" and " .
                   "\"$OCR_LOCATION\" do not match");
            error ("Update either \"$OCRFILE\" to use \"$OCR_LOCATION\" or " .
                   "variable OCR_LOCATIONS property set in " .
                   catfile ($crshome, "crs", "install", "crsconfig_params") .
                "with \"$OCRCONFIG_LOC\" then rerun this script");
            return $FAILED;
        }
    } else {
        #set ocrconfig_loc = OCR_LOCATION
        $OCRCONFIG_LOC = $OCR_LOCATION;
    }

    if ($OCRMIRRORCONFIG_LOC) {
        if ($OCR_MIRROR_LOCATION ne $OCRMIRRORCONFIG_LOC) {
            error ("Current Oracle Cluster Registry mirror location " .
                   "\"$OCRMIRRORCONFIG_LOC\" in \"$OCRFILE\" and " .
                   "\"$OCR_MIRROR_LOCATION\" do not match");
            error ("Update either \"$OCRFILE\" to use " .
                   "\"$OCR_MIRROR_LOCATION\" or variable OCR_LOCATIONS " .
                   "property set in " .
                   catfile ($crshome, "crs" . "install" . "crsconfig_params") .
                   " with \"$OCRMIRRORCONFIG_LOC\" then rerun this script");
            return $FAILED;
        }
    } else {
        #set the mirror location=user entered value for OCR_MIRROR_LOCATION
        $OCRMIRRORCONFIG_LOC = $OCR_MIRROR_LOCATION;
    }

    if ($OCRCONFIG_LOC3) {
        if ($OCR_MIRROR_LOC3 ne $OCRCONFIG_LOC3) {
            error ("Current Oracle Cluster Registry mirror location " .
                   "\"$OCRCONFIG_LOC3\" in \"$OCRFILE\" and " .
                   "\"$OCR_MIRROR_LOC3\" do not match");
            error ("Update either \"$OCRFILE\" to use " .
                   "\"$OCR_MIRROR_LOC3\" or variable OCR_LOCATIONS " .
                   "property set in " .
                   catfile ($crshome, "crs" . "install" . "crsconfig_params") .
                   " with \"$OCRCONFIG_LOC3\" then rerun this script");
            return $FAILED;
        }
    } else {
        #set the mirror location=user entered value for OCR_MIRROR_LOCATION
        $OCRCONFIG_LOC3 = $OCR_MIRROR_LOC3;
    }

    if ($OCRCONFIG_LOC4) {
        if ($OCR_MIRROR_LOC4 ne $OCRCONFIG_LOC4) {
            error ("Current Oracle Cluster Registry mirror location " .
                   "\"$OCRCONFIG_LOC4\" in \"$OCRFILE\" and " .
                   "\"$OCR_MIRROR_LOC4\" do not match");
            error ("Update either \"$OCRFILE\" to use " .
                   "\"$OCR_MIRROR_LOC4\" or variable OCR_LOCATIONS " .
                   "property set in " .
                   catfile ($crshome, "crs" . "install" . "crsconfig_params") .
                   " with \"$OCRCONFIG_LOC4\" then rerun this script");
            return $FAILED;
        }
    } else {
        #set the mirror location=user entered value for OCR_MIRROR_LOCATION
        $OCRCONFIG_LOC4 = $OCR_MIRROR_LOC4;
    }

    if ($OCRCONFIG_LOC5) {
        if ($OCR_MIRROR_LOC5 ne $OCRCONFIG_LOC5) {
            error ("Current Oracle Cluster Registry mirror location " .
                   "\"$OCRCONFIG_LOC5\" in \"$OCRFILE\" and " .
                   "\"$OCR_MIRROR_LOC5\" do not match");
            error ("Update either \"$OCRFILE\" to use " .
                   "\"$OCR_MIRROR_LOC5\" or variable OCR_LOCATIONS " .
                   "property set in " .
                   catfile ($crshome, "crs" . "install" . "crsconfig_params") .
                   " with \"$OCRCONFIG_LOC5\" then rerun this script");
            return $FAILED;
        }
    } else {
        #set the mirror location=user entered value for OCR_MIRROR_LOCATION
        $OCRCONFIG_LOC5 = $OCR_MIRROR_LOC5;
    }

    trace ("Setting OCR locations in $OCRCONFIG");
    s_validate_ocrconfig ($ocrlocations, 0) or (return $FAILED);

    if (-f $OCR_SYNC_FILE) {
        trace ("Removing OCR sync file: $OCR_SYNC_FILE");
        s_remove_file ("$OCR_SYNC_FILE");
    }

    return $status;
}

####---------------------------------------------------------
#### Function for invalidating srvconfig_loc in srvconfig.loc file
sub s_reset_srvconfig
{
    trace ("Invalidating repository location for Oracle 9i deployments");
    ##Invalidate the existing srvConfig.loc file if it was existing 
    if (-f $SRVCONFIG) {
        open (SRVCFGFILE, ">$SRVCONFIG") or return $FAILED;
        print SRVCFGFILE "srvconfig_loc=/dev/null\n";
        close (SRVCFGFILE);
        s_set_ownergroup ($SUPERUSER, $ORA_DBA_GROUP, $SRVCONFIG)
            or return $FAILED;
        s_set_perms ("0644", $SRVCONFIG) or return $FAILED;
    }

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for registering daemon/service with init
# ARGS: 1
# ARG1: daemon to be registered
sub s_register_service
{
    my $srv = $_[0];

    # Setup init scripts
    my $INITDIR = catfile ($ORACLE_HOME, "crs", "init");
    my $INITDIR_INITSRV = catfile ($INITDIR, "init.$srv");
    my $INITDIR_SRV = catfile ($INITDIR, $srv);
    s_copy_to_initdir ($INITDIR_INITSRV, "init.$srv") or return $FAILED;
    s_copy_to_rcdirs ($INITDIR_SRV, $srv) or return $FAILED;

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for unregistering daemon/service
# ARGS: 1
# ARG1: daemon to be unregistered
sub s_unregister_service
{
    # TBD

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for starting daemon/service
# ARGS: 3
# ARG1: daemon to be started
# ARG2: user under whom daemon/service needs to be started
sub s_start_service
{
    my $srv  = $_[0];
    my $user = $_[1];

    # Check to see if the service is OHASD
    if ($srv eq "ohasd") {

	# Create the autorun file
        my $AUTORUNFILE = catfile ($SCRBASE, $HOST, $HAS_USER, "ohasdrun");
        open (AUTORUN, ">$AUTORUNFILE")
            or die "Can't open $AUTORUNFILE for write: $!";
        print AUTORUN "stop\n";
        close (AUTORUN);
        s_set_ownergroup ($HAS_USER, $HAS_GROUP, $AUTORUNFILE)
	    or die "Can't change ownership of $AUTORUNFILE: $!";
        s_set_perms ("0644", $AUTORUNFILE)
            or die "Can't change permissions of $AUTORUNFILE: $!";

	# Add OHASD to inittab

        print "Adding daemon to inittab\n";
        s_remove_itab ("cssd|evmd|crsd|ohasd") or return $FAILED;
        system ("$INIT q");
        sleep (5);
        s_add_itab () or return $FAILED;
        system ("$INIT q");

	# Start OHASD

	$status = system ("$CRSCTL start has");
      } elsif ($srv eq "crsexcl") {
	trace ("Starting Oracle clusterware exclusive");
	# Create the autorun file
        my $AUTORUNFILE = catfile ($SCRBASE, $HOST, $HAS_USER, "ohasdrun");
        open (AUTORUN, ">$AUTORUNFILE")
            or die "Can't open $AUTORUNFILE for write: $!";
        print AUTORUN "stop\n";
        close (AUTORUN);
        s_set_ownergroup ($HAS_USER, $HAS_GROUP, $AUTORUNFILE)
	    or die "Can't change ownership of $AUTORUNFILE: $!";
        s_set_perms ("0644", $AUTORUNFILE)
            or die "Can't change permissions of $AUTORUNFILE: $!";

	# Add OHASD to inittab

        print "Adding daemon to inittab\n";
        s_remove_itab ("cssd|evmd|crsd|ohasd") or return $FAILED;
        system ("$INIT q");
        sleep (5);
        s_add_itab () or return $FAILED;
        system ("$INIT q");

	# Start OHASD

	$status = system ("$CRSCTL start crs -excl");
    } else {
        my $SRVBIN = catfile ($ORACLE_HOME, "bin", $srv);
	$status = s_run_as_user ("$SRVBIN &", $user);
    }

    if (0 == $status) {
        trace ("$srv is starting");
        print  "$srv is starting\n";
    } else {
        error ("$srv failed to start: $!");
        return $FAILED;
    }

    return $SUCCESS;
}

####---------------------------------------------------------
#### Function for stopping daemon/service
# ARGS: 2
# ARG1: daemon to be stopped
# ARG2: user under whom daemon/service needs to be stopped
sub s_stop_service
{
    # TBD

    return $SUCCESS;
}
#
####---------------------------------------------------------
#### Function for checking daemon
# ARGS: 2
# ARG1: daemon to be checked
# ARG2: is daemon running?
sub s_check_service
{
    my ($srv, $isRunning) = @_;
    if (($srv eq "ohasd") && ($isRunning)) {
        my $AUTOSTARTFILE = catfile ($SCRBASE, $HOST, $HAS_USER, "ohasdstr");
        open (AUTOSTART, ">$AUTOSTARTFILE")
            or die "Can't open $AUTOSTARTFILE for write: $!";
        print AUTOSTART "enable\n";
        close (AUTOSTART);
        s_set_ownergroup ($HAS_USER, $HAS_GROUP, $AUTOSTARTFILE)
	    or die "Can't change ownership of $AUTOSTARTFILE: $!";
        s_set_perms ("0644", $AUTOSTARTFILE)
            or die "Can't change permissions of $AUTOSTARTFILE: $!";
    }
}

####---------------------------------------------------------
#### Function for initializing SCR settings
# Note: this function will be a no-op on NT
# ARGS: 0
sub s_init_scr
{
    my $status = system ("$CRSCTL create scr $ORACLE_OWNER");
    if (0 != $status) {
        print "Failure initializing entries in " .
        catfile ($SCRBASE, $HOST) . "\n";
        exit 1;
    }
}

####---------------------------------------------------------
#### Function for running a command as given user
# ARGS: 2
# ARG1: cmd to be executed
# ARG2: user name
sub s_run_as_user
{
    my $user = $_[1];
    my $cmd;

    if ($user) {
        my $SU = "/bin/su";
        $cmd = "$SU $user -c \"$_[0]\"";
        trace ("  Invoking \"$_[0]\" as user \"$user\"");
    } else {
        $cmd = $_[0];
        trace ("  Invoking \"$_[0]\"");
    }

    return system ($cmd);
}

####---------------------------------------------------------
#### Function for running a command as given user, returning back 
#### stdout/stderra output
# ARGS: 3
# ARG1: ref to cmdlist argv list to be executed
# ARG2: user name, can be undef
# ARG3: ref to resulting array of stderr/out, can be undef
sub s_run_as_user2
{
    my $cmdlistref = $_[0];
    my $user = $_[1]; 
    my $capoutref = $_[2];
    my $rc = -1;
    my $SU = "/bin/su";
    
    my @cmdlist;
    if ($user)
    {
      @cmdlist = ( $SU, $user, '-c \'',  @{$cmdlistref}, '\'' );
    }
    else
    {
      @cmdlist = @{$cmdlistref};
    }
    my $cmd = join( ' ', @cmdlist );
    
    # capture stdout/stderr, if requested
    if (defined($capoutref))
    {
      @{$capoutref} = ();
      my $cmdout = tmpnam();

      trace ("s_run_as_user2: Running $cmd");

      # system() with stdout/stderr capture. 
      # Note that this is a portable notation in perl
      # see http://perldoc.perl.org/perlfaq8.html
      # see also
      # http://www.perlmonks.org/?node_id=597613
      open (CMDEXE, "$cmd 2>&1 |" ) 
            or die "Can't open \"$cmd\" output: $!";
      open (CMDOUT, ">>$cmdout" ) 
            or die "Can't open \"$cmd\" tee: $!";
      while (<CMDEXE>) { 
	 push( @{$capoutref}, $_ ); 
	 print CMDOUT $_; 
      }
      close (CMDEXE);  # to get $?
      $rc = $?;
      close (CMDOUT);
      s_remove_file ("$cmdout");
    }
    else  # regular system() call
    {
      $rc = s_run_as_user( $cmd, $user );
    }

    if ($rc == 0) {
        trace ("$cmdlist[0] successfully executed\n");
    }
    elsif ($rc == -1) {
        trace ("$cmdlist[0] failed to execute: $!\n");
    }
    elsif ($rc & 127) {
        trace ("$cmdlist[0]  died with signal %d, %s coredump\n",
            ($rc & 127),  ($rc & 128) ? 'with' : 'without');
    }
    else {
        trace ("$cmdlist[0] exited with rc=%d\n", $rc >> 8);
    }
    return $rc;
}

####---------------------------------------------------------
#### Function for getting value corresponding to a key in ocr.loc or olr.loc
# ARGS: 2
# ARG1: ocr/olr
# ARG2: key
sub s_get_config_key
{
    my $src = $_[0];
    my $key = $_[1];

    my $val = "";

    # $src is now OCR/OLR/SRV
    $src =~ tr/a-z/A-Z/;
    # CFGFILE is now OCRCONFIG/OLRCONFIG/SRVCONFIG
    my $CFGFILE = "${src}CONFIG";
    # open OCRCONFIG/OLRCONFIG/SRVCONFIG as appropriate
    trace("Opening file $CFGFILE");
    open (CFGFL, "<$$CFGFILE") or return $val;
    while (<CFGFL>) {
        if (/^$key=(\S+)/) {
            $val = $1;
            last;
        }
    }
    close (CFGFL);

    trace("Value ($val) is set for key=$key");
    return $val;
}

####---------------------------------------------------------
#### Function for getting platform family
# ARGS: 0
sub s_get_platform_family
{
    return "unix";
}

####---------------------------------------------------------
#### Function for checking if a path is a symlink, and if so, return the
#### target path
# ARGS: 1
# ARG1: file/dir path
sub s_isLink
{
    my $path = $_[0];
    my $target = "";

    if (-l $path) {
        $target = readlink ($path) or die "readlink failed: $!";
    }

    return $target;
}

####--------------------------------
#### Function for redirecting output
# ARGS: 1
# ARG1: file to redirect to 
sub s_redirect_souterr
{
    # no-op on Linux as we don't want to redirect output
   return $SUCCESS;
}

####---------------------------------------------------------
#### Function for restoring output
# ARGS: 0
sub s_restore_souterr
{
    # no-op on Linux
   return $SUCCESS;
}

####---------------------------------------------------------
#### Function for getting the old CRS Home
# ARGS:  0
sub s_getOldCrsHome
{
  my $oldHome;
  my $OLD_INIT_CSSD;
  my $CRS_HOME_ENV = "ORA_CRS_HOME";
  my $INITD = s_getInitd();

  $OLD_INIT_CSSD = catfile ($INITD, "init.cssd");
  open(FOHM, $OLD_INIT_CSSD) ||
    die "Could not open old init.cssd\n";
  @buffer = grep(/$CRS_HOME_ENV/, (<FOHM>));
  close FOHM;
  chomp @buffer;
  if (scalar(@buffer) != 0) {
      ($Name, $oldHome) = split(/=/, $buffer[0]);
  }
  return $oldHome;
}

####---------------------------------------------------------
#### Function to check if  the stack is up  from Pre 11.2 CrsHome
# ARGS:  1
# ARG1:  Old CRS Home Location
sub s_check_OldCrsStack
{
   trace("check old crs stack");
   my $old_crshome = $_[0];
   my @old_version = @{$CFG->oldconfig('ORA_CRS_VERSION')};
   my $crsctl      = catfile ($old_crshome, 'bin', 'crsctl');
   my $crs_stat    = catfile ($old_crshome, 'bin', 'crs_stat');

   if ($old_version[0] eq "10" &&
       $old_version[1] eq "1") {
      my @output = system_cmd_capture($crs_stat);
      my $rc     = shift @output;
      my @cmdout = grep(/CRS-0184/, @output);
      trace("rc=$rc output=@output");

      if ($rc == 0 && scalar(@cmdout) == 0) {
         return $SUCCESS;
      }
   } else {
      my $status_cssd = system_cmd($crsctl, 'check', 'cssd');
      my $status_evmd = system_cmd($crsctl, 'check', 'evmd');
      my $status_crsd = system_cmd($crsctl, 'check', 'crsd');
      if ((! $status_cssd) &&
          (! $status_evmd) &&
          (! $status_crsd)) {
         return $SUCCESS;
      }
   }

   return $FAILED;
}

####---------------------------------------------------------
####---------------------------------------------------------
#### Function for stopping the services from OldCrsHome
# ARGS:  1

sub s_stop_OldCrsStack
{
  my $OLD_INIT_CRS;
  my $INITD = s_getInitd();

  $OLD_INIT_CRS  = catfile ($INITD, "init.crs");
  $status = system("$OLD_INIT_CRS stop");
  return $status;
}
####---------------------------------------------------------
#### Function for getting the Initd locations
# ARGS:  0

sub s_getInitd
{
  return $INITD;
}

sub s_RemoveInitResources
#---------------------------------------------------------------------
# Function: Removing init resources
# Args    : 0
#---------------------------------------------------------------------
{
   my $file;
   trace ("Remove Init resources");
   trace ("Removing itab");

   s_remove_itab ("cssd|evmd|crsd|ohasd");
   system ("$INIT q");
   sleep (5);

   trace ("Removing script for Oracle Cluster Ready services");

   foreach $serv (@crs_init_scripts)
   {
     trace ("Removing $ID/$serv file");
     $file = catfile($ID,$serv);
     s_remove_file ("$file");
   }

   s_clean_rcdirs ("ohasd");
   s_clean_rcdirs ("init.crs");

} #endsub


sub s_ResetOLR
#---------------------------------------------------------------------
# Function: Reset OLR
# Args    : 0
#--------------------------------------------------------------------
{
   trace ("Reset OLR");
   my $bin_dd = "/bin/dd";

   my $olr_file = s_get_olr_file("olrconfig_loc");

   if (-f $olr_file) {
      trace("Removing OLR file: $olr_file");
      s_remove_file ("$olr_file");
   }
   else {
      trace ("Removing contents from OLR file: $olr_file");
      system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$olr_file > $dev_null");
   }

   s_remove_file ("$OLRCONFIG");
}

sub s_ResetOCR
#---------------------------------------------------------------------
# Function: Reset OCR
# Args    : 0
#--------------------------------------------------------------------
{
   trace ("Reset OCR");
   my $bin_dd = "/bin/dd";
   my ($ocr_loc, $ocr_mirror_loc, $ocr_loc3, $ocr_loc4, $ocr_loc5);

   if ($g_downgrade)
   {
      if ($g_version eq "9.2")
      {
         DowngradeTo9i ();
      } else {
         DowngradeTo10or11i ();
      }

      return $SUCCESS;
   }

   my $olr_file = s_get_olr_file("olrconfig_loc");

   if (-f $olr_file) {
      trace("Removing OLR file: $olr_file");
      s_remove_file ("$olr_file");
   }
   else {
      trace ("Removing contents from OLR file: $olr_file");
      system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$olr_file > $dev_null");
   }

   s_remove_file ("$OLRCONFIG");

   if (! $g_lastnode) 
   {
      s_remove_file ("$OCRCONFIG");
      return $SUCCESS;
   }

   if (! -f $OCRCONFIG) 
   {
      # ocr.loc file does not exist. Take ocr location of srvconfig.loc for setting
      # file permissions
      if (-f $SRVCONFIG) 
      {
         $ocr_loc =  get_srvdisk ();
      }
   } 
   else {
      $ocr_loc = get_ocrdisk ();
      $ocr_mirror_loc = get_ocrmirrordisk ();
      $ocr_loc3 = get_ocrloc3disk ();
      $ocr_loc4 = get_ocrloc4disk ();
      $ocr_loc5 = get_ocrloc5disk ();
   }

   if (($ocr_mirror_loc) and ($ocr_mirror_loc ne $dev_null)) {
      # OCR mirror device is specified and enabled
      if (-f $ocr_mirror_loc) {
         trace("Removing OCR mirror device: $ocr_mirror_loc");
         s_remove_file ("$ocr_mirror_loc");
      }
      elsif (!isPathonASM($ocr_mirror_loc)) {
         trace ("Removing contents from OCR mirror device: $ocr_mirror_loc");
         system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$ocr_mirror_loc > $dev_null");
      }
   }

   if (($ocr_loc3) and ($ocr_loc3 ne $dev_null)) {
      # OCR mirror device 3 is specified and enabled
      if (-f $ocr_loc3) {
         trace("Removing OCR mirror device 3: $ocr_loc3");
         s_remove_file ("$ocr_loc3");
      }
      elsif (!isPathonASM($ocr_loc3)) {
         trace ("Removing contents from OCR mirror device 3: $ocr_loc3");
         system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$ocr_loc3 > $dev_null");
      }
   }

   if (($ocr_loc4) and ($ocr_loc4 ne $dev_null)) {
      # OCR mirror device 4 is specified and enabled
      if (-f $ocr_loc4) {
         trace("Removing OCR mirror device 4: $ocr_loc4");
         s_remove_file ("$ocr_loc4");
      }
      elsif (!isPathonASM($ocr_loc4)) {
         trace ("Removing contents from OCR mirror device 4: $ocr_loc4");
         system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$ocr_loc4 > $dev_null");
      }
   }

   if (($ocr_loc5) and ($ocr_loc5 ne $dev_null)) {
      # OCR mirror device 5 is specified and enabled
      if (-f $ocr_loc5) {
         trace("Removing OCR mirror device 5: $ocr_loc5");
         s_remove_file ("$ocr_loc5");
      }
      elsif (!isPathonASM($ocr_loc5)) {
         trace ("Removing contents from OCR mirror device 5: $ocr_loc5");
         system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$ocr_loc5 > $dev_null");
      }
   }

   # reset OCR device if it's not on ASM
   if (($g_lastnode)    &&
       (! $g_downgrade) &&
       (! $CFG->ASM_STORAGE_USED)) {
      trace ("Removing contents from OCR device");

      if (-f $ocr_loc) {
         trace("Removing OCR device: $ocr_loc");
         s_remove_file ("$ocr_loc");
      }
      elsif (!isPathonASM($ocr_loc)) {
         trace ("Removing contents from OCR device: $ocr_loc");
         system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$ocr_loc > $dev_null");
      }
   }

   #remove the ocr.loc in the lastnode in case of ASM storage as well
   if ($g_lastnode) {
      s_remove_file ("$OCRCONFIG");
   }
   
   # reset permissions of ocr_loc files
   if (-f $ocr_loc)
   {
      chmod(0644, $ocr_loc);
      if ($valid_owner)
      {
         chown ($ORACLE_OWNER, $ocr_loc);
      }

      if ($valid_group)
      {
         system ("$cmd_chgrp $ORA_DBA_GROUP $ocr_loc");
      }
   }

   if ((not -z $ocr_mirror_loc) and (-f $ocr_mirror_loc))
   {
      chmod(0644, $ocr_mirror_loc);

      if ($valid_owner)
      {
         chown ($ORACLE_OWNER, $ocr_mirror_loc);
      }

      if ($valid_group)
      {
         system ("$cmd_chgrp $ORA_DBA_GROUP $ocr_mirror_loc");
      }
   }

   if ((not -z $ocr_loc3) and (-f $ocr_loc3))
   {
      chmod(0644, $ocr_loc3);

      if ($valid_owner)
      {
         chown ($ORACLE_OWNER, $ocr_loc3);
      }

      if ($valid_group)
      {
         system ("$cmd_chgrp $ORA_DBA_GROUP $ocr_loc3");
      }
   }

   if ((not -z $ocr_loc4) and (-f $ocr_loc4))
   {
      chmod(0644, $ocr_loc4);

      if ($valid_owner)
      {
         chown ($ORACLE_OWNER, $ocr_loc4);
      }

      if ($valid_group)
      {
         system ("$cmd_chgrp $ORA_DBA_GROUP $ocr_loc4");
      }
   }

   if ((not -z $ocr_loc5) and (-f $ocr_loc5))
   {
      chmod(0644, $ocr_loc5);

      if ($valid_owner)
      {
         chown ($ORACLE_OWNER, $ocr_loc5);
      }

      if ($valid_group)
      {
         system ("$cmd_chgrp $ORA_DBA_GROUP $ocr_loc5");
      }
   }
} #endsub

sub s_setParentDirOwner
#-------------------------------------------------------------------------------
# Function: Set $current_dir and its parent directories to $owner/DBA
#
# Args    : [0] Owner
#           [1] Directory
#-------------------------------------------------------------------------------
{
   my $current_owner = $_[0];
   my $current_dir = $_[1];
   my $dir = dirname($current_dir);

   while ($dir ne "/")
   {
      s_set_ownergroup ($current_owner, $ORA_DBA_GROUP, $dir)
           or die "Can't change ownership on $dir: $!";
      s_set_perms ("0755", $dir);
      $dir = dirname($dir);
   }
}

sub s_start_ocfs_driver
{
    # no-op on Linux
    return $SUCCESS;
}
sub s_ResetVotedisks
#-------------------------------------------------------------------------------
# Function: Reset voting disks
#
# Args    : [0] list of voting disks
#-------------------------------------------------------------------------------
{
   trace ("Reset voting disks");
   my @votedisk_list = @_;
   trace ("CRS_STORAGE_OPTION is $CRS_STORAGE_OPTION");
   foreach my $vdisk (@votedisk_list) {
      if ($CRS_STORAGE_OPTION != 1) {
         # OCFS
         if (-f $vdisk) {
            trace("Removing voting disk: $vdisk");
            s_remove_file ("$vdisk");
         }
         else {
            trace ("Removing contents from voting disk: $vdisk");
            my $bin_dd = "/bin/dd";
            system ("$bin_dd if=/dev/zero skip=25 bs=4k count=2560 of=$vdisk > $dev_null");
         }
      }
   }
}

sub s_CleanTempFiles
#-------------------------------------------------------------------------------
# Function: Remove misc files and directories
# Args    : none
#-------------------------------------------------------------------------------
{
   my ($dir, $file);

   # remove /etc/init.d/ohasd
   my $initd = s_getInitd();
   $file  = (catfile ($initd, "ohasd"));
   s_remove_file ("$file");

   # remove /var/tmp/.oracle
   $dir = catdir ("/var", "tmp", ".oracle");
   if (-e $dir) {
      trace ("Remove $dir");
      rmtree ($dir);
   }

   # remove /ect/inittab.crs
   $file = catfile ("/etc", "inittab.crs");
   s_remove_file ("$file");

   # remove /ect/oratab
   if ($CFG->defined_param('HOME_TYPE')) {
      $file = catfile ("/etc", "oratab");
      s_remove_file ("$file");
   }

   # remove /tmp/.oracle
   $dir = catdir ("/tmp", ".oracle");
   if (-e $dir) {
      trace ("Remove $dir");
      rmtree ($dir);
   }

   # remove /etc/oracle if empty
   if (-e $OCRCONFIGDIR) {
      # check if it's empty
      opendir (DIR, $OCRCONFIGDIR);
      my @files = readdir(DIR);
      close DIR;

      if (scalar(@files) == 2) {
         trace ("Remove $OCRCONFIGDIR");
         rmtree $OCRCONFIGDIR;
      }
   }
}

sub s_checkOracleCM
#-------------------------------------------------------------------------------
# Function: Check for OracleCM by checking libskgxn on unix.
#
# Args    : none
#
# Return  : TRUE - if found
#-------------------------------------------------------------------------------
{
   my $false = 0;
   my $true  = 1;
   my $libskgxnBase_lib = catfile('/etc', 'ORCLcluster', 'oracm', 'lib', 'libskgxn2.so');
   my $libskgxn_lib = catfile('/opt', 'ORCLcluster', 'lib', 'libskgxn2.so');

   trace("libskgxnBase_lib = $libskgxnBase_lib");
   trace("libskgxn_lib = $libskgxn_lib");
   if ((-e $libskgxn_lib) || (-e $libskgxnBase_lib)) {
      # no SKGXN;
      trace("SKGXN library file exists");
      return $true;
   }

   trace("SKGXN library file does not exists");
   return $false;
}

sub s_createConfigEnvFile
#---------------------------------------------------------------------
# Function: Create s_crsconfig_$HOST_env.txt file for Time Zone
# Args    : none
# Notes   : Valid <env_file> format
#           (Please keep this in sync with has/utl/crswrapexec.pl)
#             * Empty lines: lines with all white space
#             * Comments: line starts with #.
#             * <key>=<value>
#             * <key> is all non-whitespace characters on the left of the
#               first "=" character.
#             * <value> is everything on the right of the first "=" character
#               (including whitespaces).
#             * Surrounding double-quote (") won't be stripped.
#             * Key with blank <value> ('') will be undefined.
#               (e.g: Hello=, Hello will be undefined)
#---------------------------------------------------------------------
{
   my $env_file = catfile($ORA_CRS_HOME, 'crs', 'install',
                          's_crsconfig_' . $HOST . '_env.txt');

   open (ENVFILE, ">$env_file") or die "Can't create $env_file: $!";

   print ENVFILE "### This file can be used to modify the NLS_LANG environment"
               . " variable, which determines the charset to be used for messages.\n"
               . "### For example, a new charset can be configured by setting"
               . " NLS_LANG=JAPANESE_JAPAN.UTF8 \n"
               . "### Do not modify this file except to change NLS_LANG,"
               . " or under the direction of Oracle Support Services\n\n";

   ## Extract TZ value from ORACLE_OWNER
   # Note:  - Eventually the Install team would implement this and give us %TZ%
   #        in the param file.
   my @envvars = `su - $ORACLE_OWNER -c '$ENVMT' < /dev/null`;
   my $tz_entry = (grep { /^TZ=/ } @envvars)[0];
   # Print to env file only if TZ is defined. 
   print ENVFILE $tz_entry if (defined $tz_entry);

   # get NLS_LANG
   if ($CFG->defined_param('LANGUAGE_ID')) {
      my $nls_lang = $CFG->params('LANGUAGE_ID');
      $nls_lang =~ s/'//g; # remove single quotes
      print ENVFILE "NLS_LANG=" . $nls_lang . "\n";
   }

   # Make sure that env var TNS_ADMIN and ORACLE_BASE will be unset.
   print ENVFILE "TNS_ADMIN=\n";
   print ENVFILE "ORACLE_BASE=\n";

   close (ENVFILE);

   s_set_ownergroup ($SUPERUSER, $ORA_DBA_GROUP, $env_file)
                or die "Can't set ownership on $env_file: $!";
   s_set_perms ("0750", $env_file);
}

sub s_isRAC_appropriate
#-------------------------------------------------------------------------------
# Function:  Check if rac_on/rac_off on Unix
# Args    :  none
# Returns :  TRUE  if rac_on/rac_off     needs to be set
#            FALSE if rac_on/rac_off not needs to be set
#-------------------------------------------------------------------------------
{
   my $rdbms_lib = catfile($CFG->ORA_CRS_HOME, "rdbms", "lib");
   my $success   = TRUE;

   # save current dir
   my $save_dir = getcwd;

   # check for rac_on
   chdir $rdbms_lib;

   my $cmd = "$ARCHIVE -tv libknlopt.a | grep kcsm";

   open ON, "$cmd |";
   my @kcsm = (<ON>);
   close ON;

   if (scalar(@kcsm) == 0) {
      if (! $CFG->IS_SIHA) {
         $success = FALSE;
         print " \n";
         print "The oracle binary is currently linked with RAC disabled.\n";
         print "Please execute the following steps to relink oracle binary\n";
         print "and rerun the command with RAC enabled: \n";
         print "   cd <crshome> \n";
         print "   setenv ORACLE_HOME pwd \n";
         print "   cd rdbms/lib \n";
         print "   make -f ins_rdbms.mk rac_on ioracle \n";
      }
   }
   elsif ($CFG->IS_SIHA) {
      $success = FALSE;
      print " \n";
      print "The oracle binary is currently linked with RAC enabled.\n";
      print "Please execute the following steps to relink oracle binary\n";
      print "and rerun the command with RAC disabled: \n";
      print "   cd <crshome> \n";
      print "   setenv ORACLE_HOME pwd \n";
      print "   cd rdbms/lib \n";
      print "   make -f ins_rdbms.mk rac_off ioracle \n";
   }

   # restore save_dir
   chdir $save_dir;

   return $success;
}

sub s_configureCvuRpm
#------------------------------------------------------------------------------
# Function:  Install cvuqdisk rpm on Linux
# Args    :  none
#-------------------------------------------------------------------------------
{
    my $uname =`uname`;
    chomp($uname);

    if ($uname=~/Linux/)
    {
       trace ("Install cvuqdisk rpm on Linux...");
       my $rmpexe = "/bin/rpm";
       my $install_cvuqdisk=FALSE;
       my $rpm_pkg_dir;
       my $rpm_file;

       if (is_dev_env())
       {
          $rpm_pkg_dir=catfile($ORA_CRS_HOME,'opsm','cv','remenv');
       }
       else
       {
          $rpm_pkg_dir=catfile($ORA_CRS_HOME,'cv', 'rpm');
       }

       opendir (DIR, $rpm_pkg_dir);
       foreach (sort grep(/cvuqdisk/,readdir(DIR)))
       {
           $rpm_file = $_;
       }
       closedir DIR;

       my $new_rpm_file = $rpm_pkg_dir . "/" . $rpm_file;
       trace ("New package to install is $new_rpm_file");

       trace ("Invoking \"$rmpexe -q cvuqdisk\" command");
       my $curr_rpm_version = `$rmpexe -q cvuqdisk --queryformat '%{VERSION}'`;
       my $status = $?;

       if ($status == 0) 
       {
          my $curr_rpm_release = `$rmpexe -q cvuqdisk --queryformat '%{RELEASE}'`;

          trace ("Invoking \"$rmpexe -qp $new_rpm_file\" command");
          my $new_rpm_version = `$rmpexe -qp $new_rpm_file --queryformat '%{VERSION}'`;
          my $new_rpm_release = `$rmpexe -qp $new_rpm_file --queryformat '%{RELEASE}'`;

          chomp ($curr_rpm_version);
          chomp ($new_rpm_version);
          chomp ($curr_rpm_release);
          chomp ($new_rpm_release);

          if ($curr_rpm_version eq "package cvuqdisk is not installed")
          {
              trace ("package is not installed");
              $install_cvuqdisk = TRUE;
          }
          else
          {
              trace ("check package versions new = [$new_rpm_version];old=[$curr_rpm_version] ");
              my $i;
              my @currPkgArr = split(/\./, $curr_rpm_version);
              my @newPkgArr = split(/\./, $new_rpm_version);
              my $loopMax = (scalar @currPkgArr <= scalar @newPkgArr)?scalar @currPkgArr:scalar @newPkgArr;
              my $currentConfigGood = FALSE;

              for ($i=0;$i<$loopMax;$i++) {
                 if ($currPkgArr[$i] == $newPkgArr[$i])
                 {
                    next;
                 }
                 if ($currPkgArr[$i]  > $newPkgArr[$i])
                 {
                    $currentConfigGood = TRUE;
                    last;
                 }
                 trace ("install new package for version");
                 $install_cvuqdisk = TRUE;
                 last;
              }

              if (!$currentConfigGood && !$install_cvuqdisk && ($curr_rpm_release lt $new_rpm_release))
              {
                  trace ("install new package for release");
                  $install_cvuqdisk = TRUE;
              }
          }
       }
       else
       {
           trace ("no existing cvuqdisk found");
           $install_cvuqdisk = TRUE;
       }

       if ($install_cvuqdisk)
       {
          my $orauser  = $CFG->params('ORACLE_OWNER');
          my $CVUQDISK_GRP=`id -gn $orauser`;
          chomp($CVUQDISK_GRP);
          $ENV{'CVUQDISK_GRP'} = $CVUQDISK_GRP;

          trace ("removing old rpm");
          system ("$rmpexe -e --allmatches cvuqdisk 2>/dev/null");
          if ( $? == 1)
          {
              trace ("Older version cvuqdisk not uninstalled");
          }

          trace ("installing/upgrading new rpm");
          system ("$rmpexe -Uv $new_rpm_file");
       }
    }
    return TRUE;
}

sub s_removeCvuRpm
#---------------------------------------------------------------------
# Function: Remove cvuqdisk rpm
# Args    : None
#---------------------------------------------------------------------
{
    my $uname =`uname`;
    chomp($uname);

    if ($uname=~/Linux/)
    {
       trace ("removing cvuqdisk rpm");
       system ("/bin/rpm -e --allmatches cvuqdisk");
    }
    return TRUE;
}

sub s_createLocalOnlyOCR
#-------------------------------------------------------------------------------
# Function:  Create local-only OCR
# Args    :  none
#-------------------------------------------------------------------------------
{
   trace ("create Local Only OCR on Linux...");

   my $owner      = $CFG->params('ORACLE_OWNER');
   my $dba_group  = $CFG->params('ORA_DBA_GROUP');
   my $ocr_config = $CFG->params('OCRCONFIG');

   # create ocr.loc w/ local_only=TRUE and set ownergroup
   open (FILEHDL, ">$ocr_config") or die "Unable to open $ocr_config: $!";
   print FILEHDL "local_only=TRUE\n";
   close (FILEHDL);
   s_set_ownergroup ($owner, $dba_group, $ocr_config)
                or die "Can't change ownership on $ocr_config: $!";
   s_set_perms ("0640", $ocr_config)
    		or die "Can't set permissions on $ocr_config: $!";
}

sub s_houseCleaning
#-------------------------------------------------------------------------------
# Function:  Remove entries from inittab and misc files
# Args    :  none
#-------------------------------------------------------------------------------
{
   # remove cssd/evmd/crsd entries from inittab
   s_remove_itab ("cssd|evmd|crsd");

   # remove /etc/init.d/init.crs
   my $file = catfile ($CFG->params("ID"), 'init.crs');
   if (-f $file) {
      trace ("remove $file");
      s_remove_file ("$file");
   }

   # remove /etc/init.d/init.crsd
   $file = catfile ($CFG->params("ID"), 'init.crsd');
   if (-f $file) {
      trace ("remove $file");
      s_remove_file ("$file");
   }

   # remove /etc/init.d/init.cssd
   $file = catfile ($CFG->params("ID"), 'init.cssd');
   if (-f $file) {
      trace ("remove $file");
      s_remove_file ("$file");
   }

   # remove /etc/init.d/init.evmd
   $file = catfile ($CFG->params("ID"), 'init.evmd');
   if (-f $file) {
      trace ("remove $file");
      s_remove_file ("$file");
   }

   # remove S96init.crs files
   my $search_dir = catdir ('/etc', 'rc.d');
   my $delete_file = "s96init.crs";

   finddepth (\&remove_file, $search_dir);

   # remove K96init.crs files
   $delete_file = "k96init.crs";

   finddepth (\&remove_file, $search_dir);

   # remove K19init.crs files
   $delete_file = "k19init.crs";

   finddepth (\&remove_file, $search_dir);

   sub remove_file {
      if (/\b$delete_file\b/i) {
         trace ("remove $File::Find::name");
         s_remove_file ("$_");
      }
   }
}

sub s_is92ConfigExists
#-------------------------------------------------------------------------------
# Function: Check if config exists in 9.2
# Args    : none
# Returns : TRUE  if     exists
# 	    FALSE if not exists
#-------------------------------------------------------------------------------
{
   my $srvconfig_loc;

   trace("SRVCONFIG=$SRVCONFIG");

   if (-f $SRVCONFIG) {
      trace ("Checking repository used for 9i installations");
      $srvconfig_loc = s_get_config_key ("srv", "srvconfig_loc");

      trace("srvconfig location=<$srvconfig_loc>");

      if ($srvconfig_loc eq '/dev/null') {
          trace("srvconfig location=<$srvconfig_loc>");
          trace("Oracle 92 configuration and SKGXN library does exists");
          return TRUE;
      }
   }

   trace("Oracle 92 configuration and SKGXN library does not exists");

   return FALSE;
}

sub s_copyOCRLoc
{
   my $cluutil 	   = catfile ($CFG->ORA_CRS_HOME, 'bin', 'cluutil');
   my $ocrloc_temp = catfile ($CFG->ORA_CRS_HOME, 'srvm', 'admin', 'ocrloc.tmp');
   my $ocrloc_file = catfile ($CFG->ORA_CRS_HOME, 'srvm', 'admin', $OCRLOC);
   my @node_list   = getCurrentNodenameList();
   my $success	   = FALSE;
   my @capout	   = ();
   my @cmd;
   my $rc;

   if (! (-e $cluutil)) {
      trace("$cluutil not found");
      trace("Unable to copy OCR locations");
      return FALSE;
   }

   foreach my $node (@node_list) {
      if ($node !~ /\b$HOST\b/i) {
         @cmd = ("$cluutil", '-sourcefile', $OCRCONFIG, '-sourcenode', $node,
              '-destfile', $ocrloc_temp, '-nodelist', $node);
         $rc = run_as_user2($CFG->params('ORACLE_OWNER'), \@capout, @cmd);

         if ($rc == 0) {
            trace("@cmd ... passed");
	    $success = TRUE;
	    last;
         }
         else {
            trace("@cmd ... failed");
	    if (scalar(@capout) > 0) {
	    trace("capout=@capout");
 	    }
         }
      }
      else {
         trace("Avoiding self copy of ocr.loc on node: $node");
      }
   }

   if ($success) {
      rename ($ocrloc_temp, $ocrloc_file);
   } else {
      print "@cmd ... failed\n";
      s_remove_file ("$ocrloc_temp");
   }

   return $success;
}

sub s_removeGPnPprofile
#-------------------------------------------------------------------------------
# Function: Remove all contents under $crshome/gpnp dir
# Args    : none
#-------------------------------------------------------------------------------
{
   my $dir = catdir($CFG->ORA_CRS_HOME, 'gpnp');

   # read dir contents
   opendir (DIR, $dir);
   my @files = readdir(DIR);
   close DIR;

   foreach $file (@files) {
      if ($file eq '.' || $file eq '..') {
         next;
      }
      elsif (-f "$dir/$file") {
         trace ("remove file=$dir/$file");
         s_remove_file ("$dir/$file");
      }
      elsif (-d "$dir/$file") {
         trace ("rmtree dir=$dir/$file");
         rmtree ("$dir/$file");
      }
   }
}

sub s_remove_file
{
   my $remfile = $_[0];

   if (-e $remfile || -l $remfile) {
      my @args = ("rm", $remfile);

      trace("Removing file $remfile");
      my @out = s_system_cmd_capture2(@args);
      my $rc  = shift @out;

      if ($rc == 0) {
         trace("Successfully removed file: $remfile");
      }
      else {
         trace("Failed to remove file: $remfile");
      }
   }
   else {
      trace("$remfile not exists");
   }
}

sub s_system_cmd_capture2 {

  my $rc = 0;
  my @output;

  @output = `@_ 2>&1`;
  $rc = $? >> 8;

  if (($rc != 1) && ($rc & 127)) {
    # program returned error code
    my $sig = $rc & 127;
    trace("Failure with return code $sig from command: @_");
  }
  elsif ($rc) { 
    trace("Failure with return code $rc from command @_"); 
  }

  if ($DEBUG) { trace("@output"); }

  return ($rc, @output);
}

sub s_crf_check_bdbloc
{
  my $bdbloc = $_[0];

  # check whether bdb path starts with "/"
  my $str = substr($bdbloc, 0, 1);
  if ($str ne $FSSEP)
  {
    trace("ERROR: Invalid BDB location. Please provide absolute path.\n");
    return 1;
  }

  # check for existence first
  if (! -d $bdbloc)
  {
    trace("\n");
    trace("ERROR: BDB path $bdbloc does not exist.\n");
    trace("Please rerun with a valid storage location for BDB.\n");
    trace("The location should be a path on a volume with at least\n");
    trace("2GB per node space available and writable by root only.\n");
    trace("It is recommended to not create it on root filesystem.\n");
    trace("\n");
    return 14;
  }

  if (! -w $bdbloc)
  {
    trace("ERROR: BDB path $bdbloc is not writable, changing ");
    trace("permissions on it...\n");
    chmod oct('0755'),"$bdbloc";
  }

  # check for space now. df reports 1K blocks. Check for 2GB per node.
  # I think solaris df reports 512byte blocks. XXXXXX TODO
  my $rqrd;
  my $nodelist = $_[1];

  chomp($nodelist);
  my @hosts = split(/[,]+/, $nodelist);
  
  $rqrd = (@hosts)*2*1024*1024;

  if (open(DFH, "$df $bdbloc 2>/dev/null |"))
  {
    my $fulline="";
    while (<DFH>)
    {
      chomp();
      if (!($_ =~ m/Filesystem.*/i))
      {
        $fulline .= $_;
      }
    }
    close DFH;
    my @parts = split(/[ \n]+/, $fulline);
    my $avl = $parts[3];
    my $fsroot = $parts[5];
    if (open(MNTS, "</proc/mounts"))
    {
      while (<MNTS>)
      {
        chomp();
        my @fsmparts = split(/[ ]+/, $_);
        if ($fsmparts[1] eq $fsroot)
        {
          if (($fsmparts[2] eq "nfs") or ($fsmparts[2] eq "ocfs") or
              ($fsmparts[2] eq "ocfs2"))
          {
            trace("\n");
            trace("ERROR: BDB path MUST not lie on a shared filesystem.\n");
            trace("       Please recreate BDB directory on a local FS and\n");
            trace("       rerun the installer with that path.\n");
            trace("\n");
            return 18;
          }
          last;
        }
      }
      close MNTS;
    }
    else
    {
      trace("\n");
      trace("ERROR: Can't find mount points on this node.\n");
      trace("       Make sure /proc is mounted and rerun the installer.\n");
      trace("\n");
      return 19;
    }
    if ($avl < $rqrd)
    {
      trace("\n");
      trace("ERROR: Enough space not available on $bdbloc.\n");
      trace("Space available $avl KB, but required $rqrd KB\n");
      trace("Please rerun with a valid storage location for BDB.\n");
      trace("The location should be a path on a volume with at least\n");
      trace("2GB per node space available and writable by root only.\n");
      trace("It is recommended to not create it on root filesystem.\n");
      trace("\n");
      return 13;
    }
  }
}

sub s_crf_remove_itab
{
  trace("Removing /etc/init.d/init.crfd");
  unlink("/etc/init.d/init.crfd");

  # cleanup from the auto startup configuration
  s_remove_itab ("crfd");
  system ("$INIT q");
}

1;
