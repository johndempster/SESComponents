unit ChartDisplay;

{ ================================================
  Chart recorder Display Component
  (c) J. Dempster, University of Strathclyde, 1999
  ================================================
  Started 14/2/99
  Nearly complete 5/3/99
  16/6/99 ... Crosstalk between channels when zoomed or disabled now fixed
  30/8/99 ... Display grid option added /
              MinADCValue & MaxADCValue can now be set by user
  16/9/99 ... Horizontal cursors now visible only when channel is visible
  19/9/99 ... Vert. cursor now reads correctly when some channels invisible
  26/10/99 ... AddHorizontalCursor now has UseAsZeroLevel flag
               Channel zero levels updated when baseline cursors changed
  21/2/00 .... PrinterShowLabels & PrinterShowZeroLevels added to properties
  28/2/00 .... Left margin now leaves space for vertical cal. bar. text.
  16/1/01 .... CopyDataToClipboard now outputs time correctlt
               and no longer mixes up multiple channels
  20/7/01 ... CopyDataToClipboard now handles large blocks of data correctly
  14/8/01 ... Array properties shifted to Public to make component compilable under Delphi V5
  19/3/02 ... Channels now spaced apart vertically, top/bottom grid lines now correctly plotted
  20/3/02 ... ??Units/Div calibration added
  28/11/02 ... Spurious character at beginning of data copied to clipboard
               by CopyDataToClipboard now removed.
              }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Clipbrd, printers ;
const
     ChannelLimit = 15 ;
type
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

TPointArray = Array[0..32767] of TPoint ;
TSmallIntArray = Array[0..32767] of SmallInt ;
TSmallIntArrayPointer = ^TSmallIntArrayPointer ;

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
         CalBar : single ;
         InUse : Boolean ;
         ADCOffset : Integer ;
         color : TColor ;
         Position : Integer ;
         Channel : Integer ;
         ZeroLevel : Boolean ;
         end ;

  TChartDisplay = class(TGraphicControl)
  private
    { Private declarations }
    FMinADCValue : Integer ;
    FMaxADCValue : Integer ;
    FNumChannels : Integer ;
    FNumBlocks : Integer ;
    FNumBlocksInDisplay : Integer ;
    FMaxBlocksInDisplay : Integer ;
    FBlockSize : Integer ;
    FNumBytesInHeader : Integer ;
    FNumSamples : Integer ;
    FNumSamplesOld : Integer ;
    FStartAtSample : Integer ;
    FStartAtSampleOld : Integer ;
    FMaxSamples : Integer ;
    FFileHandle : Integer ;
    FNewData : Boolean ;
    Channel : Array[0..ChannelLimit] of TScopeChannel ;
    KeepChannel : Array[0..ChannelLimit] of TScopeChannel ;
    HorCursors : Array[0..ChannelLimit] of TScopeChannel ;
    VertCursors : Array[0..64] of TScopeChannel ;
    FBuf : ^TSmallIntArray ;
    FHorCursorActive : Boolean ;
    FHorCursorSelected : Integer ;
    FVertCursorActive : Boolean ;
    FVertCursorSelected : Integer ;
    FZoomBox : TRect ;
    FZoomMode : Boolean ;
    FZoomCh : Integer ;
    FMouseOverChannel : Integer ;
    FMoveZoomBox : Boolean ;
    MousePos : TMousePos ;
    FXOld : Integer ;
    FYOld : Integer ;
    FTScale : single ;
    FTFormat : string ;
    FTCalBar : single ;
    FOnCursorChange : TNotifyEvent ;
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
    FDrawGrid : Boolean ;
    FGridColor : TColor ;

    procedure SetNumChannels( Value : Integer ) ;
    procedure SetNumPoints( Value : Integer ) ;

    procedure SetChanName( Ch : Integer ; Value : string ) ;
    function GetChanName( Ch : Integer ) : string ;

    procedure SetChanUnits( Ch : Integer ; Value : string ) ;
    function GetChanUnits( Ch : Integer ) : string ;

    procedure SetChanScale( Ch : Integer ; Value : single ) ;
    function GetChanScale( Ch : Integer ) : single ;

    procedure SetChanCalBar( Ch : Integer ; Value : single ) ;
    function GetChanCalBar( Ch : Integer ) : single ;

    procedure SetChanZero( Ch : Integer ; Value : Integer ) ;
    function GetChanZero( Ch : Integer ) : Integer ;

    procedure SetChanOffset( Ch : Integer ; Value : Integer ) ;
    function GetChanOffset( Ch : Integer ) : Integer ;

    procedure SetChanVisible( Ch : Integer ; Value : boolean ) ;
    function GetChanVisible( Ch : Integer ) : Boolean ;

    procedure SetChanColor( Ch : Integer ; Value : TColor ) ;
    function GetChanColor( Ch : Integer ) : TColor ;

    procedure SetYMin( Ch : Integer ; Value : single ) ;
    function  GetYMin( Ch : Integer ) : single ;
    procedure SetYMax( Ch : Integer ; Value : single ) ;
    function  GetYMax( Ch : Integer ) : single ;

    procedure SetNewData( Value : boolean ) ;

    procedure SetHorCursor( iCursor : Integer ; Value : Integer ) ;
    function GetHorCursor( iCursor : Integer ) : Integer ;
    procedure SetVertCursor( iCursor : Integer ; Value : Integer ) ;
    function GetVertCursor( iCursor : Integer ) : Integer ;

    procedure SetTFormat( Value : string ) ;
    function GetTFormat : string ;
    function GetBlockSize : Integer ;

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
    procedure SetGrid( Value : Boolean ) ;

    function GetSelectedVertCursor : Integer ;


    function GetXScreenCoord(
             Value : Integer
             ) : Integer ;

    function IntLimitTo(
             Value : Integer ;         { Value to be checked }
             Lo : Integer ;            { Lower limit }
             Hi : Integer              { Upper limit }
             ) : Integer ;
    procedure DrawHorizontalCursor(
              iCurs : Integer
              ) ;
    procedure ProcessHorizontalCursors(
          Y : Integer
          ) ;
    procedure DrawVerticalCursor(
              iCurs : Integer
              ) ;
    procedure ProcessVerticalCursors(
              X : Integer
              ) ;

    procedure ProcessZoomBox(
              X : Integer ;
              Y : Integer ) ;

    procedure SwitchToZoomMode( Chan : Integer ) ;
    procedure SwitchToNormalMode ;              


    procedure GetADCSamples ;

  protected
    { Protected declarations }
    procedure Paint ; override ;
    procedure MouseMove(
              Shift: TShiftState;
              X, Y: Integer
              ); override ;
    procedure DblClick ; override ;

    procedure MouseDown(
              Button: TMouseButton;
              Shift: TShiftState;
              X, Y: Integer
              ); override ;
    procedure MouseUp(
              Button: TMouseButton;
              Shift: TShiftState;
              X, Y: Integer
              ); override ;

  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
    function XToScreenCoord(
             const Chan : TScopeChannel ;
             Value : Integer
             ) : Integer  ;
    function ScreenToXCoord(
             const Chan : TScopeChannel ;
             xPix : Integer
             ) : Integer  ;
    function YToScreenCoord(
             const Chan : TScopeChannel ;
             Value : Integer
             ) : Integer  ;
    function ScreenToYCoord(
             const Chan : TScopeChannel ;
             yPix : Integer
             ) : Integer  ;
    procedure ClearHorizontalCursors ;
    function AddHorizontalCursor( iChannel : Integer ;Color : TColor ;
                                  UseAsZeroLevel : Boolean ) : Integer ;
    procedure ClearVerticalCursors ;
    function AddVerticalCursor(
             Color : TColor
             ) : Integer ;

    procedure ZoomIn( Chan : Integer ) ;
    procedure ZoomOut ;

    procedure GetDataValues(
              Index : Integer ;
              Ch : Integer ;
              var MinValue : Integer ;
              var MaxValue : Integer
              ) ;
    procedure CopyDataToClipBoard ;
    procedure CopyImageToClipBoard ;
    procedure Print ;
    procedure ClearPrinterTitle ;
    procedure AddPrinterTitleLine(
              Line : string
              );

    property ChanName[ i : Integer ] : string read GetChanName write SetChanName ;
    property ChanUnits[ i : Integer ] : string read GetChanUnits write SetChanUnits ;
    property ChanScale[ i : Integer ] : single read GetChanScale write SetChanScale ;
    property ChanCalBar[ i : Integer ] : single read GetChanCalBar write SetChanCalBar ;
    property ChanZero[ i : Integer ] : Integer read GetChanZero write SetChanZero ;
    property ChanOffsets[ i : Integer ] : Integer read GetChanOffset write SetChanOffset ;
    property ChanVisible[ i : Integer ] : boolean read GetChanVisible write SetChanVisible ;
    property ChanColor[ i : Integer ] : TColor read GetChanColor write SetChanColor ;
    property YMin[ i : Integer ] : single read GetYMin write SetYMin ;
    property YMax[ i : Integer ] : single read GetYMax write SetYMax ;
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
    property OnDblClick ;
    property OnCursorChange : TNotifyEvent
             read FOnCursorChange write FOnCursorChange ;
    property Height default 150 ;
    property Width default 200 ;
    Property NumChannels : Integer Read FNumChannels write SetNumChannels ;
    Property StartAtSample : Integer Read FStartAtSample write FStartAtSample ;
    Property NumSamples : Integer Read FNumSamples write FNumSamples ;
    property MaxSamples : Integer read FMaxSamples write FMaxSamples ;
    Property FileHandle : Integer Read FFileHandle write FFileHandle ;
    property NumBytesInHeader : Integer
             read FNumBytesInHeader write FNumBytesInHeader default 0 ;
    Property NumPoints : Integer Read FMaxBlocksInDisplay write SetNumPoints ;
    property BlockSize : Integer read GetBlockSize ;
    property NewData : Boolean read FNewData write SetNewData ;
    property SelectedVertCursor : Integer read GetSelectedVertCursor ;
    property ZoomMode : boolean read FZoomMode ;
    property TScale : single read FTScale write FTScale ;
    property TFormat : string read GetTFormat write SetTFormat ;
    property TCalBar : single read FTCalBar write FTCalBar ;
    property PrinterFontSize : Integer read FPrinterFontSize write FPrinterFontSize ;
    property PrinterFontName : string read GetPrinterFontName write SetPrinterFontName ;
    property PrinterPenWidth : Integer read FPrinterPenWidth write FPrinterPenWidth ;
    property PrinterLeftMargin : Integer read GetPrinterLeftMargin write SetPrinterLeftMargin ;
    property PrinterRightMargin : Integer read GetPrinterRightMargin write SetPrinterRightMargin ;
    property PrinterTopMargin : Integer read GetPrinterTopMargin write SetPrinterTopMargin ;
    property PrinterBottomMargin : Integer read GetPrinterBottomMargin write SetPrinterBottomMargin ;
    property PrinterDisableColor : Boolean read FPrinterDisableColor write FPrinterDisableColor ;
    property PrinterShowLabels : Boolean read FPrinterShowLabels write FPrinterShowLabels ;
    property PrinterShowZeroLevels : Boolean read FPrinterShowZeroLevels write FPrinterShowZeroLevels ;
    property MetafileWidth : Integer read FMetafileWidth write FMetafileWidth ;
    property MetafileHeight : Integer read FMetafileHeight write FMetafileHeight ;
    property DisplayGrid : Boolean Read FDrawGrid Write SetGrid ;
    property MaxADCValue : Integer Read FMaxADCValue write FMaxADCValue ;
    property MinADCValue : Integer Read FMinADCValue write FMinADCValue ;

  end;

