# Output.pm: Class Used for Reporting Control

package RDA::Object::Output;

# $Id: Output.pm,v 2.26 2012/04/25 06:50:13 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Output.pm,v 2.26 2012/04/25 06:50:13 mschenke Exp $
#
# Change History
# 20120422  MSC  Rename Language in Inline.

=head1 NAME

RDA::Object::Output - Class Used for Reporting Control

=head1 SYNOPSIS

require RDA::Object::Output;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Output> class are used for reporting
control. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Copy;
  use IO::File;
  use RDA::Block qw($CONT $SPC_REF $SPC_VAL);
  use RDA::Object;
  use RDA::Object::Pipe;
  use RDA::Object::Rda qw($CREATE $DIR_PERMS $FIL_PERMS);
  use RDA::Object::Report;
  use RDA::Object::Toc;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @DELETE @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.26 $ =~ /(\d+)\.(\d+)/);
@DELETE  = qw(flt rpt);
@DUMP    = (
  hsh => {
    'RDA::Handle::Filter' => 1,
    },
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'addMetaDir'  => ['$[OUT]', 'add_dir'],
    'addMetaFile' => ['$[OUT]', 'add_file'],
    'addMetaStat' => ['$[OUT]', 'add_stat'],
    'enableIndex' => ['$[OUT]', 'enable_index'],
    'findShares'  => ['$[OUT]', 'find_shares'],
    'getLink'     => ['$[OUT]', 'get_link'],
    'getName'     => ['$[OUT]', 'get_name'],
    'getPath'     => ['$[OUT]', 'get_path'],
    'getShare'    => ['$[OUT]', 'get_share'],
    'getSub'      => ['$[OUT]', 'get_sub'],
    'isFiltered'  => ['$[OUT]', 'is_filtered'],
    'isRendered'  => ['$[OUT]', 'is_rendered'],
    'purge'       => ['$[OUT]', 'purge'],
    'setAbbr'     => ['$[OUT]', 'set_abbr'],
    'setMeta'     => ['$[OUT]', 'set_meta'],
    'setPrefix'   => ['$[OUT]', 'set_prefix'],
    'setShare'    => ['$[OUT]', 'set_share'],
    'testOutput'  => ['$[OUT]', 'test'],
    },
  beg => \&_begin_control,
  cmd => {
    'data'    => [\&_exe_report,  \&_get_data,   0, 0],
    'output'  => [\&_exe_report,  \&_get_output, 0, 0],
    'report'  => [\&_exe_report,  \&_get_report, 0, 0],
    'resume'  => [\&_exe_resume,  \&_get_name,   0, 0],
    'share'   => [\&_exe_share,   \&_get_list,   0, 0],
    'suspend' => [\&_exe_suspend, \&_get_name,   0, 0],
    },
  end => \&_end_control,
  flg => 1,
  glb => ['$[OUT]'],
  inc => [qw(RDA::Object)],
  met => {
    'add_dir'      => {ret => 0},
    'add_file'     => {ret => 0},
    'add_home'     => {ret => 0},
    'add_report'   => {ret => 0},
    'add_stat'     => {ret => 0},
    'add_temp'     => {ret => 0},
    'check_free'   => {ret => 0},
    'check_space'  => {ret => 0},
    'decr_free'    => {ret => 0},
    'enable_index' => {ret => 0},
    'end_report'   => {ret => 0},
    'end_temp'     => {ret => 0},
    'filter'       => {ret => 0},
    'find_shares'  => {ret => 1},
    'get_current'  => {ret => 0},
    'get_group'    => {ret => 0},
    'get_info'     => {ret => 0},
    'get_link'     => {ret => 0},
    'get_name'     => {ret => 0},
    'get_owner'    => {ret => 0},
    'get_path'     => {ret => 0},
    'get_prefix'   => {ret => 0},
    'get_share'    => {ret => 0},
    'get_sub'      => {ret => 0},
    'in_job'       => {ret => 0},
    'is_filtered'  => {ret => 0},
    'is_rendered'  => {ret => 0},
    'purge'        => {ret => 0},
    'set_abbr'     => {ret => 0},
    'set_info'     => {ret => 0},
    'set_meta'     => {ret => 0},
    'set_prefix'   => {ret => 0},
    'set_share'    => {ret => 0},
    'test'         => {ret => 0},
    'test_free'    => {ret => 0},
    'wait'         => {ret => 0},
    },
  );

# Define the global private constants
my $RE_MOD = qr/^S\d{3}([A-Z]\w*)$/i;

my $ALS_OID = 0;  # Report identifier
my $ALS_FIL = 1;  # Report file name
my $ALS_DIR = 2;  # Directory type
my $ALS_NAM = 3;  # Report name
my $ALS_SET = 4;  # Alias fields

my $SHR_GID = 0;  # Share group identifier
my $SHR_OID = 1;  # Report identifier
my $SHR_MOD = 2;  # Module name
my $SHR_DIR = 3;  # Report directory type
my $SHR_NAM = 4;  # Report name
my $SHR_EXT = 5;  # Report extension
my $SHR_FMT = 6;  # Report file name format
my $SHR_FIL = 7;  # Report file name
my $SHR_LNK = 8;  # Share link
my $SHR_SET = 9;  # Share fields

# Define the global private variables
my %tb_cre = (
  A => \&_mk_sub,
  B => \&_mk_sub,
  C => \&_mk_top,
  E => \&_mk_sub,
  I => \&_mk_sub,
  J => \&_mk_sub,
  L => \&_mk_sub,
  M => \&_mk_sub,
  P => \&_mk_sub,
  R => \&_mk_sub,
  S => \&_mk_sub,
  T => \&_mk_sub,
  X => \&_mk_sub,
  );
my %tb_def = (
  A => 'COL',
  B => 'BOX',
  C => 'COL',
  E => 'COL',
  I => 'INC',
  J => 'JOB',
  L => 'LCK',
  M => 'COL',
  P => 'COL',
  R => 'COL',
  S => 'COL',
  T => 'TMP',
  X => 'COL',
  );
my %tb_end = (
  'RDA::Object::Pipe'   => \&end_pipe,
  'RDA::Object::Report' => \&end_report,
  );
my %tb_err = (
  A => 'RDA-01002: Cannot create the archive directory',
  B => 'RDA-01013: Cannot create the sandbox directory',
  C => 'RDA-01001: Cannot create the report directory',
  E => 'RDA-01003: Cannot create the extern directory',
  I => 'RDA-01010: Cannot create the inline code directory',
  J => 'RDA-01011: Cannot create the job directory',
  L => 'RDA-01012: Cannot create the lock directory',
  M => 'RDA-01009: Cannot create the multi-run collection directory',
  P => 'RDA-01004: Cannot create the remote directory',
  R => 'RDA-01005: Cannot create the ref directory',
  S => 'RDA-01006: Cannot create the sample directory',
  T => 'RDA-01007: Cannot create the temporary directory',
  X => 'RDA-01008: Cannot create the transfer directory',
  );
my %tb_imp = (
  als => 2,
  cat => 2,
  cln => 1,
  def => $SHR_SET + 3,
  exp => 3,
  hom => 1,
  idx => 3,
  spc => 0,
  sta => 1,
  );
my %tb_sub = (
  A => 'archive',
  C => undef,
  E => 'extern',
  M => 'mrc',
  P => 'remote',
  R => 'ref',
  S => 'sample',
  X => 'transfer',
  );
