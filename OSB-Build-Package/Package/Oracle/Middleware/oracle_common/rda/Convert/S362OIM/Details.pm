# Details.pm: Details Conversions for OIM Reports

package Convert::S362OIM::Details;

# $Id: Details.pm,v 2.4 2012/01/02 16:43:48 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/Convert/S362OIM/Details.pm,v 2.4 2012/01/02 16:43:48 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

Convert::S362OIM::Details - Details Conversions for OIM Reports

=head1 SYNOPSIS

require Convert::S362OIM::Details;

=head1 DESCRIPTION

This package is regroups conversion methods of C<Details> cells contained in
the OIM module reports.

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
             db_connect => [
               [qr#^Database Connectivity Check$#, #
                {'*'       => 'sdp_table',
                 'details' => \&fmt_details,
                }]],
             },
           nam => 'Details Conversions',
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

=head2 S<fmt_details($ctl,$str)>

This method converts the details cell content.

=cut

sub fmt_details
{ my ($ctl, $str) = @_;
  my ($buf, $cnt);

  $buf = '';
  $cnt = 0;
  $str =~ s/\`\`//g;
  $str =~ s/&nbsp;/ /g;
  foreach my $lin (split(/\%BR\%/, $str))
  { if ($lin =~ s/^\s+//)
    { $buf .= "<sdp_detail parameter='$1' value='$2'/>\n"
        if $lin =~ m/^([^:]*):\s*(.*)$/;
    }
    elsif ($lin)
    { $buf .= "</sdp_details></sdp_test>\n" if $cnt++;
      $buf .= "<sdp_test desc='$lin'><sdp_details>\n";
    }
  }
  $buf .= "</sdp_details></sdp_test>\n" if $cnt;
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
