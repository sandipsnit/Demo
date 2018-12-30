# Windows.pm: Windows Methods for RDA::Object::Rda

package RDA::Local::Windows;

# $Id: Windows.pm,v 2.11 2012/04/25 06:38:59 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Local/Windows.pm,v 2.11 2012/04/25 06:38:59 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Local::Windows - Windows Methods for RDA::Object::Rda

=head1 SYNOPSIS

require RDA::Local::Windows;

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
$VERSION = sprintf("%d.%02d", q$Revision: 2.11 $ =~ /(\d+)\.(\d+)/);

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

=head2 S<RDA::Object::Rda-E<gt>arg_dir([$dir...,]$dir)>

This method performs a C<cat_dir> and quotes the result.

=cut

sub arg_dir
{ my $slf = shift;

  $slf->quote($slf->cat_dir(@_));
}

=head2 S<RDA::Object::Rda-E<gt>arg_file([$dir...,]$file)>

This method performs a C<cat_file> and quotes the result.

=cut

sub arg_file
{ my $slf = shift;

  $slf->quote($slf->cat_file(@_));
}

=head2 S<RDA::Object::Rda-E<gt>clean_path($path)>

This method performs a logical cleanup of a path. It removes successive slashes
and successives C<\.>. It attempts to further reduce the number of C<\..>
present in the path.

=cut

