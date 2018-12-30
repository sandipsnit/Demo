# Parser.pm: Class Used for Parser Objects
package RDA::Object::Parser;

# $Id: Parser.pm,v 2.11 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Parser.pm,v 2.11 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Parser - Class Used for Parser Objects

=head1 SYNOPSIS

require RDA::Object::Parser;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Parser> class are used to parse data.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  inc => [qw(RDA::Object)],
  met => {
    'add_begin'   => {ret => 0},
    'add_code'    => {ret => 0, evl => 'N'},
    'add_end'     => {ret => 0},
    'add_pattern' => {ret => 0, evl => 'N'},
    'get_buffer'  => {ret => 1},
    'get_count'   => {ret => 0},
    'get_hit'     => {ret => 0},
    'get_info'    => {ret => 0},
    'get_line'    => {ret => 0},
    'get_marker'  => {ret => 0},
    'keep'        => {ret => 0},
    'parse'       => {ret => 0, blk => 1},
    'quit'        => {ret => 0},
    'reset'       => {ret => 0},
    'set_attr'    => {ret => 0, evl => 'N'},
    'set_info'    => {ret => 0},
    'set_line'    => {ret => 0},
    'set_marker'  => {ret => 0},
    'set_trace'   => {ret => 0},
    },
  new => 1,
  trc => 'PARSE_TRACE',
  );

# Define the global private constants
my $NL  = "\n";
my $TRC = 'PARSE> ';

# Define the global private variables
my %tb_cod = map {$_ => 1} qw(beg end fmt var);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Parser-E<gt>new($trace)>

The object constructor. It takes the object trace level as an argument.

C<RDA::Object:Parser> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'beg' > > Code to execute at the beginning of a block (B,R)

=item S<    B<'buf' > > Block line buffer size (B,R)

=item S<    B<'end' > > Code to execute at the end of a block (B,R)

=item S<    B<'esc' > > Continuation character (P)

=item S<    B<'fmt' > > Code to execute to reformat the input line (P)

=item S<    B<'flp' > > First line parsing indicator (B,R)

=item S<    B<'ini' > > Initially open blocks (P)

=item S<    B<'lin' > > Current line (P)

=item S<    B<'llp' > > Last line parsing indicator (B,R)

=item S<    B<'ltr' > > Left trim indicator (P)

=item S<    B<'max' > > Maximum number of lines in a block (B,R)

=item S<    B<'par' > > Parent information import indicator (B)

=item S<    B<'rda' > > RDA indicator (P)

=item S<    B<'rtr' > > Right trim indicator (P)

=item S<    B<'trc' > > Trace indicator (P)

=item S<    B<'-blk'> > Block definition (P)

=item S<    B<'-buf'> > Block line buffer (R)

=item S<    B<'-cnt'> > Block line counter (R)

=item S<    B<'-cur'> > Current runtime block reference (P)

=item S<    B<'-end'> > Parser termination indicator (P)

=item S<    B<'-get'> > Get line routine (P)

=item S<    B<'-hit'> > Subexpression list of last pattern match (R)

=item S<    B<'-inp'> > Input buffer (P)

=item S<    B<'-kpt'> > Keep current line indicator (P)

=item S<    B<'-lin'> > Line indicator (P)

=item S<    B<'-mrk'> > Last block marker (R)

=item S<    B<'-nam'> > Block name (B,R)

=item S<    B<'-par'> > Parent runtime block reference (R)

=item S<    B<'-pgm'> > Block script (B,R)

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $trc) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {}, ref($cls) || $cls;

  # Initialize the parser end return the object reference
  $slf->reset($trc);
}

=head2 S<$h-E<gt>get_buffer>

This method returns a list containing all lines stored in the current block.

=cut

sub get_buffer
{ @{shift->{'-cur'}->{'-buf'}};
}

=head2 S<$h-E<gt>get_count>

This method returns the number of lines contained in the current block.

=cut

sub get_count
{ shift->{'-cur'}->{'-cnt'};
}

