# Property.pm: Class Used for Managing Properties

package RDA::Value::Property;

# $Id: Property.pm,v 2.20 2012/04/25 06:21:34 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Value/Property.pm,v 2.20 2012/04/25 06:21:34 mschenke Exp $
#
# Change History
# 20120422  MSC  Add the CUR.ACCESS property.

=head1 NAME

RDA::Value::Property - Class Used for Managing Properties

=head1 SYNOPSIS

require RDA::Value::Property;

=head1 DESCRIPTION

The objects of the C<RDA::Value::Property> class are used to manage
properties.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Value::List;
  use RDA::Value::Scalar;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.20 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Value Exporter);

# Define the global private variables
my %tb_cas = (
  AS  => 1,
  AUX => 1,
  CFG => 1,
  CUR => 1,
  ENV => 1,
  GRP => 1,
  OS  => 1,
  OUT => 1,
  RDA => 1,
  REG => 1,
  '-' => 1,
  );
my %tb_get = (
  AS  => \&_get_as,
  AUX => \&_get_aux,
  CFG => \&_get_setting,
  CUR => \&_get_current,
  ENV => \&_get_env,
  GRP => \&_get_group,
  OS  => \&_get_os,
  OUT => \&_get_output,
  RDA => \&_get_rda,
  REG => \&_get_registry,
  '-' => \&_get_setting,
  );
