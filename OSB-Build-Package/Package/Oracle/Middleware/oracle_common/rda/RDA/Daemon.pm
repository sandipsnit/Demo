# Daemon.pm: Class Used for Objects to Control Background Collections

package RDA::Daemon;

# $Id: Daemon.pm,v 2.5 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Daemon.pm,v 2.5 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Daemon - Class Used for Objects to Control Background Collections

=head1 SYNOPSIS

require RDA::Daemon;

=head1 DESCRIPTION

The objects of the C<RDA::Daemon> class are used to control background
collections.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Copy;
  use IO::File;
  use POSIX;
  use RDA::Object::Rda qw($APPEND $CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $FORK   = "Parent exit\n";
my $RE_MOD = qr/^S(\d{3})([A-Za-z]\w*)$/i;

# Define the global private variables

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Daemon-E<gt>new($agt)>

The object constructor. It takes the agent reference as an argument.

C<RDA::Daemon> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_bas'> > Maximum length of the report basename

=item S<    B<'_ctl'> > Configuration and control directory

=item S<    B<'_grp'> > Report group

=item S<    B<'_lck'> > Reference to the lock control object

=item S<    B<'_mod'> > Module hash

=item S<    B<'_oid'> > Setup name

=item S<    B<'_pid'> > Process identifier list

=item S<    B<'_rpt'> > Reference the report control object

=item S<    B<'_top'> > RDA top directory

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($cfg);

  # Create the daemon object and return its reference
  $cfg = $agt->get_config;
  bless {
    _agt => $agt,
    _bas => $cfg->get_info('RDA_BASENAME', 38),
    _ctl => exists($ENV{'RDA_PID'})
      ? $ENV{'RDA_PID'}
      : $cfg->get_group('D_CWD'),
    _mod => {},
    _oid => $agt->get_oid,
    _pid => $agt->get_info('pid', []),
    _top => $cfg->get_group('D_RDA'),
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>halt_bgnd>

This method requests the data collection running in the background to stop.

=cut

sub halt_bgnd
{ my ($slf) = @_;
  my ($ctl, $end);

  $slf->{'_agt'}->log('h');
  if (-f ($ctl = RDA::Object::Rda->cat_file($slf->{'_ctl'},
    $slf->{'_oid'}.'.pid')))
  { $end = $ctl;
    $end =~ s/pid$/end/i;
    rename($ctl, $end) ||
      die "RDA-00603: Cannot halt the background collection: $!\n";
  }
}

=head2 S<$h-E<gt>kill_bgnd>

This method kills any data collection that is running in the background.

=cut

sub kill_bgnd
{ my ($slf) = @_;

  $slf->{'_agt'}->log('k');
  _kill_bgnd($slf, '.pid') || _kill_bgnd($slf, '.end');
}

sub _kill_bgnd
{ my ($slf, $ext) = @_;
  my ($cnt, $pth);

  $cnt = 0;
  $pth = RDA::Object::Rda->cat_file($slf->{'_ctl'}, $slf->{'_oid'}.$ext);
  if (open(PID, "<$pth"))
  { my $pid = <PID>;
    close(PID);
    $pid =~ s/[\n\r]+$//;
    kill(15, $pid) if $pid;
    ++$cnt while unlink($pth);
  }
  $cnt;
}

1;

=head2 S<$h-E<gt>run_bgnd($out,[$module,...])>

This method attempts to transform the current process into a daemon and starts
the data collection loop. It redirects the standard output to the specified
output file. You can provide an alternative module list as arguments.

=cut

sub run_bgnd
{ my ($slf, $out, @mod) = @_;
  my ($agt, $cnt, $ctl, $cur, $dlt, $grp, $lck, $min, $ofh, $rat, $rpt, $tim,
      $val, @tb1, @tb2, %tbl);

  # Prepare the data collection
  $agt = $slf->{'_agt'};
  foreach my $nam (@mod)
  { $nam =~ s/\.(cfg|def)$//i;
    next unless $nam =~ $RE_MOD;

    # If not yet done, do the setup
    $agt->setup($nam)
      unless $agt->is_disabled($nam) || $agt->is_configured($nam);

    # If not disabled, add to the execution list
    $tbl{$nam} = 1 unless $agt->is_disabled($nam);
  }
  @tb1 = sort keys(%tbl);
  return -1 unless @tb1;

  # Take care that the sampling setup has been done
  foreach my $nam (split(/,/, $agt->get_setting('RDA_SAMPLE', '')))
  { $agt->setup($nam) unless $agt->is_configured($nam);
  }

  # Save the setup file
  $agt->save;

  # Prepare the pattern list
  $slf->{'_rpt'} = $rpt = $agt->get_output(1);
  $slf->{'_grp'} = $grp = $rpt->get_group;
  $slf->{'_mod'} = {};
  foreach my $nam (@tb1)
  { next unless $nam =~ $RE_MOD;
    $val = "$grp\_$2\_";
    $slf->{'_mod'}->{$nam} = {
      cat => qr/^$grp\_($2\_S|$nam\_[ADI])\.fil$/i,
      fil => "$grp\_$nam\_A.fil",
      flg => $agt->get_setting("SMPL_$2\_APPEND",1),
      pre => $val,
      rpt => qr/^$val.*(\.(box|csv|dat|gif|htm|jar|png|tmp|txt|xml|zip))$/i,
      seq => 0,
      toc => qr/^$grp\_$nam(_\d+)?\.toc$/i,
      };
  }
  
  # Prepare the initial data collection
  foreach my $nam (split(/,/, $agt->get_setting('RDA_COLLECT', '')))
  { $tbl{$nam} = 1;
  }
  @tb2 = sort keys(%tbl);

  # Prepare the sampling environment
  $rpt->get_path('A', 1);
  $rpt->get_path('R', 1);
  $rpt->get_path('S', 1);

  $dlt = $agt->get_setting('SMPL_DELTA',300);
  $min = $agt->get_setting('SMPL_SLEEP',60);
  $rat = 3600 * $agt->get_setting('SMPL_RATE', 0);

  # Try to transform the process in daemon
  $ctl = RDA::Object::Rda->cat_file($slf->{'_ctl'}, $slf->{'_oid'}.'.pid');
  $ofh = IO::File->new;
  $ofh->open($ctl, $CREATE, $FIL_PERMS)
    or die "RDA-00600: Cannot create the daemon file: $!\n";
  open(STDIN, '/dev/null') or die "RDA-00601: Cannot redirect input: $!\n";
  eval "fork() && die '$FORK'";
  if ($@ && $@ eq $FORK)
  { $ofh->close;
    return 0;
  }
  open(STDOUT, ">$out") or die "RDA-00602: Cannot redirect output: $!\n";
  eval "setsid();";
  print {$ofh} "$$\n";
  $ofh->close;
  $ctl =~s/pid$/end/i;
  $agt->log('f');

  # Perform an initial data collection and archiving
  $cur = RDA::Object::Rda->get_timestamp($tim = time);
  $cur =~ s/_//;
  $lck = '-B-'.$agt->get_oid;
  $agt->set_temp_setting('SMPL_CURRENT', $cur);
  $agt->set_temp_setting('SMPL_COUNT', $cnt = 0);
  _lock($slf, $lck);
  $slf->_do_archive($rpt->get_path('A'), $rpt->get_path('S'), $tim, $cur);
  foreach my $nam (@tb2)
  { exit(2) if $agt->collect($nam);
  }
  $slf->_wait;
  _do_unlink($slf, $rpt->get_path('R'));
  _do_move($slf, $rpt->get_path('R'), $rpt->get_path('C'));
  _unlock($slf, $lck);
  $tim = _get_next($tim + $dlt, $min);

  # Perform sample loop
  while ($slf->_chk_end($ctl))
  { # Sleep until next sample
    $val = $tim - time;
    if ($val > 20)
    { sleep(15);
      next;
    }
    elsif ($val > 0)
    { sleep($val);
    }

    # Check if a halt request has been posted
    last unless $slf->_chk_end($ctl);
 
    # Collect a new sample
    $cur = RDA::Object::Rda->get_timestamp($tim = time);
    $cur =~ s/_//;
    $agt->set_temp_setting('SMPL_CURRENT', $cur);
    $agt->set_temp_setting('SMPL_COUNT', ++$cnt);
    foreach my $nam (@tb1)
    { exit(3) if $agt->collect($nam);
    }
    $slf->_wait($lck);
    _do_concat($slf, $rpt->get_path('S'), $rpt->get_path('C'), $cur);
    _unlock($slf, $lck);

    # Check if a halt request has been posted
    last unless $slf->_chk_end($ctl);
 
    # Perform sample archiving when required
    unless ($tim < ($agt->get_setting('SMPL_LAST', 0) + $rat))
    { _lock($slf, $lck) if $lck;
      $slf->_do_archive($rpt->get_path('A'), $rpt->get_path('S'), $tim, $cur);
      _unlock($slf, $lck) if $lck;
    }
    $tim = _get_next($tim + $dlt, $min);
  }
  1;
}

# --- Internal methods --------------------------------------------------------

# Check if a halt request has been posted
sub _chk_end
{ my ($slf, $pth) = @_;

  # Continue unless an halt request is detected
  return 1 unless -f $pth;

  # Remove the control file
  0 while unlink($pth);

  # Indicate that the collection should stop
  0;
}

# Perform sample archiving
sub _do_archive
{ my ($slf, $arc, $smp, $tim, $cur) = @_;
  my ($agt, $cmd, $err, $flg, $fil, $grp, $max, $pat, $pth, $vol, %tbl);

  # Archive the sample files
  $agt = $slf->{'_agt'};
  $grp = $slf->{'_grp'};
  $pat = qr/^$grp\_.*(\.(box|csv|dat|fil|gif|jar|png|toc|txt|zip))$/i;
  if (_chk_package($smp, $pat))
  { chdir($smp) ||
      die "RDA-00607: Cannot change to the sample directory\n";
    eval {
      if (($cmd = $agt->get_setting('CMD_ZIP')) &&
        !exists($ENV{'RDA_NO_ZIP'}))
      { $fil = "RDA.$grp\_smp\_$cur.zip";
        _exe_package("$cmd -9 -q -D -j $fil -\@", $pat,
           "RDA-00610: Cannot zip the reports\n");
      }
      elsif (($cmd = $agt->get_setting('CMD_PAX')) &&
        !exists($ENV{'RDA_NO_PAX'}))
      { $fil = "RDA.$grp\_smp\_$cur.tar";
        _exe_package("$cmd -w -f $fil", $pat,
          "RDA-00611: Cannot package the reports using pax\n");
        $fil = _exe_compress($agt, $fil);
      }
      elsif (($cmd = $agt->get_setting('CMD_TAR')) &&
        !exists($ENV{'RDA_NO_TAR'}))
      { $fil = "RDA.$grp\_smp\_$cur.tar";
        system("$cmd -cf $fil $grp\_*");
        die "RDA-00612: Cannot package the reports using tar\n" if $?;
        $fil = _exe_compress($agt, $fil);
      }
      elsif (($cmd = $agt->get_setting('CMD_JAR')) &&
        !exists($ENV{'RDA_NO_JAR'}))
      { $fil = "RDA.$grp\_smp\_$cur.zip";
        system("$cmd -cfM $fil $grp\_*");
        die "RDA-00614: Cannot package the reports using jar\n" if $?;
      }
      else
      { die "RDA-00613: Archive command not -yet- identified\n";
      }
    };
    $agt->log('E', $@) if ($err = $@);
    chdir($slf->{'_top'}) ||
      die "RDA-00609: Cannot change to the RDA install directory\n";
  }

  # If there are no errors, clean up the sample directory
  if (!$err && opendir(DIR, $smp))
  { foreach $fil (readdir(DIR))
    { if ($fil =~ m/^RDA.$grp\_smp_/i)
      { move(RDA::Object::Rda->cat_file($smp, $fil),
             RDA::Object::Rda->cat_file($arc, substr($fil,4)));
      }
      elsif ($fil =~ $pat)
      { $fil = RDA::Object::Rda->cat_file($smp, $fil);
        1 while unlink($fil);
      }
    }
    closedir(DIR);
    foreach my $rec (values(%{$slf->{'_mod'}}))
    { $rec->{'seq'} = 0;
      delete($rec->{'nam'});
      delete($rec->{'oid'});
    }
  }

  # Cleanup the archive directory
  if (opendir(DIR, $arc))
  { # Get the archive files
    foreach $fil (grep {m/^$grp\_smp_/i} readdir(DIR))
    { $pth = RDA::Object::Rda->cat_file($arc, $fil);
      $tbl{$fil} = [$pth, (stat($pth))[7]];
    }
    closedir(DIR);

    # Keep more recent archives
    $max = $agt->get_setting('SMPL_KEEP',0);
    $vol = 1048576 * $agt->get_setting('SMPL_SIZE',0);
    $flg = 0;
    foreach $fil (sort {$b cmp $a} keys(%tbl))
    { if ($vol > 0)
      { $vol -= $tbl{$fil}->[1];
        $flg = 1 unless $vol > 0;
      }
      if ($flg)
      { 1 while unlink($tbl{$fil}->[0]);
      }
      if ($max > 0)
      { # Must we still keep the next one ?
        $flg = 1 unless --$max > 0;
      }
    }
  }

  # Save the setup file
  $agt->set_setting('SMPL_LAST', $tim);
  $agt->save;
}

sub _chk_package
{ my ($dir, $pat) = @_;
  my ($fil, $flg);

  if (opendir(DIR, $dir))
  { while (defined($fil = readdir(DIR)))
    { if ($fil =~ $pat)
      { $flg = 1;
        last;
      }
    }
    closedir(DIR);
  }
  $flg;
}

sub _exe_compress
{ my ($agt, $fil) = @_;
  my $cmd;

  if (($cmd = $agt->get_setting('CMD_GZIP')) &&
    !exists($ENV{'RDA_NO_GZIP'}))
  { system("$cmd -9 -q $fil");
    $fil .= '.gz';
  }
  elsif (($cmd = $agt->get_setting('CMD_COMPRESS')) &&
    !exists($ENV{'RDA_NO_COMPRESS'}))
  { system("$cmd $fil");
    $fil .= '.Z';
  }
  $fil;
}

sub _exe_package
{ my ($cmd, $pat, $err) = @_;

  opendir(DIR, '.') or die "RDA-00608: Cannot list the samples\n";
  open(CMD, "| $cmd") or die $err;
  foreach my $nam (readdir(DIR))
  { print CMD $nam, "\n" if $nam =~ $pat;
  }
  closedir(DIR);
  close(CMD) or die $err;
}

# Concatenate sample files
sub _do_concat
{ my ($slf, $dst, $src, $cur) = @_;
  my ($buf, $ctl, $dir, $ext, $fil, $grp, $ifh, $lgt, $nam, $ofh, $pth, $tgt);

  $grp = $slf->{'_grp'};
  $ifh = IO::File->new;
  $ofh = IO::File->new;
  foreach my $mod (keys(%{$slf->{'_mod'}}))
  { $ctl = $slf->{'_mod'}->{$mod};

    # Load the report catalog
    $pth = RDA::Object::Rda->cat_file($src, "$grp\_$mod\_A.fil");
    next unless $ifh->open("<$pth");
    while (<$ifh>)
    { (undef, $dir, $fil, $nam) = split(/\|/, $_, 5);
      next unless $dir eq 'C' && length($nam);
      if ($fil =~ $ctl->{'rpt'})      # TXT or DAT
      { $ext = lc($1);
        $pth = RDA::Object::Rda->cat_file($src, $fil);
        if ($ext !~ m/^\.(txt)$/)                # DAT
        { $tgt = RDA::Object::Rda->cat_file($dst, $fil);
          if (-f $tgt)
          { 1 while unlink($tgt);
          }
          else
          { $ctl->{'oid'}->{_get_oid($ctl)} = "S|$fil|$nam";
          }
          move($pth, $tgt);
        }
        elsif (!$ctl->{'flg'})                 # Not concatenated TXT
        { move($pth, _get_dest($slf, $ctl, $dst, "$nam\_$cur", $ext));
        }
        elsif (-s $pth && open(SRC, "<$pth"))  # Concatenated TXT
        { $ofh = IO::File->new; 
          binmode(SRC);

          $tgt = exists($ctl->{'nam'}->{$nam})
            ? $ctl->{'nam'}->{$nam}
            : _get_dest($slf, $ctl, $dst, $nam, $ext);
          if ($ofh->open($tgt, $APPEND, $FIL_PERMS))
          { $ofh->binmode;
            $buf = "---+ $cur\n";
            syswrite($ofh, $buf, length($buf));
            while ($lgt = sysread(SRC, $buf, 4096))
            { syswrite($ofh, $buf, $lgt);
            }
            $ofh->close;
          }
          close(SRC);
        }
        1 while unlink($pth);
      }
      elsif ($fil =~ $ctl->{'toc'})   # TOC
      { $tgt = $fil;
        $tgt =~ s/\.toc$/_$cur.toc/i;
        move(RDA::Object::Rda->cat_file($src, $fil),
             RDA::Object::Rda->cat_file($dst, $tgt));
      }
    }
    $ifh->close;

    # Generate the sample list
    if (exists($ctl->{'oid'}))
    { $fil = RDA::Object::Rda->cat_file($dst, "$grp\_$mod\_A.fil");
      $ofh->open($fil, $CREATE, $FIL_PERMS) ||
        die "RDA-00616: Cannot create the sample alias file '$fil':\n $!\n";
      foreach my $oid (sort keys(%{$ctl->{'oid'}}))
      { $buf = join('|', $oid, $ctl->{'oid'}->{$oid}, "\n");
        $ofh->syswrite($buf, length($buf));
      }
      $ofh->close;
    }
  }
}

sub _get_dest
{ my ($slf, $ctl, $dst, $nam, $ext) = @_;
  my ($fil, $lgt, $oid);

  # Truncate when needed
  $lgt = $slf->{'_bas'};
  $oid = _get_oid($ctl);
  $fil = $ctl->{'pre'}.$nam;
  if (length($fil) > $lgt)
  { $lgt -= length($oid) + 1;
    $fil = ($lgt > 1) ? $oid.'_'.substr($nam, 0, $lgt) : $oid;
  }
  $fil .= $ext;

  # Update the control structure
  $ctl->{'oid'}->{$oid} = "S|$fil|$nam";
  $ctl->{'nam'}->{$nam} = RDA::Object::Rda->cat_file($dst, $fil);
}

# Move sample files
sub _do_move
{ my ($slf, $dst, $src) = @_;

  if (opendir(DIR, $src))
  { foreach my $fil (readdir(DIR))
    { foreach my $rec (values(%{$slf->{'_mod'}}))
      { if ($fil =~ $rec->{'rpt'} ||
            $fil =~ $rec->{'cat'} ||
            $fil =~ $rec->{'toc'})
        { move(RDA::Object::Rda->cat_file($src, $fil),
               RDA::Object::Rda->cat_file($dst, $fil));
          last;
        }
      }
    }
    closedir(DIR);
  }
}

# Remove sample files
sub _do_unlink
{ my ($slf, $dst) = @_;
  my ($pth);

  if (opendir(DIR, $dst))
  { foreach my $fil (readdir(DIR))
    { foreach my $rec (values(%{$slf->{'_mod'}}))
      { if ($fil =~ $rec->{'rpt'} ||
            $fil =~ $rec->{'cat'} ||
            $fil =~ $rec->{'toc'})
        { $pth = RDA::Object::Rda->cat_file($dst, $fil);
          1 while unlink($pth);
          last;
        }
      }
    }
    closedir(DIR);
  }
}

# Get a sample identifier
sub _get_oid
{ my ($ctl) = @_;

  sprintf("%s%s%05d", $ctl->{'pre'}, $ctl->{'flg'} ? 'M' : 'S',
    ++$ctl->{'seq'});
}

# Get the lock control object
sub _get_lock
{ my ($slf) = @_;

  unless (exists($slf->{'_lck'}))
  { eval {
      require RDA::Object::Lock;
      $slf->{'_lck'} = RDA::Object::Lock->new($slf->{'_agt'},
        $slf->{'_out'}->get_path('L', 1));
    };
    $slf->{'_lck'} = undef if $@;
  }
  $slf->{'_lck'};
}

# Define when the next sample must be taken
sub _get_next
{ my ($nxt, $min) = @_;

  $min += time;
  ($nxt < $min) ? $min : $nxt;
}

# Take a lock
sub _lock
{ my ($slf, $lck) = @_;
  my ($ctl);

  $ctl->lock($lck) if ref($ctl = _get_lock($slf));
}

# Release a lock
sub _unlock
{ my ($slf, $lck) = @_;
  my ($ctl);

  $ctl->unlock($lck) if ref($ctl = _get_lock($slf));
}

# Wait for thread execution completion
sub _wait
{ my ($slf, $lck) = @_;
  my ($ctl, $pid);

  # When fork is emulated, wait for thread completion
  while (defined($pid = shift(@{$slf->{'_pid'}})))
  { waitpid($pid, 0);
  }

  # Wait until the thread lock can be get
  if (ref($ctl = _get_lock($slf)))
  { $ctl->wait;
    $ctl->lock($lck) if $lck;
  }
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Discover|RDA::Discover>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Lock|RDA::Object::Lock>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
