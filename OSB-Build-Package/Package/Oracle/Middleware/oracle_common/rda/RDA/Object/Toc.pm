# Toc.pm: Class Used for Managing Table of Contents Files

package RDA::Object::Toc;

# $Id: Toc.pm,v 2.10 2012/04/25 06:55:42 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Object/Toc.pm,v 2.10 2012/04/25 06:55:42 mschenke Exp $
#
# Change History
# 20120122  MSC  Extend the SDCL interface.

=head1 NAME

RDA::Object::Toc - Class Used for Managing Table of Contents Files

=head1 SYNOPSIS

require RDA::Object::Toc;

=head1 DESCRIPTION

The objects of the C<RDA::Object::Toc> class are used to manage table of
contents files. It is a subclass of L<RDA::Object|RDA::Object>.

The table of content operations are disabled in RDA jobs.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Block qw($SPC_VAL);
  use RDA::Object;
  use RDA::Object::Rda qw($APPEND $CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA %SDCL);
$VERSION = sprintf("%d.%02d", q$Revision: 2.10 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(RDA::Object Exporter);
%SDCL    = (
  als => {
    'getToc'       => ['$[TOC]', 'get_toc'],
    'hasTocOutput' => ['$[TOC]', 'has_output'],
    'isTocCreated' => ['$[TOC]', 'is_created'],
    'switchToc'    => ['$[TOC]', 'switch'],
    },
  beg => \&_begin_toc,
  cmd => {
    'pretoc'   => [\&_exe_pretoc,   \&_get_list,  0, 0],
    'toc'      => [\&_exe_toc,      \&_get_list,  0, 0],
    'unpretoc' => [\&_exe_unpretoc, \&_get_value, 0, 0],
    },
  dep => [qw(RDA::Object::Output)],
  glb => ['$[TOC]'],
  inc => [qw(RDA::Object)],
  met => {
    'close'      => {ret => 0},
    'get_info'   => {ret => 0},
    'get_path'   => {ret => 0},
    'get_toc'    => {ret => 0},
    'has_output' => {ret => 0},
    'is_created' => {ret => 0},
    'pop_line'   => {ret => 0},
    'push_line'  => {ret => 0, evl => 'L'},
    'set_info'   => {ret => 0},
    'switch'     => {ret => 0},
    'write'      => {ret => 0, evl => 'L'},
    },
  );

# Define the global private constants

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Object::Toc-E<gt>new($out[,$oid])>

The object constructor. This method takes the report control object reference
and the object identifier as arguments. It prefixes any specified object
identifier with the current report abbreviation. When not specified, it derives
the object identifier from the report control object.

It is represented by a blessed hash reference. The following special keys are
used:

=over 12

=item S<    B<'alt' > > List of alternative table of content files

=item S<    B<'bkp' > > Attribute backup hash

=item S<    B<'buf' > > Capture buffer

=item S<    B<'ctl' > > Cache of alternative control objects

=item S<    B<'fil' > > Table of content file name

=item S<    B<'flg' > > Table of content file flag

=item S<    B<'flt' > > Filter control object reference

=item S<    B<'gid' > > Expected group identifier

=item S<    B<'ofh' > > Table of content file handle

=item S<    B<'oid' > > Object identifier

=item S<    B<'out' > > Reference of the report control object

=item S<    B<'pth' > > Table of content file path

=item S<    B<'stk' > > Line stack

=item S<    B<'sub' > > Reference to the first alternative control object

=item S<    B<'uid' > > Expected user identifier

=back

=cut

sub new
{ my ($cls, $out, $oid) = @_;
  my ($fil, $flt, $slf);

  # Validate the object identifier
  if (!defined($oid))
  { $oid = $out->get_oid;
  }
  elsif ($oid =~ m/^\w+$/)
  { $oid = $out->get_info('abr').'_'.$oid;
  }
  else
  { die "RDA-01071: Invalid table of content name '$oid'\n";
  }

  # Create the table of contents object
  if (ref($cls))
  { $slf = bless {
      oid => $oid,
      out => $out,
      }, ref($cls);

    # Store the user and group identifiers of the report directory
    ($slf->{'uid'}, $slf->{'gid'}) = ($cls->{'uid'}, $cls->{'gid'})
      if exists($cls->{'uid'});
  }
  else
  { $slf = bless {
      oid => $oid,
      out => $out,
      }, $cls;
  }

  # Determine if filtering is required
  $slf->{'flt'} = $flt if ($flt = $out->get_info('flt'));

  # Take care about file name capitalisation
  $fil = $out->get_info('grp').'_'.$oid.'.toc';
  $fil = lc($fil) unless $out->get_info('cas');
  $slf->{'fil'} = $fil;
  $slf->{'pth'} = RDA::Object::Rda->cat_file($out->get_path('C'), $fil);

  # Propagate ownership alignment
  $slf->align_owner if $out->get_info('own');

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>align_owner>

This method indicates that the user and group identifiers of the table of
content must be aligned to those of the report directory on the table of
content closure. It returns the number of files already converted.

=cut

sub align_owner
{ my ($slf) = @_;
  my ($uid, $gid, @fil);

  ($uid, $gid) = $slf->{'out'}->get_owner;
  if (defined($uid))
  { # Store the user and group identifiers of the report directory
    $slf->{'uid'} = $uid;
    $slf->{'gid'} = $gid;

    # Adjust existing file
    return chown($uid, $gid, $slf->{'pth'}) unless exists($slf->{'ofh'});
  }
  0;
}

=head2 S<$h-E<gt>close([$flag])>

This method closes the table of contents file if the file has been opened. It
clears the line stack unless the flag is set or executed in an SDCL job.

=cut

sub close
{ my ($slf, $flg) = @_;

  # Restore the default behavior
  $slf->switch if exists($slf->{'alt'});

  # Clear the line stack
  delete($slf->{'stk'}) unless $flg || $slf->{'out'}->in_job;

  # Close the file
  delete($slf->{'ofh'})->close if exists($slf->{'ofh'});

  # Adjust the ownership
  chown($slf->{'uid'}, $slf->{'gid'}, $slf->{'pth'})
    if exists($slf->{'flg'}) && exists($slf->{'uid'});
}

=head2 S<$h-E<gt>delete>

This method deletes a table of contents object. The file is closed when needed.

=cut

sub delete
{ $_[0]->close;
  $_[0]->SUPER::delete;
}

=head2 S<$h-E<gt>get_handle>

This method returns the file handle of the table of contents file. It creates
the file on the first call.

=cut

sub get_handle
{ my ($slf) = @_;
  my ($buf, $flg, $ofh, $pth);

  # Disable table of content operations in jobs
  return undef if $slf->{'out'}->in_job;

  # Get the table of contents handler
  if (exists($slf->{'ofh'}))
  { $ofh = $slf->{'ofh'};
  }
  else
  { $flg = exists($slf->{'flg'});
    $ofh = exists($slf->{'flt'}) ? $slf->{'flt'}->new : IO::File->new;
    $slf->{'out'}->get_path('C', 1) unless $flg;
    $ofh->open($slf->{'pth'}, $flg ? $APPEND : $CREATE, $FIL_PERMS)
      or die "RDA-01070: Cannot create the table of content file '"
             .$slf->{'fil'}."'\n $!\n";
    $slf->{'flg'} = 1;
    $slf->{'ofh'} = $ofh;
  }

  # Print the stored strings
  if (exists($slf->{'stk'}))
  { $buf = join('', @{delete($slf->{'stk'})});
    $ofh->syswrite($buf, length($buf));
  }

  # Return the file handle
  $ofh;
}

=head2 S<$h-E<gt>get_path>

This method returns the path of the table of contents file.

=cut

sub get_path
{ shift->{'pth'};
}

=head2 S<$h-E<gt>get_toc([$flag])>

This method returns the name of the table of content file. When the flag is
set, it returns its path.

=cut

sub get_toc
{ my ($slf, $flg) = @_;

  $slf->{$flg ? 'pth' : 'fil'};
}

=head2 S<$h-E<gt>has_output([$flag])>

This method indicates if lines have been written in the table of contents file
since the last line push. When the flag is set, it clears the line stack also.

It becomes false after file closure.

=cut

sub has_output
{ my ($slf, $flg) = @_;

  return 0 if $slf->{'out'}->in_job;
  if (exists($slf->{'stk'}))
  { delete($slf->{'stk'}) if $flg;
    return 0;
  }
  exists($slf->{'sub'})
    ? exists($slf->{'sub'}->{'ofh'})
    : exists($slf->{'ofh'});
}

=head2 S<$h-E<gt>is_created([$flag])>

This method indicates whether the table of contents file has been created. When
the flag is set, it clears the line stack also.

=cut

sub is_created
{ my ($slf, $flg) = @_;

  return 0 if $slf->{'out'}->in_job;
  delete($slf->{'stk'}) if $flg;
  exists($slf->{'sub'})
    ? exists($slf->{'sub'}->{'flg'})
    : exists($slf->{'flg'});
}

=head2 S<$h-E<gt>switch([$toc...])>

This method modifies how RDA performs the table of content operations. When
you specify table of content names as arguments, all directives are stored in
the corresponding files. Without arguments, it restores the default behavior.

=cut

sub switch
{ my ($slf, @toc) = @_;
  my ($tbl, $val);

  # Use alternate table of content files
  if (@toc)
  { # Close previous operations
    if (exists($slf->{'bkp'}))
    { # Close alternate table of content files
      foreach my $ctl (@{$slf->{'alt'}})
      { $ctl->close;
      }
      delete($slf->{'stk'});
      delete($slf->{'sub'});
    }
    else
    { # Backup some attributes
      $slf->{'bkp'} = $tbl = {};
      foreach my $key (qw(alt stk sub))
      { $tbl->{$key} = delete($slf->{$key});
      }
    }

    # Switch to alternate table of content files
    $slf->{'alt'} = $tbl = [];
    foreach my $oid (@toc)
    { $slf->{'ctl'}->{$oid} = $slf->new($slf->{'out'}, $oid)
        unless exists($slf->{'ctl'}->{$oid});
      push(@$tbl, $slf->{'ctl'}->{$oid});
    }
    $slf->{'sub'} = $tbl->[0];
    return 1;
  }

  # Restore default behavior
  if ($tbl = delete($slf->{'bkp'}))
  { foreach my $key (keys(%$tbl))
    { if (defined($val = $tbl->{$key}))
      { $slf->{$key} = $val;
      }
      else
      { delete($slf->{$key});
      }
    }
  }
  0;
}

=head1 CAPTURE METHODS

=head2 S<$h-E<gt>begin_capture>

This method initiates the capture of the table of content lines.

=cut

sub begin_capture
{ shift->{'buf'} = [];
}

=head2 S<$h-E<gt>end_capture>

This method ends the capture of the table of content lines.

=cut

sub end_capture
{ delete(shift->{'buf'});
}

=head2 S<$h-E<gt>get_capture>

This method returns captured lines.

=cut

sub get_capture
{ shift->{'buf'};
}

=head1 LINE STACK MANAGEMENT METHODS

=head2 S<$h-E<gt>pop_line([$count])>

This method pops strings from the line stack. By default, it removes one line
from the stack. It returns the last string removed from the stack.

=cut

sub pop_line
{ my ($slf, $cnt) = @_;
  my $lin;

  if (exists($slf->{'stk'}) && !$slf->{'out'}->in_job)
  { $cnt = 1 unless defined($cnt);
    $lin = pop(@{$slf->{'stk'}}) while $cnt-- > 0;
    delete($slf->{'stk'}) unless scalar @{$slf->{'stk'}};
  }
  $lin;
}

=head2 S<$h-E<gt>push_line($line)>

This method pushes a line into the line stack. The line is assembled from the
argument list, with the undefined values and the references discarded. It
returns the stack size.

=cut

sub push_line
{ my ($slf, $lin) = @_;

  return 0 if $slf->{'out'}->in_job;
  $slf->{'stk'} = [] unless exists($slf->{'stk'});
  push(@{$slf->{'stk'}}, $lin);
  scalar @{$slf->{'stk'}};
}

=head1 WRITE METHODS

=head2 S<$h-E<gt>write($line)>

This method writes a line in the table of content file.

=cut

sub write
{ my ($slf, $lin) = @_;

  if (exists($slf->{'buf'}))
  { push(@{$slf->{'buf'}}, @{delete($slf->{'stk'})})
      if exists($slf->{'stk'});
    push(@{$slf->{'buf'}}, $lin);
  }
  elsif (exists($slf->{'alt'}))
  { my ($lgt, $ofh, $stk);

    $lgt = length($lin);
    $stk = delete($slf->{'stk'});
    foreach my $ctl (@{$slf->{'alt'}})
    { $ctl->{'stk'} = $stk if $stk;
      $ofh->syswrite($lin, $lgt) if ($ofh = $ctl->get_handle);
    }
  }
  else
  { my ($ofh);

    return 0 unless ($ofh = $slf->get_handle);
    $ofh->syswrite($lin, length($lin));
  }
  1;
}

# --- SDCL extensions ---------------------------------------------------------

# Create the table of contents object
sub _begin_toc
{ my ($pkg) = @_;
  my ($out, $toc);

  $out = $pkg->get_info('rpt');
  $toc = RDA::Object::Toc->new($out);
  $out->set_info('toc', $toc);
  $pkg->define('$[TOC]', $toc);
}

# Define the parse methods
sub _get_list
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->parse_list($str);
}

sub _get_value
{ my ($slf, $spc, $str) = @_;

  $spc->[$SPC_VAL] = $slf->parse_value($str);
}

# Push a line into the line stack
sub _exe_pretoc
{ my ($slf, $spc) = @_;
  my ($obj);

  $obj->push_line($spc->[$SPC_VAL]->eval_as_line)
    if ($obj = $slf->get_output->get_info('toc'));
  0;
}

# Write a line in the table of content file
sub _exe_toc
{ my ($slf, $spc) = @_;
  my ($obj);

  $obj->write($spc->[$SPC_VAL]->eval_as_line)
    if ($obj = $slf->get_output->get_info('toc'));
  0;
}

# Pop lines from the line stack
sub _exe_unpretoc
{ my ($slf, $spc) = @_;
  my ($obj);

  $obj->pop_line(defined($spc->[$SPC_VAL])
    ? $spc->[$SPC_VAL]->eval_as_number
    : 1)
    if ($obj = $slf->get_output->get_info('toc'));
  0;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Handle::Filter|RDA::Handle::Filter>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
