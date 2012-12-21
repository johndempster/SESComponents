unit MatrixDisplay;
// -----------------------------------
// Matrix multi-channel signal display
// -----------------------------------
// 19.10.12

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Clipbrd, printers, mmsystem, math, strutils ;
const
     ScopeChannelLimit = 1024 ;
     AllChannels = -1 ;
     NoRecord = -1 ;
     MaxStoredRecords = 200 ;
     MaxPoints = 131072 ;
     MaxColumns = 10 ;
     ScopeDisplayMaxPoints = 131072 ;
     MaxVerticalCursorLinks = 32 ;
type
    TPointArray = Array[0..MaxPoints-1] of TPoint ;
    TSinglePoint = record
        x : single ;
        y : single ;
        end ;
    TSinglePointArray = Array[0..MaxPoints-1] of TSinglePoint ;
    TScopeChannel = record
         xMin : single ;
         xMax : single ;
         yMin : single ;
         yMax : single ;
         xScale : single ;
         yScale : single ;
         Left : Integer ;
         Right : Integer ;
         Top : Integer ;
         Bottom : Integer ;
         ADCUnits : string ;
         ADCName : string ;
         ADCScale : single ;
         ADCZero : integer ;
         ADCZeroAt : Integer ;
         CalBar : single ;
         InUse : Boolean ;
         ADCOffset : Integer ;
         color : TColor ;
         Position : Integer ;
         ChanNum : Integer ;
         ZeroLevel : Boolean ;
         YSize : Single ;
         end ;
    TMousePos = ( TopLeft,
              TopRight,
              BottomLeft,
              BottomRight,
              MLeft,
              MRight,
              MTop,
              MBottom,
              MDrag,
              MNone ) ;

  TMatrixDisplayZoomButtonList = record
      Rect : TRect ;
      ButtonType : Integer ;
      ChanNum : Integer ;
      end ;



type
  TMatrixDisplay = class(TGraphicControl)
  private
    { Private declarations }
    FMinADCValue : Integer ;   // Minimum A/D sample value
    FMaxADCValue : Integer ;   // Maximum A/D sample value
    FNumChannels : Integer ;   // No. of channels in display
    FNumColumns : Integer ;    // No. of columns in display grid
    FNumRows : Integer ;       // No. of rows in display grid    
    FNumPoints : Integer ;     // No. of points displayed
    FMaxPoints : Integer ;     // Max. display points allowed
    FXMin : Integer ;          // Index of first sample in buffer on display
    FXMax : Integer ;          // Index of last sample in buffer on display
    FXOffset : Integer ;       // User-settable offset added to sample index numbers
                               // when computing sample times

    Channel : Array[0..ScopeChannelLimit] of TScopeChannel ;
//    KeepChannel : Array[0..ScopeChannelLimit] of TScopeChannel ;
    HorCursors : Array[0..ScopeChannelLimit] of TScopeChannel ;
    VertCursors : Array[0..64] of TScopeChannel ;
    FNumVerticalCursorLinks : Integer ;
    FLinkVerticalCursors : Array[0..2*MaxVerticalCursorLinks-1] of Integer ;
    FChanZeroAvg : Integer ;
    FTopOfDisplayArea : Integer ;
    FBottomOfDisplayArea : Integer ;
    FBuf : Pointer {^TSmallIntArray} ;
    FNumBytesPerSample : Integer ;

    FCursorsEnabled : Boolean ;
    FHorCursorActive : Boolean ;
    FHorCursorSelected : Integer ;
    FVertCursorActive : Boolean ;
    FVertCursorSelected : Integer ;
    FLastVertCursorSelected : Integer ;
    FZoomCh : Integer ;
    FMouseOverChannel : Integer ;
    FBetweenChannel : Integer ;
    FZoomDisableHorizontal : Boolean ;
    FZoomDisableVertical : Boolean ;
    FDisableChannelVisibilityButton : Boolean ;
//    MousePos : TMousePos ;
//    FXOld : Integer ;
//    FYOld : Integer ;
    FTScale : single ;
    FTUnits : string ;
    FTCalBar : single ;
    FFontSize : Integer ;
    FOnCursorChange : TNotifyEvent ;
    FCursorChangeInProgress : Boolean ;
    { Printer settings }
    FPrinterFontSize : Integer ;
    FPrinterPenWidth : Integer ;
    FPrinterFontName : string ;
    FPrinterLeftMargin : Integer ;
    FPrinterRightMargin : Integer ;
    FPrinterTopMargin : Integer ;
    FPrinterBottomMargin : Integer ;
    FPrinterDisableColor : Boolean ;
    FPrinterShowLabels : Boolean ;
    FPrinterShowZeroLevels : Boolean ;
    FMetafileWidth : Integer ;
    FMetafileHeight : Integer ;
    FTitle : TStringList ;
    { Additional line }
    FLine : ^TSinglePointArray ;
    FLineCount : Integer ;
    FLineChannel : Integer ;
    FLinePen : TPen ;
    { Display storage mode internal variables }
    FStorageMode : Boolean ;
    FStorageFileName : Array[0..255] of char ;
    FStorageFile : TFileStream ;

    FStorageList : Array[0..MaxStoredRecords-1] of Integer ;
    FRecordNum : Integer ;
    FDrawGrid : Boolean ;

    //Display settings
    FGridColor : TColor ;         // Calibration grid colour
    FTraceColor : TColor ;        // Trace colour
    FBackgroundColor : TColor ;   // Background colour
    FCursorColor : TColor ;       // Cursors colour
    FNonZeroHorizontalCursorColor : TColor ; // Cursor colour
    FZeroHorizontalCursorColor : TColor ;

    FFixZeroLevels : Boolean ; // True = Zero level cursors fixed at true zero

    FDisplaySelected : Boolean ;

    FMouseDown : Boolean ;

    BackBitmap : TBitMap ;        // Display background bitmap (traces/grid)
    ForeBitmap : TBitmap ;        // Display foreground bitmap (cursors)
    DisplayRect : TRect ;         // Rectangle defining size of display area

    FMarkerText : TStringList ;   // Marker text list

    MouseX : Integer ;            // Last know mouse X position
    MouseY : Integer ;            // Last know mouse Y position

    ZoomRect : TRect ;
    ZoomRectCount : Integer ;
    ZoomChannel : Integer ;
    ZoomButtonList : Array[0..100] of TMatrixDisplayZoomButtonList ;
    NumZoomButtons : Integer ;

    { -- Property read/write methods -------------- }

    procedure SetNumChannels(Value : Integer ) ;
    procedure SetNumColumns(Value : Integer ) ;    
    procedure SetNumPoints( Value : Integer ) ;
    procedure SetMaxPoints( Value : Integer ) ;

    procedure SetChanName( Ch : Integer ; Value : string ) ;
    function  GetChanName( Ch : Integer ) : string ;

    procedure SetChanUnits( Ch : Integer ; Value : string ) ;
    function  GetChanUnits( Ch : Integer ) : string ;

    procedure SetChanScale( Ch : Integer ; Value : single ) ;
    function  GetChanScale( Ch : Integer ) : single ;

    procedure SetChanCalBar( Ch : Integer ; Value : single ) ;
    function GetChanCalBar( Ch : Integer ) : single ;

    procedure SetChanZero( Ch : Integer ; Value : Integer ) ;
    function GetChanZero( Ch : Integer ) : Integer ;

    procedure SetChanZeroAt( Ch : Integer ; Value : Integer ) ;
    function GetChanZeroAt( Ch : Integer ) : Integer ;

    procedure SetChanZeroAvg( Value : Integer ) ;

    procedure SetChanOffset( Ch : Integer ; Value : Integer ) ;
    function GetChanOffset( Ch : Integer ) : Integer ;

    procedure SetChanVisible( Ch : Integer ; Value : boolean ) ;
    function GetChanVisible( Ch : Integer ) : Boolean ;

    procedure SetChanColor( Ch : Integer ; Value : TColor ) ;
    function GetChanColor( Ch : Integer ) : TColor ;

    procedure SetXMin( Value : Integer ) ;
    procedure SetXMax( Value : Integer ) ;
    procedure SetYMin( Value : single ) ;
    function GetYMin : single ;
    procedure SetYMax( Value : single ) ;
    function GetYMax : single ;
    procedure SetYSize( Ch : Integer ; Value : single ) ;
    function GetYSize( Ch : Integer ) : single ;

    procedure SetHorCursor( iCursor : Integer ; Value : Integer ) ;
    function GetHorCursor( iCursor : Integer ) : Integer ;
    procedure SetVertCursor( iCursor : Integer ; Value : Integer ) ;
    function GetVertCursor( iCursor : Integer ) : Integer ;

    procedure SetPrinterFontName( Value : string ) ;
    function GetPrinterFontName : string ;

    procedure SetPrinterLeftMargin( Value : Integer ) ;
    function GetPrinterLeftMargin : integer ;

    procedure SetPrinterRightMargin( Value : Integer ) ;
    function GetPrinterRightMargin : integer ;

    procedure SetPrinterTopMargin( Value : Integer ) ;
    function GetPrinterTopMargin : integer ;

    procedure SetPrinterBottomMargin( Value : Integer ) ;
    function GetPrinterBottomMargin : integer ;

    function GetXScreenCoord( Value : Integer ) : Integer ;

    procedure SetStorageMode( Value : Boolean ) ;

    procedure SetGrid( Value : Boolean ) ;

    function GetNumVerticalCursors : Integer ;
    function GetNumHorizontalCursors : Integer ;

    procedure SetFixZeroLevels( Value : Boolean ) ;

    { -- End of property read/write methods -------------- }


    { -- Methods used internally by component ------------ }

    function IntLimitTo( Value : Integer ; Lo : Integer ;  Hi : Integer ) : Integer ;
    procedure DrawHorizontalCursor( Canv : TCanvas ; iCurs : Integer ) ;
    function ProcessHorizontalCursors( X : Integer ; Y : Integer ) : Boolean ;
    procedure DrawVerticalCursor( Canv : TCanvas ; iCurs : Integer ) ;
    procedure DrawVerticalCursorLink( Canv : TCanvas ) ;

    function ProcessVerticalCursors( X : Integer ; Y : Integer )  : Boolean ;
    function XToCanvasCoord( var Chan : TScopeChannel ; Value : single ) : Integer  ;
    function CanvasToXCoord( var Chan : TScopeChannel ; xPix : Integer ) : Integer  ;
    function YToCanvasCoord( var Chan : TScopeChannel ; Value : single ) : Integer  ;
    function CanvasToYCoord( var Chan : TScopeChannel ; yPix : Integer ) : Integer  ;
    procedure PlotRecord( Canv : TCanvas ; var Channels : Array of TScopeChannel ;
                          var xy : Array of TPoint ) ;

    procedure CodedTextOut(
              Canvas : TCanvas ;
              var LineLeft : Integer ;
              var LineYPos : Integer ;
              List : TStringList
              ) ;

    procedure ClearDisplay( Canv : TCanvas ) ;

    procedure DrawZoomButton(
              var CV : TCanvas ;
              X : Integer ;
              Y : Integer ;
              Size : Integer ;
              ButtonType : Integer ;
              ChanNum : Integer
              ) ;
    procedure CheckZoomButtons ;
    procedure ShowSelectedZoomButton ;
    procedure ProcessZoomBox ;
    procedure ResizeZoomBox(
              X : Integer ;
              Y : Integer ) ;

    procedure UpdateChannelYSize(
              X : Integer ;
              Y : Integer
              ) ;


  protected
    { Protected declarations }
    procedure Paint ; override ;
    procedure MouseMove( Shift: TShiftState; X, Y: Integer ); override ;
    procedure MouseDown( Button: TMouseButton; Shift: TShiftState;X, Y: Integer ); override ;
    procedure MouseUp(Button: TMouseButton;Shift: TShiftState;X, Y: Integer ); override ;
    procedure DblClick ; override ;
    procedure Click ; override ;
    procedure Invalidate ; override ;
  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
    procedure ClearHorizontalCursors ;
    function AddHorizontalCursor( iChannel : Integer ;
                                  Color : TColor ;
                                  UseAsZeroLevel : Boolean ;
                                  CursorText : String
                                  ) : Integer ;
    procedure ClearVerticalCursors ;
    function AddVerticalCursor( Chan : Integer ;
                                Color : TColor ;
                                CursorText : String ) : Integer ;
    procedure MoveActiveVerticalCursor( Step : Integer ) ;
    procedure LinkVerticalCursors( C0 : Integer ; C1 : Integer ) ;

    procedure ZoomIn( Chan : Integer ) ;
    procedure ZoomOut ;

    procedure XZoom( PercentChange : Single ) ;
    procedure YZoom( Chan : Integer ; PercentChange : Single ) ;

    procedure SetDataBuf( Buf : Pointer ) ;
    procedure CopyDataToClipBoard ;
    procedure CopyImageToClipBoard ;
    procedure Print ;
    procedure ClearPrinterTitle ;
    procedure AddPrinterTitleLine( Line : string);
    procedure CreateLine( Ch : Integer ;
                          iColor : TColor ;
                          iStyle : TPenStyle ;
                          Width : Integer ) ;

    procedure AddPointToLine(x : single ; y : single ) ;

    procedure DisplayNewPoints( NewPoints : Integer ) ;


    procedure AddMarker ( AtPoint : Integer ; Text : String ) ;
    procedure ClearMarkers ;

    function XToScreenCoord(Chan : Integer ;Value : single ) : Integer  ;
    function YToScreenCoord(Chan : Integer ;Value : single ) : Integer  ;
    function ScreenCoordToX(Chan : Integer ;Value : Integer ) : single ;
    function ScreenCoordToY(Chan : Integer ;Value : Integer ) : single ;

    property ChanName[ i : Integer ] : string read GetChanName write SetChanName ;
    property ChanUnits[ i : Integer ] : string read GetChanUnits write SetChanUnits ;
    property ChanScale[ i : Integer ] : single read GetChanScale write SetChanScale ;
    property ChanCalBar[ i : Integer ] : single read GetChanCalBar write SetChanCalBar ;
    property ChanZero[ i : Integer ] : Integer read GetChanZero write SetChanZero ;
    property ChanZeroAt[ i : Integer ] : Integer read GetChanZeroAt write SetChanZeroAt ;
    property ChanZeroAvg : Integer read FChanZeroAvg write SetChanZeroAvg ;
    property ChanOffsets[ i : Integer ] : Integer read GetChanOffset write SetChanOffset ;
    property ChanVisible[ i : Integer ] : boolean read GetChanVisible write SetChanVisible ;
    property ChanColor[ i : Integer ] : TColor read GetChanColor write SetChanColor ;
    property YSize[ i : Integer ] : Single read GetYSize write SetYSize ;
    property YMin : single read GetYMin write SetYMin ;
    property YMax : single read GetYMax write SetYMax ;
    property XScreenCoord[ Value : Integer ] : Integer read GetXScreenCoord ;
    property HorizontalCursors[ i : Integer ] : Integer
             read GetHorCursor write SetHorCursor ;
    property VerticalCursors[ i : Integer ] : Integer
             read GetVertCursor write SetVertCursor ;

  published
    { Published declarations }
    property DragCursor ;
    property DragMode ;
    property OnDragDrop ;
    property OnDragOver ;
    property OnEndDrag ;
    property OnMouseDown ;
    property OnMouseMove ;
    property OnMouseUp ;
    property OnCursorChange : TNotifyEvent
             read FOnCursorChange write FOnCursorChange ;
    property CursorChangeInProgress : Boolean
             read FCursorChangeInProgress write FCursorChangeInProgress ;
    property Height default 150 ;
    property Width default 200 ;
    Property NumChannels : Integer Read FNumChannels write SetNumChannels ;
    Property NumColumns : Integer Read FNumColumns write SetNumColumns ;
    Property NumPoints : Integer Read FNumPoints write SetNumPoints ;
    Property MaxPoints : Integer Read FMaxPoints write SetMaxPoints ;
    property XMin : Integer read FXMin write SetXMin ;
    property XMax : Integer read FXMax write SetXMax ;
    property XOffset : Integer read FXOffset write FXOffset ;
    property CursorsEnabled : Boolean read FCursorsEnabled write FCursorsEnabled ;

    property ActiveHorizontalCursor : Integer read FHorCursorSelected ;
    property ActiveVerticalCursor : Integer read FHorCursorSelected ;
    property TScale : single read FTScale write FTScale ;
    property TUnits : string read FTUnits write FTUnits ;
    property TCalBar : single read FTCalBar write FTCalBar ;
    property ZoomDisableHorizontal : Boolean
             read FZoomDisableHorizontal write FZoomDisableHorizontal ;
    property ZoomDisableVertical : Boolean
             read FZoomDisableVertical write FZoomDisableVertical ;
    property DisableChannelVisibilityButton : Boolean
             read FDisableChannelVisibilityButton
             write FDisableChannelVisibilityButton ;
    property PrinterFontSize : Integer read FPrinterFontSize write FPrinterFontSize ;
    property PrinterFontName : string
             read GetPrinterFontName write SetPrinterFontName ;
    property PrinterPenWidth : Integer
             read FPrinterPenWidth write FPrinterPenWidth ;
    property PrinterLeftMargin : Integer
             read GetPrinterLeftMargin write SetPrinterLeftMargin ;
    property PrinterRightMargin : Integer
             read GetPrinterRightMargin write SetPrinterRightMargin ;
    property PrinterTopMargin : Integer
             read GetPrinterTopMargin write SetPrinterTopMargin ;
    property PrinterBottomMargin : Integer
             read GetPrinterBottomMargin write SetPrinterBottomMargin ;
    property PrinterDisableColor : Boolean
             read FPrinterDisableColor write FPrinterDisableColor ;
    property PrinterShowLabels : Boolean
             read FPrinterShowLabels write FPrinterShowLabels ;
    property PrinterShowZeroLevels : Boolean
             read FPrinterShowZeroLevels write FPrinterShowZeroLevels ;

    property MetafileWidth : Integer
             read FMetafileWidth write FMetafileWidth ;
    property MetafileHeight : Integer
             read FMetafileHeight write FMetafileHeight ;
    property StorageMode : Boolean
             read FStorageMode write SetStorageMode ;
    property RecordNumber : Integer
             read FRecordNum write FRecordNum ;
    property DisplayGrid : Boolean
             Read FDrawGrid Write SetGrid ;
    property MaxADCValue : Integer
             Read FMaxADCValue write FMaxADCValue ;
    property MinADCValue : Integer
             Read FMinADCValue write FMinADCValue ;
    property NumVerticalCursors : Integer read GetNumVerticalCursors ;
    property NumHorizontalCursors : Integer read GetNumHorizontalCursors ;
    property NumBytesPerSample : Integer read FNumBytesPerSample write FNumBytesPerSample ;
    property FixZeroLevels : Boolean read FFixZeroLevels write SetFixZeroLevels ;
    property DisplaySelected : Boolean
             read FDisplaySelected write FDisplaySelected ;
    property FontSize : Integer
             read FFontSize write FFontSize ;
  end;

