# Jdbc.pm: Class Used for Database Requests Using JDBC

package RDA::Driver::Jdbc;

# $Id: Jdbc.pm,v 1.22 2012/05/14 13:18:13 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/Jdbc.pm,v 1.22 2012/05/14 13:18:13 mschenke Exp $
#
# Change History
# 20120514  MSC  Improve null login test.

=head1 NAME

RDA::Driver::Jdbc - Class Used for Database Requests Using JDBC

=head1 SYNOPSIS

require RDA::Driver::Jdbc;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::Jdbc> class are used to interface a
database using JDBC.

The timeout mechanism is only effective for UNIX systems.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::Handle;
  use IO::File;
  use RDA::Object::Java;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.22 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the JDBC interface
my $NAM = 'RdaJdbc';
my $VER = '1.3';
my $COD = <<EOF;
import java.io.*;
import java.lang.*;
import java.sql.*;
import java.util.*;
import java.util.regex.*;

class $NAM
{// Define the common variables
 private static Connection dbh;  // Connection handle

 // Define the common constants
 private final static String DBA = "DBA";
 private final static String DRV = "DRV";
 private final static String EOL = System.getProperty("line.separator");
 private final static String LIM = "LIM";
 private final static String PWD = "PWD";
 private final static String URL = "URL";
 private final static String USR = "USR";
 private final static String WRK = "WRK";

 // Default contructor
 public $NAM()
 {
 }

 // Disconnect from the database
 private static boolean disconnect()
 {try
  {dbh.close();
  }
  catch (Exception err)
  {
  }
  return true;
 }

 // Execute a CONNECT request
 private static boolean doConnect(PrintStream ofh, Hashtable ctx)
 {try
  {if (ctx.containsKey(LIM))
   {Integer lim = new Integer((String) ctx.get(LIM));
    DriverManager.setLoginTimeout(lim.intValue());
   }
   DriverManager.registerDriver(
     ((java.sql.Driver) Class.forName((String) ctx.get(DRV)).newInstance()));
   Properties prp = new Properties();
   prp.put("user", (String) ctx.get(USR));
   prp.put("password", (String) ctx.get(PWD));
   if (ctx.containsKey(DBA))
    prp.put("internal_logon", (String) ctx.get(DBA));
   dbh = DriverManager.getConnection((String) ctx.get(URL), prp);
   dbh.setAutoCommit(false);
  }
  catch (Exception err)
  {System.err.println("CONNECT exception: " + err.toString());
   return true;
  }
  return false;
 }

 // Execute a DESC request
 private static boolean doDesc(PrintStream ofh, String dat, Hashtable ctx)
 {try
  {Statement sth = dbh.createStatement();
   if (ctx.containsKey(LIM))
   {Integer lim = new Integer((String) ctx.get(LIM));
    sth.setQueryTimeout(lim.intValue());
   }
   ResultSet res = sth.executeQuery("SELECT * FROM " + dat);
   ResultSetMetaData dsc = res.getMetaData();
   int max = dsc.getColumnCount();
   for (int i = 1; i <= max; i++ )
    ofh.println(dsc.getColumnName(i) + "|" +
                dsc.getColumnTypeName(i) + "|" + 
                dsc.getColumnType(i) + "|");
   sth.close();
  }
  catch (SQLException err)
  {String msg = err.getMessage();
   if (msg.startsWith("ORA-01013:") || msg.indexOf("timeout") >= 0)
   {System.err.println("DESC timeout");
    return disconnect();
   }
   printMessage(ofh, "describe", msg);
  }
  catch (Exception err)
  {System.err.println("DESC exception: " + err.toString());
   return disconnect();
  }
  return false;
 }

 // Execute a META request
 private static boolean doMeta(PrintStream ofh, Hashtable ctx)
 {try
  {DatabaseMetaData dsc = dbh.getMetaData();

   // Get the database provider
   ofh.println("-nam='" + dsc.getDatabaseProductName() + "'");

   // Get the database version
   String str = dsc.getDatabaseProductVersion();
   Matcher pat = Pattern.compile("(\\\\d+(\\\\.\\\\d+)+)").matcher(str);
   if (pat.find())
    ofh.println("-ver='" + pat.group(1) + "'");
  }
  catch (SQLException err)
  {String msg = err.getMessage();
   if (msg.startsWith("ORA-01013:") || msg.indexOf("timeout") >= 0)
   {System.err.println("META timeout");
    return disconnect();
   }
   printMessage(ofh, "meta", msg);
  }
  catch (Exception err)
  {System.err.println("META exception: " + err.toString());
   return disconnect();
  }
  return false;
 }

