# Sqlplus.pm: Class Used for Database Requests Using SQL*Plus

package RDA::Driver::Sqlplus;

# $Id: Sqlplus.pm,v 2.17 2012/08/28 18:49:34 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/Sqlplus.pm,v 2.17 2012/08/28 18:49:34 mschenke Exp $
#
# Change History
# 20120528  MSC  Fix the SET directive.

=head1 NAME

RDA::Driver::Sqlplus - Class Used for Database Requests Using SQL*Plus

=head1 SYNOPSIS

require RDA::Driver::Sqlplus;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::Sqlplus> class are used to interface a
database using SQL*Plus.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object::Access qw(check_sid);
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.17 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $ALR = "___Alarm___";
my $BUF = qr/^#\s*CAPTURE(\s+ONLY)?\s+(\w+)\s*$/;
my $CLL = qr/^#\s*CALL\s+(\w+)\((\d+)\)\s*$/;
my $CLS = qr/^#\s*(EXIT|QUIT)\s*$/;
my $CUT = "___Cut___";
my $DSC = qr/^#\s*(DESC\s+(.*))$/;
my $ECH = qr/^#\s*ECHO(.*)$/;
my $EOC = qr/^#\s*END\s*$/;
my $ERR = qr/^ERROR at line \d+:$/i;
my $EXT = qr/^[^:]+:\d+:{1,2}[^:]+$/;
my $LNG = qr/^#\s*LONG\((\d+)\)\s*$/;
my $LOG = qr/^((ORA|SP2)-\d{4,}):\s*(.*)/;
my $MAC = qr/^#\s*MACRO\s+(\w+)\((\d+)\)\s*$/;
my $NET1 = '@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SID = %s)))%s';
my $NET2 = '@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SERVICE_NAME = %s)))%s';
my $NET3 = '@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SERVICE_NAME = %s)'
  .'(INSTANCE_ROLE = ANY)(INSTANCE_NAME = %s)(SERVER = DEDICATED)))%s';
my $SET = qr/^#\s*SET\s+(\w+)\s*$/;
my $SID = qr/^([^:]+):(\d+):([^:]+)$/;
my $SLP = qr/^#\s*SLEEP\((\d+)\)\s*$/;
my $STM = qr/^#\s*((PL)?SQL(:\w+|\d*))\s*$/;
my $SVC = qr/^([^:]+):(\d+):([^:]*):([^:]+)$/;
my $SWT = qr/^#\s*CUT\s*$/;
my $TAG = qr/___Tag_(.+)___$/;
my $VER = q{SELECT version
 FROM product_component_version
 WHERE product LIKE 'Oracle%' OR product LIKE 'Personal Oracle%'};
my $VMS = qr/^___Set_VMS___$/;
my $WRK = 'dbi.txt';
my $WRN = qr/^ORA-280(02|11):/;

# Define the Sql*Plus interface
my $BEG = "

set arraysize 4
set define off
set echo off
set feedback off
set heading off
set linesize 1024
set long 1024
set newpage none
set pagesize 20000
set pause off
set sqlprompt RDA>
set tab off
set timing off
set verify off
set serveroutput on size 1000000
prompt $CUT
";
my $END = "prompt $CUT
exit
";

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Driver::Sqlplus-E<gt>new($agt[,$usr,$pwd,$sid,$dba])>

The object constructor. It takes the agent object reference and the login
information as arguments.

C<RDA::Driver::Sqlplus> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'acc' > > DB access error flag (error outside result section)

=item S<    B<'dur' > > Remaining alarm duration

=item S<    B<'err' > > SQL error flag (error in result section)

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'max' > > Maximum number of SQL script failures

=item S<    B<'try' > > Number of SQL script failures

=item S<    B<'-agt'> > Reference to the agent object

=item S<    B<'-dba'> > Indicates if the login should be treated as sysdba

=item S<    B<'-dft'> > Default password

