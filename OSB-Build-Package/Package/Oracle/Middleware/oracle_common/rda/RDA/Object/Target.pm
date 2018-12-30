# Target.pm: Class Used to Interface Collection Targets

package RDA::Object::Target;

# $Id: Target.pm,v 1.31 2012/05/22 15:55:43 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Target.pm,v 1.31 2012/05/22 15:55:43 mschenke Exp $
#
# Change History
# 20120522  MSC  Pass the initial Oracle home for Sql*Plus.

=head1 NAME

RDA::Object::Target - Class Used to Interface Collection Targets

=head1 SYNOPSIS

require RDA::Object::Target;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Target> class are used to interface
collection targets. It is a sub class of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use RDA::Object;
}

# Define the global public variables
use vars qw($VERSION @DUMP @EXPORT_OK @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.31 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  hsh => {
    'RDA::Object::Domain'   => 1,
    'RDA::Object::Home'     => 1,
    'RDA::Object::Instance' => 1,
    'RDA::Object::System'   => 1,
    'RDA::Object::Target'   => 1,
    'RDA::Object::WlHome'   => 1,
    },
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'addSymbol'   => ['${CUR.TARGET}', 'add_symbol'],
    'addTarget'   => ['$[TGT]',        'add_target'],
    'catSymbol'   => ['${CUR.TARGET}', 'cat_symbol'],
    'endTarget'   => ['$[TGT]',        'end_target'],
    'findTarget'  => ['$[TGT]',        'find_target'],
    'getBase'     => ['${CUR.TARGET}', 'get_base'],
    'getCommon'   => ['${CUR.TARGET}', 'get_common'],
    'getDomain'   => ['${CUR.TARGET}', 'get_domain'],
    'getFocus'    => ['${CUR.TARGET}', 'get_focus'],
    'getHome'     => ['${CUR.TARGET}', 'get_home'],
    'getInstance' => ['${CUR.TARGET}', 'get_instance'],
    'getMwHome'   => ['${CUR.TARGET}', 'get_mw_home'],
    'getSymbols'  => ['${CUR.TARGET}', 'get_symbols'],
    'getTarget'   => ['$[TGT]',        'get_target'],
    'getWlHome'   => ['${CUR.TARGET}', 'get_wl_home'],
    'listTargets' => ['$[TGT]',        'list_targets'],
    'setCurrent'  => ['$[TGT]',        'set_current'],
    'setFocus'    => ['${CUR.TARGET}', 'set_focus'],
    'setSymbol'   => ['${CUR.TARGET}', 'set_symbol'],
    },
  beg => \&_begin_control,
  dep => [qw(RDA::Object::Domain
             RDA::Object::Home
             RDA::Object::Instance
             RDA::Object::System
             RDA::Object::WlHome)],
  end => \&_end_control,
  flg => 1,
  glb => ['$[TGT]'],
  inc => [qw(RDA::Object)],
  met => {
    'add_symbol'     => {ret => 0},
    'add_target'     => {ret => 0},
    'cat_symbol'     => {ret => 0},
    'end_target'     => {ret => 0},
    'find_command'   => {ret => 0},
    'find_target'    => {ret => 0},
    'get_base'       => {ret => 0},
    'get_common'     => {ret => 0},
    'get_current'    => {ret => 0},
    'get_default'    => {ret => 0},
    'get_definition' => {ret => 0},
    'get_detail'     => {ret => 0},
    'get_domain'     => {ret => 0},
    'get_env'        => {ret => 0},
    'get_focus'      => {ret => 1},
    'get_home'       => {ret => 0},
    'get_info'       => {ret => 0},
    'get_init'       => {ret => 0},
    'get_instance'   => {ret => 0},
    'get_mw_home'    => {ret => 0},
    'get_sqlplus'    => {ret => 1},
    'get_symbols'    => {ret => 1},
    'get_target'     => {ret => 0},
    'get_top'        => {ret => 0},
    'get_type'       => {ret => 0},
    'get_wl_home'    => {ret => 0},
    'list_targets'   => {ret => 1},
    'set_current'    => {ret => 0},
    'set_focus'      => {ret => 0},
    'set_info'       => {ret => 0},
    'set_symbol'     => {ret => 0},
    },
  );

