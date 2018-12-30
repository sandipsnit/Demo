# Index.pm: Class Used for Managing the Collected Elements

package RDA::Object::Index;

# $Id: Index.pm,v 1.19 2012/04/25 06:45:31 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Index.pm,v 1.19 2012/04/25 06:45:31 mschenke Exp $
#
# Change History
# 20120422  MSC  Apply agent changes.

=head1 NAME

RDA::Object::Index - Class Used for Managing the Collected Elements

=head1 SYNOPSIS

require RDA::Object::Index;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Index> class are used for managing the
collected elements. It is a sub class of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Archive::Rda;
  use RDA::Handle::Block;
  use RDA::Object;
  use RDA::Object::Rda qw($CREATE $DIR_PERMS $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  beg => \&_begin_index,
  glb => ['$[IDX]'],
  inc => [qw(RDA::Object)],
  met => {
    'extract'   => {ret => 0},
    'find'      => {ret => 1},
    'get_dir'   => {ret => 0},
    'get_file'  => {ret => 0},
    'get_info'  => {ret => 0},
    'grep'      => {ret => 1},
    'restrict'  => {ret => 0},
    'set_info'  => {ret => 0},
    },
  );

# Define the global private constants
my %tb_cnv = (
  Cygwin  => \&_win_dir_cnv,
  Windows => \&_win_dir_cnv,
  );
my %tb_fct = (
  D => \&_load_meta,
  d => \&_load_meta,
  I => \&_load_index,
  i => \&_load_index,
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Index-E<gt>new($agt,name =E<gt> $value,...)>

The object constructor. This method enables you to specify the agent reference
and initial attributes as arguments.

C<RDA::Object::Index> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'all' > > Unless set, ignores incomplete files

=item S<    B<'err' > > When set, raises errors

=item S<    B<'sta' > > Last status code

=item S<    B<'vrb' > > Verbose mode

=item S<    B<'zip' > > Report archive path

=item S<    B<'_agt'> > Associated agent reference

=item S<    B<'_cat'> > Archive catalog

=item S<    B<'_cfg'> > RDA software configuration reference

=item S<    B<'_cnt'> > The number of index files loaded

=item S<    B<'_cls'> > Associated class

=item S<    B<'_dir'> > Report directory

=item S<    B<'_ext'> > Extraction hash

=item S<    B<'_fam'> > Index operating system family

=item S<    B<'_fct'> > Directory conversion function

=item S<    B<'_grp'> > Report group

=item S<    B<'_mod'> > Module restriction hash

=item S<    B<'_out'> > Report control object reference

=item S<    B<'_sta'> > File status hash

=item S<    B<'_zip'> > Reference to the report archive control object

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, @arg) = @_;
  my ($cfg, $fam, $key, $out, $slf, $val);

  # Create the index object
  $cfg = $agt->get_config;
  $fam = $cfg->get_family,
  $out = $agt->get_output;
  $slf = bless {
    all  => 0,
    err  => 0,
    sta  => 0,
    vrb  => 0,
    _agt => $agt,
    _cfg => $cfg,
    _cnt => 0,
    _cls => "RDA::Local::$fam",
    _dir => $out->get_info('dir'),
    _fam => $fam,
    _fct => $tb_cnv{$fam},
    _grp => $out->get_info('grp'),
    _out => $out,
    }, ref($cls) || $cls;

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $val = $key unless defined $val;
    $slf->{$key} = $val;
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>extract([$dir,@itm])>

This method extracts the requested items to the specified directory, F<extract>
by default. It uses the RDA work directory as base for relative destination
directories. When the list of requested items is empty, all collected files are
extracted.

It returns the number of extracted files.

=cut

