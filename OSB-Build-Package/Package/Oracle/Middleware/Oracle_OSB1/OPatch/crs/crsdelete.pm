#!/usr//bin/perl
#
# crsdelete.pm
#
# Copyright (c) 2007, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#       crsdelete.pm - root deconfig perl module.
#
#    DESCRIPTION
#       crsdelete.pm - root deconfig script for Oracle Clusterware.
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    dpham       09/22/09 - XbranchMerge dpham_bug-8889417 from
#                           st_has_11.2.0.1.0
#    dpham       06/19/09 - Change 'start clusterware' to 'start crs'
#    dpham       06/15/09 - Remove $oracle_base/oradiag_root dir if exists
#    dpham       06/11/09 - Not remove GPnP (bug 8585377)
#    dpham       06/05/09 - Fix ACFS-9129 during deconfigure
#                         - Add removeACFSRoot, ACFSState
#    dpham       05/20/09 - Call s_removeGPnPProfile to remove GPnP dir
#    yizhang     05/01/09 - fix bug 8440178
#    ksviswan    04/15/09 - XbranchMerge ksviswan_rootmisc_fixes from
#                           st_has_11.2beta2
#    ksviswan    04/14/09 - Don't stop ohasd in case of ocr/vdsk on asm
#    ksviswan    04/09/09 - XbranchMerge ksviswan_bug-8408487 from
#                           st_has_11.2beta2
#    dpham       04/08/09 - XbranchMerge dpham_bug-8412144 from main
#    ksviswan    04/07/09 - Temp Fix for bug 8408487.
#    dpham       04/07/09 - Move checkServiceDown to crsconfig_lib.pm module
#    dpham       03/30/09 - Use $CFG->HOST instead of call GetLocalNode
#    spavan      03/27/09 - install cvuqdisk rpm as part of root
#    dpham       03/27/09 - Change "stop clusterware" to "stop crs"
#    dpham       03/23/09 - Add checkServiceDown to check for service
#    dpham       03/17/09 - Fix "successfully" typo.
#    dpham       03/12/09 - Remove ora.registry.acfs resource after the node
#			    is de-configured
#    agraves     03/12/09 - Move usm_root to acfsroot.
#    dpham       03/11/09 - Fix isACFSSupported
#    dpham       02/11/09 - Nodeapps should be removed only if lastnode. 
#                           Otherwise, remove VIP.
#    dpham       02/09/09 - Add deconfigure_ASM
#    dpham       01/29/09 - Add RemoveVIP and RemoveACFS
#    dpham       01/26/09 - Add reset permission on OCR locations.
#    jleys       11/28/08 - Add missing use statement
#    ksviswan    11/19/08 - Support SIHA deconfig
#    dpham       10/22/08 - Call ExtractVotedisks, s_ResetVotedisks, s_CleanTempFiles
#    lmortime    08/28/08 - Bug 7279735 - Making "cluster" primary and
#                           "clusterware" an alias
#    khsingh     08/04/08 - use rmtree, add reset_crshome, and remove olr
#    khsingh     07/31/08 - fix deconfiguration issues
#    jgrout      05/21/08 - Realign crsctl commands, fix check_service
#    dpham       04/28/08 - Creation
#

use English;
use File::Copy;
use File::Path;
use strict;
no strict "vars";


sub TraceOptions
{
   my $options;

   if ($g_downgrade)
   {
      $options = $options . "-downgrade ";
   }

   if ($g_force)
   {
      $options = $options . "-force ";
   }

   if ($g_lastnode)
   {
      $options = $options . "-lastnode ";
   }

   if ($options) 
   {
      trace ("options=$options");
   }
}


sub ValidateSRVCTL
{
   # Validate system command
   trace ("Validate srvctl command");
   my $srvctl_exists = ValidateCommand ($SRVCTL);

   if (! $srvctl_exists) 
   {
      if ($g_force) 
      {
         return $SUCCESS;
      } 
      else 
      {
	 error ("$SRVCTL does not exist to proceed with deconfiguration. Use -force option to force deconfiguration");
         return $FAILED;
      }
   }

   return $SUCCESS;

} #endsub


