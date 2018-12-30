# Proto.pm: Class Used as External Perl Macro Prototype

package RDA::Extern::Proto;

# $Id: Proto.pm,v 2.4 2012/01/02 16:32:39 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extern/Proto.pm,v 2.4 2012/01/02 16:32:39 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Extern::Proto - Class Used as External Perl Macro Prototype

=head1 SYNOPSIS

require RDA::Proto;

=head1 DESCRIPTION

Objects of the C<RDA::Extern::Proto> class can be used as example of external
Perl macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Extern::Proto::dump($ctx[,$arg,...])>

The routine dumps the argument list.

=cut

sub dump
{ my $ctx = shift;
 
  RDA::Value::convert_value({'@_' => [@_]})->dump;
}

=head2 S<RDA::Extern::Proto::version($typ)>

The routine reports the module version.

=cut

sub version
{ my ($ctx, $typ) = @_;
  my ($maj, $min) = split(/\./, $VERSION);

  if ($typ)
  { return [$VERSION, undef, $maj, $min] if $typ eq 'A';
    return [{Version => [$maj, $min]}]   if $typ eq 'C';
    return {Version => [$maj, $min]}     if $typ eq 'H';
    return undef                         if $typ eq 'U';
  }
  $VERSION;
}

=head2 S<RDA::Extern::Proto::write($ctx[,$arg,...])>

The routine writes the arguments in the current report. Arguments other than
numbers and strings are simply ignored. An end of line is added at the end of
the resulting string.

=cut

sub write
{ my $ctx = shift;
  my $rpt;

  ($rpt = $ctx->get_report)
    ? $rpt->write(join('', grep {$_ && !ref($_)} @_)."\n")
    : undef;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>, L<RDA::Block|RDA::Block>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
