' $Header: emll/lib/deployPackages.vbs /main/80 2010/12/21 13:18:03 fmorshed Exp $
'
' Copyright Oracle 2006. All Rights Reserved
'
'    NAME
'      deployPackages.vbs - script for deploy of CCR packages
'
'    DESCRIPTION
'      This script is used to deploy CCR package content
'
'    EXIT VALUES
'      0 - Success
'      1 - Prerequisite failure
'      2 - Invalid argument specified
'      3 - Invalid Usage
'      4 - Failed to obtain synchronization lock
'      5 - Install corrupt
'      6 - Upgrade in progress
'      7 - Missing command qualifier value.
'      8 - Not a directory.
'      11 - Unexpected Installation failure
'      12 - License Agreement declined
'      21 - OCM registration failure
'      22 - Registration key mismatch
'      81 - Package not supported.
'      82 - Not an OCM package.
'      83 - A package deployment issue was encountered.
'      84 - No access to the specified package.
'      85 - Qualifiers -distribution and -staged_dir are mutually exclusive
'      86 - Invalid directory specified for the -staged_dir qualifier.
'
'    MODIFIED
' fmorshed  03/25/11 - deriveCCR now defines an environment variable 
'                      DERIVECCR_IN_PROGRESS to tell who it invokes that
'                      there is a deriveCCR in progress.
' fmorshed  12/15/10 - getJavaHome now takes a verbose parameter
' fmorshed  10/22/10 - Change the call to interactive_runProc to pass an array
'                      of prompts
' qding     04/11/10 - fix nt diff. no need to dump cmd output since coreutil
'                      interactive_runProc already does so
' qding     03/31/10 - no need to expand manifest file since all diagchecks are
'                      bundled in one package now
' qding     03/23/10 - bug 9487653, change manifest from diagcheck.target_type
'                      to diagcheck_target_type
' qding     03/18/10 - bug 9460322, echo diagcheck stdout/stderr to the user
' qding     03/12/10 - bug 9471559, unzip the manifest file as well in
'                      uninstall function
' jsutton   03/11/10 - XbranchMerge jsutton_9401539_w from st_emll_10.3.2
' qding     02/01/10 - project 30108, OCheck
' ndutko    04/06/09 - OsInfo has moved to emocmcommon.jar
' tsubrama  02/02/09 - no jdk dependency
' ndutko    04/28/08 - Launch OsInfo from the emocmutl.jar file
' ndutko    10/22/07 - XbranchMerge ndutko_bug-6486128 from st_emll_10.2.7
' ndutko    10/22/07 - Check for whether the OH/OCH combination refers to a
'                      configured instance before beginning.
' ndutko    10/22/07 - XbranchMerge ndutko_bug-6511316 from st_emll_10.2.7
' ndutko    10/19/07 - XbranchMerge ndutko_bug-6467643 from st_emll_10.2.7
' ndutko    10/22/07 - Fix problems with escaped quotes
' ndutko    10/18/07 - Check to see if the configuration matches the binary
'                      home in the case of a sharedHome environment
' jsutton   08/06/07 - Windows support for shared OH
' jsutton   05/15/07 - XbranchMerge jsutton_bug-6054164 from st_emll_10.2.6
' jsutton   03/09/07 - Allow for deploying generic content
' jsutton   02/27/07 - Remove logjam on launched process output
' jsutton   02/23/07 - Change in lockfile() API, we pass a message
' jsutton   02/06/07 - XbranchMerge jsutton_bug-5851694 from st_emll_10.2.5
' ndutko    01/30/07 - Bug 5854444. Syntax failure
' ndutko    01/30/07 - XbranchMerge ndutko_bug_5854444 from st_emll_10.2.5
' ndutko    01/29/07 - XbranchMerge ndutko_bug-5849585 from st_emll_10.2.5
' ndutko    01/27/07 - Movement of Exit codes to coreutils.vbs
' ndutko    01/27/07 - XbranchMerge ndutko_bug-5846940 from st_emll_10.2.5
' nemalhot  01/21/07 - Fixed bug 5767864: modified compareVersion() method to
'                      take care of package versions which are less than 5
'                      parts.
' nemalhot  01/22/07 - Bug 5770006: Display log file path in case rollback
'                      occurs during update_components cmd
' nemalhot  01/09/07 - Corrected message for an invalid OCM package.
' nemalhot  01/02/07 - Implement deployPackages -u cmd for updating components.
' kgupta    12/21/06 - Return if need to reinstall (bug#5724553)
' jsutton   12/12/06 - Fix printToLog call
' jsutton   12/05/06 - Log platform and arch mismatches
' jsutton   11/30/06 - Declare and initialize nowTime
' jsutton   11/29/06 - Support deployment of generic packages
' jsutton   11/28/06 - Fix syntax error
' jsutton   11/22/06 - Timestamp upgrades in log
' jsutton   09/29/06 - Add cp . when running java OsInfo
' ndutko    09/27/06 - Convert the ShortName, ShortPath to Lower case for 
'                      string searches.
' ndutko    09/27/06 - XbranchMerge ndutko_setup_bugs from st_emll_10.2.4
' ndutko    09/19/06 - Ignore the need for registration details in package
'                      deployment in disconnected mode
' jsutton   09/12/06 - Fix deployPackages -l
' jsutton   09/07/06 - Additional work regarding multi-arch support
' jsutton   09/01/06 - Perform platform/arch checks only if not in rollback
' jsutton   08/24/06 - Finish up multi-arch work
' jsutton   08/23/06 - Fix up output on deploy failures
' jsutton   08/07/06 - Build temp file name as is done on Unix
' jsutton   07/20/06 - Checking packages for architecture info 
' jsutton   06/09/06 - Merge changes from 10.2.3 stream to MAIN 
' ndutko    05/30/06 - Do not attempt an installation of a package if returned 
'                      from lockfile after a block. 
' jsutton   05/30/06 - XbranchMerge jsutton_lockfile_shortname from 
'                      st_emll_10.2.3 
' kgupta    05/26/06 - Changes in kgupta_fix_5214665 for deployPackages got 
'                      overlapped, restoring those 
' ndutko    05/25/06 - Addition of synchronization of package installation ala 
'                      Linux methods 
' ndutko    05/24/06 - Shorten the filenames from iterating the pending 
'                      directory (bug 5244144) 
' jsutton   05/23/06 - Bail out of initEnv if ccr.properties missing 
' ndutko    05/18/06 - Use the common GetEnvironmentalValue() interface from 
'                      coreutil 
' kgupta    05/17/06 - Moving deployPackages.vbs to lib directory
' ndutko    05/16/06 - Instantiate the environment set in the emCCREnv file 
' ndutko    05/16/06 - Use the full validating JDK function when detecting the 
'                      JAVA_HOME validity 
' nemalhot  05/17/06 - Fixed Bug 5226597 
' jsutton   05/12/06 - Alternate approach to getting output from subprocesses 
' ndutko    05/12/06 - Support the specification of JAVA_HOME that contains a 
'                      space (Bug 5223000) 
' ndutko    05/12/06 - Support the specification of packages to install or 
'                      deinstall that contain spaced in the path (Bug 5223007) 
' ndutko    05/12/06 - Update usage to conform to unix syntax (bug 5222969) 
' jsutton   05/11/06 - Handle deployment failures, give feedback and roll back 
' jsutton   05/11/06 - arg handling 
' nemalhot  05/08/06 - convert directory paths to lowercase 
' jsutton   05/05/06 - Remove extra print of error info 
' jsutton   05/03/06 - Further script cleanup 
' jsutton   05/01/06 - Make sure progress messages are printed 
' jsutton   03/23/06 - xv should be xf 
' jsutton   03/16/06 - Use CCR_INSTALL_DEBUG where applicable 
' jsutton   03/13/06 - Fix problem w/existing file 
' jsutton   01/19/06 - initial
'
Option Explicit

