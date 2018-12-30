# Report.pm: Class Used for Managing Reports

package RDA::Object::Report;

# $Id: Report.pm,v 2.47 2012/07/29 23:33:10 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Report.pm,v 2.47 2012/07/29 23:33:10 mschenke Exp $
#
# Change History
# 20120729  MSC  Restrict file permissions.

=head1 NAME

RDA::Object::Report - Class Used for Managing Reports

=head1 SYNOPSIS

require RDA::Object::Report;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Report> class are used to manage reports. It
is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use File::Copy;
  use IO::File;
  use IO::Handle;
  use RDA::Block qw($CONT $SPC_BLK $SPC_REF $SPC_VAL);
  use RDA::Diff;
  use RDA::Object;
  use RDA::Object::Buffer;
  use RDA::Object::Rda qw($APPEND $CREATE $EXE_PERMS $FIL_PERMS $TMP_PERMS);
  use RDA::Object::Sgml;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.47 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'addBlock'       => ['${CUR.REPORT}', 'add_block'],
    'addEntry'       => ['${CUR.REPORT}', 'add_entry'],
    'alignOwner'     => ['${CUR.REPORT}', 'align_owner'],
    'beginBlock'     => ['${CUR.REPORT}', 'begin_block'],
    'convertReport'  => ['${CUR.REPORT}', 'convert'],
    'dupBlock'       => ['${CUR.REPORT}', 'dup_block'],
    'endBlock'       => ['${CUR.REPORT}', 'end_block'],
    'getHtmlLink'    => ['${CUR.REPORT}', 'get_html'],
    'getRawLink'     => ['${CUR.REPORT}', 'get_raw'],
    'getWriteLength' => ['${CUR.REPORT}', 'get_length'],
    'getXmlLink'     => ['${CUR.REPORT}', 'get_xml'],
    'hasOutput'      => ['${CUR.REPORT}', 'has_output'],
    'isActive'       => ['${CUR.REPORT}', 'is_active'],
    'isCreated'      => ['${CUR.REPORT}', 'is_created'],
    'renderReport'   => ['${CUR.REPORT}', 'render'],
    'statDir'        => ['${CUR.REPORT}', 'stat_dir'],
    'statFile'       => ['${CUR.REPORT}', 'stat_file'],
    'tagBlock'       => ['${CUR.REPORT}', 'tag_block'],
    'writeCatalog'   => ['${CUR.REPORT}', 'write_catalog'],
    'writeComment'   => ['${CUR.REPORT}', 'write_comment'],
    'writeData'      => ['${CUR.REPORT}', 'write_data'],
    'writeDiff'      => ['${CUR.REPORT}', 'write_diff'],
    'writeExplorer'  => ['${CUR.REPORT}', 'write_explorer'],
    'writeExtract'   => ['${CUR.REPORT}', 'write_extract'],
    'writeFile'      => ['${CUR.REPORT}', 'write_file'],
    'writeFilter'    => ['${CUR.REPORT}', 'write_filter'],
    'writeLines'     => ['${CUR.REPORT}', 'write_lines'],
    'writeTail'      => ['${CUR.REPORT}', 'write_tail'],
    },
  cmd => {
    'end'      => [\&_exe_end,      \&_get_object, 0,   0],
    'close'    => [\&_exe_close,    \&_get_object, 0,   0],
    'prefix'   => [\&_exe_prefix,   \&_get_object, 'B', 0],
    'title'    => [\&_exe_title,    \&_get_list,   0,   0],
    'unprefix' => [\&_exe_unprefix, \&_get_object, 0,   0],
    'untitle'  => [\&_exe_untitle,  \&_get_value,  0,   0],
    'write'    => [\&_exe_write,    \&_get_list,   0,   0],
    },
  dep => [qw(RDA::Object::Output)],
  inc => [qw(RDA::Object)],
  met => {
    'add_block'      => {ret => 0},
    'add_entry'      => {ret => 0},
    'align_owner'    => {ret => 0},
    'begin_block'    => {ret => 0},
    'clone'          => {ret => 0},
    'convert'        => {ret => 0},
    'close'          => {ret => 0},
    'create'         => {ret => 0},
    'dup_block'      => {ret => 0},
    'end_block'      => {ret => 0},
    'get_block'      => {ret => 0},
    'get_file'       => {ret => 0},
    'get_html'       => {ret => 0},
    'get_info'       => {ret => 0},
    'get_length'     => {ret => 0},
    'get_path'       => {ret => 0},
    'get_raw'        => {ret => 0},
    'get_report'     => {ret => 0},
    'get_sub'        => {ret => 0},
    'get_xml'        => {ret => 0},
    'has_output'     => {ret => 0},
    'is_active'      => {ret => 0},
    'is_cloned'      => {ret => 0},
    'is_created'     => {ret => 0},
    'is_locked'      => {ret => 0},
    'pop_lines'      => {ret => 0},
    'push_lines'     => {ret => 0},
    'render'         => {ret => 0},
    'set_info'       => {ret => 0},
    'share'          => {ret => 0},
    'stat_dir'       => {ret => 0},
    'stat_file'      => {ret => 0},
    'tag_block'      => {ret => 0},
    'unlink'         => {ret => 0},
    'unprefix'       => {ret => 0},
    'update'         => {ret => 0},
    'write'          => {ret => 0, evl => 'L'},
    'write_catalog'  => {ret => 0},
    'write_comment'  => {ret => 0, evl => 'L'},
    'write_data'     => {ret => 0},
    'write_diff'     => {ret => 0},
    'write_explorer' => {ret => 0},
    'write_extract'  => {ret => 0},
    'write_file'     => {ret => 0},
    'write_filter'   => {ret => 0},
    'write_lines'    => {ret => 0},
    'write_tail'     => {ret => 0},
    },
  );

# Define the global private constants
my $REPORT = qr/^RDA::Object::(Pipe|Report)$/i;

# Define the global private variables
my @tb_bit = qw(
  --- --x -w- -wx r-- r-x rw- rwx
  --S --s -wS -ws r-S r-s rwS rws);