=head2 S<$h-E<gt>get_hit($off)>

This method retrieves a subexpression from the last pattern match or the number
of subexpressions when no argument is provided.

=cut

sub get_hit
{ my ($slf, $off) = @_;

  $slf = $slf->{'-cur'};
  !exists($slf->{'-hit'})
    ? undef
    : defined($off) ? $slf->{'-hit'}->[$off] : (scalar @{$slf->{'-hit'}});
}

=head2 S<$h-E<gt>get_line([$cnt])>

This method gets a new line from the file. That line becomes the new current
line of the parser. You can specify a number of lines to discard as an optional
argument. It returns an undefined value when the end of the file is reached.

=cut

sub get_line
{ my ($slf, $cnt) = @_;

  if (defined($cnt))
  { &{$slf->{'-get'}}($slf, 1) while $cnt-- > 0;
  }
  $slf->{'lin'} = &{$slf->{'-get'}}($slf);
}

sub _gen_get_line
{ my ($slf) = @_;
  my $buf = '';

  $buf = 'sub {'.$NL.'my ($slf, $skp) = @_;';
  if (length($slf->{'esc'}))
  { # Get a line and its continuation lines
    $buf .= $NL.'my ($flg, $lin, $str);'
           .$NL.'$str = "";'
           .$NL.'while (defined($str = $slf->{"-inp"}->getline))'
           .$NL.'{ $flg = 1;'
           .$NL.'  $lin .= $str;'
           .$NL.'  $lin =~ s/[\n\r]+$//;'
           .$NL.'  last unless $lin =~ s#'.$slf->{'esc'}.'$##;'
           .$NL.'}'
           .$NL.'unless ($flg)'
           .$NL.'{ $slf->{"-lin"} = 0;'
           .$NL.'  return undef;'
           .$NL.'}';
  }
  else
  { # Get single line
    $buf .= $NL.'my $lin;'
           .$NL.'unless (defined($lin = $slf->{"-inp"}->getline))'
           .$NL.'{ $slf->{"-lin"} = 0;'
           .$NL.'  return undef;'
           .$NL.'}';
  }
  $buf .= $NL.'return "" if $skp;';

  # Treat the line
  $buf .= $NL.'$lin =~ s/[\n\r]+$//;';
  $buf .= $NL.'$lin =~ s/^\s+//;' if $slf->{'ltr'};
  $buf .= $NL.'$lin =~ s/\s+$//;' if $slf->{'rtr'};

  # Reformat the line
  if (ref($slf->{'fmt'}))
  { $buf .= $slf->{'rda'}
          ? $NL.'$slf->{"lin"} = $lin;'.
            $NL.'$slf->{"fmt"}->eval_as_string;'
          : $NL.'&{$slf->{"fmt"}}($lin);';
  }
  else
  { $buf .= $NL.'$lin;';
  }
  $buf .= '}';

  # Generate the code
  $slf->{'-get'} = eval $buf;
  die "RDA-01180: Error in reader compilation:\n $@\n" if $@;
}

# Reformat the line
sub _fmt_line
{ my ($slf, $lin) = @_;

  # Treat the line
  $lin =~ s/[\n\r]+$//;
  $lin =~ s/^\s+// if $slf->{'ltr'};
  $lin =~ s/\s+$// if $slf->{'rtr'};

  # Reformat the line
  return $lin                   unless ref($slf->{'fmt'});
  return &{$slf->{'fmt'}}($lin) unless $slf->{'rda'};
  $slf->{'lin'} = $lin;
  $slf->{'fmt'}->eval_as_string;
}

=head2 S<$h-E<gt>get_marker>

This method returns the last block marker.

=cut

sub get_marker
{ shift->{'-cur'}->{'-mrk'};
}

=head2 S<$h-E<gt>keep>

This method indicates that the current line must be kept for the next action
loop.

=cut

sub keep
{ shift->{'-kpt'} = 1;
}

=head2 S<$h-E<gt>parse($blk,$buf[,$lin])>

This method parses a file. You can specify the first line as an extra argument.