 // Execute a PLSQL request
 private static boolean doPlSql(PrintStream ofh, String dat, Hashtable ctx)
 {try
  {CallableStatement blk;

   // Enable dbms_output
   blk = dbh.prepareCall("begin dbms_output.enable(1000000); end;");
   blk.execute();

   // Execute the PL/SQL block
   blk = dbh.prepareCall(dat);
   if (ctx.containsKey(LIM))
   {Integer lim = new Integer((String) ctx.get(LIM));
    blk.setQueryTimeout(lim.intValue());
   }
   blk.execute();

   // Retrieve the block output
   int sta = 0;
   blk = dbh.prepareCall("{call sys.dbms_output.get_line(?,?)}");
   blk.registerOutParameter(1,java.sql.Types.VARCHAR);
   blk.registerOutParameter(2,java.sql.Types.NUMERIC);
   while (true)
   {blk.execute();
    sta = blk.getInt(2);
    if (sta != 0)
     break;
    ofh.println(blk.getString(1));
   }
  }
  catch (SQLException err)
  {String msg = err.getMessage();
   if (msg.startsWith("ORA-01013:") || msg.indexOf("timeout") >= 0)
   {System.err.println("PL/SQL timeout");
    return disconnect();
   }
   printMessage(ofh, "PL/SQL", err);
  }
  catch (Exception err)
  {System.err.println("PLSQL Exception: " + err.toString());
   return disconnect();
  }
  return false;
 }

 // Execute an SQL request
 private static boolean doSql(PrintStream ofh, String dat, Hashtable ctx)
 {try
  {Statement sth = dbh.createStatement();
   if (ctx.containsKey(LIM))
   {Integer lim = new Integer((String) ctx.get(LIM));
    sth.setQueryTimeout(lim.intValue());
   }
   try
   {ResultSet res = sth.executeQuery(dat);
    int max = res.getMetaData().getColumnCount();
    while (res.next())
    {StringBuffer buf = new StringBuffer();
     for (int i = 0 ; i < max ; )
     {if (i++ > 0)
       buf.append("|");
      buf.append(res.getString(i));
     }
     ofh.println(buf.toString());
    }
   }
   catch (SQLException err)
   {String msg = err.getMessage();
    if (msg.startsWith("ORA-01013:") || msg.indexOf("timeout") >= 0)
    {System.err.println("SQL timeout");
     return disconnect();
    }
    printMessage(ofh, "SQL", err);
   }
   sth.close();
  }
  catch (Exception err)
  {System.err.println("SQL exception: " + err.toString());
   return disconnect();
  }
  return false;
 }

 // Execute a request
 private static boolean execRequest(String cmd, String dat, Hashtable ctx)
 {boolean flg = false;

  // Detect an exit request
  if ("QUIT".equals(cmd))
   return true;

  // Treat other requests
  try
  {// Create and open the output file
   String wrk = (String) ctx.get(WRK);
   File fil = new File(wrk);
   fil.createNewFile();
   PrintStream ofh = new PrintStream(new FileOutputStream(fil));

   // Process the request
   if ("CONNECT".equals(cmd))
    flg = doConnect(ofh, ctx);
   else if ("DESC".equals(cmd))
    flg = doDesc(ofh, dat, ctx);
   else if ("META".equals(cmd))
    flg = doMeta(ofh, ctx);
   else if ("PLSQL".equals(cmd))
    flg = doPlSql(ofh, dat, ctx);
   else if ("SQL".equals(cmd))
    flg = doSql(ofh, dat, ctx);

   // Close and rename the output file
   ofh.close();
   wrk = wrk.replaceAll("tmp\$", "txt");
   fil.renameTo(new File(wrk));
  }
  catch (IOException err)
  {System.err.println("Request exception: " + err.toString());
   return true;
  }

  // Accept a new request
  return flg;
 }

 // Print the formatted SQL error message to the output file
 private static void printMessage(PrintStream ofh, String typ, String msg)
 {ofh.println("ERROR in " + typ + " request:");
  ofh.println(msg.replaceAll("(\\n|\\r)"," "));
 }

