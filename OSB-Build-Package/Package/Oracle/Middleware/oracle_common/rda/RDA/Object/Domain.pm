# Domain.pm: Class Used for Managing Oracle WebLogic Server Domains

package RDA::Object::Domain;

# $Id: Domain.pm,v 1.20 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Domain.pm,v 1.20 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Domain - Class Used for Managing Oracle WebLogic Server Domains

=head1 SYNOPSIS

require RDA::Object::Domain;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Domain> class are used to interface with
Oracle WebLogic Server domains. It is a sub class of
L<RDA::Object::Target|RDA::Object::Target>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object;
  use RDA::Object::Rda;
  use RDA::Object::Target;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.20 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  hsh => {'RDA::Object::Domain'   => 1,
          'RDA::Object::Home'     => 1,
          'RDA::Object::Instance' => 1,
          'RDA::Object::System'   => 1,
          'RDA::Object::Target'   => 1,
          'RDA::Object::WlHome'   => 1,
         },
  );
@ISA     = qw(RDA::Object::Target RDA::Object Exporter);
%SDCL    = (
  als => {
    'getDomainAttr'  => ['${CUR.TARGET}', 'get_attr'],
    'getProductHome' => ['${CUR.TARGET}', 'get_product'],
    'getServer'      => ['${CUR.TARGET}', 'get_server'],
    'getWlstHome'    => ['${CUR.TARGET}', 'get_wlst'],
    'hasDomainAttr'  => ['${CUR.TARGET}', 'has_attr'],
    'setServer'      => ['${CUR.TARGET}', 'set_server'],
    },
  dep => [qw(RDA::Object::Home)],
  inc => [qw(RDA::Object::Target RDA::Object)],
  met => {
    'get_attr'    => {ret => 0},
    'get_product' => {ret => 0},
    'get_server'  => {ret => 1},
    'get_wlst'    => {ret => 1},
    'has_attr'    => {ret => 0},
    'set_product' => {ret => 0},
    'set_server'  => {ret => 0},
    },
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Domain-E<gt>new($oid,$agt,$def[,$par[,...]])>

The object constructor. It takes the object identifier, the agent reference,
the definition hash reference, the parent target reference, and initial
attributes as arguments.

Do not use this constructor directly. Create all targets using the
L<RDA::Object::Target|RDA::Object::Target> methods.

C<RDA::Object::Domain> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'dom' > > Domain home directory

=item S<    B<'oid' > > Object identifier

=item S<    B<'par' > > Reference to the parent target

=item S<    B<'_abr'> > Symbol definition hash

=item S<    B<'_bkp'> > Backup of environment variables

=item S<    B<'_cch'> > Reference to the Common Components home target

=item S<    B<'_chl'> > List of the child keys

=item S<    B<'_def'> > Target definition

=item S<    B<'_det'> > Detected home directories

=item S<    B<'_dom'> > Domain attribute hash

=item S<    B<'_env'> > Environment specifications

=item S<    B<'_fcs'> > Focus hash

=item S<    B<'_hom'> > Reference to the Oracle home target

=item S<    B<'_prs'> > Symbol detection parse tree

=item S<    B<'_shr'> > Share indicator

=item S<    B<'_srv'> > Server hash

=item S<    B<'_typ'> > Target type

=item S<    B<'_wlh'> > Reference to the Oracle WebLogic Server home target

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $oid, $agt, $def, $par, @arg) = @_;
  my ($flg, $key, $nam, $slf, $tgt, $val);

  # Create the Oracle WebLogic Server domain object
  $slf = bless {
    agt  => $agt,
    oid  => $par->get_unique($oid),
    par  => $par,
    _chl => [],
    _def => $def,
    _shr => $def->{'DEDICATED_DOMAIN'} ? 0 : 1,
    _fcs => {},
    _typ => 'DOM',
  }, ref($cls) || $cls;

  # Load the target definition
  $slf->{'dom'} = RDA::Object::Rda->cat_dir($def->{'DOMAIN_HOME'})
    if exists($def->{'DOMAIN_HOME'}) && defined($def->{'DOMAIN_HOME'});

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $slf->{$key} = $val if defined($val);
  }

  # Validate the configuration
  die "RDA-01380: Missing domain home directory in $oid target\n"
    unless exists($slf->{'dom'});

  # Load the associated Oracle home target
  unless ($def->{'MISSING_HOME'})
  { if (exists($def->{'HOME_TARGET'}) && defined($def->{'HOME_TARGET'}))
    { $val = $def->{'HOME_TARGET'};
      $slf->{'_hom'} =
        (ref($val) eq 'RDA::Object::Home' && $val->{'_typ'} eq 'OH')
        ? $val
        : $slf->get_target($val);
      push(@{$slf->{'_chl'}}, '_hom');
    }
    elsif (defined($val = _find_home($slf, $def)))
    { if ($def->{'DEDICATED_HOME'}
        || !($tgt = $par->find_target('OH', hom => $val)))
      { $nam = $oid;
        $nam =~ s/^DOM_/OH_/i;
        $tgt = $slf->add_target($nam,
          {DEDICATED_HOME => $flg,
           OH_ABBR        => $def->{'OH_ABBR'},
           ORACLE_HOME    => $val,
          });
      }
      $slf->{'_hom'} = $tgt;
      push(@{$slf->{'_chl'}}, '_hom');
    }
  }

  # Load the associated product home targets
  unless ($def->{'MISSING_PRODUCT'})
  { foreach $key (@{_get_item($slf, 'seq', [])})
    { $val = $slf->{'_det'}->{'hom'}->{$key};
      if ($def->{'DEDICATED_PRODUCT'}
        || !($tgt = $par->find_target('OH', hom => $val)))
      { $nam = $oid;
        $nam =~ s/^DOM_/OH_$key\_/i;
        $tgt = $slf->add_target($nam,
          {DEDICATED_HOME => $flg,
           OH_ABBR        => "\$$key",
           ORACLE_HOME    => $val,
          });
      }
      $slf->{"-$key"} = $tgt;
      $slf->{'_hom'} = $tgt unless exists($slf->{'_hom'});
      push(@{$slf->{'_chl'}}, "-$key");
    }
  }

  # Load the associated Oracle WebLogic Server home target
  unless ($def->{'MISSING_WL_HOME'})
  { if (exists($def->{'WL_HOME_TARGET'}))
    { $slf->{'_wlh'} = $tgt =
        (ref($val = $def->{'WL_HOME_TARGET'}) eq 'RDA::Object::WlHome')
        ? $val
        : $slf->get_target($val);
      push(@{$slf->{'_chl'}}, '_wlh');
    }
    elsif (defined($val = _find_wl_home($slf, $def)))
    { if ($def->{'DEDICATED_HOME'}
        || !($tgt = $par->find_target('WH', wlh => $val)))
      { $nam = $oid;
        $nam =~ s/^DOM_/WH_/i;
        $tgt = $slf->add_target($nam,
          {DEDICATED_WL_HOME => $flg,
           MH_ABBR           => $def->{'MH_ABBR'},
           MW_HOME           => _find_mw_home($slf, $def),
           WH_ABBR           => $def->{'WH_ABBR'},
           WL_HOME           => $val,
          });
      }
      $slf->{'_wlh'} = $tgt;
      push(@{$slf->{'_chl'}}, '_wlh');
    }
  }

  # Load the associated Common Components home target
  unless ($def->{'MISSING_COMMON'})
  { if (exists($def->{'COMMON_TARGET'}))
    { $val = $def->{'COMMON_TARGET'};
      $slf->{'_cch'} =
        (ref($val) eq 'RDA::Object::Home' && $val->{'_typ'} eq 'CH')
        ? $val
        : $slf->get_target($val);
      push(@{$slf->{'_chl'}}, '_cch');
    }
    elsif (defined($val = _find_common($slf, $def)))
    { if ($def->{'DEDICATED_HOME'}
        || !($tgt = $par->find_target('CH', cch => $val)))
      { $nam = $oid;
        $nam =~ s/^DOM_/CH_/i;
        $tgt = $slf->add_target($nam,
          {DEDICATED_HOME => $flg,
           OH_ABBR        => $def->{'CH_ABBR'} || '$CH',
           ORACLE_HOME    => $val,
          }, cch => $val);
      }
      $slf->{'_cch'} = $tgt;
      push(@{$slf->{'_chl'}}, '_cch');
    }
  }

  # Disable any further detection
  $slf->{'_det'} = {} unless exists($slf->{'_det'});

  # Initiate the symbol management when applicable
  unless (RDA::Object::Rda->is_vms)
  { $slf->{'_abr'} = {};
    $slf->set_symbol($def->{'DH_ABBR'} || '$DH', $slf->{'dom'})
      if exists($slf->{'dom'});
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>get_attr($name[,$default])>

This method returns the value of the domain attributes, extracted from the
F<$DOMAIN_HOME/init-info/tokenValue.properties> file. When not found, it
returns the default value.

=cut

sub get_attr
{ my ($slf, $nam, $dft) = @_;

  # Load all attributes on first usage
  _load_attr($slf) unless exists($slf->{'_dom'});

  # Return the attribute values
  exists($slf->{'_dom'}->{$nam})
    ? $slf->{'_dom'}->{$nam}
    : $dft;
}

sub _load_attr
{ my ($slf) = @_;
  my ($ifh, $key, $tbl, $val);

  $ifh = IO::File->new;
  $slf->{'_dom'} = $tbl = {};
  if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'dom'}, 'init-info',
    'tokenValue.properties')))
  { while (<$ifh>)
    { if (m/^[^\043]*\b(\w+)=\s*(.*?)[\n\r\s]*$/)
      { $key = $1;
        $val = $2;
        $val =~ s/\\(.)/$1/g;
        $tbl->{$key} = $val;
      }
    }
    $ifh->close;
  }
}

