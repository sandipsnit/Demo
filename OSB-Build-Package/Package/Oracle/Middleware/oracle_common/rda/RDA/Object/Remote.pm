# Remote.pm: Class Used for Managing Remote Requests

package RDA::Object::Remote;

# $Id: Remote.pm,v 1.19 2012/08/07 06:49:55 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Remote.pm,v 1.19 2012/08/07 06:49:55 mschenke Exp $
#
# Change History
# 20120807  MSC  Improve error message.

=head1 NAME

RDA::Object::Remote - Class Used for Managing Remote Requests

=head1 SYNOPSIS

require RDA::Object::Remote;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Remote> class are used for managing remote
requests.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::Handle;
  use IO::File;
  use RDA::Object::Buffer;
  use RDA::Object::Java;
  use RDA::Object::Rda qw($APPEND $FIL_PERMS);
  use RDA::Object::Sgml;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @DELETE @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);
@DELETE  = qw(_drv _mgr _ses);
@DUMP    = (
  hsh => {'RDA::Object::Remote' => 1,
          'RDA::Driver::Da'     => 1,
          'RDA::Driver::Jsch'   => 1,
          'RDA::Driver::Ssh'    => 1,
         },
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'addLocalSession'   => ['$[REM]', 'add_local'],
    'addRemoteSession'  => ['$[REM]', 'add_remote'],
    'clearRemoteBuffer' => ['$[REM]', 'clear_buffer'],
    'clearRemoteGroup'  => ['$[REM]', 'clear_group'],
    'endRemoteSession'  => ['$[REM]', 'end_session'],
    'getRemoteBuffer'   => ['$[REM]', 'get_buffer'],
    'getRemoteGroup'    => ['$[REM]', 'get_group'],
    'getRemoteSession'  => ['$[REM]', 'get_session'],
    'getRemoteTimeout'  => ['$[REM]', 'get_timeout'],
    'setRemoteTimeout'  => ['$[REM]', 'set_timeout'],
    'setRemoteTrace'    => ['$[REM]', 'set_trace'],
    'writeRemoteResult' => ['$[REM]', 'write_result'],
    },
  beg => \&_begin_remote,
  dep => [qw(RDA::Object::Java)],
  end => \&_end_remote,
  glb => ['$[REM]'],
  inc => [qw(RDA::Object)],
  met => {
    'add_local'     => {ret => 0},
    'add_remote'    => {ret => 0},
    'can_use'       => {ret => 0},
    'clear_buffer'  => {ret => 0},
    'clear_group'   => {ret => 0},
    'collect'       => {ret => 0},
    'command'       => {ret => 0},
    'end_session'   => {ret => 0},
    'execute'       => {ret => 0},
    'get'           => {ret => 0},
    'get_api'       => {ret => 0},
    'get_buffer'    => {ret => 0},
    'get_group'     => {ret => 1},
    'get_lines'     => {ret => 1},
    'get_session'   => {ret => 0},
    'get_message'   => {ret => 0},
    'get_session'   => {ret => 0},
    'get_timeout'   => {ret => 0},
    'get_type'      => {ret => 0},
    'login'         => {ret => 0},
    'logout'        => {ret => 0},
    'mget'          => {ret => 0},
    'mput'          => {ret => 0},
    'need_password' => {ret => 0},
    'need_pause'    => {ret => 0},
    'put'           => {ret => 0},
    'request'       => {ret => 0, blk => 1},
    'set_agent'     => {ret => 0},
    'set_default'   => {ret => 0},
    'set_timeout'   => {ret => 0},
    'set_trace'     => {ret => 0},
    'set_type'      => {ret => 0},
    'write_result'  => {ret => 0, blk => 1},
    },
  );

# Define the global private constants
my $OUT = qr#timeout#;
my $TOP = "[[#Top][Back to top]]\n";
my $WRK = 'remote.tmp';

my $TEST_BEG_PAT = '1 if ($slf->{"_buf"} =~ ';
my $TEST_END_PAT = ')';

