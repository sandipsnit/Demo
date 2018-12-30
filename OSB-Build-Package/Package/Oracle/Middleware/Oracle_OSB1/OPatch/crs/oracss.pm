# $Header: has/install/crsconfig/oracss.pm /main/17 2009/09/17 17:28:21 jleys Exp $
#
# OraCSS.pm
#
# Copyright (c) 2007, 2009, Oracle and/or its affiliates. All rights reserved. 
#

=head1 NAME

  oracss.pm  Oracle clusterware CSS component configuration/startup package

=head1 DESCRIPTION

   This package contains functions required for initial configuration
   and startup of the CSS component of Oracle clusterware

=cut

package oracss;

use strict;
use English;
use File::Spec::Functions;

use crsconfig_lib;

use constant CSS_EXCL_SUCCESS             => 1;
use constant CSS_EXCL_FAIL_CLUSTER_ACTIVE => 2;
use constant CSS_EXCL_FAIL                => 3;

use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);

my @exp_func  = qw(CSS_start_exclusive CSS_start_clustered CSS_start
                   CSS_is_configured CSS_upgrade CSS_get_old_VF_string
                   CSS_prep_old_VFs CSS_add_vfs CSS_delete_vfs
                   CSS_stop CSS_CanRunRealtime);

my @exp_const = qw(CSS_EXCL_SUCCESS CSS_EXCL_FAIL
                   CSS_EXCL_FAIL_CLUSTER_ACTIVE);

push @EXPORT, @exp_func, @exp_const;

=head1 EXPORTED FUNCTIONS

=head2 CSS_start_exclusive

   Start the CSSD in exclusive mode.  The CSSD when started in this
   mode requires no configuration to have completed.

=head3 Parameters

   None

=head3 Returns

  CSS_EXCL_SUCCESS             - The CSSD was     started successsfully
  CSS_EXCL_FAIL_CLUSTER_ACTIVE - The CSSD was not started successsfully
                                 because other nodes are alive
  CSS_EXCL_FAIL                - The CSSD was not started successsfully

=cut

sub CSS_start_exclusive {
  trace("Starting CSS in exclusive mode");
  my $ret;
  my @output = CSS_start("-env", "CSSD_MODE=-X");
  my $rc     = shift @output;

  # If we had a failure, check to see if it is becasue another node is
  # up and if it is, we ignore the failure
  my @node_up = grep(/CRS\-4402/, @output);
  if (scalar(@node_up) > 0) {
    $ret = CSS_EXCL_FAIL_CLUSTER_ACTIVE;
    for my $line (@node_up) {
      print "$line\n";
      trace($line);
    }
    CSS_stop();
  }
  elsif ($rc) { $ret = CSS_EXCL_SUCCESS; }
  else { $ret = CSS_EXCL_FAIL; }

  for my $line (@output) {
    # if we were successful, or we failed due to unexpected reasons.
    # print out the msgs
    if ($ret == CSS_EXCL_SUCCESS || $ret == CSS_EXCL_FAIL) {
      print "$line\n";
      trace($line); # put to both user and log file
    }
  }

  return $ret;
}

=head2 CSS_start_clustered

   Start the CSSD in clsutered (normal) mode

=head3 Parameters

   None

=head3 Returns

  TRUE  - The CSSD was     started successsfully
  FALSE - The CSSD was not started successsfully

=cut

sub CSS_start_clustered {
  trace("Starting CSS in clustered mode");
  my @output = CSS_start();
  my $rc = shift @output;
  for my $line (@output) {
    print "$line\n";
    trace($line); # put to both user and log file
  }
  return $rc;
}

=head2 CSS_stop

  Stop the CSSD

=head3 Parameters

  None

=head3 Returns

  TRUE  - The CSS component is     stopped
  FALSE - The CSS component is not stopped

=cut

sub CSS_stop {
  my $rc = TRUE;

  if (!checkServiceDown("css"))
  {
    $rc = stop_resource("ora.cssd", "-init");
    if ($rc != TRUE) {
      trace("CSS shutdown failed");
    }
  }
  stop_resource("ora.cssdmonitor", "-init");

  return $rc;
}