# Define the global private variables
my $RE_OID = qr/^([A-Z]+)(_[A-Z]\w*(\$\$)?)?$/;

# Define the global private variables
my %tb_cln = map {$_ => 1} qw(oid par);
my %tb_cls = (
  CH  => 'RDA::Object::Home',
  DOM => 'RDA::Object::Domain',
  OH  => 'RDA::Object::Home',
  OI  => 'RDA::Object::Instance',
  MH  => 'RDA::Object::System',
  SYS => 'RDA::Object::System',
  WH  => 'RDA::Object::WlHome',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Target-E<gt>new($agt)>

The object constructor. This method takes the agent reference as an argument.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'agt' > > Reference to the agent object (C,T)

=item S<    B<'bas' > > Oracle base directory (T)

=item S<    B<'cfg' > > Reference to the RDA software configuration (T)

=item S<    B<'dom' > > Domain home directory (T)

=item S<    B<'hom' > > Oracle home directory (T)

=item S<    B<'ins' > > Instance home directory (T)

=item S<    B<'jdk' > > JDK directory (T)

=item S<    B<'mwh' > > Middleware home directory (T)

=item S<    B<'oid' > > Object identifier (C,T)

=item S<    B<'par' > > Reference to the parent target (T)

=item S<    B<'tns' > > TNS_ADMIN specification (T)

=item S<    B<'wlh' > > Oracle WebLogic Server home directory (T)

=item S<    B<'_abr'> > Symbol definition hash (T)

=item S<    B<'_bkp'> > Backup of environment variables (T)

=item S<    B<'_cch'> > Reference to the Common Components home target (T)

=item S<    B<'_chl'> > List of the child keys (C,T)

=item S<    B<'_cur'> > Reference to the current target (C)

=item S<    B<'_def'> > Target definition (C,T)

=item S<    B<'_det'> > Detected home directories (T)

=item S<    B<'_dft'> > Reference to the default target (C)

=item S<    B<'_dom'> > Domain attribute hash (T)

=item S<    B<'_env'> > Environment specifications (T)

=item S<    B<'_fcs'> > Focus hash (T)

=item S<    B<'_ini'> > Initial environment (C)

=item S<    B<'_inv'> > Inventory object (T)

=item S<    B<'_prd'> > OCM product list (T)

=item S<    B<'_prs'> > Symbol detection parse tree (T)

=item S<    B<'_seq'> > Object identifier sequencers (C)

=item S<    B<'_shr'> > Share indicator (T)

=item S<    B<'_sql'> > SQL*Plus specifications (C,T)

=item S<    B<'_srv'> > Server hash (T)

=item S<    B<'_prs'> > Symbol detection parse tree (T)

=item S<    B<'_tgt'> > Sub target hash (C)

=item S<    B<'_typ'> > Target type (C,T)

=item S<    B<'_wlh'> > Reference to the Oracle WebLogic Server home target (T)

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($ini, $lib);

  # Save some environment variables
  $ini = {};
  $ini->{'ORACLE_HOME'} = $ENV{'ORACLE_HOME'}
    if exists($ENV{'ORACLE_HOME'});
  $ini->{'PATH'} = $ENV{'PATH'}
    if exists($ENV{'PATH'});
  $ini->{'TNS_ADMIN'} = $ENV{'TNS_ADMIN'}
    if exists($ENV{'TNS_ADMIN'});
  $ini->{$lib} = $ENV{$lib}
    if defined($lib = RDA::Object::Rda->get_shlib) && exists($ENV{$lib});

  # Create the target control object and return its reference
  init(bless {
    agt  => $agt,
    oid  => 'TGT',
    _chl => [],
    _def => {},
    _ini => $ini,
    _seq => {map {$_ => 0} keys(%tb_cls)},
    _tgt => {},
    _typ => 'TGT',
    }, ref($cls) || $cls);
}

=head2 S<$h-E<gt>end>

This method deletes the target control object.

=cut

