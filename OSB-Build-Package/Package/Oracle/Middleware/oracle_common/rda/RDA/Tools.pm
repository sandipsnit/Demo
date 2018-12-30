# Tools.pm: RDA Tool Box

package RDA::Tools;

# $Id: Tools.pm,v 2.16 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Tools.pm,v 2.16 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Tools - RDA Tool Box

=head1 SYNOPSIS

<rda> <options> -X Tools <command> <switches> <arg> ...

=head1 DESCRIPTION

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Diff qw(diff_files);
  use RDA::Handle::Block;
  use RDA::Object::Index;
  use RDA::Options;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.16 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<diff [-biqstw] file1 file2>

This command compares both files line by line. It supports the following
switches:

=over 8

=item B<   -b > Ignores changes in the amount of white spaces.

=item B<   -e > Ignores end of line differences in file contents.

=item B<   -i > Ignores case differences in file contents.

=item B<   -q > Only indicates whether files differ.

=item B<   -s > Ignores simple line swabs.

=item B<   -t > Expands tabs to spaces.

=item B<   -w > Ignores all white spaces.

=back

Exit status is 0 if inputs are the same, 1 for trouble with the first file, 2
for trouble with the second file, or 3 if the files are different.

=cut

sub diff
{ my ($agt, @arg) = @_;
  my ($dst, $opt, $out, $src, $str);

  # Treat the switches
  $opt = RDA::Options::getopts('beiqstw', \@arg);
  $str = '';
  $str .= 'b' if exists($opt->{'b'});
  $str .= 'e' if exists($opt->{'e'});
  $str .= 'i' if exists($opt->{'i'});
  $str .= 's' if exists($opt->{'s'});
  $str .= 't' if exists($opt->{'t'});
  $str .= 'w' if exists($opt->{'w'});
  $out = \*STDOUT unless exists($opt->{'q'});

  # Compare the files and indicate the result
  $src = shift(@arg);
  $dst = shift(@arg);
  $agt->set_temp_setting('RDA_EXIT', diff_files($src, $dst, $str, $out));

  # Disable setup save
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

  # Disable setup save
  0;
}

=head1 COMMANDS RELATED TO COLLECTED ELEMENTS

Those commands retrieves the RDA collection with the C<RPT_DIRECTORY> and
C<RPT_GROUP> settings. You must typically invoke the collected files with
their full path according to the original operating system.

They are indicating a result overview through bits in the exit code as
following:

=over 14

=item B< Bit 0 (0x01) > One of the contributing file is not complete.

=item B< Bit 1 (0x02) > One of the specified item does not exist.

=item B< Bit 2 (0x04) > No result

=item B< Bit 6 (0x40) > No RDA catalog found

=back

=head2 S<cat [-ae] [-m module,...] file ...>

This command extracts the named files from the RDA collection and concatenates
them to the standard output. 

The command supports the following switches:

=over 6

=item B<  -a > Concatenates incomplete files also.

=item B<  -e > Reports errors.

=item B<  -m > Restricts the collection to the specified module(s).

=back

=cut

sub cat
{ my ($agt, @arg) = @_;
  my ($buf, $flg, $idx, $ifh, $lgt, $opt, $val, @err, @mod, @opt);

  # Treat the switches
  $opt = RDA::Options::getopts('aem:z:', \@arg);
  $flg = exists($opt->{'e'}) ? 1 : 0;
  @mod = split(',', $opt->{'m'}) if exists($opt->{'m'});
  _check_zip(\@opt, $agt, $opt->{'z'});

  # Load the index files
  $idx = RDA::Object::Index->new($agt, @opt,
    'all' => exists($opt->{'a'}) ? 1 : 0,
    'err' => $flg,
    );
  die "[[64]]RDA-01250: No RDA catalog found\n"
    unless ($idx->restrict(@mod)->refresh(1));

  # Concatenate the files
  $val = 4;
  foreach my $fil (@arg)
  { if ($ifh = $idx->get_file($fil))
    { if ($ifh->is_partial)
      { $val |= 1;
        push(@err, "RDA-01251: Partial file '$fil'\n") if $flg;
      }
      binmode($ifh);
      syswrite(STDOUT, $buf, $lgt) while ($lgt = $ifh->sysread($buf, 8192));
      $val &= 3;
    }
    else
    { $val |= 2;
      push(@err, "RDA-01252: Missing file '$fil'\n") if $flg;
    }
  }
  $agt->set_temp_setting('RDA_EXIT', $val);

  # Report the errors
  foreach my $err (@err)
  { warn $err;
  }

  # Disable setup save
  0;
}

