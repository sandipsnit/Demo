# Xml.pm: Class Used for XML Macros

package RDA::Library::Xml;

# $Id: Xml.pm,v 2.6 2012/04/25 06:35:03 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Xml.pm,v 2.6 2012/04/25 06:35:03 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Library::Xml - Class Used for XML Macros

=head1 SYNOPSIS

require RDA::Library::Xml;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Xml> class are used to interface with XML
macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Xml;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $XML = 'RDA::Object::Xml';

my %tb_fct = (
  'setXmlTrace'    => [\&_m_trace,       'N'],
  'xmlAttributes'  => [\&_m_attrs,       'L'],
  'xmlContent'     => [\&_m_content,     'L'],
  'xmlData'        => [\&_m_data,        'T'],
  'xmlDisable'     => [\&_m_disable,     'O'],
  'xmlError'       => [\&_m_error,       'N'],
  'xmlExists'      => [\&_m_exists,      'N'],
  'xmlFind'        => [\&_m_find,        'L'],
  'xmlLoadCommand' => [\&_m_load_cmd,    'O'],
  'xmlLoadFile'    => [\&_m_load_file,   'O'],
  'xmlName'        => [\&_m_name,        'T'],
  'xmlNormalize'   => [\&_m_normalize,   'O'],
  'xmlParser'      => [\&_m_parser,      'O'],
  'xmlStatCommand' => [\&_m_stat_cmd,    'N'],
  'xmlType'        => [\&_m_type,        'T'],
  'xmlValue'       => [\&_m_value,       'T'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Xml-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Xml> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'err' > > Last command exit code

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'trc' > > XML trace flag

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of XML requests timed out

=item S<    B<'_req'> > Number of XML requests

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    err  => 0,
    lim  => _chk_alarm($agt->get_setting('RDA_TIMEOUT', 30)),
    trc  => $agt->get_setting('XML_TRACE', 0),
    _agt => $agt,
    _out => 0,
    _req => 0,
    }, ref($cls) || $cls;

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

This method resets the statistics and clears corresponding module settings.

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
  { # Get the statistics record
    $use = $slf->{'_agt'}->get_usage;
    $use->{'XML'} = {not => '', out => 0, req => 0}
      unless exists($use->{'XML'});
    $use = $use->{'XML'};

    # Indicate the current timeout when there is no other note
    $slf->{'_not'} = 'Command execution limited to '.$slf->{'lim'}.'s'
      unless $use->{'not'} || $slf->{'_not'} || $slf->{'lim'} <= 0;

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

=head1 XML MACROS

=head2 S<xmlAttributes($xml)>

This macro returns the list of node attributes.

=cut

sub _m_attrs
{ my ($slf, $ctx, $xml) = @_;
  my @tbl;

  if (ref($xml) eq $XML)
  { @tbl = grep {m/^[^-]/} keys(%$xml);
  }
  sort @tbl;
}

=head2 S<xmlContent($xml[,$flt])>

This macro returns the list of child nodes after resolving the conditions. The
second argument specifies the list of child types to consider. By default, it
returns all child nodes.

=cut

sub _m_content
{ my ($slf, $ctx, $xml, $flt) = @_;
  my @tbl;

  return () unless ref($xml) eq $XML;
  $xml->get_content($flt);
}

=head2 S<xmlData($xml)>

This macro extracts the texts and CDATA elements contained in the specified
node. It returns an empty string when it cannot find any data.

=cut

sub _m_data
{ my ($slf, $ctx, $xml) = @_;

  (ref($xml) eq $XML) ? $xml->get_data : '';
}

=head2 S<xmlError($xml)>

This macro returns the number of parsing errors.

=cut

sub _m_error
{ my ($slf, $ctx, $xml) = @_;

  (ref($xml) eq $XML) ? $xml->get_error : 0;
}

=head2 S<xmlExists($xml,$attr)>

This macro indicates whether the attribute exists in the specified node.

=cut

sub _m_exists
{ my ($slf, $ctx, $xml, $key, $dft) = @_;

  ref($xml) eq $XML && $xml->exists($key);
}

=head2 S<xmlFind($xml,$qry)>

This macro performs the query on the XML object. It returns the result as an
object list.

=cut

sub _m_find
{ my ($slf, $ctx, $xml, $qry) = @_;
  my (@tbl);

  return () unless ref($xml) eq $XML;
  $xml->find($qry);
}

=head2 S<xmlLoadCommand($cmd[,$inc[,$xml]])>

This macro parses the XML produced by the specified command. It stores the
effective command exit code and is accessible through the C<xmlStatCommand>
macro. It returns the resulting XML object.

You can increase the execution limit by specifying an increasing factor as an
argument. A negative value disables any timeout.

You can specify a parser as an argument to control what information is
extracted.

=cut

sub _m_load_cmd
{ my ($slf, $ctx, $cmd, $inc, $xml) = @_;
  my ($err, $lim, $pid);

  $xml = RDA::Object::Xml->new($slf->{'trc'}) unless ref($xml) eq $XML;

  $slf->{'err'} = 0;
  ++$slf->{'_req'};
  local $SIG{'__WARN__'} = sub { };
  if ($cmd && ($pid = open(IN, "$cmd |")))
  { eval {
      $lim = $slf->_get_alarm($inc);
      local $SIG{'ALRM'} = sub { die "Alarm\n"; } if $lim;

      # Load the command result, taking care on end of lines
      alarm($lim) if $lim;
      while (<IN>)
      { $xml->parse($_);
      }
      alarm(0) if $lim;
    };
    RDA::Object::Rda->kill_child($pid) if ($err = $@) && $pid;
    close(IN);
    $slf->{'err'} = $?;

    # Log the timeout
    $slf->_log_timeout($ctx, $cmd) if $err;
  }

  $xml;
}

=head2 S<xmlLoadFile($fil[,$xml])>

This macro parses an XML file and returns the resulting XML object. You can
specify a parser as an argument to control what information is extracted.

=cut

sub _m_load_file
{ my ($slf, $ctx, $fil, $xml) = @_;

  $xml = RDA::Object::Xml->new($slf->{'trc'}) unless ref($xml) eq $XML;
  $xml->parse_file($fil);
}

=head2 S<xmlName($xml)>

This macro returns the node name when defined. Otherwise, it returns an
undefined value.

=cut

sub _m_name
{ my ($slf, $ctx, $xml) = @_;

  (ref($xml) eq $XML) ? $xml->get_name : undef;
}

=head2 S<xmlStatCommand()>

This macro returns the exit code of the last XML command.

=cut

sub _m_stat_cmd
{ shift->{'err'};
}

=head2 S<xmlType($xml)>

This macro returns the node type.

=cut

sub _m_type
{ my ($slf, $ctx, $xml) = @_;

  (ref($xml) eq $XML) ? $xml->get_type : undef;
}

=head2 S<xmlValue($xml,$attr[,$dft])>

This macro returns the value of the attribute in the specified node. When not
defined, it returns the default value.

=cut

sub _m_value
{ my ($slf, $ctx, $xml, $key, $dft) = @_;

  (ref($xml) eq $XML) ? $xml->get_value($key, $dft) : $dft;
}

=head1 PARSER MACROS

=head2 S<setXmlTrace([$lvl])>

This macro sets the XML parsing level:

=over 7

=item B<    0 > No trace

=item B<    1 > Trace the XML parsing

=back

The level is unchanged if a new level is not defined.

It returns the previous level.

=cut

sub _m_trace
{ my ($slf, $ctx, $lvl) = @_;
  my $old;

  $old = $slf->{'trc'};
  $slf->{'trc'} = $lvl if defined($lvl);
  $old;
}

=head2 S<xmlDisable($xml[,$flt])>

This macro indicates the list of child types to ignore. When the list is
empty, it disables any type filtering. It returns the parser object reference.

=cut

sub _m_disable
{ my ($slf, $ctx, $xml, $flt) = @_;

  (ref($xml) eq $XML) ? $xml->disable($flt) : undef;
}

=head2 S<xmlNormalize($xml,$typ)>

This macro indicates how RDA must normalize the texts. It returns the parser
object reference.

=cut

sub _m_normalize
{ my ($slf, $ctx, $xml, $typ) = @_;

  return undef unless ref($xml) eq $XML;
  $xml->normalize_text($typ);
  $xml;
}

=head2 S<xmlParser()>

This macro initializes a new XML parser and returns its reference.

=cut

sub _m_parser
{ my ($slf, $ctx) = @_;

  RDA::Object::Xml->new($slf->{'trc'});
}

# --- Internal routines -------------------------------------------------------

# Check if alarm is implemented
sub _chk_alarm
{ my ($lim) = @_;

  return 0 unless $lim > 0;
  eval {alarm(0);};
  $@ ? 0 : $lim;
}

# Get the alarm duration
sub _get_alarm
{ my ($slf, $val) = @_;

  return $slf->{'lim'} unless defined($val);
  return 0 unless $slf->{'lim'} > 0 && $val > 0;
  $val *= $slf->{'lim'};
  ($val > 1) ? int($val) : 1;
}

# Log a timeout event
sub _log_timeout
{ my $slf = shift;
  my $ctx = shift;

  $slf->{'err'} = -1;
  $slf->{'_agt'}->log_timeout($ctx, 'XML', @_);
  ++$slf->{'_out'};
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Xml|RDA::Object::Xml>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
