# $Header: emagent/scripts/unix/EMDeploy.pm /st_emagent_10.2.0.5.3as11/1 2009/03/05 20:46:17 qding Exp $
#
# Copyright (c) 2001, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      EMDeploy.pm - Perl Module to deploy state-only installs
#
#    DESCRIPTION
#       This script creates state-only installs from full-install agents
#
#    MODIFIED   (MM/DD/YY)
#    qding       03/05/09 - file permission on emctl and emtgtctl
#    danili      01/14/09 - Backport danili_bug-7702704 from main
#    danili      01/14/09 - 7702704: chmod 0755 emstate/bin directory
#    nigandhi    01/08/09 - Bug 7696444: changing permissions on emd.properties
#    sunagarw    12/22/08 - Replace REPOSITORY_URL even if it is commented.
#    danili      09/09/08 - XbranchMerge danili_stateman_dumpreader from main
#    danili      09/09/08 - Add sysman/dump
#    sunagarw    08/14/08 - include option to read install pwd from stdin
#    sunagarw    08/01/08 - XbranchMerge njagathe_windows_non_service_start
#                           from main
#    sunagarw    07/24/08 - Fix deploy to accept oms host:port
#    rajverma    06/06/08 - copy emagent_storage.config to state dir.
#    nigandhi    06/06/08 - XbranchMerge nigandhi_lrg-3426127 from main
#    sunagarw    03/09/08 - Backport sunagarw_bug-6781479 from main
#    danili      03/30/08 - Add nmosudo to state directory
#    yma         09/14/07 - XbranchMerge yma_bug-3676098 from
#                           st_emagent_10.2.0.3.1db11
#    manaraya    09/05/07 - Bug 3676098:Recover the fix
#    vivsharm    05/08/06 - fix for emdbsa racMode
#    vnukal      04/12/06 - copying classpath.lst 
#    vnukal      12/13/05 - Backport vnukal_bug-4653796 from main 
#    vnukal      11/21/05 - copying monwallet directory: Bug 4653796 
#    njagathe    09/08/05 - Don't modify REPOSITORY_URL and emdWalletSrcUrl if 
#                           not in racMode 
#    kduvvuri    08/05/05 - fix 4524126. 
#    vnukal      07/13/05 - desupporting /net base deploys 
#    aaitghez    04/12/05 - remove lib link creation in deployed home 
#    aaitghez    03/09/05 - change creatin of emd.properties 
#    vnukal      02/28/05 - changing WINDIR to SystemRoot 
#    njagathe    12/14/04 - Only symlink lib if in agent deploy mode 
#    njagathe    12/09/04 - Create link back to source oracle_home/lib 
#    asawant     11/08/04 - Adding ORACLE_HOSTNAME for NT services 
#    vnukal      03/02/04 - cr comments 
#    vnukal      03/02/04 - escaping spaces with quotes 
#    vnukal      02/12/04 - Patternizing replaceEMDRoot 
#    vnukal      01/12/04 - registry creation script NT4.0 compatible 
#    vnukal      12/30/03 - permission bits for targets.xml 
#    mbhoopat    12/18/03 - Fix bug 3328281 
#    vnukal      12/11/03 - forward slashes emomslogging.properties 
#    vnukal      12/08/03 - adding emdRepServer 
#    vnukal      12/05/03 - adding dependancy to OracleService 
#    vnukal      12/01/03 - creating service for DBConsole 
#    vnukal      11/19/03 - adding emtgtctl 
#    vnukal      11/14/03 - NFS install changes 
#    njagathe    10/29/03 - Allowing for REMOTE_EMDROOT override 
#    vnukal      10/22/03 - servicename not mandatory for dbconsole deploy 
#    vnukal      10/16/03 - vnukal_bug-3076576 
#    vnukal      10/15/03 - adding b64InternetCertificate and OUIinventories 
#    vnukal      10/13/03 - fix substitution issue 
#    vnukal      10/08/03 - Initial version
#
package EMDeploy;
use strict;
use EmctlCommon;
use LWP::Simple;
use File::Copy;
use File::Temp qw/ tempfile /;