my %tb_toc = (
  C => \&_save_collect,
  E => \&_save_empty,
  R => \&_save_section,
  S => \&_save_section,
  T => \&_save_top,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Output-E<gt>new($agent[,$flag])>

The global reporting control object constructor. It takes the agent reference
as an argument. Setting the flag disables any output postprocessing.

=head2 S<$out-E<gt>new($package)>

The local reporting control object constructor. It takes a package reference,
which is used for providing the module name and version.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'als' > > Alias definition hash (L)

=item S<    B<'abr' > > Abbreviation of the current module (L)

=item S<    B<'agt' > > Reference to the agent object (G,L)

=item S<    B<'bas' > > Maximum length of the report basename (G,L)

=item S<    B<'cas' > > Indicates a case-sensitive context (G,L)

=item S<    B<'cfg' > > RDA sotware configuration reference (G,L)

=item S<    B<'cln' > > Cloned reports (L)

=item S<    B<'col' > > Collection indicator (L)

=item S<    B<'cur' > > Reference to the current report (L)

=item S<    B<'def' > > Local share definitions (L)

=item S<    B<'dir' > > Report directory name (G,L)

=item S<    B<'dup' > > Duplicated report hash (L)

=item S<    B<'emu' > > Link emulation indicator (G,L)

=item S<    B<'end' > > How long to wait for asynchronous report completion (G)

=item S<    B<'exp' > > Explorer entries (L)

=item S<    B<'flt' > > Filter control object reference (G,L)

=item S<    B<'grp' > > Report group (G,L)

=item S<    B<'idx' > > Index entries (L)

=item S<    B<'job' > > Job identifier (G,L)

=item S<    B<'lgt' > > Maximum length of the report name (L)

=item S<    B<'lst' > > Reference to the most recent report or pipe defined (L)

=item S<    B<'met' > > Meta directory indicator (G,L)

=item S<    B<'mrc' > > Multi-run collection indicator (L)

=item S<    B<'nam' > > Setup name (L)

=item S<    B<'oid' > > Setup name (G) / Package name (L)

=item S<    B<'own' > > Ownership alignment indicator (L)

=item S<    B<'pid' > > Report subprocess identifiers (G,L)

=item S<    B<'pip' > > Pipe hash (L)

=item S<    B<'pkg' > > Package object reference (L)

=item S<    B<'pre' > > Report prefix (L)

=item S<    B<'prv' > > Previous run table of content (G,L)

=item S<    B<'rel' > > Software release (G,L)

=item S<    B<'rev' > > Reverse mapping hash (L)

=item S<    B<'rnd' > > Render object reference (G,L)

=item S<    B<'rpt' > > Report hash (L)

=item S<    B<'shr' > > Share definition cache (L)

=item S<    B<'spc' > > Disk space used by all reports (L)

=item S<    B<'sta' > > File status information hash (L)

=item S<    B<'tmp' > > Temporary file hash (L)

=item S<    B<'toc' > > Reference to the table of contents object (L)

=item S<    B<'typ' > > Object type (G,L,N)

=item S<    B<'ver' > > Package version (L)

=item S<    B<'wrk' > > Work file hash (G)

=item S<    B<'_cln'> > Clean request hash (G)

=item S<    B<'_def'> > Path definition (G,L)

=item S<    B<'_dfa'> > Disk free space available (L)

=item S<    B<'_dfc'> > Disk free initialization counter (G,L)

=item S<    B<'_dff'> > Disk free check function at module level (G,L)

=item S<    B<'_dfm'> > Disk free minimum size (G,L)

=item S<    B<'_dfp'> > Disk free path (G,L)

=item S<    B<'_dfr'> > Disk free check function at report level (G,L)

=item S<    B<'_dft'> > Disk free type (G,L)

=item S<    B<'_dir'> > Report directory cache (G,L)

=item S<    B<'_exp'> > Section Explorer entries (L)

=item S<    B<'_gid'> > Group identifier of the report directory owner (G,L)

=item S<    B<'_idx'> > Section index entries (L)

=item S<    B<'_opn'> > Hash containing suspended report files (L)

=item S<    B<'_pip'> > Pipe sequence number (L)

=item S<    B<'_rpt'> > Report file sequence number (L)

=item S<    B<'_sct'> > Section reports (L)

=item S<    B<'_spl'> > Report space limit (L)

=item S<    B<'_tmp'> > Temporary file sequence number (L)

=item S<    B<'_uid'> > User identifier of the report directory owner (G,L)

=item S<    B<'_wrk'> > Work file sequence number (G)

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $obj, $flg) = @_;
  my ($slf);

  if (ref($cls))
  { my ($agt, $val);

    # Create a local reporting control object
    $slf = bless {
      als  => {},
      cln  => {},
      def  => {},
      dup  => {},
      exp  => {},
      idx  => {},
      job  => '',
      mod  => 0,
      mrc  => 0,
      nam  => $cls->{'oid'},
      oid  => $obj->get_oid,
      own  => 0,
      pip  => {},
      pkg  => $obj,
      pre  => '',
      rev  => {},
      rpt  => {},
      shr  => {},
      spc  => 0,
      sta  => {},
      tmp  => {},
      typ  => 'L',
      ver  => $obj->get_info('ver', 0),
      _cln => {},
      _def => {%tb_def},
      _dir => {%{$cls->{'_dir'}}},
      _opn => {},
      _pip => 0,
      _rpt => 0,
      _tmp => 0,
      }, ref($cls);

    # Take a copy of parameters
    foreach my $key (qw(agt bas cas cfg dir emu flt grp met rel rnd
                        _dfa _dff _dfm _dfp _dfr _dft))
    { $slf->{$key} = $cls->{$key} if exists($cls->{$key});
    }

    # Complete the report control initialization
    if ($slf->{'oid'} =~ $RE_MOD)
    { $slf->{'abr'} = $1;
      $slf->{'col'} = 1;
    }
    else
    { $slf->{'abr'} = 'TST';
      $slf->{'col'} = 0;
    }
    $slf->{'lgt'} = _adjust_length($slf);

    # Control the space management
    $agt = $slf->{'agt'};
    $val = $agt->get_setting('NO_QUOTA')
      ? 0
      : int(1048576 * $agt->get_setting($slf->{'oid'}.'_SPACE_QUOTA', 0));
    $slf->{'_spc'} = $val if $val > 0;
    $slf->check_free(0) if $cls->{'_dfc'}++;
  }
  elsif ($obj)
  { my ($cfg, $dir, $lgt, $sub, $val);

    # Create a global reporting control object
    $cfg = $obj->get_config;
    $slf = bless {
      abr => 'TST',
      agt => $obj,
      bas => $cfg->get_info('RDA_BASENAME', 38),
      cas => $cfg->get_info('RDA_CASE',     1),
      cfg => $cfg,
      dir => $obj->get_setting('RPT_DIRECTORY', 'output'),
      emu => $obj->get_setting('RDA_SHARE',     1),
      end => $obj->get_setting('RDA_WAIT',      120),
      grp => $obj->get_setting('RPT_GROUP',     'RDA'),
      job => '',
      met => $obj->get_setting('RDA_META',      0),
      oid => $obj->get_oid,
      pid => {},
      rel => $cfg->get_version,
      typ => 'G',
      wrk => {},
      _cln => {},
      _def => {%tb_def},
      _dir => {},
      _dfa => 0,
      _dfc => 0,
      _dft => $obj->get_setting('RDA_FREE_CHECK', 'M'),
      _wrk => 0,
      }, $cls;

    # Define global directories
    $slf->get_path('J');
    $slf->get_path('T');
    $slf->{'_dir'}->{'L'} = 
      (defined($dir = $obj->get_setting('RDA_LOCK', $ENV{'RDA_LOCK'}))
        && -d $dir) ? $dir : $slf->_get_path('L');

    # Prepare output postprocessing
    unless ($flg)
    { if ($obj->get_setting('RDA_FILTER'))
      { eval {
          require RDA::Handle::Filter;
          $slf->{'flt'} = RDA::Handle::Filter->new($obj)
            if $obj->is_configured('S990FLTR');
          };
        die "RDA-01020: Filter error:\n $@\n" if $@;
        $slf->{'met'} = 0;
      }
      elsif ($val = $obj->get_setting('RDA_RENDER'))
      { eval {
          require RDA::Render;
          $slf->{'rnd'} = RDA::Render->new($slf, $val);
          };
      }
    }

    # Clean the report directory
    if ($obj->del_setting('RPT_CLEAN'))
    { if (opendir(RPT, $slf->{'dir'}))
      { $val = qr/^$slf->{'grp'}_(S\d{3}[A-Z]\w*)_A\.fil$/i;
        foreach my $fil (readdir(RPT))
        { $obj->del_reports($1) if $fil =~ $val && !$obj->is_collected($1);
        }
        closedir(RPT);
      }
    }

    # Enable the space management
    _chk_free($slf, $obj->get_setting('RDA_FREE', 0));
  }
  else
  { # Create an output blocking object
    $slf = bless {
      typ => 'N',
      }, $cls;
  }

  # Return the object reference
  $slf;
}

# Adjust variable part length limit
sub _adjust_length
{ my ($slf, $job) = @_;
  my ($lgt);

  $job = $slf->{'job'} unless defined($job);
  $lgt = $slf->{'bas'} - length($slf->{'grp'}) - length($slf->{'abr'}) 
    - length($slf->{'pre'}) - length($job) - 8;
  ($lgt > 1) ? $lgt : 0;
}

=head2 S<$h-E<gt>close>

This method closes the report files.

=cut

sub close
{ my ($slf) = @_;

  if ($slf->{'typ'} eq 'L')
  { # End reports and temporary files
    foreach my $obj (values(%{$slf->{'rpt'}}), values(%{$slf->{'tmp'}}))
    { $obj->close(1) if $obj->is_active;
    }

    # Close the table of content file
    $slf->{'toc'}->close(1) if exists($slf->{'toc'});

    # Check the free space
    $slf->check_free(0);
  }
}

=head2 S<$h-E<gt>delete>

This method deletes the report control object.

=cut

sub delete
{ my ($slf, $tim) = @_;

  if ($slf->{'typ'} eq 'L')
  { my ($buf, $gid, $grp, $obj, $ofh, $oid, $pth, $uid, @tbl);

    $grp = $slf->{'grp'};
    $oid = $slf->{'oid'};

    # Clear suspended reports
    $slf->{'_opn'} = {};

    # End pipes, reports, and temporary files
    foreach my $oid (keys(%{$slf->{'pip'}}))
    { $slf->end_pipe($oid);
      delete($slf->{'pip'}->{$oid})->delete;
    }
    foreach my $oid (keys(%{$slf->{'rpt'}}))
    { $slf->end_report($oid);
      delete($slf->{'rpt'}->{$oid})->delete;
    }
    foreach my $oid (keys(%{$slf->{'tmp'}}))
    { $slf->end_temp($oid);
      delete($slf->{'tmp'}->{$oid})->delete;
    }

    # Delete the sand box directory
    RDA::Object::Rda->delete_dir(delete($slf->{'_dir'}->{'B'}))
      if exists($slf->{'_dir'}->{'B'});

    # End the table of content
    delete($slf->{'toc'})->delete if exists($slf->{'toc'});

    # Save details for collection modules
    if ($slf->{'col'})
    { $ofh = IO::File->new;

      # Check ownership alignment
      ($uid, $gid) = $slf->get_owner if $slf->{'own'};

      # Adjust the ownership of the mrc directory
      chown($uid, $gid, $slf->{'_dir'}->{'M'})
        if defined($uid) && exists($slf->{'_dir'}->{'M'});

      # Save the alias definition
      if (@tbl = keys(%{$slf->{'als'}}))
      { $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
          $grp.'_'.$oid.'_A.fil');
        if ($ofh->open($pth, $CREATE, $FIL_PERMS))
        { foreach my $key (sort @tbl)
          { foreach my $dir (sort keys(%{$slf->{'als'}->{$key}}))
            { $buf = join('|', $key, $dir, $slf->{'als'}->{$key}->{$dir});
              $ofh->syswrite($buf, length($buf));
            }
          }
          $ofh->close;
          chown($uid, $gid, $pth) if defined($uid);
        }
      }

      # Save the file status information entries
      if (@tbl = keys(%{$slf->{'sta'}}))
      { $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
          $grp.'_'.$oid.'_D.fil');
        if ($ofh->open($pth, $CREATE, $FIL_PERMS))
        { foreach my $key (sort @tbl)
          { $buf = join('|', $key, $slf->{'sta'}->{$key});
            $ofh->syswrite($buf, length($buf));
          }
          $ofh->close;
          chown($uid, $gid, $pth) if defined($uid);
        }
      }

      # Save the Explorer entries
      if (@tbl = keys(%{$slf->{'exp'}}))
      { $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
          $grp.'_'.$oid.'_E.fil');
        if ($ofh->open($pth, $CREATE, $FIL_PERMS))
        { foreach my $abr (sort @tbl)
          { foreach my $oid (sort keys(%{$slf->{'exp'}->{$abr}}))
            { foreach my $dir (sort keys(%{$slf->{'exp'}->{$abr}->{$oid}}))
              { foreach my $rec (@{$slf->{'exp'}->{$abr}->{$oid}->{$dir}})
                { $ofh->syswrite($rec, length($rec));
                }
              }
            }
          }
          $ofh->close;
          chown($uid, $gid, $pth) if defined($uid);
        }
      }

      # Save the index entries
      if (@tbl = keys(%{$slf->{'idx'}}))
      { $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
          $grp.'_'.$oid.'_I.fil');
        if ($ofh->open($pth, $CREATE, $FIL_PERMS))
        { foreach my $abr (sort @tbl)
          { $buf = "A|$abr|\n";
            $ofh->syswrite($buf, length($buf));
            if (exists($slf->{'idx'}->{$abr}->{'@'}))
            { $buf = "H|".$slf->{'idx'}->{$abr}->{'@'}."|\n";
              $ofh->syswrite($buf, length($buf));
            }
            foreach my $oid (sort keys(%{$slf->{'idx'}->{$abr}}))
            { next if $oid eq '@';
              foreach my $dir (sort keys(%{$slf->{'idx'}->{$abr}->{$oid}}))
              { foreach my $rec (@{$slf->{'idx'}->{$abr}->{$oid}->{$dir}})
                { $ofh->syswrite($rec, length($rec));
                }
              }
            }
          }
          $ofh->close;
          chown($uid, $gid, $pth) if defined($uid);
        }
      }

      # Save the share definitions
      if (@tbl = keys(%{$slf->{'def'}}))
      { foreach my $abr (sort @tbl)
        { $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
            $grp.'_'.$abr.'_S.fil');
          if ($ofh->open($pth, $CREATE, $FIL_PERMS))
          { foreach my $oid (sort keys(%{$slf->{'def'}->{$abr}}))
            { foreach my $grp (sort keys(%{$slf->{'def'}->{$abr}->{$oid}}))
              { $buf = join('|', @{$slf->{'def'}->{$abr}->{$oid}->{$grp}},
                  "\n");
                $ofh->syswrite($buf, length($buf));
              }
            }
            $ofh->close;
            chown($uid, $gid, $pth) if defined($uid);
          }
        }
      }
    }

    # Clear the internal tables
    $slf->{'als'} = {};
    $slf->{'def'} = {};
    $slf->{'idx'} = {};
    $slf->{'sta'} = {};

    # Log the limits
    $slf->{'agt'}->log('l', $slf->{'oid'}, $slf->{'spc'}, $tim)
      if defined($tim);
  }
  elsif ($slf->{'typ'} eq 'G')
  { # Stop direct rendering
    $slf->{'rnd'}->end if exists($slf->{'rnd'});

    # Clean work files
    foreach my $pth (values(%{$slf->{'_cln'}}))
    { 1 while unlink($pth);
    }
    $slf->{'_cln'} = {};
    $slf->{'wrk'}  = {};
  }

  # Delete the object
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>extract>

