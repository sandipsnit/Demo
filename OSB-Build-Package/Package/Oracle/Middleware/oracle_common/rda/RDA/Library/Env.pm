# Env.pm: Class Used for Environment Variable Macros

package RDA::Library::Env;

# $Id: Env.pm,v 2.6 2012/01/02 16:29:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Env.pm,v 2.6 2012/01/02 16:29:15 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Library::Env - Class Used for Environment Variable Macros

=head1 SYNOPSIS

require RDA::Library::Env;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Env> class are used to interface with
environment variable-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object::Env;
  use RDA::Object::Rda;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my %tb_fct = (
  'backupEnv'   => [\&_m_backup_env,  'T'],
  'restoreEnv'  => [\&_m_restore_env, 'T'],
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Env-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library:Env> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_bkp'> > Copies of environment variables

=item S<    B<'_env'> > Reference to the original environment variables

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    _agt => $agt,
    _env => $agt->get_registry('env', sub {RDA::Object::Env->new}),
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

=head1 ENVIRONMENT VARIABLE MACROS

=head2 S<backupEnv([$nam])>

This macro creates a backup of the internal copy of environment variables under
the specified name. It uses C<dft> as the default name. It returns the backup
name.

=cut

sub _m_backup_env
{ my ($slf, $ctx, $nam) = @_;
  my ($env, $top);

  $nam = 'dft' unless defined($nam);
  $top = $ctx->get_top;
  $slf->{'_bkp'}->{$nam} = $env = $top->get_info('env');
  $top->set_info('env', $env = ref($env) ? $env->clone : $slf->{'_env'}->clone);
  $nam;
}

=head2 S<restoreEnv($nam)>

This macro restores a backup of the internal copy of the environment variables.
It uses C<dft> as the default name. When the macro restores the backup, the
backup is then deleted. When successful, it returns the name of the
backup. Otherwise, it returns an undefined value.

=cut

sub _m_restore_env
{ my ($slf, $ctx, $nam) = @_;
  my ($env);

  $nam = 'dft' unless defined($nam);
  return undef unless exists($slf->{'_bkp'}->{$nam});
  $env = $ctx->get_top->set_info('env', delete($slf->{'_bkp'}->{$nam}));
  $env->unsource if ref($env);
  $nam;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object::Env|RDA::Object::Env>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
