# Web.pm: Interface Used to Manage Web Access

package RDA::Web;

# $Id: Web.pm,v 2.14 2012/04/25 16:18:04 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Web.pm,v 2.14 2012/04/25 16:18:04 mschenke Exp $
#
# Change History
# 20120425  MSC  Improve the credential management.

=head1 NAME

RDA::Web - Interface Used to Manage Web Access

=head1 SYNOPSIS

<rda> <options> -X Web <command> <switches> <arg> ...

=head1 DESCRIPTION

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
  use RDA::Options;
  use Socket;
  use Symbol;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.14 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global constants
my $DOC = "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>";
my $EOL = "\015\012";
my $ERR = "$DOC$EOL<html lang='en-US'>$EOL".
          "<head><title>RDA Viewer Error</title></head><body>$EOL";
my $TTL = "<ACRONYM title='Remote Diagnostic Agent'>RDA</ACRONYM> Viewer";

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

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<help>

This command displays the command syntaxes and the related explanations.

=cut

sub help
{ my ($agt) = @_;
  my ($pkg);

  $pkg = __PACKAGE__.'.pm';
  $pkg =~ s#::#/#g;
  $agt->get_display->dsp_pod([$INC{$pkg}], 1);

  # Indicate that the setup must not be saved
  0;
}

=head2 S<list>

This command lists available web services.

=cut

sub list
{ my ($agt) = @_;
  my ($buf, $cfg, $dir, $lgt, $max, %tbl);

  $cfg = $agt->get_config;
  $dir = $cfg->get_dir('D_RDA_PERL', 'RDA/Web');
  $max = 0;
  if (opendir(SVC, $dir))
  { foreach my $pkg (readdir(SVC))
    { next unless $pkg =~ m/^(\w+)\.pm$/i;
      $tbl{lc($1)} = $pkg;
      $max = $lgt if ($lgt = length($1)) > $max;
    }
    closedir(SVC);
  }
  if ($max)
  { $buf = ".T'Available web services are:'\n";
    foreach my $nam (sort keys(%tbl))
    { $buf .= sprintf(".I'  \001%-*s  '\n%s\n\n", $max, $nam,
        $cfg->get_title($dir, $tbl{$nam}, ''));
    }
  }
  else
  { $buf = ".P\nNo web services found\n\n";
  }
  $agt->get_display->dsp_report($buf, 1);

  # Indicate that the setup must not be saved
  0;
}

=head2 S<page url>

This command generates a help page and displays it.

=cut

sub page
{ my ($agt, $url) = @_;
  my ($pth, $qry);

  if ($url)
  { ($pth, $qry) = split(/\?/, $url, 2);
    require RDA::Web::Help;
    RDA::Web::Help->new($agt)->display(\*STDOUT, 'GET', $pth, $qry);
  }

  # Indicate that the setup must not be saved
  0;
}

=head2 S<server [switches] [port] [password]>

This command starts a basic Web server to review the reports in the report
directory structure. It uses basic authentication to restrict page access.

It supports the following command switches:

=over 16

=item B<    -p port>

Specifies the port number (C<8778> by default)

=item B<    -r>

Loads only the review-related Web services

=item B<    -s svc,...>

Specifies the authorized web services (all by default)

=item B<    -u user>

Specifies the user name (C<rda> by default)

=back

It asks for the password interactively unless a password is provided as an
argument.

You can access the start page for reviewing results with the following URL:

  http://<host>:<port>/display

=cut

