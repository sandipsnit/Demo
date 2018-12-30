#Author: Kondayya Duvvuri
#Date Created: 05/05/2004
#Handles secure and getemhome options of emctl for agent.
#Revision History:
#  kduvvuri  - 05/07/2004 -- add ilint.
#  shianand  - 03/31/2005 -- Refactoring Secure Commands.
#  skuchero  - 07/17/2006 -- fix ilint.
#  sunagarw  - 11/04/2008 -- add annotateconfigfiles.
#  bkovuri   - 11/16/2008 -- backport njagathe_secure_agent_in_emagent

package AgentMisc;
use EmctlCommon;
use EmCommonCmdDriver;
use English;
use File::stat;
use File::Copy;

sub new {
  my $classname = shift;
  my $self = {};
  bless ( $self, $classname );
  return $self;
}
sub doIT {
  my $classname = shift;
  my $rargs = shift;
  my $result = 0;
  my $argCount = @$rargs;

  if( $argCount == 0 )
  {
    return 2;  #UNKNOWN_CMD
  }
  
  if ( $rargs->[0] eq "getemhome" )
  {
    print "EMHOME=$ENV{EMHOME}\n";
  }
  elsif( $rargs->[0] eq "ilint")
  {
    runILINT($rargs);
  }
  elsif(($rargs->[0] eq "annotateconfigfiles") and ($rargs->[1] eq "agent"))
  {
    annotateconfigfiles($rargs);
  }
  else
  {
    my $found = 0;

    if ( $rargs->[1] eq "agent" )
    {
      $found = runExternalCmd($rargs); 
    }

    if ($found == 0)
    {
      $result = $EMCTL_UNK_CMD;
    }
  }
  return $result;
}


sub usage
{
  print "        emctl getemhome\n";
  print "        emctl ilint\n";
  print "        emctl annotateconfigfiles agent [<template files dir> <config files dir>]\n";
  
}

