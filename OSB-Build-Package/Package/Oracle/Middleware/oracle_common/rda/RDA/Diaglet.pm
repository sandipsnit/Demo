# Diaglet.pm: Diaglet Package

package RDA::Diaglet;

# $Id: Diaglet.pm,v 1.9 2012/04/25 07:14:15 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Diaglet.pm,v 1.9 2012/04/25 07:14:15 mschenke Exp $
#
# Change History
# 20120122  MSC  Apply agent changes.

=head1 NAME

RDA::Diaglet - Diaglet Package

=head1 SYNOPSIS

<sdp> <options> -X Diaglet <command> <switches> <arg> ...

=head1 DESCRIPTION

The following commands are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Agent;
  use RDA::Block;
  use RDA::Handle::Memory;
  use RDA::Object::Rda;
  use RDA::Object::Xml;
  use RDA::Options;
}

# Define the global public variables
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);
@ISA     = qw(Exporter);

# Define the global private constants
my $EOF = 'Eof';
my $INT = 'Interrupted';
my $NL  = "\n";

# Define the global private variables
my $re_min = qr/^(V?[BO].*|IS|V[\-\+=!<>]|[=!][=~]|[<>]=?)$/i;
my $re_max = qr/^(V?[BO])/i;
my $re_tst = qr/^(V?[BO].*|IS|N.*|V[\-\+=!<>]|[=!][=~]|[<>]=?)$/i;
my %tb_dsc = (
  fam => 'family',
  ini => 'init',
  plt => 'platform',
  prd => 'product',
  set => 'set',
  ttl => 'title',
  typ => 'type',
  );
my %tb_fct = map {$_ => 0} qw(OS PERL RDA SDCL SQL);
my %tb_inf = (
  family   => 5,
  init     => 6,
  name     => 0,
  platform => 4,
  product  => 3,
  title    => 2,
  type     => 1,
  );
my %tb_mod = map {$_ => 0} qw(ATTACH LOG RECORD VERIFY VERIFY_ABORT);
my %tb_res = map {$_ => 0} qw(FAILED PASSED SKIPPED WARNING);
my %tb_syn = map {$_ => 0} qw(text wiki);
my %tb_typ = map {$_ => 0} qw(ATTACH GROUP OS PERL PROMPT RDA SDCL SQL);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<check [-w] [-d dir] [-a|[-p prd,...] [-t typ,...]] [set|file] ...>

This command checks the diaglet. Unless you specify a directory, it considers
rule sets. You can restrict the interactive diaglet selection by specifying
product codes and rule set types. You can instruct RDA to report warnings by
specifying the C<-w> switch.

=cut

