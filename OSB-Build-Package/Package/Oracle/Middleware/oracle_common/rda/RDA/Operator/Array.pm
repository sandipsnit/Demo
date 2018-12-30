# Array.pm: Class Used for Managing Array Operators

package RDA::Operator::Array;

# $Id: Array.pm,v 2.5 2012/01/02 16:30:49 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Operator/Array.pm,v 2.5 2012/01/02 16:30:49 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Operator::Array - Class Used for Managing Array Operators

=head1 SYNOPSIS

require RDA::Operator::Array;

=head1 DESCRIPTION

This package regroups the definition of the array operators.

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
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_ini = (
  '.array.' => \&_ini_array,
  '.index.' => \&_ini_index,
  '.list.'  => \&_ini_list,
  '.pget.'  => \&_ini_pget,
  '.pset.'  => \&_ini_pset,
  'pop'     => \&_ini_pop,
  'push'    => \&_ini_push,
  'shift'   => \&_ini_shift,
  'splice'  => \&_ini_splice,
  'unshift' => \&_ini_unshift,
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

=head1 OPERATOR DEFINITIONS

=head2 S<.array.($par)>

This operator transforms a list in an array.

=cut

sub _ini_array
{ my ($arg) = @_;

  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&_find_array,
    _get => \&_get_array,
    _lft => '',
    _set => \&set_error,
    _typ => '.array.',
    }, 'RDA::Value::Operator';
}

sub _find_array
{ my ($slf, $typ) = @_;

  (RDA::Value::Array::new_from_list($slf->{'arg'}->eval_value(1)));
}

sub _get_array
{ my ($slf, $flg) = @_;

  RDA::Value::Array::new_from_list($slf->{'arg'}->eval_value($flg));
}

=head2 S<.index.($par,$arg)>

This operator selects an array or list item. It supports multidimensional
arrays.

=cut

sub _ini_index
{ my ($par, $arg) = @_;

  bless {
    arg  => $arg,
    par  => $par,
    _del => \&_del_index,
    _fnd => \&_find_index,
    _get => \&_get_index,
    _lft => \&_is_lvalue,
    _set => \&_set_index,
    _typ => '.index.',
    }, 'RDA::Value::Operator';
}

sub _decode_index
{ my ($val) = @_;

  $val = $val->eval_value(1);
  return (map {_decode_index($_)} @$val) if $val->is_list;
  int($val->as_number);
}

sub _del_index
{ my ($slf) = @_;
  my ($obj, $off, $trc, $val, @tbl);

  # Validate the indexes
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_index($_)} @tbl;
  $off = pop(@tbl);

  # Get the parent object
  ($obj, $trc) = $slf->{'par'}->find_object('@');

  # Find the current object
  foreach my $itm (@tbl)
  { return() unless defined($obj->[$itm]) && $obj->[$itm]->is_defined;
    $obj = $obj->[$itm];
    return() unless $obj->is_array;
  }

  # Delete the value
  ($obj->[$off], $val) = ($VAL_UNDEF, $obj->[$off]) unless $off > $#$obj;
  (defined($val) ? $val : $VAL_UNDEF, $trc);
}

sub _find_index
{ my ($slf, $typ) = @_;
  my ($obj, $off, $trc, @tbl);

  # Validate the indexes
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_index($_)} @tbl;
  $off = pop(@tbl);

  # Find the current object
  ($obj, $trc) = $slf->{'par'}->find_object('@');
  if (defined($obj))
  { die "RDA-00900: Array expected\n" unless $obj->is_array;
    foreach my $itm (@tbl)
    { unless (defined($obj->[$itm]) && $obj->[$itm]->is_defined)
      { return () unless $typ;
        $obj->[$itm] = RDA::Value::Array->new;
      }
      $obj = $obj->[$itm];
      die "RDA-00900: Array expected\n" unless $obj->is_array;
    }
  }

  # Treat the last level
  unless ($typ)
  { return ($obj->[$off]) unless $off > $#$obj || $off < (-$#$obj - 1);
    return ();
  }
  unless (defined($obj->[$off]) && $obj->[$off]->is_defined)
  { $obj->[$off] = ($typ eq '@') ? RDA::Value::Array->new :
                   ($typ eq '%') ? RDA::Value::Assoc->new :
                                   $VAL_UNDEF;
  }
  ($obj->[$off], $trc);
}

sub _get_index
{ my ($slf, $flg) = @_;
  my ($rec, @tbl);

  # Validate the indexes
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_index($_)} @tbl;

  # Get the index value
  ($rec) = $slf->{'par'}->find_object;
  foreach my $off (@tbl)
  { return $VAL_UNDEF unless defined($rec) && $rec->is_defined;
    die "RDA-00900: Array expected\n" unless $rec->is_array;
    return $VAL_UNDEF if $off > $#$rec;
    $rec = $rec->[$off];
  }
  ref($rec) ? $rec->eval_value($flg) : $VAL_UNDEF;
}

