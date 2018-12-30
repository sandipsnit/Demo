# Remote.pm: Class Used for Remote Operation Macros

package RDA::Library::Remote;

# $Id: Remote.pm,v 2.7 2012/05/21 21:14:23 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Remote.pm,v 2.7 2012/05/21 21:14:23 mschenke Exp $
#
# Change History
# 20120521  MSC  Add the hasRemoteTimeout macro.

=head1 NAME

RDA::Library::Remote - Class Used for Remote Operation Macros

=head1 SYNOPSIS

require RDA::Library::Remote;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Remote> class are used to interface with
remote operation macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Copy;
  use IO::File;
  use RDA::Object::Rda qw($APPEND $CREATE $FIL_PERMS);
  use RDA::Object::Remote;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $ALR = "___Alarm___";

# Define the global private variables
my %tb_fct = (
  'endSteps'         => [\&_m_end_steps,     'N'],
  'genRemoteSetup'   => [\&_m_gen_setup,     'T'],
  'get'              => [\&_m_get,           'N'],
  'getRemoteLines'   => [\&_m_get_lines,     'L'],
  'getRemoteSetup'   => [\&_m_get_setup,     'T'],
  'getStep'          => [\&_m_get_step,      'T'],
  'hasRemoteTimeout' => [\&_m_has_timeout,   'N'],
  'initRemote'       => [\&_m_init_remote,   'N'],
  'initSteps'        => [\&_m_init_steps,    'N'],
  'isRemote'         => [\&_m_is_remote,     'N'],
  'mget'             => [\&_m_mget,          'N'],
  'mput'             => [\&_m_mput,          'N'],
  'needPassword'     => [\&_m_need_password, 'N'],
  'needPause'        => [\&_m_need_pause,    'N'],
  'put'              => [\&_m_put,           'N'],
  'rcollect'         => [\&_m_rcollect,      'N'],
  'rda'              => [\&_m_rda,           'N'],
  'rexec'            => [\&_m_rexec,         'N'],
  'setStep'          => [\&_m_set_step,      'T'],
  'transfer'         => [\&_m_transfer,      'N'],
  );
