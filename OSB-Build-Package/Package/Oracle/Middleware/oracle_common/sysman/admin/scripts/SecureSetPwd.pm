#
#  $Header: SecureSetPwd.pm 20-aug-2004.14:23:50 rpinnama Exp $
#
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      SecureSetPwd.pm
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#       rpinnama 08/20/04 - Remove references to EMD ROOT 
#       rpinnama 08/26/03 - Use getConsoleClassPath 
#       rpinnama 07/30/03 - Fix em.jar
#       rpinnama 07/24/03 - grabtrans 'rpinnama_fix_2996670'
#       ggilchri 05/07/03 - use English
#       ggilchri 04/10/03 - create
#

#use English;
use strict;

package SecureSetPwd;

my $ORACLE_HOME       = $ENV{ORACLE_HOME};
my $JAVA_HOME         = $ENV{JAVA_HOME};

sub secureSetPwd
{
  my $securelog    = $_[0];
  my $authPassword = $_[1];
  my $newPassword  = $_[2];

  my $javaStr = "";
  my $classPath = &Secure::getConsoleClassPath("");
  my $rc;

  $javaStr = "$JAVA_HOME/bin/java ".
             "-cp $classPath ".
             "-DrepositoryPropertiesFile=$ORACLE_HOME/sysman/config/emoms.properties ".
             "oracle.sysman.eml.sec.InstallPassword ".
             "$authPassword $newPassword ".
             ">> $securelog";

  Secure::DEBUG (2, $securelog, "Executing .... $javaStr");

  $rc = 0xffff & system($javaStr);
  $rc >>= 8;
  if (not $rc eq 0 )
  {
    if (not $rc eq 2)
    {
      print ("Failed to reset Agent Registration Password.\n");
    }
    else
    {
      print ("Failed. Invalid sysman password.\n");
    }
  }
  return $rc;
}

sub displaySecureSetPwdHelp
{
  print "Help!\n";
}

1;
