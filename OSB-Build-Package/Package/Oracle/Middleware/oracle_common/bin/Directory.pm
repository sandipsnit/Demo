#################################################################################
#
# $Header: Directory.pm 27-oct-2004.17:55:28 ktlaw Exp $
#
# Directory.pm
#
# Copyright (c) 2003, 2004, Oracle. All rights reserved.  
#
#    NAME
#      Directory.pm - <one-line expansion of the name>
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

package Directory;

1;

#
# constructor
# create a new Directory object
#
sub new
{
  my $ref = {};
  $ref->{'path'} = undef;
  bless $ref;
  return $ref;
}

#
# set the path of the directory
#
sub setPath
{
  my $self = shift;
  $self->{'path'} = shift if (@_);
}

#
# get the path of the directory
# return "." if path is not previously set
#
sub getPath
{
  my $self = shift;
  if(defined $self->{'path'})
  {
    return $self->{'path'};
  }
  return ".";
}

#
# find all files under the directory and apply a function on each file
# param func      - reference to a function accepting one argument, the file path. 
#                   if not specified, the default function will be print out a line
#                   with the file name.
# param recursive - 'true' to find recursively, any other value otherwise
# param filter    - a regular expression to match the file name pattern. if not 
#                   specified any file found will be passed to func.
# 
# Example : use Directory;
#           $d = new Directory();
#           $d->setPath("c:/");
#           #find *.zip under c:/ recursively and execute yourfunc(fileFound);
#           $d->find(\&yourfunc,'true','\.zip');
#           #find all files under C:/ and print them out
#           $d->find(undef);
# 
sub find
{
  my $self = shift;
  my $func, $recursive, $filter;
  ($func, $recursive, $filter) = @_ ;
  if(!(defined $func))
  {
    $func = \&printFile;
  }
  _find($self->getPath(),$func,$recursive,$filter);
}

#
# default function
#
sub printFile
{
  (my $file) = @_;
  print "$file\n";
}

#
# private recursive function
#
sub _find
{
  my $path, $func, $recursive, $filter;
  ($path, $func, $recursive, $filter) = @_ ;
  
  if(opendir(F,$path))
  {
    my @list = readdir(F);
    closedir(F);
    my $h;
    foreach $h (@list)
    {
      if ($h ne '..' && $h ne '.' && $h ne '.ade_path')
      {        
        if(opendir(A,"$path/$h"))
        {
          if(defined $recursive && $recursive eq 'true')
          {
            _find("$path/$h",$func,$recursive,$filter);
          }
          closedir(A);
        }else
        {
          if(!(defined $filter) || $h =~ /$filter/)
          {
            $func->("$path/$h") ;
          }        
        }
      }
    }
  }
}

