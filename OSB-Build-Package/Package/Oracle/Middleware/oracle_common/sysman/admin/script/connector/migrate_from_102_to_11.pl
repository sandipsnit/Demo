#!/usr/local/bin/perl
# 
# $Header: migrate_from_102_to_11.pl 08-apr-2008.16:19:03 zmi Exp $
#
# migrate_from_102_to_11.pl
# 
# Copyright (c) 2007, 2008, Oracle. All rights reserved.  
#
#    NAME
#      migrate_from_102_to_11.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    zmi         04/08/08 - bug 6952417.
#    yangwang    01/10/08 - bug 6734208.
#    yangwang    10/18/07 - Creation
# 

use File::Find;
use File::Copy;
use File::Basename;
use Getopt::Long;

my $oracleHome	    =   '';
my $oldOracleHome   =   '';
my $reposUsername        =   '';
my $reposPasswd       =   '';
my $masUsername     =   '';
my $masPasswd       =   '';
my $errorMessage    =   '';
my $connectionString = "";

optionProcess();

my $cntrdir         =	"$oracleHome/sysman/connector";
my $oldcntrdir      =   "$oldOracleHome/sysman/connector";

my $remedycntrname      =   "Remedy Connector";
my $remedycntrfolder    =   $remedycntrname;
my $remedyDeployFile    =   "RemedyDeploy.xml";
$remedycntrfolder       =~  s/ /_/g;

my $momcntrname      =   "Microsoft Operations Manager Connector";
my $momcntrfolder    =	$momcntrname;
$momcntrfolder       =~  s/ /_/g;    
my $oldcntrversion = "10.2";

my $INBOUND = 1;
my $OUTBOUND = 2;
my $XML_OUTBOUND = 3;

copyToNewDir($oldcntrdir, $cntrdir);

migrateData("$cntrdir");

exit 0;

#
# useage
#
sub printUsage{
    print "migrate_from_102_to_11.pl -oh [oracle_home] -old_oh [old_oracle_home] -cs [connection string] -repos_user [repos_user] -repos_pwd [repos_password] -mas_user [mas username] -mas_pwd [mas password]\n";
}

sub optionProcess{
    #Read options
    my $opt_repos_name = '';
    my $opt_repos_password = '';
    my $opt_mas_name = '';
    my $opt_mas_password = '';
    GetOptions (
        'oh=s' => \$oracleHome,
        'old_oh=s' => \$oldOracleHome,
        'cs=s' => \$connectionString,
        'repos_user=s' => \$opt_repos_name,
        'repos_pwd=s' => \$opt_repos_password,
        'mas_user=s' => \$opt_mas_user,
        'mas_pwd=s' => \$opt_mas_password
    );
    if(not $oracleHome)
    {
        if($ENV{ORACLE_HOME})
        {
            $oracleHome = $ENV{ORACLE_HOME}
        }
        else
        {
            $errorMessage = $errorMessage."Couldn't read Oracle Home from environment. Please use -oh to specify.\n";
        }
    }
    if(not $oldOracleHome)
    {
        $errorMessage = $errorMessage."-old_oh is required.\n";
    }
    if(not $connectionString){
        $errorMessage = $errorMessage."-cs is required.\n";
    }
    
    if($opt_repos_name)
    {
        $reposUsername = $opt_repos_name;
    }
    else{
        $reposUsername = 'sysman';
    }
    if($opt_repos_password)
    {
        $reposPasswd = $opt_repos_password;
    }
    else{
        print("\n Please enter the $reposUsername password: ");
        system("stty -echo");
        $reposPasswd = <STDIN>;
        chomp $reposPasswd;
        print("\n");
        system("stty echo");
    }
    if($opt_mas_name)
    {
        $masUsername = $opt_mas_name;
    }
    else{
        $masUsername = 'fmwadmin';
    }
    if($opt_mas_password)
    {
        $masPasswd = $opt_mas_password;
    }
    else{
        print("\n Please enter the $masUsername password: ");
        system("stty -echo");
        $masPasswd = <STDIN>;
        chomp $masPasswd;
        print("\n");
        system("stty echo");
    }
    
    if($errorMessage)
    {
        print("Error:\n$errorMessage\n");
        printUsage();
        exit;
    }
}

sub mvfolder{
    my($cntrdir) = @_;
    my $newcntrdir = "$cntrdir/$oldcntrversion";
    my $tempcntrdir = "$cntrdir"."_bak";
    print "Move 10g file into $newcntrdir.\n";
    rename("$cntrdir", "$tempcntrdir") || die "Error occured while moving $cntrdir to $tempcntrdir:$!";
    mkdir("$cntrdir", 0740) || die "Cannot mkdir $cntrdir: $!";
    rename("$tempcntrdir", "$newcntrdir") || die "Error occured while moving $tempcntrdir to $newcntrdir:$!";
}

#
#copy the entire connector dir from the old oraclehome to the new oraclehome
#
sub copyToNewDir{
    my ($argv1, $argv2) = @_;
    my @old = ($argv1);
    my $new = $argv2;
    my $baselength = length($argv1);
    
    print "Copy file(s) and folder(s) from $argv1 to $argv2\n";

    sub doCopy{
        my $origname = $File::Find::name;
        my $namelength = length($origname);
        my $name = substr($origname, $baselength+1, $namelength);
        #print "$name\n";
        if(length($name) == 0){
            unless (-d $new){
                mkdir($new, 0740);
            }
        }
        elsif(-d $origname){
            unless (-d "$new/$name"){
                mkdir("$new/$name", 0740);
            }
        }
        else{
            unless (-f "$new/$name"){
                copy($origname, "$new/$name");
            }
        }    
    }
    
    find (\&doCopy, @old);
}

