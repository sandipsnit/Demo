# Data.pm: Class Used for Complex Data Structure Manipulation Macros

package RDA::Library::Data;

# $Id: Data.pm,v 2.6 2012/04/25 06:35:03 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Data.pm,v 2.6 2012/04/25 06:35:03 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Library::Data - Class Used for Complex Data Structure Manipulation Macros

=head1 SYNOPSIS

require RDA::Library::Data;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Data> class are used to interface with
macros for manipulating complex data structure.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $ARRAY  = qr/^(ARRAY|RDA::Value::(Array|List))$/i;
my $HASH   = qr/^(HASH|RDA::Value::(Assoc|Hash))$/i;
my $REF    = qr/^(ARRAY|HASH|RDA::Value::(Array|Assoc|Hash|List))$/i;

my %tb_fct = (
  'addDataValue'  => \&_m_add_value,
  'clearData'     => \&_m_clear,
  'copyData'      => \&_m_copy,
  'createData'    => \&_m_create,
  'deleteData'    => \&_m_delete,
  'decrDataValue' => \&_m_decr_value,
  'evalData'      => \&_m_eval,
  'existsData'    => \&_m_exists,
  'extern'        => \&_m_extern,
  'getData'       => \&_m_get_data,
  'getDataError'  => \&_m_get_error,
  'getDataIndex'  => \&_m_get_index,
  'getDataKeys'   => \&_m_get_keys,
  'getDataValue'  => \&_m_get_value,
  'incrDataValue' => \&_m_incr_value,
  'missingData'   => \&_m_missing,
  'refData'       => \&_m_ref,
  'renameData'    => \&_m_rename,
  'resolveData'   => \&_m_resolve,
  'setDataValue'  => \&_m_set_value,
  );
my %tb_stl = (
  '*' => '**',
  "'" => "''",
  '`' => '``',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Data-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Data> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_dat'> > Library data structure

=item S<    B<'_err'> > Error message for last external macro execution

=back

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _err => '',
    }, ref($cls) || $cls;

  # Clear the library hash
  $slf->_reset_data;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

  # Return the object reference
  $slf;
}

# Clear the library hash for each module
sub clr_stats
{ shift->_reset_data;
}

sub get_stats
{ shift->_reset_data;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}}($slf, @arg);
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;

  # return &{$tb_fct{$nam} || $tb_alt{$nam}}($slf, $ctx, $arg);
  return &{$tb_fct{$nam}}($slf, $ctx, $arg);
}

=head1 INTERFACE MACROS

=head2 S<extern(class,name[,arg,...])>

This macro calls an external Perl macro and provides a return value. It
evaluates the Perl code in a scalar context. When it returns an array
reference, the array should contain values that can be converted into RDA
values only.

=cut

sub _m_extern
{ my ($slf, $ctx, $arg) = @_;
  my ($cls, $fct, $ret, @arg);

  ($cls, $fct, @arg) = $arg->eval_as_array;
  $slf->{'_err'} = '';
  if ($cls && $fct)
  { eval "require RDA::Extern::$cls";
    if ($@)
    { eval "require $cls";
    }
    else
    { $cls = "RDA::Extern::$cls";
    }
    unless ($slf->{'_err'} = $@)
    { $ret = eval "$cls\:\:$fct(\$ctx, \@arg)";
      return RDA::Value::convert_value($ret) unless ($slf->{'_err'} = $@);
    }
  }
  $VAL_UNDEF;
}

=head2 S<getDataError()>

This macro returns the error message from the last external macro call. If
no errors are encountered, then it returns an empty string.

=cut

sub _m_get_error
{ RDA::Value::Scalar::new_text(shift->{'_err'});
}

=head1 MACROS FOR MANIPULATING COMPLEX DATA STRUCTURES

This macro library provides macros to manage complex data structures. A data
structure is associated to this macro library and is shared between all
execution contexts of a module.

=head2 S<addDataValue([$obj,]key,...,value)>

This macro pushes a new value in the array associated to the specified key
chain. It evaluates the value without executing code values. When required, it
converts a previously stored value to an array. It returns the new number of
elements in the array. In the case of problems, it returns an undefined value.

=cut