=head2 S<extract [-aev] [-d directory] [-m module,...] [file|directory ...] >

This command extracts files or directories from the RDA collection to the
specified directory. When no files are specified, all files are extracted.

It converts the full path of the extracted files into paths relative to the
extraction directory.  Windows drives or resource locations are mapped by
creating extra directories.

The command supports the following switches:

=over 6

=item B<  -a > Extracts incomplete files also.

=item B<  -d > Specifies the directory to extract to (F<extract> by default).

=item B<  -e > Reports errors.

=item B<  -m > Restricts the collection to the specified module(s).

=item B<  -v > Sets the verbose mode.

=back

The command is partially supported for VMS platforms.

=cut

sub extract
{ my ($agt, @arg) = @_;
  my ($dst, $idx, $opt, @mod, @opt);

  # Treat the switches
  $opt = RDA::Options::getopts('ad:em:vz:', \@arg);
  $dst = $opt->{'d'}             if exists($opt->{'d'});
  @mod = split(',', $opt->{'m'}) if exists($opt->{'m'});
  _check_zip(\@opt, $agt, $opt->{'z'});

  # Load the index files
  $idx = RDA::Object::Index->new($agt, @opt,
    'all' => exists($opt->{'a'}) ? 1 : 0,
    'err' => exists($opt->{'e'}) ? 1 : 0,
    'vrb' => ($agt->get_setting('RDA_VERBOSE') || exists($opt->{'v'})) ? 1 : 0,
    );
  die "[[64]]RDA-01250: No RDA catalog found\n"
    unless ($idx->restrict(@mod)->refresh);

  # Extract the entries
  eval {$idx->extract($dst, @arg)};
  warn $@ if $@;
  $agt->set_temp_setting('RDA_EXIT', $idx->get_info('sta'));

  # Disable setup save
  0;
}

=head2 S<find [-ae] [-m module,...] [-d depth] [-n pattern] [directory ...]>

This command searches for files in the RDA collection.

The command supports the following switches:

=over 6

=item B<  -a > Reports incomplete files also.

=item B<  -d > Specifies the search depth.

=item B<  -e > Reports errors.

=item B<  -m > Restricts the collection to the specified module(s).

=item B<  -n > Specifies a basename pattern in a Perl syntax.

=back

=cut

sub find
{ my ($agt, @arg) = @_;
  my ($idx, $lvl, $opt, $pat, @mod, @opt);

  # Create the index control object
  $idx = RDA::Object::Index->new($agt);

  # Treat the switches
  $opt = RDA::Options::getopts('ad:em:n:z:', \@arg);
  $lvl = $opt->{'d'}             if exists($opt->{'d'}) && $opt->{'d'} >= 0;
  @mod = split(',', $opt->{'m'}) if exists($opt->{'m'});
  $pat = $opt->{'n'}             if exists($opt->{'n'});
  _check_zip(\@opt, $agt, $opt->{'z'});

  # Load the index files
  $idx = RDA::Object::Index->new($agt, @opt,
    'all' => exists($opt->{'a'}) ? 1 : 0,
    'err' => exists($opt->{'e'}) ? 1 : 0,
    );
  die "[[64]]RDA-01250: No RDA catalog found\n"
    unless ($idx->restrict(@mod)->refresh(1));

  # Display the matching files and set the exit code.
  eval {
    foreach my $hit ($idx->find($pat, $lvl, @arg))
    { print "$hit\n";
    }
    };
  warn $@ if $@;
  $agt->set_temp_setting('RDA_EXIT', $idx->get_info('sta'));

  # Disable setup save
  0;
}

