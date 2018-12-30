# Http.pm: Class Used for HTTP Requests

package RDA::Library::Http;

# $Id: Http.pm,v 2.6 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Http.pm,v 2.6 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Http - Class Used for HTTP Requests

=head1 SYNOPSIS

require RDA::Library::Http;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Http> class are used to manage HTTP
requests.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Request;
  use RDA::Object::Response;
  use RDA::Object::UsrAgent;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $RPT = qr/^RDA::Object::(Pipe|Report)$/i;

my %tb_fct = (
  'addCookie'       => [\&_m_add_cookie,      'O'],
  'addReqForm'      => [\&_m_req_add_form,    'N'],
  'clearCookieJar'  => [\&_m_clr_jar,         'O'],
  'clearReqForm'    => [\&_m_req_clr_form,    'O'],
  'createRequest'   => [\&_m_req_create,      'O'],
  'getCookieJar'    => [\&_m_get_jar,         'O'],
  'getPrevious'     => [\&_m_rsp_prev,        'O'],
  'getRspCode'      => [\&_m_rsp_get_code,    'L'],
  'getRspContent'   => [\&_m_rsp_get_content, 'L'],
  'getRspField'     => [\&_m_rsp_get_field,   'L'],
  'getRspKeys'      => [\&_m_rsp_get_keys,    'L'],
  'getRspMessage'   => [\&_m_rsp_get_message, 'T'],
  'getRspType'      => [\&_m_rsp_get_type,    'T'],
  'isRedirected'    => [\&_m_rsp_tst_redir,   'T'],
  'isSuccess'       => [\&_m_rsp_tst_success, 'T'],
  'needCredentials' => [\&_m_rsp_tst_cred,    'T'],
  'saveResponse'    => [\&_m_rsp_save,        'N'],
  'setCredentials'  => [\&_m_dft_set_cred,    'T'],
  'setDftField'     => [\&_m_dft_set_field,   'T'],
  'setDftTimeout'   => [\&_m_dft_set_timeout, 'N'],
  'setRedirection'  => [\&_m_dft_set_redir,   'T'],
  'setReqField'     => [\&_m_req_set_field,   'T'],
  'submitRequest'   => [\&_m_req_submit,      'O'],
  'writeResponse'   => [\&_m_rsp_write,       'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Http-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Http> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_err'> > Last error

=item S<    B<'_max'> > Maximum number of redirections

=item S<    B<'_req'> > HTTP request

=item S<    B<'_uag'> > User Agent reference

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _err => '',
    _max => 7,
    _req => {typ => 'GET', url => ''},
    _uag => RDA::Object::UsrAgent->new($agt->get_setting('HTTP_TRACE')),
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)]);

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

=head1 HTTP REQUEST MACROS

=head2 S<addCookie(nam=E<gt>$name,val=E<gt>$value,...)>

This method adds a cookie in the user agent. It returns a reference to the
cookie jar.

=cut

sub _m_add_cookie
{ my ($slf, $ctx, @arg) = @_;

  $slf->{'_uag'}->get_info('jar')->add_cookie(RDA::Object::Cookie->new(@arg));
}

=head2 S<addReqForm($req,$elm,...)>

This method adds extra query elements to the request form. It returns the
number of elements in the form on successful completion. Otherwise, it returns
an undefined value.

=cut

sub _m_req_add_form
{ my ($slf, $ctx, $req, @arg) = @_;

  (ref($req) eq 'RDA::Object::Request') ? $req->add_form(@arg) : undef;
}

=head2 S<clearCookieJar()>

This macro deletes all cookies and returns a reference to the cookie jar.

=cut

sub _m_clr_jar
{ my ($slf) = @_;

  $slf->{'_uag'}->get_info('jar')->clear_cookies;
}

=head2 S<clearReqForm($req)>

This method clears the form and the query part. It returns the reference of the
request object on successful completion. Otherwise, it returns an undefined
value.

=cut

sub _m_req_clr_form
{ my ($slf, $ctx, $req) = @_;

  (ref($req) eq 'RDA::Object::Request') ? $req->clear_form : undef;
}

=head2 S<createRequest($type,$url)>

This macro creates a HTTP request and returns a request object.

