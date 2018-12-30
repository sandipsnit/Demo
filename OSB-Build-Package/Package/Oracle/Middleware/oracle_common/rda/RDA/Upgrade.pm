# Upgrade.pm: Package Used to Manage Upgrades

package RDA::Upgrade;

# $Id: Upgrade.pm,v 2.38 2012/05/30 10:22:07 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Upgrade.pm,v 2.38 2012/05/30 10:22:07 mschenke Exp $
#
# Change History
# 20120530  MSC  Upgrade to build 120530.

=head1 NAME

RDA::Upgrade - Package Used to Manage Upgrades

=head1 SYNOPSIS

require RDA::Upgrade;

=head1 DESCRIPTION

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use File::Copy;
  use IO::File;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.38 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_mod = (
  S000INI  => '120530',
  S010CFG  => '100612',
  S090OCM  => '100829',
  S100OS   => '090805',
  S110PERF => '090926',
  S120NET  => '080804',
  S122ONET => '100211',
  S200DB   => '090503',
  S204LOG  => '090807',
  S205BR   => '100806',
  S206RSRC => '061127',
  S250BEE  => '080430',
  S260OMS  => '071106',
  S290DEV  => '100928',
  S300IAS  => '080804',
  S301WREQ => '110407',
  S310J2EE => '080419',
  S313ASIT => '100504',
  S325PDA  => '100928',
  S328WC   => '110407',
  S330SSO  => '100504',
  S340OID  => '110407',
  S342OVD  => '071023',
  S353UAO  => '110407',
  S354UCM  => '110407',
  S355IPM  => '110407',
  S360CRID => '080521',
  S361OAM  => '110407',
  S362OIM  => '110407',
  S369STA  => '120110',
  S370SOA  => '110407',
  S373BPEL => '080509',
  S374BAM  => '110407',
  S379WLI  => '110407',
  S390DSCV => '110407',
  S399BIPL => '110407',
  S400RAC  => '100823',
  S400RACD => '061110',
  S402ASM  => '100806',
  S405DG   => '100806',
  S410GRID => '110407',
  S420AGT  => '091105',
  S430DBC  => '091105',
  S440EM   => '091105',
  S530SEBL => '100831',
  S545EPM  => '110407',
  S550ESS  => '110407',
  S554HPSV => '110407',
  S555HIR  => '110407',
  S556PR   => '110407',
  S557HFR  => '110407',
  S563HPL  => '110407',
  S564HFM  => '110407',
  S565FCM  => '110407',
  S571HSS  => '110407',
  S572EPMA => '110407',
  S573HSV  => '110407',
  S578HDRM => '110407',
  S730PWEB => '110204',
  S900REXE => '120425',
  S919LOAD => '110407',
);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<engine exe src>

This command updates the engine.

=cut

sub engine
{ my ($agt, $exe, $src) = @_;

  if (defined($exe) && defined($src) && -r $src)
  { my ($cfg, $dir, $dst, $eng, $lck, $sta, $vrb, @st1, @st2);

    # Initialization
    $cfg = $agt->get_config;
    $dir = dirname($exe = $cfg->cat_file($exe));
    $eng = basename($src = $cfg->cat_file($src));
    $sta = 0;
    $vrb = $agt->get_setting('RDA_VERBOSE');

    # Disable some signals
    local $SIG{'HUP'}  = 'IGNORE' if exists($SIG{'HUP'});
    local $SIG{'INT'}  = 'IGNORE' if exists($SIG{'INT'});
    local $SIG{'KILL'} = 'IGNORE' if exists($SIG{'KILL'});
    local $SIG{'PIPE'} = 'IGNORE' if exists($SIG{'PIPE'});
    local $SIG{'STOP'} = 'IGNORE' if exists($SIG{'STOP'});
    local $SIG{'TERM'} = 'IGNORE' if exists($SIG{'TERM'});
    local $SIG{'QUIT'} = 'IGNORE' if exists($SIG{'QUIT'});

    # Perform the operation
    eval {
      print "Trying to take a lock ...\n" if $vrb;
      if ($sta = _upd_lock($lck = $cfg->cat_file($dir, 'rda.lck')))
      { if (! -e $exe)
        { print "Copying the compile engine '$eng' ...\n" if $vrb;
          copy($src, $exe);
          chmod(0555, $exe);
        }
        elsif ((@st1 = stat($exe)) && (@st2 = stat($src))
          && ($st1[9] < $st2[9] || $st1[7] != $st2[7]))
        { $dst = $cfg->cat_file($dir, $eng);
          print "Copying the compile engine '$eng' ...\n" if $vrb;
          copy($src, $dst)
            or die "RDA-00091: Cannot copy the compiled engine:\n $!\n";
          print "Replacing the compile engine '$eng' ...\n" if $vrb;
          1 while unlink($exe);
          move($dst, $exe)
            or die "RDA-00092: Cannot move the compiled engine:\n $!\n";
          chmod(0555, $exe);
        }
      }
      else
      { print "Waiting for lock file removal ...\n" if $vrb;
        sleep(2) while (-e $lck);
      }
    };
    print $@ if $@ && $vrb;

    # Delete the lock file
    if ($sta > 0)
    { print "Removing the lock file ...\n" if $vrb;
      1 while unlink($lck);
    }
  }

  # Indicate that the setup should not be saved
  0;
}

