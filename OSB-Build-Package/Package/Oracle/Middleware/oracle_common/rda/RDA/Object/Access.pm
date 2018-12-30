# Access.pm: Class Used for Objects to Manage Access Credentials

package RDA::Object::Access;

# $Id: Access.pm,v 1.5 2012/05/14 07:35:18 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Access.pm,v 1.5 2012/05/14 07:35:18 mschenke Exp $
#
# Change History
# 20120514  MSC  Eliminate undefined SID at normalization time.

=head1 NAME

RDA::Object::Access - Class Used for Objects to Manage Access Credentials

=head1 SYNOPSIS

require RDA::Object::Access;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Access> class are used to manage the access
credentials. It is a sub class of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @DUMP @EXPORT_OK @ISA %SDCL);
$VERSION   = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);
@DUMP      = (
  str => { map {$_ => 1} qw(con dos pwd) },
  );
@EXPORT_OK = qw(check_dsn check_sid);
@ISA       = qw(RDA::Object Exporter);
%SDCL      = (
  als => {
    'askPassword'   => ['${CUR.ACCESS}', 'ask_password'],
    'hasPassword'   => ['${CUR.ACCESS}', 'has_password'],
    'samePassword'  => ['${CUR.ACCESS}', 'same_password'],
    'setPassword'   => ['${CUR.ACCESS}', 'set_password'],
    'sharePassword' => ['${CUR.ACCESS}', 'share_password'],
    },
  inc => [qw(RDA::Object)],
  met => {
    'ask_password'   => {ret => 0},
    'has_password'   => {ret => 0},
    'same_password'  => {ret => 0},
    'set_password'   => {ret => 0},
    'share_password' => {ret => 0},
    },
  );

# Define the global private constants
my $EXT = qr/^[^:]+:\d+:{1,2}[^:]+$/;
my $EZC = qr|^//([^:/]+):(\d+)/([^:]+)$|;
my $EZD = qr|^//([^:/]+)/([^:]+)$|;
my $SID = qr/^([^:]+):(\d+):([^:]+)$/;
my $SVC = qr/^([^:]+):(\d+):([^:]*):([^:]+)$/;

# Define the global private variables
my $ctl;

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Access-E<gt>new($agt[,$flg])>

The object constructor. This method enables you to specify the agent reference
and an optional load suppression indicator as arguments.

C<RDA::Object::Access> is represented by a blessed hash reference. The following
special keys are used:

=over 16

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'cfg' > > RDA software configuration

=item S<    B<'con' > > Reference to DOS console input object

=item S<    B<'dos' > > Reference to DOS console object

=item S<    B<'oid' > > Object identifier

=item S<    B<'pwd' > > Password container

=item S<    B<'yes' > > Auto confirmation flag

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, $flg) = @_;
  my ($slf, $str);

  # Create the setup object
  $slf = bless {
    agt  => $agt,
    cfg  => $agt->get_config,
    oid  => 'access',
    pwd  => {},
    yes  => $agt->get_info('yes'),
    }, ref($cls) || $cls;

  # Load the credentials
  $slf->load_credentials unless $flg;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>ask_password($txt)>

This method asks for a password. When supported by the installed Perl version,
it suppresses the character echo for password entry. When the character echo is
suppressed, the method requests the password twice. If both strings do not
match after three attempts, the request is canceled. It returns the password,
or, in case of failure, it returns an undefined value.

=head2 S<RDA::Object::Access::ask_password($agt, $txt)>

This method asks for a password without requiring an access control object.

=cut

