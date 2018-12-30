# Help.pm: Help Web Service

package RDA::Web::Help;

# $Id: Help.pm,v 2.14 2012/04/26 05:49:17 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Web/Help.pm,v 2.14 2012/04/26 05:49:17 mschenke Exp $
#
# Change History
# 20120126  MSC  Add RDA drivers.

=head1 NAME

RDA::Web::Help - Help Web Service

=head1 SYNOPSIS

require RDA::Web::Help;

=head1 DESCRIPTION

The objects of the C<RDA::Web::Help> class are used to perform help requests.

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use RDA::Block;
  use RDA::Handle::Data;
  use RDA::Handle::Memory;
  use RDA::Module;
  use RDA::Object;
  use RDA::Object::Pod;
  use RDA::Object::Rda;
  use RDA::Object::Sgml;
  use RDA::Profile;
}

# Define the global public variables
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 2.14 $ =~ /(\d+)\.(\d+)/);

# Define the global constants
my $DOC = "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>";
my $EOL = "\015\012";

# Define the global private variables

# Define the related link sections
my $tb_eng = [
  [['RDA', [
    ['Agent',    '/help/engine/RDA/Agent', 'RDA::Agent'],
    ['Packages', '/help/dir/RDA',          'rda'],
    ['Handles',  '/help/dir/RDA/Handle',   'rda_handle'],
    ['Objects',  '/help/dir/RDA/Object',   'rda_object'],
    ['Drivers',  '/help/dir/RDA/Driver',   'rda_driver'],
  ]]],
  [['SDCL', [
    ['Macro Libraries',        '/help/dir/RDA/Library',  'rda_library'],
    ['Packages',               '/help/dir/RDA',          'rda'],
    ['Objects',                '/help/dir/RDA/Object',   'rda_object'],
    ['Drivers',                '/help/dir/RDA/Driver',   'rda_driver'],
    ['Operators',              '/help/dir/RDA/Operator', 'rda_oper'],
    ['SDCL Object Interfaces', '/help/dir/obj',          'obj'],
    ['Values',                 '/help/dir/RDA/Value',    'rda_value'],
  ]]],
  [['SDSL', [
    ['Module',  '/help/engine/RDA/Module',  'RDA::Module'],
    ['Setting', '/help/engine/RDA/Setting', 'RDA::Setting'],
  ]]],
  [['Miscellaneous', [
    ['Cross References',      '/help/dir/obj',     'xref_def'],
    ['Error Explanation',     '/help/error',       'error'],
    ['Pod Documentation',     '/help/dir/pod',     'pod'],
    ['Multi-run Collections', '/help/mrc',         'mrc'],
    ['README files',          '/help/dir/txt',     'txt'],
    ['XML Converter Plugins', '/help/dir/Convert', 'convert'],
  ]]],
  ];
my $tb_mrc = [[
  ['Collection Modules',                '/help/mrc',        'mrc'],
  ['Collection Group Cross References', '/help/xref/group', 'xref_mrc'],
  ]];
my $tb_prf = [[
  ['Profiles',         '/help/profile',      'profile'],
  ['Cross References', '/help/xref/profile', 'xref_prf'],
  ]];
my $tb_rul = [[
  ['Available Rule Sets', '/help/hcve', 'hcve'],
  ]];
my $tb_set = [[
  ['Data Collection Module Setup', '/help/setup/list/dm', 'setup_list_dm'],
  ['Test Module Setup',            '/help/setup/list/tm', 'setup_list_tm'],
  ['Tool Setup',                   '/help/setup/list/tl', 'setup_list_tl'],
  ]];
my $tb_xrf = [[
  ['Collect Cross References',             '/help/dir/def',  'def'],
  ['Conversion Group Cross Reference',     '/help/xref/cnv', 'xref_cnv'],
  ['Multi-run Collection Cross Reference', '/help/xref/mrc', 'xref_mrc'],
  ['Object Interfaces',                    '/help/dir/obj',  'obj'],
  ['Profiles Cross Reference',             '/help/xref/prf', 'xref_prf'],
  ['Setup Cross References',               '/help/dir/cfg',  'cfg'],
  ]];

# Define the generation directives
my %tb_dsp = (
  '*'     => {},
  module  => {module  => '#',
              modules => '#'},
  mrc     => {mrc     => '#'},
  profile => {profile => '#'},
  setup   => {setup   => '#'},
  );
my %tb_hlp = (
  dir     => {fct => \&do_dir,
              rel => $tb_eng,
             },
  engine  => {fct => \&do_engine,
              rel => $tb_eng,
             },
  error   => {fct => \&do_error,
              rel => $tb_eng,
             },
  hcve    => {fct => \&do_hcve,
              rel => $tb_rul,
             },
  module  => {fct => \&do_module,
             },
  mrc     => {fct => \&do_mrc,
              rel => $tb_mrc,
             },
  profile => {fct => \&do_profile,
              rel => $tb_prf,
             },
  rda     => {fct => \&do_rda,
             },
  setup   => {fct => \&do_setup,
              rel => $tb_set,
             },
  text    => {fct => \&do_text,
              rel => $tb_eng,
             },
  xref    => {fct => \&do_xref,
              rel => $tb_xrf,
             },
  );