=cut

sub parse
{ my ($slf, $blk, $buf, $lin) = @_;
  my ($cod);

  # Initialization
  $slf->{'-inp'} = $buf->get_handle;
  $slf->{'-end'} = 0;
  $slf->{'-kpt'} = 0;
  $slf->{'-lin'} = 1;

  # Define an internal variable for the current line
  if ($blk)
  { $slf->{'-ctx'} = $blk->{'ctx'};
    $slf->{'-ctx'}->define_internal('lin', 'line', $slf, sub {my $lin;
      defined($lin = shift->{'lin'})
        ? RDA::Value::Scalar::new_text($lin)
        : $VAL_UNDEF;
      });
  }

  # Generate the parser
  _gen_get_line($slf);
  $cod = _gen_parse($slf);

  # Parse the file
  eval {&$cod($slf, $lin)};
  die sprintf("RDA-01182: Parsing error in %s near line %s:\n %s\n",
    $slf->{'-nam'}, $slf->{'-inp'}->input_line_number, $@) if $@;

  # Indicate a successful completion
  0;
}

sub _check_use
{ my ($slf, $key) = @_;

  foreach my $blk (values(%{$slf->{'-blk'}}))
  { return 1 if exists($blk->{$key}) && $blk->{$key};
  }
  0;
}

