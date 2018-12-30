# Hash.pm: Class Used for Managing Hash Operators

package RDA::Operator::Hash;

# $Id: Hash.pm,v 2.6 2012/01/02 16:30:49 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Operator/Hash.pm,v 2.6 2012/01/02 16:30:49 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Operator::Hash - Class Used for Managing Hash Operators

=head1 SYNOPSIS

require RDA::Operator::Hash;

=head1 DESCRIPTION

This package regroups the definition of the hash operators.

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
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_ini = (
  '.assoc.' => \&_ini_assoc,
  '.hash.'  => \&_ini_hash,
  '.hset.'  => \&_ini_hset,
  '.key.'   => \&_ini_key,
  'keys'    => \&_ini_keys,
  'resolve' => \&_ini_resolve,
  'values'  => \&_ini_values,
  );
my %tb_key = (
  '*' => \&_keys_all,
  IA  => \&_keys_ia,
  ID  => \&_keys_id,
  KA  => \&_keys_ka,
  KD  => \&_keys_kd,
  NA  => \&_keys_na,
  ND  => \&_keys_nd,
  SA  => \&_keys_sa,
  SD  => \&_keys_sd,
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

=head2 S<$h = RDA::Operator::Hash-E<gt>load($tbl)>

This method loads the operator definition in the operator table.

=cut

sub load
{ my ($cls, $tbl) = @_;

  foreach my $nam (keys(%tb_ini))
  { $tbl->{$nam} = $tb_ini{$nam};
  }
}

=head1 OPERATOR DEFINITIONS

=head2 S<.assoc.($par)>

This operator transforms a list in an associative array.

=cut

sub _ini_assoc
{ my ($arg) = @_;

  bless {
    arg  => $arg,
    _del => \&del_error,
    _fnd => \&_find_assoc,
    _get => \&_get_assoc,
    _lft => '',
    _set => \&set_error,
    _typ => '.assoc.',
    }, 'RDA::Value::Operator';
}

sub _find_assoc
{ my ($slf, $typ) = @_;

  (RDA::Value::Assoc::new_from_list($slf->{'arg'}->eval_value(1)));
}

sub _get_assoc
{ my ($slf, $flg) = @_;

  RDA::Value::Assoc::new_from_list($slf->{'arg'}->eval_value($flg));
}

=head2 S<.hash.($par)>

This operator transforms an associative array in a hash.

=cut

sub _ini_hash
{ my ($par) = @_;

  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_hash,
    _get => \&_get_hash,
    _lft => '',
    _set => \&set_error,
    _typ => '.hash.',
    }, 'RDA::Value::Operator';
}

sub _find_hash
{ my ($slf, $typ) = @_;
  my ($trc, $val);

  ($val, $trc) = $slf->{'par'}->find_object($typ);
  ((defined($val) && $val->is_defined)
    ? RDA::Value::Hash::new_from_hash($val->get_hash)
    : RDA::Value::Hash->new, $trc);
}

sub _get_hash
{ my ($slf, $flg) = @_;
  my ($val);

  ($val) = $slf->{'par'}->find_object;
  (defined($val) && $val->is_defined)
    ? RDA::Value::Hash::new_from_hash($val->get_hash)->eval_value($flg)
    : RDA::Value::Hash->new;
}

=head2 S<.hset.($nam,$arg)>

This operator assigns the value to the specified hash variable and returns the
variable.

=cut

sub _ini_hset
{ my ($var, $val) = @_;

  # Validate the arguments
  die "RDA-00934: Invalid left value to assign\n" unless $var->is_lvalue eq '%';
  die "RDA-00939: Missing right value\n" unless ref($val);

  # Create the operator
  bless {
    val  => $val,
    var  => $var,
    _del => \&del_error,
    _fnd => \&_find_hset,
    _get => \&_get_hset,
    _lft => '%',
    _set => \&set_error,
    _typ => '.hset.',
    }, 'RDA::Value::Operator';
}

sub _find_hset
{ my ($slf, $typ) = @_;

  $slf->{'var'}->assign_value($slf->{'val'});
  $slf->{'var'}->find_object($typ);
}

sub _get_hset
{ my ($slf, $flg) = @_;

  $slf->{'var'}->assign_value($slf->{'val'});
  $slf->{'var'}->eval_value($flg);
}

=head2 S<.key.($par,$arg)>

