# WlHome.pm: Class Used to Interface the Oracle WebLogic Server Homes

package RDA::Object::WlHome;

# $Id: WlHome.pm,v 1.9 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/WlHome.pm,v 1.9 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::WlHome - Class Used to Interface the Oracle WebLogic Server Homes

=head1 SYNOPSIS

require RDA::Object::WlHome;

=head1 DESCRIPTION

The objects of the C<RDA::Object::WlHome> class are used to interface with the
Oracle WebLogic Server homes. It is a sub class of
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
$VERSION = sprintf('%d.%02d', q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);
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
  inc => [qw(RDA::Object::Target RDA::Object)],
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::WlHome-E<gt>new($oid,$agt,$def[,$par[,...]])>

The object constructor. This method takes the object identifier, the agent
reference, the definition hash reference, the parent target, and initial
attributes as arguments.

Do not use this constructor directly. Create all targets using
L<RDA::Object::Target|RDA::Object::Target> methods.

C<RDA::Object::WlHome> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'oid' > > Object identifier

=item S<    B<'mwh' > > Middleware home directory

=item S<    B<'par' > > Reference to the parent target

=item S<    B<'wlh' > > Oracle WebLogic Server home directory

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
  my ($key, $slf, $val);

  # Create the system object
  $slf = bless {
    agt  => $agt,
    oid  => $par->get_unique($oid),
    par  => $par,
    _chl => [],
    _def => $def,
    _fcs => {},
    _shr => $def->{'DEDICATED_WL_HOME'} ? 0 : 1,
    _typ => 'WH',
    }, ref($cls) || $cls;

  # Load the target definition
  $slf->{'mwh'} = RDA::Object::Rda->cat_dir($def->{'MW_HOME'})
    if exists($def->{'MW_HOME'}) && defined($def->{'MW_HOME'});
  $slf->{'wlh'} = RDA::Object::Rda->cat_dir($def->{'WL_HOME'})
    if exists($def->{'WL_HOME'}) && defined($def->{'WL_HOME'});

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $slf->{$key} = $val if defined($val);
  }

  # Validate the configuration
  die "RDA-01370: Missing WebLogic Server home directory in $oid target\n"
    unless exists($slf->{'wlh'});

  # Determine the middleware home
  $slf->{'mwh'} = _find_mw_home($slf, $def) unless exists($slf->{'mwh'});

  # Initiate the symbol management when applicable
  { $slf->{'_abr'} = {};
    $slf->set_symbol($def->{'MH_ABBR'} || '$MH', $slf->{'mwh'});
    $slf->set_symbol($def->{'WH_ABBR'} || '$WH', $slf->{'wlh'});
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>adjust_env($env)>

This method adjust environment variable specifications for the Oracle WebLogic
Server home.

=cut

sub adjust_env
{ my ($slf, $env) = @_;
  my ($dir, $lib,  $wlh, %tbl, @dir);

  # Add the common target specifications
  $env->{'BEA_HOME'} = 
  $env->{'MW_HOME'} = RDA::Object::Rda->native($slf->{'mwh'});
  $env->{'WL_HOME'} = RDA::Object::Rda->native($wlh = $slf->{'wlh'});

  # Add the operating system-specific target specifications
  if (RDA::Object::Rda->is_unix)
  { # Adapt the command path
    @dir = split(/\:/, $env->{'PATH'});
    %tbl = map {$_ => 1} @dir;
    unshift(@dir, $dir)
      if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'server', 'adr'))
      && !exists($tbl{$dir});
    unshift(@dir, $dir)
      if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'common', 'bin'))
      && !exists($tbl{$dir});
    $env->{'PATH'} = join(':', @dir);

    # Adapt the shared library path
    if (defined($lib = RDA::Object::Rda->get_shlib))
    { @dir = split(/\:/, $env->{$lib});
      %tbl = map {$_ => 1} @dir;
      unshift(@dir, $dir)
        if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'server', 'adr'))
        && !exists($tbl{$dir});
      unshift(@dir, $dir)
        if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'common', 'lib'))
        && !exists($tbl{$dir});
      $env->{$lib} = join(':', @dir);
    }
  }
  elsif (RDA::Object::Rda->is_windows)
  { # Adapt the command path
    @dir = split(/\;/, $env->{'PATH'});
    %tbl = map {$_ => 1} @dir;
    unshift(@dir, $dir)
      if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'server', 'adr'))
      && !exists($tbl{$dir});
    unshift(@dir, $dir)
      if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'common', 'bin'))
      && !exists($tbl{$dir});
    $env->{'PATH'} = join(';', @dir);
  }
  elsif (RDA::Object::Rda->is_cygwin)
  { # Adapt the command path
    $wlh =~ s#^([A-Z]):#/cygdrive/\L$1#i;
    @dir = split(/\:/, $env->{'PATH'});
    %tbl = map {$_ => 1} @dir;
    unshift(@dir, $dir)
      if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'server', 'adr'))
      && !exists($tbl{$dir});
    unshift(@dir, $dir)
      if -d ($dir = RDA::Object::Rda->cat_dir($wlh, 'common', 'bin'))
      && !exists($tbl{$dir});
    $env->{'PATH'} = join(':', @dir);
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
  { my ($dft);

    $dft = exists($slf->{'_hom'})
      ? $slf->{'_hom'}
      : $slf->get_default;
    adjust_env($slf, $slf->{'_env'} = {%{$dft->get_env}});
  }

  # Return the environment specifications
  $slf->{'_env'};
}

# --- Internal routines -------------------------------------------------------

# Find the Oracle Middleware home
sub _find_mw_home
{ my ($slf, $def) = @_;
  my ($dir, $ifh, @dir);

  # Try to detect the Oracle Middleware home directory
  unless ($def->{'NO_DETECT'})
  { $ifh = IO::File->new;
    if (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
    { if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'dom'}, 'common',
        'bin', 'commEnv.cmd')))
      { while (<$ifh>)
        { if (m/^\s*set\s+(BEA|MW)_HOME=(.*?)\s*$/)
          { $dir = RDA::Object::Rda->cat_dir($2);
            last;
          }
        }
        $ifh->close;
      }
    }
    else
    { if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->{'dom'}, 'common',
        'bin', 'commEnv.sh')))
      { while (<$ifh>)
        { if (m/^[^\043]*\b(BEA|MW)_HOME=([\042\047])(.*?)\2\s*$/)
          { $dir = $3;
            last;
          }
          if (m/^[^\043]*\b(BEA|MW)_HOME=(\S+)/)
          { $dir = $2;
            last;
          }
        }
        $ifh->close;
      }
    }
    return $dir if defined($dir);
  }

  # Derive the Oracle Middleware home from the Oracle WebLogic Server home
  @dir = RDA::Object::Rda->split_dir($slf->{'wlh'});
  pop(@dir);
  RDA::Object::Rda->cat_dir(@dir);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Target|RDA::Object::Target>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