 private static void printMessage(PrintStream ofh, String typ, SQLException err)
 {ofh.println("ERROR in " + typ + " request:");
  ofh.println(err.getMessage().replaceAll("(\\n|\\r)"," "));
 }

 // Parse input and manage requests
 public static void main(String[] argv) throws IOException
 {BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in));
  Hashtable ctx = new Hashtable();

  String cmd, lin;
  StringBuffer buf = new StringBuffer();
  boolean flg = true;
  int beg, end;

  cmd = "";
  while ((lin = stdin.readLine()) != null)
  {if (flg)
   {if ((beg = lin.indexOf("='")) > 0 &&
        (end = lin.lastIndexOf("'")) > 0 &&
        end > beg)
     ctx.put(lin.substring(0, beg), lin.substring(beg + 2, end));
    else if (lin.startsWith("#"))
    {cmd = lin.substring(1);
     flg = false;
    }
   }
   else
   {if ("/".equals(lin))
    {// Execute the request
     if (execRequest(cmd, buf.toString(), ctx))
      break;

     // Prepare the next command
     buf = new StringBuffer();
     cmd = "";
     ctx = new Hashtable();
     flg = true;
    }
    else
    {buf.append(lin);
     buf.append(EOL);
    }
   }
  }
 }
}
EOF

# Define the global private constants
my $ALR = "timeout";
my $CUT = "___Cut___";
my $EOD = "#QUIT\n/\n";
my $OUT = qr#timeout#;
my $WRK = 'jdbc.tmp';

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
  '-8'  => 'CHAR',     # SQL_WCHAR
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

=head2 S<$h = RDA::Driver::Jdbc-E<gt>new($ctx[,$usr,$pwd,$sid,$dba])>

The object constructor. It takes the context object reference and the login
information as arguments.

C<RDA::Driver::Jdbc> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'acc' > > DB access error flag (error outside result section)

=item S<    B<'dur' > > Remaining alarm duration

=item S<    B<'err' > > SQL error flag (error in result section)

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'max' > > Maximum number of SQL script failures

=item S<    B<'try' > > Number of SQL script failures

=item S<    B<'-agt'> > Reference to the agent object

=item S<    B<'-ctl'> > Reference to the language control object

=item S<    B<'-dba'> > Indicates if the login should be treated as sysdba

=item S<    B<'-dbh'> > Database handle

=item S<    B<'-dft'> > Default password

=item S<    B<'-die'> > Last die message

=item S<    B<'-drv'> > JDBC driver

=item S<    B<'-err'> > Number of SQL request errors

=item S<    B<'-fil'> > Error file

=item S<    B<'-ief'> > Interface error file

=item S<    B<'-log'> > Login information

=item S<    B<'-msg'> > Last error message

=item S<    B<'-nam'> > Name of the database provider

=item S<    B<'-not'> > Statistics note

=item S<    B<'-pwd'> > User password

=item S<    B<'-pid'> > Process identifier of the Java interface

=item S<    B<'-pwd'> > User password

=item S<    B<'-req'> > Number of SQL requests

=item S<    B<'-out'> > Number of SQL requests timed out

=item S<    B<'-skp'> > Number of SQL requests skipped

=item S<    B<'-trc'> > SQL output trace level

=item S<    B<'-txt'> > Password request test

=item S<    B<'-url'> > JDBC connection URL

=item S<    B<'-usr'> > User name

=item S<    B<'-ver'> > Database version

