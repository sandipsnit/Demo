# Object.pm: Superclass Used for Implementing Basic RDA Object Methods

package RDA::Object;

# $Id: Object.pm,v 2.10 2012/05/11 08:59:16 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object.pm,v 2.10 2012/05/11 08:59:16 mschenke Exp $
#
# Change History
# 20120511  MSC  Improve the documentation.

=head1 NAME

RDA::Object - Superclass Used for Implementing Basic RDA Object Methods

=head1 SYNOPSIS

require RDA::Object;

=head1 DESCRIPTION

The objects of the C<RDA::Object> class regroups the methods common to RDA
objects.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);
%SDCL    = (
  met => {
    'as_class'  => {ret => 0},
    'as_string' => {ret => 0},
    'dump'      => {ret => 0},
    'get_oid'   => {ret => 0},
    },
  );

# Define the global private constants
my $OBJECT = 'RDA::Object';

# Define the global private variables
my $RPT_LST = "  \001* ";
my $RPT_NXT = ".N1\n";
my $RPT_XRF = "  ";

my %tb_ref = (
  ARRAY  => 'ARRAY',
  CODE   => 'sub { ... }',
  GLOB   => 'GLOB',
  HASH   => 'HASH',
  LVALUE => 'HASH',
  REF    => 'REF',
  SCALAR => 'SCALAR',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object-E<gt>new([name =E<gt> $value,...])>

The object constructor. It enables you to specify initial attributes at object
creation time.

C<RDA::Object> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'lvl' > > Trace level

=item S<    B<'oid' > > Object identified

=item S<    B<'par' > > Optional reference to the parent object

=item S<    B<'_inf'> > Optional reference for getting missing object attributes

=back

=cut

sub new
{ my $cls = shift;

  # Create the object and return its reference
  bless {@_}, ref($cls) || $cls;
}

=head2 S<$h-E<gt>as_class>

This method returns the object class.

=cut

sub as_class
{ ref(shift);
}

=head2 S<$h-E<gt>as_string>

This method returns the object as a string.

=cut

sub as_string
{ my ($slf) = @_;

  exists($slf->{'oid'}) ? '['.$slf->{'oid'}.']' : '';
}

=head2 S<$h-E<gt>delete>

This method deletes the object.

=cut

sub delete
{ my ($ref, @tbl);

  # Delete associated objects
  $ref = ref($_[0]);
  @tbl = eval "\@$ref\:\:DELETE";
  foreach my $key (@tbl)
  { my $val = delete($_[0]->{$key});
    next unless ($ref = ref($val));
    if ($ref eq 'HASH')
    { foreach my $obj (values(%$val))
      { eval {$obj->delete};
      }
      undef %$val;
    }
    elsif ($ref eq 'ARRAY')
    { foreach my $obj (@$val)
      { eval {$obj->delete};
      }
      undef @$val;
    }
    elsif ($ref ne 'CODE')
    { eval {$val->delete};
    }
  }

  # Delete the object
  undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>dump([$level[,$text]])>

This method returns a string containing the object dump. You can provide an
indentation level and a prefix text as extra parameters.

=cut

sub dump
{ my ($slf, $lvl, $txt) = @_;
  my ($ref, @tbl);

  $ref = ref($slf);
  @tbl = eval "\@$ref\:\:DUMP";
  dump_obj($slf, {@tbl}, $lvl, $txt);
}

sub dump_obj
{ my ($slf, $tbl, $lvl, $txt) = @_;
  my ($buf, $pre);

  $lvl = 0 unless defined($lvl);
  $txt = '' unless defined($txt);
  $tbl = {} unless ref($tbl);

  $pre = '  ' x $lvl;
  $tbl->{'flg'} = 0 unless exists($tbl->{'flg'});
  $tbl->{'typ'} = 'Hash';
  $tbl->{'slf'}->{$slf} = ref($slf).'=Hash()';
  $tbl->{'obj'}->{$OBJECT} = 1;
  $pre.$txt."bless(\{\n".dump_hash($slf, $tbl, $lvl, '')
    .$pre."}, '".ref($slf)."')";
}

sub dump_array
{ my ($slf, $tbl, $lvl, $arg) = @_;
  my ($buf, $cnt, $pre, $ref, $typ);

  $pre = '  ' x ++$lvl;
  $buf = '';
  $cnt = 0;
  $typ = $tbl->{'typ'};
  foreach my $val (@$slf)
  { $ref = ref($val);
    if ($ref && exists($tbl->{'slf'}->{$val}))
    { $buf .= $pre.$tbl->{'slf'}->{$val}."\n";
    }
    elsif ($ref eq 'ARRAY')
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg$cnt)";
      $buf .= $pre."[\n";
      $buf .= dump_array($val, $tbl, $lvl, "$arg$cnt,");
      $buf .= "$pre]\n";
    }
    elsif (exists($tbl->{'arr'}->{$ref}))
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg$cnt)";
      $buf .= $pre."bless([\n";
      $buf .= dump_array($val, $tbl, $lvl, "$arg$cnt,");
      $buf .= "$pre], '$ref')\n";
    }
    elsif ($ref eq 'HASH')
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg$cnt)";
      $buf .= $pre."{\n";
      $buf .= dump_hash($val, $tbl, $lvl, "$arg$cnt,");
      $buf .= "$pre}\n";
    }
    elsif (exists($tbl->{'hsh'}->{$ref}))
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg$cnt)";
      $buf .= $pre."bless({\n";
      $buf .= dump_hash($val, $tbl, $lvl, "$arg$cnt,");
      $buf .= "$pre}, '$ref')\n";
    }
    elsif (exists($tbl->{'obj'}->{$ref}))
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg$cnt)";
      $buf .= $val->dump($lvl);
      $buf .= "\n";
    }
    elsif (exists($tb_ref{$ref}))
    { $buf .= $pre.$tb_ref{$ref}."\n";
    }
    elsif ($ref)
    { $buf .= $pre.$ref;
      eval {
        $buf .= '('.$val->as_string.')' if $val->can('as_string');
      };
      $buf .= "(**$val**)" if $@;
      $buf .= "\n";
    }
    elsif (defined($val))
    { $buf .= $pre;
      $buf .= _encode($val, $tbl->{'flg'});
      $buf .= "\n";
    }
    else
    { $buf .= $pre."undef\n";
    }
    ++$cnt;
  }
  $buf;
}