# Define the global private variables
my @tb_dft = qw(da jsch ssh);
my %tb_cap = (
  da   => ['RDA::Driver::Da',   'NO_DA'],
  jsch => ['RDA::Driver::Jsch', 'NO_JSCH'],
  ssh  => ['RDA::Driver::Ssh',  'NO_SSH'],
  rsh  => ['RDA::Driver::Rsh',  'NO_RSH'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Remote-E<gt>new($agent)>

The remote access manager object constructor. It takes the package object
reference as arguments.

=head2 S<$h-E<gt>new($package)>

The remote session manager object constructor. It takes the package object
reference as arguments.

C<RDA::Object::Remote> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object (M,T)

=item S<    B<'lim' > > Execution time limit (in sec) (L,M,S)

=item S<    B<'lvl' > > Trace level (L,M,S,T)

=item S<    B<'msg' > > Last message (L,S)

=item S<    B<'oid' > > Object identifier (L,M,S,T)

=item S<    B<'out' > > Timeout indicator (L,S)

=item S<    B<'par' > > Reference to the session manager object (M)

=item S<    B<'pkg' > > Reference to the package object (M)

=item S<    B<'skp' > > Skip indicator (L,S)

=item S<    B<'_buf'> > Buffer hash (M)

=item S<    B<'_drv'> > Reference to the driver object (L,S)

=item S<    B<'_err'> > Number of remote requests in error (L,M,S)

=item S<    B<'_hst'> > Host (C<localhost> by default) (L,S)

=item S<    B<'_mgr'> > Driver manager hash (T)

=item S<    B<'_out'> > Number of remote requests timed out (L,M,S)

=item S<    B<'_pre'> > Trace prefix (L,S)

=item S<    B<'_pwd'> > Reference to the access control object (M)

=item S<    B<'_req'> > Number of remote requests (L,M,S)

=item S<    B<'_seq'> > Session sequencer (M)

=item S<    B<'_ses'> > Remote session hash (M)

=item S<    B<'_skp'> > Number of remote requests skipped (L,M,S)

=item S<    B<'_ssh'> > Authentication agent indicator (T)

=item S<    B<'_shl'> > Remote shell (C</bin/sh> by default) (L,S)

=item S<    B<'_typ'> > Object type (L,M,S,T)

=item S<    B<'_usr'> > Login user (L,M,S,T)

=item S<    B<'_var'> > Variable group hash (M)

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $arg) = @_;
  my ($agt, $slf, $val);

  # Create the object
  if (ref($cls))
  { # Create the remote session manager object
    $agt = $cls->{'agt'};
    $slf = bless {
      agt  => $agt,
      lim  => _chk_alarm($agt->get_setting('REMOTE_TIMEOUT', 30)),
      lvl  => $cls->{'lvl'},
      oid  => 'REM/'.$arg->get_oid,
      par  => $cls,
      pkg  => $arg,
      _buf => {},
      _err => 0,
      _out => 0,
      _req => 0,
      _seq => 0,
      _ses => {},
      _skp => 0,
      _typ => 'M',
      _usr => $cls->{'_usr'},
      _var => {},
      }, ref($cls);
  }
  else
  { # Create the remote access control object
    $slf = bless {
      agt  => $arg,
      lvl  => $arg->get_setting('REMOTE_TRACE', 0),
      oid  => 'REM',
      _mgr => {},
      _ssh => $arg->get_setting('NO_SSH_AGENT', 0) ? 0 : -1,
      _typ => 'T',
      _usr => $arg->get_setting('REMOTE_USER', ''),
      }, $cls;
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method terminates the remote operations.

=cut

sub delete
{ # Prepare the object deletion
  if ($_[0]->{'_typ'} eq 'M')
  { my ($use);

    # Close open sessions
    $_[0]->end_session;

    # Get the statistics record
    $use = $_[0]->{'agt'}->get_usage;
    $use->{'REM'} = {err => 0, not => '', out => 0, req => 0, skp => 0}
      unless exists($use->{'REM'});
    $use = $use->{'REM'};

    # Generate the module statistics
    $use->{'err'} += $_[0]->{'_err'};
    $use->{'out'} += $_[0]->{'_out'};
    $use->{'req'} += $_[0]->{'_req'};
    $use->{'skp'} += $_[0]->{'_skp'};
  }
  elsif ($_[0]->{'_typ'} eq 'T')
  { # Kill the authentication agent
    if ($_[0]->{'_ssh'} > 0)
    { `ssh-agent -k`;
      $_[0]->{'_ssh'} = 0;
    }
  }

  # Delete the object
  $_[0]->SUPER::delete;
}

=head1 REMOTE SESSION MANAGER METHODS

=head2 S<$h-E<gt>add_local($oid)>

This method adds a new local session.

=cut

sub add_local
{ my ($slf, $oid) = @_;
  my ($agt, $obj);

  # Validate the identifier
  $oid = $slf->get_unique($oid);

  # Clear any previous entry
  $slf->end_session($oid) if exists($slf->{'_ses'}->{$oid});

  # Define the session object
  $agt = $slf->{'agt'};
  $obj = bless {
    lim  => $slf->{'lim'},
    lvl  => $slf->{'lvl'},
    oid  => $oid,
    out  => 0,
    par  => $slf,
    skp  => 0,
    _err => 0,
    _hst => 'localhost',
    _out => 0,
    _pre => "LOC($oid)",
    _usr => $slf->{'_usr'},
    _req => 0,
    _shl => $agt->get_setting('REMOTE_SHELL', '/bin/sh'),
    _skp => 0,
    _typ => 'L',
    }, __PACKAGE__;

  # Add the driver
  $obj->{'_drv'} = _get_local($slf)->new($obj);

  # Return the session object reference
  $slf->{'_ses'}->{$oid} = $obj;
}

=head2 S<$h-E<gt>add_remote($oid[,$host[,$user[,$password]]])>

This method adds a new remote session.

=cut

sub add_remote
{ my ($slf, $oid, $hst, $usr, $pwd) = @_;
  my ($agt, $obj);

  # Validate the identifier
  $oid = $slf->get_unique($oid);

  # Clear any previous entry
  $slf->end_session($oid) if exists($slf->{'_ses'}->{$oid});

  # Define the session object
  $agt = $slf->{'agt'};
  $hst = $agt->get_setting("REMOTE_$oid\_HOSTNAME", 'localhost')
    unless defined($hst);
  $obj = bless {
    lim  => $slf->{'lim'},
    lvl  => $slf->{'lvl'},
    oid  => $oid,
    out  => 0,
    par  => $slf,
    skp  => 0,
    _err => 0,
    _hst => $hst,
    _out => 0,
    _pre => "REM($oid)",
    _req => 0,
    _shl => $agt->get_setting('REMOTE_SHELL', '/bin/sh'),
    _skp => 0,
    _typ => 'S',
    }, __PACKAGE__;

  # Manage the credentials
  if (defined($usr))
  { $obj->{'_usr'} = $usr;
    $slf->{'pkg'}->get_access->set_password('host', $hst, $usr, $pwd)
      if defined($pwd);
  }
  elsif (defined($usr = $agt->get_setting("REMOTE_$oid\_USER")))
  { $obj->{'_usr'} = $usr;
  }
  else
  { $obj->{'_usr'} = $slf->{'_usr'};
  }

  # Return the session object reference
  $slf->{'_ses'}->{$oid} = $obj;
}

=head2 S<$h-E<gt>can_use($type)>

This method indicates whether RDA can use the specified type.

=cut

sub can_use
{ my ($slf, $typ) = @_;

  defined(shift->_get_manager($typ));
}

=head2 S<$h-E<gt>clear_buffer([$name,...])>

This method deletes the specified capture buffers. The capture buffer names are
not case sensitive. It deletes all capture buffers when called without
arguments.

=cut

sub clear_buffer
{ my ($slf, @arg) = @_;

  if (exists($slf->{'_buf'}))
  { if (@arg)
    { foreach my $nam (@arg)
      { delete($slf->{'_buf'}->{lc($nam)}) if defined($nam);
      }
    }
    else
    { $slf->{'_buf'} = {};
    }
  }
  0;
}

=head2 S<$h-E<gt>clear_group([$name,...])>

This method deletes the specified variable groups. The variable group names are
not case sensitive. It deletes all variable groups when called without
arguments.

=cut

sub clear_group
{ my ($slf, @arg) = @_;

  if (exists($slf->{'_var'}))
  { if (@arg)
    { foreach my $nam (@arg)
      { delete($slf->{'_var'}->{uc($nam)}) if defined($nam);
      }
    }
    else
    { $slf->{'_var'} = {};
    }
  }
  0;
}

=head2 S<$h-E<gt>end_session([$session...])>

This method ends the corresponding sessions. You can specify a session by its
object reference or its object identifier. When no sessions are specified, it
ends all sessions.

It returns the number of deleted sessions.

=cut

sub end_session
{ my ($slf, @arg) = @_;
  my ($cnt, $obj, $oid, $tbl);

  $cnt = 0;
  if (exists($slf->{'_ses'}))
  { $tbl = $slf->{'_ses'};
    if (@arg)
    { foreach my $arg (@arg)
      { $oid = ref($arg) ? $arg->get_oid : uc($arg);
        next unless defined($oid) && ($obj = delete($tbl->{$oid}));
        $slf->{'_err'} += $obj->{'_err'};
        $slf->{'_out'} += $obj->{'_out'};
        $slf->{'_req'} += $obj->{'_req'};
        $slf->{'_skp'} += $obj->{'_skp'};
        $obj->delete;
        ++$cnt;
      }
    }
    else
    { foreach my $oid (keys(%$tbl))
      { $obj = delete($tbl->{$oid});
        $slf->{'_err'} += $obj->{'_err'};
        $slf->{'_out'} += $obj->{'_out'};
        $slf->{'_req'} += $obj->{'_req'};
        $slf->{'_skp'} += $obj->{'_skp'};
        $obj->delete;
        ++$cnt;
      }
    }
  }
  $cnt;
}

=head2 S<$h-E<gt>get_buffer([$name[,$flag]])>

This method returns the specified capture buffer or undefined value when the
name is undefined. The capture buffer names are not case sensitive. Unless the
flag is set, it assumes Wiki data.

=cut

sub get_buffer
{ my ($slf, $nam, $flg) = @_;

  defined($nam)
    && exists($slf->{'_buf'}) && exists($slf->{'_buf'}->{$nam = lc($nam)})
    ? RDA::Object::Buffer->new($flg ? 'L' : 'l', $slf->{'_buf'}->{$nam})
    : undef;
}

=head2 S<$h-E<gt>get_group($name)>

This method returns the specified variable group as a list. The variable group
names are not case sensitive.

=cut

sub get_group
{ my ($slf, $nam) = @_;

  return () unless defined($nam)
    && exists($slf->{'_var'}) && exists($slf->{'_var'}->{$nam = uc($nam)});
  (%{$slf->{'_var'}->{$nam}});
}

=head2 S<$h-E<gt>get_session($oid[,$flag])>

This method returns a reference to the corresponding session. When the flag is
set, it created missing session automatically. It returns an undefined value
when the session does not exist.

=cut

sub get_session
{ my ($slf, $oid, $flg) = @_;

  !defined($oid)                            ? undef :
  !exists($slf->{'_ses'})                   ? undef :
  exists($slf->{'_ses'}->{$oid = uc($oid)}) ? $slf->{'_ses'}->{$oid} :
  $flg                                      ? $slf->add_remote($oid) :
                                              undef;
}

=head2 S<$h-E<gt>get_timeout>

This method returns the current duration of the timeout for executing remote
commands. When this mechanism is disabled, it returns 0.

=head2 S<$h-E<gt>get_unique($oid)>

This method replaces the C<$$> string in the session identifier by a sequence
number. It takes care that the resulting identifer is not currently used.

=cut

sub get_unique
{ my ($slf, $oid) = @_;
  my ($pat, $seq, $uid);

  # Detect a variable identifier
  die "RDA-01501: Requires a session manager object\n"
    unless $slf->{'_typ'} eq 'M';
  die "RDA-01503: Missing session identifier\n"
    unless defined($oid);
  $pat = uc($oid);
  die "RDA-01504: Invalid session identifier '$pat'\n"
    unless $pat =~ m/^[A-Z][A-Z\d]*(\$\$)?$/;
  return $pat unless $1;

  # Make it unique
  do
  { $uid = $pat;
    $seq = ++$slf->{'_seq'};
    $uid =~ s/\$\$/$seq/;
  } while exists($slf->{'_ses'}->{$uid});
  $uid;
}

=head2 S<$h-E<gt>reset>

This method resets the object for its new environment to allow a thread-save
execution.

=cut

sub reset
{ my ($slf) = @_;

  $slf->{'_ses'} = {} if exists($slf->{'_ses'});
}

=head2 S<$h-E<gt>set_agent>

This method forces the initialization of the authentication agent. It returns
the authentication agent status.

=cut

sub set_agent
{ my ($slf) = @_;
  my ($key, $val);
 
  $slf = $slf->get_top;
  return $slf->{'_ssh'} if $slf->{'_ssh'};

  # Check if an authentication agent must be started
  return $slf->{'_ssh'} = -1
    if $slf->{'agt'}->get_setting('NO_SSH_AGENT')
    || exists($ENV{'SSH_AUTH_SOCK'})
    || exists($ENV{'SSH_AGENT_PID'});

  # Create an authentication agent
  foreach my $lin (`ssh-agent -s 2>/dev/null`)
  { next unless $lin =~ m/ export /;
    ($key, $val) = split(/[=;]/, $lin, 3);
    $ENV{$key} = $val;
  }
  return $slf->{'_ssh'} = -1 if $?;

  # Add RSA or DSA identities to the authentication agent
  `ssh-add 2>/dev/null`;
  $slf->{'_ssh'} = 1;
}

=head2 S<$h-E<gt>set_timeout($limit)>

This method sets the timeout for the session, specified in seconds, only if the
value is strictly positive. Otherwise, it disables the timeout mechanism. It is
disabled also if the C<alarm> function is not implemented.

It returns the effective value.

=head2 S<$h-E<gt>set_trace([$level])>

This method sets the remote trace level:

=over 7

=item B<    0 > Disables the remote trace.

=item B<    1 > Traces the remote command execution.

=back

The level is unchanged if the new level is not defined.

It returns the previous level.

=head1 REMOTE SESSION METHODS

=head2 S<$h-E<gt>collect($report,$command)>

This method sends the specified command and includes in the report the
characters sent back by the command.

=head2 S<$h-E<gt>collect($report,$definition)>

To alter temporarily some object attributes, you can specify an hash reference
as the argument. It supports following keys:

=over 11

=item S<    B<'ack'> > Acknowledge string (a line feed by default)

=item S<    B<'cln'> > Line cleanup indicator (true by default)

=item S<    B<'cmd'> > Command to execute

=item S<    B<'lim'> > Execution time limit

=item S<    B<'max'> > Maximum command execution time (30 seconds by default)

=item S<    B<'nxt'> > Continuation pattern(s)

=item S<    B<'pat'> > Prompt pattern

=item S<    B<'skp'> > Skip mode

=back

=cut

sub collect
{ my ($slf, $rpt, $def) = @_;
  my ($drv, $ref, $val, %var);

  delete($slf->{'msg'});
  $slf->{'out'} = 0;
  ++$slf->{'_req'};

  # Abort when no driver is available
  unless ($drv = _get_driver($slf, 1))
  { ++$slf->{'_err'};
    return -1;
  }

  # Analyze the request
  $var{'COL'} = $rpt;
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = $slf->{'lim'} if $slf->{'lim'};
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'TMP'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  $ref = ref($def);
  if ($ref eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'ack')
      { $var{'ACK'} = $val
          if defined($val = _parse_string($def->{$key}, 1));
      }
      elsif ($key eq 'cln')
      { $var{'CLN'} = $def->{$key};
      }
      elsif ($key eq 'cmd')
      { $val = $def->{$key};
        $var{'CMD'} = join(' ', @$val) if ref($val) eq 'ARRAY';
      }
      elsif ($key eq 'lim')
      { $var{'LIM'} = $val
          if defined($val = _parse_timeout($def->{$key}));
      }
      elsif ($key eq 'max')
      { $var{'MAX'} = $val
          if defined($val = _parse_timeout($def->{$key}));
      }
      elsif ($key eq 'nxt')
      { $var{'NXT'} = $val
          if defined($val = _parse_next($def->{$key}, "\n"));
      }
      elsif ($key eq 'pat')
      { $var{'PAT'} = $val
          if defined($val = _parse_prompt($def->{$key}));
      }
      elsif ($key eq 'skp')
      { $var{'SKP'} = $val
          if defined($val = _parse_skip_mode($def->{$key}));
      }
    }
  }
  elsif ($ref eq 'ARRAY')
  { $var{'CMD'} = join(' ', @$def);
  }
  elsif ($ref)
  { return -2;
  }
  else
  { $var{'CMD'} = $def;
  }
  return -3 unless exists($var{'CMD'});
  
  # Execute the request
  _update_status($slf, $drv->request('COLLECT', {%var}));
}

