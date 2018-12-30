# Filter.pm: Interface Used for Objects to Filter RDA Output

package RDA::Filter;

# $Id: Filter.pm,v 2.11 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Filter.pm,v 2.11 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Filter - Interface Used for Objects to Filter RDA Output

=head1 SYNOPSIS

<rda> <options> -X Filter <command> [<subcommand>] <arg> ...

=head1 DESCRIPTION

This package regroups additional commands to control how to filter sensitive
information from the generated reports.

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Handle::Filter qw(%FLT_FORMATS);
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
  use Symbol;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $FILTER = ($^O eq 'VMS')        ? 'filter.vms' :
             ($^O eq 'MSWin32')    ? 'filter.win' :
             ($^O eq 'MSWin64')    ? 'filter.win' :
             ($^O eq 'Windows_NT') ? 'filter.win' :
             ($^O eq 'cygwin')     ? 'filter.win' :
                                     '.filter';

# Define the global private variables
my @tb_ip4 = (
  '<<$1:$3>>\d{1,3}(\.\d{1,3}){3}',
  );
my @tb_ip6 = (
  '<<$1:$3>>[A-F\d]{1,4}(\:[A-F\d]{1,4}){7}',
  '<<$1:$4>>([A-F\d]{1,4}\:){1,5}(\:[A-F\d]{1,4}){1,5}',
  '<<$1:$3>>\:(\:[A-F\d]{1,4}){1,6}',
  '<<$1:$3>>([A-F\d]{1,4}\:){1,6}\:',
  );
my @tb_msk = (
  '<<$1:$3>>255(\.\d{1,3}){3}',
  '<<$1:$2>>0\.0\.0\.0',
  );
my %tb_set = (
  format  => [1, "_FORMAT"],
  gid     => [0, 'FILTER_MINIMUM_GID'],
  options => [1, "_OPTIONS"],
  string  => [1, "_STRING"],
  uid     => [0, 'FILTER_MINIMUM_UID'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head1 FILTER MANAGEMENT METHODS

=head2 S<add format [name format]...)>

This command defines additional substitution formats. A format name must start
with an uppercase letter, followed by uppercase letters or underscores.

=head2 S<add pattern [name [re...]])>

This command adds more patterns in the pattern list of the specified rule set.

=head2 S<add set [name desc]...)>

This command adds rule sets at the end of the rule set lists. It removes any
previous occurrences and preserves definitions of existing rule sets.

=cut

