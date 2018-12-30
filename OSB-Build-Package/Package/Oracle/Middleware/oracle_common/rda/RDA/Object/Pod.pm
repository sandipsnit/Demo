# Pod.pm: Class Used for Managing Manual Pages

package RDA::Object::Pod;

# $Id: Pod.pm,v 2.12 2012/08/22 14:03:13 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Pod.pm,v 2.12 2012/08/22 14:03:13 mschenke Exp $
#
# Change History
# 20120822  KRA  Update MOS URL.

=head1 NAME

RDA::Object::Pod - Class Used for Managing Manual Pages

=head1 SYNOPSIS

require RDA::Object::Pod;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Pod> class are used to manage manual
pages. It is a sub class of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.12 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'display'   => {ret => 0},
    'render'    => {ret => 0},
    },
  );

# Define the global private constants
my $BEG = "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>
<html lang='en-US'><head>
<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>
<style type='text/css'>
<!--
.rda { font-size:9pt;
       font-family:sans-serif;
     }
.rda h1 { font-family:sans-serif;
          font-size:12pt;
          color:#333333;
          border-bottom-width:1px;
          border-bottom-style:solid;
          border-bottom-color:#c4d1e6;
          padding-top:4px;
        }
.rda h2 { font-family:sans-serif;
          font-size:11pt;
          color:#333333;
          padding-top:4px;
        }
.rda h3 { font-family:sans-serif;
          font-size:10pt;
          color:#666666;
        }
.rda h4 { font-family:sans-serif;
          font-size:9pt
          color:#666666;
        }
.rda input { font-size:9pt;
             font-family:sans-serif;
           }
.rda p { font-size:9pt;
         font-family:sans-serif;
       }
.rda table { border-style:none;
           }
.rda tr { padding-top:1px;
          padding-bottom:1px;
        }
.rda td { border-style:none;
          font-size:9pt;
          font-family:sans-serif;
          padding:2px;
          padding-top:1px;
          padding-bottom:1px;
          vertical-align:top;
        }
.rda a:hover { color:#ff2222;
             }
.rda_links td { font-size:9pt;
                padding:4px;
                vertical-align:top;
              }
.rda_links th { font-size:9pt;
                font-weight:bold;
                padding:4px;
                text-align:left;
                vertical-align:top
          }
.rda_links table { border-top-width:1px;
                   border-top-style:solid;
                   border-top-color:#c4d1e6;
                   border-left-width:1px;
                   border-left-style:solid;
                   border-left-color:#c4d1e6;
                 }
.rda_links td { border-right-width:1px;
                border-right-style:solid;
                border-right-color:#c4d1e6;
                border-bottom-width:1px;
                border-bottom-style:solid;
                border-bottom-color:#c4d1e6;
                font-size:9pt;
                padding:4px;
                vertical-align:top;
              }
.rda_links th { border-right-width:1px;
                border-right-style:solid;
                border-right-color:#c4d1e6;
                border-bottom-width:1px;
                border-bottom-style:solid;
                border-bottom-color:#c4d1e6;
                padding:4px;
                background-color:#dee6ef;
                font-size:9pt;
                font-weight:bold;
                text-align:left;
                vertical-align:top
              }
.rda_report table { border-style:solid;
                    border-width:1px;
                    border-color:#999966;
                    border-collapse:collapse;
                    border-spacing:0px;
                    empty-cells: show;
                  }
.rda_report td    { border-style:solid;
                    border-width:1px;
                    border-color:#999966;
                    font-size:9pt;
                    font-family:sans-serif;
                    padding:2px;
                  }
.rda_report th    { border-style:solid;
                    border-width:1px;
                    border-color:#999966;
                    background:#cccc99;
                    font-size:9pt;
                    font-family:sans-serif;
                    font-weight:bold;
                    padding:2px;
                    color:#336699
                  }
.rda_report tr    { vertical-align:top;
                  }

\# -->
</style>\n";