procedure Register;
function MinInt( const Buf : array of Integer ) : Integer ;
function MaxInt( const Buf : array of Integer ) : Integer ;


implementation

procedure Register;
begin
  RegisterComponents('Samples', [TChartDisplay]);
end;


constructor TChartDisplay.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
var
   i,ch : Integer ;
begin

     inherited Create(AOwner) ;
     
     { Set opaque background to minimise flicker when display updated }
     ControlStyle := ControlStyle + [csOpaque] ;

     { Create a list to hold any printer title strings }
     FTitle := TStringList.Create ;

     Width := 200 ;
     Height := 150 ;
     { Create internal objects used by control }
     FMinADCValue := -2048 ;
     FMaxADCValue := 2047 ;
     FNumChannels := 1 ;
     FBlockSize := FNumChannels ;
     FStartAtSample := 0 ;
     FStartAtSampleOld := 0 ;
     FMaxBlocksInDisplay := 1024 ;
     FNumSamples := FMaxBlocksInDisplay ;
     FNumSamplesOld := 0 ;
     FNumBlocksInDisplay := FMaxBlocksInDisplay ;
     FFileHandle := -1 ;
     FNewData := False ;

     for ch := 0 to High(Channel) do begin
         Channel[ch].InUse := True ;
         Channel[ch].ADCName := format('Ch.%d',[ch]) ;
         Channel[ch].ADCUnits := '' ;
         Channel[ch].ADCScale := 1.0 ;
         Channel[ch].ADCZero := 0 ;
         Channel[ch].CalBar := 0.0 ;
         Channel[ch].YMin := -2048 ;
         Channel[ch].YMax := 2047 ;
         Channel[ch].XMin := 0.0 ;
         Channel[ch].XMax := FNumBlocksInDisplay ;
         Channel[ch].ADCOffset := ch ;
         Channel[ch].Color := clBlue ;
         end ;

     for i := 0 to High(HorCursors) do HorCursors[i].InUse := False ;
     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;


     FHorCursorActive := False ;
     FHorCursorSelected := -1 ;
     FVertCursorActive := False ;
     FVertCursorSelected := -1 ;
     FZoomMode := False ;
     FZoomCh := 0 ;
     FMouseOverChannel := 0 ;
     FTFormat := '%.1f' ;
     FTScale := 1.0 ;

     { Default printer settings }
     FPrinterFontName := 'Arial' ;
     FPrinterFontSize := 10 ;
     FPrinterPenWidth := 1 ;
     FPrinterLeftMargin := 250 ;
     FPrinterRightMargin := 250 ;
     FPrinterTopMargin := 250 ;
     FPrinterBottomMargin := 250 ;
     FPrinterDisableColor := False ;
     FPrinterShowLabels := True ;
     FPrinterShowZeroLevels := True ;


     FDrawGrid := True ;
     FGridColor := clAqua ;

     FOnCursorChange := Nil ;

     { Create display buffer }
     New(FBuf)

     end ;


destructor TChartDisplay.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin
     { Destroy internal objects created by TChartDisplay.Create }
     Dispose(FBuf) ;
     FTitle.Free ;
     { Call inherited destructor }
     inherited Destroy ;
     end ;


procedure TChartDisplay.Paint ;
{ -----------------------
  Update chart on display
  -----------------------}
var
   i,j,n,ch : Integer ;
   OK : Boolean ;
   ChannelHeight,cTop,NumInUse,AvailableHeight,ChannelSpacing,LastActiveChannel : Integer ;
   TopOfChannels, BottomOfChannels : Integer ;
   x,dx,xPix,y,dy,yPix : Integer ;
   xy : ^TPointArray ;
   SaveColor : TColor ;
   ZoomScreen : TRect ;
   Lab : string ;
