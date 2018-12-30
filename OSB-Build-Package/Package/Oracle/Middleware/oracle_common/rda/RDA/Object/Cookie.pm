# Cookie.pm: Class Used for Objects to Manage HTTP Cookies

package RDA::Object::Cookie;

# $Id: Cookie.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Cookie.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Cookie - Class Used for Objects to Manage HTTP Cookies

=head1 SYNOPSIS

require RDA::Object::Cookie;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Cookie> class are used to manage HTTP
cookies. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use vars qw($SEPARATOR $VERSION @EXPORT @ISA %SDCL);
  @ISA    = qw(RDA::Object Exporter);
  @EXPORT = qw($SEPARATOR);
}

# Define the global public variables
$SEPARATOR = "; ";
$VERSION   = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
%SDCL      = (
  inc => [qw(RDA::Object)],
  met => {
    'as_cookie'      => {ret => 0},
    'decode_cookie'  => {ret => 0},
    'decode_cookie2' => {ret => 0},
    'equals'         => {ret => 0},
    'get_length'     => {ret => 0},
    'get_info'       => {ret => 0},
    'is_expired'     => {ret => 0},
    'is_netscape'    => {ret => 0},
    'is_secure'      => {ret => 0},
    'is_valid_port'  => {ret => 0},
    },
  new => 1,
  );

# Define the global private constants
my $DOMAIN    = "domain";
my $EXPIRES   = "expires";
my $MAX_AGE   = "max-age";
my $NS_COOKIE = "NS-cookie";
my $PATH      = "path";
my $PORT      = "port";
my $SECURE    = "secure";
my $VERSION   = "version";

