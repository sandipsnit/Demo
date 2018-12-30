# Expr.pm: Class Used for Numeric Expression Macros

package RDA::Library::Expr;

# $Id: Expr.pm,v 2.5 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Expr.pm,v 2.5 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Expr - Class Used for Numeric Expression Macros

=head1 SYNOPSIS

require RDA::Library::Expr;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Expr> class are used to interface with
numeric expression-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $NUMBER = qr/^[+-]?(\d+(\.\d*)?|\.\d+)([eE][\+\-]?\d+)?$/;

my %tb_fct = (
  'compute'  => [\&_m_compute,   'N'],
  'expr'     => [\&_m_expr,      'N'],
  'frac'     => [\&_m_frac,      'L'],
  'int'      => [\&_m_int,       'N'],
  'isNumber' => [\&_m_is_number, 'N'],
  'max'      => [\&_m_max,       'N'],
  'min'      => [\&_m_min,       'N'],
  'num'      => [\&_m_num,       'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Expr-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Expr> is represented by a blessed hash reference. The following
special key is used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=back

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)]);

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}->[0]}($slf, @arg);
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context. Code values are executed.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 NUMERIC EXPRESSION MACROS

=head2 S<compute($str)>

This macro computes the specified expression. It returns an undefined value in
case of errors or when the string contains invalid characters.

=cut

sub _m_compute
{ my ($slf, $ctx, $str) = @_;
  my ($ret);

  if (defined($str) && $str !~/[\;\$\%\@\[\]\{\}\#]/)
  { $ret = eval "$str";
    return $ret unless $@;
  }
  undef;
}

=head2 S<expr($op,$num1,$num2)>

This macro performs a given operation on the two numbers specified as
arguments. The supported operations are as follows:

=over 12

=item S<    B<'+' > > Sum of C<$num1> and C<$num2>

=item S<    B<'-' > > Difference between C<$num1> and C<$num2>

=item S<    B<'*' > > Product of C<$num1> and C<$num2>

=item S<    B<'/' > > Quotient of C<$num1> by C<$num2>

=item S<    B<'%' > > Modulus of C<$num1> by C<$num2>

=item S<    B<'E<lt>E<lt>'> > C<$num1> left shifted by C<$num2> bits

=item S<    B<'E<gt>E<gt>'> > C<$num1> right shifted by C<$num2> bits

=item S<    B<'E<amp>' > > Bitwise AND of C<$num1> and C<$num2>

=item S<    B<'|' > > Bitwise OR of C<$num1> and C<$num2>

=item S<    B<'^' > > Bitwise Exclusive OR of C<$num1> and C<$num2>

=item S<    B<'=='> > True if C<$num1> equals to C<$num2>

=item S<    B<'E<lt>E<gt>'> > True if C<$num1> differs from C<$num2>

=item S<    B<'E<lt>' > > True if C<$num1> is less than C<$num2>

=item S<    B<'E<lt>='> > True if C<$num1> is less than or equals to C<$num2>

=item S<    B<'E<gt>' > > True if C<$num1> is greater than C<$num2>

=item S<    B<'E<gt>='> > True if C<$num1> is greater than or equals to C<$num2>

=back

=cut

sub _m_expr
{ my ($slf, $ctx, $op, $num1, $num2) = @_;

  if (defined($num1) && defined($num2))
  { return $num1 + $num2  if $op eq '+';
    return $num1 - $num2  if $op eq '-';
    return $num1 * $num2  if $op eq '*';
    return $num1 / $num2  if $op eq '/';
    return $num1 % $num2  if $op eq '%';
    return int($num1) << int($num2) if $op eq '<<';
    return int($num1) >> int($num2) if $op eq '>>';
    return int($num1) & int($num2)  if $op eq '&';
    return int($num1) | int($num2)  if $op eq '|';
    return int($num1) ^ int($num2)  if $op eq '^';
    return $num1 == $num2 if $op eq '==';
    return $num1 != $num2 if $op eq '<>';
    return $num1 < $num2  if $op eq '<';
    return $num1 <= $num2 if $op eq '<=';
    return $num1 > $num2  if $op eq '>';
    return $num1 >= $num2 if $op eq '>=';
  }
  0;
}

=head2 S<frac($num[,$flg])>

This macro splits the integer and decimal parts of a number. When the flag is
set, the decimal part is always positive.

=cut

sub _m_frac
{ my ($slf, $ctx, $num, $flg) = @_;
  my ($dec, $int);

  return () unless defined($num);
  $dec = $num - ($int = int($num));
  if ($flg && $dec < 0)
  { $dec += 1.;
    --$int;
  }
  ($int, $dec);
}

=head2 S<int($num)>

This macro returns the integer part of a number.

=cut

sub _m_int
{ my ($slf, $ctx, $num) = @_;

  defined($num) ? int($num) : undef;
}

=head2 S<isNumber($str)>

This macro indicates whether the string represents a number.

=cut

sub _m_is_number
{ my ($slf, $ctx, $str) = @_;

  defined($str) && $str =~ $NUMBER;
}

=head2 S<max($num,...)>

This macro returns the maximum value of the specified arguments.

=cut

sub _m_max
{ my $slf = shift;
  my $ctx = shift;
  my $max;

  foreach my $val (@_)
  { next unless defined($val);
    $max = $val unless defined($max) && $max >= $val;
  }
  $max;
}

=head2 S<min($num,...)>

This macro returns the minimum value of the specified arguments.

=cut

sub _m_min
{ my $slf = shift;
  my $ctx = shift;
  my $min;

  foreach my $val (@_)
  { next unless defined($val);
    $min = $val unless defined($min) && $min <= $val;
  }
  $min;
}

=head2 S<num($str[,$dft])>

This macro converts a string in a number. It uses the default value when the
string does not represent a valid number format.

=cut

sub _m_num
{ my ($slf, $ctx, $str, $dft) = @_;

  (defined($str) && $str =~ $NUMBER) ? 0 + $str : $dft;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
