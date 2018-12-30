#
# Copyright (c) 2003, 2008, Oracle and/or its affiliates.All rights reserved. 
#
# DESCRIPTION
#   Script for calling RefreshFromMetalink job standalone from commandline.
#
# USAGE
#   perl refFromML.pl [<options>] 
#
# NOTES
#
# MODIFIED     (MM/DD/YY)
#   summukhe   04/10/08 - removing internal reference
#   minfan     01/30/07 - update ojdbc jar path to env var
#   mbhoopat   02/09/07 - Adding emagentSDK.jar to classpath
#   milshah    09/19/05 - 
#   milshah    09/07/05 - milshah_bug-4590359
#   milshah    07/21/05 - Created

# ------ Initialize global variables -------------------------------------

use English;         # Let us say "$CHILD_ERROR" instead of "$?", etc.
use strict;          # Enforce strict variables, refs, subs, etc.

my $USAGE = "USAGE:
             perl refFromML.pl (download|upload|update) <options>
            
             <options> for various modes
       
             if 'download':
             -to       : Directory where you want to download ARU files
             -dl_url   : Metalink url from where to download ARU files
             -dl_user  : Metalink username
             -dl_pass  : Metalink password
             -rep_conn : Repoistory connection string <OMS_URL>:<PORT>:<SID>
             -rep_user : Repository username
             -rep_pass : Repository password

             Example: perl refFromML.pl download -to=/downloads/aru -dl_url=http://updates.example.com 
                      -dl_user=abc_us -dl_pass=xxxx -rep_conn=abc.example.com:1521:emrep 
                      -rep_user=admin -rep_pass=xxxx

             if 'upload':
             -from     : Directory where you want to download ARU files
             -rep_conn : Repoistory connection string <OMS_URL>:<PORT>:<SID>
             -rep_user : Repository username
             -rep_pass : Repository password

             Example: perl refFromML.pl upload -from=/downloads/aru -rep_conn=abc.example.com:1521:emrep 
                      -rep_user=admin -rep_pass=xxxx

             if 'update':
             -dl_url   : Metalink url from where to download ARU files
             -dl_user  : Metalink username
             -dl_pass  : Metalink password
             -rep_conn : Repoistory connection string <OMS_URL>:<PORT>:<SID>
             -rep_user : Repository username
             -rep_pass : Repository password

             Example: perl refFromML.pl update -dl_url=http://updates.example.com 
                      -dl_user=abc_us -dl_pass=xxxx -rep_conn=abc.example.com:1521:emrep 
                      -rep_user=admin -rep_pass=xxxx
             \n";

       
            

my $ORACLE_HOME = $ENV{'ORACLE_HOME'}; # Oracle Home
my $PERL        = $^X;                 # Perl executable
my $PERL5LIB    = $ENV{'PERL5LIB'};
my $ADE_VIEW_ROOT = $ENV{'ADE_VIEW_ROOT'};
my $CLASSPATH = '';

if ($ORACLE_HOME eq '')
{
    printf("\$ORACLE_HOME is not defined. This script needs the \$ORACLE_HOME to be defined.\n");
    exit -1;
}

if ($ADE_VIEW_ROOT eq '')
{
   #Install
    $CLASSPATH = ".:$ORACLE_HOME/sysman/jlib/emCORE.jar:$ORACLE_HOME/j2ee/home/lib/http_client.jar:$ORACLE_HOME/sysman/jlib/log4j-core.jar:$ENV{'EM_JDBC_DMS_JAR'}:$ORACLE_HOME/lib/xmlparserv2.jar:$ORACLE_HOME/j2ee/home/lib/servlet.jar:$ORACLE_HOME/jlib/uix2.jar:$ORACLE_HOME/lib/dms.jar:$ORACLE_HOME/lib/ojdl.jar:$ORACLE_HOME/lib/emagentSDK.jar:$ORACLE_HOME/jlib/share.jar";
}
else 
{
   #View
   $CLASSPATH = "$ADE_VIEW_ROOT/emcore/sysman/jlib/emCORE.jar:$ADE_VIEW_ROOT/emcore/dependencies/http_client.jar:$ADE_VIEW_ROOT/emcore/dependencies/log4j-core.jar:$ADE_VIEW_ROOT/emagent/lib/emagentSDK.jar:$ADE_VIEW_ROOT/dms/lib/ojdl.jar:$ADE_VIEW_ROOT/dms/lib/dms.jar:$ENV{'EM_JDBC_DMS_JAR'}:$ADE_VIEW_ROOT/emcore/dependencies/xmlparserv2.jar:$ADE_VIEW_ROOT/emcore/dependencies/servlet.jar:$ADE_VIEW_ROOT/emcore/dependencies/uix2.jar:$ADE_VIEW_ROOT/dms/lib/dms.jar:$ADE_VIEW_ROOT/oracle/bali/share/share.jar";
}

my $OP = '';
my $args = '';

# parseArgs()
#
# Parse the arguments and store them away for future use
#
sub parseArgs
{
    $args = join(" ",@ARGV);
}

#
# Set STDOUT,STDERR to autoflush
#
sub setOutputAutoflush
{
    my $outHandle = select(STDOUT);
    $| = 1;    # set OUTPUT_AUTOFLUSH
    select(STDERR);
    $| = 1;                # flush std error as well
    select($outHandle);    #reset handle back to original
}

# --------------------- Main program -------------------------------------

# make sure output is flushed
setOutputAutoflush();

# make sure arguments are correct
parseArgs();

# output a little info for feedback
printf("\n---------------------------------------------------\n");
printf("Some info :\n");
printf("PERL        = $^X\n");
printf("SCRIPT      = $0\n");
printf("ORACLE_HOME = $ORACLE_HOME\n");
printf("ARGS        = $args\n");
printf("\n---------------------------------------------------\n");
printf("Errors thrown out (if any) with stack trace : \n");

open(PROC,"$ORACLE_HOME/jdk/bin/java -cp $CLASSPATH oracle.sysman.emdrep.jobs.commands.UpdateARUTables $args|");
printf("\n---------------------------------------------------\n");
printf("PROGRAM OUTPUT : \n$OP\n");

while(<PROC>) {
# print each line.
   print $_;
}
# Close the process
close(PROC);
printf("\n---------------------------------------------------\n");

my $return_code = ($CHILD_ERROR >> 8);
printf("RETURN CODE : $return_code \n");

if ($return_code != 0)
{
    #print usage
    printf("\n---------------------------------------------------\n");
    printf("There was an error. Check the Usage: \n");
    printf("$USAGE \n");
}

printf("\n---------------------------------------------------\n");
exit $return_code;


