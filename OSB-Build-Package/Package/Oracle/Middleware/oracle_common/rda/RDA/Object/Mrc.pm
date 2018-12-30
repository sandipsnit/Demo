# Mrc.pm: Class Used for Managing Multi-run Collections

package RDA::Object::Mrc;

# $Id: Mrc.pm,v 1.15 2012/08/13 14:19:16 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Mrc.pm,v 1.15 2012/08/13 14:19:16 mschenke Exp $
#
# Change History
# 20120813  MSC  Introduce the current calling block concept.

=head1 NAME

RDA::Object::Mrc - Class Used for Managing Multi-run Collections

=head1 SYNOPSIS

require RDA::Object::Mrc;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Mrc> class are used to manage collections
performed in multiple runs. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Block qw($CONT $SPC_REF $SPC_VAL);
  use RDA::Object;
  use RDA::Object::Rda qw($RE_MOD);
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'beginCollect'   => ['$[MRC]', 'begin'],
    'endCollect'     => ['$[MRC]', 'end'],
    'getCollections' => ['$[MRC]', 'get_collections'],
    'getLastRun'     => ['$[MRC]', 'get_run'],
    'getGroups'      => ['$[MRC]', 'get_groups'],
    'getGroupSets'   => ['$[MRC]', 'get_sets'],
    'getMembers'     => ['$[MRC]', 'get_members'],
    'validate'       => ['$[MRC]', 'validate'],
    },
  beg => \&_begin_mrc,
  cmd => {
    'collect'  => [\&_exe_collect, \&_get_collect, 0, 0],
    },
  dep => [qw(RDA::Object::Output)],
  end => \&_end_mrc,
  glb => ['$[MRC]'],
  inc => [qw(RDA::Object)],
  met => {
    'begin'           => {ret => 0},
    'end'             => {ret => 0},
    'get_collections' => {ret => 1},
    'get_groups'      => {ret => 1},
    'get_info'        => {ret => 0},
    'get_members'     => {ret => 1},
    'get_run'         => {ret => 0},
    'get_sets'        => {ret => 1},
    'set_info'        => {ret => 0},
    'validate'        => {ret => 0},
    },
  );

# Define the global private constants
my $RPT_LST = "    \001* ";
my $RPT_NXT = ".N1\n";
my $RPT_SUB = "    \001  ";
my $RPT_TXT = "    ";

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Mrc-E<gt>new($agt,$pkg)>

The multi-run collection control object constructor. This method takes the
agent and package object references as arguments.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'oid' > > Object identifier

=item S<    B<'out' > > Reference to the global reporting control object

=item S<    B<'pkg' > > Package reference

=item S<    B<'rpt' > > Reference to the local reporting control object

=item S<    B<'_acc'> > Section acceptance indicator

=item S<    B<'_cur'> > Current table of content record

=item S<    B<'_dft'> > Default acceptance status

=item S<    B<'_grp'> > Group definitions

=item S<    B<'_lvl'> > Collection level

=item S<    B<'_prv'> > Previous run table of content

=item S<    B<'_ref'> > Table of content record used as reference

=item S<    B<'_sct'> > Name of the current active section

=item S<    B<'_set'> > Set definitions

=item S<    B<'_toc'> > Current run table of content

=item S<    B<'_typ'> > User type

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt, $pkg) = @_;
  my ($slf);

  # Create the object
  $slf = ref($pkg)
    ? {agt  => $agt,
       oid  => $pkg->get_oid,
       out  => $agt->get_output,
       pkg  => $pkg,
       rpt  => $pkg->get_output,
       _lvl => 0,
       _typ => 1,
      }
    : {agt => $agt};

  # Return the object reference
  bless $slf, ref($cls) || $cls;
}

=head2 S<$h-E<gt>begin($oid[,$flag])>

This method ends any active collection context, saves the original context, and
starts a new collection context for the specified module. When the flag is set,
it assumes that the collections are performed as an user without super user
privileges.

It does not start a collection unless the base collection is already done and
returns -1.

It returns 0 on successful completion.

=cut

