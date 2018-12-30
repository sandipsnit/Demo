# $Header: has/install/crsconfig/crspatch.pm st_has_ksviswan_autopatch_impl1/3 2009/11/03 00:14:15 ksviswan Exp $
#
# crspatch.pm
#
# Copyright (c) 2007, 2009, Oracle and/or its affiliates. All rights reserved. 
#

=head1 NAME

  crspatch.pm  Oracle clusterware Patching Module/Package

=head1 DESCRIPTION

   This package contains functions required for  patching
   Oracle clusterware Software

=cut

#    MODIFIED   (MM/DD/YY)
#    ksviswan    08/24/09 - Fix Bug 8797450
#    dpham       07/29/09 - XbranchMerge dpham_bug-8727340 from
#                           st_has_11.2.0.1.0
#    ksviswan    07/24/09 - Install ACFS after patching
#    dpham       07/15/09 - XbranchMerge dpham_bug-8664938 from main
#    dpham       07/09/09 - wait for crs to start
#    ksviswan    04/20/09 - Creation



use strict;
use English;
use File::Spec::Functions;

use crsconfig_lib;

my $stfile;

sub Getcrsconfig
{

}

sub Getdbconfig
{

}

sub Stopdbhomeres
{
   my $home = $_[0];
   my $srvctlbin    = catfile ($home, "bin", "srvctl");
   my $nodename = $CFG->HOST; 
   my $success;

   $stfile = catfile ($home, "srvm", "admin", "stophome.txt");
   $ENV{ORACLE_HOME} = $home;
   my $cmd = "$srvctlbin stop home -o $home -s $stfile -n $nodename";
   my $status = system_cmd($cmd);
   if ($status != 0) {
     error("Failed to stop resources from  database home $home");
     $success = FALSE;
   } else {
     trace("Stopped resources from datbase home $home");
  }
  return $success;
}

sub Stopcrshomeres
{

}

sub Stopcrs
{

}

sub Instantiatepatchfiles
{
   #TODO - Should we just rely on crsconfig_params or
   #should we derive the critical values.
   instantiate_scripts ();
   create_dirs ();   
   copy_wrapper_scripts ();

   set_file_perms ();
   
}

sub StartCRS
{
   my $rc;
   # Validate system command
   ValidateCRSCTL || return $FAILED;
   trace("Starting Oracle Clusterware");
   $rc = system ("$CRSCTL start crs"); 

   if (!wait_for_stack_start(36)) { exit 1; }
}

sub StartHA
{
   my $rc;
   # Validate system command
   ValidateCRSCTL || return $FAILED;
   trace("Starting Oracle Restart");
   $rc = system ("$CRSCTL start has");

    # Check if the service/daemon has started
    trace ("Checking ohasd");
    my $ohasd_running = check_service ("ohasd", 24);

    if ($ohasd_running) {
      trace ("ohasd started successfully");
    } else {
      error ("Timed out waiting for ohasd to start.");
      exit 1;
    }
}
sub Startcrshomeres
{

}

sub Startdbhomeres
{
   my $home = $_[0];
   my $srvctlbin    = catfile ($home, "bin", "srvctl");
   my $nodename = $CFG->HOST; 
   my $success;


   my $cmd = "$srvctlbin start home -o $home -s $stfile -n $nodename";
   $ENV{ORACLE_HOME} = $home;
   my $status = system_cmd($cmd);
   if ($status != 0) {
     error("Failed to start resources from  database home $home");
     $success = FALSE;
   } else {
     trace("Started resources from datbase home $home");
  }

  unlink ($stfile);  
  return $success;
}

######################################################################
#                       M A I N                                      #
######################################################################
sub CRSPatch
{

   trace ("Patching Oracle Clusterware");

   #Instantiate the patched files.
   Instantiatepatchfiles ();
  
   # fixme: rename isACFSSupported in crsconfig_lib.pm 
   # install ACFS
   isACFSSupported(); 

   StartCRS();  
}
sub HAPatch
{

   trace ("Patching Oracle Restart");

   #Instantiate the patched files.
   Instantiatepatchfiles ();

   # fixme: rename isACFSSupported in crsconfig_lib.pm 
   # install ACFS
   isACFSSupported();

   StartHA();
}
1;
