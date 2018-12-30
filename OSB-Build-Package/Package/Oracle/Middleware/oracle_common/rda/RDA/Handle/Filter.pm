# Filter.pm: Class Used to Filter RDA Output

package RDA::Handle::Filter;

# $Id: Filter.pm,v 2.9 2012/01/02 16:32:01 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Handle/Filter.pm,v 2.9 2012/01/02 16:32:01 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Handle::Filter - Class Used to Filter RDA Output

=head1 SYNOPSIS

require RDA::Handle::Filter;

=head1 DESCRIPTION

The objects of the C<RDA::Handle::Filter> class are used to filter sensitive
information out the generated reports.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use Symbol;
}

# Define the global public variables
use vars qw($VERSION @EXPORT_OK @ISA %FLT_FORMATS);
@EXPORT_OK = qw(%FLT_FORMATS);
$VERSION   = sprintf("%d.%02d", q$Revision: 2.9 $ =~ /(\d+)\.(\d+)/);
@ISA       = qw(Exporter);

# Define the global private variables
%FLT_FORMATS = (
  DFT     => '$str =~ s/\b%s\b/%s%s%s/g%s;',
  DFT_ATT => '<<$1:$4>>$str =~ s/(\b%s\s*=\s*([\'"]))(.*?)(\2)/%s%s%s/g%s;',
  DFT_HST => '<<$1:$2>>$str =~ s/(\b|\bnode|_)%s(\b|_)/%s%s%s/g%s;',
  DFT_IP4 => '<<$1:$2>>1 '.
             'while $str =~ s/(^|[^\.])\b%s\b($|[^\.])/%s%s%s/%s;',
  DFT_IP6 => '<<$1:$2>>1 '.
             'while $str =~ s/(^|[^\:\dA-F])%s($|[^\:\dA-F])/%s%s%s/i%s;',
  DFT_SYS => '<<:$1>>$str =~ s/\b%s(\b|_)/%s%s%s/g%s;',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Handle::Filter-E<gt>new($agt)>

The control object constructor. This method takes the configuration reference
as an argument.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'agt' > > Reference to the agent object

=item S<    B<'rul' > > Filter rules

=item S<    B<'sub' > > Filter function reference

=back

=head2 S<$h-E<gt>new>

The output object constructor. It derives its attributes from the control
object and it returns the output file handle.

=cut

sub new
{ my $cls = shift;
  my $slf;

  if (ref($cls))
  { # Create the filter output object
    $slf = bless Symbol::gensym(), ref($cls);
    tie *$slf, $slf;
    *$slf->{'sub'} = $cls->{'sub'};
  }
  else
  { my $agt = shift;

    # Create the filter control object
    $slf = bless {agt => $agt}, $cls;

    # Define the filter
    _def_filter($slf, $agt);
  }

  # Return the object reference
  $slf;
}

sub _def_filter
{ my ($slf, $agt) = @_;
  my ($fmt, $min, $max, $opt, $rul, $str, @tbl, %fmt);

  # Define the substitution formats
  foreach my $nam (keys(%FLT_FORMATS))
  { $fmt = $FLT_FORMATS{$nam};
    ($min, $max) = ($fmt =~ s/^<<(\$\d+)?:(\$\d+)?>>//)
      ? ($1, $2) : ('', '');
    $fmt{$nam} = [$min, $max, $fmt];
  }
  foreach my $nam (split(/\#/, $agt->get_setting('FILTER_FORMATS', '')))
  { next unless ($fmt = $agt->get_setting("FILTER_FORMAT_$nam"));
    ($min, $max) = ($fmt =~ s/^<<(\$\d+)?:(\$\d+)?>>//)
      ? ($1, $2) : ('', '');
    $fmt{$nam} = [$min, $max, $fmt];
  }

  # Get the filter rules
  foreach my $set (split(/\#/, $agt->get_setting('FILTER_SETS', '')))
  { $fmt = $agt->get_setting("FILTER_${set}_FORMAT", 'DFT');
    $opt = $agt->get_setting("FILTER_${set}_OPTIONS", '');
    $str = $agt->get_setting("FILTER_${set}_STRING", '');
    $rul = $agt->get_setting("FILTER_${set}_PATTERNS");
    next unless exists($fmt{$fmt}) && $rul;
    $fmt = $fmt{$fmt};
    foreach my $pat (split(/\#/, $rul))
    { ($min, $max) = ($pat =~ s/^<<(\$\d+)?:(\$\d+)?>>//)
        ? ($1, $2) : ($fmt->[0], $fmt->[1]);
      next unless $pat;
      push(@tbl, sprintf($fmt->[2], $pat, $min || '', $str, $max || '', $opt));
    }
  }
  die "RDA-00290: No filter rules\n" unless @tbl;
  $slf->{'rul'} = [@tbl];

  # Generate the filter routine
  $slf->{'sub'} = eval join("\n",
    'sub { my $str = shift;',
    'unless ($str =~ m#^<\/?(code|pre|verbatim)>$#',
    '|| $str =~ m#^%(DATA|TOC[\d\-]*)%$#){',
    @tbl,
    '}$str;}');
  die "RDA-00291: Filter code error:\n$@\n" if $@;
}

=head2 S<$h-E<gt>display>

This method displays the filter code.

=cut

sub display
{ print join("\n", 'Filter rules:', @{shift->{'rul'}}, '');
}

=head2 S<$h-E<gt>filter($str)>

This method filters sensitive information out of the specified string.

=cut

sub filter
{ my ($slf, $str) = @_;

  &{$slf->{'sub'}}($str);
}

# --- Functions to emulate a file handle --------------------------------------

sub _not_implemented
{ return undef;
}

*blocking = \&_not_implemented;
*clearerr = \&_not_implemented;
*eof = \&_not_implemented;
*error = \&_not_implemented;
*fileno = \&_not_implemented;
*getc = \&_not_implemented;
*getline = \&_not_implemented;
*getlines = \&_not_implemented;
*getpos = \&_not_implemented;
*input_line_number = \&_not_implemented;
*opened = \&_not_implemented;
*printflush = \&_not_implemented;
*read = \&_not_implemented;
*seek = \&_not_implemented;
*setpos = \&_not_implemented;
*stat = \&_not_implemented;
*sync = \&_not_implemented;
*sysread = \&_not_implemented;
*tell = \&_not_implemented;
*truncate = \&_not_implemented;
*ungetc = \&_not_implemented;
*untaint = \&_not_implemented;

sub autoflush
{ my $slf = shift;

  *$slf->{'rpt'}->autoflush(@_) if *$slf->{'rpt'};
}

sub close
{ my $slf = shift;

  *$slf->{'rpt'} ? *$slf->{'rpt'}->close : 1;
}

sub flush
{ my $slf = shift;

  *$slf->{'rpt'}->flush if *$slf->{'rpt'};
}

sub open
{ my $slf = shift;

  (*$slf->{'rpt'} = IO::File->new)->open(@_);
}

sub print
{ my $slf = shift;

  *$slf->{'rpt'}->print(map {&{*$slf->{'sub'}}($_)} @_) if *$slf->{'rpt'};
}

sub printf
{ my $slf = shift;
  my $fmt = shift;

  *$slf->{'rpt'}->print(&{*$slf->{'sub'}}(sprintf($fmt, @_))) if *$slf->{'rpt'};
}

sub sysseek
{ my $slf = shift;

  sysseek(*$slf->{'rpt'}, $_[0], $_[1]) if *$slf->{'rpt'};
}

sub syswrite
{ my $slf = shift;
  my $str = shift;
  my $lgt = shift;

  $str = substr($str, 0, $lgt) if defined($lgt);
  $str = &{*$slf->{'sub'}}($str);
  *$slf->{'rpt'}->syswrite($str, length($str)) if *$slf->{'rpt'};
}

sub write
{ my $slf = shift;
  my $str = shift;
  my $lgt = shift;

  $str = substr($str, 0, $lgt) if defined($lgt);
  $str = &{*$slf->{'sub'}}($str);
  *$slf->{'rpt'}->write($str, length($str)) if *$slf->{'rpt'};
}

sub BINMODE
{ my $slf = shift;

  binmode *$slf->{'rpt'}, @_;
}

*CLOSE = \&close;
*EOF = \&_not_implemented;
*FILENO = \&_not_implemented;
*GETC = \&_not_implemented;
*OPEN = \&open;
*PRINT = \&print;
*PRINTF = \&printf;
*READ = \&_not_implemented;
*READLINE = \&_not_implemented;
*SEEK = \&_not_implemented;
*TELL = \&_not_implemented;
*WRITE = \&write;

sub DESTROY
{
}

sub TIEHANDLE
{ shift;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Output|RDA::Object::Output>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
