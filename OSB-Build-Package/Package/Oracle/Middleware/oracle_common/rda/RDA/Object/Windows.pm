# Windows.pm: Class Used for Interfacing with Microsoft Windows

package RDA::Object::Windows;

# $Id: Windows.pm,v 2.16 2012/08/07 09:02:44 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Windows.pm,v 2.16 2012/08/07 09:02:44 mschenke Exp $
#
# Change History
# 20120802  MSC  Improve registry access.

=head1 NAME

RDA::Object::Windows - Class Used for Interfacing with Microsoft Windows

=head1 SYNOPSIS

require RDA::Object::Windows;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Windows> class are used to interface with
Microsoft Windows. Limited operations remain available on other operating
systems.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Handle::Memory;
  use RDA::Object;
  use RDA::Object::Buffer;
  use RDA::Object::Rda;
  use RDA::Local::Windows;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.16 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'getCodePage'     => ['$[WIN]', 'get_code_page'],
    'getRegValue'     => ['$[WIN]', 'get_registry'],
    'getReg32Value'   => ['$[WIN]', 'get_registry32'],
    'getReg64Value'   => ['$[WIN]', 'get_registry64'],
    'getVersionInfo'  => ['$[WIN]', 'get_version'],
    'grepRegValue'    => ['$[WIN]', 'grep_registry'],
    'grepReg32Value'  => ['$[WIN]', 'grep_registry32'],
    'grepReg64Value'  => ['$[WIN]', 'grep_registry64'],
    'hasRegOption'    => ['$[WIN]', 'has_reg_option'],
    'loadRegistry'    => ['$[WIN]', 'load_registry'],
    'writeEvents'     => ['$[WIN]', 'write_events',     '${CUR.REPORT}'],
    'writeFirewall'   => ['$[WIN]', 'write_firewall',   '${CUR.REPORT}'],
    'writeMsinfo'     => ['$[WIN]', 'write_msinfo',     '${CUR.REPORT}'],
    'writeRegistry'   => ['$[WIN]', 'write_registry',   '${CUR.REPORT}'],
    'writeRegistry32' => ['$[WIN]', 'write_registry32', '${CUR.REPORT}'],
    'writeRegistry64' => ['$[WIN]', 'write_registry64', '${CUR.REPORT}'],
    'writeSysinfo'    => ['$[WIN]', 'write_systeminfo', '${CUR.REPORT}'],
    'writeWinmsd'     => ['$[WIN]', 'write_winmsd',     '${CUR.REPORT}'],
    },
  beg => \&_begin_windows,
  dep => [qw(RDA::Object::Output)],
  glb => ['$[WIN]'],
  inc => [qw(RDA::Object)],
  met => {
    'get_code_page'    => {ret => 0},
    'get_info'         => {ret => 0},
    'get_registry'     => {ret => 0},
    'get_registry32'   => {ret => 0},
    'get_registry64'   => {ret => 0},
    'get_version'      => {ret => 0},
    'grep_registry'    => {ret => 1},
    'grep_registry32'  => {ret => 1},
    'grep_registry64'  => {ret => 1},
    'has_reg_option'   => {ret => 0},
    'load_command'     => {ret => 0},
    'load_registry'    => {ret => 0},
    'set_info'         => {ret => 0},
    'write_events'     => {ret => 0},
    'write_firewall'   => {ret => 0},
    'write_msinfo'     => {ret => 0},
    'write_registry'   => {ret => 0},
    'write_registry32' => {ret => 0},
    'write_registry64' => {ret => 0},
    'write_systeminfo' => {ret => 0},
    'write_winmsd'     => {ret => 0},
    },
  );

# Define the global private constants
my $BOC = "<code>\n";
my $BOV = "<verbatim>\n";
my $EOC = "</code>\n";
my $EOV = "</verbatim>\n";
my $WRK = 'win.txt';

my $REG   = '';
my $REG32 = ' /reg:32';
my $REG64 = ' /reg:64';

# Define the global private variables
my %tb_cat = (
  0 => 'None',
  1 => 'General',
  2 => 'Disk',
  8 => 'Installation',
  );
my %tb_msi = (
  'ComponentsDisplay'         => ['Display' => 1],
  'ComponentsStorageDrives'   => ['Disks' => 1, 'Drives' => 1],
  'ComponentsNetworkProtocol' => ['Protocol' => 1],
  'Odbc'                      => ['ODBC Drivers' => 2],
  'ResourcesMemory'           => ['Memory' => 1],
  'SWEnvServices'             => ['Services' => 1],
  'SWEnvDrivers'              => ['System Drivers' => 1],
  'SWEnvEnvVars'              => ['Environment Variables' => 1],
  'SystemSummary'             => ['System Summary' => 1],
  );
