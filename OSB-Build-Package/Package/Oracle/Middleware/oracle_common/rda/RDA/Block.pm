# Block.pm: Class Used for Objects to Execute Data Collection Specifications

package RDA::Block;

# $Id: Block.pm,v 2.33 2012/08/13 14:25:10 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Block.pm,v 2.33 2012/08/13 14:25:10 mschenke Exp $
#
# Change History
# 20120813  MSC  Introduce the current calling block concept.

=head1 NAME

RDA::Block - Class Used for Objects to Execute Data Collection Specifications

=head1 SYNOPSIS

require RDA::Block;

=head1 DESCRIPTION

The objects of the C<RDA::Block> class are used to execute data collection
specifications.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Context;
  use RDA::Handle::Memory;
  use RDA::Object::Rda qw($CREATE $RE_TST $TMP_PERMS);
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @EXPORT_OK @ISA
            $CONT $ERROR $RET_RET $RET_BRK $RET_NXT $RET_DIE
            $DIE $DIE_A $DIE_B $DIE_M $DIE_S $DIE_X
            $SPC_BLK $SPC_COD $SPC_FCT $SPC_LIN $SPC_OBJ $SPC_REF $SPC_VAL);
$VERSION   = sprintf("%d.%02d", q$Revision: 2.33 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw($CONT $ERROR $RET_RET $RET_BRK $RET_NXT $RET_DIE
                $DIE $DIE_B $DIE_C $DIE_M $DIE_S $DIE_X
                $SPC_BLK $SPC_COD $SPC_FCT $SPC_LIN $SPC_OBJ $SPC_REF $SPC_VAL);
@ISA       = qw(Exporter);

$SPC_FCT = 0; # Associated execution function
$SPC_REF = 1; # Associated reference
$SPC_VAL = 2; # Associated value
$SPC_BLK = 3; # Associated code block
$SPC_LIN = 4; # Source line
$SPC_COD = 5; # Source code
$SPC_OBJ = 6; # Associated object reference

$DIE = qr/^___Die\((\w)\)___/;
$DIE_A = "___Die(A)___\n"; # All module abort
$DIE_B = "___Die(B)___\n"; # Block abort
$DIE_M = "___Die(M)___\n"; # Module abort
$DIE_S = "___Die(S)___\n"; # Section abort
$DIE_X = "___Die(x)___\n"; # Exit request

$CONT    = 0;
$ERROR   = -1;
$RET_RET = 1;
$RET_BRK = 2;
$RET_NXT = 3;
$RET_DIE = 4;

# Define the global private constants
my $EXE_FCT = 0; # Execution function
my $GET_FCT = 1; # Parsing function
my $SUB_BLK = 2; # When not null, subblock type
my $TXT_BLK = 3; # 0 = code / 1 or function reference = text

my $ALR = "___Alarm___";

my $RPT_NXT = ".N1\n";
my $RPT_XRF = "  ";

# Define the global private variables
my $tb_clr = {
  cfg => \&_skip_job,
  err => \&_skip_job,
  out => \&_skip_job,
  use => \&_skip_job,
  };
my %tb_cmd = (
  'alias'    => [undef,           \&_get_alias,    0,   0],
  'append'   => [\&_exe_append,   \&get_var_txt,   'T', \&_merge_txt],
  'break'    => [\&_exe_break,    \&_get_break,    0,   0],
  'calc'     => [\&_exe_calc,     \&_get_value,    0,   0],
  'call'     => [\&_exe_calc,     \&_get_call,     0,   0],
  'code'     => [\&_exe_code,     \&_get_code,     'B', 0],
  'debug'    => [\&_exe_debug,    \&_get_list,     0,   0],
  'decr'     => [\&_exe_calc,     \&_get_decr,     0,   0],
  'delete'   => [\&_exe_calc,     \&_get_delete,   0,   0],
  'die'      => [\&_exe_die,      \&_get_die,      0,   0],
  'dump'     => [\&_exe_dump,     \&_get_list,     0,   0],
  'echo'     => [\&_exe_echo,     \&_get_list,     0,   0],
  'else'     => [\&_exe_else,     \&_get_cond3,    'B', 0],
  'elsif'    => [\&_exe_elsif,    \&_get_cond2,    'B', 0],
  'eval'     => [\&_exe_eval,     \&_get_none,     'E', 0],
  'for'      => [\&_exe_for,      \&_get_for,      'L', 0],
  'global'   => [\&_exe_global,   \&_get_global,   0,   0],
  'if'       => [\&_exe_if,       \&_get_cond1,    'B', 0],
  'import'   => [\&_exe_import,   \&get_var_list,  0,   0],
  'incr'     => [\&_exe_calc,     \&_get_incr,     0,   0],
  'job'      => [\&_exe_job,      \&_get_list,     'F', 0],
  'keep'     => [\&_exe_keep,     \&get_var_list,  0,   0],
  'loop'     => [\&_exe_loop,     \&_get_loop,     'L', 0],
  'macro'    => [\&_exe_macro,    \&_get_name,     'F', 0],
  'next'     => [\&_exe_next,     \&_get_break,    0,   0],
  'once'     => [\&_exe_once,     \&_get_while,    'L', 0],
  'recover'  => [\&_exe_recover,  \&_get_cond,     0,   0],
  'return'   => [\&_exe_return,   \&_get_value,    0,   0],
  'run'      => [\&_exe_run,      \&_get_run,      0,   0],
  'section'  => [undef,           \&_get_name,     'S', 0],
  'set'      => [\&_exe_set,      \&get_var_txt,   'T', \&_merge_txt],
  'sleep'    => [\&_exe_sleep,    \&_get_value,    0,   0],
  'test'     => [\&_exe_test,     \&_get_run,      0,   0],
  'thread'   => [\&_exe_job,      \&_get_thread,   'F', 0],
  'use'      => [undef,           \&_get_class,    0,   0],
  'var'      => [\&_exe_calc,     \&get_var_def,   0,   0],
  'wait'     => [\&_exe_wait,     \&_get_value,    0,   0],
  'while'    => [\&_exe_while,    \&_get_while,    'L', 0],
  );
my %tb_die = (
  A => $DIE_A,
  B => $DIE_B,
  M => $DIE_M,
  S => $DIE_S,
  x => $DIE_X,
  );
my $tb_job = {
  cfg => \&_load_job_cfg,
  out => \&_load_job_out,
  use => \&_load_job_use,
  };
my $tb_rec = {
  cfg => \&_load_job_cfg,
  out => \&_skip_job,
  use => \&_skip_job,
  };

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Block-E<gt>new($nam,$dir)>

The object constructor for data collection (package) objects. It takes the
module name and the module directory as arguments.

=head2 S<$obj-E<gt>new('S',$nam)>

The object constructor for code block objects. It takes the section name as an
extra argument.

=head2 S<$obj-E<gt>new($typ)>

The object constructor for code block objects.

C<RDA::Block> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object (P)

=item S<    B<'als' > > Alias table (P)

=item S<    B<'aux' > > Reference to the associated object (P)

=item S<    B<'beg' > > Start time (P)

=item S<    B<'cfg' > > Reference to the RDA software configuration (P)

=item S<    B<'cmd' > > Command parsing hash (P)

=item S<    B<'ctx' > > Reference to the execution context (P)

=item S<    B<'dbg' > > Debug flag (P)

=item S<    B<'dft' > > Default section execution indicator (P)

=item S<    B<'die' > > Die information (P)

=item S<    B<'dir' > > Module directory (P)

=item S<    B<'dsp' > > Reference to the display object (P)

=item S<    B<'env' > > Reference to the environment object (P)

=item S<    B<'err' > > Error stack (P)

=item S<    B<'glb' > > Valid global variables (P)

=item S<    B<'inc' > > Reference to the inline code control object (P)

=item S<    B<'job' > > Job identifier (P)

=item S<    B<'lck' > > Lock control reference (P)

=item S<    B<'mrc' > > Reference to the multi-run collection control object (P)

=item S<    B<'nam' > > Setup name (P)

=item S<    B<'nxt' > > List of next sections to execute (P)

=item S<    B<'oid' > > Object identifier (P,S)

=item S<    B<'opr' > > Hash that contains the operator definitions (P)

=item S<    B<'out' > > Output suppression indicator (P)

=item S<    B<'pre' > > Trace prefix (P)

=item S<    B<'pwd' > > Reference to the access control object (P)

=item S<    B<'rem' > > Remote session manager reference (P)

=item S<    B<'rpt' > > Local reporting control object (P)

=item S<    B<'sct' > > List of sections already executed (P)

=item S<    B<'tim' > > Time limit (P)

=item S<    B<'use' > > Use hash (P)

=item S<    B<'val' > > Collect value (P)

=item S<    B<'ver' > > Specification version number (P)

=item S<    B<'yes' > > Auto confirmation flag (P)

=item S<    B<'_chl'> > List of children (S,*)

=item S<    B<'_cod'> > Associated code block (S,*)

=item S<    B<'_err'> > Number of parsing errors (P)

=item S<    B<'_exe'> > Execution sequence (P)

=item S<    B<'_ifc'> > IF counter (F,S,*)

=item S<    B<'_job'> > Job counter (P)

=item S<    B<'_lib'> > Hash that contains the macro definitions (P)

=item S<    B<'_lin'> > Current line number in the specification file (P)

=item S<    B<'_lst'> > Last specification executed (S,*)

=item S<    B<'_lvl'> > Code block level (S,*)

=item S<    B<'_nam'> > Loop names (S,*)

=item S<    B<'_par'> > Reference to the parent object (*)

=item S<    B<'_pid'> > Process identifier list (P)

=item S<    B<'_pkg'> > Reference to the package object (P,S,*)

=item S<    B<'_run'> > Parents of the called shared packages (P)

=item S<    B<'_sct'> > Section hash (P)

=item S<    B<'_thr'> > Thread indicator (P)

=item S<    B<'_typ'> > Associated code block type (P,S,*)

=item S<    B<'_use'> > Use indicator hash (P)

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my $obj = shift;
  my ($cls, $slf);

  if ($cls = ref($obj))
  { my ($typ, $nam) = @_;

    if ($typ eq 'S')
    { die "RDA-00271: Duplicate section '$nam'\n"
        if exists($obj->{'_sct'}->{$nam});

      # Create the section object
      $slf = bless {
        ctx => $obj->{'ctx'},
        oid => $nam,
        _chl => [],
        _cod => [],
        _ifc => 0,
        _lvl => 0,
        _pkg => $obj,
        _typ => $typ,
        }, $cls;

      # Manage the sections
      die "Missing section name\n" unless $nam;
      $obj->{'_sct'}->{$nam} = $slf;
      push(@{$obj->{'_exe'}}, $nam) unless $nam =~ m/^(\-|begin|end)$/;
    }
    else
    { # Create the code object
      $slf = bless {
        ctx  => $obj->{'ctx'},
        _chl => [],
        _cod => [],
        _ifc => 0,
        _lvl => $obj->{'_lvl'} + 1,
        _typ => $typ,
        _par => $obj,
        _pkg => $obj->{'_pkg'},
        }, $cls;
      push(@{$obj->{'_chl'}}, $slf);

      # Create a dedicate context for macros and classes
      $slf->{'ctx'} = RDA::Context->new($obj->{'ctx'}) if $typ =~ m/^[CF]$/;

      # Propagate loop names
      $slf->{'_nam'} = [@{$obj->{'_nam'}}]
        if exists($obj->{'_nam'}) && $typ ne 'F';
    }
  }
  else
  { my ($nam, $dir) = @_;

    # Create the data collection (package) object
    $slf = bless {
      als  => {},
      cmd  => {%tb_cmd},
      ctx  => RDA::Context->new,
      dbg  => 0,
      dft  => 0,
      glb  => {},
      job  => '',
      nxt  => [],
      oid  => $nam,
      out  => 0,
      pre  => 'TRACE/',
      rnd  => 0,
      use  => {},
      ver  => 0,
      yes  => 0,
      _exe => [],
      _job => 0,
      _lib => {},
      _opr => {},
      _run => {},
      _sct => {},
      _thr => 0,
      _typ => 'P',
      _use => {},
      }, $obj;
    $slf->{'_pkg'} = $slf;

    # Get some setup information
    $slf->{'dir'} = $dir if defined($dir);

    # Create a default associated object
    $slf->{'aux'} = $slf;
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($nam,...)>

This method executes the code of the specified macro.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;
  my ($lib);

  $lib = $slf->{'_pkg'}->{'_lib'};
  return undef unless exists($lib->{$nam});
  $lib->{$nam}->call($nam, @arg);
}

=head2 S<$h-E<gt>check_die($err)>

This method determines how to handle an abort or a die.

=cut

sub check_die
{ my ($slf, $err) = @_;
  my ($mod, $msg);

  # Treat a die request
  if ($err =~ $DIE)
  { ($mod, $msg) = ($1, delete($slf->{'die'}));

    # Handle exit request
    if ($mod eq 'x')
    { $slf->{'agt'}->end;
      exit(0);
    }

    # Handle die request
    die $msg        if $mod eq 'A';
    return $ERROR   if $mod eq 'B';
    print $msg;
    return $RET_DIE if $mod eq 'M';
    return $CONT    if $mod eq 'S';
  }

  # Convert it as an error
  $ERROR;
}

=head2 S<$h-E<gt>check_free>

This method indicates whether enough free disk space remains. It always
returns zero when the check is disabled or when the reporting control is not
enabled.

=cut

sub check_free
{ my $slf = shift->get_top;

  exists($slf->{'rpt'}) ? $slf->{'rpt'}->test_free(0, 1) : 0;
}
=head2 S<$h-E<gt>check_quotas>

This method indicates whether quotas are exceeded.

=cut

sub check_quotas
{ my $slf = shift->get_top;

  # Check quotas
  if (exists($slf->{'tim'}) && time > $slf->{'tim'})
  { $slf->{'agt'}->set_setting('LAST_INFO_'.$slf->{'oid'},
      'Time quota exceeded','T','Execution error');
    return 1;
  }
  if (exists($slf->{'rpt'}) && $slf->{'rpt'}->check_space < 0)
  { $slf->{'agt'}->set_setting('LAST_INFO_'.$slf->{'oid'},
      'Space quota exceeded','T','Execution error');
    return 2;
  }

  # Return the current return code
  0;
}


=head2 S<$h-E<gt>check_space>

This method indicates whether report space remains. It always returns zero
when the space quota is disabled or when the reporting control is not enabled.

=cut

sub check_space
{ my $slf = shift->get_top;

  exists($slf->{'rpt'}) ? $slf->{'rpt'}->check_space : 0;
}

=head2 S<$h-E<gt>check_time>

This method indicates whether some time remains. It always returns zero
when the time quota is disabled.

=cut

sub check_time
{ my $slf = shift->get_top;

  exists($slf->{'tim'}) ? $slf->{'tim'} - time : 0;
}

=head2 S<$h-E<gt>collect([$dbg[,$trc[,section,...]]])>

This method executes the data collection specifications. It returns a
completion status. Possible values are as follows:

=over 8

=item B<     0 > Successful completion

=item B<    -1 > Execution error

=back

When the script is complete, it closes report files automatically.

=cut

sub collect
{ my ($slf, $dbg, $trc, @sct) = @_;
  my ($agt, $flg, $sta, $val);

  # Abort when not called on a top code block
  return $ERROR
    unless exists($slf->{'_sct'}) && exists($slf->{'_sct'}->{'-'});

  # Initialize the code block
  $agt = $slf->{'agt'};
  $slf->{'out'} = $flg = $agt->{'out'};
  $slf->{'dbg'} = ($flg || !defined($dbg)) ? 0 : $dbg;
  $slf->{'pre'} = 'TRACE/';
  $slf->{'ctx'}->set_trace(($flg || !defined($trc)) ? 0 : $trc);

  $slf->{'_lib'} = {};
  $slf->{'_thr'} = 0;
  $agt->get_macros($slf->{'_lib'});

  # Define the time quota when requested
  $slf->{'beg'} = time;
  $val = $agt->get_setting('NO_QUOTA')
    ? 0
    : int($agt->get_setting($slf->{'oid'}.'_TIME_QUOTA', 0));
  if ($val > 0)
  { $slf->{'tim'} = $slf->{'beg'} + $val;
  }
  else
  { delete($slf->{'tim'});
  }

  # Execute the package sections
  $sta = $slf->exec($slf, 0, undef, @sct);

  # Remove lock files
  eval {$slf->{'lck'}->end} if exists($slf->{'lck'}) && ref($slf->{'lck'});

  # Return the completion status
  $sta;
}

=head2 S<$h-E<gt>define($var,$value)>

This method predefines a package variable.

=cut

sub define
{ my ($slf, $var, $val) = @_;

  $slf->{'_pkg'}->{'ctx'}->set_object($var, $val, 1);
}

=head2 S<$h-E<gt>define_operator($name,$arg,...)>

This method defines a new operator. You can specify multiple operator names
with a name array. It uses the first definition found. It generates an error
when no definitions are found.

=cut

sub define_operator
{ my ($slf, $nam, @arg) = @_;
  my ($tbl);

  $tbl = $slf->{'_pkg'}->{'opr'};
  $nam = [$nam] unless ref($nam) eq 'ARRAY';
  foreach my $itm (@$nam)
  { return &{$tbl->{$itm}}(@arg) if exists($tbl->{$itm});
  }
  die "RDA-00243: Invalid operator '".join(',',@$nam)."'\n";
}

=head2 S<$h-E<gt>delete>

This method deletes an object and all subobjects, thus handling circular
references.

=cut

sub delete
{ my ($slf) = @_;

  # Delete subobjects
  $slf->delete_sections if exists($slf->{'_sct'});
  if (exists($slf->{'_chl'}))
  { foreach my $obj (@{$slf->{'_chl'}})
    { $obj->delete;
    }
  }

  # Remove references to other objects and next delete the object
  undef %$slf;
  undef $slf;
}

=head2 S<$h-E<gt>delete_sections>

This method deletes all code sections.

=cut

sub delete_sections
{ my ($slf) = @_;

  $slf->{'_exe'} = [];
  foreach my $nam (keys(%{$slf->{'_sct'}}))
  { delete($slf->{'_sct'}->{$nam})->delete;
  }
  $slf;
}

=head2 S<$h-E<gt>eval($ctx,$lvl,$pre,$trc[,section,...])>

This method evaluates the block in a dedicated context. You can specify the
trace prefix and level as arguments. It returns the error count.

=cut

sub eval
{ my ($slf, $ctx, $lvl, $pre, $trc, @sct) = @_;

  # Prepare the block for the execution
  $slf->{'_stk'} = [];
  $slf->{'_thr'} = 0;
  if ($lvl)
  { $slf->{'_lib'} = {%{$ctx->get_lib}};
    $slf->{'_par'} = $ctx;
  }

  # Determine the trace requirements
  $slf->{'ctx'}->set_trace(($slf->get_top('out') || !defined($trc)) ? 0 : $trc);
  $slf->{'pre'} = $pre || 'TRACE/EVAL/';

  # Execute the block and return the error number
  $slf->exec($ctx, $lvl, undef, @sct);
}

=head2 S<$h-E<gt>exec($req,$lvl[,$arg[,section,...]])>

This method executes code sections. It returns the error count.

=cut

sub exec
{ my ($slf, $req, $lvl, $arg, @arg) = @_;
  my ($ctx, $err, $flg, $nam, $ret, $sct, $use);

  # Abort the execution if the object is not appropriate
  return -1
    unless exists($slf->{'_sct'}) && exists(($sct = $slf->{'_sct'})->{'-'});

  # Evalue the argument list before adjusting the context
  $arg =
    (ref($arg) =~ $VALUE) ?
      $arg->eval_value :
    (ref($arg) eq 'HASH') ?
      RDA::Value::Assoc::new_from_data(%$arg) :
    undef;

  # Execute the begin treatment for the loaded classes
  if ($lvl)
  { my ($dst, $src, $top, @cls);

    $slf->{'_par'} = $req;

    # Transfer new existing classes
    $top = $req->get_top;
    $src = $slf->{'use'};
    $dst = $top->{'use'};
    $flg = $slf->{'_use'};
    @cls = grep {!exists($dst->{$_})} keys(%$src);
    foreach my $cls (sort {$src->{$a}->{'rnk'} <=> $src->{$b}->{'rnk'}
      || $a cmp $b} @cls)
    { $dst->{$cls} = $src->{$cls};
      &{$src->{$cls}->{'beg'}}($top, $flg->{$cls})
        if exists($src->{$cls}->{'beg'});
    }
  }
  else
  { $flg = $slf->{'_use'};
    $use = $slf->{'use'};
    foreach my $cls (sort {$use->{$a}->{'rnk'} <=> $use->{$b}->{'rnk'}
      || $a cmp $b} keys(%$use))
    { &{$use->{$cls}->{'beg'}}($slf, $flg->{$cls})
        if exists($use->{$cls}->{'beg'});
    }
  }

  # Create the execution context and manage recursive calls
  $ctx = $slf->{'ctx'}->push_context($slf, $req->{'ctx'}, $lvl);

  # Declare the arguments
  if (ref($arg) =~ $VALUE)
  { if ($arg->is_list)
    { $ctx->set_value('@arg', $arg);
    }
    else
    { $slf->{'_arg'} = $ctx->set_object('$[ARG]', $arg, 1);
    }
  }

  # Select the sections to execute
  $slf->{'sct'} = {map {$_ => 0} @{$slf->{'_exe'}}};
  $slf->{'val'} = undef;
  if (@arg)
  { $slf->{'nxt'} = [];
    foreach my $str (@arg)
    { foreach my $nam (split(/\|/, $str))
      { next unless exists($sct->{$nam}) && $nam !~ m/^(begin|end|\-)$/;
        push(@{$slf->{'nxt'}}, $nam);
        last;
      }
    }
    return 0 unless @{$slf->{'nxt'}};
  }
  elsif (@{$slf->{'_exe'}})
  { $slf->{'nxt'} = [@{$slf->{'_exe'}}];
  }
  else
  { $slf->{'nxt'} = ['-'];
    $slf->{'dft'} = 1;
  }
  unshift(@{$slf->{'nxt'}}, 'begin') if exists($sct->{'begin'});

  # Execute the selected sections
  $err = 0;
  unless ($slf->{'dft'})
  { $ctx->{'val'} = $VAL_UNDEF;
    eval {$ret = $sct->{'-'}->_exec_block("section '-'")};
    $ret = $slf->check_die($@) if $@;
    ++$err if $ret < 0;
    $slf->{'dft'} = 1;
  }
  $ctx->{'val'} = $VAL_UNDEF;
  while (defined($nam = shift(@{$slf->{'nxt'}})))
  { next unless exists($sct->{$nam});
    last if $slf->check_quotas;
    $slf->{'sct'}->{$nam} = 1;
    eval {$ret = $sct->{$nam}->_exec_block("section '$nam'")};
    $ret = $slf->check_die($@) if $@;
    if ($ret)
    { ++$err unless $ret > 0;
      last;
    }
  }
  $slf->{'val'} = $ctx->get_internal('val')->eval_as_scalar
    unless $ret < 0;
  if (exists($sct->{'end'}))
  { $slf->{'sct'}->{'end'} = 1;
    eval {$ret = $sct->{'end'}->_exec_block("section 'end'")};
    $ret = $slf->check_die($@) if $@;
    ++$err if $ret < 0;
  }

  # Restore the previous context
  $ctx->pop_context($slf, $lvl ? $req : undef);

  # Complete main level execution
  unless ($lvl)
  { # Wait for thread completion
    _exe_wait($slf);

    # Execute the end treatment for the loaded classes
    $use = $slf->{'use'};
    foreach my $cls (sort {$use->{$b}->{'rnk'} <=> $use->{$a}->{'rnk'}
      || $b cmp $a} keys(%$use))
    { &{$use->{$cls}->{'end'}}($slf) if exists($use->{$cls}->{'end'});
    }
  }

  # Return the error count
  $err;
}

=head2 S<$h-E<gt>exec_block([$dsc])>

This method executes the block, preserving the last value of its context. It
returns 0 on successful completion, otherwise, the return code.

=cut

sub exec_block
{ my ($slf, $dsc) = @_;
  my ($ret, $old);

  # Check if the block has been deleted
  return 0 unless exists($slf->{'_cod'});

  # Execute the block, preserving the last variable
  $old = $slf->{'ctx'}->{'val'};
  $ret = $slf->_exec_block($dsc);
  $slf->{'ctx'}->{'val'} = $old;
  $ret;
}

sub _exec_block
{ my ($slf, $dsc, $arg) = @_;
  my ($ctx, $job, $ret, $top, $trc);

  # Determine the trace requirements
  $ctx = $slf->{'ctx'};
  $top = $slf->get_top;
  $trc = $top->{'pre'}.$slf->{'_pkg'}->{'oid'};
  $trc .= "|$job" if ($job = $top->{'job'});
  $ctx->set_prefix($trc);

  # Execute the code block
  $ctx->{'val'} = $VAL_UNDEF;
  if ($ctx->{'trc'})
  { $ctx->trace_string("Start $dsc");
    $ctx->set_value('@arg', $arg) if ref($arg);
    eval {$ret = $slf->_exec};
    if ($@)
    { $slf->gen_exec_err($@) unless $@ =~ $DIE;
      $ctx->trace_string("Abort $dsc") unless $@ eq $DIE_X;
      die $@;
    }
    $ret = $slf->gen_exec_err("RDA-00240: Break or next used outside a loop")
      if $ret == $RET_NXT || $ret == $RET_BRK;
    $ctx->trace_string("End $dsc");
  }
  else
  { $ctx->set_value('@arg', $arg) if ref($arg);
    $ret = $slf->_exec;
    $ret = $slf->gen_exec_err("RDA-00240: Break or next used outside a loop")
      if $ret == $RET_NXT || $ret == $RET_BRK;
  }

  # Return the last return code
  $ret;
}

=head2 S<$h-E<gt>exec_code($name[,$value])>

This method executes the named block and returns the last value. You can
specify an initial value for the last value.

=cut

sub exec_code
{ my ($slf, $nam, $arg) = @_;
  my ($ctx, $def, $old, $ret, $val);

  # Find the code block definition
  die "RDA-00269: Unknown named block '$nam'\n"
    unless ($def = $slf->{'ctx'}->find_code($nam));

  # Execute the code block and report errors
  $ctx = $def->{'ctx'};
  $ctx->trace_string("Start block $nam") if $ctx->{'trc'};

  $old = $ctx->{'val'};
  if (ref($arg))
  { $ctx->set_internal('val', $arg);
  }
  else
  { $ctx->{'val'} = $VAL_UNDEF;
  }
  eval {$ret = $def->_exec($slf)};
  $val = exists($def->{'val'}) ? $def->{'val'} : $ctx->{'val'};
  $ctx->{'val'} = $old;

  if ($@)
  { $ctx->trace_string("Abort block $nam") if $ctx->{'trc'};
    die $@;
  }
  $ret = $slf->gen_exec_err("RDA-00240: Break or next used outside a loop")
    if $ret == $RET_NXT || $ret == $RET_BRK;
  $ctx->trace_string("End block $nam") if $ctx->{'trc'};
  die "RDA-00270: Error encountered in the named block '$nam' called\n"
    if $ret < 0;

  # Return the last value
  $val;
}

=head2 S<$h-E<gt>get_access>

This method returns a reference to the access control object.

=cut

sub get_access
{ my ($slf) = @_;

  $slf = $slf->get_top;
  return $slf->{'pwd'} if ref($slf->{'pwd'});
  $slf->{'pwd'} = $slf->{'agt'}->get_access;
}

=head2 S<$h-E<gt>get_agent([$key[,$default]])>

This method returns the value of an agent object key or the default
value when the key is not defined.

It returns the reference of the agent object when no key is specified.

=cut

sub get_agent
{ my ($slf, $key, $val) = @_;

  defined($key)
    ? $slf->{'_pkg'}->{'agt'}->get_info($key, $val)
    : $slf->{'_pkg'}->{'agt'};
}

=head2 S<$h-E<gt>get_config([$key[,$default]])>

This method returns the value of an RDA software configuration object key or
the default value when the key is not defined.

It returns the reference of the RDA software configuration object when no key
is specified.

=cut

sub get_config
{ my ($slf, $key, $val) = @_;

  defined($key)
    ? $slf->{'_pkg'}->{'cfg'}->get_info($key, $val)
    : $slf->{'_pkg'}->{'cfg'};
}

=head2 S<$h-E<gt>get_context>

This method returns the reference of the current execution context.

=cut

sub get_context
{ shift->{'ctx'};
}

=head2 S<$h-E<gt>get_context>

This method returns the reference of the current execution package.

=cut

sub get_current
{ shift->{'ctx'}->get_current;
}

=head2 S<$h-E<gt>get_info($key[,$default])>

This method returns the value of the given object key. If the object key does
not exist, then it returns the default value.

=cut

sub get_info
{ my ($slf, $key, $val) = @_;

  exists($slf->{$key}) ? $slf->{$key} : $val;
}

=head2 S<$h-E<gt>get_inline>

This method returns the reference of the inline code control object.

=cut

sub get_inline
{ my ($slf) = @_;
  my ($cls);

  $slf = $slf->get_top;
  unless (exists($slf->{'inc'}))
  { $cls = 'RDA::Object::Inline';
    load_class($slf, $cls, 0, $cls);
    &{$slf->{'use'}->{$cls}->{'beg'}}($slf, $slf->{'_use'}->{$cls});
  }
  $slf->{'inc'}
}

=head2 S<$h-E<gt>get_lib>

This method returns the reference of the macro library.

=cut

sub get_lib
{ shift->{'_pkg'}->{'_lib'};
}

=head2 S<$h-E<gt>get_lock>

This method returns the reference of the lock control object.

=cut

sub get_lock
{ my ($slf) = @_;

  $slf = $slf->get_top;
  unless (exists($slf->{'lck'}))
  { eval {
      require RDA::Object::Lock;
      $slf->{'lck'} = RDA::Object::Lock->new($slf->get_agent,
        $slf->get_output->get_path('L', 1));
    };
    $slf->{'lck'} = undef if $@;
  }
  $slf->{'lck'};
}

=head2 S<$h-E<gt>get_oid>

This method returns the package identifier.

=cut

sub get_oid
{ shift->{'_pkg'}->{'oid'};
}

=head2 S<$h-E<gt>get_output>

This method returns the reference of the report control object.

=cut

sub get_output
{ my ($out);

  return $out if ($out = shift->get_top('rpt'));
  die "RDA-00248: Reporting disabled\n"
}

=head2 S<$h-E<gt>get_package([$key[,$default]])>

This method returns the value of a package object key or the default value
when the key is not defined.

It returns the reference of the package when no key is specified.

=cut

sub get_package
{ my ($slf, $key, $val) = @_;

  defined($key)
    ? $slf->{'_pkg'}->get_info($key, $val)
    : $slf->{'_pkg'};
}

=head2 S<$h-E<gt>get_remote>

This method returns the reference of the remote session control object.

=cut

sub get_remote
{ my ($slf) = @_;
  my ($cls);

  $slf = $slf->get_top;
  unless (exists($slf->{'rem'}))
  { $cls = 'RDA::Object::Remote';
    load_class($slf, $cls, 0, $cls);
    &{$slf->{'use'}->{$cls}->{'beg'}}($slf, $slf->{'_use'}->{$cls});
  }
  $slf->{'rem'}
}

=head2 S<$h-E<gt>get_report>

This method returns a reference to the current report.

=cut

sub get_report
{ shift->get_output->get_info('cur');
}

=head2 S<$h-E<gt>get_top([$key[,$default]])>

This method returns the value of a top package object key or the default value
when the key is not defined.

It returns the reference of the top package when no key is specified.

=cut

sub get_top
{ my ($slf, $key, $val) = @_;

  $slf = $slf->{'_pkg'};
  while (exists($slf->{'_par'}))
  { $slf = $slf->{'_par'}->{'_pkg'};
  }
  defined($key)
    ? $slf->get_info($key, $val)
    : $slf;
}

=head2 S<$h-E<gt>get_version>

This method returns the version number of the specifications.

=cut

sub get_version
{ shift->{'ver'};
}

=head2 S<$h-E<gt>load($agt[,$flg])>

This method loads and parses the data collection specifications. The file name
is deduced from the object identifier by adding a C<.def> suffix to it.

=cut

sub load
{ my ($slf, $agt, $flg) = @_;
  my ($fil, $ifh);

  # Determine the data collection specification file
  $ifh = IO::File->new;
  $fil = RDA::Object::Rda->cat_file($slf->{'dir'}, $slf->{'oid'});

  # Load and parse the file
  $slf->parse($agt,
    ($ifh->open("<$fil.def") || $ifh->open("<$fil.ctl")) ? $ifh : undef, $flg);
}

=head2 S<$h-E<gt>parse($agt,$ifh[,$flg])>

This method parses the data collection specifications from the specified input
handle. It closes the specification file at the end of parsing.

=cut

sub parse
{ my ($slf, $agt, $ifh, $flg) = @_;
  my ($buf, $cmd, $cur, $lin, $nam, $off, $par, $pod, $spc, $sub, $txt, $typ);

  # Load and parse the file
  $slf->{'_lin'} = $slf->{'_err'} = 0;
  if ($ifh)
  { $lin = '';
    $pod = $sub = $txt = 0;

    # Initialize operators and default classes
    $slf->{'agt'} = $agt;
    $slf->{'cfg'} = $agt->get_config;
    $slf->{'dsp'} = $agt->get_display;
    $slf->{'nam'} = $agt->get_oid;
    $slf->{'opr'} = $agt->get_operators;
    $slf->{'out'} = $agt->get_info('out');
    load_class($slf, 'RDA::Object::Rda',    1, 'RDA::Object::Rda');
    load_class($slf, 'RDA::Object::Env',    1, 'RDA::Object::Env');
    load_class($slf, 'RDA::Object::Access', 1, 'RDA::Object::Access');
    load_class($slf, 'RDA::Object::Target', 1, 'RDA::Object::Target');
    if ($flg)
    { load_class($slf, 'RDA::Object::Display', 1, 'RDA::Object::Display');
      load_class($slf, 'RDA::Object::Pipe',    1, 'RDA::Object::Pipe');
      load_class($slf, 'RDA::Object::Report',  1, 'RDA::Object::Report');
      load_class($slf, 'RDA::Object::Toc',     1, 'RDA::Object::Toc');
    }
    load_class($slf, 'RDA::Object::Windows', 1, 'RDA::Object::Windows');
    if (defined($cur = $agt->get_setting('RDA_CLASSES')))
    { foreach my $cls (split(/,/, $cur))
      { load_class($slf, $cls, 1, $cls) if $cls =~ m/^RDA::Object::\w+$/;
      }
    }

    # Create the top code block
    $cur = $slf->new('S', '-');
    $off = '  ' x $cur->{'_lvl'};

    # Treat all lines
    $par = undef;
    while (defined($buf = $ifh->getline))
    { # Trim leading spaces and join continuation line
      $slf->{'_lin'}++;
      $buf =~ s/^\s*//;
      $buf =~ s/[\r\n]+$//;
      $lin .= $buf;
      next if $lin =~ s/\\$//;
      $lin =~ s/\s+$//;

      # Ignore a documentation block
      if ($pod)
      { $pod = 0 if $lin =~ m/^=cut/;
        $lin = '';
        next;
      }
      if ($lin =~ m/^=[a-z]/)
      { $pod = 1;
        $lin = '';
        next;
      }

      # Detect and treat the beginning of a block
      if ($lin =~ s/^\{\s*//)
      { # Generate an error if a block is not expected
        $slf->gen_load_err("RDA-00272: Invalid block start") unless $sub;

        # Do not limit the block to a single line
        $sub = 0;
      }

      # Treat the line
      if ($lin =~ m/^\}(\s*\#.*)?$/)
      { # Indicate that a code or text block must be closed
        if ($par)
        { $sub = 1;
        }
        else
        { $slf->gen_load_err("RDA-00273: Invalid block end");
        }
      }
      elsif ($txt)
      { # Take all lines without other processing
        $lin =~ s/^["]//;
        push(@{$cur->[$SPC_VAL]}, $lin);
      }
      elsif ($lin !~ m/^#/ && $lin !~ m/^$/)
      { # Create the specification and parse the arguments
        if ($lin =~ s/^(\w+)// && exists($slf->{'cmd'}->{$1}))
        { $cmd = $slf->{'cmd'}->{$1};
          $spc = [$cmd->[$EXE_FCT], undef, undef, undef, $slf->{'_lin'},
            $slf->{'_lin'}.'.'.$off.$1.$lin];
          $lin =~ s/^\s*//;
        }
        else
        { $cmd = $slf->{'cmd'}->{'calc'};
          $lin = $1.$lin if defined($1);
          $spc = [$cmd->[$EXE_FCT], undef, undef, undef, $slf->{'_lin'},
            $slf->{'_lin'}.'.'.$off.'[calc] '.$lin];
        }
        eval {&{$cmd->[$GET_FCT]}($cur, $spc, \$lin, $cmd)};
        if ($@)
        { $slf->gen_load_err($@);
        }
        elsif ($lin !~ m/^(#.*)?$/)
        { $slf->gen_load_err("RDA-00275: Invalid characters at end of line");
        }
        $typ = $cmd->[$SUB_BLK];

        # Add the command in the current block
        push(@{$cur->{'_cod'}}, $spc) if $spc->[$SPC_FCT];

        # Prepare the parsing of a subblock
        if ($typ eq 'S')
        { $slf->gen_load_err("RDA-00274: Missing block end") if $par;
          if ($nam = $spc->[$SPC_REF])
          { if (exists($slf->{'_sct'}->{$nam}))
            { $slf->gen_load_err("RDA-00271: Duplicate section '$nam'")
            }
            else
            { $cur = $slf->new($typ, $spc->[$SPC_REF]);
              $off = '  ' x $cur->{'_lvl'};
            }
          }
        }
        elsif ($typ)
        { $par = $cur;
          if ($txt = $cmd->[$TXT_BLK])
          { $cur = $spc;
            $cur->[$SPC_VAL] = [];
          }
          else
          { $spc->[$SPC_BLK] = $cur = $cur->new($typ);
            $off = '  ' x $cur->{'_lvl'};
            push(@{$cur->{'_nam'}}, $spc->[$SPC_OBJ]) if $typ eq 'L';
          }
          $sub = 2;
        }
      }
      elsif ($lin =~ m/\$[Ii]d\:\s+\S+\s+(\d+)(\.(\d+))?\s/)
      { $slf->{'ver'} = sprintf('%d.%02d', $1, $3 || 0);
      }
      $lin = '';

      # Check of a subblock must be closed
      if ($sub > 0 && --$sub == 0)
      { # Perform the specified post treatment
        &$txt($slf, $cur) if ref($txt) eq 'CODE';

        # Return to the previous level
        $txt = 0;
        $cur = $par;
        $off = '  ' x $cur->{'_lvl'};
        $par = exists($cur->{'_par'}) ? $cur->{'_par'} : undef;
      }
    }
    $slf->gen_load_err("RDA-00274: Missing block end") if $par;
    $ifh->close;
  }
  else
  { $slf->gen_load_err(
      "RDA-00260: Cannot open the specification file '".$slf->{'oid'}."': $!");
  }

  # Delete the code when there are errors
  $slf->delete_sections if $slf->{'_err'};

  # Returns the number of errors found
  $slf->{'_err'};
}

=head2 S<$h-E<gt>run or $h-E<gt>run($name,$arg,$ctx)>

This method executes a data collection or macro code block. You can pass
arguments as a list value.

=cut

sub run
{ my ($slf, $nam, $arg, $blk) = @_;
  my ($ctx, $ret);

  # Evalue the argument list before adjusting the context
  $arg = $arg->eval_value if ref($arg);

  # Execute the associated code block
  $ctx = $slf->{'ctx'}->push_context($blk, $blk->{'ctx'});
  $ret = $slf->_exec_block("macro '$nam'", $arg);
  $ret = $ctx->get_internal('val') unless $ret < 0;
  $ctx->pop_context;

  # Return the error indicator or the last value.
  $ret;
}

=head2 S<$h-E<gt>set_info($key[,$value])>

This method assigns a new value to the given object key when the value is
defined. Otherwise, it deletes the object attribute.

It returns the previous value.

=cut

sub set_info
{ my ($slf, $key, $val) = @_;

  if (defined($val))
  { ($slf->{$key}, $val) = ($val, $slf->{$key});
  }
  else
  { $val = delete($slf->{$key});
  }
  $val;
}

=head2 S<$h-E<gt>xref($agent)>

This method produces a cross-reference of the macro definitions and the macro
and module calls.

=cut

sub xref
{ my ($slf, $agt) = @_;
  my ($buf, $err, $lib, $tbl, $xrf);

  # Analyze the code
  $err = $slf->load($agt, 1);
  $xrf = {};
  foreach my $sct ('-', 'begin', @{$slf->{'_exe'}}, 'end')
  { _xref_code($xrf, $slf->{'_sct'}->{$sct}) if exists($slf->{'_sct'}->{$sct});
  }

  # Display the cross-reference
  $buf = _dsp_name("Module ".$slf->{'oid'}.".def Cross Reference");
  $buf .= _dsp_text($RPT_XRF, "$err error(s) detected at load") if $err;
  $buf .= $RPT_NXT;

  # List called modules
  $buf .= _dsp($xrf->{'run'}, $xrf->{'run'}, 'Called Modules:', 'module');

  # Classify the macros
  $agt->get_macros($lib = {});
  foreach my $nam (sort keys(%{$xrf->{'mac'}}))
  { push(@{$xrf->{exists($xrf->{'def'}->{$nam}) ? 'mcl' :
                  exists($lib->{$nam})          ? 'mcp' :
                                                  'mco'}}, $nam);
  }
  $buf .= _dsp($xrf->{'def'}, $xrf->{'def'}, 'Locally Defined Macros:');
  $buf .= _dsp($xrf->{'mcl'}, $xrf->{'mac'}, 'Calls to Local Macros:');
  $buf .= _dsp($xrf->{'mcp'}, $xrf->{'mac'}, 'Calls to Predefined Macros:');
  $buf .= _dsp($xrf->{'mco'}, $xrf->{'mac'}, 'Calls to other Macros:');

  # Classify the methods
  foreach my $cls (sort keys(%{$slf->{'use'}}))
  { $tbl = $slf->{'use'}->{$cls};
    foreach my $nam (keys(%{$tbl->{'met'}}))
    { push(@{$xrf->{'mtd'}->{$nam}}, $cls);
    }
    foreach my $nam (keys(%{$tbl->{'als'}}))
    { my ($obj, $met, @arg) = @{$tbl->{'als'}->{$nam}};
      push(@{$xrf->{'ald'}->{$nam}},
        '``'.$obj.'->'.$met.'('.join(',', @arg, '...').')``');
    }
  }
  foreach my $nam (sort keys(%{$xrf->{'met'}}))
  { push(@{$xrf->{exists($xrf->{'mtd'}->{$nam}) ? 'mtu' : 'mto'}}, $nam);
  }
  $buf .= _dsp($slf->{'use'}, undef,         'Included Classes:', 'xref_obj');
  $buf .= _dsp($xrf->{'als'}, $xrf->{'als'}, 'Alias Usage:');
  $buf .= _dsp($xrf->{'mtu'}, $xrf->{'met'}, 'Method Usage:');
  $buf .= _dsp($xrf->{'prp'}, $xrf->{'prp'}, 'Property Usage:');
  $buf .= _dsp($xrf->{'als'}, $xrf->{'ald'}, 'Alias Definitions:');
  $buf .= _dsp($xrf->{'mtu'}, $xrf->{'mtd'}, 'Method Definitions:');
  $buf .= _dsp($xrf->{'mto'}, $xrf->{'met'}, 'Unknown Methods:');

  # Classify the named blocks
  foreach my $nam (sort keys(%{$xrf->{'cod'}}))
  { push(@{$xrf->{exists($xrf->{'cdd'}->{$nam}) ? 'cdu' : 'cdo'}}, $nam);
  }
  $buf .= _dsp($xrf->{'cdd'}, $xrf->{'cdd'}, 'Named Blocks:');
  $buf .= _dsp($xrf->{'cdu'}, $xrf->{'cod'}, 'Named Block Usage:');
  $buf .= _dsp($xrf->{'cdo'}, $xrf->{'cod'}, 'Unknown Named Blocks:');

  # Classify the operators
  $buf .= _dsp($xrf->{'opr'}, $xrf->{'opr'}, 'Operator Usage:');

  # Return the report
  $buf;
}

# Display a result set
sub _dsp
{ my ($key, $lin, $ttl, $typ) = @_;
  my ($buf, $lgt, $lnk, $max);

  return '' unless defined($key);

  # Determine the name length
  $key = [sort keys(%$key)] if ref($key) eq 'HASH';
  $max = 0;
  foreach my $nam (@$key)
  { $max = $lgt if ($lgt = length($nam)) > $max;
  }
  return '' unless $max;

  # Display the table
  $buf = _dsp_title($ttl);
  if (defined($lin))
  { if ($typ)
    { $max += 6 + length($typ);
    }
    else
    { $lgt = $max + 4;
    }
    foreach my $nam (@$key)
    { if ($typ)
      { $lnk = ($nam =~ m/^<\w+>$/) ? "``$nam``" : "!!$typ:$nam!$nam!!";
        $lgt = $max + length($nam);
      }
      else
      { $lnk = "``$nam``";
      }
      $buf .= _dsp_text(sprintf("%s\001%-*s  ", $RPT_XRF, $lgt, $lnk),
        join(', ', @{$lin->{$nam}}));
    }
  }
  elsif ($typ)
  { foreach my $nam (@$key)
    { $nam =~ m/([^:]*)$/;
      $buf .= _dsp_text($RPT_XRF, "!!$typ:$1!$nam!!");
    }
  }
  else
  { foreach my $nam (@$key)
    { $buf .= _dsp_text($RPT_XRF, "``$nam``");
    }
  }
  $buf.$RPT_NXT;
}

sub _dsp_name
{ my ($ttl) = @_;

  ".R '$ttl'\n"
}

sub _dsp_text
{ my ($pre, $txt, $nxt) = @_;

  $txt =~ s/\n{2,}/\n\\040\n/g;
  $txt =~ s/(\n|\\n)/\n\n.I '$pre'\n/g;
  ".I '$pre'\n$txt\n\n".($nxt ? ".N $nxt\n" : "");
}

sub _dsp_title
{ my ($ttl) = @_;

  ".T '$ttl'\n"
}

# Analyse recursively the code
sub _xref_code
{ my ($xrf, $blk) = @_;
  my ($cod, $lin);

  foreach my $spc (@{$blk->{'_cod'}})
  { $lin = $spc->[$SPC_LIN];
    if (defined($spc->[$SPC_REF]))
    { $cod = $spc->[$SPC_COD];
      if ($cod =~ m/^\d+\.\s*code\b/)
      { push(@{$xrf->{'cdd'}->{'SDCL.'.$spc->[$SPC_REF]}}, $lin);
      }
      elsif ($cod =~ m/^\d+\.\s*java\b/)
      { push(@{$xrf->{'cdd'}->{'Java.'.$spc->[$SPC_REF]}}, $lin);
      }
      elsif ($cod =~ m/^\d+\.\s*macro\b/)
      { push(@{$xrf->{'def'}->{$spc->[$SPC_REF]}}, $lin);
      }
      elsif ($cod =~ m/^\d+\.\s*run\b/)
      { push(@{$xrf->{'run'}->{ref($spc->[$SPC_REF])
          ? '<Ref>'
          : $spc->[$SPC_REF]}}, $lin);
      }
      elsif ($cod =~ m/^\d+\.\s*(append|set)\b/)
      { _xref_set($xrf, $spc->[$SPC_VAL], $lin);
      }
      else
      { _xref_value($xrf, $spc->[$SPC_REF], $lin);
      }
    }
    _xref_value($xrf, $spc->[$SPC_VAL], $lin);
    _xref_code($xrf, $spc->[$SPC_BLK]) if ref($spc->[$SPC_BLK]);
  }
}

# Analyse append/set text
sub _xref_set
{ my ($xrf, $obj, $lin) = @_;
  my ($val, %tbl);

  $val = $obj->{'val'};
  %tbl = map {$_ => 1}
    $val =~ m/___Macro_(\w+)\(\d+\)___/g,
    $val =~ m/\!\!call\s+(\w+)\(\d+\)\s*$/g,
    $val =~ m/^#\s*CALL\s+(\w+)\(\d+\)\s*$/g,
    $val =~ m/^#\s*MACRO\s+(\w+)\(\d+\)\s*$/g;
  foreach my $nam (keys(%tbl))
  { push(@{$xrf->{'mac'}->{$nam}}, $lin);
  }
}

# Analyse recursively a value
sub _xref_value
{ my ($xrf, $obj, $lin) = @_;
  my ($ref, $val);

  $ref = ref($obj);
  if ($ref eq 'RDA::Value::Operator')
  { $val = $obj->is_operator;
    if ($val eq '.macro.')
    { push(@{$xrf->{'mac'}->{$obj->{'nam'}}}, $lin);
      _xref_value($xrf, $val, $lin) if ref($val = $obj->{'arg'});
    }
    elsif ($val eq '.method.')
    { if (exists($obj->{'als'}))
      { push(@{$xrf->{'als'}->{$obj->{'als'}}}, $lin);
      }
      else
      { push(@{$xrf->{'met'}->{$obj->{'nam'}}}, $lin);
      }
      _xref_value($xrf, $val, $lin) if ref($val = $obj->{'arg'});
      _xref_value($xrf, $val, $lin) if ref($val = $obj->{'par'});
    }
    else
    { push(@{$xrf->{'opr'}->{$val}}, $lin) if $val !~ m/^\./;
      foreach my $key (keys(%$obj))
      { _xref_value($xrf, $obj->{$key}, $lin) unless $key =~ m/^_/;
      }
    }
  }
  elsif ($ref eq 'RDA::Value::Array' || $ref eq 'RDA::Value::List'||
      $ref eq 'ARRAY')
  { foreach my $ptr (@$obj)
    {_xref_value($xrf, $ptr, $lin);
    }
  }
  elsif ($ref eq 'RDA::Value::Assoc' || $ref eq 'RDA::Value::Hash'||
      $ref eq 'HASH')
  { foreach my $ptr (values(%$obj))
    { _xref_value($xrf, $ptr, $lin);
    }
  }
  elsif ($ref eq 'RDA::Value::Code')
  { if (exists($obj->{'cod'}))
    { _xref_value($xrf, $obj->{'cod'}, $lin)
    }
    else
    { push(@{$xrf->{'cod'}->{$obj->{'lng'}.'.'.$obj->{'nam'}}}, $lin);
      _xref_value($xrf, $val, $lin) if ref($val = $obj->{'arg'});
    }
  }
  elsif ($ref eq 'RDA::Value::Property')
  { push(@{$xrf->{'prp'}->{($obj->{'grp'} eq '-')
      ? $obj->{'nam'} : $obj->{'grp'}.'.'.$obj->{'nam'}}}, $lin);
    _xref_value($xrf, $val, $lin) if ref($val = $obj->{'dft'});
  }
}

# --- Parsing routines -------------------------------------------------------

# Get an alias definition
sub _get_alias
{ my ($slf, $spc, $str) = @_;
  my ($nam, $val);

  die "RDA-00246: Invalid or missing alias name\n"
    unless $$str =~ s/^(\w+)\s+//;
  $nam = $1;
  $$str =~ s/=\s*//;
  die "RDA-00247: Invalid or missing alias definition\n"
    unless ($val = $slf->parse_value($str))->is_method;
  $slf->{'_pkg'}->{'als'}->{$nam} = $val;
}

# Get a break/next condition
#   value
#   !value
#   !?value
#   ?value
#   <NAME> value
#   <NAME> !value
#   <NAME> !?value
#   <NAME> ?value
sub _get_break
{ my ($slf, $spc, $str) = @_;
  my ($nam);

  die "RDA-00240: Break or next used outside a loop\n"
    unless exists($slf->{'_nam'});
  if ($$str =~ s/^\<([A-Za-z]\w+)\>\s*//)
  { $spc->[$SPC_OBJ] = $nam = lc($1);
    die "RDA-00276: No corresponding loop\n"
      unless grep {$_ eq $nam} @{$slf->{'_nam'}};
  }
  else
  { $spc->[$SPC_OBJ] = $slf->{'_nam'}->[-1];
  }
  $spc->[$SPC_REF] = ($$str =~ s/^(\!\?{0,1}|\?)\s*//) ? $1 : '';
  $spc->[$SPC_VAL] = $slf->parse_value($str) || $VAL_ONE;
}

# Get a macro call
sub _get_call
{ my ($slf, $spc, $str) = @_;
  my ($var);

  die "RDA-00210: Invalid or missing macro call\n"
    unless ref($var = $slf->parse_value($str)) && $var->is_call;
  $spc->[$SPC_VAL] = $var;
}

# Get a class name
sub _get_class
{ my ($slf, $spc, $str) = @_;

  if ($$str =~ s/^(RDA::Object::([A-Z]\w*::)*[A-Z]\w*)\s*//i)
  { load_class($slf->{'_pkg'}, $1, 1, $1);
  }
  elsif ($$str =~ s/^(([A-Z]\w*::)*[A-Z]\w*)\s*//i)
  { load_class($slf->{'_pkg'}, $1, 1, "RDA::Object::$1");
  }
  elsif ($$str =~ s/(([\$\@\%])\[\w+\])\s*//)
  { $slf->{'_pkg'}->{'glb'}->{$1} = 0;
  }
  else
  { die "RDA-00268: Bad class\n";
  }
}

sub _load_arg
{ my ($slf, $str) = @_;

  ($str =~ m/^(\$)\{((\w+\.)*\w+)\}$/) ?
    RDA::Value::Property->new($slf, $1, $2) :
  ($str =~ m/^\$\[\w+\]$/) ?
    RDA::Value::Global->new($slf->{'ctx'}, $str) :
  RDA::Value::Scalar::new_text($str);
}

sub load_class
{ my ($slf, $nam, $flg, @cls) = @_;
  my ($dsc, $err, $glb, $ref, $rnk);

  foreach my $cls (@cls)
  { if (exists($slf->{'use'}->{$cls}))
    { $dsc = $slf->{'use'}->{$cls};
      if ($flg)
      { $slf->{'_use'}->{$cls} = 1;
        if (exists($dsc->{'glb'}))
        { foreach my $key (@{$dsc->{'glb'}})
          { $slf->{'glb'}->{$key} = 1;
          }
        }
      }
      return $dsc;
    }
    eval "require $cls";
    unless ($err = $@)
    { $dsc = {eval "\%${cls}::SDCL"};
      die "RDA-00267: Bad object '$cls':\n $@\n" if $@;
      $dsc->{'rnk'} = $rnk = 10;
      $slf->{'use'}->{$cls} = $dsc;
      $slf->{'_use'}->{$cls} = $glb = $dsc->{'flg'} ? 1 : $flg;

      # Treat dependencies
      if (exists($dsc->{'dep'}))
      { foreach my $key (@{$dsc->{'dep'}})
        { $ref = load_class($slf, $key, 0, $key);
          $rnk = $ref->{'rnk'} + 10 unless $rnk > $ref->{'rnk'};
        }
      }

      # Load the synonyms
      if (exists($dsc->{'syn'}))
      { foreach my $key (@{$dsc->{'syn'}})
        { $slf->{'use'}->{$key} = $ref = {%$dsc};
          $slf->{'_use'}->{$key} = 0;
          delete($ref->{'beg'});
          delete($ref->{'end'});
        }
      }

      # Extend the syntax
      if (exists($dsc->{'cmd'}))
      { foreach my $key (keys(%{$dsc->{'cmd'}}))
        { $slf->{'cmd'}->{$key} = $dsc->{'cmd'}->{$key};
        }
      }
      if ($glb && exists($dsc->{'glb'}))
      { foreach my $key (@{$dsc->{'glb'}})
        { $slf->{'glb'}->{$key} = 1;
        }
      }
      if (exists($dsc->{'inc'}))
      { foreach my $key (@{$dsc->{'inc'}})
        { $ref = load_class($slf, $key, 0, $key);
          $rnk = $ref->{'rnk'} + 10 unless $rnk > $ref->{'rnk'};
          foreach my $fct (keys %{$ref->{'met'}})
          { $dsc->{'met'}->{$fct} = $ref->{'met'}->{$fct}
              unless exists($dsc->{'met'}->{$fct});
          }
        }
        delete($dsc->{'inc'});
      }

      # Load the aliases
      if (exists($dsc->{'als'}))
      { foreach my $key (keys(%{$dsc->{'als'}}))
        { my ($obj, $met, @arg) = @{$dsc->{'als'}->{$key}};
          $slf->{'als'}->{$key} =
            ($obj =~ m/^(\$)\{((\w+\.)*\w+)\}$/) ?
              $slf->define_operator(['.method.'], $slf,
                RDA::Value::Property->new($slf, $1, $2),
                $met,
                RDA::Value::List->new(map {_load_arg($slf, $_)} @arg)) :
            ($obj =~ m/^\$\[\w+\]$/) ?
              $slf->define_operator(['.method.'], $slf,
                RDA::Value::Global->new($slf->{'ctx'}, $obj),
                $met,
                RDA::Value::List->new(map {_load_arg($slf, $_)} @arg)) :
            $dsc->{'als'}->{$key};
        }
      }

      # Store the rank
      $dsc->{'rnk'} = $rnk;

      # Treat subclasses
      if (exists($dsc->{'det'}))
      { foreach my $key (@{$dsc->{'det'}})
        { $ref = load_class($slf, $key, 0, $key);
        }
      }

      # Perform class initialization and return
      &{$dsc->{'use'}}($slf) if exists($dsc->{'use'});
      return $dsc;
    }
  }
  die "RDA-00266: Unknown object '$nam':\n $err\n";
}

# Get a named block declaration
sub _get_code
{ my ($slf, $spc, $str) = @_;

  die "RDA-00215: Invalid or missing name\n"
    unless $$str =~ s/^([A-Za-z]\w*)\s*//;
  $spc->[$SPC_REF] = $1;
  $spc->[$SPC_VAL] = $slf->parse_value($str) if $$str =~ s/=\s*//;
}

# Get a condition
#   value
#   !value
#   !?value
#   ?value
sub _get_cond
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_REF] = ($$str =~ s/^(\!\?{0,1}|\?)\s*//) ? $1 : '';
  $spc->[$SPC_VAL] = $slf->parse_value($str) || $VAL_ONE;
}

sub _get_cond1
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_OBJ] = $slf->{'_ifc'} = ++$slf->{'_pkg'}->{'_ifc'};
  $spc->[$SPC_REF] = ($$str =~ s/^(\!\?{0,1}|\?)\s*//) ? $1 : '';
  $spc->[$SPC_VAL] = $slf->parse_value($str) || $VAL_ONE;
}

sub _get_cond2
{ my ($slf, $spc, $str) = @_;

  die "RDA-00242: Missing if command\n" unless $slf->{'_ifc'};
  $spc->[$SPC_OBJ] = $slf->{'_ifc'};
  $spc->[$SPC_REF] = ($$str =~ s/^(\!\?{0,1}|\?)\s*//) ? $1 : '';
  $spc->[$SPC_VAL] = $slf->parse_value($str) || $VAL_ONE;
}

sub _get_cond3
{ my ($slf, $spc, $str) = @_;

  die "RDA-00242: Missing if command\n" unless $slf->{'_ifc'};
  $spc->[$SPC_OBJ] = $slf->{'_ifc'};
}

# Get a decrement
#   $var
#   $var,$value
sub _get_decr
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->define_operator(['decr'], $slf, 'decr',
    $slf->parse_list($str));
}


# Get a variable list for a delete command
sub _get_delete
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->define_operator(['delete'], $slf, 'delete',
    $slf->parse_list($str));
}

# Get the parameters of a 'die' command
sub _get_die
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_REF] = ($$str =~ s/^(a(ll)?|m(odule)?|s(ection)?),\s*//i)
    ? uc(substr($1, 0, 1))
    : 'A';
  _get_list(@_);
}

# Get the parameters of a 'for' command
#   for $var (value1,value2,value3)
#   for $var (value1,value2)
#   for <NAME> $var (value1,value2,value3)
#   for <NAME> $var (value1,value2)
sub _get_for
{ my ($slf, $spc, $str) = @_;
  my ($cnt, $rec);

  # Get the loop name when present
  $spc->[$SPC_OBJ] = ($$str =~ s/^\<([A-Za-z]\w+)\>\s+//) ? lc($1) : '';

  # Get the for variable
  die "RDA-00211: Missing scalar variable\n"
    unless ($rec = $slf->parse_value($str)) && $rec->is_scalar_lvalue;
  $spc->[$SPC_REF] = $rec;

  # Get the for list
  $spc->[$SPC_VAL] = $rec = $slf->parse_sub_list($str);
  $cnt = @$rec;
  die "RDA-00212: Invalid command format\n" if $cnt < 2 || $cnt > 3;
}

# Get a global variable
sub _get_global
{ my ($slf, $spc, $str) = @_;
  my ($typ);

  die "RDA-00219: Invalid or missing variable\n"
    unless $$str =~ s/([\$\@\%]\[\w+\])\s*//;
  $slf->{'_pkg'}->{'glb'}->{$spc->[$SPC_REF] = $1} = 0;
  $spc->[$SPC_VAL] = $slf->parse_value($str) if $$str =~ s/=\s*//;
}

# Get an increment
#   $var
#   $var,$value
sub _get_incr
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->define_operator(['incr'], $slf, 'incr',
    $slf->parse_list($str));
}

# Get a list
#   <empty list>
#   value
#   value,...
sub _get_list
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->parse_list($str);
}

# Get the parameters of a 'loop' command
#   loop $var (list)
#   loop $var[value] (list)
#   loop $var{value} (list)
#   loop <NAME> $var (list)
#   loop <NAME> $var[value] (list)
#   loop <NAME> $var{value} (list)
sub _get_loop
{ my ($slf, $spc, $str) = @_;
  my ($rec);

  # Get the loop name
  $spc->[$SPC_OBJ] = ($$str =~ s/^\<([A-Za-z]\w+)\>\s*//) ? lc($1) : '';

  # Get the loop variable
  die "RDA-00211: Missing scalar variable\n"
    unless ($rec = $slf->parse_value($str)) && $rec->is_scalar_lvalue;
  $spc->[$SPC_REF] = $rec;

  # Get the loop list
  $spc->[$SPC_VAL] = $slf->parse_sub_list($str);
}

# Get a name
sub _get_name
{ my ($slf, $spc, $str) = @_;

  die "RDA-00215: Invalid or missing name\n"
    unless $$str =~ s/^([A-Za-z]\w*)\s*//;
  $spc->[$SPC_REF] = $1;
}

# Check that no argument has been provided
sub _get_none
{
}

# Get an report file
sub _get_output
{ my ($slf, $spc, $str) = @_;

  $slf->_get_report($spc, $str,
     ($$str =~ s/^(P|[EORS][NF])\s*,\s*//) ? $1 : 'OF');
}

# Get a report name
sub _get_report
{ my ($slf, $spc, $str, $typ) = @_;
  my $rec;

  if ($$str =~ s/^([A-Za-z]\w*)\s*(#.*)?$//)
  { $spc->[$SPC_REF] = $1;
    $typ = lc($typ) if $typ;
  }
  elsif (ref($rec = $slf->parse_value($str)))
  { $spc->[$SPC_REF] = $rec;
  }
  else
  { die "RDA-00215: Invalid or missing name\n"
  }
  $spc->[$SPC_VAL] = $typ;
}

# Get a module call
sub _get_run
{ my ($slf, $spc, $str) = @_;

  if ($$str =~ s/^\&\{\s*//)
  { $spc->[$SPC_REF] = $slf->parse_value($str);
    die "RDA-00216: Invalid or missing name\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str =~ s/^(\w+(\-\w+)*)\s*//)
  { $spc->[$SPC_REF] = $1;
  }
  else
  { die "RDA-00216: Invalid or missing name\n"
  }
  $spc->[$SPC_VAL] = $slf->parse_sub_list($str);
}

# Set thread specification
sub _get_thread
{ my ($slf, $spc) = @_;

  $spc->[$SPC_REF] = 1;
  _get_list(@_);
}

# Get a single value
#   number
#   "..."
#   '...'
#   @name
#   $name[value]
#   $name{value}
#   $name
#   name(value,...)
sub _get_value
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->parse_value($str);
}

# Assemble the lines of a text block
sub _merge_txt
{ my ($slf, $spc) = @_;
  $spc->[$SPC_VAL] =
    RDA::Value::Scalar::new_text(join("\n", @{$spc->[$SPC_VAL]}));
}

# Define or assign a variable or a list of variables
#   lvalue
#   lvalue = value
#   lvalue = (value,...)
#   (lvalue,...) = (value)
sub get_var_def
{ my ($slf, $spc, $str) = @_;
  my ($rec);

  die "RDA-00219: Invalid or missing variable\n"
    unless ($rec = $slf->parse_value($str));
  $spc->[$SPC_VAL] = ($rec->is_operator eq '.assign.')
    ? $rec
    : $slf->define_operator(['.assign.'], $rec, $rec->is_scalar_lvalue
        ? $VAL_UNDEF
        : RDA::Value::List->new);
}

# Get a variable list
sub get_var_list
{ my ($slf, $spc, $str) = @_;
  my @tbl;

  die "RDA-00220: Invalid value(s) found in variable list\n"
    unless $$str =~ s/^([\$\@\%]\w+)\s*//;
  do
  { push(@tbl, $1);
  } while $$str =~ s/^,\s*([\$\@\%]\w+)\s*//;
  $spc->[$SPC_VAL] = [@tbl];
}

# Get a variable followed by a text block
#  $var
#  $var[...]
#  $var{...}
sub get_var_txt
{ my ($slf, $spc, $str) = @_;
  my $rec;

  $spc->[$SPC_VAL] = [];
  if (ref($rec = $slf->parse_value($str)))
  { die "RDA-00221: Invalid variable\n" unless $rec->is_scalar_lvalue;
    $spc->[$SPC_REF] = $rec;
    $$str =~ s/^\=?\s*//;
  }
}

# Get a while/once condition
#   value
#   !value
#   !?value
#   ?value
#   <NAME> value
#   <NAME> !value
#   <NAME> !?value
#   <NAME> ?value
sub _get_while
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_OBJ] = ($$str =~ s/^\<([A-Za-z]\w+)\>\s*//) ? lc($1) : '';
  $spc->[$SPC_REF] = ($$str =~ s/^(\!\?{0,1}|\?)\s*//) ? $1 : '';
  $spc->[$SPC_VAL] = $slf->parse_value($str) || $VAL_ONE;
}

# Parse a list of values between parentheses
sub parse_sub_list
{ my ($slf, $str) = @_;
  my $rec;

  # Get the sublist
  die "RDA-00222: Missing opening parenthesis\n" unless $$str =~ s/^\(\s*//;
  $rec = $slf->parse_list($str, ')');
  die "RDA-00223: Missing closing parenthesis\n" unless $$str =~ s/^\)\s*//;

  # Return the list
  $rec;
}

# Parse a list of values
sub parse_list
{ my ($slf, $str, $del) = @_;
  my ($itm, @tbl);

  $del = '#' unless defined($del);
  if (length($$str) > 0 && substr($$str, 0, 1) ne $del
    && ref($itm = $slf->parse_value($str)))
  { # Get the first list element, merging sublists
    if ($itm->is_list)
    { push(@tbl, @$itm);
    }
    else
    { push(@tbl, $itm);
    }

    # Get next list elements, merging sublists
    while ($$str =~ s/^\s*(,|=>)\s*//)
    { last unless ref($itm = $slf->parse_value($str));
      if ($itm->is_list)
      { push(@tbl, @$itm);
      }
      else
      { push(@tbl, $itm);
      }
    }
  }
  RDA::Value::List->new(@tbl);
}

# Parse a value
sub parse_value
{ my ($slf, $str, $del) = @_;
  my ($arg, $nam, $rec, $typ);

  # Extract a value
  if ($$str =~ s/^'([^\']*)'\s*//)
  { $rec = RDA::Value::Scalar::new_text($1);
  }
  elsif ($$str =~ s/^"([^\"]*)\s*"//)
  { $arg = $1;
    $arg =~ s/(\\[0-7]{3}|\\0x[0-9A-Fa-f]{2})/chr(oct(substr($&,1)))/eg;
    $rec = RDA::Value::Scalar::new_text($arg);
  }
  elsif ($$str =~ s/^([-+])?(0x[\dA-Fa-f]+)\s*// ||
         $$str =~ s/^([-+])?0o([0-7]+)\s*//)
  { $rec = ($1 && $1 eq '-')
      ? RDA::Value::Scalar::new_number(-oct($2))
      : RDA::Value::Scalar::new_number(oct($2));
  }
  elsif ($$str =~ s/^([-+]?\d+(\.\d*)?([eE][\+\-]?\d+)?)\s*//)
  { $rec = RDA::Value::Scalar::new_number(0 + $1);
  }
  elsif ($$str =~ s/^\$(\w+)\s*\[\s*//)
  { $nam = "\@$1";
    $arg = $slf->parse_list($str, ']');
    die "RDA-00224: Invalid or missing array index\n" unless @$arg;
    $rec = $slf->define_operator(['.index.'],
      RDA::Value::Variable->new($slf->{'ctx'}, $nam), $arg);
    die "RDA-00225: Invalid array index end\n"
      unless $$str =~ s/^\]\s*//;
  }
  elsif ($$str =~ s/^\$(\w+)\s*\{\s*//)
  { $nam = "\%$1";
    $arg = $slf->parse_list($str, '}');
    die "RDA-00226: Invalid or missing hash key\n" unless @$arg;
    $rec = $slf->define_operator(['.key.'],
      RDA::Value::Variable->new($slf->{'ctx'}, $nam), $arg);
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str =~ s/^([\$\@\%]\[\w+\])\s*//)
  { die "RDA-00245: Undefined global variable '$1'\n"
      unless exists($slf->{'_pkg'}->{'glb'}->{$1});
    $rec = RDA::Value::Global->new($slf->{'ctx'}, $1);
  }
  elsif ($$str =~ s/^\@\{\s*last\s*\}\s*//)
  { $rec = $slf->define_operator(['.list.'],
      RDA::Value::Internal->new($slf->{'ctx'}, 'last'));
  }
  elsif ($$str =~ s/^([\$\@])\{\s*((\w+\.)*\w+)\s*([\:\}])/$4/)
  { $typ = $1;
    $nam = $2;
    $arg = ($$str =~ s/^:\s*//) ? $slf->parse_value($str, '}') : undef;
    $rec = RDA::Value::Property->new($slf, $typ, $nam, $arg);
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str =~ s/^([\$\@\%]\w+)\s*//)
  { $rec = RDA::Value::Variable->new($slf->{'ctx'}, $1);
  }
  elsif ($$str =~ s/^\\([\$\@\%]\w+)\s*//)
  { $rec = RDA::Value::Pointer->new($slf->{'ctx'}, $1);
  }
  elsif ($$str =~ s/^\&((\w+)\.)?(\w+)\s*(\((\s*eval:)?\s*)?//)
  { $typ = defined($1) ? $2 : 'SDCL';
    $nam = $3;
    if ($4)
    { $arg = $5;
      $rec = RDA::Value::Code->new($slf, $typ, $nam,
        $slf->parse_list($str, ')'), $arg);
      die "RDA-00228: Invalid argument list end\n"
        unless $$str =~ s/^\)\s*//;
    }
    else
    { $rec = RDA::Value::Code->new($slf, $typ, $nam);
    }
  }
  elsif ($$str =~ s/^(\w+)\s*\(\s*//)
  { $nam = $1;
    $arg = $slf->parse_list($str, ')');
    if (exists($slf->{'_pkg'}->{'als'}->{$nam}))
    { $rec = (ref($rec = $slf->{'_pkg'}->{'als'}->{$nam}) eq 'ARRAY')
        ? $slf->define_operator(['.alias.'], $slf, $rec, $arg)
        : $rec->clone($arg);
      $rec->set_info('als', $nam);
    }
    else
    { $rec = $slf->define_operator([$nam, '.macro.'], $slf, $nam, $arg);
    }
    die "RDA-00228: Invalid argument list end\n"
      unless $$str =~ s/^\)\s*//;
  }
  elsif ($$str =~ s/^(caller:\w+)\s*\(\s*//)
  { $nam = $1;
    $arg = $slf->parse_list($str, ')');
    $rec = $slf->define_operator(['.macro.'], $slf, $nam, $arg);
    die "RDA-00228: Invalid argument list end\n"
      unless $$str =~ s/^\)\s*//;
  }
  elsif ($$str =~ s/^(\w+)\s*\=>\s*/,/)
  { $rec = RDA::Value::Scalar::new_text($1);
  }
  elsif ($$str =~ s/^true\s*//)
  { $rec = $VAL_ONE;
  }
  elsif ($$str =~ s/^false\s*//)
  { $rec = $VAL_ZERO;
  }
  elsif ($$str =~ s/^undef\s*//)
  { $rec = $VAL_UNDEF;
  }
  elsif ($$str =~ s/^(error|last|line)\s*//)
  { $rec = RDA::Value::Internal->new($slf->{'ctx'}, $1);
  }
  elsif ($$str =~ m/^\(/)
  { $rec = $slf->parse_sub_list($str);
  }
  elsif ($$str =~ s/^\[\s*//)
  { $rec = $slf->define_operator(['.array.'], $slf->parse_list($str, ']'));
    die "RDA-00225: Missing closing bracket\n"
      unless $$str =~ s/^\]\s*//;
  }
  elsif ($$str =~ s/^\{\s*//)
  { $rec = $slf->define_operator(['.assoc.'], $slf->parse_list($str, '}'));
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str =~ s/^\@\{\s*//)
  { $rec = $slf->define_operator(['.list.'], $slf->parse_value($str, '}'));
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str =~ s/^\%\{\s*//)
  { $rec = $slf->define_operator(['.hash.'], $slf->parse_value($str, '}'));
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str !~ m/^(#.*)?$/)
  { die "RDA-00229: Invalid value\n";
  }

  # Extract operators
  for (;;)
  { if ($$str =~ s/^\-\>\s*\[\s*//)
    { $arg = $slf->parse_list($str, ']');
      die "RDA-00224: Invalid or missing array index\n" unless @$arg;
      $rec = $slf->define_operator(['.index.'], $rec, $arg);
      die "RDA-00225: Missing closing bracket\n"
        unless $$str =~ s/^\]\s*//;
    }
    elsif ($$str =~ s/^\-\>\s*\{\s*//)
    { $arg = $slf->parse_list($str, '}');
      die "RDA-00226: Invalid or missing hash key\n" unless @$arg;
      $rec = $slf->define_operator(['.key.'], $rec, $arg);
      die "RDA-00227: Missing closing brace\n"
        unless $$str =~ s/^\}\s*//;
    }
    elsif ($$str =~ s/^\-\>\s*(\w+)\s*\(\s*//)
    { $nam = $1;
      $rec = $slf->define_operator(['.method.'],
        $slf, $rec, $nam, $slf->parse_list($str, ')'));
      die "RDA-00228: Invalid argument list end\n"
        unless $$str =~ s/^\)\s*//;
    }
    elsif ($$str =~ s/^\-\>\s*(\w+)\s*//)
    { $nam = $1;
      $rec = $slf->define_operator(['.method.'],
        $slf, $rec, $nam, RDA::Value::List->new);
    }
    elsif ($$str =~ m/^\=\>\s*/)
    { last;
    }
    elsif ($$str =~ s/^\=\s*//)
    { $rec = $slf->define_operator(['.assign.'], $rec,
        $slf->parse_value($str));
    }
    else
    { last;
    }
  }

  # Return the value found, otherwise, undef
  $rec;
}

# --- Execution routines -----------------------------------------------------

sub _exec
{ my ($slf) = @_;
  my ($ctx, $ret, $top);

  # Execute the code block
  $ctx = $slf->{'ctx'};
  $ret = $CONT;
  eval {
    foreach my $spc (@{$slf->{'_cod'}})
    { $ctx->trace_string($spc->[$SPC_COD]) if $ctx->{'trc'};
      $slf->{'_lst'} = $spc;
      last if ($ret = &{$spc->[$SPC_FCT]}($slf, $spc));
    }
  };
  return $ret unless $@;

  # Propagate the error
  die $@ if $@ =~ $DIE;
  $slf->gen_exec_err($@);
  die $DIE_B;
}

# Append a text to a scalar variable
sub _exe_append
{ my ($slf, $spc) = @_;
  my ($txt, $var);

  $var = $spc->[$SPC_REF];
  $txt = join("\n", $var->eval_as_string, $spc->[$SPC_VAL]->eval_as_string);
  $slf->{'ctx'}->set_internal('val',
    $var->assign_value(RDA::Value::Scalar::new_text($txt), 1));

  # Indicate the successful completion
  $CONT;
}

# Interrupt a loop
sub _exe_break
{ my ($slf, $spc) = @_;
  my ($ctx, $val);

  $ctx = $slf->{'ctx'};

  # Evaluate the condition
  $val = $ctx->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
  $val = $val->as_scalar;
  $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
  $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;

  # Take the appropriate action
  return $CONT unless $val;
  $ctx->{'nam'} = $spc->[$SPC_OBJ];
  $RET_BRK;
}

# Evaluate an expression
sub _exe_calc
{ my ($slf, $spc) = @_;

  $slf->{'ctx'}->set_internal('val', $spc->[$SPC_VAL]->eval_value)
    if defined($spc->[$SPC_VAL]);

  # Indicate the successful completion
  $CONT;
}

# Define a named block
sub _exe_code
{ my ($slf, $spc) = @_;
  my ($blk);

  # Register the named block
  $blk = $spc->[$SPC_BLK];
  $blk->{'val'} = $spc->[$SPC_VAL]->eval_value
    if defined($spc->[$SPC_VAL]);
  $blk->{'ctx'} = $slf->{'ctx'}->set_code($spc->[$SPC_REF], $spc->[$SPC_BLK]);

  # Indicate the successful completion
  $CONT;
}

# Display some debugging information
sub _exe_debug
{ my ($slf, $spc) = @_;

  # Display the debug information
  $slf = $slf->get_top;
  $slf->{'dsp'}->dsp_line($spc->[$SPC_VAL]->eval_as_line)
    if $slf->{'dbg'} && !$slf->{'out'};

  # Indicate the successful completion
  $CONT;
}

# Echo some information
sub _exe_die
{ my ($slf, $spc) = @_;

  # Set the die message and start propagating the die
  $slf->get_package->{'die'} = $spc->[$SPC_VAL]->eval_as_line;
  die $tb_die{$spc->[$SPC_REF]};
}

# Dump some information
sub _exe_dump
{ my ($slf, $spc) = @_;

  # Dump the information
  $slf = $slf->get_top;
  $slf->{'dsp'}->dsp_data(join('',
    map {$_->as_dump} @{$spc->[$SPC_VAL]->eval_value})."\n")
    unless $slf->{'out'};

  # Indicate the successful completion
  $CONT;
}

# Echo some information
sub _exe_echo
{ my ($slf, $spc) = @_;

  # Echo the line
  $slf = $slf->get_top;
  $slf->{'dsp'}->dsp_line($spc->[$SPC_VAL]->eval_as_line)
    unless $slf->{'out'};

  # Indicate the successful completion
  $CONT;
}

# Do an if condition
sub _exe_else
{ my ($slf, $spc) = @_;
  my $val;

  # Get the last condition, but prevent further matches
  $slf->{'ctx'}->end_cond($spc->[$SPC_OBJ])
    ? $CONT
    : $spc->[$SPC_BLK]->_exec;
}

# Do an eval
sub _exe_eval
{ my ($slf, $spc) = @_;
  my ($prv, $ret, $top, $txt, @err);

  # Sve the previous context
  $top = $slf->get_top;
  ($top->{'err'}, $prv) = ([], $top->{'err'});

  # Execute the eval block
  $slf->{'ctx'}->set_internal('err', RDA::Value::List->new);
  eval {$ret = $spc->[$SPC_BLK]->_exec($slf)};
  if ($@)
  { die $@ if $@ =~ $DIE && $1 ne 'B';
    $ret = $ERROR;
  }

  # Catch errors and restore the previous context
  $slf->{'ctx'}->set_internal('err',
    RDA::Value::List::new_from_data(@{delete($top->{'err'})}));
  $top->{'err'} = $prv if defined($prv);

  # Indicate the completion status
  ($ret < 0) ? $CONT : $ret;
}

# Do an elsif condition
sub _exe_elsif
{ my ($slf, $spc) = @_;
  my ($ctx, $val);

  # Check the last condition
  $ctx = $slf->{'ctx'};
  return $CONT if $ctx->get_cond($spc->[$SPC_OBJ]);

  # Evaluate the condition
  $val = $ctx->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
  $val = $val->as_scalar;
  $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
  $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;
  $ctx->set_cond($spc->[$SPC_OBJ], $val);

  # When fullfilled, execute it
  $val ? $spc->[$SPC_BLK]->_exec : $CONT;
}

# Do a for
sub _exe_for
{ my ($slf, $spc) = @_;
  my ($blk, $ctx, $cur, $inc, $lim, $nam, $ret, $var);

  $ctx = $slf->{'ctx'};
  $blk = $spc->[$SPC_BLK];
  $nam = $spc->[$SPC_OBJ];
  $var = $spc->[$SPC_REF];
  ($cur, $lim, $inc) = @{$spc->[$SPC_VAL]};
  $cur = $cur->eval_as_number;
  $lim = $lim->eval_as_number;
  $inc = defined($inc) ? $inc->eval_as_number : 1;
  if ($inc >= 0)
  { for (; $cur <= $lim ; $cur += $inc)
    { # Update the loop variable
      $ctx->set_internal('val',
        $var->assign_value(RDA::Value::Scalar::new_number($cur), 1));

      # Execute the loop iteration
      $ret = $blk->_exec;
      if ($ret == $RET_NXT)
      { return $ret unless $nam eq $ctx->{'nam'};
      }
      elsif ($ret == $RET_BRK)
      { return $ret unless $nam eq $ctx->{'nam'};
        last;
      }
      elsif ($ret == $RET_RET || $ret == $ERROR)
      { return $ret;
      }

      # Prepare for the next iteration
      $ctx->trace_string($spc->[$SPC_COD].' **') if $ctx->{'trc'};
    }
  }
  else
  { for (; $cur >= $lim ; $cur += $inc)
    { # Update the loop variable
      $ctx->set_internal('val',
        $var->assign_value(RDA::Value::Scalar::new_number($cur), 1));

      # Execute the loop iteration
      $ret = $blk->_exec;
      if ($ret == $RET_NXT)
      { return $ret unless $nam eq $ctx->{'nam'};
      }
      elsif ($ret == $RET_BRK)
      { return $ret unless $nam eq $ctx->{'nam'};
        last;
      }
      elsif ($ret == $RET_RET || $ret == $ERROR)
      { return $ret;
      }

      # Prepare for the next iteration
      $ctx->trace_string($spc->[$SPC_COD].' **') if $ctx->{'trc'};
    }
  }

  # Indicate the successful completion
  $CONT;
}

# Define a global variable
sub _exe_global
{ my ($slf, $spc) = @_;
  my ($val, $var);

  # Define a global variable
  $var = $spc->[$SPC_REF];
  if (defined($val = $spc->[$SPC_VAL]))
  { $val = $slf->{'ctx'}->set_internal('val', $val->eval_value);
    $val = RDA::Value::Hash::new_from_list($val->is_list ? [@$val] : [$val])
      if $var =~m/^%/;
  }
  $slf->{'ctx'}->set_object($var, $val);

  # Indicate the successful completion
  $CONT;
}

# Do an if condition
sub _exe_if
{ my ($slf, $spc) = @_;
  my ($ctx, $val);

  # Evaluate the condition
  $ctx = $slf->{'ctx'};
  $val = $ctx->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
  $val = $val->as_scalar;
  $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
  $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;
  $ctx->set_cond($spc->[$SPC_OBJ], $val);

  # When fullfilled, execute it
  $val ? $spc->[$SPC_BLK]->_exec($slf) : $CONT;
}

# Import some variables from upper levels
sub _exe_import
{ my ($slf, $spc) = @_;

  # Import the variables
  $slf->{'ctx'}->import_variables(@{$spc->[$SPC_VAL]});

  # Indicate the successful completion
  $CONT;
}

# Execute a block in a separate process
sub _exe_job
{ my ($slf, $spc) = @_;
  my ($agt, $arg, $flg, $job, $lck, $pid, $top, %bkp);

  # Abort nested jobs
  $top = $slf->get_top;
  die "RDA-00249: Thread nesting\n" if $top->{'job'};

  # Clear previous files used for transfering thread information
  _load_job($top, $tb_clr) unless $top->{'_job'};

  # Force the creation of the event log file and close reports
  $top->{'agt'}->log_force;
  $top->{'rpt'}->close if exists($top->{'rpt'});

  # Create a separate process to execute the block
  $arg = $arg->eval_value if defined($arg = $spc->[$SPC_VAL]);
  $flg = $spc->[$SPC_REF];
  $job = _fmt_job($top->{'_job'}++);
  $agt = $top->get_agent;
  $lck = $top->get_lock;
  if (!defined($pid = _fork($top, $flg)))
  { my ($bkp, $cfg, $err, $out, $tgt);

    # Prepare the lock context
    eval {$lck->init(0)} if $lck;

    # Execute the block in main process
    $err = delete($top->{'err'});
    $bkp = $agt->backup_settings;
    $tgt = $agt->get_target->get_current;
    $out = _exec_job($slf, $spc->[$SPC_BLK], $arg, $top, $job, $flg, 0);
    $cfg = $agt->extract_settings;
    $agt->restore_settings($bkp);
    $agt->load_settings(RDA::Handle::Memory->new($cfg));
    $agt->get_target->set_current($tgt);
    $top->{'_thr'} = -1;
    if ($out)
    { $top->{'rpt'}->load(RDA::Handle::Memory->new($out));
      $top->{'rpt'}->check_free(0);
    }
    $top->{'err'} = $err if defined($err);

    # Restore the lock context
    eval {$lck->end(0)} if $lck;
  }
  elsif (!$pid)
  { my ($aux, $fil);

    # Prepare the lock context
    eval {$lck->init($flg)} if $lck;

    # Clear previous transfer files
    if ($flg)
    { $fil = RDA::Object::Rda->cat_file($agt->get_output->get_path('J', 1),
        $top->{'nam'}.'_'.$job);
      1 while unlink("$fil.cfg");
      1 while unlink("$fil.out");
      1 while unlink("$fil.use");
    }

    # Reset libraries requiring thread preparation
    $agt->backup_settings;
    $agt->reset_usage;
    $agt->set_info('aux', $aux = {
      blk => $slf,
      fil => $fil,
      job => $job,
      lck => $lck,
      top => $top});
    foreach my $lib (@{$top->get_agent->can_thread})
    { $lib->reset;
    }

    # Execute the block in a child process
    delete($top->{'err'});
    $aux->{'buf'} =
      _exec_job($slf, $spc->[$SPC_BLK], $arg, $top, $job, $flg, 1);

    # Terminate the job execution
    $flg ? _end_thread($agt) : _end_job($agt);
    die $DIE_X;
  }
  elsif ($flg)
  { $top->{'_thr'} = 1;
    push(@{$top->{'_pid'}}, $pid) if $pid < 0;
  }

  # Indicate the successful completion
  $CONT;
}

sub _end_job
{ my ($agt) = @_;
  my ($lck);

  # Remove lock files
  eval {$lck->end(1)} if ($lck = $agt->get_info('aux')->{'lck'});
}

sub _end_thread
{ my ($agt) = @_;
  my ($ctl, $fil, $ofh, $str, $tbl);

  # Initialization
  $ctl = $agt->get_info('aux');
  $fil = $ctl->{'fil'};

  # Save the setting changes
  if (($str = $agt->extract_settings)
    && ($ofh = IO::File->new)->open("$fil.cfg", $CREATE, $TMP_PERMS))
  { $ofh->syswrite($str, length($str));
    $ofh->close;
  }

  # Save the index and share definitions
  if (($str = $ctl->{'buf'})
    && ($ofh = IO::File->new)->open("$fil.out", $CREATE, $TMP_PERMS))
  { $ofh->syswrite($str, length($str));
    $ofh->close;
  }

  # Save the library usage
  if (($str = $agt->extract_usage)
    && ($ofh = IO::File->new)->open("$fil.use", $CREATE, $TMP_PERMS))
  { $ofh->syswrite($str, length($str));
    $ofh->close;
  }

  # Remove lock files
  eval {$ctl->{'lck'}->end(1)} if $ctl->{'lck'};
}

sub _exec_job
{ my ($slf, $blk, $arg, $top, $job, $flg, $frk) = @_;
  my ($bkp, $buf, $ctx, $dsc, $out);

  $buf = '';
  $ctx = $blk->{'ctx'}->push_context($slf, $slf->{'ctx'});
  $dsc = $flg ? 'thread' : 'job';
  $top->{'job'} = $job;
  if (exists($top->{'rpt'}))
  { $out = $top->{'rpt'};
    $bkp = $out->suspend($job, $frk);
    eval {$blk->_exec_block($dsc, $arg)};
    $slf->gen_exec_err($@) unless $@ =~ $DIE;
    $buf = $out->extract if $flg;
    $out->resume($bkp);
  }
  else
  { eval {$blk->_exec_block($dsc, $arg)};
    $slf->gen_exec_err($@) unless $@ =~ $DIE;
  }
  $ctx->pop_context;
  $top->{'job'} = '';

  # Return the index and share definitions.
  $buf;
}

sub _fmt_job
{ my ($val) = @_;
  my $str = '';

  do
  { $str .= chr(65 + ($val & 15));
    $val >>= 4;
  } while $val;
  $str;
}

sub _fork
{ my ($top, $typ) = @_;
  my ($flg, $pid);

  # Abort when can't fork
  return undef unless ($flg = $top->{'agt'}->can_fork);

  # Create the thread process
  return undef unless defined($pid = fork());
  unless ($pid)
  { # For a thread or when fork is emulated, a child process is sufficient
    return 0 if $typ || $flg < 0;

    # Make a double fork to have an independant child process
    exit(1) unless defined($pid = fork());
    exit(0) if $pid;
    return 0;
  }

  # Must not wait for a thread or when fork is emulated
  return $pid if $typ || $flg < 0;

  # In the parent process, wait for the grand child process fork
  waitpid($pid, 0);
  $? ? undef : 1;
}

sub _load_job
{ my ($top, $tbl) = @_;
  my ($dir, $nam, $out, $pth, $trc);

  $nam = $top->{'nam'};
  $out = $top->{'rpt'};
  $trc = $top->{'agt'}->get_setting('JOB_TRACE');
  $dir = $out->get_path('J');
  if (opendir(JOB, $dir))
  { foreach my $fil (sort readdir(JOB))
    { next unless $fil =~ m/^$nam\_[A-Z]+\.(cfg|out|use)$/i;
      $pth = RDA::Object::Rda->cat_file($dir, $fil);
      &{$tbl->{$1}}($top, $pth);
      unless ($trc)
      { 1 while unlink($pth);
      }
    }
    closedir(JOB);
  }
  $out->check_free(0);
}

sub _load_job_cfg
{ my ($slf, $pth) = @_;
  my ($ifh);

  $slf->get_agent->load_settings($ifh)
    if ($ifh = IO::File->new)->open("<$pth");
}

sub _load_job_out
{ my ($slf, $pth) = @_;
  my ($ifh);

  $slf->{'rpt'}->load($ifh)
    if ($ifh = IO::File->new)->open("<$pth");
}

sub _load_job_use
{ my ($slf, $pth) = @_;
  my ($ifh);

  $slf->get_agent->load_usage($ifh)
    if ($ifh = IO::File->new)->open("<$pth");
}

sub _skip_job
{
}

# Keep some variables
sub _exe_keep
{ my ($slf, $spc) = @_;

  # Keep all variables from the list
  $slf->{'ctx'}->keep_variables(@{$spc->[$SPC_VAL]});

  # Indicate the successful completion
  $CONT;
}

# Do a loop
sub _exe_loop
{ my ($slf, $spc) = @_;
  my ($blk, $ctx, $nam, $rec, $ret, $var);

  $ctx = $slf->{'ctx'};
  $blk = $spc->[$SPC_BLK];
  $nam = $spc->[$SPC_OBJ];
  $var = $spc->[$SPC_REF];
  $rec = $spc->[$SPC_VAL]->eval_value;
  foreach my $cur (@$rec)
  { # Update the loop variable
    $ctx->get_internal('val', $var->assign_value($cur, 1));

    # Execute the loop iteration
    $ret = $blk->_exec;
    if ($ret == $RET_NXT)
    { return $ret unless $nam eq $ctx->{'nam'};
    }
    elsif ($ret == $RET_BRK)
    { return $ret unless $nam eq $ctx->{'nam'};
      last;
    }
    elsif ($ret == $RET_RET || $ret == $ERROR)
    { return $ret;
    }

    # Prepare for the next iteration
    $ctx->trace_string($spc->[$SPC_COD].' **') if $ctx->{'trc'};
  }

  # Indicate the successful completion
  $CONT;
}

# Define a macro
sub _exe_macro
{ my ($slf, $spc) = @_;

  # Register the macro
  $slf->{'_pkg'}->{'_lib'}->{$spc->[$SPC_REF]} = $spc->[$SPC_BLK];

  # Indicate the successful completion
  $CONT;
}

# Interrupt the current loop iteration and start the next one
sub _exe_next
{ my ($slf, $spc) = @_;
  my ($ctx, $val);

  $ctx = $slf->{'ctx'};

  # Evaluate the condition
  $val = $ctx->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
  $val = $val->as_scalar;
  $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
  $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;

  # Take the appropriate action
  return $CONT unless $val;
  $ctx->{'nam'} = $spc->[$SPC_OBJ];
  $RET_NXT;
}

# Do an once loop
sub _exe_once
{ my ($slf, $spc) = @_;
  my ($blk, $ctx, $ret, $val);

  $blk = $spc->[$SPC_BLK];
  $ctx = $slf->{'ctx'};

  # Evaluate the condition
  $val = $ctx->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
  $val = $val->as_scalar;
  $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
  $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;

  # Execute the loop once
  if ($val)
  { $ret = $blk->_exec;
    if ($ret == $RET_NXT || $ret == $RET_BRK)
    { return $ret unless $spc->[$SPC_OBJ] eq $ctx->{'nam'};
    }
    elsif ($ret == $RET_RET || $ret == $ERROR)
    { return $ret;
    }
  }

  # Indicate the successful completion
  $CONT;
}

# Recover abort threads
sub _exe_recover
{ my ($slf, $spc) = @_;
  my ($top, $val);

  # Evaluate the condition
  $val = $slf->{'ctx'}->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
  $val = $val->as_scalar;
  $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
  $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;

  # When fullfilled, execute it
  $top = $slf->get_top;
  _load_job($top, $val ? $tb_rec : $tb_clr) unless $top->{'_job'};

  # Indicate the successful completion
  $CONT;
}

# Terminate the current context execution
sub _exe_return
{ my ($slf, $spc) = @_;

  $slf->{'ctx'}->set_internal('val', $spc->[$SPC_VAL]->eval_value)
    if defined($spc->[$SPC_VAL]);

  # Return to the previous context
  $RET_RET;
}

# Execute a module
sub _exe_run
{ my ($slf, $spc) = @_;
  my ($agt, $blk, $err, $nam, $pkg, $tbl, $top, @sct);

  # Load the block
  $nam = $nam->eval_as_string if ref($nam = $spc->[$SPC_REF]);
  ($nam, @sct) = split(/\-/, $nam);
  return $CONT unless defined($nam) && length($nam);
  $top = $slf->get_top;
  $agt = $top->{'agt'};
  if ($blk = $agt->get_block($nam))
  { $pkg = $slf->{'_pkg'};
    $pkg->{'_run'}->{$nam} = $blk->{'_par'}
      if exists($pkg->{'_run'}) && exists($blk->{'_par'});
    $blk->{'_run'} = {};
  }
  else
  { $blk = RDA::Block->new($nam, $top->{'dir'});
    $blk->{'glb'} = {%{$top->{'glb'}}};
    $blk->load($agt, 1);

    # Initialize the macro list
    $agt->get_macros($blk->{'_lib'});
  }

  # Execute the associated code block
  $err = $blk->exec($slf, 1, $spc->[$SPC_VAL], @sct);

  # Keep or free the block memory
  if ($blk->{'ctx'}->check_variable('$KEEP_BLOCK'))
  { delete($blk->{'_run'});
    $agt->keep_block($nam, $blk);
  }
  else
  { # Resynchronize the calling block
    $top->{'rpt'}->deprefix($blk) if exists($top->{'rpt'});

    # Delete associated code blocks
    $agt->get_inline->delete_blocks($nam);

    # Fix block chaining
    if (exists($blk->{'_run'}))
    { foreach my $nam (keys(%{$tbl = $blk->{'_run'}}))
      { $pkg->{'_par'} = $tbl->{$nam} if ($pkg = $agt->get_block($nam));
      }
    }

    # Delete the block
    $blk->delete;
  }

  # Propagate any error
  die "RDA-00241: Error encountered in the block called\n" if $err;

  # Indicate the successful completion
  $CONT;
}

# Assign a text to a scalar variable
sub _exe_set
{ my ($slf, $spc) = @_;

  $slf->{'ctx'}->set_internal('val',
    $spc->[$SPC_REF]->assign_value($spc->[$SPC_VAL]));

  # Indicate the successful completion
  $CONT;
}

# Suspend the data collection
sub _exe_sleep
{ my ($slf, $spc) = @_;
  my $val;

  $val = defined($spc->[$SPC_VAL])
    ? $slf->{'ctx'}->set_internal('val',
                                  $spc->[$SPC_VAL]->eval_value)->as_number
    : 1;
  eval "sleep($val)" if $val > 0;

  # Indicate the successful completion
  $CONT;
}

# Execute a test module
sub _exe_test
{ my ($slf, $spc) = @_;
  my ($agt, $bkp, $blk, $err, $nam, $sct, $top, $yes, @sct);

  # Validate the module name
  $nam = $nam->eval_as_string if ref($nam = $spc->[$SPC_REF]);
  ($nam, @sct) = split(/\-/, $nam);
  return $CONT unless defined($nam) && length($nam);
  die "RDA-00244: Invalid test module name '$nam'\n" unless $nam =~ $RE_TST;

  # Load the block
  $top = $slf->get_top;
  $agt = $top->{'agt'};
  $blk = RDA::Block->new($nam, $top->{'dir'});
  $blk->{'glb'} = {%{$top->{'glb'}}};
  $blk->load($agt, 1);

  # Execute the associated code block
  $bkp = $agt->backup_settings;
  $yes = $agt->set_info('yes',1);
  $agt->set_setting('TST_MAN', '');
  $agt->set_setting('TST_ARGS',
    join(':', grep {defined($_) && !ref($_)} $spc->[$SPC_VAL]->eval_as_array));
  $agt->set_current($nam);
  $err = $blk->collect($top->{'dbg'}, $agt->get_setting('TEST_TRACE'), @sct);
  $sct = $blk->get_info('sct', {});
  $agt->log('T', $nam, $blk->get_version, $err,
    join(',', grep {$sct->{$_} > 0} keys(%$sct)));
  $agt->set_info('yes',$yes);
  $agt->restore_settings($bkp);

  # Delete the block
  $blk->delete;

  # Propagate any error
  die "RDA-00241: Error encountered in the block called\n" if $err;

  # Indicate the successful completion
  $CONT;
}

# Wait that all threads execution is complete
sub _exe_wait
{ my ($slf, $spc) = @_;
  my ($lck, $lim, $pid, $top);

  # Wait for thread completion
  $top = $slf->get_top;
  if ($top->{'_thr'} > 0)
  { # Wait for thread completion within the specified limit
    $lim = (defined($spc) && defined($lim = $spc->[$SPC_VAL]))
      ? _chk_alarm($lim->eval_as_number)
      : 0;
    eval {
      # Set the alarm
      local $SIG{'__WARN__'} = sub {};
      local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;

      alarm($lim) if $lim;

      # Wait until the thread lock can be get
      eval {
        sleep(1);
        $lck->wait if ($lck = $top->get_lock);
        };
      die $@ if $@ =~ m/^$ALR\n/;

      # When fork is emulated, wait for thread completion
      waitpid($pid, 0)
        while defined($pid = shift(@{$top->{'_pid'}}));

      # Disable the alarm
      alarm(0) if $lim;
      };

    # Kill the remaining processes after a timeout
    if ($@ =~ m/^$ALR\n/)
    { unshift(@{$top->{'_pid'}}, $pid) if defined($pid);
      RDA::Object::Rda->kill_child($pid)
        while defined($pid = shift(@{$top->{'_pid'}}));
    }

    # Consolidate the thread results
    _load_job($top, $tb_job);
  }
  $top->{'_thr'} = 0;

  # Indicate the successful completion
  $CONT;
}

sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0);};
  $@ ? 0 : $lim;
}

# Do a while loop
sub _exe_while
{ my ($slf, $spc) = @_;
  my ($blk, $ctx, $nam, $ret, $val);

  $blk = $spc->[$SPC_BLK];
  $ctx = $slf->{'ctx'};
  $nam = $spc->[$SPC_OBJ];
  for (; ;)
  { # Evaluate the condition
    $val = $ctx->set_internal('val', $spc->[$SPC_VAL]->eval_value(1));
    $val = $val->as_scalar;
    $val = defined($val) if $spc->[$SPC_REF] =~ m/\?/;
    $val = !$val         if $spc->[$SPC_REF] =~ m/\!/;
    last unless $val;

    # Execute the loop iteration
    $ret = $blk->_exec;
    if ($ret == $RET_NXT)
    { return $ret unless $nam eq $ctx->{'nam'};
    }
    elsif ($ret == $RET_BRK)
    { return $ret unless $nam eq $ctx->{'nam'};
      last;
    }
    elsif ($ret == $RET_RET || $ret == $ERROR)
    { return $ret;
    }

    # Prepare for the next iteration
    $ctx->trace_string($spc->[$SPC_COD].' **') if $ctx->{'trc'};
  }

  # Indicate the successful completion
  $CONT;
}

=head1 ERROR METHODS

=head2 S<$h-E<gt>gen_exec_err($msg[,$ret])>

This method generates an error message at execution time. It adds the context
to the error message automatically. This method does not stop the data
collection process.

For reclassifying the error, it accepts a return code as an extra argument.

=cut

sub gen_exec_err
{ my ($slf, $msg, $ret) = @_;
  my ($top);

  $top = $slf->get_top;

  $msg =~ s/\.?\n$//;
  if (exists($top->{'err'}))
  { push(@{$top->{'err'}}, grep {m/\S/} split(/\n/, $msg)) if $msg;
  }
  else
  { print $msg." in ".$slf->{'_pkg'}->{'oid'}." near line ".
      $slf->{'_lst'}->[$SPC_LIN]."\n" if $msg;
  }

  defined($ret) ? $ret : $ERROR;
}

=head2 S<$h-E<gt>gen_load_err($msg)>

This method generates an error message at load time. It adds the context to the
error message automatically. Any error causes the code to be removed at load
end.

=cut

sub gen_load_err
{ my ($slf, $msg) = @_;

  $slf = $slf->{'_pkg'};
  $slf->{'_err'}++;
  $msg =~ s/\n$//;
  $msg .= " in ".$slf->{'oid'}." near line ".$slf->{'_lin'} if $slf->{'_lin'};
  print "$msg\n";
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
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
L<RDA::Extra|RDA::Extra>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Handle::Area|RDA::Handle::Area.pm>,
L<RDA::Handle::Block|RDA::Handle::Block.pm>,
L<RDA::Handle::Data|RDA::Handle::Data.pm>,
L<RDA::Handle::Deflate|RDA::Handle::Deflate.pm>,
L<RDA::Handle::Filter|RDA::Handle::Filter.pm>,
L<RDA::Handle::Memory|RDA::Handle::Memory.pm>,
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
L<RDA::Log|RDA::Log>,
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
L<RDA::Object::Htm|RDA::Object::Html.pm>,
L<RDA::Object::Home|RDA::Object::Home.pm>,
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
L<RDA::Object::Pod|RDA::Object::Pod.pm>,
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
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
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
