{***************************************************************}
{                                                               }
{       HTML Help Viewer for Delphi 6 and 7                     }
{                                                               }
{       Copyright (c) 2004  Jan Goyvaerts                       }
{                                                               }
{       Design & implementation, by Jan Goyvaerts, 2004         }
{                                                               }
{***************************************************************}

{
  You may use this unit free of charge in all your Delphi applications.
  Distribution of this unit or units derived from it is prohibited.
  If other people would like a copy, they are welcome to download it from:
  http://www.helpscribble.com/delphi-bcb.html
  
  To enable HTML Help (i.e. using CHM files) in your application, simply
  add this unit to the uses clause in your .dpr project source file.

  Set the Application.HelpFile property to the .chm file you want to use,
  and assign HelpContext properties as usual.
  
  Note that unlike some other source code that is freely available on the 
  Internet to make Delphi 6 and 7 work with HTML Help, this unit does not 
  disable WinHelp.  Should you use a .hlp file rather than a .chm file 
  after all, HTMLHelpViewer will detect this and stay inactive, 
  letting the standard WinHelpViewer do its job.

  If you're looking for a tool to easily create HLP and/or CHM files,
  take a look at HelpScribble at http://www.helpscribble.com/
  HelpScribble includes a special HelpContext property editor for Delphi
  that makes it very easy to link your help file to your application.
}

unit HTMLHelpViewer;

interface

uses
  Windows, Messages, SysUtils, Types, Classes, Forms;

// Commands to pass to HtmlHelp()
const
  HH_DISPLAY_TOPIC        = $0000;
  HH_HELP_FINDER          = $0000;  // WinHelp equivalent
  HH_DISPLAY_TOC          = $0001;
  HH_DISPLAY_INDEX        = $0002;
  HH_DISPLAY_SEARCH       = $0003;
  HH_SET_WIN_TYPE         = $0004;
  HH_GET_WIN_TYPE         = $0005;
  HH_GET_WIN_HANDLE       = $0006;
  HH_ENUM_INFO_TYPE       = $0007;  // Get Info type name, call repeatedly to enumerate, -1 at end
  HH_SET_INFO_TYPE        = $0008;  // Add Info type to filter.
  HH_SYNC                 = $0009;
  HH_RESERVED1            = $000A;
  HH_RESERVED2            = $000B;
  HH_RESERVED3            = $000C;
  HH_KEYWORD_LOOKUP       = $000D;
  HH_DISPLAY_TEXT_POPUP   = $000E;  // display string resource id or text in a popup window
  HH_HELP_CONTEXT         = $000F;  // display mapped numeric value in dwData
  HH_TP_HELP_CONTEXTMENU  = $0010;  // text popup help, same as WinHelp HELP_CONTEXTMENU
  HH_TP_HELP_WM_HELP      = $0011;  // text popup help, same as WinHelp HELP_WM_HELP
  HH_CLOSE_ALL            = $0012;  // close all windows opened directly or indirectly by the caller
  HH_ALINK_LOOKUP         = $0013;  // ALink version of HH_KEYWORD_LOOKUP
  HH_GET_LAST_ERROR       = $0014;  // not currently implemented // See HHERROR.h
  HH_ENUM_CATEGORY        = $0015;	// Get category name, call repeatedly to enumerate, -1 at end
  HH_ENUM_CATEGORY_IT     = $0016;  // Get category info type members, call repeatedly to enumerate, -1 at end
  HH_RESET_IT_FILTER      = $0017;  // Clear the info type filter of all info types.
  HH_SET_INCLUSIVE_FILTER = $0018;  // set inclusive filtering method for untyped topics to be included in display
  HH_SET_EXCLUSIVE_FILTER = $0019;  // set exclusive filtering method for untyped topics to be excluded from display
  HH_INITIALIZE           = $001C;  // Initializes the help system.
  HH_UNINITIALIZE         = $001D;  // Uninitializes the help system.
  HH_PRETRANSLATEMESSAGE  = $00FD;  // Pumps messages. (NULL, NULL, MSG*).
  HH_SET_GLOBAL_PROPERTY  = $00FC;  // Set a global property. (NULL, NULL, HH_GPROP)