my %tb_set = (
  AS  => \&_set_error,
  AUX => \&_set_aux,
  CFG => \&_set_setting,
  CUR => \&_set_current,
  ENV => \&_set_error,
  GRP => \&_set_error,
  OUT => \&_set_error,
  OS  => \&_set_error,
  RDA => \&_set_error,
  REG => \&_set_error,
  '-' => \&_set_temp,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Value::Property-E<gt>new($blk,$typ,$nam,$dft)>

The object constructor.

A C<RDA::Value::Property> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'blk' > > Reference to the current block

=item S<    B<'dft' > > Default value

=item S<    B<'flg' > > Dynamic name error handling indicator

=item S<    B<'grp' > > Property group

=item S<    B<'nam' > > Property name

=item S<    B<'var' > > Variable type

=item S<    B<'_dyn'> > Dynamic property indicator

=item S<    B<'_get'> > Associated 'get' routine

=item S<    B<'_grp'> > Dynamic group name

=item S<    B<'_nam'> > Dynamic property name

=item S<    B<'_set'> > Associated 'set' routine

=back

=cut

# Static property constructor
sub new
{ my ($cls, $blk, $var, $nam, $dft) = @_;
  my $grp;

  # Determine the property group
  ($grp, $nam) = ($nam =~ m/^([A-Z]+)\.(.*)$/i && exists($tb_get{$1}))
    ? ($1,  $2)
    : ('-', $nam);

  # Create the property object and return its reference
  bless {
    blk  => $blk,
    dft  => $dft,
    grp  => $grp,
    nam  => $tb_cas{$grp} ? uc($nam) : $nam,
    var  => $var,
    _get => $tb_get{$grp},
    _set => $tb_set{$grp},
    }, ref($cls) || $cls;
}

# Dynamic property constructor
sub new_dynamic
{ my ($cls, $blk, $var, $grp, $nam, $dft, $flg) = @_;
  
  # Create the property object and return its reference
  bless {
    blk  => $blk,
    dft  => $dft,
    flg  => $flg,
    grp  => '-',
    nam  => '?',
    var  => $var,
    _dyn => 1,
    _grp => $grp,
    _nam => $nam,
    }, ref($cls) || $cls;
}

# Resolve dynamic group and name
sub _resolve
{ my ($slf, $flg) = @_;
  my ($grp, $nam);

  $grp = uc($slf->{'_grp'}->eval_as_string);
  $nam = $slf->{'_nam'}->eval_as_string;
  ($grp, $nam) = ('-', "$grp.$nam") unless exists($tb_get{$grp});
  $slf->{'grp'}  = $grp;
  $slf->{'nam'}  = $tb_cas{$grp} ? uc($nam) : $nam;
  $slf->{'_get'} = $tb_get{$grp};
  $slf->{'_set'} = $tb_set{$grp};
  return 0 if $nam =~ m/^\w+(\.\w+)*$/;
  return 1 if $flg && $slf->{'flg'};
  die "RDA-00835: Invalid property name '$nam'";
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the value dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;

  $lvl = 0  unless defined($lvl);
  $txt = '' unless defined($txt);

  $slf->dump_object({}, $lvl, $txt, '');
}

sub dump_object
{ my ($slf, $tbl, $lvl, $txt, $arg) = @_;

  '  ' x $lvl.$txt.(exists($slf->{'_dyn'})
    ? 'Dynamic_Property'
    : "Property=".$slf->{'grp'}.'.'.$slf->{'nam'});
}

=head2 S<$h-E<gt>is_lvalue>

This method indicates whether the value can be used as a left value.

=cut

sub is_lvalue
{ shift->{'var'};
}

=head1 ASSIGN AND EVAL METHODS

=head2 S<$h-E<gt>assign_value($val[,$flg])>

This method assigns a new value to the current value. It evaluates the new
value unless the flag is set. It returns the new value.

=cut

sub assign_item
{ my ($slf, $tbl) = @_;
  my ($typ, $val);

  _resolve($slf) if exists($slf->{'_dyn'});
  $typ = $slf->{'var'};
  &{$slf->{'_set'}}($slf,
    ($typ eq '@') ? [map {$_->as_data} splice(@$tbl, 0)] :
    ($typ eq '%') ? {map {$_->as_data} splice(@$tbl, 0)} :
                    _as_data($val = shift(@$tbl)));
  undef;
}

sub assign_var
{ my ($slf, $val) = @_;
  my $typ;

  _resolve($slf) if exists($slf->{'_dyn'});
  $typ = $slf->{'var'};
  if ($typ eq '$')
  { &{$slf->{'_set'}}($slf, $val->is_list
      ? scalar @$val
      : _as_data($val));
  }
  elsif ($typ eq '@')
  { &{$slf->{'_set'}}($slf, $val->is_list
      ? [map {$_->as_data} @$val]
      : [$val->as_data]);
  }
  elsif ($typ eq '%')
  { &{$slf->{'_set'}}($slf, $val->is_list
      ? {map {ref($_) ? $_->as_data : $_} @$val}
      : {$val->as_data});
  }
  undef;
}

sub _as_data
{ my ($val) = @_;

  ($val) = $val->as_data if ref($val);
  $val;
}

sub _set_error
{ die "RDA-00834: Cannot assign a new value to the property '"
    .shift->{'nam'}."'\n";
}

=head2 S<$h-E<gt>eval_value([$flg])>

This method evaluates a property. When the flag is set, it executes code
values.

=cut

sub eval_value
{ my ($slf, $flg) = @_;
  my ($dft, @tbl);

  # Evaluate the property
  @tbl = &{$slf->{'_get'}}($slf)
    unless exists($slf->{'_dyn'}) && _resolve($slf, 1);
  return ($slf->{'var'} eq '$')
    ? RDA::Value::Scalar::new_from_data($tbl[0])
    : RDA::Value::List::new_from_data(@tbl)
    unless (scalar @tbl) == 0 && defined($slf->{'dft'});

  # Return the default value when missing
  $dft = $slf->{'dft'}->eval_value($flg);
  $dft = RDA::Value::List->new($dft) unless $dft->is_list;
  ($slf->{'var'} eq '$') ? $dft->[0] : $dft;
}

# --- Find object mechanim ----------------------------------------------------

sub find_object
{ my ($slf, $typ) = @_;
  my $val;

  # Treat a request without creating the property
  return ($slf->eval_value) unless $typ;

  # Get the variable value, creating the property when needed
  die "RDA-00820: Incompatible types\n"
    unless !defined($slf->{'var'})
    || $slf->{'var'} eq $typ
    || $slf->{'var'} eq '$';
  $val = $slf->eval_value(1);
  return ($val, [$slf->{'blk'}->{'ctx'}, $slf->{'nam'}, $val]);
}

# --- AS properties -----------------------------------------------------------

my %tb_as = (
  BAT     => sub {RDA::Object::Rda->as_bat(@_)},
  BATCH   => sub {RDA::Object::Rda->as_bat(@_, 1)},
  CMD     => sub {RDA::Object::Rda->as_cmd(@_)},
  COMMAND => sub {RDA::Object::Rda->as_cmd(@_, 1)},
  EXE     => sub {RDA::Object::Rda->as_exe(@_)},
  );

sub _get_as
{ my ($slf) = @_;
  my ($dft, $nam);

  $dft = $slf->{'dft'};
  $dft = defined($dft) ? $dft->eval_as_string : '';
  $nam = $slf->{'nam'};
  (exists($tb_as{$nam}) ? &{$tb_as{$nam}}($dft) : $dft.'.'.lc($nam));
}

# --- Auxiliary properties ----------------------------------------------------

sub _get_aux
{ my ($slf) = @_;

  ($slf->{'blk'}->get_top('aux')->get_value($slf->{'nam'}));
}

sub _set_aux
{ my ($slf, $val) = @_;

  $slf->{'blk'}->get_top('aux')->set_value($slf->{'nam'}, $val);
}

# --- Current objects ---------------------------------------------------------

my %tb_cur = (
  ACCESS    => sub {shift->{'blk'}->get_access},
  AVAILABLE => sub {my ($slf) = @_;
                    my ($val, @tbl);
                    $val = $slf->{'blk'}->get_package('sct');
                    @tbl = grep {$val->{$_} == 0} keys(%$val);
                    return scalar @tbl if $slf->{'var'} eq '$';
                    return sort @tbl;
                  },
  DIRECTORY => sub {my $val = shift->{'blk'}->get_package('dir');
                    return () unless defined($val);
                    $val;
                   },
  EGID      => sub {my ($slf) = @_;
                    my @tbl = split(/ /, $));
                    shift(@tbl);
                   },
  ENV       => sub {my $val = shift->{'blk'}->get_top('env');
                    return () unless defined($val);
                    $val;
                   },
  EUID      => sub {$>},
  GID       => sub {my ($slf) = @_;
                    my @tbl = split(/ /, $();
                    my $gid = shift(@tbl);
                    return ($gid) if $slf->{'var'} eq '$';
                    @tbl;
                   },
  GROUP     => sub {shift->{'blk'}->get_output->get_group},
  LAST      => sub {shift->{'blk'}->get_output->get_info('lst')},
  LOCK      => sub {shift->{'blk'}->get_lock},
  MODULE    => sub {shift->{'blk'}->get_package('oid')},
  NEXT      => sub {@{shift->{'blk'}->get_package('nxt')}},
  OUTPUT    => sub {shift->{'blk'}->get_output->get_current},
  OWNER     => sub {shift->{'blk'}->get_output->get_owner},
  PERL      => sub {my $val =
                     shift->{'blk'}->get_agent->get_setting('RDA_PERL');
                    return () unless defined($val);
                    $val;
                   },
  PREFIX    => sub {shift->{'blk'}->get_output->get_prefix},
  PREVIOUS  => sub {my ($slf) = @_;
                    my $val = $slf->{'blk'}->get_package('sct');
                    my @tbl = grep {$val->{$_} > 0} keys(%$val);
                    return (scalar @tbl) if $slf->{'var'} eq '$';
                    return sort @tbl;
                   },
  REPORT    => sub {shift->{'blk'}->get_report},
  SECTIONS  => sub {my ($slf) = @_;
                    my @tbl = keys(%{$slf->{'blk'}->get_package('sct')});
                    return (scalar @tbl) if $slf->{'var'} eq '$';
                    return sort @tbl;
                   },
  SETUP     => sub {shift->{'blk'}->get_agent('oid')},
  SHLIB     => sub {my ($slf) = @_;
                    return (scalar $slf->{'blk'}->get_config->get_shlib)
                      if $slf->{'var'} eq '$';
                    $slf->{'blk'}->get_config->get_shlib;
                   },
  TARGET    => sub {shift->{'blk'}->get_agent->get_target->get_current},
  TOP       => sub {shift->{'blk'}->get_top('oid')},
  UID       => sub {$<},
  );

sub _get_current
{ my ($slf) = @_;
  my ($nam);

  $nam = $slf->{'nam'};
  return () unless exists($tb_cur{$nam});
  (&{$tb_cur{$nam}}($slf));
}

sub _set_current
{ my ($slf, $val) = @_;

  _set_error($slf) unless $slf->{'nam'} eq 'NEXT';

  die "RDA-00820: Incompatible types\n" unless ref($val) eq 'ARRAY';
  $slf->{'blk'}->get_package->set_info('nxt', $val);
}

# --- Environment properties --------------------------------------------------

sub _get_env
{ my ($slf) = @_;

  return ($slf->{'blk'}->get_top('env')->get_value($slf->{'nam'}))
    if $slf->{'var'} eq '$';
  ($slf->{'blk'}->get_top('env')->get_list($slf->{'nam'}));
}

# --- Group definitions -------------------------------------------------------

sub _get_group
{ my ($slf) = @_;

  ($slf->{'blk'}->get_package('cfg')->get_group($slf->{'nam'}));
}

# --- Operating system indicators ---------------------------------------------

sub _get_os
{ my ($slf) = @_;

  ((uc($slf->{'blk'}->get_package('cfg')->get_os) eq $slf->{'nam'}) ? 1 : 0);
}

# --- Report directories ------------------------------------------------------

sub _get_output
{ my ($slf) = @_;

  ($slf->{'blk'}->get_output->get_path($slf->{'nam'}));
}

# --- RDA properties ----------------------------------------------------------

sub _get_rda
{ my ($slf) = @_;

  ($slf->{'blk'}->get_package('cfg')->get_value($slf->{'nam'}));
}

# --- RDA registry entries ----------------------------------------------------

sub _get_registry
{ my ($slf) = @_;

  (ref($slf->{'dft'})
    ? $slf->{'blk'}->get_package('agt')->get_registry('REG.'.$slf->{'nam'},
        sub {shift->eval_as_data(1)}, $slf->{'dft'})
    : $slf->{'blk'}->get_package('agt')->get_registry('REG.'.$slf->{'nam'}));
}

# --- Settings ----------------------------------------------------------------

sub _get_setting
{ my ($slf) = @_;
  my ($val);

  return ($val)
    if defined($val = $slf->{'blk'}->get_agent->get_setting($slf->{'nam'}));
  ()
}

sub _set_setting
{ my ($slf, $val) = @_;

  defined($val)
    ? $slf->{'blk'}->get_agent->set_setting($slf->{'nam'}, $val)
    : $slf->{'blk'}->get_agent->del_setting($slf->{'nam'});
}

# --- Temporary settings ------------------------------------------------------

sub _set_temp
{ my ($slf, $val) = @_;

  defined($val)
    ? $slf->{'blk'}->get_agent->set_temp_setting($slf->{'nam'}, $val)
    : $slf->{'blk'}->get_agent->clr_temp_setting($slf->{'nam'});
}

1;

__END__

=head1 SEE ALSO

L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Module|RDA::Module>,
L<RDA::Object::Env|RDA::Object::Env>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Target|RDA::Object::Target>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Scalar|RDA::Value::Scalar>,
L<RDA::Value::List|RDA::Value::List>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
