# Da.pm: Class Used for Remote Access with the Diagnostic Assistant

package RDA::Driver::Da;

# $Id: Da.pm,v 1.5 2012/05/10 07:13:59 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/Da.pm,v 1.5 2012/05/10 07:13:59 mschenke Exp $
#
# Change History
# 20120510  MSC  Add the is_skipped method.

=head1 NAME

RDA::Driver::Da - Class Used for Remote Access using the Diagnostic Assistant

=head1 SYNOPSIS

require RDA::Driver::Da;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::Da> class are used for execution remote
access requests using the Diagnostic Assistant (DA).

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Driver::Da-E<gt>new($agent)>

The remote access manager object constructor. It takes the agent object
reference as an argument.

=head2 S<$h-E<gt>new>

The remote session manager object constructor.

C<RDA::Driver::Da> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'-lin'> > Stored lines (S)

=item S<    B<'-msg'> > Last message (M,S)

=item S<    B<'-out'> > Timeout indicator (M,S)

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls) = @_;
  my ($slf);

  # Create the object and return its reference
  ref($cls)
    ? bless {
        -lin => [],
        -msg => undef,
        -out => 0,
        }, ref($cls)
    : _create_manager(@_);
}

=head2 S<$h-E<gt>as_type>

This method returns the driver type.

=cut

sub as_type
{ 'da';
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
{ my ($slf) = @_;

  shift->{'-msg'};
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

=head2 S<$h-E<gt>need_password([$var])>

This method indicates whether the last request encountered a timeout.

=cut

sub need_password
{ 0;
}

=head2 S<$h-E<gt>need_pause>

This method indicates whether the current connection could require a pause for
providing a password.

=cut

sub need_pause
{ 0;
}

=head2 S<$h-E<gt>request($cmd,$var,@dat)>

This method executes a requests and return the result file. It returns an
undefined value in case of problems.

=cut

sub request
{ my ($slf, $cmd, $var, @dat) = @_;

  undef;
}

# --- Internal routines -------------------------------------------------------

# Create the driver manager
sub _create_manager
{ undef
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Remote|RDA::Object::Remote>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