=head2 CSS_CanRunRealtime

  Verifies that the CSSD can run realtime

=head3 Parameters

  crsconfig_lib class object

=head3 Returns

  TRUE  - The CSSD can    run realtime
  FALSE - The CSSD cannot run realtime

=cut

sub CSS_CanRunRealtime {
  my $cfg       = shift;
  my $rc = TRUE;

  if ($OSNAME eq "aix") {
    my $user = $cfg->params('ORACLE_OWNER');

    my @out = system_cmd_capture('/usr/sbin/lsuser', '-a',
                                 'capabilities', $user);
    my $status  = shift @out;
    chomp @out;
    my $capstr = (split(' ', $out[0]))[1];
    $capstr =~ s/^ *capabilities=//;
    my %caps = map { lc($_) => 1 } (split(',', $capstr));
    my @req_caps = ('CAP_NUMA_ATTACH', 'CAP_BYPASS_RAC_VMM',
                    'CAP_PROPAGATE');
    my @needed_caps;
    for my $cap (@req_caps) {
      if (!$caps{lc($cap)}) {
        push @needed_caps, $cap;
        $rc = FALSE;
      }
    }

    if ($rc) {
      my @msg = ("User $user has the required capabilities to run CSSD",
                 "in realtime mode");
      print "@msg\n";
      trace(@msg);
    }
    else {
      my @msg =
        ("User $user is missing the following capabilies required to",
         "run CSSD in realtime:");
      print "@msg\n";
      trace(@msg);
      @msg = (" ", join(',', @needed_caps));
      print "@msg\n";
      trace(@msg);
      @msg = ("To add the required capabilities, please run:");
      print "@msg\n";
      trace(@msg);
      @msg = ("   /usr/bin/chuser capabilities=" . join(',', @req_caps),
             $user);
      print "@msg\n";
      trace(@msg);
    }
  }

  return $rc;
}

=head2 CSS_upgrade

  Performs operations required for upgrade of CSS

=head3 Parameters

  crsconfig_lib class object

=head3 Returns

  SUCCESS - The CSS component has been successfully upgraded
  FAILED  - The CSS component upgrade failed

=cut

sub CSS_upgrade {
  my $cfg       = shift;
  my $rc        = SUCCESS;
  my $vfds;

  trace ("Upgrading the existing voting disks!");
  my $cmdrc = run_crs_cmd('cssvfupgd');
  if ($cmdrc != 0) {
    $rc = FAILED;
    error("Upgrade of voting files failed");
  }

  return $rc;
}

=head2 CSS_get_old_VF_string

  Gets old VF list from OCR and updates VF discovery string

=head3 Parameters

  None

=head3 Returns

  The CSS VF list obtained from OCR, or NULL if unable to obtain

=cut

sub CSS_get_old_VF_string {
  my $vfds;
  my $crsctl = crs_exec_path('crsctl');

  trace ("Obtaining the existing voting disks");
  my @vflist = system_cmd_capture($crsctl, 'get', 'css', 'vfdiscstring');
  my $cmdrc = shift @vflist;

  if ($cmdrc == 0) { $vfds = join(',', @vflist); }
  else {
    error("Unable to get voting file list for upgrade, return code $cmdrc");
    for my $line (@vflist) { print "$line\n"; trace($line); }
  }

  return $vfds;
}

=head2 CSS_prep_old_VFs

  Prepares older voting files that may have had the skgfr block cleaned

=head3 Parameters

  None

=head3 Returns

  SUCCESS - The voting files are all successfully prepared
  FAILED  - One or more voting files are not prepared

=cut

sub CSS_prep_old_VFs {
  my $cfg = shift;
  my $rc     = SUCCESS;
  my $clsfmt = crs_exec_path('clsfmt');
  my @vflist = split(',', $cfg->VF_DISCOVERY_STRING);

  trace ("Preparing the existing voting disks");
  for my $vf (@vflist) {
    my @cmdout = system_cmd_capture($clsfmt, 'css', $vf);
    my $cmdrc  = shift @cmdout;

    if ($cmdrc == 0) { for my $line (@cmdout) { trace($line); } }
    else {
      $rc = FAILED;
      error("Unable to prepare voting file $vf, return code $cmdrc");
      for my $line (@cmdout) { print "$line\n"; trace($line); }
    }
  }

  return $rc;
}


