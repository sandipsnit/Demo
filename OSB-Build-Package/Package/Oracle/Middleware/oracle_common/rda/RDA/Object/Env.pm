# Env.pm: Class Used for Managing Environment Variables

package RDA::Object::Env;

# $Id: Env.pm,v 2.13 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Env.pm,v 2.13 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Env - Class Used for Managing Environment Variables

=head1 SYNOPSIS

require RDA::Object::Env;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Env> class are used for managing environment
variables. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Object;
  use RDA::Object::Rda;
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.13 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'getEnv'     => ['${CUR.ENV}', 'get_value'],
    'grepEnv'    => ['${CUR.ENV}', 'grep'],
    'replaceEnv' => ['${CUR.ENV}', 'resolve'],
    'setEnv'     => ['${CUR.ENV}', 'set_value'],
    'source'     => ['${CUR.ENV}', 'source'],
    'unsource'   => ['${CUR.ENV}', 'unsource'],
    },
  beg => \&_begin_env,
  end => \&_end_env,
  inc => [qw(RDA::Object)],
  met => {
    'clone'         => {ret => 0},
    'find'          => {ret => 0},
    'get_list'      => {ret => 1},
    'get_separator' => {ret => 0},
    'get_value'     => {ret => 0},
    'grep'          => {ret => 1},
    'resolve'       => {ret => 0},
    'source'        => {ret => 0},
    'unsource'      => {ret => 0},
    'set_value'     => {ret => 0},
    },
  );

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Env-E<gt>new>

The object constructor. It also takes a copy of the environment variables and
considers the object as read-only.

C<RDA::Object:Env> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_bkp'> > Hash that contains the saved values

=item S<    B<'_env'> > Hash that contains the original environment variables

=item S<    B<'_ref'> > Environment reference indicator

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls) = @_;
  my ($env, $slf);

  # Create the object
  $slf = bless {
    _env => $env = {},
    _ref => 1,
    }, ref($cls) || $cls;

  # Take a copy of the environment variables
  eval
  { foreach my $key (keys(%ENV))
    { $env->{$key} = $ENV{$key};
    }
  };
  die "RDA-01190: Cannot access environment variables:\n $@\n" if $@;

  # Restore original environment variables
  foreach my $key (grep {m/^RDA_ALTER_/} keys(%$env))
  { next unless delete($env->{$key}) =~ m/^(\w+)=(.*)$/;
    if (length($2))
    { $env->{$1} = $2;
    }
    else
    { delete($env->{$1});
    }
  }

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>clone>

This method clones the environment variable object and returns a reference
to the new object. Modifications are allowed in that new object.

=cut

sub clone
{ my ($slf) = @_;

  bless {
    _env => {%{$slf->{'_env'}}},
    _ref => 0,
  }, ref($slf);
}

=head2 S<$h-E<gt>find($cmd[,$flg])>

This method explores the path to find where a command is located. When the
command is found, it returns a full path name. Otherwise, it returns an
undefined variable. It only considers files or symbolic links in its search. If
the flag is set, the file path is quoted as required by a command shell.

=cut

sub find
{ my ($slf, @arg) = @_;

  RDA::Object::Rda->find_path($slf->{'_env'}->{'PATH'}, @arg);
}

=head2 S<$h-E<gt>get_list($key[,$flg])>

This method returns the value of the specified environment variable as a
list. The operating system specific separator is used to split the value. It
returns an empty list when the environment variable is not defined.

If the flag is set, the value is retrieved from the current environment instead
of the local copy.

=cut

sub get_list
{ my ($slf, $key, $flg) = @_;
  my ($val);

  if ($flg)
  { return () unless exists($ENV{$key});
    $val = $ENV{$key};
  }
  else
  { return () unless exists($slf->{'_env'}->{$key});
    $val = $slf->{'_env'}->{$key};
  }
  split(RDA::Object::Rda->get_separator, $val, -1);
}

=head2 S<$h-E<gt>get_separator>

