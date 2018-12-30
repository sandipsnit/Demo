# Jar.pm: Class Used for Objects to Manage Cookie Jars

package RDA::Object::Jar;

# $Id: Jar.pm,v 2.6 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Jar.pm,v 2.6 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Jar - Class Used for Objects to Manage Cookie Jars

=head1 SYNOPSIS

require RDA::Object::Jar;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Jar> class are used to manage cookie jars. It
is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Cookie;
  use RDA::Object::Request;
  use RDA::Object::Response;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  dep => [qw(RDA::Object::Cookie)],
  inc => [qw(RDA::Object)],
  met => {
    'add_cookie'      => {ret => 0},
    'clear_cookies'   => {ret => 0},
    'extract_cookies' => {ret => 0},
    'get_info'        => {ret => 0},
    'insert_cookies'  => {ret => 0},
    'remove_cookie'   => {ret => 0},
    'set_trace'       => {ret => 0},
    },
  new => 1,
  trc => 'JAR_TRACE',
  );

# Define the global private constants
my $TRC = 'JAR> ';

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Jar-E<gt>new([$dbg])>

The object constructor. You can specify the trace indicator as an argument.

C<RDA::Object::Jar> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'jar' > > Cookie list

=item S<    B<'lvl' > > Trace level

=item S<    B<'oid' > > Object identifier

=back

=cut

