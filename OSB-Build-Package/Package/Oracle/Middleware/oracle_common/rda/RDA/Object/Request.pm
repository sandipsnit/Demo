# Request.pm: Class Used for Objects to Manage HTTP Requests

package RDA::Object::Request;

# $Id: Request.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Request.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Request - Class Used for Objects to Manage HTTP Requests

=head1 SYNOPSIS

require RDA::Object::Request;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Request> class are used to manage HTTP
requests. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Response;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  obj => {'RDA::Object::Response' => 1},
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'add_form'    => {ret => 0},
    'clear_form'  => {ret => 0},
    'get_content' => {ret => 0},
    'get_field'   => {ret => 0},
    'get_header'  => {ret => 0},
    'get_host'    => {ret => 0},
    'get_info'    => {ret => 0},
    'get_keys'    => {ret => 1},
    'get_path'    => {ret => 0},
    'set_field'   => {ret => 0},
    },
  new => 1,
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Request-E<gt>new($rsp[,$cred])>

The object constructor from a previous response.

=head2 S<$h = RDA::Object::Request-E<gt>new($typ,$url)>

The object constructor.

C<RDA::Object::Request> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'fld' > > Header fields

=item S<    B<'frm' > > Form hash

=item S<    B<'hdr' > > HTTP header lines

=item S<    B<'prt' > > URL port

=item S<    B<'pth' > > URL path

=item S<    B<'qry' > > URL query

=item S<    B<'rsp' > > Redirecting response

=item S<    B<'srv' > > URL server

=item S<    B<'typ' > > Request type (method)

=item S<    B<'url' > > Request URL

=back

When using the POST method, it converts the query part of the URL in content.

=cut

sub new
{ my ($cls, $typ, $str) = @_;
  my ($req, $slf);

  # Validate the request
  if (ref($typ) eq 'RDA::Object::Response')
  { $req = $typ->get_request;
    $slf = bless {
      fld => { %{$req->{'fld'}} },
      rsp => $typ,
      typ => $req->{'typ'},
      }, ref($cls) || $cls;
    if ($str)
    { $slf->{'fld'}->{'Authorization'} = 'Basic '.$str;
      foreach my $key (qw(prt pth qry srv url))
      { $slf->{$key} = $req->{$key} if exists($req->{$key});
      }
    }
    else
    { die "RDA-01142: Missing location\n"
        unless ($str = $typ->get_field('Location'));
      if ($typ->{'cod'} == 303)
      { $slf->{'typ'} = 'GET';
      }
      elsif ($req->{'typ'} eq 'POST' && exists($req->{'qry'}))
      { $slf->{'qry'} = $req->{'qry'}
      }
      $str = 'http://'.$req->{'srv'}.':'.$req->{'prt'}.$str if $str =~ m#^/#;
      _analyze_url($slf, $str);
    }
  }
  else
  { $typ = uc($typ);
    die "RDA-01143: Invalid type: $typ\n"
      unless $typ eq 'GET' || $typ eq 'POST';
    $slf = bless {
      fld => {},
      typ => $typ,
      }, ref($cls) || $cls;
    _analyze_url($slf, $str);
  }

  # Return the object reference
  $slf;
}

# Analyze the url
sub _analyze_url
{ my ($slf, $url) = @_;
  my ($pth, $qry);

  die "RDA-01144: Unsupported url: $url\n"
    unless $url =~ m#^http://([^:/]+)(:(\d+))?(/.*)?$#;  #
  $slf->{'url'} = $url;
  $slf->{'srv'} = $1;
  $slf->{'prt'} = $3 || 80;
  ($pth, $qry) = split(/\?/, $4) if defined($4);
  $slf->{'pth'} = $pth || '/';
  $slf->{'qry'} = $qry if defined($qry) && length($qry);
}

=head2 S<$h-E<gt>as_string>

This method returns the request URL.

=cut

sub as_string
{ my ($slf) = @_;
  my ($buf);

  $slf->{'qry'} = join('&', @{$slf->{'frm'}})
    if exists($slf->{'frm'}) && !exists($slf->{'qry'});
  $buf = 'http://'.$slf->get_host.$slf->{'pth'};
  $buf .= '?'.$slf->{'qry'} 
    if exists($slf->{'qry'}) && length($slf->{'qry'});
  $buf;
}

=head2 S<$h-E<gt>get_content>

This method returns the request content. It returns an undefined value for a
GET method or when the form is empty.

=cut

sub get_content
{ my ($slf) = @_;

  $slf->{'qry'} = join('&', @{$slf->{'frm'}})
    if exists($slf->{'frm'}) && !exists($slf->{'qry'});
  ($slf->{'typ'} eq 'POST' && exists($slf->{'qry'}) && length($slf->{'qry'}))
    ? $slf->{'qry'}
    : undef;
}

=head2 S<$h-E<gt>get_field($key[,$dft])>

This method gets a HTTP header field value. When the field is not defined, it
returns the default value.

=cut

sub get_field
{ my ($slf, $key, $val) = @_;

  if ($key)
  { $key = lc($key);
    $key =~ s/\b([a-z])/\U$1/g;
    $val = $slf->{'fld'}->{$key} if exists($slf->{'fld'}->{$key});
  }
  $val;
}


=head2 S<$h-E<gt>get_header([$flag])>

This method returns the header field stack. When the flag is set, it clears the
stack also.

=cut

sub get_header
{ my ($slf, $flg) = @_;

  $slf->{'hdr'} = [] if $flg || !exists($slf->{'hdr'});
  $slf->{'hdr'};
}

=head2 S<$h-E<gt>get_host>

This method returns the host and port number of the resource being requested. A
host without any trailing port information implies the default port for the
service requested.

=cut

sub get_host
{ my ($slf) = @_;

  ($slf->{'prt'} == 80) ? $slf->{'srv'} : $slf->{'srv'}.':'.$slf->{'prt'};
}

=head2 S<$h-E<gt>get_keys>

This method returns the list of defined HTTP header fields.

=cut

sub get_keys
{ sort keys(%{shift->{'fld'}});
}

=head2 S<$h-E<gt>get_path>

This method returns the request path. For a GET method, it includes the query
path also, if any.

=cut

sub get_path
{ my ($slf) = @_;

  $slf->{'qry'} = join('&', @{$slf->{'frm'}})
    if exists($slf->{'frm'}) && !exists($slf->{'qry'});
  ($slf->{'typ'} eq 'GET' && exists($slf->{'qry'}) && length($slf->{'qry'}))
    ? join('?', $slf->{'pth'}, $slf->{'qry'})
    : $slf->{'pth'};
}


=head2 S<$h-E<gt>set_field($key[,$value])>

This method adds a HTTP header field. When the value is undefined, it deletes
the HTTP header field. It returns the old value.

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

=head1 FORM MANAGEMENT METHODS

=head2 S<$h-E<gt>add_form(...)>

This method adds extra query elements to the list. It returns the number of
elements in the form.

=cut

sub add_form
{ my $slf = shift;

  delete($slf->{'qry'});
  $slf->{'frm'} = [] unless exists($slf->{'frm'});
  push(@{$slf->{'frm'}}, @_);
}

=head2 S<$h-E<gt>clear_form>

This method clears the form and the query part. It returns the reference of the
request object.

=cut

sub clear_form
{ my ($slf) = @_;

  delete($slf->{'qry'});
  delete($slf->{'frm'});
  $slf;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Library::Http|RDA::Library::Http>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Cookie|RDA::Object::Cookie>,
L<RDA::Object::Jar|RDA::Object::Jar>,
L<RDA::Object::Response|RDA::Object::Response>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
