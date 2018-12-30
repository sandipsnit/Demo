# Table.pm: Class Used for Table Structures

package RDA::Object::Table;

# $Id: Table.pm,v 2.5 2012/01/02 16:27:14 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Table.pm,v 2.5 2012/01/02 16:27:14 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Object::Table - Class Used for Table Structures

=head1 SYNOPSIS

require RDA::Object::Table;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Table> class are used for storing table
structures.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my @tb_mon = qw(??? Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %tb_dec = (
  NUM => \&decode_number,
  STR => \&decode_string,
  TSP => \&decode_timestamp,
  );
my %tb_enc = (
  FMT => \&encode_string,
  NUM => \&encode_number,
  STR => \&encode_string,
  TSP => \&encode_timestamp,
  );
my %tb_mon = (
  JAN => '01',
  FEB => '02',
  MAN => '03',
  APR => '04',
  MAY => '05',
  JUN => '06',
  JUL => '07',
  AUG => '08',
  SEP => '09',
  OCT => '10',
  NOV => '11',
  DEC => '12',
  );
my %tb_srt = (
  FMT => 'S',
  NUM => 'N',
  STR => 'S',
  TSP => 'S',
  );
my %tb_ttl = (
  FMT => \&title_string,
  NUM => \&title_number,
  STR => \&title_string,
  TSP => \&title_string,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Table-E<gt>new($nam[,$def])>

The object constructor. You can provide the table name and the column
definition as arguments.

C<RDA::Object:Table> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'oid'>  > Table name

=item S<    B<'-dim'> > Number of columns

=item S<    B<'-dat'> > Data rows

=item S<    B<'-fmt'> > Column formats

=item S<    B<'-hdr'> > Column names

=item S<    B<'-idx'> > Unique identifier index

=item S<    B<'-typ'> > Column types

=item S<    B<'-uid'> > Unique identifier definition

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $nam, $def) = @_;
  my ($hdr, $slf);

  # Create the table object
  $slf = bless {
    oid  => $nam,
    -dim => 0,
    -dat => [],
    -fmt => [],
    -hdr => [],
    -typ => [],
    }, ref($cls) || $cls;

  # Initialize the table
  if (defined($def))
  { $def = [split(/,\s*|\s+/, $def)] unless ref($def) eq 'ARRAY';
    foreach my $itm (@$def)
    { $hdr = _check_name($itm);
      push(@{$slf->{'-fmt'}}, undef);
      push(@{$slf->{'-hdr'}}, $hdr);
      push(@{$slf->{'-typ'}}, defined($hdr) ? 'STR' : 'NUL');
      ++$slf->{'-dim'};
    }
  }

  # Return the object reference
  $slf;
}

sub _check_name
{ my ($nam) = @_;

  (defined($nam) && !ref($nam) && length($nam)) ? $nam : undef;
}

=head2 S<$h-E<gt>add_column($name,$pos,$fmt[,off,...])>

This method adds a column in the table. You can indicate the position where it
must insert the column. It appends after the last column when the position is
an undefined value.

=cut

sub add_column
{ my ($slf, $nam, $pos, $fmt, @arg) = @_;
  my ($dim, $val, @fmt, @off, @tbl);

  # Validate the arguments
  $dim = $slf->{'-dim'};
  $fmt = '' unless defined($fmt);
  $pos = defined($pos) ? _norm_offset($slf, $pos) : $dim;
  foreach my $off (@arg)
  { $off = _norm_offset($slf, $off);
    push(@off, $off);
    ++$off unless $off < $pos;
    push(@fmt, $off);
  }

  # Adjust the unique identifier definition
  ++$slf->{'-uid'} if exists($slf->{'-uid'}) && $slf->{'-uid'} >= $pos;

  # Adjust the existing formats
  foreach my $rec (@{$slf->{'-fmt'}})
  { next unless ref($rec);
    for (my $off = @$rec ; --$off > 0 ;)
    { ++$rec->[$off] unless $rec->[$off] < $pos;
    }
  }

  # Define the new column
  $nam = _check_name($nam);
  splice(@{$slf->{'-fmt'}}, $pos, 0, [$fmt, @fmt]);
  splice(@{$slf->{'-hdr'}}, $pos, 0, $nam);
  splice(@{$slf->{'-typ'}}, $pos, 0, defined($nam) ? 'FMT' : 'NUL');
  ++$slf->{'-dim'};

  # Adjust current records
  foreach my $rec (@{$slf->{'-dat'}})
  { @tbl = ();
    foreach my $off (@off)
    { push(@tbl, defined($val = $rec->[$off]) ? $val : '');
    }
    splice(@$rec, $pos, 0, sprintf($fmt, @tbl));
  }

  # Indicate the successful completion
  1;
}