sub check
{ my ($agt, @arg) = @_;
  my ($all, $cnt, $dir, $err, $flg, $opt, $prd, $pth, $typ, $vrb, $wrn, $xml);

  # Treat the options
  $opt = RDA::Options::getopts('ad:p:t:w', \@arg);
  $all = 1 if exists($opt->{'a'});
  $dir = exists($opt->{'d'})
    ? $opt->{'d'}
    : $agt->get_config->get_group('D_RDA_HCVE');
  $prd = {map {$_ => 1} split(/,/, $opt->{'p'})} if exists($opt->{'p'});
  $typ = {map {$_ => 1} split(/,/, $opt->{'t'})} if exists($opt->{'t'});
  $vrb = $agt->get_info('vrb');
  $wrn = 1 if exists($opt->{'w'});

  # Get the diaglet list
  unless (@arg)
  { print "\tAnalyzing directory '$dir' ...\n" if $vrb;
    @arg = _get_diaglet($agt, $dir, $prd, $typ, $all);
  }

  # Check the diaglet
  $flg = 0;
  foreach my $arg (@arg)
  { print "\tChecking diaglet '$arg' ...\n" if $vrb;
    $cnt = $err = 0;
    $arg =~ s/\.xml$//i;
    $pth = RDA::Object::Rda->is_absolute($arg)
        ? RDA::Object::Rda->cat_file("$arg.xml")
        : RDA::Object::Rda->cat_file($dir, "$arg.xml");
    eval {
      # Find the diaglet
      ($xml) = _load($agt, $pth)->find('sdp_diaglet');
      die "RDA-08101: Missing or invalid diaglet '$pth'\n"
        unless defined($xml);

      # Check the diaglet
      $err += _error("RDA-08103: Missing set attribute\n")
        unless length($xml->get_value('set', ''));
      $err += _error("RDA-08104: Missing title attribute\n")
        unless length($xml->get_value('title', ''));
      $err += _error("RDA-08105: Missing type attribute\n")
        unless length($xml->get_value('type', ''));
      foreach my $itm ($xml->find('sdp_content'))
      { ++$cnt;
        $typ = $itm->get_value('type', '');
        if ($typ eq 'check')
        { $err += _chk_rule_set($agt, $itm, $cnt, $wrn);
        }
        elsif ($typ eq 'eval')
        { $err += _chk_eval($agt, $itm, $cnt);
        }
        else
        { $err += _error(
             "RDA-08107: Missing or invalid type in content block $cnt\n");
        }
      }
      $err += _error("RDA-08106: Missing content block\n") unless $cnt;
      };
    if ($@)
    { print $@;
      ++$flg;
    }
    elsif ($err)
    { print "$arg has syntax errors.\n" if $vrb;
      ++$flg;
    }
    else
    { print "$arg syntax OK\n" if $vrb;
    }
  }

  # Indicate the completion status
  $agt->set_temp_setting('RDA_EXIT', 2) if $flg;
  0;
}

=head2 S<execute [-r id] [-p prd,...] [-t typ,...] [set] ...>

This command executes rule sets. You can restrict the interactive rule set
selection by specifying product codes and rule set types.

=cut

sub execute
{ my ($agt, @arg) = @_;
  my ($dbg, $dir, $opt, $prd, $typ, $vrb);

  # Treat the options
  $opt = RDA::Options::getopts('p:r:t:', \@arg);
  $dbg = $agt->get_setting('RDA_DEBUG');
  $dir = $agt->get_config->get_group('D_RDA_HCVE');
  $prd = {map {$_ => 1} split(/,/, $opt->{'p'})} if exists($opt->{'p'});
  $typ = {map {$_ => 1} split(/,/, $opt->{'t'})} if exists($opt->{'t'});
  $vrb = $agt->get_info('vrb');

  # Get the diaglet list
  unless (@arg)
  { print "\tAnalyzing directory '$dir' ...\n" if $vrb;
    @arg = _get_diaglet($agt, $dir, $prd, $typ);
  }

  # Treat the diaglet files
  foreach my $arg (@arg)
  { $arg =~ s/\.xml$//i;
    print "\tTreating rule set '$arg'\n" if $vrb;
    $agt->set_setting('TST_MAN', 0);
    $agt->set_setting('TST_ARGS', $arg);
    exit(1) if $agt->collect('TSThcve', $dbg, 0, 0);
  }

  # Indicate a successful completion
  0;
}

=head2 S<help>

This command displays the command syntaxes and the related explanations.

=cut

sub help
{ my ($agt) = @_;
  my ($pkg);

  $pkg = __PACKAGE__.'.pm';
  $pkg =~ s#::#/#g;
  $agt->get_display->dsp_pod([$INC{$pkg}], 1);

  # Disable setup save
  0;
}

=head2 S<man [-d dir] [-r id] [-p prd,...] [-t typ,...] [set|file] ...>

This command generates a report containing the diaglet documentation. Unless
you specify a directory, it considers rule sets. You can restrict the
interactive diaglet selection by specifying product codes and rule set types.

=cut

