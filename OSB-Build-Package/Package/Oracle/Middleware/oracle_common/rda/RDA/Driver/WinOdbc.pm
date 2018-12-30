# WinOdbc.pm: Class Used for Database Requests Using Win32::ODBC

package RDA::Driver::WinOdbc;

# $Id: WinOdbc.pm,v 1.19 2012/08/29 05:54:17 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/WinOdbc.pm,v 1.19 2012/08/29 05:54:17 mschenke Exp $
#
# Change History
# 20120828  MSC  Update type mapping.

=head1 NAME

RDA::Driver::WinOdbc - Class Used for Database Requests Using Win32::ODBC

=head1 SYNOPSIS

require RDA::Driver::WinOdbc;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::WinOdbc> class are used to interface a
database using Win32::ODBC.

The timeout mechanism is only effective for UNIX systems.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object::Access qw(check_dsn);
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $ALR = "___Alarm___";
my $CUT = "___Cut___";
my $OUT = qr#(ORA-01013:|timeout)#i;

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
my %tb_map = (
  '-11' => 'NUMBER',   # SQL_GUID
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
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Driver::WinOdbc-E<gt>new($agt[,$usr,$pwd,$dsn])>

The object constructor. It takes the agent object reference and the login
information as arguments.

C<RDA::Driver::WinOdbc> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'acc' > > DB access error flag (error outside result section)

=item S<    B<'dur' > > Remaining alarm duration

=item S<    B<'err' > > SQL error flag (error in result section)

=item S<    B<'ini' > > ODBC initialization error

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'max' > > Maximum number of SQL script failures

=item S<    B<'try' > > Number of SQL script failures

=item S<    B<'-agt'> > Reference to the agent object

=item S<    B<'-con'> > Connection attributes

=item S<    B<'-dbh'> > Database handle

=item S<    B<'-dft'> > Default password

=item S<    B<'-dsn'> > Database source name

=item S<    B<'-err'> > Number of SQL request errors

=item S<    B<'-grp'> > Password group

=item S<    B<'-msg'> > Last error message

=item S<    B<'-nam'> > Name of the database provider

=item S<    B<'-not'> > Statistics note

=item S<    B<'-out'> > Number of SQL requests timed out

=item S<    B<'-pwd'> > User password

=item S<    B<'-req'> > Number of SQL requests

=item S<    B<'-skp'> > Number of SQL requests skipped

=item S<    B<'-trc'> > SQL output trace level

=item S<    B<'-txt'> > Password request test

=item S<    B<'-usr'> > User name

=item S<    B<'-ver'> > Database version

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $agt, $usr, $pwd, $dsn) = @_;
  my ($slf);

  # Create the object
  $slf = bless {}, ref($cls) || $cls;

  # Setup some parameters by default
  $slf->{'-agt'} = $agt;
  $slf->{'-dft'} = $agt->get_info('yes') ? '?' : undef;
  $slf->{'-req'} = $slf->{'-err'} = $slf->{'-out'} = $slf->{'-skp'} = 0;
  $slf->{'-trc'} = $agt->get_setting('SQL_TRACE', 0);

  $slf->{'acc'} = $agt->get_setting('SQL_ACCESS', 0);
  $slf->{'dur'} = 0;
  $slf->{'err'} = $agt->get_setting('SQL_ERROR', 0);
  $slf->{'lim'} = _chk_alarm($agt->get_setting('SQL_TIMEOUT', 30));
  $slf->{'max'} = $agt->get_setting('SQL_ATTEMPTS', 3);
  $slf->{'try'} = 0;

  # Set the common attributes
  $slf->{'-con'} = {};

  # Initialize the ODBC access
  eval "require Win32::ODBC";
  if ($slf->{'ini'} = $@)
  { $slf->{'try'} = $slf->{'max'};
    $slf->{'_not'} = "Win32::ODBC package not available: $@";
  }
  else
  { # Analyze the login information
    if (defined($usr))
    { ($usr, $dsn) = ($1, $2) if $usr =~ m/^(.*)\@(.*)$/;
      ($usr, $pwd) = ($1, $2) if $usr =~ m/^(.*?)\/(.*)$/;
    }
    else
    { $usr = $pwd = '';
    }
    die "RDA-00519: Missing DSN\n" unless $dsn;
    $slf->{'-usr'} = $usr;
    $slf->{'-dsn'} = check_dsn($dsn);

    # Prepare password request
    if (defined($pwd))
    { $slf->{'-pwd'} = $pwd;
    }
    else
    { $slf->{'-grp'} = $slf->{'-dsn'};
      $slf->{'-txt'} = "Enter the password for '$usr' in '$dsn': ";
    }
  }

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

