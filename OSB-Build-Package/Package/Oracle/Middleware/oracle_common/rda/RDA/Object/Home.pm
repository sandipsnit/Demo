# Home.pm: Class Used for Managing Oracle and Common Homes

package RDA::Object::Home;

# $Id: Home.pm,v 1.19 2012/05/22 15:56:09 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Home.pm,v 1.19 2012/05/22 15:56:09 mschenke Exp $
#
# Change History
# 20120522  MSC  Store the initial Oracle home.

=head1 NAME

RDA::Object::Home - Class Used for Managing Oracle and Common Homes

=head1 SYNOPSIS

require RDA::Object::Home;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Home> class are used to manage Oracle and
common homes and the auto discovery aspects. It is a sub class of
L<RDA::Object::System|RDA::Object::System>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Rda;
  use RDA::Object::System;
  use RDA::Object::Target;
  use RDA::Object::Xml;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  hsh => {'RDA::Object::Domain'   => 1,
          'RDA::Object::Home'     => 1,
          'RDA::Object::Instance' => 1,
          'RDA::Object::System'   => 1,
          'RDA::Object::Target'   => 1,
          'RDA::Object::WlHome'   => 1,
         },
  );
@ISA     = qw(RDA::Object::System RDA::Object::Target RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object::Target RDA::Object)],
  met => {
    'find'          => {ret => 0},
    'get_location'  => {ret => 0},
    'get_product'   => {ret => 0},
    'get_version'   => {ret => 0},
    'has_inventory' => {ret => 0},
    },
  );

# Define the global private constants

# Define the global private variables
my %tb_inv = (
  LOCATION => 'INST_LOC',
  VERSION  => 'VER',
  );
my %tb_lib = (
  aix    => 'LIBPATH',
  darwin => 'DYLD_LIBRARY_PATH',
  hpux   => 'SHLIB_PATH',
  unix   => 'LD_LIBRARY_PATH',
  );
my %tb_ocm = (
  LOCATION => 'INSTALLED_LOCATION',
  VERSION  => 'VERSION',
  );
