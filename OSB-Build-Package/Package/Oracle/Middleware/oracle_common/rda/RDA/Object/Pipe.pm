# Pipe.pm: Class Used for Managing Pipes to Commands

package RDA::Object::Pipe;

# $Id: Pipe.pm,v 2.10 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Pipe.pm,v 2.10 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Pipe - Class Used for Managing Pipes to Commands

=head1 SYNOPSIS

require RDA::Object::Pipe;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Pipe> class are used to manage pipes to
commands. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object;
  use RDA::Object::Rda qw($APPEND $CREATE $FIL_PERMS);
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'getOutputPid' => ['${CUR.REPORT}', 'get_pid'],
    },
  dep => [qw(RDA::Object::Output)],
  inc => [qw(RDA::Object)],
  met => {
    'close'         => {ret => 0},
    'get_pid'       => {ret => 0},
    'get_info'      => {ret => 0},
    'get_status'    => {ret => 0},
    'has_output'    => {ret => 0},
    'is_active'     => {ret => 0},
    'is_locked'     => {ret => 0},
    'prefix'        => {ret => 0},
    'push_lines'    => {ret => 0},
    'set_info'      => {ret => 0},
    'unprefix'      => {ret => 0},
    'write'         => {ret => 0, evl => 'L'},
    'write_data'    => {ret => 0},
    },
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Pipe-E<gt>new($out,$oid,$cmd)>

The pipe object constructor. This method takes the output control object
reference, the object identifier, and the command to execute as arguments.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'aft' > > List of lines to insert after an output

=item S<    B<'bef' > > List of lines to insert before an output

=item S<    B<'flg' > > Output start indicator

=item S<    B<'lck' > > Lock indicator

=item S<    B<'ofh' > > Pipe file handle

=item S<    B<'oid' > > Object identifier

=item S<    B<'out' > > Reference of the output control object

=item S<    B<'pre' > > Code to execute before next write operation

=item S<    B<'pid' > > Subprocess identifier

=item S<    B<'sta' > > Subprocess exit status

=back

=cut

