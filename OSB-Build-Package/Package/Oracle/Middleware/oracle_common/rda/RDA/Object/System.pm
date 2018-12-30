# System.pm: Class Used to Interface the Operating System

package RDA::Object::System;

# $Id: System.pm,v 1.12 2012/05/13 22:35:55 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/System.pm,v 1.12 2012/05/13 22:35:55 mschenke Exp $
#
# Change History
# 20120513  MSC  Modify the environment management outside UNIX.

=head1 NAME

RDA::Object::System - Class Used to Interface the Operating System

=head1 SYNOPSIS

require RDA::Object::System;

=head1 DESCRIPTION

The objects of the C<RDA::Object::System> class are used to interface with the
operating system. It is a sub class of
L<RDA::Object::Target|RDA::Object::Target>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Rda;
  use RDA::Object::Target;
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf('%d.%02d', q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);
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

=head2 S<$h = RDA::Object::System-E<gt>new($oid,$agt,$def[,$par[,...]])>

The object constructor. This method takes the object identifier, the agent
reference, the definition hash reference, the parent target, and initial
attributes as arguments.

Do not use this constructor directly. Create all targets using
L<RDA::Object::Target|RDA::Object::Target> methods.

C<RDA::Object::System> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'oid' > > Object identifier

=item S<    B<'par' > > Reference to the parent target

=item S<    B<'_abr'> > Symbol definition hash

=item S<    B<'_bkp'> > Backup of environment variables

=item S<    B<'_chl'> > List of the child keys

=item S<    B<'_def'> > Target definition

=item S<    B<'_env'> > Environment specifications

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
    _shr => $def->{'DEDICATED_SYSTEM'} ? 0 : 1,
    _typ => 'SYS',
    }, ref($cls) || $cls;

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { $slf->{$key} = $val if defined($val);
  }

  # Initiate the symbol management when applicable
  $slf->{'_abr'} = {} unless RDA::Object::Rda->is_vms;

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
  { my ($val);

    if (RDA::Object::Rda->is_unix)
    { my ($dir, $lib, @tbl, %tbl);

      # Adapt the command path
      if (defined($val = $slf->get_init('PATH')))
      { @tbl = split(/\:/, $val);
        %tbl = map {$_ => 1} @tbl;
      }
      push(@tbl, $dir) if -d ($dir = "/usr/sbin")    && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/usr/bin")     && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/etc")         && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/usr/ccs/bin") && !exists($tbl{$dir});
      push(@tbl, $dir) if -d ($dir = "/sbin")        && !exists($tbl{$dir});
      $slf->{'_env'}->{'PATH'} = join(":", @tbl);

      # Adapt the shared library path
      if (defined($lib = RDA::Object::Rda->get_shlib))
      { if (defined($val = $slf->get_init($val)))
        { @tbl = split(/\:/, $val);
          %tbl = map {$_ => 1} @tbl;
        }
        else
        { (@tbl, %tbl) = ();
        }
        push(@tbl, $dir) if -d ($dir = "/lib")           && !exists($tbl{$dir});
        push(@tbl, $dir) if -d ($dir = "/usr/lib")       && !exists($tbl{$dir});
        push(@tbl, $dir) if -d ($dir = "/usr/local/lib") && !exists($tbl{$dir});
        $slf->{'_env'}->{$lib} = join(':', @tbl);
      }
    }
    elsif (defined($val = $slf->get_init('PATH')))
    { $slf->{'_env'}->{'PATH'} = $val;
    }
    else
    { $slf->{'_env'} = {};
    }
  }

  # Return the environment specifications
  $slf->{'_env'};
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
