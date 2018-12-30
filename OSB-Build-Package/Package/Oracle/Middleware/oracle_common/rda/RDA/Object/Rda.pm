# Rda.pm: Class Used for Managing the RDA Software Configuration

package RDA::Object::Rda;

# $Id: Rda.pm,v 2.22 2012/04/25 06:40:44 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Rda.pm,v 2.22 2012/04/25 06:40:44 mschenke Exp $
#
# Change History
# 20120422  MSC  Add the get_input method.

=head1 NAME

RDA::Object::Rda - Class Used for Managing the RDA Software Configuration

=head1 SYNOPSIS

require RDA::Object::Rda;

=head1 DESCRIPTION

This package is designed to manage the RDA software configuration. It is a
subclass of L<RDA::Object|RDA::Object>.

It supports RDA operations commonly performed on file names also. Since these
functions are different for most operating systems, each set of operating
system-specific routines is available in a separate module, including:

=over 4

=item S<    L<RDA::Local::Cygwin|RDA::Local::Cygwin>>

=item S<    L<RDA::Local::Unix|RDA::Local::Unix>>

=item S<    L<RDA::Local::Vms|RDA::Local::Vms>>

=item S<    L<RDA::Local::Windows|RDA::Local::Windows>>

=back

The module appropriate for the current operating system is automatically loaded
by C<RDA::Object::Rda>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Cwd;
  use Exporter;
  use File::Basename;
  use RDA::Object;
}

# Determine which platform-specific package must be loaded
my %tb_fam = (
  'aix'        => 'Unix',
  'bsdos'      => 'Unix',
  'cygwin'     => 'Cygwin',
  'darwin'     => 'Unix',
  'dec_osf'    => 'Unix',
  'dgux'       => 'Unix',
  'dynixptx'   => 'Unix',
  'freebsd'    => 'Unix',
  'hpux'       => 'Unix',
  'irix'       => 'Unix',
  'linux'      => 'Unix',
  'MSWin32'    => 'Windows',
  'MSWin64'    => 'Windows',
  'next'       => 'Unix',
  'openbsd'    => 'Unix',
  'svr4'       => 'Unix',
  'sco_sv'     => 'Unix',
  'solaris'    => 'Unix',
  'sunos'      => 'Unix',
  'VMS'        => 'Vms',
  'Windows_NT' => 'Windows',
  );
my %tb_fnd = (
  Cygwin  => \&_find_windows,
  Unix    => \&_find_unix,
  Vms     => \&_find_vms,
  Windows => \&_find_windows,
  );
my %tb_lib = (
  'aix'    => ['LIBPATH'],
  'darwin' => ['DYLD_LIBRARY_PATH'],
  'hpux'   => ['SHLIB_PATH', 'LD_LIBRARY_PATH'],
  'unix'   => ['LD_LIBRARY_PATH'],
  );
my $mod = $tb_fam{$^O} || 'Unix';

# Define the global public variables
use vars qw($APPEND $CREATE $DIR_PERMS $EXE_PERMS $FIL_PERMS $TMP_PERMS
            $RE_MOD $RE_TST $VERSION @ISA @EXPORT_OK %SDCL);
