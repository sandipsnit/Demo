# Scalar.pm: Class Used for Managing Scalar Values

package RDA::Value::Scalar;

# $Id: Scalar.pm,v 2.7 2012/06/15 05:13:02 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Scalar.pm,v 2.7 2012/06/15 05:13:02 mschenke Exp $
#
# Change History
# 20120615  MSC  Fix value pattern.

=head1 NAME

RDA::Value::Scalar - Class Used for Managing Scalar Values

=head1 SYNOPSIS

require RDA::Value::Scalar;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Scalar> class are used to manage scalar
values.

The following value types are supported:

=over 8

=item B<    'N'> Number

=item B<    'O'> Object

=item B<    'T'> Text String

=item B<    'U'> Undef

=back

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA @EXPORT
  $NUMBER $VAL_NONE $VAL_ONE $VAL_UNDEF $VAL_ZERO);
$NUMBER  = qr/^[+-]?(\d+(\.\d*)?|\.\d+)([eE][\+\-]?\d+)?$/;
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@EXPORT  = qw($NUMBER $VAL_NONE $VAL_ONE $VAL_UNDEF $VAL_ZERO);
@ISA     = qw(RDA::Value Exporter);

# Define the global private constants
my $OBJECT = qr/^RDA::Object::/i;
my $RDA    = qr/^RDA(::[A-Z]\w+){1,2}$/i;
my $VALUE  = qr/^RDA::Value(::[A-Z]\w+)?/i;

my %tb_dbg = (
  N => \&_dump_value,
  O => \&_dump_object,
  T => \&_dump_value,
  U => \&_dump_none,
  );
my %tb_dmp = (
  N => \&_dump_number,
  O => \&_dump_object,
  T => \&_dump_text,
  U => \&_dump_undef,
  );
my %tb_ini = (
  N => \&new_number,
  O => \&new_object,
  T => \&new_text,
  U => \&new_undef,
  );

# Define global special values
$VAL_NONE  = new_text('');
$VAL_ONE   = new_number(1);
$VAL_UNDEF = new_undef();
$VAL_ZERO  = new_number(0);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Scalar-E<gt>new($typ,...)>

The object constructor. The list of arguments depends on the specified value
type:

=over 8

=item B<    'N'> $val (0 by default)

=item B<    'O'> $val

=item B<    'T'> $val (empty string by default)

=item B<    'U'> (no argument)

=back

A C<RDA::Value::Scalar> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'typ' > > Value type

=item S<    B<'val' > > Associated value

=back

=cut

sub new
{ my (undef, $typ, @arg) = @_;

  # Validate the value type
  die "RDA-00823: Invalid value type '$typ'\n" unless exists($tb_ini{$typ});

  # Create the data collection object and return its reference
  &{$tb_ini{$typ}}(@arg);
}

=head2 S<$h = RDA::Value::Scalar::new_from_data($val)>

This method creates a list where each argument is converted into object, text,
or undefined values.

=cut

sub new_from_data
{ my ($val) = @_;
  my $ref = ref($val);

  ($ref =~ $VALUE)        ? $val :
  ($ref =~ $OBJECT)       ? new_object($val, 1) :
  ($ref =~ $RDA &&
   $val->can('as_class')) ? new_object($val, 1) :
  ($ref eq 'ARRAY')       ? RDA::Value::Array::new_from_data(@$val) :
  ($ref eq 'HASH')        ? RDA::Value::Assoc::new_from_data(%$val) :
  $ref                    ? new_undef() :
  !defined($val)          ? new_undef() :
  $val =~ $NUMBER         ? new_number($val) :
                            new_text($val);
}

# Initialize the object based on its type
sub new_number
{ my ($val) = @_;

  bless {
    typ => 'N',
    val => defined($val) ? $val : 0,
    }, __PACKAGE__;
}