sub ValidateCRSCTL
{
   # Validate system command
   trace ("Validate crsctl command");
   my $crsctl_exists = ValidateCommand ($CRSCTL);

   if (! $crsctl_exists)
   {
      if ($g_force)
      {
         return $SUCCESS;
      } 
      else 
      {
         error ("$CRSCTL does not exist to proceed with deconfiguration. Use -force option to force deconfiguration");
         return $FAILED;
      }
   }

   return $SUCCESS;

} #endsub


sub removeListeners
{
   trace ("Remove listener resource...");

   my $force;
   if ($g_force) {
      $force = "-f";
   }

   # Verify listener resources when deconfiguring last node in the cluster
   # Listener resource are local resources
   my @out = system_cmd_capture ($SRVCTL, 'config', 'listener');
   my $rc  = shift @out;

   if ($rc == 0) {
      print "CRS resources for listeners are still configured\n";
      trace  ("$SRVCTL remove listener -a $force");
      system ("$SRVCTL remove listener -a $force");

      if ($CHILD_ERROR != 0) {
         if ($g_force) {
            print "Failed to remove database listener,\n";
            print "but continuing to deconfigure with force\n";
         } else {
            print "Failed to remove database listener.\n";
            return $FAILED;
         }
      }
   }

   return $SUCCESS;

} #endsub

sub VerifyASMProxy
{
   return $SUCCESS;
}

sub VerifyDatabases
{
  return $SUCCESS;
}

sub VerifyResources
#---------------------------------------------------------------------
# Function: Verify resources (db, lsnr, asm) 
# Args    : 0
#---------------------------------------------------------------------
{
   trace ("Verifying the existence of CRS resources used by Oracle RAC databases");

   my $node_name = $CFG->HOST;

   # Check if CRS is running
   trace ("check_service cluster");
   my $crs_running = check_service ("cluster", 2);

   if (! $crs_running) 
   {
      if ($g_force) 
      {
         return $SUCCESS;
      } else {
	 print "Oracle Clusterware stack is not active on this node\n";
	 error ("Restart the clusterware stack (use $CRSCTL start crs) and retry");
         return $FAILED;
      }
   }

   # Validate system command
   ValidateSRVCTL || return $FAILED;

   if ($g_lastnode)
   {
      removeListeners () || return $FAILED;
 
      VerifyASMProxy () || return $FAILED;
   }

   VerifyDatabases () || return $FAILED;

} #endsub


sub VerifyHAResources
#---------------------------------------------------------------------
# Function: Verify resources (db, lsnr, asm)
# Args    : 0
#---------------------------------------------------------------------
{
   trace ("Verifying the existence of SIHA resources used by Oracle databases");

   my $node_name = $CFG->HOST;

   # Check if SIHA is running
   trace ("check_service SIHA");
   my $siha_running = check_service ("ohasd", 2);

   if (! $siha_running)
   {
      if ($g_force)
      {
         return $SUCCESS;
      } else {
         print "Oracle Restart stack is not active on this node\n";
         error ("Restart the SIHA stack (use $CRSCTL start has) and retry");
         return $FAILED;
      }
   }

   # Validate system command
   ValidateSRVCTL () || return $FAILED;

   removeListeners () || return $FAILED;

   VerifyDatabases () || return $FAILED;

} #endsub

sub GetDBInst
#---------------------------------------------------------------------
# Function: Get database instances.
# Args    : 2
#---------------------------------------------------------------------
{
   my $node_name = $_[0];

   trace ("Get database instances for node $node_name");

   # Validate system command
   ValidateSRVCTL () || return $FAILED;

   trace ("$SRVCTL config database");
   open (SRVCTL_OUT, "$SRVCTL config database");
   my @config_db_out = <SRVCTL_OUT>;
   close (SRVCTL_OUT);

   foreach my $line (@config_db_out) 
   {
      chomp($line);
      if ($line =~ $node_name) 
      {
         my @word = split(/ /, $line);
         push (@db_inst_list, $word[1]);
      }
   }
   return(@db_inst_list);

   trace ("database instance list = @db_inst_list");
} #endsub