=head2 S<$h-E<gt>get_env>

This method returns the environment variable specifications as a hash
reference.

=cut

sub get_env
{ my ($slf) = @_;

  # Determine the environment specifications on first usage
  unless (exists($slf->{'_env'}))
  { my ($dft, $dir, $dom, $env, $lib, %tbl);

    # Get the default specifications
    $dft = exists($slf->{'_hom'})
      ? $slf->{'_hom'}
      : $slf->get_default;
    $slf->{'_env'} = $env = {%{$dft->get_env}};

    # Add common target specifications
    $dom = $slf->{'dom'};
    $env->{'DOMAIN_HOME'} = RDA::Object::Rda->short($dom);
    $env->{'LONG_DOMAIN_HOME'} = RDA::Object::Rda->native($dom);
    $env->{'MW_ORA_HOME'} = $env->{'ORACLE_HOME'}
      if exists($env->{'ORACLE_HOME'});
    $slf->{'_wlh'}->adjust_env($env) if exists($slf->{'_wlh'});

    # Add operating system specific target specifications
    if (RDA::Object::Rda->is_unix)
    { # Adapt the command path
      %tbl = map {$_ => 1} split(/\:/, $env->{'PATH'});
      $env->{'PATH'} = join(':', $dir, $env->{'PATH'})
        if -d ($dir = RDA::Object::Rda->cat_dir($dom, 'bin'))
        && !exists($tbl{$dir});

      # Adapt the shared library path
      if (defined($lib = RDA::Object::Rda->get_shlib))
      { %tbl = map {$_ => 1} split(/\:/, $env->{$lib});
        $env->{$lib} = join(':', $dir, $env->{$lib})
          if -d ($dir = RDA::Object::Rda->cat_dir($dom, 'lib'))
          && !exists($tbl{$dir});
      }
    }
    elsif (RDA::Object::Rda->is_windows)
    { # Adapt the command path
      %tbl = map {$_ => 1} split(/\;/, $env->{'PATH'});
      $env->{'PATH'} = join(';', $dir, $env->{'PATH'})
        if -d ($dir = RDA::Object::Rda->cat_dir($dom, 'bin'))
        && !exists($tbl{$dir});
    }
    elsif (RDA::Object::Rda->is_cygwin)
    { # Adapt the command path
      $dom =~ s#^([A-Z]):#/cygdrive/\L$1#i;
      %tbl = map {$_ => 1} split(/\:/, $env->{'PATH'});
      $env->{'PATH'} = join(':', $dir, $env->{'PATH'})
        if -d ($dir = RDA::Object::Rda->cat_dir($dom, 'bin'))
        && !exists($tbl{$dir});
    }
  }

  # Return the environment specifications
  $slf->{'_env'};
}

