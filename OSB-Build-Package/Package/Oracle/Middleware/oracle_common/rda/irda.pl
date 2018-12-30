# irda.pl: Collect diagnostic information in DFW/IPS 11g contexts
#
# $Id: irda.pl,v 1.34 2012/08/21 09:59:26 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/bin/irda.pl,v 1.34 2012/08/21 09:59:26 mschenke Exp $
#
# Change History
# 20120821  MSC  Specify mkdir permissions.

eval 'exec perl -w -S "$0" ${1+"$@"}'
  if 0; # not running under some shell

use strict;

BEGIN
{ use Cwd;
  use Getopt::Std;
  use File::Basename;
  use File::Copy;
  use File::Spec;
  use IO::Handle;
}

# Define default agent attributes
my %tb_agt = (
  bkp => 0,
  out => 0,
  sav => 0,
  yes => 1,
  );

# Define software relocation files and extension pattern
my $EXT = qr/\.(vms|win|cyg|ini)$/;
my %tb_cnf = (
  'VMS'     => ['irdacfg.vms',                'irdacfg.ini'],
  'MSWin32' => ['irdacfg.win',                'irdacfg.ini'],
  'MSWin64' => ['irdacfg.win',                'irdacfg.ini'],
  'cygwin'  => ['irdacfg.cyg', 'irdacfg.win', 'irdacfg.ini'],
  '*'       => [                              'irdacfg.ini'],
  );
my @tb_fil = ('irda.pl');

# Check the operating system
my $vms = ($^O eq 'VMS');
my $win = ($^O eq 'MSWin32' || $^O eq 'MSWin64');

# Set the defaults
my $dbg = 0;          # No debug
my $edt;              # No temporary settings
my $ful = 0;          # No full/force
my $inp = 0;          # Do not read extra information from STDIN
my $mod = 'S';        # Perform startup
my $out = 1;          # Redirect standard output and error
my $prg = 0;          # No progress log
my $pro;              # No configuration prototype
my $trc = 0;          # No trace
my $ver = 'cv0100';   # Default IRDA type
my $vrb = 0;          # Silent mode

# Parse the options
my %opts;
getopts('CIRSTc:de:fhioqtv', \%opts);
$mod = 'C'                if $opts{'C'};
$mod = 'I'                if $opts{'I'};
$mod = 'R'                if $opts{'R'};
$mod = 'S'                if $opts{'S'};
$mod = 'T'                if $opts{'T'};
$pro = $opts{'c'}         if $opts{'c'};
$dbg = 1                  if $opts{'d'};
$edt = $opts{'e'}         if $opts{'e'};
$ful = 1                  if $opts{'f'};
$inp = 1                  if $opts{'i'};
$out = 0                  if $opts{'o'};
$tb_agt{'out'} = 1        if $opts{'q'};
$trc = 2                  if $opts{'t'};
$tb_agt{'vrb'} = $vrb = 1 if $opts{'v'};

if ($opts{'h'} || (@ARGV < 1 && $mod ne 'C'))
{ print <<'EOF';
Usage : irda.pl [-dfioqtv] [-c conf] [-e list] [-C|I|S|T] [request|dir ...]
        -C      Check the rule files for consistency
        -I      Install the IRDA bootstrap in specified directories
        -S      Start RDA
        -T      Executes the specified test module
        -c conf Specify the prototype for the bootstrap configuration file
        -d      Set debug mode
        -e list Specify a list of alternate setting definitions (var=val,...)
        -f      Set full/force mode
        -i      Enable reading of information from STDIN
        -o      Disable standard output and error redirection
        -q      Set quiet mode
        -t      Set trace mode
        -v      Set verbose mode
        dir     Directory where to install RDA bootstrap
        request Full path to the request file
EOF
  exit(1);
}

# Ajust the @INC when needed
unshift(@INC, '.') unless grep {$_ eq '.'} @INC;