This method extracts the alias, file, index, and share information.

=cut

sub extract
{ my ($slf) = @_;
  my ($buf, $tbl, @tbl);

  $buf = '';

  # Close all reports
  $slf->close;

  # Save the alias definitions
  foreach my $key (keys(%{$slf->{'als'}}))
  { foreach my $dir (keys(%{$tbl = $slf->{'als'}->{$key}}))
    { $buf .= join("\001", 'als', $key, $dir, $tbl->{$dir});
    }
  }
  $slf->{'als'} = {};

  # Save the share definitions
  foreach my $abr (keys(%{$slf->{'def'}}))
  { foreach my $oid (keys(%{$slf->{'def'}->{$abr}}))
    { foreach my $gid (keys(%{$tbl = $slf->{'def'}->{$abr}->{$oid}}))
      { $buf .= join("\001", 'def', $abr, $oid, $gid, @{$tbl->{$gid}}, "\n");
      }
    }
  }
  $slf->{'def'} = {};

  # Save the Explorer entries
  foreach my $abr (keys(%{$slf->{'exp'}}))
  { foreach my $oid (keys(%{$slf->{'exp'}->{$abr}}))
    { foreach my $dir (keys(%{$tbl = $slf->{'exp'}->{$abr}->{$oid}}))
      { foreach my $rec (@{$tbl->{$dir}})
        { $buf .= join("\001", 'exp', $abr, $oid, $dir, $rec);
        }
      }
    }
  }
  $slf->{'exp'} = {};

  # Save the index entries
  foreach my $abr (keys(%{$slf->{'idx'}}))
  { $buf .= join("\001", 'hom', $abr, $slf->{'idx'}->{$abr}->{'@'})
      if exists($slf->{'idx'}->{$abr}->{'@'});
    foreach my $oid (keys(%{$slf->{'idx'}->{$abr}}))
    { next if $oid eq '@';
      foreach my $dir (keys(%{$tbl = $slf->{'idx'}->{$abr}->{$oid}}))
      { foreach my $rec (@{$tbl->{$dir}})
        { $buf .= join("\001", 'idx', $abr, $oid, $dir, $rec);
        }
      }
    }
  }
  $slf->{'idx'} = {};

  # Save the file status information
  foreach my $key (keys(%{$tbl = $slf->{'sta'}}))
  { $buf .= join("\001", 'sta', $key, $slf->{'sta'}->{$key});
  }
  $slf->{'sta'} = {};

  # Save the cloned report list and related catalog entries
  foreach my $oid (keys(%{$slf->{'rpt'}}))
  { next unless $slf->{'rpt'}->{$oid}->is_cloned;
    $buf .= join("\001", 'cln', $oid, "\n");
    foreach my $key (keys(%{$tbl = $slf->{'rpt'}->{$oid}->get_info('cat')}))
    { foreach my $rec (@{$tbl->{$key}})
      { $buf .= join("\001", 'cat', $oid, $key, $rec);
      }
    }
  }
  
  # Save the report space
  $buf .= join("\001", 'spc', $slf->{'spc'}) if $slf->{'spc'};

  # Return the extracted definition
  $buf;
}

=head2 S<$h-E<gt>get_group>

This method returns the report group.

=cut

sub get_group
{ shift->{'grp'};
}

=head2 S<$h-E<gt>get_current([$flag])>

This method returns the path of the current report directory (the report
directory or the multi-run collection directory). When the flag is set, it
creates missing directories also.

=cut

sub get_current
{ my ($slf, $flg) = @_;

  $slf->get_path($slf->{'mrc'} ? 'M' : 'C', $flg);
}

=head2 S<$h-E<gt>get_owner([$flag])>

This method returns the owner of the report directory. In list contexts, it
returns both user and group identifiers. In scalar contexts, it returns the
user identifier. When the directory does not yet exists, it returns
respectively an empty list or an undefined value. When the flag is set, it
forces its creation.

=cut

sub get_owner
{ my ($slf, $flg) = @_;
  my (@sta);

  unless (exists($slf->{'_uid'}))
  { unless (@sta = stat($slf->get_path('C',$flg)))
    { return () if wantarray;
      return undef;
    }
    $slf->{'_uid'} = $sta[4];
    $slf->{'_gid'} = $sta[5];
  }
  return ($slf->{'_uid'}, $slf->{'_gid'}) if wantarray;
  $slf->{'_uid'};
}

=head2 S<$h-E<gt>get_path($type[,$flag])>

This method returns the path of the report directory for the specified
type. Valid subdirectory types are:

=over 7

=item B<    A > For the C<archive> subdirectory

=item B<    B > For the sandbox subdirectory

=item B<    C > For the output/report directory itself

=item B<    E > For the C<extern> subdirectory

=item B<    I > For the language interface subdirectory

=item B<    J > For the job subdirectory

=item B<    L > For the lock subdirectory

=item B<    M > For the multi-run collections (C<mrc> subdirectory)

=item B<    P > For the remote packages (C<remote> subdirectory)

=item B<    R > For the C<ref> subdirectory

=item B<    S > For the C<sample> subdirectory

=item B<    T > For the temporary subdirectory

=item B<    X > For the transfer subdirectory

=back

When the flag is set, it creates missing directories also.

=cut

sub get_path
{ my ($slf, $typ, $flg) = @_;
  my ($pth);

  # Validate the request
  die "RDA-01000: Unknown directory type '$typ'\n"
    unless exists($slf->{'_def'}->{$typ});

  # Determine the report subdirectory
  $pth = exists($slf->{'_dir'}->{$typ})
    ? $slf->{'_dir'}->{$typ}
    : _get_path($slf, $typ);

  # Create the report subdirectory when needed
  &{$tb_cre{$typ}}($slf, $pth, $tb_err{$typ}) unless -d $pth || !$flg;

  # Return the report subdirectory
  $pth;
}

sub _get_path
{ my ($slf, $typ, $flg) = @_;
  my ($pth, $sub);

  $sub = exists($tb_sub{$typ}) ? $tb_sub{$typ} :
                                 $slf->{'_def'}->{$typ}.'_'.$slf->{'grp'};
  $pth = defined($sub)
    ? RDA::Object::Rda->cat_dir($slf->get_path('C', $flg), $sub)
    : $slf->{'dir'};
  RDA::Object::Rda->clean_dir($pth) if $typ eq 'T' && -d $pth;
  $slf->{'_dir'}->{$typ} = $pth;
}

sub _mk_sub
{ my ($slf, $pth, $err) = @_;

  _mk_top($slf, $slf->{'dir'}, $err) unless -d $slf->{'dir'};
  RDA::Object::Rda->create_dir($pth, $DIR_PERMS, $err);
}

sub _mk_top
{ my ($slf, $pth, $err) = @_;

  RDA::Object::Rda->create_dir($pth, $DIR_PERMS, $err);
  $slf->{'agt'}->log_force;
}

=head2 S<$h-E<gt>get_prefix>

This method returns the current report prefix.

=cut

sub get_prefix
{ my ($slf) = @_;

  $slf->{'grp'}.'_'.$slf->{'abr'}.'_'.$slf->{'pre'};
}

=head2 S<$h-E<gt>get_sub($type)>

This method returns the name of the report subdirectory for the specified
type. It returns an undefined value when not applicable.

=cut

sub get_sub
{ my ($slf, $typ) = @_;

  exists($tb_sub{$typ}) ? $tb_sub{$typ} : undef;
}

=head2 S<$h-E<gt>in_job>

This method indicates whether the report control is currently working for a
job.

=cut

sub in_job
{ shift->{'job'};
}

=head2 S<$h-E<gt>is_rendered>

This method indicates whether the report file is rendered immediately. When
applied to the report control object, it indicates if direct rendering has been
requested.

=cut

sub is_rendered
{ exists(shift->{'rnd'}) ? 1 : 0;
}

=head2 S<$h-E<gt>load($ifh)>

This method loads extracted alias, file, index, and share information.

=cut