=item S<    B<'-wrk'> > Reference to the work file manager

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $ctx, $usr, $pwd, $sid, $dba) = @_;
  my ($agt, $ctl, $slf, $suf);

  # Create the object
  $agt = $ctx->get_agent;
  $ctl = $ctx->get_inline->force_context('Java');
  $slf = bless {
    acc  => $agt->get_setting('SQL_ACCESS', 0),
    dur  => 0,
    err  => $agt->get_setting('SQL_ERROR', 0),
    lim  => _chk_alarm($agt->get_setting('JDBC_TIMEOUT', 30)),
    max  => $agt->get_setting('SQL_ATTEMPTS', 3),
    try  => 0,
    -agt => $agt,
    -ctl => $ctl,
    -dft => $agt->get_info('yes') ? '?' : undef,
    -err => 0,
    -fil => RDA::Object::Rda->cat_file($ctl->get_cache, "$NAM.err"),
    -out => 0,
    -req => 0,
    -skp => 0,
    -trc => $agt->get_setting('SQL_TRACE', 0),
    -wrk => $agt->get_output,
    }, ref($cls) || $cls;

  # Analyze the login information
  if (defined($usr))
  { $suf = $dba ? ' as SYSDBA' : '';
    if ($usr =~ m/^([^@]*)\@(\S+)(.*)$/)
    { ($usr, $sid, $suf) = ($1, $2, $3);
    }
    elsif ($usr =~ m/^([^@]*)\@(.*)$/)
    { ($usr, $suf) = ($1, $2);
    }
    ($usr, $pwd) = ($1, $2) if $usr =~ m/^(.*?)\/(.*)$/;
  }
  else
  { $usr = $pwd = $suf = '';
  }
  die "RDA-00521: Missing or invalid JDBC connection information\n"
    unless $sid && $sid =~ m/^(\w+(\.\w+)+)\|(.+)$/;
  $slf->{'-usr'} = $usr;
  $slf->{'-drv'} = $1;
  $slf->{'-url'} = $3;
  $slf->{'-dba'} = 'sysdba'
    if $suf =~ m/AS\s+SYSDBA/i && $slf->{'-url'} =~ m/^jdbc\:oracle\:thin\:/;

  # Prepare password request
  if (defined($pwd))
  { $slf->{'-pwd'} = $pwd;
  }
  else
  { $sid = $slf->{'-url'};
    $slf->{'-txt'} = "Enter the password for '$usr' in '$sid': ";
    $slf->{'-log'} = ['jdbc', $sid, $usr];
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
  { my ($ctl, $lim, $lng, $msg, $pwd, $usr, $wrk, $var);

    # Get the password
    $usr = $slf->{'-usr'};
    delete($slf->{'-die'});
    unless (defined($pwd = $slf->{'-pwd'}))
    { $pwd = $ctx->get_access->get_password(@{$slf->{'-log'}}, $slf->{'-txt'},
        $slf->{'-dft'});
      die "RDA-00508: Null password given; logon denied\n"
        unless defined($pwd);
    }

    # Open the pipe
    eval {
      $ctl = $slf->{'-ctl'};
      $lng = $ctl->add_common(RDA::Object::Java->new($NAM,
        [$COD], $VER))->add_sequence->get_language;
      ($slf->{'-pid'}, undef, $slf->{'-ief'}) =
        $ctl->pipe_code($slf->{'-dbh'} = IO::File->new, $lng, $NAM);
      };
    if ($msg = $@)
    { $msg =~ s/[\n\r\s]+$//;
      $slf->{'-die'} = $slf->{'-msg'} = $msg;
      die "RDA-00522: Launch error:\n $msg\n" if $slf->{'acc'};
      return $slf->{'-dbh'} = undef;
    }

    # Connect to the database
    $var = {
      DRV => $slf->{'-drv'},
      PWD => $pwd,
      URL => $slf->{'-url'},
      USR => $usr,
      };
    $var->{'DBA'} = $slf->{'-dba'} if exists($slf->{'-dba'});
    $var->{'LIM'} = $lim           if ($lim = $slf->get_alarm($inc));
    unless ($wrk = _request($slf, $slf->{'lim'}, '#CONNECT', $var))
    { $slf->{'-wrk'}->clean_work($WRK);
      die "RDA-00502: Database connection timeout\n"
         if $slf->{'-msg'} =~ $OUT;
      die "RDA-00523: ".$slf->{'-die'}."\n" if $slf->{'acc'};
      return undef;
    }
    1 while unlink($wrk);
  }

  # Return the database handle
  $slf->{'-dbh'};
}

=head2 S<$h-E<gt>describe($ctx,$obj)>

This method returns a hash describing the specified table or view.

=cut

