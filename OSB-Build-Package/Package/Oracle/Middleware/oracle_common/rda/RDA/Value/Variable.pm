# Variable.pm: Class Used for Managing RDA Variables

package RDA::Value::Variable;

# $Id: Variable.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Variable.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Variable - Class Used for Managing RDA Variables

=head1 SYNOPSIS

require RDA::Value::Variable;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Variable> class are used to manage RDA
variables.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Hash;
  use RDA::Value::List;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Variable-E<gt>new($ctx,$nam)>

The object constructor. It takes the execution context reference and the
variable name as extra arguments.

A C<RDA::Value::Variable> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'ctx' > > Reference to the execution context

=item S<    B<'nam' > > Variable name

=item S<    B<'var' > > Variable type

=back

=cut

sub new
{ my ($cls, $ctx, $nam) = @_;

  # Create the variable value object and return its reference
  bless {
    ctx => $ctx,
    nam => $nam,
    var => substr($nam, 0, 1),
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the object dump. You can provide an
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

  '  ' x $lvl.$txt.'Variable='.$slf->{'nam'};
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value.

=cut

sub is_lvalue
{ shift->{'var'};
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>delete_value>

This method deletes a variable and returns its previous content.

=cut

sub delete_value
{ my ($slf, $flg) = @_;

  $slf->{'ctx'}->delete_variable($slf->{'nam'}, $flg);
}

=head2 S<$h-E<gt>eval_value([$flg])>

This method resolves a variable. When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;
  my ($val);

  defined($val = $slf->{'ctx'}->get_value($slf->{'nam'}))
    ? $val->eval_value($flg)
    : $VAL_UNDEF;
}

# --- Assign mechanim ---------------------------------------------------------

sub assign_item
{ my ($slf, $tbl) = @_;
  my ($typ);

  $typ = $slf->{'var'};
  $slf->{'ctx'}->set_value($slf->{'nam'},
    ($typ eq '@') ? RDA::Value::List->new(splice(@$tbl, 0)) :
    ($typ eq '%') ? RDA::Value::Hash::new_from_list($tbl) :
                    shift(@$tbl) || $VAL_UNDEF);
  undef;
}

sub assign_var
{ my ($slf, $val, $flg) = @_;
  my ($typ);

  # Treat an incrementation
  return $slf->{'ctx'}->incr_value($slf->{'nam'}, $val) if $flg;

  # Treat an assignment
  $typ = $slf->{'var'};
  if ($typ eq '$')
  { $slf->{'ctx'}->set_value($slf->{'nam'}, $val->is_list
      ? RDA::Value::Scalar->new('N', (scalar @$val))
      : $val);
  }
  elsif ($typ eq '@')
  { $slf->{'ctx'}->set_value($slf->{'nam'}, $val->is_list
      ? $val
      : RDA::Value::List->new($val));
  }
  elsif ($typ eq '%')
  { $slf->{'ctx'}->set_value($slf->{'nam'},
      RDA::Value::Hash::new_from_list($val->is_list ? [@$val] : [$val]));
  }
  undef;
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

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Hash|RDA::Value::Hash>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