=head2 S<$h-E<gt>connect([$inc])>

This method connects to the database.

=cut

sub connect
{ my ($slf, $ctx, $inc) = @_;
  my ($dbh, $lim);

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
  { my ($acc, $con, $err, $grp, $pwd, $txt, $usr);

    # Get the password
    $acc = $ctx->get_access;
    $usr = $slf->{'-usr'};
    unless (defined($pwd = $slf->{'-pwd'}))
    { $grp = $slf->{'-grp'};
      $pwd = $acc->get_password('odbc', $grp, $usr, $slf->{'-txt'},
        $slf->{'-dft'});
      die "RDA-00508: Null password given; logon denied\n"
        unless defined($pwd);
    }

    # Connect to the database
    $con = $slf->{'-dsn'};
    $con = "DSN=$con;" unless $con =~ m/=/;
    $con .= "uid=$usr;pwd=$pwd;";
    unless (defined($slf->{'-dbh'} = Win32::ODBC->new($con)))
    { ($err, $txt) = Win32::ODBC->Error;
      $txt =~ s/[\n\r\s]+$//;
      $slf->{'-msg'} = $txt;
      ++$slf->{'-err'};
      die "RDA-00507: SQL Error: $txt\n" if $slf->{'acc'};
      return undef;
    }
  }

  # Set the timeout and clear previous error
  if (defined($dbh = $slf->{'-dbh'}))
  { $lim = $slf->get_alarm($inc);
    $dbh->SetConnectOption($dbh->SQL_QUERY_TIMEOUT, $lim);
    $dbh->SetStmtOption($dbh->SQL_QUERY_TIMEOUT, $lim);
    $dbh->ClearError;
  }

  # Return the database handle
  $dbh;
}

=head2 S<$h-E<gt>describe($ctx,$obj)>

This method returns a hash describing the specified table or view.

=cut

sub describe
{ my ($slf, $ctx, $obj) = @_;
  my ($cur, $dbh, $dsc, $err, $off, $sth, $txt, @nam, %att);

  ++$slf->{'-req'};
  $dsc = {row => [], typ => {}};
  eval {
    local $SIG{'__WARN__'} = sub {};

    if (($dbh = $slf->connect($ctx)) && !$dbh->Sql("SELECT * FROM $obj"))
    { @nam = $dbh->FieldNames;
      $off = @nam;
      while ($off > 0)
      { $cur = lc($nam[--$off]);
        unshift(@{$dsc->{'row'}}, $cur);
        %att = $dbh->ColAttributes($dbh->SQL_COLUMN_TYPE, $cur);
        $dsc->{'typ'}->{$cur} = $tb_map{$att{$cur}} || $att{$cur};
      }
    }
    };

  # Detect and treat interrupts
  if ($err = $@)
  { unless ($err =~ $OUT)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->disconnect;
    $slf->_log_timeout($ctx, "DESC $obj");
  }

  # Return the object description
  $dsc;
}

=head2 S<$h-E<gt>disconnect>

This method disconnects from the database.

=cut

sub disconnect
{ my ($slf) = @_;

  delete($slf->{'dbh'})->Close if exists($slf->{'dbh'});
}

=head2 S<$h-E<gt>execute($ctx,$job,$inc,$fct,$arg)>

This method executes a database job.

=cut