sub new_object
{ my ($val, $flg) = @_;

  return new_undef() unless $flg || ref($val) =~ $OBJECT;
  bless {
    typ => 'O',
    val => $val,
    }, __PACKAGE__;
}

sub new_text
{ my ($val) = @_;

  bless {
    typ => 'T',
    val => defined($val) ? $val : '',
    }, __PACKAGE__;
}

sub new_undef
{ bless {
    typ => 'U',
    val => undef,
    }, __PACKAGE__;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the object dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;

  $lvl = 0  unless defined($lvl);
  $txt = '' unless defined($txt);

  dump_object($slf, {}, $lvl, $txt, '');
}

sub dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;

  &{$tb_dmp{$slf->{'typ'}}}($slf, $tbl, $lvl, $txt, $arg);
}

sub _dump_none
{ '';
}

sub _dump_number
{ my ($slf, $tbl, $lvl, $txt) = @_;

  '  ' x $lvl.$txt.'Number='.$slf->{'val'};
}

sub _dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;
  my ($flg, $ref, $val);
 
  $ref = ref($val = $slf->{'val'});
  $flg = $ref =~ $OBJECT || ($ref =~ $RDA && $val->can('as_class'));

  !$flg ? '  ' x $lvl.$txt.'Object=bless(...,'.$ref.')' :
  $arg  ? '  ' x $lvl.$txt.'Object='.$ref.'('.$val->as_string.')' :
          $val->dump($lvl, $txt.'Object=');
}

sub _dump_text
{ my ($slf, $tbl, $lvl, $txt) = @_;

  '  ' x $lvl.$txt."Text='".$slf->{'val'}."'";
}

sub _dump_undef
{ my ($slf, $tbl, $lvl, $txt) = @_;

  '  ' x $lvl.$txt.'Undef';
}

sub _dump_value
{ shift->{'val'};
}

=head2 S<$h-E<gt>has_methods>

This method indicates whether the value has methods.

=cut

sub has_methods
{ shift->{'typ'} =~ m/^[OU]$/;
}

=head2 S<$h-E<gt>is_defined>

This method indicates whether the value is defined.

=cut