sub load
{ my ($slf, $ifh) = @_;
  my ($key, $lin, $str, $typ, @rec);

  $lin = 0;
  while (defined($str = $ifh->getline))
  { ++$lin;
    ($typ, $key, @rec) = split(/\001/, $str, -1);
    die "RDA-01032: Cannot load information from threads (line $lin)\n"
      unless $typ && exists($tb_imp{$typ}) && (scalar @rec) == $tb_imp{$typ}
      && $key;
    if ($typ eq 'als')
    { $slf->{'als'}->{$key}->{$rec[0]} = $rec[1];
    }
    elsif ($typ eq 'cat')
    { $slf->{'rpt'}->{$key}->add_entry($rec[0], $rec[1]);
    }
    elsif ($typ eq 'cln')
    { $slf->{'rpt'}->{$key}->update(1) if exists($slf->{'rpt'}->{$key});
    }
    elsif ($typ eq 'def')
    { my ($gid, $oid);

      pop(@rec);
      push(@{$slf->{'shr'}->{$key}},
        $slf->{'def'}->{$key}->{$oid}->{$gid} = [@rec])
        if ($oid = shift(@rec)) && ($gid = shift(@rec));
    }
    elsif ($typ eq 'exp')
    { push(@{$slf->{'exp'}->{$key}->{$rec[0]}->{$rec[1]}}, $rec[2]);
    }
    elsif ($typ eq 'hom')
    { $slf->{'idx'}->{$key}->{'@'} = $rec[0];
    }
    elsif ($typ eq 'idx')
    { push(@{$slf->{'idx'}->{$key}->{$rec[0]}->{$rec[1]}}, $rec[2]);
    }
    elsif ($typ eq 'spc')
    { $slf->{'spc'} += $key;
    }
    elsif ($typ eq 'sta')
    { $slf->{$typ}->{$key} = $rec[0];
    }
  }
  $ifh->close;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>resume($bkp)>

This method resumes some object activities. It returns a list containing the
object reference and the previous values of the restored attributes.

=cut

sub resume
{ my ($slf, $rec) = @_;
  my ($bkp);

  die "RDA-01031: Cannot resume the reporting control\n"
    unless $slf->{'typ'} eq 'L' && ref($rec) eq 'HASH';

  # End pipes, reports, and temporary files
  foreach my $oid (keys(%{$slf->{'pip'}}))
  { $slf->end_pipe($oid);
    delete($slf->{'pip'}->{$oid})->delete;
  }
  foreach my $oid (keys(%{$slf->{'rpt'}}))
  { $slf->end_report($oid);
    delete($slf->{'rpt'}->{$oid})->delete;
  }
  foreach my $oid (keys(%{$slf->{'tmp'}}))
  { $slf->end_temp($oid)->delete;
    delete($slf->{'tmp'}->{$oid})->delete;
  }

  # End the table of content
  delete($slf->{'toc'})->delete if exists($slf->{'toc'});

  # Restore the attributes
  $bkp = _switch($slf, {}, $rec);

  # Unlock the reports and temporary files
  foreach my $obj (values(%{$slf->{'pip'}}),
                   values(%{$slf->{'rpt'}}),
                   values(%{$slf->{'tmp'}}))
  { $obj->unlock;
  }

  # Return previous values
  $bkp;
}

sub _switch
{ my ($slf, $bkp, $rec) = @_;

  # Restore saved attributes
  foreach my $key (keys(%$rec))
  { $slf->{$key} = $bkp->{$key} if exists($bkp->{$key});
    if (defined($rec->{$key}))
    { ($slf->{$key}, $bkp->{$key}) = ($rec->{$key}, $slf->{$key});
    }
    else
    { $bkp->{$key} = delete($slf->{$key});
    }
  }

  # Return the value of the modified attributes
  $bkp;
}

=head2 S<$h-E<gt>set_abbr([$abbr])>

This method uses the specified argument as the new module abbreviation when it
starts with a letter followed by alphanumeric characters. Otherwise, it remains
unchanged.

It returns the previous abbreviation.

=cut

sub set_abbr
{ my ($slf, $abr) = @_;
  my ($old);

  $old = $slf->{'abr'};
  if (defined($abr) && $abr =~ m/^([A-Z]\w*?)\_*$/i)
  { die "RDA-01024: Invalid request in a multi-run collection section\n"
      if exists($slf->{'_sct'});
    $slf->{'abr'} = $1;
    $slf->{'lgt'} = _adjust_length($slf);
  }
  $old;
}

=head2 S<$h-E<gt>set_prefix([$prefix])>

This method defines a new report prefix when the prefix is an empty string or
starts with a letter followed by alphanumeric characters. Otherwise, it remains
unchanged.

It returns the previous prefix.

=cut

sub set_prefix
{ my ($slf, $pre) = @_;
  my ($old);

  $old = $slf->{'pre'};
  if (defined($pre))
  { if ($pre eq '')
    { $slf->{'pre'} = '';
      $slf->{'lgt'} = _adjust_length($slf);
    }
    elsif ($pre =~ m/^([A-Z]\w*?)\_*$/i)
    { $slf->{'pre'} = $1.'_';
      $slf->{'lgt'} = _adjust_length($slf);
    }
  }
  $old;
}

=head2 S<$h-E<gt>suspend($job[,$fork])>

This method suspends some report activities for the specified job. It returns
previous attributes.

=cut

sub suspend
{ my ($slf, $job, $frk) = @_;
  my ($top, @tbl);

  die "RDA-01030: Cannot suspend the reporting control\n"
    if $slf->{'typ'} ne 'L' || $slf->{'job'};

  # Handle forked contexts
  if ($frk)
  { # Close pipes
    foreach my $oid (keys(%{$slf->{'pip'}}))
    { delete($slf->{'pip'}->{$oid})->delete;
    }

    # Reset work file manager
    $top = $slf->{'agt'}->get_output;
    $top->{'job'} = $job;
    $top->{'wrk'} = {};
    $top->{'_cln'} = {};
    $top->{'_wrk'} = 0;
  }

  # Lock pipes, reports, and temporary files
  foreach my $obj (values(%{$slf->{'pip'}}),
                   values(%{$slf->{'rpt'}}),
                   values(%{$slf->{'tmp'}}))
  { $obj->lock;
  }

  # Close the table of content file
  $slf->{'toc'}->close(1) if exists($slf->{'toc'});

  # Add space management contribution
  push(@tbl, _spc => $slf->{'_spc'} - $slf->{'spc'})
    if exists($slf->{'_spc'});

  # Switch object attributes
  _switch($slf, {}, {
    abr  => $slf->{'abr'},
    als  => {},
    cur  => undef,
    def  => {},
    dup  => {},
    exp  => {},
    idx  => {},
    job  => $job,
    lgt  => _adjust_length($slf, $job),
    met  => $slf->{'met'},
    pid  => {},
    pip  => {},
    pre  => $slf->{'pre'},
    rpt  => {},
    shr  => {},
    spc  => 0,
    sta  => {},
    tmp  => {},
    toc  => undef,
    _opn => {},
    _pip => 0,
    _rpt => 0,
    _tmp => 0,
    @tbl,
    });
}

=head2 S<$h-E<gt>test>

This method determines if it can create and remove files from the report
directory. It creates the directory if it does not exist already. It returns
an error message in case of a problem, or an undefined value on successful
completion.

=cut

sub test
{ my ($slf) = @_;
  my ($ofh, $pth, $val);

  # Test if the report group is compatible with basename constraint
  return "RDA-01021: The report file prefix is too long\n"
    if length($slf->{'grp'}) + 14 > $slf->{'bas'};

  # Create the report directory when needed
  eval {$pth = $slf->get_path('C', 1)};
  if ($val = $@)
  { $val =~ s/[\n\r\s]+$//;
    return $val;
  }

  # Try to create a test file
  $ofh = IO::File->new;
  $pth = RDA::Object::Rda->cat_file($pth, $slf->{'grp'}.'_test.txt');
  return "RDA-01022: Cannot create a test file in the report directory:\n $!\n"
    unless $ofh->open($pth, $CREATE, $FIL_PERMS);
  $ofh->close;

  # Unlink the file and indicate the completion status
  $val = 0;
  ++$val while unlink($pth);
  return
    "RDA-01023: Cannot remove the test file from the report directory:\n $!\n"
    unless $val;

  # Indicate the successful completion
  undef;
}

=head2 S<$h-E<gt>wait>

This method waits for the completion of report subprocesses.

=cut

sub wait
{ my ($slf) = @_;

  if (exists($slf->{'rpt'}))
  { foreach my $rpt (values(%{$slf->{'rpt'}}))
    { $rpt->wait;
    }
  }

  if (exists($slf->{'pid'}))
  { my ($cnt, $lim);

    $lim = $cnt = ($slf->{'end'} > 0) ? $slf->{'end'} : 0;
    foreach my $pid (keys(%{$slf->{'pid'}}))
    { eval {
        while (kill(0, $pid))
        { die "Timeout\n" if $lim && $cnt-- <= 0;
          sleep(1);
        }
        delete($slf->{'pid'}->{$pid});
      };
    }
    foreach my $pid (keys(%{$slf->{'pid'}}))
    { eval {RDA::Object::Rda->kill_child($pid)};
    }
    delete($slf->{'pid'});
  }
}

=head1 FILE INDEX METHODS

=head2 S<$h-E<gt>add_home($pth)>

This method associates an Oracle home directory entry to the current
abbreviation.

=cut

sub add_home
{ my ($slf, $pth) = @_;

  return 0 unless $pth && -d $pth;
  $slf->{'idx'}->{$slf->{'abr'}}->{'@'} = join('|', 'H', $pth, "\n");
  1;
}

=head2 S<$h-E<gt>enable_index([$flg])>

This method enables the index creation regardless the execution context. When
the flag is set, it aligns as much as possible the owner of the produced files
to the owner of the report directory.

=cut

sub enable_index
{ my ($slf, $flg) = @_;

  $slf->{'agt'}->set_info('own', $slf->{'own'} = 1)
    if $flg && defined($slf->get_owner);
  $slf->{'col'} = 1;
}

=head1 FILTERING METHODS

=head2 S<$h-E<gt>filter($str)>

This method filters sensitive information out of the specified string.

=cut

sub filter
{ my ($slf, $str) = @_;

  exists($slf->{'flt'}) ? $slf->{'flt'}->filter($str) : $str;
}

=head2 S<$h-E<gt>is_filtered>

This method indicates if sensitive information are filtered out.

=cut

sub is_filtered
{ exists(shift->{'flt'});
}

=head2 S<$h-E<gt>log_timeout($req,$rpt)>

This method logs a timeout event in the event log. It applies the filtering
rules to the request command.

=cut

sub log_timeout
{ my ($slf, $req, $rpt) = @_;
  my ($cmd); 
  $cmd = join(' ', $req->get_attr('command'));
  $cmd = $slf->{'flt'}->filter($cmd) if exists($slf->{'flt'});
  $slf->{'agt'}->log('t', $slf->{'oid'}, $req->get_first('id', $rpt->get_file),
    $req->get_info('msg'), $cmd);
}

=head1 META DIRECTORY MANAGEMENT METHODS

=head2 S<$h-E<gt>add_dir($dir)>

This method gets file status information for each file contained in the
specified directory and stores it in the meta directory repository.

=cut

sub add_dir
{ my ($slf, $dir) = @_;
  my ($pth);

  if ($pth->{'met'} && opendir(MET, $dir))
  { $dir = $slf->{'cfg'}->get_file('D_RDA', $dir)
      unless RDA::Object::Rda->is_absolute($dir);
    foreach my $fil (sort readdir(MET))
    { $pth = RDA::Object::Rda->cat_file($dir, $fil);
      $slf->{'sta'}->{$pth} = join('|', stat($pth), "\n");
    }
    closedir(MET);
  }
}

=head2 S<$h-E<gt>add_file($path)>

This method gets the file information and stores it in the meta directory
repository.

=cut

sub add_file
{ my ($slf, $pth) = @_;

  if ($slf->{'met'})
  { $pth = $slf->{'cfg'}->get_file('D_RDA', $pth)
      unless RDA::Object::Rda->is_absolute($pth);
    $slf->{'sta'}->{$pth} = join('|', stat($pth), "\n");
  }
}

=head2 S<$h-E<gt>add_stat($path,$stat)>

This method stores specified file status information in the meta directory
repository.

=cut

sub add_stat
{ my ($slf, $pth, $sta) = @_;

  if ($slf->{'met'})
  { $pth = $slf->{'cfg'}->get_file('D_RDA', $pth)
      unless RDA::Object::Rda->is_absolute($pth);
    $slf->{'sta'}->{$pth} = join('|', @$sta, "\n");
  }
}

=head2 S<$h-E<gt>set_meta($flag)>

This method specifies whether RDA can store file information in the meta
directory repository. This functionality is disabled when a security filter
is active.

=cut

sub set_meta
{ my ($slf, $flg) = @_;
  my ($old);

  $old = $slf->{'met'};
  $slf->{'met'} = $flg if defined($flg) && !exists($slf->{'flt'});
  $old
}

=head1 SECTION MANAGEMENT METHODS

=head2 S<$h-E<gt>begin_capture>

This method initiates the capture of the table of content lines.

=cut

sub begin_capture
{ shift->{'toc'}->begin_capture;
}

=head2 S<$h-E<gt>begin_section($name,$type)>

This method initiates the treatment of a new section.

=cut

sub begin_section
{ my ($slf, $nam, $typ) = @_;

  # Enable report capture
  $slf->{'_exp'} = [];
  $slf->{'_idx'} = [];
  $slf->{'_sct'} = [];

  # Start table of content output buffering
  $slf->{'toc'}->begin_capture;
}

=head2 S<$h-E<gt>end_section($name,$type,$flag[,prev])>

This method accepts or reject the section.

=cut

sub end_section
{ my ($slf, $nam, $typ, $flg, $prv) = @_;
  my ($abr, $dir, $exp, $idx, $oid, $pth, $rec, $tbl, @det);

  # Create the section record
  $exp = delete($slf->{'_exp'});
  $idx = delete($slf->{'_idx'});
  $tbl = delete($slf->{'_sct'});
  if ($flg)
  { # End section reports
    if ($typ)
    { $rec = {
        lin => $slf->{'toc'}->get_capture,
        nam => $nam,
        rpt => [],
        typ => 'R',
        };

      # End all reports created in the section
      foreach my $rpt (@$tbl)
      { push(@{$rec->{'rpt'}}, join('|', $rpt->get_info('abr'),
          $rpt->get_oid, $rpt->get_info('dir'), $rpt->get_info('fil')))
          if $rpt->is_created;
        $slf->end_report($rpt);
      }
    }
    else
    { $rec = {
        lin => $slf->{'toc'}->get_capture,
        nam => $nam,
        rpt => [],
        typ => 'S',
        };

      # Render all reports created in the section
      foreach my $rpt (@$tbl)
      { if ($rpt->is_created)
        { push(@{$rec->{'rpt'}}, join('|', $rpt->get_info('abr'),
            $rpt->get_oid, $rpt->get_info('dir'),
            $rpt->get_info('fil')));
          $rpt->render;
        }
        else
        { $slf->end_report($rpt);
        }
      }
    }

    # Accept catalog entries
    foreach my $rec (@$exp)
    { ($abr, $oid, $dir, @det) = @$rec;
      push(@{$slf->{'exp'}->{$abr}->{$oid}->{$dir}}, @det);
    }
    foreach my $rec (@$idx)
    { ($abr, $oid, $dir, @det) = @$rec;
      push(@{$slf->{'idx'}->{$abr}->{$oid}->{$dir}}, @det);
    }
  }
  else
  { $rec = {
      lin => [],
      nam => $nam,
      rpt => [],
      typ => 'E',
      };

    # Delete section reports
    foreach my $rpt (@$tbl)
    { $slf->end_report($rpt);
      $pth = $rpt->get_file(1);
      1 while unlink($pth);
      foreach my $pth (@{$rpt->get_info('lst')})
      { 1 while unlink($pth);
      }
      delete($slf->{'als'}->{$rpt->get_oid}->{$rpt->get_info('dir')});
    }
  }

  # Delete previous reports from common sections
  if (ref($prv))
  { foreach my $rpt (@$prv)
    { my ($abr, $dir, $fil, $oid);

      ($abr, $oid, $dir, $fil) = split(/\|/, $rpt, 4);

      # Delete the index entries
      delete($slf->{'als'}->{$oid}->{$dir});
      delete($slf->{'exp'}->{$abr}->{$oid}->{$dir});
      delete($slf->{'idx'}->{$abr}->{$oid}->{$dir});

      # Remove the file
      $fil = RDA::Object::Rda->cat_file($slf->get_path($dir), $fil);
      1 while unlink($fil);
      $fil =~ s/\.(dat|txt)$/.htm/i;
      1 while unlink($fil);
      $fil =~ s/\.htm$/.xml/i;
      1 while unlink($fil);
    }
  }

  # Return the section record
  $rec;
}

=head2 S<$h-E<gt>get_section>

This method gets the content of the capture buffer.

=cut

sub get_section
{ shift->{'toc'}->get_capture,
}

=head2 S<$h-E<gt>load_index($rec,$type)>

This method loads the index tables with previous run information.

=cut

sub load_index
{ my ($slf, $rec, $typ) = @_;
  my ($abr, $dir, $key, $ref, $rev, $rpt, $tbl, @det);

  # Load the alias entries
  $rev = $slf->{'rev'};
  if (exists($rec->{'als'}))
  { $tbl = $slf->{'als'};
    $ref = $typ ? 'C' : 'M';
    foreach my $lin (@{$rec->{'als'}})
    { ($key, $dir, @det) = split(/\|/, $lin);
      next if $dir eq $ref;

      # Define the alias entry
      $tbl->{$key}->{$dir} = join('|', @det);

      # Define the reverse map entry
      next unless exists($tb_sub{$dir});
      $rpt = defined($tb_sub{$dir})
        ? RDA::Object::Rda->cat_file($tb_sub{$dir}, $det[0])
        : $det[0];
      $rpt =~ s/\.(dat|txt)$/.htm/i;
      $rev->{$rpt} = [$key, $dir];
    }
  }

  # Load the Explorer entries
  if (exists($rec->{'exp'}))
  { $abr = $slf->{'abr'};
    $tbl = $slf->{'exp'};
    foreach my $lin (@{$rec->{'exp'}})
    { ($key, $ref) = split(/\|/, $lin, 3);
      if (exists($rev->{$ref}))
      { ($key, $dir) = @{$rev->{$ref}};
        push(@{$tbl->{$abr}->{$key}->{$dir}}, $lin);
        $rev->{$ref}->[2] = $abr;
      }
    }
  }

  # Load the index entries
  if (exists($rec->{'idx'}))
  { $abr = $slf->{'abr'};
    $tbl = $slf->{'idx'};
    foreach my $lin (@{$rec->{'idx'}})
    { ($key, $ref) = split(/\|/, $lin, 3);
      if ($key eq 'A')
      { $abr = $ref;
      }
      if ($key eq 'H')
      { $tbl->{$abr}->{'@'} = $ref;
      }
      elsif (exists($rev->{$ref}))
      { ($key, $dir) = @{$rev->{$ref}};
        push(@{$tbl->{$abr}->{$key}->{$dir}}, $lin);
        $rev->{$ref}->[2] = $abr;
      }
    }
  }

  # Save the file status information entries
  if (exists($rec->{'sta'}))
  { $tbl = $slf->{'sta'};
    foreach my $lin (@{$rec->{'sta'}})
    { ($key, $lin) = split(/\|/, $lin, 2);
      $tbl->{$key} = $lin;
    }
  }
}

=head2 S<$h-E<gt>load_run($oid)>

This method loads the information from the previous run.

=cut

sub load_run
{ my ($slf, $oid) = @_;
  my ($col, $ifh, $par, $pth, $rec);

  # Determine the name of the table of content file
  $pth = $slf->{'grp'}.'_'.$oid.'.toc';
  $pth = lc($pth) unless $slf->{'cas'};
  $pth = RDA::Object::Rda->cat_file($slf->get_path('C'), $pth);
  $ifh = IO::File->new;

  # Load the table of content
  $slf->{'prv'} = $rec = {col => {}, lin => [], typ => 'T'};
  if ($ifh->open("<$pth"))
  { while (<$ifh>)
    { if (m/^#---\[([CEFRS]):(.+)\]---/)
      { if ($1 eq 'R' || $1 eq 'S')
        { $par = $rec;
          push(@{$par->{'lin'}}, $par->{'sct'}->{$2} = $rec =
            {lin=> [], nam => $2, par => $par, rpt => [], typ => $1});
        }
        elsif ($1 eq 'E')
        { push(@{$rec->{'lin'}}, $rec->{'sct'}->{$2} =
            {lin=> [], nam => $2, par => $rec, rpt => [], typ => 'E'});
        }
        elsif ($1 eq 'F')
        { push(@{$rec->{'rpt'}}, $2);
        }
        else
        { $par = $rec;
          push(@{$par->{'lin'}}, $par->{'col'}->{$2} = $rec =
            {lin=> [], nam => $2, par => $par, sct => {}, typ => 'C'});
        }
      }
      elsif (m/^#---\[([ce]:.+)?\]---/)
      { $rec = $rec->{'par'} if exists($rec->{'par'});
      }
      else
      { push(@{$rec->{'lin'}}, $_);
      }
    }
    $ifh->close;
  }

  # Load the alias definitions
  $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
    $slf->{'grp'}.'_'.$oid.'_A.fil');
  if ($ifh->open("<$pth"))
  { $slf->{'prv'}->{'als'} = [$ifh->getlines];
    $ifh->close;
  }

  # Load the file status information entries
  $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
    $slf->{'grp'}.'_'.$oid.'_D.fil');
  if ($ifh->open("<$pth"))
  { $slf->{'prv'}->{'sta'} = [$ifh->getlines];
    $ifh->close;
  }

  # Load the Explorer entries
  $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
    $slf->{'abr'}.'E.fil');
  if ($ifh->open("<$pth"))
  { $slf->{'prv'}->{'exp'} = [$ifh->getlines];
    $ifh->close;
  }

  # Load the index entries
  $pth = RDA::Object::Rda->cat_file($slf->get_path('C', 1),
    $slf->{'grp'}.'_'.$oid.'_I.fil');
  if ($ifh->open("<$pth"))
  { $slf->{'prv'}->{'idx'} = [$ifh->getlines];
    $ifh->close;
  }

  # Return the table of content definition
  $slf->{'prv'};
}