sub begin
{ my ($slf, $oid, $typ) = @_;
  my ($agt, $bkp, $out, $pkg, $toc);

  die "RDA-01290: Context change inside a collection\n"
    if $slf->{'_col'};

  # Restore any existing backup
  $slf->end;

  # Abort unless the base collection is done
  $agt = $slf->{'agt'};
  return -1 unless $agt->is_done($oid);
  $slf->{'oid'} = $oid;

  # Define the user type
  $slf->{'_typ'} = $typ;

  # Load the table of content
  $slf->{'_prv'} = $slf->{'_ref'} =
  $slf->{'_toc'} = $slf->{'_cur'} = $slf->{'out'}->load_run($oid);

  # Define the new reporting context
  $slf->{'_bkp'} = $bkp = {};
  $pkg = $slf->{'pkg'};

  $bkp->{'oid'} = $pkg->set_info('oid', $oid);
  
  $slf->{'rpt'} = $out = $pkg->get_agent->get_output->new($pkg);
  $bkp->{'rpt'} = $pkg->set_info('rpt', $out);
  $pkg->define('$[OUT]', $out);
  unless ($typ)
  { $out->set_info('mrc', 1);
    $out->enable_index(1);
    $out->load_index($slf->{'_prv'}, 0);
    $out->purge('M', '.', -1);
  }

  $toc = RDA::Object::Toc->new($out);
  $out->set_info('toc', $toc);
  $pkg->define('$[TOC]', $toc);

  # Initialize the usage counters
  $agt->set_current($oid);
  $agt->init_usage($oid);

  # Indicate the successful completion
  0;
}

=head2 S<$h-E<gt>delete>

This method deletes the multi-run collection control object.

=cut

