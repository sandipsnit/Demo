# Header.pm: Routines for Managing Archive Headers

package RDA::Archive::Header;

# $Id: Header.pm,v 1.8 2012/01/02 16:33:54 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Archive/Header.pm,v 1.8 2012/01/02 16:33:54 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Archive::Header - Routines for Managing Archive Headers

=head1 SYNOPSIS

require RDA::Archive::Header;

=head1 DESCRIPTION

Routines for managing archive headers.

Available routines are:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Handle::Area;
  use RDA::Handle::Memory;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($DATA_SIG $DICT_SIG $FILE_SIG $ITEM_SIG
            $DEFLATED $STORED $VERSION @EXPORT_OK @ISA);
$VERSION   = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw($DATA_SIG $DICT_SIG $FILE_SIG $ITEM_SIG
                $DEFLATED $STORED);
@ISA       = qw(Exporter);

# Detect the presence of Compress::Zlib package
my ($BITS, $STA_EOF, $STA_OK);
eval {
  require Compress::Zlib;
  $BITS    = Compress::Zlib::MAX_WBITS();
  $STA_EOF = Compress::Zlib::Z_STREAM_END();
  $STA_OK  = Compress::Zlib::Z_OK();
  require RDA::Handle::Deflate;
};
my $EMUL = $@;

# Define the global public constants
$DATA_SIG = 0x08074b50;
$DICT_SIG = 0x06054b50;
$FILE_SIG = 0x04034b50;
$ITEM_SIG = 0x02014b50;

$DEFLATED = 8;
$STORED   = 0;

# Define the global private variables
my %tb_hdr = (
  # File header
  $ITEM_SIG  => [42,
                 'C2 v3 V4 v5 V2',
                 [qw(dir1 dir2 ver flg met mod crc off szu lfn lef lcm),
                  qw(dir3 dir4 dir5 dir6)],
                 [['lfn', 'nam'],
                  ['lef', 'ext'],
                  ['lcm', 'dsc']],
                ],
  # Local file header
  $FILE_SIG  => [26,
                 'v3 V4 v2',
                 [qw(ver flg met mod crc siz szu lfn lef)],
                 [['lfn', 'nam'],
                  ['lef', 'ext']],
                ],
  # Digital signature
  0x05054b50 => [6,
                 'v',
                 [qw(lsg)],
                 [['lsg', 'dsg']],
                ],
  # End of central directory record
  $DICT_SIG  => [18,
                 'v4 V2 v',
                 [qw(ecd1 ecd2 ecd3 ecd4 ecd5 ecd6 lcm)],
                 [['lcm', 'dsc']],
                ],
  # End of central directory record (Zip64) - incomplete
  0x06064b50 => [52,
                 'V13',
                 [qw(ecd1 ecd2 ecd3 ecd4 ecd5 ecd6 ecd7 ecd8 ecd9),
                  qw(ecd10 ecd11 ecd12 ecd13)],
                 [],
                ],
  # End of central directory record (Zip64) - incomplete
  0x07064b50 => [20,
                 'V5',
                 [qw(ecd1 ecd2 ecd3 ecd4 ecd5)],
                 [],
                ],
  # Archive extra data record
  $DATA_SIG  => [4,
                 'V',
                 [qw(lef)],
                 [['lef', 'ext']],
                ],
  # Data descriptor
  0x08074b50 => [12,
                 'V3',
                 [qw(crc siz szu)],
                 [],
                ],
  );
my %tb_sig = map {$_ => 1} keys(%tb_hdr);

# Report the module version number
sub Version
{ $VERSION;
}

=head1 METHODS

=head2 S<RDA::Archive::Header-E<gt>new($arc,$ifh,$typ)>

Object constructor.

C<RDA::Archive::Header> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'buf' > > Data buffer

=item S<    B<'crc' > > Content CRC

=item S<    B<'dsc' > > Comment field

