#Author: Kondayya Duvvuri
#Date created: 05/05/2004
# Handles start/stop/status subagent of emctl.
package AgentSubAgent;
use EmctlCommon;
use EmCommonCmdDriver;

$EMHOME = getEMHome($ENV{CONSOLE_CFG});

sub new {
  my $classname = shift;
  my $self = {};
  bless ( $self, $classname );
  return $self;
}
sub doIT {
  my $classname = shift;
  my $rargs = shift;
  my $result = 0;
  my $argCount = @$rargs; 
  my $result = 0; # EMCTL_DONE
  
  if ( $argCount != 2 )
  {
    return 2; #UNKOWN_CMD
  }
  $component = $rargs->[1];
  $action = $rargs->[0];
  if ( $component eq "subagent" )
  {
    if ($action eq "start")
    {
      $found = statusSubAgent();
      if ( $found == 1) {
         print "Sub agent is already running..\n";
         exit 1;
      }
      startSubAgent();
    }
    elsif ($action eq "stop")
    {
      $found = statusSubAgent();
      if ( $found == 0) {
         print "Sub agent is not running..\n";
         exit 1;
      }
      stopSubAgent();
    }
    elsif ($action eq "status" )
    {
      $found = statusSubAgent();
      if ( $found == 0) {
         print "Sub agent is not running..\n";
      }
      else {
         print "Sub agent is running..\n";
      }
    }
    else
    {
      $result = EMCTL_BAD_USAGE; #BAD_USAGE
    }
  }
  else
  {
    $result = $EMCTL_UNK_CMD;
  }
  return $result;
}

#
# startSubAgent starts the emsubagent. A cutover from the 
# older dbsnmp
#
sub startSubAgent()
{
    use Cwd;
    local $curdir=cwd();      # get the current directory
    chomp($curdir);           # remove trailing spaces

    if( $IS_WINDOWS eq "TRUE" )
    {
      print "Running sub agent ...";
      system("$EMDROOT/bin/emsubagent >> $EMHOME/sysman/log/emsubagent.nohup 2>&1");
      print "..stopped\n";
    }
    else
    {
      # Start the agent and wait for 30 secs
      print "Starting sub agent ...";

      system("if [ `uname` = \"HP-UX\" ] ; then  ulimit -n 300 ; fi ; nohup $EMDROOT/bin/emsubagent >> $EMHOME/sysman/log/emsubagent.nohup 2>&1 &");

      print "..started\n";
    }

    chdir("$curdir");

    exit 0;
}

sub statusSubAgent()
{
  my $found = 0;
  my @procs = ``;

  if( $IS_WINDOWS eq "TRUE" )
  {
    @procs = `$EMDROOT/bin/nmupm.exe topProcs`;
    foreach $item (@procs) {
     if ( $item =~ /emsubagent/ ) {
       $found = 1;
     }
    }
  }
  else
  {
    @procs = `ps -eo "pid,args" | grep "$EMDROOT/bin/emsubagent"`;
    foreach $item (@procs) {
     if ( $item !~ /grep/ ) {
       $found = 1;
     }
    }
  }
  return $found;
}

sub stopSubAgent()
{
  my @procs = ``;

  if( $IS_WINDOWS eq "TRUE" )
  {
    @procs = `$EMDROOT/bin/nmupm.exe topProcs`;

    print "Stopping sub agent...";
    foreach $item (@procs) {
     if ( $item =~ /em_result=([0-9]+)\|emsubagent\|.*/ ) {
       $subAgentPid = $1;
       kill 9,  $subAgentPid;
       print "stopped\n";
     }
    }
  }
  else
  {
    @procs = `ps -eo "pid,args" | grep "$EMDROOT/bin/emsubagent"`;

    print "Stopping sub agent...";
    foreach $item (@procs) {
     if ( $item !~ /grep/ ) {
       ($subAgentPid, $arg) = split(" ", $item);
        kill 9, $subAgentPid;
        print "stopped\n";
     }
    }
  }
}
sub usage
{
  print "        emctl start | stop | status subagent\n";
}


1;