my %tb_lnk = (
  modvert => '/help/engine/Convert',
  RDA     => '/help/engine/RDA',
  cfg     => '/help/xref/cfg',
  def     => '/help/xref/def',
  dir     => '/help/dir',
  hcve    => '/help/hcve',
  module  => '/help/module',
  modules => '/help/module',
  mrc     => '/help/mrc',
  obj     => '/help/xref/obj',
  profile => '/help/profile',
  setup   => '/help/setup',
  );
my %tb_opt = (
  cfg     => {ext => '.cfg',
              fil => 1,
              grp => 'D_RDA_CODE',
              rel => $tb_xrf,
              typ => '',
             },
  def     => {ext => '.def',
              fil => 1,
              grp => 'D_RDA_CODE',
              rel => $tb_xrf,
              typ => '',
             },
  obj     => {ext => '.pm',
              fil => 1,
              grp => 'D_RDA_PERL',
              rel => $tb_xrf,
              req => ['RDA/Object', 'RDA', 'Object'],
              typ => 'obj/',
             },
  pod     => {ext => '.pod',
              dir => 1,
              grp => 'D_RDA_POD',
              typ => '',
             },
  top     => {ext => '.pm',
              dir => [qw(Convert RDA)],
              typ => '',
             },
  txt     => {ext => '.txt',
              dir => {engine => 1},
              fil => 1,
              grp => 'D_RDA',
              par => -1,
              typ => '',
             },
  Convert => {ext => '.pm',
              dir => 1,
              par => 1,
              typ => '',
             },
  RDA     => {ext => '.pm',
              dir => 1,
              par => 1,
              typ => '',
             },
  );
my %tb_ttl = (
  cfg          => 'Setup Specifications',
  convert      => 'XML Converter Plugins',
  def          => 'Collect Specifications',
  hcve         => 'Available Rule Sets',
  obj          => 'SDCL Object Interfaces',
  pod          => 'Pod Documentation',
  rda          => 'RDA Packages',
  rda_driver   => 'RDA Drivers',
  rda_handle   => 'RDA Handles',
  rda_object   => 'RDA Objects',
  rda_library  => 'SDCL Libraries',
  rda_operator => 'SDCL Operators',
  rda_value    => 'SDCL Values',
  rda_web      => 'Web Services',
  txt          => 'README Files',
  txt_engine   => 'Compiled Engine README Files',
  );
my %tb_typ = (
  Convert  => '/help/engine/Convert/',
  RDA      => '/help/engine/RDA/',
  cfg      => '/help/xref/cfg/',
  def      => '/help/xref/def/',
  dir      => '/help/dir/',
  hcve     => '/help/hcve/',
  module   => '/help/module/',
  modules  => '/help/module/',
  mrc      => '/help/mrc/',
  obj      => '/help/xref/obj/',
  pod      => '/help/engine/pod/',
  profile  => '/help/profile/',
  setup    => '/help/setup/',
  txt      => '/help/text/',
  xref_def => '/help/xref/def/',
  xref_obj => '/help/xref/obj/',
  );

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Web::Help-E<gt>new($agt)>

The object constructor. This method enables you to specify the agent reference.

C<RDA::Web::Help> is represented by a blessed hash reference. The following
special key is used:

=over 12

=item S<    B<'_agt'> > Reference to the agent object

=item S<    B<'_cfg'> > Reference to the RDA software configuration

=item S<    B<'_col'> > Screen width (in columns)

=item S<    B<'_dir'> > Report directory

=item S<    B<'_grp'> > Report group

=item S<    B<'_man'> > Rule set manual page cache

=item S<    B<'_pod'> > Pod rendering object

=item S<    B<'_ttl'> > Rule set title cache

=back

Internal keys are prefixed by an underscore.

=cut

sub new
{ my ($cls, $agt) = @_;
  my ($cfg, $out);

  # Create the service object and return the object reference
  $cfg = $agt->get_config;
  $out = $agt->get_output;
  bless {
    _agt => $agt,
    _cfg => $cfg,
    _col => $cfg->get_columns,
    _dir => $out->get_path('C'),
    _grp => $out->get_group,
    _man => {},
    _pod => RDA::Object::Pod->new($cfg),
    _ttl => {},
    }, ref($cls) || $cls;
}

=head2 S<$h-E<gt>delete>

This method deletes the help object.

=cut