sub end
{ my ($slf) = @_;

  # Stop all target activities when deleting the target control object
  if (exists($slf->{'_dft'}))
  { _restore_env(delete($slf->{'_cur'})) if exists($slf->{'_cur'});
    _restore_env(delete($slf->{'_dft'})) if exists($slf->{'_dft'});
    $slf->end_target;
  }

  # Delete the object
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>init>

This method initializes the default target.

=cut

sub init
{ my ($slf) = @_;
  my ($agt, $cmd, $dft, $env, $ini, $lib, $val);

  $slf = $slf->get_top;
  $agt = $slf->{'agt'};

  # Delete all targets
  _restore_env(delete($slf->{'_cur'})) if exists($slf->{'_cur'});
  _restore_env(delete($slf->{'_dft'})) if exists($slf->{'_dft'});
  $slf->end_target;

  # Create the default target
  _set_env($slf->{'_dft'} = $dft =
    length($val = $agt->get_setting('ORACLE_HOME', ''))
    ? $slf->add_target('OH_default',  {ORACLE_HOME => $val}, $slf)
    : $slf->add_target('SYS',         {},                    $slf));

  # Determine how to execute SQL*Plus
  $ini = $slf->{'_ini'};
  $lib = RDA::Object::Rda->get_shlib;
  $val = RDA::Object::Rda->is_vms ? 'PIPE SQLPLUS' : 'sqlplus'
    unless defined($val = $agt->get_setting('SQL_COMMAND'));
  $slf->{'_sql'} = {cmd => $val, env => $env = {}};
  if (defined($val = $agt->get_setting('SQL_HOME')))
  { $slf->{'_sql'} = {cmd => $agt->get_setting('SQL_COMMAND'),
                      env => $env = {}};
    if (RDA::Object::Rda->is_unix)
    { $env->{'ORACLE_HOME'} = $val;
      $env->{'PATH'} = join(':', RDA::Object::Rda->cat_dir($val, 'bin'),
                                 $ini->{'PATH'});
      $env->{$lib} = exists($ini->{$lib})
        ? join(':', RDA::Object::Rda->cat_dir($val, 'lib'), $ini->{$lib})
        : RDA::Object::Rda->cat_dir($val, 'lib')
        if defined($lib);
    }
    elsif (RDA::Object::Rda->is_windows)
    { $env->{'ORACLE_HOME'} = $val = RDA::Object::Rda->native($val);
      $env->{'PATH'} = join(';', RDA::Object::Rda->cat_dir($val, 'bin'),
                                 $ini->{'PATH'});
    }
    elsif (RDA::Object::Rda->is_cygwin)
    { $env->{'ORACLE_HOME'} = RDA::Object::Rda->native($val);
      $env->{'PATH'} = join(':', RDA::Object::Rda->cat_dir($val, 'bin'),
                                 $ini->{'PATH'});
    }
  }
  elsif (RDA::Object::Rda->is_vms)
  { $slf->{'_sql'} = {cmd => 'PIPE SQLPLUS', env => $env = {}};
  }
  else
  { # Assume that SQL*Plus could be available in calling context
    $slf->{'_sql'} = {cmd => $agt->get_setting('SQL_COMMAND','sqlplus'),
                      env => $env = {}};
    $env->{'ORACLE_HOME'} = $ini->{'ORACLE_HOME'}
      if exists($ini->{'ORACLE_HOME'});
    $env->{'PATH'}        = $ini->{'PATH'};
    $env->{$lib}          = $ini->{$lib}
      if defined($lib) && exists($ini->{$lib});

    # Adjust when SQL*Plus can be derived from settings
    if (exists($dft->{'hom'}))
    { $val = $dft->{'hom'};
      if ((RDA::Object::Rda->is_unix &&
            -f ($cmd = RDA::Object::Rda->cat_file($val, 'bin', 'sqlplus')))
      || (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin) &&
          (-f ($cmd = RDA::Object::Rda->cat_file($val, 'bin', 'PLUS80.exe')) ||
           -f ($cmd = RDA::Object::Rda->cat_file($val, 'bin', 'sqlplus.exe'))))
      { $slf->{'_sql'}->{'cmd'} = $cmd;
        $env->{'INITIAL_HOME'} = $dft->{'_env'}->{'INITIAL_HOME'}
          if exists($dft->{'_env'}->{'INITIAL_HOME'});
        $env->{'ORACLE_HOME'}  = $dft->{'_env'}->{'ORACLE_HOME'};
        $env->{'PATH'}         = $dft->{'_env'}->{'PATH'};
        $env->{$lib}           = $dft->{'_env'}->{$lib}
          if defined($lib);
      }
    }
  }

  # Create the default target
  _set_env($slf->{'_dft'} = 
    length($val = $agt->get_setting('ORACLE_HOME', ''))
    ? $slf->add_target('OH_default',  {ORACLE_HOME => $val}, $slf)
    : $slf->add_target('SYS',         {},                    $slf));

  # Return the object reference
  $slf;
}

=head1 TARGET MANAGEMENT METHODS

=head2 S<$h-E<gt>add_target($oid,$def[,key=E<gt>value...])>

This method creates a sub target using the specified definition and
extra attributes. The definition is either a hash reference or a target
reference.

When the target identifier starts with C<$$>, this method replaces that string
by a type-specific sequence number.

=cut

sub add_target
{ my ($slf, $oid, $def, @arg) = @_;
  my ($cls, $flg, $seq, $tgt);

  # Validate the object identifier
  die "RDA-01350: Missing target name\n" unless defined($oid);
  $tgt = uc($oid);
  die "RDA-01351: Invalid object name '$oid'\n"
    unless $tgt =~ $RE_OID && exists($tb_cls{$1});
  $cls = $tb_cls{$1};
  $flg = $3;

  # Clone attributes when a target is provided as definition
  if (ref($def) =~ m/^RDA::Object::/ && $def->isa('RDA::Object::Target'))
  { foreach my $key (keys(%$def))
    { unshift(@arg, $key, $def->{$key})
        unless $key !~ /^[A-Za-z]\w*$/ || exists($tb_cln{$key});
    }
    $def = $def->get_definition;
  }
  die "RDA-01352: Missing target definition\n" unless ref($def) eq 'HASH';

  # Stop a previous target with the same name before adding the sub target
  $slf = $slf->get_top;
  $slf->end_target($tgt) unless $flg;

  # Create the sub target object
  eval "require $cls";
  die "RDA-01353: Invalid target class '$cls' for '$oid':\n $@\n" if $@;
  $tgt = $cls->new($oid, $slf->{'agt'}, $def, $slf, @arg);
  $slf->{'_tgt'}->{$tgt->{'oid'}} = $tgt;
}

=head2 S<$h-E<gt>end_target([$target...])>

This method ends the corresponding targets. You can specify a target by its
object reference or its object identifier. When no targets are specified, it
ends all sub targets.

It returns the number of deleted targets.

=cut

sub end_target
{ my ($slf, @arg) = @_;
  my ($cnt, $dft, $oid);

  # Initialization
  $cnt = 0;
  $slf = $slf->get_top;
  $dft = exists($slf->{'_dft'}) ? $slf->{'_dft'} : $slf;

  # End targets
  if (@arg)
  { foreach my $arg (@arg)
    { $oid = ref($arg) ? $arg->get_oid : uc($arg);
      $cnt += _end_target($slf, delete($slf->{'_tgt'}->{$oid}))
        if exists($slf->{'_tgt'}->{$oid}) && $slf->{'_tgt'}->{$oid} != $dft;
    }
  }
  else
  { foreach my $oid (keys(%{$slf->{'_tgt'}}))
    { $cnt += _end_target($slf, delete($slf->{'_tgt'}->{$oid}))
        if exists($slf->{'_tgt'}->{$oid}) && $slf->{'_tgt'}->{$oid} != $dft;
    }
  }

  # Indicate the number of delete targets
  $cnt;
}

sub _end_target
{ my ($slf, $tgt) = @_;
  my ($cnt, $obj);

  # End all targets referencing it
  $cnt = 1;
  foreach my $oid (keys(%{$slf->{'_tgt'}}))
  { $obj = $slf->{'_tgt'}->{$oid};
    $cnt += _end_target($slf, delete($slf->{'_tgt'}->{$oid}))
      if grep {$obj->{$_} == $tgt} @{$obj->{'_chl'}};
  }

  # Restore the default target
  if (exists($tgt->{'_bkp'}))
  { _restore_env($tgt);
    delete($slf->{'_cur'});
  }

  # Delete the target
  $tgt->delete;

  # Indicate the number of delete targets
  $cnt;
}

=head2 S<$h-E<gt>find_target($type,$attr,$value)>

This method returns the first target of the specified type where the specified
attribute has the specified value.

=cut

sub find_target
{ my ($slf, $typ, $key, $val) = @_;

  foreach my $tgt (values(%{$slf->get_top('_tgt')}))
  { return $tgt if $tgt->{'_typ'} eq $typ && $tgt->{'_shr'}
      && exists($tgt->{$key}) && $tgt->{$key} eq $val;
  }
  undef;
}

=head2 S<$h-E<gt>get_current>

This method returns a reference to the current target.

=cut

sub get_current
{ my ($slf) = @_;

  $slf = $slf->get_top;
  exists($slf->{'_cur'}) ? $slf->{'_cur'} : $slf->{'_dft'};
}

=head2 S<$h-E<gt>get_init($key[,$default])>

This method returns the initial value of a saved environment variables or the
default value when the environment variable was not defined.

=cut

sub get_init
{ my ($slf, $key, $dft) = @_;

  $slf = $slf->get_top;
  exists($slf->{'_ini'}->{$key}) ? $slf->{'_ini'}->{$key} : $dft;
}

=head2 S<$h-E<gt>get_default>

This method returns a reference to the default target.

=cut

sub get_default
{ shift->get_top('_dft');
}

=head2 S<$h-E<gt>get_sqlplus>

This method returns a list containing the command and the associated
environment specifications.

=cut

sub get_sqlplus
{ my $sql = shift->get_top('_sql');

  ($sql->{'cmd'}, $sql->{'env'});
}

=head2 S<$h-E<gt>get_target($oid[,$default])>

This method returns the specified target if it exists. Otherwise, it returns
the default value.

=cut

sub get_target
{ my ($slf, $oid, $dft) = @_;
  my ($tgt);

  # Validate the arguments
  die "RDA-01350: Missing target name\n"        unless defined($oid);
  die "RDA-01351: Invalid object name '$oid'\n" unless $oid =~ m/^[A-Z]\w*$/i;
  $tgt = uc($oid);

  # Find the target
  $slf = $slf->get_top;
  ($tgt eq $slf->{'oid'})        ? $slf :
  exists($slf->{'_tgt'}->{$tgt}) ? $slf->{'_tgt'}->{$tgt} :
                                   $dft;
}

=head2 S<$h-E<gt>get_unique($oid)>

This method replaces the C<$$> string in the object identifier by a
type-specific sequence number. It takes care that the resulting identifer is
not currently used.

=cut

sub get_unique
{ my ($slf, $oid) = @_;
  my ($pat, $seq, $typ, $uid);

  # Detect a variable name
  $pat = uc($oid);
  die "RDA-01351: Invalid object name '$pat'\n"
    unless $pat =~ $RE_OID && exists($tb_cls{$typ = $1});
  return $pat unless $3;

  # Make it unique
  $slf = $slf->get_top;
  do
  { $uid = $pat;
    $seq = ++$slf->{'_seq'}->{$typ};
    $uid =~ s/\$\$/$seq/;
  } while exists($slf->{'_tgt'}->{$uid});
  $uid;
}

=head2 S<$h-E<gt>list_targets([$type])>

This method returns the list of sub targets. You can restrict the list to the
targets corresponding to a specified type.

=cut

sub list_targets
{ my ($slf, $typ) = @_;
  my ($tbl);

  $slf = $slf->get_top;
  $tbl = $slf->{'_tgt'};
  return sort keys(%$tbl) unless defined($typ);
  sort grep {$tbl->{$_}->{'_typ'} eq $typ} keys(%$tbl);
}

=head2 S<$h-E<gt>set_current([$tgt])>

This method assigns the specified target as the current target. By default, it
restores the default target as current target. It returns the previous target.

=cut

sub set_current
{ my ($slf, $tgt) = @_;
  my ($bkp, $old, $val);

  $slf = $slf->get_top;

  # Restore the environment
  if (exists($slf->{'_cur'}))
  { return $tgt if ref($tgt) && $tgt == $slf->{'_cur'};
    _restore_env($old = delete($slf->{'_cur'}));
  }
  else
  { $old = $slf->{'_dft'};
  }

  # Adapt the environment
  _set_env($slf->{'_cur'} = $tgt) if ref($tgt) && $tgt != $slf->{'_dft'};

  # Return the reference of the previous target
  $old;
}

# Restore the environment
sub _restore_env
{ my ($slf) = @_;
  my ($bkp, $val);

  if ($bkp = delete($slf->{'_bkp'}))
  { foreach my $key (keys(%$bkp))
    { if (defined($val = $bkp->{$key}))
      { $ENV{$key} = $val;
      }
      else
      { delete($ENV{$key});
      }
    }
  }
}

# Adapt the environment for the current target
sub _set_env
{ my ($slf) = @_;
  my ($bkp, $env, $val);

  $bkp = $slf->{'_bkp'} = {};
  $env = $slf->get_env;
  foreach my $key (keys(%$env))
  { if (defined($val = $env->{$key}))
    { $bkp->{$key} = $ENV{$key};
      $ENV{$key} = $val;
    }
    elsif (exists($ENV{$key}))
    { $bkp->{$key} = delete($ENV{$key});
    }
  }
}

=head1 COMMON TARGET METHODS

=head2 S<$h-E<gt>find_command($command[,$flag])>

This method explores the path to find where a command is located. When found,
it returns the full path name. Otherwise, it returns an undefined variable. It
only considers files or symbolic links in its search. If the flag is set, the
file path is quoted as required by a command shell.

=cut

sub find_command
{ my ($slf, @arg) = @_;
  my ($env);

  $env = $slf->get_env;
  exists($env->{'PATH'})
    ? RDA::Object::Rda->find_path($env->{'PATH'}, @arg)
    : RDA::Object::Rda->find(@arg);
}

=head2 S<$h-E<gt>get_definition>

This method returns a reference to the target definition hash.

=cut

sub get_definition
{ shift->{'_def'};
}

=head2 S<$h-E<gt>get_detail($ref[,$key[,$default]])>

This method returns the first target from the target tree where the referenced
attribute is defined. When an attribute name is also specified as argument, it
returns its value. When the attribute is not found, it returns the default
value.

You can specify a C<.> to get the value of the reference attribute.

=cut

sub get_detail
{ my ($slf, $ref, $key, $dft) = @_;
  my ($tgt);

  if (ref($tgt = _get_detail($slf, $ref)))
  { return $tgt unless defined($key);
    $key = $ref if $key eq '.';
    return $tgt->{$key} if exists($tgt->{$key});
  }
  $dft;
}

sub _get_detail
{ my ($slf, $ref) = @_;
  my ($tgt);

  return $slf if exists($slf->{$ref});
  foreach my $key (@{$slf->{'_chl'}})
  { return $tgt if ref($tgt = _get_detail($slf->{$key}, $ref));
  }
  undef;
}

=head2 S<$h-E<gt>get_env>

This method returns the environment variable specifications as a hash
reference.

=cut

sub get_env
{ my ($slf) = @_;

  (ref($slf->{'_env'}) eq 'HASH')
    ? $slf->{'_env'}
    : {};
}

=head2 S<$h-E<gt>get_focus([$name[,$list]])>

This method returns the list of all identifiers associated to the specified
focus area name. By default, it returns all identifiers.

=cut

sub get_focus
{ my ($slf, $nam, $src) = @_;
  my ($fcs, $tbl, @dst, @src);

  if (exists($slf->{'_fcs'}))
  { $tbl = $slf->{'_fcs'};

    # Determine the candidates
    if (ref($src) eq 'ARRAY')
    { foreach my $uid (@$src)
      { push(@src, $uid) if exists($tbl->{$uid});
      }
    }
    else
    { @src = keys(%$tbl);
    }

    # Select the identifiers
    return @src unless defined($nam);
    foreach my $uid (@src)
    { if (ref($fcs = $tbl->{$uid}))
      { push(@dst, $uid) if exists($fcs->{$nam});
      }
      else
      { push(@dst, $uid);
      }
    }
  }
  @dst;
}

=head2 S<$h-E<gt>get_type>

This method returns the target type.

=cut

sub get_type
{ shift->{'_typ'};
}

=head2 S<$h-E<gt>set_focus($name[,$list])>

When the target supports focus, this method associates a comma-separated list
of focus area names to the specified identifier. It discards focus area names
that contain characters other than alphanumeric characters or underscores
(_). When the list is undefined, the C<get_focus> method will select the
identifier for any focus area.

It returns the number of focus area names associated to the identifier.

=cut

sub set_focus
{ my ($slf, $uid, $str) = @_;
  my ($agt, $cnt, $tbl, @tbl);

  # Validate the argument
  die "RDA-01354: Missing or invalid identifier\n"
    unless defined($uid) && $uid =~ m/^\w+$/;
  die "RDA-01355: Focus not supported for the '".$slf->{'oid'}."' target\n"
    unless exists($slf->{'_fcs'});

  # Associate focus areas to the identifier
  return $slf->{'_fcs'}->{$uid} = undef unless defined($str);

  $agt = $slf->{'agt'};
  $cnt = 0;
  $slf->{'_fcs'}->{$uid} = $tbl = {};
  foreach my $nam (split(/,/, $str))
  { $tbl->{$3} = ++$cnt
      if $nam =~ m/^((\w+)\?)?(\w+)$/ && (!$1 || $agt->get_setting($2));
  }
  $cnt;
}

=head1 SYMBOL MANAGEMENT METHODS

The symbol management is disabled for VMS.

=head2 S<$h-E<gt>add_symbol($dir)>

This method detects when a base directory matches a defined symbol. It returns
the resulting directory string.

=cut

sub add_symbol
{ my ($slf, $dir) = @_;
  my ($abr, $flg, $hsh, $str, $sub, $tbl, @dir, @prv);

  # Check symbol availability
  return $dir
    unless exists($slf->{'_prs'}) && defined($dir) && length($dir);

  # Detect when a symbol is applicable
  $flg = RDA::Object::Rda->is_unix;
  $tbl = $slf->{'_prs'};
  @dir = RDA::Object::Rda->split_dir(RDA::Object::Rda->cat_dir($dir));
  while (defined($sub = shift(@dir)))
  { $hsh = $tbl->[0];
    $str = $flg ? $sub : lc($sub);
    ($abr, @prv) = ($tbl->[1]) if defined($tbl->[1]);
    return $abr
      ? RDA::Object::Rda->cat_dir($abr, @prv, $sub, @dir)
      : $dir
      unless exists($hsh->{$str});
    push(@prv, $sub) if $abr;
    $tbl = $hsh->{$str};
  }
  defined($tbl->[1]) ? $tbl->[1] :
  $abr               ? RDA::Object::Rda->cat_dir($abr, @prv) :
                       $dir;
}

=head2 S<$h-E<gt>cat_symbol($file)>

This method detects when a base directory matches a defined symbol. It returns
the resulting path string.

=cut

sub cat_symbol
{ my ($slf, $pth) = @_;
  my ($dir, $fil);

  ($fil, $dir) = fileparse(RDA::Object::Rda->cat_file($pth));
  RDA::Object::Rda->cat_file($slf->add_symbol($dir), $fil)
}

=head2 S<$h-E<gt>get_symbols([$hash])>

This method returns a hash containing the symbol definitions applicable to the
target.

=cut

sub get_symbols
{ my ($slf, $def) = @_;

  $def = {} unless ref($def) eq 'HASH';
  _get_symbols($slf, $def);
  (%$def);
}

sub _get_symbols
{ my ($slf, $def) = @_;

  foreach my $key (@{$slf->{'_chl'}})
  { _get_symbols($slf->{$key}, $def);
  }
  if (exists($slf->{'_abr'}))
  { foreach my $key (keys(%{$slf->{'_abr'}}))
    { $def->{$key} = $slf->{'_abr'}->{$key};
    }
  }
}

=head2 S<$h-E<gt>set_symbol($abbr[,$dir])>

This method manages the symbol definitions. It deletes the symbol when a
directory is not specified. It returns the previous definition.

=cut

sub set_symbol
{ my ($slf, $abr, $dir) = @_;
  my ($flg, $hsh, $old, $str, $tbl, @abr, @dir, %def);

  if (exists($slf->{'_abr'}) && defined($abr) && length($abr))
  { # Get the previous directory
    $old = RDA::Object::Rda->cat_dir(@{delete($slf->{'_abr'}->{$abr})})
      if exists($slf->{'_abr'}->{$abr});

    # Define the symbol
    $slf->{'_abr'}->{$abr} =
      [RDA::Object::Rda->split_dir(RDA::Object::Rda->cat_dir($dir))]
      if defined($dir) && length($dir);

    # Update the parse tree
    _get_symbols($slf, \%def);
    if (@abr = keys(%def))
    { $slf->{'_prs'} = [{}];
      $flg = RDA::Object::Rda->is_unix;
      foreach my $key (sort @abr)
      { $tbl = $slf->{'_prs'};
        @dir = @{$def{$key}};
        while (defined($str = shift(@dir)))
        { $hsh = $tbl->[0];
          $str = lc($str) unless $flg;
          $hsh->{$str} = [{}] unless exists($hsh->{$str});
          $tbl = $hsh->{$str};
        }
        $tbl->[1] = $key;
      }
    }
    else
    { delete($slf->{'_prs'});
    }
  }
  $old;
}

=head1 DOMAIN, ORACLE HOME AND INSTANCE METHODS

=head2 S<$h-E<gt>get_base([$key[,$default]])>

This method returns the associated Oracle instance target object. When an
attribute name is specified, it returns its value. When the attribute is not
found, it returns the default value.

You can specify a C<.> to get the base directory.

=cut

sub get_base
{ my $slf = shift;

  $slf->get_detail('bas', @_);
}

=head2 S<$h-E<gt>get_common([$key[,$default]])>

This method returns the associated Common Components home target object. When
an attribute name is specified, it returns its value. When the attribute is not
found, it returns the default value.

You can specify a C<.> to get the Common Components home directory.

=cut

sub get_common
{ my $slf = shift;

  $slf->get_detail('cch', @_);
}

=head2 S<$h-E<gt>get_domain([$key[,$default]])>

This method returns the associated Oracle WebLogic Server domain target
object. When an attribute name is specified, it returns its value. When the
attribute is not found, it returns the default value.

You can specify a C<.> to get the domain home directory.

=cut

sub get_domain
{ my $slf = shift;

  $slf->get_detail('dom', @_);
}

=head2 S<$h-E<gt>get_home([$key[,$default]])>

This method returns the associated Oracle home target object. When an attribute
name is specified, it returns its value. When the attribute is not found, it
returns the default value.

You can specify a C<.> to get the Oracle home directory.

=cut

sub get_home
{ my $slf = shift;

  $slf->get_detail('hom', @_);
}

=head2 S<$h-E<gt>get_instance([$key[,$default]])>

This method returns the associated Oracle instance target object. When an
attribute name is specified, it returns its value. When the attribute is not
found, it returns the default value.

You can specify a C<.> to get the instance home directory.

=cut

sub get_instance
{ my $slf = shift;

  $slf->get_detail('ins', @_);
}

=head2 S<$h-E<gt>get_mw_home([$key[,$default]])>

This method returns the associated Oracle Middleware home target object. When
an attribute name is specified, it returns its value. When the attribute is not 
found, it returns the default value.

You can specify a C<.> to get the Oracle Middleware home directory.

=cut

sub get_mw_home
{ my $slf = shift;

  $slf->get_detail('mwh', @_);
}

=head2 S<$h-E<gt>get_wl_home([$key[,$default]])>

This method returns the associated Oracle WebLogic Server home target
object. When an attribute name is specified, it returns its value. When the
attribute is not found, it returns the default value.

You can specify a C<.> to get the Oracle WebLogic Server home directory.

=cut

sub get_wl_home
{ my $slf = shift;

  $slf->get_detail('wlh', @_);
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the module target
sub _begin_control
{ my ($pkg, $tgt) = @_;

  $tgt = $pkg->get_agent->get_target;
  $pkg->set_info('tgt', $tgt->get_default);
  $pkg->define('$[TGT]', $tgt);
}

# Close all package targets
sub _end_control
{ my ($pkg) = @_;

  $pkg->get_agent->get_target->end_target;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Domain|RDA::Object::Domain>,
L<RDA::Object::Home|RDA::Object::Home>,
L<RDA::Object::Instance|RDA::Object::Instance>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::System|RDA::Object::System>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