sub _gen_parse
{ my ($slf) = @_;
  my ($buf, $f_b, $f_m, $rda, $sub, $trc);

  $rda = $slf->{'rda'};
  $trc = $slf->{'trc'};
  $f_b = _check_use($slf, 'buf');
  $f_m = _check_use($slf, 'max');
  $buf = 'sub {'.
          $NL.'my ($slf,$lin) = @_;'.
          $NL.'my ($cnt,$cur,$prv,$siz,$typ);';

  # Create the initial runtime blocks
  $buf .= $NL.' print "'.$TRC.'*** Auto init block TOP\n";'
    if $trc > 0;
  $buf .= $NL.' $slf->{"-cur"} = $cur = $slf->_set_block("TOP");';
  $buf .= $NL.' $cur = $slf->_beg_block($slf->{"ini"},"*** Auto init block ");'
    if $slf->{'ini'};

  # Check if the first line has not been provided as an argument
  $buf .= $NL.' $slf->{"lin"} = defined($lin)'.
          $NL.'  ? $slf->_fmt_line($lin)'.
          $NL.'  : &{$slf->{"-get"}}($slf);';

  # Parse the file
  $buf .= $NL.' while ($slf->{"-lin"})'.
          $NL.' {';
  $buf .= $NL.'  print "'.$TRC.'Line ".$slf->{"-inp"}->input_line_number'.
          $NL.'   .": \'".$slf->{"lin"}."\'\n";'
    if $trc;

  # Check if the maximum number of lines in the block is reached
  $buf .= $NL.'  $cnt = $cur->{"-cnt"}++;';
  $buf .= $NL.'  if ($cur->{"max"} && $cnt >= $cur->{"max"})'.
          $NL.'  {$cur = $slf->_end_block(1,"*** Size close block ");'.
          $NL.'   next;'.
          $NL.'  }'
    if $f_m;
  $buf .= $NL.'  if ($siz = $cur->{"buf"})'.
          $NL.'  {push(@{$cur->{"-buf"}},$slf->{"lin"});'.
          $NL.'   $prv = ($siz > 0 && (scalar @{$cur->{"-buf"}}) > $siz)'.
          $NL.'    ? shift(@{$cur->{"-buf"}})'.
          $NL.'    : undef;'.
          $NL.'  }'
    if $f_b;

  # Execute the block script
  $buf .= $NL.'  ++$cnt unless $cur->{"flp"};';
  $buf .= $NL.'  foreach my $act (@{$cur->{"-pgm"}})'.
          $NL.'  {$typ = $act->[0];'.
          $NL.'   if ($typ eq "A")';     # --- Block auto close
  $buf .= $NL.'   {next unless $cnt && $slf->{"lin"} =~ $act->[1];';
  $buf .= $NL.'    --$cur->{"-cnt"};';
  $buf .= $NL.'    if ($cur->{"buf"})'.
          $NL.'    {pop(@{$cur->{"-buf"}});'.
          $NL.'     unshift(@{$cur->{"-buf"}}, $prv) if defined($prv);'.
          $NL.'    }'
    if $f_b;
  $buf .= $NL.'    $cur = $slf->_end_block($act->[2],"*** Auto close block ");';
  $buf .= $NL.'    if ($act->[3])'.
          $NL.'    {$cur = $slf->_beg_block($act->[3],"*** Auto begin block ",'.
          $NL.'      $act->[4]);'.
          $NL.'     $slf->{"-kpt"} = $cur->{"flp"};'.
          $NL.'    }'.
          $NL.'    else'.
          $NL.'    {$slf->{"-kpt"} = 1;'.
          $NL.'    }';
  $buf .= $NL.'    last;';
  $buf .= $NL.'   }'.
          $NL.'   elsif ($typ eq "P")';  # --- Pattern group
  $buf .= $NL.'   { my ($off, $ret, $tbl);';
  $buf .= $NL.'     $ret = 0;';
  $buf .= $NL.'     $off = $act->[1];';
  $buf .= $NL.'     $tbl = $act->[2];';
  $buf .= $NL.'     while ($off--)';
  $buf .= $NL.'     {next unless (@{$cur->{"-hit"} ='.
          $NL.'       [$slf->{"lin"} =~ $tbl->[$off--]]});';
  $buf .= $rda
        ? $NL.'      $ret = $tbl->[$off]->eval_as_number;'
        : $NL.'      $ret = &{$tbl->[$off]}();';
  $buf .= $NL.'      print "'.$TRC.'Eval pattern code value: ".$ret."\n";'
    if $trc;
  $buf .= $NL.'      last;';
  $buf .= $NL.'     }';
  $buf .= $NL.'     last if $slf->{"-end"};';
  $buf .= $NL.'     if ($ret)'.
          $NL.'     {$cur = $slf->_end_block($ret,"*** Pattern close block ")'.
          $NL.'       if $ret > 0;'.
          $NL.'      last;'.
          $NL.'     }';
  $buf .= $NL.'   }'.
          $NL.'   elsif ($typ eq "B")';  # --- Block beginning
  $buf .= $NL.'   {next unless $slf->{"lin"} =~ $act->[1];';
  $buf .= $NL.'    $cur = $slf->_beg_block($act->[2],"*** Begin block ",'.
          $NL.'     $act->[3]);';
  $buf .= $NL.'    $slf->{"-kpt"} = $cur->{"flp"};';
  $buf .= $NL.'    last;';
  $buf .= $NL.'   }'.
          $NL.'   elsif ($typ eq "C")';  # --- Code execution
  $buf .= $NL.'   {my $ret;';
  $buf .= $rda
        ? $NL.'    $ret = $VAL_ZERO;'
        : $NL.'    $ret = 0;';
  $buf .= $NL.'    foreach my $cod (@{$act->[1]})';
  $buf .= $rda
        ? $NL.'    {$ret = $cod->eval_value;'.
          $NL.'    }'
        : $NL.'    {$ret = &$cod();'.
          $NL.'    }';
  $buf .= $rda
        ? $NL.'    print $ret->dump(0, "'.$TRC.'Eval code result: ")."\n";'
        : $NL.'    print "'.$TRC.'Eval code result: $ret\n";'
    if $trc;
  $buf .= $NL.'    last if $slf->{"-end"};';
  $buf .= $rda
        ? $NL.'    if ($ret = $ret->eval_as_number)'
        : $NL.'    if ($ret)';
  $buf .= $NL.'    {$cur = $slf->_end_block($ret,"*** Code close block ")'.
          $NL.'      if $ret > 0;'.
          $NL.'     last;'.
          $NL.'    }';
  $buf .= $NL.'   }'.
          $NL.'   elsif ($typ eq "E")';  # --- Block end
  $buf .= $NL.'   {next unless $slf->{"lin"} =~ $act->[1];';
  $buf .= $NL.'    $slf->{"-kpt"} = $cur->{"llp"};';
  $buf .= $NL.'    $cur = $slf->_end_block($act->[2],"*** Close block ");';
  $buf .= $NL.'    last;';
  $buf .= $NL.'   }'.
          $NL.'  }';

      # Get the next line
  $buf .= $NL.'  $slf->{"lin"} = &{$slf->{"-get"}}($slf)';
  $buf .= $NL.'   unless $slf->{"-kpt"};';
  $buf .= $NL.'  $slf->{"-kpt"} = 0;';
  $buf .= $NL.' }';

  # Close open blocks
  $buf .= $NL.' $slf->_end_block(-1,"*** EOF close block ");';
  $buf .= $NL.'}';

  # Generate the code
  $sub = eval $buf;
  die "RDA-01181: Error in parser compilation:\n $@\n" if $@;
  $sub;
}