# Define the global private variables
my %tb_key = (
  $DOMAIN    => 'dom',
  $EXPIRES   => 'exp',
  $MAX_AGE   => 'exp',
  $NS_COOKIE => 'nsc',
  $PATH      => 'pth',
  $PORT      => 'prt',
  $SECURE    => 'sec',
  $VERSION   => 'ver',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Cookie-E<gt>new([name =E<gt> $value,...])>

The object constructor. It enables you to specify initial attributes at object
creation time. You can specify attribute names in upper case to indicate
attributes that are generated by default.

C<RDA::Object::Cookie> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'dom' > > Cookie domain

=item S<    B<'exp' > > Expire date

=item S<    B<'nam' > > Cookie name

=item S<    B<'nsc' > > Is Netscape cookie?

=item S<    B<'obs' > > Obsolete cookie indicator

=item S<    B<'prt' > > Cookie port list reference

=item S<    B<'pth' > > Cookie path

=item S<    B<'sec' > > Secure cookie indicator

=item S<    B<'val' > > Cookie value

=item S<    B<'ver' > > Cookie version

=item S<    B<'_dom'> > Is domain specified?

=item S<    B<'_prt'> > Is port specified?

=item S<    B<'_pth'> > Is path specified?

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my $cls = shift;
  my ($key, $slf, $val);

  # Create the object
  $slf = bless {
    dom  => 'localhost.local',
    nsc  => 1,
    obs  => 0,
    prt  => undef,
    pth  => '/',
    ver  => 0,
    _dom => 0,
    _prt => 0,
    _pth => 0,
    }, ref($cls) || $cls;

  # Add the optional attributes
  while (($key, $val) = splice(@_, 0, 2))
  { next unless $key && defined($val);
    $slf->{lc($key)} = $val;
    $slf->{lc("_$key")} = 1 if $key eq uc($key);
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>as_cookie>

This method converts the cookie in its external form.

=cut

sub as_cookie
{ my ($slf) = @_;
  my ($buf);

  $buf = $slf->{'nam'}.'='.$slf->{'val'};
  if ($slf->{'ver'} > 0)
  { $buf .= $SEPARATOR.'$Version='.$slf->{'ver'};
    $buf .= $SEPARATOR.'$Path='.$slf->{'pth'}   if $slf->{'_pth'};
    $buf .= $SEPARATOR.'$Domain='.$slf->{'dom'} if $slf->{'_dom'};
    $buf .= $SEPARATOR.'$Port="'.join(',', @{$slf->{'prt'}}).'"'
      if $slf->{'_prt'} && ref($slf->{'prt'});
  }
  $buf;
}

=head2 S<$h-E<gt>as_string>

This method returns the object as a string.

=cut

sub as_string
{ my ($slf) = @_;
  my ($buf);

  $buf = "Set-Cookie3: ".$slf->{'nam'}.'='.$slf->{'val'}
    .$SEPARATOR.$PATH.'='.$slf->{'pth'}
    .$SEPARATOR.$DOMAIN.'='.$slf->{'dom'};
  $buf .= $SEPARATOR.$PORT.'="'.join(',', @{$slf->{'prt'}}).'"'
    if ref($slf->{'prt'});
  $buf .= $SEPARATOR.$SECURE   if $slf->{'sec'};
  $buf .= $SEPARATOR.'discard' if $slf->{'obs'};
  $buf.$SEPARATOR.$VERSION.'='.$slf->{'ver'};
}

=head2 S<$h-E<gt>decode_cookie($str)>

This method decodes a C<Set-Cookie> specification.

=cut

sub decode_cookie
{ my ($str) = @_;
  my ($key, $off, $tbl, $val, @tok);

  # Abort if the header value cannot be retrieved
  return undef unless $str;

  # Decode the cookie
  $tbl = {};
  ($val, @tok) = split(/\s*;\s*/, $str);

  # Extract the cookie name and value
  if (($off = index($val, '=')) > 0)
  { $tbl->{'nam'} = trim(substr($val, 0, $off));
    $tbl->{'val'} = trim(substr($val, $off + 1));
  }

  # Extract the other information
  foreach $val (@tok)
  { if (($off = index($val, '=')) < 0)
    { $key = $val;
      $val = '';
    }
    else
    { $key = substr($val, 0, $off);
      $val = trim(substr($val, $off + 1));
    }
    next unless exists($tb_key{$key = lc(trim($key))});
    $tbl->{$key} = $val unless exists($tbl->{$key = $tb_key{$key}});
  }

  # Align on cookie2 format
  $tbl->{'nsc'} = 0;
  $tbl->{'ver'} = 0;

  # Return the cookie definition
  exists($tbl->{'nam'}) ? $tbl : undef;
}

=head2 S<$h-E<gt>decode_cookie2($str)>

This method decodes a C<Set-Cookie2> specification.

=cut

sub decode_cookie2
{ my ($str) = @_;
  my ($key, $off, $tbl, $val, @tok);

  # Abort if the header value cannot be retrieved
  return undef unless $str;

  # Decode the cookie
  $tbl = {};
  ($val, @tok) = split(/\s*;\s*/, $str);

  # Extract the cookie name and value
  if (($off = index($val, '=')) > 0)
  { $tbl->{'nam'} = trim(substr($val, 0, $off));
    $tbl->{'val'} = trim(substr($val, $off + 1));
  }

  # Extract the other information
  foreach $val (@tok)
  { if (($off = index($val, '=')) < 0)
    { $key = $val;
      $val = '';
    }
    else
    { $key = substr($val, 0, $off);
      $val = trim(substr($val, $off + 1));
    }
    next unless exists($tb_key{$key = lc(trim($key))});
    $tbl->{$key} = $val unless exists($tbl->{$key = $tb_key{$key}});
  }

  # Assume a default version
  $tbl->{'ver'} = 0 unless exists($tbl->{'ver'});

  # Return the cookie definition
  exists($tbl->{'nam'}) ? $tbl : undef;
 }

=head2 S<$h-E<gt>equals($cookie)>

This method indicates whether the specified cookie is identical.

=cut

sub equals
{ my ($slf, $cok) = @_;

  $slf->{'nam'} eq $cok->{'nam'} &&
  $slf->{'dom'} eq $cok->{'dom'} &&
  $slf->{'pth'} eq $cok->{'pth'};
}

=head2 S<$h-E<gt>get_length>

This method returns the length of the cookie path.

=cut

sub get_length
{ length(shift->{'pth'});
}

=head2 S<$h-E<gt>is_expired>

This method indicates whether the cookie is expired.

=cut

sub is_expired
{ 0;
}

=head2 S<$h-E<gt>is_netscape>

This method indicates whether it is a Netscape cookie.

=cut

sub is_netscape
{ shift->{'nsc'};
}

=head2 S<$h-E<gt>is_secure>

This method indicates whether the cookie can be used with secure
connections only.

=cut

sub is_secure
{ shift->{'sec'};
}

=head2 S<$h-E<gt>is_valid_port($prt)>

This method indicates whether the port is in the port list.

=cut

sub is_valid_port
{ my ($slf, $prt) = @_;

  # Accept it if there is no list
  return 1 unless ref($slf->{'prt'});

  # Check if the port is in the list
  foreach my $itm (@{$slf->{'prt'}})
  { return 1 if $prt == $itm;
  }
  0;
}

# --- Internal routines -------------------------------------------------------

sub trim
{ my ($str) = @_;

  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $str;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>, 
L<RDA::Library::Http|RDA::Library::Http>, 
L<RDA::Object|RDA::Object>, 
L<RDA::Object::Jar|RDA::Object::Jar>,
L<RDA::Object::Request|RDA::Object::Request>,
L<RDA::Object::Response|RDA::Object::Response>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
