# Global.pm: Class Used for Managing Global Variables

package RDA::Value::Global;

# $Id: Global.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Global.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Global - Class Used for Managing Global Variables

=head1 SYNOPSIS

require RDA::Value::Global;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Global> class are used to manage global
variables.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Global-E<gt>new($ctx,$nam)>

The object constructor. It takes the execution context reference and the
variable name as extra arguments.

A C<RDA::Value::Global> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'ctx' > > Reference to the execution context

=item S<    B<'nam' > > Variable name

=item S<    B<'var' > > Variable type

=back

=cut

sub new
{ my ($cls, $ctx, $nam) = @_;

  # Create the variable value object and return its reference
  bless {
    ctx => $ctx,
    nam => $nam,
    var => substr($nam, 0, 1),
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the value dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;

  $lvl = 0  unless defined($lvl);
  $txt = '' unless defined($txt);

  $slf->dump_object({}, $lvl, $txt, '');
}

sub dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;

  '  ' x $lvl.$txt."Global=".$slf->{'nam'};
}


=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>eval_value([$flg])>

This method resolves a variable. When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;

  $slf->{'ctx'}->get_object($slf->{'nam'})->eval_value($flg);
}

# --- Find object mechanim ----------------------------------------------------

sub find_object
{ my ($slf, $typ) = @_;
  my $val;

  # Treat a request without creating the variable
  return ($slf->{'ctx'}->get_object($slf->{'nam'}))
    unless $typ;

  # Get the variable value, creating the variable when needed
  die "RDA-00820: Incompatible types\n"
    unless $slf->{'var'} eq $typ || $slf->{'var'} eq '$';
  $val = $slf->{'ctx'}->get_object($slf->{'nam'});
  return ($val, [$slf->{'ctx'}, $slf->{'nam'}, $val]);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