=head2 S<$h-E<gt>quit>

This method indicates that the parser must terminate file processing. Open
blocks are closed.

=cut

sub quit
{ my $slf = shift;

  $slf->{'-lin'} = 0;
  $slf->{'-kpt'} = 1;
  $slf->{'-end'} = -1;
}

=head2 S<$h-E<gt>set_marker($str)>

This method specifies a new block marker and returns it.

=cut

sub set_marker
{ my ($slf, $str) = @_;

  $str = '' unless defined($str);
  $slf->{'-cur'}->{'-mrk'} =
    $slf->{'-inp'}->input_line_number.'|'.$slf->{'-inp'}->tell.':'.$str;
}

=head1 PARSER CONFIGURATION METHODS

=head2 S<$h-E<gt>add_begin($name,$pattern,$next[,$grp]])>

This method adds a conditional block start action to the action list of the
specified block. When you specify a group, all begin actions belonging to that
group are used as auto close conditions in the next block.

=cut

sub add_begin
{ my ($slf, $nam, $pat, $nxt, $grp) = @_;
  my $blk;
 
  return 1 unless ref($blk = $slf->_get_block($nam));
  return 2 unless $pat;
  return 3 unless $slf->_val_block($nxt);
  return 4 if $grp && $grp =~ /\W/;
  push(@{$blk->{'-pgm'}}, ['B', $pat, $nxt, $grp]);

  # Indicate a successful completion
  0;
}

=head2 S<$h-E<gt>add_code($block,code,...)>

This method adds a code list to the action list of the specified block.

=cut

sub add_code
{ my ($slf, $blk, @arg) = @_;
  my ($ref, @tbl);
 
  return 1 unless $blk && ref($blk = $slf->_get_block($blk));
  $ref = $slf->{'rda'} ? $VALUE : qr/^CODE$/;
  push(@{$blk->{'-pgm'}}, ['C', [@tbl]])
    if (@tbl = grep {ref($_) =~ $ref} @arg);

  # Indicate a successful completion
  0;
}

=head2 S<$h-E<gt>add_end($name,$pattern)>

This method adds a conditional block end action to the action list of the
specified block.

=cut

sub add_end
{ my ($slf, $nam, $pat, $nxt, $grp) = @_;
  my $blk;
 
  return 1 unless ref($blk = $slf->_get_block($nam));
  return 2 unless $pat;
  push(@{$blk->{'-pgm'}}, ['E', $pat, 1]);

  # Indicate a successful completion
  0;
}

=head2 S<$h-E<gt>add_pattern($name,$pattern,code,...)>

This method adds a pattern list to the action list of the specified block.

=cut

sub add_pattern
{ my ($slf, $blk, @arg) = @_;
  my ($cod, $pat, $ref, @tbl);

  return 1 unless $blk && ref($blk = $slf->_get_block($blk));
  $ref = $slf->{'rda'} ? $VALUE : qr/^CODE$/;
  while (($pat, $cod) = splice(@arg, 0, 2))
  { unshift(@tbl, $cod, $pat) if $pat && ref($cod) =~ $ref;
  }
  return 2 unless @tbl;
  push(@{$blk->{'-pgm'}}, ['P', (scalar @tbl), [@tbl]]);

  # Indicate a successful completion
  0;
}