sub server
{ my ($agt, @arg) = @_;
  my ($acl, $buf, $cln, $dbg, $opt, $pwd, $prt, $pth, $src, $srv, $svc, $usr,
      @svc, %opt, %src, %svc);

  # Initialization
  $dbg = $agt->get_setting('RDA_DEBUG');
  $cln = gensym;
  $srv = gensym;

  # Parse the options
  $opt = RDA::Options::getopts('p:rs:u:z:', \@arg);
  $prt = exists($opt->{'p'}) ? $opt->{'p'} : 8778;
  $usr = exists($opt->{'u'}) ? $opt->{'u'} : 'rda';
  $svc = {map {lc($_) => 1} split(/,/, $opt->{'s'})} if exists($opt->{'s'});
  @svc = qw(archive display) if $opt->{'r'};
  if (defined($pth = $agt->get_info('zip',$opt->{'z'})))
  { my ($cfg);

    $cfg = $agt->get_config;
    $pth = $cfg->get_file('D_CWD', $pth)
      unless $cfg->is_absolute($pth = $cfg->cat_file($pth));
    $opt{'archive'} = $pth;
  }

  # Treat the arguments
  $pwd = '';
  foreach my $arg (@arg)
  { if ($arg =~ m/\D/)
    { $pwd = $arg;
    }
    else
    { $prt = $arg;
    }
  }
  unless ($pwd)
  { $pwd = $agt->get_access->ask_password("Enter the '$usr' password: ");
    return 0 unless $pwd;
  }
  $acl->{$usr} = $pwd;

  # Load the Web services
  unless (@svc)
  { $src = $agt->get_config->get_dir('D_RDA_PERL', 'RDA/Web');
    opendir(SVC, $src)
      or die "RDA-09000: Cannot open the Web service directory '$src':\n $!\n";
    foreach my $pkg (readdir(SVC))
    { push(@svc, lc($1)) if $pkg =~ m/^(\w+)\.pm$/i;
    }
    closedir(SVC);
  }
  foreach my $key (@svc)
  { my ($ctl, $nam);

    $nam = ucfirst($key);
    next if $svc && !exists($svc->{$key});
    eval "require RDA::Web::$nam";
    die "RDA-09001: Cannot load the Web service '$key':\n $@\n" if $@;
    $svc{$key} = $ctl if ($ctl = "RDA::Web::$nam"->new($agt, $opt{$key}));
  }
  die "RDA-09002: No services\n" unless keys(%svc);

  # Start the web server
  socket($srv, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
    or die "RDA-09003: socket error: $!";
  setsockopt($srv, SOL_SOCKET, SO_REUSEADDR, pack("l", 1))
    or die "RDA-09004: setsockopt error: $!";
  bind($srv, sockaddr_in($prt, INADDR_ANY))
    or die "RDA-09005: bind error: $!";
  listen($srv, SOMAXCONN)
    or die "RDA-9006: listen error: $!";
  _dsp_msg("server started on port $prt");

  # Treat the web requests
  local $SIG{'__WARN__'} = sub {};
  while ($src = accept($cln, $srv))
  { my ($adr, $ctl, $cnt, $htp, $lin, $met, $nam, $req, $url);

    local $SIG{'PIPE'} = 'IGNORE';

    # Get the client address
    if (exists($src{$src}))
    { ($nam, $adr, $prt) = @{$src{$src}};
    }
    else
    { ($prt, $adr) = sockaddr_in($src);
       $nam = gethostbyaddr($adr, AF_INET);
       $adr = inet_ntoa($adr);
       $nam = $adr unless defined($nam);
       $src{$src} = [$nam, $adr, $prt];
    }

    # Get the HTTP header
    $ctl = {buf => ''};
    $url = '';
    $req = {};
    binmode($cln);
    while (defined($lin = _get_line($cln, $ctl)))
    { s/[\n\r]+//;
      print "  $$/Header: $lin\n" if $dbg;
      if ($lin =~ m#^([A-Z][A-Za-z\-]*):\s+(.*)$#) #
      { $req->{lc($1)} = $2;
      }
      elsif ($lin =~ m#^(GET)\s+(.*)\s+HTTP/(\d\.\d)$#) #
      { ($met, $htp) = ($1, $3);
        ($url, $cnt) = split(/\?/, $2, 2)
      }
      elsif ($lin =~ m#^(POST)\s+(.*)\s+HTTP/(\d\.\d)$#) #
      { ($met, $htp) = ($1, $3);
        ($url) = split(/\?/, $2, 2)
      }
      elsif ($lin eq '')
      { last;
      }
    }
    _dsp_msg("Request from $nam [$adr] at port $prt:\n  $url");
    $url =~ s#/{2,}#/#g;

    # Load the request content
    if (exists($req->{'content-length'}))
    { my ($lgt, $off, $siz);

      $siz = $req->{'content-length'};
      print "  $$/Read request content (size = $siz)" if $dbg;
      $cnt = substr($ctl->{'buf'}, 0, $siz);
      $off = length($cnt);
      for ($siz -= $off ; $siz > 0 ; $siz -= $lgt, $off += $lgt)
      { print "  $$/Read request content (size = $siz)" if $dbg;
        last unless defined($lgt = sysread($cln, $cnt, $siz, $off));
      }
    }

    # Treat the request
    if (_need_authen($req, $acl))
    { # Request an authentication
      $buf = "HTTP/1.0 401 Authentication required$EOL".
        "WWW-Authenticate: basic realm=\"RDA Viewer\"$EOL".
        "Content-Type: text/html; charset=UTF-8$EOL$EOL$ERR".
        "<H1 style='color:Red'>$TTL</H1>$EOL".
        "<h2>HTTP Code 401: Authentication required</h2>$EOL".
        "</body></html>$EOL";
      syswrite($cln, $buf, length($buf));
    }
    elsif ($url !~ s#^/(\w+)(/|\z)## || !exists($svc{$svc = lc($1)}))
    { $buf = "HTTP/1.0 500 Invalid request$EOL".
        "Content-Type: text/html; charset=UTF-8$EOL$EOL$ERR".
        "<h1 style='color:Red'>$TTL</h1>$EOL".
        "<h2>HTTP Code 500: Invalid request</h2>$EOL".
        "</body></html>$EOL";
      syswrite($cln, $buf, length($buf));
    }
    elsif ($svc{$svc}->request($cln, $met, $url, $cnt))
    { $buf = "HTTP/1.0 404 Invalid page$EOL".
        "Content-Type: text/html; charset=UTF-8$EOL$EOL$ERR".
        "<h1 style='color:Red'>$TTL</h1>$EOL".
        "<h2>HTTP Code 404: Invalid request</h2>$EOL".
        "</body></html>$EOL";
      syswrite($cln, $buf, length($buf));
    }

    # Close the client socket
    close($cln);
  }

  # Indicate that the setup must not be saved
  0;
}

# Display a log message
sub _dsp_msg
{ print "$$: @_ at ".(scalar gmtime)."\n";
}

# Extract a line from the message data
sub _get_line
{ my ($cln, $ctl) = @_;
  my ($buf);

  for (;; _load_buffer($cln, $ctl))
  { # Extract the first line from the buffer
    if (length($ctl->{'buf'}))
    { _sync_line($cln, $ctl);
      return $1 if $ctl->{'buf'} =~ s/^(.*?)\015\012//;
      if ($ctl->{'buf'} =~ s/^(.*?)([\012\015])//)
      { $ctl->{'nxt'} = ($2 eq "\012") ? "\015" : "\012";
        return $1;
      }
    }

    # Accept an incomplete last line
    if ($ctl->{'eof'})
    { return undef unless length($ctl->{'buf'});
      ($buf, $ctl->{'buf'}) = ($ctl->{'buf'}, '');
      return $buf;
    }
  }
}

# Load more input in the buffer
sub _load_buffer
{ my ($cln, $ctl) = @_;

  $ctl->{'eof'} = 1
    unless sysread($cln, $ctl->{'buf'}, 1024, length($ctl->{'buf'}));
}

# Validate the authentication
sub _need_authen
{ my ($req, $acl) = @_;
  my ($enc, $pwd, $str, $usr);

  # Check if an authentication is present
  return 1 unless exists($req->{'authorization'})
    && ($req->{'authorization'} =~ m#^Basic\s+([A-Za-z0-9+/=]*)#i)
    && (length($enc = $1) % 4) == 0;

  # Decode the authentication
  local ($^W) = 0 ;
  $enc =~ s/=+$//;              # Remove padding
  $enc =~ tr|A-Za-z0-9+/| -_|;  # Convert to uuencode
  $str = '';
  $str .= unpack('u', chr(32 + 3 * length($1) / 4).$1)
    while $enc =~ /(.{1,60})/gs;

  # Validate the authentication
  ($usr, $pwd) = split(/\:/, $str, 2);
  !exists($acl->{$usr}) || $acl->{$usr} ne $pwd;
}

# Skip trailing characters from previous line
sub _sync_line
{ my ($cln, $ctl) = @_;
  my $nxt;

  if (defined($nxt = delete($ctl->{'nxt'})))
  { _load_buffer($cln, $ctl) unless length($ctl->{'buf'}) || $ctl->{'eof'};
    $ctl->{'buf'} =~ s/^$nxt?//
  }
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Daemon|RDA::Daemon>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Discover|RDA::Discover>,
L<RDA::Extra|RDA::Extra>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Display|RDA::Object::Display>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Pod|RDA::Object::Pod>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web::Archive|RDA::Web::Archive>,
L<RDA::Web::Display|RDA::Web::Display>,
L<RDA::Web::Help|RDA::Web::Help>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