sub dump_hash
{ my ($slf, $tbl, $lvl, $arg) = @_;
  my ($buf, $flg, $pre, $ref, $typ, $val);

  $pre = '  ' x ++$lvl;
  $buf = '';
  $typ = $tbl->{'typ'};
  foreach my $key (sort keys(%$slf))
  { $flg = $tbl->{'flg'};
    $tbl->{'flg'} = $tbl->{'mlt'}->{$key} if exists($tbl->{'mlt'}->{$key});
    $ref = ref($val = $slf->{$key});
    if ($ref && exists($tbl->{'str'}->{$key}))
    { if ($ref eq 'ARRAY')
      { $buf .= "$pre'$key' => [ ... ]\n";
      }
      elsif ($ref eq 'CODE')
      { $buf .= "$pre'$key' => sub { ... }\n";
      }
      elsif ($ref eq 'HASH')
      { $buf .= "$pre'$key' => { ... }\n";
      }
      else
      { $buf .= "$pre'$key' => ".$val->as_string."\n";
      }
    }
    elsif ($ref && exists($tbl->{'slf'}->{$val}))
    { $buf .= "$pre'$key' => ".$tbl->{'slf'}->{$val}."\n";
    }
    elsif ($ref eq 'ARRAY')
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg'$key')";
      $buf .= "$pre'$key' => [\n";
      $buf .= dump_array($val, $tbl, $lvl, "$arg'$key',");
      $buf .= "$pre]\n";
    }
    elsif (exists($tbl->{'arr'}->{$ref}))
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg'$key')";
      $buf .= "$pre'$key' => bless([\n";
      $buf .= dump_array($val, $tbl, $lvl, "$arg'$key',");
      $buf .= "$pre], '$ref')\n";
    }
    elsif ($ref eq 'HASH')
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg'$key')";
      $buf .= "$pre'$key' => {\n";
      $buf .= dump_hash($val, $tbl, $lvl, "$arg'$key',");
      $buf .= "$pre}\n";
    }
    elsif (exists($tbl->{'hsh'}->{$ref}))
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg'$key')";
      $buf .= "$pre'$key' => bless({\n";
      $buf .= dump_hash($val, $tbl, $lvl, "$arg'$key',");
      $buf .= "$pre}, '$ref')\n";
    }
    elsif (exists($tbl->{'obj'}->{$ref}))
    { $tbl->{'slf'}->{$val} = "$ref=$typ($arg'$key')";
      $buf .= $val->dump($lvl, "'$key' => ");
      $buf .= "\n";
    }
    elsif (exists($tb_ref{$ref}))
    { $buf .= "$pre'$key' => ".$tb_ref{$ref}."\n";
    }
    elsif ($ref)
    { $buf .= "$pre'$key' => $ref";
      eval {
        $buf .= '('.$val->as_string.')' if $val->can('as_string');
      };
      $buf .= "(**$val**)" if $@;
      $buf .= "\n";
    }
    elsif (defined($val))
    { $buf .= "$pre'$key' => ";
      $buf .= _encode($val, $tbl->{'flg'});
      $buf .= "\n";
    }
    else
    { $buf .= "$pre'$key' => undef\n";
    }
    $tbl->{'flg'} = $flg;
  }
  $buf;
}

