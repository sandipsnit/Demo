# Was.pm: Class Used for Web Application Server Macros

package RDA::Library::Was;

# $Id: Was.pm,v 1.14 2012/05/07 18:08:14 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Library/Was.pm,v 1.14 2012/05/07 18:08:14 mschenke Exp $
#
# Change History
# 20120507  MSC  Normalize the credentials.

=head1 NAME

RDA::Library::Was - Class Used for Web Application Server Macros

=head1 SYNOPSIS

require RDA::Library::Was;

=head1 DESCRIPTION

The objects of the C<RDA::Library::Was> class are used to interface with
Web application server-related macros.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use File::Basename;
  use IO::File;
  use RDA::Object::Buffer;
  use RDA::Object::Rda qw($CREATE $TMP_PERMS);
  use RDA::Object::Sgml;
  use RDA::Value;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private variables
my $EXT = "\nexit()\n";
my $JOB = 'was_job.py';
my $RES = 'was_res.txt';
my $TOP = "[[#Top][Back to top]]\n";

my %tb_fct = (
  'clearWasBuffer' => [\&_m_clear_buffer, 'N'],
  'clearWasGroup'  => [\&_m_clear_group,  'N'],
  'getWasBuffer'   => [\&_m_get_buffer,   'O'],
  'getWasGroup'    => [\&_m_get_group,    'L'],
  'getWasType'     => [\&_m_get_type,     'T'],
  'parseWspShow'   => [\&_m_parse_show,   'X'],
  'requestWas'     => [\&_m_request,      'N'],
  'setWasLogin'    => [\&_m_set_login,    'N'],
  'setWasTrace'    => [\&_m_set_trace,    'N'],
  'setWasType'     => [\&_m_set_type,     'N'],
  'writeWas'       => [\&_m_write,        'N'],
  'writeWasResult' => [\&_m_write_result, 'N'],
  );
my %tb_typ = (
  WLS => {'exe' => \&_wls_exec,
          'log' => \&_wls_login,
         },
  WSP => {'exe' => \&_wsp_exec,
          'log' => \&_wsp_login,
         },
  '?' => {'exe' => \&_not_set,
          'log' => \&_not_set,
         },
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Library::Was-E<gt>new($agt)>

The object constructor. It takes the agent object reference as an argument.

C<RDA::Library::Was> is represented by a blessed hash reference. The following
special keys are used:

=over 12

=item S<    B<'lim' > > Execution time limit (in sec)

=item S<    B<'trc' > > Output trace flag

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_buf'> > Buffer hash

=item S<    B<'_con'> > Connection string (WLS,WSP)

=item S<    B<'_err'> > Number of WAS request errors

=item S<    B<'_log'> > Login string (WSP)

=item S<    B<'_not'> > Statistics note

=item S<    B<'_out'> > Number of WAS requests timed out

=item S<    B<'_req'> > Number of WAS requests

=item S<    B<'_shl'> > Web application server tool command

=item S<    B<'_skp'> > Number of WAS requests skipped

=item S<    B<'_var'> > Variable group hash

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($slf);

  # Create the macro object
  $slf = bless {
    lim  => 0,
    trc  => $agt->get_setting('WAS_TRACE', 0),
    _agt => $agt,
    _buf => {},
    _err => 0,
    _fct => $tb_typ{'?'},
    _not => '',
    _out => 0,
    _req => 0,
    _shl => undef,
    _skp => 0,
    _typ => '?',
    _var => {},
    }, ref($cls) || $cls;

  # Register the macros
  $agt->register($slf, [keys(%tb_fct)], qw(stat));

  # Return the object reference
  $slf;
}

=head2 S<$h-E<gt>call($name,...)>

This method executes the macro code.

=cut

sub call
{ my ($slf, $nam, @arg) = @_;

  &{$tb_fct{$nam}->[0]}($slf, @arg);
}

=head2 S<$h-E<gt>clr_stats>

This method resets the statistics and clears corresponding module settings.

=cut

