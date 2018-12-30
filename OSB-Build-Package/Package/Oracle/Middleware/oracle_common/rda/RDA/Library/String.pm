# String.pm: Class Used for String Macros

package RDA::Library::String;

# $Id: String.pm,v 2.11 2012/04/25 06:35:03 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/String.pm,v 2.11 2012/04/25 06:35:03 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Library::String - Class Used for String Macros

=head1 SYNOPSIS

require RDA::Library::String;

=head1 DESCRIPTION

The objects of the C<RDA::Library::String> class are used to interface with
string-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Rda;
  use RDA::Object::Sgml;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_fct = (
  'bind'      => [\&_m_bind,      'T'],
  'bindDb'    => [\&_m_bind,      'T'],
  'bindSql'   => [\&_m_bind,      'T'],
  'chomp'     => [\&_m_chomp,     'T'],
  'command'   => [\&_m_command,   'L'],
  'compare'   => [\&_m_compare,   'N'],
  'concat'    => [\&_m_concat,    'T'],
  'decode'    => [\&_m_decode,    'T'],
  'difftime'  => [\&_m_difftime,  'N'],
  'encode'    => [\&_m_encode,    'T'],
  'field'     => [\&_m_field,     'T'],
  'gmtime'    => [\&_m_gmtime,    'T'],
  'hash'      => [\&_m_hash,      'T'],
  'hex2chr'   => [\&_m_hex2chr,   'T'],
  'hex2dec'   => [\&_m_hex2dec,   'T'],
  'hex2int'   => [\&_m_hex2int,   'N'],
  'id'        => [\&_m_id,        'T'],
  'index'     => [\&_m_index,     'N'],
  'join'      => [\&_m_join,      'T'],
  'key'       => [\&_m_key,       'T'],
  'lc'        => [\&_m_lc,        'T'],
  'length'    => [\&_m_length,    'N'],
  'localtime' => [\&_m_localtime, 'T'],
  'm'         => [\&_m_match2,    'L'],
  'match'     => [\&_m_match,     'L'],
  'mktime'    => [\&_m_mktime,    'N'],
  'oct2int'   => [\&_m_oct2int,   'N'],
  'pack'      => [\&_m_pack,      'T'],
  'quote'     => [\&_m_quote,     'T'],
  're'        => [\&_m_re,        'T'],
  'repeat'    => [\&_m_repeat,    'T'],
  'replace'   => [\&_m_replace,   'T'],
  'rindex'    => [\&_m_rindex,    'N'],
  's'         => [\&_m_replace2,  'T'],
  'shell'     => [\&_m_shell,     'T'],
  'split'     => [\&_m_split,     'L'],
  'sprintf'   => [\&_m_sprintf,   'T'],
  'status'    => [\&_m_status,    'N'],
  'substr'    => [\&_m_substr,    'T'],
  'system'    => [\&_m_system,    'N'],
  'time'      => [\&_m_time,      'T'],
  'tput'      => [\&_m_tput,      'T'],
  'translate' => [\&_m_translate, 'T'],
  'trim'      => [\&_m_trim,      'T'],
  'uc'        => [\&_m_uc,        'T'],
  'ucfirst'   => [\&_m_ucfirst,   'T'],
  'unpack'    => [\&_m_unpack,    'L'],
  'value'     => [\&_m_value,     'T'],
  'version'   => [\&_m_version,   'T'],
  );
my %tb_mon = (
  'jan' => 0,
  'feb' => 1,
  'mar' => 2,
  'apr' => 3,
  'may' => 4,
  'jun' => 5,
  'jul' => 6,
  'aug' => 7,
  'sep' => 8,
  'oct' => 9,
  'nov' => 10,
  'dec' => 11,
  );
