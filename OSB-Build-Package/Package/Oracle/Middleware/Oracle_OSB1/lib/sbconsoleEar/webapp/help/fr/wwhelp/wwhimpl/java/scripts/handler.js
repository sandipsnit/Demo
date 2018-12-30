// Copyright (c) 2000-2003 Quadralay Corporation.  All rights reserved.
//

function  WWHHandler_Object()
{
  this.mbInitialized = false;

  this.fInit              = WWHHandler_Init;
  this.fFinalize          = WWHHandler_Finalize;
  this.fGetFrameReference = WWHHandler_GetFrameReference;
  this.fGetFrameName      = WWHHandler_GetFrameName;
  this.fIsReady           = WWHHandler_IsReady;
  this.fUpdate            = WWHHandler_Update;
  this.fSyncTOC           = WWHHandler_SyncTOC;
  this.fProcessAccessKey  = WWHHandler_ProcessAccessKey;
  this.fGetCurrentTab     = WWHHandler_GetCurrentTab;
  this.fSetCurrentTab     = WWHHandler_SetCurrentTab;
}

function  WWHHandler_Init()
{
  // Java has already started loading
  // May have finished loading before this stage was reached
  //
  if (this.mbInitialized)
  {
    WWHFrame.WWHHelp.fHandlerInitialized();
  }
}

function  WWHHandler_Finalize()
{
  var  VarNavigationFrame;


  VarNavigationFrame = eval(WWHFrame.WWHHelp.fGetFrameReference("WWHNavigationFrame"));
  if (WWHFrame.WWHHelp.mInitialTabName != null)
  {
    VarNavigationFrame.document.applets[0].fShowTab(WWHFrame.WWHHelp.mInitialTabName);
  }
  else
  {
    VarNavigationFrame.document.applets[0].fShowTab("contents");
  }
}

function  WWHHandler_GetFrameReference(ParamFrameName)
{
  var  VarFrameReference;


  // Nothing to do
  //

  return VarFrameReference;
}

function  WWHHandler_GetFrameName(ParamFrameName)
{
  var  VarName = null;


  // Nothing to do
  //

  return VarName;
}

function  WWHHandler_IsReady()
{
  var  bVarIsReady = true;


  return bVarIsReady;
}

function  WWHHandler_Update(ParamBookIndex,
                            ParamFileIndex)
{
  var  VarNavigationFrame;


  VarNavigationFrame = eval(WWHFrame.WWHHelp.fGetFrameReference("WWHNavigationFrame"));
  VarNavigationFrame.document.applets[0].updateFavorites(ParamBookIndex, ParamFileIndex);
}

function  WWHHandler_SyncTOC(ParamBookIndex,
                             ParamFileIndex,
                             ParamAnchor,
                             bParamReportError)
{
  var  VarNavigationFrame;


  VarNavigationFrame = eval(WWHFrame.WWHHelp.fGetFrameReference("WWHNavigationFrame"));
  VarNavigationFrame.document.applets[0].syncTOC(ParamBookIndex, ParamFileIndex, ParamAnchor);
}

function  WWHHandler_ProcessAccessKey(ParamAccessKey)
{
  switch (ParamAccessKey)
  {
    case 1:
      this.fSetCurrentTab("contents");
      break;

    case 2:
      this.fSetCurrentTab("index");
      break;

    case 3:
      this.fSetCurrentTab("search");
      break;
  }
}

function  WWHHandler_GetCurrentTab()
{
  var  VarCurrentTab;
  var  VarNavigationFrame;
  var  VarCurrentTabAsJavaString;


  // Initialize return value
  //
  VarCurrentTab = "";

  VarNavigationFrame = eval(WWHFrame.WWHHelp.fGetFrameReference("WWHNavigationFrame"));
  VarCurrentTabAsJavaString = VarNavigationFrame.document.applets[0].fGetCurrentTab();
  VarCurrentTab += VarCurrentTabAsJavaString;

  return VarCurrentTab;
}

function  WWHHandler_SetCurrentTab(ParamTabName)
{
  var  VarNavigationFrame;


  VarNavigationFrame = eval(WWHFrame.WWHHelp.fGetFrameReference("WWHNavigationFrame"));

  switch (ParamTabName)
  {
    case "contents":
      VarNavigationFrame.document.applets[0].fShowTab(ParamTabName);

      // SyncTOC if possible
      //
      if (WWHFrame.WWHControls.fCanSyncTOC())
      {
        WWHFrame.WWHControls.fClickedSyncTOC();
      }
      break;

    case "index":
    case "search":
    case "favorites":
      VarNavigationFrame.document.applets[0].fShowTab(ParamTabName);
      break;
  }
}
