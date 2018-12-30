# Sgml.pm: Class Used for Objects to Manage SGML Data

package RDA::Object::Sgml;

# $Id: Sgml.pm,v 2.11 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Sgml.pm,v 2.11 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Sgml - Class Used for Objects to Manage SGML Data

=head1 SYNOPSIS

require RDA::Object::Sgml;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Sgml> class are used to manage SGML data. It
regroups the methods common to the C<RDA::Object::Html> and C<RDA::Object::Xml>
classes.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use IO::File;
}

use strict;

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

# Define common entities
my %tb_ent = (
  # Normal characters that have a special meaning in SGML context
  'quot'  => 042, # double quote
  'amp'   => 046, # ampersand
  'apos'  => 047, # single quote
  'lt'    => 074, # less than
  'gt'    => 076, # greater than

  # ISO 8859-1 characters
  'nbsp'   => 0240, # non breaking space
  'iexcl'  => 0241, # inverted exclamation point
  'cent'   => 0242, # Cent sign
  'pound'  => 0243, # Pound sign
  'curren' => 0244, # currency sign
  'yen'    => 0245, # Yen sign
  'brvbar' => 0246,
  'sect'   => 0247, # section sign
  'uml'    => 0250,
  'copy'   => 0251, # copyright sign
  'ordf'   => 0252,
  'laquo'  => 0253,
  'not'    => 0254, # not sign
  'shy'    => 0255,
  'reg'    => 0256, # registered sign
  'macr'   => 0257, # macron sign
  'deg'    => 0260, # degre sign
  'plusmn' => 0261, # plus/minus sign
  'sup2'   => 0262, # superscript 2
  'sup3'   => 0263, # superscript 3
  'acute'  => 0264, # acute sign
  'micro'  => 0265,
  'para'   => 0266, # paragraph sign
  'middot' => 0267, # mid dot
  'cedil'  => 0270, # cedilla sign
  'sup1'   => 0271, # superscript 1
  'ordm'   => 0272,
  'raquo'  => 0273,
  'frac14' => 0274, # fraction 1/4
  'frac12' => 0275, # fraction 1/2
  'frac34' => 0276, # fraction 3/4
  'iquest' => 0277, # inverted question mark
  'Agrave' => 0300, # uppercase A, grave accent
  'Aacute' => 0301, # uppercase A, acute accent
  'Acirc'  => 0302, # uppercase A, circumflex accent
  'Atilde' => 0303, # uppercase A, tilde
  'Auml'   => 0304, # uppercase A, dieresis or umlaut mark
  'Aring'  => 0305, # uppercase A, ring
  'AElig'  => 0306, # uppercase AE diphthong (ligature)
  'Ccedil' => 0307, # uppercase C, cedilla
  'Egrave' => 0310, # uppercase E, grave accent
  'Eacute' => 0311, # uppercase E, acute accent
  'Ecirc'  => 0312, # uppercase E, circumflex accent
  'Euml'   => 0313, # uppercase E, dieresis or umlaut mark
  'Igrave' => 0314, # uppercase I, grave accent
  'Iacute' => 0315, # uppercase I, acute accent
  'Icirc'  => 0316, # uppercase I, circumflex accent
  'Iuml'   => 0317, # uppercase I, dieresis or umlaut mark
  'ETH'    => 0320, # uppercase Eth, Icelandic
  'Ntilde' => 0321, # uppercase N, tilde
  'Ograve' => 0322, # uppercase O, grave accent
  'Oacute' => 0323, # uppercase O, acute accent
  'Ocirc'  => 0324, # uppercase O, circumflex accent
  'Otilde' => 0325, # uppercase O, tilde
  'Ouml'   => 0326, # uppercase O, dieresis or umlaut mark
  'times'  => 0327, # times sign
  'Oslash' => 0330, # uppercase O, slash
  'Ugrave' => 0331, # uppercase U, grave accent
  'Uacute' => 0332, # uppercase U, acute accent
  'Ucirc'  => 0333, # uppercase U, circumflex accent
  'Uuml'   => 0334, # uppercase U, dieresis or umlaut mark
  'Yacute' => 0335, # uppercase Y, acute accent
  'THORN'  => 0336, # uppercase THORN, Icelandic
  'szlig'  => 0337, # lowercase sharp s, German (sz ligature)
  'agrave' => 0340, # lowercase a, grave accent
  'aacute' => 0341, # lowercase a, acute accent
  'acirc'  => 0342, # lowercase a, circumflex accent
  'atilde' => 0343, # lowercase a, tilde
  'auml'   => 0344, # lowercase a, dieresis or umlaut mark
  'aring'  => 0345, # lowercase a, ring
  'aelig'  => 0346, # lowercase ae diphthong (ligature)
  'ccedil' => 0347, # lowercase c, cedilla
  'egrave' => 0350, # lowercase e, grave accent
  'eacute' => 0351, # lowercase e, acute accent
  'ecirc'  => 0352, # lowercase e, circumflex accent
  'euml'   => 0353, # lowercase e, dieresis or umlaut mark
  'igrave' => 0354, # lowercase i, grave accent
  'iacute' => 0355, # lowercase i, acute accent
  'icirc'  => 0356, # lowercase i, circumflex accent
  'iuml'   => 0357, # lowercase i, dieresis or umlaut mark
  'eth'    => 0360, # lowercase eth, Icelandic
  'ntilde' => 0361, # lowercase n, tilde
  'ograve' => 0362, # lowercase o, grave accent
  'oacute' => 0363, # lowercase o, acute accent
  'ocirc'  => 0364, # lowercase o, circumflex accent
  'otilde' => 0365, # lowercase o, tilde
  'ouml'   => 0366, # lowercase o, dieresis or umlaut mark
  'divide' => 0367, # divide sign
  'oslash' => 0370, # lowercase o, slash
  'ugrave' => 0371, # lowercase u, grave accent
  'uacute' => 0372, # lowercase u, acute accent
  'ucirc'  => 0373, # lowercase u, circumflex accent
  'uuml'   => 0374, # lowercase u, dieresis or umlaut mark
  'yacute' => 0375, # lowercase y, acute accent
  'thorn'  => 0376, # lowercase thorn, Icelandic
  'yuml'   => 0377, # lowercase y, dieresis or umlaut mark
);

