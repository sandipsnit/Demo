# PrRegRd.pm: Interface to IntegRate Framework Registry

package RDA::Extern::PrRegRd;

# $Id: PrRegRd.pm,v 2.8 2012/05/11 11:05:58 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extern/PrRegRd.pm,v 2.8 2012/05/11 11:05:58 mschenke Exp $
#
# Change History
# 20120510  KRA  Extend BRM version detection.

=head1 NAME

RDA::Extern::PrRegRd - Interface to IntegRate Framework Registry

=head1 SYNOPSIS

require RDA::Extern::PrRegRd;

=head1 DESCRIPTION

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::Handle;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 2.8 $ =~ /(\d+)\.(\d+)/);

# Define the global private variables
my $STATUS;                   # Initialization status
my $ROOT_NAME  = "ifw";       # Name of the root node in the pipeline registry
my $ROOT_TIMOS = "timosMgr";  # Name of the root node in the timos registry

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Extern::PrRegRd-E<gt>check_package([$dir...])>

This method checks if the package can be initialialized to extract information
from registry files. Additional directories can be specified to locate the
required Perl packages. It returns an empty string when successful, otherwise,
the error message.

=cut

sub check_package
{ my $slf = shift;

  return $STATUS if defined($STATUS);
  eval {
    require Registry::RegistryEntry;
    require Registry::RegistryLexer;
  };
  if ($@)
  { foreach my $dir (@_)
    { next unless -d $dir;
      push(@INC, $dir);
      if (-d RDA::Object::Rda->cat_dir($dir, 'Registry'))
      { eval {
          require Registry::RegistryEntry;
          require Registry::RegistryLexer;
        };
        return $STATUS = $@ unless $@;
      }
      elsif (-f RDA::Object::Rda->cat_file($dir, 'Lex.pm'))
      { eval {
          require Template;
          $INC{'Parse/Template.pm'} = $INC{'Template.pm'};
          require Trace;
          $INC{'Parse/Trace.pm'} = $INC{'Trace.pm'};
          require Token;
          $INC{'Parse/Token.pm'} = $INC{'Token.pm'};
          require ALex;
          $INC{'Parse/ALex.pm'} = $INC{'ALex.pm'};
          require Lex;
          $INC{'Parse/Lex.pm'} = $INC{'Lex.pm'};
          require RegistryEntry;
          $INC{'Registry/RegistryEntry.pm'} = $INC{'RegistryEntry.pm'};
          require RegistryLexer;
          $INC{'Registry/RegistryLexer.pm'} = $INC{'RegistryLexer.pm'};
        };
        return $STATUS = $@ unless $@;
      }
      pop(@INC);
    }
  }
  $STATUS = $@;
}

=head2 S<RDA::Extern::PrRegRd-E<gt>get_release($dir...)>

This method determines the product release. The Pipeline Manager directory must
be provided as first argument. It first tries to get the release by executing
C<ifw -v>, next to derive it from the path of the specified directories, 
otherwise, C<undef> is returned.

=cut