sub _encode
{ my ($val, $flg) = @_;

  $val =~ s/([^\012\040\041\043-\176])/sprintf("\\%03o", ord($1))/eg;
  $val =~ s/\012/\\012/g unless $flg;
  '"'.$val.'"';
}

=head2 S<$h-E<gt>get_info($key[,$default])>

This method returns the value of the given object key. If the object key does
not exist, then it returns the default value.

=cut

sub get_info
{ my ($slf, $key, $dft) = @_;

  exists($slf->{$key})   ? $slf->{$key} :
  exists($slf->{'_inf'}) ? $slf->{'_inf'}->get_info($key, $dft) :
                           $dft;
}

=head2 S<$h-E<gt>get_level>

This method returns the trace level.

=cut

sub get_level
{ shift->{'lvl'};
}

=head2 S<$h-E<gt>get_oid>

This method returns the object identifier.

=cut

sub get_oid
{ shift->{'oid'};
}

=head2 S<$h-E<gt>get_parent($default)>

This method returns the reference to the parent object when defined. Otherwise,
it returns the default value.

=cut

sub get_parent
{ my ($slf, $dft) = @_;

  (exists($slf->{'par'}) && ref($slf->{'par'})) ? $slf->{'par'} : $dft;
}

=head2 S<$h-E<gt>get_top([$name[,$default]])>

This method returns the value of a top object attribute, or the default value
when the attribute is not defined.

It returns the reference of the top object when no attribute is specified.

=cut

sub get_top
{ my ($slf, $nam, $dft) = @_;

  $slf = $slf->{'par'} while exists($slf->{'par'}) && ref($slf->{'par'});
  !defined($nam)       ? $slf :
  exists($slf->{$nam}) ? $slf->{$nam} :
                         $dft;
}

=head2 S<$h-E<gt>set_info($key[,$value])>

This method assigns a new value to the given object attribute when the value is
defined. Otherwise, it deletes the object attribute.

It returns the previous value.

=cut

sub set_info
{ my ($slf, $key, $val) = @_;

  if (defined($val))
  { ($slf->{$key}, $val) = ($val, $slf->{$key});
  }
  else
  { $val = delete($slf->{$key});
  }
  $val;
}

=head2 S<$h-E<gt>set_trace([$level])>

This method specifies the trace level and returns the previous trace level.

=cut

sub set_trace
{ my ($slf, $lvl) = @_;
  my ($old);

  $old = $slf->{'lvl'};
  $slf->{'lvl'} = ($lvl > 0) ? $lvl : 0 if defined($lvl);
  $old;
}

=head2 S<$h-E<gt>xref>

This method analyzes the object interface and returns a report.

=cut

