# Profile.pm: Class Used for Objects to Manage Profiles

package RDA::Profile;

# $Id: Profile.pm,v 2.12 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Profile.pm,v 2.12 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Profile - Class Used for Objects to Manage Profiles

=head1 SYNOPSIS

require RDA::Profile;

=head1 DESCRIPTION

The objects of the C<RDA::Profile> class are used to manage profiles.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.12 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $RPT_NXT = ".N1\n";
my $RPT_SUB = "    \001  ";
my $RPT_TXT = "    ";

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Profile-E<gt>new($dir,$agt)>

The object constructor. It takes the data directory and the agent reference
as arguments.

C<RDA::Profile> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_alt'> > Alternative profile names

=item S<    B<'_dir'> > Module directory

=item S<    B<'_lvl'> > Level definitions

=item S<    B<'_prf'> > Profile definitions

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $dir, $agt) = @_;
  my ($slf);

  # Create the render object
  $slf = bless {
    _dir => $dir,
    }, ref($cls) || $cls;
  $slf->{'_agt'} = $agt if ref($agt);;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>chk_profile([$name])>

This method indicates whether the specified setting level and profile name are
current.

=cut

sub chk_profile
{ my ($slf, $nam) = @_;
  my ($agt, $lvl, @prf);

  # No change by default
  return 1 unless $nam;

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_lvl'});

  # Separate profile and setting level
  $lvl = 0;
  foreach my $itm (split(/\-/, $nam))
  { if (exists($slf->{'_lvl'}->{$itm}))
    { $lvl = $slf->{'_lvl'}->{$itm};
    }
    elsif (exists($slf->{'_prf'}->{$itm}))
    { push(@prf, $itm);
    }
    else
    { die "RDA-00122: Invalid profile name '$itm'\n";
    }
  }

  # Compare setting level and profile name
  return 0 unless ($agt = $slf->{'_agt'});
  $lvl == $agt->get_setting('RDA_LEVEL',0) &&
  ((scalar @prf) == 0
    || join('-', @prf) eq $agt->get_setting('RDA_PROFILE',''));
}

=head2 S<$h-E<gt>display($name[,$flag])>

This method displays the manual page of the specified profile entry. When the
flag is set, it includes the profile settings.

=cut

sub display
{ my ($slf, $nam, $det, $flg) = @_;
  my ($abr, $agt, $buf, $cur, $lgt, $tbl, @mod, @set, @tbl, %txt);

  # Load the profile definitions when not yet done
  $slf->load unless exists($slf->{'_prf'});

  # Reject unknown profile
  return '' unless exists($slf->{'_prf'}->{$nam});

  # Initialization
  $agt = $slf->{'_agt'};
  $nam = $slf->{'_alt'}->{$nam} if exists($slf->{'_alt'}->{$nam});
  $cur = $slf->{'_prf'}->{$nam};

  # Analyse the profile definition
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

  # Display the profile name and title
  $buf = _dsp_title('NAME')
    ._dsp_text($RPT_TXT, "Profile ``".$nam.'`` - '.$slf->get_title($nam, ''),
               1);

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
      "The ``$nam`` profile uses the following modules:");
    foreach my $key (@mod)
    { $abr = $tbl->{$key} || $key;
      $lgt = 20 + length($key); 
      $buf .= _dsp_text(sprintf('%s%-*s  ', $RPT_SUB, $lgt,
        "!!module:$key!$abr!!"), $agt->get_title($key, '\040'));
    }
    $buf .= $RPT_NXT;
  }

  # Display the profile settings
  if (@set)
  { $buf .= _dsp_title('SETTINGS')._dsp_text($RPT_TXT,
       "The ``$nam`` profile sets the following temporary settings:");
    foreach my $key (@set)
    { $buf .= _dsp_text($RPT_SUB, '``'.$key.'='.$cur->{$key}.'``');
    }
    $buf .= $RPT_NXT;
  }

  # Display the copyright and trademark notices
  $buf .= _dsp_title('COPYRIGHT NOTICE')
    ._dsp_text($RPT_TXT,
      "Copyright (c) 2002, 2012, Oracle and/or its affiliates. "
      ."All rights reserved.", 1)
    ._dsp_title('TRADEMARK NOTICE')
    ._dsp_text($RPT_TXT,
      "Oracle and Java are registered trademarks of Oracle and/or its "
      ."affiliates. Other names may be trademarks of their respective owners.")
    unless $flg;

  # Return the result
  $buf;
}