=head2 S<$h-E<gt>save_toc([$rec])>

This method saves a table of content.

=cut

sub save_toc
{ my ($slf, $rec) = @_;
  my ($toc);

  $rec = $slf->{'prv'} unless defined($rec);
  if (ref($toc = $slf->{'toc'}) && ref($rec))
  { # Disable the capture mode
    $toc->end_capture;

    # Save the record lines
    &{$tb_toc{$rec->{'typ'}}}($toc, $rec) if exists($tb_toc{$rec->{'typ'}});
  }
}

sub _save_collect
{ my ($toc, $rec) = @_;

  $toc->write("#---[C:".$rec->{'nam'}."]---\n");
  _save_lines($toc, $rec->{'lin'});
  $toc->write("#---[c:".$rec->{'nam'}."]---\n");
}

sub _save_empty
{ my ($toc, $rec) = @_;

  $toc->write("#---[E:".$rec->{'nam'}."]---\n");
}

sub _save_lines
{ my ($toc, $tbl) = @_;

  foreach my $lin (@$tbl)
  { if (ref($lin))
    { &{$tb_toc{$lin->{'typ'}}}($toc, $lin) if exists($tb_toc{$lin->{'typ'}});
    }
    else
    { $toc->write($lin);
    }
  }
}

sub _save_section
{ my ($toc, $rec) = @_;

  $toc->write("#---[".$rec->{'typ'}.":".$rec->{'nam'}."]---\n");
  _save_lines($toc, $rec->{'lin'});
  foreach my $rpt (@{$rec->{'rpt'}})
  { $toc->write("#---[F:$rpt]---\n");
  }
  $toc->write("#---[e:".$rec->{'nam'}."]---\n");
}

