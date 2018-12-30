#!/usr/bin/perl

#check if a system variable EMSTATE exists if not then exit. 
#check if ORACLE_HOME/agentpatches/patchstarted, this is present.
#if does not exists the return 0;
#create $EMSTATE/agentpatch/blackout file.
#stop agent bu executing $EMSTATE/bin/emctl stop agent
#loop through till the $ORACLE_HOME/agentpatches/patchstarted exists
#if the $ORACLE_HOME/agentpatches/patchstarted does not exists, start detached process 
#to start the agent.
#kill the watch dog with exit command.


use English;
use File::Path;
use Config;

#-------------------------------------------------------------------------------

#======================================================================
# logf(<message>)
#
# Display the message with timestamp
#
#======================================================================
sub logf
{
    local (*outFile) = $_[0];
    my $msg = $_[1];

    printf(outFile "\n%s - %s\n", scalar(localtime()), $msg);
}


sub patchPlug {


$debug = 0;
$OraHome=$ENV{ORACLE_HOME};
$emState=$ENV{EMSTATE};
open(OUTFILE,">>$emState/sysman/log/nfsPatchPlug.log");

#------------ Finding OS---------------------------
$OSNAME = $Config{'osname'};
$IsWin32 = ($OSNAME eq 'MSWin32' || $OSNAME eq 'Windows_NT') ;



#-------------checking whether Master agent is getting patched-----------------
if ( -d "$OraHome/agentpatch" ) {
	 if ( ! -e "$OraHome/agentpatch/patchstarted") {
		 if ($debug) {
			 print "Master Agent is not getting patched";
		 }
		 return 0;
	 }
}
else {
  	 if ($debug) {
		print "Master Agent is not getting patched";
	 }
		 return 0;
}

#-- if agentpatch dir does not exists then create in state dir of NFS Agent----

if (! -d "$emState/agentpatch") {
         mkpath( "$emState/agentpatch" );
}

#------start the blackout on the agent--------------------------------------

        logf(*OUTFILE, "Starting Agent blackout...");
        #print OUTFILE "Starting Agent blackout...\n";
	system( "$emState/bin/emctl start blackout agent" );
        $exit_value  = $? >> 8;
        if( $exit_value eq  1) {
          return  1;   
       }
              
#--------create a blackout file in $emState/agentpatch-------------------

logf(*OUTFILE, "creating a blackout file: $emState/agentpatch/blackout");
#print OUTFILE "creating a blackout file\n";
open(TEMPFILE,">$emState/agentpatch/blackout");
close(TEMPFIE);



logf(*OUTFILE, "Stopping agent and launching patch watchdog ...");
#print OUTFILE "Exiting from the watchDog and starting the agent";
#if the Master Agent is getting patched,we starting a different process to start agent--------


my $retStatus = 0;

 $retStatus = system ( "$emState/bin/emctl stop agent" ); 
 $retStatus = $retStatus>>8;
 logf(*OUTFILE, "Patching watchdog launched, Agent stopped (Status = $retStatus))"); 
 close(OUTFILE);


#Launch patching watchdog as background process
if ($IsWin32) {
   exec ( "$OraHome/bin/patchnfs.bat" );
}
else {
   exec ( "sh $OraHome/bin/patchnfs.sh &" );
}


# On Windows, it is observed that as soon as the exit statement is executed,
# then agent service is getting stopped automatically.
 exit;


}

1;
