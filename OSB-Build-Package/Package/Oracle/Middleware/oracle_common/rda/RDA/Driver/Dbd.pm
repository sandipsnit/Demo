# Dbd.pm: Class Used for Database Requests Using DBD

package RDA::Driver::Dbd;

# $Id: Dbd.pm,v 2.21 2012/08/29 05:54:17 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/Dbd.pm,v 2.21 2012/08/29 05:54:17 mschenke Exp $
#
# Change History
# 20120828  MSC  Update type mapping.

=head1 NAME

RDA::Driver::Dbd - Class Used for Database Requests Using DBD

=head1 SYNOPSIS

require RDA::Driver::Dbd;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::Dbd> class are used to interface a database
using DBD.

The timeout mechanism is only effective for UNIX systems.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object::Access qw(check_dsn check_sid);
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.21 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $ALR = "___Alarm___";
my $CUT = "___Cut___";
my $DSN = qr/^-:(=)?(.*)$/;
my $EXT = qr/^[^:]+:\d+:{1,2}[^:]+$/;
my $SID = qr/^([^:]+):(\d+):([^:]+)$/;
my $SVC = qr/^([^:]+):(\d+):([^:]*):([^:]+)$/;
my $OUT = qr#(ORA-01013:|timeout)#i;

my $NET1 = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SID = %s)))%s';
my $NET2 = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SERVICE_NAME = %s)))%s';
my $NET3 = '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SERVICE_NAME = %s)'
  .'(INSTANCE_ROLE = ANY)(INSTANCE_NAME = %s)(SERVER = DEDICATED)))%s';

# Define the global private variables
my %tb_cap = (
  LEFT       => 0x00000004,
  RIGHT      => 0x00000200,
  DAYOFMONTH => 0x00000004,
  MONTH      => 0x00000020,
  MONTHNAME  => 0x00010000,
  YEAR       => 0x00000100,
  HOUR       => 0x00000400,
  MINUTE     => 0x00000800,
  SECOND     => 0x00001000,
  );
