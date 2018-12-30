#!/usr/local/bin/perl
# 
# $Header: omsstop.pl 27-apr-2005.06:32:55 ramalhot Exp $
#
# omsstop.pl
# 
# Copyright (c) 2004, 2005, Oracle. All rights reserved.  
#
#    NAME
#      omsstop.pl 
#
#    DESCRIPTION
#      Mail specified user that oms is stop
#
#    NOTES
#      can be run stand-alone for testing purposes
#
#    MODIFIED   (MM/DD/YY)
#    ramalhot    04/27/05 - renamed threaddump oms to dump omsthread 
#    aholser     04/26/05 - 
#    asawant     01/31/05 - Adding some tmp code to trace bug # 4135050 
#    aholser     05/11/04 - 
#    aholser     04/17/04 - aholser_bug-3016947 
#    aholser     04/17/04 - Creation
#

  system ("echo Entry");
  my $fn = "$ENV{ORACLE_HOME}/sysman/config/omsstop";
  system "date > $fn";
  if(!open(FH, ">>$fn")) 
  {
    system("echo Could not open $fn for error messages");
  }
  system ("echo outputfile=$fn");

  # Force a OMS Thread dump...
  print("Executing $ENV{ORACLE_HOME}/bin/emctl dump omsthread\n");
  if(system("$ENV{ORACLE_HOME}/bin/emctl dump omsthread 2>&1"))
  {
    print("Error calling emctl: $!\n");
  }

  my $subject="Enterprise Manager oms has been shut down";
  print FH "The Management Service in ORACLE_HOME $ENV{ORACLE_HOME} has been shut down.\n";

  if(!close FH) 
  {
    system("echo Could not close $fn");
  }

  my $filename="$ENV{ORACLE_HOME}/sysman/config/emoms.properties";
  system("echo filename=$filename");
  my $command1="cat $filename | grep 'em_oob_shutdown=' | grep -v '#' | sed s/em_oob_shutdown=// | awk '{print $1}'";
  my $isok=`$command1` or system("echo em_oob_shutdown not defined");
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
         $command1 = "`mail -s \"$subject\" $list \< $fn`";
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