=head2 S<$h-E<gt>add_row($data)>

This method adds a row in the table.

=cut

sub add_row
{ my ($slf, $dat) = @_;
  my ($dim, $fmt, $off, $rec, $typ, $val, @tbl);

  push(@{$slf->{'-dat'}}, $rec = []);

  # Add data fields
  $dim = $slf->{'-dim'};
  if (ref($dat) eq 'ARRAY')
  { @tbl = @$dat;
    for ($off = 0 ; $off < $dim ; ++$off)
    { $typ = $slf->{'-typ'}->[$off];
      $rec->[$off] = (exists($tb_dec{$typ}) && defined($val = shift(@tbl)))
        ? &{$tb_dec{$typ}}($val)
        : undef;
    }
  }
  else
  { for ($off = 0 ; $off < $dim ; ++$off)
    { $typ = $slf->{'-typ'}->[$off];
      $rec->[$off] =
        (!exists($tb_dec{$typ}))
          ? undef :
        ($dat =~ s/^"([^"]*)"(,\s*)?// || $dat =~ s/^([^\,]*)(,\s*|\z)//)
          ? &{$tb_dec{$typ}}($1) : undef;
    }
  }

  # Add format fields
  for ($off = 0 ; $off < $dim ; ++$off)
  { next unless ref($fmt = $slf->{'-fmt'}->[$off]);
    ($fmt, @tbl) = @$fmt;
    $rec->[$off] =
      sprintf($fmt, map{defined($val = $rec->[$_]) ? $val : ''} @tbl);
  }

  # Index it when needed
  $slf->{'-idx'}->{$val} = $rec
    if exists($slf->{'-uid'}) && defined($val = $rec->[$slf->{'-uid'}]);
  1;
}

=head2 S<$h-E<gt>add_uid($off)>

This method defines an unique identifier on a table.

=cut

sub add_uid
{ my ($slf, $off) = @_;
  my ($idx, $val);
  
  # Normalize the offset
  return 0
    unless exists($tb_enc{$slf->{'-typ'}->[$off = _norm_offset($slf, $off)]});
  
  # Create the index
  $slf->{'-idx'} = $idx = {};
  $slf->{'-uid'} = $off;
  foreach my $rec (@{$slf->{'-dat'}})
  { $idx->{$val} = $rec if defined($val = $rec->[$off]);
  }
  1;
}

=head2 S<$h-E<gt>as_string>

This method returns the table name.

=cut

sub as_string
{ shift->{'oid'};
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method dumps the table description. You can provide an indentation level
and a prefix test as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;
  my ($buf, $off, $pre);

  $lvl = 0 unless defined($lvl);
  $txt = '' unless defined($txt);

  $pre = '  ' x $lvl;
  $buf = $pre.$txt."Table ".$slf->{'oid'}."\n";
  $buf .= $pre."- #Columns: ".$slf->{'-dim'}."\n";
  $buf .= $pre."- Active Columns:\n";
  for ($off = 0 ; $off < $slf->{'-dim'} ; ++ $off)
  { $buf .= $pre."  ".$slf->{'-hdr'}->[$off].'('.$slf->{'-typ'}->[$off].")\n"
      if defined($slf->{'-hdr'}->[$off]);
  }
  $buf .= $pre."- #Rows: ".(scalar @{$slf->{'-dat'}})."\n";
  $buf;
}

=head2 S<$h-E<gt>delete>

This method deletes the table.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>get_columns>

This method returns the list of columns names.

=cut

