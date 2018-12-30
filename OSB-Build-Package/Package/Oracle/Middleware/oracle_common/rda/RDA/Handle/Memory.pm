# Memory.pm: Class Used for Managing Memory Files

package RDA::Handle::Memory;

# $Id: Memory.pm,v 2.7 2012/01/02 16:32:01 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Handle/Memory.pm,v 2.7 2012/01/02 16:32:01 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Handle::Memory - Class Used for Managing Memory Files

=head1 SYNOPSIS

require RDA::Handle::Memory;

=head1 DESCRIPTION

The objects of the C<RDA::Handle::Memory> class are used for managing memory
files.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use Symbol;
}

use strict;

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Handle::Memory-E<gt>new([$str])>

The object constructor.

C<RDA::Handle::Memory> is represented by a symbol, which can be used as a file
handle. The following special keys are used:

=over 12

=item S<    B<'blk' > > Blocking indicator

=item S<    B<'buf' > > String buffer

=item S<    B<'eol' > > End of line characters protection indicator

=item S<    B<'lin' > > Line number

=item S<    B<'lgt' > > String buffer length

=item S<    B<'min' > > Lower limit of a circular buffer

=item S<    B<'max' > > Higher limit of a circular buffer

=item S<    B<'pad' > > Padding character

=item S<    B<'pos' > > Current position in the string buffer

=back

You can specify a string or a string reference as an argument.

=cut

sub new
{ my $cls = shift;

  # Create the buffer object
  my $slf = bless Symbol::gensym(), ref($cls) || $cls;
  tie *$slf, $slf;
  $slf->open(@_);

  # Return the object reference
  $slf;
}

sub open
{ my $slf = shift;

  # Create the object when not yet done
  return $slf->new(@_) unless ref($slf);

  # Create the string buffer
  if (@_)
  { my $ref = ref($_[0]) ? $_[0] : \$_[0];
    $$ref = '' unless defined $$ref;
    *$slf->{'buf'} = $ref;
  }
  else
  { my $buf = '';
    *$slf->{'buf'} = \$buf;
  }

  # Define other object attributes
  *$slf->{'blk'} = 0;
  *$slf->{'eol'} = 1;
  *$slf->{'lgt'} = length(${*$slf->{'buf'}});
  *$slf->{'lin'} = 0;
  *$slf->{'pad'} = "\0";
  *$slf->{'pos'} = 0;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>save($ofh)>

This method saves the area from the current position when no circular buffer
is defined.

=cut

sub save
{ my ($slf, $ofh) = @_;
  my ($buf, $lgt, $pos);

  # Reject the request in a circular buffer
  return 0 if exists(*$slf->{'max'});

  # Save the buffer
  binmode($ofh);
  $buf = *$slf->{'buf'};
  $pos = *$slf->{'pos'};
  if ($lgt = *$slf->{'lgt'} - $pos)
  { $ofh->syswrite(substr($$buf, $pos), $lgt);
    *$slf->{'pos'} += $lgt;
  }
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

  delete *$slf->{'blk'};
  delete *$slf->{'buf'};
  delete *$slf->{'eol'};
  delete *$slf->{'lgt'};
  delete *$slf->{'lin'};
  delete *$slf->{'min'};
  delete *$slf->{'max'};
  delete *$slf->{'pad'};
  delete *$slf->{'pos'};
  undef *$slf;
  1;
}

sub eof
{ my ($slf) = @_;

  *$slf->{'pos'} >= *$slf->{'lgt'};
}

*fileno = $und;

sub getc
{ my ($slf) = @_;
  my $buf;

  $slf->read($buf, 1) ? $buf : undef;
}

sub read
{ my ($slf, undef, $lgt, $off) = @_;
  my ($buf, $max, $pos);

  $buf = *$slf->{'buf'};
  return undef unless $buf;
  $off = 0 unless defined($off);
  $pos = *$slf->{'pos'};
  if (exists(*$slf->{'max'}))
  { $max = *$slf->{'max'} - $pos;
    if ($lgt > $max)
    { return (defined($slf->read($_[1], $max, $off)) &&
        $slf->seek(*$slf->{'min'}, 0) &&
        defined($slf->read($_[1], $lgt - $max, $off + $max))) ? $lgt : undef;
    }
  }
  else
  { $max = *$slf->{'lgt'} - $pos;
    $lgt = $max if $lgt > $max;
  }
  return undef if $lgt < 0;
  if ($off)
  { substr($_[1], $off) = substr($$buf, $pos, $lgt);
  }
  else
  { $_[1] = substr($$buf, $pos, $lgt);
  }
  *$slf->{'pos'} += $lgt;
  return $lgt;
}

sub print
{ my $slf = shift;

  $slf->write(join((defined($,) ? $, : ''), @_).(defined($,) ? $, : ''));
  return 1;
}

sub printf
{ my $slf = shift;
  my $fmt = shift;

  $slf->write(sprintf($fmt, @_));
  return 1;
}

sub stat
{ my ($slf) = @_;

  return undef unless $slf->opened;
  return 1 unless wantarray;
  ( undef,                            # device
    undef,                            # inode
    0666,                             # filemode
    1,                                # links
    $>,                               # user identidier
    $),                               # group identidier
    undef,                            # device identidier
    *$slf->{'lgt'},                   # size
    undef,                            # atime
    undef,                            # mtime
    undef,                            # ctime
    512,                              # block size
    int((*$slf->{'lgt'} + 511) / 512) # blocks
  );
}