# Take a lock
sub _upd_lock
{ my ($fil) = @_;
  my ($lck);

  # Check if open constants are available
  eval "require Fcntl";
  return -1 if $@;

  # Create the lock file
  $lck = IO::File->new;
  unless ($lck->open($fil, &Fcntl::O_CREAT | &Fcntl::O_EXCL))
  { die "RDA-00090: Cannot create the lock file '$fil':\n $!\n"
      unless $! =~ m/File exists/i;
    return 0;
  }
  $lck->close;
  1;
}

=head2 S<files>

This command removes the obsolete files.

=cut

sub files
{ my ($agt) = @_;
  my ($cfg, $cnt, $pth);

  # Remove the obsolete files
  $cfg = $agt->get_config;
  $cnt = 0;
  foreach my $rec ($cfg->get_obsolete('fil'))
  { next unless $rec =~ m/^(D_RDA_[A-Z]+):(.+)$/
      && -f ($pth = $cfg->get_file($1, $2));
    1 while unlink($pth);
    ++$cnt if -f $pth;
  }

  # Remove the obsolete directories
  foreach my $rec ($cfg->get_obsolete('dir'))
  { next unless $rec =~ m/^(D_RDA_[A-Z]+):(.+)$/
      && -d ($pth = $cfg->get_dir($1, $2));
    RDA::Object::Rda->delete_dir($pth);
    ++$cnt if -d $pth;
  }

  # Remove the list of obsolete files on successful cleanup
  unless ($cnt)
  { $pth = $cfg->get_file('D_RDA_DATA', 'obsolete.txt');
    1 while unlink($pth);
  }

  # Indicate that the setup should not be saved
  0;
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

  # Indicate that the setup must not be saved
  0;
}

=head2 S<setup>

This command updates the setup information.

=cut

