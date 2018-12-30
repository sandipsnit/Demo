#
# Copyright (c) 2003, 2010, Oracle and/or its affiliates. All rights reserved. 
#
# DESCRIPTION
#   EM script to patch OPatch inside ORACLE_HOME
#
# USAGE
#   perl emdpatch.pl <patch-id> [<options>] [<patch-loc>]
#
#   patch-id                         : PSE patch number
#   patch-loc                        : Location of patch files
#   options
#     -invPtrLoc <OUI-inventory-loc> : Location of OUI inventory
#     -oh <ORACLE_HOME>              : Location of ORACLE_HOME
#     -no_inventory                  : Ignore OUI inventory update
#     -bounce                        : Bounce the agent.
#
# NOTES
#   <other useful comments,qualifications,etc>
#
# MODIFIED     (MM/DD/YY)
#   vganeasn    01/29/09 - Support 'util updateOPatchVersion'
#   vganesan    08/05/08 - Bug-6612481 : Backup old OPatch as $OH/OPatch/OPatch_<ver> 
#                          rather than renaming it in $OH directory itself 
#   vsriram     07/01/08 - Bug 7145653 : Default don't bounce agent, bounce on request
#   vsriram     05/19/08 - Bug 7111712 : Do not bounce the agent only if specified.
#   vsriram     12/22/06 - Bug-5731160 : Take care of lower version.
#   shgangul    04/18/05 - shgangul_opatch_backup_rollback_emdpatch
#   shgangul    04/15/05 - Fix minor bug in pattern matching version string 
#   shgangul    01/27/05 - Bounce agent while patching agent
#   shgangul    01/21/05 - shgangul_opatch_add_emdpatch_pl_ver1
#   shgangul    01/20/05 - Created

# --- Set up necessary variables for proper running of this environment ---
use English;
use strict;
use File::Basename;
use File::Find;
use File::Path;
use File::Spec();
use File::Spec::Functions qw (:ALL);
use File::Copy();
use File::Copy;

# Constants
use constant B_TRUE             => 1;
use constant B_FALSE            => 0;

my $scriptName = basename($0);
my $scriptDir  = dirname($0);


# ------ Initialize global variables -------------------------------------

my $patch_path  = rel2abs($scriptDir);
# This script will be located inside OPatch directory. So patch path
# is actually a level over that
$patch_path  = dirname($patch_path);
my $patch_id    = $ARGV[0];           # patch number (e.g. 2944899)
my $patch_loc   = '';                 # location of patch files
my $inv_loc     = '';                 # OUI inventory location
my $PERL        = $^X;                # Perl executable
my $EMDROOT     = $ENV{'EMDROOT'};
my $ORACLE_HOME = $ENV{'ORACLE_HOME'};
my $PERL5LIB    = $ENV{'PERL5LIB'};
my $FAIL        = (1<<9);
my $blackout    = "${patch_id}-$$";   # blackout name
my $wantMask    = '';                 # used as mask for wantName()
my $sleepTime   = 60;                 # used to give job a chance to suspend
my $status      = $FAIL;              # used to display if a patch is successful
my $stopAgent   = 0;                  # 1 = stopped; 0 = failed
my $startBlackout = 0;                # 1 = started; 0 = failed
my $retStatus   = 0;                  # used for testing system commands
my $bounceAgent = B_FALSE;            # By default do not bounce agent if upgrading opatch in agent home

# --------------------- OSD platform-specific ---------------------------

my $NULL_DEVICE  = '/dev/null';
my $EMCTL        = 'emctl';
my $OPATCHPL     = 'opatch.pl';
my $PATCHSH      = 'patch.sh';
my $RMFR         = '/bin/rm -fr';
my $SHELL        = '/bin/sh';
my $TAR          = '/bin/tar';

my $INVPTRLOCFILEPATH = '';
my $INVPTRLOCFILE = 'oraInst.loc';

# --------------------- Subroutines -------------------------------------