sub man
{ my ($agt, @arg) = @_;
  my ($dbg, $dir, $opt, $prd, $typ, $vrb);

  # Treat the options
  $opt = RDA::Options::getopts('d:p:r:t:', \@arg);
  $dbg = $agt->get_setting('RDA_DEBUG');
  $dir = exists($opt->{'d'})
    ? $opt->{'d'}
    : $agt->get_config->get_group('D_RDA_HCVE');
  $prd = {map {$_ => 1} split(/,/, $opt->{'p'})} if exists($opt->{'p'});
  $typ = {map {$_ => 1} split(/,/, $opt->{'t'})} if exists($opt->{'t'});
  $vrb = $agt->get_info('vrb');

  # Get the diaglet list
  unless (@arg)
  { print "\tAnalyzing directory '$dir' ...\n" if $vrb;
    @arg = _get_diaglet($agt, $dir, $prd, $typ);
  }

  # Generate the documentation
  foreach my $arg (@arg)
  { print "\tGenerating the documentation for diaglet '$arg' ...\n" if $vrb;
    $arg =~ s/\.xml$//i;
    $agt->set_setting('TST_MAN', 1);
    $agt->set_setting('TST_ARGS', $arg);
    exit(1) if $agt->collect('TSThcve', $dbg, 0, 0);
  }

  # Indicate a successful completion
  0;
}

=head2 S<version [-d dir] [-p prd,...] [-t typ,...] [set|file] ...>

This command displays the version information contained in the diaglet. Unless
you specify a directory, it considers rule sets. You can restrict the
interactive diaglet selection by specifying product codes and rule set types.

=cut

sub version
{ my ($agt, @arg) = @_;
  my ($dir, $err, $opt, $prd, $pth, $typ, $vrb, $xml);

  # Treat the options
  $opt = RDA::Options::getopts('d:p:t:', \@arg);
  $dir = exists($opt->{'d'})
    ? $opt->{'d'}
    : $agt->get_config->get_group('D_RDA_HCVE');
  $prd = {map {$_ => 1} split(/,/, $opt->{'p'})} if exists($opt->{'p'});
  $typ = {map {$_ => 1} split(/,/, $opt->{'t'})} if exists($opt->{'t'});
  $vrb = $agt->get_info('vrb');

  # Get the diaglet list
  unless (@arg)
  { print "\tAnalyzing directory '$dir' ...\n" if $vrb;
    @arg = _get_diaglet($agt, $dir, $prd, $typ);
  }

  # Extract the versions
  $err = 0;
  foreach my $arg (@arg)
  { print "\tExtracting versions from diaglet '$arg' ...\n" if $vrb;

    # Parse the diaglet
    $arg =~ s/\.xml$//i;
    eval {
      $pth = RDA::Object::Rda->is_absolute($arg)
        ? RDA::Object::Rda->cat_file("$arg.xml")
        : RDA::Object::Rda->cat_file($dir, "$arg.xml");
      ($xml) = _load($agt, $pth)->find('sdp_diaglet');
      die "RDA-08101: Missing or invalid diaglet '$pth'\n"
        unless defined($xml);
      };

    # Report the version information
    if ($@)
    { print $@;
      ++$err;
    }
    else
    { foreach my $itm ($xml->find('sdp_meta type="version" id="\S"'))
      { printf("%-20s %s\n", _get_version($itm->get_value('id')));
      }
      foreach my $rul ($xml->find('.../sdp_rule id="\d+" version="\d+"'))
      { printf("  %-18s %s\n", 'Rule '.$rul->get_value('id'),
          $rul->get_value('version'));
      }
    }
  }

  # Indicate the completion status
  $agt->set_temp_setting('RDA_EXIT', 2) if $err;
  0;
}

# --- Internal routines -------------------------------------------------------

