# Rda.pm: Class Used to Manage Archives without Jar or Zip

package RDA::Archive::Rda;

# $Id: Rda.pm,v 1.10 2012/04/25 07:08:26 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Archive/Rda.pm,v 1.10 2012/04/25 07:08:26 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Archive::Rda - Class Used to Manage Archives without Jar or Zip

=head1 SYNOPSIS

require RDA::Archive::Rda;

=head1 DESCRIPTION

The objects of the C<RDA::Archive::Rda> class are used to manage archives
when F<jar> and F<zip> are not available.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::File;
  use RDA::Archive::Header qw($DICT_SIG $FILE_SIG $ITEM_SIG
                              $DEFLATED $STORED);
  use RDA::Object::Rda qw($CREATE $DIR_PERMS $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  hsh => {'RDA::Archive::Header' => 1},
  );
@ISA     = qw(Exporter);

# Detect the presence of Compress::Zlib package
my ($BITS, $STA_EOF, $STA_OK);
eval {
  require Compress::Zlib;
  $BITS    = Compress::Zlib::MAX_WBITS();
  $STA_EOF = Compress::Zlib::Z_STREAM_END();
  $STA_OK  = Compress::Zlib::Z_OK();
};
my $EMUL = $@;

# Define the global private variables
my @tb_crc = (
  0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419,
  0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4,
  0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07,
  0x90bf1d91, 0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
  0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856,
  0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
  0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4,
  0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
  0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
  0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a,
  0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599,
  0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
  0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190,
  0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f,
  0x9fbfe4a5, 0xe8b8d433, 0x7807c9a2, 0x0f00f934, 0x9609a88e,
  0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
  0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed,
  0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
  0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3,
  0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
  0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a,
  0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5,
  0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010,
  0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
  0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17,
  0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6,
  0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
  0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
  0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1, 0xf00f9344,
  0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
  0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a,
  0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
  0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1,
  0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c,
  0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef,
  0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
  0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe,
  0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31,
  0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c,
  0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
  0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b,
  0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
  0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1,
  0x18b74777, 0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
  0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
  0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7,
  0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc, 0x40df0b66,
  0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
  0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605,
  0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8,
  0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b,
  0x2d02ef8d
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Archive-E<gt>new($pth[,$flg])>

The object constructor. This method takes the archive path and the closure
indicator as arguments.

C<RDA::Object::Archive> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'flg' > > Archive closure indicator

=item S<    B<'pth' > > Archive path

=item S<    B<'_cre'> > Creation time (encoded)

=item S<    B<'_dic'> > Dictionary elements

=item S<    B<'_err'> > Error list

=item S<    B<'_ifh'> > Archive file input handler

=item S<    B<'_ofh'> > Archive file output handler

=item S<    B<'_sto'> > Force 'stored' method indicator

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $pth, $flg) = @_;

  # Create the object and return its reference
  bless {
    flg  => $flg,
    pth  => RDA::Object::Rda->cat_file($pth),
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>delete>

This macro deletes the archive control object.

=cut

sub delete
{ # Close existing file handle
  delete($_[0]->{'_ifh'})->close if exists($_[0]->{'_ifh'});

  # Delete the object
  undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>create($opt,$dir[,$item...])>

This method creates the archive file and adds the specified items to it. When
you are specifying a directory as item, it archives the whole directory. The
item paths must be specified relatively to provided base directory. By default,
it compresses the files.

It supports the following option:

=over 9

=item B<    's' > Stores only.

=back

It returns zero for a successful completion.

=cut

sub create
{ my ($slf, $opt, $dir, @fil) = @_;
  my ($fct, $ofh, @arg);

  # Create the archive
  RDA::Object::Rda->create_dir(dirname($slf->{'pth'}), $DIR_PERMS);
  $ofh = IO::File->new;
  $ofh->open($slf->{'pth'}, $CREATE, $FIL_PERMS)
    or die "RDA-08000: Cannot create archive '".$slf->{'pth'}."'\n";
  binmode($ofh);
  $slf->{'_cre'} = _encode_time(time);
  $slf->{'_dic'} = [];
  $slf->{'_ofh'} = $ofh;
  $slf->{'_sto'} = ($EMUL || index($opt, 's') >= 0) ? 1 : 0;

  # Execute the command
  if (-d $dir)
  { foreach my $fil (@fil)
    { if (ref($fil) eq 'ARRAY')
      { ($fct, @arg) = @$fil;
        foreach my $itm (&$fct($dir, @arg))
        { if (-d RDA::Object::Rda->cat_dir($dir, $itm))
          { _archive_dir($slf, $dir, $itm);
          }
          else
          { $slf->add_file($dir, $itm);
          }
        }
      }
      elsif (-d RDA::Object::Rda->cat_dir($dir, $fil))
      { _archive_dir($slf, $dir, $fil);
      }
      else
      { $slf->add_file($dir, $fil);
      }
    }
  }

  # Add the archive dictionary and return the completion status
  $slf->add_dict;
}

sub _archive_dir
{ my ($slf, $bas, $dir) = @_;
  my ($pth, @dir);

  if (opendir(ZIP, RDA::Object::Rda->cat_file($bas, $dir)))
  { # Treat the directory
    foreach my $fil (sort readdir(ZIP))
    { next if $fil =~ m/^\./ || $fil =~ m/^(CVS|META\-INF)$/i;
      $pth = RDA::Object::Rda->cat_file($bas, $dir, $fil);
      if (-f $pth)
      { $slf->add_file($bas, RDA::Object::Rda->cat_file($dir, $fil)) if -r $pth;
      }
      elsif (-d $pth )
      { push(@dir, RDA::Object::Rda->cat_dir($dir, $fil));
      }
    }
    closedir(ZIP);

    # Treat the sub directories
    foreach my $sub (@dir)
    { _archive_dir($slf, $bas, $sub);
    }
  }
}

=head2 S<$h-E<gt>extract($dir,$fil...)>

This method extracts files from the archive. It stores the files in the
specified directory.

=cut

sub extract
{ my ($slf, $dir, @fil) = @_;
  my ($cnt);

  ($cnt = @fil)
    ? $slf->scan(\&_extract, $dir, {map {_encode_name($_) => 0} @fil}, \$cnt)
    : 0;
}

sub _extract
{ my ($nam, $hdr, $slf, $dir, $tbl, $cnt) = @_;
  my ($ifh, $ofh, $pth);

  return 0 unless exists($tbl->{$nam});

  # Save the file
  if ($ifh = $hdr->get_handle)
  { $ofh = IO::File->new;
    $pth = RDA::Object::Rda->cat_file($dir, $nam);
    RDA::Object::Rda->create_dir(dirname($pth));
    if ($ofh->open($pth, $CREATE, $FIL_PERMS))
    { $ifh->save($ofh);
    }
    else
    { $slf->error("Cannot create extracted file '$pth': $!");
    }
  }
  else
  { $slf->error(
      'Unsupported compression method ('.$hdr->get_method.') for '.$nam);
  }

  # Suppress the file from the search list
  delete($tbl->{$nam});
  --$$cnt ? 0 : 1;
}

=head2 S<$h-E<gt>find($sig,$off)>

This method retrieves the specified header.

=cut

sub find
{ my ($slf, $sig, $pos) = @_;
  my ($ifh);

  (defined($ifh = $slf->get_handle) && seek($ifh, $pos, 0))
    ? RDA::Archive::Header->new($slf, $ifh, $sig)
    : undef;
}

=head2 S<$h-E<gt>get_handle>

This method returns the archive input handle.

=cut

sub get_handle
{ my ($slf) = @_;
  my ($ifh);

  return $slf->{'_ifh'} if exists($slf->{'_ifh'});

  $ifh = IO::File->new;
  return $slf->{'_ifh'} = undef unless $ifh->open('<'.$slf->{'pth'});
  binmode($ifh);
  $slf->{'_ifh'} = $ifh;
}

=head2 S<$h-E<gt>scan($fct[,@arg])>

This method scans the archive. For each file found inside the archive, it calls
the specified function wtth the following arguments: the file name, a reference
to the header object, and the specified function arguments. It stops the
processing when the function returns a true value.

=cut

sub scan
{ my ($slf, $fct, @arg) = @_;
  my ($hdr, $ifh, $met, $nam, $nxt, $sig);

  $slf->{'_err'} = [];

  # Analyze the archive
  return -2 unless defined($ifh = $slf->get_handle);
  while (defined($sig = RDA::Archive::Header->find($slf, $ifh, $nxt)))
  { # Read the header
    unless ($hdr = RDA::Archive::Header->new($slf, $ifh, $sig))
    { $nxt = undef;
      next;
    }
    $nxt = $hdr->get_next;

    # Analyze the file
    last if $sig == $FILE_SIG && defined($nam = $hdr->get_name)
      && &$fct($nam, $hdr, @arg);
    $hdr->skip_content;
  }
  $ifh->close unless $slf->{'flg'};

  # Return the completion status
  @{$slf->{'_err'}} ? -1 : 0;
}

=head1 LOW LEVEL ARCHIVE METHODS

=head2 S<$h-E<gt>add_data($nam,$str[,$met,$szu[,$ext]])>

This method adds data in the archive.

=cut

sub add_data
{ my ($slf, $nam, $str, $met, $szu, $ext) = @_;

  $met = $STORED      unless defined($met);
  $szu = length($str) unless defined($szu);
  $slf->_add_item($nam, $met, $slf->{'_cre'}, _calc_crc32($str, 0),
    length($str), $szu, $str, $ext)
}

=head2 S<$h-E<gt>add_dict>

This method adds the central dictionary and closes the archive.

=cut

sub add_dict
{ my ($slf) = @_;
  my ($beg, $cnt, $off);

  die "RDA-08001: Not open for output\n" unless exists($slf->{'_ofh'});
  $beg = $off = sysseek($slf->{'_ofh'}, 0, 1);

  # Write the headers
  $cnt = 0;
  foreach my $hdr (@{$slf->{'_dic'}})
  { my ($pos, $nam, $met, $tim, $crc, $siz, $szu, $ext) = @$hdr;

    $off += $slf->_write(pack('Vv4V4v5V2', $ITEM_SIG,
      10, 10, 0, $met, $tim, $crc, $siz, $szu,
      length($nam), length($ext), 0, 0, 0, 0, $pos).$nam.$ext);
    ++$cnt;
  }

  # Write the end of the central dictionary and own checksum
  $slf->_write(pack('Vv4V2v',
    $DICT_SIG, 0, 0, $cnt, $cnt, $off - $beg, $beg, 0));

  # Close the archive
  $slf->{'_ofh'}->close;
  delete($slf->{'_dic'});
  delete($slf->{'_ofh'});

  # Indicate the successful completion
  0;
}

=head2 S<$h-E<gt>add_dir($bas,$nam[,$ext])>

This method adds a directory in the archive.

=cut

sub add_dir
{ my ($slf, $bas, $nam, $ext) = @_;
  my ($tim, @sta);

  # Get the directory characteristics
  @sta = stat(RDA::Object::Rda->cat_dir($bas, $nam));
  $tim = defined($sta[9]) ? _encode_time($sta[9]) : $slf->{'_cre'};

  # Add the file in the archive
  $slf->_add_item(_encode_name($nam, ''), $STORED, $slf->{'_cre'}, 0, 0, 0, '',
    $ext)
}

=head2 S<$h-E<gt>add_file($bas,$nam[,$ext])>

This method adds a file in the archive.

=cut

sub add_file
{ my ($slf, $bas, $nam, $ext) = @_;
  my ($buf, $crc, $ifh, $lgt, $met, $pth, $siz, $szu, $tim, @sta);

  $pth = RDA::Object::Rda->cat_dir($bas, $nam);
  return 0 unless ($ifh = IO::File->new)->open("<$pth");

  # Get the file characteristics
  @sta = stat($pth);

  # Add the file in the archive
  $nam = _encode_name($nam);
  if ($slf->{'_sto'} || $nam =~ m/\.(jar|zip)$/i)
  { $crc = $siz = 0;
    while ($lgt = $ifh->sysread($buf, 8192))
    { $crc = _calc_crc32($buf, $crc);
      $siz += $lgt;
    }
    sysseek($ifh, 0, 0);
    $slf->_add_item($nam, $STORED, _encode_time($sta[9]), $crc, $siz, $siz,
      $ifh, $ext);
  }
  elsif ($sta[7] > 8192)
  { $slf->_add_deflate($nam, _encode_time($sta[9]), $ifh, $ext);
  }
  else
  { $slf->_add_small($nam, _encode_time($sta[9]), $ifh, $ext);
  }

  # Add the file in the archive
}

=head2 S<$h-E<gt>error($err)>

This method adds an error message to the error stack.

=cut

sub error
{ my ($slf, $err) = @_;

  push(@{$slf->{'_err'}}, $err);
}

# --- Internal Functions ------------------------------------------------------

# Add a deflated item in the archive
sub _add_deflate
{ my ($slf, $nam, $tim, $ifh, $ext) = @_;
  my ($buf, $crc, $dat, $lgt, $nxt, $obj, $off, $siz, $sta, $szu);

  die "RDA-08001: Not open for output\n" unless exists($slf->{'_ofh'});

  # Write the local header
  $crc = $siz = $szu;
  $ext = '' unless defined($ext);
  $off = sysseek($slf->{'_ofh'}, 0, 1);
  $slf->_write(pack('Vv3V4v2', $FILE_SIG, 10, 0, $DEFLATED, $tim, $crc,
    $siz, $szu, length($nam), length($ext)).$nam.$ext);

  # Deflate the file
  ($obj, $sta) = Compress::Zlib::deflateInit(
    '-Level'      => 9,
    '-Bufsize'    => 32768,
    '-WindowBits' => -$BITS,
    );
  die "RDA-08004: Cannot initialize the data deflation:\n $sta\n"
    unless $sta == $STA_OK;
  while ($lgt = $ifh->sysread($buf, 8192))
  { $szu += $lgt;
    $crc = Compress::Zlib::crc32($buf, $crc);
    ($dat, $sta) = $obj->deflate($buf);
    die "RDA-08005: Cannot deflate data for '$nam':\n $sta\n"
      unless $sta == $STA_OK;
    $siz += $slf->_write($dat);
  }
  $ifh->close;
  ($dat, $sta) = $obj->flush;
  die "RDA-8006: Cannot flush deflated data for '$nam':\n $sta\n"
    unless $sta == $STA_OK;
  $siz += $slf->_write($dat);

  # Write final header
  $nxt = sysseek($slf->{'_ofh'}, 0, 1);
  sysseek($slf->{'_ofh'}, $off, 0);
  $slf->_write(pack('Vv3V4v2', $FILE_SIG, 10, 0, $DEFLATED, $tim, $crc,
    $siz, $szu, length($nam), length($ext)).$nam.$ext);
  sysseek($slf->{'_ofh'}, $nxt, 0);

  # Store the data elements to store in the central dictionary
  push(@{$slf->{'_dic'}}, [$off, $nam, $DEFLATED, $tim, $crc, $siz, $szu,
    $ext]);
}

# Add an item in the archive
sub _add_item
{ my ($slf, $nam, $met, $tim, $crc, $siz, $szu, $dat, $ext) = @_;
  my ($buf, $off);

  die "RDA-08001: Not open for output\n" unless exists($slf->{'_ofh'});

  # Write the local header
  $ext = '' unless defined($ext);
  $off = sysseek($slf->{'_ofh'}, 0, 1);
  $slf->_write(pack('Vv3V4v2', $FILE_SIG, 10, 0, $met, $tim, $crc, $siz, $szu,
    length($nam), length($ext)).$nam.$ext);

  # Write the data
  if ($siz)
  { if (ref($dat))
    { $slf->_write($buf) while $dat->sysread($buf, 8192);
      $dat->close;
    }
    else
    { $slf->_write($dat);
    }
  }
  elsif (ref($dat))
  { $dat->close
  }

  # Store the data elements to store in the central dictionary
  push(@{$slf->{'_dic'}}, [$off, $nam, $met, $tim, $crc, $siz, $szu, $ext]);
}

# Add a small file in the archive
sub _add_small
{ my ($slf, $nam, $tim, $ifh, $ext) = @_;
  my ($buf, $crc, $dat, $met, $obj, $off, $out, $siz, $sta, $szu);

  die "RDA-08001: Not open for output\n" unless exists($slf->{'_ofh'});

  # Try to deflate the file
  $szu = $ifh->sysread($buf, 8192);
  $ifh->close;
  $crc = Compress::Zlib::crc32($buf, 0);
  ($obj, $sta) = Compress::Zlib::deflateInit(
    '-Level'      => 9,
    '-Bufsize'    => 32768,
    '-WindowBits' => -$BITS,
    );
  die "RDA-08004: Cannot initialize the data deflation:\n $sta\n"
    unless $sta == $STA_OK;
  ($dat, $sta) = $obj->deflate($buf);
  die "RDA-08005: Cannot deflate data for '$nam':\n $sta\n"
    unless $sta == $STA_OK;
  ($out, $sta) = $obj->flush;
  die "RDA-8006: Cannot flush deflated data for '$nam':\n $sta\n"
    unless $sta == $STA_OK;
  $dat .= $out;
  $siz = length($dat);

  # Select the method with minimum size
  if ($siz < $szu)
  { $met = $DEFLATED;
  }
  else
  { $met = $STORED;
    $siz = $szu;
    $dat = $buf;
  }

  # Write the local header
  $ext = '' unless defined($ext);
  $off = sysseek($slf->{'_ofh'}, 0, 1);
  $slf->_write(pack('Vv3V4v2', $FILE_SIG, 10, 0, $met, $tim, $crc, $siz, $szu,
    length($nam), length($ext)).$nam.$ext);

  # Write the data
  $slf->_write($dat);

  # Store the data elements to store in the central dictionary
  push(@{$slf->{'_dic'}}, [$off, $nam, $met, $tim, $crc, $siz, $szu, $ext]);
}

# Compute the CRC
sub _calc_crc32
{ my ($dat, $crc) = @_;

  return Compress::Zlib::crc32($dat, $crc) unless $EMUL;

  # Compute the CRC
  $crc ^= 0xffffffff;
  for (unpack('C*', $dat))
  { $crc = $tb_crc[($crc & 0xff) ^ $_] ^ ($crc >> 8);
  }
  $crc ^ 0xffffffff;
}

# Format date/time information
sub _encode_time
{ my ($tim) = @_;
  my ($day, $hou, $min, $mon, $sec, $val, $yea);

  ($sec, $min, $hou, $day, $mon, $yea) = localtime($tim);
  $val = 0;
  $val += ($sec >> 1);
  $val += ($min << 5);
  $val += ($hou << 11);
  $val += ($day << 16);
  $val += (($mon +  1) << 21);
  $val += (($yea - 80) << 25);
  $val;
}

# Format name
sub _encode_name
{ my ($nam, @arg) = @_;

  join('/', RDA::Object::Rda->split_dir($nam), @arg);
}

# Write some data to the zip file
sub _write
{ my ($slf, $buf) = @_;
  my ($lgt);

  $lgt = length($buf);
  $slf->{'sum'} += unpack('%32C*', $buf);
  $slf->{'sum'} %= 65535;
  die "RDA-08002: Cannot write archive:\n $!\n"
    unless $slf->{'_ofh'}->syswrite($buf, $lgt) == $lgt;
  $lgt;
}

1;

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Handle::Area|RDA::Handle::Area>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
