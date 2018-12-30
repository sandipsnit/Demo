# Input.pm: Discovery Plug-in for Accessing Inputs

package IRDA::CV0100::Input;

# $Id: Input.pm,v 1.25 2012/05/30 15:53:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/IRDA/CV0100/Input.pm,v 1.25 2012/05/30 15:53:15 mschenke Exp $
#
# Change History
# 20120530  MSC  Extend it for Oracle Fusion Applications.

=head1 NAME

IRDA::CV0100::Input - Discovery Plug-in for Accessing Inputs

=head1 SYNOPSIS

require IRDA::CV0100::Input;

=head1 DESCRIPTION

This package regroups the definition of the discovery mechanisms for getting
values from the environment.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION $PLUGIN);
$VERSION = sprintf("%d.%02d", q$Revision: 1.25 $ =~ /(\d+)\.(\d+)/);

# Define the global private variables
my %tb_run = (
  'apply_request_value' => \&_apply_request_value,
  'get_env'             => \&_get_env,
  'get_merge_period'    => \&_get_merge_period,
  'get_problem_type'    => \&_get_problem_type,
  'get_product_type'    => \&_get_product_type,
  'get_request_dir'     => \&_get_request_dir,
  'get_request_value'   => \&_get_request_value,
  'get_rpt_directory'   => \&_get_rpt_directory,
  'set_domain_request'  => \&_set_domain_request,
  'set_node_request'    => \&_set_node_request,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = IRDA::CV0100::Input-E<gt>load($tbl)>

This method loads the mechanism definition in the mechanism table.

=cut

sub load
{ my ($cls, $tbl) = @_;

  foreach my $nam (keys(%tb_run))
  { $tbl->{$nam} = $tb_run{$nam};
  }
}

=head1 MECHANISM DEFINITIONS

=head2 apply_request_value - Get a request parameter value for collect phase

This discovery mechanism retrieves the value of the specified request
parameter for modifying a setting at collection time.

=cut

sub _apply_request_value
{ my ($slf, $nam) = @_;

  $slf->{'edt'}->{$nam} = $slf->get_request_value($nam);
}

=head2 get_env - Get environment variable value

This discovery mechanism retrieves the value of the specified environment
variable.

=cut

sub _get_env
{ my ($slf, $nam) = @_;

  $slf->{'agt'}->set_temp_setting($nam, exists($ENV{$nam}) ? $ENV{$nam} : '');
}


=head2 get_merge_period - Get the merge period

This discovery mechanism determines the merge period from the incident creation
time.

It defines the C<LOG_MERGE_BEGIN>, C<LOG_MERGE_END>, C<LOG_MERGE_SET>, and
C<LOG_RUN_MERGE> settings accordingly.

=cut

sub _get_merge_period
{ my ($slf, $nam) = @_;
  my ($agt, $beg, $dat, $end, @tbl);

  $agt = $slf->{'agt'};
  return '' unless $dat = $slf->get_request_value('INCIDENT_CREATION_TIME')
    && $dat =~ m/^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})/;
  @tbl = ($6, $5, $4, $3, $2 - 1, $1 - 1900, 0, 0, -1);

  # Derive the time stamps
  eval {
    require POSIX;
    &POSIX::tzset();
    $beg = $end = &POSIX::mktime(@tbl);
    $beg -= 3600 * $agt->get_setting('hours_before_incident', 1);
    $end += 3600 * $agt->get_setting('hours_after_incident', 0.5);
    $beg = &POSIX::strftime('%d-%b-%Y_%H:%M:%S', localtime($beg));
    $end = &POSIX::strftime('%d-%b-%Y_%H:%M:%S', localtime($end));
  };
  die "Time stamp generation error\n$@\n" if $@;
  $agt->set_temp_setting('LOG_MERGE_BEGIN', $beg);
  $agt->set_temp_setting('LOG_MERGE_END',   $end);
  $agt->set_temp_setting('LOG_MERGE_SET',   'adr');
  $agt->set_temp_setting('LOG_RUN_MERGE',   1);
}

=head2 get_problem_type - Get the problem_type rule

This discovery mechanism retrieves the rule corresponding to the problem type.

It sets the C<PROBLEM_CLASS> setting. For non-manual C<ofm> collections, it
derives the product from the first word of the problem key using the 
C<OFM_PRODUCT> map and performs extra discovery based on its corresponding
value of the C<OFM_REQUIREMENT> hash.

When it does not find required information, all C<ofm> collections are falling
back to the C<ofm.wls> problem type.

=cut

sub _get_problem_type
{ my ($slf, $nam) = @_;
  my ($agt, $cls, $key, $typ);

  $agt = $slf->{'agt'};
  $key = $slf->get_request_value('PROBLEM_KEY','');
  $typ = $agt->get_setting('PRODUCT_TYPE', '');
  if ($key =~ /^\s*(\w+)\s+(\w+)/)
  { $cls = ($slf->get_request_value('INCIDENT_TYPE','') eq 'manual')
             ? 'manual_'.$1 :
           ($typ eq 'ofm')
             ? _discover_product($slf, $1) :
           lc($1.'_'.$2);
    $agt->set_temp_setting('PROBLEM_CLASS', $cls);
  }
  else
  { $cls = '';
  }
  $agt->set_temp_setting($nam, $slf->map_value($nam, join('.', $typ, $cls)));
}


