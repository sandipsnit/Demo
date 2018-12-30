# Db.pm: Class Used for Database Macros

package RDA::Library::Db;

# $Id: Db.pm,v 2.23 2012/05/22 15:54:53 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Db.pm,v 2.23 2012/05/22 15:54:53 mschenke Exp $
#
# Change History
# 20120522  MSC  Improve the database connection.

=head1 NAME

RDA::Library::Db - Class Used for Database Macros

=head1 SYNOPSIS

require RDA::Library::Db;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Db> class are used to interface with
database-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use RDA::Object::Access qw(check_sid);
  use RDA::Object::Buffer;
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.23 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $ALR = "___Alarm___";
my $BUF = qr/^___Capture(_Only)?_(\w+)___$/;
my $CLL = qr/(\!\!call|^#\s*CALL)\s+(\w+)\((\d+)\)\s*$/;
my $CUT = "___Cut___";
my $DSC = "SET TAB OFF\nDESC :1";
my $EOC = qr/^___End_Capture___$/;
my $ERR = qr/^ERROR at line \d+:$/i;
my $EXT = qr/^[^:]+:\d+:{1,2}[^:]+$/;
my $LOG = qr/^((ORA|SP2)-\d{4,}):\s*(.*)/;
my $MAC = qr/^___Macro_(\w+)\((\d+)\)___$/;
my $NET1 =
  '%s(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SID = %s)))%s';
my $NET2 =
  '%s(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SERVICE_NAME = %s)))%s';
my $NET3 =
  '%s(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = %s)(PORT = %s)) '
  .'(CONNECT_DATA = (SERVICE_NAME = %s)'
  .'(INSTANCE_ROLE = ANY)(INSTANCE_NAME = %s)(SERVER = DEDICATED)))%s';
my $RPT = qr/^RDA::Object::(Pipe|Report)$/i;
my $SEP = qr/^___Separator\((\w+)\)___$/;
my $SID = qr/^([^:]+):(\d+):([^:]+)$/;
my $SLP = qr/(\!\!sleep|^#\s*SLEEP)\((\d+)\)\s*$/;
my $SQL = "SELECT data_type || '|' || column_name
 FROM all_tab_columns
 WHERE owner = ':1'
   AND table_name = ':2';";
my $SVC = qr/^([^:]+):(\d+):([^:]*):([^:]+)$/;
my $VMS = qr/^___Set_VMS___$/;
my $WRK = 'db.txt';
my $WRN = qr/^ORA-280(02|11):/;

# Define the global private variables
my %tb_fct = (
  'checkSid'          => [\&_m_check_sid,   'T'],
  'clearLastSql'    => [\&_m_clear_last,    'N'],
  'clearSqlBuffer'  => [\&_m_clear_buffer,  'N'],
  'clearSqlColumns' => [\&_m_clear_columns, 'N'],
  'getSqlBuffer'    => [\&_m_get_buffer,    'O'],
  'getSqlColumns'   => [\&_m_get_columns,   'L'],
  'getSqlDesc'      => [\&_m_get_desc,      'L'],
  'getSqlHits'      => [\&_m_get_hits,      'L'],
  'getSqlLines'     => [\&_m_get_lines,     'L'],
  'getSqlMessage'   => [\&_m_get_message,   'T'],
  'getSqlPrelim'    => [\&_m_get_prelim,    'N'],
  'getSqlTimeout'   => [\&_m_get_timeout,   'N'],
  'grepLastSql'     => [\&_m_grep_last,     'L'],
  'grepSql'         => [\&_m_grep_sql,      'L'],
  'grepSqlBuffer'   => [\&_m_grep_buffer,   'L'],
  'hasSqlPassword'  => [\&_m_has_password,  'N'],
  'isSqlEnabled'    => [\&_m_is_enabled,    'N'],
  'loadSql'         => [\&_m_load_sql,      'N'],
  'resetSqlTimeout' => [\&_m_reset_timeout, 'N'],
  'resolveSid'      => [\&_m_resolve_sid,   'T'],
  'setSqlAccess'    => [\&_m_set_access,    'N'],
  'setSqlColumns'   => [\&_m_set_columns,   'N'],
  'setSqlError'     => [\&_m_set_error,     'N'],
  'setSqlFailure'   => [\&_m_set_failure,   'N'],
  'setSqlHeader'    => [\&_m_set_header,    'N'],
  'setSqlLogin'     => [\&_m_set_login,     'T'],
  'setSqlPrelim'    => [\&_m_set_prelim,    'N'],
  'setSqlSid'       => [\&_m_set_sid,       'T'],
  'setSqlTimeout'   => [\&_m_set_timeout,   'N'],
  'setSqlTrace'     => [\&_m_set_trace,     'N'],
  'setSqlType'      => [\&_m_set_type,      'N'],
  'testSql'         => [\&_m_test_sql,      'T'],
  'writeLastSql'    => [\&_m_write_last,    'N'],
  'writeSql'        => [\&_m_write_sql,     'N'],
  );
my %tb_jus = (
  FLOAT  => 'L',
  NUMBER => 'L',
  );
my %tb_typ = (
  CHAR      => '%s',
  DATE      => 'TO_CHAR(%s,\'DD-Mon-YYYY HH24:MI:SS\')',
  FLOAT     => '%s',
  NCHAR     => '%s',
  NUMBER    => '%s',
  NVARCHAR2 => '%s',
  TIMESTAMP => 'TO_CHAR(%s,\'DD-Mon-YYYY HH24:MI:SSxFF\')',
  VARCHAR2  => '%s',
  );

# Define the Sql*Plus interface
my $BEG = "

set arraysize 4
set define off
set echo off
set feedback off
set heading off
set linesize 1024
set newpage none
set pagesize 20000
set pause off
set sqlprompt RDA>
set timing off
set verify off
prompt $CUT
";
my $END = "prompt $CUT
exit
";

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Db-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Db> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'acc' > > DB access error flag (error outside result section)

=item S<    B<'err' > > SQL error flag (error in result section)

=item S<    B<'frk' > > Fork indicator

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'max' > > Maximum number of SQL script failures

=item S<    B<'trc' > > SQL output trace flag

=item S<    B<'try' > > Number of SQL script failures

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_buf'> > Buffer hash

=item S<    B<'_cur'> > Current login

=item S<    B<'_dba'> > Indicates if the login should be treated as sysdba

=item S<    B<'_dft'> > Default SQL login

=item S<    B<'_dlg'> > Dialog suppression indicator

=item S<    B<'_dsc'> > Table description hash

=item S<    B<'_dur'> > Remaining alarm duration

=item S<    B<'_err'> > Number of SQL request errors

=item S<    B<'_fct'> > Function to execute a SQL request

=item S<    B<'_grp'> > Current password group

=item S<    B<'_hit'> > Lines captured when executing SQL statements

=item S<    B<'_log'> > User name and password to connect

=item S<    B<'_msg'> > Last error message

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of SQL requests timed out

=item S<    B<'_pre'> > C<prelim> connection option

=item S<    B<'_req'> > Number of SQL requests

=item S<    B<'_sid'> > Current Oracle system identifier

=item S<    B<'_skp'> > Number of SQL requests skipped

=item S<    B<'_sql'> > Last SQL result

=item S<    B<'_tgt'> > Reference to the target control object

=item S<    B<'_vms'> > VMS indicator

=item S<    B<'_wrk'> > Reference to the work file manager

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($sid, $slf, $usr);

  # Create the macro object
  $slf = bless {
    acc  => $agt->get_setting('SQL_ACCESS', 0),
    err  => $agt->get_setting('SQL_ERROR', 0),
    frk  => _chk_fork($agt->get_setting('SQL_FORK', 1)),
    lim  => _chk_alarm($agt->get_setting('SQL_TIMEOUT', 30)),
    max  => $agt->get_setting('SQL_ATTEMPTS', 3),
    trc  => $agt->get_setting('SQL_TRACE', 0),
    try  => 0,
    _agt => $agt,
    _buf => {},
    _dba => $agt->get_setting('SQL_SYSDBA', 0),
    _dlg => $agt->get_info('yes'),
    _dsc => {},
    _dur => 0,
    _err => 0,
    _hit => [],
    _not => '',
    _out => 0,
    _pre => $agt->get_setting('SQL_PRELIM') ? '-prelim' : '',
    _req => 0,
    _skp => 0,
    _sql => [],
    _tgt => $agt->get_target,
    _vms => RDA::Object::Rda->is_vms,
    }, ref($cls) || $cls;

  # Check the ORACLE_SID usage
  $usr = $agt->get_setting('SQL_LOGIN', 'SYSTEM');
  $sid = $agt->get_setting('ORACLE_SID', '');
  if ($usr =~ s/\@(\S+)?.*$// && $1)
  { $usr = uc($usr).'@'.check_sid($1);
    $slf->{'_grp'} = $slf->{'_sid'} = '';
  }
  else
  { $usr = uc($usr);
    if ($sid =~ $EXT)
    { $slf->{'_sid'} = $slf->{'_grp'} = check_sid($sid);
    }
    elsif ($agt->get_setting('DATABASE_LOCAL',1))
    { $ENV{'ORACLE_SID'} = $sid if length($sid);
      $slf->{'_grp'} = uc($slf->{'_sid'} = $sid);
    }
    else
    { $usr = uc($usr).'@'.uc($sid);
      $slf->{'_grp'} = $slf->{'_sid'} = '';
    }
  }

  # Determine the default user and initialize the password table
  if ($usr =~ m#^/?(@(.*))?$#) #
  { $slf->{'_dft'} = $2 ? $1 : '';
  }
  else
  { $slf->{'_dft'} = $usr;
  }

  # Determine the request method
  if ($slf->{'frk'})
  { $slf->{'_fct'} = \&_run_sql_fork;
  }
  else
  { $slf->{'_fct'} = \&_run_sql_tmp;
    $slf->{'_wrk'} = $agt;
  }

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(reload stat));

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

  if ($slf->{'_req'})
  { # Get the statistics record
    $use = $slf->{'_agt'}->get_usage;
    $use->{'DB'} = {err => 0, not => '', out => 0, req => 0, skp => 0}
      unless exists($use->{'DB'});
    $use = $use->{'DB'};
    
    # Indicate the current timeout when there is no other note
    $slf->{'_not'} = 'SQL execution limited to '.$slf->{'lim'}.'s'
      unless $use->{'not'} || $slf->{'_not'} || $slf->{'lim'} <= 0;

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

=head2 S<checkSid($sid[,$dft])>

This macro checks the system identifier and returns a normalized string for
password management.

=cut

sub _m_check_sid
{ my ($slf, $ctx, $sid, $dft) = @_;

  check_sid($sid, $dft);
}

=head2 S<clearLastSql()>

This macro clears the last SQL result.

=cut

sub _m_clear_last
{ shift->{'_sql'} = [];
}

=head2 S<clearSqlBuffer([$nam,...])>

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

=head2 S<clearSqlColumns($tid)>

This macro clears all information associated with the specified table
identifier.

=cut

sub _m_clear_columns
{ my ($slf, $ctx, $tid) = @_;

  delete($slf->{'_dsc'}->{$tid}) if $tid;
  0;
}

=head2 S<getSqlBuffer([$nam[,$flg]])>

This macro returns the specified capture buffer or the hit buffer when the name
is undefined. The capture buffer names are not case sensitive. Unless the flag
is set, it assumes Wiki data.

=cut

sub _m_get_buffer
{ my ($slf, $ctx, $nam, $flg) = @_;

  RDA::Object::Buffer->new($flg ? 'L' : 'l',
    defined($nam) ? $slf->{'_buf'}->{lc($nam)} : $slf->{'_hit'});
}

=head2 S<getSqlColumns($tid,$own,$tbl[,@col])>

This macro determines if the specified columns are present in the table and
generates the header string and the select list accordingly. You can provide
specific headers or select contributions through the C<setSqlColumns> and
C<setSqlHeader> macros. RDA supports predefined data types only unless an
explicit select contribution or an extra conversion format is specified. You
can manage the data types list with the C<setSqlType> macro.

When no columns are specified, all table columns are considered.

This macro returns a list containing the corresponding header and select
list. If the table is not found or if the query identifier is missing, then the
header and select list are undefined.

=cut

sub _m_get_columns
{ my ($slf, $ctx, $tid, $own, $tbl, @arg) = @_;
  my ($col, $dsc, $hdr, $jus, $row, $sql, $typ, @hdr, @sel, @tbl);

  # Get the query entry
  return () unless $tid;
  $slf->{'_dsc'}->{$tid} = {} unless exists($slf->{'_dsc'}->{$tid});
  $dsc = $slf->{'_dsc'}->{$tid};

  # Get the table description and reject unknown table
  unless (exists($dsc->{'typ'}))
  { $dsc->{'row'} = [];
    $dsc->{'typ'} = {};
    $tbl = uc($tbl);
    if ($own)
    { $own = uc($own);
      $sql = $SQL;
      $sql =~ s/:1/$own/;
      $sql =~ s/:2/$tbl/;
      &{$slf->{'_fct'}}($slf, $ctx, $sql, 1, undef, \&_desc_sql, [$dsc]);
    }
    else
    { $sql = $DSC;
      $sql =~ s/:1/$tbl/;
      &{$slf->{'_fct'}}($slf, $ctx, $sql, 1, undef, \&_desc_desc, [$dsc]);
    }
  }
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
      exists($tb_jus{$typ}) ? $tb_jus{$typ} :
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
      : _desc_typ($dsc, $col, $typ);
    next unless $col;
    $col = "' ||\n       $col || '";
    $col = " $col" if $jus =~ m/L/;
    $col = "$col " if $jus =~ m/R/;
    push(@sel, $col);
    push(@hdr, $hdr);
  }

  # Return the header and select strings
  (scalar @sel) ? ('|'.join('|', @hdr).'|', "'|".join('|',@sel)."|'") : ();
}

sub _desc_desc
{ my ($slf, $rec, $lin) = @_;
  my ($col, $dsc, $typ);

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL error\n" if $lin =~ $ERR && $slf->{'err'};

  # Store the lines
  $dsc = $rec->[0];
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

sub _desc_sql
{ my ($slf, $rec, $lin) = @_;
  my ($col, $dsc, $typ);

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL error\n" if $lin =~ $ERR && $slf->{'err'};

  # Store the lines
  $dsc = $rec->[0];
  ($typ, $col) = split(/\|/, $lin, 2);
  $col = lc($col);
  push(@{$dsc->{'row'}}, $col);
  $dsc->{'typ'}->{$col} = $typ;

  # Continue the search
  0;
}

sub _desc_typ
{ my ($dsc, $col, $typ) = @_;

  exists($dsc->{'fmt'}->{$typ}) ? sprintf($dsc->{'fmt'}->{$typ}, $col) :
  exists($tb_typ{$typ}) ? sprintf($tb_typ{$typ}, $col) :
  '';
}

=head2 S<getSqlDesc($tid,$col[,$flg])>

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
        : _desc_typ($dsc, $nam, $dsc->{'typ'}->{$nam});
      next unless $val;
    }

    # Check the column
    ++$cnt;
    return ($cnt, $dsc->{'typ'}->{$col}) if $col eq $nam;
  }

  # Indicate that the column has not been found
  ();
}

=head2 S<getSqlHits()>

This macro returns the list of lines captured during the last C<writeSql>.

=cut

sub _m_get_hits
{ @{shift->{'_hit'}};
}

=head2 S<getSqlLines([$min[,$max]])>

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

=head2 S<getSqlMessage()>

This macro returns the error message of the last SQL execution. If no error is
detected, it returns C<undef>.

=cut

sub _m_get_message
{ my ($slf) = @_;

  exists($slf->{'_msg'}) ? $slf->{'_msg'} : undef;
}

=head2 S<getSqlPrelim()>

This macro indicates whether the C<prelim> option is set.

=cut

sub _m_get_prelim
{ shift->{'_pre'} ? 1 : 0;
}

=head2 S<getSqlTimeout()>

This macro returns the current duration of the SQL timeout. If this mechanism
is disabled, it returns 0.

=cut

sub _m_get_timeout
{ shift->{'lim'};
}

=head2 S<grepLastSql($re,$opt)>

This macro returns the lines of the last SQL result that match the regular
expression. It supports the same options as C<grepSql>.

=cut

sub _m_grep_last
{ my ($slf, $ctx, $re, $opt) = @_;

  _grep_buffer($slf->{'_sql'}, $re, $opt);
}

=head2 S<grepSql($sql,$re,$opt)>

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
  &{$slf->{'_fct'}}($slf, $ctx, $sql, 1, undef, \&_grep_sql,
    [$re, \@tbl, $inv, $one]) if $re;
  @tbl;
}

