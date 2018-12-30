# Temp.pm: Class Used for Temporary File Management Macros

package RDA::Library::Temp;

# $Id: Temp.pm,v 2.4 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Temp.pm,v 2.4 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Temp - Class Used for Temporary File Management Macros

=head1 SYNOPSIS

require RDA::Library::Temp;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Temp> class are used to interface with
temporary file management macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_fct = (
  'closeTemp'     => [\&_m_close_temp,  'N'],
  'createTemp'    => [\&_m_create_temp, 'T'],
  'getTemp'       => [\&_m_get_temp,    'T'],
  'newTemp'       => [\&_m_new_temp,    'T'],
  'unlinkTemp'    => [\&_m_unlink_temp, 'N'],
  'writeTemp'     => [\&_m_write_temp,  'N'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Temp-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Temp> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_tmp'> > Hash containing the temporary file definitions

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _tmp => {},
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

  # Return the object reference
  $slf;
}

# Clear the temporary file hash for each module
sub clr_stats
{ shift->_reset_table;
}

sub get_stats
{ shift->_reset_table;
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

=head1 TEMPORARY FILE MACROS

=head2 S<closeTemp($nam)>

This macro closes the specified temporary file. It returns 1 on successful
completion and 0 if the file was not previously defined.

=cut

sub _m_close_temp
{ my ($slf, $ctx, $nam) = @_;

  return 0 unless exists($slf->{'_tmp'}->{$nam});

  $slf->{'_tmp'}->{$nam}->close;
  1;
}

=head2 S<createTemp($nam[,$suf[,$flg]])>

This macro creates a temporary file name based on the specified name, used as a
unique identifier for other requests. It uses C<.tmp> as the default suffix and
removes any previous file. When the flag is set, the file is made executable,
but it is only accessible for the file owner.

It returns the file name on successful completion. Otherwise, it returns an
undefined value.

=cut

sub _m_create_temp
{ my ($slf, $ctx, $nam, $suf, $flg) = @_;

  # Delete any temporary file previously associated with that name
  $ctx->get_output->end_temp(delete($slf->{'_tmp'}->{$nam}))
    if exists($slf->{'_tmp'}->{$nam});

  # Define the new temporary file
  _new_tmp($slf, $ctx, 1, $nam, $suf, $flg)->get_file(1);
}

=head2 S<getTemp($nam[,$suf])>

This macro generates a temporary file name based on the specified name, which
is used as a unique identifier for other requests. It uses C<.tmp> as the
default suffix.

=cut

sub _m_get_temp
{ my ($slf, $ctx, $nam, $suf) = @_;

  (exists($slf->{'_tmp'}->{$nam})
    ? $slf->{'_tmp'}->{$nam}
    : _new_tmp($slf, $ctx, 1, $nam, $suf))->get_file(1);
}

=head2 S<newTemp($nam[,$suf])>

This macro generates a temporary file name based on the specified name, which
is used as a unique identifier for other requests. It uses C<.tmp> as the
default suffix. It takes care that the file does not exists but well the
temporary directory.

=cut

sub _m_new_temp
{ my ($slf, $ctx, $nam, $suf) = @_;
  my ($out, $pth);

  # Delete any temporary file previously associated with that name
  $out = $ctx->get_output;
  $out->end_temp(delete($slf->{'_tmp'}->{$nam}))
    if exists($slf->{'_tmp'}->{$nam});

  # Define the new temporary file
  $out->get_path('T', 1);
  $pth = _new_tmp($slf, $ctx, 0, $nam, $suf)->get_file(1);
  1 while unlink($pth);
  $pth;
}

=head2 S<unlinkTemp($nam)>

This macro unlinks a temporary file. It returns 1 for a successful
completion. Otherwise, it returns 0.

=cut

sub _m_unlink_temp
{ my ($slf, $ctx, $nam) = @_;

  return 0 unless exists($slf->{'_tmp'}->{$nam});

  $ctx->get_output->end_temp(delete($slf->{'_tmp'}->{$nam}));
  1;
}

=head2 S<writeTemp($nam[,$str...])>

This macro writes a line in the temporary file. It returns the number of bytes
written.

=cut

sub _m_write_temp
{ my ($slf, $ctx, $nam, @arg) = @_;
  my ($ofh, $tmp);

  # Get the temporary file definition
  $tmp = exists($slf->{'_tmp'}->{$nam})
    ? $slf->{'_tmp'}->{$nam}
    : _new_tmp($slf, $ctx, 0, $nam);

  # Write the line
  $tmp->write(join('', grep {defined($_)} @arg)."\n");
}

#--- Internal methods ---------------------------------------------------------

# Define a new temporary file
sub _new_tmp
{ my ($slf, $ctx, $flg, $nam, $suf, $exe) = @_;
  my ($ctl);

  $ctl = $ctx->get_output->add_temp($nam, $suf, $exe);
  if ($flg)
  { $ctl->create;
    $ctl->close;
  }
  $slf->{'_tmp'}->{$nam} = $ctl;
}

# Reset the temporary file hash
sub _reset_table
{ shift->{'_tmp'} = {};
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Report|RDA::Object::Report>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