sub _set_index
{ my ($slf, $typ, $val, $flg) = @_;
  my ($obj, $off, $trc, @tbl);

  # Adjust the value
  $val = shift(@$val) || $VAL_UNDEF if $typ;

  # Validate the indexes
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_index($_)} @tbl;
  $off = pop(@tbl);

  # Get the parent object
  ($obj, $trc) = $slf->{'par'}->find_object('@');
  die "RDA-00900: Array expected\n" unless $obj->is_array;

  # Find the current object
  foreach my $itm (@tbl)
  { $obj->[$itm] = RDA::Value::Array->new
      unless defined($obj->[$itm]) && $obj->[$itm]->is_defined;
    $obj = $obj->[$itm];
    die "RDA-00900: Array expected\n" unless $obj->is_array;
  }

  # Set the value
  if ($flg)
  { $val += $obj->[$off]->as_number if ref($obj->[$off]);
    $obj->[$off] = $val = RDA::Value::Scalar::new_number($val);
    $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
    return $val;
  }
  else
  { $obj->[$off] = $val->is_list
      ? RDA::Value::Scalar::new_number(scalar @$val)
      : $val;
  }
  $trc;
}

=head2 S<.list.($par)>

This operator transforms an array in a list.

=cut

sub _ini_list
{ my ($par) = @_;

  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_list,
    _get => \&_get_list,
    _lft => '?',
    _set => \&set_error,
    _typ => '.list.',
    }, 'RDA::Value::Operator';
}

sub _find_list
{ my ($slf, $typ) = @_;
  my ($trc, $val);

  ($val, $trc) = $slf->{'par'}->find_object($typ);
  ((defined($val) && $val->is_defined)
    ? RDA::Value::List::new_from_list($val)
    : RDA::Value::List->new, $trc);
}

sub _get_list
{ my ($slf, $flg) = @_;
  my ($val);

  ($val) = $slf->{'par'}->find_object;
  (defined($val) && $val->is_defined)
    ? RDA::Value::List::new_from_list($val)->eval_value($flg)
    : RDA::Value::List->new;
}

=head2 S<.pget.($par)>

This operator stores temporarily a property value.

=cut

sub _ini_pget
{ my ($par) = @_;

  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_pget,
    _get => \&get_error,
    _lft => '?',
    _set => \&set_error,
    _typ => '.pget.',
    }, 'RDA::Value::Operator';
}

sub _find_pget
{ my ($slf, $typ) = @_;
  my ($par);

  $par = $slf->{'par'};
  die "RDA-00903: Incompatible types\n"
    if $typ && $typ ne $par->{'var'};
  ($slf->{'val'} = $par->eval_value);
}

=head2 S<.pset.($par)>

This operator synchronizes the property value.

=cut

sub _ini_pset
{ my ($par) = @_;

  # Insert the .pget. operator
  $par->{'par'} = _ini_pget($par->{'par'});

  # Add the synchronisation request
  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_pset,
    _lft => '?',
    _set => \&set_error,
    _typ => '.pset.',
    }, 'RDA::Value::Operator';
}

sub _get_pset
{ my ($slf, $flg) = @_;
  my ($par, $val);

  $par = $slf->{'par'};
  $val = $par->eval_value($flg);
  $par = $par->{'par'};
  $par->{'par'}->assign_var($par->{'val'});
  $val;
}

=head2 S<pop(array[,$dft])>

This operator removes the last element from a list and returns it. It returns
the default value if the list is empty or if the value is not a list.

=cut

sub _ini_pop
{ my (undef, $nam, $arg) = @_;
  my ($dft, $par);

  # Validate the arguments
  die "RDA_00902: Missing array argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  $dft = shift(@$arg) || $VAL_UNDEF;
  die "RDA-00901: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  _check_property(bless {
    dft  => $dft,
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_pop,
    _get => \&_get_pop,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator');
}

sub _find_pop
{ (_get_pop(shift));
}

sub _get_pop
{ my ($slf, $flg) = @_;
  my ($tbl, $trc, $val);

  ($tbl, $trc) = $slf->{'par'}->find_object('@');
  die "RDA-00900: Array expected\n"
    unless defined($tbl) && $tbl->is_array;
  if (defined($val = pop(@$tbl)))
  { $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
    return $flg ? $val->eval_value(1) : $val;
  }
  $slf->{'dft'}->eval_value($flg);
}

=head2 S<push(@array,$val,...)>

This operator adds values at the end the list. When applicable, it merges lists.

=cut

