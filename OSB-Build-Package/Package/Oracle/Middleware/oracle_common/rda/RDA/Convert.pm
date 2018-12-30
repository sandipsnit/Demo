# Convert.pm: Class Used for Managing Conversion Plugins

package RDA::Convert;

# $Id: Convert.pm,v 2.8 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Convert.pm,v 2.8 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Convert - Class Used for Managing Conversion Plugins

=head1 SYNOPSIS

require RDA::Convert;

=head1 DESCRIPTION

This package is designed to manage the XML conversion plugins.

The plugins must declare a global variable C<@PLUGIN>, which lists available
conversion methods. Each array element is an hash reference containing at least
the following keys:

=over 12

=item S<    B<'nam' > > Definition name

=item S<    B<'rnk' > > Definition rank

=item S<    B<'sel' > > Reference to the selection function

=item S<    B<'typ' > > Conversion type

=back

The definitions can contain additional keys that are specific to the selection
function. The conversion control object calls successively all applicable
selection functions with its reference, the definition hash reference, and the
block name as arguments. The selection function returns the conversion with the
highest rank that is applicable to the current block.

The selection functions have typically access to the module name and version,
the report name, and the operating system.

Supported conversion types are as following:

=over 9

=item B<    'B' > Block conversion

=item B<    'S' > Stat conversion

=item B<    'T' > Table conversion

=back

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.8 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Convert-E<gt>new($agt,$cfg)>

The object constructor. It takes the agent and SDP software configuration
object references as arguments.

An C<RDA::Convert> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'cnv' > > Active converters

=item S<    B<'ctx' > > Current context

=item S<    B<'eob' > > End of block indicator

=item S<    B<'ifh' > > Current input file handle

=item S<    B<'mod' > > Name of the current module

=item S<    B<'osn' > > Operating system used for report production

=item S<    B<'rpt' > > Name of the current report

=item S<    B<'typ' > > Active types

=item S<    B<'ver' > > Version of the current module

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_def'> > Module conversion definitions

=item S<    B<'_dir'> > Conversion directory

=item S<    B<'_dsp'> > Reference to the display control object