begin
     { Create plotting points array }
     New(xy) ;

     SaveColor := Canvas.Pen.Color ;


     try
        { Get new sample data if range has changed }
        if (FNumSamples <> FNumSamplesOld) or
           (FStartAtSample <> FStartAtSampleOld) then begin
           FNumSamplesOld := FNumSamples ;
           FStartAtSampleOld := FStartAtSample ;
           FNewData := True ;
           end ;

        { Clear display area }
        Canvas.fillrect(Canvas.ClipRect);

        { Get A/D samples from data file }
        if FNewData and (FFileHandle >= 0) then begin
           Canvas.TextOut( 0,0, ' Wait ...' ) ;
           GetADCSamples ;
           end ;

        { Determine number of channels in use and the height
          available for each channel }
        NumInUse := 0 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then Inc(NumInUse) ;
        if NumInUse < 1 then NumInUse := 1 ;

        Canvas.Font.Size := 8 ;
        AvailableHeight := Height - Canvas.TextHeight('X') - 4 ;
        ChannelSpacing :=  Canvas.TextHeight('X') ;
        ChannelHeight := (AvailableHeight div NumInUse) - ChannelSpacing ;

        { Define display area for each channel in use }
        //TopOfChannels := cTop ;
        cTop := 2 ;
        TopOfChannels := cTop ;
        LastActiveChannel := 0 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
             Channel[ch].Left := 5 ;
             Channel[ch].Right := Width - 5 ;
             Channel[ch].Top := cTop ;
             Channel[ch].xMin := 0.0 ;
             Channel[ch].xMax := FNumBlocksInDisplay ;
             if Channel[ch].xMax <= 0.0 then Channel[ch].xMax := 1.0 ;
             Channel[ch].Bottom := Channel[ch].Top + ChannelHeight ;
             Channel[ch].xScale := (Channel[ch].Right - Channel[ch].Left) /
                                   (Channel[ch].xMax - Channel[ch].xMin ) ;
             if Channel[ch].yMin = Channel[ch].yMax then
                Channel[ch].yMax := Channel[ch].yMin + 1.0 ;
             Channel[ch].yScale := (Channel[ch].Bottom - Channel[ch].Top) /
                                   (Channel[ch].yMax - Channel[ch].yMin ) ;
             cTop := cTop + ChannelHeight + ChannelSpacing ;
             LastActiveChannel := ch ;
             end ;
        BottomOfChannels := cTop ;

        for i := 0 to High(HorCursors) do if HorCursors[i].InUse then begin
           HorCursors[i].Left := Channel[HorCursors[i].Channel].Left ;
           HorCursors[i].Right := Channel[HorCursors[i].Channel].Right ;
           HorCursors[i].Top := Channel[HorCursors[i].Channel].Top ;
           HorCursors[i].Bottom := Channel[HorCursors[i].Channel].Bottom ;
           HorCursors[i].xScale := Channel[HorCursors[i].Channel].xScale ;
           HorCursors[i].yScale := Channel[HorCursors[i].Channel].yScale ;
           end ;

       for i := 0 to High(VertCursors) do if VertCursors[i].InUse then begin
           VertCursors[i].Left := Channel[VertCursors[i].Channel].Left ;
           VertCursors[i].Right := Channel[VertCursors[i].Channel].Right ;
           VertCursors[i].Top := TopOfChannels ;
           VertCursors[i].Bottom := BottomOfChannels ;
           VertCursors[i].yScale := Channel[VertCursors[i].Channel].yScale ;
           VertCursors[i].xMin := 0.0 ;
           VertCursors[i].xMax := MaxInt([FNumBlocksInDisplay,1]) ;
           VertCursors[i].xScale := (VertCursors[i].Right - VertCursors[i].Left) /
                                    (VertCursors[i].xMax - VertCursors[i].xMin ) ;
           end ;

       if FDrawGrid then begin

          Canvas.Pen.Color := FGridColor ;

         // Draw horizontal grid lines
         for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
             dy := (FMaxADCValue - FMinADCValue) div 10 ;
             y := FMinADCValue ;
             for i := 1 to 11 do begin
                 if (y >= Channel[ch].yMin) and
                    (y <= Channel[ch].yMax) then begin
                    yPix := YToScreenCoord( Channel[ch], y ) ;
                    Canvas.MoveTo( Channel[ch].Left, yPix )  ;
                    Canvas.LineTo( Channel[ch].Right, yPix )  ;
                    end ;
                 y := y + dy ;
                 end ;
             end ;

          dx := FNumBlocksInDisplay div 10 ;
          x := 0 ;
          for i := 1 to 9 do begin
             x := x + dx ;
             xPix := XToScreenCoord( Channel[LastActiveChannel], x ) ;
             if (xPix >= Channel[LastActiveChannel].Left) and
                (xPix <= Channel[LastActiveChannel].Right) then begin
                for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                    Canvas.MoveTo( xPix, Channel[ch].Bottom )  ;
                    Canvas.LineTo( xPix, Channel[ch].Top )  ;
                    end ;
                 end ;
             end ;

          Canvas.Pen.Color := SaveColor ;
          end ;


        { Plot channel }
        for ch := 0 to FNumChannels-1 do
           if Channel[ch].InUse and (FBuf <> Nil) then begin

           Canvas.Pen.Color := Channel[ch].Color ;
           { Display channel name(s) }
           Lab := Channel[ch].ADCName ;
           if FDrawGrid then begin
              Lab := Lab + format(' %.3g%s/div',
                     [Channel[ch].ADCScale*FMaxADCValue*0.2,Channel[ch].ADCUnits]) ;
              end ;
           Canvas.TextOut( Channel[ch].Left,
                         (Channel[ch].Top + Channel[ch].Bottom) div 2,
                         Lab ) ;

           x := Round(Channel[ch].xMin) ;
           for i := 0 to 2*FNumBlocks - 1 do begin
                j := (i*FNumChannels) + Channel[ch].ADCOffset ;
                xy^[i].y := Channel[ch].Bottom - Round(
                            Channel[ch].yScale*(FBuf^[j] - Channel[ch].yMin));
                xy^[i].x := Round(Channel[ch].xScale*(x -
                            Channel[ch].xMin) + Channel[ch].Left) ;
                if ((i mod 2) = 1) then x := x + 1 ;
                end ;
           OK := Polyline( Canvas.Handle, xy^, 2*FNumBlocks ) ;
           end ;


        if not FZoomMode then begin
           { Horizontal Cursors }

           for i := 0 to High(HorCursors) do if HorCursors[i].InUse
               and Channel[HorCursors[i].Channel].InUse then
               DrawHorizontalCursor(i) ;
           { Vertical Cursors }
           for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
               DrawVerticalCursor(i) ;
           end
        else begin
           { Zoom box }
           Canvas.TextOut( 0,0, ' Zoom In/Out' ) ;
           ZoomScreen.Left :=  XToScreenCoord(  Channel[FZoomCh], FZoomBox.Left ) ;
           ZoomScreen.Right := XToScreenCoord(  Channel[FZoomCh], FZoomBox.Right ) ;
           ZoomScreen.Top :=   YToScreenCoord(  Channel[FZoomCh], FZoomBox.Top ) ;
           ZoomScreen.Bottom := YToScreenCoord( Channel[FZoomCh], FZoomBox.Bottom ) ;
           Canvas.DrawFocusRect( ZoomScreen ) ;
           end ;

        { Time labels }
        Lab := format( FTFormat,[StartAtSample*FTScale] ) ;
        Canvas.TextOut( 1, Height - Canvas.TextHeight(Lab), Lab ) ;
        Lab := format( FTFormat,
               [(StartAtSample
                 + (FNumBlocksInDisplay*FBlockSize) div FNumChannels)*FTScale] ) ;
        Canvas.TextOut( Width - Canvas.TextWidth(Lab),
                        Height - Canvas.TextHeight(Lab), Lab ) ;

        { Notify a change in cursors }
        if Assigned(OnCursorChange) then OnCursorChange(Self) ;

        finally
           { Get rid of array }
           Dispose(xy) ;
           Canvas.Pen.Color := SaveColor ;
           end ;

     end ;


procedure TChartDisplay.GetADCSamples ;
{ ---------------------------------------------------------
  Create a compressed extraction of a block of sampled data
  ---------------------------------------------------------}
var
   Done : Boolean ;
   i : Integer ;
   NumSamplesPerBuffer : Integer ;
   NumBytesPerBuffer : Integer ;
   NumDisplayPoints : Integer ;
   y,ch,ChCounter,nBlock,ChOffset : Integer ;
   yMin : Array[0..ChannelLimit] of SmallInt ;
   yMax : Array[0..ChannelLimit] of SmallInt ;
   tMin : Array[0..ChannelLimit] of Integer ;
   tMax : Array[0..ChannelLimit] of Integer ;
   ADC : ^TSmallIntArray ;
begin

     { Create A/D sample buffer }

     { Calculate size of min./max. extraction block }
     FBlockSize := (FNumSamples*FNumChannels) div FMaxBlocksInDisplay ;
     if FBlockSize < FNumChannels then FBlockSize := FNumChannels ;
     FNumBlocksInDisplay := IntLimitTo( (FNumSamples*FNumChannels) div FBlockSize,
                                         32,
                                         FMaxBlocksInDisplay ) ;

     { Move data file pointer to start of data to be displayed }
     FileSeek( FFileHandle,
               (FStartAtSample*FNumChannels*2) + FNumBytesInHeader,
               0 ) ;

     { Initialise min./max. holders }
     for ch := 0 to FNumChannels-1 do begin
         yMax[ch] := FMinADCValue ;
         yMin[ch] := FMaxADCValue ;
         end ;

     { Scan through selected block of samples, calculating and storing
       min. and max. values within each block of size FFBlockSize }

     Done := False ;
     FNumBlocks := 0 ;
     NumDisplayPoints := 0 ;
     nBlock := 0 ;
     ChCounter := 0 ;
     NumSamplesPerBuffer := 256*FNumChannels ;
     NumBytesPerBuffer := NumSamplesPerBuffer*2 ;
     i := NumSamplesPerBuffer ;
     New(ADC) ;
     try
        while (not Done) do begin

           { Read next block of data from file when required }
           if i >= NumSamplesPerBuffer then begin
              if FileRead(FFileHandle,ADC^,NumBytesPerBuffer)
                 <> NumBytesPerBuffer then Done := True ;
              i := 0 ;
              end ;

           { Get sample value }
           y := ADC^[i] ;

           { Find min./max. }
           If y < YMin[ChCounter] Then begin
              YMin[ChCounter] := y ;
              TMin[ChCounter] := i ;
              end ;
           If y > YMax[ChCounter] Then begin
              YMax[ChCounter] := y ;
              TMax[ChCounter] := i ;
              end ;

           { Increment counters & pointers }
           Inc(i) ;
           Inc(ChCounter) ;
           if ChCounter >= FNumChannels then ChCounter := 0 ;
           Inc(nBlock) ;

           { Update compressed signal buffer, when full a block is in }

           if nBlock >= FBlockSize Then begin

              for ch := 0 to FNumChannels-1 do begin
                  ChOffset := Channel[ch].ADCOffset ;
                  { Keep traces within limits of their part of display area }
                  if yMin[ChOffset] < Round(Channel[ch].yMin) then
                     yMin[ChOffset] := Round(Channel[ch].yMin) ;
                  if yMax[ChOffset] < Round(Channel[ch].yMin) then
                     yMax[ChOffset] := Round(Channel[ch].yMin) ;
                  if yMin[ChOffset] > Round(Channel[ch].yMax) then
                     yMin[ChOffset] := Round(Channel[ch].yMax) ;
                  if yMax[ChOffset] > Round(Channel[ch].yMax) then
                     yMax[ChOffset] := Round(Channel[ch].yMax) ;
                  end ;

              { Add first of Min/max pair to display buffer }
              for ch := 0 to FNumChannels-1 do begin
                  if TMin[ch] <= TMax[ch] then FBuf^[NumDisplayPoints] := YMin[ch]
                                          else FBuf^[NumDisplayPoints] := YMax[ch] ;
                  Inc(NumDisplayPoints) ;
                  end ;

              { Add second of each Min/max pairs to display buffer }
              for ch := 0 to FNumChannels-1 do begin
                  if TMin[ch] > TMax[ch] then FBuf^[NumDisplayPoints] := YMin[ch]
                                         else FBuf^[NumDisplayPoints] := YMax[ch] ;
                  Inc(NumDisplayPoints) ;
                  end ;

              { Reset Min./Max. buffers }
              for ch := 0 to FNumChannels-1 do begin
                  yMax[ch] := FMinADCValue ;
                  yMin[ch] := FMaxADCValue ;
                  end ;

              nBlock := 0 ;
              Inc(FNumBlocks) ;
              if FNumBlocks >= FNumBlocksInDisplay then Done := True ;
              end ;
           end ;
     finally
           Dispose(ADC) ;
           end ;
     NewData := False ;
     end ;