# Check the action code
sub _chk_action
{ my ($agt, $dir, $nam, $cod) = @_;
  my ($blk);

  $blk = RDA::Block->new($nam, $dir);
  $cod = '' unless defined($cod);
  $blk->parse($agt, RDA::Handle::Memory->new($cod));
}

# Check an eval content block
sub _chk_eval
{ my ($agt, $xml, $blk) = @_;
  my ($cnt, $err, $tag);

  $cnt = $err = 0;
  foreach my $itm ($xml->get_content)
  { ++$cnt;
    $tag = $itm->get_name('');
    if ($tag eq 'sdp_ask')
    { $err += _error(
        "RDA-08180: Missing attribute name in request '$blk/$cnt'\n")
        unless defined($itm->get_value('name'));
    }
    elsif ($tag eq 'sdp_exec')
    { $err += _error("RDA-08181: Missing command in request '$blk/$cnt'\n")
        unless defined($itm->get_value('command'));
    }
    elsif ($itm->get_type eq 'T')
    { $err += _error("RDA-08182: Invalid tag '$tag'\n");
    }
    else
    { $err += _error("RDA-08183: Only tags expected in request '$blk/$cnt'\n");
    }
  }
  $err;
}

# Check the message references
sub _chk_message
{ my ($tbl, $val) = @_;

  foreach my $uid (split(/,/, $val))
  { return 1 unless $uid =~ m/%(\w+\.)*\w+%/ || exists($tbl->{$uid});
  }
  0;
}

