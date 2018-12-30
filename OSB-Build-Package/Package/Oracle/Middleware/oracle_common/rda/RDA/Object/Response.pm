# Response.pm: Class Used for Objects to Manage HTTP Responses
package RDA::Object::Response;

# $Id: Response.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Response.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Response - Class Used for Objects to Manage HTTP Responses

=head1 SYNOPSIS

require RDA::Object::Response;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Response> class are used to manage HTTP
responses. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  mlt => {cnt => 1},
  obj => {'RDA::Object::Request' => 1},
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'get_code'         => {ret => 0},
    'get_codes'        => {ret => 1},
    'get_content'      => {ret => 0},
    'get_field'        => {ret => 0},
    'get_header'       => {ret => 0},
    'get_info'         => {ret => 0},
    'get_keys'         => {ret => 1},
    'get_lines'        => {ret => 1},
    'get_message'      => {ret => 0},
    'get_previous'     => {ret => 0},
    'get_request'      => {ret => 0},
    'get_type'         => {ret => 0},
    'is_redirected'    => {ret => 0},
    'is_success'       => {ret => 0},
    'need_credentials' => {ret => 0},
    'set_error'        => {ret => 0},
    'set_field'        => {ret => 0},
    },
  new => 0,
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Response-E<gt>new($req)>

The object constructor.

C<RDA::Object::Response> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'cnt' > > Response content

=item S<    B<'cod' > > HTTP code

=item S<    B<'cok' > > Cookie list

=item S<    B<'err' > > Response error

=item S<    B<'fld' > > HTTP header fields

=item S<    B<'hdr' > > HTTP header lines

=item S<    B<'req' > > Related HTTP request

=back

=cut

sub new
{ my ($cls, $req) = @_;

  # Create the object and return its reference
  bless {
    'cnt' => [],
    'cod' => 500,
    'err' => 'Invalid response',
    'fld' => {},
    'hdr' => [],
    'req' => $req,
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>as_string>

This method returns the response content as a string.

=cut

sub as_string
{ join('', @{shift->{'cnt'}});
}

=head2 S<$h-E<gt>get_code>

This method returns the response code.

=cut

sub get_code
{ shift->{'cod'};
}

=head2 S<$h-E<gt>get_codes>

This method returns the list of response HTTP codes, including the HTTP
response codes of all redirected requests.

=cut

sub get_codes
{ my ($slf) = @_;
  my (@sta);

  while (ref($slf) eq 'RDA::Object::Response')
  { push(@sta, $slf->{'cod'});
    $slf = $slf->get_previous;
  }
  @sta;
}

=head2 S<$h-E<gt>get_content>

This method returns the response content.

=cut

sub get_content
{ shift->{'cnt'};
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

=head2 S<$h-E<gt>get_header>

This method returns the response header.

=cut

sub get_header
{ shift->{'hdr'};
}

=head2 S<$h-E<gt>get_keys>

This method returns the list of defined HTTP header fields.

=cut

sub get_keys
{ sort keys(%{shift->{'fld'}});
}

=head2 S<$h-E<gt>get_lines>

This method returns the response content as a list of lines.

=cut

sub get_lines
{ split(/\n/, join('',@{shift->get_content}));
}

=head2 S<$h-E<gt>get_message>

This method returns the response message.

=cut

sub get_message
{ shift->{'err'};
}

=head2 S<$h-E<gt>get_previous>

This method returns the previous response. It returns an undefined value when
the request was not redirected.

=cut

sub get_previous
{ shift->{'req'}->get_info('rsp');
}

=head2 S<$h-E<gt>get_request>

This method returns the request that produces the specified response.

=cut

sub get_request
{ shift->{'req'};
}


=head2 S<$h-E<gt>get_type([$dft])>

This method returns the HTTP response content MIME type. When the type is not
found, it returns the default value.

=cut

sub get_type
{ my ($slf, $dft) = @_;

  ($slf->get_field('Content-Type') =~ m#^([^/]+/[^;\s]+)#) ? $1 : $dft;
}

=head2 S<$h-E<gt>is_redirected>

This method indicates that the request was redirected.

=cut

sub is_redirected
{ my $cod = shift->{'cod'};

  $cod == 301 || $cod == 302 || $cod == 303 || $cod == 307;
}

=head2 S<$h-E<gt>is_success>

This method indicates that the request was successful.

=cut

sub is_success
{ shift->{'cod'} == 200;
}

=head2 S<$h-E<gt>need_credentials>

This method indicates that an authentication has been requested. RDA supports
basic authentication only at the moment. It returns the C<host:port/realm>
combination. Otherwise, it returns an undefined value for unsupported or failed
authentications.

=cut

sub need_credentials
{ my ($slf) = @_;
  my ($req, $str);

  # Determine if credentials are required
  $req = $slf->{'req'};
  $str = exists($slf->{'fld'}->{'Www-Authenticate'})
    ? $slf->{'fld'}->{'Www-Authenticate'}
    : '';
  return undef unless $slf->{'cod'} == 401
    && $str =~ m/^basic\s+realm="(.*)"/i
    && !$req->get_field('Authorization');

  # Determine the credentials entry.
  $req->get_info('srv').':'.$req->get_info('prt').'/'.$1;
}

=head2 S<$h-E<gt>set_error($sta,$err)>

This method specifies a response error.

=cut

sub set_error
{ my ($slf, $cod, $err) = @_;

  $err =~ s/[\n\r\s]+$//;
  $slf->{'cod'} = $cod;
  $slf->{'err'} = $err;
}

=head2 S<$h-E<gt>set_field($key,$val)>

This method adds a HTTP header field. It stores cookies separately.

=cut

sub set_field
{ my ($slf, $key, $val) = @_;

  $key = lc($key);
  if ($key eq 'set-cookie')
  { $slf->{'cok'} = ['-'] unless exists($slf->{'cok'});
    unshift(@{$slf->{'cok'}}, $val);
  }
  elsif ($key eq 'set-cookie2')
  { $slf->{'cok'} = ['-'] unless exists($slf->{'cok'});
    push(@{$slf->{'cok'}}, $val);
  }
  else
  { $key =~ s/\b([a-z])/\U$1/g;
    $val =~ s/^"(.*)"$/$1/;
    $slf->{'fld'}->{$key} = $val;
  }
  $val;
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
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
