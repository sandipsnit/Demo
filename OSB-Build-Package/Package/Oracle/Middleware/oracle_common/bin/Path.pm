#################################################################################
#
# $Header: Path.pm 27-oct-2004.17:55:28 ktlaw Exp $
#
# Path.pm
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      PAth.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YYYY)
#       ktlaw      10/27/04 - ktlaw_add_repmanager_transx_support
#       ktlaw      10/22/04 - 
#     ktlaw      10/14/2004 - Created
################################################################################

package Path;

1;

#
# constructor
# create a new Directory object
#
sub new
{
  my $ref = {};
  $ref->{'paths'} = ();
  $ref->{'sep'} = ':' ;
  if($ENV{'OS'} eq 'Windows_NT')
  {
    $ref->{'sep'} = ';' ;
  }
  bless $ref;
  return $ref;
}

sub setEnv
{
  my $self = shift ;
  my $key = shift if (@_);
  if(defined $key)
  {
    $self->{'env'} = $ENV{$key} ;
  }
}

sub add
{
  my $self = shift ;
  my $path = shift if (@_);
  if(defined $path)
  {
    push(@{$self->{'paths'}},$path);
  }
}

sub toString
{
  my $self = shift ;
  my $h , $ret = "";
  foreach $h (@{$self->{'paths'}})
  {
    if($ret ne '')
    {
      $ret .= $self->{'sep'};
    }
    $ret .= $h ;
  }
  if(defined $self->{'env'})
  {
    if($ret ne '')
    {
      $ret .= $self->{'sep'};
    }
    $ret .= $self->{'env'} ;
  }
  return $ret ;
}