sub clr_stats
{ my ($slf) = @_;

  $slf->{'_buf'} = {};
  $slf->{'_con'} = undef;
  $slf->{'_fct'} = $tb_typ{$slf->{'_typ'} = '?'};
  $slf->{'_var'} = {};
  $slf->{'_not'} = '';
  $slf->{'_req'} = $slf->{'_err'} = $slf->{'_out'} = $slf->{'_skp'} = 0;
}

=head2 S<$h-E<gt>get_stats>

This method reports the library statistics in the specified module.

=cut

sub get_stats
{ my ($slf) = @_;
  my ($use);

  # Generate the statistics
  if ($slf->{'_req'})
  { # Get the statistics record
    $use = $slf->{'_agt'}->get_usage;
    $use->{'WAS'} = {err => 0, not => '', out => 0, req => 0, skp => 0}
      unless exists($use->{'WAS'});
    $use = $use->{'WAS'};

    # Indicate the current timeout when there is no other note
    $slf->{'_not'} = 'WAS execution limited to '.$slf->{'lim'}.'s'
      unless $use->{'not'} || $slf->{'_not'} || $slf->{'lim'} <= 0;

    # Generate the module statistics
    $use->{'err'} += $slf->{'_err'};
    $use->{'out'} += $slf->{'_out'};
    $use->{'req'} += $slf->{'_req'};
    $use->{'skp'} += $slf->{'_skp'};
    $use->{'not'} = $slf->{'_not'} if $slf->{'_not'};

    # Reset the statistics
    clr_stats($slf);
  }
}

=head2 S<$h-E<gt>run($name,$arg,$ctx)>

This method executes the macro with the specified argument list in a given
context.

=cut

sub run
{ my ($slf, $nam, $arg, $ctx) = @_;
  my ($fct, $ret, $typ);

  $fct = $tb_fct{$nam};
  $typ = $fct->[1];

  # Treat an array context
  return RDA::Value::List::new_from_data(&{$fct->[0]}($slf, $ctx,
    $arg->eval_as_array)) if $typ eq 'L';

  # Treat a SDCL value context
  return &{$fct->[0]}($slf, $ctx, $arg->eval_as_array) if $typ eq 'X';

  # Treat a scalar context
  defined($ret = &{$fct->[0]}($slf, $ctx, $arg->eval_as_array))
    ? RDA::Value::Scalar->new($typ, $ret)
    : $VAL_UNDEF;
}

=head1 WEB APPLICATION SERVER MACROS

=head2 S<clearWasBuffer([$nam,...])>

This macro deletes the specified capture buffers. The capture buffer names are
not case sensitive. It deletes all capture buffers when called without
arguments.

=cut

sub _m_clear_buffer
{ my ($slf, $ctx, @arg) = @_;

  if (@arg)
  { foreach my $nam (@arg)
    { delete($slf->{'_buf'}->{lc($nam)}) if defined($nam);
    }
  }
  else
  { $slf->{'_buf'} = {};
  }
  0;
}

=head2 S<clearWasGroup([$nam,...])>

This macro deletes the specified variable groups. The variable group names are
not case sensitive. It deletes all variable groups when called without
arguments.

=cut

sub _m_clear_group
{ my ($slf, $ctx, @arg) = @_;

  if (@arg)
  { foreach my $nam (@arg)
    { delete($slf->{'_var'}->{uc($nam)}) if defined($nam);
    }
  }
  else
  { $slf->{'_var'} = {};
  }
  0;
}

=head2 S<getWasBuffer([$nam[,$flg]])>

This macro returns the specified capture buffer or undefined value when the
name is undefined. The capture buffer names are not case sensitive. Unless the
flag is set, it assumes Wiki data.

=cut

sub _m_get_buffer
{ my ($slf, $ctx, $nam, $flg) = @_;

  defined($nam)
    ? RDA::Object::Buffer->new($flg ? 'L' : 'l', $slf->{'_buf'}->{lc($nam)})
    : undef;
}

=head2 S<getWasGroup($nam)>

This macro returns the specified variable group as a list. The variable group
names are not case sensitive.

=cut

sub _m_get_group
{ my ($slf, $ctx, $nam) = @_;

  return () unless defined($nam) && exists($slf->{'_var'}->{$nam = uc($nam)});
  (%{$slf->{'_var'}->{$nam}});
}