require "RDA/Local/$mod.pm";
$VERSION   = sprintf("%d.%02d", q$Revision: 2.22 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw($APPEND $CREATE $DIR_PERMS $EXE_PERMS $FIL_PERMS $TMP_PERMS
                $RE_MOD $RE_TST);
@ISA       = ("RDA::Local::$mod", "RDA::Object", "Exporter");
%SDCL      = (
  als => {
    'curDir'       => ['$[RDA]', 'current_dir'],
    'findCommand'  => ['$[RDA]', 'find'],
    'getFamily'    => ['$[RDA]', 'get_family'],
    'getGmTime'    => ['$[RDA]', 'get_gmtime'],
    'getGroup'     => ['$[RDA]', 'get_group'],
    'getGroupDir'  => ['$[RDA]', 'get_dir'],
    'getGroupFile' => ['$[RDA]', 'get_file'],
    'getLists'     => ['$[RDA]', 'get_lists'],
    'getLocalTime' => ['$[RDA]', 'get_localtime'],
    'getModule'    => ['$[RDA]', 'get_module'],
    'getModules'   => ['$[RDA]', 'get_modules'],
    'getOsName'    => ['$[RDA]', 'get_os'],
    'getPid'       => ['$[RDA]', 'get_pid'],
    'getTimeStamp' => ['$[RDA]', 'get_timestamp'],
    'getTools'     => ['$[RDA]', 'get_tests'],
    'isAbsolute'   => ['$[RDA]', 'is_absolute'],
    'isCygwin'     => ['$[RDA]', 'is_cygwin'],
    'isUnix'       => ['$[RDA]', 'is_unix'],
    'isVms'        => ['$[RDA]', 'is_vms'],
    'isWindows'    => ['$[RDA]', 'is_windows'],
    'testRda'      => ['$[RDA]', 'check'],
    'uname'        => ['$[RDA]', 'uname'],
    'user'         => ['$[RDA]', 'get_user'],
    'upDir'        => ['$[RDA]', 'up_dir'],
     },
  beg => \&_begin_rda,
  glb => ['$[RDA]'],
  inc => [qw(RDA::Object)],
  met => {
    'arg_dir'       => {ret => 0},
    'arg_file'      => {ret => 0},
    'as_bat'        => {ret => 0},
    'as_cmd'        => {ret => 0},
    'as_exe'        => {ret => 0},
    'cat_dir'       => {ret => 0},
    'cat_file'      => {ret => 0},
    'check'         => {ret => 0},
    'clean_dir'     => {ret => 0},
    'clean_group'   => {ret => 0},
    'clean_path'    => {ret => 0},
    'create_dir'    => {ret => 0},
    'create_group'  => {ret => 0},
    'current_dir'   => {ret => 0},
    'delete_dir'    => {ret => 0},
    'delete_group'  => {ret => 0},
    'find'          => {ret => 0},
    'get_build'     => {ret => 0},
    'get_columns'   => {ret => 0},
    'get_dir',      => {ret => 0},
    'get_domain'    => {ret => 0},
    'get_family'    => {ret => 0},
    'get_file'      => {ret => 0},
    'get_gmtime'    => {ret => 0},
    'get_group'     => {ret => 0},
    'get_host'      => {ret => 0},
    'get_info'      => {ret => 0},
    'get_lists'     => {ret => 0},
    'get_localtime' => {ret => 0},
    'get_login'     => {ret => 0},
    'get_module'    => {ret => 0},
    'get_modules'   => {ret => 1},
    'get_node'      => {ret => 0},
    'get_obsolete'  => {ret => 1},
    'get_os'        => {ret => 0},
    'get_path'      => {ret => 1},
    'get_pid'       => {ret => 0},
    'get_separator' => {ret => 0},
    'get_timestamp' => {ret => 0},
    'get_title'     => {ret => 0},
    'get_tests'     => {ret => 1},
    'get_tz'        => {ret => 1},
    'get_user'      => {ret => 0},
    'get_value'     => {ret => 0},
    'get_version'   => {ret => 0},
    'is_absolute'   => {ret => 0},
    'is_cygwin'     => {ret => 0},
    'is_root_dir'   => {ret => 0},
    'is_unix'       => {ret => 0},
    'is_vms'        => {ret => 0},
    'is_windows'    => {ret => 0},
    'kill_child'    => {ret => 0},
    'native'        => {ret => 0},
    'quote'         => {ret => 0},
    'set_domain'    => {ret => 0},
    'set_info'      => {ret => 0},
    'short'         => {ret => 0},
    'split_dir'     => {ret => 1},
    'split_volume'  => {ret => 1},
    'uname'         => {ret => 0},
    'up_dir'        => {ret => 0},
    },
  );

# Define file modes
$APPEND = '>>';
$CREATE = '>';
eval {
  require Fcntl;
  $APPEND = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_APPEND();
  $CREATE = Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_TRUNC();
  };

# Define default permissions
$DIR_PERMS = 0750;
$EXE_PERMS = 0700;
$FIL_PERMS = 0640;
$TMP_PERMS = 0600;

# Define the module patterns
$RE_MOD = qr/^S\d{3}([A-Z][A-Z\d]*)$/i;
$RE_TST = qr/^(TL|TM|TST)(\w+)$/i;

# Define the global private variables
my $re_mod = qr/^S(\d{3})([A-Za-z]\w*)\.(ctl|def)$/i;

my @tb_mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my %tb_dir = (
  dft => {D_RDA_ADM  => ['modules'],
          D_RDA_CODE => ['modules'],
          D_RDA_DATA => ['modules'],
          D_RDA_DFW  => ['dfw'],
          D_RDA_HCVE => ['hcve'],
          D_RDA_HTML => ['modules'],
          D_RDA_PERL => [],
          D_RDA_POD  => ['modules'],
          D_RDA_XML  => ['modules'],
         },
  izu => {D_RDA_ADM  => ['modules'],
          D_RDA_CODE => ['modules'],
          D_RDA_DATA => ['modules'],
          D_RDA_DFW  => ['dfw'],
          D_RDA_HCVE => [RDA::Object::Rda->up_dir, 'html'],
          D_RDA_HTML => [RDA::Object::Rda->up_dir, 'html'],
          D_RDA_PERL => [RDA::Object::Rda->up_dir, 'perl'],
          D_RDA_POD  => [RDA::Object::Rda->up_dir, 'perl', 'Pod'],
          D_RDA_XML  => [RDA::Object::Rda->up_dir, 'html'],
         },
  );
my %tb_fct = (
  BUILD     => \&get_build,
  COLUMNS   => \&get_columns,
  CYGWIN    => 'is_cygwin',
  DOMAIN    => \&get_domain,
  ENGINE    => \&check,
  FAMILY    => \&get_family,
  GMTIME    => \&get_gmtime,
  HOST      => \&get_host,
  LOCALTIME => \&get_localtime,
  LOGIN     => 'get_login',
  MACHINE   => \&get_node,
  NODE      => \&get_node,
  OS        => \&get_os,
  PID       => \&get_pid,
  SEPARATOR => 'get_separator',
  TIMESTAMP => \&get_timestamp,
  TZ        => \&get_tz,
  UNIX      => 'is_unix',
  USER      => 'get_user',
  VERSION   => \&get_version,
  VMS       => 'is_vms',
  WINDOWS   => 'is_windows',
  );
my %tb_sys = (
  's' => 0,
  'n' => 1,
  'r' => 2,
  'v' => 3,
  'm' => 4,
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Rda-E<gt>new($agent)>

This method converts the RDA software configuration hash into an object.

C<RDA::Object::Rda> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'aux' > > Reference to an auxiliary object

=item S<    B<'def' > > List of predefined properties

=item S<    B<'dyn' > > Dynamic work directory indicator

=item S<    B<'oid' > > Agent object identifier

=item S<    B<'typ' > > Software configuration type

=item S<    B<'_abr'> > Abbreviation hash

=item S<    B<'_bld'> > Current software build

=item S<    B<'_chk'> > Engine check indicator

=item S<    B<'_cnt'> > Counter hash

=item S<    B<'_con'> > Reference to DOS console object

=item S<    B<'_dom'> > Local domain

=item S<    B<'_eng'> > Current engine build

=item S<    B<'_fam'> > Operating system family

=item S<    B<'_log'> > Login name

=item S<    B<'_mod'> > Data collection module hash

=item S<    B<'_nod'> > Local node name

=item S<    B<'_obs'> > Obsolete object hash

=item S<    B<'_osn'> > Operating system name

=item S<    B<'_tls'> > Tools hash

=item S<    B<'_tst'> > Test module hash

=item S<    B<'_txt'> > Text control object reference

=item S<    B<'_usr'> > User name

=item S<    B<'_ver'> > Software version

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf, $val, %dir);

  # Convert the configuration hash into an object
  $slf = $agt->get_config;
  bless $slf, $cls;

  # Normalize all directories
  foreach my $key (keys(%$slf))
  { $slf->{$key} = $slf->clean_path($slf->{$key}) if $key =~ m/^D_/;
  }

  # Initialize extra attributes
  $slf->{'def'} = [grep {m/^[A-Z]_/} sort keys(%$slf)];
  $slf->{'oid'} = $agt->get_oid;
  $slf->{'typ'} = 'dft' unless exists($slf->{'typ'});

  $slf->{'_fam'} = exists($tb_fam{$^O}) ? $tb_fam{$^O} : $^O;
  $slf->{'_osn'} = $^O;

  # Initialize extra attributes
  $slf->{'RDA_CASE'} =
    exists($ENV{'RDA_CASE'}) ? $ENV{'RDA_CASE'} : $^O ne 'VMS'
    unless exists($slf->{'B_CASE'});
  $slf->{'RDA_BASENAME'} = ($^O eq 'VMS') ? 38 : 64
    unless exists($slf->{'RDA_BASENAME'});
  $slf->{'RDA_COLUMNS'} = exists($ENV{'COLUMNS'}) ? $ENV{'COLUMNS'} - 2 : 78
    unless exists($slf->{'RDA_COLUMNS'});

  # Determine the machine name
  $slf->{'_nod'} = 'localhost';
  $slf->{'_dom'} = undef;
  eval {
    require Sys::Hostname;
    $val = Sys::Hostname::hostname();
    ($slf->{'_nod'}, $slf->{'_dom'}) = ($1, $3)
      if $val && $val =~ m/^([^\.]+)(\.(.*))?$/;
  };

  # Adjust RDA context
  if (exists($ENV{'RDAPERL'}))
  { %dir = map {$_ => 1} @INC;
    foreach my $dir (split($slf->get_separator, $ENV{'RDAPERL'}))
    { unshift(@INC, $dir) if -d $dir && !exists($dir{$dir});
    }
  }

  # Return the object reference
  $slf;
}
 
