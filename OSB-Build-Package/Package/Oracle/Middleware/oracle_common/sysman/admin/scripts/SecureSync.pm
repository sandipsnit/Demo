#
#  $Header: SecureSync.pm 20-aug-2004.14:25:46 rpinnama Exp $
#
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      SecureStatus.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       rpinnama 08/20/04 - Remove references to EMD ROOT 
#       rpinnama 08/27/03 - Use getConsoleClassPath 
#       rpinnama 07/30/03 - Fix em.jar
#       rpinnama 07/24/03 - grabtrans 'rpinnama_fix_2996670'
#       ggilchri 04/10/03 - create
#

use English;
use strict;


package SecureSync;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};
my $IS_WINDOWS        ="";

sub secureSync
{
  my $securelog = $_[0];
  my $javaStr   = "";
  my $classPath = "";
  my $rc;

  $classPath = &Secure::getConsoleClassPath("");

  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DrepositoryPropertiesFile=$ORACLE_HOME/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.InstallPassword -auth nopassword ".
             ">> $securelog";
  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if (not $rc eq 2 )
  {
    print ("   Done.\n");
  }
  else
  {
    print ("   Failed.\n");
  }
  return $rc;
}

sub displaySecureSyncHelp
{
  print "Help!\n";
}

1;