=head2 S<getWasType()>

This macro returns the Web application type: C<WLS> for Oracle WebLogic Server,
C<WSP> for IBM WebSphere, C<?> when the type of the Web application server is
not yet specified.

=cut

sub _m_get_type
{ shift->{'_typ'};
}

=head2 S<setWasLogin($usr,$pwd,$url)>

This macro defines a new connection for Oracle Weblogic Server.

=head2 S<setWasLogin([$usr,$pwd[,$hst,$prt]])>

This macro defines a new connection for IBM WebSphere. Without host or port,
it uses C<NONE> as F<wsadmin> connection type. It requires that a Web
application server tool command is already available.

=cut

sub _m_set_login
{ my ($slf) = @_;

  $slf->{'_shl'}
    ? &{$slf->{'_fct'}->{'log'}}(@_)
    : 1;
}

=head2 S<setWasTrace([$flag])>

This macro manages the trace flag. When the flag is set, it prints all job and
result lines to the screen. It remains unchanged if the flag value is undefined.

It returns the previous value of the flag.

=cut

sub _m_set_trace
{ my ($slf, $ctx, $flg) = @_;

  ($slf->{'trc'}, $flg) = ($flg, $slf->{'trc'});
  $flg;
}

=head2 S<setWasType($typ[,$shl])>

This macro indicates how to interact with the Web application server. It clears
any connection information.

=cut

sub _m_set_type
{ my ($slf, $ctx, $typ, $shl) = @_;

  # Clear the connection
  $slf->{'_con'} = undef;

  # Disable access when no valid type is provided
  unless ($typ && exists($tb_typ{$typ}))
  { $slf->{'_fct'} = $tb_typ{$slf->{'_typ'} = '?'};
    $slf->{'_shl'} = undef;
    return 1;
  }

  # Configure the access
  $slf->{'_fct'} = $tb_typ{$slf->{'_typ'} = $typ};
  $slf->{'_shl'} = $shl;
  0;
}

=head2 S<requestWas([$job[,$var[,out[,$err]]]])>

This macro executes the specified Jython job and saves its results and the
errors in the specified files. It returns 0 for a successful completion.

=cut

sub _m_request
{ my ($slf, $ctx, @arg) = @_;

  &{$slf->{'_fct'}->{'exe'}}($slf, @arg);
}

=head2 S<writeWas($job[,$var])>

This macro writes the output of the Jython job in report files. The request job
can contain the following directives:

=over 4

=item * C<---#RDA:BEGIN>

It starts capturing the output lines until an END directive treats them.

=item * C<---#RDA:BEGIN CAPTURE:E<lt>nameE<gt>>

It copies the following lines in the named capture buffer. It clears the
capture buffer unless its name is in lower case.

=item * C<---#RDA:BEGIN SECTION:E<lt>pretoc stringE<gt>>

It starts a new section.

=item * C<---#RDA:END CAPTURE>

It stops copying lines in a capture buffer. It does not stop the line capture
for other END directives.

=item * C<---#RDA:END FILE:E<lt>pathE<gt>>

It treats the captured lines as file content. It generates a report but let the
next END SECTION adding it in the table of content.

=item * C<---#RDA:END MACRO E<lt>nameE<gt>:E<lt>argument stringE<gt>>

It executes the specified macro with a buffer containing the captured lines and
the argument string as arguments.

=item * C<---#RDA:END REPORT:E<lt>report descriptionE<gt>>

It produces a report with the captured lines. The report description string
contains the table of content level, the link text, the report title, the
location, and the report name separated by C<|> characters. The last two
elements are optional.

=item * C<---#RDA:END SECTION>

It ends a section.

=item * C<---#RDA:END SECTION:E<lt>index levelE<gt>>

It produces the file index and ends a section.

=item * C<---#RDA:SET TITLE:E<lt>toc stringE<gt>>

It adds the specified string in the table of content.

=item * C<---#RDA:SET VARIABLE:E<lt>groupE<gt>:E<lt>varE<gt>="E<lt>valueE<gt>">

