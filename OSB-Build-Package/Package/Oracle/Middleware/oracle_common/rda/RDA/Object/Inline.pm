# Inline.pm: Class Used for Code Blocks in Other Languages

package RDA::Object::Inline;

# $Id: Inline.pm,v 1.14 2012/04/30 20:58:54 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Inline.pm,v 1.14 2012/04/30 20:58:54 mschenke Exp $
#
# Change History
# 20120430  MSC  Allow concurrent use of interfaces.

=head1 NAME

RDA::Object::Inline - Class Used for Managing Code Blocks in Other Languages

=head1 SYNOPSIS

require RDA::Object::Inline;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Inline> class are used to manage named blocks
written in other languages. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @DUMP @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);
@DUMP    = (
  hsh => {
    'RDA::Object::Inline' => 1,
    },
  );
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'getInlinePath' => ['$[INC]', 'get_path'],
    'setInlineInfo' => ['$[INC]', 'set_context'],
    'setInlinePath' => ['$[INC]', 'set_path'],
    },
  beg => \&_begin_inline,
  end => \&_end_inline,
  flg => 1,
  glb => ['$[INC]'],
  inc => [qw(RDA::Object)],
  met => {
    'get_info'      => {ret => 0},
    'get_path'      => {ret => 1},
    'set_context'   => {ret => 0},
    'set_info'      => {ret => 0},
    'set_path'      => {ret => 1},
    },
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Inline-E<gt>new($agent)>

The master control object constructor. This method takes the agent reference as
an argument.

=head2 S<$h = $ctl-E<gt>new($package)>

The local control object constructor. This method takes the package reference
as an argument.

The control objects are represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'agt' > > Reference to the agent object (M)

=item S<    B<'dir' > > Cache directory (M)

=item S<    B<'oid' > > Object identifier (L,M)

=item S<    B<'par' > > Reference to the master control object (L)

=item S<    B<'pkg' > > Reference to the package object (L)

=item S<    B<'_blk'> > Defined named block hash (M)

=item S<    B<'_cod'> > Registred named block hash (L)

=item S<    B<'_ctx'> > Language context hash (L,M)

=item S<    B<'_eng'> > Engine directory (M)

=item S<    B<'_lim'> > Alarm indicator (M)

=item S<    B<'_pkg'> > Package hash (M)

=back

=cut

