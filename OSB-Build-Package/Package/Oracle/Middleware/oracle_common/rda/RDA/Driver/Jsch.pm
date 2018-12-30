# Jsch.pm: Class Used for Remote Access with JSCH

package RDA::Driver::Jsch;

# $Id: Jsch.pm,v 1.18 2012/05/22 04:37:09 mschenke Exp $
# ARCS: $Header: /home/cvs/cvs/RDA_4/src/scripting/lib/RDA/Driver/Jsch.pm,v 1.18 2012/05/22 04:37:09 mschenke Exp $
#
# Change History
# 20120522  MSC  Remove JSCH timeouts.

=head1 NAME

RDA::Driver::Jsch - Class Used for Remote Access using JSCH

=head1 SYNOPSIS

require RDA::Driver::Jsch;

=head1 DESCRIPTION

The objects of the C<RDA::Driver::Jsch> class are used for execution remote
access requests using Java Secure Channel (JSCH).

The following methods are available:

=cut

use strict;

BEGIN
{ use Exporter;
  use IO::File;
  use RDA::Object::Rda qw($APPEND $CREATE $FIL_PERMS);
}

# Define the global public variables
use vars qw($VERSION @EXPORT_OK @ISA %INLINE);
$VERSION   = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);
@EXPORT_OK = qw(%INLINE);
@ISA       = qw(Exporter);

# Define the Java interface
my $VER  = '1.5';
my $PKG1 = 'com.jcraft.jsch';
my $PKG2 = 'oracle.sysman.rda.jsch';

my $NAM = 'RdaJsch';
my $COD = <<EOF;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.lang.StringBuffer;
import java.util.Hashtable;

import $PKG2.RdaInstance;

class $NAM
{// Define the common variables
 private static RdaInstance ssh = new RdaInstance();

 // Define the common constants
 private final static String EOL = "\\012";
 private final static String ERR = "ERR";
 private final static String WRK = "WRK";

 // Define the default contructor
 public $NAM()
 {
 }

 // Execute a META request
 private static boolean doMeta(PrintStream ofh)
 {try
  {ofh.println("-api='$VERSION'");
  }
  catch (Exception err)
  {System.err.println("META exception: " + err.toString());
   return true;
  }
  return false;
 }

 // Execute a request
 private static boolean execRequest(String cmd, String dat,
   Hashtable<String,String> ctx)
 {boolean flg = false;
  File fil;
  PrintStream efh = null;
  PrintStream ofh = null;

  // Detect an exit request
  if ("QUIT".equals(cmd))
   return true;
  if ("ABORT".equals(cmd))
   return true;

  // Treat other requests
  try
  {// Create and open the output file
   if (ctx.containsKey(ERR))
   {String err = (String) ctx.get(ERR);
    fil = new File(err);
    fil.createNewFile();
    efh = new PrintStream(new FileOutputStream(fil));
   }
   String wrk = (String) ctx.get(WRK);
   fil = new File(wrk);
   fil.createNewFile();
   ofh = new PrintStream(new FileOutputStream(fil));

   // Process the request
   if ("COLLECT".equals(cmd))
    flg = ssh.doCollect(ofh, efh, ctx);
   else if ("DEFAULT".equals(cmd))
    flg = ssh.doDefault(ofh, efh, ctx);
   else if ("EXEC".equals(cmd))
    flg = ssh.doExec(ofh, efh, dat, ctx);
   else if ("GET".equals(cmd))
    flg = ssh.doGet(ofh, efh, ctx);
   else if ("LOGIN".equals(cmd))
    flg = ssh.doLogin(ofh, efh, ctx);
   else if ("LOGOUT".equals(cmd))
    flg = ssh.doLogout(ofh, efh, ctx);
   else if ("PUT".equals(cmd))
    flg = ssh.doPut(ofh, efh, ctx);
   else if ("TEST".equals(cmd))
    flg = ssh.doTest(ofh, efh, ctx);
   else if ("META".equals(cmd))
    flg = doMeta(ofh);

   // Close and rename the output file
   ofh.close();
   wrk = wrk.replaceAll("tmp\$", "txt");
   fil.renameTo(new File(wrk));
   if (efh != null)
    efh.close();
  }
  catch (IOException err)
  {System.err.println("Request exception: " + err.toString());
   return true;
  }

  // Accept a new request
  return flg;
 }

 // Print the formatted error message to the output file
 private static void printMessage(PrintStream ofh, String typ, String msg)
 {ofh.println("ERROR in " + typ + " request:");
  ofh.println(msg.replaceAll("(\\n|\\r)"," "));
 }

 // Parse input and manage requests
 public static void main(String[] argv) throws IOException
 {BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in));
  Hashtable<String,String> ctx = new Hashtable<String,String>();

  String cmd, lin;
  StringBuffer buf = new StringBuffer();
  boolean flg = true;
  int beg, end;

  // Parse the input and treat the requests
  cmd = "";
  while ((lin = stdin.readLine()) != null)
  {if (flg)
   {if ((beg = lin.indexOf("='")) > 0 &&
        (end = lin.lastIndexOf("'")) > 0 &&
        end > beg)
     ctx.put(lin.substring(0, beg), lin.substring(beg + 2, end));
    else if (lin.startsWith("/"))
    {// Execute the request
     cmd = lin.substring(1);
     if (execRequest(cmd, buf.toString(), ctx))
      break;

     // Prepare the next command
     cmd = "";
     ctx = new Hashtable<String,String>();
    }
    else if (lin.startsWith("#"))
    {cmd = lin.substring(1);
     flg = false;
    }
   }
   else
   {if ("/".equals(lin))
    {// Execute the request
     if (execRequest(cmd, buf.toString(), ctx))
      break;

     // Prepare the next command
     buf = new StringBuffer();
     cmd = "";
     ctx = new Hashtable<String,String>();
     flg = true;
    }
    else
    {buf.append(lin);
     buf.append(EOL);
    }
   }
  }

  // End the SSH interactions and exit
  ssh.end();
  System.exit(0);
 }
}
EOF

my $NAM2 = 'IdentityRepository';
my $COD2 = <<EOF;
// Copyright (c) 2011 ymnk, JCraft,Inc. All rights reserved.
//
// Transformation into a public interface

package $PKG1;

import java.util.Vector;

public interface IdentityRepository
{public Vector getIdentities();
 public boolean add(byte[] identity);
 public boolean remove(byte[] blb);
 public void removeAll();
}
EOF

my $NAM3 = 'RdaAgent';
my $COD3 = <<EOF;
package $PKG2;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.lang.Process;
import java.lang.Runtime;

import $PKG2.RdaAgentException;
import $PKG2.RdaBuffer;

public class $NAM3
{// Define the object attributes
 private DataInputStream  ifh;
 private DataOutputStream ofh;
 private Process prc = null;
 private String  rda = "perl rda.pl";  // How to execute RDA ?
 private String  pre;                  // Trace prefix
 private String  mod = "$NAM3";        // Trace module
 private byte    lvl;                  // Trace level
 private String  trc = "";             // Agent communication trace file

 private final byte[]     tmp = new byte[4];
 private final RdaBuffer  buf = new RdaBuffer();

 // Define the private constants
 private static final byte SSH_FAILURE           = (byte)  5;
 private static final byte REQUEST_IDENTITIES    = (byte) 11;
 private static final byte SIGN_REQUEST          = (byte) 13;
 private static final byte ADD_IDENTITY          = (byte) 17;
 private static final byte REMOVE_IDENTITY       = (byte) 18;
 private static final byte REMOVE_ALL_IDENTITIES = (byte) 19;

 private static final byte TRACE = (byte) 8;

 // Define the constructor
 public $NAM3(String pre, byte lvl)
 {this.ifh = null;
  this.ofh = null;
  this.pre = pre;
  this.lvl = lvl;
  traceln(TRACE,"New agent interface created");
 }

 public boolean addIdentity(byte[] dat)
 {// Prepare the request
  traceln(TRACE, "Request to add an identity");
  buf.addCommand(ADD_IDENTITY);
  buf.addByte(dat);
  buf.addLength();

  // Execute the request
  try
  {query(buf);
  }
  catch (RdaAgentException err)
  {return false;
  }
  return true;
 }

 // Get available identities
 public RdaIdentity[] getIdentities()
 {RdaIdentity[] res = null;

  // Create the request
  traceln(TRACE, "Request the available identities");
  buf.addCommand(REQUEST_IDENTITIES);
  buf.addLength();

  // Execute the request
  try
  {query(buf);
  }
  catch (RdaAgentException err)
  {res = new RdaIdentity[0];
   return res;
  }
  int sta = buf.getByte();

  // Extract the identities
  int cnt = buf.getInt();
  traceln(TRACE, " => " + cnt + " identities found");
  res = new RdaIdentity[cnt];
  for (int off = 0 ; off < cnt ; ++off)
   res[off] = new RdaIdentity(buf.getString(), buf.getString());
  return res;
 }