sub _grep_sql
{ my ($slf, $rec, $lin) = @_;
  my $flg;

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL error\n" if $lin =~ $ERR && $slf->{'err'};

  # Check if the line matches the pattern
  $flg = ($lin =~ $rec->[0]);
  if ($rec->[2] ? !$flg : $flg)
  { push(@{$rec->[1]}, $lin);
    return $rec->[3];
  }

  # Continue the search
  0;
}

=head2 S<grepSqlBuffer($name,$re,$opt)>

This macro returns the lines of the specified capture buffer that match the
regular expression. It supports the same options as C<grepSql>.

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

=head2 S<hasSqlPassword($usr[,$sid])>

This macro indicates whether a password hash entry exists for the specified
user already. You can provide an alternative Oracle system identifier as the
second argument.

=cut

sub _m_has_password
{ my ($slf, $ctx, $usr, $sid) = @_;

  return 0 unless $usr;

  # Determine user and SID parts
  $usr = uc($usr);
  ($usr, $sid) = ($1, $2) if $usr =~ m/^([^@]*)@(\S+)/;
  $sid = check_sid($sid, $slf->{'_grp'});
  
  # Indicate if a password has been provided for that user
  $ctx->get_access->has_password('oracle', $sid, $usr);
}

=head2 S<isSqlEnabled()>