sub new
{ my ($cls, $obj) = @_;
  my ($slf);

  # Create the object
  if (ref($cls))
  { # Create a local inline code control
    $slf = bless {
      oid  => $obj->get_oid,
      par  => $cls,
      pkg  => $obj,
      _cod => {},
      }, ref($cls);

    # Initialize the execution context
    foreach my $lng (keys(%{$cls->{'_ctx'}}))
    { $slf->{'_ctx'}->{$lng} = {%{$cls->{'_ctx'}->{$lng}}};
    }
  }
  else
  { # Create the master inline code control
    $slf = bless {
      agt  => $obj,
      oid  => 'LNG',
      _blk => {},
      _ctx => {},
      _eng => $obj->get_config->get_dir('D_RDA', 'engine'),
      _pkg => {},
      }, $cls;

    # Check if alarm is implemented
    eval {alarm(0)};
    $slf->{'_lim'} = $@ ? 0 : 1;
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>add_code($code)>

This method registers a named block in the local inline code control object. It
returns the block reference.

=cut

sub add_code
{ my ($slf, $cod) = @_;

  $slf->{'_cod'}->{$cod->get_language}->{$cod->get_name} = $cod;
}

=head2 S<$h-E<gt>add_common($block)>

This method registers a common block in the local inline code control
object. It returns the block reference.

=cut

sub add_common
{ my ($slf, $cod) = @_;
  my ($lng, $nam, $top);

  # Validate the language
  $lng = $cod->get_language;
  die "RDA-01403: Missing or invalid language\n"
    unless defined($lng) && exists($slf->{'_ctx'}->{$lng});

  # Register the block in the cache on first call
  $nam = $cod->get_name;
  $top = $slf->get_top;
  $top->{'_blk'}->{$lng}->{$nam} = $cod
    unless exists($top->{'_blk'}->{$lng}->{$nam});

  # Return the reference to the source object
  $slf->{'_cod'}->{$lng}->{$nam} = $cod;
}

=head2 S<$h-E<gt>exec_code($lang,$name,@arg)>

This method executes the specified named block with the specified arguments and
returns the result as a list.

=cut

sub exec_code
{ my ($slf, $lng, $nam, @arg) = @_;
  my ($cod);

  # Check if the block has been registred
  die "RDA-01411: Unregistred $lng named block '$nam'\n"
    unless exists($slf->{'_cod'}->{$lng}) &&
           exists($slf->{'_cod'}->{$lng}->{$nam});

  # Abort when the block has errors
  $cod = $slf->{'_cod'}->{$lng}->{$nam};
  die "RDA-01410: Invalid $lng named block '$nam'\n" if $cod->has_errors;

  # Compile the code when not yet available
  $cod->prepare($slf);

  # Execute the named block
  $cod->execute($slf, @arg);
}

=head2 S<$h-E<gt>pipe_code($ofh,$lang,$name,@arg)>

This method creates a pipe to the specified named block which is executed with
the specified arguments. It returns the process identifier in a scalar context,
the process identifier, the output and error files in a list context.

=cut

sub pipe_code
{ my ($slf, $ofh, $lng, $nam, @arg) = @_;
  my ($cod);

  # Check if the block has been registred
  die "RDA-01411: Unregistred $lng named block '$nam'\n"
    unless exists($slf->{'_cod'}->{$lng}) &&
           exists($slf->{'_cod'}->{$lng}->{$nam});

  # Abort when the block has errors
  $cod = $slf->{'_cod'}->{$lng}->{$nam};
  die "RDA-01410: Invalid $lng named block '$nam'\n" if $cod->has_errors;

  # Compile the code when not yet available
  $cod->prepare($slf);

  # Launch the named block and return its process identifier
  $cod->launch($ofh, $slf, @arg);
}

=head1 CACHE MANAGEMENT METHODS

=head2 S<$h-E<gt>add_block($package,$block)>

This method adds the block to the cache.

=cut

sub add_block
{ my ($slf, $pkg, $blk) = @_;
  my ($lng, $nam);

  # Check block unicity
  $slf = $slf->get_top;
  $lng = $blk->get_language;
  $nam = $blk->get_name;
  die "RDA-01412: Duplicate $lng block name '$nam'\n"
    if exists($slf->{'_blk'}->{$lng}->{$nam});

  # Initialize the context on the first call
  $slf->init_context($lng, ref($blk)) unless exists($slf->{'_ctx'}->{$lng});

  # Store the named block
  $slf->{'_blk'}->{$lng}->{$nam} = $blk;
  push(@{$slf->{'_pkg'}->{$pkg}}, [$lng, $nam]);

  # Return the reference to the source object
  $blk;
}

=head2 S<$h-E<gt>check_cache>

This method checks the validatity of the inline code cache. When a new build is
present, the cache directory is cleared.

=cut

sub check_cache
{ my ($slf) = @_;
  my ($cfg, $dir, $ifh, $ref, $ver);

  $slf = $slf->get_top;
  $dir = $slf->{'dir'};
  $cfg = RDA::Object::Rda->cat_file($dir, 'version.cfg');
  $ifh = IO::File->new;
  $ref = $slf->{'agt'}->get_config->get_build;
  if ($ifh->open("<$cfg"))
  { # Get the cache version
    $ver = <$ifh>;
    $ifh->close;
    $ver =~ s/[\n\r\s]+//;

    # Clean the cache when a new build is present
    if ($ver lt $ref)
    { RDA::Object::Rda->clean_dir($dir);
      _add_version($cfg, $ref);
    }
  }
  else
  { _add_version($cfg, $ref);
  }
  $slf;
}

sub _add_version
{ my ($cfg, $ver) = @_;
  my ($ofh);

  $ofh = IO::File->new;
  $ofh->open($cfg, $CREATE, $FIL_PERMS)
    or die "RDA-01400: Cannot set cache version:\n $!\n";
  print {$ofh} "$ver\n";
  $ofh->close;
}

=head2 S<$h-E<gt>delete_block($package)>

This method deletes all blocks contained in the specified package.

=cut

sub delete_blocks
{ my ($slf, $pkg) = @_;

  $slf = $slf->get_top;
  if (exists($slf->{'_pkg'}->{$pkg}))
  { foreach my $rec (@{delete($slf->{'_pkg'}->{$pkg})})
    { delete($slf->{'_blk'}->{$rec->[0]}->{$rec->[1]})->delete;
    }
  }
  $slf;
}

=head2 S<$h-E<gt>get_cache>

This method returns the cache directory.

=cut

sub get_cache
{ my $slf = shift->get_top;

  # Initialize the cache on first use
  unless (exists($slf->{'dir'}))
  { # Get the cache directory
    $slf->{'dir'} = $slf->{'agt'}->get_output->get_path('I', 1);

    # Check the validity of the cache directory
    $slf->check_cache;
  }

  # Return the cache directory
  $slf->{'dir'};
}

=head2 S<$h-E<gt>get_compiled($file)>

This method returns the path to a precompiled block file.

=cut

sub get_compiled
{ my ($slf, $fil) = @_;

  RDA::Object::Rda->cat_file($slf->get_top('_eng'), $fil);
}

=head1 CONTEXT MANAGEMENT METHODS

=head2 S<$h-E<gt>force_context($lang)>

This method forces the creation of an execution for the specified language.

=cut

sub force_context
{ my ($slf, $lng) = @_;
  my ($top);

  if (defined($lng))
  { $top = $slf->get_top;
    $top->init_context($lng)
      unless exists($top->{'_ctx'}->{$lng});
    $slf->{'_ctx'}->{$lng} = {%{$top->{'_ctx'}->{$lng}}}
      unless exists($slf->{'_ctx'}->{$lng});
  }
  $slf;
}

=head2 S<$h-E<gt>get_context($lang)>

This method returns the execution for the specified language.

=cut

sub get_context
{ my ($slf, $lng) = @_;

  die "RDA-01403: Missing or invalid language\n"
    unless defined($lng) && exists($slf->{'_ctx'}->{$lng});

  $slf->{'_ctx'}->{$lng};
}

=head2 S<$h-E<gt>get_path($lang,$name)>

This method returns the specified path list.

=cut

sub get_path
{ my ($slf, $lng, $nam) = @_;

  die "RDA-01403: Missing or invalid language\n"
    unless defined($lng) && exists($slf->{'_ctx'}->{$lng});

  return ()
    unless defined($nam) && exists($slf->{'_ctx'}->{$lng}->{$nam = lc($nam)});
  @{$slf->{'_ctx'}->{$lng}->{$nam}};
}

=head2 S<$h-E<gt>init_context($lang[,$class])>

This method initializes the execution context for the specified language using
the specified class.

=cut

sub init_context
{ my ($slf, $lng, $cls) = @_;
  my ($agt, $ctx, $off, $pat);

  # Perform generic initialization
  $slf->{'_ctx'}->{$lng} = $ctx = {
    CACHE   => 1,
    KEEP    => 0,
    TIMEOUT => 0,
    TRACE   => 0,
    };
  $agt = $slf->{'agt'};
  $off = length($lng) + 1;
  foreach my $key ($agt->grep_setting("^\U$lng\E_"))
  { $ctx->{substr($key, $off)} = $agt->get_setting($key);
  }
  $ctx->{'TIMEOUT'} = 0
    unless $slf->{'_lim'} && $ctx->{'TIMEOUT'} > 0;

  # Perform language-specific initialization
  $cls = "RDA::Object::$lng" unless defined($cls);
  eval "require $cls";
  die "RDA-01401: Cannot load language '$lng':\n $@\n" if $@;
  eval {$cls->init($ctx, $agt)};
  die "RDA-01402: Unsupported language '$lng':\n $@\n" if $@;

  # Return the language context
  $ctx;
}

=head2 S<$h-E<gt>set_context($lang,$name[,$value])>

This method defines the specified context property. When the value is missing
or undefined, it deletes the context property. It returns the previous value.

=cut

sub set_context
{ my ($slf, $lng, $nam, $val) = @_;
  my ($old);

  die "RDA-01403: Missing or invalid language\n"
    unless defined($lng) && exists($slf->{'_ctx'}->{$lng});

  if (defined($nam))
  { $nam = uc($nam);
    $slf = $slf->{'par'} if $nam =~ s/^DEFAULT\.//;
    $old = delete($slf->{'_ctx'}->{$lng}->{$nam});
    $slf->{'_ctx'}->{$lng}->{$nam} = $val if defined($val);
  }
  $old;
}

=head2 S<$h-E<gt>set_path($lang,$name,@list)>

This method sets the specified path list and returns its previous content.

=cut

sub set_path
{ my ($slf, $lng, $nam, @new) = @_;
  my (@old);

  die "RDA-01403: Missing or invalid language\n"
    unless defined($lng) && exists($slf->{'_ctx'}->{$lng});

  if (defined($nam))
  { $nam = lc($nam);
    $slf = $slf->{'par'} if $nam =~ s/^default\.//;
    @old = @{$slf->{'_ctx'}->{$lng}->{$nam}}
      if exists($slf->{'_ctx'}->{$lng}->{$nam});
    $slf->{'_ctx'}->{$lng}->{$nam} = [@new];
  }
  @old;
}

=head1 LANGUAGE ENVIRONMENT MANAGEMENT METHODS

=head2 S<$h-E<gt>restore_env($backup)>

This method restores the environment.

=cut

sub restore_env
{ my ($slf, $bkp) = @_;
  my ($val);

  foreach my $key (keys(%$bkp))
  { if (defined($val = $bkp->{$key}))
    { $ENV{$key} = $val;
    }
    else
    { delete($ENV{$key});
    }
  }
}

=head2 S<$h-E<gt>set_env($env)>

This method adapts the environment.

=cut

sub set_env
{ my ($slf, $env, $trc) = @_;
  my ($bkp, $val);

  $bkp = {};
  foreach my $key (keys(%$env))
  { if (defined($val = $env->{$key}))
    { $bkp->{$key} = $ENV{$key};
      $ENV{$key} = $val;
      print "$trc Set $key='$val'\n" if $trc;
    }
    elsif (exists($ENV{$key}))
    { $bkp->{$key} = delete($ENV{$key});
      print "$trc Unset $key=\n" if $trc;
    }
  }
  $bkp;
}

# --- SDCL extensions ---------------------------------------------------------

# Initialize the local inline control object
sub _begin_inline
{ my ($pkg) = @_;
  my ($ctl);

  $ctl = $pkg->get_agent->get_inline->new($pkg);
  $pkg->set_info('inc', $ctl);
  $pkg->define('$[INC]', $ctl);
}

# Clear all local blocks
sub _end_inline
{ my ($pkg) = @_;
  my ($ctl);

  $ctl = $pkg->get_info('inc');
  foreach my $lng (keys(%{$ctl->{'_cod'}}))
  { foreach my $cod (values(%{$ctl->{'_cod'}->{$lng}}))
    { $cod->clear;
    }
  }
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Java|RDA::Object::Java>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
