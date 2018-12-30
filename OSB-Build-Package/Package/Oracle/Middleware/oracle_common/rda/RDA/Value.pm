# Value.pm: Class Used for Managing Values

package RDA::Value;

# $Id: Value.pm,v 2.13 2012/05/20 20:51:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value.pm,v 2.13 2012/05/20 20:51:04 mschenke Exp $
#
# Change History
# 20120520  MSC  Update the SEE ALSO section.

=head1 NAME

RDA::Value - Class Used for Managing Values

=head1 SYNOPSIS

require RDA::Value;

=head1 DESCRIPTION

The C<RDA::Value> class regroups the methods common to all value subclasses.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Array;
  use RDA::Value::Assoc;
  use RDA::Value::Code;
  use RDA::Value::Global;
  use RDA::Value::Hash;
  use RDA::Value::Internal;
  use RDA::Value::List;
  use RDA::Value::Operator;
  use RDA::Value::Pointer;
  use RDA::Value::Property;
  use RDA::Value::Scalar;
  use RDA::Value::Variable;
}

# Define the global public variables
use vars qw($VALUE $VERSION @ISA @EXPORT);
$VALUE   = qr/^RDA::Value(::[A-Z]\w+)?$/i;
$VERSION = sprintf("%d.%02d", q$Revision: 2.13 $ =~ /(\d+)\.(\d+)/);
@EXPORT  = qw($NUMBER $VALUE $VAL_NONE $VAL_ONE $VAL_UNDEF $VAL_ZERO);
@ISA     = qw(Exporter);

# Define the global private constants
my $HASH    = 'RDA::Value::Hash';
my $LIST    = 'RDA::Value::List';
my $POINTER = 'RDA::Value::Pointer';
my $SCALAR  = 'RDA::Value::Scalar';

my $ARRAY  = qr/^RDA::Value::(Array|List)$/i;
my $ASSOC  = qr/^RDA::Value::(Assoc|Hash)$/i;

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h-E<gt>get_hash>

This method returns the internal hash of an object. Otherwise, it returns the
object reference.

=cut

sub get_hash
{ shift;
}

=head2 S<$h-E<gt>get_info($key[,$dft])>

This method returns the value that is associated with a given attribute. When
the attribute does not exist, it returns the default value.

=cut

sub get_info
{ my ($slf, $key, $val) = @_;

  $val = $slf->{$key} if exists($slf->{$key});
  $val;
}

=head2 S<$h-E<gt>has_methods>

This method indicates whether the value has methods.

=cut

sub has_methods
{ 0;
}

=head2 S<$h-E<gt>is_array>

This method indicates whether the value is a list or an array.

=cut

sub is_array
{ 0;
}

=head2 S<$h-E<gt>is_call>

This method indicates whether it assimilates the value to a macro call or an
object method invocation.

=cut

sub is_call
{ 0;
}

=head2 S<$h-E<gt>is_code>

This method indicates whether the value is a named block.

=cut

sub is_code
{ '';
}

=head2 S<$h-E<gt>is_defined>

This method indicates whether the value is defined.

=cut

sub is_defined
{ 1;
}

=head2 S<$h-E<gt>is_hash>

This method indicates whether the value is an associative array.

=cut

sub is_hash
{ 0;
}

=head2 S<$h-E<gt>is_item>

This method indicates whether the value is a list item.

=cut

sub is_item
{ 1;
}

=head2 S<$h-E<gt>is_list>

This method indicates whether the value is a list.

=cut

