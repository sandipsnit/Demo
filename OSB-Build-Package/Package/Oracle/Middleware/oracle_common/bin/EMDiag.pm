#Author: Neeraj Arora
#Date Created : 04/18/2005
#Handles dump <component>
package EMDiag;
use EmCommonCmdDriver;
use EmctlCommon;
use File::Copy;
use File::Basename;


my $INSTANCE_HOME  = $ENV{EM_INSTANCE_HOME};
my $sendErrorToLog = "false";

my $mas_user;
my $mas_passwd;

sub new {
  my $classname = shift;
  my $self = { };
  bless ( $self, $classname);
  return $self;
}

sub doIT {
   my $classname = shift;
   my $rargs = shift;
   my $result = $EMCTL_UNK_CMD; #Unknown command.
   my $argCount = @$rargs;
     $action = $rargs->[0];
   if ($action eq "dump")
     {
       $result = printDump( $rargs );
     }
   return $result;
} 


sub usage {
    print " Dump Usage : \n";
    print "emctl dump [-log] omsthread \n";
    print "emctl dump [-log] repos <rep user> <rep passwd> <rep host> <rep port> <rep sid> OR \n";
    print "emctl dump [-log] repos <rep user> <rep passwd> <rep connect descriptor> \n";
    print "\n";
}

sub printDump()
{
  local (*args) = @_;
  $sendErrorToLog = "false";
  if( @args->[1] eq "-log")
  {
    $sendErrorToLog = "true"; 
    shift(@args);
  }  

  my $component = @args->[1];
  if ($component eq "omsthread")
  {
    omsThreadDump();
  }
  elsif ($component eq "repos")
  {
    reposDump( $args);
  }
  else 
  {
    return $EMCTL_BAD_USAGE;
  }
}

sub omsThreadDump()
{
    require "semd_common.pl";
    my $osType = get_osType();
    if($osType eq 'WIN')
    {
        print STDERR "Unsuported OS type!\n";
        exit(1);
    }
    my ($pid) = @_;

    if(@args != 2 )
    {
      return $EMCTL_BAD_USAGE;
    }
    # Check if pid was provided
    unless(defined($pid))
    {
      $pid = getEMProcessID();

      unless((defined($pid)) && ($pid =~ m/^\d+$/o))
      {
        print STDERR "Failed to retrieve pid [$pid].\n";
        exit(1);
      }
    }
    unless(kill('QUIT', $pid))
    {
        print STDERR "Failed to deliver signal to process ($pid): $!.\n";
        exit(1);
    };
    print("Thread dumped successfully for process '$pid'!\n");

  return 0;
}

sub reposDump()
{
  local (*args) = @_;
  
  my $outfile = "\"\"";
  my $pid = getEMProcessID();
  my $rep_alias;
  unless((defined($pid)) && ($pid =~ m/^\d+$/o))
  {
    $pid = "0000";
  }

  if(@args != 5 && @args != 7)
  {
    return $EMCTL_BAD_USAGE;
  }
 
  my $rep_user = @args->[2];
  $rep_user = uc($rep_user);
  my $rep_pwd  = @args->[3];
  if (@args eq 5)
  {
    my $temp_rep_alias=@args->[4];
    $rep_alias="\"$temp_rep_alias\"";
  }
  else
  {
    $rep_host=@args->[4];
    $rep_port=@args->[5];
    $rep_sid=@args->[6];
    $rep_alias="\"(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP) (Host = $rep_host) (Port= $rep_port))) (CONNECT_DATA=(SERVICE_NAME = $rep_sid)))\"";
  }

  if($sendErrorToLog eq "true")
  {
    $outfile = "$INSTANCE_HOME/OC4JComponent/oc4j_em/sysman/log/db_stat_$pid.out";
  }
  my $srcfile = "$ORACLE_HOME/emcore/source/oracle/sysman/emdrep/sql/core/latest/emdiag/db_stats_sql.sql";

  $rc = 0xffff & system("${ORACLE_HOME}/bin/sqlplus -silent $rep_user/$rep_pwd\@$rep_alias \@$srcfile $rep_user $outfile");
  $rc >>= 8;

  return $rc;

}

 sub getEMProcessID()
 {
       checkAndSetMasInfo();
	my $pid;
	my $asctlPath = "$ENV{'ORACLE_HOME'}/bin/asctl" ;
        my $mas_connurl = $ENV{'EM_MAS_CONN_URL'};
	my $em_instance_name = $ENV{'EM_INSTANCE_NAME'};
	my $mas_instance_name = $ENV{'EM_MAS_INSTANCE_NAME'};
	my $oracle_instance = $ENV{'EM_INSTANCE_HOME'};
	my $mas_farm_name = $ENV{'EM_FARM_NAME'};
	my $oc4j_name = $ENV{'EM_OC4J_NAME'};
	my $mas_oracle_home = $ENV{'ORACLE_HOME'} ;

	my $status_oms_command =  "$asctlPath -oraclehome $mas_oracle_home status -masserver $mas_connurl -oracleinstance $oracle_instance -password $mas_passwd -user $mas_user -comp $oc4j_name -dw 200" ;
	my @states = `$status_oms_command 2>&1`;
    my $count = scalar(@states);
    my $i=0;
    while( $i < $count)
    {
      @comp = split /\s+\|/, $states[$i];
      if( $comp[0] eq "OC4JComponent" && $comp[1] eq $oc4j_name)
      {
          $pid = $comp[3];
          last;
      }
      $i = $i + 1;
   }
   return $pid; 
 }

sub checkAndSetMasInfo()
{
  if(!defined($ENV{'EM_MAS_ADMIN_USER'}) ||
     !defined($ENV{'EM_MAS_ADMIN_PASSWD'}) )
  {
    print STDOUT "MAS Username: ";
    chomp($ENV{'EM_MAS_ADMIN_USER'} = <STDIN>);
    $ENV{'EM_MAS_ADMIN_PASSWD'} = EmctlCommon::promptUserPasswd("MAS Password: ");
  }

  $mas_user = $ENV{'EM_MAS_ADMIN_USER'};
  $mas_passwd = $ENV{'EM_MAS_ADMIN_PASSWD'};
}


1;
