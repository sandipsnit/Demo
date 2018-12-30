# Explorer.pm: Class Used for Interfacing with Oracle Explorer

package RDA::Object::Explorer;

# $Id: Explorer.pm,v 1.4 2012/08/14 00:29:00 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Explorer.pm,v 1.4 2012/08/14 00:29:00 mschenke Exp $
#
# Change History
# 20120813  MSC  Add the 'has_ipmitool' and 'set_ipmi_tool' methods.

=head1 NAME

RDA::Object::Explorer - Class Used for Interfacing with Oracle Explorer

=head1 SYNOPSIS

require RDA::Object::Explorer;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Explorer> class are used to interface with
Oracle Explorer. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object;
  use RDA::Object::Rda qw($APPEND $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  beg => \&_begin_explorer,
  glb => ['$[XPL]'],
  inc => [qw(RDA::Object)],
  met => {
    'exec_curl'    => {ret => 0},
    'has_curl'     => {ret => 0},
    'has_ipmitool' => {ret => 0},
    'log'          => {ret => 0, evl=>'L'},
    'set_curl'     => {ret => 0},
    'set_ipmitool' => {ret => 0},
    },
  );

# Define the global private constants

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Explorer-E<gt>new($agent)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Object::Explorer> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'oid' > > Object identifier

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_crl'> > CURL command

=item S<    B<'_ipm'> > IPMITOOL command

=item S<    B<'_log'> > Log file path

=item S<    B<'_ofh'> > Log file handler

=item S<    B<'_pwd'> > Reference to the access control object

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($log, $slf);

  # Create the object
  $slf = bless {
    oid  => 'Explorer',
    _agt => $agt,
    _pwd => $agt->get_access,
    }, ref($cls) || $cls;

  # Determine if a log file is provided
  ($slf->{'_log'}, $slf->{'_ofh'}) = ($log, IO::File->new)
    if defined($log = $agt->get_setting('XPLR_LOG'));

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>exec_curl($host,$user,$arg...)>

This method executes a F<curl> request. It returns zero on successful
completion.

=cut

sub exec_curl
{ my ($slf, $hst, $usr, @arg) = @_;
  my ($buf, $pgm, $pwd);

  # Validate the arguments
  return -1 unless has_curl($slf);
  return -2 unless defined($hst) && defined($usr);

  # Perform the curl request
  $pwd = $slf->{'_pwd'}->get_password('host', $hst, $usr,
    "Enter the password for $usr on $hst: ", '');
  $buf = "user='$usr:$pwd'\n";

  return -1 unless open(EXP, join(' ', '|', $slf->{'_crl'}, '-q',
    '--config', '-', @arg, '>/dev/null', '2>&1'));
  syswrite(EXP, $buf, length($buf));
  close(EXP);
  $?;
}

=head2 S<$h-E<gt>has_curl>

This method indicates whether F<curl> is available.

=cut

sub has_curl
{ my ($slf) = @_;
  my ($pgm);

  return $slf->{'_crl'} if exists($slf->{'_crl'});
  $slf->{'_crl'} = ((-f ($pgm = '/bin/curl')     && -x $pgm) ||
                    (-f ($pgm = '/usr/bin/curl') && -x $pgm))
}

=head2 S<$h-E<gt>has_ipmitool>

This method indicates whether F<ipmitool> is available.

=cut

sub has_ipmitool
{ my ($slf) = @_;
  my ($pgm);

  return $slf->{'_ipm'} if exists($slf->{'_ipm'});
  $slf->{'_ipm'} = ((-f ($pgm = '/opt/ipmitool/bin/ipmitool') && -x $pgm) ||
                    (-f ($pgm = '/usr/sbin/ipmitool')         && -x $pgm) ||
                    (-f ($pgm = '/usr/sfw/bin/ipmitool')      && -x $pgm))
    ? $pgm
    : undef;
}

=head2 S<$h-E<gt>log($txt)>

This method adds the specified text at the end of the log file.

=cut

sub log
{ my ($slf, $txt) = @_;

  if (exists($slf->{'_log'})
    && $slf->{'_ofh'}->open($slf->{'_log'}, $APPEND, $FIL_PERMS))
  { $slf->{'_ofh'}->syswrite($txt, length($txt));
    $slf->{'_ofh'}->close;
  }
}

=head2 S<$h-E<gt>set_curl($path)>

This method specifies to use a specific copy of F<curl>. It requires an
absolute path to an existing file.

=cut

sub set_curl
{ my ($slf, $pth) = @_;

  $slf->{'_crl'} = RDA::Object::Rda->quote($pth)
    if RDA::Object::Rda->is_absolute($pth) && -f $pth && -x $pth;
}

=head2 S<$h-E<gt>set_ipmitool($path)>

This method specifies to use a specific copy of F<ipmitool>. It requires an
absolute path to an existing file.

=cut

sub set_ipmitool
{ my ($slf, $pth) = @_;

  $slf->{'_ipm'} = RDA::Object::Rda->quote($pth)
    if RDA::Object::Rda->is_absolute($pth) && -f $pth && -x $pth;
}

# --- SDCL extensions ---------------------------------------------------------

# Define a global variable to access the interface object
sub _begin_explorer
{ my ($pkg) = @_;
  my ($agt);

  $agt = $pkg->get_agent;
  $pkg->define('$[XPL]', $agt->get_registry('xpl', \&new, __PACKAGE__, $agt));
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