sub new
{
  my ($class) = @_;
  my $self = {
      mode => "agent",
      StateDir => "",
      localHost => "",
      sid => "",
      sourceEMDROOT => "",
      replaceEMDROOT => "",
      installPassword => "",
      NtServiceName => "",
      NtServiceUserName => "",
      NtServicePassword => "",
      omsHostPort => "",
      readPwdInStdin => "",
      batchFileCreate => 0
  };
  bless $self, $class;
  return $self;
}

#
# doDeploy
#
sub doDeploy
{
    my $self = shift;
    my $mode = shift;
    $self->{StateDir} = shift; # directory to install state files
    $self->{hostPort} = shift; # host-port combination to insert in EMD_URL
    $self->{localHost} = shift; # host where EM was 'oui'nstalled. 
	                        # Used as a replacement target
    $self->{sid} = shift; # SID : used in dbconsole deploys
    $self->{sourceEMDROOT} = shift;
    $self->{replaceEMDROOT} = shift;
    $self->{installPassword} = shift;
    $self->{NtServiceName} = shift;
    $self->{NtServiceUserName} = shift;
    $self->{NtServicePassword} = shift;
    $self->{omsHostPort} = shift;
    $self->{readPwdInStdin} = shift;
    $self->{batchFileCreate} = shift;

    if ($self->{NtServiceName} eq "" )
    {
	$self->{NtServiceName} = "NOSERVICE";
    }

    $self->{racMode} = $mode ne "agent"; # determines deploy mode (agent or db)

    print "Creating shared install...\n";
    print "Source location: $self->{sourceEMDROOT}\n";
    print "Destination (shared install) : $self->{StateDir}\n";
    print "DeployMode : $mode\n\n";

    if($IS_WINDOWS eq "TRUE")
    {
	# make the replaceEMDROOT a search pattern which matches a path
	# with either '/' or '\' 
	# For e.g.
	# c:\oracle\em_1 => c:[\\/]oracle[\\/]em_1
	# c:/oracle\em_1 => c:[\\/]oracle[\\/]em_1

	$self->{replaceEMDROOT} =~ s/[\/\\]/\[\\\\\/\]/g;
    }

    if($self->{readPwdInStdin})
    {
      print "Reading Password from STDIN...\n";
      $self->{installPassword} = <STDIN>;
      chomp ($self->{installPassword});
    }

    $self->createDirs();

    #TODO validate port to be number
    my ($hostname, $port)  = split /:/, $self->{hostPort};

    if(!$self->{racMode})  
    {
	$self->createTargetsXml($hostname);
	$self->createEmctlScript();
	$self->createTgtCtlScript();
    }
    else
    {
	$self->createEMConfigFiles($hostname);
    }

    my $secureMode = $self->createAgentConfigFiles($hostname);

    if ($secureMode==1 || $self->{readPwdInStdin}==1) 
    {
	print "\nSource Agent operating in secure mode.\n";
	if($self->{installPassword} ne "") 
	{
	    print  "Securing shared agent ... \n";
	    system("$self->{StateDir}/bin/emctl secure agent $self->{installPassword}");
	}
	else 
	{
	    print "Run \"$self->{StateDir}/bin/emctl secure agent\" to secure agent\n";
	}
    }

    if($IS_WINDOWS eq "TRUE")
    {
	$self->createNtService();
    }

    return 0;
}
  
