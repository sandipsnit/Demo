# Scalar.pm: Class Used for Managing Scalar Operators

package RDA::Operator::Scalar;

# $Id: Scalar.pm,v 2.4 2012/01/02 16:30:49 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Operator/Scalar.pm,v 2.4 2012/01/02 16:30:49 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Operator::Scalar - Class Used for Managing Scalar Operators

=head1 SYNOPSIS

require RDA::Operator::Scalar;

=head1 DESCRIPTION

This package regroups the definition of the scalar operators.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Operator;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_ini = (
  'concat' => \&_ini_concat,
  'decr'   => \&_ini_decr,
  'incr'   => \&_ini_incr,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Operator::Value-E<gt>load($tbl)>

This method loads the operator definition in the operator table.

=cut

sub load
{ my ($cls, $tbl) = @_;

  foreach my $nam (keys(%tb_ini))
  { $tbl->{$nam} = $tb_ini{$nam};
  }
}

=head1 VALUE RELATED OPERATORS

=head2 S<concat($str,...)>

This macro concatenates all text strings specified as arguments into a new
text string. It ignores invalid arguments.

=cut

sub _ini_concat
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_concat,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_concat
{ RDA::Value::Scalar::new_text(join('', grep {defined($_) && !ref($_)}
    shift->{'arg'}->eval_as_array));
}

=head2 S<decr(var[,value])>

This operator decrements a variable and returns the resulting value.

=cut

sub _ini_decr
{ my (undef, $nam, $arg) = @_;
  my ($val, $var);

  # Validate the arguments
  die "RDA-00920: Missing scalar variable\n"
    unless ref($var = shift(@$arg)) && $var->is_scalar_lvalue;
  $val = shift(@$arg) || $VAL_ONE;
  die "RDA-00921: Extra value(s) found for '$nam'\n" if @$arg;

  # Create the operator
  bless {
    val  => $val,
    var  => $var,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_decr,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_decr
{ my ($slf) = @_;

  $slf->{'var'}->decr_value($slf->{'val'}->eval_as_number);
}

=head2 S<incr(var[,value])>

This operator increments a variable and returns the resulting value.

=cut

sub _ini_incr
{ my (undef, $nam, $arg) = @_;
  my ($val, $var);

  # Validate the arguments
  die "RDA-00920: Missing scalar variable\n"
    unless ref($var = shift(@$arg)) && $var->is_scalar_lvalue;
  $val = shift(@$arg) || $VAL_ONE;
  die "RDA-00921: Extra value(s) found for '$nam'\n" if @$arg;

  # Create the operator
  bless {
    val  => $val,
    var  => $var,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_incr,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_incr
{ my ($slf) = @_;

  $slf->{'var'}->incr_value($slf->{'val'}->eval_as_number);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Operator|RDA::Value::Operator>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
