# Ftp.pm: Class Used for Managing FTP Connections

package RDA::Object::Ftp;

# $Id: Ftp.pm,v 2.11 2012/04/27 06:00:28 mschenke Exp $
# $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Ftp.pm,v 2.11 2012/04/27 06:00:28 mschenke Exp $
#
# Change History
# 20120427  MSC  Assume UNIX ls format.

=head1 NAME

RDA::Object::Ftp - Class Used for Managing FTP Connections

=head1 SYNOPSIS

require RDA::Object::Ftp;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Ftp> class are used to manage FTP connections.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::File;
  use RDA::Object::Buffer;
  use RDA::Object::Rda qw($APPEND $CREATE $FIL_PERMS);
  use RDA::Object::Report;
  use Socket;
  use Symbol;
}

use strict;

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'abort'        => {ret => 0},
    'account'      => {ret => 0},
    'append'       => {ret => 0},
    'ascii'        => {ret => 0},
    'authorize'    => {ret => 0},
    'binary'       => {ret => 0},
    'cd'           => {ret => 0},
    'cdup'         => {ret => 0},
    'dir'          => {ret => 1},
    'get'          => {ret => 0},
    'get_code'     => {ret => 0},
    'get_info'     => {ret => 0},
    'get_length'   => {ret => 0},
    'get_message'  => {ret => 0},
    'get_response' => {ret => 0},
    'get_status'   => {ret => 0},
    'is_success'   => {ret => 0},
    'is_supported' => {ret => 0},
    'login'        => {ret => 0},
    'ls'           => {ret => 1},
    'mkdir'        => {ret => 0},
    'modtime'      => {ret => 1},
    'put'          => {ret => 0},
    'put_unique'   => {ret => 0},
    'pwd'          => {ret => 0},
    'quit'         => {ret => 0},
    'quote'        => {ret => 0},
    'rm'           => {ret => 0},
    'rmdir'        => {ret => 0},
    'rename'       => {ret => 0},
    'set_info'     => {ret => 0},
    'site'         => {ret => 0},
    'size'         => {ret => 0},
    },
  new => 1,
  pwd => 1,
  trc => 'FTP_TRACE',
  );

# Define the private constants
my $FTP_INFO    = 1;
my $FTP_OK      = 2;
my $FTP_MORE    = 3;
my $FTP_REJECT  = 4;
my $FTP_ERROR   = 5;
my $FTP_PENDING = 0;

my $TELNET_IAC = 255;
my $TELNET_IP  = 244;
my $TELNET_DM  = 242;

# Define the private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Ftp-E<gt>new($host[,...])>

The object constructor. It takes the host name, and initial attributes as
arguments.

C<RDA::Object::Ftp> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'blk' > > Block size

=item S<    B<'fwa' > > Firewall account

=item S<    B<'fwh' > > Firewall host

=item S<    B<'fwp' > > Firewall password

=item S<    B<'fwt' > > Firewall type

=item S<    B<'fwu' > > Firewall user

=item S<    B<'hst' > > Remote host

=item S<    B<'lim' > > Timeout value (in seconds)

=item S<    B<'lvl' > > Trace level

=item S<    B<'prt' > > Port

=item S<    B<'_buf'> > Last incomplete line

=item S<    B<'_cmd'> > Supported command hash

=item S<    B<'_cod'> > Last response code

=item S<    B<'_ctl'> > Data connection control structure

=item S<    B<'_ftp'> > Command socket handle

=item S<    B<'_ini'> > Indicate whether an internal listen socket is present

=item S<    B<'_lgt'> > Number of bytes saved in the last get request

=item S<    B<'_lim'> > Time limit

=item S<    B<'_lin'> > Line buffer

=item S<    B<'_lsn'> > Listen socket handle

=item S<    B<'_off'> > Transfer offset

=item S<    B<'_pwd'> > Password manager

=item S<    B<'_rsp'> > Response buffer

