# Unix.pm: UNIX Methods for RDA::Object::Rda

package RDA::Local::Unix;

# $Id: Unix.pm,v 2.11 2012/04/25 06:38:59 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Local/Unix.pm,v 2.11 2012/04/25 06:38:59 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Local::Unix - UNIX Methods for RDA::Object::Rda

=head1 SYNOPSIS

require RDA::Local::Unix;

=head1 DESCRIPTION

See L<RDA::Object::Rda|RDA::Object::Rda>. This package overrides the
implementation of these methods, not the semantics.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Object::Rda-E<gt>as_bat([$path[,$flag]])>

This method adds a C<.sh> extension to the specified path unless the flag is
set.

=cut

sub as_bat
{ my ($slf, $pth, $flg) = @_;
  my ($ext);

  $ext = $flg ? '' : '.sh';
  defined($pth) ? $pth.$ext : $ext;
}

=head2 S<RDA::Object::Rda-E<gt>as_cmd([$path[,$flag]])>

This method adds a C<.sh> extension to the specified path unless the flag is
set.

=cut

sub as_cmd
{ my ($slf, $pth, $flg) = @_;
  my ($ext);

  $ext = $flg ? '' : '.sh';
  defined($pth) ? $pth.$ext : $ext;
}

=head2 S<RDA::Object::Rda-E<gt>as_exe([$path])>

This method returns the specified path.

=cut

sub as_exe
{ my ($slf, $pth) = @_;

  defined($pth) ? $pth : '';
}

=head2 S<RDA::Object::Rda-E<gt>cat_dir([$dir...,]$dir)>

This method concatenates directory names to form a complete path ending with a
directory. It removes the trailing slash from the resulting string, except for
the root directory.

It discards undefined values and references from the argument list.

=cut

sub cat_dir
{ my $slf = shift;
  my @tbl = grep {defined($_) && !ref($_)} @_;

  (scalar @tbl) ? $slf->clean_path([@tbl, '']) : $slf->current_dir;
}

*arg_dir = \&cat_dir;

=head2 S<RDA::Object::Rda-E<gt>cat_file([$dir...,]$file)>

This method concatenates directory names and a filename to form a complete path
ending with a filename.

It discards undefined values and references from the argument list.

=cut

sub cat_file
{ my $slf = shift;
  my @tbl = grep {defined($_) && !ref($_)} @_;

  (scalar @tbl) ? $slf->clean_path([@tbl]) : undef;
}

*arg_file = \&cat_file;

=head2 S<RDA::Object::Rda-E<gt>clean_dir($path)>

This method deletes the content of a directory but not the directory itself.

=cut

sub clean_dir
{ my ($slf, $pth) = @_;

  _clean_dir($slf, $pth) if defined($pth);
}

sub _clean_dir
{ my ($slf, $top, $flg) = @_;
  my ($pth, @dir);

  # Remove files
  if (opendir(DIR, $top))
  { foreach my $nam (readdir(DIR))
    { next if $nam =~ /^\.+$/;
      $pth = $slf->cat_file($top, $nam);
      if (-d $pth)
      { push(@dir, $nam);
      }
      else
      { 1 while unlink($pth);
      }
    }
    closedir(DIR);
  }

  # Remove subdirectories
  foreach my $nam (@dir)
  { rmdir(_clean_dir($slf, $slf->cat_dir($top, $nam)));
  }

  # Return the directory name
  $top
}

=head2 S<RDA::Object::Rda-E<gt>clean_path($path[,$flag])>

This method performs a logical cleanup of a path. It removes successive slashes
and successives C</.>. When the flag is set, it attempts to further reduce the
number of C</..> present in the path.

=cut