This operator selects a hash entry. It supports multidimensional hashes.

=cut

sub _ini_key
{ my ($par, $arg) = @_;

  bless {
    arg  => $arg,
    par  => $par,
    _del => \&_del_key,
    _fnd => \&_find_key,
    _get => \&_get_key,
    _lft => \&_is_lvalue,
    _set => \&_set_key,
    _typ => '.key.',
    }, 'RDA::Value::Operator';
}

sub _decode_key
{ my ($val) = @_;

  $val = $val->eval_value(1);
  return (map {_decode_key($_)} @$val) if $val->is_list;
  $val->as_string;
}

sub _del_key
{ my ($slf) = @_;
  my ($obj, $off, $trc, @tbl);

  # Validate the indexes
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_key($_)} @tbl;
  $off = pop(@tbl);

  # Get the parent object
  ($obj, $trc) = $slf->{'par'}->find_object('%');

  # Find the current object
  foreach my $itm (@tbl)
  { return () unless exists($obj->{$itm}) && $obj->{$itm}->is_defined;
    $obj = $obj->{$itm};
    return () unless $obj->is_hash || ($obj = $obj->get_hash)->is_hash;
  }

  # Delete the value
  (delete($obj->{$off}), $trc);
}

sub _find_key
{ my ($slf, $typ) = @_;
  my ($obj, $off, $trc, @tbl);

  # Validate the keys
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_key($_)} @tbl;
  $off = pop(@tbl);

  # Find the current object
  ($obj, $trc) = $slf->{'par'}->find_object('%');
  if (defined($obj))
  { die "RDA-00910: Hash expected\n"
      unless $obj->is_hash || ($obj = $obj->get_hash)->is_hash;
    foreach my $itm (@tbl)
    { unless (exists($obj->{$itm}) && $obj->{$itm}->is_defined)
      { return () unless $typ;
        $obj->{$itm} = RDA::Value::Assoc->new;
      }
      $obj = $obj->{$itm};
      die "RDA-00910: Hash expected\n"
        unless $obj->is_hash || ($obj = $obj->get_hash)->is_hash;
    }
  }

  # Treat the last level
  unless ($typ)
  { return ($obj->{$off}) if exists($obj->{$off});
    return ();
  }
  unless (exists($obj->{$off}) && $obj->{$off}->is_defined)
  { $obj->{$off} = ($typ eq '@') ? RDA::Value::Array->new :
                   ($typ eq '%') ? RDA::Value::Assoc->new :
                                   $VAL_UNDEF;
  }
  ($obj->{$off}, $trc);
}

sub _get_key
{ my ($slf, $flg) = @_;
  my ($rec, @tbl);

  # Validate the keys
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_key($_)} @tbl;

  # Get the key value
  ($rec) = $slf->{'par'}->find_object;
  foreach my $off (@tbl)
  { return $VAL_UNDEF unless defined($rec) && $rec->is_defined;
    die "RDA-00910: Hash expected\n"
      unless $rec->is_hash || ($rec = $rec->get_hash)->is_hash;
    $rec = $rec->{$off};
  }
  ref($rec) ? $rec->eval_value($flg) : $VAL_UNDEF;
}

sub _set_key
{ my ($slf, $typ, $val, $flg) = @_;
  my ($obj, $off, $trc, @tbl);

  # Adjust the value
  $val = shift(@$val) || $VAL_UNDEF if $typ;

  # Validate the keys
  @tbl = @{$slf->{'arg'}};
  @tbl = map {_decode_key($_)} @tbl;
  $off = pop(@tbl);

  # Get the parent object
  ($obj, $trc) = $slf->{'par'}->find_object('%');
  die "RDA-00910: Hash expected\n"
    unless $obj->is_hash || ($obj = $obj->get_hash)->is_hash;

  # Find the current object
  foreach my $itm (@tbl)
  { $obj->{$itm} = RDA::Value::Assoc->new
      unless exists($obj->{$itm}) && $obj->{$itm}->is_defined;
    $obj = $obj->{$itm};
    die "RDA-00910: Hash expected\n"
      unless $obj->is_hash || ($obj = $obj->get_hash)->is_hash;
  }

  # Set the value
  if ($flg)
  { $val += $obj->{$off}->as_number if exists($obj->{$off});
    $obj->{$off} = $val = RDA::Value::Scalar::new_number($val);
    $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
    return $val;
  }
  else
  { $obj->{$off} = $val->is_list
      ? RDA::Value::Scalar::new_number(scalar @$val)
      : $val;
  }
  $trc;
}