sub createDirs
{
  my($self) = @_;

    # Create directory structure underneath StateDir
    #
    # For AGENT_ONLY mode
    #
    # StateDir
    #   |-------bin
    #   |       |-------nmosudo (for non-windows platforms only)
    #   |       `-------emctl
    #   |
    #   `-------sysman
    #           |-------config 
    #           |       |-------emagentlogging.properties
    #           |       |-------b64InternetCertificate.txt
    #           |       |-------OUIinventories.add
    #           |       |-------classpath.lst
    #           |       `-------emd.properties
    #           |-------emd
    #           |       |-------collection
    #           |       |-------state
    #           |       |-------upload
    #           |       `-------targets.xml
    #           |-------log
    #           |-------dump
    #           `-------recv
 
    #
    # For DBConsole mode
    #
    # StateDir
    #   `-------sysman
    #        |-------config
    #        |       |-------b64InternetCertificate.txt
    #        |       |-------OUIinventories.add
    #        |       |-------classpath.lst
    #        |       |-------emagentlogging.properties
    #        |       |-------emd.properties
    #        |       |-------emoms.properties
    #        |       |-------emomsintg.xml
    #        |       `-------emomslogging.properties
    #        |-------emd
    #        |       |-------collection
    #        |       |-------state
    #        |       `-------upload
    #        |-------log
    #        |-------dump
    #        `-------recv
    #

    print "Creating directories...\n";
    -e "$self->{StateDir}" or mkdir "$self->{StateDir}" or 
	die "Unable to create $self->{StateDir}: $!\n";
    chmod 0755, "$self->{StateDir}";

    # emctl script gets generated in the bin directory when only the
    # agent is deployed.
    -e "$self->{StateDir}/bin" or mkdir "$self->{StateDir}/bin" or 
        die "Unable to create $self->{StateDir}/bin: $!\n";
    chmod 0755, "$self->{StateDir}/bin";
  
    if($IS_WINDOWS eq "FALSE")
    {
      copy("$self->{sourceEMDROOT}/bin/nmosudo", 
         "$self->{StateDir}/bin/nmosudo") or
             die "Unable to copy $self->{sourceEMDROOT}/bin/nmosudo to $self->{StateDir}/bin/nmosudo: $!";  
      chmod 0755, "$self->{StateDir}/bin/nmosudo";
    }

    -e "$self->{StateDir}/sysman" or mkdir "$self->{StateDir}/sysman" or 
	die "Unable to create $self->{StateDir}/sysman: $!\n";
    -e "$self->{StateDir}/sysman/config" or 
	mkdir "$self->{StateDir}/sysman/config" or 
	    die "Unable to create $self->{StateDir}/sysman/config: $!\n";
    -e "$self->{StateDir}/sysman/config/monwallet" or 
	mkdir "$self->{StateDir}/sysman/config/monwallet" or 
	    die "Unable to create $self->{StateDir}/sysman/config/monwallet: $!\n";
    -e "$self->{StateDir}/sysman/emd" or 
	mkdir "$self->{StateDir}/sysman/emd" or 
	    die "Unable to create $self->{StateDir}/sysman/emd: $!\n";
    -e "$self->{StateDir}/sysman/emd/collection" or 
	mkdir "$self->{StateDir}/sysman/emd/collection" or 
	    die "Unable to create $self->{StateDir}/sysman/collection: $!\n";
    -e "$self->{StateDir}/sysman/emd/upload" or 
	mkdir "$self->{StateDir}/sysman/emd/upload" 
	    or die "Unable to create $self->{StateDir}/sysman/upload: $!\n";
    -e "$self->{StateDir}/sysman/emd/state" or 
	mkdir "$self->{StateDir}/sysman/emd/state" 
	    or die "Unable to create $self->{StateDir}/sysman/state: $!\n";
    -e "$self->{StateDir}/sysman/log" or 
	mkdir "$self->{StateDir}/sysman/log" or 
	    die "Unable to create $self->{StateDir}/sysman/log: $!\n"; 
    -e "$self->{StateDir}/sysman/recv" or 
	mkdir "$self->{StateDir}/sysman/recv" or 
	    die "Unable to create $self->{StateDir}/sysman/recv: $!\n"; 
    -e "$self->{StateDir}/sysman/dump" or 
	mkdir "$self->{StateDir}/sysman/dump" or 
            die "Unable to create $self->{StateDir}/sysman/dump: $!\n"; 

  #
  # Properties file under $EMDROOT/sysman/config/
  #
  copy("$self->{sourceEMDROOT}/sysman/config/emagentlogging.properties", 
       "$self->{StateDir}/sysman/config/emagentlogging.properties.$$") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emagentlogging.properties to $self->{StateDir}/sysman/config/emagentlogging.properties.$$: $!";

  my $srcEmdRootPropPerm = getFilePermission("$self->{sourceEMDROOT}/sysman/config/emd.properties");

  copy("$self->{sourceEMDROOT}/sysman/config/emd.properties", 
       "$self->{StateDir}/sysman/config/emd.properties.$$") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emd.properties to $self->{StateDir}/sysman/config/emd.properties.$$: $!";

  #restore permissions on copy of emd.properties
  restoreFilePermissions($srcEmdRootPropPerm, "$self->{StateDir}/sysman/config/emd.properties.$$");

  copy("$self->{sourceEMDROOT}/sysman/config/OUIinventories.add", 
       "$self->{StateDir}/sysman/config/OUIinventories.add") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/OUIinventories.add to $self->{StateDir}/sysman/config/OUIinventories.add: $!";

  copy("$self->{sourceEMDROOT}/sysman/config/classpath.lst", 
       "$self->{StateDir}/sysman/config/classpath.lst") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/classpath.lst to $self->{StateDir}/sysman/config/classpath.lst: $!";

 copy("$self->{sourceEMDROOT}/sysman/emd/emagent_storage.config",
           "$self->{StateDir}/sysman/emd/emagent_storage.config") or
                die "Unable to copy $self->{sourceEMDROOT}/sysman/emd/emagent_storage.config to $self->{StateDir}/sysman/emd/emagent_storage.config: $!";

 chmod 0640, "$self->{StateDir}/sysman/emd/emagent_storage.config";

#
# Internet certificate list.
#
  copy("$self->{sourceEMDROOT}/sysman/config/b64InternetCertificate.txt", 
       "$self->{StateDir}/sysman/config/b64InternetCertificate.txt") or 
	   die "Unable to copy $self->{sourceEMDROOT}/sysman/config/b64InternetCertificate.txt to $self->{StateDir}/sysman/config/b64InternetCertificate.txt: $!";
  
#
# monwallet
#

  if(-e "$self->{sourceEMDROOT}/sysman/config/monwallet") {
    my $fname="";

    opendir(MONWALLET, "$self->{sourceEMDROOT}/sysman/config/monwallet") or
       die "Unable to open directory $self->{sourceEMDROOT}/sysman/config/monwallet: $!";
    while($fname = readdir(MONWALLET)) {
      next if ($fname =~ /^\./); #skip hidden files
      #skip directories
      next if (-d "$self->{sourceEMDROOT}/sysman/config/monwallet/$fname");
      copy("$self->{sourceEMDROOT}/sysman/config/monwallet/$fname",
	   "$self->{StateDir}/sysman/config/monwallet/$fname") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/monwallet/$fname to $self->{StateDir}/sysman/config/monwallet/$fname: $!";

    }
    closedir(MONWALLET);
  }
  
  if ($self->{racMode}) 
  {
    copy("$self->{sourceEMDROOT}/sysman/config/emomsintg.xml",
	 "$self->{StateDir}/sysman/config/emomsintg.xml") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emomsintg.xml to $self->{StateDir}/sysman/config/emomsintg.xml: $!";
    
copy("$self->{sourceEMDROOT}/sysman/config/emoms.properties", 
	 "$self->{StateDir}/sysman/config/emoms.properties.$$") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emoms.properties to $self->{StateDir}/sysman/config/emoms.properties.$$: $!";

    copy("$self->{sourceEMDROOT}/sysman/config/emomslogging.properties", 
	 "$self->{StateDir}/sysman/config/emomslogging.properties.$$") or 
	     die "Unable to copy $self->{sourceEMDROOT}/sysman/config/emomslogging.properties to $self->{StateDir}/sysman/config/emomslogging.properties.$$: $!";
  }
  return 0;
}

