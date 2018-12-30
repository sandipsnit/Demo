# Odi.pm: Interface to Oracle Data Integrator

package RDA::Extern::Odi;

# $Id: Odi.pm,v 2.6 2012/04/25 07:08:47 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extern/Odi.pm,v 2.6 2012/04/25 07:08:47 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Extern::Odi - Interface to Oracle Data Integrator

=head1 SYNOPSIS

require RDA::Extern::Odi;

=head1 DESCRIPTION

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
  use RDA::Object::Xml;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);

# Define the global private variables
my $MRP = 'ODI_M';
my $WRP = 'ODI_W';

my $ERR = "Therefore, this module cannot Oracle Data Integrator information.";
my $WRN = "Therefore, this module has only limited information access.";

my %tb_err = (
  1  => "Cannot extract login from 'odiparams.sh'. $WRN",
  2  => "Cannot extract login from 'odiparams.bat'. $WRN",
  4  => "Cannot extract logins from 'snps_login_security.xml'. $WRN",
  5  => "Cannot extract logins from 'odiparams.sh' and ".
        "'snps_login_security.xml'. $ERR",
  6  => "Cannot extract logins from 'odiparams.bat' and ".
        "'snps_login_security.xml'. $ERR",
  8  => "Cannot extract logins from 'snps_login_work.xml'. $WRN",
  9  => "Cannot extract logins from 'odiparams.sh' and ".
        "'snps_login_work.xml'. $ERR",
  10 => "Cannot extract logins from 'odiparams.bat' and ".
        "'snps_login_work.xml'. $ERR",
  );
