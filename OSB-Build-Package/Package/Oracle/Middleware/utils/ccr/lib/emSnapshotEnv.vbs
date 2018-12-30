' $Header: emSnapshotEnv 07-mar-2006.15:47:41 jsutton
'
' Copyright Oracle 2006. All Rights Reserved
'
'    NAME
'      emSnapshotEnv.vbs - captures the environmental variables
'
'    DESCRIPTION
'      Captures the environmental variables required by daemon
'      tasks. Allows for re-capture
'
'    NOTES
'      Used by emCCR and other scripts to insure a consistent configuration
'      picture
'
'    MODIFIED   (MM/DD/YY)
'    proxy       07/01/10 - bug_fix_9861559 Adding ORACLE_INSTANCE env variable
'    ckalivar    11/11/09 - Snapshot env variable ORACLE_CCR_TESTS
'    jsutton     11/24/08 - BEAHOME should be BEA_HOME
'    jsutton     11/21/08 - Add WLS env requireds
'    ndutko      03/11/08 - Snapshot the ORACLE_OCM_SERVICE environmental
'                           variable
'    jsutton     08/06/07 - Windows support for shared OH
'    ndutko      09/13/06 - Addition of EBS INSTANCE ORACLE_CONFIG_HOME
'    nemalhot    05/22/06 - Fixing Null value checks 
'    ndutko      05/12/06 - Support the specification of JAVA_HOME that 
'                           contains a space (Bug 5223000) 
'    jsutton     05/10/06 - Lift from shell equivalent
Option Explicit

Dim oExec,oStdErr,oStdOut
Dim WshShell,WshEnv

Dim FSO
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8
Const TempFolder = 2

Const ENV_TYPE_STRING = 0
Const ENV_TYPE_PATH = 1
Const ENV_TYPE_FILE = 2


Dim CCRHome,CCRTemp,OracleHome,JavaHome,javaHomeEnv

Set WshShell = WScript.CreateObject("WScript.Shell")
Set WshEnv = WshShell.Environment("PROCESS")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Include core utility
IncludeCoreUtils

' Extract the binary directory specification where this script resides. 
' The enclosed code will come up with an absolute path. 
Dim CCRBinDir,CCRLibDir,CCRCfgHome
CCRBinDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName,"\"))
CCRLibDir = FSO.GetParentFolderName(CCRBinDir) & "\lib"

' Construct the CCR installation directory root based upon the bin
' directory being a child.
CCRHome = FSO.GetParentFolderName(CCRBinDir)

Call GetPaths(CCRHome,CCRBinDir,OracleHome,CCRCfgHome)

Dim envFile
Set envFile = FSO.CreateTextFile(CCRCfgHome & "/config/emCCRenv", True)

saveEnv "CLUSTER_NAME", envFile, ENV_TYPE_STRING
saveEnv "CRS_HOME", envFile, ENV_TYPE_PATH
saveEnv "EMAGENT_PERL_TRACE_LEVEL", envFile, ENV_TYPE_STRING
saveEnv "EMTAB", envFile, ENV_TYPE_FILE
saveEnv "JAVA_HOME", envFile, ENV_TYPE_PATH
saveEnv "JAVA_HOME_CCR", envFile, ENV_TYPE_PATH
saveEnv "ORACLE_HOME", envFile, ENV_TYPE_PATH
saveEnv "ORAINST_LOC", envFile, ENV_TYPE_PATH
saveEnv "TNS_ADMIN", envFile, ENV_TYPE_PATH
saveEnv "TZ", envFile, ENV_TYPE_STRING
saveEnv "ORACLE_CONFIG_HOME", envFile, ENV_TYPE_STRING
saveEnv "ORACLE_OCM_SERVICE", envFile, ENV_TYPE_STRING
saveEnv "WL_HOME", envFile, ENV_TYPE_STRING
saveEnv "BEA_HOME", envFile, ENV_TYPE_STRING
saveEnv "ORACLE_INSTANCE", envFile, ENV_TYPE_STRING
saveEnv "ORACLE_CCR_TESTS", envFile, ENV_TYPE_STRING

Private Sub saveEnv(varName, fileObj, envType)
  Dim envVal
  envVal = UnquoteString(WshEnv(varName))

  If (isUninitialized(envVal)) Then
    Exit Sub
  Else
    Select Case envType

      Case ENV_TYPE_PATH
              If (FSO.FolderExists(envVal)) Then
                envVal = FSO.GetFolder(envVal).ShortPath
              End If

      Case ENV_TYPE_FILE   
	      If (FSO.FileExists(envVal)) Then
                envVal = FSO.GetFile(envVal).ShortPath
              End If

    End Select
    fileObj.WriteLine(varName & "=" & envVal)
  End If
End Sub

' Includes the core utility file.
Private Sub IncludeCoreUtils
  Dim CoreUtils
  ' get directory context of this script, coreutils must be in the same directory
  CoreUtils = LCase(Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName,"\")))
  CoreUtils = CoreUtils & "..\lib\coreutil.vbs"
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
