# Context.pm: Class Used for Managing Execution Context

package RDA::Context;

# $Id: Context.pm,v 2.8 2012/08/13 16:20:57 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Context.pm,v 2.8 2012/08/13 16:20:57 mschenke Exp $
#
# Change History
# 20120813  MSC  Introduce the calling block concept.

=head1 NAME

RDA::Context - Class Used for Managing Execution Context

=head1 SYNOPSIS

require RDA::Context;

=head1 DESCRIPTION

The objects of the C<RDA::Context> class are used to manage execution context
for collect specifications.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Block;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.8 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants

# Define the global private variables
my %tb_get = (
  'err' => \&_get_internal,
  'val' => \&_get_internal,
  );
my %tb_int = (
  'err' => 'error',
  'val' => 'last',
  );
my %tb_set = (
  'err' => \&_set_internal,
  'val' => \&_set_internal,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Block-E<gt>new([$par])>

The object constructor. It takes the block reference and the parent context
reference as extra arguments.

The following special keys are used:

=over 12

=item S<    B<'err' > > Last eval error

=item S<    B<'nam' > > Loop name

=item S<    B<'slf' > > Class attribute hash

=item S<    B<'trc' > > Trace level

=item S<    B<'val' > > Last value

=item S<    B<'_blk'> > Current calling block

=item S<    B<'_cnd'> > Condition hash

=item S<    B<'_flg'> > Activity indicator

=item S<    B<'_glb'> > Hash that contains the list of variables to keep

=item S<    B<'_int'> > Internal variable definition

=item S<    B<'_nam'> > Named block definition hash

=item S<    B<'_par'> > Reference to the parent context

=item S<    B<'_pre'> > Trace prefix

=item S<    B<'_stk'> > Context stack

=item S<    B<'_top'> > Reference of the top context

=item S<    B<'_trc'> > Variable trace indicator

=item S<    B<'_val'> > Last assigned value

=item S<    B<'_var'> > Variable definition hash

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $par) = @_;
  my ($slf);

  if (ref($cls))
  { # Create the backup context object
    $slf = bless {
      err  => $cls->{'err'},
      trc  => $cls->{'trc'},
      val  => $cls->{'val'},
      _cnd => $cls->{'_cnd'},
      _int => $cls->{'_int'},
      _blk => $cls->{'_blk'},
      _pre => $cls->{'_pre'},
      _trc => $cls->{'_trc'},
      _var => $cls->{'_var'},
      }, ref($cls);

    # Update the context
    $cls->{'_cnd'} = {};
    $cls->{'_val'} = 0;
    $cls->{'_var'} =
      {map {$_ => $slf->{'_var'}->{$_}} keys(%{$cls->{'_glb'}})};
  }
  else
  { # Create the context object
    $slf = bless {
      err  => RDA::Value::List->new,
      trc  => 0,
      val  => $VAL_UNDEF,
      _flg => 0,
      _glb => {},
      _nam => {},
      _stk => [],
      _trc => 0,
      _val => 0,
      _var => {},
      }, $cls;

    # Chain the contexts
    if (ref($par))
    { $slf->{'_par'} = $par;
      $slf->{'_top'} = $par->{'_top'};
    }
    else
    { $slf->{'_pre'} = 'TRACE';
      $slf->{'_top'} = $slf;
    }

    # Predefine default internal variables
    _init_internal($slf);
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method deletes the object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>get_current>

This method returns the current calling block.

=cut

sub get_current
{ shift->{'_blk'};
}

=head2 S<$h-E<gt>get_dict>

This method returns the variable dictionary.

=cut

sub get_dict
{ shift->{'_var'};
}

=head2 S<$h-E<gt>get_top>

This method returns the reference of the top context.

=cut

sub get_top
{ my $slf = shift->{'_top'};

  while (exists($slf->{'_par'}))
  { $slf = $slf->{'_par'}->{'_top'};
  }
  $slf;
}

=head2 S<$h-E<gt>pop_context($blk[,$par])>

This method restores a previous context. When there is no previous context, it
deactivates the context.

=cut

sub pop_context
{ my ($slf, $blk, $par) = @_;
  my ($bkp);

  if (ref($bkp = pop(@{$slf->{'_stk'}})))
  { # Update kept variables
    foreach my $nam (keys(%{$slf->{'_glb'}}))
    { $bkp->{'_var'}->{$nam} = $slf->{'_var'}->{$nam};
    }

    # Restore the previous context
    $slf->{'err'} = $bkp->{'err'};
    $slf->{'trc'} = $bkp->{'trc'};
    $slf->{'val'} = $bkp->{'val'};
    $slf->{'_cnd'} = $bkp->{'_cnd'};
    $slf->{'_int'} = $bkp->{'_int'};
    $slf->{'_blk'} = $bkp->{'_blk'};
    $slf->{'_pre'} = $bkp->{'_pre'};
    $slf->{'_trc'} = $bkp->{'_trc'};
    $slf->{'_val'} = 0;
    $slf->{'_var'} = $bkp->{'_var'};

    # Delete the backup
    $bkp->delete;
  }
  else
  { # Clear the context
    $slf->{'_cnd'} = {};

    # Delete the local variables
    foreach my $nam (keys(%{$slf->{'_var'}}))
    { delete($slf->{'_var'}->{$nam})
        unless exists($slf->{'_glb'}->{$nam});
    }

    # Transfer library context information
    if (ref($par))
    { my ($cnt, $ctx, $dst, $src, $val, %tbl);

      # Determine the macros to reset
      %tbl = map {$_ => 0}
        $slf->{'_var'}->{'@RESET_MACROS'}->{'val'}->eval_as_array
        if exists($slf->{'_var'}->{'@RESET_MACROS'});

      # Share macros
      if (exists($slf->{'_var'}->{'@SHARE_MACROS'}))
      { $cnt = 0;
        $dst = $par->get_lib;
        $src = $blk->get_lib;
        $val = $slf->{'_var'}->{'@SHARE_MACROS'}->{'val'};
        foreach my $itm ($val->eval_as_array)
        { next unless $itm && exists($src->{$itm});
          $dst->{$itm} = $src->{$itm};
          if (exists($tbl{$itm}))
          { $ctx = $src->{$itm}->get_context;
            $ctx->{'_glb'} = {};
            $ctx->{'_var'} = {};
          }
          ++$cnt;
        }

        # Force to keep the block when macros are shared
        $slf->{'_var'}->{'$KEEP_BLOCK'}->{'val'} = $VAL_UNDEF if $cnt;
      }

      # Copy internal variables
      $par->{'ctx'}->{'err'} = $slf->{'err'};
      $par->{'ctx'}->{'val'} = $slf->{'val'};
    }

    # Make the context inactive
    $slf->{'_flg'} = 0;
  }
}

=head2 S<$h-E<gt>push_context($blk,$par)>

This method activates a context or takes a backup of the current context to
enable recursive calls.

=cut

sub push_context
{ my ($slf, $blk, $par, $flg) = @_;

  if ($slf->{'_flg'})
  { # Backup the context
    push(@{$slf->{'_stk'}}, $slf->new);
  }
  else
  { # Make the context active
    $slf->{'_flg'} = 1;
  }
  if (ref($par))
  { $slf->{'_par'} = $par if $flg;
    $slf->{'_trc'} = ($slf->{'trc'} = $par->{'trc'}) > 1;
  }
  $slf->{'_blk'} = $blk;
  $slf->{'_val'} = 0;
  _init_internal($slf);

  # Return the context reference
  $slf;
}

=head1 CONDITION MANAGEMENT METHODS

=head2 S<$h-E<gt>end_cond($nam)>

This method retrieves the condition value and stores a true value for next
queries.

=cut

sub end_cond
{ my ($slf, $nam) = @_;
  my ($val);

  $val = $slf->{'_cnd'}->{$nam};
  $slf->{'_cnd'}->{$nam} = 1;
  $val;
}

=head2 S<$h-E<gt>get_cond($nam)>

This method retrieves the condition value.

=cut

sub get_cond
{ my ($slf, $nam) = @_;

  $slf->{'_cnd'}->{$nam};
}

=head2 S<$h-E<gt>set_cond($nam,$flg)>

This method stores a condition value.

=cut

sub set_cond
{ my ($slf, $nam, $val) = @_;

  $slf->{'_cnd'}->{$nam} = $val;
}

=head1 NAMED BLOCK MANAGEMENT METHODS

=head2 S<$h-E<gt>find_code($name)>

This method finds the definition of a named block. It returns an undefined
value when no definitions are found.

=cut

sub find_code
{ my ($slf, $nam) = @_;

  while (ref($slf) eq __PACKAGE__)
  { return $slf->{'_nam'}->{$nam} if exists($slf->{'_nam'}->{$nam});
    $slf = $slf->{'_par'};
  }
  undef;
}

=head2 S<$h-E<gt>set_code($name)>

This macro defines a named block. It returns the context reference.

=cut

sub set_code
{ my ($slf, $nam, $def) = @_;

  $slf->{'_nam'}->{$nam} = $def;
  $slf;
}

=head1 VARIABLE MANAGEMENT METHODS

=head2 S<$h-E<gt>check_variable($nam)>

This method indicates whether the specified variable is defined.

=cut

sub check_variable
{ my ($slf, $nam) = @_;

  exists($slf->{'_var'}->{$nam});
}

=head2 S<$h-E<gt>delete_variable($nam)>

This method deletes the specified variable. It returns its previous content or
an undefined value when the variable does not exists.

=cut

sub delete_variable
{ my ($slf, $nam, $flg) = @_;
  my ($val);

  # Check if the variable exists
  unless (exists($slf->{'_var'}->{$nam}))
  { return () if $flg;
    return $VAL_UNDEF;
  }

  # Delete the variable and return its previous value
  $val = $slf->{'_var'}->{$nam}->{'val'};
  _trace_warning($slf, "$nam deleted") if $slf->{'_trc'};
  delete($slf->{'_glb'}->{$nam});
  delete($slf->{'_var'}->{$nam});
  $val;
}

=head2 S<$h-E<gt>get_content($nam[,$flg])>

This method returns the current value of the specified variable. It follows
the pointers to get the effective value. When the flag is set, it creates
nonexistent variables. Otherwise, it returns an undefined value.

=cut

sub get_content
{ my ($slf, $nam, $flg, $typ) = @_;
  my ($dic, $val);

  # Create the variable when not yet defined
  $dic = $slf->{'_var'};
  unless (exists($dic->{$nam}))
  { _trace_warning($slf, "undefined variable $nam") if $slf->{'_trc'};
    return $flg
      ? [$slf, $nam,
         $dic->{$nam}->{'val'} = $slf->get_default($typ || $nam), $dic]
      : undef;
  }

  # Follow the pointers to return the variable value
  $val = $dic->{$nam}->{'val'};
  $val->is_pointer ? [_resolve_pointer($val)] : [$slf, $nam, $val, $dic];
}

sub _resolve_pointer
{ my ($val) = @_;
  my ($ctx, $dic, $nam, %tbl);

  while ($val->is_pointer)
  { $ctx = $val->{'ctx'};
    $dic = exists($val->{'dic'}) ? $val->{'dic'} : $val->{'ctx'}->{'_var'};
    $nam = $val->{'nam'};
    die "RDA-00801: Pointer loop detected\n"
      if $tbl{$dic.$nam}++;
    die "RDA-00802: Pointer referencing a missing variable '$nam'\n"
      unless exists($dic->{$nam});
    $val = $dic->{$nam}->{'val'};
  }
  ($ctx, $nam, $val, $dic);
}

=head2 S<$h-E<gt>get_default($nam)>

This method returns the default value for the specified variable name.

=cut

sub get_default
{ my ($slf, $nam) = @_;

  return $VAL_UNDEF             if $nam =~ m/^\.?\$/;
  return RDA::Value::List->new  if $nam =~ m/^\@/;
  return RDA::Value::Hash->new  if $nam =~ m/^\%/;
  return RDA::Value::Array->new if $nam =~ m/^\.\@/;
  return RDA::Value::Assoc->new if $nam =~ m/^\.\%/;
  die "RDA-00803: Invalid value type for '$nam'\n";
}

=head2 S<$h-E<gt>get_object($nam)>

This method returns the current value of the specified global object. It
returns an undefined value when the global object is not defined.

=cut

sub get_object
{ my ($slf, $nam) = @_;

  $slf = $slf->get_top;
  exists($slf->{'_var'}->{$nam})
    ? $slf->{'_var'}->{$nam}->{'val'}
    : $VAL_UNDEF;
}

=head2 S<$h-E<gt>get_value($nam[,$flg])>

This method returns the current value of the specified variable. When the flag
is set, it creates nonexistent variables. Otherwise, it returns an undefined
value.

=cut

sub get_value
{ my ($slf, $nam, $flg, $typ) = @_;

  # Create the variable when not yet defined
  unless (exists($slf->{'_var'}->{$nam}))
  { _trace_warning($slf, "2 undefined variable $nam") if $slf->{'_trc'};
    return $flg
      ? $slf->{'_var'}->{$nam}->{'val'} = $slf->get_default($typ || $nam)
      : $slf->get_default($nam);
  }

  # Return the variable value
  $slf->{'_var'}->{$nam}->{'val'};
}

=head2 S<$h-E<gt>import_variables($nam,...)>

This method imports variables from previous contexts.

=cut

sub import_variables
{ my $slf = shift;
  my ($ctx, $dic, $trc);

  $dic = $slf->{'_var'};
  $trc = $slf->{'_trc'};
  foreach my $nam (@_)
  { # Skip already defined variable
    next if exists($dic->{$nam});

    # Search in previous contexts
    $ctx = $slf;
    while (exists($ctx->{'_par'}))
    { $ctx = $ctx->{'_par'};
      if (exists($ctx->{'_var'}->{$nam}))
      { $dic->{$nam} = $ctx->{'_var'}->{$nam};
        _trace_value($slf, $nam, $dic->{$nam}->{'val'}) if $trc;
        last;
      }
    }
  }
}

=head2 S<$h-E<gt>incr_value($nam,$num)>

This method increments the specified variable and returns the new value.

=cut

sub incr_value
{ my ($slf, $nam, $val) = @_;
  my ($dic, $trc, $var);

  # Reject non scalar variable
  die "RDA-00804: Bad variable '$nam' for increment or decrement operation\n"
    unless $nam =~ m/^\$/;

  # Increment the variable and return the new value
  $dic = $slf->{'_var'};
  $trc = $slf->{'_trc'};
  if (exists($dic->{$nam}))
  { $var = $dic->{$nam}->{'val'};
    ($slf, $nam, $var, $dic) = _resolve_pointer($var) if $var->is_pointer;
    $val += $var->eval_as_number;
  }
  else
  { _trace_warning($slf, "undefined variable $nam") if $trc;
  }
  $val = RDA::Value::Scalar::new_number($val);
  _trace_value($slf, $nam, $val) if $trc;
  $dic->{$nam}->{'val'} = $slf->{'_val'} = $val;
}

=head2 S<$h-E<gt>keep_variables($nam,...)>

This method keeps specified variables in next calls. Missing variables are
created.

=cut

sub keep_variables
{ my $slf = shift;
  my ($dic, $glb, $trc);

  $dic = $slf->{'_var'};
  $glb = $slf->{'_glb'};
  $trc = $slf->{'_trc'};
  foreach my $nam (@_)
  { $glb->{$nam} = 1;
    next if exists($dic->{$nam});
    $dic->{$nam}->{'val'} = $slf->get_default($nam);
    _trace_value($slf, $nam, $dic->{$nam}->{'val'}) if $trc;
  }
}

=head2 S<$h-E<gt>set_object($nam,$val)>

This method defines a global object.

=cut

sub set_object
{ my ($slf, $nam, $val, $flg) = @_;

  # Validate the value
  if (defined($val))
  { $val = RDA::Value::Scalar::new_object($val)
      unless ref($val) =~ $VALUE;
    die "RDA-00252: Incompatible types\n"
      if ($nam =~ m/^@/ xor ref($val) eq 'RDA::Value::List')
      || ($nam =~ m/^%/ xor ref($val) eq 'RDA::Value::Hash');
  }
  else
  { $val = $slf->get_default($nam);
  }

  # Define the global object
  $slf = $slf->get_top;
  $slf->{'_glb'}->{$nam} = -1;
  _trace_value($slf, $nam, $val) if $slf->{'_trc'} && !$flg;
  $slf->{'_var'}->{$nam}->{'val'} = $slf->{'_val'} = $val;
}

=head2 S<$h-E<gt>set_value($nam,$val)>

This method provides a new value for the specified variable.

=cut

sub set_value
{ my ($slf, $nam, $val) = @_;

  _trace_value($slf, $nam, $val) if $slf->{'_trc'};
  $slf->{'_var'}->{$nam}->{'val'} = $slf->{'_val'} = $val;
}

=head2 S<$h-E<gt>share_variable($nam,$ref)>

This method shares a variable between two contexts.

=cut

sub share_variable
{ my ($slf, $nam, $ref) = @_;
  my ($dic);

  # Validate the arguments
  die "RDA-00251: Invalid reference assignment\n"
    unless ref($ref) && $ref->is_pointer;
  die "RDA-00252: Incompatible types\n"
    unless substr($nam, 0, 1) eq substr($ref->{'nam'}, 0, 1);

  # Create the variable when not yet defined
  $dic = exists($ref->{'dic'}) ? $ref->{'dic'} : $ref->{'ctx'}->{'_var'};
  $ref = $ref->{'nam'};
  $dic->{$ref}->{'val'} = $slf->get_default($ref)
    unless exists($dic->{$ref});
  $ref = $dic->{$ref};

  # Share the variables
  _trace_value($slf, $nam, $ref->{'val'}) if $slf->{'_trc'};
  $slf->{'_var'}->{$nam} = $ref;
}

=head1 INTERNAL VARIABLE MANAGEMENT METHODS

=head2 S<$h-E<gt>define_internal($abr,$nam[,$obj[,$get[,$set]]])>

This method defines an internal variable.

=cut

sub define_internal
{ my ($slf, $abr, $nam, $obj, $get, $set) = @_;

  # Validate the arguments
  die "RDA-00805: Bad internal variable abbreviation '$abr'\n"
    unless $abr && $abr =~ m/^[A-Za-z]\w*$/;
  $obj = $slf                                       unless ref($obj);
  ($get, $set) = (\&_get_internal, \&_set_internal) unless ref($get) eq 'CODE';
  $set = \&_set_error                               unless ref($set) eq 'CODE';

  # Define the internal variable
  $slf->{'_int'}->{$abr} = [$nam, $obj, $set, $get];
}

=head2 S<$h-E<gt>delete_internal($abr)>

This method deletes an internal variable definition.

=cut

sub delete_internal
{ my ($slf, $abr) = @_;

  delete($slf->{'_int'}->{$abr});
}

sub _init_internal
{ my ($slf) = @_;
  my ($tbl);

  $slf->{'_int'} = {map {$_ => [$tb_int{$_}, $slf, $tb_set{$_}, $tb_get{$_}]}
    keys(%tb_int)};
}

=head2 S<$h-E<gt>get_internal($abr)>

This method returns the current value of the specified internal variable.

=cut

sub get_internal
{ my ($slf, $abr) = @_;
  my ($rec);

  die "RDA-00800: Cannot modify the internal variable '$abr'\n"
    unless exists($slf->{'_int'}->{$abr});
  $rec = $slf->{'_int'}->{$abr};
  &{$rec->[3]}($rec->[1], $abr);
}

sub _get_internal
{ my ($slf, $abr) = @_;

  $slf->{$abr};
}

=head2 S<$h-E<gt>set_internal($abr,$val)>

This method modifies the value of an internal variable.

=cut

sub set_internal
{ my ($slf, $abr, $val) = @_;
  my ($rec);

  die "RDA-00800: Cannot modify the internal variable '$abr'\n"
    unless exists($slf->{'_int'}->{$abr});
  $rec = $slf->{'_int'}->{$abr};
  if ($slf->{'_trc'})
  { if ($val == $slf->{'_val'})
    { _trace_warning($slf, $rec->[0].' assigned with same content');
    }
    else
    { _trace_value($slf, $rec->[0], $val)
    }
  }
  &{$rec->[2]}($rec->[1], $abr, $val);
}

sub _set_error
{ my ($slf, $abr) = @_;

  die "RDA-00800: Cannot modify the internal variable '"
    .$slf->{'_int'}->{$abr}->[0]."'\n";
}

sub _set_internal
{ my ($slf, $abr, $val) = @_;

  $slf->{$abr} = $val;
}

=head1 TRACE MANAGEMENT METHODS

=head2 S<$h-E<gt>check_trace($level)>

This method indicates if the current trace level is equal to or higher than
the level specified by the argument.

=cut

sub check_trace
{ my ($slf, $lvl) = @_;

  $slf->{'_trc'} >= $lvl;
}

=head2 S<$h-E<gt>get_trace>

This method returns the current trace level.

=cut

sub get_trace
{ shift->{'trc'};
}

=head2 S<$h-E<gt>set_prefix($txt)>

This method specifies a new trace prefix in the package context and returns its
previous value.

=cut

sub set_prefix
{ my ($slf, $txt) = @_;

  $slf = $slf->{'_top'};
  ($slf->{'_pre'}, $txt) = ($txt, $slf->{'_pre'});
  $txt;
}

=head2 S<$h-E<gt>set_trace($lvl)>

This method specifies a new trace level for the current context and returns its
previous value.

=cut

sub set_trace
{ my ($slf, $lvl) = @_;

  $slf->{'_trc'} = $lvl > 1;
  ($slf->{'trc'}, $lvl) = ($lvl, $slf->{'trc'});
  $lvl;
}

=head2 S<$h-E<gt>trace($str...)>

This method adds a line into the trace.

=cut

sub trace
{ my $slf = shift;

  print join('', $slf->{'_top'}->{'_pre'}, ':',
    grep {defined($_) && !ref($_)} @_)."\n";
}

=head2 S<$h-E<gt>trace_string($str)>

This method adds a string into the trace.

=cut

sub trace_string
{ my ($slf, $txt) = @_;

  print $slf->{'_top'}->{'_pre'}.':'.$txt."\n";
}

=head2 S<$h-E<gt>trace_value($txt, $val)>

This method dumps the value into the trace when the variable tracing is
enabled.

=cut

sub trace_value
{ my ($slf, $txt, $val) = @_;

  print $val->dump(1, $slf->{'_top'}->{'_pre'}.'/'.$txt.': ')."\n"
    if $slf->{'_trc'};
}

sub _trace_value
{ my ($slf, $txt, $val) = @_;

  print $val->dump(1, $slf->{'_top'}->{'_pre'}.'/'.$txt.': ')."\n";
}

=head2 S<$h-E<gt>trace_warning($str...)>

This method adds a warning line into the trace when the variable tracing is
enabled.

=cut

sub trace_warning
{ my $slf = shift;

  print join('', '  ', $slf->{'_top'}->{'_pre'}, ':',
    grep {defined($_) && !ref($_)} @_)."\n" if $slf->{'_trc'};
}

sub _trace_warning
{ my $slf = shift;

  print join('', '  ', $slf->{'_top'}->{'_pre'}, ':',
    grep {defined($_) && !ref($_)} @_)."\n";
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Handle::Data|RDA::Handle::Data.pm>,
L<RDA::Handle::Filter|RDA::Handle::Filter.pm>,
L<RDA::Handle::Memory|RDA::Handle::Memory.pm>,
L<RDA::Operator::Array|RDA::Operator::Array>,
L<RDA::Operator::Hash|RDA::Operator::Hash>,
L<RDA::Operator::Scalar|RDA::Operator::Scalar>,
L<RDA::Operator::Value|RDA::Operator::Value>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Buffer|RDA::Object::Buffer.pm>,
L<RDA::Object::Convert|RDA::Object::Convert.pm>,
L<RDA::Object::Cookie|RDA::Object::Cookie.pm>,
L<RDA::Object::Dbd|RDA::Object::Dbd.pm>,
L<RDA::Object::Display|RDA::Object::Display.pm>,
L<RDA::Object::Env|RDA::Object::Env.pm>,
L<RDA::Object::Ftp|RDA::Object::Ftp.pm>,
L<RDA::Object::Htm|RDA::Object::Html.pm>,
L<RDA::Object::Jar|RDA::Object::Jar.pm>,
L<RDA::Object::Lock|RDA::Object::Lock.pm>,
L<RDA::Object::Output|RDA::Object::Output.pm>,
L<RDA::Object::Parser|RDA::Object::Parser.pm>,
L<RDA::Object::Pipe|RDA::Object::Pipe.pm>,
L<RDA::Object::Pod|RDA::Object::Pod.pm>,
L<RDA::Object::Rda|RDA::Object::Rda.pm>,
L<RDA::Object::Report|RDA::Object::Report.pm>,
L<RDA::Object::Request|RDA::Object::Request.pm>,
L<RDA::Object::Response|RDA::Object::Response.pm>,
L<RDA::Object::Sgml|RDA::Object::Sgml.pm>,
L<RDA::Object::Sqlplus|RDA::Object::Sqlplus.pm>,
L<RDA::Object::Table|RDA::Object::Table.pm>,
L<RDA::Object::Toc|RDA::Object::Toc.pm>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent.pm>,
L<RDA::Object::Windows|RDA::Object::Windows.pm>,
L<RDA::Object::Xml|RDA::Object::Xml.pm>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Array|RDA::Value::Array>,
L<RDA::Value::Assoc|RDA::Value::Assoc>,
L<RDA::Value::Code|RDA::Value::Code>,
L<RDA::Value::Global|RDA::Value::Global>,
L<RDA::Value::Hash|RDA::Value::Hash>,
L<RDA::Value::Internal|RDA::Value::Internal>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Operator|RDA::Value::Operator>,
L<RDA::Value::Object|RDA::Value::Operator>,
L<RDA::Value::Pointer|RDA::Value::Pointer>,
L<RDA::Value::Property|RDA::Value::Property>,
L<RDA::Value::Scalar|RDA::Value::Scalar>,
L<RDA::Value::Variable|RDA::Value::Variable>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