my %tb_typ = (
  LOCATION => 'D',
  VERSION  => 'V',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Home-E<gt>new($oid,$agt,$def[,$par[,...]])>

The object constructor. This method takes the object identifier, the agent
reference, the definition hash reference, the parent target reference, and
initial attributes as arguments.

Do not use this constructor directly. Create all targets using the
L<RDA::Object::Target|RDA::Object::Target> methods.

C<RDA::Object::Home> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'cfg' > > Reference to the RDA software configuration

=item S<    B<'hom' > > Oracle home directory

=item S<    B<'ini' > > Initial Oracle home directory

=item S<    B<'jdk' > > JDK directory

=item S<    B<'oid' > > Object identifier

=item S<    B<'par' > > Reference to the parent target

=item S<    B<'tns' > > TNS_ADMIN specification

=item S<    B<'_abr'> > Symbol definition hash

=item S<    B<'_bkp'> > Backup of environment variables

=item S<    B<'_chl'> > List of the child keys

=item S<    B<'_def'> > Target definition

=item S<    B<'_env'> > Environment specifications

=item S<    B<'_fcs'> > Focus hash

=item S<    B<'_inv'> > Inventory object

=item S<    B<'_prd'> > OCM product list

=item S<    B<'_prs'> > Symbol detection parse tree

=item S<    B<'_shr'> > Share indicator

=item S<    B<'_sql'> > SQL*Plus specifications

=item S<    B<'_src'> > Inventory source

=item S<    B<'_typ'> > Target type

=back

Internal keys are prefixed by an underscore. Defined inventory sources are:

=over 12

=item S<    B<'INV'> > Oracle home inventory

=item S<    B<'OCM'> > OCM configuration information

=back

An empty string indicates that no inventory has been found.

=cut

sub new
{ my ($cls, $oid, $agt, $def, $par, @arg) = @_;
  my ($alt, $key, $slf, $typ, $val);

  # Validate the target type
  die "RDA-01361: Invalid object identifier '$oid'\n"
    unless $oid =~ m/^([CO]H)_[A-Z]\w*(\$\$)?$/i;
  $typ = uc($1);

  # Create the Oracle home object
  $slf = bless {
    agt  => $agt,
    cfg  => $agt->get_config,
    oid  => $par->get_unique($oid),
    par  => $par,
    _chl => [],
    _def => $def,
    _fcs => {},
    _shr => ($def->{'DEDICATED_HOME'} ||
             $def->{'DEDICATED_COMMON'}) ? 0 : 1,
    _typ => $typ,
  }, ref($cls) || $cls;

  # Load the target definition
  if (exists($def->{'ORACLE_HOME'}) && defined($def->{'ORACLE_HOME'}))
  { $slf->{'hom'} = RDA::Object::Rda->cat_dir($alt = $def->{'ORACLE_HOME'});
    $slf->{'ini'} = $alt if $alt ne $slf->{'hom'};
  }
  $slf->{'tns'} = defined($def->{'TNS_ADMIN'})
    ? RDA::Object::Rda->cat_dir($def->{'TNS_ADMIN'})
    :undef
    if exists($def->{'TNS_ADMIN'});

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $slf->{$key} = $val if defined($val);
  }

  # Validate the configuration
  die "RDA-01360: Missing Oracle home directory in $oid target\n"
    unless exists($slf->{'hom'});

  # Detect the presence of a JDK
  $slf->{'jdk'} = $val
    if -d ($val = RDA::Object::Rda->cat_dir($slf->{'hom'}, 'jdk'));

  # Initiate the symbol management when applicable
  unless (RDA::Object::Rda->is_vms)
  { $slf->{'_abr'} = {};
    $slf->set_symbol($def->{'OH_ABBR'} || '$OH', $slf->{'hom'});
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>get_env>

This method returns the environment variable specifications as a hash
reference.

=cut

sub get_env
{ my ($slf) = @_;

  # Determine the environment specifications on first usage
  unless (exists($slf->{'_env'}))
  { if (RDA::Object::Rda->is_unix)
    { my ($dir, $env, $flg, $lib, $old, $ora, $val, @tbl, %tbl);

      $slf->{'_env'} = $env = {};

      # Align the environment and the settings
      $env->{'INITIAL_HOME'} = $slf->{'ini'} if exists($slf->{'ini'});
      $env->{'ORACLE_HOME'}  = $ora = $slf->{'hom'};
      $env->{'TNS_ADMIN'}    = $slf->{'tns'} if exists($slf->{'tns'});

      # Check when corrections are applicable
      if (defined($old = $slf->get_init('ORACLE_HOME')))
      { $old = RDA::Object::Rda->cat_dir($old);
        $flg = $old ne $ora;
      }

      # Adapt the command path
      if (defined($val = $slf->get_init('PATH')))
      { if ($flg)
        { foreach my $dir (split(/\:/, $val))
          { $dir =~ s#^\Q$old\E/#$ora/#;
            push(@tbl, $dir);
          }
        }
        else
        { @tbl = split(/\:/, $val);
        }
        %tbl = map {$_ => 1} @tbl;
      }
      unshift(@tbl, $dir)
        if $ora && -d ($dir = "$ora/bin")     && !exists($tbl{$dir});
      unshift(@tbl, $dir)
        if $ora && -d ($dir = "$ora/jdk/bin") && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/usr/sbin")    && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/usr/bin")     && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/etc")         && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/usr/ccs/bin") && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/sbin")        && !exists($tbl{$dir});
      $env->{'PATH'} = join(":", @tbl);

      # Adapt the shared library path
      if (defined($lib = RDA::Object::Rda->get_shlib))
      { my (@tbl, %tbl);

        if (defined($val = $slf->get_init($lib)))
        { if ($flg)
          { foreach my $dir (split(/\:/, $val))
            { $dir =~ s#^\Q$old\E/#$ora/#;
              push(@tbl, $dir);
            }
          }
          else
          { @tbl = split(/\:/, $val);
          }
          %tbl = map {$_ => 1} @tbl;
        }
        unshift(@tbl, $dir)
          if $ora && -d ($dir = "$ora/lib") && !exists($tbl{$dir});
        push(@tbl, $dir) if -d ($dir = "/lib")           && !exists($tbl{$dir});
        push(@tbl, $dir) if -d ($dir = "/usr/lib")       && !exists($tbl{$dir});
        push(@tbl, $dir) if -d ($dir = "/usr/local/lib") && !exists($tbl{$dir});
        $env->{$lib} = join(':', @tbl);
      }
    }
    elsif (RDA::Object::Rda->is_windows)
    { my ($dir, $env, $flg, $old, $ora, $val, @tbl, %tbl);

      $slf->{'_env'} = $env = {};

      # Align the environment and the settings
      $env->{'ORACLE_HOME'} =
        RDA::Object::Rda->native($ora = $slf->{'hom'});
      $env->{'TNS_ADMIN'} = defined($slf->{'tns'})
        ? RDA::Object::Rda->native($slf->{'tns'})
        : undef
        if exists($slf->{'tns'});

      # Check when corrections are applicable
      if (defined($old = $slf->get_init('ORACLE_HOME')))
      { $old = RDA::Object::Rda->cat_dir($old);
        $flg = lc($ora) ne lc($old);
      }

      # Adapt the command path
      if (defined($val = $slf->get_init('PATH')))
      { if ($old && $old ne $ora)
        { foreach my $dir (split(/;/, $val))
          { $dir = RDA::Object::Rda->cat_dir($dir);
            $dir =~ s#^\Q$old\E/#$ora/#i;
            $dir =~ s#^\Q$old\E\\#$ora\\#i;
            push(@tbl, $dir);
          }
        }
        else
        { @tbl = split(/;/, $val);
        }
        %tbl = map {$_ => 1} @tbl;
      }
      unshift(@tbl, $dir)
        if -d ($dir = RDA::Object::Rda->cat_dir($ora, 'bin'))
        && !exists($tbl{$dir});
      unshift(@tbl, $dir)
        if -d ($dir = RDA::Object::Rda->cat_dir($ora, 'jdk', 'bin'))
        && !exists($tbl{$dir});
      $env->{'PATH'} = join(';', @tbl);
    }
    elsif (RDA::Object::Rda->is_cygwin)
    { my ($alt, $dir, $env, $flg, $old, $ora, $pre, $val, @tbl, %tbl);

      $slf->{'_env'} = $env = {};

      # Align the environment and the settings
      $env->{'ORACLE_HOME'} =
        RDA::Object::Rda->native($ora = $slf->{'hom'});
      $env->{'TNS_ADMIN'} = defined($slf->{'tns'})
        ? RDA::Object::Rda->native($slf->{'tns'})
        : undef
        if exists($slf->{'tns'});

      # Check when corrections are applicable
      $ora =~ s#^([A-Z]):#/cygdrive/\L$1#i;
      if (defined($old = $slf->get_init('ORACLE_HOME')))
      { $alt = $old = RDA::Object::Rda->cat_dir($old);
        $alt =~ s#^([A-Z]):#/cygdrive/\L$1#i;
        $flg = lc($ora) ne lc($alt);
      }

      # Adapt the command path
      if (defined($val = $slf->get_init('PATH')))
      { $pre = '';
        foreach my $dir (split(/\:/, $val))
        { if ($dir =~ m/^[A-Z]$/i)
          { $pre = "$dir:";
          }
          else
          { $dir = RDA::Object::Rda->cat_dir($pre.$dir);
            $dir =~ s#^([A-Z]):#/cygdrive/\L$1#i;
            if ($flg)
            { $dir =~ s#^\Q$old\E/#$ora/#i;
              $dir =~ s#^\Q$alt\E/#$ora/#i;
            }
            push(@tbl, $dir);
            $pre = '';
          }
        }
        %tbl = map {$_ => 1} @tbl;
      }
      unshift(@tbl, $dir)
        if -d ($dir = RDA::Object::Rda->cat_dir($ora, 'bin'))
        && !exists($tbl{$dir});
      unshift(@tbl, $dir)
        if -d ($dir = RDA::Object::Rda->cat_dir($ora, 'jdk', 'bin'))
        && !exists($tbl{$dir});
      $env->{'PATH'} = join(':', @tbl);
    }
    else
    { $slf->{'_env'} = {};
    }
  }

  # Return the environment specifications
  $slf->{'_env'};
}