sub add
{ my $agt = shift;
  my $typ = shift || '';

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Treat the request
  if ($typ eq 'format')
  { my ($def, $nam, %tbl);

    %tbl = map {$_ => 1} split(/\#/, $agt->get_setting('FILTER_FORMATS', ''));
    while (($nam, $def) = splice(@_, 0, 2))
    { next unless $nam =~ m/^[A-Z][A-Z\d\_]*$/ && $def;
      $tbl{$nam} = 1;
      $agt->set_temp_setting("FILTER_FORMAT_$nam", $def);
    }
    $agt->set_temp_setting('FILTER_FORMATS', join('#', sort keys(%tbl)));
  }
  elsif ($typ eq 'pattern')
  { my ($nam, @tbl);

    return 0 unless ($nam = shift) && $agt->get_setting("FILTER_${nam}_DESC");
    @tbl = split(/\#/, $agt->get_setting("FILTER_${nam}_PATTERNS", ''));
    foreach my $pat (@_)
    { push(@tbl, $pat) if $pat;
    }
    $agt->set_temp_setting("FILTER_${nam}_PATTERNS", join('#', @tbl));
  }
  elsif ($typ eq 'set' || $typ eq 'rule')
  { my ($nam, $dsc, @tbl);

    @tbl = split(/\#/, $agt->get_setting('FILTER_SETS', ''));
    while (($nam, $dsc) = splice(@_, 0, 2))
    { next unless $nam =~ m/^[A-Z][A-Z\d\_]*$/;
      @tbl = ((grep {$_ ne $nam} @tbl), $nam);
      $agt->set_temp_setting("FILTER_${nam}_DESC",
        $dsc || $agt->get_setting("FILTER_${nam}_DESC", $nam));
      $agt->set_temp_setting("FILTER_${nam}_STRING", '%R:'.$nam.'%')
        unless defined($agt->get_setting("FILTER_${nam}_STRING"));
    }
    $agt->set_temp_setting('FILTER_SETS', join('#', @tbl));
  }
  else
  { return 0;
  }

  # Run the module setup and save the setup file
  $agt->set_temp_setting('FILTER_DEFINED', 1);
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<clear>

This command disables the filter and clears the filter definition. It performs
this operation only when you specify the B<-f> option.

=cut

sub clear
{ my $agt = shift;

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Don't execute it unless in force mode
  return 0 unless $agt->get_setting('RDA_FORCE');

  # Disable the filter and delete the filter definition
  $agt->set_temp_setting('RDA_FILTER', 0);
  $agt->set_temp_setting('FILTER_DEFINED', 0);

  # Run the module setup and save the setup file
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<delete format  name...>

This command deletes the specified user-defined substitution formats.

=head2 S<delete pattern name [offset...]>

This command deletes the specified patterns from the pattern list of the
specified rule set. Patterns are referenced by their offset in the list.

=head2 S<delete set name...>

This command deletes the specified rule set.

=cut

sub delete
{ my $agt = shift;
  my $typ = shift || '';

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Treat the request
  if ($typ eq 'format')
  { my %tbl;

    %tbl = map {$_ => 1} split(/\#/, $agt->get_setting('FILTER_FORMATS', ''));
    map {delete($tbl{$_})} @_;
    $agt->set_temp_setting('FILTER_FORMATS', join('#', sort keys(%tbl)));
  }
  elsif ($typ eq 'pattern')
  { my ($nam, @tbl);

    return 0 unless ($nam = shift) && $agt->get_setting("FILTER_${nam}_DESC");
    @tbl = split(/\#/, $agt->get_setting("FILTER_${nam}_PATTERNS", ''));
    foreach my $off (@_)
    { $tbl[$off] = undef if $off =~ m/^\d+$/ && $off > 0 && --$off <= $#tbl;
    }
    $agt->set_temp_setting("FILTER_${nam}_PATTERNS",
      join('#', grep {defined($_)} @tbl));
  }
  elsif ($typ eq 'set' || $typ eq 'rule')
  { my (@tbl);

    @tbl = split(/\#/, $agt->get_setting('FILTER_SETS', ''));
    foreach my $nam (@_)
    { @tbl = grep {$_ ne $nam} @tbl;
    }
    $agt->set_temp_setting('FILTER_SETS', join('#', @tbl));
  }
  else
  { return 0;
  }

  # Run the module setup and save the setup file
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<disable>

This command disables the filter. It generates the default filter configuration
if the module is not configured yet.

=cut

sub disable
{ my $agt = shift;

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Disable the filter
  $agt->set_temp_setting('RDA_FILTER', 0);

  # Generate the default rules
  set_default($agt) unless $agt->is_configured('S990FLTR');

  # Run the module setup and save the setup file
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<enable>

This command enables the filter. It generates the default filter configuration
if the module is not configured yet.

=cut

sub enable
{ my $agt = shift;

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Enable the filter
  $agt->set_temp_setting('RDA_FILTER', 1);

  # Generate the default rules
  set_default($agt) unless $agt->is_configured('S990FLTR');

  # Run the module setup and save the setup file
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<export>

This command exports the filter definition.

=cut

sub export
{ my $agt = shift;
  my ($def);

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Clear any existing definition
  print "$0 -X Filter -f clear\n";

  # Export the rule sets
  foreach my $set (split(/\#/, $agt->get_setting('FILTER_SETS', '')))
  { print "\n# Define $set rule set\n";
    print "$0 -X Filter add set $set "
      ._exp_str($agt->get_setting("FILTER_${set}_DESC"))."\n";
    print "$0 -X Filter set string $set "._exp_str($def)."\n"
      if defined($def = $agt->get_setting("FILTER_${set}_STRING"));
    print "$0 -X Filter set format $set "._exp_str($def)."\n"
      if defined($def = $agt->get_setting("FILTER_${set}_FORMAT"));
    print "$0 -X Filter set options $set "._exp_str($def)."\n"
      if defined($def = $agt->get_setting("FILTER_${set}_OPTIONS"));
    foreach my $pat (split(/\#/,
      $agt->get_setting("FILTER_${set}_PATTERNS", '')))
    { print "$0 -X Filter add pattern $set "._exp_str($pat)."\n" if $pat;
    }
  }

  # Export the limits
  print "\n# Set limits\n";
  print "$0 -X Filter set gid $def\n"
    if defined($def = $agt->get_setting('FILTER_MINIMUM_GID'));
  print "$0 -X Filter set uid $def\n"
    if defined($def = $agt->get_setting('FILTER_MINIMUM_UID'));

  # Export the user defined substitution formats
  print "\n# Load user defined substitution formats\n";
  foreach my $fmt (split(/\#/, $agt->get_setting('FILTER_FORMATS', '')))
  { next unless $fmt;
    print "$0 -X Filter add format $fmt "
      ._exp_str($agt->get_setting("FILTER_FORMAT_$fmt"))."\n";
  }

  # Enable the filter when required
  print "\n# Enable the filter\n$0 -X Filter enable\n"
    if $agt->get_setting('RDA_FILTER');

  0;
}

sub _exp_str
{ my ($str) = @_;

  return "''" unless defined($str);
  $str =~ s/\'/'"'"'/g;
  "'$str'";
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

  # Don't save the setup file
  0;
}

=head2 S<list formats>

This command lists the defined substitution formats.

=head2 S<list set  [name...]>

This command provides the description of the specified rules.

=head2 S<list sets>

This command lists the defined rules.

=cut

sub list
{ my $agt = shift;
  my $typ = shift || '';
   my ($cnt, $dsc);

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Treat the request
  if ($typ eq 'formats')
  { print "Internal Substitution Formats:\n";
    foreach my $fmt (keys(%FLT_FORMATS))
    { printf("  %-10s %s\n", $fmt, $FLT_FORMATS{$fmt});
    }
    print "\nUser-Defined Substitution Formats:\n";
    foreach my $fmt (split(/\#/, $agt->get_setting('FILTER_FORMATS', '')))
    { next unless $fmt
        && ($dsc = $agt->get_setting("FILTER_FORMAT_$fmt", ''));
      printf("  %-10s %s\n", $fmt, $dsc, ++$cnt);
    }
    print "  No substitution formats defined\n" unless $cnt;
  }
  elsif ($typ eq 'set' || $typ eq 'rule')
  { my ($off, @tbl);

    @tbl = split(/\#/, $agt->get_setting('FILTER_SETS', ''))
      unless (@tbl = @_);
    foreach my $set (@tbl)
    { next unless defined($dsc = $agt->get_setting("FILTER_${set}_DESC"));
      print "\n" if $cnt++;
      $off = 0;
      print "Rule Set $set ($dsc)\n";
      print "  Substitution format: ",
        $agt->get_setting("FILTER_${set}_FORMAT", ''), "\n";
      print "  Replacement string: ",
        $agt->get_setting("FILTER_${set}_STRING", ''), "\n";
      print "  Matching options: ",
        $agt->get_setting("FILTER_${set}_OPTIONS", ''), "\n";
      print "  Matching patterns:\n";
      foreach my $pat (split(/\#/,
        $agt->get_setting("FILTER_${set}_PATTERNS", '')))
      { printf("    %2d. %s\n", ++$off, $pat);
      }
      print "    No matching patterns defined\n" unless $off;
    }
    print "  No filter rule sets defined\n" unless $cnt;
  }
  elsif ($typ eq 'sets' || $typ eq 'rules')
  { print "Filter Rule Sets:\n";
    foreach my $set (split(/\#/, $agt->get_setting('FILTER_SETS', '')))
    { printf("  %2d. %-10s %s\n", ++$cnt, $set,
        $agt->get_setting("FILTER_${set}_DESC", '')) if $set;
    }
    print "  No filter rule sets defined\n" unless $cnt;
  }

  # Don't save the setup file
  0;
}

=head2 S<reset>

This command resets the filter, restoring its default configuration. It performs
this operation only when you specify the B<-f> option.

=cut

sub reset
{ my $agt = shift;

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Don't execute it unless in force mode
  return 0 unless $agt->get_setting('RDA_FORCE');

  # Define the default rules
  set_default($agt);

  # Run the module setup and save the setup file
  $agt->set_temp_setting('FILTER_DEFINED', 1);
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<set format name string>

This command sets the substitution format for the specified rule set.

=head2 S<set gid min>

This command specifies the minimum group identifier to consider for scrubbing
groups for UNIX. When no value is provided, it restores the default value.

=head2 S<set options name string>

This command sets the matching options for the specified rule set.

=head2 S<set string name string>

This command sets the substitution string for the specified rule set.

=head2 S<set uid min>

This command specifies the minimum user identified to consider for scrubbing
users for UNIX. When no value is provided, it restores the default value.

=cut

sub set
{ my $agt = shift;
  my $typ = shift || '';
  my $nam = shift || '';

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;

  # Treat the request
  return 0 unless exists($tb_set{$typ});
  if ($tb_set{$typ}->[0])
  { my $str = shift;

    $agt->set_temp_setting('FILTER_'.$nam.$tb_set{$typ}->[1], $str)
      if defined($str) && defined($agt->get_setting("FILTER_${nam}_DESC"));
  }
  elsif ($nam && RDA::Object::Rda->is_unix)
  { $agt->set_temp_setting($tb_set{$typ}->[1], $nam)
      if $nam =~ m/^\d+$/ && $nam >= 0;
  }
  else
  { $agt->del_setting($tb_set{$typ}->[1]);
  }

  # Run the module setup and save the setup file
  $agt->set_temp_setting('FILTER_DEFINED', 1);
  $agt->set_info('yes', 1);
  $agt->setup('S990FLTR', $agt->get_setting('RDA_TRACE'));
  1;
}

=head2 S<test>

This command tests the filter generation. When the B<-d> option is set, it
displays the rule code also.

=cut

sub test
{ my $agt = shift;
  my $flt;

  # Generate the filter
  $flt = RDA::Handle::Filter->new($agt);
  $flt->display if $agt->get_setting('RDA_DEBUG');

  # Don't save the setup file
  0;
}

=head1 AUTOMATIC FILTERING METHODS

=head2 S<remove>

This command removes the saved filter definition from the work directory.

=cut

sub remove
{ my $agt = shift;
  my $fil;

  $fil = RDA::Object::Rda->cat_file($agt->get_config->get_group('D_RDA'),
    $FILTER);
  1 while unlink($fil);

  # Don't save the setup file
  0;
}

=head2 S<save>

This command saves the definition of an active filter in the work directory. It
does not perform the operation unless the filter is enabled.

=cut

sub save
{ my $agt = shift;
  my ($def, $fil, $ofh);

  # Abort if the setup file is not yet configured
  die "RDA-00123: Missing setup file\n" unless $agt->is_configured;
  
  # Check if the filter is enabled
  die "RDA-00124: Filter not enabled" 
    unless $agt->get_setting('RDA_FILTER')
      &&   $agt->get_setting('FILTER_DEFINED');
  
  # Create a .filter file, abort if not able to create
  $fil = RDA::Object::Rda->cat_file($agt->get_config->get_group('D_RDA'),
    $FILTER);
  $ofh = IO::File->new;
  $ofh->open($fil, $CREATE, $FIL_PERMS)
    or die "RDA-00125: Cannot create the filter file '$fil':\n $!\n";
  
  # Save the rule sets
  if ($def = $agt->get_setting("FILTER_SETS"))
  { print {$ofh} "FILTER_SETS="._sav_str($def)."\n";

    foreach my $set (split(/\#/, $agt->get_setting('FILTER_SETS', '')))
    { print {$ofh} "FILTER_${set}_DESC="
        ._sav_str($agt->get_setting("FILTER_${set}_DESC"))."\n";
      print {$ofh} "FILTER_${set}_STRING="._sav_str($def)."\n"
        if defined($def = $agt->get_setting("FILTER_${set}_STRING"));
      print {$ofh} "FILTER_${set}_FORMAT="._sav_str($def)."\n"
        if defined($def = $agt->get_setting("FILTER_${set}_FORMAT"));
      print {$ofh} "FILTER_${set}_OPTIONS="._sav_str($def)."\n"
        if defined($def = $agt->get_setting("FILTER_${set}_OPTIONS"));
      print {$ofh} "FILTER_${set}_PATTERNS="._sav_str($def)."\n"
        if defined($def = $agt->get_setting("FILTER_${set}_PATTERNS"));
    }
  }
    
  # Save the limits
  print {$ofh} "FILTER_MINIMUM_GID=$def\n"
    if defined($def = $agt->get_setting('FILTER_MINIMUM_GID'));
  print {$ofh} "FILTER_MINIMUM_UID=$def\n"
    if defined($def = $agt->get_setting('FILTER_MINIMUM_UID'));

  # Save the user defined substitution formats
  if ($def = $agt->get_setting("FILTER_FORMATS"))
  { print {$ofh} "FILTER_FORMATS="._sav_str($def)."\n";

    foreach my $fmt (split(/\#/, $agt->get_setting('FILTER_FORMATS', '')))
    { next unless $fmt;
      print {$ofh} "FILTER_FORMAT_$fmt="
        ._sav_str($agt->get_setting("FILTER_FORMAT_$fmt"))."\n";
    }
  }

  # Close the file
  $ofh->close;

  # Don't save the setup file
  0;
}

sub _sav_str
{ my ($str) = @_;

  $str =~ s/\n/&\#10;/g;
  $str =~ s/\"/&\#34;/g;
  $str =~ s/\'/&\#39;/g;
  "'$str'";
}

=head2 S<set_default  [key]>

This command generates temporary settings containing the default filter
configuration. You can specify a setting key as an extra argument. When set,
it returns its value. Otherwise, it returns an empty string.

=cut

sub set_default
{ my ($agt, $ret) = @_;
  my ($fil, $key, $val, @set);

  if ((exists($ENV{'RDA_FILTER'}) &&
       -r ($fil = RDA::Object::Rda->cat_file($ENV{'RDA_FILTER'})))
    || -r ($fil = RDA::Object::Rda->cat_file(
                    $agt->get_config->get_group('D_RDA'), $FILTER))
    || -r ($fil = $FILTER))
  { if (open(FLT, "<$fil"))
    { while (<FLT>)
      { next unless m/^\s*(\w+)='(.*)'/;
        $key = $1;
        $val = $2;
        $val =~ s/&\#10;/\n/g;
        $val =~ s/&\#34;/"/g;
        $val =~ s/&\#39;/'/g;
        $agt->set_temp_setting($key, $val);
      }
      $agt->set_setting('FILTER_DEFINED', 1);
      $agt->set_setting('RDA_FILTER', 1);
      close(FLT);
    }
  }
  else
  { push(@set, _dft_config($agt));
    push(@set, _dft_user($agt));
    push(@set, _dft_extra($agt, 'HOST', 'Additional host'));
    push(@set, _dft_group($agt));
    push(@set, _dft_mask($agt));
    push(@set, _dft_extra($agt, 'DOMAIN', 'Additional domain'));
    push(@set, _dft_ip($agt));
    push(@set, _dft_pwd($agt));
    $agt->set_temp_setting('FILTER_SETS', join('#', @set));
  }

  $ret ? $agt->get_setting($ret, '') : '';
}

# Define the default group rules
sub _dft_config
{ my $agt = shift;
  my ($dft, $dim, $dom, @pat, @set, @tbl);

  $dft = {};

  # Treat the setup file information
  _dft_cfg_nam($dft, $agt->get_config->get_node);
  _dft_cfg_dom($dft, $dom) if ($dom = $agt->get_config->get_domain);
  foreach my $key ($agt->grep_setting('REMOTE_.*_HOSTNAME'))
  { _dft_cfg_nam($dft, $agt->get_setting($key));
  }
  foreach my $key ($agt->grep_setting('_SPECIFIC_HOSTS$'))
  { foreach my $nam (split(/\|/, $agt->get_setting($key)))
    { _dft_cfg_nam($dft, $nam);
    }
  }

  # Treat the configuration file
  if (RDA::Object::Rda->is_unix)
  { _dft_cfg_hst($dft, '/etc/hosts');
    if (open(DFT, '</etc/resolv.conf'))
    { while (<DFT>)
      { next unless s/^(domain|search)\s+//;
        foreach my $nam (split(/\s+/, $_))
        { _dft_cfg_dom($dft, $nam);
        }
      }
      close(DFT);
    }
  }
  elsif (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
  { _dft_cfg_hst($dft, RDA::Object::Rda->cat_file($ENV{'SYSTEMROOT'},
      'system32', 'drivers', 'etc', 'hosts'));
  }

  # Generate the settings
  if (@tbl = sort {$b cmp $a} keys(%{$dft->{'dom'}}))
  { @pat = ();
    foreach $dom (@tbl)
    { $dim = $dft->{'dom'}->{$dom};
      push(@pat,
        sprintf('<<$1:$3>>([a-z\d][a-z\d\-]*\.){%d}%s', $dim - 1, $dom))
        unless $dim < 2;
    }
    $agt->set_temp_setting('FILTER_DFT_HFDQ_DESC',
      'Default domain qualified host');
    $agt->set_temp_setting('FILTER_DFT_HFDQ_FORMAT', 'DFT_HST');
    $agt->set_temp_setting('FILTER_DFT_HFDQ_OPTIONS', 'i');
    $agt->set_temp_setting('FILTER_DFT_HFDQ_PATTERNS', join('#', @pat));
    $agt->set_temp_setting('FILTER_DFT_HFDQ_STRING', '%R:HOST%.%R:DOMAIN%');
    @pat = ();
    foreach $dom (@tbl)
    { $dim = $dft->{'dom'}->{$dom} - 2;
      push(@pat, ($dim <= 0) ? $dom :
        sprintf('<<:$2>>([a-z\d][a-z\d\-]*\.){0,%d}%s', $dim, $dom));
    }
    $agt->set_temp_setting('FILTER_DFT_DOMAIN_DESC', 'Default domain');
    $agt->set_temp_setting('FILTER_DFT_DOMAIN_FORMAT', 'DFT_SYS');
    $agt->set_temp_setting('FILTER_DFT_DOMAIN_OPTIONS', 'i');
    $agt->set_temp_setting('FILTER_DFT_DOMAIN_PATTERNS', join('#', @pat));
    $agt->set_temp_setting('FILTER_DFT_DOMAIN_STRING', '%R:DOMAIN%');
    @pat = ();
    foreach $dom (@tbl)
    { $dim = $dft->{'dom'}->{$dom} - 2;
      $dom =~ s/\\\./,dc=/;
      push(@pat, ($dim <= 0) ? "dc=$dom" :
        sprintf('<<:$2>>(dc=[a-z\d][a-z\d\-]*\,){0,%d}dc=%s', $dim, $dom));
    }
    $agt->set_temp_setting('FILTER_DFT_DC_DESC', 'Default LDAP domain');
    $agt->set_temp_setting('FILTER_DFT_DC_FORMAT', 'DFT_SYS');
    $agt->set_temp_setting('FILTER_DFT_DC_OPTIONS', 'i');
    $agt->set_temp_setting('FILTER_DFT_DC_PATTERNS', join('#', @pat));
    $agt->set_temp_setting('FILTER_DFT_DC_STRING', '%R:DC%');
    push(@set, 'DFT_HFDQ', 'DFT_DOMAIN', 'DFT_DC');
  }
  if (@tbl = sort {$b cmp $a} keys(%{$dft->{'hst'}}))
  { $agt->set_temp_setting('FILTER_DFT_HOST_DESC', 'Default host');
    $agt->set_temp_setting('FILTER_DFT_HOST_FORMAT', 'DFT_HST');
    $agt->set_temp_setting('FILTER_DFT_HOST_OPTIONS', 'i');
    $agt->set_temp_setting('FILTER_DFT_HOST_PATTERNS', join('#', @tbl));
    $agt->set_temp_setting('FILTER_DFT_HOST_STRING', '%R:HOST%');
    push(@set, 'DFT_HOST');
  }
  @set;
}

sub _dft_cfg_dom
{ my ($dft, $dom) = @_;
  my ($dim, @dom);

  $dim = (@dom = split(/\./, $dom));
  $dom = $dom[-2].'\.'.$dom[-1] if $dim > 1;
  $dft->{'dom'}->{$dom} = $dim
    if !exists($dft->{'dom'}->{$dom}) || $dim > $dft->{'dom'}->{$dom};
}

sub _dft_cfg_hst
{ my ($dft, $fil) = @_;

  if (open(DFT, "<$fil"))
  { while (<DFT>)
    { s/#.*$//;
      next unless s/^\s*\d{1,3}(\.\d{1,3}){3}\s+//
        || s/^\s*\:(\:[A-F\d]{1,4}){1,6}\s+//
        || s/^\s*[A-F\d]{1,4}(\:[A-F\d]{1,4}){7}\s+//
        || s/^\s*([A-F\d]{1,4}\:){1,5}(\:[A-F\d]{1,4}){1,5}\s+//
        || s/^\s*([A-F\d]{1,4}\:){1,6}\:\s+//;
      s/[\n\r\s]+$//;
      foreach my $nam (split(/\s+/, $_))
      { _dft_cfg_nam($dft, $nam);
      }
    }
    close(DFT);
  }
}

sub _dft_cfg_nam
{ my ($dft, $nam) = @_;
  my ($dom, $hst);

  ($hst, $dom) = split(/\./, $nam, 2);
  $dft->{'hst'}->{$hst} = 1;
  _dft_cfg_dom($dft, $dom) if $dom;
}

# Define the extra rules
sub _dft_extra
{ my ($agt, $set, $dsc) = @_;

  $agt->set_temp_setting("FILTER_${set}_DESC", $dsc);
  $agt->set_temp_setting("FILTER_${set}_FORMAT", 'DFT');
  $agt->set_temp_setting("FILTER_${set}_OPTIONS", '');
  $agt->set_temp_setting("FILTER_${set}_PATTERNS", '');
  $agt->set_temp_setting("FILTER_${set}_STRING", '%R:'.$set.'%');
  $set;
}

# Define the default group rules
sub _dft_group
{ my $agt = shift;
  my ($gid, $lim, $nam, @tbl);

  if (RDA::Object::Rda->is_unix)
  { $lim = $agt->get_setting('FILTER_MINIMUM_GID', 101);
    if (open(DFT, '</etc/group'))
    { while (<DFT>)
      { ($nam, undef, $gid) = split(/:/, $_, 4);
        next if $lim && defined($gid) && $gid =~ m/^\s*(\d+)\s*$/
          && $1 >= 0 && $1 < $lim;
        $nam =~ s/^[\+\-]\@?//;
        push(@tbl, $nam) unless $nam =~ m/^(dba|oinstall|oper|oracle|)$/;
      }
      close(DFT);
    }
  }
  elsif (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
  { my $flg;
    if (open(DFT, 'net localgroup |'))
    { while (<DFT>)
      { s/[\n\r\s]+$//;
        if (m/^\-+$/)
        { $flg = 1;
        }
        elsif (m/completed successfully/)
        { last;
        }
        elsif ($flg && s/^\*//)
        { foreach my $nam (split(/\s+\*/, $_))
          { $nam =~ s/\$.*$//;
            push(@tbl, $nam)
              if $nam
              && $nam !~ m/^(dba|oinstall|oper|ora_dba|oracle|support)$/i;
          }
        }
      }
      close(DFT);
    }
  }
  return () unless @tbl;

  $agt->set_temp_setting('FILTER_GROUP_DESC', 'Group');
  $agt->set_temp_setting('FILTER_GROUP_FORMAT', 'DFT');
  $agt->set_temp_setting('FILTER_GROUP_OPTIONS', '');
  $agt->set_temp_setting('FILTER_GROUP_PATTERNS',
    join('#', sort {$b cmp $a} @tbl));
  $agt->set_temp_setting('FILTER_GROUP_STRING', '%R:GROUP%');
  'GROUP';
}

# Define the default IP addresses rules
sub _dft_ip
{ my $agt = shift;

  $agt->set_temp_setting('FILTER_IP4_DESC', 'IPv4 addresses');
  $agt->set_temp_setting('FILTER_IP4_FORMAT', 'DFT_IP4');
  $agt->set_temp_setting('FILTER_IP4_OPTIONS', '');
  $agt->set_temp_setting('FILTER_IP4_PATTERNS', join('#', @tb_ip4));
  $agt->set_temp_setting('FILTER_IP4_STRING', '%R:IP4%');

  $agt->set_temp_setting('FILTER_IP6_DESC', 'IPv6 addresses');
  $agt->set_temp_setting('FILTER_IP6_FORMAT', 'DFT_IP6');
  $agt->set_temp_setting('FILTER_IP6_OPTIONS', '');
  $agt->set_temp_setting('FILTER_IP6_PATTERNS', join('#', @tb_ip6));
  $agt->set_temp_setting('FILTER_IP6_STRING', '%R:IP6%');
  ('IP4', 'IP6');
}

# Define the default network mask rules
sub _dft_mask
{ my $agt = shift;

  $agt->set_temp_setting('FILTER_MASK_DESC', 'Network mask');
  $agt->set_temp_setting('FILTER_MASK_FORMAT', 'DFT_IP4');
  $agt->set_temp_setting('FILTER_MASK_OPTIONS', '');
  $agt->set_temp_setting('FILTER_MASK_PATTERNS', join('#', @tb_msk));
  $agt->set_temp_setting('FILTER_MASK_STRING', '%R:MASK%');
  'MASK';
}

# Define the default password rules
sub _dft_pwd
{ my $agt = shift;

  $agt->set_temp_setting('FILTER_PWD_DESC', 'Passwords');
  $agt->set_temp_setting('FILTER_PWD_FORMAT', 'DFT_ATT');
  $agt->set_temp_setting('FILTER_PWD_OPTIONS', 'i');
  $agt->set_temp_setting('FILTER_PWD_PATTERNS', 'password');
  $agt->set_temp_setting('FILTER_PWD_STRING', '%R:PASSWORD%');
  'PWD';
}

# Define the default user rules
sub _dft_user
{ my $agt = shift;
  my ($nam, @tbl, %tbl);

  # Treat the setup file information
  foreach my $key ($agt->grep_setting('_USER$'))
  { $nam = $agt->get_setting($key);
    $nam =~ s/@.*$//;
    $tbl{$nam} = 0 unless $nam =~ m/^(oracle|)$/;
  }

  # Treat the configuration file
  if (RDA::Object::Rda->is_unix)
  { my ($lim, $uid);

    $lim = $agt->get_setting('FILTER_MINIMUM_UID', 101);
    if (open(DFT, '</etc/passwd'))
    { while (<DFT>)
      { ($nam, undef, $uid) = split(/:/, $_, 4);
        next if $lim && defined($uid) && $uid =~ m/^\s*(\d+)\s*$/
          && $1 >= 0 && $1 < $lim;
        $nam =~ s/^[\+\-]\@?//;
        $tbl{$nam} = 1 unless $nam =~ m/^(oracle|)$/;
      }
      close(DFT);
    }
  }
  elsif (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
  { my $flg;
    if (open(DFT, 'net user |'))
    { while (<DFT>)
      { s/[\n\r\s]+$//;
        if (m/^\-+$/)
        { $flg = 1;
        }
        elsif (m/completed successfully/)
        { last;
        }
        elsif ($flg)
        { foreach my $nam (split(/\s+/, $_))
          { $tbl{$nam} = 1 unless $nam =~ m/^(oracle|support)$/i;
          }
        }
      }
      close(DFT);
    }
  }
  return () unless (@tbl = keys(%tbl));

  # Generate the settings
  $agt->set_temp_setting('FILTER_USER_DESC', 'User');
  $agt->set_temp_setting('FILTER_USER_OPTIONS', '');
  $agt->set_temp_setting('FILTER_USER_PATTERNS',
    join('#', sort {$b cmp $a} @tbl));
  $agt->set_temp_setting('FILTER_USER_STRING', '%R:USER%');
  'USER';
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
L<RDA::Setting|RDA::Render>,
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
