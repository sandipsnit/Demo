# $Header: nfsagentupdate.pl 06-sep-2007.23:28:19 lihliu Exp $
#
# nfsagentupdate.pl
#
# Copyright (c) 2005, 2006, Oracle. All rights reserved.  
#
#    NAME
#      nfsagentupdate.pl - script used in NFS Install for Agent Push
#
#    DESCRIPTION
#    Enterprise Manager Agent deployment
#    This script is used to update the agent config once the NFS installation is done. 
#    Right now it is used for updating timezone, it can be extended for any other update as well.
#
#
#    MODIFIED   (MM/DD/YY)
#    lihliu      09/06/07 - 
#    supchoud    12/11/06 - fix 5707211
#    phshah      07/27/06 - XbranchMerge phshah_bug-5338419 from main 
#    phshah      07/14/06 - fix 5191641 
#    phshah      12/01/05 - Creation
#    phshah      01/09/06 - fix 4932625
#

if ($#ARGV < 3){
    usage();
}
$NOVAL = "__NO__VAL__";
$statedir = $NOVAL;
$timezone = $NOVAL;
$nfs_loc = $NOVAL;
$rspfile = $NOVAL;

$config_agent = "false";
$update_tz = "false";

if( $ARGV[0] eq "-h" ) {
    usage();
}
if ( $ARGV[0] eq "-p" ){
	if ( $ARGV[1] eq "-s" ) {
            $statedir =  $ARGV[2];
        }
        if ( $ARGV[3] eq "-s" ) {
            $statedir =  $ARGV[4];
        }
        if ( $ARGV[1] eq "-n" ) {
            $nfs_loc =  $ARGV[2];
        }
        if ( $ARGV[3] eq "-n" ) {
            $nfs_loc =  $ARGV[4];
        }
        if ( $ARGV[5] eq "-r" ) {
            $rspfile =  $ARGV[6];
        }
        if ( $statedir eq $NOVAL || $nfs_loc eq $NOVAL  ) {
            usage();
        }
	$config_agent = "true";
} else {
	if ( $ARGV[0] eq "-s" ) {
	    $statedir =  $ARGV[1];
	}
	if ( $ARGV[2] eq "-s" ) {
	    $statedir =  $ARGV[3];
	}
	if ( $ARGV[0] eq "-z" ) {
	    $timezone =  $ARGV[1];
	}
	if ( $ARGV[2] eq "-z" ) {
	    $timezone =  $ARGV[3];
	}
	if ( $statedir eq $NOVAL ) {
	    usage();
	}
        if ( $timezone eq $NOVAL ) {
            print("No TZ passed by the user, no update TZ is required.\n");
            exit;
        }

	$update_tz = "true";
}

print "The statedir is $statedir\n";
print "The nfs agent loc is $nfs_loc\n";

if ( $config_agent eq "true" ){
	config_agent();
}
if ( $update_tz eq "true" ){
	update_tz();
}

sub update_tz() {

    if ( $timezone ne $NOVAL ) {
        print "Updating timezone...\n";
        # Set the timezone environment variable to the one which used passed.
        $ENV{'TZ'} = $timezone;
    }
    #Update agent config to have same timezone value.
    system("$statedir/bin/emctl config agent updateTZ") && die("Command to update TZ exited with status : $?");

}

sub config_agent(){
    print "Configuring agent\n";
    print "Value of rsp file: $rspfile \n";
    system("$nfs_loc/jdk/bin/java -classpath $nfs_loc/oui/jlib/emCfg.jar:$nfs_loc/oui/jlib/xml.jar:$nfs_loc/oui/jlib/xmlparserv2.jar:$nfs_loc/oui/jlib/ojmisc.jar:$nfs_loc/sysman/jlib/agentPlug.jar oracle.sysman.emCfg.common.EmCfgActionPerform -oracleHome $statedir  -descriptionPath install -instancePath install -actionType custom:nfsagent -aggregateID oracle.sysman.top.agent -responseFile $rspfile -requestType 1 -debug") && die("Command to configure agent exited with status : $?");
}

sub usage() {
    print "To update timezone: perl nfsagentupdate.pl -s <state dir> -z <TZ> \n";
    print "To configure agent: perl nfsagentupdate.pl -p -s <state dir> -n <nfs_loc> \n";
    exit;
}
