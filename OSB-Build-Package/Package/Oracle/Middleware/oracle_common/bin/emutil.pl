#!/usr/local/bin/perl -w
# 
# $Header: emutil.pl 10-jan-2008.04:04:10 lsatyapr Exp $
#
# Copyright (c) 2007, 2008, Oracle. All rights reserved.  
#
# emutil.pl
# 
#    NAME
#      emutil.pl - Implementation of the emutil tool
#
#    DESCRIPTION
#      EMUtil tool to register job types and event types.
#
#    NOTES
#      The environment variables JAVA_HOME, ORACLE_HOME and EMDROOT must be set
#      prior to execution of this script.
#
#    MODIFIED   (MM/DD/YY)
#    lsatyapr    01/10/08 - JTReg moved from emSDK to emdrep
#    rdabbott    08/31/07 - tweak 4570966: error msg readability
#    rdabbott    08/21/07 - review: better login format
#    rdabbott    08/15/07 - bug 4570966: password not required on command line
#    rmaggarw    05/20/07 - autogen mib on eventtyp reg
#    minfan      01/31/07 - update ojdbc jar to env var
#    dgiaimo     02/06/07 - Adding ojdl.jar and dms.jar
#    lsatyapr    02/08/07 - Update emutil classpath
#    lsatyapr    01/17/07 - Perl EMUtil
#    lsatyapr    01/17/07 - Creation
# 

use strict;
use POSIX;

$main::VERSION   = 'Enterprise Manager 11.0.0.0.0';
$main::COPYRIGHT = 'Copyright (c) 2007, 2008, Oracle. All rights reserved.  ';

sub displayHelp()
{
   print<<EOF_HELP

Error: Incorrect command option

Usage:
emutil register jobtype [<options>] [<connect details>] <XML filename>
OR
emutil register eventtype [-o <outdirectory>] [-m <mibdirectory>] <XML filename>
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
               "$main::oracleHome/jdbc/lib/ojdbc5.jar",
               "$main::oracleHome/jlib/orai18n.jar",
               "$main::oracleHome/jlib/orai18n-mapping.jar",
               "$main::oracleHome/jlib/orai18n-translation.jar",
               "$main::oracleHome/jlib/orai18n-collation.jar",
               "$main::oracleHome/jlib/orai18n-mapping.jar",
               "$main::oracleHome/jlib/orai18n-utility.jar",
               "$main::oracleHome/jdbc/lib/nls_charset12.jar",
               "$main::oracleHome/j2ee/OC4J_EM/applications/em/em/WEB-INF/classes",
               "$main::oracleHome/sysman/jlib/emCORE.jar",
               "$main::oracleHome/sysman/jlib/emagentSDK.jar",
               "$main::oracleHome/sysman/jlib/log4j-core.jar",
               "$main::oracleHome/dms/lib/ojdl.jar",
               "$main::oracleHome/dms/lib/dms.jar",
               "$main::oracleHome/jlib/uix2.jar",
               "$main::oracleHome/lib/xmlparserv2.jar",
              );
    return $classpath;
}

sub execJava
{
    my ($classpath, $classname, @args) = @_;
    my $stat;

    $stat = system("$main::javaHome/bin/java", "-classpath", $classpath,
                   "-DEMDROOT=$main::emdRoot", "-DORACLE_HOME=$main::oracleHome",
                   $classname, @args);

    # Exit code is returned value/256. Return the lowest byte after that
    exit (($stat >> 8) & 0xFF);
}

sub registerJobType
{
    my @args = @_;
    my $classPath = join(":",
                         "$main::oracleHome/jlib/commons-el.jar",
                         "$main::oracleHome/jlib/jsp-el-api.jar",
                         "$main::oracleHome/jlib/oracle-el.jar",
                         "$main::oracleHome/lib/xschema.jar",
                         "$main::oracleHome/lib/xml.jar",
                         "$main::oracleHome/lib/xmlmesg.jar",
                         getBaseClasspath());

    execJava($classPath, "oracle.sysman.emdrep.jobs.defn.JobTypeRegistration", @args);
}

sub registerEventType
{
    my @args = @_;
    my $outputDir;
    my $mibDir;

    if (defined $args[0] and $args[0] eq "-o")
    {
        displayHelp unless ($#args >= 2);
        shift @args;
        $outputDir = shift @args;
    }
    else
    {
        $outputDir = &POSIX::getcwd();
    }

    if (defined $args[0] and $args[0] eq "-m")
    {
        displayHelp unless ($#args == 2);
        shift @args;
        $mibDir = shift @args;
    }
    else
    {
        $mibDir = &POSIX::getcwd();
    }

    print join(" ", @args) . "\n";

    displayHelp unless ($#args == 0);
    my $inputFile = shift @args;

    execJava(getBaseClasspath(),
            "oracle.sysman.core.app.events.evtmodel.parser.EventTypeParserHandler",
            $inputFile, $outputDir, $mibDir, "prompt");
}

sub initVars
{
    unless (defined $ENV{JAVA_HOME}
            and defined $ENV{ORACLE_HOME}
            and defined $ENV{EMDROOT})
    {
        print<<EOF_ERROR
Please set the following environment variables before executing this script:
    JAVA_HOME   - Location of Java (parent of bin directory)
    ORACLE_HOME - Location where Oracle is installed
    EMDROOT     - Location of agent
EOF_ERROR
        ;
        exit 1;
    }

    $main::javaHome   = $ENV{JAVA_HOME};
    $main::oracleHome = $ENV{ORACLE_HOME};
    $main::emdRoot    = $ENV{EMDROOT};

    # Set path so that our native executables can be found when run from java
    $ENV{PATH} = qq($main::emdRoot/bin:$ENV{PATH});
}

&initVars;
&printHeader;

my @args = @ARGV;
my $option1 = (shift @args or "");
my $option2 = (shift @args or "");

if ($option1 eq "register")
{
    if ($option2 eq "eventtype")
    {
        registerEventType(@args);
    }
    elsif ($option2 eq "jobtype")
    {
        registerJobType(@args);
    }
    else
    {
        displayHelp;
    }
}
elsif ($option1 eq "-help")
{
    registerJobType($option1);
}
else
{
    displayHelp;
}