*sysread = \&read;

sub syswrite
{ my ($slf, $str, $max, $off) = @_;
  my ($buf, $lgt, $pos);

  $buf = *$slf->{'buf'};
  return undef unless $buf;
  $pos  = *$slf->{'pos'};
  $lgt = length($str);
  $off = 0 unless defined($off);
  if ($off)
  { die "RDA-01101: Offset outside string\n" if $off > $lgt;
    if ($off < 0)
    { $off += $lgt;
      die "RDA-01101: Offset outside string\n" if $off < 0;
    }
    my $lgt -= $off;
  }
  $lgt = $max if defined($max) && $max < $lgt;
  substr($$buf, $pos, $lgt) = substr($str, $off, $lgt);
  *$slf->{'pos'} += $lgt;
  *$slf->{'lgt'} = length($$buf);
  return $lgt;
}

sub truncate
{ my ($slf, $lgt) = @_;
  my ($buf);

  $buf = *$slf->{'buf'};
  $lgt = 0 unless defined($lgt);
  if (*$slf->{'lgt'} < $lgt)
  { $$buf .= (*$slf->{'pad'} x ($lgt - *$slf->{'lgt'}));
  }
  else
  { substr($$buf, $lgt) = '';
    *$slf->{'pos'} = $lgt if $lgt < *$slf->{'pos'};
  }
  *$slf->{'lgt'} = $lgt;
  1;
}

=head1 I/O METHODS RELATED TO PERL VARIABLES

See L<perlvar> for complete descriptions of each of the following methods. The
methods return the previous value of the attribute and take an optional single
argument that, when given, sets the value. If no argument is given, then the
previous value is unchanged.

    $|    $io-E<gt>autoflush([BOOL])
    $.    $io-E<gt>input_line_number([NUM])

=cut

*autoflush  = $und;

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
{ my $slf = shift;
  my ($buf, $lgt, $pos, $str);

  $buf = *$slf->{'buf'};
  return undef unless $buf;
  $lgt = *$slf->{'lgt'};
  $pos = *$slf->{'pos'};
  return undef if $pos >= $lgt;

  unless (defined($/))  # No line separator defined
  { *$slf->{'pos'} = $lgt;
    return substr($$buf, $pos);
  }
  if (length($/))       # Line mode
  { my $off = index($$buf, $/, $pos);
    $. = ++*$slf->{'lin'};
    if ($off < 0)
    { *$slf->{'pos'} = $lgt;
      $str = substr($$buf, $pos);
    }
    else
    { $lgt = $off - $pos + length($/);
      *$slf->{'pos'} += $lgt;
      $str = substr($$buf, $pos, $lgt);
    }
  }
  else                  # Paragraph mode
  { my ($chr, $eol);

    $str = '';
    $eol = 0;
    while (defined($chr = $slf->getc))
    { if ($chr eq "\n")
      { $eol++;
        next if $eol > 2;
      }
      elsif ($eol > 1)
      { $slf->ungetc($chr);
        last;
      }
      else
      { $eol = 0;
      }
      $str .= $chr;
    }
  }
  $str =~ s/[\n\r\s]+$// unless *$slf->{'eol'};
  $str;
}

