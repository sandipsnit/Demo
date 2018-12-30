# Ftp.pm: Class Used for FTP Macros

package RDA::Library::Ftp;

# $Id: Ftp.pm,v 2.11 2012/04/25 06:34:53 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Ftp.pm,v 2.11 2012/04/25 06:34:53 mschenke Exp $
#
# Change History
# 20120122  MSC  Modify the access control.

=head1 NAME

RDA::Library::Ftp - Class Used for FTP Macros

=head1 SYNOPSIS

require RDA::Library::Ftp;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Ftp> class are used to interface with
FTP-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object::Ftp;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

my %tb_fct = (
  'createFtp'      => [\&_m_create,       'N'],
  'deleteFtp'      => [\&_m_delete,       'N'],
  'ftpAppend'      => [\&_m_append,       'T'],
  'ftpCd'          => [\&_m_cd,           'N'],
  'ftpCdUp'        => [\&_m_cdup,         'N'],
  'ftpCollectData' => [\&_m_collect_data, 'L'],
  'ftpCollectFile' => [\&_m_collect_file, 'L'],
  'ftpDir'         => [\&_m_dir,          'L'],
  'ftpGet'         => [\&_m_get,          'N'],
  'ftpLogin'       => [\&_m_login,        'N'],
  'ftpLs'          => [\&_m_ls,           'L'],
  'ftpMkdir'       => [\&_m_mkdir,        'N'],
  'ftpPut'         => [\&_m_put,          'T'],
  'ftpPutUnique'   => [\&_m_put_unique,   'T'],
  'ftpPwd'         => [\&_m_pwd,          'T'],
  'ftpQuote'       => [\&_m_quote,        'N'],
  'ftpRename'      => [\&_m_rename,       'N'],
  'ftpRm'          => [\&_m_rm,           'N'],
  'ftpRmdir'       => [\&_m_rmdir,        'N'],
  'ftpSite'        => [\&_m_site,         'N'],
  'getFtpCode'     => [\&_m_get_code,     'N'],
  'getFtpError'    => [\&_m_get_error,    'N'],
  'getFtpLength'   => [\&_m_get_length,   'N'],
  'getFtpMessage'  => [\&_m_get_message,  'T'],
  'getFtpModTime'  => [\&_m_modtime,      'L'],
  'getFtpResponse' => [\&_m_get_response, 'L'],
  'getFtpSize'     => [\&_m_size,         'N'],
  'getFtpStatus'   => [\&_m_get_status,   'N'],
  'isFtpSuccess'   => [\&_m_is_success,   'N'],
  'isFtpSupported' => [\&_m_is_supported, 'N'],
  'setFtpAscii'    => [\&_m_ascii,        'T'],
  'setFtpBinary'   => [\&_m_binary,       'T'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Ftp-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Ftp> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_ftp'> > FTP hash 

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _ftp => {},
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

=head1 FTP MACROS

=head2 S<createFtp($nam,$host[,...])>

This macro creates an FTP connection to the specified host. It accepts other
parameters for the FTP connection as name value pairs. If you do not specify
a trace level, it uses the C<FTP_TRACE> setting. It returns any error
encountered.

=cut

sub _m_create
{ my ($slf, $ctx, $nam, $hst, @arg) = @_;
  my ($ftp);

  # Check the supplied name
  return undef unless defined($nam);

  # Unset the current FTP connection
  _m_delete($slf, $nam) if exists($slf->{'_ftp'}->{$nam});

  # Create the FTP object
  eval {
    if (defined($ftp = RDA::Object::Ftp->new($hst,
      lvl => $slf->{'_agt'}->get_setting('FTP_TRACE', 0), @arg)))
    { $ftp->set_authen($slf->{'_agt'}->get_access);
      $slf->{'_ftp'}->{$nam} = $ftp;
    }
    };

  # Return the completion status
  $@;
}

=head2 S<deleteFtp($nam)>

This macro closes the FTP connection. It returns a true value on a successful
completion.

=cut

sub _m_delete
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? delete($slf->{'_ftp'}->{$nam})->quit
    : undef;
}

=head1 FTP STATUS MACROS

=head2 S<getFtpCode($nam)>

This macro returns the last response code.

=cut

sub _m_get_code
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get_code
    : undef;
}

=head2 S<getFtpError($nam)>

This macro returns the last error.

=cut

sub _m_get_error
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get_error
    : undef;
}

=head2 S<getFtpLength($nam)>

This macro returns the number of bytes received in the last C<get> request.