type
  HH_AKLINK = record
    cbStruct: Integer;
    fReserved: BOOL;
    pszKeywords: PChar;
    pszURL: PChar;
    pszMsgText: PChar;
    pszMsgTitle: PChar;
    pszWindow: PChar;
    fIndexOnFail: BOOL;
  end;

// HtmlHelp API function.
// You can use this to directly control HTML Help.
// However, using Application.HelpContext() etc. is recommended.
function HtmlHelp(hwndCaller: THandle; pszFile: PChar; uCommand: cardinal; dwData: longint): THandle; stdcall;

implementation

uses
  HelpIntfs, WinHelpViewer;

function HtmlHelp(hwndCaller: THandle; pszFile: PChar; uCommand: cardinal; dwData: longint): THandle; stdcall;
         external 'hhctrl.ocx' name 'HtmlHelpA';

type
  THTMLHelpViewer = class(TInterfacedObject, ICustomHelpViewer, IExtendedHelpViewer)
  private
    FViewerID : Integer;
    FHelpManager : IHelpManager;
    function HTMLHelpFileAvailable: Boolean;
  {$IFDEF VER140}
    procedure InternalShutDown;
  {$ENDIF}
  public
    { ICustomHelpViewer }
    function GetViewerName: string;
    function UnderstandsKeyword(const HelpString: String): Integer;
    function GetHelpStrings(const HelpString: String): TStringList;
    function CanShowTableOfContents: Boolean;
    procedure ShowHelp(const HelpString: String);
    procedure ShowTableOfContents;
    procedure NotifyID(const ViewerID: Integer);
    procedure SoftShutDown;
    procedure ShutDown;
    property HelpManager: IHelpManager read FHelpManager write FHelpManager;
    property ViewerID: Integer read FViewerID;
  public
    { IExtendedHelpViewer }
    function UnderstandsTopic(const Topic: String): Boolean;
    procedure DisplayTopic(const Topic: String);
    function UnderstandsContext(const ContextID: Integer; const HelpFileName: String): Boolean;
    procedure DisplayHelpByContext(const ContextID: Integer; const HelpFileName: String);
  end;

type
  { The new help system introduced in Delphi 6, designed to make it easy to link to different help systems
    from your application, is basically broken.  The problem is that the default WinHelp help viewer
    always pretends that it can fullfill the help request, even when the help file is not a WinHelp file.
    However, we can make the WinHelp viewer behave properly by implementing our own WinHelp tester. }
  TWinHelpMakeBehave = class(TInterfacedObject, IWinHelpTester)
  public
    function CanShowALink(const ALink, FileName: string): Boolean;
    function CanShowTopic(const Topic, FileName: string): Boolean;
    function CanShowContext(const Context: Integer; const FileName: string): Boolean;
    function GetHelpStrings(const ALink: string): TStringList;
    function GetHelpPath : string;
    function GetDefaultHelpFile: string;
  end;


{ THTMLHelpViewer }

function THTMLHelpViewer.CanShowTableOfContents: Boolean;
begin
  Result := HTMLHelpFileAvailable;
end;

function THTMLHelpViewer.GetHelpStrings(const HelpString: String): TStringList;
begin
  Result := TStringList.Create;
  // We cannot query the HTML Help API to get a list of topic titles.
  // So we just return HelpString if a .chm file is available.
  if HTMLHelpFileAvailable then Result.Add(HelpString);
  Assert(Result <> nil, 'ENSURE: GetHelpStrings must always return a valid string list');
end;

function THTMLHelpViewer.GetViewerName: String;
begin
  Result := 'HTMLHelp Viewer';
end;

function THTMLHelpViewer.HTMLHelpFileAvailable: Boolean;
begin
  Result := SameText(ExtractFileExt(FHelpManager.GetHelpFile), '.chm');
end;

procedure THTMLHelpViewer.NotifyID(const ViewerID: Integer);
begin
  FViewerID := ViewerID;
end;

procedure THTMLHelpViewer.ShowHelp(const HelpString: String);
var
  AKLink: HH_AKLink;