=head2 S<$h-E<gt>get_sqlplus>

This method returns a list containing the command and the associated
environment specifications.

=cut

sub get_sqlplus
{ my ($slf) = @_;

  # Determine how to execute SQL*Plus on first call
  unless (exists($slf->{'_sql'}))
  { my ($cmd, $hom);

    $hom = $slf->{'hom'};
    if (RDA::Object::Rda->is_unix)
    { $slf->{'_sql'} =
        (-f ($cmd = RDA::Object::Rda->cat_file($hom, 'bin', 'sqlplus')))
        ? {cmd => $cmd, env => {}}
        : $slf->get_top('_sql');
    }
    elsif (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
    { $slf->{'_sql'} =
        (-f ($cmd = RDA::Object::Rda->cat_file($hom, 'bin', 'PLUS80.exe')) ||
         -f ($cmd = RDA::Object::Rda->cat_file($hom, 'bin', 'sqlplus.exe')))
        ? {cmd => $cmd, env => {}}
        : $slf->get_top('_sql');
    }
    else
    { $slf->{'_sql'} = $slf->get_top('_sql');
    }
  }

  ($slf->{'_sql'}->{'cmd'}, $slf->{'_sql'}->{'env'});
}

=head2 S<$h-E<gt>init_inventory>

This method initializes the inventory search.

=cut

sub init_inventory
{ my ($slf) = @_;
  my ($fil, $obj);

  # Examine the Oracle home inventory
  unless ($slf->{'agt'}->get_setting('NO_INVENTORY'))
  { if (-r ($fil = RDA::Object::Rda->cat_file($slf->{'hom'}, 'inventory',
      'ContentsXML', 'comps.xml')))
    { $slf->{'_inv'} =
        RDA::Object::Xml->new->parse_file($fil);
      $slf->{'_src'} = 'INV';
      return $slf;
    }
  }

  # Examine the OCM configuration informantion
  unless ($slf->{'agt'}->get_setting('NO_OCM'))
  { if (-r ($fil = _get_ocm_inv($slf->{'cfg'}, $slf->{'hom'})))
    { $slf->{'_inv'} = $obj =
        RDA::Object::Xml->new->parse_file($fil);
      $slf->{'_prd'} =
        [$obj->find(".../ROWSET TABLE='MGMT_LL_INV_COMPONENT'/ROW")];
      $slf->{'_src'} = 'OCM';
      return $slf;
    }
  }

  # Indicate the initialization completion
  $slf->{'_src'} = '';

  # Return the object reference
  $slf;
}

sub _get_ocm_inv
{ my ($cfg, $dir) = @_;
  my ($nam, $pth);

  foreach my $sub ($cfg->cat_dir($dir, 'ccr'),
                   $cfg->cat_dir($dir, 'livelink'),
                   $cfg->cat_dir($dir, $cfg->up_dir, 'utils', 'ccr'))
  { next unless -d $sub;

    # Find the CONFIG_HOME
    if (-d $cfg->cat_dir($sub, 'hosts'))
    { if (exists($ENV{'ORACLE_CONFIG_HOME'}))
      { $sub = $cfg->cat_dir($ENV{'ORACLE_CONFIG_HOME'}, 'ccr')
      }
      elsif (-d ($pth = $cfg->cat_dir($sub, 'hosts', $cfg->get_host)) ||
             -d ($pth = $cfg->cat_dir($sub, 'hosts', $cfg->get_node)))
      { $sub = $pth
      }
      else
      { next;
      }
    }

    # Check the presence of the Oracle home target
    if (-d ($pth = $cfg->cat_dir($sub, 'state', 'review')))
    { if (opendir(DIR, $pth))
      { ($nam) = grep {/-oracle_home_config\.xml$/i} readdir(DIR);
        closedir(DIR);
        return $pth
          if $nam && -r ($pth = $cfg->cat_file($pth, $nam));
      }
      last;
    }
  }
  '';
}

=head1 AUTO DISCOVERY METHODS

=head2 S<$h-E<gt>check($name,$prod)>

This method determines if the product is installed. When the product is found
in the inventory, it sets the temporary settings C<E<lt>nameE<gt>_VERSION> and
C<E<lt>nameE<gt>_LOCATION> and returns a true value. Otherwise, it returns an
undefined value.

=cut

sub check
{ my ($slf, $cfg, $nam, $prd) = @_;
  my ($res);

  # Validate the parameters
  return undef
    unless ref($cfg) && $nam =~ m/^\w+$/ && $prd =~ m/^\w+(\.\w+)*$/;

  # Initialize it on the first call
  $slf->init_inventory unless exists($slf->{'_src'});

  # Check the product information
  if ($slf->{'_src'} eq 'INV')
  { $prd =~ s/\./\\\./g;
    $res = _get_first($slf->{'_inv'},"PRD_LIST/COMP_LIST/PATCH NAME='^$prd\$'")
      || _get_first($slf->{'_inv'},"PRD_LIST/COMP_LIST/COMP NAME='^$prd\$'");
    if ($res)
    { foreach my $key (keys(%tb_inv))
      { $cfg->set_temp($tb_typ{$key}.'_'.$nam.'_'.$key, $res->{$tb_inv{$key}})
          if exists($res->{$tb_inv{$key}});
      }
      return 1;
    }
  }
  elsif ($slf->{'_src'} eq 'OCM')
  { foreach my $obj (@{$slf->{'_prd'}})
    { if (_get_text($obj, 'NAME', '') eq $prd)
      { foreach my $key (keys(%tb_ocm))
        { $cfg->set_temp($tb_typ{$key}.'_'.$nam.'_'.$key, $res)
            if defined($res = _get_text($obj, $tb_ocm{$key}));
        }
        return 1;
      }
    }
  }
  undef;
}

=head2 S<$h-E<gt>find($attr,$prod[,$dft])>

This method finds the specified attribute for a given product and returns its
value. It returns the default value when the product or the attribute is not
found.

=cut

sub find
{ my ($slf, $key, $prd, $val) = @_;
  my $res;

  # Initialize it on the first call
  $slf->init_inventory unless exists($slf->{'_src'});

  # Validate the parameters
  $key = uc($key);
  return undef unless exists($tb_inv{$key}) && $prd =~ m/^\w+(\.\w+)*$/;

  # Find the attribute
  if ($slf->{'_src'} eq 'INV')
  { $key = $tb_inv{$key};
    $prd =~ s/\./\\\./g;
    $res = _get_first($slf->{'_inv'}, "PRD_LIST/COMP_LIST/PATCH NAME='^$prd\$'")
      || _get_first($slf->{'_inv'}, "PRD_LIST/COMP_LIST/COMP NAME='^$prd\$'");
    $val = $res->{$key} if $res && exists($res->{$key});
  }
  elsif ($slf->{'_src'} eq 'OCM')
  { foreach my $obj (@{$slf->{'_prd'}})
    { if (_get_text($obj, 'NAME', '') eq $prd)
      { $val = _get_text($obj, $tb_ocm{$key});
        last;
      }
    }
  }
  $val;
}

# Get the first element from a query result
sub _get_first
{ my ($xml, $qry, $nod) = @_;

  ($nod) = $xml->find($qry);
  $nod;
}

# Get the text of a specific XML element
sub _get_text
{ my ($xml, $tag, $dft) = @_;
  my $nod;

  ($nod = _get_first($xml, $tag)) ? $nod->get_data : $dft;
}

=head2 S<$h-E<gt>get_location($name[,$dft])>

This macro returns the location of the specified component. It returns the
default value when the specified component is not found in the inventory.

=cut

sub get_location
{ my ($slf, $nam, $dft) = @_;

  $slf->find('LOCATION', $nam, $dft);
}

=head2 S<$h-E<gt>get_product([$dft])>

This macro returns the extended name of the product or the default value when
the extended name is not available.

=cut

sub get_product
{ my ($slf, $dft) = @_;

  # Initialize it on the first call
  $slf->init_inventory unless exists($slf->{'_src'});

  # Get the extended name of the product
  if ($slf->{'_src'} eq 'INV')
  { my ($xml) = $slf->{'_inv'}->find('PRD_LIST/TL_LIST/COMP/EXT_NAME');
    return $xml->get_data if $xml;
  }
  $dft;
}

=head2 S<$h-E<gt>get_version>

This macro returns the version of the product. It returns an undefined value
when there is no inventory information for the product.

=head2 S<$h-E<gt>get_version($name[,$dft])>

This macro returns the version of the specified component. It returns the
default value when there is no inventory information for the specified
component.

=cut

sub get_version
{ my ($slf, $nam, $dft) = @_;

  # Identify a component version
  return $slf->find('VERSION', $nam, $dft) if defined($nam);

  # Initialize it on the first call
  $slf->init_inventory unless exists($slf->{'_src'});

  # Identify a product version
  if ($slf->{'_src'} eq 'INV')
  { my ($xml) = $slf->{'_inv'}->find('PRD_LIST/TL_LIST/COMP');
    return $xml->get_value('VER', $dft) if $xml;
  }
  $dft;
}

=head2 S<$h-E<gt>has_inventory>

This method indicates the type of the inventory used for the auto discovery. It
returns an empty string when no inventory is available.

=cut

sub has_inventory
{ my ($slf) = @_;

  # Initialize it on the first call
  $slf->init_inventory unless exists($slf->{'_src'});

  # Return the inventory source
  $slf->{'_src'};
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Instance|RDA::Object::Instance>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::System|RDA::Object::System>,
L<RDA::Object::Target|RDA::Object::Target>,
L<RDA::Object::Xml|RDA::Object::Xml>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
