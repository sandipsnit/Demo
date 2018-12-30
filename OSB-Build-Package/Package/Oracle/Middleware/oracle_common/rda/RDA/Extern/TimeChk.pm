# TimeChk.pm: Time Check Routines

package RDA::Extern::TimeChk;

# $Id: TimeChk.pm,v 2.5 2012/01/02 16:32:39 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extern/TimeChk.pm,v 2.5 2012/01/02 16:32:39 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Extern::Timecheck - Time Check Routines

=head1 SYNOPSIS

require RDA::Extern::TimeChk;

=head1 DESCRIPTION

The following method is available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Extern::TimeChk::check_clock($ctx[,$cnt])>

This method checks for monotonically increasing time. You can specify the
number of clock checks as an argument. It does 1000000 tests by default. It
returns an empty string on successful completion, or otherwise, an error
message.

=cut

sub check_clock
{ my ($ctx, $cnt) = @_;
  my ($cur, $dif, $prv);

  eval "require Time::HiRes";
  return "Not available: $@" if $@;

  $cnt = 1000000 unless defined($cnt);
  $prv = [Time::HiRes::gettimeofday()];
  for (1..$cnt)
  { $cur = [Time::HiRes::gettimeofday()];
    return sprintf('Time went backwards: %d.%06d -> %d.%06d', @$prv, @$cur)
      if Time::HiRes::tv_interval($prv, $cur) < 0;
    $prv = $cur;
  }
  '';
}

1;

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