sub delete
{ my ($slf) = @_;

  # Restore any original context
  $slf->end;

  # Delete the object
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>display($name[,$flag])>

This method displays the manual page of the specified collection group. When
the flag is set, it includes the group settings.

=cut

sub display
{ my ($slf, $nam, $det, $flg) = @_;
  my ($abr, $agt, $buf, $cur, $dsc, $lgt, $mod, $pat, $tbl,
      @mod, @pre, @set, @tbl, %txt);

  # Load the group definitions when not yet done
  $slf->load unless exists($slf->{'_grp'});

  # Reject unknown group
  return '' unless exists($slf->{'_grp'}->{$nam});

  # Initialization
  $agt = $slf->{'agt'};
  $cur = $slf->{'_grp'}->{$nam};

  # Analyse the group definition
  foreach my $key (sort keys(%$cur))
  { if ($key =~ m/^\!(\w*)(\!(\w*))?$/)
    { $txt{$1} = $cur->{$key} unless defined($2) && $3 ne $nam;
    }
    elsif ($key eq '*')
    { @mod = split(/,/, $cur->{$key});
    }
    elsif ($det && $key =~ m/^\w/)
    { push(@set, $key);
    }
  }

  # Display the group name and title
  $buf = _dsp_title('NAME')
    ._dsp_text($RPT_TXT, "Group ``".$nam.'`` - '.$slf->get_title($nam, ''), 1);

  # Display the text elements
  if (@tbl = keys(%txt))
  { $buf .= _dsp_title('DESCRIPTION');
    foreach my $key (sort @tbl)
    { $buf .= _dsp_block($RPT_TXT, $txt{$key}, 1);
    }
  }

  # Display the modules and their descriptions
  if (@mod)
  { $tbl = $agt->get_config->get_modules;
    $buf .= _dsp_title('MODULES')._dsp_text($RPT_TXT,
      "The ``$nam`` group uses the following sections:");
    foreach my $itm (@mod)
    { if ($itm =~ m/\-/)
      { ($mod, @pre) = split(/\-/, $itm);
        $abr = $tbl->{$mod} || $mod;
        $dsc = " ($dsc)" if ($dsc = $agt->get_title($mod, ''));
        $buf .= _dsp_text($RPT_LST, 'The ``'.join('``, ``', @pre)
          ."`` section(s) from !!module:$mod!$abr!!$dsc");
      }
      else
      { ($mod, $pat) = split(/\|/, $itm, 2);
        $abr = $tbl->{$mod} || $mod;
        $dsc = " ($dsc)" if ($dsc = $agt->get_title($mod, ''));
        $buf .= _dsp_text($RPT_LST, defined($pat)
          ? "The sections matching ``$pat`` from !!module:$mod!$abr!!$dsc"
          : "All sections from !!module:$mod!$abr!!$dsc");
      }
    }
    $buf .= $RPT_NXT;
  }

  # Display the group settings
  if (@set)
  { $buf .= _dsp_title('SETTINGS')._dsp_text($RPT_TXT,
       "The ``$nam`` group sets the following temporary settings:");
    foreach my $key (@set)
    { $buf .= _dsp_text($RPT_SUB, '``'.$key.'='.$cur->{$key}.'``');
    }
    $buf .= $RPT_NXT;
  }

  # Display the copyright and trademark notices
  $buf .= _dsp_title('COPYRIGHT NOTICE')
    ._dsp_text($RPT_TXT,
      "Copyright (c) 2002, 2012, Oracle and/or its affiliates. ".
      "All rights reserved.",1)
    ._dsp_title('TRADEMARK NOTICE')
    ._dsp_text($RPT_TXT,
      "Oracle and Java are registered trademarks of Oracle and/or its "
      ."affiliates. Other names may be trademarks of their respective owners.")
    unless $flg;

  # Return the result
  $buf;
}

=head2 S<$h-E<gt>end>

This method ends all operations in the current collection context and restores
the original context.

=cut

sub end
{ my ($slf) = @_;
  my ($agt, $bkp, $oid, $pkg, $rnd);

  if (defined($bkp = delete($slf->{'_bkp'})))
  { # Generate the table of content
    $slf->{'rpt'}->save_toc($slf->{'_toc'});

    # Delete the current report control object
    $slf->{'rpt'}->delete;

    # Restore the original context
    $pkg = $slf->{'pkg'};
    $pkg->define('$[TOC]', $bkp->{'toc'});
    $pkg->define('$[OUT]', $bkp->{'rpt'});
    $pkg->set_info('rpt', $slf->{'rpt'} = $bkp->{'rpt'});
    $oid = $pkg->set_info('oid', $bkp->{'oid'});

    # Update settings
    $agt = $slf->{'agt'};
    $agt->set_setting("LAST_MRC_RUN_$oid", RDA::Object::Rda->get_gmtime.' UTC',
        'T', 'Date and time of the last multi-run collection execution');
    $agt->update_usage($oid, 1);
    $agt->set_current;
    $agt->save if $agt->get_setting('RDA_SAVE');
  }
  0;
}

=head2 S<$h-E<gt>get_collections>

This method returns the list of modules involved in multi-run collections.

=cut

sub get_collections
{ (map {substr($_, 0, -4)}
       shift->{'agt'}->grep_setting('^S\d{3}\w{1,4}_MRC$', 'n'));
}

=head2 S<$h-E<gt>get_groups([$set])>

This method returns the list of all defined collection groups. It loads the
collection group definitions when not yet done.

=cut

sub get_groups
{ my ($slf, $set) = @_;

  # Load the group definition when not yet done
  $slf->load unless exists($slf->{'_grp'});

  # Return the group list
  return sort keys(%{$slf->{'_grp'}}) unless defined($set);
  return () unless exists($slf->{'_set'}->{$set = lc($set)});
  sort keys(%{$slf->{'_set'}->{$set}});
}

=head2 S<$h-E<gt>get_members($set[,$list[,$flag]]])>

This method returns the list of collection modules corresponding to the
specified collection groups. It uses C<default> as default group. An 
asterisk (C<*>) represents all groups. When the flag is set, it keeps the
prefix associations. It applies the corresponding group settings.

It loads the collection group definitions when not yet done.

=cut

sub get_members
{ my ($slf, $set, $lst, $flg) = @_;
  my ($agt, $grp, $tbl, @lst, %mod);

  # Load the group definition when not yet done
  $slf->load unless exists($slf->{'_grp'});

  # Validate the set
  if (defined($set))
  { die "RDA-01286: Invalid set name '$set'\n"
      unless exists($slf->{'_set'}->{$set = lc($set)});
    $tbl = $slf->{'_set'}->{$set};
  }
  else
  { $tbl = $slf->{'_grp'};
  }

  # Determine the group list
  $agt = $slf->{'agt'};
  if (!defined($lst))
  { @lst = ('default');
  }
  elsif ($lst eq '*')
  { @lst = keys(%$tbl);
  }
  else
  { @lst = split(/\|/, lc($lst));
  }

  # Analyze the groups
  foreach my $itm (@lst)
  { die "RDA-01285: Invalid group name '$itm'\n"
      unless exists($tbl->{$itm});
    $grp = $tbl->{$itm};
    foreach my $key (keys(%$grp))
    { if ($key eq '*')
      { foreach my $mod (split(/\,/, $grp->{$key}))
        { $mod{$flg ? $mod : $1} = 1 if $mod =~ m/^(\w+)/;
        }
      }
      elsif ($key =~ /^\w/)
      { $agt->set_temp_setting($key, $grp->{$key});
      }
    }
  }
  sort keys(%mod);
}

