# Telnet.pm: Class Used for Managing Telnet Connections

package RDA::Object::Telnet;

# $Id: Telnet.pm,v 1.18 2012/04/30 21:03:26 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Telnet.pm,v 1.18 2012/04/30 21:03:26 mschenke Exp $
#
# Change History
# 20120130  MSC  Fix command construction.

=head1 NAME

RDA::Object::Telnet - Class Used for Managing Telnet Connections

=head1 SYNOPSIS

require RDA::Object::Telnet;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Telnet> class are used to manage Telnet
connections.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object;
  use RDA::Object::Buffer;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
  use Socket;
  use Symbol;
}

# Define the global public variables
use vars qw($STRINGS $VERSION @EXPORT_OK @ISA @TELOPTS %SDCL);
$VERSION   = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw(TELNET_IAC TELNET_DONT TELNET_DO    TELNET_WONT TELNET_WILL
                TELNET_SB  TELNET_GA   TELNET_EL    TELNET_EC   TELNET_AYT
                TELNET_AO  TELNET_IP   TELNET_BREAK TELNET_DM   TELNET_NOP
                TELNET_SE  TELNET_EOR  TELNET_ABORT TELNET_SUSP TELNET_EOF
                TELNET_SYNCH
                TELOPT_BINARY      TELOPT_ECHO           TELOPT_RCP
                TELOPT_SGA         TELOPT_NAMS           TELOPT_STATUS
                TELOPT_TM          TELOPT_RCTE           TELOPT_NAOL
                TELOPT_NAOP        TELOPT_NAOCRD         TELOPT_NAOHTS
                TELOPT_NAOHTD      TELOPT_NAOFFD         TELOPT_NAOVTS
                TELOPT_NAOVTD      TELOPT_NAOLFD         TELOPT_XASCII
                TELOPT_LOGOUT      TELOPT_BM             TELOPT_DET
                TELOPT_SUPDUP      TELOPT_SUPDUPOUTPUT   TELOPT_SNDLOC
                TELOPT_TTYTYPE     TELOPT_EOR            TELOPT_TUID
                TELOPT_OUTMRK      TELOPT_TTYLOC         TELOPT_3270REGIME
                TELOPT_X3PAD       TELOPT_NAWS           TELOPT_TSPEED
                TELOPT_LFLOW       TELOPT_LINEMODE       TELOPT_XDISPLOC
                TELOPT_OLD_ENVIRON TELOPT_AUTHENTICATION TELOPT_ENCRYPT
                TELOPT_NEW_ENVIRON TELOPT_TN3270E        TELOPT_XAUTH
                TELOPT_CHARSET     TELOPT_TRSP           TELOPT_COM_PORT
                TELOPT_TSLE        TELOPT_TSTLS          TELOPT_KERMIT
                TELOPT_EXOPL);
@ISA       = qw(RDA::Object Exporter);
@TELOPTS   = (
  "BINARY",              "ECHO",               "RCP",
  "SUPPRESS GO AHEAD",   "NAME",               "STATUS",
  "TIMING MARK",         "RCTE",               "NAOL",
  "NAOP",                "NAOCRD",             "NAOHTS",
  "NAOHTD",              "NAOFFD",             "NAOVTS",
  "NAOVTD",              "NAOLFD",             "EXTEND ASCII",
  "LOGOUT",              "BYTE MACRO",         "DATA ENTRY TERMINAL",
  "SUPDUP",              "SUPDUP OUTPUT",      "SEND LOCATION",
  "TERMINAL TYPE",       "END OF RECORD",      "TACACS UID",
  "OUTPUT MARKING",      "TTYLOC",             "3270 REGIME",
  "X.3 PAD",             "NAWS",               "TSPEED",
  "LFLOW",               "LINEMODE",           "XDISPLOC",
  "OLD-ENVIRON",         "AUTHENTICATION",     "ENCRYPT",
  "NEW-ENVIRON",         "TN3270E",            "XAUTH",
  "CHARSET",             "REMOTE SERIAL PORT", "COM PORT",
  "SUPPRESS LOCAL ECHO", "START TLS",          "KERMIT"
  );
%SDCL      = (
  inc => [qw(RDA::Object)],
  met => {
    'accept_options'    => {ret => 0},
    'binmode'           => {ret => 0},
    'break'             => {ret => 0},
    'collect'           => {ret => 0},
    'command'           => {ret => 1},
    'empty_buffer'      => {ret => 0},
    'eof'               => {ret => 0},
    'error'             => {ret => 0},
    'exit'              => {ret => 0},
    'fatal'             => {ret => 0},
    'get'               => {ret => 0},
    'getline'           => {ret => 0},
    'getlines'          => {ret => 1},
    'get_info'          => {ret => 0},
    'get_input'         => {ret => 0},
    'get_option_state'  => {ret => 0},
    'get_print_length'  => {ret => 0},
    'login'             => {ret => 0},
    'open'              => {ret => 0},
    'print'             => {ret => 0},
    'put'               => {ret => 0},
    'quit'              => {ret => 0},
    'set_buffer_length' => {ret => 0},
    'set_error_mode'    => {ret => 0},
    'set_info'          => {ret => 0},
    'set_irs'           => {ret => 0},
    'set_prompt'        => {ret => 0},
    'set_skip_mode'     => {ret => 0},
    'set_telnet_mode'   => {ret => 0},
    'set_timeout'       => {ret => 0},
    'timeout'           => {ret => 0},
    'wait_for'          => {ret => 1},
    },
  new => 1,
  pwd => 1,
  trc => 'TELNET_TRACE',
  );


# Define the global private constants
my $DUMP_FMT = '%s %s %s %s  ' x 4;
my $DUMP_MSK = 'a2' x 16;
my $DUMP_SPC = '  ' x 15;
my $TEST_BEG_PAT = '1 if ($slf->{"_buf"} =~ ';
my $TEST_END_PAT = ')';
my $WAIT_BEG_PAT =
    'if ($slf->{"_buf"} =~ ';
my $WAIT_END_PAT = ')
      { $pre = $`;
        $hit = $&;
        substr($slf->{"_buf"}, 0, length($`) + length($&)) = "";
        last;
      }
';
my $WAIT_BEG_STR =
    'if (($pos = index($slf->{"_buf"}, ';
my $WAIT_MID_STR = ')) > -1)
      { $lgt = ';
my $WAIT_END_STR = ';
        $pre = substr($slf->{"_buf"}, 0, $pos);
        $hit = substr($slf->{"_buf"}, $pos, $lgt);
        substr($slf->{"_buf"}, 0, $pos + $lgt) = "";
        last;
      }
';

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Telnet-E<gt>new([key =E<gt> $value,...])>

The object constructor. This method enables you to specify initial attributes
at object creation time. It supports following attributes:

=over 11

=item S<    B<'bin'> > Binary mode (C<0> by default)

=item S<    B<'cmd'> > Command mode (C<1> by default)

=item S<    B<'dmp'> > Dump file (none by default)

=item S<    B<'err'> > Error mode (C<auto> by default)

=item S<    B<'inp'> > Input log file (none by default)

=item S<    B<'hst'> > Host (C<localhost> by default)

=item S<    B<'irs'> > Input record separator (C<\n> by default)

=item S<    B<'lim'> > Timeout value in seconds (C<10> by default)

=item S<    B<'max'> > Maximum buffer size (C<1048576> by default)

=item S<    B<'mod'> > Telnet mode (C<0> by default)

=item S<    B<'nxt'> > Continuation pattern (none by default)

=item S<    B<'ofs'> > Output field separator (empty string by default)

=item S<    B<'opt'> > Option log file (none by default)

=item S<    B<'ors'> > Output record separator (C<\n> by default)

=item S<    B<'out'> > Output log file (none by default)

=item S<    B<'pat'> > Prompt pattern (C<m/[\$%#E<gt>] $/> by default)

=item S<    B<'prt'> > Service port (C<23> by default)

=item S<    B<'skp'> > Skip mode (C<auto> by default)

=back

C<RDA::Object::Telnet> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'dis' > > Disconnection command

=item S<    B<'eoc' > > End of command indicator

=item S<    B<'eof' > > End of file indicator

=item S<    B<'hit' > > Last prompt matched

=item S<    B<'lin' > > Last line

=item S<    B<'msg' > > Error message

=item S<    B<'ofs' > > Output field separator

=item S<    B<'ors' > > Output record separator

=item S<    B<'out' > > Timeout indicator

=item S<    B<'txt' > > Captured text

=item S<    B<'_alt'> > Alternative buffer

=item S<    B<'_bin'> > Binary mode indicator

=item S<    B<'_buf'> > Reception buffer

=item S<    B<'_chg'> > Pending option changes

=item S<    B<'_cmd'> > Command mode

=item S<    B<'_dfh'> > Dump log handle

=item S<    B<'_ech'> > Echo indicator

=item S<    B<'_err'> > Error mode

=item S<    B<'_hst'> > Host address

=item S<    B<'_irs'> > Input record separator

=item S<    B<'_lgt'> > Print length

=item S<    B<'_lim'> > Timeout value in seconds

=item S<    B<'_max'> > Maximum buffer size

=item S<    B<'_mod'> > Telnet mode

=item S<    B<'_msk'> > File descriptor mask

=item S<    B<'_not'> > Pending error message

=item S<    B<'_nxt'> > Continuation pattern

=item S<    B<'_ocb'> > Option callback function

=item S<    B<'_ofh'> > Option log handle

=item S<    B<'_opt'> > Option hash

=item S<    B<'_pat'> > Prompt pattern

=item S<    B<'_prt'> > Port number

=item S<    B<'_pwd'> > Password manager

=item S<    B<'_rfh'> > Reception log handle

=item S<    B<'_scb'> > Sub option callback function

=item S<    B<'_siz'> > Block size

=item S<    B<'_skp'> > Command remove mode

=item S<    B<'_sfh'> > Send log handle

=item S<    B<'_srv'> > Server socket

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, @arg) = @_;
  my ($key, $slf, $val);

  # Create the object
  $slf = bless {
    eoc  => 1,
    eof  => 1,
    hit  => '',
    msg  => '',
    lin  => '',
    ofs  => '',
    ors  => "\n",
    out  => 0,
    _alt => '',
    _bin => 0,
    _buf => '',
    _chg => '',
    _cmd => 1,
    _err => 'die',
    _hst => 'localhost',
    _irs => "\n",
    _lgt => 0,
    _lim => 10,
    _max => 1048576,
    _mod => 1,
    _msk => '',
    _opn => 0,
    _opt => {},
    _pat => 'm/.*?[\$%#>]\s*$/',
    _prt => 23,
    _siz => _check_block_size(),
    _skp => 'auto',
    }, ref($cls) || $cls;

  # Add the initial attributes
  while (($key, $val) = splice(@arg, 0, 2))
  { if ($key eq 'bin')
    { $slf->binmode($val);
    }
    elsif ($key eq 'dmp')
    { $slf->log_dump($val);
    }
    elsif ($key eq 'err')
    { $slf->set_error_mode($val);
    }
    elsif ($key eq 'hst')
    { $slf->{'_hst'} = $val if defined($val);
    }
    elsif ($key eq 'inp')
    { $slf->log_input($val);
    }
    elsif ($key eq 'irs')
    { $slf->set_input_record_separator($val);
    }
    elsif ($key eq 'lim')
    { $slf->set_timeout($val);
    }
    elsif ($key eq 'max')
    { $slf->set_buffer_length($val);
    }
    elsif ($key eq 'mod')
    { $slf->set_telnet_mode($val);
    }
    elsif ($key eq 'nxt')
    { $slf->{'_nxt'} = $val
        if defined($val = _parse_prompt($val));
    }
    elsif ($key eq 'opt')
    { $slf->log_options($val);
    }
    elsif ($key eq 'out')
    { $slf->log_output($val);
    }
    elsif ($key eq 'pat')
    { $slf->set_prompt($val);
    }
    elsif ($key eq 'prt')
    { $slf->{'_prt'} = _parse_port($val, $slf->{'_prt'});
    }
    elsif ($key eq 'skp')
    { $slf->set_skip_mode($val);
    }
    elsif (defined($val))
    { $slf->{$key} = $val;
    }
  }

  # Return the object reference
  $slf;
}

