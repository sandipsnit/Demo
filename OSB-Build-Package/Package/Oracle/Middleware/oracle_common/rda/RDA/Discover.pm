# Discover.pm: Class Used to Manage the Auto Discovery Aspects

package RDA::Discover;

# $Id: Discover.pm,v 2.7 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Discover.pm,v 2.7 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Discover - Class Used to Manage the Auto Discovery Aspects

=head1 SYNOPSIS

require RDA::Discover;

=head1 DESCRIPTION

The objects of the C<RDA::Discover> class are used to manage the auto
discovery aspects.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
  use RDA::Object::Xml;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.7 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_inv = (
  LOCATION => 'INST_LOC',
  VERSION  => 'VER',
  );
my %tb_ocm = (
  LOCATION => 'INSTALLED_LOCATION',
  VERSION  => 'VERSION',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Discover-E<gt>new($agt,$dir)>

The object constructor. It takes the agent reference and the Oracle home
directory as arguments.

C<RDA::Discover> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_cfg'> > Reference to the RDA software configuration

=item S<    B<'_inv'> > Inventory object

=item S<    B<'_prd'> > OCM product list

=item S<    B<'_typ'> > Inventory type

=back

Internal keys are prefixed by an underscore. Defined types are as follows:

=over 11

=item B<       '' > No inventory found

=item B<    'INV' > Oracle home inventory

=item B<    'OCM' > OCM configuration information

=back

=cut

sub new
{ my ($cls, $agt, $dir) = @_;
  my ($fil, $obj, $slf, $trc);

  # Create the render object
  $slf = bless {
    _agt => $agt,
    _cfg => $agt->get_config,
    _typ => '',
    }, $cls;

  # Determine trace request
  $trc  = $agt->get_setting('XML_TRACE', 0);

  # Examine the Oracle home inventory
  unless ($agt->get_setting('NO_INVENTORY'))
  { $fil = RDA::Object::Rda->cat_file($dir, 'inventory', 'ContentsXML',
                                      'comps.xml');
    if (-r $fil)
    { $slf->{'_inv'} = RDA::Object::Xml->new($trc)->parse_file($fil);
      $slf->{'_typ'} = 'INV';
      return $slf;
    }
  }

  # Examine the OCM configuration informantion
  unless ($agt->get_setting('NO_OCM'))
  { if ($fil = _get_ocm_inv($slf, $dir))
    { $slf->{'_inv'} = $obj = RDA::Object::Xml->new($trc)->parse_file($fil);
      $slf->{'_prd'} =
        [$obj->find(".../ROWSET TABLE='MGMT_LL_INV_COMPONENT'/ROW")];
      $slf->{'_typ'} = 'OCM';
      return $slf;
    }
  }

  # Return the object reference
  $slf;
}

# Find the OCM inventory file
sub _get_ocm_inv
{ my ($slf, $dir) = @_;
  my ($cfg, $nam, $pth);

  $cfg = $slf->{'_cfg'};
  foreach my $sub ($cfg->cat_dir($dir, 'ccr'),
                   $cfg->cat_dir($dir, 'livelink'),
                   $cfg->cat_dir($dir, $cfg->up_dir, 'utils', 'ccr'))
  { next unless -d $sub;

    # Find the CONFIG_HOME
    if (-d $cfg->cat_dir($sub, 'hosts'))
    { if (exists($ENV{'ORACLE_CONFIG_HOME'}))
      { $sub = $cfg->cat_dir($ENV{'ORACLE_CONFIG_HOME'}, 'ccr');
      }
      elsif (-d ($pth = $cfg->cat_dir($sub, 'hosts', $cfg->get_host)) ||
             -d ($pth = $cfg->cat_dir($sub, 'hosts', $cfg->get_node)))
      { $sub = $pth;
      }
      else
      { next;
      }
    }

    # Check the presence of the Oracle home target
    if (-d ($pth = $cfg->cat_dir($sub, 'state', 'review')))
    { if (opendir(DIR, $pth))
      { ($nam) = grep {/-oracle_home_config\.xml$/i} readdir(DIR);
        closedir(DIR);
        return $pth
          if $nam && -r ($pth = $cfg->cat_file($pth, $nam));
      }
    }
  }
  '';
}

=head2 S<$h-E<gt>get_product([$dft])>

This method returns the extended name of the product or the default value when
not available.

=cut

sub get_product
{ my ($slf, $dft) = @_;

  if ($slf->{'_typ'} eq 'INV')
  { my ($obj) = $slf->{'_inv'}->find('PRD_LIST/TL_LIST/COMP/EXT_NAME');
    return $obj->get_data if ref($obj);
  }
  $dft;
}

=head2 S<$h-E<gt>get_type>

This method indicates the type of inventory used for the auto discovery.

=cut

sub get_type
{ shift->{'_typ'};
}

=head1 AUTO DISCOVERY METHODS

=head2 S<$h-E<gt>check($name,$prod)>

This method determines if the product is installed. When it finds the product
in the inventory, it sets the temporary settings C<E<lt>nameE<gt>_VERSION> and
C<E<lt>nameE<gt>_LOCATION> and returns a true value. Otherwise, it returns an
undefined value.

=cut

sub check
{ my ($slf, $nam, $prd) = @_;
  my ($agt, $res);

  # Validate the parameters
  return undef unless $nam =~ m/^\w+$/ && $prd =~ m/^\w+(\.\w+)*$/;
  
  # Check the product information
  $agt = $slf->{'_agt'};
  if ($slf->{'_typ'} eq 'INV')
  { $prd =~ s/\./\\\./g;
    $res = _get_first($slf->{'_inv'},"PRD_LIST/COMP_LIST/PATCH NAME='^$prd\$'")
      || _get_first($slf->{'_inv'},"PRD_LIST/COMP_LIST/COMP NAME='^$prd\$'");
    if ($res)
    { foreach my $key (keys %tb_inv)
      { $agt->set_temp_setting("$nam\_$key", $res->{$tb_inv{$key}})
          if exists($res->{$tb_inv{$key}});
      }
      return 1;
    }
  }
  elsif ($slf->{'_typ'} eq 'OCM')
  { foreach my $obj (@{$slf->{'_prd'}})
    { if (_get_text($obj, 'NAME', '') eq $prd)
      { foreach my $key (keys %tb_ocm)
        { $agt->set_temp_setting("$nam\_$key", $res)
            if defined($res = _get_text($obj, $tb_ocm{$key}));
        }
        return 1;
      }
    }
  }
  undef;
}

=head2 S<$h-E<gt>find($attr,$prod[,$dft])>

This method finds the specified attribute for a given product and returns its
value. It returns the default value when the product is not found.

=cut

sub find
{ my ($slf, $key, $prd, $val) = @_;
  my $res;

  # Validate the parameters
  $key = uc($key);
  return undef unless exists($tb_inv{$key}) && $prd =~ m/^\w+(\.\w+)*$/;
  
  # Find the attribute
  if ($slf->{'_typ'} eq 'INV')
  { $key = $tb_inv{$key};
    $prd =~ s/\./\\\./g;
    $res = _get_first($slf->{'_inv'}, "PRD_LIST/COMP_LIST/PATCH NAME='^$prd\$'")
      || _get_first($slf->{'_inv'}, "PRD_LIST/COMP_LIST/COMP NAME='^$prd\$'");
    $val = $res->{$key} if $res && exists($res->{$key});
  }
  elsif ($slf->{'_typ'} eq 'OCM')
  { foreach my $obj (@{$slf->{'_prd'}})
    { if (_get_text($obj, 'NAME', '') eq $prd)
      { $val = _get_text($obj, $tb_ocm{$key});
        last;
      }
    }
  }
  $val;
}

# Get the first element from a query result
sub _get_first
{ my ($xml, $qry, $nod) = @_;

  ($nod) = $xml->find($qry);
  $nod;
}

# Get the text of a specific XML element
sub _get_text
{ my ($xml, $tag, $dft) = @_;
  my $nod;

  ($nod = _get_first($xml, $tag)) ? $nod->get_data : $dft;
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
L<RDA::Extra|RDA::Extra>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>
L<RDA::Object::Xml|RDA::Object::Xml>
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>,

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
