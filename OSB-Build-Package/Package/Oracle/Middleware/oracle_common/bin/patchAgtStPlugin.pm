#!/usr/bin/perl
#--------------------------------------------------------------------------
# This plugin will apply the patch to state Directories.
#--------------------------------------------------------------------------
use strict;
use English;
use File::Path;
use Config;
use Fcntl ':flock';

use constant S_EMPTY => '';
#--------------------------------------------------------------------------
# logf(<message>)
#
# Display the message with timestamp
#
sub logf
{
    local (*outFile) = $_[0];
    my $msg = $_[1];

    printf(outFile "\n%s - %s\n", scalar(localtime()), $msg);
}

sub applyPatch {

my $debug = 0;
my $OraHome=$ENV{ORACLE_HOME};
my $emState=$ENV{EMSTATE};
my $nfsPatchPlugin = "false";

if ($emState eq S_EMPTY) {
   print " --- Standalone agent\n";
   return 0;
}
else
{
   print " --- Shared agent\n";
}

open(OUTFILE, ">>$emState/sysman/log/patchAgtStPlugin.log");

#------------ Finding OS---------------------------
my $OSNAME = $Config{'osname'};
my $IsWin32 = ($OSNAME eq 'MSWin32' || $OSNAME eq 'Windows_NT') ;


#------------- Trying to get shared Lock while starting the agent,
#------------- which  is later on used while Patching 

if (-e "$OraHome/sysman/nfsinstall/lock")  
{
  open(FHANDLE,"<$OraHome/sysman/nfsinstall/lock");
  my $retLock = flock( FHANDLE, LOCK_SH | LOCK_NB);
  if ( $retLock ne 0 ) {
    # The above was a non-blocking call so presumably a manual
    # start of the agent can be done and will interfere with
    # patching. Need to fix this ...
    logf(*OUTFILE, "Got the shared lock");
    #print OUTFILE  "Got the shared lock\n";
  }
  else {
    logf(*OUTFILE, "Didn't get the shared lock");
    #print OUTFILE "Didn't get the shared lock\n";
  }
}


#------------------checking if master agent is patched ------------------------

if (! -d "$OraHome/agentpatch" ) {
	if ($debug) {
            print "No patching is required as MasterAgent is not pathched\n";
	}
  return 0;
}

if (! -d "$OraHome/agentpatch/state")  {
  if (-e "$emState/agentpatch/blackout") {
         logf(*OUTFILE, "Stopping the blackout");
         #print OUTFILE "Stopping the blackout\n";
         removeBlackOut($emState);
   }
  else {  
	if ($debug) {
	  print "No patching is required as MasterAgent is not pathched\n";
	}
  }
  return 0;
}

#-----------check if $OraHome/agentpatch/state has any entries----------------

opendir( DIR,"$OraHome/agentpatch/state");

my @files = readdir(DIR);

if ( $#files <= 1  ) {
  close(DIR);
  if ($debug) {
    print "No patching is required as MasterAgent is not pathched\n";
  }

 if (-e "$emState/agentpatch/blackout") {
    logf(*OUTFILE, "Stopping the blackout");
    #print OUTFILE "Stopping the blackout\n";
    removeBlackOut($emState);
 }

  return 0;
}

#-----------------creating patch Dir------------------------------------------
if (! -d "$emState/agentpatch") {
         mkpath( "$emState/agentpatch");
}

#--------------Apply Patches to local host-------------------------------------
#  For all the patchDir the MasterAgent
#  check if file with same directory name exists in the local agent home.
#  If so then don't apply that patch and go to next one.
#  After applying all the patches delete the black out file and stop agent blackout
#------------------------------------------------------------------------------

my $patchDir = S_EMPTY;
my $patchFileName = S_EMPTY;
foreach $patchDir (@files ) {
	chomp $patchDir;

        if( $patchDir eq "."  || $patchDir eq "..") {
             next;
        }

	if ( -e "$emState/agentpatch/$patchDir") {
		next;
	}

       if ($IsWin32) {
         $patchFileName="statepatchcmd.bat";
       }
       else {
           $patchFileName="statepatchcmd.sh";
       }
       

 
        open(AGTLOG, ">>$emState/sysman/log/emagent.trc");
        if ( ! open(PATCHFILE,"$OraHome/agentpatch/state/$patchDir/$patchFileName") ) {
           logf(*OUTFILE, "$patchFileName not found....");
           #print OUTFILE "$patchFileName not found....\n";
           print AGTLOG  "$patchFileName not found...\n";
           return 1;               
        }
        else {
            logf(*OUTFILE, "Applying Patch");
            #print OUTFILE "Applying Patch\n";
            my $patchfile = "$OraHome/agentpatch/state/$patchDir/$patchFileName";
            if($IsWin32) {
                system( "$patchfile");
            }
            else {
             system( "/bin/sh $patchfile");
            }
            my $exit_value  = $? >> 8;
	    if ( $exit_value != 0 ) {
        	   print "Error while applying patch $patchDir \n";
                   print AGTLOG "Error while applying patch\n";
		   #return 1;
	   } 
	   open(INFILE,">$emState/agentpatch/$patchDir");  #creating a file with same name as patchdir in local host
	   close(INFILE);
           close(AGTLOG);
    }
  }


#
  if (-e "$emState/agentpatch/blackout") {

             logf(*OUTFILE, "Stopping the blackout");
             #print OUTFILE "Stopping the blackout\n";
             removeBlackOut($emState);
             #print OUTFILE "Removing the blackout file\n";
             #system("$emState/bin/emctl stop blackout agent");    
             
             #$exit_value  = $? >> 8;

             #if ( $exit_value eq  1) {
             #print OUTFILE "Error while stopping blackout \n";
             #  return 1;
             #}        
             #print OUTFILE "Removing the blackout file\n";
             #unlink("$emState/agentpatch/blackout");
   }
}
#--------------------------------------------------------------------------------

sub removeBlackOut
{
  my $emState=shift;

  system("$emState/bin/emctl stop blackout agent");

  my $exit_value  = $? >> 8;

  if ( $exit_value eq  1) {
      logf(*OUTFILE, "Error while stopping blackout");
      #print OUTFILE "Error while stopping blackout \n";
      return 1;
   }        
  unlink("$emState/agentpatch/blackout");
}

 
close(OUTFILE);

1;