=head2 S<$h-E<gt>command($command[,$flag])>

This method executes the specified command on a remote node. There is no attempt
to treat the request differently if the remote node is the local node. When the
flag is set, it captures all output lines.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub command
{ my ($slf, $cmd, $flg, $inc) = @_;
  my ($drv, $val, %var);

  delete($slf->{'msg'});
  $slf->{'out'} = 0;
  ++$slf->{'_req'};

  # Abort when no driver is available
  unless ($drv = _get_driver($slf, 1))
  { ++$slf->{'_err'};
    return -1;
  }

  # Skip empty job
  return -1 unless $cmd;

  # Execute the request
  $var{'CMD'} = $cmd;
  $var{'FLG'} = $flg;
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = $val if ($val = _get_alarm($slf, $inc));
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'STA'} = 1;
  $var{'TMP'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  _update_status($slf, $drv->request('EXEC', {%var}));
}

=head2 S<$h-E<gt>execute($job,$file[,$inc])>

This method saves the output of the shell execution on the remote node in the
specified file.

It returns the command exit code when the request is executed. Otherwise, it
returns a negative value.

=cut

sub execute
{ my ($slf, $job, $fil, $inc, $add) = @_;
  my ($drv, $val, %var);

  delete($slf->{'msg'});
  $slf->{'out'} = 0;
  ++$slf->{'_req'};

  # Abort when no driver is available
  unless ($drv = _get_driver($slf, 1))
  { ++$slf->{'_err'};
    return -1;
  }

  # Skip empty job
  return -1 unless $job;

  # Execute the request
  $var{'HST'} = $slf->{'_hst'};
  $var{'CMD'} = $slf->{'_shl'};
  $var{'LIM'} = $val if ($val = _get_alarm($slf, $inc));
  $var{'NEW'} = 1 unless $add;
  $var{'OUT'} = $fil;
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'STA'} = 1;
  $var{'TMP'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  _update_status($slf, $drv->request('EXEC', {%var}, $job));
}

