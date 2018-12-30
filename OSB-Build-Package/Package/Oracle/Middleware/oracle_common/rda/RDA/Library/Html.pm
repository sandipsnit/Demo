# Html.pm: Class Used for HTML Macros

package RDA::Library::Html;

# $Id: Html.pm,v 2.4 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Html.pm,v 2.4 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Html - Class Used for HTML Macros

=head1 SYNOPSIS

require RDA::Library::Html;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Html> class are used to interface with HTML
macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Html;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $HTML = 'RDA::Object::Html';

my %tb_fct = (
  'htmlAttributes'   => [\&_m_attrs,     'L'],
  'htmlContent'      => [\&_m_content,   'L'],
  'htmlDisable'      => [\&_m_disable,   'O'],
  'htmlExists'       => [\&_m_exists,    'N'],
  'htmlFilter'       => [\&_m_filter,    'O'],
  'htmlFind'         => [\&_m_find,      'L'],
  'htmlFix'          => [\&_m_fix,       'N'],
  'htmlLoadFile'     => [\&_m_load_file, 'O'],
  'htmlLoadResponse' => [\&_m_load_rsp,  'O'],
  'htmlName'         => [\&_m_name,      'T'],
  'htmlParser'       => [\&_m_parser,    'O'],
  'htmlError'        => [\&_m_error,     'N'],
  'htmlTable'        => [\&_m_table,     'L'],
  'htmlText'         => [\&_m_text,      'T'],
  'htmlType'         => [\&_m_type,      'T'],
  'htmlValue'        => [\&_m_value,     'T'],
  'setHtmlTrace'     => [\&_m_trace,     'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Html-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Html> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'trc' > > HTML trace flag

=item S<    B<'_agt'> > Reference to the agent object

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    trc  => $agt->get_setting('HTML_TRACE', 0),
    _agt => $agt,
    }, ref($cls) || $cls;

  # Setup some parameters by default
 
  # Register the macros
  $agt->register($slf, [keys(%tb_fct)]);

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

=head1 HTML MACROS

=head2 S<htmlAttributes($htm)>

This macro returns the list of node attributes.

=cut

sub _m_attrs
{ my ($slf, $ctx, $htm) = @_;
  my @tbl;

  return () unless ref($htm) eq $HTML;
  $htm->get_attr;
}

=head2 S<htmlContent($htm[,$flt[,$cln]])>

This macro returns the list of child nodes after resolving the conditions. The
second argument specifies the list of child types to consider. The third
argument specifies a regular expression to identify objects that must be
replaced by their content. By default, it returns all child nodes.

=cut

sub _m_content
{ my ($slf, $ctx, $htm, $flt, $cln) = @_;
  my @tbl;

  return () unless ref($htm) eq $HTML;
  $htm->get_content($flt, $cln);
}

=head2 S<htmlError($htm)>

This macro returns the number of parsing errors.

=cut

sub _m_error
{ my ($slf, $ctx, $htm) = @_;

  (ref($htm) eq $HTML) ? $htm->get_error : 0;
}

=head2 S<htmlExists($htm,$attr)>

This macro indicates whether the attribute exists in the specified node.

=cut

sub _m_exists
{ my ($slf, $ctx, $htm, $key, $dft) = @_;

  ref($htm) eq $HTML && $htm->exists($key);
}

=head2 S<htmlFind($htm,$qry)>

This macro performs the query on the HTML object. It returns the result as an
object list.

=cut

sub _m_find
{ my ($slf, $ctx, $htm, $qry) = @_;

  return () unless ref($htm) eq $HTML;
  $htm->find($qry);
}

=head2 S<htmlLoadFile($fil[,$htm])>

This macro parses a HTML file and returns the resulting HTML object. You can
specify a parser as an argument to control what information is extracted.

=cut

sub _m_load_file
{ my ($slf, $ctx, $fil, $htm) = @_;

  $htm = RDA::Object::Html->new($slf->{'trc'}) unless ref($htm) eq $HTML;
  $htm->parse_file($fil);
}

=head2 S<htmlLoadResponse($rsp[,$htm])>

This macro parses the HTTP response content and returns the resulting HTML
object. You can specify a parser as an argument to control what information is
extracted.

=cut

sub _m_load_rsp
{ my ($slf, $ctx, $rsp, $htm) = @_;

  $htm = RDA::Object::Html->new($slf->{'trc'}) unless ref($htm) eq $HTML;
  if (ref($rsp) eq 'RDA::Object::Response')
  { foreach my $lin (@{$rsp->get_content})
    { $htm->parse($lin);
    }
    $htm->eof;
  }
  $htm;
}

=head2 S<htmlName($htm)>

This macro returns the node name when defined. Otherwise, it returns an
undefined value.

=cut

sub _m_name
{ my ($slf, $ctx, $htm) = @_;

  (ref($htm) eq $HTML) ? $htm->get_name : undef;
}

=head2 S<htmlTable($htm[,$lvl])>

This macro extracts all significant tables from the parsed document. Cells in
bold are taken as the heading. It converts single cell rows in the header of
the specified level. It considers horizontal rulers and header lines also. The
macro returns the result as a list of raw data lines.

=cut

sub _m_table
{ my ($slf, $ctx, $htm, $lvl) = @_;

  return () unless ref($htm) eq $HTML;
  $htm->get_tables($lvl);
}

=head2 S<htmlText($htm)>

This macro extracts the texts contained in the specified node. It returns an
empty string when it finds no text.

=cut

sub _m_text
{ my ($slf, $ctx, $htm) = @_;

  (ref($htm) eq $HTML) ? $htm->get_text : '';
}

=head2 S<htmlType($htm)>

This macro returns the node type.

=cut

sub _m_type
{ my ($slf, $ctx, $htm) = @_;

  (ref($htm) eq $HTML) ? $htm->get_type : undef;
}

=head2 S<htmlValue($htm,$attr[,$dft])>

This macro returns the value of the attribute in the specified node. When the
attribute is not defined, it returns the default value.

=cut

sub _m_value
{ my ($slf, $ctx, $htm, $key, $dft) = @_;

  (ref($htm) eq $HTML) ? $htm->get_value($key, $dft) : $dft;
}

=head1 PARSER MACROS

=head2 S<htmlDisable($htm[,$flt])>

This macro indicates the list of child types to ignore. When the list is
empty, any type filtering is disabled. It returns the parser object reference.

=cut

sub _m_disable
{ my ($slf, $ctx, $htm, $flt) = @_;

  (ref($htm) eq $HTML) ? $htm->disable($flt) : undef;
}

=head2 S<htmlFilter($htm[,$tag,...])>

This macro specifies the list of the tags to consider when parsing the
document. When the list is empty, any tag filtering is disabled. It returns the
parser object reference.

=cut

sub _m_filter
{ my $slf = shift;
  my $ctx = shift;
  my $htm = shift;

  (ref($htm) eq $HTML) ? $htm->filter(@_) : undef;
}

=head2 S<htmlFix($htm,$flg)>

This macro indicates that the parser can fix incorrect HTML code. It returns
the parser object reference.

=cut

sub _m_fix
{ my ($slf, $ctx, $htm, $flg) = @_;

  (ref($htm) eq $HTML) ? $htm->fix($flg) : undef;
}

=head2 S<htmlParser()>

This macro initializes a new HTML parser and returns its reference.

=cut

sub _m_parser
{ RDA::Object::Html->new(shift->{'trc'});
}

=head2 S<setHtmlTrace([$lvl])>

This macro sets the HTML parsing level:

=over 7

=item B<    0 > No trace

=item B<    1 > Trace the HTML parsing

=back

The level is unchanged if the new level is not defined.

It returns the previous level.

=cut

sub _m_trace
{ my ($slf, $ctx, $lvl) = @_;
  my $old;

  $old = $slf->{'trc'};
  $slf->{'trc'} = $lvl if defined($lvl);
  $old;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Html|RDA::Object::Html>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
