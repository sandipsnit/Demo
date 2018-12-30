# File.pm: Class Used for File Management Macros

package RDA::Library::File;

# $Id: File.pm,v 2.42 2012/08/14 00:12:33 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/File.pm,v 2.42 2012/08/14 00:12:33 mschenke Exp $
#
# Change History
# 20120813  MSC  Extend the collectCommand macro.

=head1 NAME

RDA::Library::File - Class Used for File Management Macros

=head1 SYNOPSIS

require RDA::Library::File;

=head1 DESCRIPTION

The objects of the C<RDA::Library::File> class are used to interface with file
management macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::File;
  use RDA::Object::Buffer;
  use RDA::Object::Rda qw($CREATE $TMP_PERMS);
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.42 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $ERR = 'stderr.txt';
my $OUT = 'stdout.txt';
my $PWF = 'pwf.txt';
my $RPT = qr/^RDA::Object::(Pipe|Report)$/i;
my $WRK = 'fil.txt';

# Define the global private variables
my %tb_fct = (
  'basename'       => [\&_m_basename,     'T'],
  'catCommand'     => [\&_m_cat_command,  'T'],
  'catDir'         => [\&_m_cat_dir,      'T'],
  'catFile'        => [\&_m_cat_file,     'T'],
  'checksum'       => [\&_m_checksum,     'T'],
  'cleanBox'       => [\&_m_clean_box,    'T'],
  'clearLastFile'  => [\&_m_clear_last,   'N'],
  'collectCommand' => [\&_m_collect_cmd,  'L'],
  'collectData'    => [\&_m_collect_data, 'L'],
  'collectFile'    => [\&_m_collect_file, 'L'],
  'collectInfo'    => [\&_m_collect_info, 'T'],
  'countCommand'   => [\&_m_count_cmd,    'L'],
  'countFile'      => [\&_m_count_file,   'L'],
  'countLast'      => [\&_m_count_last,   'L'],
  'dirname'        => [\&_m_dirname,      'T'],
  'findDir'        => [\&_m_find_dir,     'L'],
  'getHeader'      => [\&_m_get_header,   'T'],
  'getLastAccess'  => [\&_m_get_atime,    'T'],
  'getLastBuffer'  => [\&_m_get_buffer,   'O'],
  'getLastChange'  => [\&_m_get_ctime,    'T'],
  'getLastLength'  => [\&_m_get_last_lgt, 'N'],
  'getLastModify'  => [\&_m_get_mtime,    'T'],
  'getLength'      => [\&_m_get_file_lgt, 'N'],
  'getLines'       => [\&_m_get_lines,    'L'],
  'getNativePath'  => [\&_m_native_path,  'T'],
  'getOwner'       => [\&_m_get_owner,    'T'],
  'getShortPath'   => [\&_m_short_path,   'T'],
  'getSize'        => [\&_m_get_size,     'N'],
  'getStat'        => [\&_m_get_stat,     'L'],
  'getTimeout'     => [\&_m_get_timeout,  'N'],
  'grepCommand'    => [\&_m_grep_cmd,     'L'],
  'grepDir'        => [\&_m_grep_dir,     'L'],
  'grepFile'       => [\&_m_grep_file,    'L'],
  'grepLastFile'   => [\&_m_grep_last,    'L'],
  'isNewer'        => [\&_m_is_newer,     'N'],
  'isOlder'        => [\&_m_is_older,     'N'],
  'kill'           => [\&_m_kill,         'N'],
  'lastCommand'    => [\&_m_last_command, 'T'],
  'lastDir'        => [\&_m_last_dir,     'T'],
  'lastFile'       => [\&_m_last_file,    'T'],
  'loadCommand'    => [\&_m_load_cmd,     'N'],
  'loadFile'       => [\&_m_load_file,    'N'],
  'loadString'     => [\&_m_load_string,  'N'],
  'parseFile'      => [\&_m_parse_file,   'L'],
  'sameFile'       => [\&_m_same_file,    'N'],
  'readLink'       => [\&_m_read_link,    'T'],
  'sameDir'        => [\&_m_same_file,    'N'],
  'sameFile'       => [\&_m_same_file,    'N'],
  'setTimeout'     => [\&_m_set_timeout,  'N'],
  'sortLastFile'   => [\&_m_sort_last,    'N'],
  'splitDir'       => [\&_m_split_dir,    'L'],
  'statCommand'    => [\&_m_stat_cmd,     'N'],
  'testCommand'    => [\&_m_test_cmd,     'T'],
  'testDir'        => [\&_m_test_file,    'N'],
  'testFile'       => [\&_m_test_file,    'N'],
  'umask'          => [\&_m_umask,        'N'],
  'writeCommand'   => [\&_m_write_cmd,    'N'],
  'writeLastFile'  => [\&_m_write_last,   'N'],
  );
my %tb_srt = (
  ps_time => {
    'aix'      => [\&_sort_ps_ms],
    'darwin'   => [\&_sort_ps_msc],
    'dec_osf'  => [\&_sort_ps_hmsc, 43],
    'dynixptx' => [\&_sort_ps_ms],
    'hpux'     => [\&_sort_ps_hms, 33],
    'linux'    => [\&_sort_ps_hms, 57],
    'solaris'  => [\&_sort_ps_ms],
    '?'        => [\&_sort_ps_ms],
    }
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::File-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::File> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'cnt' > > Number of lines read for the last load

=item S<    B<'err' > > Last command exit code

=item S<    B<'hdr' > > First line for a grep operation

=item S<    B<'lgt' > > Number of lines read for the last file

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'max' > > Default highest line number to write

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_buf'> > Last command/line buffer

=item S<    B<'_cks'> > Checksum function

=item S<    B<'_dir'> > Last directory

=item S<    B<'_fil'> > Last file

=item S<    B<'_grp'> > Report group

=item S<    B<'_mod'> > Function to get the last modification day of a file

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of operating system requests timed out

=item S<    B<'_req'> > Number of operating system requests

=item S<    B<'_rpt'> > Report directory

=item S<    B<'_sam'> > Function to compare directory or file paths

=item S<    B<'_skp'> > List of file tests to skip

=item S<    B<'_spl'> > Function to split directories

=item S<    B<'_sta'> > Function to get the file statistics

=item S<    B<'_vms'> > VMS indicator

=item S<    B<'_win'> > Windows indicator

=item S<    B<'_wrk'> > Reference to the work file manager

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($fil, $grp, $out, $rpt, $slf, $vms, $win);

  # Create the macro object
  $out = $agt->get_output;
  $grp = $out->get_info('grp');
  $rpt = $out->get_info('dir');
  $slf = bless {
    cnt  => 0,
    err  => 0,
    lgt  => 0,
    lim  => _chk_alarm($agt->get_setting('RDA_TIMEOUT', 30)),
    max  => $agt->get_setting('RDA_TAIL', 30000),
    _agt => $agt,
    _grp => $grp,
    _out => 0,
    _req => 0,
    _rpt => $rpt,
    _skp => $agt->get_setting('RDA_BIN_CHECK',1) ? '-' : '-BT',
    _vms => RDA::Object::Rda->is_vms,
    _win => RDA::Object::Rda->is_windows,
    }, ref($cls) || $cls;

  # Determine which functions to use
  if ($slf->{'_vms'})
  { $slf->{'_mod'} = \&_mod;
    $slf->{'_sam'} = \&_same_i;
    $slf->{'_sta'} = \&_stat;
    $slf->{'_spl'} = \&_split_v;
  }
  else
  { $slf->{'_mod'} = \&_lmod;
    $slf->{'_sam'} = ($slf->{'_win'} || RDA::Object::Rda->is_cygwin)
      ? \&_same_i
      : \&_same_c;
    $slf->{'_sta'} = \&_lstat;
    $slf->{'_spl'} = $slf->{'_win'} ? \&_split_w : \&_split_u;
  }

  # Determine the request method
  $slf->{'_wrk'} = $agt
    if $agt->get_setting('RDA_USE_TEMP', $slf->{'_win'} || $slf->{'_vms'});

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}->[0]}($slf, @arg);
}

=head2 S<$h-E<gt>clr_stats>

This method resets the statistics and clears corresponding module settings.

=cut

sub clr_stats
{ my ($slf) = @_;

  $slf->{'_not'} = '';
  $slf->{'_req'} = $slf->{'_out'} = 0;
}

=head2 S<$h-E<gt>get_stats>

This method reports the library statistics in the specified module.

=cut

