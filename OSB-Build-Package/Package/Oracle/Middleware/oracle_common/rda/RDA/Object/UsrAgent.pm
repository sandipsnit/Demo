# UsrAgent.pm: Class Used for Objects to Manage a User Agent

package RDA::Object::UsrAgent;

# $Id: UsrAgent.pm,v 2.6 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/UsrAgent.pm,v 2.6 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::UsrAgent - Class Used for Objects to Manage a User Agent

=head1 SYNOPSIS

require RDA::Object::UsrAgent;

=head1 DESCRIPTION

The objects of the C<RDA::Object::UsrAgent> class are used to manage a user
agent for executing HTTP requests using a GET or POST method. It supports basic
authentication only. It supports a cookie jar to insert and extract cookies
automatically. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use Socket;
  use IO::Handle;
  use RDA::Object;
  use RDA::Object::Jar;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'get_info'        => {ret => 0},
    'set_credentials' => {ret => 0},
    'set_field'       => {ret => 0},
    'set_info'        => {ret => 0},
    'set_redirection' => {ret => 0},
    'set_timeout'     => {ret => 0},
    'set_trace'       => {ret => 0},
    'submit_request'  => {ret => 0},
    },
  new => 1,
  trc => 'HTTP_TRACE',
  );

# Define the global private variables
my $EOL = "\015\012";

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::UsrAgent-E<gt>new([$debug])>

The object constructor.

C<RDA::Object::UsrAgent> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'cre' > > Credentials hash

=item S<    B<'fld' > > Default HTTP header fields

=item S<    B<'jar' > > Cookie jar

=item S<    B<'lim' > > Timeout value (in seconds)

=item S<    B<'lvl' > > Trace level

=item S<    B<'max' > > Maximum number of redirections

=item S<    B<'oid' > > Object identifier

=back

=cut