This method returns the operating system specific value separator.

=cut

sub get_separator
{ RDA::Object::Rda->get_separator;
}

=head2 S<$h-E<gt>get_value($key[,$dft[,$flg]])>

This method returns the value of the specified environment variable. It returns
the default value when the environment variable is not defined.

If the flag is set, it retrieves the value from the current environment instead
of the local copy.

=cut

sub get_value
{ my ($slf, $key, $val, $flg) = @_;

  if ($flg)
  { $val = $ENV{$key} if exists($ENV{$key});
  }
  else
  { $val = $slf->{'_env'}->{$key} if exists($slf->{'_env'}->{$key});
  }
  if (wantarray)
  { return ($val) if defined($val);
    return ();
  }
  $val;
}

=head2 S<$h-E<gt>grep($re[,$opt])>

This method returns the list of all environment variables with names that
match the regular expression. It supports the following attributes:

=over 9

=item B<    'f' > Stops the scanning on the first match

=item B<    'i' > Ignores case distinctions in both the pattern and the name

=item B<    'v' > Inverts the sense of matching, to select nonmatching lines

=back

=cut

sub grep
{ my ($slf, $re, $opt) = @_;
  my ($flg, $inv, $one, @tbl);

  # Decode the options
  $opt = '' unless defined($opt);
  $re = (index($opt, 'i') < 0) ? qr#$re# : qr#$re#i;
  $inv = index($opt, 'v') >= 0;
  $one = index($opt, 'f') >= 0;

  # Scan the variables
  foreach my $key (sort keys(%{$slf->{'_env'}}))
  { $flg = ($key =~ $re);
    if ($inv ? !$flg : $flg)
    { push(@tbl, $key);
      last if $one;
    }
  }

  # Return the variable list
  @tbl;
}

=head2 S<$h-E<gt>resolve($str)>

This method replaces all environment variable references contained in the
specified string.

For UNIX, C<$name>, C<${name}>, and C<${name:-text}> are resolved. For Windows,
C<%name%> format is supported. No replacements are performed for VMS.

=cut

sub resolve
{ my ($slf, $str, $flg) = @_;

  if (defined($str))
  { if (RDA::Object::Rda->is_unix)
    { $str =~ s#\$(\w+)#_repl_unix1($slf, $1)#eg;
      $str =~ s#\$\{(\w+)\}#_repl_unix1($slf, $1)#eg;
      1 while $str =~ s#\$\{(\w+)\:\-([^\{\}]*)\}#_repl_unix2($slf, $1, $2)#eg;
    }
    elsif (RDA::Object::Rda->is_windows || RDA::Object::Rda->is_cygwin)
    { if ($flg)
      { $str =~ s#\$(\w+)#_repl_windows($slf, $1, '')#eg;
        $str =~ s#\$\{(\w+)\}#_repl_windows($slf, $1, '')#eg;
        1 while $str =~
                s#\$\{(\w+)\:\-([^\{\}]*)\}#_repl_windows($slf, $1, $2)#eg;
      }
      else
      { $str =~ s#\%(\w+)\%#_repl_windows($slf, $1, '')#eg;
      }
    }
  }
  $str;
}

sub _repl_unix1
{ my ($slf, $nam) = @_;

  exists($slf->{'_env'}->{$nam}) ? $slf->{'_env'}->{$nam} : '';
}

sub _repl_unix2
{ my ($slf, $nam, $alt) = @_;

  my $str = exists($slf->{'_env'}->{$nam}) ? $slf->{'_env'}->{$nam} : '';
  length($str) ? $str : $alt;
}

sub _repl_windows
{ my ($slf, $nam, $alt) = @_;
  my ($str);

  return $str
    if exists($slf->{'_env'}->{$nam}) && length($str = $slf->{'_env'}->{$nam});
  $nam = "\%$nam\%";
  ($str) = `cmd /c echo $nam`;
  $str =~ s/"?[\n\r]+$//;
  ($str ne $nam && length($str)) ? $str : $alt;
}