=head2 S<$h-E<gt>check>

This method checks that the RDA engine code is not obsolete. It generates an
error when the engine is obsolete. Otherwise, it returns the engine build.

=cut

sub check
{ my ($slf) = @_;
  my ($bld, $min);

  unless (exists($slf->{'_eng'}))
  { eval {
      require RDA::Build;
      $slf->{'_eng'} = $bld = $RDA::Build::BUILD;
      };
    die "RDA-01203: Cannot determine the RDA engine code build:\n $@\n" if $@;
    $min = get_build($slf);
    die "RDA-01204: Expecting the RDA build $min or later\n" if $bld lt $min;
  }
  $slf->{'_eng'};
}

=head2 S<RDA::Object::Rda-E<gt>find($cmd[,$flg])>

This method explores the path to find where a command is located. When the
command is found, it returns a full path name. Otherwise, it returns an
undefined variable. It only considers files or symbolic links in its
search. Unless the flag is set, the file path is quoted as required by a
command shell.

=cut

sub find
{ my ($slf, @arg) = @_;

  __PACKAGE__->find_path([__PACKAGE__->get_path], @arg);
}

=head2 S<$h-E<gt>get_build>

This method returns the current software build.

=cut

sub get_build
{ my ($slf) = @_;

  _get_version($slf) unless exists($slf->{'_bld'});
  $slf->{'_bld'};
}

=head2 S<$h-E<gt>get_columns>

This method returns the screen width.

=cut

sub get_columns
{ shift->{'RDA_COLUMNS'} || 78;
}

=head2 S<$h-E<gt>get_domain>

This method returns the domain name. On first call, it attempts to detect more
completely the domain name.

=cut