=cut

sub _m_req_create
{ my ($slf, $ctx, $typ, $url) = @_;
  my $req;

  if ($typ && $url)
  { eval {$req = RDA::Object::Request->new($typ, $url);};
    return $req unless $@;
    $slf->{'_err'} = $@;
  }
  undef;
}

=head2 S<getCookieJar()>

This macro returns a reference to the cookie jar.

=cut

sub _m_get_jar
{ my ($slf) = @_;

  $slf->{'_uag'}->get_info('jar');
}

=head2 S<getPrevious($rsp)>

This macro returns the previous response in case of redirections. Otherwise, it
returns an undefined value.

=cut

sub _m_rsp_prev
{ my ($slf, $ctx, $rsp) = @_;

  (ref($rsp) eq 'RDA::Object::Response') ? $rsp->get_previous : undef;
}

=head2 S<getRspCode($rsp)>

This macro returns the list of response HTTP codes, including the HTTP response
codes of all redirected requests.

=cut

sub _m_rsp_get_code
{ my ($slf, $ctx, $rsp) = @_;
  my (@sta);

  while (ref($rsp) eq 'RDA::Object::Response')
  { push(@sta, $rsp->get_code);
    $rsp = $rsp->get_previous;
  }
  @sta;
}

=head2 S<getRspContent($rsp)>

This macro returns the response content as a list of lines.

=cut

sub _m_rsp_get_content
{ my ($slf, $ctx, $rsp) = @_;

  return () unless ref($rsp) eq 'RDA::Object::Response';
  split(/\n/, join('',@{$rsp->get_content}));
}

=head2 S<getRspField($rsp,$key)>

This macro returns the value of the specified HTTP header field.

=cut

sub _m_rsp_get_field
{ my ($slf, $ctx, $rsp, $key) = @_;

  (ref($rsp) eq 'RDA::Object::Response') ? $rsp->get_field($key) : undef;
}

=head2 S<getRspKeys($rsp)>

This macro returns the list of HTTP header fields present in the response.

=cut

sub _m_rsp_get_keys
{ my ($slf, $ctx, $rsp) = @_;

  return () unless ref($rsp) eq 'RDA::Object::Response';
  $rsp->get_keys;
}

=head2 S<getRspMessage($rsp)>

This macro returns the HTTP response message.

=cut

sub _m_rsp_get_message
{ my ($slf, $ctx, $rsp) = @_;

  (ref($rsp) eq 'RDA::Object::Response') ? $rsp->get_message : undef;
}

=head2 S<getRspType($rsp[,$dft])>

This macro returns the HTTP response content MIME type. When the type is not
found, it returns the default value.

=cut

sub _m_rsp_get_type
{ my ($slf, $ctx, $rsp, $dft) = @_;

  $dft = $1 if ref($rsp) eq 'RDA::Object::Response'
    && $rsp->get_field('Content-Type') =~ m#^([^/]+/[^;\s]+)#;
  $dft;
}

=head2 S<isRedirected($rsp)>

This macro indicates if the request was redirected.

=cut

sub _m_rsp_tst_redir
{ my ($slf, $ctx, $rsp) = @_;

  ref($rsp) eq 'RDA::Object::Response' && $rsp->is_redirected;
}

=head2 S<isSuccess($rsp)>

This macro indicates if the request was successful.

=cut

sub _m_rsp_tst_success
{ my ($slf, $ctx, $rsp) = @_;

  ref($rsp) eq 'RDA::Object::Response' && $rsp->is_success;
}

=head2 S<needCredentials($rsp)>

This macro indicates whether the request requires credentials for execution. It
returns the related C<host:port/realm> combination. Otherwise, it returns an
undefined value.

=cut

sub _m_rsp_tst_cred
{ my ($slf, $ctx, $rsp) = @_;

  (ref($rsp) eq 'RDA::Object::Response') ? $rsp->need_credentials : undef;
}

=head2 S<saveResponse([$rpt,]$rsp)>

This macro saves the response content as data in the report file. It returns 1
on successful completion. Otherwise, it returns 0.

=cut

