# Pointer.pm: Class Used for Managing RDA Variable Pointers

package RDA::Value::Pointer;

# $Id: Pointer.pm,v 2.5 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Pointer.pm,v 2.5 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Pointer - Class Used for Managing RDA Variable Pointers

=head1 SYNOPSIS

require RDA::Value::Pointer;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Pointer> class are used to manage RDA
variable pointers.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Array;
  use RDA::Value::Hash;
  use RDA::Value::List;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Pointer-E<gt>new($ctx,$nam)>

The pointer object constructor. It takes the execution context reference and
the variable name as extra arguments.

=head2 S<$h = $p-E<gt>new>

The reference object constructor. It converts the variable pointer into a
variable reference.

A C<RDA::Value::Pointer> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'ctx' > > Reference to the execution context

=item S<    B<'dic' > > Reference to the execution context dictionary

=item S<    B<'nam' > > Variable name

=item S<    B<'var' > > Variable type

=back

=cut

sub new
{ my ($cls, $ctx, $nam) = @_;

  # Create the variable value object and return its reference
  ref($cls)
    ? bless {
        dic => $cls->{'ctx'}->get_dict,
        %$cls,
        }, ref($cls)
    : bless {
        ctx => $ctx,
        nam => $nam,
        var => substr($nam, 0, 1),
        }, $cls;
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
  my $pre;

  $pre = '  ' x $lvl++;
  exists($slf->{'dic'})
    ? $pre.$txt.'Reference='.$slf->{'nam'}
    : $pre.$txt.'Pointer='.$slf->{'nam'};
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value.

=cut

sub is_lvalue
{ 1;
}

=head2 S<$h-E<gt>is_pointer>

This method indicates whether the value is a variable pointer.

=cut

sub is_pointer
{ shift->{'var'};
}

=head2 S<$h-E<gt>is_scalar_lvalue>

This method indicates whether the value is a left value that requires a scalar
in assignment.

=cut

sub is_scalar_lvalue
{ 1;
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a value. It resolves the variables and executes
appropriate macro calls. When there is an evaluation problem, it returns an
undefined value.

When the flag is set, it executes code values.

=cut

sub eval_value
{ shift->new;
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>get_value>

This method resolves the pointer and returns the value.

=cut

# --- Assign mechanim ---------------------------------------------------------

sub assign_item
{ my ($slf, $tbl) = @_;

  $slf->{'ctx'}->share_variable($slf->{'nam'}, shift(@$tbl));
  undef;
}

sub assign_var
{ my ($slf, $val, $flg) = @_;

  # Treat an incrementation
  return $slf->{'ctx'}->incr_value($slf->{'nam'}, $val) if $flg;

  # Share the variable
  $slf->{'ctx'}->share_variable($slf->{'nam'}, $val);
  undef;
}

# --- Copy mechanim -----------------------------------------------------------

sub copy_object
{ my ($slf, $flg) = @_;
  my ($val);

  $val = $slf->{'ctx'}->get_value($slf->{'nam'});
  return defined($val) 
    ? RDA::Value::Scalar::new_number(scalar @$val)
    : $VAL_ZERO
    if $slf->{'var'} eq '@';
  return defined($val) 
    ? RDA::Value::Scalar::new_number(scalar @{[%$val]})
    : $VAL_ZERO
    if $slf->{'var'} eq '%';
  defined($val) ? $val : $VAL_UNDEF;
}

# --- Find object mechanim ----------------------------------------------------

sub find_object
{ my ($slf, $typ) = @_;
  my ($trc, $val);

  # Treat a request without creating the variable
  unless ($typ)
  { return ()
      unless ($trc =  $slf->{'ctx'}->get_content($slf->{'nam'}));
    return ($trc->[2]);
  }

  # Get the variable value, creating the variable when needed
  if ($slf->{'var'} eq $typ)
  { $val = $slf->{'ctx'}->get_value($slf->{'nam'}, 1);
    return ($val, [$slf->{'ctx'}, $slf->{'nam'}, $val]);
  }
  if ($slf->{'var'} eq '$')
  { return ()
      unless ($trc = $slf->{'ctx'}->get_content($slf->{'nam'}, 1, ".$typ"));
    return ($trc->[2], $trc);
  }
  die "RDA-00820: Incompatible types\n";
}

# --- Get the associated value ------------------------------------------------

sub get_value
{ my ($slf) = @_;
  my ($trc);

  ($trc = $slf->{'ctx'}->get_content($slf->{'nam'})) ? $trc->[2] : $VAL_UNDEF;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Array|RDA::Value::Array>,
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