sub get_domain
{ my ($slf) = @_;

  # When not yet known, attempt to determine the domain
  unless (defined($slf->{'_dom'}))
  { $slf->{'_dom'} =
      $ENV{'RDA_DOMAIN'} ||
      _get_domain("nslookup $slf->{'_nod'}",
        qr/Name:\s*($slf->{'_nod'})\.(\S*)/) ||
      _get_domain('nslookup localhost', qr/Name:\s*(localhost)\.(\S*)/) ||
      _get_domain('nslookup -debug localhost', qr/(localhost)\.([^,]*),/) ||
      _get_domain('cat /etc/resolv.conf', qr/^(domain|search)\s+(\S*)/,'');
  }

  # Return the domain name
  $slf->{'_dom'};
}

sub _get_domain
{ my ($cmd, $re, $val) = @_;

  local $SIG{'__WARN__'} = sub {};
  if (open(CMD, "$cmd 2>&1 |"))
  { while (<CMD>)
    { last if ($_ =~ $re) && ($val = $2);
    }
    close(CMD);
  }
  $val;
}

=head2 S<$h-E<gt>get_family>

This method indicates the current operating system family.

=head2 S<RDA::Object::Rda-E<gt>get_family($osn)>

This method indicates the family of the specified operating system. It assumes
C<Unix> for unknown operating systems.

=cut

sub get_family
{ my ($slf, $osn) = @_;

  !defined($osn)        ? $slf->{'_fam'} :
  exists($tb_fam{$osn}) ? $tb_fam{$osn} :
                          'Unix';
}

=head2 S<RDA::Object::Rda-E<gt>get_gmtime([$time])>

This method returns the GMT time.

=cut

sub get_gmtime
{ my ($slf, $tim) = @_;
  my (@tim);

  @tim = gmtime(defined($tim) ? $tim : time);
  sprintf("%02d-%3s-%04d %02d:%02d:%02d",
      $tim[3], $tb_mon[$tim[4]], 1900 + $tim[5], $tim[2], $tim[1], $tim[0]);
}

=head2 S<$h-E<gt>get_host>

This method returns a full domain qualified host name.

=cut

sub get_host
{ my ($slf) = @_;

  $slf->get_domain ? $slf->{'_nod'}.'.'.$slf->{'_dom'} : $slf->{'_nod'};
}

=head2 S<$h-E<gt>get_input>

This method returns the input device for Windows. Otherwise, it returns an
undefined value.

=cut

sub get_input
{ my ($slf) = @_;

  unless (exists($slf->{'_con'}))
  { $slf->{'_con'} = undef;
    eval {
      my ($dev);

      require Win32::Console;
      $slf->{'_con'} = $dev =
        Win32::Console->new(&Win32::Console::STD_INPUT_HANDLE);
      if (ref($dev) && $dev->Mode)
      { $dev->Mode(&Win32::Console::ENABLE_ECHO_INPUT);
        $slf->{'_con'} = $dev;
      }
    } if RDA::Object::Rda->is_windows;
  }
  $slf->{'_con'};
}

=head2 S<$h-E<gt>get_lists([$lim])>

This method gets the module lists. When the argument is greater than zero, it
considers data collection module abbreviations only. When the argument is less
than zero, it considers tools and test module abbreviations only.

It returns the object reference.

=cut

sub get_lists
{ my ($slf, $lim) = @_;
  my ($abr, $flg, $val, %skp);

  # Initialization
  $flg = __PACKAGE__->is_vms;
  $lim = 0 unless defined($lim);
  $slf->{'_abr'} = {};
  $slf->{'_cnt'} = {};
  $slf->{'_mod'} = {};
  $slf->{'_tst'} = {};
  %skp = map {($flg ? uc($_) : $_) => 1} get_obsolete($slf, 'mod');

  # Determine module abbreviations
  if (opendir(DIR, get_group($slf, 'D_RDA_CODE')))
  { foreach my $nam (sort readdir(DIR))
    { next unless $nam =~ s/\.(ctl|def)$//i;
      $nam = uc($nam) if $flg;
      next if exists($skp{$nam});
      if ($nam =~ $RE_MOD)
      { $abr = uc($1);
        if ($lim < 0)
        { $slf->{'_mod'}->{$nam} = '';
        }
        elsif (!exists($slf->{'_abr'}->{$abr}))
        { $slf->{'_abr'}->{$abr} = $nam;
          $slf->{'_mod'}->{$nam} = $abr;
        }
        elsif (defined($val = $slf->{'_abr'}->{$abr}))
        { $slf->{'_mod'}->{$val} =
          $slf->{'_mod'}->{$nam} = '';
          $slf->{'_abr'}->{$abr} = undef;
        }
        else
        { $slf->{'_mod'}->{$nam} = '';
        }
      }
      elsif ($nam =~ $RE_TST)
      { $abr = $flg ? uc($2) : lc ($2);
        $slf->{'_tst'}->{$nam} = $abr;
        ++$slf->{'_cnt'}->{$abr};
      }
    }
  }

  # Determine test/tool abbreviations
  foreach my $nam (sort keys(%{$slf->{'_tst'}}))
  { $abr = $slf->{'_tst'}->{$nam};
    if ($lim > 0)
    { $slf->{'_tst'}->{$nam} = '';
    }
    elsif (exists($slf->{'_abr'}->{$abr}) || $slf->{'_cnt'}->{$abr} != 1)
    { $slf->{'_tst'}->{$nam} = '';
    }
    else
    { $slf->{'_abr'}->{$abr} = $nam;
    }
  }

  # Eliminate the ambiguous abbreviations
  foreach my $key (keys(%{$slf->{'abr'}}))
  { delete($slf->{'_abr'}->{$key}) unless defined($slf->{'_abr'}->{$key});
  }

  # Return the object reference
  $slf;
}