sub ask_password
{ my ($slf, $txt, $pwd) = @_;
  my ($clf, $cnt, $err, $fdi, $str1, $str2, $tio);

  # Return the default password  when the dialog are suppressed
  return $pwd if $slf->get_info('yes');

  # Assume a default input prompt
  $txt = 'Please enter the password: ' unless defined($txt);
  $txt =~ s/[\s\r\n]+$/ /;

  # Try to get the password without character echo
  eval {
    die "Not a tty\n" unless -t STDIN;
    if (RDA::Object::Rda->is_windows)
    { # Get the input device
      die "Bad DOS windows\n"
        unless ref($tio = $slf->get_info('cfg')->get_input);

      # Request the password
      for ($cnt = 3 ;;)
      { $str1 = _get_dos_password($tio, $txt);
        $str2 = _get_dos_password($tio, "\nPlease re-enter it to confirm:");
        print "\n";

        if ($str1 ne $str2)
        { $err = 'Entries do not match';
        }
        else
        { $str1 =~ s/[\r\n]+$//;
          if ($str1 ne '')
          { $pwd = $str1;
            last;
          }
          $err = 'Empty string';
        }
        if (--$cnt < 1)
        { print "Failure to match a valid entry on 3 attempts\n";
          last;
        }
        print "$err. Please try again...\n";
      }
    }
    else
    { # Get initial standard input setting
      require POSIX;
      $tio = POSIX::Termios->new;
      $tio->getattr($fdi = fileno(STDIN));
      $clf = $tio->getlflag;

      # Trap Interrupt signal to restore echo
      sub trap_int
      { my $tio = POSIX::Termios->new;
        $tio->getattr(fileno(STDIN));
        $tio->setlflag($tio->getlflag | &POSIX::ECHO);
        $tio->setattr(fileno(STDIN), &POSIX::TCSANOW);
        exit(1);
      }
      local $SIG{'INT'} = \&trap_int;

      # Suppress character echo
      $tio->setlflag($clf & ~&POSIX::ECHO);
      $tio->setattr($fdi, &POSIX::TCSANOW);

      # Ask for the password and verify string match
      for ($cnt = 3 ;;)
      { print $txt;
        unless (defined($str1 = <STDIN>))
        { print "\nFailure to enter the password\n";
          last;
        }
        print "\nPlease re-enter it to confirm:";
        unless (defined($str2 = <STDIN>))
        { print "\nFailure to confirm the password\n";
          last;
        }
        print "\n";

        if ($str1 ne $str2)
        { $err = 'Entries do not match';
        }
        else
        { $str1 =~ s/[\r\n]+$//;
          if ($str1 ne '')
          { $pwd = $str1;
            last;
          }
          $err = 'Empty string';
        }
        if (--$cnt < 1)
        { print "Failure to match a valid entry on 3 attempts\n";
          last;
        }
        print "$err. Please try again...\n";
      }

      # Restore initial standard input setting
      $tio->setlflag($clf);
      $tio->setattr($fdi, &POSIX::TCSANOW);
    }
  };

  # If that is not possible, try it without suppressing character echo
  if ($@)
  { for ($cnt = 3 ;;)
    { print $txt;
      unless (defined($pwd = <STDIN>))
      { print "\nFailure to enter the password\n";
        last;
      }
      $pwd =~ s/[\r\n]+$//;
      last if $pwd;
      if (--$cnt < 1)
      { print "Failure to provide a valid entry on 3 attempts\n";
        last;
      }
      print "Empty string. Please try again...\n";
    }
    print "\n" unless -t STDIN;
  }

  # Return the password
  return $pwd;
}

sub _get_dos_password
{ my ($dev, $txt) = @_;
  my ($chr, $mod, $pwd, @inp);

  syswrite(STDOUT, $txt, length($txt));
  $pwd = '';
  for (;;)
  { @inp = $dev->Input();
    next unless $inp[0] == 1 && $inp[1] == 1 && $inp[5] != 0;
    $chr = chr(($inp[5] > 0) ? $inp[5] : 256 + $inp[5]);
    last if $chr eq "\r";
    $pwd .= $chr;
  }
  $pwd;
}


=head2 S<$h-E<gt>get_password($typ,$sid,$usr)>

This method returns the password for the specified login.

=cut

sub get_password
{ my ($slf, $typ, $sid, $usr, $txt, $dft) = @_;

  _get_password($slf, _norm_credential($typ, $sid, $usr), $txt, $dft);
}

sub _get_password
{ my ($slf, $typ, $sid, $usr, $txt, $dft) = @_;

  $slf->{'pwd'}->{$typ}->{$sid}->{$usr} = $slf->ask_password($txt, $dft)
    unless _has_password($slf, $typ, $sid, $usr);
  $slf->{'pwd'}->{$typ}->{$sid}->{$usr};
}

=head2 S<$h-E<gt>has_password($typ,$sid,$usr)>

This method indicates whether a password hash entry already exists for the
specified login.

=cut

sub has_password
{ my ($slf, $typ, $sid, $usr) = @_;

  _has_password($slf, _norm_credential($typ, $sid, $usr));
}

sub _has_password
{ my ($slf, $typ, $sid, $usr) = @_;

  # Create the system list
  if ($typ eq 'oracle')
  { $slf->{'pwd'}->{$typ}->{$sid}->{''} = ''
      unless exists($slf->{'pwd'}->{$typ}->{$sid});
  }
  else
  { $slf->{'pwd'}->{$typ}->{$sid} = {}
      unless exists($slf->{'pwd'}->{$typ}->{$sid});
  }

  # Check the login record existence
  exists($slf->{'pwd'}->{$typ}->{$sid}->{$usr});
}