sub DESTROY
{
}

# Set initial trace
sub set_trace
{ my ($slf, $lvl) = @_;

  if ($lvl)
  { $slf->log_dump(\*STDOUT)    if $lvl & 1;
    $slf->log_options(\*STDOUT) if $lvl & 2;
  }
}

=head2 S<$h-E<gt>binmode($mode)>

This method indicates whether or not RDA must translate sequences of CR
(C<\015>) anf LF (C<\012>). When the mode is set to a true value, RDA does
not modify the data received or sent. When disabled, it activates the
conversion of carriages returns and line feeds.

Changing binary mode does not effect the data already present in the input
buffer but has an immediate effect on output data, which are not buffered.

It returns the previous mode.

=head2 S<$h-E<gt>binmode>

This method returns the current binary mode.

=cut

sub binmode
{ my ($slf, $mod) = @_;
  my ($old);

  $old = $slf->{'_bin'};
  $slf->{'_bin'} = $mod unless defined($mod);
  $old;
}

=head2 S<$h-E<gt>get_buffer>

This method returns a scalar reference to the reception buffer.

=cut

sub get_buffer
{ \shift->{'_buf'};
}

=head2 S<$h-E<gt>get_input>

This method returns the content of the reception buffer.

=cut

sub get_input
{ shift->{'_buf'};
}

=head2 S<$h-E<gt>get_option_state($option)>

This method returns a copy of the state structure of the specified structure
as a hash reference containing:

=over 26

=item S<    $h->{'rem'}->{'ack'}>

Boolean that indicates that RDA may accept an offer to enable this option on
the remote side

=item S<    $h->{'rem'}->{'flg'}>

Boolean that indicates whether the option is enabled on the remote side

=item S<    $h->{'rem'}->{'sta'}>

String representing the internal state of option negotiation for this
option on the remote side

=item S<    $h->{'loc'}->{'ack'}>

Boolean that indicates that RDA may accept an offer to enable this option on
the local side

=item S<    $h->{'loc'}->{'flg'}>

Boolean that indicates whether the option is enabled on the local side.

=item S<    $h->{'loc'}->{'sta'}>

String representing the internal state of option negotiation for this option
on the local side

=back

=cut

sub get_option_state
{ my ($slf, $opt) = @_;
  my ($rec);

  # Validate the option
  return undef unless defined($opt);
  _parse_option($opt);

  # Define the option on first use
  $rec = exists($slf->{'_opt'}->{$opt})
    ? $slf->{'_opt'}->{$opt}
    : _add_option($slf, $opt);

  # Return a state copy
  {loc => %{$rec->{'loc'}}, rem => %{$rec->{'rem'}}};
}

=head2 S<$h-E<gt>get_print_length>

This method returns the number of bytes effectively sent by the most recent
C<print> or C<put> request.

=cut

sub get_print_length
{ shift->{'_lgt'};
}

=head2 S<$h-E<gt>log_dump($file)>

This method specifies a file name or a file handle to store a dump of the data
exchanges. It returns the previous value.

=head2 S<$h-E<gt>log_dump>

This method disables the log operations and returns the previous value.

=cut

sub log_dump
{ _set_handle('_dfh', @_);
}

=head2 S<$h-E<gt>log_input($file)>

This method specifies a file name or a file handle to store the data received
from the server. It returns the previous value.

=head2 S<$h-E<gt>log_input>

This method disables the input logging and returns the previous value.

=cut

sub log_input
{ _set_handle('_rfh', @_);
}

=head2 S<$h-E<gt>log_options($file)>

This method specifies a file name or a file handle to trace the option
negotiations. It returns the previous value.

=head2 S<$h-E<gt>log_options>

This method disables the option negotiation logging and returns the previous
value.

=cut

sub log_options
{ _set_handle('_ofh', @_);
}

=head2 S<$h-E<gt>log_output($file)>

This method specifies a file name or a file handle to store the data sent to
the server. It returns the previous value.

=head2 S<$h-E<gt>log_output>

This method disables the output logging and returns the previous value.

=cut

sub log_output
{ _set_handle('_sfh', @_);
}

=head2 S<$h-E<gt>set_authen($pwd)>

This method associates a password manager to the object.

=cut

sub set_authen
{ my ($slf, $pwd) = @_;

  $slf->{'_pwd'} = $pwd;
}

=head2 S<$h-E<gt>set_buffer_length([$max])>

This method specifies the maximum size of the reception buffer. It returns the
previous value.

=cut

sub set_buffer_length
{ my ($slf, $max) = @_;
  my ($min, $old);

  $old = $slf->{'_max'};
  $min = 512;
  $slf->{'_max'} = ($max < $min) ? $min : $max
    if defined($max) && $max =~ /^\d+$/;
  $old;
}

=head2 S<$h-E<gt>set_error_mode($mode)>

This method specifies the error mode for the scripting methods. It supports the
following types of arguments:

=over 2

=item *

C<die>, to abort the primitive execution.

=item *

C<return>, to terminate the function execution with an undefined value.

=item *

A reference to a function that is executed in case of error. It exits from the
error context with an undefined value.

=item *

A reference to an array containing a function reference as first element. The
other array elements are passed as first function arguments. It exists from
the error context with an undefined value.

=back

It returns the previous value.

=head2 S<$h-E<gt>set_error_mode>

This method returns the current error mode.

=cut

sub set_error_mode
{ my ($slf, $mod) = @_;
  my ($old);

  $slf->{'_err'} = _parse_error_mode($mod, $old = $slf->{'_err'});
  $old;
}

=head2 S<$h-E<gt>set_input_record_separator($string)>

This method specifies the string representing the input record separator. It
returns the previous value.

=head2 S<$h-E<gt>set_input_record_separator>

It returns the current value.

=head2 S<$h-E<gt>set_irs([$string])>

Synonym of the C<set_input_record_separator> method.

=cut

sub set_input_record_separator
{ my ($slf, $irs) = @_;
  my ($old);

  $slf->{'_irs'} = _parse_input_record_separator($irs, $old = $slf->{'_irs'});
  $old;
}

*set_irs = \&set_input_record_separator;

=head2 S<$h-E<gt>set_option_callback($function)>

This method defines the callback function that is called when a telnet option
is enabled or disabled. RDA executes the callback function in the following
circumstances:

=over 2

=item *

An option becomes enabled on the remote side request and C<accept_options>
had been used to arrange its acceptance.

=item *

The remote side arbitrarily decides to disable an option that is currently
enabled. RDA always accepts a request to disable request coming from the
remote side.

=back

It returns the previous value.

=head2 S<$h-E<gt>set_option_callback>

This method removes any existing function and returns it.

=cut

sub set_option_callback
{ my ($slf, $fct) = @_;
  my ($old);

  $old = delete($slf->{'_ocb'});
  $slf->{'_ocb'} = $fct if ref($fct) eq 'CODE';
  $old;
}

=head2 S<$h-E<gt>set_prompt($pattern)>

This method specifies the pattern to find the prompt in the input stream. It
accepts a string representing a valid Perl C<match> operator. It returns the
previous value.

=head2 S<$h-E<gt>set_prompt>

This method returns the current prompt pattern.

=cut

sub set_prompt
{ my ($slf, $pat) = @_;
  my ($old);

  $slf->{'_pat'} = _parse_prompt($pat, $old = $slf->{'_pat'});
  $old;
}

=head2 S<$h-E<gt>set_skip_mode($mode)>

This method indicates the number of lines to remove from the beginning of the
command response. When you specify C<auto>, the value is derived the C<echo>
option state. It returns the previous value.

=head2 S<$h-E<gt>set_skip_mode>

This method returns the current skip mode.

=cut

sub set_skip_mode
{ my ($slf, $mod) = @_;
  my ($old);

  $slf->{'_skp'} = _parse_skip_mode($mod, $old = $slf->{'_skp'});
  $old;
}

=head2 S<$h-E<gt>set_suboption_callback($function)>

This method specifies a callback function to handle suboptions. Without an
argument, it removes any existing function. It returns the previous value.

=head2 S<$h-E<gt>set_suboption_callback>

This method removes any existing function and returns it.

=cut

sub set_suboption_callback
{ my ($slf, $fct) = @_;
  my ($old);

  $old = delete($slf->{'_scb'});
  $slf->{'_scb'} = $fct if ref($fct) eq 'CODE';
  $old;
}

=head2 S<$h-E<gt>set_telnet_mode($mode)>

This method enables or disables the telnet command interpretation. It returns
the previous value.

=head2 S<$h-E<gt>set_telnet_mode>

This method returns the current telnet mode.

=cut

sub set_telnet_mode
{ my ($slf, $mod) = @_;
  my ($old);

  $old = $slf->{'_mod'};
  $slf->{'_mod'} = $mod if defined($mod);
  $old;
}

=head2 S<$h-E<gt>set_timeout($sec)>

This method specifies the maximum number of seconds to complete a request. A
zero value disables any time limit. It returns the previous value.

=head2 S<$h-E<gt>set_timeout>

This method returns the current timeout value.

=cut

sub set_timeout
{ my ($slf, $lim) = @_;
  my ($old);

  $slf->{'_lim'} = _parse_timeout($lim, $old = $slf->{'_lim'});
  $old;
}

=head1 TELNET COMMANDS

=head2 S<$h-E<gt>accept_options($operation,$option...)>

This method indicates whether to accept or to reject telnet options. It
supports the following operations:

=over 12

=item S<    B<'Do'>>

It will accept an offer to enable the option on the local side.

=item S<    B<'Dont'>>

It will reject an offer to enable the option on the local side.

=item S<    B<'Will'>>

It will accept an offer to enable the option on the remote side.

=item S<    B<'Wont'>>

It will reject an offer to enable the option on the remote side.

=back

C<Do> or C<Will> requires to first define a notification callback, using the
C<set_option_callback> method.

It returns the object reference.

=cut