=head2 S<RDA::Object::Rda-E<gt>get_localtime([$time])>

This method returns the local time.

=cut

sub get_localtime
{ my ($slf, $tim) = @_;
  my (@tim);

  @tim = localtime(defined($tim) ? $tim : time);
  sprintf("%02d-%3s-%04d %02d:%02d:%02d",
      $tim[3], $tb_mon[$tim[4]], 1900 + $tim[5], $tim[2], $tim[1], $tim[0]);
}

=head2 S<$h-E<gt>get_login>

This method returns the login name.

=head2 S<$h-E<gt>get_module($str)>

This method resolves abbreviations.

=head2 S<$h-E<gt>get_module($abbr,$ext[,$dft])>

This method returns the name of the module corresponding to the specified
abbreviation. It returns an undefined value when the abbreviation is not
defined.

=cut

sub get_module
{ my ($slf, $abr, $ext, $dft) = @_;

  # Get the module lists on first usage
  get_lists($slf) unless exists($slf->{'_abr'});

  # Try to resolve an abbreviation
  $abr =~ s/\.(cfg|ctl|def)$//i;
  $abr = uc($abr) if __PACKAGE__->is_vms;
  ($dft, $ext) = ($abr, '') unless defined($ext);
  (exists($slf->{'_abr'}->{$abr}) && defined($slf->{'_abr'}->{$abr}))
    ? $slf->{'_abr'}->{$abr}.$ext
    : $dft;
}

=head2 S<$h-E<gt>get_modules>

This method returns the list of existing data collection modules. It is based
on files with names similar to C<Snnn*.def> that are present in the
C<D_RDA_CODE> directory group.

In a scalar context, it returns a hash array. In an array context, it returns
the modules sorted alphabetically.

=cut

sub get_modules
{ my ($slf, $flg) = @_;
  my @tbl;

  # Get the module lists on first usage
  get_lists($slf) unless exists($slf->{'_mod'});

  # Return the data collection modules
  return (sort keys(%{$slf->{'_mod'}})) if wantarray;
  $slf->{'_mod'};
}

=head2 S<$h-E<gt>get_node>

This method returns the node name.

=cut

sub get_node
{ shift->{'_nod'};
}

=head2 S<$h-E<gt>get_obsolete($type)>

This method returns the list of obsolete objects from the specified type.

=cut

sub get_obsolete
{ my ($slf, $typ) = @_;

  # Load the list of obsolete objects on first request
  unless (exists($slf->{'_obs'}))
  { my ($ifh, $tbl);

    $slf->{'_obs'} = $tbl = {};
    $ifh = IO::File->new;
    if ($ifh->open('<'.get_file($slf, 'D_RDA_DATA', 'obsolete.txt')))
    { while (<$ifh>)
      { s/[\n\r\s]*$//;
        push(@{$tbl->{lc($1)}}, $_) if s/^(\w+)://;
      }
      $ifh->close;
    }
  }

  # Return the obsolete objects
  return () unless exists($slf->{'_obs'}->{$typ});
  @{$slf->{'_obs'}->{$typ}};
}

=head2 S<$h-E<gt>get_os>

This method returns the name of the operating system.

=cut

sub get_os
{ shift->{'_osn'};
}

=head2 S<RDA::Object::Rda-E<gt>get_pid>

This method returns the current process identifier.

=cut

sub get_pid
{ $$;
}

=head2 S<$h-E<gt>get_shlib>

This method returns the name of the environment variables related to shared
libraries.

=cut

sub get_shlib
{ my ($slf) = @_;
  my ($lib, $osn);

  $osn = ref($slf) ? $slf->get_os : $^O;
  $lib = exists($tb_lib{$osn}) ? $tb_lib{$osn} :
         __PACKAGE__->is_unix  ? $tb_lib{'unix'} :
                                 [];
  return @$lib if wantarray;
  return $lib->[0];
}

=head2 S<$h-E<gt>get_tests($flg)>

This method returns the list of the tools and the test modules. When the flag
is set, it ensures that the tool list is loaded.

In a scalar context, it returns a hash array. In an array context, it returns
the modules sorted alphabetically.

=cut

sub get_tests
{ my ($slf, $flg) = @_;

  # Get the module lists on first call
  get_lists($slf) unless exists($slf->{'_tst'});

  # Force the load of the tool list when requested
  $slf->is_tool('') if $flg;

  # Return the test module list
  return (sort keys(%{$slf->{'_tst'}})) if wantarray;
  $slf->{'_tst'};
}

=head2 S<$h-E<gt>get_text>

This method returns the text control object reference.

=cut

sub get_text
{ shift->{'_txt'};
}

=head2 S<RDA::Object::Rda-E<gt>get_timestamp([$time])>

This method returns the GMT time as a time stamp string.

=cut