=item S<    B<'-err'> > Number of SQL request errors

=item S<    B<'-fct'> > Function to execute a SQL request

=item S<    B<'-frk'> > Fork indicator

=item S<    B<'-log'> > User name and password to connect

=item S<    B<'-msg'> > Last error message

=item S<    B<'-not'> > Statistics note

=item S<    B<'-out'> > Number of SQL requests timed out

=item S<    B<'-pre'> > Prelim connection option

=item S<    B<'-pwd'> > User password

=item S<    B<'-req'> > Number of SQL requests

=item S<    B<'-sid'> > Database system identifier

=item S<    B<'-skp'> > Number of SQL requests skipped

=item S<    B<'-tgt'> > Reference to the target control object

=item S<    B<'-trc'> > SQL output trace flag

=item S<    B<'-usr'> > User name

=item S<    B<'-ver'> > Database version

=item S<    B<'-vms'> > VMS indicator

=item S<    B<'-wrk'> > Reference to the work file manager

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $agt, $usr, $pwd, $sid, $dba) = @_;
  my ($slf);

  # Create the object
  $slf = bless {
    acc  => $agt->get_setting('SQL_ACCESS', 0),
    dur  => 0,
    err  => $agt->get_setting('SQL_ERROR', 0),
    lim  => _chk_alarm($agt->get_setting('SQL_TIMEOUT', 30)),
    max  => $agt->get_setting('SQL_ATTEMPTS', 3),
    try  => 0,
    -agt => $agt,
    -err => 0,
    -dft => $agt->get_info('yes') ? '?' : undef,
    -frk => $agt->can_fork > 0,
    -out => 0,
    -pre => $agt->get_setting('SQL_PRELIM') ? '-prelim' : '',
    -req => 0,
    -skp => 0,
    -tgt => $agt->get_target,
    -trc => $agt->get_setting('SQL_TRACE', 0),
    -vms => RDA::Object::Rda->is_vms,
    -wrk => $agt->get_output,
    }, ref($cls) || $cls;

  # Setup some parameters by default
  if (defined($usr))
  { $slf->{'-dba'} = $dba;
    $slf->{'-pwd'} = $pwd;
    $slf->{'-sid'} = $sid;
    $slf->{'-usr'} = $usr;
  }

  # Determine the request method
  if ($slf->{'-frk'})
  { $slf->{'-fct'} = \&_run_sql_fork;
  }
  else
  { $slf->{'-fct'} = \&_run_sql_tmp;
    $slf->{'-wrk'} = $agt->get_output;
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method deletes the object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>reset>

This method resets the object for its new environment to allow a thread-save
execution.

=cut

sub reset
{
}

=head1 OBJECT METHODS

=head2 S<$h-E<gt>describe($ctx,$obj)>

This method returns a hash describing the specified object.

=cut

sub describe
{ my ($slf, $ctx, $obj) = @_;
  my ($dsc);

  $dsc = {row => [], typ => {}};
  &{$slf->{'-fct'}}($slf, $ctx, "#DESC $obj", 1, \&_describe, $dsc);
  $dsc;
}

sub _describe
{ my ($slf, $dsc, $lin) = @_;
  my ($col, $typ);

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL error\n" if $lin =~ $ERR && $slf->{'err'};

  # Store the lines
  if (exists($dsc->{'off'}) && $lin =~ m/\w/)
  { $col = lc(substr($lin, $dsc->{'off'}->[0], $dsc->{'off'}->[1]));
    $typ = substr($lin, $dsc->{'off'}->[2]);
    $col =~ s/\s+$//;
    $typ =~ s/(\(\d+\))?\s*$//;
    push(@{$dsc->{'row'}}, $col);
    $dsc->{'typ'}->{$col} = $typ;
  }
  elsif ($lin =~ m/^\s*Name\s+Null\?\s+Type\s*$/)
  { $col = index($lin,'Name');
    $dsc->{'off'} = [$col, index($lin,'Null?') - $col, index($lin,'Type')];
  }

  # Continue the search
  0;
}

=head2 S<$h-E<gt>execute($ctx,$job,$inc,$fct,$arg)>

This method executes a database job.

=cut

sub execute
{ my ($slf, $ctx, $job, $inc, $fct, $arg) = @_;

  &{$slf->{'-fct'}}($slf, $ctx, $job, $inc, $fct, $arg);
}

=head2 S<$h-E<gt>get_alarm($val)>

This method returns the alarm duration.

=cut

sub get_alarm
{ my ($slf, $val) = @_;

  return $slf->{'lim'} unless defined($val);
  return 0 unless $slf->{'lim'} > 0 && $val > 0;
  $val *= $slf->{'lim'};
  ($val > 1) ? int($val) : 1;
}

=head2 S<$h-E<gt>get_dialects>

This method returns the list of the dialects that this interface understands.

=cut

sub get_dialects
{ ('oracle');
}

=head2 S<$h-E<gt>get_message>

This method returns the error message of the last SQL execution. If no error is
detected, it returns C<undef>.

=cut

sub get_message
{ my ($slf) = @_;

  exists($slf->{'-msg'}) ? $slf->{'-msg'} : undef;
}

=head2 S<$h-E<gt>get_prelim>

This method indicates whether the C<prelim> option is set.

=cut

sub get_prelim
{ shift->{'-pre'} ? 1 : 0;
}

=head2 S<$h-E<gt>get_provider>

This method returns the name of the database provider.

=cut

sub get_provider
{ 'Oracle';
}

=head2 S<$h-E<gt>get_timeout>

This method returns the current duration of the SQL timeout. If this mechanism
is disabled, it returns 0.

=cut

sub get_timeout
{ shift->{'lim'};
}

=head2 S<$h-E<gt>get_usage>

This method returns the current usage and resets the counters.

=cut

sub get_usage
{ my ($slf) = @_;
  my ($rec, $str);

  # Consolidate the usage
  $rec = {};
  $rec->{'req'} += $slf->{'-req'};
  $rec->{'err'} += $slf->{'-err'};
  $rec->{'out'} += $slf->{'-out'};
  $rec->{'skp'} += $slf->{'-skp'};
  $rec->{'lim'} = $slf->{'lim'};
  $rec->{'not'} = $str if defined($str = delete($slf->{'-not'}));

  # Reset the usage
  $slf->{'-req'} = $slf->{'-err'} = $slf->{'-out'} = $slf->{'-skp'} = 0;

  # Return the usage
  $rec;
}

=head2 S<$h-E<gt>get_version($ctx)>

This method returns the database version. It returns an undefined value in case
of connection problems.

=cut

sub get_version
{ my ($slf, $ctx) = @_;

  &{$slf->{'-fct'}}($slf, $ctx, "#SQL\n$VER\n/", 1, \&_version, $slf)
    unless exists($slf->{'-ver'});
  $slf->{'-ver'};
}

sub _version
{ my ($ctx, $slf, $lin) = @_;

  $slf->{'-ver'} = $lin;
}

=head2 S<$h-E<gt>is_enabled>

This method indicates whether a SQL statement will be executed.

=cut

sub is_enabled
{ my ($slf) = @_;

  $slf->{'try'} < $slf->{'max'};
}

=head2 S<reset_timeout([$inc])>

This method resets the remaining alarm time to the SQL timeout value. To allow
more time for executing statements, you can specify a factor as an argument. 1
is the default. For a positive value, the maximum execution time is obtained by
multiplying the SQL timeout value by this factor. Otherwise, it disables the
alarm mechanism.

The effective value is returned.

=cut

sub reset_timeout
{ my ($slf, $inc) = @_;

  $slf->{'dur'} = $slf->get_alarm($inc);
}

=head2 S<$h-E<gt>set_access($flag)>

This method manages the access/connect error flag. When the flag is set, it
generates an error when an access/connect error is detected.

It returns the previous value of the flag.

=cut

sub set_access
{ my ($slf, $flg) = @_;

  ($slf->{'acc'}, $flg) = ($flg, $slf->{'acc'});
  $flg;
}

=head2 S<$h-E<gt>set_error($flag)>

This method manages the SQL error flag. When the flag is set, it generates an
error when a SQL error is detected.

It returns the previous value of the flag.

=cut

sub set_error
{ my ($slf, $flg) = @_;

  ($slf->{'err'}, $flg) = ($flg, $slf->{'err'});
  $flg;
}

=head2 S<$h-E<gt>set_failure($cnt)>

This method manages the number of SQL script failures. A negative value disables
any further database connection.

It returns the previous value of the counter.

=cut

sub set_failure
{ my ($slf, $cnt) = @_;

  $cnt = 0 unless defined($cnt);
  $cnt = $slf->{'max'} if $cnt < 0;

  ($slf->{'try'}, $cnt) = ($cnt, $slf->{'try'});
  $cnt;
}

=head2 S<$h-E<gt>set_prelim($flag)>

This method controls the C<prelim> option. When the flag is set, it activates
the option. Otherwise, it removes the option.

It returns the previous status.

=cut

sub set_prelim
{ my ($slf, $flg) = @_;

  $flg = $flg ? '-prelim' : '';
  ($slf->{'-pre'}, $flg) = ($flg, $slf->{'-pre'});
  $flg ? 1 : 0;
}

=head2 S<$h-E<gt>set_timeout($sec)>

This method sets the SQL timeout, specified in seconds, only if the value is
greater than zero. Otherwise, the timeout mechanism is disabled. It is disabled
also if the alarm function is not implemented.

It returns the effective value.

=cut

sub set_timeout
{ my ($slf, $val) = @_;

  $slf->{'lim'} = _chk_alarm($val);
}

=head2 S<$h-E<gt>set_trace([$flag])>

This method manages the SQL trace flag. When the flag is set, it prints all SQL
lines to the screen. It remains unchanged if the flag value is undefined.

It returns the previous value of the flag.

=cut

sub set_trace
{ my ($slf, $flg) = @_;

  ($slf->{'-trc'}, $flg) = ($flg, $slf->{'-trc'});
  $flg;
}

=head2 S<$h-E<gt>test($ctx)>

This method tests the database connection. In case of problems, further access
is disabled.

=cut

sub test
{ my ($slf, $ctx) = @_;
  my ($sql, @buf);

  # Test the database connection
  $slf->{'try'} = 0;
  delete($slf->{'-not'});
  $sql = "# SQL\nSELECT 'X' FROM sys.dual\n/";
  return ''
    if &{$slf->{'-fct'}}($slf, $ctx, $sql, 1, \&_test_sql, [$ctx, \@buf])
    && (scalar @buf) && $buf[0] eq 'X';
  ++$slf->{'-err'};
  $slf->{'-not'} = 'No database access in the last run';

  # Disable further access to the database
  $slf->{'try'} = $slf->{'max'};
  return 'RDA-00501: Database access disabled due to a connection problem';
}

sub _test_sql
{ my ($slf, $rec, $lin) = @_;

  # Interrupt when a SQL error is encountered
  if ($lin =~ $LOG)
  { $slf->{'-msg'} = $lin;
    return 1;
  }

  # Save the line in the last SQL result
  push(@{$rec->[1]}, $lin);

  # Continue the result processing
  0;
}

# --- Methods required for RDA::Object::Dbd compatibility ---------------------

sub connect
{ undef;
}

sub disconnect
{ undef;
}

sub get_date_fmt
{ undef;
}

sub get_sources
{ ();
}

# --- Internal routines -------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0)};
  $@ ? 0 : $lim;
}

