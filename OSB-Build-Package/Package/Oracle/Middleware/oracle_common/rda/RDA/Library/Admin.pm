# Admin.pm: Class Used for Administration Macros

package RDA::Library::Admin;

# $Id: Admin.pm,v 2.6 2012/04/25 06:35:03 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Admin.pm,v 2.6 2012/04/25 06:35:03 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Library::Admin - Class Used for Administration Macros

=head1 SYNOPSIS

require RDA::Library::Admin;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Admin> class are used to interface with
value-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Block;
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $RE_MOD = qr/^S(\d{3})([A-Z]\w*)$/i;

my %tb_fct = (
  'checkFree'     => [\&_m_check_free,     'N'],
  'checkSpace'    => [\&_m_check_space,    'N'],
  'checkTime'     => [\&_m_check_time,     'N'],
  'getFile'       => [\&_m_get_file,       'T'],
  'inThread'      => [\&_m_in_thread,      'N'],
  'isImplemented' => [\&_m_is_implemented, 'T'],
  'renderFile'    => [\&_m_render_file,    'T'],
  'renderIndex'   => [\&_m_render_index,   'N'],
  'setDebug'      => [\&_m_set_debug,      'N'],
  'setTrace'      => [\&_m_set_trace,      'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Admin-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Value> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=back

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the library object
  $slf = bless {
    _agt => $agt,
    }, ref($cls) || $cls;

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

This method runs the macro with the specified argument list in a given context.

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

=head1 ADMINISTRATION MACROS

=head2 S<checkFree()>

This macro indicates whether it remains enough free disk space. It always
returns zero when the check is disabled or when the reporting control is not
enabled.

=cut

sub _m_check_free
{ my ($slf, $ctx) = @_;

  $ctx->check_free;
}

=head2 S<checkSpace()>

This macro indicates whether some time is remaining. It always returns zero
when the time quota is disabled or when the reporting control is not enabled.

=cut

sub _m_check_space
{ my ($slf, $ctx) = @_;

  $ctx->check_space;
}

=head2 S<checkTime()>

This macro indicates whether some time is remaining. It always returns zero
when the time quota is disabled.

=cut

sub _m_check_time
{ my ($slf, $ctx) = @_;

  $ctx->check_time;
}

=head2 S<getFile([$report[,$module]])>

This macro returns the name of the report file that is associated with the
specified report. It is possible to refer to another module. When no argument
is specified, it returns the name of the current report file if defined.
Otherwise, it returns an undefined value.

=cut

sub _m_get_file
{ my ($slf, $ctx, $rpt, $mod) = @_;
  my ($abr, $fil, $out);

  $out = $ctx->get_output;
  if (!defined($rpt))
  { return undef unless ($rpt = $out->get_info('cur'));
    $fil = $rpt->get_report;
  }
  elsif ($rpt eq '.')
  { return undef unless ($rpt = $out->get_info('cur'));
    $fil = $rpt->get_file;
  }
  elsif ($rpt eq '/')
  { return undef unless ($rpt = $out->get_info('cur'));
    $fil = $rpt->get_file(1);
  }
  elsif ($rpt eq '$')
  { return undef unless ($rpt = $out->get_info('cur'));
    $fil = RDA::Object::Rda->quote($rpt->get_file(1));
  }
  else
  { $abr = ($mod && $mod =~ $RE_MOD) ? $2 : $out->get_info('abr');
    $fil = $out->get_info('grp').'_'.$abr.'_'.$rpt.'.htm';
  }
  $out->get_info('cas') ? $fil : lc($fil);
}

=head2 S<inThread()>

This macro indicates whether the code belongs to a thread.

=cut

sub _m_in_thread
{ my ($slf, $ctx) = @_;

  $ctx->get_top('job') ? 1 : 0;
}

=head2 S<isImplemented($name)>

This macro indicates whether the specified macro or operator is implemented.

=cut

sub _m_is_implemented
{ my ($slf, $ctx, $nam) = @_;

  exists($ctx->get_package('als')->{$nam}) ? 'ALIAS' :
  exists($ctx->get_package('opr')->{$nam}) ? 'OPERATOR' :
  exists($ctx->get_lib->{$nam})            ? 'MACRO' :
                                             '';
}

=head2 S<renderFile([$file[,$title]])>

This macro renders the specified file. When no argument is specified, it closes
and renders the current report file.

It returns the name of the generated file.

=cut

sub _m_render_file
{ my ($slf, $ctx, $rpt, $ttl) = @_;

  $rpt                      ? _get_render($ctx)->gen_html($rpt, $ttl) :
  ($rpt = $ctx->get_report) ? $rpt->render($ttl) :
                              undef;
}

=head2 S<renderIndex([$flag])>

This macro generates the index. When the flag is set, it re-creates the
cascading style sheet file.

=cut

sub _m_render_index
{ my ($slf, $ctx, $flg) = @_;

  _get_render($ctx)->gen_index($flg);
  1;
}

sub _get_render
{ my ($ctx) = @_;
  my ($rnd);

  $rnd = $ctx->get_agent->get_render;
  $rnd->align_owner if $ctx->get_output->get_info('own');
  $rnd;
}

=head2 S<setDebug([$flg])>

This macro enables or disables the debug mode. It is disabled when the output
is suppressed. It remains unchanged when the flag is undefined.

It returns the previous flag setting.

=cut

sub _m_set_debug
{ my ($slf, $ctx, $flg) = @_;
  my ($top);

  $top = $ctx->get_top;
  $top->get_info('out') ? $top->set_info('dbg', 0) :
  defined($flg)         ? $top->set_info('dbg', $flg) :
                          $top->get_info('dbg');
}

=head2 S<setTrace([$lvl])>

This macro sets the trace level:

=over 7

=item B<    0 > No trace

=item B<    1 > Trace the command execution.

=item B<    2 > Trace the variable assignment also.

=back

The tracing is disabled when the output is suppressed. The level is unchanged
when the new level is not defined.

It returns the previous trace level.

=cut

sub _m_set_trace
{ my ($slf, $ctx, $lvl) = @_;

  $ctx->get_info('out') ? $ctx->get_context->set_trace(0) :
  defined($lvl)         ? $ctx->get_context->set_trace($lvl) :
                          $ctx->get_context->get_trace;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Render|RDA::Render>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::List|RDA::Value::List>,
L<RDA::Value::Scalar|RDA::Value::Scalar>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