=cut

sub _m_get_length
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get_length
    : undef;
}

=head2 S<getFtpMessage($nam)>

This macro returns the last response as a string.

=cut

sub _m_get_message
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get_message
    : undef;
}

=head2 S<getFtpResponse($nam)>

This macro returns the last response as a list.

=cut

sub _m_get_response
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get_response
    : ();
}

=head2 S<getFtpStatus($nam)>

This macro returns the last response status.

=cut

sub _m_get_status
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get_status
    : undef;
}

=head2 S<isFtpSuccess($nam)>

This macro indicates whether the last request has an OK status.

=cut

sub _m_is_success
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->is_success
    : undef;
}

=head2 S<isFtpSupported($nam,$cmd)>

This macro indicates whether the specified FTP command is supported.

=cut

sub _m_is_supported
{ my ($slf, $ctx, $nam, $cmd) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->is_supported($cmd)
    : undef;
}

=head1 FTP COMMAND MACROS

=head2 S<ftpAppend($nam,$loc[,$rem])>

This macro appends a local file to a file on the remote machine. By default,
it uses the local file name in naming the remote file and the current settings
for the file transfer. It returns the remote file name.

=cut

sub _m_append
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->append(@arg)
    : undef;
}

=head2 S<ftpCd($nam[,$dir])>

This macro changes the working directory on the remote system to the specified
directory or the root directory by default. If $dir is C<..>, it uses the FTP
C<CDUP> command to attempt to move up one directory. It returns a true value on
a successful completion.

=cut

sub _m_cd
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->cd(@arg)
    : undef;
}

=head2 S<ftpCdUp($nam)>

This macro changes the remote machine working directory to the parent of the
current remote machine working directory. It returns a true value on a
successful completion.

=cut

sub _m_cdup
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->cdup
    : undef;
}

=head2 S<ftpCollectData($nam,$req,$fil)>

This macro collects the content of a remote binary file. On successful
completion, it creates an entry in the Explorer catalog. It returns the list of
the generated reports.

=cut

sub _m_collect_data
{ my ($slf, $ctx, $nam, $req, $fil, $idx, $cat) = @_;
  my ($out, $rpt, @rpt);

  if (defined($nam) && defined($req) && defined($fil)
    && exists($slf->{'_ftp'}->{$nam}))
  { $req =~ s#^/+##;
    $req =~ s#[^\-\+\=\@\.\/A-Za-z0-9]+#_#g;
    $cat = (ref($cat) eq 'RDA::Value::Array')
       ? $cat->eval_as_data(1)
       : ['E', 'B', $req];
    $idx = (ref($idx) eq 'RDA::Value::Array')
       ? $idx->eval_as_data(1)
       : undef;
    $out = $ctx->get_output;
    $rpt = $out->add_report('b', $req, 0, '.bin');
    push(@rpt, $rpt->get_file) if $slf->{'_ftp'}->{$nam}->get($fil, $rpt, 0,
      [\&_block, $rpt, 0, $idx, $cat]);
    $out->end_report($rpt);
  }
  @rpt;
}

sub _block
{ my ($flg, $rpt, $vrb, $idx, $cat) = @_;

  $flg
    ? $rpt->end_block($idx, $cat)
    : $rpt->begin_block;
}

=head2 S<ftpCollectFile($nam,$req,$fil)>

This macro collects the content of a remote data file. On successful
completion, it creates an entry in the Explorer catalog. It returns the list of
the generated reports.

=cut

sub _m_collect_file
{ my ($slf, $ctx, $nam, $req, $fil, $idx, $cat) = @_;
  my ($out, $rpt, @rpt);

  if (defined($nam) && defined($req) && defined($fil)
    && exists($slf->{'_ftp'}->{$nam}))
  { $req =~ s#^/+##;
    $req =~ s#[^\-\+\=\@\.\/A-Za-z0-9]+#_#g;
    $cat = (ref($cat) eq 'RDA::Value::Array')
       ? $cat->eval_as_data(1)
       : ['E', 'D', $req];
    $idx = (ref($idx) eq 'RDA::Value::Array')
       ? $idx->eval_as_data(1)
       : undef;
    $out = $ctx->get_output;
    $rpt = $out->add_report('d', $req, 0, '.lin');
    push(@rpt, $rpt->get_file) if $slf->{'_ftp'}->{$nam}->get($fil, $rpt, 0,
      [\&_block, $rpt, 0, $idx, $cat]);
    $out->end_report($rpt);
  }
  @rpt;
}