my %tb_set = (
  '_STEP'    => ['T', 'Remote node execution step'],
  '_STORAGE' => ['T', 'Remote node storage type'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Remote-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Remote> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'lim' > > Execution time limit (in seconds)

=item S<    B<'trc' > > Remote execution trace flag

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_cfg'> > Reference to the RDA software configuration

=item S<    B<'_err'> > Last command error lines

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of operating system requests timed out

=item S<    B<'_req'> > Number of operating system requests

=item S<    B<'_rlg'> > Remote log file path

=item S<    B<'_rfh'> > Remote log file handler

=item S<    B<'_ses'> > Reference the the last session

=item S<    B<'_ssh'> > Authentication agent indicator

=item S<    B<'_stp'> > Step hash

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    lim  => _chk_alarm($agt->get_setting('RDA_TIMEOUT', 30)),
    trc  => $agt->get_setting('REMOTE_TRACE', 0),
    _agt => $agt,
    _cfg => $agt->get_config,
    _err => [],
    _out => 0,
    _req => 0,
    _ssh => 0,
    _ses => undef,
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

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

=head2 S<$h-E<gt>clr_stats>

This method resets the statistics and clears corresponding module settings.

=cut

sub clr_stats
{ my ($slf) = @_;

  $slf->{'_ses'} = undef;
  $slf->{'_not'} = '';
  $slf->{'_req'} = $slf->{'_out'} = 0;
}

=head2 S<$h-E<gt>get_stats>

This method reports the library statistics in the specified module.

=cut

sub get_stats
{ my ($slf) = @_;
  my ($use);

  if ($slf->{'_req'})
  { # Get the statistics record
    $use = $slf->{'_agt'}->get_usage;
    $use->{'REM'} = {err => 0, not => '', out => 0, req => 0, skp => 0}
      unless exists($use->{'REM'});
    $use = $use->{'REM'};

    # Indicate the current timeout when there is no other note
    $slf->{'_not'} = 'Command execution limited to '.$slf->{'lim'}.'s'
      unless $use->{'not'} || $slf->{'_not'} || $slf->{'lim'} <= 0;

    # Generate the module statistics
    $use->{'out'} += $slf->{'_out'};
    $use->{'req'} += $slf->{'_req'};
    $use->{'not'} = $slf->{'_not'} if $slf->{'_not'};

    # Reset the statistics
    clr_stats($slf);
  }
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

=head1 REMOTE MACROS

=head2 S<endSteps()>

This macro collects all the step changes accumulated in the remote log file,
updates settings appropriately, and removes the remote log file. This is not
performed inside a thread. It returns 1 on successful completion. Otherwise,
it returns 0.

=cut

sub _m_end_steps
{ my ($slf, $ctx) = @_;

  # Check if it can be done
  return 0 if $ctx->get_top('job') || !exists($slf->{'_rlg'});

  # Close the remote log file
  if (exists($slf->{'_rfh'}))
  { $slf->{'_rfh'}->close;
    delete($slf->{'_rfh'});
  }

  # Review all steps present in the remote log file
  $slf->_load_steps($slf->{'_agt'}, $slf->{'_rlg'});

  # Remove the remote log file
  1 while unlink($slf->{'_rlg'});
  delete($slf->{'_rlg'});

  # Indicate the successful completion
  1;
}

# Load steps from the remote log file
sub _load_steps
{ my ($slf, $agt, $pth) = @_;
  my ($key, $nod, $rec, $stp, $val, @tbl, %stp);

  if (open(REM, "<$pth"))
  { # Read the remote log file
    while (<REM>)
    { ($nod, $stp, @tbl) = split(/\|/);
      pop(@tbl);
      $stp{$nod} = $stp;
      foreach my $itm (@tbl)
      { ($key, $val) = split(/=/, $itm, 2);
        if (exists($tb_set{$key}))
        { $rec = $tb_set{$key};
          $agt->set_setting("REMOTE_$nod$key", $val, $rec->[0], $rec->[1]);
          next;
        }
        $key = "REMOTE_$nod$key" if $key =~ m/^_/;
        $agt->set_setting($key, $val);
      }
      $slf->{'_stp'}->{$nod} = $stp;
    }
    close(REM);

    # Save the last steps
    foreach $nod (keys(%stp))
    { $agt->set_setting("REMOTE_$nod\_STEP", $stp{$nod}, 'T',
        'Remote node execution step');
    }
  }
}

=head2 S<get($node,$rdir,$rname[,$ldir[,$lname]])>

This macro gets a single file from a remote node. By default, the same directory
and file name are assumed for the local destination. However, it takes remote
relative paths from the home directory, and local paths from the working
directory.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_get
{ my ($slf, $ctx, $nod, @arg) = @_;

  return -1 unless $nod;

  # Execute the remote request
  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
  $slf->{'_ses'}->get(@arg);
} 

=head2 S<getRemoteLines()>

This macro returns the lines stored during the last command execution.

=cut

sub _m_get_lines
{ my ($slf, $ctx) = @_;

  return () unless $slf->{'_ses'};
  $slf->{'_ses'}->get_lines;
}

=head2 S<genRemoteSetup($node[,$key,$val,...])>

This macro locally generates the setup file for the specified remote node. It
returns the local name on successful completion. Otherwise, it returns an
undefined value.

=cut

sub _m_gen_setup
{ my $slf = shift;
  my $ctx = shift;
  my $nod = shift;
  my ($fil, $key, $ofh, $sep, $val);

  # Determine the local setup file name
  $fil = $slf->{'_agt'}->get_config->get_file('D_CWD',
    'l'.$nod.'_'.$slf->{'_agt'}->get_oid, '.cfg');

  # Generate the setup file
  $ofh = IO::File->new;
  return undef unless $ofh->open($fil, $CREATE, $FIL_PERMS);
  $sep = '-' x 78;
  print {$ofh} "#$sep\n# Data Collection Overview\n#$sep\n# S900INI=skip\n\n",
    "#$sep\n# S900INI: Transferred parameters\n#$sep\n";
  while (($key, $val) = splice(@_, 0, 2))
  { print {$ofh} "#T.$key\n$key=$val\n";
  }
  $ofh->close;

  # Indicate a successful completion
  $fil;
}

=head2 S<getRemoteSetup($node[,$flag])>

This macro returns the name of the remote node setup file. When the flag is
set, it returns the local name. The two names differ by their first letter to
detect shared installation.

=cut

sub _m_get_setup
{ my ($slf, $ctx, $nod, $flg) = @_;

  ($flg ? 'l' : 'r').$nod.'_'.$slf->{'_agt'}->get_oid.'.cfg';
}

=head2 S<getStep($node,$dft)>

This macro returns the current step for the specified node. Otherwise, it
returns the default value when the node step is not yet defined.

=cut

sub _m_get_step
{ my ($slf, $ctx, $nod, $val) = @_;

  # Get the step information when not yet initialized
  _m_init_steps($slf, $ctx) unless exists($slf->{'_rfh'});

  # Get the step information
  $val = $slf->{'_stp'}->{$nod} if exists($slf->{'_stp'}->{$nod});
  $val;
}

=head2 S<hasRemoteTimeout([$nod])>

This macro indicates whether the last request encountered a timeout.

=cut

sub _m_has_timeout
{ my ($slf, $ctx, $nod) = @_;

  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1) if defined($nod);
  $slf->{'_ses'}
    ? $slf->{'_ses'}->has_timeout
    : undef;
}

=head2 S<initRemote()>

This macro forces the initialization of the authentication agent. It returns
the authentication agent status.

=cut

sub _m_init_remote
{ my ($slf) = @_;

  $slf->{'_ssh'} = $slf->{'_agt'}->get_remote->set_agent unless $slf->{'_ssh'};
  $slf->{'_ssh'};
}

=head2 S<initSteps($flg)>

This macro gets the steps from the settings. Unless the flag is set, it
recovers steps from an aborted session and opens the remote log file. It
creates the remote directory if it does not exist already. It returns 1 on
successful completion. Otherwise, it returns 0.

You should run this macro before the first C<getStep> or C<setStep>, and
especially before starting any thread.

=cut

sub _m_init_steps
{ my ($slf, $ctx, $flg) = @_;
  my ($agt, $pth, $rfh);

  # Check if it can be done
  return 0 if exists($slf->{'_rlg'});

  # Create the remote directory when needed
  $agt = $slf->{'_agt'};
  $pth = RDA::Object::Rda->cat_dir($agt->get_setting('RPT_DIRECTORY'),
    'remote');
  die "RDA-00511: Cannot create the remote directory $pth:\n $!\n"
        unless -d $pth || mkdir($pth, 0750);

  # Recover steps present in an existing remote log file
  $slf->{'_rlg'} = $pth =
    RDA::Object::Rda->cat_file($pth, $agt->get_oid.'.log');
  $slf->_load_steps($agt, $pth) unless $flg;

  # Extract steps from the settings
  $slf->{'_stp'} = {};
  foreach my $key ($agt->grep_setting('^REMOTE_.*_STEP$'))
  { $slf->{'_stp'}->{$1} = $agt->get_setting("REMOTE_$1\_STEP")
      if $key =~ m/^REMOTE_(.*)_STEP$/;
  }

  # Open the remote log file
  unless ($flg)
  { $rfh = IO::File->new;
    $rfh->open($pth, $APPEND, $FIL_PERMS) ||
      die "RDA-00512: Cannot create the remote log file $pth:\n $!\n";
    $slf->{'_rfh'} = $rfh;
  }

  # Indicate the successful completion
  1;
}

=head2 S<isRemote($node)>

This macro indicates if the specified node is a remote one.

=cut

sub _m_is_remote
{ my ($slf, $ctx, $nod) = @_;

  _is_remote($slf->{'_cfg'},
    $slf->{'_agt'}->get_setting("REMOTE_$nod\_HOSTNAME", 'localhost'));
}

sub _is_remote
{ my ($cfg, $nod) = @_;

  $nod ne 'localhost' && $nod ne $cfg->get_node && $nod ne $cfg->get_host;
}

=head2 S<mget($node,$flg,$rdir[,$re[,$ldir]])>

This macro gets one or more files from a remote node. The name may contain
shell meta characters. By default, the same directory name is assumed for the
local destination. However, it takes remote relative paths from the home
directory and local paths from the working directory. If the flag is set, it
copies entire directories recursively.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_mget
{ my ($slf, $ctx, $nod, @arg) = @_;

  return -1 unless $nod;

  # Execute the remote request
  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
  $slf->{'_ses'}->mget(@arg);
} 

=head2 S<mput($node,$ldir[,$re[,$rdir]])>

This macro puts one or more files into a remote node. You can use a regular
expression to select the files inside the local directory. By default, it
assumes the same directory name for the remote destination. However, it takes
remote relative paths from the home directory, and local paths from the working
directory. If the flag is set, it copies entire directories recursively.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_mput
{ my ($slf, $ctx, $nod, @arg) = @_;

  return -1 unless $nod;

  # Execute the remote request
  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
  $slf->{'_ses'}->mput(@arg);
} 

=head2 S<needPassword([$nod])>

This macro indicates whether the remote session requires a password.

=cut

sub _m_need_password
{ my ($slf, $ctx, $nod) = @_;

  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1) if defined($nod);
  $slf->{'_ses'}
    ? $slf->{'_ses'}->need_password
    : undef;
}

=head2 S<needPause([$nod])>

This macro indicates whether the remote session could require a pause for
providing a password.

=cut

sub _m_need_pause
{ my ($slf, $ctx, $nod) = @_;

  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1) if defined($nod);
  $slf->{'_ses'}
    ? $slf->{'_ses'}->need_pause
    : undef;
}

