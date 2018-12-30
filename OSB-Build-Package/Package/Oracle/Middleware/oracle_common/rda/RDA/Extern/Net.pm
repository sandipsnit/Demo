# Net.pm: Net Routines

package RDA::Extern::Net;

# $Id: Net.pm,v 2.5 2012/01/02 16:32:38 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extern/Net.pm,v 2.5 2012/01/02 16:32:38 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Extern::Net - Net Routines

=head1 SYNOPSIS

require RDA::Extern::Net;

=head1 DESCRIPTION

The following method is available:

=cut

use strict;

BEGIN
{ use Exporter;
  use Socket;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Extern::Net::reverse_lookup($ctx,$hst)>

This method gets the reverse lookup information.

=cut

sub reverse_lookup
{ my ($ctx, $hst) = @_;
  my ($alt, $nam, $rpt, @adr);

  if ($rpt = $ctx->get_report)
  { ($nam, $alt, undef, undef, @adr) = gethostbyname($hst);
    $rpt->write("|*Host Name*|".$nam." |\n");
    if (ref($alt) eq 'ARRAY')
    { $rpt->write("|*Aliases*|".join('%BR%', @$alt)." |\n");
    }
    else
    { $rpt->write("|*Aliases*|".$alt." |\n");
    }
    foreach my $adr (@adr)
    { $rpt->write('|*Reverse Lookup of '.inet_ntoa($adr)."*|"
       .gethostbyaddr($adr, AF_INET)." |\n");
    }
  }
  1;
}

1;

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
