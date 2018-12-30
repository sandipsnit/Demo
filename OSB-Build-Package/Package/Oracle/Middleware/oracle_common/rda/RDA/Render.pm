# Render.pm: Class Used for Objects to Format Collected Information

package RDA::Render;

# $Id: Render.pm,v 2.25 2012/09/16 16:07:51 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Render.pm,v 2.25 2012/09/16 16:07:51 mschenke Exp $
#
# Change History
# 20120916  MSC  Improve the documentation.

=head1 NAME

RDA::Render - Class Used for Objects to Format Collected Information

=head1 SYNOPSIS

require RDA::Render;

=head1 DESCRIPTION

The objects of the C<RDA::Render> class are used to format collected
information based on formatting specifications.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Copy;
  use IO::File;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.25 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $CMD = '%COL\d+%|%ENDCOL%|%ENDLIST%|%ENDTBL%|%ENDSEQ%|%LIST%|%TBL%|%SEQ%';
my $NBD = " style='border-style:none;padding:0px;'";
my $NBT = " style='border-style:none;padding:0px 0px 0px 4px;'";
my $SEP = "<td$NBD>&nbsp;&nbsp;&nbsp;&nbsp;</td>";

my %tb_beg = (
  '*' => "<ul>",
  '1' => "<ol type='1'>",
  'A' => "<ol type='A'>",
  'a' => "<ol type='a'>",
  'I' => "<ol type='I'>",
  'i' => "<ol type='i'>",
  );
my %tb_cnv = (
  C => \&_cnv_col,
  F => \&_cnv_text,
  L => \&_cnv_list,
  S => \&_cnv_seq,
  T => \&_cnv_tbl,
  );
my %tb_end = (
  '*' => '</ul>',
  '1' => '</ol>',
  'A' => '</ol>',
  'a' => '</ol>',
  'I' => '</ol>',
  'i' => '</ol>',
  );
my @tb_jus = (" align='left'",
              " align='right'",
              " align='left'",
              " align='center'");