sub _m_add_value
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $lst, $tbl, $val);

  ($dat, $val, $lst) = _parse_arg($slf, $arg, 1);
  return $VAL_UNDEF unless ref($val);
  ($dat, $key, $flg) = _find_item($dat, $lst);
  return $VAL_UNDEF unless defined($key);
  if ($flg)
  { if (defined($dat->[$key]))
    { $dat->[$key] = $tbl = RDA::Value::Array->new($tbl)
        unless ref($tbl = $dat->[$key]) =~ $ARRAY;
    }
    else
    { $dat->[$key] = $tbl = RDA::Value::Array->new;
    }
  }
  else
  { if (exists($dat->{$key}))
    { $dat->{$key} = $tbl = RDA::Value::Array->new($tbl)
        unless ref($tbl = $dat->{$key}) =~ $ARRAY;
    }
    else
    { $dat->{$key} = $tbl = RDA::Value::Array->new;
    }
  }
  RDA::Value::Scalar::new_number(push(@$tbl, $val->eval_value));
}

=head2 S<clearData([[$obj,]key,...])>

This macro clears the specified subhash. When you do not specify any keys, the
whole hash is cleared. It returns zero on successful completion. Otherwise, it
returns a nonzero value.

=cut

sub _m_clear
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  return $VAL_ONE unless defined($dat);
  if ($flg)
  { $dat->[$key] = RDA::Value::Assoc->new;
  }
  elsif (defined($key))
  { $dat->{$key} = RDA::Value::Assoc->new;
  }
  else
  { foreach $key (keys(%$dat))
    { delete($dat->{$key});
    }
  }
  $VAL_ZERO;
}

=head2 S<copyData([$obj])>

This macro returns a copy of a data structure.

=cut

sub _m_copy
{ my ($slf, $ctx, $arg) = @_;
  my $dat;

  ($dat) = _parse_arg($slf, $arg);
  $dat->copy_value;
}

=head2 S<createData([key=>val,...])>

This macro creates a new data structure and returns an object reference. Array
and hash variables are converted respectively in arrays or hashes. You can use
a C<list> macro to create subarrays also. It evaluates other arguments in a
scalar context.

=cut

sub _m_create
{ my ($slf, $ctx, $arg) = @_;
  my ($key, $val, @arg, @tbl);

  @arg = @$arg;
  while (($key, $val) = splice(@arg, 0, 2))
  { push(@tbl, $key->eval_as_string, $val->eval_value)
      if ref($key) && ref($val);
  }
  RDA::Value::Assoc->new(@tbl);
}

=head2 S<decrDataValue([$obj,]key,...)>

This macro decrements by one the value associated with the specific key
chain. It returns the new value. If the key is not defined or is associated
with a subhash or an array, it returns an undefined value.

=cut

sub _m_decr_value
{ _incr_value(-1, @_);
}

=head2 S<deleteData([$obj,]key,...)>

This macro deletes a data element from the data structure. It returns zero on
successful completion. Otherwise, it returns a nonzero value.

=cut

sub _m_delete
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  return $VAL_ONE unless defined($key);
  if ($flg)
  { $dat->[$key] = undef;
  }
  else
  { delete($dat->{$key});
  }
  $VAL_ZERO;
}

=head2 S<evalData([$obj])>

This macro evaluates a data structure. It returns a new data structure that can
be used by external Perl modules.

=cut

sub _m_eval
{ my ($slf, $ctx, $arg) = @_;
  my $dat;

  ($dat) = _parse_arg($slf, $arg);
  RDA::Value::convert_value($dat->eval_as_data(1));
}

=head2 S<existsData([$obj,]key,...)>

This macro indicates if the key chain exists in a hash. The macro does not
modify the data structure.

=cut

sub _m_exists
{ _exists(@_) ? $VAL_ONE : $VAL_ZERO;
}

sub _exists
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $lst);

  ($dat, $lst) = _parse_arg($slf, $arg);
  foreach my $itm ($lst->eval_as_array)
  { next unless defined($itm);
    if (defined($key))
    { if ($flg)
      { return 0 unless defined($dat->[$key]);
        $dat = $dat->[$key];
      }
      else
      { return 0 unless exists($dat->{$key});
        $dat = $dat->{$key};
      }
      return 0 unless ref($dat) =~ $HASH;
    }
    $flg = ref($dat) =~ $ARRAY;
    $key = $itm;
  }
  (!$flg && defined($key) && exists($dat->{$key})) ? 1 : 0;
}

=head2 S<getData()>

This macro returns a reference to the library data structure.

=cut

sub _m_get_data
{ RDA::Value::Scalar::new_object(shift->{'_dat'})
}
  

=head2 S<getDataIndex([[$obj,]key,...])>