sub clean_path
{ my ($slf, $pth) = @_;
  my ($vol);

  if (ref($pth) eq 'ARRAY')
  { foreach my $itm (@$pth)
    { $itm =~ s/^"(.*)"$/$1/;
    }
    $pth = join('/', @$pth);
  }

  $pth =~ s#/#\\#g;                   # x/x     -> x\x
  $vol = ($pth =~ s#^(\\\\[^\\]+)(\\|\z)#\\#s) ? $1 :
         ($pth =~ s#^([a-z]:)##is)             ? uc($1) :
                                                 '';
  $pth =~ s#\\+#\\#g;                 # x\\\\x  -> x\x
  $pth =~ s#(\\\.)+(\\|\z)#\\#g;      # x\.\.\x -> x\x
  $pth =~ s#^(\.\\)+(.)#$2#s;         # .\x     -> x
  $pth =~ s#^(\\\.\.)+(\\|\z)#\\#s;   # \..\..  -> \
  $pth =~ s#(.)\\$#$1#;               # x\      -> x

  if ($pth =~ m#\\\.\.(\\|\z)#)
  { my ($itm, @tbl);

    foreach $itm (split(/\\/, $pth, -1))
    { if ($itm eq '..' && @tbl)
      { $itm = pop(@tbl);
        push(@tbl, $itm)       if $itm eq '';
        push(@tbl, $itm, '..') if $itm eq '..';
      }
      else
      { push(@tbl, $itm);
      }
    }
    $pth = ((scalar @tbl) > 1)        ? join('\\', @tbl) :
           !defined($itm = pop(@tbl)) ? '.' :
           ($itm eq '')               ? '\\' :
                                        $itm;
  }

  $vol.$pth;
}

=head2 S<RDA::Object::Rda-E<gt>dev_null>

This method returns a string representation of the null device.

=cut

sub dev_null
{ 'nul';
}

=head2 S<RDA::Object::Rda-E<gt>dev_tty>

This method returns a string representation of the terminal device.

=cut

sub dev_tty
{ 'con';
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

=head2 S<RDA::Object::Rda-E<gt>get_path>

This method returns the environment variable PATH as a list.

=cut

sub get_path
{ my ($pth, @dir);

  $pth = exists($ENV{'PATH'}) ? $ENV{'PATH'} :
         exists($ENV{'Path'}) ? $ENV{'Path'} :
         exists($ENV{'path'}) ? $ENV{'path'} :
                                undef;
  if (defined($pth))
  { foreach my $dir (split(';', $pth))
    { push(@dir, ($dir eq '') ? '.' : $dir);
    }
  }
  return @dir;
}

=head2 S<RDA::Object::Rda-E<gt>get_separator>

This method returns the character used as separator.

=cut

sub get_separator
{ ';';
}

=head2 S<RDA::Object::Rda-E<gt>is_absolute($path)>

This method indicates whether the argument is an absolute path.

=cut

sub is_absolute
{ my ($slf, $pth) = @_;

  scalar ($pth =~ m#^([a-z]:)?[\\/]#is);
}

=head2 S<RDA::Object::Rda-E<gt>is_root_dir($path)>

This method indicates whether the path represents a root directory. It assumes
that the provided path is already cleaned.

=cut

sub is_root_dir
{ my ($slf, $pth) = @_;

  $pth =~ s#^[a-z]:##is;
  $pth eq '\\';
}

=head2 S<RDA::Object::Rda-E<gt>is_unix>

This method returns a true value if the operating system belongs to the UNIX
family.

=cut

sub is_unix
{ 0;
}

=head2 S<RDA::Object::Rda-E<gt>is_windows>

This method returns a true value if the operating system belongs to the Windows
family.

=cut

sub is_windows
{ 1;
}

=head2 S<RDA::Object::Rda-E<gt>kill_child($pid)>

This method kills a child process tree when possible.

=cut

sub kill_child
{ my ($slf, $pid) = @_;

  # On recent Perl versions, kill the process tree
  return kill(-9, $pid) unless $] < 5.008009;

  # Try to kill the process tree with taskkill 
  eval {`taskkill /F /T /pid $pid 2>NUL`};

  # Otherwise, kill the process
  kill(9, $pid);
}

=head2 S<RDA::Object::Rda-E<gt>native($path)>

This method converts the path to its Windows representation.

=cut

sub native
{ my ($slf, $pth) = @_;

  $pth =~ s#^([a-z]:)#\U$1\Q#;
  $pth =~ s#/#\\#g;
  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>quote($str[,$flg])>

This method encodes a string to be considered as a single argument by a command
shell. When the flag is set, variable substitution is disabled also.

=cut

sub quote
{ my ($slf, $str, $flg) = @_;

  return $str unless defined($str)
    && $str =~ m/[\s\&\(\)\[\]\{\}\|\<\>\^\=\!\"\'\`\+\,\~\*\?\%]/;
  $str =~ s#"#"^""#g;
  $str =~ s#\%#"^\%"#g if $flg;
  '"'.$str.'"';
}

=head2 S<RDA::Object::Rda-E<gt>short($path)>

This method converts the path to its native representation using only short
names.

=cut

sub short
{ my ($slf, $pth) = @_;

  $pth =~ s#^([a-z]:)#\U$1\Q#;
  $pth =~ s#[//\\]#\\\\#g;
  ($pth) = `cmd /q /c "FOR %D IN (\042$pth\042) DO ECHO %~sD"`;
  $pth =~ s/[\n\r]+$//;
  $pth;
}

=head2 S<RDA::Object::Rda-E<gt>split_dir($path)>

This method returns the list of directories contained in the specified
path. The first element will contain the volume information. It returns an
empty list when the path is missing.

=cut

sub split_dir
{ my ($slf, $pth) = @_;
  my ($vol, @dir);

  if (defined($pth))
  { ($vol, $pth) = $slf->split_volume($pth);
    @dir = split(/\\/, $pth, -1);
    $dir[0] = $vol.$dir[0];
  }
  @dir;
}

=head2 S<RDA::Object::Rda-E<gt>split_volume($path)>

This method separates the volume from the other path information. It returns an
empty list when the path is missing.

=cut

sub split_volume
{ my ($slf, $pth) = @_;
  my ($vol);

  return () unless defined($pth);
  $pth =~ s#/#\\#g;
  $vol = ($pth =~ s#^(\\\\[^\\]+)\\?\z#\\#s) ? $1 :
         ($pth =~ s#^(\\\\[^\\]+\\)##s)      ? $1 :
         ($pth =~ s#^([a-z]:)##is)           ? uc($1) :
                                               '';
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

# --- Private routines --------------------------------------------------------

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