=head2 S<$h-E<gt>load_credentials>

This method loads the database passwords stored in the specified items. It
does not overwrite existing passwords. It returns the object reference.

=cut

sub load_credentials
{ my ($slf) = @_;
  my ($agt, $grp, $pwd, $sid, $typ, $usr);

  # Determine the default group
  $agt = $slf->{'agt'};
  $usr = $agt->get_setting('SQL_LOGIN',  'SYSTEM');
  $sid = $agt->get_setting('ORACLE_SID', '');
  $grp = ($usr =~ s/\@(\S+)?.*$// && $1)       ? '' :
         ($sid =~ $EXT)                        ? check_sid($sid) :
         $agt->get_setting('DATABASE_LOCAL',1) ? uc($sid) :
                                                 '';

  # Create the default entries
  $slf->{'pwd'}->{'oracle'}->{''}->{''} = '';

  # Load the password
  foreach my $key ($agt->grep_setting('^SQL_PASSWORD_'))
  { $pwd = unpack('u', $agt->get_setting($key));
    $pwd =~ s/\r\n//g;
    if ($key =~ m/^SQL_PASSWORD__([\+\w]+)__(.*)$/)
    { $usr = $2;
      $sid = $1;
      $sid =~ s/plus/\+/g;
    }
    else
    { $usr = substr($key, 13);
      $sid = $grp;
    }
    _set_password($slf, 'oracle', $sid, uc($usr), $pwd);
  }

  foreach my $key ($agt->grep_setting('^SQL_PASS_[A-Z]*\d+$'))
  { $pwd = unpack('u', $agt->get_setting($key));
    $pwd =~ s/\r\n//g;
    $key =~ s/_PASS_/_USER_/;
    ($usr, $sid) = split(/\@/, $agt->get_setting($key), 2);
    $usr = uc($usr);
    $sid = $grp unless $sid;
    _set_password($slf, 'oracle', $sid, $usr, $pwd);
  }

  foreach my $key ($agt->grep_setting('^DBI_PASS_[A-Z]*\d+$'))
  { $pwd = unpack('u', $agt->get_setting($key));
    $pwd =~ s/\r\n//g;
    $key =~ s/_PASS_/_USER_/;
    ($usr, $typ, $sid) = split(/\@/, $agt->get_setting($key), 3);
    _set_password($slf, _norm_credential($typ, $sid, $usr), $pwd);
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>return_password($typ,$sid,$usr[,$dft])>

This method returns an existing password for the specified login.

=cut

sub return_password
{ my ($slf, $typ, $sid, $usr, $dft) = @_;

  _return_password($slf, _norm_credential($typ, $sid, $usr), $dft);
}

sub _return_password
{ my ($slf, $typ, $sid, $usr, $dft) = @_;

  _has_password($slf, $typ, $sid, $usr)
    ? $slf->{'pwd'}->{$typ}->{$sid}->{$usr}
    : $dft;
}

=head2 S<$h-E<gt>same_password($usr,$typ,@sid)>

This method assigns the current password of the specified user to all specified
systems of a same type.

=cut

sub same_password
{ my ($slf, $usr, $typ, @arg) = @_;
  my ($cnt, $pwd, $sid, $tbl, @sid);

  $cnt = 0;
  if (defined($usr) && defined($typ) && defined($sid = shift(@arg)))
  { ($typ, $sid, $usr) = _norm_credential($typ, $sid, $usr);
    if (exists($slf->{'pwd'}->{$typ}))
    { $tbl = $slf->{'pwd'}->{$typ};

      # Normalize the system identifiers
      push(@sid, $sid);
      foreach $sid (@arg)
      { next unless defined($sid);
        ($typ, $sid) = _norm_credential($typ, $sid);
        push(@sid, $sid);
      }

      # Get the password
      foreach my $sid (@sid)
      { next unless exists($tbl->{$sid}) && exists($tbl->{$sid}->{$usr});
        $pwd = $tbl->{$sid}->{$usr};
        last;
      }

      # Assign the password
      if (defined($pwd))
      { foreach my $sid (@sid)
        { _set_password($slf, $typ, $sid, $usr, $pwd);
          ++$cnt;
        }
      }
    }
  }
  $cnt;
}

=head2 S<$h-E<gt>set_password($typ,$sid,$usr,$pwd)>

This method defines a new password hash entry. It returns the password.

=cut

sub set_password
{ my ($slf, $typ, $sid, $usr, $pwd) = @_;

  _set_password($slf, _norm_credential($typ, $sid, $usr), $pwd);
}

sub _set_password
{ my ($slf, $typ, $sid, $usr, $pwd) = @_;

  $slf->{'pwd'}->{$typ}->{$sid}->{''} = ''
    unless $typ ne 'oracle' || exists($slf->{'pwd'}->{$typ}->{$sid});
  $slf->{'pwd'}->{$typ}->{$sid}->{$usr} = $pwd;
}

=head2 S<$h-E<gt>share_password($typ,$sid,...)>

This method shares the credentials between the specified systems, identified by
type and identifier pairs.

=cut

sub share_password
{ my ($slf, @arg) = @_;
  my ($cnt, $dst, $sid, $src, $typ);

  $cnt = 0;
  $dst = {};
  while (($typ, $sid) = splice(@arg, 0, 2))
  { next unless defined($typ) && defined($sid);

    # Normalize the identifiers
    ($typ, $sid) = _norm_credential($typ, $sid);

    # Merge the credentials
    if (ref($src = $slf->{'pwd'}->{$typ}->{$sid}))
    { foreach my $usr (keys(%$src))
      { $dst->{$usr} = $src->{$usr} unless exists($dst->{$usr});
      }
    }
    elsif ($typ eq 'oracle')
    { $dst->{''} = '' unless exists($dst->{''});
    }

    # Share the credentials
    $slf->{'pwd'}->{$typ}->{$sid} = $dst;
    ++$cnt;
  }
  $cnt;
}

# --- Internal routines -------------------------------------------------------

# Check the DSN
sub check_dsn
{ my ($dsn, $dft) = @_;
  my (%dsn);

  return $dft unless defined($dsn);
  return $dsn unless $dsn =~ m/=/;

  # Sort the extended DSN attributes
  foreach my $att (split(/;/, $dsn))
  { $dsn{$1} = $2 if $att =~ /\s*([^=]+)=(.*)$/;
  }
  join('', map {$_.'='.$dsn{$_}.';'} sort keys(%dsn));
}

# Check the SID
sub check_sid
{ my ($sid, $dft) = @_;

  return $dft unless $sid;
  ($sid =~ $EZC) ? join(':', $1, $2, '', uc($3)) :
  ($sid =~ $EZD) ? join(':', $1, 1521, '', uc($2)) :
  ($sid =~ $SID) ? join(':', $1, $2, uc($3)) :
  ($sid =~ $SVC) ? join(':', $1, $2, $3, uc($4)) :
                   uc($sid);
}

# Keep the connection string without transformation
sub _keep_sid
{ shift;
}

# Normalize the user, the type, and the system identifier
sub _norm_credential
{ my ($typ, $sid, $usr) = @_;

  $typ = (!defined($typ) || $typ eq '+') ? 'oracle' :
         ($typ eq '-')                   ? 'odbc' :
                                           lc($typ);
  if ($typ eq 'jdbc')
  { $sid =~ s/^[^\|]*\|//;
    $sid =~ s/^jdbc://i;
    if ($sid =~ s/^oracle\:thin\:\@//i)
    { if ($sid =~ m/\/\/([\w\.\-]+)\:(\d+)\/([\w\.\-]+)$/)
      { ($typ, $sid) = ('oracle', join(':', $1, $2, '', $3));
      }
      elsif ($sid =~ m/([\w\.\-]+)\:(\d+)\:([\w\.\-]+)$/)
      { ($typ, $sid) = ('oracle', join(':', $1, $2, $3));
      }
      else
      { $sid = 'oracle@'.$sid;
      }
    }
    elsif ($sid =~ s/^odbc\:(DSN=)?//i)
    { $typ = 'odbc';
    }
  }

  if ($typ eq 'oracle')
  { $usr = uc($usr) if defined($usr);
    $sid = check_sid($sid, '');
  }
  elsif ($typ eq 'odbc')
  { $sid = check_dsn($sid, '');
  }
  elsif ($typ eq 'host')
  { $sid = defined($sid) ? lc($sid) : '';
  }
  elsif ($typ eq 'wls' || $typ eq 'wsp')
  { $usr = defined($usr) ? lc($usr) : '';
    $sid = defined($sid) ? lc($sid) : '';
  }

  ($typ, $sid, $usr);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