This macro returns the list of all keys of the specified subhash, sorted
numerically.

=cut

sub _m_get_index
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $ref);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  if (defined($key))
  { return RDA::Value::List->new unless exists($dat->{$key});
    $ref = ref($dat = $dat->{$key});
    return RDA::Value::List->new unless $ref =~ $HASH;
  }
  defined($dat)
    ? RDA::Value::List::new_from_data(sort {$a <=> $b} keys(%$dat))
    : RDA::Value::List->new;
}

=head2 S<getDataKeys([[$obj,]key,...])>

This macro returns the list of all keys of the specified subhash, sorted
alphabetically.

=cut

sub _m_get_keys
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $ref);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  if (defined($key))
  { return RDA::Value::List->new unless exists($dat->{$key});
    $ref = ref($dat = $dat->{$key});
    return RDA::Value::List->new unless $ref =~ $HASH;
  }
  defined($dat)
    ? RDA::Value::List::new_from_data(sort keys(%$dat))
    : RDA::Value::List->new;
}

=head2 S<getDataValue([$obj,]key,...)>

This macro returns the value associated with the specified key chain. If the
key is not defined or if the key chain is invalid, it returns an undefined
value.  Arrays are converted in lists but subarrays are not included.

=cut

sub _m_get_value
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $ref, $val);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  defined($key)
    ? RDA::Value::convert_value($flg ? $dat->[$key] :
                  exists($dat->{$key}) ? $dat->{$key} : undef)
    : $VAL_UNDEF;
}

=head2 S<incrDataValue([$obj,]key,...)>

This macro increments by one the value associated with the specific key
chain. It returns the new value. If the key is not defined or is associated
with a subhash or an array, it returns an undefined value.

=cut

sub _m_incr_value
{ _incr_value(1, @_);
}

sub _incr_value
{ my ($val, $slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $old, $ref);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  return $VAL_UNDEF unless defined($key);
  $old = $flg ? $dat->[$key] : $dat->{$key};
  if (defined($old))
  { if ($ref = ref($old))
    { return $VAL_UNDEF if $ref !~ $VALUE || $ref =~ $REF;
      $val += $old->eval_as_number;
    }
    else
    { $val += $old;
    }
  }
  $val = RDA::Value::Scalar::new_number($val);
  $flg ? $dat->[$key] = $val : $dat->{$key} = $val;
}

=head2 S<missingData([$obj,]key,...)>

This macro indicates whether the key chain is missing in a hash. The macro does
not modify the data structure.

=cut

sub _m_missing
{ _exists(@_) ? $VAL_ZERO : $VAL_ONE;
}

=head2 S<refData([$obj,]key,...)>

This macro returns a nonempty string if the specified key chain is associated
with a reference. Otherwise, it returns an empty string.

=cut

sub _m_ref
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key);

  ($dat, $key, $flg) = _find_item(_parse_arg($slf, $arg));
  (!defined($key))     ? $VAL_NONE :
  $flg                 ? _ref_value($dat->[$key]) :
  exists($dat->{$key}) ? _ref_value($dat->{$key}) :
                         $VAL_NONE;
}

sub _ref_value
{ my $ref = ref(shift);

  ($ref =~ m/^(ARRAY|HASH|RDA::Value::(Array|Assoc|Hash|List))$/)
    ? RDA::Value::Scalar::new_text($ref)
    : $VAL_NONE;
}
  

=head2 S<renameData([$obj,]old,...,new)>

This macro renames a hash key. It returns zero on successful completion.
Otherwise, it returns a nonzero value.

=cut

sub _m_rename
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $lst, $old, $new);

  ($dat, $new, $lst) = _parse_arg($slf, $arg, 1);
  return $VAL_ONE unless ref($new) && ($new = $new->eval_as_string);
  ($dat, $old, $flg) = _find_item($dat, $lst);
  return $VAL_ONE
    unless !$flg && defined($old) && exists($dat->{$old});
  $dat->{$new} = delete($dat->{$old});
  $VAL_ZERO;
}

=head2 S<resolveData([$obj,][key,...,]string)>

This macro resolves hash key references from the string, using the specified
subhash. It supports nested references. The following reference formats are
supported:

=over 20

=item B<    ${key}>

Replaces the reference with the hash key values. When the key is not defined,
it replaces the reference with an empty string.

=item B<    ${key:dft}>

Replaces the reference with the hash key values. When the key is not defined,
it replaces the reference with the default text.

