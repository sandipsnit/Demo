# Convert.pm: Generic Conversions for TSTalert Reports

package Convert::TSTALERT::Convert;

# $Id: Convert.pm,v 2.4 2012/01/02 16:43:48 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/Convert/TSTALERT/Convert.pm,v 2.4 2012/01/02 16:43:48 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

Convert::TSTALERT::Convert - Generic Conversions for TSTalert Reports

=head1 SYNOPSIS

require Convert::TSTALERT::Convert;

=head1 DESCRIPTION

This package is regroups generic conversion methods for the TSTalert module
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
             alert_summary => [
               [qr#^Counts by Error$#,  #
                {'-' => \&split_error_row}]
               ],
             },
           nam => 'Table Improvements',
           rnk => 10,
           sel => \&RDA::Convert::sel_block,
           typ => 'T',
         },
        ],
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

# Split error count rows
sub split_error_row
{ my ($ctl, $lin) = @_;
  my ($buf, $cnt, $err, @tbl);

  $buf = '';
  @tbl = $ctl->get_cells($lin); 
  while (($err, $cnt) = splice(@tbl, 0, 2))
  { $buf .= "<sdp_row error='$err' count='$cnt'/>\n"
      if $err && $err !~ m/^\*(.+)\*$/;
  }
  $buf;
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