This macro indicates whether a SQL statement will be executed.

=cut

sub _m_is_enabled
{ my ($slf) = @_;

  $slf->{'try'} < $slf->{'max'};
}

=head2 S<loadSql($sql,$flg[,$inc])>

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
  &{$slf->{'_fct'}}($slf, $ctx, $sql, $inc, undef, \&_load_sql,
    [$ctx, $slf->{'_sql'}]);
}

sub _load_sql
{ my ($slf, $rec, $lin) = @_;

  # Interrupt when a SQL error is encountered
  die "RDA-00507: SQL error\n" if $lin =~ $ERR && $slf->{'err'};

  # Save the line in the last SQL result
  push(@{$rec->[1]}, $lin);

  # Continue the result processing
  0;
}

=head2 S<resetSqlTimeout([$inc])>

This macro resets the remaining alarm time to the SQL timeout value. To allow
more time for executing statements, you can specify a factor as an argument. 1
is the default. For a positive value, the maximum execution time is obtained by
multiplying the SQL timeout value by this factor. Otherwise, it disables the
alarm mechanism.

The effective value is returned.

=cut

sub _m_reset_timeout
{ my ($slf, $ctx, $inc) = @_;

  $slf->{'_dur'} = $slf->_get_alarm($inc);
}

=head2 S<resolveSid($sid)>