sub _m_rsp_save
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_rsp_save($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_rsp_save($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_rsp_save
{ my ($slf, $ctx, $rpt, $rsp) = @_;

  # Indicate that no output has been produced
  return 0 unless ref($rsp) eq 'RDA::Object::Response';

  # Write the response content in the report file
  for (@{$rsp->get_content})
  { $rpt->write($_);
  }

  # Indicate the successful completion
  1;
}

=head2 S<setCredentials($key,$u_p)>

This macro associates credentials to a C<host:port/realm> combination.

=cut

sub _m_dft_set_cred
{ my ($slf, $ctx, $key, $u_p) = @_;

  $slf->{'_uag'}->set_credentials($key, $u_p);
}

=head2 S<setDftField($key[,$value])>

This macro specifies a default HTTP header field. When the value is undefined,
it deletes the default HTTP header field.

It returns the old value.

=cut

sub _m_dft_set_field
{ my ($slf, $ctx, $key, $val) = @_;

  $slf->{'_uag'}->set_field($key, $val);
}

=head2 S<setDftTimeout($timeout)>

This macro sets the HTTP timeout, specified in seconds, only if the value is
greater than zero. Otherwise, the timeout mechanism is disabled.

The effective value is returned.

=cut

sub _m_dft_set_timeout
{ my ($slf, $ctx, $val) = @_;

  $slf->{'_uag'}->set_timeout($val);
}

=head2 S<setRedirection([$max])>

This macro specifies a new limit for the number of redirections. It returns the
previous value. When no value is specified, the current limit is not changed.

=cut

sub _m_dft_set_redir
{ my ($slf, $ctx, $max) = @_;

  my $old = $slf->{'_max'};
  $slf->{'_max'} = $max if defined($max) && $max >= 0;
  $old;
}

=head2 S<setReqField($req,$key[,$value])>

This macro adds a HTTP header field in the request. When the value is
undefined, it deletes the HTTP header field.

It returns the old value.

=cut

sub _m_req_set_field
{ my ($slf, $ctx, $req, $key, $val) = @_;

  (ref($req) eq 'RDA::Object::Request')
    ? $req->set_field($key, $val)
    : undef;
}

=head2 S<submitRequest($req)>

This macro submits a HTTP request and returns a response object.

=cut

sub _m_req_submit
{ my ($slf, $ctx, $req) = @_;

  (ref($req) eq 'RDA::Object::Request')
    ? $slf->{'_uag'}->submit_request($req, $slf->{'_max'})
    : undef;
}

=head2 S<writeResponse([$rpt,]$rsp[,$flg])>

This macro writes the response content in the report file. When the flag is set,
it writes the body part of HTML responses only.

It returns 1 when the content has one or more lines. Otherwise, it returns 0.

=cut

sub _m_rsp_write
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_rsp_write($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_rsp_write($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_rsp_write
{ my ($slf, $ctx, $rpt, $rsp, $flg) = @_;
  my (@tbl);

  # Indicate that no output has been produced
  return 0
    unless ref($rsp) eq 'RDA::Object::Response'
    && (@tbl = split(/\015?\012/, join('',@{$rsp->get_content})));

  # Write the response content in the report file.
  if ($flg && $rsp->get_field('Content-Type') =~ m#^text/html\b#)
  { my $sec = 0;
    for (@tbl)
    { if ($sec > 0)
      { $sec = 0 if s#</BODY.*$##i; #
        $rpt->write("$_\n");
        last unless $sec;
      }
      elsif ($sec < 0)
      { if (s#^[^>]*>##)
        { $sec = 1;
          $rpt->write("$_\n") if $_;
        }
      }
      elsif (m#<BODY[^>]*>#i)
      { s#^.*<BODY[^>]*>##i;
        $sec = 1;
        $rpt->write("$_\n") if $_;
      }
      elsif (m#<BODY#i)
      { $sec = -1;
      }
    }
  }
  else
  { for (@tbl)
    { $rpt->write("$_\n");
    }
  }

  # Indicate the successful completion
  1;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Cookie|RDA::Object::Cookie>,
L<RDA::Object::Jar|RDA::Object::Jar>,
L<RDA::Object::Request|RDA::Object::Request>,
L<RDA::Object::Response|RDA::Object::Response>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
