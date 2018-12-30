# Extra.pm: Interface Used to Manage User Defined Data Collection.

package RDA::Extra;

# $Id: Extra.pm,v 2.7 2012/08/10 15:15:46 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Extra.pm,v 2.7 2012/08/10 15:15:46 mschenke Exp $
#
# Change History
# 20120810  MSC  Fix collection status.

=head1 NAME

RDA::Extra - Interface Used to Manage User Defined Data Collection.

=head1 SYNOPSIS

<rda> <options> -X Extra <command> <switches> <arg> ...

=head1 DESCRIPTION

This package regroups additional commands to manage the collection of
additional information.

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my (%tb_cmd, %tb_dat, %tb_dir, %tb_env, %tb_fil, %tb_smp);

my $EXTRA = 'S998XTRA';

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<add_cmd title cmd [arg...]>

This command adds a command to collect information.

=cut

sub add_cmd
{ my $slf = shift;
  my $ttl = shift;
  my $cmd = shift;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Add the command
  $tb_cmd{join("\n", $ttl, $cmd, @_)} = 0 if $ttl && $cmd;

  # Adjust the settings for the extra elements to collect
  _set_extra($slf);
}

=head2 S<add_data file...>

This command adds the specified binary files to the list of extra elements to
collect.

=cut

sub add_data
{ my $slf = shift;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Merge the new files
  foreach my $dat (@_)
  { $tb_dat{$dat} = 0;
  }

  # Adjust the settings for the extra elements to collect
  _set_extra($slf);
}

=head2 S<add_dir dir [pattern [options]]>

This command adds a directory to analyze, with the associated pattern and search
options. Valid options are as follows:

=over 9

=item B<    'i' > Ignores case distinctions in both the pattern and the results

=item B<    'r' > Searches files recursively under each subdirectory

=item B<    'v' > Inverts the sense of matching to select nonmatching files

=back

=cut

sub add_dir
{ my ($slf, $dir, $pat, $opt) = @_;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Add the directory
  if ($dir)
  { $pat = '.' unless $pat;
    $opt = '' unless $opt;
    $opt =~ s/[^irv]//g;
    $tb_dir{join("\n", $dir, $pat, "p$opt")} = 0;
  }

  # Adjust the settings for the extra elements to collect
  _set_extra($slf);
}

=head2 S<add_env name...>

This command adds the specified environment variable names to the list of
environment variables that are temporarily imported as settings. It ignores
names that contain nonalphanumeric characters.

=cut

sub add_env
{ my $slf = shift;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Merge the new names
  foreach my $key (@_)
  { $tb_env{$key} = 0 if $key =~ m/^\w+$/;
  }

  # Adjust the settings for the extra elements to collect
  _set_extra($slf);
}

=head2 S<add_files file...>

This command adds the specified files to the list of extra elements to collect.

=cut

sub add_file
{ add_files(@_);
}

sub add_files
{ my $slf = shift;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Merge the new files
  foreach my $fil (@_)
  { $tb_fil{$fil} = 0;
  }

  # Adjust the settings for the extra elements to collect
  _set_extra($slf);
}

=head2 S<add_smpl name cmd [arg...]>

This command adds a command to sample.

=cut

sub add_smpl
{ my $slf = shift;
  my $nam = shift;
  my $cmd = shift;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Add the command
  $tb_smp{join("\n", $nam, $cmd, @_)} = 0
    if $nam && $cmd && $nam =~ m/^[A-Za-z]/;

  # Adjust the settings for the extra elements to collect
  _set_extra($slf);
}

=head2 S<del_env name...>

This command deletes an environment variable name from the list of environment
variables that are temporarily imported as settings.

=cut

sub del_env
{ my $slf = shift;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Delete the specified names
  foreach my $key (@_)
  { delete($tb_env{$key}) if exists($tb_env{$key});
  }

  # Adjust the settings for the extra elements to collect
  _set_extra($slf, 1);
}

=head2 S<del_extra pos...>

This command deletes files or directories from the list of extra elements to
collect. They are referenced by their position in the list.

=cut

sub del_cmd
{ del_extra(@_);
}

sub del_data
{ del_extra(@_);
}

sub del_dir
{ del_extra(@_);
}