Dim oExec,oStdErr,oStdOut
Dim WshShell,WshEnv

Dim FSO
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8
Const TempFolder = 2

' Constants to be used in exit codes.
Const SUCCESS = 0
Const ERR_PREREQ_FAILURE = 1
Const ERR_INVALID_ARG = 2
Const ERR_INVALID_USAGE = 3

'This is declared in coreutil.vbs
'Const ERR_LOCK_FAILURE=4
'Const ERR_CORRUPT_INSTALL=5
'Const ERR_UNEXPECTED_FAILURE

Const ERR_UPGRADE_IN_PROGRESS=6
Const MISSING_QUALIFIER_VALUE=7
Const NOT_A_DIRECTORY=8
Const ERR_LICENSE_DECLINED=12
Const ERR_REGISTRATION_FAILURE=21
Const ERR_KEY_MISMATCH=22
Const PKG_NOT_SUPPORTED=81
Const INVALID_OCM_PKG=82
Const PKG_DEPLOY_FAILURE=83
Const PKG_ACCESS_FAILURE=84
Const INVALID_QUALIFIER_COMBINATION=85
Const INVALID_DIRECTORY=86

Dim CCR_HOME,CCR_BIN,ORACLE_HOME,JAVA_HOME
Dim CCR_TEMP,CCR_CONFIG_HOME

Dim CCR_INSTALL_DEBUG
Dim CCR_DISCONNECTED

Dim g_rollback
Dim g_tmpDir
Dim g_deployFile
Dim g_packageName
Dim g_privateLog
Dim g_logFile
Dim g_logObj

Dim inParams
Dim inFile
Dim waitMsg

' package jars contain a manifest; we're interested in this data
Const pkgName = 0
Const pkgVersion = 1
Const pkgPlatform = 2
Const pkgDate = 3
Const pkgHeader = 4
Const pkgArch = 5
Const pkgSuppArch = 6
Const pkgManifestVer = 7

'End Structure

'**************************
' Main entry point
'**************************

Randomize

Set WshShell = WScript.CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set WshEnv = WshShell.Environment("PROCESS")

' Include core utility
IncludeCoreUtils

' Get the standard environmental variables.
Call GetPaths(CCR_HOME, CCR_BIN, ORACLE_HOME, CCR_CONFIG_HOME)

'
' Ensure CCR_CONFIG_HOME exists
'
If (Not FSO.FolderExists(CCR_CONFIG_HOME)) Then
  WScript.StdErr.WriteLine "OCM Configuration Home " & CCR_CONFIG_HOME & " is missing."
  WScript.Quit(ERR_PREREQ_FAILURE)
End If


'
' check to make certain that this OCM configuration is a validly constructed 
' one.
If (Not IsOCMConfigured(True)) Then
    WScript.Echo "OCM is not configured for this host or ORACLE_CONFIG_HOME. Please configure OCM first."
    WScript.Quit(ERR_PREREQ_FAILURE)
End If

'
' Get the CCR Temporary directory
CCR_TEMP = GetEnvironmentalValue("CCR_TEMP")
If (isUninitialized(CCR_TEMP)) Then
    CCR_TEMP = FSO.GetSpecialFolder(TempFolder)
Else
    If ( Not FSO.FolderExists(CCR_TEMP) ) Then
        WScript.StdErr.WriteLine "User specified location for TEMP (" & CCR_TEMP & ") does not exist"
        WScript.Quit(ERR_PREREQ_FAILURE)
    End If
End If

'
' init global variables, etc.
'
WshEnv("CCR_HOME") = CCR_HOME

' instantiate saved env
instantiateSavedEnv(CCR_CONFIG_HOME)

