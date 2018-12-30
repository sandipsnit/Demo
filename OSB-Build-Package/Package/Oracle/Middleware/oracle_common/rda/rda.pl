# rda.pl: Setup, collect, render, and package diagnostic information
#
# $Id: rda.pl,v 2.57 2012/06/06 14:05:38 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/bin/rda.pl,v 2.57 2012/06/06 14:05:38 mschenke Exp $
#
# Change History
# 20120606  MSC  Add the age check.

eval 'exec perl -w -S "$0" ${1+"$@"}'
  if 0; # not running under some shell

use strict;

BEGIN
{ use Cwd;
  use File::Basename;
  use File::Copy;
  use File::Spec;
  use Getopt::Std;
  use IO::File;
}

# Include packages in the compiled version

#perl2exe_exclude Digest::Perl::MD5

#perl2exe_include Compress::Zlib
#perl2exe_include Digest::MD5
#perl2exe_include File::Spec::Mac
#perl2exe_include File::Spec::OS2
#perl2exe_include File::Spec::Unix
#perl2exe_include File::Spec::Win32
#perl2exe_include integer
#perl2exe_include IO::File
#perl2exe_include IO::Handle
#perl2exe_include POSIX
#perl2exe_include Socket
#perl2exe_include Time::HiRes

#perl2exe_include RDA::Agent
#perl2exe_include RDA::Block
#perl2exe_include RDA::Build
#perl2exe_include RDA::Context
#perl2exe_include RDA::Convert
#perl2exe_include RDA::Daemon
#perl2exe_include RDA::Diaglet
#perl2exe_include RDA::Diff
#perl2exe_include RDA::Discover
#perl2exe_include RDA::Explorer
#perl2exe_include RDA::Extra
#perl2exe_include RDA::Filter
#perl2exe_include RDA::Log
#perl2exe_include RDA::Module
#perl2exe_include RDA::Object
#perl2exe_include RDA::Options
#perl2exe_include RDA::Profile
#perl2exe_include RDA::Remote
#perl2exe_include RDA::Render
#perl2exe_include RDA::Setting
#perl2exe_include RDA::Tools
#perl2exe_include RDA::Upgrade
#perl2exe_include RDA::Value
#perl2exe_include RDA::Web

#perl2exe_include RDA::Archive::Header
#perl2exe_include RDA::Archive::Rda

#perl2exe_include RDA::Driver::Da
#perl2exe_include RDA::Driver::Dbd
#perl2exe_include RDA::Driver::Jdbc
#perl2exe_include RDA::Driver::Jsch
#perl2exe_include RDA::Driver::Local
#perl2exe_include RDA::Driver::Rsh
#perl2exe_include RDA::Driver::Sqlplus
#perl2exe_include RDA::Driver::Ssh
#perl2exe_include RDA::Driver::WinOdbc

#perl2exe_include RDA::Handle::Area
#perl2exe_include RDA::Handle::Block
#perl2exe_include RDA::Handle::Data
#perl2exe_include RDA::Handle::Deflate
#perl2exe_include RDA::Handle::Filter
#perl2exe_include RDA::Handle::Memory

#perl2exe_include RDA::Library::Admin
#perl2exe_include RDA::Library::Archive
#perl2exe_include RDA::Library::Buffer
#perl2exe_include RDA::Library::Data
#perl2exe_include RDA::Library::Db
#perl2exe_include RDA::Library::Dbi
#perl2exe_include RDA::Library::Env
#perl2exe_include RDA::Library::Expr
#perl2exe_include RDA::Library::File
#perl2exe_include RDA::Library::Ftp
#perl2exe_include RDA::Library::Hcve
#perl2exe_include RDA::Library::Html
#perl2exe_include RDA::Library::Http
#perl2exe_include RDA::Library::Invent
#perl2exe_include RDA::Library::Remote
#perl2exe_include RDA::Library::String
#perl2exe_include RDA::Library::Table
#perl2exe_include RDA::Library::Temp
#perl2exe_include RDA::Library::Value
#perl2exe_include RDA::Library::Was
#perl2exe_include RDA::Library::Xml

#perl2exe_include RDA::Local::Cygwin
#perl2exe_include RDA::Local::Unix
#perl2exe_exclude RDA::Local::Vms
#perl2exe_include RDA::Local::Windows

#perl2exe_include RDA::Object::Access
#perl2exe_include RDA::Object::Buffer
#perl2exe_include RDA::Object::Convert
#perl2exe_include RDA::Object::Cookie
#perl2exe_include RDA::Object::Display
#perl2exe_include RDA::Object::Domain
#perl2exe_include RDA::Object::Env
#perl2exe_include RDA::Object::Explorer
#perl2exe_include RDA::Object::Ftp
#perl2exe_include RDA::Object::Html
#perl2exe_include RDA::Object::Home
#perl2exe_include RDA::Object::Index
#perl2exe_include RDA::Object::Inline
#perl2exe_include RDA::Object::Instance
#perl2exe_include RDA::Object::Jar
#perl2exe_include RDA::Object::Java
#perl2exe_include RDA::Object::Lock
#perl2exe_include RDA::Object::Mrc
#perl2exe_include RDA::Object::Output
#perl2exe_include RDA::Object::Parser
#perl2exe_include RDA::Object::Pipe
#perl2exe_include RDA::Object::Pod
#perl2exe_include RDA::Object::Rda
#perl2exe_include RDA::Object::Remote
#perl2exe_include RDA::Object::Report
#perl2exe_include RDA::Object::Request
#perl2exe_include RDA::Object::Response
#perl2exe_include RDA::Object::Sgml
#perl2exe_include RDA::Object::SshAgent
#perl2exe_include RDA::Object::System
#perl2exe_include RDA::Object::Table
#perl2exe_include RDA::Object::Target
#perl2exe_include RDA::Object::Telnet
#perl2exe_include RDA::Object::Toc
#perl2exe_include RDA::Object::UsrAgent
#perl2exe_include RDA::Object::Windows
#perl2exe_include RDA::Object::WlHome
#perl2exe_include RDA::Object::Xml

#perl2exe_include RDA::Operator::Array
#perl2exe_include RDA::Operator::Hash
#perl2exe_include RDA::Operator::Scalar
#perl2exe_include RDA::Operator::Value

#perl2exe_include RDA::Value::Array
#perl2exe_include RDA::Value::Assoc
#perl2exe_include RDA::Value::Code
#perl2exe_include RDA::Value::Global
#perl2exe_include RDA::Value::Hash
#perl2exe_include RDA::Value::Internal
#perl2exe_include RDA::Value::List
#perl2exe_include RDA::Value::Operator
#perl2exe_include RDA::Value::Pointer
#perl2exe_include RDA::Value::Property
#perl2exe_include RDA::Value::Scalar
#perl2exe_include RDA::Value::Variable

#perl2exe_include RDA::Web::Archive
#perl2exe_include RDA::Web::Display
#perl2exe_include RDA::Web::Help

# Change to the install directory
my ($bin, $cwd);
$cwd = exists($ENV{'RDA_CWD'})
  ? File::Spec->catdir($ENV{'RDA_CWD'})
  : get_cwd();
chdir($bin)
  if ($bin = dirname($0)) ne '.'
  || ($^X =~ m/\brda_\w+56$/ && ($bin = dirname($^X)) ne '.');

# Define global variables
my ($re_trc, $re_tst);
my %tb_trc = (
  't:' => 1,
  'T:' => 2,
  'T/' => 2,
  't/' => 2,
  );
my %tb_wrn = (
  DB  => "RDA-00015: Warning - ".
         "\%d database request(s) not executed in \%s module(s)\n",
  DBI => "RDA-00015: Warning - ".
         "\%d DBI request(s) not executed in \%s module(s)\n",
  OS  => "RDA-00017: Warning - ".
         "\%d command(s) not executed in \%s module(s)\n",
  SQL => "RDA-00015: Warning - ".
         "\%d database request(s) not executed in \%s module(s)\n",
  XML => "RDA-00018: Warning - ".
         "\%d XML request(s) not executed in \%s module(s)\n",
  );

# Check the operating system
my $vms = ($^O eq 'VMS');
my $win = ($^O eq 'MSWin32' || $^O eq 'MSWin64');

# Set the defaults
my $act = '*';       # Default action
my $cls;             # No default plugin class
my $dbg = 0;         # No debug
my $doC = 0;         # No data collection
my $doP = 0;         # No report packaging
my $doR = 0;         # No report rendering
my $doS = 0;         # No setup
my $edt;             # No temporary settings
my $end = 0;         # Default exit value
my $frc = 0;         # Only generate outdated reports
my $grp;             # Default XML group
my $inp;             # No input pipe
my $prf;             # Default setup profile
my $rnd = 0;         # Don't immediately render selected reports
my $sav;             # Auto save controlled by the setup file
my $trc = 0;         # No trace
my $vrb = 0;         # Silent mode
my $wrn = -1;        # Don't display execution warnings
my $xml = 'convert'; # Default XML result file
my %agt;             # Agent attributes

my $out = $win ? 'NUL' : $vms ? 'nla0:' : '/dev/null';