my %tb_sta = (
  1  => 1,
  2  => 1,
  4  => 1,
  5  => 2,
  6  => 2,
  8  => 1,
  9  => 2,
  10 => 2,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Extern::Odi::search_master($agt,$hom,$typ)>

This method searches Oracle Data Integrator master repositories in the
F<$ODI_HOME/bin/odiparams.(bat|sh)> and
F<$ODI_HOME/bin/snps_login_security.xml> files.

=cut

sub search_master
{ my ($agt, $hom, $typ) = @_;
  my ($err, $off, $val, @tbl);

  $err = 0;

  # Extract login information from odiparams.(bat|sh)
  if ($typ eq "ODI10")
  { ($off, $val) = (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
     ? (2, _grep_value(RDA::Object::Rda->cat_file($hom, 'bin', 'odiparams.bat'),
                       qr/^\s*set ODI_SECU_USER=(.+)/i))
     : (1, _grep_value(RDA::Object::Rda->cat_file($hom, 'bin', 'odiparams.sh'),
                       qr/^\s*ODI_SECU_USER=([^#]+)/));
  }
  else
  { ($off, $val) = (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
     ? (2, _grep_value(RDA::Object::Rda->cat_file($hom, 'agent', 'bin',
                                                  'odiparams.bat'),
                       qr/^\s*set ODI_MASTER_USER=(.+)/i))
     : (1, _grep_value(RDA::Object::Rda->cat_file($hom, 'agent', 'bin',
                                                  'odiparams.sh'),
                       qr/^\s*ODI_MASTER_USER=([^#]+)/));
  }
  if (defined($val) && length($val))
  { $agt->set_temp_setting("$MRP\_LOGIN", '[odiparams]');
    push(@tbl, $MRP);
  }
  else
  { $err |= $off;
  }

  # Extract login information from snps_login_security.xml
  if ($typ eq "ODI10")
  { $err |= 4 unless _extract_logins($agt, \@tbl,
     RDA::Object::Rda->cat_file($hom, 'bin', 'snps_login_security.xml'), $MRP);
  }

  # Create the identifier list
  $agt->set_temp_setting('ODI_MASTER_SET', join(',', @tbl));

  # Indicate the result
  $agt->set_temp_setting('ODI_MASTER_ERROR', $tb_err{$err})
    if exists($tb_err{$err});
  exists($tb_sta{$err}) ? $tb_sta{$err} : 0;
}

=head2 S<RDA::Extern::Odi::search_work($agt,$hom,$typ)>

This method searches Oracle Data Integrator work repositories in the
F<$ODI_HOME/bin/odiparams.(bat|sh)> and F<$ODI_HOME/bin/snps_login_work.xml>
files.

=cut

sub search_work
{ my ($agt, $hom, $typ) = @_;
  my ($err, $fil, $off, $val, @tbl);

  $err = 0;

  # Extract login information from odiparams.(bat|sh)
  if ($typ eq "ODI10" || $typ eq "AGENT")
  { if ($typ eq "ODI10")
    { ($off, $val) = (RDA::Object::Rda->is_windows || 
                      RDA::Object::Rda->is_cygwin)
       ? (2, _grep_value(RDA::Object::Rda->cat_file($hom, 'bin',
                                                    'odiparams.bat'),
                         qr/^\s*set ODI_SECU_WORK_REP=(.+)/i))
       : (1, _grep_value(RDA::Object::Rda->cat_file($hom, 'bin',
                                                    'odiparams.sh'),
                         qr/^\s*ODI_SECU_WORK_REP=([^#]+)/));
    }
    else
    { ($off, $val) = (RDA::Object::Rda->is_windows ||
                      RDA::Object::Rda->is_cygwin)
       ? (2, _grep_value(RDA::Object::Rda->cat_file($hom, 'agent', 'bin',
                                                    'odiparams.bat'),
                         qr/^\s*set ODI_SECU_WORK_REP=(.+)/i))
       : (1, _grep_value(RDA::Object::Rda->cat_file($hom, 'agent', 'bin',
                                                    'odiparams.sh'),
                         qr/^\s*ODI_SECU_WORK_REP=([^#]+)/));
    }
    if (defined($val) && length($val))
    { $agt->set_temp_setting("$WRP\_LOGIN", '[odiparams]');
      push(@tbl, $WRP);
    }
    else
    { $err |= $off;
    }
  }

  # Extract login information from snps_login_work.xml
  if ($typ eq "ODI10" || $typ eq "STUDIO")
  { if ($typ eq "ODI10")
    { $fil = RDA::Object::Rda->cat_file($hom, 'bin', 'snps_login_work.xml');
    }
    else
    { $fil = (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
       ? RDA::Object::Rda->cat_file($ENV{'APPDATA'}, 'odi', 'oracledi',
                                    'snps_login_work.xml')
       : RDA::Object::Rda->cat_file($ENV{'HOME'}, '.odi', 'oracledi',
                                    'snps_login_work.xml');
    }
    $err |= 8 unless _extract_logins($agt, \@tbl, $fil, $WRP);
  }

  # Create the identifier list
  $agt->set_temp_setting('ODI_WORK_SET', join(',', @tbl));

  # Indicate the result
  $agt->set_temp_setting('ODI_WORK_ERROR', $tb_err{$err})
    if exists($tb_err{$err});
  exists($tb_sta{$err}) ? $tb_sta{$err} : 0;
}

# --- Internal routines -------------------------------------------------------

# Extract logins from a XML file
sub _extract_logins
{ my ($agt, $tbl, $fil, $pre) = @_;
  my ($cnt, $nam, $num, $top);

  $cnt = 0;
  $top = RDA::Object::Xml->new->parse_file($fil);
  foreach my $xml ($top->find('SnpsLogin/Object'))
  { ($num) = $xml->find('Field name="ILogin"');
    ($nam) = $xml->find('Field name="LoginName"');
    next unless ref($num) && ref($nam);
    $num = sprintf("%s%d", $pre, $num->get_data);
    $agt->set_temp_setting("$num\_LOGIN", $nam->get_data);
    push(@$tbl, $num);
    ++$cnt;
  }
  $cnt;
}

# Grep a value from a file
sub _grep_value
{ my ($fil, $pat) = @_;
  my $val;

  if (open(FIL, "<$fil"))
  { while (<FIL>)
    { if ($_ =~ $pat)
      { $val = $1;
        $val =~ s#[\n\r\s]+$##; #
        $val = $2 if $val =~ m/([\'\"])(.*?)\1/;
        last;
      }
    }
    close(FIL);
  }
  $val;
}

1;

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
