# 
# $Header: EMAgentPatch.pm 12-jul-2005.22:11:38 sthergao Exp $
#
# EMAgentPatch.pm
# 
# Copyright (c) 2002, 2005, Oracle. All rights reserved.  
#
#    NAME
#      EMAgentPatch.pm - Perl module to support agent patching
#
#    DESCRIPTION
#      Module that monitors marker file and sets up the agent to appropriate
#      states to facilitate patching
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    sthergao    07/12/05 - 
#    sthergao    07/12/05 - 
#    sthergao    06/23/05  - 
#    vnukal      03/16/05  - vnukal_bug-4081918
#    vnukal      03/14/05  - created.
#
package EMAgentPatch;
require nfsPatchPlugin;
require patchAgtStPlugin;
use strict;

sub new 
{
  my ($class) = @_;

  my $self = 
  {
   initialized => 0
  };

  bless $self, $class;
  return $self;
}

# Initialize method called before agent is launched.
sub Initialize {

  my $self = shift;

  $self->{initialized} = 1;
  #print "In method EMAgentPatch->Initialize\n";
  applyPatch();
  return 1;
}

# Status method called every periodically. The frequency is currently @30 secs.
# subject to change. Note. Every effort should be made to return from this 
# method in a timely manner otherwise the monitoring of the agent and any
# other components will be affected.
sub status
{
  my($self) = @_;

  if(!$self->{initialized}) {
    return 0;
  }
  #print "In method EMAgentPatch->status\n";
  patchPlug();
  return 1;
}
  
1;
