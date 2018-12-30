# Dbi.pm: Class Used for Database Macros

package RDA::Library::Dbi;

# $Id: Dbi.pm,v 2.28 2012/05/07 18:10:46 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Dbi.pm,v 2.28 2012/05/07 18:10:46 mschenke Exp $
#
# Change History
# 20120507  MSC  Normalize the credentials.

=head1 NAME

RDA::Library::Dbi - Class Used for Database Macros

=head1 SYNOPSIS

require RDA::Library::Dbi;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Dbi> class are used to interface with
database-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Driver::Dbd;
  use RDA::Driver::Jdbc;
  use RDA::Driver::Sqlplus;
  use RDA::Driver::WinOdbc;
  use RDA::Object::Access qw(check_dsn check_sid);
  use RDA::Object::Buffer;
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.28 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $BUF = qr/^___Capture(_Only)?_(\w+)___$/;
my $EOC = qr/^___End_Capture___$/;
my $EXT = qr/^[^:]+:\d+:{1,2}[^:]+$/;
my $LOG = qr/^((ORA|SP2)-\d{4,}):\s*(.*)/;
my $MAC = qr/^___Macro_(\w+)\((\d+)\)___$/;
my $RPT = qr/^RDA::Object::(Pipe|Report)/i;
my $SID = qr/^([^:]+):(\d+):([^:]+)$/;
my $SVC = qr/^([^:]+):(\d+):([^:]*):([^:]+)$/;

my $ERR1 = '^ERROR( at line \d+| in \S+ request):$';
my $ERR2 = 'error possibly near <\*> indicator';
my $ERR3 = '^(\[\S*\]\s*){3}';
my $ERR = qr/($ERR1|$ERR2|$ERR3)/i;

my %tb_cat = (
  '?'                        => sub {join(' || ', @_)},
  'adaptive server anywhere' => sub {join(' || ', @_)},
  'odbc'                     => sub {'{fn CONCAT('.join(',', @_).')}'},
  'oracle'                   => sub {join(' || ', @_)},
  );
my %tb_fct = (
  'checkDsn'          => [\&_m_check_dsn,      'T'],
  'clearDbBuffer'     => [\&_m_clear_buffer,   'N'],
  'clearDbColumns'    => [\&_m_clear_columns,  'N'],
  'clearLastDb'       => [\&_m_clear_last,     'N'],
  'concatDb'          => [\&_m_concat,         'T'],
  'getDataSources'    => [\&_m_get_sources,    'L'],
  'getDbBuffer'       => [\&_m_get_buffer,     'O'],
  'getDbColumns'      => [\&_m_get_columns,    'L'],
  'getDbDesc'         => [\&_m_get_desc,       'L'],
  'getDbHits'         => [\&_m_get_hits,       'L'],
  'getDbLines'        => [\&_m_get_lines,      'L'],
  'getDbMessage'      => [\&_m_get_message,    'T'],
  'getDbPrelim'       => [\&_m_get_prelim,     'N'],
  'getDbProvider'     => [\&_m_get_provider,   'T'],
  'getDbTimeout'      => [\&_m_get_timeout,    'N'],
  'getDbVersion'      => [\&_m_get_version,    'T'],
  'getDrivers'        => [\&_m_get_drivers,    'L'],
  'grepLastDb'        => [\&_m_grep_last,      'L'],
  'grepDb'            => [\&_m_grep_sql,       'L'],
  'grepDbBuffer'      => [\&_m_grep_buffer,    'L'],
  'hasDbPassword'     => [\&_m_has_password,   'N'],
  'isDbEnabled'       => [\&_m_is_enabled,     'N'],
  'isDriverAvailable' => [\&_m_is_available,   'T'],
  'loadDb'            => [\&_m_load_sql,       'N'],
  'resetDbTimeout'    => [\&_m_reset_timeout,  'N'],
  'sameDbPassword'    => [\&_m_same_password,  'N'],
  'setDbAccess'       => [\&_m_set_access,     'N'],
  'setDbColumns'      => [\&_m_set_columns,    'N'],
  'setDbError'        => [\&_m_set_error,      'N'],
  'setDbFailure'      => [\&_m_set_failure,    'N'],
  'setDbHeader'       => [\&_m_set_header,     'N'],
  'setDbPassword'     => [\&_m_set_password,   'N'],
  'setDbPrelim'       => [\&_m_set_prelim,     'N'],
  'setDbTimeout'      => [\&_m_set_timeout,    'N'],
  'setDbTrace'        => [\&_m_set_trace,      'N'],
  'setDbType'         => [\&_m_set_type,       'N'],
  'shareDbPassword'   => [\&_m_share_password, 'N'],
  'switchDb'          => [\&_m_switch,         'N'],
  'testDb'            => [\&_m_test_sql,       'T'],
  'writeDb'           => [\&_m_write_sql,      'N'],
  'writeLastDb'       => [\&_m_write_last,     'N'],
  );
my %tb_jus = (
  FLOAT  => 'L',
  NUMBER => 'L',
  );
