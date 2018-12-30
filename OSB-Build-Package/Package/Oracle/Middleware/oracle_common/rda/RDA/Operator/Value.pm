# Value.pm: Class Used for Managing Value Operators

package RDA::Operator::Value;

# $Id: Value.pm,v 2.9 2012/08/13 14:17:02 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Operator/Value.pm,v 2.9 2012/08/13 14:17:02 mschenke Exp $
#
# Change History
# 20120813  MSC  Introduce the current calling block concept.

=head1 NAME

RDA::Operator::Value - Class Used for Managing Value Operators

=head1 SYNOPSIS

require RDA::Operator::Value;

=head1 DESCRIPTION

This package regroups the definition of the value operators.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use RDA::Block qw($DIE);
  use RDA::Value::Operator;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.9 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_grp = (
  b  => \&_grep_b,
  bv => \&_grep_bv,
  d  => \&_grep_d,
  dv => \&_grep_dv,
  f  => \&_grep_f,
  fv => \&_grep_fv,
  );
my %tb_ini = (
  '.alias.'  => \&_ini_alias,
  '.assign.' => \&_ini_assign,
  '.macro.'  => \&_ini_macro,
  '.method.' => \&_ini_method,
  'and'      => \&_ini_and,
  'check'    => \&_ini_check,
  'code'     => \&_ini_code,
  'cond'     => \&_ini_cond,
  'copy'     => \&_ini_copy,
  'defined'  => \&_ini_defined,
  'delete'   => \&_ini_delete,
  'dump'     => \&_ini_dump,
  'eval'     => \&_ini_eval,
  'exists'   => \&_ini_exists,
  'first'    => \&_ini_first,
  'grep'     => \&_ini_grep,
  'list'     => \&_ini_list,
  'missing'  => \&_ini_missing,
  'not'      => \&_ini_not,
  'nvl'      => \&_ini_nvl,
  'or'       => \&_ini_or,
  'property' => \&_ini_property,
  'ref'      => \&_ini_ref,
  'reverse'  => \&_ini_reverse,
  'scalar'   => \&_ini_scalar,
  );
