# Linux.pm: Linux-specific Conversions for OS Reports

package Convert::S100OS::Linux;

# $Id: Linux.pm,v 2.4 2012/01/02 16:43:48 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/Convert/S100OS/Linux.pm,v 2.4 2012/01/02 16:43:48 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

Convert::S100OS::Linux - Linux-specific Conversions for OS Reports

=head1 SYNOPSIS

require Convert::S100OS::Linux;

=head1 DESCRIPTION

This package is regroups Linux-specific conversion methods for the OS module
reports.

It is only provided as plugin example and is thus incomplete by nature.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Convert;
}

# Define the global public variables
use vars qw($VERSION %PLUGIN);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
%PLUGIN  = (
  cnv => [{blk => {
             cpu_info => [
               [qr/^CPU Information$/,
                \&ext_value]],
             memory_info => [
               [qr/^Physical Memory Installed$/,
                \&ext_value]],
             services => [
               [qr/^Runlevel Information for System Services$/,
                \&ext_svc_level],
               [qr/^System Service Status$/,
                \&ext_svc_status]],
             sysdef => [
               [qr/^System\/Kernel Settings$/,
                \&ext_sysdef_info]],
             },
           nam => 'Linux-specific Conversions',
           osn => 'linux',
           rnk => 10,
           sel => \&RDA::Convert::sel_block,
           typ => 'B',
          },
          {blk => {
             packages => [
               [qr/^Operating System Package Information$/,
                {'*' => 'package_list'}]],
             sysdef => [
               [qr/^Main Kernel Parameters$/,
                {'*' => 'kernel_parameters'}]],
             },
           nam => 'Linux-specific Custom Table Tags',
           osn => 'linux',
           rnk => 10,
           sel => \&RDA::Convert::sel_block,
           typ => 'T',
          },
         ],
  );

# Define the global private variables
my %tb_val = (
  'CPU Information'           => 'cpu_details',
  'Physical Memory Installed' => 'mem_details',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<ext_svc_level($ctl,$ofh,$blk)>

This method converts C<chkconfig --list> output.

=cut

sub ext_svc_level
{ my ($ctl, $ofh, $blk) = @_;
  my ($lin, $sum, $svc, @lvl, @xml);

  # Treat init level part
  print {$ofh} "<service_levels summary='$blk'>\n";
  while (defined($lin = $ctl->get_line))
  { if ($lin =~ m/^([\w\s]*):$/)
    { $sum = $1;
      last;
    }
    ($svc, @lvl, @xml) = split(/\s+/, $lin);
    foreach my $lvl (@lvl)
    { push(@xml, "init$1='$2'") if $lvl =~ m/^(\d):(.*)$/;
    }
    print {$ofh} "<sdp_row service='$svc' ".join(' ', @xml)."/>\n";
  } 
  print {$ofh} "</service_levels>\n";

  # Treat other part
  if ($sum)
  { print {$ofh} "<sdp_table summary='$sum'>\n";
    while (defined($lin = $ctl->get_line))
    { if ($lin =~ m/^\s+(.*):\s*(.+)$/)
      { print {$ofh} "<sdp_row service='$1' status='$2'/>\n"
      }
      else
      { $ctl->trace(4, "** skipping: $lin");
      }
    }
    print {$ofh} "</sdp_table>\n";
  }
}

=head2 S<ext_svc_status($ctl,$ofh,$blk)>

This method converts C<service --status-all> output.

=cut

sub ext_svc_status
{ my ($ctl, $ofh, $blk) = @_;
  my ($lin);

  print {$ofh} "<service_statuses summary='$blk'>\n";
  while (defined($lin = $ctl->get_line))
  { if ($lin =~ m/^(.*) is (.*)\.*$/ || $lin =~ m/^(.*) ((dead|loaded).*)$/)
    { print {$ofh} "<sdp_row service='$1' status='$2'/>\n";
    }
    elsif ($lin)
    { $ctl->trace(4, "** skipping: $lin");
    }
  } 
  print {$ofh} "</service_statuses>\n";
}

=head2 S<ext_sysdef_info($ctl,$ofh,$blk)>

This method converts C<sysdef> output.

=cut

sub ext_sysdef_info
{ my ($ctl, $ofh, $blk) = @_;
  my ($key, $lin, $val);

  print {$ofh} "<sysdef_details summary='$blk'>\n";
  while (defined($lin = $ctl->get_line))
  { ($key, $val) = split(/\s*=\s*/, $lin);
    print {$ofh} "<sdp_row parameter='$key' value='$val'/>\n";
  } 
  print {$ofh} "</sysdef_details>\n";
}

=head2 S<ext_value($ctl,$ofh,$blk)>

This method converts C<parameter:value> pairs.

=cut

sub ext_value
{ my ($ctl, $ofh, $blk) = @_;
  my ($key, $lin, $tag, $val);

  $tag = exists($tb_val{$blk}) ? $tb_val{$blk} : 'sdp_table';
  print {$ofh} "<$tag summary='$blk'>\n";
  while (defined($lin = $ctl->get_line))
  { next unless $lin;
    ($key, $val) = split(/\s*:\s*/, $lin);
    print {$ofh} "<sdp_row parameter='$key' value='$val'/>\n"
      if defined($key) && defined($val);
  } 
  print {$ofh} "</$tag>\n";
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Object::Convert|RDA::Object::Convert>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