my %tb_typ = (
  ODBC   => {dsc => 'TYPE',
             log => \&odbc_login,
             msg => qr/^\[^\]]*]{3}.*$/,
             pls => 0,
             pwd => 0,
             typ =>{'-11' => 'NUMBER',   # SQL_GUID
                    '-10' => 'LONG',     # SQL_WLONGVARCHAR
                    '-9'  => 'VARCHAR2', # SQL_WVARCHAR
                    '-8'  => 'VARCHAR2', # SQL_WCHAR
                    '-7'  => 'VARCHAR2', # SQL_BIT
                    '-6'  => 'NUMBER',   # SQL_TINYINT
                    '-5'  => 'NUMBER',   # SQL_BIGINT
                    '-4'  => 'VARCHAR2', # SQL_LONGVARBINARY
                    '-3'  => 'RAW',      # SQL_VARBINARY
                    '-2'  => 'RAW',      # SQL_BINARY
                    '-1'  => 'LONG',     # SQL_LONGVARCHAR
                    '0'   => 'VARCHAR2', # SQL_UNKNOWN_TYPE, SQL_ALL_TYPES
                    '1'   => 'CHAR',     # SQL_CHAR
                    '2'   => 'NUMBER',   # SQL_NUMERIC
                    '3'   => 'NUMBER',   # SQL_DECIMAL
                    '4'   => 'NUMBER',   # SQL_INTEGER
                    '5'   => 'NUMBER',   # SQL_SMALLINT
                    '6'   => 'NUMBER',   # SQL_FLOAT
                    '7'   => 'NUMBER',   # SQL_REAL
                    '8'   => 'NUMBER',   # SQL_DOUBLE
                    '9'   => 'DATE',     # SQL_DATETIME,SQL_DATE
                    '10'  => 'DATE',     # SQL_INTERVAL, SQL_TIME
                    '11'  => 'DATE',     # SQL_TIMESTAMP
                    '12'  => 'VARCHAR2', # SQL_VARCHAR
                    '16'  => 'BOOLEAN',  # SQL_BOOLEAN
                    '17'  => 'VARCHAR2', # SQL_UDT
                    '18'  => 'VARCHAR2', # SQL_UDT_LOCATOR
                    '19'  => 'VARCHAR2', # SQL_ROW
                    '20'  => 'VARCHAR2', # SQL_REF
                    '30'  => 'BLOB',     # SQL_BLOB
                    '31'  => 'VARCHAR2', # SQL_BLOB_LOCATOR
                    '40'  => 'CLOB',     # SQL_CLOB
                    '41'  => 'VARCHAR2', # SQL_CLOB_LOCATOR
                    '50'  => 'VARCHAR2', # SQL_ARRAY
                    '51'  => 'VARCHAR2', # SQL_ARRAY_LOCATOR
                    '55'  => 'VARCHAR2', # SQL_MULTISET
                    '56'  => 'VARCHAR2', # SQL_MULTISET_LOCATOR
                    '91'  => 'DATE',     # SQL_TYPE_DATE
                    '92'  => 'DATE',     # SQL_TYPE_TIME
                    '93'  => 'DATE',     # SQL_TYPE_TIMESTAMP
                    '94'  => 'DATE',     # SQL_TYPE_TIME_WITH_TIMEZONE
                    '95'  => 'DATE',     # SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
                    '101' => 'VARCHAR2', # SQL_INTERVAL_YEAR
                    '102' => 'VARCHAR2', # SQL_INTERVAL_MONTH
                    '103' => 'VARCHAR2', # SQL_INTERVAL_DAY
                    '104' => 'VARCHAR2', # SQL_INTERVAL_HOUR
                    '105' => 'VARCHAR2', # SQL_INTERVAL_MINUTE
                    '106' => 'VARCHAR2', # SQL_INTERVAL_SECOND
                    '107' => 'VARCHAR2', # SQL_INTERVAL_YEAR_TO_MONTH
                    '108' => 'VARCHAR2', # SQL_INTERVAL_DAY_TO_HOUR
                    '109' => 'VARCHAR2', # SQL_INTERVAL_DAY_TO_MINUTE
                    '110' => 'VARCHAR2', # SQL_INTERVAL_DAY_TO_SECOND
                    '111' => 'VARCHAR2', # SQL_INTERVAL_HOUR_TO_MINUTE
                    '112' => 'VARCHAR2', # SQL_INTERVAL_HOUR_TO_SECOND
                    '113' => 'VARCHAR2', # SQL_INTERVAL_MINUTE_TO_SECOND
                    },
            },
  Oracle => {dsc => 'ora_types',
             log => \&ora_login,
             msg => qr/^((ORA|SP2)-\d{4,}):\s*(.*)/,
             pls => 1,
             pwd => 0,
             typ => {1   => 'VARCHAR2',
                     2   => 'NUMBER',
                     8   => 'LONG',
                     12  => 'DATE',
                     23  => 'RAW',
                     24  => 'LONG RAW',
                     69  => 'ROWID',
                     96  => 'CHAR',
                     100 => 'BINARY_FLOAT',
                     101 => 'BINARY_DOUBLE',
                     108 => 'User-defined',
                     111 => 'REF',
                     112 => 'CLOB',
                     113 => 'BLOB',
                     114 => 'BFILE',
                     180 => 'TIMESTAMP',
                     181 => 'TIMESTAMP WITH TIME ZONE',
                     182 => 'INTERVAL YEAR TO MONTH',
                     183 => 'INTERVAL DAY TO SECOND',
                     208 => 'UROWID',
                     231 => 'TIMESTAMP WITH LOCAL TIME ZONE',
                    },
            },
  '?'    => {dsc => 'TYPES',
             log => \&dft_login,
             msg => qr/^\[^\]]*]{3}.*$/,
             pls => 0,
             pwd => 1,
             typ => {},
            },
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Driver::Dbd-E<gt>new($typ,$agt[,$usr,$pwd,$sid,$dba])>

The object constructor. It takes the driver type, the agent object reference,
and the login information as arguments.

C<RDA::Driver::Dbd> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'acc' > > DB access error flag (error outside result section)

=item S<    B<'dur' > > Remaining alarm duration