# Check a rule set
sub _chk_rule_set
{ my ($agt, $xml, $blk, $flg) = @_;
  my ($cnt, $dir, $err, $mod, $nbg, $nbf, $nbr, $out, $rid, $typ, $uid, $val,
      %fct, %msg, %out, %rul, %tbl);

  $err = 0;

  # Validate the opt-out identifier
  $err += _error("RDA-O8108: Invalid opt-out identifier\n")
    unless $xml->get_value('id','X') =~ m/^\w+$/;

  # Analyze the facts
  $dir = $agt->get_config->get_group('D_RDA_CODE');
  $nbf = 0;
  foreach my $itm ($xml->find('sdp_facts/sdp_fact'))
  { ++$nbf;
    if (defined($uid = $itm->get_value('id')))
    { next if $fct{$uid}++;

      # Check the presence of a description
      $cnt = $itm->find('sdp_description');
      $err += _error("RDA-08126: Fact $uid: Missing description\n")
        unless $cnt;
      $err += _error("RDA-08128: Fact $uid: Multiple descriptions\n")
        if $cnt > 1;

      # Validate the triggering parameters
      $cnt = 0;
      foreach my $trg ($itm->find('sdp_parameters/sdp_parameter'))
      { next unless defined($val = $trg->get_value('name'));
        $err += _error("RDA-08124: Fact $uid: Invalid parameter name '$val'\n")
          unless $val =~ m/^(\w+\.)+\w+$/;
        ++$cnt;
      }
      $err += _error("RDA-08127: Fact $uid: Missing parameter\n") unless $cnt;

      # Validate the fact commands
      $cnt = 0;
      foreach my $cmd ($itm->find('sdp_command'))
      { ++$cnt;

        # Validate the command type
        $typ = uc($cmd->get_value('type', ''));
        $err += _error("RDA-08123: Fact $uid: Invalid command type '$typ'\n")
           unless exists($tb_fct{$typ});

        # Check the command code
        if (($typ eq 'SDCL' || $typ eq 'RDA')
          && length($val = $cmd->get_data))
        { $err += _error("RDA-08122: Fact $uid: Command errors\n")
            if _chk_action($agt, $dir, "fact$uid", _fmt_code($val));
        }
      }
      $err += _error("RDA-08125: Fact $uid: Missing command\n") unless $cnt;
    }
    else
    { $err += _error("RDA-08120: Missing identifier in fact $nbf\n");
    }
  }

  # Analyze the messages
  $cnt = 0;
  foreach my $itm ($xml->find('sdp_messages/sdp_message'))
  { ++$cnt;
    if (defined($uid = $itm->get_value('id')))
    { ++$msg{$uid};
    }
    else
    { $err += _error("RDA-08170: Missing identifier in message $cnt\n");
    }
  }

  # Analyze the rules
  $nbg = 0;
  foreach my $grp ($xml->find('sdp_group'))
  { ++$nbg;
    $nbr = 0;
    $out = $grp->get_value('opt_out');
    foreach my $rul ($grp->find('sdp_rule'))
    { ++$nbr;

      # Check the rule identifier
      $rid = $rul->get_value('id','');
      if ($rid =~ m/^\w+$/)
      { next if $tbl{$rid}++;
        $err += _error("RDA-08138: Rule $rid: Identifier too long\n")
          if length($rid) > 6;
        $out{$rid} = 0 if $rul->get_value('opt_out', $out);

        # Check the presence of a description
        $cnt = $rul->find('sdp_description');
        $err += _error("RDA-08148: Rule $rid: Missing description\n")
          unless $cnt;
        $err += _error("RDA-08152: Rule $rid: Multiple descriptions\n")
          if $cnt > 1;

        # Check the dependencies
        $rul{$rid} = [];
        foreach my $dep ($rul->find('sdp_dependencies/sdp_dependency'))
        { $uid = $dep->get_value('id','');
          if ($uid !~ m/^\w+$/)
          { $err += _error(
              "RDA-08147: Rule $rid: Missing dependency identifier\n");
          }
          elsif ($rid)
          { push(@{$rul{$rid}}, $uid);

            # Check the condition
            if (defined($val = $dep->get_value('condition')))
            { $err += _error("RDA-08160: Rule $rid/Dependency $uid:"
                ." Invalid condition '$val'\n")
                unless $val =~ $re_tst;
              $err += _error("RDA-08164: Rule $rid/Dependency $uid:"
                ." Minimum attribute required for condition '$val'\n")
                if $val =~ $re_min && !defined($dep->get_value('minimum'));
              $err += _error("RDA-08165: Rule $rid/Dependency $uid:"
                ." Maximum attribute required for condition '$val'\n")
                if $val =~ $re_max && !defined($dep->get_value('maximum'));
            }

            # Check the result
            $val = $dep->get_value('result','FAILED');
            $err += _error("RDA-08162: Rule $rid/Dependency $uid:"
              ." Invalid result code '$val'\n")
              unless exists($tb_res{$val});

            # Check the syntax
            $val = $dep->get_value('syntax','text');
            $err += _error("RDA-08163: Rule $rid/Dependency $uid:"
              ." Invalid syntax type '$val'\n")
              unless exists($tb_syn{$val});

            # Check the messages
            $err += _error("RDA-08161: Rule $rid/Dependency $uid:"
              ." Invalid message reference '$val'\n")
              if defined($val = $dep->get_value('message'))
              && _chk_message(\%msg, $val);
          }
        }

        # Check the command blocks
        $cnt = 0;
        $mod = uc($rul->get_value('mode', ''));
        $typ = '';
        foreach my $cmd ($rul->find('sdp_command'))
        { ++$cnt;

          # Validate the command type
          $typ = uc($cmd->get_value('type', ''));
          $err += _error(
            "RDA-08149: Rule $rid: Missing or invalid command type '$typ'\n")
            unless exists($tb_typ{$typ});

          # Check the command code
          if (($typ eq 'SDCL' || $typ eq 'RDA')
            && length($val = $cmd->get_data))
          { $err += _error("RDA-08137: Rule $rid: Command errors\n")
              if _chk_action($agt, $dir, "rule$rid", _fmt_code($val));
          }
          elsif ($typ eq 'ATTACH')
          { $mod = 'ATTACH';
          }

          # Check parameter and variable
          $err += _error("RDA-08133: Rule $rid: Bad parameter name '$val'\n")
            if defined($val = $cmd->get_value('exec'))
            && $val !~ m/^(\w+\.)+\w+$/;
          $err += _error("RDA-08133: Rule $rid: Bad parameter name '$val'\n")
            if defined($val = $cmd->get_value('parameter'))
            && $val !~ m/^(\w+\.)+\w+$/;
          $err += _error("RDA-08135: Rule $rid: Bad variable name '$val'\n")
            if defined($val = $cmd->get_value('variable'))
            && $val !~ m/^\$\w+$/;
        }
        $err += _error("RDA-08145: Rule $rid: Missing command\n")
          unless $cnt;

        # Check the rule mode and name
        $val = length($rul->get_value('name', ''));
        $err += _error("RDA-08151: Rule $rid: Missing rule name\n")
          unless $val;
        $err += _warn("RDA-08153: Rule $rid: Rule name too long\n")
          if $flg && $val > 20;
        $err += _error(
          "RDA-08150: Rule $rid: Missing or invalid rule mode '$mod'\n")
          unless exists($tb_mod{$mod});

        # Check the actions
        $cnt = 0;
        foreach my $act ($rul->find('sdp_actions/sdp_action'))
        { # Check the condition
          if (defined($val = $act->get_value('condition')))
          { ++$cnt if $cnt;
            $err += _error(
              "RDA-08139: Rule $rid: Invalid condition '$val' in action\n")
              unless $val =~ $re_tst;
            $err += _error("RDA-08144: Rule $rid: "
              ."Minimum attribute required for condition '$val' in action\n")
              if $val =~ $re_min && !defined($act->get_value('minimum'));
            $err += _error("RDA-08143: Rule $rid: "
              ."Maximum attribute required for condition '$val' in action\n")
              if $val =~ $re_max && !defined($act->get_value('maximum'));
          }
          else
          { ++$cnt;
          }

          # Check the result
          $val = $act->get_value('result','FAILED');
          $err += _error("RDA-08141: Rule $rid: "
            ."Invalid result code '$val' in action\n")
            unless exists($tb_res{$val});

          # Check the syntax
          $val = $act->get_value('syntax','text');
          $err += _error("RDA-08142: Rule $rid: "
            ."Invalid syntax type '$val' in action\n")
            unless exists($tb_syn{$val});

          # Check the variable
          $err += _error("RDA-08134: Rule $rid: "
            ."Bad variable name '$val' in action\n")
            if defined($val = $act->get_value('variable'))
            && $val !~ m/^\$\w+$/;

          # Check the messages
          $err += _error("RDA-08140: Rule $rid: "
            ."Invalid message reference '$val' in action\n")
            if defined($val = $act->get_value('message'))
            && _chk_message(\%msg, $val);
        }
        $err += _error("RDA-08132: Rule $rid: ".($cnt -1)
          ." action(s) never used\n")
          if $cnt > 1;
      }
      else
      { $err += _error( "RDA-08130: Missing or invalid rule identifier "
          ."in '$blk/$nbg/$nbr'\n");
      }
    }
    $err += _error("RDA-08111: Missing rule in group $nbg\n") unless $nbr;
  }
  $err += _error("RDA-08110: Missing group\n") unless $nbg;

  # Detect the duplicate facts
  foreach $uid (sort keys(%fct))
  { $err += _error("RDA-08121: Duplicate fact identifier '$uid'\n")
      if $fct{$uid} > 1;
  }

  # Detect the duplicate messages
  foreach $uid (sort keys(%msg))
  { $err += _error("RDA-08171: Duplicate message identifier '$uid'\n")
      if $msg{$uid} > 1;
  }

  # Detect the missing rules
  foreach $rid (sort keys(%rul))
  { foreach my $did (@{$rul{$rid}})
    { ++$out{$did} if exists($out{$did});
      $err += _error(
        "RDA-08146: Rule $rid: Missing definition for dependency $did\n")
        unless exists($rul{$did});
    }
    $err += _error("RDA-08131: Duplicate rule $rid\n")
      if $tbl{$rid} > 1;
  }

  # Detect rules that can opted out but referenced in dependencies
  foreach $rid (sort keys(%out))
  { $err += _error("RDA-08154: Rule $rid: Opt-out/ dependency conflict\n")
      if $out{$rid};
  }

  # Detect circular references
  %tbl = ();
  foreach $rid (sort keys(%rul))
  { if (exists($tbl{$rid}))
    { $err += _error("RDA-08136: Rule $rid: Circular dependencies\n")
        if $tbl{$rid};
    }
    elsif (_detect_loop(\%tbl, \%rul, $rid))
    { $err += _error("RDA-08136: Rule $rid: Circular dependencies\n");
    }
  }

  # Return the number of errors
  $err;
}

