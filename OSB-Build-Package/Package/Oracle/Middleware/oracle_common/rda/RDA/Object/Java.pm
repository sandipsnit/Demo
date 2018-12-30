# Java.pm: Class Used for Managing Java Classes

package RDA::Object::Java;

# $Id: Java.pm,v 1.18 2012/05/14 04:50:23 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Java.pm,v 1.18 2012/05/14 04:50:23 mschenke Exp $
#
# Change History
# 20120515  MSC  Force native in CLASSPATH.

=head1 NAME

RDA::Object::Java - Class Used for Managing Java Classes

=head1 SYNOPSIS

require RDA::Object::Java;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Java> class are used to manage Java
classes. It is a subclass of L<RDA::Object|RDA::Object>.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Copy;
  use IO::File;
  use IO::Handle;
  use RDA::Block qw($SPC_OBJ $SPC_REF $SPC_VAL $CONT);
  use RDA::Object;
  use RDA::Object::Rda qw($CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  cmd => {
    'java' => [\&_exe_java, \&_get_java, 'T', \&_parse_java],
    },
  beg => \&_begin_java,
  dep => [qw(RDA::Object::Inline)],
  inc => [qw(RDA::Object)],
  met => {
    'get_info'      => {ret => 0},
    'set_info'      => {ret => 0},
    },
  );

# Define the global private constants
my $JAVA = 'Java';

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Java-E<gt>new($nam,$cod[,$ver[,$pkg]])>

The master control object constructor. This method takes the block name, the
code line array, the Java version, and the package as arguments.

The control objects are represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'err' > > Error indicator

=item S<    B<'oid' > > Object identifier

=item S<    B<'pre' > > Trace prefix

=item S<    B<'_cod'> > Java code lines

=item S<    B<'_dep'> > Dependency hash

=item S<    B<'_err'> > Standard error file

=item S<    B<'_exe'> > Class file

=item S<    B<'_jar'> > Associated jar files

=item S<    B<'_jdk'> > Current JDK

=item S<    B<'_out'> > Standard output file

=item S<    B<'_seq'> > Execution sequencer

=item S<    B<'_sub'> > Optional subdirectory

=item S<    B<'_typ'> > Block type

=item S<    B<'_ver'> > Optional source Java version

=back

=cut

sub new
{ shift->new_block('M', @_);
}

sub new_block
{ my ($cls, $typ, $oid, $cod, $ver, $pkg) = @_;
  my ($slf, $sub);

  # Create the object
  $slf = bless {
    err  => 0,
    oid  => $oid,
    pre  => '',
    _cod => $cod,
    _dep => [],
    _jar => [],
    _typ => $typ,
    }, ref($cls) || $cls;
  if (defined($pkg))
  { $sub = $pkg;
    $sub =~ s#\.#/#g;
    $slf->{'_sub'} = $sub;
  }
  $slf->{'_ver'} = $ver if defined($ver) && $ver =~ m/^\d+(\.\d+)?$/;

  # Check the Java code and return the object reference
  $slf->check;
}

=head2 S<$h-E<gt>add_dependency($dep)>

This method adds the specified block in the dependency list. It returns the
object reference.

=cut