=head2 S<$h-E<gt>reset>

This method resets the parser. It returns the reference of the parser object.

=cut

sub reset
{ my ($slf, $trc) = @_;
 
  # Reset the block definitions
  $slf->{'-blk'} = {};
  $slf->_get_block('TOP', $slf);

  # Define some global attributes
  $slf->{'esc'} = '';
  $slf->{'fmt'} = undef;
  $slf->{'ini'} = '';
  $slf->{'ltr'} = 0;
  $slf->{'rda'} = 1;
  $slf->{'rtr'} = 1;
  $slf->{'trc'} = $trc ? 1 : 0;

  # Return the parser object reference
  $slf;
}

=head2 S<$h-E<gt>set_attr($name,$key[,value])>

This method assigns the value to the given block attribute. It does not
evaluate code attributes. Otherwise, it evaluates the value as a scalar and
executes code values. When the value is omitted, it deletes the block
attribute. It returns the previous value.

=cut

sub set_attr
{ my ($slf, $blk, $key, $val) = @_;
  my ($old, $ref);

  if ($blk && $key && ref($blk = $slf->_get_block($blk)))
  { $old = $blk->{$key};
    $ref = $slf->{'rda'} ? $VALUE : qr/^CODE$/;
    if ($tb_cod{$key})
    { $blk->{$key} = (ref($val) =~ $ref) ? $val : undef;
    }
    elsif (ref($val) =~ $VALUE)
    { $blk->{$key} = $val->eval_as_scalar;
    }
    elsif (defined($val))
    { $blk->{$key} = $val;
    }
    else
    { delete($blk->{$key});
    }
  }
  $old;
}

=head2 S<$h-E<gt>set_line($line)>

This method replaces the current line by the specified value. It returns the
previous value.

=cut

sub set_line
{ my ($slf, $lin) = @_;

  ($slf->{'lin'}, $lin) = ($lin, $slf->{'lin'});
  $lin;
}

# --- Internal block routines -------------------------------------------------