sub getlines
{ my ($slf) = @_;
  my ($lin, @tbl);

  die "RDA-01102: getlines() called in a scalar context\n" unless wantarray;
  push(@tbl, $lin) while defined($lin = $slf->getline);
  @tbl;
}

*ioctl = $und;

sub opened
{ my ($slf) = @_;

  defined(*$slf->{'buf'});
}

*printflush = \&print;
*setbuf = $und;
*setvbuf = $und;
*sync = $und;

sub ungetc
{ my ($slf) = @_;

  --*$slf->{'pos'};
  1;
}

*untaint = $und;
*write = \&syswrite;

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
  my ($buf, $flg, $min, $max, $pos);

  $buf = *$slf->{'buf'};
  return 0 unless $buf;
  $pos = *$slf->{'pos'};
  $max = ($flg = exists(*$slf->{'max'})) ? *$slf->{'max'} : *$slf->{'lgt'};

  if ($typ == 0)
  { $pos = $off;
  }
  elsif ($typ == 1)
  { $pos += $off;
  }
  elsif ($typ == 2)
  { $pos = $max + $off;
  }
  else
  { die "RDA-01103: Bad whence '$typ'\n";
  }

  if ($flg)
  { $min = *$slf->{'min'};
    $pos = $pos + $max - $min while $pos < $min;
    $pos = $pos - $max + $min while $pos > $max;
  }
  else
  { $pos = 0 if $pos < 0;
    $slf->truncate($pos) if $pos > $max;
  }
  *$slf->{'pos'} = $pos;
  return 1;
}

sub setpos
{ my ($slf, $pos) = @_;
  my ($lgt);

  return undef unless defined($pos) && *$slf->{'buf'};
  $lgt = *$slf->{'lgt'} || 0;
  *$slf->{'pos'} = ($pos < 0) ? 0 : ($pos > $lgt) ? $lgt : $pos;
  1;
}

*sysseek = \&seek;
*tell = \&getpos;

=head1 OTHER I/O METHODS

=head2 S<$io-E<gt>clrlim>

This method clears the limits of the circular buffer.

=cut

sub clrlim
{ my ($slf) = @_;

  delete *$slf->{'max'};
  delete *$slf->{'min'};
  1;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the object dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;
  my ($buf, $pre, $ref);

  $lvl = 0 unless defined($lvl);
  $pre = '  ' x $lvl;
  $buf = $pre.$txt."bless {\n";
  foreach my $key (sort keys(%{*$slf}))
  { if ($key eq 'buf')
    { $buf .=  "$pre  $key => '...'\n";
    }
    elsif ($key eq 'blk')
    { $buf .= sprintf("$pre  $key => 0x%02x\n", *$slf->{$key});
    }
    elsif ($key eq 'pad')
    { $buf .= sprintf("$pre  $key => 0x%02x\n", ord(*$slf->{$key}));
    }
    else
    { $buf .= sprintf("$pre  $key => 0x%08x\n", *$slf->{$key});
    }
  }
  $buf .=  "$pre}, RDA::Handle::Memory";
  $buf;
}

=head2 S<$io-E<gt>getbuf>

This method returns the buffer content.

=cut

sub getbuf
{ my ($slf) = @_;

  *$slf->{'buf'};
}

=head2 S<$io-E<gt>pad([$chr])>

This method manages the padding character. It returns the previous value of
the attribute and takes an optional single argument that, when given, sets
the value. If no argument is given, then the previous value is unchanged.

=cut

sub pad
{ my ($slf, $pad) = @_;

  $slf->setinfo('pad', $pad ? substr($pad, 0, 1) : undef);
}

=head2 S<$io-E<gt>setlim([$min[,$max]])>

This method specifies the buffer area that will be used circularly.

=cut

sub setlim
{ my ($slf, $min, $max) = @_;

  # Resolve default limits
  $max = *$slf->{'lgt'} unless defined($max);
  $min = 0 unless defined($min);

  # Assign the limits when a valid range is specified
  if ($min < $max)
  { *$slf->{'max'} = $max;
    *$slf->{'min'} = $min;
    *$slf->{'pos'} = $min if *$slf->{'pos'} < $min || *$slf->{'max'} >= $max;
    return 1;
  }

  # Indicate an invalid range
  0;
}

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
{ my $slf = shift;

  (@_) ? 0 : 1;
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

  unless (ref($slf))
  { $slf = bless Symbol::gensym(), $slf;
    $slf->open(@_);
  }
  $slf;
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
