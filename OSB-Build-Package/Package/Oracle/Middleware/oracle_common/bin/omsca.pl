#!/usr/local/bin/perl
# 
# $Header: omsca.pl 14-apr-2008.18:49:25 rmaggarw Exp $
#
# omsca.pl
# 
# Copyright (c) 2008, Oracle. All rights reserved.  
#
#    NAME
#      omsca.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rmaggarw    03/19/08 - 
#    minfan      03/18/08 - 
#    rmaggarw    03/17/08 - creation
# 
use strict;
use POSIX;

$main::VERSION   = 'Enterprise Manager 11.0.0.2.0';
$main::COPYRIGHT = 'Copyright (c) 2007, 2008, Oracle. All rights reserved.  ';

sub displayHelp()
{
   print<<EOF_HELP
Usage:
omsca -config (fresh|upgrade|recovery) [-responseFile <path>]
EOF_HELP
;
   exit 2;
}

sub printHeader
{
    print <<EOF_HEADER
$main::VERSION
$main::COPYRIGHT
EOF_HEADER
;
}

sub getBaseClasspath
{
    my $classpath
        = join(":",
               "$main::oracleHome/sysman/jlib/emCORE.jar",
               "$main::oracleHome/sysman/jlib/emInstall.jar",
               "$main::oracleHome/sysman/jlib/emcore_client.jar",
               "$main::oracleHome/j2ee/home/lib/oc4j_mas.jar",
               "$main::oracleHome/emagent/lib/emagentSDK.jar",
               "$main::oracleHome/sysman/jlib/log4j-core.jar",
               "$main::oracleHome/lib/xml.jar",
               "$main::oracleHome/lib/xmlparserv2.jar",
               "$main::oracleHome/jlib/adminserver.jar",
               "$main::oracleHome/j2ee/home/lib/http_client.jar",
               "$main::oracleHome/j2ee/home/jps-mas.jar",
               "$main::oracleHome/j2ee/home/lib/jmxframework.jar",
               "$main::oracleHome/jlib/dms.jar",
               "$main::oracleHome/jlib/emConfigInstall.jar",
	       "$main::oracleHome/install/config/ASConfig.jar",
	       "$main::oracleHome/install/config/message.jar",
	       "$main::oracleHome/bin/internal/adfdconfigbeans.jar",
    );

    return $classpath;
}

sub execJava
{
    my ($classpath, $classname, @args) = @_;
    my $stat;

    $stat = system("$main::javaHome/bin/java", "-classpath", $classpath,
                   $classname, @args);

    # Exit code is returned value/256. Return the lowest byte after that
    exit (($stat >> 8) & 0xFF);
}

sub initVars
{
    unless (defined $ENV{JAVA_HOME}
            and defined $ENV{ORACLE_HOME})
    {
        print<<EOF_ERROR
Please set the following environment variables before executing this script:
    JAVA_HOME   - Location of Java (parent of bin directory)
    ORACLE_HOME - Location where Oracle is installed
EOF_ERROR
        ;
        exit 1;
    }

    $main::javaHome   = $ENV{JAVA_HOME};
    $main::oracleHome = $ENV{ORACLE_HOME};

    # Set path so that our native executables can be found when run from java
    $ENV{PATH} = qq($main::oracleHome/bin:$ENV{PATH});
}

&initVars;
&printHeader;

my @args = @ARGV;

#shift out -config
shift @args;

my $installtype = (shift @args or "");

displayHelp unless ($installtype eq "fresh" or $installtype eq "upgrade" or $installtype eq "recovery");

my $instType = "";

if ($installtype eq "fresh")
{
    $instType = "FRESH_INSTALL";
}
elsif ($installtype eq "upgrade") 
{
    $instType = "UPGRADE_OUT_OF_PLACE_INSTALL";
}
elsif ($installtype eq "recovery") 
{
    $instType = "RECOVERY_INSTALL";
}

my $installprops = "";

if (defined $args[0] and $args[0] eq "-responseFile")
{
    displayHelp unless ($#args >= 1);
    shift @args;
    $installprops = shift @args;

    execJava(getBaseClasspath(),
          "oracle.sysman.omsca.util.CoreOMSConfigAssistantCmdline",
          $instType, "emgc", $installprops);
}
else
{
    execJava(getBaseClasspath(),
          "oracle.sysman.omsca.util.CoreOMSConfigAssistantCmdline",
          $instType, "emgc");
}