# Get the login information
sub _get_login
{ my ($slf, $ctx) = @_;
  my ($acc, $agt, $grp, $loc, $pwd, $sid, $str, $suf, $typ, $usr);

  # Determine the user
  $acc = $ctx->get_access;
  $agt = $slf->{'-agt'};
  $str = $suf = '';
  if (exists($slf->{'-usr'}))
  { $usr = $slf->{'-usr'};
    $pwd = $slf->{'-pwd'};
    $sid = check_sid($slf->{'-sid'}, '');
    $loc = check_sid($agt->get_setting('ORACLE_SID'), '');
    $suf = ' as SYSDBA' if $slf->{'-dba'};
    if ($usr =~ m/^(.*)\@(\S+)(.*)$/)
    { ($usr, $sid, $suf) = ($1, check_sid($2), $3);
    }
    elsif ($usr =~ m/^(.*)\@(.*)$/)
    { ($usr, $suf) = ($1, $2);
    }
  }
  else
  { $usr = $agt->get_setting('SQL_LOGIN', 'SYSTEM');
    $loc = check_sid($agt->get_setting('ORACLE_SID'), '');
    $sid = ($agt->get_setting('DATABASE_LOCAL',1) && $loc !~ $EXT) ? '' : $loc;
    $suf = ' as SYSDBA' if $agt->get_setting('SQL_SYSDBA');

    $sid = check_sid($1) if $usr =~ s/\@(\S+)?.*$// && $1;
  }
  if ($usr =~ m/^(.*?)\/(.*)$/)
  { ($usr, $pwd) = (uc($1), $2);
  }
  else
  { $usr = uc($usr);
  }
  $str = (defined($sid) && length($sid)) ? "\@$sid$suf" : $suf;
  $suf = ($sid =~ $SID) ? sprintf($NET1, $1, $2, $3, $suf) :
         ($sid !~ $SVC) ? $str :
         length($3)     ? sprintf($NET3, $1, $2, $4, $3, $suf) :
                          sprintf($NET2, $1, $2, $4, $suf);

  # Get the password
  unless (defined($pwd))
  { $sid = $loc if $sid eq '';
    $pwd = $acc->get_password('oracle', $sid, $usr,
      "Enter the password for '$usr$str': ", $slf->{'-dft'});
    die "RDA-00508: Null password given; logon denied\n"
      unless defined($pwd);
  }

  # Create the login string
  $slf->{'-log'} = "$usr/$pwd$suf";
}

