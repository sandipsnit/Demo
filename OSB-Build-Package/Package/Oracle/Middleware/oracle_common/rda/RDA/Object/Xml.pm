# Xml.pm: Class Used for Objects to Manage XML Data

package RDA::Object::Xml;

# $Id: Xml.pm,v 2.10 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Xml.pm,v 2.10 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Xml - Class Used for Objects to Manage XML Data

=head1 SYNOPSIS

require RDA::Object::Xml;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Xml> class are used to manage XML data. It is
a subclass of C<RDA::Object::Sgml>.

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
$VERSION = sprintf("%d.%02d", q$Revision: 2.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object::Sgml RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'decode'         => {ret => 0},
    'disable'        => {ret => 0},
    'encode'         => {ret => 0},
    'exists'         => {ret => 0},
    'find'           => {ret => 1},
    'get_attr'       => {ret => 1},
    'get_content'    => {ret => 1},
    'get_data'       => {ret => 0},
    'get_error'      => {ret => 0},
    'get_name'       => {ret => 0},
    'get_status'     => {ret => 0},
    'get_type'       => {ret => 0},
    'get_value'      => {ret => 0},
    'normalize_text' => {ret => 0},
    'parse'          => {ret => 0},
    'parse_command'  => {ret => 0},
    'parse_file'     => {ret => 0},
    'set_trace'      => {ret => 0},
    },
  new => 1,
  trc => 'XML_TRACE',
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Xml-E<gt>new([$level])>

The object constructor.

C<RDA::Object::Xml> is represented by a blessed hash reference. Along with
the keys inherited from C<RDA::Object::Sgml>, the following special keys are
used also:

=over 12

=item S<    B<'-ent'> > Internal entity hash

=item S<    B<'-ext'> > External entity hash

=item S<    B<'-pub'> > External entity public hash

=back

=cut

sub new
{ my ($cls, $lvl) = @_;
  my ($slf);

  # Create the object
  $slf = bless RDA::Object::Sgml->new('X', 'XML> ', $lvl), ref($cls) || $cls;

  # Perform extra initialization
  $slf->{'-ent'} = {},
  $slf->{'-ext'} = {},
  $slf->{'-pub'} = {},

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the item tree, the list of defined
internal and external entities. You can provide an indentation level and a
prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;
  my ($buf, $pre);

  $lvl = 0 unless defined($lvl);
  $txt = '' unless defined($txt);
  $pre = '  ' x $lvl++;
  $buf = $txt ? "$pre$txt\n" : "";

  # Display the entity information
  if (exists($slf->{'-ent'}))
  { $buf .= $pre."-Entities:\n";
    for (sort keys(%{$slf->{'-ent'}}))
    { $buf .= $pre."  $_=".$slf->fmt_str($slf->{'-ent'}->{$_})."\n";
    }
    $buf .= "\n";
  }
  if (exists($slf->{'-ext'}))
  { $buf .= $pre."-External Entities:\n";
    for (sort keys(%{$slf->{'-ext'}}))
    { $buf .= $pre."  $_=".$slf->fmt_str($slf->{'-ext'}->{$_})."\n";
    }
    $buf .= "\n";
  }

  # Return the tree information
  $buf.$pre."-Object tree:\n".$slf->SUPER::dump($lvl);
}

=head2 S<$h-E<gt>eof>

This method signals the end of the document, flushing any remaining buffered
text. It returns a reference to the parser object.

=cut

sub eof
{ my $slf = shift;
  my $buf  = \$slf->{'-buf'};

  # Assume rest is text
  if (length($$buf))
  { $slf->add_text($$buf);
    $$buf = '';
  }

  # Insert pending text
  $slf->add_text;

  # Detect open tags
  my $cur = $slf->{'-cur'};
  for (; $cur->{'-typ'} ne 'X' ; $cur = $slf->pop_item)
  { next unless $cur->{'-typ'} eq 'T';
    ++$slf->{'-err'};
    print "ERR> Expecting end tag for '".$cur->{'-nam'}."' !\n"
      if $slf->{'-lvl'} > 0;
  }

  # Return the object reference
  return $slf;
}