=head2 get_product_type - Get the product_type rule

This discovery mechanism retrieves the rule corresponding to the product type.

For C<ofm> collections, it sets the C<WLS_DOMAIN_ROOT>, C<ADR_DOMAIN>, and
C<ADR_SERVER> settings.

=cut

sub _get_product_type
{ my ($slf, $nam) = @_;
  my ($agt, $dir, $dom, $srv, $sub, $typ, @dir);

  if ($dir = $slf->get_request_value('ADR_HOME'))
  { $agt = $slf->{'agt'};
    $dir = RDA::Object::Rda->clean_path($dir, 1);
    @dir = RDA::Object::Rda->split_dir($dir);
    return '' if scalar(@dir) < 4;
    ($typ, $sub) = splice(@dir, -3);
    if ($typ eq 'ofm')
    { return '' if scalar(@dir) < 6;
      ($dom, undef, $srv) = splice(@dir, -5);
      $agt->set_temp_setting('WLS_DOMAIN_ROOT',
        RDA::Object::Rda->cat_dir(@dir));
      $agt->set_temp_setting('ADR_DOMAIN',
        RDA::Object::Rda->cat_dir(@dir, $dom));
      $agt->set_temp_setting('ADR_SERVER', $srv);
      if ($sub eq 'fusionapps')
      { splice(@dir, 3);
        return '' unless @dir;
        $typ = 'ofa';
        $agt->set_temp_setting('OFA_ROOT', RDA::Object::Rda->cat_dir(@dir));
      }
    }
    $agt->set_temp_setting($nam, $slf->map_value($nam, $typ));
  }
}

=head2 get_request_dir - Get a directory from the request file

This discovery mechanism retrieves the path of the specified request
directory parameter.

=cut

sub _get_request_dir
{ my ($slf, $nam) = @_;
  my ($val);

  $slf->{'agt'}->set_temp_setting($nam,
    defined($val = $slf->get_request_value($nam))
    ? RDA::Object::Rda->cat_dir($val)
    : '');
}

=head2 get_request_value - Get a request parameter value

This discovery mechanism retrieves the value of the specified request
parameter.

=cut

sub _get_request_value
{ my ($slf, $nam) = @_;

  $slf->{'agt'}->set_temp_setting($nam, $slf->get_request_value($nam, ''));
}

=head2 get_rpt_directory - Retrieve the output directory

This discovery mechanism retrieves the output directory.

=cut

sub _get_rpt_directory
{ my ($slf, $nam) = @_;

  $slf->{'agt'}->set_temp_setting($nam, $slf->get_request_value('OUTPUT_DIR')
    || dirname($slf->get_request_value('REQUEST_FILE')));
}

=head2 set_domain_request - Define an Oracle WebLogic Server domain request

This discovery mechanism defines an Oracle WebLogic Server domain request.

=cut

sub _set_domain_request
{ my ($slf, $nam) = @_;
  my ($agt);

  $agt = $slf->{'agt'};
  $agt->set_temp_setting($nam.'_REQ_DOMAIN',  $agt->get_setting('ADR_DOMAIN'));
  $agt->set_temp_setting($nam.'_WLS_SERVERS', $agt->get_setting('ADR_SERVER'));
}

=head2 set_node_request - Define an Oracle Fusion Applications node request

This discovery mechanism defines an Oracle Fusion Applications node request.

=cut

sub _set_node_request
{ my ($slf, $nam) = @_;
  my ($agt);

  $agt = $slf->{'agt'};
  $agt->set_temp_setting($nam.'_WLS_NODE',
    $agt->get_setting('WLS_DOMAIN_ROOT'));
}

# ---- Internal functions -----------------------------------------------------

# Discover the product homes
sub _discover_homes
{ my ($agt, $ctl, $req) = @_;
  my ($dir, $dom, $key, %hom);

  # Get the domain target
  $dom = $ctl->add_target('DOM_ADR',
    { DOMAIN_HOME     => $agt->get_setting('ADR_DOMAIN'),
      MISSING_COMMON  => 1,
      MISSING_HOME    => 1,
      MISSING_WL_HOME => 1,
    });

  # Get the required product homes
  foreach my $itm (split(/,/, $req))
  { if ($itm =~ m/^(\w+):(\w+)$/)
    { $key = $1;
      return 1
        unless defined($dir = $dom->get_product($2, 'hom')) && -d $dir;
      $hom{$1} = $dir;
    }
  }

  # Set the required settings
  foreach my $key (keys(%hom))
  { $agt->set_temp_setting($key, $hom{$key});
  }
  
  # Indicate a successful completion
  0;
}

# Discover product settings
sub _discover_product
{ my ($slf, $prb) = @_;
  my ($agt, $ctl, $prd, $req, @dir);

  # Determine the product name
  $prd = $slf->map_value('OFM_PRODUCT', $prb);

  # Analyze product requirements
  return 'wls' unless defined($prd)
    && defined($req = $slf->get_value('OFM_REQUIREMENT', $prd));
  $agt = $slf->{'agt'};
  $ctl = $agt->get_target;
  $prd = 'wls' if _discover_homes($agt, $ctl, $req);
  $ctl->init;

  # Return the collection
  $prd;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Domain|RDA::Object::Domain>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Target|RDA::Object::Target>,
L<IRDA::Prepare|IRDA::Prepare>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
