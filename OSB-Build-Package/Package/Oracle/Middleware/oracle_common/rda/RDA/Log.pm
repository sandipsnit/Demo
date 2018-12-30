# Log.pm: Class Used for Objects to Manage the Event Log

package RDA::Log;

# $Id: Log.pm,v 2.5 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Log.pm,v 2.5 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Log - Class Used for Objects to Manage the Event Log

=head1 SYNOPSIS

require RDA::Log;

=head1 DESCRIPTION

The objects of the C<RDA::Log> class are used to manage the event log.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object::Rda qw($APPEND $DIR_PERMS $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Log-E<gt>new($agt)>

The object constructor. It takes the agent reference as an argument.

C<RDA::Log> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_beg'> > Start time

=item S<    B<'_cfg'> > Reference to the RDA software configuration object

=item S<    B<'_evt'> > Event stack

=item S<    B<'_nam'> > Setup file name

=item S<    B<'_ofh'> > Output file handle

=item S<    B<'_pth'> > Log file path

=back

Internal keys are prefixed by an underscore.

It tries to open the event log file and to add a start event (type 'b').

=cut

sub new
{ my ($cls, $agt) = @_;

  # Create the log object and return its reference
  bless {
    _agt => $agt,
    _beg => time,
    _cfg => $agt->get_config,
    _evt => [],
    _nam => $agt->get_oid,
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>end>

This method logs an end event (type 'e') including the execution duration,
and then closes the event log.

It returns a true value when it effectively closes the event log, otherwise, a
false value.

=cut

sub end
{ my ($slf) = @_;
  my ($tim);

  if (exists($slf->{'_ofh'}))
  { # Log the end record
    $tim = time;
    $slf->_log($tim, 'e', $slf->{'_cfg'}->get_version,
      $tim - $slf->{'_beg'}, $slf->{'_agt'}->get_setting('RPT_GROUP'));

    # Close the event log file
    delete($slf->{'_ofh'})->close;
    delete($slf->{'_pth'});
  }
}

=head2 S<$h-E<gt>init($dir[,$flg])>

This method initializes the log file in the specified directory. When the flag
is set, it creates the report directory also.

=cut

sub init
{ my ($slf, $dir, $flg) = @_;

  unless (exists($slf->{'_ofh'}))
  { # Create the report directory when needed.
    if ($flg && $dir)
    { die "RDA-00200: Cannot create the report directory $dir:\n $!\n"
        unless -d $dir || RDA::Object::Rda->create_dir($dir, $DIR_PERMS);
    }

    # Open the event log file and add the start event
    $slf->_init($dir) if $dir && -d $dir;
  }
}

sub _init
{ my ($slf, $dir) = @_;
  my ($cfg, $evt, $ofh, $pth);

  # Open the event log file and add the start event
  $cfg = $slf->{'_cfg'};
  $ofh = IO::File->new;
  $pth = $cfg->cat_file($dir,
    $cfg->get_info('RDA_CASE') ? 'RDA.log' : 'rda.log');
  return unless $ofh->open($pth, $APPEND, $FIL_PERMS);
  $slf->{'_ofh'} = $ofh;
  $slf->{'_pth'} = $pth;

  # Add the start event and other pending events
  $slf->_log($slf->{'_beg'}, 'b', $slf->{'_cfg'}->get_version);
  $slf->_log(@$evt) while defined($evt = shift(@{$slf->{'_evt'}}));
}

=head2 S<$h-E<gt>log($typ[,$arg...])>

This method logs an event in the event log. It prefixes event records with a
time stamp (GMT) and the setup name. The fields are separated by a C<|>
character.

It stores the event if the log file is not currently open.

It returns an undefined value if the type does not contain ASCII letters
only. Otherwise, it returns the number of events effectively in the log file.

=cut

sub log
{ my ($slf, $typ, @arg) = @_;

  ($typ && $typ =~ m/^[A-Za-z]+$/)
    ? _log($slf, time, $typ, @arg)
    : undef;
}

sub _log
{ my ($slf, $tim, @arg) = @_;

  # Write the event if the evnt log is open
  if (exists($slf->{'_ofh'}))
  { my ($buf);

    $buf = join('|', RDA::Object::Rda->get_timestamp($tim), $slf->{'_nam'},
      @arg, "\n");
    sysseek($slf->{'_ofh'}, 0, 2);
    $slf->{'_ofh'}->syswrite($buf, length($buf));
    return 1;
  }

  # Otherwise, store it
  push(@{$slf->{'_evt'}}, [$tim, @arg]);
  return 0;
}

=head2 S<$h-E<gt>logfile>

This method returns the file handle that is associated with the event log.
Otherwise, it returns C<undef> when not possible.

=cut

sub logfile
{ my $slf = shift;

  exists($slf->{'_ofh'}) ? $slf->{'_ofh'} : undef;
}

=head2 S<$h-E<gt>resume>

This method reopens the log file and restarts the event logging.

=cut

sub resume
{ my ($slf) = @_;
  my ($evt, $ofh);

  if (exists($slf->{'_pth'}) && !exists($slf->{'_ofh'})
    && ($ofh = IO::File->new)->open($slf->{'_pth'}, $APPEND, $FIL_PERMS))
  { $slf->{'_ofh'} = $ofh;

    # Add the pending events
    $slf->_log(@$evt) while defined($evt = shift(@{$slf->{'_evt'}}));
  }
}

=head2 S<$h-E<gt>suspend>

This method suspends event logging and closes the log file.

=cut

sub suspend
{ my ($slf) = @_;

  delete($slf->{'_ofh'})->close if exists($slf->{'_ofh'});
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
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
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