sub delete
{ undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>display($ofh,$met,$url,$cnt)>

This method executes a display request. It returns 0 on successful
completion. Otherwise, it returns a non-zero value.

=cut

sub display
{ my ($slf, $ofh, $met, $url, $cnt) = @_;
  my ($det, $nam, $req, $tbl, $ttl, $typ, %lnk, %typ);

  # Normalize the URL
  $url = 'rda' unless $url;

  # Validate the request
  ($typ, $req) = split(/\//, $url, 2);
  return 1 if !exists($tb_hlp{$typ}) || (defined($req) && $req =~ m#(^|\/)\.#);
  $tbl = $tb_hlp{$typ};
  ($nam, $ttl, $det) = &{$tbl->{'fct'}}($slf, $req, $tbl->{'rel'}, $cnt);
  return 2 unless defined($det);

  # Generate the page
  %lnk = %tb_lnk;
  %typ = %tb_typ;
  %tb_lnk = ();
  %tb_typ = %{$tb_dsp{exists($tb_dsp{$typ}) ? $typ : '*'}};
  eval {
    $slf->{'_pod'}->render($ofh, {
      det => $det,
      dsp => 1,
      fct => \&_fmt_link,
      nam => $nam,
      ttl => $ttl,
      });
  };
  %tb_lnk = %lnk;
  %tb_typ = %typ;
  syswrite($ofh, $@, length($@)) if $@;

  # Indicate a successful completion
  0;
}

=head2 S<$h-E<gt>request($ofh,$met,$url,$cnt)>

This method executes a help request. It returns 0 on successful
completion. Otherwise, it returns a non-zero value.

=cut

sub request
{ my ($slf, $ofh, $met, $url, $cnt) = @_;
  my ($det, $hdr, $nam, $rel, $req, $tbl, $ttl, $typ);

  # Normalize the URL
  $url = 'rda' unless $url;

  # Validate the request
  ($typ, $req) = split(/\//, $url, 2);
  return 1 if !exists($tb_hlp{$typ}) || (defined($req) && $req =~ m#(^|\/)\.#);
  $tbl = $tb_hlp{$typ};
  ($nam, $ttl, $det, $rel) = &{$tbl->{'fct'}}($slf, $req, $tbl->{'rel'}, $cnt);
  return 2 unless defined($det) || defined($rel);

  # Generate the page
  $hdr = "HTTP/1.0 200 OK$EOL".
    "Content-Type: text/html; charset=UTF-8$EOL$EOL";
  syswrite($ofh, $hdr, length($hdr));
  eval {
    $slf->{'_pod'}->render($ofh, {
      det => $det,
      fct => \&_fmt_link,
      nam => $nam,
      rel => $rel,
      tab => [['RDA Manual Page', '/help/rda',     'rda_man'],
              ['Modules',         '/help/module',  'module'],
              ['Profiles',        '/help/profile', 'profile'],
              ['Setup',           '/help/setup',   'setup'],
              ['HCVE',            '/help/hcve',    'hcve'],
              ['Engine',          '/help/engine',  'RDA::Agent'],
             ],
      ttl => $ttl,
      });
  };
  syswrite($ofh, $@, length($@)) if $@;

  # Indicate a successful completion
  0;
}

# Treat a directory help request
sub do_dir
{ my ($slf, $req, $rel) = @_;
  my ($buf, $cfg, $cls, $cur, $dir, $nam, $opt, $par, $pre, $top, $ttl, $typ,
      @dir, @pkg, @sub, @tbl);

  # Get the file list
  $cfg = $slf->{'_cfg'};
  if ($req)
  { ($dir, @sub) = split(/\//, $req);
    return () unless exists($tb_opt{$dir});
    $opt = $tb_opt{$dir};
    ($req, @sub) = @{$opt->{'req'}} if exists($opt->{'req'});
    $typ = $opt->{'typ'};
    $par = $cur = "dir/$req";
    $par =~ s#/[^\/]+$##;
    $nam = lc($req);
    $nam =~ s#/#_#g;
    $pre = "$nam\_";
    $ttl = exists($tb_ttl{$nam}) ? $tb_ttl{$nam} : "$req Directory Content";

    $top = exists($opt->{'grp'})
      ? $cfg->cat_dir($cfg->get_group($opt->{'grp'}), @sub)
      : $cfg->cat_dir($cfg->get_group('D_RDA_PERL'), $req);
    return () unless opendir(DIR, $top);
    @tbl = readdir(DIR);
    closedir(DIR);
    if (exists($opt->{'dir'}))
    { if (ref($opt->{'dir'}) eq 'HASH')
      { @dir = sort grep {exists($opt->{'dir'}->{$_})} @tbl;
      }
      else
      { @dir = sort grep {m/^[^\.]/ && -d $cfg->cat_dir($top, $_)} @tbl;
      }
    }
    @pkg = sort grep {m/\Q$opt->{'ext'}\E$/i} @tbl;
    @pkg = sort grep {!m/$opt->{'skp'}$/i} @pkg if exists($opt->{'skp'});
  }
  else
  { $cur = 'dir';
    $pre = '';
    $opt = $tb_opt{'top'};
    $top = $cfg->get_group('D_RDA_PERL');
    $nam = 'rda_perl';
    $ttl = 'RDA Perl Directory';
    @dir = sort grep {-d $cfg->cat_dir($top, $_)} @{$opt->{'dir'}};
  }

  # Generate a dynamic POD file
  $buf = "=head1 NAME\n\n=over 16\n\n";
  $buf .= "=item o B<L<..|$par> > Parent Directory\n\n"
    if ($opt->{'par'} > 0) || ($opt->{'par'} < 0 && @sub);
  $req =~ s#/#::#g;
  foreach my $itm (@dir)
  { $buf .= exists($tb_ttl{$cls = $pre.lc($itm)})
      ? "=item o B<L<$itm|$cur/$itm> > ".$tb_ttl{$cls}."\n\n"
      : "=item o B<L<$itm|$cur/$itm> > F<$itm> Directory\n\n";
  }
  foreach my $itm (@pkg)
  { $cls = "$req\::$itm";
    $cls =~ s/\Q$opt->{'ext'}\E$//i;
    $cur = exists($opt->{'fil'}) ? $itm : $cls;
    $buf .= "=item o B<L<$cur|$typ$cls> > "
      .$cfg->get_title($top, $itm, "F<$cur>")
      ."\n\n";
  }
  $buf .= "=back\n\n";

  # Return the page definition
  ($nam, $ttl, [[$ttl, RDA::Handle::Memory->new($buf)]],
    exists($opt->{'rel'}) ? $opt->{'rel'} : $rel);
}

# Treat an engine help request
sub do_engine
{ my ($slf, $req, $rel) = @_;
  my ($dir, $grp, $fil, $nam, $opt);

  $req = 'RDA/Agent' unless $req;
  ($dir, $nam) = split(/\//, $req, 2);
  return () unless exists($tb_opt{$dir}) && $nam;
  $opt = $tb_opt{$dir};
  $fil = exists($opt->{'grp'})
    ? $slf->{'_cfg'}->get_file($opt->{'grp'}, $nam, $opt->{'ext'})
    : $slf->{'_cfg'}->get_file('D_RDA_PERL', $req, $opt->{'ext'});
  return () unless -r $fil;
  $nam = $req;
  $nam =~ s#/#::#g;
  ($nam, "Engine Documentation - $nam", [[$nam, $fil]], $rel);
}

# Treat an error explanation request
sub do_error
{ my ($slf, $req, $rel, $cnt) = @_;
  my ($rpt, $ttl, $txt, %qry);

  $ttl = 'Error Explanation';
  $rpt = ".R '$ttl'\n.Q error='Error Number: '\n";
  $rpt .= ($txt = $slf->{'_agt'}->get_display->explain($qry{'error'}))
    ? ".S\n$txt"
    : ".S\n.P\nError ``".$qry{'error'}."`` not found\n\n"
    if parse_query(\%qry, $cnt) && exists($qry{'error'});

  ('error', $ttl, [[$ttl, [\&_cat_report, RDA::Handle::Memory->new($rpt), $ttl,
    $slf->{'_col'}]]], $rel);
}

# Treat a HCVE help request
sub do_hcve
{ my ($slf, $req, $rel) = @_;
  my ($ifh, $pth, $ttl);

  # List available sets
  unless ($req)
  { my ($buf, $cfg);

    return () unless opendir(DIR, $slf->{'_cfg'}->get_group('D_RDA_HCVE'));

    # Generate a dynamic POD file
    $buf = "=head1 NAME\n\n=over 16\n\n";
    $ttl = "Available Rule Sets";
    foreach my $set (sort grep {m/\.xml$/i} readdir(DIR))
    { $set =~ s/\.xml$//i;
      $buf .= "=item o B<L<$set|hcve/$set> > "._get_hcve_title($slf, $set)
        ."\n\n";
    }
    $buf .= "=back\n\n";
    closedir(DIR);

    # Return the page definition
    return ('hcve', $ttl, [[$ttl, RDA::Handle::Memory->new($buf)]]);
  }

  # Display the rule set
  $ifh = IO::File->new;
  $pth = _get_hcve_man($slf, $req);
  return () unless $ifh->open("<$pth");
  $ttl = defined($ttl = _get_hcve_title($slf, $req))
    ? "Rule set $req / $ttl"
    : "Rule set $req";
  ($req, $ttl, [[$ttl, [\&_cat_html, $ifh]]], $rel);
}

# Treat a module help request
sub do_module
{ my ($slf, $req, $rel) = @_;
  my ($cfg, $fil, $nam);

  $cfg = $slf->{'_cfg'};
  unless ($req)
  { $fil = $cfg->get_file('D_RDA_POD', 'modules.pod');
    return () unless -r $fil;
    return ('module', 'Modules', [['Modules', $fil]], $rel);
  }
  return ()
    unless -r ($fil = $cfg->get_file('D_RDA_CODE', $req, '.def'))
    ||     -r ($fil = $cfg->get_file('D_RDA_CODE', $req, '.ctl'));
  $nam = $req;
  $nam =~ s/\.(ctl|def)$//i;
  ($nam, "Module Documentation - $nam", [[$nam, $fil]], $rel);
}

# Treat a multi-run collection help request
sub do_mrc
{ my ($slf, $req, $rel) = @_;

  # List available modules
  unless ($req)
  { my ($agt, $buf, $cfg, $ttl);

    return () unless opendir(DIR, $slf->{'_cfg'}->get_group('D_RDA_CODE'));

    # Generate a dynamic POD file
    $agt = $slf->{'_agt'};
    $buf = "=head1 NAME\n\n=over 16\n\n";
    $ttl = "Available Multi-run Collection Modules";
    foreach my $mod (sort grep {m/^M\d{3}[A-Z]\w*\.(ctl|def)$/i} readdir(DIR))
    { $mod =~ s/\.(ctl|def)$//i;
      $buf .= "=item o B<L<$mod|module/$mod> > ".$agt->get_title($mod)."\n\n";
    }
    $buf .= "=back\n\n";
    closedir(DIR);

    # Return the page definition
    return ('mrc', $ttl, [[$ttl, RDA::Handle::Memory->new($buf)]], $rel);
  }

  # Treat a group documentation request
  ($req, "Group - $req", [[$req, [\&_cat_report,
    RDA::Handle::Memory->new($slf->{'_agt'}->get_mrc->display($req, 1, 1)),
    $req, $slf->{'_col'}]]], $rel);
}

# Treat a profile help request
sub do_profile
{ my ($slf, $req, $rel) = @_;
  my ($fil);

  # Treat a profile documentation request
  return ($req, "Profile - $req", [[$req, [\&_cat_report,
    RDA::Handle::Memory->new($slf->{'_agt'}->get_profile->display($req, 1, 1)),
    $req, $slf->{'_col'}]]], $rel)
    if $req;

  # Treat a profile explanation request
  $fil = $slf->{'_cfg'}->get_file('D_RDA_POD', 'profiles.pod');
  return () unless -r $fil;
  ('profile', 'Profiles', [['Profiles', $fil]], $rel);
}

# Treat a RDA manual page help request
sub do_rda
{ my ($slf) = @_;
  my ($fil);

  $fil = $slf->{'_cfg'}->get_file('D_RDA_POD', 'rda.pod');
  return () unless -r $fil;
  ('rda_man', 'RDA Manual Page', [['RDA Manual Page', $fil]]);
}

# Treat a setup help request
sub do_setup
{ my ($slf, $req, $rel, $cnt) = @_;
  my ($agt, $all, $buf, $cfg, $lnk, $nam, $tbl, $ttl, $txt, @mod);

  $agt = $slf->{'_agt'};
  $cfg = $slf->{'_cfg'};
  $req = 'list/dm' unless $req;
  if ($req eq 'list/dm')
  { $nam = 'setup_list_dm';
    $ttl = 'Data Collection Module Setup';
    $tbl = $cfg->get_modules;
    @mod = sort {$tbl->{$a} cmp $tbl->{$b}} keys(%$tbl);
  }
  elsif ($req eq 'list/tl')
  { $nam = 'setup_list_tl';
    $ttl = 'Tools Setup';
    $tbl = $cfg->get_tests(1);
    @mod = sort grep {$cfg->is_tool($_)} keys(%$tbl);
  }
  elsif ($req eq 'list/tm')
  { $nam = 'setup_list_tm';
    $ttl = 'Test Module Setup';
    $tbl = $cfg->get_tests(1);
    @mod = sort grep {!$cfg->is_tool($_)} keys(%$tbl);
  }
  elsif ($req)
  { $nam = $cfg->get_module($req);
    if ($cnt)
    { foreach my $arg (split(/&/, $cnt))
      { $all = $1 if $arg =~ m/^all=(.*)$/;
      }
    }
    return ($nam, "Setup Questions - $nam", [[$nam, [\&_cat_report,
      RDA::Handle::Memory->new($agt->dsp_module($nam, $all, 1)), $nam,
      $slf->{'_col'}]]], $rel);
  }
  else
  { return ();
  }
  $buf = "=head1 NAME\n\n=over 16\n\n";
  foreach my $mod (@mod)
  { $buf .= "=item o B<L<$lnk|setup/$mod> > $txt\n\n"
      if ($lnk = $tbl->{$mod} || $mod) && ($txt = $agt->get_title($mod));
  }
  $buf .= "=back\n\n";
  ($nam, $ttl, [[$ttl, RDA::Handle::Memory->new($buf)]], $rel);
}

# Treat a text file display request
sub do_text
{ my ($slf, $req, $rel) = @_;
  my ($ifh, $ttl);

  $ifh = IO::File->new;
  return () unless $req
    && $ifh->open('<'.$slf->{'_cfg'}->get_file('D_RDA', $req, '.txt'));
  $ttl = "$req.txt File";

  ($req, $ttl, [[$req, [\&_cat_file, $ifh, $ttl]]], $rel);
}

# Treat a cross reference request
sub do_xref
{ my ($slf, $req, $rel) = @_;
  my ($nam, $rpt, $ttl, $typ);

  return () unless $req;
  ($typ, $nam) = split(/\//, $req, 2);

  if ($typ eq 'cfg')
  { $rpt = ($nam eq 'rda')
      ? $slf->{'_agt'}->get_profile->load($slf->{'_cfg'}->get_file('D_RDA_DATA',
          $nam, '.cfg'))->xref :
    ($nam eq 'convert')
      ? $slf->{'_agt'}->get_convert->load($slf->{'_cfg'}->get_file('D_RDA_DATA',
          $nam, '.cfg'))->xref :
        RDA::Module->new($nam,
          $slf->{'_cfg'}->get_group('D_RDA_CODE'))->xref($slf->{'_agt'});
    $ttl = "$nam Cross Reference";
    $nam = "xref_cfg_$nam";
  }
  elsif ($typ eq 'cnv')
  { $rpt = $slf->{'_agt'}->get_convert->load->xref;
    $ttl = 'Conversion Group Cross Reference';
    $nam = 'xref_cnv';
  }
  elsif ($typ eq 'def')
  { $rpt = RDA::Block->new($nam,
      $slf->{'_cfg'}->get_group('D_RDA_CODE'))->xref($slf->{'_agt'});
    $ttl = "$nam Cross Reference";
    $nam = "xref_cfg_$nam";
  }
  elsif ($typ eq 'group')
  { $rpt = $slf->{'_agt'}->get_mrc->xref;
    $ttl = 'Multi-run Collection Group Cross Reference';
    $nam = 'xref_mrc';
    $rel = $tb_mrc;
  }
  elsif ($typ eq 'mrc')
  { $rpt = $slf->{'_agt'}->get_mrc->xref;
    $ttl = 'Multi-run Collection Cross Reference';
    $nam = 'xref_mrc';
  }
  elsif ($typ eq 'obj')
  { $nam =~ s#/#::#g;
    $rpt = RDA::Object::xref($nam);
    $ttl = "$nam SDCL Object Reference";
    $nam =~ s#::#_#g;
    $nam = 'xref_'.lc($nam);
  }
  elsif ($typ eq 'prf')
  { $rpt = $slf->{'_agt'}->get_profile->load->xref;
    $ttl = 'Profile Cross Reference';
    $nam = 'xref_prf';
  }
  elsif ($typ eq 'profile')
  { $rpt = $slf->{'_agt'}->get_profile->load->xref;
    $ttl = 'Profile Cross Reference';
    $nam = 'xref_prf';
    $rel = $tb_prf;
  }
  else
  { return ();
  }

  ($nam, $ttl, [[$nam, [\&_cat_report, RDA::Handle::Memory->new($rpt), $ttl,
    $slf->{'_col'}]]], $rel);
}

# --- Internal routines -------------------------------------------------------

# Insert a file
sub _cat_file
{ my ($ofh, $ifh, $ttl) = @_;
  my ($buf);

  $buf = defined($ttl) ? "<h1>$ttl</h1><pre>\n" : "<pre>\n";
  syswrite($ofh, $buf, length($buf));
  while (defined($buf = $ifh->getline))
  { $buf =~ s/&/&amp;/g;
    $buf =~ s/</&lt;/g;
    $buf =~ s/>/&gt;/g;
    $buf =~ s#(https?://\S+)#<a href='$1' target='_blank'>$1</a>#;
    syswrite($ofh, $buf, length($buf));
  }
  $buf = "</pre>\n";
  syswrite($ofh, $buf, length($buf));
  $ifh->close;
}

# Insert a HTML file
sub _cat_html
{ my ($ofh, $ifh) = @_;
  my ($lin);

  # Skip the head section
  for (;;)
  { return unless defined($lin = $ifh->getline);
    last if $lin =~ m/\<body\>/i;
  }

  # Transfer the HTML code
  $lin = "<div class='rda_report'>\n";
  for (;;)
  { syswrite($ofh, $lin, length($lin));
    return unless defined($lin = $ifh->getline);
    $lin =~ s#\<\/body\>.*##i;
  }
  $ifh->close;
}

# Insert a RDA report
sub _cat_report
{ my ($ofh, $ifh, $nam, $wdt) = @_;
  my ($buf, $flg, $pr1, $pr2);
 
  while (<$ifh>)
  { if (m/^.I\s*'(.*)'(\s+(\d+))?$/)
    { $buf = '';
      $buf .= "<table summary='' width='100%'>\n" unless $flg++;
      ($pr1, $pr2) = split(/\001/, $1, 2);
      if (defined($pr2))
      { $buf .= "<tr><td width='1%' style='white-space:nowrap'>"
          ._encode_prefix($pr1)
          ."</td><td width='1%' style='white-space:nowrap'>"
          ._encode_prefix($pr2)
          ."</td><td>"._encode_block($ifh)."</td><td></td></tr>\n";
      }
      else
      { $buf .= "<tr><td width='1%' style='white-space:nowrap'>"
          ._encode_prefix($pr1)
          ."</td><td colspan='3'>"._encode_block($ifh)."</td></tr>\n";
      }
      if (defined($3) && $3 > 1)
      { $buf .= "</table>\n";
        $flg = 0;
      }
    }
    else
    { if ($flg)
      { $buf = "</table>\n";
        syswrite($ofh, $buf, length($buf));
        $flg = 0;
      }
      if (m/^.C(\s*(\d+))?$/)
      { $buf = _encode_columns($ifh, $wdt, $2);
      }
      elsif (m/^.N\s*(\d+)$/)
      { next;
      }
      elsif (m/^.P(\s*(\d+))?$/)
      { $buf = "<p>"._encode_block($ifh)."</p>\n";
      }
      elsif (m/^.Q\s*(\w+)='(.*)'$/)
      { $buf = "<form action='' method='GET'>"
           ."<label for='$1'>$2</label><input type='text' id='$1' name='$1'>"
           ."&nbsp;&nbsp;<button type=submit>Explain</button>"
           ."</form>\n";
      }
      elsif (m/^.R\s*'(.*)'$/)
      { $buf = "<h1>$1</h1>\n";
      }
      elsif (m/^.S$/)
      { $buf = "<hr \>\n";
      }
      elsif (m/^.T\s*'(.*)'$/)
      { $buf = ($nam && $1 eq 'NAME')
          ? "<h1><a id='$nam' name='$nam'>$nam</a></h1>\n"
          : "<h2>$1</h2>\n";
      }
      else
      { $buf = "<p>$_</p>\n";
      }
    }
    syswrite($ofh, $buf, length($buf));
  }
  if ($flg)
  { $buf = "</table>\n";
    syswrite($ofh, $buf, length($buf));
  }
  $ifh->close;
}

sub _encode_block
{ local $/ = '';  # Treat multiple empty lines as a single empty line
  my $lin = _encode_string(shift->getline);
  $lin =~ s#\n#<br/>#g;
  $lin;
}

sub _encode_columns
{ my ($ifh, $wdt, $sep) = @_;
  my ($buf, $cnt, $col, $lgt, $lin, $max, $pre, $txt, @tbl);

  $buf = '';
  $cnt = $max = 0;
  $sep = 0 unless defined($sep);
  while (defined($lin = $ifh->getline))
  { last if $lin =~ m/^$/;
    push(@tbl, $lin);
    $lin =~ s/\001//;
    $lin =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
    $max = $lgt if ($lgt = length($lin)) > $max;
    ++$cnt;
  }
  if ($max && ($col = int($wdt / ($max + $sep))))
  { for (; $cnt % $col ; ++$cnt)
    { push(@tbl, '');
    }
    $lgt = $cnt / $col;
  }
  if ($col > 1)
  { $sep = '&nbsp;'x$sep;
    for (my $row = 0 ; $row < $lgt ; ++$row)
    { $buf .= "<tr>\n";
      for (my $off = $row ;  $off < $cnt ; $off += $lgt)
      { $txt = $tbl[$off];
        $txt =~ s/\001//;
        $txt =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
        $buf .= "<td width='1%' style='white-space:nowrap'>$sep</td><td>"
          ._encode_string($txt)."</td>";
      }
      $buf .= "</tr>\n";
    }
  }
  else
  { foreach $lin (@tbl)
    { ($pre, $txt) = split(/\001/, $lin, 2);
      $buf .= defined($txt)
        ? "<tr><td width='1%' style='white-space:nowrap'>"
             ._encode_prefix($pre)
             ."</td><td width='1%' style='white-space:nowrap'>"
             ._encode_string($txt)
             ."</td><td></td></tr>\n"
        : "<tr><td colspan='3'>"._encode_string($pre)."</td></tr>\n";
    }
  }
  $buf ? "<table summary='' width='100%'>$buf</table>" : '';
}

sub _encode_link
{ my ($typ, $lnk, $txt) = @_;

  exists($tb_typ{$typ})
    ? "<a href='".$tb_typ{$typ}.$lnk."'>$txt</a>"
    : "<code>$txt</code>";
}

sub _encode_prefix
{ my ($str) = @_;

  $str =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
  $str =~ s/\s/\240/g;
  $str = _encode_style(RDA::Object::Sgml::encode($str));
  $str =~ s/^((&nbsp;)*)[o\*\-]((&nbsp;)*)$/$1&middot;$3/;
  $str; 
}

sub _encode_string
{ my ($str) = @_;

  $str =~ s/[\n\r\s]+$//;
  $str =~ s/\\([0-7]{3}|0x[0-9A-Fa-f]{2})/chr(oct($1))/eg;
  _encode_style(RDA::Object::Sgml::encode($str));
}

sub _encode_style
{ my ($str) = @_;

  $str =~ s#``(.*?)``#<code>$1</code>#g;
  $str =~ s#~~(.*?)~~#<em>$1</em>#g;
  $str =~ s#\*\*(.*?)\*\*#<strong>$1</strong>#g;
  $str =~ s#\!\!(\w+):(.*?)\!(.*?)\!\!#_encode_link($1, $2, $3)#eg;
  $str;
}

# Format links
sub _fmt_link
{ my ($txt, $url) = @_;
  my ($typ);

  $url =~ s#::#/#g;
  ($typ, $url) = split(/\//, $url, 2);
  return exists($tb_typ{$typ})
    ? "\001a href='".$tb_typ{$typ}.$url."'\002$txt\001/a\002"
    : "\001code\002$txt\001/code\002"
    if defined($url);
  return exists($tb_lnk{$typ})
    ? "\001a href='".$tb_lnk{$typ}."'\002$txt\001/a\002"
    : "\001code\002$txt\001/code\002";
}

# Get the manual page of a rule set
sub _get_hcve_man
{ my ($slf, $set) = @_;
  my ($cmd, $lin, $pth, $tim, @sta);

  # Check for a file in cache
  if (exists($slf->{'_man'}->{$set}))
  { ($tim, $pth) = @{$slf->{'_man'}->{$set}};
    return $pth if _get_hcve_time($slf, $set) < $tim && -f $pth;
    delete($slf->{'_man'}->{$set});
  }

  # Check the existence of existing documentation
  $pth = RDA::Object::Rda->cat_file($slf->{'_dir'},
    $slf->{'_grp'}.'_HCVE_'.$set.'_man.htm');
  if (-f $pth && (@sta = stat($pth)) && _get_hcve_time($slf, $set) < $sta[9])
  { $slf->{'_man'}->{$set} = [$sta[9], $pth];
    return $pth;
  }

  # Generate the rule set documentation
  $cmd = $slf->{'_agt'}->get_setting('RDA_SELF').' -T M:hcve:'.$set;
  $tim = time;
  ($lin) = grep {m/description file: (.*)/} `$cmd`;
  return unless $lin =~ m/description file: (.*)/;
  $slf->{'_man'}->{$set} = [$tim, $1];
  return $1;
}

# Get the last modification date/time of a rule set
sub _get_hcve_time
{ my ($slf, $set) = @_;
  my (@sta);

  @sta = stat($slf->{'_cfg'}->get_file('D_RDA_HCVE', $set, '.xml'));
  $sta[9] || 0;
}

# Get the title of a rule set
sub _get_hcve_title
{ my ($slf, $set, $dft) = @_;
  my ($buf, $cnt, $pth, $ifh, $tim, $ttl);

  # Check for a title in cache
  if (exists($slf->{'_ttl'}->{$set}))
  { ($tim, $ttl) = @{$slf->{'_ttl'}->{$set}};
    return $ttl if _get_hcve_time($slf, $set) < $tim;
    delete($slf->{'_ttl'}->{$set});
  }

  # Extract the title
  $ifh = IO::File->new;
  $pth = $slf->{'_cfg'}->get_file('D_RDA_HCVE', $set, '.xml');
  if ($ifh->open("<$pth"))
  { $buf = '';
    $cnt = 10;
    while (<$ifh>)
    { $buf .= $_;
      $buf =~ s/[\n\r\s]*$/ /;
      if ($buf !~ m#<sdp_diaglet#)
      { $buf = '';
        last unless --$cnt;
      }
      elsif ($buf =~ m#<sdp_diaglet.*?>#)
      { $buf =~ s#.*<sdp_diaglet\s+##;
        while ($buf =~ s#^(\w+)\s*=\s*['"](.*?)['"]\s*##)
        { next unless $1 eq 'title';
          $ifh->close;
          $slf->{'_ttl'}->{$set} = [_get_hcve_time($slf, $set), $2];
          return $2;
        }
        last
      }
    }
    $ifh->close;
  }

  # Return the default title
  $ttl;
}

# Parse the query string
sub parse_query
{ my ($hsh, $qry) = @_;
  my ($cnt);

  if (defined($qry))
  { foreach my $arg (split(/\&/, $qry))
    { next unless $arg =~ m/^(\w+)=(.*)$/;
      $hsh->{$1} = $2;
      ++$cnt;
    }
  }
  $cnt;
}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Block|RDA::Block>,
L<RDA::Handle::Data|RDA::Handle::Data>,
L<RDA::Handle::Memory|RDA::Handle::Memory>,
L<RDA::Module|RDA::Module>,
L<RDA::Object|RDA::Object>,
L<RDA::Object::Display|RDA::Object::Display>,
L<RDA::Object::Mrc|RDA::Object::Mrc>,
L<RDA::Object::Pod|RDA::Object::Pod>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Sgml|RDA::Object::Sgml>,
L<RDA::Profile|RDA::Profile>,
L<RDA::Web|RDA::Web>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