procedure TChartDisplay.ClearHorizontalCursors ;
{ -----------------------------
  Remove all horizontal cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(HorCursors) do HorCursors[i].InUse := False ;
     end ;


function TChartDisplay.AddHorizontalCursor(
         iChannel : Integer ;       { Signal channel associated with cursor }
         Color : TColor ;           { Colour of cursor }
         UseAsZeroLevel : Boolean   { If TRUE indicates this is a zero level cursor }
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
       HorCursors[iCursor].Channel := iChannel ;
       HorCursors[iCursor].ZeroLevel := UseAsZeroLevel ;
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;


procedure TChartDisplay.DrawHorizontalCursor(
          iCurs : Integer
          ) ;
{ -----------------------
  Draw horizontal cursor
 ------------------------}
var
   yPix : Integer ;
   OldColor : TColor ;
   OldStyle : TPenStyle ;
   OldMode : TPenMode ;
begin
     with canvas do begin
          OldColor := pen.color ;
          OldStyle := pen.Style ;
          OldMode := pen.mode ;
          pen.mode := pmXor ;
          pen.color := HorCursors[iCurs].Color ;
          end ;

     yPix := YToScreenCoord( Channel[HorCursors[iCurs].Channel],
                             HorCursors[iCurs].Position ) ;

     Canvas.polyline( [Point(4,yPix),Point(Width-4,yPix)]);

     { If this cursor is being used as the zero baseline level for a signal
       channel, update the zero level for that channel }
     if HorCursors[iCurs].ZeroLevel then begin
        Channel[HorCursors[iCurs].Channel].ADCZero := HorCursors[iCurs].Position ;
        end ;

     with Canvas do begin
          pen.style := OldStyle ;
          pen.color := OldColor ;
          pen.mode := OldMode ;
          end ;

    end ;


procedure TChartDisplay.ClearVerticalCursors ;
{ -----------------------------
  Remove all vertical cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     end ;


function TChartDisplay.AddVerticalCursor(
         Color : TColor
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
       VertCursors[iCursor].Position := FNumBlocksInDisplay ;
       VertCursors[iCursor].InUse := True ;
       VertCursors[iCursor].Color := Color ;
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;



procedure TChartDisplay.DrawVerticalCursor(
          iCurs : Integer
          ) ;
{ -----------------------
  Draw vertical cursor
 ------------------------}
var
   xPix : Integer ;
   OldColor : TColor ;
   OldStyle : TPenStyle ;
   OldMode : TPenMode ;
begin
     with canvas do begin
          OldColor := pen.color ;
          OldStyle := pen.Style ;
          OldMode := pen.mode ;
          pen.mode := pmXor ;
          pen.color := VertCursors[iCurs].Color ;
          end ;

     xPix := XToScreenCoord( VertCursors[iCurs], VertCursors[iCurs].Position ) ;

     Canvas.polyline( [Point(xPix,VertCursors[iCurs].Top),
                       Point(xPix,VertCursors[iCurs].Bottom)]);

     with Canvas do begin
          pen.style := OldStyle ;
          pen.color := OldColor ;
          pen.mode := OldMode ;
          end ;

    end ;


procedure TChartDisplay.SetNumChannels(
          Value : Integer
          ) ;
{ ------------------------------------------
  Set the number of channels to be displayed
  ------------------------------------------ }
begin
     FNumChannels := IntLimitTo(Value,1,High(Channel)+1) ;
     end ;


procedure TChartDisplay.SetNumPoints(
          Value : Integer
          ) ;
{ -------------------------------------------
  Set the maximum number of points in display
  ------------------------------------------- }
begin
     FMaxBlocksInDisplay := IntLimitTo(Value,256,High(TSmallIntArray)) ;
     end ;


procedure TChartDisplay.SetNewData(
          Value : Boolean
          ) ;
{ --------------------------------------------------------------
  Set the new A/D sample data flag and reqeuest a display update
  -------------------------------------------------------------- }
begin
     FNewData := Value ;
     Invalidate ;
     end ;


procedure TChartDisplay.SetYMin(
          Ch : Integer ;
          Value : single
          ) ;
{ -------------------------
  Set the channel Y minimum
  ------------------------- }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].YMin := Value ;
     end ;


procedure TChartDisplay.SetYMax(
          Ch : Integer ;
          Value : single
          ) ;
{ -------------------------
  Set the channel Y maximum
  ------------------------- }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].YMax := Value ;
     end ;


function TChartDisplay.GetYMin(
         Ch : Integer
          ) : single ;
{ -------------------------
  Get the channel Y minimum
  ------------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].YMin ;
     end ;


function TChartDisplay.GetYMax(
         Ch : Integer
          ) : single ;
{ -------------------------
  Get the channel Y maximum
  ------------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].YMax ;
     end ;


procedure TChartDisplay.SetChanName(
          Ch : Integer ;
          Value : string
          ) ;
{ ------------------
  Set a channel name
  ------------------ }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].ADCName := Value ;
     end ;


procedure TChartDisplay.SetChanUnits(
          Ch : Integer ;
          Value : string
          ) ;
{ ------------------
  Set a channel units
  ------------------ }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].ADCUnits := Value ;
     end ;


procedure TChartDisplay.SetChanScale(
          Ch : Integer ;
          Value : single
          ) ;
{ ------------------------------------------------
  Set a channel A/D -> physical units scale factor
  ------------------------------------------------ }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].ADCScale := Value ;
     end ;


procedure TChartDisplay.SetChanCalBar(
          Ch : Integer ;
          Value : single
          ) ;
{ -----------------------------
  Set a channel calibration bar
  ----------------------------- }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].CalBar := Value ;
     end ;


procedure TChartDisplay.SetChanZero(
          Ch : Integer ;
          Value : Integer
          ) ;
{ ------------------------
  Set a channel zero level
  ------------------------ }
begin
     if (0 <= ch) and (ch < FNumChannels) then begin
        Channel[Ch].ADCZero := Value ;
        end ;
     end ;


procedure TChartDisplay.SetChanOffset(
          Ch : Integer ;
          Value : Integer
          ) ;
{ ---------------------------------------------
  Get data interleaving offset for this channel
  ---------------------------------------------}
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].ADCOffset := Value ;
     end ;


procedure TChartDisplay.SetChanVisible(
          Ch : Integer ;
          Value : boolean
          ) ;
{ ----------------------
  Set channel visibility
  ---------------------- }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].InUse := Value ;
     end ;


procedure TChartDisplay.SetChanColor(
          Ch : Integer ;
          Value : TColor
          ) ;
{ ----------------------
  Set channel colour
  ---------------------- }
begin
     if (0 <= ch) and (ch < FNumChannels) then Channel[Ch].Color := Value ;
     end ;


function TChartDisplay.GetChanName(
          Ch : Integer
          ) : string ;
{ ------------------
  Get a channel name
  ------------------ }
begin
     if (0 <= ch) and (ch < FNumChannels) then Result := Channel[Ch].ADCName ;
     end ;


function TChartDisplay.GetChanUnits(
          Ch : Integer
          ) : string ;
{ ------------------
  Get a channel units
  ------------------ }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].ADCUnits ;
     end ;


function TChartDisplay.GetChanScale(
          Ch : Integer
          ) : single ;
{ --------------------------------------------------
  Get a channel A/D -> physical units scaling factor
  -------------------------------------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].ADCScale ;
     end ;


function TChartDisplay.GetChanCalBar(
          Ch : Integer
          ) : single ;
{ -----------------------------------
  Get a channel calibration bar value
  ----------------------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].CalBar ;
     end ;


function TChartDisplay.GetChanZero(
          Ch : Integer
          ) : Integer ;
{ ----------------------------
  Get a channel A/D zero level
  ---------------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].ADCZero ;
     end ;


function TChartDisplay.GetChanOffset(
          Ch : Integer
          ) : Integer ;
{ ---------------------------------------------
  Get data interleaving offset for this channel
  ---------------------------------------------}
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].ADCOffset ;
     end ;


function TChartDisplay.GetChanVisible(
          Ch : Integer
          ) : boolean ;
{ ----------------------
  Get channel visibility
  ---------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].InUse ;
     end ;


function TChartDisplay.GetChanColor(
          Ch : Integer
          ) : TColor ;
{ ----------------------
  Get channel colour
  ---------------------- }
begin
     Ch := IntLimitTo(Ch,0,FNumChannels-1) ;
     Result := Channel[Ch].Color ;
     end ;