sub RemoveResources
#---------------------------------------------------------------------
# Function: Remove nodeapps
# Args    : 0
#---------------------------------------------------------------------
{
   trace ("Remove Resources");

   # Validate system command
   ValidateSRVCTL || return $FAILED;

   if ($g_lastnode) {
      RemoveOC4JResource ();
      RemoveScan ();
   }

   RemoveNodeApps ();

} #endsub


sub RemoveHAResources
#---------------------------------------------------------------------
# Function: Remove HA application resources
# Args    : 0
#---------------------------------------------------------------------
{
   trace ("Remove High Availability resources...");

   # Validate system command
   ValidateSRVCTL () || return $FAILED;

   my $force;
   if ($g_force) {
      $force = "-f";
   }

   # remove ONS
   my @out = system_cmd_capture ($SRVCTL, 'config', 'ons');
   my $rc  = shift @out;

   if ($rc == 0) {
      trace  ("$SRVCTL stop ons $force");
      system ("$SRVCTL stop ons $force");

      trace  ("$SRVCTL remove ons $force");
      system ("$SRVCTL remove ons $force");
   }

   # remove eONS
   @out = system_cmd_capture ($SRVCTL, 'config', 'eons');
   $rc  = shift @out;

   if ($rc == 0) {
      trace  ("$SRVCTL stop eons $force");
      system ("$SRVCTL stop eons $force");

      trace  ("$SRVCTL remove eons $force");
      system ("$SRVCTL remove eons $force");
   }
} #endsub


sub RemoveOC4JResource
{
  return $SUCCESS;
}

sub removeACFSRegistry
#-------------------------------------------------------------------------------
# Function: Uninstall ACFS if OS is supported
# Args    : 0
#-------------------------------------------------------------------------------
{
   my $node   = $CFG->HOST;
   my $crsctl = catfile ($CFG->ORA_CRS_HOME, 'bin', 'crsctl');
   my $res    = 'ora.registry.acfs';
   my $force  = '';
   my $cmd;
   my $status;

   if ($g_force) {
      $force = '-f';
   }

   # check if acfs registry status
   my @out = system_cmd_capture($crsctl, 'stat', 'res', $res);
   $status  = grep (/OFFLINE/i, @out);

   if (scalar($status) > 0) {
      trace ("$cmd is OFFLINE");
      return TRUE;
   }

   # stop acfs registry 
   $cmd    = "$crsctl stop res $res -n $node $force";
   $status = system("$cmd");

   if ($status == 0) {
      trace ("$cmd ... success");
   } else {
      trace ("$cmd ... failed");
   }

   # delete acfs registry if lastnode
   if ($g_lastnode) {
      $cmd    = "$crsctl delete res $res $force";
      $status = system ("$cmd");

      if ($status == 0) {
         trace ("$cmd ... success");
      } else {
         trace ("$cmd ... failed");
      }
   }
}

sub disableACFSDriver
#-------------------------------------------------------------------------------
# Function: Stop ACFS drivers
# Args    : 0
#-------------------------------------------------------------------------------
{
   my $crsctl = catfile ($CFG->ORA_CRS_HOME, 'bin', 'crsctl');
   my $res    = 'ora.drivers.acfs';
   my $cmd;
   my $status;

   # disable acfs drivers 
   $cmd    = "$crsctl modify resource $res -attr \"ENABLED=0\" -init";
   $status = system ("$cmd");

   if ($status == 0) {
      trace ("$cmd ... success");
   } else {
      trace ("$cmd ... failed");
   }
}

sub deleteACFSDriver
#-------------------------------------------------------------------------------
# Function: Delete ACFS resource and uninstall acfsroot
# Args    : 0
#-------------------------------------------------------------------------------
{
   my $crsctl = catfile ($CFG->ORA_CRS_HOME, 'bin', 'crsctl');
   my $res    = 'ora.drivers.acfs';
   my $force  = '';
   my $cmd;
   my $status;

   if ($g_force) {
      $force = '-f';
   }

   # delete acfs drivers 
   $cmd    = "$crsctl delete res $res -init $force";
   $status = system ("$cmd");

   if ($status == 0) {
      trace ("$cmd ... success");
   } else {
      trace ("$cmd ... failed");
   }
}