sub execute
{ my ($slf, $ctx, $job, $inc, $fct, $arg) = @_;
  my ($dbh, $err, $flg, $lin, $lng, $row, $tag, $trc, @job);

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
  @job = split(/\n/, $job);
  eval {
    local $SIG{'__WARN__'} = sub {};

    if ($dbh = $slf->connect($ctx, $inc))
    { while (defined($lin = shift(@job)))
      { if ($lin =~ m/^#\s*(SQL\d*)\s*$/)
        { my (@row, @sql);

          $tag = $1;
          push(@sql, $lin) while defined($lin = shift(@job)) && $lin ne '/';
          next unless @sql;
          if ($dbh->Sql(join(" ", @sql)))
          { ($err, $row) = $dbh->Error;
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
          while ($dbh->FetchRow)
          { @row = $dbh->Data;
            $row = join('|', @row);
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
        }
        elsif ($lin =~ m/^#\s*(PLSQL\d*)\s*$/)
        { die "RDA-00520: PL/SQL not supported through ODBC\n";
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
    { ($err, $row) = Win32::ODBC->Error;
      $row =~ s/[\n\r\s]+$//;
      die "RDA-00507: SQL Error: $row\n" if $slf->{'acc'};
      $slf->{'-msg'} = "ODBC-$err: $row";
    }
    };
  $dbh->{'LongReadLen'} = 1024 if $lng;

  # Detect and treat interrupts
  if ($err = $@)
  { unless ($err =~ m/^$ALR\n/)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->disconnect;
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

  $slf->get_provider($ctx) ? (lc($slf->{'-nam'}), 'odbc') : ('odbc');
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
value in case of connection problems.

=cut

sub get_provider
{ my ($slf, $ctx) = @_;

  unless (exists($slf->{'-nam'}))
  { my ($dbh, $err, $txt);

    # Execute the request
    eval {
      local $SIG{'__WARN__'} = sub {};

      if ($dbh = $slf->connect($ctx))
      { $slf->{'-nam'} = $dbh->GetInfo(17);
        ($err, $txt) = $dbh->Error;
        $txt =~ s/[\n\r\s]+$//;
        die "$txt\n" if $err;
      }
      };

    # Detect and treat interrupts
    if ($err = $@)
    { unless ($err =~ $OUT)
      { ++$slf->{'-err'};
        die $err;
      }
      $slf->disconnect;
      $slf->_log_timeout($ctx, 'DBprovider');
    }
  }
  $slf->{'-nam'};
}

=head2 S<$h-E<gt>get_sources([$pattern])>

This method returns the list of data sources. You can specify a pattern to
restrict the data sources.

=cut

sub get_sources
{ my ($slf, $pat) = @_;
  my (%tbl);

  return () if $slf->{'ini'};
  %tbl = Win32::ODBC::DataSources('');
  return sort keys(%tbl) unless defined($pat);
  return sort grep {$tbl{$_} =~ m/$pat/i} keys(%tbl);
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

  unless (exists($slf->{'-ver'}))
  { my ($dbh, $err, $txt);

    # Execute the request
    eval {
      local $SIG{'__WARN__'} = sub {};

      if ($dbh = $slf->connect($ctx))
      { $slf->{'-ver'} = $dbh->GetInfo(18);
        ($err, $txt) = $dbh->Error;
        die "$txt\n" if $err;
      }
      };

    # Detect and treat interrupts
    if ($err = $@)
    { unless ($err =~ $OUT)
      { ++$slf->{'-err'};
        die $err;
      }
      $slf->disconnect;
      $slf->_log_timeout($ctx, 'DBversion');
    }
  }
  $slf->{'-ver'};
}

=head2 S<$h-E<gt>is_enabled>

This method indicates whether or not a SQL statement is able to be executed.

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
  my ($dbh, $lim);

  $lim = $slf->get_alarm($inc);
  if (defined($inc) && exists($slf->{'-dbh'}) && defined($dbh = $slf->{'-dbh'}))
  { $dbh->SetConnectOption($dbh->SQL_QUERY_TIMEOUT, $lim);
    $dbh->SetStmtOption($dbh->SQL_QUERY_TIMEOUT, $lim);
  }
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
  my ($dbh, $lim);

  $lim = _chk_alarm($val);
  if (exists($slf->{'-dbh'}) && defined($dbh = $slf->{'-dbh'}))
  { $dbh->SetConnectOption($dbh->SQL_QUERY_TIMEOUT, $lim);
    $dbh->SetStmtOption($dbh->SQL_QUERY_TIMEOUT, $lim);
  }
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
  my ($cnt, $dbh, $err, $flg, $txt, @tab);

  # Test the database connection
  $slf->{'try'} = 0;
  delete($slf->{'-not'});

  # Execute the request
  $flg = 1;
  eval {
    local $SIG{'__WARN__'} = sub {};

    $flg = 0 if defined($slf->connect($ctx));
  };
  return '' unless $@ || $flg;

  # Disable further access to the database in case of problems
  if ($err = $@)
  { $slf->disconnect;
    ++$slf->{'-err'};
    $slf->_log_timeout($ctx, 'Test') if $err =~ $OUT;
  }
  $slf->{'-not'} = 'No database access in the last run';
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

# --- Internal routines -------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  ($lim > 0) ? $lim : 0;
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
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
