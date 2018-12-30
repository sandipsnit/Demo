# Convert.pm: Generic Conversions for CFG Reports

package Convert::S010CFG::Convert;

# $Id: Convert.pm,v 2.5 2012/01/02 16:43:48 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/Convert/S010CFG/Convert.pm,v 2.5 2012/01/02 16:43:48 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

Convert::S010CFG::Convert - Generic Conversions for CFG Reports

=head1 SYNOPSIS

require Convert::S010CFG::Convert;

=head1 DESCRIPTION

This package is regroups generic conversion methods for the CFG module reports.

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
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
%PLUGIN  = (
  cnv => [{blk => {
             database => [
               [qr/^Database Overview$/,
                 {'*' => 'database_overview'}],
               [qr/^V\$Database$/,
                 {'*' => 'database_details'}],
               [qr/^V\$Version$/,
                 {'*' => 'database_versions'}],
               [qr/^Database Connection Information$/,
                 {'*' => 'database_ping'}]],
             },
           nam => 'Custom Table Tags',
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
