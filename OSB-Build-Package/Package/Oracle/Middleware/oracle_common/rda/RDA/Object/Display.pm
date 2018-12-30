# Display.pm: Class Used for Controlling the Display

package RDA::Object::Display;

# $Id: Display.pm,v 2.12 2012/04/25 06:44:50 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Display.pm,v 2.12 2012/04/25 06:44:50 mschenke Exp $
#
# Change History
# 20120422  MSC  Apply agent changes.

=head1 NAME

RDA::Object::Display - Class Used for Controlling the Display

=head1 SYNOPSIS

require RDA::Object::Display;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Display> class are used for controlling the
display. It is a sub class of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Handle::Data;
  use RDA::Handle::Memory;
  use RDA::Object;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.12 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'echo'    => ['$[DSP]', 'dsp_line'],
    'explain' => ['$[DSP]', 'explain'],
    },
  beg => \&_begin_display,
  glb => ['$[DSP]'],
  inc => [qw(RDA::Object)],
  met => {
    'dsp_block'   => {ret => 0},
    'dsp_data'    => {ret => 0},
    'dsp_error'   => {ret => 0},
    'dsp_line'    => {ret => 0, evl => 'L'},
    'dsp_pod'     => {ret => 0},
    'dsp_report'  => {ret => 0},
    'dsp_string'  => {ret => 0},
    'dsp_text'    => {ret => 0},
    'get_info'    => {ret => 0},
    'explain'     => {ret => 0},
    'set_info'    => {ret => 0},
    'wrap_string' => {ret => 0},
    },
  );

# Define the global private constants

# Define the global private variables
my %tb_det = (
  '_B_'    => ".I '        \001- '\n",
  '_P_'    => ".I '        '\n",
  'Action' => ".I 'Action: '\n",
  'Cause'  => ".I 'Cause: '\n",
  );