=head2 S<grep [-acefhilnvHL...] [-m module,...] pattern file ...>

This command searches the named files for lines containing a match to the given
pattern in Perl syntax. By default C<grep> prints the matching lines. 

The command supports the following switches:

=over 6

=item B<  -a > Analyzes incomplete files also.

=item B<  -b > Prefixes lines with their byte offset.

=item B<  -c > Returns the match count instead of the match list.

=item B<  -e > Reports errors.

=item B<  -f > Stops file scanning on the first match.

=item B<  -h > Suppresses the prefixing of file names on output.

=item B<  -i > Ignores case when matching.

=item B<  -j > Joins continuation lines.

=item B<  -l > Prints only the name of the files with matching lines.

=item B<  -m > Restricts the collection to the specified module(s).

=item B<  -n > Prefixes output lines with the line number in its input file.

=item B<  -v > Inverts the sense of matching.

=item B<  -An> Prints E<lt>nE<gt> lines of trailing context after matching
lines.

=item B<  -Bn> Prints E<lt>nE<gt> lines of leading context before matching
lines.

=item B<  -Cn> Prints E<lt>nE<gt> lines of output context.

=item B<  -Fn> Stops file scanning after E<lt>nE<gt> matching lines.

=item B<  -H > Prints the file names for each match.

=item B<  -L > Prints only the name of the files without matching lines.

=back

It uses a pipe sign (|) as separator between file names, line numbers,
counters, and line details.

=cut

sub grep
{ my ($agt, @arg) = @_;
  my ($cmd, $idx, $opt, @mod, @opt);

  # Treat the switches and the pattern
  $opt = RDA::Options::getopts('abcefhijlm:nvz:A:B:C:F:HL', \@arg);
  $cmd = '';
  foreach my $key (qw(b c f h i j l n v H L))
  { $cmd .= $key if exists($opt->{$key});
  }
  foreach my $key (qw(A B C F))
  { $cmd .= "$key$1"    if exists($opt->{$key}) && $opt->{$key} =~ m/^(\d+)$/;
  }
  @mod = split(',', $opt->{'m'}) if exists($opt->{'m'});
  _check_zip(\@opt, $agt, $opt->{'z'});

  # Load the index files
  $idx = RDA::Object::Index->new($agt, @opt,
    'all' => exists($opt->{'a'}) ? 1 : 0,
    'err' => exists($opt->{'e'}) ? 1 : 0,
    );
  $idx->set_info('all', exists($opt->{'a'}) ? 1 : 0);
  die "[[64]]RDA-01250: No RDA catalog found\n"
    unless ($idx->restrict(@mod)->refresh(1));

  # Treat all files
  eval {
    foreach my $hit ($idx->grep($cmd, @arg))
    { print "$hit\n";
    }
  };
  warn $@ if $@;
  $agt->set_temp_setting('RDA_EXIT', $idx->get_info('sta'));

  # Disable setup save
  0;
}

# --- Internal routines -------------------------------------------------------

sub _check_zip
{ my ($tbl, $agt, $pth) = @_;
  my ($cfg);

  if (defined($pth = $agt->get_info('zip', $pth)))
  { $cfg = $agt->get_config;
    $pth = $cfg->get_file('D_CWD', $pth)
      unless $cfg->is_absolute($pth = $cfg->cat_file($pth));
    push(@$tbl, zip => $pth) if -r $pth;
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
L<RDA::Handle::Block|RDA::Handle::Block>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Index|RDA::Object::Index>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>,
L<RDA::Web::Display|RDA::Web::Display>,
L<RDA::Web::Help|RDA::Web::Help>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