=head2 S<$h-E<gt>get_run>

This method returns the name of the last run setting.

=cut

sub get_run
{ my ($slf) = @_;

  $slf->{'_typ'}
    ? 'LAST_RUN_'.$slf->{'oid'}
    : 'LAST_MRC_RUN_'.$slf->{'oid'};
}

=head2 S<$h-E<gt>get_sets>

This method returns the list of all defined collection group sets. It loads the
collection group definitions when not yet done.

=cut

sub get_sets
{ my ($slf) = @_;

  # Load the group definition when not yet done
  $slf->load unless exists($slf->{'_grp'});

  # Return the group set list
  sort keys(%{$slf->{'_set'}});
}

=head2 S<$h-E<gt>get_title($name[,$default])>

This method returns the description of the specified group, or the default
value when not found.

=cut

sub get_title
{ my ($slf, $nam, $ttl) = @_;

  return $ttl unless $nam;

  my $cur = $slf->{'_grp'}->{$nam = lc($nam)};
  exists($cur->{"?$nam"}) ? $cur->{"?$nam"} :
  exists($cur->{"?"})     ? $cur->{"?"} :
  $ttl;
}

=head2 S<$h-E<gt>load([$flag])>

This method loads the setup group definitions. When the flag is set, it raises
an exception when encountering load errors.

It returns the reference to the object.

=cut

