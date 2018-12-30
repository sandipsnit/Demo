# Remote.pm: Interface Used to Manage Remote Data Collections

package RDA::Remote;

# $Id: Remote.pm,v 2.8 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Remote.pm,v 2.8 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Remote - Interface Used to Manage Remote Data Collections

=head1 SYNOPSIS

require RDA::Remote;

=head1 DESCRIPTION

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Options;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.8 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<authenticate [-t file]>

This commands submits requests received on its standard input to the SSH
authentication agent and returns agent response on its standard output.

=cut

sub authenticate
{ my ($agt, @arg) = @_;
  my ($ctl, $opt, $trc);

  # Treat the switches
  $opt = RDA::Options::getopts('t:', \@arg);
  $trc = undef unless exists($opt->{'t'})
    && ($trc = IO::File->new)->open($opt->{'t'}, $CREATE, $FIL_PERMS);

  # Treat the requests
  eval {
    # Initialize the interface with the authentication agent
    require RDA::Object::SshAgent;
    $ctl = RDA::Object::SshAgent->new($trc);

    # Treat the requests
    binmode(STDIN);
    binmode(STDOUT);
    $ctl->treat_request while $ctl->get_request;

    # Close the interface
    };
  if ($@)
  { $trc->syswrite($@, length($@)) if $trc;
    $agt->set_temp_setting('RDA_EXIT', 3);
  }

  # Close the interface and the trace file
  $ctl->delete if $ctl;
  $trc->close  if $trc;

  # Disable setup save
  0;
}

=head2 S<disable [node...]>

This command disables the remote collection on nodes that are still executing a
step before the post treatment or the report package transfer. When you specify
the force option without any node, then all nodes are considered.

=cut

sub disable
{ my $agt = shift;

  # Perform the action and indicate if the setup must be saved
  _exec_code($agt, 'RACsetup', 'S900REXE', 'disable', @_) ? 0 : 1;
}

=head2 S<edit list [node...]>

This command edits one or more remote node initial settings. The modifications
are provided as a comma separated list of C<key=value> pairs. No settings are
created. When you specify the force option without any node, then all nodes are
considered.

=cut

sub edit
{ my $agt = shift;
  my $edt = shift;

  # Perform the action and indicate if the setup must be saved
  return 0 unless $edt;
  $agt->set_temp_setting('EXT_EDIT', $edt);
  _exec_code($agt, 'RACsetup', 'S900REXE', 'edit', @_) ? 0 : 1;
}

=head2 S<help>

This command displays the command syntaxes and the related explanations.

=cut

sub help
{ my ($agt) = @_;
  my ($pkg);

  $pkg = __PACKAGE__.'.pm';
  $pkg =~ s#::#/#g;
  $agt->get_display->dsp_pod([$INC{$pkg}], 1);

  # Disable setup save
  0;
}

=head2 S<list>

This command lists the nodes.

=cut

sub list
{ my $agt = shift;

  # Perform the action and indicate that there are no setup changes
  _exec_code($agt, 'RACsetup', 'S900REXE', 'list', @_);

  # Disable setup save
  0;
}

=head2 S<restart [node...]>

This command restarts the remote node collection from the beginning. This occurs
only when the node step is defined already. When you specify the force option
without any node, then all nodes are restarted.

=cut

sub restart
{ my $agt = shift;

  # Perform the action and indicate if the setup must be saved
  _exec_code($agt, 'RACsetup', 'S900REXE', 'restart', @_) ? 0 : 1;
}

=head2 S<retry [node...]>

This command attempts to execute the last step of remote data collections again.
This is performed for nodes with errors only. When you specify the force option
without any node, then all nodes are restarted.

=cut

sub retry
{ my $agt = shift;

  # Perform the action and indicate if the setup must be saved
  _exec_code($agt, 'RACsetup', 'S900REXE', 'retry', @_) ? 0 : 1;
}

=head2 S<set type [node...]>

This command specifies the commands that should be used for remote operations on
the specified nodes. When you specify the force option without any node, then
all nodes are considered. Valid types are as follows:

=over 10

=item S<    B<dft > > Restores the default settings.

=item S<    B<remsh>> Uses C<remsh>/C<rcp>.

=item S<    B<rsh > > Uses C<rsh>/C<rcp>.

=item S<    B<ssh > > Uses C<ssh>/C<scp>.