sub _save_top
{ my ($toc, $rec) = @_;

  _save_lines($toc, $rec->{'lin'});
}

=head1 REPORT MANAGEMENT METHODS

=head2 S<$h-E<gt>add_report($type,$name[,$dyn[,$ext]])>

This method creates a new report and returns the corresponding report
object. It supports the following report types:

=over 8

=item B<    'B' > Binary data file

=item B<    'C' > Collection report

=item B<    'D' > Data file

=item B<    'E' > Extern subdirectory report

=item B<    'F' > Collection file

=item B<    'R' > Reference report

=item B<    'S' > Sample report

=back

When the type is in lower case, it does not take it as current report and will
not be closed automatically when it creates a another report.

You can use a same name for multiple reports.

=cut

sub add_report
{ my ($slf, $typ, $nam, $dyn, $ext) = @_;
  my ($flg, $fmt, $oid, $rpt);

  # Validate the arguments
  die "RDA-01033: Reports are not available in this context\n"
    unless $slf->{'typ'} eq 'L';
  if (index('BCDEFRS', $typ) < 0)
  { $typ = uc($typ);
    $flg = 1;
    die "RDA-01034: Invalid report type '$typ'\n"
      if index('BCDEFRS', $typ) < 0;
  }
  $nam =~ s/[_\W]+/_/g;
  die "RDA-01035: Invalid or missing name\n" unless $nam =~ /^[A-Za-z]/;

  # Terminate the current report
  _end_current($slf, delete($slf->{'cur'})) if exists($slf->{'cur'}) && !$flg;

  # Create the report
  $oid = _gen_rpt_oid($slf, 'R');
  $slf->{'rpt'}->{$oid} = $slf->{'lst'} = $rpt = RDA::Object::Report->new($slf,
    $oid, $typ, $slf->{'pre'}, $nam, $dyn, $slf->{'lgt'}, $ext);
  $slf->{'als'}->{$oid}->{$rpt->get_info('dir')} =
    join('|', $rpt->get_info('fil'), $dyn ? '' : $rpt->get_info('nam'), "\n");
  $slf->{'cur'} = $rpt unless $flg;

  # Capture the report
  push(@{$slf->{'_sct'}}, $rpt) if exists($slf->{'_sct'});

  # Return the report reference
  $rpt;
}

sub _end_current
{ my ($slf, $obj) = @_;

  &{$tb_end{ref($obj)}}($slf, $obj);
}

sub _gen_rpt_oid
{ my ($slf, $typ) = @_;

  sprintf('%s_%s_%s%s%05d%s', $slf->{'grp'}, $slf->{'abr'}, $slf->{'pre'}, $typ,
    ++$slf->{'_rpt'}, $slf->{'job'});
}

=head2 S<$h-E<gt>deprefix($blk)>

This method suppresses in all active reports the execution of a code block
contained in the specified block.

=cut

sub deprefix
{ my ($slf, $blk) = @_;

  foreach my $rpt (values(%{$slf->{'rpt'}}))
  { $rpt->deprefix($blk);
  }
}

=head2 S<$h-E<gt>end_report($report)>

This method ends the corresponding report. You can specify the report by its
object reference or its object identifier. It returns the report reference when
the operation is successful. Otherwise, it returns an undefined value.

=cut

sub end_report
{ my ($slf, $oid) = @_;
  my ($abr, $dir, $pid, $rpt, $tbl);

  $oid = $oid->get_oid if ref($oid);
  return undef unless defined($oid)
    && exists($slf->{'rpt'})
    && exists($slf->{'rpt'}->{$oid})
    && ($rpt = $slf->{'rpt'}->{$oid})->is_active;

  # Adjust the current and suspended reports
  delete($slf->{'cur'})
    if exists($slf->{'cur'}) && $slf->{'cur'} == $rpt;
  delete($slf->{'lst'})
    if exists($slf->{'lst'}) && $slf->{'lst'} == $rpt;
  foreach my $nam (keys(%{$tbl = $slf->{'_opn'}}))
  { delete($tbl->{$nam})
      if $tbl->{$nam} == $rpt;
  }

  # Update the reverse mapping and add catalog entries
  $abr = $rpt->get_info('abr');
  $dir = $rpt->get_info('dir');
  $tbl = $rpt->get_info('cat');
  $slf->{'rev'}->{$rpt->get_report} = [$oid, $dir, $abr];
  foreach my $key (keys(%$tbl))
  { if (exists($slf->{"_$key"}))
    { push(@{$slf->{"_$key"}}, [$abr, $oid, $dir, @{$tbl->{$key}}]);
    }
    else
    { push(@{$slf->{$key}->{$abr}->{$oid}->{$dir}}, @{$tbl->{$key}});
    }
  }

  # Delete any share definition if the file has not been created
  unless (defined($rpt->is_created))
  { foreach my $abr (keys(%{$slf->{'def'}}))
    { delete($slf->{'def'}->{$abr}->{$oid});
    }
  }

  # Store any remaining asynchronous subprocess
  if ($rpt->get_info('aft'))
  { $rpt->wait;
  }
  else
  { $slf->{'pid'}->{$pid} = 1 if ($pid = $rpt->set_info('pid'));
  }

  # End the report
  $rpt->end;
}

=head2 S<$h-E<gt>get_link($report[,$module[,$flag]])>

This method returns the link that is associated with the specified report. It
is possible to refer to another module. When the flag is set, it adjusts the
link for multi-run collections.

=cut

sub get_link
{ my ($slf, $rpt, $mod, $flg) = @_;
  my ($lnk);

  $lnk = ($mod && $mod =~ $RE_MOD)
    ? $slf->{'grp'}.'_'.$1.'_'.$rpt.'.htm'
    : $slf->{'grp'}.'_'.$slf->{'abr'}.'_'.$rpt.'.htm';
  $lnk = $tb_sub{'M'}.'/'.$lnk if $flg && $slf->{'mrc'};
  $slf->{'cas'} ? $lnk : lc($lnk);
}

=head2 S<$h-E<gt>get_name($type,$file)>

This method returns the report name.

=cut

sub get_name
{ my ($slf, $typ, $fil) = @_;
  my ($lnk);

  $lnk = (exists($tb_sub{$typ}) && defined($tb_sub{$typ}))
    ? $tb_sub{$typ}.'/'.$fil
    : $fil;
  $slf->{'cas'} ? $lnk : lc($lnk);
}

=head2 S<$h-E<gt>purge($type,$re,$day[,$sec[,flag]])>

This method removes all files that match the regular expression and that are
older than the specified age from the specified report subdirectory. Unless
the type is in lower case, the regular expression is automatically prefixed
with the report group and the current abbreviation. Valid subdirectory types
are:

=over 7

=item B<    C > For the output/report directory itself

=item B<    E > For the C<extern> subdirectory

=item B<    M > For the multi-run collections (C<mrc> subdirectory)

=item B<    P > For the remote packages (C<remote> subdirectory)

=item B<    R > For the C<ref> subdirectory

=item B<    S > For the C<sample> subdirectory

=back

When the flag is set, it creates a missing directory.

It returns the number of removed files.

=cut