# Begin one or more blocks
sub _beg_block
{ my ($slf, $nxt, $msg, $grp) = @_;
  my ($cod, $cur, $ref);

  $cur = $slf->{'-cur'};
  foreach my $nam (split(/\//, $nxt))
  { print $TRC.$msg.$nam."\n" if $slf->{'trc'};

    # Open the new block
    $cur = $slf->_set_block($nam, $cur, $grp);

    # Execute the begin code
    $ref = ref($cod = $cur->{'beg'});
    if ($ref eq 'CODE')
    { &$cod();
    }
    elsif ($ref =~ $VALUE)
    { $cod->eval_value(1);
    }
  }
  $slf->{'-cur'} = $cur;
}

# Dump a block
sub _dump_block
{ my ($blk, $pre) = @_;
  my ($buf, $val);

  $buf = $pre."Block ".$blk->{'-nam'}."\n";
  foreach my $key (sort keys(%$blk))
  { $val = $blk->{$key};
    if (ref($val) =~ $VALUE)
    { $buf .= $val->dump(1,"* $key=")."\n";
    }
    elsif (ref($val) eq 'ARRAY')
    { next unless $key eq '-pgm';
      $buf .= "  * -pgm:\n";
      foreach my $act (@$val)
      { $buf .= _dump_action($act);
      }
    }
    elsif (defined($val))
    { $buf .= "  * $key = $val\n";
    }
    else
    { $buf .= "  * $key\n";
    }
  }
  $buf;
}

sub _dump_action
{ my ($act, $str) = @_;
  my $buf = '';

  $buf .= "$str:\n" if $str;
  $buf .= "    $act: [";
  foreach my $arg (@$act)
  { if (ref($arg) eq 'ARRAY')
    { $buf .= "[\n";
      foreach my $det (@$arg)
      { if (ref($det) =~ $VALUE)
        { $buf .= $det->dump(3)."\n";
        }
        else
        { $buf .= "      $det\n";
        }
      }
      $buf .= "      ]\n    ";
    }
    elsif (defined($arg))
    { $buf .= $arg.' ';
    }
    else
    { $buf .= '*undef* ';
    }
  }
  $buf .= "]\n";
  $buf;
}

# End one or more blocks
sub _end_block
{ my ($slf, $lvl, $msg) = @_;
  my ($cod, $cur, $flg, $ref);

  $cur = $slf->{'-cur'};
  while ($lvl < 0 || (exists($cur->{'-par'}) && $lvl-- > 0))
  { print $TRC.$msg.$cur->{'-nam'}."\n" if $slf->{'trc'};

    # Execute the end code
    $ref = ref($cod = $cur->{'end'});
    if ($ref eq 'CODE')
    { &$cod();
    }
    elsif ($ref =~ $VALUE)
    { $cod->eval_value(1);
    }
 
    # Return to the parent block
    last unless exists($cur->{'-par'});
    $slf->{'-cur'} = $cur = $cur->{'-par'};
    print $TRC."--> Back in block ".$cur->{'-nam'}."\n" if $slf->{'trc'};
  }
  $cur;
}

# Get a block and create it on first use
sub _get_block
{ my ($slf, $nam, $blk) = @_;
 
  # Return a reference when the block already exists
  return $slf->{'-blk'}->{$nam} if exists($slf->{'-blk'}->{$nam});

  # Validate the name
  return undef unless $nam && $nam =~ m/^\w+$/;

  # Create it
  $blk = {} unless ref($blk);
  $slf->{'-blk'}->{$nam} = $blk;

  $blk->{'beg'} = undef;
  $blk->{'buf'} = 0;
  $blk->{'end'} = undef;
  $blk->{'flp'} = 1;
  $blk->{'llp'} = 1;
  $blk->{'max'} = 0;
  $blk->{'par'} = 1;

  $blk->{'-nam'} = $nam;
  $blk->{'-pgm'} = [];

  # Return the block reference
  $blk;
}

# Define a runtime block
sub _set_block
{ my ($slf, $ref, $par, $grp) = @_;
  my ($blk);

  # Get the reference block definition
  $ref = $slf->_get_block($ref) unless ref($ref);

  # Create the runtime block
  $blk = {};

  foreach my $key (qw(beg buf cnt end flp llp max par -nam))
  { $blk->{$key} = $ref->{$key} if exists($ref->{$key});
  }

  $blk->{'-buf'} = [];
  $blk->{'-cnt'} = 0;
  $blk->{'-mrk'} = undef;
  $blk->{'-pgm'} = [];

  # Inherit parent information
  if (ref($par))
  { $blk->{'-par'} = $par;
    if ($grp && $ref->{'par'})
    { # Extract parent actions 
      foreach my $act (@{$par->{'-pgm'}})
      { push(@{$blk->{'-pgm'}}, ['A', $act->[1], $act->[2] + 1])
          if $act->[0] eq 'A' || $act->[0] eq 'E';
        push(@{$blk->{'-pgm'}}, ['A', $act->[1], 1, $act->[2], $act->[3]])
          if $act->[0] eq 'B' && $act->[3] && $act->[3] eq $grp;
      }
     
      # Get parent attributes
      foreach my $key (qw(fmt ltr rtr))
      { $blk->{$key} = $par->{$key} unless exists($blk->{$key});
      }
    }
  }

  # Get the block change patterns
  push(@{$blk->{'-pgm'}}, @{$ref->{'-pgm'}});

  # Return the block reference
  $blk;
}

# Validate a block list
sub _val_block
{ my ($slf, $nxt) = @_;

  return 0 unless $nxt;
  foreach my $nam (split(/\//, $nxt))
  { return 0 unless ref($slf->_get_block($nam));
  }
  1; 
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object|RDA::Object>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