# Execute the request
if ($mod eq 'C')
{ exit(1) if do_check();
  print "No errors found\n" if $vrb;
}
elsif ($mod eq 'I')
{ do_install(@ARGV);
}
elsif ($mod eq 'R')
{ do_run(shift(@ARGV));
}
elsif ($mod eq 'S')
{ do_start(shift(@ARGV));
}
elsif ($mod eq 'T')
{ do_test(@ARGV);
}

# Stop processing
exit(0);

# --- Execution modes ---------------------------------------------------------

# Check the rule file consistency
sub do_check
{ my ($agt, $obj);

  # Load the RDA software configuration
  load_rda();

  # Create RDA Agent
  print "\tCreating the RDA Agent\n" if $vrb;
  eval "require RDA::Agent";
  die "IRDA-00004: Cannot locate required RDA modules:\n$@" if $@;
  $agt = eval "RDA::Agent->new(\%tb_agt, oid => 'check')";
  die "IRDA-00005: Cannot start the RDA Agent:\n$@" if $@;

  # Load the request parameters, the rules and the plugins
  print "\tLoading rules and plugins ...\n" if $vrb;
  eval "require IRDA::Prepare";
  die "IRDA-00006: Cannot locate required IRDA modules:\n$@" if $@;
  $obj = IRDA::Prepare->new($agt, $ver);
  $obj->load_rules;
  $obj->load_plugins;

  # Check the rule files
  $obj->check_rules($ful);
}

# Install RDA bootstrap in Oracle homes
sub do_install
{ my (@ora) = @_;
  my ($bin, $cnt, $cnf, $dst, $ext, $rda);

  # Change to the install directory
  chdir($bin)
    if ($bin = dirname(File::Spec->catfile($0))) ne '.'
    || ($^X =~ m/\birda_\w+56$/ && ($bin = dirname($^X)) ne '.');
  $bin = get_cwd() unless File::Spec->file_name_is_absolute($bin);

  # Check the prototype file and its extension
  ($cnf) = @{$tb_cnf{'*'}};
  if (defined($pro))
  { die "IRDA-00010: Prototype file '$pro' does not exist\n" unless -f $pro;
    die "IRDA-00011: Prototype file '$pro' has invalid extension\n"
      unless $pro =~ $EXT;
    $ext = lc($1);
    $cnf =~ s/\.ini$/.$ext/;
  }

  # Create the bootstrap in the target directories
  foreach my $ora (@ora)
  { # Check the target directory
    die "IRDA-00012: '$ora' not found\n"
      unless -d $ora;
    $rda = File::Spec->catdir($ora, 'rda');
    print "\tCreating bootstrap in '$rda' ...\n" if $vrb;
    if (-e $rda)
    { die "IRDA-00013: '$rda' already exists\n"
        unless $ful;
      die "IRDA-00014: '$rda' is not a directory\n"
        unless -d $rda;
    }
    else
    { mkdir($rda, 0755)
        or die "IRDA-00015: Cannot create bootstrap directory '$rda':\n$!\n";
    }

    # Copy the script files
    foreach my $fil (@tb_fil)
    { next unless -e $fil;
      $dst = File::Spec->catfile($rda, $fil);

      # Remove any existent version
      if (-f $dst)
      { $cnt = 0;
        $cnt++ while unlink($dst);
        die "IRDA-00016: Cannot remove old version of '$dst':\n$!\n"
          unless $cnt;
      }

      # Copy the file
      File::Copy::copy($fil, $dst)
        or die "IRDA-00017: Cannot install '$dst':\n$!\n";
      chmod(0555, $dst);
    }

    # Create the configuration file
    $dst = File::Spec->catfile($rda, $cnf);
    if (-f $dst)
    { $cnt = 0;
      $cnt++ while unlink($dst);
      die "IRDA-00016: Cannot remove old version of '$dst':\n$!\n"
        unless $cnt;
    }
    open(CNF, ">$dst")
      or die "IRDA-00018: Cannot create '$dst':\n$!\n";
    binmode(CNF);
    print CNF "RDA_HOME=\"$bin\"\n";
    if (defined($pro))
    { open(PRO, "<$pro")
        or die "IRDA-00019: Cannot read prototype file '$pro': $!\n";
      while(<PRO>)
      { s/[\n\r\s]+$//;
        print CNF "$_\n" unless m/^RDA_HOME=/;
      }
      close(PRO);
    }
    close(CNF);
    chmod(0444, $dst);
  }
}