my %tb_qte = (
  'r' => \&_quote_r,
  'v' => \&_quote_v,
  'x' => \&_quote_x,
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

=head2 S<$h = RDA::Library::String-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:String> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_cmd'> > Exit status of the last command executed

=item S<    B<'_id' > > User identification

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of operating system requests timed out

=item S<    B<'_req'> > Number of operating system requests

=item S<    B<'_usr'> > User name

=item S<    B<'_tc' > > Terminal capability hash

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _out => 0,
    _req => 0,
    }, ref($cls) || $cls;

  # Setup some parameters by default
  eval {
    local $SIG{'__WARN__'} = sub {};
    require Term::Cap;
    my $trm = Tgetent Term::Cap {TERM => undef, OSPEED => 15};
    $slf->{'_tc'}->{'bell'}    = $trm->Tputs('bl', 1);
    $slf->{'_tc'}->{'bold'}    = $trm->Tputs('mb', 1);
    $slf->{'_tc'}->{'clear'}   = $trm->Tputs('cl', 1);
    $slf->{'_tc'}->{'home'}    = $trm->Tputs('ho', 1);
    $slf->{'_tc'}->{'off'}     = $trm->Tputs('me', 1);
    $slf->{'_tc'}->{'reverse'} = $trm->Tputs('mr', 1);
  };

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

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

This method resets the statistics. It creates a setting to indicate when the
module was executed for the last time.

=cut

sub clr_stats
{ my ($slf) = @_;

  $slf->{'_not'} = '';
  $slf->{'_req'} = $slf->{'_out'} = 0;
}

=head2 S<$h-E<gt>get_stats>

This method reports the library statistics in the specified module.

=cut