sub extract
{ my ($slf, $dst, @itm) = @_;
  my ($cfg, $cnt, $def, $flg, @pth);

  # Validate the destination directory
  $cfg = $slf->{'_cfg'};
  $flg = exists($slf->{'_zip'});
  if (!defined($dst))
  { $dst = $slf->{'_cfg'}->get_dir('D_CWD', 'extract');
  }
  elsif (!$cfg->is_absolute($dst))
  { $dst = $slf->{'_cfg'}->get_dir('D_CWD', $dst);
  }

  # Load the indexes on first use
  $slf->refresh unless exists($slf->{'_idx'});

  # Extract collected files
  $slf->{'sta'} = 4;
  $slf->{'_ext'} = {};
  if (@itm)
  { $cnt = 0;
    foreach my $itm (@itm)
    { @pth = $slf->{'_cls'}->split_dir($itm);
      if (defined($def = _get_entry($slf, [@pth])))
      { $cnt += (ref($def) eq 'HASH')
          ? _extract_dir($slf, $dst, $def, $flg, @pth)
          : _extract_file($slf, $dst, $def, $flg, @pth);
      }
      else
      { $slf->{'sta'} |= 2;
        die "RDA-01270: Missing file or directory '$itm'\n"
          if $slf->{'err'};
      }
    }
  }
  else
  { $cnt = _extract_dir($slf, $dst, $slf->{'_idx'}, $flg);
  }

  # Extract archived files
  if ($flg)
  { my ($cat, $ext, $frg, $hdr, $ifh, $lgt, $sta, $zip);

    $cat = $slf->{'_cat'};
    $ext = $slf->{'_ext'};
    $zip = $slf->{'_zip'};
    foreach my $nam (sort {$cat->{$a}->[1] <=> $cat->{$b}->[1]} keys(%$ext))
    { # Find the archived report
      next unless ($hdr = $zip->find(@{$cat->{$nam}}));

      # Extract requested blocks
      if ($ifh = $hdr->get_handle)
      { foreach my $off (sort {$a <=> $b} keys(%{$ext->{$nam}}))
        { ($lgt, $frg, @pth) = @{$ext->{$nam}->{$off}};
          $cnt += _extract_block($slf,
            RDA::Handle::Block->new($ifh, $off, $lgt, $frg), @pth);
        }
        $ifh->close;
      }
    }
  }

  # Return the number of extracted files
  $cnt;
}

# Extract a block
sub _extract_block
{ my ($slf, $ifh, $sta, $dst, @pth) = @_;
  my ($buf, $lgt, $ofh, $pth, @sta);

  print RDA::Object::Rda->cat_file(@pth)."\n" if $slf->{'vrb'};

  # Create the file
  $ofh = IO::File->new;
  $pth = RDA::Object::Rda->cat_file($dst, @pth);
  $ofh->open($pth, $CREATE, $FIL_PERMS)
    or die "RDA-01271: Cannot create extract file '$pth': $!\n";
  binmode($ifh);
  binmode($ofh);
  $ofh->syswrite($buf, $lgt) while ($lgt = $ifh->sysread($buf, 8192));
  $ifh->close;
  $ofh->close;

  # Update the file status information
  if ($sta)
  { @sta = split(/\|/, $sta);
    utime $sta[8], $sta[9], $pth;
  }

  # Update the extraction status
  $slf->{'sta'} &= 3;
  1;
}

# Extract a whole directory
sub _extract_dir
{ my ($slf, $dst, $cur, $flg, @pth) = @_;
  my ($cnt);

  $cnt = 0;
  foreach my $itm (keys(%$cur))
  { $cnt += (ref($cur->{$itm}) eq 'HASH')
      ? _extract_dir($slf, $dst, $cur->{$itm}, $flg, @pth, $itm)
      : _extract_file($slf, $dst, $cur->{$itm}, $flg, @pth, $itm)
      unless $itm eq '.' || $itm eq '..';
  }
  $cnt;
}