# Detect circular dependencies
sub _detect_loop
{ my ($tbl, $rul, $rid) = @_;

  $tbl->{$rid} = 1;
  foreach my $did (@{$rul->{$rid}})
  { if (exists($tbl->{$did}))
    { return 1 if $tbl->{$did};
    }
    elsif (exists($rul->{$did}))
    { return 1 if _detect_loop($tbl, $rul, $did);
    }
  }
  $tbl->{$rid} = 0;
}

# Report an error
sub _error
{ print @_;
  1;
}

# Format the code
sub _fmt_code
{ my ($val) = @_;
  my ($chr, $key, $ref);

  # Replace the references
  $chr = "\224";
  while ($val =~ m/(%+(.*?)%+)/)
  { ($ref, $key) = ($1, $2);
    if ($key =~ m/^(\w+\.)*\w+$/)
    { $ref = 0;
    }
    else
    { # Escape when not a reference
      $ref =~ s/%!/%/;
      $ref =~ s/!%/%/;
      $ref =~ s/%/$chr/g;
    }
    $val =~ s/%+$key%+/$ref/g;
  }
  $val =~ s/$chr/%/g;

  # Return the code without reference
  $val;
}

# Get the description 
sub _get_desc
{ my ($xml, $glb) = @_;
  my ($rec, $val);

  $rec = $glb ? {%$glb} : {};
  foreach my $key (keys(%tb_dsc))
  { $rec->{$key} = $val if defined($val = $xml->get_value($tb_dsc{$key}));
  }
  $rec->{'cnt'} = 0;
  $rec->{'xml'} = $xml;
  $rec;
}