sub is_defined
{ shift->{'typ'} ne 'U';
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value(s).

=cut

sub is_lvalue
{ (shift->{'typ'} eq 'U')  ? '-' : '';
}

=head2 S<$h-E<gt>is_object>

This method indicates whether the value is an object.

=cut

sub is_object
{ my ($slf) = @_;

  ($slf->{'typ'} eq 'O') ? ref($slf->{'val'}) : '';
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>decr_value($num)>

This method has no effect on a scalar value and returns an undefined value.

=head2 S<$h-E<gt>delete_value>

This method has no effect on a scalar value and returns an undefined value.

=cut

sub delete_value
{ my ($slf, $flg) = @_;

  return () if $flg;
  $VAL_UNDEF;
}

=head2 S<$h-E<gt>eval_method($blk,$nam,$arg[,$flg])>

This method invokes an object method.

=cut

sub eval_method
{ my ($slf, $blk, $nam, $arg, $flg) = @_;
  my ($cls, $def, $err, $obj, $typ, $use, $val, @val);

  # Skip undefined object
  unless (defined($obj = $slf->{'val'}))
  { $blk->get_context->trace_warning("undefined object for method $nam");
    return $VAL_UNDEF;
  }

  # Validate the associated object
  $use = $blk->get_package('use');
  die "RDA-00824: Object required to invoke a method\n"
    unless ($cls = ref($obj));
  die "RDA-00825: Unknown object type '$cls'\n"
    unless exists($use->{$cls});
  die "RDA-00826: Undefined method '$nam'\n"
    unless exists($use->{$cls}->{'met'}->{$nam});

  # Invoke the method and convert the result
  $def = $use->{$cls}->{'met'}->{$nam};
  $typ = exists($def->{'evl'}) ? $def->{'evl'} : '';
  if (exists($def->{'arg'}))
  { foreach my $arg (@{$def->{'arg'}})
    { push(@val, $blk->get_package($arg));
    }
  }
  if ($typ eq 'E')
  { push(@val, [@{$arg->eval_value}]);
  }
  elsif ($typ eq 'D')
  { push(@val, $arg->eval_as_dump);
  }
  elsif ($typ eq 'L')
  { push(@val, $arg->eval_as_line);
  }
  elsif ($typ eq 'N')
  { push(@val, [@$arg]);
  }
  else
  { push(@val, $arg->eval_as_data(1));
  }
  unshift(@val, $blk) if $def->{'blk'};
  if ($def->{'ret'})
  { @val = eval "\$obj->$nam(\@val)";
    if ($err = $@)
    { $err =~s/[\n\r\s]+$//;
      die "$err\nRDA-00827: Error encountered in method '$cls\::$nam'\n";
    }
    $val = RDA::Value::List->new(map {RDA::Value::convert_value($_)} @val);
  }
  else
  { $val = eval "\$obj->$nam(\@val)";
    if ($err = $@)
    { $err =~s/[\n\r\s]+$//;
      die "$err\nRDA-00827: Error encountered in method '$cls\::$nam'\n";
    }
    $val = (ref($val) eq 'ARRAY')
      ? RDA::Value::List->new(map {RDA::Value::convert_value($_)} @$val)
      : RDA::Value::convert_value($val);
  }
  $flg ? $val->eval_value(1) : $val;
}

=head2 S<$h-E<gt>incr_value($num)>

This method has no effect on a scalar value and returns an undefined value.

=cut

my $n_a = sub {$VAL_UNDEF};

*decr_value   = $n_a;

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_array>

This method converts the value as a Perl list, without altering complex data
structures.

=cut

sub as_array
{ (shift->{'val'});
}

=head2 S<$h-E<gt>as_data>

This method converts the value as a list of Perl data structures.

=cut

sub as_data
{ (shift->{'val'});
}

=head2 S<$h-E<gt>as_dump>

This method converts the value as a dump string

=cut

sub as_dump
{ my ($slf) = @_;

  &{$tb_dbg{$slf->{'typ'}}}($slf, {}, 0, '', '');
}

=head2 S<$h-E<gt>as_number>

This method converts the value as a Perl number.

=cut

sub as_number
{ my ($slf) = @_;
  my $typ;

  $typ = $slf->{'typ'};
  return $slf->{'val'}  if $typ eq 'N';
  return 0              if $typ eq 'U';
  return 0 + $slf->{'val'}
    if $typ eq 'T' && $slf->{'val'} =~ m/^[+-]?\d+(\.\d*)?([eE][\+\-]?\d+)?$/;
  die "RDA-00814: Not a numeric value\n";
}

=head2 S<$h-E<gt>as_scalar>

This method converts the value as a Perl scalar.

=cut

sub as_scalar
{ shift->{'val'};
}

=head2 S<$h-E<gt>as_string>

This method converts the value as a Perl string.

=cut

sub as_string
{ my ($slf) = @_;
  my $typ;

  $typ = $slf->{'typ'};
  return $slf->{'val'}            if $typ eq 'T';
  return ''.$slf->{'val'}         if $typ eq 'N';
  return $slf->{'val'}->as_string if $typ eq 'O';
  '';
}

# --- Assign mechanism --------------------------------------------------------

sub assign_item
{ my ($slf, $tbl) = @_;

  die "RDA-00828: Invalid value type '".ref($slf)."' to assign\n"
    if $slf->{'typ'} ne 'U';
  shift(@$tbl);
  undef;
}

sub assign_var
{ my ($slf, $val, $flg) = @_;

  die "RDA-00829: Invalid value type '".ref($slf)."' to delete\n"
    if $slf->{'typ'} ne 'U';
  undef;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Hash|RDA::Value::Hash>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