sub get_timestamp
{ my ($slf, $tim) = @_;
  my (@tim);

  @tim = gmtime(defined($tim) ? $tim : time);
  sprintf("%04d%02d%02d_%02d%02d%02d",
      1900 + $tim[5], 1 + $tim[4], $tim[3], $tim[2], $tim[1], $tim[0]);
}

=head2 S<$h-E<gt>get_tz>

This method returns the names of the current time zone. In a scalar context, it
returns the standard time zone name only.

=cut

sub get_tz
{ my (@tbl);

  eval {
    require POSIX;
    eval {POSIX::tzset()};
    @tbl = POSIX::tzname();
  };
  return @tbl if wantarray;
  $tbl[0];
}

=head2 S<$h-E<gt>get_user>

This method returns the user name.

=head2 S<$h-E<gt>get_value($name[,$default])>

This method returns the value of the given software configuration property. When
the property does not exist, it returns the default value.

When an array reference is provided as the name, it returns the value of the
first defined attribute from that list.

When executed in an array context, it returns the results as a list.

=cut

sub get_value
{ my ($slf, $nam, $dft) = @_;
  my ($cur, $fct, @tbl);

  $nam = [$nam] unless ref($nam);
  foreach my $key (@$nam)
  { $key = uc($key);
    if (exists($tb_fct{$key}))
    { $fct = $tb_fct{$key};
      $dft = (ref($fct) eq 'CODE')
        ? &{$tb_fct{$key}}($slf)
        : eval "\$slf->$fct";
      last;
    }
    elsif (exists($slf->{$key}))
    { $dft = $slf->{$key};
      last;
    }
  }
  if (wantarray)
  { return @$dft  if ref($dft) eq 'ARRAY';
    return ($dft) if defined($dft);
    return ();
  }
  $dft;
}

=head2 S<$h-E<gt>get_version>

This method returns the software version.

=cut

sub get_version
{ my ($slf) = @_;

  _get_version($slf) unless exists($slf->{'_ver'});
  $slf->{'_ver'};
}

sub _get_version
{ my ($slf) = @_;
  my ($lin);

  if (open(CHK, '<'.get_file($slf, 'D_RDA_ADM', 'rda.dat')))
  { $lin = <CHK>;
    close(CHK);
    if ($lin =~ m/\$Build:\s+(\d+\.\d+)-([^\$\s]+)/)
    { $slf->{'_bld'} = $2;
      $slf->{'_ver'} = $1;
      return;
    }
  }
  $slf->{'_bld'} = '000000';
  $slf->{'_ver'} = $RDA::Agent::VERSION;
}

=head2 S<$h-E<gt>is_tool($name)>

This method indicates whether a module is a tool, based on the modules declared
in F<[D_RDA_DATA]/tools.txt>.

=cut

sub is_tool
{ my ($slf, $nam) = @_;
  my ($flg);

  # Load the tool declarations on first call
  unless (exists($slf->{'_tls'}))
  { $slf->{'_tls'} = {};
    $flg = __PACKAGE__->is_vms;
    if (open(IN,
      '<'.__PACKAGE__->cat_file(get_group($slf, 'D_RDA_DATA'), 'tools.txt')))
    { while (<IN>)
      { s/[\n\r\s]+$//;
        $slf->{'_tls'}->{$flg ? uc($_) : $_} = 0 if m/^(TL|TM|TST)\w+$/i;
      }
      close(IN);
    }
  }

  # Check for a tool
  exists($slf->{'_tls'}->{$nam});
}

=head2 S<RDA::Object::Rda-E<gt>set_domain($domain)>

This method specifies an alternative domain. It returns the previous domain
name.

=cut

sub set_domain
{ my ($slf, $dom) = @_;
  my ($old);

  $old = $slf->{'_dom'};
  $slf->{'_dom'} = $dom if defined($dom);
  $old;
}

=head2 S<$h-E<gt>set_work($agt[,$dir])>

This method determines the work environment and changes the current directory
to it.

=cut