procedure Register;

implementation
const
    LeftEdgeSpace = 60 ;
    RightEdgeSpace = 20 ;
    BottomEdgeSpace = 20 ;
    TopEdgeSpace = 5 ;
    ChannelNameSpace = 50 ;
    cZoomInButton = 0 ;
    cZoomOutButton = 1 ;
    cZoomUpButton = 2 ;
    cZoomDownButton = 3 ;
    cZoomLeftButton = 4 ;
    cZoomRightButton = 5 ;
    cEnabledButton = 6 ;

type
    TSmallIntArray = Array[0..$FFFFFF] of SmallInt ;
    PSmallIntArray = ^TSmallIntArray ;
    TIntArray = Array[0..$FFFFFF] of Integer ;
    PIntArray = ^TIntArray ;


procedure Register;
begin
  RegisterComponents('Samples', [TMatrixDisplay]);
end;

constructor TMatrixDisplay.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
var
   i,ch : Integer ;
begin

     inherited Create(AOwner) ;

     { Set opaque background to minimise flicker when display updated }
     ControlStyle := ControlStyle + [csOpaque] ;

     BackBitmap := TBitMap.Create ;
     ForeBitmap := TBitMap.Create ;
     BackBitmap.Width := Width ;
     BackBitmap.Height := Height ;
     ForeBitmap.Width := Width ;
     ForeBitmap.Height := Height ;

     { Create a list to hold any printer title strings }
     FTitle := TStringList.Create ;

     { Create an empty line array }
     FLine := Nil ;
     FLineCount := 0 ;
     FLineChannel := 0 ;
     FLinePen := TPen.Create;
     FLinePen.Assign(Canvas.Pen) ;

     FGridColor := clLtGray ;
     FTraceColor := clBlue ;
     FBackgroundColor := clWhite ;
     FCursorColor := clNavy ;
     FNonZeroHorizontalCursorColor := clRed ;
     FZeroHorizontalCursorColor := clGreen ;

     FMouseDown := False ;

     Width := 200 ;
     Height := 150 ;
     { Create internal objects used by control }

     FMinADCValue := -32768 ;
     FMaxADCValue := 32768 ;

     FNumChannels := 1 ;
     FNumColumns := 1 ;
     FNumRows := 1 ;
     FNumPoints := 0 ;
     FMaxPoints := 1024 ;
     FXMin := 0 ;
     FXMax := FMaxPoints - 1 ;
     FXOffset := 0 ;
     FChanZeroAvg := 20 ;
     FBuf := Nil ;
     FNumBytesPerSample := 2 ;
     for ch := 0 to High(Channel) do begin
         Channel[ch].InUse := True ;
         Channel[ch].ADCName := format('Ch.%d',[ch]) ;
         Channel[ch].ADCUnits := '' ;
         Channel[ch].YMin := FMinADCValue ;
         Channel[ch].YMax := FMaxADCValue ;
         Channel[ch].ADCScale := 1.0 ;
         Channel[ch].XMin := FXMin ;
         Channel[ch].XMax := FXMax ;
         Channel[ch].ADCOffset := ch ;
         Channel[Ch].CalBar := -1.0 ;    { <0 indicates no value entered yet }
         Channel[ch].Color := FTraceColor ;
         Channel[ch].ADCZeroAt := -1 ;
         Channel[ch].YSize := 1.0 ;
         end ;

     for i := 0 to High(HorCursors) do HorCursors[i].InUse := False ;
     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     FNumVerticalCursorLinks := 0 ;

    FCursorsEnabled := True ;
    FHorCursorActive := False ;
    FHorCursorSelected := -1 ;
    FVertCursorActive := False ;
    FVertCursorSelected := -1 ;
    FLastVertCursorSelected := 0 ;
    FOnCursorChange := Nil ;
    FCursorChangeInProgress := False ;
    FFixZeroLevels := False ;

    FTopOfDisplayArea := 0 ;
    FBottomOfDisplayArea := Height ;
    FZoomCh := 0 ;
    FMouseOverChannel := 0 ;
    FBetweenChannel := -1 ;
    FZoomDisableHorizontal := False ;
    FZoomDisableVertical := False ;
    FDisableChannelVisibilityButton := False ;
    FTUnits := 's' ;
    FTScale := 1.0 ;
    FTCalBar := -1.0 ;
    FFontSize := 8 ;
    FPrinterDisableColor := False ;
    FPrinterShowLabels := True ;
    FPrinterShowZeroLevels := True ;

    { Create file for holding records in stored display mode }
    FStorageMode := False ;
    FStorageFile := Nil ;
    for i := 0 to High(FStorageList) do FStorageList[i] := NoRecord ;
    FRecordNum := NoRecord ;

    FDrawGrid := True ;

    // Create marker text list
    FMarkerText := TStringList.Create ;

    FDisplaySelected := False ;

    ZoomRectCount := 0 ;
    NumZoomButtons := 0 ;

    end ;


destructor TMatrixDisplay.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin
     { Destroy internal objects created by TMatrixDisplay.Create }
     FBuf := Nil ;

     BackBitmap.Free ;  // Free internal bitmap
     ForeBitmap.Free ;

     { Call inherited destructor }
     inherited Destroy ;

     FTitle.Free ;
     FLinePen.Free ;
     if FStorageFile <> Nil then begin
        FStorageFile.Destroy ;
        DeleteFile( FStorageFileName ) ;
        FStorageFile := Nil ;
        end ;
     if FLine <> Nil then Dispose(FLine) ;

     FMarkerText.Free ;

     end ;


procedure TMatrixDisplay.Paint ;
{ ---------------------------
  Draw signal on display area
  ---------------------------}
const
     pFilePrefix : PChar = 'SCD' ;
var
   i,ch,Rec,NumBytesPerRecord : Integer ;

   SaveColor : TColor ;
   KeepPen : TPen ;
   TempPath : Array[0..255] of Char ;
   KeepColor : Array[0..ScopeChannelLimit] of TColor ;
   xy : ^TPointArray ;