This macro transforms the system identifier in a connect string.

=cut

sub _m_resolve_sid
{ my ($slf, $ctx, $sid) = @_;

  ($sid =~ $SID) ? sprintf($NET1, '', $1, $2, $3, '') :
  ($sid !~ $SVC) ? $sid :
  length($3)     ? sprintf($NET3, '', $1, $2, $4, $3, '') :
                   sprintf($NET2, '', $1, $2, $4, '');
}

=head2 S<setSqlAccess($flag)>

This macro manages the access/connect error flag. When the flag is set, it
generates an error when an access/connect error is detected.

It returns the previous value of the flag.

=cut

sub _m_set_access
{ my ($slf, $ctx, $flg) = @_;

  ($slf->{'acc'}, $flg) = ($flg, $slf->{'acc'});
  $flg;
}

=head2 S<setSqlColumns($tid[,$col1,$val1...])>

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

=head2 S<setSqlError($flag)>

This macro manages the SQL error flag. When the flag is set, it generates an
error when a SQL error is detected.

It returns the previous value of the flag.

=cut

sub _m_set_error
{ my ($slf, $ctx, $flg) = @_;

  ($slf->{'err'}, $flg) = ($flg, $slf->{'err'});
  $flg;
}

=head2 S<setSqlFailure($cnt)>

This macro manages the number of SQL script failures. A negative value disables
any further database connection.

It returns the previous value of the counter.

=cut

sub _m_set_failure
{ my ($slf, $ctx, $cnt) = @_;

  $cnt = 0 unless defined($cnt);
  $cnt = $slf->{'max'} if $cnt < 0;

  ($slf->{'try'}, $cnt) = ($cnt, $slf->{'try'});
  $cnt;
}

=head2 S<setSqlHeader($tid[,$col1,$val1...])>

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

=head2 S<setSqlLogin([$user[,$password[,$sid[,$dba]]]])>

This macro specifies the login information to use for running SQL statements.
When the password is not specified, it is asked interactively at the first
statement execution. By default, the user is derived from the C<SQL_LOGIN>
variable. You can specify an alternative system identifier as a third argument.

It returns the previous user using the same conventions.

=cut

