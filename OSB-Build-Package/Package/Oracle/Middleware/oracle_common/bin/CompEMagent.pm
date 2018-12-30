#
# $Header: emagent/scripts/unix/CompEMagent.pm /st_emagent_10.2.0.1.0/11 2008/10/31 18:48:46 bkovuri Exp $
#
# CompEMagent.pm
#
# Copyright (c) 2002, 2008, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      CompEMagent.pm - Top level module for agent commands w.r.t emctl.
#
#    DESCRIPTION
#    Top level module that implements the agent opitons for emctl.
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    bkovuri    10/29/08 - Update copyright year - 7460158
#    njagathe   06/02/08 - Update version to 10.2.0.5
#    sunagarw   03/11/08 - XbranchMerge sunagarw_bug-5550295 from main
#    neearora   05/23/07 - changed version to 10.2.0.4.0
#    njagathe   02/23/07 - Update version to 10.2.4.0.0
#    schoudha   12/20/06 - Bug-5726004-Change banner for emctl
#    njagathe   11/03/06 - Update copyright year
#    smodh      07/20/06 - change version to 10.2.0.3.0
#    smodh      07/20/06 - Backport smodh_bug_4769194_agent from main 
#    kduvvuri   12/30/05 - XbranchMerge kduvvuri_bug-4893236 from main 
#    smodh      12/11/05 - change version to 10.2.0.2.0 
#    njagathe   10/27/05 - XbranchMerge njagathe_bug-4690651 from main 
#    kduvvuri   07/27/05 - space after the copy right. 
#    kduvvuri   07/25/05 - remove CFS_RAC. 
#    kduvvuri   07/25/05 - CFS_RAC banner is no longer used. 
#    kduvvuri   07/25/05 - banner gets cmd args. 
#    kduvvuri   07/12/05 - add banner. 
#    shianand   03/31/05 - Refactoring Secure Commands.
#    kduvvuri   07/28/04 - add getVersion.
#    kduvvuri   06/17/04 - launchComp moved to package launchEMagent.
#    kduvvuri   05/05/04 - created   

package CompEMagent;
use AgentLifeCycle;
use AgentStatus;
use AgentMisc;
use AgentSubAgent;
use EMAgent;
use EmCommonCmdDriver;
use EmctlCommon;
use SecureAgentCmds;
use File::Copy cp;


sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);

  #cmdList is a list containing all the command implementors.
  $self->{cmds} = [ AgentLifeCycle->new(), AgentStatus->new(), 
                    AgentMisc->new(),AgentSubAgent->new(),
                    SecureAgentCmds->new()];
  setEMHome(\@_);
  return $self;
}

sub doIT {
   my $self = shift;
   #print "from sub routine doIT of agent.pm ,  @_\n";
   $refCmds = $self->{cmds};
   $cmdDriver = EmCommonCmdDriver->new();  
   $result = $cmdDriver->doIT($refCmds, \@_);
   return $result;
}

sub usage {
  #print "This is usage from agent.pm\n";
  print "    Oracle Enterprise Manager 10g Agent Commands:\n"; 
  my $self = shift;
  $refCmds = $self->{cmds};
  $cmdDriver = EmCommonCmdDriver->new();
  $result = $cmdDriver->usage($refCmds, \@_); 
}

sub getVersion {
  #print "this is Version from CompEMagent.pm\n";
  my $self = shift;
  $refVars = [ EMAgent->new() ];
  $cmdDriver = EmCommonCmdDriver->new();
  $result = $cmdDriver->getVersion($refVars, \@_);
}

sub banner {
  my $self = shift;
  my $rargs = shift; #reference to command line args.

  print "Oracle Enterprise Manager 10g Release 5 Grid Control 10.2.0.5.0.  \n";
  print "Copyright (c) 1996, 2009 Oracle Corporation.  All rights reserved.\n";
  if($DEBUG_ENABLED)
  {
    print "NOHUP File is: $AGENT_NOHUPFILE \n";
  }

}

sub setEMHome {
  my $rargs = shift;
  $numargs = @$rargs;

  for ( $i = 0; $numargs>0 && $i < $numargs; $i++)
  {
    if($rargs->[$i] eq "-statedir" && (($i+1)<$numargs))
    {
      $ENV{'EMSTATE'}=$rargs->[$i+1];
      return;
    }
  }
}


1;