begin

     { Create plotting points array }
     New(xy) ;
     KeepPen := TPen.Create ;

     // Keep within valid limits
     Top := Max( Top, 2 ) ;
     Left := Max( Left, 2 ) ;
     Height := Max( Height,2 ) ;
     Width := Max( Width,2 ) ;

     try

        // Make bit map same size as control
        if (BackBitmap.Width <> Width) or
           (BackBitmap.Height <> Height) then begin
           BackBitmap.Width := Width ;
           BackBitmap.Height := Height ;
           ForeBitmap.Width := Width ;
           ForeBitmap.Height := Height ;
           end ;

        DisplayRect := Rect(0,0,Width-1,Height-1) ;

        // Set colours
        BackBitmap.Canvas.Pen.Color := FTraceColor ;
        BackBitmap.Canvas.Brush.Color := FBackgroundColor ;

        // Clear display, add grid and labels
        ClearDisplay( BackBitmap.Canvas ) ;

        { Display records in storage list }
        if FStorageMode then begin

           { Create a temporary storage file, if one isn't already open }
           if FStorageFile = Nil then begin
              { Get path to temporary file directory }
              GetTempPath( High(TempPath), TempPath ) ;
              { Create a temp file name }
              GetTempFileName( TempPath, pFilePrefix, 0, FStorageFileName ) ;
              FStorageFile := TFileStream.Create( FStorageFileName, fmCreate ) ;
              end ;

           NumBytesPerRecord := FNumChannels*FNumPoints*2 ;

           { Save current record as first record in file }
           FStorageFile.Seek( 0, soFromBeginning ) ;
           FStorageFile.Write( FBuf^, NumBytesPerRecord ) ;

           { Change colour of stored records }
           for ch := 0 to FNumChannels-1 do begin
               KeepColor[Ch] := Channel[Ch].Color ;
               Channel[Ch].Color := clAqua ;
               end ;

           { Display old records stored in file }
           Rec := 1 ;
           while (FStorageList[Rec] <> NoRecord)
                 and (Rec <= High(FStorageList)) do begin
                 { Read buffer }
                 FStorageFile.Read( FBuf^, NumBytesPerRecord ) ;
                 { Plot record on display }
                 PlotRecord( BackBitmap.Canvas, Channel, xy^ ) ;
                 Inc(Rec) ;
                 end ;

           { Restore colour }
           for ch := 0 to FNumChannels-1 do Channel[Ch].Color := KeepColor[Ch] ;

           { Retrieve current record }
           FStorageFile.Seek( 0, soFromBeginning ) ;
           FStorageFile.Read( FBuf^, NumBytesPerRecord ) ;

           { Determine whether current record is already in list }
           Rec := 1 ;
           while (FStorageList[Rec] <> FRecordNum)
                 and (Rec <= High(FStorageList)) do Inc(Rec) ;

           { If record isn't in list add it to end }
           if Rec > High(FStorageList) then begin
              { Find next vacant storage slot }
              Rec := 1 ;
              while (FStorageList[Rec] <> NoRecord)
                    and (Rec <= High(FStorageList)) do Inc(Rec) ;
              { Add record number to list and store data in file }
              if Rec <= High(FStorageList) then begin
                 FStorageList[Rec] := FRecordNum ;
                 FStorageFile.Seek( Rec*NumBytesPerRecord, soFromBeginning ) ;
                 FStorageFile.Write( FBuf^, NumBytesPerRecord ) ;
                 end ;
              end ;
           end ;

        PlotRecord( BackBitmap.Canvas, Channel, xy^ ) ;

       { Plot external line on selected channel }
       if (FLine <> Nil) and (FLineCount > 1) then begin
          if Channel[FLineChannel].InUse then begin
             KeepPen.Assign(BackBitmap.Canvas.Pen) ;
             BackBitmap.Canvas.Pen.Assign(FLinePen) ;
             for i := 0 to FLineCount-1 do begin
                  xy^[i].x := XToCanvasCoord( Channel[FLineChannel], FLine^[i].x ) ;
                  xy^[i].y := YToCanvasCoord( Channel[FLineChannel], FLine^[i].y ) ;
                  end ;
             Polyline( BackBitmap.Canvas.Handle, xy^, FLineCount ) ;
             BackBitmap.Canvas.Pen.Assign(KeepPen) ;
             end ;
          end ;

        // Copy from internal bitmap to control
        Canvas.CopyRect( DisplayRect,
                         BackBitmap.Canvas,
                         DisplayRect) ;

        // Add cursors or zoom box
        { Horizontal Cursors }
        for i := 0 to High(HorCursors) do if HorCursors[i].InUse
            and Channel[HorCursors[i].ChanNum].InUse then DrawHorizontalCursor(Canvas,i) ;

        // Draw link between selected pair of vertical cursors
        DrawVerticalCursorLink(Canvas) ;

        // Draw red box round display to indicate it is selected

        SaveColor := Canvas.Brush.Color ;
        if FDisplaySelected then begin
           Canvas.Brush.Color := clRed ;
           Canvas.FrameRect( DisplayRect );
           Canvas.Brush.Color := SaveColor ;
           end ;

        { Vertical Cursors }
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
            DrawVerticalCursor(Canvas,i) ;

        ResizeZoomBox( ZoomRect.Right, ZoomRect.Bottom ) ;

        { Notify a change in cursors }
        if Assigned(OnCursorChange) and
          (not FCursorChangeInProgress) then OnCursorChange(Self) ;

     finally
        { Get rid of array }
        Dispose(xy) ;
        KeepPen.Free ;
        end ;

     end ;


procedure TMatrixDisplay.PlotRecord(
          Canv : TCanvas ;                        { Canvas to be plotted on }
          var Channels : Array of TScopeChannel ; { Channel definition array }
          var xy : Array of TPoint                { Work array }
          ) ;
{ -----------------------------------
  Plot a signal record on to a canvas
  ----------------------------------- }
var
   ch,n,i,j : Integer ;
   y : single ;
begin

     // Exit if no buffer
     if FBuf = Nil then Exit ;

     { Plot each active channel }
     for ch := 0 to FNumChannels-1 do if Channels[ch].InUse then begin
         Canv.Pen.Color := Channels[ch].Color ;
         n := 0 ;
         for i := Round(FXMin) to Min(Round(FXMax),FNumPoints-1) do begin

             j := (i*FNumChannels) + Channels[ch].ADCOffset ;
             if FNumBytesPerSample > 2 then y := PIntArray(FBuf)^[j]
                                       else y := PSmallIntArray(FBuf)^[j] ;
             xy[n].y := YToCanvasCoord( Channels[ch], y) ;
             xy[n].x := XToCanvasCoord( Channels[ch],i ) ;
             Inc(n) ;

             { If line exceeds 16000 output a partial line to canvas,
               since polyline function seems to be unable to handle more than 16000 points }
             if n > 16000 then begin
                Polyline( Canv.Handle, xy, n ) ;
                xy[0] := xy[n-1] ;
                n := 1 ;
                end ;

             end ;
         Polyline( Canv.Handle, xy, n ) ;

         // Display lines indicating area from which "From Record" zero level is derived
         if (Channels[ch].ADCZeroAt >= Channels[ch].xMin) and
            ((Channels[ch].ADCZeroAt+FChanZeroAvg) <= Channels[ch].xMax) then begin
            Canv.Pen.Color := FCursorColor ;
            xy[0].x := XToCanvasCoord( Channels[ch],Channels[ch].ADCZeroAt ) ;
            xy[1].x := xy[0].x ;
            xy[0].y := YToCanvasCoord( Channels[ch], Channels[ch].ADCZero ) - 15 ;
            xy[1].y := xy[0].y + 30 ;
            Polyline( Canv.Handle, xy, 2 ) ;

            xy[0].x := XToCanvasCoord( Channels[ch],
                                       Channels[ch].ADCZeroAt + FChanZeroAvg -1) ;
            xy[1].x := xy[0].x ;
            xy[0].y := YToCanvasCoord( Channels[ch], Channels[ch].ADCZero ) - 15 ;
            xy[1].y := xy[0].y + 30 ;
            Polyline( Canv.Handle, xy, 2 ) ;

            end ;
         end ;
     end ;


procedure TMatrixDisplay.ClearDisplay(
          Canv : TCanvas               // Canvas to be cleared
          ) ;
{ ---------------------------
  Clear signal display canvas
  ---------------------------}
const
    TickSize = 4 ;
    ButtonSize  = 12 ;
    TickMultipliers : array[0..6] of Integer = (1,2,5,10,20,50,100) ;
var
   CTop,ch,i,NumInUse,AvailableHeight,ChannelHeight,ChannelSpacing,LastActiveChannel : Integer ;
   Lab : string ;
   x,xPix,y,yPix : Integer ;
   dy,dx : Single ;
   KeepColor : TColor ;
   XGrid : Single ;                // Vertical grid X coord
   s : String ;
   yVal : Single ;
   yRange,TickBase,YTick,YTickSize,YTickMin,YTickMax,YScaledMax,YScaledMin : Single ;
   r,XRange,XTick,XTickSize,XTickMin,XTickMax,XScaledMax,XScaledMin : Single ;
   XAxisAt : Integer ;
   YTotal : Single ;
   iTick, NumTicks : Integer ;
   ChannelXSpacing,ChannelYSpacing : Integer ;
   iRow,iCol : Integer ;
   xMid,yMid : Integer ;
begin
     FNumColumns := 8 ;
     FNumRows := FNumChannels div FNumColumns ;
     if (FNumChannels mod FNumColumns) <> 0 then Inc(FNumRows) ;

     Canv.Font.Size := FFontSize ;
     // Clear number of zoom buttons on display
     NumZoomButtons := 0 ;

     { Clear display area }
     Canv.fillrect(DisplayRect);

     { Determine number of channels in use and the height
       available for each channel }
     YTotal := 0.0 ;
     NumInUse := 0 ;
     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
        Inc(NumInUse) ;
        YTotal := YTotal + Channel[ch].YSize ;
        end ;
     if NumInUse < 1 then begin
        YTotal := 1.0 ;
        end ;

     Canv.Font.Size := FFontSize ;
     Canv.Font.Color := FTraceColor ;

     { Define display area for each channel in use }
     cTop := TopEdgeSpace ;
     FTopOfDisplayArea := cTop ;
     LastActiveChannel := 0 ;

     ChannelXSpacing := (Width - RightEdgeSpace - LeftEdgeSpace) div FNumColumns ;
     ChannelYSpacing := (Height - 2*Canv.TextHeight('X') - FTopOfDisplayArea) div FNumRows ;
     FBottomOfDisplayArea := FTopOfDisplayArea + ChannelYSpacing*FNumRows ;

     for ch := 0 to FNumChannels-1 do begin

         iRow := ch div FNumColumns ;
         iCol := ch mod FNumColumns ;
         // Update X scale for all channels
         Channel[ch].Left := LeftEdgeSpace + ChannelXSpacing*iCol + ChannelNameSpace ;
         Channel[ch].Right := Channel[ch].Left + ChannelXSpacing - ChannelNameSpace ;
         Channel[ch].Top := FTopOfDisplayArea + ChannelYSpacing*iRow ;
         Channel[ch].Bottom := Channel[ch].Top + ChannelYSpacing - Canv.TextHeight('X') ;

         if FXMax = FXMin then FXMax := FXMin + 1 ;
         Channel[ch].xMin := FXMin ;
         Channel[ch].xMax := FXMax ;
         Channel[ch].xScale := (Channel[ch].Right - Channel[ch].Left) /
                               (FXMax - FXMin ) ;

         // Update y scale for channels in use
         if Channel[ch].yMax = Channel[ch].yMin then Channel[ch].yMax := Channel[ch].yMin + 1.0 ;
         Channel[ch].yScale := (Channel[ch].Bottom - Channel[ch].Top) /
                                  (Channel[ch].yMax - Channel[ch].yMin ) ;

         end ;

     // Display channel enabled buttons
     Canv.Pen.Color := clBlack ;
     for ch := 0 to FNumChannels-1 do if not FDisableChannelVisibilityButton then begin
         YPix := (Channel[ch].Top + Channel[ch].Bottom {- ButtonSize}) div 2 ;
         XPix := 2 ;
{         DrawZoomButton( Canv,
                         XPix,
                         YPix,
                         ButtonSize,
                         cEnabledButton,
                         ch ) ;}

         end ;

     { Update horizontal cursor limits/scale factors to match channel settings }
     for i := 0 to High(HorCursors) do if HorCursors[i].InUse then begin
         HorCursors[i].Left := Channel[HorCursors[i].ChanNum].Left ;
         HorCursors[i].Right := Channel[HorCursors[i].ChanNum].Right ;
         HorCursors[i].Top := Channel[HorCursors[i].ChanNum].Top ;
         HorCursors[i].Bottom := Channel[HorCursors[i].ChanNum].Bottom ;
         HorCursors[i].xMin := Channel[HorCursors[i].ChanNum].xMin ;
         HorCursors[i].xMax := Channel[HorCursors[i].ChanNum].xMax ;
         HorCursors[i].xScale := Channel[HorCursors[i].ChanNum].xScale ;
         HorCursors[i].yMin := Channel[HorCursors[i].ChanNum].yMin ;
         HorCursors[i].yMax := Channel[HorCursors[i].ChanNum].yMax ;
         HorCursors[i].yScale := Channel[HorCursors[i].ChanNum].yScale ;
         end ;

     { Update vertical cursor limits/scale factors  to match channel settings}
     for i := 0 to High(VertCursors) do if VertCursors[i].InUse then begin
         if VertCursors[i].ChanNum >= 0 then begin
            { Vertical cursors linked to individual channels }
            VertCursors[i].Left := Channel[VertCursors[i].ChanNum].Left ;
            VertCursors[i].Right := Channel[VertCursors[i].ChanNum].Right ;
            VertCursors[i].Top := Channel[VertCursors[i].ChanNum].Top ;
            VertCursors[i].Bottom := Channel[VertCursors[i].ChanNum].Bottom ;
            VertCursors[i].xMin := Channel[LastActiveChannel].xMin ;
            VertCursors[i].xMax := Channel[LastActiveChannel].xMax ;
            VertCursors[i].xScale := Channel[VertCursors[i].ChanNum].xScale ;
            VertCursors[i].yMin := Channel[LastActiveChannel].yMin ;
            VertCursors[i].yMax := Channel[LastActiveChannel].yMax ;
            VertCursors[i].yScale := Channel[VertCursors[i].ChanNum].yScale ;
            end
         else begin
            { All channel cursors }
            VertCursors[i].Left := Channel[LastActiveChannel].Left ;
            VertCursors[i].Right := Channel[LastActiveChannel].Right ;
            VertCursors[i].Top := FTopOfDisplayArea ;
            VertCursors[i].Bottom := FBottomOfDisplayArea ;
            VertCursors[i].xMin := Channel[LastActiveChannel].xMin ;
            VertCursors[i].xMax := Channel[LastActiveChannel].xMax ;
            VertCursors[i].xScale := Channel[LastActiveChannel].xScale ;
            VertCursors[i].yScale := 1.0 ;
            end ;
         end ;

         KeepColor := Canv.Pen.Color ;
         Canv.Pen.Color := FGridColor ;


     // Draw horizontal time calibration bar

     XRange := (FXMax - FXMin)*FTScale ;
     TickBase := 0.01*exp(Round(Log10(Abs(xRange)))*ln(10.0)) ;
     for i := 0 to High(TickMultipliers) do begin
         XTickSize := TickBase*TickMultipliers[i] ;
         if (XRange/XTickSize) <= 2.0 then Break ;
         end ;
     dx := (Channel[0].Right - Channel[0].Left) / XRange ;
     xPix := Channel[0].Left ;
     yPix := Height - 2*Canv.TextHeight('X') ;

     Canv.Pen.Style := psSolid ;
     Canv.Pen.Color := clBlack ;
     Canv.MoveTo( xPix, yPix - (Canv.TextHeight('X') div 3) )  ;
     Canv.LineTo( xPix, yPix + (Canv.TextHeight('X') div 3) )  ;
     Canv.TextOut( xPix,yPix + (2*Canv.TextHeight('X') div 3),
                  format('%.3g %s',[XTickSize,FTUnits])  )  ;
     Canv.MoveTo( xPix, yPix )  ;

     xPix := xPix + Round(dx*XTickSize) ;
     Canv.LineTo( xPix, yPix )  ;
     Canv.MoveTo( xPix, yPix - (Canv.TextHeight('X') div 3) )  ;
     Canv.LineTo( xPix, yPix + (Canv.TextHeight('X') div 3) )  ;

     // Draw vertical signal anplitude calibration bar

     if Channel[0].ADCScale = 0.0 then Channel[0].ADCScale := 1.0 ;
     yRange := Abs(Channel[0].yMax - Channel[0].yMin)*Channel[0].ADCScale ;
     TickBase := 0.01*exp(Round(Log10(Abs(yRange)))*ln(10.0)) ;
     for i := 0 to High(TickMultipliers) do begin
         YTickSize := TickBase*TickMultipliers[i] ;
         if (yRange/YTickSize) <= 2.0 then Break ;
         end ;

     dy := (Channel[0].Top - Channel[0].Bottom) / YRange ;
     xPix := Canv.TextWidth('X') ;
     yPix := FBottomOfDisplayArea ;

     Canv.Pen.Style := psSolid ;
     Canv.Pen.Color := clBlack ;
     Canv.MoveTo( xPix - (Canv.TextWidth('X') div 3),yPix )  ;
     Canv.LineTo( xPix + (Canv.TextWidth('X') div 3), yPix )  ;
     Canv.MoveTo( xPix, yPix )  ;
     yPix := yPix + Round(dy*YTickSize) ;
     Canv.LineTo( xPix, yPix )  ;
     Canv.MoveTo( xPix - (Canv.TextWidth('X') div 3),yPix )  ;
     Canv.LineTo( xPix + (Canv.TextWidth('X') div 3), yPix )  ;

     Canv.TextOut( xPix + (2*Canv.TextWidth('X') div 3),
                   yPix - Round(0.5*dy*YTickSize),
                   format('%.4g %s',[YTickSize,Channel[0].ADCUnits])  )  ;
     // Display channel name(s)

     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin

         Canv.Pen.Color := clBlack ; //Channel[ch].Color ;
         Canv.Font.Color := clBlack ;

         // Draw label & units mid-way between lower and upper limits
         YMid := (Channel[ch].Top + Channel[ch].Bottom) div 2 ;
         s := Channel[ch].ADCName ;
         Canv.TextOut( Max(Channel[ch].Left - Canv.TextWidth(s+'x') - 1,0),
                       YMid - Canv.TextHeight(s) -1,
                       s) ;

         if Channel[ch].ADCScale <> Channel[0].ADCScale then begin
            s := format('/%.2g',[Channel[0].ADCScale/Channel[ch].ADCScale]) ;
            Canv.TextOut( Max(Channel[ch].Left - Canv.TextWidth(s+'x') - 1,0),
                          YMid,
                          s) ;
            end ;

         end ;

     // Display zoom buttons

     if not FZoomDisableVertical then begin

         xMid := ButtonSize + 1 ;
         yMid := Height div 2 ;
         //xPix := 0 ;
         yPix := Height - ButtonSize - 1 ;
         ch := 0 ;
         DrawZoomButton( Canv,
                         xMid,
                         YMid - (ButtonSize+1)*2,
                         12,
                         cZoomUpButton,
                         ch ) ;

            DrawZoomButton( Canv,
                         xMid,
                         YMid - (ButtonSize+1),
                         12,
                         cZoomInButton,
                         ch ) ;

             DrawZoomButton( Canv,
                         xMid,
                         YMid + (ButtonSize+1),
                         12,
                         cZoomOutButton,
                         ch ) ;

             DrawZoomButton( Canv,
                         xMid,
                         YMid + (ButtonSize+1)*2,
                         12,
                         cZoomDownButton,
                         ch ) ;
             end ;


     if not FZoomDisableHorizontal then begin

         xMid := (Max(ClientWidth,2) - (ButtonSize*2)) div 2 ;
         yMid := Height - ButtonSize - 1 ;

         DrawZoomButton( Canv,
                         xMid - (ButtonSize+1)*2,
                         yMid,
                         12,
                         cZoomLeftButton,
                         -1 ) ;

         xPix := xPix + 14 ;
         DrawZoomButton( Canv,
                         xMid - (ButtonSize+1),
                         yMid,
                         12,
                         cZoomInButton,
                         -1 ) ;

         xPix := xPix + 14 ;
         DrawZoomButton( Canv,
                         xMid + (ButtonSize+1),
                         yMid,
                         12,
                         cZoomOutButton,
                         -1 ) ;

         xPix := xPix + 14 ;
         DrawZoomButton( Canv,
                         xMid + (ButtonSize+1)*2,
                         yMid,
                         12,
                         cZoomRightButton,
                         -1 ) ;

         end ;

     // Marker text
     for i := 0 to FMarkerText.Count-1 do begin
         x := Integer(FMarkerText.Objects[i]) ;
         xPix := XToCanvasCoord( Channel[LastActiveChannel], x ) ;
         yPix := Height - ((i Mod 2)+1)*Canv.TextHeight(FMarkerText.Strings[i]) ;
         Canv.TextOut( xPix, yPix, FMarkerText.Strings[i] );
         end ;

     end ;


procedure TMatrixDisplay.DisplayNewPoints(
          NewPoints : Integer
          ) ;
{ -----------------------------------------
  Plot a new block of A/D samples of display
  -----------------------------------------}
var
   i,j,ch : Integer ;
   StartAt,EndAt,XPix : Integer ;
   y : single ;
begin

     { Start plot lines at last point in buffer }
     StartAt := Max( FNumPoints - 2,0 ) ;
     { End plot at newest point }
     FNumPoints := NewPoints ;
     EndAt := FNumPoints-1 ;
     for ch := 0 to FNumChannels-1 do
         if Channel[ch].InUse and (FBuf <> Nil) then begin
         Canvas.Pen.Color := Channel[ch].Color ;
         j := (StartAt*FNumChannels) + Channel[ch].ADCOffset ;
         if FNumBytesPerSample > 2 then y := PIntArray(FBuf)^[j]
                                   else y := PSmallIntArray(FBuf)^[j] ;

         XPix := Max( XToCanvasCoord( Channel[ch], StartAt ), Channel[ch].Left ) ;
         Canvas.MoveTo( XPix,YToCanvasCoord( Channel[ch], y) ) ;

         for i := StartAt to EndAt do begin
             j := (i*FNumChannels) + Channel[ch].ADCOffset ;
             if FNumBytesPerSample > 2 then y := PIntArray(FBuf)^[j]
                                       else y := PSmallIntArray(FBuf)^[j] ;
             XPix := XToCanvasCoord( Channel[ch], i ) ;
             if (XPix >= Channel[ch].Left) and (XPix <= Channel[ch].Right) then begin
                Canvas.LineTo( XPix, YToCanvasCoord( Channel[ch], y) ) ;
                end ;
            end ;
         end ;

     ResizeZoomBox( ZoomRect.Right, ZoomRect.Bottom ) ;

     // Draw link between selected pair of vertical cursors
     DrawVerticalCursorLink(Canvas) ;

     { Vertical Cursors }
     for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
         DrawVerticalCursor(Canvas,i) ;

     end ;


procedure TMatrixDisplay.AddMarker (
          AtPoint : Integer ;       // Marker display point
          Text : String             // Marker text
                    ) ;
// ------------------------------------
// Add marker text at bottom of display
// ------------------------------------
begin

    FMarkerText.AddObject( Text, TObject(AtPoint) ) ;
    Invalidate ;
    end ;


procedure TMatrixDisplay.ClearMarkers ;
// ----------------------
// Clear marker text list
// ----------------------
begin
     FMarkerText.Clear ;
     Invalidate ;
     end ;


procedure TMatrixDisplay.ClearHorizontalCursors ;
{ -----------------------------
  Remove all horizontal cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(HorCursors) do HorCursors[i].InUse := False ;
     end ;


function TMatrixDisplay.AddHorizontalCursor(
         iChannel : Integer ;       { Signal channel associated with cursor }
         Color : TColor ;           { Colour of cursor }
         UseAsZeroLevel : Boolean ;  { If TRUE indicates this is a zero level cursor }
         CursorText : String       // Cursor label text
         ) : Integer ;
{ --------------------------------------------
  Add a new horizontal cursor to the display
  -------------------------------------------}
var
   iCursor : Integer ;
begin
     { Find an unused cursor }
     iCursor := 0 ;
     while HorCursors[iCursor].InUse
           and (iCursor < High(HorCursors)) do Inc(iCursor) ;

    { Attach the cursor to a channel }
    if iCursor <= High(HorCursors) then begin
       HorCursors[iCursor] := Channel[iChannel] ;
       HorCursors[iCursor].Position := 0 ;
       HorCursors[iCursor].InUse := True ;
       HorCursors[iCursor].Color := Color ;
       HorCursors[iCursor].ChanNum := iChannel ;
       HorCursors[iCursor].ZeroLevel := UseAsZeroLevel ;
       HorCursors[iCursor].ADCName := CursorText ;
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;


procedure TMatrixDisplay.DrawHorizontalCursor(
          Canv : TCanvas ;
          iCurs : Integer
          ) ;
{ -----------------------
  Draw horizontal cursor
 ------------------------}
var
   yPix : Integer ;
   OldPen : TPen ;
begin

     // Skip plot if cursor not within displayed area
     if (HorCursors[iCurs].Position < HorCursors[iCurs].yMin) or
        (HorCursors[iCurs].Position > HorCursors[iCurs].yMax) then Exit ;

     // Skip if channel disabled
     if not Channel[HorCursors[iCurs].ChanNum].InUse then Exit ;

     // Save pen settings
     OldPen := TPen.Create ;
     OldPen.Assign(Canv.Pen) ;

     // Settings for cursor
     Canv.Pen.Style := psDashDotDot ;
     Canv.Pen.Mode := pmMASK ;

     // If fixed zero levels flag set, set channel zero level to 0
     if FFixZeroLevels and HorCursors[iCurs].ZeroLevel then begin
        HorCursors[iCurs].Position := 0 ;
        end ;

     // Set line colour
     // (Note. If this cursor is being used as a zero level
     //  use a different colour when cursors is not at true zero)
     if HorCursors[iCurs].ZeroLevel and (HorCursors[iCurs].Position = 0) then
        Canv.Pen.Color := FZeroHorizontalCursorColor
     else Canv.Pen.Color := FNonZeroHorizontalCursorColor ;

     // Draw line
     yPix := YToCanvasCoord( HorCursors[iCurs],
                             HorCursors[iCurs].Position ) ;
     Canv.polyline( [Point(HorCursors[iCurs].Left,yPix),
                     Point(HorCursors[iCurs].Right,yPix)]);

     { If this cursor is being used as the zero baseline level for a signal
       channel, update the zero level for that channel }
     if (HorCursors[iCurs].ZeroLevel) then
        Channel[HorCursors[iCurs].ChanNum].ADCZero := HorCursors[iCurs].Position ;

     // Plot cursor label
     if HorCursors[iCurs].ADCName <> '' then begin
        Canv.TextOut( HorCursors[iCurs].Right
                      - Canv.TextWidth(HorCursors[iCurs].ADCName)-2,
                      yPix - (Canv.TextHeight(HorCursors[iCurs].ADCName) div 2) - 1,
                      HorCursors[iCurs].ADCName) ;
        end ;

     // Restore pen colour
     Canv.Pen.Assign(OldPen)  ;
     OldPen.Free ;

    end ;


procedure TMatrixDisplay.ClearVerticalCursors ;
{ -----------------------------
  Remove all vertical cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     FNumVerticalCursorLinks := 0 ;
     end ;


function TMatrixDisplay.AddVerticalCursor(
         Chan : Integer ;                { Signal channel (-1=all channels) }
         Color : TColor ;                 { Cursor colour }
         CursorText : String             // Text label at bottom of cursor
         ) : Integer ;
{ --------------------------------------------
  Add a new vertical cursor to the display
  -------------------------------------------}
var
   iCursor : Integer ;
begin
     { Find an unused cursor }
     iCursor := 0 ;
     while VertCursors[iCursor].InUse
           and (iCursor < High(VertCursors)) do Inc(iCursor) ;

    { Attach the cursor to a channel }
    if iCursor <= High(VertCursors) then begin
       VertCursors[iCursor] := Channel[0] ;
       VertCursors[iCursor].ChanNum := Chan ;
       VertCursors[iCursor].Position := FNumPoints div 2 ;
       VertCursors[iCursor].InUse := True ;
       VertCursors[iCursor].Color := Color ;
       VertCursors[iCursor].ADCName := CursorText ;
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;


procedure TMatrixDisplay.DrawVerticalCursor(
          Canv : TCanvas ;
          iCurs : Integer
          ) ;
{ -----------------------
  Draw vertical cursor
 ------------------------}
var
   j,ch,xPix,StartCh,EndCh,TChan : Integer ;
   OldFontColor : TColor ;
   y,yz : single ;
   s : string ;
   SavedPen : TPenRecall ;
   ChannelsAvailable : Boolean ;
begin

     // Skip if off the display
     if (VertCursors[iCurs].Position < Max(Channel[0].XMin,0)) or
        (VertCursors[iCurs].Position >= Min(Channel[0].XMax,FMaxPoints)) then Exit ;

     // Skip if channel disabled
     ChannelsAvailable := False ;
     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
         ChannelsAvailable := True ;
         Break ;
         end ;
     if not ChannelsAvailable then Exit ;

     if VertCursors[iCurs].ChanNum >= 0 then begin
        if not Channel[VertCursors[iCurs].ChanNum].InUse then Exit ;
        end ;

     SavedPen := TPenRecall.Create( Canv.Pen ) ;
     // Set pen to cursor colour (saving old)
     OldFontColor := Canv.Font.Color ;
     Canv.Pen.Color := VertCursors[iCurs].Color ;
     Canv.Font.Color := VertCursors[iCurs].Color ;
     Canv.Font.Size := FFontSize ;

     // Plot cursor line
     xPix := XToCanvasCoord( VertCursors[iCurs], VertCursors[iCurs].Position ) ;
     Canv.polyline( [Point(xPix,VertCursors[iCurs].Top),
                     Point(xPix,VertCursors[iCurs].Bottom)] );

     // Plot cursor label

     // Display signal value at cursor
     if VertCursors[iCurs].ChanNum < 0 then begin
        StartCh := 0 ;
        EndCh := FNumChannels-1 ;
        end
     else begin
       StartCh := VertCursors[iCurs].ChanNum ;
       EndCh := VertCursors[iCurs].ChanNum ;
       end ;

     // Select channel to be used to display time
     TChan := 0 ;
     for ch := StartCh to EndCh do if Channel[ch].InUse then TChan := ch ;

     for ch := StartCh to EndCh do if Channel[ch].InUse then begin
         // Get cursor name
         s := VertCursors[iCurs].ADCName ;

         // Cursor signal level reading
         j := (VertCursors[iCurs].Position*FNumChannels) + Channel[ch].ADCOffset ;
         if (j >= 0) and (j < (FMaxPoints*FNumChannels)) and (FBuf <> Nil) then begin
            if FNumBytesPerSample > 2 then y := PIntArray(FBuf)^[j]
                                      else y := PSmallIntArray(FBuf)^[j] ;
            end
         else y := 0 ;

         // Display time

         if ANSIContainsText(VertCursors[iCurs].ADCName,'?t0') and (ch = TChan) then begin
            // Display time relative to cursor 0
            s := s + format('t=%6.5g, ',[(VertCursors[iCurs].Position
                                        - VertCursors[0].Position)*FTScale]) ;
            end
         else if ANSIContainsText(VertCursors[iCurs].ADCName,'?t') and (ch = TChan) then begin
            // Display time relative to start of record
            s := s + format('t=%6.5g, ',[(VertCursors[iCurs].Position + FXOffset)*FTScale]) ;
            end ;

         // Display sample index
         if ANSIContainsText(VertCursors[iCurs].ADCName,'?i') then begin
            s := s + format('i=%d, ',[VertCursors[iCurs].Position]) ;
            end ;

         // Display signal level
         if ANSIContainsText(VertCursors[iCurs].ADCName,'?y0') then begin
            // Display signal level (relative to cursor 0)
            j := (VertCursors[0].Position*FNumChannels) + Channel[ch].ADCOffset ;
            if (j >= 0) and (j < (FMaxPoints*FNumChannels)) and (FBuf <> Nil) then begin
               if FNumBytesPerSample > 2 then yz := PIntArray(FBuf)^[j]
                                         else yz := PSmallIntArray(FBuf)^[j] ;
               end
            else yz := 0 ;
            s := s + format('%6.5g %s',[(y-yz)*Channel[ch].ADCScale,Channel[ch].ADCUnits]) ;
            end
         else if ANSIContainsText(VertCursors[iCurs].ADCName,'?y') then begin
            // Display signal level (relative to baseline)
              yz := Channel[ch].ADCZero ;
              s := s + format('%6.5g %s',[(y-yz)*Channel[ch].ADCScale,Channel[ch].ADCUnits]) ;
              end ;

         // Remove query text
         s := AnsiReplaceText(s,'?t0','') ;
         s := AnsiReplaceText(s,'?t','') ;
         s := AnsiReplaceText(s,'?r','') ;
         s := AnsiReplaceText(s,'?i','') ;
         s := AnsiReplaceText(s,'?y0','') ;
         s := AnsiReplaceText(s,'?y','') ;

         if s <> '' then Canv.TextOut( xPix - Canv.TextWidth(s) div 2,Channel[ch].Bottom + 1,s) ;

         end ;

     // Restore pen colour
     SavedPen.Free ;
     Canv.Font.Color := OldFontColor ;

     end ;


procedure TMatrixDisplay.DrawVerticalCursorLink(
          Canv : TCanvas
          ) ;
{ ---------------------------------------------
  Draw horizontal link between vertical cursors
 ----------------------------------------------}
var
   i,ch : Integer ;
   iCurs0,iCurs1 : Integer ;
   xPix0,xPix1,yPix : Integer ;
   SavedPen : TPenRecall ;
   ChannelsAvailable : Boolean ;
begin

     // Skip if all channels disabled
     ChannelsAvailable := False ;
     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
         ChannelsAvailable := True ;
         Break ;
         end ;
     if not ChannelsAvailable then Exit ;

     SavedPen := TPenRecall.Create( Canv.Pen ) ;

     for i := 0 to FNumVerticalCursorLinks-1 do begin

         iCurs0 := FLinkVerticalCursors[2*i] ;
         iCurs1 := FLinkVerticalCursors[(2*i)+1] ;

         if VertCursors[iCurs0].InUse and
            VertCursors[iCurs1].InUse and
            Channel[VertCursors[iCurs0].ChanNum].InUse then begin ;

            // Set pen to cursor colour (saving old)
            Canv.Pen.Color := VertCursors[iCurs0].Color ;

            // Y location of line
            yPix := VertCursors[iCurs0].Bottom + (Canv.TextHeight('X') div 2) ;

            // Plot left cursor end
            xPix0 := XToCanvasCoord( VertCursors[iCurs0], VertCursors[iCurs0].Position ) ;
            if VertCursors[iCurs0].ADCName <> '' then begin
               xPix0 := xPix0 + (Canv.TextWidth(VertCursors[iCurs0].ADCName) div 2) + 2 ;
               end
            else begin
               Canv.polyline( [Point(xPix0,yPix-3),Point(xPix0,yPix+3)] );
               end ;

            // Plot right cursor end
            xPix1 := XToCanvasCoord( VertCursors[iCurs1], VertCursors[iCurs1].Position ) ;
            if VertCursors[iCurs1].ADCName <> '' then begin
               xPix1 := xPix1 - (Canv.TextWidth(VertCursors[iCurs0].ADCName) div 2) - 2 ;
               end
            else begin
               Canv.polyline( [Point(xPix1,yPix-3),Point(xPix1,yPix+3)] );
               end ;

            // Plot horizontal lne
            Canv.polyline( [Point(xPix0,yPix),Point(xPix1,yPix)] );

            end ;
         end ;

     SavedPen.Free ;

     end ;



{ ==========================================================
  PROPERTY READ / WRITE METHODS
  ==========================================================}


procedure TMatrixDisplay.SetNumChannels(
          Value : Integer
          ) ;
{ ------------------------------------------
  Set the number of channels to be displayed
  ------------------------------------------ }
begin
     FNumChannels := IntLimitTo(Value,1,High(Channel)+1) ;
     FNumRows := Max(FNumChannels div FNumColumns,1) ;
     end ;


procedure TMatrixDisplay.SetNumColumns(
          Value : Integer
          ) ;
{ ------------------------------------------
  Set the number of columns to be displayed
  ------------------------------------------ }
begin
     FNumColumns := IntLimitTo(Value,1,MaxColumns) ;
     FNumRows := Max(FNumChannels div FNumColumns,1) ;
     end ;


procedure TMatrixDisplay.SetNumPoints(
          Value : Integer
          ) ;
{ ------------------------------------
  Set the number of points per channel
  ------------------------------------ }
begin
     FNumPoints := IntLimitTo(Value,0,High(TSmallIntArray)) ;
     end ;


procedure TMatrixDisplay.SetMaxPoints(
          Value : Integer
          ) ;
{ --------------------------------------------
  Set the maximum number of points per channel
  ------------------------------------------- }
begin
     FMaxPoints := IntLimitTo(Value,1,High(TSmallIntArray)) ;
     end ;


 procedure TMatrixDisplay.SetXMin(
          Value : Integer
          ) ;
{ ----------------------
  Set the X axis minimum
  ---------------------- }
var
   ch : Integer ;
begin
     FXMin := Min(Value,FMaxPoints-1) ;
     if FXMax = FXMin then FXMax := FXMin + 1 ;
     for ch := 0 to High(Channel) do Channel[ch].XMin := FXMin ;
     end ;


 procedure TMatrixDisplay.SetXMax(
          Value : Integer
          ) ;
{ ----------------------
  Set the X axis maximum
  ---------------------- }
var
   ch : Integer ;
begin
     FXMax := Min(Value,FMaxPoints-1) ;
     if FXMax = FXMin then FXMax := FXMin + 1 ;
     for ch := 0 to High(Channel) do Channel[ch].XMax := FXMax ;
     end ;


procedure TMatrixDisplay.SetYMin(
          Value : single
          ) ;
{ -------------------------
  Set the channel Y minimum
  ------------------------- }
var
    ch : Integer ;
begin
     for ch := 0 to ScopeChannelLimit do begin
         Channel[Ch].YMin := Max(Value,FMinADCValue) ;
         if Channel[Ch].YMin = Channel[Ch].YMax then
            Channel[Ch].YMax := Channel[Ch].YMin + 1.0 ;
         end ;
     end ;


procedure TMatrixDisplay.SetYMax(
          Value : single
          ) ;
{ -------------------------
  Set the channel Y maximum
  ------------------------- }
var
    ch : Integer ;
begin
     for ch := 0 to ScopeChannelLimit do begin
         Channel[Ch].YMax := Max(Value,FMinADCValue) ;
         if Channel[Ch].YMin = Channel[Ch].YMax then
            Channel[Ch].YMax := Channel[Ch].YMin + 1.0 ;
         end ;
     end ;


procedure TMatrixDisplay.SetYSize(
          Ch : Integer ;
          Value : single
          ) ;
{ -------------------------
  Set the channel Y axis relative size
  ------------------------- }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].YSize := Value ;
     end ;


function TMatrixDisplay.GetYMin(
          ) : single ;
{ -------------------------
  Get the channel Y minimum
  ------------------------- }
begin
     Result := Channel[0].YMin ;
     end ;


function TMatrixDisplay.GetYMax(
          ) : single ;
{ -------------------------
  Get the channel Y maximum
  ------------------------- }
begin
     Result := Channel[0].YMax ;
     end ;


function TMatrixDisplay.GetYSize(
         Ch : Integer
          ) : single ;
{ -------------------------
  Get the channel Y axis relative size
  ------------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].YSize ;
     end ;


procedure TMatrixDisplay.SetChanName(
          Ch : Integer ;
          Value : string
          ) ;
{ ------------------
  Set a channel name
  ------------------ }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].ADCName := Value ;
     end ;


function TMatrixDisplay.GetChanName(
          Ch : Integer
          ) : string ;
{ ------------------
  Get a channel name
  ------------------ }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].ADCName ;
     end ;


procedure TMatrixDisplay.SetChanUnits(
          Ch : Integer ;
          Value : string
          ) ;
{ ------------------
  Set a channel units
  ------------------ }

begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].ADCUnits := Value ;
     end ;