sub StopClusterware
#-------------------------------------------------------------------------------
# Function: Stop clusterware
# Args    : 0
#-------------------------------------------------------------------------------
{
   trace ("Stop Oracle Clusterware...");

   # Validate system command
   ValidateCRSCTL || return $FAILED;

   # check if ACFS supported
   my $ACFS_supported = ACFSState();

   if ($ACFS_supported) {
      removeACFSRegistry();
   }

   if (($g_lastnode) && ($CFG->params('CRS_STORAGE_OPTION') != 1)) {
      if ($ACFS_supported) {
         disableACFSDriver();
         deleteACFSDriver();
         removeACFSRoot();
      }
   }

   #keep ohasd running for ocr/vdsk on asm
   if (($g_lastnode) && ($CFG->params('CRS_STORAGE_OPTION') == 1)) {
      my $cmd = "$CRSCTL stop cluster -f";
      trace ("$cmd");
      system ("$cmd");
   }
   else {
      my $cmd = "$CRSCTL stop crs -f";
      trace ("$cmd");
      system ("$cmd");
   }

   # check the status of CRS stack
   if (! (($g_lastnode) && ($CFG->params('CRS_STORAGE_OPTION') == 1))) {
      if (! checkServiceDown("cluster")) {
         print "You must kill crs processes or reboot the system to properly \n";
         print "cleanup the processes started by Oracle clusterware\n";
      }
   }

   if (($g_lastnode) &&  ($CFG->params('CRS_STORAGE_OPTION') == 1)) {
      if ($ACFS_supported) {
         disableACFSDriver();
      }

      deconfigure_ASM();

      if ($ACFS_supported) {
         deleteACFSDriver();
         removeACFSRoot();
      }

      # stop crs
      my $cmd = "$CRSCTL stop crs -f";
      trace ("$cmd");
      system ("$cmd");
   }

   # Allow CRS daemons to shutdown in 10sec
   sleep 10;

} #endsub

sub StopHAStack
#-------------------------------------------------------------------------------
# Function: Stop Oracle Restart
# Args    : 0
#-------------------------------------------------------------------------------
{
   trace ("Stop Oracle Restart");

   # Validate system command
   ValidateCRSCTL || return $FAILED;

   trace ("$CRSCTL stop resource ora.cssd");
   if ($g_force)
   {
      system ("$CRSCTL stop resource ora.cssd -f");
   } else {
      system ("$CRSCTL stop resource ora.cssd");
   }

   # remove ohasd resource
   trace ("$CRSCTL delete resource ora.cssd");
   if ($g_force)
   {
      system ("$CRSCTL delete resource ora.cssd -f");
   } else {
      system ("$CRSCTL delete resource ora.cssd");
   }

   # stop ohasd
   trace ("Stopping Oracle Restart");

   trace ("$CRSCTL stop has");
   if ($g_force)
   {
      system ("$CRSCTL stop has -f");
   } else {
      system ("$CRSCTL stop has");
   }

   # Allow HA daemons to shutdown in 10sec
   sleep 10;

   # check the status of HA stack
   if (! checkServiceDown("ohasd")) {
      print "You must kill ohasd processes or reboot the system to properly \n";
      print "cleanup the processes started by Oracle clusterware\n";
   }
} #endsub

sub DowngradeTo9i
#--------------------------------------------------------------------
# Function: Downgrade to 9i
# Args    :
#--------------------------------------------------------------------
{
   # Check existence of srvconfig.loc
   if (-f $SRVCONFIG) 
   { 
      # CASE 1: srvConfig.loc does exist. So lets see the OCR location
      $srv_loc = get_srvdisk (); 
      $ocr_loc = get_ocrdisk (); 

      if ($srv_loc eq "/dev/null") 
      {
         # CASE 1.1: srvconfig_loc = /dev/null
         # srvConfig.loc has /dev/null that was invalidated during 10g install
         # Copying the location from ocr.loc to srvConfig.loc for downgrade
         AddLocation ($SRVCONFIG, "srvconfig_loc", $ocr_loc)
      } elsif ($srv_loc ne $ocr_loc) {
         # CASE 1.2: if srvconfig_loc = ocrconfig_loc, do nothing.
         # Otherwise OCR device in ocr.loc will be wiped out next
         $ocr_loc = $srv_loc;
      }
   } 

   if ($g_lastnode)
   {
      # Ensure 9i GSD can read/write 9i OCR
      if (($valid_owner) and ($valid_group)) 
      {
         chown ($ORACLE_OWNER, $ORA_DBA_GROUP, $ocr_loc);
      } 


      chmod (0644, $ocr_loc);
   }

   unlink($OCRCONFIG);

} #endsub