=item B<    ${key?txt:dft}>

Replaces the reference with the specified text when the hash key
exists. Otherwise, it replaces the reference with the default text.

=back

You can prefix the key by a character indicating how the key value must be
emphasized. It is not used for other replacement texts. The valid style
characters are as follows:

=over 6

=item S<    *> for bold

=item S<    '> (single quote) for italic

=item S<    `> (back quote) for code

=back

It returns the resulting value.

=cut

sub _m_resolve
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $lst, $str);

  ($dat, $str, $lst) = _parse_arg($slf, $arg, 1);
  return $VAL_UNDEF unless ref($str);
  ($dat, $key, $flg) = _find_item($dat, $lst);
  $dat = $flg ? $dat->[$key] : $dat->{$key} if defined($key);
  $dat = RDA::Value::Assoc->new unless ref($dat) =~ $HASH;

  $str = $str->eval_as_string;
  1 while $str =~ s/\$\{([\*\'\`])?(\w+)((\?)([^\{\}]*?))?(\:([^\{\}]*?))?\}/
                    _resolve($dat, $1, $2, $4, $5, $7)/eg;
  RDA::Value::Scalar::new_text($str);
}

sub _resolve
{ my ($hsh, $stl, $key, $tst, $txt, $dft) = @_;
  my ($ref, $str);
 
  if (exists($hsh->{$key}))
  { return defined($txt) ? $txt : '' if $tst;
    $str = $hsh->{$key};
    $stl = ($stl && exists($tb_stl{$stl})) ? $tb_stl{$stl} : '';
    $ref = ref($str);
    return $stl.$str->eval_as_string.$stl
      if $ref =~ $VALUE && $ref !~ $REF;
    return $stl.$str.$stl unless $ref;
  }
  defined($dft) ? $dft : '';
}

=head2 S<setDataValue([$obj,]key,...,value)>

This macro assigns a new value to the specified key chain. You can insert array
structures as value, by using array variables or C<list> macros. By analogy, a
hash variable is converted into a hash structure. Otherwise, it evaluates the
value in a scalar context without executing code values.

It returns the assigned value.

=cut

sub _m_set_value
{ my ($slf, $ctx, $arg) = @_;
  my ($dat, $flg, $key, $lst, $val, @tbl);

  ($dat, $val, $lst) = _parse_arg($slf, $arg, 1);

  return $VAL_UNDEF unless ref($val);
  ($dat, $key, $flg) = _find_item($dat, $lst);
  return $VAL_UNDEF unless defined($key);
  $val = $val->eval_value;
  $flg ? $dat->[$key] = $val : $dat->{$key} = $val;
  $val;
}

# --- Internal data structure routines ----------------------------------------

# Find data item
sub _find_item
{ my ($dat, $arg) = @_;
  my ($flg, $key, $ref, @key);

  @key = ('[data]');
  foreach my $itm ($arg->eval_as_array)
  { next unless defined($itm);
    if (defined($key))
    { if ($flg)
      { $dat->[$key] = RDA::Value::Assoc->new unless defined($dat->[$key]);
        $dat = $dat->[$key];
      }
      else
      { $dat->{$key} = RDA::Value::Assoc->new unless exists($dat->{$key});
        $dat = $dat->{$key};
      }
      $ref = ref($dat);
      return () unless $ref =~ $HASH || $ref =~ $ARRAY;
      push(@key, $key)
    }
    $flg = ref($dat) =~ $ARRAY;
    $key = $itm;
  }
  ($dat, $key, $flg, join('->', @key));
}

# Parse the argument list
sub _parse_arg
{ my ($slf, $arg, $flg) = @_;
  my ($dat, $obj, $val, @arg);

  # Take a copy of the argument list
  @arg = @$arg;

  # Determine the data structure object
  if (ref($obj = shift(@arg)))
  { $dat = $obj->eval_as_scalar;
    unless (ref($dat) =~ $HASH)
    { $dat = $slf->{'_dat'};
      unshift(@arg, $obj);
    }
  }
  else
  { $dat = $slf->{'_dat'};
  }

  # Return the arguments
  if ($flg)
  { $val = pop(@arg);
    return ($dat, $val, RDA::Value::List->new(@arg));
  }
  return ($dat, RDA::Value::List->new(@arg));
}

# Reset the library hash
sub _reset_data
{ shift->{'_dat'} = RDA::Value::Assoc->new;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>,

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