sub new
{ my ($cls, $out, $oid, $cmd) = @_;
  my ($slf);

  # Create the control object and open the pipe
  if (ref($cmd))
  { # Create the pipe control object
    $slf = bless {
      cmd => $cmd,
      lck => 0,
      ofh => IO::File->new,
      oid => $oid,
      out => $out,
      }, ref($cls) || $cls;

    # Open the pipe
    $slf->{'pid'} = $cmd->open_pipe($slf->{'ofh'});
  }
  else
  { # Convert the command on VMS and Windows
    if (RDA::Object::Rda->is_windows)
    { $cmd =~ s#/dev/null#NUL#g;
    }
    elsif (RDA::Object::Rda->is_unix || RDA::Object::Rda->is_cygwin)
    { $cmd = "exec $cmd";
    }
    elsif (RDA::Object::Rda->is_vms && $cmd =~ m/[\<\>]/ && $cmd !~ m/^PIPE /i)
    { $cmd = "exec $cmd";
    }
    elsif ($cmd =~ m/[\<\>]/ && $cmd !~ m/^PIPE /i)
    { $cmd = "PIPE $cmd";
      $cmd =~ s/2>&1/2>SYS\$OUTPUT/g;
      $cmd =~ s#/dev/null#NLA0:#g;
    }

    # Create the pipe control object
    $slf = bless {
      cmd => $cmd,
      lck => 0,
      ofh => IO::File->new,
      oid => $oid,
      out => $out,
      }, ref($cls) || $cls;

    # Open the pipe
    die "RDA-01080: Cannot create the output pipe for '$cmd':\n $!\n"
      unless ($slf->{'pid'} = $slf->{'ofh'}->open("| $cmd"));
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>close([$flag])>

This method closes the pipe. Unless the flag is set, it writes the existing
suffix lines to the pipe before closing it.

=cut

sub close
{ my ($slf, $flg) = @_;

  if (exists($slf->{'ofh'}))
  { # Apply post treatment
    $slf->get_handle(1) unless $flg;

    # Close the file
    delete($slf->{'ofh'})->close;
    $slf->{'sta'} = $?;
    delete($slf->{'pid'});
    delete($slf->{'pre'});
  }
}

=head2 S<$h-E<gt>end>

This method terminates the command execution. It returns the object reference.

=cut

sub end
{ my ($slf) = @_;
 
  # End the command execution
  if (exists($slf->{'ofh'}))
  { RDA::Object::Rda->kill_child($slf->{'pid'});
    $slf->{'sta'} = $?;
    delete($slf->{'ofh'});
    delete($slf->{'pid'});
    delete($slf->{'pre'});
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>get_handle([$flag])>

This method returns the file handle of the pipe. Unless the flag is set, it
also executes prefix blocks when present.

=cut

sub get_handle
{ my ($slf, $flg) = @_;
  my ($val);

  # Abort when the object is locked
  die "RDA-01083: Locked pipe\n" if $slf->{'lck'};

  # Get the pipe handler
  die "RDA-01081: Pipe already closed\n" unless exists($slf->{'ofh'});

  # Put the suffix lines
  if ($val = delete($slf->{'aft'}))
  { $val = [$val] unless ref($val) eq 'ARRAY';
    $slf->write(join('', grep {defined($_) && !ref($_)} @$val)."\n");
  }

  # Perform all pre-treatments
  unless ($flg)
  { # Put the start lines
    $slf->write(join("\n", @{delete($slf->{'bef'})}, ''))
      if exists($slf->{'bef'});

    # When required, execute the prefix code block
    die "RDA-01082: Prefix error\n" if exists($slf->{'pre'})
      && delete($slf->{'pre'})->exec_block('prefix ['.$slf->{'fil'}.']');

    # Report the file as created only after prefix block execution
    $slf->{'flg'} = 1;
  }

  # Return the file handle
  $slf->{'ofh'};
}

=head2 S<$h-E<gt>get_pid>

This method returns the process identifier of the executed command.

=cut

sub get_pid
{ my ($slf) = @_;

  exists($slf->{'pid'}) ? $slf->{'pid'} : undef;
}

=head2 S<$h-E<gt>get_status>

This method returns the exit status of the executed command.

=cut

sub get_status
{ my ($slf) = @_;

  exists($slf->{'sta'}) ? $slf->{'sta'} : undef;
}

=head2 S<$h-E<gt>has_output([$flag])>

This method indicates whether lines have been written in the pipe since the
last prefix command. When the flag is set, it clears any prefix also.

It becomes false after pipe closure.

=cut

sub has_output
{ my ($slf, $flg) = @_;

  if (exists($slf->{'pre'}))
  { delete($slf->{'pre'}) if $flg;
    return 0;
  }
  exists($slf->{'ofh'}) ? 1 : 0;
}

=head2 S<$h-E<gt>is_active>

This method indicates whether the pipe is not closed.

=cut

sub is_active
{ exists(shift->{'ofh'}) ? 1 : 0;
}

=head2 S<$h-E<gt>is_created([$flag])>

This method indicates whether the pipe has been effectively used. When the flag
is set, it clears any prefix also.

=cut

sub is_created
{ my ($slf, $flg) = @_;

  delete($slf->{'pre'}) if $flg;
  exists($slf->{'flg'}) ? 1 : 0;
}

=head2 S<$h-E<gt>is_locked>

This method indicates whether the object is locked.

=cut

sub is_locked
{ shift->{'lck'};
}

=head2 S<$h-E<gt>push_lines($key,$line...)>

This method adds lines in the list of lines to insert before or after an
output. You can specify the extra lines as array references.

=cut

sub push_lines
{ my ($slf, $key, @arg) = @_;

  # Abort when the pipe is already closed
  die "RDA-01081: Pipe already closed\n" unless exists($slf->{'ofh'});

  # Push specified lines
  if ($key eq 'aft' || $key eq 'bef')
  { foreach my $arg (@arg)
    { $arg = [$arg] unless ref($arg) eq 'ARRAY';
      foreach my $lin (@$arg)
      { push(@{$slf->{$key}}, $lin) if defined($lin) && !ref($lin);
      }
    }
  }
}

=head2 S<$h-E<gt>write($str[,$size])>

This method writes a string in the pipe. It returns the number of bytes
actually written, or an undefined value if there was an error.

=cut

sub write_data
{ my ($slf, $buf, $lgt) = @_;
  local $SIG{'PIPE'} = 'IGNORE';

  $lgt = length($buf) unless defined($lgt);
  $slf->get_handle->syswrite($buf, $lgt);
}

*write = \&write_data;

=head1 INTERNAL METHODS

=head2 S<$h-E<gt>delete>

This method deletes a report. The pipe is closed when needed.

=cut

sub delete
{ # Close the pipe when not yet done
  $_[0]->close if exists($_[0]->{'ofh'});

  # Delete the object
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>lock>

This method locks the object. It ignores the request on closed pipes.

=cut

sub lock
{ my ($slf) = @_;

  $slf->{'lck'} = 1 if exists($slf->{'ofh'});
}

=head2 S<$h-E<gt>unlock>

This method unlocks the object.

=cut

sub unlock
{ shift->{'lck'} = 0;
}

=head1 PREFIX MANAGEMENT METHODS

=head2 S<$h-E<gt>deprefix($blk)>

This method suppresses the execution of a code block contained in the specified
block.

=cut

sub deprefix
{ my ($slf, $blk) = @_;

  delete($slf->{'pre'}) if exists($slf->{'ofh'})
    && exists($slf->{'pre'}) && $slf->{'pre'}->get_package == $blk;
}

=head2 S<$h-E<gt>prefix($blk)>

This method specifies a code block to execute when writing to the pipe.

=cut

sub prefix
{ my ($slf, $blk) = @_;

  # Abort when the pipe is already closed
  die "RDA-01081: Pipe already closed\n" unless exists($slf->{'ofh'});

  # Set the prefix
  $slf->{'pre'} = $blk;
}

=head2 S<$h-E<gt>unprefix>

This method suppresses the execution of a code block when writing to the pipe.

=cut

sub unprefix
{ delete(shift->{'pre'});
}

# --- Report compatibility routines -------------------------------------------

sub get_path
{ '-';
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