=item S<    B<'err' > > SQL error flag (error in result section)

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'max' > > Maximum number of SQL script failures

=item S<    B<'try' > > Number of SQL script failures

=item S<    B<'-agt'> > Reference to the agent object

=item S<    B<'-con'> > Connection attributes

=item S<    B<'-dbh'> > Database handle

=item S<    B<'-def'> > Driver characteristic definition

=item S<    B<'-dft'> > Default password

=item S<    B<'-err'> > Number of SQL request errors

=item S<    B<'-grp'> > Password group

=item S<    B<'-msg'> > Last error message

=item S<    B<'-nam'> > Name of the database provider

=item S<    B<'-not'> > Statistics note

=item S<    B<'-out'> > Number of SQL requests timed out

=item S<    B<'-pwd'> > User password

=item S<    B<'-req'> > Number of SQL requests

=item S<    B<'-sid'> > Database system identifier

=item S<    B<'-skp'> > Number of SQL requests skipped

=item S<    B<'-trc'> > SQL output trace level

=item S<    B<'-txt'> > Password request test

=item S<    B<'-typ'> > Driver type

=item S<    B<'-usr'> > User name

=item S<    B<'-ver'> > Database version

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $typ, $agt, $usr, $pwd, $sid, $dba) = @_;
  my ($slf);

  # Create the object
  $slf = bless {}, ref($cls) || $cls;

  # Setup some parameters by default
  $slf->{'-agt'} = $agt;
  $slf->{'-def'} = $tb_typ{exists($tb_typ{$typ}) ? $typ : '?'};
  $slf->{'-dft'} = $agt->get_info('yes') ? '?' : undef;
  $slf->{'-req'} = $slf->{'-err'} = $slf->{'-out'} = $slf->{'-skp'} = 0;
  $slf->{'-trc'} = $agt->get_setting('SQL_TRACE', 0);
  $slf->{'-typ'} = $typ;

  $slf->{'acc'} = $agt->get_setting('SQL_ACCESS', 0);
  $slf->{'dur'} = 0;
  $slf->{'err'} = $agt->get_setting('SQL_ERROR', 0);
  $slf->{'lim'} = _chk_alarm($agt->get_setting('DBI_TIMEOUT', 30));
  $slf->{'max'} = $agt->get_setting('SQL_ATTEMPTS', 3);
  $slf->{'try'} = 0;

  # Set the common attributes
  $slf->{'-con'} = {
    LongReadLen => 1024,
    LongTruncOk => 1,
    RaiseError  => 0,
    };
  $slf->{'-con'}->{'ReadOnly'} = 1                unless $DBI::VERSION < 1.55;
  $slf->{'-con'}->{'TraceLevel'} = $slf->{'-trc'} unless $DBI::VERSION < 1.21;

  # Determine the login information
  &{$slf->{'-def'}->{'log'}}($slf, $usr, $pwd, $sid, $dba);

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>delete>

This method deletes the object.

=cut