=head2 S<$h-E<gt>get($rdir,$rname[,$ldir[,$lname]])>

This method gets a single file from a remote node. By default, the same
directory and file name are assumed for the local destination. However, it
takes remote relative paths from the home directory, and local paths from the
working directory.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub get
{ my ($slf, $rdr, $rnm, $ldr, $lnm) = @_;
  my ($drv, $val, %var);

  return -2 unless $rdr && $rnm;

  # Abort when no driver is available
  return -1 unless ($drv = _get_driver($slf, 1));

  # Execute the remote request
  $var{'DST'} = _gen_path(defined($ldr) ? $ldr : $rdr, $lnm);
  $var{'FIL'} = _gen_path($rdr, $rnm);
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = 0;
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'STA'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  _update_status($slf, $drv->request('GET', {%var}));
}

=head2 S<$h-E<gt>get_api>

This method returns the version of the Java interface. It returns an undefined
value in case of problems.

=cut

sub get_api
{ _get_driver(shift)->get_api;
}

=head2 S<$h-E<gt>get_lines>

This method returns the lines stored during the last command execution.

=cut

sub get_lines
{ _get_driver(shift)->get_lines;
}

=head2 S<$h-E<gt>get_message>

This method returns the last message.

=cut

sub get_message
{ my ($slf) = @_;

  exists($slf->{'msg'}) ? $slf->{'msg'} : undef;
}

=head2 S<$h-E<gt>get_timeout>

This method returns the current duration of the timeout for executing remote
commands. When this mechanism is disabled, it returns 0.

=cut

sub get_timeout
{ shift->{'lim'};
}

=head2 S<$h-E<gt>get_type>

This method returns the session type. It returns an undefined value when a
driver is not yet associated to the session.

=cut

sub get_type
{ my ($slf) = @_;

  exists($slf->{'_drv'}) ? $slf->{'_drv'}->as_type : undef;
}

=head2 S<$h-E<gt>has_timeout>

This method indicates whether the last request encountered a timeout.

=cut

sub has_timeout
{ my ($slf) = @_;

  exists($slf->{'out'}) ? $slf->{'out'} : undef;
}

=head2 S<$h-E<gt>is_skipped>

This method indicates whether the last request was skipped.

=cut

sub is_skipped
{ my ($slf) = @_;

  exists($slf->{'skp'}) ? $slf->{'skp'} : undef;
}

=head2 S<$h-E<gt>login($username,$password[,$request])>

This method performs a login by waiting for a login prompt and responding with
the specified user name, then waiting for the password prompt and responding
with the specified password, and finally waiting for the command interpreter
prompt.

The login prompt must match either of these case insensitive patterns:

    /login[: ]*$/i
    /username[: ]*$/i

The password prompt must match this case insensitive pattern:

    /password[: ]*$/i

The current prompt pattern must match the command interpreter prompt.

When any of those prompts sent by the remote side do not match what is
expected, this method will time out, unless the timeout mechanism is disabled.

To alter temporarily some object attributes, you can specify an hash reference
as an argument. It supports following keys:

=over 11

=item S<    B<'chk'> > Banner check pattern

=item S<    B<'dis'> > Disconnection command

=item S<    B<'lim'> > Execution time limit

=item S<    B<'pat'> > Prompt pattern

=item S<    B<'pwd'> > User password

=item S<    B<'try'> > Maximum number of login attempts (2 per default)

=item S<    B<'usr'> > User name

=back

It returns the object reference on successful completion. Otherwise, it stores
the error message and returns an undefined value.

=head2 S<$h-E<gt>login($request)>

Since you can specify the user name and password in the request hash, you can
omit the two first arguments when specifying a request argument.

=cut

sub login
{ my ($slf, $usr, $pwd, $def) = @_;
  my ($acc, $drv, $hst, $ref, $val, %var);

  delete($slf->{'msg'});
  $slf->{'out'} = 0;
  ++$slf->{'_req'};

  # Abort when no driver is available
  unless ($drv = _get_driver($slf, 1))
  { ++$slf->{'_err'};
    return -1;
  }

  # Analyze the request
  if ($ref = ref($usr))
  { $def = $usr;
    $usr = $pwd = undef;
  }
  elsif ($ref = ref($pwd))
  { $def = $pwd;
    $pwd = undef;
  }
  else
  { $ref = ref($def);
  }
  $hst = $slf->{'_hst'};
  $usr = $slf->{'_usr'} unless defined($usr);

  $var{'LIM'} = $slf->{'lim'} if $slf->{'lim'};
  if ($ref eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'chk')
      { $var{'CHK'} = $val if defined($val = _parse_prompt($def->{$key}));
      }
      elsif ($key eq 'dis')
      { $var{'DIS'} = $val if defined($val = $def->{$key}) && $val =~ m/^\w/;
      }
      elsif ($key eq 'lim')
      { $var{'LIM'} = $val if defined($val = _parse_timeout($def->{$key}));
      }
      elsif ($key eq 'pat')
      { $var{'PAT'} = $val if defined($val = _parse_prompt($def->{$key}));
      }
      elsif ($key eq 'pwd')
      { $pwd = $def->{$key} if defined($def->{$key});
      }
      elsif ($key eq 'try')
      { $var{'TRY'} = $val
          if defined($val = $def->{$key}) && $val =~ m/^\d+$/;
      }
      elsif ($key eq 'usr')
      { $usr = $def->{$key} if defined($def->{$key});
      }
    }
  }
  die "RDA-01507: Missing user name\n" unless length($usr);
  $var{'HST'} = $hst;
  $var{'USR'} = $usr;
  if (exists($slf->{'_pwd'}))
  { $acc = $slf->{'_pwd'};
    $pwd = defined($pwd)
             ? $acc->set_password('host', $hst, $usr, $pwd) :
           $acc->has_password('host', $hst, $usr)
             ? $acc->get_password('host', $hst, $usr) :
           undef;
  }
  $var{'PWD'} = $pwd if defined($pwd);
 
  # Execute the request
  _update_status($slf, $drv->request('LOGIN', {%var})) ? undef : $slf;
}

=head2 S<$h-E<gt>logout>

This method closes the connection with the remote host. It returns the object
reference.

=cut

