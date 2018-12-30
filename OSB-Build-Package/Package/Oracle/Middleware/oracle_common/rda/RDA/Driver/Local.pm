# Ssh.pm: Class Used for Local Access

package RDA::Driver::Local;

# $Id: Local.pm,v 1.2 2012/05/12 17:45:11 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/Local.pm,v 1.2 2012/05/12 17:45:11 mschenke Exp $
#
# Change History
# 20120512  MSC  Improve the tracing.

=head1 NAME

RDA::Driver::Local - Class Used for Local Access

=head1 SYNOPSIS

require RDA::Driver::Local;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::Local> class are used for execution local
requests.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Driver::Local-E<gt>new($agent)>

The remote access manager object constructor. It takes the agent object
reference as an argument.

=head2 S<$h-E<gt>new($session)>

The remote session manager object constructor. It takes the remote session
object reference as an argument.

C<RDA::Driver::Local> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'-agt'> > Reference to the agent object (M,S)

=item S<    B<'-lin'> > Stored lines (S)

=item S<    B<'-msg'> > Last message (M,S)

=item S<    B<'-nod'> > Node identifier (M,S)

=item S<    B<'-out'> > Timeout indicator (M,S)

=item S<    B<'-pre'> > Trace prefix (M,S)

=item S<    B<'-ses'> > Reference to the session object (S)

=item S<    B<'-sta'> > Last captured exit code (M,S)

=item S<    B<'-trc'> > Trace indicator (M,S)

=item S<    B<'-wrk'> > Reference to the work file manager (M,S)

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $ses) = @_;
  my ($nod);

  # Create the object and return its reference
  $nod = $ses->get_oid;
  ref($cls)
    ? bless {
        -agt => $cls->{'-agt'},
        -lin => [],
        -msg => undef,
        -nod => $nod,
        -pre => $cls->{'-agt'}->get_setting("REMOTE_$nod\_PREFIX", $nod),
        -out => 0,
        -ses => $ses,
        -sta => 0,
        -trc => $cls->{'-trc'} || $ses->get_level,
        -wrk => $cls->{'-wrk'},
        }, ref($cls)
    : _create_manager(@_);
}

=head2 S<$h-E<gt>as_type>

This method returns the driver type.

=cut

sub as_type
{ 'local';
}

=head2 S<$h-E<gt>delete>

This method deletes the object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>get_api($ctx)>

This method returns the version of the interface. It returns an undefined value
in case of problems.

=cut

sub get_api
{ undef;
}

=head2 S<$h-E<gt>get_lines>

This method returns the lines stored during the last command execution.

=cut

sub get_lines
{ @{shift->{'-lin'}};
}

=head2 S<$h-E<gt>get_message>

This method returns the last message.

=cut

sub get_message
{ shift->{'-msg'};
}

=head2 S<$h-E<gt>has_timeout>

This method indicates whether the last request encountered a timeout.

=cut

sub has_timeout
{ shift->{'-out'};
}

=head2 S<$h-E<gt>is_skipped>

This method indicates whether the last request was skipped.

=cut

sub is_skipped
{ 0;
}

=head2 S<$h-E<gt>need_password>

This method indicates whether the last request encountered a timeout.

=cut

sub need_password
{ 0;
}

=head2 S<$h-E<gt>need_pause([$var])>

This method indicates whether the current connection could require a pause for
providing a password.

=cut

sub need_pause
{ 0;
}

=head2 S<$h-E<gt>request($cmd,$var,@dat)>

This method executes a requests and returns the result file. It supports the
following commands:

=over 2

=item * C<DEFAULT>

It changes some interface parameters.

=item * C<EXEC>

It submits one or more commands to the remote servers and collects the results.

=item * C<GET>

It gets one or more remote files.

=item * C<PUT>

It puts one or more local files into the remote server.

=back

It returns a negative value in case of problems.

=cut

sub request
{ my ($slf, $cmd, $var, @dat) = @_;

  # Validate the request
  return -20 unless defined($cmd) && ref($var) eq 'HASH';

  # Execute the request
  return _do_default($slf, $var)    if $cmd eq 'DEFAULT';
  return exists($var->{'FLG'})
    ? _do_command($slf, $var)
    : _do_exec($slf, $var, @dat)    if $cmd eq 'EXEC';
  return -21;
}

# --- Alarm routines ----------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0);};
  $@ ? 0 : $lim;
}

# Get the alarm duration
sub _get_alarm
{ my ($slf, $val) = @_;

  return $slf->{'lim'} unless defined($val);
  return 0 unless $slf->{'lim'} > 0 && $val > 0;
  $val *= $slf->{'lim'};
  ($val > 1) ? int($val) : 1;
}

# --- Internal routines -------------------------------------------------------

# Create the driver manager
sub _create_manager
{ my ($cls, $agt, $lim) = @_;

  # Create the driver manager object
  bless {
    -agt => $agt,
    -msg => undef,
    -nod => 'LOCAL',
    -out => 0,
    -sta => 0,
    -trc => $agt->get_setting('SSH_TRACE', 0),
    -wrk => $agt->get_output,
    }, $cls;
}

# Perform an EXEC request (Command mode)
sub _do_command
{ my ($slf, $var) = @_;
  my ($cmd, $flg, $ifh, $trc);

  $slf->{'-lin'} = [];
  $cmd = $var->{'CMD'};
  $flg = $var->{'FLG'};
  $trc = $slf->{'-pre'} if $slf->{'-trc'};
  if (open($ifh = IO::Handle->new, "$cmd 2>&1 |"))
  { while (<$ifh>)
    { s/[\n\r\s]+$//;
      print "$trc> $_\n" if $trc;
      push(@{$slf->{'-lin'}}, $_) if $flg || m/RDA-\d{5}:/;
    }
    $ifh->close;
  }

  # Indicate the command result
  return $?;
}

# Perform a DEFAULT request
sub _do_default
{ my ($slf, $var) = @_;

  $slf->{'-lim'} = $var->{'MAX'} if exists($var->{'MAX'});
  $slf->{'-pre'} = $var->{'PRE'} if exists($var->{'PRE'});
  $slf->{'-trc'} = $var->{'TRC'} if exists($var->{'TRC'});
  0;
}

# Perform an EXEC request (Execute mode)
sub _do_exec
{ my ($slf, $var, @dat) = @_;
  my ($cmd, $cod, $ofh, $pre);

  $cmd = $var->{'CMD'};
  if (open($ofh = IO::Handle->new, "| $cmd 2>/dev/null"))
  { if (@dat)
    { $cod = join("\n", @dat);
      if ($slf->{'-trc'})
      { $pre = $slf->{'-pre'};
        for (split(/\n/, $cod))
        { print "$pre: $_\n";
        }
      }
      syswrite($ofh, $cod, length($cod));
    }
    $ofh->close;
  }

  # Indicate the command result
  return $?;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Remote|RDA::Object::Remote>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
