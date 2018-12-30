# Buffer.pm: Class Used for Buffer Macros

package RDA::Library::Buffer;

# $Id: Buffer.pm,v 2.10 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Buffer.pm,v 2.10 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Buffer - Class Used for Buffer Macros

=head1 SYNOPSIS

require RDA::Library::Buffer;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Buffer> class are used to interface with
buffer-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object::Buffer;
  use RDA::Object::Parser;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $RPT = qr/^RDA::Object::(Pipe|Report)$/i;

my %tb_fct = (
  'countBuffer'  => [\&_m_count,      'L'],
  'createBuffer' => [\&_m_create,     'N'],
  'deleteBuffer' => [\&_m_delete,     'N'],
  'filterBuffer' => [\&_m_filter,     'N'],
  'getBytes'     => [\&_m_getbytes,   'T'],
  'getLine'      => [\&_m_getline,    'T'],
  'getPos'       => [\&_m_getpos,     'N'],
  'grepBuffer'   => [\&_m_grep,       'L'],
  'inputLine'    => [\&_m_input,      'N'],
  'parse'        => [\&_m_parse,      'N'],
  'parseBegin'   => [\&_m_parse_beg,  'N'],
  'parseBuffer'  => [\&_m_parse_buf,  'L'],
  'parseCode'    => [\&_m_parse_code, 'X'],
  'parseCount'   => [\&_m_parse_cnt,  'N'],
  'parseEnd'     => [\&_m_parse_end,  'N'],
  'parseHit'     => [\&_m_parse_hit,  'T'],
  'parseInfo'    => [\&_m_parse_info, 'X'],
  'parseKeep'    => [\&_m_parse_keep, 'N'],
  'parseLast'    => [\&_m_parse_last, 'T'],
  'parseLine'    => [\&_m_parse_line, 'T'],
  'parseMarker'  => [\&_m_parse_mark, 'T'],
  'parsePattern' => [\&_m_parse_pat,  'X'],
  'parseReplace' => [\&_m_parse_repl, 'T'],
  'parseReset'   => [\&_m_parse_init, 'N'],
  'parseQuit'    => [\&_m_parse_quit, 'N'],
  'setPos'       => [\&_m_setpos,     'N'],
  'writeBuffer'  => [\&_m_write,      'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Buffer-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Buffer> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_buf'> > Buffer hash

=item S<    B<'_prs'> > Parser object reference

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($dbg, $slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _buf => {},
    _prs => RDA::Object::Parser->new($agt->get_setting('PARSE_TRACE')),
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(reset));

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

=head2 S<$h-E<gt>reset>

This method resets the library.

=cut

sub reset
{ my ($slf) = @_;

  foreach my $buf (values(%{$slf->{'_buf'}}))
  { $buf->close;
  }
  $slf->{'_buf'} = {};
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method runs the macro with the specified argument list in a given context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return &{$fct->[0]}($slf, $ctx, $arg) if $typ eq 'X';

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 BUFFER MACROS

=head2 S<countBuffer($name[,$re...])>

This macro returns the number of lines in the specified buffer. You can search
additional regular expressions also. It returns a list containing the
respective counters.

=cut

sub _m_count
{ my ($slf, $ctx, $nam, @arg) = @_;

  return () unless defined($nam) && exists($slf->{'_buf'}->{$nam});
  $slf->{'_buf'}->{$nam}->count(@arg);
}

=head2 S<createBuffer($name,'S',$str)>

This macro creates a new buffer with the specified string. On successful
completion, it returns a true value. Otherwise, it returns a false value.

=head2 S<createBuffer($name,'F',$file)>

This macro loads the file in a new buffer. On successful completion, it
returns a true value. Otherwise, it returns a false value.

=head2 S<createBuffer($name,'H',$file[,$size])>

This macro creates a new buffer with the head of the specified file. By
default, it considers the first 64KiB. On successful completion, it returns a
true value. Otherwise, it returns a false value.

The buffer size will never exceed the file size. When the whole file is loaded,
it returns a negative value. Otherwise, it returns a positive value.

=head2 S<createBuffer($name,'R',$file)>

This macro opens the file in read-only mode. On successful completion, it
returns a true value. Otherwise, it returns a false value.

=head2 S<createBuffer($name,'T',$file[,$size])>

This macro creates a new buffer with the tail of the specified file. By
default, it considers the last 64KiB. On successful completion, it returns a
true value. Otherwise, it returns a false value.

The buffer size will never exceed the file size. When the whole file is loaded,
it returns a negative value. Otherwise, it returns a positive value.

=cut

sub _m_create
{ my ($slf, $ctx, $nam, $typ, $arg, $max) = @_;

  if ($nam && $typ)
  { my $obj;

    # Delete any previous buffer associated to this name
    delete($slf->{'_buf'}->{$nam})->close if exists($slf->{'_buf'}->{$nam});

    # Create the new buffer
    $slf->{'_buf'}->{$nam} = $obj
      if defined($obj = RDA::Object::Buffer->new($typ, $arg, $max));

    # Return the completion status
    return $obj->is_complete ? -1 : 1 if exists($slf->{'_buf'}->{$nam});
  }
  0;
}

=head2 S<deleteBuffer($name)>

This macro deletes the specified buffer.

=cut

sub _m_delete
{ my ($slf, $ctx, $nam) = @_;

  return undef unless defined($nam) && exists($slf->{'_buf'}->{$nam});
  delete($slf->{'_buf'}->{$nam})->close;
}


=head2 S<filterBuffer($name,$alt,$options[,$begin,$end,...])>

This macro replaces all strings that are delimited by one of the regular
expression pairs by the alternative text. The regular expressions should not
contain backtracking constructions. The following options are supported:

=over 9

=item B<    'i' > Ignores case distinctions in the patterns

=item B<    's' > Treats the buffer as a single line

=back

It returns the number of modifications.

This macro has no effect on read-only file buffers.

=cut

sub _m_filter
{ my ($slf, $ctx, $nam, @arg) = @_;

  (defined($nam) && exists($slf->{'_buf'}->{$nam}))
    ? $slf->{'_buf'}->{$nam}->filter(@arg)
    : 0;
}

=head2 S<getBytes($name,$size[,$skip])>

This macro gets the specified number of bytes from the current position into
the buffer. You can specify the number of bytes to skip as an extra
argument. It returns an undefined value if this is not possible.

=cut

sub _m_getbytes
{ my ($slf, $ctx, $nam, $siz, $skp) = @_;
  my ($buf, $hnd);

  return undef unless defined($nam) && exists($slf->{'_buf'}->{$nam})
    && defined($siz);
  return '' unless $siz > 0;

  $hnd = $slf->{'_buf'}->{$nam}->get_handle;
  $hnd->seek($skp, 1) if defined($skp);
  $hnd->read($buf, $siz);
  $buf;
}

=head2 S<getLine($name[,$skip])>

This macro gets a line from the current position into the buffer. You can
specify the number of lines to skip as an extra argument. It returns an
undefined value if this is not possible.

=cut

sub _m_getline
{ my ($slf, $ctx, $nam, $skp) = @_;

  (defined($nam) && exists($slf->{'_buf'}->{$nam}))
    ? $slf->{'_buf'}->{$nam}->get_line($skp)
    : undef;
}

=head2 S<getPos($name)>

This macro returns a value that represents the current position in the
buffer. If this is not possible, it returns an undefined value.

=cut

sub _m_getpos
{ my ($slf, $ctx, $nam) = @_;

  (defined($nam) && exists($slf->{'_buf'}->{$nam}))
    ? $slf->{'_buf'}->{$nam}->get_pos
    : undef;
}

=head2 S<grepBuffer($name,$re[,$options[,$length[,$min,$max]]])>

This macro returns the lines that match the regular expression. The following
options are supported:

=over 9

=item B<    'c' > Returns the match count instead of the match list

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the file

=item B<    'n' > Prefixes lines with a line number

=item B<    'o' > Prefixes lines with the offset to the next line

=item B<    'r' > Does not restart from the beginning of the file

=item B<    'v' > Inverts the sense of matching to select nonmatching lines

=back

It is possible to limit the number of matched lines to the specified number.
For a positive number, it returns the first matches only. For a negative
number, it returns the last matches only.

You can restrict search to a line range.

=cut

sub _m_grep
{ my ($slf, $ctx, $nam, $re, @arg) = @_;

  return () unless defined($nam) && exists($slf->{'_buf'}->{$nam}) && $re;
  $slf->{'_buf'}->{$nam}->grep($re, @arg);
}

=head2 S<inputLine($name[,$num])>

This macro returns the current input line number and takes an optional single
argument that, when given, sets the value. If you do not provide an argument,
the previous value is unchanged.

=cut

sub _m_input
{ my ($slf, $ctx, $nam, $num) = @_;

  (defined($nam) && exists($slf->{'_buf'}->{$nam}))
    ? $slf->{'_buf'}->{$nam}->input_line($num)
    : undef;
}

=head2 S<setPos($name[,$pos])>

This macro uses the value of a previous C<getPos> call to return to a
previously visited position. When the position is omitted, it returns to the
beginning of the buffer.

It returns a true value on success and an undefined value on failure.

=cut

sub _m_setpos
{ my ($slf, $ctx, $nam, $pos) = @_;

  (defined($nam) && exists($slf->{'_buf'}->{$nam}))
    ? $slf->{'_buf'}->{$nam}->set_pos($pos)
    : undef;
}

=head2 S<writeBuffer([$rpt,]$name[,$str])>

This macro writes the buffer content to the report file. When you specify an
extra argument, the macro takes it as the first line and continues from the
current buffer position. Otherwise, the whole buffer is written.

=cut

sub _m_write
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_write($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_write($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_write
{ my ($slf, $ctx, $rpt, $nam, $str) = @_;
  my ($buf, $lin);

  if (exists($slf->{'_buf'}->{$nam}))
  { # Write the buffer to the report file, taking care on end of lines
    $buf = $slf->{'_buf'}->{$nam};
    $rpt->begin_block(1);
    if (defined ($str))
    { $rpt->write("$str\n");
    }
    else
    { $buf->set_pos;
    }
    while ($lin = $buf->get_line)
    { $lin =~ s/[\r\n]+$//;
      $lin = '' if $lin =~ m/^\000*$/;
      $rpt->write("$lin\n");
    }
    $rpt->end_block;

    # Indicate the successful completion
    return 1;
  }
  0;
}

=head1 PARSER MACROS

=head2 S<parse($name[,$line])>

This macro parses the buffer content. You can specify a first line to parse
as an extra argument. It returns zero on successful completion. Otherwise,
it returns a nonzero value.

=cut

sub _m_parse
{ my ($slf, $ctx, $nam, $lin) = @_;

  return undef unless defined($nam) && exists($slf->{'_buf'}->{$nam});
  $slf->{'_prs'}->parse($ctx, $slf->{'_buf'}->{$nam}, $lin);
}

=head2 S<parseBegin($block,$pattern,$next[,$group])>

This macro adds a conditional block start action to the action list of the
specified block. When a group is specified, all begin actions belonging to that
group are used as auto close conditions in the next block. It returns zero on
successful completion. Otherwise, it returns a nonzero value.

=cut

sub _m_parse_beg
{ my ($slf, $ctx, $blk, $pat, $nxt, $grp) = @_;

  $pat = ($pat =~ s/\#i$//) ? qr#$pat#i : qr#$pat# if defined($pat);
  $slf->{'_prs'}->add_begin($blk, $pat, $nxt, $grp);
}

=head2 S<parseBuffer()>

This macro returns a list containing all lines stored in the current block.

=cut

sub _m_parse_buf
{ shift->{'_prs'}->get_buffer;
}

=head2 S<parseCode($name,code,...)>

This method adds a code list to the action list of the specified block. It
returns zero on successful completion. Otherwise, it returns a nonzero value.

=cut

sub _m_parse_code
{ my ($slf, $ctx, $arg) = @_;
  my ($blk, $cod, $pat, @arg, @tbl);

  ($blk, @arg) = @$arg;
  RDA::Value::Scalar::new_number((ref($blk) && ($blk = $blk->eval_as_string))
    ? $slf->{'_prs'}->add_code($blk, @arg)
    : -1);
}

=head2 S<parseCount()>

This macro returns the number of lines contained in the current block.

=cut

sub _m_parse_cnt
{ shift->{'_prs'}->get_count;
}

=head2 S<parseEnd($block,$pattern)>

This macro adds a conditional block end action to the action list of the
specified block. It returns zero on successful completion. Otherwise, it
returns a nonzero value.

=cut

sub _m_parse_end
{ my ($slf, $ctx, $blk, $pat) = @_;

  $pat = ($pat =~ s/\#i$//) ? qr#$pat#i : qr#$pat# if defined($pat);
  $slf->{'_prs'}->add_end($blk, $pat);
}

=head2 S<parseHit($offset)>

This macro retrieves a subexpression from the last pattern match or the number
of subexpressions when an argument is not provided.

=cut

sub _m_parse_hit
{ my ($slf, $ctx, $off) = @_;

  $slf->{'_prs'}->get_hit($off);
}

=head2 S<parseInfo($block,$key[,value])>

This macro assigns the value to the given block key. It does not evaluate the 
code attribute values. Otherwise, it evaluates the value as a scalar and
executes the code values. If you omit the value, the block attribute is
deleted. It returns the previous value.

=cut

sub _m_parse_info
{ my ($slf, $ctx, $arg) = @_;
  my ($blk, $key, $val) = @$arg;

  return $VAL_UNDEF unless ref($blk) && ($blk = $blk->eval_as_string)
                        && ref($key) && ($key = $key->eval_as_string);
  $val = $slf->{'_prs'}->set_attr($blk, $key, $val);
  (ref($val) =~ $VALUE) ? $val :
  defined($val)         ? RDA::Value::Scalar::new_text($val) :
                          $VAL_UNDEF;
}

=head2 S<parseKeep()>

This macro indicates that the current line must be kept for the next action
loop.

=cut

sub _m_parse_keep
{ shift->{'_prs'}->keep;
}

=head2 S<parseLast()>

This macro gets the last block marker.

=cut

sub _m_parse_last
{ shift->{'_prs'}->get_marker;
}

=head2 S<parseLine([$count])>

This macro gets a new line from the file. That line becomes the new current
line of the parser. You can specify a number of lines to discard as an optional
argument. It returns an undefined value when the end of the file is reached.

=cut

sub _m_parse_line
{ my ($slf, $ctx, $cnt) = @_;

  $slf->{'_prs'}->get_line($cnt);
}

=head2 S<parseMarker([$str])>

This macro sets a new block marker.

=cut

sub _m_parse_mark
{ my ($slf, $ctx, $str) = @_;

  $slf->{'_prs'}->set_marker($str);
}

=head2 S<parsePattern($name,$pattern,code,...)>

This macro adds a pattern list to the action list of the specified block. When
the action is executed, only the code associated to the first matching pattern
is executed. It returns zero on successful completion. Otherwise, it returns
a nonzero value.

=cut

sub _m_parse_pat
{ my ($slf, $ctx, $arg) = @_;
  my ($blk, $cod, $pat, @arg, @tbl);

  ($blk, @arg) = @$arg;
  return RDA::Value::Scalar::new_number(-1)
    unless ref($blk) && ($blk = $blk->eval_as_string);
  while (($pat, $cod) = splice(@arg, 0, 2))
  { next unless ref($pat) =~ $VALUE && ref($cod) =~ $VALUE;
    $pat = $pat->eval_as_string;
    $pat = ($pat =~ s/\#i$//) ? qr#$pat#i : qr#$pat#;
    push(@tbl, $pat, $cod);
  }
  RDA::Value::Scalar::new_number($slf->{'_prs'}->add_pattern($blk, @tbl));
}

=head2 S<parseReplace($line)>

This macro replaces the current line by the specified value. It returns the
previous value.

=cut

sub _m_parse_repl
{ my ($slf, $ctx, $lin) = @_;

  $slf->{'_prs'}->set_line($lin);
}

=head2 S<parseReset()>

This macro resets the parser.

=cut

sub _m_parse_init
{ my $slf= shift;

  $slf->{'_prs'}->reset($slf->{'_agt'}->get_setting('PARSE_TRACE'));
  0;
}

=head2 S<parseQuit()>

This macro indicates that the parser must terminate its file processing. It
closes open blocks.

=cut

sub _m_parse_quit
{ shift->{'_prs'}->quit;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Parser|RDA::Object::Parser>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