begin
  AKLink.cbStruct := SizeOf(AKLink);
  AKLink.fReserved := False;
  AKLink.pszKeywords := PChar(HelpString);
  AKLink.pszURL := nil;
  AKLink.pszMsgText := nil;
  AKLink.pszMsgTitle := nil;
  AKLink.pszWindow := nil;
  AKLink.fIndexOnFail := True;
  HTMLHelp(HelpManager.GetHandle, PChar(HelpManager.GetHelpFile), HH_KEYWORD_LOOKUP, Integer(@AKLink));
end;

procedure THTMLHelpViewer.ShowTableOfContents;
begin
  HTMLHelp(HelpManager.GetHandle, PChar(HelpManager.GetHelpFile), HH_DISPLAY_TOC, 0);
end;

procedure THTMLHelpViewer.ShutDown;
begin
  HTMLHelp(0, nil, HH_CLOSE_ALL, 0);
  FHelpManager := nil;
end;

procedure THTMLHelpViewer.SoftShutDown;
begin
  HTMLHelp(0, nil, HH_CLOSE_ALL, 0);
end;

function THTMLHelpViewer.UnderstandsKeyword(const HelpString: String): Integer;
begin
  // It is not possible to check if a .chm file's index contains a particular keyword through the HTML Help API
  // So we assume it does, if a .chm file is available at all
  if HTMLHelpFileAvailable then Result := 1
    else Result := 0
end;

procedure THTMLHelpViewer.DisplayHelpByContext(const ContextID: Integer; const HelpFileName: String);
begin
  HTMLHelp(HelpManager.GetHandle, PChar(HelpFileName), HH_HELP_CONTEXT, ContextID);
end;

procedure THTMLHelpViewer.DisplayTopic(const Topic: String);
var
  URL: string;
begin
  if Topic = '' then URL := ''
    else if Topic[1] = '/' then URL := '::' + Topic
    else URL := '::/' + Topic;
  HTMLHelp(HelpManager.GetHandle, PChar(HelpManager.GetHelpFile + URL), HH_DISPLAY_TOPIC, 0);
end;

function THTMLHelpViewer.UnderstandsContext(const ContextID: Integer; const HelpFileName: String): Boolean;
begin
  // It is not possible to check if the given context ID is mapped to a topic in the .chm file
  // So we assume it does, if a .chm file is available at all
  Result := HTMLHelpFileAvailable;
end;

function THTMLHelpViewer.UnderstandsTopic(const Topic: String): Boolean;
begin
  // It is not possible to check if .chm file contains a topic with the given file name
  // So we assume it does, if a .chm file is available at all
  Result := HTMLHelpFileAvailable;
end;

{$IFDEF VER140}
procedure THTMLHelpViewer.InternalShutDown;
begin
  SoftShutDown;
  if Assigned(FHelpManager) then FHelpManager.Release(FViewerID);
end;
{$ENDIF}

{ TWinHelpMakeBehave }

function TWinHelpMakeBehave.CanShowALink(const ALink, FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), '.hlp');
end;

function TWinHelpMakeBehave.CanShowContext(const Context: Integer; const FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), '.hlp');
end;

function TWinHelpMakeBehave.CanShowTopic(const Topic, FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), '.hlp');
end;

function TWinHelpMakeBehave.GetDefaultHelpFile: string;
begin
  Result := '';
end;

function TWinHelpMakeBehave.GetHelpPath: string;
begin
  Result := '';
end;

function TWinHelpMakeBehave.GetHelpStrings(const ALink: string): TStringList;
begin
  Result := TStringList.Create;
  Assert(Result <> nil, 'ENSURE: GetHelpStrings must always return a valid string list');
end;

var
  HelpViewer: THTMLHelpViewer;

initialization
  // Enable support for CHM files
  HelpViewer := THTMLHelpViewer.Create;
  HelpIntfs.RegisterViewer(HelpViewer, HelpViewer.FHelpManager);
  // Force the stupid WinHelp viewer to accept HLP files only
  // Otherwise, it will try to open the CHM file and show an error
  WinHelpTester := TWinHelpMakeBehave.Create;
{$IFDEF VER140}
finalization
  Application.OnHelp := nil;
  if Assigned(HelpViewer) then HelpViewer.InternalShutDown;
{$ENDIF}
end.