# Perform an RDA collection
sub do_run
{ my ($fil, $cfg) = @_;
  my ($agt, $cnt, $flg, $max, $obj, $pth, $req, $wrk, @tbl, %tbl);

  # Load configuration file
  $cfg = load_configuration(0) unless $cfg;
  $dbg = $cfg->{'RDA_DEBUG'}   if exists($cfg->{'RDA_DEBUG'});
  $trc = $cfg->{'RDA_TRACE'}   if exists($cfg->{'RDA_TRACE'});
  $vrb = $cfg->{'RDA_VERBOSE'} if exists($cfg->{'RDA_VERBOSE'});
  $flg = exists($cfg->{'RDA_PREPARE'}) ? $cfg->{'RDA_PREPARE'} : $trc;

  # Load the request file
  $req = load_request($fil);

  # Start the RDA agent
  $pth = $req->{'OUTPUT_DIR'} || dirname($fil);
  $agt = start_agent('ips', $pth, 'output.log', 1);

  # Open the progress log
  $prg = 1
    if !exists($cfg->{'RDA_NO_PROGRESS'})
    && -w ($pth = File::Spec->catfile($pth, File::Spec->updir, "progress.log"))
    && open(PRG, ">>$pth");

  # Load the request parameters, the rules and the plugins
  $cnt = 1;
  log_progress("RDA ".$cnt++."/?: Prepares RDA collection\n");
  print "\tLoading rules and plugins ...\n" if $vrb;
  eval "require IRDA::Prepare";
  die "IRDA-00006: Cannot locate required IRDA packages:\n$@" if $@;
  $obj = IRDA::Prepare->new($agt, $ver, $flg);
  $obj->load_request($req);
  $obj->load_configuration($cfg);
  $obj->load_rules;
  $obj->load_plugins;

  # Resolve the rule selection settings
  print "\tApplying selection rules ...\n" if $vrb;
  $obj->apply_selections;

  # Discover the module settings
  print "\tDiscovering module settings ...\n" if $vrb;
  $obj->discover_settings;

  # Initialize the agent
  $agt->init($trc, 1);

  # Setup RDA
  if (defined($agt->get_setting('RAC_PROFILE')))
  { log_progress("RDA ".$cnt++."/?: Configures a remote collection\n");
    print "\tConfiguring a remote collection ...\n" if $vrb;
    unless (-d ($wrk = $agt->get_config->get_group('D_CWD')))
    { mkdir($wrk, 0755)
        or die "IRDA-00007: Cannot create work directory '$wrk':\n$!\n";
    }
    eval "require RDA::Remote";
    die "IRDA-00008: Cannot locate required RDA::Remote package:\n$@" if $@;
    $agt->set_temp_setting('RDA_TRACE', $trc);
    RDA::Remote::setup_cluster($agt, '/');
  }
  print "\tSetting up ...\n" if $vrb;
  foreach my $nam ($obj->get_modules)
  { $agt->setup($nam, $flg, 0) unless $agt->is_reconfigured($nam);
  }
  $agt->end_setup(0);

  # Collect diagnostic information
  print "\tCollecting diagnostic data ...\n" if $vrb;
  $obj->apply_settings;
  %tbl = map {$_ => exists($cfg->{"TRACE_$_"}) ? $cfg->{"TRACE_$_"} : $trc}
    split(/,/, $agt->get_setting('RDA_COLLECT', ''));
  foreach my $nam ($agt->get_config->get_modules)
  { $nam =~ s/\.(cfg|ctl|def)$//;
    next unless $agt->is_configured($nam);
    if ($agt->is_disabled($nam))
    { $agt->del_reports($nam);
    }
    elsif (!$agt->is_collected($nam))
    { $tbl{$nam} = exists($cfg->{"TRACE_$nam"}) ? $cfg->{"TRACE_$nam"} : $trc;
    }
  }

  @tbl = sort keys(%tbl);
  $max = $cnt + scalar @tbl;
  foreach my $nam (@tbl)
  { foreach my $key (split(/,/, $agt->get_setting("${nam}_TEMP", '')))
    { $agt->set_temp_setting($key, '') if $key;
    }
  }
  foreach my $nam (@tbl)
  { log_progress("RDA ".$cnt++."/$max: ".$agt->get_title($nam, "Collects $nam")
      ."\n");
    exit(1) if $agt->collect($nam, $dbg, $tbl{$nam}, 0);
  }

  # Render RDA
  log_progress("RDA $max/$max: Generates the reports\n");
  print "\tGenerating the reports ...\n" if $vrb;
  $obj = $agt->get_render;
  foreach my $fil ($obj->get_reports)
  { print "\t\t- $fil ...\n" if $vrb;
    $obj->gen_html($fil);
  }
  print "\t\t- Report index ...\n" if $vrb;
  $obj->gen_index;

  # Close the progress log
  log_progress("RDA execution completed\n");
  close(PRG) if $prg;

  # Cleanup
  # TBD
}