sub load
{ my ($slf, $flg) = @_;
  my ($cur, $err, $fil, $ifh, $key, $lin, $pos, $val);

  # Select the group definition file
  $fil = $slf->{'agt'}->get_config->get_file('D_RDA_DATA', 'mrc.cfg');
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    or die "RDA-01280: Cannot open the group definition file $fil:\n $!\n";

  # Load the group definition
  $slf->{'_set'} = {};
  $slf->{'_grp'} = {};
  $pos = $err = 0;
  $lin = '';
  while (<$ifh>)
  { # Trim leading spaces
    s/^\s+//;
    s/[\r\n]+$//;
    $lin .= $_;

    # Join continuation line
    $pos++;
    next if $lin =~ s/\\$//;
    $lin =~ s/\s+$//;

    # Parse the line
    eval {
      if ($lin =~ s/^(\w+|\?(\w+:\w+)?|!(\w+:\w+)?(!\w+)?)\s*=\s*//)
      { $key = $1;
        if ($lin =~ s/^'([^']*)'// || $lin =~ s/^"([^"]*)"//)
        { $val = $1;
          $val =~ s/&\#34;/"/;
          $val =~ s/&\#39;/'/;
        }
        else
        { $val = $lin;
          $lin = '';
        }
        die "RDA-01281: Invalid group specification value\n"
          unless $lin =~ m/^\s*(#.*)?$/;
        die "RDA-01283: Unexpected group specification\n"
          unless $cur;
        $cur->{$key} = $val;
      }
      elsif ($lin =~ s/^\[(\w+:\w+(\|\w+:\w+)*)\]$//)
      { $cur = {};
        foreach $key (split(/\|/, $1))
        { $slf->{'_grp'}->{$key = lc($key)} = $cur;
          $slf->{'_set'}->{$1}->{$2} = $cur if $key =~ m/^(.*):(.*)$/;
        }
      }
      elsif ($cur && $lin =~ s/^\*\s*=\s*(\w+([\-\|]\w+)*(,\w+([\-\|]\w+)*)*)//)
      { $cur->{'*'} = $1;
        die "RDA-01282: Invalid group module list\n"
          unless $lin =~ m/^\s*(#.*)?$/;
      }
      elsif ($lin !~ m/^(#.*)?$/)
      { die "RDA-01283: Unexpected group specification\n";
      }
    };

    # Report an error
    if ($@)
    { my $msg = $@;

      $msg =~ s/\n$//;
      last if $msg =~ m/^last/;
      $err++;
      print $msg;
      print " in the group definition file near line $pos" if $pos;
      print "\n";
    }

    # Prepare the next line
    $lin = '';
  }
  $ifh->close;

  # Terminate if errors are encountered
  die "RDA-01284: Error(s) in group definition file $fil\n" if $flg && $err;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>validate([$flag])>

This method accepts or rejects the current section. By default, it accepts the
section.

=cut

sub validate
{ my ($slf, $flg) = @_;

  die "RDA-01295: Not in a multi-run collection section\n"
    unless exists($slf->{'_sct'});
  $slf->{'_acc'} = defined($flg) ? $flg : 1;
}

=head2 S<$h-E<gt>xref([$flag])>

This method produces a cross-reference of the group definitions and the
related modules. When the flag is set, it includes the groups without title.

=cut

sub xref
{ my ($slf, $flg) = @_;
  my ($buf, $mod, %tb_bad, %tb_mod, %tb_grp, %tb_set);

  # Load the group definition when not yet done
  $slf->load unless exists($slf->{'_grp'});

  # Get the collection modules
  if (opendir(DIR, $slf->{'agt'}->get_config->get_group('D_RDA_CODE')))
  { foreach my $nam (readdir(DIR))
    { $tb_mod{uc($1)} = [] if $nam =~ m/^(M\d{3}[A-Z]\w*)\.(ctl|def)$/i;
    }
    closedir(DIR);
  }

  # Analyze the group sets
  foreach my $set (sort keys(%{$slf->{'_set'}}))
  { $tb_set{$set} = [map {"$set:$_"} keys(%{$slf->{'_set'}->{$set}})];
  }

  # Analyze the groups
  foreach my $prf (sort keys(%{$slf->{'_grp'}}))
  { next unless $flg || $slf->get_title($prf);
    $tb_grp{$prf} = [];
    if (exists($slf->{'_grp'}->{$prf}->{'*'}))
    { foreach my $col (split(',', $slf->{'_grp'}->{$prf}->{'*'}))
      { ($mod) = split(/[\-\|]/, $col);
        if (exists($tb_mod{$mod}))
        { push(@{$tb_mod{$mod}}, $prf);
        }
        else
        { push(@{$tb_bad{$mod}}, $prf);
        }
        push(@{$tb_grp{$prf}}, $col);
      }
    }
  }

  # Produce the cross-reference
  $buf = _dsp_name('Group Cross Reference').$RPT_NXT;
  $buf .= _xref_dsp(\%tb_set, '-', 'Defined Group Sets:', 'set');
  $buf .= _xref_dsp(\%tb_grp, '-', 'Defined Groups:',     'mrc');
  $buf .= _xref_dsp(\%tb_mod, '',  'Referenced Modules:', 'module');
  $buf .= _xref_dsp(\%tb_bad, '',  'Unknown Modules:');
  $buf;
}

# Display a result set
sub _xref_dsp
{ my ($tbl, $dft, $ttl, $typ) = @_;
  my ($buf, $lgt, $lnk, $max, @tbl);

  return '' unless ref($tbl) eq 'HASH' && (@tbl = sort keys(%$tbl));

  # Determine the name length
  $max = 0;
  foreach my $nam (@tbl)
  { $max = $lgt if ($lgt = length($nam)) > $max;
  }

  # Display the table
  $buf = _dsp_title($ttl);
  if ($typ)
  { $max += 6 + length($typ);
  }
  else
  { $lgt = $max + 4;
  }
  foreach my $nam (@tbl)
  { if ($typ)
    { $lnk = "!!$typ:$nam!$nam!!";
      $lgt = $max + length($nam);
    }
    else
    { $lnk = "``$nam``";
    }
    $buf .= _dsp_text(sprintf("  \001%-*s  ", $lgt, $lnk), @{$tbl->{$nam}}
      ? '``'.join('``, ``', @{$tbl->{$nam}}).'``'
      : $dft);
  }
  $buf.$RPT_NXT;
}

# --- Internal reporting routines ---------------------------------------------

sub _dsp_block
{ my ($pre, $txt, $nxt) = @_;
  my $buf = '';

  foreach my $str (split(/\n|\\n/, $txt))
  { if ($str =~ m/^(\s*[o\*\-]\s+)(.*)$/)
    { $buf .= ".I '$pre\001$1'\n$2\n\n";
    }
    else
    { $buf .= ".I '$pre'\n$str\n\n";
    }
  }
  $buf .= ".N $nxt\n" if $nxt;
  $buf;
}

sub _dsp_name
{ my ($ttl) = @_;

  ".R '$ttl'\n"
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

# --- Section management ------------------------------------------------------

# Start a new collection
sub _begin_collect
{ my ($slf, $ctl, $skp, $ctx, $col) = @_;
  my ($par, $rec, $tbl);

  # Manage the table of content contribution
  if (exists($slf->{'_cur'}))
  { $par = $slf->{'_ref'};
    push(@{$par->{'lin'}}, $par->{'col'}->{$col} = {
        col => {},
        nam => $col,
        lin => [],
        par => $par,
        sct => {},
        typ => 'C',
        }) unless exists($par->{'col'}->{$col});
    $slf->{'_ref'} = $par->{'col'}->{$col};
    $par = $slf->{'_cur'};
    push(@{$par->{'lin'}}, $par->{'col'}->{$col} = {
        col => {},
        nam => $col,
        lin => [],
        par => $par,
        sct => {},
        typ => 'C',
        }) unless exists($par->{'col'}->{$col});
    $slf->{'_cur'} = $par->{'col'}->{$col};
  }
  elsif ($slf->{'_typ'})
  { $slf->{'_prv'} = $rec = $slf->{'out'}->get_info('prv');
    $slf->{'_ref'} = exists($rec->{'col'}->{$col})
      ? $rec->{'col'}->{$col}
      : 
    $rec->{'col'}->{$col} = {
      col => {},
      nam => $col,
      lin => [],
      par => $rec,
      sct => {},
      typ => 'C',
      } unless exists($rec->{'col'}->{$col});
    $slf->{'_ref'} = $rec->{'col'}->{$col};
    $slf->{'_toc'} = $slf->{'_cur'} = {
      col => {},
      nam => $col,
      lin => [],
      sct => {},
      typ => 'C',
      };
    $slf->{'rpt'}->load_index($slf->{'_prv'}, 1);
  }
  else
  { die "RDA-01291: Missing module declaration\n";
  }

  # Update the multi-run collection flag
  $slf->{'agt'}->set_setting($slf->{'oid'}.'_MRC', $slf->{'_typ'} ? 0 : 1)
    if $slf->{'oid'} =~ $RE_MOD;

  # Determine the control section
  $ctl->{'begin'} = $ctl->{'end'} = -1;
  if ($ctx->check_variable('@CONTROL_SECTIONS'))
  { foreach my $nam ($ctx->get_value('@CONTROL_SECTIONS')->eval_as_array)
    { $ctl->{$nam} = 1;
    }
  }

  # Determine the sections to execute
  if (!$slf->{'_typ'})
  { # Load the sections already collected
    foreach my $nam (keys(%{$tbl = $slf->{'_cur'}->{'sct'}}))
    { $skp->{$nam} = 1 if $tbl->{$nam}->{'typ'} eq 'R';
    }
  }
  elsif ($> && $ctx->check_variable('@ROOT_SECTIONS'))
  { foreach my $nam ($ctx->get_value('@ROOT_SECTIONS')->eval_as_array)
    { $skp->{$nam} = 1;
    }
  }

  # Do not skip common sections
  if ($ctx->check_variable('@COMMON_SECTIONS'))
  { foreach my $nam ($ctx->get_value('@COMMON_SECTIONS')->eval_as_array)
    { delete($skp->{$nam});
    }
  }

  # Determine the validation default
  $slf->{'_dft'} = $ctx->check_variable('$VALIDATE')
    ? $ctx->get_value('$VALIDATE')->eval_as_scalar
    : 0;

  # Indicate the start of the collection
  $slf->{'rpt'}->begin_capture;
}

# Start a new section
sub _begin_section
{ my ($slf, $ctl, $skp, $nam) = @_;
  my ($typ);

  # Always execute a control section
  if (exists($ctl->{$nam}))
  { $slf->{'rpt'}->begin_capture;
    return 1;
  }

  # Skip a section when requested
  if (exists($skp->{$nam}))
  { my ($cur, $rec);

    $cur = $slf->{'_cur'};
    $rec = {
      lin => [],
      nam => $nam,
      rpt => [],
      typ => 'E',
      };
    if ($slf->{'_typ'})
    { push(@{$cur->{'lin'}}, exists($slf->{'_ref'}->{'sct'}->{$nam})
        ? $slf->{'_ref'}->{'sct'}->{$nam}
        : $rec);
    }
    elsif (!exists($cur->{'sct'}->{$nam}))
    { push(@{$cur->{'lin'}}, $cur->{'sct'}->{$nam} = $rec);
    }
    elsif (($cur = $cur->{'sct'}->{$nam})->{'typ'} ne 'R')
    { foreach my $key (keys(%$rec))
      { $cur->{$key} = $rec->{$key};
      }
    }
    return 0;
  }

  # Determine whether a common section requires cleanup
  $typ = $slf->{'_typ'} ? 'S' : 'R';
  $slf->{'_cln'} = (exists($slf->{'_ref'}->{'sct'}->{$nam})
    && $slf->{'_ref'}->{'sct'}->{$nam}->{'typ'} eq $typ)
    ? $slf->{'_ref'}->{'sct'}->{$nam}->{'rpt'}
    : undef;

  # Treat a section
  $slf->{'_acc'} = $slf->{'_dft'};
  $slf->{'_sct'} = $nam;
  $slf->{'rpt'}->begin_section($nam, $slf->{'_typ'});
  return 1;
}

# End the collection
sub _end_collect
{ my ($slf) = @_;

  if (exists($slf->{'_cur'}->{'par'}))
  { $slf->{'_cur'} = $slf->{'_cur'}->{'par'};
  }
  else
  { $slf->{'rpt'}->save_toc(delete($slf->{'_cur'}));
  }
  $slf->{'_ref'} = $slf->{'_ref'}->{'par'}
    if $slf->{'_typ'} && exists($slf->{'_ref'}->{'par'});
  --$slf->{'_lvl'};
}

# End the section
sub _end_section
{ my ($slf) = @_;
  my ($cur, $nam, $prv, $rec, $sct);

  $cur = $slf->{'_cur'};
  if (defined($nam = delete($slf->{'_sct'})))
  { $rec = $slf->{'rpt'}->end_section($nam, $slf->{'_typ'}, $slf->{'_acc'},
      $slf->{'_cln'});
    $sct = $cur->{'sct'};
    if (!exists($sct->{$nam}))
    { $sct->{$nam} = $rec;
      push(@{$cur->{'lin'}}, $rec);
    }
    elsif ($slf->{'_acc'} || $sct->{$nam}->{'typ'} ne 'S' || !$slf->{'_typ'})
    { $prv = $sct->{$nam};
      foreach my $key (keys(%$rec))
      { $prv->{$key} = $rec->{$key};
      }
    }
  }
  elsif ($slf->{'_typ'})
  { push(@{$cur->{'lin'}}, @{$slf->{'rpt'}->get_section});
  }
}

# --- SDCL extensions ---------------------------------------------------------

# Define the global variable
sub _begin_mrc
{ my ($pkg) = @_;
  my ($mrc);

  $mrc = __PACKAGE__->new($pkg->get_agent, $pkg);
  $pkg->set_info('mrc', $mrc);
  $pkg->define('$[MRC]', $mrc);
}

# Close all active reports
sub _end_mrc
{ shift->set_info('mrc')->delete;
}

# Get a collection definition
sub _get_collect
{ my ($slf, $spc, $str) = @_;

  if ($$str =~ s/^\&\{\s*//)
  { $spc->[$SPC_REF] = $slf->parse_value($str);
    die "RDA-01292: Invalid or missing name\n"
      unless $$str =~ s/^\}\s*//;
  }
  elsif ($$str =~ s/^(\w+(\|\w+)*)\s*//)
  { $spc->[$SPC_REF] = $1;
  }
  else
  { die "RDA-01292: Invalid or missing name\n"
  }
  $spc->[$SPC_VAL] = $slf->parse_sub_list($str);
}

# Execute a collection
sub _exe_collect
{ my ($slf, $spc) = @_;
  my ($agt, $blk, $col, $dft, $err, $mrc, $nam, $pre, $sct, $top);

  $top = $slf->get_top;
  $agt = $top->{'agt'};
  $mrc = $top->{'mrc'};
  die "RDA-01293: Invalid collect nesting\n" if exists($mrc->{'_sct'});

  # Load the block
  $col = $col->eval_as_string if ref($col = $spc->[$SPC_REF]);
  ($nam, $pre) = split(/\|/, $col, 2);
  return $CONT unless defined($nam) && length($nam);
  unless ($blk = $agt->get_block($nam))
  { $blk = RDA::Block->new($nam, $top->{'dir'});
    $blk->{'glb'} = {%{$top->{'glb'}}};
    $blk->load($agt, 1);

    # Initialize the macro list
    $agt->get_macros($blk->{'_lib'});
  }

  # Execute the associated code block
  $dft = $top->{'_dft'};
  if (exists($blk->{'_sct'}) && exists(($sct = $blk->{'_sct'})->{'-'}))
  { my ($arg, $ctx, $cur, $dst, $flg, $ret, $src, @cls, %ctl, %skp);

    $blk->{'_par'} = $slf;

    # Transfer new existing classes
    $src = $blk->{'use'};
    $dst = $top->{'use'};
    $flg = $blk->{'_use'};
    @cls = grep {!exists($dst->{$_})} keys(%$src);
    foreach my $cls (sort {$src->{$a}->{'rnk'} <=> $src->{$b}->{'rnk'}
      || $a cmp $b} @cls)
    { $dst->{$cls} = $src->{$cls};
      &{$src->{$cls}->{'beg'}}($top, $flg->{$cls})
        if exists($src->{$cls}->{'beg'});
    }

    # Evaluate the argument list
    $arg = $spc->[$SPC_VAL]->eval_value;

    # Create the execution context and manage recursive calls
    ++$mrc->{'_lvl'};
    $ctx = $blk->{'ctx'}->push_context($slf, $slf->{'ctx'}, 1);

    # Declare the arguments
    $ctx->set_value('@arg', $arg);

    # Execute the code before any section
    $err = 0;
    unless ($blk->{'dft'})
    { $ctx->{'val'} = $VAL_UNDEF;
      eval {$ret = $sct->{'-'}->exec_block("section '-'")};
      $ret = $blk->check_die($@) if $@;
      ++$err if $ret < 0;
      $blk->{'dft'} = 1;
    }

    # Select the sections to execute
    _begin_collect($mrc, \%ctl, \%skp, $ctx, $col);
    if (defined($pre))
    { $blk->{'nxt'} = [grep {m/^$pre\_/} @{$blk->{'_exe'}}];
    }
    else
    { $blk->{'nxt'} = [@{$blk->{'_exe'}}];
    }
    unshift(@{$blk->{'nxt'}}, 'begin') if exists($sct->{'begin'});

    # Execute the selected sections
    $ctx->{'val'} = $VAL_UNDEF;
    while (defined($cur = shift(@{$blk->{'nxt'}})))
    { next unless _begin_section($mrc, \%ctl, \%skp, $cur);
      last if $blk->check_quotas;
      $blk->{'sct'}->{$cur} = 1;
      eval {$ret = $sct->{$cur}->exec_block("section '$cur'")};
      $ret = $blk->check_die($@) if $@;
      _end_section($mrc);
      if ($ret)
      { ++$err unless $ret > 0;
        last;
      }
    }
    $blk->{'val'} = $ctx->get_internal('val')->eval_as_scalar
      unless $ret < 0;
    if (exists($sct->{'end'}))
    { $blk->{'sct'}->{'end'} = 1;
      eval {$ret = $sct->{'end'}->exec_block("section 'end'")};
      $ret = $blk->check_die($@) if $@;
      ++$err if $ret < 0;
    }

    # Restore the previous context
    $ctx->pop_context($blk, $slf);
    _end_collect($mrc);
  }
  else
  { $err = -1;
  }
  $top->{'_dft'} = $dft;

  # Keep or free the block memory
  if ($blk->{'ctx'}->check_variable('$KEEP_BLOCK'))
  { $agt->keep_block($nam, $blk);
  }
  else
  { # Resynchronize the calling block
    $top->{'rpt'}->deprefix($blk) if exists($top->{'rpt'});

    # Delete the block
    $blk->delete;
  }

  # Propagate any error
  die "RDA-01294: Error encountered in the block called\n" if $err;

  # Indicate the successful completion
  $CONT;
}

sub _load_list
{ my ($tbl, $lst) = @_;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Report|RDA::Object::Report>,
L<RDA::Object::Toc|RDA::Object::Toc>,
L<RDA::Render|RDA::Render>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