my $END = "<hr/><h1><a name='copyright_notice'>COPYRIGHT NOTICE</a></h1>
<p>Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.
</p><h1><a name='trademark_notice'>TRADEMARK NOTICE</a></h1>
<p>Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.</p>
<h1><a name='legal_notice'>LEGAL NOTICES AND TERMS OF USE</a></h1>
<p>By downloading and using RDA, you agree to the following: <a
href='https://support.oracle.com/rs?type=doc&id=225559.1'> Warranties and
Disclaimers</a>.</p>
<h1><a name='accessibility_notice'>DOCUMENTATION ACCESSIBILITY</a></h1>
<p>Our goal is to make Oracle products, services, and supporting documentation
accessible, with good usability, to the disabled community. To that end, our
documentation includes features that make information available to users of
assistive technology. This documentation is available in HTML format, and
contains markup to facilitate access by the disabled community. Standards will
continue to evolve over time, and Oracle is actively engaged with other
market-leading technology vendors to address technical obstacles so that our
documentation can be accessible to all of our customers. For additional
information, visit the Oracle Accessibility Program Web site at</p>
<p><a href='http://www.oracle.com/accessibility/'
>http://www.oracle.com/accessibility/</a></p>
<p><strong>Accessibility of Code Examples in Documentation</strong> JAWS, a
Windows screen reader, may not always correctly read the code examples in this
document. The conventions for writing code require that closing braces should
appear on an otherwise empty line; however, JAWS may not always read a line of
text that consists solely of a bracket or brace.</p>
<p><strong>Accessibility of Links to External Web Sites in
Documentation</strong> This documentation may contain links to Web sites of
other companies or organizations that Oracle does not own or control. Oracle
neither evaluates nor makes any representations regarding the accessibility of
these Web sites.</p></div></body></html>\n";

my $LNK = 'L<[^<>]+>|[^<>]*?>';

my $TOP ="<body><div class='rda'><p><a name='top'></a>
<!-- Oracle Remote Diagnostic Agent / Documentation 1.0 -->\n";

# Define acronyms
my $HCVE = "<acronym title='Health Check / Validation Engine'>HCVE</acronym>";
my $RDA  = "<acronym title='Remote Diagnostic Agent'>RDA</acronym>";
my $SDCL = "<acronym title='Support Diagnostic Collect Language'>".
           "SDCL</acronym>";
my $SDSL = "<acronym title='Support Diagnostic Setup Language'>".
           "SDSL</acronym>";

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Pod-E<gt>new($cfg)>

The object constructor. It takes the reference to RDA software configuration as
an argument.

C<RDA::Object::Pod> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'oid' > > Object identifier

=item S<    B<'_blk'> > Block indicator (_pod2text)

=item S<    B<'_cfg'> > Reference to the RDA software configuration

=item S<    B<'_off'> > Text offset (_pod2text)

=item S<    B<'_pre'> > Previous Tag text (_pod2text)

=item S<    B<'_reg'> > Applicable regions

=item S<    B<'_tag'> > Tag text (_pod2text)

=item S<    B<'_ver'> > RDA software version

