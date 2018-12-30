#
# Copyright (c) 2003, 2005, Oracle. All rights reserved.  
#
# DESCRIPTION
#   Script for oracle services running on windows and to shut them.
#
# USAGE
#   perl winservices.pl [<options>] 
#
# NOTES
#
# MODIFIED     (MM/DD/YY)
#   milshah    10/31/05 - Created

# ------ Initialize global variables -------------------------------------

use English;         # Let us say "$CHILD_ERROR" instead of "$?", etc.
use strict;          # Enforce strict variables, refs, subs, etc.
use Cwd;

# constants
use constant S_EMPTY => '';
use constant B_TRUE  => 1;
use constant B_FALSE => 0;

# my variables
my $ORACLE_HOME = $ENV{'ORACLE_HOME'};

my $STOP_SRVS = B_FALSE;
my $IS_RUNNING = B_FALSE;

my $USAGE = 
"USAGE:
 perl winservices.pl <options>
       
 If no options given. It displays all oracle services running in 
 the ORACLE_HOME whatever their status (running, stopped, paused etc) 
 This script needs the ORACLE_HOME, PERL5LIB to be defined.
 Only one of the two options can be given.

 <options>
     -isrunning  : will display oracle services running in the 
                   oracle home. return error code 1 if any services 
                   running else returns eror code 0. 
     -stop       : will stop all the running services.";  

my $PERL        = $^X;                 # Perl executable
my $PERL5LIB    = $ENV{'PERL5LIB'};
my $OP          = S_EMPTY;
my $RETURN_CODE = 0;

my $ORADIM_ALL_CMD  = "$ORACLE_HOME\\bin\\oradim -ex services enum with image | findstr /IL $ORACLE_HOME";
my $ORADIM_CMD = "$ORACLE_HOME\\bin\\oradim -ex services enum with image | findstr /I RUNNING | findstr /IL $ORACLE_HOME";

my $MY_CMD = S_EMPTY;

# getStringArg(<opt>, <i>)
#
# Parse the argument as string
#
# Return value
#
sub getStringArg($$)
{
    my ($opt, $i) = @_;
    my $value = S_EMPTY;

    if ($i < (scalar(@ARGV) - 1))
    {
        $i += 1;
        $value = $ARGV[$i];
    }
    else
    {
        printf("$opt missing \n");
        exit -1;
    }

    return $value;
}


# parseArgs()
#
# Parse the arguments and store them away for future use
#
sub parseArgs
{
    my $opt      = S_EMPTY;
    my $argcount = scalar(@ARGV);
    my $i        = 0;

    my $cwd = getcwd();

    # Only one of isrunning or stop is allowed 
    if ($argcount > 1)
    {
        printf("Only one option can be given.\n\n");
        printf("$USAGE \n");
        exit -1;
    }

    for (my $i = 0 ; $i < $argcount ; $i++)
    {
        $opt = $ARGV[$i];
        if (substr($opt,0,1) eq '-')
        {
            if (index('-stop', $opt) == 0)
            {
		#Do not use default wget
                $STOP_SRVS = B_TRUE;
                $i++;
            }
            elsif (index('-isrunning', $opt) == 0)
            {
                $IS_RUNNING = B_TRUE;
                $i++;
            }
            elsif (index('-help', $opt) == 0)
            {
                printf("$USAGE \n");
                exit 0;                
            }
        }
    }

    # To verify oracle home is set or not
    if ($ORACLE_HOME eq S_EMPTY)
    {
        printf("\nERROR: ORACLE_HOME is not set.\n");
        exit -1;
    }
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
printf("\n###################################################\n");
printf("Some info and user args :\n");
printf("PERL          = $^X\n");
printf("SCRIPT        = $0\n");
printf("###################################################\n");


# Display Services 

$MY_CMD = $ORADIM_ALL_CMD;
if ($IS_RUNNING eq B_TRUE)
{
    $MY_CMD = $ORADIM_CMD;
}

# open process with oradim command
printf("\n###################################################\n");
printf("DISPLAY SERVICES:\n");
printf("ORADIM command: $MY_CMD");
chomp($OP = `$MY_CMD`);
# open(PROC,"$MY_CMD|");
printf("\n---------------------------------------------------\n");
printf("Oracle Services from $ORACLE_HOME: \n");
printf("$OP\n");
# while(<PROC>) 
# {
    # print each line.
#    print $_;
# }
       
# Close the process
#close(PROC);
printf("---------------------------------------------------\n");
printf("###################################################\n");

if ($OP eq S_EMPTY)
{
    if (($IS_RUNNING eq B_FALSE) && ($STOP_SRVS eq B_TRUE))
    {
        printf("\nNo services are running in $ORACLE_HOME to be stopped.\n");
        exit (-1);
    }
    elsif ($IS_RUNNING eq B_TRUE)
    {
        printf("\nNo services are running in $ORACLE_HOME. \n");
	exit (0);
    } 
}
else
{
    if ($IS_RUNNING eq B_TRUE)
    {
        printf("\nServices are still running in $ORACLE_HOME. \n");
	exit (1);
    }
}

# Shut down services if needed
if ($STOP_SRVS eq B_TRUE)
{
    printf("\n###################################################\n");
    printf("STOPPING RUNNING SERVICES:\n");
    # Run oradim.exe to figure out the services running out of an Oracle Home.
    my @op = `$ORADIM_CMD`;
    my $line = S_EMPTY;
    my $service = S_EMPTY;     

    my $size = scalar @op;
    if ($size == 0)
    {
        printf("No services are running.\n");
        printf("###################################################\n");
        exit (0);
    }

    # Loop through the services, figure the names and shut them down.
    foreach $line (@op)
    {
       chomp($line);
 
       # Figure out the service name.
       $service = (split(/\s+/,$line))[1];
       
       # Stop the services
       printf("Manually stopping $service ...\n");
       system("net stop $service");
    } 
    printf("###################################################\n");
}

exit 0;