sub delete
{ disconnect($_[0]);
  undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>reset>

This method resets the object for its new environment to allow a thread-save
execution.

=cut

sub reset
{ my ($slf) = @_;

}

=head1 OBJECT METHODS

=head2 S<$h-E<gt>connect($ctx[,$inc])>

This method connects to the database.

=cut

sub connect
{ my ($slf, $ctx, $inc) = @_;

  # Abort when the number of tries have been reached
  ++$slf->{'-req'};
  unless ($slf->{'try'} < $slf->{'max'})
  { $slf->{'-msg'} = 'RDA-00510: SQL execution disabled';
    ++$slf->{'-skp'};
    return undef;
  }

  # Delete the previous message
  delete($slf->{'-msg'});

  # Connect on the first call
  unless (exists($slf->{'-dbh'}))
  { my ($acc, $err, $flg, $grp, $pwd, $typ, $usr);

    # Get the password
    $acc = $ctx->get_access;
    $flg = $slf->{'-def'}->{'pwd'};
    $usr = $slf->{'-usr'};
    unless (defined($pwd = $slf->{'-pwd'}) || $flg < 0)
    { $grp = $slf->{'-grp'};
      $typ = lc($slf->{'-typ'});
      $pwd = $acc->get_password($typ, $grp, $usr, $slf->{'-txt'},
        $slf->{'-dft'});
      die "RDA-00508: Null password given; logon denied\n"
        unless defined($pwd) || $flg;
    }

    # Connect to the database
    unless (defined($slf->{'-dbh'} =
      DBI->connect('dbi:'.$slf->{'-typ'}.':'.$slf->{'-sid'}, $usr, $pwd,
        $slf->{'-con'})))
    { $err = $DBI::errstr;
      $err =~ s/[\n\r\s]+$//;
      $slf->{'-msg'} = $err;
      ++$slf->{'-err'};
      $err =~ $tb_typ{$slf->{'-typ'}}->{'msg'};
      die "RDA-00507: SQL Error: $3 ($1)\n" if $slf->{'acc'};
      return undef;
    }
  }

  # Set timeout
  $slf->{'-dbh'}->{'odbc_query_timeout'} = $slf->get_alarm($inc)
    if $slf->{'-typ'} eq 'ODBC' && defined($slf->{'-dbh'});

  # Return the database handle
  $slf->{'-dbh'};
}

=head2 S<$h-E<gt>describe($ctx,$obj)>

This method returns a hash describing the specified table or view.

=cut

sub describe
{ my ($slf, $ctx, $obj) = @_;
  my ($cur, $dbh, $dsc, $err, $lim, $nam, $off, $sth, $tbl, $typ);

  $dsc = {row => [], typ => {}};
  $lim = ($slf->{'-typ'} eq 'ODBC') ? 0 : $slf->get_alarm;
  eval {
    local $SIG{'__WARN__'} = sub {};
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;

    alarm($lim) if $lim;
    eval {
      if (($dbh = $slf->connect($ctx))
        && ($sth = $dbh->prepare("SELECT * FROM $obj")))
      { $nam = $sth->{'NAME'};
        $typ = $sth->{$slf->{'-def'}->{'dsc'}};
        $tbl = $slf->{'-def'}->{'typ'};
        $off = $sth->{'NUM_OF_FIELDS'};
        while ($off > 0)
        { $cur = lc($nam->[--$off]);
          unshift(@{$dsc->{'row'}}, $cur);
          $dsc->{'typ'}->{$cur} = $tbl->{$typ->[$off]} || $typ->[$off];
        }
        $sth->finish;
      }
      };
    alarm(0) if $lim;
    die $@ if $@;
    };

  # Detect and treat interrupts
  if ($err = $@)
  { unless ($err =~ m/^$ALR\n/ || $err =~ $OUT)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->_log_timeout($ctx, "DESC $obj");
  }

  # Return the object description
  $dsc;
}

=head2 S<$h-E<gt>disconnect>

This method disconnects from the database.

=cut

sub disconnect
{ my ($dbh);

  $dbh->disconnect if ($dbh = delete(shift->{'-dbh'}));
}

=head2 S<$h-E<gt>execute($ctx,$job,$inc,$fct,$arg)>

This method executes a database job.

=cut

sub execute
{ my ($slf, $ctx, $job, $inc, $fct, $arg) = @_;
  my ($dbh, $err, $flg, $lim, $lin, $lng, $row, $sth, $tag, $trc, @job);

  # Abort when job is missing or when the number of tries have been reached
  unless ($job)
  { $slf->{'-msg'} = 'RDA-00509: Missing SQL code';
    ++$slf->{'-req'};
    ++$slf->{'-err'};
    return 0;
  }
  unless ($slf->{'try'} < $slf->{'max'})
  { $slf->{'-msg'} = 'RDA-00510: SQL execution disabled';
    ++$slf->{'-req'};
    ++$slf->{'-skp'};
    return 0;
  }

  # Execute the job
  if ($trc = $slf->{'-trc'})
  { for (split(/\n/, $job))
    { print "SQL: $_\n";
    }
  }
  $flg = 1;
  $lim = ($slf->{'-typ'} eq 'ODBC') ? 0 : $slf->get_alarm($inc);
  @job = split(/\n/, $job);
  eval {
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;
    local $SIG{'__WARN__'} = sub {};

    alarm($lim) if $lim;
    eval {
      if ($dbh = $slf->connect($ctx, $inc))
      { while (defined($lin = shift(@job)))
        { $tag = '';
          if ($lin =~ m/^#\s*(SQL\d*)\s*$/)
          { my (@row, @sql);

            $tag = $1;
            push(@sql, $lin) while defined($lin = shift(@job)) && $lin ne '/';
            next unless @sql;
            unless (($sth = $dbh->prepare(join("\n", @sql))) && $sth->execute)
            { $row = $DBI::errstr;
              $row =~ s/[\n\r\s]+$//;
              die "$ALR\n" if $row =~ $OUT;
              if ($flg)
              { last if &$fct($slf, $arg, 'ERROR in SQL request:');
                last if &$fct($slf, $arg, $row);
                next;
              }
              die "RDA-00507: SQL Error: $row\n" if $slf->{'acc'};
              $slf->{'-msg'} = $row;
              last;
            }
            while (@row = $sth->fetchrow_array)
            { $row = join('|', @row);
              print "SQL> $row\n" if $trc;
              if ($row =~ $CUT)
              { $flg = !$flg;
              }
              elsif ($flg)
              { if ($row =~ m/^\[\[\[\012(.*)\012\]\]\]$/s)
                { $row = $1;
                  $row =~ s/[\n\r]//gs;
                }
                last if &$fct($slf, $arg, $row);
              }
            }
            $sth->finish;
          }
          elsif ($lin =~ m/^#\s*(PLSQL\d*)\s*$/)
          { my ($buf, $cat, @sql);

            die "RDA-00520: PL/SQL not supported through ODBC\n"
              unless $tb_typ{$slf->{'-typ'}}->{'pls'};
            $tag = $1;
            push(@sql, $lin) while defined($lin = shift(@job)) && $lin ne '/';
            next unless @sql;
            $dbh->func(1000000, 'dbms_output_enable');
            unless (($sth = $dbh->prepare(join("\n", @sql))) && $sth->execute)
            { $row = $DBI::errstr;
              $row =~ s/[\n\r\s]+$//;
              if ($flg)
              { last if &$fct($slf, $arg, 'ERROR in PL/SQL request:');
                last if &$fct($slf, $arg, $row);
                next;
              }
              die "RDA-00507: SQL Error: $row\n" if $slf->{'acc'};
              $slf->{'-msg'} = $row;
              last;
            }
            $cat = 0;
            foreach $row ($dbh->func('dbms_output_get'))
            { print "SQL> $row\n" if $trc;
              if ($row =~ $CUT)
              { $flg = !$flg;
              }
              elsif ($flg)
              { if ($cat)
                { if ($row =~ m/^\]\]\]$/)
                  { last if &$fct($slf, $arg, $buf);
                    $cat = 0;
                  }
                  else
                  { $buf .= $row;
                  }
                }
                elsif ($row =~ m/^\[\[\[$/)
                { $buf = '';
                  $cat = 1;
                }
                elsif ($row =~ m/^\[\[\[\012(.*)\012\]\]\]$/s)
                { $buf = $1;
                  $buf =~ s/[\n\r]//gs;
                  last if &$fct($slf, $arg, $buf);
                }
                else
                { last if &$fct($slf, $arg, $row);
                }
              }
            }
            $sth->finish;
          }
          elsif ($lin =~ m/^#\s*MACRO\s+(\w+)\((\d+)\)\s*$/)
          { &$fct($slf, $arg, "___Macro_$1($2)___") if $flg;
          }
          elsif ($lin =~ m/^#\s*CUT\s*$/)
          { $flg = !$flg;
          }
          elsif ($lin =~ m/^#\s*CALL\s+(\w+)\((\d+)\)\s*$/)
          { my ($val);
  
            $val = RDA::Value::Scalar::new_number($2);
            $val = RDA::Value::List->new($val);
            $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
            $val->eval_value;
          }
          elsif ($lin =~ m/^#\s*CAPTURE\s+ONLY\s+(\w+)\s*$/)
          { &$fct($slf, $arg, "___Capture_Only_$1___") if $flg;
          }
          elsif ($lin =~ m/^#\s*CAPTURE\s+(\w+)\s*$/)
          { &$fct($slf, $arg, "___Capture_$1___") if $flg;
          }
          elsif ($lin =~ m/^#\s*ECHO(\s+(.*))?$/)
          { &$fct($slf, $arg, $2) if $flg && defined($1);
          }
          elsif ($lin =~ m/^#\s*END\s*$/)
          { &$fct($slf, $arg, "___End_Capture___") if $flg;
          }
          elsif ($lin =~ m/^#\s*(EXIT|QUIT)\s*$/)
          { $slf->disconnect;
            last;
          }
          elsif ($lin =~ m/^#\s*LONG\((\d+)\)\s*$/)
          { $dbh->{'LongReadLen'} = $1;
            $lng = 1;
          }
          elsif ($lin =~ m/^#\s*SLEEP\((\d+)\)\s*$/)
          { sleep($1);
          }
        }
      }
      else
      { $row = $DBI::errstr;
        $row =~ s/[\n\r\s]+$//;
        die "RDA-00507: SQL Error: $row\n" if $slf->{'acc'};
        $slf->{'-msg'} = $row;
      }
      };
    alarm(0) if $lim;
    die $@ if $@;
    };
  $dbh->{'LongReadLen'} = 1024 if $lng;

  # Detect and treat interrupts
  if ($err = $@)
  { unless ($err =~ m/^$ALR\n/)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->_log_timeout($ctx, $tag);
  }

  # Terminate the output treatment
  exists($slf->{'-msg'}) ? 0 : 1;
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

=head2 S<$h-E<gt>get_date_fmt($fct)>

This method returns the date format using the specified concatenation function.

=cut

sub get_date_fmt
{ my ($slf, $fct) = @_;
  my ($cap, $str);

  # Test the function availability
  return '%s' unless ($cap = $slf->{'-dbh'}->get_info(50))
    && ($cap & $tb_cap{'LEFT'})
    && ($cap & $tb_cap{'RIGHT'})
    && ($cap = $slf->{'-dbh'}->get_info(52))
    && ($cap & $tb_cap{'DAYOFMONTH'})
    && ($cap & $tb_cap{'MONTH'})
    && ($cap & $tb_cap{'YEAR'})
    && ($cap & $tb_cap{'HOUR'})
    && ($cap & $tb_cap{'MINUTE'})
    && ($cap & $tb_cap{'SECOND'});

  # Return the date format
  $str = ($cap & $tb_cap{'MONTHNAME'})
    ? '{fn LEFT({fn MONTHNAME(%s)},3)}'
    : '{fn RIGHT('.&$fct('\'0\'', '{fn MONTH(%s)}').',2)}';
  &$fct('{fn RIGHT('.&$fct('\'0\'', '{fn DAYOFMONTH(%s)}').',2)}', '\'-\'',
    $str, '\'-\'',
    '{fn RIGHT('.&$fct('\'000\'', '{fn YEAR(%s)}').',4)}', '\' \'',
    '{fn RIGHT('.&$fct('\'0\'', '{fn HOUR(%s)}').',2)}', '\':\'',
    '{fn RIGHT('.&$fct('\'0\'', '{fn MINUTE(%s)}').',2)}', '\':\'',
    '{fn RIGHT('.&$fct('\'0\'', '{fn SECOND(%s)}').',2)}');
}

=head2 S<$h-E<gt>get_dialects($ctx)>

This method returns the list of the dialects that this interface understands.

=cut

sub get_dialects
{ my ($slf, $ctx) = @_;
  my (@tbl);

  push(@tbl, lc($slf->{'-nam'})) if $slf->get_provider($ctx);
  push(@tbl, 'odbc')             if $slf->{'-typ'} eq 'ODBC';
  (@tbl, '?');
}

=head2 S<$h-E<gt>get_message>

This method returns the error message of the last SQL execution. If no error is
detected, it returns C<undef>.

=cut

sub get_message
{ my ($slf) = @_;

  exists($slf->{'-msg'}) ? $slf->{'-msg'} : undef;
}

=head2 S<$h-E<gt>get_provider($ctx)>

This method returns the name of the database provider. It returns an undefined
value in case of problems.

=cut

sub get_provider
{ my ($slf, $ctx) = @_;

  unless (exists($slf->{'-nam'}))
  { my ($dbh, $err, $lim);

    # Execute the request
    $lim = ($slf->{'-typ'} eq 'ODBC') ? 0 : $slf->get_alarm;
    eval {
      local $SIG{'__WARN__'} = sub {};
      local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;

      alarm($lim) if $lim;
      eval {
        $slf->{'-nam'} = $dbh->get_info(17) if ($dbh = $slf->connect($ctx));
        };
      alarm(0) if $lim;
      die $@ if $@;
      };

    # Detect and treat interrupts
    if ($err = $@)
    { unless ($err =~ m/^$ALR\n/ || $err =~ $OUT)
      { ++$slf->{'-err'};
        die $err;
      }
      $slf->_log_timeout($ctx, 'DBprovider');
      return undef;
    }
  }
  $slf->{'-nam'};
}

=head2 S<$h-E<gt>get_sources>

This method returns the list of the available data sources.

=cut

sub get_sources
{ my ($slf) = @_;
  my ($nam, %tbl);

  eval {
    foreach my $src (DBI->data_sources($slf->{'-typ'}))
    { (undef, undef, $nam) = split(/:/, $src, 3);
      $tbl{$nam} = 1;
    }
    };
  sort keys(%tbl);
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
of problems.

=cut

sub get_version
{ my ($slf, $ctx) = @_;

  unless (exists($slf->{'-ver'}))
  { my ($dbh, $err, $lim);

    # Execute the request
    $lim = ($slf->{'-typ'} eq 'ODBC') ? 0 : $slf->get_alarm;
    eval {
      local $SIG{'__WARN__'} = sub {};
      local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;

      alarm($lim) if $lim;
      eval {
        $slf->{'-ver'} = $dbh->get_info(18) if ($dbh = $slf->connect($ctx));
        };
      alarm(0) if $lim;
      die $@ if $@;
      };

    # Detect and treat interrupts
    if ($err = $@)
    { unless ($err =~ m/^$ALR\n/ || $err =~ $OUT)
      { ++$slf->{'-err'};
        die $err;
      }
      $slf->_log_timeout($ctx, 'DBversion');
      return undef;
    }
  }
  $slf->{'-ver'};
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
  my ($lim);

  $lim = $slf->get_alarm($inc);
  $slf->{'-dbh'}->{'odbc_query_timeout'} = $slf->{'lim'}
    if defined($inc) && $slf->{'-typ'} eq 'ODBC'
    && exists($slf->{'-dbh'}) && defined($slf->{'-dbh'});
  $slf->{'_dur'} = $lim;
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

=head2 S<$h-E<gt>set_timeout($sec)>

This method sets the SQL timeout, specified in seconds, only if the value is
greater than zero. Otherwise, the timeout mechanism is disabled. It is disabled
also if the alarm function is not implemented.

It returns the effective value.

=cut

sub set_timeout
{ my ($slf, $val) = @_;
  my ($lim);

  $lim = _chk_alarm($val);
  $slf->{'-dbh'}->{'odbc_query_timeout'} = $lim
    if $slf->{'-typ'} eq 'ODBC'
    && exists($slf->{'-dbh'}) && defined($slf->{'-dbh'});
  $slf->{'lim'} = $lim;
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
  my ($dbh, $flg, $lim);

  # Test the database connection
  $slf->{'try'} = 0;
  delete($slf->{'-not'});

  # Execute the request
  $lim = ($slf->{'-typ'} eq 'ODBC') ? 0 : $slf->get_alarm;
  $flg = 1;
  eval {
    local $SIG{'__WARN__'} = sub {};
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;

    alarm($lim) if $lim;
    eval {
      if ($dbh = $slf->connect($ctx))
      { if ($dbh->ping)
        { $flg = 0;
        }
        else
        { $slf->{'-msg'} = $DBI::errstr;
          $slf->{'-msg'} =~ s/[\n\r\s]+$//;
          $dbh->disconnect;
        }
      }
      };
    alarm(0) if $lim;
    die $@ if $@;
    };
  return '' unless $@ || $flg;

  # Detect and treat interrupts
  $slf->_log_timeout($ctx, 'Test') if $@ =~ m/^$ALR\n/;
  ++$slf->{'-err'};
  $slf->{'-not'} = 'No database access in the last run';

  # Disable further access to the database in case of problems
  $slf->{'try'} = $slf->{'max'};
  return 'RDA-00501: Database access disabled due to a connection problem';
}

# --- Methods required for RDA::Object::Sqlplus compatibility -----------------

sub get_prelim
{ undef;
}

sub set_prelim
{ undef;
}

# --- Default-specific methods ------------------------------------------------

sub dft_login
{ my ($slf, $usr, $pwd, $sid) = @_;
  my ($agt);

  if (defined($usr))
  { $slf->{'-pwd'} = $pwd;
    $slf->{'-sid'} = $sid;
    $slf->{'-usr'} = $usr;
  }
  else
  { $agt = $slf->{'-agt'};
    $slf->{'-sid'} = $agt->get_setting('ORACLE_SID', '');
    $slf->{'-usr'} = $agt->get_setting('SQL_LOGIN', 'SYSTEM');
  }
}

# --- ODBC-specific methods -------------------------------------------------

sub odbc_login
{ my ($slf, $usr, $pwd, $dsn) = @_;

  # Determine the login information
  if (defined($usr))
  { ($usr, $dsn) = ($1, $2) if $usr =~ m/^(.*)\@(.*)$/;
    ($usr, $pwd) = ($1, $2) if $usr =~ m/^(.*?)\/(.*)$/;
  }
  else
  { $usr = $pwd = '';
  }
  die "RDA-00519: Missing DSN" unless $dsn;
  $slf->{'-usr'} = $usr;
  $slf->{'-sid'} = check_dsn($dsn);

  # Prepare password request
  if (defined($pwd))
  { $slf->{'-pwd'} = $pwd;
  }
  else
  { $slf->{'-grp'} = $slf->{'-sid'};
    $slf->{'-txt'} = "Enter the password for '$usr' in '$dsn': ";
  }
}

# --- Oracle-specific methods -------------------------------------------------

sub ora_login
{ my ($slf, $usr, $pwd, $sid, $dba) = @_;
  my ($agt, $loc, $str, $suf);
 
  # Load the Oracle driver
  require DBD::Oracle;

  # Determine the login information
  $agt = $slf->{'-agt'};
  $str = $suf = '';
  if (defined($usr))
  { $loc = check_sid($agt->get_setting('ORACLE_SID'), '');
    $sid = check_sid($sid, '');
    $suf = ' as SYSDBA' if $dba;
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
  $str = length($sid) ? "\@$sid$suf" : $suf;
  $slf->{'-nam'} = 'Oracle';
  $slf->{'-usr'} = $usr;
  $slf->{'-sid'} = ($sid =~ $SID) ? sprintf($NET1, $1, $2, $3, '') :
                   ($sid !~ $SVC) ? $sid :
                   length($3)     ? sprintf($NET3, $1, $2, $4, $3, '') :
                                    sprintf($NET2, $1, $2, $4, '');
  unless ($DBD::Oracle::VERSION < 1.03)
  { $slf->{'-con'}->{'ora_session_mode'} = 2 if $suf =~ m/AS\s+SYSDBA/i;
    unless ($DBD::Oracle::VERSION < 1.20)
    { $slf->{'-con'}->{'ora_charset'} = 'AL32UTF8';
      $slf->{'-con'}->{'ora_envhp'}   = 0;
    }
  }

  # Prepare password request
  if (defined($pwd))
  { $slf->{'-pwd'} = $pwd;
  }
  else
  { $slf->{'-grp'} = ($sid eq '') ? $loc : $sid;
    $slf->{'-txt'} = "Enter the password for '$usr$str': ";
  }
}

# --- Internal routines -------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0)};
  $@ ? 0 : $lim;
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

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Library::Dbi|RDA::Library::Dbi>,
L<RDA::Object::Access|RDA::Object::Access>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
