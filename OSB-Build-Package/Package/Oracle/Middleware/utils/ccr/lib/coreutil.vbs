' $Header: emll/lib/coreutil.vbs /main/93 2010/12/21 13:18:03 fmorshed Exp $
'
' coreutil.vbs
'
' Copyright (c) 2006, Oracle. All rights reserved.
'
'    NAME
'      coreutil.vbs - VBS utility functions
'
'    DESCRIPTION
'      This VBS script is a collection of functions that are used by the 
'      installation and running of the OCM collector.
'    MODIFIED
'      fmorshed  04/21/11 - Fix getNLevelJavaHome to work properly when JAVA_HOME
'                           is not defined at all.
'      fmorshed  04/20/11 - Make the output text for warning env vars not
'                           defined now but were defined in previoussnapshot
'                           the same as Linux.
'      fmorshed  03/24/11 - Make getNLevelJavaHome closer to Linux version of
'                           this method (determineJavaHome). In particular,
'                           look for existence of a java executable in
'                           JAVA_HOME before accepting it as the final place to
'                           find a java.
'      fmorshed  01/05/11 - Combine the prompts for configCCR invocations from
'                           deriveCCR.
'      fmorshed  12/19/10 - create the function isConfigHomeSetup
'      fmorshed  12/15/10 - getJavaHome now takes a verbose parameter
'      fmorshed  10/13/10 - Move some common declarations from configCCR to here.
'                           Change how interactive_runProc implements recognizing prompts
'                           to make it more robust and handle multiple prompts.
'                           Split instantiateSavedEnv into two methods so that its snap shot
'                           file lookup can be used by other methods.
'                           Add common method: getAllScriptArguments.
'      qding     04/15/10 - XbranchMerge qding_bug-9586850 from st_emll_10.3.3
'      qding     04/15/10 - bug 9586850, fix the array size and index of
'                           llSubdirs
'      qding     04/02/10 - diagexclusion.template file
'      ckalivar  02/18/10 - Bug 8900047: added method getComspec
'      ckalivar  02/15/10 - Bug 9057054: Deprecated Country code
'      aghanti   06/10/09 - XbranchMerge aghanti_bug-8574989 from
'                           st_emll_10.3.1
'      aghanti   06/05/09 - Bug 8574989 - Honor env var JAVA_HOME_CCR, with
'                           precedence over JAVA_HOME
'      tsubrama  04/15/09 - XbranchMerge tsubrama_bug8421098 from
'                           st_emll_10.3.1
'      tsubrama  04/14/09 - fix for 8421098
'      ckalivar  04/03/09 - added function getPropertyString
'      tsubrama  04/02/09 - XbranchMerge tsubrama_jarutilwin from main
'      tsubrama  02/06/09 - no jdk dependeny for jar
'      nmittal   12/23/08 - creating state/upload/external for gc harvester
'      ndutko    12/19/08 - Don't print a line if the message is null of length
'                           of 0
'      jsutton   12/09/08 - Alternate mechanism for getting home name
'      ckalivar  11/13/08 - make emocmrsp, no jdk and OH and JAVA_HOME not set,
'                           error generic
'      ndutko    09/03/08 - XbranchMerge ndutko_setup_flow_changes_10.3.0.1.0
'                           from st_emll_10.3.0
'      pparida   05/13/08 - 7038753: Fix typo in msg
'      ndutko    05/08/08 - XbranchMerge ndutko_bug-7028658 from st_emll_10.3.0
'      ndutko    05/08/08 - Support of getting JAVA_HOME in the great
'                           grandparent if the grandparent doesn't contain a
'                           jdk. Note, this is in support of opatch deployment.
'      ndutko    04/28/08 - XbranchMerge ndutko_fix_nt_lrgs from main
'      ndutko    04/23/08 - Handle trailing spaces
'      ndutko    04/21/08 - Definition of metalink_email_addr
'      ndutko    04/16/08 - MLID is no longer required for valid registration
'                           in ccr.properties if ccr.registration_mode=CSI
'      ndutko    03/17/08 - Handle case of no CSI being in the ccr.properties
'                           file
'      ndutko    03/17/08 - 
'      jsutton   11/06/07 - Strip quotes from ORACLE_CONFIG_HOME env var
'      jsutton   10/30/07 - Shared home update sync
'      jsutton   10/23/07 - XbranchMerge jsutton_bug-6519777 from
'                           st_emll_10.2.7
'      jsutton   10/22/07 - XbranchMerge jsutton_bug-6512241 from
'                           st_emll_10.2.7
'      jsutton   10/19/07 - XbranchMerge jsutton_bug-6513264 from
'                           st_emll_10.2.7
'      ndutko    10/19/07 - XbranchMerge ndutko_bug-6467643 from st_emll_10.2.7
'      ndutko    10/19/07 - XbranchMerge ndutko_bug-6512958 from st_emll_10.2.7
'      ndutko    10/19/07 - Conditionally display msgs based upon the state of
'                           the configuration of OCM
'      jsutton   10/18/07 - XbranchMerge jsutton_bug-6495447 from
'                           st_emll_10.2.7
'      ndutko    10/18/07 - In sharedHome mode, store the CCR_HOME directory in
'                           the collector.properties as ccr.binHome. Verify
'                           this against running command paths.
'      jsutton   10/18/07 - Enhance isOCMConfigured checks
'      jsutton   10/17/07 - XbranchMerge jsutton_bug-6504177 from
'                           st_emll_10.2.7
'      jsutton   10/17/07 - Abstract shortPathing a directory if needed
'      jsutton   10/15/07 - XbranchMerge jsutton_bug-6475562 from
'                           st_emll_10.2.7
'      ndutko    10/13/07 - XbranchMerge ndutko_bug-6495476 from st_emll_10.2.7
'      jsutton   10/12/07 - XbranchMerge jsutton_bug-6486401 from
'                           st_emll_10.2.7
'      ndutko    10/12/07 - XbranchMerge ndutko_bug-6497483 from st_emll_10.2.7
'      jsutton   10/12/07 - Shorten CCR_CONFIG_HOME
'      ndutko    10/12/07 - Provide a better msg for where OCH does not exist
'      jsutton   10/11/07 - Check full hierarchy when looking at properties
'                           files
'      ndutko    10/09/07 - XbranchMerge ndutko_bug-6488100 from st_emll_10.2.7
'      ndutko    10/09/07 - Determine whether this version of install supports
'                           shared installs and use constants vs checking for a
'                           directory.
'      jsutton   10/05/07 - Service name cleanup
'      jsutton   10/03/07 - Service name depends on ORACLE_CONFIG_HOME
'      jsutton   09/25/07 - Downcase ORACLE_CONFIG_HOME
'      jsutton   09/04/07 - Issues introduced from last transaction
'      jsutton   08/29/07 - Handle upgrade path from pre-shared-home versions
'      jsutton   08/27/07 - Create config/default subtree in CCR_CONFIG_HOME
'      jsutton   08/23/07 - Windows fixups for shared home work
'      jsutton   08/06/07 - Windows support for shared OH
'      jsutton   07/16/07 - Use IsNull check
'      jsutton   07/12/07 - Check return from EnumKey
'      jsutton   05/15/07 - XbranchMerge jsutton_bug-6054164 from
'                           st_emll_10.2.6
'      ndutko    05/10/07 - XbranchMerge ndutko_bug-6040007 from st_emll_10.2.6
'      jsutton   05/08/07 - Better regexp for cmd line options
'      ndutko    05/09/07 - Movement of getNonDHCPHostname to coreutils.vbs
'      nemalhot  05/04/07 - XbranchMerge nemalhot_bug-6016056 from main
'      nemalhot  05/02/07 - Adding isInteracitveUploadCmd() method.
'      pparida   04/23/07 - Fix bug 6006355: Look for absence of
'                           lib\deployPackages.vbs to distinguish GridAgent
'                           home in GetPaths() subroutine.
'      dcawley   04/13/07 - Use emCCR.bat
'      dcawley   04/13/07 - Fix EMSTATE
'      jsutton   02/28/07 - When getting home name, watch out for missing reg
'                           entries
'      jsutton   02/27/07 - Remove logjam on launched process output
'      jsutton   02/23/07 - Alter lockfile() to take message indicating delay
'      jsutton   02/06/07 - XbranchMerge jsutton_bug-5851694 from
'                           st_emll_10.2.5
'      nemalhot  01/29/07 - Bug 5851876: Fix decrSemaphore() method
'      ndutko    01/27/07 - Catch condition of state directory not being
'                           writeable
'      ndutko    01/26/07 - Synchronize on semaphire initialization
'      ndutko    01/26/07 - Synchronize the semaphore access
'      ndutko    01/27/07 - XbranchMerge ndutko_bug-5846940 from st_emll_10.2.5
'      pparida   01/26/07 - Fix bug 5849157: Define variable lockStatus
'      pparida   01/26/07 - XbranchMerge pparida_bug-5849157 from
'                           st_emll_10.2.5
'      jsutton   01/19/07 - Prevent updateComponents from stepping on other
'                           operations
'      nemalhot  01/09/07 - Fix isReadable() method.
'      ndutko    01/04/07 - Use a constant for the JDK version number
'      nemalhot  01/03/07 - Add checkPkgDir() and isReadable() methods.
'      kgupta    12/26/06 - Adding verifyInstall function
'      kgupta    12/15/06 - Adding stdin support in method interactive_runProc
'      nemalhot  12/11/06 - Do case-insensitive comparison of diagnostic
'                           qualifier in isDiagnosticCmd()
'      nemalhot  11/29/06 - Adding getExecCmd()
'      nemalhot  11/28/06 - Adding isDiagnosticCmd()
'      nemalhot  11/28/06 - Adding interactive_runProc()
'      dcawley   11/10/06 - Remove duplicate definition
'      dcawley   11/08/06 - Fix quotes
'      dcawley   11/03/06 - Check for EMSTATE
'      pparida   10/17/06 - Addition of dumpExecInfoErrOnly
'      ndutko    09/18/06 - Addition of utility functions to modify
'                           configuration property files and get the full path
'                           of a temporary filename
'      dcawley   08/02/06 - Changes for Grid Agent Home
'      jsutton   07/05/06 - Handle java version info correctly 
'      ndutko    06/29/06 - Change the minimum version to 1.3 
'      ndutko    06/29/06 - XbranchMerge ndutko_bug-5365379 from 
'                           st_emll_10.2.3 
'      jsutton   06/09/06 - Merge changes from 10.2.3 stream to MAIN 
'      jsutton   05/30/06 - Fix up merge issues 
'      jsutton   05/26/06 - Ensure lockfile is short-named 
'      ndutko    05/25/06 - Addition of lockfile() and releaseLockfile() 
'                           interfaces 
'      ndutko    05/24/06 - Change of service name to 
'                           Oracle<homeName>ConfigurationManager 
'      jsutton   05/24/06 - Move more common code to coreutil 
'      ndutko    05/23/06 - Reuse getEnvironmentalValue() 
'      nemalhot  05/22/06 - Added isUninitialized() function 
'      jsutton   05/23/06 - Deal with shortened paths in GetHomeName 
'      ndutko    05/15/06 - Add function getJavaHome() that returns the java_home 
'                           equivalent or an error code 
'      ndutko    05/15/06 - Create the tempFile in tempDir 
'      ndutko    05/15/06 - Add the UnquoteString function 
'      jsutton   05/12/06 - Alternate approach to getting output from subprocesses 
'      jsutton   05/07/06 - handle spaces in home directory 
'      nemalhot  04/26/06 - Creation
'
Option Explicit

