# Buffer.pm: Class Used for Buffer Objects

package RDA::Object::Buffer;

# $Id: Buffer.pm,v 2.14 2012/04/26 20:02:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Buffer.pm,v 2.14 2012/04/26 20:02:15 mschenke Exp $
#
# Change History
# 20120126  MSC  Restore dump behaviour.

=head1 NAME

RDA::Object::Buffer - Class Used for Buffer Objects

=head1 SYNOPSIS

require RDA::Object::Buffer;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Buffer> class are used to manage buffers. It
is a subclass of L<RDA:Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Handle::Data;
  use RDA::Handle::Memory;
  use RDA::Object;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.14 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  obj => {'RDA::Handle::Area'    => 1,
          'RDA::Handle::Data'    => 1,
          'RDA::Handle::Deflate' => 1,
          'RDA::Handle::Memory'  => 1,
         },
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'close'       => {ret => 0},
    'count'       => {ret => 1},
    'filter'      => {ret => 0},
    'get_info'    => {ret => 0},
    'get_length'  => {ret => 0},
    'get_line'    => {ret => 0},
    'get_lines'   => {ret => 1},
    'get_pos'     => {ret => 0},
    'get_range'   => {ret => 1},
    'get_type'    => {ret => 0},
    'get_wiki'    => {ret => 0},
    'grep'        => {ret => 1},
    'input_line'  => {ret => 0},
    'is_complete' => {ret => 0},
    'set_handler' => {ret => 0},
    'set_info'    => {ret => 0},
    'set_pos'     => {ret => 0},
    'set_wiki'    => {ret => 0},
    'sort_lines'  => {ret => 0},
    'stat'        => {ret => 1},
    'truncate'    => {ret => 0},
    'write'       => {ret => 0},
    },
  new => 1,
  );

# Define the global private constants