=head2 S<$h-E<gt>get_levels>

This method returns the list of all setting levels. It loads the profile
definitions when not yet done.

=cut

sub get_levels
{ my $slf = shift;

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_lvl'});

  # Return the setting level list
  keys(%{$slf->{'_lvl'}});
}

=head2 S<$h-E<gt>get_profile>

This method returns the list of the current profile components.

=cut

sub get_profile
{ split(/-/, shift->{'_agt'}->get_setting('RDA_PROFILE',''));
}

=head2 S<$h-E<gt>get_profiles>

This method returns the list of all defined profiles. It loads the profile
definitions when not yet done.

=cut

sub get_profiles
{ my ($slf) = @_;

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_prf'});

  # Return the profile list
  keys(%{$slf->{'_prf'}});
}

=head2 S<$h-E<gt>get_title($name[,$default])>

This method returns the description of the specified profile or the default
value when not found.

=cut

sub get_title
{ my ($slf, $nam, $ttl) = @_;

  return $ttl unless $nam;

  my $cur = $slf->{'_prf'}->{$nam};
  exists($cur->{"?$nam"}) ? $cur->{"?$nam"} :
  exists($cur->{"?"})     ? $cur->{"?"} :
  $ttl;
}

=head2 S<$h-E<gt>load([$file[,$flag]])>

This method loads the setup profile definitions from the specified file. When
no file is specified, it uses the file specified by the C<RDA_PROFILE>
environment variable or C<rda.cfg> by default.

When the flag is set, it raises an exception when encountering load errors.

It returns the reference to the profile object.

=cut

