# $Header: sAgentUtils.pm 27-may-2008.21:16:34 apenmets Exp $
#
#
# Copyright (c) 2001, 2008, Oracle. All rights reserved.  
#
#    NAME
#      sAgentUtils.pm - OSD watchdog code.
#
#    DESCRIPTION
#       This script contains OSD code for e.g traceback generation from 
#       corefiles
#
#    MODIFIED   (MM/DD/YY)
#      apenmets  05/27/08 - Removing .threads file
#      vnukal    07/12/07 - Fix Bug 6203090. Traceback files for state agents
#      sksaha    11/04/04 - Add package info
#      sksaha    10/29/04 - Created

package sAgentUtils;
use EMAgent;
use EmctlCommon;

#
# sDebugCore
# sDebugCore is called when the monitor detects a core dump
# Parameter : CoreFile
#
sub sDebugCore
{
  $self = $_[0];
  $debugFile = $_[1];

  if($self->{initialized})
  {
    my($DBX) = "/usr/bin/gdb";

    if( -e $DBX )
    {
      my($traceBack) = $debugFile.".traceback";
      my($threads) = $debugFile.".threads";
      my($tempFile) = $debugFile.".tmp";
      my ($EMHOME) = $self->{emHome};

      #Delete old core files if neccessary
      EMAgent::deleteExtraAgentCores($EMHOME);

      if ( $^O eq "linux" )
      {
        # Create a tempFile for inputting gdb commands for core.threads file ...
        open TMPF, ">$tempFile";
        printf TMPF "info threads\n"                 .
                    "quit\n" ;
        close TMPF;

        system("$DBX $EMDROOT/bin/emagent $debugFile <$tempFile > $threads 2>&1");

        # Need to glob the threads file to gdb individual threads
        my(@perthreadinfo, @threadColumns, @threadNums);
        my($numOfThreads, $x) = 0;
        open (THREADFILE, $threads);
        while(<THREADFILE>)
        {
          my($line) = $_;
          chomp($line);

          if($line =~ /process/)
          {
            $numOfThreads++;
          }
        }
        close(THREADFILE);

        system("echo ============================ THREAD BY THREAD BACK TRACE IN CORE DUMP ======================= > $traceBack");

        # start a frest tempFile for backtrace
        open TMPF, ">$tempFile";
        for($x=1; $x <= $numOfThreads; $x++)
        {
          printf TMPF "echo ===================================== THREAD $x ============================================ \n";
          printf TMPF "thread $x\n"                 .
                      "where\n";
        }
        printf TMPF "quit\n";
        close TMPF;

        system("$DBX $EMDROOT/bin/emagent $debugFile <$tempFile >> $traceBack 2>&1");

        # Remove temporary command file
        unlink("$tempFile");
        unlink("$threads");
        return;
      }
    }
  }
}

1;