# Define the reverse mapping
my @tb_ent;
foreach my $val (0 .. 31)
{ $tb_ent[$val] = sprintf('&#x%X;', $val);
}
foreach my $val (32 .. 126)
{ $tb_ent[$val] = chr($val);
}
foreach my $val (127 .. 159)
{ $tb_ent[$val] = sprintf('&#x%X;', $val);
}
while (my ($key, $val) = each(%tb_ent))
{ $tb_ent[$val] = "&$key;";
}
foreach my $val (37, 39, 40, 41, 91, 93, 123, 124, 125)
{ $tb_ent[$val] = sprintf('&#x%X;', $val);
}

# Add additional entities

=head2 S<$h = RDA::Object::Sgml-E<gt>new($type[,$prefix[,$level]])>

The object constructor.

C<RDA::Object::Sgml> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'-bak'> > Item backup stack

=item S<    B<'-buf'> > Input buffer

=item S<    B<'-crf'> > Trailing carriage return indicator

=item S<    B<'-cur'> > Current parent object

=item S<    B<'-dat'> > Data information

=item S<    B<'-det'> > Child object array

=item S<    B<'-err'> > Error count

=item S<    B<'-flg'> > Item indicator

=item S<    B<'-flt'> > Type filter hash

=item S<    B<'-lst'> > Last item reference

=item S<    B<'-lvl'> > Trace level

=item S<    B<'-nam'> > Item name

=item S<    B<'-pre'> > Trace prefix

=item S<    B<'-sta'> > Exit status of the last command

=item S<    B<'-stk'> > Item stack

=item S<    B<'-txt'> > Text normalization indicator

=item S<    B<'-typ'> > Item type

