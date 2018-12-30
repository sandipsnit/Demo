# Internal.pm: Class Used for Managing Internal Variables

package RDA::Value::Internal;

# $Id: Internal.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Internal.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Internal - Class Used for Managing Internal Variables

=head1 SYNOPSIS

require RDA::Value::Internal;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Internal> class are used to manage internal
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

# Define the global private variables
my %tb_key = (
  'error' => 'err',
  'last'  => 'val',
  'line'  => 'lin',
  'self'  => 'slf',
  );
my %tb_lft = (
  'error' => '',
  'last'  => '',
  'line'  => '',
  'self'  => '$',
  );
my %tb_var = (
  'error' => '@',
  'last'  => undef,
  'line'  => '$',
  'self'  => '$',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Internal-E<gt>new($ctx,$nam)>

The object constructor. It takes the execution context reference and the
variable name as extra arguments.

A C<RDA::Value::Internal> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'ctx' > > Reference to the execution context

=item S<    B<'key' > > Variable key

=item S<    B<'nam' > > Variable name

=item S<    B<'var' > > Variable type

=back

=cut

sub new
{ my ($cls, $ctx, $nam) = @_;

  die "RDA-00833: Invalid internal variable name '$nam'\n"
    unless exists($tb_key{$nam});

  # Create the variable value object and return its reference
  bless {
    ctx => $ctx,
    key => $tb_key{$nam},
    nam => $nam,
    var => $tb_var{$nam},
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

  '  ' x $lvl.$txt."Internal=".$slf->{'nam'};
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value.

=cut

sub is_lvalue
{ $tb_lft{shift->{'nam'}};
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>eval_value([$flg])>

This method resolves a variable. When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;

  $slf->{'ctx'}->get_internal($slf->{'key'})->eval_value($flg);
}

# --- Find object mechanim ----------------------------------------------------

sub find_object
{ my ($slf, $typ) = @_;
  my $val;

  # Treat a request without creating the variable
  return ($slf->{'ctx'}->get_internal($slf->{'key'}))
    unless $typ;

  # Get the variable value, creating the variable when needed
  die "RDA-00820: Incompatible types\n"
    unless !defined($slf->{'var'})
    || $slf->{'var'} eq $typ
    || $slf->{'var'} eq '$';
  $val = $slf->{'ctx'}->get_internal($slf->{'key'}, 1, ".$typ");
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
