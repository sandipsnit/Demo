# Module.pm: Class Used for Objects to Set up Modules

package RDA::Module;

# $Id: Module.pm,v 2.36 2012/06/11 10:16:19 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Module.pm,v 2.36 2012/06/11 10:16:19 mschenke Exp $
#
# Change History
# 20120611  MSC  Allow to control parallel execution.

=head1 NAME

RDA::Module - Class Used for Objects to Set up Modules

=head1 SYNOPSIS

require RDA::Module;

=head1 DESCRIPTION

The objects of the C<RDA::Module> class are used to manage module setup.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Block;
  use RDA::Object::Rda;
  use RDA::Setting;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.36 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $RE_MOD  = qr/^S\d{3}([A-Z]\w*)$/i;
my $REQUEST = 'TRACE/REQUEST/';
my $SETUP   = 'TRACE/SETUP/';

my $RPT_NXT = ".N1\n";
my $RPT_SUB = "  \001  ";
my $RPT_TXT = "  ";
my $RPT_XRF = "  ";

# Define the global private variables
my %tb_aux = (
  MODULE => [-1, 'oid'],
  NEXT   => [ 1, '_nxt'],
  PREFIX => [-1, 'pre'],
  );
my %tb_def = (
  '_frk' => ['_FORK',        'T', 'Parallel execution indicator'],
  '-mrc' => ['_MRC',         'B', 'Multi-run collection indicator'],
  '_rpt' => ['_SETTINGS',    'T', 'Settings to include in the setting report'],
  '-spc' => ['_SPACE_QUOTA', 'T', 'Report space limit'],
  '-tim' => ['_TIME_QUOTA',  'T', 'Execution time limit'],
  '_tmp' => ['_TEMP',        'T', 'Predefined temporary settings'],
  '-trg' => ['_TRIGGER',     'T', 'Modules to trigger'],
  '_ttl' => ['_TITLE',       'T', 'Title for a setting report section'],
  );
my %tb_mod = (
  'col' => ['_col', \&_load_val],
  'dsc' => ['_dsc', \&_load_val],
  'env' => ['_env', \&_load_list],
  'exe' => ['_exe', \&_load_word],
  'fam' => ['_fam', \&_load_list],
  'frk' => ['_frk', \&_load_val],
  'ini' => ['_ini', \&_load_val],
  'inv' => ['_inv', \&_load_list],
  'lim' => ['_lim', \&_load_val],
  'man' => ['_man', \&_load_text],
  'mrc' => ['_mrc', \&_load_mrc],
  'req' => ['_req', \&_load_list],
  'rpt' => ['_rpt', \&_load_val],
  'tmp' => ['_tmp', \&_load_val],
  'trg' => ['_trg', \&_load_list],
  'ttl' => ['_ttl', \&_load_val],
  'var' => ['_var', \&_load_list],
  );