sub _ini_push
{ my (undef, $nam, $arg) = @_;
  my ($par, $opt);

  # Validate the arguments
  die "RDA_00902: Missing array argument for '$nam'\n"
    unless ref($par = shift(@$arg));

  # Create the operator
  _check_property(bless {
    arg  => $arg,
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_push,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator');
}

sub _get_push
{ my ($slf) = @_;
  my ($cnt, $tbl, $trc);

  ($tbl, $trc) = $slf->{'par'}->find_object('@');
  die "RDA-00900: Array expected\n"
    unless defined($tbl) && $tbl->is_array;
  $cnt = push(@$tbl, @{$slf->{'arg'}->eval_value});
  $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
  RDA::Value::Scalar::new_number($cnt);
}

=head2 S<shift(@array[,$dft])>

This operator removes the first element from a list and returns it. It returns
the default value if the list is empty or if the value is not a list.

=cut

sub _ini_shift
{ my (undef, $nam, $arg) = @_;
  my ($dft, $par);

  # Validate the arguments
  die "RDA_00902: Missing array argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  $dft = shift(@$arg) || $VAL_UNDEF;
  die "RDA-00901: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  _check_property(bless {
    dft  => $dft,
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_shift,
    _get => \&_get_shift,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator');
}

sub _find_shift
{ (_get_shift(shift));
}

sub _get_shift
{ my ($slf, $flg) = @_;
  my ($val, $tbl, $trc);

  ($tbl, $trc) = $slf->{'par'}->find_object('@');
  die "RDA-00900: Array expected\n"
    unless defined($tbl) && $tbl->is_array;
  if (defined($val = shift(@$tbl)))
  { $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
    return $flg ? $val->eval_value(1) : $val;
  }
  $slf->{'dft'}->eval_value($flg);
}

=head2 S<splice(@array,$offset,$length[,value...])>

This operator removes the elements designated by the offset and the length from
an array, and replaces them with the specified values, if any.

It returns the elements removed from the array as a list.

If the offset is negative then it starts that far from the end of the array. If
the length is omitted, it removes everything from the offset onward. If the
length is negative, it removes the elements from the offset onward except for
-length elements at the end of the array. If both offset and length are
omitted, it removes everything.

=cut

sub _ini_splice
{ my (undef, $nam, $arg) = @_;
  my ($lgt, $off, $par, @tbl);

  # Validate the arguments
  die "RDA_00902: Missing array argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  $off = shift(@$arg) || $VAL_ZERO;
  @tbl = (lgt => $lgt) if defined($lgt = shift(@$arg));

  # Create the operator
  _check_property(bless {
    @tbl,
    arg  => $arg,
    off  => $off,
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_splice,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator');
}

sub _get_splice
{ my ($slf, $flg) = @_;
  my ($arg, $tbl, $trc, $val);

  ($tbl, $trc) = $slf->{'par'}->find_object('@');
  die "RDA-00900: Array expected\n"
    unless defined($tbl) && $tbl->is_array;
  $arg = $slf->{'arg'}->eval_value($flg);
  $val = RDA::Value::List->new(splice(@$tbl, $slf->{'off'}->eval_as_scalar,
    exists($slf->{'lgt'}) ? $slf->{'lgt'}->eval_as_scalar : scalar @$tbl,
    @$arg));
  $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
  $val;
}

=head2 S<unshift(@array,$value,...)>

This operator prepends specified values to the front of the array and returns
the new number of elements in the array.

=cut

sub _ini_unshift
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Validate the arguments
  die "RDA_00902: Missing array argument for '$nam'\n"
    unless ref($par = shift(@$arg));

  # Create the operator
  _check_property(bless {
    arg  => $arg,
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_unshift,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator');
}

sub _get_unshift
{ my ($slf) = @_;
  my ($cnt, $tbl, $trc);

  ($tbl, $trc) = $slf->{'par'}->find_object('@');
  die "RDA-00900: Array expected\n"
    unless defined($tbl) && $tbl->is_array;
  $cnt = unshift(@$tbl, @{$slf->{'arg'}->eval_value});
  $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
  RDA::Value::Scalar::new_number($cnt);
}

# --- Common routines ---------------------------------------------------------

# Convert the operator to perform complex operations on properties
sub _check_property
{ my ($slf) = @_;

  (ref($slf->{'par'}) eq 'RDA::Value::Property')  ? _ini_pset($slf) : $slf;
}

# Test a left value
sub _is_lvalue
{ shift->{'par'}->is_lvalue ? '$' : '';
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Array|RDA::Value::Array>,
L<RDA::Value::Assoc|RDA::Value::Assoc>,
L<RDA::Value::Hash|RDA::Value::Hash>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Operator|RDA::Value::Operator>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
