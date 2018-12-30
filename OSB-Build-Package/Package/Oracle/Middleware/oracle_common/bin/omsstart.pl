#!/usr/local/bin/perl
# 
# $Header: omsstart.pl 26-apr-2005.14:44:14 aholser Exp $
#
# omsstart.pl
# 
# Copyright (c) 2004, 2005, Oracle. All rights reserved.  
#
#    NAME
#      omsstart.pl 
#
#    DESCRIPTION
#      mail specified user that oms has started
#
#    NOTES
#      can be run stand-alone for testing purposes
#
#    MODIFIED   (MM/DD/YY)
#    aholser     04/26/05 - 
#    aholser     05/11/04 - 
#    aholser     04/17/04 - aholser_bug-3016947 
#    aholser     04/17/04 - Creation
# 

  system ("echo Entry");
  my $fn = "$ENV{ORACLE_HOME}/sysman/config/omsstart";
  system "date > $fn";
  if(!open(FH, ">>$fn")) 
  {
    system("echo Could not open $fn for error messages");
  }
  system ("echo outputfile=$fn");
  my $subject="Enterprise Manager oms has been started";
  print FH "The Management Service in ORACLE_HOME $ENV{ORACLE_HOME} has been started.\n";

  if(!close FH) 
  {
    system("echo Could not close $fn");
  }

  my $filename="$ENV{ORACLE_HOME}/sysman/config/emoms.properties";
  system("echo filename=$filename");
  my $command1="cat $filename | grep 'em_oob_startup=' | grep -v '#' | sed s/em_oob_startup=// | awk '{print $1}'";
  my $isok=`$command1` or system("echo em_oob_startup not defined");
  system("echo isok=$isok");
  chomp($isok);
  if ( "$isok" ne "true" )
  {
     system("echo isok is null");
     exit;
  }
  my $command1="cat $filename | grep 'em_email_address=' | grep -v '#' | sed s/em_email_address=// | awk '{print $1}'";
  system("echo list command1=$command1");
  my $list=`$command1` or system("echo em_email_address is not correctly defined in $filename");
  $command1="cat $filename | grep 'em_from_email_address=' | grep -v '#' | sed s/em_from_email_address=// | awk '{print $1}'";
  system("echo return command1=$command1");
  my $return=`$command1` or system("echo em_from_email_address is not correctly defined in $filename");
  my $out;
  chomp($return);
  chomp($list);
  system("echo list=$list");
  system("echo return=$return");

  if ( "$list" ne "" ) 
  {
    if ("$return" eq "" ) 
    {
      if($ENV{OSTYPE} eq "linux")
      {
         $command1 = "`mail -s \"$subject\" $list < $fn`";
      }
      else
      {
         $command1 = "`mailx -s \"$subject\" $list \< $fn`";
      }
      system($command1);
    } 
    else 
    {
      if($ENV{OSTYPE} eq "linux")
      {
         $command1 = "`mail -s \"$subject\" $list < $fn`";
      }
      else
      {
         $command1 = "`mailx -s \"$subject\" -r $return $list < $fn`";
      }
      system($command1);
    }
  }
