# Apex.pm: Interface to Get APEX Configuration Information

package RDA::Extern::Apex;

# $Id: Apex.pm,v 2.6 2012/01/02 16:32:38 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extern/Apex.pm,v 2.6 2012/01/02 16:32:38 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Extern::Apex - Interface to Get APEX Configuration Information

=head1 SYNOPSIS

require RDA::Extern::Apex;

=head1 DESCRIPTION

The following method is available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Agent;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define global constants
my $FMT = '\\s*PlsqlDatabaseConnectString\\s*(.*)\\s+'
  .'(((Net)?ServiceName|SID|TNS)Format)';

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Extern::Apex::get_db_set($agt,$cfg)>

This method extracts the details of all different database connections from the
configuration file. It attempts to preserve collection indications provided in
the previous setup run. It returns the database identifier list.

=cut

sub get_db_set
{ my ($agt, $cfg) = @_;
  my ($cnt, $fmt, $hst, $itm, $loc, $prt, $sid, $val,
      @set, @tb_sid, %tb_flg, %tb_dba, %tb_fmt, %tb_loc, %tb_usr);

  # Get the previous settings
  foreach $itm (split(/\|/, $agt->get_setting('APEX_DB_SET', '')))
  { next unless $itm && ($sid = $agt->get_setting("APEX_SID_$itm"));
    $tb_flg{$sid} = $agt->get_setting("APEX_FLAG_$itm");
    $tb_usr{$sid} = $agt->get_setting("APEX_USER_$itm");
    $tb_dba{$sid} = $agt->get_setting("APEX_SYSDBA_$itm");
  }

  # Extract database connection details from the configuration file
  if (open(IN, "<$cfg"))
  { while (<IN>)
    { next if m/^<!--/;
      if (m/^<Location\s*(.*)>$/i)
      { $loc = $1;
      }
      elsif ($_ =~ $FMT)
      { ($sid, $fmt) = ($1, $2);
        if ($fmt =~ m/ServiceNameFormat/i)
        { $sid =~ s/(.*:.*):(.*)/$1::\U$2\E/;
        }
        elsif ($fmt =~ m/TNSFormat/i)
        { $hst = ($sid =~ m/HOST\s*=\s*([^\051]+)/i) ? $1 : undef;
          $prt = ($sid =~ m/PORT\s*=\s*([^\051]+)/i) ? $1 : 0;
          if ($sid =~ m/SERVICE_NAME\s*=\s*([^\051]+)/i)
          { $sid = $hst.":".$prt."::".uc($1) if $hst && $prt;
          }
          elsif ($sid =~ m/SID_NAME\s*=\s*([^\051]+)/i)
          { $sid = $hst.":".$prt.":".uc($1) if $hst && $prt;
          }
        }
        if (exists($tb_fmt{$sid}))
        { push(@{$tb_fmt{$sid}}, $fmt);
          push(@{$tb_loc{$sid}}, $loc);
        }
        else
        { $tb_fmt{$sid} = [$fmt];
          $tb_loc{$sid} = [$loc];
          push(@tb_sid, $sid);
        }
      }
    }
    close(IN);
  }

  # Generate the temporary settings
  $cnt = 0;
  foreach $sid (@tb_sid)
  { push(@set, $itm = 'DB'.++$cnt);
    $agt->set_temp_setting("APEX_SID_$itm", $sid);
    $agt->set_temp_setting("APEX_FLAG_$itm", $tb_flg{$sid})
      if exists($tb_flg{$sid});
    $agt->set_temp_setting("APEX_FORMAT_$itm", join(', ', @{$tb_fmt{$sid}}))
      if exists($tb_fmt{$sid});
    $agt->set_temp_setting("APEX_LOC_$itm", join(', ', @{$tb_loc{$sid}}))
      if exists($tb_loc{$sid});
    $agt->set_temp_setting("APEX_SYSDBA_$itm", $tb_dba{$sid})
      if exists($tb_dba{$sid});
    $agt->set_temp_setting("APEX_USER_$itm", $tb_usr{$sid})
      if exists($tb_usr{$sid});
  }

  # Return the database identifier list
  join('|', @set);
}

1;

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