sub describe
{ my ($slf, $ctx, $obj) = @_;
  my ($dsc, $err, $ifh, $nam, $trc, $wrk);

  # Execute the describe request
  $dsc = {row => [], typ => {}};
  $trc = $slf->{'-trc'};
  eval {
    local $SIG{'__WARN__'} = sub {};

    print "SQL: describe $obj\n" if $trc;
    if ($slf->connect($ctx))
    { die "RDA-00523: ".$slf->{'-msg'}."\n"
        unless ($wrk = _request($slf, 0, '#DESC', {}, $obj));
      $ifh = IO::File->new;
      if ($ifh->open("<$wrk"))
      { while (<$ifh>)
        { s/[\n\r\s]+$//;
          print "SQL> $_\n" if $trc;
          if ($_ =~ /^([^\|]+)\|([^\|]+)\|/)
          { $nam = lc($1);
            push(@{$dsc->{'row'}}, $nam);
            $dsc->{'typ'}->{$nam} = exists($tb_map{$2}) ? $tb_map{$2} : $2;
          }
        }
        $ifh->close;
      }
      1 while unlink($wrk);
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
  my ($dbh);

  if (defined($dbh = delete($slf->{'-dbh'})))
  { $dbh->syswrite($EOD, length($EOD));
    $dbh->close;
  }
}

=head2 S<$h-E<gt>execute($ctx,$job,$inc,$fct,$arg)>

This method executes a database job.

=cut

sub execute
{ my ($slf, $ctx, $job, $inc, $fct, $arg) = @_;
  my ($buf, $cat, $err, $flg, $ifh, $lim, $lin, $tag, $trc, $var, @job);

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
  $cat = 0;
  $flg = 1;
  $ifh = IO::File->new;
  $var = ($lim = $slf->get_alarm($inc)) ? {LIM => $lim} : {};
  @job = split(/\n/, $job);
  if ($trc = $slf->{'-trc'})
  { for (@job)
    { print "SQL: $_\n";
    }
  }
  eval {
    local $SIG{'__WARN__'} = sub {};

    if ($slf->connect($ctx, $inc))
    { while (defined($lin = shift(@job)))
      { if ($lin =~ m/^#\s*(SQL\d*)\s*$/)
        { my ($wrk, @row, @sql);

          $tag = $1;
          push(@sql, $lin) while defined($lin = shift(@job)) && $lin ne '/';
          next unless @sql;
          die "RDA-00523: ".$slf->{'-msg'}."\n"
            unless ($wrk = _request($slf, 0, '#SQL', $var, @sql));
          if ($ifh->open("<$wrk"))
          { while (<$ifh>)
            { s/[\n\r\s]+$//;
              print "SQL> $_\n" if $trc;
              if ($_ =~ $CUT)
              { $flg = !$flg;
              }
              elsif ($flg)
              { if ($cat)
                { if (m/^\]\]\]$/)
                  { last if &$fct($slf, $arg, $buf);
                    $cat = 0;
                  }
                  else
                  { $buf .= $_;
                  }
                }
                elsif (m/^\[\[\[$/)
                { $buf = '';
                  $cat = 1;
                }
                else
                { last if &$fct($slf, $arg, $_);
                }
              }
            }
            $ifh->close;
          }
          1 while unlink($wrk);
        }
        elsif ($lin =~ m/^#\s*(PLSQL\d*)\s*$/)
        { my ($wrk, @row, @sql);

          $tag = $1;
          push(@sql, $lin) while defined($lin = shift(@job)) && $lin ne '/';
          next unless @sql;
          die "RDA-00523: ".$slf->{'-msg'}."\n"
            unless ($wrk = _request($slf, 0, '#PLSQL', $var, @sql));
          if ($ifh->open("<$wrk"))
          { while (<$ifh>)
            { s/[\n\r\s]+$//;
              print "SQL> $_\n" if $trc;
              if ($_ =~ $CUT)
              { $flg = !$flg;
              }
              elsif ($flg)
              { if ($cat)
                { if (m/^\]\]\]$/)
                  { last if &$fct($slf, $arg, $buf);
                    $cat = 0;
                  }
                  else
                  { $buf .= $_;
                  }
                }
                elsif (m/^\[\[\[$/)
                { $buf = '';
                  $cat = 1;
                }
                else
                { last if &$fct($slf, $arg, $_);
                }
              }
            }
            $ifh->close;
          }
          1 while unlink($wrk);
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
        { $var->{'LNG'} = $1;
        }
        elsif ($lin =~ m/^#\s*SLEEP\((\d+)\)\s*$/)
        { sleep($1);
        }
      }
    }
    else
    { die "RDA-00507: SQL Error: ".$slf->{'-die'}."\n" if $slf->{'acc'};
    }
    };

  # Detect and treat interrupts
  if ($err = $@)
  { unless ($err =~ $OUT)
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

=head2 S<$h-E<gt>get_dialects($ctx)>

This method returns the list of the dialects that this interface understands.

=cut

sub get_dialects
{ my ($slf, $ctx) = @_;
  my (@tbl);

  push(@tbl, lc($slf->{'-nam'})) if $slf->get_provider($ctx);
  #push(@tbl, 'odbc')             if $slf->{'-drv'} =~ /ODBC/i;
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
value in case of connection problems.

=cut

sub get_provider
{ my ($slf, $ctx) = @_;

  _get_meta($slf, $ctx) unless exists($slf->{'-nam'});
  $slf->{'-nam'};
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

  _get_meta($slf, $ctx) unless exists($slf->{'-ver'});
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

  $slf->{'_dur'} = $slf->get_alarm($inc);
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
  my ($cnt, $err, $flg, $txt, @tab);

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

# --- Methods required for RDA::Object::Dbd compatibility ---------------------

sub get_date_fmt
{ undef;
}

sub get_sources
{ ();
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

# Get the Java error
sub _get_error
{ my ($err) = @_;
  my ($buf, $ifh);

  return 'Request error'
    unless -s $err && ($ifh = IO::File->new)->open("<$err");
  $buf = join("\n ", <$ifh>);
  $ifh->close;
  $buf;
}

# Retrieve driver and database information
sub _get_meta
{ my ($slf, $ctx) = @_;
  my ($err, $ifh, $trc, $wrk);

  # Set default values
  $slf->{'-nam'} = $slf->{'-ver'} = '';

  # Try to retrieve the data
  eval {
    local $SIG{'__WARN__'} = sub {};

    # Execute the meta request
    if ($slf->connect($ctx))
    { die "RDA-00523: ".$slf->{'-msg'}."\n"
        unless ($wrk = _request($slf, 0, '#META', {}));
      $ifh = IO::File->new;
      if ($ifh->open("<$wrk"))
      { while (<$ifh>)
        { print "META> $_" if $trc;
          $slf->{$1} = $2 if $_ =~ /^(\-\w+)\='(.*)'/;
        }
        $ifh->close;
      }
      1 while unlink($wrk);
    }
  };

  # Detect and treat interrupts
  if ($err = $@)
  { unless ($err =~ $OUT)
    { ++$slf->{'-err'};
      die $err;
    }
    $slf->disconnect;
    $slf->_log_timeout($ctx, "META");
  }
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

# Submit a request
sub _request
{ my ($slf, $lim, $cmd, $var, @dat) = @_;
  my ($buf, $cnt, $err, $wrk);

  eval {
    local $SIG{'ALRM'} = 'IGNORE' if exists($SIG{'ALRM'});
    local $SIG{'PIPE'} = sub {die "Pipe broken\n"};

    # Prepare the request
    unless (ref($var))
    { $var = {};
      $var->{'LIM'} = $slf->{'lim'} if $slf->{'lim'};
    }
    $wrk = $slf->{'-wrk'}->get_work($WRK, 1);
    $var->{'WRK'} = RDA::Object::Rda->native($wrk);
    $wrk =~ s/\.tmp$/.txt/;
    1 while unlink($wrk);

    # Send the request
    $buf = join("\n", (map {$_."='".$var->{$_}."'"} keys(%$var)), $cmd, @dat,
      "/\n");
    $slf->{'-dbh'}->syswrite($buf, length($buf));

    # Wait for the request completion
    $cnt = $lim;
    $err = $slf->{'-ief'};
    while (! -e $wrk)
    { die _get_error($err)."\n" if -s $err;
      die "Request timeout\n"   if $lim && --$cnt < 0;
      sleep(1);
    }
    die _get_error($err)."\n" if -s $err;
  };
  if ($buf = $@)
  { $buf =~ s/[\n\r\s]+$//;
    $slf->{'-die'} = $slf->{'-msg'} = $buf;
    $slf->{'-dbh'}->close;
    $slf->{'-dbh'} = undef;
    return undef;
  }
  $slf->{'-wrk'}->clean_work($WRK);
  $wrk;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Library::Dbi|RDA::Library::Dbi>,
L<RDA::Object::Inline|RDA::Object::Inline>,
L<RDA::Object::Java|RDA::Object::Java>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
