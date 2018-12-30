# Html.pm: Class Used for Objects to Manage HTML Data

package RDA::Object::Html;

# $Id: Html.pm,v 2.6 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Html.pm,v 2.6 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Html - Class Used for Objects to Manage HTML Data

=head1 SYNOPSIS

require RDA::Object::Html;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Html> class are used to manage HTML data. It
is a subclass of C<RDA::Object::Sgml>.

The following methods are available:

=cut

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Sgml;
}

use strict;

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object::Sgml RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'decode'         => {ret => 0},
    'disable'        => {ret => 0},
    'encode'         => {ret => 0},
    'exists'         => {ret => 0},
    'filter'         => {ret => 0},
    'find'           => {ret => 1},
    'fix'            => {ret => 0},
    'get_attr'       => {ret => 1},
    'get_content'    => {ret => 1},
    'get_error'      => {ret => 0},
    'get_name'       => {ret => 0},
    'get_status'     => {ret => 0},
    'get_tables'     => {ret => 1},
    'get_text'       => {ret => 0},
    'get_type'       => {ret => 0},
    'get_value'      => {ret => 0},
    'parse'          => {ret => 0},
    'parse_command'  => {ret => 0},
    'parse_file'     => {ret => 0},
    'set_trace'      => {ret => 0},
    },
  new => 1,
  trc => 'HTML_TRACE',
  );

# Define the global private variables
my %tb_emp = map {$_ => 1} qw(area base basefont bgsound br col embed frame hr
                              img input isindex link meta param spacer wbr);
my %tb_par =(
  'dd'        => [qw(dl)],
  'dt'        => [qw(dl)],
  'li'        => [qw(dir menu ol ul)],
  'option'    => [qw(form select)],
  'select'    => [qw(form)],
  'td'        => [qw(table tr)],
  'textarea'  => [qw(form)],
  'th'        => [qw(table tr)],
  'tr'        => [qw(table)],
  );
my %tb_phr = map {$_ => 1} qw(a abbr acronym b br basefont bdo big blink cite
                              code dfn em embed font i img kbd nobr noembed q
                              s samp small spacer span strike strong sub sup tt
                              u var wbr); 

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Html-E<gt>new([$level])>

The object constructor.

C<RDA::Object::Html> is represented by a blessed hash reference. Along with the
keys inherited from C<RDA::Object::Sgml>, the following special key is used
also:

=over 12

=item S<B<    '-fix'> > Auto fix HTML code indicator (false by default)

=item S<B<    '-tag'> > Tag filter hash

=back

=cut

sub new
{ my ($cls, $lvl) = @_;

  # Return the object reference
  bless RDA::Object::Sgml->new('H', 'HTML> ', $lvl), ref($cls) || $cls;
}

=head2 S<$h-E<gt>eof>

This method signals the end of the document, flushing any remaining buffered
text. It returns a reference to the parser object.

=cut

sub eof
{ my $slf = shift;
  my $buf = \$slf->{'-buf'};

  # Assume rest is text
  if (length($$buf))
  { $slf->add_text($$buf);
    $$buf = '';
  }

  # Insert pending text
  $slf->add_text;

  # Return the object reference
  return $slf;
}


=head2 S<$h-E<gt>filter([$tag,...])>

This method specifies the list of the tags to consider when parsing the
document. It can automatically add additional tags to the list for resolving
optional end tags. When the list is empty, it disables any tag filtering.

It returns the parser object reference.

=cut

