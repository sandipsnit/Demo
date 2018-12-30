# Hash.pm: Class Used for Managing Hash Structures

package RDA::Value::Hash;

# $Id: Hash.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Hash.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Hash - Class Used for Managing Hash Structures

=head1 SYNOPSIS

require RDA::Value::Hash;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Hash> class are be used for storing array
structures.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::List;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Value::Assoc RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Hash-E<gt>new(...)>

The object constructor. You can specify some initial content as arguments.

C<RDA::Value:Hash> is represented by a blessed array reference.

=cut

sub new
{ my $cls = shift;

  bless {@_}, ref($cls) || $cls;
}

=head2 S<$h = RDA::Value::Hash::new_from_hash($ref)>

Alternative object contructor, populating the hash from a associative array.

=cut

sub new_from_hash
{ my ($ref) = @_;

  die "RDA-00822: Hash expected\n" unless $ref->is_hash;
  bless {%$ref}, __PACKAGE__;
}

=head2 S<$h = RDA::Value::Hash::new_from_list($ref)>

Alternative object contructor, populating the hash from a RDA list.

=cut

sub new_from_list
{ my ($ref) = @_;
  my ($slf, $key, $val);

  $slf = bless {}, __PACKAGE__;
  while (($key, $val) = splice(@$ref, 0, 2))
  { $slf->{$key->eval_as_string} = defined($val) ? $val : $VAL_UNDEF;
  }
  $slf;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the value dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;

  $lvl = 0  unless defined($lvl);
  $txt = '' unless defined($txt);

  dump_object($slf, {$slf => 'Hash()'}, $lvl, $txt, 'Hash(');
}

sub dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;
  my ($buf, $cnt, $pre, $val);

  $pre = '  ' x $lvl++;
  $buf = $pre.$txt.'Hash=(';
  $cnt = 0;
  foreach my $key (sort keys(%$slf))
  { $buf .= "\n";
    $val = $slf->{$key};
    if (exists($tbl->{$val}))
    { $buf .= $pre."  '$key' => ".$tbl->{$val};
    }
    elsif ($arg)
    { $tbl->{$val} = "$arg'$key')";
      $buf .= $val->dump_object($tbl, $lvl, "'$key' => ", "$arg'$key',");
    }
    else
    { $buf .= $val->dump_object($tbl, $lvl, "'$key' => ");
    }
    ++$cnt;
  }
  $cnt ? $buf."\n".$pre.')' : $buf.')';
}

=head2 S<$h-E<gt>is_hash>

This method indicates whether the value is an associative array.

=cut

sub is_hash
{ 1;
}

=head2 S<$h-E<gt>is_item>

This method indicates whether the value is a list item.

=cut

sub is_item
{ 0;
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a value. It resolves the variables and executes
appropriate macro calls. When there is an evaluation problem, it returns an
undefined value.

When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;

  $flg
    ? RDA::Value::List->new(
        map {RDA::Value::Scalar->new('T', $_), $slf->{$_}->eval_value($flg)}
            sort keys(%$slf))
    : RDA::Value::List->new(
        map {RDA::Value::Scalar->new('T', $_), $slf->{$_}} sort keys(%$slf));
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_array>

This method converts the value as a Perl list, without altering complex data
structures.

=cut

sub as_array
{ my ($slf) = @_;
  my @tbl;

  foreach my $key (sort keys(%$slf))
  { push(@tbl, $key, $slf->{$key}->as_scalar);
  }
  @tbl;
}

=head2 S<$h-E<gt>as_number>

This method converts the value as a Perl number.

=cut

sub as_number
{ my ($slf) = @_;

  scalar @{[%$slf]};
}

=head2 S<$h-E<gt>as_scalar>

This method converts the value as a Perl scalar.

=cut

sub as_scalar
{ my ($slf) = @_;

  scalar @{[%$slf]};
}

# --- Find object mechanim ----------------------------------------------------

sub find_object
{ (shift)
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