=head2 S<$h-E<gt>get_data>

This method returns the text or CDATA contained in the object.

=cut

sub get_data
{ my ($slf) = @_;
  my $buf = '';

  $slf->traverse(\&_data, \$buf);
  $buf;
}

sub _data
{ my ($slf, $lvl, $flg, $buf) = @_;

  if ($flg)
  { $$buf .= $slf->{'-dat'} unless index('CS', $slf->{'-typ'}) < 0;
  }
  1;
}

=head2 S<$h-E<gt>normalize_text($flag)>

This method controls how the parser normalizes texts. It returns the previous
value.

=cut

sub normalize_text
{ my ($slf, $flg) = @_;

  ($slf->{'-txt'}, $flg) = ($flg, $slf->{'-txt'});
  $flg;
}

=head2 S<$h-E<gt>parse($string)>;

This method parses the specified string as the next XML chunk. It returns a
reference to the XML object.

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

  # Parse XML in the buffer
  $$buf .= $_[0];
  $slf->debug('XML> ## New Buffer') if $dbg;
  TOKEN: while ($$buf !~ m#^(<\/|<\?|<!|<!\[|<!-|<!--)?$#)
  { $slf->debug('XML> Buffer') if $dbg;

    # Parse the next token
    if ($$buf =~ s#^([^<\]]+)##s)  # Plain text
    { # Extract any text before '<' or ']' characters
      $slf->add_text($1);
      last TOKEN unless length($$buf);
    }
    elsif ($$buf =~ s#^(<!\[)##)  # Section start
    { my $cur = $1;

      if ($$buf =~ s#^(CDATA\[)##)
      { # Treat a data section
        $cur .= $1;
        $slf->debug('XML> ++ CDATA found') if $dbg;
        if ($$buf =~ s#^((.*?)\]\]>)##s)
        { $slf->add_item('C', -dat => $2);
        }
        else
        { my ($ifh, $pre, $tmp);

          # Need more data to get all data
          unless (ref($ifh = $_[1]))
          { $$buf = $cur.$$buf;
            last TOKEN;
          }
          $pre = ($$buf =~ s/(\]+)$//) ? $1 : undef;
          for (;;)
          { unless ($ifh->read($tmp, 512))
            { $$buf = defined($pre) ? $cur.$$buf.$pre : $cur.$$buf;
              last TOKEN 
            }
            $tmp = $pre.$tmp if defined($pre);
            $tmp =~ s#\r\n#\n#g;
            $tmp =~ s#\r#\n#g;
            if ($tmp =~ s#^((.*?)\]\]>)##s)
            { $slf->add_item('C', -dat => $$buf.$2);
              $$buf = $tmp;
              last
            }
            $pre = ($tmp =~ s/(\]+)$//) ? $1 : undef;
            $$buf .= $tmp;
          }
        }
      }
      elsif ($$buf =~ s#^([A-Z]+)\[## ||
             $$buf =~ s#^(\%[a-zA-Z_:][a-zA-Z0-9_:\.\-]*\;)\[##)
      { # Treat a conditional section
        $slf->_add_section($slf->decode($1));
      }
      elsif ($$buf =~ m#^([A-Z]*)$# ||
             $$buf =~ m#^(\%([a-zA-Z_:][a-zA-Z0-9_:\.\-]*(\;)?)?)$#)
      { # Need more data to get the type
        $$buf = $cur.$$buf;
        last TOKEN;
      }
      else
      { # Consider any other pattern as text
        $slf->add_text($cur);
      }
    }
    elsif ($$buf =~ s#^(\](\]>)?)##)  # Conditional section end
    { if ($2)
      { # Close the conditional section
        $slf->_end_section;
      }
      elsif (length($$buf))
      { # Consider any other pattern as text
        $slf->add_text($1);
      }
      else
      { # Need more data to get identify the context
        $$buf = $1.$$buf;
        last TOKEN;
      }
    }
    elsif ($$buf =~ s#^(<!--)\s*##)  # Comment
    { my $cur = $1;
      $slf->debug('XML> ++ Comment found') if $dbg;
      if ($$buf !~ s#^((.*?)\s*-->)##s)
      { # Need more data to get all data
        $$buf = $cur.$$buf;
        last TOKEN;
      }
      $slf->add_item('R', -dat => $2);
    }
    elsif ($$buf =~ s#^(<!)##)  # Markup declaration
    { my ($cur, $typ);

      $cur = $1;
      $slf->debug('XML> ++ Declaration found') if $dbg;

      # Get the declaration type
      if ($$buf =~ s#^(([A-Z]+)\s+)##s)
      { # Extract the declaration type
        $cur .= $1;
        $typ = $2;
      }
      elsif ($$buf =~ m#^[A-Z]+$#)
      { # Need more data to parse the declaration
        $$buf = $cur.$$buf;
        last TOKEN;
      }
      else
      { # Nonconform declaration, consider it as text
        $slf->add_text($cur);
        next TOKEN;
      }

      # Extract the declaration
      if ($typ eq 'ENTITY')
      { my (@tok);

        while ($$buf !~ s#^>##)
        { if ($$buf =~ s#^((\%)\s*)##s)
          { # Extract the external entity indicator
            $cur .= $1;
            push(@tok, $2);
          }
          elsif ($$buf =~ s#^(([a-zA-Z_:][a-zA-Z0-9_:\.\-]*)\s+)##s)
          { # Extract a name
            $cur .= $1;
            push(@tok, $2);
          }
          elsif ($$buf =~ s#(^([\042\047])(.*?)\2\s*)##s)
          { # Extract a quoted string
            $cur .= $1;
            push(@tok, "'", $slf->decode($3));
          }
          elsif ($$buf =~ m#^\s*$# ||
                 $$buf =~ m#^([a-zA-Z_:][a-zA-Z0-9_:\.\-]*)?$# ||
                 $$buf =~ m#(^([\042\047]).*$)#s)
          { # Need more data to parse the declaration
            $$buf = $cur.$$buf;
            last TOKEN;
          }
          else
          { # Nonconform declaration, consider it as text
            $slf->add_text($cur);
            next TOKEN;
          }
        }
        $slf->_add_entity(@tok);
      }
      else
      { my $dcl = '';
        while ($$buf !~ s#^>##)
        { if ($$buf !~ s#^([^>\[]+)##s && $$buf !~ s#^(\[(.*?)\])##s)
          { # Need more data to get all data
            $$buf = $cur.$dcl.$$buf;
            last TOKEN;
          }
          $dcl .= $1;
        }
        $slf->add_item('D', -nam => $typ, -dat => $dcl);
      }
    }
    elsif ($$buf =~ s#^(<\?xml\s*)##i)  # XML declaration
    { my ($cur, %tbl);

      $cur = $1;
      $slf->debug('XML> ++ XML Declaration found') if $dbg;

      # Look for attributes
      while ($$buf =~ s#^(([a-zA-Z_:][a-zA-Z0-9_:\.\-]*)\s*)##)
      { my ($nam, $val);
        $cur .= $1;
        $nam = $2;

        if ($$buf =~ s#(^=\s*([\042\047])(.*?)\2\s*)##s)
        { # Extract attribute value (quoted)
          $cur .= $1;
          $tbl{$nam} = $slf->decode($3);
        }
        elsif ($$buf =~ m#^(=\s*)$# || $$buf =~ m#^(=\s*[\042\047].*)#s)
        { # Need more data to extract attribute
          $$buf = $cur.$$buf;
          last TOKEN;
        }
        else
        { # Missing or invalid attribute value, consider it as text
          $slf->add_text($cur);
          next TOKEN;
        }
      }

      # Check XML declaration end
      if ($$buf =~ s#^\?>##)
      { $slf->_add_xml(\%tbl);
      }
      elsif (length($$buf))
      { # Not a conforming XML declaration, consider it as text
        $slf->add_text($cur);
      }
      else
      { # Need more data to parse the XML declaration
        $$buf = $cur;
        last TOKEN;
      }
    }
    elsif ($$buf =~ s#^<\?##)  # Processing instruction
    { my ($cur, $tgt);

      $cur = '<?';
      $slf->debug('XML> ++ Processing instruction found') if $dbg;

      # Get the target name
      if ($$buf =~ s#^(([a-zA-Z\_\:][a-zA-Z0-9\_\:\.\-]*)\s*)##)
      { $cur .= $1;
        $tgt = $2;

        # Get the instruction
        if ($$buf !~ s#^((.*?)\s*\?>)##s)
        { # Need more data to parse the processing instruction
          $$buf = $cur.$$buf;
          last TOKEN;
        }
        $slf->add_item('P', -nam => $tgt, -dat => $2);
      }
      elsif (length($$buf))
      { # Not a conforming processing instruction, consider it as text
        $slf->add_text($cur);
      }
      else
      { # Need more data to extract the target name
        $$buf = $cur.$$buf;
        last TOKEN;
      }
    }
    elsif ($$buf =~ s#^</##)  # End tag
    { if ($$buf =~ s#^(([a-zA-Z\_\:][a-zA-Z0-9\_\:\.\-]*)\s*>)##)
      { # Close the tag
        $slf->_end_tag($2);
      }
      elsif ($$buf =~ m#^[a-zA-Z\_\:][a-zA-Z0-9\_\:\.\-]*\s*$#)
      { # Need more data for the end tag
        $$buf = '</'.$$buf;
        last TOKEN;
      }
      else
      { # When not valid, consider it as text
        $slf->add_text("</");
      }
    }
    elsif ($$buf =~ s#^(<([a-zA-Z]+)\s*(\/)?>)##)  # Tag without attributes
    { $slf->_add_tag($2, {}, $3);
    }
    elsif ($$buf =~ s#^<##)                        # Tag
    { my ($cur, $tag, %tbl);

      $cur = '<';
      $slf->debug('XML> ++ Start tag found') if $dbg;

      if ($$buf =~ s#^(([a-zA-Z:_][a-zA-Z0-9:_\.\-]*)\s*)##)
      { # Extract the tag name
        $cur .= $1;
        $tag = $2;

        # Extract attributes
        while ($$buf =~ s#^(([a-zA-Z:_][a-zA-Z0-9:_\.\-]*)\s*)##)
        { my ($nam);
          $cur .= $1;
          $nam = $2;

          if ($$buf =~ s#(^=\s*([^\042\047>\s][^>\s]*)\s*)##)
          { # Extract attribute value (unquoted)
            $cur .= $1;
            $tbl{$nam} = $slf->decode($2);
          }
          elsif ($$buf =~ s#(^=\s*([\042\047])(.*?)\2\s*)##s)
          { # Extract attribute value (quoted)
            $cur .= $1;
            $tbl{$nam} = $slf->decode($3);
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
        $slf->debug('XML> ++ Start tag end') if $dbg;
        if ($$buf =~ s#^(\/)?>##)
        { # Insert the tag in the object tree
          $slf->_add_tag($tag, \%tbl, $1);
        }
        elsif (length($$buf) && $$buf !~ m#^\/$#)
        { # Not a conforming XML declaration, consider it as text
          $slf->add_text($cur);
        }
        else
        { # Need more data to parse the start tag
          $$buf = $cur.$$buf;
          last TOKEN;
        }
      }
      elsif (length($$buf))
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

# Parsing methods
sub _add_entity
{ my ($top, @arg) = @_;
  my ($flg, $nam, $pub, $tok, $val);

  # Insert the entity in the tree
  $top->add_item('E', -dat => join(' ', @arg));

  # Decode the entity
  return 0 unless defined($nam = shift(@arg));
  if ($nam eq '%')
  { return 0 unless defined($nam = shift(@arg));
    $flg = 1;
  }
  return 0 unless defined($tok = shift(@arg));
  if ($tok eq "'")
  { return 0 unless defined($val = shift(@arg));
  }
  elsif ($tok eq "SYSTEM")
  { return 0 unless defined($tok = shift(@arg)) && $tok eq "'" &&
                    defined($val = shift(@arg));
  }
  elsif ($tok eq "PUBLIC")
  { return 0 unless defined($tok = shift(@arg)) && $tok eq "'" &&
                    defined($pub = shift(@arg)) &&
                    defined($tok = shift(@arg)) && $tok eq "'" &&
                    defined($val = shift(@arg));
  }
  else
  { return 0;
  }
  return 0 if @arg;
  if ($flg)
  { print $top->{'-pre'}."** Add external entity \%$nam; '$val'\n"
      if $top->{'-lvl'};
    $top->{'-ext'}->{$nam} = $val;
    $top->{'-pub'}->{$nam} = $pub if defined($pub);
  }
  else
  { print $top->{'-pre'}."** Add entity \&$nam; '$val'\n"
      if $top->{'-lvl'};
    $top->{'-ent'}->{$nam} = $val;
  }

  return 1;
}

sub _add_section
{ my ($slf, $nam) = @_;
  my ($flg);

  # Resolve entities and determine if the block must be included or ignored
  $flg = ($nam ne 'IGNORE');

  # Create the tag element, insert in the list, and go to the next level
  $slf->add_item('B', -nam => $nam, -flg => $flg);
  $slf->push_item;
}

sub _add_tag
{ my ($slf, $tag, $tbl, $flg) = @_;

  # When requested, filter the tag
  return if exists($slf->{'-flt'}->{'T'});

  # Create the tag element and insert in the list
  $slf->add_item('T', -nam => $tag, %$tbl);

  # Go to the next level when an end tag is expected
  $slf->push_item unless $flg;
}

sub _add_xml
{ my ($slf, $tbl) = @_;

  print 'XML> ** Add XML attributes ('.join(',', %$tbl).")\n"
    if $slf->{'-lvl'};
  foreach my $key (keys(%$tbl))
  { $slf->{$key} = $tbl->{$key};
  }
}

sub decode
{ my ($slf, $str) = @_;

  $str =~ s/(&(\w+);?)/exists($slf->{'-ent'}->{$2}) ? $slf->{'-ent'}->{$2} :
                       $1/eg;
  $str = $slf->SUPER::decode($str);
  $str =~ s/(%(\w+);?)/exists($slf->{'-ext'}->{$2}) ? $slf->{'-ext'}->{$2} :
                       $1/eg;
  $str;
}

sub _end_section
{ my ($slf) = @_;

  # Insert pending text
  $slf->add_text;

  # Close the tag
  $slf->save_stack;
  print $slf->{'-pre'}."** Close conditional section\n" if $slf->{'-lvl'};
  my $cur = $slf->{'-cur'};
  for (; $cur->{'-typ'} ne 'X' ; $cur = $slf->pop_item)
  { if ($cur->{'-typ'} eq 'B')
    { $slf->pop_item;
      return;
    }
  }

  # Ignore it when no block has been found
  $slf->restore_stack;
  ++$slf->{'-err'};
  print "ERR> Missing conditional section !\n" if $slf->{'-lvl'};
}

sub _end_tag
{ my ($slf, $tag) = @_;
  my ($cur, @nam);

  # When requested, filter the tag
  return if exists($slf->{'-flt'}->{'T'});

  # Insert pending text
  $slf->add_text;

  # Close the tag
  $slf->save_stack;
  print $slf->{'-pre'}."** Close tag $tag\n" if $slf->{'-lvl'};
  $cur = $slf->{'-cur'};
  for (; index('HX', $cur->{'-typ'}) < 0 ; $cur = $slf->pop_item)
  { next unless $cur->{'-typ'} eq 'T';
    if ($cur->{'-nam'} eq $tag)
    { $slf->pop_item;
      foreach my $nam (@nam)
      { ++$slf->{'-err'};
        print "ERR> Expecting end tag for '$nam' !\n" if $slf->{'-lvl'};
      }
      return;
    }
    push(@nam, $cur->{'-nam'});
  }

  # Ignore it when no corresponding tag has been found
  $slf->restore_stack;
  ++$slf->{'-err'};
  print "ERR> Missing tag '$tag' !\n" if $slf->{'-lvl'};
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Library::Xml|RDA::Library::Xml>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Sgml|RDA::Object::Sgml>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
