# Instance.pm: Class Used for Managing Oracle Instances

package RDA::Object::Instance;

# $Id: Instance.pm,v 1.13 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Instance.pm,v 1.13 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Instance - Class Used for Managing Oracle Instances

=head1 SYNOPSIS

require RDA::Object::Instance;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Instance> class are used to interface with
Oracle instances. It is a sub class of
L<RDA::Object::Target|RDA::Object::Target>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object;
  use RDA::Object::Rda;
  use RDA::Object::Target;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);
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
  dep => [qw(RDA::Object::Home)],
  inc => [qw(RDA::Object::Target RDA::Object)],
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Instance-E<gt>new($oid,$agt,$def[,$par[,...]])>

The object constructor. It takes the object identifier, the agent reference,
the definition hash reference, the parent target reference, and initial
attributes as arguments.

Do not use this constructor directly. Create all targets using the
L<RDA::Object::Target|RDA::Object::Target> methods.

C<RDA::Object::Instance> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'bas' > > Oracle base directory

=item S<    B<'ins' > > Instance home directory

=item S<    B<'oid' > > Object identifier

=item S<    B<'par' > > Reference to the parent target

=item S<    B<'tns' > > TNS_ADMIN specification

=item S<    B<'_abr'> > Symbol definition hash

=item S<    B<'_bkp'> > Backup of environment variables

=item S<    B<'_chl'> > List of the child keys

=item S<    B<'_def'> > Target definition

=item S<    B<'_env'> > Environment specifications

=item S<    B<'_fcs'> > Focus hash

=item S<    B<'_prs'> > Symbol detection parse tree

=item S<    B<'_shr'> > Share indicator