=item S<    B<'_wdt'> > Page width parameter

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $cfg) = @_;
  my ($slf);

  # Create the render object
  $slf = bless {
    oid  => 'POD',
    _cfg => $cfg,
    _reg => {text => 1},
    _ver => $cfg->get_version,
    _wdt => $cfg->get_columns,
    }, ref($cls) || $cls;

  # Identify applicable regions
  if (exists($ENV{'RDA_MAN'}))
  { foreach my $key (split(/,/, $ENV{'RDA_MAN'}))
    { $slf->{'_reg'}->{$key} = 1 if $key;
    }
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>pod2text($ofh,$file)>

This method extracts the Plain Old Documentation (POD) blocks from the
specified file and converts them into formatted ASCII.

=cut

sub pod2text
{ my ($slf, $ofh, $fil) = @_;
  my ($cut, $dft, $flg, $hdr, $ifh, $max, $reg, @off);
  local $/   = "";    # Treat multiple empty lines as a single empty line

  $cut = 1;
  $dft = 4;
  $flg = 0;
  $hdr = '  ';
  $slf->{'_blk'} = 0;
  $slf->{'_off'} = $dft;

  # Extract the documentation and format it
  if (ref($fil))
  { $ifh = $fil;
  }
  else
  { $ifh = IO::File->new;
    $ifh->open("<$fil")
      or die "RDA-00402: Cannot open the manual file '$fil':\n $!\n"
  }
  while (<$ifh>)
  { # Extract the documentation
    if ($cut)
    { next unless m/^=/;
      $cut = 0;
    }
    if ($reg)
    { next unless m/^=end\s+$reg[\n\r\s]*$/;
      $reg = undef;
    }

    # Resolve attributes
    $max = 10;
    s#E<(\w+)>#\&$1;#g;
    while ($max-- && m/[A-Z]</)
    { s#L<([^|>]+)\|[^>]+>#$1#g;
      s#C<(.*?)>#"$1"#sg;
      s#I<(.*?)>#*$1*#sg;
      s#X<.*?>##sg;
      s#[A-Z]<(.*?)>#$1#sg;
    }
    s#\&amp;#&#g;
    s#\&lt;#<#g;
    s#\&gt;#>#g;
    s#\&verbar;#|#g;
    s#\&sol;#/#g;
    s#\&(0[0-7]{1,3}|0x[0-9A-Fa-f]{1,4});#chr(oct($1))#g;
    s#\&(\d+);#chr($1)#g;
    s/[\s\r\n]+$//;

    # Treat the pod directives
    if (s/^=(\S*)\s?//)
    { my $cmd = $1;

      if ($cmd eq 'cut')
      { $cut = 1;
      }
      elsif ($cmd eq 'pod')
      { $cut = 0;
      }
      elsif ($cmd eq 'head1')
      { _prt_buf($slf, $ofh, $_, 0);
      }
      elsif ($cmd eq 'head2' || $cmd eq 'head3')
      { _prt_buf($slf, $ofh, $hdr.$_, 0);
      }
      elsif ($cmd eq 'over')
      { $slf->{'_pre'} = $slf->{'_tag'} if exists($slf->{'_tag'});
        unshift(@off, $slf->{'_off'});
        $slf->{'_off'} += ($_ + 0) || $dft;
        $flg = 1;
      }
      elsif ($cmd eq 'back')
      { _prt_blk($slf, $ofh, '', 1) if exists($slf->{'_tag'});
        $slf->{'_off'} = shift(@off) || $dft;
        $flg = 0;
      }
      elsif ($cmd eq 'item')
      { my ($lgt, $off, $tag);

        _prt_blk($slf, $ofh, '', 0) if exists($slf->{'_tag'});
        $off = $slf->{'_off'};
        $tag = exists($slf->{'_pre'}) ? delete($slf->{'_pre'}) :
          ' ' x ($off[0] || $dft);
        s/\n/ /g;
        $tag .= $_.' ';
        for ($lgt = length($tag) ; $lgt < $off ; ++$lgt)
        { $tag .= ' ';
        }
        $slf->{'_blk'} = 0 unless $flg;
        $slf->{'_tag'} = $tag;
        $flg = 0;
      }
      elsif ($cmd eq 'begin')
      { if (!exists($slf->{'_reg'}->{$_}))
        { $reg = $_;
        }
        elsif ($_ eq 'credits')
        { _prt_buf($slf, $ofh, 'CREDITS', 0);
        }
      }
    }
    elsif (m/^\s+/)
    { my ($pre);

      _prt_blk($slf, $ofh, '', 0) if exists($slf->{'_tag'});
      $pre = ' ' x $slf->{'_off'};
      s/\n/\n$pre/g;
      _prt_buf($slf, $ofh, "$pre$_", 1);
    }
    else
    { _prt_blk($slf, $ofh, $_, 1);
    }
  }
  close($ifh);
}

sub _prt_blk
{ my ($slf, $ofh, $str, $nxt) = @_;
  my ($buf, $lgt, $off);

  $off = $slf->{'_off'};
  if (exists($slf->{'_tag'}))
  { $lgt = length($buf = delete($slf->{'_tag'}));
    if ($lgt > $off)
    { $buf .= $str;
      ($buf, $str) = ($buf =~ m/^(\s*\S+\s)(.*)/);
      $lgt = length($buf);
    }
  }
  elsif (exists($slf->{'_pre'}))
  { $lgt = length($buf = delete($slf->{'_pre'}));
  }
  else
  { $buf = ' ' x ($lgt = $off);
  }

  foreach my $wrd (split(/\s/, $str))
  { $lgt += length($wrd);
    if ($lgt > $slf->{'_wdt'})
    { _prt_buf($slf, $ofh, $buf, 0);
      $buf = ' ' x $off;
      $lgt = $off + length($wrd);
    }
    $buf .= $wrd;
    $buf .= ' ';
    ++$lgt;
  }

  if ($lgt)
  { _prt_buf($slf, $ofh, $buf, $nxt);
  }
  else
  { $slf->{'_blk'} = $nxt;
  }
}

sub _prt_buf
{ my ($slf, $ofh, $buf, $nxt) = @_;

  $buf =~ s/\s+$//;
  $buf .= "\n";
  $buf = "\n$buf" if $slf->{'_blk'};
  $slf->{'_blk'} = $nxt;
  syswrite($ofh, $buf, length($buf));
}

sub _prt_str
{ my ($ofh, $str) = @_;

  syswrite($ofh, $str, length($str));
}

=head2 S<$h-E<gt>pod2html($ofh,$name,$file[,$fct])>

This method extracts the POD blocks from the specified file and converts them
into HTML. You can specify a function to convert the links as an extra
argument.

=cut

sub pod2html
{ my ($slf, $ofh, $nam, $fil, $fct) = @_;
  my ($cut, $flg, $ifh, $max, $off, $reg, $str, $tag, @tbl);
  local $/   = "";    # Treat multiple empty lines as a single empty line

  $cut = $off = 2;
  $fct = \&_fmt_link unless defined($fct);
  $flg = 0;
  $tag = [0, '<p>', "</p>\n", '<p>', "</p>\n"];

  # Extract the documentation and format it
  if (ref($fil))
  { $ifh = $fil;
  }
  else
  { $ifh = IO::File->new;
    $ifh->open("<$fil")
      or die "RDA-00402: Cannot open the manual file '$fil':\n $!\n"
  }
  while (<$ifh>)
  { # Extract the documentation
    if ($cut)
    { next unless m/^=/;
      $cut = 0;
    }
    if ($reg)
    { next unless m/^=end\s+$reg[\n\r\s]*$/;
      $reg = undef;
    }

    # Resolve attributes
    $max = 10;
    s#\&#\&amp;#g;
    s#E<(\w+)>#\&$1;#g;
    s#^(\s*)((<|require |use |(rda|sdp)\.\w+ ).*)$#
      "$1\001code\002"._fmt_space($2)."\001/code\002"#sge; #
    s#B<(\s*)>#$1#sg;
    s#^(=item(\s+o)?\s+S<\s*B<\s*)($LNK|[^<>]*?)\s*>\s*>\s*(\S.*)#$1$3>>\003$4#s
    || s#^(=item(\s+o)?\s+B<\s*)($LNK|[^<>]*?)\s*>\s*(\S.*)#$1$3>\003$4#s;
    while ($max-- && /[A-Z]</)
    { s#L<([^|>]+)\|([^>]+)>#&{$fct}($1,$2)#sge;
      s#B<(.*?)>#"\001strong\002\001tt\002"._fmt_space($1, 1).
        "\001/tt\002\001/strong\002"#sge;
      s#[CFL]<(.*?)>#"\001code\002"._fmt_space($1)."\001/code\002"#sge;
      s#I<(.*?)>#\001em\002$1\001/em\002#sg;
      s#S<(.*?)>#_fmt_space($1)#sge;
      s#X<.*?>##sg;
      s#[A-Z]<(.*?)>#$1#sg;
    }
    s/</&lt;/g;
    s/>/&gt;/g;
    s/\001/</g;
    s/\002/>/g;
    s/[\s\r\n]+$//;

    # Treat the pod directives
    if (s/^=(\S*)\s?//)
    { my $cmd = $1;

      if ($cmd eq 'cut')
      { $cut = 1;
      }
      elsif ($cmd eq 'pod')
      { $cut = 0;
      }
      elsif ($cmd eq 'head1')
      { if (m/(COPYRIGHT|TRADEMARK) NOTICE/)
        { $cut = 1;
        }
        elsif (m/^NAME$/)
        { $str = _fmt_name($nam);
          _prt_str($ofh, "<h1><a id='$str' name='$str'>$nam</a></h1>\n");
        }
        else
        { _prt_str($ofh, "<h2>$_</h2>\n");
        }
      }
      elsif ($cmd eq 'head2')
      { _prt_str($ofh, "<h3>$_</h3>\n");
      }
      elsif ($cmd eq 'head3')
      { _prt_str($ofh, "<h4>$_</h4>\n");
      }
      elsif ($cmd eq 'over')
      { unshift(@tbl, $tag);
        _prt_str($ofh,
          "<table summary=\'\'><tr><td style=\'white-space:nowrap\'>\n");
        $tag = [1,
                "<br/>\n",
                '',
                "</td></tr>\n<tr><td style=\'white-space:nowrap\'>",
                "</td>\n<td>",
                ''];
        $flg = 1;
        $off = 5;
      }
      elsif ($cmd eq 'back')
      { if ($tag = shift(@tbl))
        { _prt_str($ofh, "</td></tr></table>\n");
        }
        else
        { $tag = [0, '<p>', "</p>\n", '<p>', "</p>\n"];
        }
        $flg = $tag->[0];
        $off = 3;
      }
      elsif ($cmd eq 'item')
      { s/^(\s*)[o\*](\s|\z)/$1&middot;\003/;
        s/\003/$tag->[4]/g;
        _prt_str($ofh, $tag->[$off].$_.$tag->[4]);
        $off = 3;
        $flg = 1;
      }
      elsif ($cmd eq 'begin')
      { if (!exists($slf->{'_reg'}->{$_}))
        { $reg = $_;
        }
        elsif ($_ eq 'credits')
        { _prt_str($ofh, "<h1>CREDITS</h1>\n");
        }
      }
    }
    elsif (m/^\s+/)
    { ($flg, $str) = ($flg < 0) ? ($flg, $tag->[1]) : (-$flg, '');
      s#\n#<br/>#g;
      _prt_str($ofh, $str."<tt>"._fmt_space($_)."</tt>\n");
    }
    else
    { ($flg, $str) = ($flg > 0) ? (-$flg, '') : ($flg, $tag->[1]);
      _prt_str($ofh, $str.$_.$tag->[2]);
    }
  }
  while ($tag = shift(@tbl))
  { _prt_str($ofh, "</td></tr></table>\n");
  }
  $ifh->close;
}

=head2 S<$h-E<gt>render($ofh,$def)>

This method converts the specified documentation in the POD format into
HTML. The definition hash can contain the following keys:

=over 11

=item B<    'det' > List of files to render

=item B<    'fct' > Function to format links

=item B<    'nam' > Page name

=item B<    'rel' > List of related links

=item B<    'tab' > List of main links

=item B<    'ttl' > Page title

=back

A link item is represented by a scalar, used as text, or by an array reference
containing the text and URL.

=cut

sub render
{ my ($slf, $ofh, $def) = @_;
  my ($buf, $col, $fct, $nam, $src, $tbl, $ttl, $val, @arg);

  # Initialization
  $fct = $def->{'fct'} || \&_fmt_link;
  $nam = _fmt_name($def->{'nam'} || '');
  $ttl = $def->{'ttl'} || 'RDA Documentation';

  # Start the page
  unless ($def->{'dsp'})
  { $buf = $BEG."<title>$ttl</title></head>\n".$TOP."<h1>$RDA ".$slf->{'_ver'}
      ." - $ttl</h1>\n";
    syswrite($ofh, $buf, length($buf));
  }

  # Add the tab section
  if (ref($tbl = $def->{'tab'}) eq 'ARRAY' && ($col = scalar @$tbl))
  { $buf = "<div class='rda_links'><table border='0' cellspacing='0'"
      ." cellpadding='0' summary='Main Links' width='100%'>\n"
      ."<tr><th colspan='$col'>$RDA Main Links</th></tr><tr>\n";
    $val = int(100 / $col);
    foreach my $det (@$tbl)
    { if (!ref($det))
      { $buf .= "<td align='center' width='$val%'><strong>"
          ._fmt_abbr($det)."</strong></td>\n";
      }
      elsif ($det->[2] eq $nam)
      { $buf .= "<td align='center' width='$val%'><strong>"
          ._fmt_abbr($det->[0])."</strong></td>\n";
      }
      else
      { $buf .= "<td align='center' width='$val%'><a href='".$det->[1]."'>"
          ._fmt_abbr($det->[0])."</a></td>\n";
      }
    }
    $buf .= "</tr></table></div>\n";
    syswrite($ofh, $buf, length($buf));
  }

  # Add the related link section
  if (ref($tbl = $def->{'rel'}) eq 'ARRAY')
  { $buf = "<h1>Related Links</h1>\n"._rel2html($tbl, $nam);
    syswrite($ofh, $buf, length($buf));
  }

  # Add the page content
  foreach my $det (@{$def->{'det'}})
  { if (ref($src = $det->[1]) eq 'ARRAY')
    { ($src, @arg) = @$src;
      &$src($ofh, @arg);
    }
    else
    { pod2html($slf, $ofh, $det->[0], $src, $fct);
    }
  }

  # Terminate the page with all notices
  _prt_str($ofh, $END) unless $def->{'dsp'};
}

sub _rel2html
{ my ($tbl, $nam) = @_;
  my ($buf);

  $buf = "<table summary='Related Links'><tr>\n";
  foreach my $det (@$tbl)
  { if (ref($det))
    { $buf .= "<td>"._idx2html($det, $nam)."</td>\n";
    }
    else
    { $buf .= "<td>"._fmt_abbr($det)."</td>\n";
    }
  }
  $buf .= "\n</tr></table>\n";
  $buf;
}

sub _idx2html
{ my ($tbl, $nam) = @_;
  my ($buf);

  $buf = "<ul>\n";
  foreach my $det (@$tbl)
  { if (!ref($det))
    { $buf .= "<li>"._fmt_abbr($det)."</li>\n";
    }
    elsif ($det->[2] eq $nam)
    { next;
    }
    elsif (ref($det->[1]))
    { $buf .= "<li>"._fmt_abbr($det->[0])._idx2html($det->[1], $nam)."</li>\n";
    }
    else
    { $buf .= "<li><a href='".$det->[1]."'>"._fmt_abbr($det->[0])."</a></li>\n";
    }
  }
  $buf .= "</ul>\n";
  $buf;
}

# Document abbreviations and acronyms
sub _fmt_abbr
{ my ($txt) = @_;

  $txt =~ s#\bHCVE\b#$HCVE#gs;
  $txt =~ s#\bRDA\b#$RDA#gs;
  $txt =~ s#\bSDCL\b#$SDCL#gs;
  $txt =~ s#\bSDSL\b#$SDSL#gs;
  $txt;
}

# Generate a link
sub _fmt_link
{ shift;
}

# Generate an anchor
sub _fmt_name
{ my ($str) = @_;
  $str =~ s#\.\w+$##;
  $str =~ s#\.[\/\\]##;
  $str =~ s#[\/\\]#::#g;
  $str =~ s#[_\s]+#_#g;
  $str;
}

# Replace the spaces by non blanking spaces
sub _fmt_space
{ my ($str, $flg) = @_;
  $str =~ s/'//g if $flg;
  $str =~ s/\s/&nbsp;/g;
  $str =~ s/a&nbsp;href=/a href=/g;
  $str;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
