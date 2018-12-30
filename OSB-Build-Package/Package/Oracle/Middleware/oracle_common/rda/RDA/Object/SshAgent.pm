# SshAgent.pm: Class Used to Dialog with an Authentication Agent

package RDA::Object::SshAgent;

# $Id: SshAgent.pm,v 1.2 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/SshAgent.pm,v 1.2 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::SshAgent - Class Used to Dialog with an Authentication Agent

=head1 SYNOPSIS

require RDA::Object::SshAgent;

=head1 DESCRIPTION

The objects of the C<RDA::Object::SshAgent> class are used to dialog with a SSH
authentication agent. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use Socket;
  use Symbol;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);

# Define the global private constants
my $DUMP_FMT = '%s %s %s %s  ' x 4;
my $DUMP_MSK = 'a2' x 16;
my $DUMP_SPC = '  ' x 15;

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::SshAgent-E<gt>new($trc)>

The object constructor. This method enables you to specify a trace file as an
argument. It supports following attributes:

=over 11

=item S<    B<'ifh'> > Input file handle

=item S<    B<'inp'> > Encoded input size

=item S<    B<'lgt'> > Input size

=item S<    B<'ofh'> > Output file handle

=item S<    B<'out'> > Encoded output size

=item S<    B<'req'> > Request

=item S<    B<'rsp'> > Response from the authentication agent

=item S<    B<'trc'> > Optional trace file handler

=item S<    B<'_sck'>> Symbol to communicate with the authentication agent

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $trc) = @_;
  my ($fil, $sck, $slf);

  # Creates a socket to comunicate with the authentication agent
  $fil = $ENV{"SSH_AUTH_SOCK"} or die "No authentication agent\n";
  _trace($trc, "SSH Agent socket: $fil\n") if $trc;
  $sck = gensym;
  socket($sck, PF_UNIX, SOCK_STREAM, 0)
    or die "Cannot create socket: $!\n";
  connect($sck, sockaddr_un($fil))
    or die "Can't connect to $fil: $!\n";
  _trace($trc, "Connected to SSH Agent through $fil\n") if $trc;

  # Do not buffer writes
  select((select($sck), $| = 1)[$[]);

  # Create the object
  $slf = bless {
    ifh  => \*STDIN,
    lgt  => 0,
    ofh  => \*STDOUT,
    trc  => $trc,
    _sck => $sck,
    }, ref($cls) || $cls;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method closes the communication socket and deletes the library object.

=cut

sub delete
{ # Close the socket
  _trace($_[0]->{'trc'}, "Closing SSH Agent connection\n") if $_[0]->{'trc'};
  close($_[0]->{'_sck'});

  # Delete the object
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>get_request>

This method reads a request from the standard input.

=cut

sub get_request
{ my ($slf) = @_;
  my ($lgt);

  _read($slf, $slf->{'ifh'}, '<', 'inp', 4, 'request length');
  return 0 unless ($lgt = unpack('N', $slf->{'inp'}));
  _read($slf, $slf->{'ifh'}, '<', 'req', $lgt, 'request');
  $slf->{'lgt'} = $lgt;
}

=head2 S<$h-E<gt>treat_request>

This method sends a request to the authentication and writes its response in
the standard input.

=cut

sub treat_request
{ my ($slf) = @_;
  my ($lgt);

  if ($lgt = $slf->{'lgt'})
  { # Send the request to the authentication agent
    _write($slf, $slf->{'_sck'}, ']', $slf->{'inp'}, 4, 'request length');
    _write($slf, $slf->{'_sck'}, ']', $slf->{'req'}, $lgt, 'request');

    # Get the response from the authentication
    _read($slf, $slf->{'_sck'}, '[', 'out', 4, 'response length');
    return 0 unless ($lgt = unpack('N', $slf->{'out'}));
    die "Response too long: $lgt\n" if $lgt > 262144;   # 256 KB
    _read($slf, $slf->{'_sck'}, '[', 'rsp', $lgt, 'response');

    # Send the response to the caller
    _write($slf, $slf->{'ofh'}, '>', $slf->{'out'}, 4, 'response length');
    _write($slf, $slf->{'ofh'}, '>', $slf->{'rsp'}, $lgt, 'response');
  }
}

# --- Internal routines -------------------------------------------------------

# Dump a block of characters
sub _dump
{ my ($trc, $pre, $dat, $off) = @_;
  my ($adr, $hex, $lgt, $txt);

  $adr = 0;
  $lgt = length($dat) - $off;
  if ($lgt > 0)
  { for (; $lgt > 0 ; $adr += 16, $off += 16, $lgt -= 16)
    { $txt = substr($dat, $off, ($lgt >= 16) ? 16 : $lgt);
      $hex = sprintf($DUMP_FMT,
        unpack($DUMP_MSK, unpack('H*', $txt).$DUMP_SPC));
      $txt =~ s/[\000-\037\177-\237]/./g;
      _trace($trc, sprintf("%s 0x%5.5lx: %s%s\n", $pre, $adr, $hex, $txt));
    }
  }
}

# Read bytes from the specified file handle
sub _read
{ my ($slf, $ifh, $pre, $key, $lgt, $dsc) = @_;
  my ($buf, $off, $siz, $trc);

  $off = 0;
  $trc = $slf->{'trc'};
  _trace($trc, "Reading $dsc ($lgt bytes)\n") if $trc;
  $slf->{$key} = '';
  do
  { $siz = sysread($ifh, $slf->{$key}, $lgt, $off)
      or die "Read error\n";
    _dump($trc, $pre, $slf->{$key}, $off) if $trc;
    $lgt -= $siz;
    $off += $siz;
  } while ($lgt > 0);
}

# Add a line to the trace file
sub _trace
{ my ($trc, $txt) = @_;

  $trc->syswrite($txt, length($txt));
}

# Write a block to the specified file handle
sub _write
{ my ($slf, $ofh, $pre, $buf, $lgt, $dsc) = @_;
  my ($trc);

  $trc = $slf->{'trc'};
  _trace($trc, "Writing $dsc ($lgt bytes)\n") if $trc;
  syswrite($ofh, $buf, $lgt) == $lgt
    or die "Error writing: $!\n";
  _dump($trc, $pre, $buf, 0) if $trc;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