sub accept_options
{ my ($slf, @arg) = @_;
  my ($act, $opt, @chg);

  # Validate the connection
  die "RDA-01430: Not connected\n" unless exists($slf->{'_srv'});

  # Treat the requests
  while (($act, $opt) = splice(@arg, 0, 2))
  { $act = lc($act);
    if ($act eq 'do')
    { die "RDA-01452: Missing option callback function\n"
        unless exists($slf->{'_ocb'});
      push(@chg, {ack => 1, opt => _parse_option($opt), rem => 0});
    }
    elsif ($act eq 'dont')
    { push(@chg, {ack => 0, opt => _parse_option($opt), rem => 0});
    }
    elsif ($act eq 'will')
    { die "RDA-01452: Missing option callback function\n"
        unless exists($slf->{'_ocb'});
      push(@chg, {ack => 1, opt => _parse_option($opt), rem => 1});
    }
    elsif ($act eq 'wont')
    { push(@chg, {ack => '', opt => _parse_option($opt), rem => 1});
    }
    else
    { die "RDA-01453: Invalid option action \"$act\"\n";
    }
  }
  _accept_options($slf, @chg);

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>collect($report,$command)>

This method sends the specified command and includes in the report the
characters sent back by the command until it matches a command prompt. It
automatically appends the current output record separator to the specified
command, simulating someone typing a command and hitting the return key. It
extracts the lines from the input stream by using the current input record
separator.

Many command interpreters echo back the command sent. In most situations, this
method removes the first line returned from the remote side. See the
C<set_skip_mode> for more controls over this feature.

=head2 S<$h-E<gt>collect($report,$request)>

To alter temporarily some object attributes, you can specify an hash reference
as the argument. It supports following keys:

=over 11

=item S<    B<'ack'> > Acknowledge string (output record separator by default)

=item S<    B<'cln'> > Line cleanup indicator (true by default)

=item S<    B<'cmd'> > Command to execute

=item S<    B<'lim'> > Execution time limit

=item S<    B<'max'> > Maximum command execution time (30 seconds by default)

=item S<    B<'nxt'> > Continuation pattern(s)

=item S<    B<'pat'> > Prompt pattern

=item S<    B<'skp'> > Skip mode

=back

=cut

sub collect
{ my ($slf, $rpt, $def) = @_;
  my ($ack, $buf, $cln, $cmd, $flg, $lim, $max, $nxt, $pat, $ref, $skp, @lin);

  # Validate the connection
  $slf->{'out'} = 0;
  die "RDA-01430: Not connected\n" unless exists($slf->{'_srv'});

  # Parse the command definition
  $slf->{'hit'} = '';
  $ack = $slf->{'ors'};
  $cln = 1;
  $lim = $slf->{'_lim'};
  $max = 30;
  $nxt = $slf->{'_nxt'} if exists($slf->{'_nxt'});
  $pat = $slf->{'_pat'};
  $skp = $slf->{'_skp'};
  $ref = ref($def);
  if ($ref eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'ack')
      { $ack = _parse_string($def->{$key}, 1, $ack);
      }
      elsif ($key eq 'cln')
      { $cln = $def->{$key};
      }
      elsif ($key eq 'cmd')
      { $cmd = $def->{$key};
        $cmd = join(' ', @$cmd) if ref($cmd) eq 'ARRAY';
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $lim);
      }
      elsif ($key eq 'max')
      { $max = _parse_timeout($def->{$key}, $max);
      }
      elsif ($key eq 'nxt')
      { $nxt = _parse_next($def->{$key}, $nxt, $ack);
      }
      elsif ($key eq 'pat')
      { $pat = _parse_prompt($def->{$key}, $pat);
      }
      elsif ($key eq 'skp')
      { $skp = _parse_skip_mode($def->{$key}, $skp);
      }
    }
  }
  elsif ($ref eq 'ARRAY')
  { $cmd = join(' ', @$def);
  }
  else
  { $cmd = $def;
  }
  $skp = $slf->{'_opt'}->{&TELOPT_ECHO}->{'rem'}->{'flg'} if $skp eq 'auto';
  die "RDA-01450: Missing command\n" unless defined($cmd);

  # Collect the command result
  local $slf->{'_err'} = 'return';
  local $slf->{'_lim'} = $lim;
  if ($slf->print($cmd))
  { $flg = 1 if $skp;
    $lim = time() + $max if $max;
    $nxt = [[$nxt, $ack]] unless ref($nxt) || !defined($nxt);
    for (;;)
    { # Treat lines already received
      if (@lin = $slf->getlines({all => 0,
                                 cmd => 0,
                                 lim => 0}))
      {if ($flg > 0)
       { shift(@lin);
         $flg = 0;
       }
       elsif ($flg)
       { $lin[0] =~ s/^(\r\s*\r|\010+\s+\010+)//;
         $flg = 0;
       }
       foreach my $lin (@lin)
       { $lin =~ s/^[\r\000]+// if $cln;
         $rpt->write($lin."\n");
       }
      }

      # Detect prompts
      $buf = $slf->{'_buf'};
      if (defined($ack = _check_next($buf, $nxt)))
      { $slf->{'_buf'} = '';
        return 2 unless $slf->put($ack);
        $flg = -1;
      }
      elsif (eval "\$buf =~ $pat")
      { $slf->{'_buf'} = '';
        return 0
      }

      # Detect timeout
      if ($max && time() >= $lim)
      { $slf->{'_buf'} = '';
        unless ($flg > 0)
        { $buf =~ s/^(\r\s*\r|\010+\s+\010+)// if $flg;
          $buf =~ s/^[\r\000]+//               if $cln;
          $rpt->write($buf."\n") if length($buf);
        }
        $slf->quit;
        return -1;
      }
      sleep(1);
    }
  }

  # Indicate a command error
  return 1;
}

sub _check_next
{ my ($buf, $nxt) = @_;

  if (ref($nxt))
  { foreach my $rec (@$nxt)
    { return $rec->[1] if eval "\$buf =~ $rec->[0]";
    }
  }
  undef;
}

=head2 S<$h-E<gt>command($string)>

This method sends the specified command and reads the characters sent back by
the command until it matches a command prompt. It automatically appends the
current output record seprator to the specified command, simulating someone
typing a command and hitting the return key. It extracts the lines from the
input stream by using the current input record separator. The returned lines
do no longer contain the input record separator.

Many command interpreters echo back the command sent. In most situations, this
method removes the first line returned from the remote side. See the
C<set_skip_mode> for more controls over this feature.

In a list context, it returns the line list. Otherwise, it returns a reference
to an array containing the command output lines.

=head2 S<$h-E<gt>command($request)>

To alter temporarily some object attributes, you can specify an hash reference
as the argument. It supports following keys:

=over 11

=item S<    B<'buf'> > Use a line buffer to store and return the result.

=item S<    B<'cmd'> > Command to execute

=item S<    B<'irs'> > Input record separator

=item S<    B<'lim'> > Execution time limit

=item S<    B<'ors'> > Output record separator

=item S<    B<'out'> > Array, hash, or scalar reference to store the result

=item S<    B<'pat'> > Prompt pattern

=item S<    B<'skp'> > Skip mode

=back

In a list context, it returns the line list, which is empty in case of
failure. Otherwise, it returns an undefined value in case of failure or a
reference to the command output, an array reference by default.

=cut

sub command
{ my ($slf, $def) = @_;
  my ($beg, $cmd, $dat, $dst, $end, $hit, $irs, $lgt, $lim, $mod, $opt, $ors,
      $out, $pat, $ref, $skp);

  # Validate the connection
  $slf->{'out'} = 0;
  die "RDA-01430: Not connected\n" unless exists($slf->{'_srv'});

  # Parse the command definition
  $slf->{'hit'} = '';
  $irs = $slf->{'_irs'};
  $lim = $slf->{'_lim'};
  $ors = $slf->{'ors'};
  $out = [];
  $pat = $slf->{'_pat'};
  $skp = $slf->{'_skp'};
  $ref = ref($def);
  if ($ref eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'buf')
      { $dst = 'Buffer';
      }
      elsif ($key eq 'cmd')
      { $cmd = $def->{$key};
        $cmd = join(' ', @$cmd) if ref($cmd) eq 'ARRAY';
      }
      elsif ($key eq 'irs')
      { $irs = _parse_input_record_separator($def->{$key}, $irs);
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $lim);
      }
      elsif ($key eq 'out')
      { $out = $def->{$key} if ($dst = ref($def->{$key})) eq 'ARRAY';
      }
      elsif ($key eq 'ors')
      { $ors = $def->{$key};
        $ors = "\n" unless defined($ors);
      }
      elsif ($key eq 'pat')
      { $pat = _parse_prompt($def->{$key}, $pat);
      }
      elsif ($key eq 'skp')
      { $skp = _parse_skip_mode($def->{$key}, $skp);
      }
    }
  }
  elsif ($ref eq 'ARRAY')
  { $cmd = join(' ', @$def);
  }
  else
  { $cmd = $def;
  }
  die "RDA-01450: Missing command\n" unless defined($cmd);

  # Send command and wait for the prompt
  local $slf->{'_err'} = 'return';
  local $slf->{'_lim'} = $lim;
  $slf->{'msg'} = '';
  unless ($slf->put($cmd.$ors) and ($hit, $dat) = $slf->wait_for($pat))
  { $slf->{'msg'} = 'RDA-01451: Command timeout' if $slf->{'out'};
    return () if wantarray;
    return undef;
  }
  $slf->{'hit'} = $hit;

  # Extract the lines not preserving the input record separator
  $lgt = length($irs);
  for ($beg = 0 ; ($end = index($dat, $irs, $beg)) > -1 ; $beg = $end + $lgt)
  { push(@$out, substr($dat, $beg, $end - $beg));
  }
  push(@$out, substr($dat, $beg)) if $beg < length($dat);

  # Eliminate command echo
  $skp = $slf->{'_opt'}->{&TELOPT_ECHO}->{'rem'}->{'flg'} if $skp eq 'auto';
  shift(@$out) while $skp--;

  # Return command output
  if ($dst)
  { return RDA::Object::Buffer->new($def->{'buf'} ? 'L' : 'l', $out)
      if $dst eq 'Buffer';
    $dat = $def->{'out'};
    if ($dst eq 'SCALAR')
    { $$dat = @$out ? join($irs, @$out, '') : '';
    }
    elsif ($dst eq 'HASH')
    { %$dat = @$out;
    }
    return $dat;
  }
  return @$out if wantarray;
  return $out;
}

=head2 S<$h-E<gt>empty_buffer>

This method clears the reception buffer.

=cut

sub empty_buffer
{ shift->{'_buf'} = '';
}

=head2 S<$h-E<gt>exit>

This method closes the socket associated with the object. It returns the object
reference.

=cut