function TChartDisplay.GetHorCursor(
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


procedure TChartDisplay.SetHorCursor(
          iCursor : Integer ;           { Cursor # }
          Value : Integer               { New Cursor position }
          )  ;
{ ---------------------------------
  Set position of horizontal cursor
  ---------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(HorCursors)) ;
     HorCursors[iCursor].Position := Value ;
     Invalidate ;
     end ;


function TChartDisplay.GetVertCursor(
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


procedure TChartDisplay.SetVertCursor(
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


function TChartDisplay.GetSelectedVertCursor : Integer ;
{ -------------------------------------------------
  Return the number of the selected vertical cursor
  -------------------------------------------------}
begin
     if FVertCursorActive then Result := FVertCursorSelected
                          else Result := -1 ;
     end ;


procedure TChartDisplay.SetTFormat(
          Value : string
          ) ;
{ ---------------------
  Set time label format
  --------------------- }
begin
     FTFormat := Value ;
     end ;


function TChartDisplay.GetTFormat : string ;
{ ----------------------------
  Get time label format string
  ---------------------------- }
begin
     Result := FTFormat ;
     end ;

function TChartDisplay.GetBlockSize : Integer ;
{ ----------------------------
  Get size of min./max. block
  ---------------------------- }
begin
     Result := FBlockSize div FNumChannels ;
     end ;



function TChartDisplay.GetXScreenCoord(
         Value : Integer               { Index into display data array (IN) }
         ) : Integer ;
{ --------------------------------------------------------------------------
  Get the screen coordinate within the paint box from the data array index
  -------------------------------------------------------------------------- }
begin
     Result := XToScreenCoord( Channel[0], Value ) ;
     end ;


procedure TChartDisplay.SetPrinterFontName(
          Value : string
          ) ;
{ -----------------------
  Set printer font name
  ----------------------- }
begin
     FPrinterFontName := Value ;
     end ;


function TChartDisplay.GetPrinterFontName : string ;
{ -----------------------
  Get printer font name
  ----------------------- }
begin
     Result := FPrinterFontName ;
     end ;


procedure TChartDisplay.SetPrinterLeftMargin(
          Value : Integer                    { Left margin (mm) }
          ) ;
{ -----------------------
  Set printer left margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     try
        FPrinterLeftMargin := (Printer.PageWidth*Value)
                              div GetDeviceCaps( printer.handle, HORZSIZE ) ;
     except
        FPrinterLeftMargin := 0 ;
        end ;
     end ;


function TChartDisplay.GetPrinterLeftMargin : integer ;
{ ----------------------------------------
  Get printer left margin (returned in mm)
  ---------------------------------------- }
begin
     Try
        Result := (FPrinterLeftMargin*GetDeviceCaps(Printer.Handle,HORZSIZE))
               div Printer.PageWidth ;
     except
        Result := 0 ;
        end ;
     end ;


procedure TChartDisplay.SetPrinterRightMargin(
          Value : Integer                    { Right margin (mm) }
          ) ;
{ -----------------------
  Set printer Right margin
  ----------------------- }
begin
     { Printe
     r pixel height (mm) }
     Try
        FPrinterRightMargin := (Printer.PageWidth*Value)
                           div GetDeviceCaps( printer.handle, HORZSIZE ) ;
     except
        FPrinterRightMargin := 0 ;
        end ;
     end ;


function TChartDisplay.GetPrinterRightMargin : integer ;
{ ----------------------------------------
  Get printer Right margin (returned in mm)
  ---------------------------------------- }
begin
     try
        Result := (FPrinterRightMargin*GetDeviceCaps(Printer.Handle,HORZSIZE))
                  div Printer.PageWidth ;
     except
        Result := 0 ;
        end ;
     end ;


procedure TChartDisplay.SetPrinterTopMargin(
          Value : Integer                    { Top margin (mm) }
          ) ;
{ -----------------------
  Set printer Top margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     try
        FPrinterTopMargin := (Printer.PageHeight*Value)
                           div GetDeviceCaps( printer.handle, VERTSIZE ) ;
     except
        FPrinterTopMargin := 0 ;
        end ;
     end ;


function TChartDisplay.GetPrinterTopMargin : integer ;
{ ----------------------------------------
  Get printer Top margin (returned in mm)
  ---------------------------------------- }
begin
     try
        Result := (FPrinterTopMargin*GetDeviceCaps(Printer.Handle,VERTSIZE))
               div Printer.PageHeight ;
     except
        Result := 0 ;
        end ;
     end ;


procedure TChartDisplay.SetPrinterBottomMargin(
          Value : Integer                    { Bottom margin (mm) }
          ) ;
{ -----------------------
  Set printer Bottom margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     try
        FPrinterBottomMargin := (Printer.PageHeight*Value)
                                div GetDeviceCaps( printer.handle, VERTSIZE ) ;
     except
        FPrinterBottomMargin := 0 ;
        end ;
     end ;


function TChartDisplay.GetPrinterBottomMargin : integer ;
{ ----------------------------------------
  Get printer Bottom margin (returned in mm)
  ---------------------------------------- }
begin
     try
        Result := (FPrinterBottomMargin*GetDeviceCaps(Printer.Handle,VERTSIZE))
               div Printer.PageHeight ;
     except
        Result := 0 ;
        end ;
     end ;


procedure TChartDisplay.SetGrid(
          Value : Boolean                    { True=storage mode on }
          ) ;
{ ---------------------------
  Enable/disable display grid
  --------------------------- }
begin
     FDrawGrid := Value ;
     Invalidate ;
     end ;


{ ******************************************************************** }



procedure TChartDisplay.MouseDown(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;

begin
     Inherited MouseDown( Button, Shift, X, Y ) ;

     if FHorCursorSelected > -1  then FHorCursorActive := True ;

     if (not FHorCursorActive)
        and (FVertCursorSelected > -1) then FVertCursorActive := True ;

     FMoveZoomBox := True ;

     end ;


procedure TChartDisplay.MouseUp(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;
begin
     Inherited MouseUp( Button, Shift, X, Y ) ;

     FHorCursorActive := false ;
     FVertCursorActive := false ;
     FMoveZoomBox := false ;
     end ;


procedure TChartDisplay.MouseMove(
          Shift: TShiftState;
          X, Y: Integer) ;
{ --------------------------------------------------------
  Select/deselect cursors as mouse is moved over display
  -------------------------------------------------------}
var
   ch : Integer ;
begin
     Inherited MouseMove( Shift, X, Y ) ;

     { Find and store channel mouse is over }
     for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
         if (Channel[ch].Top <= Y) and (Y <= Channel[ch].Bottom) then
            FMouseOverChannel := ch ;
         end ;

     if FZoomMode then begin
        ProcessZoomBox( X, Y ) ;
        end
     else begin
        { Find/move any active horizontal cursor }
        ProcessHorizontalCursors( Y ) ;

        { Find/move any active vertical cursor }
        if not FHorCursorActive then ProcessVerticalCursors( X ) ;

        { Set type of cursor icon }
        if FHorCursorSelected > -1 then Cursor := crSizeNS
        else if FVertCursorSelected > -1 then Cursor := crSizeWE
                                         else Cursor := crDefault ;
        end ;


     end ;


procedure TChartDisplay.DblClick ;
{ -------------------------------------------------
  Switch between zoom control / normal display mode
  -------------------------------------------------}
begin
     if not FZoomMode then SwitchToZoomMode( FMouseOverChannel )
                      else SwitchToNormalMode ;
     Invalidate ;
     end ;

procedure TChartDisplay.SwitchToZoomMode(
          Chan : Integer
          ) ;
{ ----------------------------------------------------
  Switch display to zoom in/out mode on channel "Chan"
  ---------------------------------------------------- }
var
   ch : Integer ;
begin
     FZoomCh := Chan ;
     FZoomMode := True ;
     for ch := 0 to FNumChannels-1 do begin
         KeepChannel[ch] := Channel[ch] ;
         if ch = FZoomCh then begin
            { Determine block size for displaying whole record }
            FBlockSize := (FMaxSamples*FNumChannels) div FMaxBlocksInDisplay ;
            if FBlockSize < FNumChannels then FBlockSize := FNumChannels ;
            { Calculate zoom box position }
            FZoomBox.Bottom := Round(Channel[ch].yMin) ;
            FZoomBox.Top := Round(Channel[ch].yMax) ;
            FZoomBox.Left := FStartAtSample div (FBlockSize div FNumChannels) ;
            FZoomBox.Right := IntLimitTo( (FStartAtSample + FNumSamples -1)
                                          div (FBlockSize div FNumChannels),
                                          0,
                                          FMaxBlocksInDisplay ) ;
            Channel[ch].InUse := True ;
            Channel[ch].yMin := FMinADCValue ;
            Channel[ch].yMax := FMaxADCValue ;
            FStartAtSample := 0 ;
            FNumSamples := FMaxSamples ;
            end
         else Channel[ch].InUse := False ;
         end ;
     end ;


procedure TChartDisplay.SwitchToNormalMode ;
{ -------------------------------------
  Switch to normal display mode
  ----------------------------- }
var
   ch : Integer ;
begin
    FZoomMode := False ;
    for ch := 0 to FNumChannels-1 do begin
        if ch = FZoomCh then begin
           Channel[ch].InUse := True ;
           Channel[ch].yMin := FZoomBox.Bottom ;
           Channel[ch].yMax := FZoomBox.Top ;
           FStartAtSample :=  FZoomBox.Left*(FBlockSize div FNumChannels) ;
           FNumSamples := FZoomBox.Right*(FBlockSize div FNumChannels)
                          - FStartAtSample + 1 ;
           end
        else Channel[ch] := KeepChannel[ch] ;
        end ;
    end ;


procedure TChartDisplay.ZoomIn(
          Chan : Integer
          ) ;
{ -----------------------------------------------------------
  Switch to zoom in/out mode on selected chan (External call)
  ----------------------------------------------------------- }
begin
     SwitchToZoomMode( Chan ) ;
     Invalidate ;
     end ;


procedure TChartDisplay.ZoomOut ;
{ ---------------------------------
  Zoom out to minimum magnification
  ---------------------------------}
var
   ch : Integer ;
begin
     FZoomMode := False ;
     for ch := 0 to FNumChannels-1 do begin
         Channel[ch].yMin := FMinADCValue ;
         Channel[ch].yMax := FMaxADCValue ;
         FStartAtSample :=  0 ;
         FNumSamples := FMaxSamples ;
         end ;
     Invalidate ;
     end ;



procedure TChartDisplay.ProcessHorizontalCursors(
          Y : Integer
          ) ;
{ ----------------------------------
  Find/move active horizontal cursor
  ----------------------------------}
const
     Margin = 4 ;
var
   YPosition,i,CurCh : Integer ;
begin

     if FHorCursorActive and (FHorCursorSelected > -1) then begin

        { *** Move the currently activated cursor to a new position *** }
        CurCh := HorCursors[FHorCursorSelected].Channel ;
        { Remove the old cursor }
        DrawHorizontalCursor( FHorCursorSelected ) ;
        { Keep within channel display area }
        Y := IntLimitTo( Y,Channel[CurCh].Top,Channel[CurCh].Bottom ) ;
        { Update cursor position (in terms of signal level) }
        HorCursors[FHorCursorSelected].Position := ScreenToYCoord(Channel[CurCh],Y) ;
        { Draw new cursor }
        DrawHorizontalCursor( FHorCursorSelected ) ;
        { Notify a change in cursors }
        if Assigned(OnCursorChange) then OnCursorChange(Self) ;

        end
     else begin

        { *** Find the active horizontal cursor (if any) *** }

        FHorCursorSelected := -1 ;
        for i := 0 to High(HorCursors) do
            if HorCursors[i].InUse and Channel[HorCursors[i].Channel].InUse then begin
            YPosition := YToScreenCoord( Channel[HorCursors[i].Channel],
                                         HorCursors[i].Position ) ;
            if Abs(Y - YPosition) <= Margin then FHorCursorSelected := i ;
            end ;
        end ;
     end ;


procedure TChartDisplay.ProcessVerticalCursors(
          X : Integer                          { X mouse coord (IN) }
          ) ;
{ --------------------------------
  Find/move active vertical cursor
  --------------------------------}
const
     Margin = 4 ;
var
   XPosition,i : Integer ;
begin

     if FVertCursorActive and (FVertCursorSelected > -1) then begin

        { *** Move the currently activated cursor to a new position *** }

        { Remove the old cursor }
        DrawVerticalCursor( FVertCursorSelected ) ;
        { Keep within channel display area }
        X := IntLimitTo( X,
                         VertCursors[FVertCursorSelected].Left,
                         VertCursors[FVertCursorSelected].Right ) ;
        { Update cursor position (as index into data array) }
        VertCursors[FVertCursorSelected].Position := ScreenToXCoord(
                                                  VertCursors[FVertCursorSelected], X ) ;
        { Draw new cursor }
        DrawVerticalCursor( FVertCursorSelected ) ;
        { Notify a change in cursors }
        if Assigned(OnCursorChange) then OnCursorChange(Self) ;
        end
     else begin

        { *** Find the active vertical cursor (if any) *** }

        FVertCursorSelected := -1 ;
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then begin
            XPosition := XToScreenCoord(VertCursors[i],VertCursors[i].Position) ;
            if Abs(X - XPosition) <= Margin then FVertCursorSelected := i ;
            end ;
        end ;
     end ;


procedure TChartDisplay.ProcessZoomBox(
          X : Integer ;      { Mouse X Coord (IN) }
          Y : Integer ) ;    { Mouse Y Coord (IN) }
{ ------------------------------------------------------------
  Update size/location of display magnification adjustment box
  ------------------------------------------------------------}
const
     Margin = 4 ;
     ZoomMin = 0 ;
var
   ZoomScreen : TRect ;
   BoxWidth,BoxHeight : Integer ;
begin

     { Calculate zoom rectangle in screen coords. }
     ZoomScreen.Left :=   XToScreenCoord( Channel[FZoomCh], FZoomBox.Left ) ;
     ZoomScreen.Right :=  XToScreenCoord( Channel[FZoomCh], FZoomBox.Right ) ;
     ZoomScreen.Top :=    YToScreenCoord( Channel[FZoomCh], FZoomBox.Top ) ;
     ZoomScreen.Bottom := YToScreenCoord( Channel[FZoomCh], FZoomBox.Bottom ) ;

     if FMoveZoomBox then begin

        Canvas.DrawFocusRect( ZoomScreen ) ;

        { Move the part of the zoom box which is under the mouse }

        case MousePos of
          MTop : Begin
              { Move top margin of zoom box }
              if (ZoomScreen.Bottom-Y) > ZoomMin then ZoomScreen.Top := Y ;
              end ;
          MBottom : Begin
              { Move bottom margin }
              if Abs(Y - ZoomScreen.Top) > ZoomMin then ZoomScreen.Bottom := Y ;
              end ;
          MLeft : Begin
              { Move left margin }
              if (ZoomScreen.Right-X) > ZoomMin then ZoomScreen.Left := X ;
              end ;
          MRight : Begin
              { Move right margin }
              if (X - ZoomScreen.Left) > ZoomMin then ZoomScreen.Right := X ;
              end ;
          MDrag : begin
              { Move whole box }
              BoxWidth := ZoomScreen.Right - ZoomScreen.Left ;
              BoxHeight := ZoomScreen.Bottom - ZoomScreen.Top ;
              ZoomScreen.Left := IntLimitTo( ZoomScreen.Left + (X - FXOld),
                                             Channel[FZoomCh].Left,
                                             Channel[FZoomCh].Right - BoxWidth ) ;
              ZoomScreen.Right := ZoomScreen.Left + BoxWidth ;
              ZoomScreen.Top := IntLimitTo( ZoomScreen.Top + (Y - FYOld),
                                            Channel[FZoomCh].Top,
                                            Channel[FZoomCh].Bottom - BoxHeight ) ;
              ZoomScreen.Bottom := ZoomScreen.Top + BoxHeight ;
              FXOld := X ;
              FYOld := Y ;
              end ;
          else
          end ;

          { Keep within bounds }

        ZoomScreen.Left :=      IntLimitTo(ZoomScreen.Left,
                                           Channel[FZoomCh].Left,
                                           Channel[FZoomCh].Right ) ;
        ZoomScreen.Right :=     IntLimitTo(ZoomScreen.Right,
                                           Channel[FZoomCh].Left,
                                           Channel[FZoomCh].Right ) ;
        ZoomScreen.Top :=       IntLimitTo(ZoomScreen.Top,
                                           Channel[FZoomCh].Top,
                                           Channel[FZoomCh].Bottom ) ;
        ZoomScreen.Bottom :=    IntLimitTo(ZoomScreen.Bottom,
                                           Channel[FZoomCh].Top,
                                           Channel[FZoomCh].Bottom ) ;

        Canvas.DrawFocusRect( ZoomScreen ) ;

             { Calculate zoom rectangle in screen coords. }
        FZoomBox.Left :=  ScreenToXCoord( Channel[FZoomCh], ZoomScreen.Left ) ;
        FZoomBox.Right := ScreenToXCoord( Channel[FZoomCh], ZoomScreen.Right ) ;
        FZoomBox.Top :=   ScreenToYCoord( Channel[FZoomCh], ZoomScreen.Top ) ;
        FZoomBox.Bottom := ScreenToYCoord( Channel[FZoomCh], ZoomScreen.Bottom ) ;

        end
     else begin

        { *** Determine if the mouse is over part of the zoom box *** }

        if (Abs(X - ZoomScreen.Left) < Margin ) and
           (Y <= ZoomScreen.Bottom) and (Y >= ZoomScreen.Top ) then begin
           { Left margin }
            Cursor := crSizeWE ;
            MousePos := MLeft ;
            end
        else if (Abs(X - ZoomScreen.Right) < Margin) and
               (Y <= ZoomScreen.Bottom) and (Y >= ZoomScreen.Top ) then begin
            { Right margin }
            Cursor := crSizeWE ;
            MousePos := MRight ;
            end
        else if (Abs(Y - ZoomScreen.Top) < Margin) and
              (X <= ZoomScreen.Right) and (X >= ZoomScreen.Left ) then begin
            { Top margin }
            Cursor := crSizeNS ;
            MousePos := MTop ;
            end
        else if (Abs(Y - ZoomScreen.Bottom) < Margin ) and
               (X <= ZoomScreen.Right) and (X >= ZoomScreen.Left ) then begin
            { Bottom margin }
            Cursor := crSizeNS ;
            MousePos := MBottom ;
            end
        else if (ZoomScreen.Bottom > Y) and (Y > ZoomScreen.Top) and
                (ZoomScreen.Right > X) and (X > ZoomScreen.Left) then begin
            { Cursor within zoom box }
            Cursor := CrSize ;
            MousePos := MDrag ;
            FXOld := X ;
            FYOld := Y ;
            end
        else
            Cursor := crDefault ;

        end ;
     end ;



function TChartDisplay.IntLimitTo(
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


function TChartDisplay.XToScreenCoord(
         const Chan : TScopeChannel ;
         Value : Integer
         ) : Integer  ;
begin
     Result := Round( (Value - Chan.xMin)*Chan.xScale + Chan.Left ) ;
     end ;


function TChartDisplay.ScreenToXCoord(
         const Chan : TScopeChannel ;
         xPix : Integer
         ) : Integer  ;
begin
     Result := Round((xPix - Chan.Left)/Chan.xScale - Chan.xMin) ;
     end ;


function TChartDisplay.YToScreenCoord(
         const Chan : TScopeChannel ;
         Value : Integer
         ) : Integer  ;
begin
     Result := Round( Chan.Bottom - (Value - Chan.yMin)*Chan.yScale ) ;
     end ;


function TChartDisplay.ScreenToYCoord(
         const Chan : TScopeChannel ;
         yPix : Integer
         ) : Integer  ;
begin
     Result := Round( (Chan.Bottom - yPix)/Chan.yScale + Chan.yMin ) ;
     end ;




procedure TChartDisplay.GetDataValues(
          Index : Integer ;            { Data array index (IN) }
          Ch : Integer ;               { Data channel (IN) }
          var MinValue : Integer ;     { Minimum value (OUT) }
          var MaxValue : Integer       { Maximum value (OUT) }
          ) ;
{ ----------------------------------------------------------------------
  Get the min./max. data values for a point in the compressed data array
  ----------------------------------------------------------------------}
var
   i0,i1 : Integer ;
begin
     { Keep channel and index within valid limits }
     Ch := IntLimitTo( Ch, 0, FNumChannels-1 ) ;
     Index := IntLimitTo( Index, 0, FNumBlocks-1 ) ;

     { Extract min./max. data values for this index position in data array }

     i0 := (Index*FNumChannels*2) + Channel[Ch].ADCOffset ;
     i1 := i0 + FNumChannels ;
     if FBuf^[i0] < FBuf^[i1] then begin
        MinValue := FBuf^[i0] ;
        MaxValue := FBuf^[i1] ;
        end
     else begin
        MinValue := FBuf^[i1] ;
        MaxValue := FBuf^[i0] ;
        end ;
     end ;



procedure TChartDisplay.CopyDataToClipBoard ;
{ ------------------------------------------------
  Copy the data points on display to the clipboard
  ------------------------------------------------}
var
   i,j,ch,BufSize : Integer ;
   t : single ;
   CopyBuf : PChar ;

begin

     // Open clipboard preventing others acceessing it
     Clipboard.Open ;



        // Determine size of and allocate string buffer
        BufSize := 1 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then BufSize := BufSize + 1 ;
        BufSize := BufSize*10*(FNumBlocks*2) ;
        CopyBuf := StrAlloc( BufSize ) ;

     try
        StrCopy(CopyBuf,PChar('')) ;

        //i := 0 ;
        //j := 0 ;
        Screen.Cursor := crHourglass ;
        t := 0.0 ;
        for i := 0 to (FNumBlocks*2)-1 do begin

            // Time
            StrCat(CopyBuf,PChar(format( '%.4g', [t] ))) ;

            for ch := 0 to FNumChannels-1 do begin
                j := (i*FNumChannels) + Channel[ch].ADCOffset ;
                if Channel[ch].InUse then begin
                   StrCat(CopyBuf,
                      PChar(Format(#9'%.4g',
                      [(FBuf^[j] - Channel[ch].ADCZero)*Channel[ch].ADCScale] ))) ;
                   end ;
                 end ;

            // CR+LF at end of line
            StrCat(CopyBuf, PChar(#13#10)) ;

            if (i mod 2) = 1 then t := t + (FBlockSize div FNumChannels)*FTScale ;
            end ;

         // Copy text accumulated in copy buffer to clipboard
         ClipBoard.SetTextBuf( PChar(CopyBuf) ) ;

     finally
         screen.cursor := crDefault ;
         // Free buffer
         StrDispose(CopyBuf) ;
         // Release clipboard
         Clipboard.Close ;
         end ;
     end ;


procedure TChartDisplay.Print ;
{ ---------------------------------
  Copy signal on display to printer
  ---------------------------------
  3/4/99 Polyline function replaced by .LineTo() because it was
         causing a printing to hang up for unknown reason }
var
   i,j,n,ch,LastCh,xPix, yPix : Integer ;
   x : single ;
   LeftMarginShift, TopMarginShift : Integer ;
   OK : Boolean ;
   ChannelHeight,cTop,NumInUse,AvailableHeight : Integer ;
   PrChan : Array[0..ChannelLimit] of TScopeChannel ;
   Bar : TRect ;
   Lab : string ;
begin
     { Create plotting points array }
     Printer.BeginDoc ;
     Screen.Cursor := crHourglass ;

     try

        Printer.Canvas.Pen.Color := clBlack ;
        Printer.Canvas.font.Name := FPrinterFontName ;
        Printer.Canvas.font.size := FPrinterFontSize ;
        Printer.Canvas.Pen.Width := FPrinterPenWidth ;

        { Determine number of channels in use and the height
          available for each channel }
        AvailableHeight := Printer.PageHeight
                           - FPrinterBottomMargin
                           - FPrinterTopMargin
                           - (3 + FTitle.Count)*Printer.Canvas.TextHeight('X') ;
        NumInUse := 0 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then Inc(NumInUse) ;
        if NumInUse < 1 then NumInUse := 1 ;
        ChannelHeight := AvailableHeight div NumInUse ;

        { Make space at left margin for channel names/cal. bars }
        LeftMarginShift := 0 ;
        for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
            Lab := format( '%.3g %s ', [PrChan[ch].CalBar,PrChan[ch].ADCUnits] )
                   + Channel[ch].ADCName + ' ' ;;
            if (LeftMarginShift < Printer.Canvas.TextWidth(Lab)) then
               LeftMarginShift := Printer.Canvas.TextWidth(Lab) ;
            end ;

        { Define display area for each channel in use }
        cTop := FPrinterTopMargin ;
        for ch := 0 to FNumChannels-1 do begin
            PrChan[ch] := Channel[ch] ;
            if Channel[ch].InUse then begin
               if FPrinterDisableColor then PrChan[ch].Color := clBlack ;
               PrChan[ch].Left := FPrinterLeftMargin + LeftMarginShift ;
               PrChan[ch].Right := Printer.PageWidth - FPrinterRightMargin ;
               PrChan[ch].Top := cTop ;
               PrChan[ch].Bottom := PrChan[ch].Top + ChannelHeight ;
               PrChan[ch].xScale := (PrChan[ch].Right - PrChan[ch].Left) /
                                    (PrChan[ch].xMax - PrChan[ch].xMin ) ;
               PrChan[ch].yScale := (PrChan[ch].Bottom - PrChan[ch].Top) /
                                    (PrChan[ch].yMax - PrChan[ch].yMin ) ;
               cTop := cTop + ChannelHeight ;
               end ;
            end ;

        { Plot channel }
        for ch := 0 to FNumChannels-1 do
           if PrChan[ch].InUse and (FBuf <> Nil) then begin

           { Display channel name(s) }
           if FPrinterShowLabels then begin
              Lab := PrChan[ch].ADCName + ' ' ;
              Printer.Canvas.TextOut( PrChan[ch].Left - Printer.Canvas.TextWidth(Lab),
                                      (PrChan[ch].Top + PrChan[ch].Bottom) div 2,
                                      Lab ) ;
              end ;

           x := PrChan[ch].xMin ;
           for i := 0 to 2*FNumBlocks - 1 do begin
                j := (i*FNumChannels) + PrChan[ch].ADCOffset ;
                yPix := YToScreenCoord( PrChan[ch], FBuf^[j] );
                xPix := XToScreenCoord( PrChan[ch], Round(x) ) ;
                if i = 0 then Printer.Canvas.MoveTo( xPix, yPix ) ;
                Printer.Canvas.LineTo( xPix, yPix ) ;
                if ((i mod 2) = 1) then x := x + 1.0 ;
                end ;

           { Draw baseline levels }
           if FPrinterShowZeroLevels then begin
              Printer.Canvas.Pen.Style := psDot ;
              Printer.Canvas.Pen.Width := 1 ;
              YPix := YToScreenCoord( PrChan[ch], PrChan[ch].ADCZero ) ;
              Printer.Canvas.MoveTo( PrChan[ch].Left,  YPix ) ;
              Printer.Canvas.LineTo( PrChan[ch].Right, YPix ) ;
              Printer.Canvas.Pen.Style := psSolid ;
              Printer.Canvas.Pen.Width := FPrinterPenWidth ;
              end ;

           end ;


       if FPrinterShowLabels then begin
          { Draw vertical calibration bars }
          LastCh := 0 ;
          for ch := 0 to FNumChannels-1 do
              if PrChan[ch].InUse and (PrChan[ch].CalBar <> 0.0) then begin
              { Bar label }
              Lab := format( '%.3g %s ', [PrChan[ch].CalBar,PrChan[ch].ADCUnits] ) ;
              { Calculate position/size of bar }
              Bar.Left := PrChan[ch].Left - Printer.Canvas.TextWidth(Lab+' ') div 2
                          - Printer.Canvas.TextWidth(PrChan[ch].ADCName) ;
              Bar.Right := Bar.Left + Printer.Canvas.TextWidth('X') ;
              Bar.Bottom := PrChan[ch].Bottom ;
              Bar.Top := Bar.Bottom
                         - Abs( YToScreenCoord( PrChan[ch],
                                Round(PrChan[ch].CalBar/PrChan[ch].ADCScale))
                                - YToScreenCoord( PrChan[ch],0) ) ;
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
          Lab := format( FTFormat, [FTCalBar] ) ;
          { Calculate position/size of bar }
          for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
              Bar.Top := PrChan[ch].Bottom + Printer.Canvas.TextHeight(Lab) ;
              LastCh := ch ;
              end ;
          Bar.Bottom := Bar.Top + Printer.Canvas.TextHeight(Lab) div 2 ;
          Bar.Left := PrChan[LastCh].Left ;
          Bar.Right := Bar.Left
                       + Round((PrChan[LastCh].xScale*FTCalBar)/(FBlockSize*FTScale)) ;
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

          { Draw printer title }
          for i := 0 to FTitle.Count-1 do
              Printer.Canvas.TextOut( FPrinterLeftMargin,
                                   FPrinterTopMargin + i*Printer.Canvas.TextHeight('X'),
                                   FTitle.Strings[i] ) ;
          end ;

     finally
           { Close down printer }
           Printer.EndDoc ;
           Screen.Cursor := crDefault ;
           end ;

     end ;


procedure TChartDisplay.CopyImageToClipboard ;
{ -----------------------------------------
  Copy signal image on display to clipboard
  21/2/00
  -----------------------------------------}
var
   i,j,n,ch,LastCh,XPix,YPix : Integer ;
   x : single ;
   LeftMarginShift, TopMarginShift : Integer ;
   OK : Boolean ;
   ChannelHeight,cTop,NumInUse,AvailableHeight : Integer ;
   MFChan : Array[0..ChannelLimit] of TScopeChannel ;
   xy : ^TPointArray ;
   Bar : TRect ;
   Lab : string ;
   TMF : TMetafile ;
   TMFC : TMetafileCanvas ;
begin

     { Create plotting points array }
     New(xy) ;
     Screen.Cursor := crHourglass ;

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

            { Make the size of the canvas the same as the displayed area
              AGAIN ... See above. Not sure why we need to do this again
              but clipboard image doesn't come out right if we don't}
            TMF.Width := FMetafileWidth ;
            TMF.Height := FMetafileHeight ;
            { ** NOTE ALSO The above two lines MUST come
              BEFORE the setting of the plot margins next }


            { Determine number of channels in use and the height
              available for each channel. NOTE This includes 3
              lines at bottom for time calibration bar }
            NumInUse := 0 ;
            AvailableHeight := TMF.Height - 4*TMFC.TextHeight('X') - 4 ;
            for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then Inc(NumInUse) ;
            if NumInUse < 1 then NumInUse := 1 ;
            ChannelHeight := AvailableHeight div NumInUse ;

            { Make space at left margin for channel names/cal. bars }
            LeftMarginShift := 0 ;
            for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                Lab := format( '%.3g %s ', [MFChan[ch].CalBar,MFChan[ch].ADCUnits] )
                       + Channel[ch].ADCName + ' ' ;
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
                   MFChan[ch].Bottom := MFChan[ch].Top + ChannelHeight ;
                   MFChan[ch].xScale := (MFChan[ch].Right - MFChan[ch].Left) /
                                        (MFChan[ch].xMax - MFChan[ch].xMin ) ;
                   MFChan[ch].yScale := (MFChan[ch].Bottom - MFChan[ch].Top) /
                                        (MFChan[ch].yMax - MFChan[ch].yMin ) ;
                   cTop := cTop + ChannelHeight ;
                   end ;
                end ;

            { Plot channel }
            for ch := 0 to FNumChannels-1 do
                if MFChan[ch].InUse and (FBuf <> Nil) then begin

                TMFC.Pen.Color := MFChan[ch].Color ;

                { Display channel name(s) }
                if FPrinterShowLabels then begin
                   Lab := MFChan[ch].ADCName + ' ' ;
                   TMFC.TextOut( MFChan[ch].Left - TMFC.TextWidth(Lab),
                                 ( MFChan[ch].Top + MFChan[ch].Bottom) div 2,
                                 Lab ) ;
                   end ;

                x := MFChan[ch].xMin ;
                for i := 0 to 2*FNumBlocks - 1 do begin
                    j := (i*FNumChannels) + MFChan[ch].ADCOffset ;
                    yPix := YToScreenCoord( MFChan[ch], FBuf^[j] );
                    xPix := XToScreenCoord( MFChan[ch], Round(x) ) ;
                    if i = 0 then TMFC.MoveTo( xPix, yPix ) ;
                    TMFC.LineTo( xPix, yPix ) ;
                    if ((i mod 2) = 1) then x := x + 1.0 ;
                    end ;

                { Draw baseline levels }
                if FPrinterShowZeroLevels then begin
                   TMFC.Pen.Style := psDot ;
                   TMFC.Pen.Width := 1 ;
                   YPix := YToScreenCoord( MFChan[ch], MFChan[ch].ADCZero ) ;
                   TMFC.MoveTo( MFChan[ch].Left,  YPix ) ;
                   TMFC.LineTo( MFChan[ch].Right, YPix ) ;
                   TMFC.Pen.Style := psSolid ;
                   TMFC.Pen.Width := FPrinterPenWidth ;
                   end ;

                end ;

           TMFC.Pen.Color := clBlack ;
           if FPrinterShowLabels then begin
              { Draw vertical calibration bars }
              LastCh := 0 ;
              for ch := 0 to FNumChannels-1 do
                 if MFChan[ch].InUse and (MFChan[ch].CalBar <> 0.0) then begin
                 { Bar label }
                 Lab := format( '%.3g %s ', [MFChan[ch].CalBar,MFChan[ch].ADCUnits] ) ;
                 { Calculate position/size of bar }
                 Bar.Left := MFChan[ch].Left - TMFC.TextWidth(Lab+' ') div 2
                             - TMFC.TextWidth(MFChan[ch].ADCName) ;
                 Bar.Right := Bar.Left + TMFC.TextWidth('X') ;
                 Bar.Bottom := MFChan[ch].Bottom ;
                 Bar.Top := Bar.Bottom
                            - Abs( YToScreenCoord( MFChan[ch],
                                  Round(MFChan[ch].CalBar/MFChan[ch].ADCScale))
                            - YToScreenCoord( MFChan[ch],0) ) ;
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
              Lab := format( FTFormat, [FTCalBar] ) ;
              { Calculate position/size of bar }
              for ch := 0 to FNumChannels-1 do if Channel[ch].InUse then begin
                  Bar.Top := MFChan[ch].Bottom + TMFC.TextHeight(Lab) ;
                  LastCh := ch ;
                  end ;
              Bar.Bottom := Bar.Top + TMFC.TextHeight(Lab) div 2 ;
              Bar.Left := MFChan[LastCh].Left ;
              Bar.Right := Bar.Left
                         + Round((MFChan[LastCh].xScale*FTCalBar)/(FBlockSize*FTScale)) ;
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
              end ;

        finally
            { Free metafile canvas. Note this copies plot into metafile object }
            TMFC.Free ;
            end ;

        { Copy metafile to clipboard }
        Clipboard.Assign(TMF) ;

     finally
           { Get rid of array }
           Dispose(xy) ;
           Screen.Cursor := crDefault ;
           end ;

     end ;


procedure TChartDisplay.ClearPrinterTitle ;
{ -------------------------
  Clear printer title lines
  -------------------------}
begin
     FTitle.Clear ;
     end ;

procedure TChartDisplay.AddPrinterTitleLine(
          Line : string
          );
{ ---------------------------
  Add a line to printer title
  ---------------------------}
begin
     FTitle.Add( Line ) ;
     end ;


function MaxInt(
         const Buf : array of Integer  { List of numbers (IN) }
         ) : Integer ;                 { Returns maximum of Buf }
{ ---------------------------------------------------------
  Return the largest long integer value in the array 'Buf'
  ---------------------------------------------------------}
var
   Max : Integer ;
   i : Integer ;
begin
     Max:= -High(Max) ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;

function MinInt(
         const Buf : array of Integer { List of numbers (IN) }
         ) : Integer ;                { Returns Minimum of Buf }
{ -------------------------------------------
  Return the smallest value in the array 'Buf'
  -------------------------------------------}
var
   i,Min : Integer ;
begin
     Min := High(Min) ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;



end.