sub setup
{ my ($agt) = @_;
  my ($bld, $flg);

  # Determine the current setup build
  $bld = $agt->get_setting('RDA_BUILD');
  $bld = '000000' unless $bld && $bld =~ m/^\d{6}$/;

  # Set temporarily the auto-configure flag
  $flg =  $agt->set_info('yes', 1);

  # Upgrade the setup configuration
  if ($bld lt '060124')
  { my ($val);

    # Move the opatch setting
    if (defined($val = $agt->del_setting('OPATCH_DIR')))
    { $agt->upd_module('S000INI');
      $agt->set_current('S130INST');
      $agt->set_setting('OPATCH_DIR', $val, 'D', 'OPatch directory');
      $agt->set_current;
    }
  }
  if ($bld lt '051123')
  { my $tbl = {};

    # Upgrade DB settings
    if ($agt->is_configured('S200DB'))
    { # Move settings to the INI module
      _get_value($agt, $tbl,
        qw(SQL_ACCESS SQL_ATTEMPTS SQL_COMMAND SQL_ERROR SQL_FORK SQL_TIMEOUT
           SQL_TRACE));
      $agt->setup('S200DB');
      _set_temp($agt, $tbl);

      # Actualize DB settings after the module split
      unless ($agt->is_configured('S201DBA') || 
              $agt->is_configured('S204LOG') || 
              $agt->is_configured('S205BR'))
      { $agt->setup('S201DBA');
        $agt->setup('S204LOG');
        $agt->setup('S205BR');
      }
    }

    # Upgrade INI settings
    $agt->setup('S000INI') if $agt->is_configured('S000INI');
  }
  if ($bld lt '051202')
  { foreach my $mod ($agt->get_config->get_modules)
    { if ($mod =~ m/^(S[2-4]\d{2}[A-Za-z]\w*)$/i &&
        $agt->get_setting("$1_SETTINGS"))
      { $agt->set_current($1);
        $agt->set_setting("$1_TITLE", 'Oracle Product Settings', 'T',
          'Title for a setting report section');
      }
    }
    $agt->set_current;
  }
  if ($bld lt '060206')
  { my $str;

    # Convert the OCS modules
    if ($agt->is_configured('S240MAIL'))
    { $agt->ren_module('S240MAIL','S241MAIL');
      $agt->set_temp_setting('OCS_AGE', $agt->get_setting('EMAIL_AGE'));
      $agt->set_temp_setting('OCS_TAIL1', $agt->get_setting('EMAIL_TAIL'));
    }
    if ($agt->is_configured('S322ECM'))
    { $agt->ren_module('S322ECM', 'S248CONT');
      $agt->set_temp_setting('CONTENT_IN_USE', $agt->get_setting('ECM_IN_USE'));
      $agt->set_temp_setting('OCS_TAIL1', $agt->get_setting('ECM_TAIL1'));
      $agt->set_temp_setting('OCS_TAIL2', $agt->get_setting('ECM_TAIL2'));
    }
    $agt->setup('S241MAIL') if $agt->is_configured('S241MAIL');
    $agt->setup('S248CONT') if $agt->is_configured('S248CONT');
    if ($str = $agt->get_setting('SQL_PASSWORD_ECM_REPOS_USER'))
    { $agt->set_current('S999END');
      $agt->del_setting('SQL_PASSWORD_ECM_REPOS_USER');
      $agt->set_setting('SQL_PASSWORD_CONTENT_REPOS_USER', $str, 'T',
        "Password for 'CONTENT_REPOS_USER'");
      $agt->set_current;
    }
  }
  if ($bld lt '061003')
  { # Configure the LOAD module
    if ($agt->is_configured('S909RDSP'))
    { $agt->set_temp_setting('NO_LOAD', $agt->get_setting('NO_EXTRA'));
      $agt->setup('S909RDSP');
      $agt->setup('S919LOAD');
    }
  }
  if ($bld lt '061004')
  { my $tbl = {};

    # Split RAC module
    if ($agt->is_configured('S400RAC'))
    { _get_value($agt, $tbl,
        qw(CLUSTER_FACTOR CLUSTER_HANG_CHECK CLUSTER_PARALLEL CLUSTER_REPEAT
           CLUSTER_SLEEP));
      $agt->setup('S400RAC');
      _set_temp($agt, $tbl);
      $agt->setup('S400RACD');
    }
  }
  if ($bld lt '061127')
  { my $tbl = {};

    # Move the LDAP settings
    if ($agt->is_configured('S241MAIL'))
    { $agt->set_temp_setting('OCS_IN_USE',
        $agt->get_setting('EMAIL_SERVER_IN_USE'));
      _get_value($agt, $tbl, qw(LDAP_HOST LDAP_PORT LDAP_DOMAIN));
      $agt->setup('S241MAIL');
      _set_temp($agt, $tbl);
      $agt->setup('S240OCS');
    }
  }
  if ($bld lt '071008')
  { # Rename the OLAP/OES module
    if ($agt->is_configured('S210OLAP'))
    { $agt->ren_module('S210OLAP', 'S215OES');
      _xfr_value($agt, {EXPRESS_IN_USE => 'OLAP_IN_USE'});
      $agt->setup('S215OES');
      $agt->setup('S210OLAP');
    }
  }
  if ($bld lt '080804')
  { # Split the NET module
    if ($agt->is_configured('S120NET'))
    { _xfr_value($agt, {
        ONET_IN_USE     => 'DATABASE_INSTALLED',
        ONET_LOG_SIZE   => 'NETWORK_LOG_SIZE',
        ONET_TRACE_AGE  => 'NETWORK_TRACE_AGE',
        ONET_TRACE_SIZE => 'NETWORK_TRACE_SIZE',
        });
      $agt->setup('S122ONET');
    }
  }
  if ($bld lt '091105')
  { # Upgrade the GRID module
    if ($agt->is_configured('S440EM'))
    { _xfr_value($agt, {
        GRID_SERVER_HOME   => 'O_HOME_1',
        GRID_PING_TEST     => 'EM_PING_TEST',
        GRID_PING_LIST     => 'EM_PING_LIST',
        GRID_AUDIT_AGE     => 'EM_AUDIT_AGE',
        GRID_VIOLATION_AGE => 'EM_VIOLATION_AGE',
        });
      $agt->set_temp_setting('GRID_EMDIAG_IN_USE', 1);
      $agt->setup('S410GRID');
      $agt->setup('S440EM');
    }
    elsif ($agt->is_configured('S410GRID'))
    { _xfr_value($agt, {GRID_SERVER_HOME => 'O_HOME_1'});
      $agt->setup('S410GRID');
    }

    # Upgrade the AGT module
    if ($agt->is_configured('S420AGT'))
    { _xfr_value($agt, {AGT_HOME => 'AGT_AGENT_STATE_DIR'});
      $agt->setup('S420AGT');
    }

    # Upgrade the DBC module
    if ($agt->is_configured('S430DBC'))
    { my ($val);

      $agt->set_temp_setting('DBC_BASE',
        basename(RDA::Object::Rda->cat_dir($val)))
        if defined($val = $agt->get_setting('O_HOME_3'));
      $agt->setup('S430DBC');
    }
  }
  if ($bld lt '100612')
  { $agt->set_current('S999END');
    $agt->set_setting('S999END_MRC', 0, 'B', 'Multi-run collection indicator')
      unless defined($agt->get_setting('S999END_MRC'));
    $agt->set_current;
  }
  if ($bld lt '100806')
  { my ($nam, $typ);

    if ($agt->is_configured('S362OIM')
      && defined($nam = $agt->set_setting('OIM_ITRESOURCE_NAME'))
      && defined($typ = $agt->set_setting('OIM_ITRESOURCE_TYPE'))
      && !defined($agt->get_setting('OIM_RESOURCES')))
    { $agt->set_current('S362OIM');
      $agt->set_setting('OIM_RESOURCES', "$typ-$nam",
        'T', 'List of requested IT Resource type-name combinations');
      $agt->set_current;
    }
  }
  if ($bld lt '110103')
  { # Rename the WCI module
    if ($agt->is_configured('S328WCI') && !$agt->is_configured('S328WC'))
    { $agt->ren_module('S328WCI', 'S328WC');
      _xfr_value($agt, {WC_ALT_JDK       => 'WCI_ALT_JDK',
                        WC_DISTINCT_HOME => 'WCI_DISTINCT_HOME',
                        WC_INTERIM       => 'WCI_INTERIM',
                        WC_IN_USE        => 'WCI_IN_USE',
                        WC_JDK           => 'WCI_JDK',
                        WC_ORACLE_HOME   => 'WCI_ORACLE_HOME'});
      $agt->setup('S328WC');
    }
  }
  if ($bld lt '111120')
  { if ($agt->is_configured('S211EXA') && !$agt->is_configured('S280EXA'))
    { $agt->ren_module('S211EXA', 'S280EXA');
      $agt->setup('S280EXA');
    }
  }

  # Update individual modules
  foreach my $mod (sort keys(%tb_mod))
  { $agt->setup($mod) if $bld lt $tb_mod{$mod} && $agt->is_configured($mod);
  }

  # Restore the auto-configure flag
  $agt->set_info('yes', $flg);

  # Indicate that the setup must be saved
  1;
}

sub _get_value
{ my $agt = shift;
  my $tbl = shift;
  my $val;

  foreach my $key (@_)
  { $tbl->{$key} = $val if defined($val = $agt->get_setting($key));
  }
}

sub _set_temp
{ my $agt = shift;
  my $tbl = shift;

  foreach my $key (keys(%$tbl))
  { $agt->set_temp_setting($key, $tbl->{$key});
  }
}

sub _xfr_value
{ my ($agt, $tbl) = @_;
  my ($val);

  foreach my $key (keys(%$tbl))
  { $agt->set_temp_setting($key, $val)
      if defined($val = $agt->get_setting($tbl->{$key}));
  }
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
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