my %tb_reg = (
  buf => [\&_get_buf, \&_grep_buf, \&_test_buf, \&_write_buf],
  fil => [\&_get_fil, \&_grep_fil, \&_test_fil, \&_write_fil],
  reg => [\&_get_reg, \&_grep_reg, \&_test_reg, \&_write_reg],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Windows-E<gt>new($agent)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Object::Windows> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'oid' > > Object identifier

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_buf'> > Registry hash

=item S<    B<'_cpg'> > Current code page

=item S<    B<'_msi'> > Msinfo32 access method

=item S<    B<'_opt'> > REG option indicator

=item S<    B<'_reg'> > Registry access methods

=item S<    B<'_wrk'> > Reference to the work file manager

=item S<    B<'_utb'> > UTF16 to UTF8 / begin of file indicator

=item S<    B<'_utf'> > UTF16 to UTF8 / unpack format

=item S<    B<'_uth'> > UTF16 to UTF8 / input file handle

=item S<    B<'_uti'> > UTF16 to UTF8 / input array

=item S<    B<'_utl'> > UTF16 to UTF8 / character left from previous read

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the object
  $slf = bless {
    oid  => $agt->get_oid,
    _agt => $agt,
    _wrk => $agt->get_output,
    }, ref($cls) || $cls;

  # Determine how access the registry and msinfo32
  if (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
  { $slf->{'_buf'} = {};
    $slf->{'_reg'} =
      $tb_reg{$agt->get_registry('windows.reg', \&_init_win_reg, $slf)};
    $slf->{'_opt'} =
      $agt->get_registry('windows.opt', \&_has_reg_option, $slf);
    $slf->{'_msi'} = 1
      if $agt->get_registry('windows.msi', \&_init_win_msi, $slf);
  }
  else
  { $slf->{'_buf'} = [];
    $slf->{'_cpg'} = undef;
    $slf->{'_reg'} = $tb_reg{'fil'};
  }

  # Return the object reference
  $slf;
}

sub _init_win_msi
{ my ($slf) = @_;

  &{$slf->{'_reg'}->[0]}($slf,
    'HKLM\Software\Microsoft\Windows NT\CurrentVersion', 'CurrentVersion',
    '5.1', $REG) =~ m/^6\./;
}

sub _init_win_reg
{ my ($slf) = @_;

  _get_reg($slf,
    'HKLM\Software\Microsoft\Windows NT\CurrentVersion', 'ProductName',
    undef, $REG) ? 'reg' : 'buf';
}

=head2 S<$h-E<gt>get_code_page>

This method returns the current code page. It returns an undefined value
outside Windows platforms.

=cut

sub get_code_page
{ my ($slf) = @_;
  my ($set);

  return $slf->{'_cpg'} if exists($slf->{'_cpg'});

  $slf->{'_agt'}->incr_usage('OS');
  ($set) = `cmd /c chcp`;
  $slf->{'_cpg'} = ($set =~ m/\s(\d+)[\n\r\s]*$/) ? $1 : undef;
}

=head2 S<$h-E<gt>get_registry($key,$nam[,$dft])>

This method returns the value of a registry key name. It returns the default
value when not found.

When using a 32-bit Perl, the method extracts the key value from the 32-bit
registry, while a 64-bit Perl extracts the value from the 64-bit registry.

=head2 S<$h-E<gt>get_registry32($key,$nam[,$dft])>

This method returns the value of a registry key name from the 32-bit
registry. It returns the default value when not found.

=head2 S<$h-E<gt>get_registry64($key,$nam[,$dft])>

This method returns the value of a registry key name from the 64-bit
registry. It returns the default value when not found.

=cut

sub get_registry
{ _get_registry($REG, @_);
}

sub get_registry32
{ _get_registry($REG32, @_);
}

sub get_registry64
{ _get_registry($REG64, @_);
}

sub _get_registry
{ my ($opt, $slf, $key, $nam, $val) = @_;

  return $val unless $key && $nam;
  &{$slf->{'_reg'}->[0]}($slf, $key, $nam, $val, $opt);
}

=head2 S<$h-E<gt>get_version($file[,$flag])>

This method returns the version information of the specified file as a hash
reference. Unless the flag is set, it encodes the value of the entries ending
with C<version>. It returns an empty list when problems are encountered.

=cut

sub get_version
{ my ($slf, $fil, $flg) = @_;
  my ($ifh, $inf);

  $ifh = IO::File->new;
  $inf = {};
  if ($fil && $ifh->open("<$fil"))
  { binmode($ifh);
    _get_version($inf, $ifh, $flg);
    $ifh->close;
  }
  $inf;
}

sub _get_version
{ my ($inf, $ifh, $flg) = @_;
  my ($bas, $buf, $cnt, $nxt, $off, $siz, @tbl);

  # Read the first block
  return unless $ifh->sysread($buf, 4096) == 4096;
  ($nxt) = unpack('L', substr($buf, 0, 4));
  return unless $nxt == 0x905a4d;

  # List the sections
  ($off) = unpack('L', substr($buf, 60, 4));
  ($cnt) = unpack('S', substr($buf, $off +  6, 2));
  ($siz) = unpack('S', substr($buf, $off + 20, 2));
  for ($off += 24 + $siz , $nxt = 0 ; $cnt-- > 0 ; $off += 40)
  { @tbl = unpack('Z8L4', substr($buf, $off, 40));
    ($nxt, $siz, $bas) = ($tbl[4], $tbl[3], $tbl[2]) if $tbl[0] eq '.rsrc';
  }

  # Read the resource block
  return unless $nxt && $siz && defined(sysseek($ifh, $nxt, 0))
    && $ifh->sysread($buf, $siz) == $siz;

  # Find the version information
  ($siz, $cnt) = unpack('S2', substr($buf, 12, 4));
  for ($off = 16 + $siz * 8 , $nxt = 0 ; $cnt-- > 0 ; $off += 8)
  { @tbl = unpack('S3', substr($buf, $off, 6));
    $nxt = $tbl[2] if $tbl[0] == 16;
  }
  return unless $nxt;

  ($off) = unpack('S', substr($buf, $nxt + 20, 2));
  ($off) = unpack('S', substr($buf, $off + 20, 2));
  ($off, $siz) = unpack('L2', substr($buf, $off, 8));

  # Decode the file information
  @tbl = unpack('S*', substr($buf, $off - $bas, $siz));
  _ext_version($inf, \@tbl, 0, $flg) if $siz == $tbl[0];
}

sub _ext_version
{ my ($inf, $tbl, $off, $flg) = @_;
  my ($beg, $dat, $end, $key, $siz, $str, $typ, @str);

  $beg = $off;
  $siz = $tbl->[$off++];
  $end = $beg + $siz / 2;
  $dat = $tbl->[$off++];
  $typ = $tbl->[$off++];

  # Extract the associated key
  push(@str, $tbl->[$off++]) while $tbl->[$off];
  ++$off if ++$off & 1;
  $key = _ext_ver_str(\@str);

  # Extract the value
  if ($typ == 0)
  { $off += int(($dat + 1) / 2);
    ++$off if $off & 1;
  }
  elsif ($dat)
  { @str = ();
    push(@str, $tbl->[$off++]) while $tbl->[$off];
    ++$off if ++$off & 1;
    $str = _ext_ver_str(\@str);
    $str =~ s/\./&#46;/g unless $flg || $key !~ m/version$/i;
    $inf->{$key} = $str;
    return $off;
  }

  $off = _ext_version($inf, $tbl, $off, $flg) while $off < $end;
  return $off;
}

sub _ext_ver_str
{ my ($buf, $chr, @inp);

  _cnv_utf16(\@inp, shift);
  $buf = '';
  $buf .= chr($chr) while defined($chr = shift(@inp)) && $chr;
  $buf;
}

=head2 S<$h-E<gt>grep_registry($key,$nam[,$flg])>

This method returns the list of registry keys that contain the specified value
name. When the flag is set, it returns C<key|name> pairs.

When using a 32-bit Perl, the method extracts the key value from the 32-bit
registry, while a 64-bit Perl extracts the value from the 64-bit registry.

=head2 S<$h-E<gt>grep_registry32($key,$nam[,$flg])>

This method returns the list of registry keys from the 32-bit registry
that contain the specified value name. When the flag is set, it returns
C<key|name> pairs.

=head2 S<$h-E<gt>grep_registry64($key,$nam[,$flg])>

This method returns the list of registry keys from the 64-bit registry
that contain the specified value name. When the flag is set, it returns
C<key|name> pairs.

=cut

sub grep_registry
{ _grep_registry($REG, @_);
}

sub grep_registry32
{ _grep_registry($REG32, @_);
}

sub grep_registry64
{ _grep_registry($REG64, @_);
}

sub _grep_registry
{ my ($opt, $slf, $key, $nam, $flg) = @_;

  return () unless $key && $nam;
  &{$slf->{'_reg'}->[1]}($slf, $key, $nam, $flg, $opt);
}

=head2 S<$h-E<gt>has_reg_option>

This method indicates whether both 32-bit and 64-bit parts of the registry are
accessible.

=cut

sub has_reg_option
{ shift->{'_opt'};
}

sub _has_reg_option
{ my ($slf) = @_;

  &{$slf->{'_reg'}->[2]}($slf);
}

=head2 S<$h-E<gt>load_command($command)>

This method executes the specified command and converts all lines to UTF-8. It
returns a line buffer containing the results or an undefined value in case of
problems.

=cut

sub load_command
{ my ($slf, $cmd) = @_;
  my ($buf);

  # Abort when the command is missing
  return undef unless $cmd
    && (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin);

  # Load the command result
  $buf =_load_command($slf, $cmd);

  # Remove the temporary file
  $slf->{'_wrk'}->clean_work($WRK);

  # Return the execution results
  $buf;
}

sub _load_command
{ my ($slf, $cmd) = @_;
  my ($arg, $buf, $lin, $out, $tmp);

  # Write the command output to a temporary file
  local $SIG{'PIPE'}     = 'IGNORE';
  local $SIG{'__WARN__'} = sub { };

  $tmp = $slf->{'_wrk'}->get_work($WRK, 1);
  $out = RDA::Object::Rda->quote($tmp);
  $arg = $cmd;
  $arg =~ s#(\s+2>&1)?\s*$# >$out $1#;  #
  if (RDA::Object::Rda->is_windows)
  { $arg =~ s#/dev/null#NUL#g;
  }
  else
  { $arg = "exec $arg";
  }
  return undef unless open(OUT, "| $arg");
  close(OUT);
  $slf->{'_agt'}->incr_usage('OS');

  # Load the command result
  return undef unless _open_utf16($slf, $tmp);
  $buf = [];
  push(@$buf, $lin) while defined($lin = _getl_utf16($slf));
  _close_utf16($slf);
  RDA::Object::Buffer->new('L', $buf);
}

=head2 S<$h-E<gt>load_registry($fil)>

This method loads the registry data from a file.

=cut

sub load_registry
{ my ($slf, $fil) = @_;
  my ($lin, $reg);

  if (open(REG, "<$fil"))
  { $slf->{'_buf'} = $reg = [];
    $lin = '';
    while (<REG>)
    { s/[\n\r]+$//;
      $lin .= $_;
      next if $lin =~ s/\\$//;
      if ($lin =~ m/^\[([^\]]*)\]/)
      { push(@$reg, "HKEY_LOCAL_MACHINE\\$1");
      }
      elsif ($lin =~ s/\s+=\s+\((REG_[A-Z_]+)\)\s+"?/ $1 /)
      { $lin =~ s/"?\s*$//;
        push(@$reg, $lin)
      }
      $lin = '';
    }
    close(REG);
    $slf->{'_reg'} = $tb_reg{'fil'};
    1;
  }
  0;
}

=head2 S<$h-E<gt>write_events($rpt,$fil[,$src[,$age[,$full]]])>

This method extracts events from the specified event log and writes them to
the report file. You can filter events by using a regular expression to
indicate which sources are relevant. When a number greater than zero is
specified as age, then only the events more recent than that number of days
are considered. By default, it includes main fields only in the report. This
is controlled by the last argument.

It returns the number of the events written.

=cut

sub write_events
{ my ($slf, $rpt, $fil, $flt, $age, $all) = @_;
  my ($cnt);

  # Initialize the filter
  $flt = qr#$flt# if $flt;
  $age = ($age && $age > 0) ? time - 86400 * $age : 0;

  # Treat the event log file
  $cnt = 0;
  if (open(EVT, "<$fil"))
  { my ($buf, $cmp, $dat, $evt, $lgt, $nxt, $off, $siz, $src, $str);

    # Load the file content
    binmode(EVT);
    $off = 0;
    $off += $lgt while ($lgt = read(EVT, $dat, 65536, $off));
    close(EVT);

    # Create the circular buffer
    $evt = RDA::Handle::Memory->new(\$dat);
    $evt->setlim(unpack('L', $dat));

    # Find and load the end record
    return 0 unless _find_end_evt($evt, \$dat);
    $lgt = $evt->sysread($buf, 4);
    $evt->sysseek($off = unpack('L',$buf), 0);

    # Treat all events
    for ($nxt = 4; ($lgt = $nxt) && $evt->sysread($buf, $lgt) == $lgt ;)
    { # Determine the size of the next record
      ($nxt) = unpack('L', substr($buf,-4));
      next if $lgt == 4;

      # Analyze the header
      my ($sig, $rec, $tmc, $tmw, $eid, $typ, $num, $flg, $cat,
          $end, $off1, $lgt2, $off2, $lgt3, $off3) = unpack("L4S4L7", $buf);
      last unless $sig == 0x654c664c;

      # Filter the event on its age
      next if $age && $tmc < $age;

      # Filter the event on its source
      if (($siz = $off1 - 56) > 0)
      { my (@src, @tbl);
        @src = unpack('v*', substr($buf, 52, $siz));
        _cnv_utf16(\@tbl, \@src);
        $src = _ext_evt_txt(\@tbl);
        $cmp = _ext_evt_txt(\@tbl);
      }
      else
      { $cmp = $src = '';
      }
      next if $flt && $src !~ $flt;

      # Print the event
      $str = ($cnt++) ? "| ||\n" : '';
      $str .= "|*Record Number*|".$rec." |\n" if $all;
      $str .= "|*Event Id*|".$eid
        ." |\n|*Created*|".RDA::Object::Rda->get_gmtime($tmc)
        ." UTC |\n";
      $str .= "|*Written*|".RDA::Object::Rda->get_gmtime($tmw)
        ." UTC |\n|*Type*|".sprintf("0x%04x", $typ)
        ." |\n|*Flag*|".sprintf("0x%04x", $flg)
        ." |\n" if $all;
      $str .= "|*Category*|".($tb_cat{$cat} || "($cat)")." |\n";
      $str .= "|*Source*|".$src." |\n|*Computer*|".$cmp." |\n"
        if $src || $cmp;
      if (($siz = $off3 - $off1) > 0)
      { my (@src, @tbl);
        @src = unpack('v*', substr($buf, $off1 - 4, $siz));
        _cnv_utf16(\@tbl, \@src);
        $str .= "|*Description*|"._ext_evt_txt(\@tbl)." |\n"
      }
      $str .= "|*String*|"._ext_evt_str(substr($buf, $off3 - 4, $lgt3))." |\n"
        if $lgt3;
      $str .= "|*SID*|"._dump_evt_data(substr($buf, $off2 - 4, $lgt2))." |\n"
        if $lgt2;
      $rpt->write($str);
    }
    $evt->close;
  }
  $cnt;
}

sub _dump_evt_data
{ my ($str) = @_;
  my ($buf, $sep);

  $sep = $buf = '';
  foreach my $chr (split(//, $str))
  { $buf .= $sep.sprintf('%02x', ord($chr));
    $sep = ' ';
  }
  "``$buf``";
}

sub _ext_evt_str
{ my ($str) = @_;

  # Detect a string in UTF16
  if ($str =~ m/^\r\000\n\000/)
  { my (@src, @tbl);
    @src = unpack('v*', $str);
    _cnv_utf16(\@tbl, \@src);
    return '``'._ext_evt_txt(\@tbl).'``';
  }

  # Detect a binary string
  return _dump_evt_data($str) if $str =~ m/^.?[\000-\037]/;

  # Treat a string
  _fmt_evt_str($str);
}

sub _ext_evt_txt
{ my $src = shift;
  my $buf = '';
  my $chr;

  while (defined($chr = shift(@$src)))
  { last unless $chr;
    $buf .= chr($chr);
  }
  _fmt_evt_str($buf);
}

sub _find_end_evt
{ my ($evt, $dat) = @_;
  my ($buf, $off, $sig1, $sig2);

  $sig1 = pack('H*',"11111111");
  $sig2 = pack('H*',"11111111222222223333333344444444");
  for ($off = 0 ; ($off = index($$dat, $sig1, $off)) > 0 ; ++$off)
  { 
    unless ($off & 3)
    { $evt->sysseek($off, 0);
      return 0 unless $evt->sysread($buf, 16) == 16;
      return $off if $buf eq $sig2;
    }
  }
  0;
}

sub _fmt_evt_str
{ my ($str) = @_;

  $str =~ s/^\r//g;
  $str =~ s/^[\n\s]+//;
  $str =~ s/[\n\s]+$//;
  $str =~ s/\n+/\%BR\%/g;
  $str =~ s/\'/&#39;/g;
  $str =~ s/\*/&#42;/g;
  $str =~ s/\`/&#96;/g;
  $str =~ s/\|/&#124;/g;
  $str;
}

=head2 S<$h-E<gt>write_firewall($rpt[,$flg])>

This method writes the firewall configuration to the report file. It returns
the number of the lines written. When the flag is set, the subsections do
not contribute to the table of contents.

=cut

sub write_firewall
{ my ($slf, $rpt, $toc) = @_;
  my ($buf, $cnt, $flg, $lvl, $scp);

  return 0 unless RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin;

  $cnt = 0;
  if (open(IN, "netsh firewall show state verbose=enable |"))
  { # Reformat the command output
    $buf = '';
    $toc = $toc ? '+!!' : '';
    while (<IN>)
    { s/[\s\n\r]+$//;
      if (m/^(.*):$/)
      { $buf .= "\n---+$toc $1";
        ++$cnt;
        $flg = $lvl = 2;
        $scp = ($1 =~ m/ICMP settings/) ? 0 : -1;
      }
      elsif (s/\s+=\s/ |/)
      { $buf .= "\n|$_ |";
        ++$cnt;
      }
      elsif ($flg && s/\s{2,}/* |*/g)
      { $lvl = tr/\|/\|/;
        $buf .= "\n|*$_* |";
        ++$cnt;
        if ($scp)
        { $buf .= "*Scope* |";
          $scp = 1;
        }
      }
      elsif (s/\s{2,}/ |/g)
      { $buf .= "\n|$_ |";
        ++$cnt;
      }
      elsif (m/^-+$/)
      { $flg = 0;
      }
      elsif (m/^\s+Scope:\s+(.*)/)
      { $buf .= "Scope: " if $scp < 0;
        $buf .= "$1 |";
      }
      else
      { $buf .= "\n$_";
        ++$cnt;
      }
    }
    $buf .= "\n";
    $rpt->write($buf);
    ++$cnt;
    close(IN);
    $slf->{'_agt'}->incr_usage('OS');
  }

  # Return the number of lines written
  $cnt;
}

=head2 S<$h-E<gt>write_msinfo($rpt,$ttl[,$cat,...])>

This method writes the result of C<msinfo32> categories to the report file. It
returns the number of the lines written.

=cut

sub write_msinfo
{ my ($slf, $rpt, $ttl, @arg) = @_;
  my ($buf, $cat, $cnt, $flg, $hdr, $nxt, $pgm, $pre, $skp, $tbl, $tmp);

  return 0 unless RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin;

  if (exists($slf->{'_msi'}))
  { # Determine the category list
    $tbl = (scalar @arg)
      ? {map {@{exists($tb_msi{$_}) ? $tb_msi{$_} : []}} @arg}
      : {'System Summary' => 1};

    # Get the msinfo32 report on the first call
    $tmp = RDA::Local::Windows->cat_file($slf->{'_wrk'}->get_work('msi.txt',
      1));
    unless (-f $tmp)
    { $pgm = RDA::Local::Windows->cat_file($ENV{'COMMONPROGRAMFILES'},
        'Microsoft Shared', 'MSInfo', 'msinfo32.exe');
      $pgm = '"'.$pgm.'"' unless RDA::Object::Rda->is_cygwin;
      $slf->{'_agt'}->incr_usage('OS');
      eval {
        local $SIG{'__WARN__'} = sub { };

        system($pgm, '/report', $tmp);
        };
      return 0 if $@;
    }
  }
  else
  { # Determine the category list
    $cat = (scalar @arg) ? join('+', @arg) : 'SystemSummary';

    # Get the information in a temporary file
    $tmp = RDA::Local::Windows->cat_file($slf->{'_wrk'}->get_work($WRK, 1));
    $pgm = RDA::Local::Windows->cat_file($ENV{'COMMONPROGRAMFILES'},
      'Microsoft Shared', 'MSInfo', 'msinfo32.exe');
    return 0 unless -x $pgm;
    $slf->{'_agt'}->incr_usage('OS');
    eval {
      local $SIG{'__WARN__'} = sub { };

      system($pgm, '/categories', "+$cat", '/report', $tmp);
      };
    return 0 if $@;
  }

  # Open the file
  return 0 unless $slf->_open_utf16("<$tmp");

  # Reformat the information
  $flg = $skp = 1;
  $cnt = $nxt = 0;
  $hdr = '';
  $pre = "---+ $ttl\n";
  while (defined($_ = $slf->_getl_utf16))
  { s/</&lt;/g;
    s/>/&gt;/g;
    if (s/ *\t */ |/g)
    { next if $skp;
      s/^ \| \|/ ||/g;
      s/^/|/;
      s/([^\|])$/$1|/;
      s/^(\|[^\|]+\|)$/$1|/;
      if ($flg)
      { s/\|/*|*/g;
        s/^\*//;
        s/\*$//;
      }
    }
    elsif (m/^\[(.*)\]$/)
    { if (!$tbl)
      { $skp = ($1 eq 'System Summary' && $cat ne 'SystemSummary');
      }
      elsif (exists($tbl->{$1}))
      { $skp = 0;
        $nxt = $tbl->{$1};
      }
      elsif ($nxt)
      { $skp = (--$nxt) ? 0 : 1;
      }
      else
      { $skp = 1;
      }
      $hdr = ($1 eq $ttl) ? '' : "---++!! $1\n";
      next;
    }
    else
    { $flg = 1;
      next;
    }
    $buf = $pre.$hdr.$_."\n";
    $rpt->write($buf);
    if ($hdr)
    { ++$cnt;
      $hdr = '';
    }
    ++$cnt;
    $flg = $pre = '';
  }
  $slf->_close_utf16;
  $slf->{'_wrk'}->clean_work($WRK) unless $tbl;

  # Return the number of lines written
  $cnt;
}

=head2 S<$h-E<gt>write_registry($rpt,$key[,$lvl])>

This method writes the registry key to the report file. The level (starting
from 0) indicates the highest branch level to include in the report table of
contents. By default, it takes one more than the level of the specified key.
It returns the number of the lines written.

When using a 32-bit Perl, the method extracts the key value from the 32-bit
registry, while a 64-bit Perl extracts the value from the 64-bit registry.

=head2 S<$h-E<gt>write_registry32($rpt,$key[,$lvl])>

This method writes the registry key from the 32-bit registry to the report
file. The level (starting from 0) indicates the highest branch level to
include in the report table of contents. By default, it takes one more than
the level of the specified key. It returns the number of the lines written.

=head2 S<$h-E<gt>write_registry64($rpt,$key[,$lvl])>

This method writes the registry key from the 64-bit registry to the report
file. The level (starting from 0) indicates the highest branch level to
include in the report table of contents. By default, it takes one more than
the level of the specified key. It returns the number of the lines written.

=cut

sub write_registry
{ _write_registry($REG, @_);
}

sub write_registry32
{ _write_registry($REG32, @_);
}

sub write_registry64
{ _write_registry($REG64, @_);
}

sub _write_registry
{ my ($opt, $slf, $rpt, $key, $lvl) = @_;

  # Determine the indexation level
  $lvl = 1 + ($key =~ tr/\\/\\/) unless defined($lvl);

  # Write the registry key and return the number of lines written
  &{$slf->{'_reg'}->[3]}($slf, $rpt, $key, $lvl, $opt);
}

=head2 S<$h-E<gt>write_systeminfo($rpt)>

This method writes the C<systeminfo> information to the report file.

=cut

sub write_systeminfo
{ my ($slf, $rpt) = @_;
  my ($buf, $cnt, $itm, $val, @tbl, @tb_itm, @tb_val);

  return 0 unless RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin;

  # Get the systeminfo output
  $cnt = 0;
  if (open(IN, "systeminfo /FO CSV 2>&1 |"))
  { while (<IN>)
    { s/[\s\n\r]+$//;
      push(@tbl, $1) if m/^"(.*)"$/;
    }
    close(IN);
    $slf->{'_agt'}->incr_usage('OS');
  }
  return 0 unless (scalar @tbl) == 2;

  # Decode the information
  @tb_itm = split(/","/, $tbl[0]);
  @tb_val = split(/","/, $tbl[1]);

  # Output the information
  while (defined($itm = shift(@tb_itm)) && defined($val = shift(@tb_val)))
  { $val =~ s/,/\%BR\%/g if $itm =~ m/^(Hotfix|NetWork|Processor)/i;
    $val =~ s/^\s+/&nbsp;&nbsp;&nbsp;&nbsp;/g;
    $buf = "|$itm |$val |\n";
    $rpt->write($buf);
    ++$cnt;
  }

  # Return the number of lines written
  $cnt;
}

=head2 S<$h-E<gt>write_winmsd($rpt)>

This method writes the result of C<winmsd> to the report file. It returns the
number of the lines written.

=cut

sub write_winmsd
{ my ($slf, $rpt) = @_;
  my ($buf, $cnt, $flg, $hdr, $skp, $tmp);

  return 0 unless RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin;

  # Get the information in a temporary file
  $tmp = $ENV{'COMPUTERNAME'}.'.txt';
  eval {
    local $SIG{'__WARN__'} = sub { };
    system("winmsd /a /f");
    $slf->{'_agt'}->incr_usage('OS');
  };
  return 0 if $@;

  # Open the file
  return 0 unless $slf->_open_utf16("<$tmp");

  # Reformat the information
  $cnt = $skp = 0;
  $flg = 1;
  $hdr = '';
  while (defined($_ = $slf->_getl_utf16))
  { s/[\s]+$//;
    if ($hdr)
    { next if $flg && m/^(-+)?$/;
      $buf = '';
      if (m/^$hdr\s/)
      { $buf .= $EOV unless $flg;
        $buf .= "---++ $_";
        $flg = 1;
      }
      elsif (m/^$/)
      { next if $skp++;
      }
      else
      { $buf .= $BOV if $flg;
        $buf .= $_;
        $skp = $flg = 0;
      }
      $buf .= "\n";
      $rpt->write($buf);
      ++$cnt;
    }
    else
    { $hdr = $1 if m/^(\w+)\s/;
    }
  }
  $slf->_close_utf16;
  $rpt->write($EOV) unless $flg;
  1 while unlink($tmp);

  # Return the number of lines written
  $cnt;
}

#--- UTF16 to UTF8 conversion methods ----------------------------------------

sub _open_utf16
{ my ($slf, $fil) = @_;
  my ($cnt);

  $slf->{'_utb'} = 1;
  $slf->{'_utf'} = 'v*';
  $slf->{'_uth'} = IO::File->new;
  $slf->{'_uti'} = [];
  $slf->{'_utl'} = '';
  $cnt = 10;
  while (!$slf->{'_uth'}->open($fil))
  { return 0 unless $cnt--;
    sleep(1);
  }
  1;
}

sub _close_utf16
{ my ($slf) = @_;

  close($slf->{'_uth'});
}

sub _getl_utf16
{ my ($slf) = @_;
  my ($chr, @lin);

  while (defined($chr = $slf->_getc_utf16))
  { return pack('C*', @lin) if $chr == 10;
    push(@lin, $chr) unless $chr == 13;
  }
  (scalar @lin) ? pack('C*', @lin) : undef;
}

sub _getc_utf16
{ my ($slf) = @_;
  my ($buf, $chr, $inp, $lgt, @src);
 
  # Return a character from the input buffer
  $inp = $slf->{'_uti'};
  return $chr if defined($chr = shift(@$inp));

  # Read a block and convert it
  while ($lgt = $slf->{'_uth'}->sysread($buf, 2048))
  { # Get an even number of characters
    $lgt = length($buf = $slf->{'_utl'}.$buf);
    if ($lgt & 1)
    { $slf->{'_utl'} = substr($buf, -1);
      next unless --$lgt;
      $buf = substr($buf, 0, $lgt);
    }
    else
    { $slf->{'_utl'} = '';
    }

    # Determine the byte order at the beginning of the file
    if ($slf->{'_utb'})
    { $slf->{'_utb'} = 0;
      if ($buf =~ m/^\377\376/)
      { $slf->{'_utf'} = 'v*';
        $buf = substr($buf, 2);
        next if $lgt < 2;
      }
      elsif ($buf =~ m/^\376\377/)
      { $slf->{'_utf'} = 'n*';
        $buf = substr($buf, 2);
        next if $lgt < 2;
      }
    }

    # Decode the buffer
    @src = unpack($slf->{'_utf'}, $buf);
    _cnv_utf16($inp, \@src);
    return $chr if defined($chr = shift(@$inp));
  }

  # Indicate the end of the file
  undef;
}

sub _cnv_utf16
{ my ($inp, $src) = @_;
  my ($chr, $low);

  while (defined($chr = shift(@$src)))
  { # Detect surrogate
    if ($chr >= 0xD800 && $chr <= 0xDFFF)
    { $low = shift(@$src) || 0;
      if ($chr >= 0xDC00 || $low < 0xDC00 || $low > 0xDFFF)
      { unshift(@$src, $low);
        next;
      }
      else
      { $chr = ($chr - 0xD800) * 0x400 + ($low - 0xDC00) + 0x10000;
      }
    }

    # Convert the character
    if ($chr < 0x80)
    { push(@$inp, $chr);
    }
    elsif ($chr < 0x800)
    { push(@$inp, (($chr >> 6)   | 0300),
                  (($chr & 0077) | 0200));
    }
    elsif ($chr < 0x10000)
    { push(@$inp, (( $chr >> 12)         | 0340),
                  ((($chr >>  6) & 0077) | 0200),
                  (( $chr        & 0077) | 0200));
    }
    elsif ($chr < 0x200000)
    { push(@$inp, (( $chr >> 18)         | 0360),
                  ((($chr >> 12) & 0077) | 0200),
                  ((($chr >>  6) & 0077) | 0200),
                  (( $chr        & 0077) | 0200));
    }
  }
}

#--- File query methods ------------------------------------------------------

# Get a registry value
sub _get_fil
{ my ($slf, $key, $nam, $val) = @_;
  my $flg;

  if ($key && $nam)
  { # Normalize the key
    $key =~ s/^HKCU\\/HKEY_CURRENT_USER\\/i;
    $key =~ s/^HKLM\\/HKEY_LOCAL_MACHINE\\/i;
    $key =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;
    $nam =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;

    # Get the value
    for (@{$slf->{'_buf'}})
    { if ($flg && m/^\s+$nam\s/i)
      { s/[\s\n\r]+$//;
        my @tbl = split(/\s+/, $_, 4);
        $val = $tbl[3] if defined($tbl[3]);
      }
      elsif (m/^$key$/i)
      { $flg = 1;
      }
      elsif (m/^[A-Z]/)
      { $flg = 0;
      }
    }
  }
  $val;
}

# Grep all registry keys containing a name
sub _grep_fil
{ my ($slf, $key, $nam, $flg) = @_;
  my ($lst, @tbl);

  if ($key && $nam)
  { # Normalize the key
    $key =~ s/^HKCU\\/HKEY_CURRENT_USER\\/i;
    $key =~ s/^HKLM\\/HKEY_LOCAL_MACHINE\\/i;
    $key =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;

    # Search in the buffer
    for (@{$slf->{'_buf'}})
    { if (m/^\s+($nam)\s/i)
      { push(@tbl, $flg ? "$lst|$1" : $lst) if $lst;
      }
      elsif (m/^$key/i)
      { $lst = $_;
      }
      elsif (m/^[A-Z]/)
      { $lst = undef;
      }
    }
  }
  @tbl;
}

# Test access to both registry parts
sub _test_fil
{ 0;
}

# Write registry information
sub _write_fil
{ my ($slf, $rpt, $key, $lvl) = @_;
  my ($buf, $cnt, $flg, $hit, $nam, $toc, $typ, $val);

  # Normalize the key
  $key =~ s/^HKCU\\/HKEY_CURRENT_USER\\/i;
  $key =~ s/^HKLM\\/HKEY_LOCAL_MACHINE\\/i;
  $key =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;

  # Write the registry key
  $cnt = 0;
  if (@{$slf->{'_buf'}})
  { # Reformat the command output
    for (@{$slf->{'_buf'}})
    { s/[\s\n\r]+$//;
      next if m/^$/ || m/^!/ || m/^Error:/;
      if (m/^[A-Z]/)
      { $buf = '';
        $buf .= $EOC if $flg;
        $flg = 0;
        next unless $hit = m/^$key/i;
        $toc = tr/\\/\\/;
        $toc = ($toc > $lvl) ? '+!!' : '';
        $buf .= "\n---++$toc ``[$_]``\n";
        $rpt->write($buf);
        ++$cnt;
      }
      elsif ($hit && m/^\s+(.*)\sREG_([A-Z_]+)\s(.*)$/)
      { ($buf, $nam, $typ, $val) = ('', $1, $2, $3);
        $buf .= $BOC unless $flg++;
        $nam = '(Default)' if $nam eq '<NO NAME>';
        if ($typ =~ m/SZ$/)
        { $buf .= "$nam = \"$val\"\n";
        }
        else
        { $typ = lc($typ);
          $buf .= "$nam = $typ:$val\n";
        }
        $rpt->write($buf);
        ++$cnt;
      }
    }
    close(IN);
  }
  $rpt->write($EOC) if $flg;

  # Return the number of lines written
  $cnt;
}

#--- Reg query methods -------------------------------------------------------

# Get a registry value
sub _get_reg
{ my ($slf, $key, $nam, $val, $opt) = @_;

  if (open(REG, "reg query \"$key\" /v "
    .RDA::Object::Rda->quote($nam)
    .($slf->{'_opt'} ? $opt : $REG)." 2>&1 |"))
  { $nam =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;
    while (<REG>)
    { if (m/^\s+$nam\s/i)
      { s/[\s\n\r]+$//;
        my @tbl = split(/\s+/, $_, 4);
        $val = $tbl[3] if defined($tbl[3]);
      }
    }
    close(REG);
    $slf->{'_agt'}->incr_usage('OS');
  }
  $val;
}

# Grep all registry keys containing a name
sub _grep_reg
{ my ($slf, $key, $nam, $flg, $opt) = @_;
  my ($lst, @tbl);

  if (open(REG, "reg query \"$key\" /s".($slf->{'_opt'} ? $opt : $REG)
    ." 2>&1 |"))
  { while (<REG>)
    { s/[\s\n\r]+$//;
      if ($lst && m/^\s+($nam)\s/i)
      { push(@tbl, $flg ? "$lst|$1" : $lst);
      }
      elsif (m/^[A-Z]/)
      { $lst = $_;
      }
    }
    close(REG);
    $slf->{'_agt'}->incr_usage('OS');
  }
  @tbl;
}

# Test access to both registry parts
sub _test_reg
{ my ($slf) = @_;

  return 0 unless open(REG, "reg query \"HKLM\" /reg:64 2>&1 |");
  while (<REG>)
  { next unless m/^Error:/i;
    close(REG);
    return 0;
  }
  close(REG);
  1;
}

# Write registry information
sub _write_reg
{ my ($slf, $rpt, $key, $lvl, $opt) = @_;
  my ($buf, $cnt, $cod, $nam, $toc, $typ, $val);

  # Write the registry key
  $cnt = 0;
  if (open(IN, "reg query \"$key\" /s".($slf->{'_opt'} ? $opt : $REG)
    ." 2>&1 |"))
  { # Reformat the command output
    while (<IN>)
    { s/[\s\n\r]+$//;
      next if m/^$/ || m/^!/ || m/^Error:/i;
      if (m/^[A-Z]/)
      { $toc = tr/\\/\\/;
        $toc = ($toc > $lvl) ? '+!!' : '';
        $buf = '';
        $buf .= $EOC if $cod;
        $buf .= "\n---++$toc ``[$_]``\n";
        $rpt->write($buf);
        ++$cnt;
        $cod = 0;
      }
      elsif (m/^\s+(.*\S)\s+REG_([A-Z_]+)\s+(.*)$/)
      { ($buf, $nam, $typ, $val) = ('', $1, $2, $3);
        $buf .= $BOC unless $cod++;
        $nam = '(Default)' if $nam eq '<NO NAME>';
        if ($typ =~ m/SZ$/)
        { $val =~ s/\./&#46;/g if $nam =~ m/version$/i;
          $buf .= "$nam = \"$val\"\n";
        }
        else
        { $typ = lc($typ);
          $buf .= "$nam = $typ:$val\n";
        }
        $rpt->write($buf);
        ++$cnt;
      }
    }
    close(IN);
    $slf->{'_agt'}->incr_usage('OS');
  }
  $rpt->write($EOC) if $cod;

  # Return the number of lines written
  $cnt;
}

#--- Regedit methods ---------------------------------------------------------

# Get a registry value
sub _get_buf
{ my ($slf, $key, $nam, $val) = @_;
  my ($flg, $reg);

  ($key, $reg) = _key_buf($key);
  $nam =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;
  for (@{$slf->_sel_buf($key)})
  { if ($flg && m/^\s+$nam\s/i)
    { my @tbl = split(/\s+/, $_, 4);
      $val = $tbl[3] if defined($tbl[3]);
      last;
    }
    elsif (m/^[A-Z]/)
    { last if $flg;
      $flg = $_ =~ m/^$reg$/i;
    }
  }
  $val;
}

# Grep all registry keys containing a name
sub _grep_buf
{ my ($slf, $key, $nam, $flg) = @_;
  my ($lst, $reg, @tbl);

  ($key, $reg) = _key_buf($key);
  for (@{$slf->_sel_buf($key)})
  { if ($lst && m/^\s+($nam)\s/i)
    { push(@tbl, $flg ? "$lst|$1" : $lst);
    }
    elsif (m/^[A-Z]/)
    { if (m/^$reg/i)
      { $lst = $_;
      }
      elsif ($lst)
      { last;
      }
    }
  }
  @tbl;
}

# Reformat the key for searching in buffer
sub _key_buf
{ my ($key) = @_;
  my ($reg);

  $key =~ s/^HKCU/HKEY_CURRENT_USER/i;
  $key =~ s/^HKLM/HKEY_LOCAL_MACHINE/;
  $reg = $key;
  $reg =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;
  ($key, $reg);
}

# Load a registry key in memory
sub _load_buf
{ my ($slf, $key) = @_;
  my ($buf, $flg, $lin, $nam, $tmp, $typ);

  # Export the registry key
  $tmp = RDA::Local::Windows->cat_file($slf->{'_wrk'}->get_work($WRK, 1));
  $slf->{'_buf'}->{uc($key)} = $buf = [];
  system('regedit /e "'.$tmp.'" "'.$key.'"');
  unless ($?)
  { # Load the registry key
    $flg = 0;
    $lin = '';
    if ($slf->_open_utf16("<$tmp"))
    { while (defined($_ = $slf->_getl_utf16))
      { s/\s+$//;
        s/^\s+//;
        $lin .= $_;
        next if $lin =~ s/\\$//;
        $lin =~ s/\s+$//;
        next if $lin =~ m/^$/;
        if ($lin =~ m/^\[([^\]]+)/)
        { push(@$buf, $1);
          $flg = 1;
        }
        elsif ($flg)
        { $nam = ($lin =~ s/^"([^"]*)"=//) ? $1 :
                 ($lin =~ s/@=//) ? '<NO NAME>' :
                 '?';
          if ($lin =~ s/^"([^"]*)"/$1/)
          { $typ = 'REG_SZ ';
            $lin =~ s/\\(.)/$1/g;
          }
          elsif ($lin =~ s/^hex\(0\)://i)
          { $typ = 'REG_NONE';
          }
          elsif ($lin =~ s/^hex://i)
          { $typ = 'REG_BINARY ';
            $lin =~ s/,//g;
            $lin = uc($lin);
          }
          elsif ($lin =~ s/^hex\(2\)://i)
          { $typ = 'REG_EXPAND_SZ ';
            $lin =~ s/00,?//g;
            $lin =~ s/[\dA-Fa-f]{2},?/chr(oct('0x'.substr($&,0,2)))/eg;
          }
          elsif ($lin =~ s/^dword://i)
          { $typ = 'REG_DWORD 0x';
            $lin =~ s/^0+(\d)/$1/;
          }
          else
          { $typ = '?';
          }
          push(@$buf, "    $nam $typ$lin");
        }
        $lin = '';
      }
      $slf->_close_utf16;
    }
  }
  $slf->{'_agt'}->incr_usage('OS');

  # Delete the temporary file
  $slf->{'_wrk'}->clean_work($WRK);

  # Return the buffer
  $buf;
}

# Select the buffer
sub _sel_buf
{ my ($slf, $key) = @_;

  my $ref = uc($key);
  foreach my $cur (sort {length($a) <=> length($b)} keys(%{$slf->{'_buf'}}))
  { return $slf->{'_buf'}->{$cur} if $cur eq substr($ref, 0, length($cur));
  }
  return $slf->_load_buf($key);
}

# Test access to both registry parts
sub _test_buf
{ 0;
}

# Write registry information
sub _write_buf
{ my ($slf, $rpt, $key, $lvl) = @_;
  my ($buf, $cnt, $cod, $flg, $nam, $ref, $reg, $toc, $typ, $val);

  # Write the registry key
  ($key, $reg) = _key_buf($key);
  $ref = $slf->_sel_buf($key);
  $cnt = 0;
  if (@$ref)
  { # Reformat the command output
    for (@$ref)
    { if (m/^[A-Z]/)
      { if (m/^$reg/i)
        { $flg = 1;
        }
        elsif ($flg)
        { last;
        }
        $toc = tr/\\/\\/;
        $toc = ($toc > $lvl) ? '+!!' : '';
        $buf = '';
        $buf .= $EOC if $cod;
        $buf .= "\n---++$toc ``[$_]``\n";
        $rpt->write($buf);
        ++$cnt;
        $cod = 0;
      }
      elsif ($flg && m/^\s+(.*\S)\s+REG_([A-Z_]+)\s+(.*)$/)
      { ($buf, $nam, $typ, $val) = ('', $1, $2, $3);
        $buf .= $BOC unless $cod++;
        $nam = '(Default)' if $nam eq '<NO NAME>';
        if ($typ =~ m/SZ$/)
        { $val =~ s/\./&#46;/g if $nam =~ m/version$/i;
          $buf .= "$nam = \"$val\"\n";
        }
        else
        { $typ = lc($typ);
          $buf .= "$nam = $typ:$val\n";
        }
        $rpt->write($buf);
        ++$cnt;
      }
    }
  }
  $rpt->write($EOC) if $cod;

  # Return the number of lines written
  $cnt;
}

# --- SDCL extensions ---------------------------------------------------------

# Define a global variable to access the interface object
sub _begin_windows
{ my ($pkg) = @_;

  $pkg->define('$[WIN]', RDA::Object::Windows->new($pkg->get_agent));
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Handle::Memory|RDA::Handle::Memory>,
L<RDA::Local::Windows|RDA::Local::Windows>,
L<RDA::Object::Buffer|RDA::Object::Buffer>
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