# Log a timeout event
sub _log_timeout
{ my $slf = shift;
  my $ctx = shift;

  ++$slf->{'try'};
  $slf->{'-agt'}->log_timeout($ctx, 'SQL', @_);
  $slf->{'-msg'} = 'RDA-00502: Database connection timeout';
  ++$slf->{'-out'};
}

# Execute SQL code (fork method)
sub _run_sql_fork
{ my ($slf, $ctx, $sql, $inc, $fct, $rec) = @_;
  my ($buf, $blk, $end, $err, $lim, $lin, $pid1, $pid2, $tag, $trc, $vms);

  # Abort when SQL is missing or when the number of tries have been reached
  ++$slf->{'-req'};
  unless ($sql)
  { $slf->{'-msg'} = 'RDA-00509: Missing SQL code';
    ++$slf->{'-err'};
    return 0;
  }
  unless ($slf->{'try'} < $slf->{'max'})
  { $slf->{'-msg'} = 'RDA-00510: SQL execution disabled';
    ++$slf->{'-skp'};
    return 0;
  }

  # Delete the previous error message
  delete($slf->{'-msg'});

  # Get the login information
  $slf->_get_login($ctx) unless exists($slf->{'-log'});

  # Run the SQL code in a limited execution time
  $lim = $slf->get_alarm($inc);
  if ($trc = $slf->{'-trc'})
  { for (split(/\n/, $sql))
    { print "SQL: $_\n";
    }
  }
  eval {
    local $SIG{'__WARN__'} = sub {};
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;
    local $SIG{'PIPE'}     = sub { exit(0); };

    # Prepare the requester pipe
    pipe(IN1, OUT1) or die "RDA-00503: Cannot create the pipe $!\n";

    # Launch the requester process
    die "RDA-00504: Cannot fork $!" unless defined($pid1 = fork());
    unless ($pid1)
    { my ($flg);

      close(IN1);
      $lin = $slf->{'-log'}.$BEG;
      syswrite(OUT1, $lin, length($lin));
      foreach $lin (split(/\n/, $sql))
      { if ($flg)
        { $flg = 0 if $lin eq '/';
          $lin .= "\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $BUF)
        { $lin = $1
            ? "PROMPT ___Capture_Only_$2___\n"
            : "PROMPT ___Capture_$2___\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $CLL)
        { my $val;

          $val = RDA::Value::Scalar::new_number($2);
          $val = RDA::Value::List->new($val);
          $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
          $val->eval_value;
        }
        elsif ($lin =~ $CLS)
        { $lin = "$1\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $DSC)
        { $lin = "PROMPT ___Tag_DESC $2___\nDESC $2\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $ECH)
        { $lin = "PROMPT$1\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $EOC)
        { $lin = "PROMPT ___End_Capture___\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $LNG)
        { $lin = "SET long $1\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $MAC)
        { $lin = "PROMPT ___Macro_$1($2)___\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $SET)
        { $lin = "PROMPT ___Set_$1___\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $SLP)
        { sleep($1);
        }
        elsif ($lin =~ $STM)
        { $flg = 1;
          $lin = "PROMPT ___Tag_$1___\n";
          syswrite(OUT1, $lin, length($lin));
        }
        elsif ($lin =~ $SWT)
        { $lin = "PROMPT $CUT\n";
          syswrite(OUT1, $lin, length($lin));
        }
      }
      if ($flg)
      { $lin = "/\n";
        syswrite(OUT1, $lin, length($lin));
      }
      syswrite(OUT1, $END, length($END));
      exit(0);
    }
    close(OUT1);

    # Prepare the SQL*Plus pipe
    pipe(IN2, OUT2) or die "RDA-00503: Cannot create the pipe:\n $!\n";

    # Launch SQL*Plus
    die "RDA-00504: Cannot fork:\n $!" unless defined($pid2 = fork());
    unless ($pid2)
    { my ($cmd, $env, $val, @opt);

      ($cmd, $env) = $slf->{'-tgt'}->get_current->get_sqlplus;
      foreach my $key (keys(%$env))
      { if (defined($val = $env->{$key}))
        { $ENV{$key} = $val;
        }
        elsif (exists($ENV{$key}))
        { delete($ENV{$key});
        }
      }
      @opt = ('-s');
      push(@opt, $slf->{'-pre'}) if $slf->{'-pre'};
      close(IN2);
      open(STDIN,  "<&IN1") or die;
      open(STDOUT, ">&OUT2") or die;
      open(STDERR, ">&OUT2") or die;
      exec($cmd, @opt)
        or die "RDA-00505: Cannot launch SQL*Plus!:\n $!\n";
    }

    # Parent process that treats the SQL*Plus output
    close(IN1);
    close(OUT2);

    # Limit its execution to prevent RDA hangs
    alarm($lim) if $lim;

    # Treat the SQL*Plus output
    my ($cat, $flg, $lin, $skp);

    $skp = $cat = $end = $flg = $vms = 0;
    while (<IN2>)
    { s/[\s\r\n]+$//;
      print "SQL> $_\n" if $trc;
      if (m/^$CUT$/)
      { $flg = !$flg;
      }
      elsif (m/^$TAG$/)
      { $tag = $1;
      }
      elsif ($flg)
      { if ($cat)
        { if (m/^\]\]\]$/)
          { last if &$fct($slf, $rec, $lin);
            $cat = 0;
            $skp = 1;
          }
          else
          { $lin .= $_;
          }
        }
        elsif (m/^\[\[\[$/)
        { $lin = '';
          $cat = 1;
        }
        elsif ($skp && m/^$/)
        { $skp = $vms;
        }
        elsif ($_ =~ $VMS)
        { $skp = $vms = 1;
        }
        else
        { $skp = $vms;
          last if ($end = &$fct($slf, $rec, $_));
        }
      }
      elsif ($_ =~ $WRN)
      { next;
      }
      elsif ($_ =~ $LOG)
      { die "RDA-00507: SQL Error: $3 ($1)\n" if $slf->{'acc'};
        $slf->{'-msg'} = $_;
        $end = 1;
        last;
      }
    }

    # Disable alarms
    alarm(0) if $lim;
  };
  if (($err = $@) || $end)
  { RDA::Object::Rda->kill_child($pid2) if $pid2;
    RDA::Object::Rda->kill_child($pid1) if $pid1;
  }
  close(IN2);
  waitpid($pid1, 0) if $pid1;
  waitpid($pid2, 0) if $pid2;

  # Detect and treat interrupts
  if ($err)
  { unless ($err =~ m/^$ALR\n/)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->_log_timeout($ctx, $tag);
    return 0;
  }

  # Terminate the output treatment
  exists($slf->{'-msg'}) ? 0 : 1;
}

# Execute SQL code (using a temporary file)
sub _run_sql_tmp
{ my ($slf, $ctx, $sql, $inc, $fct, $rec) = @_;
  my ($cmd, $env, $err, $lim, $lin, $pid, $tag, $tmp, $trc, $val, $vms, %bkp);

  # Abort when SQL is missing or when the number of tries have been reached
  ++$slf->{'-req'};
  unless ($sql)
  { $slf->{'-msg'} = 'RDA-00509: Missing SQL code';
    ++$slf->{'-err'};
    return 0;
  }
  unless ($slf->{'try'} < $slf->{'max'})
  { $slf->{'-msg'} = 'RDA-00510: SQL execution disabled';
    ++$slf->{'-skp'};
    return 0;
  }

  # Delete the previous error message
  delete($slf->{'-msg'});

  # Get the login information
  $slf->_get_login($ctx) unless exists($slf->{'-log'});

  # Run the SQL code in a limited execution time
  $lim = $slf->get_alarm($inc);
  $tmp = $slf->{'-wrk'}->get_work($WRK, 1);
  $vms = $slf->{'-vms'};
  if ($trc = $slf->{'-trc'})
  { for (split(/\n/, $sql))
    { print "SQL: $_\n";
    }
  }
  eval {
    my ($flg);
    local $SIG{'__WARN__'} = sub {};
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;
    local $SIG{'PIPE'}     = sub { die "$ALR\n" } if $lim;

    # Limit its execution to prevent RDA hangs
    alarm($lim) if $lim;

    # Execute SQL*Plus
    ($cmd, $env) = $slf->{'-tgt'}->get_current->get_sqlplus;
    $cmd = RDA::Object::Rda->quote($cmd) unless $vms;
    foreach my $key (keys(%$env))
    { if (defined($val = $env->{$key}))
      { $bkp{$key} = $ENV{$key};
        $ENV{$key} = $val;
      }
      elsif (exists($ENV{$key}))
      { $bkp{$key} = delete($ENV{$key});
      }
    }
    ($pid = open(OUT, '| '.$cmd.' -s '.$slf->{'-pre'}
      .' >'.RDA::Object::Rda->quote($tmp)
      .' 2>&1')) or die "RDA-00505: Cannot launch SQL*Plus:\n $!\n";
    $lin = $slf->{'-log'}.$BEG;
    syswrite(OUT, $lin, length($lin));
    foreach $lin (split(/\n/, $sql))
    { if ($flg)
      { $flg = 0 if $lin eq '/';
        $lin .= "\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $BUF)
      { $lin = $1
          ? "PROMPT ___Capture_Only_$2___\n"
          : "PROMPT ___Capture_$2___\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $EOC)
      { $lin = "PROMPT ___End_Capture___\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $CLL)
      { my $val;

        $val = RDA::Value::Scalar::new_number($2);
        $val = RDA::Value::List->new($val);
        $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
        $val->eval_value;
      }
      elsif ($lin =~ $CLS)
      { $lin = "$1\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $DSC)
      { $lin = "PROMPT ___Tag_DESC $2___\nDESC $2\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $ECH)
      { $lin = "PROMPT$1\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $LNG)
      { $lin = "SET long $1\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $MAC)
      { $lin = "PROMPT ___Macro_$1($2)___\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $SET)
      { $lin = "PROMPT ___Set_$1___\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $SLP)
      { sleep($1);
      }
      elsif ($lin =~ $STM)
      { $flg = 1;
        $lin = "PROMPT ___Tag_$1___\n";
        syswrite(OUT, $lin, length($lin));
      }
      elsif ($lin =~ $SWT)
      { $lin = "PROMPT $CUT\n";
        syswrite(OUT, $lin, length($lin));
      }
    }
    if ($flg)
    { $lin = "/\n";
      syswrite(OUT, $lin, length($lin));
    }
    syswrite(OUT, $END, length($END));
    waitpid($pid, 0);

    # Disable alarms
    alarm(0) if $lim;
  };
  RDA::Object::Rda->kill_child($pid) if ($err = $@) && $pid;
  close(OUT);

  # Restore the environment
  foreach my $key (keys(%bkp))
  { if (defined($val = $bkp{$key}))
    { $ENV{$key} = $val;
    }
    else
    { delete($ENV{$key});
    }
  }

  # Treat the SQL*Plus output
  if (open(IN, "<$tmp"))
  { eval {
      my ($cat, $flg, $lin, $skp);
      $cat = $flg = 0;
      $skp = $vms;
      while (<IN>)
      { s/[\s\r\n]+$//;
        print "SQL> $_\n" if $trc;
        if (m/^$CUT$/)
        { $flg = !$flg;
        }
        elsif (m/^$TAG$/)
        { $tag = $1;
        }
        elsif ($flg)
        { if ($cat)
          { if (m/^\]\]\]$/)
            { last if &$fct($slf, $rec, $lin);
              $cat = 0;
              $skp = 1;
            }
            else
            { $lin .= $_;
            }
          }
          elsif (m/^\[\[\[$/)
          { $lin = '';
            $cat = 1;
          }
          elsif ($skp && m/^$/)
          { $skp = $vms;
          }
          elsif ($_ =~ $VMS)
          { $skp = $vms = 1;
          }
          elsif (! m/^RDA\>$/)
          { $skp = $vms;
            last if &$fct($slf, $rec, $_);
          }
        }
        elsif ($_ =~ $WRN)
        { next;
        }
        elsif ($_ =~ $LOG)
        { die "RDA-00507: SQL Error: $3 ($1)\n" if $slf->{'acc'};
          $slf->{'-msg'} = $_;
          last;
        }
      }
    };
    $err = $@ if $@;
    close(IN);
    1 while unlink($tmp);
    $slf->{'-wrk'}->clean_work($WRK, 1) if -e $tmp;
  }

  # Detect and treat interrupts
  if ($err)
  { unless ($err =~ m/^$ALR\n/)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->_log_timeout($ctx, $tag);
    return 0;
  }

  # Terminate the output treatment
  exists($slf->{'-msg'}) ? 0 : 1;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Library::Dbi|RDA::Library::Dbi>,
L<RDA::Object::Access|RDA::Object::Access>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