sub createTargetsXml
{
  my($self,$hostname) = @_;

  print "Creating targets.xml...\n";
  open (TARGETSXML,">$self->{StateDir}/sysman/emd/targets.xml") or 
      die "Unable to create $self->{StateDir}/sysman/emd/targets.xml\n";
    
  print TARGETSXML <<TARGETS;
<Targets>
<Target TYPE="host" NAME="$hostname" DISPLAY_NAME="$hostname"/>
</Targets>
TARGETS
    
    close TARGETSXML;
    chmod 0640, "$self->{StateDir}/sysman/emd/targets.xml";

  return 0;
}

sub createEmctlScript
{
  my($self) = @_;

  # Create a redirecter emctl script
  # The emctl calls into the root emctl after 
  # setting the StateDir and AGENTSTATE
  #
  print "Creating emctl control program...\n";
  if($IS_WINDOWS eq "TRUE")
  {
      open(EMCTLBATCH,">$self->{StateDir}/bin/emctl.bat") or 
	  die "Unable to create $self->{StateDir}/bin/emctl.bat: $!\n";
      
      print EMCTLBATCH <<HEADER;
\@echo off
REM ++
REM
REM  08-oct-03.15:38:56 vnukal   
REM
REM Copyright (c) 2002, 2009, Oracle and/or its affiliates.
REM All rights reserved. 
REM
REM  emctl - control script for state-only agent installs.
REM
REM    MODIFIED   (MM/DD/YY)
REM    vnukal       10/08/03 - Creation
REM --
setlocal
set REMOTE_EMDROOT=$self->{sourceEMDROOT}
set EMSTATE=$self->{StateDir}
set AGENT_SERVICE_NAME=$self->{NtServiceName}
$self->{sourceEMDROOT}/bin/emctl.bat \%*
endlocal
HEADER
    close EMCTLBATCH;
  }
  else
  {
      open(EMCTLSCRIPT,">$self->{StateDir}/bin/emctl") or 
	  die "Unable to create $self->{StateDir}/bin/emctl: $!\n";
      
      print EMCTLSCRIPT <<HEADER;
#!/bin/sh -f
#++
#
#  16-dec-02.15:38:56 vnukal   
#
# Copyright (c) 2002, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#  emctl - control script for state-only agent installs.
#
#    MODIFIED   (MM/DD/YY)
#    vnukal       12/16/02 - Creation
#--
REMOTE_EMDROOT=$self->{sourceEMDROOT}
export REMOTE_EMDROOT
EMSTATE=$self->{StateDir}
export EMSTATE
$self->{sourceEMDROOT}/bin/emctl \$*
HEADER
    close EMCTLSCRIPT;
      chmod 0700, "$self->{StateDir}/bin/emctl";
  }

  return 0;

}