 // Remove all identities
 public void removeAllIdentities()
 {// Create the request
  traceln(TRACE, "Request to remove all identities");
  buf.addCommand(REMOVE_ALL_IDENTITIES);
  buf.addLength();

  // Execute the request
  try
  {query(buf);
  }
  catch (RdaAgentException err)
  {
  }
 }

 // Remove an identity
 public boolean removeIdentity(byte[] pub)
 {// Create the request
  traceln(TRACE, "Request to remove an identity");
  buf.addCommand(REMOVE_IDENTITY);
  buf.addString(pub);
  buf.addLength();

  // Execute the request
  try
  {query(buf);
  }
  catch (RdaAgentException err)
  {return false;
  }
  return true;
 }

 // Execute a sign request
 public byte[] sign(byte[] pub, byte[] dat)
 {// Create the request
  traceln(TRACE, "Request signature");
  buf.addCommand(SIGN_REQUEST);
  buf.addString(pub);
  buf.addString(dat);
  buf.addInt(0);
  buf.addLength();

  // Execute the request
  try
  {query(buf);
  }
  catch (RdaAgentException err)
  {byte[] res = new byte[1];
   res[0] = SSH_FAILURE;
   return res;
  }
  int sta = buf.getByte();

  // Return the result
  return buf.getString();
 }

 // --- Low level methods -----------------------------------------------------

 // Close the RDA agent interface
 public void end()
 {traceln(TRACE, "Close the RDA agent interface");
  // Notify the RDA agent and close the output stream
  if (ofh != null)
  {traceln(TRACE, "Close the output stream");
   try
   {byte[] buf = new byte[4];
    buf[0] = (byte) 0;
    buf[1] = (byte) 0;
    buf[2] = (byte) 0;
    buf[3] = (byte) 0;
    ofh.write(buf, 0, 4);
    ofh.flush();
    ofh.close();
   }
   catch (Exception err)
   {
   }
   finally
   {ofh = null;
   }
  }

  // Close the input stream
  if (ifh != null)
  {traceln(TRACE, "Close the input stream");
   try
   {ifh.close();
   }
   catch (Exception err)
   {
   }
   finally
   {ifh = null;
   }
  }

  // Kill the process
  if (prc != null)
  {traceln(TRACE, "Kill the RDA authentication process");
   try
   {prc.destroy();
   }
   catch (Exception err)
   {
   }
   finally
   {prc = null;
   }
  }
 }

 // Initiate the RDA agent interface
 private void open() throws IOException
 {if (ofh == null)
  {traceln(TRACE, "Start a RDA proxy to the authentication agent");
   try
   {Runtime run = java.lang.Runtime.getRuntime();
    String cmd;
    prc = (trc.length() > 0)
      ? run.exec(cmd = rda + " -XRemote authenticate -t " + trc)
      : run.exec(cmd = rda + " -XRemote authenticate");
    traceln(TRACE, "Using: " + cmd);
    ofh = new DataOutputStream(prc.getOutputStream());
    ifh = new DataInputStream(prc.getInputStream());
   }
   catch (Exception err)
   {end();
    err.printStackTrace();
   }
  }
 }

 // Perform a query
 public void query(RdaBuffer buf) throws RdaAgentException
 {traceln(TRACE, " - Execute a query");
  try
  {// Send the request
   write(buf.getBuffer(), 0, buf.getLength());

   // Read the length and next the data
   int lgt = read(buf.getBuffer(), 0, 4);
   lgt = buf.getInt();
   lgt = read(buf.getBuffer(), 0, lgt);
  }
  catch (IOException err)
  {// Close the communication in case of problems
   end();
   throw new RdaAgentException(err.toString());
  }
 }

 // Read data from the RDA agent
 private int read(byte[] buf, int off, int lgt) throws IOException
 {int max = lgt;
  while (max > 0)
  {traceln(TRACE, " - Read " + max);
   int cur = ifh.read(buf, off, max);
   if (cur <= 0)
    return -1;
   if (cur > 0)
   {off += cur;
    max -= cur;
   }
  }
  return lgt;
 }

 // Modify how to execute RDA
 public void setAgent(String rda)
 {this.rda = rda;
 }

 // Modify the trace level
 public void setLevel(byte lvl)
 {this.lvl = lvl;
 }

 // Modify the trace prefix
 public void setPrefix(String pre)
 {this.pre = pre;
 }

 // Modify the communication trace file
 public void setTrace(String trc)
 {this.trc = trc;

  // Close the communication interface to use the trace on the next request
  end();
 }

 // Send data to the RDA agent
 private void write(byte[] buf, int off, int lgt) throws IOException
 {// Start the communication with the RDA agent on first request
  open();

  // Send the data
  traceln(TRACE, " - Write " + lgt);
  ofh.write(buf, off, lgt);
  ofh.flush();
 }

 // Display a trace line
 public void traceln(byte msk, String txt)
 {if ((lvl & msk) == msk)
   System.out.println(pre + "/" + mod + "[" + msk + "]: " + txt);
 }
}
EOF

my $NAM4 = 'RdaAgentException';
my $COD4 = <<EOF;
package $PKG2;

public class $NAM4 extends Exception
{private static final long serialVersionUID = 1L;

 public $NAM4(String message)
 {super(message);
 }
}
EOF

my $NAM5 = 'RdaBuffer';
my $COD5 = <<EOF;
package $PKG2;

public class $NAM5
{// Defined the object attributes
 private final byte[] tmp = new byte[4];
 private byte[]       buf;
 private int          idx;
 private int          off;

 // Define the constructors
 public $NAM5(int siz)
 {this.buf = new byte[siz];
  this.idx = 0;
  this.off = 0;
 }

 public $NAM5(byte[] buf)
 {this.buf = buf;
  this.idx = 0;
  this.off = 0;
 }

 public $NAM5()
 {this(20480);
 }

 // Public methods
 public void addByte(byte[] dat)
 {addByte(dat, dat.length);
 }

 public void addByte(byte[] dat, int lgt)
 {System.arraycopy(dat, 0, buf, idx, lgt);
  idx += lgt;
 }

 public void addCommand(byte cmd)
 {idx = 4;
  off = 0;
  buf[idx++] = cmd;
 }

 public void addInt(int val)
 {buf[idx++] = (byte) (val >>> 24);
  buf[idx++] = (byte) (val >>> 16);
  buf[idx++] = (byte) (val >>> 8);
  buf[idx++] = (byte) (val);
 }

 public void addLength()
 {int lgt = idx - 4;
  buf[0] = (byte) (lgt >>> 24);
  buf[1] = (byte) (lgt >>> 16);
  buf[2] = (byte) (lgt >>> 8);
  buf[3] = (byte) (lgt);
 }

 public void addString(byte[] dat)
 {addString(dat, dat.length);
 }

 public void addString(byte[] dat, int lgt)
 {addInt(lgt);
  addByte(dat, lgt);
 }

 public byte[] getBuffer()
 {off = 0;
  return buf;
 }

 public int getByte()
 {return (buf[off++] & 0xff);
 }

 void getByte(byte[] dat, int lgt)
 {System.arraycopy(buf, off, dat, 0, lgt);
  off += lgt;
 }

 public int getInt()
 {int dat = (((int) buf[off++]) << 24) & 0xff000000;
  dat |=    (((int) buf[off++]) << 16) & 0x00ff0000;
  dat |=    (((int) buf[off++]) <<  8) & 0x0000ff00;
  dat |=     ((int) buf[off++])        & 0x000000ff;
  return dat;
 }

 public int getLength()
 {return idx - off;
 }

 public byte[] getString()
 {int cnt = getInt();
  if (cnt < 0 || cnt > 262144)
   cnt = 262144;
  byte[] dat = new byte[cnt];
  getByte(dat, cnt);
  return dat;
 }
}
EOF

my $NAM6 = 'RdaCollector';
my $COD6 = <<EOF;
package $PKG2;

import java.io.PrintStream;
import java.util.Hashtable;

import $PKG1.ChannelShell;
import $PKG1.Session;

public class $NAM6
{// Define the object attributes
 private ChannelShell chn = null;  // Collection channel
 private String       dis = null;  // Disconnection command

 private String pwd;  // User password
 private String usr;  // User name

 private String pre = "JSCH";    // Trace prefix
 private String mod = "$NAM6";   // Trace module
 public byte    lvl = (byte) 0;  // Trace level