=head2 S<put($node,$ldir,$lname[,$rdir[,$rname]])>

This macro puts a single file into a remote node. By default, it assumes the
same directory and file name for the remote destination. However, it takes
remote relative paths from the home directory, and local paths from
C<RDA_HOME>.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_put
{ my ($slf, $ctx, $nod, @arg) = @_;

  return -1 unless $nod;

  # Execute the remote request
  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
  $slf->{'_ses'}->put(@arg);
} 

=head2 S<rcollect($nod,$job,$fil[,$var])>

This macro saves the output of the shell execution on the remote node in the
specified file.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_rcollect
{ my ($slf, $ctx, $nod, $cod, $res, $var) = @_;
  my ($ref, @buf);

  return -1 unless $nod && $cod;

  # Determine the variable contribution
  if ($ref = ref($var))
  { $var = $var->as_data if $ref =~ m/^RDA::Value/;
    foreach my $key (sort keys(%$var))
    { push(@buf, $key.'="'.$var->{$key}.'"');
    }
  }

  # Execute the script command
  $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
  $slf->{'_ses'}->execute(join("\n", @buf, $cod), $res);
}

=head2 S<rda($node,$options[,$flag])>

This macro executes RDA with the specified options on a remote node. It treats
requests differently, depending on whether they are on local or remote
systems. When the flag is set, it captures all output lines.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_rda
{ my ($slf, $ctx, $nod, $opt, $flg) = @_;
  my ($agt, $cmd, $tgt);

  return -1 unless $nod && defined($opt);

  # Determine the target system
  $agt = $slf->{'_agt'};
  $tgt = $agt->get_setting("REMOTE_$nod\_HOSTNAME", 'localhost');

  # Execute the RDA command
  if (_is_remote($slf->{'_cfg'}, $tgt))
  { # Determine the command
    $cmd = RDA::Object::Rda->cat_file($agt->get_setting("REMOTE_$nod\_HOME"),
      $agt->get_setting("REMOTE_$nod\_RDA_COMMAND") ||
      $agt->get_setting('REMOTE_RDA_COMMAND', 'rda.sh'));
    $cmd .= ' '.$opt if $opt;

    # Execute the remote request
    $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
  } 
  else
  { # Determine the command
    $cmd = $agt->get_setting('LOCAL_RDA_COMMAND') ||
           $agt->get_setting('RDA_SELF');
    $cmd .= ' '.$opt if $opt;
    $cmd .= ' 2>&1';

    # Execute the local request
    $slf->{'_ses'} = $ctx->get_remote->add_local($nod);
  } 
  $slf->{'_ses'}->command($cmd, $flg);
}

