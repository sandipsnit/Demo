# Explorer.pm: Interface Used to Manage Oracle Explorer modules

package RDA::Explorer;

# $Id: Explorer.pm,v 1.26 2012/08/24 14:58:47 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Explorer.pm,v 1.26 2012/08/24 14:58:47 mschenke Exp $
#
# Change History
# 20120624  MSC  Pre-load the access control manager.

=head1 NAME

RDA::Explorer - Interface Used to Manage Oracle Explorer modules.

=head1 SYNOPSIS

require RDA::Explorer;

=head1 DESCRIPTION

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::File;
  use RDA::Block;
  use RDA::Handle::Block;
  use RDA::Object::Mrc;
  use RDA::Object::Output;
  use RDA::Object::Rda qw($CREATE $DIR_PERMS $FIL_PERMS);
  use RDA::Options;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.26 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $OUTPUT = 'XPLR';
my $PREFIX = 'EXPLORER/';
my $TARGET = 'explorer';

# Define the global private variables
my %tb_clr = (
  globalzone => {XPLR_GLOBAL => 0},
  localzones => {},
  zones      => {XPLR_LOCAL  => 0},
  );
my %tb_mrc = (
  cygwin  => 'xplr_cyg',
  linux   => 'xplr_lin',
  solaris => 'xplr_sol',
  sunos   => 'xplr_sol',
  );
