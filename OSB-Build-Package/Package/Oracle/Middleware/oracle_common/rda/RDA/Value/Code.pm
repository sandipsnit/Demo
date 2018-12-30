# Code.pm: Class Used for Managing Code Block References

package RDA::Value::Code;

# $Id: Code.pm,v 2.8 2012/04/25 06:21:18 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Code.pm,v 2.8 2012/04/25 06:21:18 mschenke Exp $
#
# Change History
# 20120422  MSC  Rename Language in Inline.

=head1 NAME

RDA::Value::Code - Class Used for Managing Code Block References

=head1 SYNOPSIS

require RDA::Value::Code;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Code> class are used to manage code block
references.

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.8 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Code-E<gt>new($typ,$blk,$nam[,$arg[,evl]])>

The object constructor. It takes the reference of the current block and the
code block name as arguments.

A C<RDA::Value::Code> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'arg' > > Optional invocation arguments

=item S<    B<'blk' > > Reference to the current block

=item S<    B<'cod' > > Associated code

=item S<    B<'evl' > > Indicates that the arguments must be evaluated directly

=item S<    B<'lng' > > Code block language

=item S<    B<'nam' > > Code block name

=item S<    B<'var' > > Associated type

=back

=cut

sub new
{ my ($cls, $blk, $lng, $nam, $arg, $evl) = @_;
  my (%tbl);

  # Detect the argument presence
  if (defined($arg))
  { $tbl{'arg'} = $arg;
    $tbl{'evl'} = 1 if defined($evl);
  }

  # Create the data collection object and return its reference
  bless {
    %tbl,
    blk => $blk,
    lng => $lng,
    nam => $nam,
    var => '&',
    }, ref($cls) || $cls;
}

sub new_code
{ my ($ctx, $cod) = @_;

  bless {
    cod => $cod,
    ctx => $ctx,
    lng => 'SDCL',
    }, __PACKAGE__;
}

sub new_eval
{ my ($slf) = @_;

  bless {
    arg => $slf->{'arg'}->eval_value,
    blk => $slf->{'blk'},
    lng => $slf->{'lng'},
    nam => $slf->{'nam'},
    var => '&',
    }, ref($slf);
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
  my ($buf, $fct);

  return '  ' x $lvl.$txt.'Code=(...)'
     if exists($slf->{'cod'});

  $fct = '&'.$slf->{'lng'}.'.'.$slf->{'nam'};
  return '  ' x $lvl.$txt.'Code='.$fct
     unless exists($slf->{'arg'});

  $tbl->{$slf->{'arg'}} = "$arg$fct)";
  $slf->{'arg'}->dump_object($tbl, $lvl, $txt.'Code='.$fct.' arg:',
    "$arg$fct,");
}

=head2 S<$h-E<gt>is_code([$flag])>

This method indicates whether the value is a named block. When the flag is set,
it does not consider SDCL block.

=cut

sub is_code
{ my ($slf, $flg) = @_;

  $flg ? $slf->{'lng'} ne 'SDCL' : $slf->{'lng'};
}

=head2 S<$h-E<gt>open_pipe($ofh)>

This method resolves code values.

=cut

sub open_pipe
{ my ($slf, $ofh) = @_;
  my ($lng, $nam, $pid, @arg);

  $lng = $slf->{'lng'};
  $nam = $slf->{'nam'};
  push(@arg, $slf->{'arg'}->eval_as_data) if exists($slf->{'arg'});
  die "RDA-00836: Cannot open a pipe to the $lng block '$nam'\n"
    unless $slf->{'lng'} ne 'SDCL'
    && ($pid = $slf->{'blk'}->get_inline->pipe_code($ofh, $lng, $nam, @arg));
  $pid;
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>eval_code([$dft])>

This method resolves code values.

=cut

sub eval_code
{ my ($slf, $val) = @_;

  if (exists($slf->{'cod'}))
  { my $ret;

    $ret = defined($val) ? $val : $VAL_UNDEF;
    $slf->{'ctx'}->set_internal('val', $ret);
    foreach my $itm (@{$slf->{'cod'}})
    { $ret = $itm->eval_value(1);
    }
    return $ret;
  }

  if ($slf->{'lng'} ne 'SDCL')
  { my (@arg);

    if (exists($slf->{'arg'}))
    { push(@arg, $slf->{'arg'}->eval_as_data);
    }
    elsif (ref($val))
    { push(@arg, $val->eval_as_data);
    }
    return RDA::Value::List::new_from_data(
      $slf->{'blk'}->get_inline->exec_code($slf->{'lng'}, $slf->{'nam'},
                                             @arg));
  }

  $slf->{'blk'}->exec_code($slf->{'nam'}, exists($slf->{'arg'})
    ? $slf->{'arg'}->eval_value(1)
    : $val)->eval_value(1);
}

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a value. When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;

  $flg                  ? $slf->eval_code :
  exists($slf->{'evl'}) ? $slf->new_eval :
                          $slf;
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_data([$flg])>

This method converts the value as a list of Perl data structures.

When the flag is set, it executes code values.

=cut

sub as_data
{ my ($slf, $flg) = @_;

  $flg                  ? $slf->eval_code->as_data :
  exists($slf->{'evl'}) ? $slf->new_eval :
                          $slf;
}

# --- Copy mechanim -----------------------------------------------------------

sub copy_object
{ my ($slf, $flg) = @_;
  my ($val);

  return $slf unless $flg;
  ($val = $slf->eval_code)->is_list
    ? RDA::Value::Scalar::new_number(scalar @$val)
    : $val;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Context>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