=head2 S<$h-E<gt>get_product($name[,$key[,$default]])>

This method returns the product home target when defined. When an attribute
name is specified as an argument, it returns its value. When the attribute is
not found, it returns the default value.

=cut

sub get_product
{ my ($slf, $nam, $key, $dft) = @_;
  my ($prd);

  $prd = '-'.uc($nam);
  !exists($slf->{$prd})        ? $dft :
  !defined($key)               ? $slf->{$prd} :
  exists($slf->{$prd}->{$key}) ? $slf->{$prd}->{$key} :
                                 $dft;
}

=head2 S<$h-E<gt>get_server([$name[,$list]])>

This method returns the list of all identifiers associated to the specified
server name. By default, it returns all identifiers.

=cut

sub get_server
{ my ($slf, $nam, $src) = @_;
  my ($srv, $tbl, @dst, @src);

  $tbl = $slf->{'_srv'};

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
  { if (ref($srv = $tbl->{$uid}))
    { push(@dst, $uid) if exists($srv->{$nam});
    }
    else
    { push(@dst, $uid);
    }
  }
  @dst;
}

=head2 S<$h-E<gt>get_wlst([$flag])>

This method returns the list of the homes containing the WebLogic Server
Scripting Tool (WLST). When the flag is set, it stops the search at the first
matching home.