=head2 S<ftpDir($nam[,$dir])>

This macro gets a directory listing of the specified directory in long
format. It uses the current directory by default. It returns the result as a
list.

=cut

sub _m_dir
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->dir(@arg)
    : ();
}

=head2 S<ftpGet($nam,$rem[,$loc[,$off]])>

This macro gets the specified remote files and stores it locally. You can
specify a number of bytes to skip at the beginning of the file. It uses the
current settings for the file transfer. It returns a true value on a successful
completion.

=cut

sub _m_get
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->get(@arg)
    : undef;
}

=head2 S<ftpLogin($nam[,$usr[,$pwd[,$acc]]])>

This method performs a login to the FTP server. It returns the completion
status.

=cut

sub _m_login
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->login(@arg)
    : undef;
}

=head2 S<ftpLs($nam[,$dir])>

This macro gets a directory listing of the specified directory. It uses the
current directory by default. It returns the result as a list.

=cut

sub _m_ls
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->ls(@arg)
    : ();
}

=head2 S<ftpMkdir($nam,$dir)>

This macro creates a directory on the remote server. It returns a true value
on a successful completion.

=cut

sub _m_mkdir
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->mkdir(@arg)
    : undef;
}

=head2 S<ftpPut($nam,$loc[,$rem])>

This macro stores a local file on the remote system. By default, it derives
the remote file name from the local file name. It uses the current settings for
the file transfer. It returns the remote file name.

=cut

sub _m_put
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->put(@arg)
    : undef;
}

=head2 S<ftpPutUnique($nam,$loc[,$rem])>

This macro stores a local file on the remote system. By default, it derives
the remote file name from the local file name. It forces a unique file name on
the remote system. It uses the current settings for the file transfer. It
returns the remote file name.

=cut

sub _m_put_unique
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->put_unique(@arg)
    : undef;
}

=head2 S<ftpPwd($nam)>

This macro returns the full path name of the current working directory on the
remote system.

=cut

sub _m_pwd
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->pwd
    : undef;
}

=head2 S<ftpQuote($nam,$cmd[,$arg...])>

This macro sends a command to the remote server and waits for a response. It
returns the most significant digit of the response code. You can use this macro
only on commands that do not require data connections. A misuse of this macro
can hang the connection.

=cut

sub _m_quote
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->quote(@arg)
    : undef;
}

=head2 S<ftpRename($nam,$src,$dst)>

This macro renames the specified file on the remote server. It returns a true
value on a successful completion.

=cut

sub _m_rename
{ my ($slf, $ctx, $nam, $src, $dst) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->rename($src, $dst)
    : undef;
}

=head2 S<ftpRm($nam,$fil)>

This macro deletes the specified file on the remote server. It returns a true
value on a successful completion.

=cut

sub _m_rm
{ my ($slf, $ctx, $nam, $fil) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->rm($fil)
    : undef;
}

=head2 S<ftpRmdir($nam,$dir)>

This macro deletes the specified directory on the remote server. It does not
empty the directory before attempting to remove it. It returns a true value on
a successful completion.

=cut

sub _m_rmdir
{ my ($slf, $ctx, $nam, $dir) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->rmdir($dir)
    : undef;
}

=head2 S<ftpSite($nam,$arg,...)>

This macro sends a C<SITE> specific command to the FTP server and waits for a
response. It returns the most significant digit of the response code.

=cut


sub _m_site
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->site(@arg)
    : undef;
}

=head2 S<getFtpModTime($nam, $fil)>

This macro returns the last modification time of the specified remote file. It
returns the time as a list usable with the C<mktime> macro.

=cut

sub _m_modtime
{ my ($slf, $ctx, $nam, $fil) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->modtime($fil)
    : ();
}

=head2 S<getFtpSize($nam,$fil)>

This macro returns the size in bytes for the specified remote file.

=cut

sub _m_size
{ my ($slf, $ctx, $nam, $fil) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->size($fil)
    : undef;
}

=head2 S<setFtpAscii($nam)>

This macro sets the transfer type to network ASCII. It returns the previous
transfer type.

=cut

sub _m_ascii
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->ascii
    : undef;
}

=head2 S<setFtpBinary($nam)>

This macro sets the file transfer type to support binary image transfer. It
returns the previous transfer type.

=cut

sub _m_binary
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_ftp'}->{$nam}))
    ? $slf->{'_ftp'}->{$nam}->binary
    : undef;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Ftp|RDA::Object::Ftp>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Array|RDA::Value::Array>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