# Start a RDA collection
sub do_start
{ my ($req) = @_;
  my ($bin, $cfg, $fil, $opt);

  # Change to the start directory
  chdir($bin)
    if ($bin = dirname(File::Spec->catfile($0))) ne '.'
    || ($^X =~ m/\birda_\w+56$/ && ($bin = dirname($^X)) ne '.');

  # Grab the software relocation settings and launch the RDA collection
  $cfg = load_configuration(1);

  # Adjust the environment
  $ENV{'RDA_FILTER'} = File::Spec->catfile($cfg->{'RDA_FILTER'})
    if exists($cfg->{'RDA_FILTER'});

  # Check for possible relocation
  if (exists($cfg->{'RDA_HOME'}) || exists($cfg->{'RDA_SCRIPT'}))
  { $bin = exists($cfg->{'RDA_HOME'})   ? $cfg->{'RDA_HOME'}   : '.';
    $fil = exists($cfg->{'RDA_SCRIPT'}) ? $cfg->{'RDA_SCRIPT'} : 'irda.pl';
    $opt = '-R';
    $opt .= 'd' if $dbg;
    $opt .= 'i' if $inp;
    $opt .= 'o' unless $out;
    $opt .= 'q' if $tb_agt{'out'};
    $opt .= 't' if $trc;
    $opt .= 'v' if $vrb;
    exec($^X, File::Spec->catfile($bin, $fil), $opt, $req);
  }

  # Execute the collection
  do_run($req, $cfg);
}

# Test the database access
sub do_test
{ my ($agt, $arg, $cfg, $key, $nam);

  # Load configuration file
  $cfg = load_configuration(0);
  $dbg = $cfg->{'RDA_DEBUG'}   if exists($cfg->{'RDA_DEBUG'});
  $trc = $cfg->{'RDA_TRACE'}   if exists($cfg->{'RDA_TRACE'});
  $vrb = $cfg->{'RDA_VERBOSE'} if exists($cfg->{'RDA_VERBOSE'});

  # Start the RDA agent
  $agt = start_agent('test', $ENV{'RDA_OUTPUT'}, 'test.log', 0);

  # Execute the test modules
  if (@_)
  { $agt->init($trc);

    foreach my $mod (@_)
    { next unless $mod =~ m/^([^:]+)(:(.*))?$/;
      $agt->set_setting('TST_MAN', 0);
      $agt->set_setting('TST_ARGS', $3 || '');
      $nam = $1;
      $nam =~ s/\.(cfg|ctl|def)$//i;
      next unless $nam =~ m/^(TL|TST)\w+$/i;
      print "\tRunning $nam tool ...\n" if $vrb;
      $key = uc("TRACE_$nam");
      exit(1) if $agt->collect($nam, $dbg,
        exists($cfg->{$key}) ? $cfg->{$key} : $trc, 0);
    }
  }
}