=item S<    B<'ext' > > Extension field

=item S<    B<'flg' > > Item flag

=item S<    B<'hnd' > > Content read handle

=item S<    B<'ifh' > > Archive file handle

=item S<    B<'lcm' > > Length of the comment field

=item S<    B<'lef' > > Length of extension field

=item S<    B<'lfn' > > File name length

=item S<    B<'met' > > Compression method

=item S<    B<'nam' > > File name

=item S<    B<'nxt' > > Next signature

=item S<    B<'pos' > > Header position inside the archive

=item S<    B<'sig' > > Associated signature

=item S<    B<'siz' > > Compressed data size

=item S<    B<'szu' > > Uncompressed data size

=back

=cut

sub new
{ my ($cls, $arc, $ifh, $sig) = @_;
  my ($buf, $chr, $hdr, $key, $lgt, $off, $pos, $slf, $str, $typ);

  # Read and decode the header
  $hdr = $tb_hdr{$sig};
  $pos = $ifh->tell;
  unless (_read($ifh, \$buf, $hdr->[0]))
  { $arc->error(sprintf('Error reading header (%s) at offset %08x', $typ,
      $ifh->tell));
    return undef;
  }
  $off = -1;
  $slf = bless {
    hdr => $hdr,
    ifh => $ifh,
    pos => $pos,
    sig => $sig,
    map {$hdr->[2]->[++$off] => $_} unpack($hdr->[1], $buf)
    }, $cls;

  # Read additional information (except the file)
  foreach my $itm (@{$hdr->[3]})
  { next unless $lgt = $slf->{$itm->[0]};
    $key = $itm->[1];
    $slf->{$key} = '';
    unless (_read($ifh, \$slf->{$key}, $lgt))
    { $arc->error(sprintf('Error reading item details (%s) at offset %08x',
        $key, $ifh->tell));
      return undef;
    }
  }

  # Check if a data descriptor is used
  if ($slf->{'sig'} == $FILE_SIG && $slf->{'flg'} & 8)
  { unless (_read($ifh, \$buf, 4))
    { $arc->error(sprintf('Error reading data descriptor at offset %08x',
        $ifh->tell));
      return undef;
    }

    for (;;)
    { $typ = unpack('V', $key = substr($buf, -4));
      if (exists($tb_sig{$typ}))
      { if ($typ == $DATA_SIG)
        { $slf->{'buf'} = substr($buf, 0, -4);
          unless (_read($ifh, \$buf, 12))
          { $arc->error(
              sprintf('Error reading data descriptor content at offset %08x',
                      $ifh->tell));
            return undef;
          }
        }
        elsif (($lgt = length($buf)) < 16)
        { $arc->error(sprinf('Incomplete data descriptor (%d) at offset %08x',
            $lgt, $ifh->tell));
          $slf->{'nxt'} = $key;
          return $slf;
        }
        else
        { $slf->{'buf'} = substr($buf, 0, -16);
          $slf->{'nxt'} = $key;
          $buf = substr($buf, -16, 12);
        }
        last;
      }
      unless ($ifh->read($chr, 1))
      { if (($lgt = length($buf)) < 12)
        { $arc->error(sprinf('Incomplete data descriptor (%d) at offset %08x',
            $lgt, $ifh->tell));
          return undef;
        }
        $slf->{'buf'} = substr($buf, 0, -12);
        $buf = substr($buf, -12);
        last;
      }
      $buf .= $chr;
    }
    ($slf->{'crc'}, $slf->{'siz'}, $slf->{'szu'}) = unpack('V3', $buf);
  }

  # Return the zip file object reference
  $slf;
}

sub _read
{ my ($ifh, $buf, $lgt) = @_;

  ($lgt > 0) ? $ifh->read($$buf, $lgt) == $lgt : 1;
}

=head2 S<$h-E<gt>delete>

This method deletes the header object.

=cut

