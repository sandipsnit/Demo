# Array.pm: Class Used for Managing Array Structures

package RDA::Value::Array;

# $Id: Array.pm,v 2.5 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Array.pm,v 2.5 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::Array - Class Used for Managing Array Structures

=head1 SYNOPSIS

require RDA::Value::Array;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Array> class are be used for storing array
structures.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
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

=head2 S<$h = RDA::Value::Array-E<gt>new(...)>

The object constructor. You can specify some initial content as arguments.

C<RDA::Value:Array> is represented by a blessed array reference.

=cut

sub new
{ my $cls = shift;

  bless [@_], ref($cls) || $cls;
}

=head2 S<$h = RDA::Value::Array::new_from_data(@array)>

Alternative object contructor, populating the array from a Perl list.

=cut

sub new_from_data
{ bless [map {RDA::Value::Scalar::new_from_data($_)} @_], __PACKAGE__;
}

=head2 S<$h = RDA::Value::Array::new_from_list($ref)>

Alternative object contructor, populating the array from a RDA list.

=cut

sub new_from_list
{ my ($tbl) = @_;

  bless [@$tbl], __PACKAGE__;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the value dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;

  $lvl = 0  unless defined($lvl);
  $txt = '' unless defined($txt);

  dump_object($slf, {$slf => 'Array()'}, $lvl, $txt, 'Array(');
}

sub dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;
  my ($buf, $cnt, $pre);

  $pre = '  ' x $lvl++;
  $buf = $pre.$txt.'Array=[';
  $cnt = 0;
  foreach my $itm (@$slf)
  { $buf .= "\n";
    if (!defined($itm))
    { $buf .= $pre.'  <undef>';
    }
    elsif (exists($tbl->{$itm}))
    { $buf .= $pre.'  '.$tbl->{$itm};
    }
    elsif ($arg)
    { $tbl->{$itm} = "$arg$cnt)";
      $buf .= $itm->dump_object($tbl, $lvl, '', "$arg$cnt,");
    }
    else
    { $buf .= $itm->dump_object($tbl, $lvl, '');
    }
    ++$cnt;
  }
  $cnt ? $buf."\n".$pre.']' : $buf.']';
}

=head2 S<$h-E<gt>is_array>

This method indicates whether the value is a list or an array.

=cut

sub is_array
{ 1;
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>copy_value([$flag])>

This method returns a copy of the data structure.

=cut

sub copy_value
{ my ($src, $flg) = @_;

  RDA::Value::copy_array($src->new, $src, {}, $flg);
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_data>

This method converts the value as a list of Perl data structures.

=cut

sub as_data
{ (RDA::Value::conv_array([], shift, {}));
}

=head2 S<$h-E<gt>as_scalar>

This method converts the value as a Perl scalar.

=cut

sub as_scalar
{ shift;
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