=head2 S<rexec($node,$command[,$flag])>

This macro executes the specified command on a remote node. There is no attempt
to treat the request differently if the remote node is the local node. When the
flag is set, it captures all output lines.

It returns the command exit code when the request is executed. Otherwise, it
returns -1.

=cut

sub _m_rexec
{ my ($slf, $ctx, $nod, $cmd, $flg) = @_;
  my ($agt, $err, $lim, $ret, $tgt, @cmd);

  return -1 unless $nod && $cmd;

  # Execute the remote request
  $lim = $slf->{'lim'};
  $ret = -1;
  eval {
    local $SIG{'__WARN__'} = sub {};
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;
    local $SIG{'PIPE'}     = sub { die "$ALR\n" } if $lim;

    alarm($lim) if $lim;
    $slf->{'_ses'} = $ctx->get_remote->get_session($nod, 1);
    $ret = $slf->{'_ses'}->command($cmd, $flg);
    alarm(0) if $lim;
    };

  # Propagate errors
  if ($@ && $@ !~ m/^$ALR\n/)
  { alarm(0) if $lim;
    die $@;
  }

  # Return the command result
  $ret;
} 

=head2 S<setStep($node,$step[,...])>

This macro sets the current step for the specified node and saves it in the
remote log file. You can specify additional setting directives as extra
arguments in a 'key=value' format.