sub add_dependency
{ my ($slf, $dep) = @_;

  die "RDA-01428: Main block required\n" unless $slf->{'_typ'} eq 'M';
  push(@{$slf->{'_dep'}}, $dep);

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>add_jar($jar)>

This method associates the specified jar file for compilation and execution. It
returns the object reference.

=cut

sub add_jar
{ my ($slf, $jar) = @_;

  push(@{$slf->{'_jar'}}, RDA::Object::Rda->native($jar))
    if -f $jar || -d $jar;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>add_sequence>

This method adds a sequencer to make the file names unique. It returns the
object reference.

=cut

sub add_sequence
{ my ($slf) = @_;

  $slf->{'_seq'} = 0;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>check>

This method checks that the code is conform to its type. It returns the object
reference.

=cut

sub check
{ my ($slf) = @_;
  my ($err, $nam, $nxt, $pat, $tbl, $typ, %tbl);

  # Determine the validation rules
  $nam = $slf->{'oid'};
  $typ = $slf->{'_typ'};
  %tbl = (
  C => {top => [qr/^\s*(public\s+)?class\s+\Q$nam\E\b/m,
                'RDA-01420: Missing public class definition',
                'end'],
        end => [],
       },
  I => {top => [qr/^\s*(public\s+)?interface\s+\Q$nam\E\b/m,
                'RDA-01427: Missing public interface definition',
                'end'],
        end => [],
       },
  M => {top => [qr/^\s*(public\s+)?(static\s+)?class\s+\Q$nam\E\b/m,
                'RDA-01420: Missing public class definition',
                'met'],
        end => [],
        met => [qr/^[\{\s]*public\s+static\s+void\s+main\b/m,
                'RDA-01421: Missing main method definition',
                'end'],
       },
  );
  die "Invalid block type '$typ'\n" unless exists($tbl{$typ});
  $tbl = $tbl{$typ};

  # Apply the validation rules
  ($pat, $err, $nxt) = @{$tbl->{'top'}};
  CHECK: foreach my $lin (@{$slf->{'_cod'}})
  { while ($lin =~ $pat)
    { ($pat, $err, $nxt) = @{$tbl->{$nxt}};
      last CHECK unless $nxt;
    }
  }
  die "$err in '$nam'\n" if $err;

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>clear>

This method removes the associated files.

=cut

sub clear
{ my ($slf) = @_;
  my ($pth);

  foreach my $key (qw(_out _err))
  { next unless defined($pth = delete($slf->{$key}));
    1 while unlink($pth);
  }
  $slf;
}

=head2 S<$h-E<gt>compile($ctl)>

This method compiles the code.

=cut

sub compile
{ my ($slf, $ctl) = @_;
  my ($bkp, $cmd, $ctx, $dir, $err, $exe, $nam, $ofh, $ret, $src, $trc, @opt);

  # Get the language context
  $ctx = $ctl->get_context($JAVA);
  $trc = $ctx->{'TRACE'} ? 'JAVA]' : '';

  # Compile the Java class when not yet available
  $dir = exists($slf->{'_sub'})
    ? RDA::Object::Rda->create_dir(RDA::Object::Rda->cat_dir($ctl->get_cache,
        $slf->{'_sub'}))
    : $ctl->get_cache;
  $nam = $slf->{'oid'};
  $exe = RDA::Object::Rda->cat_file($dir, $nam.$ctx->{'EXE'});
  if ($ctx->{'CACHE'} && -f $exe)
  { print "JAVA] Reuse: $exe\n" if $trc;
  }
  elsif ($ctx->{'CACHE'} && -f ($src = $ctl->get_compiled($nam.$ctx->{'EXE'})))
  { print "JAVA] Use: $src\n" if $trc;
    copy($src, $exe) or die "RDA-01422: Copy error:\n $!\n";
  }
  elsif (defined($cmd = _find_cmd($slf, $ctx, 'JAVAC', 'javac')))
  { # Write the source file
    $ofh = IO::File->new;
    $src = RDA::Object::Rda->cat_file($dir, $nam.$ctx->{'SRC'});
    print "JAVA] Save block $src\n" if $trc;
    if ($ofh->open($src, $CREATE, $FIL_PERMS))
    { print {$ofh} join("\n", @{$slf->{'_cod'}}, '');
      $ofh->close;
    }

    # Modify the environment
    $bkp = $ctl->set_env({
      CLASSPATH => join($ctx->{'SEP'},
                     RDA::Object::Rda->native($ctl->get_cache),
                     @{$slf->{'_jar'}},
                     map {RDA::Object::Rda->native($_)} @{$ctx->{'classpath'}}),
      }, $trc);

    # Compile the Java class
    $err = RDA::Object::Rda->cat_file($dir, $nam.'.err');
    @opt = ('-deprecation');
    push(@opt, '-source', $slf->{'_ver'},'-Xlint:none')
      if exists($slf->{'_ver'});
    $cmd = _conv_cmd(join(' ', $cmd, @opt,
      RDA::Object::Rda->quote(RDA::Object::Rda->native($src)),
      '>'.RDA::Object::Rda->quote($err), "2>&1"));
    print "JAVA] Execute: $cmd\n" if $trc;
    $ret = system($cmd);
    print "JAVA] Compilation exit code: $ret\n" if $trc;
    if (-s $err)
    { $slf->{'err'} = 1;
      1 while unlink($exe);
      die "RDA-01424: Error encountered when compiling Java block '$nam'\n";
    }
    1 while unlink($err);

    # Restore the environment
    $ctl->restore_env($bkp);

    # Remove the source file
    unless ($ctx->{'KEEP'})
    { 1 while unlink($src);
    }
  }
  else
  { $slf->{'err'} = 1;
    die "RDA-01423: Missing Java compiler\n";
  }
  $slf->{'_exe'} = $exe;

  # Return the completion status
  $ret;
}

=head2 S<$h-E<gt>execute($ctl,@arg)>

This method executes the named block in the specified context.

=cut

sub execute
{ my ($slf, $ctl, @arg) = @_;
  my ($bkp, $cls, $cmd, $ctx, $dir, $err, $ifh, $lim, $nam, $out, $pid, $trc,
      @tbl);

  # Get the language context
  $ctx = $ctl->get_context($JAVA);
  die "RDA-01425: Missing Java configuration\n"
    unless defined($cmd = _find_cmd($slf, $ctx, 'JAVA', 'java'));
  $lim = $ctx->{'TIMEOUT'};
  $trc = $ctx->{'TRACE'} ? 'JAVA]' : '';

  # Modify the environment
  $dir = $ctl->get_cache;
  $bkp = $ctl->set_env({
    CLASSPATH => join($ctx->{'SEP'},
                   RDA::Object::Rda->native($dir),
                   @{$slf->{'_jar'}},
                   map {RDA::Object::Rda->native($_)} @{$ctx->{'classpath'}}),
    }, $trc);

  # Execute the Java code
  $cls = $nam = $slf->{'oid'};
  $nam .= '_'.(++$slf->{'_seq'}) if exists($slf->{'_seq'});
  $out = RDA::Object::Rda->cat_file($dir, "$nam.out");
  $err = RDA::Object::Rda->cat_file($dir, "$nam.err");
  $cmd = _conv_cmd(join(' ', $cmd, $cls, (grep {defined($_) && !ref($_)} @arg),
    '>'.RDA::Object::Rda->quote($out),
    '2>'.RDA::Object::Rda->quote($err)));
  print "JAVA] Execute: $cmd\n"   if $trc;
  print "JAVA] Limit: $lim sec\n" if $lim;
  eval {
    local $SIG{'ALRM'} = sub { die "Alarm\n" } if $lim;
    alarm($lim) if $lim;
    close(OUT) if ($pid = open(OUT, "| $cmd"));
    alarm(0) if $lim;
  };
  if ($@)
  { print "JAVA] Process identifier: $pid\n" if $trc;
    RDA::Object::Rda->kill_child($pid);
    $ctl->{'pkg'}->get_agent->log_timeout($ctl->{'pkg'}, "$JAVA.$cls", @arg);
    print "JAVA] Execution timeout\n" if $trc;
  }

  # Restore the environment
  $ctl->restore_env($bkp);

  # Extract and return the results
  die "RDA-01426: Error encountered when executing Java block '$cls'\n"
    if -s $err;
  1 while unlink($err);
  $ifh = IO::File->new;
  if ($ifh->open("<$out"))
  { while(<$ifh>)
    { s/[\n\r\s]+$//;
      push(@tbl, $_);
      print "JAVA> $_\n" if $trc;
    }
    $ifh->close;
  }
  unless ($ctx->{'KEEP'})
  { 1 while unlink($out);
  }
  @tbl;
}

=head2 S<$h-E<gt>get_language>

This method returns the block language.

=cut

sub get_language
{ $JAVA;
}

=head2 S<$h-E<gt>get_name>

This method returns the block name.

=cut

sub get_name
{ shift->{'oid'};
}

=head2 S<$h-E<gt>has_errors>

This method indicates whether the named block or its dependencies has errors.

=cut

sub has_errors
{ my ($slf) = @_;

  foreach my $dep (@{$slf->{'_dep'}})
  { return 1 if $dep->{'err'};
  }
  $slf->{'err'};
}

=head2 S<RDA::Object::Java-E<gt>init($ctx, $agt)>

This method initializes the compilation and execution context.

=cut

sub init
{ my ($slf, $ctx, $agt) = @_;
  my ($tbl);

  # Initialize the context
  $ctx->{'BIN'} = 'bin' unless exists($ctx->{'BIN'});
  $ctx->{'EXE'} = '.class';
  $ctx->{'SRC'} = '.java';
  $ctx->{'SEP'} = RDA::Object::Rda->is_windows ? ';' :
                  RDA::Object::Rda->is_cygwin  ? ';' :
                                                 ':';

  # Clean up the Java class path
  $ctx->{'classpath'} = $tbl = [];
  if (exists($ENV{'CLASSPATH'}))
  { foreach my $pth (split($ctx->{'SEP'}, $ENV{'CLASSPATH'}))
    { $pth =~ s/^\s+//;
      $pth =~ s/\s+$//;
      push(@$tbl, $pth) if -e $pth;
    }
  }

  # Keep the agent reference
  $ctx->{'Agt'} = $agt;

  # Return the context description
  $ctx;
}

=head2 S<$h-E<gt>is_compiled>

This method indicates whether the named block is already compiled.

=cut

sub is_compiled
{ my ($slf) = @_;

  exists($slf->{'_exe'}) && -f $slf->{'_exe'};
}

=head2 S<$h-E<gt>launch($ofh,$ctl,@arg)>

This method creates a pipe to the named block, which is executed in the
specified context with the specified arguments. It returns the process
identifier in a scalar context, the process identifier, the output and error
files in a list context.

=cut

sub launch
{ my ($slf, $ofh, $ctl, @arg) = @_;
  my ($bkp, $cls, $cmd, $ctx, $dir, $err, $ifh, $nam, $out, $pid, $trc);

  # Get the language context
  $ctx = $ctl->get_context($JAVA);
  die "RDA-01425: Missing Java configuration\n"
    unless defined($cmd = _find_cmd($slf, $ctx, 'JAVA', 'java'));
  $trc = $slf->{'pre'}   ? $slf->{'pre'}.']' :
         $ctx->{'TRACE'} ? 'JAVA]' :
                           '';

  # Modify the environment
  $dir = $ctl->get_cache;
  $bkp = $ctl->set_env({
    CLASSPATH => join($ctx->{'SEP'},
                   RDA::Object::Rda->native($dir),
                   @{$slf->{'_jar'}},
                   map {RDA::Object::Rda->native($_)} @{$ctx->{'classpath'}}),
    }, $trc);

  # Execute the Java code
  $cls = $nam = $slf->{'oid'};
  $nam .= '_'.(++$slf->{'_seq'}) if exists($slf->{'_seq'});
  $err = RDA::Object::Rda->cat_file($dir, "$nam.err");
  $out = RDA::Object::Rda->cat_file($dir, "$nam.out");
  $cmd = join(' ', $cmd, $cls, (grep {defined($_) && !ref($_)} @arg));
  $cmd .= ' >'.RDA::Object::Rda->quote($out) unless $trc;
  $cmd .= ' 2>'.RDA::Object::Rda->quote($err);
  $cmd = _conv_cmd($cmd);
  print "$trc Launch: $cmd\n" if $trc;
  $pid = $ofh->open("| $cmd");
  print "$trc Pid: $pid\n" if $trc;
  unless ($ctx->{'KEEP'})
  { $slf->{'_err'} = $err;
    $slf->{'_out'} = $out;
  }

  # Restore the environment
  $ctl->restore_env($bkp);

  # Return the process identifier
  return ($pid, $out, $err) if wantarray;
  $pid;
}

=head2 S<$h-E<gt>prepare($ctl)>

This method compiles the code when not yet available.

=cut

sub prepare
{ my ($slf, $ctl) = @_;

  die "RDA-01428: Main block required\n" unless $slf->{'_typ'} eq 'M';
  foreach my $dep (@{$slf->{'_dep'}})
  { $dep->compile($ctl) unless $dep->is_compiled;
  }
  $slf->compile($ctl) unless $slf->is_compiled;
}

# --- Internal routines -------------------------------------------------------

# Adapt the command for VMS
sub _conv_cmd
{ my ($cmd) = @_;

  return $cmd unless $cmd;
  if (RDA::Object::Rda->is_windows)
  { $cmd =~ s#/dev/null#NUL#g;
  }
  elsif (RDA::Object::Rda->is_unix || RDA::Object::Rda->is_cygwin)
  { $cmd = "exec $cmd";
  }
  elsif (RDA::Object::Rda->is_vms && $cmd =~ m/[\<\>]/ && $cmd !~ m/^PIPE /i)
  { $cmd = "PIPE $cmd";
    $cmd =~ s/2>&1/2>SYS\$OUTPUT/g;
    $cmd =~ s#/dev/null#NLA0:#g;
  }
  $cmd;
}

# Find a JDK command commnad
sub _find_cmd
{ my ($slf, $ctx, $key, $cmd) = @_;
  my ($jdk);

  exists($ctx->{$key})
    ? $ctx->{$key} :
  ($jdk = _find_jdk($slf, $ctx))
    ? RDA::Object::Rda->quote(RDA::Object::Rda->cat_file($jdk, $ctx->{'BIN'},
                                                         $cmd)) :
  undef;
}

# Detect a JDK directory
sub _find_jdk
{ my ($slf, $ctx) = @_;
  my ($agt, $dir);

  return $dir              if defined($dir = $slf->{'_jdk'});
  return $ctx->{'HOME'}    if exists($ctx->{'HOME'});
  return $ENV{'JAVA_HOME'} if exists($ENV{'JAVA_HOME'});

  $agt = $ctx->{'Agt'};
  foreach my $key ('ORACLE_HOME', $agt->grep_setting('_ORACLE_HOME$'))
  { $dir = RDA::Object::Rda->cat_file($agt->get_setting($key), 'jdk');
    return $dir if -d $dir;
  }
  undef;
}

# --- SDCL extensions ---------------------------------------------------------

# Force a Java context
sub _begin_java
{ my ($pkg) = @_;

  $pkg->get_inline->force_context('Java');
}

# Declare a Java block
sub _exe_java
{ my ($slf, $spc) = @_;
  my ($dir, $obj);

  # Declare the block
  $obj = $spc->[$SPC_OBJ];
  $slf->get_inline->add_code($obj);
  $obj->{'_jdk'} =
    $slf->get_agent->get_target->get_current->get_detail('jdk', 'jdk');

  # Indicate the successful completion
  $CONT;
}

# Get a Java block name
sub _get_java
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_OBJ] = $1 if $$str =~ s/^(\d+(\.\d+)?)\s+//;
  die "RDA-00215: Invalid or missing name\n"
    unless $$str =~ s/^([A-Za-z]\w*)\s*//;
  $spc->[$SPC_REF] = $1;
}

# Parse a Java block
sub _parse_java
{ my ($slf, $spc) = @_;

  $slf->get_agent->get_inline->add_block($slf->get_package('oid'),
    $spc->[$SPC_OBJ] = __PACKAGE__->new($spc->[$SPC_REF], $spc->[$SPC_VAL],
      $spc->[$SPC_OBJ]));
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Inline|RDA::Object::Inline>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
