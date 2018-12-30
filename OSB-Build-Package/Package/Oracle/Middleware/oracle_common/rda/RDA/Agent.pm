# Agent.pm: Class Used for Objects to Interface with the Diagnostic Agent

package RDA::Agent;

# $Id: Agent.pm,v 2.49 2012/07/23 11:12:27 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Agent.pm,v 2.49 2012/07/23 11:12:27 mschenke Exp $
#
# Change History
# 20120720  LDE  Create extra synonyms.

=head1 NAME

RDA::Agent - Class Used for Objects to Interface with the Diagnostic Agent

=head1 SYNOPSIS

require RDA::Agent;

=head1 DESCRIPTION

The objects of the C<RDA::Agent> class are used to interface with the Remote
Diagnostic Agent (RDA).

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Copy;
  use IO::File;
  use IO::Handle;
  use RDA::Log;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
}

autoflush STDOUT 1;
autoflush STDERR 1;

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.49 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $BLD = '000000';
my $DSC = 'Unknown group';
my $EXT = '(bin|box|csv|dat|err|fil|gif|htm|jar|lin|out|png|toc|txt|zip)';
my $LIN = ('#' x 79)."\n";
my $SEP = '#'.('-' x 78)."\n";

# Define the global private variables
my $re_nam = qr/^S(\d{3})([A-Za-z]\w*)$/i;
my %tb_cap = (
  'end'    => '_end',
  'reload' => '_rel',
  'reset'  => '_rst',
  'stat'   => '_sta',
  'thread' => '_thr',
  );
my @tb_col = qw(skip obsolete partial done pending);
my %tb_col = (
  'pending'  => -1,
  'skip'     => 0,
  'obsolete' => 1,
  'partial'  => 2,
  'done'     => 3,
  );
my %tb_err = (
  'IRDA'  => 'irda.txt',
  'OCM'   => 'ocm.txt',
  'ODRDA' => 'odrda.txt',
  'RDA'   => 'err.txt',
  );
my %tb_fct = (
  'canFork'        => [\&can_fork,        'N'],
  'canThread'      => [\&can_thread,      'B'],
  'displayText'    => [\&_m_dsp_text,     'N'],
  'filterSetting'  => [\&_m_flt_setting,  'L'],
  'forkModules'    => [\&_m_fork_modules, 'L'],
  'getDesc'        => [\&_m_get_desc,     'L'],
  'getSetting'     => [\&_m_get_setting,  'T'],
  'grepSetting'    => [\&_m_grep_setting, 'L'],
  'isVerbose'      => [\&is_verbose,      'B'],
  'log'            => [\&_m_log,          'N'],
  'requestSetting' => [\&_m_req_setting,  'N'],
  'setSetting'     => [\&_m_set_setting,  'T'],
  'setTempSetting' => [\&_m_temp_setting, 'T'],
  'updateUsage'    => [\&_m_upd_usage,    'N'],
  'waitModules'    => [\&_m_wait_modules, 'L'],
  );
