# Deflate.pm: Class used for Deflating Stream Areas

package RDA::Handle::Deflate;

# $Id: Deflate.pm,v 1.10 2012/01/02 16:32:01 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Handle/Deflate.pm,v 1.10 2012/01/02 16:32:01 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Handle::Deflate - Class used for Deflating Stream Areas

=head1 SYNOPSIS

require RDA::Handle::Deflate;

=head1 DESCRIPTION

The objects of the C<RDA::Handle::Deflate> class are used for deflating stream
areas.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use Compress::Zlib;
  use Symbol;
}

use strict;

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $R_BLK = 8192;
my $S_BLK = 16384;

my $BITS    = Compress::Zlib::MAX_WBITS();
my $STA_EOF = Compress::Zlib::Z_STREAM_END();
my $STA_OK  = Compress::Zlib::Z_OK();

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Handle::Deflate-E<gt>new($ifh,$max)>

The object constructor.

C<RDA::Handle::Deflate> is represented by a symbol, which can be used as a file
handle. The following special keys are used:

=over 12

=item S<    B<'buf' > > Buffer

=item S<    B<'eol' > > End of line characters protection indicator

=item S<    B<'ifh' > > Input file handle

=item S<    B<'lgt' > > Buffer length

=item S<    B<'lin' > > Line number

=item S<    B<'max' > > Data size

=item S<    B<'obj' > > Inflater object

=item S<    B<'pos' > > Current position in the stream

=back

=cut

sub new
{ my $cls = shift;
  my ($slf);

  # Create the buffer object
  $slf = bless Symbol::gensym(), ref($cls) || $cls;
  tie *$slf, $slf;
  $slf->open(@_);

  # Return the object reference
  $slf;
}