function TMatrixDisplay.GetChanUnits(
          Ch : Integer
          ) : string ;
{ ------------------
  Get a channel units
  ------------------ }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].ADCUnits ;
     end ;


procedure TMatrixDisplay.SetChanScale(
          Ch : Integer ;
          Value : single
          ) ;
{ ------------------------------------------------
  Set a channel A/D -> physical units scale factor
  ------------------------------------------------ }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].ADCScale := Value ;
     end ;


function TMatrixDisplay.GetChanScale(
          Ch : Integer
          ) : single ;
{ --------------------------------------------------
  Get a channel A/D -> physical units scaling factor
  -------------------------------------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].ADCScale ;
     end ;


procedure TMatrixDisplay.SetChanCalBar(
          Ch : Integer ;
          Value : single
          ) ;
{ -----------------------------
  Set a channel calibration bar
  ----------------------------- }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].CalBar := Value ;
     end ;


function TMatrixDisplay.GetChanCalBar(
          Ch : Integer
          ) : single ;
{ -----------------------------------
  Get a channel calibration bar value
  ----------------------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].CalBar ;
     end ;


procedure TMatrixDisplay.SetChanOffset(
          Ch : Integer ;
          Value : Integer
          ) ;
{ ---------------------------------------------
  Get data interleaving offset for this channel
  ---------------------------------------------}
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].ADCOffset := Value ;
     end ;


function TMatrixDisplay.GetChanOffset(
          Ch : Integer
          ) : Integer ;
{ ---------------------------------------------
  Get data interleaving offset for this channel
  ---------------------------------------------}
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].ADCOffset ;
     end ;


procedure TMatrixDisplay.SetChanZero(
          Ch : Integer ;
          Value : Integer
          ) ;
{ ------------------------
  Set a channel zero level
  ------------------------ }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].ADCZero := Value ;
     end ;


function TMatrixDisplay.GetChanZero(
          Ch : Integer
          ) : Integer ;
{ ----------------------------
  Get a channel A/D zero level
  ---------------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].ADCZero ;
     end ;


procedure TMatrixDisplay.SetChanZeroAt(
          Ch : Integer ;
          Value : Integer
          ) ;
{ ------------------------
  Set a channel zero level
  ------------------------ }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].ADCZeroAt := Value ;
     end ;


function TMatrixDisplay.GetChanZeroAt(
          Ch : Integer
          ) : Integer ;
{ ----------------------------
  Get a channel A/D zero level
  ---------------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].ADCZeroAt ;
     end ;


procedure TMatrixDisplay.SetChanZeroAvg(
          Value : Integer
          ) ;
{ ------------------------------------------------------------
  Set no. of points to average to get From Record channel zero
  ------------------------------------------------------------ }
begin
     FChanZeroAvg := IntLimitTo(Value,1,FNumPoints) ;
     end ;


procedure TMatrixDisplay.SetChanVisible(
          Ch : Integer ;
          Value : boolean
          ) ;
{ ----------------------
  Set channel visibility
  ---------------------- }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].InUse := Value ;
     end ;


function TMatrixDisplay.GetChanVisible(
          Ch : Integer
          ) : boolean ;
{ ----------------------
  Get channel visibility
  ---------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].InUse ;
     end ;


procedure TMatrixDisplay.SetChanColor(
          Ch : Integer ;
          Value : TColor
          ) ;
{ ----------------------
  Set channel colour
  ---------------------- }
begin
     if (ch < 0) or (ch > ScopeChannelLimit) then Exit ;
     Channel[Ch].Color := Value ;
     end ;


function TMatrixDisplay.GetChanColor(
          Ch : Integer
          ) : TColor ;
{ ----------------------
  Get channel colour
  ---------------------- }