my %tb_var = (
  'add' => ['_add', \&_load_val],
  'aft' => ['_aft', \&_load_text],
  'alt' => ['_alt', \&_load_list],
  'ask' => ['_ask', \&_load_val],
  'bef' => ['_bef', \&_load_text],
  'cas' => ['_cas', \&_load_val],
  'clr' => ['_clr', \&_load_val],
  'col' => ['_col', \&_load_val],
  'ctx' => ['_ctx', \&_load_val],
  'dft' => ['_dft', \&_load_val],
  'dsc' => ['_dsc', \&_load_val],
  'dup' => ['_dup', \&_load_val],
  'end' => ['_end', \&_load_val],
  'err' => ['_err', \&_load_text],
  'exe' => ['_exe', \&_load_word],
  'fam' => ['_fam', \&_load_list],
  'hlp' => ['_hlp', \&_load_text],
  'inp' => ['_inp', \&_load_val],
  'itm' => ['_itm', \&_load_val],
  'lvl' => ['_lvl', \&_load_val],
  'man' => ['_man', \&_load_text],
  'mnu' => ['_mnu', \&_load_val],
  'nam' => ['_nam', \&_load_name],
  'one' => ['_one', \&_load_val],
  'opt' => ['_opt', \&_load_val],
  'pck' => ['_pck', \&_load_val],
  'ref' => ['_ref', \&_load_val],
  'rsp' => ['_rsp', \&_load_val],
  'sep' => ['_sep', \&_load_val],
  'val' => ['_val', \&_load_valid],
  'typ' => ['_typ', \&_load_type],
  'var' => ['_var', \&_load_list],
  'vis' => ['_vis', \&_load_val],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Module-E<gt>new($name,$dir)>

The object constructor. It takes the module name and  module directory as
arguments.

C<RDA::Module> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'cfg' > > Reference to the RDA software configuration

=item S<    B<'cnt' > > Module counters

=item S<    B<'dir' > > Module directory

=item S<    B<'dpt' > > Current setup depth

=item S<    B<'dsp' > > Reference to the display object

=item S<    B<'mrc' > > Reference to the multi-run collection control object

=item S<    B<'oid' > > Object identifier

=item S<    B<'pre' > > Module prefix

=item S<    B<'prv' > > Previous settings

=item S<    B<'reg' > > Reference to an object for accessing registry

=item S<    B<'rpt' > > Reference to the report control object

=item S<    B<'trc' > > Trace level

=item S<    B<'ver' > > Specification version number

=item S<    B<'xml' > > XML file hash

=item S<    B<'wdt' > > Screen width

=item S<    B<'yes' > > Dialog suppression indicator

=item S<    B<'_col'> > Indicates if the data collection should be done

=item S<    B<'_cur'> > Current setup object reference

=item S<    B<'_def'> > Setting definition hash

=item S<    B<'_dsc'> > Description string

=item S<    B<'_err'> > Number of load errors

=item S<    B<'_env'> > List of environment variables to import

=item S<    B<'_evt'> > Pending events stack

=item S<    B<'_exe'> > Associated package

=item S<    B<'_fam'> > Optional list of operating system families

=item S<    B<'_ini'> > Indicates if it will require library reload

=item S<    B<'_inv'> > Alternative setting array for auto discovery context

=item S<    B<'_lim'> > Indicates if execution limits are allowed

=item S<    B<'_lin'> > Line number

=item S<    B<'_man'> > Module manual text

=item S<    B<'_mrc'> > Multi-run collection condition

=item S<    B<'_nxt'> > List of next settings

=item S<    B<'_req'> > List of required modules

=item S<    B<'_rpt'> > List of settings to include in setting report

=item S<    B<'_set'> > Setting object list

=item S<    B<'_tbl'> > Current attribute table

=item S<    B<'_tmp'> > List of predefined temporary settings

=item S<    B<'_trg'> > Trigger rule

=item S<    B<'_ttl'> > Title for a setting report section

=item S<    B<'_var'> > Setting array

=item S<    B<'-mrc'> > Multi-run collection indicator

=item S<    B<'-spc'> > Space limit

=item S<    B<'-tim'> > Time limit

=item S<    B<'-trg'> > List of the modules to trigger

=back

Internal keys are prefixed by an underscore or a dash.

=cut

sub new
{ my ($cls, $nam, $dir) = @_;
  my ($pre);

  # Create the module definition object and return its reference
  $pre = ($nam =~ $RE_MOD) ? $1 : $nam;
  bless {
    dir  => $dir,
    dpt  => 0,
    oid  => $nam,
    pre  => $pre,
    prv  => {},
    ver  => '?',
    xml  => {},
    _col => 1,
    _dsc => $nam,
    _env => [],
    _ini => 0,
    _lim => 1,
    _req => [],
    _var => [],
    _ver => 0,
     }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>display($agt[,$all])>

This method extracts the setup questions of a module. When the second argument
is set, it disables family restrictions.

=cut

sub display
{ my ($slf, $agt, $all, $flg) = @_;
  my ($buf);

  # Display the module section
  $buf = _dsp_title('NAME')
    ._dsp_text($RPT_TXT, '``'.$slf->{'oid'}.'`` - '.$slf->{'_dsc'}, 1);
  $buf .= _dsp_title('MODULE SETUP')
    ._dsp_block($RPT_TXT, $slf->{'_man'}, 1)
    if exists($slf->{'_man'});

  # Display the setting section
  if (exists($slf->{'_set'}))
  { my ($cnt, $fam, $lvl, @rec);

    $cnt = 0;
    $fam = $slf->{'cfg'}->get_family;
    $lvl = $agt->get_setting('RDA_LEVEL');
    foreach my $obj (@{$slf->{'_set'}})
    { # Determine if the setting contributes to the report
      next unless $all || $obj->is_valid($fam);
      @rec = $obj->get_detail;
      next unless @rec && $lvl >= $rec[1];

      # Provide the setting details
      $buf .= _dsp_title('SETTING DESCRIPTION') unless $cnt++;
      $buf .= _dsp_text($RPT_TXT, '``'.$rec[0].'``');
      $buf .= _dsp_text($RPT_SUB, $rec[2]) if defined($rec[2]);
      $buf .= _dsp_text($RPT_SUB, $rec[3]) if defined($rec[3]);
      $buf .= $RPT_NXT;
    }
  }

  # Display the dependencies
  if (exists($slf->{'_req'}))
  { my @req = map {(m/^(?:\*\?\!?\w+\:|[\*\+\-]+)?(.*)$/)} @{$slf->{'_req'}};
    $buf .= _dsp_title('DEPENDENCIES')._dsp_text($RPT_TXT,
      join(', ', map {"!!setup:$_!$_!!"} sort @req), 1)
      if @req;
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

=head2 S<$h-E<gt>get_access>

This method returns the reference to the access control object.

=cut

sub get_access
{ my ($slf) = @_;

  $slf->{'agt'}->get_access;
}

=head2 S<$h-E<gt>get_info($key[,$default])>

This method returns the value of the given object key. If the object key does
not exist, then it returns the default value.

=cut

sub get_info
{ my ($slf, $key, $val) = @_;

  exists($slf->{$key}) ? $slf->{$key} : $val;
}

=head2 S<$h-E<gt>get_output>

This method returns the reference to the current report control object.

=cut

sub get_output
{ my ($slf) = @_;

  exists($slf->{'rpt'}) ? $slf->{'rpt'} : $slf->{'agt'}->get_output(1);
}

=head2 S<$h-E<gt>get_var($name[,$default])>

This method resolves a variable.

=cut

sub get_var
{ my ($slf, $nam, $val) = @_;

  if ($nam =~ s/^ENV\.//)
  { $val = $ENV{$nam} if exists($ENV{$nam});
  }
  elsif ($nam =~ s/^AS\.//)
  { $val =
      ($nam eq 'BAT')     ? RDA::Object::Rda->as_bat($val) :
      ($nam eq 'BATCH')   ? RDA::Object::Rda->as_bat($val, 1) :
      ($nam eq 'CMD')     ? RDA::Object::Rda->as_cmd($val) :
      ($nam eq 'COMMAND') ? RDA::Object::Rda->as_cmd($val, 1) :
      ($nam eq 'EXE')     ? RDA::Object::Rda->as_exe($val) :
                            $val.'.'.lc($nam);
  }
  elsif ($nam =~ s/^CFG\.//)
  { $val = $slf->{'agt'}->get_setting($nam, $val);
  }
  elsif ($nam =~ s/^CNT\.//)
  { $val = $slf->{'cnt'}->{lc($nam)} || 0;
  }
  elsif ($nam =~ s/^CUR\.//)
  { $val =
      ($nam eq 'DEPTH')     ? $slf->{'dpt'} :
      ($nam eq 'DIRECTORY') ? $slf->{'dir'} :                    # (
      ($nam eq 'EGID')      ? (split(/ /, $)))[0] :
      ($nam eq 'EUID')      ? $> :
      ($nam eq 'GID')       ? (split(/ /, $())[0] :              # )
      ($nam eq 'GROUP')     ? $slf->get_output->get_group :
      ($nam eq 'MODULE')    ? $slf->{'oid'} :
      ($nam eq 'PERL')      ? $slf->{'agt'}->get_info('prl') :
      ($nam eq 'PREFIX')    ? $slf->get_output->get_prefix :
      ($nam eq 'UID')       ? $< :
                              $val;
  }
  elsif ($nam =~ s/^GRP\.//)
  { $val = $slf->{'cfg'}->get_group($nam);
  }
  elsif ($nam =~ s/^INC\.//)
  { $val = ++$slf->{'cnt'}->{lc($nam)};
  }
  elsif ($nam =~ s/^OS\.//)
  { $val = uc($slf->{'cfg'}->get_os) eq uc($nam);
  }
  elsif ($nam =~ s/^OUT\.//)
  { $val = $slf->get_output->get_path($nam);
  }
  elsif ($nam =~ s/^RDA\.//)
  { $val = $slf->{'cfg'}->get_value($nam, $val);
  }
  elsif (length($nam))
  { $val = $slf->{'agt'}->get_setting($nam, $val);
  }
  $val;
}

=head2 S<$h-E<gt>get_version>

This method returns the version number of the specifications.

=cut

sub get_version
{ shift->{'ver'};
}

=head2 S<$h-E<gt>is_active>

This method indicates whether the module is active. If it is not active, the
module can be skipped during data collection.

=cut

sub is_active
{ shift->{'_col'};
}

=head2 S<$h-E<gt>is_valid($family)>

This method indicates whether the module is applicable for the specified
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

=head2 S<$h-E<gt>load($agt)>

This method loads the module definition. It returns 1 if a setup is required.
Otherwise, it returns 0.

=cut

sub load
{ my ($slf, $agt) = @_;
  my ($cmd, $lin, $nam, $obj, $pth, $tbl);

  # Initialization
  $slf->{'agt'} = $agt;
  $slf->{'cfg'} = $agt->get_config;
  $slf->{'dsp'} = $agt->get_display;
  $slf->{'yes'} = $agt->get_info('yes');

  $slf->{'_err'} = 0;
  $slf->{'_lin'} = 0;

  # Get the screen width without requiring a configuration object
  $slf->{'wdt'} = RDA::Object::Rda::get_columns($slf->{'cfg'});

  # Check if there is a setup associate to the module
  $pth = RDA::Object::Rda->cat_file($slf->{'dir'}, $slf->{'oid'}.'.cfg');
  return 0 unless -e $pth;

  # Load the module setup file
  open(IN, "<$pth")
    or die "RDA-00103: Cannot open the setup specification file '$pth':\n $!\n";
  $lin = '';
  $obj = $slf;
  $tbl = \%tb_mod;
  while (<IN>)
  { # Trim leading spaces
    s/^\s+//;
    s/[\r\n]+$//;
    $lin .= $_;

    # Join continuation line
    $slf->{'_lin'}++;
    next if $lin =~ s/\\$//;
    $lin =~ s/\s+$//;

    # Parse the line
    eval {
      if ($lin =~ s/^(\w+)\s*=\s*//)
      { $nam = lc($1);
        die "RDA-00104: Invalid setup attribute keyword '$nam'\n"
          unless exists($tbl->{$nam});
        $cmd = $tbl->{$nam};
        &{$cmd->[1]}($obj, $cmd->[0], \$lin);
        die "RDA-00105: Invalid setup attribute value\n"
          unless $lin =~ m/^\s*(#.*)?$/;
      }
      elsif ($lin =~ s/^\[(\w+)\]$//)
      { $nam = $1;
        $slf->{'_def'}->{$nam} = $obj = RDA::Setting->new($nam);
        $tbl = \%tb_var;
        push(@{$slf->{'_set'}}, $obj);
      }
      elsif ($lin !~ m/^(#.*)?$/)
      { die "RDA-00106: Unexpected setup specification\n";
      }
      elsif ($lin =~ m/\$[Ii]d\:\s+\S+\s+(\d+)(\.(\d+))?\s/)
      { $slf->{'ver'} = sprintf('%d.%02d', $1, $3 || 0);
      }
    };

    # Report an error
    if ($@)
    { my $msg = $@;

      $slf->{'_err'}++;
      $msg =~ s/\n$//;
      $msg .= ' in '.$slf->{'oid'}.' near line '.$slf->{'_lin'}
        if $slf->{'_lin'};
      print "$msg\n";
    }

    # Prepare the next line
    $lin = '';
  }
  close(IN);

  # Terminate if errors are encountered
  die "RDA-00107: Error(s) in ".$slf->{'oid'}." setup\n" if $slf->{'_err'};

  # Indicate that a setup can be performed
  1;
}

sub _load_list
{ my ($slf, $key, $buf) = @_;

  $slf->{$key} = [split(/\s*,\s*/, $$buf)];
  $$buf = '';
}

sub _load_mrc
{ my ($slf, $key, $buf) = @_;
  my $str;

  $slf->{'mrc'} = $slf->{'agt'}->get_mrc;
  if ($$buf =~ s/^'([^']*)'// || $$buf =~ s/^"([^"]*)"//)
  { $str = $1;
    $str =~ s/&\#34;/"/g;
    $str =~ s/&\#39;/'/g;
    $slf->{$key} = $str;
  }
  else
  { $slf->{$key} = $$buf;
    $$buf = '';
  }
}

sub _load_name
{ my ($slf, $key, $buf) = @_;

  die "RDA-00108: Invalid name\n" unless $$buf =~
    s/^((\w|\$\{(\w+\.)*\w+(:\w+)?\})+|\-(\w|\$\{(\w+\.)*\w+(:\w+)?\})*)//;
  $slf->{$key} = $1;
}

sub _load_valid
{ my ($slf, $key, $buf) = @_;

  die "RDA-00117: Invalid validation rule\n"
    unless $$buf =~ s/^(E\d*|F|W)//;
  $slf->{$key} = $1;
}

sub _load_text
{ my ($slf, $key, $buf) = @_;
  my $str;

  if ($$buf =~ s/^'([^']*)'// || $$buf =~ s/^"([^"]*)"//)
  { $str = $1;
    $str =~ s/&\#10;/\n/g;
    $str =~ s/&\#34;/"/g;
    $str =~ s/&\#39;/'/g;
    $str =~ s/\\n/\n/g;
    $slf->{$key} = $str;
  }
  else
  { $slf->{$key} = $$buf;
    $$buf = '';
  }
}

sub _load_type
{ my ($slf, $key, $buf) = @_;

  die "RDA-00109: Invalid type\n" unless $$buf =~ s/^([BCDEFILMNPST])//;
  $slf->{$key} = $1;
}

sub _load_val
{ my ($slf, $key, $buf) = @_;
  my $str;

  if ($$buf =~ s/^'([^']*)'// || $$buf =~ s/^"([^"]*)"//)
  { $str = $1;
    $str =~ s/&\#34;/"/g;
    $str =~ s/&\#39;/'/g;
    $slf->{$key} = $str;
  }
  else
  { $slf->{$key} = $$buf;
    $$buf = '';
  }
}

sub _load_word
{ my ($slf, $key, $buf) = @_;

  die "RDA-00119: Invalid word\n" unless $$buf =~ s/^(\w+)//;
  $slf->{$key} = $1;
}


=head2 S<$h-E<gt>log($str)>

This method adds an event to the event stack.

=cut

sub log
{ my ($slf, $str) = @_;

  $slf->{'_evt'} = [] unless exists($slf->{'_evt'});
  push(@{$slf->{'_evt'}}, $str);
}

=head2 S<$h-E<gt>request($level[,$trace])>

This method requests additional settings. The module context is unchanged and
it preserves temporary settings. No requisites are considered.

=cut

sub request
{ my ($slf, $lvl, $trc) = @_;
  my ($agt, $blk, $fam, $flg, $nam, $pre, $ptr, $var, @tbl);

  # Check if the setup is relevant for the current OS family
  return unless $slf->is_valid($fam = $slf->{'cfg'}->get_family);

  # Reset module counters
  $slf->{'cnt'} = {};
  $slf->{'trc'} = $trc;

  # Load the associated logic
  $agt = $slf->{'agt'};
  $flg = $slf->{'yes'};
  $nam = $slf->{'oid'};
  if (exists($slf->{'_exe'}))
  { eval {
      $blk = RDA::Block->new($slf->{'_exe'}, $slf->{'dir'});
      $blk->load($slf->{'agt'});
      };
    die "$@\nRDA-00130: Cannot load the associated logic\n" if $@;
    $blk->set_info('aux', $slf);
    $agt->get_macros($blk->get_lib);

    # Execute the associated logic
    $slf->{'_cur'} = $slf;
    $slf->{'_tbl'} = \%tb_mod;
    $blk->eval($blk, 0, $REQUEST, $trc, 'init');
    $slf->{'_tbl'} = \%tb_var;
  }

  # Collect the variables
  $slf->{'_nxt'} = [@{$slf->{'_var'}}];
  while (defined($var = shift(@{$slf->{'_nxt'}})))
  { $pre = "REQUEST/$nam/$var:" if $trc;

    # Ignore variables without definitions
    unless (exists($slf->{'_def'}->{$var}))
    { print "$pre definition missing\n" if $trc;
      next;
    }

    # Check if the definition is relevant for the current OS family
    $ptr = $slf->{'_def'}->{$var};
    unless ($ptr->is_valid($fam))
    { print "$pre skipped on this platform\n" if $trc;
      next;
    }

    # Execute the associated logic
    if ($blk && exists($ptr->{'_exe'}))
    { $slf->{'_cur'} = $ptr;
      $blk->eval($blk, 0, $REQUEST, $trc, $ptr->{'_exe'});
    }

    # Perform the variable setting
    $var = $ptr->setup($slf, $lvl, $slf->{'_nxt'}, $pre, $flg);
    delete($slf->{'prv'}->{$var}) if defined($var);
  }
  $slf->{'xml'} = {};
}

=head2 S<$h-E<gt>set_info($key[,$value])>

This method assigns a new value to the given object hey when the value is
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

=head2 S<$h-E<gt>setup($level[,$trace[,$save[,$selected]]])>

This method collects the setup information for the module.

=cut

sub setup
{ my ($slf, $lvl, $trc, $sav, $sel) = @_;
  my ($agt, $bkp, $blk, $dsp, $fam, $flg, $nam, $pre, $ptr, $ret, $sep, $str,
      $val, $var, %bkp, %cur, @req, @tbl);

  # Check if the setup is relevant for the current OS family
  $agt = $slf->{'agt'};
  $dsp = $slf->{'dsp'};
  $nam = $slf->{'oid'};
  $flg = $slf->{'yes'};
  unless ($slf->is_valid($fam = $slf->{'cfg'}->get_family))
  { $agt->set_collection($nam, 0);
    print "SETUP/$nam: disabled\n" if $trc;
    return ();
  }
  $slf->{'trc'} = $trc;

  # Clear a previous occurence of the module setup
  $slf->{'prv'} = {map {$_ => 1} $agt->del_module($nam)};

  # Already define the module to prevent loop in pre-requisites
  $agt->set_current($nam, $slf->{'_dsc'});

  # Check the pre-requisites
  foreach my $nam (@{$slf->{'_req'}})
  { if ($nam =~ m/^\*([\+\-]?(.*))$/)
    { push(@req, $1) unless $agt->is_described($2);
    }
    else
    { $agt->setup($nam, $trc, $sav, defined($sel) ? 0 : $sel)
        unless $agt->is_described($nam);
    }
  }
  $agt->set_current($nam);

  # Load the associated logic
  if (exists($slf->{'_exe'}))
  { eval {
      $blk = RDA::Block->new($slf->{'_exe'}, $slf->{'dir'});
      $blk->load($agt);
      };
    die "$@\nRDA-00130: Cannot load the associated logic\n" if $@;
    $blk->set_info('aux', $slf);
    $agt->get_macros($blk->get_lib);
  }

  # Display the start of the definition
  unless ($flg)
  { $sep = ('-' x ($slf->{'wdt'} + 1))."\n";
    print $sep;
    $dsp->dsp_string('', join(': ', $nam, $slf->{'_dsc'}), 1);
    print $sep;
  }

  # Import environment variables as temporary settings
  foreach $var (@{$slf->{'_env'}})
  { next unless exists($ENV{$var});
    unless ($agt->exists_setting($var))
    { $agt->set_temp_setting($var, $ENV{$var});
      print "SETUP/$nam: $var='$ENV{$var}'\n" if $trc;
    }
  }

  # Collect the variables allowing interruptions
  for (;;)
  { # Backup the current status
    $bkp = $agt->backup_settings;
    %bkp = %{$slf->{'prv'}};
    $agt->set_temp_setting('SELECTED_MODULE', $sel) if defined($sel);

    # Reset module counters
    $slf->{'cnt'} = {};

    # Execute the associated logic
    if ($blk)
    { $slf->{'_cur'} = $slf;
      $slf->{'_tbl'} = \%tb_mod;
      $blk->eval($blk, 0, $SETUP, $trc, 'init');
      $slf->{'_tbl'} = \%tb_var;
    }

    # Collect the variables
    delete($slf->{'_evt'});
    eval {
      local $SIG{'INT'} = sub { die "Interrupted\n"; };

      $slf->{'_nxt'} = [@{$slf->{(exists($slf->{'_inv'}) && $agt->get_discover)
        ? '_inv'
        : '_var'}}];
      while (defined($var = shift(@{$slf->{'_nxt'}})))
      { $pre = "SETUP/$nam/$var:" if $trc;

        # Ignore variables without definitions
        unless (exists($slf->{'_def'}->{$var}))
        { print "$pre definition missing\n" if $trc;
          next;
        }

        # Check if the definition is relevant for the current OS family
        $ptr = $slf->{'_def'}->{$var};
        unless ($ptr->is_valid($fam))
        { print "$pre skipped on this platform\n" if $trc;
          next;
        }

        # Execute the associated logic
        if ($blk && exists($ptr->{'_exe'}))
        { $slf->{'_cur'} = $ptr;
          $blk->eval($blk, 0, $SETUP, $trc, $ptr->{'_exe'});
        }

        # Perform the variable setting
        $var = $ptr->setup($slf, $lvl, $slf->{'_nxt'}, $pre, $flg);
        delete($slf->{'prv'}->{$var}) if defined($var);
      }
    };
    $slf->{'xml'} = {};

    # Determine the next action
    last   unless $@ && $@ !~ m/^Aborted/;
    die $@ unless $@ =~ m/^Interrupted/;
    $dsp->dsp_string('', "\n\nThe setup has been interrupted\n".
      "Do you want to restart it (Y/N)?", 0);
    $str = <STDIN>;
    die "RDA-00121: RDA setup interrupted\n" unless $str =~ m/\s*y(es)?/i;
    $dsp->dsp_string('', ' ', 1);

    # Restore the initial status
    $agt->restore_settings($bkp);
    $slf->{'prv'} = {%bkp};
  }

  # Analyze the trigger specification
  if (exists($slf->{'_trg'}))
  { @tbl = ();
    foreach my $trg (@{$slf->{'_trg'}})
    { if ($trg =~ s/^\+//)
      { push(@tbl, $trg)
          unless $agt->is_disabled($nam);
      }
      elsif ($trg =~ s/^\-//)
      { push(@tbl, $trg)
          if $agt->is_disabled($nam);
      }
      elsif ($trg =~ s/^\?(\!)?(\w+)\://)
      { push(@tbl, $trg)
          if defined($1) xor $agt->get_setting($2, 0);
      }
      else
      { push(@tbl, $trg);
      }
    }
    if (@tbl)
    { $slf->{'-trg'} = join(',', @tbl);
    }
    else
    { delete($slf->{'-trg'});
    }
  }

  # Define settings for the setting report
  $slf->{'_frk'} = $slf->get_var($1, $4 || 1)
    if exists($slf->{'_frk'})
    && $slf->{'_frk'} =~ m/\$\{((\w+\.)?\w+)(:([^\}]*))?\}/;
  if (exists($slf->{'_mrc'}))
  { $slf->{'_mrc'} = $slf->get_var($1, $4)
      if $slf->{'_mrc'} =~ m/\$\{((\w+\.)?\w+)(:([^\}]*))?\}/;
    $slf->{'-mrc'} = $agt->get_setting($slf->{'oid'}.'_MRC', 0)
      if $slf->{'_mrc'};
  }
  foreach my $key (sort keys(%tb_def))
  { $ptr = $tb_def{$key};
    if (exists($slf->{$key}))
    { $var = $nam.$ptr->[0];
      $agt->set_setting($var, $slf->{$key}, $ptr->[1], $ptr->[2]);
      delete($slf->{'prv'}->{$var});
      print "SETUP/$nam/$var:".$slf->{$key}."\n" if $trc;
    }
  }

  # Check whether diagnostic data should be collected
  $slf->{'_col'} = $slf->get_var($1, $4 || 1)
    if $slf->{'_col'} =~ m/\$\{((\w+\.)?\w+)(:([^\}]*))?\}/;
  if ($slf->{'_col'})
  { $agt->set_collection($nam, 1);
    print "SETUP/$nam: enabled\n" if $trc;
    $slf->{'_lim'} = $agt->get_setting($1, $3 || 1)
      if $slf->{'_lim'} =~ m/\$\{(\w+)(:([^\}]*))?\}/;

    # Manage the execution limits
    delete($slf->{'-spc'});
    delete($slf->{'-tim'});
    if ($slf->{'_lim'})
    { if (defined($val = $agt->get_setting("$nam\_SPACE_QUOTA")))
      { $slf->{'-spc'} = $val;
        print "QUOTA/$nam: space limit = $val MiB\n" if $trc;
      }
      if (defined($val = $agt->get_setting("$nam\_TIME_QUOTA")))
      { $slf->{'-tim'} = $val;
        print "QUOTA/$nam: time limit = $val sec\n" if $trc;
      }
    }
    else
    { print "QUOTA/$nam: inactive\n" if $trc;
    }
  }
  else
  { $agt->set_collection($nam, 0);
    print "SETUP/$nam: disabled\n" if $trc;
  }

  # Check if it require library reload
  $slf->{'_ini'} = $agt->get_setting($1, $3 || 1)
    if $slf->{'_ini'} =~ m/\$\{(\w+)(:([^\}]*))?\}/;
  $agt->reload_libraries if $slf->{'_ini'};

  # Delete obsolete variables
  foreach $var (keys(%{$slf->{'prv'}}))
  { $agt->del_setting($var);
  }

  # Store the pending events
  if ($ptr = delete($slf->{'_evt'}))
  { $agt->log_force;
    foreach my $evt (@$ptr)
    { my ($typ, @det) = split(/\|/, $evt);
      $agt->log($typ, @det) if $typ && $typ =~ m/^\w{2,}$/;
    }
  }

  # Detach the associated logic
  $blk->delete if $blk;

  # Return the list of post-requisites
  @req;
}

=head2 S<$h-E<gt>xref($agent)>

This method produces a cross-reference of the setting definitions and their
references.

=cut

sub xref
{ my ($slf, $agt) = @_;
  my ($buf, $err, $obj, $typ, $xrf, @tb_mis, @tb_not, @tb_use, %tb_def);

  # Load the module
  eval {$slf->load($agt);};
  $err = $@;

  # Analyze the module
  $xrf = {};
  _xref_def($xrf, $slf, "<MODULE>", 'var', 'inv');
  _xref_ref($xrf, $slf, '_var', "<MODULE>(var)");
  _xref_ref($xrf, $slf, '_inv', "<MODULE>(inv)");
  foreach my $nam (sort keys(%{$slf->{'_def'}}))
  { $obj = $slf->{'_def'}->{$nam};
    $typ = $obj->{'_typ'};
    _xref_def($xrf, $obj, "$nam($typ)", 'var', 'alt');
    _xref_ref($xrf, $obj, '_var', "$nam(var)");
    _xref_ref($xrf, $obj, '_alt', "$nam(alt)");
    if ($typ eq 'I' && $obj->{'_dft'} =~ m/^decode:/i)
    { my ($key, $lst, @nxt, @tbl);

      (undef, undef, @tbl) = split(/:/, $obj->{'_dft'});
      while (($key, $lst) = splice(@tbl, 0, 2))
      { next unless defined $lst;
        @nxt = split(/,/, $lst);
        foreach my $arg (@nxt)
        { push(@{$xrf->{'-use'}->{$arg}}, "$nam(dec/$key)");
        }
        $xrf->{'-def'}->{"$nam(I)"}->{"dec/$key: "} = [@nxt];
      }
    }
    elsif ($typ eq 'M' && $obj->{'_add'})
    { my ($cod, $itm, $rsp, $var, @nxt, @tbl);

      @tbl = split(/\|/, $obj->{'_add'});
      while (($cod, $itm, $rsp, $var) = splice(@tbl, 0, 4))
      { next unless $var && defined($rsp)
          && length($cod) && length($itm) && length($rsp);
        @nxt = split(/,/, $var);
        foreach my $arg (@nxt)
        { push(@{$xrf->{'-use'}->{$arg}}, "$nam(add/$cod)");
        }
        $xrf->{'-def'}->{"$nam(M)"}->{"add/$cod: "} = [@nxt];
      }
    }
  }

  # Classify the setting definitions
  foreach my $nam (sort keys(%{$xrf->{'-def'}}))
  { if ($nam eq '<MODULE>' || exists($xrf->{'-use'}->{substr($nam, 0, -3)}))
    { push(@tb_use, $nam);
    }
    else
    { push(@tb_not, $nam);
    }
    $tb_def{substr($nam, 0, -3)} = 1 unless $nam eq '<MODULE>';
  }
  foreach my $nam (sort keys(%{$xrf->{'-use'}}))
  { push(@tb_mis, $nam) unless exists($tb_def{$nam});
  }

  # Display the cross-reference
  $buf = _dsp_name("Module ".$slf->{'oid'}.".cfg Cross Reference");
  $buf .= _dsp_text($RPT_XRF, "$err error(s) detected at load") if $err;
  $buf .= $RPT_NXT;
  $buf .= _xref_dsp($xrf, \@tb_use, '-def', 'Definitions Used:');
  $buf .= _xref_dsp($xrf, \@tb_not, '-def', 'Definitions Unused:');
  $buf .= _xref_dsp($xrf, \@tb_mis, '-use', 'Missing Definitions:');
  $buf .= _xref_dsp($xrf, $xrf->{'-use'}, '-use', 'References:');
  $buf;
}

# Analyse a definition
sub _xref_def
{ my ($xrf, $obj, $nam, @arg) = @_;
  my ($key, $rec);

  $xrf->{'-def'}->{$nam} = $rec = {};
  foreach my $arg (@arg)
  { $key = "_$arg";
    $rec->{"$arg: "} = $obj->{$key} if ref($obj->{$key}) && @{$obj->{$key}};
  }
}

# Display a result set
sub _xref_dsp
{ my ($xrf, $tbl, $key, $ttl) = @_;
  my ($buf, $cur, $max, $str);

  return '' unless ($cur = ref($tbl));
  $tbl = [sort keys(%$tbl)] if $cur eq 'HASH';
  return '' unless @$tbl;

  # Determine the name length
  $max = 0;
  foreach my $nam (@$tbl)
  { $max = $cur if ($cur = length($nam)) > $max;
  }

  # Display the table
  $buf = _dsp_title($ttl);
  $max += 4;
  foreach my $nam (@$tbl)
  { next unless defined($xrf->{$key}->{$nam});
    if (ref($xrf->{$key}->{$nam}) eq 'HASH')
    { $str = join("\n",
        map {"**".$_."**``".join("``, ``",@{$xrf->{$key}->{$nam}->{$_}})."``"}
        keys(%{$xrf->{$key}->{$nam}})); 
      $str = '\040' unless defined($str) && length($str);
    }
    else
    { $str = "``".join("``, ``", @{$xrf->{$key}->{$nam}})."``";
      $str =~ s/\(/``\(**/g;
      $str =~ s/\)``/**\)/g;
    }
    $buf .= _dsp_item(sprintf("%s\001%-*s  ", $RPT_XRF, $max, "``$nam``"),
      sprintf("%s\001%-*s  ", $RPT_XRF, $max - 4, ' '),
      $str);
  }
  $buf.$RPT_NXT;
}

# Determine the references
sub _xref_ref
{ my ($xrf, $obj, $key, $nam) = @_;

  if (ref($obj->{$key}))
  { foreach my $arg (@{$obj->{$key}})
    { push(@{$xrf->{'-use'}->{$arg}}, $nam);
    }
  }
}

=head1 PROPERTY INTERFACE

=head2 S<$h-E<gt>get_value($nam)>

This method returns the value of the specified attribute as a list. Depending
on the context, it considers the attribute from the module or from the current
setting.

=cut

sub get_value
{ my ($slf, $nam) = @_;
  my ($key);

  if (exists($tb_aux{$nam}))
  { return @{$slf->{$tb_aux{$nam}->[1]}} if $tb_aux{$nam}->[0] > 0;
    return $slf->{$tb_aux{$nam}->[1]};
  }
  die "RDA-00131: Invalid property '$nam'\n"
    unless exists($slf->{'_tbl'}->{$nam = lc($nam)});
  $key = $slf->{'_tbl'}->{$nam}->[0];
  return ($slf->{'_cur'}->{$key}) if exists($slf->{'_cur'}->{$key});
  ();
}

=head2 S<$h-E<gt>set_value($nam,$val)>

This method provides a new value for the specified attribute. Depending on the
context, it considers the attribute from the module or from the current setting.

=cut

sub set_value
{ my ($slf, $nam, $val) = @_;
  my ($key);

  if (exists($tb_aux{$nam}))
  { die "RDA-00131: Invalid property '$nam'\n" if $tb_aux{$nam}->[0] < 0;
    $slf->{$tb_aux{$nam}->[1]} = $val;
  }
  elsif (exists($slf->{'_tbl'}->{$nam = lc($nam)}))
  { $slf->{'_cur'}->set_info($slf->{'_tbl'}->{$nam}->[0], $val);
  }
  else
  { die "RDA-00131: Invalid property '$nam'\n";
  }
}

# --- Internal reporting routines ---------------------------------------------

sub _dsp_block
{ my ($pre, $txt, $nxt) = @_;
  my $buf = '';

  foreach my $str (split(/\\n|\n/, $txt))
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

sub _dsp_item
{ my ($pre, $oth, $txt, $nxt) = @_;

  $txt =~ s/\n{2,}/\n\\040\n/g;
  $txt =~ s/(\\n|\n)/\n\n.I '$oth'\n/g;
  ".I '$pre'\n$txt\n\n".($nxt ? ".N $nxt\n" : "");
}

sub _dsp_name
{ my ($ttl) = @_;

  ".R '$ttl'\n"
}

sub _dsp_text
{ my ($pre, $txt, $nxt) = @_;

  $txt =~ s/\n{2,}/\n\\040\n/g;
  $txt =~ s/(\\n|\n)/\n\n.I '$pre'\n/g;
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
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
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