=item S<    B<'_typ'> > Transfer type (C<A> for ASCII, C<I> for binary)

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $hst, @arg) = @_;
  my ($adr, $ftp, $key, $lim, $slf, $val);

  # Create the root object
  $ftp = gensym;
  $slf = bless {
    blk  => 10240,
    hst  => $hst,
    lim  => 30,
    lvl  => 0,
    prt  => 21,
    _buf => '',
    _cmd => {},
    _cod => '000',
    _ftp => $ftp,
    _lgt => 0,
    _lin => [],
    _rsp => [],
    _typ => 'A',
    }, ref($cls) || $cls;

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $slf->{$key} = $val if defined($val);
  }

  # Create the socket and connect to the FTP server
  $slf->{'_lim'} = $lim = ($slf->{'lim'} > 0) ? time + $slf->{'lim'} : 0;
  $hst = $slf->{'fwh'} if exists($slf->{'fwh'});
  die "RDA-01150: Cannot resolve $hst\n"
    unless defined($adr = inet_aton($hst));
  $adr = sockaddr_in(exists($slf->{'fwh'}) ? 21 : $slf->{'prt'}, $adr);
  socket($ftp, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
    or die "RDA-01151: Socket error: $!\n";
  connect($ftp, $adr) or die "RDA-01153: Connect error: $!\n";
  die "RDA-01154: Connect timeout\n" if $lim && time > $lim;

  # Check the FTP server response
  eval {$val = $slf->_response};
  if ($@)
  { $slf->_close_connection;
    die $@;
  }
  unless ($val == $FTP_OK)
  { $slf->_close_connection;
    die "RDA-01155: Start error: ".join("\n", @{$slf->{'_rsp'}})."\n";
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method deletes an FTP connection control object.

=cut

sub delete
{ # Close the sockets
  close (delete($_[0]->{'_ctl'})->{'hnd'})
    if exists($_[0]->{'_ctl'}) && exists($_[0]->{'_ctl'}->{'hnd'});

  close(delete($_[0]->{'_lsn'}))
    if exists($_[0]->{'_lsn'});

  close (delete($_[0]->{'_ftp'}))
    if exists($_[0]->{'_ftp'});

  # Delete the object
  undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>get_code>

This method returns the last response code.

=cut

sub get_code
{ shift->{'_cod'};
}

=head2 S<$h-E<gt>get_error>

This method returns the last error.

=cut

sub get_error
{ shift->{'err'};
}

=head2 S<$h-E<gt>get_length>

This method returns the number of bytes received in the last C<get> request.

=cut

sub get_length
{ shift->{'_lgt'};
}

=head2 S<$h-E<gt>get_message>

This method returns the last response as a string.

=cut

sub get_message
{ join('', @{shift->{'_rsp'}});
}

=head2 S<$h-E<gt>get_response>

This method returns the last response as a list.

=cut

sub get_response
{ @{shift->{'_rsp'}};
}

=head2 S<$h-E<gt>get_status>

This method returns the last response status.

=cut

sub get_status
{ substr(shift->{'_cod'}, 0, 1);
}

=head2 S<$h-E<gt>is_success>

This method indicates whether the last request has an OK status.

=cut

sub is_success
{ substr(shift->{'_cod'}, 0, 1) eq $FTP_OK;
}

=head2 S<$h-E<gt>is_supported($cmd)>

This method indicates whether the specified FTP command is supported.

=cut

sub is_supported
{ my ($slf, $arg) = @_;
  my ($cmd, $hsh, $txt);

  $cmd = uc($arg);
  $hsh = $slf->{'_cmd'};
  unless (exists($hsh->{$cmd}))
  { $hsh->{$cmd} = 0;

    # Submit a help command
    return 0
      unless $slf->_request(1, 'HELP', $cmd)->_response == $FTP_OK;

    # Analyze the help output
    $txt = $slf->get_message;
    if ($txt =~ m/following\s+commands/i)
    { $txt =~ s/^.*\n//;
      while ($txt =~ m/(\*?)(\w+)(\*?)/sg)
      { $hsh->{"\U$2"} = !length("$1$3");
      }
    }
    else
    { $hsh->{$cmd} = $txt !~ m/unimplemented/i;
    }
  }
  $hsh->{$cmd};
}

=head2 S<$h-E<gt>set_authen($pwd)>

This method associates a password manager to the object.

=cut

sub set_authen
{ my ($slf, $pwd) = @_;

  $slf->{'_pwd'} = $pwd;
}

=head1 FTP COMMANDS

=head2 S<$h-E<gt>abort>

This method aborts the current data transfer. It returns a true value on a
successful completion.

=cut

sub abort
{ my ($slf) = @_;

  send($slf->{'_ftp'}, pack('CCC', $TELNET_IAC, $TELNET_IP, $TELNET_IAC),
    MSG_OOB);

  $slf->_request(1, pack('C', $TELNET_DM).'ABOR');
  close($slf->{'_ctl'}->{'hnd'}) if exists($slf->{'_ctl'});
  $slf->_response == $FTP_OK;
}

=head2 S<$h-E<gt>account>

This method supplies a supplemental password required by a remote system for
access to resources after a login has been successfully completed. It returns a
true value on a successful completion.

=cut

sub account
{ my ($slf, $act) = @_;

  $slf->_request(1, 'ACCT', $act)->_response == $FTP_OK;
}

=head2 S<$h-E<gt>append($loc[,$rem])>

This method appends a local file to a file on the remote machine. By default,
it uses the local file name in naming the remote file and the current settings
for the file transfer. It returns the remote file name.

=cut

sub append
{ shift->_store_data('APPE', @_);
}

=head2 S<$h-E<gt>ascii>

This method sets the transfer type to network ASCII. It returns the previous
transfer type.

=cut

sub ascii
{ shift->type('A');
}

sub type
{ my ($slf, $typ) = @_;
  my ($old);

  $old = $slf->{'_typ'};
  if (defined($typ))
  { return undef unless $slf->_request(1, 'TYPE', $typ)->_response == $FTP_OK;
    $slf->{'_typ'} = $typ;
  }
  $old;
}

=head2 S<$h-E<gt>binary>

This method sets the file transfer type to support binary image transfer. It
returns the previous transfer type.

=cut

sub binary
{ shift->type('I');
}

=head2 S<$h-E<gt>cd([$dir])>

This method changes the working directory on the remote system to the specified
directory or to the root directory by default. If C<$dir> is C<..>, it uses the
FTP C<CDUP> command to attempt to move up one directory. It returns a true
value on a successful completion.

=cut

sub cd
{ my ($slf, $dir) = @_;

  $dir = '/' unless defined($dir) && $dir =~ m/\S/;
  (($dir eq '..')
    ? $slf->_request(1, 'CDUP')
    : $slf->_request(1, 'CWD', $dir))->_response == $FTP_OK;
}

=head2 S<$h-E<gt>cdup>

This method changes the remote machine working directory to the parent of the
current remote machine working directory. It returns a true value on a
successful completion.

=cut

sub cdup
{ shift->_request(1, 'CDUP')->_response == $FTP_OK;
}

=head2 S<$h-E<gt>dir([$dir])>

This methods gets a directory listing of the specified directory in long
format. It uses the current directory by default. It returns the result as a
list.

=cut

sub dir
{ shift->_request_list('LIST', @_);
}

=head2 S<$h-E<gt>get($rem[,$loc[,$off]])>

This methods gets the specified remote file and stores the file locally. You
can specify a number of bytes to skip at the beginning of the file. It uses the
current settings for the file transfer. It returns a true value on a successful
completion.

=cut

sub get
{ my ($slf, $rem, $loc, $off, $cbf) = @_;
  my ($blk, $buf, $ctl, $fct, $flg, $lgt, $ofh, $ref, @arg);

  # Initialization
  $flg = $slf->{'lvl'} > 0;
  $slf->{'_lgt'} = 0;
  $slf->{'_off'} = (defined($off) && $off > 0) ? $off : 0;
  die "RDA-01173: Missing remote file\n" unless defined($rem);

  # Submit the transfer request
  return undef
    unless ($ctl = $slf->_request_data($slf->{'_typ'}, 'RETR', $rem));

  # Determine the local file
  $ref = ref($loc);
  if ($ref eq 'RDA::Object::Buffer')
  { $ofh = $loc->get_handle;
    $loc = 'buffer';
  }
  elsif ($ref eq 'RDA::Object::Report')
  { $ofh = $loc;
    $loc = 'report';
  }
  elsif ($ref)
  { die "RDA-01172: Missing or invalid local file\n";
  }
  else
  { $loc = RDA::Object::Rda->cat_file($rem) unless defined($loc);
    $ofh = IO::File->new;
    unless ($ofh->open($loc, $slf->{'_off'} ? $APPEND : $CREATE, $FIL_PERMS))
    { $slf->_abort_data($ctl);
      die "RDA-01176: Cannot open local file '$loc':\n $!\n";
    }
    if ($slf->type eq 'I' && !binmode($ofh))
    { $slf->_abort_data($ctl);
      $ofh->close unless $ref;
      die "RDA-01177: Cannot binmode local file '$loc':\n $\n";
    }
    $loc = "local file '$loc'";
  }

  # Determine the callback treatment
  if (ref($cbf) eq 'ARRAY' && ref($cbf->[0]) eq 'CODE')
  { ($cbf, @arg) = @$cbf;
    &$cbf(0, @arg);
  }
  else
  { $cbf = undef;
  }

  # Transfer the file
  $blk = $ctl->{'blk'};
  $fct = $ctl->{'fct'};
  while ($lgt = length($buf = &$fct($ctl, $blk)))
  { unless ($ofh->syswrite($buf, $lgt))
    { $slf->_abort_data($ctl);
      $ofh->close unless $ref;
      die "RDA-01178: Cannot write to $loc:\n $!\n";
    }
    $slf->{'_lgt'} += $lgt;
  }

  # Terminate the file transfer and indicate the transfer result
  die "RDA-01179: Cannot close local file '$loc':\n $!\n"
    unless $ref || $ofh->close;
  &$cbf(1, @arg) if $cbf;
  $slf->_close_data($ctl);
}

=head2 S<$h-E<gt>login([$usr[,$pwd[,$acc]]])>

This method performs a login to the FTP server. It returns the completion
status.

=cut

sub login
{ my ($slf, $usr, $pwd, $acc) = @_;
  my ($hst, $log, $sta, $typ);

  $hst = $slf->{'hst'};
  $typ = exists($slf->{'fwt'}) ? $slf->{'fwt'} : 0;

  # Specify the user name
  $log = defined($usr) ? $usr : 'anonymous';
  if ($typ == 1 || $typ == 7)
  { $log .= '@'.$hst;
  }
  elsif ($typ)
  { my ($fwp, $fwu);

    ($fwu, $fwp) = ($slf->{'fwu'}, $slf->{'fwp'});
    if ($typ == 5)
    { $log = join('@', $log, $fwu, $hst);
      $pwd = $pwd.'@'.$fwp;
    }
    elsif ($typ == 8)
    { $log = $log.'@'.$hst.' '.$fwu;
    }
    else
    { if ($typ == 2)
      { $log .= '@'.$hst;
      }
      elsif ($typ == 6)
      { $fwu .= '@'.$hst;
      }
      $sta = $slf->_request(0, 'user', $fwu)->_response;
      return 0 unless $sta == $FTP_MORE || $sta == $FTP_OK;
      $sta = $slf->_request(0, 'user', $fwp || '')->_response;
      return 0 unless $sta == $FTP_MORE || $sta == $FTP_OK;
      $sta = $slf->_request(0, 'ACCT', $slf->{'fwa'})->_response
        if exists($slf->{'fwa'});
      $sta = $slf->_request(0, 'SITE', $hst)->_response
        if $typ == 3;
      $sta = $slf->_request(0, 'OPEN', $hst)->_response
        if $typ == 4;
      return 0 unless $sta == $FTP_OK || $sta == $FTP_MORE;
    }
  }
  $sta = $slf->_request(0, 'USER', $log)->_response;
  $sta = $slf->_request(0, 'user', $log)->_response
    unless $sta == $FTP_MORE || $sta == $FTP_OK;

  # Some firewalls don't prefix the connection messages
  $sta = $slf->_response
    if $sta == $FTP_OK && $slf->{'_cod'} == 220 && $log =~ m/\@/;

  # Submit the password when requested
  $sta = $slf->_request(0, 'PASS', _authen($slf, $hst, $usr, $pwd))->_response
    if $sta == $FTP_MORE;

  # Submit the account when requested
  $sta = $slf->_request(0, 'ACCT', $acc)->_response
    if defined($acc) && ($sta == $FTP_MORE || $sta == $FTP_OK);

  # Complete login with a firewall
  $slf->authorize($slf->{'fwu'}, $slf->{'fwp'})
    if $typ == 7 && $sta == $FTP_OK && exists($slf->{'fwp'});

  # Return the last status
  $sta;
}

sub authorize
{ my ($slf, $aut, $rsp) = @_;
  my ($sta);

  $sta = $slf->_request(0, 'AUTH', $aut || '')->_response;
  $sta = $slf->_request(0, 'RESP', $rsp || '')->_response if $sta == $FTP_MORE;
  $sta == $FTP_OK;
}

sub _authen
{ my ($slf, $hst, $usr, $pwd) = @_;

  # Use the password manager when available
  return defined($pwd)
    ? $slf->{'_pwd'}->set_password('host', $hst, $usr, $pwd)
    : $slf->{'_pwd'}->get_password('host', $hst, $usr,
        "Enter password for user $usr on host $hst:", '')
    if exists($slf->{'_pwd'});

  # Check for default password
  defined($pwd) ? $pwd : '';
}

=head2 S<$h-E<gt>ls([$dir])>

This methods gets a directory listing of the specified directory. It uses the
current directory by default. It returns the result as a list.

=cut

sub ls
{ shift->_request_list('NLST', @_);
}

=head2 S<$h-E<gt>mkdir($dir)>

This methods creates a directory on the remote server. It returns a true value
on successful completion.

=cut

sub mkdir
{ my ($slf, $dir) = @_;

  die "RDA-01170: Missing directory\n" unless defined($dir);
  $slf->_request(1, 'MKD', $dir)->_response == $FTP_OK;
}

=head2 S<$h-E<gt>modtime($fil)>

This methods returns the last modification time of the specified remote file. It
returns the time as a list usable by C<timegm>.

=cut

sub modtime
{ my ($slf, $fil) = @_;

  die "RDA-01171: Missing file\n" unless defined($fil);
  $slf->_request(1, 'MDTM', $fil)->_response == $FTP_OK
    && $slf->get_message =~ m/((\d\d)(\d\d\d?))(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/
    ? ($8, $7, $6, $5, $4 - 1, ($2 eq '19') ? $3 : ($1 - 1900))
    : ();
}

=head2 S<$h-E<gt>put($loc[,$rem])>

This method stores a local file on the remote system. By default, it derives
the remote file name from the local file name. It uses the current settings for
the file transfer. It returns the remote file name.

=cut

sub put
{ shift->_store_data('STOR', @_);
}

=head2 S<$h-E<gt>put_unique($loc[,$rem])>

This method stores a local file on the remote system. By default, it derives
the remote file name from the local file name. It forces a unique file name on
the remote system. It uses the current settings for the file transfer. It
returns the remote file name.

=cut

sub put_unique
{ shift->_store_data('STOU', @_);
}

=head2 S<$h-E<gt>pwd>

This method returns the full path name of the current working directory on the
remote system.

=cut

sub pwd
{ my ($slf) = @_;
  my ($pth);

  if ($slf->_request(1, 'PWD')->_response == $FTP_OK
    && $slf->get_message =~ m/(^|\s)\"(.*)\"($|\s)/)
  { $pth = $2;
    $pth =~ s/\"\"/\"/g;
  }
  $pth;
}

=head2 S<$h-E<gt>quit>

This method sends a C<QUIT> command to the FTP server and closes the socket
connection. It returns a true value on a successful completion.

=cut

sub quit
{ my ($slf) = @_;
  my ($sta);

  $sta = $slf->_request(1, 'QUIT')->_response;
  $slf->_close_connection;
  $sta == $FTP_OK;
}

=head2 S<$h-E<gt>quote($cmd[,$arg...])>

This method sends a command to the remote server and waits for a response. It
returns the most significant digit of the response code. You can use this
method only on commands that do not require data connections. A misuse of this
method can hang the connection.

=cut

sub quote
{ my ($slf, $cmd, @arg) = @_;

  $slf->_request(1, uc($cmd), @arg)->_response;
}

=head2 S<$h-E<gt>rename($src,$dst)>

This method renames the specified file on the remote server. It returns a true
value on a successful completion.

=cut

sub rename
{ my ($slf, $src, $dst) = @_;

  die "RDA-01174: Missing rename source\n"      unless defined($src);
  die "RDA-01175: Missing rename destination\n" unless defined($dst);
  $slf->_request(1, 'RNFR', $src)->_response == $FTP_MORE
    && $slf->_request(0, 'RNTO', $dst)->_response == $FTP_OK;
}

=head2 S<$h-E<gt>rm($fil)>

This method deletes the specified file on the remote server. It returns a true
value on a successful completion.

=cut

sub rm
{ my ($slf, $fil) = @_;

  die "RDA-01171: Missing file\n" unless defined($fil);
  $slf->_request(1, 'DELE', $fil)->_response == $FTP_OK;
}

=head2 S<$h-E<gt>rmdir($dir)>

This method deletes the specified directory on the remote server. It does not
empty the directory before attempting to remove it. It returns a true value on
a successful completion.

=cut

sub rmdir
{ my ($slf, $dir) = @_;

  die "RDA-01170: Missing directory\n" unless defined($dir);
  $slf->_request(1, 'RMD', $dir)->_response == $FTP_OK;
}

=head2 S<$h-E<gt>site($arg,...)>

This method sends a C<SITE> specific command to the FTP server and waits for a
response. It returns the most significant digit of the response code.

=cut

sub site
{ shift->_request(1, 'SITE', @_)->_response;
}

=head2 S<$h-E<gt>size($fil)>

This method returns the size in bytes for the specified remote file.

=cut

sub size
{ my ($slf, $fil) = @_;
  my (@tbl);

  die "RDA-01171: Missing file\n" unless defined($fil);
  if ($slf->is_supported('SIZE'))
  { return ($slf->_request(1, 'SIZE', $fil)->_response == $FTP_OK)
      ? ($slf->get_message =~ m/(\d+)\s*(bytes?\s*)?$/)[0]
      : undef;
  }
  elsif ($slf->is_supported('STAT'))
  { return $1
      if $slf->_request(1, 'STAT', $fil)->_response == $FTP_OK
      && (@tbl = $slf->get_response) == 3
      && $tbl[1] =~ m/[-rwxSsTt]{10}\s+\d+\s+\S+\s+\S+\s*(\d+)/;
  }
  else
  { return $1
      if (@tbl = $slf->dir($fil))
      && $tbl[0] =~ m/[-rwxSsTt]{10}\s+\d+\s+\S+\s+\S+\s*(\d+)/;
  }
  undef;
}

# --- Internal communication routines -----------------------------------------

# Submit a request
sub _request { my ($slf, $flg, @arg) = @_;
  my ($buf, $ftp, $lgt, $lim, $off, $siz);

  # Abort if the connection is closed
  unless (exists($slf->{'_ftp'}))
  { $slf->{'_cod'} = '426';
    $slf->{'_rsp'} = ['Connection closed'];
    return $slf;
  }

  # Generate the command
  die "RDA-01169: Missing command\n" unless @arg;
  $buf = join(' ', @arg);
  $buf =~ tr/\n/ /;
  print "FTP> Out: $buf\n" if $slf->{'lvl'} > 0;
  $buf .= "\015\012";
  $siz = length($buf);

  # Submit the request
  local $SIG{'PIPE'} = 'IGNORE' unless $^O eq 'MacOS';

  $ftp = $slf->{'_ftp'};
  $off = 0;
  $slf->{'_lim'} = $lim = ($slf->{'lim'} > 0) ? time + $slf->{'lim'} : 0
    if $flg;

  for ($off = 0 ; $siz > 0 ; $siz -= $lgt, $off += $lgt)
  { $lgt = syswrite($ftp, $buf, $siz);
    die "RDA-01156: Request error: $!\n" unless defined($lgt);
    die "RDA-01157: Request timeout\n" if $lim && time > $lim;
  }

  # Clear any previous response and return the object reference
  $slf->{'_cod'} = '000';
  $slf->{'_rsp'} = [];
  $slf;
}

# Get the request response
sub _response
{ my ($slf) = @_;
  my ($flg, $lin);

  $flg = $slf->{'lvl'} > 0;

  # Determine the response to a request
  unless ($slf->{'_cod'} + 0)
  { for (;;)
    { # Get a response line
      return $FTP_ERROR unless defined($lin = $slf->_get_line);
      print "FTP> In: $lin\n" if $flg;

      # Evaluate the response line
      if ($lin =~ s/^(\d{3})([- ]?)//o)
      { push(@{$slf->{'_rsp'}}, $lin);
        $slf->{'_cod'} = $1;
        last unless $2 eq '-';
      }
      elsif ($slf->{'_cod'} + 0)
      { push(@{$slf->{'_rsp'}}, $lin);
      }
      else
      { unshift(@{$slf->{'_lin'}}, $lin);
        last;
      }
    }
  }

  # Indicate the completion status
  print "FTP> Code: ".$slf->{'_cod'}."\n" if $flg;
  substr($slf->{'_cod'}, 0, 1);
}

# --- Command communication methods -------------------------------------------

# Close the connection socket
sub _close_connection
{ my ($slf) = @_;
  my ($hnd);

  if (defined($hnd = delete($slf->{'_ftp'})))
  { close($hnd);
    print "FTP> Close command socket\n" if $slf->{'lvl'} > 0;
  }
  undef;
}

# Get a line from the FTP server
sub _get_line
{ my ($slf) = @_;
  my ($buf, $ftp, $lgt, $off, $sel, @buf);

  # Load new lines if the line buffer is empty
  unless (@{$slf->{'_lin'}})
  { # Read lines
    $buf = $slf->{'_buf'};
    $ftp = $slf->{'_ftp'};
    $off = length($buf);
    $sel = {msk => ''};
    vec($sel->{'msk'}, fileno($ftp), 1) = 1;
    $sel->{'exm'} = $sel->{'msk'};

    while ($buf !~ m/\015?\012/)
    { die "RDA-01160: Response timeout\n"
        unless _can_read($sel, $slf->{'_lim'});

      unless (defined($lgt = sysread($ftp, $buf, 1024, $off)))
      { $slf->{'_cod'} = 421;
        push(@{$slf->{'_rsp'}},
          'Service not available, closing control connection');
        return $slf->_close_connection
      }
      last unless $lgt;
      $off += $lgt;
    }

    # Break into lines
    @buf = split(/\015?\012/, $buf, -1);
    $slf->{'_buf'} = pop(@buf);
    push(@{$slf->{'_lin'}}, @buf);
  }

  # Return the first line from the buffer
  shift(@{$slf->{'_lin'}});
}


# Define a listen port
sub _port
{ my ($slf, $prt) = @_;
  my ($lim);

  delete($slf->{'_ini'});

  # Create a listen socket when no port is specified
  unless (defined($prt))
  { my ($adr, $cmd, $lsn, @tbl);

    if (exists($slf->{'_lsn'}))
    { $lsn = $slf->{'_lsn'};
    }
    elsif (exists($slf->{'_ftp'}))
    { # Create a listen socket at same address as the command socket
      $slf->{'_lsn'} = $lsn = gensym;
      $cmd = $slf->{'_ftp'};

      $lim = ($slf->{'lim'} > 0) ? time + $slf->{'lim'} : 0;
      die "RDA-01151: Socket error: $!\n"
        unless socket($lsn, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
      (undef, $adr) = sockaddr_in(getsockname($cmd));
      die "RDA-01152: Bind error: $!\n"
        unless bind($lsn, sockaddr_in(0, $adr));
      die "RDA-01161: Listen error: $!\n"
        unless listen($lsn, 5);
      if ($lim && time > $lim)
      { close($lsn);
        die "RDA-01162: Listen timeout\n";
      }
    }
    else
    { $slf->{'_cod'} = '426';
      $slf->{'_rsp'} = ['Connection closed'];
      return undef
    }

    @tbl = sockaddr_in(getsockname($lsn));
    $prt = $tbl[0];
    @tbl = split(/\./, $adr = inet_ntoa($tbl[1]));
    print "FTP> Start listen socket for $adr on port $prt\n"
      if $slf->{'lvl'} > 0;
    $prt = join(',', @tbl, $prt >> 8, $prt & 0xff);

    $slf->{'_ini'} = 1;
  }

  # Communicate the connection details to the FTP server
  $slf->_request(0, 'PORT', $prt)->_response == $FTP_OK;
}

# --- Data Communication methods ----------------------------------------------

# Abort the data transfer
sub _abort_data
{ my ($slf, $ctl) = @_;

  print "FTP> Abort data transfer\n" if $ctl->{'trc'};

  # No need to abort when the transfer is already complete
  return $slf->_close_data($ctl) if $ctl->{'eof'};

  # Read at least a byte to prevent that the FTP server closes the connection
  if (exists($ctl->{'byt'}) && $ctl->{'byt'} == 0
    && _can_read($ctl->{'sel'}, $ctl->{'tim'}))
  { my $buf = '';
    sysread($ctl->{'hnd'}, $buf, 1);
  }
  $ctl->{'eof'} = 1;

  # Abort the command
  $slf->abort;
}

# Check if bytes are available
sub _can_read
{ my ($sel, $lim) = @_;
  my ($exm, $msk, $ret, $tim);

  unless ($lim && ($tim = $lim - time) <= 0)
  { $ret = select($msk = $sel->{'msk'}, undef, $exm = $sel->{'exm'}, $tim);
    die "RDA-01163: Receive error: $!\n" unless $msk;
  }
  $ret;
}

# Check if bytes can be sent
sub _can_write
{ my ($sel, $lim) = @_;
  my ($exm, $msk, $ret, $tim);

  unless ($lim && ($tim = $lim - time) <= 0)
  { $ret = select(undef, $msk = $sel->{'msk'}, $exm = $sel->{'exm'}, $tim);
    die "RDA-01158: Send error: $!\n" unless $msk;
  }
  $ret;
}

# Close the data connection and get the command response
sub _close_data
{ my ($slf, $ctl) = @_;

  # Delete the data control structure
  if (exists($ctl->{'byt'}) && !$ctl->{'eof'})
  { &{$ctl->{'fct'}}($ctl, 1, 0);
    return $slf->_abort_data($ctl) unless $ctl->{'eof'};
  }
  print "FTP> Close data transfer socket\n" if $ctl->{'trc'};
  close($ctl->{'hnd'});
  undef %$ctl;
  delete($slf->{'_ctl'});

  # Get the command response
  $slf->{'_cod'} = '000';
  $slf->_response == $FTP_OK;
}

# Format data in network ASCII
sub _format_ascii
{ my ($ctl, $buf) = @_;

  $buf =~ s/([^\015])(\012+)/$1.("\015\012" x length($2))/esg
    if $buf =~ tr/\r\n/\015\012/;
  $buf =~ s/^\012/\015\012/ unless $ctl->{'nxt'};
  $ctl->{'nxt'} = substr($buf, -1) eq "\015";
  $buf;
}

# Format binary data
sub _format_binary
{ my ($ctl, $buf) = @_;

  $buf;
}

# Initialize a data connection
sub _init_data
{ my ($slf, $typ) = @_;
  my ($flg, $hnd, $lsn, $sel, $src);

  # Delete a previous data transfer control structure
  delete($slf->{'_ctl'});

  # Get a transfer socket
  $flg = $slf->{'lvl'} > 0;
  $hnd = gensym;
  $lsn = delete($slf->{'_lsn'});
  $src = accept($hnd, $lsn);
  close($lsn);
  print "FTP> Close listen socket\n" if $flg;
  if ($flg)
  { my ($prt, $adr) = sockaddr_in($src);
    $adr = inet_ntoa($adr);
    print "FTP> Transfer from $adr on port $prt\n" if $flg;
  }
  return undef unless $src;

  # Determine the select masks
  $sel = {msk => ''};
  vec($sel->{'msk'}, fileno($hnd), 1) = 1;
  $sel->{'exm'} = $sel->{'msk'};

  # Create and return a new data transfer control structure
  $slf->{'_ctl'} = {
    blk => $slf->{'blk'},
    buf => '',
    eof => 0,
    fct => ($typ eq 'A') ? \&_read_ascii   : \&_read_binary,
    fmt => ($typ eq 'A') ? \&_format_ascii : \&_format_binary,
    hnd => $hnd,
    lim => $slf->{'_lim'},
    nxt => '',
    sel => $sel,
    trc => $flg,
    };
}

# Read data in network ASCII
sub _read_ascii
{ my ($ctl, $siz, $lim) = @_;
  my ($blk, $buf, $lgt, $off);

  $lim = $ctl->{'lim'} unless defined($lim);

  # Fill the buffer when needed
  $off = length($ctl->{'buf'});
  if ($off < $siz && !$ctl->{'eof'})
  { # Determine the block size
    $blk = $ctl->{'blk'};
    $blk = $siz if $siz > $blk;

    # Read data
    for (;;)
    { die "RDA-01164: Receive timeout\n"
        unless _can_read($ctl->{'sel'}, $lim);

      $buf = $ctl->{'nxt'};
      if ($lgt = sysread($ctl->{'hnd'}, $buf, $blk, length($buf)))
      { $ctl->{'nxt'} = substr($buf, -1) eq "\015" ? chop($buf) : '';
      }
      else
      { print "FTP> End of data transfer\n" if $ctl->{'trc'};
        return undef unless defined($lgt);
        $ctl->{'eof'} = 1;
        return '' unless $off;
        last;
      }
      $buf =~ s/\015\012/\n/sgo;
      $ctl->{'buf'} .= $buf;

      # Repeat if only read an incomplete end of line
      last if length($ctl->{'buf'});
    }
  }

  # Extract requested data from the data buffer
  $lgt = length($buf = substr($ctl->{'buf'}, 0, $siz));
  substr($ctl->{'buf'}, 0, $lgt) = '';
  $ctl->{'byt'} += $lgt;
  print "FTP> ".$ctl->{'byt'}." bytes read\n" if $ctl->{'trc'};
  $buf;
}

# Read binary data
sub _read_binary
{ my ($ctl, $siz, $lim) = @_;
  my ($blk, $buf, $lgt, $off);

  $lim = $ctl->{'lim'} unless defined($lim);

  # Fill the buffer when needed
  $off = length($ctl->{'buf'});
  if ($off < $siz && !$ctl->{'eof'})
  { die "RDA-01164: Receive timeout\n"
      unless _can_read($ctl->{'sel'}, $lim);

    # Determine the block size
    $blk = $ctl->{'blk'};
    $blk = $siz if $siz > $blk;

    # Read data
    unless ($lgt = sysread($ctl->{'hnd'}, $ctl->{'buf'}, $blk, $off))
    { print "FTP> End of data transfer\n" if $ctl->{'trc'};
      return undef unless defined($lgt);
      $ctl->{'eof'} = 1;
      return '' unless $off;
    }
  }

  # Extract requested data from the data buffer
  $lgt = length($buf = substr($ctl->{'buf'}, 0, $siz));
  substr($ctl->{'buf'}, 0, $lgt) = '';
  $ctl->{'byt'} += $lgt;
  print "FTP> ".$ctl->{'byt'}." bytes read\n" if $ctl->{'trc'};
  $buf;
}

# Submit a data request
sub _request_data
{ my ($slf, $typ, $cmd, @arg) = @_;
  my ($ctl, $flg, $off, $sta);

  # Define the data transfer port
  $slf->{'_lim'} = ($slf->{'lim'} > 0) ? time + $slf->{'lim'} : 0;
  return undef unless $slf->_port;

  # Skip first bytes
  if ($off = delete($slf->{'_off'}))
  { return undef
      unless $slf->_request(0, 'REST', $off)->_response == $FTP_MORE;
  }

  # Submit the request
  $flg = $slf->_request(0, $cmd, @arg)->_response == $FTP_INFO;

  # Initialize the data transfer
  if (exists($slf->{'_ini'}))
  { if ($flg)
    { $ctl = $slf->_init_data($typ);
      $ctl->{'byt'} = 0
        if $ctl && $cmd =~ m/LIST|NLST|RETR/;
      return $ctl;
    }

    # Abort the data transfer
    print "FTP> Close listen socket\n" if $slf->{'lvl'} > 0;
    close(delete($slf->{'_lsn'}));
  }
  undef;
}

# Submit a data request and return a line list
sub _request_list
{ my ($slf, $cmd, @arg) = @_;
  my ($blk, $buf, $ctl, $fct, $str);

  # Submit the data request
  return () unless defined($ctl = $slf->_request_data('A', $cmd, @arg));

  # Transfer the data
  $blk = $ctl->{'blk'};
  $fct = $ctl->{'fct'};
  $buf = '';
  $buf .= $str while length($str = &$fct($ctl, $blk));

  # Close the data transfer
  $slf->_close_data($ctl);

  # Return the data lines
  split(/\n/, $buf);
}

sub _store_data
{ my ($slf, $cmd, $loc, $rem) = @_;
  my ($blk, $buf, $ctl, $flg, $fmt, $ifh, $ref, $siz, $tot);

  $flg = $slf->{'lvl'} > 0;
  $slf->{'_lim'} = ($slf->{'lim'} > 0) ? time + $slf->{'lim'} : 0;

  # Allocate the reading from a file
  $siz = do {local $^W; -f $loc && -s _ };
  $slf->_request(0, 'ALLO', $siz)->_response if $siz;

  # Open the local file
  $ref = ref($loc);
  if ($ref eq 'RDA::Object::Buffer')
  { $ifh = $loc->get_handle;
    die "RDA-01173: Missing remote file\n" unless defined($rem);
  }
  elsif ($ref)
  { die "RDA-01172: Missing or invalid local file\n";
  }
  else
  { die "RDA-01172: Missing or invalid local file\n" unless defined($loc);
    $rem = basename($loc) unless defined($rem);
    $ifh = IO::File->new;
    die "RDA-01176: Cannot open local file '$loc':\n $!\n"
      unless $ifh->open('<'.$loc);
    die "RDA-01177: Cannot binmode local file '$loc':\n $!\n"
      if $slf->{'_typ'} eq 'I' && !binmode($ifh);
  }

  # Initialize the data transfer socket
  return undef
    unless defined($ctl = $slf->_request_data($slf->{'_typ'}, $cmd, $rem));
  $rem = $1
    if $cmd eq 'STOU'
    && $slf->get_message =~ m/FILE:\s*(.*)/;

  # Transfer the file
  $blk = $ctl->{'blk'};
  $buf = '';
  $fmt = $ctl->{'fmt'};
  $tot = 0;
  while ($siz = $ifh->sysread($buf, $blk))
  { if (_write_data($ctl, &$fmt($ctl, $buf)))
    { print "FTP> 'Transfer interrupted\n" if $flg;
      $ifh->close unless $ref;
      $slf->_abort_data($ctl);
      return undef;
    }
    $tot += $siz;
    print "FTP> $tot bytes stored\n" if $flg;
  }

  # Close the file and the data transfer socket
  $ifh->close unless $ref;
  return undef unless $slf->_close_data($ctl);

  # Return the remote name
  ($cmd eq 'STOU'
    && $slf->get_message =~ m/unique\s+file\s*name\s*:\s*(.*)\)|"(.*)"/)
    ? basename($+)
    : $rem;
}

# Write data
sub _write_data
{ my ($ctl, $buf) = @_;
  my ($blk, $hnd, $lgt, $off, $siz);

  # Disable signal
  local $SIG{'PIPE'} = 'IGNORE'
    unless ($SIG{'PIPE'} || '') eq 'IGNORE' or $^O eq 'MacOS';

  # Write the buffer
  $blk = $ctl->{'blk'};
  $hnd = $ctl->{'hnd'};
  $off = 0;
  $siz = length($buf);
  while ($siz > 0)
  { die "RDA-01159: Send timeout\n"
      unless _can_write($ctl->{'sel'}, $ctl->{'lim'});

    $lgt = syswrite($hnd, $buf, ($siz > $blk) ? $blk : $siz, $off);
    last unless defined($lgt);
    $siz -= $lgt;
    $off += $lgt;
  }
  $siz;
}

=head1 FIREWALL TYPES

Firewall types are defined by analogy to C<Net::Config>.

=over 4

=item 0

There is no firewall

=item 1

 USER usr@hst
 PASS pwd

=item 2

 USER fwu
 PASS fwp
 USER usr@hst
 PASS pwd

=item 3

 USER fwu
 PASS fwp
 SITE hst
 USER usr
 PASS pwd

=item 4

 USER fwu
 PASS fwp
 OPEN hst
 USER usr
 PASS pwd

=item 5

 USER usr@fwu@hst
 PASS pwd@fwp

=item 6

 USER fwu@hst
 PASS fwp
 USER usr
 PASS pwd

=item 7

 USER usr@hst
 PASS pwd
 AUTH fwu
 RESP fwp

=item 8

 USER usr@hst fwu
 PASS pwd
 ACCT fwp

=back

=cut

# --- FTP Commands ------------------------------------------------------------
# account [passwd]
# append local-file [remote-file]
# ascii
# bell
# binary
# bye
# case
# cd remote-directory
# cdup
# chmod mode file-name
# close
# cr
# delete remote-file
# debug [debug-value]
# dir [remote-directory] [local-file]
# disconnect
# form format
# get remote-file [local-file]
# glob
# hash [size]
# help [command]
# idle [seconds]
# lcd [directory]
# ls [remote-directory] [local-file]
# macdef macro-name
# mdelete [remote-files]
# mdir remote-files local-file
# mget remote-files
# mkdir directory-name
# mls remote-files local-file
# mode [mode-name]
# modtime file-name
# mput local-files
# newer file-name
# nlist [remote-directory] [local-file]
# nmap [inpattern outpattern]
# ntrans [inchars [outchars]]
# open host [port]
# passive
# prompt
# proxy ftp-command
# put local-file [remote-file]
# pwd
# quit
# quote arg1 arg2 ...
# recv remote-file [local-file]
# reget remote-file [local-file]
# remotehelp [command-name]
# remotestatus [file-name]
# rename [from] [to]
# reset
# restart marker
# rmdir directory-name
# runique
# send local-file [remote-file]
# sendport
# site arg1 arg2 ...
# size file-name
# status
# struct [struct-name]
# sunique
# system
# tenex
# trace
# type [type-name]
# umask [newmask]
# user user-name [password] [account]
# verbose
# -----------------------------------------------------------------------------

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Report|RDA::Object::Report>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