Public isGridAgentHome
Public emState

'Prompt strings used in deriveCCR.vbs to invoke configCCR.
'Note:  If you add a prompt to configCCR then add it to the array below.   If you do not 
'the new prompt will cause deriveCCR's invocation of interactive_runproc cause console
'input to be non-responsive!
Const CSIPrompt = "    Customer Support Identifier (CSI): "
Const MOSUsernamePrompt = "    My Oracle Support User Name: "
Const CountryCodePrompt = "    The two character country code: "
Const EmailAddressUserNamePrompt = "Email address/User Name: "
Const Password = "Password (optional): "
Dim ConfigCCRPromptsArray : ConfigCCRPromptsArray = _
    array(CSIPrompt,MOSUsernamePrompt,CountryCodePrompt,EmailAddressUserNamePrompt,Password)

'Following constants are used in getExecCmd() to identify the command type
Const INTERACTIVE_CMD = 1
Const NON_INTERACTIVE_CMD = 2
Const NON_INTERACTIVE_CMD_ERRONLY = 3

' Return codes
'Const ERR_PREREQ_FAILURE = 1
Const ERR_LOCK_FAILURE = 4
Const ERR_CORRUPT_INSTALL = 5
Const ERR_UNEXPECTED_FAILURE=11

' Constant used elsewhere
Const MIN_JAVA_VERSION = "1.3.0"
Const CCR_PARENT_LEVEL = 1

Public Function checkPrerequisites()
    printDebug "checkPrerequisites"

    WshEnv("CCR_HOME") = CCR_HOME
    If (getJavaHome(JAVA_HOME, True)) Then
      checkPrerequisites = SUCCESS
      WshEnv("JAVA_HOME") = JAVA_HOME
    Else
      checkPrerequisites = ERR_PREREQ_FAILURE
    End If

    printDebug CCR_HOME & ", " & ORACLE_HOME & ", " & JAVA_HOME
End Function

' 
' Returns the path variables for a number of key strings used as
' constants in subsequent operations. Specifically, CCR_HOME,
' CCR_BIN, ORACLE_HOME, and CCR_CONFIG_HOME
'
' The logic contained within derives the path from the full script
' path. This subroutine also assumes that the script being run is in
' a subdirectory of %ORACLE_HOME%/ccr.
'
Public Sub GetPaths(ByRef CCR_HOME, ByRef CCR_BIN, ByRef ORACLE_HOME, _
                    ByRef CCR_CONFIG_HOME)
    printDebug "* coreUtil GetPaths "
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Dim curScript : curScript = WScript.ScriptFullName

    Dim rootDirObj 
    Dim libDirObj 
    
    Set libDirObj = FSO.GetFolder( _
                         FSO.GetParentFolderName( _
                            FSO.GetParentFolderName(curScript)))

    ' Check if this is a Grid Agent Installation

    If (FSO.FileExists(libDirObj & "\lib\emocmutl.vbs")) Then
       isGridAgentHome = 0
       Set rootDirObj = FSO.GetFolder(FSO.GetParentFolderName(libDirObj))              
       ORACLE_HOME = LCase(rootDirObj.ShortPath)
       CCR_HOME = LCase(libDirObj.ShortPath)
    Else
       isGridAgentHome = 1
       ORACLE_HOME = LCase(libDirObj.ShortPath)
       CCR_HOME = ORACLE_HOME
       emState = GetEnvironmentalValue("EMSTATE")
       If (isUninitialized(emState)) Then
          emState = CCR_HOME
       End If
    End If

    CCR_BIN = FSO.BuildPath(CCR_HOME, "bin")

    Call GetCCRConfigHome(CCR_HOME, CCR_CONFIG_HOME)

End Sub