sub new
{ my ($cls, $dbg) = @_;

  # Create the user agent object and return its reference
  bless {
    fld => {
      'Accept'          => 'text/xml,text/html;q=0.9,text/*;q=0.5',
      'Accept-Language' => 'en-us,en;q=0.5',
      'Accept-Charset'  => 'ISO-8859-1,*;q=0.5',
      'User-Agent'      => 'Mozilla/5.0',
      },
    jar => RDA::Object::Jar->new($dbg),
    lim => 30,
    lvl => $dbg,
    max => 7,
    oid => 'UserAgent',
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>set_credentials($key,$u_p)>

This method associates credentials to a C<host:port/realm> combination. When
the value is undefined, it removes the credential from the table.

=cut

sub set_credentials
{ my ($slf, $key, $u_p) = @_;
  my $old;

  $old = delete($slf->{'cre'}->{$key});
  $slf->{'cre'}->{$key} = _encode_cred($u_p) if $u_p;
  _decode_cred($old);
}

sub _decode_cred
{ my ($enc) = @_;

  # Abort when there is no credendials
  return undef unless defined($enc);

  # Decode the credentials
  local ($^W) = 0 ;
  my $str = '';
  $enc =~ s/=+$//;              # Remove padding
  $enc =~ tr|A-Za-z0-9+/| -_|;  # Convert to uuencode
  $str .= unpack('u', chr(32 + 3 * length($1) / 4).$1)
    while $enc =~ /(.{1,60})/gs;
  $str;
}

sub _encode_cred
{ my ($str) = @_;
  my ($enc, $lgt);

  $lgt = (3 - length($str) % 3) % 3;
  $enc = '';
  $enc .= substr(pack('u', $1), 1, -1)
    while $str =~ /(.{1,45})/gs;
  $enc =~ tr#` -_#AA-Za-z0-9+/#;            # Convert from uuencode
  $enc =~ s/.{$lgt}$/'=' x $lgt/e if $lgt;  # Fix padding
  $enc;
}

=head2 S<$h-E<gt>set_field($key[,$value])>

This method specifies a default HTTP field. When the value is undefined, it
deletes the default HTTP field.

It returns the old value.

=cut

sub set_field
{ my ($slf, $key, $val) = @_;
  my $old;

  if ($key)
  { $key = lc($key);
    $key =~ s/\b([a-z])/\U$1/g;
    $old = delete($slf->{'fld'}->{$key});
    $slf->{'fld'}->{$key} = $val if defined($val);
  }
  $old;
}

=head2 S<$h-E<gt>set_timeout($value)>

This method sets the HTTP timeout, specified in seconds, only if the value is
greater than zero. Otherwise, it disables the timeout mechanism.

It returns the effective value.

=cut

sub set_timeout
{ my ($slf, $val) = @_;
  my $old;

  ($old, $slf->{'lim'}) = ($slf->{'lim'}, $val);
  $old;
}

=head2 S<$h-E<gt>set_redirection([$max])>

This method specifies a new limit for the number of redirections. It returns
the previous value. When no value is specified, the current limit is not
changed.

=cut

sub set_redirection
{ my ($slf, $max) = @_;

  my $old = $slf->{'max'};
  $slf->{'max'} = $max if defined($max) && $max >= 0;
  $old;
}

=head2 S<$h-E<gt>submit_request($req[,$max])>

This method performs a HTTP request. It resolves redirections but it limits
the number of redirections to the specified maximum. By default, it allows 7
redirections.

=cut

sub submit_request
{ my ($slf, $req, $max) = @_;
  my ($adr, $buf, $hdr, $key, $lgt, $lim, $off, $rsp, $sel, $siz, $str, $val);

  # Initialization
  $max = $slf->{'max'} unless defined($max);
  $rsp = RDA::Object::Response->new($req);

  # Treat the HTTP request
  eval {
    # Prepare the request
    $hdr = $req->get_header(1);
    push(@$hdr, join(' ', $req->get_info('typ'), $req->get_path, 'HTTP/1.0'));
    push(@$hdr, 'Host: '.$req->get_host);
    foreach my $key ($req->get_keys)
    { push(@$hdr, $key.': '.$req->get_field($key));
    }
    foreach my $key (sort keys(%{$slf->{'fld'}}))
    { push(@$hdr, $key.': '.$slf->{'fld'}->{$key})
        unless exists($req->{'fld'}->{$key});
    }
    if (defined($buf = $req->get_content))
    { push(@$hdr, 'Content-Type: application/x-www-form-urlencoded');
      push(@$hdr, 'Content-Length: '.length($buf));
    }

    # Insert the cookies
    $slf->{'jar'}->insert_cookies($req);

    # Create the socket and connect to the web server
    $lim = ($slf->{'lim'} > 0) ? time + $slf->{'lim'} : 0;
    $str = $req->get_info('srv');
    die "RDA-01130: Cannot resolve $str\n"
      unless defined($adr = inet_aton($str));
    $adr = sockaddr_in($req->get_info('prt'), $adr);
    socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
      or die "RDA-01131: Socket error: $!\n";
    connect(SOCK, $adr) or die "RDA-01132: Connect error: $!\n";
    autoflush SOCK 1;
    die "RDA-01133: Connect timeout\n" if $lim && time > $lim;

    # Submit the request
    $siz = length($str = join($EOL, @$hdr).$EOL.$EOL);
    for ($off = 0 ; $siz > 0 ; $siz -= $lgt, $off += $lgt)
    { $lgt = syswrite(SOCK, $str, $siz);
      die "RDA-01134: Request error: $!\n" unless defined($lgt);
      die "RDA-01135: Request timeout\n" if $lim && time > $lim;
    }

    # Send the request content
    if (defined($buf))
    { $siz = length($buf);
      for ($off = 0 ; $siz > 0 ; $siz -= $lgt, $off += $lgt)
      { $lgt = syswrite(SOCK, $buf, $siz);
        die "RDA-01136: Request content error: $!\n" unless defined($lgt);
        die "RDA-01137: Request content timeout\n" if $lim && time > $lim;
      }
    }

    # Treat the response
    $buf = '';
    $off = 0;
    $sel = {rdm => ''};
    vec($sel->{'rdm'}, fileno(SOCK), 1) = 1;
    $sel->{'exm'} = $sel->{'rdm'};

    # Read the whole header
    while ($buf !~ m/^\015?\012/ && $buf !~ m/\015?\012\015?\012/)
    { if ($slf->_can_read($sel, $lim))
      { $lgt = sysread(SOCK, $buf, 1024, $off);
        die "RDA-01139: Response read error:$!\n" unless defined($lgt);
        last unless $lgt;
        $off += $lgt;
      }
    }

    # Decode the header
    $key = '';
    $str = $rsp->get_header;
    if ($buf =~ s#^(HTTP/(\d+\.\d+)\s+(\d+)\s*(.*?))\015?\012##)
    { $rsp->set_error($3, $4);
      push(@$str, $1);
    }
    while ($buf =~ s#^(.*?)\015?\012##)
    { my $lin = $1;
      last unless length($lin);
      push(@$str, $lin);
      if ($lin =~ m#^([\w\-\.]+)\s*:\s*(.*)#)
      { $rsp->set_field($key, $val) if $key;
        ($key, $val) = ($1, $2);
      }
      elsif ($lin =~ m#^\s+(.*)# && $key)
      { $val .= " $1";
      }
    }
    $rsp->set_field($key, $val) if $key;

    # Get the response content
    $str = $rsp->get_content;
    push(@$str, $buf) if length($buf);
    for (;;)
    { if ($slf->_can_read($sel, $lim))
      { $lgt = sysread(SOCK, $buf, 1024);
        die "RDA-01139: Response read error:$!\n" unless defined($lgt);
        last unless $lgt;
        push(@$str, $buf);
      }
    }

    # Close the request
    close(SOCK) or die "RDA-01141: Close error: $!\n";

    # Extract the cookies
    $slf->{'jar'}->extract_cookies($rsp);
  };
  $rsp->set_error(500, $@) if $@;

  # Treat the redirection
  if ($rsp->is_redirected)
  { eval {
      $rsp = $slf->submit_request(RDA::Object::Request->new($rsp), $max - 1)
        if $max > 0 && $rsp->get_field('Location');
    };
    $rsp->set_error(500, "Redirection/$@") if $@;
  }
  elsif ($str = $rsp->need_credentials)
  { eval {
      $rsp = $slf->submit_request(
        RDA::Object::Request->new($rsp, $slf->{'cre'}->{$str}), $max - 1)
        if $max > 0 && exists($slf->{'cre'}->{$str});
    };
    $rsp->set_error(500, "Authentication/$@") if $@;
  }

  # Return the response
  $rsp;
}

sub _can_read
{ my ($slf, $sel, $lim) = @_;
  my ($exm, $rdm, $ret, $tim);

  die "RDA-01140: Response timeout\n" if $lim && ($tim = $lim - time) <= 0;
  $ret = select($rdm = $sel->{'rdm'}, undef, $exm = $sel->{'exm'}, $tim);
  die "RDA-01138: Response select error:$!\n" unless $rdm;
  $ret;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Library::Http|RDA::Library::Http>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Cookie|RDA::Object::Cookie>,
L<RDA::Object::Jar|RDA::Object::Jar>,
L<RDA::Object::Request|RDA::Object::Request>,
L<RDA::Object::Response|RDA::Object::Response>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
