# Block.pm: Class used for Managing Report Blocks

package RDA::Handle::Block;

# $Id: Block.pm,v 1.10 2012/01/02 16:32:01 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Handle/Block.pm,v 1.10 2012/01/02 16:32:01 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Handle::Block - Class Used for Managing Report Blocks

=head1 SYNOPSIS

require RDA::Handle::Block;

=head1 DESCRIPTION

The objects of the C<RDA::Handle::Block> class are used for managing report
blocks.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use IO::File;
  use Symbol;
}

use strict;

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $BLOCK = 8192;

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Handle::Block-E<gt>new($path,$offset,$length[,$partial])>

The object constructor.

C<RDA::Handle::Block> is represented by a symbol, which can be used as a file
handle. The following special keys are used:

=over 12

=item S<    B<'blk' > > Blocking indicator

=item S<    B<'buf' > > Read buffer

=item S<    B<'eol' > > End of line characters protection indicator

=item S<    B<'flg' > > Partial information indicator

=item S<    B<'ifh' > > Input file handle

=item S<    B<'lgt' > > Block length

=item S<    B<'lin' > > Line number

=item S<    B<'max' > > Data size

=item S<    B<'pos' > > Current position

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
{ my ($slf, $pth, $off, $lgt, $flg) = @_;
  my ($ifh);

  # Create the object when not yet done
  return $slf->new($pth, $off, $lgt, $flg) unless ref($slf);

  # Create the block
  if (ref($pth))
  { $ifh = $pth;
  }
  else
  { $ifh = IO::File->new;
    die "RDA-01260: Cannot open file '$pth':\n $!\n"
      unless $ifh->open("<$pth");
  }
  $off = 0 unless defined($off) && $off > 0;
  die "RDA-01261: Cannot find block in file '$pth':\n $!\n"
    unless defined(sysseek($ifh, $off, 0));

  # Create the block
  *$slf->{'blk'} = 0;
  *$slf->{'buf'} = '';
  *$slf->{'eol'} = 1;
  *$slf->{'flg'} = $flg;
  *$slf->{'ifh'} = $ifh;
  *$slf->{'lgt'} = 0;
  *$slf->{'lin'} = 0;
  *$slf->{'max'} = (defined($lgt) && $lgt > 0) ? $lgt : 0;
  *$slf->{'pos'} = 0;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>is_partial>

This method indicates whether the block contains incomplete information.

=cut

sub is_partial
{ my ($slf) = @_;

  *$slf->{'flg'} ? 1 : 0;
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

  delete *$slf->{'blk'};
  delete *$slf->{'buf'};
  delete *$slf->{'eol'};
  delete *$slf->{'flg'};
  delete *$slf->{'ifh'};
  delete *$slf->{'lgt'};
  delete *$slf->{'lin'};
  delete *$slf->{'max'};
  delete *$slf->{'pos'};
  undef *$slf;
  1;
}

sub eof
{ my ($slf) = @_;

  (defined(*$slf->{'ifh'}) && (*$slf->{'max'} > 0 || *$slf->{'lgt'} > 0))
    ? 0
    : 1;
}

*fileno = $und;

sub getc
{ my ($slf) = @_;
  my ($buf);

  $slf->read($buf, 1) ? $buf : undef;
}

*print = $und;
*printf = $und;

sub read
{ my ($slf, undef, $siz, $off) = @_;
  my ($buf, $lgt);

  return 0 unless defined(*$slf->{'ifh'});

  # Read from line buffer
  $lgt = *$slf->{'lgt'};
  if ($lgt > 0)
  { if ($siz > $lgt)
    { $buf = *$slf->{'buf'};
      if ($siz = _read_block($slf, $siz - $lgt))
      { $buf .= *$slf->{'buf'};
        *$slf->{'buf'} = '';
        *$slf->{'lgt'} = 0;
        $lgt += $siz;
      }
    }
    else
    { $buf = substr(*$slf->{'buf'}, 0, $lgt = $siz);
      *$slf->{'buf'} = substr(*$slf->{'buf'}, $lgt);
      *$slf->{'lgt'} -= $lgt;
    }
    if (defined($off))
    { substr($_[1], $off) = $buf;
    }
    else
    { $_[1] = $buf;
    }
    *$slf->{'pos'} += $lgt;
    return $lgt;
  }

  # Read from file
  $lgt = ($siz > *$slf->{'max'}) ? *$slf->{'max'} : $siz;
  return 0 unless $lgt > 0
    && defined($lgt = *$slf->{'ifh'}->read($_[1], $lgt, $off))
    && $lgt > 0;
  *$slf->{'max'} -= $lgt;
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
{ my ($slf, $val) = @_;

  $slf->setinfo('blk', $val);
}

*clearerr = $und;
*error = $und;
*fcntl = $und;
*flush = $und;

sub getline
{ my ($slf) = @_;
  my ($eol, $lgt, $lin, $str);

  return undef unless defined(*$slf->{'ifh'})
    && (*$slf->{'max'} > 0 || *$slf->{'lgt'} > 0);
  unless (defined($/))  # No line separator defined
  { $str = *$slf->{'buf'};
    *$slf->{'pos'} += *$slf->{'lgt'};
    while ($lgt = _read_block($slf, $BLOCK))
    { $str .= *$slf->{'buf'};
      *$slf->{'pos'} += *$slf->{'lgt'};
    }
    *$slf->{'buf'} = '';
    *$slf->{'lgt'} = *$slf->{'max'} = 0;
    return $str;
  }
  if (length($/))       # Line mode
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
{ my ($slf, $siz) = @_;
  my ($lgt);

  $lgt = (*$slf->{'max'} < $siz) ? *$slf->{'max'} : $siz;
  if ($lgt > 0
    && defined($lgt = *$slf->{'ifh'}->read(*$slf->{'buf'}, $lgt))
    && $lgt > 0)
  { *$slf->{'max'} -= $lgt;
    return *$slf->{'lgt'} = $lgt;
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
    return length($str) ? $str : undef unless _read_block($slf, $BLOCK);
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

  die "RDA-01262: getlines() called in a scalar context\n" unless wantarray;
  push(@tbl, $lin) while defined($lin = $slf->getline);
  @tbl;
}

*ioctl = $und;

sub opened
{ my ($slf) = @_;

  defined(*$slf->{'ifh'}) ? 1 : 0;
}

*printflush = $und;
*setbuf = $und;
*setvbuf = $und;
*sync = $und;

sub ungetc
{ my ($slf) = @_;

  --*$slf->{'cur'};
  1;
}

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

  defined(*$slf->{'ifh'})
    ? *$slf->{'pos'}
    : undef;
}

*seek = \&sysseek;

sub setpos
{ my ($slf, $pos) = @_;
  my ($max);

  return undef unless defined(*$slf->{'ifh'});

  $max = *$slf->{'pos'} + *$slf->{'max'};
  $pos = ($pos < 0) ? 0 : ($pos > $max) ? $max : $pos;
  sysseek(*$slf->{'ifh'}, $pos, 0);
  1;
}

sub sysseek
{ my ($slf, $off, $typ) = @_;
  my ($ret, $siz);

  return 0 unless defined(*$slf->{'ifh'});

  # Determine the offset
  if ($typ == 0)
  { $siz = $off - *$slf->{'pos'};
  }
  elsif ($typ == 1)
  { $siz = $off;
  }
  else
  { die "RDA-01281: Bad whence ($typ)";
  }

  # Move the current position
  if ($siz < 0)
  { $siz = - *$slf->{'pos'} unless (*$slf->{'pos'} - $siz) > 0;
    return 0 unless $siz < 0;
    *$slf->{'pos'} += $siz;
  }
  else
  { $siz = *$slf->{'max'} if $siz > *$slf->{'max'};
    return 0 unless $siz > 0;
    *$slf->{'pos'} += $siz;
    unless ($siz > *$slf->{'lgt'})
    { *$slf->{'buf'} = substr(*$slf->{'buf'}, $siz);
      *$slf->{'lgt'} -= $siz;
      return 1;
    }
    $siz -= *$slf->{'lgt'};
  }
  $ret = *$slf->{'ifh'}->seek($siz, 1);
  *$slf->{'buf'} = '';
  *$slf->{'lgt'} = 0;
  *$slf->{'max'} -= $siz;
  $ret;
}

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

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