sub createTgtCtlScript
{
  my($self) = @_;

  # Create a redirecter emtgtctl script
  # The emtgtctl script calls into the root OH
  # setting the StateDir and AGENTSTATE
  #
  print "Creating emtgtctl control program...\n";
  if($IS_WINDOWS eq "TRUE")
  {
      open(EMTGTCTLBATCH,">$self->{StateDir}/bin/emtgtctl.bat") or 
	  die "Unable to create $self->{StateDir}/bin/emtgtctl.bat: $!\n";
      
      print EMTGTCTLBATCH <<HEADER;
\@echo off
REM ++
REM
REM  19-nov-03.15:38:56 vnukal   
REM
REM Copyright (c) 2002, 2009, Oracle and/or its affiliates.
REM All rights reserved. 
REM
REM  emtgtctl - Redirector script for emtgtctl
REM
REM    MODIFIED   (MM/DD/YY)
REM    vnukal       11/19/03 - Creation
REM --
setlocal
set ORACLE_HOME=$self->{sourceEMDROOT}
set REMOTE_EMDROOT=$self->{sourceEMDROOT}
set EMSTATE=$self->{StateDir}
$self->{sourceEMDROOT}/bin/emtgtctl \%*
endlocal
HEADER
    close EMTGTCTLBATCH;
  }
  else
  {
      open(EMTGTCTLSCRIPT,">$self->{StateDir}/bin/emtgtctl") or 
	  die "Unable to create $self->{StateDir}/bin/emtgtctl: $!\n";
      
      print EMTGTCTLSCRIPT <<HEADER;
#!$self->{sourceEMDROOT}/perl/bin/perl
#++
#
#  19-nov-03.15:38:56 vnukal   
#
# Copyright (c) 2002, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#  emtgtctl - Redirector script for emtgtctl
#
#    MODIFIED   (MM/DD/YY)
#    vnukal       11/19/03 - Creation
#--
for(\$i = 3;\$i < 1024; \$i++)
{
    if (!open(TMPHANDLE, "<&=\$i")) {
        close(TMPHANDLE);
    }
}
\$ENV{"ORACLE_HOME"}="$self->{sourceEMDROOT}";
\$ENV{"REMOTE_EMDROOT"}="$self->{sourceEMDROOT}";
\$ENV{"EMSTATE"}="$self->{StateDir}";
exec("$self->{sourceEMDROOT}/bin/emtgtctl \@ARGV");
HEADER
    close EMTGTCTLSCRIPT;
      chmod 0750, "$self->{StateDir}/bin/emtgtctl";
  }

  return 0;

}