sub set_work
{ my ($slf, $agt, $wrk) = @_;
  my ($dir, $pth);

  # Check the setup file
  if (defined($dir = $agt->get_info('set')))
  { $agt->set_info('set', basename($dir));
    $dir = dirname($dir);
    $dir = '...' if $dir eq '.';
  }

  # Determine the work directory specification
  $dir = defined($wrk)           ? $wrk :
         exists($slf->{'D_CWD'}) ? $slf->{'D_CWD'} :
         exists($ENV{'RDA_CWD'}) ? $ENV{'RDA_CWD'} :
         defined($dir)           ? $dir :
                                   '...';

  # Resolve dynamic work directory
  $slf->{'dyn'} = ($dir =~ s#\$\$#$$#g) ? 1 : 0;
  $dir = __PACKAGE__->cat_dir(getcwd()) if $dir eq '...';
  $slf->{'D_CWD'} = $dir = RDA::Object::Rda->is_absolute($dir)
    ? __PACKAGE__->cat_dir($dir)
    : __PACKAGE__->cat_dir($slf->{'D_RDA'}, $dir);

  # Change to the work directory
  die "RDA-01200: Cannot change to the work directory '$dir':\n $!\n"
    unless chdir(__PACKAGE__->create_dir($dir, 0700));
}

=head2 S<$h-E<gt>uname($opt)>

This method gets the name of the current operating system and returns the
information associated with one of the following options:

=over 9

=item B<    'a' > Returns all information in the following order:

=item B<    's' > Returns the system/kernel name

=item B<    'n' > Returns the network node name

=item B<    'r' > Returns the kernel release

=item B<    'v' > Returns the kernel version

=item B<    'm' > Returns the machine hardware name

=back

The meanings of the various fields are not well standardized. The system
name might be the name of the operating system, the node name might be the
name of the host, the kernel release might be the (major) release number of
the operating system, the kernel version might be the (minor) release
number of the operating system, and the machine might be a hardware
identifier.

=cut

sub uname
{ my ($slf, $opt) = @_;

  # Get the system information
  $slf->{'_sys'} = $slf->sys_uname unless exists($slf->{'_sys'});

  # Extract the requested information
  $opt = 's' unless $opt;
  return join(' ', @{$slf->{'_sys'}}) if $opt eq 'a';
  return $slf->{'_sys'}->[$tb_sys{$opt}] if exists($tb_sys{$opt});
  '';
}

=head1 GROUP MANAGEMENT METHODS

Following groups are defined:

=over 20

=item B<    'D_CWD'>

Work directory

=item B<    'D_RDA'>

Main RDA directory

=item B<    'D_RDA_ADM'>

Administration file directory

=item B<    'D_RDA_CODE'>

RDA code directory

=item B<    'D_RDA_DATA'>

Data file directory

=item B<    'D_RDA_DFW'>

Diagnostic Framework rule repository directory

=item B<    'D_RDA_HCVE'>

HCVE file directory

=item B<    'D_RDA_HTML'>

HTML file directory

=item B<    'D_RDA_PERL'>

Perl package directory

=item B<    'D_RDA_POD'>

Perl documentation directory

=item B<    'D_RDA_XML'>

XML file directory

=back

Group management methods are usable also as routines by providing a hash
with the configuration as first argument.

=head2 S<$h-E<gt>clean_group($group)>

This method retrieves a group directory and deletes its content.

=cut

sub clean_group
{ my ($slf, $grp) = @_;

  __PACKAGE__->clean_dir(get_group($slf, $grp));
}

=head2 S<$h-E<gt>create_group($group[,$mode])>

This method retrieves a group directory and creates it when it does not yet
exist. It makes parent directories as needed. It returns the directory path.

=cut

sub create_group
{ my ($slf, $grp, $mod) = @_;

  __PACKAGE__->create_dir(get_group($slf, $grp), $mod);
}

=head2 S<$h-E<gt>delete_group($group)>

This method retrieves a group directory and deletes it.

=cut

sub delete_group
{ my ($slf, $grp) = @_;

  __PACKAGE__->delete_dir(get_group($slf, $grp));
}

=head2 S<$h-E<gt>get_dir($group,$path)>

This method retrieves and returns the path to a directory belonging to the
specified group. Slashes (C</>) are used as delimiters when directories are
included in the path.

=cut

sub get_dir
{ my ($slf, $grp, $dir) = @_;
  my $pth;

  die "RDA-01202: Invalid directory group '$grp'\n"
    unless defined($pth = get_group($slf, $grp));
  __PACKAGE__->cat_dir($pth, split(/\//, $dir));
}

=head2 S<$h-E<gt>get_file($group,$path[,$ext])>

This method retrieves and returns the path to a file belonging to the specified
group. Slashes (C</>) are used as delimiters when directories are included
in the path.

=cut

sub get_file
{ my ($slf, $grp, $nam, $ext) = @_;
  my $pth;

  die "RDA-01202: Invalid directory group '$grp'\n"
    unless defined($pth = get_group($slf, $grp));
  if ($ext)
  { $nam =~ s#\Q$ext\E$##i;  #
    $nam .= $ext;
  }
  __PACKAGE__->cat_file($pth, split(/\//, $nam));
}

=head2 S<$h-E<gt>get_group($group[,$flag])>

This method returns the specified directory path. When the flag is set,
relative paths are not converted to absolute ones.

It supports also some pseudo directory names:

=over 9

=item B<    '-' > Returns a list of all defined directories

=item B<    '*' > Returns a list of all directories

=back

=cut

sub get_group
{ my ($slf, $nam, $flg) = @_;
  my ($dir, $typ);

  $typ = $slf->{'typ'} || 'dft';
  return (grep {m/^D_RDA_/} sort keys(%$slf)) if $nam eq '-';
  return (sort keys(%{$tb_dir{$typ}}))        if $nam eq '*';
  $dir = exists($slf->{$nam})
           ? $slf->{$nam} :
         exists($tb_dir{$typ}->{$nam})
           ? __PACKAGE__->cat_dir(@{$tb_dir{$typ}->{$nam}}) :
         undef;
  if (defined($dir))
  { $flg = 1 unless $dir && $nam =~ m/^D/ && exists($slf->{'D_RDA'});
    $dir = __PACKAGE__->cat_dir($slf->{'D_RDA'}, $dir)
      unless $flg || __PACKAGE__->is_absolute($dir);
  }
  $dir;
}

=head1 DIRECTORY AND FILE MANAGEMENT METHODS

=head2 S<RDA::Object::Rda-E<gt>arg_dir([$dir...,]$dir)>

This method performs a C<cat_dir> and quotes the result only for Windows.

=head2 S<RDA::Object::Rda-E<gt>arg_file([$dir...,]$file)>

This method performs a C<cat_file> and quotes the result only for Windows.

=head2 S<RDA::Object::Rda-E<gt>as_bat([$path])>

This method adds script-specific extension to the specified path.

=head2 S<RDA::Object::Rda-E<gt>as_cmd([$path])>

This method adds script-specific extension to the specified path.

=head2 S<RDA::Object::Rda-E<gt>as_exe([$path])>

This method adds executable-specific extension to the specified path.

=head2 S<RDA::Object::Rda-E<gt>cat_dir([$dir...,]$dir)>

This method concatenates directory names to form a complete path ending with a
directory. It removes the trailing slash from the resulting string, except for
the root directory.

It discards undefined values and references from the argument list.

=head2 S<RDA::Object::Rda-E<gt>cat_file([$dir...,]$file)>

This method concatenates directory names and a file name to form a complete
path ending with a file name.

It discards undefined values and references from the argument list.

=head2 S<RDA::Object::Rda-E<gt>clean_dir($path)>

This method deletes the content of a directory but not the directory itself.

=head2 S<RDA::Object::Rda-E<gt>clean_path($path[,$flag])>

This method performs a logical cleanup of a path. When the flag is set, it
performs additional platform-specific simplifications.

=head2 S<RDA::Object::Rda-E<gt>create_dir($path[,$mode])>

This method creates a directory when it does not yet exist. It makes parent
directories as needed. If directory permissions are omitted, 0750 is used as
default. It returns the directory name.

=head2 S<RDA::Object::Rda-E<gt>current_dir>

This method returns a string representation of the current directory (C<.> on
UNIX).

=head2 S<RDA::Object::Rda-E<gt>delete_dir($path)>

This method deletes a directory and its content.

=head2 S<RDA::Object::Rda-E<gt>dev_null>

This method returns a string representation of the null device.

=head2 S<RDA::Object::Rda-E<gt>dev_tty>

This method returns a string representation of the terminal device.

=head2 S<RDA::Object::Rda-E<gt>get_last_modify($file[,$default])>

This method gets the last modification date of the file. It returns the default
value when there are problems.

=head2 S<RDA::Object::Rda-E<gt>get_path>

This method returns the environment variable C<PATH> as a list.

=head2 S<RDA::Object::Rda-E<gt>get_separator>

This method returns the character used as the separator.

=head2 S<RDA::Object::Rda-E<gt>get_title($dir,$file[,$default])>

This method extracts the short description (title) from the specified file.

=head2 S<RDA::Object::Rda-E<gt>is_absolute($path)>

This method indicates whether the argument is an absolute path.

=head2 S<RDA::Object::Rda-E<gt>is_cygwin>

This method returns a true value if the operating system is Cygwin.

=head2 S<RDA::Object::Rda-E<gt>is_root_dir($path)>

This method indicates whether the path represents a root directory. It assumes
that the provided path is already cleaned.

=head2 S<RDA::Object::Rda-E<gt>is_unix>

This method returns a true value if the operating system belongs to the UNIX
family.

=head2 S<RDA::Object::Rda-E<gt>is_vms>

This method returns a true value if the operating system is VMS.

=head2 S<RDA::Object::Rda-E<gt>is_windows>

This method returns a true value if the operating system belongs to the
Windows family.

=head2 S<RDA::Object::Rda-E<gt>kill_child($pid)>

This method kills a child process.

=head2 S<RDA::Object::Rda-E<gt>native($path)>

This method converts the path to its native representation. It does not make
any transformation for UNIX.

=head2 S<RDA::Object::Rda-E<gt>quote($str[,$flg])>

This method encodes a string to be considered as a single argument by a command
shell. When the flag is set, variable substitution is disabled also.

=head2 S<RDA::Object::Rda-E<gt>short($path)>

This method converts the path to its native representation using only short
names. It does not make any transformation for UNIX.

=head2 S<RDA::Object::Rda-E<gt>split_dir($path)>

This method returns the list of directories contained in the specified
path. Unlike just splitting the directories on the separator, empty directory
names (C<''>) can be returned, because these are significant on some operating
systems. The first element can contain volume information.

For UNIX,

    RDA::Object::Rda->split_dir("/a/b//c/");

Yields:

    ('', 'a', 'b', '', 'c', '')

=head2 S<RDA::Object::Rda-E<gt>split_volume($path)>

This method separates the volume from the other path information.

=head2 S<RDA::Object::Rda-E<gt>up_dir>

This method returns a string representation of the parent directory (C<..> on
UNIX).

=cut

# --- SDCL extensions ---------------------------------------------------------

# Define a global variable to access RDA software configuration
sub _begin_rda
{ my ($pkg) = @_;

  $pkg->define('$[RDA]', $pkg->get_info('cfg'));
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Build|RDA::Build>,
L<RDA::Object|RDA::Object>,
L<RDA::Local::Cygwin|RDA::Local::Cygwin>,
L<RDA::Local::Unix|RDA::Local::Unix>,
L<RDA::Local::Vms|RDA::Local::Vms>,
L<RDA::Local::Windows|RDA::Local::Windows>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