sub del_extra
{ my $slf = shift;
  my %tbl;

  # Get the extra elements to collect from the settings
  _get_extra($slf);

  # Delete the specified commands/files/directories
  %tbl = map {$_ => 1} @_;
  foreach my $cmd (keys(%tb_cmd))
  { delete($tb_cmd{$cmd}) if exists($tbl{$tb_cmd{$cmd}});
  }
  foreach my $dat (keys(%tb_dat))
  { delete($tb_dat{$dat}) if exists($tbl{$tb_dat{$dat}});
  }
  foreach my $fil (keys(%tb_fil))
  { delete($tb_fil{$fil}) if exists($tbl{$tb_fil{$fil}});
  }
  foreach my $dir (keys(%tb_dir))
  { delete($tb_dir{$dir}) if exists($tbl{$tb_dir{$dir}});
  }
  foreach my $smp (keys(%tb_smp))
  { delete($tb_smp{$smp}) if exists($tbl{$tb_smp{$smp}});
  }

  # Adjust the settings for the extra elements to collect
  _set_extra($slf, 1);
}

sub del_file
{ del_extra(@_);
}

sub del_files
{ del_extra(@_);
}

sub del_smpl
{ del_extra(@_);
}

=head2 S<export>

This command exports the extra collection settings. It generates commands to
re-create them.

=cut

sub export
{ my $slf = shift;
  my ($env, $flg, @tbl);

  # Get the extra elements to collect from the settings
  $flg = _get_extra($slf);

  # Display the environment variable names
  print "# Required environment variables\n$0 -X RDA::Extra add_env $env\n\n"
    if ($env = join(',', sort keys(%tb_env)));
 

  # Display the commands
  if ($flg & 1)
  { print "# Extra commands to collect\n";
    foreach my $cmd (sort {$tb_cmd{$a} <=> $tb_cmd{$b}} keys(%tb_cmd))
    { $cmd =~ s#'#'"'"'#g;
      @tbl = split(/\n/, $cmd); 
      print "$0 -X RDA::Extra add_cmd '".join("' '", @tbl)."'\n";
    }
    print "\n";
  }

  # Display the binary files
  if ($flg & 2)
  { print "# Extra binary files to collect\n";
    foreach my $dat (sort {$tb_dat{$a} <=> $tb_dat{$b}} keys(%tb_dat))
    { $dat =~ s#'#'"'"'#g;
      print "$0 -X RDA::Extra add_data '$dat'\n";
    }
    print "\n";
  }

  # Display the files
  if ($flg & 4)
  { print "# Extra files to collect\n";
    foreach my $fil (sort {$tb_fil{$a} <=> $tb_fil{$b}} keys(%tb_fil))
    { $fil =~ s#'#'"'"'#g;
      print "$0 -X RDA::Extra add_file '$fil'\n";
    }
    print "\n";
  }

  # Display the directories
  if ($flg & 8)
  { print "# Extra directories to analyze\n";
    foreach my $dir (sort {$tb_dir{$a} <=> $tb_dir{$b}} keys(%tb_dir))
    { $dir =~ s#'#'"'"'#g;
      $dir =~ s#\n#' '#g;
      print "$0 -X RDA::Extra add_dir '$dir'\n";
    }
    print "\n";
  }

  # Display the sample commands
  if ($flg & 16)
  { print "# Extra commands to sample\n";
    foreach my $smp (sort {$tb_smp{$a} <=> $tb_smp{$b}} keys(%tb_smp))
    { $smp =~ s#'#'"'"'#g;
      @tbl = split(/\n/, $smp); 
      print "$0 -X RDA::Extra add_smpl '".join("' '", @tbl)."'\n";
    }
    print "\n";
  }

  # Don't save the setup
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

  # Don't save the setup
  0;
}

=head2 S<list>

This command lists the extra elements to collect.

=cut

sub list
{ my $slf = shift;
  my ($env, $flg);

  # Get the extra elements to collect from the settings
  $flg = _get_extra($slf);
  print "No extra data to collect\n" unless $flg;

  # Display the environment variable names
  print "Environment variables to temporarily import:\n  $env\n"
    if $env = join(',', sort keys(%tb_env));

  # Display the commands
  if ($flg & 1)
  { print "Extra commands to collect:\n";
    foreach my $cmd (sort {$tb_cmd{$a} <=> $tb_cmd{$b}} keys(%tb_cmd))
    { my ($ttl, @cmd) = split(/\n/, $cmd); 
      printf("%3d. '%s' %s\n", $tb_cmd{$cmd}, $ttl, join(' ', @cmd));
    }
  }

  # Display the binary files
  if ($flg & 2)
  { print "Extra binary files to collect:\n";
    foreach my $dat (sort {$tb_dat{$a} <=> $tb_dat{$b}} keys(%tb_dat))
    { printf("%3d. %s\n", $tb_dat{$dat}, $dat);
    }
  }

  # Display the files
  if ($flg & 4)
  { print "Extra files to collect:\n";
    foreach my $fil (sort {$tb_fil{$a} <=> $tb_fil{$b}} keys(%tb_fil))
    { printf("%3d. %s\n", $tb_fil{$fil}, $fil);
    }
  }

  # Display the directories
  if ($flg & 8)
  { print "Extra directories to analyze:\n";
    foreach my $dir (sort {$tb_dir{$a} <=> $tb_dir{$b}} keys(%tb_dir))
    { printf("%3d. %s %s %s\n", $tb_dir{$dir}, split(/\n/, $dir));
    }
  }

  # Display the sample commands
  if ($flg & 16)
  { print "Extra commands to sample:\n";
    foreach my $smp (sort {$tb_smp{$a} <=> $tb_smp{$b}} keys(%tb_smp))
    { my ($nam, @smp) = split(/\n/, $smp); 
      printf("%3d. '%s' %s\n", $tb_smp{$smp}, $nam, join(' ', @smp));
    }
  }

  # Don't save the setup
  0;
}

