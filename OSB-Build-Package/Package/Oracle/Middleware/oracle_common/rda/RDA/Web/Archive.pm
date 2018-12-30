# Archive.pm: Archive Web Service

package RDA::Web::Archive;

# $Id: Archive.pm,v 1.4 2012/01/02 16:31:11 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Web/Archive.pm,v 1.4 2012/01/02 16:31:11 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Web::Archive - Archive Web Service

=head1 SYNOPSIS

require RDA::Web::Archive;

=head1 DESCRIPTION

The objects of the C<RDA::Web::Archive> class are used to perform display
requests from a report package. It supports ZIP format only.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Archive::Rda;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

# Define the global constants
my $DOC = "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>";
my $EOL = "\015\012";

# Define the global private variables
my %tb_typ = (
  bz2  => 'application/x-bzip2',
  css  => 'text/css',
  gz   => 'application/x-gzip',
  htm  => 'text/html',
  html => 'text/html',
  tar  => 'application/x-tar',
  tgz  => 'application/x-gzip',
  txt  => 'text/text',
  z    => 'application/x-compress',
  zip  => 'application/zip',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Web::Archive-E<gt>new($agt,pth)>

The object constructor. This method enables you to specify the agent reference
and the archive path as arguments.

C<RDA::Web::Archive> is represented by a blessed hash reference. The following
special key is used:

=over 12

=item S<    B<'_cat'> > Archive catalog

=item S<    B<'_ctl'> > Reference to the archive control object

=item S<    B<'_dft'> > Default page

=item S<    B<'_pth'> > Archive path

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, $pth) = @_;

  # Validate the archive
  return undef unless $pth && -f $pth && -r $pth;

  # Create the service object and return its reference
  bless {
    _cat => {},
    _dft => 'RDA__start.htm',
    _pth => $pth,
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>delete>

This method deletes the display object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>request($ofh,$met,$url)>

This method executes a display request. It returns 0 on successful
completion. Otherwise, it returns a non-zero value.

=cut

sub request
{ my ($slf, $ofh, $met, $url) = @_;
  my ($buf, $cat, $ctl, $hdr, $ifh, $lgt, $suf, $typ);

  # Analyze the archive on first use
  if (exists($slf->{'_ctl'}))
  { $ctl = $slf->{'_ctl'};
  }
  else
  { $slf->{'_ctl'} = $ctl = RDA::Archive::Rda->new($slf->{'_pth'}, 1);
    $ctl->scan(\&_scan, $slf);
  }

  # Check for default URL
  unless (defined($url) && length($url))
  { $hdr = "HTTP/1.0 301 OK$EOL".
      "Location: /archive/".$slf->{'_dft'}.$EOL.$EOL;
    syswrite($ofh, $hdr, length($hdr));
    return 0;
  }

  # Validate the request
  $cat = $slf->{'_cat'};
  return 1 if $url =~ m#^\.# || $url =~ m#\/\.#;
  return 2 unless exists($cat->{$url}) || exists($cat->{$url = lc($url)});
  return 3 unless ref($hdr = $ctl->find(@{$cat->{$url}}))
    && defined($ifh = $hdr->get_handle);

  # Determine the MIME type
  $typ = 'application/octet-stream';
  $lgt = 0;
  if ($url =~ m/\.([a-z][a-z0-9]*)$/i)
  { $suf = lc($1);
    if (exists($tb_typ{$suf}))
    { $typ = $tb_typ{$suf} if exists($tb_typ{$suf});
    }
    elsif ($suf eq 'dat')
    { $lgt = $ifh->sysread($buf, 4096);
      $typ = 'text/plain' unless $buf =~ m/[^\b\f\n\r\t\040-\176]/
    }
  }

  # Generate the page
  $hdr = "HTTP/1.0 200 OK$EOL".
    "Content-Type: $typ; charset=UTF-8$EOL$EOL";
  syswrite($ofh, $hdr, length($hdr));
  syswrite($ofh, $buf, $lgt) if $lgt;
  while ($lgt = $ifh->sysread($buf, 4096))
  { syswrite($ofh, $buf, $lgt);
  }
  $ifh->close;

  # Indicate a successful completion
  0;
}

sub _scan
{ my ($nam, $hdr, $slf) = @_;

  $slf->{'_cat'}->{$nam} = [$hdr->get_signature, $hdr->get_position];
  $slf->{'_dft'} = $nam if $nam =~ m/^\w+__start\.htm$/i;
  0;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