#
# get the perl script that runs
#
sub runExternalCmd()
{
  local (*args) = @_;

  my $found = 0;
  
  open(AGENTMISCMDS, "<$EMDROOT/bin/AgentMiscCmds") ||
                 return $found;
 
  while (my $cmdline = <AGENTMISCMDS> )
  {
    if ($cmdline =~ /^$args[0],/ )
    {
      $cmdline =~ s/^$args[0],//;
      chomp($cmdline);
      $found = 1;
  
      @remArgs = @args[2 .. $#args];
      my $rc = 0xffff && system("$ENV{PERL_BIN}/perl $cmdline @remArgs"); 
      $rc >>= 8;

      if( $rc < 0 )
      {
        print stderr "Failed to execute $cmdline\n";
        close(AGENTMISCMDS);
        exit -1;
      }
      last;
    }
  }
  close(AGENTMISCMDS);

  return $found; 
}

#
# runILINT takes
# 1) Array of arguments
#
# ILINT performs static validation of the XML metadata:
# target, instance, and collection.

sub runILINT()
{
  use File::Spec qw( tmpdir );

  local (*args) = @_;

  die "Missing ilint executable"
     if (! -e "$EMDROOT/bin/nmei"."$binExt");

  # ilint requires that T_WORK env variable is set
  if (not defined $ENV{T_WORK})
  {
    $ENV{T_WORK} = File::Spec->tmpdir(); # /tmp on Linux, C:\TEMP on Windows
  }

  shift(@args); # -- shift out ilint...

  my $rc = 0xffff & system ("$EMDROOT/bin/nmei -e @args"); # ilint <args>
  $rc >>= 8;
  exit $rc;
}

#
# annotateconfigfiles takes
# 1) Array of arguments
#
# This subroutine creates emd.properties of versions older than 10.2.0.4
# from emd.properties.template of newer versions

sub annotateconfigfiles()
{
  local (*args) = @_;

  my $templateDir = "";
  my $inputfileDir = "";

  #if input directories are not available then assume defaults
  if(scalar(@args)<4)
  {
    $templateDir=$ENV{ORACLE_HOME}."/sysman/config/";
    $inputfileDir=$ENV{EMHOME}."/sysman/config/";
    print "Template and input config files directories are not provided as inputs, assuming default values.\n";
    print "Template Dir (Oracle Home) = $templateDir\n";
    print "Input Dir (Agent State Dir) = $inputfileDir\n\n";
  }
  else
  {
    shift(@args); # -- shift out annotateconfigfiles...
    shift(@args); # -- shift out agent...
    $templateDir = $args[0];
    $inputfileDir = $args[1];
  }

  my @configfiles = ("emd.properties", "emagentlogging.properties");
  my $configcount = scalar(@configfiles);


  for(my $j=0;$j<$configcount;$j++)
  {
    my $template = $templateDir."$configfiles[$j].template";
    my $inputfile = $inputfileDir."$configfiles[$j]";

    my $ifileperm = getFilePermission($inputfile);

    #Open the template file.
    open (TEMPFILE,"<$template") or die "Unable to read $template: $! \n";

    #Back up the original input file.
    print "\nFixing configuration file $inputfile\n";
    print "Copying the original file $inputfile to $inputfile.ORIG \n";
    copy("$inputfile","$inputfile.ORIG") or
             die "Unable to copy $inputfile to $inputfile.ORIG: $!";

    #open the file to write.
    open (CONFIGFILE,">$inputfile.bak") or die "Unable to write $inputfile: $! \n";

    #open the backupfile to read input from.
    open (ORIGFILE,"<$inputfile.ORIG") or die "Unable to read $inputfile.ORIG: $! \n";

    my @fileinput = <ORIGFILE>;
    while (<TEMPFILE>)
    {
      my $found = 0;
      if(/^#@/) #Copy all annotations as it is.
      {
        print CONFIGFILE;
        next;
      }
      elsif(/=/) #these are properties.
      {
        my($propName, $propVal) = split(/=/, $_);
        if (/^#/) #incase it is a commented property
        {
          my($prop1, $prop2) = split(/#/, $propName);
          $propName = $prop2;
        }
        elsif (/REPOSITORY_URL=/) #special case req. for REPOS_URL
        {
          $propName = "REPOSITORY_URL";
        }
        $propName = $propName."=";

        #check thru all the properties in the input file
        #and print the one that is matching.
        my $count = scalar(@fileinput);
        for(my $i=0;$i < $count; $i++)
        {
          if($fileinput[$i] =~ /$propName/)
          {
            print CONFIGFILE $fileinput[$i];
            $found = 1;
            #set to empty as we need to dump all non-empty properties at the end.
            $fileinput[$i] = "";
            last;
          }
        }
        if($found == 0) #print all properties not found in input.
        {
          print CONFIGFILE; 
        }
      }
      else #print all other lines and comments.
      {
        print CONFIGFILE; 
      }
    }

    #add all remaining input properties at the end.
    print CONFIGFILE "\n";
    print CONFIGFILE "\#\@description=Miscellaneous\n";
    print CONFIGFILE "\#\@valueType=String\n";
    print CONFIGFILE "\#\@modifiable=true\n";
    print CONFIGFILE "\#\@LOV=\n";
    print CONFIGFILE "\#\@default=\n";
    for(my $i=0;$i < scalar(@fileinput); $i++)
    {
      if($fileinput[$i] =~ /=/)
      {
        print CONFIGFILE $fileinput[$i];
      }
    }
    close ORIGFILE;
    close TEMPFILE;
    close CONFIGFILE;

    #Copy new created file to properties file.
    print "Copying $inputfile.bak to $inputfile \n";
    copy("$inputfile.bak","$inputfile") or
             die "Unable to copy $inputfile.bak to $inputfile: $!";
    unlink "$inputfile.bak";

    #restore permissions for the file
    restoreFilePermissions($ifileperm, "$inputfile");
  }
  #end of for
}
#end annotateconfigfiles

1;