=item S<    B<'_typ'> > Target type

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $oid, $agt, $def, $par, @arg) = @_;
  my ($flg, $key, $slf, $tgt, $val);

  # Create the Oracle instance object
  $slf = bless {
    agt  => $agt,
    oid  => $par->get_unique($oid),
    par  => $par,
    _chl => [],
    _def => $def,
    _fcs => {},
    _shr => $def->{'DEDICATED_INSTANCE'} ? 0 : 1,
    _typ => 'OI',
  }, ref($cls) || $cls;

  # Load the target definition
  $slf->{'bas'} = RDA::Object::Rda->cat_dir($def->{'ORACLE_BASE'})
    if exists($def->{'ORACLE_BASE'}) && defined($def->{'ORACLE_BASE'});
  $slf->{'ins'} = RDA::Object::Rda->cat_dir($def->{'ORACLE_INSTANCE'})
    if exists($def->{'ORACLE_INSTANCE'}) && defined($def->{'ORACLE_INSTANCE'});
  $slf->{'tns'} = defined($def->{'TNS_ADMIN'})
    ? RDA::Object::Rda->cat_dir($def->{'TNS_ADMIN'})
    :undef
    if exists($def->{'TNS_ADMIN'});

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $slf->{$key} = $val if defined($val);
  }

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
    { $oid =~ s/^OI_/OH_/i;
      $tgt = ($flg = $def->{'DEDICATED_HOME'})
        ? undef
        : $par->find_target('OH', hom => $val);
      $slf->{'_hom'} = $tgt
        || $slf->add_target($oid, {OH_ABBR        => $def->{'OH_ABBR'},
                                   ORACLE_HOME    => $val,
                                   DEDICATED_HOME => $flg,
                                  });
      push(@{$slf->{'_chl'}}, '_hom');
    }
  }

  # Initiate the symbol management when applicable
  unless (RDA::Object::Rda->is_vms)
  { $slf->{'_abr'} = {};
    $slf->set_symbol($def->{'OB_ABBR'} || '$OB', $slf->{'bas'})
      if exists($slf->{'bas'});
    $slf->set_symbol($def->{'OI_ABBR'} || '$OI', $slf->{'ins'})
      if exists($slf->{'ins'});
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
  { my ($dft, $dir, $env, $ins, $lib, %tbl);

    # Get the default specifications
    $dft = exists($slf->{'_hom'})
      ? $slf->{'_hom'}
      : $slf->get_default;
    $slf->{'_env'} = $env = {%{$dft->get_env}};

    # Add the target specifications
    if (exists($slf->{'ins'}))
    { if (RDA::Object::Rda->is_unix)
      { # Align the environment and the settings
        $env->{'ORACLE_INSTANCE'} = $ins = $slf->{'ins'};
        $env->{'TNS_ADMIN'} = $slf->{'tns'}
          if exists($slf->{'tns'});

        # Adapt the command path
        %tbl = map {$_ => 1} split(/\:/, $env->{'PATH'});
        $env->{'PATH'} = join(':', $dir, $env->{'PATH'})
          if -d ($dir = RDA::Object::Rda->cat_dir($ins, 'bin'))
          && !exists($tbl{$dir});

        # Adapt the shared library path
        if (defined($lib = RDA::Object::Rda->get_shlib))
        { %tbl = map {$_ => 1} split(/\:/, $env->{$lib});
          $slf->{'_env'}->{$lib} = join(':', $dir, $env->{$lib})
            if -d ($dir = RDA::Object::Rda->cat_dir($ins, 'lib'))
            && !exists($tbl{$dir});
        }
      }
      elsif (RDA::Object::Rda->is_windows)
      { # Align the environment and the settings
        $env->{'ORACLE_INSTANCE'} =
          RDA::Object::Rda->native($ins = $slf->{'ins'});
        $env->{'TNS_ADMIN'} = defined($slf->{'tns'})
          ? RDA::Object::Rda->native($slf->{'tns'})
          : undef
          if exists($slf->{'tns'});

        # Adapt the command path
        %tbl = map {$_ => 1} split(/\;/, $env->{'PATH'});
        $env->{'PATH'} = join(';', $dir, $env->{'PATH'})
          if -d ($dir = RDA::Object::Rda->cat_dir($ins, 'bin'))
          && !exists($tbl{$dir});
      }
      elsif (RDA::Object::Rda->is_cygwin)
      { # Align the environment and the settings
        $env->{'ORACLE_INSTANCE'} =
          RDA::Object::Rda->native($ins = $slf->{'ins'});
        $env->{'TNS_ADMIN'} = defined($slf->{'tns'})
          ? RDA::Object::Rda->native($slf->{'tns'})
          : undef
          if exists($slf->{'tns'});

        # Adapt the command path
        $ins =~ s#^([A-Z]):#/cygdrive/\L$1#i;
        %tbl = map {$_ => 1} split(/\:/, $env->{'PATH'});
        $env->{'PATH'} = join(':', $dir, $env->{'PATH'})
          if -d ($dir = RDA::Object::Rda->cat_dir($ins, 'bin'))
          && !exists($tbl{$dir});
      }
    }
  }

  # Return the environment specifications
  $slf->{'_env'};
}

# --- Internal routines -------------------------------------------------------

# Find the Oracle home directory
sub _find_home
{ my ($slf, $def) = @_;
  my ($dir, $ifh);

  # Check the definition
  return RDA::Object::Rda->cat_dir($def->{'ORACLE_HOME'})
    if exists($def->{'ORACLE_HOME'}) && defined($def->{'ORACLE_HOME'});

  # Try to detect the Oracle home directory
  unless ($def->{'NO_DETECT'})
  { $ifh = IO::File->new;
    if (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
    { if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'ins'}, 'bin',
        'opmnctl.bat')))
      { while (<$ifh>)
        { if (m/^\s*set\s+ORACLE_HOME=(.*?)[\n\r\s]*$/)
          { $dir = RDA::Object::Rda->cat_dir($1) if length($1);
            last;
          }
        }
        $ifh->close;
      }
    }
    else
    { if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'ins'}, 'bin',
        'opmnctl')))
      { while (<$ifh>)
        { if (m/^\s*\$OracleHome\s*=([\042\047])(.*?)\1/)
          { $dir = RDA::Object::Rda->cat_dir($2) if length($2);
            last;
          }
        }
        $ifh->close;
      }
    }
  }
  $dir;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Home|RDA::Object::Home>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Target|RDA::Object::Target>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
