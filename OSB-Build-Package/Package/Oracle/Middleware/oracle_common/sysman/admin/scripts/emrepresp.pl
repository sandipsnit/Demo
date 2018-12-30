#  $Header: emagent/sysman/admin/scripts/emrepresp.pl /st_emagent_10.2.0.1.0/4 2009/01/13 17:42:14 mveena Exp $
#
# Copyright (c) 2001, 2009, Oracle and/or its affiliates.All rights reserved. 
#
#    NAME
#      emrepresp.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      It connects to a database, executes a user-defined SQL
#      and reports success/failure and response time.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#      mveena   01/09/09 - fix for bug 7695901
#      tsubrama 07/30/08 - using plsql function instead of direct queries bug#7277905
#      tsubrama 05/17/07 - fix for referring emrepdown.pl path and remvoing double quotes in subject,msg
#      aholser  10/21/03 - remove tracing pwd 
#      aholser  10/18/03 - 
#      aholser  08/20/03 - add metric eval job check
#      aholser  04/15/03 - 
#      aholser  03/13/03 - use perl script for mail
#      aholser  11/23/02 - use connectdescriptor
#      aholser  07/15/02 - oob notification
#      aholser  07/12/02 - aholser_bug-2445264_main
#      aholser  07/11/02 - Creation
#

use strict;
use Oraperl;
use Time::HiRes;
use DBI;
use DBD::Oracle qw(:ora_types);

require "emd_common.pl";
require "semd_common.pl";

my $targetname = "";
my $db_connect = "";
EMD_PERL_DEBUG("Connectdescriptor $ENV{CONNECTDESCRIPTOR}");
if ( $ENV{CONNECTDESCRIPTOR} ne "" )
{
  #$db_connect = $ENV{EM_REPOS_USER} . "/" . $ENV{EM_REPOS_PWD} . "@" . $ENV{CONNECTDESCRIPTOR};
  $db_connect = $ENV{CONNECTDESCRIPTOR};
  $targetname = $ENV{EM_REPOS_USER}."test";
}
else
{
  #$db_connect = $ENV{EM_REPOS_USER} . "/" . $ENV{EM_REPOS_PWD} . "@" . $ENV{EM_TARGET_ADDRESS};
  $db_connect = $ENV{EM_TARGET_ADDRESS};
  $targetname = $ENV{SID}.$ENV{PORT};
}


### find out the perl modules path
#my $mod;
#foreach $mod ( keys %INC ) {
#  EMD_PERL_DEBUG( "path of the modules $mod ---> $INC{$mod} \n");
#}

my $start_time = Time::HiRes::time;
my $fn = get_tmp_filename ($targetname, "emrepresp");
EMD_PERL_DEBUG("$targetname, $fn");

########## Using DBI to execute the stored procedure and get the required data ####
my $DB_Connection = DBI->connect("dbi:Oracle:$db_connect",
     $ENV{EM_REPOS_USER},
     $ENV{EM_REPOS_PWD},
    {
       RaiseError =>0
    }
);

if( !$DB_Connection ) {
   EMD_PERL_DEBUG("Getting repository connection failed. Error: $DBI::errstr $DBI::err $DBI::state");
   print "em_result=0|Enterprise Manager Repository database is down. Error: $DBI::errstr\n$db_connect";
   processfailure("Could not connect to Enterprise Manager Repository database: $DBI::errstr");
   exit 0;
}

my $oms_up_count;
my $total_oms_count;
my $repos_job_broken_count;
my $repos_job_schedule;


eval {
    my $data_cursor;
    $DB_Connection->{RaiseError} = 1;
    my $prepare_stmt = $DB_Connection->prepare(q{
        BEGIN
           :data_cursor := mgmt_emrep_oob_monitoring.GET_OOB_DATA_FOR_STATUS();
        END;
    });
   $prepare_stmt->bind_param_inout(":data_cursor", \$data_cursor, 0, { ora_type => ORA_RSET });
   $prepare_stmt->execute;

   my @row_data;
   @row_data = $data_cursor->fetchrow_array;

   EMD_PERL_DEBUG("data from repository... @row_data");

   my $arry_size = scalar(@row_data);
   if($arry_size>=4){
      $oms_up_count = $row_data[0];
      $total_oms_count = $row_data[1];
      $repos_job_broken_count = $row_data[2];
      $repos_job_schedule = $row_data[3];
   }

  #my $close_cur = $DB_Connection->prepare("BEGIN CLOSE :cursor; END;");
  #$close_cur->bind_param_inout(":cursor", \$data_cursor, 0, { ora_type => ORA_RSET } );
  #$close_cur->execute;
};