my %tb_ref = (
  '$'                 => RDA::Value::Scalar::new_text('SCALAR'),
  '@'                 => RDA::Value::Scalar::new_text('ARRAY'),
  '%'                 => RDA::Value::Scalar::new_text('HASH'),
  'RDA::Value::Array' => RDA::Value::Scalar::new_text('ARRAY'),
  'RDA::Value::Assoc' => RDA::Value::Scalar::new_text('HASH'),
  'RDA::Value::Code'  => RDA::Value::Scalar::new_text('CODE'),
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

=head1 INTERNAL OPERATORS

=head2 S<.alias.($blk,$par,$nam,$arg)>

This operator executes an object method defined through an alias.

=cut

sub _ini_alias
{ my ($blk, $def, $arg) = @_;
  my ($cls, $nam, $par);

  ($cls, $nam) = @$def;
  return $VAL_UNDEF unless ref($par = shift(@$arg));
  bless {
    arg  => $arg,
    cls  => $cls,
    nam  => $nam,
    par  => $par,
    _blk => $blk,
    _del => \&del_error,
    _fnd => \&_find_alias,
    _get => \&_get_alias,
    _lft => '',
    _set => \&set_error,
    _typ => '.alias.',
    }, 'RDA::Value::Operator';
}

sub _find_alias
{ (_get_alias(shift));
}

sub _get_alias
{ my ($slf, $flg) = @_;
  my ($cls, $obj);

  $obj = $slf->{'par'}->eval_value(1);
  $obj = $obj->[0] if $obj->is_list;
  return $VAL_UNDEF unless defined($obj);
  die "RDA-00936: Object required to invoke a method\n"
    unless $obj->has_methods;
  $obj->eval_method($slf->{'_blk'}, $slf->{'nam'}, $slf->{'arg'}, $flg);
}

=head2 S<.assign.($nam,$arg)>

This operator assigns the value to the specified variables and returns the
value.

=cut

sub _ini_assign
{ my ($var, $val) = @_;

  # Validate the arguments
  die "RDA-00934: Invalid left value to assign\n" unless $var->is_lvalue;
  die "RDA-00939: Missing right value\n" unless ref($val);

  # Create the operator
  bless {
    val  => $val,
    var  => $var,
    _del => \&del_error,
    _fnd => \&_find_assign,
    _get => \&_get_assign,
    _lft => \&_left_assign,
    _set => \&set_error,
    _typ => '.assign.',
    }, 'RDA::Value::Operator';
}

sub _find_assign
{ (_get_assign(shift));
}

sub _get_assign
{ my ($slf, $flg) = @_;
  my ($val);

  $val = $slf->{'var'}->assign_value($slf->{'val'});
  $flg ? $val->eval_value(1) : $val;
}

sub _left_assign
{ shift->{'val'}->is_lvalue;
}

=head2 S<.macro.($blk,$nam,$arg)>

This operator transforms an array in a list.

=cut

sub _ini_macro
{ my ($blk, $nam, $arg) = @_;
 
  bless {
    arg  => $arg,
    nam  => $nam,
    _blk => $blk,
    _del => \&del_error,
    _fnd => \&_find_macro,
    _get => \&_get_macro,
    _lft => '',
    _set => \&set_error,
    _typ => '.macro.',
    }, 'RDA::Value::Operator';
}

sub _find_macro
{ (_get_macro(shift));
}

sub _get_macro
{ my ($slf, $flg) = @_;
  my ($blk, $def, $lib, $nam, $val);

  # Determine the macro or library definition
  $nam = $slf->{'nam'};
  if ($nam =~ m/^caller:(.*)$/)
  { $nam = $1;
    $blk = $slf->{'_blk'}->get_current;
  }
  else
  { $blk = $slf->{'_blk'};
  }
  $lib = $blk->get_lib;
  die "RDA-00937: Undefined macro '$nam'\n" unless exists($lib->{$nam});
  $def = $lib->{$nam};

  # Execute the macro but do not yet evaluate its arguments
  eval {$val = $def->run($nam, $slf->{'arg'}, $blk)};
  return $flg ? $val->eval_value(1) : $val if ref($val);

  # Propagate the error
  if ($@ =~ $DIE)
  { die $@ if $1 ne 'B';
  }
  elsif ($@)
  { $blk->gen_exec_err($@);
  }
  die "RDA-00938: Error encountered in the macro '$nam' called\n";
}

=head2 S<.method.($blk,$par,$nam,$arg)>

This operator executes an object method.

=cut

sub _ini_method
{ my ($blk, $par, $nam, $arg) = @_;

  bless {
    arg  => $arg,
    nam  => $nam,
    par  => $par,
    _blk => $blk,
    _del => \&del_error,
    _fnd => \&_find_method,
    _get => \&_get_method,
    _lft => '',
    _set => \&set_error,
    _typ => '.method.',
    }, 'RDA::Value::Operator';
}

sub _find_method
{ (_get_method(shift));
}

sub _get_method
{ my ($slf, $flg) = @_;
  my ($obj);

  $obj = $slf->{'par'}->eval_value(1);
  $obj = $obj->[0] if $obj->is_list;
  return $VAL_UNDEF unless defined($obj);
  die "RDA-00936: Object required to invoke a method\n"
    unless $obj->has_methods;
  $obj->eval_method($slf->{'_blk'}, $slf->{'nam'}, $slf->{'arg'}, $flg);
}

=head1 CONDITION RELATED OPERATORS

=head2 S<and(value,...)>

This operator returns 1 when all elements in the argument list are equivalent
to true. Otherwise, it returns 0. It executes code values. When an argument is
false, the remaining arguments are not evaluated.

=cut

sub _ini_and
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_and,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_and
{ my ($slf) = @_;

  foreach my $itm (@{$slf->{'arg'}})
  { return $VAL_ZERO unless $itm->eval_as_scalar;
  }
  $VAL_ONE;
}

=head2 S<copy(value,flag)>

This operator returns a copy of the data structure. When the flag is set, it
evaluates values.

=cut

sub _ini_copy
{ my (undef, $nam, $arg) = @_;
  my ($flg, $val);

  # Validate the argument
  return $VAL_UNDEF, unless ($val = shift(@$arg));
  $flg = shift(@$arg) || $VAL_ZERO;
  die "RDA-00931: Extra value(s) found for '$nam'\n" if @$arg;

  # Create the operator
  bless {
    flg  => $flg,
    val  => $val,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_copy,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_copy
{ my ($slf) = @_;

  $slf->{'val'}->eval_value(1)->copy_value($slf->{'flg'}->eval_as_scalar);
}

=head2 S<defined(value,...)>

This operator returns 1 when all arguments are not undefined. Otherwise, it
returns 0. It executes code values. When an argument is not defined, it does
not evaluate the remaining arguments.

=cut


sub _ini_defined
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_defined,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_defined
{ my ($slf) = @_;

  foreach my $itm (@{$slf->{'arg'}})
  { return $VAL_ZERO unless $itm->eval_value(1)->is_defined;
  }
  $VAL_ONE;
}

=head2 S<not(value)>

This operator returns 1 when the argument is equivalent to false, or otherwise,
0. It executes code values.

=cut


sub _ini_not
{ my (undef, $nam, $arg) = @_;
  my ($val);

  # Validate the arguments
  return $VAL_ZERO unless ref($val = shift(@$arg));
  die "RDA-00931: Extra value(s) found for '$nam'\n" if @$arg;

  # Create the operator
  bless {
    val  => $val,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_not,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_not
{ my ($slf) = @_;

  $slf->{'val'}->eval_as_scalar ? $VAL_ZERO : $VAL_ONE;
}

=head2 S<or(value,...)>

This operator returns 1 when at least one element in the argument list is
equivalent to true. Otherwise, it returns 0. It executes code values. When an
argument is true, it does not evaluate the remaining arguments.

=cut

sub _ini_or
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_or,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}


sub _get_or
{ my ($slf) = @_;

  foreach my $itm (@{$slf->{'arg'}})
  { return $VAL_ONE if $itm->eval_as_scalar;
  }
  $VAL_ZERO;
}

=head1 VALUE RELATED OPERATORS

=head2 S<check(str[,re1,expr1[,...]][default])>

This operator checks for the first matching regular expression. When a match is
found, it evaluates the corresponding expression and it returns the result. You
can define a default return value as an extra argument. If the default value is
omitted, it returns an undefined value. It only evaluates arguments when
required.

=cut

sub _ini_check
{ my (undef, $nam, $arg) = @_;
  my ($str);

  # Validate the arguments
  return $VAL_UNDEF unless ref($str = shift(@$arg));

  # Create the operator
  bless {
    arg  => $arg,
    str  => $str,
    _del => \&del_error,
    _fnd => \&_find_check,
    _get => \&_get_check,
    _lft => \&_left_pair,
    _set => \&_set_check,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _find_check
{ my ($slf, $typ) = @_;
  my ($pat, $str, $val, @tbl);

  $str = $slf->{'str'}->eval_as_string;
  @tbl = @{$slf->{'arg'}};
  while (($pat, $val) = splice(@tbl, 0, 2))
  { return $pat->find_object($typ) unless defined($val);
    $pat = $pat->eval_as_scalar;
    return $val->find_object($typ) if $str =~ qr#$pat#;
  }
  ();
}

sub _get_check
{ my ($slf, $flg) = @_;
  my ($pat, $str, $val, @tbl);

  $str = $slf->{'str'}->eval_as_string;
  @tbl = @{$slf->{'arg'}};
  while (($pat, $val) = splice(@tbl, 0, 2))
  { return $pat->eval_value($flg) unless defined($val);
    $pat = $pat->eval_as_scalar;
    return $val->eval_value($flg) if $str =~ qr#$pat#;
  }
  $VAL_UNDEF;
}

sub _set_check
{ my ($slf, $typ, @arg) = @_;
  my ($pat, $str, $val, @tbl);

  $str = $slf->{'str'}->eval_as_string;
  @tbl = @{$slf->{'arg'}};
  while (($pat, $val) = splice(@tbl, 0, 2))
  { return $typ ? $pat->assign_item(@arg) : $pat->assign_var(@arg)
      unless defined($val);
    $pat = $pat->eval_as_scalar;
    return $typ ? $val->assign_item(@arg) : $val->assign_var(@arg)
      if $str =~ qr#$pat#;
  }
  undef;
}

=head2 S<code(arg,...)>

This operators constructs a code value based on the specified arguments without
evaluating them.

=cut

sub _ini_code
{ my ($blk, undef, $arg) = @_;

  RDA::Value::Code::new_code($blk->get_context, $arg);
}

=head2 S<cond([cond1,expr1,...][default])>

This operator evaluates the conditions successively until a true condition is
encountered. It executes code values. When a true condition is found, it
evaluates the corresponding expression and it returns the result. You can
specify a default return value as an extra argument. If the default value is
omitted, it returns an undefined value. It only avaluates arguments when
required.

=cut

sub _ini_cond
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&_find_cond,
    _get => \&_get_cond,
    _lft => \&_left_pair,
    _set => \&_set_cond,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _find_cond
{ my ($slf, $typ) = @_;
  my ($cnd, $val, @tbl);

  @tbl = @{$slf->{'arg'}};
  while (($cnd, $val) = splice(@tbl, 0, 2))
  { return $cnd->find_object($typ) unless defined($val);
    return $val->find_object($typ) if $cnd->eval_as_scalar;
  }
  ();
}

sub _get_cond
{ my ($slf, $flg) = @_;
  my ($cnd, $val, @tbl);

  @tbl = @{$slf->{'arg'}};
  while (($cnd, $val) = splice(@tbl, 0, 2))
  { return $cnd->eval_value($flg) unless defined($val);
    return $val->eval_value($flg) if $cnd->eval_as_scalar;
  }
  $VAL_UNDEF;
}

sub _set_cond
{ my ($slf, $typ, @arg) = @_;
  my ($cnd, $val, @tbl);

  @tbl = @{$slf->{'arg'}};
  while (($cnd, $val) = splice(@tbl, 0, 2))
  { return $typ ? $cnd->assign_item(@arg) : $cnd->assign_var(@arg)
      unless defined($val);
    return $typ ? $val->assign_item(@arg) : $val->assign_var(@arg)
      if $cnd->eval_as_scalar;
  }
  undef;
}

=head2 S<delete(var,...)>

This operator deletes some left values and returns their previous content.

=cut

sub _ini_delete
{ my (undef, $nam, $arg) = @_;

  # Validate the arguments
  die "RDA-00935: Invalid left value to delete for '$nam'\n"
    unless $arg->is_lvalue;
  $arg = $arg->[0] if (scalar @$arg) == 1;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_delete,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_delete
{ shift->{'arg'}->delete_value;
}

=head2 S<dump(value)>

This operator returns the dump of the value specifies as an argument.

=cut

sub _ini_dump
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Validate the arguments
  die "RDA-00932: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  die "RDA-00931: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_dump,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_dump
{ RDA::Value::Scalar::new_text(shift->{'par'}->eval_value->dump);
}

=head2 S<eval(arg,...)>

This operator evaluates each value from the argument list. It executes code
values. It returns the last result.

=cut

sub _ini_eval
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_eval,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_eval
{ my ($slf) = @_;
  my ($ret);

  $ret = $VAL_UNDEF;
  foreach my $itm (@{$slf->{'arg'}})
  { $ret = $itm->eval_value(1);
  }
  $ret;
}

=head2 S<exists($var)>, S<exists($var[value...])>, or exists($var{value...})>

This operator indicates when a variable, an array index, or a hash key exists.

=cut

sub _ini_exists
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Validate the arguments
  die "RDA-00932: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  die "RDA-00933: Invalid first argument for '$nam'\n"
    unless $par->is_lvalue;
  die "RDA-00931: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_exists,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_exists
{ my ($slf) = @_;

  my ($obj) = $slf->{'par'}->find_object;
  defined($obj) ? $VAL_ONE : $VAL_ZERO;
}

=head2 S<first(arg,...)>

This operator evaluates its argument list and returns the first value from that
list or an undefined value when the list is empty. It executes code values.

=cut

sub _ini_first
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_first,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_first
{ shift->{'arg'}->eval_value(1)->[0] || $VAL_UNDEF;
}

=head2 S<grep(@var,cond[,$opt])> or grep(%var,cond[,$opt])

This operator evaluates the specified condition for each array value or the
hash key (setting C<last> to each element). It supports named blocks and
expression arrays as condition. It returns the list value consisting of the
elements for which the expression evaluated to true. It supports the
following option:

=over 9

=item B<    'f' > Stops on the first match.

=item B<    'v' > Inverts the sense of matching to select nonmatching value

=back

=head2 S<grep(@var,$re[,$opt])> or grep(%var,$re[,$opt])

This operator returns the array values or the hash keys that correspond to the
specified pattern. It ignores undefined array elements. It supports the
following options:

=over 9

=item B<    'b' > Considers only the basename part of the value

=item B<    'd' > Considers only the directory part of the value

=item B<    'f' > Stops on the first match.

=item B<    'i' > Ignores case distinctions in both the pattern and the value

=item B<    'v' > Inverts the sense of matching to select nonmatching value

=back

=cut

sub _ini_grep
{ my ($blk, $nam, $arg) = @_;
  my ($cnd, $opt, $par, $typ);

  # Validate the arguments
  die "RDA-00932: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  if ($par->is_operator eq '.assign.')
  { $typ = $par->{'var'}->is_lvalue;
    if ($typ eq '%')
    { $par = $blk->define_operator(['.hset.'], $par->{'var'}, $par->{'val'});
    }
    elsif ($typ ne '@')
    { die "RDA-00933: Invalid first argument for '$nam'\n";
    }
  }
  elsif (!$par->is_lvalue)
  { die "RDA-00933: Invalid first argument for '$nam'\n";
  }
  $cnd = shift(@$arg) || $VAL_NONE;
  $opt = shift(@$arg) || $VAL_NONE;
  die "RDA-00931: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  bless {
    cnd  => $cnd,
    ctx  => $blk->{'ctx'},
    opt  => $opt,
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_grep,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_grep
{ my ($slf) = @_;
  my ($cnd, $ctx, $fct, $obj, $opt, $val);

  # Get the arguments
  ($obj) = $slf->{'par'}->find_object;
  return RDA::Value::List->new unless defined($obj);
  $cnd = $slf->{'cnd'}->eval_value;
  $opt = $slf->{'opt'}->eval_as_string;

  # Apply code based filter
  if ($cnd->is_code)
  { $fct = index($opt, 'v') >= 0;
    if (index($opt, 'f') < 0)
    { return RDA::Value::List->new(grep
        {ref($_) && ($fct xor $cnd->eval_code($_)->eval_as_scalar)}
        @$obj)
        if $obj->is_array;
      return RDA::Value::List::new_from_data(grep
        {$fct xor
         $cnd->eval_code(RDA::Value::Scalar::new_text($_))->eval_as_scalar}
        keys(%$obj))
        if $obj->is_hash || ($obj = $obj->get_hash)->is_hash;
    }
    else
    { if ($obj->is_array)
      { foreach my $itm (@$obj)
        { return RDA::Value::List->new($itm)
            if ref($itm) && ($fct xor $cnd->eval_code($itm)->eval_as_scalar);
        }
        return RDA::Value::List->new;
      }
      if ($obj->is_hash || ($obj = $obj->get_hash)->is_hash)
      { foreach my $key (keys(%$obj))
        { $val = RDA::Value::Scalar::new_text($key);
          return RDA::Value::List->new($val)
            if $fct xor $cnd->eval_code($val)->eval_as_scalar;
        }
        return RDA::Value::List->new;
      }
    }
    die "RDA-00930: Expecting an array or a hash variable as first argument\n";
  }

  # Decode the options
  $cnd = $cnd->as_string;
  $cnd = (index($opt, 'i') < 0) ? qr#$cnd# : qr#$cnd#i;
  $fct = (index($opt, 'b') >= 0) ? 'b' :
         (index($opt, 'd') >= 0) ? 'd' :
         'f';
  $fct .= 'v' if index($opt, 'v') >= 0;

  # Filter the list
  $fct = $tb_grp{$fct};
  if (index($opt, 'f') < 0)
  { return RDA::Value::List->new(grep {ref($_) && &$fct($_->as_scalar, $cnd)}
      @$obj) if $obj->is_array;
    return RDA::Value::List::new_from_data(grep {&$fct($_, $cnd)} keys(%$obj))
      if $obj->is_hash || ($obj = $obj->get_hash)->is_hash;
  }
  else
  { if ($obj->is_array)
    { foreach my $itm (@$obj)
      { return RDA::Value::List->new($itm)
          if ref($itm) && &$fct($itm->as_scalar, $cnd);
      }
      return RDA::Value::List->new;
    }
    if ($obj->is_hash || ($obj = $obj->get_hash)->is_hash)
    { foreach my $key (keys(%$obj))
      { return RDA::Value::List::new_from_data($key)
          if &$fct($key, $cnd);
      }
      return RDA::Value::List->new;
    }
  }
  die "RDA-00930: Expecting an array or a hash variable as first argument\n";
}

sub _grep_b
{ my ($val, $re) = @_;
  defined($val) && basename($val) =~ $re;
}

sub _grep_bv
{ my ($val, $re) = @_;
  defined($val) && basename($val) !~ $re;
}

sub _grep_d
{ my ($val, $re) = @_;
  defined($val) && dirname($val) =~ $re;
}

sub _grep_dv
{ my ($val, $re) = @_;
  defined($val) && dirname($val) !~ $re;
}

sub _grep_f
{ my ($val, $re) = @_;
  defined($val) && $val =~ $re;
}

sub _grep_fv
{ my ($val, $re) = @_;
  defined($val) && $val !~ $re;
}

=head2 S<list(arg,...)>

This operator returns the argument list after its evaluation. It executes the
code values.

=cut

sub _ini_list
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_list,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_list
{ shift->{'arg'}->eval_value(1);
}

=head2 S<missing($var)>, S<missing($var[value...])>, or missing($var{value...})>

This operator indicates when a variable, an array index, or a hash key does
not exist.

=cut

sub _ini_missing
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Validate the arguments
  die "RDA-00932: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  die "RDA-00933: Invalid first argument for '$nam'\n"
    unless $par->is_lvalue;
  die "RDA-00931: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_missing,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_missing
{ my ($slf) = @_;

  my ($obj) = $slf->{'par'}->find_object;
  defined($obj) ? $VAL_ZERO : $VAL_ONE;
}

=head2 S<nvl($arg,...)>

This operator returns the value of the first argument that is not undefined. It
executes code values. The remaining arguments are not evaluated. When no
defined arguments are found, it returns an undefined value.

=cut

sub _ini_nvl
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_nvl,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_nvl
{ my ($slf) = @_;
  my ($val);

  foreach my $itm (@{$slf->{'arg'}})
  { return $val if ($val = $itm->eval_value(1))->is_defined;
  }
  $VAL_UNDEF;
}

=head2 S<property(type,group,name,[default[,flag]])>

This operator represents a property with a dynamic name in the specified
group.

=cut

sub _ini_property
{ my ($blk, $nam, $arg) = @_;
  my ($dft, $flg, $grp, $prp, $typ);

  # Validate the arguments
  die "RDA-00932: Missing argument for '$nam'\n"
    unless ref($typ = shift(@$arg))
        && ref($grp = shift(@$arg))
        && ref($prp = shift(@$arg));
  die "RDA-00933: Invalid first argument for '$nam'\n"
    unless ($typ = $typ->as_scalar) && $typ =~ m/^[\$\@\%]$/;
  $dft = shift(@$arg);
  $flg = ref($flg = shift(@$arg)) ? $flg->as_scalar : undef;
  die "RDA-00931: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the dynamic property
  RDA::Value::Property->new_dynamic($blk, $typ, $grp, $prp, $dft, $flg);
}

=head2 S<ref(value)>

This operator returns the object class if the value is a reference to an
object. Otherwise, it returns an empty string. It executes code values.

=cut

sub _ini_ref
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Validate the arguments
  die "RDA-00932: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  die "RDA-00931: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Create the operator
  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_ref,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_ref
{ my ($slf) = @_;
  my ($ref, $val);

  $val = $slf->{'par'}->eval_value;
  ($ref = $val->is_object)          ? RDA::Value::Scalar::new_text($ref) :
  ($ref = $val->is_pointer)         ? $tb_ref{$ref} :
  exists($tb_ref{$ref = ref($val)}) ? $tb_ref{$ref} :
                                      $VAL_NONE;
}

=head2 S<reverse(value,...)>

This operator returns the reverse list of the arguments. It executes code
values.

=cut

sub _ini_reverse
{ my (undef, $nam, $arg) = @_;

  # Create the operator
  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_reverse,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_reverse
{ RDA::Value::List->new(reverse @{shift->{'arg'}->eval_value(1)});
}

=head2 S<scalar(...)>

This operator evaluates its argument list in a scalar context. It executes code
values.

=cut

sub _ini_scalar
{ my (undef, $nam, $arg) = @_;
  my ($cnt);

  # Determine the treatment
  $cnt = @$arg;
  return $VAL_ZERO unless $cnt;
  
  # Create the operator
  bless {
    arg  => ($cnt > 1) ? $arg : $arg->[0],
    _del => \&del_error,
    _fnd => \&find_error,
    _get => ($cnt > 1) ? \&_get_scalar_list : \&_get_scalar_first,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_scalar_first
{ my ($val);

  ($val = shift->{'arg'}->eval_value(1))->is_list
    ? RDA::Value::Scalar::new_number(scalar @$val)
    : $val;
}

sub _get_scalar_list
{ RDA::Value::Scalar::new_number(scalar @{shift->{'arg'}->eval_value(1)});
}

# --- Common routines ---------------------------------------------------------

sub _left_pair
{ my ($slf) = @_;
  my ($cnd, $typ, $val, @arg);

  $typ = '';
  @arg = @{$slf->{'arg'}};
  while (($cnd, $val) = splice(@arg, 0, 2))
  { return _test_pair($cnd, $typ) unless defined($val);
    return ''                     unless ($typ = _test_pair($val, $typ));
  }
  $typ;
}

sub _test_pair
{ my ($val, $prv) = @_;
  my ($typ);

  $typ = $val->is_lvalue;
  !$typ ? '' : ($prv eq '' || $prv eq $typ) ? $typ : '-';
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