# Transform some options
if ($vms || $win)
{ $re_trc = qr#^([Tt][:\/])(.*)$#;  #
  $re_tst = qr#^([Mm][:\/])?([^:]+)([:\/](.*))?$#;  #
  foreach my $arg (@ARGV)
  { last if $arg eq '--';
    $arg = '-'.uc($arg) if $arg =~ s#^\/##;
  }
}
else
{ $re_trc = qr#^([Tt]:)(.*)$#;  #
  $re_tst = qr#^([Mm]:)?([^:]+)(:(.*))?$#;  #
}

# Parse the options
my %opt;
getopts("ABCDEFGHIKLMOPQRSTVX:bcde:fg:hilm:no:p:qs:tvwxyz:",\%opt);
$act = 'A'                       if $opt{'A'};
$act = 'B'                       if $opt{'B'};
$act = $doC = '-'                if $opt{'C'};
$act = 'D'                       if $opt{'D'};
$act = 'E'                       if $opt{'E'};
$act = 'F'                       if $opt{'F'};
$act = 'G'                       if $opt{'G'};
$act = 'H'                       if $opt{'H'};
$act = 'I'                       if $opt{'I'};
$act = 'K'                       if $opt{'K'};
$act = 'L'                       if $opt{'L'};
$act = 'M'                       if $opt{'M'};
$act = 'O'                       if $opt{'O'};
$act = $doP = '-'                if $opt{'P'};
$act = 'Q'                       if $opt{'Q'};
$act = $doR = '-'                if $opt{'R'};
$act = $doS = '-'                if $opt{'S'};
$act = 'T'                       if $opt{'T'};
$act = 'V'                       if $opt{'V'};
($act, $cls) = ('X', $opt{'X'})  if $opt{'X'};
$agt{'bkp'} = 0                  if $opt{'b'};
$act = 'c'                       if $opt{'c'};
$dbg = 1                         if $opt{'d'};
$edt = $opt{'e'}                 if $opt{'e'};
$frc = 1                         if $opt{'f'};
$grp = $opt{'g'}                 if $opt{'g'};
$agt{'lck'} = 1                  if $opt{'l'} || $act eq 'B';
$agt{'new'} = 1                  if $opt{'n'};
$out = $xml = $opt{'o'}          if $opt{'o'};
$prf = $opt{'p'}                 if $opt{'p'};
$agt{'out'} = 1                  if $opt{'q'} || $opt{'O'};
$trc = 1                         if $opt{'t'};
$agt{'vrb'} = $vrb = 1           if $opt{'v'};
$agt{'lck'} = -1                 if $opt{'w'};
$sav = 0                         if $opt{'w'};
$act = 'x'                       if $opt{'x'};
$agt{'yes'} = 1                  if $opt{'y'} || $opt{'i'} || $act eq 'B';
$agt{'zip'} = $opt{'z'}          if $opt{'z'};
($trc, $prf) = ($tb_trc{$1}, $2) if $prf && $prf =~ $re_trc;

if ($opt{'h'})
{ print <<"EOF";
Usage: rda.pl [-bcdfilntvwxy] [-ABCDEGHIKLMPQRSTV] [-e list] [-m dir]
              [-s name] [-o out] [-p prof] arg ...
        -A      Authentify user through the setup file
        -B      Start background collection
        -C      Collect diagnostic information
        -D      Delete specified modules from the setup
        -E      Explain specified error numbers
        -G      Convert report files to XML format
        -H      Halt background collection
        -I      Regenerate the index
        -K      Kill background collection
        -L      List the available modules, profiles, and conversion groups
        -M      Display the related manual pages
        -O      Render output specifications from STDIN
        -P      Package the reports (tar or zip)
        -Q      Display the related setup questions
        -R      Generate specified reports
        -S      Setup specified modules
        -T      Execute test modules
        -V      Display component version numbers
        -b      Don't backup setup file before saving
        -c      Check the RDA installation and exit
        -d      Set debug mode
        -e list Specify a list of alternate setting definitions (var=val,...)
        -f      Set force mode
        -g grp  Specify the XML conversion group
        -h      Display the command usage and exit
        -i      Read settings from the standard input
        -l      Use a lock file to prevent concurrent usage of a setup file
        -m dir  Specify the module directory ('modules' by default)
        -n      Start a new data collection
        -o out  Specify the file for background collection output redirection
        -p prof Specify the setup profile ('Default' by default)
        -q      Set quiet mode
        -s name Specify the setup name ('setup' by default)
        -t      Set trace mode
        -v      Set verbose mode
        -w      Wait as long as the background collection daemon is active
        -x      Produce cross references
        -y      Accept all defaults and skip all pauses
EOF
  exit(0);
}

# Determine the directory structure
{ my ($cfg, $inc, $pth, $str, $typ, @edt, @inp);

  # Get absolute path
  $bin = get_cwd() unless File::Spec->file_name_is_absolute($bin);

  # Determine possible directory structure
  $inc = File::Spec->catdir($bin, File::Spec->updir(), 'perl');
  if (-f File::Spec->catfile($inc, 'RDA', 'Agent.pm'))
  { $typ = 'izu';
  }
  else
  { $typ = 'dft';
    $inc = $bin;
  }
  $cfg = {typ => $typ};

  # Treat the options
  if ($opt{'m'})
  { $pth = File::Spec->catdir($opt{'m'});
    $pth = File::Spec->catdir($bin, $pth)
      unless File::Spec->file_name_is_absolute($pth);
    $cfg->{'D_RDA_CODE'} =
    $cfg->{'D_RDA_DATA'} =
    $cfg->{'D_RDA_HTML'} =
    $cfg->{'D_RDA_XML'} = $pth;
  }

  # Extract RDA directory structure from an existing configuration file
  if (open(CFG, '<'.File::Spec->catfile($bin, 'rda.cfg')))
  { while (<CFG>)
    { $cfg->{$1} = File::Spec->catdir(decode($2))
        if m/^(D_[A-Z]\w*[A-Z]+|NO_[A-Z]+)="([^"]*)"/;
    }
    close(CFG);
  }

  # Extract RDA configuration from the edit specifications
  edit(\@edt, $cfg, $ENV{'RDA_EDIT'}) if exists($ENV{'RDA_EDIT'});
  edit(\@edt, $cfg, $edt)             if defined($edt);
  if ($opt{'i'})
  { while (<STDIN>)
    { if (m/^(\w+)='(.*)'/)
      { push(@edt, uc($1).'='.$2);
      }
      else
      { last if m/^#EOF\b/;
        push(@inp, $_) ;
      }
    }
  }
  $agt{'edt'} = [@edt] if @edt;
  $agt{'inp'} = [@inp] if @inp;

  # Adjust the software directory
  if (exists($cfg->{'D_RDA'}))
  { chdir($bin = $cfg->{'D_RDA'})
      or die "RDA-0000: Cannot change to the RDA directory '$bin':\n $!\n";
    $bin = get_cwd();
  }
  $cfg->{'D_RDA'} = $bin;

  # Determine the setup file name and location
  unless ($opt{'c'})
  { if ($str = $opt{'s'} || $ENV{'RDA_SETUP'})
    { $pth = dirname($str = File::Spec->catfile($str));
      $cfg->{'D_CWD'} = mk_work(File::Spec->file_name_is_absolute($pth)
        ? $pth
        : File::Spec->catdir($cwd, $pth));
      $str = basename($str);
      $str =~ s/\.cfg$//i;
      $agt{'oid'} = $str;
    }
    else
    { $cfg->{'D_CWD'} = mk_work($cwd);
    }
  }

  # Check for an alternate Perl module location
  if (exists($cfg->{'D_RDA_PERL'}))
  { $inc = File::Spec->catdir($cfg->{'D_RDA_PERL'});
    $inc = File::Spec->catdir($bin, $inc)
      unless File::Spec->file_name_is_absolute($inc);
  }

  # Adapt the context
  $agt{'cfg'} = $cfg;
  push(@INC, $inc);

  # Check for RDA upgrade
  do_upgrade($bin, exists($cfg->{'NO_RETEST'}) ? $cfg->{'NO_RETEST'} : 36000)
    unless exists($cfg->{'NO_GETUPDATES'}) ||
           exists($cfg->{'NO_UPGRADE'}) ||
           $vms;
}

# Perform checks when requested
do_check(\%agt) if $act eq 'c';

# Initialize the RDA agent
eval "require RDA::Agent";
die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
my $h = RDA::Agent->new(%agt);

# Restrict STDERR usage
unless ($opt{'M'} || $opt{'Q'} || $opt{'x'})
{ my $cmd = exists($ENV{'RDA_WARN'}) ? $ENV{'RDA_WARN'} : '';
  my $rdr = ($cmd =~ m/^\&LOG$/i) ? '>&'.fileno($h->logfile || *STDOUT) :
            ($cmd =~ m/^[\w\/\\\.]/) ? '>>'.$cmd :
            $cmd ? undef :
            $win ? '>NUL' :
            $vms ? '>nla0:' : '>/dev/null';
  if ($rdr)
  { open(STDERR, $rdr) or die "stderr error $!\n";;
    $SIG{'__DIE__'}  = sub { open(STDERR, ">&STDOUT")
                               unless $^S || !defined($^S) };
    $SIG{'__WARN__'} = sub { print @_ };
  }
}