sub _m_set_login
{ my ($slf, $ctx, $usr, $pwd, $sid, $dba) = @_;
  my ($suf, $old);

  $old = exists($slf->{'_cur'}) ? $slf->{'_cur'} : undef;
  if (defined($usr))
  { # Set the new current user
    if ($usr =~ s/\@(\S*)?(\s+AS\s+SYSDBA)?\s*$//i)
    { $sid = check_sid($1) if $1;
      $dba = 1             if $2;
    }
    $usr = uc($usr);
    $suf = '';
    unless ($usr =~ m/\@/)
    { $suf .= $sid         if ($sid = check_sid($sid));
      $suf .= ' AS SYSDBA' if $dba;
    }
    $slf->{'_cur'} = $suf ? "$usr\@$suf" : $usr;

    # Manage the password
    if (defined($pwd))
    { $pwd =~ s/\r\n//g;
      if ($usr =~ m/^([^@]*)@(\S+)/)
      { $usr = $1;
        $sid = check_sid($2);
      }
      else
      { $usr = $1 if $usr =~ m/^([^@]*)@/;
        $sid = $slf->{'_grp'} unless $sid;
      }
      $ctx->get_access->set_password('oracle', $sid, $usr, $pwd);
    }
  }
  else
  { delete($slf->{'_cur'});
  }
  delete($slf->{'_log'});
  $old;
}

=head2 S<setSqlPrelim($flag)>

This macro controls the C<prelim> option. When the flag is set, it activates
the option. Otherwise, it removes the option.

It returns the previous status.

=cut

sub _m_set_prelim
{ my ($slf, $ctx, $flg) = @_;

  $flg = $flg ? '-prelim' : '';
  ($slf->{'_pre'}, $flg) = ($flg, $slf->{'_pre'});
  $flg ? 1 : 0;
}

=head2 S<setSqlSid($sid)>

This macro switches the database context to the specified Oracle system
identifier. When an empty string is provided, the C<ORACLE_SID> environment
variable is removed. It returns the previous system identifier.

=cut

sub _m_set_sid
{ my ($slf, $ctx, $sid) = @_;
  my ($old);

  $old = $slf->{'_sid'};
  if (defined($sid) && $sid ne $old)
  { # Change the database context
    
    if (!length($sid))
    { delete($ENV{'ORACLE_SID'});
      $slf->{'_sid'} = $slf->{'_grp'} = $sid;
    }
    elsif ($sid =~ $EXT)
    { $slf->{'_sid'} = $slf->{'_grp'} = check_sid($sid);
    }
    else
    { $ENV{'ORACLE_SID'} = $slf->{'_sid'} = $sid;
      $slf->{'_grp'} = uc($sid);
    }
  }
  $old;
}

=head2 S<setSqlTimeout($sec)>

This macro sets the SQL timeout, specified in seconds, only if the value is
greater than zero. Otherwise, the timeout mechanism is disabled. It is disabled
also if the alarm function is not implemented.

It returns the effective value.

=cut

sub _m_set_timeout
{ my ($slf, $ctx, $val) = @_;

  $slf->{'lim'} = _chk_alarm($val);
}

=head2 S<setSqlTrace([$flag])>

This macro manages the SQL trace flag. When the flag is set, it prints all SQL
lines to the screen. It remains unchanged if the flag value is undefined.

It returns the previous value of the flag.

=cut

sub _m_set_trace
{ my ($slf, $ctx, $flg) = @_;

  ($slf->{'trc'}, $flg) = ($flg, $slf->{'trc'});
  $flg;
}

=head2 S<setSqlType($tid[,$typ1,$fmt1...])>

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

=head2 S<testSql()>

This macro tests the database connection. In case of problems, further access
is disabled.

=cut

sub _m_test_sql
{ my ($slf, $ctx) = @_;
  my ($old, $sql, @buf);

  # Test the database connection
  $slf->{'try'} = 0;
  $slf->{'_not'} = '';
  $sql = "SELECT 'X' FROM sys.dual;";
  delete($slf->{'_msg'});
  return '' if &{$slf->{'_fct'}}($slf, $ctx, $sql, 1, undef, \&_test_sql,
    [$ctx, \@buf]) && (scalar @buf) && $buf[0] eq 'X';

  if (exists($ENV{'INITIAL_HOME'}))
  { $old = $ENV{'ORACLE_HOME'};
    @buf = ();
    $ENV{'ORACLE_HOME'} = $ENV{'INITIAL_HOME'};
    delete($slf->{'_msg'});
    return '' if &{$slf->{'_fct'}}($slf, $ctx, $sql, 1, undef, \&_test_sql,
      [$ctx, \@buf]) && (scalar @buf) && $buf[0] eq 'X';
    $ENV{'ORACLE_HOME'} = $old;
  }

  ++$slf->{'_err'};
  $slf->{'_not'} = 'No database access in the last run';

  # Disable further access to the database
  $slf->{'try'} = $slf->{'max'};
  return 'RDA-00501: Database access disabled due to a connection problem';
}

sub _test_sql
{ my ($slf, $rec, $lin) = @_;

  # Interrupt when a SQL error is encountered
  if ($lin =~ $LOG)
  { $slf->{'_msg'} = $lin;
    return 1;
  }

  # Save the line in the last SQL result
  push(@{$rec->[1]}, $lin);

  # Continue the result processing
  0;
}

=head2 S<writeLastSql([$rpt,][$min[,$max]])>

This macro writes a line range from the last SQL result to the report file.
It assumes the first and last line respectively as the default for the range
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

=head2 S<writeSql([$rpt,]$sql[,$inc[,$re...]])>

This macro writes the output of the SQL statements in the report file. It
returns 1 for a successful completion. If the execution time exceeds the limit
or if the maximum number of attempts has been reached, it returns 0.

Only lines between C<___Cut___> lines are inserted in the report file.

Some special lines are identified:

=over 4

=item *

Lines like C<___Separator(E<lt>nameE<gt>)___> are replaced by the lines
contained in the corresponding array variable C<@E<lt>nameE<gt>>.

=item *

Lines like C<___Macro_E<lt>nameE<gt>(E<lt>numE<gt>)___> are replaced by the
execution of the specified macro with C<E<lt>numE<gt>> as an argument. A
positive return value resets the alarm.

=item *

Lines like C<___Capture_E<lt>nameE<gt>___> indicate that the following lines
are copied to the named capture buffer. They clear the capture buffer unless
their name is in lower case.

=item *

Lines like C<___Capture_Only_E<lt>nameE<gt>___> indicate that the following
lines are removed from the result flow and added to the named capture
buffer. They clear the capture buffer unless their name is in lower case.

=item *

Lines like C<___End_Capture___> disable any previous line capture.

=back

You can insert input pauses with lines like C<!!sleep(E<lt>nE<gt>)>.

It is possible to increase the execution limit by specifying an increasing
factor as an argument. A negative value disables timeout.

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
  $slf->{'_hit'} = [];
  foreach my $str (@arg)
  { next unless defined($str);
    $tbl = [] unless ref($tbl);
    push(@$tbl, qr#$str#);
  }

  # Execute the SQL statement
  &{$slf->{'_fct'}}($slf, $ctx, $sql, $inc, $tbl, \&_write_sql,
    [$ctx, $rpt, undef, $slf->{'frk'} ? $slf->_get_alarm($inc) : 0, $tbl]);
}

sub _write_sql
{ my ($slf, $rec, $lin) = @_;

  if ($lin =~ $MAC)
  { my ($val);

    # Suspend alarm
    $slf->{'_dur'} = $rec->[3] ? alarm(0) + 1 : 0;

    # Execute a macro
    $val = RDA::Value::Scalar::new_number($2);
    $val = RDA::Value::List->new($val);
    $val = $rec->[0]->define_operator([$1, '.macro.'], $rec->[0], $1, $val);
    eval {
      _m_reset_timeout($slf, undef, $val) if ($val = $val->eval_as_number) > 0;
      };

    # Must clear it, to execute a prefix block on next write
    $rec->[2] = undef;

    # Restart the alarm when suspended
    alarm($slf->{'_dur'}) if $slf->{'_dur'};
  }
  elsif ($lin =~ $ERR && $slf->{'err'})
  { # Generate a SQL error
    die "RDA-00507: SQL error\n";
  }
  elsif ($lin =~ $BUF)
  { $rec->[5] = lc($2);
    $rec->[6] = $1;
    $slf->{'_buf'}->{$rec->[5]} = [] unless $2 eq $rec->[5];
  }
  elsif ($lin =~ $EOC)
  { $rec->[5] = $rec->[6] = undef;
  }
  elsif ($rec->[6])
  { push(@{$slf->{'_buf'}->{$rec->[5]}}, $lin);
  }
  else
  { my ($lim, $val);

    # Get the report file handle, with the alarm suspended
    unless ($rec->[2])
    { $lim = $rec->[3] ? alarm(0) + 1 : 0;
      $rec->[2] = $rec->[1]->get_handle;
      alarm($lim) if $lim;
    }

    # Write the line to the report file
    if ($lin =~ $SEP)
    { $val = $rec->[0]->get_context->get_value("\@$1");
      foreach my $txt ($val->eval_as_array)
      { $rec->[1]->write("$txt\n") if defined($txt);
      }
    }
    else
    { $rec->[1]->write("$lin\n");
      if ($rec->[4])
      { foreach my $pat (@{$rec->[4]})
        { if ($lin =~ $pat)
          { push(@{$slf->{'_hit'}}, $lin);
            last;
          }
        }
      }
      push(@{$slf->{'_buf'}->{$rec->[5]}}, $lin) if $rec->[5];
    }
  }

  # Continue the result processing
  0;
}

# --- Internal routines -------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0)};
  $@ ? 0 : $lim;
}