sub get_columns
{ my ($slf) = @_;

  (grep {defined($_)} @{$slf->{'-hdr'}});
}
  
=head2 S<$h-E<gt>get_keys($off)>

This method returns the list of distinct values present in a column.

=cut

sub get_keys
{ my ($slf, $off) = @_;
  my ($val, %tbl);
  
  if (exists($tb_enc{$slf->{'-typ'}->[$off = _norm_offset($slf, $off)]}))
  { foreach my $rec (@{$slf->{'-dat'}})
    { $tbl{$val} = 1 if defined($val = $rec->[$off]);
    }
  }
  keys(%tbl);
}

=head2 S<$h-E<gt>get_offset($nam)>

This method returns the offset of the specified column name. It returns an
undefined value if it does not find the column.

=cut

sub get_offset
{ my ($slf, $nam) = @_;
  my ($hdr, $off);
  
  for ($off = 0 ; $off < $slf->{'-dim'} ; ++$off)
  { return $off if defined($hdr = $slf->{'-hdr'}->[$off]) && $nam eq $hdr;
  }
  undef;
}

=head2 S<$h-E<gt>merge($src,$off,$dst1,$src1,...)>

This method merges source table fields inside the table records. It makes a join
between the specified column and the source table unique identifier.

=cut

sub merge
{ my ($dst, $src, $off, @arg) = @_;
  my ($idx, $off1, $off2, $ref, $val, @xfr);
  
  die "RDA-01110: Invalid source table\n" unless ref($src) eq ref($dst);

  # Normalize the offsets
  return 0
    unless exists($tb_enc{$dst->{'-typ'}->[$off = _norm_offset($dst, $off)]});
  while (($off1, $off2) = splice(@arg, 0, 2))
  { push(@xfr, [_norm_offset($dst, $off1), _norm_offset($src, $off2)]);
  }
  
  # Merge the record
  $idx = $src->{'-idx'};
  foreach my $rec (@{$dst->{'-dat'}})
  { next unless defined($val = $rec->[$off]) && exists($idx->{$val});
    $ref = $idx->{$val};
    foreach my $xfr (@xfr)
    { $rec->[$xfr->[0]] = $ref->[$xfr->[1]];
    }
  }
  1;
}

=head2 S<$h-E<gt>set_type($typ,$off,...)>

This method modifies the type of the specified columns. Invalid columns are
discarded. It supports the following types:

=over 9

=item B<    NUM > Numeric value

=item B<    STR > String

=item B<    TSP > Time stamp

=back

It returns the number of modified columns.

=cut

sub set_type
{ my ($slf, $typ, @arg) = @_;
  my ($cnt);

  $cnt = 0;
  if (exists($tb_dec{$typ}))
  { foreach my $off (@arg)
    { eval {
        $slf->{'-typ'}->[_norm_offset($slf, $off)] = $typ;
        ++$cnt;
      };
    }
  }
  $cnt;
}

=head2 S<$h-E<gt>write($rpt,$srt)>

This method writes the table content in the specified report. It returns the
number of written rows.

=cut