sub purge
{ my ($slf, $typ, $re, $day, $sec, $flg) = @_;
  my ($cnt, $dir, $fil, $key, $ref);

  $cnt = 0;
  if ($typ && $re && defined($day) && exists($tb_sub{$key = uc($typ)}))
  { $dir = $slf->get_path($key);
    if (opendir(DIR, $dir))
    { $sec = 0 unless defined($sec);
      $ref = time - $day * 86400 - $sec;
      $re  = ($typ eq $key)
        ? qr#^$slf->{'grp'}_$slf->{'abr'}_$re#i
        : qr#$re#i;
      foreach my $nam (readdir(DIR))
      { next unless $nam =~ $re;
        $fil = RDA::Object::Rda->cat_file($dir, $nam);
        next unless RDA::Object::Rda->get_last_modify($fil, $ref) < $ref;
        ++$cnt while unlink($fil);
      }
      closedir(DIR);
    }
    elsif ($flg)
    { $slf->get_path($key, 1);
    }
  }
  $cnt;
}

=head1 REPORT SHARING METHODS

=head2 S<$h-E<gt>add_share($report,$group,$link)>

This method shares the current report and adds it in the specified group with
the specified link text. It returns a true value when the operation is
successful. Otherwise, it returns a false value.

=cut

sub add_share
{ my ($slf, $oid, $gid, $lnk) = @_;
  my ($abr, $def, $rpt);

  die "RDA-01024: Invalid request in a multi-run collection section\n"
    if exists($slf->{'_sct'});

  $abr = $slf->{'abr'};
  $oid = $oid->get_oid if ref($oid);
  return 0 unless  $gid && $lnk && exists($slf->{'rpt'})
    && exists($slf->{'rpt'}->{$oid})
    && !exists($slf->{'def'}->{$abr}->{$oid}->{$gid});
  $rpt = $slf->{'rpt'}->{$oid};
  $gid =~ s/[_\W]+/_/g;
  $lnk =~ s/[\|\n\r\s]+/ /g;
  push(@{$slf->{'shr'}->{$abr}}, $slf->{'def'}->{$abr}->{$oid}->{$gid} =
    [$gid,
     $oid,
     $slf->{'oid'},
     $rpt->get_info('dir'),
     $rpt->get_info('nam'),
     $rpt->get_info('ext'),
     $rpt->get_info('fmt'),
     $rpt->get_info('fil'),
     $slf->filter($lnk)]);
  1;
}

=head2 S<$h-E<gt>find_shares($group,$module...)>

This method returns the identifiers of all shared files that belong to the
specified group. It only searches the specified modules.

=cut

sub find_shares
{ my ($slf, $gid, @mod) = @_;
  my ($cnt, $def, $ifh, @rec, @tbl);

  if ($gid && exists($slf->{'shr'}))
  { $gid =~ s/[_\W]+/_/g;
    foreach my $mod (@mod)
    { # Load the module sharing definitions
      if (exists($slf->{'shr'}->{$mod}))
      { $def = $slf->{'shr'}->{$mod};
      }
      else
      { $slf->{'shr'}->{$mod} = $def = [];
        $ifh = IO::File->new;
        if ($ifh->open('<'.RDA::Object::Rda->cat_file($slf->get_path('C'),
          $slf->{'grp'}.'_'.$mod.'_S.fil')))
        { while (<$ifh>)
          { @rec = split(/\|/, $_);
            pop(@rec);
            push(@$def, [@rec]);
          }
          $ifh->close;
        }
      }

      # Search for shared files
      $cnt = 0;
      foreach my $rec (@$def)
      { push(@tbl, "$mod:$cnt") if $gid eq $rec->[0];
        ++$cnt;
      }
    }
  }
  @tbl;
}

=head2 S<$h-E<gt>get_share($oid)>

This method returns the link text of the specified shared file.

=cut

sub get_share
{ my ($slf, $oid) = @_;
  my ($mod, $off);

  return undef unless $oid;
  ($mod, $off) = split(/\:/, $oid);
  (exists($slf->{'shr'})
    && exists($slf->{'shr'}->{$mod}) && ref($slf->{'shr'}->{$mod}->[$off]))
    ? $slf->{'shr'}->{$mod}->[$off]->[$SHR_LNK]
    : undef;
}

=head2 S<$h-E<gt>set_share($oid[,$flag])>

This method creates a link inside the current module to the specified shared
file. It returns the report file name when the operation is
successful. Otherwise, it returns an undefined value.

When the flag is set, it preserves the original file extension.

=cut

sub set_share
{ my ($slf, $oid, $flg) = @_;
  my ($abr, $def, $dir, $dst, $fil, $mod, $off, $ret, $src);

  # Get the sharing definition record
  return undef unless $oid;
  ($mod, $off) = split(/\:/, $oid);
  return undef unless exists($slf->{'shr'})
    && exists($slf->{'shr'}->{$mod}) && ref($slf->{'shr'}->{$mod}->[$off]);
  $def = $slf->{'shr'}->{$mod}->[$off];

  # Check if the file exists
  $dir = $slf->get_path($def->[$SHR_DIR]);
  $fil = $def->[$SHR_FIL];
  return undef
    unless -f ($src = RDA::Object::Rda->cat_file($dir, $fil));

  # Link the file when referencing a report from another module
  $abr = $slf->{'abr'};
  if ($mod ne $abr)
  { if (exists($slf->{'dup'}->{$abr}->{$def->[$SHR_OID]}))
    { $fil = $slf->{'dup'}->{$abr}->{$def->[$SHR_OID]};
    }
    else
    { $fil = _gen_rpt_oid($slf, 'L');
      $fil .= substr('_'.$def->[$SHR_NAM], 0, $slf->{'lgt'})
        if $def->[$SHR_FMT];
      $fil .= $def->[$SHR_EXT];
      $fil = lc($fil) unless $slf->{'cas'};
      unless (-f ($dst = RDA::Object::Rda->cat_file($dir, $fil)))
      { eval {$ret = link($src, $dst)};
        eval {$ret = copy($src, $dst)} unless $ret || !$slf->{'emu'};
        return undef unless $ret;
      }
      $slf->{'dup'}->{$abr}->{$def->[$SHR_OID]} = $fil;
    }
  }

  # Return the file name
  $fil =~ s/\.(dat|txt)$/.htm/i unless $flg;
  defined($tb_sub{$def->[$SHR_DIR]})
    ? RDA::Object::Rda->cat_file($tb_sub{$def->[$SHR_DIR]}, $fil)
    : $fil;
}

=head1 SPACE MANAGEMENT METHODS

=head2 S<$h-E<gt>check_free($size)>

This method checks whether enough disk space is free after consuming the
specified size. It raises an error when that is no longer true.

=cut

sub check_free
{ my ($slf, $siz, $flg) = @_;

  &{$slf->{$flg ? '_dff' : '_dfr'}}($slf, $siz);
}

sub _chk_free
{ my ($slf, $val) = @_;

  # Determine the test function
  if ($val > 0)
  { $slf->{'_dfm'} = int(1048576 * $val);
    if (RDA::Object::Rda->is_unix || RDA::Object::Rda->is_cygwin)
    { return _set_free($slf) if defined(_ini_free_unix($slf));
    }
    elsif (RDA::Object::Rda->is_windows)
    { return _set_free($slf) if defined(_ini_free_dos($slf));
    }
  }

  # No check by default
  $slf->{'_dff'} = $slf->{'_dfr'} = \&_chk_free_none;
  $slf->{'_dfm'} = 0;
}

sub _chk_free_dos
{ my ($slf, $siz) = @_;
  my ($val, @tbl);

  @tbl = `cmd /C dir /-C $slf->{'_dfp'}`;
  foreach my $lin (@tbl)
  { next unless $lin =~ m/^\s*0\s.*\s(\d+)\s[^\d]+$/;
    $slf->{'_dfa'} = $val = $1 - $slf->{'_dfm'} - $siz;
    die "RDA-01029: Not enough free space for running RDA\n" if $val < 0;
    return $val;
  }
  undef;
}

sub _chk_free_hpux
{ my ($slf, $siz) = @_;
  my ($val, @tbl);

  @tbl = `df -k $slf->{'_dfp'}`;
  foreach my $lin (@tbl)
  { next unless $lin =~ m/\s(\d+)\s+free allocated Kb/;
    $slf->{'_dfa'} = $val = 1024 * $1 - $slf->{'_dfm'} - $siz;
    die "RDA-01029: Not enough free space for running RDA\n" if $val < 0;
    return $val;
  }
  undef;
}

sub _chk_free_none
{ undef;
}

sub _chk_free_unix
{ my ($slf, $siz) = @_;
  my ($val, @tbl);

  @tbl = `df -k $slf->{'_dfp'}`;
  foreach my $lin (@tbl)
  { next unless $lin =~ m/\s(\d+)\s+\d+\%\s/;
    $slf->{'_dfa'} = $val = 1024 * $1 - $slf->{'_dfm'} - $siz;
    die "RDA-01029: Not enough free space for running RDA\n" if $val < 0;
    return $val;
  }
  undef;
}

sub _ini_free_dos
{ my ($slf) = @_;

  $slf->{'_dff'} = \&_chk_free_dos;
  $slf->{'_dfp'} = RDA::Object::Rda->quote(RDA::Object::Rda->cat_file(
    $slf->get_path('C', 1), 'RDA.log'));
  &{$slf->{'_dff'}}($slf, 0);
}

sub _ini_free_unix
{ my ($slf) = @_;

  $slf->{'_dff'} = ($^O eq 'hpux') ? \&_chk_free_hpux : \&_chk_free_unix;
  $slf->{'_dfp'} = RDA::Object::Rda->quote($slf->get_path('C', 1));
  &{$slf->{'_dff'}}($slf, 0);
}

sub _set_free
{ my ($slf) = @_;

  $slf->{'_dfr'} = ($slf->{'_dft'} eq 'E') ? $slf->{'_dff'} = \&_chk_free_none :
                   ($slf->{'_dft'} eq 'R') ? $slf->{'_dff'} :
                                             \&_chk_free_none;
}

=head2 S<$h-E<gt>check_space>

This method indicates whether the disk space consumed by the module reports is
within the specified limit. It always returns zero when the space quota is
disabled.

=cut

sub check_space
{ my ($slf) = @_;

  # Skip the test when there is no limit
  return 0 unless exists($slf->{'_spc'});

  # Update the space consumed
  foreach my $rpt (values(%{$slf->{'rpt'}}))
  { $rpt->update;
  }

  # Return the space margin
  $slf->{'_spc'} - $slf->{'spc'};
}

=head2 S<$h-E<gt>decr_free($size[,$flag])>

This method decreases the estimated free disk space. Unless the flag is set, it
raises an error instead of returning a false value when free space is not
sufficient.

=cut