sub exit
{ my ($slf) = @_;

  $slf->{'eoc'} = $slf->{'eof'} = 1;
  close(delete($slf->{'_srv'})) if exists($slf->{'_srv'});
  $slf->{'_opt'} = {};

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>login($username,$password[,$request])>

This method performs a login by waiting for a login prompt and responding with
the specified user name, then waiting for the password prompt and responding
with the specified password, and finally waiting for the command interpreter
prompt.

The login prompt must match either of these case insensitive patterns:

    /login[: ]*$/i
    /username[: ]*$/i

The password prompt must match this case insensitive pattern:

    /password[: ]*$/i

The current prompt pattern must match the command interpreter prompt.

When any of those prompts sent by the remote side do not match what is
expected, this method will time out, unless the timeout mechanism is disabled.

To alter temporarily some object attributes, you can specify an hash reference
as an argument. It supports following keys:

=over 11

=item S<    B<'chk'> > Banner check pattern

=item S<    B<'dis'> > Disconnection command

=item S<    B<'lim'> > Execution time limit

=item S<    B<'pat'> > Prompt pattern

=item S<    B<'pwd'> > User password

=item S<    B<'try'> > Maximum number of login attempts (2 per default)

=item S<    B<'usr'> > User name

=back

It returns the object reference on successful completion. Otherwise, it stores
the error message and returns an undefined value.

=head2 S<$h-E<gt>login($request)>

Since you can specify the user name and password in the request hash, you can
omit the two first arguments when specifying a request argument.

=cut

sub login
{ my ($slf, $usr, $pwd, $def) = @_;
  my ($chk, $dis, $lim, $hit, $ors, $pat, $ref, $str, $try);

  # Validate the connection
  $slf->{'out'} = 0;
  die "RDA-01430: Not connected\n" unless exists($slf->{'_srv'});

  # Parse the request definition
  $lim = $slf->{'_lim'};
  $ors = $slf->{'ors'};
  $pat = $slf->{'_pat'};
  $try = 2;
  if ($ref = ref($usr))
  { $def = $usr;
    $usr = $pwd = undef;
  }
  elsif ($ref = ref($pwd))
  { $def = $pwd;
    $pwd = undef;
  }
  else
  { $ref = ref($def);
  }
  if ($ref eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'chk')
      { $chk = _parse_prompt($def->{$key}, $pat);
      }
      elsif ($key eq 'dis')
      { $dis = $str if defined($str = $def->{$key}) && $str =~ m/^\w/;
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $lim);
      }
      elsif ($key eq 'pat')
      { $pat = _parse_prompt($def->{$key}, $pat);
      }
      elsif ($key eq 'pwd')
      { $pwd = '' unless defined($pwd = $def->{$key});
      }
      elsif ($key eq 'try')
      { $try = $str if defined($str = $def->{$key}) && $str =~ m/^\d+$/;
      }
      elsif ($key eq 'usr')
      { $usr = '' unless defined($usr = $def->{$key});
      }
    }
  }
  die "RDA-01455: Missing user name\n" unless defined($usr);
  if (exists($slf->{'_pwd'}))
  { $str = $slf->{'_hst'};
    $pwd = defined($pwd)
      ? $slf->{'_pwd'}->set_password('host', $str, $usr, $pwd)
      : $slf->{'_pwd'}->get_password('host', $str, $usr,
          "Enter password for user $usr on host $str:", '');
  }
  die "RDA-01456: Missing user password\n" unless defined($pwd);
  local $slf->{'_lim'} = $lim;

  # Wait for an initial prompt
  $slf->{'hit'} = '';
  ($hit, $str) = $slf->wait_for(pat => 'm/input[: ]*$/i',
                                pat => 'm/login[: ]*$/i',
                                pat => 'm/username[: ]*$/i',
                                pat => 'm/password[: ]*$/i',
                                pat => $pat,
                                err => 'return');
  return undef unless defined($hit);

  # Treat the banner
  if  (defined($chk))
  { $str =~ s/.+$//;
    unless (eval "\$str =~ $chk")
    { $slf->{'msg'} = 'RDA-01458: Invalid device';
      return undef;
    }
    $slf->{'txt'} = $str;
  }

  # Return when no login is requested
  unless ($hit =~ m/(input|login|username|password)[: ]*$/i)
  { $slf->{'hit'} = $hit;
    $slf->{'dis'} = $dis if defined($dis);
    return $slf;
  }

  # Perform the login
  for (; $try > 0 ; --$try)
  { # Treat the prompt
    unless ($hit =~ m/password[: ]*$/i)
    { # Send the user name
      _sleep(0.01);
      return undef unless $slf->put({str => $usr.$ors, err => 'return'});

      # Wait for the password prompt
      ($hit) = $slf->wait_for(pat => 'm/password[: ]*$/i',
                              pat => $pat,
                              err => 'return');
      return undef unless defined($hit);

      # Return when no password is expected
      unless ($hit =~ m/password[: ]*$/i)
      { $slf->{'hit'} = $hit;
        $slf->{'dis'} = $dis if defined($dis);
        return $slf;
      }
    }

    # Send the user password
    _sleep(0.01);
    return undef unless $slf->put({str => $pwd.$ors, err => 'return'});

    # Wait for command prompt or another login prompt
    ($hit) = $slf->wait_for(pat => 'm/input[: ]*$/i',
                            pat => 'm/login[: ]*$/i',
                            pat => 'm/username[: ]*$/i',
                            pat => $pat,
                            err => 'return');
    return undef unless defined($hit);

    # Return when expected prompt is detected
    unless ($hit =~ m/(input|login|username)[: ]*$/i)
    { $slf->{'hit'} = $hit;
      $slf->{'dis'} = $dis if defined($dis);
      return $slf;
    }
  }

  # Report the login problem
  $slf->{'msg'} = 'RDA-01457: Invalid user and password combination';
  undef;
}

=head2 S<$h-E<gt>open([$host[,$port[,$timeout]]])>

This method opens a TCP connection to remote side. When the host or the port
are not specified as arguments, it uses their current object values.

Timeouts do not work for this method on machines where C<alarm()> is not
implemented.

It returns the object reference on successful completion. Otherwise, it stores
the error message and returns an undefined value.

=cut

sub open
{ my ($slf, $hst, $prt, $lim) = @_;
  my ($adr, $err, $srv, $val);

  # Close any previous connection
  $slf->exit;

  # Determine the host name and the service port
  if (defined($hst))
  { $slf->{'_hst'} = $hst;
  }
  else
  { $hst = $slf->{'_hst'};
  }
  $slf->{'_prt'} = $prt = _parse_port($prt, $slf->{'_prt'});

  # Determine the time limit
  eval {alarm(0)};
  $lim = $@ ? 0 : _parse_timeout($lim, $slf->{'_lim'});

  # Connect to the server
  $slf->{'out'} = 0;
  eval {
    local $SIG{'__DIE__'} = 'DEFAULT';
    local $SIG{ALRM}      = sub { die "Alarm\n" } if $lim;
    alarm($lim) if $lim;

    $adr = inet_aton($hst)
      or die "RDA-01432: Unknown remote host \"$hst\"\n";
    $srv = gensym;
    socket($srv, AF_INET, SOCK_STREAM, 0)
      or die "RDA-01433: Cannot create socket:\n$!\n";
    connect($srv, sockaddr_in($prt, $adr))
      or die "RDA-01434: Cannot connect to \"$hst:$prt\":\n$!\n";
    };
  alarm(0) if $lim;

  # Handle errors
  if ($slf->{'msg'} = $@)
  { close($srv) if defined($srv);
    if ($slf->{'msg'} =~ m/^Alarm/)
    { $slf->{'out'} = 1;
      $slf->{'msg'} = $adr
        ? "RDA-01435: Timeout in connection to \"$hst:$prt\""
        : "RDA-01436: Timeout in \"$hst\" name lookup";
    }
    return undef;
  }

  # Update the object
  $slf->{'eoc'} = $slf->{'_cmd'} ? 1 : 0;
  $slf->{'eof'} = 0;
  $slf->{'lin'} = '';
  $slf->{'out'} = 0;
  $slf->{'_alt'} = '';
  $slf->{'_buf'} = '';
  $slf->{'_chg'} = '';
  $slf->{'_lgt'} = 0;
  $slf->{'_siz'} = _check_block_size((stat $srv)[11]);
  $slf->{'_srv'} = $srv;
  vec($slf->{'_msk'} = '', fileno($srv), 1) = 1;
  delete($slf->{'_not'});

  # Do not buffer writes
  select((select($srv), $| = 1)[$[]);

  # Accept echo and suppress go aheads from the server
  _accept_options($slf, {opt => &TELOPT_ECHO, ack => 1, rem => 1},
                        {opt => &TELOPT_SGA,  ack => 1, rem => 1});

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>quit>

This method sends the disconnection command and closes the socket associated
with the object. It returns the object reference.

=cut

sub quit
{ my ($slf) = @_;

  # Send the disconnection command
  $slf->print(delete($slf->{'dis'}))
    if exists($slf->{'dis'}) && exists($slf->{'_srv'});

  # Close the socket and return the object reference
  $slf->exit;
}

=head1 TELNET SCRIPTING METHODS

=head2 S<$h-E<gt>break>

This method sends the telnet break character, which is a signal outside the
ASCII character set.

It returns C<1> on success, or performs the error mode action on failure.

=cut

sub break
{ my ($slf) = @_;
  my ($cmd);

  # Validate the connection
  $slf->{'out'} = 0;
  return $slf->error("RDA-01430: Not connected") unless exists($slf->{'_srv'});

  # Send the telnet command
  $cmd = "\377\363";
  _put($slf, \$cmd, "break");
}

=head2 S<$h-E<gt>eof>

This method indicates whether an end of file has been detected.

=cut

sub eof
{ shift->{'eof'};
}

=head2 S<$h-E<gt>error(@msg)>

This method concatenates all arguments into a string, stores it in the object
as the error message, and performs the error mode action. It returns an
undefined value when the error mode does not cause the program to die.

=head2 S<$h-E<gt>error>

This method returns the last error message.

=cut

sub error
{ my ($slf, @msg) = @_;
  my ($fct, $mod, $msg, @arg);

  return $slf->{'msg'} unless @msg;

  # Store the error message
  $msg = join('', @msg);
  $msg =~ s/[\n\r\s]+$//;
  $slf->{'msg'} = $msg;

  # Trigger the error action as defined in the error mode
  $mod = $slf->{'_err'};
  if (ref($mod) eq 'ARRAY')
  { ($fct, @arg) = @$mod;
    &$fct(@arg, $msg);
  }
  elsif ($mod ne 'return')
  { die "$msg\n";
  }
  undef;
}

=head2 S<$h-E<gt>fatal(@msg)>

This method closes the connection before invoking the C<error> method.

=cut

sub fatal
{ my ($slf, @msg) = @_;

  $slf->exit;
  $slf->error(@msg);
}

=head2 S<$h-E<gt>get([$request])>

This method reads a block of data from the object and returns it along
with any buffered data. When no buffered data is available, it will wait for
data to read using the current time limit. When buffered data is available, it
checks for a block of data that can be immediately read.

It returns an undefined value on end of file conditions. It performs the error
mode action on timeout or other failures, When the error mode is not set to
C<die>, you can use the C<eof> method to differentiate end of fille from other
errors.

You can alter temporarily some object attributes by specifying an hash
reference as the argument. It supports following keys:

=over 11

=item S<    B<'bin'> > Binary mode

=item S<    B<'err'> > Error mode

=item S<    B<'mod'> > Telnet mode

=item S<    B<'lim'> > Execution time limit

=back

=cut

sub get
{ my ($slf, $def) = @_;
  my ($bin, $buf, $end, $err, $lim, $mod);

  # Validate the connection
  $slf->{'out'} = 0;
  return undef if $slf->{'eof'} || $slf->{'eoc'};

  # Parse the request definition
  $lim = $slf->{'_lim'};
  if (ref($def) eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'bin')
      { $bin = $def->{$key};
        $bin = 0 unless defined($bin);
      }
      elsif ($key eq 'err')
      { $err = _parse_error_mode($def->{$key}, $err);
      }
      elsif ($key eq 'mod')
      { $mod = $def->{$key};
        $mod = 0 unless defined($mod);
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $lim);
      }
    }
  }
  local $slf->{'_err'} = $err if defined($err);
  local $slf->{'_bin'} = $bin if defined($bin);
  local $slf->{'_mod'} = $mod if defined($mod);

  # Determine the end time
  $end = _get_end_time($lim);

  # Send pending option changes
  _send_options($slf) if length($slf->{'_chg'});

  # Fill data that is already available
  { local $slf->{'_err'} = 'return';
    $slf->{'msg'} = '';
    _fill_buffer($slf, 0);
  }
  return $slf->error($slf->{'msg'})
    if $slf->{'out'} && defined($lim) && $lim == 0 && !length($slf->{'_buf'});
  if ($slf->{'msg'} and !$slf->{'out'})
  { return $slf->error($slf->{'msg'}) unless length($slf->{'_buf'});
    $slf->{'_not'} = $slf->{'msg'};
  }

  # When buffer is empty, wait for data
  $slf->{'out'} = 0;
  $slf->{'msg'} = '';
  unless (length($slf->{'_buf'}) || _fill_buffer($slf, $end))
  { $slf->exit unless $slf->{'out'};
    return undef;
  }

  # Extract buffer content
  $buf = $slf->{'_buf'};
  $slf->{'_buf'} = '';
  $buf;
}