sub get_stats
{ my ($slf) = @_;
  my ($use);

  if ($slf->{'_req'})
  { # Get the statistics record
    $use = $slf->{'_agt'}->get_usage;
    $use->{'OS'} = {not => '', out => 0, req => 0}
      unless exists($use->{'OS'});
    $use = $use->{'OS'};

    # Indicate the current timeout when there is no other note
    $slf->{'_not'} = 'Command execution limited to '.$slf->{'lim'}.'s'
      unless $use->{'not'} || $slf->{'_not'} || $slf->{'lim'} <= 0;

    # Generate the module statistics
    $use->{'out'} += $slf->{'_out'};
    $use->{'req'} += $slf->{'_req'};
    $use->{'not'} = $slf->{'_not'} if $slf->{'_not'};

    # Clear the statistics
    clr_stats($slf);
  }
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 FILE MACROS

=head2 S<basename($file[,@suf])>

This macro extracts the base name of the file specification and  removes the
suffix when it belongs to the suffix list. Each element of this list is
interpreted as a regular expression. It is matched against the end of the name.

When opening existing files from systems that are not case-sensitive, the
pattern matching for suffix removal ignores case.

=cut

sub _m_basename
{ my ($slf, $ctx, @arg) = @_;

  basename(@arg);
}

=head2 S<catCommand($dir[,...],$file)>

This macro concatenates one or more directory names and a file name to form a
complete path ending with a file name. It returns the name quoted as
appropriate to execute it in a shell.

=cut

sub _m_cat_command
{ my ($slf, $ctx, @arg) = @_;

  RDA::Object::Rda->quote($slf->{'_fil'} = ((scalar @arg) > 0)
    ? RDA::Object::Rda->cat_file(@arg)
    : undef);
}

=head2 S<catDir($dir[,...],$dir)>

This macro concatenates two or more directory names to form a complete path
ending with a directory. It removes the trailing slash from the resulting
string. If it is the root directory, then the trailing slash is not removed.

=cut

sub _m_cat_dir
{ my ($slf, $ctx, @arg) = @_;

  $slf->{'_dir'} = ((scalar @arg) > 0)
    ? RDA::Object::Rda->cat_dir(@arg)
    : undef;
}

=head2 S<catFile($dir[,...],$file)>

This macro concatenates one or more directory names and a file name to form a
complete path ending with a file name.

=cut

sub _m_cat_file
{ my ($slf, $ctx, @arg) = @_;

  $slf->{'_fil'} = ((scalar @arg) > 0)
    ? RDA::Object::Rda->cat_file(@arg)
    : undef;
}

=head2 S<checksum($file)>

This macro returns the checksum of the file. Based on available tools, it can
use an MD5 digest, the C<cksum> command, or an internal basic checksum. It
returns an undefined value in case of problems.

=cut

sub _m_checksum
{ my ($slf, $ctx, $fil) = @_;

  # Identify the checksum approach on first usage
  unless (exists($slf->{'_cks'}))
  { $slf->{'_cks'} = \&_get_sum;

    # Check the availability of the MD5 package
    eval {
      require Digest::MD5;
      $slf->{'_cks'} = \&_get_md5;
      };

    # Check the availability of the cksum command
    if ($@)
    { my %tbl = (
        '/bin/cksum'     => \&_get_cksum1,
        '/usr/bin/cksum' => \&_get_cksum2,
        );

      foreach my $pgm (keys(%tbl))
      { `$pgm rda.sh`;
        next if $?;
        $slf->{'_cks'} = $tbl{$pgm};
        last;
      }
    }
  }

  # Compute the checksum
  ($fil && -f $fil && -r $fil)
    ? &{$slf->{'_cks'}}($fil)
    : undef;
}

sub _get_cksum1
{ my ($fil) = @_;
  my ($lin);

  ($lin) = `/bin/cksum "$fil"`;
  ($lin =~ m/(\d+)/) ? $1 : undef;
}

sub _get_cksum2
{ my ($fil) = @_;
  my ($lin);

  ($lin) = `/usr/bin/cksum "$fil"`;
  ($lin =~ m/(\d+)/) ? $1 : undef;
}

sub _get_md5
{ my ($fil) = @_;
  my ($ifh, $val);

  if (($ifh = IO::File->new)->open("<$fil"))
  { binmode($ifh);
    $val = Digest::MD5->new->addfile($ifh)->hexdigest;
    $ifh->close;
  }
  $val;
}

sub _get_sum
{ my ($fil) = @_;
  my ($buf, $ifh, $sum);

  if (($ifh = IO::File->new)->open("<$fil"))
  { binmode($ifh);
    $sum = 0;
    while ($ifh->sysread($buf, 1024))
    { $sum = (($sum + (unpack('%32C*', $buf) << 12) + unpack('%32B*', $buf))
        ^ ($sum << 8)) & 0xffffffff;
    }
    $ifh->close;
  }
  $sum;
}

=head2 S<cleanBox()>

This macro prepares the sand box directory by creating the directory on first
use or by removing any previous content. It returns the directory path.

=cut

sub _m_clean_box
{ my ($slf, $ctx) = @_;

  RDA::Object::Rda->clean_dir($ctx->get_output->get_path('B', 1));
}

=head2 S<clearLastFile()>

This macro clears the information about the last command/file results.

=cut

sub _m_clear_last
{ my ($slf) = @_;

  delete($slf->{'_buf'});
  $slf->{'cnt'} = $slf->{'err'} = 0;
}

=head2 S<collectCommand($request,$command[,$incr])>

This macro captures the standard output and the standard error of the specified
command in two separate reports. By default, it eliminates the standard error
report when empty. On successful completion, it creates entries in the Explorer
catalog.

For finer tuning the collection, you can provide a hash reference as the
request argument. It supports the following keys.

=over 11

=item S<    B<'err'> > Controls the standard error processing.

=item S<    B<'inp'> > Specifies the string to provide as the standard input.

=item S<    B<'inv'> > When true, inverts redirection arguments.

=item S<    B<'nam'> > Specifies the name of the Explorer target.

=item S<    B<'out'> > Controls the standard output processing.

=item S<    B<'ret'> > When present, indicates what the macro must returns.

=item S<    B<'sta'> > Contains the command exit status.

=back

The standard output and error control hashes can have the following keys:

=over 11

=item S<    B<'arg'> > Contains the argument added to the command.

=item S<    B<'blk'> > When true, forces a verbatim block in the RDA report.

=item S<    B<'cat'> > Controls and specifies the catalog entry type.

=item S<    B<'dup'> > Controls and specifies a duplicated catalog entry.

=item S<    B<'end'> > Controls report closing.

=item S<    B<'ext'> > Specifies the  extension for the Explorer target.

=item S<    B<'fct'> > Specifies the macro to filter the command result.

=item S<    B<'fil'> > Specifies a file or a redirection request.

=item S<    B<'flt'> > When true, forces the work file use.

=item S<    B<'ftr'> > Specifies an associated footer text.

=item S<    B<'hdr'> > Specifies an associated header text.

=item S<    B<'mod'> > When true, appends to the file instead of creating it.

=item S<    B<'kpt'> > When true, keeps empty reports.

=item S<    B<'rpt'> > Specifies a report to reuse.

=item S<    B<'wrk'> > Contains the name of the work file.

=back

The macro can override some parameters to ensure a correct behavior. It
returns:

=over 2

=item *

By default, the list of the generated reports.

=item *

A list of values when the C<ret> key contains an array reference as value. The
result is a fixed length list, where missing elements are represented by an
undefined value. The entries of the standard output and error control hashes
are available by prefixing their key with C<out_> or C<err_>.

=item *

A list with a single value when the C<ret> key does not contain an array
reference as value. The entries of the standard output and error control hashes
are available by prefixing their key with C<out_> or C<err_>. The macro returns
an empty list when the requested value is not available.

=back

=cut

sub _m_collect_cmd
{ my ($slf, $ctx, $req, $cmd, $inc) = @_;
  my ($ctl, $flg, $lim, $out, $pid, $pwf, $sta, $val, $wrk, @rpt);

  $slf->{'err'} = 0;
  ++$slf->{'_req'};

  $val = ref($req);
  if ($val =~ m/^RDA::Value::(Assoc|Hash)$/)
  { $ctl = $req->eval_as_data(1);
    delete($ctl->{'sta'});
    $ctl->{'err'} = {}         unless ref($ctl->{'err'}) eq 'HASH';
    $ctl->{'out'} = {kpt => 1} unless ref($ctl->{'out'}) eq 'HASH';
  }
  elsif ($val eq 'HASH')
  { $ctl = $req;
    delete($ctl->{'sta'});
    $ctl->{'err'} = {}         unless ref($ctl->{'err'}) eq 'HASH';
    $ctl->{'out'} = {kpt => 1} unless ref($ctl->{'out'}) eq 'HASH';
  }
  else
  { $ctl = {
      err => {},
      nam => $val ? '' : $req,
      out => {kpt => 1},
      };
  }

  if ($ctl->{'nam'} && $cmd)
  { # Prepare the command
    $out = $ctx->get_output;
    $wrk = $slf->{'_agt'}->get_output;
    _beg_collect($out, $wrk, $ctl->{'nam'}, $ctl->{'out'}, 'O', ' >',
      $OUT, '.out');
    _beg_collect($out, $wrk, $ctl->{'nam'}, $ctl->{'err'}, 'E', ' 2>',
      $ERR, '.err');
    if (ref($ctl->{'pwf'}) eq 'ARRAY')
    { my ($buf, $fmt, $ofh, @pwd);

      ($fmt, @pwd) = @{$ctl->{'pwf'}};
      $ofh = IO::File->new;
      $pwf = $wrk->get_work($PWF, 1);
      if ($ofh->open($pwf, $CREATE, $TMP_PERMS))
      { $buf = sprintf($fmt, $slf->{'_agt'}->get_access->get_password(@pwd));
        $ofh->syswrite($buf, length($buf));
        $ofh->close;
      }
      $cmd = sprintf($cmd, RDA::Object::Rda->quote($pwf));
    }
    $val = _conv_cmd($slf, $ctl->{'inv'}
      ? $cmd.$ctl->{'err'}->{'arg'}.$ctl->{'out'}->{'arg'}
      : $cmd.$ctl->{'out'}->{'arg'}.$ctl->{'err'}->{'arg'});

    # Execute the command
    $lim = $slf->_get_alarm($inc);
    eval {
      local $SIG{'ALRM'} = sub { die "Alarm\n" } if $lim;
      local $SIG{'PIPE'} = 'IGNORE';

      # Limit its execution to prevent RDA hangs
      alarm($lim) if $lim;

      # Execute the command
      if ($pid = open(OUT, "| $val"))
      { syswrite(OUT, $ctl->{'inp'}, length($ctl->{'inp'}))
          if exists($ctl->{'inp'});
        close(OUT);
      }
      alarm(0) if $lim;
      };
    $slf->{'err'} = $ctl->{'sta'} = $?;
    $wrk->clean_work($PWF) if $pwf;

    # Treat the results
    if ($pid)
    { # Abort sub process when timeout
      if ($sta = $@)
      { RDA::Object::Rda->kill_child($pid);
        _log_timeout($slf, $ctx, $cmd);
        $slf->{'err'} = $ctl->{'sta'} = -1;
      }

      # Process the standard output
      push(@rpt, _end_collect($ctx, $out, $wrk, $ctl, $ctl->{'out'},
        ['C', $cmd], '.out'));

      # Process the standard error
      push(@rpt, _end_collect($ctx, $out, $wrk, $ctl, $ctl->{'err'},
        ['E', $cmd], '.err'));
    }
    else
    { _no_collect($ctl->{'out'});
      _no_collect($ctl->{'err'});
    }
  }

  # Indicate the command completion
  return @rpt unless exists($ctl->{'ret'});
  $val = $ctl->{'ret'};
  return (map {_get_collect($ctl, $_)} @$val) if ref($val) eq 'ARRAY';
  _get_collect($ctl, $val, 1);
}

sub _beg_collect
{ my ($out, $wrk, $nam, $dsc, $cat, $pre, $fmt, $ext) = @_;
  my ($rpt);

  # Treat a file request
  if (exists($dsc->{'fil'}))
  { delete($dsc->{'rpt'});
    delete($dsc->{'wrk'});
    ($dsc->{'mod'}, $dsc->{'fil'}) = (0, RDA::Object::Rda->dev_null)
      unless defined($dsc->{'fil'}) && length($dsc->{'fil'});
    $dsc->{'arg'} = $pre
      .($dsc->{'mod'} ? '>' : '')
      .(($dsc->{'fil'} =~ m/^\&\d+$/) ? $dsc->{'fil'}
                                      : RDA::Object::Rda->quote($dsc->{'fil'}));
    return;
  }

  # Treat a filter request
  $dsc->{'cat'} = $cat unless exists($dsc->{'cat'});
  $dsc->{'ext'} = $ext unless exists($dsc->{'ext'});
  if ($dsc->{'flt'} || $dsc->{'fct'} || $out->is_filtered)
  { $dsc->{'wrk'} = $wrk->get_work($dsc->{'flt'} = $fmt, 1);
    $dsc->{'arg'} = $pre.$dsc->{'wrk'};
    return;
  }

  # Treat a report request
  delete($dsc->{'wrk'});
  if (ref($dsc->{'rpt'}) eq 'RDA::Object::Report')
  { $rpt = $dsc->{'rpt'};
    $dsc->{'arg'} = $pre.'>'
      .RDA::Object::Rda->quote($dsc->{'fil'} = $rpt->get_path);
    $dsc->{'end'} = 0 unless exists($dsc->{'end'});
    $dsc->{'kpt'} = $dsc->{'mod'} = 1;
  }
  else
  { $dsc->{'rpt'} = $rpt = $out->add_report('d', $nam, 0, $ext);
    $dsc->{'arg'} = $pre
      .RDA::Object::Rda->quote($dsc->{'fil'} = $rpt->get_path);
    $dsc->{'end'} = 1 unless exists($dsc->{'end'});
    $dsc->{'mod'} = 0;
  }
  $rpt->begin_block($dsc->{'blk'});
  if (defined($dsc->{'cat'}))
  { $rpt->add_block('E', $dsc->{'cat'}, $nam.$dsc->{'ext'});
  }
  else
  { delete($dsc->{'dup'});
  }
  $rpt->close;
}

sub _end_collect
{ my ($ctx, $out, $wrk, $ctl, $dsc, $idx, $ext) = @_;
  my ($blk, $rpt, $val, @cat, @rpt);

  if (exists($dsc->{'wrk'}))
  { if ($dsc->{'kpt'} || -s $dsc->{'wrk'})
    { if (ref($dsc->{'rpt'}) eq 'RDA::Object::Report')
      { $rpt = $dsc->{'rpt'};
        $dsc->{'end'} = 0 unless exists($dsc->{'end'});
        $dsc->{'kpt'} = $dsc->{'mod'} = 1;
      }
      else
      { $dsc->{'rpt'} = $rpt = $out->add_report('d', $ctl->{'nam'}, 0, $ext);
        $dsc->{'end'} = 1 unless exists($dsc->{'end'});
        $dsc->{'mod'} = 0;
      }
      $dsc->{'fil'} = $rpt->get_path;
      if (defined($dsc->{'cat'}))
      { @cat = (['E', $dsc->{'cat'}, $ctl->{'nam'}.$dsc->{'ext'}]);
      }
      else
      { delete($dsc->{'dup'});
      }
      if (ref($ctl->{'idx'}))
      { $rpt->begin_block;
        $rpt->end_block('-', delete($ctl->{'idx'}));
      }
      $rpt->write($dsc->{'hdr'}."\n") if exists($dsc->{'hdr'});
      if (exists($dsc->{'fct'}))
      { $rpt->begin_block($dsc->{'blk'});
        $val = RDA::Value::List->new(
          RDA::Value::Scalar::new_object($rpt),
          RDA::Value::Scalar::new_object(
            RDA::Object::Buffer->new('R', $dsc->{'wrk'})),
          RDA::Value::Assoc::new_from_data(%$ctl));
        if ($dsc->{'fct'} =~ m/^(caller:(\w+))$/)
        { $blk = $ctx->get_current;
          $val = $blk->define_operator([$2, '.macro.'], $blk, $2, $val)
        }
        else
        { $val = $ctx->define_operator([$dsc->{'fct'}, '.macro.'], $ctx,
            $dsc->{'fct'}, $val);
        }
        $val->eval_value;
        $rpt->end_block($idx, @cat);
        if ($dsc->{'kpt'} || -s $dsc->{'fil'})
        { push(@rpt, $rpt->get_report);
        }
        else
        { delete($dsc->{'fil'});
          $rpt->unlink;
        }
      }
      elsif ($dsc->{'blk'})
      { $rpt->write_file($dsc->{'wrk'},$idx, @cat);
        push(@rpt, $rpt->get_report);
      }
      else
      { $rpt->write_data($dsc->{'wrk'},$idx, @cat);
        push(@rpt, $rpt->get_report);
      }
      $rpt->dup_block('E', @{$dsc->{'dup'}})
        if ref($dsc->{'dup'}) eq 'ARRAY';
      $rpt->write($dsc->{'ftr'}."\n") if exists($dsc->{'ftr'});
      $out->end_report(delete($dsc->{'rpt'})) if $dsc->{'end'};
    }
    elsif ($dsc->{'idx'})
    { $ctl->{'idx'} = ['E', $dsc->{'cat'}, $ctl->{'nam'}.$dsc->{'ext'}]
        if defined($dsc->{'cat'});
    }
    delete($dsc->{'wrk'});
    $wrk->clean_work($dsc->{'flt'});
  }
  elsif (exists($dsc->{'rpt'}))
  { if ($dsc->{'kpt'} || -s $dsc->{'fil'})
    { $rpt = $dsc->{'rpt'};
      $rpt->update(1);
      $rpt->end_block($idx);
      $rpt->dup_block('E', @{$dsc->{'dup'}})
        if ref($dsc->{'dup'}) eq 'ARRAY';
      push(@rpt, $rpt->get_report);
    }
    else
    { $dsc->{'rpt'}->unlink;
    }
    $out->end_report(delete($dsc->{'rpt'})) if $dsc->{'end'};
  }
  @rpt;
}

sub _get_collect
{ my ($ctl, $key, $flg) = @_;
  my ($val);

  if (!ref($key) && defined($key) && length($key))
  { return _get_collect($ctl->{$1}, $key, $flg) if $key =~ s/(err|out)_?//;
    $val = $ctl->{$key} if exists($ctl->{$key});
  }
  if ($flg)
  { return ($val) if defined($val);
    return ();
  }
  $val;
}

sub _no_collect
{ my ($dsc) = @_;

  delete($dsc->{'wrk'});
  if (exists($dsc->{'rpt'}) && !exists($dsc->{'wrk'}) && !$dsc->{'mod'})
  { delete($dsc->{'fil'});
    delete($dsc->{'rpt'})->unlink;
  }
}

=head2 S<collectData($request,$file)>

This macro collects the content of a binary file or a buffer without any
transformation. On successful completion, it creates an entry in the Explorer
catalog. It returns the list of the generated reports.

=cut

sub _m_collect_data
{ my ($slf, $ctx, $req, $fil, $idx, $cat) = @_;
  my ($out, $rpt, @rpt);

  if (defined($req) && defined($fil))
  { $req =~ s#^/##;
    $req =~ s#[^\-\+\=\@\.\/A-Za-z0-9]+#_#g;
    $cat = (ref($cat) eq 'RDA::Value::Array')
       ? $cat->eval_as_data(1)
       : ['E', 'B', $req];
    $idx = (ref($idx) eq 'RDA::Value::Array')
       ? $idx->eval_as_data(1)
       : undef;
    $out = $ctx->get_output;
    $rpt = $out->add_report('b', $req, 0, '.bin');
    push(@rpt, $rpt->get_file) if $rpt->write_data($fil, $idx, $cat);
    $out->end_report($rpt);
  }
  @rpt;
}

=head2 S<collectFile($request,$file)>

This macro collects the content of a data file or a buffer. On successful
completion, it creates an entry in the Explorer catalog. It returns the list of
the generated reports.

=cut

sub _m_collect_file
{ my ($slf, $ctx, $req, $fil, $idx, $cat) = @_;
  my ($out, $rpt, @rpt);

  if (defined($req) && defined($fil))
  { $req =~ s#^/##;
    $req =~ s#[^\-\+\=\@\.\/A-Za-z0-9]+#_#g;
    $cat = (ref($cat) eq 'RDA::Value::Array')
       ? $cat->eval_as_data(1)
       : ['E', 'D', $req];
    $idx = (ref($idx) eq 'RDA::Value::Array')
       ? $idx->eval_as_data(1)
       : undef;
    $out = $ctx->get_output;
    $rpt = $out->add_report('d', $req, 0, '.lin');
    push(@rpt, $rpt->get_file)
      if $rpt->write_data($fil, $idx, $cat);
    $out->end_report($rpt);
  }
  @rpt;
}

=head2 S<countCommand($cmd[,$re...])>

This macro returns the number of lines in the specified command. You can search
additional regular expressions also. It returns a list containing the
respective counters.

=head2 S<countFile($file[,$re...])>

This macro returns the number of lines in the specified file. You can search
additional regular expressions also. It returns a list containing the
respective counters.

=head2 S<countLast([$re...])>

This macro returns the number of lines in the last file/command buffer. You can
search additional regular expressions also. It returns a list containing the
respective counters.

=cut

sub _m_count_cmd
{ my ($slf, $ctx, $cmd, @arg) = @_;
  my ($err, $ifh, $pid, $tmp, @tbl);

  $slf->{'err'} = 0;
  ++$slf->{'_req'};

  $ifh = IO::Handle->new;
  if (exists($slf->{'_wrk'}))
  { # When requested, treat the command output through a temporary file
    ($err, undef, $tmp) = _get_output($slf, $ctx, $cmd, 1);
    if ($tmp && open($ifh, "<$tmp"))
    { @tbl = _count_in($slf, $ctx, $ifh, 0, 0, 0, 0, $err, @arg);
      $slf->{'_wrk'}->get_output->clean_work($WRK);
    }
    else
    { $slf->{'err'} = $err;
    }
  }
  else
  { # Treat the output on the fly
    local $SIG{'__WARN__'} = sub { };
    if ($cmd = _conv_cmd($slf, $cmd))
    { return _count_in($slf, $ctx, $ifh, 0, $cmd, $slf->{'lim'}, $pid, 0, @arg)
        if ($pid = open($ifh, "$cmd |"));
      $slf->{'err'} = $?;
    }
  }
  return @tbl;
}

sub _m_count_file
{ my ($slf, $ctx, $fil, @arg) = @_;
  my ($ifh);

  $ifh = IO::Handle->new;
  return () unless $fil && open($ifh, "<$fil");
  _count_in($slf, $ctx, $ifh, 1, 0, 0, 0, 0, @arg);
}

sub _m_count_last
{ my ($slf, $ctx, @arg) = @_;

  _count_in($slf, $ctx,
     RDA::Object::Buffer->new('l', $slf->{'_buf'})->get_handle, 0, 0, 0, 0, 0,
     @arg);
}

sub _count_in
{ my ($slf, $ctx, $ifh, $fil, $cmd, $lim, $pid, $err, @arg) = @_;
  my ($off, $sta, @tb_cnt, @tb_re);

  $slf->{'err'} = $err;
  eval {
    local $SIG{'ALRM'} = sub { die "Alarm\n"; } if $lim;

    # Get the regular expressions
    push(@tb_cnt, 0);
    foreach my $str (@arg)
    { next unless defined($str);
      push(@tb_re, qr#$str#);
      push(@tb_cnt, 0);
    }

    # Scan the input
    alarm($lim) if $lim;
    while (<$ifh>)
    { ++$tb_cnt[$off = 0];
      s/^\000+$//;
      foreach my $re (@tb_re)
      { ++$off;
        ++$tb_cnt[$off] if $_ =~ $re;
      }
    }
    alarm(0) if $lim;
  };
  RDA::Object::Rda->kill_child($pid) if ($sta = $@) && $pid;
  close($ifh);
  if ($sta)
  { _log_timeout($slf, $ctx, $cmd);
  }
  elsif ($cmd)
  { $slf->{'err'} = $?;
  }
  $slf->{'lgt'} = $tb_cnt[0] if $fil;

  # Return the counter array
  @tb_cnt;
}

=head2 S<dirname($file)>

This macro returns the directory portion of the input file specification.

=cut

sub _m_dirname
{ my ($slf, $ctx, @arg) = @_;

  dirname(@arg);
}

=head2 S<findDir($dir,$re[,$options[,$depth]])>

This macro returns the subdirectories that correspond to the specified pattern
from the specified directory. It supports the following options:

=over 9

=item B<    'd' > Sorts the subdirectories per directory, then by name

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the name

=item B<    'n' > Sorts the subdirectories by name

=item B<    'm(n)'> Keeps subdirectories modified during last (n) days only

=item B<    'p' > Returns the full directory path

=item B<    'r' > Reads subdirectories under each directory recursively

=item B<    't' > Sorts the subdirectories by modification time

=item B<    'v' > Inverts the sense of matching to select nonmatching names

=item B<    'w' > Returns where the subdirectory has been found

=back

The depth argument controls how far you can descend in the subdirectories. It
is limited to 8 levels by default.

You can also specify the directory as an array reference containing a base
directory and an optional relative path from where the search must be
done. Unless you require a full path, the returned paths are relative to the
base directory.

=cut

sub _m_find_dir
{ my ($slf, $ctx, $dir, $re, $opt, $max) = @_;
  my ($bas, $fct, $flg, $f_f, $f_m, $f_p, $f_r, $f_v, $f_w, $rel, @tbl, %mod);

  # Abort if we can access to that directory
  if (ref($dir) eq 'RDA::Value::Array')
  { ($bas, $rel) = @$dir;
    $rel = (defined($rel) && $rel->is_defined) ? $rel->eval_as_string : '.';
    $dir = (defined($bas) && $bas->is_defined)
      ? RDA::Object::Rda->cat_dir($bas = $bas->eval_as_string, $rel)
      : undef;
    $flg = 0;
  }
  else
  { $bas = $dir;
    $rel = '.';
    $flg = 1;
  }
  return @tbl unless $dir && opendir(DIR, $dir);
  $bas = '' if $bas =~ m/^[\\\/]$/;

  # Decode the options
  $opt = '' unless defined($opt);
  $re  = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
  $f_f = index($opt, 'f') >= 0;
  $f_m = ($opt =~ m/m(\d+(\.\d+)?)/) ? (time - 86400 * $1) : 0;
  $f_p = index($opt, 'p') >= 0;
  $f_r = index($opt, 'r') >= 0;
  $f_v = index($opt, 'v') >= 0;
  $f_w = index($opt, 'w') >= 0;
  $f_p = 1 if $flg && $f_r;
  $max = 8 unless defined($max) && $max >= 0;

  # Read the directory content
  $fct = $slf->{'_mod'};
  _find_dir(\@tbl, $bas, $rel, $re, 0, $max, $fct, $f_f, $f_m, $f_p, $f_r,
    $f_v, $f_w);

  # Sort the directory names when requested
  if (index($opt, 'd') >= 0)
  { return sort {dirname($a)  cmp dirname($b) ||
                 basename($a) cmp basename($b)} @tbl;
  }
  if (index($opt, 'n') >= 0)
  { return sort {$a cmp $b} @tbl;
  }
  if (index($opt, 't') >= 0)
  { %mod = map {$_ =>
      &$fct($f_p ? $_ : RDA::Object::Rda->cat_file($bas, $_), 0)} @tbl;
    return sort {$mod{$b} <=> $mod{$a} || $a cmp $b} keys(%mod);
  }

  # Return the list of the directories
  @tbl;
}

sub _find_dir
{ my ($tbl, $bas, $dir, $re, $lvl, $max, $fct, $f_f, $f_m, $f_p, $f_r, $f_v,
    $f_w) = @_;
  my ($flg, $pth, $rel, $skp, @sub);

  # Read the directory content
  foreach my $nam (readdir(DIR))
  { $rel = RDA::Object::Rda->cat_dir($dir, $nam);
    next unless -d ($pth = RDA::Object::Rda->cat_file($bas, $rel));
    push(@sub, $rel) if $f_r && -r $pth && $nam !~ m/^\.+$/;
    next if $skp;
    $flg = $f_v ? ($nam !~ $re) : ($nam =~ $re);
    $flg = (&$fct($pth, 0) > $f_m) if $flg && $f_m;
    if ($flg)
    { if ($f_w)
      { push(@$tbl, ($f_p ? RDA::Object::Rda->cat_dir($bas, $dir) : $dir));
        $skp = 1;
      }
      else
      { push(@$tbl, ($f_p ? $pth : $rel));
      }
      if ($f_f)
      { $lvl = $max;
        last;
      }
    }
  }
  closedir(DIR);

  # Explore subdirectories
  unless (++$lvl > $max)
  { foreach my $sub (@sub)
    { next unless opendir(DIR, RDA::Object::Rda->cat_dir($bas, $sub));
      _find_dir($tbl, $bas, $sub, $re, $lvl, $max, $fct, $f_f, $f_m, $f_p,
        $f_r, $f_v, $f_w);
      return if $f_f && @$tbl;
    }
  }
}

=head2 S<getHeader([$default])>

This macro returns the first line of the last C<grepCommand> or C<grepFile>.

=cut

sub _m_get_header
{ my ($slf, $ctx, $str) = @_;

  $str = $slf->{'hdr'} if exists($slf->{'hdr'});
  $str;
}

=head2 S<getLastAccess($file[,$fmt])>

This macro returns the last access time. Unless a format is specified, it
returns the number of seconds since the epoch.

=cut

sub _m_get_atime
{ my ($slf, $ctx, $fil, $fmt) = @_;

  my $tim = (stat($fil))[8];
  defined($tim) ? _fmt_time($tim, $fmt) : $tim;
}

sub _fmt_time
{ my ($tim, $fmt) = @_;
  my (@tim);

  if ($fmt)
  { eval {
      require POSIX;
      @tim = gmtime($tim);
      $tim[-1] = -1;
      $tim = &POSIX::strftime($fmt, @tim);
    };
    return $tim unless $@;
  }
  $tim;
}

=head2 S<getLastBuffer([$flag])>

This macro returns the last file/command buffer. Unless the flag is set, it
assumes Wiki data.

=cut

sub _m_get_buffer
{ my ($slf, $ctx, $flg) = @_;

  RDA::Object::Buffer->new($flg ? 'L' : 'l', $slf->{'_buf'});
}

=head2 S<getLastChange($file[,$format])>

This macro returns the inode change time. Unless a format is specified, it
returns the number of seconds since the epoch.

=cut

sub _m_get_ctime
{ my ($slf, $ctx, $fil, $fmt) = @_;

  my $tim = (stat($fil))[10];
  defined($tim) ? _fmt_time($tim, $fmt) : $tim;
}

=head2 S<getLastLength()>

This macro returns the number of lines in the last file/command buffer.

=cut

sub _m_get_last_lgt
{ shift->{'cnt'};
}

=head2 S<getLastModify($file[,$format])>

This macro returns the last modify time. Unless a format is specified, it
returns the number of seconds since the epoch.

=cut

sub _m_get_mtime
{ my ($slf, $ctx, $fil, $fmt) = @_;

  my $tim = (stat($fil))[9];
  defined($tim) ? _fmt_time($tim, $fmt) : $tim;
}

=head2 S<getLength()>

This macro returns the number of lines read for the last file operation (see
C<countFile>, C<grepFile> macros).

=cut

sub _m_get_file_lgt
{ shift->{'lgt'};
}

=head2 S<getLines([$min[,$max]])>

This macro returns a range of the lines stored in the last file/command
buffer. It assumes the first and last line as the default for the range
definition. You can use negative line numbers to specify lines from the
buffer end.

=cut

sub _m_get_lines
{ my ($slf, $ctx, $min, $max) = @_;
  my $buf;

  return () unless exists($slf->{'_buf'});

  # Validate the range
  $buf = $slf->{'_buf'};
  $min = (!defined($min) || ($#$buf + $min) < -1) ? 0 :
         ($min < 0) ? $#$buf + $min + 1 :
         $min;
  $max = (!defined($max)) ? $#$buf :
         (($#$buf + $max) < -1) ? 0 :
         ($max < 0) ? $#$buf + $max + 1 :
         ($max > $#$buf) ? $#$buf :
         $max;

  # Return the line range
  @$buf[$min..$max];
}

=head2 S<getNativePath($path)>

This macro converts the path to its native representation. It does not make any
transformation for UNIX.

=cut

sub _m_native_path
{ my ($slf, $ctx, $pth) = @_;

  RDA::Object::Rda->native($pth);
}

=head2 S<getOwner($file)>

This macro returns the user identifier of the file owner or an undefined value
in case of error.

=cut

sub _m_get_owner
{ my ($slf, $ctx, $fil) = @_;

  (stat($fil))[4];
}

=head2 S<getShortPath($path)>

This macro converts the path to its native representation using only short
names. It does not make any transformation for UNIX.

=cut

sub _m_short_path
{ my ($slf, $ctx, $pth) = @_;

  RDA::Object::Rda->short($pth);
}

=head2 S<getSize($file)>

This macro returns the total size of the file, in bytes, or an undefined value
in case of error.

=cut

sub _m_get_size
{ my ($slf, $ctx, $fil) = @_;

  (stat($fil))[7];
}

=head2 S<getStat($file)>

This macro returns the status information of the file, in bytes, or an empty
list in case of error.

The following fields are present:

=over 8

=item B<     0 > Device number of file system

=item B<     1 > Inode number

=item B<     2 > File mode (type and permissions)

=item B<     3 > Number of (hard) links to the file

=item B<     4 > User identifier of file owner

=item B<     5 > Group identifier of file owner

=item B<     6 > Device identifier (special files only)

=item B<     7 > Total size of file (in bytes)

=item B<     8 > Last access time in seconds since the epoch

=item B<     9 > Last modify time in seconds since the epoch

=item B<    10 > Inode change time in seconds since the epoch

=item B<    11 > Preferred block size for file system I/O

=item B<    12 > Actual number of blocks allocated

=back

Their effective use depends on file systems.

=cut

sub _m_get_stat
{ my ($slf, $ctx, $fil) = @_;

  stat($fil);
}

=head2 S<getTimeout()>

This macro returns the current duration of the timeout for executing operating
system commands or 0 when this mechanism is disabled.

=cut

sub _m_get_timeout
{ shift->{'lim'};
}

=head2 S<grepDir($dir,$re[,$options[,$depth]])>

This macro returns the files that correspond to the specified pattern from the
specified directory. It supports the following options:

=over 9

=item B<    'd' > Sorts the files per directory, then by name

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the file

=item B<    'n' > Sorts the files by name

=item B<    'm(n)'> Keeps files modified during last (n) days only

=item B<    'p' > Returns the full file path

=item B<    'r' > Reads files under each directory recursively

=item B<    't' > Sorts the files by modification time

=item B<    'v' > Inverts the sense of matching to select nonmatching files

=item B<    'w' > Returns where the file has been found

=back

The depth argument controls how far you can descend in the subdirectories. It
is limited to 8 levels by default.

You can also specify the directory as an array reference containing a base
directory and an optional relative path from where the search must be
done. Unless you require a full path, the returned paths are relative to the
base directory.

=cut

sub _m_grep_dir
{ my ($slf, $ctx, $dir, $re, $opt, $max) = @_;
  my ($bas, $fct, $flg, $f_f, $f_m, $f_p, $f_r, $f_v, $f_w, $rel, @tbl, %mod);

  # Abort if we can access to that directory
  if (ref($dir) eq 'RDA::Value::Array')
  { ($bas, $rel) = @$dir;
    $rel = (defined($rel) && $rel->is_defined) ? $rel->eval_as_string : '.';
    $dir = (defined($bas) && $bas->is_defined)
      ? RDA::Object::Rda->cat_dir($bas = $bas->eval_as_string, $rel)
      : undef;
    $flg = 0;
  }
  else
  { $bas = $dir;
    $rel = '.';
    $flg = 1;
  }
  return @tbl unless $dir && opendir(DIR, $dir);
  $bas = '' if $bas =~ m/^[\\\/]$/;

  # Decode the options
  $opt = '' unless defined($opt);
  $re  = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
  $f_f = index($opt, 'f') >= 0;
  $f_m = ($opt =~ m/m(\d+(\.\d+)?)/) ? (time - 86400 * $1) : 0;
  $f_p = index($opt, 'p') >= 0;
  $f_r = index($opt, 'r') >= 0;
  $f_v = index($opt, 'v') >= 0;
  $f_w = index($opt, 'w') >= 0;
  $f_p = 1 if $flg && $f_r;
  $max = 8 unless defined($max) && $max >= 0;

  # Read the directory content
  $fct = $slf->{'_mod'};
  _grep_dir(\@tbl, $bas, $rel, $re, 0, $max, $fct, $f_f, $f_m, $f_p, $f_r,
    $f_v, $f_w);

  # Sort the file names when requested
  if (index($opt, 'd') >= 0)
  { return sort {dirname($a)  cmp dirname($b) ||
                 basename($a) cmp basename($b)} @tbl;
  }
  if (index($opt, 'n') >= 0)
  { return sort {$a cmp $b} @tbl;
  }
  if (index($opt, 't') >= 0)
  { %mod = map {$_ =>
      &$fct($f_p ? $_ : RDA::Object::Rda->cat_file($bas, $_), 0)} @tbl;
    return sort {$mod{$b} <=> $mod{$a} || $a cmp $b} keys(%mod);
  }

  # Return the list of the files
  @tbl;
}

sub _grep_dir
{ my ($tbl, $bas, $dir, $re, $lvl, $max, $fct, $f_f, $f_m, $f_p, $f_r, $f_v,
    $f_w) = @_;
  my ($flg, $pth, $rel, $skp, @sub);

  # Read the directory content
  foreach my $nam (readdir(DIR))
  { $rel = RDA::Object::Rda->cat_file($dir, $nam);
    $pth = RDA::Object::Rda->cat_file($bas, $rel) if $f_m || $f_p || $f_r;
    push(@sub, $rel) if $f_r && -d $pth && -r $pth && $nam !~ m/^\.+$/;
    next if $skp;
    $flg = $f_v ? ($nam !~ $re) : ($nam =~ $re);
    $flg = (&$fct($pth, 0) > $f_m) if $flg && $f_m;
    if ($flg)
    { if ($f_w)
      { push(@$tbl, ($f_p ? RDA::Object::Rda->cat_dir($bas, $dir) : $dir));
        $skp = 1;
      }
      else
      { push(@$tbl, ($f_p ? $pth : $rel));
      }
      if ($f_f)
      { $lvl = $max;
        last;
      }
    }
  }
  closedir(DIR);

  # Explore subdirectories
  unless (++$lvl > $max)
  { foreach my $sub (@sub)
    { next unless opendir(DIR, RDA::Object::Rda->cat_dir($bas, $sub));
      _grep_dir($tbl, $bas, $sub, $re, $lvl, $max, $fct, $f_f, $f_m, $f_p,
        $f_r, $f_v, $f_w);
      return if $f_f && @$tbl;
    }
  }
}

=head2 S<grepCommand($command,$re[,$options[,$length[,$min,$max]]])>

This macro returns the command output lines that match the regular expression.

=head2 S<grepFile($file,$re[,$options[,$length[,$min,$max]]])>

This macro returns the file lines that match the regular expression.

The following options are supported:

=over 9

=item B<    'c' > Returns the match count instead of the match list

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the line

=item B<    'j' > Joins continuation lines

=item B<    'n' > Prefixes lines with a line number

=item B<    'v' > Inverts the sense of matching to select nonmatching lines

=item B<    (n) > Returns the (n)th capture buffer instead of the line.

=back

You can limit the number of matched lines to the specified number. When the
number is positive, it returns the first matches only. When it is negative,
it returns the last matches only.

You can restrict the search to a line range.

When the file is read completely, the macro stores the number of lines
contained in the file and this number is accessible by the C<getLength> macro.

=cut

sub _m_grep_cmd
{ my ($slf, $ctx, $cmd, $re, @arg) = @_;
  my ($err, $pid, $tmp, @tbl);

  $slf->{'err'} = 0;
  ++$slf->{'_req'};

  if (exists($slf->{'_wrk'}))
  { # When requested, treat the command output through a temporary file
    ($err, undef, $tmp) = _get_output($slf, $ctx, $cmd, 1);
    if ($tmp && open(IN, "<$tmp"))
    { @tbl = _grep_in($slf, $ctx, 0, 0, 0, 0, $err, $re, @arg);
      $slf->{'_wrk'}->get_output->clean_work($WRK);
    }
    else
    { $slf->{'err'} = $err;
    }
    return @tbl;
  }
  else
  { # Treat the command output on the fly
    local $SIG{'__WARN__'} = sub { };
    if (($cmd = _conv_cmd($slf, $cmd)) && $re)
    { return _grep_in($slf, $ctx, 0, $cmd, $slf->{'lim'}, $pid, 0, $re, @arg)
        if ($pid = open(IN, "$cmd |"));
      $slf->{'err'} = $?;
    }
  }
  return @tbl;
}

sub _m_grep_file
{ my ($slf, $ctx, $fil, $re, @arg) = @_;

  return () unless $fil && $re && open(IN, "<$fil");
  _grep_in($slf, $ctx, 1, 0, 0, 0, 0, $re, @arg);
}

sub _grep_in
{ my ($slf, $ctx, $fil, $cmd, $lim, $pid, $err, $re, $opt, $lgt, $min, $max)
    = @_;
  my ($all, $beg, $cnt, $end, $flg, $f_c, $f_i, $f_n, $inc, $lin, $nxt, $pos,
      $sta, @tbl);

  # Determine the options
  $min = 0 unless $min && $min > 0;
  $max = 0 unless $max && $max > 0;
  $opt = '' unless defined($opt);
  $re = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
  $f_c = index($opt, 'c') >= 0;
  $f_i = index($opt, 'v') >= 0;
  $f_n = index($opt, 'n') >= 0;
  $inc = 0 if index($opt, 'j') >= 0;
  $pos = ($opt =~ m/(\d+)/) ? $1 : 0;

  # Check the file
  $slf->{'err'} = $err;
  eval {
    local $SIG{'ALRM'} = sub { die "Alarm\n"; } if $lim;

    # Restrict the number of records returned
    $beg = $end = $cnt = 0;
    if ($lgt)
    { $beg = $lgt  if $lgt > 0;
      $end = -$lgt if $lgt < 0;
    }
    elsif (index($opt, 'f') >= 0)
    { $beg = 1;
    }

    # Scan the file
    $all = 1;
    $lin = '';
    $tbl[0] = 0 if $f_c;
    delete($slf->{'hdr'});
    alarm($lim) if $lim;
    while (defined($lin = <IN>))
    { $lin =~ s/[\r\n]+$//;
      if (defined($inc))
      { $cnt += $inc;
        $inc = 0;
        while ($lin =~ s/\\$// && defined($nxt = <IN>))
        { $nxt =~ s/[\r\n]+$//;
          $lin .= $nxt;
          $inc++;
        }
      }
      $lin =~ s/^\000+$//;
      $slf->{'hdr'} = $lin unless $cnt++;
      next if $cnt < $min;
      $all = 0;
      last if $max && $cnt > $max;
      $flg = ($lin =~ $re);
      if ($f_i ? !$flg : $flg)
      { if ($f_c)
        { ++$tbl[0];
        }
        else
        { $lin = eval "\$$pos" if $pos;
          push(@tbl, $f_n ? "$cnt:$lin" : $lin);
          last if $beg && (scalar @tbl) == $beg;
          shift(@tbl) if $end && (scalar @tbl) > $end;
        }
      }
      $all = 1;
    }
    alarm(0) if $lim;
  };
  RDA::Object::Rda->kill_child($pid) if ($sta = $@) && $pid;
  close(IN);
  if ($sta)
  { _log_timeout($slf, $ctx, $cmd);
  }
  elsif ($cmd)
  { $slf->{'err'} = $?;
  }
  $slf->{'lgt'} = $cnt if $all && $fil;

  # Return the matches
  @tbl;
}

=head2 S<grepLastFile($re[,$options[,$length[,$min,$max]]])>

This macro returns the lines in the last file/command buffer that match the
regular expression. It supports the same options as C<grepFile>.

=cut

sub _m_grep_last
{ my ($slf, $ctx, $re, $opt, $lgt, $min, $max) = @_;
  my ($beg, $buf, $cnt, $end, $flg, $f_c, $f_i, $f_n, $inc, $lin, $nxt, $pos,
      @tbl);

  if (exists($slf->{'_buf'}) && $re)
  { # Determine the options
    $min = 0 unless $min && $min > 0;
    $max = 0 unless $max && $max > 0;
    $opt = '' unless defined($opt);
    $re = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
    $f_c = index($opt, 'c') >= 0;
    $f_i = index($opt, 'v') >= 0;
    $f_n = index($opt, 'n') >= 0;
    $inc = 0 if index($opt, 'j') >= 0;
    $pos = ($opt =~ m/(\d+)/) ? $1 : 0;

    # Restrict the number of records returned
    $beg = $end = 0;
    if ($lgt)
    { $beg = $lgt  if $lgt > 0;
      $end = -$lgt if $lgt < 0;
    }
    elsif (index($opt, 'f') >= 0)
    { $beg = 1;
    }

    # Check the file
    $tbl[0] = 0 if $f_c;
    $buf = $slf->{'_buf'};
    $cnt = 0;
    while ($cnt <= $#$buf)
    { if (defined($inc))
      { $cnt += $inc;
        $lin = $buf->[$cnt++];
        $inc = 0;
        $lin .= $buf->[$inc++ + $cnt]
          while ($lin =~ s/\\$// && ($cnt + $inc) <= $#$buf);
      }
      else
      { $lin = $buf->[$cnt++];
      }
      next if $cnt < $min;
      last if $max && $cnt > $max;
      $flg = ($lin =~ $re);
      if ($f_i ? !$flg : $flg)
      { if ($f_c)
        { ++$tbl[0];
        }
        else
        { $lin = eval "\$$pos" if $pos;
          push(@tbl, $f_n ? "$cnt:$lin" : $lin);
          last if $beg && (scalar @tbl) == $beg;
          shift(@tbl) if $end && (scalar @tbl) > $end;
        }
      }
    }
  }
  @tbl;
}

=head2 S<isNewer($file,$day[,$sec])>

This macro indicates if the file is newer than the specified period. It
returns a false value if it cannot obtain the status information of the file.

=cut

sub _m_is_newer
{ my ($slf, $ctx, $fil, $day, $sec) = @_;
  my ($ref, @sta);

  # Get the reference time
  $day = 0 unless defined($day);
  $sec = 0 unless defined($sec);
  $ref = time - $day * 86400 - $sec;

  # Check the modification time of the file
  &{$slf->{'_mod'}}($fil, 0) > $ref;
}

=head2 S<isOlder($file,$day[,$sec])>

This macro indicates if the file is older than the specified period. It
returns a false value if it cannot obtain the status information of the file.

=cut

sub _m_is_older
{ my ($slf, $ctx, $fil, $day, $sec) = @_;
  my ($ref, @sta);

  # Get the reference time
  $day = 0 unless defined($day);
  $sec = 0 unless defined($sec);
  $ref = time - $day * 86400 - $sec;

  # Check the modification time of the file
  &{$slf->{'_mod'}}($fil, $ref) < $ref;
}

=head2 S<kill($sig,$pid...)>

This macro sends a signal to a list of processes. It returns the number of
processes successfully signaled, which is not necessarily the same as the
number of processes killed.

If the signal number is zero, then no signal is sent to the process. This is a
useful way to check that a child process is alive and has not changed its user
identifier. If the signal number is negative, then it kills process groups
instead of processes.

=cut

sub _m_kill
{ my ($slf, $ctx, $sig, @pid) = @_;

  kill($sig, @pid);
}

=head2 S<lastCommand()>

This macro returns the last file produced by the C<catCommand> or C<catFile>
macro, quoted as appropriate to execute it in a shell.

=cut

sub _m_last_command
{ my $slf = shift;

  RDA::Object::Rda->quote($slf->{'_fil'});
}

=head2 S<lastDir()>

This macro returns the last directory produced by the C<catDir> macro.

=cut

sub _m_last_dir
{ shift->{'_dir'};
}

=head2 S<lastFile()>

This macro returns the last file produced by the C<catCommand> or C<catFile>
macro.

=cut

sub _m_last_file
{ shift->{'_fil'};
}

=head2 S<loadCommand($command[,$flag[,$incr[,$length]]])>

This macro loads the result of the specified command. It returns 1 for a
successful load. Otherwise, it returns 0. It saves the effective command exit
code and it is accessible through the C<statCommand> macro. When the flag is
set, the load is considered successful regardless of the exit code.

It is possible to increase the execution limit by specifying an increasing
factor as an argument. A negative or null (zero) value disables any timeout.

It is possible to limit the number of lines loaded to the specified number
also. When the number is positive, it loads the first lines only. When the
number is negative, it loads the last lines only.

=cut

sub _m_load_cmd
{ my ($slf, $ctx, $cmd, $flg, $inc, $lgt) = @_;
  my ($ret, $sta);

  $slf->{'err'} = $ret = 0;
  ++$slf->{'_req'};

  if (exists($slf->{'_wrk'}))
  { my ($err, $tmp);

    # Write the command output using a temporary file
    ($err, $sta, $tmp) = _get_output($slf, $ctx, $cmd, $inc);
    $ret = _m_load_file($slf, $ctx, $tmp, $lgt) if $tmp;
    $slf->{'err'} = $err;

    # Remove the temporary file
    $slf->{'_wrk'}->get_output->clean_work($WRK);

    # Indicate the successful completion
    return $flg ? 1 : $err ? 0 : $ret unless $sta || !$tmp;
    $ret = 0;
  }
  else
  { my ($beg, $buf, $cnt, $end, $lim, $pid);
    local $SIG{'__WARN__'} = sub { };

    if ($cmd = _conv_cmd($slf, $cmd))
    { if ($pid = open(IN, "$cmd |"))
      { eval {
          $lim = $slf->_get_alarm($inc);
          local $SIG{'ALRM'} = sub { die "Alarm\n"; } if $lim;

          # Restrict the number of lines loaded
          $beg = $end = $cnt = 0;
          if ($lgt)
          { $beg = $lgt  if $lgt > 0;
            $end = -$lgt if $lgt < 0;
          }

          # Load the command result, taking care on end of lines
          $slf->{'_buf'} = $buf = [];
          alarm($lim) if $lim;
          while (<IN>)
          { s/[\r\n]+$//;
            s/^\000+$//;
            ++$cnt;
            push(@$buf, $_);
            last if $beg && (scalar @$buf) == $beg;
            if ($end && (scalar @$buf) > $end)
            { shift(@$buf);
              --$cnt;
            }
          }
          alarm(0) if $lim;
        };
        RDA::Object::Rda->kill_child($pid) if ($sta = $@) && $pid;
        close(IN);
        $slf->{'cnt'} = $cnt;
        unless ($sta)
        { $slf->{'err'} = $?;
          return $flg ? 1 : $slf->{'err'} ? 0 : 1;
        }
        _log_timeout($slf, $ctx, $cmd);
        $ret = 0;
      }
      else
      { $slf->{'err'} = $?;
        $ret = 1 if $flg;
      }
    }
  }

  # Indicate the error
  delete($slf->{'_buf'});
  $slf->{'cnt'} = 0;
  $ret;
}

=head2 S<loadFile($file[,$length])>

This macro loads the content of the file. It returns 1 for a successful
completion. Otherwise, it returns 0.

It is possible to limit the number of lines loaded to the specified
number. When the number is positive, it loads the first lines only. When the
number is negative, it loads the last lines only.

=cut

sub _m_load_file
{ my ($slf, $ctx, $fil, $lgt) = @_;
  my ($beg, $buf, $cnt, $end);

  $slf->{'err'} = 0;
  if ($fil && open(IN, "<$fil"))
  { # Restrict the number of lines loaded
    $beg = $end = 0;
    if ($lgt)
    { $beg = $lgt  if $lgt > 0;
      $end = -$lgt if $lgt < 0;
    }

    # Load the file, taking care on end of lines
    $slf->{'_buf'} = $buf = [];
    $cnt = 0;
    while (<IN>)
    { s/[\r\n]+$//;
      s/^\000+$//;
      ++$cnt;
      push(@$buf, $_);
      last if $beg && (scalar @$buf) == $beg;
      if ($end && (scalar @$buf) > $end)
      { shift(@$buf);
        --$cnt;
      }
    }
    close(IN);
    $slf->{'cnt'} = $cnt;

    # Indicate the successful completion
    return 1;
  }

  # Indicate the error
  delete($slf->{'_buf'});
  $slf->{'cnt'} = 0;
}

=head2 S<loadString($file,$re)>

This macro loads the character sequences that match the pattern. It returns 1
for a successful completion. Otherwise, it returns 0.

=cut

sub _m_load_string
{ my ($slf, $ctx, $fil, $re) = @_;
  my ($buf, $nxt);

  $slf->{'cnt'} = $slf->{'err'} = 0;
  if ($re && $fil && open(IN, "<$fil"))
  { $slf->{'_buf'} = [];
    binmode(IN);
    for ($buf = '' ; sysread(IN, $buf, 65536, length($buf)) ; $buf = $nxt)
    { $nxt = ($buf =~ s/([\040-\176]+)$//) ? $1 : '';
      foreach my $str ($buf =~ m#($re)#g)
      { push(@{$slf->{'_buf'}}, $str);
        ++$slf->{'cnt'};
      }
    }
    if ($nxt =~ $re)
    { push(@{$slf->{'_buf'}}, $nxt);
      ++$slf->{'cnt'};
    }
    close(IN);

    # Indicate the successful completion
    return 1;
  }

  # Indicate the error
  delete($slf->{'_buf'});
  0;
}

=head2 S<parseFile($path[,@suf])>

This macro divides a file path into the directories, its file name, and
optionally the file suffix. The directory part contains everything up to and
including the last directory separator in the $path including the volume, when
applicable. The remainder of the path is the file name.

=cut

sub _m_parse_file
{ my ($slf, $ctx, $pth, @suf) = @_;

  my ($fil, $dir, @ext) = fileparse($pth, @suf);
  ($dir, $fil, @ext);
}

=head2 S<readLink($file[,$default])>

This macro returns the value of a symbolic link, if symbolic links are
implemented. When not applicable, it returns the default value.

=cut

sub _m_read_link
{ my ($slf, $ctx, $fil, $dft) = @_;

  if (defined($fil) && -l $fil)
  { $fil = eval {readlink($fil)};
    return $fil unless $@;
  }
  $dft;
}

=head2 S<sameDir($dir1,$dir2)> or S<sameFile($file1,$file2)>

This macro indicates whether two directory or file paths are identical. For VMS
and for Windows, it ignores case differences. No path cleanup is performed.

=cut

sub _m_same_file
{ my ($slf, $ctx, $fil1, $fil2) = @_;

  $fil1 && $fil2 && &{$slf->{'_sam'}}($fil1, $fil2);
}

sub _same_c
{ my ($fil1, $fil2) = @_;

  $fil1 eq $fil2;
}

sub _same_i
{ my ($fil1, $fil2) = @_;

  $fil1 eq $fil2 || lc($fil1) eq lc($fil2);
}

=head2 S<setTimeout($sec)>

This macro sets the timeout for executing operating system commands, specified
in seconds, only if the value is greater than zero. Otherwise, the timeout
mechanism is disabled. It is disabled also if the alarm function is not
implemented.

It returns the effective value.

=cut

sub _m_set_timeout
{ my ($slf, $ctx, $val) = @_;

  $slf->{'lim'} = _chk_alarm($val);
}

=head2 S<sortLastFile($type)>

This macro sorts the last file buffer according to the specified criteria. It
returns the number of records on successful completion. Otherwise, it returns
0. The following sort types are supported:

=over 12

=item B<    ps_time>

Sorts the C<ps> lines by decreasing CPU time.

=back

It ignores empty lines. Lines that do not contain the sort field are placed at
the top of the list.

=cut

sub _m_sort_last
{ my ($slf, $ctx, $typ) = @_;
  my ($fct, $key, $new, $off, $rec, @tbl);

  if (exists($slf->{'_buf'}) && $typ && exists($tb_srt{$typ}))
  { # Get the sort key function key
    $new = [];
    $rec = $tb_srt{$typ};
    $rec = $rec->{exists($rec->{$^O}) ? $^O : '?'};
    $fct = $rec->[0];
    $off = $rec->[1];

    # Create the sort key
    foreach my $lin (@{$slf->{'_buf'}})
    { if (defined($key = &$fct($lin, $off)))
      { push(@tbl, [$key, $lin]);
      }
      elsif ($lin !~ m/^\s*$/)
      { push(@$new, $lin);
      }
    }

    # Sort the records
    foreach my $rec (sort {$b->[0] <=> $a->[0]} @tbl)
    { push(@$new, $rec->[1]);
    }
    $slf->{'_buf'} = $new;

    # Return the number of records
    return scalar @$new;
  }

  0;
}

sub _sort_ps_hms
{ my ($lin, $off) = @_;

  $lin = substr($lin, $off);
  return undef unless $lin =~ m/\s(((\d+)-)?(\d+)\:)?(\d+)\:(\d+)\s/;
  my $tps = $5 * 60 + $6;
  $tps += $4 * 3600  if $4;
  $tps += $3 * 86400 if $3;
  $tps;
}

sub _sort_ps_hmsc
{ my ($lin, $off) = @_;

  # Possible formats:
  # 2-16:17:48
  #   04:00:14
  #       0:01.31
  $lin = substr($lin, $off);
  return undef
    unless $lin =~ m/\s(((\d+)-)?(\d+)\:)?(\d+)\:(\d+)(\.(\d+))?\s/;
  my $tps = $5 * 60 + $6;
  $tps += $4 * 3600  if $4;
  $tps += $3 * 86400 if $3;
  $tps += $8 / 100   if $8;
  $tps;
}

sub _sort_ps_ms
{ my ($lin) = @_;

  ($lin =~ m/\s(\d+)\:(\d+)\s/) ? ($1 * 60 + $2) : undef;
}

sub _sort_ps_msc
{ my ($lin) = @_;

  ($lin =~ m/\s(\d+)\:(\d+\.\d+)\s/) ? ($1 * 60 + $2) : undef;
}

=head2 S<splitDir($dir[,$base])>

This macro splits the directory in its components. When a base directory is
specified, only the relative part is treated.

=cut

sub _m_split_dir
{ my ($slf, $ctx, $dir, $bas) = @_;

  &{$slf->{'_spl'}}($dir, $bas) if $dir;
}

sub _split_u
{ my ($dir, $bas) = @_;

  $dir =~ s#/*$#/#;         #
  if ($bas)
  { $bas =~ s#/*$#/#;       #
    $dir =~ s#^\Q$bas\E##;
  }
  $dir =~ s#/$##;           #
  split(/\//, $dir);
}

sub _split_v
{ my ($dir, $bas) = @_;
  ($dir);
}

sub _split_w
{ my ($dir, $bas) = @_;

  $dir =~ s#\\*$#\\#;       #
  if ($bas)
  { $bas =~ s#\\*$#\\#;     #
    $dir =~ s#^\Q$bas\E##i;
  }
  $dir =~ s#\\$##;          #
  split(/\\/, $dir);
}

=head2 S<statCommand()>

This macro returns the exit code of the last command. It clears this
information when the last command information is changed.

=cut

sub _m_stat_cmd
{ shift->{'err'};
}

=head2 S<testCommand($command,...)>

This macro returns the first command from the list that executes successfully.
Otherwise, it returns an undefined value. Specified commands should complete
their execution quickly and produce less output.

=cut

sub _m_test_cmd
{ my $slf = shift;
  my $ctx = shift;
  my ($cmd, $sta);

  foreach my $arg (@_)
  { eval {
      local $SIG{'__WARN__'} = sub { };
      local $SIG{'PIPE'} = 'IGNORE';
      $cmd = _conv_cmd($slf, "$arg 2>&1");
      open(PIPE, "$cmd |") or die "Bad open\n";
      while (<PIPE>)
      { ; # Need a loop to prevent pipe errors on platforms like AIX
      }
      close(PIPE) or die "Bad close\n";;
    };
    return $arg unless $@ || $?;
  }
  undef;
}

=head2 S<testDir($opt,$dir) or testFile($opt,$file)>

This macro applies one or more tests on the specified file or directory.
Possible tests are as follows:

=over 9

=item B<    'b' > File is a block special file

=item B<    'c' > File is a character special file

=item B<    'd' > File is a directory

=item B<    'e' > File exists

=item B<    'f' > File is a plain file

=item B<    'g' > File has setgid bit set

=item B<    'k' > File has sticky bit set

=item B<    'l' > File is a symbolic link

=item B<    'o' > File is owned by effective uid

=item B<    'p' > File is a named pipe (FIFO)

=item B<    'r' > File is readable by effective uid/gid

=item B<    's' > File has nonzero size

=item B<    't' > File handle is opened to a tty

=item B<    'u' > File has setuid bit set

=item B<    'w' > File is writable by effective uid/gid

=item B<    'x' > File is executable by effective uid/gid

=item B<    'z' > File has zero size (is empty)

=item B<    'B' > File is a binary file (opposite of C<T>)

=item B<    'S' > File is a socket

=item B<    'T' > File is an ASCII text file (heuristic guess)

=back

It returns 1 if all specified tests are successful. Otherwise, it returns 0.

=cut

sub _m_test_file
{ my ($slf, $ctx, $opt, $fil) = @_;
  my ($flg, $skp);

  $opt = '' unless defined($opt);
  $skp = $slf->{'_skp'};
  return 0 unless $fil;
  $fil =~ s/\\+$/\\\\/;
  foreach my $tst (split(//, $opt))
  { next if index($skp, $tst) >= 0;
    $flg = index('bcdefgkloprstuwxzBST', $tst) >= 0 && eval "-$tst '$fil'";
    return 0 if !$flg || $@;
  }
  1;
}

=head2 S<umask([$mask])>

This macro sets the umask for the process to the specified value and returns
the previous value. To specify an octal representation, you can use a string
starting with a zero. If the argument is omitted, then it returns the current
umask.

=cut

sub _m_umask
{ my ($slf, $ctx, $msk) = @_;

  return umask unless defined($msk);
  $msk = oct($msk) if $msk =~ m/^0/;
  umask($msk);
}

=head2 S<writeCommand([$report,]$command[,$flag[,$incr]])>

This macro writes the result of the specified command in the report file. It
returns 1 for successful completion. Otherwise, it returns 0. It stores the
effective command exit code. This code is accessible through the C<statCommand>
macro. When the flag is set, the write is considered successful regardless of
the exit code.

It is possible to increase the execution limit by specifying an increasing
factor as an argument. A nonpositive value disables any timeout.

=cut

sub _m_write_cmd
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_write_cmd($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_write_cmd($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_write_cmd
{ my ($slf, $ctx, $rpt, $cmd, $flg, $inc) = @_;
  my ($ret, $sta);

  $slf->{'err'} = $ret = 0;
  ++$slf->{'_req'};

  if (exists($slf->{'_wrk'}))
  { my ($err, $old, $tmp);

    # Write the command output using a temporary file
    ($err, $sta, $tmp) = _get_output($slf, $ctx, $cmd, $inc);
    $ret = ($tmp && -s $tmp) ? $rpt->write_file($tmp, ['C', $cmd]) :
           $tmp              ? 1 :
                               0;
    $slf->{'err'} = $err;

    # Remove the temporary file
    $slf->{'_wrk'}->get_output->clean_work($WRK);

    # Indicate the successful completion
    return $flg ? 1 : $err ? 0 : $ret unless $sta;
    $ret = 0;
  }
  else
  { my ($lim, $ofh, $pid);

    local $SIG{'__WARN__'} = sub { };
    if ($cmd = _conv_cmd($slf, $cmd))
    { if ($pid = open(IN, "$cmd |"))
      { eval {
          $lim = $slf->_get_alarm($inc);
          local $SIG{'ALRM'} = sub { die "Alarm\n"; } if $lim;

          # Load the command result, taking care on end of lines
          alarm($lim) if $lim;
          while (<IN>)
          { s/[\r\n]+$//;
            s/^\000+$//;
            unless ($ofh)
            { $lim = alarm(0) + 1 if $lim;
              $ofh = $rpt->get_handle;
              $rpt->begin_block(1);
              alarm($lim) if $lim;
            }
            $rpt->write("$_\n") if $ofh;
          }
          alarm(0) if $lim;
          };
        RDA::Object::Rda->kill_child($pid) if ($sta = $@) && $pid;
        close(IN);
        $rpt->end_block(['C', $cmd]) if $ofh;

        # Indicate the successful completion
        unless ($sta)
        { $slf->{'err'} = $?;
          return $flg ? 1 : $slf->{'err'} ? 0 : 1;
        }
        _log_timeout($slf, $ctx, $cmd);
      }
      else
      { $slf->{'err'} = $?;
        $ret = 1 if $flg;
      }
    }
  }

  # Indicate the error
  $ret;
}

=head2 S<writeLastFile([$report,][$min[,$max]])>

This macro writes a line range from the last file/command buffer in the output
file. It assumes the first and last line as default for the range definition.
You can use negative line numbers to specify lines from the buffer end.

It returns 1 for a successful completion. Otherwise, it returns 0.

=cut

sub _m_write_last
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_write_last($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_write_last($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_write_last
{ my ($slf, $ctx, $rpt, $min, $max, $idx, @cat) = @_;
  my ($buf);

  if (exists($slf->{'_buf'}))
  { # Validate the range
    $buf = $slf->{'_buf'};
    $min = (!defined($min) || ($#$buf + $min) < -1) ? 0 :
           ($min < 0) ? $#$buf + $min + 1 :
           $min;
    $max = (!defined($max)) ? $#$buf :
           (($#$buf + $max) < -1) ? 0 :
           ($max < 0) ? $#$buf + $max + 1 :
           ($max > $#$buf) ? $#$buf :
           $max;

    # Write the file to the report file, taking care on end of lines
    $rpt->begin_block(1);
    foreach my $lin (@$buf[$min..$max])
    { $rpt->write("$lin\n");
    }
    $rpt->end_block($idx, @cat);

    # Indicate the successful completion
    return 1;
  }
  0;
}

# --- Internal routines -------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0)};
  $@ ? 0 : $lim;
}

# Get the alarm duration
sub _get_alarm
{ my ($slf, $val) = @_;

  return $slf->{'lim'} unless defined($val);
  return 0 unless $slf->{'lim'} > 0 && $val > 0;
  $val *= $slf->{'lim'};
  ($val > 1) ? int($val) : 1;
}

# Adapt the command for VMS
sub _conv_cmd
{ my ($slf, $cmd) = @_;

  return $cmd unless $cmd;
  if ($slf->{'_win'})
  { $cmd =~ s#/dev/null#NUL#g;
  }
  elsif (RDA::Object::Rda->is_unix || RDA::Object::Rda->is_cygwin)
  { $cmd = "exec $cmd";
  }
  elsif ($slf->{'_vms'} && $cmd =~ m/[\<\>]/ && $cmd !~ m/^PIPE /i)
  { $cmd = "PIPE $cmd";
    $cmd =~ s/2>&1/2>SYS\$OUTPUT/g;
    $cmd =~ s#/dev/null#NLA0:#g;
  }
  $cmd;
}

# Get the output of a command in a temporary file
sub _get_output
{ my ($slf, $ctx, $cmd, $inc) = @_;
  my ($arg, $err, $lim, $out, $pid, $ret, $sta, $tmp);
  local $SIG{'__WARN__'} = sub { };

  # Abort when the command is missing
  return (0) unless $cmd;

  # Execute the command
  $lim = $slf->_get_alarm($inc);
  $tmp = $slf->{'_wrk'}->get_output->get_work($WRK, 1);
  $out = RDA::Object::Rda->quote($tmp);
  $arg = $cmd;
  $arg =~ s#(\s+2>&1)?\s*$# >$out $1#;  #
  $arg = _conv_cmd($slf, $arg);
  eval {
    local $SIG{'ALRM'} = sub { die "Alarm\n" } if $lim;
    local $SIG{'PIPE'} = 'IGNORE';

    # Limit its execution to prevent RDA hangs
    alarm($lim) if $lim;

    # Execute the command
    close(OUT) if ($pid = open(OUT, "| $arg"));

    # Disable alarms
    alarm(0) if $lim;
  };
  $err = $?;
  return ($err) unless $pid;
  if ($sta = $@)
  { RDA::Object::Rda->kill_child($pid);
    $err = _log_timeout($slf, $ctx, $cmd);
  }

  # Return the file name
  ($err, $sta, $tmp);
}

# Log a timeout event
sub _log_timeout
{ my $slf = shift;
  my $ctx = shift;

  $slf->{'_agt'}->log_timeout($ctx, 'OS', @_);
  ++$slf->{'_out'};
  $slf->{'err'} = -1;
}

# Get the file statistics
sub _lstat
{ return lstat(shift);
}

sub _stat
{ return stat(shift);
}

# Get the last modification date of the file
sub _lmod
{ my ($fil, $dft) = @_;
  my @sta = lstat($fil);
  defined($sta[9]) ? $sta[9] : $dft;
}

sub _mod
{ my ($fil, $dft) = @_;
  my @sta = stat($fil);
  defined($sta[9]) ? $sta[9] : $dft;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
