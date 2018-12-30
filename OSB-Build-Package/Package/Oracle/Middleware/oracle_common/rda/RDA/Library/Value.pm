# Value.pm: Class Used for Value Macros

package RDA::Library::Value;

# $Id: Value.pm,v 2.6 2012/04/25 06:33:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Value.pm,v 2.6 2012/04/25 06:33:04 mschenke Exp $
#
# Change History
# 20120122  MSC  Modify the access control.

=head1 NAME

RDA::Library::Value - Class Used for Value Macros

=head1 SYNOPSIS

require RDA::Library::Value;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Value> class are used to interface with
value-related macros.

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
my $RE_MOD = qr/^S(\d{3})([A-Z]\w*)$/i;

my %tb_fct = (
  'can'      => \&_m_can,
  'new'      => \&_m_new,
  'setClass' => \&_m_set_class,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Value-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Value> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_lvl'> > Debug/trace level hash

=back

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the library object
  $slf = bless {
    _agt => $agt,
    _lvl => {},
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)]);

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code. It requires external conversion of the
argument list and of the return value.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}}($slf, [@arg]);
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method runs the macro with the specified argument list in a given context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;

  return &{$tb_fct{$nam}}($slf, $ctx, $arg);
}

=head1 OBJECT RELATED MACROS

=head2 S<can($class,$name)>

This macro indicates if the specified method is supported by that object
class. An object can be specified as a class.

=cut

sub _m_can
{ my ($slf, $ctx, $arg) = @_;
  my ($cls, $def, $nam, $obj, $use);

  # Validate the arguments
  ($obj, $nam) = @$arg;
  return $VAL_ZERO
    unless $obj && $nam && ($nam = $nam->eval_value(1)->as_string(''));

  # Determine the object class
  $obj = $obj->eval_value(1);
  return $VAL_ZERO 
    unless ($cls = $obj->is_object) || ($cls = $obj->as_string(''));

  # Check the Perl object
  $use = $ctx->get_top('use');
  (defined($cls = _get_class($use, $cls)) && exists($use->{$cls})
    && exists($use->{$cls}->{'obj'}->{$nam}))
    ? $VAL_ONE
    : $VAL_ZERO;
}

=head2 S<new($class[,$arg,...])>

This macro creates a new object and returns a reference to it. An object can be
specified as a class.

=cut

sub _m_new
{ my ($slf, $ctx, $arg) = @_;
  my ($cls, $def, $flg, $new, $obj, $use, @arg);

  # Determine the object class
  ($obj, @arg) = @$arg;
  return $VAL_UNDEF unless ref($obj = $obj->eval_value(1));
  if ($cls = $obj->is_object)
  { $obj = $obj->as_scalar || $cls ;
  }
  elsif ($cls = $obj->as_string(''))
  { $obj = $cls;
  }
  else
  { return $VAL_UNDEF;
  }

  # Validate the Perl object class
  $use = $ctx->get_top('use');
  return $VAL_UNDEF
    unless exists($use->{$cls}) || exists($use->{$cls = "RDA::Object::$cls"});

  # Create a Perl object
  die "RDA-00517: 'new' macro not supported for '$cls'\n"
    unless exists($use->{$cls}->{'new'});
  eval {
    $flg = $use->{$cls}->{'new'};
    $new = $cls->new(map {$_->eval_as_data($flg)} @arg);
    $new->set_authen($slf->{'_agt'}->get_access) if $use->{$cls}->{'pwd'};
    if (exists($use->{$cls}->{'trc'}))
    { $slf->{'_lvl'}->{$cls} = $ctx->get_top('out')
        ? 0
        : $slf->{'_agt'}->get_setting($use->{$cls}->{'trc'})
        unless exists($slf->{'_lvl'}->{$cls});
      $new->set_trace($slf->{'_lvl'}->{$cls});
    }
    };
  die "RDA-00518: Object creation error ($@)\n" if $@;
  RDA::Value::Scalar::new_object($new, 1);
}

=head2 S<setClass($class[,$level])>

This macro sets the trace level for an object class.

It returns the previous trace level.

=cut

sub _m_set_class
{ my ($slf, $ctx, $arg) = @_;
  my ($cls, $lvl, $old, $pkg);

  ($cls, $lvl) = $arg->eval_as_array;
  return $VAL_UNDEF
    unless defined($cls)
        && defined($cls = _get_class($ctx->get_package('use'), $cls));
  $old = $slf->{'_lvl'}->{$cls};
  if ($ctx->get_top('out'))
  { $slf->{'_lvl'}->{$cls} = 0;
  }
  elsif (defined($lvl) && $lvl =~ m/^\d+$/)
  { $slf->{'_lvl'}->{$cls} = $lvl;
  }
  RDA::Value::Scalar::new_number($old);
}

sub _get_class
{ my ($use, $nam) = @_;
  my ($cls);

  if ($cls = ref($nam))
  { return undef unless exists($use->{$cls});
  }
  elsif (defined($nam))
  { return undef unless exists($use->{$cls = $nam})
                     || exists($use->{$cls = "RDA::Object::$nam"});
  }
  $cls;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Object|RDA::Object>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
