# Setting.pm: Class Used for Objects to Set up Settings

package RDA::Setting;

# $Id: Setting.pm,v 2.29 2012/06/07 05:30:24 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Setting.pm,v 2.29 2012/06/07 05:30:24 mschenke Exp $
#
# Change History
# 20120606  MSC  Improve search in root directory.

=head1 NAME

RDA::Setting - Class Used for Objects to Set up Settings

=head1 SYNOPSIS

require RDA::Setting;

=head1 DESCRIPTION

The objects of the C<RDA::Setting> class are used to manage the setup of a
setting.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use RDA::Object::Rda;
  use RDA::Object::Windows;
  use RDA::Object::Xml;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.29 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $re_cfg = qr/<<(CONFIG):((\w+\.)*\w+):(\d+):(.*)$/i;
my $re_cnd = qr/<<COND:(.*)$/i;
my $re_ext = qr/<<EXTERN:([\w\/]+):(\w+):(.*)$/i;
my $re_mod = qr/<<MODULES:([^:]+):(.*?)(#(.*))?$/i;
my $re_mrc = qr/<<MRC:(\w+):(\*?\w+)(:(.*))?$/i;
my $re_lst = qr/<<(LIST):((\w+\.)*\w+):(\-?\d+):(.*)$/i;
my $re_reg = qr/<<REG:([^:]+):(\w+)(:(.*))?$/i;
my $re_src = qr/<<(SEARCH):((\w+\.)*\w+):([bdnprtw1-9]*):(.*)$/i;
my $re_xml = qr/<<(XML):((\w+\.)*\w+):(\w*):(.*)$/i;

my %tb_dft = (
  'B' => \&_dft_boolean,
  'C' => \&_dft_comment,
  'D' => \&_dft_dir,
  'E' => \&_dft_event,
  'F' => \&_dft_file,
  'I' => \&_dft_none,
  'L' => \&_dft_none,
  'M' => \&_dft_menu,
  'N' => \&_dft_value,
  'P' => \&_dft_product,
  'S' => \&_dft_setup,
  'T' => \&_dft_value,
  );
my %tb_dsp = (
  'M' => \&_dsp_menu,
  );
my %tb_get = (
  'B' => \&_get_boolean,
  'D' => \&_get_dir,
  'F' => \&_get_file,
  'M' => \&_get_menu,
  'N' => \&_get_number,
  'T' => \&_get_value,
  );
my %tb_val = (
  'B' => \&_val_boolean,
  'D' => \&_val_dir,
  'F' => \&_val_file,
  'I' => \&_val_if,
  'L' => \&_val_loop,
  'M' => \&_val_menu,
  'N' => \&_val_number,
  'P' => \&_val_product,
  'T' => \&_val_value,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Setting-E<gt>new($nam)>

The object constructor. It takes the setting name as an argument.

C<RDA::Setting> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_add'> > Additional menu item definition

=item S<    B<'_ask'> > Interaction control indicator

=item S<    B<'_cas'> > Case sensitivity indicator

=item S<    B<'_clr'> > Clear string

=item S<    B<'_col'> > Optional multi-column indicator

=item S<    B<'_ctx'> > Validation context

=item S<    B<'_def'> > Definition name

=item S<    B<'_dft'> > Default value

=item S<    B<'_dsc'> > Description string

=item S<    B<'_dup'> > Duplication value error message

=item S<    B<'_end'> > String that indicates the end of a value list

=item S<    B<'_err'> > Setting error text

=item S<    B<'_fam'> > Optional list of operating system families

=item S<    B<'_hlp'> > Setting help text

=item S<    B<'_inp'> > Setting prompt string

=item S<    B<'_itm'> > Menu item definition

=item S<    B<'_man'> > Setting manual text

=item S<    B<'_mnu'> > Menu item definition

=item S<    B<'_nam'> > Setting effective name

=item S<    B<'_pck'> > Pick indicator

=item S<    B<'_one'> > Value to convert a value list in a single value

=item S<    B<'_opt'> > Optional setting flag

=item S<    B<'_ref'> > Setting validation reference

=item S<    B<'_rsp'> > Valid menu responses

=item S<    B<'_sep'> > Value separator

=item S<    B<'_typ'> > Setting type

=item S<    B<'_val'> > Setting validation type

=item S<    B<'_var'> > Array of additional settings

=item S<    B<'_vis'> > Flag to control character echo during input

=item S<    B<'-act'> > Additional settings associated to the extra item

=item S<    B<'-add'> > Information associated to the extra item

=item S<    B<'-ask'> > Interaction control

=item S<    B<'-cnt'> > Retry counter

=item S<    B<'-ctx'> > Effective validation context

=item S<    B<'-cur'> > Current value

=item S<    B<'-fmt'> > Menu selector format

=item S<    B<'-itm'> > Menu item description hash

=item S<    B<'-lgt'> > Maximum length of the menu item selectors

=item S<    B<'-mnu'> > Array of displayed menu items

=item S<    B<'-nxt'> > Array of next values

=item S<    B<'-pck'> > Array of pick values

=item S<    B<'-prv'> > Array of previous values

=item S<    B<'-rsp'> > Menu response hash

=item S<    B<'-sav'> > Saved elements

=back

Internal keys are prefixed by an underscore or a dash.

=cut

sub new
{ my ($cls, $nam) = @_;

  bless {
    _add => '',
    _ask => 1,
    _clr => '',
    _cas => 1,
    _col => 0,
    _def => $nam,
    _dsc => $nam,
    _dft => '',
    _dup => '',
    _err => '',
    _itm => '',
    _lvl => 0,
    _mnu => '',
    _nam => $nam,
    _opt => 0,
    _pck => 0,
    _sep => ($^O eq 'MSWin32' || $^O eq 'MSWin64') ? ';' : ':',
    _typ => 'T',
    _var => [],
    _vis => 1,
    -nxt => [],
    -prv => [],
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>get_detail>

This method returns the setting details. Only settings that have an C<inp>, 
C<hlp>, or C<man> property are considered. Otherwise, it returns an empty list.

=cut

sub get_detail
{ my $slf = shift;

  # Detect a relevant setting
  return () unless $slf->{'_typ'} ne 'C' &&
    (exists($slf->{'_inp'}) || exists($slf->{'_man'}) ||
     exists($slf->{'_hlp'}));

  # Provide the setting details
  ( $slf->{'_nam'},
    $slf->{'_lvl'},
    exists($slf->{'_inp'}) ? _get_detail($slf) : undef,
    exists($slf->{'_man'}) ? $slf->{'_man'} :
    exists($slf->{'_hlp'}) ? $slf->{'_hlp'} :
    undef
  );
}

sub _get_detail
{ my $slf = shift;
  my @tbl;

  if ($slf->{'_typ'} eq 'M')
  { my ($lgt, $max, $str, @key, %tbl);

    return undef unless exists($slf->{'_itm'});

    push(@tbl, $slf->{'_bef'}) if exists($slf->{'_bef'});
    if ($slf->{'_itm'} =~ m/(\$\{.*\}|^<<(COND|MRC):)/i)
    { push(@tbl, "[Dynamic menu]");
    }
    else
    { _spl_menu(\%tbl, \@key, $slf->{'_itm'});
      $max = 0;
      foreach my $itm (sort keys(%tbl))
      { $max = $lgt if ($lgt = length($itm)) > $max;
      }
      if ($slf->{'_mnu'} =~ m/^<<n(umber)?$/i)
      { @key = sort {$a <=> $b} keys(%tbl);
      }
      elsif ($slf->{'_mnu'} =~ m/^<<t(ext)?$/i)
      { @key = sort keys(%tbl);
      }
      foreach my $itm (@key)
      { $str = sprintf("  %-*s  ", $max, $itm);
        $str =~ s/\s/\\040/g;
        push(@tbl, $str.$tbl{$itm});
      }
    }
    push(@tbl, $slf->{'_aft'}) if exists($slf->{'_aft'});
  }
  join("\\n", @tbl, '"'.$slf->{'_inp'}.'"');
}

=head2 S<$h-E<gt>is_valid($family)>

This method indicates whether the setting is applicable for the specified
operating system family.

=cut

sub is_valid
{ my ($slf, $fam) = @_;

  # Accept it directly if there is no restriction
  return 1 unless exists($slf->{'_fam'});

  # Check if the family is included in the list
  for (@{$slf->{'_fam'}})
  { return 1 if $_ eq $fam;
  }

  # Otherwise, reject it
  0;
}

=head2 S<$h-E<gt>set_info($key[,$value])>

This method assigns a new value to the given object key when the value is
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

=head2 S<$h-E<gt>setup($module,$agent,$level,$list[,$trace])>

This method gets the setting value. When appropriate, it adds additional
settings to the input list.

=cut

sub setup
{ my ($slf, $mod, $lvl, $lst, $trc) = @_;
  my ($agt, $ask, $inp, $nam, $typ, $val);

  # Get the default value
  $agt = $mod->get_info('agt');
  $typ = $slf->{'_typ'};
  $slf->{'-ask'} = ($lvl < $slf->{'_lvl'} || $mod->get_info('yes'))
    ? 0
    : (exists($slf->{'_inp'}) && exists($tb_get{$typ}));
  if (&{$tb_dft{$typ}}($slf, $mod, $agt->get_setting($slf->{'_def'}), $lvl,
    $trc))
  { unshift(@$lst, @{$slf->{'_alt'}}) if exists($slf->{'_alt'});
    print "$trc No assignment\n" if $trc;
    return undef;
  }

  # Ask the setting value
  if ($ask = $slf->{'-ask'})
  { _dsp_text($slf, $mod, '_hlp', 2);
    &{$tb_dsp{$typ}}($slf, $mod) if exists($tb_dsp{$typ});
    $slf->_nxt_value([]);
    while ($ask)
    { $inp = $slf->{'_inp'};
      $inp =~ s/\$\{clr\}/$slf->{'_clr'}/g if $slf->{'_clr'};
      $inp =~ s/\$\{end\}/$slf->{'_end'}/g if exists($slf->{'_end'});
      $inp = _repl_var($mod, $inp, 1);
      $val = $slf->{'_vis'} ?
        $slf->_ask_setting($mod, $inp) :
        $slf->_ask_password($mod, $inp);
      if ($val eq '?')
      { _dsp_text($slf, $mod, '_hlp', 2);
        &{$tb_dsp{$typ}}($slf, $mod) if exists($tb_dsp{$typ});
      }
      else
      { $val = uc($val) unless $slf->{'_cas'};
        ($val, $ask) = &{$tb_get{$typ}}($slf, $mod, $val, $lst);
      }
    }
  }
  else
  { $val = &{$tb_val{$typ}}($slf, $mod, $lst);
  }

  # Create or update the setting and return its effective name
  $nam = _repl_var($mod, $slf->{'_nam'});
  $nam =~ s/[^\-\w]/_/g;
  print "$trc $nam=".(defined($val) ? "'$val'" : 'undef')."\n" if $trc;
  if ($nam =~ s/^-//)
  { if (length($nam))
    { if (defined($val))
      { $agt->set_temp_setting($nam, $val);
      }
      else
      { $agt->clr_temp_setting($nam);
      }
    }
    return undef;
  }
  $agt->set_setting($nam, $val, $typ, _repl_var($mod, $slf->{'_dsc'}))
    if length($nam);
  $nam;
}

# Ask the user value
sub _ask_setting
{ my ($slf, $mod, $inp) = @_;
  my ($cur, $str);

  $str = $inp;
  if (length($cur = $slf->{'-cur'}))
  { $cur =~ s/\\/\\134/g;
    $str .= "\nHit 'Return' to accept the default ($cur)"
  }
  _dsp_string($mod, "$str\n>\\040", 0);
  $str = <STDIN>;
  print "\n";
  $str =~ s/[\s\r\n]+$//;
  ($str eq '')             ? $slf->{'-cur'} :
  ($str eq $slf->{'_clr'}) ? '' :
                             $str;
}

sub _ask_password
{ my ($slf, $mod, $inp) = @_;
  my $str;

  return ''
    unless defined($str = $mod->get_access->ask_password($inp, $slf->{'-cur'}));
  $str =~ s/[\s\r\n]+$//;
  $str;
}

# Do a boolean setting
sub _dft_boolean
{ my ($slf, $mod, $dft) = @_;

  unless (defined($dft))
  { $dft = $slf->{'_dft'};
    $dft = _repl_cnd($mod, $1) if $dft =~ $re_cnd;
    $dft = _repl_var($mod, $dft);
    return 1 if $slf->{'_opt'} && $dft eq '';
  }
  $slf->{'-prv'} = [$dft ? 'Y' : 'N'];
  0;
}

sub _get_boolean
{ my ($slf, $mod, $val, $lst) = @_;

  (_tst_boolean($slf, $val, $lst), 0);
}

sub _val_boolean
{ my ($slf, $mod, $lst) = @_;
 
  _tst_boolean($slf, $slf->{'-prv'}->[0], $lst);
}

sub _tst_boolean
{ my ($slf, $val, $lst) = @_;

  if ($val =~ m/\s*y(es)?/i)
  { unshift(@$lst, @{$slf->{'_var'}});
    return 1;
  }
  else
  { unshift(@$lst, @{$slf->{'_alt'}}) if exists($slf->{'_alt'});
    return 0;
  }
}

# Do a comment setting
sub _dft_comment
{ my ($slf, $mod, $dft) = @_;
  my ($cnt, $col, $lgt, $max, $off, $row, $txt, @txt);

  unless ($mod->get_info('yes'))
  { # Resolve settings
    $dft = _repl_var($mod, $slf->{'_dft'}) unless defined($dft);

    # Display the comment
    _dsp_string($mod, _repl_var($mod, $slf->{'_bef'}, 1), 1)
      if exists($slf->{'_bef'});
    if (exists($slf->{'_inp'}))
    { $txt = $slf->{'_inp'};
      $txt =~ s/\$\{dft\}/$dft/g;
      if (exists($slf->{'_end'}))
      { @txt = split(/\Q$slf->{'_sep'}\E/, _repl_var($mod, $txt, 1));
        if ($slf->{'_col'})
        { foreach my $itm (@txt)
          { $max = $lgt if ($lgt = length($itm)) > $max;
            ++$cnt;
          }
          if ($max && ($col = int($mod->get_info('wdt') / ($max + 2))))
          { for (; $cnt % $col ; ++$cnt)
            { push(@txt, '');
            }
            $lgt = $cnt / $col;
          }
        }
        if ($col)
        { for ($row = 0 ; $row < $lgt ; ++$row)
          { $txt = '';
            for ($off = $row ;  $off < $cnt ; $off += $lgt)
            { $txt .= sprintf('  %-*s', $max, $txt[$off]);
            }
            $txt =~ s/\s/\\040/g;
            _dsp_string($mod, $txt)
          }
        }
        else
        { foreach my $itm (@txt)
          { _dsp_string($mod, $itm, 1);
          }
        }
      }
      else
      { _dsp_string($mod, _repl_var($mod, $txt, 1), 1);
      }
    }
    _dsp_string($mod, _repl_var($mod, $slf->{'_aft'}, 1), 1)
      if exists($slf->{'_aft'});

    # When applicable, wait for the confirmation
    $dft = <STDIN> if $slf->{'_vis'};
  }

  # Detect if the setup must be aborted
  if (exists($slf->{'_val'}))
  { die "RDA-00121: Setup aborted\n" if $slf->{'_val'} eq 'F';
    die "Aborted\n"                  if $slf->{'_val'} eq 'E';
  }

  # Refuse the default value
  1;
}

# Do a directory setting
sub _dft_dir
{ my ($slf, $mod, $dft) = @_;
  my ($ctx);

  # When possible, use the current setting as default
  unless (defined($dft))
  { $dft = $slf->{'_dft'};
    if ($dft =~ $re_cfg)
    { $dft = RDA::Object::Rda->cat_dir($dft)
        if length($dft = _repl_cfg($mod, $1, $2, $4, $5));
    }
    elsif ($dft =~ $re_cnd)
    { $dft = RDA::Object::Rda->cat_dir($dft)
        if length($dft = _repl_cnd($mod, $1));
    }
    elsif ($dft =~ $re_ext)
    { $dft = _repl_ext($mod, $1, $2, $3);
    }
    elsif ($dft =~ $re_lst)
    { $dft = _repl_lst($mod, $1, $2, $4, $5);
    }
    elsif ($dft =~ $re_reg)
    { $dft = RDA::Object::Rda->cat_dir($dft)
        if length($dft = _repl_reg($mod, $1, $2, $4));
    }
    elsif ($dft =~ $re_src)
    { $dft = _repl_src($mod, $1, $2, $4, $5, '-d');
    }
    elsif ($dft =~ $re_xml)
    { $dft = RDA::Object::Rda->cat_dir($dft)
        if length($dft = _repl_xml($mod, $1, $2, $4, $5));
    }
    else
    { $dft =~ s/\//\001/g;
      $dft = length($dft = _repl_var($mod, $dft))
         ? RDA::Object::Rda->clean_path([map
             {($_ eq '..') ? RDA::Object::Rda->up_dir : $_}
             split(/\001/, $dft)], 1)
         : '';
    }
    return 1 if $slf->{'_opt'} && $dft eq '';
  }

  # Determine the validation context
  delete($slf->{'-ctx'});
  if (exists($slf->{'_ctx'}))
  { $ctx = $slf->{'_ctx'};
    $ctx =~ s/\//\001/g;
    $slf->{'-ctx'} = RDA::Object::Rda->clean_path([map
      {($_ eq '..') ? RDA::Object::Rda->up_dir : $_}
      split(/\001/, $ctx)], 1)
      if length($ctx = _repl_var($mod, $ctx));
  }

  # When requested, validate the directory
  return 1 if exists($slf->{'_alt'}) && defined($dft)
    && ! -d (_chk_case($slf, exists($slf->{'-ctx'})
               ? RDA::Object::Rda->cat_dir($slf->{'-ctx'}, $dft)
               : $dft));

  # Get the default list
  $slf->{'-prv'} = exists($slf->{'_end'})
    ? [split(/\Q$slf->{'_sep'}\E/, _chk_case($slf, $dft))]
    : [_chk_case($slf, $dft)];
  0;
}

sub _get_dir
{ my ($slf, $mod, $val, $lst) = @_;
  my ($nxt);

  # Detect the end of a value list
  $nxt = exists($slf->{'_end'});
  return (join($slf->{'_sep'}, @{$slf->{'-nxt'}}), 0)
    if $nxt && $val eq $slf->{'_end'};

  # Reject an error
  if ($slf->_tst_file($mod, \$val, 'D'))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_err');
  }
  elsif ($slf->_chk_value($val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_dup');
  }

  # Accept other value
  if ($nxt)
  { $slf->_nxt_value($val);
  }
  elsif (-d $val)
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  ($val, $nxt);
}

sub _val_dir
{ my ($slf, $mod, $lst) = @_;

  if (exists($slf->{'_end'}))
  { foreach my $itm (@{$slf->{'-prv'}})
    { $slf->_dsp_validation($mod, 0, '_err')
        if $slf->_tst_file($mod, $itm, 'D');
      $slf->_dsp_validation($mod, 0, '_dup') if $slf->_chk_value($itm, 1);
    }
  }
  elsif ($slf->_tst_file($mod, $slf->{'-prv'}->[0], 'D'))
  { $slf->_dsp_validation($mod, 0, '_err');
  }
  else
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  join($slf->{'_sep'}, @{$slf->{'-prv'}});
}

# Do an event setting
sub _dft_event
{ my ($slf, $mod, $dft) = @_;

  # Resolve settings and add the event to the module event stack
  $dft = _repl_var($mod, $slf->{'_dft'}) unless defined($dft);
  $mod->log($dft);

  # Refuse the default value
  1;
}

# Do a file setting
sub _dft_file
{ my ($slf, $mod, $dft) = @_;
  my ($ctx, @tbl);

  # When possible, use the current setting as default
  unless (defined($dft))
  { $dft = $slf->{'_dft'};
    if ($dft =~ $re_cfg)
    { $dft = RDA::Object::Rda->cat_file($dft)
        if length($dft = _repl_cfg($mod, $1, $2, $4, $5));
    }
    elsif ($dft =~ $re_cnd)
    { $dft = RDA::Object::Rda->cat_file($dft)
        if length($dft = _repl_cnd($mod, $1));
    }
    elsif ($dft =~ $re_ext)
    { $dft = _repl_ext($mod, $1, $2, $3);
    }
    elsif ($dft =~ $re_lst)
    { $dft = _repl_lst($mod, $1, $2, $4, $5);
    }
    elsif ($dft =~ $re_reg)
    { $dft = RDA::Object::Rda->cat_file($dft)
        if length($dft = _repl_reg($mod, $1, $2, $4));
    }
    elsif ($dft =~ $re_src)
    { $dft = _repl_src($mod, $1, $2, $4, $5, '-f');
    }
    elsif ($dft =~ $re_xml)
    { $dft = RDA::Object::Rda->cat_file($dft)
        if length($dft = _repl_xml($mod, $1, $2, $4, $5));
    }
    elsif ($dft)
    { $dft =~ s/\//\001/g;
      $dft = length($dft = _repl_var($mod, $dft))
         ? RDA::Object::Rda->clean_path([map
             {($_ eq '..') ? RDA::Object::Rda->up_dir : $_}
             split(/\001/, $dft)], 1)
         : '';
    }
    return 1 if $slf->{'_opt'} && $dft eq '';
  }

  # Determine the validation context
  delete($slf->{'-ctx'});
  if (exists($slf->{'_ctx'}))
  { $ctx = $slf->{'_ctx'};
    $ctx =~ s/\//\001/g;
    $slf->{'-ctx'} = RDA::Object::Rda->clean_path([map
      {($_ eq '..') ? RDA::Object::Rda->up_dir : $_}
      split(/\001/, $ctx)], 1)
      if length($ctx = _repl_var($mod, $ctx));
  }

  # When requested, validate the file
  return 1 if exists($slf->{'_alt'}) && defined($dft)
    && ! -f (_chk_case($slf, exists($slf->{'_ctx'})
               ? RDA::Object::Rda->cat_file($slf->{'-ctx'}, $dft)
               : $dft));

  # Get the default list
  $slf->{'-prv'} = exists($slf->{'_end'})
    ? [split(/\Q$slf->{'_sep'}\E/, _chk_case($slf, $dft))]
    : [_chk_case($slf, $dft)];
  0;
}

sub _get_file
{ my ($slf, $mod, $val, $lst) = @_;
  my ($nxt);

  # Detect the end of a value list
  $nxt = exists($slf->{'_end'});
  return (join($slf->{'_sep'}, @{$slf->{'-nxt'}}), 0)
    if $nxt && $val eq $slf->{'_end'};

  # Reject an error
  if ($slf->_tst_file($mod, \$val, 'F'))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_err');
  }
  elsif ($slf->_chk_value($val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_dup');
  }

  # Accept other value
  if ($nxt)
  { $slf->_nxt_value($val);
  }
  elsif (-f $val)
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  ($val, $nxt);
}

sub _val_file
{ my ($slf, $mod, $lst) = @_;

  if (exists($slf->{'_end'}))
  { foreach my $itm (@{$slf->{'-prv'}})
    { $slf->_dsp_validation($mod, 0, '_err')
        if $slf->_tst_file($mod, $itm, 'F');
      $slf->_dsp_validation($mod, 0, '_dup') if $slf->_chk_value($itm, 1);
    }
  }
  elsif ($slf->_tst_file($mod, $slf->{'-prv'}->[0], 'F'))
  { $slf->_dsp_validation($mod, 0, '_err');
  }
  else
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  join($slf->{'_sep'}, @{$slf->{'-prv'}});
}

sub _tst_file
{ my ($slf, $mod, $val, $dft) = @_;
  my ($fil, $ref);

  # Resolve variables
  if (ref($val))
  { unless (RDA::Object::Rda->is_vms)
    { $$val =~ s/\$\{(\w+)\}/_resolve($mod, $1)/eg;
      $$val =~ s/\$(\w+)/_resolve($mod, $1)/eg;
    }
    $$val =~ s/\%(\w+)\%/_resolve($mod, $1)/eg;
    $fil = $$val;
  }
  else
  { $fil = $val;
  }
  return 0 unless length($fil) || $slf->{'_clr'} eq '';

  # Apply the context
  $fil = ($dft eq 'D') ? RDA::Object::Rda->cat_dir($slf->{'-ctx'}, $fil) :
         ($dft eq 'F') ? RDA::Object::Rda->cat_file($slf->{'-ctx'}, $fil) :
                         $fil
    if exists($slf->{'-ctx'});

  # Test the directory/file
  $ref = exists($slf->{'_ref'}) ? uc(_repl_var($mod, $slf->{'_ref'})) : $dft;
  return 1
    unless index($ref, 'A') < 0 || RDA::Object::Rda->is_absolute($fil);
  return 1 unless index($ref, 'B') < 0 || -b $fil;
  return 1 unless index($ref, 'C') < 0 || -c $fil;
  return 1 unless index($ref, 'D') < 0 || -d $fil;
  return 1 unless index($ref, 'E') < 0 || -e $fil;
  return 1 unless index($ref, 'F') < 0 || -f $fil;
  return 1 unless index($ref, 'L') < 0 || -l $fil;
  return 1 unless index($ref, 'N') < 0 || -s $fil;
  return 1 unless index($ref, 'P') < 0 || -p $fil;
  return 1 unless index($ref, 'R') < 0 || -r $fil;
  return 1 unless index($ref, 'S') < 0 || -S $fil;
  return 1 unless index($ref, 'T') < 0 || -t $fil;
  return 1 unless index($ref, 'W') < 0 || -w $fil;
  return 1 unless index($ref, 'X') < 0 || -x $fil;
  return 1 unless index($ref, 'Z') < 0 || -z $fil;
  0;
}

sub _resolve
{ my ($mod, $key) = @_;
  my ($val);

  defined($val = $mod->get_var($key)) ? $val :
  exists($ENV{$key}) ? $ENV{$key} :
  '';
}

# Treat a conditional setting
sub _val_if
{ my ($slf, $mod, $lst) = @_;
  my ($arg, $cmd, $ref, $val);

  # Eval the condition
  $val = 0;
  ($cmd, $ref, $arg) = split(/:/, _repl_var($mod, $slf->{'_dft'}), 3);
  if ($cmd && $ref)
  { $cmd = lc($cmd);
    $ref = $mod->get_var($ref);
    if ($cmd eq 'decode')
    { if (defined($ref) && defined($arg))
      { my %tbl = split(/:/, $arg);
        if (exists($tbl{$ref}))
        { unshift(@$lst, split(/\s*,\s*/, $tbl{$ref}));
          $val = $ref;
        }
      }
    }
    elsif ($cmd eq 'eq')
    { $val = 1 if defined($ref) && defined($arg) && $ref eq $arg;
    }
    elsif ($cmd eq 'exists')
    { $val = 1 if defined($ref);
    }
    elsif ($cmd eq 'gt')
    { $val = 1 if defined($ref) && defined($arg) && $ref gt $arg;
    }
    elsif ($cmd eq 'hash')
    { if (defined($ref))
      { my ($cnt);
        $cnt = defined($arg) ? $arg : 0;
        $val = join('|', map {$cnt++ => $_} split(/\|/, $ref));
      }
    }
    elsif ($cmd eq 'join')
    { $val = (!defined($ref)) ? $arg :
             (!defined($arg)) ? $ref :
                                "$ref|$arg";
    }
    elsif ($cmd eq 'lt')
    { $val = 1 if defined($ref) && defined($arg) && $ref lt $arg;
    }
    elsif ($cmd eq 'match')
    { $val = 1 if defined($ref) && defined($arg) && $ref =~ m#$arg#;
    }
    elsif ($cmd eq 'member')
    { if (defined($ref) && defined($arg))
      { my %tbl = map {$_ => 1} split(/,/, $arg);
        $val = 1 if exists($tbl{$ref});
      }
    }
    elsif ($cmd eq 'owner')
    { $val = 1
        if defined($ref) && defined($arg = (stat($ref))[4]) && $arg == $<;
    }
    elsif ($cmd eq 're')
    { if (defined($ref) && defined($arg))
      { my ($off, @tbl);
        $off = ($arg =~ s/^(\d+):// && $1) ? $1 - 1 : 0;
        @tbl = ($ref =~ m#$arg#);
        $val = $tbl[$off];
      }
    }
    elsif ($cmd eq 'start')
    { $val = 1 if defined($ref) && defined($arg) && index($ref, $arg) == 0;
    }
    elsif ($cmd eq 'unmatch')
    { $val = 1 if defined($ref) && defined($arg) && $ref !~ m#$arg#;
    }
    elsif ($cmd eq 'values')
    { if (defined($ref))
      { my (%tbl);
        %tbl = split(/\|/, $ref);
        $val = $arg
          ? join('|', map {$tbl{$_}} sort {$a <=> $b} keys(%tbl))
          : join('|', map {$tbl{$_}} sort keys(%tbl));
      }
    }
  }

  # Adapt the setting list accordingly
  if ($val)
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  elsif (exists($slf->{'_alt'}))
  { unshift(@$lst, @{$slf->{'_alt'}});
  }

  # Return the condition value
  $val;
}

# Treat a loop setting
sub _val_loop
{ my ($slf, $mod, $lst) = @_;
  my ($dft, $val);

  # Initiate the loop operation
  if (exists($slf->{'-sav'}))
  { # Purge last loop iteration
    splice(@$lst);
  }
  else
  { # Enter in the loop
    $dft = $slf->{'_dft'};
    $dft =
      ($dft =~ $re_cfg) ? _repl_cfg($mod, $1, $2, $4, $5) :
      ($dft =~ $re_cnd) ? _repl_cnd($mod, $1) :
      ($dft =~ $re_ext) ? _repl_ext($mod, $1, $2, $3) :
      ($dft =~ $re_mod) ? _repl_mod($mod, $1, $2, $4) :
      ($dft =~ $re_mrc) ? _repl_mrc($mod, $1, $2, $4) :
      ($dft =~ $re_lst) ? _repl_lst($mod, $1, $2, $4, $5) :
      ($dft =~ $re_reg) ? _repl_reg($mod, $1, $2, $4) :
      ($dft =~ $re_src) ? _repl_src($mod, $1, $2, $4, $5, '-e') :
      ($dft =~ $re_xml) ? _repl_xml($mod, $1, $2, $4, $5) :
                          _repl_var($mod, $dft);
    $slf->{'-prv'} = [split(/\Q$slf->{'_sep'}\E/, _chk_case($slf, $dft))];
    $slf->{'-sav'} = [splice(@$lst)];
    $slf->{'_nam'} = '-'.$slf->{'_nam'} unless $slf->{'_nam'} =~ m/^-/;
  }

  # Get the next loop value
  while (defined($val = shift(@{$slf->{'-prv'}})))
  { last unless $val eq '' && $slf->{'_vis'};
  }

  # Determine what is the next action
  if (defined($val))
  { # Start an iteration
    push(@$lst, @{$slf->{'_var'}}, $slf->{'_def'});
  }
  else
  { # Restore the context and exit the loop
    push(@$lst, @{$slf->{'_alt'}}) if exists($slf->{'_alt'});
    push(@$lst, @{$slf->{'-sav'}});
    delete($slf->{'-sav'});
  }

  # Return the loop value
  $val;
}

# Treat a menu setting
sub _dft_menu
{ my ($slf, $mod, $dft) = @_;
  my ($itm, $lgt, $tbl, $val, @key);

  # Parse the menu description
  $itm = $slf->{'_itm'};
  return 1
    unless ($itm = ($itm =~ $re_cnd) ? _repl_cnd($mod, $1) :
                   ($itm =~ $re_lst) ? _repl_lst($mod, $1, $2, $4, $5) :
                   ($itm =~ $re_mrc) ? _repl_mrc($mod, $1, $2, $4) :
                                       _repl_var($mod, $itm));
  _spl_menu($slf->{'-itm'} = $tbl = {}, \@key, $itm);
  $val = $slf->{'_mnu'};
  $val = '<<T' unless ($val = ($val =~ $re_cnd) ? _repl_cnd($mod, $1) :
                                                  _repl_var($mod, $val));
  if ($val =~ m/^<<i(tem)?$/i)
  { $slf->{'-fmt'} = '  %-*s  ';
    $slf->{'-mnu'} = [@key];
  }
  elsif ($val =~ m/^<<n(umber)?$/i)
  { $slf->{'-fmt'} = '  %*d  ';
    $slf->{'-mnu'} = [sort {$a <=> $b} keys(%$tbl)];
  }
  elsif ($val =~ m/^<<t(ext)?$/i)
  { $slf->{'-fmt'} = '  %-*s  ';
    $slf->{'-mnu'} = [sort keys(%$tbl)];
  }
  else
  { $slf->{'-fmt'} = '  %-*s  ';
    $slf->{'-mnu'} = [grep {exists($tbl->{$_})} split(/\|/, $val)];
  }
  if (exists($slf->{'_rsp'}))
  { $val = $slf->{'_rsp'};
    _spl_menu($slf->{'-rsp'} = $tbl = {}, [], _repl_var($mod, ($val eq '^')
      ? $itm
      : $slf->{'_rsp'}));
    $slf->{'-mnu'} = [grep {exists($tbl->{$_})} @{$slf->{'-mnu'}}];
  }
  else
  { $slf->{'-rsp'} = {map {$_ => $_} @{$slf->{'-mnu'}}};
  }

  # Treat trivial menus
  return 1 unless ($val = scalar @{$slf->{'-mnu'}});
  unless ($slf->{'_ask'} || $val > 1)
  { $slf->{'-ask'} = 0;
    $slf->{'-prv'} = [$slf->{'-mnu'}->[0]];
    return 0;
  }

  # Determine the selector size
  $val = 0;
  delete($slf->{'-act'});
  delete($slf->{'-add'});
  if ($slf->{'_add'})
  { my ($cod, $itm, $lgt, $rsp, $var, @tbl);

    @tbl = split(/\|/, $slf->{'_add'});
    while (($cod, $itm, $rsp, $var) = splice(@tbl, 0, 4))
    { if (defined($rsp) && length($cod) && length($itm) && length($rsp))
      { $val = $lgt if ($lgt = length($cod)) > $val;
        $slf->{'-rsp'}->{$cod} = $rsp;
        push(@{$slf->{'-add'}}, [$cod, $itm]);
        $slf->{'-act'}->{$rsp} = [split(/,/, $var)] if $var;
      }
    }
  }
  foreach my $itm (@{$slf->{'-mnu'}})
  { $val = $lgt if ($lgt = length($itm)) > $val;
  }
  return 1 unless ($slf->{'-lgt'} = $val);

  # When possible, use the current setting as default
  unless (defined($dft))
  { $dft = $slf->{'_dft'};
    $dft = ($dft =~ $re_cnd) ? _repl_cnd($mod, $1) :
                               _repl_var($mod, $dft);
  }
  if ($slf->{'_pck'})
  { my (@all, @dft, @rec, %dft);

    $slf->{'-pck'} =
      [@all = sort {$a <=> $b} grep {m/^\d+$/} keys(%{$slf->{'-rsp'}})];
    foreach my $itm (split(/\Q$slf->{'_sep'}\E/, $dft))
    { $dft{$val} = 1 if defined($val = _sel_pick($slf, $itm));
    }
    foreach my $itm (@all)
    { if (!exists($dft{$itm}))
      { push(@dft, _fmt_pick(splice(@rec))) if @rec;
      }
      elsif (@rec)
      { $rec[1] = $itm;
      }
      else
      { @rec = ($itm);
      }
    }
    push(@dft, _fmt_pick(@rec)) if @rec;
    $slf->{'-prv'} = [join(',', @dft)];
  }
  elsif (exists($slf->{'_end'}))
  { $slf->{'-prv'} = [];
    foreach my $itm (split(/\Q$slf->{'_sep'}\E/, $dft))
    { push(@{$slf->{'-prv'}}, $val) if defined($val = _sel_menu($slf, $itm));
    }
  }
  elsif ($dft eq '^')
  { $slf->{'-prv'} = [$val] if defined($val = $slf->{'-mnu'}->[0]);
  }
  elsif (defined($val = _sel_menu($slf, $dft)))
  { $slf->{'-prv'} = [$val];
  }
  0;
}

sub _dsp_menu
{ my ($slf, $mod) = @_;
  my ($cnt, $dsp, $col, $lgt, $max, $off, $row, $txt, @tbl);
 
  $dsp = $mod->get_info('dsp');
  $cnt = $col = $max = 0;
  _dsp_text($slf, $mod, '_bef', 1);
  if ($slf->{'_col'})
  { foreach my $itm (@{$slf->{'-mnu'}})
    { push(@tbl, $txt = sprintf($slf->{'-fmt'}, $slf->{'-lgt'}, $itm)
        .$slf->{'-itm'}->{$itm});
      $max = $lgt if ($lgt = length($txt)) > $max;
      ++$cnt;
    }
    if (exists($slf->{'-add'}))
    { foreach my $rec (@{$slf->{'-add'}})
      { push(@tbl, $txt = sprintf($slf->{'-fmt'}, $slf->{'-lgt'}, $rec->[0])
          .$rec->[1]);
        $max = $lgt if ($lgt = length($txt)) > $max;
        ++$cnt;
      }
    }
    if ($max && ($col = int($mod->get_info('wdt') / $max)))
    { for (; $cnt % $col ; ++$cnt)
      { push(@tbl, '');
      }
      $lgt = $cnt / $col;
    }
  }
  if ($col)
  { for ($row = 0 ; $row < $lgt ; ++$row)
    { $txt = '';
      for ($off = $row ;  $off < $cnt ; $off += $lgt)
      { $txt .= sprintf('%-*s', $max, $tbl[$off]);
      }
      $txt =~ s/\s/\\040/g;
      _dsp_string($mod, $txt)
    }
  }
  else
  { foreach my $itm (@{$slf->{'-mnu'}})
    { $dsp->dsp_string(sprintf($slf->{'-fmt'}, $slf->{'-lgt'}, $itm),
        $slf->{'-itm'}->{$itm}, 1);
    }
    if (exists($slf->{'-add'}))
    { foreach my $rec (@{$slf->{'-add'}})
      { $dsp->dsp_string(sprintf($slf->{'-fmt'}, $slf->{'-lgt'}, $rec->[0]),
          $rec->[1], 1);
      }
    }
  }
  _dsp_text($slf, $mod, '_aft', 1);
}

sub _fmt_pick
{ my ($min, $max) = @_;

  defined($max) ? $min.'-'.$max : $min;
}

sub _get_menu
{ my ($slf, $mod, $val, $lst) = @_;
  my ($nxt);

  # Treat a pick list
  if ($slf->{'_pck'})
  { $nxt = $slf->_tst_pick(\$val, $lst);
    return ($val, ($nxt &&  $slf->_dsp_validation($mod, 1, '_err'))
      ? $slf->{'-cnt'}
      : 0);
  }

  # Detect the end of a value list
  $nxt = exists($slf->{'_end'});
  return (join($slf->{'_sep'}, @{$slf->{'-nxt'}}), 0)
    if $nxt && $val eq $slf->{'_end'};

  # Reject an error
  if ($slf->_tst_menu($mod, \$val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_err');
  }
  elsif ($slf->_chk_value($val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_dup');
  }

  # Accept other value
  if ($nxt)
  { if (exists($slf->{'_one'}) && $val eq $slf->{'_one'})
    { unshift(@$lst, @{$slf->{'-act'}->{$val}})
        if exists($slf->{'-act'}) && exists($slf->{'-act'}->{$val});
      return ($val, 0);
    }
    $slf->_nxt_value($val);
  }
  elsif (exists($slf->{'-act'}) && exists($slf->{'-act'}->{$val}))
  { unshift(@$lst, @{$slf->{'-act'}->{$val}});
    $val = $slf->{'-rsp'}->{$slf->{'-cur'}};
  }
  else
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  ($val, $nxt);
}

sub _sel_menu
{ my ($slf, $itm) = @_;
  my $ret;

  foreach my $rsp (keys(%{$slf->{'-rsp'}}))
  { if ($itm eq $slf->{'-rsp'}->{$rsp})
    { return $rsp if $itm eq $rsp;
      $ret = $rsp;
    }
  }
  $ret;
}

sub _sel_pick
{ my ($slf, $itm) = @_;

  foreach my $rsp (@{$slf->{'-pck'}})
  { return $rsp if $itm eq $slf->{'-rsp'}->{$rsp};
  }
  undef;
}

sub _spl_menu
{ my ($tbl, $seq, $str) = @_;
  my ($key, $val, @tbl);

  @tbl = split(/\|/, $str);
  while (($key, $val) = splice(@tbl, 0, 2))
  { next unless defined($key) && length($key);
    push(@$seq, $key);
    $tbl->{$key} = (defined($val) && length($val)) ? $val : $key;
  }
}

sub _tst_menu
{ my ($slf, $mod, $val) = @_;

  $$val =~ s/^\s+//;
  return 1 unless exists($slf->{'-rsp'}->{$$val});
  $$val = $slf->{'-rsp'}->{$$val};
  0;
}

sub _tst_pick
{ my ($slf, $val, $lst) = @_;
  my ($act, $err, $ret, $rsp, %val);

  $act = exists($slf->{'-act'}) ? $slf->{'-act'} : {};
  $err = 0;
  $rsp = $slf->{'-rsp'};
  foreach my $rng (split(/,/, $$val))
  { if ($rng !~ m/^(\d+)(\-(\d+))?$/ || !exists($rsp->{$1}))
    { ++$err;
    }
    elsif (!defined($3))
    { $val{$1} = 1;
      $ret = $rsp->{$1};
      unshift(@$lst, @{$act->{$ret}}) if exists($act->{$ret});
    }
    elsif (!exists($rsp->{$3}))
    { ++$err;
    }
    else
    { foreach my $itm (@{$slf->{'-pck'}})
      { next if $itm < $1 || $itm > $3;
        $val{$itm} = 2;
        $ret = $rsp->{$itm};
        unshift(@$lst, @{$act->{$ret}}) if exists($act->{$ret});
      }
    }
  }
  $$val = join($slf->{'_sep'}, map {$rsp->{$_}} sort {$a <=> $b} keys(%val));
  $err;
}

sub _val_menu
{ my ($slf, $mod, $lst) = @_;
  my ($rsp);

  if ($slf->{'_pck'})
  { $rsp = $slf->{'-prv'}->[0];
    $slf->_dsp_validation($mod, 0, '_err') if $slf->_tst_pick(\$rsp, $lst);
    return $rsp;
  }
  elsif (exists($slf->{'_end'}))
  { foreach my $itm (@{$slf->{'-prv'}})
    { $slf->_dsp_validation($mod, 0, '_err')
        unless exists($slf->{'-rsp'}->{$itm});
      if (exists($slf->{'_one'})
        && ($rsp = $slf->{'-rsp'}->{$itm}) eq $slf->{'_one'})
      { unshift(@$lst, @{$slf->{'-act'}->{$rsp}})
          if exists($slf->{'-act'}) && exists($slf->{'-act'}->{$rsp});
        $slf->{'-prv'} = [$itm];
        last;
      }
      $slf->_dsp_validation($mod, 0, '_dup') if $slf->_chk_value($itm, 1);
    }
  }
  elsif (@{$slf->{'-prv'}} && exists($slf->{'-rsp'}->{$slf->{'-prv'}->[0]}))
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  else
  { $slf->_dsp_validation($mod, 0, '_err');
  }
  join($slf->{'_sep'}, map {$slf->{'-rsp'}->{$_}} @{$slf->{'-prv'}});
}

# No default value
sub _dft_none
{ 0;
}

# Do a number setting
sub _get_number
{ my ($slf, $mod, $val) = @_;
  my ($nxt);

  # Detect the end of a value list
  $nxt = exists($slf->{'_end'});
  return (join($slf->{'_sep'}, @{$slf->{'-nxt'}}), 0)
    if $nxt && $val eq $slf->{'_end'};

  # Reject an error
  if ($slf->_tst_number($mod, \$val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_err');
  }
  elsif ($slf->_chk_value($val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_dup');
  }

  # Accept other value
  $slf->_nxt_value($val) if $nxt;
  ($val, $nxt);
}

sub _val_number
{ my ($slf, $mod) = @_;

  foreach my $itm (@{$slf->{'-prv'}})
  { $slf->_dsp_validation($mod, 0, '_err') if $slf->_tst_number($mod, \$itm);
    $slf->_dsp_validation($mod, 0, '_dup') if $slf->_chk_value($itm, 1);
  }
  join($slf->{'_sep'}, @{$slf->{'-prv'}});
}

sub _tst_number
{ my ($slf, $mod, $val) = @_;

  $$val =~ s/^\s+//;
  return 1 unless $$val =~ m/^([-+])?\d+(\.\d*)?([eE][\+\-]?\d+)?$/;
  $$val += 0;
  my $ref = exists($slf->{'_ref'}) ? _repl_var($mod, $slf->{'_ref'}) : '';
  return 0 unless $ref =~
    m/([IR])?([\[\]])([-+]?\d+(\.\d*)?)?\,([-+]?\d+(\.\d*)?)?([\[\]])/;
  my $typ = $1 || 'I';
  ((($typ eq 'I') ? $$val == int($$val) : 1) &&
    (defined($3) ? (($2 eq '[') ? ($$val >= $3) : ($$val > $3)) : 1) &&
    (defined($5) ? (($7 eq ']') ? ($$val <= $5) : ($$val < $5)) : 1)) ? 0 : 1;
}

# Treat a product setting
sub _dft_product
{ my ($slf, $mod, $dft) = @_;

  # Detect if the setting is already defined
  if (defined($dft))
  { $slf->{'-sav'} = $dft;
    return 0;
  }

  # Otherwise, check if auto discovery information are present
  ($slf->{'-sav'} = $mod->get_info('agt')->get_discover) ? 0 : 1;
}

sub _val_product
{ my ($slf, $mod, $lst) = @_;
  my ($cmd, $prd, $ref, $val);

  if (ref($slf->{'-sav'}))
  { ($cmd, $ref, $prd) = split(/:/, _repl_var($mod, $slf->{'_dft'}), 3);
    if ($cmd)
    { $cmd = lc($cmd);
      if ($cmd eq 'product')
      { $val = $slf->{'-sav'}->get_product($ref);
      }
      elsif ($ref && $prd)
      { if ($cmd eq 'check')
        { $val = $slf->{'-sav'}->check($ref, $prd);
        }
        elsif ($cmd eq 'find')
        { $val = $slf->{'-sav'}->find($ref, $prd);
        }
      }
      if (defined($val))
      { unshift(@$lst, @{$slf->{'_var'}});
        return $val;
      }
    }
  }
  else
  { unshift(@$lst, @{$slf->{'_var'}});
    return $slf->{'-sav'};
  }

  # Identify what to do when not found
  if (! $slf->{'_vis'})
  { unshift(@$lst, @{$slf->{'_var'}});
  }
  elsif (exists($slf->{'_alt'}))
  { unshift(@$lst, @{$slf->{'_alt'}});
  }
  ''
}

# Treat a setup setting
sub _dft_setup
{ my ($slf, $mod, $def, $lvl, $trc) = @_;
  my ($agt, $cfg, $dft, $obj);

  $agt = $mod->get_info('agt');
  $cfg = $mod->get_info('cfg');

  # Get the module list
  $dft = $slf->{'_dft'};
  $dft =
    ($dft =~ $re_cfg) ? _repl_cfg($mod, $1, $2, $4, $5) :
    ($dft =~ $re_cnd) ? _repl_cnd($mod, $1) :
    ($dft =~ $re_ext) ? _repl_ext($mod, $1, $2, $3) :
    ($dft =~ $re_mod) ? _repl_mod($mod, $1, $2, $4) :
    ($dft =~ $re_mrc) ? _repl_mrc($mod, $1, $2, $4) :
    ($dft =~ $re_reg) ? _repl_reg($mod, $1, $2, $4) :
    ($dft =~ $re_src) ? _repl_src($mod, $1, $2, $4, $5, '-e') :
    ($dft =~ $re_xml) ? _repl_xml($mod, $1, $2, $4, $5) :
                        _repl_var($mod, $dft);

  # Perform the setup
  foreach my $nam (split(/\Q$slf->{'_sep'}\E/, $dft))
  { $nam =~ s/\.cfg$//i;
    $obj = RDA::Module->new($nam, $cfg->get_group('D_RDA_CODE'));
    if ($obj->load($agt))
    { $obj->set_info('dpt', $mod->get_info('dpt') + 1);
      $obj->set_info('prv', $mod->get_info('prv'));
      $obj->set_info('rpt', $mod->get_info('rpt'));
      $obj->set_info('yes', 1) unless $slf->{'_vis'};
      $obj->request($lvl, $mod->get_info('trc'));
    }
  }
  1;
}

# Do a value setting
sub _dft_value
{ my ($slf, $mod, $dft) = @_;

  # When possible, use the current setting as default
  unless (defined($dft))
  { $dft = $slf->{'_dft'};
    $dft =
      ($dft =~ $re_cfg) ? _repl_cfg($mod, $1, $2, $4, $5) :
      ($dft =~ $re_cnd) ? _repl_cnd($mod, $1) :
      ($dft =~ $re_ext) ? _repl_ext($mod, $1, $2, $3) :
      ($dft =~ $re_mod) ? _repl_mod($mod, $1, $2, $4) :
      ($dft =~ $re_mrc) ? _repl_mrc($mod, $1, $2, $4) :
      ($dft =~ $re_lst) ? _repl_lst($mod, $1, $2, $4, $5) :
      ($dft =~ $re_reg) ? _repl_reg($mod, $1, $2, $4) :
      ($dft =~ $re_src) ? _repl_src($mod, $1, $2, $4, $5, '-e') :
      ($dft =~ $re_xml) ? _repl_xml($mod, $1, $2, $4, $5) :
                          _repl_var($mod, $dft);
    return 1 if $slf->{'_opt'} && $dft eq '';
  }

  # Get the default list
  $slf->{'-prv'} = exists($slf->{'_end'})
    ? [split(/\Q$slf->{'_sep'}\E/, _chk_case($slf, $dft))]
    : [_chk_case($slf, $dft)];
  0;
}

sub _get_value
{ my ($slf, $mod, $val) = @_;
  my ($nxt);

  # Detect the end of a value list
  $nxt = exists($slf->{'_end'});
  return (join($slf->{'_sep'}, @{$slf->{'-nxt'}}), 0)
    if $nxt && $val eq $slf->{'_end'};

  # Reject an error
  if ($slf->_tst_value($val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_err');
  }
  elsif ($slf->_chk_value($val))
  { return ($val, $slf->{'-cnt'}) if $slf->_dsp_validation($mod, 1, '_dup');
  }

  # Accept other value
  $slf->_nxt_value($val) if $nxt;
  ($val, $nxt);
}

sub _val_value
{ my ($slf, $mod) = @_;

  foreach my $itm (@{$slf->{'-prv'}})
  { $slf->_dsp_validation($mod, 0, '_err') if $slf->_tst_value($itm);
    $slf->_dsp_validation($mod, 0, '_dup') if $slf->_chk_value($itm, 1);
  }
  join($slf->{'_sep'}, @{$slf->{'-prv'}});
}

sub _tst_value
{ my ($slf, $val) = @_;

  exists($slf->{'_ref'}) && $val !~ $slf->{'_ref'};
}

# Control string capitalisation
sub _chk_case
{ my ($slf, $str) = @_;

  (!defined($str)) ? undef :
  $slf->{'_cas'}   ? $str :
                     uc($str);
}

# Compare the value with the previous values
sub _chk_value
{ my ($slf, $val, $flg) = @_;
  my $key;

  if (exists($slf->{'_end'}) && $slf->{'_dup'})
  { foreach my $prv (@{$slf->{$flg ? '-prv' : '-nxt'}})
    { if ($val eq $prv)
      { return 1 unless $flg;
        $flg = 0;
      }
    }
  }
  0;
}

# Display a string
sub _dsp_string
{ my ($mod, $str, $nxt) = @_;

  $mod->get_info('dsp')->dsp_string('', $str, $nxt);
}

# Display a text
sub _dsp_text
{ my ($slf, $mod, $key, $nxt) = @_;

  _dsp_string($mod, _repl_var($mod, $slf->{$key}), $nxt)
    if exists($slf->{$key});
}

# Report setting validation error
sub _dsp_validation
{ my ($slf, $mod, $flg, $msg) = @_;
  my ($key, $ret);

  if (exists($slf->{'_val'}))
  { if ($flg)
    { $ret = $slf->{'_val'} ne 'W';
      _dsp_text($slf, $mod, $msg, 1);
      unless ($ret)
      { _dsp_string($mod, "Do you want to specify a new value (Y/N)?", 0);
        $key = <STDIN>;
        $ret = ($key =~ m/\s*y(es)?/i) ? 1 : 0;
      }
      print "\n";
    }
    elsif ($slf->{'_val'} eq 'F')
    { _dsp_text($slf, $mod, $msg, 1);
      die "RDA-00118: Invalid value for setting '".$slf->{'_nam'}."'\n";
    }
    --$slf->{'-cnt'} if defined($slf->{'-cnt'}) && $slf->{'-cnt'} > 0;
  }
  $ret;
}

# Switch to the next value
sub _nxt_value
{ my ($slf, $val) = @_;

  if (ref($val))
  { $slf->{'-nxt'} = $val;
  }
  else
  { push(@{$slf->{'-nxt'}}, $val);
  }
  $slf->{'-cnt'} = (exists($slf->{'_val'}) && $slf->{'_val'} =~ m/^E(\d+)$/
    && !exists($slf->{'_end'})) ? $1 + 1 : -1;
  $slf->{'-cur'} = (defined($val = shift(@{$slf->{'-prv'}})) &&
    $val ne $slf->{'_clr'}) ? $val : '';
}

# Extract the setting from a configuration file
sub _repl_cfg
{ my ($mod, $cfg, $fil, $pos, $re) = @_;
  my $str;

  # Generate the regular expression
  $re = _repl_var($mod, $re);
  $re = ($cfg eq 'CONFIG') ? qr/$re/ : qr/$re/i;

  # Scan the file
  $fil = $mod->get_var($fil);
  if ($fil && open(CFG, "<$fil"))
  { while (<CFG>)
    { s/[\r\n]+//;
      if ($_ =~ $re)
      { $str = eval "\$$pos";
        last;
      }
    }
    close(CFG);
  }

  # Return the value or an empty string
  defined($str) ? $str : '';
}

# Evaluate a condition
sub _repl_cnd
{ my ($mod, $def) = @_;
  my ($cnd, $val, @tbl);

  (@tbl) = split(/,/, $def);
  while (($cnd, $val) = splice(@tbl, 0, 2))
  { return _repl_var($mod, $cnd) unless defined($val);
    next unless $cnd =~ m/^(\!)?(\?)?((\w+\.)*\w+)$/;
    $cnd = $mod->get_var($3);
    $cnd = defined($cnd) if $2;
    $cnd = !$cnd         if $1;
    return _repl_var($mod, $val) if $cnd;
  }
  '';
}

# Get the setting from an external module
sub _repl_ext
{ my ($mod, $pkg, $fct, $arg) = @_;
  my ($agt, $cmd, $str, @arg);

  # Execute the external code
  if ($pkg && $fct)
  { $pkg =~ s#\/#::#g;
    if ($arg)
    { foreach my $itm (split('\s*,\s*', $arg))
      { $itm = _repl_var($mod, $itm);
        $itm =~ s/'//g;
        $itm =~ s/\\+$//;
        push(@arg, $itm);
      }
    }
    $agt = $mod->get_info('agt');
    $cmd = (scalar @arg)
      ? "$pkg\:\:$fct(\$agt, '".join("', '", @arg)."')"
      : "$pkg\:\:$fct(\$agt)";
    eval "require $pkg";
    $str = eval $cmd unless $@;
  }
  
  # Return the value or an empty string
  defined($str) ? $str : '';
}

# List files
sub _repl_lst
{ my ($mod, $src, $dir, $pos, $re) = @_;
  my ($buf, $cnt, $flg, @tbl, %tbl);

  # Decode the options
  $re = _repl_var($mod, $re);
  $re = ($src eq 'LIST') ? qr#$re# : qr#$re#i;
  ($flg, $pos) = (1, -$pos) if $pos < 0;

  # Scan the directory
  $dir = $mod->get_var($dir);
  if ($dir && opendir(DIR, $dir))
  { foreach my $nam (readdir(DIR))
    { $tbl{eval "\$$pos"} = 1 if $nam =~ $re;
    }
    closedir(DIR);
  }

  # Return the list
  if ($flg)
  { @tbl = sort {$a <=> $b} keys(%tbl);
  }
  else
  { @tbl = sort keys(%tbl);
  }
  $buf = '';
  $cnt = 0;
  foreach my $itm (@tbl)
  { $buf .= '|' if $cnt++;
    $buf .= "$cnt|$itm";
  }
  $buf;
}

# Search modules
sub _repl_mod
{ my ($mod, $sep, $re1, $re2) = @_;
  my ($cfg, $flg, %tbl);

  # Scan the directory
  $cfg = $mod->get_info('cfg');
  $flg = $cfg->get_info('RDA_CASE');
  if (opendir(DIR, $cfg->get_group('D_RDA_CODE')))
  { $re1 = $re1 ? qr#$re1#i : qr#.#;
    $re2 = qr#$re2#i if $re2;
    foreach my $nam (readdir(DIR))
    { $nam = uc($nam) unless $flg;
      next unless $nam =~ s/\.(ctl|def)$//i && $nam =~ $re1;
      next if $re2 && $nam =~ $re2;
      $tbl{$nam} = 1;
    }
    closedir(DIR);
  }

  # Return the modules found
  join($sep, sort keys(%tbl));
}

# Get multi-run collection information
sub _repl_mrc
{ my ($mod, $cmd, $set, $str) = @_;
  my ($cnt, $mrc, %tbl);

  if ($mrc = $mod->get_info('mrc'))
  { $cmd = lc($cmd);
    $set = $mod->get_var($1, '') if $set =~ m/^\*(\w+)$/;
    if ($cmd eq 'groups')
    { if (defined($str))
      { $str = _repl_var($mod, $str);
        return '' if $str eq '*';
        %tbl = map {lc($_) => 1} split(/\|/, $str)
      }
      return join('|', grep {!exists($tbl{$_})} $mrc->get_groups($set));
    }
    if ($cmd eq 'items')
    { $cnt = 0;
      if (defined($str))
      { $str = _repl_var($mod, $str);
        return '' if $str eq '*';
        %tbl = map {lc($_) => 1} split(/\|/, $str)
      }
      return join('|', map {++$cnt => $_}  grep {!exists($tbl{$_})}
        $mrc->get_groups($set));
    }
    return join('|', $mrc->get_members($set,
      defined($str) ? _repl_var($mod, $str) : undef))
      if $cmd eq 'members';
    return $mrc->get_title("$set:$str") 
      if $cmd eq 'title' && defined($str);
  }
  '';
}

# Extract the setting from the Windows registry
sub _repl_reg
{ my ($mod, $key, $nam, $suf) = @_;
  my ($obj, $str);

  if (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
  { $mod->set_info('reg',
      $obj = RDA::Object::Windows->new($mod->get_info('agt')))
      unless ($obj = $mod->get_info('reg'));
    return defined($suf) ? $str.$suf : $str
      if defined($str = $obj->get_registry($key, $nam));
  }
  '';
}

# Search a file
sub _repl_src
{ my ($mod, $src, $dir, $opt, $re, $flt) = @_;
  my ($lvl, $one, $str, @tbl, %mod);

  # Decode the options
  $lvl = 0;
  $re = _repl_var($mod, $re);
  $re = eval "(\$src eq 'SEARCH') ? qr#$re# : qr#$re#i";
  $lvl = $1 || 8 if $opt =~ m/r([1-9])?/;
  $flt = '-e' if index($opt, 'w') >= 0;
  $one = index($opt, 'f') >= 0;

  # Scan the directory
  $dir = $mod->get_var($dir);
  return '' unless $dir && opendir(DIR, $dir);
  $dir = '' if $dir =~ m/^[\\\/]$/;
  _grep_dir(\@tbl, $dir, $re, $lvl, $flt, $one);

  # Indicate that no match has been found
  return '' unless @tbl;

  # Sort the file names
  if (index($opt, 'd') >= 0)
  { @tbl = sort {dirname($a)  cmp dirname($b) ||
                 basename($a) cmp basename($b)} @tbl;
  }
  elsif (index($opt, 'n') >= 0)
  { @tbl = sort {$a cmp $b} @tbl;
  }
  elsif (index($opt, 't') >= 0)
  { foreach my $nam (@tbl)
    { $mod{$nam} = (stat($nam))[9] || 0;
    }
    @tbl = sort {$mod{$b} <=> $mod{$a} || $a cmp $b} keys(%mod);
  }

  # Return the first match
  (index($opt, 'b') >= 0) ? basename($tbl[0]) :
  (index($opt, 'w') >= 0) ? dirname($tbl[0]) :
  $tbl[0];
}

sub _grep_dir
{ my ($tbl, $dir, $re, $lvl, $flt, $one) = @_;
  my ($pth, @sub);

  # Read the directory content
  --$lvl;
  foreach my $nam (readdir(DIR))
  { $pth = RDA::Object::Rda->cat_file($dir, $nam);
    if ($nam =~ $re && eval "$flt '$pth'")
    { push(@$tbl, $pth);
      if ($one)
      { $lvl = 0;
        last;
      }
    }
    push(@sub, $pth) if $lvl > 0 && -d $pth && -r $pth && $nam !~ m/^\.+$/;
  }
  closedir(DIR);

  # Explore subdirectories
  if ($lvl > 0)
  { foreach my $sub (@sub)
    { next unless opendir(DIR, $sub);
      _grep_dir($tbl, $sub, $re, $lvl, $flt, $one);
      return if $one && @$tbl;
    }
  }
}

# Replace settings in string
sub _repl_var
{ my ($mod, $str, $flg) = @_;
  my ($val, $var);

  # Replace special characters
  if ($flg)
  { $str =~ s/\\n/\n/g;
    $str =~ s/&\#10;/\n/g;
    $str =~ s/&\#34;/"/g;
    $str =~ s/&\#39;/'/g;
  }

  # Replace variables
  1 while ($str =~ s/\$\{((\w+\.)*\w+)(\:([^\{\}]*))?\}/
                     $mod->get_var($1, defined($4) ? $4 : '')/eg);

  # Treat commands
  local $SIG{'__WARN__'} = sub {};
  $str =~ s/`(.*?)`/eval {
      $val = $1;
      if ($val && $^O eq 'VMS' && $val =~ m#[\<\>]# && $val !~ m#^PIPE #i)
      { $val = "PIPE $val";
        $val =~ s#2>&1#2>SYS\$OUTPUT#g;
      }
      $val = `$val`;
      $val =~ s#[\n\r]$##;
    };
    ($@ || $?) ? undef : $val;/eg;

  # Return the result
  $str;
}

# Extract the setting from an XML file
sub _repl_xml
{ my ($mod, $cfg, $fil, $key, $qry) = @_;
  my ($obj, $tbl);

  # Get the parsed XML and perform the query
  $tbl = $mod->get_info('xml');
  $fil = $mod->get_var($fil);
  $tbl->{$fil} = RDA::Object::Xml->new(
      $mod->get_info('agt')->get_setting('XML_TRACE', 0))->parse_file($fil)
    unless exists($tbl->{$fil});
  $obj = $tbl->{$fil};
  ($obj) = $obj->find(_repl_var($mod, $qry));

  # Return the requested value
  (!$obj) ? '' :
  (!$key) ? $obj->get_data :
            $obj->get_value($key, '');
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
L<RDA::Object::Windows|RDA::Object::Windows>,
L<RDA::Object::Xml|RDA::Object::Xml>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