sub load
{ my ($slf, $fil, $flg) = @_;
  my ($cas, $cur, $err, $ifh, $key, $lin, $pos, $val);

  # Select the profile definition file
  if ($fil)
  { $fil = RDA::Object::Rda->cat_file($slf->{'_dir'}, $fil) unless -r $fil;
  }
  else
  { $fil = RDA::Object::Rda->cat_file($slf->{'_dir'}, 'rda.cfg')
      unless ($fil = $ENV{'RDA_PROFILE'}) && -r $fil;
  }
  $ifh = IO::File->new;
  $ifh->open("<$fil")
    or die "RDA-00112: Cannot open the profile definition file $fil:\n $!\n";

  # Load the profile definition
  $slf->{'_alt'} = {};
  $slf->{'_lvl'} = {};
  $slf->{'_prf'} = {};
  $cas = exists($slf->{'_agt'})
    ? $slf->{'_agt'}->get_config->get_info('RDA_CASE')
    : 1;
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
      if ($lin =~ s/^(\w+|\?\w*|(!\w*){1,2})\s*=\s*//)
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
        die "RDA-00113: Invalid profile specification value\n"
          unless $lin =~ m/^\s*(#.*)?$/;

        if ($cur)
        { $cur->{$key} = $val;
        }
        elsif ($key !~ m/^[\!\?]/)
        { $slf->{'_lvl'}->{$key} = $val;
        }
      }
      elsif ($lin =~ s/^\[([\w\|]+)\]$//)
      { $cur = {};
        foreach $key (split(/\|/, $1))
        { $slf->{'_prf'}->{$key} = $cur;
          unless ($cas)
          { $slf->{'_alt'}->{lc($key)} = $key;
            $slf->{'_prf'}->{lc($key)} = $cur;
          }
        }
      }
      elsif ($lin =~ s/^\*\s*=\s*([\w\,]+)// && $cur)
      { $cur->{'*'} = $1;
        die "RDA-00114: Invalid profile module list\n"
          unless $lin =~ m/^\s*(#.*)?$/;
      }
      elsif ($lin =~ s/^\@\s*=\s*(\w+(:\w+)*)// && $cur)
      { $cur->{'@'} = $1;
        die "RDA-00113: Invalid profile specification value\n"
          unless $lin =~ m/^\s*(#.*)?$/;
      }
      elsif ($lin !~ m/^(#.*)?$/)
      { die "RDA-00115: Unexpected profile specification\n";
      }
    };

    # Report an error
    if ($@)
    { my $msg = $@;

      $msg =~ s/\n$//;
      last if $msg =~ m/^last/;
      $err++;
      print $msg;
      print " in the profile definition file near line $pos" if $pos;
      print "\n";
    }

    # Prepare the next line
    $lin = '';
  }
  $ifh->close;

  # Terminate if errors are encountered
  die "RDA-00116: Error(s) in profile definition file $fil\n" if $flg && $err;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>set_profile([$name])>

This method sets the setup profile. When there is no name specified, it uses
the current setup profile name. It returns the list of modules associated with
that profile.

=cut

sub set_profile
{ my ($slf, $nam) = @_;
  my ($agt, $cur, $typ, @prf, %mod);

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_prf'});

  # Set the setting level and extract profile name components
  $agt = $slf->{'_agt'};
  if ($nam)
  { foreach my $itm (split(/\-/, $nam))
    { if (exists($slf->{'_lvl'}->{$itm}))
      { $agt->set_setting('RDA_LEVEL', $slf->{'_lvl'}->{$itm});
      }
      else
      { push(@prf, $itm);
      }
    }
  }

  # Apply the profile
  $typ = $agt->get_setting('RDA_TYPE', '');
  @prf = split(/\-/, $agt->get_setting('RDA_PROFILE','')) unless @prf;
  foreach my $itm (@prf)
  { die "RDA-00122: Invalid profile name '$itm'\n"
      unless exists($slf->{'_prf'}->{$itm});
    $cur = $slf->{'_prf'}->{$itm};
    foreach my $key (keys(%$cur))
    { if ($key eq '*')
      { foreach my $mod (split(/\,/, $cur->{$key}))
        { $mod{$mod} = 1;
        }
      }
      elsif ($key =~ /^\w/)
      { $agt->set_temp_setting($key, $cur->{$key});
      }
      elsif ($key eq '@')
      { die "RDA-00126: Incompatible profiles\n"
          if $typ && $typ ne $cur->{$key};
        $typ = $cur->{$key};
      }
    }
  }
  $agt->set_setting('RDA_PROFILE',join('-', @prf)) if @prf;
  $agt->set_setting('RDA_TYPE',$typ);

  # Return the module list
  sort keys(%mod);
}

=head2 S<$h-E<gt>xref([$flag])>

This method produces a cross-reference of the profile definitions and the
related modules. When the flag is set, it includes the profiles without title.

=cut

sub xref
{ my ($slf, $flg) = @_;
  my ($buf, %tb_bad, %tb_mod, %tb_prf);

  # Load the profile definition when not yet done
  $slf->load unless exists($slf->{'_prf'});

  # Get the module list
  foreach my $mod ($slf->{'_agt'}->get_config->get_modules)
  { $tb_mod{$mod} = [];
  }

  # Analyze the profiles
  foreach my $prf (sort keys(%{$slf->{'_prf'}}))
  { next unless $flg || $slf->get_title($prf);
    $tb_prf{$prf} = [];
    if (exists($slf->{'_prf'}->{$prf}->{'*'}))
    { foreach my $mod (split(',', $slf->{'_prf'}->{$prf}->{'*'}))
      { if (exists($tb_mod{$mod}))
        { push(@{$tb_mod{$mod}}, $prf);
        }
        else
        { push(@{$tb_bad{$mod}}, $prf);
        }
        push(@{$tb_prf{$prf}}, $mod);
      }
    }
  }

  # Produce the cross-reference
  $buf = _dsp_name('Profile Cross Reference').$RPT_NXT;
  $buf .= _xref_dsp(\%tb_prf, '-', 'Defined Profiles:',   'profile');
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
L<RDA::Options|RDA::Options>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