# Select a diaglet
sub _get_diaglet
{ my ($agt, $dir, $prd, $typ, $all) = @_;
  my ($buf, $cfg, $cnt, $fam, $lin, $osn, $rec, $str, @rsp);

  # Initialization
  $cfg = $agt->get_config;
  $fam = $cfg->get_family;
  $osn = $cfg->get_os;

  # Get the diaglet list
  $cnt = 0;
  if (opendir(DLD, $dir))
  { $buf = ".P\nSelect a diaglet:\n\n";
    foreach my $fil (readdir(DLD))
    { next unless $fil =~ m/\.xml/i;
      next unless ($rec = _get_info($agt, $dir, $fil));
      unless ($all)
      { if ($rec->[4])
        { next unless _tst_member($rec->[4], $osn);
        }
        elsif ($rec->[5])
        { next unless _tst_member($rec->[5], $fam);
        }
        next if $prd && !exists($prd->{$rec->[3]});
        next if $typ && !exists($typ->{$rec->[1]});
      }
      $buf .= sprintf(".I '  %3d  '\n\%s\n\n", ++$cnt, $rec->[2]);
      $rsp[$cnt] = $rec->[0];
    }
    closedir(DLD);
    $buf .= ".N 1\n.P\nEnter the item number:\n\n";
  }
  die "RDA-08100: No such rulesets\n" unless $cnt;

  # Return an empty list when the input is disabled
  return () if $agt->get_info('yes');

  # Get the selected item
  $agt->get_display->dsp_report($buf, 0);
  for (;;)
  { # Read a line
    eval {
      local $SIG{'INT'} = sub { die "$INT\n"; };

      $lin = <STDIN>;
      syswrite(STDOUT, $NL, length($NL));
      die "$EOF\n" unless defined($lin);
      $lin =~ s/[\n\r\s]+$//;
      $lin =~ s/^\s+//;
    };
    return () if $@ || !length($lin);

    # Validate the answer
    last if $lin =~ m/^\d+$/ && $lin > 0 && $lin <= $cnt;
    if ($lin eq '?')
    { $agt->get_display->dsp_report($buf, 0);
    }
    else
    { $str = "Enter only a number between 1 and $cnt\n";
      syswrite(STDOUT, $str, length($str));
    }
  }
  ($rsp[$lin]);
}