sub DowngradeTo10or11i
#----------------------------------------------------------------
# Function:
# Args    :
#----------------------------------------------------------------
{
   # Re-create ocr.loc for version 10 and later
   $ocr_loc = get_ocrdisk ();
   $ocr_mirror_loc = get_ocrmirrordisk ();
   $ocr_loc3 = get_ocrloc3disk ();
   $ocr_loc4 = get_ocrloc4disk ();
   $ocr_loc5 = get_ocrloc5disk ();
   $local_only = get_ocrlocaldisk ("ocr", "local_only");

   # for all 10 version and later
   AddLocation ($OCRCONFIG, "ocrconfig_loc", $ocr_loc);

   # 10.1 doesn't support any mirroring
   if ($VERSION ne "10.1") 
   {
      if (! -z $ocr_mirror_loc) 
      {
         AddLocation ($OCRCONFIG, "ocrmirrorconfig_loc", $ocr_mirror_loc);
      } 
   } 

   # 10.1, 10.2 and 11.1 only support 2-way mirroring
   if (($VERSION ne "10.1") && 
       ($VERSION ne "10.2") && 
       ($VERSION ne "11.1")) 
   {
      if (! -z $ocr_loc3) 
      {
         AddLocation ($OCRCONFIG, "ocrconfig_loc3", $ocr_loc3);
      } 

      if (! -z $ocr_loc4) 
      {
         AddLocation ($OCRCONFIG, "ocrconfig_loc4", $ocr_loc4);
      } 

      if (! -z $ocr_loc5) 
      {
         AddLocation ($OCRCONFIG, "ocrconfig_loc5", $ocr_loc5);
      }
   }

   # for all 10 version and later; append local_only to the end
   if (! -z $local_only) 
   {
      AddLocation ($OCRCONFIG, "local_only", $local_only);
   } 

   #ocr.loc will be preserved for downgrading to 10.1
} #endsub


sub AddLocation
#---------------------------------------------------------------------
# Function: Add ocrconfig_loc, ocrmirrorconfig_loc, etc...
#           If location already exists it replaces with the new location
# Args    : 3
#---------------------------------------------------------------------
{
   my $infile = $_[0];
   my $match_pattern = $_[1];
   my $replace_text = $_[2];

   open (InFile, "<$infile")
      or die "Can't open $infile for reading :$!";
   open (OutFile, ">$infile.tmp")
      or die "Can't open $infile.tmp for writing :$!";

   my $found_pattern = FALSE;
   while (my $line = <InFile>) 
   {
      if ($line =~ /$match_pattern\b/) 
      {
         $found_pattern = TRUE;
         print OutFile "$match_pattern=$replace_text\n";
      } else {
         print OutFile $line;
      }
   }

   if (! $found_pattern)
   {
      print OutFile "$match_pattern=$replace_text\n";
   }

   close (InFile)
      or die "Can't close $infile :$!";
   close (OutFile)
      or die "Can't close $infile.tmp :$!";

   move ("$infile.tmp", $infile)
      or die "Can't move $infile.tmp to $infile: $!";
} #endsub

sub DeleteSCR
{
   if (-d $SCRBASE)
   {
      trace ("Cleaning up SCR settings in $SCRBASE");
      rmtree ($SCRBASE);
   }

   if (-d $OPROCDDIR)
   {
      trace ("Cleaning oprocd directory, and log files");
      rmtree ($OPROCDDIR);
   }
} #endsub 

