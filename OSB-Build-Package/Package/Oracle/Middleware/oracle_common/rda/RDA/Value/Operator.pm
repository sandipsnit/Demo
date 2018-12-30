# Operator.pm: Class Used for Managing Value Operators

package RDA::Value::Operator;

# $Id: Operator.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Operator.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Operator - Class Used for Managing Value Operators

=head1 SYNOPSIS

require RDA::Value::Operator;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Operator> class are be used for storing value
operators. They are represented by a blessed hash reference. The following
internal keys are required:

=over 12

=item S<    B<'_del'> > Associated 'delete' routine

=item S<    B<'_fnd'> > Associated 'find' routine

=item S<    B<'_get'> > Associated 'get' routine

=item S<    B<'_lft'> > Left value indicator

=item S<    B<'_set'> > Associated 'set' routine

=item S<    B<'_typ'> > Operator name

=back

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @EXPORT @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@EXPORT  = qw(del_error find_error set_error);
@ISA     = qw(RDA::Value Exporter);

# Define the global private variables
my $OBJECT = qr/^RDA::Object::/i;
my $RDA    = qr/^RDA(::[A-Z]\w+){1,2}$/i;
my $VALUE  = qr/^RDA::Value(::[A-Z]\w+)?$/i;

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h-E<gt>clone($value)>

This method returns a copy of the operator with a merge of both argument lists.

=cut

sub clone
{ my ($src, $val) = @_;
  my ($dst);

  $dst = bless {%$src}, ref($src);
  $dst->{'arg'} = RDA::Value::List->new(@{$src->{'arg'}}, @$val);
  $dst;
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
  my ($buf, $pre, $ref, $val);

  $pre = '  ' x $lvl++;
  $buf = $pre.$txt.'Operator=<'.$slf->{'_typ'}.'>(';
  foreach my $key (sort grep {m/^[a-z]/i} keys(%$slf))
  { $ref = ref($val = $slf->{$key});
    $buf .= "\n";
    $buf .= ($ref =~ $VALUE) ?
              $val->dump_object($tbl, $lvl, "'$key' => ") :
            ($ref =~ $OBJECT || ($ref =~ $RDA && $val->can('as_class'))) ?
              $val->dump($lvl, "'$key' => Object=") :
            $ref ?
              $pre."  '$key' => Object=bless ...,$ref" :
            $pre."  '$key' => '$val'";
  }
  $buf."\n".$pre.')';
}

=head2 S<$h-E<gt>is_call>

This method indicates whether it assimilates the value to a macro call or an
object method invocation.

=cut

sub is_call
{ 1;
}

=head2 S<$h-E<gt>is_item>

This method indicates whether the value is a list item.

=cut

sub is_item
{ 0;
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value.

=cut

sub is_lvalue
{ my ($slf)  = @_;

  (ref($slf->{'_lft'}) eq 'CODE') ? &{$slf->{'_lft'}}($slf) : $slf->{'_lft'};
}

=head2 S<$h-E<gt>is_method>

This method indicates whether the value is a method invocation.

=cut

sub is_method
{ my ($slf) = @_;

  ($slf->{'_typ'} eq '.method.') ? $slf->{'nam'} : '';
}

=head2 S<$h-E<gt>is_operator>

This method indicates whether the value is an operator.

=cut

sub is_operator
{ shift->{'_typ'};
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>delete_value>

This method deletes a left value and return its previous content.

=cut

sub delete_value
{ my ($slf, $flg) = @_;
  my ($trc, $val);

  ($val, $trc) = &{$slf->{'_del'}}($slf);
  $trc->[0]->trace_value($trc->[1], $trc->[2]) if $trc;
  return $val if defined($val);
  return () if $flg;
  $VAL_UNDEF;
}

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a value. It resolves the variables and executes
appropriate macro calls. When there is an evaluation problem, it returns an
undefined value.

When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf) = @_;

  &{$slf->{'_get'}}(@_);
}

# --- Assign mechanim ---------------------------------------------------------

sub assign_item
{ my $slf = shift;

  &{$slf->{'_set'}}($slf, 1, @_);
}

sub assign_var
{ my $slf = shift;

  &{$slf->{'_set'}}($slf, 0, @_);
}

# --- Find object mechanim ----------------------------------------------------

sub find_object
{ my ($slf) = @_;

  &{$slf->{'_fnd'}}(@_);
}

# --- Error routines ----------------------------------------------------------

sub del_error
{ my ($slf) = @_;

  die "RDA-00830: Delete not implemented for '".$slf->{'_typ'}."'\n";
}

sub find_error
{ my ($slf) = @_;

  die "RDA-00831: Find not implemented for '".$slf->{'_typ'}."'\n";
}

sub set_error
{ my ($slf) = @_;

  die "RDA-00832: Assign not implemented for '".$slf->{'_typ'}."'\n";
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
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