'
' determine value for CCR_CONFIG_HOME
'
Public Sub GetCCRConfigHome(ByVal CCR_HOME, ByRef CCR_CONFIG_HOME)
  Dim CCH : CCH = GetEnvironmentalValue("CCR_CONFIG_HOME")
  '
  ' Use this block only if CCR_CONFIG_HOME was not already set
  '
  If (isUninitialized(CCH)) Then
    If Not SupportsSharedHomes(CCR_HOME) Then
      '
      ' No CCR_HOME/hosts directory, this is an upgrade scenario
      ' CCR_HOME and CCR_CONFIG_HOME are the same
      '
      CCR_CONFIG_HOME = CCR_HOME
    Else
      '
      ' Check for ORACLE_CONFIG_HOME
      '
      Dim OCH : OCH = GetEnvironmentalValue("ORACLE_CONFIG_HOME")
      If (isUninitialized(OCH)) Then
        '
        ' No ORACLE_CONFIG_HOME, use the hosts tree
        '
        CCR_CONFIG_HOME = FSO.BuildPath(FSO.BuildPath(CCR_HOME,"hosts"), getNonDHCPHostname)
      Else
        OCH = UnquoteString(LCase(Replace(OCH,"/","\")))
        If (FSO.FolderExists(OCH)) Then
          ' Remove the trailing slashes as it gives GetAbsolutePathName some issues.
          '
          Do While Right(OCH, 1) = "\"
            OCH = Left(OCH,Len(OCH)-1)
          Loop
          If (LCase(FSO.GetAbsolutePathName(OCH)) = LCase(OCH)) Then
            CCR_CONFIG_HOME = FSO.BuildPath(OCH, "ccr")
          Else
            WScript.Echo("ORACLE_CONFIG_HOME refers to a relative path.")
            WScript.Echo("Redefine ORACLE_CONFIG_HOME to refer to an absolute path, or")
            WScript.Echo("unset it if the configuration state is in the ccr directory tree.")
            WScript.Quit(1)
          End If
        Else
          '
          ' ORACLE_CONFIG_HOME directory does not exist - now what??
          '
          WScript.Echo("ORACLE_CONFIG_HOME refers to a non-existent directory.")
          WScript.Echo("Redefine ORACLE_CONFIG_HOME to refer to the correct location or")
          WScript.Echo("unset it if the configuration state is in the ccr directory tree.")
          WScript.Quit(1)
        End If
      End If
    End If
  Else
    '
    ' Use the value specified in the environment
    '
    CCR_CONFIG_HOME = CCH
  End If
  '
  ' ensure the folder exists
  '
  If (Not FSO.FolderExists(CCR_CONFIG_HOME)) Then
    FSO.CreateFolder(CCR_CONFIG_HOME)
  End If

  ' make sure we shortpath and downcase
  Call ShortenIfNeeded(CCR_CONFIG_HOME)

End Sub

Public Sub ShortenIfNeeded(ByRef dirCheck)
  ' Get shortPath, as needed
  If (InStr(dirCheck," ") > 0) Then
    dirCheck = FSO.GetFolder(dirCheck).ShortPath
  End If
  dirCheck = LCase(dirCheck)
End Sub

Public Sub CreateConfigTree(ByVal CCRConfigHome)
  '
  ' Create the list of subdirectories that may not be present.
  '
  Dim llSubdirs(12),llDir,llDirObj
  llSubDirs(0) = "\config"
  llSubDirs(1) = "\config\default"
  llSubDirs(2) = "\config\diagchecks_exclude"
  llSubDirs(3) = "\config\diagcheck_wallet"
  llSubDirs(4) = "\state"
  llSubDirs(5) = "\state\diagnostic"
  llSubDirs(6) = "\state\previous"
  llSubDirs(7) = "\state\review"
  llSubDirs(8) = "\state\temp"
  llSubDirs(9) = "\state\upload"
  llSubDirs(10) = "\state\upload\external"
  llSubDirs(11) = "\log"

  For Each llDir in llSubdirs
    If Not FSO.FolderExists(CCRConfigHome & llDir) Then
      printDebug "Creating " & CCRConfigHome & llDir
      Set llDirObj = FSO.CreateFolder(CCRConfigHome & llDir)
    End If
  Next
End Sub

'
' Get the *unique* name for the scheduler service based on
' the OracleHomeName for the directory where OCM is installed.
' If the home name is unavailable, convert the path to a unique
' string and use it for the unique part of the service name
'
Public Function getOCMServiceName ()
  printDebug "* coreUtil getOCMServiceName "
  Dim homeName
  homeName = GetHomeName(GetEnvironmentalValue("ORACLE_HOME"))
  If (SupportsSharedHomes(CCR_HOME)) Then
    Dim OCH : OCH = GetEnvironmentalValue("ORACLE_CONFIG_HOME")
    If (not isUninitialized(OCH)) Then
      OCH = UnquoteString(OCH)
      OCH = Replace(OCH,"/","\")
      OCH = Replace(OCH,":","")
      OCH = Replace(OCH,"\","_")
      OCH = Replace(OCH," ","_")
      homeName = homeName & LCase(OCH)
    End If
  End If
  getOCMServiceName = "Oracle" & homeName & "ConfigurationManager"
  printDebug "*  returning " & getocmservicename
End Function

'
'Returns executable command with appropriate STDOUT/STDERR redirection.
'
Function getExecCmd(cmd, params, cmdType, logFname)
  Dim rdrTxt

  Select Case cmdType

    Case INTERACTIVE_CMD
      rdrTxt = " 2>&1"

    Case NON_INTERACTIVE_CMD
      rdrTxt = " > " & logFname & " 2>&1"

    Case NON_INTERACTIVE_CMD_ERRONLY
      rdrTxt = " > NUL 2>" & logFname

  End Select
  Dim comspec : comspec = getComspec
  Dim ExecCommand
  ExecCommand = comspec & " /C " & cmd & " " & params & rdrTxt

  printDebug "Exec: " & ExecCommand
  getExecCmd = ExecCommand  
End Function

'Returns full path to cmd.exe or command.exe
Function getComspec
  Dim tmpComspec
  tmpComspec = UnquoteString(WshEnv("comspec"))
  Dim windir : windir=  UnquoteString(WshEnv("windir"))
  Dim systemroot : systemroot=  UnquoteString(WshEnv("systemroot"))
  If (Not isUninitialized(tmpComspec)) Then
     getComspec=tmpComspec
     Exit Function
  ElseIf(Not isUninitialized(windir)) Then
     printDebug "Looking for cmd in (windir)" & windir
     If (FSO.FileExists(windir & "\system32\cmd.exe")) Then
          getComspec = FSO.GetFile(windir & "\system32\cmd.exe").ShortPath
          Exit Function
     ElseIf (FSO.FileExists(windir & "\system32\command.exe")) Then
          getComspec = FSO.GetFile(windir & "\system32\command.exe").ShortPath
          Exit Function
     End If
  ElseIf(Not isUninitialized(systemroot)) Then
     printDebug "Looking for cmd in (SystemRoot)" & systemroot
     If (FSO.FileExists(systemroot & "\system32\cmd.exe")) Then
          getComspec = FSO.GetFile(systemroot & "\system32\cmd.exe").ShortPath
          Exit Function
     ElseIf (FSO.FileExists(systemroot & "\system32\command.exe")) Then
          getComspec = FSO.GetFile(systemroot & "\system32\command.exe").ShortPath
          Exit Function
     End If
  End If
  WScript.Stderr.WriteLine _
         "Unable to locate system command processor command(cmd.exe)"
  WScript.Quit(1)
End Function

'
' Run a command in a subprocess
'
Function runProc(cmd, params)
  printDebug "* coreUtil runProc "
  runProc = runProc2(cmd, params, False)
End Function

Function runProc2(cmd, params, bErrOnly)
  printDebug "* coreUtil runProc2 "
  oStdOut = ""
  Dim procEC,logFname,logFile,tempFolder,ExecCommand
  '
  ' Create (and close) the temp log file
  '
  Const TemporaryFolder = 2
  Set tempFolder = fso.GetSpecialFolder(TemporaryFolder)
  logFname = FSO.BuildPath(tempFolder.ShortPath, FSO.GetTempName)
  Set logFile = FSO.CreateTextFile(logFname, True)
  logFile.Close  
  
  If (bErrOnly) Then
    ExecCommand = getExecCmd(cmd, params, NON_INTERACTIVE_CMD_ERRONLY, logFname)
  Else
    ExecCommand = getExecCmd(cmd, params, NON_INTERACTIVE_CMD, logFname)
  End If
  Set oExec = WshShell.Exec(ExecCommand)

  Do While oExec.Status = 0
    WScript.Sleep(25)
  Loop

  Set logFile = FSO.OpenTextFile(logFname, ForReading)
  If (Not logFile.AtEndOfStream) Then
    oStdOut = logFile.ReadAll
  End If
  logFile.Close
  Set logFile = FSO.GetFile(logFname)
  logFile.Delete
  
  runProc2 = oExec.ExitCode

End Function

' This method displays STDOUT/STDERR msgs of child process
' interactively on console. This is used for diagnostic cmds.
' You can use the promptsArray parameter to provide input to any prompts
' (actually any output!) from the child process.
Function interactive_runProc(cmd, params, promptsArray)
  printDebug "* coreUtil interactive_runProc "  
  Dim ExecCommand : ExecCommand = getExecCmd(cmd, params,INTERACTIVE_CMD, Null)
  Set oExec = WshShell.exec(ExecCommand)  

  Dim output : output = ""
  Dim str  : str = ""
  oStdOut = ""

  Do While oExec.Status = 0 
      If (Not oExec.StdOut.AtEndOfStream) Then
         If Not IsArray(promptsArray) Then
             output = oExec.StdOut.ReadLine
             WScript.StdOut.writeLine output
             ' saving to oStdOut - this is used in emCCR.deployPackages
             ' when we duplicate the output in upgrade.log
             oStdOut = oStdOut & output & vbCrLf
         Else
             ' Will have to read stdin, read character by character
             output = oExec.StdOut.Read(1)
             WScript.StdOut.write output

             str = str & output
             
             Dim promptMatched : promptMatched = false
             Dim prompt
             For Each prompt In promptsArray
                 If prompt = str then
                     promptMatched = true
                 End If
             Next

             If promptMatched Then
                Dim userIn

                If Not (oExec.Status = 1) Then
                   userIn =  WScript.StdIn.ReadLine
                   oExec.StdIn.WriteLine(userIn)
                End If
                str = ""
             End If

             If Not InStr(str, VbCrLf) = 0 Then
                ' A complete line has been read
                str = ""
             End If

         End If
      End If
  Loop

  If (Not oExec.StdOut.AtEndOfStream) Then
     WScript.StdOut.write oExec.StdOut.ReadAll
  End If
  
  interactive_runProc = oExec.ExitCode

End Function

'----------------
' dump oExec info
'----------------
Sub dumpExecInfo
  printDebug "*********" & vbCrLf & _
             "PID: "      & oExec.ProcessID & vbCrLf & _
             "Status: "   & oExec.Status & vbCrLf & _ 
             "ExitCode: " & oExec.ExitCode & vbCrLf & _
             "StdErr: "   & oStdErr & vbCrLf & _
             "StdOut: "   & oStdOut & vbCrLf & _
             "*********" & vbCrLf
  If (Len(oStdOut) > 0) Then
    WScript.StdOut.Write(oStdOut)
  End If
  If (Len(oStdErr) > 0) Then
    WScript.StdErr.write(oStdErr)
  End If
End Sub

'----------------
' dump oExec info only error
'----------------
Sub dumpExecInfoErrOnly
  printDebug "*********" & vbCrLf & _
             "PID: "      & oExec.ProcessID & vbCrLf & _
             "Status: "   & oExec.Status & vbCrLf & _ 
             "ExitCode: " & oExec.ExitCode & vbCrLf & _
             "StdErr: "   & oStdErr & vbCrLf & _
             "StdOut: "   & oStdOut & vbCrLf & _
             "*********" & vbCrLf
  If (Len(oStdErr) > 0) Then
    WScript.StdErr.write(oStdErr)
  End If
End Sub

Sub printDebug(outTxt)
  Dim nowTime
  nowTime = Time

  Dim CCR_DEBUG_LOG,CCR_DEBUG_FILE,CCR_DEBUG

  CCR_DEBUG_LOG = GetEnvironmentalValue("CCR_DEBUG_LOG")
  If (isUninitialized(CCR_DEBUG_LOG)) Then
    CCR_DEBUG_LOG = ""
  End If

  If (Len(CCR_DEBUG_LOG) > 0) Then
    Set CCR_DEBUG_FILE = FSO.OpenTextFile(CCR_DEBUG_LOG, ForAppending, True)
    CCR_DEBUG_FILE.WriteLine(nowTime & " " & WScript.ScriptName & ": " & outTxt)
    CCR_DEBUG_FILE.Close
  Else
    CCR_DEBUG = GetEnvironmentalValue("CCR_DEBUG")    
    If (Not isUninitialized(CCR_DEBUG)) Then
      WScript.Echo(WScript.ScriptName & ": " & outTxt)
    End If
  End If
End Sub

'
' Given an ORACLE_HOME path, determine the home Name.  If it's been set
' in the registry, we'll use what we get, otherwise we derive the name
' based on the path, substituting "_" for "\" and removing the ":"
'
Function GetHomeName(homePath)
  printDebug "* coreUtil GetHomeName for " & homePath
  '
  ' Set up the default in case we have to bail
  '
  homePath = Replace(homePath,"/","\")
  GetHomeName = Replace(homePath,"\","_")
  GetHomeName = Replace(GetHomeName, ":","")
  GetHomeName = Replace(GetHomeName, " ","_")
  GetHomeName = LCase(GetHomeName)

  Const ForReading = 1
  Set FSO = CreateObject("Scripting.FileSystemObject")

  Dim shortPathName,pathObject
  Dim comspec : comspec = getComspec
  set oExec = wshshell.exec(comspec & " /c ver")
  Do While oExec.Status = 0
    WScript.Sleep(25)
  Loop
  oStdErr = oExec.StdErr.ReadAll
  oStdOut = oExec.StdOut.ReadAll

  Dim procEC : procEC = oExec.ExitCode

  If (Not procEC = 0) Then
    ' Can't figure out OS version, have to bail
    Exit Function
  End If

  If Instr(oStdOut, "Windows NT") = 0 Then
    printDebug "* coreutil gethomename use winmgmts"
    Const HKEY_LOCAL_MACHINE = &H80000002

    Dim ObjReg 

    ' we have seen some issues getting at the registry
    on error resume next
    Set objReg = GetObject("winmgmts:\\.\root\default:StdRegProv")
    on error goto 0

    if (isObject(objreg)) then
      Dim strKeyPath : strKeyPath = "SOFTWARE\ORACLE"
      Dim arrSubKeys, subKey, oHomeKeyPath, nameValue, pathValue
      objReg.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys
      If (IsArray(arrSubKeys)) Then
        For Each subkey In arrSubKeys
          If Left(subkey,4) = "HOME" OR Left(subkey,4) = "KEY_" Then
            ohomeKeyPath = strKeyPath & "\" & subkey
            objReg.GetStringValue HKEY_LOCAL_MACHINE,oHomeKeyPath,"ORACLE_HOME_NAME",nameValue
            objReg.GetStringValue HKEY_LOCAL_MACHINE,oHomeKeyPath,"ORACLE_HOME",pathValue
            If (Not (isUninitialized(pathValue))) And (Not (isUninitialized(nameValue))) Then
              pathValue = replace (pathValue, "/", "\")
              If (FSO.FolderExists(pathValue)) Then
                Set pathObject = FSO.GetFolder(pathValue)
                shortPathName = pathObject.ShortPath
                If Len(nameValue) > 0 AND _
                   (StrComp(LCase(pathValue), LCase(homePath)) = 0 OR _
                    StrComp(LCase(shortPathName), LCase(homePath)) = 0) Then
                  GetHomeName = nameValue
                  printDebug "* coreutil gethomename returning " & gethomename
                  Exit Function
                End If
              End If
            End If
          End If
        Next
      End If
    End If
  Else
    printDebug "* coreutil gethomename use regedit"
    Set oExec = WshShell.Exec("regedit /e .\oHomes.reg ""HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE""")
    Do While oExec.Status = 0
      WScript.Sleep(25)
    Loop
    oStdErr = oExec.StdErr.ReadAll
    oStdOut = oExec.StdOut.ReadAll

    procEC = oExec.ExitCode
    If Not (procEC = 0) Then
      ' Can't read registry info?  Bail!
      Exit Function
    End If

    Dim regFile,regText,regTextArray,regInfo,regParts,inHome,currhomename,currhomepath
    Set regFile = FSO.opentextfile("oHomes.reg", ForReading, False, -2)
    regText = regFile.readAll
    regfile.close
    'Call FSO.deletefile("oHomes.reg")
    regtextarray = split(regtext, vblf, -1)
    inHome = 0
    currhomename = ""
    currhomepath = ""
    For Each reginfo In regtextarray
      If Left(regInfo,1) = "[" Then
        inHome = 0
        If Len(currhomename) > 0 Then
          currhomepath = Replace (currhomepath, "/", "\")
          If (FSO.FolderExists(currhomepath)) Then
            Set pathObject = FSO.GetFolder(currhomepath)
            shortPathName = pathObject.ShortPath
            If (StrComp(LCase(currhomepath), LCase(homePath)) = 0 OR _
                StrComp(LCase(shortPathName), LCase(homePath)) = 0) Then
              GetHomeName = currhomename
              Exit Function
            End If
          End If
          currhomename = ""
          currhomepath = ""
        End If
      End If

      If (InStr(reginfo,"[HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE\HOME") > 0  OR _
          InStr(regInfo,"[HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE\KEY_") > 0) Then
        regParts = Split(reginfo,"\",-1)
        If (UBound(regParts) = 3) Then
          inHome = 1
          currhomename = ""
          currhomepath = ""
        Else
          inHome = 0
          If Len(currhomename) > 0 Then
            currhomepath = replace (currhomepath, "/", "\")
            If (FSO.FolderExists(currhomepath)) Then
              Set pathObject = FSO.GetFolder(currhomepath)
              shortPath = pathObject.ShortPath
              If (StrComp(LCase(currhomepath), LCase(homePath)) = 0 OR _
                  StrComp(LCase(shortPath), LCase(homePath)) = 0) Then
                GetHomeName = currhomename
                Exit Function
              End If
            End If
            currhomename = ""
            currhomepath = ""
          End If
        End If

      Elseif inHome Then
        If InStr(reginfo,"""ORACLE_HOME_NAME""") > 0  Then
          currHomeName = Right(reginfo,Len(reginfo)-InStr(regInfo,"="))
          currHomeName = Mid(currHomeName, 2, InStrRev(currHomeName,"""")-2)
        Elseif InStr(regInfo,"""ORACLE_HOME""") > 0 Then
          currHomePath = Right(reginfo,Len(reginfo)-InStr(regInfo,"="))
          currHomePath = Mid(currHomePath, 2, InStrRev(currHomePath,"""")-2)
          currHomePath = LCase(Replace(currHomePath,"\\","\"))
        End if
      End if
    Next
  End If 

  ' If we get here we have NOT found a home name.  Now try parsing the OUI central inventory file
  printDebug "* coreutil gethomename try XML parse"
  Dim basename, str, xdoc, invFile
  invFile = GetEnvironmentalValue("ProgramFiles")
  invFile = invFile & "\Oracle\Inventory\ContentsXML\inventory.xml"
  If (FSO.fileExists(invFile)) Then
    Dim f : Set f = FSO.GetFile(invFile)
    basename = f.Name
    ' Load XML input file & validate it
    Set xdoc = CreateObject("Msxml2.DOMDocument")
    xdoc.validateOnParse = True
    xdoc.async = False
    xdoc.load(invFile)
    If xdoc.parseError.errorCode = 0 Then
       str = basename & " is valid"
    ElseIf xdoc.parseError.errorCode <> 0 Then
       str = basename & " is not valid" & vbCrLf & _
       xdoc.parseError.reason & " URL: " & Chr(9) & _
       xdoc.parseError.url & vbCrLf & "Code: " & Chr(9) & _
       xdoc.parseError.errorCode & vbCrLf & "Line: " & _
       Chr(9) & xdoc.parseError.line & vbCrLf & _
       "Char: "  & Chr(9) & xdoc.parseError.linepos & vbCrLf & _
       "Text: "  & Chr(9) & xdoc.parseError.srcText
    End If
    printdebug "* coreutil inventory parseStatus = " & str
    xdoc.setProperty "SelectionLanguage", "XPath"
    Dim oNodes : set oNodes = xdoc.selectNodes("//HOME_LIST/*")
    Dim oNode
    Dim oAttr
    Dim homeName, homeLoc
    For Each oNode in oNodes
      If (oNode.nodeName = "HOME") Then
        homeName = ""
        homeLoc = ""
        If oNode.Attributes.length > 0 Then
          For Each oAttr In oNode.Attributes
            If (oAttr.name = "NAME") Then
              homeName = oAttr.Value
            Elseif (oAttr.Name = "LOC") Then
              homeLoc =  oAttr.Value
            End If
          Next
          printdebug "* coreutil homeLoc = " & homeLoc & " homeName = " & homeName
          pathValue = replace (homeLoc, "/", "\")
          If (Len(pathValue) > 0 And FSO.FolderExists(pathValue)) Then
            Set pathObject = FSO.GetFolder(pathValue)
            shortPathName = pathObject.ShortPath
            If Len(homeName) > 0 AND _
               (StrComp(LCase(pathValue), LCase(homePath)) = 0 OR _
                StrComp(LCase(shortPathName), LCase(homePath)) = 0) Then
              GetHomeName = homeName
              printDebug "* coreutil gethomename returning " & gethomename
              Exit Function
            End If
          End If
        End If
      End If
    Next
  End If
End Function

'
' Unquotes leading and trailing quote character
'
Public Function UnquoteString(str)
  printDebug "* coreUtil UnquoteString: " & str
  Dim regEx
  Set regEx = New RegExp            ' Create regular expression.
  If (isUninitialized(str)) Then
    UnquoteString = str
  Else
    regEx.Pattern = "^('|"")(.*)('|"")$"
    regEx.IgnoreCase = True            ' Make case insensitive.
    UnquoteString = regEx.Replace(str, "$2")   ' Make replacement.
  End If
End Function

'
' Returns the javaHome that was determined for the installation. It returns
' the refined javaHome path (removing spaces, making 8.3 fnm conformant). 
' If the javaHome detected is incorrect, a message is written to stdOut
'
'    Format:
'         retCode = getJavaHome( arg, arg )
'
'    arg      -  variable that is passed by reference and returned as
'                a valid String
'    arg      -  verbose, True Or False
' 
' returns:
'
'    True if correctly detected the javaHome value returned in arg
'    False if error encountered
'
Public Function getJavaHome(ByRef String, ByVal bVerbose)
    printDebug "* coreUtil getJavaHome"
    getJavaHome = getNLevelJavaHome(string, CCR_PARENT_LEVEL, bVerbose)
End Function

'
' Given a directory specification, determine if the parent of the directory
' is a valid JDK/JRE. This is used for the purpose of hierarchical traveral
' up a tree. specifically in the case where the grand parent may contain a
' JDK/JRE, such as in the OPatch deployment in a home where the OCM binaries are
' a directly level lower.
Public Function getNLevelJavaHome(ByRef string, ByVal nLevel, ByVal bVerbose)
    printDebug "* coreUtil getNLevelJavaHome with nLevel = " & nLevel
    getNLevelJavaHome = True

    Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
    Dim javaHome

    ' Get the paths that are needed further
    Dim ccr_bin, ccr_home, oracle_home, ccr_config_home
    Call GetPaths(ccr_home, ccr_bin, oracle_home, ccr_config_home)

    ' First get the value of JAVA_HOME_CCR
    ' Internal products like OUI that consume OCM, which
    ' can't set JAVA_HOME, can set JAVA_HOME_CCR
    javaHome = GetEnvironmentalValue("JAVA_HOME_CCR")

    ' If JAVA_HOME_CCR is not defined, get JAVA_HOME from the env
    If (isUninitialized(javaHome)) Then
        javaHome = GetEnvironmentalValue("JAVA_HOME")
    End If

    Const JDK_DIR = "jdk"
    Const JRE_DIR = "jre"
    Const BIN_PATH = "bin"
    Const JAVA_EXE = "java.exe"

    ' If the java home is bad, ignore it.
    If (Not isUninitialized(javaHome)) Then
        Dim javaHomePath
        javaHomePath = FSO.BuildPath(javaHome,BIN_PATH)
        If (FSO.FolderExists(javaHomePath)) Then
            If (FSO.FileExists(FSO.BuildPath(javaHomePath,JAVA_EXE)) <> True) Then
                javaHome = Null
            End If
        Else
            javaHome = Null
        End If
    End If

    If (isUninitialized(javaHome)) Then
        Dim nCurLevel, parentDir, jdkTestPath, jreTestPath , testPath
        Dim javaImage, jdkExists, jreExists, jdkJavaExists, jreJavaExists

        parentDir = oracle_home
        For nCurLevel=1 to nLevel Step 1
            printDebug "* coreUtil getNLevelJavaHome - Interrogating " & parentDir
            jdkTestPath = FSO.BuildPath(parentDir, JDK_DIR)
            jreTestPath = FSO.BuildPath(parentDir, JRE_DIR)

            javaImage = FSO.BuildPath(FSO.BuildPath(jdkTestPath,BIN_PATH),JAVA_EXE)
	    jdkExists = FSO.FolderExists(jdkTestPath)
	    jdkJavaExists = FSO.FileExists(javaImage)

            jreExists = FSO.FolderExists(jreTestPath) 

	    javaImage = FSO.BuildPath(FSO.BuildPath(jreTestPath,BIN_PATH),JAVA_EXE)
            jreJavaExists = FSO.FileExists(javaImage)

	    testPath = ""

            ' validate the resultant JDK/JRE path
            If (jdkExists AND jdkJavaExists) Then
		testPath = jdkTestPath
            ElseIf (jreExists AND jreJavaExists) Then
                testPath = jreTestPath
            ElseIf (jdkExists) Then
                testPath = jdkTestPath
            ElseIf (jreExists) Then
                testPath = jreTestPath
            End If

	    If (NOT isUninitialized(testPath)) Then
               if (validateJdkPath(testPath)) Then
                    javaHome = testPath
                    Exit For
               End If
            End If

            parentDir = FSO.GetParentFolderName(parentDir)
            If (Len(parentDir) = 0) Then
                Exit For
            End If
        Next 

        ' The resultant looping completed, javaHome would be set if a valid
        ' jdk was found. The value is the JAVA_HOME.
        If (isUninitialized(javaHome)) Then
            If (bVerbose = True) Then
    	        WScript.Stderr.WriteLine "The ORACLE_HOME does not contain java."
                WScript.Stderr.WriteLine "The ORACLE_HOME does not contain a valid JDK/JRE."
                WScript.Stderr.WriteLine "Redefine JAVA_HOME to refer to a JDK/JRE "& MIN_JAVA_VERSION & " or greater."
    	    End If
            getNLevelJavaHome = False
        End If
    Else
        ' Validate the user specified JAVA_HOME location
        If (Not validateJdkPath(javaHome)) Then
            If (bVerbose = True) Then
	        WScript.Stderr.WriteLine "JAVA_HOME does not contain a valid JDK/JRE."
                WScript.Stderr.WriteLine "Redefine JAVA_HOME to refer to a JDK/JRE "& MIN_JAVA_VERSION &" or greater."
            End If
            getNLevelJavaHome = False
        End If
    End If

    string = javaHome
End Function

'
' A private function called by getJavaHome() this function performs validation
' of a path to insure the JVM is the right version and that the directory 
' is that of a JDK and not a JRE.
'
'   Parameters:
'         path   - validated path to check, updated with a canonic representation
'
'   Returns:
'         True   - valid JDK path specified
'         False  - Invalid JDK path specified. Error written to stderr.
'
Private Function validateJdkPath(ByRef path)
    printDebug "* coreUtil validateJdkPath: " & path
    Const BIN_PATH = "bin"
    Const JAVA_EXE = "java.exe"

    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")

    ' Determine that the path is valid first
    path = UnquoteString(path)
    If (Not FSO.FolderExists(path)) Then
        WScript.Stderr.WriteLine("The directory " & path & " does not exist.")
        validateJdkPath = False
        Exit Function
    End If

    ' Convert the path to be a short path. Frequently this is needed for
    ' environment persistence or path creation.
    path = FSO.GetFolder(path).ShortPath
    
    Dim javaImage : javaImage = FSO.BuildPath( FSO.BuildPath( path, BIN_PATH ), JAVA_EXE )

    ' Check to make certain the jar and java commands exist. 
    If FSO.FileExists(javaImage) Then
        validateJdkPath = True
    Else
        WScript.Stderr.WriteLine (path & " does not contain java.")
        validateJdkPath = False
        Exit Function
    End If

    ' Now determine the java version.
    Dim ExecCommand : ExecCommand = javaImage & " -version"
    Dim javaVerInfo,javaVerInfoArray,javaTxt,javaVerArray,javaVerStr

    Call runProc(ExecCommand,"")
    javaVerInfo = oStdOut

    javaVerInfoArray = Split(javaVerInfo, vbCr, -1)
    For Each javaTxt In javaVerInfoArray
        If (instr(javaTxt," version ")) Then
            ' The string is like [java version "<version>"], so we split on the quote
            ' and take the second piece (element 1 in the array) for comparison
            javaVerArray = Split(javaTxt, """", -1)
            javaVerStr = javaVerArray(1)
            If (StrComp(javaVerStr,MIN_JAVA_VERSION) < 0) Then
                WScript.Stderr.WriteLine "Java Version " & javaVerStr & " less than minimum required ("& MIN_JAVA_VERSION &")."
                validateJdkPath = False
                Exit Function
            Else
                validateJdkPath = True
                Exit Function
            End If
        End If
    Next

    WScript.Stderr.WriteLine _
       "Java version not able to be identified."
    WScript.Stderr.WriteLine _
       "Set JAVA_HOME to an appropriate version JDK/JRE ("& MIN_JAVA_VERSION &" or later)."
    validateJdkPath = False

End Function

'
' Sets the environment to the set values in the emCCREnv as recorded 
' by emSnapshotEnv
'
Private Sub setEnvVar(ByVal envVar, ByVal envVal)
    WshEnv(envVar) = envVal
End Sub
Public Sub instantiateSavedEnv(ByVal CCR_CONFIG_HOME)
    Call callBackForEachSavedEnv(CCR_CONFIG_HOME, "setEnvVar")
End Sub

'
' Warns of any environment variables that where captured by the emSnapshotEnv but currently
' not defined
'
Private Sub warnEnvVarNotDefined(ByVal envVar, ByVal envVal)
    Dim var : var = GetEnvironmentalValue(envVar)
    If (isUninitialized(var)) Then
        Wscript.StdOut.WriteLine _
            "WARNING:  " & envVar & " is currently not defined but it was originally defined for this OCM installation."
    End If
End Sub
Public Function warnOfSavedEnvNotDefined(ByVal CCR_CONFIG_HOME)
    Call callBackForEachSavedEnv(CCR_CONFIG_HOME, "warnEnvVarNotDefined")
End Function
'
' Sets the environment to the set values in the emCCREnv as recorded 
' by emSnapshotEnv
'
Private Sub callBackForEachSavedEnv(ByVal CCR_CONFIG_HOME, ByVal callBackName)
    printDebug "* callBackForEachSavedEnv"
    Dim callBack : Set callBack = GetRef(callBackName)
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Dim envFileNM : envFileNM = FSO.BuildPath( _
                                FSO.BuildPath(CCR_CONFIG_HOME, "config"), "emCCREnv")
    If FSO.FileExists(envFileNM) Then
        Dim envFile,envInfo,envVar,envVal
        Set envFile = FSO.OpenTextFile(envFileNM, ForReading)
        Do While Not envFile.AtEndOfStream
            envInfo = envFile.ReadLine
            If Instr(envInfo,"=") Then
                envVar = Left(envInfo,InStr(envInfo,"=")-1)
                envVal = Right(envInfo,Len(envInfo) - InStr(envInfo,"="))
                Call callBack(envVar, envVal)
            End If
        Loop
    End If
End Sub

'
' Gets the given environment variable from the emCCREnv if found.
'
Public Function getSavedEnv(ByVal CCR_CONFIG_HOME, ByVal requestedEnvVar)
    printDebug "* coreUtil getSavedEnv"
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Dim envFileNM : envFileNM = FSO.BuildPath( _
                                FSO.BuildPath(CCR_CONFIG_HOME, "config"), "emCCREnv")
    If FSO.FileExists(envFileNM) Then
        Dim envFile,envInfo,envVar,envVal
        Set envFile = FSO.OpenTextFile(envFileNM, ForReading)
        Do While Not envFile.AtEndOfStream
            envInfo = envFile.ReadLine
            If Instr(envInfo,"=") Then
		envVar = Left(envInfo,InStr(envInfo,"=")-1)
		If (envVar = requestedEnvVar) Then
                    getSavedEnv = Right(envInfo,Len(envInfo) - InStr(envInfo,"="))
		    Exit Function
                End if
            End If
        Loop
    End If
    getSavedEnv = ""
End Function

'
' Function to return the environmental value for a specified string. This
' function traverses the process environmental table first and then the system
' environmental table.
'
Public Function GetEnvironmentalValue(ByVal envString)

    Dim WshShell : Set WshShell = WScript.CreateObject("WScript.Shell")
    Dim processEnv : Set processEnv = WshShell.Environment("PROCESS")
    Dim systemEnv : Set systemEnv = WshShell.Environment("SYSTEM")

    If (isUninitialized(envString)) Then
        WScript.Stderr.WriteLine _
            "Internal exception - call to GetEnvironmentalValue with no string specified!"
        WScript.Quit(1)
    End If

    ' Get the result from the process table
    GetEnvironmentalValue = processEnv(envString)

    If (isUninitialized(GetEnvironmentalValue)) Then
        GetEnvironmentalValue = systemEnv(envString)
    End If
End Function

'Check whether var is initialized or not
Public Function isUninitialized(ByVal var)
    If (IsEmpty(var) Or IsNull(var) Or Len(var)=0) then
        isUninitialized = True
    Else
        isUninitialized = False
    End If
End Function

'
' lockfile is meant to mimic the capabilities of the lockfile directive
' native to the Linux operating system. The lockfile function accepts the
' time to sleep between attempts to open the designated file for write
' access. It also will attempt this a number of times, before returning
' to the caller.
'
'    Arguments
'
'        objFile    - Reference to a object to return the TextStream when
'                     the file is successfully openned
'        sleepTime  - Integer value of seconds to sleep between attempts
'                     to open the file
'        retries    - Number of times to re-attempt the open attempt
'        filename   - String representation of the file to open
'        waitMsg    - String to be output when we must wait
'
'    Returns
'        True       - The filename specified was openned. objFile contains
'                     the reference to the TextStream that will remain open
'        False      - Failure to open the filename specified after a number
'                     of attempts
'
Public Function lockfile(ByRef objFile, ByVal sleepTime, ByVal retries, ByVal filename, ByVal waitMsg)

    printDebug "* coreUtil lockfile: " & filename

    Const ForWriting = 2

    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Dim attemptCounter : attemptCounter = 0
    Dim sleepMs : sleepMs = sleepTime * 1000

    lockfile = False
    On Error Resume Next
    Do
        attemptCounter = attemptCounter + 1

        printDebug "Attempting to open file: " & filename & ", attempt " & attemptCounter

        ' Localize the error handling to the one function
        Err.Clear
        Set objFile = FSO.OpenTextFile(filename, ForWriting, True)

        If (Err.Number <> 0) Then
            printDebug ", OpenFile failed, (ErrCode:" & Err.Number & ", " _
                        & Err.Description & "), Sleeping..." & vbCrLf
            If (attemptCounter = 1 And Len(waitMsg) > 0) Then
                Wscript.StdOut.WriteLine waitMsg
            End If
            WScript.Sleep sleepTime*1000
        Else
            printDebug vbCrLf
            lockfile = True
        End If

    Loop While (Not lockfile And attemptCounter < retries)
    On Error Goto 0

End Function

'
' Releases the objects used by the lockfile function
'
'    Arguments
'        objFile     -    reference to the TextStream that was openned
'        filename -    name of the file that was created
'
' Side effect - open return, the filename specified is deleted/
'
Public Sub releaseLockfile(ByRef objFile, ByRef filename)

    ' Turn off all the safeties...
    On Error Resume Next

    ' Try to close the file
    objFile.Close
    Set objFile = Nothing

    ' Delete the file
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Call FSO.DeleteFile(filename, True)

    ' Time to put the Safety back on
    On Error Goto 0
End Sub

' Determines wheter two directory specifications are identical. Returns
' True if a match.
Function compareDirSpec(ByVal srcDir, ByVal destDir)

    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Dim srcObject : Set srcObject = FSO.GetFolder(srcDir)
    Dim destObject : Set destObject = FSO.GetFolder(destDir)

    If (LCase(srcObject.ShortPath) = LCase(destObject.ShortPath)) Then
        compareDirSpec = True
    Else
        compareDirSpec = False
    End If

End Function

' getPropertyValues returns to the caller a dictionary object instance 
' that contains the names and corresponding values requested in the 
' dictProps object.
'
' Arguments:
'     strFilespec - String full file specification of the config file
'                   to collect configuration information out of.
'     dictProps   - An instance of a Scripting.Dictionary object. The
'                   value of the property is not consumed.
'
' Returns:
'     a instance of a Scripting.Dictionary object that contains the value
'     for all properties that were found. If a property was not found in 
'     the user supplied property file, no entry is in the resultant 
'     Dictionary object
'
Public Function getPropertyValues(ByVal strFilespec, ByVal dictProps)

    Const ForReading = 1
    Dim dictResult : Set dictResult = CreateObject("Scripting.Dictionary")

    ' open the input file if it exists
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    If FSO.FileExists(strFilespec) <> True Then
        Exit Function
    End If

    Dim propertyLine
    Dim regExpression : Set regExpression = New RegExp
    Dim textStream : Set textStream = FSO.OpenTextFile(strFilespec, ForReading)

    ' Set the pattern to ignore lines that are comments and do not contain
    ' an =
    regExpression.Pattern = "^([\w\.]+)=(.*?)\s*$"
    regExpression.Global = False
    regExpression.IgnoreCase = False

    ' Loop thru the records, looking for lines that contain the properties
    Do While textStream.AtEndOfStream <> True
        propertyLine = textStream.ReadLine

        ' Look for a pattern that matches and extract the property name
        If regExpression.Test(propertyLine) Then
            Dim Matches : Set Matches = regExpression.Execute(propertyLine)
            Dim propertyName : propertyName = Matches(0).SubMatches(0)
            Dim propertyValue : propertyValue = Matches(0).SubMatches(1)

            ' Check to see if the property encountered was requested for. If
            ' it was, then store it in the result set.
            If dictProps.Exists(propertyName) Then
                Call dictResult.Add(propertyName, propertyValue)
            End If            
        End If
    Loop

    textStream.Close
        
    Set getPropertyValues = dictResult

End Function

' Extracts and returns the Value for the property specified from the base
' configuration file and returns if that configuration file present or not. 
' The algorithm iterates thru all the files in precidence order, taking the
' first one present. Order is:
'
'   (1) $CCR_CONFIG_HOME/config
'   (2) $CCR_CONFIG_HOME/config/default
'   (3) $CCR_HOME/config
'   (4) $CCR_HOME/config/default
'
' Arguments:
'     propertyName  - String specification of property name
'     propFileName  - property file name in which propertyName can be found
'     PropFIleFound - (By Ref)Gives True/False based on property file found or not
'
' Returns:
'     String that contains the property value

public Function getPropertyString(ByVal propertyName, ByVal propFileName, ByRef PropFileFound)

  Dim dictProps : Set dictProps = CreateObject("Scripting.Dictionary")
  Dim dictResults,autoUpdate
  Dim propertyValue 
  propertyValue = ""
  propFileFound = False
  Call dictProps.Add(propertyName,"")
  Dim propFiles(4),propFile
  propFiles(0) = CCR_CONFIG_HOME & "\config\" & propFileName
  propFiles(1) = CCR_CONFIG_HOME & "\config\default\" & propFileName
  propFiles(2) = CCR_HOME & "\config\" & propFileName
  propFiles(3) = CCR_HOME & "\config\default\" & propFileName

  For Each propFile in propFiles
    If FSO.FileExists(propFile) Then
      propFileFound = True
      Set dictResults = getPropertyValues(propFile, dictProps)
      propertyValue = dictResults.Item(propertyName)
      If (Not IsUninitialized(propertyValue)) Then
        Exit For
      End If
    End If
  Next
  getPropertyString = propertyValue

End Function

' replaces properties found in the file with values specified as an argument.
' If the property is not present in the configuration file, the property is
' added at the end.
'
' Arguments:
'     strFilespec - string file specification of the file to update
'     dictProps   - Scripting.Dictionary object that contains the values to 
'                   replace.
'
' Notes:
'     Uses the private function modifyProperties that allows for the 
'     caller to indicate how the dictProps are to be interpretted.
'
Public Sub replaceProperties(ByVal strFilespec, ByVal dictProps)

    Call modifyProperties_(strFilespec, dictProps, False)

End Sub

'
' removeProperties removes the properties from the specified configuration 
' file if they are present.
'
' Arguments:
'     strFilespec - string file specification of the file to update
'     dictProps   - Scripting.Dictionary object that contains the values to 
'                   remove.
'
' Notes:
'     Uses the private function modifyProperties that allows for the 
'     caller to indicate how the dictProps are to be interpretted.
'
Public Sub removeProperties(ByVal strFilespec, ByVal dictProps)

    Call modifyProperties_(strFilespec, dictProps, True)

End Sub

' Modifies properties found in the file with values specified as an argument.
' If the property is not present in the configuration file, the property is
' added at the end if bModify is set to True - otherwise, this private 
' function is used to remove the properties specified.
'
' Arguments:
'     strFilespec - string file specification of the file to update
'     dictProps   - Scripting.Dictionary object that contains the values to 
'                   replace.
'     bRemove     - indicates the operation is a removal of specified values
'                   and not a strict modification.
'
' Notes:
'     The implementation of this method creates a duplicate file in the System
'     Temporary folder with a Temporary name. Once the source file is processed
'     the temporary file replaces the original.
'
'     This private subroutine is consumed by the replaceProperties and 
'     deleteProperties subroutined.
'
Private Sub modifyProperties_(ByVal strFilespec, ByVal dictProps, ByRef bRemove)

    Const ForReading = 1

    ' open the input file creating it if it doesn't exist
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")

    Dim propertyLine
    Dim regExpression : Set regExpression = New RegExp

    ' Check to see if the property file is there. If it is not, append or return
    If (Not FSO.FileExists(strFilespec)) Then
        If (bRemove) Then
            Exit Sub
        Else
            Call appendProperties_(strFilespec, dictProps)
        End If
    End If

    Dim textInStream
    Set textInStream = FSO.OpenTextFile(strFilespec, ForReading)

    Dim tempFNM : tempFNM = GetTempFilename()
    Dim textOutStream : Set textOutStream = FSO.CreateTextFile( tempFNM )
    Dim bPropertyMatched

    ' Set the pattern to ignore lines that are comments and do not contain
    ' an =
    regExpression.Pattern = "^([\w\.]+)=(.*?)\s*$"
    regExpression.Global = False
    regExpression.IgnoreCase = False

    ' Loop thru the records, looking for lines that contain the properties
    Do While textInStream.AtEndOfStream <> True
        propertyLine = textInStream.ReadLine

        bPropertyMatched = regExpression.Test(propertyLine)

        ' Look for a pattern that matches and extract the property name
        If bPropertyMatched Then
            Dim Matches : Set Matches = regExpression.Execute(propertyLine)
            Dim propertyName : propertyName = Matches(0).SubMatches(0)
            Dim propertyValue : propertyValue = Matches(0).SubMatches(1)
            
            ' Determine if the property uncovered is to be replaced by looking
            ' in the user supplied dictionary instance.
            If dictProps.Exists( propertyName ) Then
                propertyValue = dictProps.Item( propertyName )

                ' Now remove the entry from the dictionary indicating the 
                ' entry was processed.
                dictProps.Remove( propertyName )
            Else
                bPropertyMatched = False
            End If

            ' reconstruct the new propertyLine
            propertyLine = propertyName & "=" & propertyValue
        End If

        If bPropertyMatched <> True or bRemove <> True Then
            textOutStream.WriteLine propertyLine
        End If
    Loop

    ' If this is the non-removal path, add the remaining properties to the 
    ' configuration file.
    If bRemove <> True Then
        Dim keyIdx
        Dim Key : Key = dictProps.Keys()
        For keyIdx=LBound(Key) to UBound(Key)
            textOutStream.WriteLine Key(keyIdx) & "=" & dictProps(Key(keyIdx))
        Next
    End If

    textInStream.Close
    textOutStream.Close

    ' Move the temporary file to overwrite the source.
    If FSO.FileExists(strFilespec) Then
        FSO.DeleteFile(strFilespec)
    End If
    Call FSO.MoveFile(tempFNM, strFilespec)
        
End Sub

' Creates a property file with the properties specified in the argument
'
' Arguments:
'     strFilespec - string file specification of the file to update
'     dictProps   - Scripting.Dictionary object that contains the values to 
'                   add.
'
Private Sub appendProperties_(ByVal strFilespec, ByVal dictProps)

    Const ForReading = 1

    ' open the input file creating it if it doesn't exist
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    Dim textOutStream : Set textOutStream = FSO.CreateTextFile( strFilespec )

    Dim keyIdx
    Dim Key : Key = dictProps.Keys()
    For keyIdx=LBound(Key) to UBound(Key)
        textOutStream.WriteLine Key(keyIdx) & "=" & dictProps(Key(keyIdx))
    Next

    textOutStream.Close
        
End Sub

' getTempFilename() returns a filename that can be created in the system folder
' 
Public Function getTempFilename()
    Const TemporaryFolder = 2

    Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
    Dim tmpDir : Set tmpDir = FSO.GetSpecialFolder( TemporaryFolder )
    getTempFilename = FSO.BuildPath(tmpDir.ShortPath, FSO.GetTempName)

End Function

' Check if its a diagnostic cmd
Public Function isDiagnosticCmd(argInfo)
    
    Dim RegularExpressionObject

    Set RegularExpressionObject = New RegExp

    With RegularExpressionObject
    .Pattern = """-diagnostic[=$]?"
    .IgnoreCase = True
    .Global = False
    End With

    isDiagnosticCmd = RegularExpressionObject.Test(LCase(argInfo))

End Function

' Check if -nointeractive qualifier is given
Public Function isInteractiveCmd(argInfo)
    
    Dim RegularExpressionObject

    Set RegularExpressionObject = New RegExp

    With RegularExpressionObject
    .Pattern = """-nointeractive"""
    .IgnoreCase = True
    .Global = False
    End With

    If (RegularExpressionObject.Test(LCase(argInfo))) Then
        isInteractiveCmd = False
    Else
        isInteractiveCmd = True
    End If

End Function


' Check if its a diagnostic upload cmd
Public Function isInteractiveUploadCmd(argInfo)

    printDebug "Checking whether its a interactive upload cmd: " & argInfo
    If (isDiagnosticCmd(argInfo)) Then
        Dim RegularExpressionObject
        Set RegularExpressionObject = New RegExp

        printDebug "Identified diagnostic command."

        ' Check whether -restart qualifier is present
        With RegularExpressionObject
        .Pattern = """-restart"""
        .IgnoreCase = True
        .Global = False
        End With
        If (RegularExpressionObject.Test(LCase(argInfo))) Then
          'Its a restart cmd
          isInteractiveUploadCmd = False
          Exit Function
        End If

        printDebug "Given diagnostic command is not a restart cmd."

        ' Check whether its a upload cmd
        With RegularExpressionObject
        .Pattern = """upload"""
        .IgnoreCase = True
        .Global = False
        End With

        If (Not RegularExpressionObject.Test(LCase(argInfo))) Then
          isInteractiveUploadCmd = False
          Exit Function
        End If

        printDebug "Given diagnostic command is a upload cmd."

        ' Check whether its a interactive cmd
        If (isInteractiveCmd(argInfo)) Then
          printDebug "Given diagnostic command is a interactive upload cmd."
          isInteractiveUploadCmd = True
          Exit Function
        Else
          isInteractiveUploadCmd = False
          Exit Function
        End If

    Else
        isInteractiveUploadCmd = False
        Exit Function
    End If 

End Function

' Verifies the ocm install returns ERR_CORRUPT_INSTALL if its corrupt
Public Function verifyInstall(ByVal CCR_CONFIG_HOME)
    verifyInstall = 0

    ' Verify we have CSI, metalink-id and country code in ccr.properties file
    If (Not FSO.FileExists(CCR_CONFIG_HOME & "\config\ccr.properties") And _
        Not FSO.FileExists(CCR_CONFIG_HOME & "\config\default\ccr.properties") And _
        Not FSO.FileExists(CCR_HOME & "\config\ccr.properties") And _
        Not FSO.FileExists(CCR_HOME & "\config\default\ccr.properties") ) Then
      WScript.Echo("The current configuration information appears to be corrupted. Please run configCCR to reconfigure.")
      verifyInstall=ERR_CORRUPT_INSTALL
    Else
      printDebug "Checking ccr.properties"
      Dim supportId,metalinkId,countryCode,propFileName,registration_method,cipherText
      Dim metalink_email_addr

      propFileName = CCR_CONFIG_HOME & "\config\ccr.properties"
      Call GetRegistrationProperties(propFileName, supportId, metalinkID, _
                registration_method, metalink_email_addr, cipherText)
      '
      ' If any items left uninitialized, check alternate properties files
      '
      propFileName = CCR_CONFIG_HOME & "\config\default\ccr.properties"
      Call GetRegistrationProperties(propFileName, supportId, metalinkID, _
                registration_method, metalink_email_addr, cipherText)

      propFileName = CCR_HOME & "\config\ccr.properties"
      Call GetRegistrationProperties(propFileName, supportId, metalinkID, _
                registration_method, metalink_email_addr, cipherText)

      propFileName = CCR_HOME & "\config\default\ccr.properties"
      Call GetRegistrationProperties(propFileName, supportId, metalinkID, _
                registration_method, metalink_email_addr, cipherText)
      If (isUninitialized(registration_method)) Then
          printDebug "* coreutil registration_method is not defined"
          If (isUninitialized(supportId) Or _
              isUninitialized(metalinkId)) Then
            printDebug "* coreutil supportId|metalinkId are not defined"
            WScript.Echo("The current configuration information appears to be corrupted. Please run configCCR to reconfigure.")
            verifyInstall=ERR_CORRUPT_INSTALL
          End If
      ElseIf (Lcase(registration_method) = "csi") Then
          printDebug "* coreutil registration_method = CSI"
          If (isUninitialized(supportId) Or _
              isUninitialized(cipherText)) Then 
            printDebug "* coreutil supportId|cipherText are not defined"
            WScript.Echo("The current configuration information appears to be corrupted. Please run configCCR to reconfigure.")
            verifyInstall=ERR_CORRUPT_INSTALL
          End If
      ElseIf (Lcase(registration_method) = "email") Then
          printDebug "* coreutil registration_method = email"
          If (isUninitialized(metalink_email_addr) Or _
              isUninitialized(cipherText)) Then
            printDebug "* coreutil metalink_email_addr | cipherText are not defined."
            WScript.Echo("The current configuration information appears to be corrupted. Please run configCCR to reconfigure.")
            verifyInstall=ERR_CORRUPT_INSTALL
          End If
      ElseIf (Lcase(registration_method) = "anon") Then
          printDebug "* coreutil registration_method = anon"
      End If
    End If
End Function

'
' Read registration properties (CSL, MLID) from specified file
'
Public Sub GetRegistrationProperties(ByVal propFileName, ByRef supportID, _
                                     ByRef metalinkID, ByRef registration_method, _
                                     ByRef metalink_email_addr, ByRef cipherText)
  If (isUninitialized(supportID) or _
      isUninitialized(metalinkId)) Then
    If (FSO.FileExists(propFileName)) Then
      Dim dictProps, dictResults
      Set dictProps = CreateObject("Scripting.Dictionary")
      Call dictProps.Add("ccr.registration_mode","")
      Call dictProps.Add("ccr.metalink_email.address", "")
      Call dictProps.Add("ccr.registration_ct", "")
      Call dictProps.Add("ccr.support_id","")
      Call dictProps.Add("ccr.metalink_id","")
      Set dictResults = getPropertyValues(propFileName, dictProps)
      If (isUninitialized(supportID) And dictResults.exists("ccr.support_id")) Then 
          supportID = dictResults.Item("ccr.support_id")
      End If
      If (isUninitialized(metalinkID) And dictResults.Exists("ccr.metalink_id")) Then
          metalinkID = dictResults.Item("ccr.metalink_id")
      End If
      If (isUninitialized(registration_method) And dictResults.Exists("ccr.registration_mode")) Then
          registration_method = dictResults.Item("ccr.registration_mode")
      End If
      If (isUninitialized(metalink_email_addr) And dictResults.Exists("ccr.metalink_email.address")) Then
          metalink_email_addr = dictResults.Item("ccr.metalink_email.address")
      End If
      If (isUninitialized(cipherText) And dictResults.Exists("ccr.registration_ct")) Then
          cipherText = dictResults.Item("ccr.registration_ct")
      End If
    End If
  End If
End Sub

' Check if package exists in $CCR_HOME\inventory. Return True if yes
' otherwise false
' Params:
'   arg - package/folder to be compared
Function checkPkgDir(ByVal arg)

  Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
  Dim target, matched
  target = FSO.BuildPath(CCR_HOME, "inventory")
  matched = False
  
  'Get Absoulte path
  arg = FSO.GetAbsolutePathName(arg)

  If (Not FSO.FolderExists(arg)) Then
    arg=FSO.GetParentFolderName(arg)
  End If
  
  Do While ((Len(arg) > 0) AND (NOT matched))  
    matched = CompareDirSpec(arg,target)
    arg = FSO.GetParentFolderName(arg)
  Loop

  checkPkgDir = matched

End Function

' Tests whether the given file/folder has read permissions.
Function isReadable(arg)
  isReadable = true
  on error resume next

  If (FSO.folderExists(arg)) Then
    Dim folder, files
    Set folder = FSO.GetFolder(arg)
    Set files = folder.files
    For each file in Files
      Exit For
    Next
    If (err) Then
      isReadable = false
    End If
  Else
    Dim file, fileHandle
    set file = FSO.GetFile(arg)
    set fileHandle = file.OpenAsTextStream(ForReading, -2)
    If (err) Then
      isReadable = false
    Else
      fileHandle.Close
    End If
  End If
  On Error Goto 0
End Function 

'
' semaphore operations (maintain count of semaphore usage)
'
Dim semaphoreLock,objSemaphoreLock,semaphoreOp,semaphoreUpdate
Dim g_semHandle,g_semBase

Sub initSemaphores
  Const FOLDER_READ_ONLY = 1
  Dim objStateDir : Set objStateDir = FSO.GetFolder(CCR_HOME & "\state" )
  If (objStateDir.attributes and FOLDER_READ_ONLY) Then
    Set objStateDir = FSO.GetFolder(CCR_CONFIG_HOME & "\state" )
    If (objStateDir.attributes and FOLDER_READ_ONLY) Then
      ' Call Banner()
      WScript.Echo "Unable to satisfy request - initialization failure."
      WScript.Echo CCR_CONFIG_HOME & "\state is not writeable."
      Quit(ERR_UNEXPECTED_FAILURE)
    End If
    g_semBase = CCR_CONFIG_HOME
  Else
    g_semBase = CCR_HOME
  End If
    semaphoreLock = g_semBase & "\state\semaphore.lock"
    semaphoreOp = g_semBase & "\state\semaphore.op"
    semaphoreUpdate = g_semBase & "\state\semaphore.update"
End Sub

Public Function incrSemaphore(ByVal inFile)
  Const ForWriting = 2
  Dim fList,fInst,fName
  Dim confPref,confExists,lockStatus
  ' the conflict prefix is the one we're *not* working with
  If (inFile = semaphoreOp) Then
    confPref = "semaphore.update"
  Else
    confPref = "semaphore.op"
  End If
  ' assume no conflict
  confExists = False
  lockStatus = lockfile( objSemaphoreLock, 2, 30, semaphoreLock, "" )
  If (lockStatus) Then
    ' look thru all files in the state directory
    Set fList = FSO.GetFolder(FSO.BuildPath(g_semBase,"state")).Files
    For Each fInst in fList
      ' look for a file whose name starts with the conflict prefix
      If (LCase(Left(fInst.Name,Len(confPref))) = LCase(confPref)) Then
        ' we found one; a conflict exists - we can bail out of the loop
        confExists = True
        Exit For
      End If
    Next
    Call releaseLockfile(objSemaphoreLock, semaphoreLock)
  Else
    WScript.Echo "Unable to acquire semaphore lock to synchronize operation, aborting."
    Quit(ERR_LOCK_FAILURE)
  End If

  If (confExists) Then
    WScript.Echo "Operation blocked, waiting..."
    ' we will wait up to 120 seconds
    Dim willWait : willWait = 120
    Do While ((willWait > 0) And (confExists))
      WScript.Sleep(1000)
      willWait = willWait - 1
      ' Synchronize on the semaphore lock
      lockStatus = lockfile( objSemaphoreLock, 2, 30, semaphoreLock, "" )
      if (lockStatus) Then
        ' look thru all files in the state directory
        Set fList = FSO.GetFolder(FSO.BuildPath(g_semBase,"state")).Files
        confExists = False
        For Each fInst in fList
          If (LCase(Left(fInst.Name,Len(confPref))) = LCase(confPref)) Then
            ' we have a file whose name matches the conflict prefix - try to delete the file
            On Error Resume Next
            FSO.DeleteFile(fInst)
            If (Err.Number <> 0) Then
              ' Unable to remove file, set conflict flag 
              confExists = True
              ' bail out of for loop (back to the do loop)
              Exit For
            End If
            On Error Goto 0
          End If
        Next
        Call releaseLockfile(objSemaphoreLock, semaphoreLock)
      Else
        WScript.Echo "Unable to acquire semaphore lock to synchronize operation, aborting."
        Quit(ERR_LOCK_FAILURE)
      End If
    Loop
    If (confExists) Then
      ' conflict flag still set - deletion(s) failed and we timed out
      WScript.Echo "Operation still blocked; aborting!"
      Quit(ERR_UNEXPECTED_FAILURE)
    End If
  End If 
  lockStatus = lockfile( objSemaphoreLock, 5, 60, semaphoreLock, "" )
  If (lockStatus) Then
    fName = inFile & "." & FSO.GetTempName
    ' open a new file; this becomes the semaphore for our operation
    Set g_semHandle = FSO.OpenTextFile(fName, ForWriting, True)
    ' return value is the name of the newly created file
    incrSemaphore = fName
    Call releaseLockfile(objSemaphoreLock, semaphoreLock)
  Else
    WScript.Echo "Unable to synchronize operation, aborting."
    Quit(ERR_LOCK_FAILURE)
  End If
End Function

Sub decrSemaphore(ByVal inFile)
  Const ForWriting = 2
  Dim lockStatus
  ' input is the file name; make sure it's set to something and the file exists
  If (Not isUninitialized(inFile)) And FSO.FileExists(inFile) Then
    lockStatus = lockfile( objSemaphoreLock, 5, 60, semaphoreLock, "" )
    If (lockStatus) Then
      On Error Resume Next
      g_semHandle.Close      
      Call FSO.DeleteFile(inFile, True)
      On Error Goto 0 
      Call releaseLockfile(objSemaphoreLock, semaphoreLock)
    End If
  End If
End Sub

'
' Get the "logical" host name, in case we're using DHCP
'
Function getNonDHCPHostname
  Dim WshNetwork : Set WshNetwork = WScript.CreateObject("WScript.Network")
  getNonDHCPHostName = LCase(WshNetwork.ComputerName)
  Dim ipConfig,ipInfo,ipText,ipDomain,hostName

  Call runProc("ipconfig", "/all")
  ipConfig = oStdOut

  ipInfo = Split(ipConfig,vbCr,-1)
  For Each ipText In ipInfo
    If (Instr(LCase(ipText),"primary dns suffix")) Then
      ipDomain = Trim(Right(ipText,Len(ipText)-InStr(ipText,":")))
      If (Len(Trim(ipDomain)) > 0) Then
         getNonDHCPHostName = getNonDHCPHostName & "." & ipDomain
         Exit Function
      End If
    End If

    If (Instr(LCase(ipText),"host name")) Then
      hostName = Trim(Right(ipText,Len(ipText)-InStr(ipText,":")))
      If (Instr(hostName, ".") > 0) Then
         getNonDHCPHostName = hostName
         Exit Function
      End If
    End If
  Next

End Function

Function IsConfigHomeSetup()
  IsConfigHomeSetup = False
  If (FSO.FolderExists(CCR_CONFIG_HOME & "\config") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\config\default") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\log") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\state") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\state\diagnostic") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\state\previous") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\state\review") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\state\temp") And _
      FSO.FolderExists(CCR_CONFIG_HOME & "\state\upload")) Then
      IsConfigHomeSetup = True
    End If
End Function

'
' Checks the conditions which must be met to indicate OCM has been
' configured for the current CCR_CONFIG_HOME
'
Function IsOCMConfigured(ByVal bVerbose)
  Dim licenseAccepted,configFile,acceptee
  Dim dictProps, dictResults

  IsOCMConfigured = False
  '
  ' The config tree must exist
  '
  If Not (IsConfigHomeSetup()) Then
    If (bVerbose = True) Then
        WScript.Echo "The Oracle Configuration Manager state/writeable directory structure is incomplete."
    End If
    Exit Function
  End If

  '
  ' And the agreement must have been signed
  '
  configFile = FSO.BuildPath( _
                 FSO.BuildPath(CCR_CONFIG_HOME, "config"), "collector.properties")
  If FSO.FileExists(configFile) Then

    printDebug "* coreUtil IsOCMConfigured probing "&configFile
    Set dictProps = CreateObject("Scripting.Dictionary")
    Call dictProps.Add("ccr.agreement_signer","")
    Set dictResults = getPropertyValues(configFile, dictProps)
    acceptee = dictResults.Item("ccr.agreement_signer")
    printDebug "* coreUtil IsOCMConfigured accepteee = "& acceptee

    If (Not isUninitialized(acceptee)) Then
      IsOCMConfigured = True
    ElseIf (bVerbose = True) Then
      WScript.Echo "The Oracle Configuration Manager license agreement has not been accepted."
    End If
  End If
End Function

'
' Check for the ccr.disconnected property in collector.properties files
'
Function IsDisconnected
  Dim dictProps : Set dictProps = CreateObject("Scripting.Dictionary")
  Dim dictResults,dictValue
  Call dictProps.Add("ccr.disconnected","")
  Dim propFiles(4),propFile
  propFiles(0) = CCR_CONFIG_HOME & "\config\collector.properties"
  propFiles(1) = CCR_CONFIG_HOME & "\config\default\collector.properties"
  propFiles(2) = CCR_HOME & "\config\collector.properties"
  propFiles(3) = CCR_HOME & "\config\default\collector.properties"

  For Each propFile in propFiles
    If FSO.FileExists(propFile) Then
      Set dictResults = getPropertyValues(propFile, dictProps)
      dictValue = dictResults.Item("ccr.disconnected")
      If (Not IsUninitialized(dictValue)) Then
        Exit For
      End If
    End If
  Next

  If (Not IsUninitialized(dictValue) And dictValue = "true") Then
    IsDisconnected = True
  Else
    IsDisconnected = False
  End If
End Function

' 
' Returns whether the specified CCR_HOME supports a shared home environment. 
' Pre 10.2.7 collectors did not have a hosts directory, which was put in place 
' for shared home support.
'
Function SupportsSharedHomes(ByVal ccrhome)
    Dim hostsPath : hostsPath = FSO.BuildPath(ccrhome, "hosts")
    If Not FSO.FolderExists(hostsPath) Then
        SupportsSharedHomes = False
    Else
        SupportsSharedHomes = True
    End If
End Function

'
' Return the stored ocm binary home directory tree based upon information
' stored in the sharedHome and persisted as part of configuration.
'
' Returns a undefined variable if this is not a SharedHome configuration.
'
Public Function getCcrBinHomeConfig(ByVal ccrHome)
  If SupportsSharedHomes(ccrHome) Then

    Dim dictProps : Set dictProps = CreateObject("Scripting.Dictionary")
    Dim dictResults,dictValue
    Call dictProps.Add("ccr.binHome","")
    Dim ccrConfigHome

    Call GetCCRConfigHome(ccrHome, ccrConfigHome)
    Dim propFiles(2),propFile
    propFiles(0) = ccrConfigHome & "\config\collector.properties"
    propFiles(1) = ccrConfigHome & "\config\default\collector.properties"

    For Each propFile in propFiles
      If FSO.FileExists(propFile) Then
        Set dictResults = getPropertyValues(propFile, dictProps)
        dictValue = dictResults.Item("ccr.binHome")
        If (Not IsUninitialized(dictValue)) Then
          Call unEscapeSpecialChars(dictValue)
          getCcrBinHomeConfig = dictValue
          Exit For
        End If
      End If
    Next
  End If
End Function 

'
' mimic Java Properties escaping, as when properties are persisted
'
Public Sub escapeSpecialChars(ByRef strToEsc)
  strToEsc = replace(strToEsc,"\","\\")
  strToEsc = replace(strToEsc,"!","\!")
  strToEsc = replace(strToEsc,"#","\#")
  strToEsc = replace(strToEsc,"=","\=")
  strToEsc = replace(strToEsc,":","\:")
End Sub
'
' mimic Java Properties "unescaping", as when properties are loaded
'
Public Sub unEscapeSpecialChars(ByRef strToEsc)
  strToEsc = replace(strToEsc,"\\","\")
  strToEsc = replace(strToEsc,"\!","!")
  strToEsc = replace(strToEsc,"\#","#")
  strToEsc = replace(strToEsc,"\=","=")
  strToEsc = replace(strToEsc,"\:",":")
End Sub

'
' Checks to see if the CCR_HOME matches the configuration stored in the 
' collector.properties in a SharedHome environment
'
' Returns
'     True - if the directories are the same
'     False - if the directories are not the same 
'
'     storedBinHome - the value found for configuration or undefined if
'                     not a sharedHome environment or unspecified.
'
Public Function configMatchesHome(ByVal ccrHome, ByRef storedBinHome)
  If SupportsSharedHomes(ccrHome) Then
    
    storedBinHome = getCcrBinHomeConfig(ccrHome)
    If (Not isUninitialized(storedBinHome)) Then
      configMatchesHome = compareDirSpec(storedBinHome, ccrHome) 
    Else
      configMatchesHome = False
    End If
  Else
      configMatchesHome = True
  End If
End Function
  
Public Function getAllScriptArguments()
    Dim objArgs : Set objArgs = WScript.Arguments
    Dim allArgs, argIndex
    For argIndex = 0 to objArgs.Count - 1
        allArgs = allArgs & objArgs(argIndex) & " "
    Next
    getAllScriptArguments = allArgs
End Function

Public Function isInSetupMode(ByVal ccrHome)
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")
    If (FSO.FileExists(ccrHome & "\lib\emCCRCollector.vbs")) Then
        isInSetupMode = False
    Else
        isInSetupMode = True
    End If
End Function

