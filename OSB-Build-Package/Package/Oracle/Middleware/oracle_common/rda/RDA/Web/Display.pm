# Display.pm: Display Web Service

package RDA::Web::Display;

# $Id: Display.pm,v 2.6 2012/04/25 06:59:22 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Web/Display.pm,v 2.6 2012/04/25 06:59:22 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Web::Display - Display Web Service

=head1 SYNOPSIS

require RDA::Web::Display;

=head1 DESCRIPTION

The objects of the C<RDA::Web::Display> class are used to perform display
requests.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);

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

=head2 S<$h = RDA::Web::Display-E<gt>new($agt)>

The object constructor. This method enables you to specify the agent reference.

C<RDA::Web::Display> is represented by a blessed hash reference. The following
special key is used:

=over 12

=item S<    B<'_dft'> > Default page

=item S<    B<'_dir'> > Output directory

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($out);

  # Create the service object and return its reference
  $out = $agt->get_output;
  bless {
    _dft => $out->get_group.'__start.htm',
    _dir => $out->get_path('C'),
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
  my ($buf, $dir, $hdr, $lgt, $pth, $suf, $typ);

  # Check for default URL
  unless (defined($url) && length($url))
  { $hdr = "HTTP/1.0 301 OK$EOL".
      "Location: /display/".$slf->{'_dft'}.$EOL.$EOL;
    syswrite($ofh, $hdr, length($hdr));
    return 0;
  }

  # Validate the request
  $dir = $slf->{'_dir'};
  return 1 if $url =~ m#^\.# || $url =~ m#\/\.#;
  return 2
    unless -f ($pth = RDA::Object::Rda->cat_file($dir, $url))
    ||     -f ($pth = RDA::Object::Rda->cat_file($dir, lc($url)));
  return 3 unless open(FIL, "<$pth");

  # Determine the MIME type
  $typ = 'application/octet-stream';
  $lgt = 0;
  if ($pth =~ m/\.([a-z][a-z0-9]*)$/i)
  { $suf = lc($1);
    if (exists($tb_typ{$suf}))
    { $typ = $tb_typ{$suf} if exists($tb_typ{$suf});
    }
    elsif ($suf eq 'dat')
    { $lgt = sysread(FIL, $buf, 4096);
      $typ = 'text/plain' unless $buf =~ m/[^\b\f\n\r\t\040-\176]/
    }
  }

  # Generate the page
  $hdr = "HTTP/1.0 200 OK$EOL".
    "Content-Type: $typ; charset=UTF-8$EOL$EOL";
  syswrite($ofh, $hdr, length($hdr));
  syswrite($ofh, $buf, $lgt) if $lgt;
  while ($lgt = sysread(FIL, $buf, 4096))
  { syswrite($ofh, $buf, $lgt);
  }
  close(FIL);

  # Indicate a successful completion
  0;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