# Check if fork is allowed and implemented
sub _chk_fork
{ my ($flg) = @_;

  if ($flg && !RDA::Object::Rda->is_windows && !RDA::Object::Rda->is_vms)
  { eval {
      my $pid;

      die "No fork\n" unless defined($pid = fork());
      exit(0) unless $pid;
      waitpid($pid, 0);
    };
    return 1 unless $@;
  }
  0;
}

# Convert a job directive
sub _conv_job
{ my ($lin) = @_;

  ($lin =~ qr/^(EXIT|QUIT)\s*$/)     ? "$1\n" :
  ($lin =~ qr/^CAPTURE\s+ONLY\s+(\w+)\s*$/)
                                     ? "PROMPT ___Capture_Only_$1___\n" :
  ($lin =~ qr/^CAPTURE\s+(\w+)\s*$/) ? "PROMPT ___Capture_$1___\n" :
  ($lin =~ qr/^CUT\s*$/)             ? "PROMPT ___Cut___\n" :
  ($lin =~ qr/^DESC (.*)$/)          ? "PROMPT ___Tag_DESC $1___\nDESC $1\n" :
  ($lin =~ qr/^ECHO(.*)$/)           ? "PROMPT$1\n" :
  ($lin =~ qr/^END\s*$/)             ? "PROMPT ___End_Capture___\n" :
  ($lin =~ qr/^LONG\((\d+)\)\s*$/)   ? "SET long $1\n" :
  ($lin =~ qr/^MACRO\s+(\w+)\((\d+)\)\s*$/) ? "PROMPT ___Macro_$1($2)___\n" :
  ($lin =~ qr/^SET\s(\w+)\s*$/)      ? "PROMPT ___Set_$1___\n" :
  '';
}

