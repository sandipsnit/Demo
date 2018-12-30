# Lock.pm: Class Used for Managing Locks

package RDA::Object::Lock;

# $Id: Lock.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Lock.pm,v 2.7 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Lock - Class Used for Managing Locks

=head1 SYNOPSIS

require RDA::Object::Lock;

=head1 DESCRIPTION

The objects of the C<RDA::Object::lock> class are used to manage locks. It
is a subclass of L<RDA::Object|RDA::Object>.

You can use the C<RDA_LOCK> environment variable to specify the directory in
which lock files are regrouped. When the directory is not specified or does not
exist, it creates the lock files in the lock subdirectory.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use Fcntl ':flock';
  use IO::File;
  use RDA::Object;
  use RDA::Object::Rda qw($FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  obj => {
    'RDA::Agent' => 1,
    },
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'lock'   => ['${CUR.LOCK}', 'lock'],
    'mlock'  => ['${CUR.LOCK}', 'mlock'],
    'slock'  => ['${CUR.LOCK}', 'slock'],
    'unlock' => ['${CUR.LOCK}', 'unlock'],
    },
  inc => [qw(RDA::Object)],
  met => {
    'get_info'  => {ret => 0},
    'lock'      => {ret => 0},
    'mlock'     => {ret => 0},
    'set_info'  => {ret => 0},
    'slock'     => {ret => 0},
    'unlock'    => {ret => 0},
    'wait'      => {ret => 0},
    },
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Lock-E<gt>new($agt,$dir)>

The lock control object constructor. It takes the agent reference and the lock
file directory as arguments.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'dir' > > Lock file directory

=item S<    B<'fil' > > Alternative prefix for locking by file presence

=item S<    B<'oid' > > Object identifier

=item S<    B<'_bkp'> > Lock file name backup

=item S<    B<'_job'> > Job/thread log name

=item S<    B<'_lck'> > Lock file name cache

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, $dir) = @_;

  # Create the lock control object and return the object reference
  bless {
    agt  => $agt,
    dir  => $dir,
    fil  => "TMP",
    oid  => "LCK",
    _job => $agt->get_oid.'_job',
    _lck => {},
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>lock($nam[,$flg])>

This method takes an exclusive lock. For VMS, it uses an alternative mechanism,
based on the file presence. When the flag is set, it does not wait until the
lock is available. It returns true for success or false for failure.

=head2 S<$h-E<gt>mlock($nam[,$flg])>

This method is similar to the C<lock> method. When forking is emulated, it uses
an alternative mechanism, based on file presence. In that context, the lock
file cannot be located on a network file system.

=head2 S<$h-E<gt>slock($nam[,$flg])>

This method is similar to the C<lock> method but it only takes a shared lock.
Shared locks are not always effective for VMS or in contexts where forking is
emulated.

=cut

sub lock
{ my ($slf, $nam, $flg) = @_;

  $slf->{'agt'}->can_flock
    ? _lock($slf, $nam, $flg ? LOCK_EX | LOCK_NB : LOCK_EX)
    : _file($slf, $nam, $flg);
}

sub mlock
{ my ($slf, $nam, $flg) = @_;

  ($slf->{'agt'}->can_flock > 0)
    ? _lock($slf, $nam, $flg ? LOCK_EX | LOCK_NB : LOCK_EX)
    : _file($slf, $nam, $flg);
}

sub slock
{ my ($slf, $nam, $flg) = @_;

  ($slf->{'agt'}->can_flock > 0)
    ? _lock($slf, $nam, $flg ? LOCK_SH | LOCK_NB : LOCK_SH)
    : 0;
}

# Use a file as locking mechanism
sub _file
{ my ($slf, $nam, $flg) = @_;
  my ($fil, $lck);

  unless (exists($slf->{'_lck'}->{$nam}))
  { $fil = RDA::Object::Rda->cat_file($slf->{'dir'}, "$nam.lck");
    $lck = IO::File->new;
    while (!$lck->open($fil, O_CREAT | O_EXCL, $FIL_PERMS))
    { die "RDA-01120: Cannot create the lock file '$nam'\n $!\n"
        unless $! =~ m/File exists/i;
      return 0 if $flg;
      sleep(3);
    }
    $lck->close;
    $slf->{'_lck'}->{$nam} = $fil;
  }
  return 1;
}

# Use an operating system lock
sub _lock
{ my ($slf, $nam, $flg) = @_;
  my ($fil, $lck);

  # Determine the lock file path
  return 0 unless $nam;
  if (exists($slf->{'_lck'}->{$nam}))
  { $lck = $slf->{'_lck'}->{$nam};
  }
  else
  { $fil = RDA::Object::Rda->cat_file($slf->{'dir'}, "$nam.lck");
    $lck = IO::File->new;
    $lck->open($fil, O_CREAT | O_APPEND | O_RDWR, $FIL_PERMS)
      or die "RDA-01120: Cannot create the lock file '$nam':\n $!\n";
    $slf->{'_lck'}->{$nam} = $lck;
  }

  # Take the lock
  flock($lck, $flg);
}

=head2 S<$h-E<gt>unlock($nam)>

This method releases a lock. It returns true for success or false for failure.

=cut

sub unlock
{ my ($slf, $nam) = @_;
  my ($lck, $ret);

  return 0 unless exists($slf->{'_lck'}->{$nam});
  $lck = $slf->{'_lck'}->{$nam};
  return flock($lck, LOCK_UN) if ref($lck);
  ++$ret while unlink($lck);
  delete($slf->{'_lck'}->{$nam});
  $ret;
}

=head1 JOB AND THREAD LOCK METHODS

=head2 S<$h-E<gt>end($flg)>

This method removes the files that were created to indicate a lock by their
presence. Unless the flag is set, it performs explicit unlocks.

=cut

sub end
{ my ($slf, $flg) = @_;
  my ($fil, $tbl);

  $tbl = $slf->{'_lck'};
  foreach my $nam (keys(%$tbl))
  { if (ref($fil = $tbl->{$nam}))
    { flock($fil, LOCK_UN) unless $flg;
    }
    else
    { 1 while unlink($fil);
    }
  }
  $slf->{'_lck'} = ref($tbl = delete($slf->{'_bkp'})) ? $tbl : {};
}

=head2 S<$h-E<gt>init($flg)>

This method prepares the lock context for a new job or thread. When the flag
is set, it takes a shared lock to indicate that a thread is running. The method
derives the lock name from the name of the setup file.

=cut

sub init
{ my ($slf, $flg) = @_;

  $slf->{'_bkp'} = $slf->{'_lck'};
  $slf->{'_lck'} = {};
  _lock($slf, $slf->{'_job'}, LOCK_SH | LOCK_NB)
    if $flg && $slf->{'agt'}->can_fork > 0;
}

=head2 S<$h-E<gt>wait>

This method takes an exclusive lock that can only be obtained if no threads
are running. It releases the lock immediately.

=cut

sub wait
{ my ($slf) = @_;

  _lock($slf, $slf->{'_job'}, LOCK_EX);
  unlock($slf, $slf->{'_job'});
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
