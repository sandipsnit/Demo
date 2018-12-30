# Data.pm: Class Used for Managing Data

package RDA::Handle::Data;

# $Id: Data.pm,v 2.7 2012/01/02 16:32:01 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Handle/Data.pm,v 2.7 2012/01/02 16:32:01 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Handle::Data - Class Used for Managing Data

=head1 SYNOPSIS

require RDA::Handle::Data;

=head1 DESCRIPTION

The objects of the C<RDA::Handle::Data> class are used for managing data.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use Symbol;
  use RDA::Handle::Memory;
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

=head2 S<$h = RDA::Handle::Data-E<gt>new([$data[,$dft]])>

The object constructor.

C<RDA::Handle::Data> is represented by a symbol, which can be used as a file
handle. The following special keys are used:

=over 12

=item S<    B<'buf' > > String buffer

=item S<    B<'lgt' > > String buffer length

=item S<    B<'pad' > > Padding line

=item S<    B<'pos' > > Current position in the string buffer

=back

You can specify a string or a string reference as an argument.

=cut

sub new
{ my ($cls, $dat, $dft) = @_;
  my ($slf);

  # Create the buffer object
  if (defined($dat) || defined($dat = $dft))
  { if (ref($dat) eq 'ARRAY')
    { $slf = bless Symbol::gensym(), ref($cls) || $cls;
      tie *$slf, $slf;
      $slf->open($dat);
    }
    else
    { $slf = RDA::Handle::Memory->new($dat);
      $slf->setinfo('eol', 0);
    }
  }

  # Return the handle reference
  $slf;
}

sub open
{ my ($slf, $dat) = @_;

  # Create the handle when not yet done
  return $slf->new($dat) unless ref($slf);

  # Create the line buffer
  *$slf->{'buf'} = (ref($dat) eq 'ARRAY') ? $dat :
                    defined($dat)         ? [$dat] :
                                            [];
  *$slf->{'lgt'} = scalar @{*$slf->{'buf'}};
  *$slf->{'pad'} = '';
  *$slf->{'pos'} = 0;

  # Return the handle reference
  $slf;
}

# Manage handle attributes
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
which are just front ends for the corresponding built-in functions:

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

  delete *$slf->{'buf'};
  delete *$slf->{'lgt'};
  delete *$slf->{'pos'};
  undef *$slf;
  1;
}

sub eof
{ my ($slf) = @_;

  *$slf->{'pos'} >= *$slf->{'lgt'};
}

*fileno = $und;
*getc = $und;
*read = $und;

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
  ( undef,          # device
    undef,          # inode
    0666,           # filemode
    1,              # links
    $>,             # user identidier
    $),             # group identidier
    undef,          # device identidier
    *$slf->{'lgt'}, # size
    undef,          # atime
    undef,          # mtime
    undef,          # ctime
    512,            # block size
    *$slf->{'lgt'}, # blocks
  );
}

*sysread = $und;

sub syswrite
{ my ($slf, $str, $lgt, $off) = @_;
  my ($buf, $pos, @lin);

  if (ref($str) eq 'ARRAY')
  { @lin = @$str;
  }
  elsif (defined($str))
  { @lin = split(/\n/, $str);
  }
  if ($off || $lgt)
  { $lgt = scalar @lin unless defined($lgt);
    $off = 0           unless defined($off);
    @lin = splice(@lin, $off, $lgt);
  }
  $lgt = scalar @lin;

  $buf = *$slf->{'buf'};
  $pos = *$slf->{'pos'};
  splice(@$buf, $pos, $lgt, @lin);
  *$slf->{'pos'} += $lgt;
  *$slf->{'lgt'} = scalar @$buf;
  return $lgt;
}

sub truncate
{ my ($slf, $lgt) = @_;
  my ($buf, $cnt);

  $buf = *$slf->{'buf'};
  $lgt = 0 unless defined($lgt);
  $cnt = $lgt - *$slf->{'lgt'};
  if ($cnt > 0)
  { push(@$buf, *$slf->{'pad'}) while $cnt-- > 0;
  }
  else
  { pop(@$buf) while $cnt++ < 0;
  }
  *$slf->{'pos'} = $lgt if *$slf->{'pos'} > $lgt;
  *$slf->{'lgt'} = $lgt;
  1;
}

=head1 I/O METHODS RELATED TO PERL VARIABLES

See L<perlvar> for complete descriptions of each of the following methods. All
of them return the previous value of the attribute and takes an optional single
argument that when given will set the value. If no argument is given the
previous value is unchanged.

    $|    $io-E<gt>autoflush([BOOL])
    $.    $io-E<gt>input_line_number([NUM])

=cut

*autoflush = $und;

sub input_line_number
{ my ($slf, $val) = @_;

  $slf->setinfo('pos', $val);
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

*blocking = $und;
*clearerr = $und;
*error = $und;
*fcntl = $und;
*flush = $und;

sub getline
{ my $slf = shift;
  my ($buf, $lgt, $pos);

  $buf = *$slf->{'buf'};
  return undef unless $buf;
  $lgt = *$slf->{'lgt'};
  $pos = *$slf->{'pos'};
  return undef if $pos >= $lgt;

  unless (defined($/))  # No line separator defined
  { *$slf->{'pos'} = $lgt--;
    return join(' ', $buf->[$pos..$lgt]);
  }
  unless (length($/))   # Paragraph mode
  { my ($eol, $lin, @buf);

    $eol = 0;
    while ($pos < $lgt)
    { $lin = $buf->[$pos++];
      if ($lin eq '')
      { $eol++;
      }
      elsif ($eol)
      { --$pos;
        last;
      }
      else
      { push(@buf, $lin);
      }
    }
    *$slf->{'pos'} = $pos;
    return join(' ', @buf);
  }
  return $buf->[*$slf->{'pos'}++];
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

*printflush = $und;
*setbuf = $und;
*setvbuf = $und;
*sync = $und;
*ungetc = $und;
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
  my ($buf, $lgt, $pos);

  $buf = *$slf->{'buf'};
  return 0 unless $buf;
  $pos = *$slf->{'pos'};
  $lgt = *$slf->{'lgt'};

  if ($typ == 0)
  { $pos = $off;
  }
  elsif ($typ == 1)
  { $pos += $off;
  }
  elsif ($typ == 2)
  { $pos = $lgt + $off;
  }
  else
  { die "RDA-01103: Bad whence '$typ'\n";
  }

  $pos = 0 if $pos < 0;
  $slf->truncate($pos) if $pos > $lgt;
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
    { $buf .= "$pre  $key => '[...]'\n";
    }
    elsif ($key eq 'pad')
    { $buf .= "$pre  $key => '".*$slf->{$key}."'\n";
    }
    else
    { $buf .= "$pre  $key => ".*$slf->{$key}."\n";
    }
  }
  $buf .=  "$pre}, RDA::Handle::Data";
  $buf;
}

=head2 S<$io-E<gt>getbuf>

This method returns the buffer content.

=cut

sub getbuf
{ my ($slf) = @_;

  *$slf->{'buf'};
}

=head2 S<$io-E<gt>pad([$line])>

This method manages the padding line. It returns the previous value of
the attribute and takes an optional single argument that when given will set
the value. If no argument is given the previous value is unchanged.

=cut

sub pad
{ my ($slf, $pad) = @_;

  $pad =~ s/[\n\r]+$// if defined($pad);
  $slf->setinfo('pad', $pad);
}

=head1 TIE METHODS

Following methods are implemented to emulate a file handle:

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

L<RDA::Agent|RDA::Agent>,
L<RDA::Handle::Memory|RDA::Handle::Memory>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