# Get the alarm duration
sub _get_alarm
{ my ($slf, $val) = @_;

  return $slf->{'lim'} unless defined($val);
  return 0 unless $slf->{'lim'} > 0 && $val > 0;
  $val *= $slf->{'lim'};
  ($val > 1) ? int($val) : 1;
}

# Get the login information
sub _get_login
{ my ($slf, $ctx) = @_;
  my ($acc, $grp, $nam, $pwd, $sid, $str, $suf, $usr);

  # Determine the user
  $acc = $ctx->get_access;
  $grp = $slf->{'_grp'};
  $sid = $slf->{'_sid'};
  $str = $suf = '';
  if (exists($slf->{'_cur'}))
  { $usr = $nam = $slf->{'_cur'};
    if ($nam =~ m/^(.*)\@(\S+)(.*)$/)
    { ($usr, $sid, $suf, $str) = ($1, $2, $3, $3);
      ($grp, $str) = (check_sid($sid), "\@$sid$suf") if $sid ne $slf->{'_sid'};
    }
    elsif ($nam =~ m/^(.*)\@(.*)$/)
    { ($usr, $suf, $str) = ($1, $2, $2);
    }
    $suf = ($sid =~ $SID) ? sprintf($NET1, '@', $1, $2, $3, $suf) :
           ($sid !~ $SVC) ? $str :
           length($3)     ? sprintf($NET3, '@', $1, $2, $4, $3, $suf) :
                            sprintf($NET2, '@', $1, $2, $4, $suf);
  }
  else
  { $usr = $nam = $slf->{'_dft'};
    if ($nam =~ m/^(.*)\@(\S+)(.*)$/)
    { ($usr, $sid, $suf, $str) = ($1, $2, $3, $3);
      ($grp, $str) = (check_sid($sid), "\@$sid$suf") if $sid ne $slf->{'_sid'};
    }
    elsif ($nam =~ m/^(.*)(\@.*)$/)
    { ($usr, $suf, $str) = ($1, $2, $2);
    }
    $suf = ($sid =~ $SID) ? sprintf($NET1, '@', $1, $2, $3, $suf) :
           ($sid !~ $SVC) ? $str :
           length($3)     ? sprintf($NET3, '@', $1, $2, $4, $3, $suf) :
                            sprintf($NET2, '@', $1, $2, $4, $suf);
    if ($slf->{'_dba'})
    { $str .= ' as SYSDBA';
      $suf .= ' as sysdba';
    }
  }

  # Get the password
  $pwd = $acc->get_password('oracle', $grp, $usr,
    "Enter the password for '$usr$str': ", $slf->{'_dlg'} ? '?' : undef);
  die "RDA-00508: Null password given; logon denied\n"
    unless defined($pwd);

  # Create the login string
  $slf->{'_log'} = "$usr/$pwd$suf";
}

# Log a timeout event
sub _log_timeout
{ my $slf = shift;
  my $ctx = shift;

  ++$slf->{'try'};
  $slf->{'_agt'}->log_timeout($ctx, 'SQL', @_);
  $slf->{'_msg'} = 'RDA-00502: Database connection timeout';
  ++$slf->{'_out'};
}