=head2 S<keys(%hash,$opt)>

This operator returns the list of all keys used in the specified hash. By
default, it sorts the keys in alphabetic order. You can specify sort
criteria as an argument:

=over 10

=item B<    'IA' > By their keys, sorted numerically ascending

=item B<    'ID' > By their keys, sorted numerically descending

=item B<    'KA' > By their keys, sorted alphabetically

=item B<    'KD' > By their keys, in reverse alphabetic order

=item B<    'NA' > By their values, sorted numerically ascending

=item B<    'ND' > By their values, sorted numerically descending

=item B<    'SA' > By their values, sorted alphabetically

=item B<    'SD' > By their values, in reverse alphabetic order

=back

The hash is not implicitly defined by this operator.

When you specify C<*> as sort criteria, it returns all valid key lists for the
specified hash.

=cut

sub _ini_keys
{ my (undef, $nam, $arg) = @_;
  my ($opt, $par);

  # Validate the arguments
  die "RDA-00912: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  $opt = shift(@$arg) || $VAL_NONE;
  die "RDA-00911: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Transform assign operator when required
  $par = _ini_hset($par->{'var'}, $par->{'val'})
    if $par->is_operator eq '.assign.' && $par->{'var'}->is_lvalue eq '%';

  # Create the operator
  bless {
    opt  => $opt,
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_keys,
    _get => \&_get_keys,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _find_keys
{ (_get_keys(shift));
}

sub _get_keys
{ my ($slf) = @_;
  my ($hsh, $opt);

  # Get the hash
  ($hsh) = $slf->{'par'}->find_object;
  return RDA::Value::List->new unless defined($hsh) && $hsh->is_defined;
  die "RDA-00910: Hash expected\n"
    unless $hsh->is_hash || ($hsh = $hsh->get_hash)->is_hash;

  # Get the sort type
  $opt = uc($slf->{'opt'}->eval_as_string);
  exists($tb_key{$opt}) ? &{$tb_key{$opt}}($hsh) : _keys_ka($hsh);
}

sub _keys_ia
{ my ($hsh) = @_;

  RDA::Value::List::new_from_data(sort {$a <=> $b} keys(%$hsh));
}

sub _keys_id
{ my ($hsh) = @_;

  RDA::Value::List::new_from_data(sort {$b <=> $a} keys(%$hsh));
}

sub _keys_ka
{ my ($hsh) = @_;

  RDA::Value::List::new_from_data(sort keys(%$hsh));
}

sub _keys_kd
{ my ($hsh) = @_;

  RDA::Value::List::new_from_data(sort {$b cmp $a} keys(%$hsh));
}

sub _keys_na
{ my ($hsh) = @_;

  my %tbl = map {$_ => $hsh->{$_}->eval_as_number} keys(%$hsh);
  RDA::Value::List::new_from_data(sort {$tbl{$a} <=> $tbl{$b}} keys(%tbl));
}

sub _keys_nd
{ my ($hsh) = @_;

  my %tbl = map {$_ => $hsh->{$_}->eval_as_number} keys(%$hsh);
  RDA::Value::List::new_from_data(sort {$tbl{$b} <=> $tbl{$a}} keys(%tbl));
}

sub _keys_sa
{ my ($hsh) = @_;

  my %tbl = map {$_ => $hsh->{$_}->eval_as_string} keys(%$hsh);
  RDA::Value::List::new_from_data(sort {$tbl{$a} cmp $tbl{$b}} keys(%tbl));
}

sub _keys_sd
{ my ($hsh) = @_;

  my %tbl = map {$_ => $hsh->{$_}->eval_as_string} keys(%$hsh);
  RDA::Value::List::new_from_data(sort {$tbl{$b} cmp $tbl{$a}} keys(%tbl));
}

sub _keys_all
{ RDA::Value::List->new(_keys_sub(shift));
}

sub _keys_sub
{ my ($hsh, @key) = @_;
  my (@tbl);

  foreach my $key (sort keys(%$hsh))
  { if (ref($hsh->{$key}) =~ m/^(HASH|RDA::Value::(Assoc|Hash))$/)
    { push(@tbl,
        _keys_sub($hsh->{$key}, @key, RDA::Value::Scalar::new_text($key)));
    }
    else
    { push(@tbl,
        RDA::Value::Array->new(@key, RDA::Value::Scalar::new_text($key)));
    }
  }
  @tbl;
}

=head2 S<$h-E<gt>resolve(%hash,$string)>

This operator resolves hash key references from the string, using the specified
hash. It supports nested references. The following reference formats are
supported:

=over 20

=item B<    ${key}>

Replaces the reference by the hash key value. When the key is not defined, it
replaces the reference with an empty string.

=item B<    ${key:dft}>

Replaces the reference by the hash key value. When the key is not defined, it
replaces the reference with the default text.

=item B<    ${key?txt:dft}>

Replaces the reference by the specified text when the hash key
exists. Otherwise, it replaces the reference with the default text.

=back

You can prefix the key with a character that indicates on how to emphasize the
key value. It is not used for other replacement texts. The valid style
characters are as follows:

=over 6

=item S<    *> for bold

=item S<    '> (single quote) for italic

=item S<    `> (back quote) for code

=back

It returns the resulting value.

=cut

sub _ini_resolve
{ my (undef, $nam, $arg) = @_;
  my ($par, $str);

  # Validate the arguments
  die "RDA-00912: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  return $VAL_NONE unless ref($str = shift(@$arg));
  die "RDA-00911: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Transform assign operator when required
  $par = _ini_hset($par->{'var'}, $par->{'val'})
    if $par->is_operator eq '.assign.' && $par->{'var'}->is_lvalue eq '%';

  # Create the operator
  bless {
    str  => $str,
    par  => $par,
    _del => \&del_error,
    _fnd => \&find_error,
    _get => \&_get_resolve,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _get_resolve
{ my ($slf) = @_;
  my ($hsh, $str);

  ($hsh) = $slf->{'par'}->find_object;
  $hsh = {}
    unless defined($hsh) && $hsh->is_defined
      && ($hsh->is_hash || ($hsh = $hsh->get_hash)->is_hash);
  $str = $slf->{'str'}->eval_as_string;
  1 while $str =~ s/\$\{([\*\'\`])?(\w+)((\?)([^\{\}]*?))?(\:([^\{\}]*?))?\}/
                    _resolve($hsh, $1, $2, $4, $5, $7)/eg;
  return RDA::Value::Scalar::new_text($str);
}

sub _resolve
{ my ($hsh, $stl, $key, $tst, $txt, $dft) = @_;
  my $str;

  return defined($dft) ? $dft : '' unless exists($hsh->{$key});
  return defined($txt) ? $txt : '' if $tst;
  $str = eval "\$hsh->{\$key}->eval_as_string";
  return defined($dft) ? $dft : '' if $@;
  ($stl && exists($tb_stl{$stl}))
    ? $tb_stl{$stl}.$str.$tb_stl{$stl}
    : $str;
}

=head2 S<values(%hash)>

This operator returns the list of all values used in the specified hash. The
hash is not implicitly defined by this operator.

=cut

sub _ini_values
{ my (undef, $nam, $arg) = @_;
  my ($par);

  # Validate the arguments
  die "RDA-00912: Missing argument for '$nam'\n"
    unless ref($par = shift(@$arg));
  die "RDA-00911: Extra value(s) found for '$nam'\n"
    if @$arg;

  # Transform assign operator when required
  $par = _ini_hset($par->{'var'}, $par->{'val'})
    if $par->is_operator eq '.assign.' && $par->{'var'}->is_lvalue eq '%';

  # Create the operator
  bless {
    par  => $par,
    _del => \&del_error,
    _fnd => \&_find_values,
    _get => \&_get_values,
    _lft => '',
    _set => \&set_error,
    _typ => $nam,
    }, 'RDA::Value::Operator';
}

sub _find_values
{ (_get_values(shift));
}

sub _get_values
{ my ($slf) = @_;
  my ($hsh);

  ($hsh) = $slf->{'par'}->find_object;
  return RDA::Value::List->new unless defined($hsh) && $hsh->is_defined;
  die "RDA-00910: Hash expected\n"
    unless $hsh->is_hash || ($hsh = $hsh->get_hash)->is_hash;
  RDA::Value::List->new(values(%$hsh));
}

# --- Common routines ---------------------------------------------------------

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
