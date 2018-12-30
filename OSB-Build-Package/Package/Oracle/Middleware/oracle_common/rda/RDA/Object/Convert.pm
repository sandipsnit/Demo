# Convert.pm: Class Used for Managing XML Conversions

package RDA::Object::Convert;

# $Id: Convert.pm,v 2.15 2012/04/25 06:43:12 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Convert.pm,v 2.15 2012/04/25 06:43:12 mschenke Exp $
#
# Change History
# 20120422  MSC  Apply agent changes.

=head1 NAME

RDA::Object::Convert - Class Used for Managing XML Conversions

=head1 SYNOPSIS

require RDA::Object::Convert;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Convert> class are used to manage the XML
conversions. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::File;
  use RDA::Archive::Rda;
  use RDA::Convert;
  use RDA::Object;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
  use RDA::Object::Sgml;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.15 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  beg => \&_begin_convert,
  dep => [qw(RDA::Object::Output)],
  glb => ['$[CNV]'],
  inc => [qw(RDA::Object)],
  met => {
    'convert'    => {ret => 0},
    'gen_file'   => {ret => 0},
    'gen_group'  => {ret => 0},
    'get_groups' => {ret => 1},
    'get_title'  => {ret => 0},
    },
  );

# Define the global private constants
my $CMD = '%COL\d+%|%ENDCOL%|%ENDLIST%|%ENDTBL%|%ENDSEQ%|%LIST%|%TBL%|%SEQ%';
my $LGT = 128;
my $SIG =
  qr/^<!--\s*Module:(\S+)\s+Version:(\S+)\s+Report:(\S+)\s+OS:(\S+)\s+-->$/;
my $TBL = {'*' => 'sdp_table'};

my $RPT_NXT = ".N1\n";
my $RPT_SUB = "    \001  ";
my $RPT_TXT = "    ";

# Define the global private variables
my %tb_beg = (
  '*' => "<sdp_list",
  '1' => "<sdp_seq type='1'",
  'A' => "<sdp_seq type='A'",
  'a' => "<sdp_seq type='a'",
  'I' => "<sdp_seq type='I'",
  'i' => "<sdp_seq type='i'",
  );
my %tb_cnv = (
  C => \&_cnv_col,
  F => \&_cnv_text,
  L => \&_cnv_list,
  S => \&_cnv_seq,
  T => \&_cnv_tbl,
  );