my %tb_typ = (
  '?' => {
    CHAR      => '%s',
    DATE      => '%s',
    FLOAT     => '%s',
    NCHAR     => '%s',
    NUMBER    => '%s',
    NVARCHAR2 => '%s',
    TIMESTAMP => '%s',
    VARCHAR2  => '%s',
    },
  'adaptive server anywhere' => {
    CHAR      => '%s',
    DATE      => 'dateformat(%s,\'DD-Mmm-YYYY HH:NN:SS\')',
    FLOAT     => '%s',
    NCHAR     => '%s',
    NUMBER    => '%s',
    NVARCHAR2 => '%s',
    TIMESTAMP => 'dateformat(%s,\'DD-Mmm-YYYY HH:NN:SS.SS\')',
    VARCHAR2  => '%s',
    },
  'odbc' => {
    CHAR      => '%s',
    DATE      => \&_get_date_fmt,
    FLOAT     => '%s',
    NCHAR     => '%s',
    NUMBER    => '%s',
    NVARCHAR2 => '%s',
    TIMESTAMP => \&_get_date_fmt,
    VARCHAR2  => '%s',
    },
  'oracle' => {
    CHAR      => '%s',
    DATE      => 'TO_CHAR(%s,\'DD-Mon-YYYY HH24:MI:SS\')',
    FLOAT     => '%s',
    NCHAR     => '%s',
    NUMBER    => '%s',
    NVARCHAR2 => '%s',
    TIMESTAMP => 'TO_CHAR(%s,\'DD-Mon-YYYY HH24:MI:SSxFF\')',
    VARCHAR2  => '%s',
    },
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Dbi-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Dbi> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_buf'> > Buffer hash

=item S<    B<'_cat'> > Concatenation function

=item S<    B<'_dbh'> > Current database handle

=item S<    B<'_dbi'> > Available DBI drivers

=item S<    B<'_dft'> > Default database handle

=item S<    B<'_dsc'> > Table description hash

=item S<    B<'_err'> > Number of SQL request errors

=item S<    B<'_frk'> > Fork indicator

=item S<    B<'_hit'> > Lines captured when executing SQL statements

=item S<    B<'_lim'> > Execution time limit (in sec)

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of SQL requests timed out

=item S<    B<'_req'> > Number of SQL requests

=item S<    B<'_skp'> > Number of SQL requests skipped

=item S<    B<'_sql'> > Last SQL result

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($fil, $grp, $rpt, $sid, $slf, $typ);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _buf => {},
    _dsc => {},
    _err => 0,
    _hit => [],
    _lim => 0,
    _not => '',
    _out => 0,
    _req => 0,
    _skp => 0,
    _sql => [],
    }, ref($cls) || $cls;

  # Setup some parameters by default
  $slf->{'_frk'} = $agt->can_fork > 0;

  # Adapt the environment
  if ($agt->get_setting('DATABASE_LOCAL',1))
  { $sid = $agt->get_setting('ORACLE_SID', '');
    $ENV{'ORACLE_SID'} = $sid if $sid && $sid !~ $EXT;
  }

  # Create the handle for the default connection
  unless ($agt->get_setting('NO_DBI'))
  { eval {
      require DBI;
      $slf->{'_dbi'} = {map {lc($_) => $_} DBI->available_drivers};
      delete($slf->{'_dbi'}->{'oracle'}) if $ENV{'RDA_NO_DBD_ORACLE'};
      $slf->{'_dbh'} = RDA::Driver::Dbd->new('Oracle', $agt)
        if exists($slf->{'_dbi'}->{'oracle'});
      };
  }
  $slf->{'_dbh'} = RDA::Driver::Sqlplus->new($agt)
    unless exists($slf->{'_dbh'});

  # Delete previous temporary files
  $rpt = $agt->get_setting('RPT_DIRECTORY');
  $grp = $agt->get_setting('RPT_GROUP');
  if (opendir(DIR, $rpt))
  { while (defined($fil = readdir(DIR)))
    { next unless $fil =~ m/^tmp_$grp\_\d+_\d+.txt$/i;
      $fil = RDA::Object::Rda->cat_file($rpt, $fil);
      1 while unlink($fil);
    }
    closedir(DIR);
  }

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(reload stat thread));

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}->[0]}($slf, @arg);
}

=head2 S<$h-E<gt>clr_stats>

This method resets the statistics and clears corresponding module settings.

=cut

sub clr_stats
{ my ($slf) = @_;

  $slf->{'_buf'} = {};
  $slf->{'_not'} = '';
  $slf->{'_req'} = $slf->{'_err'} = $slf->{'_out'} = $slf->{'_skp'} = 0;
}

=head2 S<$h-E<gt>get_stats>

This method reports the library statistics in the specified module.

=cut

sub get_stats
{ my ($slf) = @_;
  my ($use);

  # Add last database handle contribution
  _restore_dbh($slf);

  # Generate the statistics
  if ($slf->{'_req'})
  { # Get the statistics record
    $use = $slf->{'_agt'}->get_usage;
    $use->{'DBI'} = {err => 0, not => '', out => 0, req => 0, skp => 0}
      unless exists($use->{'DBI'});
    $use = $use->{'DBI'};

    # Indicate the current timeout when there is no other note
    $slf->{'_not'} = 'DBI execution limited to '.$slf->{'_lim'}.'s'
      unless $use->{'not'} || $slf->{'_not'} || $slf->{'_lim'} <= 0;

    # Generate the module statistics
    $use->{'err'} += $slf->{'_err'};
    $use->{'out'} += $slf->{'_out'};
    $use->{'req'} += $slf->{'_req'};
    $use->{'skp'} += $slf->{'_skp'};
    $use->{'not'} = $slf->{'_not'} if $slf->{'_not'};

    # Reset the statistics
    clr_stats($slf);
  }
}