'
' Check to see that the configuration directory in shared mode is a pair to the
' binary tree. Use the emCCR to check for a config check (case specifically is in 
' the initial install of core, the core.jar does not get moved to inventory till
' a successfull install.
Dim matchingCCRHome
Dim CCRHomeBin : CCRHomeBin = FSO.BuildPath(CCR_HOME,"bin")
If (isUninitialized(GetEnvironmentalValue("DERIVECCR_IN_PROGRESS"))) Then
  If (FSO.FileExists(FSO.BuildPath(CCRHomeBin,"emCCR.bat"))) Then
    If (Not configMatchesHome(CCR_HOME, matchingCCRHome)) Then
      WScript.Echo "Error: This OCM configuration location corresponds to the installation in "
      WScript.Echo "the directory: """ & matchingCCRHome & """."
      WScript.Quit(ERR_PREREQ_FAILURE)
    End If
  End If
End If

if (NOT getJavaHome(JAVA_HOME, True)) Then
  WScript.Quit(ERR_PREREQ_FAILURE)
End If
Dim JavaBinPath : JavaBinPath = FSO.BuildPath(JAVA_HOME, "bin")

'
' If jdk/jar is available then use it, Otherwise use our util.
'
Dim Jar_Exe : Jar_Exe = FSO.BuildPath(JavaBinPath, "jar.exe")
If (Not FSO.FileExists(Jar_Exe)) Then
   Jar_Exe = FSO.BuildPath(CCRHomeBin, "ocmJarUtil.bat")
   If (Not FSO.FileExists(Jar_Exe)) Then
      WScript.Echo "OCM JAR Util is not found."
      WScript.Quit(ERR_PREREQ_FAILURE)
   End If
End If


Dim Java_Exe : Java_Exe = FSO.BuildPath(JavaBinPath, "java")

CCR_INSTALL_DEBUG = GetEnvironmentalValue("CCR_INSTALL_DEBUG")
If (isUninitialized(CCR_INSTALL_DEBUG)) Then
  CCR_INSTALL_DEBUG = ""
End If

Dim initStatus
initStatus = initEnv()
If (initStatus > 0) Then
  WScript.Quit(initStatus)
End If

' get command line parameters, switches...
Dim allArgs,argIndex,exitStatus
Set allArgs = WScript.Arguments
exitStatus = SUCCESS

If allArgs.Count = 0 Then
  printDebug "Deploy all pending packages"
  Call deployPackages
Else
  For argIndex = 0 to allArgs.count - 1
    If (allArgs(argIndex) = "-i") Then
      If allArgs.Count = argIndex+2 Then
        inFile = allArgs(argIndex + 1)

        ' Convert specification of arg to Short Absolute path
        inFile = LCase(FSO.GetFile(inFile).ShortPath)
        g_rollback = 0
        exitStatus = deploy(inFile)
        Exit For
      Else
        WScript.Echo("Required value for option '-i' not specified")
        WScript.Quit(MISSING_QUALIFIER_VALUE)
      End If
    ElseIf (allArgs(argIndex) = "-u") Then
      If allArgs.Count >= argIndex+2 Then
        inFile = allArgs(argIndex + 1)

        ' Convert specification of arg to Short Absolute path
        inFile = LCase(FSO.GetFile(inFile).ShortPath)
        g_rollback = 0
        exitStatus = updatePackage(inFile)
        Exit For
      Else
        WScript.Echo("Required value for option '-u' not specified")
        WScript.Quit(MISSING_QUALIFIER_VALUE)
      End If
    ElseIf (allArgs(argIndex) = "-d") Then
      If allArgs.Count = argIndex+2 Then
        inFile = allArgs(argIndex + 1)

        ' Convert specification of args to short paths and absolute
        inFile = LCase(FSO.GetFile(inFile).ShortPath)
        g_rollback = 0
        exitStatus = uninstall(inFile)
        Exit For
      Else
        WScript.Echo("Required value for option '-d' not specified")
        WScript.Quit(MISSING_QUALIFIER_VALUE)
      End If
    ElseIf (allArgs(argIndex) = "-l") Then
      doInventory()
      Exit For
    ElseIf (allArgs(argIndex) = "-h") Then
      usage()
      Exit For
    Else
      WScript.Echo("Unrecognized command qualifier or parameter: " & allArgs(argIndex))
      WScript.Quit(ERR_INVALID_ARG)
    End If
  Next
End If

WScript.Quit(exitStatus)

'-----------------------
' initialize environment
'-----------------------
Function initEnv()
  Dim dictProps : Set dictProps = CreateObject("Scripting.Dictionary")
  Dim dictResults
  Call dictProps.Add("ccr.disconnected","")
  Set dictResults = getPropertyValues(CCR_CONFIG_HOME & "\config\collector.properties", _
                                      dictProps)
  CCR_DISCONNECTED = dictResults.Item("ccr.disconnected")

  If (Not IsUninitialized(CCR_DISCONNECTED) And CCR_DISCONNECTED = "true") Then
    CCR_DISCONNECTED = True
  Else
    CCR_DISCONNECTED = False
  End If

  If (Not CCR_DISCONNECTED) Then
    initEnv = verifyInstall(CCR_CONFIG_HOME)

    If (initEnv <> 0) Then
       Exit Function
    End If

  End If

  ' create log directory if not there
  If (Not FSO.FolderExists(CCR_CONFIG_HOME & "\log")) Then
    printDebug "Creating " & CCR_CONFIG_HOME & "\log"
    FSO.CreateFolder(CCR_CONFIG_HOME & "\log")
  End If

  ' create inventory directory if not there
  If (Not FSO.FolderExists(CCR_HOME & "\inventory\pending")) Then
    printDebug "Creating " & CCR_HOME & "\inventory\pending"
    FSO.CreateFolder(CCR_HOME & "\inventory\pending")
  End If

  initEnv = 0
End Function

'-----------
' usage info
'-----------
Sub usage()

  Dim usageMsg,scriptName
  scriptName = Left(WScript.ScriptName, InStr(WScript.ScriptName, ".vbs")-1)

  usageMsg = "Usage: " & scriptName & " [-i <package-fs> | -d <package-fs> | -l]" & vbCrLf _
   & "" & vbCrLf _
   & "   where:" & vbCrLf _
   & "" & vbCrLf _
   & "      -i <package-fs>     installs the package with the filespec specified." & vbCrLf _
   & "      -d <package-fs>     deinstalls the package installed with the filespec" & vbCrLf _
   & "                          specified" & vbCrLf _
   & "      -u <package-fs>     updates the package with the filespec specified." & vbCrLf _
   & "      -l                  list inventory" & vbCrLf _
   & "" & vbCrLf _
   & "   If no options are specified, all pending deployment packages found in" & vbCrLf _
   & "   %ORACLE_HOME%\ccr\inventory\pending are installed."
  WScript.Echo(usageMsg)
End Sub

'---------------------
' roll back the deploy
'---------------------
Sub rollback()
  printDebug "ROLLBACK..."
  ' make sure we're not already in a rollback
  If (g_rollback > 0) Then
    Exit Sub
  End If

  ' wipe out the temp directory and its contents
  If (Not isUninitialized(g_tmpDir)) Then
    If FSO.FolderExists(g_tmpDir) Then
      printDebug "Removing " & g_tmpDir
      Call FSO.DeleteFolder(g_tmpDir, True)
    End If
  End If

  ' Check if package exists in CCR_HOME/inventory
  If (checkPkgDir(g_deployFile)) Then

    WScript.Echo("Error encountered in package deployment.")
    WScript.Echo("Check the contents of the deployment log - " & g_logFile)
    WScript.Echo(" ")

    ' Force the uninstall of the new package. Note, this will most
    ' likely yield errors as the installation failed and a full
    ' deinstall will fail as the installation never completed.
  
    Call printToLog("Deinstalling failed installation of " & g_deployFile, g_logFile)
    uninstall(g_deployFile)

    ' Remove the bad kit.  It will get downloaded via the collector
    ' anyway if there was no kit issue, but another resource issue.
    ' Except in the case where this is an installation codepath problem.
    Dim installCodepath: installCodepath = GetEnvironmentalValue("CCR_INSTALL_CODEPATH")
    If (isUninitialized(installCodepath)) Then
      If (FSO.FileExists(g_deployFile)) Then
        printDebug "Removing " & g_deployFile
        Call FSO.DeleteFile(g_deployFile, True)
      End If
    End If

    If (FSO.FileExists(CCR_HOME & "\inventory\" & g_packageName & ".jar")) Then
      WScript.Echo("Rolling back to previously installed version")
      Call printToLog("Rolling back to previously installed version", g_logFile)
      g_rollback = 1
      deploy(CCR_HOME & "\inventory\" & g_packageName & ".jar ")
      g_rollback = 0
    End If
  Else

    Dim fileName
    ' Strip path information from package
    fileName = FSO.GetFileName(g_deployFile)
 
    WScript.Echo("Error encountered in deployment of " & fileName)
    WScript.Echo("Check the contents of the deployment log - " & g_logFile)
    WScript.Echo(" ")

    ' Force the uninstall of the new package. Note, this will most
    ' likely yield errors as the installation failed and a full
    ' deinstall will fail as the installation never completed.  
    Call printToLog("Deinstalling failed installation of " & g_deployFile, g_logFile)
    uninstall(g_deployFile)

    If (FSO.FileExists(CCR_HOME & "\inventory\" & g_packageName & ".jar")) Then
      WScript.Echo("Rolling back to previously installed version")
      Call printToLog("Rolling back to previously installed version", g_logFile)
      g_rollback = 1
      deploy(CCR_HOME & "\inventory\" & g_packageName & ".jar ")
      g_rollback = 0
    End If

  End If

End Sub

'----------------------------
' uninstall the named package
'----------------------------
Function uninstall(l_pkgFile)
  uninstall = 0
  printDebug "Uninstall " & l_pkgFile
  ' get the package name from the input filename
  g_packageName = Left(l_pkgFile, InStrRev(LCase(l_pkgFile), ".jar", -1)-1)
  g_packageName = Right(g_packageName, Len(g_packageName) - InStrRev(g_packageName, "\", -1))

  printDebug "Uninstalling " & g_packageName

  ' get the current time for log file creation if necessary
  Dim deployTime,nowTime
  nowTime = Now
  deployTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) _
               & "." & Hour(nowTime) & "." & Minute(nowTime) & "." & Second(nowTime)
  deployTime = deployTime & "." & Int(1000 * Rnd)

  ' construct a log file if one was not previously defined
  If (isUninitialized(g_logFile)) Then
    g_privateLog = 1
    g_logFile = CCR_CONFIG_HOME & "\log\uninstall_" & g_packageName & "-" & deployTime & ".log"
    If (FSO.FileExists(g_logFile)) Then
      printDebug "Removing " & g_logFile
      Call FSO.DeleteFile(g_logFile)
    End If
    Set g_logObj = FSO.CreateTextFile(g_logFile, True)
    g_logObj.Close
  End If

  If (FSO.FileExists(l_pkgFile)) Then
    ' Create a temporary directory in TMP 
    Dim g_tmpUninstallDir
    g_tmpUninstallDir = CCR_TEMP & "\uninstall_" & g_packageName & "-" & deployTime

    Call printToLog("Uninstalling " & g_packageName, g_logFile)
    printDebug "Creating " & g_tmpUninstallDir
    FSO.CreateFolder(g_tmpUninstallDir)

    ' extract the uninstall executable into the temp dir
    Dim saveCurrDir
    saveCurrDir = LCase(FSO.GetFolder("."))
    WshShell.CurrentDirectory = g_tmpUninstallDir
    Call runProc(Jar_Exe, " xf " & l_pkgFile & " uninstall.vbs")

    'Put output in log file
    Call printToLog(oStdOut, g_logFile)

    WshShell.CurrentDirectory = saveCurrDir

    ' exec the uninstall procedure

    Call printToLog("Uninstall script unpacked, executing the script", g_logFile)
    ' we want the output from this to go into the log
    uninstall = runProc("cscript //nologo " & g_tmpUninstallDir & "\uninstall.vbs", "")

    'Put output in log file
    Call printToLog(oStdOut, g_logFile)
    
    Call printToLog("Uninstall complete", g_logFile)
    printDebug "Removing " & g_tmpUninstallDir
    Call FSO.DeleteFolder(g_tmpUninstallDir, True)
  End If

  ' wipe out any private log file, unless CCR_INSTALL_DEBUG is enabled
  If (isUninitialized(CCR_INSTALL_DEBUG)) Then
    If (g_privateLog > 0) Then
      printDebug "Removing " & g_logFile
      Call FSO.DeleteFile(g_logFile)
      g_privateLog = 0
      g_logFile = ""
    End If
  End If
End Function

' deploy the named jar file
Function deploy(l_pkgfile)
  printDebug "deploy " & l_pkgFile

  Dim fileName
  ' Strip path information from package
   fileName = FSO.GetFileName(l_pkgFile)
  
  ' can't install if there's no such file
  If (Not FSO.FileExists(l_pkgfile)) Then
    WScript.Echo("There is no such package as " & l_pkgfile & " to deploy")
    deploy = PKG_ACCESS_FAILURE
    Exit Function
  End If

  ' set the global variable
  g_deployFile = l_pkgfile

  ' get the package name, directory from the input filename
  g_packageName = Left(l_pkgFile, InStrRev(LCase(l_pkgFile), ".jar", -1)-1)
  g_packageName = Right(g_packageName, Len(g_packageName) - InStrRev(g_packageName, "\", -1))

  Dim packageDir
  packageDir = Left(l_pkgfile, InStrRev(l_pkgfile, "\", -1))

  printDebug l_pkgFile & " ... " & packageDir & " ... " & g_packageName

  ' check to see if the lock file is there; if so, bail out
  Dim pkgLockFile
  pkgLockFile = packageDir & g_packageName & ".lk"
  If (FSO.FileExists(pkgLockFile)) Then
    printDebug "Removing " & pkgLockFile
    Call FSO.DeleteFile(pkgLockFile)
    printDebug "Removing " & l_pkgfile
    Call FSO.DeleteFile(l_pkgfile)
    ' although this is an issue, we return with "normal" status
    deploy = ERR_LOCK_FAILURE
    Exit Function
  End If

  ' get the current time for log file creation if necessary
  Dim deployTime,nowTime
  nowTime = Now
  deployTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) _
               & "." & Hour(nowTime) & "." & Minute(nowTime) & "." & Second(nowTime)
  deployTime = deployTime & "." & Int(1000 * Rnd)

  g_logFile = CCR_CONFIG_HOME & "\log\install-" & g_packageName & "-" & deployTime & ".log"
  g_tmpDir = CCR_TEMP & "\" & g_packageName & "-" & deployTime

  ' If the log exists (it shouldn't due to the timestamp, but...)
  '  delete it.
  If (FSO.FileExists(g_logFile)) Then
    printDebug "Removing " & g_logFile
    Call FSO.DeleteFile(g_logFile)
  End If

  ' Determine if the temporary directory exists and if so, attempt to 
  ' delete it.  [What if this fails? Need to catch exceptions?]
  If (FSO.FolderExists(g_tmpDir)) Then
    printDebug "Removing " & g_tmpDir
    Call FSO.DeleteFolder(g_tmpDir, True) 
  End If

  printDebug "Creating " & g_tmpDir
  Call FSO.CreateFolder(g_tmpDir)

  ' now open the log file
  printDebug "Creating log file " & g_logFile
  Set g_logObj = FSO.CreateTextFile(g_logFile, True)
  g_logObj.Close

  ' if NOT in rollback, roll back if any of the remaining steps hit an error

  ' get manifest info, make sure platform OK
  Dim pkgInfo
  pkgInfo = getManifestInfo(FSO.GetFile(l_pkgfile))
  If (Err) Then
    WScript.StdErr.WriteLine l_pkgfile & " is not a valid OCM package."
    deploy = INVALID_OCM_PKG
    Exit Function
  End If

  If (Not (Instr(pkgInfo(pkgPlatform),"Windows") = 1 Or LCase(pkgInfo(pkgPlatform)) = "generic")) Then
    Dim badPlat : badPlat = "The kit being installed (" & fileName _
                  & ") is not for this platform, but for " & pkgInfo(pkgPlatform) & "."
    WScript.Echo(badPlat)
    Call printToLog(badPlat, g_logFile)
    rollback()
    deploy = PKG_NOT_SUPPORTED
    Exit Function
  End If

  ' Do platform/architecture checks if NOT in rollback AND manifest version >= 1.2
  If ((g_rollback = 0) And (StrComp(pkgInfo(pkgManifestVer),"1.2") >= 0)) Then
    ' generic packages need not check architecture either
    If (Not LCase(pkgInfo(pkgPlatform)) = "generic") Then
      ' go to CCR_HOME\lib, run OsInfo to get architecture
      Dim osArch,infoStat,saveCurrDir
      saveCurrDir = LCase(FSO.GetFolder("."))
      WshShell.CurrentDirectory = CCR_HOME & "\lib"
      infoStat = runProc(Java_Exe, " -cp " & _
                   FSO.BuildPath( FSO.BuildPath(CCR_HOME, "lib"), _
                                  "emocmcommon.jar") & ";" & _
                   FSO.BuildPath( FSO.BuildPath(CCR_HOME, "lib"), _
                                  "emocmutl.jar") & ";" & _
                   FSO.BuildPath(CCR_HOME, "lib") _
                                  & " OsInfo")
      WshShell.CurrentDirectory = saveCurrDir
      osArch = Split(oStdOut,vbCrLf,-1)
      ' check architecture against base & mapped/supported
      If (Not StrComp(osArch(0),pkgInfo(pkgArch)) = 0) Then
        Dim archArray,thisArch,archMapped
        archMapped = 0
        archArray = split(pkgInfo(pkgSuppArch),",",-1)
        For Each thisArch In archArray
          If StrComp(osArch(0),thisArch) = 0 Then
            archMapped = 1
          End If
        Next
        If (archMapped = 0) Then
          Dim badArch : badArch = "The kit being installed (" & fileName _
              & ") is not supported on this architecture (" & osArch(0) & ")."
          WScript.Echo(badArch)
          Call printToLog(badArch, g_logFile)
          rollback()
          deploy = PKG_NOT_SUPPORTED
          Exit Function
        End If
      End If
    End If
  End If

  ' unzip the entire file being deployed
  saveCurrDir = LCase(FSO.GetFolder("."))
  WshShell.CurrentDirectory = g_tmpDir
  deploy = interactive_runProc(Jar_Exe, " xf " & l_pkgfile, null)
  'dumpExecInfo
  WshShell.CurrentDirectory = saveCurrDir

  ' Force the uninstall of the package. Note, during rollback this 
  ' will most likely yield errors as the installation failed and a 
  ' full deinstall will fail as the installation never completed.
  If (g_rollback = 1) Then
    ' uninstall the 'pending' package
    Call printToLog("Deinstalling failed installation of " & CCR_HOME & "\inventory\pending\" & pkgInfo(pkgName) & ".jar", g_logFile)
    uninstall(CCR_HOME & "\inventory\pending\" & pkgInfo(pkgName) & ".jar")
    Call printToLog("Rolling back " & pkgInfo(pkgName) & "to version " & pkgInfo(pkgVersion), g_logFile)
  Else
    ' uninstall the existing package
    Call printToLog("Deinstalling previously deployed version of installed package " & pkgInfo(pkgName), g_logFile)
    uninstall(CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar")
    WScript.Echo("Deploying " & pkgInfo(pkgName) & " - Version " & pkgInfo(pkgVersion))
  End If

  Dim saveLog: saveLog = GetEnvironmentalValue("CCR_DEBUG_LOG")
  If (isUninitialized(saveLog)) Then
    saveLog = ""
  End If

  ' for saving status of deploy scripts
  Dim scriptStatus
  ' exec install.exe, postinstall.exe, config.exe from the temp dir
  Call printToLog("Executing package install script", g_logFile)
  WshEnv("CCR_DEBUG_LOG") = g_logFile
  Call runProc("cscript //nologo " & g_tmpDir & "\install.vbs", "")
  WshEnv("CCR_DEBUG_LOG") = saveLog
  Call printToLog(oStdOut, g_logFile)
  If Not (oExec.ExitCode = 0) Then
    ' save script exit status, roll back, and exit with the status from the script
    scriptStatus = oExec.ExitCode
    rollback()
    WScript.Quit(scriptStatus)
  End If

  Call printToLog("Executing package postinstall script", g_logFile)
  WshEnv("CCR_DEBUG_LOG") = g_logFile
  Call runProc("cscript //nologo " & g_tmpDir & "\postinstall.vbs", "")
  WshEnv("CCR_DEBUG_LOG") = saveLog
  Call printToLog(oStdOut, g_logFile)
  If Not (oExec.ExitCode = 0) Then
    ' save script exit status, roll back, and exit with the status from the script
    scriptStatus = oExec.ExitCode
    rollback()
    WScript.Quit(scriptStatus)
  End If

  Call printToLog("Executing package config script", g_logFile)
  WshEnv("CCR_DEBUG_LOG") = g_logFile
  Call runProc("cscript //nologo " & g_tmpDir & "\config.vbs", "")
  WshEnv("CCR_DEBUG_LOG") = saveLog
  Call printToLog(oStdOut, g_logFile)
  If Not (oExec.ExitCode = 0) Then
    ' save script exit status, roll back, and exit with the status from the script
    scriptStatus = oExec.ExitCode
    rollback()
    WScript.Quit(scriptStatus)
  End If

  If ( pkgInfo(pkgName) = "diagchecks" ) Then
  ' Checking whether there are properties need to be configured
    Call interactive_runProc(CCR_HOME & "\lib\configDiagchecks.bat", "diagchecks true ", null)
    WshEnv("CCR_DEBUG_LOG") = saveLog
    Call printToLog(oStdOut, g_logFile)
    If Not (oExec.ExitCode = 0) Then
      ' save script exit status, roll back, and exit with the status from the script
      scriptStatus = oExec.ExitCode
      rollback()
      WScript.Quit(scriptStatus)
    End If
  End If

  ' if NOT in rollback, and $CCR_HOME/inventory/$packageName exists, remove it
  If (g_rollback = 0) Then
    If (FSO.FileExists(CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar")) Then
      printDebug "Removing " & CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar"
      Call FSO.DeleteFile(CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar")
    End If
  End If

  If (checkPkgDir(l_pkgFile)) Then
    ' move the package jar file into $CCR_HOME/inventory as $packageName.jar
    printDebug "Moving " & l_pkgFile & " to " & CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar"
    Call FSO.MoveFile(l_pkgfile, CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar")
  Else
    ' copy package from user-specified directory
    Call FSO.CopyFile(l_pkgfile, CCR_HOME & "\inventory\" & pkgInfo(pkgName) & ".jar")
  End If

  ' remove the log file if NOT in debug mode
  If (isUninitialized(CCR_INSTALL_DEBUG)) Then
    printDebug "Removing " & g_logFile
    Call FSO.DeleteFile(g_logFile)
  End If

  ' clean up the temp directory
  If (FSO.FolderExists(g_tmpDir)) Then
    printDebug "Removing " & g_tmpDir
    Call FSO.DeleteFolder(g_tmpDir, True) 
  End If

  deploy = SUCCESS
End Function

'------------------------
' deploy pending packages
'------------------------
Function deployPackages()
  Dim pendingFldr,pendingFiles,pendingFile
  Set pendingFldr = FSO.GetFolder(CCR_HOME & "\inventory\pending")
  Set pendingFiles = pendingFldr.Files

  For Each pendingFile in pendingFiles
    If (LCase(FSO.GetExtensionName(pendingFile.name)) = "jar") Then
      printDebug "Recursive call; deploy " & pendingFile

      ' Determine a lock name based upon the package bundle and create a
      ' file lock resource to prevent two concurrent processing of the
      ' same bundle.
      Dim packageLock, lockStatus, objPackageLock, pendingFileSpec
      pendingFileSpec = LCase(pendingFile.ShortPath)
      Dim deployTime,nowTime
      nowTime = Now
      deployTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) _
               & "." & Hour(nowTime) & "." & Minute(nowTime) & "." & Second(nowTime)
      deployTime = deployTime & "." & Int(1000 * Rnd)    
      g_tmpDir = CCR_TEMP & "\info-" & deployTime

      If (FSO.FolderExists(g_tmpDir)) Then
        printDebug "Removing " & g_tmpDir
        Call FSO.DeleteFolder(g_tmpDir, True) 
      End If

      printDebug "Creating " & g_tmpDir
      Call FSO.CreateFolder(g_tmpDir)

      ' get manifest info, 
      Dim pkgInfo, packageName
      pkgInfo = getManifestInfo(FSO.GetFile(pendingFile))
      If (Err) Then
          WScript.StdErr.WriteLine pendingFile & " is not a valid OCM package."
      Else
          packageName = pkgInfo(pkgName)

          ' clean up the temp directory
          If (FSO.FolderExists(g_tmpDir)) Then
            printDebug "Removing " & g_tmpDir
            Call FSO.DeleteFolder(g_tmpDir, True) 
          End If
          packageLock = CCR_HOME & "\inventory\pending\" & packageName & ".installLk"

          ' If the lock file exists, indicate that we are stalling for the package deployment
          ' to complete.
          waitMsg =  "Stalling deployment waiting for the package to complete"
          lockStatus = lockfile( objPackageLock, 5, 60, packageLock, waitMsg )

          If (lockStatus) Then
             If (FSO.FileExists(pendingFileSpec)) Then
               dim CCR_TIMESTAMP : CCR_TIMESTAMP = GetEnvironmentalValue("CCR_TIMESTAMP")
               If (Not isUninitialized(CCR_TIMESTAMP) And CCR_TIMESTAMP = "1") Then
                 nowTime = Now
                 deployTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) _
                   & ":" & Hour(nowTime) & ":" & Minute(nowTime) & ":" & Second(nowTime)              
                 WScript.Echo("Deploying " & pendingFileSpec & " at " & deployTime)
               End If
               deployPackages = interactive_runProc("cscript //nologo " & CCR_HOME & "\lib\deployPackages.vbs", _
                                                    " -i " & pendingFileSpec, null)
               'dumpExecInfo
             End If
             Call releaseLockfile(objPackageLock, packageLock)
          Else
             WScript.Stderr.WriteLine "Unable to acquire deployment lock for " & _
                                      pendingFile.name & ". Skipping deployment of the package."
             Exit Function
          End If
      End If
    End If
  Next
End Function


' This method is used for updating CCR components from user-specified
' directory.
' Params:
'   l_pkgFile - package to be applied

Function updatePackage(l_pkgFile)

  ' Convert specification of arg to Short Absolute path
  l_pkgFile = LCase(FSO.GetFile(l_pkgFile).ShortPath)

  printDebug "deployPackage updatePackage, updating package " & l_pkgFile

  Dim fileName
  ' Strip path information from package
  fileName = FSO.GetFileName(l_pkgFile)

  ' Check if package exists
  If (Not FSO.FileExists(l_pkgFile)) Then  
    WScript.StdErr.WriteLine "There is no such package as " & fileName & " to deploy"
    updatePackage = PKG_ACCESS_FAILURE
    Exit Function
  End If

  ' Check if package exists in CCR_HOME/inventory
  If (checkPkgDir(l_pkgFile)) Then
    WScript.StdErr.WriteLine "Invalid package directory. Cannot install package from " & CCR_HOME & "\inventory."
    updatePackage = INVALID_DIRECTORY
    Exit Function
  End If

  If (Not isReadable(l_pkgFile)) Then
    WScript.StdErr.WriteLine "No read access to package " & fileName
    updatePackage = PKG_ACCESS_FAILURE
    Exit Function
  End If

  ' Determine a lock name based upon the package bundle and create a
  ' file lock resource to prevent two concurrent processing of the
  ' same bundle.
  Dim packageLock, lockStatus, objPackageLock
  Dim deployTime,nowTime
  nowTime = Now
  deployTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) _
               & "." & Hour(nowTime) & "." & Minute(nowTime) & "." & Second(nowTime)
  deployTime = deployTime & "." & Int(1000 * Rnd)    
  g_tmpDir = CCR_TEMP & "\info-" & deployTime  

  If (FSO.FolderExists(g_tmpDir)) Then
    printDebug "deployPackage updatePackage, Removing " & g_tmpDir
    Call FSO.DeleteFolder(g_tmpDir, True) 
  End If

  printDebug "deployPackage updatePackage, Creating " & g_tmpDir
  Call FSO.CreateFolder(g_tmpDir)

  printDebug "deployPackage updatePackage, Obtaining manifest information for " & l_pkgFile
  ' get manifest info, 
  Dim pkgInfo, packageName, packageVersion
  On Error Resume Next
  pkgInfo = getManifestInfo(FSO.GetFile(l_pkgFile))
  If (Err) Then
    WScript.StdErr.WriteLine fileName & " is not a valid OCM package."
    updatePackage = INVALID_OCM_PKG
    ' clean up the temp directory
    If (FSO.FolderExists(g_tmpDir)) Then
      printDebug "Removing " & g_tmpDir
      Call FSO.DeleteFolder(g_tmpDir, True) 
    End If
    Exit Function
  End If
  On Error Goto 0

  packageName = pkgInfo(pkgName)
  packageVersion = pkgInfo(pkgVersion)

  printDebug "deployPackage updatePackage, target package name: " & packageName & ".jar, version: " & packageVersion

  ' Get currently installed package version (if any)
  Dim inventoryPkg, currentVersion
  inventoryPkg = CCR_HOME & "\inventory\" & packageName & ".jar"
  If (FSO.FileExists(inventoryPkg)) Then
    pkgInfo = getManifestInfo(FSO.GetFile(inventoryPkg))
    currentVersion = pkgInfo(pkgVersion)

    printDebug "deployPackage updatePackage, current package name: " & packageName & ".jar, version: " & currentVersion

    ' Compare Version
    Dim retCode
    retCode = compareVersion(packageVersion, currentVersion)
    If (retCode <= 0) Then
      WScript.Stdout.WriteLine fileName & " is an old package. No update required."
      updatePackage = SUCCESS
      ' clean up the temp directory
      If (FSO.FolderExists(g_tmpDir)) Then
        printDebug "deployPackage updatePackage, Removing " & g_tmpDir
        Call FSO.DeleteFolder(g_tmpDir, True) 
      End If
      exit Function
    End If        
  End If

  ' clean up the temp directory
  If (FSO.FolderExists(g_tmpDir)) Then
    printDebug "deployPackage updatePackage, Removing " & g_tmpDir
    Call FSO.DeleteFolder(g_tmpDir, True) 
  End If

  ' Get lock for the package name
  packageLock = CCR_HOME & "\inventory\pending\" & packageName & ".installLk"

  printDebug "deployPackage updatePackage, Obtaining deployment lock for " & packageLock

  ' If the lock file exists, indicate that we are stalling for the package deployment
  ' to complete.
  waitMsg =  "Stalling deployment waiting for the package to complete"
  lockStatus = lockfile( objPackageLock, 5, 60, packageLock, waitMsg )

  If (lockStatus) Then
    If (FSO.FileExists(l_pkgFile)) Then
      dim CCR_TIMESTAMP : CCR_TIMESTAMP = GetEnvironmentalValue("CCR_TIMESTAMP")
      If (Not isUninitialized(CCR_TIMESTAMP) And CCR_TIMESTAMP = "1") Then
         nowTime = Now
         deployTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) _
           & ":" & Hour(nowTime) & ":" & Minute(nowTime) & ":" & Second(nowTime)
         WScript.Echo("Deploying " & fileName & " at " & deployTime)
      End If
         updatePackage = interactive_runProc("cscript //nologo " & CCR_HOME & "\lib\deployPackages.vbs", _
                                             " -i " & l_pkgFile, null)
         'dumpExecInfo
    End If
      Call releaseLockfile(objPackageLock, packageLock)
  Else
    WScript.Stderr.WriteLine "Unable to acquire deployment lock for " & _
                                  fileName & ". Skipping deployment of the package."
    updatePackage = ERR_LOCK_FAILURE
    Exit Function
  End If

End Function

' Compare targetVersion with currentVersion and return following
' 1 if targetVersion > currentVersion
' 0 if targetVersion = currentVersion
' -1 if targetVersion < currentVersion

Function compareVersion(targetVersion, currentVersion)

  Dim targetArray, currentArray

  'Split version information
  targetArray = Split(targetVersion, ".")
  currentArray = Split(currentVersion, ".")

  'Initialize empty fields
  Dim i, max
  i = 0

  'Compare five fields
  max = 4

  ReDim preserve targetArray(max)
  ReDim preserve currentArray(max)

  Do While (i <= max)
    If (isUninitialized(targetArray(i)) OR Not isNumeric(targetArray(i))) Then
      targetArray(i) = 0
    Else
      targetArray(i) = CInt(targetArray(i))
    End If

    If (isUninitialized(currentArray(i)) OR Not isNumeric(currentArray(i))) Then
      currentArray(i) = 0
    Else
      currentArray(i) = CInt(currentArray(i))
    End If  

    i = i +1
  Loop

  ' Compare
  i = 0
  Do While (i <= max)
    If (targetArray(i) > currentArray(i)) Then
      compareVersion = 1
      Exit Function
    ElseIf (targetArray(i) < currentArray(i)) Then
      compareVersion = -1
      Exit Function
    End If
    i = i +1
  Loop  
  
  compareVersion = 0

End Function

'
' Inventory installed & pending packages
'
Sub doInventory()
  Dim installedFldr,installedFiles,installedFile
  Dim pendingFldr,pendingFiles,pendingFile

  Set installedFldr = FSO.GetFolder(CCR_HOME & "\inventory")
  Set installedFiles = installedFldr.Files
  If (installedFiles.Count > 0) Then
    WScript.Echo("")
    WScript.Echo("Installed Oracle Configuration Manager Packages:")
    WScript.Echo("===============================================")
    For Each installedFile in installedFiles
      If (LCase(FSO.GetExtensionName(installedFile.name)) = "jar") Then
        displayPackageInfo(installedFile)
      End If
    Next
  End If

  Set pendingFldr = FSO.GetFolder(CCR_HOME & "\inventory\pending")
  Set pendingFiles = pendingFldr.Files
  If (pendingFiles.Count > 0) Then
    WScript.Echo("")
    WScript.Echo("Oracle Configuration Manager packages pending deployment:")
    WScript.Echo("========================================================")
    For Each pendingFile in pendingFiles
      If (LCase(FSO.GetExtensionName(pendingFile.name)) = "jar") Then
        displayPackageInfo(pendingFile)
      End If
    Next
  End If

End Sub

Sub displayPackageInfo(pkgJar)
  Dim invTime,nowTime
  nowTime = Now 
  invTime = Month(nowTime) & "-" & Day(nowTime) & "-" & Year(nowTime) & _
            "." & Hour(nowTime) & "." & Minute(nowTime) & "." & Second(nowTime)
  invTime = invTime & "." & Int(1000 * Rnd)

  g_tmpDir = CCR_TEMP & "\inv-" & invTime
  If FSO.FolderExists(g_tmpDir) Then
    WScript.Echo("Temporary directory " & g_tmpDir & " exists!")
    Exit Sub
  End If
  FSO.CreateFolder(g_tmpDir)
  Dim pkgInfo
  pkgInfo = getManifestInfo(pkgJar)

  WScript.Echo("Package " & pkgInfo(pkgName) _
               & ", Version " & pkgInfo(pkgVersion) _
               & " - built " & pkgInfo(pkgDate))
  ' List default and supported architectures
  If (StrComp(pkgInfo(pkgManifestVer),"1.2") >= 0) Then
    WScript.stdout.write("    built on " & pkgInfo(pkgArch))
    If Len(pkgInfo(pkgSuppArch)) > 0 Then
      WScript.stdout.write("; also supported: " & pkgInfo(pkgSuppArch))
    End If
    WScript.stdout.write(vbCrLf)
  End If

  ' clean up temp directory we just created & used
  Call FSO.DeleteFolder(g_tmpDir, True)

End Sub

Function getManifestInfo(pkgJar)
  Dim manInfo(9)

  ' extract the manifest into the temp dir
  Dim saveCurrDir 
  saveCurrDir = LCase(FSO.GetFolder("."))
  WshShell.CurrentDirectory = g_tmpDir
  Call interactive_runProc(Jar_Exe, " xf " & pkgJar.ShortPath & " META-INF/MANIFEST.MF", null)
  'dumpExecInfo
  WshShell.CurrentDirectory = saveCurrDir

  ' read package name, version, platform, date, header from manifest
  Dim manifestFile
  Set manifestFile = FSO.OpenTextFile(g_tmpDir & "\META-INF\MANIFEST.MF", ForReading)
  Dim manifestText
  Do While Not manifestFile.AtEndOfStream
    manifestText = manifestFile.ReadLine
    if (Not isUninitialized(manifestText)) Then
      Dim infoArray
      infoArray = Split(manifestText,": ",-1)
      Select Case infoArray(0)
        Case "package-name"
          manInfo(pkgName) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-version"
          manInfo(pkgVersion) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-platform"
          manInfo(pkgPlatform) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-date"
          manInfo(pkgDate) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-header"
          manInfo(pkgHeader) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-architecture"
          manInfo(pkgArch) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-supported-arch"
          manInfo(pkgSuppArch) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case "package-metadata-version"
          manInfo(pkgManifestVer) = Right(manifestText, Len(manifestText) - InStr(manifestText, ":")-1)
        Case Else
      End Select
    End If
  Loop
  manifestFile.Close
  getManifestInfo = manInfo
  ' clean up
  Call FSO.DeleteFile(g_tmpDir & "\META-INF\MANIFEST.MF")
End Function

Sub printToLog(logText, fileName)
  Dim outStream
  set outStream = FSO.OpenTextFile(fileName, ForAppending, True)
  outStream.WriteLine(logText)
  outStream.Close
End Sub

' Includes the core utility file.
Private Sub IncludeCoreUtils
    Dim CoreUtils, tmpCCRRootObj
    Dim FSO : Set FSO = WScript.CreateObject("Scripting.FileSystemObject")

    ' Derive the location of the temporary CCR_HOME from the script
    ' name. Its the parent directory of the parent directory.
    Set tmpCCRRootObj = FSO.GetFolder( _
                            FSO.GetParentFolderName( _
                                FSO.GetParentFolderName(WScript.ScriptFullName)))

    CoreUtils = FSO.BuildPath( _
                    FSO.BuildPath( tmpCCRRootObj.ShortPath, "lib" ), _
                    "coreutil.vbs" )

    IncludeFileAbs CoreUtils
End Sub

' Includes a file in the global namespace of the current script.
' The file can contain any VBScript source code.
' The path of the file name must be specified absolute (or
' relative to the current directory).
Private Sub IncludeFileAbs (ByVal FileName)
  Dim f: set f = FSO.OpenTextFile(FileName,ForReading)
  Dim s: s = f.ReadAll()
  ExecuteGlobal s
End Sub