# setupOSD()
#
# Setup OSD commands
#
sub setupOSD
{
    if (!defined $EMDROOT || $EMDROOT eq '')
    {
        abortf("EMDROOT not defined.");
    }

    if (!defined $ORACLE_HOME || $ORACLE_HOME eq '')
    {
        abortf("ORACLE_HOME not defined.");
    }

    if (!defined $PERL5LIB || $PERL5LIB eq '')
    {
        $PERL5LIB = getPERL5LIB();
        $ENV{'PERL5LIB'} = $PERL5LIB;
    }

    # This will enable emctl to return error codes, not required for
    # Unix, add it anyway
    if ( !defined $ENV{NEED_EXIT_CODE} )
    {
        $ENV{NEED_EXIT_CODE} = 1;
    }

    if (onWindows())
    {
        $NULL_DEVICE = 'NUL';
        $EMCTL       = 'emctl.bat';
        $PATCHSH     = 'patch.bat';
        $RMFR        = 'ERASE /S /Q';
        $SHELL       = 'CMD.EXE';
        $TAR         = 'TAR';

        # Convert path separators for windows case
        $EMDROOT =~ s/\//\\/g;
        $ORACLE_HOME =~ s/\//\\/g;
        $PERL5LIB =~ s/\//\\/g;
    }

    # Use perl utility to concat file names
    # $EMCTL = "$EMDROOT/bin/$EMCTL";
    $EMCTL = File::Spec -> catfile($EMDROOT, "bin", $EMCTL);
}

# parseArgs()
#
# Parse the arguments and store them away for future use
#
sub parseArgs
{
    my $opt      = '';
    my $argcount = scalar(@ARGV);

    $patch_id = $ARGV[0];   # PSE number
    if (!defined $patch_id || $patch_id eq '')
    {
        abortf("PSE number not specified.")
    }

    for (my $i = 1 ; $i < $argcount ; $i++)
    {
        $opt = $ARGV[$i];
        if (substr($opt,0,1) eq '-')
        {
            if (index('-invPtrLoc', $opt) == 0)
            {
                if ($i < ($argcount - 1))
                {
                    $i += 1;
                    $inv_loc = "-invPtrLoc $ARGV[$i]";
                }
            }
            elsif (index('-oh', $opt) == 0)
            {
                if ($i < ($argcount - 1))
                {
                    $i += 1;
                    $ORACLE_HOME = $ARGV[$i];
                    $ENV{'ORACLE_HOME'} = $ORACLE_HOME;
                }
            }
            elsif (index('-no_inventory', $opt) == 0)
            {
                $inv_loc = '-no_inventory';
            }
            elsif (index('-bounce', $opt) == 0)
            {
                $bounceAgent = B_TRUE;
            }
        }
        elsif ($patch_loc eq '')
        {
            if (-d "$opt")
            {
                $patch_loc = $opt;
                $patch_path = $patch_loc;
            }
        }
    }
    if ( $inv_loc eq '' )
    {
        $INVPTRLOCFILEPATH = File::Spec->catfile($ORACLE_HOME, $INVPTRLOCFILE);
        if (-f $INVPTRLOCFILEPATH)
        {
            $inv_loc  =  "-invPtrLoc $INVPTRLOCFILEPATH";
        }
    }
}

#
# getPERL5LIB()
#
# Return the equated value of $PERL5LIB
#
sub getPERL5LIB
{
    my $PERL5LIB = $ENV{'PERL5LIB'};
    if (!defined $PERL5LIB || $PERL5LIB eq '')
    {
        $PERL5LIB = $ENV{'PERLLIB'};
        if (!defined $PERL5LIB || $PERL5LIB eq '')
        {
            for (my $i = 0 ; $i < @INC ; $i++)
            {
                if ($i == 0)
                {
                    $PERL5LIB = $INC[$i];
                }
                else
                {
                    $PERL5LIB .= ':' . $INC[$i];
                }
            }
        }
    }

    return $PERL5LIB;
}

# currentDir()
#
# Return absolute value of working directory
#
sub currentDir
{
    my $curDir = '.';
    if (onWindows())
    {
        chomp($curDir = `cd`);
    }
    else
    {
        chomp($curDir = `pwd`);
    }

    return $curDir;
}