=item S<    B<'_lvl'> > Conversion trace level

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, $cfg) = @_;

  # Create the macro object and return its reference
  bless {
    cnv  => {},
    ctx  => {},
    eob  => 1,
    osn  => '',
    typ  => {},
    _agt => $agt,
    _def => {},
    _dir => $ENV{'RDA_CONVERT'} || $cfg->get_dir('D_RDA_PERL', 'Convert'),
    _dsp => $agt->get_display,
    _lvl => $agt->get_setting('CONVERT_TRACE', 0),
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>convert($ofh,$ifh,$blk[,$typ])>

This method determines the conversion method by executing all applicable
selection functions of the current module. It uses the conversion method with
the highest rank to converts a block. It returns a true value on successful
completion. Otherwise, it returns a false value.

=cut

sub convert
{ my ($slf, $ofh, $ifh, $blk, $typ) = @_;
  my ($fct);

  # Determine which conversion to do
  $typ = (defined($typ) && exists($slf->{'typ'}->{$typ}))
    ? $slf->{'typ'}->{$typ}
    : 'B';
  return 0 unless ($fct = $slf->search($typ, $blk));

  # Execute the conversion
  $slf->trace(2, "convert: Converting '$blk'\n");
  $slf->{'eob'} = 0;
  $slf->{'ifh'} = $ifh;
  eval {&$fct($slf, $ofh, $blk)};
  die "RDA-01230: Conversion error for '$blk':\n $@\n" if $@;
  1 while defined($slf->get_line);

  # Indicate the completion status
  1;
}

=head2 S<$h-E<gt>delete>

This method deletes the conversion control object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>get_cells($lin)>

This method gets all cells contained in a table row. It trims leading and
trailing and spaces.

=cut

sub get_cells
{ my ($slf, $lin) = @_;
  my ($txt, @tbl);

  while ($lin =~ s/([^\|]*)\|//)
  { $txt = $1;
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    push(@tbl, $txt);
  }
  @tbl;
}

=head2 S<$h-E<gt>get_context([$key[,$dft]])>

This method returns the value of a context property, or the default value when
the property is not defined.

It returns the reference of the context hash when no attribute is specified.

=cut

sub get_context
{ my ($slf, $key, $dft) = @_;

  !defined($key)                ? $slf->{'ctx'} :
  exists($slf->{'ctx'}->{$key}) ? $slf->{'ctx'}->{$key} :
                                  $dft;
}

=head2 S<$h-E<gt>get_line>

This method gets a block line. It trims trailing carriage return, line feed,
and spaces. It returns an undefined value when it reaches the block end.

=cut

sub get_line
{ my ($slf) = @_;
  my ($lin);

  unless ($slf->{'eob'})
  { if (defined($lin = $slf->{'ifh'}->getline))
    { $lin =~ s#[\n\r\s]+$##;  #
      return $lin unless $lin eq '</verbatim>';
    }
    $slf->{'eob'} = 1;
  }
  undef;
}

=head2 S<$h-E<gt>get_module>

This method returns the name of the current module. It returns an undefined
value when no signature is present in the report.

=cut

sub get_module
{ shift->{'mod'};
}

=head2 S<$h-E<gt>get_os>

This method returns the operation system used for report production. It returns
an undefined value when no signature is present in the report.

=cut

sub get_os
{ shift->{'osn'};
}

=head2 S<$h-E<gt>get_report>

This method returns the name of the current report. It returns an undefined
value when no signature is present in the report.

=cut

sub get_report
{ shift->{'rpt'};
}

=head2 S<$h-E<gt>get_version>

This method returns the version of the current module. It returns an undefined
value when no signature is present in the report.

=cut

sub get_version
{ shift->{'ver'};
}

=head2 S<$h-E<gt>init($ctx,$ifh)>

This method initializes the conversion control. On the first occurrence, it
loads all plugins related to the context module. They are regrouped in the
F<Convert/E<lt>moduleE<gt>> subdirectory of the C<D_RDA_PERL> directory group.

The conversion mechanism is enabled only for reports having a signature.

=cut

sub init
{ my ($slf, $ctx, $ifh) = @_;
  my ($def, $mod);

  if (exists($ctx->{'module'}))
  { $mod = uc($ctx->{'module'});
    $slf->trace(1, "convert: Initializing $mod for ".$ctx->{'report'}."\n");

    $def = _init($slf, $mod);
    $slf->{'cnv'} = $def->{'cnv'};
    $slf->{'mod'} = $mod;
    $slf->{'osn'} = $ctx->{'os'};
    $slf->{'rpt'} = $ctx->{'report'};
    $slf->{'typ'} = $def->{'typ'};
    $slf->{'ver'} = $ctx->{'version'};
  }
  else
  { $slf->{'cnv'} = {};
    $slf->{'osn'} = '';
    $slf->{'typ'} = {};
    delete($slf->{'mod'});
    delete($slf->{'rpt'});
    delete($slf->{'ver'});
  }
  $slf->{'ctx'} = $ctx;
  $slf->{'ifh'} = $ifh;
}

sub _init
{ my ($slf, $mod, $flg) = @_;
  my ($def, $src, %cnv);

  # Reuse a previous definition
  return $slf->{'_def'}->{$mod} if exists($slf->{'_def'}->{$mod});

  # Create a default definition
  if ($flg)
  { $def = {typ => {}};
  }
  else
  { $src = _init($slf, 'Common', 1);
    %cnv = map {$_ => [@{$src->{'cnv'}->{$_}}]} keys(%{$src->{'cnv'}});
    $def = {typ => {%{$src->{'typ'}}}};
  }

  # Load the plugins
  if (opendir(DIR, RDA::Object::Rda->cat_dir($slf->{'_dir'}, $mod)))
  { foreach my $nam (readdir(DIR))
    { next unless $nam =~ s/\.pm$//;
      $slf->trace(1, "convert: - Loading $mod/$nam\n");

      # Load the plugin definition
      eval "require Convert::$mod\::$nam";
      die "RDA-01231: Error encountered when loading the plugin "
        ."'$mod/$nam':\n $@\n" if $@;
      $src = {eval "\%Convert::$mod\::$nam\::PLUGIN"};
      die "RDA-01232: Plugin '$mod/$nam' definition error:\n $@\n" if $@;

      # Merge the definitions
      if (exists($src->{'cnv'}))
      { foreach my $itm (@{$src->{'cnv'}})
        { push(@{$cnv{$itm->{'typ'}}}, $itm)
            if exists($itm->{'typ'}) && exists($itm->{'rnk'});
        }
      }
      if (exists($src->{'typ'}))
      { foreach my $itm (keys(%{$src->{'typ'}}))
        { $def->{'typ'}->{$itm} = $src->{'typ'}->{$itm};
        }
      }
    }
    closedir(DIR);
  }

  # Sort the converters
  $def->{'cnv'} =
    {map {$_ => [sort {$b->{'rnk'} <=> $a->{'rnk'}} @{$cnv{$_}}]} keys(%cnv)};

  # Return the definition
  $slf->{'_def'}->{$mod} = $def;
}

=head2 S<$h-E<gt>search($typ,$blk[,$dft])>

This method determines the conversion method by executing all applicable
selection functions of the current module. It selects and returns the
conversion with the highest rank. Otherwise, it returns the default value.

=cut

sub search
{ my ($slf, $typ, $blk, $dft) = @_;
  my ($ret);

  if (exists($slf->{'cnv'}->{$typ}))
  { $slf->trace(2, "convert: Search conversion for '$typ:$blk'\n");
    foreach my $def (@{$slf->{'cnv'}->{$typ}})
    { next if exists($def->{'osn'}) && $def->{'osn'} ne $slf->{'osn'};
      $slf->trace(3, "convert: - Checking '".$def->{'nam'}."'\n");
      eval {$ret = &{$def->{'sel'}}($slf, $def, $blk)};
      die "RDA-01233: Search error for '$blk':\n $@\n" if $@;
      next unless defined($ret);
      $slf->trace(3, "convert: Found rank=".$def->{'rnk'}."\n");
      return $ret;
    }
  }
  $dft;
}

=head2 S<$h-E<gt>trace($level,$text)>

This method adds lines to the trace when it satisfies the minimal trace level.

=cut

sub trace
{ my ($slf, $lvl, $txt) = @_;

  $slf->{'_dsp'}->dsp_data($txt) unless $slf->{'_lvl'} < $lvl;
}

=head1 COMMON SELECTION METHODS

=head2 S<$h-E<gt>sel_block($def,$blk)>

This method determines if the current block needs some conversion based on
definition block table and possible operating system constraint, as
described respectively by the C<blk> and C<osn> definition keys.

Reports are internally converted to lower case.

=cut

sub sel_block
{ my ($slf, $def, $blk) = @_;
  my ($key);

  $key = lc($slf->{'rpt'});
  if (exists($def->{'blk'}->{$key}) && ref($def->{'blk'}->{$key}))
  { foreach my $rec (@{$def->{'blk'}->{$key}})
    { return $rec->[1] if $blk =~ $rec->[0];
    }
  }
  return undef;
}

=head2 S<$h-E<gt>sel_function($def)>

This method selects the function associated to the C<fct> definition key for
converting the current block.

=cut

sub sel_function
{ my ($slf, $def) = @_;

  exists($def->{'fct'}) ? $def->{'fct'} : undef;
}

=head1 COMMON CONVERSION METHODS

=head2 S<RDA::Convert::merge_block($ctl,$ofh)>

This method merges the block in the XML output.

=cut

sub merge_block
{ my ($ctl, $ofh) = @_;
  my ($lin);

  while (defined($lin = $ctl->get_line))
  { $lin =~ s/<\?xml.*?\?>//;
    print {$ofh} "$lin\n" if length($lin);
  }
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