sub delete
{ # Close existing file handle
  delete($_[0]->{'hnd'})->close if exists($_[0]->{'hnd'});

  # Delete the object
  undef %{$_[0]};
  undef $_[0];
}

=head2 S<RDA::Archive::Header-E<gt>find($arc,$ifh[,$sig])>

This method finds the next header type. Otherwise, it returns an undefined
value.

=cut

sub find
{ my ($cls, $arc, $ifh, $sig) = @_;
  my ($chr, $typ);

  if (defined($sig) || $ifh->read($sig, 4) == 4)
  { return $typ if exists($tb_hdr{$typ = unpack('V', $sig)});
    $arc->error(sprintf('Unknown header signature (%08x) at offset %08x', $typ,
      $ifh->tell - 4));
    for (;;)
    { last unless $ifh->read($chr, 1);
      $sig = substr($sig, -3).$chr;
      return $typ
        if $sig =~ m/^PK/ && exists($tb_hdr{$typ = unpack('V', $sig)});
    }
  }
  undef;
}

=head2 S<$h-E<gt>get_handle>

This method returns a file handle to the corresponding data or an undefined
value in case of problems.

=cut

sub get_handle
{ my ($slf) = @_;
  my ($ifh, $met, $siz) = @_;

  if (exists($slf->{'siz'}))
  { return RDA::Handle::Memory->new('') unless ($siz = $slf->{'siz'});
    $met = $slf->{'met'};
    return $slf->{'hnd'} = exists($slf->{'buf'})
      ? RDA::Handle::Deflate->new(
          RDA::Handle::Memory->new(delete($slf->{'buf'})), $siz)
      : RDA::Handle::Deflate->new($slf->{'ifh'}, $siz)
      if $met eq '8' && !$EMUL;
    return $slf->{'hnd'} = exists($slf->{'buf'})
      ? RDA::Handle::Memory->new(delete($slf->{'buf'}))
      : RDA::Handle::Area->new($slf->{'ifh'}, $siz)
      if $met eq '0';
  }
  undef;
}

=head2 S<$h-E<gt>get_info($key[,$dft])>

This method returns the value of the header attribute. If the header attribute
does not exist, then it returns the default value.

=cut

sub get_info
{ my ($slf, $key, $dft) = @_;

  exists($slf->{$key}) ? $slf->{$key} : $dft;
}

=head2 S<$h-E<gt>get_method>

This method returns the archiving method.

=cut

sub get_method
{ my $met = shift->{'met'};

  !defined($met) ? -1 :
  ($met eq '0')  ? $STORED :
  $EMUL          ? -1 :
  ($met eq '8')  ? $DEFLATED :
                   -1;
}

=head2 S<$h-E<gt>get_name>

This method returns the archive file name.

=cut

sub get_name
{ shift->{'nam'};
}

=head2 S<$h-E<gt>get_next>

This method returns the next signature when the signature is already loaded.

=cut

sub get_next
{ shift->{'nxt'};
}

=head2 S<$h-E<gt>get_position>

This method returns the header position in the file.

=cut

sub get_position
{ shift->{'pos'};
}

=head2 S<$h-E<gt>get_signature>

This method returns the header signature.

=cut

sub get_signature
{ shift->{'sig'};
}

=head2 S<$h-E<gt>skip_content>

This method skips the content associated to the current header.

=cut

sub skip_content
{ my ($slf) = @_;
  my ($siz);

  if (exists($slf->{'buf'}))
  { delete($slf->{'buf'});
  }
  elsif (exists($slf->{'hnd'}))
  { delete($slf->{'hnd'})->close;
  }
  elsif (exists($slf->{'siz'}))
  { $slf->{'ifh'}->seek($siz, 1) if ($siz = $slf->{'siz'});
  }
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Handle::Area|RDA::Handle::Area>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate>,
L<RDA::Handle::Memory|RDA::Handle::Memory>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