# Extract a file
sub _extract_file
{ my ($slf, $dst, $def, $flg, @pth) = @_;
  my ($buf, $dir, $ifh, $lgt, $nam, $ofh, $sub, $vol);

  # Retrieve the file name
  $nam = pop(@pth);

  # Create the directory when needed
  if (defined($vol = shift(@pth)) && length($vol))
  { if ($vol =~ /^(\w+):$/)
    { unshift(@pth, 'drive', $1)
    }
    elsif ($vol =~ s#^[\\\/]+#_#g)
    { $vol =~ s#[\\\/]#_#g;
      unshift(@pth, 'unc', $vol)
    }
    else
    { $vol =~ s#[\\\/]#_#g;
      unshift(@pth, $vol)
    }
  }
  RDA::Object::Rda->create_dir(RDA::Object::Rda->cat_dir($dst, @pth),
    $DIR_PERMS);

  # Extract the contents
  return _extract_block($slf, $ifh,
    $slf->{'_sta'}->{$def->[2]}, $dst, @pth, $nam)
    if ref($ifh = _get_file($slf, $def, $flg, $dst, @pth, $nam));

  # Indicate that the file has been skipped
  $slf->{'sta'} |= 1 unless defined($ifh);
  0;
}

=head2 S<$h-E<gt>find([$pattern[,$level,@dir]])>

This method returns the list of all files matching the specified pattern in the
specified directory structures. By default, it searches the files in the whole
directory structure. 

When no pattern is specified, it returns all files entries from the directory.

The depth of the search is limited to the specified level, or C<20> by default.

=cut

sub find
{ my ($slf, $pat, $lvl, @dir) = @_;
  my ($sub, @hit, @pth);

  # Check the argument
  $lvl = 20  unless defined($lvl);
  $pat = '.' unless defined($pat);

  # Load the indexes on first use
  $slf->refresh unless exists($slf->{'_idx'});

  # Search files in the directory structure
  $slf->{'sta'} = 4;
  if (@dir)
  { foreach my $dir (@dir)
    { @pth = $slf->{'_cls'}->split_dir($dir);
      if (ref($sub = $slf->get_dir([@pth])) eq 'HASH')
      { push(@hit, _find($slf, $sub, $pat, $lvl, @pth));
      }
      else
      { $slf->{'sta'} |= 2;
        die "RDA-01272: Missing or invalid directory '$dir'\n"
          if $slf->{'err'};
      }
    }
  }
  else
  { @hit = _find($slf, $slf->{'_idx'}, $pat, $lvl);
  }
  $slf->{'sta'} &= 3 if @hit;

  # Return the hit list
  @hit;
}

sub _find
{ my ($slf, $cur, $pat, $lvl, @pth) = @_;
  my ($def, @tbl);

  foreach my $itm (keys(%$cur))
  { next if $itm eq '.' || $itm eq '..';
    if (ref($def = $cur->{$itm}) eq 'HASH')
    { push(@tbl, _find($slf, $cur->{$itm}, $pat, $lvl - 1, @pth, $itm))
        if $lvl > 0;
    }
    elsif ($itm =~ $pat)
    { push(@tbl, $slf->{'_cls'}->cat_dir(@pth, $itm))
        if defined($def->[0]) || $slf->{'all'};
    }
  }
  @tbl;
}

=head2 S<$h-E<gt>get_dir($path)>

This method returns the corresponding directory hash, or an undefined value
when the directory does not exist.

=cut

sub get_dir
{ my ($slf, $pth) = @_;
  my ($def);

  # Load the indexes on first use
  $slf->refresh unless exists($slf->{'_idx'});

  # Return the directory hash reference
  !defined($pth)                                 ? $slf->{'_idx'} :
  (ref($def = _get_entry($slf, $pth)) eq 'HASH') ? $def :
                                                   undef;
}

=head2 S<$h-E<gt>get_file($path)>

This method returns a block handler to the specified file. It returns an
undefined value when it does not find a valid block.

=cut

sub get_file
{ my ($slf, $pth) = @_;
  my ($def);

  # Load the indexes on first use
  $slf->refresh unless exists($slf->{'_idx'});

  # Return the block handler
  (ref($def = _get_entry($slf, $pth)) eq 'ARRAY')
    ? _get_file($slf, $def)
    : undef;
}

=head2 S<$h-E<gt>grep($opt,$pat,@files)>

This method returns the file lines that match the regular expression.

The following options are supported:

=over 9

=item B<    'b' > Prefixes lines with their byte offset.

=item B<    'c' > Returns the match count instead of the match list.

=item B<    'f' > Stops file scanning on the first match.

=item B<    'h' > Suppresses the prefixing of file names on output.

=item B<    'i' > Ignores case distinctions in both the pattern and the line.

=item B<    'j' > Joins continuation lines.

=item B<    'n' > Prefixes lines with a line number.

=item B<    'v' > Inverts the sense of matching to select nonmatching lines.

=item B<    'An'> Prints E<lt>nE<gt> lines of trailing context after matching
lines.

=item B<    'Bn'> Prints E<lt>nE<gt> lines of leading context before matching
lines.

=item B<    'Cn'> Prints E<lt>nE<gt> lines of output context.

=item B<    'Fn'> Stops file scanning after E<lt>nE<gt> matching lines.

=item B<    'H' > Prints the file names for each match.

=item B<    'L' > Prints only the name of the files without matching lines.

=back

It uses a pipe sign (|) as separator between file names, line numbers,
counters, and line details.

=cut

sub grep
{ my ($slf, $opt, $pat, @arg) = @_;
  my ($aft, $bef, $chk, $cnt, $f_b, $f_c, $f_h, $f_n, $fil, $ifh, $inc, $inv,
      $lin, $max, $num, $nxt, $off, $r_a, $r_b, $r_m, $sep, $sta, @bef, @hit);

  # Decode the options and the pattern
  $pat = '.' unless defined($pat);
  $opt = '' unless defined($opt);
  $pat = (index($opt, 'i') < 0) ? qr#$pat# : qr#$pat#i;
  $inc = 1  if index($opt, 'j') >= 0;
  $inv = index($opt, 'v') >= 0;
  $r_a = $r_b = 0;
  if (index($opt, 'l') >= 0)
  { $fil = {};
    $sta = 1;
  }
  elsif (index($opt, 'L') >= 0)
  { $fil = {};
    $sta = 0;
  }
  else
  { $f_h = ((scalar @arg) > 1) ? 1 : 0;
    $f_h = 0 if index($opt, 'h') >= 0;
    $f_h = 1 if index($opt, 'H') >= 0;
    $r_m = $1 if $opt =~ m/F(\d+)/ && $1 > 0;
    $r_m = 1  if index($opt, 'f') >= 0;
    if (index($opt, 'c') >= 0)
    { $f_c = 1;
    }
    else
    { $f_b = index($opt, 'b') >= 0;
      $f_n = index($opt, 'n') >= 0;
      $r_a = $1 if $opt =~ m/[AC](\d+)/ && $1 > 0;
      $r_b = $1 if $opt =~ m/[BC](\d+)/ && $1 > 0;
    }
  }

  # Load the indexes on first use
  $slf->refresh unless exists($slf->{'_idx'});

  # Treat all files
  $slf->{'sta'} = 4;
  foreach my $arg (@arg)
  { if ($ifh = $slf->get_file($arg))
    { $cnt = $num = $off = 0;
      $chk = 1;
      ($aft, $bef, $max, @bef) = (0, $r_b, $r_m);
      $sep = 1 if $r_a || $r_b;
      $fil->{$arg} = 0 if $fil;
      $slf->{'sta'} |= 1 if $ifh->is_partial;
      $ifh->setinfo('eol',0);
      while (defined($lin = $ifh->getline))
      { if (defined($inc))
        { $num += $inc;
          $inc = 1;
          while ($lin =~ s/\\$// && defined($nxt = $ifh->getline))
          { $lin .= $nxt;
            $inc++;
          }
        }
        else
        { ++$num;
        }
        unless ($chk && ($inv xor $lin =~ $pat))
        { if ($aft)
          { $lin = "$off-$lin" if $f_b;
            $lin = "$num-$lin" if $f_n;
            $lin = "$arg-$lin" if $f_h;
            push(@hit, $lin);
            $sep = 1 unless --$aft > 0 || $bef;
          }
          elsif ($bef)
          { $lin = "$off-$lin" if $f_b;
            $lin = "$num-$lin" if $f_n;
            $lin = "$arg-$lin" if $f_h;
            if (push(@bef, $lin) > $bef)
            { shift(@bef);
              $sep = 1;
            }
          }
        }
        elsif ($fil)
        { $fil->{$arg} = 1;
          last;
        }
        else
        { unless ($f_c)
          { $lin = "$off|$lin" if $f_b;
            $lin = "$num|$lin" if $f_n;
            $lin = "$arg|$lin" if $f_h;
            if ($sep)
            { push(@hit, '--');
              $sep = 0;
            }
            push(@hit, splice(@bef), $lin);
            $aft = $r_a;
          }
          ++$cnt;
          if (defined($max) && --$max < 1)
          { last unless $aft;
            $chk = 0;
          }
        }
        $off = $ifh->tell if $f_b;
      }
      $ifh->close;
      push(@hit, $f_h ? "$arg|$cnt" : $cnt) if $f_c;
    }
    else
    { $slf->{'sta'} |= 2;
      die "RDA-01273: Missing file '$arg'\n" if $slf->{'err'};
    }
  }
  shift(@hit) if $r_a || $r_b;
  @hit = sort grep {$fil->{$_} == $sta} keys(%$fil) if $fil;
  $slf->{'sta'} &= 3 if @hit;

  # Return the hits
  @hit;
}

=head2 S<$h-E<gt>refresh($flg)>

This method clears the current index and loads all index files applying the
current restrictions. Unless the flag is set, it loads the file status
information.

It returns the object reference except when it has loaded index
files. Otherwise, it returns an undefined value.

=cut

sub refresh
{ my ($slf, $flg) = @_;
  my ($cfg, $cnt, $ext, $grp, $pat);

  $cfg = $slf->{'_cfg'};
  $cnt = 0;
  $slf->{'_idx'} = {};
  if (exists($slf->{'zip'}))
  { my ($cat, $hdr, $ifh, $zip, %tbl);

    # Create the archive object
    $slf->{'_zip'} = $zip = RDA::Archive::Rda->new($slf->{'zip'}, 1);

    # Determine the operating system family and create the archive catalog
    $slf->{'_cat'} = $cat = {};
    $zip->scan(\&_refresh, $slf);

    # Load the index and meta files
    $cfg = $slf->{'_cfg'};
    $grp = $slf->{'_grp'};
    if (exists($slf->{'_mod'}))
    { foreach my $mod (keys(%{$slf->{'_mod'}}))
      { $tbl{$pat} = \&_load_index
          if exists($cat->{$pat = "$grp\_$mod\_I.fil"})
          || exists($cat->{$pat = lc($pat)});
        next if $flg;
        $tbl{$pat} = \&_load_meta
          if exists($cat->{$pat = "$grp\_$mod\_D.fil"})
          || exists($cat->{$pat = lc($pat)});
      }
    }
    else
    { $ext = $flg ? 'I' : '[DI]';
      $pat = $cfg->is_unix
         ? qr/^$grp\_([A-Z]\d{3}[A-Z\d]{1,4}|(TL|TM|TST)\w+)_($ext).fil$/
         : qr/^$grp\_([A-Z]\d{3}[A-Z\d]{1,4}|(TL|TM|TST)\w+)_($ext).fil$/i;
      foreach my $fil (keys(%$cat))
      { $tbl{$fil} = $tb_fct{$3} if $fil =~ $pat;
      }
    }
    foreach my $fil (sort {$cat->{$a}->[1] <=> $cat->{$b}->[1]} keys(%tbl))
    { $cnt += &{$tbl{$fil}}($slf, $ifh)
        if ($hdr = $zip->find(@{$cat->{$fil}})) && ($ifh = $hdr->get_handle);
    }
  }
  else
  { my ($dir, $ifh, $lin);

    # Determine the operating system family
    $dir = $slf->{'_dir'};
    $grp = $slf->{'_grp'};
    $ifh = IO::File->new;
    _load_fam($slf, $ifh)
      if $ifh->open('<'.$cfg->cat_file($dir, "$grp\_END_report.txt"))
      || $ifh->open('<'.$cfg->cat_file($dir, 'mrc', "$grp\_END_report.txt"));

    # Load the index and meta files
    if (exists($slf->{'_mod'}))
    { foreach my $mod (keys(%{$slf->{'_mod'}}))
      { $cnt += _load_index($slf, $ifh)
          if $ifh->open('<'.$cfg->cat_file($dir, "$grp\_$mod\_I.fil"));
        next if $flg;
        $cnt += _load_meta($slf, $ifh)
          if $ifh->open('<'.$cfg->cat_file($dir, "$grp\_$mod\_D.fil"));
      }
    }
    else
    { if (opendir(DIR, $dir))
      { $ext = $flg ? 'I' : '[DI]';
        $pat = $cfg->is_unix
           ? qr/^$grp\_([A-Z]\d{3}[A-Z\d]{1,4}|(TL|TM|TST)\w+)_($ext).fil$/
           : qr/^$grp\_([A-Z]\d{3}[A-Z\d]{1,4}|(TL|TM|TST)\w+)_($ext).fil$/i;
        foreach my $fil (readdir(DIR))
        { $cnt += &{$tb_fct{$3}}($slf, $ifh)
            if $fil =~ $pat && $ifh->open('<'.$cfg->cat_file($dir, $fil));
        }
        closedir(DIR);
      }
    }
  }

  # Return the object reference
  $cnt ? $slf : undef;
}

sub _refresh
{ my ($nam, $hdr, $slf) = @_;
  my ($ifh);

  # Add the file to the catalog
  $slf->{'_cat'}->{$nam} = [$hdr->get_signature, $hdr->get_position];

  # Identify the collection family
  if ($nam =~ m/\b(\w+)_END_report\.txt$/i)
  { $slf->{'_grp'} = $1;
    _load_fam($slf, $ifh) if defined($ifh = $hdr->get_handle);
  }

  0;
}

=head2 S<$h-E<gt>restrict(@modules)>

This method stores the list of modules that can contribute. When called
without argument, it clears any previous restriction. It returns the object
reference.

=cut

sub restrict
{ my ($slf, @mod) = @_;
  my ($cfg);

  if (@mod)
  { $cfg = $slf->{'_cfg'};
    $slf->{'_mod'} = {map {$cfg->get_module($_) => 1} @mod};
  }
  else
  { delete($slf->{'_mod'});
  }

  # Return the object reference
  $slf;
}

# --- Internal routines -------------------------------------------------------

sub _find_files
{ my ($slf, $pat) = @_;
  my ($tbl);

  sort {$tbl->{$a}->[1] <=> $tbl->{$b}->[1]}
    grep {$_ =~ $pat} keys(%{$tbl = $slf->{'_cat'}});
}

# Retrieve a file or directory entry and its path
sub _get_entry
{ my ($slf, $pth) = @_;
  my ($cur, $fct, $fil, $lvl, $new);

  $pth = [$slf->{'_cls'}->split_dir($pth)] unless ref($pth);
  $fil = pop(@$pth);
  $cur = $slf->{'_idx'};
  $fct = $slf->{'_fct'};
  $lvl = 0;
  foreach my $itm (@$pth)
  { next unless length($itm) || $lvl == 0;
    $itm = &$fct($itm, $cur) if $fct;
    return undef unless exists($cur->{$itm});
    $cur = $cur->{$itm};
    $lvl++;
  }
  exists($cur->{$fil}) ? $cur->{$fil} : undef;
}

# Get a block handler to read the file
sub _get_file
{ my ($slf, $def, $flg, @pth) = @_;
  my ($blk, $dir, $fil, $frg, $hdr, $lgt, $max, $off, $rpt);
  
  # Find the best block definition
  unless (defined($blk = $def->[0]))
  { return undef unless $slf->{'all'};
  
    $frg = $max = -1;
    foreach my $rec (@{$def->[1]})
    { (undef, undef, $lgt) = split(/\//, $rec, 4);
      ($blk, $max) = ($rec, $lgt) if $lgt > $max;
    }
  }

  # Get the block definition
  (undef, $off, $lgt, $dir, $rpt) = split(/\//, $blk, 6);
  if ($flg)
  { $fil = $slf->{'_out'}->get_name($dir, $rpt);
    $slf->{'_ext'}->{$fil}->{$off} =
      [$lgt, $frg, $slf->{'_sta'}->{$def->[2]}, @pth]
      if exists($slf->{'_cat'}->{$fil})
      || exists($slf->{'_cat'}->{$fil = lc($fil)});
    return 0;
  }

  # Return a block handler
  if (exists($slf->{'_zip'}))
  { $fil = $slf->{'_out'}->get_name($dir, $rpt);
    return undef
      unless (exists($slf->{'_cat'}->{$fil}) ||
              exists($slf->{'_cat'}->{$fil = lc($fil)}))
      && ($hdr = $slf->{'_zip'}->find(@{$slf->{'_cat'}->{$fil}}))
      && ($fil = $hdr->get_handle);
  }
  else
  { $fil = RDA::Object::Rda->cat_file($slf->{'_out'}->get_path($dir), $rpt);
  }
  RDA::Handle::Block->new($fil, $off, $lgt, $frg);
}

# Load the family information
sub _load_fam
{ my ($slf, $ifh) = @_;
  my ($fam, $lin);

  $lin = <$ifh>;
  $lin = <$ifh>;
  $ifh->close;
  if ($lin && $lin =~ m/ OS:(\w+) /)
  { $slf->{'_fam'} = $fam = $slf->{'_cfg'}->get_family($1);
    $slf->{'_cls'} = "RDA::Local::$fam";
    $slf->{'_fct'} = $tb_cnv{$fam};
    eval "require RDA::Local::$fam";
  }
}

# Load a file entry
sub _load_file
{ my ($slf, $pth, $def) = @_;
  my ($cur, $fct, $fil, $lvl, $new, @pth);

  @pth = $slf->{'_cls'}->split_dir($pth);
  $cur = $slf->{'_idx'};
  $fct = $slf->{'_fct'};
  $fil = pop(@pth);
  $lvl = 0;
  foreach my $itm (@pth)
  { next unless length($itm) || $lvl == 0;
    $itm = &$fct($itm, $cur) if $fct;
    unless (exists($cur->{$itm}))
    { $cur->{$itm} = $new = {};
      $new->{'.'}  = $new;
      $new->{'..'} = $lvl ? $cur : $new;
    }
    $cur = $cur->{$itm};
    $lvl++;
  }

  # Treat a new record
  $fil = &$fct($fil, $cur) if $fct;
  unless (exists($cur->{$fil}))
  { return undef unless $def;
    return $cur->{$fil} = ($def =~ m#^F/#)
      ? [$def,  [$def], $pth]
      : [undef, [$def], $pth];
  }

  # Update the current record
  $cur = $cur->{$fil};
  die "RDA-01274: Invalid path '$pth'\n" unless ref($cur) eq 'ARRAY';
  if ($def)
  { $cur->[0] = $def if $def =~ m#^F/#;
    push(@{$cur->[1]}, $def);
  }
  $cur;
}

sub _win_dir_cnv
{ my ($sub, $tbl) = @_;

  return $sub if exists($tbl->{$sub});
  my $ref = lc($sub); 
  foreach my $dir (keys(%$tbl))
  { return $dir if lc($dir) eq $ref;
  }
  $sub;
}

# Load an index file
sub _load_index
{ my ($slf, $ifh) = @_;
  my ($blk, $pth, $rec, $typ);

  while (<$ifh>)
  { ($rec, undef, $blk, $pth, $typ) = split(/\|/, $_);
    next unless $rec eq 'F'  && $blk =~ m#^\d+/\d+#;
    _load_file($slf, $pth, "$typ/$blk");
  }
  $ifh->close;
  1;
}

# Load file status information
sub _load_meta
{ my ($slf, $ifh) = @_;
  my ($pth, $sta);

  while (<$ifh>)
  { ($pth, $sta) = split(/\|/, $_, 2);
    $slf->{'_sta'}->{$pth} = $sta;
  }
  0;
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the index control
sub _begin_index
{ my ($pkg) = @_;
  my ($agt);

  $agt = $pkg->get_agent;
  $pkg->define('$[IDX]',
    $agt->get_registry('index', \&new, __PACKAGE__, $agt));
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Handle::Area|RDA::Handle::Area>,
L<RDA::Handle::Block|RDA::Handle::Block>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate>,
L<RDA::Handle::Memory|RDA::Handle::Memory>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