sub open
{ my ($slf, $ifh, $max) = @_;
  my ($obj, $sta);

  # Create the object when not yet done
  return $slf->new($ifh, $max) unless ref($slf);

  # Initialize the deflated area
  ($obj, $sta) = Compress::Zlib::inflateInit(
    '-WindowBits' => -$BITS,
    '-Bufsize'    => 32768,
    );
  die "inflateInit error: $sta\n" unless $sta == $STA_OK;
  $max = 0 unless defined($max) && $max > 0;
  *$slf->{'buf'} = '';
  *$slf->{'ifh'} = $ifh;
  *$slf->{'lgt'} = 0;
  *$slf->{'max'} = $max;
  *$slf->{'obj'} = $obj;
  *$slf->{'pos'} = 0;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>save($ofh)>

This method saves the area from the current position.

=cut

sub save
{ my ($slf, $ofh) = @_;
  my ($lgt);

  binmode($ofh);
  if ($lgt = *$slf->{'lgt'})
  { $ofh->syswrite(*$slf->{'buf'}, $lgt);
    *$slf->{'pos'} += $lgt;
  }
  while ($lgt = _read_block($slf))
  { $ofh->syswrite(*$slf->{'buf'}, $lgt);
    *$slf->{'pos'} += $lgt;
  }
  *$slf->{'buf'} = '';
  *$slf->{'lgt'} = 0;
  $ofh->close;
}

# Manage object attributes
sub setinfo
{ my ($slf, $key, $val) = @_;
  my ($old);

  $old = *$slf->{$key};
  *$slf->{$key} = $val if defined($val);
  $old;
}

# Declare a routine for an undefined functionality
my $und = sub { return };

=head1 BASIC I/O METHODS

See L<perlfunc> for complete descriptions of each of the following methods,
which are front ends for the corresponding built-in functions:

    $io->close
    $io->eof
    $io->fileno
    $io->getc
    $io->read(BUF,LEN,[OFFSET])
    $io->print(ARGS)
    $io->printf(FMT,[ARGS])
    $io->stat
    $io->sysread(BUF,LEN,[OFFSET])
    $io->syswrite(BUF,[LEN,[OFFSET]])
    $io->truncate(LEN)

=cut

sub close
{ my ($slf) = @_;

  *$slf->{'ifh'}->seek(*$slf->{'max'}, 1) if *$slf->{'max'} > 0;
  delete(*$slf->{'buf'});
  *$slf->{'lgt'} = *$slf->{'max'} = 0;
  1;
}

sub eof
{ my ($slf) = @_;

  (*$slf->{'max'} > 0 || *$slf->{'lgt'} > 0) ? 0 : 1;
}

*fileno = $und;

sub getc
{ my ($slf) = @_;
  my $buf;

  $slf->read($buf, 1) ? $buf : undef;
}

*print = $und;
*printf = $und;

sub read
{ my ($slf, undef, $siz, $off) = @_;
  my ($inp, $lgt, $out, $sta);

  return 0 unless $siz > 0;

  while (*$slf->{'max'} > 0 && *$slf->{'lgt'} < $siz)
  { $lgt = (*$slf->{'max'} < $R_BLK) ? *$slf->{'max'} : $R_BLK;
    last unless defined($lgt = *$slf->{'ifh'}->read($inp, $lgt))
      && $lgt > 0;
    *$slf->{'max'} -= $lgt;
    ($out, $sta) = *$slf->{'obj'}->inflate(\$inp);
    last unless $sta == $STA_OK || $sta == $STA_EOF;
    *$slf->{'buf'} .= $out;
    *$slf->{'lgt'} += length($out);
    if ($sta == $STA_EOF)
    { *$slf->{'max'} = 0;
      last;
    }
  }

  $lgt = ($siz > *$slf->{'lgt'}) ? *$slf->{'lgt'} : $siz;
  if (defined($off))
  { substr($_[1], $off) = substr(*$slf->{'buf'}, 0, $lgt);
  }
  else
  { $_[1] = substr(*$slf->{'buf'}, 0, $lgt);
  }
  *$slf->{'buf'} = substr(*$slf->{'buf'}, $lgt);
  *$slf->{'lgt'} -= $lgt;
  *$slf->{'pos'} += $lgt;
  return $lgt;
}

*stat = $und;
*sysread = \&read;
*syswrite = $und;
*truncate = $und;

=head1 I/O METHODS RELATED TO PERL VARIABLES

See L<perlvar> for complete descriptions of each of the following methods. The
methods return the previous value of the attribute and take an optional single
argument that, when given, sets the value. If no argument is given, then the
previous value is unchanged.

    $|    $io-E<gt>autoflush([BOOL])
    $.    $io-E<gt>input_line_number([NUM])

=cut

*autoflush = $und;

sub input_line_number
{ my ($slf, $val) = @_;

  $slf->setinfo('lin', $val);
}

=head1 IO::HANDLE LIKE METHODS

See L<IO::Handle> for complete descriptions of each of the following methods:

    $io->blocking([BOOL])
    $io->clearerr
    $io->error
    $io->flush
    $io->getline
    $io->getlines
    $io->opened
    $io->printflush(ARGS)
    $io->sync
    $io->ungetc(ORD)
    $io->untaint
    $io->write(BUF,LEN[,OFFSET])

=cut

sub blocking
{ 1;
}

*clearerr = $und;
*error = $und;
*fcntl = $und;
*flush = $und;

sub getline
{ my ($slf) = @_;
  my ($eol, $lgt, $lin, $str);

  return undef unless *$slf->{'max'} > 0 || *$slf->{'lgt'} > 0;
  unless (defined($/))  # No line separator defined
  { $str = *$slf->{'buf'};
    *$slf->{'pos'} += *$slf->{'lgt'};
    while ($lgt = _read_block($slf))
    { $str .= *$slf->{'buf'};
      *$slf->{'pos'} += *$slf->{'lgt'};
    }
    *$slf->{'buf'} = '';
    *$slf->{'lgt'} = *$slf->{'max'} = 0;
    return $str;
  }
  if (length($/))   # Line mode
  { return undef unless defined($str = _read_line($slf, $/));
    $. = ++*$slf->{'lin'};
  }
  else                  # Paragraph mode
  { return undef unless defined($str = _read_line($slf, "\n"));
    $eol = 0;
    while (defined($lin = _read_line($slf, "\n")))
    { if ($lin eq "\n")
      { $eol++;
        next if $eol > 1;
      }
      elsif ($eol)
      { $lgt = length($lin);
        *$slf->{'buf'} = $lin.*$slf->{'buf'};
        *$slf->{'lgt'} += $lgt;
        *$slf->{'pos'} -= $lgt;
        last;
      }
      else
      { $eol = 0;
      }
      $str .= $lin;
    }
  }
  $str =~ s/[\n\r\s]+$// unless *$slf->{'eol'};
  $str;
}

sub _read_block
{ my ($slf) = @_;
  my ($inp, $lgt, $out, $sta);

  $lgt = (*$slf->{'max'} < $R_BLK) ? *$slf->{'max'} : $R_BLK;
  if ($lgt > 0 && defined($lgt = *$slf->{'ifh'}->read($inp, $lgt)) && $lgt > 0)
  { *$slf->{'max'} -= $lgt;
    ($out, $sta) = *$slf->{'obj'}->inflate(\$inp);
    if ($sta == $STA_OK || $sta == $STA_EOF)
    { *$slf->{'max'} = 0 if $sta == $STA_EOF;
      return *$slf->{'lgt'} = length(*$slf->{'buf'} = $out);
    }
  }
  *$slf->{'buf'} = '';
  *$slf->{'lgt'} = 0;
}

sub _read_line
{ my ($slf, $eol) = @_;
  my ($off, $str);

  $str = '';
  while (($off = index(*$slf->{'buf'}, $eol)) < 0)
  { $str .= *$slf->{'buf'};
    *$slf->{'pos'} += *$slf->{'lgt'};
    return length($str) ? $str : undef unless _read_block($slf);
  }
  $off += length($eol);
  $str .= substr(*$slf->{'buf'}, 0, $off);
  *$slf->{'buf'} = substr(*$slf->{'buf'}, $off);
  *$slf->{'lgt'} -= $off;
  *$slf->{'pos'} += $off;
  $str;
}

sub getlines
{ my ($slf) = @_;
  my ($lin, @tbl);

  die "RDA-01310: getlines() called in a scalar context\n" unless wantarray;
  push(@tbl, $lin) while defined($lin = $slf->getline);
  @tbl;
}

*ioctl = $und;

sub opened
{ 1;
}

*printflush = $und;
*setbuf = $und;
*setvbuf = $und;
*sync = $und;
*ungetc = $und;
*untaint = $und;
*write = $und;

=head1 SEEK METHODS

See L<IO::Seekable> for complete descriptions of each of the following methods:

    $io->getpos
    $io->setpos($pos)
    $io->seek($pos,$whence)
    $io->sysseek($pos,$whence)
    $io->tell

=cut

sub getpos
{ my ($slf) = @_;

  *$slf->{'pos'};
}

sub seek
{ my ($slf, $off, $typ) = @_;
  my ($buf, $inp, $lgt, $out, $siz, $sta);
 
  if ($typ == 0)
  { $siz = $off - *$slf->{'pos'};
  }
  elsif ($typ == 1)
  { $siz = $off;
  }
  else
  { die "RDA-01311: Bad whence ($typ)";
  }

  return 0 unless $siz > 0;

  # Use buffer data
  $lgt = ($siz > *$slf->{'lgt'}) ? *$slf->{'lgt'} : $siz;
  $siz -= $lgt;
  *$slf->{'buf'} = substr(*$slf->{'buf'}, $lgt);
  *$slf->{'lgt'} -= $lgt;
  *$slf->{'pos'} += $lgt;

  # Read additionnal data
  for (; $siz > 0 && *$slf->{'max'} > 0 ; $siz -= $lgt, *$slf->{'pos'} += $lgt)
  { $lgt = (*$slf->{'max'} < $S_BLK) ? *$slf->{'max'} : $S_BLK;
    return 0 unless defined($lgt = *$slf->{'ifh'}->read($inp, $lgt))
      && $lgt > 0;
    *$slf->{'max'} -= $lgt;
    ($out, $sta) = *$slf->{'obj'}->inflate(\$inp);
    unless ($sta == $STA_OK)
    { *$slf->{'max'} = 0;
      $lgt = ($sta == $STA_EOF) ? length($out) : 0;
      if ($lgt < $siz)
      { *$slf->{'pos'} += $lgt;
        return 0;
      }
      $lgt -= $siz;
      *$slf->{'buf'} = substr($out, $siz);
      *$slf->{'lgt'} = $lgt;
      *$slf->{'pos'} += $siz;
      last;
    }
    $lgt = length($out);
    if ($siz < $lgt)
    { $lgt -= $siz;
      *$slf->{'buf'} = substr($out, $siz);
      *$slf->{'lgt'} = $lgt;
      *$slf->{'pos'} += $siz;
      last;
    }
  }
  return 1;
}

sub setpos
{ 0;
}

*sysseek = \&seek;
*tell = \&getpos;

=head1 TIE METHODS

The following methods are implemented to emulate a file handle:

    BINMODE this
    CLOSE this
    DESTROY this
    EOF this
    FILENO this
    GETC this
    OPEN this, mode, LIST
    PRINT this, LIST
    PRINTF this, format, LIST
    READ this, scalar, length, offset
    READLINE this
    SEEK this, position, whence
    TELL this
    TIEHANDLE classname, LIST
    WRITE this, scalar, length, offset

=cut

sub BINMODE
{ my ($slf, @arg) = shift;

  (@arg) ? 0 : 1;
}

*CLOSE = \&close;

sub DESTROY
{
}

*EOF = \&eof;

sub FILENO
{ return undef;
}

*GETC = \&getc;
*OPEN = \&open;
*PRINT = \&print;
*PRINTF = \&printf;
*READ = \&read;

sub READLINE
{ goto &getlines if wantarray;
  goto &getline;
}

*SEEK = \&seek;
*TELL = \&getpos;

sub TIEHANDLE
{ my $slf = shift;

  ref($slf) ? $slf : $slf->new(@_);
}

*WRITE = \&syswrite;

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