my %tb_set = (
  globalzone => {XPLR_GLOBAL => 1},
  localzones => {XPLR_LOCAL  => 1},
  zones      => {},
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<can [name...]>

This command indicates whether RDA covers all Explorer modules that specified
as arguments.

Without arguments, it lists the Explorer collections that can be performed by
RDA.

=cut

sub can
{ my ($agt, @arg) = @_;
  my ($cfg, $mrc, $set, %tbl);

  # Treat the switches
  RDA::Options::getopts('', \@arg);
  
  # Treat the arguments
  $cfg = $agt->get_config;
  $mrc = $agt->get_mrc;
  $set = _get_set($agt);
  if (@arg)
  { foreach my $grp (@arg)
    { my (@tbl);

      # Check for the group existence
      @tbl = eval {$mrc->get_members($set, $grp)};
      if ($@)
      { $agt->set_temp_setting('RDA_EXIT', 2);
        return 0;
      }

      # Validate the group members
      foreach my $mod (@tbl)
      { next if -r $cfg->get_file('D_RDA_CODE', $mod, '.def');
        $agt->set_temp_setting('RDA_EXIT', 3);
        return 0;
      }
    }
  }
  else
  { my ($exp, $nam, %tbl);

    # Determine whether experimental modules must be included
    $exp = $ENV{'XPL_EXP'} ? '(beta )?module' : '(module)';

    # List existing modules
    foreach my $grp ($mrc->get_groups($set))
    { next unless
        $mrc->get_title("$set:$grp", '') =~ m/^Oracle Explorer $exp ($grp)$/i;
      $nam = $2;
      foreach my $mod ($mrc->get_members($set, $grp))
      { $tbl{$mod} = $nam if -r $cfg->get_file('D_RDA_CODE', $mod, '.def');
      }
    }
    print join(' ', 
      $mrc->get_groups("obs_$set"),
      map {$tbl{$_}} grep {exists($tbl{$_})} $mrc->get_members($set, 'all')
      )."\n";
  }

  # Disable setup save
  0;
}

sub _get_set
{ my ($agt) = @_;
  my ($val);

  defined($val = $agt->get_setting('FORCE_SET')) ? $val :
  exists($tb_mrc{$^O})                           ? $tb_mrc{$^O} :
                                                   'xplr';
}

=head2 S<convert [-d directory] [set...]>

This command extracts Explorer results from RDA reports using the Explorer
catalog. When you do not specify any Explorer collection sets as arguments,
all files are extracted.

The command supports the following switch:

=over 6

=item B<  -d > Specifies the Explorer result directory (F<explorer> by default).

=back

=cut

sub convert
{ my ($agt, @arg) = @_;
  my ($opt);

  # Treat the switches
  $opt = RDA::Options::getopts('d:', \@arg);

  # Perform the conversion
  exists($opt->{'d'})
    ? _convert($agt, $opt->{'d'},
               RDA::Object::Rda->cat_dir($opt->{'d'}, 'rda'), @arg)
    : _convert($agt, $TARGET, $OUTPUT, @arg);
}

sub _convert
{ my ($agt, $dst, $src, @arg) = @_;
  my ($alt, $blk, $cfg, $dir, $flt, $grp, $ifh, $nam, $pth, $rpt, $typ, $vrb);

  # Validate the result directory
  $cfg = $agt->get_config;
  $dst = $cfg->get_dir('D_CWD', $dst) unless $cfg->is_absolute($dst);
  die "RDA-09010: Invalid directory '$dst'\n" if -e $dst && ! -d $dst;

  # Adjust the source directory
  unless ($agt->is_described('S999END'))
  { $agt->set_temp_setting('RPT_DIRECTORY', $src);
    $agt->set_info('rpt', RDA::Object::Output->new($agt));
  }

  # Treat all Explorer catalog files
  $flt = {map {$_ => 1} @arg} if @arg;
  $vrb = $agt->get_info('vrb');
  $rpt = $agt->get_output;
  $grp = $rpt->get_group;
  $ifh = IO::File->new;
  if (opendir(DIR, $dir = $rpt->get_path('C')))
  { my (%tbl);

    foreach my $fil (readdir(DIR))
    { next unless $fil =~ /^$grp\_.*\_E.fil$/
        && $ifh->open('<'.RDA::Object::Rda->cat_file($dir, $fil));
      print "Treat catalog $fil\n" if $vrb;
      while (<$ifh>)
      { ($typ, undef, $blk, $nam, $alt) = split(/\|/, $_);
        next if $flt && $nam =~ m/^([^\/]+)/ && !exists($flt->{$1});
        if ($typ eq 'T')
        { push(@{$tbl{$nam}}, $blk) if $blk;
        }
        elsif ($typ eq 'G')
        { print "\tCreating directory $nam ...\n" if $vrb;
          $pth = RDA::Object::Rda->cat_dir($dst, $nam);
          RDA::Object::Rda->create_dir($pth) unless -d $pth;
        }
        elsif ($typ eq 'L')
        { next unless defined($alt);
          print "\tLinking $alt to $nam ...\n" if $vrb;
          $pth = RDA::Object::Rda->cat_dir($dst, $nam);
          RDA::Object::Rda->create_dir($blk) unless -d ($blk = dirname($pth));
          eval {symlink($alt, $pth)};
        }
        else
        { print "\tExtracting $nam ($typ)...\n" if $vrb;
          _extract_file($rpt, $dst, $nam, $blk);
        }
      }
      $ifh->close;
    }
    closedir(DIR);

    # Treat fragments
    foreach my $key (keys(%tbl))
    { print "\tExtracting $key (T)...\n" if $vrb;
      _extract_file($rpt, $dst, $key, @{$tbl{$key}});
    }
  }

  # Disable setup save
  0;
}

sub _extract_file
{ my ($rpt, $dst, $nam, @blk) = @_;
  my ($buf, $dir, $fil, $ifh, $lgt, $off, $ofh, $pth, $siz, $typ);

  # Create the directory
  $pth = RDA::Object::Rda->cat_file($dst, $nam);
  RDA::Object::Rda->create_dir($dir) unless -d ($dir = dirname($pth));

  # Create the target file
  $ofh = IO::File->new;
  $ofh->open($pth, $CREATE, $FIL_PERMS)
    or die "RDA-09011: Cannot create result file '$pth': $!\n";
  binmode($ofh);
  foreach my $blk (@blk)
  { ($off, $siz, $typ, $fil) = split(/\//, $blk, 4);
    $pth = RDA::Object::Rda->cat_file($rpt->get_path($typ), $fil);
    $ifh = RDA::Handle::Block->new($pth, $off, $siz)
      or die "RDA-09012: Cannot open report file '$pth': $!\n";
    binmode($ifh);
    $ofh->syswrite($buf, $lgt) while ($lgt = $ifh->sysread($buf, 8192));
    $ifh->close;
  }
  $ofh->close;
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

This command lists the Explorer collections that can be extracted from RDA
reports.

=cut

sub list
{ my ($agt, @arg) = @_;
  my ($dir, $grp, $ifh, $nam, $rpt, @mod, %mod);

  # Treat the switches
  RDA::Options::getopts('', \@arg);
  
  # Extract the report list
  $ifh = IO::File->new;
  $rpt = $agt->get_output;
  $grp = $rpt->get_group;
  if (opendir(DIR, $dir = $rpt->get_path('C')))
  { foreach my $fil (readdir(DIR))
    { next unless $fil =~ /^$grp\_.*\_E.fil$/
        && $ifh->open('<'.RDA::Object::Rda->cat_file($dir, $fil));
      while (<$ifh>)
      { (undef, undef, undef, $nam) = split(/\|/, $_);
         $mod{$1} = 1 if $nam =~ m/^([^\/]+)/;
      }
      $ifh->close;
    }
    closedir(DIR);
  }

  # Display the list
  if (@mod = keys(%mod))
  { $agt->get_display->dsp_report(join('',
      ".T 'Available Explorer Collections:'\n",
      map {".I '  '\n$_\n\n"} sort @mod));
  }
  else
  { print "No Explorer collections available.\n";
  }

  # Disable setup save
  0;
}

=head2 S<run [-c] -d directory [module...]>

This command performs data collection for Oracle explorer. It accepts a
comma-separated list of modules as arguments.

The command supports the following switches:

=over 6

=item B<  -c > Converts the RDA report in Explorer results.

=item B<  -d > Specifies the Explorer result directory.

=item B<  -t > Activates the trace mode for the Explorer collections.

=back

=cut

sub run
{ my ($agt, @arg) = @_;
  my ($blk, $cfg, $dbg, $dir, $err, $exp, $ifh, $mrc, $opt, $sel, $set, $trc,
      $val, $vrb, $yes, @mod, %det, %grp, %mod, %pkg);

  # Treat the switches
  $opt = RDA::Options::getopts('cd:ts', \@arg);
  
  # Initialization
  $cfg = $agt->get_config;
  $trc = $agt->get_setting('RDA_TRACE', 0);
  $sel = $opt->{'t'} ? 2 : $trc;
  $set = _get_set($agt);
  $yes = 1;
  if ((exists($ENV{'XPL_MOD'}) && $ENV{'XPL_MOD'}  eq 'verbose')
    || $ENV{'EXP_VERBOSE'})
  { $dbg = $vrb = 1;
  }
  else
  { $dbg = $agt->get_setting('RDA_DEBUG');
    $vrb = $agt->get_info('vrb');
  }

  # Pre-load the access control manager
  $agt->get_access;

  # Determine whether experimental modules must be included
  $exp = $ENV{'XPL_EXP'} ? '(beta )?module' : 'module';

  # Analyze the available collections
  $mrc = $agt->get_mrc;
  foreach my $grp ($mrc->get_groups($set))
  { @mod = $mrc->get_members($set, $grp, 1);
    $det{$grp} = [@mod];
    $grp{$mod[0]} = $grp if (scalar @mod) == 1
      && $mrc->get_title("$set:$grp", '') =~ m/^Oracle Explorer $exp $grp$/i;
  }

  # Identify relevant collections
  print "Identifying relevant collections\n" if $sel;
  foreach my $nam (split(/[,\s]+/,
    lc(shift(@arg) || $ENV{'XPL_COL'} || $ENV{'EXP_WHICH'} || 'default')))
  { next if $nam =~ m/^$/;
    print "\t- Treat '$nam'\n" if $sel;
    if ($nam =~ m/^\\?\!ipaddr$/)
    { $agt->set_temp_setting('RDA_FILTER', 1);
    }
    elsif ($nam eq 'interactive')
    { $yes = 0;
    }
    elsif ($nam =~ /^\\?\!(\w*)$/)
    { if (exists($tb_clr{$1}))
      { print "\t\t- Clearing flag $1\n" if $sel;
        foreach my $key (keys(%{$val = $tb_clr{$1}}))
        { $agt->set_temp_setting($key, $val->{$key});
        }
      }
      elsif (exists($det{$1}))
      { foreach my $mod (@{$det{$1}})
        { print "\t\t- Removing MRC module $mod\n" if $sel;
          $mod{$mod} = undef;
        }
      }
    }
    elsif ($nam =~ /^(\w*)$/)
    { if (exists($tb_set{$1}))
      { print "\t\t- Setting flag $1\n" if $sel;
        foreach my $key (keys(%{$val = $tb_set{$1}}))
        { $agt->set_temp_setting($key, $val->{$key});
        }
      }
      elsif (exists($det{$nam}))
      { foreach my $mod (@{$det{$1}})
        { next if exists($mod{$mod}) || !exists($grp{$mod});
          print "\t\t- Adding MRC module $mod\n" if $sel;
          $mod{$mod} = 1;
        }
      }
    }
  }

  $agt->set_temp_setting('xplr_run_mode', 1);
  $agt->set_temp_setting('XPLR_MRC_GROUPS',
    $val = join('|', map {$grp{$_}} grep {$mod{$_}} keys(%mod)));
  print "Selected collections: $val\n" if $sel;

  # Do minimum setup
  print "Performing default setup\n" if $vrb;
  $agt->set_info('bkp', 0);
  $agt->set_info('yes', 1);
  $agt->set_temp_setting('ORACLE_HOME', '');
  $agt->set_temp_setting('RPT_DIRECTORY', exists($opt->{'d'})
    ? RDA::Object::Rda->cat_dir($opt->{'d'}, 'rda')
    : $OUTPUT);
  $agt->set_temp_setting('NO_OCM', 1);
  $agt->set_temp_setting('NO_LOAD', 1);
  $agt->set_temp_setting('XPLR_ETC',
    $ENV{'XPL_ETC'} || $ENV{'EXP_ETC'} || '/etc/opt/SUNWexplo');
  $agt->set_temp_setting('XPLR_LOG', $val)
    if (defined($val = $ENV{'XPL_LOG'}) || defined($val = $ENV{'EXP_LOGFILE'}))
    && -f $val;
  $agt->set_temp_setting('XPLR_PID', $ENV{'XPL_PID'} || $ENV{'EXP_PID'} || $$);
  $agt->set_temp_setting('XPLR_SET', $set);
  $agt->setup('S000INI', $trc, 0);

  # Reuse Explorer information when available
  foreach my $key (qw(ARC BLD OSN OSV SUB TGT TMP TOP))
  { $agt->set_temp_setting("XPLR_$key", $ENV{"XPL_$key"})
      if exists($ENV{"XPL_$key"});
  }
  foreach my $key (qw(ZONES))
  { if (exists($ENV{"EXP_$key"}))
    { $val = $ENV{"EXP_$key"};
      $val =~ s/^\s+//;
      $val =~ s/\s+$//;
      $agt->set_temp_setting("XPLR_$key", $val) if length($val);
    }
  }

  # Treat the input files
  print "Treating input files\n" if $vrb;
  foreach my $mod (keys(%mod))
  { $pkg{$1} = 1 if $mod{$mod} && $mod =~ m/^([^\|\-]+)/;
  }
  if (exists($det{'mandatory'}))
  { foreach my $mod (@{$det{'mandatory'}})
    { $pkg{$1} = 1 if $mod =~ m/^([^\|\-]+)/;
    }
  }
  $ifh = IO::File->new;
  $dir = $cfg->get_group('D_RDA_CODE');
  foreach my $pkg (sort keys(%pkg))
  { print "\t- Executing $pkg-input\n" if $vrb;
    eval {
      $blk = RDA::Block->new($pkg, $dir);
      $blk->load($agt, 1);
      $agt->get_macros($blk->get_lib);
      $blk->get_info('ctx')->set_trace($sel);
      $err = $blk->exec($blk, 0, undef, 'input');
      };
    print "\t*** Error while executing $pkg-input:\n$@\n" if $@ && $sel;
  }

  # Perform the setup
  print "Performing Oracle Explorer setup ($yes)\n" if $vrb;
  $agt->set_info('yes', $yes);
  $agt->setup('S150XPLR', $sel, 0);
  $agt->set_info('yes', 1);
  $agt->end_setup(0);

  # Perform the collections
  print "Executing the collection scripts\n" if $vrb;
  $agt->set_info('yes', $yes);
  $agt->collect_all({S000INI  => $trc,
                     S010CFG  => $trc,
                     S150XPLR => $sel,
                     S999END  => $trc,
                    }, $dbg, 0);
  $agt->save if $opt->{'s'};

  # When requested, convert the results
  if ($opt->{'c'})
  { print "Converting the collection results\n" if $vrb;
    _convert($agt, exists($opt->{'d'}) ? $opt->{'d'} : $TARGET,
      $agt->get_setting('RPT_DIRECTORY'));
  }

  # Disable setup save
  0
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
L<RDA::Handle::Block|RDA::Handle::Block>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Mrc|RDA::Object::Mrc>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
