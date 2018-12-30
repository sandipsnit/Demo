#!/usr/local/bin/perl
# 
# $Header: oui/OPatch/opatch.pl /main/18 2009/05/06 07:16:14 vganesan Exp $
#
# opatch.pl
# 
# Copyright (c) 2004, 2009, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      opatch.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      A wrapper perl script to invoke OPatch 10.2.
#
#    NOTES
#      Works only in -silent or -force mode
#
#    MODIFIED   (MM/DD/YY
#    phnguyen    02/06/09 - Remove references to bug ID.
#    vsriram     08/07/06 - Trap the error messages correctly.
#    vsriram     10/20/05 - Invoke opatch with live printing.
#    shgangul    07/29/04 - call opatch.bat instead of opatch.exe, 
#                           and parse the error code 
#    shgangul    07/27/04 - Creation
# 
######
#
# Standard modules:
#
use English;         # Let us say "$CHILD_ERROR" instead of "$?", etc.
use strict;          # Enforce strict variables, refs, subs, etc.
use File::Basename();
use File::Spec();

my $opatchScript;
# For windows opatch script is opatch.exe and for unix like env it is opatch
if ( $OSNAME =~ m#Win# )
{
    $opatchScript = File::Spec->catfile(File::Basename::dirname($PROGRAM_NAME), "opatch.bat");
}
else
{
    $opatchScript = File::Spec->catfile(File::Basename::dirname($PROGRAM_NAME), "opatch");
}

my $systemCommand = $opatchScript;

# Invoke OPatch only in -silent or in -force mode for this script
my $isApply = 0;
my $isRollback = 0;
my $isSilent = 0;
my $isForce = 0;
foreach my $arg (@ARGV)
{
    if ($arg eq "apply") 
    {
        $isApply = 1;
    }
    if ($arg eq "rollback") 
    {
        $isRollback = 1;
    }
    if ($arg eq "-silent") 
    {
        $isSilent = 1;
    }
    if ($arg eq "-force") 
    {
        $isForce = 1;
    }
    $systemCommand = $systemCommand . " " . $arg;
}

# Exit gracefully for apply and rollback without -force or -silent
if ((($isApply == 1) || ($isRollback == 1)) && 
    ($isSilent != 1) && ($isForce != 1))
{
    print "This script can be invoked only in -silent mode... exiting\n";
    exit 1;
}

# Execute opatch with the specified options
#my $scriptResult = qx/$systemCommand/;

my $scriptResult = "";
open(READ, "$systemCommand 2>&1 | ");
while (<READ>) {
      print $_;
      $scriptResult = $scriptResult . $_ ;
}
close(READ);

my $childError = 0;
if ( $OSNAME =~ m#Win# )
{
    ( $childError ) = ( $scriptResult =~ m#.*OPatch failed with error code = (\d+).*# );
    if ( $childError !~ m#(\d+)# )
    {
        $childError = 0;
    }
}
else
{
    $childError = $CHILD_ERROR >> 8;
}

#print $scriptResult;
exit $childError;