# onWindows()
#
# Return true if running under MS Windows
#
sub onWindows
{
    return ($^O eq 'MSWin32');
}

#
# echodo(<cmd>)
#
# Display the command and execute it
#
# Return exit status
#
sub echodo($)
{
    my ($cmd) = @_;

    printf("\n%s\n", $cmd);

    return system($cmd);
}

#
# logf(<message>)
#
# Display the message with timestamp
#
#
sub logf($)
{
    my ($msg) = @_;

    printf("\n%s - %s\n", scalar(localtime()), $msg);
}

#
# errorf(<message>)
#
# Display an error message
#
#
sub errorf($)
{
    my ($msg) = @_;

    printf("\nError: %s\n", $msg);
}

#
# abortf(<message>,<status>)
#
# Display a fatal error message and exit
#
#
sub abortf($;$)
{
    my ($msg, $status) = @_;

    $status = $FAIL if (!defined $status);

    printf("\nFatal Error: %s\n", $msg);
    logf("Patching aborted.");

    exit statusf($status);
}

#
# statusf(<status>)
#
# Returns the exit status of failed command
#
#
sub statusf($)
{
    my ($status) = @_;

    $status = $FAIL if (!defined $status);

    return ($status >> 8);
}

#
# setOutputAutoflush()
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

# wantName()
#
# Helper routine called by findFile to find matching file
#
sub wantName
{
    # Could be source of the famous unicode problem in perl
    # if ($_ =~ m/^$wantMask$/)
    if ($_ eq $wantMask)
    {
        $wantMask = $File::Find::name;
    }
}

# findFile(<path>,<mask>)
#
# Return the absolute name of file matching a pattern mask
#
sub findFile($$)
{
    my ($path, $mask) = @_;

    $wantMask = $mask;
    find(\&wantName, $path);
    if ($wantMask eq $mask)
    {
        return '';
    }

    # Update directory name to take care of windows case
    if ( onWindows() ) {
        $wantMask =~ s/\//\\/g;
    }

    return $wantMask;
}