sub NSCleanUp
{
   trace ("Cleaning up Network socket directories");

   foreach $nsdir (@ns_dir)
   {
      foreach $file (<$nsdir/*>)
      {
         foreach $ns (@ns_files)
	 {
            if ($file =~ $ns)
            {
	       trace("Unlinking file : $file");
               unlink($file);
            }
         }
      }
   }

} #endsub

sub remove_oradiag
{
   # oradiag_root is to removed only if root script is invoked
   my $dir = catdir ($CFG->params('ORACLE_BASE'), 'oradiag_root');

   if ($CFG->defined_param('HOME_TYPE')) {
      # remove oracle_base/oradiag_root dir
      if (-e $dir) {
         trace ("Remove $dir");
         rmtree ($dir);
      }
   }
   else {
      trace ("Root script is not invoked as part of deinstall. $dir is not removed");
   }
}


######################################################################
#                       M A I N                                      #
######################################################################
sub CRSDelete
{
  
   if (! $CFG->DOWNGRADE)
   { 
      trace ("Deconfiguring Oracle Clusterware on this node");
   } else {
      trace ("Downgrading  Oracle Clusterware on this node");
   }

   TraceOptions ();

   # We need Oracle owner and group to reset permission of 
   # Oracle software files
   ValidateOwnerGroup ();

   if ($g_lastnode) {
      # Extract voting disks
      @votedisk_list = ExtractVotedisks();
   }

   if (! $CFG->DOWNGRADE) 
   {
      $status = VerifyResources ();
      if ($status eq $FAILED) 
      {
         die "Failed to verify resources\n";
      }

      # Only remove resources which were created during 
      # Oracle Clusterware configuration
      RemoveResources ();
   }

   StopClusterware ();

   s_RemoveInitResources ();

   if (! $CFG->DOWNGRADE)
   {
      s_ResetOCR ();
   }

   #Remove olr.loc in case of downgrade
   if ($CFG->DOWNGRADE)
   {
      s_ResetOLR ();
   }

   if ($g_lastnode) {
      s_ResetVotedisks (@votedisk_list);
   }

   if (($CFG->DOWNGRADE) && ($g_lastnode)) {
      ocrDowngrade ();
   }

   DeleteSCR ();

   NSCleanUp ();
   
   # Temporarely comment out s_removeGPnPprofile()
#  s_removeGPnPprofile();

   remove_oradiag();

   s_CleanTempFiles ();

   remove_checkpoints ();

   trace ("Opening permissions on Oracle clusterware home");
   s_reset_crshome($ORACLE_OWNER, $ORA_DBA_GROUP, 755, $ORACLE_HOME);

   # reset permission on OCR locations
   #TODO - move this to s_ResetOCR so that we need not rely
   #on OCR_LOCATIONS
   trace ("reset permissions on OCR locations");
   if (! $CFG->ASM_STORAGE_USED) {
      if ($CFG->defined_param('OCR_LOCATIONS'))
      {
         my @ocr_locs = split (/\s*,\s*/, $CFG->params('OCR_LOCATIONS'));
         foreach my $loc (@ocr_locs) {
            # reset owner/group of OCR path
            trace ("set owner/group of OCR path");
            s_reset_crshome($ORACLE_OWNER, $ORA_DBA_GROUP, 755, $loc);
         }
      }
   }

  removeCvuRpm ();

  if (($CFG->DOWNGRADE) && (! $g_lastnode)) 
  {
     trace ("Successfully downgraded Oracle clusterware stack on this node");
     print "Successfully downgraded Oracle clusterware stack on this node\n";

  }

  if (! $CFG->DOWNGRADE)
  {
     trace ("Successfully deconfigured Oracle clusterware stack on this node");
     print "Successfully deconfigured Oracle clusterware stack on this node\n";
  }
} #end sub CRSDelete