# Make temporary setup configuration
$h->set_setting('RDA_ARGC', (scalar @ARGV),   'N', 'Number of arguments');
$h->set_setting('RDA_ARGV', join('|', @ARGV), 'T', 'Argument list');
if ($0 =~ m/\brda.pl$/ && $^X !~ m/\brda_\w+56$/)
{ my ($cmd, $pth);

  $cmd = RDA::Object::Rda->quote($^X);
  $pth = RDA::Object::Rda->is_unix
    ? $cmd
    : RDA::Object::Rda->short($^X);
  $h->set_setting('RDA_EXEC', "$pth rda.pl", 'T', 'Launch command');
  $h->set_setting('RDA_SELF', "$cmd rda.pl", 'T', 'Relaunch command');
  $h->set_setting('RDA_PERL', $cmd,          'F', 'Perl executable');
}
else
{ my ($cmd, $pth);

  $pth = $^X;
  $pth = File::Spec->catfile($h->get_config->get_group('D_RDA'), basename($pth))
    unless File::Spec->file_name_is_absolute($pth);
  $cmd = RDA::Object::Rda->quote($pth);
  $pth = RDA::Object::Rda->is_unix
    ? $cmd
    : RDA::Object::Rda->short($cmd);
  $h->set_setting('RDA_EXEC', $pth, 'T', 'Launch command');
  $h->set_setting('RDA_SELF', $cmd, 'T', 'Relaunch command');
}

# Control STDOUT usage
$h->set_info('out', 1) if $h->get_info('RDA_RENDER');
if ($h->get_info('out'))
{ $dbg = $trc = $vrb = $wrn = 0;
  foreach my $key (keys(%tb_trc))
  { $tb_trc{$key} = 0;
  }
}

# Adjust the default requests
if ($act eq '*')
{ $doC = $doR = $doP = 1;
  $doS = 1 unless $h->get_profile->chk_profile($prf);
  unless (@ARGV)
  { $doS = 1 unless $h->is_configured;
    $frc = 1 if $h->get_setting('RPT_FORCE', 1);
  }
}

# Treat the requests
if ($doS)
{ my @tbl = $h->get_profile->set_profile($prf);
  if (@ARGV)
  { do_setup($h, $sav, ($doC || $doR || $doP), 1, @ARGV);
  }
  else
  { do_setup($h, $sav, ($doC || $doR || $doP), undef, @tbl);
  }
  do_post($h, $sav, 'POST_SETUP');
}
if ($doC)
{ do_collect($h, $sav, @ARGV);
  do_post($h, $sav, 'POST_COLLECT');
  $wrn = 1 if $wrn;
}
if ($doR)
{ do_render($h);
  do_post($h, $sav, 'POST_RENDER');
  $wrn = 1 if $wrn;
}
if ($doP)
{ my ($str);

  do_package($h, 1);
  do_post($h, $sav, 'POST_PACKAGE');
  if ($str = $h->set_setting('DO_FINALIZE'))
  { foreach my $itm (split(/,/, $str))
    { $h->set_temp_setting("FINALIZE_PACKAGE_$itm", $itm) if $itm =~ m/^\w+$/;
    }
    do_post($h, $sav, 'FINALIZE_PACKAGE');
    do_render($h);
    do_package($h, 1);
  }
  $wrn = 1 if $wrn;
}

# Treat the exclusive requests
if ($act eq 'A')
{ do_authen($h, @ARGV);
}
elsif ($act eq 'B')
{ do_bgnd($h, $out, @ARGV);
}
elsif ($act eq 'D')
{ do_delete($h, @ARGV);
}
elsif ($act eq 'E')
{ do_explain($h, @ARGV);
}
elsif ($act eq 'F')
{ do_render($h, @ARGV);
}
elsif ($act eq 'G')
{ do_convert($h, $grp, $xml, @ARGV);
}
elsif ($act eq 'H')
{ do_halt($h);
}
elsif ($act eq 'I')
{ do_index($h);
}
elsif ($act eq 'K')
{ do_kill($h);
}
elsif ($act eq 'L')
{ do_list($h);
}
elsif ($act eq 'M')
{ do_man($h, @ARGV);
}
elsif ($act eq 'O')
{ do_output($h);
}
elsif ($act eq 'Q')
{ my @tbl = $h->get_profile->set_profile($prf);
  @tbl = @ARGV if @ARGV;
  do_question($h, @tbl);
}
elsif ($act eq 'T')
{ $h->get_profile->set_profile($prf) if $prf;
  do_test($h, @ARGV);
  $end = $h->get_setting('RDA_EXIT', 0);
  $sav = 0 unless $h->get_setting('FORCE_SAVE');
}
elsif ($act eq 'V')
{ do_version($h);
}
elsif ($act eq 'X')
{ $end = do_extern($h, $cls, @ARGV);
}
elsif ($act eq 'x')
{ do_xref($h, @ARGV);
}
elsif ($act eq '?')
{ $h->dsp_text($win ? 'Start/Windows' : 'Start',
    $win && !exists($ENV{'RDA_NO_PAUSE'}));
}

# Save the setup
if (!defined($sav) && index('?EFGHIKLMOQVx', $act) < 0)
{ print "\tUpdating the setup file ...\n" if $vrb;
  $h->save;
}

# Report execution warnings
if ($wrn > 0)
{ my ($cnt, $tbl, @mod);

  $tbl = $h->get_config->get_modules;
  print "RDA-00024: Warning - Partially collected module(s): ",$cnt
    if ($cnt = $h->get_setting('SECTION_WARNINGS'));
  foreach my $key (qw(DB DBI OS XML))
  { if ($cnt = $h->get_setting($key.'_WARNINGS'))
    { ($cnt, @mod) = split(/\|/, $cnt);
      @mod = map {exists($tbl->{$_}) ? $tbl->{$_} : $_} @mod;
      printf($tb_wrn{$key}, $cnt, join(', ', @mod));
    }
  }
}

# Close the agent and exit
$h->end;

exit($end);

# Decode a string
sub decode
{ my ($val) = @_;

  $val =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
  $val;
}

# Extract the information from the edit directives
sub edit
{ my ($tbl, $cfg, $edt) = @_;
  my ($key, $val);

  foreach my $str (split(/,/, $edt))
  { next unless ($str =~ m/^(\w+)=(.*)$/);
    $key = uc($1);
    $val = decode($2);
    if ($key =~ m/^D_[A-Z]\w*[A-Z]+$/)
    { $cfg->{$key} = $val;
    }
    else
    { push(@$tbl, "$key=$val");
    }
  }
}