# Get the extra elements to collect from the settings
sub _get_extra
{ my ($slf) = @_;
  my ($env, $flg);

  if ($env = $slf->get_setting('EXTRA_ENV'))
  { %tb_env = map {$_ => 1} split(/,/, $env);
  }

  $flg = 0;
  foreach my $key (keys(%{$slf->{'_set'}}))
  { if ($key =~ m/^EXTRA_CMD(\d+)$/)
    { $tb_cmd{$slf->get_setting($key)} = $1;
      $flg |= 1;
    }
    elsif ($key =~ m/^EXTRA_DATA(\d+)$/)
    { $tb_dat{$slf->get_setting($key)} = $1;
      $flg |= 2;
    }
    elsif ($key =~ m/^EXTRA_FILE(\d+)$/)
    { $tb_fil{$slf->get_setting($key)} = $1;
      $flg |= 4;
    }
    elsif ($key =~ m/^EXTRA_DIR(\d+)$/)
    { $tb_dir{$slf->get_setting($key)} = $1;
      $flg |= 8;
    }
    elsif ($key =~ m/^EXTRA_SMPL(\d+)$/)
    { $tb_smp{$slf->get_setting($key)} = $1;
      $flg |= 16;
    }
  }
  $flg;
}

# Adjust settings for the extra elements to collect
sub _set_extra
{ my ($slf, $flg) = @_;
  my ($cnt, $env);

  # Reset the module
  if ($slf->is_configured($EXTRA))
  { $slf->del_reports($EXTRA) if $flg;
    $slf->del_module($EXTRA);
  }
  else
  { $slf->setup($EXTRA);
  }
  $slf->set_current($EXTRA, 'Collect extra elements');
  $slf->set_setting('EXTRA_TAIL', $slf->get_setting('EXTRA_TAIL', 1000), 'N',
    'Default number of lines for tail operations');

  # Save the environment variable names
  if ($env = join(',', sort keys(%tb_env)))
  { $slf->set_setting('EXTRA_ENV', $env);
  }

  # Indicate the extra commands
  $cnt = 0;
  foreach my $cmd (sort keys(%tb_cmd))
  { ++$cnt;
    $slf->set_setting("EXTRA_CMD$cnt", $cmd, 'F', "Extra command $cnt");
  }

  # Indicate the extra binary files
  foreach my $dat (sort keys(%tb_dat))
  { ++$cnt;
    $slf->set_setting("EXTRA_DATA$cnt", $dat, 'F', "Extra binary file $cnt");
  }

  # Indicate the extra files
  foreach my $fil (sort keys(%tb_fil))
  { ++$cnt;
    $slf->set_setting("EXTRA_FILE$cnt", $fil, 'F', "Extra file $cnt");
  }

  # Indicate the extra directories
  foreach my $dir (sort keys(%tb_dir))
  { ++$cnt;
    $slf->set_setting("EXTRA_DIR$cnt", $dir, 'T', "Extra directory $cnt");
  }

  # Indicate the extra sample commands
  foreach my $smp (sort keys(%tb_smp))
  { ++$cnt;
    $slf->set_setting("EXTRA_SMPL$cnt", $smp, 'T', "Extra sample command $cnt");
  }

  # Indicate if information must be collected
  $slf->set_collection($EXTRA, $cnt ? 1 : 0);
  $slf->log('S', $EXTRA);

  # Indicate that the setup must be saved
  1;
}

1;

__END__

=head1 NOTE

Any deletion operation causes the removal of the data previously collected by
the XTRA module.

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Daemon|RDA::Daemon>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Discover|RDA::Discover>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
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