sub HADeconfigure
{
   trace ("Deconfiguring Oracle Restart on this node");
   TraceOptions ();

   # We need Oracle owner and group to reset permission of
   # Oracle software files
   ValidateOwnerGroup ();

   if (! $g_downgrade)
   {
      $status = VerifyHAResources ();
      if ($status eq $FAILED)
      {
         die "Failed to verify HA resources\n";
      }

      # Only remove resources which were created during
      # Oracle Restart configuration
      RemoveHAResources ();
   }

   StopHAStack ();

   my $ACFS_supported = ACFSState();
   if ($ACFS_supported) {
      removeACFSRoot();
   }

   s_RemoveInitResources ();

   s_ResetOCR ();

   DeleteSCR ();

   NSCleanUp ();

   s_CleanTempFiles ();

   trace ("Opening permissions on Oracle Restart home");   
   s_reset_crshome($ORACLE_OWNER, $ORA_DBA_GROUP, 755, $ORACLE_HOME);

   trace ("Successfully deconfigured Oracle Restart stack");
   print "Successfully deconfigured Oracle Restart stack\n";

} #end sub HADeconfigure

sub removeCvuRpm
#---------------------------------------------------------------------
# Function: Remove cvuqdisk rpm
# Args    : None
#---------------------------------------------------------------------
{
   my $platform_family = s_get_platform_family ();

   if ($platform_family eq "unix")
   {
      s_removeCvuRpm();
   }
}

sub ocrDowngrade
#---------------------------------------------------------------------
# Function: Downgrade OCR
# Args    : None
#---------------------------------------------------------------------
{
 my $OLD_CRS_HOME  = $CFG->oldcrshome;
 my $ocrconfigbin  = catfile ($OLD_CRS_HOME, 'bin', 'ocrconfig');
 my $oldcrsver     = $CFG->oldcrsver;
 my $ocrbackupfile = "ocr" . "$oldcrsver";
 my $ocrbackuploc  = catfile ($ORACLE_HOME, 'cdata', $ocrbackupfile);


 if (! -e $OLD_CRS_HOME) {
    error  ("crshome: $OLD_CRS_HOME not found. Re-try the command with right path for old crs home");     
    exit 1;
 }

 trace("OCR backup file is $ocrbackuploc");

 if ((! (-f $ocrbackuploc)) || (0 !=  system_cmd($ocrconfigbin, '-import', $ocrbackuploc))) {
    error("Failed to downgrade OCR to $oldcrsver");
    print "Perform the following to restore to old version Clusterware\n";
    print "1. Run '$ORACLE_HOME/crs/install rootcrs.pl -force -delete' on all the remote nodes\n";
    print "2. Run '$ORACLE_HOME/crs/install rootcrs.pl -force -delete -lastnode' on the local node\n";
    print "3. Re-install old Clusterware and re-configure all the resources with appropriate srvctl commands\n";
    
 }else {
    trace("Successfully downgraded OCR to $oldcrsver"); 
    print "Successfully downgraded OCR to $oldcrsver\n";
    print "Run root.sh from the old crshome on all the cluster nodes one at a time to start the Clusterware\n";
 }
}

sub ACFSState
#---------------------------------------------------------------------
# Function: Check if ACFS is supported
# Args    : None
# Return  : TRUE  if     supported
#           FALSE if not supported
#---------------------------------------------------------------------
{
   my $acfsstate = catfile ($CFG->ORA_CRS_HOME, 'bin', 'acfsdriverstate');
   my $cmd       = "$acfsstate supported";

   if (! (-e $acfsstate)) {
      trace ("ADVM/ACFS is not configured");
      return;
   }

   my $status = system ("$cmd");

   if ($status == 0) {
      trace ("ADVM/ACFS is configured");
      return TRUE;
   }
   else {
      trace ("ADVM/ACFS is not configured");
      return FALSE;
   }
}

sub removeACFSRoot
{
   # removing acfsroot
   my $acfsroot = catfile ($CFG->ORA_CRS_HOME, 'bin', 'acfsroot');
   my $cmd      = "$acfsroot uninstall -s";

   if (! (-e $acfsroot)) {
      trace ("ADVM/ACFS is not configured");
      return;
   }

   my $status = system ("$cmd");

   if ($status == 0) {
      trace ("$cmd ... success");
   } else {
      trace ("$cmd ... failed");
   }
}

1;
