# Archive.pm: Class Used for Archive Macros

package RDA::Library::Archive;

# $Id: Archive.pm,v 1.7 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Archive.pm,v 1.7 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Archive - Class Used for Archive Macros

=head1 SYNOPSIS

require RDA::Library::Archive;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Archive> class are used to interface with
archive-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Archive::Rda;
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_fct = (
  'closeArchive'      => [\&_m_close,       'T'],
  'createArchive'     => [\&_m_create,      'N'],
  'findArchiveItem'   => [\&_m_find,        'N'],
  'getArchiveBuffer'  => [\&_m_get_buffer,  'O'],
  'getArchiveContent' => [\&_m_get_content, 'L'],
  'getArchiveInfo'    => [\&_m_get_info,    'T'],
  'openArchive'       => [\&_m_open,        'T'],
  'scanArchive'       => [\&_m_scan,        'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Archive-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Archive> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_arc'> > Archive hash

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _arc => {},
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(reset));

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}->[0]}($slf, @arg);
}

=head2 S<$h-E<gt>reset>

This method resets the library.

=cut

sub reset
{ my ($slf) = @_;

  foreach my $ctl (values(%{$slf->{'_arc'}}))
  { _delete($ctl);
  }
  $slf->{'_arc'} = {};
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 ARCHIVE CREATION MACROS

=head2 S<createArchive($path,$opt,$dir,[$item,...])>

This macro creates an archive containing the specified items. When you are
specifying a directory as item, it archives the whole directory. The item paths
must be specified relatively to provided base directory. By default, it
compresses the files.

It supports the following option:

=over 9

=item B<    's' > Stores only

=back

It returns zero for a successful completion.

=cut

sub _m_create
{ my ($slf, $ctx, $pth, $opt, $dir, @fil) = @_;

  ($pth && $dir && -d $dir)
    ? RDA::Archive::Rda->new($pth)->create($opt, $dir, @fil)
    : -1;
}

=head1 ARCHIVE MANAGEMENT MACROS

=head2 S<closeArchive($name)>

This macro closes the archive associated to the specified name.

=cut

sub _m_close
{ my ($slf, $ctx, $nam) = @_;
  my ($ctl);

  $nam = 'dft' unless defined($nam);
  _delete($ctl) if defined($ctl = delete($slf->{'_arc'}->{$nam}));
  $nam;
}

sub _close
{ my ($ctl) = @_;

  delete($ctl->{'hdr'})->delete if exists($ctl->{'hdr'});
  delete($ctl->{'arc'})->delete if exists($ctl->{'arc'});
}

=head2 S<findArchiveItem($name,$path)>

This macro searches the specified file inside the specified archive. A true
value indicates that the file is became the current archive item. It scans the
archive on first call.

=cut

sub _m_find
{ my ($slf, $ctx, $nam, $pth) = @_;
  my ($tbl);

  $nam = 'dft' unless defined($nam);
  $tbl = $slf->{'_arc'};
  (defined($pth) && exists($tbl->{$nam}))
    ? _find($tbl->{$nam}, $pth)
    : 0;
}

sub _find
{ my ($ctl, $pth) = @_;
  my ($hdr);

  # Analyze the archive on first request
  if (exists($ctl->{'hdr'}))
  { delete($ctl->{'hdr'})->delete;
  }
  elsif (!exists($ctl->{'cat'}))
  { $ctl->{'arc'}->scan(\&_content, $ctl->{'cat'} = {});
  }

  # Search the specified file
  return 0 unless exists($ctl->{'cat'}->{$pth})
    && defined($hdr = $ctl->{'arc'}->find(@{$ctl->{'cat'}->{$pth}}));
  $ctl->{'hdr'} = $hdr;
  1;
}

=head2 S<getArchiveBuffer($name[,path])>

This macro returns a buffer for the content of the current archive header. It
returns an undefined value when the compression method is not supported or in
absence of current item.

=cut

sub _m_get_buffer
{ my ($slf, $ctx, $nam, $pth) = @_;
  my ($ctl, $ifh, $tbl);

  $nam = 'dft' unless defined($nam);
  $tbl = $slf->{'_arc'};
  return undef unless exists($tbl->{$nam});
  $ctl = $tbl->{$nam};

  # Find a new header when a path is provided
  _find($ctl, $pth) if defined($pth);
  
  # Create the buffer
  (exists($tbl->{$nam}->{'hdr'})
    && defined($ifh = $tbl->{$nam}->{'hdr'}->get_handle))
    ? RDA::Object::Buffer->new('B', $ifh)
    : undef;
}

=head2 S<getArchiveContent($name)>

This macro returns the list of items contained in the archive associated to the
specified name.

=cut

sub _m_get_content
{ my ($slf, $ctx, $nam) = @_;
  my ($ctl, $tbl);

  $nam = 'dft' unless defined($nam);
  $tbl = $slf->{'_arc'};
  return () unless exists($tbl->{$nam});

  # Analyze the archive
  $ctl = $tbl->{$nam};
  $ctl->{'arc'}->scan(\&_content, $ctl->{'cat'} = {})
    unless exists($ctl->{'cat'});

  # Return the archive content
  sort keys(%{$ctl->{'cat'}});
}

sub _content
{ my ($nam, $hdr, $cat) = @_;

  $cat->{$nam} = [$hdr->get_signature, $hdr->get_position];
  0;
}

=head2 S<getArchiveInfo($name,$key[,$default])>

This macro returns the value of the specified archive header attribute. If the
header attribute does not exist, then it returns the default value. The most
useful attributes are:

=over 12

=item S<    B<'crc' > > Content CRC

=item S<    B<'dsc' > > Comment field

=item S<    B<'met' > > Compression method

=item S<    B<'nam' > > File name

=item S<    B<'sig' > > Associated signature

=item S<    B<'siz' > > Compressed data size

=item S<    B<'szu' > > Uncompressed data size

=back

=cut

sub _m_get_info
{ my ($slf, $ctx, $nam, $key, $dft) = @_;
  my ($tbl);

  $nam = 'dft' unless defined($nam);
  $tbl = $slf->{'_arc'};
  exists($tbl->{$nam}) && exists($tbl->{$nam}->{'hdr'})
    ? $tbl->{$nam}->{'hdr'}->get_info($key, $dft)
    : $dft;
}

=head2 S<openArchive($name,$path)>

This macro opens an archive and associates it to the specified name.

=cut

sub _m_open
{ my ($slf, $ctx, $nam, $pth) = @_;
  my ($tbl);

  # Delete any previous entry
  $nam = 'dft' unless defined($nam);
  $tbl = $slf->{'_arc'};
  _delete(delete($tbl->{$nam})) if exists($tbl->{$nam});

  # Open the archive
  return undef unless $pth && -r $pth;
  $tbl->{$nam} = {arc => RDA::Archive::Rda->new($pth, 1)};
  $nam;
}

=head2 S<scanArchive($name,$macro,@arg)>

This macro scans the archive associated to the specified name.

For each item, it calls the specified macro with the archive name, the item
name, and the specified arguments as arguments. A true return value aborts the
scan.

=cut

sub _m_scan
{ my ($slf, $ctx, $nam, $mac, @arg) = @_;
  my ($ctl, $tbl, $val);

  # Validate the archive name
  $nam = 'dft' unless defined($nam);
  $tbl = $slf->{'_arc'};
  return -1 unless exists($tbl->{$nam}) && $mac && $mac =~ m/^\w+$/;

  # Scan the archive
  $ctl = $tbl->{$nam};
  $val = $ctl->{'arc'}->scan(\&_scan, $ctx, $ctl, $mac, $nam, @arg);
  delete($ctl->{'hdr'});
  $val;
}

sub _scan
{ my ($nam, $hdr, $ctx, $ctl, $mac, $uid, @arg) = @_;

  $ctl->{'hdr'} = $hdr;
  $ctx->define_operator([$mac, '.macro.'], $ctx, $mac,
    RDA::Value::List::new_from_data($uid, $nam, @arg))->eval_as_scalar;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