sub xref
{ my ($slf) = @_;
  my ($buf, $cls, $def, $lgt, $max, $tbl, %tbl);

  # Get the interface definition
  $cls = ref($slf) || $slf;
  eval "require $cls";
  $def = {eval "\%${cls}::SDCL"} unless $@;

  # Produce the report
  $buf = _dsp_name("$cls SDCL Interface");
  if (ref($def) eq 'HASH' && keys(%$def))
  { $buf .= _dsp_text($RPT_LST, "Uses implicitly: "
      .join(', ', map {_dsp_link($_)} @{$def->{'dep'}}))
      if exists($def->{'dep'});
    $buf .= _dsp_text($RPT_LST, "Subclassess: "
      .join(', ', map {_dsp_link($_)} @{$def->{'det'}}))
      if exists($def->{'det'});
    $buf .= _dsp_text($RPT_LST, "Includes methods from: "
      .join(', ', map {_dsp_link($_)} @{$def->{'inc'}}))
      if exists($def->{'inc'});
    $buf .= _dsp_text($RPT_LST, "Synonyms: ``"
      .join('``, ``', @{$def->{'syn'}})."``")
      if exists($def->{'syn'});
    $buf .= _dsp_text($RPT_LST, "Defines global object: ``"
      .join('``, ``', @{$def->{'glb'}})."``")
      if exists($def->{'glb'});
    $buf .= _dsp_text($RPT_LST,
      "Objects can be created with the ``new`` macro.")
      if exists($def->{'new'});
    $buf .= _dsp_text($RPT_LST, "Objects can use the password manager.")
      if exists($def->{'pwd'});
    $buf .= _dsp_text($RPT_LST, "Object trace is controlled by the ``"
      .$def->{'trc'}."`` environment variable.")
      if exists($def->{'trc'});
    $buf .= $RPT_NXT;

    if (exists($def->{'cmd'}))
    { $max = 0;
      %tbl = ();
      foreach my $nam (sort keys(%{$def->{'cmd'}}))
      { $max = $lgt if ($lgt = length($nam)) > $max;
        $tbl{$nam} = '\040';
      }
      $buf .= _dsp_table("Additional Commands:", \%tbl, $max);
    }

    if (exists($def->{'met'}))
    { $max = 0;
      %tbl = ();
      foreach my $nam (sort keys(%{$tbl = $def->{'met'}}))
      { my ($typ, @arg);

        $max = $lgt if ($lgt = length($nam)) > $max;
        push(@arg,  $tbl->{$nam}->{'ret'}
          ? 'Evaluated in a list context'
          : 'Evaluated in a scalar context');
        $typ = exists($tbl->{$nam}->{'evl'}) ? $tbl->{$nam}->{'evl'} : '';
        push(@arg, 'argument list evaluated as a SDCL value') if $typ eq 'E';
        push(@arg, 'argument list evaluated as a line')       if $typ eq 'L';
        push(@arg, 'argument list not evaluated')             if $typ eq 'N';
        push(@arg, 'package reference inserted as argument')
          if $tbl->{$nam}->{'blk'};
        $tbl{$nam} = join(', ', @arg);
      }
      $buf .= _dsp_table("Available Methods:", \%tbl, $max);
    }

    if (exists($def->{'als'}))
    { $max = 0;
      %tbl = ();
      foreach my $nam (sort keys(%{$tbl = $def->{'als'}}))
      { my ($obj, $met, @arg) = @{$tbl->{$nam}};
        $max = $lgt if ($lgt = length($nam)) > $max;
        $tbl{$nam} = '``'.$obj.'->'.$met.'('.join(',', @arg, '...').')``';
      }
      $buf .= _dsp_table("Defined Aliases:", \%tbl, $max);
    }
  }
  else
  { $buf .= _dsp_text($RPT_XRF, "No interface defined")
  }
  $buf;
}

sub _dsp_link
{ my ($cls) = @_;
  my (@tbl);

  @tbl = split(/::/, $cls);
  '!!xref_obj:'.join('/',@tbl).'!'.$cls.'!!';
}

sub _dsp_name
{ my ($ttl) = @_;

  ".R '$ttl'\n"
}

sub _dsp_table
{ my ($ttl, $tbl, $max) = @_;
  my ($buf);

  $buf = _dsp_title($ttl);
  $max += 4;
  foreach my $key (sort keys(%$tbl))
  { $buf .= _dsp_text(sprintf("%s\001%-*s  ", $RPT_XRF, $max, "``$key``"),
      $tbl->{$key});
  }
  $buf.$RPT_NXT;
}

sub _dsp_text
{ my ($pre, $txt, $nxt) = @_;

  $txt =~ s/\n{2,}/\n\\040\n/g;
  $txt =~ s/(\n|\\n)/\n\n.I '$pre'\n/g;
  ".I '$pre'\n$txt\n\n".($nxt ? ".N $nxt\n" : "");
}

sub _dsp_title
{ my ($ttl) = @_;

  ".T '$ttl'\n"
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