sub decr_free
{ my ($slf, $siz, $flg) = @_;
  
  $slf->{'_dfa'} -= $siz if $slf->{'_dfm'};
  return 1 unless $slf->{'_dfa'} < 0;
  return 0 if $flg;
  die "RDA-01029: Not enough free space for running RDA\n";
}

=head2 S<$h-E<gt>test_free($size[,$flag])>

This method indicates whether the specified space is still available from the
estimated free disk space. Unless the flag is set, it raises an error instead
of returning a false value when free space is not sufficient.

=cut

sub test_free
{ my ($slf, $siz, $flg) = @_;
  
  return 1 unless $siz > $slf->{'_dfa'} && $slf->{'_dfm'};
  return 0 if $flg;
  die "RDA-01029: Not enough free space for running RDA\n";
}

=head2 S<$h-E<gt>update_space>

This method adds a report contribution to the total space consumed.

=cut

sub update_space
{ my ($slf, $siz) = @_;

  $slf->{'spc'} += $siz;
}

=head1 TEMPORARY FILE MANAGEMENT METHODS

=head2 S<$h-E<gt>add_temp($name[,$ext[,$flag]])>

This method creates a new temporary file. You can specify the file extension as
an argument. C<.tmp> is used as default file extension. When the flag is set,
it makes the file executable when the file is closed.

It returns the corresponding object.

=cut

sub add_temp
{ my ($slf, $nam, $ext, $flg) = @_;
  my ($oid);

  die "RDA-01036: Temporary files are not available in this context\n"
    unless $slf->{'typ'} eq 'L';
  die "RDA-01035: Invalid or missing name\n" unless $nam =~ /^[A-Za-z]/;
  $nam =~ s/[_\W]+/_/g;
  $oid = sprintf('%s_%s_T%05d_%02d%s', $slf->{'grp'}, $slf->{'abr'}, $$,
    ++$slf->{'_tmp'}, $slf->{'job'});
  $slf->{'tmp'}->{$oid} = RDA::Object::Report->new($slf, $oid, 'T', '',
    $nam, 0, $slf->{'lgt'}, $ext, $flg);
}

=head2 S<$h-E<gt>end_temp($temp)>

This method ends the corresponding temporary file. You can specify the
temporary file by its object reference or its object identifier. It returns a
the report reference when the operation is successful. Otherwise, it returns
an undefined value.

=cut

sub end_temp
{ my ($slf, $oid) = @_;

  $oid = $oid->get_oid if ref($oid);
  (defined($oid) && exists($slf->{'tmp'}) && exists($slf->{'tmp'}->{$oid}))
    ? $slf->{'tmp'}->{$oid}->end
    : undef;
}

=head1 COMMAND PIPE MANAGEMENT METHODS

=head2 S<$h-E<gt>add_pipe($command)>

This method creates a pipe to the specified command. It returns a reference to
the corresponding object.

=cut

sub add_pipe
{ my ($slf, $cmd) = @_;
  my ($oid);

  die "RDA-01037: Pipes are not available in this context\n"
    unless $slf->{'typ'} eq 'L';
  die "RDA-01038: Missing command\n" unless $cmd;

  # Terminate the current report
  _end_current($slf, delete($slf->{'cur'})) if exists($slf->{'cur'});

  # Create the new pipe
  $oid = sprintf('%s_%s_P%05d_%02d%s', $slf->{'grp'}, $slf->{'abr'}, $$,
    ++$slf->{'_pip'}, $slf->{'job'});
  $slf->{'pip'}->{$oid} = $slf->{'lst'} = $slf->{'cur'} =
    RDA::Object::Pipe->new($slf, $oid, $cmd);
}

=head2 S<$h-E<gt>end_pipe($pipe)>

This method closes the corresponding pipe. You can specify the pipe object by
its reference or its object identifier. It returns a the pipe object reference
when the operation is successful. Otherwise, it returns an undefined value.

=cut

sub end_pipe
{ my ($slf, $oid) = @_;
  my ($obj, $tbl);

  $oid = $oid->get_oid if ref($oid);
  return undef unless defined($oid)
    && exists($slf->{'pip'}) && exists($slf->{'pip'}->{$oid});
  $obj = $slf->{'pip'}->{$oid};

  # Adjust the current and suspended reports
  delete($slf->{'cur'})
    if exists($slf->{'cur'}) && $slf->{'cur'} == $obj;
  delete($slf->{'lst'})
    if exists($slf->{'lst'}) && $slf->{'lst'} == $obj;
  foreach my $nam (keys(%{$tbl = $slf->{'_opn'}}))
  { delete($tbl->{$nam})
      if $tbl->{$nam} == $obj;
  }

  # Close the pipe
  $obj->close;
}

=head1 WORK FILE MANAGEMENT METHODS

=head2 S<$h-E<gt>clean_work($type)>

This method tries to remove the current work file. When it cannot remove the
file, it disables further usage of that file.

=cut

sub clean_work
{ my ($slf, $typ) = @_;
  my ($pth);

  $typ = 'tmp' unless defined($typ);
  if (exists($slf->{'wrk'}) & exists($slf->{'wrk'}->{$typ}))
  { $pth = $slf->{'_cln'}->{$slf->{'wrk'}->{$typ}};
    1 while unlink($pth);
    delete($slf->{'wrk'}->{$typ}) if -e $pth;
  }
}

=head2 S<$h-E<gt>get_work($type[,$flag])>

This method returns the path to the corresponding work file. When the flag is
set, it forces the creation of the directory.

=cut

sub get_work
{ my ($slf, $typ, $flg) = @_;
  my ($oid);

  die "RDA-01039: Work files are not available in this context\n"
    unless $slf->{'typ'} eq 'G';

  $typ = 'tmp' unless defined($typ);
  return $slf->{'_cln'}->{$slf->{'wrk'}->{$typ}}
    if exists($slf->{'wrk'}->{$typ});

  $slf->{'wrk'}->{$typ} = $oid =
    sprintf("%s_W%05d_%02d", $slf->{'oid'}, $$, ++$slf->{'_wrk'});
  $slf->{'_cln'}->{$oid} =
    RDA::Object::Rda->cat_file($slf->get_path('T', $flg), $oid.'_'.$typ);
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the local report control
sub _begin_control
{ my ($pkg) = @_;
  my ($out);

  $out = $pkg->get_agent->get_output->new($pkg);
  $pkg->set_info('rpt', $out);
  $pkg->set_info('out', 1) if exists($out->{'rnd'});
  $pkg->define('$[OUT]', $out);
}

# Close all active reports
sub _end_control
{ my ($pkg) = @_;
  my ($tim);

  $tim = $pkg->get_info('beg');
  $pkg->set_info('rpt')->delete(defined($tim) ? time - $tim : undef);
}

# Define the parse methods
sub _get_data
{ _parse_output(['>', 'D'], @_);
}

sub _get_list
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->parse_list($str);
}

sub _get_name
{ my ($slf, $spc, $str) = @_;

  die "RDA-00215: Invalid or missing name\n"
    unless $$str =~ s/^([A-Za-z]\w*)\s*//;
  $spc->[$SPC_REF] = $1;
}

sub _get_output
{ my ($slf, $spc, $str) = @_;
  my ($mod);

  $mod = ($$str =~ s/^(>+|\|)\s*//) ? $1 : '>';
  if ($mod eq '|')
  { _parse_output('P', @_);
  }
  else
  { _parse_output([$mod, ($$str =~ s/^([BCDEFRS])\s*,\s*//i) ? $1 : 'C'], @_);
  }
}

sub _get_report
{ _parse_output(['>', 'C'], @_);
}

sub _parse_output
{ my ($val, $slf, $spc, $str) = @_;
  my ($rec);

  if ($$str =~ s/^([A-Za-z]\w+)\s*(#.*)?$//)
  { $spc->[$SPC_REF] = $1;
  }
  elsif (ref($rec = $slf->parse_value($str)))
  { $spc->[$SPC_REF] = $rec;
  }
  else
  { die "RDA-00215: Invalid or missing name\n"
  }
  $spc->[$SPC_VAL] = $val;
}

# Specify a new report, closing the current one
sub _exe_report
{ my ($slf, $spc) = @_;
  my ($dyn, $ext, $mod, $nam, $obj, $typ);

  if (ref($spc->[$SPC_VAL]))
  { # Add a new report
    ($mod, $typ) = @{$spc->[$SPC_VAL]};
    if (ref($nam = $spc->[$SPC_REF]))
    { $nam = $nam->eval_as_string;
      $ext = $1
        if $typ =~ m/^[BDEMSR]$/i
        && $nam =~ s/(\.(box|csv|dat|gif|htm|jar|log|png|tmp|txt|xml|zip))$//;
      $dyn = 1;
    }
    $obj = $slf->get_output->add_report($typ, $nam, $dyn, $ext);
    $obj->set_info('eof', 1) if $mod eq '>>';
  }
  else
  { # Add a new pipe
    $nam = $nam->eval_as_string
      if ref($nam = $spc->[$SPC_REF]) && !$nam->is_code(1);
    $obj = $slf->get_output->add_pipe($nam);
  }

  # Indicate the successful completion
  $CONT;
}

# Resume the output to a report
sub _exe_resume
{ my ($slf, $spc) = @_;
  my ($cur, $out);

  # Close the current report file and suppress any prefix block
  $out = $slf->get_output;
  _end_current($out, delete($out->{'cur'})) if exists($out->{'cur'});

  # Restore the report file
  $out->{'cur'} = $cur
    if ($cur = delete($out->{'_opn'}->{$spc->[$SPC_REF]}));

  # Indicate the successful completion
  $CONT;
}

# Share a report between modules
sub _exe_share
{ my ($slf, $spc) = @_;
  my ($gid, $lnk, $out);

  # Share the file
  $out = $slf->get_output;
  die "RDA-00201: Report file not specified\n" unless exists($out->{'cur'});
  ($gid, $lnk) = @{$spc->[$SPC_VAL]};
  $out->add_share($out->{'cur'}, $gid->eval_as_string, $lnk->eval_as_string)
    if ref($gid) && ref($lnk);

  # Indicate the successful completion
  $CONT;
}

# Suspend the output to the current report
sub _exe_suspend
{ my ($slf, $spc) = @_;
  my ($out);

  $out = $slf->get_output;
  $out->{'_opn'}->{$spc->[$SPC_REF]} = delete($out->{'cur'})
    if exists($out->{'cur'});

  # Indicate the successful completion
  $CONT;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Handle::Filter|RDA::Handle::Filter>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Pipe|RDA::Object::Pipe>,
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