sub get_release
{ my ($ctx, $dir, @dir) = @_;
  my ($ifh);

  # Try to get the release by executing 'ifw -v'
  $ifh = IO::Handle->new;
  if ($dir && -d $dir
    && open($ifh, '"'.RDA::Object::Rda->cat_file($dir, 'bin', 'ifw')
                 .'" -v 2>&1 |'))
  { while (<$ifh>)
    { return $1
        if m#Pipeline\s+Server\s+/\s+Version\s+(\d+(\.\d+){1,})#;
    }
    close($ifh)
  }

  # Try to get the release by executing 'pinrev'
  if ($dir && -d $dir
    && open($ifh, '"'.RDA::Object::Rda->cat_file($dir, 'bin', 'pinrev')
                 .'" 2>&1 |'))
  { while (<$ifh>)
    { if ( m#^PRODUCT_NAME="?(Infranet|Portal)_Base# )
      { return $1 if <$ifh> =~ m#^VERSION="?(\d+(\.\d+){1,})#;
      }
    }
    close($ifh)
  }

  # Try to derive it from the profile
  return "$1.$2" if $ctx->get_agent->get_setting('RDA_PROFILE', '')
    =~ m/\bSupportInformer(7)(\d+)\b/;

  # Otherwise, try to derive it from the path
  foreach my $pth ($dir, @dir)
  { return $2 if $pth && $pth =~ m#/(brm|portal)/?(\d+(\.\d+){1,})($|/)#;
  }

  # Indicate that no release has been identified
  undef;
}

=head2 S<RDA::Extern::PrRegRd::read_registry($context,$registry)>

This method extracts registry information and returns it as a hash reference.

=cut

sub read_registry
{ my ($ctx, $reg) = @_;
  my ($err, $fmt, $grp, $inf, $nod, $top);

  $inf = {};

  # Parse Registry
  eval {$top = Registry::RegistryLexer::registryNew($ROOT_NAME, $reg, "");};
  eval {$top = RegistryLexer::registryNew($ROOT_NAME, $reg, "");}
    if ($err = $@);
  die $err if $@;

  # Read Info-Registry
  $nod = _get_node($top, "Registry");
  $inf->{'Info'} = _read_infos($ctx, $nod);

  # Read Process-Log
  $nod = _get_node($top, "ProcessLog");
  $nod = _get_node($nod, "Module");
  $nod = _get_node($nod, "ITO");
  $inf->{'Process'} = _read_infos($ctx, $nod);

  # Read Formats
  $nod = _get_node($top, "Pipelines");
  my $itr = new RegistryIterator($nod);
  while (my $fmt = $itr->next())
  { next if $fmt->getName() eq "Instances";

    # Read Format-Log
    $nod = _get_node($fmt, "PipelineLog");
    $nod = _get_node($nod, "Module");
    $nod = _get_node($nod, "ITO");
    push(@{$inf->{'FormatLogs'}}, _read_infos($ctx, $nod));

    # Read Format-Descs
    $nod = _get_node($fmt, "EdrFactory");
    $nod = _get_node($nod, "Description");
    $inf->{'FormatDescs'}->{_read_value($ctx, $nod)} = 0;

    if ($grp = _get_node($fmt, "DataDescription", 1))
    { my ($cnf, $it1, $it2, $itm, $mod, $nam, $spc);

      $it1 = new RegistryIterator($grp);
      while ($itm = $it1->next())
      { if (($nam = _get_node($itm, "ModuleName", 1)) &&
            ($mod = _get_node($itm, "Module", 1)))
        { $nam = $nam->getValue();
          if ($nam eq 'Standard')
          { foreach my $typ (qw(StreamFormats InputMapping OutputMapping))
            { next unless ($nod = _get_node($mod, $typ, 1));
              $it2 = new RegistryIterator($nod);
              $inf->{'FormatDescs'}->{_read_value($ctx, $nod)} = 0
                while ($nod = $it2->next());
            }
          }
          elsif ($nam eq 'ASN')
          { foreach my $typ (qw(StreamFormats InputMapping OutputMapping))
            { next unless ($nod = _get_node($mod, $typ, 1));
              $it2 = new RegistryIterator($nod);
              while ($nod = $it2->next())
              { if (($cnf = _get_node($nod, 'ConfFile', 1)) &&
                    ($spc = _get_node($nod, 'SpecFile', 1)))
                { $inf->{'FormatDescs'}->{_read_value($ctx, $cnf)} = 0;
                  $inf->{'FormatDescs'}->{_read_value($ctx, $spc)} = 0;
                }
              }
            }
          }
        }
        else
        { $nam = $itm->getName();
          if ($nam eq 'StreamFormats' ||
              $nam eq 'InputMapping' ||
              $nam eq 'OutputMapping')
          { $it2 = new RegistryIterator($itm);
            $inf->{'FormatDescs'}->{_read_value($ctx, $nod)} = 0
              while ($nod = $it2->next());
          }
        }
      }
    }

    $nod = _get_node($fmt, "Input");
    $nod = _get_node($nod, "InputModule");
    $nod = _get_node($nod, "Module");
    $inf->{'FormatDescs'}->{_read_value($ctx, $nod)} = 0
      if ($nod = _get_node($nod, "Grammar", 1));

    $grp = _get_node($fmt, "Output");
    $nod = _get_node($grp, "OutputCollection");
    my $itr = new RegistryIterator($nod);
    while (my $mod = $itr->next())
    { $nod = _get_node($mod, "Module");
      $inf->{'FormatDescs'}->{_read_value($ctx, $nod)} = 0
        if ($nod = _get_node($nod, "Grammar", 1));
    }
    $nod = _get_node($grp, "OutputLog");
    push(@{$inf->{'StreamLogs'}}, _read_infos($ctx, $nod));
  }

  # Return collected information
  $inf;
}

# Get a sub node
sub _get_node
{ my ($nod, $ent, $opt) = @_;
  my ($sub);

  $sub = $nod->findNode($ent);
  die "  RegistryEntry not found: ".$nod->getName().".$ent\n"
    unless defined($sub) || $opt;
  $sub;
}

# Read infos
sub _read_infos
{ my ($ctx, $nod) = @_;
  my ($inf, $nam, $pre, $pth, $rpt, $suf);

  $pth = _get_node($nod, "FilePath");
  $nam = _get_node($nod, "FileName");
  $pre = _get_node($nod, "FilePrefix", 1);
  $suf = _get_node($nod, "FileSuffix", 1);
  $inf = {
    Name   => $nam->getValue(),
    Path   => $pth->getValue(),
    Prefix => defined($pre) ? $pre->getValue() : '',
    Suffix => defined($suf) ? $suf->getValue() : '',
  };
  
  $rpt->write('  '.RDA::Object::Rda->cat_file($inf->{'Path'},
    $inf->{'Prefix'}.$inf->{'Name'}.$inf->{'Suffix'})."\n")
    if ($rpt = $ctx->get_report);
  $inf;
}

# Read a value
sub _read_value
{ my ($ctx, $nod) = @_;
  my ($rpt);

  my $dat = $nod->getValue();

  $rpt->write("  $dat\n") if ($rpt = $ctx->get_report);
  $dat;
}

=head2 S<RDA::Extern::PrRegRd::read_timos($context,$registry)>

This method extracts C<timos> registry information and returns it as a hash
reference.

=cut

sub read_timos
{ my ($ctx, $reg) = @_;
  my ($err, $fmt, $grp, $inf, $nod, $top);

  $inf = {};

  # Parse Registry
  eval {$top = Registry::RegistryLexer::registryNew($ROOT_TIMOS, $reg, "");};
  eval {$top = RegistryLexer::registryNew($ROOT_TIMOS, $reg, "");}
    if ($err = $@);
  die $err if $@;

  # Get the pin log file
  $nod = _get_node($top, "PinLogFile");
  $inf->{'PinLog'}->{_read_value($ctx, $nod)} = 0;

  # Get the log server file
  $nod = _get_node($top, "LogServer");
  $nod = _get_node($nod, "Module");
  $nod = _get_node($nod, "ITO");
  $inf->{'LogServer'} = _read_infos($ctx, $nod);

  # Return collected information
  $inf;
}

=head2 S<RDA::Extern::PrRegRd::set_reg_sets($agt,$int)>

This method creates settings for multi home registries.

=cut

sub set_reg_sets
{ my ($agt, $int) = @_;
  my ($cnt, $dir, $reg, $set, $val, @set, %tbl);

  # Get the previous settings
  if ($val = $agt->get_setting('BRM_REG_SETS'))
  { foreach $set (split(/\|/, $val))
    { $dir = $agt->get_setting("BRM_INT_$set");
      $reg = $agt->get_setting("BRM_REG_$set");
      $tbl{$reg} = $dir if $dir && $reg;
    }
  }

  # Generate the temporary settings
  if ($val = $agt->get_setting('BRM_REGISTRY'))
  { $cnt = 0;
    foreach $reg (split(/\|/, $val))
    { push(@set, $set = 'REG'.++$cnt);
      $agt->set_temp_setting("BRM_REG_$set", $reg);
      if (exists($tbl{$reg}))
      { $dir = $tbl{$reg};
      }
      else
      { $dir = $int || '';
        while (length($reg = dirname($reg)) > 1)
        { if (-d RDA::Object::Rda->cat_dir($reg, 'log'))
          { $dir = $reg;
            last;
          }  
        }  
      }
      $agt->set_temp_setting("BRM_INT_$set", $dir);
    }
  }
  join('|', @set);
}

1;

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