my %tb_thm = (
  'odf' => { nwl => '',   lnk => 0, css => 'odf.css', out => 'out.css' },
  'rda' => { nwl => "\n", lnk => 1, css => 'rda.css', out => 'out.css' },
  'tst' => { nwl => "\n", lnk => 0, css => 'odf.css', out => 'out.css' },
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Render-E<gt>new($out[,$rul])>

The object constructor. It takes the reporting control reference and the
immediate rendering rules as arguments.

C<RDA::Render> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_cas'> > Indicates a case sensitive context

=item S<    B<'_cfg'> > Reference to the RDA software configuration

=item S<    B<'_cpm'> > Code page mapping

=item S<    B<'_css'> > Cascading style sheet (CSS) file name

=item S<    B<'_frm'> > Report to present in the report frame at initial load

=item S<    B<'_gid'> > Owner group identifier

=item S<    B<'_grp'> > Report group

=item S<    B<'_hdr'> > Header reference counter

=item S<    B<'_ofh'> > Rendering output file handle

=item S<    B<'_out'> > Reference to the output control object

=item S<    B<'_own'> > Owner alignment indicator

=item S<    B<'_rnd'> > Immediate rendering hash

=item S<    B<'_rpt'> > Report directory

=item S<    B<'_spl'> > Flag controlling the table of contents split

=item S<    B<'_thm'> > Theme name

=item S<    B<'_uid'> > Owner user identifier

=item S<    B<'_ver'> > Software version

=item S<    B<'_var'> > Render variable hash

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $out, $rul) = @_;
  my ($agt, $cfg, $ofh, $slf, $str);

  # Create the render object
  $agt = $out->get_info('agt');
  $cfg = $agt->get_config;
  $slf = bless {
    _agt => $agt,
    _cas => $out->get_info('cas'),
    _cfg => $cfg,
    _frm => $agt->get_setting('RPT_START', '_blank'),
    _grp => $out->get_info('grp'),
    _out => $out,
    _own => 0,
    _rpt => $out->get_info('dir'),
    _spl => $agt->get_setting('RDA_SPLIT', 1),
    _thm => $agt->get_setting('RDA_THEME', 'rda'),
    _ver => $out->get_info('rel'),
    }, ref($cls) || $cls;

  # Validate settings
  $slf->{'_thm'} = 'rda' unless exists($tb_thm{$slf->{'_thm'}});

  # Control immediate rendering
  if ($rul)
  { # Create the rendering handle
    $slf->{'_ofh'} = $ofh = bless Symbol::gensym(), ref($slf);
    tie *$ofh, $ofh;
    *$ofh->{'fil'} = 0;
    *$ofh->{'pip'} = IO::File->new;
    *$ofh->{'rpt'} = IO::File->new;
    *$ofh->{'sep'} = 0;

    # Get the report list
    foreach my $val (split(/[\:\;]/, $rul))
    { $slf->{'_rnd'}->{uc($1)} = qr#$2#i if $val =~ m#^(\w+_)(.*$)#;
    }

    # Launch the rendering subprocess
    $ofh = *$ofh->{'pip'};
    open($ofh, '| '.$agt->get_setting('RDA_SELF').' -O -s '.
      $cfg->get_file('D_CWD', $agt->get_info('nam'))) ||
      die "RDA-00308: Cannot launch rendering subprocess: $!";
    $ofh->autoflush(1);
  }

  # Load the render variable definitions
  if (open(VAR, '<'.$cfg->get_file('D_RDA_DATA', 'rdavar.txt')))
  { while (<VAR>)
    { next if m/^#$/;
      s/[\n\r\s]*$//;
      my ($key, $val) = split(/=/, $_, 2);
      $slf->{'_var'}->{$key} = $val if $key && $val;
    }
    close(VAR);
  }

  # Load the code page mapping
  if (open(CPM, '<'.$cfg->get_file('D_RDA_DATA', 'cp.txt')))
  { while(<CPM>)
    { $slf->{'_cpm'}->{$1} = $2 if m/^(\d+)\s+(\S+)/;
    }
    close(CPM);
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>align_owner([$uid,$gid])>

This method indicates that the user and group identifiers of the produced files
must be aligned to the owner of the report directory.

=cut

sub align_owner
{ shift->{'_own'} = 1;
}

=head2 S<$h-E<gt>end>

This method ends any rendering activity.

=cut

sub end
{ my ($slf) = @_;

  if (exists($slf->{'_ofh'}))
  { my $pip = $slf->{'_ofh'};

    *$pip->{'rpt'}->close if *$pip->{'fil'};
    *$pip->{'pip'}->close;
    delete(*$pip->{'fil'});
    delete(*$pip->{'pip'});
    delete(*$pip->{'rpt'});
    delete(*$pip->{'sep'});
    undef *$pip;

    delete($slf->{'_ofh'});
    delete($slf->{'_rnd'});
  }
  1;
}

=head2 S<$h-E<gt>gen_css($flg)>

This method generates the cascading style sheet (CSS) file for the report
group if it does exist yet. When the flag is set, it re-creates the CSS file.
It returns the name of the CSS file.

=cut

sub gen_css
{ my ($slf, $flg) = @_;
  my ($cfg, $css, $fil, $thm);

  # Return directly the CSS file name on multiple calls
  return $slf->{'_css'} if exists($slf->{'_css'}) && !$flg;

  # Determine the source file
  $cfg = $slf->{'_cfg'};
  $thm = $tb_thm{$slf->{'_thm'}};
  unless ($thm->{'lnk'})
  { $slf->{'_css'} = $css =
      $cfg->get_file('D_RDA_HTML', $thm->{'css'});
    return $css;
  }

  # Stop if the CSS file already exists
  $css = $slf->{'_grp'}.'_rda.css';
  $css = lc($css) unless $slf->{'_cas'};
  $slf->{'_css'} = $css;
  $fil = $cfg->cat_file($slf->gen_directory, $css);
  if ($flg)
  { 1 while unlink($fil);
  }
  elsif (-e $fil)
  { return $css;
  }

  # Generate the CSS file
  copy($cfg->get_file('D_RDA_HTML', $thm->{'css'}), $fil)
    && chmod($FIL_PERMS, $fil)
    && $slf->{'_own'}
    && chown($slf->{'_uid'}, $slf->{'_gid'}, $fil);

  # Return the name of the CSS file
  $css;
}

=head2 S<$h-E<gt>gen_directory>

This method creates the output directory if it does not exist. It returns the
directory path also.

=cut

sub gen_directory
{ my ($slf) = @_;
  my ($rpt, @sta);

  # Create the directory if not existing yet
  $rpt = $slf->{'_rpt'};
  die "RDA-00300: Cannot create the report directory $rpt:\n $!\n"
    unless -d $rpt || mkdir($rpt, 0750);

  #  Determine the owner of the report directory
  if ($slf->{'_own'} && (@sta = stat($rpt)))
  { $slf->{'_uid'} = $sta[4];
    $slf->{'_gid'} = $sta[5];
  }
  else
  { $slf->{'_own'} = 0;
  }

  # Return the directory path
  $rpt;
}

=head2 S<$h-E<gt>gen_html($name[,$title])>

This method transforms formatting specifications in a HTML file. You can
specify the report by its name or by its file name. By default, it derives
the title from the report or file name. It generates the cascading style 
sheet (CSS) file if it does not already exist and then it returns the name
of the generated file.

=cut

sub gen_html
{ my ($slf, $src, $ttl, $sub, $idx) = @_;
  my ($dst, $grp, $ifh, $nwl, $ofh, $set, $thm, @sta, %dsc);

  # Initialization
  $grp = $slf->{'_grp'};
  $thm = $tb_thm{$slf->{'_thm'}};
  $dsc{'css'} = $slf->gen_css;
  $dsc{'dat'} = $src;
  $dsc{'def'} = {};
  $dsc{'lnk'} = $thm->{'lnk'};
  $dsc{'nwl'} = $nwl = $thm->{'nwl'};
  $dsc{'toc'} = [];

  # Set a default title
  unless ($ttl)
  { $ttl = ($src =~ m/(\w*)(\.(dat|txt))?$/i) ? $1 : "RDA Report";
    $ttl =~ s/^$grp\_//;
    $ttl =~ s/_/ /g;
    $ttl =~ s/\b([a-z])/\U$1/g;
  }
  $dsc{'ttl'} = $ttl;

  # Correct the CSS path
  $dsc{'css'} = '../'.$dsc{'css'} if $sub;

  # Determine the file names and get extra rendering information
  if ($src =~ m/\.dat$/i)
  { $dst = $src;
    $dst =~ s/\.dat$/.htm/i;
    $src = $slf->{'_cfg'}->get_file('D_RDA_DATA', 'dat.txt');
    $dsc{'hdr'} = 1;
  }
  else
  { $src = "$grp\_$src.txt" unless $src =~ m/\.txt$/i;
    $dst = $src;
    $dst =~ s/\.txt$/.htm/i;
    $src = RDA::Object::Rda->cat_file($slf->{'_rpt'}, $src);

    # Get the table of content
    $slf->_gen_toc($src, $dsc{'toc'}, $dsc{'def'});
  }
  $dst = RDA::Object::Rda->cat_file($slf->{'_rpt'},
    $slf->{'_cas'} ? $dst : lc($dst));

  # Determine the page character set
  if (exists($dsc{'def'}->{'codepage'}))
  { $set = $dsc{'def'}->{'codepage'};
    $set = exists($slf->{'_cpm'}->{$set})
      ? $slf->{'_cpm'}->{$set}
      : 'UTF-8';
  }
  else
  { $set = exists($dsc{'def'}->{'charset'})
      ? $dsc{'def'}->{'charset'}
      : 'UTF-8';
  }

  # Generate the HTML file
  $ifh = IO::File->new;
  $ofh = IO::File->new;
  $ifh->open("<$src") ||
    die "RDA-00302: Cannot open the format specification file '$src':\n $!\n";
  $ofh->open($dst, $CREATE, $FIL_PERMS) ||
    die "RDA-00303: Cannot create the report file $dst:\n $!";
  chown($slf->{'_uid'}, $slf->{'_gid'}, $dst) if $slf->{'_own'};

  $slf->{'_out'}->check_free(3 * $sta[7]) if (@sta = stat($ifh));

  print {$ofh}
    "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>".$nwl.
    "<html lang='en-US'><head>".$nwl.
    "<meta http-equiv='Content-Type' content='text/html;charset=".$set."'/>".
    $nwl."<title>".$dsc{'ttl'}."</title>".$nwl;
  if ($dsc{'lnk'})
  { print {$ofh} "<link rel='stylesheet' type='text/css' href='".$dsc{'css'}.
      "'>".$nwl;
  }
  elsif (open(CSS, '<'.$dsc{'css'}))
  { while(<CSS>)
    { s#\/\*.*?\*\/##g;
      s#[\n\r\s]+$##; #
      print {$ofh} "<style type='text/css'>$_</style>$nwl" if $_;
    }
    close(CSS);
  }
  print {$ofh} "</head><body>";
  $slf->_gen_html($ofh, $ifh, $idx, \%dsc);
  print {$ofh} "</body></html>$nwl";
  $ofh->close;
  $ifh->close;

  # Return the the result file
  $dst;
}

=head2 S<$h-E<gt>gen_output>

This method reads formatting specifications from standard input and transforms
them into HTML code.

=cut

sub gen_output
{ my ($slf) = @_;
  my ($dst, $grp, $nwl, $thm, %dsc);

  # Initialization
  $thm = $tb_thm{$slf->{'_thm'}};
  $dsc{'nwl'} = $nwl = $thm->{'nwl'};

  # Insert the style
  if (open(CSS, '<'.$slf->{'_cfg'}->get_file('D_RDA_HTML', $thm->{'out'})))
  { while(<CSS>)
    { s#\/\*.*?\*\/##g;
      s#[\n\r\s]+$##;
      print "<style type='text/css'>$_</style>$nwl" if $_;
    }
    close(CSS);
  }

  # Generate the HTML code
  $slf->_gen_html(*STDOUT, *STDIN, 0, \%dsc);
}

# Generate the HTML file
sub _gen_html
{ my ($slf, $dst, $src, $flg, $dsc) = @_;
  my ($blk, $cur, $hdr, $lst, $lvl, $max, $nxt, $rec, $sct, $sum, $tbl, $tid);
  my ($eob, $lin, $nwl, @tb_lvl);

  # Treat the input file
  $lin = <$src> if $dsc->{'hdr'};
  $eob = $lin = '';
  $slf->{'_hdr'} = $blk = $hdr = $lvl = $nxt = $rec = $sct = $tbl = $tid = 0;
  $nwl = $dsc->{'nwl'};
  print {$dst} "<div class='".($flg ? 'rda_index' : 'rda_normal').
    "'><p><a name='Top'></a>$nwl";
  while (<$src>)
  { # Detect if there is a continuation line
    s/[\r\n]*$//;
    $lin .= $_ unless m/^\000*$/;
    unless ($blk)
    { next if $lin =~ s/\\$//;
    }
    $lin =~ s/\s+$//;

    # Detect a context change
    if ($lvl)
    { # Close an open list
      unless ($lin =~ m/^( {3,})[\*1AaIi]./ && (length($1) % 3) == 0)
      { my ($typ);
        while ($typ = pop(@tb_lvl))
        { print {$dst} $tb_end{$typ}.$nwl;
        }
        $lvl = $nxt = 0;
      }
    }
    elsif ($rec)
    { # Close an open table
      unless ($lin =~ m/^\|[^\|].*\|$/)
      { print {$dst} "</table>$nwl";
        $nxt = $rec = 0;
        $tid = $max;
      }
    }

    # Treat a line
    if ($blk)
    { if ($lin eq $eob)
      { print {$dst} "</pre>$nwl" if defined(&$blk($slf, ''));
        $blk = 0;
      }
      elsif (defined($lin = &$blk($slf, $lin)))
      { print {$dst} "$lin\n";
      }
    }
    elsif ($lin =~ m/^\|<([^>]*)>\|$/)
    { unless ($rec)
      { ++$tbl;
        $sum = _clr_var($slf, $1);
        $sum =~ s/'/&quot;/g;
        print {$dst} "<table border='1' summary='$sum'>$nwl";
        $sum = undef;
        $lst = $max = $tid + 1;
        ++$rec;
      }
    }
    elsif ($lin =~ s/^\|([^\|].*\|)$/$1/)
    { my ($col, $dir, $hid, $jus, $new, $spn, $txt);
      unless ($rec)
      { ++$tbl;
        $sum = _clr_var($slf, $sum) if $sum;
        $sum = $sum ? "$sum Information" : "RDA Result Set $tbl";
        $sum =~ s/'/&quot;/g;
        print {$dst} "<table border='1' summary='$sum'>$nwl";
        $sum = undef;
        $lst = $max = $tid + 1;
      }
      print {$dst} "<tr>", $nwl;
      $new = $tid + 1;
      $col = $dir = 0;
      while ($lin =~ s/([^\|]+)(\|{1,})//)
      { $new = 0 if ($cur = length($2)) > 1;
        $txt = $1;
        $jus = 0;
        $jus += 1 if $txt =~ s/^\s+//;
        $jus += 2 if $txt =~ s/\s+$//;
        $txt = '&nbsp;' unless length($txt);
        $spn = ($cur > 1) ? " colspan='$cur'" : "";
        if ($txt =~ s/^\*(.+)\*$/$1/)
        { ++$tid;
          $max = $tid if $tid > $max;
          print {$dst} "<th$tb_jus[$jus] id='T$tid'$spn>".
            _rpl_var($slf, $txt)."</th>$nwl";
          $dir = 1;
        }
        else
        { $hid = ($dir) ? $tid : $lst + $col;
          $max = $tid = $hid if $hid > $max;
          print {$dst} "<td$tb_jus[$jus] headers='T$hid'$spn>".
            _rpl_var($slf, $txt)."</td>$nwl";
          $dir = $new = 0;
        }
        $col += $cur;
      }
      print {$dst} "</tr>", $nwl;
      $lst = $new if $new;
      ++$rec;
    }
    elsif ($lin =~ m/^$/)
    { $nxt = 0;
    }
    elsif ($lin =~ m/^-{3,}$/)
    { print {$dst} "<hr size='1'/>", $nwl;
      $nxt = 0;
    }
    elsif ($lin =~ m/^-{3}(\+{1,6})(!!)?\s*(.*)$/)
    { my ($idn, $tag);
      $tag = sprintf("h%d", length($1));
      if ($2)
      { $idn = 'Sct'.++$sct;
      }
      else
      { $idn = 'Hdr'.++$hdr;
        $slf->{'_hdr'} = $hdr if $hdr > $slf->{'_hdr'};
      }
      print {$dst} "<$tag id='$idn'>"._rpl_var($slf, $3)."</$tag>$nwl";
      $sum = $3;
      $nxt = 0;
    }
    elsif ($lin =~ m/^-{3}(\#{1,6})\s*(.*)$/)
    { my $tag = sprintf("h%d", length($1));
      print {$dst} "<$tag>"._rpl_var($slf, $2)."</$tag>$nwl";
      $nxt = 0;
    }
    elsif ($lin =~ m/^<verbatim(:\w+)?>$/)
    { $blk = \&_rpl_enc;
      $eob = '</verbatim>';
      print {$dst} "<pre>\n";
    }
    elsif ($lin =~ m/^<pre>$/)
    { $blk = \&_rpl_none;
      $eob = '</pre>';
      print {$dst} "<pre>\n";
    }
    elsif ($lin =~ m/^<code>$/)
    { $blk = \&_rpl_var;
      $eob = '</code>';
      print {$dst} "<pre>\n";
    }
    elsif ($lin =~ m/^<comment>$/)
    { $blk = \&_skp_line;
      $eob = '</comment>';
    }
    elsif ($lin =~ m/^( {3,})([\*1AaIi])\s*(.+)$/ && (length($1) % 3) == 0)
    { $cur = int(length($1) / 3);
      while ($lvl > $cur || ($lvl == $cur && $2 ne $tb_lvl[$#tb_lvl]))
      { print {$dst} $tb_end{pop(@tb_lvl)}.$nwl;
        --$lvl;
      }
      while ($lvl < $cur)
      { print {$dst} $tb_beg{$2}.$nwl;
        push(@tb_lvl, $2);
        ++$lvl;
      }
      print {$dst} "<li>"._rpl_var($slf, $3).$nwl;
    }
    elsif ($lin =~ m/^#(\w+)(\s(---(#{1,6})\s)?(.*))?$/)
    { my $txt = _rpl_var($slf, ($5 || ''));
      if ($3)
      { my $tag = sprintf("h%d", length($4));
        print {$dst} "<$tag><a name='$1'>$txt</a></$tag>$nwl";
        $nxt = 0;
      }
      else
      { print {$dst} "<p>" unless $nxt++;
        print {$dst} "<a name='$1'>$txt</a>$nwl";
      }
    }
    elsif ($lin =~ m/^\%DATA\%$/)
    { print {$dst} "<p>" unless $nxt++;
      print {$dst} "<a href='".$dsc->{'dat'}."'>".$dsc->{'dat'}."</a>$nwl"
        if exists($dsc->{'dat'});
    }
    elsif ($lin =~ m/^\%TOC\%$/)
    { $cur = $lvl = 0;
      if (exists($dsc->{'toc'}))
      { print {$dst} "<div class='rda_toc'>$nwl";
        foreach my $itm (@{$dsc->{'toc'}})
        { while ($lvl > $itm->[0])
          { print {$dst} "</ul>$nwl";
            --$lvl;
          }
          while ($lvl < $itm->[0])
          { print {$dst} "<ul>$nwl";
            ++$lvl;
          }
          print {$dst} "<li><a href='#Hdr".$itm->[1]."'>".
            _rpl_var($slf, $itm->[2])."</a>$nwl";
        }
        while ($lvl > 0)
        { print {$dst} "</ul>$nwl";
          --$lvl;
        }
        print {$dst} "</div>$nwl";
      }
      $nxt = 0;
    }
    elsif ($lin =~ m/^\%TOC(\d+)(-(\d+))?\%$/)
    { my ($col, $max, $sep);
      $col = $1 || 1; 
      $lvl = $3 || 1; 
      $cur = 0;
      if (exists($dsc->{'toc'}))
      { foreach my $itm (@{$dsc->{'toc'}})
        { ++$cur unless $itm->[0] > $lvl;
        }
        $nxt = $cur % $col;
        $col = int($cur / $col);
        print {$dst} "<div class='rda_toc'>".$nwl.
          "<table border='0' summary=''$NBD><tr$NBD>$nwl$SEP$nwl<td$NBD>";
        $sep = '';
        $cur = ($nxt-- > 0) ? $col + 1 : $col;
        foreach my $itm (@{$dsc->{'toc'}})
        { next if $itm->[0] > $lvl;
          print {$dst} "$sep<a href='#Hdr".$itm->[1]."'>".
            _rpl_var($slf, $itm->[2])."</a>";
          if (--$cur)
          { $sep = '<br/>';
          }
          else
          { $sep = "</td>$nwl$SEP$nwl<td$NBD>";
            $cur = ($nxt-- > 0) ? $col + 1 : $col;
          }
        }
        print {$dst} "</td>$nwl</tr></table></div>$nwl";
      }
      $nxt = 0;
    }
    elsif ($lin =~ m/^\%INCLUDE\{"([^"]+)"\}\%$/)
    { print {$dst} "<p>" unless $nxt++;
      if (open(INC, '<'.(RDA::Object::Rda->is_absolute($1)
        ? $1
        : RDA::Object::Rda->cat_file($slf->{'_rpt'}, $1))))
      { while (<INC>)
        { print {$dst} _rpl_var($slf, $_);
        }
        close(INC);
      }
    }
    elsif ($lin =~ m/^\%PRE\{"([^"]+)"\}\%$/)
    { if (open(INC, '<'.(RDA::Object::Rda->is_absolute($1)
        ? $1
        : RDA::Object::Rda->cat_file($slf->{'_rpt'}, $1))))
      { print {$dst} "<pre>$nwl";
        while (<INC>)
        { print {$dst} _rpl_none($slf, $_);
        }
        print {$dst} "</pre>$nwl";
        close(INC);
      }
    }
    elsif ($lin =~ m/^\%VERBATIM\{"([^"]+)"\}\%$/)
    { if (open(INC, '<'.(RDA::Object::Rda->is_absolute($1)
        ? $1
        : RDA::Object::Rda->cat_file($slf->{'_rpt'}, $1))))
      { print {$dst} "<pre>$nwl";
        while (<INC>)
        { print {$dst} _rpl_enc($slf, $_);
        }
        close(INC);
        print {$dst} "</pre>$nwl";
      }
    }
    elsif ($lin =~ m/^<!-- .* -->$/)
    { print {$dst} "<p>" unless $nxt++;
      print {$dst} $lin.$nwl;
    }
    elsif ($lin !~ m/^<\?.*\?>$/)
    { print {$dst} "<p>" unless $nxt++;
      print {$dst} _rpl_var($slf, $lin).$nwl;
    }
    $lin = '';
  }

  # Terminate and close the HTML file
  if ($lvl) # Open list
  { my ($typ);
    while ($typ = pop(@tb_lvl))
    { print {$dst} $tb_end{$typ}.$nwl;
    }
  }
  elsif ($rec) # Open table
  { print {$dst} "</table>$nwl";
  }
  elsif ($blk) # Open block
  { print {$dst} "</pre>$nwl" if defined(&$blk($slf, ''));
  }
  print {$dst} "</div>";
}

# Generate the table of content
sub _gen_toc
{ my ($slf, $src, $toc, $def) = @_;
  my ($blk, $hdr, $lin);

  open(IN, "<$src") ||
    die "RDA-00302: Cannot open the format specification file '$src':\n $!\n";
  $blk = undef;
  $hdr = 0;
  $lin = '';
  while (<IN>)
  { # Detect if there is a continuation line
    s/[\r\n]*$//;
    $lin .= $_ unless m/^\000*$/;
    next if $lin =~ s/\\$//;
    $lin =~ s/\s+$//;

    # Minimal parsing to get the heading lines
    if ($blk)
    { $blk = undef if $lin eq $blk;
    }
    elsif ($lin =~ m/^-{3}(\+{1,6})(!!)?\s*(.*)$/)
    { push(@$toc, [length($1), ++$hdr, _clr_var($slf, $3, 1)]) unless $2;
    }
    elsif ($lin =~ m/^<\?\s*(\w+):(\S*)\s*\?>$/)
    { $def->{lc($1)} = $2;
    }
    elsif ($lin =~ m/^<verbatim(:\w+)?>$/)
    { $blk = "</verbatim>";
    }
    elsif ($lin =~ m/^<pre>$/)
    { $blk = "</pre>";
    }
    elsif ($lin =~ m/^<comment>$/)
    { $blk = "</comment>";
    }
    $lin = '';
  }
  close(IN);
}

# Remove variables and other enhancements
sub _clr_var
{ my ($slf, $str, $flg) = @_;

  $str =~ s#\%COL\d+\%# #g;
  $str =~ s#\%R:(\w+)\%#$1#g;
  $str =~ s#\%(BR|(END)?LIST|NEXT|(END)?SEQ)\%# #g;
  $str =~ s#\%ID(:\w+)*\%##g;
  $str =~ s#\%(BLUE|RED)\%##g;
  $str =~ s#\%ENDCOL(OR)?\%##g;
  $str =~ s#\%HDR\%# #g;
  $str =~ s#\%MRC:\w+\%##g;
  $str =~ s#\%NULL\%#Null value#g;
  $str =~ s#\%VERSION\%#$slf->{'_ver'}#g;
  $str =~ s#\*\*(.*?)\*\*#$1#g;
  $str =~ s#\'\'(.*?)\'\'#$1#g;
  $str =~ s#\`\`(.*?)\`\`#$1#g unless $flg;
  $str =~ s#\{\{[^\|\}]+?\}\}##g;
  $str =~ s#\{\{.+?\|(.*?)\}\}#[$2]#g;
  $str =~ s#\[\[([^\[\]]+)\]\[([^\[\]]+)\]\[(.+?)\]\]#$3#g;
  $str =~ s#\[\[([^\[\]]+)\]\[(.+?)\]\]#$2#g;
  $str =~ s#\s+# #g;
  $str =~ s/([\042\045\047\050\051\053\055\074\076])/
    sprintf("&#x%X;", ord($1))/ge;
  $str;
}

# Convert a column
sub _cnv_col
{ my ($str, $ctl) = @_;
  my ($col, $cur, $nxt, @col, @tbl);

  $col = $ctl->{'num'};
  $str =~ s/\%NEXT\%/\%BR\%/g;
  $cur = scalar(@tbl = split(/\%BR\%/, $str, -1));
  $nxt = $cur % $col;
  $col = int($cur / $col);
  while (@tbl)
  { $cur = ($nxt-- > 0) ? $col + 1 : $col;
    push(@col, join('<br/>', splice(@tbl, 0, $cur)));
  }
  "<table summary=''$NBD><tr$NBD><td$NBD>"
    .join("</td>$SEP<td$NBD>", @col)."</td></tr></table>";
}

# Convert a list
sub _cnv_list
{ my ($str) = @_;

  ($str =~ m/^\s*$/)
    ? $str
    : "<div class='rda_lst'><ul><li>"
      .join("</li><li>", map {_rpl_ref($_)} split(/\%NEXT\%/, $str, -1))
      ."</li></ul></div>";
}

# Convert a sequence
sub _cnv_seq
{ my ($str) = @_;

  ($str =~ m/^\s*$/)
    ? $str
    : "<div class='rda_seq'><ol><li>"
      .join("</li><li>", map {_rpl_ref($_)} split(/\%NEXT\%/, $str, -1))
      ."</li></ol></div>";
}

# Convert a table
sub _cnv_tbl
{ my ($str, $ctl) = @_;
  my ($buf, @row);

  $str =~ s/\%ID(:\w+)*\%//;
  return '' unless (@row = split(/\%BR\%/, $str, -1));
  $buf = "<table summary=''$NBD>";
  foreach my $row (@row)
  { $buf .= "<tr$NBD>"
      .join('', map {_cnv_cell($_)} split(/\%NEXT\%/, $row, -1))
      ."</tr>";
  }
  $buf."</table>";
}

sub _cnv_cell
{ my ($txt) = @_;
  my ($jus);

  $jus = 0;
  $jus += 1 if $txt =~ s/^\s+//;
  $jus += 2 if $txt =~ s/\s+$//;
  "<td".$tb_jus[$jus].$NBT.">"._rpl_ref($txt)."</td>";
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

# Parse a string
sub _prs_tree
{ my ($tbl, $ctl) = @_;
  my ($itm);

  while (defined($itm = shift(@$tbl)))
  { next if $itm eq '';
    return $ctl if exists($ctl->{'end'}) && $itm eq $ctl->{'end'};
    if ($itm =~ m#^\%COL(\d*)\%$#) #
    { push(@{$ctl->{'det'}}, _prs_tree($tbl,
        {typ => 'C', det => [], end => '%ENDCOL%', num => $1 || 1}));
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

# Encode some characters
sub _rpl_enc
{ my ($slf, $str) = @_;

  $str =~ s/([\042\046\047\050\051\053\055\074\076])/
    sprintf("&#x%X;", ord($1))/ge;
  $str =~ s#\%R:(\w+)\%#_rpl_rdr($slf, $1)#eg;
  $str =~ s/\045/&#x25;/g;
  $str;
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

  $str =~ s#\%R:(\w+)\%#_rpl_rdr($slf, $1)#eg;
  $str;
}

# Replace render variables
sub _rpl_rdr
{ my ($slf, $var) = @_;

  $var = $slf->{'_var'}->{$var} if exists($slf->{'_var'}->{$var});
  "<span class='rda_filter'>&lt;$var&gt;</span>";
}

# Replace references
sub _rpl_ref
{ my ($str) = @_;
  my ($blk);

  $blk = '([^\[\]]+)';
  $str =~ s#\%BR\%#<br/>#g;
  $str =~ s#\%ID(:\w+)*\%##g;
  $str =~ s#\%RED\%#<span class='rda_red'>#g;
  $str =~ s#\%BLUE\%#<span class='rda_blue'>#g;
  $str =~ s#\%ENDCOLOR\%#</span>#g;
  $str =~ s#\{\{([^\|\}]+?)\}\}#<img src='$1' alt='' border='0'/>#g;
  $str =~ s#\{\{(.+?)\|(.*?)\}\}#<img src='$1' alt='$2' border='0'/>#g;
  $str =~ s#\[\[$blk\]\[$blk\]\[(.+?)\]\]#<a href='$1' target='$2'>$3</a>#g;
  $str =~ s#\[\[$blk\]\[(.+?)\]\]#<a href='$1'>$2</a>#g;
  $str;
}

# Replace variables
sub _rpl_var
{ my ($slf, $str) = @_;
  my (@tbl);

  $str =~ s/([\042\050\051\053\055\074\076])/
    sprintf("&#x%X;", ord($1))/ge;

  while ($str =~ m#\%HDR\%#)
  { ++$slf->{'_hdr'};
    $str =~ s#\%HDR\%#Hdr$slf->{'_hdr'}#;
  }

  $str =~ s#\*\*(.*?)\*\*#<strong>$1</strong>#g;
  $str =~ s#</strong><strong>##g;
  $str =~ s#\'\'(.*?)\'\'#<em>$1</em>#g;
  $str =~ s#</em><em>##g;
  $str =~ s#\`\`(.*?)\`\`#<code>$1</code>#g;
  $str =~ s#</code><code>##g;
  $str =~ s/\'/&#x27;/g;

  $str =~ s#\%R:(\w+)\%#_rpl_rdr($slf, $1)#eg;
  $str =~ s#\%MRC:(\w+)\%#_rpl_mrc($slf, $1)#eg;
  $str =~ s#\%NULL\%#<span class='rda_null'>Null value</span>#g;
  $str =~ s#\%VERSION\%#$slf->{'_ver'}#g;

  # Parse the string and convert the resulting tree
  @tbl = split(/($CMD)/, $str);
  $str = _cnv_tree(_prs_tree(\@tbl, {typ => 'F', det => []}));
  $str =~ s#<li></li>##g;
  $str =~ s/\%/&#x25;/g;
  $str;
}

# Skip a line
sub _skp_line
{ undef;
}

=head2 S<$h-E<gt>gen_index([$flag])>

This method generates the index file and the start file. When the flag is set,
it re-creates the cascading style sheet file.

=cut

sub gen_index
{ my ($slf, $flg) = @_;
  my ($cas, $cfg, $fct, $fil, $grp, $idx, $ifh, $lst, $mod, $rpt, $spl);
  my ($mbs, $mts, $sbs, $sts, @all, @tbl);

  # Initialization
  $cas = $slf->{'_cas'};
  $cfg = $slf->{'_cfg'};
  $grp = $slf->{'_grp'};
  $rpt = $slf->{'_rpt'};
  $spl = $slf->{'_spl'};

  # Get the report list
  return unless -d $rpt;
  opendir(DIR, $rpt) ||
    die "RDA-00301: Cannot open the report directory:\n $!\n";
  @all = grep {m/^$grp\_/i} readdir(DIR);
  closedir(DIR);

  # Generate the stylesheet generation as appropriate
  $slf->gen_css($flg);

  # Delete the old global index files
  _del_files($rpt, \@all, qr/^$grp\__(blank|index|start)\.(htm|txt)$/i);

  # Create the index specifications file
  $idx = "$grp\__index.txt";
  $idx = lc($idx) unless $cas;
  $fil = RDA::Object::Rda->cat_file($rpt, $idx);
  if ($spl)
  { $fct = \&_cat_split;
    $mts = $cfg->get_file('D_RDA_DATA', 'rdamtop.txt');
    $mbs = $cfg->get_file('D_RDA_DATA', 'rdambot.txt');
    $sts = $cfg->get_file('D_RDA_DATA', 'rdastop.txt');
    $sbs = $cfg->get_file('D_RDA_DATA', 'rdasbot.txt');
  }
  else
  { $fct = \&_cat_single;
    $mts = $cfg->get_file('D_RDA_DATA', 'rdatop.txt');
    $mbs = $cfg->get_file('D_RDA_DATA', 'rdabot.txt');
  }
  $ifh = IO::File->new;
  $ifh->open($fil, $CREATE, $FIL_PERMS) ||
    die "RDA-00304: Cannot create index format specifications:\n $!\n";
  chown($slf->{'_uid'}, $slf->{'_gid'}, $fil) if $slf->{'_own'};

  # Insert the index top
  _cat_index($ifh, $mts);

  # Insert the module contributions
  $lst = '';
  @tbl = sort grep {m/^$grp\_S\d{3}\w+\.toc$/i} @all;
  foreach my $toc (@tbl)
  { # Delete the old index files
    $mod = substr($toc, 0, -4);
    _del_files($rpt, \@all, qr/^$mod(_\d+)?\.(htm|txt)$/i);

    # Generate the new index
    $toc = lc($toc) unless $cas;
    $lst = &$fct($ifh, $rpt, $toc, $lst, $slf, $sts, $sbs);
  }

  # Insert the index bottom
  _cat_index($ifh, $mbs);

  # Render the index file
  close($ifh);
  $slf->gen_html($idx, "RDA Report Index", 0, 1);

  # Generate the start file
  $slf->gen_start($tbl[0]);
}

sub _cat_index
{ my ($ifh, $fil) = @_;

  if (open(IN, "<$fil"))
  { while (<IN>)
    { if (s/^(\d+):// && $1 > 0)
      { print $ifh '   'x$1.'* '.$_;
      }
      elsif (!m/^#/)
      { print $ifh $_;
      }
    }
    close(IN);
  }
}

sub _cat_single
{ my ($ifh, $rpt, $toc, $lst) = @_;
  my ($lin, $lvl, $min, $off, @stk, @toc, @ttl);

  $off = 0;
  $min = 1;
  if (open(IN, '<'.RDA::Object::Rda->cat_file($rpt, $toc)))
  { # Load all specifications
    @toc = <IN>;
    close(IN);

    # Convert the module table contents in format specifications
    while (defined($lin = shift(@toc)))
    { $lin =~ s/[\r\n]+$//;
      if ($lin =~ m/^(\^?)(\d+)\+*:(.*)$/ && $2 > 0)
      { $lvl = $2 - $off;
        if ($3 eq $lst || $1 || $lvl < $min)
        { $lst = '';
        }
        elsif (@ttl)
        { unshift (@toc, splice(@ttl), $lin);
        }
        else
        { print $ifh '   'x$lvl."* $3\n";
          $lst = '';
        }
      }
      elsif ($lin =~ s/^\-://)
      { $lst = $lin;
      }
      elsif ($lin =~ m/^\%FOCUS(\-?\d+)?(:([1-9]\d*))?\%\s*$/)
      { $off = defined($1) ? $1 : 0;
        $min = defined($3) ? $3 : 1;
      }
      elsif ($lin =~ m/^\%INCLUDE\("([^"]+)"(,(\d+))?\)\%$/)
      { my ($fil, $str);

        $fil = RDA::Object::Rda->is_absolute($1)
          ? $1
          : RDA::Object::Rda->cat_file($rpt, $1);
        if (open(IN, "<$fil"))
        { if ($2 && $3 > 0)
          { $str = '+' x $3;
            unshift (@toc, splice(@ttl), splice(@stk),
              map {_indent_top($_, $str)} <IN>);
          }
          else
          { unshift (@toc, splice(@ttl), splice(@stk), <IN>);
          }
          close(IN);
        }
      }
      elsif ($lin =~ m/^\%(LEVEL([1-9])|SPLIT)\%\s*$/)
      {
      }
      elsif ($lin =~ m/^\%POP(\d+)?\%\s*$/)
      { my $val = defined($1) ? $1 : 1;
        pop(@stk) while $val-- > 0;
      }
      elsif ($lin =~ m/^\%PUSH\("([^"]+)"\)\%\s*$/)
      { push(@stk, $1);
      }
      elsif ($lin =~ m/^\%TITLE\("([^"]+)"\)\%\s*$/)
      { push(@ttl, $1);
      }
      elsif ($lin =~ m/^\%UNTITLE(\d+)?\%\s*$/)
      { my $val = defined($1) ? $1 : 1;
        pop(@ttl) while $val-- > 0;
      }
      elsif ($lin !~ m/^#---\[.*\]---$/)
      { if (@ttl)
        { unshift (@toc, splice(@ttl), $lin);
        }
        else
        { print $ifh "$lin\n";
        }
      }
    }
  }
  $lst;
}

sub _cat_split
{ my ($ifh, $rpt, $toc, $lst, $slf, $top, $bot) = @_;
  my ($bas, $cnt, $fil, $lim, $lin, $min, $off, $sfh, $spl, $txt,
      @stk, @toc, @ttl);

  $off = 0;
  $min = 1;
  if (open(IN, '<'.RDA::Object::Rda->cat_file($rpt, $toc)))
  { # Load all specifications
    @toc = <IN>;
    close(IN);

    # Create the subindex file and insert subindex top
    $sfh = IO::File->new;
    $toc =~ s/\.toc$//i;
    $fil = RDA::Object::Rda->cat_file($rpt, "$toc.txt");
    $sfh->open($fil, $CREATE, $FIL_PERMS) ||
      die "RDA-00305: Cannot create subindex format specifications:\n $!\n";
    chown($slf->{'_uid'}, $slf->{'_gid'}, $fil) if $slf->{'_own'};
    _cat_index($sfh, $top);

    # Split the module table of content
    $bas = $toc;
    $spl = $cnt = 0;
    $lim = 1;
    while (defined($lin = shift(@toc)))
    { $lin =~ s/[\r\n]+$//;
      if ($lin =~ m/^(\^?)(\d+)(\+*):(.*)$/)
      { my ($dsc, $flg, $idx, $lvl, $str);

        ($flg, $lvl, $str, $txt) = ($1, $2, $3, $4);
        if ($txt eq $lst)
        { $lst = '';
        }
        elsif ($lvl && ($lvl -= $off) < $min)
        { $lst = '';
        }
        elsif (@ttl)
        { unshift (@toc, splice(@ttl), $lin);
        }
        elsif ($lvl > $lim)
        { print $sfh '   'x($lvl - $lim)."* $txt\n" unless $flg;
          $lst = '';
        }
        elsif ($lvl == $lim)
        { $dsc = ($txt =~ m/\[\[([^\[\]]*\]\[){1,2}(.*?)\]\]/) ? $2 : $txt;
          $lvl += length($str);
          if ($flg)
          { print $ifh '   'x$lvl."* $dsc\n";
          }
          else
          { if ($cnt++)
            { $idx = "#Idx$cnt";
              print $sfh "$idx\n";
            }
            else
            { $idx = '';
            }
            print $sfh "---+ $txt\n";
            print $ifh '   'x$lvl, "* [[$toc.htm$idx][rda_sub_index][$dsc]]\n";
          }
          $lst = '';
        }
        elsif ($lvl > 0)
        { print $ifh '   'x($lvl + length($str))."* $txt\n";
          $lst = '';
        }
        else
        { print $ifh "$txt\n";
        }
      }
      elsif ($lin =~ s/^\-://)
      { $lst = $lin;
      }
      elsif ($lin =~ m/^\%FOCUS(\-?\d+)?(:([1-9]\d*))?\%\s*$/)
      { $off = defined($1) ? $1 : 0;
        $min = defined($3) ? $3 : 1;
      }
      elsif ($lin =~ m/^\%INCLUDE\("([^"]+)"(,(\d+))?\)\%$/)
      { my ($fil, $str);

        $fil = RDA::Object::Rda->is_absolute($1)
          ? $1
          : RDA::Object::Rda->cat_file($rpt, $1);
        if (open(IN, "<$fil"))
        { if ($2 && $3 > 0)
          { $str = '+' x $3;
            unshift (@toc, splice(@ttl), splice(@stk),
              map {_indent_top($_, $str)} <IN>);
          }
          else
          { unshift (@toc, splice(@ttl), splice(@stk), <IN>);
          }
          close(IN);
        }
      }
      elsif ($lin =~ m/^\%LEVEL([1-9])\%\s*$/)
      { $lim = $1;
      }
      elsif ($lin =~ m/^\%POP(\d+)?\%\s*$/)
      { my $val = defined($1) ? $1 : 1;
        pop(@stk) while $val-- > 0;
      }
      elsif ($lin =~ m/^\%PUSH\("([^"]+)"\)\%\s*$/)
      { push(@stk, $1);
      }
      elsif ($lin =~ m/^\%SPLIT\%\s*$/)
      { # Insert the subindex bottom and render the subindex file
        _cat_index($sfh, $bot);
        close($sfh);
        $slf->gen_html("$toc.txt", "$toc Sub Index", 0, 1);

        # Create the next subindex file and insert subindex top
        $cnt = 0;
        $toc = sprintf("%s_%02d", $bas, ++$spl);
        $fil = RDA::Object::Rda->cat_file($rpt, "$toc.txt");
        $sfh->open($fil, $CREATE, $FIL_PERMS) or die
          "RDA-00305: Cannot create subindex format specifications:\n $!\n";
        chown($slf->{'_uid'}, $slf->{'_gid'}, $fil) if $slf->{'_own'};
        _cat_index($sfh, $top);
      }
      elsif ($lin =~ m/^\%TITLE\("([^"]+)"\)\%\s*$/)
      { push(@ttl, $1);
      }
      elsif ($lin =~ m/^\%UNTITLE(\d+)?\%\s*$/)
      { my $val = defined($1) ? $1 : 1;
        pop(@ttl) while $val-- > 0;
      }
      elsif ($lin !~ m/^#---\[.*\]---$/)
      { if (@ttl)
        { unshift (@toc, splice(@ttl), $lin);
        }
        else
        { print $sfh "$lin\n";
        }
      }
    }

    # Insert the subindex bottom and render the subindex file
    _cat_index($sfh, $bot);
    close($sfh);
    $slf->gen_html("$toc.txt", "$toc Sub Index", 0, 1);
  }
  $lst;
}

sub _del_files
{ my ($rpt, $tbl, $re) = @_;

  foreach my $nam (grep {$_ =~ $re} @$tbl)
  { my $fil = RDA::Object::Rda->cat_file($rpt, $nam);
    1 while unlink($fil);
  }
}

sub _indent_top
{ my ($lin, $str) = @_;

  $lin =~ s/^(1\+*):/$1$str:/;
  $lin;
}

=head2 S<$h-E<gt>gen_start([$sub[,$nam]])>

This method generates the start page. You can specify the default subindex
page and report name as arguments.

=cut

sub gen_start
{ my ($slf, $sub, $nam) = @_;
  my ($fil, $flg, $grp, $idx, $ofh, $rpt, $spl, $ver);

  # Initialization
  $flg = $slf->{'_cas'};
  $grp = $slf->{'_grp'};
  $spl = $slf->{'_spl'};
  $ver = $slf->{'_ver'};
  $ver .= " ($rpt)"
    if ($rpt = $slf->{'_cfg'}->get_host)
    && !$slf->{'_agt'}->get_setting('RDA_FILTER');

  $ofh = IO::File->new;
  $rpt = $slf->gen_directory;
  $nam = $slf->{'_frm'} unless defined($nam);
  $nam = "$grp\__blank.htm"
    unless -r RDA::Object::Rda->cat_file($rpt, $nam = "$grp\_$nam.htm")
        || -r RDA::Object::Rda->cat_file($rpt, $nam = "mrc/$nam");
  $idx = "$grp\__index.htm";
  if (defined($sub))
  { $sub =~ s/\.(toc|txt)$/.htm/i;
  }
  else
  { $sub = $grp.'__blank.htm';
  }
  unless ($flg)
  { $idx = lc($idx);
    $sub = lc($sub);
    $nam = lc($nam);
  }

  # Generate the frameset file
  $fil = "$grp\__start.htm";
  $fil = RDA::Object::Rda->cat_file($rpt, $flg ? $fil : lc($fil));
  $ofh->open($fil, $CREATE, $FIL_PERMS) ||
    die "RDA-00306: Cannot create the start file '$fil':\n $!\n";
  print {$ofh} "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Frameset//EN'
     'http://www.w3.org/TR/html4/frameset.dtd'>
    <html lang='en-US'><head>
     <meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
     <title>Remote Diagnostic Agent $ver</title>
    </head>
    <frameset cols='25%,*'>";
  if ($spl)
  { print {$ofh} "<frameset rows='30%,*'>
       <frame name='rda_index' src='$idx'
        frameborder=1 marginwidth=8 marginheight=1
        title='Main Index Frame'>
       <frame name='rda_sub_index' src='$sub'
        frameborder=1 marginwidth=8 marginheight=1
        title='Sub Index Frame'>
      </frameset>";
  }
  else
  { print {$ofh} "<frame name='rda_index' src='$idx'
                frameborder=1 marginwidth=8 marginheight=1
                title='Index Frame'>";
  }
  print {$ofh} "<frame name='rda_report' src='$nam'
              frameborder=1 marginwidth=8 marginheight=1
              title='Data Collected Report Frame'>
     <noframes>This page requires a frames capable browser to view.
     </noframes>
    </frameset>
    </html>";
  $ofh->close;
  chown($slf->{'_uid'}, $slf->{'_gid'}, $fil) if $slf->{'_own'};

  # Generate the blank page
  $fil = "$grp\__blank.htm";
  $fil = RDA::Object::Rda->cat_file($rpt, $flg ? $fil : lc($fil));
  $ofh->open($fil, $CREATE, $FIL_PERMS) ||
    die "RDA-00307: Cannot create the blank file '$fil':\n $!\n";
  print {$ofh} "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>
    <html lang='en-US'><head>
     <meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
     <title>Remote Diagnostic Agent $ver</title>
    </head><body>
    </body></html>";
  $ofh->close;
  chown($slf->{'_uid'}, $slf->{'_gid'}, $fil) if $slf->{'_own'};
}

=head2 S<$h-E<gt>get_handle($abr,$nam)>

This method returns the rendering pipe handle if the report must be rendered
immediately. Otherwise, it returns an undefined value.

=cut

sub get_handle
{ my ($slf, $abr, $nam) = @_;

  (exists($slf->{'_ofh'})
    && exists($slf->{'_rnd'}->{$abr})
    && $nam =~ $slf->{'_rnd'}->{$abr}) ? $slf->{'_ofh'} : undef;
}

=head2 S<$h-E<gt>get_reports($flg)>

This method retrieves all related reports that must be rendered. When the
flag is set, it returns all related reports.

=cut

sub get_reports
{ my ($slf, $flg) = @_;
  my ($re, $rpt, @tbl);

  # Initialization
  $re  = qr/^$slf->{'_grp'}\_[A-Za-z]\w*(-\d+)?\.(dat|txt)$/i;
  $rpt = $slf->{'_rpt'};

  # Scan the directory for report files
  if (opendir(DIR, $rpt))
  { @tbl = grep {_chk_report($rpt, $_, $re, $flg)} readdir(DIR);
    closedir(DIR);
  }

  # Return the files found
  @tbl;
}

sub _chk_report
{ my ($dir, $fil, $re, $flg) = @_;

  # Skip files that does not correspond to the report pattern
  return 0 unless $fil =~ $re;

  # Check the modification times, unless the flag is set
  unless ($flg)
  { my ($mt1, $mt2, $pth, @sta);

    @sta = stat($pth = RDA::Object::Rda->cat_file($dir, $fil));
    $mt1 = $sta[9];
    $pth =~ s/\.(dat|txt)$/.htm/i;
    @sta = stat($pth);
    $mt2 = $sta[9];
    return 0 if $mt1 && $mt2 && $mt1 <= $mt2;
  }
  1;
}

# --- Functions to emulate a file handle --------------------------------------

sub _not_implemented
{ return undef;
}

*blocking = \&_not_implemented;
*clearerr = \&_not_implemented;
*eof = \&_not_implemented;
*error = \&_not_implemented;
*fileno = \&_not_implemented;
*getc = \&_not_implemented;
*getline = \&_not_implemented;
*getlines = \&_not_implemented;
*getpos = \&_not_implemented;
*input_line_number = \&_not_implemented;
*opened = \&_not_implemented;
*printflush = \&_not_implemented;
*read = \&_not_implemented;
*seek = \&_not_implemented;
*setpos = \&_not_implemented;
*stat = \&_not_implemented;
*sync = \&_not_implemented;
*sysread = \&_not_implemented;
*sysseek = \&_not_implemented;
*syswrite = \&write;
*tell = \&_not_implemented;
*truncate = \&_not_implemented;
*ungetc = \&_not_implemented;
*untaint = \&_not_implemented;

sub autoflush
{ my $slf = shift;

  *$slf->{'rpt'}->autoflush(@_) if *$slf->{'fil'};
}

sub close
{ my $slf = shift;

  return 1 unless *$slf->{'fil'};
  *$slf->{'fil'} = 0;
  *$slf->{'sep'} = 1;
  *$slf->{'rpt'}->close;
}

sub flush
{ my $slf = shift;

  *$slf->{'rpt'}->flush if *$slf->{'fil'};
  *$slf->{'pip'}->flush;
}

sub open
{ my $slf = shift;

  *$slf->{'rpt'}->close if *$slf->{'fil'};
  *$slf->{'pip'}->print("---\n") if *$slf->{'sep'};
  *$slf->{'fil'} = *$slf->{'rpt'}->open(@_);
}

sub print
{ my $slf = shift;

  *$slf->{'rpt'}->print(@_) if *$slf->{'fil'};
  *$slf->{'pip'}->print(@_);
}

sub printf
{ my $slf = shift;
  my $fmt = shift;
  my $str;

  $str = sprintf($fmt, @_);
  *$slf->{'rpt'}->print($str) if *$slf->{'fil'};
  *$slf->{'pip'}->print($str);
}

sub write
{ my $slf = shift;

  *$slf->{'rpt'}->write(@_) if *$slf->{'fil'};
  *$slf->{'pip'}->write(@_);
}

sub BINMODE
{ my $slf = shift;

  binmode *$slf->{'rpt'}, @_ if *$slf->{'fil'};
}

*CLOSE = \&close;
*EOF = \&_not_implemented;
*FILENO = \&_not_implemented;
*GETC = \&_not_implemented;
*OPEN = \&open;
*PRINT = \&print;
*PRINTF = \&printf;
*READ = \&_not_implemented;
*READLINE = \&_not_implemented;
*SEEK = \&_not_implemented;
*TELL = \&_not_implemented;
*WRITE = \&write;

sub DESTROY
{
}

sub TIEHANDLE
{ shift;
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
