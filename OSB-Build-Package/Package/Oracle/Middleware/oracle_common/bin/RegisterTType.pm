#Author: Rajendra Pandey
#Date Created : 08/24/2004
#Handles register targettype
package RegisterTType;
use EmCommonCmdDriver;
use EmctlCommon;
use File::Copy;
use File::Basename;


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
   if ($action eq "register")
     {
       $result= registerType( $rargs );
     }
   return $result;
} 


sub usage {
    print " Register Targettype Usage : \n";
    print "emctl register oms targettype [-o <Output filename>] <XML filename> <rep user> <rep passwd> <rep host> <rep port> <rep sid> OR \n";
    print "emctl register oms targettype [-o <Output filename>] <XML filename> <rep user> <rep passwd> <rep connect descriptor> \n";
    print "\nThe <XML filename> provided must be the xml file name with the absolute path and not with relative path.";
    print "\n-o option generates the SQL file into the <Output filename> and does not register the target type into the repository.";
    print "\n";
}

sub registerType()
{
  local (*args) = @_;
  my  $argCount = @args;
  my ($refresh, $CP, $file_only, $outfile, $xmlfile,$rep_user,$rep_pwd,$rep_alias,$debug,$infile);
  my $result = $EMCTL_UNK_CMD; #Unknown command.
  if (lc(@args->[1]) eq "oms")
  {
    my $component = @args->[2];

    if (lc($component) eq "targettype") #emctl register targettype
    {
      shift(@args);                  # -- shift out register...
      shift(@args);                  # -- shift out oms ...
      shift(@args);                  # -- shift out targettype...
      $CP = "$ORACLE_HOME/jdbc/lib/ojdbc5.jar$cpSep$ORACLE_HOME/jlib/orai18n.jar$cpSep$ORACLE_HOME/jlib/orai18n-mapping.jar$cpSep$ORACLE_HOME/jlib/orai18n-translation.jar$cpSep$ORACLE_HOME/jlib/orai18n-collation.jar$cpSep$ORACLE_HOME/jlib/orai18n-mapping.jar$cpSep$ORACLE_HOME/jlib/orai18n-utility.jar$cpSep$ORACLE_HOME/jdbc/lib/nls_charset12.jar$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar$cpSep$ORACLE_HOME/lib/xmlparserv2.jar$cpSep$ORACLE_HOME/dms/lib/ojdl.jar$cpSep$ORACLE_HOME/dms/lib/dms.jar";
      if (@args->[0] eq "-refresh")
      {
        $refresh = "true";
        shift(@args);               # -- shift out -refresh
      }
      else
      {
        $refresh = "false";
      }

      if (@args->[0] eq "-o")
      {
        if (@args gt 3)
        {
          $file_only = "true";
          $outfile = @args->[1];
          shift(@args);                  # -- shift out -o ...
          shift(@args);                  # -- shift out output filename...
          $xmlfile  = @args->[0];
        }
        else 
        {
          return $EMCTL_BAD_USAGE;
        }
      }
      else 
      {
        $xmlfile  = @args->[0];
        $outfile = ${ORACLE_HOME} . "/sysman/admin/emdrep/bin/" . basename($xmlfile, ".xml") . "_TT.sql";
      }
      if (@args gt 3)
      {
        $rep_user = @args->[1];
        $rep_pwd  = @args->[2];
        if (@args lt 6)
        {
          $rep_alias=@args->[3];
          ($rep_host,$rep_port,$rep_sid)  = ($rep_alias =~ /\(DESCRIPTION=\(ADDRESS_LIST=\(ADDRESS=\(PROTOCOL=TCP\)\(HOST=([A-Za-z.0-9]+)\)\(PORT=(\d+)\)\)\)\(CONNECT_DATA=\((SID|SERVICE_NAME)=([A-Za-z.0-9]+)\)\)\)/)[0,1,3];
          $debug=@args->[4];
        }
        else
        {
          $rep_host=@args->[3];
          $rep_port=@args->[4];
          $rep_sid=@args->[5];
          $debug=@args->[6];
          $rep_alias="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=$rep_host)(Port=$rep_port))(CONNECT_DATA=(SID=$rep_sid)))";
        }
      }
      else 
      {
        return $EMCTL_BAD_USAGE;
      }
      $infile =  ${ORACLE_HOME}."/sysman/admin/metadata/TT_".basename($xmlfile, ".xml").".xml";
      copy($xmlfile, $infile);
      delete($ENV{EMSTATE});
      delete($ENV{REMOTE_EMDROOT});


      if ($file_only ne "true")
      {
        $result =  system("${JRE_HOME}/bin/java -classpath $CP -DEMHOME=$EMHOME -DORACLE_HOME=$ORACLE_HOME oracle.sysman.emdrep.registry.typeRegistry.SqlGenerator  $infile $refresh execute $rep_user $rep_pwd $rep_host $rep_port $rep_sid $debug");
      }
      else
      {
        $result = system("${JRE_HOME}/bin/java -classpath $CP -DEMHOME=$EMHOME -DORACLE_HOME=$ORACLE_HOME oracle.sysman.emdrep.registry.typeRegistry.SqlGenerator  $infile $outfile $refresh $debug");

        open(SQL, ">>$outfile");
        print SQL "\nQUIT\n";
        close(SQL);
      }

      unlink($infile);
    }
    elsif ((lc($component) eq "discmethod") ||
	   (lc($component) eq "plugindiscovery")) #emctl register discmethod
    {
      shift(@args);                  # -- shift out register...
      shift(@args);                  # -- shift out oms ...
      my $regtype = @args->[0];
      my $fileprefix = "";
      if($regtype eq "discmethod")
      {
	$fileprefix = "DiscMthd:";
      }
      elsif($regtype eq "plugindiscovery")
      {
	$fileprefix = "PluginDisc:";
      }
      shift(@args);                  # -- shift out discmethod...
      $CP = "$ORACLE_HOME/jdbc/lib/ojdbc5.jar$cpSep$ORACLE_HOME/jlib/orai18n.jar$cpSep$ORACLE_HOME/jlib/orai18n-mapping.jar$cpSep$ORACLE_HOME/jlib/orai18n-translation.jar$cpSep$ORACLE_HOME/jlib/orai18n-collation.jar$cpSep$ORACLE_HOME/jlib/orai18n-mapping.jar$cpSep$ORACLE_HOME/jlib/orai18n-utility.jar$cpSep$ORACLE_HOME/jdbc/lib/nls_charset12.jar$cpSep$ORACLE_HOME/sysman/jlib/emCORE.jar$cpSep$ORACLE_HOME/sysman/jlib/log4j-core.jar$cpSep$ORACLE_HOME/sysman/jlib/emagentSDK.jar$cpSep$ORACLE_HOME/lib/xmlparserv2.jar$cpSep$ORACLE_HOME/dms/lib/dms.jar$cpSep$ORACLE_HOME/dms/lib/ojdl.jar";
      if (@args->[0] eq "-refresh")
      {
        $refresh = "true";
        shift(@args);               # -- shift out -refresh
      }
      else
      {
        $refresh = "false";
      }

      if (@args->[0] eq "-o")
      {
        if (@args gt 3)
        {
          $file_only = "true";
          $outfile = @args->[1];
          shift(@args);                  # -- shift out -o ...
          shift(@args);                  # -- shift out output filename...
          $xmlfile  = @args->[0];
        }
        else 
        {
          return $EMCTL_BAD_USAGE;
        }
      }
      else 
      {
        $xmlfile  = @args->[0];
        $outfile = ${ORACLE_HOME} . "/sysman/admin/emdrep/bin/" . basename($xmlfile, ".xml") . "_TT.sql";
      }
      if (@args gt 3)
      {
        $rep_user = @args->[1];
        $rep_pwd  = @args->[2];
        if (@args lt 6)
        {
          $rep_alias=@args->[3];
          ($rep_host,$rep_port,$rep_sid)  = ($rep_alias =~ /\(DESCRIPTION=\(ADDRESS_LIST=\(ADDRESS=\(PROTOCOL=TCP\)\(HOST=([A-Za-z.0-9]+)\)\(PORT=(\d+)\)\)\)\(CONNECT_DATA=\((SID|SERVICE_NAME)=([A-Za-z.0-9]+)\)\)\)/)[0,1,3];
          $debug=@args->[4];
        }
        else
        {
          $rep_host=@args->[3];
          $rep_port=@args->[4];
          $rep_sid=@args->[5];
          $debug=@args->[6];
          $rep_alias="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=$rep_host)(Port=$rep_port))(CONNECT_DATA=(SID=$rep_sid)))";
        }
      }
      else 
      {
        return $EMCTL_BAD_USAGE;
      }
      delete($ENV{EMSTATE});
      delete($ENV{REMOTE_EMDROOT});

      my $filetouse = $fileprefix . $xmlfile;
      
      if ($file_only ne "true")
      {
	$result =  system("${JRE_HOME}/bin/java -classpath $CP -DEMHOME=$EMHOME -DORACLE_HOME=$ORACLE_HOME oracle.sysman.emdrep.registry.typeRegistry.SqlGenerator  $filetouse $refresh execute $rep_user $rep_pwd $rep_host $rep_port $rep_sid $debug");
      }
      else
      {
        $result = system("${JRE_HOME}/bin/java -classpath $CP -DEMHOME=$EMHOME -DORACLE_HOME=$ORACLE_HOME oracle.sysman.emdrep.registry.typeRegistry.SqlGenerator  $filetouse $outfile $refresh $debug");

        open(SQL, ">>$outfile");
        print SQL "\nQUIT\n";
        close(SQL);
      }


    }
    else
    {
      return $EMCTL_BAD_USAGE;
    }
  }
  else
  {
    return $EMCTL_BAD_USAGE;
  }

  exit $result;
}

1;
