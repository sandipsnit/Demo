# Options.pm: Process Single-Character Switches with Switch Clustering

package RDA::Options;

# $Id: Options.pm,v 2.4 2012/01/02 16:21:31 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Options.pm,v 2.4 2012/01/02 16:21:31 mschenke Exp $
#
# Change History
# 20120102  MSC  Change the copyright notice.

=head1 NAME

RDA::Options - Process Single-Character Switches with Switch Clustering

=head1 SYNOPSIS

require RDA::Options;

=head1 DESCRIPTION

=cut

use strict;

BEGIN
{ use Exporter;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<RDA::Options::getopts($list,\@arg[,$flg])>

The function processes single-character switches with switch clustering.

The first argument indicates the list of all switches to be recognized. Switches
which take an argument are followed by a C<:> character in the list. They don't
care whether there is a space between the switch and the argument.

If unspecified switches are found on the command-line, an error will be
generated unless the flag is set. In that case, they are discarded.

It returns an hash reference, where hash keys will be the switch names, and
thier value the value of the argument or 1 if no argument is specified.

To allow programs to process arguments that look like switches, the function
will stop processing switches when they see the argument C<-->. The C<--> will
be removed from the argument list array.

=cut

sub getopts
{ my ($lst, $arg, $flg) = @_;
  my ($itm, $hsh, $opt, $val, %opt);

  # Parse the option list
  $val = 0;
  $lst = '' unless defined($lst);
  foreach $opt (reverse split(/ */, $lst))
  { if ($opt eq ':')
    { $val = 1;
    }
    else
    { $opt{$opt} = $val if $opt =~ m/\w/;
      $val = 0;
    }
  }

  # Extract the options from the argument list
  $hsh = {};
  while (defined($itm = shift(@$arg)))
  { # Detect the end of the options
    last if $itm eq '--';
    unless ($itm =~ s/^-//)
    { unshift(@$arg, $itm);
      last;
    }

    # Treat option letters
    while (length($opt = substr($itm, 0, 1)))
    { $itm = substr($itm, 1);
      unless (exists($opt{$opt}))
      { die "RDA-00025: Bad option '$opt'\n" unless $flg;
        next;
      }
      if ($opt{$opt})
      { $hsh->{$opt} = $itm if length($itm) || defined($itm = shift(@$arg));
        last;
      }
      $hsh->{$opt} = 1;
    }
  }

  # Return the parsing result
  $hsh;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent.pm|RDA::Agent.pm>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