=cut

sub _m_set_step
{ my ($slf, $ctx, $nod, $stp, @arg) = @_;
  my ($agt, $key, $val);

  # Get the step information when not yet initialized
  _m_init_steps($slf, $ctx) unless exists($slf->{'_rfh'});

  # Save the step information in the remote log file
  print {$slf->{'_rfh'}} join('|', $nod, $stp, @arg), "|\n";

  # Also apply the setting directives in the local context
  $agt = $slf->{'_agt'};
  foreach my $itm (@arg)
  { ($key, $val) = split(/=/, $itm, 2);
    $key = "REMOTE_$nod$key" if $key =~ m/^_/;
    $agt->set_setting($key, $val);
  }

  # Set the step information
  $slf->{'_stp'}->{$nod} = $stp;
}

=head2 S<transfer($ldir,$lname,$rdir[,$rname[,$flag]])>

This macro moves a file between directories. When the flag is set, it copies
the file. It returns 1 on success or 0 on failure.

=cut

sub _m_transfer
{ my ($slf, $ctx, $ldr, $lnm, $rdr, $rnm, $flg) = @_;
  my ($src, $dst);

  return -1 unless $ldr && $lnm;

  $src = _gen_path($ldr, $lnm);
  return 0 unless -e $src;

  $rdr = $ldr unless defined($rdr);
  return 0 unless -d $rdr || mkdir($rdr,0750);
  $dst = _gen_path($rdr, defined($rnm) ? $rnm : $lnm);

  $flg ? copy($src, $dst) : move($src, $dst);
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

# --- Local Internal routines -------------------------------------------------

sub _gen_path
{ my ($dir, $fil) = @_;

  (!defined($fil)) ? $dir : ($dir eq '.') ? $fil :
    RDA::Object::Rda->cat_file($dir, $fil);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Remote|RDA::Object::Remote>,
L<RDA::Object::Ssh|RDA::Object::Ssh>,
L<RDA::Value|RDA::Value>
L<RDA::Value::Array|RDA::Value::Array>
L<RDA::Value::List|RDA::Value::List>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