 // Define the private constants
 private final static String ACK = "ACK";
 private final static String CHK = "CHK";
 private final static String CLN = "CLN";
 private final static String CMD = "CMD";
 private final static String DIS = "DIS";
 private final static String MAX = "MAX";
 private final static String NXT = "NXT";
 private final static String PAT = "PAT";
 private final static String SKP = "SKP";
 private final static String TRY = "TRY";

 private static final byte TRACE = (byte) 16;

 // Define the constructor
 public $NAM6(String usr, String pwd, String pre, byte lvl)
 {this.usr = usr;
  this.pwd = pwd;
  this.pre = pre;
  this.lvl = lvl;
 }

 // Close all collection operation
 public void end()
 {if (chn != null)
  {// Send the disconnection command
   if (dis != null)
   {traceln(TRACE, "Send the disconnection command");
//    out.println(dis);
    dis = null;
   }

   // Close the channel
   traceln(TRACE, "Close the collect channel");
   chn.disconnect();
   chn = null;
  }
 }

 // Perform a collection
 public boolean collect(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {try
  {ofh.println("-api='$VERSION'");
  }
  catch (Exception err)
  {System.err.println("COLLECT exception: " + err.toString());
   return true;
  }
  return false;
 }

 // Perform a login
 public boolean login(Session ses, PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {

  // Save the disconnection command
  if (ctx.containsKey(DIS))
   dis = ctx.get(DIS);

  return false;
 }

 // Modify the trace level
 public void setLevel(byte lvl)
 {this.lvl = lvl;
 }

 // Modify the trace prefix
 public void setPrefix(String pre)
 {this.pre = pre;
 }

 // Display a trace line
 public void traceln(byte msk, String txt)
 {if ((lvl & msk) == msk)
   System.out.println(pre + "/" + mod + "[" + msk + "]: " + txt);
 }

 // --- Private methods ------------------------------------------------------

}
EOF

my $NAM7 = 'RdaIdentity';
my $COD7 = <<EOF;
package $PKG2;

public class $NAM7
{// Define the object attributes
 private byte[] pub;  // Public key
 private byte[] dsc;  // Source description

 // Define the constructor
 public $NAM7(byte[] pub, byte[] dsc)
 {this.pub = pub;
  this.dsc = dsc;
 }

 // Get the public key
 public byte[] getPublicKey()
 {return pub;
 }

 // Get the description
 public byte[] getDescription()
 {return dsc;
 }
}
EOF

my $NAM8 = 'RdaIdentityCache';
my $COD8 = <<EOF;
package $PKG2;

import java.util.Vector;

import $PKG1.IdentityRepository;
import $PKG1.JSchException;

public class $NAM8 implements IdentityRepository
{// Define the object attributes
 private RdaAgent agt;

 // Define the constructor
 public $NAM8(RdaAgent agt)
 {this.agt = agt;
 }

 // Add the specify identity to the cache
 public boolean add(byte[] dat)
 {return agt.addIdentity(dat);
 }

 // Get all available identities
 public Vector<com.jcraft.jsch.Identity> getIdentities()
 {Vector<com.jcraft.jsch.Identity> res = new Vector<com.jcraft.jsch.Identity>();
  RdaIdentity[] tbl = agt.getIdentities();
  for (int off = 0 ; off < tbl.length ; ++off)
  {final RdaIdentity rid = tbl[off];
   com.jcraft.jsch.Identity jid = new com.jcraft.jsch.Identity()
   {byte[] pub = rid.getPublicKey();
    String nam = new String((new RdaBuffer(pub)).getString());

    public boolean setPassphrase(byte[] psp) throws JSchException
    {return true;
    }

    public byte[] getPublicKeyBlob()
    {return pub;
    }

    public byte[] getSignature(byte[] dat)
    {return agt.sign(pub, dat);
    }

    public boolean decrypt()
    {return true;
    }

    public String getAlgName()
    {return nam;
    }

    public String getName()
    {return "";
    }

    public boolean isEncrypted()
    {return false;
    }

    public void clear()
    {
    }
   };
   res.addElement(jid);
  }
  return res;
 }

 // Remove the specified identity from the cache
 public boolean remove(byte[] pub)
 {return agt.removeIdentity(pub);
 }

 // Remove all identities from the cache
 public void removeAll()
 {agt.removeAllIdentities();
 }
}
EOF

my $NAM9 = 'RdaIdentityRepository';
my $COD9 = <<EOF;
package $PKG2;

import java.util.Vector;

public interface $NAM9
{\@SuppressWarnings("rawtypes")
 public Vector  getIdentities();
 public boolean add(byte[] identity);
 public boolean remove(byte[] blb);
 public void    removeAll();
}
EOF

my $NAM10 = 'RdaInstance';
my $COD10 = <<EOF;
package $PKG2;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintStream;
import java.lang.reflect.Method;
import java.util.Hashtable;
import java.util.Vector;
import java.util.regex.Pattern;

import $PKG1.UserInfo;
import $PKG1.ChannelExec;
import $PKG1.ChannelSftp;
import $PKG1.ChannelSftp.LsEntry;
import $PKG1.ChannelShell;
import $PKG1.IdentityRepository;
import $PKG1.JSch;
import $PKG1.JSchException;
import $PKG1.Logger;
import $PKG1.Session;
import $PKG1.SftpATTRS;
import $PKG1.SftpException;

import $PKG2.RdaAgent;
import $PKG2.RdaCollector;
import $PKG2.RdaIdentityCache;
import $PKG2.RdaJsch;
import $PKG2.RdaUser;

public class $NAM10
{// Define the object attributes
 private RdaAgent     agt = null;   // No RDA agent by default
 private RdaCollector col = null;   // No RDA collector by default
 private Session      ses = null;   // Session to the remote server
 private String       dis = null;   // Disconnection command
 private String       msg = null;   // Last connection error
 private Boolean      con = false;  // Not yet connected
 private Boolean      old = false;  // Indicator of an old JSCH version

 private String pre = "JSCH";    // Trace prefix
 private String mod = "$NAM10";  // Trace module
 public byte    lvl = (byte) 0;  // Trace level

 // Define the instance defaults
 private String hst = "localhost";                      // Local host
 private int    lim = 0;                                // Timeout disabled
 private int    prt = 22;                               // Default port
 private String pph = "";                               // No passphrase
 private String pwd = "";                               // No password
 private String shl = "/bin/sh";			// Bourne shell
 private String usr = System.getProperty("user.name");  // Current user

 // Define a logger
 public final Logger log = new Logger()
   {public boolean isEnabled(int lvl)
    {return true;
    }

    public void log(int lvl, String msg)
    {System.out.println("LOG:" + msg);
    }
   };

 // Define the common constants
 private final static String AGT = "AGT";
 private final static String CMD = "CMD";
 private final static String DIR = "DIR";
 private final static String DST = "DST";
 private final static String FIL = "FIL";
 private final static String FLG = "FLG";
 private final static String HST = "HST";
 private final static String LIM = "LIM";
 private final static String PAT = "PAT";
 private final static String PRE = "PRE";
 private final static String PRT = "PRT";
 private final static String PPH = "PPH";
 private final static String PWD = "PWD";
 private final static String RDA = "RDA";
 private final static String RDR = "RDR";
 private final static String RNM = "RNM";
 private final static String SRC = "SRC";
 private final static String STA = "STA";
 private final static String TRC = "TRC";
 private final static String USR = "USR";

 private static final byte TRACE_DATA = (byte) 1;
 private static final byte TRACE_EXEC = (byte) 2;
 private static final byte TRACE_JSCH = (byte) 128;

 // Define the constructor
 public $NAM10()
 { // Detect and take advantage of an authentication agent
   if (System.getenv("SSH_AUTH_SOCK") != null)
   {traceln(TRACE_EXEC, "Authentication agent detected");
    agt = new RdaAgent(pre, lvl);
   }
 }

 // --- Session methods -------------------------------------------------------

 // Create a session
 public Session createSession(String usr, String hst, int prt)
 {Session ses = null;

  // Create a new session
  try
  {JSch ctl1 = new JSch();
   RdaJsch ctl2 = new RdaJsch(pre, lvl);
   Object ctl;

   traceln(TRACE_EXEC, "Create a new JSCH session");

   // Detect old JSCH version
   traceln(TRACE_EXEC, "Check the Jsch version");
   try
   {if (ctl1.getClass().getDeclaredField("VERSION") != null)
     ;
    ctl = ctl1;
   }
   catch (Exception err)
   {traceln(TRACE_EXEC, "No VERSION detected => assuming pre 0.1.46");
    ctl = (RdaJsch) ctl2;
    old = true;
   }
   if ((lvl & TRACE_JSCH) == TRACE_JSCH)
    ((JSch) ctl).setLogger(log);

   // Create the session
   if (agt == null)
   {traceln(TRACE_EXEC, "Create a session (no authentication agent)");
    ses = ((JSch) ctl).getSession(usr, hst, prt);
   }
   else if (old)
   {traceln(TRACE_EXEC, "Create a session (old JSCH version)");
    RdaIdentityCache rep = new RdaIdentityCache(agt);
    ((RdaJsch) ctl).setIdentityRepository(rep);
    ses = ((RdaJsch) ctl).getSession(usr, hst, prt);
   }
   else
   {try
    {traceln(TRACE_EXEC, "Create a session (dynamic approach)");
     IdentityRepository rep = (IdentityRepository) new RdaIdentityCache(agt);
     Method[] methods = ctl.getClass().getDeclaredMethods();
     for (int off = 0 ; off < methods.length ; ++off)
     {if ((methods[off].getName().compareTo("setIdentityRepository")) == 0)
      {traceln((byte) 8, "Setter found, dynamic invoke ....");
       methods[off].invoke((JSch) ctl, rep);
      }
     }
     ses = ((JSch) ctl).getSession(usr, hst, prt);
    }
    catch (Exception err)
    {err.printStackTrace();
     traceln(TRACE_EXEC, "Create a session (static approach)");
     IdentityRepository rep = (IdentityRepository) new RdaIdentityCache(agt);
     ((RdaJsch) ctl).setIdentityRepository((RdaIdentityCache) rep);
     ses = ((JSch) ctl).getSession(usr, hst, prt);
    }
   }
  }
  catch (JSchException err)
  {// setting commnand to foo to consume pre prompt input
   traceln(TRACE_EXEC, "Exception when establishing session: " +
                       err.getMessage());
   if (agt != null)
    agt.end();
   System.exit(1);
  }
  catch (Exception err)
  {err.printStackTrace();
  }
  finally
  {con = false;
  }
  return ses;
 }

 // Get a session
 public Session getSession(Hashtable<String,String> ctx)
 {return getSession(ctx, false);
 }

 public Session getSession(Hashtable<String,String> ctx, Boolean flg)
 {String hst, pph, pwd, usr;

  // Determine the requested connection
  hst = ctx.containsKey(HST) ? ctx.get(HST) : this.hst;
  pph = ctx.containsKey(PPH) ? ctx.get(PPH) : this.pph;
  pwd = ctx.containsKey(PWD) ? ctx.get(PWD) : this.pwd;
  usr = ctx.containsKey(USR) ? ctx.get(USR) : this.usr;
  traceln(TRACE_EXEC, " - Host: " + hst);
  traceln(TRACE_EXEC, " - Port: " + prt);
  traceln(TRACE_EXEC, " - User: " + usr);
  if (pwd.length() > 0)
   traceln(TRACE_EXEC, " - Password: ***");
  if (pph.length() > 0)
   traceln(TRACE_EXEC, " - Passphrase: ***");

  // Create the session when needed
  if (ses == null)
   ses = createSession(usr, hst, prt);
  else if (!usr.equals(ses.getUserName()) || !hst.equals(ses.getHost()))
  {if (col != null)
   {col.end();
    col = null;
   }
   if (con)
    ses.disconnect();
   ses = createSession(usr, hst, prt);
  }

  // Connect to the session
  if (!con)
  {try
   {traceln(TRACE_EXEC, "Set the user information and connect");
    RdaUser uio = new RdaUser();
    if (pwd.length() > 0)
     uio.setPassword(pwd);
    if (pph.length() > 0)
     uio.setPassphrase(pph);
    ses.setUserInfo(uio);
    ses.connect();
    //ses.setTimeout(2000);
    con = true;
   }
   catch (Exception err)
   {msg = err.getMessage();
    ses = null;
    traceln(TRACE_EXEC, "Could not open ssh channel:" + msg);
    //return null;
   }
  }

  // Initiate a collector when requested
  if (flg)
  {if (col != null)
    col.end();
   col = new RdaCollector(usr,pwd,pre,lvl);
  }

  // Return the session
  return ses;
 }

 // --- Request methods -------------------------------------------------------

 // Execute a COLLECT request
 public boolean doCollect(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {traceln(TRACE_EXEC, "Treat a COLLECT request");

   // Perform the collection
   if (col != null)
    return col.collect(ofh, efh, ctx);

   // Report a missing collector
   traceln(TRACE_EXEC, "Missing collector");
   if (sta)
    efh.println("Error: Missing collector");
  }
  catch (Exception err)
  {if (sta)
    efh.println("Error:" + err.toString());
   else
   {System.err.println("COLLECT exception: " + err.toString());
    return true;
   }
  }
  return false;
 }

 // Execute a DEFAULT request
 public boolean doDefault(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {String cur = null;
  Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {traceln(TRACE_EXEC, "Treat a DEFAULT request");

   if (ctx.containsKey(cur = AGT) && agt != null)
    agt.setTrace(new String(ctx.get(AGT)));
   if (ctx.containsKey(cur = CMD))
    this.shl = new String(ctx.get(CMD));
   if (ctx.containsKey(cur = HST))
    this.hst = new String(ctx.get(HST));
   if (ctx.containsKey(cur = LIM))
   {Integer val = new Integer(ctx.get(LIM));
    this.lim = val.intValue();
   }
   if (ctx.containsKey(cur = PRE))
    setPrefix(new String(ctx.get(PRE)));
   if (ctx.containsKey(cur = PRT))
   {Integer val = new Integer(ctx.get(PRT));
    this.prt = val.intValue();
   }
   if (ctx.containsKey(cur = PPH))
    this.pph = new String(ctx.get(PPH));
   if (ctx.containsKey(cur = RDA) && agt != null)
    agt.setAgent(new String(ctx.get(RDA)));
   if (ctx.containsKey(cur = PWD))
    this.pwd = new String(ctx.get(PWD));
   if (ctx.containsKey(cur = TRC))
   {Integer val = new Integer(ctx.get(TRC));
    setLevel((byte) val.intValue());
   }
   if (ctx.containsKey(cur = USR))
    this.usr = new String(ctx.get(USR));
   if (sta)
    efh.println("Exit:0");
  }
  catch (Exception err)
  {if (cur == null)
   {System.err.println("DEFAULT exception: " + err.toString());
    return true;
   }
   traceln(TRACE_EXEC, "Error when treating " + cur + ":\\n " +
                       err.toString());
   if (sta)
    efh.println("Error:" + cur + "|" + err.toString());
  }
  return false;
 }

 // Execute a EXEC request
 public boolean doExec(PrintStream ofh, PrintStream efh, String dat,
   Hashtable<String,String> ctx)
 {ChannelExec chn;
  Session ses;
  Boolean flg = (lvl & TRACE_DATA) == TRACE_DATA;
  Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {String cmd;

   traceln(TRACE_EXEC, "Treat an EXEC request");

   // Get a connected session
   ses = getSession(ctx);
   if (ses == null)
   {traceln(TRACE_EXEC, "Connection error: " + msg);
    if (sta)
     efh.println("Error: " + msg);
    return false;
   }

   // Determine the command to execute
   if (ctx.containsKey(CMD))
    cmd = new String(ctx.get(CMD));
   else
    cmd = shl;
   if (flg)
    System.out.println(pre + "< Command: " + cmd + "\\n" +
                       pre + "< Input:\\n" + dat);

   // Create the execution channel
   traceln(TRACE_EXEC, "Create the channel");
   chn = (ChannelExec) ses.openChannel("exec");
   chn.setCommand(cmd);
   chn.connect();
   if (efh != null && !sta)
    chn.setErrStream(efh);

   // Pass the input to the remote command
   traceln(TRACE_EXEC, "Send the command input");
   OutputStream ocs = chn.getOutputStream();
   if (dat.length() > 0)
   {ocs.write(dat.getBytes());
    ocs.flush();
   }
   ocs.close();

   // Read command results
   traceln(TRACE_EXEC, "Read command results");
   BufferedReader ics =
     new BufferedReader(new InputStreamReader(chn.getInputStream()));
   String lin;
   while ((lin = ics.readLine()) != null)
   {ofh.println(lin);
    if (flg)
     System.out.println(pre + "> " + lin);
   }
   traceln(TRACE_EXEC, "Report the execution status");
   if (sta)
    efh.println("Exit:"+chn.getExitStatus());

   // Disconnect the channel and terminate the request
   traceln(TRACE_EXEC, "Disconnect the channel");
   chn.disconnect();
   traceln(TRACE_EXEC, "Terminate the EXEC request");
  }
  catch (Exception err)
  {traceln(TRACE_EXEC, "EXEC exception: " + err.toString());
   if (sta)
    efh.println("Error:" + err.toString());
   else
    System.err.println("EXEC exception: " + err.toString());
   return true;
  }
  return false;
 }

 // Execute a GET request
 public boolean doGet(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {ChannelSftp chn;
  Session ses;
  Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {String dst, src;
   Boolean flg = ctx.containsKey(FLG);

   traceln(TRACE_EXEC, "Treat a GET request");

   if (ctx.containsKey(DST))
   {dst = ctx.get(DST);

    // Get a connected session
    ses = getSession(ctx);
    if (ses == null)
    {traceln(TRACE_EXEC, "Connection error: " + msg);
     if (sta)
      efh.println("Error: " + msg);
     return false;
    }

    // Create the SFTP channel
    traceln(TRACE_EXEC, "Create the channel");
    chn = (ChannelSftp) ses.openChannel("sftp");
    chn.connect();

    // Get the requested files
    if (ctx.containsKey(FIL))
     exec_get(chn, dst, ctx.get(FIL));
    else if (ctx.containsKey(DIR))
    {String nam, pat;

     src = ctx.get(DIR);
     if (ctx.containsKey(PAT))
     {// Validate the destination directory
      File fil = new File(dst);
      if (!(fil.exists() || fil.mkdir()) || !fil.isDirectory())
       throw new SftpException(1, "Missing or invalid directory " + dst);

      // Get the files
      pat = src + "/" + ctx.get(PAT);
      traceln(TRACE_EXEC, "Get files matching " + pat);
      for (Object obj : chn.ls(pat))
      {LsEntry itm = (LsEntry)obj;

       nam = itm.getFilename();
       if (!itm.getAttrs().isDir())
        exec_get(chn, dst, src + "/" + nam);
       else if (".".equals(nam) || "..".equals(nam) || !flg)
        traceln(TRACE_EXEC, "Skipping directory: " + src + "/" + nam);
       else
        exec_mget(chn, dst + "/" + nam, src + "/" + nam);
      }
     }
     else
      exec_mget(chn, dst, src);
    }

    // Disconnect the channel and terminate the request
    traceln(TRACE_EXEC, "Disconnect the channel");
    chn.disconnect();
    traceln(TRACE_EXEC, "Terminate the GET request");

    // Indicate the successful completion
    traceln(TRACE_EXEC, "Transfer complete");
    if (sta)
     efh.println("Exit:0");
   }
  }
  catch (Exception err)
  {if (sta)
    efh.println("Error:" + err.toString());
   else
   {System.err.println("GET exception: " + err.toString());
    return true;
   }
  }
  return false;
 }

 // Execute a LOGIN request
 public boolean doLogin(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {traceln(TRACE_EXEC, "Treat a LOGIN request");

   // Get a connected session
   ses = getSession(ctx, true);
   if (ses == null)
   {traceln(TRACE_EXEC, "Connection error: " + msg);
    if (sta)
     efh.println("Error: " + msg);
    return false;
   }

   // Perform the collector login
   col.login(ses, ofh, efh, ctx);
  }
  catch (Exception err)
  {if (sta)
    efh.println("Error:" + err.toString());
   else
   {System.err.println("LOGIN exception: " + err.toString());
    return true;
   }
  }
  return false;
 }

 // Execute a LOGOUT request
 public boolean doLogout(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {traceln(TRACE_EXEC, "Treat a LOGOUT request");

   // Close any existing collector
   if (col != null)
   {col.end();
    col = null;
   }

   // Indicate the sucessful completion
   if (sta)
    efh.println("Exit:0");
  }
  catch (Exception err)
  {if (sta)
    efh.println("Error:" + err.toString());
   else
   {System.err.println("LOGOUT exception: " + err.toString());
    return true;
   }
  }
  return false;
 }

 // Execute a PUT request
 public boolean doPut(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {ChannelSftp chn;
  Session ses;
  Boolean sta = ctx.containsKey(STA) && efh != null;

  try
  {String rdr, src;

   traceln(TRACE_EXEC, "Treat a PUT request");

   if (ctx.containsKey(RDR))
   {// Get a connected session
    ses = getSession(ctx);
    if (ses == null)
    {traceln(TRACE_EXEC, "Connection error: " + msg);
     if (sta)
      efh.println("Error: " + msg);
     return false;
    }

    // Create the SFTP channel
    traceln(TRACE_EXEC, "Create the channel");
    chn = (ChannelSftp) ses.openChannel("sftp");
    chn.connect();

    // Validate the remote directory
    rdr = exec_mkdir(chn, ctx.get(RDR));

    // Put the files
    if (ctx.containsKey(SRC))
     exec_put(chn, ctx.containsKey(RNM) ? rdr + "/" + ctx.get(RNM) : rdr,
              ctx.get(SRC));
    else if (ctx.containsKey(SRC + "#"))
    {File fil;
     Boolean flg = ctx.containsKey(FLG);
     Integer max = new Integer(ctx.get(SRC + "#"));

     for (int off = 1 ; off <= max.intValue() ; ++off)
     {src = ctx.get(SRC + off);
      fil = new File(src);
      if (!fil.isDirectory())
       exec_put(chn, rdr, fil.getAbsolutePath());
      else if (flg)
       exec_mput(chn, exec_mkdir(chn, rdr + "/" + fil.getName()),
                 fil.getAbsolutePath());
      else
       traceln(TRACE_EXEC, "Skipping directory " + fil.getAbsolutePath());
     }
    }

    // Disconnect the channel and terminate the request
    traceln(TRACE_EXEC, "Disconnect the channel");
    chn.disconnect();
    traceln(TRACE_EXEC, "Terminate the PUT request");

    // Indicate the successful completion
    traceln(TRACE_EXEC, "Transfer complete");
    if (sta)
     efh.println("Exit:0");
   }
  }
  catch (Exception err)
  {if (sta)
    efh.println("Error:" + err.toString());
   else
   {System.err.println("PUT exception: " + err.toString());
    return true;
   }
  }
  return false;
 }

 // Execute a TEST request
 public boolean doTest(PrintStream ofh, PrintStream efh,
   Hashtable<String,String> ctx)
 {traceln(TRACE_EXEC, "Treat a TEST request");
  try
  {Session ses = getSession(ctx);
   if (ses == null)
    ofh.println("Error: " + msg);
   else
    ofh.println("OK Connect");
  }
  catch (Exception err)
  {System.err.println("TEST exception: " + err.toString());
   return true;
  }
  return false;
 }

 // --- Other methods ---------------------------------------------------------

 // Close all instances operations
 public void end()
 {traceln(TRACE_EXEC, "End the SSH instance");

  // Disconnect the session
  if (ses != null)
   ses.disconnect();

  // Close an existing collector
  if (col != null)
  {col.end();
   col = null;
  }

  // Close the RDA agent interface
  if (agt != null)
  {agt.end();
   agt = null;
  }
 }

 // Modify the trace level
 public void setLevel(byte lvl)
 {this.lvl = lvl;
  if (agt != null)
   agt.setLevel(lvl);
  if (col != null)
   col.setLevel(lvl);
 }

 // Modify the trace prefix
 public void setPrefix(String pre)
 {this.pre = pre;
  if (agt != null)
   agt.setPrefix(pre);
  if (col != null)
   col.setPrefix(pre);
 }

 // Display a trace line
 public void traceln(byte msk, String txt)
 {if ((lvl & msk) == msk)
   System.out.println(pre + "/" +mod + "[" + msk + "]: " + txt);
 }

 // --- Private methods -------------------------------------------------------

 // Get a file
 private void exec_get(ChannelSftp chn, String dst, String src)
   throws SftpException
 {traceln(TRACE_EXEC, " " + src + " -> " + dst);
  chn.get(src, dst);
 }

 // Get all files recursively from a sub directory
 private void exec_mget(ChannelSftp chn, String dst, String src)
   throws SftpException
 {String nam;

  traceln(TRACE_EXEC, "Treating directory: " + src);

  // Validate the destination directory
  File fil = new File(dst);
  if (!(fil.exists() || fil.mkdir()) || !fil.isDirectory())
   throw new SftpException(1, "Missing or invalid directory " + dst);

  // Get the file
  for (Object obj : chn.ls(src))
  {LsEntry itm = (LsEntry)obj;

   nam = itm.getFilename();
   if (!itm.getAttrs().isDir())
    exec_get(chn, dst, src + "/" + nam);
   else if (".".equals(nam) || "..".equals(nam))
    traceln(TRACE_EXEC, "Skipping directory: " + src + "/" + nam);
   else
    exec_mget(chn, dst + "/" + nam, src + "/" + nam);
  }
 }

 // Create a remote directory when needed
 private String exec_mkdir(ChannelSftp chn, String dir)
   throws SftpException
 {SftpATTRS sta;

  try
  {sta = chn.stat(dir);
  }
  catch (Exception err)
  {chn.mkdir(dir);
   sta = chn.stat(dir);
  }
  if (sta.isDir())
   return dir;
  throw new SftpException(1, "Missing or invalid remote directory " + dir);
 }

 // Put all files from a directory
 private void exec_mput(ChannelSftp chn, String dst, String src)
   throws SftpException
 {File dir = new File(src);
  String nam;

  for (File fil : dir.listFiles())
  {nam = fil.getName();
   if (!fil.isDirectory())
    exec_put(chn, dst, fil.getAbsolutePath());
   else if (".".equals(nam) || "..".equals(nam))
    traceln(TRACE_EXEC, "Skipping directory: " + fil.getAbsolutePath());
   else
    exec_mput(chn, exec_mkdir(chn, dst + "/" + nam), fil.getAbsolutePath());
  }
 }

 // Put a file
 private void exec_put(ChannelSftp chn, String dst, String src)
   throws SftpException
 {traceln(TRACE_EXEC, " " + src + " -> " + dst);
  chn.put(src, dst);
 }
}
EOF

my $NAM11 = 'RdaJsch';
my $COD11 = <<EOF;
package $PKG2;

import java.io.PrintStream;
import java.lang.reflect.Field;

import $PKG1.JSch;

public class $NAM11 extends JSch
{// Define the object attributes
 private String  pre ="JSCH";     // Trace prefix
 private String  mod ="$NAM11";   // Trace module
 private byte    lvl = (byte) 0;  // Trace level

 // Define the common constants
 private static final byte TRACE = (byte) 4;

 // Define the constructors
 public $NAM11()
 {super();
 }

 public $NAM11(String pre, byte lvl)
 {super();
  this.pre = pre;
  this.lvl = lvl;
 }

 // Initialize the identity repository for old JSCH versions
 public synchronized void setIdentityRepository(RdaIdentityCache rep)
   throws IllegalArgumentException, IllegalAccessException
 {Field[] tbl = this.getClass().getSuperclass().getDeclaredFields();
  for (int off = 0 ; off < tbl.length ; ++off)
  {if (tbl[off].getName().compareTo("identities") == 0)
   {traceln(TRACE, "Old version of JSch detected");
    tbl[off].setAccessible(true);
    tbl[off].set(this, rep.getIdentities());
   }
  }
 }

 // Define the trace method
 public void traceln(byte msk, String txt)
 {if ((lvl & msk) == msk)
   System.out.println(pre + "/" + mod + "[" + msk + "]: " + txt);
 }
}
EOF

my $NAM12 = 'RdaUser';
my $COD12 = <<EOF;
package $PKG2;

import $PKG1.UIKeyboardInteractive;
import $PKG1.UserInfo;

public class $NAM12 implements UserInfo, UIKeyboardInteractive
{// Define the object attributes
 String pwd = null;  // Password
 String pph = null;  // Passphrase

 // Define the public methods
 public String getPassphrase()
 {return pph;
 }

 public String getPassword()
 {return pwd;
 }

 public String[] promptKeyboardInteractive(String dst,
                                           String nam,
                                           String ins,
                                           String[] dsp,
                                           boolean[] ech)
 {String[] rsp = new String[dsp.length];
  rsp[0] = pwd;
  return rsp;
 }

 public boolean promptPassphrase(String msg)
 {return true;
 }

 public boolean promptPassword(String msg)
 {return true;
 }

 public boolean promptYesNo(String str)
 {return true;
 }

 public void setPassphrase(String pph)
 {this.pph = pph;
 }

 public void setPassword(String pwd)
 {this.pwd = pwd;
 }

 public void showMessage(String msg)
 {
 }
}
EOF

# Define the inline descriptor
%INLINE = (
  cls => 'RDA::Object::Java',
  top => [$NAM, [$COD], $VER],
  dep => [['I', $NAM2,  [$COD2],  $VER, $PKG1],
          ['C', $NAM4,  [$COD4],  $VER, $PKG2],
          ['C', $NAM5,  [$COD5],  $VER, $PKG2],
          ['C', $NAM7,  [$COD7],  $VER, $PKG2],
          ['I', $NAM9,  [$COD9],  $VER, $PKG2],
          ['C', $NAM12, [$COD12], $VER, $PKG2],
          ['C', $NAM3,  [$COD3],  $VER, $PKG2],
          ['C', $NAM8,  [$COD8],  $VER, $PKG2],
          ['C', $NAM11, [$COD11], $VER, $PKG2],
          ['C', $NAM6,  [$COD6],  $VER, $PKG2],
          ['C', $NAM10, [$COD10], $VER, $PKG2],
         ],
  );

# Define the global private constants
my $END = "/QUIT\n";
my $OUT = qr#timeout#;
my $WRK = 'jsch.tmp';

# Define the global private variables
my %tb_cnv = (
  SRC => \&_cnv_array,
  );
my %tb_cmd = map {$_ => 1}
  qw(COLLECT DEFAULT EXEC GET LOGIN LOGOUT META PUT TEST);

# Report the module version number
sub Version
{ $VERSION;
}

=head2 S<$h = RDA::Driver::Jsch-E<gt>new($agent)>

The remote access manager object constructor. It takes the agent object
reference as an argument.

=head2 S<$h-E<gt>new($session)>

The remote session manager object constructor. It takes the remote session
object reference as an argument.

C<RDA::Driver::Jsch> is represented by a blessed hash reference. The
following special keys are used:

=over 12

=item S<    B<'-agt'> > Reference to the agent object (M,S)

=item S<    B<'-api'> > Version of the Java interface (M,S)

=item S<    B<'-cod'> > Reference to the main Java object (M,S)

=item S<    B<'-ctl'> > Reference to the language control (M,S)

=item S<    B<'-die'> > Last die message (M,S)

=item S<    B<'-fil'> > Error file (M)

=item S<    B<'-hnd'> > Communication handler (M,S)

=item S<    B<'-ief'> > Interface error file (M,S)

=item S<    B<'-lim'> > Default execution limit (S)

=item S<    B<'-lin'> > Stored lines (S)

=item S<    B<'-lng'> > Interface language (M,S)

=item S<    B<'-msg'> > Last message (M,S)

=item S<    B<'-nod'> > Node identifier (M,S)

=item S<    B<'-out'> > Timeout indicator (M,S)

=item S<    B<'-pid'> > Process identifier of the Java interface (M,S)

=item S<    B<'-pre'> > Trace prefix (M,S)

=item S<    B<'-ses'> > Reference to the session object (S)

=item S<    B<'-skp'> > Skip indicator (M,S)

=item S<    B<'-sta'> > Last captured exit code (M,S)

=item S<    B<'-trc'> > Trace indicator (M,S)

=item S<    B<'-wrk'> > Reference to the work file manager (M,S)

=back

Internal keys are prefixed by a dash.

=cut

sub new
{ my ($cls, $ses) = @_;
  my ($nod);

  # Create the object and return its reference
  $nod = $ses->get_oid;
  ref($cls)
    ? bless {
        -agt => $cls->{'-agt'},
        -api => $cls->{'-api'},
        -cod => $cls->{'-cod'},
        -ctl => $cls->{'-ctl'},
        -lim => $ses->get_info('lim'),
        -lin => [],
        -lng => $cls->{'-lng'},
        -msg => undef,
        -nod => $nod,
        -pre => $cls->{'-agt'}->get_setting("REMOTE_$nod\_PREFIX", $nod),
        -out => 0,
        -ses => $ses,
        -skp => 0,
        -sta => 0,
        -trc => $cls->{'-trc'} || $ses->get_level,
        -wrk => $cls->{'-wrk'},
        }, ref($cls)
    : _create_manager(@_);
}

=head2 S<$h-E<gt>as_type>

This method returns the driver type.

=cut

sub as_type
{ 'jsch';
}

=head2 S<$h-E<gt>delete>

This method deletes the object.

=cut

sub delete
{ # Close the communication handle
  _end($_[0]);

  # Delete the object
  undef %{$_[0]};
  undef $_[0];
}

=head2 S<$h-E<gt>get_api>

This method returns the version of the Java interface. It returns an undefined
value in case of problems.

=cut

sub get_api
{ shift->{'-api'};
}

=head2 S<$h-E<gt>get_lines>

This method returns the lines stored during the last command execution.

=cut

sub get_lines
{ @{shift->{'-lin'}};
}

=head2 S<$h-E<gt>get_message>

This method returns the last message.

=cut

sub get_message
{ shift->{'-msg'};
}

=head2 S<$h-E<gt>get_status>

This method returns the last captured status.

=cut

sub get_status
{ shift->{'-sta'};
}

=head2 S<$h-E<gt>has_timeout>

This method indicates whether the last request encountered a timeout.

=cut

sub has_timeout
{ shift->{'-out'};
}

=head2 S<$h-E<gt>is_skipped>

This method indicates whether the last request was skipped.

=cut

sub is_skipped
{ shift->{'-skp'};
}

=head2 S<$h-E<gt>need_password([$var])>

This method indicates whether the last request encountered a timeout.

=cut

sub need_password
{ my ($slf, $var) = @_;
  my ($ret);

  $ret = -1;
  $var = {} unless ref($var) eq 'HASH';
  $var->{'FCT'} = [\&_check_connect, \$ret];
  $slf->request('TEST', $var);
  $ret;
}

=head2 S<$h-E<gt>need_pause>

This method indicates whether the current connection could require a pause for
providing a password.

=cut

sub need_pause
{ 0;
}

=head2 S<$h-E<gt>request($cmd,$var,@dat)>

This method executes a requests and returns the result file. It supports the
following commands:

=over 2

=item * C<COLLECT>

It submits a command to the remote servers and collects the results. It manages
the command and continuation prompts.

=item * C<DEFAULT>

It changes some interface parameters.

=item * C<EXEC>

It submits one or more commands to the remote servers and collects the results.

=item * C<LOGIN>

It closes any existing session and starts a new session with the remote server.

=item * C<LOGOUT>

It ends any current session with the remote server.

=item * C<META>

It returns the interface information.

=item * C<QUIT>

It closes the interface.

=back

It returns a negative value in case of problems.

=cut

sub request
{ my ($slf, $cmd, $var, @dat) = @_;
  my ($buf, $cnt, $err, $fct, $lim, $sta, $tmp, $trc, $wrk, @arg);

  local $SIG{'__WARN__'} = sub {};

  # Validate the request
  $slf->{'-out'} = 0;
  return -30 unless defined($cmd) && ref($var) eq 'HASH';
  return -31 unless exists($tb_cmd{$cmd});

  # Get the communication handle
  unless (_get_handle($slf))
  { $slf->{'-skp'} = 1 unless defined($slf->{'-msg'});
    return -32;
  }

  # Execute the request
  eval {
    local $SIG{'ALRM'} = 'IGNORE' if exists($SIG{'ALRM'});
    local $SIG{'PIPE'} = sub {die "Pipe broken\n"};

    # Prepare the request
    $trc = $slf->{'-pre'}.'] ' if $slf->{'-trc'};
    $lim = exists($var->{'LIM'}) ? $var->{'LIM'} : 0;
    if (exists($var->{'FCT'}))
    { ($fct, @arg) = @$fct if ref($fct = delete($var->{'FCT'})) eq 'ARRAY';
    }
    elsif ($cmd eq 'EXEC')
    { if (exists($var->{'FLG'}))
      { ($fct, @arg) = (\&_load_lines, $var->{'FLG'});
      }
      elsif (exists($var->{'OUT'}))
      { $wrk = delete($var->{'OUT'});
        ($fct, @arg) = (ref($wrk) ? \&_write_result : \&_copy_result, $wrk,
          delete($var->{'NEW'}));
      }
    }
    $wrk = $tmp = $slf->{'-wrk'}->get_work($WRK, 1);
    $var->{'WRK'} = RDA::Object::Rda->native($wrk);
    $wrk =~ s/\.tmp$/.txt/;
    1 while unlink($wrk);
    if (exists($var->{'STA'}))
    { $sta = $wrk;
      $sta =~ s/\.txt$/.sta/;
      $var->{'ERR'} = RDA::Object::Rda->native($sta);
      $var->{'STA'} = 1;
      $slf->{'-sta'} = -33;
    }
    else
    { $slf->{'-sta'} = 0;
      $var->{'ERR'} = RDA::Object::Rda->native($var->{'ERR'})
        if exists($var->{'ERR'});
    }

    # Amend some driver attributes
    foreach my $key (keys(%$var))
    { &{$tb_cnv{$key}}($slf, $var, $key) if exists($tb_cnv{$key});
    }
    if ($cmd eq 'DEFAULT')
    { $slf->{'-lim'} = $var->{'MAX'} if exists($var->{'MAX'});
      $slf->{'-pre'} = $var->{'PRE'} if exists($var->{'PRE'});
      $slf->{'-trc'} = $var->{'TRC'} if exists($var->{'TRC'});
    }

    # Send the request
    print join("\n", $trc."Executing a $cmd request",
      map {m/^(PPH|PWD)$/ ? "$trc  $_=***" : "$trc  $_='".$var->{$_}."'"}
        sort keys(%$var))."\n"
      if $trc;
    $buf = @dat
      ? join("\n", (map {$_."='".$var->{$_}."'"} keys(%$var)), '#'.$cmd,
                   @dat, "/\n")
      : join("\n", (map {$_."='".$var->{$_}."'"} keys(%$var)), '/'.$cmd, '');
    $slf->{'-hnd'}->syswrite($buf, length($buf));

    # Wait for the request completion
    print $trc."Waiting the $cmd results\n" if $trc;
    $cnt = $lim;
    $err = $slf->{'-ief'};
    while (! -e $wrk)
    { die _get_error($err)."\n" if -s $err;
      die "Request timeout\n"   if $lim && --$cnt < 0;
      print $trc."* Sleeping ($cnt)\n" if $trc;
      sleep(1);
    }
    die _get_error($err)."\n" if -s $err;

    # Treat the result when requested
    &$fct($slf, $wrk, @arg) if $fct;
    if ($sta && -f $sta)
    { _check_status($slf, $sta);
      1 while unlink($sta);
    }
    1 while unlink($wrk);
    };

  # Indicate the completion status
  if ($buf = $@)
  { $buf =~ s/[\n\r\s]+$//;
    $slf->{'-msg'} = $buf;
    print $trc."Error: $buf\n" if $trc;
    RDA::Object::Rda->kill_child($slf->{'-pid'});
    $slf->{'-hnd'}->close;
    $slf->{'-hnd'} = undef;
    if ($buf =~ $OUT)
    { $slf->{'-out'} = 1;
      $slf->{'-sta'} = -34;
    }
    else
    { $slf->{'-sta'} = -35;
    }

    # Treat partial results when requested
    eval {
      if ($fct && exists($var->{'TMP'}))
      { rename($tmp, $wrk)      if -f $tmp;
        &$fct($slf, $wrk, @arg) if -f $wrk;
      }
      };
  }
  else
  { $slf->{'-wrk'}->clean_work($WRK);
  }
  $slf->{'-sta'};
}

# --- Result handling routines ------------------------------------------------

# Check a connection status
sub _check_connect
{ my ($slf, $wrk, $var) = @_;
  my ($ifh, $trc);

  $ifh = IO::File->new;
  $trc = $slf->{'-pre'}.'] ' if $slf->{'-trc'};
  print $trc."Check the connection status\n" if $trc;
  $$var = 1;
  if ($ifh->open("<$wrk"))
  { while (<$ifh>)
    { print $trc.'* '.$_ if $trc;
      if (m/^OK\b/)
      { $$var = 0;
        last;
      }
    }
    $ifh->close;
  }
}

# Check an execution status
sub _check_status
{ my ($slf, $wrk) = @_;
  my ($ifh, $trc);

  $ifh = IO::File->new;
  $trc = $slf->{'-pre'}.'] ' if $slf->{'-trc'};
  print $trc."Check the execution status\n" if $trc;
  if ($ifh->open("<$wrk"))
  { while (<$ifh>)
    { print $trc.'* '.$_ if $trc;
      if (m/^Exit:\s*(\-?\d+)/)
      { $slf->{'-sta'} = $1 << 8;
      }
      elsif (m/^Error:\s*(.*?)[\n\r\s]*$/)
      { $slf->{'-msg'} = $1;
      }
    }
    $ifh->close;
  }
}

# Copy the result into a file
sub _copy_result
{ my ($slf, $src, $dst, $new) = @_;
  my ($buf, $ifh, $lgt, $ofh);

  print $slf->{'-pre'}."] Tranferring results\n" if $slf->{'-trc'};
  $ifh = IO::File->new;
  $ofh = IO::File->new;
  $ifh->open("<$src")
    or die "Cannot read results from '$src':\n $!\n";
  $ofh->open($dst, $new ? $CREATE : $APPEND, $FIL_PERMS)
    or die "Cannot transfer results into '$dst':\n $!\n";
  binmode($ofh);
  while ($lgt = $ifh->sysread($buf, 65536))
  { die "Cannot write results into '$dst':\n $!\n"
      unless $ofh->syswrite($buf, $lgt) == $lgt;
  }
  $ifh->close;
  $ofh->close;
}

# Load the results
sub _load_lines
{ my ($slf, $wrk, $flg) = @_;
  my ($ifh);

  $ifh = IO::File->new;
  print $slf->{'-pre'}.'] Loading execution '
    .($flg ? 'results' : 'errors')."\n" if $slf->{'-trc'};
  if ($ifh->open("<$wrk"))
  { while (<$ifh>)
    { s/[\n\r\s]+$//;
      push(@{$slf->{'-lin'}}, $_) if $flg || m/RDA-\d{5}:/;
    }
    $ifh->close;
  }
}

# Load the interface information
sub _load_meta
{ my ($slf, $wrk) = @_;
  my ($ifh, $trc);

  $ifh = IO::File->new;
  $trc = $slf->{'-pre'}.'] ' if $slf->{'-trc'};
  print $trc."Loading META results\n" if $trc;
  if ($ifh->open("<$wrk"))
  { while (<$ifh>)
    { print $trc.'* '.$_ if $trc;
      $slf->{$1} = $2 if m/^(\-\w+)\='(.*)'/;
    }
    $ifh->close;
  }
}

# Write the result into a report or a buffer
sub _write_result
{ my ($slf, $src, $dst, $new) = @_;
  my ($buf, $ifh, $lgt, $ofh);

  print $slf->{'-pre'}."] Tranferring results\n" if $slf->{'-trc'};
  $ifh = IO::File->new;
  $ifh->open("<$src")
    or die "Cannot read results from '$src':\n $!\n";
  while ($lgt = $ifh->sysread($buf, 65536))
  { die "Cannot write results into '$dst':\n $!\n"
      unless $ofh->syswrite($buf, $lgt) == $lgt;
  }
  $ifh->close;
}

# --- Conversion routines -----------------------------------------------------

sub _cnv_array
{ my ($slf, $var, $key) = @_;

  if (ref($var->{$key}) eq 'ARRAY')
  { my ($cnt);

    $cnt = 0;
    foreach my $val (@{delete($var->{$key})})
    { ++$cnt;
      $var->{$key.$cnt} = $val;
    }
    $var->{$key.'#'} = $cnt;
  }
}

# --- Internal routines -------------------------------------------------------

# Create the driver manager
sub _create_manager
{ my ($cls, $agt, $lim) = @_;
  my ($cod, $ctl, $lib, $slf, $trc);

  # Try to locate JSCH
  $trc = $agt->get_setting('JSCH_TRACE', 0);
  if (defined($lib = $agt->get_setting('REMOTE_JSCH_JAR')) && -r $lib)
  { print "JSCH] Use $lib\n" if $trc;
  }
  else
  { print "JSCH] Searching for jsch.jar ...\n" if $trc;
    return undef unless ($lib = _get_jar($agt));
    print "JSCH]  => $lib found\n" if $trc;
  }

  # Compile the Java interface
  eval {
    $ctl = $agt->get_inline;
    print "JSCH] Defining $NAM Java block ...\n" if $trc;
    $cod = $ctl->add_common(
      RDA::Object::Java->new(@{$INLINE{'top'}})->add_jar($lib)->add_sequence);
    foreach my $dep (@{$INLINE{'dep'}})
    { print "JSCH] Defining ".$dep->[1]." Java block ...\n" if $trc;
      $ctl->add_common($cod->add_dependency(
        RDA::Object::Java->new_block(@$dep)->add_jar($lib)));
    }
    };
  if ($@)
  { print "JSCH] Error in Java code generation:\nJSCH]  $@\n" if $trc;
    return undef;
  }

  # Create the driver manager object
  $slf = bless {
    -agt => $agt,
    -cod => $cod,
    -ctl => $ctl,
    -fil => RDA::Object::Rda->cat_file($ctl->get_cache, "$NAM.err"),
    -lib => $lib,
    -lng => $cod->get_language,
    -msg => undef,
    -nod => 'JSCH',
    -out => 0,
    -pre => 'JSCH',
    -sta => 0,
    -trc => $trc,
    -wrk => $agt->get_output,
    }, $cls;

  # Initialize the authentication agent
  $agt->get_remote->set_agent;

  # Request the interface information to test the interface
  request($slf, 'META', {FCT => [\&_load_meta], LIM => $lim})
    ? undef
    : _end($slf);
}

# Close the Java interface
sub _end
{ my ($slf) = @_;
  my ($hnd);

  if ($hnd = delete($slf->{'-hnd'}))
  { $hnd->syswrite($END, length($END));
    $hnd->close;
    delete($slf->{'-pid'});
  }
  $slf
}

# Get the Java error
sub _get_error
{ my ($err) = @_;
  my ($buf, $ifh);

  return 'Request error'
    unless -s $err && ($ifh = IO::File->new)->open("<$err");
  $buf = join("\n ", <$ifh>);
  $ifh->close;
  $buf;
}

# Get the communication handle
sub _get_handle
{ my ($slf) = @_;
  my ($msg, $trc);

  # Initialise the communication handle on the first call
  unless (exists($slf->{'-hnd'}))
  { $trc = $slf->{'-trc'};
    $slf->{'-cod'}->set_info('pre', $trc ? 'JSCH' : '');
    eval {$slf->{'-pid'} =
      $slf->{'-ctl'}->pipe_code($slf->{'-hnd'} = IO::File->new,
                                $slf->{'-lng'}, $NAM)};
    if ($msg = $@)
    { $msg =~ s/[\n\r\s]+$//;
      $slf->{'-msg'} = $msg;
      return $slf->{'-hnd'} = undef;
    }

    # Load some defaults
    if ($trc && exists($slf->{'-ses'}))
    { my ($val, %var);

      if ($val = $slf->{'-agt'}->get_setting('REMOTE_AGENT_LOG'))
      { $val = sprintf($val, $$);
        $var{'AGT'} = RDA::Object::Rda->is_unix
          ? RDA::Object::Rda->quote($val)
          : RDA::Object::Rda->short($val);
      }
      elsif ($trc & 0x0100)
      { $var{'AGT'} = 'RdaSsh.log';
      }
      $var{'LIM'} = $slf->{'-lim'} if $slf->{'-lim'};
      $var{'PRE'} = $slf->{'-pre'};
      $var{'RDA'} = $slf->{'-agt'}->get_setting('RDA_EXEC');
      $var{'TRC'} = $trc & 0xff;
      return $slf->{'-hnd'} = undef if $slf->request('DEFAULT', {%var});
    }
  }

  # Delete the previous message
  $slf->{'-msg'} = undef;

  # Return the remote handle
  $slf->{'-hnd'};
}

# Get jsch.jar location
sub _get_jar
{ my ($agt) = @_;
  my ($dir, $lib);

  return $lib
    if -r ($lib = RDA::Object::Rda->cat_file('da', 'lib', 'jsch.jar'));

  foreach my $key ($agt->grep_setting('(^|_)ORACLE_HOME$'))
  { return $lib
      if -d ($dir = RDA::Object::Rda->cat_dir($agt->get_setting($key)))
      && defined($lib = _get_jar_home($dir));
  }

  return $lib
    if exists($ENV{'ORACLE_HOME'})
    && -d ($dir = RDA::Object::Rda->cat_dir($ENV{'ORACLE_HOME'}))
    && defined($lib = _get_jar_home($dir));

  undef;
}

sub _get_jar_home
{ my ($dir) = @_;
  my ($lib);

  (-r ($lib = RDA::Object::Rda->cat_file($dir, 'oui', 'jlib',
                                         'jsch.jar')) ||
   -r ($lib = RDA::Object::Rda->cat_file($dir, 'sysman', 'jlib', 'j2ee',
                                         'jsch.jar')) ||
   -r ($lib = RDA::Object::Rda->cat_file($dir, 'sqldeveloper', 'jdev', 'lib',
                                         'jsch.jar')))
    ? $lib
    : undef;

}

1;

__END__

=head1 SEE ALSO

L<RDA::Agent|RDA::Agent>,
L<RDA::Object::Inline|RDA::Object::Inline>,
L<RDA::Object::Java|RDA::Object::Java>,
L<RDA::Object::Rda|RDA::Object::Rda>,
L<RDA::Object::Remote|RDA::Object::Remote>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002, 2012, Oracle and/or its affiliates. All rights reserved.

=head1 TRADEMARK NOTICE

Oracle and Java are registered trademarks of Oracle and/or its
affiliates. Other names may be trademarks of their respective owners.

=cut
