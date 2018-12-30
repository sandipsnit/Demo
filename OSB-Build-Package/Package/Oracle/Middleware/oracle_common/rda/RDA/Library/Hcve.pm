# Hcve.pm: Class Used for HCVE Rule Sets

package RDA::Library::Hcve;

# $Id: Hcve.pm,v 2.11 2012/05/03 21:07:07 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Hcve.pm,v 2.11 2012/05/03 21:07:07 mschenke Exp $
#
# Change History
# 20120503  MSC  Share the local output control.

=head1 NAME

RDA::Library::Hcve - Class Used for HCVE Rule Sets

=head1 SYNOPSIS

require RDA::Library::Hcve;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Hcve> class are used to manage HCVE rule
sets.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Block;
  use RDA::Handle::Memory;
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $PREFIX = 'TRACE/HCVE/';

my %tb_fam = (
  'aix'        => 'Unix',
  'bsdos'      => 'Unix',
  'cygwin'     => 'Cygwin',
  'darwin'     => 'Unix',
  'dec_osf'    => 'Unix',
  'dgux'       => 'Unix',
  'dynixptx'   => 'Unix',
  'freebsd'    => 'Unix',
  'hpux'       => 'Unix',
  'irix'       => 'Unix',
  'linux'      => 'Unix',
  'MacOs'      => 'Mac',
  'MSWin32'    => 'Windows',
  'MSWin64'    => 'Windows',
  'next'       => 'Unix',
  'openbsd'    => 'Unix',
  'svr4'       => 'Unix',
  'sco_sv'     => 'Unix',
  'solaris'    => 'Unix',
  'sunos'      => 'Unix',
  'VMS'        => 'Vms',
  'Windows_NT' => 'Windows',
  );
my %tb_fct = (
  'addHcveParameter' => [\&_m_add_parameter,  'N'],
  'addHcveVariable'  => [\&_m_add_variable,   'N'],
  'evalHcveCommand'  => [\&_m_eval_command,   'L'],
  'getHcveFact'      => [\&_m_get_fact,       'V'],
  'getHcveFamily'    => [\&_m_get_family,     'T'],
  'getHcveFile'      => [\&_m_get_file,       'T'],
  'getHcveName'      => [\&_m_get_name,       'T'],
  'getHcveParameter' => [\&_m_get_parameter,  'V'],
  'getHcvePlatform'  => [\&_m_get_platform,   'T'],
  'getHcveProduct'   => [\&_m_get_product,    'T'],
  'getHcveResult'    => [\&_m_get_result,     'T'],
  'getHcveSets'      => [\&_m_get_sets,       'L'],
  'getHcveType'      => [\&_m_get_type,       'T'],
  'getHcveValues'    => [\&_m_get_values,     'T'],
  'setHcveContext'   => [\&_m_set_context,    'N'],
  'setHcveFact'      => [\&_m_set_fact,       'N'],
  'setHcveParameter' => [\&_m_set_parameter,  'V'],
  'setHcveResult'    => [\&_m_set_result,     'T'],
  'setHcveRule'      => [\&_m_set_rule,       'T'],
  'setHcveVariable'  => [\&_m_set_variable,   'N'],
  );
my %tb_inf = (
  family   => 5,
  platform => 4,
  product  => 3,
  title    => 2,
  type     => 1,
  );
my %tb_osn = (
  'sunos'      => 'solaris',
  'MSWin64'    => 'MSWin32',
  'Windows_NT' => 'MSWin32',
  );