begin
     Ch := IntLimitTo(Ch,0,ScopeChannelLimit) ;
     Result := Channel[Ch].Color ;
     end ;


function TMatrixDisplay.GetHorCursor(
         iCursor : Integer
         ) : Integer ;
{ ---------------------------------
  Get position of horizontal cursor
  ---------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(HorCursors)) ;
     if HorCursors[iCursor].InUse then Result := HorCursors[iCursor].Position
                                   else Result := -1 ;
     end ;


procedure TMatrixDisplay.SetHorCursor(
          iCursor : Integer ;           { Cursor # }
          Value : Integer               { New Cursor position }
          )  ;
{ ---------------------------------
  Set position of horizontal cursor
  ---------------------------------}
begin

     iCursor := IntLimitTo(iCursor,0,High(HorCursors)) ;
     HorCursors[iCursor].Position := Value ;

     { If this cursor is being used as the zero baseline level for a signal
       channel, update the zero level for that channel }
     if (HorCursors[iCursor].ZeroLevel) then
        Channel[HorCursors[iCursor].ChanNum].ADCZero := HorCursors[iCursor].Position ;

     Invalidate ;
     end ;


function TMatrixDisplay.GetVertCursor(
         iCursor : Integer
         ) : Integer ;
{ -------------------------------
  Get position of vertical cursor
  -------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(VertCursors)) ;
     if VertCursors[iCursor].InUse then Result := VertCursors[iCursor].Position
                                   else Result := -1 ;
     end ;


procedure TMatrixDisplay.SetVertCursor(
          iCursor : Integer ;           { Cursor # }
          Value : Integer               { New Cursor position }
          )  ;
{ -------------------------------
  Set position of Vertical cursor
  -------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(VertCursors)) ;
     VertCursors[iCursor].Position := Value ;
     Invalidate ;
     end ;


function TMatrixDisplay.GetXScreenCoord(
         Value : Integer               { Index into display data array (IN) }
         ) : Integer ;
{ --------------------------------------------------------------------------
  Get the screen coordinate within the paint box from the data array index
  -------------------------------------------------------------------------- }
begin
     Result := XToScreenCoord( 0, Value ) ;
     end ;


procedure TMatrixDisplay.SetPrinterFontName(
          Value : string
          ) ;
{ -----------------------
  Set printer font name
  ----------------------- }
begin
     FPrinterFontName := Value ;
     end ;


function TMatrixDisplay.GetPrinterFontName : string ;
{ -----------------------
  Get printer font name
  ----------------------- }
begin
     Result := FPrinterFontName ;
     end ;


procedure TMatrixDisplay.SetPrinterLeftMargin(
          Value : Integer                    { Left margin (mm) }
          ) ;
{ -----------------------
  Set printer left margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     if Printer.Printers.Count > 0 then begin
        FPrinterLeftMargin := (Printer.PageWidth*Value)
                              div GetDeviceCaps( printer.handle, HORZSIZE ) ;
        end
     else FPrinterLeftMargin := 0 ;
     end ;


function TMatrixDisplay.GetPrinterLeftMargin : integer ;
{ ----------------------------------------
  Get printer left margin (returned in mm)
  ---------------------------------------- }
begin
     if Printer.Printers.Count > 0 then begin
        Result := (FPrinterLeftMargin*GetDeviceCaps(Printer.Handle,HORZSIZE))
                     div Printer.PageWidth ;
        end
     else Result := 0 ;
     end ;


procedure TMatrixDisplay.SetPrinterRightMargin(
          Value : Integer                    { Right margin (mm) }
          ) ;
{ -----------------------
  Set printer Right margin
  ----------------------- }
begin
     { Printe
     r pixel height (mm) }
     if Printer.Printers.Count > 0 then begin
        FPrinterRightMargin := (Printer.PageWidth*Value)
                                div GetDeviceCaps( printer.handle, HORZSIZE ) ;
        end
     else FPrinterRightMargin := 0 ;
     end ;


function TMatrixDisplay.GetPrinterRightMargin : integer ;
{ ----------------------------------------
  Get printer Right margin (returned in mm)
  ---------------------------------------- }
begin
    if Printer.Printers.Count > 0 then begin
       Result := (FPrinterRightMargin*GetDeviceCaps(Printer.Handle,HORZSIZE))
                 div Printer.PageWidth ;
       end
    else Result := 0 ;
    end ;


procedure TMatrixDisplay.SetPrinterTopMargin(
          Value : Integer                    { Top margin (mm) }
          ) ;
{ -----------------------
  Set printer Top margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     if Printer.Printers.Count > 0 then begin
        FPrinterTopMargin := (Printer.PageHeight*Value)
                           div GetDeviceCaps( printer.handle, VERTSIZE ) ;
        end
     else FPrinterTopMargin := 0 ;
     end ;


function TMatrixDisplay.GetPrinterTopMargin : integer ;
{ ----------------------------------------
  Get printer Top margin (returned in mm)
  ---------------------------------------- }
begin
     if Printer.Printers.Count > 0 then begin
        Result := (FPrinterTopMargin*GetDeviceCaps(Printer.Handle,VERTSIZE))
                  div Printer.PageHeight ;
        end
     else Result := 0 ;
     end ;


procedure TMatrixDisplay.SetPrinterBottomMargin(
          Value : Integer                    { Bottom margin (mm) }
          ) ;
{ -----------------------
  Set printer Bottom margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     if Printer.Printers.Count > 0 then begin
        FPrinterBottomMargin := (Printer.PageHeight*Value)
                                div GetDeviceCaps( printer.handle, VERTSIZE ) ;
        end
     else FPrinterBottomMargin := 0 ;
     end ;


function TMatrixDisplay.GetPrinterBottomMargin : integer ;
{ ----------------------------------------
  Get printer Bottom margin (returned in mm)
  ---------------------------------------- }
begin
     if Printer.Printers.Count > 0 then begin
        Result := (FPrinterBottomMargin*GetDeviceCaps(Printer.Handle,VERTSIZE))
                  div Printer.PageHeight ;
        end
     else Result := 0 ;
     end ;


procedure TMatrixDisplay.SetStorageMode(
          Value : Boolean                    { True=storage mode on }
          ) ;
{ ------------------------------------------------------
  Set display storage mode
  (in store mode records are superimposed on the screen
  ------------------------------------------------------ }
var
   i : Integer ;
begin
     FStorageMode := Value ;
     { Clear out list of stored records }
     for i := 0 to High(FStorageList) do FStorageList[i] := NoRecord ;
     Invalidate ;
     end ;


procedure TMatrixDisplay.SetGrid(
          Value : Boolean                    { True=storage mode on }
          ) ;
{ ---------------------------
  Enable/disable display grid
  --------------------------- }
begin
     FDrawGrid := Value ;
     Invalidate ;
     end ;


function TMatrixDisplay.GetNumVerticalCursors : Integer ;
// ---------------------------------------------------
// Get number of vertical cursors defined in displayed
// ---------------------------------------------------
var
    i,NumCursors : Integer ;
begin
    NumCursors := 0 ;
    for i := 0 to High(VertCursors) do if
        VertCursors[i].InUse then Inc(NumCursors) ;
    Result := NumCursors ;
    end ;


function TMatrixDisplay.GetNumHorizontalCursors : Integer ;
// ---------------------------------------------------
// Get number of horizontal cursors defined in displayed
// ---------------------------------------------------
var
    i,NumCursors : Integer ;
begin
    NumCursors := 0 ;
    for i := 0 to High(HorCursors) do if
        HorCursors[i].InUse then Inc(NumCursors) ;
    Result := NumCursors ;
    end ;


procedure TMatrixDisplay.SetFixZeroLevels( Value : Boolean ) ;
// -------------------------
// Set fixed zero level flag
// -------------------------
begin
     FFixZeroLevels := Value ;
     Invalidate ;
     end ;


{ =======================================================
  INTERNAL EVENT HANDLING METHODS
  ======================================================= }

procedure TMatrixDisplay.MouseDown(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;
{ --------------------
  Mouse button is down
  -------------------- }
var
    OldCopyMode : TCopyMode ;
    ch : Integer ;
begin
     Inherited MouseDown( Button, Shift, X, Y ) ;

     FMouseDown := True ;

     if FHorCursorSelected > -1  then FHorCursorActive := True ;

     if (not FHorCursorActive)
        and (FVertCursorSelected > -1) then FVertCursorActive := True ;

     if ZoomRectCount > 1 then begin
        OldCopyMode := Canvas.CopyMode ;
        Canvas.CopyMode := cmNotSrcCopy	;
        Canvas.CopyRect( ZoomRect, Canvas, ZoomRect ) ;
        Canvas.CopyMode := OldCopyMode ;
        end ;

     { Find and store channel mouse is over }
     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
         if (Channel[ch].Top <= Y) and (Y <= Channel[ch].Bottom) then
            ZoomChannel := ch ;
         end ;
     ZoomChannel := Min(Max(0,ZoomChannel),FNumChannels-1) ;

     ZoomRect.Left := Min(Max(X,Channel[ZoomChannel].Left),Channel[ZoomChannel].Right) ;
     ZoomRect.Top := Min(Max(Y,Channel[ZoomChannel].Top),Channel[ZoomChannel].Bottom) ;
     ZoomRect.Bottom := ZoomRect.Top ;
     ZoomRect.Right := ZoomRect.Left ;
     ZoomRectCount := 1 ;

     // If mouse is between channels, record upper channel
     FBetweenChannel := -1 ;
     for ch := 0 to FNumChannels-2 do if Channel[ch].InUse then begin
         if (X < Channel[ch].Left) and
            (Y > Channel[ch].Bottom) and
            (Y < Channel[ch+1].Top) then FBetweenChannel := ch ;
         end ;

     // Save mouse position
     MouseX := X ;
     MouseY := Y ;

     // If mouse over zoom button, change its colour
     ShowSelectedZoomButton ;

     end ;


procedure TMatrixDisplay.MouseUp(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;
{ --------------------
  Mouse button is up
  -------------------- }
begin
     Inherited MouseUp( Button, Shift, X, Y ) ;

     FHorCursorActive := false ;
     FVertCursorActive := false ;

     // Save mouse position
     MouseX := X ;
     MouseY := Y ;

     // Update display magnification from zoom box
     ProcessZoomBox ;

     // Update space occupied by channel
     UpdateChannelYSize( X, Y ) ;

     Invalidate ;

     FMouseDown := False ;

     end ;

procedure TMatrixDisplay.UpdateChannelYSize(
          X : Integer ;
          Y : Integer
          ) ;
// -----------------------------------------------
// Change proportion of Y axis occupied by channel
// -----------------------------------------------
var
    ch,ChannelSpacing : Integer ;
begin

     if FBetweenChannel < 0 then Exit ;

     ChannelSpacing :=  Canvas.TextHeight('X') + 1  ;
     Channel[FBetweenChannel].Bottom := Max( Y + (ChannelSpacing div 2),
                                             Channel[FBetweenChannel].Top ) ;

     // Find next higher channel
     for ch := FBetweenChannel+1 to FNumChannels-1 do if Channel[ch].InUse then begin
        Channel[FBetweenChannel].Bottom := Min( Channel[FBetweenChannel].Bottom,
                                                Channel[ch].Bottom ) ;
         Channel[ch].Top := Channel[FBetweenChannel].Bottom + ChannelSpacing ;
         break ;
         end ;

    for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
         Channel[ch].YSize := Channel[ch].Bottom - Channel[ch].Top ;
         end ;

     { Notify a change in cursors }
     if Assigned(OnCursorChange) and
        (not FCursorChangeInProgress) then OnCursorChange(Self) ;

     end ;


procedure TMatrixDisplay.MouseMove(
          Shift: TShiftState;
          X, Y: Integer) ;
{ --------------------------------------------------------
  Select/deselect cursors as mouse is moved over display
  -------------------------------------------------------}
var
   i : Integer ;
   HorizontalChanged : Boolean ; // Horizontal cursor changed flag
   VerticalChanged : Boolean ;   // Vertical cursor changed flag
   BetweenChannels : Boolean ;
begin
     Inherited MouseMove( Shift, X, Y ) ;

     { Find and store channel mouse is over }
     BetweenChannels := False ;
{     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
         if (Channel[ch].Top <= Y) and (Y <= Channel[ch].Bottom) then FMouseOverChannel := ch ;
         if (X < Channel[ch].Left) and
            (Y > Channel[ch].Bottom) and
            (Y < Channel[ch+1].Top) then BetweenChannels := True ;
         end ;}


     if not FMouseDown then ZoomRectCount := 0 ;
     // Re-size display zoom box
     ResizeZoomBox( X, Y ) ;

     if FCursorsEnabled then begin

        { Find/move any active horizontal cursor }
        HorizontalChanged := ProcessHorizontalCursors( X, Y ) ;
        { Find/move any active vertical cursor }
        if not FHorCursorActive then VerticalChanged := ProcessVerticalCursors( X, Y )
                                else  VerticalChanged := False ;

        if (HorizontalChanged or VerticalChanged) then begin

           // Copy image from internal bitmap
           ForeBitmap.Canvas.CopyRect( DisplayRect,
                                       BackBitmap.Canvas,
                                       DisplayRect ) ;

           // Re-draw cursors
           for i := 0 to High(HorCursors) do if HorCursors[i].InUse
               and Channel[HorCursors[i].ChanNum].InUse then DrawHorizontalCursor(ForeBitmap.Canvas,i) ;

           // Draw link between selected pair of vertical cursors
           DrawVerticalCursorLink(ForeBitmap.Canvas) ;

           // Draw vertical cursors
           for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
               DrawVerticalCursor(ForeBitmap.Canvas,i) ;

          Canvas.CopyRect( DisplayRect,
                           ForeBitmap.Canvas,
                           DisplayRect) ;

           end ;

        { Set type of cursor icon }
        if FHorCursorSelected > -1 then Cursor := crSizeNS
        else if FVertCursorSelected > -1 then Cursor := crSizeWE
        else if BetweenChannels then Cursor := crVSplit
        else Cursor := crDefault ;

        end ;

     end ;


procedure TMatrixDisplay.DblClick ;
{ -------------------------------------------------
  Handle events activated by double mouse clicks
  -------------------------------------------------}
begin

     CheckZoomButtons ;

     end ;


procedure TMatrixDisplay.Click ;
{ ----------------------------------------
  Handle events activated by mouse clicks
  ----------------------------------------}
begin

     // Check state of display zoom buttons
     CheckZoomButtons ;

     end ;



procedure TMatrixDisplay.Invalidate ;
begin

     inherited Invalidate ;

     end ;


procedure TMatrixDisplay.ZoomIn(
          Chan : Integer
          ) ;
{ -----------------------------------------------------------
  Switch to zoom in/out mode on selected chan (External call)
  ----------------------------------------------------------- }
begin
     end ;


procedure TMatrixDisplay.XZoom( PercentChange : Single ) ;
// ----------------------------------------------------------
// Change horizontal display magnification for selected channel
// ----------------------------------------------------------
const
    XLoLimit = 16 ;
var
    XShift,XMid : Integer ;
begin

     XShift := Round(Abs(FXMax - FXMin)*Min(Max(PercentChange*0.01,-1.0),10.0)) div 2 ;
     FXMin := Min( Max( FXMin - XShift, 0 ), FMaxPoints - 1 ) ;
     FXMax := Min( Max( FXMax  + XShift, 0 ), FMaxPoints - 1 ) ;
     if Abs(FXMax - FXMin) < XLoLimit then begin
        XMid := Round((FXMax +FXMin)*0.5) ;
        FXMax := Min(XMid + (XLoLimit div 2),FMaxPoints - 1 ) ;
        FXMin := Max(XMid - (XLoLimit div 2),0) ;
        end ;

     end ;


procedure TMatrixDisplay.YZoom(
          Chan : Integer ;       // Selected channel (-1 = all channels)
          PercentChange : Single // % change (-100..10000%) (Negative values zoom in)
          ) ;
// ----------------------------------------------------------
// Change vertical display magnification for selected channel
// ----------------------------------------------------------
const
    YLoLimit = 16 ;
var
    ch : Integer ;
    YShift,YMid : Integer ;
begin

     if Chan >= FNumChannels then Exit ;

     YShift := Round( Abs(Channel[Chan].YMax - Channel[Chan].YMin)
                      *Min(Max(PercentChange*0.01,-1.0),10.0)) div 2 ;

     if Chan < 0 then begin
        // Zoom all channels
        for ch := 0 to FNumChannels-1 do begin
            Channel[ch].YMax := Max(Min(Channel[ch].YMax + YShift, FMaxADCValue),FMinADCValue) ;
            Channel[ch].YMin := Max(Min(Channel[ch].YMin - YShift, FMaxADCValue),FMinADCValue) ;
            if Abs(Channel[ch].YMax - Channel[ch].YMin) < YLoLimit then begin
               YMid := Round((Channel[ch].YMax + Channel[ch].YMin)*0.5) ;
               Channel[ch].YMax := YMid + (YLoLimit div 2) ;
               Channel[ch].YMin := YMid - (YLoLimit div 2) ;
               end ;
            end ;
        end
     else begin
        // Zoom selected channel
        Channel[Chan].YMax := Max(Min(Channel[Chan].YMax + YShift, FMaxADCValue),FMinADCValue) ;
        Channel[Chan].YMin := Max(Min(Channel[Chan].YMin - YShift, FMaxADCValue),FMinADCValue) ;
        if Abs(Channel[Chan].YMax - Channel[Chan].YMin) < YLoLimit then begin
           YMid := Round((Channel[Chan].YMax + Channel[Chan].YMin)*0.5) ;
           Channel[Chan].YMax := YMid + (YLoLimit div 2) ;
           Channel[Chan].YMin := YMid - (YLoLimit div 2) ;
           end ;
        end ;

     Self.Invalidate ;

     end ;


procedure TMatrixDisplay.ZoomOut ;
{ ---------------------------------
  Zoom out to minimum magnification
  ---------------------------------}
var
   ch : Integer ;
begin
     for ch := 0 to FNumChannels-1 do begin
         Channel[ch].yMin := FMinADCValue ;
         Channel[ch].yMax := FMaxADCValue ;
         FXMin := 0 ;
         FXMax := FMaxPoints - 1;
         Channel[ch].xMin := FXMin ;
         Channel[ch].xMax := FXMax ;
         end ;
     Invalidate ;
     end ;


function TMatrixDisplay.ProcessHorizontalCursors(
         X : Integer ;
         Y : Integer
         ) : Boolean ;                       // Returns TRUE if a cursor changed
{ ----------------------------------
  Find/move active horizontal cursor
  ----------------------------------}
const
     Margin = 4 ;
var
   YPosition,i : Integer ;
begin

     if FHorCursorActive and (FHorCursorSelected > -1) then begin
        { ** Move the currently activated cursor to a new position ** }
        { Keep within display limits }
        Y := IntLimitTo( Y,
                         HorCursors[FHorCursorSelected].Top,
                         HorCursors[FHorCursorSelected].Bottom ) ;
        HorCursors[FHorCursorSelected].Position := CanvasToYCoord(
                                                   HorCursors[FHorCursorSelected],Y) ;

        { Notify a change in cursors }
        if Assigned(OnCursorChange) and
           (not FCursorChangeInProgress) then OnCursorChange(Self) ;

        Result := True ;
        end
     else begin
        { Find the active horizontal cursor (if any) }
        FHorCursorSelected := -1 ;
        for i := 0 to High(HorCursors) do if HorCursors[i].InUse then begin
            YPosition := YToCanvasCoord(HorCursors[i],HorCursors[i].Position) ;
            if (Abs(Y - YPosition) <= Margin) and
               (X < Channel[0].Right) and
               (X > Channel[0].Left) then FHorCursorSelected := i ;
            end ;

        Result := False ;
        end ;

     end ;


function TMatrixDisplay.ProcessVerticalCursors(
         X : Integer ;                        // X mouse coord (IN)
         Y : Integer                          // Y mouse coord (IN)
         ) : Boolean ;                       // Returns TRUE is cursor changed
{ --------------------------------
  Find/move active vertical cursor
  --------------------------------}
const
     Margin = 4 ;
var
   XPosition,i : Integer ;
begin

     if FVertCursorActive and (FVertCursorSelected > -1) then begin
        { ** Move the currently activated cursor to a new position ** }
        { Keep within channel display area }
        X := IntLimitTo( X,
                         VertCursors[FVertCursorSelected].Left,
                         VertCursors[FVertCursorSelected].Right ) ;
        { Calculate new X value }
        VertCursors[FVertCursorSelected].Position := CanvasToXCoord(
                               VertCursors[FVertCursorSelected], X ) ;

        { Notify a change in cursors }
        if Assigned(OnCursorChange) and
           (not FCursorChangeInProgress) then OnCursorChange(Self) ;

        Result := True ;
        end
     else begin
        { ** Find the active vertical cursor (if any) ** }
        FVertCursorSelected := -1 ;
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse and
            (VertCursors[i].Bottom >= Y) and (Y >= VertCursors[i].Top) then begin
            XPosition := XToCanvasCoord( VertCursors[i], VertCursors[i].Position ) ;
            if Abs(X - XPosition) <= Margin then begin
               FVertCursorSelected := i ;
               FLastVertCursorSelected := FVertCursorSelected ;
               end ;
            end ;
        Result := False ;
        end ;
     end ;


procedure TMatrixDisplay.MoveActiveVerticalCursor( Step : Integer ) ;
{ ----------------------------------------------------------------
  Move the currently selected vertical cursor by "Step" increments
  ---------------------------------------------------------------- }
begin

    VertCursors[FLastVertCursorSelected].Position := IntLimitTo(
        VertCursors[FLastVertCursorSelected].Position + Step,FXMin,FXMax );

     { Notify a change in cursors }
     if Assigned(OnCursorChange) and
        (not FCursorChangeInProgress) then OnCursorChange(Self) ;

    Invalidate ;

    end ;


procedure TMatrixDisplay.LinkVerticalCursors(
          C0 : Integer ;                     // First cursor to link
          C1 : Integer                       // Second cursor to link
          ) ;
// -----------------------------------------------------
// Link a pair of cursors with line at bottom of display
// -----------------------------------------------------
begin


    if FNumVerticalCursorLinks > MaxVerticalCursorLinks then Exit ;
    if (C0 < 0) or (C0 > High(VertCursors)) then Exit ;
    if (C1 < 0) or (C1 > High(VertCursors)) then Exit ;
    if (not VertCursors[C0].InUse) or (not VertCursors[C1].InUse) then Exit ;

    FLinkVerticalCursors[2*FNumVerticalCursorLinks] := C0 ;
    FLinkVerticalCursors[2*FNumVerticalCursorLinks+1] := C1 ;
    Inc(FNumVerticalCursorLinks) ;

    end ;


function TMatrixDisplay.IntLimitTo(
         Value : Integer ;          { Value to be checked }
         Lo : Integer ;             { Lower limit }
         Hi : Integer               { Upper limit }
         ) : Integer ;              { Return limited value }
{ --------------------------------
  Limit Value to the range Lo - Hi
  --------------------------------}
begin
     if Value < Lo then Value := Lo ;
     if Value > Hi then Value := Hi ;
     Result := Value ;
     end ;


function TMatrixDisplay.XToCanvasCoord(
         var Chan : TScopeChannel ;
         Value : single
         ) : Integer  ;
var
   XScale : single ;
begin
        XScale := (Chan.Right - Chan.Left) / ( FXMax - FXMin ) ;
     Result := Round( (Value - FXMin)*XScale + Chan.Left ) ;
     end ;


function TMatrixDisplay.XToScreenCoord(
         Chan : Integer ;
         Value : single
         ) : Integer  ;
{ ------------------------------------------------------------------------
  Public function which allows pixel coord to be obtained for X axis coord
  ------------------------------------------------------------------------}
var
   XScale : single ;
begin
     XScale := (Channel[Chan].Right - Channel[Chan].Left) / ( FXMax - FXMin ) ;
     Result := Round( (Value - FXMin)*XScale + Channel[Chan].Left ) ;
     end ;


function TMatrixDisplay.ScreenCoordToX(
         Chan : Integer ;
         Value : Integer
         ) : Single  ;
{ ------------------------------------------------------------------------
  Public function which allows pixel coord to be obtained for X axis coord
  ------------------------------------------------------------------------}
var
   XScale : single ;
begin
     XScale := (Channel[Chan].Right - Channel[Chan].Left) / ( FXMax - FXMin ) ;
     Result := (Value - Channel[Chan].Left)/XSCale + FXMin ;
     end ;



function TMatrixDisplay.CanvasToXCoord(
         var Chan : TScopeChannel ;
         xPix : Integer
         ) : Integer  ;
var
   XScale : single ;
begin
     XScale := (Chan.Right - Chan.Left) / ( FXMax - FXMin ) ;
     Result := Round((xPix - Chan.Left)/XScale + FXMin) ;
     end ;


function TMatrixDisplay.YToCanvasCoord(
         var Chan : TScopeChannel ;
         Value : single
         ) : Integer  ;
begin
     Chan.yScale := (Chan.Bottom - Chan.Top)/(Chan.yMax - Chan.yMin ) ;
     Result := Round( Chan.Bottom - (Value - Chan.yMin)*Chan.yScale ) ;
     if Result > Chan.Bottom then Result := Chan.Bottom ;
     if Result < Chan.Top then Result := Chan.Top ;
     end ;


function TMatrixDisplay.YToScreenCoord(
         Chan : Integer ;
         Value : single
         ) : Integer  ;
{ ------------------------------------------------------------------------
  Public function which allows pixel coord to be obtained from Y axis coord
  ------------------------------------------------------------------------}

begin
     Channel[Chan].yScale := (Channel[Chan].Bottom - Channel[Chan].Top)/
                             (Channel[Chan].yMax - Channel[Chan].yMin ) ;
     Result := Round( Channel[Chan].Bottom
               - (Value - Channel[Chan].yMin)*Channel[Chan].yScale ) ;

     end ;


function TMatrixDisplay.ScreenCoordToY(
         Chan : Integer ;
         Value : Integer
         ) : single  ;
{ ------------------------------------------------------------------------
  Public function which allows pixel coord to be obtained from Y axis coord
  ------------------------------------------------------------------------}

begin
     Channel[Chan].yScale := (Channel[Chan].Bottom - Channel[Chan].Top)/
                             (Channel[Chan].yMax - Channel[Chan].yMin ) ;
     Result := (Channel[Chan].Bottom - Value)/Channel[Chan].yScale
               + Channel[Chan].yMin ;
     end ;



function TMatrixDisplay.CanvasToYCoord(
         var Chan : TScopeChannel ;
         yPix : Integer
         ) : Integer  ;
begin
     Chan.yScale := (Chan.Bottom - Chan.Top)/(Chan.yMax - Chan.yMin ) ;
     Result := Round( (Chan.Bottom - yPix)/Chan.yScale + Chan.yMin ) ;
     end ;

procedure TMatrixDisplay.SetDataBuf(
          Buf : Pointer ) ;
// ----------------------------------------------------
// Supply address of data buffer containing digitised signals
// to be displayed
// ----------------------------------------------------
begin
     FBuf := Buf ;
     //Invalidate ; Removed 5/12/01
     end ;


procedure TMatrixDisplay.CopyDataToClipBoard ;
{ ------------------------------------------------
  Copy the data points on display to the clipboard
  ------------------------------------------------}
var
   i,j,ch,BufSize,Line,NumLines : Integer ;
   t : single ;
   CopyBuf : PChar ;
   y : single ;
begin

     Screen.Cursor := crHourGlass ;

     // Open clipboard preventing others acceessing it
     Clipboard.Open ;

     // Determine size of and allocate string buffer
     // No. of lines in table
     NumLines := Max( FXMax - FXMin + 1, FLineCount ) ;
     BufSize := 1 ;
     if FLineCount > 0 then BufSize := BufSize + 2 ;
     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then BufSize := BufSize + 1 ;
     BufSize := BufSize*10*NumLines ;
     CopyBuf := StrAlloc( BufSize ) ;

     try

       // Write table of data to buffer

       StrCopy(CopyBuf,PChar('')) ;
       t := 0.0 ;
       for Line := 0 to NumLines-1 do begin
           i := Line + FXMin ;
           if ( FXMin <= i) and (i <= FXMax) then begin
              // Add data columns
              // Time
              StrCat(CopyBuf,PChar(format( '%.4g', [t] ))) ;
              // Channel sample values
              for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                  j := i*FNumChannels + Channel[ch].ADCOffset ;
                  if FNumBytesPerSample > 2 then y := PIntArray(FBuf)^[j]
                                            else y := PSmallIntArray(FBuf)^[j] ;
                  StrCat(CopyBuf,
                         PChar(Format(#9'%.4g',
                         [(y - Channel[ch].ADCZero)*Channel[ch].ADCScale] ))) ;
                  end ;
              end
           else begin
              // Add empty columns
              StrCat(CopyBuf,PChar(#9)) ;
              for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then StrCat(CopyBuf,PChar(#9)) ;
              end ;

           if FLineCount > 0 then begin
              if Line < FLineCount then begin
                 StrCat(CopyBuf,PChar(format( #9'%.4g'#9'%.4g',
                 [ FLine^[Line].x*FTScale,
                  (FLine^[Line].y - Channel[FLineChannel].ADCZero)*Channel[FLineChannel].ADCScale
                 ] ))) ;
                 end
              else begin
                 StrCat(CopyBuf,PChar(#9#9)) ;
                 end ;
              end ;

           // CR+LF at end of line
           StrCat(CopyBuf, PChar(#13#10)) ;

           t := t + FTScale ;

           end ;

       // Copy text accumulated in copy buffer to clipboard
       ClipBoard.SetTextBuf( CopyBuf ) ;

     finally
       // Free buffer
       StrDispose(CopyBuf) ;
       // Release clipboard
       Clipboard.Close ;
       Screen.Cursor := crDefault ;
       end ;

     end ;


procedure TMatrixDisplay.Print ;
{ ---------------------------------
  Copy signal on display to printer
  ---------------------------------}
var
   i,j,n,ch,LastCh,YPix,xPix,Rec,NumBytesPerRecord : Integer ;
   x,YTotal : single ;
   LeftMarginShift, TopMarginShift, XPos,YPos : Integer ;
   OK : Boolean ;
   ChannelHeight,cTop,NumInUse,AvailableHeight : Integer ;
   PrChan : Array[0..ScopeChannelLimit] of TScopeChannel ;
   xy : ^TPointArray ;
   Bar : TRect ;
   Lab : string ;
   DefaultPen : TPen ;
   TopSpaceNeeded : Integer ;
begin
     { Create plotting points array }
     New(xy) ;
     DefaultPen := TPen.Create ;
     Printer.BeginDoc ;
     Cursor := crHourglass ;

     try

        Printer.Canvas.Pen.Color := clBlack ;
        Printer.Canvas.font.Name := FPrinterFontName ;
        Printer.Canvas.font.size := FPrinterFontSize ;
        Printer.Canvas.Pen.Width := FPrinterPenWidth ;
        Printer.Canvas.Pen.Style := psSolid ;
        Printer.Canvas.Pen.Color := clBlack ;
        DefaultPen.Assign(Printer.Canvas.Pen) ;

        // Determine number of channels in use and the height
        TopSpaceNeeded := (3 + FTitle.Count)*Printer.Canvas.TextHeight('X') ;
        AvailableHeight := Printer.PageHeight
                           - FPrinterBottomMargin
                           - FPrinterTopMargin
                           - TopSpaceNeeded ;

        // Determine number of channels in use
        NumInUse := 0 ;
        YTotal := 0.0 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
            Inc(NumInUse) ;
            YTotal := YTotal + Channel[ch].YSize ;
            end ;
        if NumInUse < 1 then begin
           YTotal := 1.0 ;
           end ;

        { Make space at left margin for channel names/cal. bars }
        LeftMarginShift := 0 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
            Lab := Channel[ch].ADCName + ' ' ;
            if (LeftMarginShift < Printer.Canvas.TextWidth(Lab)) then
                LeftMarginShift := Printer.Canvas.TextWidth(Lab) ;
            Lab := format( ' %6.5g %s ', [Channel[ch].CalBar,Channel[ch].ADCUnits] ) ;
            if (LeftMarginShift < Printer.Canvas.TextWidth(Lab)) then
                LeftMarginShift := Printer.Canvas.TextWidth(Lab) ;
            end ;

        { Define display area for each channel in use }
        cTop := FPrinterTopMargin + TopSpaceNeeded ;
                ;
        for ch := 0 to FNumChannels-1 do begin
             PrChan[ch] := Channel[ch] ;
             if Channel[ch].InUse then begin
                if FPrinterDisableColor then PrChan[ch].Color := clBlack ;
                PrChan[ch].Left := FPrinterLeftMargin + LeftMarginShift ;
                PrChan[ch].Right := Printer.PageWidth - FPrinterRightMargin ;
                PrChan[ch].Top := cTop ;
                ChannelHeight := Round((Channel[ch].YSize/YTotal)*AvailableHeight) ;
                PrChan[ch].Bottom := PrChan[ch].Top + ChannelHeight ;
                PrChan[ch].xMin := FXMin ;
                PrChan[ch].xMax := FXMax ;
                PrChan[ch].xScale := (PrChan[ch].Right - PrChan[ch].Left) /
                                     (PrChan[ch].xMax - PrChan[ch].xMin ) ;
                PrChan[ch].yScale := (PrChan[ch].Bottom - PrChan[ch].Top) /
                                     (PrChan[ch].yMax - PrChan[ch].yMin ) ;
                cTop := cTop + ChannelHeight ;
                end ;
             end ;

        { Plot channel }
        for ch := 0 to FNumChannels-1 do
           if PrChan[ch].InUse and (FBuf <> Nil) and FPrinterShowLabels then begin
           { Display channel name(s) }
           Lab := PrChan[ch].ADCName + ' ' ;
           Printer.Canvas.TextOut( PrChan[ch].Left - Printer.Canvas.TextWidth(Lab),
                                   (PrChan[ch].Top + PrChan[ch].Bottom) div 2,
                                   Lab ) ;
           end ;

        { Plot record(s) on screen }

        if FStorageMode then begin
           { Display all records stored on screen }
           NumBytesPerRecord := FNumChannels*FNumPoints*2 ;
           Rec := 1 ;
           while (FStorageList[Rec] <> NoRecord)
                 and (Rec <= High(FStorageList)) do begin
                 { Read buffer }
                 FStorageFile.Seek( Rec*NumBytesPerRecord, soFromBeginning ) ;
                 FStorageFile.Read( FBuf^, NumBytesPerRecord ) ;
                 { Plot record on display }
                 PlotRecord( Printer.Canvas, PrChan, xy^ ) ;
                 Inc(Rec) ;
                 end ;
           end
        else begin
           { Single-record mode }
           PlotRecord( Printer.Canvas, PrChan, xy^ ) ;
           end ;


       { Plot external line on selected channel }
       if (FLine <> Nil) and (FLineCount > 1) then begin
           Printer.Canvas.Pen.Assign(FLinePen) ;
           Printer.Canvas.Pen.Width := FPrinterPenWidth ;
           for i := 0 to FLineCount-1 do begin
               xy^[i].x := XToCanvasCoord( PrChan[FLineChannel], FLine^[i].x ) ;
               xy^[i].y := YToCanvasCoord( PrChan[FLineChannel], FLine^[i].y ) ;
               end ;
           OK := Polyline( Printer.Canvas.Handle, xy^, FLineCount ) ;
           Printer.Canvas.Pen.Assign(DefaultPen) ;
           end ;

       { Draw baseline levels }
       if FPrinterShowZeroLevels then begin
          Printer.Canvas.Pen.Style := psDot ;
          Printer.Canvas.Pen.Width := 1 ;
          for ch := 0 to FNumChannels-1 do if PrChan[ch].InUse then begin
              YPix := YToCanvasCoord( PrChan[ch], PrChan[ch].ADCZero ) ;
              Printer.Canvas.MoveTo( PrChan[ch].Left,  YPix ) ;
              Printer.Canvas.LineTo( PrChan[ch].Right, YPix ) ;
              end ;
          end ;

       { Restore pen to black and solid for cal. bars }
       Printer.Canvas.Pen.Assign(DefaultPen) ;

       if FPrinterShowLabels then begin
          { Draw vertical calibration bars }
          for ch := 0 to FNumChannels-1 do
              if PrChan[ch].InUse and (PrChan[ch].CalBar <> 0.0) then begin
              { Bar label }
              Lab := format( '%6.5g %s ', [PrChan[ch].CalBar,PrChan[ch].ADCUnits] ) ;
              { Calculate position/size of bar }
              Bar.Left := PrChan[ch].Left - Printer.Canvas.TextWidth(Lab+' ') div 2 ;
              Bar.Right := Bar.Left + Printer.Canvas.TextWidth('X') ;
              Bar.Bottom := PrChan[ch].Bottom ;
              Bar.Top := Bar.Bottom
                         - Abs( Round((PrChan[ch].CalBar*PrChan[ch].yScale)
                                    /PrChan[ch].ADCScale) ) ;
              { Draw vertical bar with T's at each end }
              Printer.Canvas.MoveTo( Bar.Left ,  Bar.Bottom ) ;
              Printer.Canvas.LineTo( Bar.Right , Bar.Bottom ) ;
              Printer.Canvas.MoveTo( Bar.Left ,  Bar.Top ) ;
              Printer.Canvas.LineTo( Bar.Right , Bar.Top ) ;
              Printer.Canvas.MoveTo( (Bar.Left + Bar.Right) div 2,  Bar.Bottom ) ;
              Printer.Canvas.LineTo( (Bar.Left + Bar.Right) div 2,  Bar.Top ) ;
              { Draw bar label }
              Printer.Canvas.TextOut(PrChan[ch].Left - Printer.Canvas.TextWidth(Lab),
                                     prChan[ch].Bottom
                                     + Printer.Canvas.TextHeight(Lab) div 4,
                                     Lab ) ;
              end ;

          { Draw horizontal time calibration bar }
          Lab := format( '%.4g %s', [FTCalBar*FTScale,FTUnits] ) ;
          { Calculate position/size of bar }
          LastCh := 0 ;
          for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
              Bar.Top := PrChan[ch].Bottom + Printer.Canvas.TextHeight(Lab) ;
              LastCh := ch ;
              end ;
          Bar.Bottom := Bar.Top + (Printer.Canvas.TextHeight(Lab) div 2);
          Bar.Left := PrChan[LastCh].Left ;
          Bar.Right := Bar.Left + Abs(Round(FTCalBar*PrChan[LastCh].xScale)) ;
          { Draw vertical bar with T's at each end }
          Printer.Canvas.MoveTo( Bar.Left ,  Bar.Bottom ) ;
          Printer.Canvas.LineTo( Bar.Left ,  Bar.Top ) ;
          Printer.Canvas.MoveTo( Bar.Right , Bar.Bottom ) ;
          Printer.Canvas.LineTo( Bar.Right , Bar.Top ) ;
          Printer.Canvas.MoveTo( Bar.Left, (Bar.Top + Bar.Bottom) div 2 ) ;
          Printer.Canvas.LineTo( Bar.Right,(Bar.Top + Bar.Bottom) div 2 ) ;
          { Draw bar label }
          Printer.Canvas.TextOut(Bar.Left ,
                              Bar.Bottom + Printer.Canvas.TextHeight(Lab) div 4,
                              Lab ) ;

           // Marker text
          for i := 0 to FMarkerText.Count-1 do begin
              xPix := XToCanvasCoord( PrChan[LastCh],
                                      Integer(FMarkerText.Objects[i]) ) ;
              yPix := PrChan[LastCh].Bottom +
                      ((i Mod 2)+1)*Printer.Canvas.TextHeight(FMarkerText.Strings[i]) ;
              Printer.Canvas.TextOut( xPix, yPix, FMarkerText.Strings[i] );
              end ;


          { Draw printer title }
          XPos := FPrinterLeftMargin ;
          YPos := FPrinterTopMargin ;
          CodedTextOut( Printer.Canvas, XPos, YPos, FTitle ) ;

          end ;

     finally
           { Get rid of array }
           Dispose(xy) ;
           DefaultPen.Free ;
           { Close down printer }
           Printer.EndDoc ;
           Cursor := crDefault ;
           end ;

     end ;


procedure TMatrixDisplay.CopyImageToClipboard ;
{ -----------------------------------------
  Copy signal image on display to clipboard
  -----------------------------------------}
var
   i,j,n,ch,LastCh,yPix,xPix,Rec,NumBytesPerRecord : Integer ;
   x,YTotal : single ;
   LeftMarginShift, TopMarginShift : Integer ;
   OK : Boolean ;
   ChannelHeight,cTop,NumInUse,AvailableHeight : Integer ;
   MFChan : Array[0..ScopeChannelLimit] of TScopeChannel ;
   xy : ^TPointArray ;
   Bar : TRect ;
   Lab : string ;

   TMF : TMetafile ;
   TMFC : TMetafileCanvas ;
   DefaultPen : TPen ;
begin

     { Create plotting points array }
     New(xy) ;
     DefaultPen := TPen.Create ;
     Cursor := crHourglass ;

     { Create Windows metafile object }
     TMF := TMetafile.Create ;
     TMF.Width := FMetafileWidth ;
     TMF.Height := FMetafileHeight ;

     try
        { Create a metafile canvas to draw on }
        TMFC := TMetafileCanvas.Create( TMF, 0 ) ;

        try
            { Set type face }
            TMFC.Font.Name := FPrinterFontName ;
            TMFC.Font.Size := FPrinterFontSize ;
            TMFC.Pen.Width := FPrinterPenWidth ;
            DefaultPen.Assign(TMFC.Pen) ;

            { Make the size of the canvas the same as the displayed area
              AGAIN ... See above. Not sure why we need to do this again
              but clipboard image doesn't come out right if we don't}
            TMF.Width := FMetafileWidth ;
            TMF.Height := FMetafileHeight ;
            { ** NOTE ALSO The above two lines MUST come
              BEFORE the setting of the plot margins next }


            // Determine number of channels in use
             NumInUse := 0 ;
             YTotal := 0.0 ;
             for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                 Inc(NumInUse) ;
                 YTotal := YTotal + Channel[ch].YSize ;
                 end ;
             if NumInUse < 1 then begin
                YTotal := 1.0 ;
                end ;

             // Height available for each channel. NOTE This includes 3
             AvailableHeight := TMF.Height - 4*TMFC.TextHeight('X') - 4 ;

            { Make space at left margin for channel names/cal. bars }
            LeftMarginShift := 0 ;
            for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                Lab := Channel[ch].ADCName + ' ' ;
                if (LeftMarginShift < TMFC.TextWidth(Lab)) then
                   LeftMarginShift := TMFC.TextWidth(Lab) ;
                Lab := format( ' %6.5g %s ', [Channel[ch].CalBar,Channel[ch].ADCUnits] ) ;
                if (LeftMarginShift < TMFC.TextWidth(Lab)) then
                   LeftMarginShift := TMFC.TextWidth(Lab) ;
                end ;

            { Define display area for each channel in use }
            cTop := TMFC.TextHeight('X') ;
            for ch := 0 to FNumChannels-1 do begin
                MFChan[ch] := Channel[ch] ;
                if Channel[ch].InUse then begin
                   if FPrinterDisableColor then MFChan[ch].Color := clBlack ;
                   MFChan[ch].Left := TMFC.TextWidth('X') + LeftMarginShift ;
                   MFChan[ch].Right := TMF.Width - TMFC.TextWidth('X') ;
                   MFChan[ch].Top := cTop ;
                   ChannelHeight := Round((Channel[ch].YSize/YTotal)*AvailableHeight) ;
                   MFChan[ch].Bottom := MFChan[ch].Top + ChannelHeight ;
                   MFChan[ch].xMin := FXMin ;
                   MFChan[ch].xMax := FXMax ;
                   MFChan[ch].xScale := (MFChan[ch].Right - MFChan[ch].Left) /
                                        (MFChan[ch].xMax - MFChan[ch].xMin ) ;
                   MFChan[ch].yScale := (MFChan[ch].Bottom - MFChan[ch].Top) /
                                        (MFChan[ch].yMax - MFChan[ch].yMin ) ;
                   cTop := cTop + ChannelHeight ;
                   End ;
                end ;

            { Plot channel names }
            if FPrinterShowLabels then begin
               for ch := 0 to FNumChannels-1 do
                   if MFChan[ch].InUse and (FBuf <> Nil) then begin
                   Lab := MFChan[ch].ADCName + ' ' ;
                   TMFC.TextOut( MFChan[ch].Left - TMFC.TextWidth(Lab),
                                (MFChan[ch].Top + MFChan[ch].Bottom) div 2,
                                 Lab ) ;
                   end ;
               end ;

            { Plot record(s) on metafile image canvas }

            if FStorageMode then begin
               { Display all records stored on screen }
               NumBytesPerRecord := FNumChannels*FNumPoints*2 ;
               Rec := 1 ;
               FStorageFile.Seek( Rec*NumBytesPerRecord, soFromBeginning ) ;
               while (FStorageList[Rec] <> NoRecord)
                     and (Rec <= High(FStorageList)) do begin
                     { Read buffer }
                     FStorageFile.Read( FBuf^, NumBytesPerRecord ) ;
                     { Plot record on display }
                     PlotRecord( TMFC, MFChan, xy^ ) ;
                     Inc(Rec) ;
                     end ;
               end
            else begin
               { Single-record mode }
               PlotRecord( TMFC, MFChan, xy^ ) ;
               end ;

            { Plot external line on selected channel }
            if (FLine <> Nil) and (FLineCount > 1) then begin
               TMFC.Pen.Assign(FLinePen) ;
               for i := 0 to FLineCount-1 do begin
                   xy^[i].x := XToCanvasCoord( MFChan[FLineChannel], FLine^[i].x ) ;
                   xy^[i].y := YToCanvasCoord( MFChan[FLineChannel], FLine^[i].y ) ;
                   end ;
               OK := Polyline( TMFC.Handle, xy^, FLineCount ) ;
               TMFC.Pen.Assign(DefaultPen) ;
               end ;

            { Draw baseline levels }
            if FPrinterShowZeroLevels then begin
               TMFC.Pen.Width := 1 ;
               TMFC.Pen.Style := psDot ;
               for ch := 0 to FNumChannels-1 do if MFChan[ch].InUse then begin
                   YPix := YToCanvasCoord( MFChan[ch], MFChan[ch].ADCZero ) ;
                   TMFC.MoveTo( MFChan[ch].Left,  YPix ) ;
                   TMFC.LineTo( MFChan[ch].Right, YPix ) ;
                   end ;
               end ;

            { Restore pen to black and solid for cal. bars }
            TMFC.Pen.Assign(DefaultPen) ;

            if FPrinterShowLabels then begin
               { Draw vertical calibration bars }
               for ch := 0 to FNumChannels-1 do
                   if MFChan[ch].InUse and (MFChan[ch].CalBar <> 0.0) then begin
                   { Bar label }
                   Lab := format( '%6.5g %s ', [MFChan[ch].CalBar,MFChan[ch].ADCUnits] ) ;
                   { Calculate position/size of bar }
                   Bar.Left := MFChan[ch].Left - TMFC.TextWidth(Lab+' ') div 2 ;
                   Bar.Right := Bar.Left + TMFC.TextWidth('X') ;
                   Bar.Bottom := MFChan[ch].Bottom ;
                   Bar.Top := Bar.Bottom
                              - Abs( Round((MFChan[ch].CalBar*MFChan[ch].yScale)/
                                         MFChan[ch].ADCScale) ) ;
                   { Draw vertical bar with T's at each end }
                   TMFC.MoveTo( Bar.Left ,  Bar.Bottom ) ;
                   TMFC.LineTo( Bar.Right , Bar.Bottom ) ;
                   TMFC.MoveTo( Bar.Left ,  Bar.Top ) ;
                   TMFC.LineTo( Bar.Right , Bar.Top ) ;
                   TMFC.MoveTo( (Bar.Left + Bar.Right) div 2,  Bar.Bottom ) ;
                   TMFC.LineTo( (Bar.Left + Bar.Right) div 2,  Bar.Top ) ;
                   { Draw bar label }
                   TMFC.TextOut(MFChan[ch].Left - TMFC.TextWidth(Lab),
                                MFChan[ch].Bottom
                                + TMFC.TextHeight(Lab) div 4,
                                Lab ) ;
                   end ;

               { Draw horizontal time calibration bar }
               Lab := format( '%.4g %s', [FTCalBar*FTScale,FTUnits] ) ;
               { Calculate position/size of bar }
               LastCh := 0 ;
               for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                   Bar.Top := MFChan[ch].Bottom + TMFC.TextHeight(Lab) ;
                   LastCh := ch ;
                   end ;
               Bar.Bottom := Bar.Top + (TMFC.TextHeight(Lab) div 2);
               Bar.Left := MFChan[LastCh].Left ;
               Bar.Right := Bar.Left + Round(FTCalBar*MFChan[LastCh].xScale) ;
               { Draw vertical bar with T's at each end }
               TMFC.MoveTo( Bar.Left ,  Bar.Bottom ) ;
               TMFC.LineTo( Bar.Left ,  Bar.Top ) ;
               TMFC.MoveTo( Bar.Right , Bar.Bottom ) ;
               TMFC.LineTo( Bar.Right , Bar.Top ) ;
               TMFC.MoveTo( Bar.Left, (Bar.Top + Bar.Bottom) div 2 ) ;
               TMFC.LineTo( Bar.Right,(Bar.Top + Bar.Bottom) div 2 ) ;
               { Draw bar label }
               TMFC.TextOut(Bar.Left ,
                         Bar.Bottom + TMFC.TextHeight(Lab) div 4,
                         Lab ) ;

               // Marker text
               for i := 0 to FMarkerText.Count-1 do begin
                   xPix := XToCanvasCoord( MFChan[LastCh],
                                           Integer(FMarkerText.Objects[i]) ) ;
                   yPix := MFChan[LastCh].Bottom +
                           ((i Mod 2)+1)*TMFC.TextHeight(FMarkerText.Strings[i]) ;
                   TMFC.TextOut( xPix, yPix, FMarkerText.Strings[i] );
                   end ;

               end ;
        finally
            { Free metafile canvas. Note this copies plot into metafile object }
            DefaultPen.Free ;
            TMFC.Free ;
            end ;

        { Copy metafile to clipboard }
        Clipboard.Assign(TMF) ;

     finally
           { Get rid of array }
           Dispose(xy) ;
           Cursor := crDefault ;
           end ;

     end ;


procedure TMatrixDisplay.CodedTextOut(
          Canvas : TCanvas ;           // Output Canvas
          var LineLeft : Integer ;     // Position of left edge of line
          var LineYPos : Integer ;     // Vertical line position
          List : TStringList           // Strings to be displayed
          ) ;
//----------------------------------------------------------------
// Display lines of text with ^-coded super/subscripts and symbols
//----------------------------------------------------------------
// Added 17/7/01
var
   DefaultFont : TFont ;
   Line,LineSpacing,YSuperscriptShift,YSubscriptShift,i,X,Y : Integer ;
   Done : Boolean ;
   TextLine : string ;
begin

     // Store default font settings
     DefaultFont := TFont.Create ;
     DefaultFont.Assign(Canvas.Font) ;

     try

     // Inter-line spacing and offset used for super/subscripting
     LineSpacing := Canvas.TextHeight('X') ;
     YSuperscriptShift := LineSpacing div 4 ;
     YSubscriptShift := LineSpacing div 2 ;
     LineSpacing := LineSpacing + YSuperscriptShift ;

     // Move to start position for text output
     Canvas.MoveTo( LineLeft, LineYPos ) ;

     { Display coded lines of text on device }

     for Line := 0 to FTitle.Count-1 do begin

         // Get line of text
         TextLine := FTitle.Strings[Line] ;

         // Move to start of line
         X := LineLeft ;
         Y := LineYPos ;
         Canvas.MoveTo( X, Y ) ;

         // Decode and output line
         Done := False ;
         i := 1 ;
         while not Done do begin

             // Get current cursor position
             X := Canvas.PenPos.X ;
             Y := LineYPos ;
             // Restore default font setting
             Canvas.Font.Assign(DefaultFont) ;

             if i <= Length(TextLine) then begin
                if TextLine[i] = '^' then begin
                   Inc(i) ;
                   case TextLine[i] of
                        // Bold
                        'b' : begin
                           Canvas.Font.Style := [fsBold] ;
                           Canvas.TextOut( X, Y, TextLine[i+1] ) ;
                           Inc(i) ;
                           end ;
                        // Italic
                        'i' : begin
                           Canvas.Font.Style := [fsItalic] ;
                           Canvas.TextOut( X, Y, TextLine[i+1] ) ;
                           Inc(i) ;
                           end ;
                        // Subscript
                        '-' : begin
                           Y := Y + YSubscriptShift ;
                           Canvas.Font.Size := (3*Canvas.Font.Size) div 4 ;
                           Canvas.TextOut( X, Y, TextLine[i+1] ) ;
                           Inc(i) ;
                           end ;
                        // Superscript
                        '+' : begin
                           Y := Y - YSuperscriptShift ;
                           Canvas.Font.Size := (3*Canvas.Font.Size) div 4 ;
                           Canvas.TextOut( X, Y, TextLine[i+1] ) ;
                           Inc(i) ;
                           end ;
                        // Superscripted 2
                        '2' : begin
                           Y := Y - YSuperscriptShift ;
                           Canvas.Font.Size := (3*Canvas.Font.Size) div 4 ;
                           Canvas.TextOut( X, Y, '2' ) ;
                           end ;

                        // Greek letter from Symbol character set
                        's' : begin
                           Canvas.Font.Name := 'Symbol' ;
                           Canvas.TextOut( X, Y, TextLine[i+1] ) ;
                           Inc(i) ;
                           end ;
                        // Square root symbol
                        '!' : begin
                           Canvas.Font.Name := 'Symbol' ;
                           Canvas.TextOut( X, Y, chr(214) ) ;
                           end ;
                        // +/- symbol
                        '~' : begin
                           Canvas.Font.Name := 'Symbol' ;
                           Canvas.TextOut( X, Y, chr(177) ) ;
                           end ;

                        end ;
                   end
                else Canvas.TextOut( X, Y, TextLine[i] ) ;

                Inc(i) ;
                end
             else Done := True ;
             end ;

         // Increment position to next line
         LineYPos := LineYPos + LineSpacing ;

         Canvas.Font.Assign(DefaultFont) ;

         end ;

     finally

            DefaultFont.Free ;

            end ;

     end ;



procedure TMatrixDisplay.ClearPrinterTitle ;
{ -------------------------
  Clear printer title lines
  -------------------------}
begin
     FTitle.Clear ;
     end ;


procedure TMatrixDisplay.AddPrinterTitleLine(
          Line : string
          );
{ ---------------------------
  Add a line to printer title
  ---------------------------}
begin
     FTitle.Add( Line ) ;
     end ;


procedure TMatrixDisplay.CreateLine(
          Ch : Integer ;                    { Display channel to be drawn on [IN] }
          iColor : TColor ;                 { Line colour [IN] }
          iStyle : TPenStyle ;               { Line style [IN] }
          Width : Integer                   // Line width (IN)
          ) ;
{ -----------------------------------------------
  Create a line to be superimposed on the display
  -----------------------------------------------}
begin
     { Create line data array }
     if FLine = Nil then New(FLine) ;
     FLineCount := 0 ;
     FLineChannel := IntLimitTo(Ch,0,FNumChannels-1) ;
     FLinePen.Color := iColor ;
     FLinePen.Style := iStyle ;
     FLinePen.Width := Width ;
     end ;


procedure TMatrixDisplay.AddPointToLine(
          x : single ;
          y : single
          ) ;
{ ---------------------------
  Add a point to end of line
  ---------------------------}
var
   xPix, yPix : Integer ;
   KeepPen : TPen ;
begin

     KeepPen := TPen.Create ;

     if FLine <> Nil then begin
        { Add x,y point to array }
        FLine^[FLineCount].x := x ;
        FLine^[FLineCount].y := y ;
        { Add line to end of plot }
        if FLineCount > 0 then begin
           KeepPen.Assign(Canvas.Pen) ;
           Canvas.Pen.Assign(FLinePen) ;
           xPix := XToCanvasCoord( Channel[FLineChannel], FLine^[FLineCount-1].x ) ;
           yPix := YToCanvasCoord( Channel[FLineChannel], FLine^[FLineCount-1].y ) ;
           Canvas.MoveTo( xPix, yPix ) ;
           xPix := XToCanvasCoord( Channel[FLineChannel], x ) ;
           yPix := YToCanvasCoord( Channel[FLineChannel], y ) ;
           Canvas.LineTo( xPix, yPix ) ;
           Canvas.Pen.Assign(KeepPen) ;
           end ;
        { Increment counter }
        if FLineCount < High(TSinglePointArray) then Inc(FLineCount) ;
        end ;

     KeepPen.Free ;

     end ;


procedure TMatrixDisplay.DrawZoomButton(
          var CV : TCanvas ;
          X : Integer ;
          Y : Integer ;
          Size : Integer ;
          ButtonType : Integer ;
          ChanNum : Integer
          ) ;
var
    SavedBrush : TBrushRecall ;
    SavedPen : TPenRecall ;
    XMid,YMid,HalfSize : Integer ;
begin

    SavedBrush := TBrushRecall.Create( CV.Brush ) ;
    SavedPen := TPenRecall.Create( CV.Pen ) ;

    CV.Pen.Color := clBlack ;
    CV.Brush.Style := bsSolid ;
    CV.Brush.Color := clGray ;

    HalfSize := Size div 2 ;
    XMid :=  X + HalfSize -1 ;
    YMid :=  Y + HalfSize -1 ;

    ZoomButtonList[NumZoomButtons].Rect.Left := X ;
    ZoomButtonList[NumZoomButtons].Rect.Top := Y ;
    ZoomButtonList[NumZoomButtons].Rect.Right := X + Size -1 ;
    ZoomButtonList[NumZoomButtons].Rect.Bottom := Y + Size -1 ;
    ZoomButtonList[NumZoomButtons].ChanNum := ChanNum ;
    ZoomButtonList[NumZoomButtons].ButtonType := ButtonType ;

    CV.RoundRect( ZoomButtonList[NumZoomButtons].Rect.Left,
                  ZoomButtonList[NumZoomButtons].Rect.Top,
                  ZoomButtonList[NumZoomButtons].Rect.Right,
                  ZoomButtonList[NumZoomButtons].Rect.Bottom,
                  2,2) ;

    CV.Pen.Color := clWhite ;

    // Draw button label

    case ButtonType of
       cZoomOutButton : begin
          CV.Polyline( [Point(X+2,YMid),Point(X+Size-3,YMid)]);
          end ;
       cZoomInButton : begin
          CV.Polyline( [Point(X+2,YMid),Point(X+Size-3,YMid)]);
          CV.Polyline( [Point(XMid,Y+2),Point(XMid,Y+Size-3)]);
          end ;
       cZoomUpButton : begin
          CV.Polygon( [Point(XMid,Y+2),
                       Point(X+2,Y+Size-3),
                       Point(X+Size-3,Y+Size-3)]);
          end ;
       cZoomDownButton : begin
          CV.Polygon( [Point(XMid,Y+Size-3),
                       Point(X+2,Y+2),
                       Point(X+Size-3,Y+2)]);
          end ;
       cZoomLeftButton : begin
          CV.Polygon( [Point(X+2,YMid),
                       Point(X+Size-3,Y+2),
                       Point(X+Size-3,Y+Size-3)]);
          end ;
       cZoomRightButton : begin
          CV.Polygon( [Point(X+Size-3,YMid),
                       Point(X+2,Y+2),
                       Point(X+2,Y+Size-3)]);
          end ;
       cEnabledButton : begin
          if Channel[ChanNum].InUse then begin
             CV.Polyline( [Point(X+2,Y+Size-4),
                           Point(X+4,Y+Size-2),
                           Point(X+Size-3,Y+2)]);
             end
          else begin
             CV.Polyline( [Point(X+2,Y+2),
                           Point(X+Size-3,Y+Size-3)]) ;
             CV.Polyline( [Point(X+Size-3,Y+2),
                        Point(X+2,Y+Size-3)]) ;
             end ;
          end ;
       end ;

    SavedBrush.Free ;
    SavedPen.Free ;

    if NumZoomButtons < High(ZoomButtonList) then Inc(NumZoomButtons) ;

    end ;


procedure TMatrixDisplay.CheckZoomButtons ;
// -------------------------------------------
// Handle mouse clicks on display zoom buttons
// -------------------------------------------
var
    ch,i,ChanNum : Integer ;
    XRange,YRange : Single ;
begin

    for i := 0 to NumZoomButtons-1 do begin
        if (MouseX >= ZoomButtonList[i].Rect.Left) and
           (MouseX <= ZoomButtonList[i].Rect.Right) and
           (MouseY >= ZoomButtonList[i].Rect.Top) and
           (MouseY <= ZoomButtonList[i].Rect.Bottom) then begin
           ChanNum := ZoomButtonList[i].ChanNum ;
           case ZoomButtonList[i].ButtonType of

             cZoomInButton : begin
                  if ChanNum >= 0 then begin
                     for ch := 0 to FNumChannels-1 do Self.YZoom( ch, -50.0 )
                     end
                  else Self.XZoom( -50.0 ) ;
                  end ;

             cZoomOutButton : begin
                  if ChanNum >= 0 then begin
                     for ch := 0 to FNumChannels-1 do Self.YZoom( ch, 100.0 )
                     end
                  else Self.XZoom( 100.0 ) ;
                  end ;

             cZoomUpButton : begin
                 YRange := (Channel[ChanNum].YMax - Channel[ChanNum].YMin) ;
                 Channel[ChanNum].YMax := Min( FMaxADCValue,
                                               Channel[ChanNum].YMax + (YRange*0.1));
                 Channel[ChanNum].YMin := Max( FMinADCValue,
                                               Channel[ChanNum].YMax - YRange);
                 end ;

             cZoomDownButton : begin
                 YRange := (Channel[ChanNum].YMax - Channel[ChanNum].YMin) ;
                 Channel[ChanNum].YMin := Max( FMinADCValue,
                                               Channel[ChanNum].YMin - (YRange*0.1));
                 Channel[ChanNum].YMax := Min( FMaxADCValue,
                                               Channel[ChanNum].YMin + YRange);
                 end ;

             cZoomLeftButton : begin
                 if FNumPoints > 0 then begin
                    XRange := (FXMax - FXMin) ;
                    FXMin := Max( 0,Round(FXMin - (XRange*0.1)));
                    FXMax := Min( FNumPoints,Round(FXMin + XRange));
                    end ;
                 for ch := 0 to FNumChannels-1 do begin
                     Channel[ch].XMin := FXMin ;
                     Channel[ch].XMax := FXMax ;
                     end ;
                 end ;

             cZoomRightButton : begin
                 if FNumPoints > 0 then begin
                    XRange := (FXMax - FXMin) ;
                    FXMax := Min( FNumPoints,Round(FXMax + (XRange*0.1)));
                    FXMin := Max( 0,Round(FXMax - XRange));
                    end ;
                 for ch := 0 to FNumChannels-1 do begin
                     Channel[ch].XMin := FXMin ;
                     Channel[ch].XMax := FXMax ;
                     end ;
                 end ;

             cEnabledButton : begin
                 Channel[ChanNum].InUse := not Channel[ChanNum].InUse ;
                 end ;
             end ;
           Invalidate ;
           end ;
        end ;
    end ;


procedure TMatrixDisplay.ShowSelectedZoomButton ;
// --------------------------------------
// Change colour of selected zoom button
// --------------------------------------
var
    i : Integer ;
    SavedBrush : TBrushRecall ;
begin

    SavedBrush := TBrushRecall.Create( Canvas.Brush ) ;
    Canvas.Brush.Color := clBlack ;
    Canvas.Brush.Style := bsSolid ;

    for i := 0 to NumZoomButtons-1 do begin
        if (MouseX >= ZoomButtonList[i].Rect.Left) and
           (MouseX <= ZoomButtonList[i].Rect.Right) and
           (MouseY >= ZoomButtonList[i].Rect.Top) and
           (MouseY <= ZoomButtonList[i].Rect.Bottom) then begin
           Canvas.RoundRect( ZoomButtonList[i].Rect.Left,
                         ZoomButtonList[i].Rect.Top,
                         ZoomButtonList[i].Rect.Right,
                         ZoomButtonList[i].Rect.Bottom,
                         2,2) ;
           end ;
        end ;

    SavedBrush.Free ;

    end ;


procedure TMatrixDisplay.ProcessZoomBox ;
// ----------------
// Process zoom box
// ----------------
var
    BoxTop,BoxBottom : Integer ;
    BoxLeft,BoxRight : Integer ;
    ch : Integer ;
    yMax,yScale : Single ;
    xMin,xScale : Single ;
begin

     // Exit if zoom box invalid
     if ZoomRectCount <= 1 then begin
        ZoomRectCount := 0 ;
        Exit ;
        end ;

     if Abs(ZoomRect.Bottom - ZoomRect.Top) < 8 then Exit ;
     if Abs(ZoomRect.Right - ZoomRect.Left) < 8 then Exit ;

     // Vertical magnification
     if not ZoomDisableVertical then begin
        yMax := Channel[ZoomChannel].yMax ;
        YScale := (Channel[ZoomChannel].yMax - Channel[ZoomChannel].yMin) /
                  (Channel[ZoomChannel].Top - Channel[ZoomChannel].Bottom) ;

        BoxTop := Min( ZoomRect.Top, ZoomRect.Bottom ) ;
        BoxBottom := Max( ZoomRect.Top, ZoomRect.Bottom ) ;
        Channel[ZoomChannel].yMax := Round( yMax +
                                     (BoxTop - Channel[ZoomChannel].Top)*YScale ) ;
        Channel[ZoomChannel].yMin := Round( yMax +
                                     (BoxBottom - Channel[ZoomChannel].Top)*YScale ) ;
        end ;

     // Horizontal magnification
     if not ZoomDisableHorizontal then begin
        xMin := FXMin ;
        XScale := (FXMax - FXMin) /
                  (Channel[ZoomChannel].Right - Channel[ZoomChannel].Left) ;
        BoxLeft := Min( ZoomRect.Left, ZoomRect.Right ) ;
        BoxRight := Max( ZoomRect.Left, ZoomRect.Right ) ;

        FXMin := Round( FXMin + (BoxLeft - Channel[ZoomChannel].Left)*XScale ) ;
        FXMax := Round( xMin + (BoxRight - Channel[ZoomChannel].Left)*XScale ) ;

        for ch := 0 to FNumChannels-1 do begin
            Channel[ch].XMin := FXMin ;
            Channel[ch].XMax := FXMax ;
            end ;

        end ;

     ZoomRectCount := 0 ;

     Invalidate ;

     end ;


procedure TMatrixDisplay.ResizeZoomBox(
          X : Integer ;
          Y : Integer ) ;
// -----------------------------
// Resize zoom box (if one exists)
// -----------------------------
var
   OldCopyMode : TCopyMode ;
begin

     // Display zoom box
     if ZoomRectCount <= 0 then Exit ;
     if FHorCursorActive or FVertCursorActive then Exit ;
     if (X < Channel[ZoomChannel].Left) or
        (X > Channel[ZoomChannel].Right) or
        (Y < Channel[ZoomChannel].Top) or
        (Y > Channel[ZoomChannel].Bottom) then Exit ;

     OldCopyMode := Canvas.CopyMode ;
     Canvas.CopyMode := cmNotSrcCopy ;

     // Remove existing zoom rectangle
     if ZoomRectCount > 1 then Canvas.CopyRect( ZoomRect, Canvas, ZoomRect ) ;

     // Update right edge of zoom box
     if FZoomDisableHorizontal then begin
        ZoomRect.Right := Channel[0].Right ;
        ZoomRect.Left := Channel[0].Left ;
        end
     else ZoomRect.Right :=  Min(Max(X,Channel[0].Left),Channel[0].Right) ;

     // Update bottom edge of zoom box
     if FZoomDisableVertical then begin
        ZoomRect.Top := Channel[ZoomChannel].Top ;
        ZoomRect.Bottom := Channel[ZoomChannel].Bottom ;
        end
     else ZoomRect.Bottom := Min(Max(Y,Channel[ZoomChannel].Top),
                                       Channel[ZoomChannel].Bottom) ;

     // Display new zoom rectangle
     Canvas.CopyRect( ZoomRect, Canvas, ZoomRect ) ;
     Canvas.CopyMode := OldCopyMode ;

     Inc(ZoomRectCount) ;
     end ;



end.