sub is_list
{ 0;
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value.

=cut

sub is_lvalue
{ '';
}

=head2 S<$h-E<gt>is_method>

This method indicates whether the value is a method invocation.

=cut

sub is_method
{ '';
}

=head2 S<$h-E<gt>is_object>

This method indicates whether the value is an object.

=cut

sub is_object
{ '';
}

=head2 S<$h-E<gt>is_operator>

This method indicates whether the value is an operator.

=cut

sub is_operator
{ '';
}

=head2 S<$h-E<gt>is_pointer>

This method indicates whether the value is a variable pointer.

=cut

sub is_pointer
{ '';
}

=head2 S<$h-E<gt>is_scalar_lvalue>

This method indicates whether the value is a left value that requires a scalar
in assignment.

=cut

sub is_scalar_lvalue
{ shift->is_lvalue eq '$';
}

=head2 S<$h-E<gt>set_info($key,$val)>

This method assigns the specified value to a given key.

=cut

sub set_info
{ my ($slf, $key, $val) = @_;

  $slf->{$key} = $val;
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>assign_value($val[,$flg])>

This method assigns a new value. It evaluates the new value unless the flag is
set. It returns the new value.

=cut

sub assign_value
{ my ($slf, $val, $flg) = @_;
  my ($trc);

  # Evaluate the value
  $val = $val->eval_value unless $flg;

  # Perform the assignment and return the value
  $trc->[0]->trace_value($trc->[1], $trc->[2])
    if ($trc = $slf->is_list
      ? $slf->assign_item($val->is_list ? [@$val] : [$val])
      : $slf->assign_var($val));

  # Return the value
  $val;
}

sub assign_item
{ die "RDA-00810: Cannot determine if a '".ref(shift)
    ."' value is usable as a left value\n";
}

sub assign_var
{ die "RDA-00810: Cannot determine if a '".ref(shift)
    ."' value is usable as a left value\n";
}

sub find_object
{ my ($slf, $typ) = @_;

  die "RDA-00811: Cannot use a '".ref($slf)
    ."' value in complex data structures\n" if $typ;
  ();
}

=head2 S<RDA::Value::convert_value($val)>

This method converts a Perl value into a value.

=cut

sub convert_value
{ _gen_value({}, @_);
}

sub _gen_value
{ my ($tbl, $val) = @_;
  my ($ref);

  $ref = ref($val);
  ($ref =~ $VALUE)               ? $val :
  ($ref && exists($tbl->{$val})) ? $tbl->{$val} :
  ($ref eq 'ARRAY')              ? _gen_array($tbl, $val) :
  ($ref eq 'HASH')               ? _gen_hash($tbl, $val) :
                                   RDA::Value::Scalar::new_from_data($val);
}

sub _gen_array
{ my ($tbl, $src) = @_;
  my ($dst);

  $tbl->{$src} = $dst = RDA::Value::Array->new;
  foreach my $itm (@$src)
  { push(@$dst, _gen_value($tbl, $itm));
  }
  $dst;
}

sub _gen_hash
{ my ($tbl, $src) = @_;
  my ($dst);

  $tbl->{$src} = $dst = RDA::Value::Assoc->new;
  foreach my $key (keys(%$src))
  { $dst->{$key} = _gen_value($tbl, $src->{$key});
  }
  $dst;
}

=head2 S<$h-E<gt>copy_value($flg)>

This method returns a copy of the data structure. When the flag is set, it
evaluates values.

=cut

sub copy_value
{ shift;
}

sub copy_array
{ my ($dst, $src, $tbl, $flg) = @_;

  $tbl->{$src} = $dst;
  foreach my $val (@$src)
  { copy_index($dst, $tbl, $val, $flg);
  }
  $dst;
}

sub copy_hash
{ my ($dst, $src, $tbl, $flg) = @_;

  $tbl->{$src} = $dst;
  foreach my $key (keys(%$src))
  { $dst->{$key} = copy_key($tbl, $src->{$key}, $flg);
  }
  $dst;
}

sub copy_index
{ my ($dst, $tbl, $val, $flg) = @_;
  my ($ref);

  $ref = ref($val);
  if ($ref eq $SCALAR)
  { push(@$dst, $val)
  }
  elsif ($ref && exists($tbl->{$val}))
  { push(@$dst, $tbl->{$val});
  }
  elsif ($ref =~ $ARRAY)
  { push(@$dst, copy_array($val->new, $val, $tbl, $flg));
  }
  elsif ($ref =~ $ASSOC)
  { push(@$dst, copy_hash($val->new, $val, $tbl, $flg));
  }
  elsif ($ref =~ $VALUE)
  { if ($flg)
    { $tbl->{$val} = $val;
      copy_index($dst, $tbl, $val->copy_object(1));
    }
    else
    { push(@$dst, $val);
    }
  }
  elsif ($ref eq 'ARRAY')
  { push(@$dst, copy_array(RDA::Value::Array->new, $val, $tbl, $flg));
  }
  elsif ($ref eq 'HASH')
  { push(@$dst, copy_hash(RDA::Value::Assoc->new, $val, $tbl, $flg));
  }
  else
  { push(@$dst, RDA::Value::Scalar::new_from_data($val));
  }
}

sub copy_key
{ my ($tbl, $val, $flg) = @_;
  my ($ref);

  $ref = ref($val);
  ($ref eq $SCALAR) ?
    $val :
  ($ref && exists($tbl->{$val})) ?
    $tbl->{$val} :
  ($ref =~ $ARRAY) ?
    copy_array($val->new, $val, $tbl, $flg) :
  ($ref =~ $ASSOC) ?
    copy_hash($val->new, $val, $tbl, $flg) :
  ($ref =~ $VALUE) ?
    ($flg ? copy_key($tbl, ($tbl->{$val} = $val)->copy_object($flg)) : $val) :
  ($ref eq 'ARRAY') ?
    copy_array(RDA::Value::Array->new, $val, $tbl, $flg) :
  ($ref eq 'HASH') ?
    copy_hash(RDA::Value::Assoc->new, $val, $tbl, $flg) :
  RDA::Value::Scalar::new_from_data($val);
}

sub copy_object
{ shift;
}

=head2 S<$h-E<gt>decr_value([$num])>

This method decrements a value and returns the new value.

=cut

sub decr_value
{ my ($slf, $val) = @_;

  $slf->assign_var(defined($val) ? -$val : -1, 1);
}

=head2 S<$h-E<gt>delete_value>

This method deletes a left value or a list of left values and returns their
previous content.

=cut

sub delete_value
{ die "RDA-00812: Cannot delete a '".ref(shift)."' value\n";
}

=head2 S<$h-E<gt>eval_as_array>

This method evaluates the value and returns the evaluation result as a Perl
list. It executes code values. When the flag is set, the value is directly
converted without being evaluated again.

=cut

sub eval_as_array
{ shift->eval_value(1)->as_array;
}

=head2 S<$h-E<gt>eval_as_data([$flg])>

This method evaluates the value and returns the evaluation result as a Perl
data structure.

When the flag is set, it executes code values.

=cut

sub eval_as_data
{ my ($slf, $flg) = @_;

  $slf->eval_value($flg)->as_data($flg);
}

=head2 S<$h-E<gt>eval_as_line>

This method evaluates the value and returns the evaluation result as a text
line. It executes code values. It ignores all undefined values and object
references.

=cut

sub eval_as_line
{ shift->eval_value(1)->as_line;
}

=head2 S<$h-E<gt>eval_as_number>

This method evaluates the value and returns the evaluation result as a Perl
number. It executes code values.

=cut

sub eval_as_number
{ shift->eval_value(1)->as_number;
}

=head2 S<$h-E<gt>eval_as_scalar>

This method evaluates the value and returns the evaluation result as a Perl
scalar. It executes code values.

=cut

sub eval_as_scalar
{ shift->eval_value(1)->as_scalar;
}

=head2 S<$h-E<gt>eval_as_string>

This method evaluates the value and returns the evaluation result as a Perl
string. It executes code values.

=cut

sub eval_as_string
{ shift->eval_value(1)->as_string;
}

=head2 S<$h-E<gt>eval_code($dft)>

This method resolves code values.

=cut

sub eval_code
{ shift;
}

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a value. It resolves the variables and executes
appropriate macro calls. When there is an evaluation problem, it returns an
undefined value.

When the flag is set, it executes code values.

=cut

sub eval_value
{ shift;
}

=head2 S<$h-E<gt>incr_value([$num])>

This method increments a value and returns the new value.

=cut

sub incr_value
{ my ($slf, $val) = @_;

  $slf->assign_var(defined($val) ? $val : 1, 1);
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_array>

This method converts the value in a Perl list, without altering complex data
structures.

=cut

sub as_array
{ die "RDA-00813: Cannot convert a '".ref(shift)."' value in a Perl list\n";
}

=head2 S<$h-E<gt>as_data($flg)>

This method converts the value as a list of Perl data structures. When the
flag is set, it executes code blocks.

=cut

sub as_data
{ shift;
}

sub conv_array
{ my ($dst, $src, $tbl) = @_;

  $tbl->{$src} = $dst;
  foreach my $val (@$src)
  { conv_index($dst, $tbl, $val);
  }
  $dst;
}

sub conv_hash
{ my ($dst, $src, $tbl) = @_;

  $tbl->{$src} = $dst;
  foreach my $key (keys(%$src))
  { $dst->{$key} = conv_key($tbl, $src->{$key});
  }
  $dst;
}

sub conv_index
{ my ($dst, $tbl, $val) = @_;
  my ($ref);

  $ref = ref($val);
  if ($ref eq $SCALAR)
  { push(@$dst, $val->as_scalar)
  }
  elsif ($ref eq $LIST)
  { push(@$dst, @$val);
  }
  elsif ($ref eq $HASH)
  { push(@$dst, %$val);
  }
  elsif ($ref && exists($tbl->{$val}))
  { push(@$dst, $tbl->{$val});
  }
  elsif ($ref eq 'ARRAY' || $ref =~ $ARRAY)
  { push(@$dst, conv_array([], $val, $tbl));
  }
  elsif ($ref eq 'HASH' || $ref =~ $ASSOC)
  { push(@$dst, conv_hash({}, $val, $tbl));
  }
  elsif ($ref eq $POINTER)
  { conv_index($dst, $tbl, $val->get_value);
  }
  elsif ($ref =~ $VALUE)
  { conv_index($dst, $tbl, $val->eval_value(1));
  }
  else
  { push(@$dst, $val);
  }
}

sub conv_key
{ my ($tbl, $val) = @_;
  my ($ref);

  $ref = ref($val);
  ($ref eq $SCALAR)                   ? $val->as_scalar :
  ($ref && exists($tbl->{$val}))      ? $tbl->{$val} :
  ($ref eq 'ARRAY' || $ref =~ $ARRAY) ? conv_array([], $val, $tbl) :
  ($ref eq 'HASH' || $ref =~ $ASSOC)  ? conv_hash({}, $val, $tbl) :
  ($ref eq $POINTER)                  ? conv_key($tbl, $val->get_value) :
  ($ref =~ $VALUE)                    ? conv_key($tbl, $val->eval_value(1)) :
                                        $val;
}

=head2 S<$h-E<gt>as_dump>

This method converts the value as a dump string.

=cut

sub as_dump
{ shift->dump;
}

=head2 S<$h-E<gt>as_line>

This method converts the value as a text line. It ignores all undefined values
and all object references.

=cut

sub as_line
{ my ($slf) = @_;

  join('', grep {defined($_) && !ref($_)} $slf->as_array)."\n";
}

=head2 S<$h-E<gt>as_number>

This method converts the value as a Perl number.

=cut

sub as_number
{ die "RDA-00814: Not a numeric value\n";
}

=head2 S<$h-E<gt>as_string($dft)>

This method converts the value as a Perl string. When the conversion is not
possible it generates an error, except if a default value is provided.

=cut

sub as_string
{ my ($slf, $dft) = @_;

  die "RDA-00815: Not a text string\n" unless defined($dft);
  $dft;
}

=head2 S<$h-E<gt>as_scalar>

This method converts the value as a Perl scalar.

=cut

sub as_scalar
{ undef;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Driver::Da|RDA::Driver::Da.pm>,
L<RDA::Driver::Dbd|RDA::Driver::Dbd.pm>,
L<RDA::Driver::Jdbc|RDA::Driver::Jdbc.pm>,
L<RDA::Driver::Jsch|RDA::Driver::Jsch.pm>,
L<RDA::Driver::Local|RDA::Driver::Local.pm>,
L<RDA::Driver::Rsh|RDA::Driver::Rsh.pm>,
L<RDA::Driver::Sqlplus|RDA::Driver::Sqlplus.pm>,
L<RDA::Driver::Ssh|RDA::Driver::Ssh.pm>,
L<RDA::Driver::WinOdbc|RDA::Driver::WinOdbc.pm>,
L<RDA::Handle::Area|RDA::Handle::Area.pm>,
L<RDA::Handle::Block|RDA::Handle::Block.pm>,
L<RDA::Handle::Data|RDA::Handle::Data.pm>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate.pm>,
L<RDA::Handle::Filter|RDA::Handle::Filter.pm>,
L<RDA::Handle::Memory|RDA::Handle::Memory.pm>,
L<RDA::Library::Admin|RDA::Library::Admin>,
L<RDA::Library::Archive|RDA::Library::Archive>,
L<RDA::Library::Buffer|RDA::Library::Buffer>,
L<RDA::Library::Data|RDA::Library::Data>,
L<RDA::Library::Db|RDA::Library::Db>,
L<RDA::Library::Dbi|RDA::Library::Dbi>,
L<RDA::Library::Env|RDA::Library::Env>,
L<RDA::Library::Expr|RDA::Library::Expr>,
L<RDA::Library::File|RDA::Library::File>,
L<RDA::Library::Ftp|RDA::Library::Ftp>,
L<RDA::Library::Hcve|RDA::Library::Hcve>,
L<RDA::Library::Html|RDA::Library::Html>,
L<RDA::Library::Http|RDA::Library::Http>,
L<RDA::Library::Invent|RDA::Library::Invent>,
L<RDA::Library::Remote|RDA::Library::Remote>,
L<RDA::Library::String|RDA::Library::String>,
L<RDA::Library::Table|RDA::Library::Table>,
L<RDA::Library::Temp|RDA::Library::Temp>,
L<RDA::Library::Value|RDA::Library::Value>,
L<RDA::Library::Windows|RDA::Library::Windows>,
L<RDA::Library::Xml|RDA::Library::Xml>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Access|RDA::Object::Access.pm>,
L<RDA::Object::Buffer|RDA::Object::Buffer.pm>,
L<RDA::Object::Convert|RDA::Object::Convert.pm>,
L<RDA::Object::Cookie|RDA::Object::Cookie.pm>,
L<RDA::Object::Display|RDA::Object::Display.pm>,
L<RDA::Object::Domain|RDA::Object::Domain.pm>,
L<RDA::Object::Env|RDA::Object::Env.pm>,
L<RDA::Object::Explorer|RDA::Object::Explorer.pm>,
L<RDA::Object::Ftp|RDA::Object::Ftp.pm>,
L<RDA::Object::Home|RDA::Object::Home.pm>,
L<RDA::Object::Html|RDA::Object::Html.pm>,
L<RDA::Object::Index|RDA::Object::Index.pm>,
L<RDA::Object::Inline|RDA::Object::Inline.pm>,
L<RDA::Object::Instance|RDA::Object::Instance.pm>,
L<RDA::Object::Jar|RDA::Object::Jar.pm>,
L<RDA::Object::Java|RDA::Object::Java.pm>,
L<RDA::Object::Lock|RDA::Object::Lock.pm>,
L<RDA::Object::Mrc|RDA::Object::Mrc.pm>,
L<RDA::Object::Output|RDA::Object::Output.pm>,
L<RDA::Object::Parser|RDA::Object::Parser.pm>,
L<RDA::Object::Pipe|RDA::Object::Pipe.pm>,
L<RDA::Object::Pod|RDA::Object::Pod.pm>,
L<RDA::Object::Rda|RDA::Object::Rda.pm>,
L<RDA::Object::Remote|RDA::Object::Remote.pm>,
L<RDA::Object::Report|RDA::Object::Report.pm>,
L<RDA::Object::Request|RDA::Object::Request.pm>,
L<RDA::Object::Response|RDA::Object::Response.pm>,
L<RDA::Object::Sgml|RDA::Object::Sgml.pm>,
L<RDA::Object::SshAgent|RDA::Object::SshAgent.pm>,
L<RDA::Object::System|RDA::Object::System.pm>,
L<RDA::Object::Table|RDA::Object::Table.pm>,
L<RDA::Object::Target|RDA::Object::Target.pm>,
L<RDA::Object::Toc|RDA::Object::Toc.pm>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent.pm>,
L<RDA::Object::Windows|RDA::Object::Windows.pm>,
L<RDA::Object::WlHome|RDA::Object::WlHome.pm>,
L<RDA::Object::Xml|RDA::Object::Xml.pm>,
L<RDA::Operator::Array|RDA::Operator::Array>,
L<RDA::Operator::Hash|RDA::Operator::Hash>,
L<RDA::Operator::Scalar|RDA::Operator::Scalar>,
L<RDA::Operator::Value|RDA::Operator::Value>,
L<RDA::Value::Array|RDA::Value::Array>,
L<RDA::Value::Assoc|RDA::Value::Assoc>,
L<RDA::Value::Code|RDA::Value::Code>,
L<RDA::Value::Global|RDA::Value::Global>,
L<RDA::Value::Hash|RDA::Value::Hash>,
L<RDA::Value::Internal|RDA::Value::Internal>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Operator|RDA::Value::Operator>,
L<RDA::Value::Pointer|RDA::Value::Pointer>,
L<RDA::Value::Property|RDA::Value::Property>,
L<RDA::Value::Scalar|RDA::Value::Scalar>,
L<RDA::Value::Variable|RDA::Value::Variable>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