sub clean_path
{ my ($slf, $pth, $flg) = @_;

  $pth = join('/', @$pth) if ref($pth) eq 'ARRAY';

  $pth =~ s#/+#/#g;                # x////x  -> x/x
  $pth =~ s#(/\.)+(/|\z)#/#g;      # x/././x -> x/x
  $pth =~ s#^(\./)+(.)#$2#s;       # ./x     -> x
  $pth =~ s#^(/\.\.)+(/|\z)#/#s;   # /../..  -> /
  $pth =~ s#(.)/$#$1#;             # x/      -> x

  if ($flg && $pth =~ m#/\.\.(/|\z)#)
  { my ($itm, @tbl);

    foreach $itm (split(/\//, $pth, -1))
    { if ($itm eq '..' && @tbl)
      { $itm = pop(@tbl);
        push(@tbl, $itm)       if $itm eq '';
        push(@tbl, $itm, '..') if $itm eq '..';
      }
      else
      { push(@tbl, $itm);
      }
    }
    $pth = ((scalar @tbl) > 1)        ? join('/', @tbl) :
           !defined($itm = pop(@tbl)) ? '.' :
           ($itm eq '')               ? '/' :
                                        $itm;
  }

  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>create_dir($path[,$mode])>

This method creates a directory when it does not yet exist. It makes parent
directories as needed. If directory permissions are omitted, 0750 is used as
default. It returns the directory name.

=cut

sub create_dir
{ my ($slf, $pth, $mod, $err) = @_;
  my ($dir, $flg, @tbl);

  unless (-d $pth)
  { $flg = $slf->is_absolute($pth);
    $mod = 0750 unless defined($mod);
    ($dir, @tbl) = $slf->split_dir($pth);
    die sprintf("%s '%s'\n %s\n",
      $err || "RDA-01201: Cannot create the directory", $dir, $!)
      unless $flg || -d $dir || mkdir($dir, $mod);
    foreach my $nam (@tbl)
    { $dir = $slf->cat_dir($dir, $nam);
      die sprintf("%s '%s'\n %s\n",
      $err || "RDA-01201: Cannot create the directory", $dir, $!)
        unless -d $dir || mkdir($dir, $mod);
    }
  }
  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>current_dir>

This method returns a string representation of the current directory (C<.> on
UNIX).

=cut

sub current_dir
{ '.';
}

=head2 S<RDA::Object::Rda-E<gt>delete_dir($path)>

This method deletes a directory and its content.

=cut

sub delete_dir
{ my ($slf, $pth) = @_;

  rmdir(_clean_dir($slf, $pth)) if defined($pth);
}

=head2 S<RDA::Object::Rda-E<gt>dev_null>

This method returns a string representation of the null device.

=cut

sub dev_null
{ '/dev/null';
}

=head2 S<RDA::Object::Rda-E<gt>dev_tty>

This method returns a string representation of the terminal device.

=cut

sub dev_tty
{ '/dev/tty';
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
  my ($fil, $fnd, $sep);

  if ($cmd && $pth)
  { unless (ref($pth) eq 'ARRAY')
    { $sep = $slf->get_separator;
      $pth = [split(/$sep/, $pth)];
    }

    foreach my $dir (@$pth)
    { $dir = $slf->current_dir if $dir eq '';
      if (opendir(DIR, $dir))
      { $fnd = grep {$_ eq $cmd} readdir(DIR);
        closedir(DIR);
        next unless $fnd;
        $fil = $slf->cat_file($dir, $cmd);
        return $flg ? $fil : $slf->quote($fil)
          if stat($fil) && (-f $fil || -l $fil) && -x $fil;
      }
    }
  }
  undef;
}

=head2 S<RDA::Object::Rda-E<gt>get_last_modify($file[,$default])>

This method gets the last modification date of the file. It returns the default
value when there are problems.

=cut

sub get_last_modify
{ my ($slf, $fil, $dft) = @_;
  my @sta = lstat($fil);
  defined($sta[9]) ? $sta[9] : $dft;
}

=head2 S<$h-E<gt>get_login>

This method returns the login name.

=cut

sub get_login
{ my ($slf) = @_;

  unless (exists($slf->{'_log'}))
  { eval {$slf->{'_log'} = getlogin() || getpwuid($<)};
    $slf->{'_log'} = exists($ENV{'USERNAME'}) ? $ENV{'USERNAME'} : '?' if $@;
  }
  $slf->{'_log'};
}

=head2 S<RDA::Object::Rda-E<gt>get_path>

This method returns the environment variable PATH as a list.

=cut

sub get_path
{ my (@dir);

  if (exists($ENV{'PATH'}))
  { foreach my $dir (split(':', $ENV{'PATH'}))
    { push(@dir, ($dir eq '') ? '.' : $dir);
    }
  }
  return @dir;
}

=head2 S<RDA::Object::Rda-E<gt>get_separator>

This method returns the character used as separator.

=cut

sub get_separator
{ ':';
}

=head2 S<RDA::Object::Rda-E<gt>get_title($dir,$file[,$default])>

This method extracts the short description (title) from the specified file.

=cut

sub get_title
{ my ($slf, $dir, $fil, $dft) = @_;
  my ($lin);

  # Try to extract it from the definition file
  if (open(TTL, '<'.$slf->cat_file($dir, $fil)))
  { $lin = <TTL>;
    close(TTL);
    return $1 if $lin && $lin =~ m/#\s*\Q$fil\E:\s*(.*)[\s\n\r]+$/i;
  }

  # Return the default title
  $dft;
}

=head2 S<$h-E<gt>get_user>

This method returns the user name.

=cut

sub get_user
{ my ($slf) = @_;

  unless (exists($slf->{'_usr'}))
  { eval {$slf->{'_usr'} = getpwuid($>)};
    eval {$slf->{'_usr'} = getlogin()} if $@;
    $slf->{'_usr'} = exists($ENV{'USERNAME'}) ? $ENV{'USERNAME'} : '?' if $@;
  }
  $slf->{'_usr'};
}

=head2 S<RDA::Object::Rda-E<gt>is_absolute($path)>

This method indicates whether the argument is an absolute path.

=cut

sub is_absolute
{ my ($slf, $pth) = @_;

  scalar ($pth =~ m#^/#s);
}

=head2 S<RDA::Object::Rda-E<gt>is_cygwin>

This method returns a true value whether the operating system is Cygwin.

=cut

sub is_cygwin
{ 0;
}

=head2 S<RDA::Object::Rda-E<gt>is_root_dir($path)>

This method indicates whether the path represents a root directory. It assumes
that the provided path is already cleaned.

=cut

sub is_root_dir
{ my ($slf, $pth) = @_;

  $pth eq '/';
}

=head2 S<RDA::Object::Rda-E<gt>is_unix>

This method returns a true value if the operating system belongs to the UNIX
family.

=cut

sub is_unix
{ 1;
}

=head2 S<RDA::Object::Rda-E<gt>is_vms>

This method returns a true value if the operating system is VMS.

=cut

sub is_vms
{ 0;
}

=head2 S<RDA::Object::Rda-E<gt>is_windows>

This method returns a true value if the operating system belongs to the
Windows family.

=cut

sub is_windows
{ 0;
}

=head2 S<RDA::Object::Rda-E<gt>kill_child($pid)>

This method kills a child process.

=cut

sub kill_child
{ my ($slf, $pid) = @_;

  kill(9, $pid);
}

=head2 S<RDA::Object::Rda-E<gt>native($path)>

This method converts the path to its native representation. It does not make
any transformation for UNIX.

=cut

sub native
{ my ($slf, $pth) = @_;

  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>quote($str[,$flag])>

This method encodes a string to be considered as a single argument by a command
shell. When the flag is set, variable substitution is disabled also.

=cut

sub quote
{ my ($slf, $str, $flg) = @_;

  return $str unless defined($str)
    && $str =~ m/[\s\&\(\)\[\]\{\}\|\<\>\^\!\"\'\`\~\*\?\$\#\\]/;
  $str =~ s#([\"\`\\])#\\$1#g;
  $str =~ s#\$#\\\$#g if $flg;
  '"'.$str.'"';
}

=head2 S<RDA::Object::Rda-E<gt>short($path)>

This method converts the path to its native representation using only short
names. It does not make any transformation for UNIX.

=cut

sub short
{ my ($slf, $pth) = @_;

  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>split_dir($path)>

This method returns the list of directories contained in the specified path. It
returns an empty list when the path is missing.

=cut

sub split_dir
{ my ($slf, $pth) = @_;

  return () unless defined($pth);
  split(/\//, $pth, -1);
}

=head2 S<RDA::Object::Rda-E<gt>split_volume($path)>

This method separates the volume from the other path information. It returns an
empty list when the path is missing.


=cut

sub split_volume
{ my ($slf, $pth) = @_;

  return () unless defined($pth);
  ('', $pth);
}

=head2 S<RDA::Object::Rda-E<gt>up_dir>

This method returns a string representation of the parent directory (C<..> on
UNIX).

=cut

sub up_dir
{ '..';
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
  $@ ? ['?', '?', '?', '?', '?'] : $sys;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