=item S<    B<ssh0> > Uses C<ssh>/C<scp> without connection timeout.

=back

=cut

sub set
{ my $agt = shift;
  my $typ = shift;

  # Validate the type
  return 0 unless $typ && $typ =~ m/^(dft|remsh|rsh|ssh0?)$/;

  # Perform the action and indicate if the setup must be saved
  _exec_code($agt, 'RACsetup', 'S900REXE', "set_$typ", @_) ? 0 : 1;
}

=head2 S<setup_cluster [user]>

This command sets up the remote data collection for a cluster. You can specify
a user as an argument to get the cluster nodes from the database. The following
user formats are supported:

=over 16

=item B<    user>

To connect with the user in the database referenced by the C<ORACLE_SID>
environment variable.

=item B<    user@SID>

To connect with the user in the specified database.

=item B<    />

To connect as C</ AS SYSDBA> to the database referenced by the C<ORACLE_SID>
environment variable.

=item B<    /@SID>

To connect as C</ AS SYSDBA> to the specified database.

=back

Using C<AS SYSDBA> requires appropriate privileges.

If the user is not specified, the command uses an operating system command
(C<olsnodes> or C<lsnodes>) to get the cluster nodes. In that case, the RDA
collection must be initiated from one of the cluster nodes.

=cut

sub setup_cluster
{ my $agt = shift;
  my $flg = $agt->is_configured('S919LOAD');
  my $trc = $agt->get_setting('RDA_TRACE');

  # Execute the RACsetup script
  return 0 if _exec_code($agt, 'RACsetup', 'S900REXE', 'setup', @_);

  # Setup the remote data collection module
  $agt->set_temp_setting('REMOTE_COLLECTION',1);
  $agt->setup('S909RDSP',$trc);
  $agt->set_info('yes', 1);
  $agt->set_temp_setting('REMOTE_DEFINITION',1);
  $agt->setup('S900REXE',$trc);
  $agt->setup('S919LOAD',$trc) if $flg;

  # Indicate that the setup must be saved
  1;
}

=head2 S<suspend [node...]>

This command suspends remote collection by putting the current step in error.
This is only performed for nodes where the collection is not completed. When
you specify the force option without any node, then all nodes are considered.

=cut

sub suspend
{ my $agt = shift;

  # Perform the action and indicate if the setup must be saved
  _exec_code($agt, 'RACsetup', 'S900REXE', 'suspend', @_) ? 0 : 1;
}

=head1 REMOTE DAEMON MANAGEMENT

=head2 S<start_daemon [node...]>

This command starts a background collection on the specified nodes. When you
specify the force option without any node, then all nodes are considered.

=cut

sub start_daemon
{ my $agt = shift;

  # Perform the action and indicate that there are no setup changes
  _exec_code($agt, 'RACsetup', 'S900REXE', 'start_daemon', @_);
  0;
}

=head2 S<stop_daemon [node...]>

This command stops the background collection on the specified nodes. When you
specify the force option without any node, then all nodes are considered.

=cut

sub stop_daemon
{ my $agt = shift;

  # Perform the action and indicate that there are no setup changes
  _exec_code($agt, 'RACsetup', 'S900REXE', 'stop_daemon', @_);
  0;
}

# --- Internal routines -------------------------------------------------------

# Execute the sub module
sub _exec_code
{ my $agt = shift;
  my $nam = shift;
  my $mod = shift;
  my $act = shift;
  my ($obj, $ret);

  # Execute the RAC setup script
  require RDA::Block;
  $obj = RDA::Block->new($nam, $agt->get_info('dir'), $agt);
  unless ($ret = $obj->load($agt))
  { $agt->set_current($mod);
    $agt->set_temp_setting('EXT_CMD', $act) if $act;
    $agt->set_temp_setting('EXT_ARGS', join('|', @_)) if @_;
    eval {
      local $SIG{'INT'} = sub {
        local $SIG{'__WARN__'} = sub {};
        die ("RDA-00206: RDA data collection interrupted\n");
      };
      $ret = $obj->collect($agt->get_setting('RDA_DEBUG'),
        $agt->get_setting('RDA_TRACE'));
    };
    $agt->set_current;
  }
  $ret;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Daemon|RDA::Daemon>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Discover|RDA::Discover>,
L<RDA::Extra|RDA::Extra>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::SshAgent|RDA::Object::SshAgent>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
