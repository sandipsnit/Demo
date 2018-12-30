# Diff.pm: Class Used for Analyzing File Differences

package RDA::Diff;

# $Id: Diff.pm,v 2.9 2012/04/27 12:55:21 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Diff.pm,v 2.9 2012/04/27 12:55:21 mschenke Exp $
#
# Change History
# 20120427  MSC  Extend comparison capabilities.

=head1 NAME

RDA::Diff - Class Used for Analyzing File Differences

=head1 SYNOPSIS

use RDA::Diff qw(diff diff_files);

=head1 DESCRIPTION

This module analyzes file differences, with an algorithm similar to GNU DIFF.

The basic algorithm is described in:
"An O(ND) Difference Algorithm and its Variations", Eugene Myers,
Algorithmica Vol. 1 No. 2, 1986, pp. 251-266

This code uses the TOO_EXPENSIVE heuristic, by Paul Eggert, to limit the cost
to O(N**1.5 log N) at the price of producing suboptimal output for large inputs
with many differences.

The basic algorithm was independently discovered as described in:
"Algorithms for Approximate String Matching", E. Ukkonen,
Information and Control Vol. 64, 1985, pp. 100-118

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Sgml;
}

# Define the global public variables
use vars qw($VERSION @EXPORT_OK @ISA);
$VERSION   = sprintf("%d.%02d", q$Revision: 2.9 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw(diff diff_files);
@ISA       = qw(Exporter);

# Define the global constants
my @tb_off = (
   0,   0,   1,   1,   3,   1,   3,   1,   5,   3,
   3,   9,   3,   1,   3,  19,  15,   1,   5,   1,
   3,   9,   3,  15,   3,  39,   5,  39,  57,   3,
  35,   1,   5,   9,  41,  31,   5,  25,  45,   7,
  87,  21,  11,  57,  17,  55,  21, 115,  59,  81,
  27, 129,  47, 111,  33,  55,   5,  13,  27,  55,
  93,   1,  57,  25
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<diff($array1,$array2[,$options])>

This method reports the differences between two line arrays. It returns an
undefined value when no differences are found.

The following options controls the comparison:

=over 9

=item B<   'b' > Ignores changes in the amount of white spaces

=item B<   'e' > Ignores end of line differences in file contents

=item B<   'i' > Ignores case differences in file contents

=item B<   't' > Expands tabs to spaces

=item B<   'w' > Ignores all white spaces

=back

=cut

sub diff
{ my ($lin0, $lin1, $opt) = @_;
  my ($cas, $fil0, $fil1, $lim, $slf, $tab, $typ, $val, @cnv);

  # Initialize the internal object
  $slf = {};
  $slf->{'fil'}->[0]->{'buf'} = $lin0;
  $slf->{'fil'}->[1]->{'buf'} = $lin1;

  # Create the conversion table
  if ($opt)
  { $cas = index($opt, 'i') >= 0;
    $typ = (index($opt, 'w') >= 0) ? -3 :
           (index($opt, 'b') >= 0) ? -2 :
                                     0;
    $tab = (index($opt, 't') >= 0) ? -1 : 0;
  }
  for my $chr (0..255)
  { $val = chr($chr);
    if ($val =~ m/\t/)
    { $cnv[$chr] = $typ || $tab || $chr;
    }
    elsif ($val =~ m/\s/)
    { $cnv[$chr] = $typ || $chr;
    }
    else
    { $cnv[$chr] = $cas ? ord(lc($val)) : $chr;
    }
  }
  $cnv[10] = $cnv[13] = -3 if index($opt, 'e') >= 0;

  # Analyze the lines
  _analyze_lines($slf, \@cnv);

  # Allocate vectors for the results of comparison
  ($fil0 = $slf->{'fil'}->[0])->{'chg'} = [];
  ($fil1 = $slf->{'fil'}->[1])->{'chg'} = [];

  # Discard lines that do not match anything in the other file
  _discard_lines($slf);

  # Determine the cost limit
  $slf->{'lim'} = $lim = $fil0->{'lgt'} + $fil1->{'lgt'} + 3;
  for ($val = 1 ; $lim ; $lim >>= 2)
  { $val <<= 1;
  }
  $slf->{'exp'} = ($val < 256) ? 256 : $val;

  # Do the main comparison algorithm, considering just the undiscarded lines
  $slf->{'bdg'} = [];
  $slf->{'fdg'} = [];
  $slf->{'odg'} = $fil1->{'lgt'} + 1;
  _compare_seq($slf, 0, $fil0->{'lgt'}, 0, $fil1->{'lgt'}, 0);

  # Join changes as much as possible
  _merge_changes($slf->{'fil'});

  # Return the edit script
  _build_script($slf->{'fil'});
}

=head2 S<diff_files($file1,$file2[,$options[,$ofh]])>

This method compares two files. It supports the following options:

=over 9

=item B<   'b' > Ignores changes in the amount of white spaces

=item B<   'e' > Ignores end of line differences in file contents

=item B<   'i' > Ignores case differences in file contents

=item B<   's' > Ignores simple line swaps

=item B<   't' > Expands tabs to spaces

=item B<   'w' > Ignores all white spaces

=back

It returns 0 if inputs are the same, 1 for trouble with the first file, 2
for trouble with the second file, or 3 if the files are different. It reports
the differences on the output file handle, when specified.

=cut

sub diff_files
{ my ($fil1, $fil2, $opt, $ofh) = @_;
  my ($dif, @fil1, @fil2);

  # Load the files
  return 1 unless _load_file(\@fil1, $fil1);
  return 2 unless _load_file(\@fil2, $fil2);

  # Compare the files
  $opt = '' unless defined($opt);
  return 0 unless ref($dif = diff(\@fil1, \@fil2, $opt));

  # Ignore swapped lines
  return 0
    if index($opt, 's') >= 0 && _ignore_swaps(\@fil1, \@fil2, $dif) == 0;

  # Loop over all changes
  if (ref($ofh) eq 'RDA::Object::Report')
  { my ($add, $beg1, $beg2, $buf, $del, $end1, $end2);

    foreach my $chg (@$dif)
    { ($beg1, $beg2, $del, $add) = @$chg;
      $end1 = $beg1 + $del - 1;
      $end2 = $beg2 + $add - 1;

      # Report the change
      $buf = '|'._get_range($beg1, $end1).' |';
      $buf .= join('%BR%', map {_encode_line($_)} @fil1[$beg1..$end1]) if $del;
      $buf .= ' |'._get_range($beg2, $end2).' |';
      $buf .= join('%BR%', map {_encode_line($_)} @fil2[$beg2..$end2]) if $add;
      $buf .= " |\n";
      $ofh->write($buf);
    }
  }
  elsif ($ofh)
  { my ($add, $beg1, $beg2, $buf, $del, $end1, $end2, $typ);

    foreach my $chg (@$dif)
    { ($beg1, $beg2, $del, $add) = @$chg;
      $end1 = $beg1 + $del - 1;
      $end2 = $beg2 + $add - 1;

      if ($add && $del)
      { $typ = 'c';
      }
      elsif ($add)
      { $typ = 'a';
      }
      elsif ($del)
      { $typ = 'd';
      }
      else
      { next;
      }

      # Report the change
      $buf = _get_range($beg1, $end1).$typ._get_range($beg2, $end2)."\n";
      $buf .= join('', map {"< $_\n"} @fil1[$beg1..$end1]) if $del;
      $buf .= "---\n" if $typ eq 'c';
      $buf .= join('', map {"> $_\n"} @fil2[$beg2..$end2]) if $add;
      syswrite($ofh, $buf, length($buf));
    }
  }

  # Indicate the difference
  3;
}

sub _load_file
{ my ($lin, $fil) = @_;

  if (ref($fil) eq 'ARRAY')
  { foreach my $blk (@$fil)
    { push(@$lin, split(/\n/, $blk));
    }
  }
  else
  { return 0 unless $fil && open(DIF, $fil);
    chomp(@$lin = <DIF>);
    close(DIF);
  }
  1;
}

sub _encode_line
{ my $lin = shift;
  $lin =~ s/\r//g;
  $lin = RDA::Object::Sgml::encode($lin);
  $lin =~ s/^\s/&nbsp;/;
  $lin;
}

sub _get_range
{my ($beg, $end) = @_;
 $beg++;
 $end++;
 ($beg < $end) ? "$beg,$end" : $end;
}

# --- Internal routines -------------------------------------------------------

# Internal hash keys:
#  'bck'  Bucket array
#  'bdg'  Backward diagonal array
#  'eqs'  Equivalence definition array
#  'exp'  Too expensive limit
#  'fil'  File object array
#  'fdg'  Forward diagonal array
#  'idx'  Equivalence definition index
#  'lim'  Diagonal limit
#  'mod'  Bucket array size
#  'odg'  Diagonal offset
#
# File hash keys:
#  'buf'  Line array
#  'chg'  Change array
#  'eqs'  Line equivalence class array
#  'lgt'  Undiscarded vector length
#  'lim'  Line array length
#  'off'  Real indexes array
#  'vec'  Undiscarded line vector

# Read the files and build the table of equivalence classes.
sub _analyze_lines
{ my ($slf, $cnv) = @_;
  my ($num, $siz);

  # Equivalence class 0 is permanently safe for lines that were not hashed
  # Real equivalence classes start at 1
  $slf->{'eqs'} = [];
  $slf->{'idx'} = 1;

  # Allocate a prime number of hash buckets
  $siz = ((scalar @{$slf->{'fil'}->[0]->{'buf'}}) +
          (scalar @{$slf->{'fil'}->[1]->{'buf'}}) + 1) / 3;
  $num = 9;
  ++$num while (1 << $num) < $siz;
  $slf->{'mod'} = (1 << $num) - $tb_off[$num];
  $slf->{'bck'} = [];

  # Hash the lines of both files
  _hash_lines($slf, $slf->{'fil'}->[0], $cnv, 1);
  _hash_lines($slf, $slf->{'fil'}->[1], $cnv, 2);

  # Free the buckets
  delete($slf->{'bck'});
  delete($slf->{'mod'});
}

# Produce an edit script
sub _build_script
{ my ($fil) = @_;
  my ($chg0, $chg1, $lim0, $lim1, $off0, $off1, $rec0, $rec1, $tbl);

  $tbl = [];
  $chg0 = $fil->[0]->{'chg'};
  $chg1 = $fil->[1]->{'chg'};
  $lim0 = $fil->[0]->{'lim'};
  $lim1 = $fil->[1]->{'lim'};

  for ($off0 = $off1 = 0 ; $off0 < $lim0 || $off1 < $lim1 ; ++$off0, ++$off1)
  { if (defined($chg0->[$off0]) || defined($chg1->[$off1]))
    { ($rec0, $rec1) = ($off0, $off1);
      ++$off0 while defined($chg0->[$off0]);
      ++$off1 while defined($chg1->[$off1]);
      push(@$tbl, [$rec0, $rec1, $off0 - $rec0, $off1 - $rec1]);
    }
  }

  (scalar @$tbl) ? $tbl : undef;
}

# Compare contiguous subsequences of the two files to match each other
sub _compare_seq
{ my ($slf, $off0, $lim0, $off1, $lim1, $flg) = @_;
  my ($fil0, $fil1, $mid, $vec0, $vec1);

  $fil0 = $slf->{'fil'}->[0];
  $fil1 = $slf->{'fil'}->[1];
  $vec0 = $fil0->{'vec'};
  $vec1 = $fil1->{'vec'};

  # Slide down the bottom initial diagonal
  while ($off0 < $lim0 && $off1 < $lim1
    && $vec0->[$off0] == $vec1->[$off1])
  { ++$off0;
    ++$off1;
  }
  # Slide up the top initial diagonal
  while ($lim0 > $off0 && $lim1 > $off1
    && $vec0->[$lim0 - 1] == $vec1->[$lim1 - 1])
  { --$lim0;
    --$lim1;
  }

  # Handle simple cases
  if ($off0 == $lim0)
  { $fil1->{'chg'}->[$fil1->{'off'}[$off1++]] = 1
      while $off1 < $lim1;
  }
  elsif ($off1 == $lim1)
  { $fil0->{'chg'}->[$fil0->{'off'}[$off0++]] = 1
      while $off0 < $lim0;
  }
  else
  { # Find a point of correspondence in the middle of the files
    $mid = _split_seq($slf, $off0, $lim0, $off1, $lim1, $flg);

    # Use the partitions to split this problem into subproblems
    _compare_seq($slf, $off0, $mid->[0], $off1, $mid->[1], $mid->[2]);
    _compare_seq($slf, $mid->[0], $lim0, $mid->[1], $lim1, $mid->[3]);
  }
}

# Discard lines from one file that have no matches in the other file
sub _discard_lines
{ my ($slf) = @_;
  my ($i, $j);
  my ($def, $eqs, $fil, $lim, $msk);

  $def = $slf->{'eqs'};

  foreach my $f (0..1)
  { $fil = $slf->{'fil'}->[$f];
    $msk = $f ? 1 : 2;
    $fil->{'vec'} = [];
    $fil->{'off'} = [];
    $eqs = $fil->{'eqs'};
    $lim = $fil->{'lim'};
    for ($i = $j = 0 ; $i < $lim ; ++$i)
    { if ($def->[$eqs->[$i]]->{'msk'} & $msk)
      { $fil->{'vec'}->[$j]   = $fil->{'eqs'}->[$i];
        $fil->{'off'}->[$j++] = $i;
      }
      else
      { $fil->{'chg'}->[$i] = 1;
      }
    }
    $fil->{'lgt'} = $j;
  }
}

# Compute the equivalence class for each line
sub _hash_lines
{ my ($slf, $fil, $cnv, $msk) = @_;
  my ($bck, $buf, $cls, $def, $eqs, $flg, $hsh, $idx, $lgt, $mod, $num, $off);

  $num = 0;

  $bck = $slf->{'bck'};
  $def = $slf->{'eqs'};
  $idx = $slf->{'idx'};
  $mod = $slf->{'mod'};

  $fil->{'eqs'} = $eqs = [];

  # Hash all lines
  foreach my $lin (@{$fil->{'buf'}})
  { $flg = $hsh = 0;
    $buf = '';
    foreach my $chr (unpack('c*', $lin))
    { $chr = $cnv->[$chr];
      if ($chr >= 0)
      { $buf .= chr($chr);
        $hsh = _hash($hsh, $chr);
        $flg = 0;
      }
      elsif ($chr == -1)
      { do
        { $buf .= ' ';
          $hsh = _hash($hsh, 32);
        } while (length($buf) % 8);
      }
      elsif ($chr == -2 && $flg++ == 0)
      { $buf .= ' ';
        $hsh = _hash($hsh, 32);
      }
    }

    # Determine the corresponding class
    $cls = undef;
    $off = $hsh % $mod;
    $lgt = length($buf);

    if (ref($bck->[$off]))
    { # Reuse existing class if the lines are identical
      foreach my $itm (@{$bck->[$off]})
      { if ($def->[$itm]->{'hsh'} == $hsh &&
            $def->[$itm]->{'lgt'} == $lgt &&
            $def->[$itm]->{'lin'} eq $buf)
        { $def->[$cls = $itm]->{'msk'} |= $msk;
          last;
        }
      }
    }
    unless (defined($cls))
    { $cls = $idx++;
      $def->[$cls] = {hsh => $hsh, lin => $buf, lgt => $lgt, msk => $msk};
      push(@{$bck->[$off]}, $cls);
    }
    $eqs->[$num++] = $cls;
  }
  $fil->{'lim'} = $num;
  $slf->{'idx'} = $idx;
}

sub _hash
{ my ($hsh, $chr) = @_;
  $chr + ($hsh << 7 | $hsh >> 57);
}

# Adjust inserts/deletes of identical lines to join changes as much as possible
sub _merge_changes
{ my ($fil) = @_;
  my ($beg, $cor, $cur, $lgt, $lim, $lin, $oth, $tb_chg, $tb_equ, $tb_oth);

  foreach my $f (0..1)
  { $tb_chg = $fil->[$f]->{'chg'};
    $tb_oth = $fil->[1 - $f]->{'chg'};
    $tb_equ = $fil->[$f]->{'eqs'};
    $lim = $fil->[$f]->{'lim'};
    for ($cur = $oth = 0 ;;)
    { # Scan forwards to find beginning of another run of changes
      while ($cur < $lim && !defined($tb_chg->[$cur]))
      { $cur++;
        1 while $tb_oth->[$oth++];
      }
      last if $cur == $lim;

      # Find the end of this run of changes
      $beg = $cur++;
      ++$cur while $tb_chg->[$cur];
      ++$oth while $tb_oth->[$oth];

      do
      { $lgt = $cur - $beg;

        # Move the changed region back, so long as the previous unchanged line
        # matches the last changed one.
        while ($beg && $tb_equ->[$beg - 1] == $tb_equ->[$cur - 1])
        { $tb_chg->[--$beg] = 1;
          $tb_chg->[--$cur] = undef;
          --$beg while $beg && $tb_chg->[$beg - 1];
          1      while $oth && $tb_oth->[--$oth];
        }

        # Move the changed region forward as far as possible
        $cor = ($oth && $tb_oth->[$oth - 1]) ? $cur : $lim;
        while ($cur < $lim && $tb_equ->[$beg] == $tb_equ->[$cur])
        { $tb_chg->[$beg++] = undef;
          $tb_chg->[$cur++] = 1;
          $cur++ while $tb_chg->[$cur];
          $cor = $cur while $tb_oth->[++$oth];
        }
      }
      while ($lgt != $cur - $beg);

      # If possible, move merged changes to a corresponding run in other file
      while ($cor < $cur)
      { $tb_chg->[--$beg] = 1;
        $tb_chg->[--$cur] = undef;
        1 while $tb_oth->[--$oth];
      }
    }
  }
}

# Find the midpoint of the shortest edit script for a specified portion
sub _split_seq
{ my ($slf, $off0, $lim0, $off1, $lim1, $flg) = @_;
  my ($cst, $exp, $lim, $odd, $vec0, $vec1);
  my ($bmid, $bmin, $bmax, $dmin, $dmax, $fmid, $fmin, $fmax);
  my ($bdg, $fdg, $odg);

  $bdg = $slf->{'bdg'};
  $fdg = $slf->{'fdg'};
  $odg = $slf->{'odg'};
  $exp = $slf->{'exp'};
  $lim = $slf->{'lim'};
  $vec0 = $slf->{'fil'}->[0]->{'vec'};
  $vec1 = $slf->{'fil'}->[1]->{'vec'};

  $dmin = $off0 - $lim1;  # Minimum valid diagonal
  $dmax = $lim0 - $off1;  # Maximum valid diagonal
  $fmid = $off0 - $off1;  # Center diagonal of top-down search
  $bmid = $lim0 - $lim1;  # Center diagonal of bottom-up search
  $fmin = $fmax = $fmid;  # Limits of top-down search
  $bmin = $bmax = $bmid;  # Limits of bottom-up search

  $odd = ($fmid - $bmid) & 1;  # True if southeast corner is on an odd
                               # diagonal with respect to the northwest

  $fdg->[$odg + $fmid] = $off0;
  $bdg->[$odg + $bmid] = $lim0;

  for ($cst = 1 ;; ++$cst)
  { my ($x, $y);

    # Extend the top-down search by an edit step in each diagonal
    if ($fmin > $dmin)
    { $fdg->[$odg + --$fmin - 1] = -1;
    }
    else
    { ++$fmin;
    }
    if ($fmax < $dmax)
    { $fdg->[$odg + ++$fmax + 1] = -1;
    }
    else
    { --$fmax;
    }
    for (my $d = $fmax ; $d >= $fmin ; $d -= 2)
    { my ($old, $low, $hgh);
      $low = $fdg->[$odg + $d - 1];
      $hgh = $fdg->[$odg + $d + 1];
      $x = ($hgh > $low) ? $hgh : $low + 1;
      $old = $x;
      $y = $x - $d;
      while ($x < $lim0 && $y < $lim1 && $vec0->[$x] == $vec1->[$y])
      { ++$x;
        ++$y;
      }
      $fdg->[$odg + $d] = $x;
      return [$x, $y, 1, 1]
        if $odd && $bmin <= $d && $d <= $bmax && $bdg->[$odg + $d] <= $x;
    }

    # Similarly extend the bottom-up search
    if ($bmin > $dmin)
    { $bdg->[$odg + --$bmin - 1] = $lim;
    }
    else
    { ++$bmin;
    }
    if ($bmax < $dmax)
    { $bdg->[$odg + ++$bmax + 1] = $lim;
    }
    else
    { --$bmax;
    }
    for (my $d = $bmax; $d >= $bmin; $d -= 2)
    { my ($old, $low, $hgh);
      $low = $bdg->[$odg + $d - 1];
      $hgh = $bdg->[$odg + $d + 1];
      $x = ($low < $hgh) ? $low : $hgh - 1;
      $old = $x;
      $y = $x - $d;
      while ($x > $off0 && $y > $off1 && $vec0->[$x - 1] == $vec1->[$y - 1])
      { --$x;
        --$y;
      }
      $bdg->[$odg + $d] = $x;
      return [$x, $y, 1, 1]
        if !$odd && $fmin <= $d && $d <= $fmax && $x <= $fdg->[$odg + $d];
    }

    # If the flag is set, find the minimal edit script regardless of expense
    next if $flg;

    # Heuristic: if we've gone well beyond the call of duty,
    # give up and report halfway between our best results so far
    if ($cst >= $exp)
    { my ($bxb, $byb, $fxb, $fyb);

      $fxb = $bxb = 0;

      # Find forward diagonal that maximizes X + Y
      $fyb = -1;
      for (my $d = $fmax ; $d >= $fmin ; $d -= 2)
      { $x = ($fdg->[$odg + $d] < $lim0) ? $fdg->[$odg + $d] : $lim0;
        $y = $x - $d;
        if ($lim1 < $y)
        { $x = $lim1 + $d;
          $y = $lim1;
        }
        if ($fyb < $x + $y)
        { $fyb = $x + $y;
          $fxb = $x;
        }
      }

      # Find backward diagonal that minimizes X + Y
      $byb = $lim;
      for (my $d = $bmax ; $d >= $bmin ; $d -= 2)
      { $x = ($off0 > $bdg->[$odg + $d]) ? $off0 : $bdg->[$odg + $d];
        $y = $x - $d;
        if ($y < $off1)
        { $x = $off1 + $d;
          $y = $off1;
        }
        if ($x + $y < $byb)
        { $byb = $x + $y;
          $bxb = $x;
        }
      }

      # Use the better of the two diagonals
      return (($lim0 + $lim1) - $byb < $fyb - ($off0 + $off1))
        ? [ $fxb, $fyb - $fxb, 1, 0 ]
        : [ $bxb, $byb - $bxb, 0, 1 ];
    }
  }
}

# --- Swap routines -----------------------------------------------------------

# Ignore swapped lines
sub _ignore_swaps
{ my ($lin1, $lin2, $dif) = @_;
  my ($cnt, $prv, $swp);

  do
  { $cnt = $swp = 0;
    $prv = undef;
    foreach my $chg (@$dif)
    { if ($chg->[2] && $chg->[3])
      { $prv = undef;
      }
      elsif ($chg->[3])
      { $swp = 2
          unless defined($prv = _test_swap($prv, $chg, $lin1, $lin2, $chg));
      }
      elsif ($chg->[2])
      { $swp = 2
          unless defined($prv = _test_swap($chg, $prv, $lin1, $lin2, $chg));
      }
      else
      { next;
      }
      ++$cnt;
    }
    $cnt -= $swp;
  } while ($cnt && $swp);
  $cnt;
}

# Test if the lines are swapped
sub _test_swap
{ my ($rec0, $rec1, $lin0, $lin1, $nxt) = @_;
  my ($beg0, $beg1, $cnt);

  return $nxt unless $rec0 && $rec1 && ($cnt = $rec0->[2]) == $rec1->[3];
  $beg0 = $rec0->[0];
  $beg1 = $rec1->[1];
  while ($cnt--)
  { return $nxt unless $lin0->[$beg0++] eq $lin1->[$beg1++];
  }
  $rec0->[2] = $rec1->[3] = 0;
  return undef;
}

1;

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