=head2 CSS_is_configured

  Checks to see if the CSS component has already been configured.  May
  be run with the CSSD started in exclusive or clustered mode, but is
  most meaningful when run with the CSSD in exclusive mode, since the
  CSSD will not start when configuration has not completed and the CSSD
  is started in clustered mode.

=head3 Parameters

  None

=head3 Returns

  TRUE  - The CSS component is     configured
  FALSE - The CSS component is not configured

=cut

sub CSS_is_configured {
  my $CRSCTL = crs_exec_path("crsctl");
  my $rc = FALSE;

  trace ("Querying for existing CSS voting disks");
  open(VFQUERY_PIPE, "$CRSCTL query css votedisk|");
  my @vflist = (<VFQUERY_PIPE>);
  chomp @vflist;
  close VFQUERY_PIPE;

  my $vfcount = scalar(@vflist) - 1;
  if ($vfcount > 0) {
    trace("Found $vfcount configured voting files");
    $rc = TRUE;
  }

  return $rc;
}

=head2 CSS_add_vfs

  Add voting file(s) to the CSSD configuration.

=head3 Parameters

  A list of voting file paths or a single ASM diskgroup name.  If the
  parameter is an ASM dikgroup name, it must be prefixed with a +

=head3 Returns

  TRUE  - The voting file(s) were     added
  FALSE - The voting file(s) were not added

=cut

sub CSS_add_vfs {
  my $rc = TRUE;

  my @addvfcmd;
  if ($_[0] =~ /^\+/) {
    my $diskgroup = $_[0];
    $diskgroup =~ s/^\+//;

    trace("Creating voting files in ASM diskgroup $diskgroup");
    @addvfcmd = ("crsctl", "replace", "votedisk", "+$diskgroup");
  }
  else {
    trace("Adding voting files @_");
    @addvfcmd = ("crsctl", "add", "css", "votedisk", (@_));
  }

  trace("Executing @addvfcmd");

  my $status = run_crs_cmd(@addvfcmd);

  if ($status != 0) {
    error("Voting file add failed");
    $rc = FALSE;
  }

  return $rc;
}

=head2 CSS_add_vfs

  Delete voting file(s) from the CSSD configuration.

=head3 Parameters

  None! It gets GUIDs from "crsctl query css votedisk"

=head3 Returns

  TRUE  - The voting file(s) were     deleted
  FALSE - The voting file(s) were not deleted

=cut

sub CSS_delete_vfs
{
   my $rc     = TRUE;
   my $crsctl = catfile ($CFG->ORA_CRS_HOME, "bin", "crsctl");
   my $ASM_DISK_GROUP = $CFG->params('ASM_DISK_GROUP');

   # deleting votedisk
   my @cmd = ("crsctl", "delete", "css", "votedisk", "+$ASM_DISK_GROUP");
   my $status = run_crs_cmd(@cmd);
   if ($status == 0) {
     trace ("crsctl delete for vds in $ASM_DISK_GROUP ... success");
   }
   else {
     error ("crsctl delete for vds in $ASM_DISK_GROUP ... failed");
     $rc = FALSE;
   }

  return $rc;
}

# Private subroutines
sub CSS_start {
  my $ORA_CRS_HOME = $ENV{'ORA_CRS_HOME'};
  my $crsctl = catfile($ORA_CRS_HOME, "bin", "crsctl");
  my $rc = FALSE;
  my @startcss = ($crsctl, "start", "resource", "ora.cssd", "-init",
                 (@_));
  my @output = system_cmd_capture(@startcss);
  my $status = shift @output;

  $rc = check_service ("css", 2);
  if (!$rc && scalar(grep(/CRS\-4402/, @output))) {
    push @output, "CSS startup failed with return code $status";
  }

  return ($rc, @output);
}

1;
