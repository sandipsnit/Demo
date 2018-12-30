#
# $Header: EmCommonCmdDriver.pm 12-jul-2005.12:31:59 kduvvuri Exp $
#
# EmCommonCmdDriver.pm
#
# Copyright (c) 2002, 2005, Oracle. All rights reserved.  
#
#    NAME
#      EmCommonCmdDriver.pm - command driver module for emctl.
#
#    DESCRIPTION
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    kduvvuri   07/12/05 - provision for common exit code from top level 
#                          emctl.pl 
#    kduvvuri   06/01/04 - use instead of require.
#    kduvvuri   05/05/04 - created
package EmCommonCmdDriver;
use EmctlCommon;
sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);
  return $self;
}
sub doIT {
   
   #print "From EmCommonCmdDrvier  @_\n"; 
   $classname = shift;
   #print "EmCommonCmdDriver class name is $classname\n";
   ( $rcmds, $rargs ) = @_;
   $rresult = $EMCTL_BAD_USAGE; 
   #print "From EmCommonCmdDriver command line args are.., ... @$rargs\n";
   $numCmds = @$rcmds;
   #print "numCmds is $numCmds\n";
   for ( $i = 0; $i < $numCmds; $i++) {
      #$rargs is a reference to args.
      
      $rresult = ($rcmds->[$i])->doIT($rargs);
      $resultType = ref($rresult);
      if ( $resultType eq "ARRAY")
      {
        $result = $rresult->[0];
        $exitCode = $rresult->[1];
      }
      else
      {
        $result = $rresult;
      }
      if ( $result == $EMCTL_DONE )
      {
         return $rresult;
      }
      elsif  ( $result == $EMCTL_BAD_USAGE )
      {
        ($rcmds->[$i])->usage();
        return $rresult;
      }
      elsif ( $result == $EMCTL_UNK_CMD )
      {
         next;  # go to next command.
      }
      
   }
   return $rresult;
}

sub usage
{
  $classname = shift;
  #print "In usage of Common\n";
   #rcmds is a referrence to an array consisting of individual command
   #implementors.
   ( $rcmds, $rargs ) = @_;
   $numCmds = @$rcmds;
   for ( $i = 0; $i < $numCmds; $i++ )
   {
     ($rcmds->[$i])->usage();
   }
}

sub getVersion
{
  $classname = shift;
   #rcmds is a referrence to an array consisting of individual command
   #implementors.
   ( $rcmds, $rargs ) = @_;
   $numCmds = @$rcmds;
   for ( $i = 0; $i < $numCmds; $i++ )
   {
     ($rcmds->[$i])->getVersion();
   }
}

1;