# Get the diaglet information
sub _get_info
{ my ($slf, $dir, $fil) = @_;
  my ($buf, $cnt, $rec);

  return undef unless open(DLF, '<'.RDA::Object::Rda->cat_file($dir, $fil));

  $cnt = 10;
  $fil =~ s/\.xml$//i;
  $rec = [$fil, '', $fil, ''];
  $buf = '';
  while (<DLF>)
  { $buf .= $_;
    $buf =~ s/[\n\r\s]*$/ /;
    if ($buf !~ m#<sdp_diaglet#)
    { $buf = '';
      last unless --$cnt;
    }
    elsif ($buf =~ m#<sdp_diaglet.*?>#)
    { $buf =~ s#.*<sdp_diaglet\s+##;
      while ($buf =~ s#^(\w+)\s*=\s*['"](.*?)['"]\s*##)
      { $rec->[$tb_inf{$1}] = $2 if exists($tb_inf{$1});
      }
      last;
    }
  }
  close(DLF);
  $rec->[1] ? $rec : undef;
}

# Extract the version 
sub _get_version
{ my ($str) = @_;
  my ($fil, $ver);

  (undef, $fil, $ver) = split(/\s+/, $str);
  $fil =~ s/,v$//i;
  ($fil, $ver);
}

# Load the diaglet
sub _load
{ my ($agt, $pth) = @_;
  my ($xml);

  # Parse the diaglet
  $xml = RDA::Object::Xml->new($agt->get_setting('XML_TRACE', 0));
  $xml->normalize_text(-1);
  $xml->parse_file($pth);

  # Reject diaglet with XML errors
  die "RDA-08102: Diaglet XML parsing error(s)\n" if $xml->get_error;

  # Return the XML tree
  $xml;
}

# Test is a value is member of a list
sub _tst_member
{ my ($lst, $str) = @_;

  foreach my $itm (split(/,/, $lst))
  { return 1 if $itm eq $str;
  }
  0;
}

# Report a warning
sub _warn
{ print @_;
  0;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Context|RDA::Context>,
L<RDA::Convert|RDA::Convert>,
L<RDA::Daemon|RDA::Daemon>,
L<RDA::Diff|RDA::Diff>,
L<RDA::Discover|RDA::Discover>,
L<RDA::Extra|RDA::Extra>,
L<RDA::Filter|RDA::Filter>,
L<RDA::Log|RDA::Log>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Xml.pm|RDA::Object::Xml.pm>,
L<RDA::Options|RDA::Options>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Remote|RDA::Remote>,
L<RDA::Render|RDA::Render>,
L<RDA::Setting|RDA::Setting>,
L<RDA::Upgrade|RDA::Upgrade>,
L<RDA::Value|RDA::Value>,
L<RDA::Web|RDA::Web>,
L<RDA::Web::Display|RDA::Web::Display>,
L<RDA::Web::Help|RDA::Web::Help>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut

