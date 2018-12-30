# Invent.pm: Class Used for Inventory Macros

package RDA::Library::Invent;

# $Id: Invent.pm,v 2.5 2012/04/25 06:35:03 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Invent.pm,v 2.5 2012/04/25 06:35:03 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Library::Invent - Class Used for Inventory Macros

=head1 SYNOPSIS

require RDA::Library::Invent;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Invent> class are used to interface with
inventory-related macros.

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
my %tb_fct = (
  'getLocation'  => [\&_m_get_location,  'T'],
  'getProduct'   => [\&_m_get_product,   'T'],
  'getVersion'   => [\&_m_get_version,   'T'],
  'hasInventory' => [\&_m_has_inventory, 'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Invent-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Invent> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_dis'> > Auto discovery object reference

=back

Internal keys are prefixed by an underscore.

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
context.

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

=head1 INVENTORY MACROS

=head2 S<getLocation($nam[,$dft])>

This macro returns the location of the specified component. It returns the
default value when there is no inventory information.

=cut

sub _m_get_location
{ my ($slf, $ctx, $nam, $dft) = @_;

  ($slf = $slf->_discover)
    ? $slf->find('LOCATION', $nam, $dft)
    : $dft;
}

=head2 S<getProduct([$dft])>

This macro returns the extended name of the product. It returns the default
value when there is no inventory information.

=cut

sub _m_get_product
{ my ($slf, $ctx, $dft) = @_;

  ($slf = $slf->_discover)
    ? $slf->get_product($dft)
    : $dft;
}

=head2 S<getVersion($nam[,$dft])>

This macro returns the version of the specified component. It returns the
default value when there is no inventory information.

=cut

sub _m_get_version
{ my ($slf, $ctx, $nam, $dft) = @_;

  ($slf = $slf->_discover)
    ? $slf->find('VERSION', $nam, $dft)
    : $dft;
}

=head2 S<hasInventory()>

This macro indicates whether inventory information is available.

=cut

sub _m_has_inventory
{ defined(shift->_discover);
}

# --- Internal routines -------------------------------------------------------

# Get the auto discovery object
sub _discover
{ my ($slf) = @_;

  return $slf->{'_dis'} if exists($slf->{'_dis'});
  $slf->{'_dis'} = $slf->{'_agt'}->get_discover;
  $slf->{'_dis'};
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