if( $@ ) {
  my $err_msg =  $DBI::errstr;

  ## check whether error is for plsql package/function not available.
  if(index($err_msg,"ORA-06550:")>-1){

     EMD_PERL_DEBUG("Getting data from repository failed. Check OMS version compatibility. Error: $err_msg $DBI::err $DBI::state");
     print "em_result=0|Enterprise Manager Repository database is down. Could not retrieve data. Error: $err_msg\n";
     processfailure("Oracle Management Service version is not compatible with the version of Monitoring Agent for Out Of Band Notification.");
     close_dbconnection($DB_Connection);
     exit 0;

  }else{ ## any other errors.

    EMD_PERL_DEBUG("Getting data from repository failed. Error: $err_msg $DBI::err $DBI::state");
    print "em_result=0|Enterprise Manager Repository database is down. Could not retrieve data. Error: $err_msg\n";
    processfailure("Could not get data from Enterprise Manager Repository database: $err_msg");
    close_dbconnection($DB_Connection);
    exit 0;

  }

}

## close the db connection after getting the data.
close_dbconnection($DB_Connection);

#################### OMSs availability checking #######################

EMD_PERL_DEBUG("Total OMSs=$total_oms_count; Active OMSs=$oms_up_count");
if($oms_up_count == 0)
{
   if($total_oms_count > 1){
      EMD_PERL_DEBUG("All Management Services are down");
      print ("em_result=0|All Management Services are down\n");
      processfailure("All Management Services are down");
   }else{
      EMD_PERL_DEBUG("Management Service is down");
      print ("em_result=0|Management Service is down\n");
      processfailure("Management Service is down");
   }
   exit 0;
}

################ Repository Metrics Collection Job Status checking ########

if($repos_job_broken_count > 0)
{
   EMD_PERL_DEBUG("Repository Metrics Collection Job is broken");
   print ("em_result=1|Repository Metrics Collection Job is broken\n");
   processfailure("Repository Metric Collection Job is broken");
   exit 0;
}

my $schdle = 1/12;
# round the value to 4 decimal places
$schdle = sprintf("%.4f", $schdle);

if(($repos_job_schedule > $schdle) || ($repos_job_schedule < -365))
{
   EMD_PERL_DEBUG("Repository Metrics Collection Job is broken - schedule is invalid");
   print ("em_result=1|Repository Metrics Collection Job is broken - schedule is invalid\n");
   processfailure("Repository Metrics Collection Job is broken - schedule is invalid");
   exit 0;
}


##############################################################################
# remove the old fail file if it exists
# unlink("emrepfail.lk");
unlink($fn);

if($oms_up_count>1){
  print ("em_result=1|$oms_up_count Management Services are active\n");
}else{
  print ("em_result=1|$oms_up_count Management Service is active\n");
}

exit 0;

sub close_dbconnection
{
   my $l_conn = $_[0];
   $l_conn->disconnect if ($l_conn);
   EMD_PERL_DEBUG("closing connection");
   my $end_time = Time::HiRes::time;
   my $logon_time = ($end_time - $start_time) * 1000;
   EMD_PERL_DEBUG("emrepresp: Time in emrepresp: $logon_time" );

}

sub processfailure
{
   # get the currently executing file with full path.
   my $thisFileWithPath = $0;
   # replace the currently executing file name with emrepdown.pl
   $thisFileWithPath=~ s/emrepresp.pl/emrepdown.pl/ig;

   my $mailscript = $thisFileWithPath;
   my $exists = -e $fn;
   my $mailscriptexists = -e $mailscript;
   my $accesstime = -M $fn;
   my $interval = 1/24;
   my $home = $ENV{ORACLE_HOME};
   EMD_PERL_DEBUG("exists=$exists, accesstime=$accesstime, interval=$interval mailscriptexists=$mailscriptexists" );

   # Email is sent if the error is new ($fn doesn't exist) or more than one hour has elapsed.
   if(($exists < 1) || ($accesstime > $interval))
   {
      if($exists > 0)
      {
         unlink($fn);
      }

      open(FILE, ">".$fn);
      print FILE scalar localtime;
      close(FILE);
      # if emrepdown.pl is not in our path, try to locate it at install and development locations
      # with oracle_home.  if we can't find it, log an error and exit
      if($mailscriptexists < 1)
      {
         if( $home ne "" )
         {
            $mailscript =  "$home/bin/emrepdown.pl";
            $mailscriptexists = -e $mailscript;
            if($mailscriptexists < 1)
            {
               $mailscript =  "$home/emagent/sysman/admin/scripts/emrepdown.pl";
               $mailscriptexists = -e $mailscript;
               if($mailscriptexists < 1)
               {
                  EMD_PERL_DEBUG("Can't locate emrepdown.pl script: ORACLE_HOME=$home - exiting");
                  return;
               }
            }
         }
      }

      {
         local @ARGV;

         my ($message) = @_;

         $ARGV[0] = $message;
         $ARGV[1] = "Severe Oracle Enterprise Manager problem";

         EMD_PERL_ERROR("emrepresp: processfailure $mailscript, Message:$ARGV[0], Subject:$ARGV[1]");

         #since ARGV is local variable,it's values are directly accessible in the mailscript.
         #The do() method executes the contents of the file as a Perl script.
         do($mailscript);

      }

      close(FH);
      return;
  }
  EMD_PERL_DEBUG("processfailure $fn already exists");
}