sub _add_usage
{ my ($slf) = @_;
  my ($rec);

  # Get the database handle contribution
  $rec = $slf->{'_dbh'}->get_usage;

  # Increment the couters
  $slf->{'_req'} += $rec->{'req'};
  $slf->{'_err'} += $rec->{'err'};
  $slf->{'_out'} += $rec->{'out'};
  $slf->{'_skp'} += $rec->{'skp'};

  # Manage the note
  if (exists($rec->{'not'}))
  { $slf->{'_not'} = $rec->{'not'};
  }
  elsif (!exists($slf->{'_not'}) && $rec->{'_lim'} > 0)
  { $slf->{'_not'} = 'SQL execution limited to '.$rec->{'_lim'}.'s'
  }
}

=head2 S<$h-E<gt>reset>

This method resets the object for its new environment to allow a thread-save
execution.

=cut

sub reset
{ my ($slf) = @_;

  $slf->{'_dbh'}->reset;
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 DATABASE MACROS

=head2 S<checkDsn($dsn[,$dft])>

This macro checks the data source name and returns a normalized string for
password management.

=cut

sub _m_check_dsn
{ my ($slf, $ctx, $dsn, $dft) = @_;

  check_dsn($dsn, $dft);
}

=head2 S<clearDbColumns($tid)>

This macro clears all information associated with the specified table
identifier.

=cut

sub _m_clear_columns
{ my ($slf, $ctx, $tid) = @_;

  delete($slf->{'_dsc'}->{$tid}) if $tid;
  0;
}

=head2 S<clearDbBuffer([$nam,...])>

This macro deletes the specified capture buffers. The capture buffer names are
not case sensitive. It deletes all capture buffers when called without
arguments.

=cut

sub _m_clear_buffer
{ my ($slf, $ctx, @arg) = @_;

  if (@arg)
  { foreach my $nam (@arg)
    { delete($slf->{'_buf'}->{lc($nam)}) if defined($nam);
    }
  }
  else
  { $slf->{'_buf'} = {};
  }
  0;
}

=head2 S<clearLastDb()>

This macro clears the last SQL result.

=cut

sub _m_clear_last
{ shift->{'_sql'} = [];
}

=head2 S<concatDb(@fields)>

This macro returns how to concatenate the specified fields. It ignores invalid
arguments. It returns an undefined value in the absence of valid arguments.

=cut

sub _m_concat
{ my ($slf, $ctx, @arg) = @_;
  my (@tbl);

  (@tbl = grep {defined($_) && !ref($_)} @arg)
    ? &{_get_concat($slf, $ctx)}(@tbl)
    : undef;
}

=head2 S<getDataSources()>

This macro returns the list of data sources.

=cut

sub _m_get_sources
{ my ($slf, $ctx, $pat) = @_;

  $slf->{'_dbh'}->get_sources($pat);
}

=head2 S<getDbBuffer([$nam[,$flg]])>

This macro returns the specified capture buffer or the hit buffer when the name
is undefined. The capture buffer names are not case sensitive. Unless the flag
is set, it assumes Wiki data.

=cut

sub _m_get_buffer
{ my ($slf, $ctx, $nam, $flg) = @_;

  RDA::Object::Buffer->new($flg ? 'L' : 'l',
    defined($nam) ? $slf->{'_buf'}->{lc($nam)} : $slf->{'_hit'});
}

=head2 S<getDbColumns($tid,$obj[,@col])>

This macro determines if the specified columns are present in the table and
generates the header string and the select list accordingly. You can provide
specific headers or select contributions through the C<setDbColumns> and
C<setDbHeader> macros. RDA supports predefined data types only unless an
explicit select contribution or an extra conversion format is specified. You
can manage the data types list with the C<setDbType> macro.

When no columns are specified, all table columns are considered.

This macro returns a list containing the corresponding header and select
list. If the table is not found or if the query identifier is missing, then the
header and select list are undefined.

=cut

sub _m_get_columns
{ my ($slf, $ctx, $tid, $obj, @arg) = @_;
  my ($col, $dsc, $hdr, $jus, $row, $typ, @hdr, @sel, @tbl);

  # Get the table description and reject an unknown table
  return () unless $tid;
  $slf->{'_dsc'}->{$tid} = {} unless exists($slf->{'_dsc'}->{$tid});
  unless (exists($slf->{'_dsc'}->{$tid}->{'typ'}))
  { $dsc = $slf->{'_dbh'}->describe($ctx, $obj);
    $slf->{'_dsc'}->{$tid}->{'row'} = $dsc->{'row'};
    $slf->{'_dsc'}->{$tid}->{'typ'} = $dsc->{'typ'};
  }
  $dsc = $slf->{'_dsc'}->{$tid};
  return () unless (@{$row = $dsc->{'row'}});

  # Generate the row
  $row = \@arg if @arg;
  foreach my $nam (@$row)
  { $col = lc($nam);

    # Reject unknown column
    next unless exists($dsc->{'typ'}->{$col})
      && defined($typ = $dsc->{'typ'}->{$col});

    # Determine how to justify the column
    $jus = exists($dsc->{'jus'}->{$col}) ? $dsc->{'jus'}->{$col} :
           exists($tb_jus{$typ})         ? $tb_jus{$typ} :
                                           'R';

    # Identify the header contribution
    if (exists($dsc->{'hdr'}->{$col}))
    { $hdr = $dsc->{'hdr'}->{$col};
    }
    else
    { $hdr = "*$col*";
      $hdr =~ s#_# #g;
      $hdr =~ s#\b([a-z])#\U$1#g;
      $hdr = " $hdr" if $jus =~ m/L/;
      $hdr = "$hdr " if $jus =~ m/R/;
    }

    # Identify the select contribution
    $col = exists($dsc->{'col'}->{$col})
      ? $dsc->{'col'}->{$col}
      : _desc_typ($slf, $ctx, $dsc, $col, $typ);
    next unless $col;
    $col = &{_get_concat($slf, $ctx)}("'", "\n       $col", "'");
    $col =~ s/\s\n/\n/g;
    $col = " $col" if $jus =~ m/L/;
    $col = "$col " if $jus =~ m/R/;
    push(@sel, $col);
    push(@hdr, $hdr);
  }

  # Return the header and select strings
  (scalar @sel) ? ('|'.join('|', @hdr).'|', "'|".join('|',@sel)."|'") : ();
}

sub _desc_typ
{ my ($slf, $ctx, $dsc, $col, $typ) = @_;
  my ($fmt);

  return _replace($dsc->{'fmt'}->{$typ}, $col)
    if exists($dsc->{'fmt'}->{$typ});
  foreach my $dia ($slf->{'_dbh'}->get_dialects($ctx))
  { if (exists($tb_typ{$dia}) && exists($tb_typ{$dia}->{$typ}))
    { $fmt = $tb_typ{$dia}->{$typ};
      $fmt = &$fmt($slf, $ctx) if ref($fmt) eq 'CODE';
      return _replace($fmt, $col) if defined($fmt);
    }
  }
  '';
}

=head2 S<getDbDesc($tid,$col[,$flg])>

This macro returns the description of the column as a list containing the
column position and its type. Column positions start from 1. Unless the flag is
set, only eligible columns are considered.

The list is empty when the column is not found.

=cut

sub _m_get_desc
{ my ($slf, $ctx, $tid, $col, $flg) = @_;
  my ($cnt, $dsc, $val);

  # Get the query entry
  return () unless $col && $tid && exists($slf->{'_dsc'}->{$tid});
  $dsc = $slf->{'_dsc'}->{$tid};

  # Validate the column
  $col = lc($col);
  return ()
    unless exists($dsc->{'typ'}->{$col}) && defined($dsc->{'typ'}->{$col});

  # Search for the column
  $cnt = 0;
  foreach my $nam (@{$dsc->{'row'}})
  { # Identify the select contribution
    unless ($flg)
    { $val = exists($dsc->{'col'}->{$nam})
        ? $dsc->{'col'}->{$nam}
        : _desc_typ($slf, $ctx, $dsc, $nam, $dsc->{'typ'}->{$nam});
      next unless $val;
    }

    # Check the column
    ++$cnt;
    return ($cnt, $dsc->{'typ'}->{$col}) if $col eq $nam;
  }

  # Indicate that the column has not been found
  ();
}

=head2 S<getDbHits()>

This macro returns the list of lines captured during the last C<writeDb>.

=cut

sub _m_get_hits
{ @{shift->{'_hit'}};
}

=head2 S<getDbLines([$min[,$max]])>

This macro returns a range of the lines of the last SQL result. It assumes the
first and last line as the default for the range definition. You can use
negative line numbers to specify lines from the buffer end.

=cut

sub _m_get_lines
{ my ($slf, $ctx, $min, $max) = @_;
  my $buf;

  # Validate the range
  $buf = $slf->{'_sql'};
  $min = (!defined($min) || ($#$buf + $min) < -1) ? 0 :
         ($min < 0) ? $#$buf + $min + 1 :
         $min;
  $max = (!defined($max)) ? $#$buf :
         (($#$buf + $max) < -1) ? 0 :
         ($max < 0) ? $#$buf + $max + 1 :
         ($max > $#$buf) ? $#$buf :
         $max;

  # Return the line range
  @$buf[$min..$max];
}

=head2 S<getDbMessage()>

This macro returns the error message of the last SQL execution. If no error is
detected, it returns C<undef>.

=cut

sub _m_get_message
{ shift->{'_dbh'}->get_message;
}

=head2 S<getDbPrelim()>

This macro indicates whether the C<prelim> option is set.

=cut

sub _m_get_prelim
{ shift->{'_dbh'}->get_prelim;
}

=head2 S<getDbProvider()>

This macro returns the name of the database provider of the current
connection. It returns an undefined value in case of connection problems.

=cut

sub _m_get_provider
{ my ($slf, $ctx) = @_;

  $slf->{'_dbh'}->get_provider($ctx);
}

=head2 S<getDbTimeout()>

This macro returns the current duration of the SQL timeout. If this mechanism
is disabled, it returns 0.

=cut

sub _m_get_timeout
{ shift->{'_dbh'}->get_timeout;
}

=head2 S<getDbVersion()>

This macro returns the database version of the current connection. It returns
an undefined value in case of connection problems.

=cut

sub _m_get_version
{ my ($slf, $ctx) = @_;

  $slf->{'_dbh'}->get_version($ctx);
}

=head2 S<getDrivers()>

This macro returns the list of available drivers.

=cut

sub _m_get_drivers
{ my ($slf) = @_;

  return () unless exists($slf->{'_dbi'});
  (sort values(%{$slf->{'_dbi'}}));
}

=head2 S<grepLastDb($re,$opt)>

This macro returns the lines of the last SQL result that match the regular
expression. It supports the same options as C<grepDb>.

=cut

sub _m_grep_last
{ my ($slf, $ctx, $re, $opt) = @_;

  _grep_buffer($slf->{'_sql'}, $re, $opt);
}

=head2 S<grepDb($sql,$re,$opt)>

This macro returns the lines that match the regular expression. The following
options are supported:

=over 9

=item B<    'f' > Stops scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the results

=item B<    'v' > Inverts the sense of matching to select nonmatching lines

=back

=cut

sub _m_grep_sql
{ my ($slf, $ctx, $sql, $re, $opt) = @_;
  my ($flg, $inv, $one, @tbl);

  # Determine the options
  $opt = '' unless defined($opt);
  $one = index($opt, 'f') >= 0;
  $re = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
  $inv = index($opt, 'v') >= 0;

  # Check the SQL output
  $slf->{'_dbh'}->execute($ctx, $sql, 1, \&_grep_sql, [$re, \@tbl, $inv, $one])
    if $re;
  @tbl;
}

sub _grep_sql
{ my ($dbh, $rec, $lin) = @_;
  my $flg;

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL Error\n" if $lin =~ $ERR && $dbh->{'err'};

  # Check if the line matches the pattern
  $flg = ($lin =~ $rec->[0]);
  if ($rec->[2] ? !$flg : $flg)
  { push(@{$rec->[1]}, $lin);
    return $rec->[3];
  }

  # Continue the search
  0;
}

=head2 S<grepDbBuffer($nam,$re,$opt)>

This macro returns the lines of the specified capture buffer that match the
regular expression. It supports the same options as C<grepDb>.

=cut

sub _m_grep_buffer
{ my ($slf, $ctx, $nam, $re, $opt) = @_;

  return () unless defined($nam) && exists($slf->{'_buf'}->{$nam = lc($nam)});
  _grep_buffer($slf->{'_buf'}->{$nam}, $re, $opt);
}

sub _grep_buffer
{ my ($buf, $re, $opt) = @_;
  my ($flg, $inv, $one, @tbl);

  if ($re)
  { # Determine the options
    $opt = '' unless defined($opt);
    $one = index($opt, 'f') >= 0;
    $re = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
    $inv = index($opt, 'v') >= 0;

    # Check the last SQL result
    foreach my $lin (@$buf)
    { $flg = ($lin =~ $re);
      if ($inv ? !$flg : $flg)
      { push(@tbl, $lin);
        last if $one;
      }
    }
  }
  @tbl;
}

=head2 S<hasDbPassword($usr[,$typ[,$sid]])>

This macro indicates whether a password hash entry exists for the specified
user. You can provide an alternative system identifier as the third argument.

=cut

sub _m_has_password
{ my ($slf, $ctx, $usr, $typ, $sid) = @_;

  return 0 unless $usr;

  # Parse the arguments
  if ($usr =~ m/^([^@]*)\@(([a-z]+|\-|\+)\@)?(\S+)/i)
  { $usr = $1;
    $typ = $3 if defined($2);
    $sid = $4;
  }
  else
  { $usr = $1 if $usr =~ m/^([^@]*)\@/;
    $sid = '' unless defined($sid);
  }

  # Indicate if a password has been provided for that user
  $ctx->get_access->has_password($typ, $sid, $usr);
}

=head2 S<isDbEnabled()>

This macro indicates whether a SQL statement will be executed.

=cut

sub _m_is_enabled
{ shift->{'_dbh'}->is_enabled;
}

=head2 S<isDriverAvailable($typ)>

This macro indicates whether a driver is available for the specified database
type.

=cut

sub _m_is_available
{ my ($slf, $ctx, $typ) = @_;

  exists($slf->{'_dbi'}) && exists($slf->{'_dbi'}->{lc($typ)})
    ? $slf->{'_dbi'}->{lc($typ)}
    : undef;
}

=head2 S<loadDb($sql,$flg[,$inc])>

This macro loads the output of the SQL statement as the last SQL result. It
clears the previous result unless the flag is set. It returns 1 for a
successful completion. If the execution time exceeds the limit or if the
maximum number of attempts has been reached, then it returns 0.

It is possible to increase the execution limit by specifying an increasing
factor as an argument. A negative value disables any timeout.

Only lines between C<___Cut___> lines are inserted in the last SQL result.

=cut

sub _m_load_sql
{ my ($slf, $ctx, $sql, $flg, $inc) = @_;

  $slf->{'_sql'} = [] unless $flg;
  $slf->{'_dbh'}->execute($ctx, $sql, $inc, \&_load_sql,
    [$ctx, $slf->{'_sql'}]);
}

sub _load_sql
{ my ($dbh, $rec, $lin) = @_;

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL Error\n" if $lin =~ $ERR && $dbh->{'err'};

  # Save the line in the last SQL result
  push(@{$rec->[1]}, $lin);

  # Continue the result processing
  0;
}

=head2 S<resetDbTimeout([$inc])>

This macro resets the remaining alarm time to the SQL timeout value. To allow
more time for executing statements, you can specify a factor as an argument. 1
is the default. For a positive value, the maximum execution time is obtained by
multiplying the SQL timeout value by this factor. Otherwise, it disables the
alarm mechanism.

The effective value is returned.

=cut

sub _m_reset_timeout
{ my ($slf, $ctx, $inc) = @_;

  $slf->{'_dbh'}->reset_timeout($inc);
}

=head2 S<sameDbPassword($user,$type,$sid...)>

This macro assigns the current password of the specified user to all specified
systems of a same type.

=cut

sub _m_same_password
{ my ($slf, $ctx, @arg) = @_;

  $ctx->get_access->same_password(@arg);
}

=head2 S<setDbAccess($flag)>

This macro manages the access/connect error flag. When the flag is set, it
generates an error when an access/connect error is detected.

It returns the previous value of the flag.

=cut

sub _m_set_access
{ my ($slf, $ctx, $flg) = @_;

  $slf->{'_dbh'}->set_access($flg);
}

=head2 S<setDbColumns($tid[,$col1,$val1...])>

This macro specifies the select list contribution for one or more columns. An
undefined value deletes an existing contribution. When no columns are specified,
all previous declarations are deleted.

=cut

sub _m_set_columns
{ my $slf = shift;
  my $ctx = shift;
  my $tid = shift;
  my ($dsc, $key, $val);

  # Get the query entry
  return 0 unless $tid;
  $slf->{'_dsc'}->{$tid} = {} unless exists($slf->{'_dsc'}->{$tid});
  $dsc = $slf->{'_dsc'}->{$tid};

  # Manage select list contributions
  if (@_)
  { while (($key, $val) = splice(@_, 0, 2))
    { if (defined($val))
      { $dsc->{'col'}->{lc($key)} = $val;
      }
      else
      { delete($dsc->{'col'}->{lc($key)});
      }
    }
  }
  else
  { delete($dsc->{'col'});
  }
  1;
}

=head2 S<setDbError($flag)>

This macro manages the SQL error flag. When the flag is set, it generates an
error when a SQL error is detected.

It returns the previous value of the flag.

=cut

sub _m_set_error
{ my ($slf, $ctx, $flg) = @_;

  $slf->{'_dbh'}->set_error($flg);
}

=head2 S<setDbFailure($cnt)>

This macro manages the number of SQL script failures. A negative value disables
any further database connection.

It returns the previous value of the counter.

=cut

sub _m_set_failure
{ my ($slf, $ctx, $cnt) = @_;

  $slf->{'_dbh'}->set_failure($cnt);
}

=head2 S<setDbHeader($tid[,$col1,$val1...])>

This macro specifies the header contribution for one or more columns. The
justification is deduced from the presence of leading and/or trailing spaces. An
undefined value deletes an existing contribution. When no columns are
specified, all previous declarations are removed.

=cut

sub _m_set_header
{ my $slf = shift;
  my $ctx = shift;
  my $tid = shift;
  my ($dsc, $key, $val);

  # Get the query entry
  return 0 unless $tid;
  $slf->{'_dsc'}->{$tid} = {} unless exists($slf->{'_dsc'}->{$tid});
  $dsc = $slf->{'_dsc'}->{$tid};

  # Manage header contributions
  if (@_)
  { while (($key, $val) = splice(@_, 0, 2))
    { $key = lc($key);
      if (defined($val))
      { $dsc->{'hdr'}->{$key} = $val;
        $dsc->{'jus'}->{$key} = ($val =~ m/^\s+\*/ ? 'L' : '')
          .($val =~ m/\*\s+$/ ? 'R' : '');
      }
      else
      { delete($dsc->{'hdr'}->{$key});
        delete($dsc->{'jus'}->{$key});
      }
    }
  }
  else
  { delete($dsc->{'hdr'});
    delete($dsc->{'jus'});
  }
  1;
}

=head2 S<setDbPassword($user,$password[,$type[,$sid]])>

This macro adds the specified login information in the password table.

=cut

sub _m_set_password
{ my ($slf, $ctx, $usr, $pwd, $typ, $sid) = @_;
  my ($suf, $old);

  return 0 unless defined($usr);

  # Parse the arguments
  if ($usr =~ m/^([^@]*)@((\w+)\@)?(\S+)/)
  { $usr = $1;
    $typ = $3 if defined($3);
    $sid = $4;
  }
  else
  { $usr = $1 if $usr =~ m/^([^@]*)@/;
    $sid = '' unless defined($sid);
  }
  ($usr, $pwd) = ($1, $2) if $usr =~ m/^(.*?)\/(.*)$/;

  # Store the login information
  return 0 unless defined($pwd);
  $pwd =~ s/\r\n//g;
  $ctx->get_access->set_password($typ, $sid, $usr, $pwd);
  1;
}

=head2 S<setDbPrelim($flag)>

This macro controls the C<prelim> option. When the flag is set, it activates
the option. Otherwise, it removes the option.

It returns the previous status.

=cut

sub _m_set_prelim
{ my ($slf, $ctx, $flg) = @_;

  $slf->{'_dbh'}->set_prelim($flg);
}

=head2 S<setDbTimeout($sec)>

This macro sets the SQL timeout, specified in seconds, only if the value is
greater than zero. Otherwise, the timeout mechanism is disabled. It is disabled
also if the alarm function is not implemented.

It returns the effective value.

=cut

sub _m_set_timeout
{ my ($slf, $ctx, $val) = @_;

  $slf->{'_lim'} = $slf->{'_dbh'}->set_timeout($val);
}

=head2 S<setDbTrace([$flag])>

This macro manages the SQL trace flag. When the flag is set, it prints all SQL
lines to the screen. It remains unchanged if the flag value is undefined.

It returns the previous value of the flag.

=cut

sub _m_set_trace
{ my ($slf, $ctx, $flg) = @_;

  $slf->{'_dbh'}->set_trace($flg);
}

=head2 S<setDbType($tid[,$typ1,$fmt1...])>

This macro specifies how to format data types. You can use an empty string to
reject a predefined data type. An undefined value deletes an existing
declaration. When no types are specified, all previous declarations are deleted.

=cut

sub _m_set_type
{ my $slf = shift;
  my $ctx = shift;
  my $tid = shift;
  my ($dsc, $key, $val);

  # Get the query entry
  return 0 unless $tid;
  $slf->{'_dsc'}->{$tid} = {} unless exists($slf->{'_dsc'}->{$tid});
  $dsc = $slf->{'_dsc'}->{$tid};

  # Manage select list contributions
  if (@_)
  { while (($key, $val) = splice(@_, 0, 2))
    { if (defined($val))
      { $dsc->{'fmt'}->{uc($key)} = $val;
      }
      else
      { delete($dsc->{'fmt'}->{uc($key)});
      }
    }
  }
  else
  { delete($dsc->{'fmt'});
  }
  1;
}

=head2 S<shareDbPassword($type,$sid,...)>

This macro shares the credentials between the specified systems, identified by
type and identifier pairs.

=cut

sub _m_share_password
{ my ($slf, $ctx, @arg) = @_;

  $ctx->get_access->share_password(@arg);
}

=head2 S<switchDb([$type,[$user[,$password[,$sid[,$dba]]]]])>

This macro switches the current database handle. It restores the default the
database handle when no database type is specified or when the corresponding
driver is not available. Using C<+> as database type forces SQL*Plus use. The
default database handle is restored at data collection module completion.

When the password is not specified, it is asked interactively at the first
statement execution. By default, the user is derived from the C<SQL_LOGIN>
setting.

=cut

sub _m_switch
{ my ($slf, $ctx, $typ, $usr, $pwd, $sid, $dba) = @_;

  !defined($typ) ?
     _restore_dbh($slf) :
  (($typ = lc($typ)) eq 'jdbc') ?
    _save_dbh($slf,
      RDA::Driver::Jdbc->new($ctx, $usr, $pwd, $sid, $dba)) :
  exists($slf->{'_dbi'}->{$typ}) ?
    _save_dbh($slf,
      RDA::Driver::Dbd->new($slf->{'_dbi'}->{$typ}, $slf->{'_agt'}, $usr, $pwd,
                            $sid, $dba)) :
  ($typ eq 'oracle' || $typ eq '+') ?
    _save_dbh($slf,
      RDA::Driver::Sqlplus->new($slf->{'_agt'}, $usr, $pwd, $sid, $dba)) :
  ($typ eq 'odbc' || $typ eq '-') ?
    _save_dbh($slf,
      RDA::Driver::WinOdbc->new($slf->{'_agt'}, $usr, $pwd, $sid, $dba)) :
    _restore_dbh($slf);
  1;
}

sub _restore_dbh
{ my ($slf) = @_;

  if (exists($slf->{'_dft'}))
  { _add_usage($slf);
    $slf->{'_dbh'}->delete;
    $slf->{'_dbh'} = delete($slf->{'_dft'});
  }
  1;
}

sub _save_dbh
{ my ($slf, $dbh) = @_;

  _add_usage($slf);
  if (exists($slf->{'_dft'}))
  { $slf->{'_dbh'}->delete;
  }
  else
  { $slf->{'_dft'} = $slf->{'_dbh'};
  }
  $slf->{'_dbh'} = $dbh;
  1;
}

=head2 S<testDb()>

This macro tests the database connection. In case of problems, further access
is disabled.

=cut

sub _m_test_sql
{ my ($slf, $ctx) = @_;

  $slf->{'_dbh'}->test($ctx);
}

=head2 S<writeLastDb([$rpt,][$min[,$max]])>

This macro writes a line range from the last SQL result to the report file.
It assumes respectively the first and last line as the default for the range
definition. You can use negative line numbers to specify lines from the
buffer end. It returns 1 for a successful completion. Otherwise, it returns 0.

=cut

sub _m_write_last
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_write_last($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_write_last($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_write_last
{ my ($slf, $ctx, $rpt, $min, $max) = @_;
  my ($buf, $rec);

  # Validate the range
  $buf = $slf->{'_sql'};
  $min = (!defined($min) || ($#$buf + $min) < -1) ? 0 :
         ($min < 0) ? $#$buf + $min + 1 :
         $min;
  $max = (!defined($max)) ? $#$buf :
         (($#$buf + $max) < -1) ? 0 :
         ($max < 0) ? $#$buf + $max + 1 :
         $max;

  $rec = [$ctx, $rpt, undef, 0];
  foreach my $lin (@$buf[$min..$max])
  { return 0 if _write_sql($slf, $rec, $lin);
  }
  1;
}

=head2 S<writeDb([$rpt,]$job[,$inc[,$re...]])>

This macro writes the output of the SQL statements in the report file. The
request job is composed of following directives:

=over 4

=item * C<#CALL E<lt>nameE<gt>(E<lt>nE<gt>)>

It executes the specified macro before treating the next directive.

=item * C<#CAPTURE E<lt>nameE<gt>>

It copies the following lines in the named capture buffer. It clears the
capture buffer unless its name is in lower case.

=item * C<#CAPTURE ONLY E<lt>nameE<gt>>

It removes the following lines from the result flow and add them in the named
capture buffer. It clears the capture buffer unless its name is in lower case.

=item * C<#CUT>

It inserts a C<___Cut___> line in the result flow.

=item * C<#ECHO E<lt>strE<gt>>

It inserts the string as a line in the result flow.

=item * C<#END>

It disables any previous line capture.

=item * C<#EXIT>

It disconnects from the database and aborts the job.

=item * C<#LONG(E<lt>nE<gt>)>

It indicates the maximum length of C<LONG> type fields that the driver can
read. It resets the default length at job completion.

=item * C<#MACRO E<lt>nameE<gt>(E<lt>nE<gt>)>

It inserts a C<___Macro_E<lt>nameE<gt>(E<lt>numE<gt>)___> line in the result
flow. Those lines are replaced by the execution of the specified macro with
C<E<lt>numE<gt>> as an argument. A positive return value resets the alarm.

=item * C<#PLSQL> or C<#PLSQLE<lt>nE<gt>>

It extract all lines until it finds a C</> line. It considers them as a PL/SQL
block and inserts its output in the result flow. A number can be included in
the directive to better locate instructions causing timeouts.

=item * C<#QUIT>

It disconnects from the database and aborts the job.

=item * C<#SLEEP(E<lt>nE<gt>)>

It creates a suspension for the specified number of seconds.

=item * C<#SQL> or C<#SQLE<lt>nE<gt>>

It extract all lines until it finds a C</> line. It considers these lines as a
SQL statement and inserts its result in the result flow. A number can be
included in the directive to better locate instructions causing timeouts.

=back

Only lines between C<___Cut___> lines are inserted in the report file.

It is possible to increase the execution limit by specifying an increasing
factor as an argument. A negative value disables timeout.

It returns 1 for a successful completion. If the execution time exceeds the
limit or if the maximum number of attempts has been reached, it returns 0.

=cut

sub _m_write_sql
{ my ($slf, $ctx, $arg, @arg) = @_;
  my ($rpt);

  (ref($arg) =~ $RPT)       ? _s_write_sql($slf, $ctx, $arg, @arg) :
  ($rpt = $ctx->get_report) ? _s_write_sql($slf, $ctx, $rpt, $arg, @arg) :
                              0;
}

sub _s_write_sql
{ my ($slf, $ctx, $rpt, $sql, $inc, @arg) = @_;
  my ($tbl);

  # Get the regular expressions
  foreach my $str (@arg)
  { next unless defined($str);
    $tbl = [] unless ref($tbl);
    push(@$tbl, qr#$str#);
  }

  # Execute the SQL statement
  $slf->{'_dbh'}->execute($ctx, $sql, $inc, \&_write_sql, [$ctx, $rpt, undef,
    $slf->{'_frk'} ? $slf->{'_dbh'}->get_alarm($inc) : 0,
    $tbl, $slf->{'_hit'} = [], $slf->{'_buf'}]);
}

sub _write_sql
{ my ($dbh, $rec, $lin) = @_;

  if ($lin =~ $MAC)
  { my ($val);

    # Suspend alarm
    $dbh->{'dur'} = $rec->[3] ? alarm(0) + 1 : 0;

    # Execute a macro
    $val = RDA::Value::Scalar::new_number($2);
    $val = RDA::Value::List->new($val);
    $val = $rec->[0]->define_operator([$1, '.macro.'], $rec->[0], $1, $val);
    eval {
      $dbh->reset_timeout($val) if ($val = $val->eval_as_number) > 0;
      };

    # Must clear it, to execute a prefix block on next write
    $rec->[2] = undef;

    # Restart the alarm when suspended
    alarm($dbh->{'dur'}) if $dbh->{'dur'};
  }
  elsif ($lin =~ $ERR && $dbh->{'err'})
  { # Generate a SQL error
    die "RDA-00507: SQL Error\n";
  }
  elsif ($lin =~ $BUF)
  { $rec->[7] = lc($2);
    $rec->[8] = $1;
    $rec->[6]->{$rec->[7]} = [] unless $2 eq $rec->[7];
  }
  elsif ($lin =~ $EOC)
  { $rec->[7] = $rec->[8] = undef;
  }
  elsif ($rec->[8])
  { push(@{$rec->[6]->{$rec->[7]}}, $lin);
  }
  else
  { my ($lim);

    # Get the report file handle, with the alarm suspended
    unless ($rec->[2])
    { $lim = $rec->[3] ? alarm(0) + 1 : 0;
      $rec->[2] = $rec->[1]->get_handle;
      alarm($lim) if $lim;
    }

    # Write the line to the report file
    $rec->[1]->write("$lin\n");
    if ($rec->[4])
    { foreach my $re (@{$rec->[4]})
      { if ($lin =~ $re)
        { push(@{$rec->[5]}, $lin);
          last;
        }
      }
    }
    push(@{$rec->[6]->{$rec->[7]}}, $lin) if $rec->[7];
  }

  # Continue the result processing
  0;
}

# --- Internal routines -------------------------------------------------------

# Get the concatenation function
sub _get_concat
{ my ($slf, $ctx) = @_;

  return $slf->{'_cat'} if exists($slf->{'_cat'});
  foreach my $dia ($slf->{'_dbh'}->get_dialects($ctx))
  { return $slf->{'_cat'} = $tb_cat{$dia} if exists($tb_cat{$dia});
  }
  $slf->{'_cat'} = $tb_cat{'?'};
}

# Get the date function
sub _get_date_fmt
{ my ($slf, $ctx) = @_;

  $slf->{'_dbh'}->get_date_fmt(_get_concat($slf, $ctx));
}

# Replace all occurrences of %s
sub _replace
{ my ($str, $val) = @_;

  $str =~ s/\%s/$val/g;
  $str;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>,
L<RDA::Driver::Dbd|RDA::Driver::Dbd>,
L<RDA::Driver::Jdbc|RDA::Driver::Jdbc>,
L<RDA::Driver::Sqlplus|RDA::Driver::Sqlplus>,
L<RDA::Driver::WinOdbc|RDA::Driver::WinOdbc>,
L<RDA::Object::Access|RDA::Object::Access>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
