#
# Copyright (c) 2003, 2008, Oracle. All rights reserved.  
#
# DESCRIPTION
#   Script for download Oracle MetaLink Metadata from commandline.
#
# USAGE
#   perl dump_metadata.pl [<options>] 
#
# NOTES
#
# MODIFIED     (MM/DD/YY)
#   summukhe   04/10/08 - removing internal reference
#   milshah    09/19/05 - Legal Bug 4614013 : to include MetaLink terms of use 
#   milshah    09/07/05 - milshah_bug-4590359
#   milshah    08/11/05 - Created

# ------ Initialize global variables -------------------------------------

use English;         # Let us say "$CHILD_ERROR" instead of "$?", etc.
use strict;          # Enforce strict variables, refs, subs, etc.
use Cwd;

# constants
use constant S_EMPTY => '';

my @files = 
(
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_products",
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_releases",
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_platforms",
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_languages",
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_product_groups",
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_product_releases",
"http://updates.oracle.com/ARULink/XMLAPI/download_seed_data\?table=aru_component_releases",
"http://updates.oracle.com/ARULink/XMLAPI/query_advisories"
 );

my @filenames = 
(
"aru_products.xml",
"aru_releases.xml",
"aru_platforms.xml",
"aru_languages.xml",
"aru_product_groups.xml",
"aru_product_releases.xml",
"aru_component_releases.xml",
"query_advisories.xml"
 );


# my variables
my $WGET_LOC   = S_EMPTY;
my $TO         = S_EMPTY;
my $HTTP_USER  = S_EMPTY;
my $HTTP_PASS  = S_EMPTY;
my $PROXY_USER = S_EMPTY;
my $PROXY_PASS = S_EMPTY;
my $PROXY_HOST = S_EMPTY;

my $PROXY_STRING = S_EMPTY;

my $USAGE = "USAGE:
             perl dump_metadata.pl <options>
            
             <options>
             -wget_loc   : wget location if you dont want to use the default wget. 
                           (optional. If not given default wget is used)
             -to         : Directory where you want to download Oracle Metadata files
                           (optional if not specified current directory will be used)
             -http_user  : Metalink username 
                           (mandatory)
             -http_pass  : Metalink password 
                           (mandatory)
             -proxy_user : Proxy username 
                           (optional; needed only if proxy requires authentication)
             -proxy_pass : Proxy password
                           (optional; needed only if proxy requires authentication)
             -proxy_host : Proxy url
                           (mandatory if proxy_user and proxy_pass are given. format: host:port)

             Example: perl dump_metadata.pl -to /downloads/metadata -http_user abc_us -http_pass xxxx 
                                            -proxy_user user1 -proxy_pass xxxx -proxy_host example-proxy.example.com:80";


my $PERL        = $^X;                 # Perl executable
my $PERL5LIB    = $ENV{'PERL5LIB'};
my $OP          = -1;

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

    # atleast http_user and http_pass and their values should be there. 
    if ($argcount < 4)
    {
        printf("$USAGE \n");
        exit -1;
    }

    for (my $i = 0 ; $i < $argcount ; $i++)
    {
        $opt = $ARGV[$i];
        if (substr($opt,0,1) eq '-')
        {
            if (index('-wget_loc', $opt) == 0)
            {
		#Do not use default wget
                $WGET_LOC = getStringArg($opt, $i);
                $i++;
            }
            elsif (index('-to', $opt) == 0)
            {
                $TO = getStringArg($opt, $i);
                $i++;
            }
            elsif (index('-http_user', $opt) == 0)
            {
                $HTTP_USER = getStringArg($opt, $i);
                $i++;
            }
            elsif (index('-http_pass', $opt) == 0)
            {
                $HTTP_PASS = getStringArg($opt, $i);
                $i++;
            }
            elsif (index('-proxy_user', $opt) == 0)
            {
                $PROXY_USER = getStringArg($opt, $i);
                $i++;
            }
            elsif (index('-proxy_pass', $opt) == 0)
            {
                $PROXY_PASS = getStringArg($opt, $i);
                $i++;
            }
            elsif (index('-proxy_host', $opt) == 0)
            {
                $PROXY_HOST = getStringArg($opt, $i);
                $i++;
            }
        }
    }

    # If to directory is missing then assume its current working directory
    if ($TO eq S_EMPTY)
    { 
	$TO = $cwd;
    }

    # Also if TO directory not existing, create it.
    if (!(-d $TO))
    {
	system("mkdir -p $TO");
    } 

    # To verify whether using proxy or not
    if (($PROXY_USER ne S_EMPTY) && ($PROXY_PASS ne S_EMPTY))
    {
        if ($PROXY_HOST ne S_EMPTY)
        {
            $ENV{'HTTP_PROXY'} = $PROXY_HOST;
        }
        $PROXY_STRING = "--proxy-user=$PROXY_USER --proxy-passwd=$PROXY_PASS"
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
printf("\nYour use of MetaLink data is subject to the terms of your Oracle license and services agreement and the MetaLink Terms of Use.\n");
printf("\n###################################################\n");
printf("Some info and user args :\n");
printf("PERL          = $^X\n");
printf("SCRIPT        = $0\n");
printf("WGET location = $WGET_LOC\n");
printf("TO location   = $TO\n");
printf("HTTP user     = $HTTP_USER\n");
printf("HTTP pass     = $HTTP_PASS\n");
printf("PROXY user    = $PROXY_USER\n");
printf("PROXY pass    = $PROXY_PASS\n");
printf("PROXY host    = $PROXY_HOST\n");
printf("\n###################################################\n");

my $counter = 0;
foreach my $file (@files)
{
   my $curr_filename = $filenames[$counter]; 
 
   printf("\n---------------------------------------------------\n");
   printf("WGET SUMMARY:\n");

   if ($WGET_LOC eq S_EMPTY)
   {
       printf("WGET command: wget $file --http-user=$HTTP_USER --http-passwd=$HTTP_PASS $PROXY_STRING --output-document=$TO/$curr_filename\n");
       chomp($OP = `wget $file --http-user=$HTTP_USER --http-passwd=$HTTP_PASS $PROXY_STRING --output-document=$TO/$curr_filename`); 
   }
   else
   {
       printf("WGET command: $WGET_LOC $file --http-user=$HTTP_USER --http-passwd=$HTTP_PASS $PROXY_STRING --directory-prefix=$TO --output-document=$TO/$curr_filename\n");
       chomp($OP = `$WGET_LOC $file --http-user=$HTTP_USER --http-passwd=$HTTP_PASS $PROXY_STRING --directory-prefix=$TO --output-document=$TO/$curr_filename`); 
   }

   printf("\n---------------------------------------------------\n");

   my $return_code = ($CHILD_ERROR >> 8); 
   if ($return_code != 0)
   {
        #print usage
        printf("\n***************************************************\n");
        printf("There was an error in getting the file : $file\n");
        printf("\n***************************************************\n");
        exit -1;
   }
   $counter++;
}

exit 0;