=head2 S<$h-E<gt>set_value($key[,$val[,$flg]])>

This method sets the value of the specified environment variable. When the
value is undefined, the variable is deleted. When the flag is set, it
adjusts the internal copy of the environment variable also. An error is raised
when trying to modify the read-only copy of the environment variables.

It returns the previous value of the environment variable.

=cut

sub set_value
{ my ($slf, $key, $val, $flg) = @_;
  my $old;

  die "RDA-01191: Read-only copy of the environment variables\n"
    if $flg && $slf->{'_ref'};

  $old = $ENV{$key} if exists($ENV{$key});
  if (defined($val))
  { $ENV{$key} = $val;
    $slf->{'_env'}->{$key} = $val if $flg;
  }
  else
  { delete($ENV{$key});
    delete($slf->{'_env'}->{$key}) if $flg;
  }
  $old;
}

=head2 S<$h-E<gt>source($pgm[,$flg[,$shl]])>

This method uses the program that is specified as an argument to modify the
environment. The program is sourced in 'sh' for UNIX or executes with 'cmd' for
Windows. Unless the flag is set, the method modifies the internal copy of the
environment variables only. For UNIX, you can provide the shell for sourcing
the program.

It raises an error when trying to modify the read-only copy of the environment
variables.

It returns the number of modified variables.

=cut

sub source
{ my ($slf, $pgm, $flg, $shl) = @_;
  my ($cmd, $cnt, $ref, %env);

  die "RDA-01191: Read-only copy of the environment variables\n"
    if $slf->{'_ref'};

  # Initialization
  if (RDA::Object::Rda->is_windows
    || (RDA::Object::Rda->is_cygwin && $pgm =~ m/\.(bat|cmd)$/i))
  { $ref = "cmd /C \"set\" |";
    $cmd = "cmd /C \"$pgm 2>NUL && set\" |";
  }
  else
  { $shl = "sh" unless defined($shl) && -x $shl;
    $ref = "$shl -c 'env' |";
    $cmd = "$shl -c '. $pgm 2>/dev/null ; env' |";
  }

  # Take a copy of the current environment
  return 0 unless open(IN, $ref);
  while (<IN>)
  { s/[\r\n]*$//;
    $env{$1} = $2 if m/^(\w+)=(.*)$/;
  }
  close(IN);

  # Compare with the modified environment
  return 0 unless $pgm && open(IN, $cmd);
  $cnt = 0;
  while (<IN>)
  { s/[\r\n]*$//;
    if (m/^(\w+)=(.*)$/ && (!exists($env{$1}) || $env{$1} ne $2))
    { $slf->{'_env'}->{$1} = $2;
      ($ENV{$1}, $slf->{'_bkp'}->{$1}) = ($2, $ENV{$1}) if $flg;
      ++$cnt;
    }
  }
  close(IN);

  # Returns the number of modified variables
  $cnt;
}

=head2 S<$h-E<gt>unsource>

This method undoes changes made to environment variables performed by previous
C<source> calls. It returns the number of restored variables.

=cut

sub unsource
{ my ($slf) = @_;
  my ($cnt, $tbl, $val);

  $cnt = 0;
  if (exists($slf->{'_bkp'}))
  { foreach my $key (keys(%{$tbl = $slf->{'_bkp'}}))
    { if (defined($val = $tbl->{$key}))
      { $ENV{$key}  = $val;
      }
      else
      { delete($ENV{$key});
      }
      ++$cnt;
    }
    delete($slf->{'_bkp'});
  }

  # Returns the number of modified variables
  $cnt;
}

# --- SDCL extensions ---------------------------------------------------------

# Define a package attribute to access environment variables
sub _begin_env
{ my ($pkg) = @_;

  $pkg->set_info('env',
    $pkg->get_agent->get_registry('env', \&new, __PACKAGE__)->clone);
}

# Restore the environment
sub _end_env
{ shift->get_info('env')->unsource;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