my %tb_use = (
  ERR  => 'err',
  NOTE => 'not',
  OUT  => 'out',
  REQ  => 'req',
  SKIP => 'skp',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Agent-E<gt>new([attrname =E<gt> $value,...])>

The object constructor. This method enables you to specify initial attributes
at object creation time.

C<RDA::Agent> is represented by a blessed hash reference. The following special
keys are used:

=over 16

=item S<    B<'aux' > > Associated control object

=item S<    B<'bkp' > > Setup backup flag

=item S<    B<'cfg' > > RDA software configuration

=item S<    B<'con' > > Reference to DOS console input object

=item S<    B<'edt' > > Edit directives

=item S<    B<'inp' > > Input directives

=item S<    B<'lck' > > Lock indicator

=item S<    B<'new' > > New setup indicator

=item S<    B<'oid' > > Setup file name

=item S<    B<'out' > > Disable output

=item S<    B<'own' > > Ownership alignment indicator

=item S<    B<'pid' > > Process identifier list

=item S<    B<'sav' > > Incremental save indicator

=item S<    B<'use' > > Library usage

=item S<    B<'ver' > > Software version

=item S<    B<'vrb' > > Verbose mode indicator

=item S<    B<'yes' > > Auto confirmation flag

=item S<    B<'zip' > > Report archive location

=item S<    B<'_cfg'> > Configuration indicator hash

=item S<    B<'_chg'> > Setting change hash

=item S<    B<'_cnv'> > Reference to the conversion control object

=item S<    B<'_col'> > Hash that controls the data collection

=item S<    B<'_cur'> > Current module name

=item S<    B<'_def'> > Hash that contains the variable definitions

=item S<    B<'_dis'> > Auto discovery object

=item S<    B<'_dsc'> > Hash that contains the module descriptions

=item S<    B<'_dsp'> > Reference to the display control object

=item S<    B<'_end'> > List of libraries requiring end treatment

=item S<    B<'_flg'> > Indicates if the setup is loaded

=item S<    B<'_flk'> > Indicates when flock can be used

=item S<    B<'_frk'> > Indicates if forking can be done

=item S<    B<'_inc'> > Reference to the inline code control object

=item S<    B<'_ini'> > Macro library initialization indicator

=item S<    B<'_lck'> > Lock control object

=item S<    B<'_lib'> > Hash that contains the library objects

=item S<    B<'_log'> > Event log object reference

=item S<    B<'_mac'> > Array of macro definitions

=item S<    B<'_mod'> > Hash that contains the module contents

=item S<    B<'_mrc'> > Reference to the multi-run collection control object

=item S<    B<'_old'> > Original setting hash

=item S<    B<'_opr'> > Operators hash

=item S<    B<'_prf'> > Profile object reference

=item S<    B<'_prq'> > Parallel run hash

=item S<    B<'_pwd'> > Reference to the access control object

=item S<    B<'_rcf'> > Reconfiguration indicator hash

=item S<    B<'_reg'> > Shared information registry

=item S<    B<'_rel'> > List of libraries to reload after setting changes

=item S<    B<'_rem'> > Reference to the remote access control object

=item S<    B<'_req'> > Postponed requisite hash

=item S<    B<'_rpt'> > Reference to the report control object

=item S<    B<'_rst'> > List of libraries to reset

=item S<    B<'_run'> > Hash that contains persistent submodules

=item S<    B<'_set'> > Setting hash

=item S<    B<'_srq'> > Serial run hash

=item S<    B<'_sta'> > List of libraries that provide statistics

=item S<    B<'_tgt'> > Reference to the target control object

=item S<    B<'_thr'> > List of libraries that require thread initialization

=item S<    B<'_tmp'> > Recent temporary settings

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my $cls = shift;
  my ($cfg, $key, $slf, $val);

  # Create the agent object
  $slf = bless {
    bkp  => 1,
    cfg  => {},
    ctl  => '.',
    dir  => 'modules',
    edt  => [],
    hcv  => 'hcve',
    inp  => [],
    lck  => 0,
    lfn  => {},
    new  => 0,
    oid  => 'setup',
    out  => 0,
    own  => 0,
    pid  => [],
    sav  => 1,
    use  => {},
    ver  => $VERSION,
    vrb  => 0,
    yes  => 0,
    _cfg => {},
    _chg => {},
    _col => {},
    _def => {},
    _dsc => {},
    _flg => 0,
    _flk => RDA::Object::Rda->is_vms() ? 0 : 1,
    _frk => 0,
    _ini => 0,
    _lib => {},
    _mac => [],
    _min => 0,
    _mod => {},
    _old => {},
    _reg => {},
    _rel => [],
    _run => {},
    _set => {},
    _sta => [],
    _thr => [],
    _tmp => {},
    }, ref($cls) || $cls;

  # Add the initial attributes
  while (($key, $val) = splice(@_, 0, 2))
  { $val = $key unless defined $val;
    $slf->{$key} = $val;
  }
  if ($slf->{'out'})
  { $slf->{'vrb'} = 0;
    $slf->{'yes'} = 1;
  }

  # Initialize the RDA software configuration
  RDA::Object::Rda->new($slf)->check;

  # Prevent concurrent usage of a same setup file
  if ($slf->{'lck'})
  { eval {
      require RDA::Object::Lock;
      $slf->{'_lck'} = RDA::Object::Lock->new($slf,
        $slf->{'cfg'}->get_group('D_CWD'));
      if  ($slf->{'lck'} > 0)
      { die "RDA-00111: Setup file already in use\n"
          unless $slf->{'_lck'}->lock($slf->{'oid'}, 1);
      }
      else
      { $slf->{'_lck'}->lock('-B-'.$slf->{'oid'});
      }
    };
    die $@ if $@ =~ m/^RDA-/;
  }

  # Initialize the event log
  $slf->{'_log'} = RDA::Log->new($slf);

  # Predefine some settings
  $cfg = $slf->{'cfg'};
  $slf->set_setting('NO_DIALOG',     $slf->{'yes'},
    'B', 'Dialog suppressed');
  $slf->set_setting('NO_OUTPUT',     $slf->{'out'},
    'B', 'Output suppressed');
  $slf->set_setting('RDA_LEVEL',     0,
    'N', 'Setting level');
  $slf->set_setting('RDA_PROFILE',   'Default',
    'T', 'Setup profile');
  $slf->set_setting('RDA_SAVE',      $slf->{'sav'},
    'B', 'Is setup information saved at the end of each module?');
  $slf->set_setting('RDA_VERSION',   $cfg->get_version,
    'T', 'RDA Software version');
  $slf->set_setting('RPT_DIRECTORY', $cfg->get_dir('D_CWD', 'output'),
    'D', 'Report file directory');
  $slf->set_setting('RPT_GROUP',     'RDA',
    'T', 'Report file prefix');

  # Load the setup file and apply temporary changes
  $slf->load unless $slf->{'new'};
  foreach my $rec (@{$slf->{'edt'}})
  { my ($key, $val) = split(/\=/, $rec, 2);
    $val = '' unless defined($val);
    $slf->set_temp_setting($key, $val);
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>can_flock>

This method indicates when flock can be used. It returns a null value when
flock is not available. The return value is negative when fork is emulated.

=cut

sub can_flock
{ shift->{'_flk'};
}

=head2 S<$h-E<gt>can_fork>

This method indicates that RDA can fork processes. It returns a positive value
to indicate that fork is implemented, a negative value when fork is emulated,
and otherwise, zero.

=cut

sub can_fork
{ shift->{'_frk'};
}

=head2 S<$h-E<gt>can_thread>

This method indicates that RDA can use threads. If threads can be used, the
method returns the list of references to libraries that require some
initialization. Otherwise, it returns an undefined value.

=cut

sub can_thread
{ my ($slf) = @_;

  $slf->{'_frk'} ? $slf->{'_thr'} : undef;
}

=head2 S<$h-E<gt>dsp_text($nam[,$flg[,%var]])>

This method displays text. The text can contain variables that are resolved
through the specified hash. When the variable is not defined in the hash,
settings are used. When the flag is set, the method requests a user
acknowledgment before continuing.

=cut

sub dsp_text
{ my ($slf, $nam, $flg, %var) = @_;
  my ($cnt, $key);

  # Extract the text from the file and display it
  $cnt = $slf->get_display->dsp_text($nam, \%var);

  # Get an user acknowledge when requested
  if ($cnt && $flg && !$slf->{'yes'})
  { print "Press 'Enter' to Continue";
    $key = <STDIN>;
  }

  # Indicate the result
  $cnt;
}

=head2 S<$h-E<gt>end>

This method terminates open tasks inside the agent.

=cut

sub end
{ my $slf = shift;

  # Apply libraries end treatment
  foreach my $lib (@{$slf->{'_end'}})
  { $lib->end;
  }

  # Delete the remote access control
  delete($slf->{'_rem'})->delete if exists($slf->{'_rem'});

  # Delete the report control
  delete($slf->{'_rpt'})->delete if exists($slf->{'_rpt'});

  # Delete the target control
  delete($slf->{'_tgt'})->end if exists($slf->{'_tgt'});

  # Log the end event
  $slf->{'_log'}->end;
}

=head2 S<$h-E<gt>get_access($flg)>

This method returns the reference to the access control object.

=cut

sub get_access
{ my ($slf, $flg) = @_;

  # When already allocated, return its reference
  return $slf->{'_pwd'} if exists($slf->{'_pwd'});

  # When not yet done, create it
  require RDA::Object::Access;
  $slf->{'_pwd'} = RDA::Object::Access->new($slf, $flg);
}

sub ask_password
{ shift->get_access->ask_password(@_);
}

=head2 S<$h-E<gt>get_config>

This method returns the reference to the RDA software configuration.

=cut

sub get_config
{ shift->{'cfg'};
}

*config = \&get_config;

=head2 S<$h-E<gt>get_convert>

This method creates the XML conversion object and returns a reference to it.

=cut

sub get_convert
{ my ($slf, $flg) = @_;

  # When already allocated, return its reference
  return $slf->{'_cnv'} if exists($slf->{'_cnv'});

  # When not yet done, create it
  require RDA::Object::Convert;
  $slf->{'_cnv'} = RDA::Object::Convert->new($slf->get_output($flg));
}

*convert = \&get_convert;

=head2 S<$h-E<gt>get_daemon>

This method creates the daemon object and returns a reference to it.

=cut

sub get_daemon
{ my $slf = shift;

  require RDA::Daemon;
  RDA::Daemon->new($slf);
}

*daemon = \&get_daemon;

=head2 S<$h-E<gt>get_discover>

This method returns the auto discovery object when product information is
available. Otherwise, it returns an undefined value.

=cut

sub get_discover
{ my ($slf) = @_;
  my ($dir, $obj);

  # Get the auto discovery object
  if (exists($slf->{'_dis'}))
  { $obj = $slf->{'_dis'};
  }
  elsif (($dir = $slf->get_setting('ORACLE_HOME')) && -d $dir)
  { require RDA::Discover;
    $slf->{'_dis'} = $obj = RDA::Discover->new($slf, $dir);
  }

  # Return it when product information is available
  ($obj && $obj->get_type) ? $obj : undef;
}

*discover = \&get_discover;

=head2 S<$h-E<gt>get_display>

This method creates the object to control the display and returns a reference
to it.

=cut

sub get_display
{ my ($slf) = @_;

  # When already allocated, return its reference
  return $slf->{'_dsp'} if exists($slf->{'_dsp'});

  # When not yet done, create it
  require RDA::Object::Display;
  $slf->{'_dsp'} = RDA::Object::Display->new($slf);
}

*display = \&get_display;

=head2 S<$h-E<gt>get_inline>

This method creates the inline code control object and returns a reference to
it.

=cut

sub get_inline
{ my ($slf) = @_;

  # When already allocated, return its reference
  return $slf->{'_inc'} if exists($slf->{'_inc'});

  # When not yet done, create it
  require RDA::Object::Inline;
  $slf->{'_inc'} = RDA::Object::Inline->new($slf);
}

=head2 S<$h-E<gt>get_info($key[,$default])>

This method returns the value of the given object key. If it does not exist,
RDA returns the default value.

=cut

sub get_info
{ my ($slf, $key, $val) = @_;

  $val = $slf->{$key} if exists($slf->{$key});
  $val;
}

=head2 S<$h-E<gt>get_mrc>

This method creates a multi-run collection control object and returns a
reference to it.

=cut

sub get_mrc
{ my ($slf, $flg) = @_;

  # When already allocated, return its reference
  return $slf->{'_mrc'} if exists($slf->{'_mrc'});

  # When not yet done, create it
  require RDA::Object::Mrc;
  $slf->{'_mrc'} = RDA::Object::Mrc->new($slf);
}

*mrc = \&get_mrc;

=head2 S<$h-E<gt>get_oid>

This method returns the object identifier.

=cut

sub get_oid
{ shift->{'oid'};
}

=head2 S<$h-E<gt>get_output([$flag])>

This method creates the object to control the output and returns a reference to
it. Setting the flag disables any output postprocessing.

=cut

sub get_output
{ my ($slf, $flg) = @_;

  # When already allocated, return its reference
  return $slf->{'_rpt'} if exists($slf->{'_rpt'});

  # When not yet done, create it
  require RDA::Object::Output;
  $slf->{'_rpt'} = RDA::Object::Output->new($slf, $flg);
}

*output = \&get_output;

=head2 S<$h-E<gt>get_profile>

This method creates the object to manage the profiles and returns a reference
to it.

=cut

sub get_profile
{ my ($slf) = @_;

  # When already allocated, return its reference
  return $slf->{'_prf'} if ref($slf->{'_prf'});

  # When not yet done, define the profile environment
  require RDA::Profile;
  $slf->{'_prf'} = RDA::Profile->new($slf->{'cfg'}->get_group('D_RDA_DATA'),
    $slf);
}

*profile = \&get_profile;

=head2 S<$h-E<gt>get_registry($key[,$fct,$arg,...])>

This method returns the value of the shared information associated to the
specified key. When it does not exist, it uses the provided function to
collect it.

=cut

sub get_registry
{ my ($slf, $key, $fct, @arg) = @_;

  exists($slf->{'_reg'}->{$key}) ? $slf->{'_reg'}->{$key} :
  (ref($fct) eq 'CODE')          ? $slf->{'_reg'}->{$key} = &$fct(@arg) :
                                   undef;
}

=head2 S<$h-E<gt>get_remote>

This method returns the reference to the remote access control object.

=cut

sub get_remote
{ my ($slf) = @_;

  # When already allocated, return its reference
  return $slf->{'_rem'} if exists($slf->{'_rem'});

  # When not yet done, create it
  require RDA::Object::Remote;
  $slf->{'_rem'} = RDA::Object::Remote->new($slf);
}

=head2 S<$h-E<gt>get_render>

This method creates the render object and returns a reference to it.

=cut

sub get_render
{ my ($slf, $flg) = @_;

  require RDA::Render;
  RDA::Render->new($slf->get_output($flg));
}

*render = \&get_render;

=head2 S<$h-E<gt>get_target>

This method creates the target control object and returns a reference to it.

=cut

sub get_target
{ my ($slf) = @_;

  # When already allocated, return its reference
  return $slf->{'_tgt'} if exists($slf->{'_tgt'});

  # When not yet done, create it
  require RDA::Object::Target;
  $slf->{'_tgt'} = RDA::Object::Target->new($slf);
}

=head2 S<$h-E<gt>is_verbose>

This method indicates whether RDA runs in verbose mode.

=cut

sub is_verbose
{ shift->{'vrb'};
}

=head2 S<$h-E<gt>set_info($key,$value)>

This method assigns the value to the given object key. It returns the previous
value.

=cut

sub set_info
{ my ($slf, $key, $val) = @_;

  ($val, $slf->{$key}) = ($slf->{$key}, $val);
  $val;
}

=head1 MACRO AND OPERATORS MANAGEMENT METHODS

=head2 S<$h-E<gt>get_libraries($cap)>

This method returns the control objects of libraries that have the specified
capability.

=cut

sub get_libraries
{ my ($slf, $cap) = @_;

  return () unless $cap && exists($tb_cap{$cap});
  @{$slf->{$tb_cap{$cap}}};
}

=head2 S<$h-E<gt>get_macros($ref)>

This method initializes a hash with all known macros. The reference to that
hash is passed as an argument.

=cut

sub get_macros
{ my ($slf, $ref, $dbg) = @_;

  init($slf, $dbg) unless $slf->{'_ini'}++;

  foreach my $lib (@{$slf->{'_mac'}})
  { my $obj = $lib->[0];
    foreach my $nam (@{$lib->[1]})
    { $ref->{$nam} = $obj;
    }
  }
}

=head2 S<$h-E<gt>get_operators>

This method returns the definition of all known operators.

=cut

sub get_operators
{ my ($slf, $dbg) = @_;

  exists($slf->{'_opr'})
    ? $slf->{'_opr'}
    : _load_operators($slf, $dbg, 
        {map {$_ => 1} RDA::Object::Rda::get_obsolete($slf->{'cfg'}, 'opr')},
        RDA::Object::Rda::get_group($slf->{'cfg'}, 'D_RDA_PERL'),
        'RDA', 'Operator');
}

sub _load_operators
{ my ($slf, $dbg, $skp, $top, @dir) = @_;
  my ($cls, $pth, @sub);

  # Load the operators
  $slf->{'_opr'} = {};
  if (opendir(LIB, $pth = RDA::Object::Rda->cat_dir($top, @dir)))
  { foreach my $sub (readdir(LIB))
    { next if $sub =~ m/^\./ || $sub eq 'CVS';
      $sub = ucfirst(lc($sub));
      if ($sub =~ s/\.pm$//)
      { $cls = join('::', @dir, $sub);
        next if exists($skp->{$cls});
        eval "require $cls";
        if ($@)
        { print $@ if $dbg;
        }
        else
        { $cls->load($slf->{'_opr'});
        }
      }
      else
      { $sub = ucfirst(lc($sub));
        $sub =~ s/\.dir$//;
        push(@sub, $sub) if -d RDA::Object::Rda->cat_dir($pth, $sub);
      }
    }
    closedir(LIB);
  }

  # Treat subdirectories
  foreach my $sub (@sub)
  { _load_operators($slf, $dbg, $skp, $top, @dir, $sub);
  }

  # Return the operator definition hash
  $slf->{'_opr'};
}

=head2 S<$h-E<gt>init([$debug[,$log]])>

This method initializes the macro library with predefined macros. When the
debug flag is set, it reports macro load problems. When the log flag is set,
it verifies that the log file is available. If it is not available, then RDA
creates the log file.

=cut

sub init
{ my ($slf, $dbg, $log) = @_;
  my ($rul);

  # Take a copy of the environment
  eval "require RDA::Object::Env";
  $slf->get_registry('env', sub {RDA::Object::Env->new}) unless $@;

  # Preload Digest::MD5, POSIX, and Socket when available
  eval "require Digest::MD5";
  eval {
    require POSIX;
    POSIX::setlocale(&POSIX::LC_ALL, 'C');
    };
  eval "require Compress::Zlib";
  eval "require DBI";
  eval "require Socket";
  eval "require Time::HiRes";

  # Check if fork can be done
  if ($slf->get_setting('RDA_FORK', 1))
  { eval {
      my $pid;

      die "No fork\n" if RDA::Object::Rda->is_vms() || !defined($pid = fork());
      exit(0) unless $pid;
      waitpid($pid, 0);
      if ($pid < 0)
      { $slf->{'_frk'} = -1;
        $slf->{'_flk'} = -$slf->{'_flk'};
      }
      else
      { $slf->{'_frk'} = 1;
      }
    };
  }
  
  # Add macros to the libraries
  $slf->register($slf, [keys(%tb_fct)]);
  _load_libraries($slf, $dbg,
    {map {$_ => 1} RDA::Object::Rda::get_obsolete($slf->{'cfg'}, 'lib')},
    RDA::Object::Rda::get_group($slf->{'cfg'}, 'D_RDA_PERL'),
    'RDA', 'Library');

  # Load the operators
  $slf->get_operators($dbg);

  # Adapt the environment variables so we get the output from all the tools
  delete($ENV{'LANG'});
  $ENV{'NLS_LANG'} = 'AMERICAN_AMERICA.US7ASCII';
  delete($ENV{'TWO_TASK'});
  delete($ENV{'SQLPATH'});
  $slf->get_target;

  # Take care that the log file is available
  $slf->{'_log'}->init($slf->get_setting('RPT_DIRECTORY'), $log);

  # Return the object reference
  $slf;
}

sub _load_libraries
{ my ($slf, $dbg, $skp, $top, @dir) = @_;
  my ($cls, $pth, @sub);

  # Load the libraries
  if (opendir(LIB, $pth = RDA::Object::Rda->cat_dir($top, @dir)))
  { foreach my $sub (readdir(LIB))
    { next if $sub =~ m/^\./ || $sub eq 'CVS';
      $sub = ucfirst(lc($sub));
      if ($sub =~ s/\.pm$//)
      { $cls = join('::', @dir, $sub);
        next if exists($skp->{$cls});
        eval "require $cls";
        if ($@)
        { print $@ if $dbg;
        }
        else
        { $cls->new($slf);
        }
      }
      else
      { $sub = ucfirst(lc($sub));
        $sub =~ s/\.dir$//;
        push(@sub, $sub) if -d RDA::Object::Rda->cat_dir($pth, $sub);
      }
    }
    closedir(LIB);
  }

  # Treat subdirectories
  foreach my $sub (@sub)
  { _load_libraries($slf, $dbg, $skp, $top, @dir, $sub);
  }
}

=head2 S<$h-E<gt>register($obj,$list[,$cap,...])>

This method registers a list of macros associated with the specified object. You
can specify a list of additional capabilities such as C<stat> for statistics,
and C<thread> for thread initialization.

=cut

sub register
{ my $slf = shift;
  my $obj = shift;
  my $lst = shift;
  my ($cls);

  if (exists($slf->{'_lib'}->{$cls = ref($obj)}))
  { $slf->{'_mac'} = [map {[(ref($_->[0]) eq $cls) ? $obj : $_->[0], $_->[1]]}
                          @{$slf->{'_mac'}}];
    foreach my $key (values(%tb_cap))
    { $slf->{$key} = [map {(ref($_) eq $cls) ? $obj : $_} @{$slf->{$key}}]
    }
  }
  else
  { push(@{$slf->{'_mac'}}, [$obj, $lst]);
    foreach my $cap (@_)
    { push(@{$slf->{$tb_cap{$cap}}}, $obj) if exists($tb_cap{$cap});
    }
  }
  $slf->{'_lib'}->{$cls} = $obj;
}

=head2 S<$h-E<gt>reload_libraries>

This method resets the default target and reloads libraries.

=cut

sub reload_libraries
{ my ($slf) = @_;
  my ($cls, %tbl);

  # Reset the default target
  $slf->{'_tgt'}->init if exists($slf->{'_tgt'});

  # Reload libraries
  %tbl = map {ref($_) => 1} @{$slf->{'_end'}};
  foreach my $obj (@{$slf->{'_rel'}})
  { $cls = ref($obj);
    $obj->end if exists($tbl{$cls});
    $cls->new($slf);
  }
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method runs the macro with the specified argument list, in a given context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  require RDA::Value;
  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a boolean
  return RDA::Value::Scalar::new_number(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array) ? 1 : 0) if $typ eq 'B';

  # Treat a scalar context
  $ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array);
  $typ = 'U' unless defined($ret);
  RDA::Value::Scalar->new($typ, $ret);
}

=head1 SETUP MANAGEMENT METHODS

=head2 S<$h-E<gt>backup_settings>

This method backs up the setting definition.

=cut

sub backup_settings
{ my ($slf) = @_;
  my ($bkp, $cur);
  
  # Backup the setting definitions
  $bkp = {};
  $bkp->{'_def'} = {%{$slf->{'_def'}}};
  $bkp->{'_old'} = {%{$slf->{'_old'}}};
  $bkp->{'_set'} = {%{$slf->{'_set'}}};
  $bkp->{'_tmp'} = {%{$slf->{'_tmp'}}};
  if (exists($slf->{'_cur'}))
  { $bkp->{'_cur'} = $cur = $slf->{'_cur'};
    $bkp->{'_mod'} = [@{$slf->{'_mod'}->{$cur}}]
      if exists($slf->{'_mod'}->{$cur});
  }

  # Reset the setting change indicators
  $bkp->{'_chg'} = $slf->{'_chg'};
  $slf->{'_chg'} = {};

  # Return the reference to the backup hash
  $bkp;
}

=head2 S<$h-E<gt>clr_temp_setting($key)>

This method restores the original setting value. It returns that value or
C<undef> if not previously defined.

=cut

sub clr_temp_setting
{ my ($slf, $key) = @_;
  my $old;

  # Restore the original setting value
  if (exists($slf->{'_old'}->{$key}))
  { $old = $slf->{'_old'}->{$key};
    if (defined($old))
    { $slf->{'_set'}->{$key} = $old;
    }
    else
    { delete($slf->{'_set'}->{$key});
    }
    delete($slf->{'_old'}->{$key});
    delete($slf->{'_tmp'}->{$key});
  }

  # Return the previous value
  $old;
}

=head2 S<$h-E<gt>del_module($name)>

This method deletes a module and adds an event (type 'D') in the event log. It
returns the list of settings that were previously associated with the module.

=cut

sub del_module
{ my ($slf, $nam) = @_;
  my (@tbl);

  # Save the previous definition
  @tbl = @{$slf->{'_mod'}->{$nam}} if exists($slf->{'_mod'}->{$nam});

  # Delete the module
  delete($slf->{'_dsc'}->{$nam});
  delete($slf->{'_mod'}->{$nam});
  delete($slf->{'_col'}->{$nam}) unless $slf->is_done($nam);
  $slf->log('D', $nam);

  # Delete the module variable definitions
  foreach my $key (@tbl)
  { delete($slf->{'_def'}->{$key});
  }

  # Return the variables previously associated with the module
  @tbl;
}

=head2 S<$h-E<gt>del_setting($key)>

This method deletes a setting from the setup information. It returns the
previous value or C<undef> if not previously defined.

=cut

sub del_setting
{ my ($slf, $key) = @_;
  my $old;

  # Get the previous value
  $old = $slf->{'_set'}->{$key} if exists($slf->{'_set'}->{$key});

  # Delete the variable
  delete($slf->{'_tmp'}->{$key});
  delete($slf->{'_old'}->{$key});
  delete($slf->{'_set'}->{$key});
  delete($slf->{'_def'}->{$key});

  # Indicate the change
  $slf->{'_chg'}->{$key} = 0;

  # Return the previous value
  $old;
}

=head2 S<$h-E<gt>dsp_module($name[,$all])>

This method extracts the setup questions of a module. When the second argument
is set, it disables family restrictions.

=cut

sub dsp_module
{ my ($slf, $nam, $all, $flg) = @_;
  my $obj;

  require RDA::Module;
  $obj = RDA::Module->new($nam, $slf->{'cfg'}->get_group('D_RDA_CODE'), $slf);

  $obj->load($slf)             ? $obj->display($slf, $all, $flg) :
  ($nam =~ $re_nam
    && $slf->is_defined($nam)) ? 'No setup specifications' :
                                 '';
}

=head2 S<$h-E<gt>end_setup([$save])>

This method performs the remaining setup operations.

=cut

sub end_setup
{ my ($slf, $sav) = @_;

  if (exists($slf->{'_req'}))
  { my ($tbl);

    foreach my $nam (sort keys(%{$tbl = delete($slf->{'_req'})}))
    { $slf->setup($nam, $tbl->{$nam}, $sav)
        unless $slf->is_reconfigured($nam);
    }
  }
}

=head2 S<$h-E<gt>exists_setting($key)>

This method indicates if a setting exists.

=cut

sub exists_setting
{ my ($slf, $key) = @_;

  exists($slf->{'_set'}->{$key});
}

=head2 S<$h-E<gt>extract_settings>

This method extracts the setting changes.

=cut

sub extract_settings
{ my ($slf) = @_;
  my ($buf, $typ, $val);

  $buf = '';
  foreach my $var (sort keys(%{$slf->{'_chg'}}))
  { if ($slf->{'_chg'}->{$var})
    { if (exists($slf->{'_def'}->{$var}))
      { ($typ, $val) = @{$slf->{'_def'}->{$var}};
        $buf .= "T=$var=$typ.$val\n";
      }
      $val = exists($slf->{'_old'}->{$var})
        ? $slf->{'_old'}->{$var}
        : $slf->{'_set'}->{$var};
      $val =~ s/'/&\#39;/g;
      $val =~ s/\n/&\#10;/g;
      $buf .= "S=$var=$val\n";
    }
    else
    { $buf .= "D=$var\n";
    }
  }
  $buf;
}

=head2 S<$h-E<gt>get_setting($key[,$default[,$flag]])>

This method returns the value of the given setup key. If it does not exist, it
returns the default value. When the flag is set, it substitutes variables in
the value.

=cut

sub get_setting
{ my ($slf, $key, $val, $flg) = @_;

  # Get the setting value
  $val = $slf->{'_set'}->{$key} if exists($slf->{'_set'}->{$key});

  # Replace variables
  if ($flg)
  { my ($str, $var);

    while ($val =~ m/(\$\{(\w+)(\:([^\}]*))?\})/)
    { $var = $1;
      $str = defined($4) ? $4 : '';
      $str = $slf->get_setting($2, $str);
      $val =~ s/\Q$var\E/$str/g;
    }
  }

  # Return the value
  $val;
}

=head2 S<$h-E<gt>get_title($nam[,$dft])>

This method returns a short description (title) of the specified module. It
returns the default value when it can retrieve the title.

=cut

sub get_title
{ my ($slf, $nam, $ttl) = @_;

  # Try to extract it from the setup
  return $slf->{'_dsc'}->{$nam} if exists($slf->{'_dsc'}->{$nam});

  # Try to extract it from the definition file
  if (open(DEF, '<'.$slf->{'cfg'}->get_file('D_RDA_CODE', $nam, '.def')) ||
      open(DEF, '<'.$slf->{'cfg'}->get_file('D_RDA_CODE', $nam, '.ctl')))
  { my $lin = <DEF>;
    close(DEF);
    return $2 if $lin && $lin =~ m/#\s*$nam(.def)?:\s*(.*)[\s\n\r]+$/i;
  }

  # Return the default title
  $ttl;
}

=head2 S<$h-E<gt>grep_setting($re,$opt)>

This method returns the setting names that match the regular expression. It
supports the following options:

=over 9

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the results

=item B<    'n' > Sorts the settings by their name

=item B<    'v' > Inverts the sense of matching to select nonmatching lines

=back

=cut

sub grep_setting
{ my ($slf, $re, $opt) = @_;
  my ($flg, $inv, $one, @tbl);

  # Determine the options
  $opt = '' unless defined($opt);
  $one = index($opt, 'f') >= 0;
  $re = (index($opt, 'i') < 0) ? qr/$re/ : qr/$re/i;
  $inv = index($opt, 'v') >= 0;

  # Scan the setting names
  foreach my $key (keys(%{$slf->{'_set'}}))
  { $flg = ($key =~ $re);
    if ($inv ? !$flg : $flg)
    { push(@tbl, $key);
      last if $one;
    }
  }
  return sort @tbl if index($opt, 'n') >= 0;
  @tbl;
}

=head2 S<$h-E<gt>is_configured([$name])>

This method indicates if a module is configured already. When no argument is
specified, it indicates whether a setup file has been loaded.

=cut

sub is_configured
{ my ($slf, $nam) = @_;

  return $slf->{'_flg'} unless defined($nam);
  exists($slf->{'_cfg'}->{$nam}) && $slf->{'_cfg'}->{$nam};
}

=head2 S<$h-E<gt>is_reconfigured($name)>

This method indicates if a module has been configured already during this RDA
execution.

=cut

sub is_reconfigured
{ my ($slf, $nam) = @_;

  $nam && exists($slf->{'_rcf'}->{$nam}) && $slf->{'_rcf'}->{$nam};
}

=head2 S<$h-E<gt>load([$file])>

This method loads the current setup (if a setup exists). You can specify an
alternative setup file as an argument.

=cut

sub load
{ my ($slf, $fil) = @_;
  my ($cfg, $dsc, $key, $typ, $val);

  # Determine the setup file name
  $cfg = $slf->{'cfg'};
  $fil = $cfg->get_file('D_CWD', $slf->{'oid'}, '.cfg') unless defined($fil);

  # Load and parse the setup information
  if (open(IN, "<$fil"))
  { $slf->set_current('?');
    while (<IN>)
    { # Trim the end of line
      s/[\r\n]+$//;

      # Treat the line
      if (m/^(\w+)='([^']*)'/ || m/^(\w+)="([^"]*)"/)
      { $key = $1;
        $val = $2;
        $val =~ s/&\#10;/\n/g;
        $val =~ s/&\#34;/"/g;
        $val =~ s/&\#39;/'/g;
        $slf->set_setting($key, $val, $typ, $dsc);
        $dsc = $typ = undef;
      }
      elsif (m/^(\w+)=(.*)$/)
      { $slf->set_setting($1, $2, $typ, $dsc);
        $dsc = $typ = undef;
      }
      elsif (m/^#([\?BDEFILMNPT])\.\s*(.*)$/)
      { $typ = $1;
        $dsc = $2;
      }
      elsif (m/^#\s*(\w+)=(done|obsolete|partial|pending|skip)/i)
      { $slf->{'_col'}->{$1} = $tb_col{lc($2)};
        $slf->{'_cfg'}->{$1} = ($2 eq uc($2)) ? -1 : 0
          unless exists($slf->{'_cfg'}->{$1});
      }
      elsif (m/^#\s*(\w+):\s*(.*)$/)
      { $slf->set_current($1, $2 || '');
        $slf->{'_col'}->{$1} = -1 unless exists($slf->{'_col'}->{$1});
        $slf->{'_cfg'}->{$1} = 1;
      }
      elsif (!m/^\s*(#.*)?$/)
      { die "RDA-00101: Invalid setup file '$fil'\n";
      }
    }
    close(IN);

    # Update an old setup file
    $val = $cfg->get_build;
    if ($slf->get_setting('RDA_BUILD', $BLD) lt $val)
    { eval {
        require RDA::Upgrade;
        RDA::Upgrade::setup($slf);
        $slf->set_setting('RDA_BUILD', $val);
      };
    }

    # Adjust agent attributes
    $slf->set_current;
    $slf->{'_flg'} = 1;
    $slf->{'sav'}  = $slf->get_setting('RDA_SAVE');
    $slf->{'ver'}  = $slf->get_setting('RDA_VERSION');
    $cfg->set_domain($slf->get_setting('DOMAIN_NAME'));

    # Initialize the log file
    delete($slf->{'_rpt'});
    $slf->{'_log'}->init($slf->get_setting('RPT_DIRECTORY'));
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>load_settings($ifh)>

This method loads the setting changes. It closes the file handle on load
completion.

=cut

sub load_settings
{ my ($slf, $ifh) = @_;
  my ($act, $def, $dsc, $typ, $val, $var);

  while (<$ifh>)
  { s/[\n\r]+$//;
    ($act, $var, $val) = split(/=/, $_, 3);
    if ($act eq 'D')
    { $slf->del_setting($var);
      $def = undef;
    }
    elsif ($act eq 'S')
    { $val =~ s/&\#10;/\n/g;
      $val =~ s/&\#34;/"/g;
      $val =~ s/&\#39;/'/g;
      if (defined($def))
      { ($typ, $dsc) = split(/\./, $def, 2);
        $slf->set_setting($var, $val, $typ, $dsc);
        $def = undef;
      }
      else
      { $slf->set_setting($var, $val);
      }
    }
    elsif ($act eq 'T')
    { $def = $val;
    }
  }
  $ifh->close;
}

=head2 S<$h-E<gt>ren_module($old,$new)>

This method renames a module.

=cut

sub ren_module
{ my ($slf, $old, $new) = @_;

  $slf->{'_cfg'}->{$new} = delete($slf->{'_cfg'}->{$old})
    if exists($slf->{'_cfg'}->{$old});
  $slf->{'_col'}->{$new} = delete($slf->{'_col'}->{$old})
    if exists($slf->{'_col'}->{$old});
  $slf->{'_dsc'}->{$new} = delete($slf->{'_dsc'}->{$old})
    if exists($slf->{'_dsc'}->{$old});
  $slf->{'_mod'}->{$new} = delete($slf->{'_mod'}->{$old})
    if exists($slf->{'_mod'}->{$old});
  $slf->{'_rcf'}->{$new} = delete($slf->{'_rcf'}->{$old})
    if exists($slf->{'_rcf'}->{$old});
}

=head2 S<$h-E<gt>restore_settings($bkp)>

This method restores the setting definitions. It returns 1 on a successful
completion. Otherwise, it returns 0.

=cut

sub restore_settings
{ my ($slf, $bkp) = @_;
  my ($cur);
  
  # Abort when no backup is available
  return 0 unless ref($bkp);

  # Backup the setting definitions
  $slf->{'_chg'} = $bkp->{'_chg'};
  $slf->{'_def'} = $bkp->{'_def'};
  $slf->{'_old'} = $bkp->{'_old'};
  $slf->{'_set'} = $bkp->{'_set'};
  $slf->{'_tmp'} = $bkp->{'_tmp'};
  if (exists($bkp->{'_cur'}))
  { $slf->{'_cur'} = $cur = $bkp->{'_cur'};
    if (exists($bkp->{'_mod'}))
    { $slf->{'_mod'}->{$cur} = $bkp->{'_mod'};
    }
    else
    { delete($slf->{'_mod'}->{$cur});
    }
  }

  # Indicate a successful completion
  1;
}

=head2 S<$h-E<gt>save([$file])>

This method saves the setup. You can specify an alternative file name as an
argument. When requested, the original setup file is renamed on first call.

=cut

sub save
{ my ($slf, $fil) = @_;
  my ($cfg, $ctl, $dsc, $gid, $ofh, $tbl, $typ, $uid, $val,
      $tb_col, $tb_def, $tb_dsc, $tb_old, $tb_set, @fil);

  # Initialization
  $tb_def = $slf->{'_def'};
  $tb_dsc = $slf->{'_dsc'};
  $tb_old = $slf->{'_old'};
  $tb_set = $slf->{'_set'};

  # Determine the setup file name
  $cfg = $slf->{'cfg'};
  $fil = $cfg->get_file('D_CWD', $slf->{'oid'}, '.cfg') unless defined($fil);

  # Temporarily disable signals
  local $SIG{'HUP'}  = 'IGNORE' if exists($SIG{'HUP'});
  local $SIG{'INT'}  = 'IGNORE' if exists($SIG{'INT'});
  local $SIG{'KILL'} = 'IGNORE' if exists($SIG{'KILL'});
  local $SIG{'STOP'} = 'IGNORE' if exists($SIG{'STOP'});
  local $SIG{'TERM'} = 'IGNORE' if exists($SIG{'TERM'});
  local $SIG{'QUIT'} = 'IGNORE' if exists($SIG{'QUIT'});

  # Backup the setup file
  $slf->{'bkp'} = 0 unless -f $fil;
  if ($slf->{'bkp'})
  { my $bkp = $fil;
    $bkp =~ s/(\.cfg)?$/.bak/i;
    1 while unlink($bkp);
    rename ($fil, $bkp)
      or die "RDA-00110: Cannot backup the setup file '$fil':\n $!\n";
    $slf->{'bkp'} = 0;
  }

  # Write the setup file
  1 while unlink($fil);
  $ofh = IO::File->new;
  $ofh->open($fil, $CREATE, $FIL_PERMS)
    or die "RDA-00100: Cannot create the setup file '$fil':\n $!\n";
  print {$ofh} $LIN, "# Oracle Remote Diagnostic Agent - Setup Information\n",
    $LIN, "\n";

  print {$ofh} $SEP, "# Data Collection Overview\n", $SEP;
  $tbl = $slf->{'_col'};
  foreach my $mod (sort keys(%$tbl))
  { $dsc = $tb_col[$tbl->{$mod}];
    $dsc = uc($dsc) if $slf->{'_cfg'}->{$mod} < 0;
    print {$ofh} '# ', $mod, '=', $dsc, "\n";
  }
  print {$ofh} "\n";

  $tbl = $slf->{'_mod'};
  foreach my $mod (sort keys(%$tbl))
  { next unless $slf->is_configured($mod);
    $dsc = $tb_dsc->{$mod} || $slf->get_title($mod, '');
    print {$ofh} $SEP, '# ', $mod, ': ', $dsc, "\n", $SEP;
    foreach my $var (@{$tbl->{$mod}})
    { next unless exists($tb_def->{$var});
      ($typ, $dsc) = @{$tb_def->{$var}};
      $val = exists($tb_old->{$var}) ? $tb_old->{$var} : $tb_set->{$var};
      if (index('BN', $typ) < 0)
      { $val =~ s/'/&\#39;/g;
        $val =~ s/\n/&\#10;/g;
        $val = "'$val'";
      }
      print {$ofh} '#', $typ, '.', $dsc, "\n", $var, '=', $val, "\n";
    }
    print {$ofh} "\n";
  }
  $ofh->close;
  push(@fil, $fil);

  # Save the multi-run collection indicators
  $ctl = $slf->get_output;
  $fil = RDA::Object::Rda->cat_file($ctl->get_path('C', 1),
    $ctl->get_group.'_mrc.fil');
  if ($ofh->open($fil, $CREATE, $FIL_PERMS))
  { foreach my $key ($slf->grep_setting('_MRC$', 'n'))
    { print {$ofh} substr($key, 0, -4)."\n" if $slf->get_setting($key);
    }
    $ofh->close;
    push(@fil, $fil);
  }

  # Adjust the ownership
  if ($slf->{'own'})
  { ($uid, $gid) = $ctl->get_owner;
    chown($uid, $gid, @fil) if defined($uid);
  }

  # Resync agent information
  $cfg->set_domain($slf->get_setting('DOMAIN_NAME'));
  $slf->{'sav'} = $slf->get_setting('RDA_SAVE');
  $slf->{'ver'} = $slf->get_setting('RDA_VERSION');

  # Return the configuration object reference
  $slf;
}

=head2 S<$h-E<gt>set_current([$nam[,$dsc]])>

This method sets the current module. When you provide a description, it defines
the module in the setup configuration also. When no name is provided, the
current module is cleared.

=cut

sub set_current
{ my ($slf, $nam, $dsc) = @_;

  if (defined($nam))
  { # Set the current module
    $slf->{'_cur'} = $nam;

    # Add the module in the setup configuration
    if (defined($dsc))
    { $slf->{'_dsc'}->{$nam} = $dsc;
      $slf->{'_mod'}->{$nam} = []   unless exists($slf->{'_mod'}->{$nam});
    }
  }
  else
  { delete($slf->{'_cur'});
  }
}

=head2 S<$h-E<gt>set_setting($key,$val[,$typ,$dsc])>

This method assigns a new value to a setting or creates a new setting. It
permits users to specify the setting type and description also. It adds new
settings to the current module automatically. You can use a special type, C<->, to store
a temporary setting.

It returns the previous value or C<undef> if it is not defined previously.

=cut

sub set_setting
{ my ($slf, $key, $val, $typ, $dsc) = @_;
  my $old;

  # Get the previous value
  $old = $slf->{'_set'}->{$key} if exists($slf->{'_set'}->{$key});

  # Discard any saved value
  delete($slf->{'_old'}->{$key});

  # Store the setting value
  $val = '' unless defined($val);
  $slf->{'_set'}->{$key} = $val;

  # Indicate the change
  $slf->{'_chg'}->{$key} = 1;

  # Define the setting
  unless (defined($typ) && $typ eq '-')
  { # Add the setting definition
    if (defined($typ) || defined($dsc) || !exists($slf->{'_def'}->{$key}))
    { $typ = 'T'  unless defined($typ);
      $dsc = $key unless defined($dsc);
      $slf->{'_def'}->{$key} = [$typ, $dsc];
    }

    # Add a new setting in the content of the current module
    if ($typ && $dsc && exists($slf->{'_cur'}))
    { my $mod = $slf->{'_cur'};
      for (@{$slf->{'_mod'}->{$mod}})
      { return $old if $_ eq $key;
      }
      push(@{$slf->{'_mod'}->{$mod}}, $key);
    }
  }

  # Return the previous value
  $old;
}

=head2 S<$h-E<gt>set_temp_setting($key,$val)>

This method assigns a temporary value to a setting and does not save the change
in the setup file. It returns the original setting value or C<undef> if it is
not defined previously.

=cut

sub set_temp_setting
{ my ($slf, $key, $val) = @_;
  my $old;

  # Get the previous value
  $old = $slf->{'_set'}->{$key} if exists($slf->{'_set'}->{$key});

  # Store the original setting value
  unless (exists($slf->{'_old'}->{$key}))
  { $slf->{'_old'}->{$key} = $old;
    $slf->{'_tmp'}->{$key} = 0;
  }

  # Assign the temporary value
  $slf->{'_set'}->{$key} = $val;

  # Return the previous value
  $old;
}

=head2 S<$h-E<gt>setup($name[,$trace[,$save[,$selected]]])>

This method collects the setup information for a specific module and then adds
an event (type 'S') to the event log. When setup is complete, the method
deletes all temporary settings created by the module. If the save flag is set,
then the setup file is saved. The C<RDA_SAVE> setting specifies the default
flag value.

=cut

sub setup
{ my ($slf, $nam, $trc, $sav, $sel) = @_;
  my ($obj, $val, @req);

  # Determine if the setup file must save at setup end
  $sav = $slf->{'sav'} unless defined($sav);

  # Collect the setup for the module
  require RDA::Module;
  $obj = RDA::Module->new($nam, $slf->{'cfg'}->get_group('D_RDA_CODE'));
  if ($obj->load($slf))
  { # Collect the module settings
    $slf->{'_cfg'}->{$nam} = $slf->{'_rcf'}->{$nam} = 1;
    $slf->{'_tmp'} = {};
    @req = $obj->setup($slf->get_setting('RDA_LEVEL', 0), $trc, $sav, $sel);
    $slf->log('S', $nam, $obj->get_version);

    # Delete the temporary settings created by the module
    foreach my $key (keys(%{$slf->{'_tmp'}}))
    { $slf->clr_temp_setting($key);
    }

    # When requested, save the setup file
    $slf->save if $sav;
  }
  elsif ($slf->is_defined($nam) && $nam =~ $re_nam)
  { # Indicate that there are no setup specifications
    $slf->{'_cfg'}->{$nam} = $slf->{'_rcf'}->{$nam} = -1;
    $slf->{'_col'}->{$nam} = exists($slf->{'_col'}->{$nam}) ? 1 : -1;

    # When requested, save the setup file
    $slf->save if $sav;
  }

  # Setup the post-requisites
  foreach my $req (@req)
  { if ($req =~ s/^\+//)
    { $slf->setup($req, $trc, $sav)
        unless $slf->is_described($req) || $slf->is_disabled($nam);
    }
    elsif ($req =~ s/^\-//)
    { $slf->setup($req, $trc, $sav)
        unless $slf->is_described($req) || !$slf->is_disabled($nam);
    }
    elsif ($req =~ s/^\?(\!)?(\w+)\://)
    { $val = ((defined($1) ? 0 : 1) xor $slf->get_setting($2, 0));
      $slf->setup($req, $trc, $sav)
        unless $slf->is_described($req) || $val;
    }
    elsif ($req =~ s/^\*//)
    { $slf->{'_req'}->{$req} = $trc
        unless $slf->is_described($req) || exists($slf->{'_req'}->{$req});
    }
    else
    { $slf->setup($req, $trc, $sav)
        unless $slf->is_described($req);
    }
  }

  # Return the module object reference
  $obj;
}

sub _get_domain
{ my ($cmd, $re, $val) = @_;

  local $SIG{'__WARN__'} = sub {};
  if (open(CMD, "$cmd 2>&1 |"))
  { while (<CMD>)
    { last if ($_ =~ $re) && ($val = $2);
    }
    close(CMD);
  }
  $val;
}

=head2 S<$h-E<gt>upd_module($name)>

This method updates the setting list for the specified module.

=cut

sub upd_module
{ my ($slf, $nam) = @_;

  $slf->{'_mod'}->{$nam} =
    [grep {exists($slf->{'_def'}->{$_})} @{$slf->{'_mod'}->{$nam}}];
}

=head1 DATA COLLECTION METHODS

=head2 S<$h-E<gt>collect($name,$debug,$trace[,$save[,section,...]])>

This method collects the diagnostic information for the specified module. It
sets up the module also when required. When the data collection is complete,
the method deletes all temporary settings created by the module. If the save
flag is set, then the setup file is saved. The C<RDA_SAVE> setting specifies
the default flag value.

When the data collection is complete, the method adds a collect event (type
'C') to the event log including the module completion status. When relevant, it
includes execution statistics as additional events (type 's').

It returns 0 on successful completion or the number of load errors. Otherwise,
it returns the error return status.

=cut

sub collect
{ my ($slf, $nam, $dbg, $trc, $sav, @sct) = @_;
  my ($flg, $obj, $rec, $ret, $sct, $sta);

  $flg = $nam !~ $re_nam;
  $sav = $slf->{'sav'} unless defined($sav);

  # Collect the diagnostic data for the module
  $slf->{'_tmp'} = {};
  require RDA::Block;
  $obj = RDA::Block->new($nam, $slf->{'cfg'}->get_group('D_RDA_CODE'));
  unless ($ret = $obj->load($slf, 1))
  { # Execute the setup when not yet done
    $slf->setup($nam, $trc, $sav) unless $flg || $slf->is_configured($nam);

    # Delete previous reports
    if ($slf->is_collected($nam))
    { $slf->get_output->load_run($nam) if $slf->get_setting("$nam\_MRC");
      $slf->del_reports($nam);
    }

    # Reset the module statistics
    $slf->set_current($nam);
    $slf->reset_usage($flg);

    # Perform the data collection
    eval {
      local $SIG{'INT'} = sub {
        local $SIG{'__WARN__'} = sub {};
        die ("RDA-00206: RDA data collection interrupted\n");
      };
      $ret = $obj->collect($dbg, $trc, @sct);
    };
    if ($@)
    { print "RDA-00209: Collect error in $nam:\n$@\n";
      $ret = 1;
    }
    $sct = $obj->get_info('sct', {});
    $slf->log('C', $nam, $obj->get_version, $ret,
      join(',', grep {$sct->{$_} > 0} keys(%$sct)));

    # Collect the module statistics
    unless ($flg)
    { $slf->set_setting("LAST_RUN_$nam", RDA::Object::Rda->get_gmtime.' UTC',
        'T', 'Date and time of the last module execution');
      $slf->update_usage($nam, 1);
    }

    # Indicate that the data collection has been done
    unless ($flg || $ret)
    { if (grep {$sct->{$_} <= 0} keys(%$sct))
      { $slf->set_setting("PARTIAL_COLLECTION_$nam",
          join(',', grep {$sct->{$_} > 0} sort keys(%$sct)).'/'.
          join(',', grep {$sct->{$_} == 0} sort keys(%$sct)),
          'T', 'Collected sections');
        $sta = $slf->get_setting("STATUS_$nam", 'partial');
      }
      else
      { $slf->del_setting("PARTIAL_COLLECTION_$nam");
        $sta = $slf->get_setting("STATUS_$nam", 'done');
      }
      $slf->{'_col'}->{$nam} = exists($tb_col{$sta}) ? $tb_col{$sta} : 3;
    }

    # Delete the temporary settings created by the module
    foreach my $key (keys(%{$slf->{'_tmp'}}))
    { $slf->clr_temp_setting($key);
    }

    # When requested, save the setup file
    $slf->save if $sav;
  }

  # Return the module completion status
  $ret;
}

=head2 S<$h-E<gt>collect_all($table,$debug[,$save])>

This method collects the diagnostic information.

=cut

sub collect_all
{ my ($slf, $tbl, $dbg, $flg) = @_;

  # Store the collection request
  $slf->{'_prq'} = {};
  $slf->{'_srq'} = $tbl;

  # Predefine global temporary settings
  foreach my $nam (keys(%$tbl))
  { foreach my $key (split(/,/, $slf->get_setting("$nam\_TEMP", '')))
    { $slf->set_temp_setting($key, '') if $key;
    }
  }

  # Delete any previous output control
  delete($slf->{'_rpt'})->delete if exists($slf->{'_rpt'});

  # Perform the data collection
  foreach my $nam (sort keys(%$tbl))
  { next if exists($slf->{'_prq'}->{$nam});
    exit(1) if $slf->collect($nam, $dbg, $tbl->{$nam}, $flg);
  }
}

=head2 S<$h-E<gt>del_reports($nam)>

This method deletes the table of contents file and all reports that are
associated with the specified module. The collection status is reset also.

=cut

sub del_reports
{ my ($slf, $nam) = @_;
  my ($abr, $dir, $grp, $re1, $re2, $re3);

  # Scan the report directory to remove reports
  if ($nam =~ $re_nam)
  { $abr = $2;
    $grp = $slf->get_setting('RPT_GROUP');
    $re1 = qr/^$grp\_$abr\_.*\.$EXT$/i;
    $re2 = qr/^$grp\_$nam(_\d+)?\.(dat|htm|toc|txt)$/i;
    $re3 = qr/^$grp\_$nam\_[ADEIS]\.fil$/i;
    if (opendir(DIR, $dir = $slf->get_setting('RPT_DIRECTORY')))
    { foreach my $fil (readdir(DIR))
      { next unless $fil =~ $re1 || $fil =~ $re2 || $fil =~ $re3;
        $fil = RDA::Object::Rda->cat_file($dir, $fil);
        1 while unlink($fil);
      }
      closedir(DIR);
    }

    # Remove statistics
    foreach my $key ("LAST_RUN_$nam",
      $slf->grep_setting("^(DB|DBI|OS|XML)_STAT_$nam\_"))
    { $slf->del_setting($key);
    }

    # Adjust the data collection status
    $slf->{'_col'}->{$nam} = -1 if $slf->is_collected($nam);
  }
}

=head2 S<$h-E<gt>extract_usage>

This method extracts the library usage.

=cut

sub extract_usage
{ my ($slf, $ofh) = @_;
  my ($buf, $rec, $use);

  # Update the statistics
  foreach my $cls (@{$slf->{'_sta'}})
  { $cls->get_stats;
  }

  # Extract the statistics
  $buf = '';
  $use = $slf->{'use'};
  foreach my $typ (keys(%$use))
  { next unless ref($rec = $use->{$typ}) eq 'HASH';
    foreach my $key (keys(%$rec))
    { $buf .= join('|', $typ, $key, $rec->{$key}, "\n");
    }
  }
  $buf;
}

=head2 S<$h-E<gt>get_block($nam)>

This method returns a reference to a previously saved block. It returns
C<undef> if there is no block saved under the specified name.

=cut

sub get_block
{ my ($slf, $nam) = @_;

  exists($slf->{'_run'}->{$nam}) ? $slf->{'_run'}->{$nam} : undef;
}

=head2 S<$h-E<gt>get_usage>

This method returns the library usage hash.

=cut

sub get_usage
{ shift->{'use'};
}

=head2 S<$h-E<gt>incr_usage($typ)>

This method increments the request counter.

=cut

sub incr_usage
{ my ($slf, $typ) = @_;

  $slf->{'use'}->{$typ} = {not => '', out => 0, req => 0}
    unless exists($slf->{'use'}->{$typ});
  ++$slf->{'use'}->{$typ}->{'req'};
}

=head2 S<$h-E<gt>init_usage>

This method initializes the usage counters with the result of the previous run.

=cut

sub init_usage
{ my ($slf, $nam) = @_;
  my ($pat, $use);

  $slf->{'use'} = $use = {};
  foreach my $cls (@{$slf->{'_sta'}})
  { $cls->clr_stats;
  }
  foreach my $key ($slf->grep_setting(
                           '_STAT_'.$nam.'_(ERR|NOTE|OUT|REQ|SKIP)$'))
  { $use->{$1}->{$tb_use{$2}} = $slf->get_setting($key)
      if $key =~ m/^(.*)_STAT_$nam\_(ERR|NOTE|OUT|REQ|SKIP)$/;
  }
}

=head2 S<$h-E<gt>is_collected($name)>

This method indicates whether the data collection step is complete for the
specified module (that is, it displays whether diagnostic information must be
collected or if it can be skipped).

=cut

sub is_collected
{ my ($slf, $nam) = @_;

  exists($slf->{'_col'}->{$nam}) && $slf->{'_col'}->{$nam} > 0;
}

=head2 S<$h-E<gt>is_defined($name)>

This method indicates when the specified module exists (that is, when the
corresponding data collection specification file exists).

=cut

sub is_defined
{ my ($slf, $nam) = @_;

  -r $slf->{'cfg'}->get_file('D_RDA_CODE', $nam, '.def') ||
  -r $slf->{'cfg'}->get_file('D_RDA_CODE', $nam, '.ctl');
}

=head2 S<$h-E<gt>is_described($name)>

This method indicates whether the module description is available.

=cut

sub is_described
{ my ($slf, $nam) = @_;

  exists($slf->{'_dsc'}->{$nam});
}

=head2 S<$h-E<gt>is_disabled($name)>

This method indicates whether data collection should be skipped for the
specified module.

=cut

sub is_disabled
{ my ($slf, $nam) = @_;

  exists($slf->{'_col'}->{$nam}) && $slf->{'_col'}->{$nam} == 0;
}

=head2 S<$h-E<gt>is_done($name)>

This method indicates whether diagnostic information has been collected
effectively for the specified module.

=cut

sub is_done
{ my ($slf, $nam) = @_;

  exists($slf->{'_col'}->{$nam}) && $slf->{'_col'}->{$nam} == 3;
}

=head2 S<$h-E<gt>keep_block($nam,$blk)>

This method stores a block reference for further reuse.

=cut

sub keep_block
{ my ($slf, $nam, $blk) = @_;

  $slf->{'_run'}->{$nam} = $blk;
}

=head2 S<$h-E<gt>load_usage($ifh)>

This method loads the library usage from the specified file handle. It closes
the file handle on completion.

=cut

sub load_usage
{ my ($slf, $ifh) = @_;
  my ($key, $typ, $use, $val);

  $use = $slf->{'use'};
  while (<$ifh>)
  { s/[\n\r]+$//;
    ($typ, $key, $val) = split(/\|/, $_, 4);
    $use->{$typ} = {not => '', req => 0, ver => '?'}
      unless exists($use->{$typ});
    if ($key =~ m/^(err|out|req|skp)$/ && exists($use->{$typ}->{$key}))
    { $use->{$typ}->{$key} += $val;
    }
    else
    { $use->{$typ}->{$key} = $val;
    }
  }
  $ifh->close;
}

=head2 S<$h-E<gt>reset_usage>

This method resets the usage counters.

=cut

sub reset_usage
{ my ($slf, $flg) = @_;

  $slf->{'use'} = {};
  unless ($flg)
  { foreach my $cls (@{$slf->{'_rst'}})
    { $cls->reset;
    }
    foreach my $cls (@{$slf->{'_sta'}})
    { $cls->clr_stats;
    }
  }
}

=head2 S<$h-E<gt>set_collection($nam,$flag)>

This method sets the data collection status of the specified module name.

=cut

sub set_collection
{ my ($slf, $nam, $flg) = @_;

  $slf->{'_col'}->{$nam} = !$flg                    ? 0 :
                           $slf->is_collected($nam) ? 1 :
                                                      -1
    if $nam =~ $re_nam;
}

=head2 S<$h-E<gt>update_usage($nam)>

This method updates the library usage.

=cut

sub update_usage
{ my ($slf, $nam, $flg) = @_;
  my ($rec, $use);
 
  $use = $slf->{'use'};
  foreach my $cls (@{$slf->{'_sta'}})
  { $cls->get_stats;
  }
  foreach my $typ (sort keys(%$use))
  { $rec = $use->{$typ};
    $slf->log('s', $nam, $typ, $rec->{'req'},
      exists($rec->{'err'}) ? $rec->{'err'} : '',
      exists($rec->{'out'}) ? $rec->{'out'} : '',
      exists($rec->{'skp'}) ? $rec->{'skp'} : '',
      $rec->{'not'}) if $flg;
    $slf->set_setting("$typ\_STAT_$nam\_REQ",  $rec->{'req'}, 'N',
      "Number of $typ requests");
    $slf->set_setting("$typ\_STAT_$nam\_ERR",  $rec->{'err'}, 'N',
      "Number of $typ request errors") if exists($rec->{'err'});
    $slf->set_setting("$typ\_STAT_$nam\_OUT",  $rec->{'out'}, 'N',
      "Number of $typ requests timed out") if exists($rec->{'out'});
    $slf->set_setting("$typ\_STAT_$nam\_SKIP", $rec->{'skp'}, 'N',
      "Number of $typ requests skipped") if exists($rec->{'skp'});
    $slf->set_setting("$typ\_STAT_$nam\_NOTE", $rec->{'not'}, 'T',
      "$typ statistics note");
  }
}

=head1 OTHER MANAGEMENT METHODS

=head2 S<$h-E<gt>log($typ[,$arg...])>

This method logs an event in the event log.

=cut

sub log
{ shift->{'_log'}->log(@_);
}

=head2 S<$h-E<gt>log_force>

This method forces the creation of the log file.

=cut

sub log_force
{ my $slf = shift;

  $slf->{'_log'}->init($slf->get_setting('RPT_DIRECTORY'), 1);
}

=head2 S<$h-E<gt>log_resume>

This method reopens the log file and restarts event logging.

=cut

sub log_resume
{ shift->{'_log'}->resume;
}

=head2 S<$h-E<gt>log_suspend>

This method suspends event logging and closes the log file.

=cut

sub log_suspend
{ shift->{'_log'}->suspend;
}

=head2 S<$h-E<gt>log_timeout($blk,$typ[,$arg...])>

This method logs a timeout event in the event log.

=cut

sub log_timeout
{ my ($slf, $blk, $typ, @arg) = @_;
  my ($mod, $out, $rpt, $top);

  $top = $blk->get_top;
  $mod = $top->get_oid;
  if (defined($out = $top->get_info('rpt')))
  { $rpt = $out->get_info('cur');
    $slf->{'_log'}->log('t', $mod, ref($rpt) ? $rpt->get_path : '-', $typ,
      map {$out->filter($_)} @arg)
  }
  else
  { $slf->{'_log'}->log('t', $mod, '-', $typ, @arg);
  }
}

=head2 S<$h-E<gt>logfile>

This method returns the file handle that is associated with the event log. When
this is not possible, it returns C<undef>.

=cut

sub logfile
{ shift->{'_log'}->logfile;
}

=head1 MACROS

=head2 S<displayText($nam[,$flg[,%hsh]])>

This macro displays text. The text can contain variables that are resolved
through the specified hash. When the variable is not defined in the hash,
settings are used. When the flag is set, a user acknowledgment is requested
before continuing.

=cut

sub _m_dsp_text
{ my $slf = shift;
  my $ctx = shift;

  $slf->dsp_text(@_) unless ref($slf->{'out'});
}

=head2 S<filterSetting($lgt,@key)>

This macro returns the list of the provided settings that correspond to modules
included in the current data collection. It obtains the module names by
ignoring the specified number of characters at the end of the setting names.

=cut

sub _m_flt_setting
{ my ($slf, $ctx, $lgt, @mod) = @_;

  return () unless exists($slf->{'_srq'});
  return grep {exists($slf->{'_srq'}->{$_})} @mod unless $lgt > 0;
  grep {exists($slf->{'_srq'}->{substr($_, 0, -$lgt)})} @mod;
}

=head2 S<forkModules()>

This macro launches the parallel collections.

=cut

sub _m_fork_modules
{ my ($slf) = @_;
  my ($dir, $fil, $nam, $oid, $pid, $pth, $trc);

  unless ($slf->get_setting('NO_PARALLEL') || !$slf->{'_frk'})
  { $dir = $slf->get_output->get_path('J', 1);
    $fil = IO::File->new;
    $oid = $slf->{'oid'};
    $trc = $slf->{'_srq'};
    foreach my $key ($slf->grep_setting('_FORK$'))
    { $nam = substr($key, 0, -5);
      next unless exists($trc->{$nam}) && $trc->{$nam} == 0
        && $slf->get_setting($key)
        && $slf->is_configured($nam);
      $pth = RDA::Object::Rda->cat_file($dir, "$oid\_$nam");

      # Clear old files
      1 while unlink("$pth.sta");
      1 while unlink("$pth.tmp");
  
      # Launch the collection
      last unless defined($pid = fork());
      if (!$pid)
      { my ($buf, $val);

        # Perform a double fork except when forks are emulated
        unless ($slf->{'_frk'} < 0)
        { exit(1) unless defined($pid  = fork());
          if ($pid)
          { _save_pid($fil, $pth, $pid);
            exit(0);
          }
        } 

        # Perform the collection
        exit(1) if $slf->collect($nam, 0, 0, 0);

        # Save results
        $buf = 'col:'.$slf->{'_col'}->{$nam}."\n";
        foreach my $key ("LAST_INFO_$nam",
                         "LAST_RUN_$nam",
                         "PARTIAL_COLLECTION_$nam",
                         $slf->grep_setting("^[A-Z]+_STAT_$nam\_"))
        { $buf .= "$key='$val'\n"
            if defined($val = $slf->get_setting($key));
        }
        if ($fil->open("$pth.tmp", $CREATE, $FIL_PERMS))
        { $fil->syswrite($buf, length($buf));
          $fil->close;
        }
        move("$pth.tmp", "$pth.sta") || copy("$pth.tmp", "$pth.sta");
        exit(0);
      }

      # Determine the fork success
      if ($slf->{'_frk'} < 0)
      { _save_pid($fil, $pth, $pid);
      }
      elsif (waitpid($pid, 0) != $pid || $? != 0)
      { next;
      }

      # Indicate that the module is executed in parallel
      $slf->{'_prq'}->{$nam} = $pth;
      $slf->log('c', $nam);
    }
  }

  # Return the modules executed in parallel
  sort keys(%{$slf->{'_prq'}});
}

sub _save_pid
{ my ($fil, $pth, $pid) = @_;
  my ($buf);

  if ($fil->open("$pth.pid", $CREATE, $FIL_PERMS))
  { $buf = "$pid\n";
    $fil->syswrite($buf, length($buf));
    $fil->close;
  }
}

=head2 S<getDesc($key)>

This macro returns a list containing the value, description, and type of the
specified setting. The value is adjusted according to the type. It returns an
empty list if the setting is not defined.

=cut

sub _m_get_desc
{ my ($slf, $ctx, $key) = @_;
  my ($typ, $val);

  return () unless exists($slf->{'_def'}->{$key});
  $typ = $slf->{'_def'}->{$key}->[0];
  $val = $slf->{'_set'}->{$key};
  $val = $val ? 'Yes' : 'No' if $typ eq 'B';
  ($val, $slf->{'_def'}->{$key}->[1], $typ);
}

=head2 S<getSetting($key[,$dft[,$flg]])>

This macro returns the current value of a setup attribute. It returns the
default value when the attribute does not exist. When the flag is set,
references to other settings are resolved in the value.

=cut

sub _m_get_setting
{ my ($slf, $ctx, $key, $dft, $flg) = @_;

  $slf->get_setting($key, $dft, $flg);
}

=head2 S<grepSetting($re,$opt)>

This macro returns the setting names that match the regular expression. It
supports the same options as the C<grep_setting> method.

=cut

sub _m_grep_setting
{ my ($slf, $ctx, $re, $opt) = @_;

  $slf->grep_setting($re, $opt);
}

=head2 S<log($typ,@det)>

This macro adds an event to the event log. The event type must be composed of
two or more alphanumeric characters. Otherwise, the request is ignored.

=cut

sub _m_log
{ my $slf = shift;
  my $ctx = shift;
  my $typ = shift;

  return 0 unless $typ && $typ =~ m/^\w{2,}$/;
  $slf->log_force;
  $slf->log($typ, @_);
}

=head2 S<requestSetting($nam[,$dpt])>

This macro requests additional settings using the named setup specifications.
The current setting level applies. You can control the setup depth by an extra
argument. It uses 1 by default.

The macro returns 1 when the setup is performed. Otherwise, it returns 0.

=cut

sub _m_req_setting
{ my ($slf, $ctx, $nam, $dpt) = @_;
  my ($obj);

  $nam =~ s/\.cfg$//i;
  require RDA::Module;
  $obj = RDA::Module->new($nam, $slf->{'cfg'}->get_group('D_RDA_CODE'));
  if ($obj->load($slf))
  { $obj->set_info('dpt', defined($dpt) ? $dpt : 1);
    $obj->set_info('rpt', $ctx->get_top('rpt'));
    $obj->request($slf->get_setting('RDA_LEVEL'),
      $ctx->get_context->check_trace(1));
    return 1;
  }
  0;
}

=head2 S<setSetting($key,$val[,$typ,$dsc])>

This macro specifies a value for a setup attribute. If the value is undefined,
then it removes the setup attribute. Also you can specify the type and
description for a new setting. This macro adds new settings to the current
module automatically.

It returns the previous value or an undefined value if it is not previously
defined.

=cut

sub _m_set_setting
{ my ($slf, $ctx, $key, $val, $typ, $dsc) = @_;

  if (defined($key))
  { if (defined($val))
    { die "RDA-00102: Invalid character in setting value\n"
        if $val =~ m/(&\#\d+;|\n|\r)/;
      $val = $slf->set_setting($key, $val, $typ, $dsc);
    }
    else
    { $val = $slf->del_setting($key);
    }
  }
  $val;
}

=head2 S<setTempSetting($key,$val)>

This macro specifies a temporary value for a setup attribute. If the value is
undefined, then the original value is restored.

It returns the previous value or an undefined value if it is not defined
previously.

=cut

sub _m_temp_setting
{ my ($slf, $ctx, $key, $val) = @_;

  if (defined($key))
  { if (defined($val))
    { die "RDA-00102: Invalid character in setting value\n"
        if $val =~ m/(&\#\d+;|\n|\r)/;
      $val = $slf->set_temp_setting($key, $val);
    }
    else
    { $val = $slf->clr_temp_setting($key);
    }
  }
  $val;
}

=head2 S<updateUsage([$key])>

This macro updates the usage information of the current collection module. It
accepts as argument the name of the setting to store the last execution time
stamp. It returns the current time stamp.

=cut

sub _m_upd_usage
{ my ($slf, $ctx, $key) = @_;
  my ($tim);

  return '' unless exists($slf->{'_cur'});
  $slf->update_usage($slf->{'_cur'});
  $key = 'LAST_RUN_'.$slf->{'_cur'} unless defined($key);
  $tim = RDA::Object::Rda->get_gmtime.' UTC';
  $slf->set_setting($key, $tim,
    'T', 'Date and time of the last module execution');
  $tim;
}

=head2 S<waitModules([$max])>

This macro waits for the completion of the parallel collections. You can
specify a maximum number of wait loops as an argument.

=cut

sub _m_wait_modules
{ my ($slf, $ctx, $max) = @_;
  my ($cnt, $ifh, $pth, %pid);

  # Check the collection completion
  $cnt = 0;
  $ifh = IO::File->new;
  foreach my $nam (keys(%{$slf->{'_prq'}}))
  { $pth = $slf->{'_prq'}->{$nam};
    if (-f "$pth.sta")
    { _load_sta($slf, $nam);
    }
    elsif (-f "$pth.pid")
    { if ($ifh->open("<$pth.pid"))
      { while(<$ifh>)
        { $pid{$nam} = $1 if m/^(\d+)/;
        }
        $ifh->close;
      }
      ++$cnt;
    }
    else
    { delete($slf->{'_prq'}->{$nam});
    }
  }
  return 0 unless $cnt;

  # Wait for the collection completion
  $max = 0 unless defined($max) && $max > 0;
  for(;;)
  { $cnt = 0;
    foreach my $nam (keys(%{$slf->{'_prq'}}))
    { if (!kill(0, $pid{$nam}) || -f $slf->{'_prq'}->{$nam}.'.sta')
      { _load_sta($slf, $nam);
      }
      else
      { ++$cnt;
      }
    }
    return 0 unless $cnt;
    return 1 if $max < 0;
    --$max if $max;
    sleep(1);
  }
}

sub _load_sta
{ my ($slf, $nam) = @_;
  my ($ifh, $pth);

  # Update the settings
  $ifh = IO::File->new;
  $pth = delete($slf->{'_prq'}->{$nam});
  if ($ifh->open("<$pth.sta"))
  { while (<$ifh>)
    { if (m/^(\w+)='(.*)'/)
      { $slf->set_setting($1, $2);
      }
      elsif (m/^col:(\d+)/)
      { $slf->{'_col'}->{$nam} = $1;
      }
    }
    $ifh->close;
  }

  # Clear the module files
  1 while unlink("$pth.pid");
  1 while unlink("$pth.sta");
  1 while unlink("$pth.tmp");
}

1;

__END__

=head1 SEE ALSO

L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Block|RDA::Block>,
L<RDA::Build|RDA::Build>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Daemon|RDA::Daemon>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Discover|RDA::Discover>,
L<RDA::Driver::Da|RDA::Driver::Da.pm>,
L<RDA::Driver::Dbd|RDA::Driver::Dbd.pm>,
L<RDA::Driver::Jdbc|RDA::Driver::Jdbc.pm>,
L<RDA::Driver::Jsch|RDA::Driver::Jsch.pm>,
L<RDA::Driver::Local|RDA::Driver::Local.pm>,
L<RDA::Driver::Rsh|RDA::Driver::Rsh.pm>,
L<RDA::Driver::Sqlplus|RDA::Driver::Sqlplus.pm>,
L<RDA::Driver::Ssh|RDA::Driver::Ssh.pm>,
L<RDA::Driver::WinOdbc|RDA::Driver::WinOdbc.pm>,
L<RDA::Explorer|RDA::Explorer>,
L<RDA::Extra|RDA::Extra>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Handle::Area|RDA::Handle::Area.pm>,
L<RDA::Handle::Block|RDA::Handle::Block.pm>,
L<RDA::Handle::Data|RDA::Handle::Data.pm>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate.pm>,
L<RDA::Handle::Filter|RDA::Handle::Filter.pm>,
L<RDA::Handle::Memory|RDA::Handle::Memory.pm>,
L<RDA::Log|RDA::Log>,
L<RDA::Library::Admin|RDA::Library::Admin>,
L<RDA::Library::Archive|RDA::Library::Archive>,
L<RDA::Library::Buffer|RDA::Library::Buffer>,
L<RDA::Library::Data|RDA::Library::Data>,
L<RDA::Library::Db|RDA::Library::Db>,
L<RDA::Library::Dbi|RDA::Library::Dbi>,
L<RDA::Library::Env|RDA::Library::Env>,
L<RDA::Library::Expr|RDA::Library::Expr>,
L<RDA::Library::File|RDA::Library::File>,
L<RDA::Library::Ftp|RDA::Library::Ftp>,
L<RDA::Library::Hcve|RDA::Library::Hcve>,
L<RDA::Library::Html|RDA::Library::Html>,
L<RDA::Library::Http|RDA::Library::Http>,
L<RDA::Library::Invent|RDA::Library::Invent>,
L<RDA::Library::Remote|RDA::Library::Remote>,
L<RDA::Library::String|RDA::Library::String>,
L<RDA::Library::Table|RDA::Library::Table>,
L<RDA::Library::Temp|RDA::Library::Temp>,
L<RDA::Library::Value|RDA::Library::Value>,
L<RDA::Library::Windows|RDA::Library::Windows>,
L<RDA::Library::Xml|RDA::Library::Xml>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Access|RDA::Object::Access.pm>,
L<RDA::Object::Buffer|RDA::Object::Buffer.pm>,
L<RDA::Object::Convert|RDA::Object::Convert.pm>,
L<RDA::Object::Cookie|RDA::Object::Cookie.pm>,
L<RDA::Object::Display|RDA::Object::Display.pm>,
L<RDA::Object::Domain|RDA::Object::Domain.pm>,
L<RDA::Object::Env|RDA::Object::Env.pm>,
L<RDA::Object::Explorer|RDA::Object::Explorer.pm>,
L<RDA::Object::Ftp|RDA::Object::Ftp.pm>,
L<RDA::Object::Home|RDA::Object::Home.pm>,
L<RDA::Object::Htm|RDA::Object::Html.pm>,
L<RDA::Object::Index|RDA::Object::Index.pm>,
L<RDA::Object::Inline|RDA::Object::Inline.pm>,
L<RDA::Object::Instance|RDA::Object::Instance.pm>,
L<RDA::Object::Jar|RDA::Object::Jar.pm>,
L<RDA::Object::Java|RDA::Object::Java.pm>,
L<RDA::Object::Lock|RDA::Object::Lock.pm>,
L<RDA::Object::Mrc|RDA::Object::Mrc.pm>,
L<RDA::Object::Output|RDA::Object::Output.pm>,
L<RDA::Object::Parser|RDA::Object::Parser.pm>,
L<RDA::Object::Pipe|RDA::Object::Pipe.pm>,
L<RDA::Object::Rda|RDA::Object::Rda.pm>,
L<RDA::Object::Remote|RDA::Object::Remote.pm>,
L<RDA::Object::Report|RDA::Object::Report.pm>,
L<RDA::Object::Request|RDA::Object::Request.pm>,
L<RDA::Object::Response|RDA::Object::Response.pm>,
L<RDA::Object::Sgml|RDA::Object::Sgml.pm>,
L<RDA::Object::SshAgent|RDA::Object::SshAgent.pm>,
L<RDA::Object::System|RDA::Object::System.pm>,
L<RDA::Object::Table|RDA::Object::Table.pm>,
L<RDA::Object::Target|RDA::Object::Target.pm>,
L<RDA::Object::Toc|RDA::Object::Toc.pm>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent.pm>,
L<RDA::Object::Windows|RDA::Object::Windows.pm>,
L<RDA::Object::WlHome|RDA::Object::WlHome.pm>,
L<RDA::Object::Xml|RDA::Object::Xml.pm>,
L<RDA::Operator::Array|RDA::Operator::Array>,
L<RDA::Operator::Hash|RDA::Operator::Hash>,
L<RDA::Operator::Scalar|RDA::Operator::Scalar>,
L<RDA::Operator::Value|RDA::Operator::Value>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Tools|RDA::Tools>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Array|RDA::Value::Array>,
L<RDA::Value::Assoc|RDA::Value::Assoc>,
L<RDA::Value::Code|RDA::Value::Code>,
L<RDA::Value::Global|RDA::Value::Global>,
L<RDA::Value::Hash|RDA::Value::Hash>,
L<RDA::Value::Internal|RDA::Value::Internal>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Operator|RDA::Value::Operator>,
L<RDA::Value::Pointer|RDA::Value::Pointer>,
L<RDA::Value::Property|RDA::Value::Property>,
L<RDA::Value::Scalar|RDA::Value::Scalar>,
L<RDA::Value::Variable|RDA::Value::Variable>,
L<RDA::Web|RDA::Web>,
L<RDA::Web::Archive|RDA::Web::Archive>,
L<RDA::Web::Display|RDA::Web::Display>,
L<RDA::Web::Help|RDA::Web::Help>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