=back

Possible item types are as follows:

=over 12

=item S<    B<'B' > > Conditional section           (XML)

=item S<    B<'C' > > CData                         (XML)

=item S<    B<'D' > > Declaration             (HTML, XML)

=item S<    B<'E' > > Entity                        (XML)

=item S<    B<'H' > > HTML root item          (HTML)

=item S<    B<'P' > > Processing instruction        (XML)

=item S<    B<'R' > > Remark, Comment         (HTML, XML)

=item S<    B<'S' > > String, Text fragment   (HTML, XML)

=item S<    B<'T' > > Element tag             (HTML, XML)

=item S<    B<'X' > > XML root item                 (XML)

=back

=cut

sub new
{ my ($cls, $typ, $pre, $dbg) = @_;

  # Create the object
  my $slf = bless {
    -buf => '',
    -dat => '',
    -err => 0,
    -flt => {},
    -lvl => 0,
    -pre => $pre || 'TRC> ',
    -stk => [],
    -txt => 1,
    -typ => $typ,
    }, $cls;

  # Perform extra initialization
  $slf->set_trace($dbg);
  $slf->{'-cur'} = $slf->{'-lst'} = $slf;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>disable($flt)>

This method indicates the list of child types to ignore. When the list is
empty, it disables any type filtering. It returns the parser object reference.

=cut

sub disable
{ my ($slf, $flt) = @_;

  # Update the type filter list
  $slf->{'-flt'} = {};
  if ($flt)
  { map {$slf->{'-flt'}->{uc($_)} = 1} split(/ */, $flt);
  }

  # Return the object reference
  $slf;
}

=head1 PARSING METHODS

=head2 S<$h-E<gt>add_item($typ[,...])>

This method adds an item to the item tree.

=cut

sub add_item
{ my $top = shift;
  my $typ = shift;
  my ($key, $slf, $val);

  # Check if the type must be ignored
  return undef if exists($top->{'-flt'}->{$typ});

  # Insert pending text
  $top->add_text;

  # Create the object
  print $top->{'-pre'}."** Add item $typ(".join(',', @_).")\n"
    if $top->{'-lvl'};
  $slf = bless { -typ => $typ, -txt => $top->{'-cur'}->{'-txt'} }, ref($top);

  # Add the initial attributes
  while (($key, $val) = splice(@_, 0, 2))
  { $val = $key unless defined $val;
    $slf->{$key} = $val;
  }

  # Link elements
  push(@{$top->{'-cur'}->{'-det'}}, $slf);
  $top->{'-lst'} = $slf;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>add_text($text)>

This method adds a text item to the item tree.

=cut

sub add_text
{ my ($slf, $txt) = @_;

  if (defined($txt))
  { $slf->{'-dat'} .= $txt;
    print $slf->{'-pre'}.'++ Add text fragment '._fmt_str($txt)."\n"
      if $slf->{'-lvl'};
  }
  elsif (length($txt = $slf->{'-dat'}))
  { # Normalize the string
    if ($slf->{'-cur'}->{'-txt'} > 0)
    { $txt =~ s/\n/ /g;
      $txt =~ s/^\s+//g;
      $txt =~ s/\s+/ /g;
    }
    elsif ($slf->{'-cur'}->{'-txt'} < 0)
    { $txt =~ s/\s+$//;
      $txt =~ s/\n+$//;
      $txt =~ s/^\s*\n+$//;
    }

    # Add a text element
    $slf->{'-dat'} = '';
    $slf->add_item('S', -dat => $slf->decode($txt)) if length($txt);
  }
}

=head2 S<$h-E<gt>debug($msg)>

This method displays a debug message and the first characters from the parser
buffer.

=cut

sub debug
{ my $slf = shift;
  my $msg = shift;

  print "$msg: "._fmt_str(substr($slf->{'-buf'}, 0, 32).'...')."\n";
}

=head2 S<$h-E<gt>fmt_str($str)>

This method formats a string to be included in debug messages or dumps.

=cut

sub fmt_str
{ my ($slf, $str) = @_;

  _fmt_str($str);
}

sub _fmt_str
{ my ($str) = @_;

  $str =~ s#\\#\\\\#g;
  $str =~ s#'#\\'#g;
  $str =~ s#\f#\\f#g;
  $str =~ s#\n#\\n#g;
  $str =~ s#\r#\\r#g;
  $str =~ s#\t#\\t#g;
  "'".$str."'";
}

=head2 S<$h-E<gt>pop_item>

This method pops an item from the parsing stack.

=cut

sub pop_item
{ my ($slf) = @_;

  $slf->{'-cur'} = $slf->{'-lst'} = pop(@{$slf->{'-stk'}}) || $slf;
}

=head2 S<$h-E<gt>push_item>

This method pushes an item in the parsing stack.

=cut

sub push_item
{ my ($slf) = @_;

  push(@{$slf->{'-stk'}}, $slf->{'-cur'});
  $slf->{'-cur'} = $slf->{'-lst'};
}

=head2 S<$h-E<gt>restore_stack>

This method restores the parsing stack backup.

=cut

sub restore_stack
{ my ($slf) = @_;

  if (exists($slf->{'-bak'}))
  { $slf->{'-stk'} = $slf->{'-bak'};
    $slf->{'-lst'} = pop(@{$slf->{'-stk'}});
    $slf->{'-cur'} = pop(@{$slf->{'-stk'}});
  }
}

=head2 S<$h-E<gt>save_stack>

This method takes a backup of the parsing stack.

=cut

sub save_stack
{ my ($slf) = @_;

  $slf->{'-bak'} = [ @{$slf->{'-stk'}}, $slf->{'-cur'}, $slf->{'-lst'} ];
}

=head1 TREE METHODS

=head2 S<$h-E<gt>as_string([$flg])>

This method returns the object tree as a string. When the flag is set, the
conditional sections appear as though other nodes and conditions are not
resolved.

=cut

sub as_string
{ my $slf = shift;
  my $flg = shift;
  my $lvl = shift || 0;
  my $buf = '';

  $slf->_traverse(0, $flg, \&_as_string, \$buf);
  $buf;
}

sub _as_string
{ my ($slf, $lvl, $flg, $buf) = @_;

  $slf->_dump_item($buf, '', $lvl) if $flg;
  1;
}

=head2 S<$h-E<gt>dump>

This method dumps the item tree. It returns a reference to the parser object.

=cut

sub dump
{ my ($slf, $lvl) = @_;
  my ($buf);

  $buf = '';
  $lvl = 0 unless defined($lvl);;
  $slf->_traverse(0, 1, \&_dump, \$buf, '  ' x $lvl);
  $buf;
}

sub _dump
{ my ($slf, $lvl, $flg, $buf, $pre) = @_;

  $slf->_dump_item($buf, $pre, $lvl) if $flg;
  1;
}

sub _dump_item
{ my ($slf, $buf, $pre, $lvl) = @_;

  $$buf .= "\n" if $$buf;
  $$buf .= $pre;
  $$buf .= '..' x $lvl;
  $$buf .= '['.$slf->{'-typ'}.']';
  $$buf .= ' '.$slf->{'-nam'} if exists($slf->{'-nam'});
  $$buf .= ' '._fmt_str($slf->{'-dat'})
    if index('HX', $slf->{'-typ'}) < 0 && exists($slf->{'-dat'});
  for (sort keys(%$slf))
  { $$buf .= " $_="._fmt_str($slf->{$_}) unless m/^-/;
  }
}

=head2 S<$h-E<gt>exists($attr)>

This function indicates whether the attribute exists in the specified node.

=cut

sub exists
{ my ($slf, $att) = @_;

  exists($slf->{$att});
}

=head2 S<$h-E<gt>find($qry)>

This method finds nodes corresponding to the specified criteria. It returns a
list of XML object references. The criteria can be composed of the following:

=over 2

=item *

C<.../> or C</.../>, which indicate that the following tag must be searched
recursively in all child nodes.

=item *

C</>, which indicates that the following tag should only be searched in the
child node.

=item *

C<|.../>, which indicates that the following tag must be searched recursively
in all child nodes. Moreover, the following criteria are used only to reduce
the current result set.

=item *

C<|>, which indicates that the following tag should only be searched in the
child node. Moreover, the following criteria are used only to reduce the
current result set.

=item *

The tag to find.

=item *

An optional list of attributes that the element must match also. They are
specified as a list of attribute specifications, each composed of the attribute
name, an C<=> sign, and a regular expression placed between single or double
quotes.

=item *

An optional condition on the associated data must match. It is composed of
C<*=> followed by the regular expression placed between simple or double
quotes.

=item *

An optional position constraint to select a single element from that hit
list. It is specified as an offset placed between square brackets. The first
list element corresponds to a zero offset. A number less than zero indicates
an offset the end of the list.

=back

For example,

  .../tag1/tag2 attr1='re1' attr2="re2" [-1]|.../tag3 *="re3"

=cut

sub find
{ my ($slf, $qry) = @_;
  my ($cur, $off, $tbl, @prv, @qry, @sel, @tbl);

  # Decode the query string
  $tbl = \@qry;
  while (length($qry))
  { if ($qry =~ s#^\/*\.\.\.\/+##)
    { push(@$tbl, $cur = [ 1, '?', {} ]);
    }
    elsif ($qry =~ s#^\|+\/*\.\.\.\/+##)
    { $tbl = \@sel;
      push(@$tbl, $cur = [ 1, '?', {} ]);
    }
    elsif ($qry =~ s#^\/+##)
    { push(@$tbl, $cur = [ 0, '?', {} ]);
    }
    elsif ($qry =~ s#^\|+\/*##)
    { $tbl = \@sel;
      push(@$tbl, $cur = [ 0, '?', {} ]);
    }
    elsif ($qry =~ s#^([A-Za-z:_][A-Za-z0-9:_\.\-]*)=([\042\047])(.*?)\2\s*##)
    { push(@$tbl, $cur = [ 0, '?', {} ]) unless $cur;
      $cur->[2]->{$1} = qr#$3#;
    }
    elsif ($qry =~ s#^([A-Za-z:_][A-Za-z0-9:_\.\-]*)\s*##)
    { push(@$tbl, $cur = [ 0, '?', {} ]) unless $cur;
      $cur->[1] = $1;
    }
    elsif ($qry =~ s#^\*=([\042\047])(.*?)\1\s*##)
    { push(@$tbl, $cur = [ 0, '?', {} ]) unless $cur;
      $cur->[3] = qr#$2#;
    }
    elsif ($qry =~ s#^\[(\-?\d+)\]\s*##)
    { push(@$tbl, $cur = [ 0, '?', {} ]) unless $cur;
      $cur->[4] = $1;
    }
    else
    { return ();
    }
  }

  # Apply the search criteria
  @tbl = _search(\@qry, $slf);

  # Apply the restrictions
  @tbl = grep {scalar _search(\@sel, $_)} @tbl if @sel;

  # Return the objects found
  @tbl;
}

sub _find
{ my ($slf, $lvl, $flg, $tbl, $cur) = @_;

  # Skip root item and scan next element at same level
  return 1 unless $flg && $lvl;

  # Analyse the node
  return $cur->[0] unless $slf->{'-typ'} eq 'T' &&
    exists($slf->{'-nam'}) && $slf->{'-nam'} eq $cur->[1];
  foreach my $key (keys(%{$cur->[2]}))
  { return $cur->[0]
      unless exists($slf->{$key}) && $slf->{$key} =~ $cur->[2]->{$key};
  }
  push(@$tbl, $slf) unless defined($cur->[3]) && $slf->get_data !~ $cur->[3];
  $cur->[0];
}

sub _search
{ my ($tbl, @tbl) = @_;
  my ($off, @prv);

  foreach my $cur (@$tbl)
  { @prv = @tbl;
    @tbl = ();
    foreach my $obj (@prv)
    { $obj->traverse(\&_find, \@tbl, $cur);
    }
    if (defined($off = $cur->[4]))
    { $off = $#tbl + $off + 1 if $off < 0;
      @tbl = ($off < 0 || $off > $#tbl) ? () : ($tbl[$off]);
    }
  }
  @tbl;
}

=head2 S<$h-E<gt>get_attr>

This function returns the list of node attributes.

=cut

sub get_attr
{ my ($slf) = @_;
  my @tbl;

  @tbl = grep {m/^[^-]/} keys(%$slf);
  sort @tbl;
}

=head2 S<$h-E<gt>get_content([$flt[,cln]])>

This method returns the list of child nodes after resolving the conditions. The
second argument specifies the list of child types to consider. The third
argument specifies a regular expression to identify objects that must be
replaced by their content. By default, it returns all child nodes.

=cut

sub get_content
{ my ($slf, $flt, $cln) = @_;
  my @tbl;

  if (exists($slf->{'-det'}))
  { for (@{$slf->{'-det'}})
    { if ($_->{'-typ'} eq 'B')
      { push (@tbl, $_->get_content($flt, $cln)) if $_->{'-flg'};
      }
      elsif ($cln && exists($_->{'-nam'}) && $_->{'-nam'} =~ $cln)
      { push (@tbl, $_->get_content($flt, $cln));
      }
      elsif ($flt)
      { push(@tbl, $_) unless index($flt, $_->{'-typ'}) < 0;
      }
      else
      { push(@tbl, $_);
      }
    }
  }
  @tbl;
}

=head2 S<$h-E<gt>get_error>

This function returns the number of parsing errors.

=cut

sub get_error
{ shift->{'-err'};
}

=head2 S<$h-E<gt>get_name([$dft])>

This method returns the object name, or the default value when no name is
defined.

=cut

sub get_name
{ my ($slf, $dft) = @_;

  exists($slf->{'-nam'}) ? $slf->{'-nam'} : $dft;
}

=head2 S<$h-E<gt>get_status>

This method returns the exit code of the last command parsed.

=cut

sub get_status
{ shift->{'-sta'};
}

=head2 S<$h-E<gt>get_type>

This function returns the node type.

=cut

sub get_type
{ shift->{'-typ'};
}

=head2 S<$h-E<gt>get_value($attr[,$dft])>

This function returns the value of the attribute in the specified node. When
the attribute is not defined, it returns the default value.

=cut

sub get_value
{ my ($slf, $att, $dft) = @_;

  exists($slf->{$att}) ? $slf->{$att} : $dft;
}

=head2 S<$h-E<gt>parse_command($cmd)>

This method parses text directly from the output of a command.
It returns a reference to the SGML object.

=cut

sub parse_command
{ my ($slf, $cmd) = @_;
  my ($buf);

  $slf->{'-sta'} = '';
  if (defined($cmd) && open(FIL, "$cmd |"))
  { while (sysread(FIL, $buf, 512))
    { $slf->parse($buf);
    }
    $slf->eof;
    close(FIL);
    $slf->{'-sta'} = $?;
  }
  $slf;
}

=head2 S<$h-E<gt>parse_file($file)>

This method parses text directly from a file. It returns a reference to the
XML object.

=cut

sub parse_file
{ my ($slf, $fil) = @_;
  my ($buf, $ifh);

  $ifh = IO::File->new;
  if (defined($fil) && $ifh->open("<$fil"))
  { $slf->parse($buf, $ifh) while $ifh->read($buf, 512);
    $slf->eof;
    $ifh->close;
  }
  $slf;
}

=head2 S<$h-E<gt>set_trace([$level])>

This method specifies the trace level and returns the previous trace level.

=cut

sub set_trace
{ my ($slf, $lvl) = @_;
  my ($old);

  $old = $slf->{'-lvl'};
  $slf->{'-lvl'} = ($lvl > 0) ? $lvl : 0 if defined($lvl);
  $old;
}

=head2 S<$h-E<gt>traverse($fct[,...])>

This method explores the whole object tree recursively. It executes the
callback function on each node before and after examining child nodes. It
passes the following arguments to the callback function:

=over 2

=item *

A reference to the current node

=item *

Its indentation level

=item *

An indicator (true at node start, false at node end)

=item *

The extra arguments of the traverse function

=back

The tree exploration continues as long as the callback function returns a true
value. It includes or ignores the conditional sections based on condition
values.

=cut

sub traverse
{ shift->_traverse(0, 0, @_);
}

sub _traverse
{ my ($slf, $lvl, $flg, $fct, @arg) = @_;

  # Treat a node
  if ($flg || $slf->{'-typ'} ne 'B')
  { if (&$fct($slf, $lvl, 1, @arg) && exists($slf->{'-det'}))
    { for (@{$slf->{'-det'}})
      { last unless $_->_traverse($lvl + 1, $flg, $fct, @arg);
      }
    }
    return &$fct($slf, $lvl, 0, @arg);
  }

  # Treat a conditional section
  if ($slf->{'-flg'} && exists($slf->{'-det'}))
  { for (@{$slf->{'-det'}})
    { return 0 unless $_->_traverse($lvl, $flg, $fct, @arg);
    }
  }
  1;
}

=head1 ENTITY METHODS

=head2 S<$h-E<gt>convert($str)> or S<RDA::Object::Sgml::convert($str)>

This method converts entities found in the string with their numeric
equivalence. It ignores unrecognized entities.

=cut

sub convert
{ my $str = shift;
  $str = shift if ref($str);

  $str =~ s/(&(\w+);?)/
    exists($tb_ent{$2}) ? sprintf('&#%d;', $tb_ent{$2}) : $1/eg;
  $str =~ s/(\&+)([^#]|\z)/('&#38;' x length($1)).$2/eg;
  $str;
}

=head2 S<$h-E<gt>decode($str)> or S<RDA::Object::Sgml::decode($str)>

This method replaces entities found in the string with the corresponding ISO
8859-1 character. It ignores unrecognized entities.

=cut

sub decode
{ my $str = shift;
  $str = shift if ref($str);
  my $cod;

  $str =~ s/(&\#(\d+);?)/$2 < 256 ? chr($2) : $1/eg;
  $str =~ s/(&\#[xX]([0-9a-fA-F]+);?)/$cod = hex($2);
                                      $cod < 256 ? chr($cod) : $1/eg;
  $str =~ s/(&(\w+);?)/exists($tb_ent{$2}) ? chr($tb_ent{$2}) : $1/eg;
  $str;
}

=head2 S<$h-E<gt>encode($str,$flg)> or S<RDA::Object::Sgml::encode($str,$flg)>

This method replaces control characters, ISO 8859-1 or UTF-8 characters,
special SGML characters, and other characters presenting a security exposure
with their entity representation. Unless the flag is set, it encodes Wiki
(C<%>, C<[>, C<]>, C<{>, C<}>, and C<|>) characters also.

=cut

sub encode
{ my $str = shift;
  $str = shift if ref($str);
  my $flg = shift;
  my ($chr, $ord);

  $chr = $flg
    ? '\040\041\043-\045\047\052\054\056-\072\075\077-\176'
    : '\040\041\043\044\052\054\056-\072\075\077-\132\134\136-\172\176';
  $str =~ s/([^\n\r\t$chr])/
    $ord = ord($1);
    $ord < 256 ?  $tb_ent[$ord] : sprintf('&#x%X;', $ord)/ge;
  $str;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Html|RDA::Object::Html>,
L<RDA::Object::Parser|RDA::Object::Parser>,
L<RDA::Object::Request|RDA::Object::Request>,
L<RDA::Object::Response|RDA::Object::Response>,
L<RDA::Object::UsrAgent|RDA::Object::UsrAgent>,
L<RDA::Object::Xml|RDA::Object::Xml>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
