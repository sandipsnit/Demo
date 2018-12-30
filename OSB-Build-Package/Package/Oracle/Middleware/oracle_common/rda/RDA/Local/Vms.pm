# Vms.pm: VMS Methods for RDA::Object::Rda

package RDA::Local::Vms;

# $Id: Vms.pm,v 2.9 2012/04/25 06:38:59 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Local/Vms.pm,v 2.9 2012/04/25 06:38:59 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Local::Vms - VMS Methods for RDA::Object::Rda

=head1 SYNOPSIS

require RDA::Local::Vms;

=head1 DESCRIPTION

See L<RDA::Object::Rda|RDA::Object::Rda> and
L<RDA::Local::Unix|RDA::Local::Unix>. This package overrides the implementation
of these methods, not the semantics.

To assure more reproducable results with different Perl versions, some code is
derived from C<File::Spec>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Spec;
  eval "use File::Spec::VMS";
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.9 $ =~ /(\d+)\.(\d+)/);

require RDA::Local::Unix;
@ISA = qw(RDA::Local::Unix Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Object::Rda-E<gt>as_bat([$path])>

This method adds a C<.com> extension to the specified path.

=cut

sub as_bat
{ my ($slf, $pth) = @_;

  defined($pth) ? "$pth.com" : '.com';
}

=head2 S<RDA::Object::Rda-E<gt>as_cmd([$path])>

This method adds a C<.com> extension to the specified path.

=cut

sub as_cmd
{ my ($slf, $pth) = @_;

  defined($pth) ? "$pth.com" : '.com';
}

=head2 S<RDA::Object::Rda-E<gt>as_exe([$path])>

This method adds a C<.exe> extension to the specified path.

=cut

sub as_exe
{ my ($slf, $pth) = @_;

  defined($pth) ? "$pth.exe" : '.exe';
}

=head2 S<RDA::Object::Rda-E<gt>cat_dir([$dir...,]$dir)>

This method concatenates directory names to form a complete path ending with a
directory. It removes the trailing slash from the resulting string, except for
the root directory.

=cut

sub cat_dir
{ my $slf = shift;

  File::Spec->catdir(@_);
}

=head2 S<RDA::Object::Rda-E<gt>cat_file([$dir...,]$file)>

This method concatenates directory names and a filename to form a complete path
ending with a filename.

=cut

sub cat_file
{ my $slf = shift;

  File::Spec->catfile(@_);
}

=head2 S<RDA::Object::Rda-E<gt>clean_path($path)>

This method performs a logical cleanup of a path.

=cut

sub clean_path
{ my ($slf, $pth) = @_;

  (ref($pth) eq 'ARRAY') ? join('/', @$pth) : $pth;
}

=head2 S<RDA::Object::Rda-E<gt>dev_null>

This method returns a string representation of the null device.

=cut

sub dev_null
{ 'NLA0:';
}

=head2 S<RDA::Object::Rda-E<gt>dev_tty>

This method returns a string representation of the terminal device.

=cut

sub dev_tty
{ 'SYS$OUTPUT';
}

=head2 S<RDA::Object::Rda-E<gt>find_path($cmd[,$flg])>

This method explores the path to find where a command is located. When the
command is found, it returns a full path name. Otherwise, it returns an
undefined variable. It only considers files or symbolic links in its
search. Unless the flag is set, the file path is quoted as required by a
command shell.

=cut

sub find_path
{ my ($slf, $pth, $cmd) = @_;
  my ($lin);

  if ($cmd)
  { eval {
      local $SIG{'__WARN__'} = sub { };
      local $SIG{'PIPE'} = 'IGNORE';
      open(PIPE, "$cmd \"-h\" |") or die "Bad open\n";
      $lin = <PIPE>;
      while (<PIPE>)
      { ; # Need a loop to prevent pipe errors
      }
      close(PIPE) or die "Bad close\n";;
    };
    return $cmd if defined($lin) && $lin !~ m/^\%DCL\-/;
  }
  undef;
}

=head2 S<RDA::Object::Rda-E<gt>get_last_modify($file[,$default])>

This method gets the last modification date of the file. In returns the default
value when there are problems.

=cut

sub get_last_modify
{ my ($slf, $fil, $dft) = @_;
  my @sta = stat($fil);
  defined($sta[9]) ? $sta[9] : $dft;
}

=head2 S<RDA::Object::Rda-E<gt>get_path>

This method returns the environment variable PATH as a list.

=cut

sub get_path
{ File::Spec->path();
}

=head2 S<RDA::Object::Rda-E<gt>is_absolute($path)>

This method indicates whether the argument is an absolute path.

=cut

sub is_absolute
{ my ($slf, $pth) = @_;

  File::Spec->file_name_is_absolute($pth);
}

=head2 S<RDA::Object::Rda-E<gt>is_unix>

This method returns a true value if the operating system belongs to the UNIX
family.

=cut

sub is_unix
{ 0;
}

=head2 S<RDA::Object::Rda-E<gt>is_vms>

This method returns a true value if the operating system is VMS.

=cut

sub is_vms
{ 1;
}

=head2 S<RDA::Object::Rda-E<gt>quote($str)>

This method encodes a string to be considered as a single argument by a command
shell. No variable substitution is attempted for VMS.

=cut

sub quote
{ my ($slf, $str) = @_;

  return $str unless defined($str) && $str =~ m/[\s\@\"\,]/;
  $str =~ s#"#""#g;
  '"'.$str.'"';
}

=head2 S<RDA::Object::Rda-E<gt>split_dir($path)>

This method returns the list of directories contained in the specified
path. The first element will includes the volume information. It returns an
empty list when the path is missing.

=cut

sub split_dir
{ my ($slf, $pth) = @_;
  my ($vol, $dir, $fil, @dir);

  if (defined($pth))
  { ($vol, $dir, $fil) = File::Spec::VMS->splitpath($pth);
    @dir = File::Spec::VMS->splitdir($dir);
    $dir[0] = File::Spec::VMS->catpath($vol, $dir[0], '');
  }
  @dir;
}

# --- Auxiliary routines ------------------------------------------------------

# Get uname information
sub sys_uname
{ my ($slf) = @_;
  my ($sys);

  # Try to get it from perl
  eval {
    require POSIX;
    $sys = [&POSIX::uname()];
  };
  return $sys unless $@;

  # Otherwise, give up
  ['?', '?', '?', '?', '?'];
}

1;

__END__

=head1 SEE ALSO

L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Local::Unix|RDA::Local::Unix>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