sub logout
{ my ($slf) = @_;
  my ($drv);

  delete($slf->{'msg'});
  $slf->{'out'} = 0;
  ++$slf->{'_req'};

  # Execute the request when a driver is available
  if ($drv = _get_driver($slf, 1))
  { _update_status($slf, $drv->request('LOGOUT',
      $slf->{'lim'} ? {LIM => $slf->{'lim'}} : {}));
  }
  else
  { ++$slf->{'_err'};
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>mget($flag,$rdir[,$rname[,$ldir]])>

This method gets one or more files from a remote node. The name may contain
shell meta characters. By default, the same directory name is assumed for the
local destination. However, it takes remote relative paths from the home
directory and local paths from the working directory. If the flag is set, it
copies entire directories recursively.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub mget
{ my ($slf, $flg, $rdr, $pat, $ldr) = @_;
  my ($drv, $val, %var);

  return 0 unless $rdr;

  # Abort when no driver is available
  return -1 unless ($drv = _get_driver($slf, 1));

  # Execute the remote request
  $var{'DIR'} = $rdr;
  $var{'DST'} = defined($ldr) ? $ldr : $rdr;
  $var{'FLG'} = 1 if $flg;
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = 0;
  $var{'PAT'} = $pat if defined($pat);
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'STA'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  _update_status($slf, $drv->request('GET', {%var}));
}

=head2 S<$h-E<gt>mput($flag,$ldir[,$re[,$rdir]])>

This method puts one or more files into a remote node. You can use a regular
expression to select the files inside the local directory. By default, it
assumes the same directory name for the remote destination. However, it takes
remote relative paths from the home directory, and local paths from the working
directory. If the flag is set, it copies entire directories recursively.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub mput
{ my ($slf, $flg, $ldr, $pat, $rdr) = @_;
  my ($drv, $val, @src, %var);

  return -1 unless $ldr;

  # Determine the list of the files to copy
  if ($pat)
  { $pat = qr/$pat/i;
    if (opendir(DIR, $ldr))
    { @src = grep {$_ =~ $pat && !m/^\.+$/} readdir(DIR);
      closedir(DIR)
    }
    return -2 unless scalar(@src);
    $var{'SRC'} = ($ldr eq '.')
      ? [@src]
      : [map {RDA::Object::Rda->native(RDA::Object::Rda->cat_file($ldr, $_))}
             @src];
  }
  else
  { $var{'SRC'} = [$ldr];
  }

  # Abort when no driver is available
  return -1 unless ($drv = _get_driver($slf, 1));

  # Execute the remote request
  $var{'FLG'} = 1 if $flg;
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = 0;
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'RDR'} = defined($rdr) ? $rdr : $ldr;
  $var{'STA'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  _update_status($slf, $drv->request('PUT', {%var}));
}

=head2 S<$h-E<gt>need_password>

This method indicates whether the current connection requires a password.

=cut

sub need_password
{ my ($slf, $inc) = @_;
  my ($drv, $val, %var);

  # Abort when no driver is available
  return 0 unless ($drv = _get_driver($slf, 1));

  # Execute the request
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = $val if ($val = _get_alarm($slf, $inc));
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  $drv->need_password({%var});
}

=head2 S<$h-E<gt>need_pause>

This method indicates whether the current connection could require a pause for
providing a password.

=cut

sub need_pause
{ my ($slf, $inc) = @_;
  my ($drv, $val, %var);

  # Abort when no driver is available
  return 0 unless ($drv = _get_driver($slf, 1));

  # Execute the request
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = $val if ($val = _get_alarm($slf, $inc));
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  $drv->need_pause({%var});
}

=head2 S<$h-E<gt>put($ldir,$lname[,$rdir[,$rname]])>

This method puts a single file into a remote node. By default, it assumes the
same directory and file name for the remote destination. However, it takes
remote relative paths from the home directory, and local paths from
C<RDA_HOME>.

It returns the command exit code when the request is executed. Otherwise, it
returns a negative value.

=cut

sub put
{ my ($slf, $ldr, $lnm, $rdr, $rnm) = @_;
  my ($drv, $val, %var);

  return -1 unless $ldr && $lnm;

  # Abort when no driver is available
  return -1 unless ($drv = _get_driver($slf, 1));

  # Execute the remote request
  $var{'HST'} = $slf->{'_hst'};
  $var{'LIM'} = 0;
  $var{'PWD'} = $val if defined($val = _get_password($slf));
  $var{'RDR'} = defined($rdr) ? $rdr : $ldr;
  $var{'RNM'} = $rnm if defined($rnm);
  $var{'SRC'} = 
    RDA::Object::Rda->native(RDA::Object::Rda->cat_file($ldr, $lnm));
  $var{'STA'} = 1;
  $var{'USR'} = $val if length($val = $slf->{'_usr'});
  _update_status($slf, $drv->request('PUT', {%var}));
}

=head2 S<$h-E<gt>request($context,$job,$file,$inc)>

This method executes a remote job and puts the results in the specified
file. It supports the following directives:

=over 2

=item * C<#BEGIN>

It adds into the result file a tag to start capturing the output lines until an END directive treats them.

=item * C<#BEGIN CAPTURE:E<lt>nameE<gt>>

It adds into the result file a tag to copy the following lines in the named
capture buffer. It clears the capture buffer unless its name is in lower case.

=item * C<#BEGIN LIST>

It adds into the result file a tag to start a new list.

=item * C<#BEGIN SECTION:E<lt>pretoc stringE<gt>>

It adds into the result file a tag to start a new section.

=item * C<#CALL E<lt>nameE<gt>(E<lt>nE<gt>)>

It executes the specified macro before treating the next directive.

=item * C<#DEFAULT>

It extracts all specifications until it finds a C</> lines and assigns them
as default interface parameters.

=item * C<#ECHO>

It extracts all lines until it finds a C</> lines and adds extracted lines
into the result file.

=item * C<#END CAPTURE>

It adds into the result file a tag to stop copying lines in a capture
buffer. It does not stop the line capture for other END directives.

=item * C<#END DATA:E<lt>pathE<gt>>

It adds into the result file a tag to treat the captured lines as data file
content. It generates a report but let the next END LIST adding it in a report.

=item * C<#END FILE:E<lt>pathE<gt>>

It adds into the result file a tag to treat the captured lines as file
content. It generates a report but let the next END SECTION adding it in the
table of content.

=item * C<#END LIST E<lt>nameE<gt>:E<lt>argument stringE<gt>>

It adds into the result file a tag to execute the specified macro with a buffer
containing the data file links and the argument string as arguments.

=item * C<#END MACRO E<lt>nameE<gt>:E<lt>argument stringE<gt>>

It adds into the result file a tag to execute the specified macro with a buffer
containing the captured lines and the argument string as arguments.

=item * C<#END PARSE>

It adds into the result file a tag to stop the file parsing.

=item * C<#END REPORT:E<lt>report descriptionE<gt>>

It adds into the result file a tag to produce a report with the captured
lines. The report description string contains the table of content level, the
link text, the report title, the location, and the report name separated by
C<|> characters. The last two elements are optional.

=item * C<#END SECTION>

It adds into the result file a tag to It ends a section.

=item * C<#END SECTION:E<lt>index levelE<gt>>

It adds into the result file a tag to It produces the file index and ends a section.

=item * C<#EXEC>

It extracts all lines until it finds a C</> lines, executes them on the remote
server, and stores their output into the result file.

=item * C<#EXIT>

It closes the communication interface and aborts the job.

=item * C<#QUIT>

It closes the communication interface and aborts the job.

=item * C<#SET TIMEOUT:E<lt>timeout stringE<gt>>

It adds into the result file a tag to It replaces the captured lines by the specified string.

=item * C<#SET TITLE:E<lt>toc stringE<gt>>

It adds into the result file a tag to It adds the specified string in the table of content.

=item * C<#SET VARIABLE:E<lt>groupE<gt>:E<lt>varE<gt>="E<lt>valueE<gt>">

It adds into the result file a tag to It adds a scalar variable to the named variable group.

=item * C<#SET VARIABLE:E<lt>groupE<gt>:E<lt>varE<gt>=(E<lt>listE<gt>)>

It adds into the result file a tag to It adds an array variable to the named variable group. The array is provided
as a comma-separated list of quoted values.

=item * C<#SLEEP(E<lt>durationE<gt>)>

It makes a pause of the specifed number of seconds.

=back

It returns 0 for a successful completion.

=cut

sub request
{ my ($slf, $ctx, $job, $fil, $inc) = @_;
  my ($buf, $drv, $err, $lim, $lin, $lgt, $msg, $ofh, $trc, @job);

  # Abort when the job is missing
  return 0 unless $job;

  # Execute the job
  ++$slf->{'_req'};
  $drv = _get_driver($slf);
  $ofh = IO::File->new;
  $ofh->open($fil, $APPEND, $FIL_PERMS)
    or die "RDA-01521: Cannot open result file for ".$slf->{'oid'}
          ." remote session:\n $!\n";

  $lim = $slf->get_alarm($inc);
  @job = split(/\n/, $job);
  if ($trc = $slf->{'lvl'})
  { for (@job)
    { print "REM: $_\n";
    }
  }
  eval {
    local $SIG{'__WARN__'} = sub {};

    if (!$slf->need_password($inc))
    { while (defined($lin = shift(@job)))
      { if ($lin =~ m/^#\s*((BEGIN|END\SET)\b.*)$/)
        { $buf = "---#RDA:$1\n";
          $ofh->syswrite($buf, length($buf));
        }
        elsif ($lin = m/^#\s*CALL\s+(\w+)\((\d+)\)\s*$/)
        { my ($val);

          $val = RDA::Value::Scalar::new_number($2);
          $val = RDA::Value::List->new($val);
          $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
          $val->eval_value;
        }
        elsif ($lin = m/^#\s*(COLLECT\d*)\s*$/)
        { my ($tag, @req);

          $tag = $1;
          while (defined($lin = shift(@job)) && $lin ne '/')
          { push(@req, $1, $2) if $lin =~ m/^([A-Z]{3})\s*=\s*'(.*)'/;
          }
          next unless @req;
          $slf->set_collect({@req});
          $slf->{'agt'}->log_timeout($ctx, $tag) if $slf->{'out'};
        }
        elsif ($lin = m/^#\s*(DEFAULT\d*)\s*$/)
        { my ($tag, @req);

          $tag = $1;
          while (defined($lin = shift(@job)) && $lin ne '/')
          { push(@req, $1, $2) if $lin =~ m/^([A-Z]{3})\s*=\s*'(.*)'/;
          }
          next unless @req;
          $slf->set_default({@req});
          $slf->{'agt'}->log_timeout($ctx, $tag) if $slf->{'out'};
        }
        elsif ($lin = m/^#\s*ECHO(\s+(.*))?$/)
        { $ofh->syswrite($2, length($2)) if defined($1);
        }
        elsif ($lin = m/^#\s*(EXEC\d*)\s*$/)
        { my ($tag, @req);

          $tag = $1;
          push(@req, $lin) while defined($lin = shift(@job)) && $lin ne '/';
          next unless @req;
          $slf->execute(join("\n", @req), $ofh, undef, 1);
          $slf->{'agt'}->log_timeout($ctx, $tag) if $slf->{'out'};
        }
        elsif ($lin = m/^#\s*(EXIT|QUIT)\s*$/)
        { $slf->disconnect;
        }
        elsif ($lin = m/^#\s*SLEEP\((\d+)\)\s*$/)
        { sleep($1);
        }
      }
    }
    };
  $ofh->close;

  # Detect and treat interrupts
  if ($err = $@)
  {
  }

  # Terminate the output treatment
  exists($slf->{'_msg'}) ? 0 : 1;
}

=head2 S<$h-E<gt>set_default($var)>

This method specifies default values to the remote interface. It returns 0 for
a successful completion. Otherwise, it returns a negative value.

=cut

sub set_default
{ my ($slf, $var, $inc) = @_;
  my ($dft, $drv, $val, @dft);

  delete($slf->{'msg'});
  $slf->{'out'} = 0;
  ++$slf->{'_req'};

  # Abort when no driver is available
  unless ($drv = _get_driver($slf, 1))
  { ++$slf->{'_err'};
    return -1;
  }

  # Skip empty job
  @dft = map {$_ => $var->{$_}}
         grep { m/^[A-Z]{3}$/ && _val_default($var->{$_})} keys(%$var)
    if ref($var) eq 'HASH';
  return 0 unless @dft;

  # Execute the request
  $dft = {@dft};
  $slf->{'_hst'} = $dft->{'HST'} if exists($dft->{'HST'});
  $slf->{'_usr'} = $dft->{'USR'} if exists($dft->{'USR'});
  $slf->{'par'}->_get_access->set_password('host',
    $slf->{'_hst'}, $slf->{'_usr'}, $dft->{'PWD'}) if exists($dft->{'PWD'});
  $dft->{'STA'} = 1;
  $dft->{'LIM'} = $val if ($val = _get_alarm($slf, $inc));
  _update_status($slf, $drv->request('DEFAULT', $dft));
}

sub _val_default
{ my ($val) = @_;
  my ($ref);

  return 0 unless defined($val);
  if ($ref = ref($val))
  { return 0 unless $ref eq 'ARRAY';
    foreach my $itm (@$val)
    { return 0 unless defined($itm) && !ref($itm);
    }
  }
  1;
}

=head2 S<$h-E<gt>set_timeout($limit)>

This method sets the timeout for the remote session, specified in seconds, only
if the value is strictly positive. Otherwise, it disables the timeout
mechanism. It is disabled also if the C<alarm> function is not implemented.

It returns the effective value.

=cut

sub set_timeout
{ my ($slf, $lim) = @_;

  $slf->{'lim'} = _chk_alarm($lim);
}

=head2 S<$h-E<gt>set_trace([$level])>

This method sets the remote trace level:

=over 7

=item B<    0 > Disables the remote trace.

=item B<    1 > Traces the remote command execution.

=back

The level is unchanged if the new level is not defined.

It returns the previous level.

=cut

sub set_trace
{ my ($slf, $lvl) = @_;
  my ($old);

  $old = $slf->{'lvl'};
  if (defined($lvl))
  { $slf->{'lvl'} = $lvl;
    $slf->{'_drv'}->request('DEFAULT', {TRC => $lvl})
      if exists($slf->{'_drv'});
  }
  $old;
}

=head2 S<$h-E<gt>set_type($type)>

This method assigns the specified type to the remote session. It deletes any
previous driver associate to it. It returns a zero value on successful
completion.

=cut

sub set_type
{ my ($slf, $typ) = @_;
  my ($ctl);

  # Validate the arguments
  die "RDA-01501: Requires a session object\n"
    unless $slf->{'_typ'} eq 'S';
  die "RDA-01505: Missing session type\n"
    unless defined($typ);
  die "RDA-01506: Invalid session type '$typ'\n"
    unless exists($tb_cap{$typ = lc($typ)});
  return 1 unless ref($ctl = _get_manager($slf, $typ));

  # Associate the a driver to the session
  $slf->{'_drv'}->delete if exists($slf->{'_drv'});
  $slf->{'_drv'} = $ctl->new($slf);

  # Indicate the successful completion
  0;
}

=head2 S<$h-E<gt>write_result($context,$file[,$prefix])>

This method treats a result file or a result buffer. It supports the following
directives:

=over 2

=item * C<---#RDA:BEGIN>

It starts capturing the output lines until an END directive treats them.

=item * C<---#RDA:BEGIN CAPTURE:E<lt>nameE<gt>>

It copies the following lines in the named capture buffer. It clears the
capture buffer unless its name is in lower case.

=item * C<---#RDA:BEGIN LIST>

It starts a new list.

=item * C<---#RDA:BEGIN SECTION:E<lt>pretoc stringE<gt>>

It starts a new section.

=item * C<---#RDA:END CAPTURE>

It stops copying lines in a capture buffer. It does not stop the line capture
for other END directives.

=item * C<---#RDA:END DATA:E<lt>pathE<gt>>

It treats the captured lines as data file content. It generates a report but
let the next END LIST adding it in a report.

=item * C<---#RDA:END FILE:E<lt>pathE<gt>>

It treats the captured lines as file content. It generates a report but let the
next END SECTION adding it in the table of content.

=item * C<---#RDA:END LIST E<lt>nameE<gt>:E<lt>argument stringE<gt>>

It executes the specified macro with a buffer containing the data file links
and the argument string as arguments.

=item * C<---#RDA:END MACRO E<lt>nameE<gt>:E<lt>argument stringE<gt>>

It executes the specified macro with a buffer containing the captured lines and
the argument string as arguments.

=item * C<---#RDA:END PARSE>

It stops the file parsing.

=item * C<---#RDA:END REPORT:E<lt>report descriptionE<gt>>

It produces a report with the captured lines. The report description string
contains the table of content level, the link text, the report title, the
location, and the report name separated by C<|> characters. The last two
elements are optional.

=item * C<---#RDA:END SECTION>

It ends a section.

=item * C<---#RDA:END SECTION:E<lt>index levelE<gt>>

It produces the file index and ends a section.

=item * C<---#RDA:SET TIMEOUT:E<lt>timeout stringE<gt>>

It replaces the captured lines by the specified string.

=item * C<---#RDA:SET TITLE:E<lt>toc stringE<gt>>

It adds the specified string in the table of content.

=item * C<---#RDA:SET VARIABLE:E<lt>groupE<gt>:E<lt>varE<gt>="E<lt>valueE<gt>">

It adds a scalar variable to the named variable group.

=item * C<---#RDA:SET VARIABLE:E<lt>groupE<gt>:E<lt>varE<gt>=(E<lt>listE<gt>)>

It adds an array variable to the named variable group. The array is provided
as a comma-separated list of quoted values.

=back

It returns 0 for a successful completion.

=cut

sub write_result
{ my ($slf, $ctx, $res, $pre) = @_;
  my ($ifh);

  $pre = $slf->{'_pre'} unless defined($pre);
  if (ref($res) eq 'RDA::Object::Buffer')
  { _write_result($slf, $ctx, $res->get_handle, $pre);
  }
  else
  { $ifh = IO::File->new;
    if ($ifh->open("<$res"))
    { _write_result($slf, $ctx, $ifh, $pre);
      $ifh->close;
    }
  }

  # Indicate a sucessful completion
  0;
}

sub _write_result
{ my ($slf, $ctx, $ifh, $pre) = @_;
  my ($buf, $cut, $out, $rpt, $toc, $trc, $val, @buf, @tbl, %idx);

  # Initialization
  $out = $ctx->get_output;
  $toc = $out->get_info('toc');
  $trc = $slf->{'lvl'};

  # Treat the results
  $cut = 1;
  $slf->{'var'} = {};
  while (<$ifh>)
  { s/[\n\r\s]+$//;
    print "$pre> $_\n" if $trc;
    if (m/^\-{3}#\s+RDA:(BEGIN|END|SET)/)
    { my ($cmd, $dat);

      (undef, $cmd, $dat) = split(/:/, $_, 3);
      if ($cmd eq 'BEGIN')
      { $cut = 0;
        @buf = ();
      }
      elsif ($cmd eq 'BEGIN CAPTURE')
      { $dat = '?' unless defined($dat) && length($dat);
        $buf = lc($dat);
        $slf->{'_buf'}->{$buf} = [] unless $dat eq $buf;
      }
      elsif ($cmd eq 'BEGIN LIST')
      { @tbl = ();
      }
      elsif ($cmd eq 'BEGIN SECTION')
      { %idx = ();
        $toc->push_line("$dat\n") if $toc;
      }
      elsif ($cmd eq 'END CAPTURE')
      { $buf = undef;
      }
      elsif ($cmd eq 'END DATA')
      { $cut = 1;
        $dat = '?' unless defined($dat) && length($dat);
        $val = basename($dat);
        if (@buf)
        { $rpt = $out->add_report('D',"log_$val");
          $rpt->write_lines(RDA::Object::Buffer->new('l', \@buf));
          push(@tbl, '[['.$rpt->get_report.'][rda_report]['.$val."]]");
          $out->end_report($rpt);
        }
        else
        { push(@tbl, $val);
        }
      }
      elsif ($cmd eq 'END FILE')
      { $cut = 1;
        if (@buf)
        { $dat = '?' unless defined($dat) && length($dat);
          $val = basename($dat);
          $rpt = $out->add_report('F',"log_$val");
          $val = RDA::Object::Sgml::encode($val);
          $rpt->write("---+ Display of $val File\n"
             ."---## Information Taken from "
             .RDA::Object::Sgml::encode($dat)."\n");
          $rpt->write_lines(RDA::Object::Buffer->new('L', \@buf));
          $rpt->write($TOP);
          $idx{dirname($dat)}->{$val} =
            ':[['.$rpt->get_report.'][rda_report]['.$val."]]\n";
          $out->end_report($rpt);
        }
      }
      elsif ($cmd =~ m/^END LIST (\w+)$/)
      { $cut = 1;
        if (@tbl)
        { $dat = (defined($dat) && length($dat))
            ? RDA::Value::Scalar::new_text($dat)
            : RDA::Value::Scalar::new_undef;
          $val = RDA::Value::List->new(RDA::Value::Scalar::new_object(
            RDA::Object::Buffer->new('L', \@tbl)), $dat);
          $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
          $val->eval_value;
        }
      }
      elsif ($cmd =~ m/^END MACRO (\w+)$/)
      { $cut = 1;
        if (@buf)
        { $dat = (defined($dat) && length($dat))
            ? RDA::Value::Scalar::new_text($dat)
            : RDA::Value::Scalar::new_undef;
          $val = RDA::Value::List->new(RDA::Value::Scalar::new_object(
            RDA::Object::Buffer->new('L', \@buf)), $dat);
          $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
          $val->eval_value;
        }
      }
      elsif ($cmd eq 'END PARSE')
      { return;
      }
      elsif ($cmd eq 'END REPORT')
      { $cut = 1;
        if (@buf)
        { my ($det, $lnk, $ttl, $loc, $nam);

          ($det, $lnk, $ttl, $loc, $nam) = split(/\|/, $dat, 5);
          if (defined($nam))
          { $nam =~ s#[\/\\]#r#g;
          }
          else
          { $nam = $lnk;
          }
          $rpt = $out->add_report('f',$nam);
          $rpt->write("---+!! $ttl\n");
          $rpt->write('---## Location:&nbsp;'
            .RDA::Object::Sgml::encode($loc)."\n") if $loc;
          $rpt->write_lines(RDA::Object::Buffer->new('L', \@buf));
          $rpt->write($TOP);
          $toc->write($det.':[['.$rpt->get_report."][rda_report][$lnk]]\n");
          $out->end_report($rpt);
        }
      }
      elsif ($cmd eq 'END SECTION')
      { $cut = 1;
        if ($toc)
        { if (defined($dat) && $dat =~ m/^\d+$/)
          { $val = $dat + 1;
            foreach my $grp (sort keys(%idx))
            { $toc->write($dat.':'.RDA::Object::Sgml::encode($grp)."\n");
              foreach my $fil (sort keys(%{$idx{$grp}}))
              { $toc->write($val.$idx{$grp}->{$fil});
              }
            }
          }
          $toc->pop_line(1);
        }
        %idx = ();
      }
      elsif ($cmd eq 'SET TITLE')
      { $toc->write("$dat\n") if $toc;
      }
      elsif ($cmd eq 'SET TIMEOUT')
      { @buf = ($dat);
      }
      elsif ($cmd eq 'SET VARIABLE')
      { if (defined($dat))
        { my ($grp, $tbl);

          $grp = ($dat =~ s/^(\w+)://) ? uc($1) : '?';
          if ($dat =~ m/^(.*?)="(.*)"/)
          { $slf->{'_var'}->{$grp}->{$1} = $2;
          }
          elsif ($dat =~ m/^(.*?)=\((.*)\)/)
          { $slf->{'_var'}->{$grp}->{$1} = $tbl = [];
            $dat = $2;
            while ($dat =~ s/^"(.*?)"(,)?//)
            { push (@$tbl, $1);
              last unless $2;
            }
          }
        }
      }
    }
    else
    { push(@buf, $_) unless $cut;
      push(@{$slf->{'_buf'}->{$buf}}, $_) if $buf;
    }
  }
}

# --- Alarm routines ----------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0);};
  $@ ? 0 : $lim;
}

# Get the alarm duration
sub _get_alarm
{ my ($slf, $val) = @_;

  return $slf->{'lim'} unless defined($val);
  return 0 unless $slf->{'lim'} > 0 && $val > 0;
  $val *= $slf->{'lim'};
  ($val > 1) ? int($val) : 1;
}

# --- Internal routines -------------------------------------------------------

# Generate a path
sub _gen_path
{ my ($dir, $fil) = @_;

  (!defined($fil)) ? $dir :
  ($dir eq '.')    ? $fil :
                     RDA::Object::Rda->cat_file($dir, $fil);
}

# Get the access control object
sub _get_access
{ my ($slf) = @_;

  return $slf->{'_pwd'} if exists($slf->{'_pwd'});
  $slf->{'_pwd'} = $slf->{'pkg'}->get_access;
}

# Get the session driver
sub _get_driver
{ my ($slf, $flg) = @_;
  my ($ctl);

  # Return any previously defined driver
  return $slf->{'_drv'} if exists($slf->{'_drv'});

  # Allocate a driver
  die "RDA-01502: Requires a remote session object\n"
    unless $slf->{'_typ'} eq 'S';
  foreach my $typ (@tb_dft)
  { return $slf->{'_drv'} = $ctl->new($slf)
      if ($ctl = _get_manager($slf, $typ));
  }
  $slf->{'msg'} = "RDA-01520: Cannot perform remote sessions";
  die $slf->{'msg'}."\n" unless $flg;
  undef;
}
 
# Provide the local session manager
sub _get_local
{ my ($slf) = @_;
  my ($cls, $top);

  # Determine the driver manager on first usage
  $top = $slf->get_top;
  unless (exists($top->{'_mgr'}->{'local'}))
  { $cls = 'RDA::Driver::Local';
    eval "require $cls";
    die "RDA-01510: Package '$cls' not available:\n $@\n" if $@;
    eval {$top->{'_mgr'}->{'local'} = $cls->new($top->{'agt'}, $slf->{'lim'})};
    die "RDA-01511: Cannot manage local sessions:\n $@\n" if $@;
  }

  # Return the local session manager
  $top->{'_mgr'}->{'local'};
}

# Provide the corresponding driver manager
sub _get_manager
{ my ($slf, $typ) = @_;
  my ($cls, $top);

  # Determine the driver manager on first usage
  $top = $slf->get_top;
  unless (exists($top->{'_mgr'}->{$typ}))
  { $top->{'_mgr'}->{$typ} = undef;
    unless ($top->{'agt'}->get_setting($tb_cap{$typ}->[1]))
    { $cls = $tb_cap{$typ}->[0];
      eval "require $cls";
      die "RDA-01510: Package '$cls' not available:\n $@\n" if $@;
      eval {$top->{'_mgr'}->{$typ} = $cls->new($top->{'agt'}, $slf->{'lim'})};
      die "RDA-01512: Cannot manage $typ sessions:\n $@\n" if $@;
    }
  }

  # Return the driver manager
  $top->{'_mgr'}->{$typ};
}

# Get the session password
sub _get_password
{ my ($slf) = @_;
  my ($acc);

  $acc = $slf->{'par'}->_get_access;
  $acc->has_password('host', $slf->{'_hst'}, $slf->{'_usr'})
    ? $acc->get_password('host', $slf->{'_hst'}, $slf->{'_usr'})
    : undef;
}

# Parse the continuation pattern(s)
sub _parse_next
{ my ($nxt, $ors) = @_;
  my ($ack, $str, @nxt, @tbl);

  return _parse_prompt($nxt) unless ref($nxt) eq 'ARRAY';
  @tbl = @$nxt;
  while (($str, $ack) = splice(@tbl, 0, 2))
  { push(@nxt, [$str, _parse_string($ack, 1, $ors)])
      if defined(_parse_prompt($str));
  }
  @nxt ? [@nxt] : undef;
}

sub _parse_prompt
{ my ($pat, $dft) = @_;
  my ($buf, $slf, @msg);

  return $dft unless defined($pat);
  die "RDA-01513: Expecting a match as prompt \"$pat\"\n"
    unless $pat =~ m(^\s*/) || $pat =~ m(^\s*m\s*\W);
  { local $^W = 1;
    local $SIG{"__WARN__"} = sub {push(@msg, @_)};

    $slf = {eof => 1, _buf => ''};
    eval $TEST_BEG_PAT.$pat.$TEST_END_PAT;
  }
  die "RDA-01514: Error when compiling pattern \"$pat\":\n$@\n"       if $@;
  die join("\n",
    "RDA-01515: Warnings when compiling pattern \"$pat\":", @msg, '') if @msg;
  $pat;
}

# Parse the skip mode
sub _parse_skip_mode
{ my ($mod, $dft) = @_;

  return $dft unless defined($mod);
  return $1   if $mod =~ /^\s*(auto|\d+)\s*$/i;
  die "RDA-01516: Invalid skip mode \"$mod\"\n";
}

# Parse a string
sub _parse_string
{ my ($str, $min, $dft) = @_;

  ref($str)                               ? $dft :
  (defined($str) && length($str) >= $min) ? $str :
                                            $dft;
}

# Parse the timeout value
sub _parse_timeout
{ my ($lim, $dft) = @_;

  return $dft unless defined($lim);
  die "RDA-01517: Invalid timeout \"$lim\"\n" unless $lim =~ m/^-?\d+$/;
  ($lim > 0) ? $lim : 0;
}

# Update the execution status
sub _update_status
{ my ($slf, $sta) = @_;

  if ($sta < 0)
  { $slf->{'msg'} = $slf->{'_drv'}->get_message;
    if ($slf->{'_drv'}->is_skipped)
    { $slf->{'skp'} = 1;
      ++$slf->{'_skp'};
    }
    elsif ($slf->{'_drv'}->has_timeout)
    { $slf->{'out'} = 1;
      ++$slf->{'_out'};
    }
    else
    { ++$slf->{'_err'};
    }
  }
  $sta;
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the remote session manager
sub _begin_remote
{ my ($pkg) = @_;
  my ($ctl);

  $ctl = $pkg->get_agent->get_remote->new($pkg);
  $pkg->set_info('rem', $ctl);
  $pkg->define('$[REM]', $ctl);
}

# Close all active remote sessions
sub _end_remote
{ my ($pkg) = @_;

  $pkg->set_info('rem')->delete;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Driver::Da|RDA::Driver::Da>,
L<RDA::Driver::Jsch|RDA::Driver::Jsch>,
L<RDA::Driver::Local|RDA::Driver::Local>,
L<RDA::Driver::Rsh|RDA::Driver::Rsh>,
L<RDA::Driver::Ssh|RDA::Driver::Ssh>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Inline|RDA::Object::Inline>,
L<RDA::Object::Java|RDA::Object::Java>,
L<RDA::Object::Sgml|RDA::Object::Sgml>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