# --- Auxiliary routines ------------------------------------------------------

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

# Get the working directory
sub get_cwd
{ return File::Spec->catdir(getcwd());
}

# Load the configuration parameters when present
sub load_configuration
{ my ($flg) = @_;
  my ($tbl, @cfg);

  # Determine possible configuration files
  @cfg = @{$tb_cnf{exists($tb_cnf{$^O}) ? $^O : '*'}};
  unshift(@cfg, File::Spec->catfile($ENV{'RDA_CONFIG'}))
    if exists($ENV{'RDA_CONFIG'});

  # Scan the configuration file
  foreach my $cfg (@cfg)
  { if (open(CFG, "<$cfg"))
    { # Load the configuration parameters
      while (<CFG>)
      { s/[\n\r\s]+$//;
        $tbl->{$1} = $2 if m/^(\w+)\s*=\s*"(.*)"/ || m/^(\w+)=(.*)$/;
      }
      close(CFG);

      # Adjust the environment
      $ENV{'RDA_CONFIG'} = File::Spec->catfile(get_cwd(), $cfg) if $flg;

      # Return the parameter hash reference
      return $tbl;
    }
  }

  # Return the parameter hash reference
  $tbl;
}

# Load the RDA software configuration
sub load_rda
{ my ($wrk) = @_;
  my ($bin, $cfg, $inc, $typ, @edt);

  # Change to the install directory
  chdir($bin)
    if ($bin = dirname(File::Spec->catfile($0))) ne '.'
    || ($^X =~ m/\birda_\w+56$/ && ($bin = dirname($^X)) ne '.');
  $bin = get_cwd() unless File::Spec->file_name_is_absolute($bin);

  # Determine installation type
  $inc = File::Spec->catdir($bin, File::Spec->updir(), 'perl');
  if (-f File::Spec->catfile($inc, 'RDA', 'Agent.pm'))
  { $typ = 'izu';
  }
  else
  { $typ = 'dft';
    $inc = $bin;
  }
  $tb_agt{'cfg'} = $cfg = {typ => $typ};

  # Extract RDA directory structure from an existing configuration file
  if (open(CFG, '<'.File::Spec->catfile($bin, 'rda.cfg')))
  { while (<CFG>)
    { $cfg->{$1} = decode($2) if m/^(D_[A-Z]\w*[A-Z]+)="([^"]*)"/;
    }
    close(CFG);
  }

  # Extract RDA configuration from the edit specifications
  edit(\@edt, $cfg, $ENV{'RDA_EDIT'}) if exists($ENV{'RDA_EDIT'});
  edit(\@edt, $cfg, $edt)             if defined($edt);
  if ($inp)
  { while (<STDIN>)
    { if (m/^(\w+)='(.*)'/)
      { push(@edt, uc($1).'='.$2);
      }
      elsif (m/^#EOF\b/)
      { last;
      }
    }
  }
  $tb_agt{'edt'} = [@edt]             if @edt;

  # Check for an alternate Perl module location
  if (exists($cfg->{'D_RDA_PERL'}))
  { $inc = $cfg->{'D_RDA_PERL'};
    $inc = File::Spec->file_name_is_absolute($inc)
      ? File::Spec->catdir($inc)
      : File::Spec->catdir($bin, $inc);
  }

  # Adapt the context
  $cfg->{'D_CWD'} = defined($wrk) ? $wrk : $bin;
  $cfg->{'D_RDA'} = $bin;
  push(@INC, $inc);

  # Return the top RDA directory
  $bin;
}

# Log the progress
sub log_progress
{ my ($txt) = @_;

  print IPS $txt if $out;
  syswrite(PRG, $txt, length($txt)) if $prg;
}