my @tb_idx = qw(T F P H);
my @tb_mon = qw(? Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %tb_add = (
  E => 'exp',
  );
my %tb_cat = (
  F => '',
  H => '(Head)',
  P => '(Partial)',
  T => '(Tail)',
  );
my %tb_dup = (
  E => \&_dup_explorer,
  );
my %tb_err = (
  B => 'RDA-01052: Cannot open or create the data file',
  C => 'RDA-01051: Cannot open or create the report file',
  D => 'RDA-01052: Cannot open or create the data file',
  E => 'RDA-01053: Cannot open or create the extern file',
  F => 'RDA-01051: Cannot open or create the report file',
  R => 'RDA-01054: Cannot open or create the reference file',
  S => 'RDA-01055: Cannot open or create the sample file',
  T => 'RDA-01056: Cannot open or create the temporary file',
  );
my %tb_idx = (
  H => '---+ Oracle Home Files',
  O => '---+ Other Files',
  );
my %tb_ini = (
  B => \&_init_bin,
  C => \&_init_report,
  D => \&_init_data,
  E => \&_init_extern,
  F => \&_init_file,
  R => \&_init_ref,
  S => \&_init_sample,
  T => \&_init_temp,
  );
my %tb_mon = (
  JAN => 1,
  FEB => 2,
  MAR => 3,
  APR => 4,
  MAY => 5,
  JUN => 6,
  JUL => 7,
  AUG => 8,
  SEP => 9,
  OCT => 10,
  NOV => 11,
  DEC => 12,
  );
my %tb_val = (
  E => \&_val_explorer,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Report-E<gt>new($out,$oid,$typ,$pre,$nam,$dyn,...)>

The report file object constructor. This method takes the report control object
reference, the object identifier, the report type, the report prefix, the
report name, and the dynamic name indicator as arguments.

It supports the following report types:

=over 9

=item B<    'B' > Binary data file

=item B<    'C' > Collection report file

=item B<    'D' > Data file

=item B<    'E' > Extern file

=item B<    'F' > Collection file

=item B<    'R' > Reference file

=item B<    'S' > Sample file

=item B<    'T' > Temporary file

=back

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'abr' > > Report abbreviation

=item S<    B<'add' > > Catalog requests

=item S<    B<'aft' > > List of lines to insert after an output

=item S<    B<'bef' > > List of lines to insert before an output

=item S<    B<'blk' > > Block definition

=item S<    B<'cat' > > Catalog entries

=item S<    B<'cln' > > Clone indicator

=item S<    B<'cod' > > Code to execute before next write operation

=item S<    B<'dir' > > Directory type

=item S<    B<'dyn' > > Dynamic name indicator

=item S<    B<'eof' > > Indicates whether all writes should be done at file end

=item S<    B<'ext' > > Report file name extension

=item S<    B<'fil' > > Report file name

=item S<    B<'flg' > > Report file creation flag

=item S<    B<'flt' > > Filter control object reference

=item S<    B<'fmt' > > File name format

=item S<    B<'gid' > > Expected group identifier

=item S<    B<'grp' > > Report group

=item S<    B<'idx' > > Index indicator

=item S<    B<'ini' > > File permissions at opening time

=item S<    B<'lck' > > Lock indicator

=item S<    B<'lgt' > > File length

=item S<    B<'lst' > > List of associated files

=item S<    B<'mod' > > Required file permissions at closing time

=item S<    B<'nam' > > Report name

=item S<    B<'ofh' > > Report file handle

=item S<    B<'oid' > > Object identifier

=item S<    B<'out' > > Reference of the report control object

=item S<    B<'pid' > > Subprocess identifier

=item S<    B<'pre' > > Report prefix

=item S<    B<'pth' > > File path

=item S<    B<'rnd' > > Direct rendering handle

=item S<    B<'spc' > > Disk space used

=item S<    B<'sig' > > Signature elements

=item S<    B<'siz' > > Block size

=item S<    B<'sub' > > Report subdirectory

=item S<    B<'tag' > > Block tag

=item S<    B<'typ' > > Report file type

=item S<    B<'uid' > > Expected user identifier

=item S<    B<'vrb' > > Verbatim block indicator

=back

=cut

sub new
{ my ($cls, $out, $oid, $typ, $pre, $nam, $dyn, @arg) = @_;

  die "RDA-01050: Invalid report file type '$typ'\n"
    unless exists($tb_ini{$typ = uc($typ)});

  # Create the report file object
  my $slf = bless {
    abr => $out->get_info('abr'),
    add => {},
    blk => '',
    cat => {},
    dir => 'C',
    dyn => $dyn,
    eof => 0,
    fmt => 0,
    grp => $out->get_info('grp'),
    ini => $FIL_PERMS,
    lck => 0,
    lst => [],
    nam => $nam,
    oid => $oid,
    out => $out,
    pre => $pre,
    siz => 0,
    spc => 0,
    tag => [],
    typ => $typ,
    }, ref($cls) || $cls;

  # Specific type initialization
  &{$tb_ini{$typ}}($slf, @arg);

  # Propagate ownership alignment
  $slf->align_owner if $typ ne 'T' && $out->get_info('own');

  # Take care about file name capitalisation
  $slf->{'fil'} = lc($slf->{'fil'}) unless $out->get_info('cas');

  # Return the object reference
  $slf;
}

sub _init_bin
{ my ($slf, $lgt, $ext) = @_;
  my ($out);

  $out = $slf->{'out'};
  if ($out->get_info('mrc'))
  { $slf->{'dir'} = 'M';
    $slf->{'sub'} = 'mrc';
  }
  $slf->{'ext'} = defined($ext) ? $ext : '.dat';
  if ($out->get_info('flt'))
  { $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
}

sub _init_data
{ my ($slf, $lgt, $ext) = @_;
  my ($out, $flt);

  $out = $slf->{'out'};
  if ($out->get_info('mrc'))
  { $slf->{'dir'} = 'M';
    $slf->{'sub'} = 'mrc';
  }
  $slf->{'ext'} = defined($ext) ? $ext : '.dat';
  if ($flt = $out->get_info('flt'))
  { $slf->{'flt'} = $flt;
    $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
}

sub _init_extern
{ my ($slf, $lgt, $ext) = @_;
  my ($flt);

  $slf->{'dir'} = 'E';
  $slf->{'ext'} = defined($ext) ? $ext : '.txt';
  $slf->{'flt'} = $flt if ($flt = $slf->{'out'}->get_info('flt'));
  if ($flt && $slf->{'dyn'})
  { $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  elsif (length($slf->{'nam'}) - 7 < $lgt)
  { $slf->{'fil'} = $slf->{'grp'}.'_'.$slf->{'abr'}.'_'.$slf->{'pre'}
      .$slf->{'nam'}.$slf->{'ext'};
    $slf->{'fmt'} = 1;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
  $slf->{'sub'} = 'extern';
}

sub _init_file
{ my ($slf, $lgt, $ext) = @_;
  my ($out, $flt);

  $out = $slf->{'out'};
  $slf->{'sig'} = {
    rel => $out->get_info('rel'),
    mod => $out->get_oid,
    ver => $out->get_info('ver')};
  if ($out->get_info('mrc'))
  { $slf->{'dir'} = 'M';
    $slf->{'sub'} = 'mrc';
  }
  $slf->{'ext'} = '.txt';
  if ($flt = $out->get_info('flt'))
  { $slf->{'flt'} = $flt;
    $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
  _gen_signature($slf);
}

sub _init_ref
{ my ($slf, $lgt, $ext) = @_;
  my ($flt);

  $slf->{'dir'} = 'R';
  $slf->{'ext'} = defined($ext) ? $ext : '.txt';
  $slf->{'flt'} = $flt if ($flt = $slf->{'out'}->get_info('flt'));
  if ($flt && $slf->{'dyn'})
  { $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  elsif (length($slf->{'nam'}) - 7 < $lgt)
  { $slf->{'fil'} = $slf->{'grp'}.'_'.$slf->{'abr'}.'_'.$slf->{'pre'}
      .$slf->{'nam'}.$slf->{'ext'};
    $slf->{'fmt'} = 1;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
  $slf->{'sub'} = 'ref';
}

sub _init_report
{ my ($slf, $lgt, $ext) = @_;
  my ($flt, $out, $rnd);

  $out = $slf->{'out'};
  $slf->{'sig'} = {
    rel => $out->get_info('rel'),
    mod => $out->get_oid,
    ver => $out->get_info('ver')};
  if ($out->get_info('mrc'))
  { $slf->{'dir'} = 'M';
    $slf->{'sub'} = 'mrc';
  }
  $slf->{'ext'} = '.txt';
  if ($flt = $out->get_info('flt'))
  { $slf->{'flt'} = $flt;
  }
  elsif ($rnd = $out->get_info('rnd'))
  { $slf->{'rnd'} = $rnd
      if ($rnd = $rnd->get_handle($slf->{'abr'}, $slf->{'nam'}));
  }
  if ($flt && $slf->{'dyn'})
  { $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  elsif (length($slf->{'nam'}) - 7 < $lgt)
  { $slf->{'fil'} = $slf->{'grp'}.'_'.$slf->{'abr'}.'_'.$slf->{'pre'}
      .$slf->{'nam'}.$slf->{'ext'};
    $slf->{'fmt'} = 1;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
  _gen_signature($slf);
}

sub _init_sample
{ my ($slf, $lgt, $ext) = @_;
  my ($flt);

  $slf->{'dir'} = 'S';
  $slf->{'ext'} = defined($ext) ? $ext : '.txt';
  $slf->{'flt'} = $flt if ($flt = $slf->{'out'}->get_info('flt'));
  if ($flt && $slf->{'dyn'})
  { $slf->{'fil'} = $slf->{'oid'}.$slf->{'ext'};
    $slf->{'fmt'} = 0;
  }
  elsif (length($slf->{'nam'}) - 7 < $lgt)
  { $slf->{'fil'} = $slf->{'grp'}.'_'.$slf->{'abr'}.'_'.$slf->{'pre'}
      .$slf->{'nam'}.$slf->{'ext'};
    $slf->{'fmt'} = 1;
  }
  else
  { $slf->{'fil'} =
      $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
    $slf->{'fmt'} = -1;
  }
  $slf->{'idx'} = $slf->{'fmt'};
  $slf->{'sub'} = 'sample';
}

sub _init_temp
{ my ($slf, $lgt, $ext, $flg) = @_;

  $slf->{'dir'} = 'T';
  $slf->{'ext'} = defined($ext) ? $ext : '.tmp';
  $slf->{'fil'} =
    $slf->{'oid'}.substr('_'.$slf->{'nam'}, 0, $lgt).$slf->{'ext'};
  $slf->{'idx'} = 0;
  $slf->{'pth'} = RDA::Object::Rda->cat_file(
    $slf->{'out'}->get_path($slf->{'dir'}), $slf->{'fil'});
  if (defined($flg))
  { $slf->{'ini'} = $TMP_PERMS;
    $slf->{'mod'} = $EXE_PERMS if $flg;
  }
}

sub _gen_signature
{ my ($slf) = @_;

  $slf->{'bef'} = [
    '<!-- Oracle Remote Diagnostic Agent / Data Collection Results '.
      $slf->{'sig'}->{'rel'}.' -->',
    sprintf('<!-- Module:%s Version:%.2f Report:%s OS:%s -->',
      $slf->{'sig'}->{'mod'}, $slf->{'sig'}->{'ver'}, $slf->{'nam'}, $^O)
    ]
    if exists($slf->{'sig'});
}

=head2 S<$h-E<gt>align_owner>

This method indicates that the user and group identifiers of the report must
be aligned to those of the report directory on the report closure. That
alignment also applies to the rendered and converted files. It returns the
number of files already converted.

=cut

sub align_owner
{ my ($slf) = @_;
  my ($uid, $gid, @fil);

  ($uid, $gid) = $slf->{'out'}->get_owner;
  if (defined($uid))
  { # Store the user and group identifiers of the report directory
    $slf->{'uid'} = $uid;
    $slf->{'gid'} = $gid;

    # Adjust existing files
    if (exists($slf->{'flg'}))
    { @fil = @{$slf->{'lst'}};
      unshift(@fil, $slf->{'pth'}) unless exists($slf->{'ofh'});
      return chown($uid, $gid, @fil) if @fil;
    }
  }
  0;
}

=head2 S<$h-E<gt>clone>

This method clones a locked report for using it in the current context. It
discards any prefix and lines to insert before and after the output.

=cut

sub clone
{ my ($slf) = @_;
  my ($cln, $oid, $tbl, $tmp);

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Abort when the report is not locked
  $oid = $slf->{'oid'};
  $tmp = $slf->{'typ'} eq 'T';
  $tbl = $slf->{'out'}->get_info($tmp ? 'tmp' : 'rpt');
  die "RDA-01061: Cannot clone an active report\n"
    unless $slf->{'lck'} && !exists($tbl->{$oid});
  die "RDA-01062: Cannot clone a report before its creation\n"
    unless exists($slf->{'flg'});

  # Clone the object
  $cln = bless {%$slf}, ref($slf);
  $cln->{'cln'} = 1 unless $tmp;
  $cln->{'lck'} = 0;
  delete($cln->{'aft'});
  delete($cln->{'bef'});
  delete($cln->{'cod'});
  $tbl->{$oid} = $cln;

  # Return the clone object reference
  $cln;
}

=head2 S<$h-E<gt>close([$flag])>

This method closes the report file. Unless the flag is set, it deletes any
prefix treatment.

When previously requested, it aligns the user and group identifiers of the
report file to those of the report directory. For temporary files, the file
permissions could be adapted.

=cut

sub close
{ my ($slf, $flg) = @_;

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Delete any prefix treatment
  delete($slf->{'cod'}) unless $flg;

  # Close the file
  delete($slf->{'ofh'})->close if exists($slf->{'ofh'});

  # Adjust the permissions and ownership
  if (exists($slf->{'flg'}))
  { chmod($slf->{'mod'}, $slf->{'pth'})
      if exists($slf->{'mod'});
    chown($slf->{'uid'}, $slf->{'gid'}, $slf->{'pth'})
      if exists($slf->{'uid'});
  }

  # Update the disk space used
  update($slf, -1) unless $slf->{'typ'} eq 'T';
}

=head2 S<$h-E<gt>convert>

This method ends the report and converts it in XML. When previously requested,
it aligns the user and group identifiers of the generated file to those of the
report directory. It returns the path of the generated file on successful
completion. Otherwise, it returns an undefined value.

=cut

sub convert
{ my ($slf) = @_;
  my ($agt, $pth);

  # End the report when still active
  $slf->{'out'}->end_report($slf) if exists($slf->{'lck'});

  # Convert the report
  return undef unless exists($slf->{'flg'});
  $agt = $slf->{'out'}->get_info('agt');
  $pth = $agt->get_convert->convert($slf->{'pth'});
  push(@{$slf->{'lst'}}, $pth);
  chown($slf->{'uid'}, $slf->{'gid'}, $pth) if exists($slf->{'uid'});
  $pth;
}

=head2 S<$h-E<gt>create>

This method forces the creation of a report. It writes the lines to insert
before any output.

=cut

sub create
{ my ($slf) = @_;

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Create the file when not yet done
  unless (exists($slf->{'flg'}))
  { # Create or open the file
    $slf->get_handle(1);

    # Put the start lines
    $slf->write(join("\n", @{delete($slf->{'bef'})}, ''))
      if exists($slf->{'bef'});

    # Indicate the file creation
    $slf->{'flg'} = 0;
  }
  1;
}

=head2 S<$h-E<gt>get_directory>

This method returns the path of the report directory.

=cut

sub get_directory
{ my ($slf, $flg) = @_;

  $slf->{'out'}->get_path($slf->{'dir'});
}

=head2 S<$h-E<gt>get_file([$flag])>

This method returns the name of the report file. When the flag is set, it
returns the path to the report file.

=cut

sub get_file
{ my ($slf, $flg) = @_;

  $flg                  ? RDA::Object::Rda->cat_file($slf->get_directory,
                                                     $slf->{'fil'}) :
  exists($slf->{'sub'}) ? RDA::Object::Rda->cat_file($slf->{'sub'},
                                                     $slf->{'fil'}) :
                          $slf->{'fil'};
}

=head2 S<$h-E<gt>get_handle([$flag])>

This method returns the file handle of the report file. It creates the file
on the first call. Unless the flag is set, it executes prefix blocks when
present.

=cut

sub get_handle
{ my ($slf, $flg) = @_;
  my ($buf, $ofh, $pth, $val);

  # Abort when the object is ended or locked
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});
  die "RDA-01063: Locked report\n" if $slf->{'lck'};

  # Get the report file handler
  if (exists($slf->{'ofh'}))
  { $ofh = $slf->{'ofh'};
  }
  else
  { # Wait for asynchronous command completion
    $slf->wait(1);

    # Create or open the file
    $pth = $slf->get_path;
    $ofh = exists($slf->{'flt'}) ? $slf->{'flt'}->new :
           exists($slf->{'rnd'}) ? $slf->{'rnd'}->new :
           IO::File->new;
    $ofh->open($pth,
      (exists($slf->{'flg'}) || $slf->{'eof'}) ? $APPEND : $CREATE,
      $slf->{'ini'})
      or die sprintf("%s '%s' (%s)\n",
                     $tb_err{$slf->{'typ'}}, $slf->{'fil'}, $!);
    $slf->{'ofh'} = $ofh;
  }

  # Put the suffix lines
  if ($val = delete($slf->{'aft'}))
  { $val = [$val] unless ref($val) eq 'ARRAY';
    _write($ofh, $slf, join('', grep {defined($_) && !ref($_)} @$val)."\n");
  }

  # Perform all pre-treatments
  unless ($flg)
  { # Put the start lines
    _write($ofh, $slf, join("\n", @{delete($slf->{'bef'})}, ''))
      if exists($slf->{'bef'});

    # When required, execute the prefix code block
    die "RDA-01060: Prefix error\n" if exists($slf->{'cod'})
      && delete($slf->{'cod'})->exec_block('prefix ['.$slf->{'fil'}.']');

    # Report the file as created only after prefix block execution
    $slf->{'flg'} = 1;
  }

  # Return the file handle
  $ofh;
}

=head2 S<$h-E<gt>get_html([$flag])>

This method returns the link to the rendered file. Unless the flag is set, it
generates a link from the index. It returns an undefined value for a temporary
file.

=cut

sub get_html
{ my ($slf, $flg) = @_;
  my ($fil);

  unless ($slf->{'typ'} eq 'T')
  { $fil = _get_report($slf);
    $fil = "../$fil" if $flg && exists($slf->{'sub'});
    $fil =~ s/\.(dat|txt)/.htm/i;
  }
  $fil;
}

=head2 S<$h-E<gt>get_path([$flag])>

This method returns the report path. The directories are created when
required. When the flag is set, it adapts the creation mode.

=cut

sub get_path
{ my ($slf, $flg) = @_;
  my ($err, $mod, $pth);

  if (exists($slf->{'flg'}))
  { $mod = $flg ? '>' : '';
    $pth = $slf->{'pth'};
  }
  elsif (exists($slf->{'lck'}))
  { # Create the report directory when needed
    $pth = $slf->{'out'}->get_path($slf->{'dir'}, 1);

    # Adapt the opening mode
    $mod = '';
    $slf->{'flg'} = 1 if $flg;
    $slf->{'pth'} = $pth = RDA::Object::Rda->cat_file($pth, $slf->{'fil'});
  }
  else
  { # Abort when the report is already ended
    die "RDA-01064: Report already ended\n";
  }
  $mod.$pth;
}

=head2 S<$h-E<gt>get_report>

This method returns the report name. It returns an undefined value for a
temporary file.

=cut

sub get_report
{ my ($slf) = @_;
  my ($fil);

  unless ($slf->{'typ'} eq 'T')
  { $fil = _get_report($slf);
    $fil =~ s/\.(dat|txt)/.htm/i;
  }
  $fil;
}

sub _get_report
{ my ($slf) = @_;

  exists($slf->{'sub'})
    ? join('/', $slf->{'sub'}, $slf->{'fil'})
    : $slf->{'fil'};
}

=head2 S<$h-E<gt>get_raw([$flag])>

This method returns the link to the raw file. Unless the flag is set, it
generates a link from the index. It returns an undefined value for a temporary
file.

=cut

sub get_raw
{ my ($slf, $flg) = @_;
  my ($fil);

  unless ($slf->{'typ'} eq 'T')
  { $fil = _get_report($slf);
    $fil = "../$fil" if $flg && exists($slf->{'sub'});
  }
  $fil;
}

=head2 S<$h-E<gt>get_sub>

This method returns the name of the report file subdirectory when
applicable. Otherwise, it returns an undefined value.

=cut

sub get_sub
{ my ($slf) = @_;

  exists($slf->{'sub'}) ? $slf->{'sub'} : undef;
}

=head2 S<$h-E<gt>get_xml([$flag])>

This method returns the link to the XML conversion. Unless the flag is set, it
generates a link from the index. It returns an undefined value for a temporary
file.

=cut

sub get_xml
{ my ($slf, $flg) = @_;
  my ($fil);

  unless ($slf->{'typ'} eq 'T')
  { $fil = _get_report($slf);
    $fil = "../$fil" if $flg && exists($slf->{'sub'});
    $fil =~ s/\.(dat|txt)/.xml/i;
  }
  $fil;
}

=head2 S<$h-E<gt>has_output([$flag])>

This method indicates whether lines have been written in the report file since
the last prefix command. When the flag is set, it clears any prefix also.

It becomes false after file closure.

=cut

sub has_output
{ my ($slf, $flg) = @_;

  if (exists($slf->{'cod'}))
  { delete($slf->{'cod'}) if $flg;
    return 0;
  }
  exists($slf->{'ofh'}) ? 1 : 0;
}

=head2 S<$h-E<gt>is_active>

This method indicates whether the object is not yet ended.

=cut

sub is_active
{ exists(shift->{'lck'}) ? 1 : 0;
}

=head2 S<$h-E<gt>is_cloned>

This method indicates whether the object is cloned.

=cut

sub is_cloned
{ shift->{'cln'} ? 1 : 0;
}

=head2 S<$h-E<gt>is_created([$flag])>

This method indicates whether the report file has been created. It reports
whether the file has not yet been created in the prefix block that is executed
for the first line written to the report file.

When the flag is set, it clears any prefix also.

=cut

sub is_created
{ my ($slf, $flg) = @_;

  delete($slf->{'cod'}) if $flg;
  exists($slf->{'flg'}) ? 1 : 0;
}

=head2 S<$h-E<gt>is_locked>

This method indicates whether the object is locked.

=cut

sub is_locked
{ my ($slf) = @_;

  exists($slf->{'flg'}) ? $slf->{'lck'} : 0;
}

=head2 S<$h-E<gt>pop_lines($key[,$count])>

This method removes recent lines from the list of lines to insert before or
after an output. It returns the last string removed from the stack.

=cut

sub pop_lines
{ my ($slf, $key, $cnt) = @_;
  my ($lin);

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Pop lines
  if (($key eq 'aft' || $key eq 'bef') && exists($slf->{$key}))
  { $cnt = 1 unless defined($cnt);
    $lin = pop(@{$slf->{$key}}) while $cnt-- > 0;
    delete($slf->{$key}) unless scalar @{$slf->{$key}};
  }
  $lin;
}

=head2 S<$h-E<gt>push_lines($key,$line...)>

This method adds lines in the list of lines to insert before or after an
output. You can specify the extra lines as array references.

=cut

sub push_lines
{ my ($slf, $key, @arg) = @_;

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Push specified lines
  if ($key eq 'aft' || $key eq 'bef')
  { foreach my $arg (@arg)
    { $arg = [$arg] unless ref($arg) eq 'ARRAY';
      foreach my $lin (@$arg)
      { push(@{$slf->{$key}}, $lin) if defined($lin) && !ref($lin);
      }
    }
  }
}

=head2 S<$h-E<gt>render([$title])>

This method ends the report and renders it. When previously requested, it
aligns the user and group identifiers of the generated file to those of the
report directory. It returns the path of the generated file on successful
completion. Otherwise, it returns an undefined value.

=cut

sub render
{ my ($slf, $ttl) = @_;
  my ($pth, $rnd);

  # End the report when still active
  $slf->{'out'}->end_report($slf) if exists($slf->{'lck'});

  # Generate the report
  return undef unless exists($slf->{'flg'});
  $pth = $slf->get_file;
  if ($pth =~ m/\.(dat|txt)$/i)
  { $rnd = $slf->{'out'}->get_info('agt')->get_render;
    $rnd->align_owner if exists($slf->{'uid'});
    $pth = $rnd->gen_html($pth, $ttl, $slf->{'sub'});
    push(@{$slf->{'lst'}}, $pth);
  }
  $pth;
}

=head2 S<$h-E<gt>unlink>

This method unlinks the associated file. It returns the number of versions
removed.

=cut

sub unlink
{ my ($slf) = @_;
  my ($cnt);

  # Close the file
  $slf->close;

  # Delete the stored lines
  delete($slf->{'aft'});
  delete($slf->{'bef'});
  _gen_signature($slf);

  # Delete all catalog entries
  $slf->{'cat'} = {};

  # Unlink the file
  $cnt = 0;
  if (exists($slf->{'pth'}))
  { delete($slf->{'flg'});
    ++$cnt while unlink($slf->{'pth'});
    foreach my $pth (@{$slf->{'lst'}})
    { ++$cnt while unlink($pth);
    }
  }
  $cnt;
}

=head2 S<$h-E<gt>write($str[,$size])>

This method writes a string in the report file. It returns the number of bytes
actually written, or an undefined value if there was an error.

=cut

sub write
{ my ($slf) = @_;

  _write($slf->get_handle, @_);
}

*syswrite = \&write;

sub _write
{ my ($ofh, $slf, $buf, $lgt) = @_;
  my ($inc, $ret);
  local $SIG{'PIPE'} = 'IGNORE';

  $lgt = length($buf) unless defined($lgt);
  $slf->{'out'}->decr_free($lgt);
  exists($slf->{'flt'}) ? $ofh->sysseek(0, 2) : sysseek($ofh, 0, 2)
    if $slf->{'eof'};
  if (defined($ret = $ofh->syswrite($buf, $lgt)))
  { $slf->{'siz'} += $ret;
    $slf->{'out'}->decr_free($inc) if ($inc = $ret - $lgt);
  }
  $ret;
}

=head1 INTERNAL METHODS

=head2 S<$h-E<gt>delete>

This method deletes a report. The report file is ended when required.

=cut

sub delete
{ # End the report when not yet done
  $_[0]->end if exists($_[0]->{'lck'});

  # Delete the object
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>end>

This method terminates the report. It returns the object reference.

=cut

sub end
{ my ($slf) = @_;

  # End the report
  if (exists($slf->{'lck'}))
  { if ($slf->{'typ'} eq 'T')
    { $slf->unlink;
    }
    else
    { $slf->close;
    }
    delete($slf->{'lck'});
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>lock>

This method locks the object. It ignores the request on ended objects.

=cut

sub lock
{ my ($slf, $flg) = @_;

  if (exists($slf->{'lck'}))
  { # Close the file
    delete($slf->{'ofh'})->close if exists($slf->{'ofh'});

    # Indicate that the object is locked
    $slf->{'lck'} = 1;
  }
}

=head2 S<$h-E<gt>unlock>

This method unlocks the object.

=cut

sub unlock
{ my ($slf) = @_;

  $slf->{'lck'} = 0 if exists($slf->{'lck'});
}

=head2 S<$h-E<gt>update>

This method updates the disk space consumed by the report when the report is
open. It discards contributions from clone reports.

=cut

sub update
{ my ($slf, $flg) = @_;
  my ($inc, $siz);

  if (($flg || exists($slf->{'ofh'}))
    && exists($slf->{'flg'})
    && exists($slf->{'lck'})
    && exists($slf->{'out'})
    && !exists($slf->{'cln'})
    && defined($siz = (stat($slf->{'pth'}))[7]))
  { $slf->{'out'}->update_space($inc = $siz - $slf->{'spc'});
    $slf->{'siz'} += $inc if $flg > 0;
    $slf->{'spc'} = $siz;
  }
}

=head2 S<$h-E<gt>wait([$flag])>

This method waits for the completion of the associated background process (cf.
asynchronous operating system command execution). Unless the flag is set, lines
to put after are written to the report and the report is closed.

It returns the report reference.

=cut

sub wait
{ my ($slf, $flg) = @_;
  my ($pid);

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Wait for the subprocess completion
  if ($pid = delete($slf->{'pid'}))
  { eval {sleep(1) while kill(0, $pid)};
  }

  # When appropriate, execute post treatments
  unless ($flg)
  { # Add the suffix lines
    $slf->get_handle(1) if exists($slf->{'aft'});

    # Close the report file
    $slf->close;
  }

  # Return the report reference
  $slf;
}

=head1 BLOCK MANAGEMENT METHODS

=head2 S<$h-E<gt>add_block($catalog,$detail...)>

This method adds the current (or next) block in the specified catalog at report
closure.

It supports the following catalog:

=over 9

=item B<    'E' > Explorer

=back

=cut

sub add_block
{ my ($slf, $cat, @det) = @_;

  die "RDA-01065: Missing catalog\n"        unless defined($cat);
  die "RDA-01066: Invalid catalog '$cat'\n" unless exists($tb_add{$cat});
  $slf->{'add'}->{$tb_add{$cat}} = &{$tb_val{$cat}}(@det);
}

sub _val_explorer
{ my ($typ, $nam, $alt) = @_;

  die "RDA-01067: Missing or invalid Explorer type\n"
    unless $typ && index('BDEGLOT', $typ) >= 0;
  die "RDA-01068: Missing or invalid Explorer name\n"
    if _val_report(\$nam);
  if ($typ eq 'L')
  { die "RDA-01068: Missing or invalid Explorer name\n"
      if _val_report(\$alt);
    return [$typ, '', '', "$nam|$alt" ];
  }
  ($typ eq 'G')
    ? [$typ, '', '', $nam]
    : [$typ, '<R>', '<B>', $nam];
}

sub _val_report
{ my ($nam) = @_;

  return 1 unless defined($$nam);
  return 2 if ref($$nam);
  $$nam =~ s#[\\\/]+#/#g;
  $$nam =~ s#^(\.*/)+##g;
  $$nam =~ s#/(\./)+#/#g;
  for (split(/\//, $$nam, -1))
  { return 3 unless m/^[\+\-\=\@\.\,\:\w]+$/;
    return 4 if m/^\.*$/;
  }
  0;
}

=head2 S<$h-E<gt>add_entry($catalog,$record)>

This method adds an entry in the specified catalog at report closure.

It supports the following catalog:

=over 9

=item B<    'E' > Explorer

=back

=cut

sub add_entry
{ my ($slf, $cat, @det) = @_;

  die "RDA-01065: Missing catalog\n"        unless defined($cat);
  die "RDA-01066: Invalid catalog '$cat'\n" unless exists($tb_add{$cat});
  _add_entry($slf, $tb_add{$cat}, join('|', @{&{$tb_val{$cat}}(@det)}, "\n"));
}

sub _add_entry
{ my ($slf, $cat, $rec) = @_;

  push(@{$slf->{'cat'}->{$cat}}, $rec);
}

=head2 S<$h-E<gt>begin_block($flg[,$tag])>

This method indicates the begin of a block. When the flag is set, it opens a
C<verbatim> section in the report.

=cut

sub begin_block
{ my ($slf, $flg, $tag) = @_;

  # When applicable, open a verbatim section in the report
  if ($flg)
  { $slf->write($tag ? "<verbatim:$tag>\n" : "<verbatim>\n");
    $slf->{'vrb'} = $flg;
  }
  elsif (!exists($slf->{'ofh'}))
  { $slf->get_handle;
  }

  # Initialize the block
  $slf->{'siz'} = 0;
}

=head2 S<$h-E<gt>dup_block($catalog,$detail...)>

This method generates a new entry from the last entry of the specified catalog.

It supports the following catalog:

=over 9

=item B<    'E' > Explorer

=back

=cut

sub dup_block
{ my ($slf, $cat, @det) = @_;
  my ($new);

  die "RDA-01065: Missing catalog\n"        unless defined($cat);
  die "RDA-01066: Invalid catalog '$cat'\n" unless exists($tb_dup{$cat});
  &{$tb_dup{$cat}}($slf, @det);
}

sub _dup_explorer
{ my ($slf, $typ, $nam) = @_;
  my ($rec, @rec);

  _val_explorer($typ, $nam);
  return 0 unless ($rec = $slf->{'cat'}->{'exp'}->[-1]);
  @rec = split('\|', $rec);
  $rec[0] = $typ;
  $rec[3] = $nam;
  _add_entry($slf, 'exp', join('|', @rec));
}

=head2 S<$h-E<gt>end_block([$idx])>

This method indicates the end of a block. You can specify the index
contribution as an argument.

=cut

sub end_block
{ my ($slf, $idx, @cat) = @_;
  my ($off, $siz, $tbl, $url);

  # Determine the block characteristics
  $slf->{'blk'} =
    (!($siz = $slf->{'siz'})) ?
      join('/', 0, 0, $slf->{'dir'}, $slf->{'fil'}, @{$slf->{'tag'}}) :
    defined($off = exists($slf->{'flt'}) ? $slf->get_handle->sysseek(0, 1)
                                         : sysseek($slf->get_handle, 0, 1)) ?
      join('/', $off - $siz, $siz, $slf->{'dir'}, $slf->{'fil'},
           @{$slf->{'tag'}}) :
      '';

  # Add the catalog entries
  if (defined($url = $slf->get_report))
  { # Add requested entries
    foreach my $cat (@cat)
    { $slf->add_block(@$cat) if ref($cat) eq 'ARRAY';
    }
    foreach my $key (keys(%{$tbl = $slf->{'add'}}))
    { _add_entry($slf, $key,
        join('|', (map {($_ eq '<B>') ? $slf->{'blk'} :
                        ($_ eq '<F>') ? $slf->get_file :
                        ($_ eq '<R>') ? $url :
                                        $_} @{delete($tbl->{$key})}), "\n"));
    }

    # Create the index entry
    _add_index($slf, $url, $idx) if ref($idx) eq 'ARRAY';
  }

  # When applicable, close the verbatim section in the report
  $slf->write("</verbatim>\n") if delete($slf->{'vrb'});
}

sub _add_index
{ my ($slf, $url, $idx) = @_;
  my ($fmt, $pth, $rec, $typ, @arg);

  # Validate the arguments
  ($rec, $pth, $typ, $fmt) = @$idx;
  return 0 unless $rec && $rec =~ m/^[BCEF]$/ && $pth && $slf->{'idx'};
  if ($rec eq 'F')
  { return 0 unless -f $pth;
    $pth = $slf->{'out'}->get_info('cfg')->get_file('D_RDA', $pth)
      unless RDA::Object::Rda->is_absolute($pth);
    $pth = $slf->{'flt'}->filter($pth) if exists($slf->{'flt'});
    $slf->{'out'}->add_file($pth);
    push(@arg, (defined($typ) && $typ =~ m/^[FHPT]$/) ? $typ : 'F');
    push(@arg, (defined($fmt) && $fmt =~ m/^[DT]$/)   ? $fmt : 'T');
  }
  elsif ($rec eq 'C' || $rec eq 'E')
  { $pth = $slf->{'flt'}->filter($pth) if exists($slf->{'flt'});
  }

  # Add the index entry
  _add_entry($slf, 'idx',
    join('|', $rec, $url, $slf->get_block, $pth, @arg, "\n"));
}

=head2 S<$h-E<gt>get_block>

This method returns the report block definition. It clears the current
definition.

=cut

sub get_block
{ my ($slf) = @_;
  my ($blk);

  ($blk, $slf->{'blk'}, $slf->{'tag'}) = ($slf->{'blk'}, '', []);
  $blk;
}

=head2 S<$h-E<gt>tag_block(@tag)>

This method associates a tag to a report block. A tag can contain a list of
components. It replaces all group of nonalphanumeric characters in tag
components with an underscore.

=cut

sub tag_block
{ my ($slf, @tag) = @_;

  $slf->{'tag'} = [map {_fmt_tag($_)} @tag];
}

sub _fmt_tag
{ my ($str) = @_;

  $str =~ s/[\_\W]+/_/g;
  $str;
}

=head1 PREFIX MANAGEMENT METHODS

=head2 S<$h-E<gt>deprefix($blk)>

This method suppresses the execution of a code block contained in the specified
block.

=cut

sub deprefix
{ my ($slf, $blk) = @_;

  delete($slf->{'cod'}) if exists($slf->{'lck'})
    && exists($slf->{'cod'}) && $slf->{'cod'}->get_package == $blk;
}

=head2 S<$h-E<gt>prefix($blk)>

This method specifies a code block to execute when writing to the report file.

=cut

sub prefix
{ my ($slf, $blk) = @_;

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Set the prefix
  $slf->{'cod'} = $blk;
}

=head2 S<$h-E<gt>unprefix>

This method suppresses the execution of a code block when writing to the
report file.

=cut

sub unprefix
{ delete(shift->{'cod'});
}

=head1 SHARE METHODS

=head2 S<$h-E<gt>share($group,$link)>

This method shares the current report and adds it in the specified group with
the specified link text. Temporary files cannot be shared.

It returns a true value when the operation is successful. Otherwise, it returns
a false value.

=cut

sub share
{ my ($slf, $grp, $lnk) = @_;

  # Abort when the report is already ended
  die "RDA-01064: Report already ended\n" unless exists($slf->{'lck'});

  # Define the share
  ($slf->{'typ'} eq 'T') ? 0 : $slf->{'out'}->add_share($slf, $grp, $lnk);
}

=head1 REPORTING METHODS

=head2 S<$h-E<gt>get_length>

This method returns the number of lines of the last file or buffer that has
been read completely.

=cut

sub get_length
{ shift->{'lgt'};
}

=head2 S<$h-E<gt>stat_dir($opt,$dir)>

This method writes the content of a directory with the status information of
each file into the report file. It supports the following attributes:

=over 9

=item B<    'a' > Does not hide entries starting with C<.>

=item B<    'n' > Sorts by name (ascending)

=item B<    't' > Sorts by modification time (descending)

=back

It returns the number of files displayed, or 0 if the directory cannot be
opened, or -1 if no files are displayed.

=cut

sub stat_dir
{ my ($slf, $opt, $dir) = @_;
  my ($all, $fct, $max, $out, @tbl);

  # Abort if we can access to that directory
  return 0 unless $dir && -d $dir;

  # Decode the options
  $opt = '' unless defined($opt);
  $all = index($opt, 'a') >= 0;
  $fct =
      (index($opt, 't') >= 0) ? 't'
    : (index($opt, 'n') <  0) ? '-'
    : $slf->{'_vms'}          ? 'v'
    : 'n';

  # Read the directory content
  $max = [0, 0, 0, 0, 0];
  $out = $slf->{'out'};
  if (RDA::Object::Rda->is_vms)
  { _get_vms_stat(\@tbl, $dir, 1, $max)
  }
  else
  { return 0 unless opendir(DIR, $dir);
    foreach my $nam (readdir(DIR))
    { _get_stat(\@tbl, $out, RDA::Object::Rda->cat_file($dir, $nam), $nam, $max)
        if $all || $nam !~ m/^\./;
    }
    closedir(DIR);
  }

  # Produce the directory listing
  return -1 unless @tbl;
  _write_stat($slf, \@tbl, $max, $fct, $dir);
}

=head2 S<$h-E<gt>stat_file($opt,$file,...)>

This method reports the status information of the specified files. It supports
the following attributes are:

=over 9

=item B<    'b' > Displays the basename of the file only (default)

=item B<    'p' > Keeps the full path of the file

=back

It returns the number of files that have been successfully treated.

=cut

sub stat_file
{ my ($slf, $opt, @fil) = @_;
  my ($all, $flg, $max, $out, $vms, @tbl);

  # Decode the options
  $opt = 'b' unless defined($opt);
  $flg = index($opt, 'p') < 0;

  # Get the status information
  $max = [0, 0, 0, 0, 0];
  $out = $slf->{'out'};
  $vms = RDA::Object::Rda->is_vms;
  foreach my $fil (@fil)
  { if ($vms)
    { _get_vms_stat(\@tbl, $fil, $flg, $max);
    }
    else
    { _get_stat(\@tbl, $out, $fil, ($flg ? basename($fil) : $fil), $max);
    }
  }

  # Write the status information in the report file
  return 0 unless @tbl;
  _write_stat($slf, \@tbl, $max, '');
}

# Decode date/time
sub _dec_dat
{ my ($str) = @_;

  ($str =~ m/^(\d{1,2})-(\w{3})-(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/)
    ? sprintf('%04d%02d%02d%02d%02d%02d',
              $3, $tb_mon{uc($2)} || 0, $1, $4, $5, $6)
    : 0;
}

# Convert the mode in its symbolic format
sub _fmt_bit
{ my ($val, $flg) = @_;
  $val += 8 if $flg;
  $tb_bit[$val];
}

sub _fmt_mod
{ my $mod = shift;

  substr("?pc?d?b?-?l?s?w?", ($mod >> 12) & 017, 1)
    ._fmt_bit(($mod >> 6) & 07, $mod & 04000)
    ._fmt_bit(($mod >> 3) & 07, $mod & 02000)
    ._fmt_bit($mod & 07,        $mod & 01000);
}

# Simplify the date/time
sub _fmt_dat
{ my ($str) = @_;

  return '' unless $str;
  return sprintf('  %s %2d %s:%s %s', $tb_mon[substr($str, 4, 2)],
    substr($str, 6, 2), substr($str, 8, 2), substr($str, 10, 2),
    substr($str,0, 4)) if length($str) == 14;
  $str = gmtime($str);
  '  '.substr($str,4,12).' '.substr($str,20,4);
}

# Resolve the group ID
sub _fmt_gid
{ my $gid = shift;
  my $str;

  eval {$str = getgrgid($gid)};
  return $gid ? "$gid" : '' if $@ || !defined($str);
  $str;
}

# Resolve the user ID
sub _fmt_uid
{ my $uid = shift;
  my $str;

  eval {$str = getpwuid($uid)};
  return $uid ? "$uid" : '' if $@ || !defined($str);
  $str;
}

# Get status information
sub _get_stat
{ my ($tbl, $out, $fil, $nam, $max) = @_;
  my ($grp, $lgt, $siz, $usr, @sta);

  # Get the status information
  return unless (@sta = lstat($fil));
  $out->add_stat($fil, [@sta]);

  # Show symbolic links
  eval {$nam .= ' -> '.readlink($fil)} if -l $fil;

  # Resolve the user and group IDs
  $usr = _fmt_uid($sta[4]);
  $grp = _fmt_gid($sta[5]);

  # Get the size or the device information
  $siz = (-b $fil || -c $fil)
    ? sprintf('[0x%x]', $sta[6])
    : sprintf("%d", $sta[7]);

  # Adjust the information for the column sizes
  if ($max)
  { $max->[0] = 10;
    $max->[1] = $sta[3] if $sta[3] > $max->[1];
    $max->[2] = $lgt if ($lgt = length($usr)) > $max->[2];
    $max->[3] = $lgt if ($lgt = length($grp)) > $max->[3];
    $max->[4] = $lgt if ($lgt = length($siz)) > $max->[4];
  }

  # Add the record to the list
  push(
    @$tbl,
    [ _fmt_mod($sta[2]),
      $sta[3],
      $usr,
      $grp,
      $siz,
      $sta[10],
      $sta[9],
      $nam
    ]
    );
}

sub _get_vms_stat
{ my ($tbl, $pth, $flg, $max) = @_;
  my ($ifh, $lgt, $rec, @sta);

  # Get the status information
  $ifh = IO::Handle->new;
  if (open($ifh, "dir/size/date=modified/owner/prot/noheading/".
    "notrailing/width=(filename=1) $pth |"))
  { while (<$ifh>)
    { s/[\n\r\s]+$//;
      if (m/^\%DIRECT-W-NOFILES,/i)
      { next;
      }
      elsif (m/^\S/)
      { s/^.*\]// if $flg;
        $rec = [ '', 1, '', '', 0, 0, 0, $_ ];
        push(@$tbl, $rec);
      }
      elsif ($rec)
      { @sta = split(/\s+/, $_);
        if ((scalar @sta) == 6)
        { my ($grp, $usr);

          # Extract the information and update the record
          ($usr, $grp) = ($2, $1) if $sta[4] =~ m/^\[(.*),(.*)]$/;
          $rec->[0] = $sta[5];
          $rec->[2] = $usr || $sta[4];
          $rec->[3] = $grp || '';
          $rec->[4] = $sta[1];
          $rec->[6] = _dec_dat($sta[2].' '.$sta[3]);

          # Adjust the information for the column sizes
          if ($max)
          { $max->[0] = $lgt if ($lgt = length($sta[5])) > $max->[0];
            $max->[1] = 1;
            $max->[2] = $lgt if ($lgt = length($usr)) > $max->[2];
            $max->[3] = $lgt if ($lgt = length($grp)) > $max->[3];
            $max->[4] = $lgt if ($lgt = length($sta[1])) > $max->[4];
          }
          $rec = undef;
        }
        else
        { $rec->[6] .= $_;
        }
      }
    }
    $ifh->close;
  }
}

# Display the status information
sub _write_stat
{ my ($slf, $tbl, $max, $fct, $dir) = @_;
  my ($buf);

  # Get the report file handle
  return 0 unless $slf->get_handle;

  # Determine the column sizes
  $max->[1] = length(sprintf("%d", $max->[1]));
  $max->[2]++ if $max->[2];
  $max->[3]++ if $max->[3];

  # Sort the files
  if ($fct eq 'n')
  { $tbl = [sort {$a->[7] cmp $b->[7]} @$tbl];
  }
  elsif ($fct eq 't')
  { $tbl = [sort {$b->[6] <=> $a->[6] || $a->[7] cmp $b->[7]} @$tbl];
  }
  elsif ($fct eq 'v')
  { $tbl = [sort {lc($a->[7]) cmp lc($b->[7])} @$tbl];
  }

  # Produce the directory listing
  $buf = "<verbatim:stat>\n";
  $buf .= "$dir:\n" if $dir;
  foreach my $sta (@$tbl)
  { $buf .= sprintf(" %-*s %*d %-*s%-*s%*s%s%s  %s\n",
      $max->[0], $sta->[0],
      $max->[1], $sta->[1], $max->[2], $sta->[2],
      $max->[3], $sta->[3], $max->[4], $sta->[4],
      _fmt_dat($sta->[5]), _fmt_dat($sta->[6]), $sta->[7]);
  }
  $buf .= "</verbatim>\n";
  $slf->write($buf);

  # Indicate the number of files
  scalar @$tbl;
}

=head2 S<$h-E<gt>write_catalog>

This method writes the catalog of collected files. It returns the number of
entries that it generated.

=cut

sub write_catalog
{ my ($slf) = @_;
  my ($cfg, $cnt, $dft, $dir, $grp, $out, $sub, %tbl);

  # Initialization
  $cnt = 0;
  $out = $slf->{'out'};
  $cfg = $out->get_info('cfg');
  $dir = $out->get_info('dir');
  $grp = $out->get_info('grp');
  $sub = exists($slf->{'sub'});

  # Determine the default Oracle home directory
  if ($dft = $out->get_info('agt')->get_setting('ORACLE_HOME'))
  { $dft = $cfg->cat_dir($dft);
    $dft =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g
  }

  # Parse the index files
  foreach my $mod ($cfg->get_modules, $cfg->get_tests)
  { my ($cmd, $hom, $ifh, $lnk, $pth, $typ);

    $ifh = IO::File->new;
    if ($ifh->open('<'.$cfg->cat_file($dir, $grp.'_'.$mod.'_I.fil')))
    { my ($cmd, $hom, $lnk, $pth, $typ);

      $hom = $dft;
      while (<$ifh>)
      { ($cmd, $lnk, undef, $pth, $typ) = split(/\|/);
        if ($cmd eq 'F')
        { $typ = exists($tb_cat{$typ}) ? $tb_cat{$typ} : '';
          $lnk = $sub
            ? "[[../$lnk][_blank][$mod]]$typ"
            : "[[$lnk][_blank][$mod]]$typ";
          if ($hom && $pth =~ s/^$hom\b/\$OH/)
          { push(@{$tbl{'H'}->{$pth}}, $lnk);
          }
          else
          { push(@{$tbl{'O'}->{$pth}}, $lnk);
          }
          ++$cnt;
        }
        elsif ($cmd eq 'H')
        { next unless $lnk;
          $lnk =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;
          $hom = $lnk;
        }
      }
      $ifh->close;
    }
  }

  # Produce the catalog
  if ($cnt && $slf->get_handle)
  { foreach my $typ (sort keys(%tbl))
    { $slf->write($tb_idx{$typ}."\n|*Path*|*Location*|\n");
      foreach my $pth (sort keys(%{$tbl{$typ}}))
      { $slf->write('|'.RDA::Object::Sgml::encode($pth).' |'
          .join('%BR%', @{$tbl{$typ}->{$pth}})." |\n");
      }
      $slf->write("[[#Top][Back to top]]\n");
    }
  }

  # Return the number of entries
  $cnt;
}

=head2 S<$h-E<gt>write_comment($text)>

This method inserts a text as a comment block in the report file. It returns a
true value for a successful completion. Otherwise, it returns a false value.

=cut

sub write_comment
{ my ($slf, $txt, $idx, @cat) = @_;

  return 0 unless defined($txt);

  # Write the comment
  $txt =~ s/\n?$/\n/;
  $slf->write("<comment>\n");
  $slf->begin_block;
  $slf->write($txt);
  $slf->end_block($idx, @cat);
  $slf->write("</comment>\n");

  # Indicate the successful completion
  1;
}

=head2 S<$h-E<gt>write_data($file)>

This method writes the content of a file or a buffer in the report file without
any transformation. It returns a true value for a successful
completion. Otherwise, it returns a false value.

=cut

sub write_data
{ my ($slf, $fil, $idx, @cat) = @_;
  my ($ifh);

  return 0 unless $fil;
  return _write_data($slf, $fil->get_handle(1), 0, $idx, @cat)
    if ref($fil) eq 'RDA::Object::Buffer';
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    ? _write_data($slf, $ifh, 1, ref($idx) ? $idx : ['F', $fil, 'F', 'D'], @cat)
    : 0;
}

sub _write_data
{ my ($slf, $ifh, $flg, $idx, @cat) = @_;
  my ($buf, $lgt, $off, $pre);

  # Get the report file handle
  return 0 unless $slf->get_handle;

  # Write the file to the report file without any transformation
  binmode($ifh);
  $slf->begin_block;
  if (exists($slf->{'flt'}))
  { while ($lgt = $ifh->sysread($buf, 4096))
    { $buf = $pre.$buf if defined($pre);
      if (($off = 1 + rindex($buf, "\n")) > 0)
      { $slf->write($buf, $off);
        $pre = ($off < $lgt) ? substr($buf, $off) : undef;
      }
      else
      { $pre = $buf;
      }
    }
    $slf->write($pre, length($pre)) if defined($pre);
  }
  else
  { $slf->write($buf, $lgt)
      while ($lgt = $ifh->sysread($buf, 4096));
  }
  $slf->end_block($idx, @cat);
  $ifh->close if $flg;

  # Indicate the successful completion
  1;
}

=head2 S<$h-E<gt>write_diff($file1,$file2,$options)>

This method compares two files and reports the differences. It supports the
following options:

=over 9

=item B<   'b' > Ignores changes in the amount of white spaces

=item B<   'e' > Ignores end of line differences in file contents

=item B<   'i' > Ignores case differences in file contents

=item B<   's' > Ignores simple line swabs

=item B<   't' > Expands tabs to spaces

=item B<   'w' > Ignores all white spaces

=back

It returns 0 if inputs are the same, 1 for trouble with the first file, 2
for trouble with the second file, or 3 if the files are different.

=cut

sub write_diff
{ my ($slf, $fil1, $fil2, $opt) = @_;

  return RDA::Diff::diff_files($fil1, $fil2, $opt, $slf);
}

=head2 S<$h-E<gt>write_explorer>

This method writes the catalog of Explorer reports for the current module. It
returns the number of entries that it generated.

=cut

sub write_explorer
{ my ($slf) = @_;
  my ($cnt, $sub, %tbl);

  # Analyze the catalog
  $sub = exists($slf->{'sub'});
  foreach my $abr (values(%{$slf->{'out'}->get_info('exp', {})}))
  { foreach my $dir (values(%$abr))
    { foreach my $rpt (values(%$dir))
      { foreach my $rec (@$rpt)
        { my ($det, $grp, $lnk, $nam, $typ);

          ($typ, $lnk, undef, $nam) = split(/\|/, $rec);
          ($grp, $det) = split(/\//, $nam, 2);
            ($grp, $det) = ('', $grp) unless defined($det);
          $tbl{$grp}->{$det}->{"$lnk|$typ"} = $sub
            ? "[[../$lnk][_blank][$lnk]]($typ)"
            : "[[$lnk][_blank][$lnk]]($typ)";
        }
      }
    }
  }

  # Produce the report
  $cnt = exists($tbl{''})
    ? _write_set($slf, 'Top Reports', delete($tbl{''}))
    : 0;
  foreach my $grp (sort keys(%tbl))
  { $cnt = _write_set($slf, "Result Set $grp", $tbl{$grp});
  }

  # Return the number of report entries
  $cnt;
}

sub _write_set
{ my ($slf, $ttl, $tbl) = @_;
  my ($cnt, $rec);

  # Write a set
  $cnt = 0;
  $slf->write("---+ $ttl\n|*Report*|*Contributors*|\n");
  foreach my $key (sort keys(%$tbl))
  { $slf->write("|$key |"
      .join('%BR%', map {$rec->{$_}} sort keys(%{$rec= $tbl->{$key}}))
      ." |\n");
    ++$cnt;
  }
  $slf->write("[[#Top][Back to top]]\n");

  # Return the number of report entries
  $cnt;
}

=head2 S<$h-E<gt>write_extract($file,$pattern,$length)>

This method extracts a block from a file or a buffer a block. It uses the
specified pattern to find the beginning of the block. It writes the first
capture buffer from the pattern and the number of bytes in report file. It
returns a true value for a successful completion. Otherwise, it returns a
false value.

=cut

sub write_extract
{ my ($slf, $fil, $pat, $lgt, $idx, @cat) = @_;
  my ($ifh);

  return 0 unless $fil;
  return _write_extract($slf, $fil->get_handle(1), 0, $pat, $lgt, $idx, @cat)
    if ref($fil) eq 'RDA::Object::Buffer';
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    ? _write_extract($slf, $ifh, 1, $pat, $lgt,
        ref($idx) ? $idx : ['F', $fil, 'P', 'D'], @cat)
    : 0;
}

sub _write_extract
{ my ($slf, $ifh, $flg, $pat, $siz, $idx, @cat) = @_;
  my ($buf, $hdr, $lgt, $off, $pre);

  # Get the report file handle
  return 0 unless $slf->get_handle;

  # Search for the beginning of the block
  binmode($ifh);
  return 0 unless (($hdr, $pre) = _find_extract($ifh, $pat, $flg));

  # Write the block to the report file without any transformation
  $slf->begin_block;
  $slf->write($hdr, length($hdr));
  if (exists($slf->{'flt'}))
  { while ($siz > 0 && ($lgt = $ifh->sysread($buf, 4096)))
    { $buf = $pre.$buf if defined($pre);
      if (($off = 1 + rindex($buf, "\n")) > 0)
      { $siz -= $slf->write($buf, ($siz < $off) ? $siz : $off);
        $pre = ($off < $lgt) ? substr($buf, $off) : undef;
      }
      else
      { $pre = $buf;
      }
    }
    $slf->write($pre, ($siz < ($off = length($pre))) ? $siz : $off)
      if defined($pre);
  }
  else
  { $siz -= $slf->write($pre, ($siz < $lgt) ? $siz : $lgt)
      if ($lgt = length($pre));
    $siz -= $slf->write($buf, ($siz < $lgt) ? $siz : $lgt)
      while ($siz > 0 && ($lgt = $ifh->sysread($buf, 4096)));
  }
  $slf->end_block($idx, @cat);
  $ifh->close if $flg;

  # Indicate the successful completion
  1;
}

sub _find_extract
{ my ($ifh, $pat, $flg) = @_;
  my ($buf, $lgt, $min, $off);

  $buf = '';
  $min = ($pat =~ s/^\*(\d+)\*//) ? $1 : length($pat) - 1;
  $off = 0;
  while ($lgt = $ifh->sysread($buf, 4096, $off))
  { return (defined($1) ? $1 : '', $buf) if $buf =~ s/^.*?$pat//s;
    if ($min < 1)
    { $buf = '';
    }
    elsif ($min < ($off += $lgt))
    { $buf = substr($buf, -$min);
      $off = $min;
    }
  }
  $ifh->close if $flg;
  ();
}

=head2 S<$h-E<gt>write_file($file)>

This method writes the content of a file or buffer in the report file. It
returns a true value for a successful completion. Otherwise, it returns a false
value.

It stores the number of lines contained in the file is stored. This number is
accessible by the C<get_length> method.

=cut

sub write_file
{ my ($slf, $fil, $idx, @cat) = @_;
  my ($ifh);

  return 0 unless $fil;
  return _write_file($slf, $fil->get_handle(1), $fil->get_wiki, 0, $idx, @cat)
    if ref($fil) eq 'RDA::Object::Buffer';
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    ? _write_file($slf, $ifh, 1, 1, ref($idx) ? $idx : ['F', $fil, 'F', 'T'],
        @cat)
    : 0;
}

sub _write_file
{ my ($slf, $ifh, $vrb, $flg, $idx, @cat) = @_;
  my ($cnt);

  # Get the report file handle
  return 0 unless $slf->get_handle;

  # Write the file to the report file, taking care on end of lines
  $slf->begin_block($vrb);
  $cnt = 0;
  while (<$ifh>)
  { s/[\r\n]+$//;
    s/^\000+$//;
    ++$cnt;
    $slf->write("$_\n");
  }
  $slf->end_block($idx, @cat);
  $ifh->close if $flg;
  $slf->{'lgt'} = $cnt;

  # Indicate the successful completion
  1;
}

=head2 S<$h-E<gt>write_filter($file,$re[,$alt])>

This method writes the content of a file or a buffer in the report file. It
applies the specified regular expression on each line. It ignores case
distinctions between the file and pattern. You can provide the replacement
string as an extra argument.

It returns a true value for a successful completion. Otherwise, it returns a
false value.

It stores the number of lines contained in the file is stored. That number is
accessible by the C<get_length> method.

=cut

sub write_filter
{ my ($slf, $fil, $re, $alt, $idx, @cat) = @_;
  my ($ifh);

  return 0 unless $fil;
  return _write_filter($slf, $fil->get_handle(1), $fil->get_wiki, 0, $re, $alt,
                       $idx, @cat)
    if ref($fil) eq 'RDA::Object::Buffer';
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    ? _write_filter($slf, $ifh, 1, 1, $re, $alt,
                    ref($idx) ? $idx : ['F', $fil, 'F', 'T'], @cat)
    : 0;
}

sub _write_filter
{ my ($slf, $ifh, $vrb, $flg, $re, $alt, $idx, @cat) = @_;
  my ($cnt);

  # Get the report file handle
  return 0 unless $slf->get_handle;

  # Write the file to the report file, taking care on end of lines
  $slf->begin_block($vrb);
  $alt = '...' unless defined($alt);
  $cnt = 0;
  while (<$ifh>)
  { s/[\r\n]+$//;
    s/^\000+$//;
    s#$re#$1$alt#ig if $re;
    ++$cnt;
    $slf->write("$_\n");
  }
  $slf->end_block($idx, @cat);
  $ifh->close if $flg;
  $slf->{'lgt'} = $cnt;

  # Indicate the successful completion
  1;
}

=head2 S<$h-E<gt>write_lines($file[,$min[,$max]])>

This method writes a line range from a file or a buffer. It assumes the first
and last lines as defaults for the range definition. Lines are numbered
starting with one. It returns a true value for a successful
completion. Otherwise, it returns a false value.

You can use negative line numbers in line buffers to specify lines from the
buffer end.

=cut

sub write_lines
{ my ($slf, $fil, $min, $max, $idx, @cat) = @_;
  my ($ifh, $typ, $vrb);

  return 0 unless $fil;
  if (ref($fil) eq 'RDA::Object::Buffer')
  { $typ = $fil->get_type;
    return ($typ eq 'L')
      ? _write_buffer($slf, $fil->get_handle(1), $fil->get_wiki,
                      $min, $max, $idx, @cat)
      : _write_lines($slf, $fil->get_handle(1), $fil->get_wiki, $typ,
                     $min, $max, $idx, @cat);
  }
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    ? _write_lines($slf, $ifh, 1, '',
                   $min, $max, ref($idx) ? $idx : ['F', $fil, '', 'T'], @cat)
    : 0;
}

sub _write_buffer
{ my ($slf, $ifh, $vrb, $min, $max, $idx, @cat) = @_;
  my ($buf, $ofh);

  # Validate the range
  $buf =  $ifh->getbuf;
  $min = (!defined($min))                   ? 0 :
         ($min > 0)                         ? $min - 1 :
         ($min < 0 && ($#$buf + $min) >= 0) ? $#$buf + $min + 1 :
                                              0;
  $max = (!defined($max))                   ? $#$buf :
         ($max > 0)                         ? $max - 1 :
         ($max < 0 && ($#$buf + $max) >= 0) ? $#$buf + $max + 1 :
                                              0;
  $max = $#$buf if $max > $#$buf;

  # Add the lines to the report
  unless ($min > $max)
  { foreach my $lin (@$buf[$min..$max])
    { # Open the report if needed
      unless ($ofh)
      { return 0 unless ($ofh = $slf->get_handle);
        $slf->begin_block($vrb);
      }

      # Write the line
      $slf->write("$lin\n");
    }
    $slf->end_block($idx, @cat) if $ofh;
  }

  # Indicate the successful completion
  1;
}

sub _write_lines
{ my ($slf, $ifh, $vrb, $flg, $min, $max, $idx, @cat) = @_;
  my ($cnt, $lin, $ofh, $typ);

  # Validate the range
  $min = 1 unless defined($min);
  if (defined($max) && $max > 0)
  { $min = $max + $min if $min < 0;
  }
  else
  { $max = undef;
  }
  $typ = ($min > 1) ? 0 : 1;

  # Add the lines to the report
  $cnt = 0;
  while (<$ifh>)
  { next if ++$cnt < $min;
    if (defined($max) && $cnt > $max)
    { $typ += 2;
      last;
    }

    # Open the report if needed
    unless ($ofh)
    { return 0 unless ($ofh = $slf->get_handle);
      $slf->begin_block($vrb);
    }

    # Write the line
    s/[\r\n]+$//;
    s/^\000+$//;
    $slf->write("$_\n");
  }
  if ($ofh)
  { $idx->[2] = $tb_idx[$typ] if $idx && $idx->[0] eq 'F';
    $slf->end_block($idx, @cat);
  }

  # Close the file
  $ifh->close unless $flg;

  # Indicate the successful completion
  1;
}

=head2 S<$h-E<gt>write_tail($file[,$lgt])>

This method writes the tail of a file or a buffer in the report file. By
default, it writes the 10 last lines. It returns a true value for a successful
completion. Otherwise, it returns a false value.

It stores the number of lines contained in the file is stored. That number is
accessible by the C<get_length> method.

=cut

sub write_tail
{ my ($slf, $fil, $lgt, $idx, @cat) = @_;
  my ($ifh);

  return 0 unless $fil;
  return _write_tail($slf, $fil->get_handle(1), $fil->get_wiki, 0, $lgt, $idx,
    @cat)
    if ref($fil) eq 'RDA::Object::Buffer';
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    ? _write_tail($slf, $ifh, 1, 1, $lgt,
                  ref($idx) ? $idx : ['F', $fil, 'F', 'T'], @cat)
    : 0;
}

sub _write_tail
{ my ($slf, $ifh, $vrb, $flg, $lgt, $idx, @cat) = @_;
  my ($cnt, $typ, @buf);

  # Read the file keeping the last lines in a buffer
  $cnt = 0;
  $lgt = 10 unless defined($lgt);
  while (<$ifh>)
  { push(@buf, m/^\000+[\r\n]+$/ ? '' : $_);
    $typ = shift(@buf) if (scalar @buf) > $lgt;
    ++$cnt;
  }
  $ifh->close if $flg;
  $slf->{'lgt'} = $cnt;

  # Get the report file handle
  return 0 unless $cnt && $slf->get_handle;

  # Write the last lines of the file in the report file.
  $slf->begin_block($vrb);
  for (@buf)
  { s/[\r\n]+$//;
    $slf->write("$_\n");
  }
  $idx->[2] = 'T' if defined($typ) && $idx && $idx->[0] eq 'F';
  $slf->end_block($idx, @cat);

  # Indicate the successful completion
  1;
}

# --- SDCL extensions ---------------------------------------------------------

# Define the parse methods
sub _get_list
{ my ($slf, $spc, $str) = @_;
  my ($val);

  if ($$str =~ s/^\{\s*//)
  { $spc->[$SPC_REF] = $val if ($val = $slf->parse_value($str));
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  $spc->[$SPC_VAL] = $slf->parse_list($str);
}

sub _get_object
{ my ($slf, $spc, $str) = @_;
  my ($val);

  $spc->[$SPC_REF] = $val if ($val = $slf->parse_value($str));
}

sub _get_value
{ my ($slf, $spc, $str) = @_;
  my ($val);

  if ($$str =~ s/^\{\s*//)
  { $spc->[$SPC_REF] = $val if ($val = $slf->parse_value($str));
    die "RDA-00227: Missing closing brace\n"
      unless $$str =~ s/^\}\s*//;
  }
  $spc->[$SPC_VAL] = $slf->parse_value($str);
}

# Close the report
sub _exe_close
{ my ($slf, $spc) = @_;
  my ($obj);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # Close the report
  $obj->close;

  # Indicate a successful completion
  $CONT;
}

# End a report
sub _exe_end
{ my ($slf, $spc) = @_;
  my ($obj);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # End the report
  $slf->get_output->end_report($obj);

  # Indicate the successful completion
  $CONT;
}

# Define a prefix block
sub _exe_prefix
{ my ($slf, $spc) = @_;
  my ($obj);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # Set the prefix
  $obj->prefix($spc->[$SPC_BLK]);

  # Indicate a successful completion
  $CONT;
}

# Add a line in the before buffer
sub _exe_title
{ my ($slf, $spc) = @_;
  my ($obj, $lin);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # Write the line
  $lin = $spc->[$SPC_VAL]->eval_as_line;
  $lin =~ s/[\n\r\s]+$//;
  $obj->push_lines('bef', $lin);

  # Indicate a successful completion
  $CONT;
}

# Clear a prefix block
sub _exe_unprefix
{ my ($slf, $spc) = @_;
  my ($obj);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # Clear the prefix
  $obj->unprefix;

  # Indicate a successful completion
  $CONT;
}

# Pop lines from the before buffer
sub _exe_untitle
{ my ($slf, $spc) = @_;
  my ($obj);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # Clear the prefix
  $obj->pop_lines('bef', defined($spc->[$SPC_VAL])
    ? $spc->[$SPC_VAL]->eval_as_number
    : 1);

  # Indicate a successful completion
  $CONT;
}

# Write a line in the report file
sub _exe_write
{ my ($slf, $spc) = @_;
  my ($obj);

  # Identify the report
  $obj = defined($obj = $spc->[$SPC_REF])
    ? $obj->eval_as_scalar
    : $slf->get_report;
  die "RDA-00201: Report file not specified\n" unless ref($obj) =~ $REPORT;

  # Write the line
  $obj->write($spc->[$SPC_VAL]->eval_as_line);

  # Indicate a successful completion
  $CONT;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Handle::Filter|RDA::Handle::Filter>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Sgml|RDA::Object::Sgml>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