# Define the global private variables
my %tb_srt = (
  ps_time => {
    'aix'      => [\&_sort_ps_ms],
    'darwin'   => [\&_sort_ps_msc],
    'dec_osf'  => [\&_sort_ps_hmsc, 43],
    'dynixptx' => [\&_sort_ps_ms],
    'hpux'     => [\&_sort_ps_hms, 33],
    'linux'    => [\&_sort_ps_hms, 57],
    'solaris'  => [\&_sort_ps_ms],
    '?'        => [\&_sort_ps_ms],
    }
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Buffer-E<gt>new($typ,[$arg...])>

The request constructor. The buffer type is specified as an argument.

C<RDA::Object::Buffer> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_flg'> > Complete load indicator

=item S<    B<'_hnd'> > Buffer handler

=item S<    B<'_typ'> > Buffer type

=item S<    B<'_wik'> > Wiki indicator

=back

Internal keys are prefixed by an underscore.

The Wiki indicator is set by default unless the type is specified by a
lowercase character.

It returns an object reference on successful completion. Otherwise, it returns
an undefined value.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('B',$handle)>

This method allows access to the specified block handle.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('F',$file)>

This method loads the file in a new buffer.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('H',$file[,$size])>

This method creates a new buffer with the head of the specified file. By
default, the first 64KiB is considered. The buffer size will never exceed the
file size.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('L'[,$dat])>

This method creates a new line buffer. You can specify an initial content as an
extra argument.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('R',$file)>

This method opens the file in read-only mode.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('S',$str)>

This method creates a new buffer with the specified string.

=head2 S<$h = RDA::Object::Buffer-E<gt>new('T',$file[,$size])>

This method creates a new buffer with the tail of the specified file. By
default, the last 64KiB is considered. The buffer size will never exceed the
file size.

=cut

sub new
{ my ($cls, $typ, $arg, $max) = @_;
  my ($slf, $vrb);

  # Determine the attributes
  $vrb = 1;
  ($typ, $vrb) = (uc($typ), 0) if $typ =~ m/[a-z]/;

  # Create the buffer
  $slf = bless {_flg => 0, _typ => $typ, _wik => $vrb}, ref($cls) || $cls;

  # Initialize the object
  if ($typ eq 'B')
  { if (ref($arg))
    { $slf->{'_hnd'} = $arg;
      binmode($arg);
      $arg->input_line_number(0);
    }
  }
  elsif ($typ eq 'F')
  { my ($off, $siz, $str);

    $str = '';
    if ($arg && open(BUF, "<$arg"))
    { $off = 0;
      $off += $siz while ($siz = sysread(BUF, $str, 65536, $off));
      close(BUF);
      $slf->{'_flg'} = 1;
      $slf->{'_hnd'} = RDA::Handle::Memory->new($str);
    }
  }
  elsif ($typ eq 'H')
  { my ($siz, $str, @sta);

    if ($arg && open(BUF, "<$arg"))
    { $siz = $max || 65536;
      @sta = stat(BUF);
      ($slf->{'_flg'}, $siz) = (-1, $sta[7]) unless $siz < $sta[7];
      $slf->{'_hnd'} = RDA::Handle::Memory->new($str)
        if sysread(BUF, $str, $siz) > 0;
      close(BUF);
    }
  }
  elsif ($typ eq 'L')
  { $slf->{'_flg'} = 1;
    $slf->{'_hnd'} = RDA::Handle::Data->new($arg, []);
  }
  elsif ($typ eq 'R')
  { my ($ifh);

    $ifh = IO::File->new;
    if ($arg && $ifh->open("<$arg"))
    { $slf->{'_hnd'} = $ifh;
      binmode($ifh);
      $ifh->input_line_number(0);
    }
  }
  elsif ($typ eq 'S')
  { $slf->{'_flg'} = 1;
    $slf->{'_hnd'} = RDA::Handle::Memory->new($arg);
  }
  elsif ($typ eq 'T')
  { my ($siz, $str, @sta);

    if ($arg && open(BUF, "<$arg"))
    { $siz = $max || 65536;
      @sta = stat(BUF);
      ($slf->{'_flg'}, $siz) = (-1, $sta[7])
        unless $sta[7] < 0 || $siz < $sta[7];
      $slf->{'_hnd'} = RDA::Handle::Memory->new($str)
        if sysseek(BUF, -$siz, 2) && sysread(BUF, $str, $siz) > 0;
      close(BUF);
    }
  }
  else
  { die "RDA-01100: Missing or invalid buffer type\n";
  }

  # Return the object reference
  exists($slf->{'_hnd'}) ? $slf : undef;
}

=head2 S<$h-E<gt>close>

This method closes the associated handler. It returns the close result.

=cut

sub close
{ shift->{'_hnd'}->close;
}

=head2 S<$h-E<gt>count([$re...])>

This method returns the number of lines in the specified buffer. It can search
additional regular expressions also. It returns a list containing the
respective counters.

=cut

sub count
{ my ($slf, @arg) = @_;
  my ($ifh, $lin, $off, @tb_cnt, @tb_re);

  # Get the regular expressions
  push(@tb_cnt, 0);
  foreach my $re (@arg)
  { push(@tb_re, qr#$re#);
    push(@tb_cnt, 0);
  }

  # Scan the input
  $ifh = $slf->{'_hnd'};
  $ifh->seek(0, 0);
  while (defined($lin = $ifh->getline))
  { ++$tb_cnt[$off = 0];
    $_ = '' if $lin =~ m/^\000*$/;
    foreach my $re (@tb_re)
    { ++$off;
      ++$tb_cnt[$off] if $lin =~ $re;
    }
  }

  # Return the counter array
  @tb_cnt;
}

=head2 S<$h-E<gt>filter($alt,$options[,$re...])>

In the delimiter mode, this method replaces all strings that are delimited by
one of the regular expression pairs by the alternative text. The regular
expressions should not contain backtracking constructions.

In replacement mode, this method replaces all strings matching one of the
specified regular expressions.

It supports the following options:

=over 9

=item B<    'd' > Sets the delimiter mode (default mode)

=item B<    'i' > Ignores case distinctions in the patterns

=item B<    'r' > Sets the replacement mode

=item B<    's' > Treats the buffer as a single line (only on memory buffer)

=back

It returns the number of modifications.

This method does not modify the content of read-only file buffers.

=cut

sub filter
{ my ($slf, $alt, $opt, @arg) = @_;
  my ($buf, $cnt, $ifh, $re1, $re2, $typ);

  # Get the options
  $typ = $cnt = 0;
  $alt = '...' unless defined($alt);
  $opt = ''    unless defined($opt);

  $typ += 1 unless index($opt, 'i') < 0;
  $typ += 2 unless index($opt, 's') < 0;

  # Filter the buffer
  if (ref($ifh = $slf->{'_hnd'}) eq 'RDA::Handle::Memory')
  { $buf = $ifh->getbuf;
    if (index($opt, 'r') < 0)
    { while (($re1, $re2) = splice(@arg, 0, 2))
      { next unless $re1 && $re2;
        if ($typ == 3)
        { $cnt += ($$buf =~ s#($re1).*?($re2)#$1$alt$2#igs);
        }
        elsif ($typ == 2)
        { $cnt += ($$buf =~ s#($re1).*?($re2)#$1$alt$2#gs);
        }
        elsif ($typ == 1)
        { $cnt += ($$buf =~ s#($re1).*?($re2)#$1$alt$2#ig);
        }
        else
        { $cnt += ($$buf =~ s#($re1).*?($re2)#$1$alt$2#g);
        }
      }
    }
    else
    { foreach $re1 (@arg)
      { next unless $re1;
        if ($typ == 3)
        { $cnt += ($$buf =~ s#$re1#$alt#igs);
        }
        elsif ($typ == 2)
        { $cnt += ($$buf =~ s#$re1#$alt#gs);
        }
        elsif ($typ == 1)
        { $cnt += ($$buf =~ s#$re1#$alt#ig);
        }
        else
        { $cnt += ($$buf =~ s#$re1#$alt#g);
        }
      }
    }
    $ifh->setinfo('lgt', length($$buf));
    $ifh->seek(0, 2);
  }
  elsif (ref($ifh = $slf->{'_hnd'}) eq 'RDA::Handle::Data')
  { $buf = $ifh->getbuf;
    if (index($opt, 'r') < 0)
    { while (($re1, $re2) = splice(@arg, 0, 2))
      { next unless $re1 && $re2;
        if ($typ & 1)
        { foreach my $str (@$buf)
          { $cnt += ($str =~ s#($re1).*?($re2)#$1$alt$2#ig);
          }
        }
        else
        { foreach my $str (@$buf)
          { $cnt += ($str =~ s#($re1).*?($re2)#$1$alt$2#g);
          }
        }
      }
    }
    else
    { foreach $re1 (@arg)
      { next unless $re1;
        if ($typ == 1)
        { foreach my $str (@$buf)
          { $cnt += ($str =~ s#$re1#$alt#ig);
          }
        }
        else
        { foreach my $str (@$buf)
          { $cnt += ($str =~ s#$re1#$alt#g);
          }
        }
      }
    }
    $ifh->seek(0, 2);
  }
  $cnt;
}

=head2 S<$h-E<gt>get_handle([$flag])>

This method returns the buffer handle. When the flag is true, the file position
is reset to the beginning of the file.

=cut

sub get_handle
{ my ($slf, $flg) = @_;
  my ($ifh);

  $ifh = $slf->{'_hnd'};
  if ($flg)
  { $ifh->seek(0, 0);
    $ifh->input_line_number(0);
  }
  $ifh;
}

=head2 S<$h-E<gt>get_length>

This method returns the buffer length, or an undefined value in case of
problems.

=cut

sub get_length
{ my ($hnd, $lgt);

  $hnd = shift->{'_hnd'};
  eval {
    $lgt = $hnd->setinfo('lgt');
  };
  $@ ? undef : $lgt;
}

=head2 S<$h-E<gt>get_line([$skip])>

This method gets a line from the current position into the buffer. You can
specify the number of lines to skip as an extra argument. It returns an
undefined value if this is not possible.

=cut

sub get_line
{ my ($slf, $skp) = @_;
  my $hnd;

  $hnd = $slf->{'_hnd'};
  if ($skp)
  { $hnd->getline while $skp-- > 0;
  }
  $hnd->getline;
}

=head2 S<$h-E<gt>get_lines([$flag])>

This method returns all lines from the current position into the buffer. When
the flag is set, it starts from the beginning of the buffer.

=cut

sub get_lines
{ my ($slf, $flg) = @_;
  my $hnd;

  $hnd = $slf->{'_hnd'};
  $hnd->seek(0, 0) if $flg;
  $hnd->getlines;
}

=head2 S<$h-E<gt>get_pos>

This method returns a value that represents the current position in the
buffer. If this is not possible, it returns an undefined value.

=cut

sub get_pos
{ my ($slf) = @_;
  my ($hnd, $pos);

  $hnd = $slf->{'_hnd'};
  return undef unless defined($pos = $hnd->tell);
  join('|', $hnd->input_line_number, $pos);
}

=head2 S<$h-E<gt>get_range([$min[,$max]])>

This method returns a range of the lines stored in the line buffer. It assumes
the first and last line as the default for the range definition. You can use
negative line numbers to specify lines from the buffer end.

For other buffer types, it return an empty list.

=cut

sub get_range
{ my ($slf, $min, $max) = @_;
  my $buf;

  return () unless $slf->{'_typ'} eq 'L';

  # Validate the range
  $buf = $slf->{'_hnd'}->getbuf;
  $min = (!defined($min) || ($#$buf + $min) < -1) ? 0 :
         ($min < 0) ? $#$buf + $min + 1 :
         $min;
  $max = (!defined($max)) ? $#$buf :
         (($#$buf + $max) < -1) ? 0 :
         ($max < 0) ? $#$buf + $max + 1 :
         ($max > $#$buf) ? $#$buf :
         $max;

  # Return the line range
  @$buf[$min..$max];
}

=head2 S<$h-E<gt>get_type>

This method returns the buffer type.

=cut

sub get_type
{ shift->{'_typ'};
}

=head2 S<$h-E<gt>get_wiki>

This method returns the Wiki indicator.

=cut

sub get_wiki
{ shift->{'_wik'};
}

=head2 S<$h-E<gt>grep($re[,$options[,$lgt[,$min,$max]]])>

This method returns the lines that match the regular expression. It supports
the following options:

=over 9

=item B<    'c' > Returns the match count instead of the match list

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the line

=item B<    'j' > Joins continuation lines

=item B<    'n' > Prefixes lines with a line number

=item B<    'o' > Prefixes lines with the offset to the next line

=item B<    'r' > Does not restart from the beginning of the file

=item B<    'v' > Inverts the sense of matching to select nonmatching lines

=item B<    (n) > Returns the (n)th capture buffer instead of the line.

=back

You can limit the number of matched lines to the specified number. For a
positive number, it returns the first matches only. For a negative number, it
returns the last matches only.

You can restrict the search to a line range.

=cut

sub grep
{ my ($slf, $re, $opt, $lgt, $min, $max) = @_;
  my ($beg, $cnt, $end, $flg, $f_c, $f_i, $f_n, $f_o, $ifh, $lin, $inc, $nxt,
      $pos, @tbl);

  if ($re)
  { # Determine the options
    $min = 0 unless $min && $min > 0;
    $max = 0 unless $max && $max > 0;
    $opt = '' unless defined($opt);
    $re = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
    $f_c = index($opt, 'c') >= 0;
    $f_i = index($opt, 'v') >= 0;
    $f_n = index($opt, 'n') >= 0;
    $f_o = index($opt, 'o') >= 0;
    $inc = 0 if index($opt, 'j') >= 0;
    $pos = ($opt =~ m/(\d+)/) ? $1 : 0;

    # Restrict the number of records returned
    $beg = $end = 0;
    if ($lgt)
    { $beg = $lgt  if $lgt > 0;
      $end = -$lgt if $lgt < 0;
    }
    elsif (index($opt, 'f') >= 0)
    { $beg = 1;
    }

    # Determine the start point
    $ifh = $slf->{'_hnd'};
    if (index($opt, 'r') >= 0)
    { $cnt = $ifh->input_line_number;
    }
    else
    { $ifh->input_line_number($cnt = 0);
      $ifh->seek(0, 0);
    }

    # Scan the file
    $tbl[0] = 0 if $f_c;
    while (defined($lin = $ifh->getline))
    { $lin =~ s/[\r\n]+$//;
      if (defined($inc))
      { $cnt += $inc;
        $inc = 0;
        while ($lin =~ s/\\$// && defined($nxt = $ifh->getline))
        { $nxt =~ s/[\r\n]+$//;
          $lin .= $nxt;
          $inc++;
        }
      }
      next if ++$cnt < $min;
      last if $max && $cnt > $max;
      $lin = '' if $lin =~ m/^\000*$/;
      $flg = ($lin =~ $re);
      if ($f_i ? !$flg : $flg)
      { if ($f_c)
        { ++$tbl[0];
        }
        else
        { $lin = eval "\$$pos" if $pos;
          $lin = $cnt.':'.$lin if $f_n;
          $lin = $ifh->input_line_number.'|'.$ifh->tell.':'.$lin if $f_o;
          push(@tbl, $lin);
          last if $beg && (scalar @tbl) == $beg;
          shift(@tbl) if $end && (scalar @tbl) > $end;
        }
      }
    }
  }

  # Return the matches
  @tbl;
}

=head2 S<$h-E<gt>input_line([$num])>

This method returns the current input line number and takes an optional single
argument that, when given, will set the value. If no argument is given, the
previous value is unchanged.

=cut

sub input_line
{ my ($slf, $num) = @_;

  $slf->{'_hnd'}->input_line_number($num);
}

=head2 S<$h-E<gt>is_complete>

This method indicates if the file is completely loaded or accessible.

=cut

sub is_complete
{ shift->{'_flg'} ? 1 : 0;
}

=head2 S<$h-E<gt>set_handler($key[,$value])>

This method specifies a new value for the given handler property. It returns
the previous value.

=cut

sub set_handler
{ my ($slf, @inf) = @_;

  $slf->{'_hnd'}->setinfo(@inf);
}

=head2 S<$h-E<gt>set_pos([$pos])>

This method uses the value of a previous C<get_pos> call to return to a
previously visited position. When the position is omitted, it returns to the
beginning of the buffer.

It returns a true value on success and an undefined value on failure.

=cut

sub set_pos
{ my ($slf, $pos) = @_;
  my $hnd;

  $hnd = $slf->{'_hnd'};
  $pos = '0|0' unless defined($pos);
  $hnd->input_line_number($1) if $pos =~ s/^(\d+)\|//;
  $hnd->seek($pos, 0);
}

=head2 S<$h-E<gt>set_wiki($flag)>

This method sets the Wiki indicator. It returns the previous value.

=cut

sub set_wiki
{ my ($slf, $flg) = @_;

  ($slf->{'_wik'}, $flg) = ($flg, $slf->{'_wik'});
  $flg;
}

=head2 S<$h-E<gt>sort_lines($type)>

This method sorts the buffer lines according to the specified criteria. It
returns the number of records on successful completion. Otherwise, it returns
C<0>. It supports the following sort types:

=over 12

=item B<    ps_time>

Sorts the 'ps' lines by decreasing CPU time.

=back

It ignores empty lines. Lines that do not contain the sort field are put at
the top of the list.

=cut

sub sort_lines
{ my ($slf, $typ) = @_;
  my ($fct, $ifh, $key, $lin, $new, $off, $rec, @tbl);

  return 0 unless $typ && exists($tb_srt{$typ});

  # Get the sort key function key
  $rec = $tb_srt{$typ};
  $rec = $rec->{exists($rec->{$^O}) ? $^O : '?'};
  $fct = $rec->[0];
  $off = $rec->[1];

  # Create the sort key
  $ifh = $slf->{'_hnd'};
  $ifh->seek(0, 0);
  $new = [];
  while (defined($lin = $ifh->getline))
  { if (defined($key = &$fct($lin, $off)))
    { push(@tbl, [$key, $lin]);
    }
    elsif ($lin !~ m/^\s*$/)
    { push(@$new, $lin);
    }
  }

  # Sort the records
  foreach $rec (sort {$b->[0] <=> $a->[0]} @tbl)
  { push(@$new, $rec->[1]);
  }

  # Store the results and return the number of records
  $slf->{'_hnd'} = RDA::Handle::Data->new($new);
  $slf->{'_typ'} = 'L';
  scalar @$new;
}

sub _sort_ps_hms
{ my ($lin, $off) = @_;

  $lin = substr($lin, $off);
  return undef unless $lin =~ m/\s(((\d+)-)?(\d+)\:)?(\d+)\:(\d+)\s/;
  my $tps = $5 * 60 + $6;
  $tps += $4 * 3600  if $4;
  $tps += $3 * 86400 if $3;
  $tps;
}

sub _sort_ps_hmsc
{ my ($lin, $off) = @_;

  # Possible formats:
  # 2-16:17:48
  #   04:00:14
  #       0:01.31
  $lin = substr($lin, $off);
  return undef
    unless $lin =~ m/\s(((\d+)-)?(\d+)\:)?(\d+)\:(\d+)(\.(\d+))?\s/;
  my $tps = $5 * 60 + $6;
  $tps += $4 * 3600  if $4;
  $tps += $3 * 86400 if $3;
  $tps += $8 / 100   if $8;
  $tps;
}

sub _sort_ps_ms
{ my ($lin) = @_;

  ($lin =~ m/\s(\d+)\:(\d+)\s/) ? ($1 * 60 + $2) : undef;
}

sub _sort_ps_msc
{ my ($lin) = @_;

  ($lin =~ m/\s(\d+)\:(\d+\.\d+)\s/) ? ($1 * 60 + $2) : undef;
}

=head2 S<$h-E<gt>stat>

This method returns a 13-element list giving the status information. It returns
a null list if the C<stat> fails. Typically used as follows:

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
   $atime,$mtime,$ctime,$blksize,$blocks) = $buf->stat

=cut

sub stat
{ shift->{'_hnd'}->stat;
}

=head2 S<$h-E<gt>truncate([$length])>

This method truncates the buffer to the specified length, zero by default. It
returns a true value if successful. Otherwise, it returns a false value.

The behavior is undefined if the length is greater than the length of the
buffer.

=cut

sub truncate
{ my ($slf, $lgt) = @_;

  $slf->{'_hnd'}->truncate($lgt);
}

=head2 S<$h-E<gt>write($data[,$length[,$offset]])>

This method attempts to write the specified data in the buffer. If the length
is not specified, it writes the whole data. If the length is greater than the
available data after the offset, it only writes as much data as is available.

You can specify an offset to write the data from some part other than the
beginning. A negative offset specifies writing that many characters counting
backwards from the end of the string.

It returns the size actually written, or an undefined value if there was an
error.

=cut

sub write
{ my ($slf, $buf, $lgt, $off) = @_;

  $slf->{'_hnd'}->syswrite($buf, $lgt, $off);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Handle::Area|RDA::Handle::Area>,
L<RDA::Handle::Data|RDA::Handle::Data>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate>,
L<RDA::Handle::Memory|RDA::Handle::Memory>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Message|RDA::Object::Message>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
