# Assoc.pm: Class Used for Managing Associative Arrays

package RDA::Value::Assoc;

# $Id: Assoc.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Assoc.pm,v 2.4 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Assoc - Class Used for Managing Associative Arrays

=head1 SYNOPSIS

require RDA::Value::Assoc;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Assoc> class are be used for storing
associative arrays.

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
@ISA     = qw(RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Assoc-E<gt>new(...)>

The object constructor. You can specify some initial content as arguments.

C<RDA::Value:Assoc> is represented by a blessed array reference.

=cut

sub new
{ my $cls = shift;

  bless {@_}, ref($cls) || $cls;
}

=head2 S<$h = RDA::Value::Assoc::new_from_data(%hash)>

Alternative object contructor, populating the hash from a Perl hash.

=cut

sub new_from_data
{ my @tbl = @_;
  my ($slf, $key, $val);

  $slf = bless {}, __PACKAGE__;
  while (($key, $val) = splice(@tbl, 0, 2))
  { $slf->{$key} = RDA::Value::Scalar::new_from_data($val);
  }
  $slf;
}


=head2 S<$h = RDA::Value::Assoc::new_from_list($ref)>

Alternative object contructor, populating the hash from a RDA list.

=cut

sub new_from_list
{ my ($tbl) = @_;
  my ($slf, $key, $val);

  $slf = bless {}, __PACKAGE__;
  while (($key, $val) = splice(@$tbl, 0, 2))
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
  $buf = $pre.$txt.'Hash={';
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
  $cnt ? $buf."\n".$pre.'}' : $buf.'}';
}

=head2 S<$h-E<gt>is_hash>

This method indicates whether the value is an associative array.

=cut

sub is_hash
{ 1;
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>copy_value([$flag])>

This method returns a copy of the data structure. When the flag is set, it
evaluates values.

=cut

sub copy_value
{ my ($src, $flg) = @_;

  RDA::Value::copy_hash($src->new, $src, {}, $flg);
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_data>

This method converts the value as a list of Perl data structures.

=cut

sub as_data
{ (RDA::Value::conv_hash({}, shift, {}));
}

=head2 S<$h-E<gt>as_scalar>

This method converts the value as a Perl scalar.

=cut

sub as_scalar
{ shift;
}

=head2 S<$h-E<gt>as_string>

This method returns a string listing all hash keys.

=cut

sub as_string
{ my ($slf) = @_;

  join(',', sort keys(%$slf));
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