sub createEMConfigFiles
{
  my($self,$hostname) = @_;

  print "Setting console properties ... \n";
  open (OMSFILE, "<$self->{StateDir}/sysman/config/emoms.properties.$$")
      or die "Unable to read $self->{StateDir}/sysman/config/emoms.properties.$$: $!\n";
  open (OMSFILEBAK, ">$self->{StateDir}/sysman/config/emoms.properties")
      or die "Unable to write $self->{StateDir}/sysman/config/emoms.properties: $!\n";
  
  while (<OMSFILE>) {
      if(/ConsoleServerHost=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
	  
      if(/ConsoleServerName=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
      
      if(/repAgentUrl=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }

      if(/emdRepServer=/)
      {
      	  s/$self->{localHost}/$hostname/;
          print OMSFILEBAK;
          next;
      }

      if(/emdRepSID=/)
      {
	  my @line = split /=/;
	  print OMSFILEBAK $line[0]."=".$self->{sid}."\n";
	  next;
      }
      
      if(/isqlplusUrl=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
      if(/isqlplusWebDBAUrl=/)
      {
	  s/$self->{localHost}/$hostname/;
	  print OMSFILEBAK;
	  next;
      }
      print OMSFILEBAK;
  }
  
  close OMSFILE;
  close OMSFILEBAK;
  unlink "$self->{StateDir}/sysman/config/emoms.properties.$$";
  
  print "Setting log and trace files locations for Console ... \n";
  open (OMSLOGFILE, "<$self->{StateDir}/sysman/config/emomslogging.properties.$$")
      or die "Unable to read $self->{StateDir}/sysman/config/emomslogging.properties.$$: $!\n";
  open (OMSLOGFILEBAK, ">$self->{StateDir}/sysman/config/emomslogging.properties")
      or die "Unable to write $self->{StateDir}/sysman/config/emomslogging.properties: $!\n";
  
  while (<OMSLOGFILE>)
  {
      if(/File=/)
      {
          if($IS_WINDOWS eq "TRUE")
          {
              s/$self->{replaceEMDROOT}/$self->{StateDir}/i;
          }
          else
          {
              s/$self->{replaceEMDROOT}/$self->{StateDir}/;
          }
	  s/\\/\//g; # replace with forward slashes
	  print OMSLOGFILEBAK;
	  next;
      }
      
      print OMSLOGFILEBAK;
  }
  
  close OMSLOGFILE;
  close OMSLOGFILEBAK;
  unlink "$self->{StateDir}/sysman/config/emomslogging.properties.$$";
}

sub createAgentConfigFiles
{
    my($self, $hostname) = @_;

    print "Setting log and trace files locations for Agent ... \n";
    open (LOGFILE, 
	  "<$self->{StateDir}/sysman/config/emagentlogging.properties.$$") or 
	      die "Unable to read $self->{StateDir}/sysman/config/emagentlogging.properties.$$: $! \n";
      open (LOGFILEBAK, 
	    ">$self->{StateDir}/sysman/config/emagentlogging.properties") or 
		die "Unable to write $self->{StateDir}/sysman/config/emagentlogging.properties: $! \n";
      
    while (<LOGFILE>)
    {
	if(/File=/)
	{
            if($IS_WINDOWS eq "TRUE")
            {
                s/$self->{replaceEMDROOT}/$self->{StateDir}/i;
            }
            else
            {
                s/$self->{replaceEMDROOT}/$self->{StateDir}/;
            }
	    s/\\/\//g; # replace with forward slashes
	    print LOGFILEBAK;
	    next;
	}
	
	print LOGFILEBAK;
    }
    
    close LOGFILE;
    close LOGFILEBAK;
    unlink "$self->{StateDir}/sysman/config/emagentlogging.properties.$$";

    my $bakEmdPropPerm = getFilePermission("$self->{StateDir}/sysman/config/emd.properties.$$");

    open (PROPFILE, "<$self->{StateDir}/sysman/config/emd.properties.$$")
	or die "Unable to read $self->{StateDir}/sysman/config/emd.properties.$$: $!\n";
    
    open (PROPFILEBAK, ">$self->{StateDir}/sysman/config/emd.properties")
	or die "Unable to write $self->{StateDir}/sysman/config/emd.properties: $!\n";
    my $secureMode = 0;
    while (<PROPFILE>) {
        if($self->{racMode})
	{
            if (/^REPOSITORY_URL=/)
            {
                s/$self->{localHost}/$hostname/;
                print PROPFILEBAK;
                next;
            }
            elsif (/^emdWalletSrcUrl=/)
            {
                s/$self->{localHost}/$hostname/;
                print PROPFILEBAK;
                next;
            }
        }
        
	if ((/^REPOSITORY_URL=/) or (/^#REPOSITORY_URL=/) or (/^\%EM_UPLOAD_DISABLE\%REPOSITORY_URL=/))
        {
            if ($self->{omsHostPort} ne "" )
            {
                my ($header,$machine,$trailer) = split /:/;
                if ($header =~ /https$/)
                {
                    print "Secure REPOSITORY_URL found. New agent should be configured for secure mode\n";
                }
                $header=~s/https/http/;

                #Remove '#' if we have REPOSITORY URL as commented.
                $header=~s/\D*REPOSITORY_URL=/REPOSITORY_URL=/;

                print PROPFILEBAK $header,"://",$self->{omsHostPort},"/em/upload/\n";
                next;
            }
        }
        elsif (/^emdWalletSrcUrl=/)
        {
            if ($self->{omsHostPort} ne "" )
            {
                my ($header,$machine,$trailer) = split /:/;
                if ($header =~ /https$/)
                {
                    print "Secure emdWalletSrcUrl found. New agent should be configured for secure mode\n";
                }
                $header=~s/https/http/;
                print PROPFILEBAK $header,"://",$self->{omsHostPort},"/em/wallets/emd\n";
                next;
            }
        }
	elsif (/^EMD_URL=/) 
	{
	    my ($header,$machine,$trailer) = split /:/;
	    if ($header =~ /https$/) 
	    {
		print "Secure agent found. New agent should be configured for secure mode\n";
		$secureMode=1;
	    }
	      
	    print PROPFILEBAK $header,"://",$self->{hostPort},"/emd/main";
	    next;
	} elsif (/^agentStateDir=/)
	{
	    s/=.*/=$self->{StateDir}/;
	    s/\\/\//g; # replace with forward slashes
	    print PROPFILEBAK;
	    next;
	} elsif (/^chronosRoot=/) 
	{
	    s/=.*/=$self->{StateDir}\/sysman\/emd\/chronos/;
	    s/\\/\//g; # replace with forward slashes
	    print PROPFILEBAK;
	    next;
	} elsif (/^emdRootCertLoc=/)
	{
	    s/=.*/=$self->{StateDir}\/sysman\/config\/b64LocalCertificate.txt/;
	    s/\\/\//g; # replace with forward slashes
	    print PROPFILEBAK;
	    next;
	} elsif (/^internetCertLoc=/)
	{
	    s/=.*/=$self->{StateDir}\/sysman\/config\/b64InternetCertificate.txt/;
	    s/\\/\//g; # replace with forward slashes
	    print PROPFILEBAK;
	    next;
	} elsif (/^emdWalletDest/)
	{
	    s/=.*/=$self->{StateDir}\/sysman\/config\/server/;
	    s/\\/\//g; # replace with forward slashes
	    print PROPFILEBAK;
	    next;
	}

	print PROPFILEBAK;
    }
    close PROPFILE;
    close PROPFILEBAK;
    unlink "$self->{StateDir}/sysman/config/emd.properties.$$";

    #Bug 7696444: changing permission on emd.properties
    restoreFilePermissions($bakEmdPropPerm, "$self->{StateDir}/sysman/config/emd.properties");

    return $secureMode;
}

sub createNtService
{
    my($self) = @_;
    my($serviceName) = "";

    if($self->{racMode})
    {
	$serviceName = "OracleDBConsole".$self->{sid} 
    }
    else
    {
	# in agent deploy mode do not create NT service if one is 
	# not specified.
	if (($self->{NtServiceName} eq "") ||
	    ($self->{NtServiceName} eq "NOSERVICE"))
	{
	    return 1;
	}
	$serviceName = $self->{NtServiceName};
    }

    #Create service using 'nmesrvops' executable in EMDROOT/bin
    my @srvcargs = ($self->{sourceEMDROOT}."\\bin\\nmesrvops","create",
		    $serviceName,
		    "$self->{sourceEMDROOT}\\bin\\nmesrvc.exe",
		    "auto");

    if($self->{NtServiceUserName} ne "") 
    {
	push(@srvcargs,$self->{NtServiceUserName});
    }
    if($self->{NtServicePassword} ne "") 
    {
	push(@srvcargs,$self->{NtServicePassword});
    }

    # initialize deleteSrvcCmd for cleanup in case we encounter any errors
    my $deleteSrvcCmd = $self->{sourceEMDROOT}."\\bin\\nmesrvops delete ".$serviceName;

    my ($fh, $tmpfilename);

    if($self->{batchFileCreate})
    {
	print "Generating script for service creation...\n";

	($fh, $tmpfilename) = tempfile(DIR => $self->{StateDir});

	open (SRVCBATCH, ">$self->{StateDir}/CrtSrvc.bat") or
	    die "Unable to create $self->{StateDir}/CrtSrvc.bat\n";
	print SRVCBATCH "\@echo off\n";
	print SRVCBATCH "echo Creating service\n";
	foreach (@srvcargs) {
	    print SRVCBATCH "$_ ";
	}
	print SRVCBATCH "\n";
	print SRVCBATCH "\n";
	print SRVCBATCH "echo Creating service registry entries\n";
	print SRVCBATCH "\%SystemRoot\%\\regedit /s \"$tmpfilename\"\n";
	close SRVCBATCH;
    }
    else 
    {
	my ($rc) = 0xffff & system @srvcargs ;
	$rc >>= 8 ;

	die "Service creation failed. Aborting...\n" if($rc);

	($fh, $tmpfilename) = tempfile(UNLINK => 1, DIR => $self->{StateDir});
    }
    
    #Now create registry entries
    my ($escEMDROOT, $escORACLE_HOME, $escEMSTATE) = 
	($self->{sourceEMDROOT}, $ORACLE_HOME, $self->{StateDir});
    $escEMDROOT =~ s/\\/\\\\/g;
    $escORACLE_HOME =~ s/\\/\\\\/g;
    $escEMSTATE =~ s/\\/\\\\/g;
    
    print $fh "REGEDIT4\r\n\r\n";
    print $fh "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle\\SYSMAN\\$serviceName]\r\n";
    print $fh "\"EMDROOT\"=\"$escEMDROOT\"\r\n";
    print $fh "\"ORACLE_HOME\"=\"$escORACLE_HOME\"\r\n";
    print $fh "\"EMSTATE\"=\"$escEMSTATE\"\r\n";
    if($self->{racMode}) {
	print $fh "\"CONSOLE_CFG\"=\"dbconsole\"\r\n";
	print $fh "\"ORACLE_SID\"=\"$self->{sid}\"\r\n";
    }else {
	print $fh "\"CONSOLE_CFG\"=\"agent\"\r\n";
    }

    if(defined($ENV{ORACLE_HOSTNAME})) {
        print $fh "\"ORACLE_HOSTNAME\"=\"$ENV{ORACLE_HOSTNAME}\"\r\n";
    }

    print $fh "\"TIMEOUT\"=\"15\"\r\n";
    print $fh "\"TRACE_LEVEL\"=\"16\"\r\n\r\n";

    print $fh "[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Eventlog\\Application\\$serviceName]\r\n";
    print $fh "\"EventMessageFile\"=\"$escEMDROOT\\\\bin\\\\orasnmemsg.dll\"\r\n";
    print $fh "\"TypesSupported\"=dword:00000007\r\n";
	
    close $fh or warn "Error closing $tmpfilename. : $!\r\n";

    # call regedit only if not generating script.
    # /s is silent option to regedit
    if(not defined $self->{batchFileCreate})
    {
	# enclose tmpfilename in quotes to escape embedded spaces
	my($rc) = 0xffff & system("$ENV{SystemRoot}\\regedit.exe /s \"$tmpfilename\"");
	$rc >>= 8 ;
	if($rc) {
	    system $deleteSrvcCmd;
	    die "Creating registry entries failed. Aborting...\n";
	}
    }
}

1;



