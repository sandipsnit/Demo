# Prepare.pm: Class Used for Objects to Prepare the Setup

package IRDA::Prepare;

# $Id: Prepare.pm,v 1.22 2012/04/25 07:16:30 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/IRDA/Prepare.pm,v 1.22 2012/04/25 07:16:30 mschenke Exp $
#
# Change History
# 20120422  MSC  Apply agent changes.

=head1 NAME

IRDA::Prepare - Class Used for Objects to Prepare the Setup

=head1 SYNOPSIS

require IRDA::Prepare;

=head1 DESCRIPTION

The objects of the C<IRDA::Prepare> class are used to prepare the setup of
the Remote Diagnostic Agent (RDA) data collection.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);

# Define the global private constants

# Define the global private variables
my %tb_req = (
  HASH => '_hsh',
  MAP  => '_map',
  RULE => '_req',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = IRDA::Prepare-E<gt>new($agt,$ver[,$trc])>

The object constructor. This method enables you to specify the agent reference,
the call interface version, and the trace indicator as extra arguments.

C<IRDA::Prepare> is represented by a blessed hash reference. The following
special keys are used:

=over 16

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'def' > > Plug-in definitions

=item S<    B<'edt' > > Collection settings

=item S<    B<'err' > > Error buffer

=item S<    B<'mod' > > List of modules to collect

=item S<    B<'trc' > > Trace indicator

=item S<    B<'ver' > > Call interface version

=item S<    B<'_inp'> > Request parameters

=item S<    B<'_dsc'> > Discovery rule definitions

=item S<    B<'_hsh'> > Hash definitions

=item S<    B<'_map'> > Mapping definitions

=item S<    B<'_req'> > Requirement rule definitions

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, $ver, $trc) = @_;

  # Create the object and return its reference
  bless {
    agt  => $agt,
    def  => {},
    edt  => {},
    err  => [],
    mod  => [],
    trc  => $trc,
    ver  => $ver,
    _dsc => {dft => [], sel => [], seq => []},
    _inp => {},
    _map => {},
    _req => {},
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>apply_selections>

This method discovers the rule selection settings, builds with the values from
the list of RDA modules to collect and sets the module settings, linked to the
rule selections.

=cut

sub apply_selections
{ my ($slf) = @_;
  my ($agt, $met, $nam, $rul, $top, $trc, $var, %mod);
  
  $agt = $slf->{'agt'};
  $top = $slf->{'_dsc'};
  $trc = $slf->{'trc'};

  # Consider default modules
  %mod = map {$_ => 0} @{$top->{'dft'}};

  # Apply selection rules
  foreach my $sel (@{$top->{'sel'}})
  { # Find the rule selection setting and discover its value
    ($nam, $met) = @$sel;
    print "[Prepare/Selection] Discover '$nam'\n" if $trc;
    $rul = $slf->discover_value($nam, $met);
    next unless defined($rul) && length($rul);

    # Load the modules in the module list and set the settings
    if (exists($slf->{'_req'}->{$rul}))
    { print "[Prepare/Selection] Apply rule '$rul' for '$nam'\n" if $trc;
      $rul = $slf->{'_req'}->{$rul};
      foreach my $key (keys(%$rul))
      { if ($key eq '*')
        { map {$mod{$_} = 1} @{$rul->{$key}};
        }
        else
        { $agt->set_temp_setting($key, $rul->{$key});
        }
      }
    }
    else
    { print "[Prepare/Selection] Skip rule '$rul' for '$nam'\n" if $trc;
    }
  }

  # Generate the module list
  $slf->{'mod'} = [sort keys(%mod)];
  print "[Prepare/Selection] Module list: ".join(",", @{$slf->{'mod'}})."\n"
    if $trc;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>apply_settings>

This method applies the collection settings.

=cut

sub apply_settings
{ my ($slf) = @_;
  my ($agt, $tbl, $val);

  $agt = $slf->{'agt'};
  foreach my $key (keys(%{$tbl = $slf->{'edt'}}))
  { $agt->set_temp_setting($key, $val) if defined($val = $tbl->{$key});
  }
}

=head2 S<$h-E<gt>check_rules($flg)>

This method checks the rule files for completeness and correctness.

=cut

sub check_rules
{ my ($slf, $flg) = @_;
  my ($agt, $cnt, $dsp, $lgt, $max, $met, $nam, $tbl, @tbl, %bad, %tbl);

  $agt = $slf->{'agt'};
  $dsp = $agt->get_display;
  $cnt = 0;

  # Report syntax errors
  print join("\n  ", 'Errors detected in rule files', @{$slf->{'err'}})."\n"
    if ($cnt = @{$slf->{'err'}});

  # Check the presence of mandatory informations
  unless (@{$slf->{'_dsc'}->{'sel'}})
  { print "\n" if $cnt++;
    print "Missing selectors\n";
  }
  unless (keys(%{$slf->{'_req'}}))
  { print "\n" if $cnt++;
    print "Missing requirement rules\n";
  }

  # Check the module existence
  %bad = ();
  foreach my $mod ($slf->{'agt'}->get_config->get_modules())
  { $tbl{$1} = 1 if $mod =~ m/^(S\d{3}\w+)$/;
  }
  foreach my $mod (@{$slf->{'_dsc'}->{'dft'}})
  { push(@{$bad{$mod}}, 'Default') unless exists($tbl{$mod});
  }
  foreach my $rul (sort (keys(%{$slf->{'_req'}})))
  { foreach my $mod(@{$slf->{'_req'}->{$rul}->{'*'}})
    { push(@{$bad{$mod}}, "[RULE.$rul]") unless exists($tbl{$mod});
    }
  }
  if (@tbl = sort keys(%bad))
  { print "\n" if $cnt++;
    print "Invalid Modules:\n";
    foreach my $mod (@tbl)
    { $dsp->dsp_string(sprintf("  %-8s  ", $mod), join(', ', @{$bad{$mod}}));
    }
  }

  # Check the plugin existence
  %bad = ();
  $tbl = $slf->{'def'};
  foreach my $rec (@{$slf->{'_dsc'}->{'sel'}})
  { ($nam, $met) = @$rec;
    push(@{$bad{$met}}, $nam) unless exists($tbl->{$met});
  }
  foreach my $mod(@{$slf->{'_dsc'}->{'seq'}})
  { next unless exists($slf->{'_dsc'}->{'mod'}->{$mod});
    foreach my $rec (@{$slf->{'_dsc'}->{'mod'}->{$mod}})
    { ($nam, $met) = @$rec;
      push(@{$bad{$met}}, "[$mod]$nam") unless exists($tbl->{$met});
    }
  }
  if (@tbl = sort keys(%bad))
  { print "\n" if $cnt++;
    print "Missing Plugins:\n";
    $max = 0;
    foreach my $met (@tbl)
    { $max = $lgt if ($lgt = length($met)) > $max;
    }
    foreach my $met (@tbl)
    { $dsp->dsp_string(sprintf("  %-*s  ", $max, $met),
        join(', ', @{$bad{$met}}));
    }
  }

  # Check mapping/rule relationship
  if ($flg)
  { my (%map, %sel);

    # Build table with selection settings
    %sel = map {$_->[0] => 1} @{$slf->{'_dsc'}->{'sel'}};

    # Build table with selection setting mappings
    foreach my $map (keys(%{$slf->{'_map'}}))
    { next unless exists($sel{$map});
      foreach my $val (values(%{$slf->{'_map'}->{$map}->{'str'}}))
      { $map{$val} = 0;
      }
      foreach my $rec (@{$slf->{'_map'}->{$map}->{'pat'}})
      { $map{$rec->[0]} = 0;
      }
    }

    # Detect map values without corresponding rules
    if (@tbl = grep{!exists($map{$_})} sort keys(%{$slf->{'_req'}}))
    { print "\n" if $cnt++;
      $dsp->dsp_string('Map values with no associated rule: ',
        join(", ", @tbl));
    }

    # Detect unused rules
    if (@tbl = grep{!exists($slf->{'_req'}->{$_})} sort keys(%map))
    { print "\n" if $cnt++;
      $dsp->dsp_string('Unmapped rules: ', join(", ", @tbl));
    }
  }

  # Indicate the check results
  $cnt;
}

=head2 S<$h-E<gt>discover_settings>

This method discovers all module settings.

=cut

sub discover_settings
{ my ($slf) = @_;
  my ($agt, $cnd, $met, $nam, $top, $trc, %tbl);

  $agt = $slf->{'agt'};
  $top = $slf->{'_dsc'};
  $trc = $slf->{'trc'};
  %tbl = map {$_ => 1} @{$slf->{'mod'}};

  foreach my $mod (@{$top->{'seq'}})
  { next unless exists($tbl{$mod}) && exists($top->{'mod'}->{$mod});
    print "[Prepare/Discover] Module '$mod'\n" if $trc;
    foreach my $rec (@{$top->{'mod'}->{$mod}})
    { ($nam, $met, $cnd) = @$rec;
      if (defined($agt->get_setting($nam)))
      { print "[Prepare/Discover] Skip defined setting '$nam'\n" if $trc;
      }
      elsif ($cnd && !$agt->get_setting($cnd))
      { print "[Prepare/Discover] Skip conditional setting '$nam'\n" if $trc;
      }
      else
      { print "[Prepare/Discover] Discover setting '$nam'\n" if $trc;
        $slf->discover_value($nam, $met);
      }
    }
  }
}

=head2 S<$h-E<gt>discover_value($name,$mechanism)>

This method retrieves the value of the specified setting using the appropriate
mechanism when the value is not known yet.

It returns the value of the setting.

=cut

sub discover_value
{ my ($slf, $nam, $met, $dft) = @_;
  my ($trc, $val);

  $trc = $slf->{'trc'};
  if(defined($val = $slf->{'agt'}->get_setting($nam)))
  { print "[Prepare/Discover] '$nam' already defined ($val)\n" if $trc;
  }
  elsif (exists($slf->{'def'}->{$met}))
  { eval {
      &{$slf->{'def'}->{$met}}($slf, $nam);
      };
    print "[Prepare/Discover] Error when using '$met' for '$nam'\n$@\n"
      if $@ && $trc;
    $val = $slf->{'agt'}->get_setting($nam);
    print "[Prepare/Discover] $nam='$val'\n" if $trc && defined($val);
  }
  else
  { print "[Prepare/Discover] Missing discovery mechanism '$met' for '$nam'\n"
      if $trc;
  }
  $val;
}

=head2 S<$h-E<gt>get_modules>

This method returns the list of selected modules.

=cut

sub get_modules
{ @{shift->{'mod'}};
}

=head2 S<$h-E<gt>get_request_value($nam[,$dft])>

This method returns the value for a request parameter or an undefined value
when it does not find such a parameter in the request file.

=cut

sub get_request_value
{ my ($slf, $nam, $dft) = @_;

  exists($slf->{'_inp'}->{$nam}) ? $slf->{'_inp'}->{$nam} : $dft;
}

=head2 S<$h-E<gt>get_value($name,$key[,$dft])>

This method returns the value of the specified hash key. It returns the default
value when the hash or the key is not defined.

=cut

sub get_value
{ my ($slf, $nam, $key, $dft) = @_;

  if (!exists($slf->{'_hsh'}->{$nam}))
  { print "[Prepare/Hash] No hash values for '$nam'\n"
      if $slf->{'trc'};
  }
  elsif (exists($slf->{'_hsh'}->{$nam}->{$key}))
  { $dft = $slf->{'_hsh'}->{$nam}->{$key};
    print "[Prepare/Hash] Value of '$key' in '$nam': '$dft'\n"
      if $slf->{'trc'};
  }
  else
  { print "[Prepare/Hash] Key '$key' not defined in '$nam'\n"
      if $slf->{'trc'};
  }
  $dft;
}

=head2 S<$h-E<gt>load_configuration($cfg)>

This method loads settings specified in the configuration file.

=cut

sub load_configuration
{ my ($slf, $cfg) = @_;

  foreach my $key (keys(%$cfg))
  { $slf->{'agt'}->set_temp_setting($1, $cfg->{$key})
      if $key =~m/^SETTING_(\w+)$/;
  }
}

=head2 S<$h-E<gt>load_plugins>

This method loads the discovery mechanism definitions from plug-ins.

=cut

sub load_plugins
{ my ($slf) = @_;
  my ($cls, $dir, $trc, $ver);

  $trc = $slf->{'trc'};
  $ver = uc($slf->{'ver'});
  $dir = $slf->{'agt'}->get_config->get_dir('D_RDA_PERL', "IRDA/$ver");
  opendir(PLG, $dir)
    or die "IRDA-01002: Cannot open the plugin directory '$dir':\n$!\n";
  foreach my $pkg (readdir(PLG))
  { next unless $pkg =~ s/\.pm$//i;

    # Load the plugin
    $cls = 'IRDA::'.$ver.'::'.$pkg;
    eval "require $cls";
    die "IRDA-01003: Cannot load the plugin '$cls':\n$@\n" if $@;
    print "[Prepare/Plugin] $pkg loaded\n" if $trc;

    # Register the discovery mechanisms
    $cls->load($slf->{'def'});
  }
  closedir(PLG);

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>load_request($req)>

This method loads the request parameters.

=cut

sub load_request
{ my ($slf, $req) = @_;

  $slf->{'_inp'} = $req;
}

=head2 S<$h-E<gt>load_rules($slf,[,$verbose])>

This method loads the rule files.

=cut

sub load_rules
{ my ($slf, $verbose) = @_;
  my ($buf, $cfg, $err, $fil, $grp, $key, $lin, $sct, $top, $trc, $val, $ver);

  # Determine the configuration directory
  $cfg = $slf->{'agt'}->get_config;
  $trc = $slf->{'trc'};
  $ver = lc($slf->{'ver'});

  # Determine the map definitions and the module requirement rules
  print "[Prepare/Rules] Loading maps and requirement rules ...\n" if $trc;
  $fil = $cfg->get_file('D_RDA_DFW', "$ver/reqrul.cfg");
  open(RUL, "<$fil")
    or die "IRDA-01000: Cannot open requirements rule file $fil:\n$!\n";
  $lin = 0;
  $buf = $grp = $sct = '';
  $slf->{'_map'} = {};
  $slf->{'_req'} = {};
  while (<RUL>)
  { # Trim spaces and join continuation lines
    ++$lin;
    s/^\s+//;
    s/[\n\r]+$//;
    $buf .= $_;
    next if $buf =~ s/\\$//;
    $buf =~ s/\s+$//;

    # Treat the line
    eval {
      if ($buf =~ m/^\[(HASH|MAP|RULE)\.(.*)\]/)
      { ($grp, $sct, $top) = ($1, $2, $slf->{$tb_req{$1}}->{$2} = {});
      }
      elsif ($grp eq 'HASH')
      { if ($buf =~ s/^(\w+(\.\w+)*)=(['"])(.*?)\3\s*//)
        { $key = $1;
          $val = $4;
          $val =~ s/\\([0-3][0-7]{2}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
          $top->{$key} = $val;
        }
        else
        { die "Invalid declaration\n" unless $buf =~ m/^#/ || $buf =~ m/^$/;
        }
      }
      elsif ($grp eq 'MAP')
      { if ($buf =~ s/^(\w+(\.\w+)*)=//)
        { $key = $1;
          while ($buf)
          { if ($buf =~ s/^'(.*?)'//)
            { $val = $1;
              $val =~ s/\\([0-3][0-7]{2}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
              $top->{'str'}->{$val} = $key;
              last unless $buf =~s/^,//;
            }
            elsif ($buf =~ s/^"(.*?)"//)
            { push(@{$top->{'pat'}}, [$key, qr/$1/i]) if length($1);
              last unless $buf =~s/^,//;
            }
            else
            { die "Invalid value\n" unless $buf =~ m/^\s*#/ || $buf =~ m/^$/;
              last;
            }
          }
        }
        else
        { die "Invalid declaration\n" unless $buf =~ m/^#/ || $buf =~ m/^$/;
        }
      }
      elsif ($grp eq 'RULE')
      { if ($buf =~ s/^([\w\.]+)=//)
        { $key = $1;
          if ($buf =~ s/^'(.*?)'// || $buf =~ s/^"(.*?)"//)
          { $val = $1;
            $val =~ s/\\([0-3][0-7]{2}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
            $top->{$key} = $val;
            die "Invalid value\n" unless $buf =~ m/^\s*#/ || $buf =~ m/^$/;
          }
          else
          { $top->{$key} = $buf;
          }
        }
        elsif ($buf =~ s/^\*=(\w+(,\w+)*)//)
        { $top->{'*'} = [split(/,/, $1)];
          die "Invalid value\n" unless $buf =~ m/^\s*#/ || $buf =~ m/^$/;
        }
        else
        { die "Invalid declaration\n" unless $buf =~ m/^#/ || $buf =~ m/^$/;
        }
      }
      else
      { die "Missing section declaration\n"
          unless $buf =~ m/^#/ || $buf =~ m/^$/;
      }
      };
    $buf = '';

    # Store errors
    if ($err = $@)
    { $err =~ s/[\n\r\s]+$//;
      push(@{$slf->{'err'}}, "$err in $fil near line $lin");
    }
  }
  close(RUL);

  # Determine the rule selection setting and the module discovery rules
  print "[Prepare/Rules] Loading discovery rules ...\n" if $trc;
  $fil = $cfg->get_file('D_RDA_DFW', "$ver/dscrul.cfg");
  open(RUL, "<$fil")
    or die "IRDA-01001: Cannot open discovery rule file $fil:\n$!\n";
  $err = $slf->{'err'};
  $slf->{'_dsc'} = $top = {dft => [], sel => [], seq => []};
  $lin = 0;
  $buf = $sct = '';
  while (<RUL>)
  { # Trim spaces and join continuation lines
    ++$lin;
    s/^\s+//;
    s/[\n\r]+$//;
    $buf .= $_;
    next if $buf =~ s/\\$//;
    $buf =~ s/\s+$//;

    # Treat the line
    eval {
      if ($buf =~ m/^\[(\w+)\]/)
      { push(@{$top->{'seq'}}, $sct = $1);
      }
      elsif ($buf =~ m/^\*=(\w+(,\w+)*)$/)
      { die "Nested default module declaration\n" if $sct;
        push(@{$top->{'dft'}}, split(/,/, $1));
      }
      elsif ($buf !~ m/^(\w+)=(((\w+)\?)?(\w+))$/)
      { die "Invalid declaration\n" unless $buf =~ m/^#/ || $buf =~ m/^$/;
      }
      elsif ($sct)
      { push(@{$top->{'mod'}->{$sct}}, [$1, $5, $4]);
      }
      else
      { push(@{$top->{'sel'}}, [$1, $5]);
        die "Condition ignored\n" if $4;
      }
      };
    $buf = '';

    # Store errors
    if ($err = $@)
    { $err =~ s/[\n\r\s]+$//;
      push(@{$slf->{'err'}}, "$err in $fil near line $lin");
    }
  }
  close(RUL);

  # Report the errors
  if ($trc && @{$slf->{'err'}})
  { print "[Prepare/Rules] Errors:\n";
    foreach $lin (@{$slf->{'err'}})
    { print "$lin\n";
    }
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>map_value($name,$value)>

This method transforms the setting value using the mapping rules. It returns
the original value when no mapping rules are associated with that variable. It
returns an empty string when no rules are applicable.

=cut

sub map_value
{ my ($slf, $nam, $old) = @_;
  my ($new, $top, $trc);

  $trc = $slf->{'trc'};
  print "[Prepare/Map] Map '$old' for '$nam'\n" if $trc;

  # Abort if no rules exist for the setting
  unless (exists($slf->{'_map'}->{$nam}))
  { print "[Prepare/Map] No mapping rules for '$nam'\n" if $trc;
    return $old;
  }

  # Map with a fixed string
  $top = $slf->{'_map'}->{$nam};
  if (exists($top->{'str'}->{$old}))
  { $new = $top->{'str'}->{$old};
    print "[Prepare/Map] String mapping for '$nam': '$old' -> '$new'\n"
      if $trc;
    return $new;
  }

  # Search for a pattern
  foreach my $rec (@{$top->{'pat'}})
  { if ($old =~ $rec->[1])
    { $new = $rec->[0];
      print "[Prepare/Map] Pattern mapping for '$nam': '$old' -> '$new'\n"
        if $trc;
      return $new;
    }
  }

  # Report no matches
  print "[Prepare/Map] Nothing mapped for '$nam': '$old'\n" if $trc;
  '';
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