#
#handling every connector existed in the connector folder. 
#
sub migrateData{
    my ($dir) = @_;
    my $flag = 0;
    my $remedyflag = 0;
    my $momgflag = 0;
    
    opendir(DIR, $dir) or die "Cannot access $dir : $!";
    while (my $file = readdir(DIR)) {
        next if $file =~ /^\.\.?$/;  # skip . and ..
        if((-d "$dir/$file") && ($file ne "common")){
            mvfolder("$dir/$file");
        }
    }
    closedir(DIR);

    open(FD, "emctl get_connectors connector -cs $connectionString -repos_user $reposUsername -repos_pwd $reposPasswd -mas_user $masUsername -mas_pwd $masPasswd|");
    while(<FD>) {
        my($line) = $_;
        chop $line;
        if($flag){
            my $index = rindex $line,",";
            my $category = substr($line, $index+1);
            $line = substr($line, 0, $index);
            $index = rindex $line,",";
            my $cntrname = substr($line, $index+1);
            my $cntrtypename = substr($line, 0, $index);
           
            my $cntrfolder = $cntrtypename;
            $cntrfolder =~  s/ /_/g;
            if($category eq "TicketingConnector"){
                handleTicketingCntr($cntrfolder, $cntrtypename, $cntrname);
                if ($cntrtypename eq "Remedy Connector"){
                    $remedyflag = 1;
                }
            }
            elsif($category eq "EventConnector"){
                handleEventCntr($cntrfolder, $cntrtypename, $cntrname);
                if($cntrtypename eq "Microsoft Operations Manager Connector"){
                    $momflag = 1;
                }
            }
        }
        elsif($line eq "#"){
            $flag = 1;
        }
        
    }
    close(FD);

    #
    # if $remedyflag = 0 means no remedy connector is registered, so deploy remedy connecotr.
    # the same happens to mom connector
    #
    if($remedyflag == 0){
        print "Deploying Remedy connector...\n";
        $status = system("perl $oracleHome/sysman/plugins/connector/install_remedycntr.pl -dd $remedyDeployFile -cs $connectionString -repos_user $reposUsername -repos_pwd $reposPasswd -mas_user $masUsername -mas_pwd $masPasswd");
    }
    
    if($momflag == 0){
        print "Deploying Microsoft Operations Manager connector...\n";
        $status = system("perl $oracleHome/sysman/plugins/connector/install_momcntr.pl -cs $connectionString -repos_user $reposUsername -repos_pwd $reposPasswd -mas_user $masUsername -mas_pwd $masPasswd");
    }
}

sub handleTicketingCntr{
    
    my($cntrfolder, $cntrtypename, $cntrname)         =   @_;
    my $status = 0;
    
    print "Checking $cntrdir/$cntrfolder...\n";
    
    if(-d "$cntrdir/$cntrfolder/$oldcntrversion"){
        $status = system("$oracleHome/bin/emctl register_template connector -t $cntrdir/$cntrfolder/$oldcntrversion/createTicketResponse.xsl -cs $connectionString -repos_user $reposUsername -repos_pwd $reposPasswd -ctname \"$cntrtypename\" -cname \"$cntrname\" -tname \"Create Ticket Response\" -iname \"createTicket\" -ttype $INBOUND -d \"Create ticket response transformation.\"");
        $status = $status>>8;
        if($status != 0){
            print("Error occured while registering the template: createTicketResponse.xsl\n");
            return $status;
        }
        
        $status = system("$oracleHome/bin/emctl register_template connector -t $cntrdir/$cntrfolder/$oldcntrversion/getTicket_response.xsl -cs $connectionString -repos_user $reposUsername -repos_pwd $reposPasswd -ctname \"$cntrtypename\" -cname \"$cntrname\" -tname \"Get Ticket Response\" -iname \"getTicket\" -ttype $INBOUND -d \"Get ticket response transformation.\"");
        $status = $status>>8;
        if ($status != 0)   
        {
            print("Error occured while registering the template: getTicket_response.xsl\n");
            return $status;
        }
            
        $status = system("$oracleHome/bin/emctl register_template connector -t $cntrdir/$cntrfolder/$oldcntrversion/getTicket_request.xsl -cs $connectionString -repos_user $reposUsername -repos_pwd $reposPasswd -ctname \"$cntrtypename\" -cname \"$cntrname\" -tname \"Get Ticket Request\" -iname \"getTicket\" -ttype $OUTBOUND -d \"Get ticket request transformation.\"");
        $status = $status>>8;
        if ($status != 0)
        {
            print("Error occured while registering the template: getTicket_request.xsl\n");
            return $status;
        }
    }
    
    return $status;
}

sub handleEventCntr{
    
    my $status = 0;
    my($cntrfolder, $cntrtypename, $cntrname)         =   @_;
    
    print "Checking $cntrdir/$cntrfolder ...\n";
    
    if(-d "$cntrdir/$cntrfolder/$oldcntrversion"){
        my $newcntrdir = "$cntrdir/$cntrfolder/$oldcntrversion";
        $status = system("perl $oracleHome/sysman/plugins/connector/install_eventcntr_registertemplate.pl $newcntrdir $connectionString $reposUsername $reposPasswd $oracleHome \"$cntrtypename\" \"$cntrname\"");
        $status = $status >> 8;
        if ($status != 0){
            return $status;
        }        
    }
    return $status;
}