sub new
{ my ($cls, $dbg) = @_;
  my ($slf);

  bless {
    jar => [],
    lvl => $dbg ? 1 : 0,
    oid => 'CookieJar',
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>add_cookie($cookie)>

This method adds a cookie in the jar. It returns the cookie reference.

=cut

sub add_cookie
{ my ($slf, $cok) = @_;
  my ($jar, $off);

  # Create the cookie when required
  $cok = RDA::Object::Cookie->new(%$cok)
    unless ref($cok) eq 'RDA::Object::Cookie';
  print $TRC."Add cookie: ".$cok->as_string."\n" if $slf->{'lvl'};

  # Search for any older version of that cookie
  $jar = $slf->{'jar'};
  for ($off = 0 ; $off <= $#$jar ; ++$off)
  { last if $cok->equals($jar->[$off]);
  }

  # Add the cookie in the jar
  splice(@$jar, $off, 1, $cok);

  # Return the cookie reference
  $cok;
}

=head2 S<$h-E<gt>clear_cookies($rsp)>

This method remove all cookies from the cookie jar. It returns the object
reference.

=cut

sub clear_cookies
{ my ($slf) = @_;

  $slf->{'jar'} = [];

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>extract_cookies($rsp)>

This method extracts cookies from the HTTP header. It returns the response
reference.

=cut

sub extract_cookies
{ my ($slf, $rsp) = @_;
  my ($cok, $flg, $key, $lvl, $off, $pth, $prt, $srv, $str, $tbl, $val);

  if (ref($rsp) eq 'RDA::Object::Response'
    && ref($cok = $rsp->get_info('cok')))
  { # Get the corresponding URL components
    $val = $rsp->get_request;
    $srv = _normalize_host($val->get_info('srv'));
    $pth = _normalize_path($val->get_info('pth'));
    $prt = $val->get_info('prt');

    # Treat specially host names without dot
    $srv .= ".local" if index($srv, '.') < 0;

    # Treat all cookies
    $flg = 0;
    $lvl = $slf->{'lvl'};
    foreach my $def (@$cok)
    { # Decode the cookie
      if ($def eq "-")
      { $flg = 1;
        next;
      }
      next unless ref($tbl = $flg
        ? RDA::Object::Cookie::decode_cookie2($def)
        : RDA::Object::Cookie::decode_cookie($def));

      # Check the domain
      if (exists($tbl->{'dom'}))
      { $val = lc($tbl->{'dom'});
        $off = index($val, '.');
        $val = ".$val" if $flg && $off > 0;
        if (index($val, '.', 1) < 0 && $val !~ m/\.local$/)
        { print $TRC."Domain '$val' contains no embedded dot.\n" if $lvl;
          next;
        }
        if ($val =~ m/\.\d+$/)
        { print $TRC."IP address '$val' is illegal as domain.\n" if $lvl;
          next;
        }
        if (substr($srv, -length($val)) eq $val)
        { print $TRC."Domain '$val' does not match host '$srv'.\n" if $lvl;
          next;
        }
        $str = substr($srv, 0, -length($val));
        if ($flg && index($str, '.') >= 0)
        { print $TRC.
           "Host prefix '$str' contains a dot, when using domain '$val'.\n"
           if $lvl;
          next;
        }
        $tbl->{'dom'} = $val;
      }
      else
      { $tbl->{'DOM'} = $srv;
      }

      # Check the path
      if (exists($tbl->{'pth'}))
      { $val = delete($tbl->{'pth'});
        if ($val eq "")
        { $tbl->{'PTH'} = _trim_path($pth);
        }
        else
        { $val = _normalize_path($val);
          if ($flg && substr($pth, 0, length($val)) ne $val)
          { print $TRC."Path '$val' is not a prefix of '$pth'.\n" if $lvl;
            next;
          }
          $tbl->{'pth'} = $val;
        }
      }
      else
      { $tbl->{'PTH'} = _trim_path($pth);
      }

      # Check the port
      if (exists($tbl->{'prt'}))
      { $val = delete($tbl->{'prt'});
        if ($val eq '')
        { $tbl->{'PRT'} = [$prt];
        }
        else
        { $tbl->{'prt'} = [_decode_port($val)];
          if (RDA::Object::Cookie::is_valid_port($tbl, $prt))
          { print $TRC."Request port '$prt' not found\n" if $lvl;
            next;
          }
        }
      }

      # Add the cookie in the jar
      $slf->add_cookie($tbl);
    }
  }

  # Return the response reference
  $rsp;
}

=head2 S<$h-E<gt>insert_cookies($req)>

This method inserts cookies in the HTTP header. On successful completion, it
returns the request reference. Otherwise, it returns an undefined value.

=cut

sub insert_cookies
{ my ($slf, $req) = @_;
  my ($buf, $dom, $max, $prt, $pth, $sep, $val, @cok, %tbl);

  # Only do it for an HTTP request
  return unless ref($req) eq 'RDA::Object::Request';

  # Get the corresponding URL components
  $dom = _normalize_host($req->get_info('srv'));
  $pth = _normalize_path($req->get_info('pth'));
  $prt = $req->get_info('prt');

  # Treat specially host names without dot
  $dom .= '.local' if index($dom, '.') < 0;

  # Look in all relevant domains
  $val = 1;
  while (index($dom, '.') >= 0)
  { # Get relevant cookies
    foreach my $cok (@{$slf->{'jar'}})
    { push(@cok, $cok)
        if ($val || $cok->is_netscape)
        && !$cok->is_secure
        && $dom eq $cok->get_info('dom')
        && substr($pth, 0, $cok->get_length) eq $cok->get_info('pth')
        && $cok->is_valid_port($prt);
    }

    # Determine the next possible domain to investigate
    $dom = (($val = index($dom, '.')) > 0)
      ? substr($dom, $val)
      : substr($dom, 1);
  }

  # Take the cookie for most significant path
  foreach my $cok (sort {$b->get_length <=> $a->get_length} @cok)
  { $tbl{$val} = $cok
      unless exists($tbl{$val = $cok->get_info('nam')});
  }

  # Add the cookies in the header
  if (@cok = keys(%tbl))
  { $buf = $sep = '';
    $max = 0;
    foreach my $cok (sort @cok)
    { # Add the cookie contribution
      $cok = $tbl{$cok};
      $buf .= $sep;
      $buf .= $cok->as_cookie;
      $sep = $SEPARATOR;

      # Determine the highest version used
      $max = $val if ($val = $cok->get_info('ver')) > $max;
    }

    # Insert the cookies in the header
    print $TRC."Insert cookies: '$buf'\n" if $slf->{'lvl'};
    $val = $req->get_header;
    push(@$val, "Cookie: $buf");
    push(@$val, "Cookie2: \$Version=\"$max\"") if $max;
  }

  # Return the request reference
  $req;
}

=head2 S<$h-E<gt>remove_cookie($cookie)>

This method removes a cookie from the jar.

=cut

sub remove_cookie
{ my ($slf, $cok) = @_;
  my ($jar, $off);

  print $TRC."Remove cookie: ".$cok->as_string."\n" if $slf->{'lvl'};

  $jar = $slf->{'jar'};
  for ($off = 0 ; $off <= $#$jar ; ++$off)
  { return splice(@$jar, $off, 1, $cok) if $cok->equals($jar->[$off]);
  }
  undef;
}

# --- Private methods ---------------------------------------------------------

# Decode a port number list
sub _decode_port
{ my ($str) = @_;
  my (@tbl);

  foreach my $val (split(/[,"]/, $str))
  { push(@tbl, $val) if $val =~ m/^\d+$/;
  }
  @tbl ? [@tbl] : undef;
}

# Normalize the host name
sub _normalize_host
{ my ($str) = @_;

  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  lc($str);
}

# Normalize the path
sub _normalize_path
{ my ($pth) = @_;

  $pth =~ s/(\%([0-9A-Fa-f]{2}))/my $chr = chr(hex($2));
    ($chr =~ m#[\040-\044\046-\056\060-\176]#) ? $chr : $1;/eg;
  $pth;
}

# Trim the last part of the path
sub _trim_path
{ my ($pth) = @_;

  for (my $off = length($pth) ; --$off >= 0 ;)
  { return ($off > 0) ? substr($pth, 0, $off) : "/"
      if substr($pth, $off, 1) eq '/';
  }
  $pth;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>, 
L<RDA::Library::Http|RDA::Library::Http>,
L<RDA::Object|RDA::Object>, 
L<RDA::Object::Cookie|RDA::Object::Cookie>,
L<RDA::Object::Request|RDA::Object::Request>,
L<RDA::Object::Response|RDA::Object::Response>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