my %tb_end = (
  '*' => '</sdp_list>',
  '1' => '</sdp_seq>',
  'A' => '</sdp_seq>',
  'a' => '</sdp_seq>',
  'I' => '</sdp_seq>',
  'i' => '</sdp_seq>',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Convert-E<gt>new($out)>

The object constructor. It takes the reporting control reference as an
argument.

C<RDA::Object::Convert> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_abr'> > Current abbreviation

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_cas'> > Indicates a case-sensitive context

=item S<    B<'_cat'> > Archive catalog

=item S<    B<'_cfg'> > Reference to the RDA software configuration object

=item S<    B<'_cnt'> > Number of converted files

=item S<    B<'_cnv'> > Reference to the conversion control object

=item S<    B<'_cpm'> > Code page mapping

=item S<    B<'_def'> > Group definitions

=item S<    B<'_dsp'> > Reference to the display control object

=item S<    B<'_end'> > End tag

=item S<    B<'_flt'> > Current filter

=item S<    B<'_gen'> > Generation function

=item S<    B<'_grp'> > Report group

=item S<    B<'_out'> > Reference to the output control object

=item S<    B<'_rpt'> > Report directory name

=item S<    B<'_sel'> > Selection function

=item S<    B<'_tbl'> > Table end tag

=item S<    B<'_tid'> > Table identifier hash

=item S<    B<'_txt'> > Text array

=item S<    B<'_ver'> > Software release/version

=item S<    B<'_vrb'> > Verbose indicator

=item S<    B<'_zip'> > Report archive path

=back

Internal keys are prefixed by an underscore.

=head2 S<$h = RDA::Object::Convert-E<gt>new($dir)>

Alternate object constructor that can only be used to check the XML conversion
group definitions. It takes the data directory as an argument.

=cut

sub new
{ my ($cls, $out) = @_;
  my ($agt, $cfg, $pth, $slf, $zip);

  # Create a minimal object for checking the definition file
  return bless {_dir => $out}, ref($cls) || $cls
    unless ref($out);

  # Create the conversion control object
  $agt = $out->get_info('agt');
  $cfg = $agt->get_config;
  $slf = bless {
    _agt => $agt,
    _cas => $out->get_info('cas'),
    _cnv => RDA::Convert->new($agt, $cfg),
    _cfg => $cfg,
    _dir => $cfg->get_group('D_RDA_DATA'),
    _dsp => $agt->get_display,
    _grp => $out->get_info('grp'),
    _out => $out,
    _rpt => $out->get_info('dir'),
    _ver => $out->get_info('rel'),
    }, ref($cls) || $cls;

  # Detect a zip file specification
  if (defined($pth = $agt->get_info('zip')))
  { $pth = $cfg->get_file('D_CWD', $pth)
      unless $cfg->is_absolute($pth = $cfg->cat_file($pth));

    # Create the archive object and its catalog
    $slf->{'_zip'} = $zip = RDA::Archive::Rda->new($pth, 1);
    $slf->{'_cat'} = {};
    $zip->scan(\&_scan, $slf);
  }

  # Return the object reference
  $slf;
}

sub _scan
{ my ($nam, $hdr, $slf) = @_;

  $slf->{'_cat'}->{$nam} =
    [$hdr->get_signature, $hdr->get_position, $hdr->get_info('mod')]
    if $nam =~ s/^mrc[\/\\]// || !exists($slf->{'_cat'}->{$nam});
  0;
}

=head2 S<$h-E<gt>convert($file)>

This method converts formatting specifications in a XML file. It returns the
result file.

=cut

sub convert
{ my ($slf, $src) = @_;
  my ($dst, $fil, $hdr,$ifh, $ofh);

  # Determine the output file name
  $dst = $slf->{'_cas'} ? $src : lc($src);
  $dst =~ s/(\.txt)?$/.xml/i;

  # Generate the XML file
  $slf->{'_gen'} = \&_gen_single;
  $slf->{'_vrb'} = 0;
  if (exists($slf->{'_cat'}))
  { die "RDA-01234: Cannot extract the report '$src'\n"
      unless (exists($slf->{'_cat'}->{$fil = $src}) ||
              exists($slf->{'_cat'}->{$fil = lc($src)}))
      && ($hdr = $slf->{'_zip'}->find(@{$slf->{'_cat'}->{$fil}}))
      && ($ifh = $hdr->get_handle);
  }
  else
  { $ifh = IO::File->new;
    $ifh->open("<$src")
      or die "RDA-01221: Cannot open the report '$src':\n $!\n";
  }
  $ofh = IO::File->new;
  $ofh->open($dst, $CREATE, $FIL_PERMS)
    or die "RDA-01223: Cannot create the result file '$dst':\n $!\n";
  binmode($ifh);
  binmode($ofh);
  $slf->_gen_xml($ofh, $ifh,
    {file => basename($src), group => $slf->{'_grp'}, os => $^O});
  $ifh->close;
  $ofh->close;

  # Return the result file
  $dst;
}

=head2 S<$h-E<gt>delete>

This method deletes the library object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>gen_file($force,$verbose[,$file,...])>

This method transforms formatting specifications in a XML file. You can
specify the reports by its name or by its file name. It returns the number of
converted files.

=cut

sub gen_file
{ my ($slf, $flg, $vrb, @fil) = @_;
  my ($dir, $dst, $fil, $ifh, $hdr, $nam, $ofh, $pre, @inf, @tbl);

  # Get the context information
  $dir = $slf->{'_rpt'};
  $pre = $slf->{'_grp'};
  @inf = (group => $pre, os => $^O);
  $pre .= '_';
  $slf->{'_cnt'} = 0;
  $slf->{'_gen'} = \&_gen_single;
  $slf->{'_vrb'} = $vrb;

  # Determine which files to convert
  if (@fil)
  { @tbl = map {($_ =~ m/\.txt$/i) ? $_ : "$pre$_.txt"} @fil;
  }
  else
  { @tbl = $slf->get_reports($pre,
      $flg                   ? \&_all_report :
      exists($slf->{'_cat'}) ? \&_chk_archive :
                               \&_chk_report);
  }

  # Convert files
  $ifh = IO::File->new;
  $ofh = IO::File->new;
  foreach my $src (@tbl)
  { # Determine the output file name
    $dst = $slf->{'_cas'} ? $src : lc($src);
    $dst =~ s/\.txt$/.xml/i;

    # Generate the XML file
    if (exists($slf->{'_cat'}))
    { die "RDA-01234: Cannot extract the report '$src'\n"
        unless (exists($slf->{'_cat'}->{$fil = $src}) ||
                exists($slf->{'_cat'}->{$fil = lc($src)}))
        && ($hdr = $slf->{'_zip'}->find(@{$slf->{'_cat'}->{$fil}}))
        && ($ifh = $hdr->get_handle);
      $ofh->open(RDA::Object::Rda->cat_file($dir, $dst), $CREATE, $FIL_PERMS)
        or die "RDA-01223: Cannot create the result file '$dst':\n $!\n";
    }
    elsif ($ifh->open('<'.RDA::Object::Rda->cat_file($dir, 'mrc', $src)))
    { $ofh->open(RDA::Object::Rda->cat_file($dir, 'mrc', $dst),
        $CREATE, $FIL_PERMS)
        or die "RDA-01223: Cannot create the result file '$dst':\n $!\n";
    }
    elsif ($ifh->open('<'.RDA::Object::Rda->cat_file($dir, $src)))
    { $ofh->open(RDA::Object::Rda->cat_file($dir, $dst), $CREATE, $FIL_PERMS)
        or die "RDA-01223: Cannot create the result file '$dst':\n $!\n";
    }
    else
    { die "RDA-01221: Cannot open the report '$src':\n $!\n";
    }
    binmode($ifh);
    binmode($ofh);
    $slf->_gen_xml($ofh, $ifh, {file => $src, @inf});
    $ifh->close;
    $ofh->close;
  }

  # Indicate the number of converted files
  $slf->{'_cnt'}
}

=head2 S<$h-E<gt>gen_group($group,$output,$verbose[,%attr])>

This method transforms formatting specifications for all files included in the
specified conversion group in a XML file. It returns the number of converted
files.

=cut

sub gen_group
{ my ($slf, $nam, $tgt, $vrb, %tbl) = @_;
  my ($cnt, $def, $dir, $hdr, $ifh, $ofh, $pat, $pre, $src, @inf);

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_def'});

  # Get the group definition
  die "RDA-01220: Unknown group '$nam'\n"
    unless exists($slf->{'_def'}->{$nam});
  $slf->{'_flt'} = $def = $slf->{'_def'}->{$nam};

  # Get the context information
  $dir = $slf->{'_rpt'};
  $pre = $slf->{'_grp'};
  @inf = (group => $pre, os => $^O);
  $pre .= '_';
  $slf->{'_abr'} = '';
  $slf->{'_cnt'} = 0;
  $slf->{'_gen'} = \&_gen_group;
  $slf->{'_vrb'} = $vrb;

  # Prepare the filter
  $pat = exists($def->{'*'})
    ? join('|', keys(%{$def->{'*'}}))
    : '[A-Z][^_]*';
  $slf->{'_sel'} = qr/^(mrc[\/\\])?$pre($pat)\_(.*)/i;

  # Open the result file
  $tgt =~ s/\.xml$//;
  $ofh = IO::File->new;
  die "RDA-01223: Cannot create the result file '$tgt.xml':\n $!\n"
    unless $ofh->open("$tgt.xml", $CREATE, $FIL_PERMS);
  binmode($ofh);
  print {$ofh} "<?xml version='1.0' encoding='utf-8'?>\n<"
    .join(' ', 'sdp_bundle', "type='$nam'",
               map {$_."='".$tbl{$_}."'"} sort keys(%tbl)).">\n";

  # Convert files
  foreach my $fil ($slf->get_reports($pre, \&_sel_report))
  { if (exists($slf->{'_cat'}))
    { die "RDA-01234: Cannot extract the report '$fil'\n"
        unless exists($slf->{'_cat'}->{$src = $fil})
        && ($hdr = $slf->{'_zip'}->find(@{$slf->{'_cat'}->{$src}}))
        && ($ifh = $hdr->get_handle);
    }
    else
    { $ifh = IO::File->new;
      $ifh->open('<'.RDA::Object::Rda->cat_file($dir, 'mrc', $fil))
        or $ifh->open('<'.RDA::Object::Rda->cat_file($dir, $fil))
        or die "RDA-01221: Cannot open the report '$fil':\n $!\n";
    }
    binmode($ifh);
    $slf->_gen_xml($ofh, $ifh, {file  => $fil, @inf});
    $ifh->close;
  }

  # Close the result file
  print {$ofh} "</".$slf->{'_abr'}.">\n" if length($slf->{'_abr'});
  print {$ofh} "</sdp_bundle>\n";
  $ofh->close;

  # Indicate the number of converted files
  $slf->{'_cnt'}
}

=head2 S<$h-E<gt>get_groups>

This method returns the list of all defined conversion groups. It loads the
group definitions when not yet done.

=cut

sub get_groups
{ my ($slf) = @_;

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_def'});

  # Return the group list
  keys(%{$slf->{'_def'}});
}

=head2 S<$h-E<gt>get_title($name[,$default])>

This method returns the description of the specified group, or the default
value when not found.

=cut

sub get_title
{ my ($slf, $nam, $ttl) = @_;

  return $ttl unless $nam;

  my $cur = $slf->{'_def'}->{$nam};
  exists($cur->{"?$nam"}) ? $cur->{"?$nam"} :
  exists($cur->{"?"})     ? $cur->{"?"} :
  $ttl;
}

=head2 S<$h-E<gt>xref>

This method produces a cross-reference of conversion group definitions. When
you do not specify definitions as data, this command analyzes the default
definition file F<convert.cfg>.

=cut

sub xref
{ my ($slf, $flg) = @_;
  my ($buf, $def, $typ, $xrf);

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_def'});

  # Produce the cross-reference
  $xrf = {typ => {
    '(*)' => 'All related reports are included.',
    '(f)' => 'Related reports are filtered by regular expressions.',
    }};
  foreach my $nam (keys(%{$slf->{'_def'}}))
  { $def = $slf->{'_def'}->{$nam};
    if (exists($def->{'*'}))
    { $xrf->{'def'}->{$nam} = [];
      foreach my $abr (keys(%{$def->{'*'}}))
      { $xrf->{'abr'}->{$abr} = [] unless exists($xrf->{'abr'}->{$abr});
        $typ = 'f';
        foreach my $cnd (@{$def->{'*'}->{$abr}})
        { $typ = '*' unless ref($cnd);
        }
        push(@{$xrf->{'abr'}->{$abr}}, "$nam($typ)");
        push(@{$xrf->{'def'}->{$nam}}, "$abr($typ)");
        $xrf->{'use'}->{"($typ)"} = 1;
      }
    }
    else
    { $xrf->{'def'}->{$nam} = ['<all>'];
      $xrf->{'abr'}->{'<all>'} = [] unless exists($xrf->{'abr'}->{'*'});
      push(@{$xrf->{'abr'}->{'<all>'}}, "$nam(*)");
      $xrf->{'use'}->{'(*)'} = 1;
    }
  }
  if (exists($xrf->{'abr'}->{'<all>'}))
  { foreach my $abr (keys(%{$xrf->{'abr'}}))
    { next if $abr eq '<all>';
      push(@{$xrf->{'abr'}->{$abr}}, @{$xrf->{'abr'}->{'<all>'}});
    }
  }

  # Produce the cross-reference
  $buf = _dsp_name('Conversion Group Cross Reference').$RPT_NXT;
  $buf .= _xref($xrf->{'def'}, $xrf->{'def'}, 'Defined Groups:');
  $buf .= _xref($xrf->{'abr'}, $xrf->{'abr'}, 'Referenced Abbreviations:');
  $buf .= _xref($xrf->{'use'}, $xrf->{'typ'}, 'Notes:');
  $buf;
}

sub _dsp_name
{ my ($ttl) = @_;

  ".R '$ttl'\n"
}

sub _dsp_text
{ my ($pre, $txt, $nxt) = @_;

  $txt =~ s/\\n/\n\n.I '$pre'\n/g;
  ".I '$pre'\n$txt\n\n".($nxt ? ".N $nxt\n" : "");
}

sub _dsp_title
{ my ($ttl) = @_;

  ".T '$ttl'\n"
}

# Display a result set
sub _xref
{ my ($key, $val, $ttl, $typ) = @_;
  my ($buf, $lgt, $lnk, $max);

  # Determine the name length
  $max = 0;
  foreach my $nam (keys(%$key))
  { $max = $lgt if ($lgt = length($nam)) > $max;
  }
  return '' unless $max;

  # Display the table
  $buf = _dsp_title($ttl);
  if ($typ)
  { $max += 6 + length($typ);
  }
  else
  { $lgt = $max + 4;
  }
  foreach my $nam (sort keys(%$key))
  { if ($typ)
    { $lnk = "!!$typ:$nam!$nam!!";
      $lgt = $max + length($nam);
    }
    else
    { $lnk = "``$nam``";
    }
    $buf .= _dsp_text(sprintf("  \001%-*s  ", $lgt, $lnk), ref($val->{$nam})
      ? '``'.join('``, ``', sort @{$val->{$nam}}).'``'
      : $val->{$nam});
  }
  $buf.$RPT_NXT;
}

=head1 CONVERSION METHODS

=head2 S<$h-E<gt>get_reports($pre,$fct)>

This method retrieves all related reports that must be converted.

=cut

sub get_reports
{ my ($slf, $pre, $fct) = @_;
  my ($dir, $mrc, $pat, @tbl, %tbl);

  # Initialization
  $pat = qr/^$pre[A-Za-z]\w*(-\d+)?\.txt$/i;

  # Scan the directory for report files
  if (exists($slf->{'_cat'}))
  { @tbl = grep {$_ =~ $pat && &$fct($slf, $_)} keys(%{$slf->{'_cat'}});
  }
  elsif (-d ($mrc = RDA::Object::Rda->cat_dir($slf->{'_rpt'}, 'mrc')))
  { if (opendir(DIR, $slf->{'_rpt'}))
    { foreach my $fil (readdir(DIR))
      { $tbl{$fil} = 0 if $fil =~ $pat && &$fct($slf, $fil);
      }
    }
    if (opendir(DIR, $mrc))
    { foreach my $fil (readdir(DIR))
      { $tbl{$fil} = 1 if $fil =~ $pat
          && &$fct($slf, RDA::Object::Rda->cat_file('mrc', $fil));
      }
    }
    @tbl = keys(%tbl);
  }
  else
  { if (opendir(DIR, $slf->{'_rpt'}))
    { @tbl = grep {$_ =~ $pat && &$fct($slf, $_)} readdir(DIR);
      closedir(DIR);
    }
  }

  # Return the files found
  sort @tbl;
}

# Get all reports
sub _all_report
{ 1;
}

# Compare the modification time with archive
sub _chk_archive
{ my ($slf, $fil) = @_;
  my ($day, $hou, $min, $mon, $mt1, $mt2, $pth, $sec, $yea, @sta);

  if (defined($mt1 = $slf->{'_cat'}->{$fil}->[2]))
  { $sec = ($mt1 & 0x1F) << 1;
    $min = ($mt1 >> 5)  & 0x3F;
    $hou = ($mt1 >> 11) & 0x1F;
    $day = ($mt1 >> 16) & 0x1F;
    $mon = ($mt1 >> 21) & 0x0F;
    $yea = (($mt1 >> 25) & 0x7F) + 80;
    eval {
      require POSIX;
      $mt1 = POSIX::mktime($sec, $min, $hou, $day, $mon, $yea, 0, 0, -1);
      };
    $mt1 = undef if $@;
  }
  $pth = RDA::Object::Rda->cat_file($slf->{'_rpt'}, $fil);
  $pth =~ s/\.txt$/.xml/i;
  @sta = stat($pth);
  $mt2 = $sta[9];
  ($mt1 && $mt2 && $mt1 <= $mt2) ? 0 : 1;
}

# Compare the modification times
sub _chk_report
{ my ($slf, $fil) = @_;
  my ($mt1, $mt2, $pth, @sta);

  @sta = stat($pth = RDA::Object::Rda->cat_file($slf->{'_rpt'}, $fil));
  $mt1 = $sta[9];
  $pth =~ s/\.txt$/.xml/i;
  @sta = stat($pth);
  $mt2 = $sta[9];
  ($mt1 && $mt2 && $mt1 <= $mt2) ? 0 : 1;
}

# Select the reports
sub _sel_report
{ my ($slf, $fil) = @_;

  $fil =~ $slf->{'_sel'};
}

=head2 S<$h-E<gt>load([$file[,$flag]])>

This method loads the XML conversion group definitions from the specified file
or F<convert.cfg> by default. When the flag is set, it raises an exception when
encountering load errors.

=cut

sub load
{ my ($slf, $fil, $flg) = @_;
  my ($cas, $cur, $err, $ifh, $lin, $msg, $pos);

  # Select the group definition source
  if ($fil)
  { $fil = RDA::Object::Rda->cat_file($slf->{'_dir'}, $fil) unless -r $fil;
  }
  else
  { $fil = RDA::Object::Rda->cat_file($slf->{'_dir'}, 'convert.cfg')
  }
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    or die "RDA-01222: Cannot open the group definition file $fil:\n $!\n";

  # Load the conversion group definition
  $slf->{'_def'}->{'Default'} = {};
  $cas = $slf->{'_cas'};
  $pos = $err = 0;
  $lin = '';
  while (<$ifh>)
  { # Trim leading spaces
    s/^\s+//;
    s/[\r\n]+$//;
    $lin .= $_;

    # Join continuation line
    $pos++;
    next if $lin =~ s/\\$//;
    $lin =~ s/\s+$//;

    # Parse the line
    eval {
      if ($lin =~ s/^\*\s*=\s*//)
      { my ($flt, $key, @pat, @tbl);

        ($key, @pat) = split(/\//, $lin);
        die "RDA-01224: Bad abbreviation '$key'\n"
          unless $key =~ m/^[A-Z]\w*$/;

        # Get the filter list
        die "RDA-01228: Missing group specification\n" unless $cur;
        $cur->{'*'}->{$key} = []
          unless exists($cur->{'*'}) && exists($cur->{'*'}->{$key});
        $flt = $cur->{'*'}->{$key};

        # Load the filter item
        if (@pat)
        { foreach my $pat (@pat)
          { next unless $pat;
            die "RDA-01226: Bad pattern '$pat'\n" unless $pat =~ s/^([\-\+])//;
            push(@tbl, [$1, qr/$pat/i]);
          }
          push(@$flt, [@tbl]);
        }
        else
        { push(@$flt, '');
        }
      }
      elsif ($lin =~ s/^(\?\w*)\s*=\s*//)
      { my ($key, $val);

        $key = $1;
        if ($lin =~ s/^'([^']*)'// || $lin =~ s/^"([^"]*)"//)
        { $val = $1;
          $val =~ s/&\#34;/"/;
          $val =~ s/&\#39;/'/;
        }
        else
        { $val = $lin;
          $lin = '';
        }
        die "RDA-01227: Bad value\n" unless $lin =~ m/^\s*(#.*)?$/;
        die "RDA-01228: Missing group specification\n" unless $cur;
        $cur->{$key} = $val;
      }
      elsif ($lin =~ s/^\[([\w\|]+)\]$//)
      { $cur = {};
        foreach my $key (split(/\|/, $1))
        { $slf->{'_def'}->{$key} = $cur;
          $slf->{'_def'}->{lc($key)} = $cur unless $cas;
        }
      }
      elsif ($lin !~ m/^(#.*)?$/)
      { die "RDA-01225: Bad line\n";
      }
    };

    # Report an error
    if ($@)
    { $err++;
      $msg = $@;
      $msg =~ s/\n$//;
      $msg .= " near line $pos" if $pos;
      print "$msg\n";
    }

    # Prepare the next line
    $lin = '';
  }
  $ifh->close;

  # Terminate if errors are encountered
  die "RDA-01229: Error(s) in group definition file $fil\n" if $flg && $err;

  # Return the object reference
  $slf;
}

# --- Conversion routines -----------------------------------------------------

# Check if the file belongs to the group
sub _chk_group
{ my ($flt, $abr, $rpt) = @_;

  return 0 unless exists($flt->{'*'});
  if (exists($flt->{'*'}->{$abr}))
  { COND: foreach my $cnd (@{$flt->{'*'}->{$abr}})
    { if (ref($cnd))
      { foreach my $pat (@$cnd)
        { next COND unless $pat->[0] eq '-' xor $rpt =~ $pat->[1];
        }
      }
      return 0;
    }
  }
  1;
}

# Check cell content
sub _chk_cell
{ my ($str) = @_;

  $str =~ m/(\%(ENDCOL|ENDLIST|ENDSEQ|ENDTBL)\%|\[\[.*\]\]|\{\{.*\}\})/;
}

# Remove variables and other enhancements
sub _clr_var
{ my ($slf, $str) = @_;

  $str =~ s#&nbsp;# #g;
  $str =~ s#\%R:(\w+)\%#$1#g;
  $str =~ s#\%(BR|COL\d+|END(COL|LIST|SEQ|TBL)|HDR|LIST|NEXT|SEQ|TBL)\%# #g;
  $str =~ s#\%(BLUE|DATA|ENDCOLOR|ID(:\w+)*|RED)\%##g;
  $str =~ s#\%MRC\.\w+\%##g;
  $str =~ s#\%NULL\%#Null value#g;
  $str =~ s#\%VERSION\%#$slf->{'_ver'}#g;
  $str =~ s#\*\*(.*?)\*\*#$1#g;
  $str =~ s#\'\'(.*?)\'\'#$1#g;
  $str =~ s#\`\`(.*?)\`\`#$1#g;
  $str =~ s#\{\{[^\|\}]+?\}\}##g;
  $str =~ s#\{\{.+?\|(.*?)\}\}#[$2]#g;
  $str =~ s#\[\[([^\[\]]+)\]\[([^\[\]]+)\]\[(.+?)\]\]#$3#g;
  $str =~ s#\[\[([^\[\]]+)\]\[(.+?)\]\]#$2#g;
  $str =~ s#\s+# #g;
  RDA::Object::Sgml::convert($str);
}

# Convert a string to a valid attribute name
sub _cnv_attr
{ my ($slf, $str) = @_;

  $str =~ s/[<>'"]/_/g;
  $str = lc(_clr_var($slf, $str));
  $str =~ s/&\#(\d+|x[0-9a-f]+);?/_/g;
  $str =~ s/\W+/_/gs;
  $str =~ s/_+/_/g;
  $str =~ s/_$//;
  substr(($str =~ m/^_/)  ? "attr$str" :
         ($str =~ m/^\d/) ? "attr_$str" :
                            $str, 0, $LGT);
}

# Convert a column
sub _cnv_col
{ my ($str, $ctl) = @_;
  my ($tag);

  $str =~ s/\%NEXT\%/\%BR\%/g;
  $tag = ($str =~ s#\%ID(:(\w+))?(:\w+)*\%##g && $2)
    ? "<sdp_item id='$2'>"
    : "<sdp_item>";
  ($str =~ m/^\s*$/)
    ? $str
    : "<sdp_columns num='".$ctl->{'num'}."'>\n$tag"
      .join("</sdp_item>\n$tag",
            map {_rpl_ref($_)} split(/\%BR\%/, $str, -1))
      ."</sdp_item>\n</sdp_columns>";
}

# Convert a list
sub _cnv_list
{ my ($str) = @_;
  my ($tag);

  $tag = ($str =~ s#\%ID(:(\w+))?(:\w+)*\%##g && $2)
    ? "<sdp_item id='$2'>"
    : "<sdp_item>";
  ($str =~ m/^\s*$/)
    ? $str
    : "<sdp_list>\n$tag"
      .join("</sdp_item>\n$tag",
            map {_rpl_ref($_)} split(/\%NEXT\%/, $str, -1))
      ."</sdp_item>\n</sdp_list>";
}

# Convert a sequence
sub _cnv_seq
{ my ($str) = @_;
  my ($tag);

  $tag = ($str =~ s#\%ID(:(\w+))?(:\w+)*\%##g && $2)
    ? "<sdp_item id='$2'>"
    : "<sdp_item>";
  ($str =~ m/^\s*$/)
    ? $str
    : "<sdp_seq>\n$tag"
      .join("</sdp_item>\n$tag",
            map {_rpl_ref($_)} split(/\%NEXT\%/, $str, -1))
      ."</sdp_item>\n</sdp_seq>";
}

# Convert a table
sub _cnv_tbl
{ my ($str, $ctl) = @_;
  my ($buf, $cnt, $key, @hdr, @row);

  @hdr = split(/:/, $1) if $str =~ s/\%ID((:\w+)*)\%//;
  return '' unless $str =~ m/\S/ && (@row = split(/\%BR\%/, $str, -1));
  $buf = "<sdp_table>";
  foreach my $row (@row)
  { $buf .= "<sdp_cells>\n";
    $cnt = 0;
    foreach my $det (split(/\%NEXT\%/, $row, -1))
    { $buf .= (($key = $hdr[++$cnt]) ? "<sdp_cell id='$key'>" : "<sdp_cell>")
        ._rpl_ref($det)."</sdp_cell>\n";
    }
    $buf .= "</sdp_cells>";
  }
  $buf."</sdp_table>";
}

# Convert a text
sub _cnv_text
{ _rpl_ref(shift);
}

# Convert a tree
sub _cnv_tree
{ my ($ctl) = @_;

  foreach my $itm (@{$ctl->{'det'}})
  { $itm->{'txt'} = _cnv_tree($itm) unless $itm->{'typ'} eq 'F';
  }
  &{$tb_cnv{$ctl->{'typ'}}}(join('', map {$_->{'txt'}} @{$ctl->{'det'}}), $ctl);
}

# Convert a string to an attribute value
sub _cnv_value
{ my ($str) = @_;

  $str =~ s/(\&+)([^#]|\z)/('&#38;' x length($1)).$2/eg;
  $str =~ s/\"/&#34;/g;
  $str =~ s/\'/&#39;/g;
  $str =~ s/\</&#60;/g;
  $str =~ s/\>/&#62;/g;
  $str;
}

# Generate report tags for a conversion group
sub _gen_group
{ my ($slf, $dst, $ctx) = @_;

  if (ref($ctx))
  { my ($abr, $rpt);

    # Check if conditions are fulfilled
    return 1 unless $ctx->{'file'} =~ $slf->{'_sel'};
    $abr = $2;
    if (exists($ctx->{'report'}))
    { $rpt = $ctx->{'report'};
    }
    else
    { $rpt = $3;
      $rpt =~ s/\.txt$//i;
      return 1 if $abr =~ m/^(SC|S\d{3})[A-Z]\w*$/i && $rpt =~ m/^\d{2,}$/i;
    }
    return 1 if _chk_group($slf->{'_flt'}, $abr, $rpt);
    $slf->{'_dsp'}->dsp_data("\t\t- ".$ctx->{'file'}." ...\n", 0)
      if $slf->{'_vrb'};
    ++$slf->{'_cnt'};

    # Detect abbreviation transition
    if ($abr ne $slf->{'_abr'})
    { print {$dst} "</".$slf->{'_abr'}.">\n" unless $slf->{'_abr'} eq '';
      print {$dst} "<$abr>\n";
      $slf->{'_abr'} = $abr;
    }

    # Indicate the new report
    $rpt = "sdp_report_$rpt";
    $rpt =~ s/[_\W]+/_/g;
    print {$dst} "<".join(' ', $slf->{'_end'} = substr($rpt, 0, $LGT),
        map {$_."='".$ctx->{$_}."'"} sort keys(%$ctx)).">\n";
  }
  else
  { print {$dst} "</".$slf->{'_end'}.">\n";
  }
  0;
}

# Generate report tags for a single file
sub _gen_single
{ my ($slf, $dst, $ctx) = @_;
  my ($set);

  if (ref($ctx))
  { $slf->{'_dsp'}->dsp_data("\t\t- ".$ctx->{'file'}." ...\n", 0)
      if $slf->{'_vrb'};
    ++$slf->{'_cnt'};

    # Determine the page character set
    if (exists($ctx->{'codepage'}))
    { $set = $ctx->{'codepage'};
      unless (exists($slf->{'_cpm'}))
      { if (open(CPM, '<'.$slf->{'_cfg'}->get_file('D_RDA_DATA', 'cp.txt')))
        { while(<CPM>)
          { $slf->{'_cpm'}->{$1} = $2 if m/^(\d+)\s+(\S+)/;
          }
          close(CPM);
        }
      }
      $set = exists($slf->{'_cpm'}->{$set})
        ? $slf->{'_cpm'}->{$set}
        : 'utf-8';
    }
    else
    { $set = exists($ctx->{'charset'})
        ? $ctx->{'charset'}
        : 'utf-8';
    }

    # Initialize the report
    print {$dst} "<?xml version='1.0' encoding='$set'?>\n<sdp_report "
      .join(' ', map {$_."='".$ctx->{$_}."'"} sort keys(%$ctx)).">\n";
  }
  else
  { print {$dst} "</sdp_report>\n";
  }
  0;
}

# Generate the XML file
sub _gen_xml
{ my ($slf, $dst, $src, $ctx) = @_;
  my ($blk, $cel, $cnv, $eob, $hdr, $lin, $lst, $lvl, $max, $rec, $sum,
      $tbl, $tid, @lvl);

  # Identify the report and load the conversion plugins
  while (defined($lin = _get_line($src)))
  { if ($lin =~ $SIG)
    { ($ctx->{'module'}, $ctx->{'version'}, $ctx->{'report'}, $ctx->{'os'})
        = ($1, $2, $3, $4);
    }
    elsif ($lin =~ m/^<\?\s*(\w+):(\S*)\s*\?>$/)
    { $ctx->{lc($1)} = $2;
    }
    elsif ($lin !~ m/^<!--.*?-->$/)
    { last;
    }
  }
  ($cnv = $slf->{'_cnv'})->init($ctx, $src);

  # Treat the input file
  $blk = $hdr = $lvl = $rec = $tbl = $tid = 0;
  $cel = $TBL;
  $eob = '';
  $slf->{'_tid'} = {};
  $slf->{'_txt'} = [];
  return if &{$slf->{'_gen'}}($slf, $dst, $ctx);
  for (; defined($lin) ; $lin = _get_line($src))
  { # Detect a context change
    if ($lvl)
    { # Close an open list
      unless ($lin =~ m/^( {3,})[\*1AaIi]/ && (length($1) % 3) == 0)
      { my ($typ);
        while ($typ = pop(@lvl))
        { print {$dst} $tb_end{$typ}."\n";
        }
        $lvl = 0;
      }
    }
    elsif ($rec)
    { # Close an open table
      unless ($lin =~ m/^\|[^\|].*\|$/)
      { print {$dst} "</".$slf->{'_tbl'}.">\n";
        $rec = 0;
        $tid = $max;
      }
    }

    # Treat a line
    if ($blk)
    { if ($lin eq $eob)
      { print {$dst} "]]></sdp_block>\n" if defined(&$blk($slf, ''));
        $blk = 0;
      }
      elsif (defined($lin = &$blk($slf, $lin)))
      { print {$dst} "$lin\n";
      }
    }
    elsif ($lin =~ m/^\|<([^>]*)>\|$/)
    { _prt_text($slf, $dst);
      unless ($rec)
      { ++$tbl;
        $sum = _cnv_value(_clr_var($slf, $1));
        $cel = $TBL unless ref($cel = $cnv->search('T', $sum)) eq 'HASH';
        $slf->{'_tbl'} = exists($cel->{'*'}) ? $cel->{'*'} : 'sdp_table';
        print {$dst} "<".$slf->{'_tbl'}." summary='$sum'>\n";
        $sum = undef;
        $lst = $max = $tid + 1;
        ++$rec;
      }
    }
    elsif ($lin =~ s/^\|([^\|].*\|)$/$1/)
    { my ($col, $cur, $dir, $hid, $new, $txt, $typ, @tbl, %tbl);
      _prt_text($slf, $dst);
      unless ($rec)
      { ++$tbl;
        $sum = "Table $tbl" unless defined($sum);
        $cel = $TBL unless ref($cel = $cnv->search('T', $sum)) eq 'HASH';
        $slf->{'_tbl'} = exists($cel->{'*'}) ? $cel->{'*'} : 'sdp_table';
        print {$dst} "<".$slf->{'_tbl'}." summary='$sum'>\n";
        $sum = undef;
        $lst = $max = $tid + 1;
      }
      $new = $tid + 1;
      if (exists($cel->{'-'}))
      { print {$dst} $txt if length($txt = &{$cel->{'-'}}($cnv, $lin));
      }
      else
      { $col = $dir = $typ = 0;
        while ($lin =~ s/([^\|]+)(\|{1,})//)
        { $new = 0 if ($cur = length($2)) > 1;
          $txt = $1;
          $txt =~ s/^\s+//;
          $txt =~ s/\s+$//;
          if ($txt =~ s/^\*(.+)\*$/$1/)
          { ++$tid;
            $max = $tid if $tid > $max;
            $slf->{'_tid'}->{$tid} = $txt
              if length($txt = _cnv_attr($slf, $txt));
            $dir = 1;
          }
          else
          { $hid = ($dir) ? $tid : $lst + $col;
            $max = $tid = $hid if $hid > $max;
            $slf->{'_tid'}->{$hid} = "attr_$hid"
              unless exists($slf->{'_tid'}->{$hid});
            if (exists($cel->{$slf->{'_tid'}->{$hid}}))
            { $typ = -1;
              $tbl{$hid} = &{$cel->{$slf->{'_tid'}->{$hid}}}($cnv, $txt);
            }
            else
            { $typ = _chk_cell($txt) ? -1 : 1 unless $typ < 0;
              $tbl{$hid} = _rpl_var($slf, $txt);
            }
            $dir = $new = 0;
          }
          $col += $cur;
        }
        $lst = $new if $new;
        if ($typ < 0)
        { print {$dst} "<sdp_cells>\n";
          foreach my $id (sort {$a <=> $b} keys(%tbl))
          { print {$dst} "<sdp_cell id='".$slf->{'_tid'}->{$id}."'>".$tbl{$id}
              ."</sdp_cell>\n";
          }
          print {$dst} "</sdp_cells>\n";
        }
        elsif ($typ > 0)
        { print {$dst} join(' ', "<sdp_row",
            map {$slf->{'_tid'}->{$_}."='"._cnv_value($tbl{$_})."'"}
            sort {$a <=> $b} keys(%tbl))."/>\n";
        }
      }
      ++$rec;
    }
    elsif ($lin =~ m/^$/)
    { _prt_text($slf, $dst);
    }
    elsif ($lin =~ m/^-{3,}$/)
    { _prt_text($slf, $dst);
      print {$dst} "<sdp_hr/>", "\n";
    }
    elsif ($lin =~ m/^-{3}(\+{1,6})(!!)?\s*(.*)$/)
    { my ($cur, $toc);
      $cur = length($1);
      $toc = defined($2) ? 0 : 1;
      $sum = _cnv_value(_clr_var($slf, $3));
      _prt_text($slf, $dst);
      for (; $cur <= $hdr ; --$hdr)
      { print {$dst} "</sdp_section>\n";
      }
      print {$dst} "<sdp_section level='$hdr'>\n" while ++$hdr < $cur;
      print {$dst} "<sdp_section level='$cur' title='$sum' toc='$toc'>\n";
    }
    elsif ($lin =~ m/^-{3}(\#{1,6})\s*(.*)$/)
    { _prt_text($slf, $dst);
      print {$dst} "<sdp_subtitle level='".length($1)."' text='"
        ._cnv_value(_clr_var($slf, $2))."'/>\n";
    }
    elsif ($lin =~ m/^<verbatim(:(\w+))?>$/)
    { unless ($cnv->convert($dst, $src, defined($sum) ? $sum : '-', $2))
      { my $typ = $2 || 'verbatim';
        $blk = \&_rpl_enc;
        $eob = '</verbatim>';
        _prt_text($slf, $dst);
        print {$dst} "<sdp_block type='$typ'><![CDATA[";
      }
    }
    elsif ($lin =~ m/^<pre>$/)
    { $blk = \&_rpl_none;
      $eob = '</pre>';
      _prt_text($slf, $dst);
      print {$dst} "<sdp_block type='pre'><![CDATA[";
    }
    elsif ($lin =~ m/^<code>$/)
    { $blk = \&_rpl_var;
      $eob = '</code>';
      _prt_text($slf, $dst);
      print {$dst} "<sdp_block type='code'><![CDATA[";
    }
    elsif ($lin =~ m/^<comment>$/)
    { $blk = \&_skp_line;
      $eob = '</comment>';
      _prt_text($slf, $dst);
    }
    elsif ($lin =~ m/^( {3,})([\*1AaIi])\s*(.*)$/ && (length($1) % 3) == 0)
    { my ($cur);
      $cur = int(length($1) / 3);
      _prt_text($slf, $dst);
      while ($lvl > $cur || ($lvl == $cur && $2 ne $lvl[$#lvl]))
      { print {$dst} $tb_end{pop(@lvl)}."\n";
        --$lvl;
      }
      while ($lvl < $cur)
      { print {$dst} $tb_beg{$2}." level='".++$lvl."'>\n";
        push(@lvl, $2);
      }
      print {$dst} "<sdp_item>"._rpl_var($slf, $3)."</sdp_item>\n";
    }
    elsif ($lin =~ m/^#(\w+)(\s(-{3}(#{1,6})\s)?(.*))?$/)
    { my ($txt);
      _prt_text($slf, $dst);
      if ($3)
      { print {$dst} "<sdp_subtitle level='".length($4)."' text='"
        ._cnv_value(_clr_var($slf, $5))."'/>\n";
      }
      elsif ($4 && length($txt =_rpl_var($slf, $5)))
      { push(@{$slf->{'_txt'}}, $txt);
      }
    }
    elsif ($lin =~ m/^\%DATA\%$/)
    {
    }
    elsif ($lin =~ m/^\%TOC[\d\-]*\%$/)
    { _prt_text($slf, $dst);
    }
    elsif ($lin =~ m/^\%INCLUDE\{"([^"]+)"\}\%$/)
    { _prt_text($slf, $dst);
      if (open(INC, "<$1"))
      { while (<INC>)
        { print {$dst} _rpl_var($slf, $_);
        }
        close(INC);
      }
    }
    elsif ($lin =~ m/^\%PRE\{"([^"]+)"\}\%$/)
    { _prt_text($slf, $dst);
      if (open(INC, "<$1"))
      { print {$dst} "<sdp_block type='pre'><![CDATA[";
        while (<INC>)
        { print {$dst} _rpl_none($slf, $_);
        }
        print {$dst} "]]></sdp_block>\n";
        close(INC);
      }
    }
    elsif ($lin =~ m/^\%VERBATIM\{"([^"]+)"\}\%$/)
    { my ($ifh);
      _prt_text($slf, $dst);
      $ifh = IO::File->new;
      if ($ifh->open("<$1"))
      { unless ($cnv->convert($dst, $ifh, defined($sum) ? $sum : '-'))
        { print {$dst} "<sdp_block type='verbatim'><![CDATA[";
          while (<$ifh>)
          { print {$dst} _rpl_enc($slf, $_);
          }
          print {$dst} "]]></sdp_block>\n";
        }
        $ifh->close;
      }
    }
    elsif ($lin =~ m/^<\?\s*(\w+):(\S*)\s*\?>$/)
    { $ctx->{lc($1)} = $2;
    }
    elsif ($lin !~ m/^<\?.*\?>$/)
    { my ($txt);
      push(@{$slf->{'_txt'}}, $txt) if length($txt = _rpl_var($slf, $lin));
    }
    $lin = '';
  }

  # Terminate and close the XML file
  _prt_text($slf, $dst);
  if ($lvl) # Open list
  { my ($typ);
    while ($typ = pop(@lvl))
    { print {$dst} $tb_end{$typ}."\n";
    }
  }
  elsif ($rec) # Open table
  { print {$dst} "</".$slf->{'_tbl'}.">\n";
  }
  elsif ($blk) # Open block
  { print {$dst} "]]></sdp_block>\n" if defined(&$blk($slf, ''));
  }
  print {$dst} "</sdp_section>\n" while $hdr--;
  &{$slf->{'_gen'}}($slf, $dst);
}

# Get an input line
sub _get_line
{ my ($ifh) = @_;
  my ($buf, $lin);

  return undef unless defined($buf = $ifh->getline);
  $buf =~ s/[\r\n]*$//;
  while ($buf =~ s/\\$//)
  { last unless defined($lin = $ifh->getline);
    $lin =~ s/[\r\n]*$//;
    $buf .= $lin unless $lin =~ m/^\000*$/;
  }
  $buf =~ s/\s+$//;
  $buf;
}

# Parse a string
sub _prs_tree
{ my ($tbl, $ctl) = @_;
  my ($itm);

  while (defined($itm = shift(@$tbl)))
  { next if $itm eq '';
    return $ctl if exists($ctl->{'end'}) && $itm eq $ctl->{'end'};
    if ($itm =~ m/^\%COL(\d+)\%$/)
    { push(@{$ctl->{'det'}}, _prs_tree($tbl,
        {typ => 'C', det => [], end => '%ENDCOL%', num => $1}));
    }
    elsif ($itm eq '%LIST%')
    { push(@{$ctl->{'det'}}, _prs_tree($tbl,
        {typ => 'L', det => [], end => '%ENDLIST%'}));
    }
    elsif ($itm eq '%SEQ%')
    { push(@{$ctl->{'det'}}, _prs_tree($tbl,
        {typ => 'S', det => [], end => '%ENDSEQ%'}));
    }
    elsif ($itm eq '%TBL%')
    { push(@{$ctl->{'det'}}, _prs_tree($tbl,
        {typ => 'T', det => [], end => '%ENDTBL%'}));
    }
    elsif ($itm !~ m/^\%END(COL|LIST|SEQ|TBL)\%$/)
    { push(@{$ctl->{'det'}}, {typ => 'F', txt => $itm});
    }
  }
  $ctl;
}

# Print stored text
sub _prt_text
{ my ($slf, $dst) = @_;
  my ($str);

  if (@{$slf->{'_txt'}})
  { print {$dst} "<sdp_para>".join(' ', @{$slf->{'_txt'}})."</sdp_para>\n";
    $slf->{'_txt'} = [];
  }
}

# Encode some characters
sub _rpl_enc
{ my ($slf, $str) = @_;

  $str =~ s/[\000-\010\013-\014\016-\037]//g;
  $str =~ s/</&#60;/g;
  $str =~ s/>/&#62;/g;
  $str =~ s/\%R:(\w+)\%/[$1]/g;
  RDA::Object::Sgml::convert($str);
}

# Replace multi-run collection variales
sub _rpl_mrc
{ my ($slf, $mod) = @_;

  $slf->{'_agt'}->get_setting("$mod\_MRC", 0)
    ? $slf->{'_out'}->get_sub('M').'/'
    : '';
}

# No replacement
sub _rpl_none
{ my ($slf, $str) = @_;

  $str =~ s/[\000-\010\013-\014\016-\037]//g;
  $str =~ s/\%R:(\w+)\%/[$1]/g;
  RDA::Object::Sgml::convert($str);
}

# Replace references
sub _rpl_ref
{ my ($str) = @_;
  my ($blk);

  $blk = '([^\[\]]+)';
  $str =~ s#\{\{([^\|\}]+?)\}\}#<sdp_img src='$1'/>#g;
  $str =~ s#\{\{(.+?)\|(.*?)\}\}#<sdp_img src='$1' alt='$2'/>#g;
  $str =~ s#\[\[\#$blk\]\[$blk\]\[(.+?)\]\]#$3#g;
  $str =~ s#\[\[\#$blk\]\[(.+?)\]\]#$2#g;
  $str =~
    s#\[\[$blk\]\[$blk\]\[(.+?)\]\]#<sdp_a href='$1' target='$2'>$3</sdp_a>#g;
  $str =~ s#\[\[$blk\]\[(.+?)\]\]#<sdp_a href='$1'>$2</sdp_a>#g;
  $str =~ s/\%BR\%/ /g;
  $str =~ s#\%ID(:\w+)*\%##g;
  $str =~ s/[ \f\t]+/ /g;
  $str =~ s/^\s//g;
  $str =~ s/\s$//g;
  RDA::Object::Sgml::convert($str);
}

# Replace variables
sub _rpl_var
{ my ($slf, $str) = @_;
  my (@tbl);

  # Resolve simple variables and references
  $str =~ s/[\000-\010\013-\014\016-\037]//g;
  $str =~ s#&nbsp;# #g;
  $str =~ s#\%R:(\w+)\%#[$1]#g;
  $str =~ s#\%(BLUE|DATA|ENDCOLOR|HDR|RED)\%##g;
  $str =~ s#\%MRC:(\w+)\%#_rpl_mrc($slf, $1)#eg;
  $str =~ s#\%NULL\%#Null value#g;
  $str =~ s#\%VERSION\%#$slf->{'_ver'}#g;
  $str =~ s#\*\*(.*?)\*\*#$1#g;
  $str =~ s#\'\'(.*?)\'\'#$1#g;
  $str =~ s#\`\`(.*?)\`\`#$1#g;
  $str =~ s#\[\[\#Top\]\[Back to top\]\]##g;

  # Parse the string and convert the resulting tree
  @tbl = split(/($CMD)/, $str);
  _cnv_tree(_prs_tree(\@tbl, {typ => 'F', det => []}));
}

# Skip a line
sub _skp_line
{ undef;
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the conversion control
sub _begin_convert
{ my ($pkg) = @_;

  $pkg->define('$[CNV]', $pkg->get_agent->get_convert);
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Archive::Rda|RDA::Archive::Rda>,
L<RDA::Archive::Header|RDA::Archive::Header>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Sgml|RDA::Object::Sgml>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