It adds a scalar variable to the named variable group.

=item * C<---#RDA:SET VARIABLE:E<lt>groupE<gt>:E<lt>varE<gt>=(E<lt>listE<gt>)>

It adds an array variable to the named variable group. The array is provided
as a comma-separated list of quoted values.

=back

When you specify a variable hash reference as an argument, they are added at
the beginning of the code. It supports scalar, array and hash references as
value. The variable names can be prefixed by a C<+> sign for suppressing the
value quoting.

It returns 0 for a successful completion.

=cut

sub _m_write
{ my ($slf, $ctx, $cod, $var) = @_;
  my ($res, $sta, $wrk);

  # Execute the request
  $wrk = $slf->{'_agt'}->get_output;
  $res = $wrk->get_work($RES, 1);
  _m_write_result($slf, $ctx, $res)
    unless ($sta = &{$slf->{'_fct'}->{'exe'}}($slf, $cod, $var, $res));
  $wrk->clean_work($RES);

  # Indicate the completion status
  $sta;
}

=head2 S<writeWasResult($fil)>

This macro treats a result file. It supports the same directives than the
C<writeWas> macro.

=cut

sub _m_write_result
{ my ($slf, $ctx, $res) = @_;
  my ($buf, $cut, $ifh, $out, $rpt, $toc, $trc, $val, @buf, @tbl, %idx);

  # Initialization
  $out = $ctx->get_output;
  $toc = $out->get_info('toc');
  $trc = $slf->{'trc'};

  # Treat the results
  $cut = 1;
  $ifh = IO::File->new;
  $slf->{'var'} = {};
  if ($ifh->open("<$res"))
  { while (<$ifh>)
    { s/[\n\r\s]+$//;
      print "WAS> $_\n" if $trc;
      if (m/^\-{3}#\s+RDA:(BEGIN|END|SET)/)
      { my ($cmd, $dat);

        (undef, $cmd, $dat) = split(/:/, $_, 3);
        if ($cmd eq 'BEGIN')
        { $cut = 0;
          @buf = ();
        }
        elsif ($cmd eq 'BEGIN CAPTURE')
        { $dat = '?' unless defined($dat) && length($dat);
          $buf = lc($dat);
          $slf->{'_buf'}->{$buf} = [] unless $dat eq $buf;
        }
        elsif ($cmd eq 'BEGIN LIST')
        { @tbl = ();
        }
        elsif ($cmd eq 'BEGIN SECTION')
        { %idx = ();
          $toc->push_line("$dat\n") if $toc;
        }
        elsif ($cmd eq 'END CAPTURE')
        { $buf = undef;
        }
        elsif ($cmd eq 'END DATA')
        { my ($nam, $val);
          $cut = 1;
          ($val, $nam) = split(/\|/, $dat, 2);
          $val = '?' unless defined($val) && length($val);
          if (@buf)
          { $rpt = $out->add_report('D',"log_$nam");
            $rpt->write_lines(RDA::Object::Buffer->new('l', \@buf));
            push(@tbl, '[['.$rpt->get_report.'][rda_report]['.$val."]]");
            $out->end_report($rpt);
          }
          else
          { push(@tbl, $val);
          }
        }
        elsif ($cmd eq 'END FILE')
        { $cut = 1;
          if (@buf)
          { $dat = '?' unless defined($dat) && length($dat);
            $val = basename($dat);
            $rpt = $out->add_report('F',"log_$val");
            $val = RDA::Object::Sgml::encode($val);
            $rpt->write("---+ Display of $val File\n"
               ."---## Information Taken from "
               .RDA::Object::Sgml::encode($dat)."\n");
            $rpt->write_lines(RDA::Object::Buffer->new('L', \@buf));
            $rpt->write($TOP);
            $idx{dirname($dat)}->{$val} =
              ':[['.$rpt->get_report.'][rda_report]['.$val."]]\n";
            $out->end_report($rpt);
          }
        }
        elsif ($cmd =~ m/^END LIST (\w+)$/)
        { $cut = 1;
          if (@tbl)
          { $dat = (defined($dat) && length($dat))
              ? RDA::Value::Scalar::new_text($dat)
              : RDA::Value::Scalar::new_undef;
            $val = RDA::Value::List->new(RDA::Value::Scalar::new_object(
              RDA::Object::Buffer->new('L', \@tbl)), $dat);
            $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
            $val->eval_value;
          }
        }
        elsif ($cmd =~ m/^END MACRO (\w+)$/)
        { $cut = 1;
          if (@buf)
          { $dat = (defined($dat) && length($dat))
              ? RDA::Value::Scalar::new_text($dat)
              : RDA::Value::Scalar::new_undef;
            $val = RDA::Value::List->new(RDA::Value::Scalar::new_object(
              RDA::Object::Buffer->new('L', \@buf)), $dat);
            $val = $ctx->define_operator([$1, '.macro.'], $ctx, $1, $val);
            $val->eval_value;
          }
        }
        elsif ($cmd eq 'END REPORT')
        { $cut = 1;
          if (@buf)
          { my ($det, $lnk, $ttl, $loc, $nam);

            ($det, $lnk, $ttl, $loc, $nam) = split(/\|/, $dat, 5);
            if (defined($nam))
            { $nam =~ s#[\/\\]#r#g;
            }
            else
            { $nam = $lnk;
            }
            $rpt = $out->add_report('c',$nam);
            $rpt->write("---+!! $ttl\n");
            $rpt->write('---## Location:&nbsp;'
              .RDA::Object::Sgml::encode($loc)."\n") if $loc;
            $rpt->write_lines(RDA::Object::Buffer->new('L', \@buf));
            $rpt->write($TOP);
            $toc->write($det.':[['.$rpt->get_report."][rda_report][$lnk]]\n");
            $out->end_report($rpt);
          }
        }
        elsif ($cmd eq 'END SECTION')
        { $cut = 1;
          if ($toc)
          { if (defined($dat) && $dat =~ m/^\d+$/)
            { $val = $dat + 1;
              foreach my $grp (sort keys(%idx))
              { $toc->write($dat.':'.RDA::Object::Sgml::encode($grp)."\n");
                foreach my $fil (sort keys(%{$idx{$grp}}))
                { $toc->write($val.$idx{$grp}->{$fil});
                }
              }
            }
            $toc->pop_line(1);
          }
          %idx = ();
        }
        elsif ($cmd eq 'SET TITLE')
        { $toc->write("$dat\n") if $toc;
        }
        elsif ($cmd eq 'SET VARIABLE')
        { if (defined($dat))
          { my ($grp, $tbl);

            $grp = ($dat =~ s/^(\w+)://) ? uc($1) : '?';
            if ($dat =~ m/^(.*?)="(.*)"/)
            { $slf->{'_var'}->{$grp}->{$1} = $2;
            }
            elsif ($dat =~ m/^(.*?)=\((.*)\)/)
            { $slf->{'_var'}->{$grp}->{$1} = $tbl = [];
              $dat = $2;
              while ($dat =~ s/^"(.*?)"(,)?//)
              { push (@$tbl, $1);
                last unless $2;
              }
            }
          }
        }
      }
      else
      { push(@buf, $_) unless $cut;
        push(@{$slf->{'_buf'}->{$buf}}, $_) if $buf;
      }
    }
    $ifh->close;
  }

  # Indicate a sucessful completion
  0;
}

=head1 IBM WEBSPHERE-SPECIFIC MACRO

=head2 S<parseWspShow($buf)>

This macro parses the result of a C<show> command and returns it as a hash
reference.

=cut

sub _m_parse_show
{ my ($slf, $ctx, $buf) = @_;
  my ($key, $str, $val, %res);

  $str = join('', $buf->get_lines(1));
  $str =~ s/[\n\r]//g;
  $res{$key} = $val while (($key, $val) = _shp_property(\$str));
  return RDA::Value::Assoc::new_from_data(%res);
}

sub _shp_array
{ my ($buf) = @_;
  my ($res);

  $res = [];
  for (;;)
  { if ($$buf =~ s/^\[(\[)/$1/)  # Hash
    { push(@$res, _shp_hash($buf));
    }
    elsif ($$buf =~ s/^"([^"]*)"\s*// || $$buf =~ s/^([^\]\s]+)\s*//)
    { push(@$res, $1);
    }
    else
    { $$buf =~ s/^\]\s*//;
      return $res;
    }
  }
}

sub _shp_hash
{ my ($buf) = @_;
  my ($key, $res, $val);

  $res = {};
  $res->{$key} = $val while (($key, $val) = _shp_property($buf));
  $$buf =~ s/^\]\s*//;
  $res;
}

sub _shp_property
{ my ($buf) = @_;
  my ($key, $val);

  # Extract the key
  return () unless $$buf =~ s/^\[\s*(\S+)\s+//;
  $key = $1;

  # Extract the value
  if ($$buf =~ s/^\[(\[\[)/$1/)        # Array
  { $val = _shp_array($buf);
  }
  elsif ($$buf =~ s/^\[(\[)/$1/)       # Hash
  { $val = _shp_hash($buf);
  }
  elsif ($$buf =~ s/^\[\s*//)          # Array
  { $val = _shp_array($buf);
  }
  elsif ($$buf =~ s/^"([^"]*)"\s*//)   # String
  { $val = $1;
  }
  elsif ($$buf =~ s/^([^\]\s]+)\s*//)  # Number or keyword
  { $val = $1;
  }
  $$buf =~ s/^\]\s*//;

  # Return the entry
  ($key, $val)
}


# --- WLS Internal routines ---------------------------------------------------

# Execute a WLST request
sub _wls_exec
{ my ($slf, $cod, $var, $out, $err) = @_;
  my ($buf, $cmd, $job, $ofh, $wrk);

  ++$slf->{'_req'};

  # Abort when connection details are missing
  unless (defined($slf->{'_con'}))
  { ++$slf->{'_skp'};
    return -1;
  }

  # Generate the job file
  $slf->{'_sta'} = 0;
  $wrk = $slf->{'_agt'}->get_output;
  $job = $wrk->get_work($JOB, 1);
  $ofh = IO::File->new;
  unless ($ofh->open($job, $CREATE, $TMP_PERMS))
  { ++$slf->{'_err'};
    return -2;
  }
  $buf = $cod
    ? $slf->{'_con'}._add_var($ofh, $var).$cod.$EXT
    : $slf->{'_con'}.$EXT;
  $ofh->syswrite($buf, length($buf));
  $ofh->close;
  if ($slf->{'trc'})
  { for (split(/\n/, $buf))
    { print "WLS: $_\n";
    }
  }

  # Prepare and execute the command
  $cmd = $slf->{'_shl'};
  $cmd .= ' '.RDA::Object::Rda->quote($job, 0);
  $cmd .= ' >';
  $cmd .= $out ? RDA::Object::Rda->quote($out, 0) :
                 RDA::Object::Rda->dev_null;
  $cmd .= ' 2>';
  $cmd .= $err ? RDA::Object::Rda->quote($err, 0) :
                 RDA::Object::Rda->dev_null;
  $slf->{'_sta'} = system($cmd);
  $wrk->clean_work($JOB);

  # Indicate the status completion
  0;
}

# Update the login information
sub _wls_login
{ my ($slf, $ctx, $usr, $pwd, $url) = @_;

  if (defined($usr) && defined ($url))
  { my ($acc);

    $acc = $ctx->get_access;
    if (defined($pwd))
    { $acc->set_password('wls', $url, $usr, $pwd);
    }
    else
    { $pwd = $acc->return_password('wls', $url, $usr);
    }
    $slf->{'_con'} = defined($pwd)
      ? "connect('$usr','$pwd','$url')\n"
      : undef;
  }
  else
  { $slf->{'_con'} = undef;
  }
  0;
}

# --- WSP Internal routines ---------------------------------------------------

# Execute a WSadmin request
sub _wsp_exec
{ my ($slf, $cod, $var, $out, $err) = @_;
  my ($buf, $cmd, $job, $ofh, $wrk);

  ++$slf->{'_req'};

  # Abort when connection details are missing
  unless (defined($slf->{'_con'}))
  { ++$slf->{'_skp'};
    return -1;
  }

  # Generate the job file
  $slf->{'_sta'} = 0;
  $wrk = $slf->{'_agt'}->get_output;
  if ($cod)
  { $job = $wrk->get_work($JOB, 1);
    $ofh = IO::File->new;
    unless ($ofh->open($job, $CREATE, $TMP_PERMS))
    { ++$slf->{'_err'};
      return -2;
    }
    $buf = _add_var($ofh, $var).$cod;
    $ofh->syswrite($buf, length($buf));
    $ofh->close;
    if ($slf->{'trc'})
    { for (split(/\n/, $buf))
      { print "WSP: $_\n";
      }
    }
  }

  # Prepare and execute the command
  $cmd = join(' ', $slf->{'_shl'},$slf->{'_con'},'-lang jython');
  $cmd .= ' -f '.RDA::Object::Rda->quote($job, 0) if $job;
  $cmd .= ' >';
  $cmd .= $out ? RDA::Object::Rda->quote($out, 0) :
                 RDA::Object::Rda->dev_null;
  $cmd .= ' 2>';
  $cmd .= $err ? RDA::Object::Rda->quote($err, 0) :
                 RDA::Object::Rda->dev_null;
  if (defined($slf->{'_log'}))
  { return -2 unless open(WSP, "| $cmd");
    syswrite(WSP, $slf->{'_log'}, length($slf->{'_log'}));
    close(WSP);
    $slf->{'_sta'} = $?;
  }
  else
  { $slf->{'_sta'} = system($cmd);
  }
  $wrk->clean_work($JOB) if $job;

  # Indicate the status completion
  0;
}

# Update the login information
sub _wsp_login
{ my ($slf, $ctx, $usr, $pwd, $hst, $prt) = @_;

  $usr = '' unless defined($usr);
  if (defined($hst) && defined($prt))
  { my ($acc, $con);

    $acc = $ctx->get_access;
    $con = "$hst:$prt";
    if (defined($pwd))
    { $acc->set_password('wsp', $con, $usr, $pwd) if length($pwd);
    }
    else
    { $pwd = $acc->return_password('wsp', $con, $usr, '');
    }
    $slf->{'_con'} = "-conntype SOAP -host $hst -port $prt";
  }
  else
  { $slf->{'_con'} = '-conntype NONE';
  }
  $slf->{'_log'} = (length($usr) || length($pwd))
    ? "$usr\n$pwd\n"
    : undef;
  0;
}

# --- Other routines ----------------------------------------------------------

# Add variables to a job
sub _add_var
{ my ($ofh, $var) = @_;
  my ($buf, $lgt, $ref, $val);

  $buf = '';
  if ($ref = ref($var))
  { $var = $var->as_data if $ref =~ m/^RDA::Value/;
    foreach my $key (sort keys(%$var))
    { $ref = ref($val = $var->{$key});
      if ($ref eq 'ARRAY')
      { $buf .= ($key =~ s/^\+//)
          ? "$key=[".join(',', @$val)."]\n"
          : "$key=[".join(',', map {"'$_'"} @$val)."]\n";
      }
      elsif ($ref eq 'HASH')
      { $buf .= ($key =~ s/^\+//)
          ? "$key={".join(',', map {"'$_':".$val->{$_}} sort keys(%$val))."}\n"
          : "$key={".join(',', map {"'$_':'".$val->{$_}."'"}
                                   sort keys(%$val))."}\n";
      }
      else
      { $buf .= ($key =~ s/^\+//)
          ? "$key=$val\n"
          : "$key='$val'\n";
      }
    }
  }
  $buf;
}

# Indicate that the function is not implemented
sub _not_set
{ 0;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Value|RDA::Value>,
L<RDA::Value::Scalar|RDA::Value::Scalar>,
L<RDA::Object::Buffer|RDA::Object::Buffer>,
L<RDA::Object::Output|RDA::Object::Output>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Report|RDA::Object::Report>,
L<RDA::Object::Sgml|RDA::Object::Sgml>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