# Store user authentication in the setup file
sub do_authen
{ my ($slf) = @_;

  die "RDA-00016: S999END setup required for managing authentication\n"
    unless $slf->is_configured('S999END');
  $slf->set_current('S999END');
  foreach my $arg (@ARGV)
  { my ($key, $pwd, $typ, $usr);

    ($usr, $pwd) = split(/\//, $arg);
    next unless $usr;
    if ($usr =~ m/^(\*)?(\w+)(\@oracle|\@\+)?(\@([\+\w]+))?$/i)
    { $usr = uc($4 ? $2.'@'.$5 : $2);
      $key = uc($4 ? "_$5__$2" : $2);
      $key =~ s/\+/plus/g;
      if ($1)
      { print "Deleting '$usr' authentication ...\n" if $vrb;
        $slf->del_setting("SQL_PASSWORD_$key");
      }
      else
      { print "Adding '$usr' authentication ...\n" if $vrb;
        $pwd = $slf->get_access->ask_password("Enter password for '$usr': ")
          unless $pwd;
        $pwd = pack('u', $pwd);
        chomp($pwd);
        $slf->set_setting("SQL_PASSWORD_$key", $pwd,
          'T', "Authentification for '$usr'");
      }
    }
    elsif ($usr =~ m/^(\*)?(\w+)(\@oracle|\@\+)?\@([\+\w]+(\.[\w\-]+)+)$/i)
    { _set_authen($slf, $1, 'SQL', $pwd, uc($2).'@'.uc($4));
    }
    elsif ($usr =~
     m/^(\*)?(\w+)(\@oracle|\@\+)?\@([\w\.\-]+)(:\d+:([\+\.\w]*:)?[\+\.\w]+)$/i)
    { _set_authen($slf, $1, 'SQL', $pwd, uc($2).'@'.$4.uc($5));
    }
    elsif ($usr =~ m/^(\*)?(\w+)\@([a-z]+|\-)\@(.+)$/i && lc($3) ne 'oracle')
    { $typ = lc($3);
      $usr = ($typ eq 'host' || $typ eq 'wls' || $typ eq 'wsp') ? $2 : uc($2);
      _set_authen($slf, $1, 'DBI', $pwd,
        $usr.'@'.(($3 eq '-') ? 'odbc' : lc($3)).'@'.$4);
    }
  }
}

sub _get_authen
{ my ($slf, $grp, $usr) = @_;
  my ($num, $ref);

  # Search if it already exists
  foreach my $key ($slf->grep_setting('^'.$grp.'_USER_\d+$'))
  { return substr($key, 9) if $usr eq $slf->get_setting($key);
  }

  # Determine its identifier
  $num = unpack("%32C*", $usr);
  do
  { $ref = sprintf('%06d', $num++);
  } while defined($slf->get_setting($grp.'_USER_'.$ref));
  $ref;
}

sub _set_authen
{ my ($slf, $del, $grp, $pwd, $usr) = @_;
  my ($key);

  $key = _get_authen($slf, $grp, $usr);
  if ($del)
  { print "Deleting '$usr' authentication ...\n" if $vrb;
    $slf->del_setting($grp.'_USER_'.$key);
    $slf->del_setting($grp.'_PASS_'.$key);
  }
  else
  { print "Adding '$usr' authentication ...\n" if $vrb;
    $pwd = $slf->get_access->ask_password("Enter password for '$usr': ")
      unless $pwd;
    $pwd = pack('u', $pwd);
    chomp($pwd);
    $slf->set_setting($grp.'_USER_'.$key, $usr, 'T', "User/SID information");
    $slf->set_setting($grp.'_PASS_'.$key, $pwd, 'T', "Password for '$usr'");
  }
}

# Start a background collection
sub do_bgnd
{ my ($slf, $arg, @arg) = @_;
  my ($cfg, $dmn, $mod, $ret, @tbl);

  print "\tStarting a background collection ...\n" if $vrb;

  # Identify the sampling modules
  if (@arg)
  { $cfg = $slf->get_config;
    foreach my $nam (@arg)
    { $mod = ($nam =~ $re_trc) ? $2 : $nam;
      push(@tbl, $cfg->get_module($mod));
    }
    @tbl = sort @tbl;
  }
  else
  { @tbl = split(/,/, $slf->get_setting('SMPL_MODULES', ''));
  }

  # Start the background collection
  $dmn = $slf->get_daemon;
  $ret = $dmn->run_bgnd($arg, @tbl);
  if ($ret > 0)
  { $vrb = 0;
  }
  elsif ($ret == 0)
  { # Don't save the setup in the launcher
    $act = '?';

    # When forced, try to halt it
    if ($frc)
    { print "\tHalting the background collection ...\n" if $vrb;
      sleep(1);
      $dmn->halt_bgnd;
    }
  }
}

# Check the RDA installation
sub do_check
{ my ($agt) = @_;
  my ($cfg);

  $cfg = $agt->{'cfg'};
  if (@ARGV)
  { # Check the module syntax
    my ($cnt, $dir, $err, $mod);

    eval "require RDA::Agent";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
    eval "require RDA::Block";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
    eval "require RDA::Module";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
    eval "require RDA::Profile";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
    eval "require RDA::Object::Convert";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
    eval "require RDA::Object::Mrc";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
    eval "require RDA::Object::Rda";
    die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;

    $agt = bless $agt, 'RDA::Agent';
    $cfg = bless $cfg, 'RDA::Object::Rda';
    $cnt = 0;
    foreach my $arg (@ARGV)
    { $arg = File::Spec->catfile($arg);
      if ($arg =~ m/^version$/i)
      { eval {$mod = RDA::Object::Rda::check($cfg)};
        if ($@)
        { ++$cnt;
          print "Obsolete version\n" if $vrb;
        }
        else
        { print "Version $mod OK\n" if $vrb;
        }
        next;
      }
      if ($arg =~ m/^age$/i)
      { my ($bld, $ref, @tbl);

        @tbl = gmtime();
        if ($tbl[4] < 6)
        { $tbl[4] += 7;
          $tbl[5] -= 101;
        }
        else
        { $tbl[4] -= 5;
          $tbl[5] -= 100;
        }
        $ref = sprintf("%02d%02d%02d", $tbl[5], $tbl[4], $tbl[3]);
        $bld = RDA::Object::Rda::get_build($cfg);
        if ($bld lt $ref)
        { ++$cnt;
          print "Old build $bld\n" if $vrb;
        }
        else
        { print "Recent build $bld\n" if $vrb;
        }
        next;
      }
      print "Checking $arg ...\n" if $vrb;
      $dir = dirname($arg);
      $mod = basename($arg);
      if ($mod =~ m/^profiles?$/i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_DATA')
          if $dir eq '.';
        eval {RDA::Profile->new($dir)->load(undef, 1)};
        $err = $@;
      }
      elsif ($mod =~ m/^mrc\.cfg$/i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_DATA')
          if $dir eq '.';
        eval {RDA::Object::Mrc->new($agt)->load(1)};
        $err = $@;
      }
      elsif ($mod =~ m/^rda\.cfg$/i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_DATA')
          if $dir eq '.';
        eval {RDA::Profile->new($dir)->load($mod, 1)};
        $err = $@;
      }
      elsif ($mod =~ m/^groups?$/i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_DATA')
          if $dir eq '.';
        eval {RDA::Object::Convert->new($dir)->load(undef, 1)};
        $err = $@;
      }
      elsif ($mod =~ m/^convert\.cfg$/i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_DATA')
          if $dir eq '.';
        eval {RDA::Object::Convert->new($dir)->load($mod, 1)};
        $err = $@;
      }
      elsif ($mod =~ s/\.cfg$//i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_CODE')
          if $dir eq '.';
        eval {RDA::Module->new($mod, $dir)->load($agt)};
        $err = $@;
      }
      elsif ($mod =~ s/\.(ctl|def)$//i)
      { $dir = RDA::Object::Rda::get_group($cfg, 'D_RDA_CODE')
          if $dir eq '.';
        $err = RDA::Block->new($mod, $dir)->load($agt, 1);
      }
      else
      { next;
      }
      print $mod.($err ? " has syntax errors.\n" : " syntax OK\n") if $vrb;
      ++$cnt if $err;
    }
    exit(1) if $cnt;
  }
  else
  { # Check the RDA installation
    my ($cnt, $fct, $fil, $flg, $grp, $nam, $pth, $ptr, $sep, $sta, $tot,
        %tb_abr, %tb_cat, %tb_flg, %tb_obs);

    # Determine how to resolve the groups
    eval {require RDA::Object::Rda};
    $fct = $@  ? sub {my ($cfg, $grp) = @_;
                   exists($cfg->{$grp})   ? $cfg->{$grp} :
                   ($grp eq 'D_RDA')      ? File::Spec->curdir :
                   ($grp eq 'D_RDA_PERL') ? File::Spec->curdir :
                   ($grp eq 'D_RDA_HCVE') ? 'hcve' :
                                            'modules';
                   }
               : \&RDA::Object::Rda::get_group;

    # Get the file list
    print "Loading the file list ...\n" if $vrb;
    unless (open(LST, '<'.
      File::Spec->catfile(&$fct($cfg, 'D_RDA_ADM', 1), 'rda.dat')))
    { die "RDA-00011: Missing file list\n" unless open(LST, '<rda.dat');
      close(LST);
      die "RDA-00012: Directory structure not preserved\n";
    }


    # Load the file list
    $cnt = $flg = $tot = 0;
    $grp = File::Spec->curdir;
    while (<LST>)
    { s/[\n\r\s]+$//;
      if (m/^\[(D_RDA\w+)\]/)
      { $grp = &$fct($cfg, $1, 1);
        $flg = $1 eq 'D_RDA_CODE';
      }
      else
      { my ($typ, $dir, $sum, $nam) = split(/\s+/, $_, 4);
        next unless $typ && $dir && $nam && $typ ne '#';
        $dir = ($dir eq '.')
          ? $grp
          : File::Spec->catdir($grp, split(/\//, $dir));
        $tot += $sum;
        unless ($typ eq '-')
        { $nam = uc($nam) if $vms;
          $tb_cat{$dir}->{$nam} = [$sum, lc($typ) eq 'f', $typ eq lc($typ)];
          ++$tb_flg{$dir} if $flg;
        }
      }
    }
    close(LST);
    die "RDA-00013: File list corrupted\n" if $tot % 65535;

    # Load the list of obsolete modules
    if (open(SKP,
      '<'.File::Spec->catfile(&$fct($cfg, 'D_RDA_CODE', 1), 'obsolete.txt')))
    { while (<SKP>)
      { $tb_obs{lc($1)} = 0 if m/^mod:(\S+)/;
      }
      close(SKP);
    }

    # Check the RDA files
    foreach my $dir (sort keys(%tb_cat))
    { print "Checking the directory '$dir' ...\n" if $vrb;

      # Check the directory content
      if (opendir(DIR, $dir))
      { $flg = $tb_flg{$dir};
        foreach $fil (sort readdir(DIR))
        { next unless -f ($pth = File::Spec->catfile($dir, $nam = $fil));
          $nam = uc($nam) if $vms;
          $nam =~ s/\.ctl$/.def/;
          if ($flg)
          { if ($nam =~ m/^(S\d{3}([A-Za-z]\w*))\.def$/i)
            { push(@{$tb_abr{uc($2)}}, $fil)
                unless exists($tb_obs{lc($1)});
            }
            elsif ($nam =~ m/^((TL|TM|TST)(\w+))\.def$/i)
            { push(@{$tb_abr{$vms ? uc($3) : lc($3)}}, $fil)
                unless exists($tb_obs{lc($1)});
            }
          }
          next unless exists($tb_cat{$dir}->{$nam});
          $ptr = $tb_cat{$dir}->{$nam};
          $sta = '';
          $sep = "File '$pth':";
          if (-r $pth)
          { unless ($ptr->[0] == _get_cksum($pth))
            { $sta .= "$sep altered";
              $sep = ',';
            }
            unless ($ptr->[1] || $win || -x $pth)
            { $sta .= "$sep not executable";
              $sep = ',';
            }
          }
          else
          { $sta = "$sep not readable";
          }
          $ptr->[2] = 1;
          if ($sta)
          { print "\t$sta\n";
            ++$cnt;
          }
        }
        closedir(DIR);

        # Identify missing files
        foreach $nam (sort keys(%{$tb_cat{$dir}}))
        { unless ($tb_cat{$dir}->{$nam}->[2])
          { print "\tFile '".File::Spec->catfile($dir, $nam)."': missing\n";
            ++$cnt;
          }
        }
      }
      else
      { # Check if that directory contains any mandatory file
        foreach $nam (sort keys(%{$tb_cat{$dir}}))
        { unless ($tb_cat{$dir}->{$nam}->[2])
          { print "\tDirectory '$dir': not accessible\n";
            ++$cnt;
          }
        }
        next;
      }

      # Check the abbreviation unicity
      foreach my $abr (sort keys(%tb_abr))
      { next unless (scalar @{$tb_abr{$abr}}) > 1;
        print "\tAbbrevation '$abr' not unique (used in ",
          join(', ', @{$tb_abr{$abr}}), ")\n";
        ++$cnt unless $vms;
      }
    }
    die "RDA-00014: $cnt issue(s) found in the RDA installation\n" if $cnt;
    print "No issues found\n" if $vrb;
  }
  exit (0);
}

sub _get_cksum
{ my ($fil) = @_;
  my $sum = 0;

  if (open(FIL, "<$fil"))
  { binmode(FIL);
    while (<FIL>)
    { s/\$(Header|[Ii]d|[Rr]evision):\s.*?\$/\$\u$1\$/;
      $sum += unpack("%32C*", $_);
    }
    close(FIL);
  }
  $sum %= 65535;
}

# Generate the reports
sub do_collect
{ my ($slf, $flg, @arg) = @_;
  my ($cfg, $cnt, $lvl, $str, %tbl);

  print "\tCollecting diagnostic data ...\n" if $vrb;

  # Determine the module list
  $cfg = $slf->get_config->get_lists(1);
  $cnt = 0;
  if (@arg)
  { # Identify the modules
    foreach my $nam (@arg)
    { ($lvl, $str) = ($trc, $nam);
      ($lvl, $str) = ($tb_trc{$1}, $2) if $nam =~ $re_trc;
      foreach my $mod (split(/\-/, $str))
      { $tbl{$cfg->get_module($mod)} = $lvl if length($mod);
      }
    }

    # Setup the modules that still require configuration
    foreach my $nam (sort keys(%tbl))
    { $slf->setup($nam, $trc, $flg)
        unless $slf->is_disabled($nam) || $slf->is_configured($nam);
    }
    $slf->end_setup($flg);

    # Prepare the execution list
    foreach my $nam (keys(%tbl))
    { if ($slf->is_disabled($nam))
      { # Delete existing reports
        $slf->del_reports($nam);
        delete($tbl{$nam});
      }
      else
      { ++$cnt;

        # Add triggered modules
        foreach my $key (split(/,/, $slf->get_setting("${nam}_TRIGGER", '')))
        { next if exists($tbl{$key}) || $slf->is_disabled($key);
          $slf->setup($key, $trc, $flg) unless $slf->is_configured($key);
          $tbl{$key} = $tbl{$nam};
          ++$cnt;
        }
        $slf->end_setup($flg);
      }
    }
    foreach my $nam (split(/,/, $slf->get_setting('RDA_COLLECT', '')))
    { $tbl{$nam} = $trc unless exists($tbl{$nam});
    }
  }
  else
  { # Prepare the execution list
    %tbl = map {$_ => $trc}
      split(/,/, $slf->get_setting('RDA_COLLECT', ''));
    foreach my $nam ($cfg->get_modules)
    { next unless $slf->is_configured($nam);
      if ($slf->is_disabled($nam))
      { $slf->del_reports($nam);
      }
      elsif ($frc || !$slf->is_done($nam))
      { $tbl{$nam} = $trc;
        ++$cnt;
      }
    }
  }

  # Collect diagnostic information
  $slf->collect_all(\%tbl, $dbg, $flg)
    if $cnt || !defined($slf->get_setting('RPT_LAST'));
  print "\t\tNo module requiring data collection\n" if $vrb && !$cnt;
}

# Convert the reports in XML
sub do_convert
{ my ($slf, $grp, $out, @arg) = @_;
  my ($cnt, $key, $val, %tbl);

  if (defined($grp))
  { print "\tGenerating the report group ...\n" if $vrb;
    foreach my $str (@arg)
    { ($key, $val) = split(/=/, $str, 2);
      $tbl{lc("set_$key")} = decode($val) if $key && defined($val);
    }
    $cnt = $slf->get_convert->gen_group($grp, $out, $vrb, %tbl);
  }
  else
  { print "\tConverting the reports ...\n" if $vrb;
    $cnt = $slf->get_convert->gen_file($frc, $vrb, @arg);
  }
  print "\t\tNo reports to convert\n" if $vrb && !$cnt;
}

# Delete modules
sub do_delete
{ my ($slf, @arg) = @_;
  my ($cfg, $val, %tbl);

  print "\tDeleting module settings ...\n" if $vrb;

  # Get the modules that are always collected
  %tbl = map {$_ => 1} split(/,/, $val)
    if defined($val = $slf->get_setting('RDA_COLLECT'));

  # Delete the modules
  $cfg = $slf->get_config->get_lists(1);
  foreach my $arg (@arg)
  { foreach my $mod (split(/\-/, $arg))
    { $mod = $cfg->get_module($mod);
      print "\t\t- $mod ...\n" if $vrb;

      # Do not delete modules that must be executed at each run
      if (exists($tbl{$mod}))
      { print "RDA-00021: Cannot delete $mod\n";
        next;
      }

      # Delete the reports when forced
      $slf->del_reports($mod) if $frc && $slf->is_collected($mod);

      # Delete the module
      if ($slf->is_configured($mod))
      { if ($slf->is_collected($mod))
        { print "RDA-00022: Option '-f' required to delete ".$mod
            ." and its collected data\n";
        }
        else
        { $slf->del_module($mod);
        }
      }
    }
  }
}

# Explain error messages
sub do_explain
{ my ($slf) = @_;
  my ($cnt, $dsp);

  print "\tExplaining errors ...\n" if $vrb;
  $cnt = 0;
  $dsp = $slf->get_display;
  foreach my $err (@ARGV)
  { print "\n" if $cnt++;
    die "RDA-00007: Error $err not found\n"
      unless $dsp->dsp_error($err, 0);
  }
}

# Execute an external call
sub do_extern
{ my ($slf, $cls, $cmd, @arg) = @_;
  my ($err, $ret);

  # Transfer debug, force, trace, and verbose flags
  $ret = 0;
  $slf->set_temp_setting('RDA_DEBUG',1) if $dbg;
  $slf->set_temp_setting('RDA_FORCE',1) if $frc;
  $slf->set_temp_setting('RDA_TRACE',1) if $trc;
  $slf->set_temp_setting('RDA_VERBOSE',1) if $vrb;

  # Perform the external call
  $cmd = 'help' unless $cmd;
  $cls =~ s/^((rda::)?[a-z])/\U$1/;
  eval "require RDA::$cls";
  if ($@)
  { eval "require $cls";
  }
  else
  { $cls = "RDA::$cls";
  }
  die "RDA-00008: External package '$cls' not available:\n$@" if $@;
  $ret = eval "$cls\:\:$cmd(\$h, \@arg)";
  if ($err = $@)
  { die "RDA-00009: Error in external call:\n$err"
      unless $err =~ s/^\[\[(\d+)\]\]//;
    warn $err;
    exit($1);
  }

  # Don't save the setup unless requested
  $act = '?' unless $ret;

  # Indicate the exit value
  $slf->get_setting('RDA_EXIT', 0);
}

# Halting a background collection
sub do_halt
{ print "\tHalting the background collection ...\n" if $vrb;
  shift->get_daemon->halt_bgnd;
}

# Regenerate the index
sub do_index
{ print "\tGenerating the index ...\n" if $vrb;
  shift->get_render->gen_index($frc);
}

# Kill a background collection
sub do_kill
{ print "\tKilling the background collection ...\n" if $vrb;
  shift->get_daemon->kill_bgnd;
}

# List the available modules
sub do_list
{ my ($slf) = @_;
  my ($buf, $cfg, $sep);

  $cfg = $slf->get_config;
  if (@ARGV)
  { $buf = $sep = '';
    foreach my $typ (@ARGV)
    { if ($typ =~ m/^(c|q|s)$/i)
      { $buf .= _list_modules($slf, $cfg, 0, $sep);
      }
      elsif ($typ =~ m/^(g|groups?)$/i)
      { $buf .= _list_groups($slf, $sep);
      }
      elsif ($typ =~ m/^(l|levels?)$/i)
      { $buf .= _list_levels($slf, $sep);
      }
      elsif ($typ =~ m/^(m|modules?)$/i)
      { $buf .= _list_modules($slf, $cfg, 1, $sep);
      }
      elsif ($typ =~ m/^(p|profiles?)$/i)
      { $buf .= _list_profiles($slf, $sep);
      }
      elsif ($typ =~ m/^(r|root)$/i)
      { $buf .= _list_root($slf, $cfg, $sep);
      }
      elsif ($typ =~ m/^t$/i)
      { $buf .= _list_tools($slf, $cfg, 1, $sep);
        $buf .= _list_tools($slf, $cfg, 0, ".N1\n");
      }
      elsif ($typ =~ m/^tests?$/i)
      { $buf .= _list_tools($slf, $cfg, 0, $sep);
      }
      elsif ($typ =~ m/^tools?$/i)
      { $buf .= _list_tools($slf, $cfg, 1, $sep);
      }
      else
      { die "RDA-00023: Invalid list type '$typ'\n";
      }
      $sep = ".N1\n";
    }
  }
  else
  { $buf =  _list_modules($slf, $cfg, 1, '');
    $buf .= _list_tools($slf, $cfg, 1, ".N1\n");
    $buf .= _list_tools($slf, $cfg, 0, ".N1\n");
    $buf .= _list_root($slf, $cfg, ".N1\n");
    $buf .= _list_levels($slf, ".N1\n");
    $buf .= _list_profiles($slf, ".N1\n");
    $buf .= _list_groups($slf, ".N1\n");
  }
  $slf->get_display->dsp_report($buf, 1) if $buf;
}

sub _list_groups
{ my ($slf, $sep) = @_;
  my ($buf, $max, $obj, $val, %tbl);

  # Get the conversion group list
  $obj = $slf->get_convert;
  $max = 0;
  foreach my $nam ($obj->get_groups)
  { next unless ($val = $obj->get_title($nam));
    $tbl{$nam} = $val;
    $max = $val if ($val = length($nam)) > $max;
  }

  # Display the conversion group list
  return '' unless $max++;
  $buf = "${sep}.T'Available XML conversion groups are:'\n";
  foreach my $nam (sort keys(%tbl))
  { $buf .= sprintf(".I '  \001%-*s '\n%s\n\n", $max, $nam, $tbl{$nam});
  }
  $buf;
}

sub _list_levels
{ my ($slf, $sep) = @_;
  my ($buf);

  $buf = "${sep}.T'Defined setting levels are:'\n";
  foreach my $nam (sort $slf->get_profile->get_levels)
  { $buf .= ".I'  '\n$nam\n\n";
  }
  $buf;
}

sub _list_modules
{ my ($slf, $cfg, $srt, $sep) = @_;
  my ($buf, $flg, $mrk, $tbl, @tbl, %tbl);

  $buf = "${sep}.T'Available data collection modules are:'\n";
  $tbl = $cfg->get_modules;
  %tbl = map {$_ => 1} split(/,/, $slf->get_setting('RDA_COLLECT', '').','
                                 .$slf->get_setting('RDA_HANDLE', ''))
    unless $frc;
  @tbl = $srt
    ? sort {$tbl->{$a} cmp $tbl->{$b}} keys(%$tbl)
    : sort keys(%$tbl);
  foreach my $nam (@tbl)
  { next if exists($tbl{$nam});
    if ($slf->is_configured($nam))
    { $mrk = $flg = '*';
    }
    else
    { $mrk = ' ';
    }
    $buf .= sprintf(".I' %s\001%-8s '\n%s\n\n", $mrk, $tbl->{$nam} || $nam,
      $slf->get_title($nam, ''));
  }
  $buf .= ".P\n"
    ."A '*' before a module name indicates that its setup has been done.\n\n"
    if $flg;
  $buf;
}

sub _list_profiles
{ my ($slf, $sep) = @_;
  my ($buf, $flg, $max, $mrk, $obj, $val, %dft, %tbl);

  # Get the profile list
  $obj = $slf->get_profile;
  $max = 0;
  foreach my $nam ($obj->get_profiles)
  { next unless ($val = $obj->get_title($nam));
    $tbl{$nam} = $val;
    $max = $val if ($val = length($nam)) > $max;
  }

  # Display the profile list
  return '' unless $max++;
  $buf = "${sep}.T'Available profiles are:'\n";
  %dft = map {$_ => 1} $obj->get_profile;
  foreach my $nam (sort keys(%tbl))
  { if (exists($dft{$nam}))
    { $mrk = $flg = '*';
    }
    else
    { $mrk = ' ';
    }
    $buf .= sprintf(".I ' %s\001%-*s '\n%s\n\n", $mrk, $max, $nam, $tbl{$nam});
  }
  $buf .= ".P\nA '*' before a profile name indicates the current profile.\n\n"
    if $flg;
  $buf;
}

sub _list_root
{ my ($slf, $cfg, $sep) = @_;
  my ($buf, $tbl, %tbl);

  eval {
    %tbl = map {$_ => 1} $slf->get_mrc->get_collections;
    };

  $buf = '';
  $tbl = $cfg->get_modules;
  foreach my $nam (sort {$tbl->{$a} cmp $tbl->{$b}} keys(%$tbl))
  { next unless exists($tbl{$nam});
    $buf = "${sep}.T'Available root collections are:'\n" unless $buf;
    $buf .= sprintf(".I'  \001%-8s '\n%s\n\n", $tbl->{$nam} || $nam,
      $slf->get_title($nam, ''));
  }
  $buf;
}

sub _list_tools
{ my ($slf, $cfg, $typ, $sep) = @_;
  my ($buf, $flg, $mrk, $tbl, %dft);

  $tbl = $cfg->get_tests;
  %dft = map {$_ => 1} split(/,/, $slf->get_setting('RDA_TEST', ''));

  # Display the tool or test module list
  $buf = "${sep}.T'Available ".($typ ? "tools" : "test modules")." are:'\n";
  foreach my $nam (sort keys(%$tbl))
  { next if $typ xor $cfg->is_tool($nam);
    if (exists($dft{$nam}))
    { $mrk = $flg = '*';
    }
    else
    { $mrk = ' ';
    }
    $buf .= sprintf(".I' %s\001%-8s '\n%s\n\n", $mrk, $tbl->{$nam} || $nam,
      $slf->get_title($nam, ''));
  }
  $buf .= ".P\nA '*' before a module name indicates a default module.\n\n"
    if $flg;
  $buf;
}

# Display the manual pages
sub do_man
{ my ($slf, @arg) = @_;
  my ($cnt, $dsp, $obj);

  print "\tDisplaying manual pages ...\n" if $vrb;
  $dsp = $slf->get_display;
  if (@arg)
  { $obj = $slf->get_config;
    foreach my $mod (@arg)
    { if ($mod =~ m/^\w+:\w+$/)
      { $dsp->dsp_report($slf->get_mrc->display(lc($mod), $frc));
      }
      else
      { $dsp->dsp_pod($obj->get_module($mod));
      }
    }
  }
  else
  { $cnt = 0;
    if ($prf)
    { $obj = $slf->get_profile;
      foreach my $nam (split('-', $prf))
      { ++$cnt if $dsp->dsp_report($obj->display($nam, $frc));
      }
    }
    $dsp->dsp_pod('rda') unless $cnt;
  }
}

# Render output specifications
sub do_output
{ shift->get_render(1)->gen_output;
}

# Package the reports
sub do_package
{ my ($slf, $msg) = @_;
  my ($cas, $cfg, $cmd, $dir, $flt, $grp, $log, $msk, $nod, $rpt, $sep, $suf,
      $tgt);

  print "\tPackaging the reports ...\n" if $vrb;
  $cfg = $slf->get_config;
  $flt = $slf->get_output->is_filtered;
  $slf->log_suspend;

  # Move to the reporting directory
  chdir($dir = $slf->get_setting('RPT_DIRECTORY')) ||
    die "RDA-00001: Cannot change to the report directory\n";

  # Define a backup strategy when there is no setup file
  unless (defined($slf->get_setting('RDA_LAST')))
  { if (!$cfg->is_vms)
    { $slf->set_temp_setting('CMD_ZIP', $cfg->find('zip', 1));
    }
    elsif (_test_vms_zip())
    { $slf->set_temp_setting('CMD_ZIP', 'zip');
    }
    if ($cfg->is_unix)
    { $slf->set_temp_setting('CMD_TAR', $cfg->find('tar', 1));
      $slf->set_temp_setting('CMD_PAX', $cfg->find('pax', 1));
      $slf->set_temp_setting('CMD_GZIP', $cfg->find('gzip', 1));
      $slf->set_temp_setting('CMD_COMPRESS', $cfg->find('compress', 1));
    }
  }

  # Archive the reports
  $cas = $cfg->get_info('RDA_CASE');
  $msk = umask(027);
  $grp = $slf->get_setting('RPT_GROUP');
  $nod = $flt ? 'rda' : $cfg->get_node;
  $nod =~ s/[\W_]+/_/g;
  ($sep, $tgt) = $cfg->is_vms
    ? ('"', "RDA-$grp\_$nod")
    : ('',  "RDA.$grp\_$nod");
  $tgt .= '_'.$slf->get_setting('RPT_LAST')
    if $slf->get_setting('RPT_KEEP', 0);
  $tgt = lc($tgt) unless $cas;
  if (($cmd = $slf->get_setting('CMD_ZIP')) && !exists($ENV{'RDA_NO_ZIP'}))
  { $tgt .= ($suf = '.zip');
    1 while unlink($tgt);
    _package("$cmd -9 -q $sep-D$sep $tgt -\@", $grp,
      "RDA-00002: Cannot zip the reports\n");
  }
  elsif (($cmd = $slf->get_setting('CMD_PAX')) && !exists($ENV{'RDA_NO_PAX'}))
  { 1 while unlink("$tgt.tar", "$tgt.tar.Z", "$tgt.tar.gz");
    _package("$cmd -w -f $tgt.tar", $grp,
      "RDA-00003: Cannot package the reports using pax\n");
    $tgt .= ($suf = _compress($slf, $tgt, '.tar'));
  }
  elsif (($cmd = $slf->get_setting('CMD_TAR')) && !exists($ENV{'RDA_NO_TAR'}))
  { $log = (-r 'RDA.log') ? 'RDA.log' : (-r 'rda.log') ? 'rda.log' : '';
    foreach my $sub (qw(archive extern mrc remote sample))
    { $log .= ' '.File::Spec->catfile($sub, "$grp\_*")
        if _check_dir($sub, $grp);
    }
    1 while unlink("$tgt.tar", "$tgt.tar.Z", "$tgt.tar.gz");
    system("$cmd -cf $tgt.tar $log $grp\_*");
    die "RDA-00004: Cannot package the reports using tar\n" if $?;
    $tgt .= ($suf = _compress($slf, $tgt, '.tar'));
  }
  elsif (($cmd = $slf->get_setting('CMD_JAR')) && !exists($ENV{'RDA_NO_JAR'}))
  { $tgt .= ($suf = '.zip');
    $log = (-r 'RDA.log') ? 'RDA.log' : (-r 'rda.log') ? 'rda.log' : '';
    foreach my $sub (qw(archive extern mrc remote sample))
    { $log .= ' '.File::Spec->catfile($sub, "$grp\_*")
        if _check_dir($sub, $grp);
    }
    1 while unlink($tgt);
    system("$cmd $sep-cfM$sep $tgt $log $grp\_*");
    die "RDA-00019: Cannot package the reports using jar\n" if $?;
  }
  elsif (($cmd = $slf->get_setting('CMD_7ZIP')) && !exists($ENV{'RDA_NO_7ZIP'}))
  { $tgt .= ($suf = '.zip');
    $log = (-r 'RDA.log') ? 'RDA.log' : (-r 'rda.log') ? 'rda.log' : '';
    foreach my $sub (qw(archive extern mrc remote sample))
    { $log .= ' '.File::Spec->catfile($sub, "$grp\_*")
        if _check_dir($sub, $grp);
    }
    1 while unlink($tgt);
    system("$cmd a $tgt -y -ssw $log $grp\_* >".File::Spec->devnull);
    die "RDA-00026: Cannot package the reports using 7zip\n" if $?;
  }
  else
  { die "RDA-00006: Archive command not -yet- identified\n";
  }
  umask($msk);

  # Move the report package to the transfer directory
  if ($rpt = $slf->get_setting('RPT_TRANSFER'))
  { # Move the report package to the transfer directory
    die "RDA-00020: Cannot create the transfer directory:\n $!\n"
        unless -d 'transfer' || mkdir('transfer', 0750);
    $rpt .= $suf;
    move($tgt, File::Spec->catfile('transfer', $rpt));
  }

  # Return to the RDA install directory
  chdir($cfg->get_group('D_RDA')) ||
    die "RDA-00000: Cannot change to the RDA install directory\n";

  # Display the thanks message
  $slf->log_resume;
  $slf->log('P', $tgt);
  if ($rpt)
  { print "\t\t$rpt created for transfer\n" if $vrb;
  }
  elsif ($msg)
  { # Display the report message
    $log = "$grp\__start.htm";
    $log = lc($log) unless $cas;
    if ($win)
    { $slf->dsp_text('Packaging/Windows', 0, beg => $log, tgt => $tgt);
    }
    elsif ($^O eq 'cygwin')
    { $slf->dsp_text('Packaging/Cygwin', 0, beg => $log, tgt => $tgt);
    }
    elsif ($vms)
    { $slf->dsp_text('Packaging/VMS', 0, beg => $log,
        tgt => File::Spec->catfile($slf->get_setting('RPT_DIRECTORY'), $tgt));
    }
    else
    { my ($dir, $ftp);

      $ftp = File::Spec->catfile($slf->get_setting('RPT_DIRECTORY'));
      $ftp = File::Spec->catfile(get_cwd(), $ftp)
        unless File::Spec->file_name_is_absolute($ftp);
      if ($dir = $ENV{'HOME'})
      { $dir = File::Spec->catdir($dir);
        $ftp =~ s#^(/export)?$dir/##;
      }
      $slf->dsp_text('Packaging', 0, beg => $log, tgt => $tgt, ftp => $ftp);
    }
  }
  elsif ($vrb)
  { print "\t\t$tgt created\n";
  }
}

sub _check_dir
{ my ($dir, $grp) = @_;

  $grp = qr/^$grp\_/i;
  if (opendir(DIR, $dir))
  { foreach my $nam (readdir(DIR))
    { return 1 if $nam =~ $grp;
    }
    closedir(DIR);
  }
  0;
}

sub _test_vms_zip
{ my ($slf) = @_;

  eval {
    local $SIG{'__WARN__'} = sub { };
    local $SIG{'PIPE'} = 'IGNORE';
    open(PIPE, "PIPE zip -h 2>SYS\$OUTPUT |") or die "Bad open\n";
    1 while <PIPE>;
    close(PIPE) or die "Bad close\n";
  };
  ($@ || $?) ? 0 : 1;
}

sub _package
{ my ($cmd, $grp, $err) = @_;
  my $alt;

  $alt = qr/^$grp\_0.*\.fil$/i;
  $grp = qr/^$grp\_/i;

  # Get first the alias files and the log file
  opendir(DIR, File::Spec->curdir)
    or die "RDA-00005: Cannot list the reports\n";
  open(CMD, "| $cmd") or die $err;
  foreach my $nam (readdir(DIR))
  { print CMD $nam, "\n" if $nam =~ $alt || $nam =~ m/^RDA.log$/i;
  }
  closedir(DIR);

  # Get the report files
  opendir(DIR, File::Spec->curdir)
    or die "RDA-00005: Cannot list the reports\n";
  foreach my $nam (readdir(DIR))
  { next if $nam =~ $alt;
    print CMD $nam, "\n" if $nam =~ $grp;
  }
  closedir(DIR);

  # Get the files from the subdirectories
  foreach my $sub (qw(archive extern mrc remote sample))
  { if (opendir(DIR, $sub))
    { foreach my $nam (readdir(DIR))
      { print CMD File::Spec->catfile($sub, $nam), "\n" if $nam =~ $grp;
      }
      closedir(DIR);
    }
  }
  close(CMD) or die $err;
}

sub _compress
{ my ($slf, $tgt, $suf) = @_;
  my $cmd;

  if (($cmd = $slf->get_setting('CMD_GZIP')) &&
    !exists($ENV{'RDA_NO_GZIP'}))
  { system("$cmd -9 -q $tgt$suf");
    $suf .= '.gz';
  }
  elsif (($cmd = $slf->get_setting('CMD_COMPRESS')) &&
    !exists($ENV{'RDA_NO_COMPRESS'}))
  { system("$cmd $tgt$suf");
    $suf .= '.Z';
  }
  $suf;
}

# Execute a post treatment
sub do_post
{ my ($slf, $flg, $typ) = @_;
  my ($mod, $run);

  foreach my $nam ($slf->grep_setting("^$typ", "n"))
  { if ($mod = $slf->get_setting($nam))
    { unless ($run)
      { print "\tExecuting the post treatment ($typ) ...\n" if $vrb;
        $run = 1;
      }
      exit(1) if $slf->collect($mod, $dbg, $trc, $flg);
    }
  }
}

# Display the setup questions
sub do_question
{ my ($slf, @arg) = @_;
  my ($cfg, $dsp);

  print "\tDisplaying setup questions ...\n" if $vrb;
  if (@arg)
  { $cfg = $slf->get_config;
    $dsp = $slf->get_display;
    foreach my $arg (@arg)
    { foreach my $mod (split(/\-/, $arg))
      { $dsp->dsp_report($slf->dsp_module($cfg->get_module($mod)));
      }
    }
  }
}

# Generate the reports
sub do_render
{ my ($slf, @arg) = @_;
  my ($cnt, $obj);

  print "\tGenerating the reports ...\n" if $vrb;
  $cnt = 0;
  $obj = $slf->get_render;
  if (@arg)
  { # Treat all arguments
    foreach my $arg (@arg)
    { my ($nam, $ttl) = split(/\:/, $arg, 2);
      print "\t\t- $nam ...\n" if $vrb;
      $obj->gen_html($nam, $ttl);
      ++$cnt;
    }
  }
  else
  { # Treat existing reports
    foreach my $fil ($obj->get_reports($frc))
    { print "\t\t- $fil ...\n" if $vrb;
      $obj->gen_html($fil);
      ++$cnt;
    }
    print "\t\tNo pending report\n" if $vrb && !$cnt;
  }

  # Generate the common files and the index page
  if ($cnt || -d $slf->get_output->get_path('R'))
  { print "\t\t- Report index ...\n" if $vrb;
    $obj->gen_index;
  }
}

# Execute the setup phase
sub do_setup
{ my ($slf, $flg, $nxt, $dft, @arg) = @_;
  my ($cfg, $cnt, $lvl, $str, %tbl);

  print "\tSetting up ...\n" if $vrb;
  $cfg = $slf->get_config->get_lists(1);
  if (@arg)
  { # Identify the modules from arguments
    foreach my $nam (@arg)
    { ($lvl, $str) = ($trc, $nam);
      ($lvl, $str) = ($tb_trc{$1}, $2) if $nam =~ $re_trc;
      foreach my $mod (split(/\-/, $str))
      { $tbl{$cfg->get_module($mod)} = $lvl if length($mod);
      }
    }

    # Setup requested modules
    foreach my $nam (sort keys(%tbl))
    { next if $slf->is_reconfigured($nam);
      $slf->setup($nam, $tbl{$nam}, $flg, $dft);
    }
    $slf->end_setup($flg);
  }
  else
  { # Setup available modules
    $cnt = 0;
    foreach my $nam ($cfg->get_modules)
    { next if $slf->is_reconfigured($nam)
        || ($slf->is_configured($nam) && !$frc);
      $slf->setup($nam, $trc, $flg);
      ++$cnt;
    }
    $slf->end_setup($flg);
    print "\t\tNo unconfigured module\n" if $vrb && !$cnt;
    $slf->dsp_text($win ? 'Setup/Windows' : $vms ? 'Setup/VMS' : 'Setup')
      unless $nxt;
  }
}

# Test the database access
sub do_test
{ my ($slf, @arg) = @_;
  my ($arg, $cfg, $cnt, $lvl, $man, $mod, @sct, %tbl);

  print "\tTesting ...\n" if $vrb;

  # Determine the module list
  $cfg = $slf->get_config->get_lists(-1);
  $cnt = 0;
  if (@arg)
  { # Prepare the execution list
    foreach my $nam (@arg)
    { $lvl = $trc;
      ($lvl, $nam) = ($tb_trc{$1}, $2) if $nam =~ $re_trc;
      if ($nam =~ $re_tst)
      { $man = $1 || '';
        $arg = $3 || '';
        ($nam, @sct) = split(/\-/, $2);
        $nam = $cfg->get_module($nam);
        next unless $nam =~ m/^(TL|TM|TST)\w+$/i;
        $tbl{$man.join('-', $nam, @sct).$arg} = $lvl;
        ++$cnt;
      }
    }
  }
  else
  { # Prepare the execution list
    %tbl = map {$_ => $trc}
      split(/,/, $slf->get_setting('RDA_TEST', ''));
    $cnt = keys(%tbl);
  }

  # Collect test information
  if ($cnt)
  { foreach my $nam (sort keys(%tbl))
    { $nam =~ $re_tst;
      $slf->set_setting('TST_MAN', $1);
      $slf->set_setting('TST_ARGS', $4);
      ($mod, @sct) = split(/\-/, $2);
      exit(1) if $slf->collect($mod, $dbg, $tbl{$nam}, 0, @sct);
    }
  }
  print "\t\tNo test module\n" if $vrb && !$cnt;
}

# Check for RDA upgrade
sub do_upgrade
{ my ($bin, $max) = @_;
  my ($ccr, $fil, $mod, $nul, $ofh, $tim, @sta);

  # Abort when the RDA directory is not writable
  return 1 unless -w $bin;

  # Abort when OCM is not available
  return 2 unless -f ($ccr = $win              ? '..\ccr\bin\emCCR.bat' :
                             ($^O eq 'cygwin') ? '../ccr/bin/emCCR.bat' :
                                                 '../ccr/bin/emCCR');

  # Skip when OCM module will not be used
  return 3 unless $act eq '*' || $doC || $doS;

  # Skip when tested recently
  $fil = File::Spec->catfile($bin, ($win || $^O eq 'cygwin')
    ? 'upgrade.ini'
    : '.upgrade');
  $tim = time;
  return 4 if -f $fil && (@sta = stat($fil)) && ($tim - $sta[9]) < $max;

  # Request updates
  print "\tChecking for upgrade ...\n" if $vrb;
  $mod = eval "O_WRONLY | O_CREAT | O_APPEND";
  $mod = '>>' if $@;
  $nul = $win ? 'NUL' : '/dev/null';
  if (system("$ccr getupdates >$nul 2>&1") == 0x300)
  { # Disable further update requests
    $ofh = IO::File->new;
    if ($ofh->open(File::Spec->catfile($bin, 'rda.cfg'), $mod, 0640))
    { print {$ofh} "NO_GETUPDATES=\"Exit 3\"\n";
      $ofh->close;
    }
    return -1;
  }

  # Indicate the last test
  if (-f $fil)
  { utime $tim, $tim, $fil;
  }
  else
  { $ofh = IO::File->new;
    $ofh->close if $ofh->open($fil, $mod, 0640);
  }
  0;
}

# Display the version numbers
sub do_version
{ my ($slf) = @_;
  my ($cfg, $cnt, $dir, $fil, $ver);

  # Force Perl package load
  eval {
    $slf->get_convert;
    $slf->get_discover;
    $slf->get_display;
    $slf->get_mrc;
    $slf->get_output;
    $slf->get_profile;
    $slf->get_render;
    $slf->init($trc);
    $slf->get_daemon;
  };
  print $@ if $@ && $trc;

  # Display the RDA version
  $cfg = $slf->get_config;
  print "RDA ".$cfg->get_version
    ."\nBuild: ".$cfg->get_build
    ."\nInstallation type: ".$cfg->get_info('typ')
    ."\nWorking directory: ".$cfg->get_group('D_CWD')
    ."\nOperating system: $^O\n\n";

  # Display the version of the RDA modules
  print "VERSION OF RDA MODULES:\n";
  foreach $dir ($cfg->get_group('D_RDA_PERL'),
    $cfg->get_dir('D_RDA_PERL', 'RDA'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Archive'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Driver'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Handle'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Library'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Library/Remote'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Local'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Object'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Operator'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Value'),
    $cfg->get_dir('D_RDA_PERL', 'RDA/Web'),
    $cfg->get_group('D_RDA_HCVE'),
    $cfg->get_group('D_RDA_CODE'))
  { if (opendir(DIR, $dir))
    { print "$dir:\n";
      foreach my $nam (sort readdir(DIR))
      { next if $nam =~ m/^\./;
        if (-f ($fil = File::Spec->catfile($dir, $nam)) && open(FIL, "<$fil"))
        { $cnt = 20;
          while (<FIL>)
          { if (m/\$[Ii]d\:\s+\S+\s+(\d+)(\.(\d+))?\s/)
            { printf("%-16s%5d.%02d\n", $nam, $1, $3 || 0);
              last;
            }
            last unless --$cnt > 0;
          }
          close(FIL);
        }
      }
      closedir(DIR);
      print "\n";
    }
  }

  # Display the version of already loaded Perl modules
  print "VERSION OF LOADED PERL PACKAGES:\n";
  foreach my $mod (sort keys(%INC))
  { next unless defined($dir = $INC{$mod});
    $dir = File::Spec->catdir($dir);
    $dir = '.' unless $dir;
    next unless $mod =~ s/\.(pl|pm)$//;
    next unless $frc || $mod !~ m/^RDA/;
    $mod =~ s/[\\\/]/::/g;
    $ver = eval "\$$mod\::VERSION" || '?';
    $ver = sprintf("%d.%02d", $1, $3 || 0) if $ver =~ m/^(\d+)(\.(\d+))?$/;
    printf("%-26s%8s %s\n", $mod, $ver, $dir);
  }
}

# Produce module cross references
sub do_xref
{ my ($slf, @arg) = @_;
  my ($cfg, $dir, $dsp, $mod);

  eval "require RDA::Block";
  die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
  eval "require RDA::Module";
  die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;
  eval "require RDA::Object::Mrc";
  die "RDA-00010: Cannot locate required RDA modules:\n$@" if $@;

  $cfg = $slf->get_config;
  $dsp = $slf->get_display;
  foreach my $arg (@arg)
  { print "Treating $arg ...\n" if $vrb;
    $dir = dirname($arg);
    $mod = basename($arg);
    if ($mod =~ m/^profiles?$/i)
    { $dsp->dsp_report($slf->get_profile->load->xref($frc));
    }
    elsif ($mod =~ m/^mrc\.cfg$/i)
    { $dsp->dsp_report($slf->get_mrc->xref($frc));
    }
    elsif ($mod =~ m/^rda\.cfg$/i)
    { $dsp->dsp_report($slf->get_profile->load($mod)->xref($frc));
    }
    elsif ($mod =~ m/^groups?$/i)
    { $dsp->dsp_report($slf->get_convert->load->xref($frc));
    }
    elsif ($mod =~ m/^convert\.cfg$/i)
    { $dsp->dsp_report($slf->get_convert->load($mod)->xref($frc));
    }
    elsif ($mod =~ s/\.cfg$//i)
    { $dir = $cfg->get_group('D_RDA_CODE') if $dir eq '.';
      $dsp->dsp_report(RDA::Module->new($mod, $dir)->xref($slf));
    }
    elsif ($mod =~ s/\.(ctl|def)$//i)
    { $dir = $cfg->get_group('D_RDA_CODE') if $dir eq '.';
      $dsp->dsp_report(RDA::Block->new($mod, $dir)->xref($slf));
    }
    elsif ($mod =~ s/\.(pm)$//i)
    { $dsp->dsp_report(RDA::Object::xref("RDA::Object::$mod"));
    }
    elsif ($mod =~ m/^RDA::Object::/i)
    { $dsp->dsp_report(RDA::Object::xref($mod));
    }
  }
}

# Get the working directory
sub get_cwd
{ return File::Spec->catdir(getcwd());
}

# Create dynamic working directory
sub mk_work
{ my $dir = shift;

  if ($dir =~ s#\$\$#$$#g)
  { mkdir($dir, 0700) unless -d $dir;
    print "|RDA_WORK=$dir|\n";
  }
  $dir;
}

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