# Execute SQL code (fork method)
sub _run_sql_fork
{ my ($slf, $ctx, $sql, $inc, $tbl, $fct, $rec) = @_;
  my ($buf, $blk, $end, $err, $lim, $lin, $pid1, $pid2, $trc, $vms);

  # Abort when SQL is missing or when the number of tries have been reached
  ++$slf->{'_req'};
  unless ($sql)
  { $slf->{'_msg'} = 'RDA-00509: Missing SQL code';
    ++$slf->{'_err'};
    return 0;
  }
  unless ($slf->{'try'} < $slf->{'max'})
  { $slf->{'_msg'} = 'RDA-00510: SQL execution disabled';
    ++$slf->{'_skp'};
    return 0;
  }

  # Delete the previous error message
  delete($slf->{'_msg'});

  # Get the login information
  $slf->_get_login($ctx) unless exists($slf->{'_log'});

  # Run the SQL code in a limited execution time
  $lim = $slf->_get_alarm($inc);
  if ($trc = $slf->{'trc'})
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
    die "RDA-00504: Cannot fork:\n $!\n" unless defined($pid1 = fork());
    unless ($pid1)
    { close(IN1);
      $lin = $slf->{'_log'}.$BEG;
      syswrite(OUT1, $lin, length($lin));
      foreach $lin (split(/\n/, $sql))
      { if ($lin =~ $SLP)
        { sleep($2);
        }
        elsif ($lin =~ $CLL)
        { my $val;

          $val = RDA::Value::Scalar::new_number($3);
          $val = RDA::Value::List->new($val);
          $val = $ctx->define_operator([$2, '.macro.'], $ctx, $2, $val);
          $val->eval_value;
        }
        elsif ($lin =~ s/^#\s*//)
        { my $lgt;

          $lin = _conv_job($lin);
          syswrite(OUT1, $lin, $lgt) if ($lgt = length($lin));
        }
        else
        { $lin .= "\n";
          syswrite(OUT1, $lin, length($lin));
        }
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

      ($cmd, $env) = $slf->{'_tgt'}->get_current->get_sqlplus;
      foreach my $key (keys(%$env))
      { if (defined($val = $env->{$key}))
        { $ENV{$key} = $val;
        }
        elsif (exists($ENV{$key}))
        { delete($ENV{$key});
        }
      }
      @opt = ('-s');
      push(@opt, $slf->{'_pre'}) if $slf->{'_pre'};
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
    my ($cat, $flg, $hit, $lin, $skp);
    $skp = $cat = $end = $flg = $vms = 0;
    $hit = $slf->{'_hit'};
    while (<IN2>)
    { s/[\s\r\n]+$//;
      print "SQL> $_\n" if $trc;
      if (m/^$CUT$/)
      { $flg = !$flg;
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
        $slf->{'_msg'} = $_;
        $end = 1;
        last;
      }
      elsif ($tbl)
      { foreach my $re (@$tbl)
        { if ($_ =~ $re)
          { push(@$hit, $_);
            last;
          }
        }
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
    { ++$slf->{'_err'};
      die $err;
    }
    $slf->_log_timeout($ctx);
    return 0;
  }

  # Terminate the output treatment
  exists($slf->{'_msg'}) ? 0 : 1;
}

# Execute SQL code (using a temporary file)
sub _run_sql_tmp
{ my ($slf, $ctx, $sql, $inc, $tbl, $fct, $rec) = @_;
  my ($cmd, $env, $err, $lim, $lin, $pid, $tmp, $trc, $val, $vms, %bkp);

  # Abort when SQL is missing or when the number of tries have been reached
  ++$slf->{'_req'};
  unless ($sql)
  { $slf->{'_msg'} = 'RDA-00509: Missing SQL code';
    ++$slf->{'_err'};
    return 0;
  }
  unless ($slf->{'try'} < $slf->{'max'})
  { $slf->{'_msg'} = 'RDA-00510: SQL execution disabled';
    ++$slf->{'_skp'};
    return 0;
  }

  # Delete the previous error message
  delete($slf->{'_msg'});

  # Get the login information
  $slf->_get_login($ctx) unless exists($slf->{'_log'});

  # Run the SQL code in a limited execution time
  $lim = $slf->_get_alarm($inc);
  $tmp = $slf->{'_wrk'}->get_output->get_work($WRK, 1);
  $vms = $slf->{'_vms'};
  if ($trc = $slf->{'trc'})
  { for (split(/\n/, $sql))
    { print "SQL: $_\n";
    }
  }
  eval {
    local $SIG{'__WARN__'} = sub {};
    local $SIG{'ALRM'}     = sub { die "$ALR\n" } if $lim;
    local $SIG{'PIPE'}     = sub { die "$ALR\n" } if $lim;

    # Limit its execution to prevent RDA hangs
    alarm($lim) if $lim;

    # Execute SQL*Plus
    ($cmd, $env) = $slf->{'_tgt'}->get_current->get_sqlplus;
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
    ($pid = open(OUT, '| '.$cmd.' -s '.$slf->{'_pre'}
      .' >'.RDA::Object::Rda->quote($tmp)
      .' 2>&1')) or die "RDA-00505: Cannot launch SQL*Plus:\n $!\n";
    $lin = $slf->{'_log'}.$BEG;
    syswrite(OUT, $lin, length($lin));
    foreach $lin (split(/\n/, $sql))
    { if ($lin =~ $SLP)
      { sleep($2);
      }
      elsif ($lin =~ $CLL)
      { my $val;

        $val = RDA::Value::Scalar::new_number($3);
        $val = RDA::Value::List->new($val);
        $val = $ctx->define_operator([$2, '.macro.'], $ctx, $2, $val);
        $val->eval_value;
      }
      elsif ($lin =~ s/^#\s*//)
      { my $lgt;

        $lin = _conv_job($lin);
        syswrite(OUT, $lin, $lgt) if ($lgt = length($lin));
      }
      else
      { $lin .= "\n";
        syswrite(OUT, $lin, length($lin));
      }
    }
    syswrite(OUT, $END, length($END));
    waitpid($pid,0);

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
      my ($cat, $flg, $hit, $lin, $skp);
      $cat = $flg = 0;
      $hit = $slf->{'_hit'};
      $skp = $vms;
      while (<IN>)
      { s/[\s\r\n]+$//;
        print "SQL> $_\n" if $trc;
        if (m/^$CUT$/)
        { $flg = !$flg;
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
          $slf->{'_msg'} = $_;
          last;
        }
        elsif ($tbl)
        { foreach my $re (@$tbl)
          { if ($_ =~ $re)
            { push(@$hit, $_);
              last;
            }
          }
        }
      }
    };
    $err = $@ if $@;
    close(IN);
    $slf->{'_wrk'}->get_output->clean_work($WRK);
  }

  # Detect and treat interrupts
  if ($err)
  { unless ($err =~ m/^$ALR\n/)
    { ++$slf->{'_err'};
      die $err;
    }
    $slf->_log_timeout($ctx);
    return 0;
  }

  # Terminate the output treatment
  exists($slf->{'_msg'}) ? 0 : 1;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Access|RDA::Object::Access>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