sub write
{ my ($slf, $rpt, $srt) = @_;
  my ($cnt, $dat, $off, $typ, @tbl);

  $cnt = 0;
  if ($rpt)
  { # Sort the record
    if (defined($srt))
    { $srt = [split(/,/, $srt)] unless ref($srt);
      foreach my $off (@$srt)
      { $typ = ($off =~ s#/([AD])$##) ? $1 : 'A'; #
        $off = _norm_offset($slf, $off);
        next unless exists($tb_srt{$slf->{'-typ'}->[$off]});
        push(@tbl, [$tb_srt{$slf->{'-typ'}->[$off]}.$typ, $off]);
      }
      $dat = [sort {
        foreach my $stp (@tbl)
        { my ($cmp, $off, $val);

          ($cmp, $off) = @$stp;
          $val = ($cmp eq 'SA') ? $a->[$off] cmp $b->[$off] :
                 ($cmp eq 'NA') ? $a->[$off] <=> $b->[$off] :
                 ($cmp eq 'SD') ? $b->[$off] cmp $a->[$off] :
                 ($cmp eq 'ND') ? $b->[$off] <=> $a->[$off] :
                 0;
          return $val if $val;
        }
        0;
        } @{$slf->{'-dat'}}];
    }
    else
    { $dat = $slf->{'-dat'};
    }

    # Write the table content
    foreach my $rec (@$dat)
    { # Write the header of the first row
      unless ($cnt)
      { for ($off = 0, @tbl = () ; $off < $slf->{'-dim'} ; ++$off)
        { $typ = $slf->{'-typ'}->[$off];
          push(@tbl, &{$tb_ttl{$typ}}($slf->{'-hdr'}->[$off]))
            if exists($tb_enc{$typ});
        }
        $rpt->write(join('|', '', @tbl, "\n"));
      }

      # Write the row
      for ($off = 0, @tbl = () ; $off < $slf->{'-dim'} ; ++$off)
      { $typ = $slf->{'-typ'}->[$off];
        push(@tbl, &{$tb_enc{$typ}}($rec->[$off]))
          if exists($tb_enc{$typ});
      }
      $rpt->write(join('|', '', @tbl, "\n"));
      ++$cnt;
    }
  }
  $cnt;
}

# --- Conversion routines -----------------------------------------------------

# Decode a number
sub decode_number
{ shift;
}

# Decode a string
sub decode_string
{ shift;
}

# Decode a time stamp
sub decode_timestamp
{ my ($str) = @_;

  (!defined($str) || !length($str))                    ? undef :
  ($str =~ m#^(\d{2})-(\d{2})-(\d{4})\s*(.*)$#)        ? $3.$1.$2.$4 :
  ($str =~ m#^(\d{2})/(\d{2})/(\d{4})\s*(.*)$#)        ? $3.$1.$2.$4 :
  ($str =~ m#^(\d{2})-([A-Za-z]{3,})-(\d{4})\s*(.*$)#) ? $1._month($2).$3.$4 :
                                                         "00000000$str";
}

# Encode a number
sub encode_number
{ my ($str) = @_;

  defined($str) ? " $str" : ' ';
}

# Encode a string
sub encode_string
{ my ($str) = @_;

  return ' ' unless defined($str) && length($str);
  $str =~ s/\|/&#124;/g;
  $str;
}

# Encode a time stamp
sub encode_timestamp
{ my ($str) = @_;

  !defined($str)         ? ' ' :
  ($str =~ m/^00000000/) ? substr($str,8) :
                           substr($str,6,2).'-'.$tb_mon[substr($str,4,2)].'-'
                           .substr($str,0,4).' '.substr($str,8);
}

# Get the month as a number
sub _month
{ my ($str) = @_;

  $str = uc(substr($str, 0, 3));
  exists($tb_mon{$str}) ? $tb_mon{$str} : '00';
}

# Normalize the column offset
sub _norm_offset
{ my ($slf, $off) = @_;

  die "RDA-01111: Missing offset\n" unless defined($off);

  # Resolve column name
  unless ($off =~ m/^\d+$/)
  { my ($hdr, $pos);

    for ($pos = 0 ; $pos < $slf->{'-dim'} ; ++$pos)
    { return $pos if defined($hdr = $slf->{'-hdr'}->[$pos]) && $off eq $hdr;
    }
    die "RDA-01113: Unknown column '$off'\n";
  }

  # Validate the offset
  $off += $slf->{'-dim'} if $off < 0;
  die "RDA-01112: Invalid offset $off\n"
    unless $off >= 0 && $off < $slf->{'-dim'};
  $off;
}

# Generate a title for a number
sub title_number
{ my ($str) = @_;

  $str = lc($str);
  $str =~ s#\b([a-z])#\U$1#g;
  $str =~ s#_([a-z])# \U$1#g;
  $str =~ s#(\d)([a-z])#$1 \U$2#g;
  " *$str*";
}

# Generate a title for a string
sub title_string
{ my ($str) = @_;

  $str = lc($str);
  $str =~ s#\b([a-z])#\U$1#g;
  $str =~ s#_([a-z])# \U$1#g;
  $str =~ s#(\d)([a-z])#$1 \U$2#g;
  "*$str*";
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
