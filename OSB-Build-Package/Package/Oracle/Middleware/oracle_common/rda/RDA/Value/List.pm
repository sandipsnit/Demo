# List.pm: Class Used for Managing RDA Lists

package RDA::Value::List;

# $Id: List.pm,v 2.5 2012/01/02 16:30:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/List.pm,v 2.5 2012/01/02 16:30:04 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Value::List - Class Used for Managing RDA Lists

=head1 SYNOPSIS

require RDA::Value::List;

=head1 DESCRIPTION

The objects of the C<RDA::Value::List> class are be used for storing RDA lists.

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
@ISA     = qw(RDA::Value::Array RDA::Value Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::List-E<gt>new(...)>

The object constructor. You can specify some initial content as arguments.

C<RDA::Value:List> is represented by a blessed array reference.

=cut

sub new
{ my $cls = shift;

  bless [@_], ref($cls) || $cls;
}

=head2 S<$h = RDA::Value::Hash::new_from_array($ref)>

Alternative object contructor, populating the hash from an array.

=cut

sub new_from_array
{ my ($ref) = @_;

  die "RDA-00821: Array expected\n" unless ref($ref) eq 'RDA::Value::Array';
  bless [@$ref], __PACKAGE__;
}

=head2 S<$h = RDA::Value::List::new_from_data($arg,...)>

Alternative object contructor, populating the array from a Perl list.

=cut

sub new_from_data
{ bless [map {RDA::Value::Scalar::new_from_data($_)} @_], __PACKAGE__;
}

=head2 S<$h = RDA::Value::List::new_from_list($ref)>

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

  dump_object($slf, {$slf => 'List()'}, $lvl, $txt, 'List(');
}

sub dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;
  my ($buf, $cnt, $pre);

  $pre = '  ' x $lvl++;
  $buf = $pre.$txt.'List=(';
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
  $cnt ? $buf."\n".$pre.')' : $buf.')';
}

=head2 S<$h-E<gt>is_array>

This method indicates whether the value is a list or an array.

=cut

sub is_array
{ 1;
}

=head2 S<$h-E<gt>is_item>

This method indicates whether the value is a list item.

=cut

sub is_item
{ 0;
}

=head2 S<$h-E<gt>is_list>

This method indicates whether the value is a list.

=cut

sub is_list
{ 1;
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value(s).

=cut

sub is_lvalue
{ my ($slf) = @_;

  foreach my $itm (@$slf)
  { return '' unless $itm->is_lvalue;
  }
  '-';
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>assign_value($val[,$flg])>

This method assigns a new value to the current value. It evaluates the new
value unless the flag is set. It returns the new value.

=cut

sub assign_item
{ my ($slf, $tbl) = @_;
  my $trc;

  foreach my $var (@$slf)
  { $trc->[0]->trace_value($trc->[1], $trc->[2])
      if ($trc = $var->assign_item($tbl));
  }
  undef;
}

=head2 S<$h-E<gt>decr_value([$num])>

This method decrements values and returns the new values.

=cut

sub decr_value
{ my ($slf, $val) = @_;

  RDA::Value::List->new(map {$_->decr_value($val)} grep {ref($_)} @$slf);
}

=head2 S<$h-E<gt>delete_value>

This method deletes a list of left values and returns their previous content.

=cut

sub delete_value
{ my ($slf) = @_;

  RDA::Value::List->new(map {$_->delete_value(1)} grep {ref($_)} @$slf);
}

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a value. It resolves the variables and executes
appropriate macro calls. When there is an evaluation problem, it returns an
undefined value.

When the flag is set, it executes code values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;
  my ($val, @tbl);

  foreach my $itm (@$slf)
  { $val = defined($itm) ? $itm->eval_value($flg) : $VAL_UNDEF;
    if ($val->is_list)
    { push(@tbl, map {defined($_) ? $_ : $VAL_UNDEF} @$val);
    }
    elsif ($val->is_item)
    { push(@tbl, $val);
    }
  }
  RDA::Value::List->new(@tbl);
}

=head2 S<$h-E<gt>incr_value([$num])>

This method increments values and returns the new values.

=cut

sub incr_value
{ my ($slf, $val) = @_;

  RDA::Value::List->new(map {$_->incr_value($val)} grep {ref($_)} @$slf);
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>as_array>

This method converts the value as a Perl list, without altering complex data
structures.

=cut

sub as_array
{ my ($slf) = @_;
  
  (map {$_->as_scalar} @$slf);
}

=head2 S<$h-E<gt>as_data>

This method converts the value as a list of Perl data structures.

=cut

sub as_data
{ @{RDA::Value::conv_array([], shift, {})};
}

=head2 S<$h-E<gt>as_number>

This method converts the value as a Perl number.

=cut

sub as_number
{ my ($slf) = @_;

  scalar @$slf;
}

=head2 S<$h-E<gt>as_scalar>

This method converts the value as a Perl scalar.

=cut

sub as_scalar
{ my ($slf) = @_;

  scalar @$slf;
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
L<RDA::Value::Array|RDA::Value::Array>.
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