=head2 S<$h-E<gt>getline([$request])>

This method extracts the next line from the reception buffer, using the input
record separator. The returned line does not contain this separator. When a
line is not available, it waits for a line or a timeout.

It returns an undefined value on end of file conditions. It performs the error
mode action on timeout or other failures, When the error mode is not set to
C<die>, you can use the C<eof> method to differentiate end of fille from other
errors.

You can alter temporarily some object attributes by specifying an hash
reference as the argument. It supports following keys:

=over 11

=item S<    B<'bin'> > Binary mode

=item S<    B<'cmd'> > Command mode

=item S<    B<'err'> > Error mode

=item S<    B<'irs'> > Input record separator

=item S<    B<'lim'> > Execution time limit

=item S<    B<'mod'> > Telnet mode

=item S<    B<'pat'> > Prompt pattern

=back

=cut

sub getline
{ my ($slf, $def) = @_;
  my ($bin, $cmd, $end, $err, $lgt, $lin, $off, $pat, $pos, $irs, $mod, $lim);

  # Validate the connection
  $slf->{'out'} = 0;
  return undef if $slf->{'eof'} || $slf->{'eoc'};

  # Parse the request definition
  $cmd = $slf->{'_cmd'};
  $irs = $slf->{'_irs'};
  $lim = $slf->{'_lim'};
  $pat = $slf->{'_pat'};
  if (ref($def) eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'bin')
      { $bin = $def->{$key};
        $bin = 0 unless defined($bin);
      }
      elsif ($key eq 'cmd')
      { $cmd = $def->{$key};
        $cmd = 0 unless defined($mod);
      }
      elsif ($key eq 'err')
      { $err = _parse_error_mode($def->{$key}, $err);
      }
      elsif ($key eq 'irs')
      { $irs = _parse_input_record_separator($def->{$key}, $irs);
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $lim);
      }
      elsif ($key eq 'mod')
      { $mod = $def->{$key};
        $mod = 0 unless defined($mod);
      }
      elsif ($key eq 'pat')
      { $pat = _parse_prompt($def->{$key}, $pat);
      }
    }
  }
  local $slf->{'_bin'} = $bin if defined($bin);
  local $slf->{'_err'} = $err if defined($err);
  local $slf->{'_mod'} = $mod if defined($mod);

  # Sending pending option changes
  $end = _get_end_time($lim);
  _send_options($slf) if length($slf->{'_chg'});

  # Keep reading into buffer until end-of-line is detected
  $off = 0;
  while (($pos = index($slf->{'_buf'}, $irs, $off)) == -1)
  { $off = length($slf->{'_buf'});
    if ($cmd && eval "\$slf->{'_buf'} =~ $pat")
    { $slf->{'hit'} = $slf->{'_buf'};
      $slf->{'eoc'} = 1;
      $slf->{'_buf'} = '';
      return undef;
    }
    unless (_fill_buffer($slf, $end))
    { return undef if $slf->{'out'};
      $lin = $slf->{'_buf'} if length($slf->{'_buf'});
      $slf->{'_buf'} = '';
      $slf->exit;
      return $lin;
    };
  }

  # Extract the line from buffer
  $lin = substr($slf->{'_buf'}, 0, $pos);
  substr($slf->{'_buf'}, 0, $pos + length($irs)) = '';
  $lin;
}

=head2 S<$h-E<gt>getlines([$request])>

This method reads and returns all the lines until it encounters an end of file
condition. It uses the input record separator to extract the lines.

It returns an empty list on end of file conditions. It performs the error
mode action on timeout or other failures, When the error mode is not set to
C<die>, you can use the C<eof> method to differentiate end of fille from other
errors.

You can alter temporarily some object attributes by specifying an hash
reference as the argument. It supports following keys:

=over 11

=item S<    B<'all'> > All line indicator (true by default)

=item S<    B<'bin'> > Binary mode

=item S<    B<'cmd'> > Command mode

=item S<    B<'err'> > Error mode

=item S<    B<'irs'> > Input record separator

=item S<    B<'lim'> > Execution time limit

=item S<    B<'mod'> > Telnet mode

=item S<    B<'pat'> > Prompt pattern

=back

When C<all> has a false value, it returns only the lines that are currently
available.

=cut

sub getlines
{ my ($slf, $def) = @_;
  my ($all, $bin, $cmd, $err, $irs, $lgt, $lim, $lin, $mod, $pat, $pos, @lin);

  # Validate the connection
  $slf->{'out'} = 0;
  return () if $slf->{'eof'} || $slf->{'eoc'};

  # Parse the request definition
  $all = 1;
  if (ref($def) eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'all')
      { $all = $def->{$key};
      }
      elsif ($key eq 'bin')
      { $bin = $def->{$key};
        $bin = 0 unless defined($bin);
      }
      elsif ($key eq 'cmd')
      { $cmd = $def->{$key};
        $cmd = 0 unless defined($mod);
      }
      elsif ($key eq 'err')
      { $err = _parse_error_mode($def->{$key}, $err);
      }
      elsif ($key eq 'irs')
      { $irs = _parse_input_record_separator($def->{$key}, $slf->{'_irs'});
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $slf->{'_lim'});
      }
      elsif ($key eq 'mod')
      { $mod = $def->{$key};
        $mod = 0 unless defined($mod);
      }
      elsif ($key eq 'pat')
      { $pat = _parse_prompt($def->{$key}, $pat);
      }
    }
  }
  local $slf->{'_bin'} = $bin if defined($bin);
  local $slf->{'_cmd'} = $cmd if defined($cmd);
  local $slf->{'_err'} = $err if defined($err);
  local $slf->{'_irs'} = $irs if defined($irs);
  local $slf->{'_lim'} = $lim if defined($lim);
  local $slf->{'_mod'} = $mod if defined($mod);
  local $slf->{'_pat'} = $pat if defined($pat);

  # Extract lines
  if ($all)
  { # Get all lines until end of file
    push(@lin, $lin) while defined($lin = $slf->getline);
  }
  elsif (defined($lin = $slf->getline))
  { # Save the first line
    push(@lin, $lin);

    # Extract subsequent lines present in the buffer
    $lgt = length($irs = $slf->{'_irs'});
    while (($pos = index($slf->{'_buf'}, $irs)) != -1)
    { push(@lin, substr($slf->{'_buf'}, 0, $pos));
      substr($slf->{'_buf'}, 0, $pos + $lgt) = '';
    }
  }

  # Return the lines
  @lin;
}

=head2 S<$h-E<gt>print($arg...)>

This method sends argument list followed by the output record separator to the
remote site and returns C<1> if all data was successfully written. It adds a
output field separartor between each argument. It performs the error mode
action on timeout or other failures.

=cut

sub print
{ my ($slf, @arg) = @_;
  my ($buf, $fh);

  # Validate the connection
  $slf->{'out'} = 0;
  return $slf->error("RDA-01430: Not connected") unless exists($slf->{'_srv'});

  # Add field and record separators
  $buf = join($slf->{'ofs'}, @arg).$slf->{'ors'};

  # Log the output when requested
  _log_write($slf->{'_sfh'}, $buf) if exists($slf->{'_sfh'});

  # Convert native newlines to CR LF
  $buf =~ s/\n/\015\012/g unless $slf->{'_bin'};

  # Send the string
  $slf->{'eoc'} = $slf->{'out'} = 0;
  _encode(\$buf) if $slf->{'_mod'};
  _put($slf, \$buf, "print");
}

=head2 S<$h-E<gt>put($string)>

This method send the specified string to the remote side and returns C<1> on
successful completion. This method is like C<print()> except that it does not
write the trailing output record separator. On timeout or other failures, it
performs the error mode action.

On failure, you can use C<get_print_length> to determine how much data was
written before the error occurred.

=head2 S<$h-E<gt>put($request)>

You can alter temporarily some object attributes by specifying an hash
reference as the argument. It supports following keys:

=over 11

=item S<    B<'bin'> > Binary mode

=item S<    B<'err'> > Error mode

=item S<    B<'lim'> > Execution time limit

=item S<    B<'mod'> > Telnet mode

=item S<    B<'str'> > String to send

=back

=cut

sub put
{ my ($slf, $def) = @_;
  my ($bin, $buf, $err, $lim, $mod);

  # Validate the connection
  $slf->{'out'} = 0;
  return $slf->error("RDA-01430: Not connected") unless exists($slf->{'_srv'});

  # Parse the request definition
  if (ref($def) eq 'HASH')
  { foreach my $key (keys(%$def))
    { if ($key eq 'bin')
      { $bin = $def->{$key};
        $bin = 0 unless defined($bin);
      }
      elsif ($key eq 'err')
      { $err = _parse_error_mode($def->{$key}, $slf->{'_err'});
      }
      elsif ($key eq 'lim')
      { $lim = _parse_timeout($def->{$key}, $slf->{'_lim'});
      }
      elsif ($key eq 'mod')
      { $mod = $def->{$key};
        $mod = 0 unless defined($mod)
      }
      elsif ($key eq 'str')
      { $buf = $def->{$key};
      }
    }
  }
  else
  { $buf = $def;
  }
  return 0 unless defined($buf) && length($buf);
  local $slf->{'_bin'} = $bin if defined($bin);
  local $slf->{'_err'} = $err if defined($err);
  local $slf->{'_lim'} = $lim if defined($lim);
  local $slf->{'_mod'} = $mod if defined($mod);

  # Log the output when requested
  _log_write($slf->{'_sfh'}, $buf) if exists($slf->{'_sfh'});

  # Convert native newlines to CR LF
  $buf =~ s/\n/\015\012/g unless $slf->{'_bin'};

  # Send the string
  $slf->{'eoc'} = $slf->{'out'} = 0;
  _encode(\$buf) if $slf->{'_mod'};
  _put($slf, \$buf, "print");
}