# Load the request parameters in a hash
sub load_request
{ my ($fil) = @_;
  my ($tbl);

  # Scan the request file
  $tbl = {REQUEST_FILE => $fil};
  open(REQ, "<$fil") or die "IRDA-00001: Cannot open request file:\n$!\n";
  while(<REQ>)
  { $tbl->{$1} = $2 if m/^(\w+)\s*=\s*"(.*)"/;
  }
  close(REQ);

  # Return the request parameter hash
  $tbl;
}

# Start the RDA agent
sub start_agent
{ my ($oid, $rpt, $fil, $flg) = @_;
  my ($agt, $cmd, $pth, $rdr, $top, $wrk);

  # Redirect standard output and error
  $wrk = File::Spec->catdir($rpt, 'work');
  if ($out)
  { open(IPS, '>&STDOUT');
    $cmd = (exists($ENV{'RDA_WARN'}) && $ENV{'RDA_WARN'}) ? '>&STDOUT' :
           $win                                           ? '>NUL' :
           $vms                                           ? '>nla0:' :
                                                            '>/dev/null';
    $pth = File::Spec->catfile($rpt, $fil);
    open(STDOUT, ">>$pth")
      or die "IRDA-00002: Cannot redirect STDOUT to $pth:\n$!\n";
    open(STDERR, $cmd)
       or die "IRDA-00003: Cannot redirect STDERR to $cmd:\n$!\n";
    $SIG{'__DIE__'}  = sub {open(STDERR, '>&STDOUT') unless $^S};
    $SIG{'__WARN__'} = sub {print @_ };
  }

  # Change to the RDA software configuration
  $top = load_rda($wrk);

  # Create RDA Agent
  print "\tCreating the RDA Agent\n" if $vrb;
  eval "require RDA::Agent";
  die "IRDA-00004: Cannot locate required RDA modules:\n$@" if $@;
  $agt = eval "RDA::Agent->new(\%tb_agt, oid => \$oid)";
  die "IRDA-00005: Cannot start the RDA Agent:\n$@" if $@;

  # Make temporary setup configuration
  $agt->set_setting('RDA_ARGC', (scalar @ARGV),   'N', 'Number of arguments');
  $agt->set_setting('RDA_ARGV', join('|', @ARGV), 'T', 'Argument list');
  if ($0 =~ m/\birda.pl$/ && $^X !~ m/\birda_\w+56$/)
  { $cmd = RDA::Object::Rda->quote($^X);
    $agt->set_setting('RDA_SELF', "$cmd irda.pl", 'T', 'Relaunch command');
    $agt->set_setting('RDA_PERL', $cmd,           'F', 'Perl executable');
    $agt->set_setting('LOCAL_RDA_COMMAND', "$cmd rda.pl",
      'T', 'Local relaunch command')
      unless $agt->get_setting('LOCAL_RDA_COMMAND');
  }
  else
  { $cmd = $^X;
    $cmd = File::Spec->catfile($top, basename($cmd))
      unless File::Spec->file_name_is_absolute($cmd);
    $agt->set_setting('RDA_SELF', RDA::Object::Rda->quote($cmd),
      'T', 'Relaunch command');
    unless ($agt->get_setting('LOCAL_RDA_COMMAND'))
    { $cmd = basename($^X);
      $cmd =~ s/irda/rda/i;
      $cmd = File::Spec->catfile($top,$cmd);
      $agt->set_setting('LOCAL_RDA_COMMAND', RDA::Object::Rda->quote($cmd),
        'T', 'Local relaunch command');
    }
  }
  $agt->set_temp_setting('RPT_DIRECTORY', $rpt);
  $agt->set_temp_setting('RPT_GROUP',     'DFW');
  $agt->set_temp_setting('SQL_LOGIN',     '/');
  $agt->set_temp_setting('SQL_SYSDBA',    '1');

  # Specify the output directory for sub processes
  $ENV{'RDA_OUTPUT'} = File::Spec->file_name_is_absolute($rpt)
    ? $rpt
    : File::Spec->catfile($top, $rpt)
    if $flg;

  # Return the agent reference
  $agt;
}

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