sub filter
{ my $slf = shift;

  # Update the tag filter list
  delete($slf->{'-tag'});
  foreach my $tag (@_)
  { $tag = lc($tag);
    $slf->{'-tag'}->{$tag} = 1;
    if (exists($tb_par{$tag}))
    { map {$slf->{'-tag'}->{$_} = 1} @{$tb_par{$tag}};
    }
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>fix([$flag])>

This method indicates that the parser can fix incorrect HTML code. It returns
the parser object reference.

=cut

sub fix
{ my ($slf, $flg) = @_;

  # Update the indicator
  $slf->{'-fix'} = $flg;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>get_tables([$level])>

This method extracts all significant tables from the parsed document. Cells
in bold are taken as heading. It converts single cell rows in the header of the
specified level. It considers horizontal rulers and header lines also. The
method returns the result as a list of raw data lines.

=cut

sub get_tables
{ my ($slf, $lvl) = @_;

  # Extract the table content
  my $obj = {
    lin => [],
    lvl => (defined($lvl) && $lvl > 1) ? '---'.('+' x $lvl).' ' : '---+ ',
    rec => [],
    txt => ''};
  $slf->traverse(\&_table_row, $obj);

  # Return the extracted information
  @{$obj->{'lin'}};
}

sub _table_row
{ my ($slf, $lvl, $flg, $obj) = @_;

  if ($flg)
  { if ($slf->{'-typ'} eq 'T')
    { my $tag = $slf->{'-nam'};
      $obj->{'txt'} = '' if $tag =~ m/^(h\d|td|tr)$/;
      $obj->{'rec'} = [] if $tag eq 'tr';
    }
    elsif ($slf->{'-typ'} eq 'S')
    { $obj->{'txt'} .= $slf->{'-dat'};
    }
  }
  elsif ($slf->{'-typ'} eq 'T')
  { my $tag = $slf->{'-nam'};
    if ($tag eq 'td')
    { _table_text($obj);
    }
    elsif ($tag eq 'tr')
    { _table_text($obj);

      my $cnt = @{$obj->{'rec'}};
      if ($cnt == 1)
      { my $txt = $obj->{'rec'}->[0];
        push(@{$obj->{'lin'}}, $obj->{'lvl'}.$slf->encode($txt))
          if $txt =~ m/\S/;
      }
      if ($cnt > 1)
      { push(@{$obj->{'lin'}},
          '|'.join('|', map{$slf->encode($_)} @{$obj->{'rec'}}).'|');
      }
      $obj->{'rec'} = [];
    }
    elsif ($tag eq 'b')
    { $obj->{'txt'} = '*'.$obj->{'txt'}.'*';
    }
    elsif ($tag =~ m/^h(\d)$/)
    { push(@{$obj->{'lin'}}, '---'.('+' x $1).' '.$slf->encode($obj->{'txt'}));
      $obj->{'txt'} = '';
    }
    elsif ($tag eq 'hr')
    { push(@{$obj->{'lin'}}, '---');
    }
  }

  1;
}

sub _table_text
{ my ($obj) = @_;
  my $txt;

  if ($txt = $obj->{'txt'})
  { $txt =~ s/\240/ /g;
    push(@{$obj->{'rec'}}, $txt);
    $obj->{'txt'} = '';
  }
}

=head2 S<$h-E<gt>get_text>

This method returns the text contained in the object.

=cut

sub get_text
{ my ($slf) = @_;
  my $buf = '';

  $slf->traverse(\&_text, \$buf);
  $buf;
}

sub _text
{ my ($slf, $lvl, $flg, $buf) = @_;
  my $typ = $slf->{'-typ'};

  if ($typ eq 'S')
  { $$buf .= $slf->{'-dat'} if $flg;
  }
  elsif ($typ eq 'T')
  { $$buf .= ' '
      unless exists($tb_phr{$slf->{'-nam'}}) && $slf->{'-nam'} ne 'br';
  }
  1;
}

=head2 S<$h-E<gt>parse($string)>;

This method parses the specified string as the next HTML chunk. It returns a
reference to the HTML object.

=cut

sub parse
{ my $slf = shift;
  my $buf  = \$slf->{'-buf'};
  my $dbg  = $slf->{'-lvl'};

  # When EOF, assume rest is text
  return $slf->eof unless defined($_[0]);

  # Transfer a trailing carriage return to the next buffer
  $_[0] =~ s#^#\r#  if delete($slf->{'-crf'});
  $slf->{'-crf'} = 1 if  $_[0] =~ s#\r$## ;

  # Filter out some characters
  $_[0] =~ s#\r\n#\n#g;
  $_[0] =~ s#\r#\n#g;

  # Parse HTML in the buffer 
  $$buf .= $_[0];
  $slf->debug('HTML> ## New Buffer') if $dbg;
  TOKEN: while ($$buf !~ m#^(<\/|<\?|<!|<!-|<!--)?$#)
  { $slf->debug('HTML> Buffer') if $dbg;

    # Parse the next token
    if ($$buf =~ s#^([^<]+)##)  # Plain text
    { # Extract any text before '<' characters
      $slf->add_text($1);
      last TOKEN unless length($$buf);
    }
    elsif ($$buf =~ s#^(<!--)\s*##)  # Comment
    { my $cur = $1;
      $slf->debug('HTML> ++ Comment found') if $dbg;
      if ($$buf !~ s#^((.*?)\s*-->)##s)
      { # Need more data to get all data
        $$buf = $cur.$$buf;
        last TOKEN;
      }
      $slf->add_item('R', -dat => $2);
    }
    elsif ($$buf =~ s#^(<!)##)  # Markup declaration
    { my ($cur, $txt, @com);
      $cur = $1;
      $txt = '';

      # Extract the comments from the declaration
      while ($$buf =~ s#^(([^>]*?)--)##)
      { $cur .= $1;
        $txt .= $2;

        # Look for end of comment
        if ($$buf =~ s#^((.*?)--)##s)
        { $cur .= $1;
          push(@com, $2) if $2;
        }
        else
        { # Need more data to extract the comment
          $$buf = $cur.$$buf;
          last TOKEN;
        }
      }

      # Try to finish the declaration extraction
      if ($$buf =~ s#^([^>]*)>##)
      { $txt .= $1;
        $slf->add_item('D', -dat => $txt) if $txt;
        foreach my $com (@com)
        { $slf->add_item('R', -dat => $com);
        }
      }
      else
      { # Need more data to extract the declaration
        $$buf = $cur.$$buf;
        last TOKEN;
      }
    }
    elsif ($$buf =~ s#^</##)  # End tag
    { if ($$buf =~ s#^(([a-zA-Z][a-zA-Z0-9\.\-]*)\s*>)##)
      { # Close the tag
        $slf->_end_tag(lc($2));
      }
      elsif ($$buf =~ m#^[a-zA-Z][a-zA-Z0-9\.\-]*\s*$#)
      { # Need more data for the end tag
        $$buf = '</'.$$buf;
        last TOKEN;
      }
      else
      { # When not valid, consider it as text
        $slf->add_text("</");
      }
    }
    elsif ($$buf =~ s#^(<([a-zA-Z]+)\s*(\/)?>)##)  # Empty start tag
    { my $tag = lc($2);
      $slf->_add_tag($tag, {}, $3 || exists($tb_emp{$tag}));
    }
    elsif ($$buf =~ s#^<##)                # Start Tag
    { my ($cur, $tag, %tbl);

      $cur = '<';
      $slf->debug('HTML> ++ Start tag found') if $dbg;

      if ($$buf =~ s#^(([a-zA-Z][a-zA-Z0-9\.\-]*)\s*)##)
      { # Extract the tag name
        $cur .= $1;
        $tag = lc $2;

        # Extract attributes
        while ($$buf =~ s#^(([a-zA-Z][a-zA-Z0-9:_\.\-]*)\s*)##)
        { my ($nam);
          $cur .= $1;
          $nam = lc $2;

          if ($$buf =~ s#(^=\s*([^\042\047>\s][^>\s]*)\s*)##)
          { # Extract attribute value (unquoted)
            $cur .= $1;
            $tbl{$nam} = $slf->decode($2);
          }
          elsif ($$buf =~ s#(^=\s*([\042\047])(.*?)\2\s*)##s)
          { # Extract attribute value (quoted)
            $cur .= $1;
            $tbl{$nam} = $slf->decode($3);

            # truncated just after the '=' or inside the attribute
          }
          elsif ($$buf =~ m#^(=\s*)$# || $$buf =~ m#^(=\s*[\042\047].*)#s)
          { # Need more data to extract attribute
            $$buf = "$cur$1";
            last TOKEN;
          }
          else
          { # Extract attribute value (implicit value)
            $tbl{$nam} = $nam;
          }
        }

        # Check start tag end
        if ($$buf =~ s#^(\/)?>##)
        { # Insert the tag in the object tree
          $slf->_add_tag($tag, \%tbl, $1 || exists($tb_emp{$tag}));
        }
        elsif ($$buf =~ m#^<# && $slf->{'-fix'})
        { # Insert the tag in the object tree
          $slf->_add_tag($tag, \%tbl, $1 || exists($tb_emp{$tag}));
        }
        elsif (length($$buf) && $$buf !~ m#^\/$#)
        { # Not a conforming HTML declaration, consider it as text
          $slf->add_text($cur);
        }
        else
        { # Need more data to parse the start tag
          $$buf = $cur.$$buf;
          last TOKEN;
        }
      }
      elsif (length $$buf)
      { # Not a valid start tag, consider it as text
        $slf->add_text($cur);
      }
      else
      { # Need more data to parse the start tag
        $$buf = $cur.$$buf;
        last TOKEN;
      }
    }
  }

  # Return the object reference
  $slf;
}

sub _add_tag
{ my ($slf, $tag, $tbl, $flg) = @_;

  # When requested, filter the tag
  if (exists($slf->{'-flt'}->{'T'})
    || (exists($slf->{'-tag'}) && !exists($slf->{'-tag'}->{$tag})))
  { $slf->add_text(' ') unless exists($tb_phr{$tag}) && $tag ne 'br';
    return;
  }

  # Terminate the current paragraph
  $slf->_end_p unless exists($tb_phr{$tag});

  # Treat tags with optional end tag
  if (exists($tb_par{$tag}))
  { # Insert pending text
    $slf->add_text;

    # Retrieve its parent tag
    $slf->_find_parent($tag, $tb_par{$tag});
  }

  # Disable text normalisation in PRE blocks
  $tbl->{'-txt'} = 0 if $tag eq 'pre';

  # Create the tag element and insert in the list
  $slf->add_item('T', -nam => $tag, %$tbl);

  # Go to the next level when an end tag is expected
  $slf->push_item unless $flg;
}

sub _end_p
{ my ($slf) = @_;
  my ($cur, $nam);

  # Insert pending text
  $slf->add_text;

  # Close all phrase tags
  print $slf->{'-pre'}."** Close tag 'p'\n" if $slf->{'-lvl'};
  $cur = $slf->{'-cur'};
  for (; index('HX', $cur->{'-typ'}) < 0 ; $cur = $slf->pop_item)
  { next unless $cur->{'-typ'} eq 'T';
    $nam = $cur->{'-nam'};
    if ($nam eq 'p')
    { $slf->pop_item;
      return;
    }
    return unless exists($tb_phr{$cur->{'-nam'}});
  }
}

sub _end_tag
{ my ($slf, $tag) = @_;
  my ($cur, $nam, $tbl);

  # When requested, filter the tag
  if (exists($slf->{'-flt'}->{'T'})
    || (exists($slf->{'-tag'}) && !exists($slf->{'-tag'}->{$tag})))
  { $slf->add_text(' ') unless exists($tb_phr{$tag}) && $tag ne 'br';
    return;
  }

  # Insert pending text
  $slf->add_text;

  # Close the tag
  $slf->save_stack;
  print $slf->{'-pre'}."** Close tag $tag\n" if $slf->{'-lvl'};
  $cur = $slf->{'-cur'};
  $tbl = exists($tb_par{$tag}) ? $tb_par{$tag} : [];
  LEVEL: for (; index('HX', $cur->{'-typ'}) < 0 ; $cur = $slf->pop_item)
  { next unless $cur->{'-typ'} eq 'T';
    $nam =  $cur->{'-nam'};
    if ($nam eq $tag)
    { $slf->pop_item;
      return;
    }
    for (@$tbl)
    { last LEVEL if $nam eq $_;
    }
  }

  # Ignore it when no corresponding tag has been found
  $slf->restore_stack;
  ++$slf->{'-err'};
  print "ERR> Missing tag '$tag' !\n" if $slf->{'-lvl'};
}

sub _find_parent
{ my ($slf, $tag, $tbl) = @_;
  my ($cur, $nam);

  # Close the tag
  $slf->save_stack;
  $cur = $slf->{'-cur'};
  for (; index('HX', $cur->{'-typ'}) < 0 ; $cur = $slf->pop_item)
  { next unless $cur->{'-typ'} eq 'T';
    $nam =  $cur->{'-nam'};
    for (@$tbl)
    { return if $_ eq $nam;
    }
  }

  # Ignore it when parent tag has not been found
  $slf->restore_stack;
  ++$slf->{'-err'};
  print "ERR> Missing parent tag for '$tag' !\n" if $slf->{'-lvl'};
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Library::Html|RDA::Library::Html>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Sgml|RDA::Object::Sgml>,

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
