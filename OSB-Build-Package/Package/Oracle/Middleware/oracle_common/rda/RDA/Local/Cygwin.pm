# Cygwin.pm: Cygwin Methods for RDA::Object::Rda

package RDA::Local::Cygwin;

# $Id: Cygwin.pm,v 2.15 2012/04/26 13:03:13 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Local/Cygwin.pm,v 2.15 2012/04/26 13:03:13 mschenke Exp $
#
# Change History
# 20120426  MSC  Eliminate some error messages.

=head1 NAME

RDA::Local::Cygwin - Cygwin Methods for RDA::Object::Rda

=head1 SYNOPSIS

require RDA::Local::Cygwin;

=head1 DESCRIPTION

See L<RDA::Object::Rda|RDA::Object::Rda> and
L<RDA::Local::Unix|RDA::Local::Unix>. This package overrides the implementation
of these methods, not the semantics.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.15 $ =~ /(\d+)\.(\d+)/);

require RDA::Local::Unix;
@ISA = qw(RDA::Local::Unix Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Object::Rda-E<gt>as_bat([$path])>

This method adds a C<.bat> extension to the specified path.

=cut

sub as_bat
{ my ($slf, $pth) = @_;

  defined($pth) ? "$pth.bat" : '.bat';
}

=head2 S<RDA::Object::Rda-E<gt>as_cmd([$path])>

This method adds a C<.cmd> extension to the specified path.

=cut

sub as_cmd
{ my ($slf, $pth) = @_;

  defined($pth) ? "$pth.cmd" : '.cmd';
}

=head2 S<RDA::Object::Rda-E<gt>as_exe([$path])>

This method adds a C<.exe> extension to the specified path.

=cut

sub as_exe
{ my ($slf, $pth) = @_;

  defined($pth) ? "$pth.exe" : '.exe';
}

=head2 S<RDA::Object::Rda-E<gt>clean_path($path[,$flag])>

This method performs a logical cleanup of a path. It removes successive slashes
(C</>) and successive C</.>. It converts backslashes (C<\>) to slashes (C</>)
also. When the flag is set, it attempts to further reduce the number of C</..>
present in the path.

=cut

sub clean_path
{ my ($slf, $pth, $flg) = @_;
  my ($vol);

  $pth = join('/', @$pth) if ref($pth) eq 'ARRAY';
  $pth =~ s#\\#/#g;
  $vol = ($pth =~ s#^(//[^/]+)(/|\z)#/#s) ? $1 :
         ($pth =~ s#^([a-z]:)##is)        ? uc($1) :
                                            '';
  $vol.$slf->SUPER::clean_path($pth, $flg);
}

=head2 S<RDA::Object::Rda-E<gt>find_path($cmd[,$flg])>

This method explores the path to find where a command is located. When the
command is found, it returns a full path name. Otherwise, it returns an
undefined variable. It only considers files or symbolic links in its
search. Unless the flag is set, the file path is quoted as required by a
command shell.

=cut

sub find_path
{ my ($slf, $pth, $cmd, $flg) = @_;
  my ($fil, @tbl, $sep);

  if ($cmd && $pth)
  { unless (ref($pth) eq 'ARRAY')
    { $sep = $slf->get_separator;
      $pth = [split(/$sep/, $pth)];
    }

    foreach my $dir (@$pth)
    { if (opendir(DIR, $dir))
      { @tbl = grep {m/^\Q$cmd\E(\.(bat|cmd|exe))?$/i} readdir(DIR);
        closedir(DIR);
        foreach my $nam (@tbl)
        { $fil = $slf->cat_file($dir, $nam);
          return $flg ? $fil : $slf->quote($fil)
            if stat($fil) && (-f $fil || -l $fil);
        }
      }
    }
  }
  undef;
}

=head2 S<RDA::Object::Rda-E<gt>is_absolute($path)>

This method indicates whether the argument is an absolute path.

=cut

sub is_absolute
{ my ($slf, $pth) = @_;

  scalar ($pth =~ m#^([a-z]:)?[\\/]#is);
}

=head2 S<RDA::Object::Rda-E<gt>is_cygwin>

This method returns a true value whether the operating system is Cygwin.

=cut

sub is_cygwin
{ 1;
}

=head2 S<RDA::Object::Rda-E<gt>is_root_dir($path)>

This method indicates whether the path represents a root directory. It assumes
that the provided path is already cleaned.

=cut

sub is_root_dir
{ my ($slf, $pth) = @_;

  $pth =~ s#\\#/#g;
  $pth =~ s#^/cygdrive/[a-z](/|\z)#/#;
  $pth =~ s#^[a-z]:##is;
  $slf->SUPER::is_root_dir($pth);
}

=head2 S<RDA::Object::Rda-E<gt>is_unix>

This method returns a true value if the operating system belongs to the UNIX
family.

=cut

sub is_unix
{ 0;
}

=head2 S<RDA::Object::Rda-E<gt>native($path)>

This method converts the path to its Windows representation.

=cut

sub native
{ my ($slf, $pth) = @_;
  my ($str);

  # Try cygpath first
  ($str) = `cygpath -w '$pth' 2>/dev/null`;
  if ($str)
  { $str =~ s/[\n\r]+$//;
    return $str;
  }

  # Do minimal transformations
  $pth =~ s#^/cygdrive/([a-z])(/|\z)#$1:/#is;
  $pth =~ s#^([a-z]:)#\U$1\Q#;
  $pth =~ s#/#\\#g;
  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>short($path)>

This method converts the path to its native representation using only short
names.

=cut

sub short
{ my ($slf, $pth) = @_;
  my ($str);

  # Try cygpath first
  ($str) = `cygpath -d '$pth' 2>/dev/null`;
  if ($str)
  { $str =~ s/[\n\r]+$//;
    return $str;
  }

  # Do minimal transformations
  $pth = $str = native(@_);
  $str =~ s/\\/\\/g;
  foreach my $lin (`echo 'FOR %D IN ("$str") DO ECHO %~sD' | cmd`)
  { return $1 if $lin =~ m/>ECHO (.*?)[\n\r\s]+$/;
  }
  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>split_dir($path)>

This method returns the list of directories contained in the specified path. It
returns an empty list when the path is missing.

=cut

sub split_dir
{ my ($slf, $pth) = @_;
  my ($vol, @dir);

  if (defined($pth))
  { ($vol, $pth) = $slf->split_volume($pth);
    @dir = split(/[\/\\]/, $pth, -1);
    $dir[0] = $vol.$dir[0];
  }
  return @dir;
}

=head2 S<RDA::Object::Rda-E<gt>split_volume($path)>

This method separates the volume from the other path information. It returns an
empty list when the path is missing.

=cut

sub split_volume
{ my ($slf, $pth) = @_;
  my ($vol);

  return () unless defined($pth);
  $pth =~ s#\\#/#g;
  $pth =~ s#^/cygdrive/([a-z])(/|\z)#$1:/#is;
  $vol = ($pth =~ s#^(//[^/]+)/?\z#/#s) ? $1 :
         ($pth =~ s#^(//[^/]+/)##s)     ? $1 :
         ($pth =~ s#^([a-z]:)##is)      ? uc($1) :
                                          '';
  $pth = '.' unless defined($pth) && length($pth);
  ($vol, ($pth eq '') ? '.' : $pth);
}

# --- Auxiliary routines ------------------------------------------------------

# Get uname information
sub sys_uname
{ my ($slf) = @_;
  my ($str, $sys);

  # Try to get it from perl
  eval {
    require POSIX;
    $sys = [&POSIX::uname()];
  };
  return $sys unless $@;

  # Try to get from the operating system
  eval {
    ($str) = `uname -a`;
    $sys = [split(/\s/, $str)];
  };
  return $sys unless $@;

  # Try to emulate it
  $sys = ['?', '?', '?', '?', '?'];
  ($str) = `echo exit | cmd`;
  if ($str =~ m/^(.*) \[Version\s+(\d+\.\d+)\.([^]]*)\]/)
  { ($sys->[0], $sys->[2], $sys->[3]) = ($1, $2, $3);
  }
  elsif ($str =~ m/^Microsoft\(R\) Windows NT\(TM\)/i)
  { $sys->[0] = 'Microsoft Windows NT';
  }
  $sys->[1] = $slf->get_node;
  $sys->[4] = $ENV{'PROCESSOR_ARCHITECTURE'}
    if exists($ENV{'PROCESSOR_ARCHITECTURE'});
  $sys;
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