my %tb_stl = (
  '*' => '**',
  "'" => "''",
  '`' => '``',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Hcve-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Hcve> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_ctx'> > Action evaluation context

=item S<    B<'_col'> > Fact collector hash

=item S<    B<'_dir'> > HCVE directory

=item S<    B<'_flg'> > HCVE rule set load indicator

=item S<    B<'_map'> > Parameter to collector mapping

=item S<    B<'_mod'> > Module directory

=item S<    B<'_res'> > HCVE rule result hash

=item S<    B<'_rul'> > HCVE rule identifier

=item S<    B<'_set'> > HCVE rule set hash

=item S<    B<'_trc'> > Trace level

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($cfg, $slf);

  # Create the macro object
  $cfg = $agt->get_config;
  $slf = bless {
    _agt => $agt,
    _col => {},
    _dir => $cfg->get_group('D_RDA_HCVE'),
    _flg => 0,
    _map => {},
    _mod => $cfg->get_group('D_RDA_CODE'),
    _res => {},
    _rul => 0,
    _set => {},
    _trc => $agt->get_setting('HCVE_TRACE', 0),
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

  # Treat functions without value conversion
  return &{$fct->[0]}($slf, $ctx, $arg->eval_as_array)
    if $typ eq 'V';

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 HCVE MACROS

=head2 S<addHcveParameter($nam,$val)>

This macro adds a result to the specified parameter. When needed, it converts
the current value to a list.

=cut

sub _m_add_parameter
{ my ($slf, $ctx, $nam, $val) = @_;
  my ($key, $ptr, @tbl);

  @tbl = split(/\./, uc($nam));
  if (defined($key = pop(@tbl)))
  { $ptr = $slf->{'_res'};
    foreach my $itm (@tbl)
    { $ptr->{$itm} = {} unless ref($ptr->{$itm}) eq 'HASH';
      $ptr = $ptr->{$itm};
    }
    if (exists($ptr->{$key}))
    { $ptr->{$key} = [$ptr->{$key}] unless ref($ptr->{$key}) eq 'ARRAY';
      push(@{$ptr->{$key}}, $val);
    }
    else
    { $ptr->{$key} = [$val];
    }
  }
  $val;
}

=head2 S<addHcveVariable($nam,$val)>

This macro defines a scalar variable in the action evaluation context and
assigns the specified variable to it. It returns the number of variables that
have been effectively created.

=cut

sub _m_add_variable
{ my ($slf, $ctx, $nam, $val) = @_;

  # Validate the request
  return 0 unless exists($slf->{'_ctx'}) && $nam =~ m/^\$\w+$/;

  # Create the variable
  $slf->{'_ctx'}->get_context->set_value($nam,
    RDA::Value::Scalar::new_from_data($val));

  # Indicate the number of variables that have been created
  1;
}

=head2 S<evalHcveCommand($typ,$cod)>

This macro evaluates a command block. It returns a list containing the value,
possibly followed by error details.

=cut

sub _m_eval_command
{ my ($slf, $ctx, $typ, $cod, $nam) = @_;
  my ($fct, $msg, $pkg, $ret, $val);

  $nam = 'rule'.$slf->{'_rul'} unless defined($nam);
  $pkg = exists($slf->{'_ctx'}) ? $slf->{'_ctx'} : $ctx;
  if ($typ eq 'OS')
  { $val = join("\n", $pkg->call('command', $pkg, $cod));
    $val =~ s/[\n\r\s]+$//m;
    return ($val, 'Execution Error', 'Exit code: '.$ret)
      if ($ret = $pkg->call('status', $pkg));
  }
  elsif ($typ eq 'PERL')
  { my ($pgm, $ret);

    return ($val, 'Perl not available')
      unless ($pgm = $slf->{'_agt'}->get_setting('RDA_PERL'));
    $cod =~ s/"/\\"/g;
    $cod =~ s/\$/\$/g;
    $cod =~ s/\n/ /g;
    $cod = $pgm.' -e "'.$cod.'"';
    $ret = $pkg->call('loadCommand', $pkg, $cod);
    $val = join("\n", $pkg->call('getLines', $pkg));
    $val =~ s/[\n\r\s]+$//m;
    return ($val, 'Execution Error',
      'Exit code: '.$pkg->call('statCommand', $pkg)) unless $ret;
  }
  elsif ($typ eq 'RDA')
  { my ($ret);

    $ret = _eval_command($slf, $nam, $cod);
    $val = _m_get_result($slf, $pkg);
    return ($val, $ret) if $ret;
  }
  elsif ($typ eq 'SQL')
  { my ($ret);

    $ret = $pkg->call('loadSql', $pkg, "SET define on\n$cod");
    $val = join("\n", $pkg->call('getSqlLines', $pkg));
    $val =~ s/^\s+//;
    $val =~ s/[\n\r\s]+$//m;
    return ($val, 'SQL Error', $pkg->call('getSqlMessage', $pkg))
      unless $ret;
    return ($val, 'SQL Error')
      if $pkg->call('grepLastSql', $pkg, '^(ORA|SP2)-\d+','f')
  }
  else
  { return ($val, "Invalid command type $typ");
  }

  # Indicate the successful completion
  ($val);
}

sub _eval_command
{ my ($slf, $nam, $cod) = @_;
  my ($blk, $err);

  # Abort if the evaluation context is not available
  return -1 unless exists($slf->{'_ctx'});

  # Parse the action code
  $blk = RDA::Block->new($nam, $slf->{'_mod'});
  $cod = '' unless defined($cod);
  return 1 if $blk->parse($slf->{'_agt'}, RDA::Handle::Memory->new($cod));

  # Execute the action and indicate its success
  eval {$err = $blk->eval($slf->{'_ctx'}, 1, $PREFIX, $slf->{'_trc'})};
  ($@ || $err) ? 2 : 0;
}

=head2 S<getHcveFact($nam[,$dft])>

This macro performs required fact collection and returns the value of the
specified parameter.

=cut

sub _m_get_fact
{ my ($slf, $ctx, $nam, $dft) = @_;
  my ($cod, $col, $err, $key, $uid, $val, @err);

  # Perform the fact collection when needed
  $nam = uc($nam);
  if (defined($uid = _get_fact_id($slf->{'_map'}, $nam))
    && defined($col = delete($slf->{'_col'}->{$uid})))
  { foreach my $cmd (@$col)
    { next unless ($cod = $cmd->get_data);

      # Execute the command
      ($val, $err, @err) = _m_eval_command($slf, $ctx, $cmd->{'type'} || '',
        $cod, "fact$uid");
      die join('\n', "Errors encountered when collecting fact '$uid':", $err,
        @err, '') if $err;

      # Define parameter and variable
      _m_set_parameter($slf, $ctx, $key, $val)
        if defined($key = $cmd->{'parameter'}) && $key =~ m/^(\w+\.)+\w+$/;
      _m_add_variable($slf, $ctx, $key, $val)
        if defined($key = $cmd->{'variable'}) && $key =~ m/^\$\w+$/;
    }
  }

  # Get the parameter value
  _m_get_parameter($slf, $ctx, $nam, $dft);
}

sub _get_fact_id
{ my ($map, $nam) = @_;

  for (my $key = $nam ;;)
  { return $map->{$nam} = $map->{$key} if exists($map->{$key});
    return undef unless $key =~ s/^((\w+\.)+\w+)\.\w+$/$1/;
  }
}

=head2 S<getHcveFamily($set)>

This macro returns the operating system family related to a HCVE rule set. It
returns an undefined value when the rule set cannot be found.

=cut

sub _m_get_family
{ my ($slf, $ctx, $set) = @_;

  return undef unless $set;
  _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
  $slf->{'_set'}->{$set}->[5];
}

=head2 S<getHcveFile($set)>

This macro returns the file name containing the HCVE rule set. It returns an
undefined value when the rule set cannot be found.

=cut

sub _m_get_file
{ my ($slf, $ctx, $set) = @_;

  return undef unless $set;
  _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
  $slf->{'_set'}->{$set}->[0];
}

=head2 S<getHcveName($set)>

This macro returns the name of a HCVE rule set. It returns an undefined value
when the rule set cannot be found.

=cut

sub _m_get_name
{ my ($slf, $ctx, $set) = @_;

  return undef unless $set;
  _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
  $slf->{'_set'}->{$set}->[2];
}

=head2 S<getHcveParameter($nam[,$dft])>

This macro returns the value of the specified parameter.

=cut

sub _m_get_parameter
{ my ($slf, $ctx, $nam, $dft) = @_;
  my ($val, @tbl);

  @tbl = split(/\./, uc($nam));
  $val = $slf->{'_res'};
  foreach my $itm (@tbl)
  { return RDA::Value::convert_value($dft)
      unless ref($val) eq 'HASH' && exists($val->{$itm});
    $val = $val->{$itm};
  }
  RDA::Value::convert_value($val);
}

=head2 S<getHcvePlatform($set)>

This macro returns the platform related to a HCVE rule set. It returns an
undefined value when the rule set cannot be found.

=cut

sub _m_get_platform
{ my ($slf, $ctx, $set) = @_;

  return undef unless $set;
  _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
  $slf->{'_set'}->{$set}->[4];
}

=head2 S<getHcveProduct($set)>

This macro returns the product related to a HCVE rule set. It returns an
undefined value when the rule set cannot be found.

=cut

sub _m_get_product
{ my ($slf, $ctx, $set) = @_;

  return undef unless $set;
  _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
  $slf->{'_set'}->{$set}->[3];
}

=head2 S<getHcveResult([$rule])>

This macro returns the result string of the specified rule. By default, it
returns the current one.

=cut

sub _m_get_result
{ my ($slf, $ctx, $rul) = @_;

  $rul = $slf->{'_rul'} unless defined($rul);
  ($rul && exists($slf->{'_res'}->{'rule'}->{$rul}))
    ? $slf->{'_res'}->{'rule'}->{$rul}
    : undef;
}

=head2 S<getHcveSets($type[,$osn])>

This macro determines the list of all rule sets from the specified type. You
can specify an alternative operating system as a second argument.

=cut

sub _m_get_sets
{ my ($slf, $ctx, $typ, $osn) = @_;
  my ($fam, $rec, @tbl);

  # On the first call load the HCVE rule set information
  unless ($slf->{'_flg'})
  { if (opendir(DIR, $slf->{'_dir'}))
    { foreach my $set (readdir(DIR))
      { next unless $set =~ m/\.xml$/;
        _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
      }
      closedir(DIR)
    }
    $slf->{'_flg'} = 1;
  }

  # Select rule sets
  if ($typ)
  { $osn = $^O unless defined($osn);
    $osn = $tb_osn{$osn} if exists($tb_osn{$osn});
    $fam = exists($tb_fam{$osn}) ? $tb_fam{$osn} : 'Unix';
    foreach my $set (sort keys(%{$slf->{'_set'}}))
    { $rec = $slf->{'_set'}->{$set};
      next unless $rec->[1] && $rec->[1] eq $typ;

      # Apply the platform restrictions
      if (defined($rec->[4]))
      { next unless _tst_member($rec->[4], $osn);
      }
      elsif (defined($rec->[5]))
      { next unless _tst_member($rec->[5], $fam);
      }

      # Add the diaglet to the list
      push(@tbl, $set);
    }
  }

  # Return the resuls
  @tbl;
}

sub _tst_member
{ my ($lst, $str) = @_;

  foreach my $itm (split(/,/, $lst))
  { return 1 if $itm eq $str;
  }
  0;
}

=head2 S<getHcveType($set)>

This macro returns the type of a HCVE rule set. It returns an undefined value
when the rule set cannot be found.

=cut

sub _m_get_type
{ my ($slf, $ctx, $set) = @_;

  return undef unless $set;
  _get_info($slf, $set) unless exists($slf->{'_set'}->{$set});
  $slf->{'_set'}->{$set}->[1];
}

=head2 S<getHcveValues($str)>

This macro returns the string with all HCVE variable references replaced by
their respective values. It supports nested references. The following reference
formats are supported:

=over 20

=item B<    ${nam}>

Replaces the reference with the variable values. When the variable is not
defined, it replaces the reference with an empty string.

=item B<    ${nam:dft}>

Replaces the reference with the variable values. When the variable is not
defined, it replaces the reference with the default text.

=item B<    ${nam?txt:dft}>

Replaces the reference with the specified text when the variable
exists. Otherwise, it replaces the reference with the default text.

=back

You can prefix the key by a character indicating how the variable value must be
emphasized. It is not used for other replacement texts. The valid style
characters are as follows:

=over 6

=item S<    *> for bold

=item S<    '> (single quote) for italic

=item S<    `> (back quote) for code

=back

It returns the resulting value.

=cut

sub _m_get_values
{ my ($slf, $blk, $str) = @_;

  if ($str && exists($slf->{'_ctx'}))
  { my $ctx = $slf->{'_ctx'};
    1 while $str =~
        s/\$\{([\*\'\`])?((\w+\.)*\w+)((\?)([^\{\}]*?))?(\:([^\{\}]*?))?\}/
          $3 ? _resolve_par($slf, $1, $2, $5, $6, $8)
             : _resolve_var($ctx, $1, $2, $5, $6, $8)/eg;
  }
  $str;
}

sub _resolve_par
{ my ($slf, $stl, $nam, $tst, $txt, $dft) = @_;
  my ($val, @tbl);

  @tbl = split(/\./, uc($nam));
  $val = $slf->{'_res'};
  foreach my $itm (@tbl)
  { return defined($dft) ? $dft : ''
      unless ref($val) eq 'HASH' && exists($val->{$itm});
    $val = $val->{$itm};
  }
  return defined($dft) ? $dft : ''
    unless defined($val) && !ref($val);
  $stl = ($stl && exists($tb_stl{$stl})) ? $tb_stl{$stl} : '';
  $val =~ s/([\042\045\047\050\051\053\055\074\076\133\135\173-\175])/
    sprintf("&#x%X;", ord($1))/ge;
  $stl.$val.$stl;
}

sub _resolve_var
{ my ($ctx, $stl, $nam, $tst, $txt, $dft) = @_;
  my $val;

  if (defined($val = $ctx->get_context->get_value('$'.$nam)))
  { $val = $val->eval_value(1);
    if ($val->is_defined)
    { return defined($txt) ? $txt : '' if $tst;
      $stl = ($stl && exists($tb_stl{$stl})) ? $tb_stl{$stl} : '';
      $val = $val->as_string;
      $val =~ s/([\042\045\047\050\051\053\055\074\076\133\135\173-\175])/
        sprintf("&#x%X;", ord($1))/ge;
      return $stl.$val.$stl;
    }
  }
  defined($dft) ? $dft : '';
}

=head2 S<setHcveContext($nam)>

This macro initializes a context for evaluating action code. It deduces the
initialization file name from the specified object identifier by adding a
C<.def> suffix to it. It deletes the previous context and it clears previous
test results.

It returns zero when that file has been successfully loaded and executed. It
returns -1 for a missing initialization file, -2 when the initialization file cannot be opened, 1 for parsing errors, and 2 for execution errors.

=cut

sub _m_set_context
{ my ($slf, $ctx, $nam) = @_;
  my ($agt, $blk, $err, $fil, $ifh, $out);

  # Delete the previous context
  delete($slf->{'_ctx'});

  # Determine the data collection specification file
  return -1 unless $nam;
  $agt = $slf->{'_agt'};
  $blk = RDA::Block->new($nam, $slf->{'_mod'});
  $fil = RDA::Object::Rda->cat_file($slf->{'_mod'}, $nam);
  $ifh = IO::File->new;
  return -2 unless $ifh->open("<$fil.def") || $ifh->open("<$fil.cfg");

  # Load and parse the file
  return 1 if $blk->parse($agt, $ifh);
  $blk->set_info('aux', $slf);

  # Initialize the macro list
  $agt->get_macros($blk->get_lib);

  # Execute the context initialization
  $slf->{'_ctx'} = $blk;
  $slf->{'_res'} = {rule => {}};
  eval {$err = $blk->eval($blk, 0, $PREFIX, $slf->{'_trc'})};
  return 2 if $@;

  # Share the output control
  if (ref($out = $ctx->get_output))
  { $blk->set_info('rpt', $out);
    $blk->define('$[OUT]', $out);
  }
  return 0;
}

=head2 S<setHcveFact($uid,$xml)>

This method defines a new fact collector.

=cut

sub _m_set_fact
{ my ($slf, $ctx, $uid, $xml) = @_;
  my ($nam, @tbl);

  if ($uid && ref($xml) && (@tbl = $xml->find('sdp_command')))
  { $slf->{'_col'}->{$uid} = [@tbl];
    foreach my $itm ($xml->find('sdp_parameters/sdp_parameter'))
    { $slf->{'_map'}->{uc($nam)} = $uid
        if defined($nam = $itm->{'name'}) && $nam =~ m/^((\w+\.)+\w+)$/;
    }
  }
  0;
}

=head2 S<setHcveParameter($nam,$val)>

This macro assigns a result to the specified parameter.

=cut

sub _m_set_parameter
{ my ($slf, $ctx, $nam, $val) = @_;
  my ($key, $ptr, @tbl);

  @tbl = split(/\./, uc($nam));
  return $val unless defined($key = pop(@tbl));
  $ptr = $slf->{'_res'};
  foreach my $itm (@tbl)
  { $ptr->{$itm} = {} unless ref($ptr->{$itm}) eq 'HASH';
    $ptr = $ptr->{$itm};
  }
  RDA::Value::convert_value($ptr->{$key} =
    (ref($val) =~ m/^RDA::Value::/) ? $val->eval_as_data(1) : $val);
}

=head2 S<setHcveResult($str)>

This macro specifies the results of the current rule and returns the result
string.

=cut

sub _m_set_result
{ my ($slf, $ctx, $str) = @_;

  $slf->{'_res'}->{'rule'}->{$slf->{'_rul'}} = $str;
}

=head2 S<setHcveRule($rule)>

This macro specifies the identifier of the current rule. It returns the
previous value. The current value is not changed if an undefined value is
specified as an argument.

=cut

sub _m_set_rule
{ my ($slf, $ctx, $rul) = @_;
  my $old;

  $old = $slf->{'_rul'};
  $slf->{'_rul'} = $rul if defined($rul);
  $old;
}

=head2 S<setHcveVariable($nam...)>

This macro shares the action variables with the action evaluation context. The
variables are specified by their name. It returns the number of variables that
have been effectively shared.

=cut

sub _m_set_variable
{ my $slf = shift;
  my $blk = shift;
  my ($cnt, $ctx, $glb, $loc);

  # Abort if the evaluation context is not available
  return 0 unless exists($slf->{'_ctx'});

  # Share the local variables
  $glb = $slf->{'_ctx'}->get_context;
  $loc = $blk->get_context;
  foreach my $nam (@_)
  { next unless $nam =~ m/^[\$\@\%]\w+$/;
    $glb->share_variable($nam, RDA::Value::Pointer->new($loc, $nam));
    ++$cnt;
  }

  # Indicate the number of variables that have been shared
  $cnt;
}

# --- Internal routines ------------------------------------------------------

# Get the rule set information
sub _get_info
{ my ($slf, $set) = @_;
  my ($buf, $cnt, $fil, $key, $rec, $val);

  $set =~ s/\.xml$//i;
  $fil = RDA::Object::Rda->cat_file($slf->{'_dir'}, "$set.xml");
  $slf->{'_set'}->{$set} = $rec = [];
  if (open(HCVE, "<$fil"))
  { $buf = '';
    $cnt = 10;
    while (<HCVE>)
    { $buf .= $_;
      $buf =~ s/[\n\r\s]*$/ /;
      if ($buf !~ m#<sdp_diaglet#)
      { $buf = '';
        last unless --$cnt;
      }
      elsif ($buf =~ m#<sdp_diaglet.*?>#)
      { # Decode the attributes
        $buf =~ s#.*<sdp_diaglet\s+##;
        while ($buf =~ s#(\w+)\s*=\s*['"](.*?)['"]\s*##)
        { $rec->[$tb_inf{$1}] = $2 if exists($tb_inf{$1});
        }

        # Complete the information when a valid rule set has been found
        $rec->[0] = $fil if $rec->[1];
        last;
      }
    }
    close(HCVE);
  }
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