sub get_stats
{ my ($slf) = @_;
  my ($use);

  if ($slf->{'_req'})
  { $use = $slf->{'_agt'}->get_usage;

    # Get the statistics record
    $use->{'OS'} = {not => '', out => 0, req => 0}
      unless exists($use->{'OS'});
    $use = $use->{'OS'};

    # Generate the module statistics
    $use->{'out'} += $slf->{'_out'};
    $use->{'req'} += $slf->{'_req'};
    $use->{'not'} = $slf->{'_not'} if $slf->{'_not'};

    # Clear statistics
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

=head1 STRING MACROS

=head2 S<bind($sql,$val...)>

This macro replaces the placeholders by the specified values. The placeholders
indicate code fragments in a database statement that will be supplied
later. The placeholders are numbered from 1 and begin with a C<:> character
(for example, C<:1>, C<:2>, and so on).

C<bindDb> and C<bindSql> are aliases.

=cut

sub _m_bind
{ my ($slf, $ctx, @arg) = @_;

  _bind(@arg);
}

sub _bind
{ my ($sql, @arg) = @_;
  my ($cnt);

  foreach my $val (@arg)
  { ++$cnt;
    $sql =~ s/\:$cnt\b/$val/g if defined($val);
  }
  $sql;
}

=head2 S<chomp($str)>

This macro removes the final end of line in the text string and returns the
resulting string.

=cut

sub _m_chomp
{ my ($slf, $ctx, $str) = @_;

  $str =~ s/[\r\n]+$// if defined($str);
  $str;
}

=head2 S<command($cmd)>

This macro executes an operating system command and returns the produced
lines as a list. If the execution fails, it returns an empty list. You can
retrieve the exit status with the C<status> macro.

=cut

sub _m_command
{ my ($slf, $ctx, $cmd) = @_;
  my @buf;

  # Adapt the command for VMS
  if ($cmd && RDA::Object::Rda->is_vms
    && $cmd =~ m/[\<\>]/ && $cmd !~ m/^PIPE /i)
  { $cmd = "PIPE $cmd";
    $cmd =~ s/2>&1/2>SYS\$OUTPUT/g;
  }

  # Execute the command, storing all resulting lines as a list
  eval {
    local $SIG{'__WARN__'} = sub {};
    @buf = `$cmd`;
    };
  $slf->{'_cmd'} = $?;
  ++$slf->{'_req'};

  # Remove the ends of line
  foreach my $lin (@buf)
  { $lin =~ s/[\r\n]+$//;
  }

  # Returns the command result
  @buf;
}

=head2 S<compare($op,$str1,$str2)>

This macro compares the two specified strings. The supported operations are as
follows:

=over 14

=item S<    B<'eq' > > True if C<$str1> equals to C<$str2>

=item S<    B<'ne' > > True if C<$str1> differs from C<$str2>

=item S<    B<'lt' > > True if C<$str1> is less than C<$str2>

=item S<    B<'le' > > True if C<$str1> is less than or equals to C<$str2>

=item S<    B<'gt' > > True if C<$str1> is greater than C<$str2>

=item S<    B<'ge' > > True if C<$str1> is greater than or equals to C<$str2>

=item S<    B<'diff' >> True if C<$str1> represents a different version than
C<$str2>

=item S<    B<'final'>> True if C<$str1> is older than or the same version as
C<$str2>

=item S<    B<'newer'>> True if C<$str1> represents a newer version than
C<$str2>

=item S<    B<'older'>> True if C<$str1> represents an older version than
C<$str2>

=item S<    B<'same' >> True if C<$str1> represents the same version as
C<$str2>

=item S<    B<'valid'>> True if C<$str1> is newer than or the same version as
C<$str2>

=back

When the version operator is in upper case, it limits the comparison to the
number of elements present in the reference.

=cut

sub _m_compare
{ my ($slf, $ctx, $op, $str1, $str2) = @_;

  if (defined($str1) && defined($str2))
  { return $str1 eq $str2 if $op eq 'eq' || $op eq '==';
    return $str1 ne $str2 if $op eq 'ne' || $op eq '!=';
    return $str1 lt $str2 if $op eq 'lt' || $op eq '<';
    return $str1 le $str2 if $op eq 'le' || $op eq '<=';
    return $str1 gt $str2 if $op eq 'gt' || $op eq '>';
    return $str1 ge $str2 if $op eq 'ge' || $op eq '>=';
    return _cmp_version($str1, $str2, 0) == 0 if $op eq 'SAME'  || $op eq 'V=';
    return _cmp_version($str1, $str2, 0) != 0 if $op eq 'DIFF'  || $op eq 'V!';
    return _cmp_version($str1, $str2, 0) <  0 if $op eq 'OLDER' || $op eq 'V<';
    return _cmp_version($str1, $str2, 0) <= 0 if $op eq 'FINAL' || $op eq 'V-';
    return _cmp_version($str1, $str2, 0) >  0 if $op eq 'NEWER' || $op eq 'V>';
    return _cmp_version($str1, $str2, 0) >= 0 if $op eq 'VALID' || $op eq 'V+';
    return _cmp_version($str1, $str2, 1) == 0 if $op eq 'same';
    return _cmp_version($str1, $str2, 1) != 0 if $op eq 'diff';
    return _cmp_version($str1, $str2, 1) <  0 if $op eq 'older';
    return _cmp_version($str1, $str2, 1) <= 0 if $op eq 'final';
    return _cmp_version($str1, $str2, 1) >  0 if $op eq 'newer';
    return _cmp_version($str1, $str2, 1) >= 0 if $op eq 'valid';
  }
  0;
}

# Compare versions
sub _cmp_version
{ my ($ver1, $ver2, $flg) = @_;
  my ($str1, $str2, $val);

  ($ver1, $str1) = split('\/', $ver1);
  ($ver2, $str2) = split('\/', $ver2);

  return $val if ($val = _cmp_ver($ver1, $ver2, $flg));
  if (defined($str2))
  { return -2 unless defined($str1) && lc($str1) eq lc($str2);
  }
  0;
}

sub _cmp_ver
{ my ($ver1, $ver2, $flg) = @_;
  my ($num1, $num2, @tbl);

  @tbl = split(/\./, $ver2);
  foreach $num1 (split(/\./, $ver1))
  { return $flg unless defined($num2 = shift(@tbl));
    return $num1 <=> $num2 unless $num1 == $num2;
  }
  return (scalar @tbl) ? -1 : 0;
}

=head2 S<concat($str,...)>

This macro concatenates all text strings specified as arguments into a new
text string. It ignores invalid arguments.

=cut

sub _m_concat
{ my $slf = shift;
  my $ctx = shift;
  join('', grep {defined($_) && !ref($_)} @_);
}

=head2 S<decode($str)>

This macro replaces entities found in the string with the corresponding ISO
8859-1 character. It ignores unrecognized entities.

=cut

sub _m_decode
{ my ($slf, $ctx, $str) = @_;

  defined($str) ? RDA::Object::Sgml::decode($str) : undef;
}

=head2 S<difftime($time1,$time0)>

This macro returns the time difference (in seconds) between the two times (as
returned by C<mktime>).

=cut

sub _m_difftime
{ my ($slf, $ctx, $tm1, $tm0) = @_;
  my $dur;

  if (defined($tm0) && defined($tm1))
  { eval {
      require POSIX;
      $dur = &POSIX::difftime($tm1, $tm0);
    };
    return $dur unless $@;
  }
  undef;
}

=head2 S<encode($str[,$flg])>

This macro replaces control characters, ISO 8859-1 or UTF-8 characters, and
some sensitive characters characters with their entity representation. Unless
the flag is set, it encodes Wiki (C<%>, C<[>, C<]>, C<{>, C<}>, and C<|>)
characters also.

=cut

sub _m_encode
{ my ($slf, $ctx, $str, $flg) = @_;

  defined($str) ? RDA::Object::Sgml::encode($str, $flg) : undef;
}

=head2 S<field($re,$num,$str)>

This macro removes leading and trailing spaces from the string, splits it into
fields, and returns the specified field. Field numbers start at 0. You can use
negative field numbers to count the fields from the end.

=cut

sub _m_field
{ my ($slf, $ctx, $re, $num, $str) = @_;
  my $lim;

  return undef unless defined($re) && defined($num) && defined($str);
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $lim = ($num < 0) ? 0 : $num + 2;
  (split(/$re/, $str, $lim))[$num];
}

=head2 S<gmtime([$format[,$time]])>

This macro returns the GMT time. You can specify a C<strftime(3)> format as an
argument.

=cut

sub _m_gmtime
{ my ($slf, $ctx, $fmt, $tim) = @_;
  my ($str, @tim);

  if ($fmt)
  { eval {
      require POSIX;
      @tim = gmtime(defined($tim) ? $tim : time);
      $tim[-1] = -1;
      $str = &POSIX::strftime($fmt, @tim);
    };
    return $str unless $@;
  }
  $str = gmtime(defined($tim) ? $tim : time);
}

=head2 S<hash($str,...)>

This macro returns a hash of its arguments using the Salvia algorithm.

=cut

sub _m_hash
{ my $slf = shift;
  my $ctx = shift;
  my ($off, $sum, @hsh);

  $sum = $off = 0;
  $hsh[0] = $hsh[1] = $hsh[2] = $hsh[3] = 0;
  foreach my $chr (unpack('c*', _m_join($slf, $ctx, ':', '0', @_ , 'RDA')))
  { $sum = ($sum + $hsh[$off]) % 15;
    $hsh[$off] = _rotate($chr, ($sum + $chr) % 15) ^ _rotate($hsh[$off], $sum);
    $off = ($off + 1) & 3;
  }
  sprintf('%08X%08X%08X%08X', @hsh);
}

sub _rotate
{ my ($val, $off) = @_;

  (($val << $off) & 0xffffffff) | (($val >> (32 - $off)) & 0xffffffff);
}

=head2 S<hex2chr($str)>

This macro replaces all hexadecimal C<\0xXX> or octal C<\NNN> sequences in the
string with character representation.

=cut

sub _m_hex2chr
{ my ($slf, $ctx, $str) = @_;

  $str =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg if $str;
  $str;
}

=head2 S<hex2dec($str)>

This macro replaces all hexadecimal numbers in the string with decimal
representation.

=cut

sub _m_hex2dec
{ my ($slf, $ctx, $str) = @_;

  $str =~ s#(0x[\da-fA-F]+)#hex(lc($1))#eg if $str;
  $str;
}

=head2 S<hex2int($str)>

This macro converts a string representing an hexadecimal number in a number.

=cut

sub _m_hex2int
{ my ($slf, $ctx, $str) = @_;

  hex($str);
}

=head2 S<id()>

This macro returns UIDs and GIDs. When it is not supported on a platform, it
returns the user name only.

=cut

sub _m_id
{ my ($slf) = @_;

  unless (exists($slf->{'_id'}))
  { eval {
      my ($id, $sep, $str, @grp);
      $id  = $>;
      $str = "uid=$id(".getpwuid($id);
      @grp = split(/\s/, $));
      $id  = shift(@grp);
      $str .= ") gid=$id(".getgrgid($id);
      $sep = ') groups=';
      foreach $id (sort @grp)
      { $str .= $sep.$id.'('.getgrgid($id);
        $sep = '),';
      }
      $str .= ')';
      $slf->{'_id'} = $str;
    };
    if ($@)
    { $slf->{'_id'} = $slf->{'_agt'}->get_config->get_user;
    }
  }

  $slf->{'_id'};
}

=head2 S<index($str,$sub[,$off])>

This macro returns the position of the first occurrence of the substring in the
text string. The offset, when specified, indicates where to start looking. If
the substring is not found, it returns -1.

=cut

sub _m_index
{ my ($slf, $ctx, $str, $sub, $off) = @_;

  $off = 0 unless defined($off);
  (defined($str) & defined($sub)) ? index($str, $sub, $off) : -1;
}

=head2 S<join($sep,$str,...)>

This macro joins all text strings that are specified as arguments into a new
text string with the fields separated by the specified separator. It ignores
invalid arguments.

=cut

sub _m_join
{ my $slf = shift;
  my $ctx = shift;
  my $sep = shift;

  join($sep, grep {defined($_) && !ref($_)} @_);
}

=head2 S<key($str)>

This macro extracts the key part of a string such as 'key=value'. It removes
leading and trailing spaces from the key.

=cut

sub _m_key
{ my ($slf, $ctx, $str) = @_;

  return undef unless defined($str);
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  (split(/\s*=\s*/, $str, 2))[0];
}

=head2 S<lc($str)>

This macro converts the specified text string to lower case.

=cut

sub _m_lc
{ my ($slf, $ctx, $str) = @_;

  defined($str) ? lc($str) : undef;
}

=head2 S<length($str)>

This macro returns the length of the specified text string. It returns an
undefined value for an undefined argument.

=cut

sub _m_length
{ my ($slf, $ctx, $str) = @_;

  defined($str) ? length($str) : undef;
}

=head2 S<localtime([$format[,$time]])>

This macro returns the local time. You can specify a C<strftime(3)> format as
an argument.

=cut

sub _m_localtime
{ my ($slf, $ctx, $fmt, $tim) = @_;
  my $str;

  if ($fmt)
  { eval {
      require POSIX;
      $str = &POSIX::strftime($fmt, localtime(defined($tim) ? $tim : time));
    };
    return $str unless $@;
  }
  $str = localtime(defined($tim) ? $tim : time);
}

=head2 S<match($str,$re[,$flg])>

This macro indicates whether the string matches the regular expression. When
the flag is set, it ignores case distinctions in both the pattern and the
string. It returns the match result as a list.

=cut

sub _m_match
{ my ($slf, $ctx, $str, $re, $flg) = @_;

  if (defined($str) && $re)
  { $re = $flg ? qr#$re#i : qr#$re#;
    return $str =~ $re;
  }
  ();
}

sub _m_match2
{ my ($slf, $ctx, $str, $re, $flg) = @_;

  if (defined($str) && $re)
  { $re = eval "\$flg ? qr#$re#i : qr#$re#";
    die $@ if $@;
    return $str =~ $re;
  }
  ();
}

=head2 S<mktime(sec,min,hour,day,mon,year)>

This macro converts date/time information to a calendar time. The month ("mon")
begins at zero (that is, January is 0, not 1). The year ("year") is given in
years since 1900 (that is, the year 1995 is 95; the year 2001 is 101).

It returns an undefined value on failure.

=cut

sub _m_mktime
{ my ($slf, $ctx, $sec, $min, $hr, $day, $mon, $yea) = @_;
  my ($tim, $wdy, $ydy);

  # Convert arguments
  $mon = lc($mon);
  $mon = $tb_mon{$mon} if $mon && exists($tb_mon{$mon});
  $yea -= 1900         if $yea && $yea >= 1900;
  $wdy = $ydy = 0;

  # Convert the date/time
  eval {
    require POSIX;
    eval {POSIX::tzset()};
    $tim = POSIX::mktime($sec, $min, $hr, $day, $mon, $yea, $wdy, $ydy, -1);
  };
  $@ ? undef : $tim;
}

=head2 S<oct2int($str)>

This macro converts a string representing an octal number in a number.

=cut

sub _m_oct2int
{ my ($slf, $ctx, $str) = @_;

  oct($str);
}

=head2 S<pack($fmt,$arg,...)>

This macro takes a list of values and converts it into a string using the
rules specified by the template. The resulting string is the concatenation of
the converted values.

=cut

sub _m_pack
{ my $slf = shift;
  my $ctx = shift;
  my $fmt = shift;

  pack($fmt, @_);
}

=head2 S<quote($str[,$typ])>

This macro encodes characters to use the string in the specified context, as a
regular expression by default. Supported types are as follows:

=over 9

=item B<    'r' > Regular expression (default type)

=item B<    'v' > Shell command argument with variable substitution disabled

=item B<    'x' > Shell command argument

=back

For any other type, it returns the string without any modification. For VMS,
variable substitutions are not disabled.

=cut

sub _m_quote
{ my ($slf, $ctx, $str, $typ) = @_;

  return $str unless defined($str);
  $typ = 'r' unless defined($typ);
  exists($tb_qte{$typ}) ? &{$tb_qte{$typ}}($slf, $str) : $str;
}

sub _quote_r
{ my ($slf, $str) = @_;
  $str =~ s#([\\\/\#\.\*\+\?\|\(\)\[\]\{\}\^\$])#\\$1#g;
  $str;
}
  
sub _quote_v
{ my ($slf, $str) = @_;

  RDA::Object::Rda->quote($str, 1);
}
  
sub _quote_x
{ my ($slf, $str) = @_;

  RDA::Object::Rda->quote($str, 0);
}

=head2 S<re($str)>

This macro tries to convert a string containing wild characters into a Perl
regular expression. It scans for the characters C<*>, C<?>, C<[>, and
C<]>. C<*> matches any string, including the null string. C<?> matches any
single character. C<[...]> matches any one of the enclosed characters, which
are taken litterally. It assumes that backslashes are used as escape characters.

=cut

sub _m_re
{ my ($slf, $ctx, $str) = @_;
  my ($itm, $nxt, @tbl);

  if ($str)
  { @tbl = split(/([\*\?\[\]])/, $str, -1);
    $nxt = '';
    $str = '^';
    while (defined($itm = shift(@tbl)))
    { $itm = $nxt.$itm;
      $nxt = '';
      if ($itm eq '*')
      { $str .= '.*';
      }
      elsif ($itm eq '?')
      { $str .= '.';
      }
      elsif ($itm eq '[')
      { $str .= $itm;
        while (defined($itm = shift(@tbl)))
        { $str .= $itm;
          last if $itm eq ']';
        }
      }
      elsif ($itm eq ']')
      { $str .= '\\]';
      }
      else
      { if ($itm =~ m/(\\+)$/ && length($1) & 1)
        { $nxt = '\\';
          $itm = substr($itm, 0, -1);
        }
        $itm =~ s#([\#\.\+\|\(\)\{\}\^\$])#\\$1#g;
        $str .= $itm;
      }
    }
    $str .= '$';
  }
  $str
}

=head2 S<repeat($str[,$cnt])>

This macro repeats the string by the specified number (1 by default).

=cut

sub _m_repeat
{ my ($slf, $ctx, $str, $cnt) = @_;

  (defined($str) && defined($cnt)) ? $str x $cnt : $str;
}

=head2 S<replace($str,$re[,$str[,$flg]])>

This macro replaces the first occurrence of the $re pattern by $str. When the
flag is set, it replaces all occurrences.

=cut

sub _m_replace
{ my ($slf, $ctx, $str, $re1, $re2, $flg) = @_;

  if (defined($str) && defined($re1))
  { $re2 = '' unless defined($re2);
    if ($flg)
    { $str =~ s#$re1#$re2#mg;
    }
    else
    { $str =~ s#$re1#$re2#m;
    }
  }
  $str;
}

sub _m_replace2
{ my ($slf, $ctx, $str, $re1, $re2, $flg) = @_;

  if (defined($str) && defined($re1))
  { $re2 = '' unless defined($re2);
    if ($flg)
    { eval "\$str =~ s#$re1#$re2#mg";
    }
    else
    { eval "\$str =~ s#$re1#$re2#m";
    }
    die $@ if $@;
  }
  $str;
}

=head2 S<rindex($str,$sub[,$off])>

This macro returns the position of the last occurrence of the substring in
the text string. The offset, when specified, is the rightmost position that
may be returned. If the substring is not found, it returns -1.

=cut

sub _m_rindex
{ my ($slf, $ctx, $str, $sub, $off) = @_;

  return -1 unless defined($str) && defined($sub);
  defined($off) ? rindex($str, $sub, $off) : rindex($str, $sub);
}

=head2 S<shell([$env])>

This macro returns the shell path. First, it attempts to deduce the path from
the environment. Next, it attempts to extract the login shell. To force a
search for a specific environment variable, provide the environment variable
as an argument.

=cut

sub _m_shell
{ my ($slf, $ctx, $env) = @_;
  my $shl;

  # Try to determine from an anvironment variable
  unless (defined($env))
  { $env = RDA::Object::Rda->is_windows ? 'COMSPEC' : 'SHELL';
  }
  return $ENV{$env} if exists($ENV{$env});

  # Try to determine the login shell
  eval
  { $shl = (getpwuid($<))[8];
  };

  $shl;
}

=head2 S<split($re,$str[,$num])>

This macro splits a string into fields. It is possible to limit the number of
fields.

=cut

sub _m_split
{ my ($slf, $ctx, $re, $str, $num) = @_;

  $num = 0 unless defined($num);
  return () unless defined($re) && defined($str);
  split(/$re/, $str, $num);
}

=head2 S<sprintf($fmt,$arg,...)>

This macro returns a text string according to the specified format.

=cut

sub _m_sprintf
{ my $slf = shift;
  my $ctx = shift;
  my $fmt = shift;

  sprintf($fmt, @_);
}

=head2 S<status()>

This macro returns the exit status of the last command executed.

=cut

sub _m_status
{ shift->{'_cmd'};
}

=head2 S<substr($str[,$off[,$lgt]])>

This macro extracts and returns a substring out of the string. The first
character is at the specified offset. If the offset is negative, it starts that
far from the end of the string. If the length is omitted, it returns everything
to the end of the string. If the length is negative, it leaves that many
characters off the end of the string.

=cut

sub _m_substr
{ my ($slf, $ctx, $str, $off, $lgt) = @_;

  if (defined($str))
  { $str = defined($lgt) ? substr($str, $off, $lgt) : substr($str, $off);
  }
  $str;
}

=head2 S<system($str...)>

This macro executes an operating system command and returns the exit status.

=cut

sub _m_system
{ my ($slf, $ctx, @arg) = @_;

  $slf->{'_cmd'} = system(@arg);
}

=head2 S<time()>

This macro returns the number of non-leap seconds since the time that the
system considers to be the epoch.

=cut

sub _m_time
{ time;
}

=head2 S<tput($mode)>

This macro returns the corresponding escape sequence. The following modes are
supported:

=over 16

=item S<    B<'bell' >> Inserts a bell

=item S<    B<'bold' >> Puts the next characters in bold

=item S<    B<'clear'>> Clears the screen

=item S<    B<'home' >> Goes to screen home

=item S<    B<'off' > > Suppresses any mode

=item S<    B<'reverse'>> Puts the next characters in reverse mode

=back

=cut

sub _m_tput
{ my ($slf, $ctx, $mod) = @_;

  exists($slf->{'_tc'}->{$mod}) ? $slf->{'_tc'}->{$mod} : '';
}

=head2 S<translate($str,$src,$dst[,$flg])>

This macro translates all occurrences of the characters found in the search
string to the corresponding character in the replacement list. If the
replacement list is shorter than the search list, then the last character of
the replacement list is replicated as necessary. When the flag is set, any
substitution that would result in multiple consecutive characters is replaced
with a single occurrence. It returns the resulting text string.

C<translate($str,'A-Z','a-z')> converts a string to lower case.

C<translate($str,'a-z','A-Z')> converts a string to upper case.

=cut

sub _m_translate
{ my ($slf, $ctx, $str, $src, $dst, $flg) = @_;

  if (defined($str) && defined($src) && defined($dst))
  { if ($flg)
    { eval "\$str =~ tr#$src#$dst#s";
    }
    else
    { eval "\$str =~ tr#$src#$dst#";
    }
  }
  $str;
}

=head2 S<trim($str[,$del])>

This macro trims all leading and trailing spaces. You can specify extra
characters to trim as a second argument.

=cut

sub _m_trim
{ my ($slf, $ctx, $str, $del) = @_;

  if (defined($str))
  { $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    if ($del)
    { $str =~ s#^$del##;
      $str =~ s#$del$##;
    }
  }
  $str;
}

=head2 S<uc($str)>

This macro converts the specified text string to upper case.

=cut

sub _m_uc
{ my ($slf, $ctx, $str) = @_;

  defined($str) ? uc($str) : undef;
}

=head2 S<ucfirst($str)>

This macro converts the first character of the specified text string to
upper case.

=cut

sub _m_ucfirst
{ my ($slf, $ctx, $str) = @_;

  defined($str) ? ucfirst($str) : undef;
}

=head2 S<unpack($fmt,$val)>

This macro takes a string and expands it into a list of values.

=cut

sub _m_unpack
{ my ($slf, $ctx, $fmt, $val) = @_;

  return () unless defined($fmt) && defined($val);
  unpack($fmt, $val);
}

=head2 S<value($str)>

This macro extracts the value part of a string such as 'key=value'. It removes
leading and trailing spaces from the value.

=cut

sub _m_value
{ my ($slf, $ctx, $str) = @_;

  return undef unless defined($str);
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  (split(/\s*=\s*/, $str, 2))[1];
}

=head2 S<version($str,...)>

This macro normalizes a version string. It returns an undefined value when the
arguments do not contain any numeric fragment.

=cut

sub _m_version
{ my $slf = shift;
  my $ctx = shift;
  my ($str, @num, @str);

  foreach my $arg (@_)
  { push(@str, split(/[\.\-]/, $arg)) if $arg;
  }

  if (@num = grep {m/^\d+$/} @str)
  { $str = join('.', @num);
    $str .= '/'.join('.', @str) if (@str = grep {m/\D/} @str);
  }
  $str;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