# Returns true(1) if the home is agent home, and false(0) otherwise
sub isAgentHome
{
    if ($EMDROOT eq $ORACLE_HOME)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

# Move directory recursively to destination
# sub move_contents_to_dir ( <Destination directory>, <OPatch location in $OH>, <contents that can be files or directories>)
# Moves the contents of Source input to Destination directory

sub move_contents_to_dir
{

 # $dst holds the Destination directory to backup
 my $dst = $_[0];
 # $opatch_loc holds the Original OPatch location in Oracle Home. 
 my $opatch_loc = $_[1];
 # recursive contents (paths) of the Original OPatch that needs to be backed up.
 # This is assumed to not include backup dir :) 
 my @src = @_[2..$#_];

 my $result = $FAIL; # Default to failure

 # Try to move the files to destination directory 
 if ( ( -d $dst ) && ( -w $dst) )
  {
     $dst =~ s/\\/\//g;

     foreach (@src)
     {
       my $sourceContent = $_;
       my $destContent;

       if ($sourceContent  =~ /^\Q$opatch_loc\E(.*)$/)
       {
         $destContent = $1;
       }

       my $destPath = File::Spec -> catfile($dst, $destContent);
       
       if (-d $sourceContent)
       {
         mkpath($destPath) if not -e $destPath;
       }
       elsif  ( ($sourceContent ne $scriptName) && (-f $sourceContent) )
       {
         move ($sourceContent, $destPath);
         chmod 0755, $destPath;
       }



     }

     ## delete empty directories in Original OPatch location. This could
     ## be there because of empty recursive directories
     foreach (@src)
     {
       my $sourceContent = $_;
       if (-d $sourceContent) { finddepth(sub{rmdir},$sourceContent); }

     }

  } # end of if


  $result = 0; # Move success

}

    
    
# Copy directory recursively to destination
# result = copy_dir ( <Source directory>, <Destination directory> )
# Copies the contents of Source directory to Destination directory
sub copy_dir
{
    my $src = $_[0]; # Source Directory
    my $dst = $_[1]; # Destination Directory
    my $result = $FAIL; # Default to failure
    

    # Try to copy if both source and destination are directories
    if ( ( -d $src ) && ( -r $src ) && ( -d $dst ) && ( -w $dst) )
    {
        $src =~ s/\\/\//g;
        $dst =~ s/\\/\//g;
        find
        (
            sub
            {
                my $targetdir = $File::Find::dir;
                my $target = $targetdir;
                $targetdir = $dst . substr($targetdir, length($src));

                mkpath( $targetdir ) if not -e $targetdir;

                my $file = $_;
                my $source = "./" . $file;
                my $dest   = "$targetdir/$file";

                if ( ($file ne $scriptName) && (-f $source) )
                {
                    copy ($source, $dest);
                    chmod 0755, $dest;
                }
            },
            $src
        );

        $result = 0; # Copy success
    }

    return $result;
}

# returns OPatch version. Expects OPatch directory as input
sub get_opatch_version
{
    my $opatch_dir = $_[0];
    my $opatch_dir_abs = rel2abs($opatch_dir);
    my $opatch_exec = File::Spec -> catfile($opatch_dir_abs, "opatch");
    if ($OSNAME =~ m#Win32#)
    {
        $opatch_exec = File::Spec -> catfile($opatch_dir_abs, "opatch\.bat");
    }

    my $version = "0.0.0.0.0";

    if ( -x $opatch_exec)
    {
        my $system_command = $opatch_exec . " version";
        my $sys_call_result = qx/$system_command/;
        my $return_code = $CHILD_ERROR >> 8;
        if ( $return_code == 0 )
        {
            ($version) = ($sys_call_result =~ /.* ([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*).*/);
        }
    }

    return $version;
}

# updates the OPatch version in the inventory of the Oracle Home
sub update_opatch_version
{
   my $opatch_dir = $_[0];
   my $opatch_dir_abs = rel2abs($opatch_dir);
   my $return_code = 0;
    

   my $opatch_exec = File::Spec -> catfile($opatch_dir_abs, "opatch");
   if ($OSNAME =~ m#Win32#)
   {
      $opatch_exec = File::Spec -> catfile($opatch_dir_abs, "opatch\.bat");
   }

   if ( -x $opatch_exec)
   {
     my $system_command = $opatch_exec . " util updateOPatchVersion " . "-oh $ORACLE_HOME " . $inv_loc . " -silent";
     my $sys_call_result = qx/$system_command/;
     logf($sys_call_result);
     $return_code = $CHILD_ERROR >> 8;
   }

   return $return_code;   
}

# Compare two OPatch versions <1> and <2>.
# If <1> Greater than <2> returns 1
# If <1> Equal to <2> returns 0
# If <1> Less than <2> returns -1
sub compare_opatch_version
{
    my $opatchv1 = $_[0];
    my $opatchv2 = $_[1];
    my $cmpresult = 0;

    # Now compare
    my (@v1) = ($opatchv1 =~ /([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*).*/);
    my (@v2) = ($opatchv2 =~ /([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*).*/);

    # Loop and compare the versions
    for (my $i = 0; $i < 5; $i ++)
    {
        if ($v1[$i] > $v2[$i])
        {
            $cmpresult = 1;
            last;
        }
        elsif ($v1[$i] < $v2[$i])
        {
            $cmpresult = -1;
            last;
        }
    }

    return $cmpresult;
}

# --------------------- Main program -------------------------------------

# make sure output is flushed
setOutputAutoflush();

# make sure arguments are correct
parseArgs();

# make sure environment is correct
setupOSD();

# output a little info for feedback
printf("PERL        = $^X\n");
printf("SCRIPT      = $0\n");
printf("PERL5LIB    = $PERL5LIB\n");
printf("EMDROOT     = $EMDROOT\n");
printf("ORACLE_HOME = $ORACLE_HOME\n");

# Sleep for 60 secs if patching agent only
if (isAgentHome())
{
    # wait for a minute - Job System requirement
    logf("Working...");
    sleep($sleepTime);
}

# Step 1: add blackout for all targets on host
if ( ($startBlackout == 0) && isAgentHome() && $bounceAgent)
{
    logf("Attempting to add blackout for host...");
    if ( onWindows() )
    {
        $retStatus = echodo("$EMCTL start blackout $blackout -nodelevel");
    }
    else
    {
        $retStatus = echodo("$EMCTL start blackout $blackout -nodelevel 2>&1");
    }
    # right shift retstatus by 8 to get the correct error code
    $retStatus = statusf($retStatus);
    if ($retStatus != 0)
    {
        errorf("failed to start blackout: status = " . $retStatus);
        $startBlackout = 0;
    }
    else
    {
        logf("Blackout succeeded");
        $startBlackout = 1;
    }
}

# Step 2: shutdown the running Oracle Agent
if ( ($startBlackout == 1) && isAgentHome() && $bounceAgent)
{
    logf("Attempting to stop Oracle Management Agent...");
    if ( onWindows() )
    {
        $retStatus = echodo("$EMCTL stop agent");
    }
    else
    {
        $retStatus = echodo("$EMCTL stop agent 2>&1");
    }
    # right shift retstatus by 8 to get the correct error code
    $retStatus = statusf($retStatus);
    if ($retStatus != 0)
    {
        errorf("failed to stop Management Agent: status = " . $retStatus);
        $stopAgent = 0;
    }
    else
    {
        logf("Agent stopped successfully");
        $stopAgent = 1;
    }
}

# Step 3: apply the patch here
if ((!isAgentHome()) || (isAgentHome() && ( $stopAgent == 1 || ! $bounceAgent ) ))
{
    # Apply the patch here
    # Basically copy the OPatch from present location to ORACLE_HOME/OPatch
    if (isAgentHome())
    {
        logf("Attempting to patch Oracle Management Agent...");
    }
    else
    {
        logf("Attempting to patch non-Agent Oracle Home...");
    }
    
    # either call opatch here or a substitute mechanism
    # We expect this script to be inside OPatch
    my $opatch_src = File::Spec -> catfile($patch_path, "OPatch");
    
    # opatch destination to ORACLE_HOME
    my $opatch_dst = File::Spec -> catfile($ORACLE_HOME, "OPatch");
    
    # Default result to FAIL
    my $result = $FAIL;
    
    # Copy OPatch to ORACLE_HOME here
    if ($opatch_src ne '')
    {
        logf("OPatch located in the patch...");
        if ( ! -e $opatch_dst ) # OPatch does not exist
        {
            logf("OPatch not present in ORACLE_HOME...");
            logf("Patching OPatch to ORACLE_HOME...");
            mkpath( $opatch_dst ) if not -e $opatch_dst;
            $result = copy_dir ($opatch_src, $opatch_dst);
            logf("Patching OPatch to ORACLE_HOME complete. Result = $result");
    
            # Set status
            if ($result == 0)
            {
                $status = 0;
            }
        }
        else
        {
            if ( -d $opatch_dst )
            {
                logf("ORACLE_HOME has OPatch already present...");
                # Calculate the versions
                my $version_dst = get_opatch_version($opatch_dst);
                my $version_src = get_opatch_version($opatch_src);
                logf("Version of OPatch in ORACLE_HOME is $version_dst");
                logf("Version of OPatch in the patch is $version_src");

                my (@v1) = ($version_src =~ /([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*).*/);
                my (@v2) = ($version_dst =~ /([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*)\.([0-9][0-9]*).*/);

                if((($v1[0]  >= 10) && ($v2[0] == 1)) || (($v2[0] >= 10) && ($v1[0] == 1)))
                {
                    logf("WARNING: The new OPatch is not compatible for this ORACLE_HOME, hence it will not be updated.");                
                    $result = 0;
                }
                else
                {
                    # returns 1 if version_src > version_dst and 0 if
                    # version_src = version_dst and -1 if
                    # version_src < version_dst
                    my $version_cmp_result = compare_opatch_version ($version_src, $version_dst);
    
                    # Patch if source OPatch is higher or equal to one
                    # inside the ORACLE_HOME
                    if ( $version_cmp_result >= 0 )
                    {
                        # Backup the original OPatch before proceeding
                        my $opatch_bak_dir = "OPatch_" . $version_dst;

                        # Directory to backup to : $OH/OPatch/backup/OPatch_<version> 
                        my $opatch_bak = File::Spec -> catfile($ORACLE_HOME, "OPatch", "backup", $opatch_bak_dir);
                    
                        # 'backup' directory path of OPatch
                        my $backup_dir = File::Spec -> catfile($ORACLE_HOME, "OPatch", "backup");
                                
                        # Get the contents of the source directory $OH/OPatch now. 
                        my @orig_opatch_contents;
                        find sub {
                                   my $opatch_file_path = $File::Find::name;
                                   # definitely needed for windows - as it is a pattern match
                                   if (onWindows()) { $opatch_file_path =~ s/\//\\/g; }
                                   if ($opatch_file_path  =~ /^\Q$backup_dir\E(.*)$/) { return; }
     				   push @orig_opatch_contents, $opatch_file_path;
     				 }, $opatch_dst;

                        logf("Backing up original OPatch to $opatch_bak...");
 
                        # Create backup directory : $OH/OPatch/backup/OPatch_<version>
                        mkpath( $opatch_bak ) if not -e $opatch_bak;

                        $result = move_contents_to_dir($opatch_bak, $opatch_dst, @orig_opatch_contents);
    
                        # Proceed with original copy if backup succeeds
                        if ( $result == 0 )
                        {
                            logf("Patching OPatch to ORACLE_HOME...");
                            $result = copy_dir ($opatch_src, $opatch_dst);
                            logf("Patching OPatch to ORACLE_HOME complete. Result = $result");
                        }
                    }
                    else
                    {
                         logf("Version of OPatch in ORACLE HOME is newer than the version of OPatch in patch. Nothing needs to be done.");
                         $result = 0;
                    }
                }
            }
            else
            {
                 logf("ERROR: A file by name OPatch exists in ORACLE_HOME. OPatch will not be updated.");
            }
    
            # Set status
            if ($result == 0)
            {
                $status = 0;
            }
        }
    }

    # Step 3a : Update OPatch version in the inventory

    if ( -e $opatch_dst)
    {
      # we ignore the return code as of now. we don't want the script to error for this call
      update_opatch_version($opatch_dst);
    }
}


# Step 4: restart the patched Oracle Agent
if (($stopAgent == 1) && isAgentHome() && $bounceAgent)
{
    logf("Attempting to start Oracle Management Agent...");
    if ( onWindows() )
    {
        $retStatus = echodo("$EMCTL start agent");
    }
    else
    {
        $retStatus = echodo("$EMCTL start agent 2>&1");
    }
    # right shift retstatus by 8 to get the correct error code
    $retStatus = statusf($retStatus);
    if ($retStatus != 0)
    {
        errorf("failed to start Management Agent: status = " . $retStatus);
        logf("Please start the agent and then stop blackout manually");
        $stopAgent = 1;
    }
    else
    {
        logf("Agent started successfully");
        $stopAgent = 0;
    }
}

# Step 5: remove blackout for all targets on host
if ( isAgentHome() && ($startBlackout == 1) && ($stopAgent == 0) && $bounceAgent )
{
    logf("Attempting to remove blackout for host...");
    if ( onWindows() )
    {
        $retStatus = echodo("$EMCTL stop blackout $blackout");
    }
    else
    {
        $retStatus = echodo("$EMCTL stop blackout $blackout 2>&1");
    }
    # right shift retstatus by 8 to get the correct error code
    $retStatus = statusf($retStatus);
    if ($retStatus != 0)
    {
        errorf("failed to stop blackout: status = " . $retStatus);
        logf("Please stop blackout manually");
        $startBlackout = 1;
    }
    else
    {
        logf("Blackout stopped successfully");
        $startBlackout = 0;
    }
}

# Exit with status
if ($status == 0)
{
    if (isAgentHome())
    {
        printf("\napplyPatch %s successful\n", $patch_id); # To satisfy showResults
    }
    else
    {
        logf("Patching completed");
    }
}
else
{
    logf("Patching failed");
}

if ($status == $FAIL)
{
    $status = statusf($status);
}

exit $status;