=head2 S<$h-E<gt>timeout(@msg)>

This method sets the timeout indicator before invoking the C<error> method.

=cut

sub timeout
{ my ($slf, @msg) = @_;

  $slf->{'out'} = 1;
  $slf->error(@msg);
}

=head2 S<$h-E<gt>wait_for($match)>

This method reads the input stream until finding a pattern match or string. It
removes all characters before and including the match from the reception buffer.

In a list context, it returns the matched characters and the characters before
the match. In a scalar context, it discards all those characters and returns
C<1>. It performs the the error mode action on timeout, end of file condition,
or other failures.

=head2 S<$h-E<gt>wait_for(key =E<gt> value...)>

You can specify more than one pattern or string, and you can alter temporarily
some object attributes by specifying key-value pairs as arguments. It supports
following keys:

=over 11

=item S<    B<'bin'> > Binary mode

=item S<    B<'err'> > Error mode

=item S<    B<'lim'> > Execution time limit

=item S<    B<'mod'> > Telnet mode

=item S<    B<'pat'> > Valid perl C<match> operator

=item S<    B<'str'> > Substring to find

=back

=cut

sub wait_for
{ my ($slf, @arg) = @_;
  my ($bin, $cod, $end, $err, $lgt, $hit, $key, $lim, $mod, $pos, $pre, $val,
      @cnd, @msg);

  # Validate the request
  $slf->{'out'} = 0;
  return undef if $slf->{'eof'};

  # Parse the request definition
  $lim = $slf->{'_lim'};
  while (($key, $val) = splice(@arg, 0, 2))
  { if ($key eq 'bin')
    { $bin = $val;
      $bin = 0 unless defined($bin);
    }
    elsif ($key eq 'err')
    { $err = _parse_error_mode($val, $slf->{'_err'});
    }
    elsif ($key eq 'lim')
    { $lim = _parse_timeout($val, $lim);
    }
    elsif ($key eq 'mod')
    { $mod = $val;
      $mod = 0 unless defined($mod);
    }
    elsif ($key eq 'pat')
    { die "RDA-01463: Expecting a match operation \"$val\"\n"
        unless $val =~ m/^\s*\// || $val =~ m/^\s*m\s*\W/;
      push(@cnd, $WAIT_BEG_PAT.$val.$WAIT_END_PAT);
    }
    elsif ($key eq 'str')
    { $val =~ s/'/\\'/g;
      push(@cnd,
        $WAIT_BEG_STR."'$val'".$WAIT_MID_STR.length($val).$WAIT_END_STR);
    }
    elsif (defined($val))
    { next;
    }
    elsif ($key =~ m/^\s*\// || $key =~ m/^\s*m\s*\W/)
    { push(@cnd, $WAIT_BEG_PAT.$key.$WAIT_END_PAT);
    }
  }
  return undef unless @cnd;
  local $slf->{'_err'} = $err if defined($err);
  local $slf->{'_bin'} = $bin if defined($bin);
  local $slf->{'_mod'} = $mod if defined($mod);

  # Construct a loop to fill the buffer until found, timeout, or end of file
  $cod = '
    for (;;)
    { '.join('      els', @cnd).'
      unless (_fill_buffer($slf, $end))
      { $slf->exit unless $slf->{"out"};
        last;
      }
    }';

  # Execute the loop
  $end = _get_end_time($lim);
  { local $^W = 1;
    local $SIG{"__WARN__"} = sub {push(@msg, @_)};
    local $slf->{'_err'} = 'return';
    $slf->{'msg'} = '';
    eval $cod;
  }
  return $slf->error("RDA-01464: Timeout in pattern match") if $slf->{'out'};
  return $slf->error($slf->{'msg'})                         if $slf->{'msg'};
  return $slf->error("RDA-01465: EOF in pattern match")     if $slf->{'eof'};
  return $slf->error($@)                                    if $@;
  return $slf->error(join("\n", @msg))                      if @msg;

  # Indicate the completion status
  return ($hit, $pre) if wantarray;
  1;
}

#--- Parsing routines ---------------------------------------------------------

# Parse the error mode
sub _parse_error_mode
{ my ($err, $dft) = @_;
  my ($ref);

  return $dft unless defined($err);
  if ($ref = ref($err))
  { return [$err] if $ref eq 'CODE';
    return $err   if $ref eq 'ARRAY' && ref($err->[0]) eq 'CODE';
    die "RDA-01441: Invalid reference \"$err\" specified as error mode\n";
  }
  return lc($1) if $err =~ /^\s*(die|return)\s*$/i;
  die "RDA-01440: Invalid error mode \"$err\"\n";
}

# Parse the input record separator string
sub _parse_input_record_separator
{ my ($irs, $dft) = @_;

  return $dft unless defined($irs);
  die "RDA-01446: Null input record separator\n" unless length($irs);
  $irs;
}

# Parse the continuation pattern(s)
sub _parse_next
{ my ($nxt, $dft, $ors) = @_;
  my ($ack, $str, @nxt, @tbl);

  return _parse_prompt($nxt, $dft) unless ref($nxt) eq 'ARRAY';
  @tbl = @$nxt;
  while (($str, $ack) = splice(@tbl, 0, 2))
  { push(@nxt, [$str, _parse_string($ack, 1, $ors)])
      if defined(_parse_prompt($str));
  }
  @nxt ? [@nxt] : undef;
}

# Parse the option
sub _parse_option
{ my ($opt) = @_;

  die "RDA-01444: Invalid telnet option \"$opt\"\n"
    unless $opt && $opt =~ m/^\d+$/ && $opt <= 255;
  $opt;
}

# Parse the service port number
sub _parse_port
{ my ($prt, $dft) = @_;
  my ($nam, $old);

  return $dft unless defined($prt);
  unless ($prt =~ /^\d+$/)
  { $nam = $prt;
    $prt = getservbyname($nam, 'tcp')
      or die "RDA-01443: Invalid TCP service \"$nam\"\n";
  }
  $prt;
}

# Parse the prompt pattern
sub _parse_prompt
{ my ($pat, $dft) = @_;
  my ($buf, $slf, @msg);

  return $dft unless defined($pat);
  die "RDA-01460: Expecting a match as prompt \"$pat\"\n"
    unless $pat =~ m(^\s*/) || $pat =~ m(^\s*m\s*\W);
  { local $^W = 1;
    local $SIG{"__WARN__"} = sub {push(@msg, @_)};

    $slf = {eof => 1, _buf => ''};
    eval $TEST_BEG_PAT.$pat.$TEST_END_PAT;
  }
  die "RDA-01461: Error when compiling pattern \"$pat\":\n$@\n"       if $@;
  die join("\n",
    "RDA-01462: Warnings when compiling pattern \"$pat\":", @msg, '') if @msg;
  $pat;
}

# Parse the skip mode
sub _parse_skip_mode
{ my ($mod, $dft) = @_;

  return $dft unless defined($mod);
  return $1   if $mod =~ /^\s*(auto|\d+)\s*$/i;
  die "RDA-01442: Invalid skip mode \"$mod\"\n";
}

# Parse a string
sub _parse_string
{ my ($str, $min, $dft) = @_;

  ref($str)                               ? $dft :
  (defined($str) && length($str) >= $min) ? $str :
                                            $dft;
}

# Parse the timeout value
sub _parse_timeout
{ my ($lim, $dft) = @_;

  return $dft unless defined($lim);
  die "RDA-01445: Invalid timeout \"$lim\"/n" unless $lim =~ m/^-?\d+$/;
  ($lim > 0) ? $lim : 0;
}

#--- Option routines ----------------------------------------------------------

# Indicate how to accept an option
sub _accept_options
{ my ($slf, @req) = @_;
  my ($cnt, $opt, $tbl);

  $cnt = 0;
  $tbl = $slf->{'_opt'};
  foreach my $req (@req)
  { $opt = $req->{opt};
    _add_option($slf, $opt) unless exists($tbl->{$opt});
    $tbl->{$opt}->{$req->{rem} ? 'rem' : 'loc'}->{'ack'} = $req->{'ack'};
    ++$cnt;
  }
  $cnt;
}

# Add a new option and initialize it
sub _add_option
{ my ($slf, $opt) = @_;

  $slf->{'_opt'}->{$opt} = {
    loc => {ack => 0, flg => 0, sta => 'no'},
    rem => {ack => 0, flg => 0, sta => 'no'}};
}

# Adjust option by invoking the callback function
sub _adjust_option
{ my ($slf, $opt, $rem, $new, $old, $pos) = @_;
  my ($fct);

  # Keep track of remote echo
  if ($rem and $opt == &TELOPT_ECHO)
  { if ($new and !$old)     # Echo activated
    { $slf->{'_ech'} = 1;
    }
    elsif (!$new and $old)  # Echo suppressed
    { $slf->{'_ech'} = 0;
    }
  }

  # Invoke the callback function when present
  &{$slf->{'_ocb'}}($slf, $opt, $rem, $new, $old, $pos)
    if exists($slf->{'_ocb'});
}

# Disable an option
sub _disable_option
{ my ($slf, $opt, $req, $rec, $pos, $sta) = @_;
  my ($ack, $flg, $nak, $rem);

  # Determine the corresponding command
  if ($req eq "wont")
  { $rem = 1;
    $ack = ['DO',   "\377\375".pack('C', $opt)];
    $nak = ['DONT', "\377\376".pack('C', $opt)];
    _log_option($slf->{'_ofh'}, 'R', 'WONT', $opt) if exists($slf->{'_ofh'});
  }
  elsif ($req eq "dont")
  { $rem = 0;
    $ack = ['WILL', "\377\373".pack('C', $opt)];
    $nak = ['WONT', "\377\374".pack('C', $opt)];
    _log_option($slf->{'_ofh'}, 'R', 'DONT', $opt) if exists($slf->{'_ofh'});
  }
  else
  { return;
  }

  # Save the current enabled state
  $flg = $rec->{'flg'};
  $sta = $rec->{'sta'};

  # Respond to WONT or DONT based on the current negotiation state
  if ($sta eq 'no')                   # Already disabled
  {
  }
  elsif ($sta eq 'yes')               # Initially disabled
  { $rec->{'flg'} = 0;
    $rec->{'sta'} = 'no';
    $slf->{'_chg'} .= $nak->[1];
    _log_option($slf->{'_ofh'}, 'S', $nak->[0], $opt)
      if exists($slf->{'_ofh'});
    _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
  }
  elsif ($sta eq "wantyes"           # Received a negative acknowledge
    ||   $sta eq "wantyes opposite"  # Now want to disable
    ||   $sta eq "wantno")           # Received a positive acknowledge
  { $rec->{'flg'} = 0;
    $rec->{'sta'} = 'no';
    _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
  }
  elsif ($sta eq "wantno opposite")  # Now want to enable
  { $rec->{'flg'} = 0;
    $rec->{'sta'} = "wantyes";
    $slf->{'_chg'} .= $ack->[1];
    _log_option($slf->{'_ofh'}, 'S', $ack->[0], $opt)
      if exists($slf->{'_ofh'});
    _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
  }
}

# Enable an option
sub _enable_option
{ my ($slf, $opt, $req, $rec, $pos) = @_;
  my ($ack, $flg, $nak, $rem, $sta);

  # Determine the corresponding command
  if ($req eq "will")
  { $rem = 1;
    $ack = ['DO',   "\377\375".pack('C', $opt)];
    $nak = ['DONT', "\377\376".pack('C', $opt)];
    _log_option($slf->{'_ofh'}, 'R', 'WILL', $opt) if exists($slf->{'_ofh'});
  }
  elsif ($req eq "do")
  { $rem = 0;
    $ack = ['WILL', "\377\373".pack('C', $opt)];
    $nak = ['WONT', "\377\374".pack('C', $opt)];
    _log_option($slf->{'_ofh'}, 'R', 'DO', $opt) if exists($slf->{'_ofh'});
  }
  else
  { return;
  }

  # Save the current enabled state
  $flg = $rec->{'flg'};
  $sta = $rec->{'sta'};

  # Respond to WILL or DO based on the current negotiation state
  if ($sta eq 'no')                   # Initiating enable
  { if ($rec->{'ack'})  # Agree to enable
    { $rec->{'flg'} = 1;
      $rec->{'sta'} = 'yes';
      $slf->{'_chg'} .= $ack->[1];
      _log_option($slf->{'_ofh'}, 'S', $ack->[0], $opt)
        if exists($slf->{'_ofh'});
      _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
    }
    else                # Disagree to enable
    { $slf->{'_chg'} .= $nak->[1];
      _log_option($slf->{'_ofh'}, 'S', $nak->[0], $opt)
        if exists($slf->{'_ofh'});
    }
  }
  elsif ($sta eq 'yes')               # State already enabled
  {
  }
  elsif ($sta eq 'wantno')            # Our disable request answered by enable
  { $rec->{'flg'} = 0;
    $rec->{'sta'} = 'no';
    _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
  }
  elsif ($sta eq 'wantno opposite'    # Disable request answered by enable
    ||   $sta eq 'wantyes')           # Positive acknowledege
  { $rec->{'flg'} = 1;
    $rec->{'sta'} = 'yes';
    _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
  }
  elsif ($sta eq 'wantyes opposite')  # Want now to disable
  { $rec->{'flg'} = 1;
    $rec->{'sta'} = "wantno";
    $slf->{'_chg'} .= $nak->[1];
    _log_option($slf->{'_ofh'}, 'S', $nak->[0], $opt)
      if exists($slf->{'_ofh'});
    _adjust_option($slf, $opt, $rem, $rec->{'flg'}, $flg, $pos);
  }
}

# Process the option
sub _process_option
{ my ($slf, $req, $opt, $pos) = @_;

  # Define the option on first use
  _add_option($slf, $opt) unless exists($slf->{'_opt'}->{$opt});

  # Process the option
  if ($req eq "\376")     # DONT
  { _disable_option($slf, $opt, 'dont', $slf->{'_opt'}->{$opt}->{'loc'}, $pos);
  }
  elsif ($req eq "\375")  # DO
  { _enable_option($slf, $opt, 'do', $slf->{'_opt'}->{$opt}->{'loc'}, $pos);
  }
  elsif ($req eq "\374")  # WONT
  { _disable_option($slf, $opt, 'wont', $slf->{'_opt'}->{$opt}->{'rem'}, $pos);
  }
  elsif ($req eq "\373")  # WILL
  { _enable_option($slf, $opt, 'will', $slf->{'_opt'}->{$opt}->{'rem'}, $pos);
  }
  else
  { die "RDA-01454: Invalid option request\n";
  }
}

# Send the pending option changes
sub _send_options
{ my ($slf) = @_;
  my ($chg);

  $chg = $slf->{'_chg'};
  $slf->{'_chg'} = '';
  { local $slf->{'_err'} = 'return';
    local $slf->{'_lim'} = 0;
    $slf->{'_chg'} .= substr($chg, $slf->{'_lgt'})
      unless _put($slf, \$chg, 'telnet option negotiation');
  }
}

#--- Internal routines --------------------------------------------------------

# Determine the optimal block size
sub _check_block_size
{ my ($blk) = @_;
  local $^W = '';  # Avoid non-numeric warning for Windows block size of ''

  (defined($blk) && $blk >= 1 && $blk <= 1048576) ? $blk : 8192;
}

# Decode carriage returns
sub _decode
{ my ($slf, $off) = @_;
  my ($chr);

  while (($off = index($slf->{'_buf'}, "\015", $off)) > -1)
  { $chr = substr($slf->{'_buf'}, ++$off, 1);
    if (!length($chr))      # Save trailing CR for possible conversion
    { last unless $slf->{'_mod'} or !$slf->{'_bin'};
      $slf->{'_alt'} .= "\015";
      chop($slf->{'_buf'});
    }
    elsif ($chr eq "\000")  # Convert CR NULL to CR when in telnet mode
    { substr($slf->{'_buf'}, $off, 1) = '' if $slf->{'_mod'};
    }
    elsif ($chr eq "\012")  # Convert CR LF to newline when not in binary mode
    { substr($slf->{'_buf'}, $off - 1, 2) = "\n" unless $slf->{'_bin'};
    }
  }
}

# Escape telnet IAC and carriage returns not followed by a line feed
sub _encode
{ my ($str) = @_;
  my ($chr, $off);

  $$str =~ s/\377/\377\377/g;
  for ($off = 0 ; ($off = index($$str, "\015", $off)) > -1 ; ++$off)
  { $chr = substr($$str, $off + 1, 1);
    substr($$str, $off, 1) = "\015\000" unless $chr && $chr eq "\012";
  }
}

# Extract telnet commands from the data
sub _extract_commands
{ my ($slf, $off) = @_;
  my ($chr, $cmd, $end, $opt, $pos);

  # Parse telnet commands in the buffer
  $pos = $off;
  while (($pos = index($slf->{'_buf'}, "\377", $pos)) > -1)
  { # Get the command code
    $chr = substr($slf->{'_buf'}, $pos + 1, 1);

    # Save a partial command
    unless (length($chr))
    { $slf->{'_alt'} .= "\377";
      chop $slf->{'_buf'};
      last;
    }

    # Treat the command
    if ($chr eq "\377")       # Convert \377 characters
    { substr($slf->{'_buf'}, $pos++, 1) = '';
    }
    elsif ($chr eq "\375" ||
           $chr eq "\373" ||
           $chr eq "\374" ||
           $chr eq "\376")    # Negotiate an option
    { $opt = substr($slf->{'_buf'}, $pos + 2, 1);

      # Save a partial command
      unless (length($opt))
      { $slf->{'_alt'} .= "\377".$chr;
        chop $slf->{'_buf'};
        chop $slf->{'_buf'};
        last;
      }

      # Remove the command from the buffer and process it
      substr($slf->{'_buf'}, $pos, 3) = '';
      _process_option($slf, $chr, ord($opt), $pos);
    }
    elsif ($chr eq "\372")   # Start of subnegotiation parameters
    { # Save a partial command
      $end = index($slf->{'_buf'}, "\360", $pos);
      if ($end < 0)
      { $slf->{'_alt'} .= substr($slf->{'_buf'}, $pos);
        substr($slf->{'_buf'}, $pos) = '';
        last;
      }

      # Remove the subnegotiation command from the buffer
      $cmd = substr($slf->{'_buf'}, $pos, $end - $pos + 1);
      substr($slf->{'_buf'}, $pos, $end - $pos + 1) = '';

      # Invoke the subnegotiation callback function when defined
      if (ref($slf->{'_scb'}) eq 'CODE' && length($cmd) > 4)
      { my ($lgt, @par);

        $opt = unpack 'C', substr($cmd, 2, 1);
        $lgt = length($cmd);
        @par = (substr($cmd, 3, $lgt - 5)) if $lgt > 5;
        &{$slf->{'_scb'}}($slf, $opt, @par);
      }
    }
    else  # Skip other telnet command
    { substr($slf->{'_buf'}, $pos, 2) = '';
    }
  }

  # Send pending option changes
  _send_options($slf) if length($slf->{'_chg'});
}

# Fill the buffer
sub _fill_buffer
{ my ($slf, $end) = @_;
  my ($fnd, $lgt, $lim, $msg, $msk, $nxt, $off, $out);

  # Return unreported error from a prevous read
  return $slf->error(delete($slf->{'_not'})) if exists($slf->{'_not'});
  return undef if $slf->{'eof'};

  for (;;)
  { # Check the buffer size
    return $slf->error("RDA-01470: Maximum reception buffer length exceeded")
      unless length($slf->{'_buf'}) <= $slf->{'_max'};

    # Determine how long to wait for input ready
    ($out, $lim) = _get_timeout($end);
    return $slf->timeout("RDA-01471: Fill timeout") if $out;

    # Wait for input
    $fnd = select($msk = $slf->{'_msk'}, '', '', $lim);
    if (!defined($fnd))
    { next if $! =~ /^interrupted/i;
      return $slf->fatal("RDA-01472: Select error:\n$!");
    }
    return $slf->timeout("RDA-01473: Select timeout") unless $fnd;

    # Append to buffer any partially processed telnet or CR sequence
    if ($lgt = length($slf->{'_alt'}))
    { $slf->{'_buf'} .= $slf->{'_alt'};
      $slf->{'_alt'} = '';
    }

    # Read available data
    $off = length($slf->{'_buf'});
    $nxt = $off - $lgt;
    $lgt = sysread($slf->{'_srv'}, $slf->{'_buf'}, $slf->{'_siz'}, $off);
    unless (defined($lgt))
    { next if $! =~ /^interrupted/i; # restart interrupted syscall
      return $slf->fatal("RDA-01474: Read error:\n$!");
    }
    if ($lgt == 0)
    { $slf->exit;
      return 0;
    }

    # Display network traffic when requested
    _log_dump('<', $slf->{'_dfh'}, \$slf->{'_buf'}, $off)
      if exists($slf->{'_dfh'});

    # Process telnet commands contained in the buffer
    _extract_commands($slf, $nxt)
      if $slf->{'_mod'} && index($slf->{'_buf'}, "\377", $nxt) > -1;

    # Decode carriage-return sequences in the buffer
    _decode($slf, $nxt);

    # Read again when all characters were consumed as telnet commands
    if ($nxt < length($slf->{'_buf'}))
    { # Log the input when requested
      _log_write($slf->{'_rfh'}, substr($slf->{'_buf'}, $nxt))
        if exists($slf->{'_rfh'});

      # Save the last line read
      _save_last_line($slf);

      # Indicate the successful completion
      return 1;
    }
  }
}

# Determine the end time
sub _get_end_time
{ my ($lim) = @_;

  ($lim > 0) ? time + $lim + 1 : undef;
}

# Determine remaining time
sub _get_timeout
{ my ($end) = @_;
  my ($lim);

  # Treat unlimited and immediate conditions
  return (0, $end) unless defined($end) && $end != 0;

  # Indicate the current status
  $lim = $end - time;
  return (0, $lim) if $lim > 0;
  return (1, 0);
}

# Dump data
sub _log_dump
{ my ($dir, $ofh, $dat, $off, $lgt) = @_;
  my ($adr, $hex, $txt);

  $adr = 0;
  $lgt = length($$dat) - $off unless defined($lgt);
  if ($lgt > 0)
  { for (; $lgt > 0 ; $adr += 16, $off += 16, $lgt -= 16)
    { $txt = substr($$dat, $off, ($lgt >= 16) ? 16 : $lgt);
      $hex = sprintf($DUMP_FMT,
        unpack($DUMP_MSK, unpack('H*', $txt).$DUMP_SPC));
      $txt =~ s/[\000-\037\177-\237]/./g;
      _log_write($ofh, sprintf("%s 0x%5.5lx: %s%s\n", $dir, $adr, $hex, $txt));
    }
    _log_write($ofh, "\n");
  }
}

# Dump option negotiation
sub _log_option
{ my ($ofh, $dir, $req, $opt) = @_;

  _log_write($ofh, join(' ', $dir, $req, 
    ($opt < 0 || $opt > $#TELOPTS) ? $opt : $TELOPTS[$opt])."\n");
}

# Log text
sub _log_write
{ my ($ofh, $buf) = @_;

  syswrite($ofh, $buf, length($buf));
}

# Send data
sub _put
{ my ($slf, $buf, $typ) = @_;
  my ($end, $lgt, $fnd, $msk, $off, $out, $lim, $ret, $try);

  # Initialization
  $slf->{'_lgt'} = 0;
  $end = _get_end_time($slf->{'_lim'});
  $lgt = length($$buf);
  $off = 0;
  $try = 10;

  # Send pending option changes
  _send_options($slf) if length($slf->{'_chg'});

  # Write whole data
  while ($lgt)
  { # Check for remaining time
    ($out, $lim) = _get_timeout($end);
    return $slf->timeout("RDA-01475: $typ / Timed-out") if $out;

    # Wait for output ready
    $fnd = select('', $msk = $slf->{'_msk'}, '', $lim);
    unless (defined($fnd))
    { next if $! =~ /^interrupted/i;
      return $slf->fatal("RDA-01476: $typ / Write error:\n$!");
    }
    return $slf->timeout("RDA-01475: $typ / Timed-out") unless $fnd;

    # Write the data
    $ret = syswrite($slf->{'_srv'}, $$buf, $lgt, $off);
    unless (defined($ret))
    { next if $! =~ /^interrupted/i;
      return $slf->fatal("RDA-01476: $typ / Write error:\n$!");
    }
    if ($ret == 0)
    { # Retry several time to write the data
      if ($try-- > 0)
      { _sleep(0.01);
        next;
      }
      return $slf->fatal("RDA-01477: $typ / Zero length write:\n$!");
    }

    # Display the network traffic when requested
    _log_dump('>', $slf->{'_dfh'}, $buf, $off, $ret)
      if exists($slf->{'_dfh'});

    # Increment
    $slf->{'_lgt'} += $ret;
    $lgt -= $ret;
    $off += $ret;
  }
  1;
}

# Save the last line
sub _save_last_line
{ my ($slf) = @_;
  my ($beg, $end, $irs, $lgt, $lin, $off);

  $irs = $slf->{'_irs'};
  if (($end = rindex($slf->{'_buf'}, $irs)) > -1)
  { $lgt = length($irs);
    for (;; $end = $off)
    { # Find the beginning of the last line
      $off = rindex($slf->{'_buf'}, $irs, $end - 1);
      $beg = ($off < 0) ? 0 : $off + $lgt;

      # Save the line when not blank
      if ($end > $beg)
      { $lin = substr($slf->{'_buf'}, $beg, $end - $beg);
        unless ($lin =~ /^\s*$/)
        { $slf->{'lin'} = $lin;
          last;
        }
      }

      # Halt at the beginning of the buffer
      last if $off < 0;
    }
  }
}

# Define a log handle
sub _set_handle
{ my ($key, $slf, $ofh) = @_;
  my ($pth);

  # Validate the argument
  return $slf->{$key}         unless defined($ofh);
  return delete($slf->{$key}) unless ref($ofh) || length($ofh);

  # Open a new handle when the argument is a filename
  no strict "refs";
  unless (ref($ofh) || defined(fileno($ofh)))
  { $pth = $ofh;
    $ofh = IO::File->new;
    $ofh->open($pth, $CREATE, $FIL_PERMS)
      or die "RDA-01431: Cannot create log file $pth:\n$!\n";
  }

  # Save and return the log handle
  $slf->{$key} = $ofh;
}

# Sleep a fraction of seconds
sub _sleep
{ my ($sec) = @_;
  my ($msk);
  local *SLP;

  socket(SLP, AF_INET, SOCK_STREAM, 0);
  vec($msk = '', fileno(SLP), 1) = 1;
  select($msk, '', '', $sec);
  close(SLP);
}

#--- Exported Constants -------------------------------------------------------

# Control functions (RFC 854)
sub TELNET_IAC()   { 255 }; # Interpret as command
sub TELNET_DONT()  { 254 }; # Ask to no longer perform the option
sub TELNET_DO()    { 253 }; # Indicate that the option is expected
sub TELNET_WONT()  { 252 }; # Refuse to perform the option
sub TELNET_WILL()  { 251 }; # indicate the desire to perform the option
sub TELNET_SB()    { 250 }; # Start subnegotiation parameters
sub TELNET_GA()    { 249 }; # Go ahead
sub TELNET_EL()    { 248 }; # Erase line
sub TELNET_EC()    { 247 }; # Erase character
sub TELNET_AYT()   { 246 }; # Are you there
sub TELNET_AO()    { 245 }; # Abort output
sub TELNET_IP()    { 244 }; # Interrupt process
sub TELNET_BRK()   { 243 }; # Break
sub TELNET_DM()    { 242 }; # Data mark
sub TELNET_NOP()   { 241 }; # No operation
sub TELNET_SE()    { 240 }; # End of subnegotiation parameters
sub TELNET_EOR()   { 239 }; # End of record (transparent mode)
sub TELNET_ABORT() { 238 }; # Abort process
sub TELNET_SUSP()  { 237 }; # Suspend process
sub TELNET_EOF()   { 236 }; # End of file
sub TELNET_SYNCH() { 242 }; # Sync

# Options
sub TELOPT_BINARY()         { 0 };   # Binary transmission (RFC 856)
sub TELOPT_ECHO()           { 1 };   # Echo (RFC 857)
sub TELOPT_RCP()            { 2 };   # Reconnection
sub TELOPT_SGA()            { 3 };   # Suppress go ahead (RFC 858)
sub TELOPT_NAMS()           { 4 };   # Approx message size negotiation
sub TELOPT_STATUS()         { 5 };   # Status (RFC 859)
sub TELOPT_TM()             { 6 };   # Timing mark (RFC 860)
sub TELOPT_RCTE()           { 7 };   # Remote controlled trans and echo
sub TELOPT_NAOL()           { 8 };   # Output line width
sub TELOPT_NAOP()           { 9 };   # Output page size
sub TELOPT_NAOCRD()         { 10 };  # Output carriage return disposition
sub TELOPT_NAOHTS()         { 11 };  # Output horizontal tab stops
sub TELOPT_NAOHTD()         { 12 };  # Output horizontal tab disposition
sub TELOPT_NAOFFD()         { 13 };  # Output formfeed disposition
sub TELOPT_NAOVTS()         { 14 };  # Output vertical tab stops
sub TELOPT_NAOVTD()         { 15 };  # Output vertical tab disposition
sub TELOPT_NAOLFD()         { 16 };  # Output linefeed disposition
sub TELOPT_XASCII()         { 17 };  # Extended ASCII RFC 698)
sub TELOPT_LOGOUT()         { 18 };  # Logout (RFC 727)
sub TELOPT_BM()             { 19 };  # Byte macro (RFC 735)
sub TELOPT_DET()            { 20 };  # Data entry terminal (RFC 1043)
sub TELOPT_SUPDUP()         { 21 };  # SUPDUP (RFC 736)
sub TELOPT_SUPDUPOUTPUT()   { 22 };  # SUPDUP output (RFC 749)
sub TELOPT_SNDLOC()         { 23 };  # Send location (RFC 779)
sub TELOPT_TTYTYPE()        { 24 };  # Terminal type (RFC 1091)
sub TELOPT_EOR()            { 25 };  # End of record (RFC 885)
sub TELOPT_TUID()           { 26 };  # TACACS user identification (RFC 927)
sub TELOPT_OUTMRK()         { 27 };  # Output marking (RFC 933)
sub TELOPT_TTYLOC()         { 28 };  # Terminal location number (RFC 946)
sub TELOPT_3270REGIME()     { 29 };  # Telnet 3270 regime (RFC 1141)
sub TELOPT_X3PAD()          { 30 };  # X.3 PAD (RFC 1053)
sub TELOPT_NAWS()           { 31 };  # Negotiate about window size (RFC 1073)
sub TELOPT_TSPEED()         { 32 };  # Terminal speed (RFC 1079)
sub TELOPT_LFLOW()          { 33 };  # Remote flow control (RFC 1372)
sub TELOPT_LINEMODE()       { 34 };  # Linemode (RFC 1184)
sub TELOPT_XDISPLOC()       { 35 };  # X display location (RFC 1096)
sub TELOPT_OLD_ENVIRON()    { 36 };  # Environment option (RFC 1408)
sub TELOPT_AUTHENTICATION() { 37 };  # Authentication option (RFC 2951)
sub TELOPT_ENCRYPT()        { 38 };  # Encryption option (RFC 2946)
sub TELOPT_NEW_ENVIRON()    { 39 };  # New environment option (RFC 1572)
sub TELOPT_TN3270E          { 40 };  # Telnet 3270E option (RFC 2355)
sub TELOPT_XAUTH            { 41 };  # Xauth
sub TELOPT_CHARSET          { 42 };  # Charset option (RFC 2066)
sub TELOPT_TRSP             { 43 };  # Telnet remote serial port
sub TELOPT_COM_PORT         { 44 };  # COM port control option (RFC 2217)
sub TELOPT_TSLE             { 45 };  # Telnet suppress local echo
sub TELOPT_TSTLS            { 46 };  # Telnet start TLS
sub TELOPT_KERMIT           { 47 };  # Kermit option (RFC 2840)
sub TELOPT_EXOPL()          { 255 }; # Extended options list (RFC 861)

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
