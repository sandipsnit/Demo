# Adrci.pm: Discovery Plug-in Related to adrci

package IRDA::CV0100::Adrci;

# $Id: Adrci.pm,v 1.14 2012/04/25 07:16:30 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/IRDA/CV0100/Adrci.pm,v 1.14 2012/04/25 07:16:30 mschenke Exp $
#
# Change History
# 20120422  MSC  Apply agent changes.

=head1 NAME

IRDA::CV0100::Adrci - Discovery Plug-in Related to adrci

=head1 SYNOPSIS

require IRDA::CV0100::Adrci;

=head1 DESCRIPTION

This package regroups the definition of the discovery mechanisms for getting
values from F<adrci>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION $PLUGIN);
$VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);

# Define the global private variables
my %tb_run = (
  'get_incident_date'  => \&_get_incident_date,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = IRDA::CV0100::Adrci-E<gt>load($tbl)>

This method loads the mechanism definition in the mechanism table.

=cut

sub load
{ my ($cls, $tbl) = @_;

  foreach my $nam (keys(%tb_run))
  { $tbl->{$nam} = $tb_run{$nam};
  }
}

=head1 OPERATOR DEFINITIONS

=head2 get_incident_date - Get date from incident

This discovery mechanism retrieves the incident date by using F<adrci>.

=cut

sub _get_incident_date
{ my ($slf, $nam) = @_;
  my ($agt, $beg, $cmd, $end, $id, $ora, $sid, $trc, @adr, @tbl);

  $agt = $slf->{'agt'};
  $trc = $slf->{'trc'};

  # Set ADRCI environment
  die "Missing incident identifier\n"
    unless defined($id = $slf->get_request_value('INCIDENT_ID'));
  die "Missing Oracle home\n"
    unless ($ora = $agt->get_setting('ORACLE_HOME'));
  die "Missing Oracle system identifier\n"
    unless ($sid = $agt->get_setting('ORACLE_SID'));

  $ENV{'ORACLE_HOME'} = $ora;
  $ENV{'ORACLE_SID'}  = $sid;

  # Assemble the ADRCI command
  $cmd = RDA::Object::Rda->clean_path($slf->get_request_value('ADR_HOME'), 1);
  die "Missing ADR home\n" unless defined($cmd);
  if (RDA::Object::Rda->is_windows)
  { (undef, @tbl) = split(/\\/, $cmd);
  }
  else
  { (undef, @tbl) = split(/\//, $cmd);
  }
  @adr = splice(@tbl, -4);
  die "Invalid ADR home '$cmd'\n" unless (scalar @adr) == 4;
  $cmd = RDA::Object::Rda->quote(RDA::Object::Rda->cat_file($ora, 'bin',
    'adrci'));
  if (RDA::Object::Rda->is_windows)
  { $cmd .= ' exec=set homepath '.join('\\\\', @adr)
      .';query (create_time) incident -p \\\\\\"incident_id='.$id.'\\\\\\"';
  }
  elsif (RDA::Object::Rda->is_cygwin)
  { $cmd .=  ' exec=\'set homepath '.join('\\\\', @adr)
      .';query (create_time) incident -p \\"incident_id='.$id.'\\"\'';
  }
  elsif (RDA::Object::Rda->is_vms)
  { $cmd = 'PIPE '.$cmd.' exec=\'set homepath '.join('/', @adr)
      .';query (create_time) incident -p \"incident_id='.$id.'\"\'';
  }
  else
  { $cmd .= ' exec=\'set homepath '.join('/', @adr)
      .';query (create_time) incident -p \"incident_id='.$id.'\"\'';
  }
  print "[Adrci/get_incident_date] exec: $cmd\n" if $trc;

  # Run the adrci command and parse the output
  open(OUT, "$cmd |") or die "Adrci pipe error\n$!\n";
  while(<OUT>)
  { s/[\n\r\s]+$//;
    print "adrci> $_\n" if $trc;
    if (m/^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})/)
    { @tbl = ($6, $5, $4, $3, $2 - 1, $1 - 1900, 0, 0, -1);
      last;
    }
  }
  close(OUT);

  # Derive the time stamps
  eval {
    require POSIX;
    &POSIX::tzset();
    $beg = $end = &POSIX::mktime(@tbl);
    $beg -= 3600 * $agt->get_setting('hours_before_incident', 1);
    $end += 3600 * $agt->get_setting('hours_after_incident', 0.5);
    $beg = &POSIX::strftime('%d-%b-%Y_%H:%M:%S', localtime($beg));
    $end = &POSIX::strftime('%d-%b-%Y_%H:%M:%S', localtime($end));
  };
  die "Time stamp generation error\n$@\n" if $@;
  $agt->set_temp_setting('LOG_MERGE_BEGIN', $beg);
  $agt->set_temp_setting('LOG_MERGE_END',   $end);
  $agt->set_temp_setting('LOG_MERGE_SET',   'adr');
  $agt->set_temp_setting('LOG_RUN_MERGE',   1);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<IRDA::Prepare|IRDA::Prepare>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