my %tb_err = (
  'EXPL'  => 'expl.txt',
  'IRDA'  => 'irda.txt',
  'OCM'   => 'ocm.txt',
  'ODRDA' => 'odrda.txt',
  'RDA'   => 'err.txt',
  'STB'   => 'stb.txt',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Display-E<gt>new($agt)>

The object constructor. This method enables you to specify the agent reference
as an argument.

C<RDA::Object::Display> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Associated agent reference

=item S<    B<'_cfg'> > RDA software configuration reference

=item S<    B<'_col'> > Screen width (in columns)

=item S<    B<'_out'> > Output indicator

=item S<    B<'_pag'> > Pager redirection

=item S<    B<'_sep'> > Separation line

=item S<    B<'_vms'> > VMS indicator

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($cfg, $slf);

  # Create the library object
  $cfg = $agt->get_config;
  $slf = bless {
    _agt => $agt,
    _col => $cfg->get_columns,
    _cfg => $cfg,
    _out => $agt->get_info('out') ? 0 : 1,
    _vms => $cfg->is_vms,
    }, ref($cls) || $cls;

  # Extra initialization
  $slf->{'_pag'} =
    exists($ENV{'PAGER'}) ? '| '.$ENV{'PAGER'} :
    $slf->{'_vms'}        ? '| TYPE/PAGE=SAVE SYS$INPUT' :
                            '| more';
  $slf->{'_pag'} .= ' 2>&1' if $cfg->is_unix || $cfg->is_cygwin;
  $slf->{'_sep'} = '-' x $slf->{'_col'};

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method deletes the library object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>dsp_block($txt[,$var])>

This method displays a text block. The text can contain variables that are
resolved through attributes specified as a hash. When the variable is not
defined, settings and properties are used.

=cut

sub dsp_block
{ my ($slf, $txt, $var) = @_;

  _dsp_text($slf, $var, 
    (ref($txt) eq 'ARRAY') ? RDA::Handle::Data->new($txt) :
    ref($txt)              ? $txt :
                             RDA::Handle::Memory->new($txt));
}

=head2 S<$h-E<gt>dsp_data($dat[,$flg])>

This method displays the data content. When the flag is set, it displays the
data through a pager.

=cut

sub dsp_data
{ my ($slf, $dat, $flg) = @_;
  my ($pid, $ret);

  return 0 unless $slf->{'_out'} && defined($dat);

  $dat = join("\n", @$dat, '') if ref($dat);
  return syswrite(STDOUT, $dat, length($dat)) unless $flg && -t STDOUT;
  $pid = open(OUT, $slf->{'_pag'});
  die "RDA-01210: Cannot open pager:\n $!\n" unless $pid;
  $ret = syswrite(OUT, $dat, length($dat));
  close(OUT);
  waitpid($pid, 0);
  $ret;
}

=head2 S<$h-E<gt>dsp_error($err)>

This method displays the explanation of the specified error.

=cut

sub dsp_error
{ my ($slf, $err, $flg) = @_;

  $slf->{'_out'}
    ? dsp_report($slf, RDA::Handle::Memory->new(explain($slf, $err)),
        defined($flg) ? $flg : 0)
    : 0;
}

=head2 S<$h-E<gt>dsp_line($lin)>

This method displays the specified line. It converts the leading spaces and a
possible bullet character in a prefix and wrap the words according to the
display width. Is also recognizes a Ctrl-A character as separator between the
prefix and the text.

=cut

sub dsp_line
{ my ($slf, $lin) = @_;
  my ($buf);

  return 0 unless $slf->{'_out'} && defined($lin);

  $lin =~  s/^(.*?)\001// || $lin =~ s/^(\s*([o\-\*]\s+)?)//;
  $buf = length($lin) ? wrap_string($slf, $1, $lin) : $1;
  syswrite(STDOUT, $buf, length($buf));
}

=head2 S<$h-E<gt>dsp_pod($fil[,$flg])>

This method displays data in Perl documentation format. When you specify an
array of file as argument, it converts the first readable file from that
list. When the flag is set or not specified, it displays the documentation
through a pager.

=cut

sub dsp_pod
{ my ($slf, $fil, $flg) = @_;

  if ($slf->{'_out'} && defined($fil))
  { my ($cfg, $pth);

    # Initialize Pod on first use
    unless (exists($slf->{'_pod'}))
    { eval "require RDA::Object::Pod";
      die "RDA-01211: Package 'RDA::Object::Pod' not available:\n $@\n" if $@;
      $slf->{'_pod'} = RDA::Object::Pod->new($slf->{'_cfg'});
    }

    # Display the documentation
    $cfg = $slf->{'_cfg'};
    $flg = 1 unless defined($flg);
    if (ref($fil) eq 'ARRAY')
    { foreach my $pth (@$fil)
      { return _dsp_pod($slf, $pth, $flg) if -r $pth;
      }
    }
    elsif ($cfg->is_absolute($fil))
    { return _dsp_pod($slf, $fil, $flg);
    }
    else
    { return _dsp_pod($slf, $pth, $flg)
        if -r ($pth = $cfg->get_file('D_RDA_POD',  $fil, '.pod'))
        || -r ($pth = $cfg->get_file('D_RDA_CODE', $fil, '.def'))
        || -r ($pth = $cfg->get_file('D_RDA_CODE', $fil, '.ctl'))
        || -r ($pth = $cfg->get_file('D_RDA_PERL', $fil, '.pod'))
        || -r ($pth = $cfg->get_file('D_RDA_POD',  $fil, '.pm'))
        || -r ($pth = $cfg->get_file('D_RDA_PERL', $fil, '.pm'));
    }
  }
  0;
}

sub _dsp_pod
{ my ($slf, $fil, $flg) = @_;
  my ($pid, $ret);

  if ($flg && -t STDOUT)
  { die "RDA-01210: Cannot open pager:\n $!\n"
      unless ($pid = open(OUT, $slf->{'_pag'}));
    $ret = $slf->{'_pod'}->pod2text(\*OUT, $fil);
    close(OUT);
    waitpid($pid, 0);
  }
  else
  { $ret = $slf->{'_pod'}->pod2text(\*STDOUT, $fil);
  }
  $ret;
}

=head2 S<$h-E<gt>dsp_report($rpt[,$flg])>

This method formats and displays a report. You can specify the report as a
string or a reference to an array of lines. When the flag is set or is not
specified, it displays the report through a pager. It returns the number of
lines effectively treated.

Following format directives are available:

Multi-Column output:

  .C <# spaces><eol>
  <item><eol>
  ...
  <item><eol>
  <eol>

Indented paragraph:

  .I '<prefix text>' <# new lines><eol>
  <line><eol>
  ...
  <line><eol>
  <eol>

New lines:

  .N <# new lines><eol>

Paragraph:

  .P <# new lines><eol>
  <line><eol>
  ...
  <line><eol>
  <eol>

Query (Web only)

  .Q <key>='<label>'<eol>

Report Name:

  .R '<title>'<eol>

Separation line:

  .S<eol>

Title:

  .T '<title>'<eol>

Comment:

  # <comment text to skip>

=cut

sub dsp_report
{ my ($slf, $rpt, $flg) = @_;
  my ($cnt, $ifh, $pid);

  # Abort when no report or no output
  return 0 unless defined($rpt) && length($rpt) && $slf->{'_out'};

  # Produce the report
  if (ref($rpt) eq 'ARRAY')
  { $ifh = RDA::Handle::Data->new($rpt);
  }
  elsif (ref($rpt))
  { $ifh = $rpt;
  }
  else
  { $ifh = RDA::Handle::Memory->new($rpt);
    $ifh->setinfo('eol', 0);
  }

  if (($flg || !defined($flg)) && -t STDOUT)
  { die "RDA-01210: Cannot open pager:\n $!\n"
      unless ($pid = open(OUT, $slf->{'_pag'}));
    $cnt = $slf->_dsp_report($ifh, *OUT);
    close(OUT);
    waitpid($pid, 0);
  }
  else
  { $cnt = $slf->_dsp_report($ifh, *STDOUT);
  }

  # Return the number of line treated
  $cnt;
}

sub _dsp_report
{ my ($slf, $ifh, $ofh) = @_;
  my ($buf, $cnt);

  $cnt = 0;
  while (<$ifh>)
  { if (m/^.C(\s*(\d+))?$/)
    { $buf = _fmt_columns($slf, $ifh, $2);
    }
    elsif (m/^.I\s*'(.*)'(\s+(\d+))?$/)
    { $buf = wrap_string($slf, _clr_string($1), _read_para($ifh), $3);
    }
    elsif (m/^.N\s*(\d+)$/)
    { next unless $1 > 0;
      $buf = "\n" x $1;
    }
    elsif (m/^.P(\s*(\d+))?$/)
    { $buf = wrap_string($slf, '', _read_para($ifh), $2);
    }
    elsif (m/^.[RT]\s*'(.*)'$/)
    { $buf = _clr_string($1)."\n";
      $buf =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
    }
    elsif (m/^.S$/)
    { $buf = $slf->{'_sep'}."\n";
    }
    elsif (!m/^(#|\.Q)/)
    { $buf = wrap_string($slf, '', _clr_string($_));
    }
    syswrite($ofh, $buf, length($buf));
    ++$cnt;
  }
  $ifh->close;

  # Return the number of line treated
  $cnt;
}

=head2 S<$h-E<gt>dsp_string($pre,$txt[,$nxt])>

This method displays a string. The string is wrapped according to the screen
width and the prefix is added on each screen line. On continuous lines, spaces
replace nonspace characters. The last argument indicates the number of line
feeds to add at the end of the string (1 by default).

=cut

sub dsp_string
{ my ($slf, $pre, $txt, $nxt) = @_;
  my ($buf);

  return 0 unless $slf->{'_out'} && defined($pre) && defined($txt);
  $buf = wrap_string($slf, $pre, $txt, $nxt);
  syswrite(STDOUT, $buf, length($buf));
}

=head2 S<$h-E<gt>dsp_text($nam[,$var])>

This method displays a text from F<rda.txt>. The text can contain variables
that are resolved through attributes specified as a hash. When the variable is
not defined, settings and properties are used.

=cut

sub dsp_text
{ my ($slf, $nam, $var) = @_;
  my ($ifh);

  $ifh = IO::File->new;
  if ($ifh->open('<'.$slf->{'_cfg'}->get_file('D_RDA_DATA', 'rda.txt')))
  { while (<$ifh>)
    { return _dsp_text($slf, $var, $ifh, qr/^===\s.*\s===$/)
        if m/^===\s+$nam\s+===[\s\r\n]+$/;
    }
    $ifh->close;
  }
  0;
}

sub _dsp_text
{ my ($slf, $var, $ifh, $eof) = @_;
  my ($buf, $cnt, $pre);

  return 0 unless $slf->{'_out'};

  $cnt = 0;
  $var = {}  unless ref($var);

  while (<$ifh>)
  { s/[\s\r\n]+$//;
    last if $eof && $_ =~ $eof;
    next if m/^#/;
    if (m/^$/)
    { $buf = "\n";
    }
    elsif (m/^-{3,}$/)
    { $buf = $slf->{'_sep'}."\n";
    }
    else
    { $pre = s/^([\-\s]*)(\S)/$2/ ? $1 : '';
      s/\$\{(\w+\.)*\w+\}/_enc_value($slf, $var, substr($&, 2, -1))/eg;
      $buf = $slf->wrap_string($pre, $_, 1);
    }
    syswrite(STDOUT, $buf, length($buf));
    ++$cnt;
  }
  $ifh->close;
  $cnt;
}

sub _enc_value
{ my ($slf, $tbl, $key) = @_;
  my $str;

  if (exists($tbl->{$key}))
  { $str = $tbl->{$key};
  }
  elsif ($key =~ m/^CFG\.(\w+)$/)
  { $str = $slf->{'_agt'}->get_setting($1, '?');
  }
  elsif ($key =~ m/^ENV\.(\w+)$/)
  { $str = exists($ENV{$1}) ? $ENV{$1} : '?';
  }
  elsif ($key =~ m/^GRP\.(\w+)$/)
  { $str = $slf->{'_cfg'}->get_group($1);
  }
  elsif ($key =~ m/^OUT\.(\w+)$/)
  { $str = $slf->{'_agt'}->get_output->get_path($1);
  }
  elsif ($key =~ m/^RDA\.(\w+)$/)
  { $str = $slf->{'_cfg'}->get_value($1, '?');
  }
  else
  { $str = $slf->{'_agt'}->get_setting($key, '?');
  }
  $str =~ s/\\/\\134/g;
  $str;
}

=head2 S<$h-E<gt>explain($err)>

This method returns the explanation of the specified error as a report script.

=cut

sub explain
{ my ($slf, $err) = @_;
  my ($buf, $fil, $grp, $lgt, $rpt, $typ, @buf);

  # Determine the error type
  $typ = 'RDA';
  ($typ, $err) = ($1, $2) if $err =~ m/^([A-Z]+)-(\d+)$/i;
  return '' unless exists($tb_err{$typ});

  # Determine the error file name
  if ($err >= 10000 && opendir(DIR, $slf->{'_cfg'}->get_group('D_RDA_DATA')))
  { $grp = sprintf("S%03d", int($err / 100));
    ($fil) = grep {m/^$grp.*\.txt$/i} readdir(DIR);
    closedir(DIR);
  }
  $fil = $tb_err{$typ} unless defined($fil);

  # Get the error explanation
  $rpt = '';
  if ($fil && open(ERR, '<'.$slf->{'_cfg'}->get_file('D_RDA_DATA', $fil)))
  { while (<ERR>)
    { s/[\s\r\n]+//;
      if (m/^(\d+),\d+,\s*"([^"]*)"/ && $err == $1)
      { $rpt = ".P\n$typ-$1: $2\n\n";
        $buf = '';
        while (<ERR>)
        { s/[\s\r\n]+$//;
          last unless s#^//\s## && m#\S#;
          next if m/^\*Mnemonic/;
          if (m/^\*(\w+):\s?(.*)$/)
          { $rpt .= "$buf\n\n" if length($buf);
            $buf = exists($tb_det{$1}) ? $tb_det{$1}.$2 : $2;
          }
          elsif (m/^(\s+\-\s)(.*)$/)
          { $rpt .= "$buf\n\n" if length($buf);
            $buf = $tb_det{'_B_'}.$2;
            $lgt = length($1);
          }
          elsif ($lgt && m/^(\s+)(.*)$/ && length($1) < $lgt)
          { $rpt .= "$buf\n\n" if length($buf);
            $buf = $tb_det{'_P_'}.$2;
            $lgt = undef;
          }
          else
          { s/^\s*/ /;
            $buf .= $_;
          }
        }
        $rpt .= "$buf\n\n" if length($buf);
        last;
      }
    }
    close(ERR);
  }

  # Return the explanation report
  $rpt;
}

=head1 TEXT METHODS

=head2 S<$h-E<gt>wrap_string($pre,$txt[,$nxt])>

This method wraps a string. The string is wrapped according to the screen
width. The prefix is added on each screen line. Non space characters in the
prefix are replaced by spaces on continuous lines. The last argument indicates
the number of line feeds to add at the end of the string (1 by default).

It supports the C<\nnn> and C<\Oxnn> character encoding in both prefix and
text.

=cut

sub wrap_string
{ my ($slf, $pre, $txt, $nxt) = @_;
  my ($buf, $cnt, $col, $lgt, $str, @lin);

  $buf = '';
  $pre =~ s/\001//;
  $pre =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
  $col = $slf->{'_col'} - length($pre);
  $cnt = (@lin = split(/\n|\\012/, $txt));
  $nxt = 1 unless defined($nxt);
  foreach my $lin (@lin)
  { --$cnt;
    $str = '';
    $lgt = $col;
    $lin =~ s/[\r\s]+$//;
    foreach my $wrd (split(/\s+/, $lin))
    { $wrd =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
      $lgt += length($wrd) + 1;
      if ($lgt > $col)
      { if (length($str))
        { $buf .= $pre.$str."\n";
          $pre =~ s/\S/ /g;
        }
        $lgt = length($wrd);
        $str = $wrd;
      }
      else
      { $str .= ' ';
        $str .= $wrd;
      }
    }
    if (length($str))
    { $str .= "\n" if $cnt || $nxt > 0;
      $buf .= $pre.$str;
      $pre =~ s/\S/ /g;
    }
    elsif ($cnt || $nxt > 0)
    { $buf .= "\n";
    }
  }
  $buf .= "\n" x $nxt if --$nxt > 0;
  $buf;
}

# --- Internal methods --------------------------------------------------------

# Remove string formating
sub _clr_string
{ my ($str) = @_;

  $str =~ s#``(.*?)``#$1#g;
  $str =~ s#~~(.*?)~~#$1#g;
  $str =~ s#\*\*(.*?)\*\*#$1#g;
  $str =~ s#\!\!(\w+):(.*?)\!(.*?)\!\!#$3#g;
  $str;
}

# Format a paragraph in columns
sub _fmt_columns
{ my ($slf, $ifh, $sep) = @_;
  my ($buf, $cnt, $col, $lgt, $lin, $max, $pre, $txt, @tbl);

  $buf = '';
  $cnt = $max = 0;
  $sep = 0 unless defined($sep);
  while (defined($lin = $ifh->getline))
  { last if $lin =~ m/^$/;
    push(@tbl, $lin);
    $lin =~ s/\001//;
    $lin =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
    $max = $lgt if ($lgt = length($lin)) > $max;
    ++$cnt;
  }
  if ($max && ($col = int($slf->{'_col'} / ($max + $sep))))
  { for (; $cnt % $col ; ++$cnt)
    { push(@tbl, '');
    }
    $lgt = $cnt / $col;
  }
  if ($col > 1)
  { $sep = ' 'x$sep;
    for (my $row = 0 ; $row < $lgt ; ++$row)
    { for (my $off = $row ;  $off < $cnt ; $off += $lgt)
      { $txt = $tbl[$off];
        $txt =~ s/\001//;
        $txt =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
        $buf .= $sep;
        $buf .= sprintf('%-*s', $max, $txt);
      }
      $buf .= "\n";
    }
  }
  else
  { foreach $lin (@tbl)
    { ($pre, $txt) = split(/\001/, $lin, 2);
      $buf .= defined($txt)
        ? wrap_string($slf, $pre, $txt, 1)
        : wrap_string($slf, '',   $pre, 1);
    }
  }
  $buf;
}

# Read a paragraph
sub _read_para
{ local $/ = '';  # Treat multiple empty lines as a single empty line
  _clr_string(shift->getline);
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the display control
sub _begin_display
{ my ($pkg) = @_;

  $pkg->define('$[DSP]', $pkg->get_agent->get_display);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Handle::Data|RDA::Handle::Data>,
L<RDA::Handle::Memory|RDA::Handle::Memory>
L<RDA::Object|RDA::Object>,
L<RDA::Object::Pod|RDA::Object::Pod>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