=cut

sub get_wlst
{ my ($slf, $flg) = @_;
  my ($fct, $seq, @dir, %dup);

  # Get the list of detected homes
  push(@dir, $slf->{'_cch'}->{'hom'}) if exists($slf->{'_cch'});
  push(@dir, $slf->{'_hom'}->{'hom'}) if exists($slf->{'_hom'});
  push(@dir,
    map {$slf->{'_det'}->{'hom'}->{$_}} @{_get_item($slf, 'seq', [])});
  push(@dir, $slf->{'_wlh'}->{'wlh'}) if exists($slf->{'_wlh'});

  # Return directories containing WLST
  $fct = (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
    ? \&_chk_wlst_w
    : \&_chk_wlst_u;
  return (grep {&$fct($_, \%dup)} @dir) unless $flg;
  foreach my $dir (@dir)
  { return ($dir) if &$fct($dir, \%dup);
  }
  ();
}

sub _chk_wlst_u
{ my ($dir, $dup) = @_;
  my ($fil);

  $fil = RDA::Object::Rda->cat_file($dir, 'common', 'bin', 'wlst.sh');
  return 0 if exists($dup->{$fil});
  $dup->{$fil} = -f $fil && -x $fil;
}

sub _chk_wlst_w
{ my ($dir, $dup) = @_;
  my ($fil);

  $fil = RDA::Object::Rda->cat_file($dir, 'common', 'bin', 'wlst.cmd');
  return 0 if exists($dup->{$fil});
  $dup->{$fil} = (-f $fil);
}

=head2 S<$h-E<gt>has_attr>

This method indicates how many domain attributes are available.

=cut

sub has_attr
{ my ($slf) = @_;

  # Load all attributes on first usage
  _load_attr($slf) unless exists($slf->{'_dom'});

  # Indicate how many attributes are available
  scalar keys(%{$slf->{'_dom'}});
}

=head2 S<$h-E<gt>set_product([$name])>

This method selects a product home target as Oracle home target. The argument
can be the product name or a hash reference indicating the preferences.

The hash associates a value to product names. The method selects the product
that is present and that has the highest value.

By default, it selects the first product.

It returns the previous Oracle home target or un andefined value when not
defined.

=cut

sub set_product
{ my ($slf, $nam) = @_;
  my ($key, $old, $ref);

  $old = $slf->{'_hom'} if exists($slf->{'_hom'});
  $ref = ref($nam);
  if ($ref =~ m/^RDA::Object::/)
  { $slf->{'_hom'} = $nam;
  }
  elsif ($ref eq 'HASH')
  { foreach my $itm (sort {$nam->{$b} <=> $nam->{$a}} keys(%$nam))
    { if (exists($slf->{$key = '-'.uc($itm)}))
      { delete($slf->{'_env'});
        $slf->{'_hom'} = $slf->{$key};
        last;
      }
    }
  }
  elsif (defined($nam))
  { if (exists($slf->{$key = '-'.uc($nam)}))
    { delete($slf->{'_env'});
      $slf->{'_hom'} = $slf->{$key};
    }
  }
  elsif (exists($slf->{$key = '-'._get_item($slf, 'seq', [''])->[0]}))
  { delete($slf->{'_env'});
    $slf->{'_hom'} = $slf->{$key};
  }
  elsif ($old)
  { delete($slf->{'_env'});
    delete($slf->{'_hom'});
  }
  $old;
}

=head2 S<$h-E<gt>set_server($name[,$list])>

This method associates a pipe-separated list of server names to the specified
identifier. It discards empty server names. When the list is undefined, the
C<get_server> method will select the identifier for any server.

It returns the number of server names associated to the identifier.

=cut

sub set_server
{ my ($slf, $uid, $str) = @_;
  my ($cnt, $tbl, @tbl);

  # Validate the argument
  die "RDA-01381: Missing or invalid identifier\n"
    unless defined($uid) && $uid =~ m/^\w+$/;

  # Associate servers to the identifier
  return $slf->{'_srv'}->{$uid} = undef unless defined($str);

  $cnt = 0;
  $slf->{'_srv'}->{$uid} = $tbl = {};
  foreach my $nam (split(/\|/, $str))
  { $tbl->{$nam} = ++$cnt if length($nam);
  }
  $cnt;
}

# --- Internal routines -------------------------------------------------------

# Find the Common Components home directory
sub _find_common
{ my ($slf, $def) = @_;

  (exists($def->{'COMMON_HOME'}) && defined($def->{'COMMON_HOME'}))
    ? RDA::Object::Rda->cat_dir($def->{'COMMON_HOME'})
    : _get_item($slf, 'com');
}

# Find the Oracle home directory
sub _find_home
{ my ($slf, $def) = @_;

  (exists($def->{'ORACLE_HOME'}) && defined($def->{'ORACLE_HOME'}))
    ? RDA::Object::Rda->cat_dir($def->{'ORACLE_HOME'})
    : _get_item($slf, 'ora');
}

# Find the Oracle Middleware home directory
sub _find_mw_home
{ my ($slf, $def) = @_;
  my ($dir);

  # Check the definition
  return RDA::Object::Rda->cat_dir($def->{'MW_HOME'})
    if exists($def->{'MW_HOME'}) && defined($def->{'MW_HOME'});

  # Try to detect the Oracle Middleware home directory
  ($def->{'NO_DETECT'}) || !defined($dir = $slf->get_attr('BEA_HOME'))
    ? undef
    : RDA::Object::Rda->cat_dir($dir);
}

# Find the Oracle WebLogic Server home directory
sub _find_wl_home
{ my ($slf, $def) = @_;

  # Check the definition
  (exists($def->{'WL_HOME'}) && defined($def->{'WL_HOME'}))
    ? RDA::Object::Rda->cat_dir($def->{'WL_HOME'})
    : _get_item($slf, 'wlh');
}

# Detect the domain-associated homes
sub _get_homes
{ my ($slf) = @_;
  my ($det, $key, $ifh);

  # Return the detection result whan already available
  return $slf->{'_det'} if exists($slf->{'_det'});

  # Detect the associated home directories on first use
  $slf->{'_det'} = $det = {};
  unless ($slf->{'_def'}->{'NO_DETECT'})
  { $ifh = IO::File->new;
    if (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
    { if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'dom'}, 'bin',
        'setDomainEnv.cmd')))
      { while (<$ifh>)
        { if (m/^\s*set\s+(\w+)_ORACLE_HOME=(.*?)\s*$/)
          { push(@{$det->{'seq'}}, $key)
              unless exists($det->{'hom'}->{$key = uc($1)});
            $det->{'hom'}->{$key} = RDA::Object::Rda->cat_dir($2);
          }
          elsif (m/^\s*set\s+COMMON_COMPONENTS_HOME=(.*?)\s*$/)
          { $det->{'com'} = RDA::Object::Rda->cat_dir($1);
          }
          elsif (m/^\s*set\s+(MW_ORA|ORACLE)_HOME=(.*?)\s*$/)
          { $det->{'ora'} = RDA::Object::Rda->cat_dir($2);
          }
          elsif (m/^\s*set\s+WL_HOME=(.*?)\s*$/)
          { $det->{'wlh'} = RDA::Object::Rda->cat_dir($1);
          }
          elsif (m/^\s*set\s+JAVA_HOME=$/)
          { last;
          }
        }
        $ifh->close;
      }
    }
    else
    { if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'dom'}, 'bin',
        'setDomainEnv.sh')))
      { while (<$ifh>)
        { if (m/^[^\043]*\b(\w+)_ORACLE_HOME=([\042\047])(.*?)\2\s*$/)
          { push(@{$det->{'seq'}}, $key)
              unless exists($det->{'hom'}->{$key = uc($1)});
            $det->{'hom'}->{$key} = $3;
          }
          elsif (m/^[^\043]*\b(\w+)_ORACLE_HOME=(\S+)/)
          { push(@{$det->{'seq'}}, $key)
              unless exists($det->{'hom'}->{$key = uc($1)});
            $det->{'hom'}->{$key} = $2;
          }
          elsif (m/^[^\043]*\bCOMMON_COMPONENTS_HOME=([\042\047])(.*?)\1\s*$/)
          { $det->{'com'} = $2;
          }
          elsif (m/^[^\043]*\bCOMMON_COMPONENTS_HOME=(\S+)/)
          { $det->{'com'} = $1;
          }
          elsif (m/^[^\043]*\b(MW_ORA|ORACLE)_HOME=([\042\047])(.*?)\2\s*$/)
          { $det->{'ora'} = $3;
          }
          elsif (m/^[^\043]*\b(MW_ORA|ORACLE)_HOME=(\S+)/)
          { $det->{'ora'} = $2;
          }
          elsif (m/^[^\043]*\bWL_HOME=([\042\047])(.*?)\1\s*$/)
          { $det->{'wlh'} = $2;
          }
          elsif (m/^[^\043]*\bWL_HOME=(\S+)/)
          { $det->{'wlh'} = $1;
          }
          elsif (m/^[^\043]*\bJAVA_HOME=/)
          { last;
          }
        }
        $ifh->close;
      }
    }
  }
  $det;
}
  
# Get a detected item
sub _get_item
{ my ($slf, $key, $dft) = @_;
  my ($det);

  $det = _get_homes($slf);
  exists($det->{$key}) ? $det->{$key} : $dft;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Home|RDA::Object::Home>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Target|RDA::Object::Target>,
L<RDA::Object::WlHome|RDA::Object::WlHome>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
