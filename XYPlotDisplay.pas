unit XYPlotDisplay;
{ ================================================
  Line graph/histogram display component
  (c) J. Dempster, University of Strathclyde, 1999
  ================================================
 12/3/99 Started
 23/6/99 Square root axis type added
 18/7/99 Percentage and Cumulative Y axis options added
 25/2/00 ClearAllLines public procedure added
 7/01 Super/subscripts and certain symbols now supported
 20/7/01 ... CopyDataToClipboard now allocates its own string buffer space
 28/11/02 ... Spurious character at beginning of data copied to clipboard
              by CopyDataToClipboard now removed.
 3.04.03 .... Error when no printers are defined now fixed
 22.04.03 ... Error when no. of points added exceeds buffer capacity fixed
 22.06.05 ... Clipboard copy functions now exit if no lines
 21.12.06 ... Empty graph now displayed as white box
              Lines now cleared when MaxPointsPerLine set
              ClearAllLines now deallocates XYBuf memory
              XYBuf memory allocation/deallocation now works reliably
 10.07.07 ... Vertical cursor readout value now displayed below X axis
              when cursor label = '?r'
 11.05.09 ... .Paint blocked during .Print or .CopyImageToClipboard
 10.06.09 ... Horizontal cursors added
 05.03.10 ... msPLus and msMinus marker styles added
 22.06.10 ... vertical cursor labels can now be positioned at top or bottom of cursor line.
              LabelPosition parameter added to .AddVerticalCursor()
 10.08.12 ... Automatic axes now set integer tick spacing
              square root axis starts from zero 
 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Clipbrd, printers, math, strutils ;

const
     MaxLines = 100 ;
     XYPlotGraphMaxLines = MaxLines ;
     MaxSingle = 3.4E38 ;
     MaxVerticalCursorLinks = 32 ;
type
    TXY = record
        x : single ;
        y : single ;
        end ;
    TXYPointer = ^TXY ;
    THist = record
          Lo : Single ;
          Mid : single ;
          Hi : single ;
          y : single ;
          end ;
    THistPointer = ^THist ;
    TLineType = ( ltNone, ltLine, ltHistogram ) ;
    TMarkerStyle = ( msNone,
                     msOpenSquare,
                     msOpenCircle,
                     msOpenTriangle,
                     msSolidSquare,
                     msSolidCircle,
                     msSolidTriangle,
                     msNumber,
                     msPlus,
                     msMinus ) ;
    TAxisLaw = (axLinear,axLog,axSquareRoot) ;

    TCursorPos = record
                 Position : single ;
                 Color : TColor ;
                 LineNum : Integer ;
                 InUse : Boolean ;
                 Text : String ;
                 LabelPosition : Integer ;
                 end ;

    { Axis description record }
    TAxis = record
      Lo : Single ;
      Hi : Single ;
      Lo1 : Single ;
      Hi1 : Single ;
      Tick : Single ;
      Min : Single ;
      Max : single ;
      PosMin : Single ;
      Position : Integer ;
      Scale : single ;
      Law : TAxisLaw ;
     { Log : Boolean ;}
      Lab : string ;
      LabelAtTop : Boolean ;
      StartOfTickLabels : Integer ;
      AutoRange : Boolean ;
      end ;

    TLine = record
              Num : Integer ;
              NumPoints : Integer ;
              Color : TColor ;
              MarkerStyle : TMarkerStyle ;
              LineStyle : TPenStyle ;
              LineType : TLineType ;
              XYBuf : Pointer ;
              end ;

    { Axis tick list object }
    TTickList = record
              NumTicks : Integer ;
              Mantissa : TStringList ;
              Exponent : TStringList ;
              Value : Array[0..400] of single ;
              MaxWidth : Integer ;
              MaxHeight : Integer ;
              end ;

  TXYPlotDisplay = class(TGraphicControl)
  private
    { Private declarations }
    FLinesAvailable : Boolean ;
    FMaxPointsPerLine : Integer ;
    FLines : Array[0..MaxLines] of TLine ;
    FXAxis : TAxis ;
    FYAxis : TAxis ;
    FYAxisLabelAtTop : Boolean ;
    FLeft : Integer ;
    FRight : Integer ;
    FTop : Integer ;
    FBottom : Integer ;
    FLineWidth : Integer ;
    FMarkerSize : Integer ;
    FShowLines : Boolean ;
    FShowMarkers : Boolean ;
    FHistogramFullBorders : Boolean ;
    FHistogramFillColor : TColor ;
    FHistogramFillStyle : TBrushStyle ;
    FHistogramCumulative : Boolean ;
    FHistogramPercentage : Boolean ;
    FScreenFontName : string ;
    FScreenFontSize : Integer ;
    FOutputToScreen : Boolean ;
    FTitle : TStringList ;
    { Vertical cursors }
    VertCursors : Array[0..6] of TCursorPos ;
    FNumVerticalCursorLinks : Integer ;
    FLinkVerticalCursors : Array[0..2*MaxVerticalCursorLinks-1] of Integer ;
    FVertCursorActive : Boolean ;
    FVertCursorSelected : Integer ;
    HorCursors : Array[0..6] of TCursorPos ;
    FHorCursorActive : Boolean ;
    FHorCursorSelected : Integer ;
    FOnCursorChange : TNotifyEvent ;
    { Printer settings }
    FPrinterFontSize : Integer ;
    FPrinterLineWidth : Integer ;
    FPrinterMarkerSize : Integer ;
    FPrinterFontName : string ;
    FPrinterLeftMargin : Integer ;
    FPrinterRightMargin : Integer ;
    FPrinterTopMargin : Integer ;
    FPrinterBottomMargin : Integer ;
    FPrinterDisableColor : Boolean ;
    FMetafileWidth : Integer ;
    FMetafileHeight : Integer ;

    FPrinting : Boolean ;

    Bitmap : TBitMap ;        // Display background bitmap (graphs/axes)

    { Property get/set methods }
    function GetLinesAvailable : Boolean ;
    procedure SetMaxPointsPerLine( Value : Integer ) ;
    procedure SetXAxisMin( Value : single ) ;
    function GetXAxisMin : single ;
    procedure SetXAxisMax( Value : single ) ;
    function GetXAxisMax : single ;
    procedure SetXAxisTick( Value : single ) ;
    function GetXAxisTick : single ;
    procedure SetXAxisLaw( Value : TAxisLaw ) ;
    function GetXAxisLaw : TAxisLaw ;
    procedure SetXAxisAutoRange( Value : Boolean ) ;
    function GetXAxisAutoRange : Boolean ;
    procedure SetXAxisLabel( Value : string ) ;
    function GetXAxisLabel : string ;

    procedure SetYAxisMin( Value : single ) ;
    function GetYAxisMin : single ;
    procedure SetYAxisMax( Value : single ) ;
    function GetYAxisMax : single ;
    procedure SetYAxisTick( Value : single ) ;
    function GetYAxisTick : single ;
    procedure SetYAxisLaw( Value : TAxisLaw ) ;
    function GetYAxisLaw : TAxisLaw ;
    procedure SetYAxisAutoRange( Value : Boolean ) ;
    function GetYAxisAutoRange : Boolean ;
    procedure SetYAxisLabel( Value : string ) ;
    function GetYAxisLabel : string ;
    procedure SetScreenFontName( Value : string ) ;
    function GetScreenFontName : string ;

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

    function GetPrinterTitleCount : Integer ;
    procedure SetPrinterTitleLines( Line : Integer ; Value : string ) ;
    function GetPrinterTitleLines( Line : Integer ) : string  ;

    procedure SetVertCursor( iCursor : Integer ; Value : single ) ;
    function GetVertCursor( iCursor : Integer ) : single ;
    procedure SetHorCursor( iCursor : Integer ; Value : single ) ;
    function GetHorCursor( iCursor : Integer ) : single ;

    procedure SetLineStyle(   Line: Integer ; Value : TPenStyle )  ;
    function  GetLineStyle(   Line: Integer ) : TPenStyle ;
    procedure SetMarkerStyle( Line: Integer ; Value : TMarkerStyle )  ;
    function  GetMarkerStyle( Line: Integer ) : TMarkerStyle ;
    function GetNumLines : Integer ;

    procedure DrawAxes( Canv : TCanvas ) ;
    procedure CheckAxis( var Axis : TAxis ) ;
    procedure DefineAxis( var Axis : TAxis ; AxisType : char ) ;
    procedure DrawMarkers( Canv : TCanvas ; MarkerSize : Integer ) ;
    procedure DrawMarkerShape(
              Canv : TCanvas ;
              xPix,yPix : Integer ;
              const LineInfo : TLine ;
              MarkerSize : Integer
              ) ;
    procedure DrawLines( Canv : TCanvas ) ;
    procedure DrawHistograms( Canv : TCanvas ) ;

    procedure TextOutRotated(
              CV : TCanvas ;
              xPix,yPix : Integer ;
              Text : String ;
              Angle : Integer
              ) ;
    procedure CreateTickList(
              var TickList : TTickList ;
              Canv : TCanvas ;
              Var Axis : TAxis
              ) ;
    procedure AddTick(
              var TickList : TTickList ;
              var Axis : TAxis ;   { Plot axis to which tick belongs }
              TickValue : single ;  { Tick value }
              Labelled : Boolean    { True = labelled tick }
              ) ;
    procedure DrawTicks(
              var TickList : TTickList ;
              const Canv : TCanvas ;
              var Axis : TAxis ;
              AxisPosition : Integer ;
              AxisType : string ) ;
    procedure CalculateTicksWidth(
              var TickList : TTickList ;
              const Canv : TCanvas    { Drawing surface }
              ) ;
    procedure CalculateTicksHeight(
              var TickList : TTickList ;
              const Canv : TCanvas    { Drawing surface }
              ) ;

    procedure CodedTextOut(
              Canvas : TCanvas ;
              var LineLeft : Integer ;
              var LineYPos : Integer ;
              List : TStringList
              ) ;

    procedure DrawVerticalCursor( iCurs : Integer ) ;
    procedure DrawHorizontalCursor( iCurs : Integer ) ;
    procedure DrawVerticalCursorLink( Canv : TCanvas ) ;


    function Log10( x : Single ) : Single ;
    function AntiLog10( x : Single ) : Single ;
    function IntLimitTo( Value : Integer ; Lo : Integer ; Hi : Integer ) : Integer ;
    function FloatLimitTo( Value : single ; Lo :  single ; Hi :  single) :  single ;
    function ExtractInt ( CBuf : string ) : Integer ;
    function TidyNumber( const RawNumber : string ) : string ;
    function PrinterPointsToPixels( PointSize : Integer ) : Integer ;


  protected
    { Protected declarations }
    procedure Paint ; override ;
    procedure MouseMove( Shift: TShiftState ; X, Y: Integer ); override ;
    procedure MouseDown( Button: TMouseButton; Shift: TShiftState; X, Y: Integer
              ); override ;
    procedure MouseUp( Button: TMouseButton; Shift: TShiftState; X, Y: Integer
              ); override ;

  public
    { Public declarations }
    constructor Create(AOwner : TComponent) ; override ;
    destructor Destroy ; override ;

    // Create a new line on plot
    procedure CreateLine(
              LineIndex : Integer ;
              Color : TColor ;
              MarkerStyle : TMarkerStyle ;
              LineStyle : TPenStyle
              ) ;

    // Free all line objects in plot
    procedure ClearAllLines ;
    // Free all lines & histograms in plot
    procedure ClearPlot ;

    // Add an (x,y) data point to plot
    procedure AddPoint(
              LineIndex : Integer ;
              x : single ;
              y : single
              ) ;

    // Returns the number of data points in line
    function GetNumPointsInLine( LineIndex : Integer ) : Integer ;

    // Returns value of selected data point in line
    procedure GetPoint(
              LineIndex : Integer ;
              BufIndex : Integer ;
              var x,y : single ) ;

    procedure SetPoint(
              LineIndex : Integer ;
              BufIndex : Integer ;
              x,y : single ) ;

    // Create a new histogram object on plot
    procedure CreateHistogram(
              LineIndex : Integer
              ) ;
    // Add a histogram bin to plot
   procedure AddBin(
             LineIndex : Integer ;
             Lo : single ;
             Mid : single ;
             Hi : single ;
             y : single
             ) ;
    // Returns contents of histogram bin
    procedure GetBin(
              LineIndex : Integer ;
              BufIndex : Integer ;
              var Lo,Mid,Hi,y : single ) ;

    procedure ClearVerticalCursors ;
    function AddVerticalCursor( Color : TColor ;
                                Text : String ;
                                LabelPosition : Integer ) : Integer ;
    procedure LinkVerticalCursors( C0 : Integer ; C1 : Integer ) ;
    procedure ClearHorizontalCursors ;
    function AddHorizontalCursor( Color : TColor ; Text : String ) : Integer ;

    function FindNearestIndex( LineIndex : Integer ; iCursor : Integer ) : Integer ;

    function XToCanvasCoord( Value : single ) : Integer  ;
    function CanvasToXCoord( xPix : Integer ) : single  ;
    function YToCanvasCoord( Value : single ) : Integer  ;
    function CanvasToYCoord( yPix : Integer ) : single  ;


    procedure Print ;
    procedure ClearPrinterTitle ;
    procedure AddPrinterTitleLine( Line : string );
    procedure CopyImageToClipboard ;
    procedure CopyDataToClipboard ;
    procedure SortByX( Line : Integer ) ;
    function TickSpacing( Range : Single ) : Single ;    

    property LineStyles[Line : Integer] : TPenStyle
             read GetLineStyle write SetLineStyle ;
    property VerticalCursors[ i : Integer ] : single
             read GetVertCursor write SetVertCursor ;
    property HorizontalCursors[ i : Integer ] : single
             read GetHorCursor write SetHorCursor ;
    property MarkerStyles[Line : Integer] : TMarkerStyle
             read GetMarkerStyle write SetMarkerStyle ;
    property PrinterTitleLines[ i : Integer ] : string
             read GetPrinterTitleLines write SetPrinterTitleLines ;


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
    property Height default 150 ;
    property Width default 200 ;
    property Available : Boolean read GetLinesAvailable ;
    property MaxPointsPerLine : Integer
             read FMaxPointsPerLine write SetMaxPointsPerLine ;
    property XAxisMin : single read GetXAxisMin write SetXAxisMin ;
    property XAxisMax : single read GetXAxisMax write SetXAxisMax ;
    property XAxisTick : single read GetXAxisTick write SetXAxisTick ;
    property XAxisLaw : TAxisLaw read GetXAxisLaw write SetXAxisLaw ;
    property XAxisLabel : string read GetXAxisLabel write SetXAxisLabel ;
    property XAxisAutoRange : boolean
             read GetXAxisAutoRange write SetXAxisAutoRange ;

    property YAxisMin : single read GetYAxisMin write SetYAxisMin ;
    property YAxisMax : single read GetYAxisMax write SetYAxisMax ;
    property YAxisTick : single read GetYAxisTick write SetYAxisTick ;
    property YAxisLaw : TAxisLaw read GetYAxisLaw write SetYAxisLaw ;
    property YAxisLabel : string read GetYAxisLabel write SetYAxisLabel ;
    property YAxisAutoRange : boolean
             read GetYAxisAutoRange write SetYAxisAutoRange ;
    property YAxisLabelAtTop : Boolean
             read FYAxisLabelAtTop write FYAxisLabelAtTop ;

    property ScreenFontName : string
             read GetScreenFontName write SetScreenFontName ;
    property ScreenFontSize : Integer
             read FScreenFontSize write FScreenFontSize ;

    property LineWidth : Integer read FLineWidth write FLineWidth ;
    property MarkerSize : Integer read FMarkerSize write FMarkerSize ;
    property ShowLines : Boolean read FShowLines write FShowLines ;
    property ShowMarkers : Boolean read FShowMarkers write FShowMarkers ;
    property NumLines : Integer read GetNumLines ;
    property HistogramFullBorders : boolean
             read FHistogramFullBorders write FHistogramFullBorders ;
    property HistogramFillColor : TColor
             read FHistogramFillColor write FHistogramFillColor ;
    property HistogramFillStyle : TBrushStyle
             read FHistogramFillStyle write FHistogramFillStyle ;
    property HistogramCumulative : Boolean
             read FHistogramCumulative write FHistogramCumulative ;
    property HistogramPercentage : Boolean
             read FHistogramPercentage write FHistogramPercentage ;


    property PrinterFontSize : Integer read FPrinterFontSize write FPrinterFontSize ;
    property PrinterFontName : string
             read GetPrinterFontName write SetPrinterFontName ;
    property PrinterLineWidth : Integer
             read FPrinterLineWidth write FPrinterLineWidth ;
    property PrinterMarkerSize : Integer
             read FPrinterMarkerSize write FPrinterMarkerSize ;
    property PrinterLeftMargin : Integer
             read GetPrinterLeftMargin write SetPrinterLeftMargin ;
    property PrinterRightMargin : Integer
             read GetPrinterRightMargin write SetPrinterRightMargin ;
    property PrinterTopMargin : Integer
             read GetPrinterTopMargin write SetPrinterTopMargin ;
    property PrinterBottomMargin : Integer
             read GetPrinterBottomMargin write SetPrinterBottomMargin ;
    property PrinterDisableColor : Boolean read FPrinterDisableColor write FPrinterDisableColor ;
    property PrinterTitleCount : Integer
             Read GetPrinterTitleCount ;
    property MetafileWidth : Integer
             read FMetafileWidth write FMetafileWidth ;
    property MetafileHeight : Integer
             read FMetafileHeight write FMetafileHeight ;

  end;

procedure Register;
{ - Support functions - }

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TXYPlotDisplay]);
end;


constructor TXYPlotDisplay.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
var
   i : Integer ;
begin

     inherited Create(AOwner) ;

     { Set opaque background to minimise flicker when display updated }
     ControlStyle := ControlStyle + [csOpaque] ;

     // Create bitmaps
     Bitmap := TBitMap.Create ;
     Bitmap.Width := Width ;
     Bitmap.Height := Height ;

     { Create a list to hold any printer title strings }
     FTitle := TStringList.Create ;

     { Size of x,y data buffer for each line }
     FMaxPointsPerLine := 4096 ;
     { Width of lines (screen,metafile=pixels, printer=points) }
     FLineWidth := 1 ;
     { Marker size (screen,metafile=pixels, printer=points) }
     FMarkerSize := 6 ;
     { Full borders flag for histogram plots }
     FHistogramFullBorders := False ;
     { Histogram bin fill colour }
     FHistogramFillColor := clWhite ;
     { Histogram bin fill style }
     FHistogramFillStyle := bsClear ;

     FHistogramCumulative := False ;

     FHistogramPercentage := False ;

     { Show markers on lines }
     FShowMarkers := True ;
     { Show lines joining data points }
     FShowLines := True ;

     { Initialise all lines on plot to none }
     for i := 0 to MaxLines do begin
         FLines[i].Num := i ;
         FLines[i].NumPoints := 0 ;
         FLines[i].XYBuf := Nil ;
         FLines[i].MarkerStyle := msOpenSquare ;
         FLines[i].LineStyle := psSolid ;
         FLines[i].LineType := ltNone ;
         FLines[i].Color := clBlack ;
         end ;

     { Initial axes settings }
     FXAxis.Lo := 0.0 ;
     FXAxis.Hi := 1.0 ;
     FXAxis.Tick := 0.2 ;
     FXAxis.Law := axLinear ;
     FXAxis.Lab := 'X Axis' ;
     FXAxis.AutoRange := False ;

     FYAxis.Lo := 0.0 ;
     FYAxis.Hi := 1.0 ;
     FYAxis.Tick := 0.2 ;
     FYAxis.Law := axLinear ;
     FYAxis.Lab := 'Y Axis' ;
     FYAxis.AutoRange := False ;
     FYAxisLabelAtTop := False ;

     FScreenFontName := 'Arial' ;
     FScreenFontSize := 10 ;
     FOutputToScreen := True ;

     { Printer margins (mm), font name and size }
     FPrinterFontName := 'Arial' ;
     FPrinterFontSize := 10 ;

     if Printer.Printers.Count > 0 then begin
        FPrinterLeftMargin := (Printer.PageWidth*25)
                              div GetDeviceCaps( printer.handle, HORZSIZE ) ;
        FPrinterTopMargin := (Printer.PageHeight*25)
                              div GetDeviceCaps( printer.handle, VERTSIZE ) ;
        end
     else begin
        FPrinterLeftMargin := 0 ;
        FPrinterTopMargin := 0 ;
        end ;
     FPrinterRightMargin := FPrinterLeftMargin ;
     FPrinterBottomMargin := FPrinterTopMargin ;
     FPrinterDisableColor := False ;
     FPrinterLineWidth := 1 ;
     FPrinterMarkerSize := 5 ;

     FPrinting := False ;

     FMetafileWidth := 500 ;
     FMetafileHeight := 400 ;

     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     for i := 0 to High(HorCursors) do HorCursors[i].InUse := False ;
     FVertCursorActive := False ;
     FVertCursorSelected := -1 ;
     FHorCursorActive := False ;
     FHorCursorSelected := -1 ;
     FOnCursorChange := Nil ;
     FLinesAvailable := False ;

     end ;


destructor TXYPlotDisplay.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
var
   i : Integer ;
begin

     { Destroy internal objects created by .Create }
     Bitmap.Free ;

     FTitle.Free ;
    { FLinePen.Free ;}
     { Dispose of any x,y data buffers that have been allocated }
     for i := 0 to High(FLines) do if FLines[i].XYBuf <> Nil then begin
         FreeMem( FLines[i].XYBuf ) ;
         FLines[i].XYBuf := Nil ;
         end ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


procedure TXYPlotDisplay.CreateLine(
          LineIndex : Integer ;
          Color : TColor ;
          MarkerStyle : TMarkerStyle ;
          LineStyle : TPenStyle
          ) ;
{ -----------------------------
  Create a new line on the plot
  -----------------------------}
begin
     { Allocate memory for x,y data points }
     if FLines[LineIndex].XYBuf = Nil then begin
        GetMem(FLines[LineIndex].XYBuf, FMaxPointsPerLine*SizeOf(TXY) ) ;
        end ;
     FLines[LineIndex].NumPoints := 0 ;
     FLines[LineIndex].LineStyle := LineStyle ;
     FLines[LineIndex].MarkerStyle := MarkerStyle ;
     FLines[LineIndex].LineType := ltLine ;
     FLines[LineIndex].Color := Color ;
     end ;


procedure TXYPlotDisplay.ClearAllLines ;
{ ----------------
  Clear all lines
  ---------------- }
var
   i : Integer ;
begin
     for i := 0 to High(FLines) do if FLines[i].LineType = ltLine then begin
         FLines[i].NumPoints := 0 ;
         if FLines[i].XYBuf <> Nil then begin
            FreeMem(FLines[i].XYBuf) ;
            FLines[i].XYBuf := Nil ;
            end ;
         end ;
     end ;


procedure TXYPlotDisplay.ClearPlot ;
{ ----------------------------
  Clear all lines & histograms
  ---------------------------- }
var
   i : Integer ;
begin
     for i := 0 to High(FLines) do begin
         FLines[i].NumPoints := 0 ;
         FLines[i].LineType := ltNone ;
         if FLines[i].XYBuf <> Nil then begin
            FreeMem(FLines[i].XYBuf) ;
            FLines[i].XYBuf := Nil ;
            end ;
         end ;
     end ;


procedure TXYPlotDisplay.AddPoint(
          LineIndex : Integer ;    { Line to add point to }
          x : single ;             { x coord (axis units) }
          y : single               { y coord (axis units) }
          ) ;
{ ------------------------------
  Add a new point to end of line
  ------------------------------}
var
   pXY : Pointer ;
begin
     if FLines[LineIndex].XYBuf <> Nil then begin
        if FLines[LineIndex].NumPoints < FMaxPointsPerLine then begin
           pXY := Pointer( Integer(FLines[LineIndex].XYBuf)
                           + FLines[LineIndex].NumPoints*SizeOf(TXY)) ;
           TXYPointer(pXY)^.x := x ;
           TXYPointer(pXY)^.y := y ;
           Inc(FLines[LineIndex].NumPoints) ;
           end ;
        end ;
     Invalidate ;
     end ;


procedure TXYPlotDisplay.CreateHistogram(
          LineIndex : Integer
          ) ;
{ ----------------------------------
  Create a new histogram on the plot
  ----------------------------------}
begin
     { Allocate memory for x,y data points }
     if FLines[LineIndex].XYBuf = Nil then begin
        GetMem(FLines[LineIndex].XYBuf, FMaxPointsPerLine*SizeOf(THist) ) ;
        end ;
     FLines[LineIndex].NumPoints := 0 ;
     FLines[LineIndex].LineType := ltHistogram ;
     end ;


procedure TXYPlotDisplay.AddBin(
          LineIndex : Integer ;
          Lo : single ;
          Mid : single ;
          Hi : single ;
          y : single
          ) ;
{ ---------------------------------
  Add a new bin to end of histogram
  --------------------------------- }
var
   pXY : Pointer ;
begin
     if FLines[LineIndex].XYBuf <> Nil then begin
        pXY := Pointer( Integer(FLines[LineIndex].XYBuf)
                        + FLines[LineIndex].NumPoints*SizeOf(THist))  ;
        THistPointer(pXY)^.Lo := Lo ;
        THistPointer(pXY)^.Mid := Mid ;
        THistPointer(pXY)^.Hi := Hi ;
        THistPointer(pXY)^.y := y ;
        if FLines[LineIndex].NumPoints < FMaxPointsPerLine then
           Inc(FLines[LineIndex].NumPoints) ;
        end ;
     Invalidate ;
     end ;

function TXYPlotDisplay.GetNumPointsInLine(
         LineIndex : Integer
         ) : Integer ;
{ -------------------------------------------------
  Returns the number of points in the selected line
  ------------------------------------------------- }
begin
     Result := FLines[LineIndex].NumPoints ;
     end ;


procedure TXYPlotDisplay.Paint ;
{ ---------------------------
  Draw plot on control canvas
  ---------------------------}
var
   i,L : Integer ;
begin

     if FPrinting then exit ;

     Bitmap.Canvas.Font.Name := FScreenFontName ;
     Bitmap.Canvas.Font.Size := FScreenFontSize ;

     if Width < 2 then Width := 2 ;
     if Height < 2 then Height := 2 ;

     // Make bit map same size as control
     if (Bitmap.Width <> Width) or
        (Bitmap.Height <> Height) then begin
        Bitmap.Width := Width ;
        Bitmap.Height := Height ;
        end ;

     FLeft := Bitmap.Canvas.TextWidth('X') ;
     FRight := Width - Bitmap.Canvas.TextWidth('X') ;
     FTop := Bitmap.Canvas.TextHeight('X') ;
     FBottom := Height - Bitmap.Canvas.TextHeight('X') ;

     { Clear display area }
     Bitmap.Canvas.fillrect(Bitmap.Canvas.ClipRect);

     { Determine if there are any lines to be plotted }
     FLinesAvailable := False ;
     for L := 0 to High(FLines) do if (FLines[L].XYBuf <> Nil)
         and (FLines[L].NumPoints > 0) then FLinesAvailable := True ;

     if FLinesAvailable then begin
        FOutputToScreen := True ;
        DrawAxes( Bitmap.Canvas ) ;
        DrawHistograms( Bitmap.Canvas ) ;
        if FShowMarkers then DrawMarkers( Bitmap.Canvas, FMarkerSize ) ;
        if FShowLines then DrawLines( Bitmap.Canvas ) ;

        // Copy from internal bitmap to control
        Canvas.CopyRect( Canvas.ClipRect,
                         Bitmap.Canvas,
                         Canvas.ClipRect) ;

        // Draw link between selected pair of vertical cursors
        DrawVerticalCursorLink(Canvas) ;

        { Vertical Cursors }
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
            DrawVerticalCursor(i) ;

        { Horizontal Cursors }
        for i := 0 to High(HorCursors) do if HorCursors[i].InUse then
            DrawHorizontalCursor(i) ;
            
        { Notify a change in cursors }
        if Assigned(OnCursorChange) then OnCursorChange(Self) ;

        end
     else begin
        // Copy from internal bitmap to control
        Canvas.CopyRect( Canvas.ClipRect,
                         Bitmap.Canvas,
                         Canvas.ClipRect) ;
        end ;
        
     end ;


procedure TXYPlotDisplay.ClearVerticalCursors ;
{ -----------------------------
  Remove all vertical cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     end ;


procedure TXYPlotDisplay.ClearHorizontalCursors ;
{ -----------------------------
  Remove all Horizontal cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(HorCursors) do HorCursors[i].InUse := False ;
     end ;



function TXYPlotDisplay.AddVerticalCursor(
         Color : TColor ;           // Cursor line colour
         Text : String ;            // Cursor label ('?r' = cursor value)
         LabelPosition : Integer    // Label position (0=bottom, 1=top)
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
       VertCursors[iCursor].Position := FXAxis.Lo ;
       VertCursors[iCursor].InUse := True ;
       VertCursors[iCursor].Color := Color ;
       VertCursors[iCursor].Text := Text ;
       VertCursors[iCursor].LabelPosition := LabelPosition ;
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;


procedure TXYPlotDisplay.LinkVerticalCursors(
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


procedure TXYPlotDisplay.DrawVerticalCursor(
          iCurs : Integer
          ) ;
{ -----------------------
  Draw vertical cursor
 ------------------------}
var
   xPix : Integer ;
   x,y,BinLoX,BinHiX : Single ;
   SavedPen : TPenRecall ;
   SavedFont : TFontRecall ;

   s : String ;
begin

     // Save pen & font
     SavedPen := TPenRecall.Create( Canvas.Pen ) ;
     SavedFont := TFontRecall.Create( Canvas.Font ) ;

     Canvas.pen.color := VertCursors[iCurs].Color ;
     Canvas.Font.Color := VertCursors[iCurs].Color ;

     VertCursors[iCurs].Position := FloatLimitTo( VertCursors[iCurs].Position,
                                                  FXAxis.Lo, FXAxis.Hi ) ;
     xPix := XToCanvasCoord( VertCursors[iCurs].Position ) ;

     Canvas.polyline( [Point(xPix,FTop),Point(xPix,FBottom)]);

     // Display text label for cursor

     // Plot cursor label
     if ANSIContainsText(VertCursors[iCurs].Text,'?r') then begin
        // Display signal value at cursor
        if FLines[0].LineType = ltHistogram then begin
           GetBin(0,FindNearestIndex(0,iCurs),BinLoX,x,BinHiX,y) ;
           end
        else begin
           GetPoint(0,FindNearestIndex(0,iCurs),x,y) ;
           end ;
        s := format('%.5g, %.5g',[x,y]) ;
        end
     else s := VertCursors[iCurs].Text ;

     Canvas.TextOut( xPix - Canvas.TextWidth(s) div 2,
                     FBottom + 1
                     - VertCursors[iCurs].LabelPosition*(FBottom-FTop),
                     s ) ;

    // Restore pen
    SavedPen.Free ;
    SavedFont.Free ;

    end ;


procedure TXYPlotDisplay.DrawVerticalCursorLink(
          Canv : TCanvas
          ) ;
{ ---------------------------------------------
  Draw horizontal link between vertical cursors
 ----------------------------------------------}
var
   i : Integer ;
   iCurs0,iCurs1 : Integer ;
   xPix0,xPix1,yPix : Integer ;
   OldColor : TColor ;
begin

     for i := 0 to FNumVerticalCursorLinks-1 do begin

         iCurs0 := FLinkVerticalCursors[2*i] ;
         iCurs1 := FLinkVerticalCursors[(2*i)+1] ;

         if VertCursors[iCurs0].InUse and VertCursors[iCurs1].InUse then begin ;

            // Set pen to cursor colour (saving old)
            OldColor := Canvas.Pen.Color ;
            Canv.Pen.Color := VertCursors[iCurs0].Color ;

            // Y location of line
            yPix := FBottom + (Canv.TextHeight('X') div 2) ;

            // Plot left cursor end
            xPix0 := XToCanvasCoord( VertCursors[iCurs0].Position ) ;
            if VertCursors[iCurs0].Text <> '' then begin
               xPix0 := xPix0 + (Canv.TextWidth(VertCursors[iCurs0].Text) div 2) + 2 ;
               end
            else begin
               Canv.polyline( [Point(xPix0,yPix-3),Point(xPix0,yPix+3)] );
               end ;

            // Plot right cursor end
            xPix1 := XToCanvasCoord( VertCursors[iCurs1].Position ) ;
            if VertCursors[iCurs1].Text <> '' then begin
               xPix1 := xPix1 - (Canv.TextWidth(VertCursors[iCurs0].Text) div 2) - 2 ;
               end
            else begin
               Canv.polyline( [Point(xPix1,yPix-3),Point(xPix1,yPix+3)] );
               end ;

            // Plot horizontal lne
            Canv.polyline( [Point(xPix0,yPix),Point(xPix1,yPix)] );

            // Restore pen colour
            Canv.Pen.Color := OldColor ;
            end ;
         end ;

     end ;


function TXYPlotDisplay.AddHorizontalCursor(
         Color : TColor ;
         Text : String
         ) : Integer ;
{ --------------------------------------------
  Add a new Horizontal cursor to the display
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
       HorCursors[iCursor].Position := FYAxis.Lo ;
       HorCursors[iCursor].InUse := True ;
       HorCursors[iCursor].Color := Color ;
       HorCursors[iCursor].Text := Text ;
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;


procedure TXYPlotDisplay.DrawHorizontalCursor(
          iCurs : Integer
          ) ;
{ -----------------------
  Draw Horizontal cursor
 ------------------------}
var
   yPix : Integer ;
   SavedPen : TPenRecall ;
   SavedFont : TFontRecall ;
   s : String ;
begin

     // Save pen & font
     SavedPen := TPenRecall.Create( Canvas.Pen ) ;
     SavedFont := TFontRecall.Create( Canvas.Font ) ;

     Canvas.pen.color := HorCursors[iCurs].Color ;
     Canvas.Font.Color := HorCursors[iCurs].Color ;

     HorCursors[iCurs].Position := FloatLimitTo( HorCursors[iCurs].Position,
                                                 FYAxis.Lo, FYAxis.Hi ) ;
     yPix := YToCanvasCoord( HorCursors[iCurs].Position ) ;

     Canvas.polyline( [Point(FLeft,yPix),Point(FRight,yPix)]);

     // Display text label for cursor

     // Plot cursor label
     s := HorCursors[iCurs].Text ;
     Canvas.TextOut( FLeft - Canvas.TextWidth(s) - 2,
                     yPix,
                     s ) ;

    // Restore pen
    SavedPen.Free ;
    SavedFont.Free ;

    end ;


function TXYPlotDisplay.FindNearestIndex(
         LineIndex : Integer ;
         iCursor : Integer
         ) : Integer ;
{ -------------------------------------------------------
  Find the nearest point/bin index to the cursor position
  -------------------------------------------------------}
var
   Nearest,i : Integer ;
   Diff,MinDiff,X : single ;
   pXY : Pointer ;
begin
     X := VertCursors[iCursor].Position ;
     MinDiff := MaxSingle ;
     Nearest := 0 ;

     if FLines[LineIndex].LineType = ltHistogram then begin
        { Find nearest histogram bin }
        for i := 0 to FLines[LineIndex].NumPoints-1 do begin
            pXY := Pointer( Integer(FLines[LineIndex].XYBuf) + SizeOf(THist)*i ) ;
            Diff := Abs(X - THistPointer(pXY)^.Mid) ;
            if  Diff < MinDiff then begin
               Nearest := i ;
               MinDiff := Diff ;
               end ;
            end ;
        end
     else begin
        { Find nearest X,Y data point on a line }
        for i := 0 to FLines[LineIndex].NumPoints-1 do begin
            pXY := Pointer( Integer(FLines[LineIndex].XYBuf) + SizeOf(TXY)*i ) ;
            Diff := Abs(X - TXYPointer(pXY)^.x) ;
            if  Diff < MinDiff then begin
               Nearest := i ;
               MinDiff := Diff ;
               end ;
            end ;
        end ;
     Result := Nearest ;
     end ;


procedure TXYPlotDisplay.GetPoint(
          LineIndex : Integer ;     { Line on plot [In] }
          BufIndex : Integer ;      { Index within line data buffer [In] }
          var x,y : single ) ;      { Returned x,y position }
{ ------------------------------------------------------
  Get the x,y data values for a selected point on a line
  ------------------------------------------------------ }
var
   pXY : pChar ;
begin
     LineIndex := IntLimitTo( LineIndex, 0, High(FLines) ) ;
     if (FLines[LineIndex].XYBuf <> Nil) and
        (FLines[LineIndex].LineType = ltLine) then begin
        BufIndex := IntLimitTo( BufIndex, 0, Flines[LineIndex].NumPoints-1 ) ;
        pXY := Pointer( Integer(FLines[LineIndex].XYBuf) + SizeOf(TXY)*BufIndex ) ;
        x := TXYPointer(pXY)^.x ;
        y := TXYPointer(pXY)^.y ;
        end
     else begin
        x := 0.0 ;
        y := 0.0 ;
        end ;
     end ;


procedure TXYPlotDisplay.SetPoint(
          LineIndex : Integer ;     { Line on plot [In] }
          BufIndex : Integer ;      { Index within line data buffer [In] }
          x,y : single ) ;          { New x,y position }
{ ------------------------------------------------------
  Set the x,y data values for a selected point on a line
  ------------------------------------------------------ }
var
   pXY : Pointer ;
begin
     LineIndex := IntLimitTo( LineIndex, 0, High(FLines) ) ;
     if (FLines[LineIndex].XYBuf <> Nil) and
        (FLines[LineIndex].LineType = ltLine) then begin
        BufIndex := IntLimitTo( BufIndex, 0, Flines[LineIndex].NumPoints-1 ) ;
        pXY := Pointer( Integer(FLines[LineIndex].XYBuf) + SizeOf(TXY)*BufIndex ) ;
        TXYPointer(pXY)^.x := x ;
        TXYPointer(pXY)^.y := y;
        end ;
     Invalidate ;
     end ;


procedure TXYPlotDisplay.GetBin(
          LineIndex : Integer ;         { Line on plot [In] }
          BufIndex : Integer ;          { Index within line data buffer [In] }
          var Lo,Mid,Hi,y : single ) ;  { Returned Lo,Mid,Hi,y bin data }
{ ------------------------------------------------------
  Get the data values for a selected histogram bin
  ------------------------------------------------------ }
var
   pXY : Pointer ;
begin
     LineIndex := IntLimitTo( LineIndex, 0, High(FLines) ) ;
     if (FLines[LineIndex].XYBuf <> Nil) and
        (FLines[LineIndex].LineType = ltHistogram) then begin
        BufIndex := IntLimitTo( BufIndex, 0, Flines[LineIndex].NumPoints-1 ) ;
        pXY := Pointer( Integer(FLines[LineIndex].XYBuf) + SizeOf(THist)*BufIndex ) ;
        Lo := THistPointer(pXY)^.Lo ;
        Mid := THistPointer(pXY)^.Mid ;
        Hi := THistPointer(pXY)^.Hi ;
        y := THistPointer(pXY)^.y ;
        end
     else begin
        Lo := 0.0 ;
        Mid := 0.0 ;
        Hi := 0.0 ;
        y := 0.0 ;
        end ;
     end ;


{ =======================================================
  INTERNAL EVENT HANDLING METHODS
  ======================================================= }

procedure TXYPlotDisplay.MouseDown(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;

begin

     Inherited MouseDown( Button, Shift, X, Y ) ;

     if (FVertCursorSelected > -1) then FVertCursorActive := True
     else if (FHorCursorSelected > -1) then FHorCursorActive := True ;

     end ;


procedure TXYPlotDisplay.MouseUp(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;
begin
     Inherited MouseUp( Button, Shift, X, Y ) ;
     FVertCursorActive := false ;
     FHorCursorActive := false ;
     end ;


procedure TXYPlotDisplay.MouseMove(
          Shift: TShiftState;
          X, Y: Integer) ;
{ --------------------------------------------------------
  Select/deselect cursors as mouse is moved over display
  -------------------------------------------------------}
const
     Margin = 4 ;
var
   XPosition,YPosition,i : Integer ;
begin
     Inherited MouseMove( Shift, X, Y ) ;

     if (FVertCursorActive and (FVertCursorSelected > -1)) or
        (FHorCursorActive and (FHorCursorSelected > -1)) then begin

        // Move the currently activated cursor to a new position

        if (FVertCursorActive and (FVertCursorSelected > -1)) then begin
           VertCursors[FVertCursorSelected].Position := CanvasToXCoord( X ) ;
           end
        else begin
           HorCursors[FHorCursorSelected].Position := CanvasToYCoord( Y ) ;
           end ;

        // Copy background graph from internal bitmap to control
        Canvas.CopyRect( Canvas.ClipRect,
                         Bitmap.Canvas,
                         Canvas.ClipRect) ;

        // Draw link between selected pair of vertical cursors
        DrawVerticalCursorLink(Canvas) ;

        // Draw cursors
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
            DrawVerticalCursor(i) ;
        for i := 0 to High(HorCursors) do if HorCursors[i].InUse then
            DrawHorizontalCursor(i) ;

        { Notify a change in cursors }
        if Assigned(OnCursorChange) then OnCursorChange(Self) ;

        end
     else begin
        { Find the active cursor (if any) }
        // Vertical
        FVertCursorSelected := -1 ;
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then begin
            XPosition := XToCanvasCoord( VertCursors[i].Position ) ;
            if Abs(X - XPosition) <= Margin then FVertCursorSelected := i ;
            end ;
        // Horizontal
        FHorCursorSelected := -1 ;
        for i := 0 to High(HorCursors) do if HorCursors[i].InUse then begin
            YPosition := YToCanvasCoord( HorCursors[i].Position ) ;
            if Abs(Y - YPosition) <= Margin then FHorCursorSelected := i ;
            end ;

        end ;


        { Set type of cursor icon }
     if FVertCursorSelected > -1 then Cursor := crSizeWE
     else if FHorCursorSelected > -1 then Cursor := crSizeNS
                                else Cursor := crDefault ;

     end ;


procedure TXYPlotDisplay.CopyImageToClipboard ;
{ ---------------------------------------------
  Copy plot to clipboard as a Windows metafile
  ---------------------------------------------}
var
   TMF : TMetafile ;
   TMFC : TMetafileCanvas ;
   KeepLineWidth : Integer ;
begin

     // Exit if no lines
     if not GetLinesAvailable then Exit ;

     Cursor := crHourglass ;
     FPrinting := True ;

     { Create Windows metafile object }
     TMF := TMetafile.Create ;
     TMF.Width := FMetafileWidth ;
     TMF.Height := FMetafileHeight ;
     KeepLineWidth := FLineWidth ;
     FLineWidth := FPrinterLineWidth ;

     try
        { Create a metafile canvas to draw on }
        TMFC := TMetafileCanvas.Create( TMF, 0 ) ;

        try
            { Set type face }
            TMFC.Font.Name := FPrinterFontName ;
            TMFC.Font.Size := FPrinterFontSize ;

            { Make the size of the canvas the same as the displayed area
              AGAIN ... See above. Not sure why we need to do this again
              but clipboard image doesn't come out right if we don't}
            TMF.Width := FMetafileWidth ;
            TMF.Height := FMetafileHeight ;
            { ** NOTE ALSO The above two lines MUST come
              BEFORE the setting of the plot margins next }

            FLeft := TMFC.TextWidth('X') ;
            FRight := TMF.Width - TMFC.TextWidth('X') ;
            FTop := TMFC.TextHeight('X') ;
            FBottom := TMF.Height - TMFC.TextHeight('X') ;

            FOutputToScreen := False ;
            DrawAxes( TMFC ) ;
            DrawHistograms( TMFC ) ;
            if FShowLines then DrawLines( TMFC ) ;
            if FShowMarkers then DrawMarkers( TMFC, FPrinterMarkerSize ) ;
        finally
            { Free metafile canvas. Note this copies plot into metafile object }
            TMFC.Free ;
            end ;
        { Copy metafile to clipboard }
        Clipboard.Assign(TMF) ;

     finally
        Cursor := crDefault ;
        FLineWidth := KeepLineWidth ;
        FPrinting := False ;
        Invalidate ; // to ensure display is repainted
        end ;

     end ;


procedure TXYPlotDisplay.CopyDataToClipboard ;
{ -------------------------------------------------------
  Copy plot data points to clipboard as table of Tab text
  ------------------------------------------------------- }
var
   L,i,NumPointsMax,BufSize,NumLines : Integer ;
   x,y,BinLo,BinMid,BinHi,Sum : Single ;
   BinY : Array[0..MaxLines] of Single ;
   YScale : Array[0..MaxLines] of Single ;
   pXY : Pointer ;
   CopyBuf : PChar ;
   First,Histogram : Boolean ;
begin

     // Exit if no lines
     if not GetLinesAvailable then Exit ;

     Screen.Cursor := crHourglass ;

     // Open clipboard preventing others acceessing it
     Clipboard.Open ;



        // Find maximum number of points in any line
        NumPointsMax := 0 ;
        NumLines := 0 ;
        Histogram := False ;
        for L := 0 to High(FLines) do if (FLines[L].XYBuf <> Nil) then begin
            if FLines[L].NumPoints > NumPointsMax then NumPointsMax := FLines[L].NumPoints ;
            if FLines[L].LineType = ltHistogram then Histogram := True ;
            Inc(NumLines) ;
            end ;

        // Allocate a suitable text buffer
        BufSize := 10*2*(NumPointsMax*NumLines) ;
        // Double allocation if this is a histogram (to inclide BinLo and BinHi values)
        if Histogram then BufSize := BufSize*2 ;

        CopyBuf := StrAlloc( BufSize ) ;


     try
        StrCopy(CopyBuf, PChar('')) ;
        { Initialisations for cumulative and/or percentage histograms }
        for L := 0 to High(FLines) do if FLines[L].XYBuf <> Nil then begin
            // Initialise cumulative Y value
            BinY[L] := 0.0 ;
            // Calculate percentage scale factor }
            if FHistogramPercentage then begin
               Sum := 0.0 ;
               for i := 0 to FLines[L].NumPoints-1 do begin
                   pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(THist)) )  ;
                   Sum := Sum + THistPointer(pXY)^.y ;
                   end ;
               YScale[L] := 100.0 / Sum ;
               end
            else YScale[L] := 1.0 ;
            end ;

        { Create tab-text table of data values }
        for i := 0 to NumPointsMax-1 do begin

            { Create a line of data values }
            First := True ;
            for L := 0 to High(FLines) do if (FLines[L].XYBuf <> Nil) then begin

                { Add tab separator between X,Y and/or histogram bin data points }
                if not First then StrCat( CopyBuf, #9 ) ;
                First := False ;

                if FLines[L].LineType = ltLine then begin
                   { Add an X,Y line point }
                   if (i < FLines[L].NumPoints) then begin
                      { Get x,y point from buffer }
                      pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(TXY)) ) ;
                      x := TXYPointer(pXY)^.x ;
                      y := TXYPointer(pXY)^.y ;
                      StrCat( CopyBuf, PChar(format('%.5g'#9'%.5g',[x,y]))) ;
                      end
                   else StrCat( CopyBuf, #9 ) ;
                   end
                else begin
                   { Add a histogram bin }
                   if (i < FLines[L].NumPoints) then begin
                      pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(THist)))  ;
                      BinLo := THistPointer(pXY)^.Lo ;
                      BinMid := THistPointer(pXY)^.Mid ;
                      BinHi := THistPointer(pXY)^.Hi ;
                      if FHistogramCumulative then
                         BinY[L] := BinY[L] + THistPointer(pXY)^.y*YScale[L]
                      else
                         BinY[L] :=THistPointer(pXY)^.y*YScale[L] ;
                      StrCat( CopyBuf, PChar(format('%.5g'#9'%.5g'#9'%.5g'#9'%.5g',
                              [BinLo,BinMid,BinHi,BinY[L]]))) ;
                      end
                   else StrCat( CopyBuf, #9#9#9 ) ;
                   end ;
                end ;

            StrCat( CopyBuf, #13#10 ) ;
            end ;

        // Copy data table to clipboard
        ClipBoard.SetTextBuf( CopyBuf ) ;

     finally

       Screen.Cursor := crDefault ;
       // Free buffer
       StrDispose(CopyBuf) ;
       // Release clipboard
       Clipboard.Close ;
       end ;


     end ;




procedure TXYPlotDisplay.DrawAxes(
          Canv : TCanvas  {canvas on which the axes are to be drawn.}
          ) ;
{ ---------------
  Draw plot axes
  --------------- }
var
   xPix,yPix : Integer ;
   yLabelxPos,yLabelyPos : Integer ;
   Temp : Single ;
   XTickList : TTickList ;
   YTickList : TTickList ;

begin
     { Create lists to hold tick label strings }
     XTickList.Mantissa := TStringList.Create ;
     XTickList.Exponent := TStringList.Create ;
     YTickList.Mantissa := TStringList.Create ;
     YTickList.Exponent := TStringList.Create ;

     try

        { Find appropriate axis ranges if required }
        if FXAxis.AutoRange then DefineAxis( FXAxis, 'X' ) ;
        if FYAxis.AutoRange then DefineAxis( FYAxis, 'Y' ) ;

        { Ensure that axes ranges are valid }
        CheckAxis( FXAxis ) ;
        CheckAxis( FYAxis ) ;

        { Make space for Y Axis label }
        if FYAxisLabelAtTop then begin
           YLabelYPos := FTop ;
           FTop := FTop + Canv.TextHeight( FYAxis.Lab ) ;
           end
        else begin
           YLabelXPos := FLeft ;
           FLeft := FLeft + Canv.TextHeight( FYAxis.Lab ) ;
           end ;

        { Create Y axis tick list }
        CreateTickList( YTickList, Canv, FYAxis ) ;
        { Shift left margin to leave space for Y axis tick values }
        FLeft := FLeft + YTickList.MaxWidth + Canv.TextWidth('X')*2 ;

        { Create X axis tick list }
        CreateTickList( XTickList, Canv, FXAxis ) ;
        FRight := FRight - XTickList.MaxWidth ;

        { Shift bottom margin to leave space for X axis label }
        FBottom := FBottom - 2*Canv.TextHeight(FxAxis.Lab) ;

        xPix := ( FLeft + FRight - Canv.TextWidth(FXAxis.Lab) ) div 2 ;
        Canv.TextOut( xPix,
                      FBottom
                      + (Canv.TextHeight(FxAxis.Lab)), FXAxis.Lab ) ;

        { Shift bottom margin to leave space for X axis tick values }
        FBottom := FBottom - XTickList.MaxHeight - (Canv.TextHeight('X') div 2) ;

        { Set thickness of line to be used to draw axes }
        Canv.Pen.Width := FLineWidth ;

        { Draw X axis }
        If FyAxis.Law = axLog Then Temp := FYAxis.Lo
                              Else Temp := FloatLimitTo( 0.0, FYAxis.Lo, FYAxis.Hi ) ;

        FXAxis.Position := YToCanvasCoord( Temp ) ;
        Canv.polyline( [ Point( FLeft, FXAxis.Position ),
                         Point( FRight,FXAxis.Position ) ] ) ;

        { Draw Y axis }
        If FxAxis.Law <> axLinear Then Temp := FXAxis.Lo
                                  Else Temp := FloatLimitTo( 0.0, FXAxis.Lo, FXAxis.Hi ) ;
        FYAxis.Position := XToCanvasCoord( Temp ) ;
        Canv.polyline( [point(FYAxis.Position, FTop),
                        point(FYAxis.Position, FBottom)]) ;

        { Draw calibration ticks on X and Y Axes }
        DrawTicks( XTickList, Canv, FXAxis, FXAxis.Position, 'X') ;
        DrawTicks( YTickList, Canv, FYAxis, FYAxis.Position, 'Y') ;

        { Plot Y axis label }
        if FyAxisLabelAtTop then begin
           { Plot label at top of Y axis }
           Canv.TextOut( FYAxis.Position, YLabelYPos, FyAxis.Lab ) ;
           end
        else begin
           { Plot label along Y axis, rotated 90 degrees }
           yPix := ((FBottom - FTop) div 2) + FTop
                   + Canv.TextWidth( FYAxis.Lab ) div 2 ;
           TextOutRotated( Canv, YLabelXPos, yPix, FYAxis.Lab, 90 ) ;
           end ;
     finally

        XTickList.Mantissa.Free ;
        XTickList.Exponent.Free ;
        YTickList.Mantissa.Free ;
        YTickList.Exponent.Free ;

        end ;

     End ;


procedure TXYPlotDisplay.DefineAxis(
          var Axis : TAxis ;         { Axis description record (OUT) }
          AxisType : char            { Type of axis 'X' or 'Y' (IN) }
          ) ;
{ -------------------------------------------------------
  Find a suitable min/max range and ticks for a plot axis
  -------------------------------------------------------}
var
   R,Max,Min,MinPositive,Range,YSum,YScale : Single ;
   L,i : Integer ;
   pXY : pChar ;
begin

     { Find max./min. range of data }
     Min := MaxSingle ;
     Max := -MaxSingle ;
     MinPositive := MaxSingle ;
     for L := 0 to High(FLines) do if FLines[L].XYBuf <> Nil then begin

         { Compute percentage scale factor, if this is a histogram with a % Y axis }
         if (FLines[L].LineType = ltHistogram) and FHistogramPercentage then begin
            YScale := 0.0 ;
            For i := 0 To FLines[L].NumPoints-1 do begin
                pXY := Pointer( Integer(FLines[L].XYBuf) + i*SizeOf(THist))  ;
                YScale := YScale + THistPointer(pXY)^.y ;
                end ;
            YScale := 100.0 / YScale ;
            end
         else YScale := 1.0 ;

         YSum := 0.0 ;
         For i := 0 To FLines[L].NumPoints-1 do begin
             if FLines[L].LineType = ltHistogram then begin
                 { Histogram data }
                 pXY := Pointer( Integer(FLines[L].XYBuf) + i*SizeOf(THist))  ;
                 If AxisType = 'X' Then begin
                    { X axis }
                    R := THistPointer(pXY)^.Lo ;
                    if R < Min then Min := R ;
                    If (R > 0) And (R <= MinPositive) Then MinPositive := R ;
                    R := THistPointer(pXY)^.Hi ;
                    if R >= Max Then Max := R ;
                    If (R > 0) And (R <= MinPositive) Then MinPositive := R ;
                    end
                 else begin
                    { Y Axis }
                    if FHistogramCumulative then begin
                       YSum := YSum + THistPointer(pXY)^.y*YScale ;
                       R := YSum ;
                       end
                    else begin
                       R := THistPointer(pXY)^.y*YScale ;
                       end ;
                    end ;
                 end
             else begin
                 { X/Y data }
                 pXY := Pointer( Integer(FLines[L].XYBuf) + i*SizeOf(TXY))  ;
                 If AxisType = 'X' Then R := TXYPointer(pXY)^.x
                                   else R := TXYPointer(pXY)^.y ;
                 end ;

             If R < Min Then Min := R ;
             If R > Max Then Max := R ;
             If (R > 0) And (R <= MinPositive) Then MinPositive := R ;

             end ;

         end ;

    Axis.Hi := Max ;
    Axis.Lo := Min ;

    { Adjust axis range if Min and Max are same value }
    if Abs(Axis.Hi - Axis.Lo) <= 1E-37 then begin
       if Axis.Hi < 0. then begin
          Axis.Lo := Axis.Lo*2. ;
          Axis.Hi := 0. ;
          end
       else begin
            Axis.Hi := Axis.Hi * 2. ;
            if Axis.Hi = 0. then Axis.Hi := Axis.Hi + 1. ;
            Axis.Lo := 0. ;
            end ;
       end ;

    Case Axis.Law of

        {* Linear axis *}
        axLinear : begin
           { Set upper limit of axis }
           { If Upper limit is (or is close to zero) set to zero }
           If Abs(Axis.Hi) <= 1E-37 Then Axis.Hi := 0. ;
           If Abs(Axis.Lo) <= 1E-37 Then Axis.Lo := 0. ;

           { Use zero as one of the limits, if the range of data points
             is not to narrow. }
           If (Axis.Hi > 0. ) And (Axis.Lo > 0. ) And
              ( Abs( (Axis.Hi - Axis.Lo)/Axis.Hi ) > 0.1 ) Then Axis.Lo := 0.
           Else If (Axis.Hi < 0. ) And (Axis.Lo < 0. ) And
              ( Abs( (Axis.Lo - Axis.Hi)/Axis.Lo ) > 0.1 ) Then Axis.Hi := 0. ;

           { Choose a tick interval ( 1, 2, 2.5, 5 ) }
           Range := Abs(Axis.Hi - Axis.Lo) ;
           Axis.Tick := TickSpacing( Range ) ;
           end ;

        {* Square root axis *}
        axSquareRoot : begin
           { Set lower limit of axis }
//           Axis.Lo := MinPositive ;
           Axis.Lo := 0.0 ;
           { Choose a tick interval ( 1, 2, 2.5, 5 ) }
           Axis.Tick := TickSpacing( Abs(Axis.Hi - Axis.Lo) ) ;
           end ;

        { * Logarithmic axis * }
        axLog : begin

           {Set upper limit }
           if Log10(Max) >= 0.0 then Axis.Hi := AntiLog10(int(log10(Max)))
                                else Axis.Hi := AntiLog10(int(log10(Max))-1.0) ;
           i := 1 ;
           while (Axis.Hi*i <= Max) and (i<10) do Inc(i) ;
           Axis.Hi := Axis.Hi*i ;

           { Set lower limit (note that minimum *positive* value
             is used since log. axes cannot deal with negative numbers) }

           if Log10(MinPositive) >= 0.0 then
              Axis.Lo := AntiLog10(int(log10(MinPositive))+1.0)
           else Axis.Lo := AntiLog10(int(log10(MinPositive))) ;
           i := 10 ;
           while (Axis.Lo*i*0.1 >= MinPositive) and (i>1) do Dec(i) ;
           Axis.Lo := Axis.Lo*i*0.1 ;
           Axis.tick := 10. ;
           end ;
        end ;

    end ;


procedure TXYPlotDisplay.DrawMarkers(
          Canv : TCanvas ; { Canvas on which line is to be drawn (OUT) }
          MarkerSize : Integer
          ) ;
{ ----------------------
   Draw markers on plot
  ----------------------}
var
   xPix,yPix,i,L : Integer ;
   x,y : single ;
   SavePen : TPen ;
   SaveBrush : TBrush ;
   MarkerColor : TColor ;
   pXY : pChar ;
begin

     { Create  objects }
     SavePen := TPen.Create ;
     SaveBrush := TBrush.Create ;

     try
        { Save current pen and brush settings }
        SavePen.Assign(Canv.Pen) ;
        SaveBrush.Assign( Canv.Brush ) ;

        for L := 0 to High(FLines) do
            if  (FLines[L].XYBuf <> Nil)
            and (FLines[L].LineType = ltLine) then begin

            if (FOutputToScreen = False) and FPrinterDisableColor then
               MarkerColor := clBlack
            else MarkerColor := FLines[L].Color ;

            { Set pen/brush properties for markers }
            with Canv.Pen do begin
                 Style := psSolid ;
                 Width := FLineWidth ;
                 Color := MarkerColor ;
                 end ;

            Canv.Brush.Color := MarkerColor ;
            case FLines[L].MarkerStyle of
                 msOpenSquare,
                 msOpenCircle,
                 msOpenTriangle,
                 msNumber : begin
                     Canv.Brush.Style := bsClear ;
                     end ;
                 msSolidSquare, msSolidCircle, msSolidTriangle : begin
                     Canv.brush.style := bsSolid ;
                     end ;
                 end ;

            if FLines[L].MarkerStyle <> msNone then begin
               for i := 0 to FLines[L].NumPoints-1 do begin
                   pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(TXY)))  ;
                   x := TXYPointer(pXY)^.x ;
                   y := TXYPointer(pXY)^.y ;
                   if (FXAxis.Lo <= x) and (x <= FXAxis.Hi) and
                      (FYAxis.Lo <= y) and (y <= FYAxis.Hi) then begin
                      xPix := XToCanvasCoord( x ) ;
                      yPix := YToCanvasCoord( y ) ;
                      DrawMarkerShape( Canv, xPix, yPix, FLines[L], MarkerSize ) ;
                      end ;
                   end ;
               end ;

            end ;
        { Restore pen settings }
        Canv.Pen.Assign(SavePen) ;
        Canv.Brush.Assign(SaveBrush) ;
     finally
          SavePen.Free ;
          SaveBrush.Free ;
          end ;

     end ;


procedure TXYPlotDisplay.DrawMarkerShape(
          Canv : TCanvas ;
          xPix,yPix : Integer ;
          const LineInfo : TLine ;
          MarkerSize : Integer
          ) ;
var
   HalfSize : Integer ;
   s : string ;
begin

     {Marker Size }
     HalfSize := MarkerSize div 2 ;

     { Draw Marker }
     case LineInfo.MarkerStyle of
          msSolidSquare, msOpenSquare :
                Canv.rectangle( xPix - HalfSize, yPix - HalfSize,
                                xPix + HalfSize, yPix + HalfSize ) ;
          msSolidCircle, msOpenCircle :
                Canv.Ellipse( xPix - HalfSize, yPix - HalfSize,
                              xPix + HalfSize, yPix + HalfSize ) ;
          msSolidTriangle, msOpenTriangle :
                Canv.Polygon( [Point(xPix - HalfSize,yPix + HalfSize),
                               Point(xPix + HalfSize,yPix + HalfSize),
                               Point(xPix ,yPix - HalfSize)] )  ;
          msNumber : begin
                Canv.Font.Height := MarkerSize ;
                Canv.rectangle( xPix - HalfSize, yPix - HalfSize,
                                xPix + HalfSize, yPix + HalfSize ) ;
                s := format('%d',[LineInfo.Num]) ;
                Canv.TextOut( xPix - (Canv.TextWidth(s) div 2),
                              yPix - (Canv.TextHeight(s) div 2),
                              s);
                end ;
          msPlus : begin
                Canv.PolyLine( [ Point(xPix - HalfSize,yPix),
                             Point(xPix + HalfSize,yPix) ]) ;
                Canv.PolyLine( [ Point(xPix,yPix - HalfSize),
                             Point(xPix,yPix + HalfSize) ]) ;
                end ;
          msMinus : begin
                Canv.PolyLine( [ Point(xPix - HalfSize,yPix),
                             Point(xPix + HalfSize,yPix) ]) ;
                end ;
          end ;
     end ;


procedure TXYPlotDisplay.DrawLines(
          Canv : TCanvas  { Canvas on which line is to be drawn (OUT) }
          ) ;
{ -------------------
   Draw lines on plot
  -------------------}
var
   xPix,yPix,i,L : Integer ;
   x, y : single ;
   OutOfRange, LineBreak : Boolean ;
   SavePen : TPen ;
   pXY : pChar ;
begin
     { Create objects }
     SavePen := TPen.Create ;

     try
        { Save current pen settings }
        SavePen.Assign(Canv.Pen) ;

        { Plot all lines within plotting data list }

        for L := 0 to High(FLines) do
            if  (FLines[L].XYBuf <> Nil)
            and (FLines[L].LineType = ltLine) then begin

            { Set line colour }
            if (FOutputToScreen = False) and FPrinterDisableColor then
               Canv.Pen.Color := clBlack
            else Canv.Pen.Color := FLines[L].Color ;

            { Plot line, if it is visible }
            if FLines[L].LineStyle <> psClear then begin
               { Set line style }
               Canv.Pen.Style := FLines[L].LineStyle ;
               LineBreak := True ;
               { Plot line }
               for i := 0 to FLines[L].NumPoints-1 do begin
                   { Get point from buffer }
                   pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(TXY)))  ;
                   x := TXYPointer(pXY)^.x ;
                   y := TXYPointer(pXY)^.y ;
                   { Check that point is on plot }
                   if (x < FXAxis.Lo ) or (x > FXAxis.Hi) or
                      (y < FYAxis.Lo ) or (y > FYAxis.Hi) then OutOfRange := True
                                                          else OutOfRange := False ;
                   { Plot point if within axes range }
                   if not OutOfRange then begin
                      xPix := XToCanvasCoord( x ) ;
                      yPix := YToCanvasCoord( y ) ;
                      if LineBreak then Canv.MoveTo( xPix, yPix ) ;
                                        Canv.LineTo( xPix, yPix ) ;
                      LineBreak := False ;
                      end
                   else LineBreak := True ;
                   end ;
               end ;
            end ;
        { Restore original pen settings }
        Canv.Pen.Assign(SavePen) ;
     finally
            { Dispose of objects }
            SavePen.Free ;
            end ;
     end ;


procedure TXYPlotDisplay.DrawHistograms(
          Canv : TCanvas  { Canvas on which line is to be drawn (OUT) }
          ) ;
{ ----------------------------------
   Draw histogram bars lines on plot
  ----------------------------------}
var
   xPixLo,xPixHi,yPix,yPix0, i,L : Integer ;
   BinLo,BinHi,BinY,YScale,Sum : single ;
   SavePen : TPen ;
   SaveBrush : TBrush ;
   pXY : pChar ;
   FirstBin, OffYAxis : boolean ;
begin
     { Create objects }
     SavePen := TPen.Create ;
     SaveBrush := TBrush.Create ;

        { Save current pen/brush settings }
        SavePen.Assign(Canv.Pen) ;
        SaveBrush.Assign(Canv.Brush) ;

        for L := 0 to High(FLines) do
            if  (FLines[L].XYBuf <> Nil)
            and (FLines[L].LineType = ltHistogram) then begin

            { Set bin fill style }
            if (FOutputToScreen = False) and FPrinterDisableColor then
               Canv.Brush.Color := clBlack
            else Canv.Brush.Color := FHistogramFillColor ;

            Canv.Brush.Color := FHistogramFillColor ;
            Canv.Brush.Style := FHistogramFillStyle ;

            { Set line colour }
            Canv.Pen.Color := clBlack ;

            { Set bottom of bar at Y=0.0, unless log axis }
            if FYAxis.Law = axLog then yPix0 := FBottom
                                  else yPix0 := YToCanvasCoord( 0.0 ) ;

            { If a percentage histogram is required,
              calculate scaling factor to convert to % }
            if FHistogramPercentage then begin
               Sum := 0.0 ;
               for i := 0 to FLines[L].NumPoints-1 do begin
                   pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(THist)))  ;
                   Sum := Sum + THistPointer(pXY)^.y ;
                   end ;
               YScale := 100.0 / Sum ;
               end
            else YScale := 1.0 ;

            FirstBin := True ;
            BinY := 0.0 ;
            for i := 0 to FLines[L].NumPoints-1 do begin

                pXY := Pointer( Integer(FLines[L].XYBuf) + (i*SizeOf(THist)))  ;
                BinLo := THistPointer(pXY)^.Lo ;
                BinHi := THistPointer(pXY)^.Hi ;

                if FHistogramCumulative then BinY := BinY + THistPointer(pXY)^.y*YScale
                                        else BinY :=THistPointer(pXY)^.y*YScale ;

                if (BinLo >= FXAxis.Lo) and (BinHi <= FXAxis.Hi) then begin

                   { Keep bin Y value to limits of plot, but determine
                     whether it has gone off scale }

                   OffYAxis := False ;
                   if BinY < FYAxis.Lo then begin
                      BinY := FYAxis.Lo ;
                      OffYAxis := True ;
                      end ;
                   if BinY > FYAxis.Hi then begin
                      BinY := FYAxis.Hi ;
                      OffYAxis := True ;
                      end ;

                   { Convert to window coordinates }
                   xPixLo := XToCanvasCoord( BinLo ) ;
                   xPixHi := XToCanvasCoord( BinHi ) ;
                   yPix :=   YToCanvasCoord( BinY ) ;

                   if Canv.Brush.Style <> bsClear then
                      Canv.FillRect( Rect( xPixLo, yPix, xPixHi, yPix0 ) ) ;

                   { Draw left edge of histogram box }

                   if FirstBin then begin
                      Canv.MoveTo( xPixLo,yPix0 ) ;
                      FirstBin := False ;
                      end ;

                   Canv.lineto( xPixLo,yPix ) ;

                   { Draw top of histogram box (but not if bin is off scale) }
                   if OffYAxis then Canv.MoveTo( xPixHi,yPix )
                               else Canv.LineTo( xPixHi,yPix ) ;

                   { Plot right hand edge of bin if all edges of bin are to
                     be displayed }
                   if FHistogramFullBorders then Canv.LineTo( xPixHi,yPix0 ) ;
                   end ;
                end ;

            { Make sure right hand edge of last bin is drawn }
            if (BinHi <= FXAxis.Hi) then Canv.LineTo( xPixHi,yPix0 ) ;

            end ;

        { Restore original pen settings }
        Canv.Pen.Assign(SavePen) ;
        Canv.Brush.Assign(SaveBrush) ;

            { Dispose of objects }
            SavePen.Free ;
            SaveBrush.Free ;
            end ;




procedure TXYPlotDisplay.Print ;
{ -----------------------
  Print hard copy of plot
  -----------------------}
var
   KeepLineWidth : Integer ;
begin

     // Exit if no printers
     if Printer.Printers.Count <= 0 then Exit ;

     // Exit if no lines
     if not GetLinesAvailable then Exit ;

     FPrinting := True ;

     Printer.BeginDoc ;
     Cursor := crHourglass ;


        Printer.Canvas.Pen.Color := clBlack ;
        Printer.Canvas.Font.Name := FPrinterFontName ;
        Printer.Canvas.font.size := FPrinterFontSize ;
        KeepLineWidth := FLineWidth ;
        FLineWidth := PrinterPointsToPixels(FPrinterLineWidth) ;
     try
        { Set bounding rectangle of plot on printed page }
        FLeft := FPrinterLeftMargin ;
        FRight := Printer.PageWidth - FPrinterRightMargin ;
        FTop := FPrinterTopMargin ;
        FBottom := Printer.PageHeight - FPrinterBottomMargin ;

        { Print title text }
        CodedTextOut( Printer.Canvas, FLeft, FTop, FTitle ) ;
        FTop := FTop + Printer.Canvas.TextHeight('X') ;

        FOutputToScreen := False ;
        DrawAxes( Printer.Canvas ) ;
        DrawHistograms( Printer.Canvas ) ;
        if FShowLines then DrawLines( Printer.Canvas ) ;
        if FShowMarkers then DrawMarkers( Printer.Canvas,
                                          PrinterPointsToPixels(FPrinterMarkerSize) ) ;

     finally

        { Close down printer }
        FLineWidth := KeepLineWidth ;
        Printer.EndDoc ;
        Cursor := crDefault ;
        FPrinting := False ;
        Invalidate ; // to ensure display is repainted
        end ;

     end ;

procedure TXYPlotDisplay.CodedTextOut(
          Canvas : TCanvas ;
          var LineLeft : Integer ;
          var LineYPos : Integer ;
          List : TStringList
          ) ;
var
   DefaultFont : TFont ;
   Line,LineSpacing,YSuperscriptShift,YSubscriptShift,i,X,Y : Integer ;
   Done : Boolean ;
   TextLine : string ;
begin

     try

     // Store default font settings
     DefaultFont := TFont.Create ;
     DefaultFont.Assign(Canvas.Font) ;

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

         end ;

     // Restore default font setting
     Canvas.Font.Assign(DefaultFont) ;

     finally

            DefaultFont.Free ;

            end ;

     end ;



procedure TXYPlotDisplay.ClearPrinterTitle ;
{ -------------------------
  Clear printer title lines
  -------------------------}
begin
     FTitle.Clear ;
     end ;


procedure TXYPlotDisplay.AddPrinterTitleLine(
          Line : string
          );
{ ---------------------------
  Add a line to printer title
  ---------------------------}
begin
     FTitle.Add( Line ) ;
     end ;




function TXYPlotDisplay.XToCanvasCoord(
         Value : single
         ) : Integer  ;
begin
     { Calculate Axes data-->pixel scaling factors }
     if FXAxis.Hi1 <> FXAxis.Lo1 then
        FXAxis.Scale := Abs(FRight - FLeft) / Abs(FXAxis.Hi1 - FXAxis.Lo1)
     else FXAxis.Scale := 1.0 ;
     case FXAxis.Law of
          axLog : Value := log10(Value) ;
          axSquareRoot : Value:= sqrt(Value) ;
          end ;
     Result := Round( (Value - FXAxis.Lo1)*FXAxis.Scale + FLeft ) ;
     end ;


{ ----------------------------------
  Ensure plot axis has a valid range
  ----------------------------------}
procedure TXYPlotDisplay.CheckAxis(
          var Axis : TAxis
          ) ;
begin

     Axis.Lo1 := Axis.Lo ;
     Axis.Hi1 := Axis.Hi ;
     case Axis.Law of
          axLog : begin
                If Axis.Hi1 <= 0. Then Axis.Hi1 := 1. ;
                If Axis.Lo1 <= 0. Then Axis.Lo1 := Axis.Hi1 * 0.01 ;
                Axis.Hi1 := log10(Axis.Hi1) ;
                Axis.Lo1 := log10(Axis.Lo1) ;
                end ;
          axSquareRoot : begin
                If Axis.Hi1 <= 0. Then Axis.Hi1 := 1. ;
                If Axis.Lo1 <= 0. Then Axis.Lo1 := 0.0 ;//Axis.Hi1 * 0.01 ;
                Axis.Hi1 := Sqrt(Axis.Hi1) ;
                Axis.Lo1 := Sqrt(Axis.Lo1) ;
                end ;
          end ;


     { Ensure that axes have non-zero ranges and tics }
     If Axis.Hi1 = Axis.Lo1 Then Axis.Hi1 := Axis.Lo1 + 1. ;
     if Axis.Tick <= 0.0 then Axis.tick := (Axis.Hi1 - Axis.Lo1) / 5.0 ;

     Axis.Lo := Axis.Lo1 ;
     Axis.Hi := Axis.Hi1 ;
     case Axis.Law of
          axLog : begin
                Axis.Lo := Antilog10( Axis.Lo ) ;
                Axis.Hi := Antilog10( Axis.Hi ) ;
                end ;
          axSquareRoot : begin
                Axis.Lo := Sqr( Axis.Lo ) ;
                Axis.Hi := Sqr( Axis.Hi ) ;
                end ;
          end ;

     end ;


function TXYPlotDisplay.CanvasToXCoord(
         xPix : Integer
         ) : single  ;
var
   Value : single ;
begin
     { Calculate Axes data-->pixel scaling factors }
     if FXAxis.Hi1 <> FXAxis.Lo1 then
        FXAxis.Scale := Abs(FRight - FLeft) / Abs(FXAxis.Hi1 - FXAxis.Lo1)
     else FXAxis.Scale := 1.0 ;

     Value := (xPix - FLeft)/FXAxis.Scale + FXAxis.Lo1 ;

     case FXAxis.Law of
          axLog : Value := AntiLog10(Value) ;
          axSquareRoot : Value:= Sqr(Value) ;
          end ;

     Result := Value ;
     end ;


function TXYPlotDisplay.YToCanvasCoord(
         Value : single
         ) : Integer  ;
begin
     { Calculate Axes data-->pixel scaling factors }
     if FYAxis.Hi1 <> FYAxis.Lo1 then
        FYAxis.Scale := Abs(FBottom - FTop) / Abs(FYAxis.Hi1 - FYAxis.Lo1)
     else FYAxis.Scale := 1.0 ;

     case FYAxis.Law of
          axLog : Value := log10(Value) ;
          axSquareRoot : Value := sqrt(Value) ;
          end ;

     Result := Round( FBottom - (Value - FYAxis.Lo1)*FYAxis.Scale ) ;
     end ;


function TXYPlotDisplay.CanvasToYCoord(
         yPix : Integer
         ) : single  ;
var
   Value : single ;
begin
     { Calculate Axes data-->pixel scaling factors }
     if FYAxis.Hi1 <> FYAxis.Lo1 then
        FYAxis.Scale := Abs(FBottom - FTop) / Abs(FYAxis.Hi1 - FYAxis.Lo1)
     else FYAxis.Scale := 1.0 ;

     FYAxis.Scale := Abs(FBottom - FTop) / Abs(FYAxis.Hi1 - FYAxis.Lo1) ;
     Value := (FBottom - yPix)/FYAxis.Scale + FYAxis.Lo1 ;

     case FYAxis.Law of
          axLog : Value := Antilog10(Value) ;
          axSquareRoot : Value:= Sqr(Value) ;
          end ;

     Result := Value ;
     end ;


procedure TXYPlotDisplay.TextOutRotated(
          CV : TCanvas ;
          xPix,yPix : Integer ;
          Text : String ;
          Angle : Integer ) ;
{ ---------------------------------------------
  Draw text rotated at an angle from horizontal
  ---------------------------------------------}
var
   LogFont : TLogFont ;
begin
     GetObject( CV.Font.Handle, SizeOf(TLogFont), @LogFont ) ;
     LogFont.lfEscapement := Angle*10 ;
     CV.Font.Handle := CreateFontIndirect(LogFont) ;
     CV.TextOut( xPix, yPix, Text ) ;
     LogFont.lfEscapement := 0 ;
     CV.Font.Handle := CreateFontIndirect(LogFont) ;
     end ;


procedure TXYPlotDisplay.CreateTickList(
          var TickList : TTickList ;
          Canv : TCanvas ;
          Var Axis : TAxis
          ) ;
{ ---------------------------------------------
  Create TickList using settings from plot axis
  ---------------------------------------------}
var
   x,xEnd,xNeg,xSmallTick : single ;
   i : Integer ;
begin

     TickList.NumTicks := 0 ;

     case Axis.Law of
          { ** Logarithmic tics ** }
          axLog : begin
              { Set starting point at first power of 10 below minimum }
              if Axis.Lo1 > 0.0 then x := Int(Axis.Lo1)
                                else x := Int(Axis.Lo1) - 1.0 ;

              While x <= Axis.Hi1 do begin
                  { Add labelled tick }
                  if x >= Axis.Lo1 then AddTick(TickList,Axis,AntiLog10(x),True ) ;
                  { Add unlabelled ticks }
                  xSmallTick := AntiLog10(x) ;
                  for i := 2 to 9 do if ((xSmallTick*i) <= Axis.Hi)
                      and ((xSmallTick*i) >= Axis.Lo) then begin
                      AddTick(TickList,Axis,xSmallTick*i,False ) ;
                      end ;
                  x := x + 1. ;
                  end ;
              end ;

          { ** Linear ticks ** }
          axLinear : begin
              { Note. If axis include zero make ticks always start from there }
              if (Axis.Lo*Axis.Hi) <= 0. then begin
                 x := 0. ;
                 xEnd := Max( Abs(Axis.Lo),Abs(Axis.Hi) ) ;
                 end
              else begin
                 x := Axis.Lo ;
                 xEnd := Axis.Hi ;
                 end ;

              While x <= xEnd do begin
                    if x <= Axis.Hi then AddTick(TickList,Axis,x,True ) ;
                    xNeg := -x ;
                    if xNeg >= Axis.Lo then AddTick(TickList,Axis,xNeg,True ) ;
                    x := x + Axis.tick ;
                    end ;
              end ;

          { ** Square root ticks ** }
          axSquareRoot : begin
              x := Axis.Lo ;
              While x <= Axis.Hi do begin
                    if x <= Axis.Hi then AddTick(TickList,Axis,x,True ) ;
                    x := x + Axis.tick ;
                    end ;
              end ;

          end ;

     { Calculate width of widest tick }
     CalculateTicksWidth( TickList, Canv ) ;
     { Calculate height of highest tick }
     CalculateTicksHeight( TickList, Canv ) ;

     end ;


procedure TXYPlotDisplay.CalculateTicksWidth(
          var TickList : TTickList ;
          const Canv : TCanvas    { Drawing surface }
          )  ;
{ ------------------------------------
  Return maximum width of tick strings
  ------------------------------------}
var
   i, TickWidth : Integer ;
begin
     with TickList do begin
          MaxWidth := 0 ;
          for i := 0 to NumTicks-1 do begin
              TickWidth := Canv.TextWidth(Mantissa[i]) + Canv.TextWidth(Exponent[i]) ;
              if TickWidth > MaxWidth then MaxWidth := TickWidth ;
              end ;
          end ;
    end ;


{ -------------------------------------
  Return maximum height of tick strings
  -------------------------------------}
procedure TXYPlotDisplay.CalculateTicksHeight(
          var TickList : TTickList ;
          const Canv : TCanvas    { Drawing surface }
          ) ;
var
   i,TickHeight : integer ;
begin

     With TickList do begin
          MaxHeight := 0 ;
          for i := 0 to NumTicks-1 do begin
              TickHeight := Canv.TextHeight(Mantissa[i]) ;
              if (Exponent[i] <> '') then
                 TickHeight := TickHeight + 2*(Canv.TextHeight(Exponent[i]) div 3) ;
              if TickHeight > MaxHeight then MaxHeight := TickHeight ;
              end ;
          end ;
     end ;


procedure TXYPlotDisplay.DrawTicks(
          var TickList : TTickList ; { List of ticks }
          const Canv : TCanvas ;     { Drawing surface }
          var Axis : TAxis ;         { Axis definition }
          AxisPosition : Integer ;   { Position of axis (pixels) }
          AxisType : string ) ;      { Type of axis 'X' or 'Y' }
{ ----------------------------------------------------------------
  Draw ticks contained in TickList object on selected axis of plot
  ----------------------------------------------------------------}

var
   TickSize,i,xPixLabel,yPixLabel,xPix,yPix : Integer ;
begin
     with TickList do begin
          for i := 0 to NumTicks-1 do begin
              { Plot tick line and value }
              If AxisType = 'X' Then begin
                 { X axis tick }
                 TickSize := Canv.TextHeight('X') div 2 ;
                 yPix := AxisPosition ;
                 xPix := XToCanvasCoord( Value[i] ) ;
                 Canv.polyline( [ Point(xPix,yPix), Point(xPix,yPix+TickSize)]) ;
                 yPixLabel := yPix + TickSize + MaxHeight
                              - (4*Canv.TextHeight(Mantissa.Strings[i]) div 5 ) ;
                 xPixLabel := xPix - (Canv.TextWidth(Mantissa.Strings[i]) div 2) ;
                 end
              else begin
                { Y axis tick }
                TickSize := Canv.TextWidth('X') ;
                xPix := AxisPosition ;
                yPix := YToCanvasCoord( Value[i] ) ;
                Canv.polyline( [ Point(xPix,yPix), Point(xPix-TickSize,yPix)]) ;
                { Calculate starting position of label }
                xPixLabel := xPix - TickSize
                             - Canv.TextWidth(Mantissa.Strings[i]
                             + Exponent.Strings[i] + ' ') ;
                yPixLabel := yPix - (Canv.TextHeight(Mantissa.Strings[i]) div 2);
                end ;

              if Mantissa.Strings[i] <> '' then begin
                 Canv.TextOut( xPixLabel, yPixLabel, Mantissa.Strings[i] ) ;
                 if Exponent.Strings[i] <> '' then Canv.TextOut(
                    xPixLabel + Canv.TextWidth(Mantissa.Strings[i]),
                    yPixLabel - ((TickSize) div 2), Exponent.Strings[i] ) ;
                 end ;
              end ;
          end ;
     end ;


procedure TXYPlotDisplay.AddTick(
          var TickList : TTickList ;
          var Axis : TAxis ;           { Plot axis to which tick belongs }
          TickValue : single ;         { Tick value }
          Labelled : Boolean           { True = labelled tick }
          ) ;
{ -----------------------------
  Add a tick string to TickList
  -----------------------------}

var
   i : Integer ;
   TickString,TempString : string ;
   PowerOfTen : Boolean ;
begin

    { Get tick value. If this is a logarithmic axis set PowerofTen% = TRUE
    to force the tick to be displayed as a power of ten irrespective of
    its magnitude }

    with TickList do begin

         If Axis.Law = axLog Then PowerofTen := True
                             else PowerofTen := False ;

         Value[NumTicks] := TickValue ;

         if Labelled then begin
            { ** Turn tick value into string ** }
            If TickValue = 0.0 Then begin
               { Zero value }
               Mantissa.Add('0') ;
               Exponent.Add('') ;
               PowerofTen := False ;
               end
            Else If (Abs(TickValue) <= 999. )
               And  (Abs(TickValue) >= 0.01 )
               And  (PowerofTen = False) Then begin
               { Print values }
               Mantissa.Add(TidyNumber(Format('%8.3g',[TickValue]))) ;
               PowerofTen := False ;
               Exponent.Add( '' ) ;
               end
            Else begin
              { Create tick as scientic notation (e.g. 2.E+003 )
                and separate out its mantissa and exponent, i.e.
                      3
                2 x 10 (Note this mode is always used if axis is logarithmic) }

              TickString := Format('%12.1e', [TickValue] ) ;
              i := Pos('E',TickString) ;
              If i > 0 Then begin
                 { Extract mantissa part of number }
                 TempString := Copy( TickString, 1, i-1 ) ;
                 TempString := TidyNumber(TempString) + 'x10'  ;
                 If TempString = '1.0x10' Then TempString := '10' ;
                 Mantissa.Add( TempString ) ;
                 { Get sign of exponent }
                 i := i + 1 ;
                 TempString := Copy(TickString, i, Length(TickString)-i+1 ) ;
                 TempString := IntToStr( ExtractInt( TempString ) );
                 Exponent.Add( TempString ) ;
                 PowerofTen := True ;
                 end ;
              end ;
            end
         else begin
              { ** Unlabelled ticks }
              Mantissa.Add('') ;
              Exponent.Add('') ;
              end ;

         Inc(NumTicks) ;
         end ;

    end ;


procedure TXYPlotDisplay.SortByX(
          Line : Integer
          ) ;
{ ------------------------------------
  Sort X,Y data into ascending X order
  ------------------------------------}
var
   Current,Last : Integer ;
   Temp : TXY ;
   pXY,pXYp1 : PChar ;
begin
     if (Line >= 0) and (Line <= High(FLines)) then begin
        if FLines[Line].LineType = ltLine then begin
           for Last := FLines[Line].NumPoints-1 DownTo 1 do begin
               for Current := 0 to Last-1 do begin
                   pXY := Pointer( Integer(FLines[Line].XYBuf) + (Current*SizeOf(TXY)))  ;
                   pXYp1 := Pointer( Integer(FLines[Line].XYBuf) + ((Current+1)*SizeOf(TXY)))  ;
                   if TXYPointer(pXY)^.x >  TXYPointer(pXYp1)^.x then begin
                      Temp := TXYPointer(pXY)^ ;
                      TXYPointer(pXY)^ := TXYPointer(pXYp1)^ ;
                      TXYPointer(pXYp1)^ := Temp ;
                      end ;
                   end ;
               end ;
           end ;
        end ;
     end ;



{ =========================================================
  Property Get/Set methods
  =========================================================}


function TXYPlotDisplay.GetLinesAvailable : Boolean ;
{ ----------------------------------------------------------------
  Return TRUE if there are lines/histograms available for plotting
  ---------------------------------------------------------------- }
Var
   L : Integer ;
begin
     { Determine if there are any lines to be plotted }
     FLinesAvailable := False ;
     for L := 0 to High(FLines) do if (FLines[L].XYBuf <> Nil)
         and (FLines[L].NumPoints > 0) then FLinesAvailable := True ;
     Result := FLinesAvailable ;
     end ;


procedure TXYPlotDisplay.SetMaxPointsPerLine(
          Value : Integer
          ) ;
// ----------------------------
// Set maximum points per lines
// ----------------------------
var
    L : Integer ;
begin
     // Clear all lines
     for L := 0 to High(FLines) do if (FLines[L].XYBuf <> Nil) then begin
         FreeMem(FLines[L].XYBuf) ;
         FLines[L].XYBuf := Nil ;
         FLines[L].NumPoints := 0 ;
         end ;
     FLinesAvailable := False ;

     FMaxPointsPerLine := Value ;

     end ;


procedure TXYPlotDisplay.SetXAxisMin( Value : single ) ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     FXAxis.Lo := Value ;
     Invalidate ;
     end ;

function TXYPlotDisplay.GetXAxisMin : single ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     Result := FXAxis.Lo ;
     end ;

procedure TXYPlotDisplay.SetXAxisMax( Value : single ) ;
{ ---------------------------
  Set Maximum of X axis range
  ---------------------------}
begin
     FXAxis.Hi := Value ;
     Invalidate ;
     end ;

function TXYPlotDisplay.GetXAxisMax : single ;
{ ---------------------------
  Set Maximum of X axis range
  ---------------------------}
begin
     Result := FXAxis.Hi ;
     end ;

procedure TXYPlotDisplay.SetXAxisTick( Value : single ) ;
{ --------------------------------
  Set tick spacing of X axis range
  --------------------------------}
begin
     FXAxis.Tick := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetXAxisTick : single ;
{ --------------------------------
  Set tick spacing of X axis range
  --------------------------------}
begin
     Result := FXAxis.Tick ;
     end ;


procedure TXYPlotDisplay.SetXAxisLaw( Value : TAxisLaw ) ;
{ ----------------------------------------------
  Set linear/log/square root law of X axis range
  ----------------------------------------------}
begin
     FXAxis.Law := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetXAxisLaw : TAxisLaw ;
{ ----------------------------------------------
  Get linear/log/square root law of X axis range
  ----------------------------------------------}
begin
     Result := FXAxis.Law ;
     end ;


procedure TXYPlotDisplay.SetXAxisAutoRange( Value : Boolean ) ;
{ -----------------------------------------
  Set automatic range setting flag of X axis
  -----------------------------------------}
begin
     FXAxis.AutoRange := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetXAxisAutoRange : Boolean ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FXAxis.AutoRange ;
     end ;


procedure TXYPlotDisplay.SetXAxisLabel( Value : string ) ;
{ ----------------
  Set X axis label
  ----------------}
begin
     FXAxis.Lab := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetXAxisLabel : string ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FXAxis.Lab ;
     end ;


procedure TXYPlotDisplay.SetYAxisMin( Value : single ) ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     FYAxis.Lo := Value ;
     Invalidate ;
     end ;

function TXYPlotDisplay.GetYAxisMin : single ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     Result := FYAxis.Lo ;
     end ;

procedure TXYPlotDisplay.SetYAxisMax( Value : single ) ;
{ ---------------------------
  Set Maximum of Y axis range
  ---------------------------}
begin
     FYAxis.Hi := Value ;
     Invalidate ;
     end ;

function TXYPlotDisplay.GetYAxisMax : single ;
{ ---------------------------
  Set Maximum of Y axis range
  ---------------------------}
begin
     Result := FYAxis.Hi ;
     end ;

procedure TXYPlotDisplay.SetYAxisTick( Value : single ) ;
{ --------------------------------
  Set tick spacing of Y axis range
  --------------------------------}
begin
     FYAxis.Tick := Value ;
     Invalidate ;
     end ;

function TXYPlotDisplay.GetYAxisTick : single ;
{ --------------------------------
  Set tick spacing of Y axis range
  --------------------------------}
begin
     Result := FYAxis.Tick ;
     end ;

procedure TXYPlotDisplay.SetYAxisLaw( Value : TAxisLaw ) ;
{ ----------------------------------------------
  Set linear/log/square root law of Y axis range
  ----------------------------------------------}
begin
     FYAxis.Law := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetYAxisLaw : TAxisLaw ;
{ ----------------------------------------------
  Get linear/log/square root law of Y axis range
  ----------------------------------------------}
begin
     Result := FYAxis.Law ;
     end ;


procedure TXYPlotDisplay.SetYAxisAutoRange( Value : Boolean ) ;
{ -----------------------------------------
  Set automatic range setting flag of X axis
  -----------------------------------------}
begin
     FYAxis.AutoRange := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetYAxisAutoRange : Boolean ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FYAxis.AutoRange ;
     end ;


procedure TXYPlotDisplay.SetYAxisLabel( Value : string ) ;
{ ----------------
  Set X axis label
  ----------------}
begin
     FYAxis.Lab := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetYAxisLabel : string ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FYAxis.Lab ;
     end ;

procedure TXYPlotDisplay.SetScreenFontName(
          Value : string
          ) ;
{ -----------------------
  Set screen font name
  ----------------------- }
begin
     FScreenFontName := Value ;
     end ;


function TXYPlotDisplay.GetScreenFontName : string ;
{ -----------------------
  Get screen font name
  ----------------------- }
begin
     Result := FScreenFontName ;
     end ;


procedure TXYPlotDisplay.SetPrinterFontName(
          Value : string
          ) ;
{ -----------------------
  Set printer font name
  ----------------------- }
begin
     FPrinterFontName := Value ;
     end ;


function TXYPlotDisplay.GetPrinterFontName : string ;
{ -----------------------
  Get printer font name
  ----------------------- }
begin
     Result := FPrinterFontName ;
     end ;


procedure TXYPlotDisplay.SetPrinterLeftMargin(
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


function TXYPlotDisplay.GetPrinterLeftMargin : integer ;
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


procedure TXYPlotDisplay.SetPrinterRightMargin(
          Value : Integer                    { Right margin (mm) }
          ) ;
{ -----------------------
  Set printer Right margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     if Printer.Printers.Count > 0 then begin
        FPrinterRightMargin := (Printer.PageWidth*Value)
                               div GetDeviceCaps( printer.handle, HORZSIZE ) ;
        end
     else FPrinterRightMargin := 0 ;
     end ;


function TXYPlotDisplay.GetPrinterRightMargin : integer ;
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


procedure TXYPlotDisplay.SetPrinterTopMargin(
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


function TXYPlotDisplay.GetPrinterTopMargin : integer ;
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


procedure TXYPlotDisplay.SetPrinterBottomMargin(
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


function TXYPlotDisplay.GetPrinterBottomMargin : integer ;
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


function TXYPlotDisplay.GetPrinterTitleCount : Integer ;
{ --------------------------------------------
  Get the number of lines in the printer title
  -------------------------------------------- }
begin
     Result := FTitle.Count ;
     end ;


procedure TXYPlotDisplay.SetPrinterTitleLines(
          Line : Integer ;
          Value : string
          ) ;
{ --------------------------------
  Set a line in the printer title
  ------------------------------- }
begin
     if (Line >= 0) and (Line <= (FTitle.Count-1)) then
        FTitle.Strings[Line] := Value ;
     end ;


function TXYPlotDisplay.GetPrinterTitleLines(
         Line : Integer
         ) : string  ;
{ --------------------------------
  Get a line in the printer title
  ------------------------------- }
begin
     if (Line >= 0) and (Line <= (FTitle.Count-1)) then
        Result := FTitle.Strings[Line]
     else Result := '' ;
     end ;


procedure TXYPlotDisplay.SetVertCursor(
          iCursor : Integer ;           { Cursor # }
          Value : single               { New Cursor position }
          )  ;
{ -------------------------------
  Set position of Vertical cursor
  -------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(VertCursors)) ;
     VertCursors[iCursor].Position := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetVertCursor(
         iCursor : Integer
         ) : single ;
{ -------------------------------
  Get position of vertical cursor
  -------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(VertCursors)) ;
     if VertCursors[iCursor].InUse then Result := VertCursors[iCursor].Position
                                   else Result := -1 ;
     end ;


procedure TXYPlotDisplay.SetHorCursor(
          iCursor : Integer ;           { Cursor # }
          Value : single               { New Cursor position }
          )  ;
{ -------------------------------
  Set position of horizontal cursor
  -------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(HorCursors)) ;
     HorCursors[iCursor].Position := Value ;
     Invalidate ;
     end ;


function TXYPlotDisplay.GetHorCursor(
         iCursor : Integer
         ) : single ;
{ -------------------------------
  Get position of horizontal cursor
  -------------------------------}
begin
     iCursor := IntLimitTo(iCursor,0,High(HorCursors)) ;
     if HorCursors[iCursor].InUse then Result := HorCursors[iCursor].Position
                                  else Result := -1 ;
     end ;


procedure TXYPlotDisplay.SetLineStyle(
          Line: Integer ;           { Line # }
          Value : TPenStyle         { New Style }
          )  ;
{ ----------------------
  Set line drawing style
  ----------------------}
begin
     if (Line >=0) and (Line <= High(FLines)) then begin
        FLines[Line].LineStyle := Value ;
        Invalidate ;
        end ;
     end ;


function TXYPlotDisplay.GetLineStyle(
         Line: Integer            { Line # }
         ) : TPenStyle ;
{ ----------------------
  Get line drawing style
  ----------------------}
begin
     Line := IntLimitTo(Line,0,High(FLines)) ;
     Result := FLines[Line].LineStyle ;
     end ;


procedure TXYPlotDisplay.SetMarkerStyle(
          Line: Integer ;           { Line # }
          Value : TMarkerStyle      { New Style }
          )  ;
{ ------------------------
  Set marker drawing style
  ------------------------}
begin
     if (Line >=0) and (Line <= High(FLines)) then begin
        FLines[Line].MarkerStyle := Value ;
        Invalidate ;
        end ;
     end ;


function TXYPlotDisplay.GetMarkerStyle(
        Line: Integer            { Line # }
        ) : TMarkerStyle ;
{ ----------------------
  Get line drawing style
  ----------------------}
begin
     Line := IntLimitTo(Line,0,High(FLines)) ;
     Result := FLines[Line].MarkerStyle ;
     end ;


function TXYPlotDisplay.GetNumLines : Integer ;
// ----------------------------------
// Return no. of active lines in plot
// ----------------------------------
var
    i : Integer ;
    NumLines : Integer ;
begin
    NumLines := 0 ;
    for i := 0 to MaxLines do if FLines[i].XYBuf <> Nil then Inc(NumLines) ;
    Result := NumLines ;
    end ;

{ ===================================================
  Miscellaneous support functions
  =================================================== }

function TXYPlotDisplay.Log10(
         x : Single
         ) : Single ;
{ -----------------------------------
  Return the logarithm (base 10) of x
  -----------------------------------}
begin

     if x > 0.0 then Log10 := ln(x) / ln(10. )
                else Log10 := -30 ;
     end ;


function TXYPlotDisplay.AntiLog10(
         x : single
         )  : Single ;
{ ---------------------------------------
  Return the antilogarithm (base 10) of x
  ---------------------------------------}
begin
     AntiLog10 := exp( x * ln( 10. ) ) ;
     end ;

function TXYPlotDisplay.IntLimitTo(
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

function TXYPlotDisplay.FloatLimitTo(
         Value : single ;          { Value to be checked }
         Lo :  single ;             { Lower limit }
         Hi :  single               { Upper limit }
         ) :  single ;              { Return limited value }
{ -----------------------------------------------
  Limit floating point Value to the range Lo - Hi
  -----------------------------------------------}
begin
     if Value < Lo then Value := Lo ;
     if Value > Hi then Value := Hi ;
     Result := Value ;
     end ;


function TXYPlotDisplay.ExtractInt (
         CBuf : string
         ) : Integer ;
{ ---------------------------------------------------
  Extract a 32 bit integer number from a string which
  may contain additional non-numeric text
  ---------------------------------------------------}

Type
    TState = (RemoveLeadingWhiteSpace, ReadNumber) ;
var CNum : string ;
    i : integer ;
    Quit : Boolean ;
    State : TState ;

begin
     CNum := '' ;
     i := 1;
     Quit := False ;
     State := RemoveLeadingWhiteSpace ;
     while not Quit do begin

           case State of

                { Ignore all non-numeric characters before number }
                RemoveLeadingWhiteSpace : begin
                   if CBuf[i] in ['0'..'9','+','-'] then State := ReadNumber
                                                    else i := i + 1 ;
                   end ;

                { Copy number into string CNum }
                ReadNumber : begin
                    {End copying when a non-numeric character
                    or the end of the string is encountered }
                    if CBuf[i] in ['0'..'9','E','e','+','-','.'] then begin
                       CNum := CNum + CBuf[i] ;
                       i := i + 1 ;
                       end
                    else Quit := True ;
                    end ;
                else end ;

           if i > Length(CBuf) then Quit := True ;
           end ;
     try


        ExtractInt := StrToInt( CNum ) ;
     except
        ExtractInt := 1 ;
        end ;
     end ;


function TXYPlotDisplay.TidyNumber(
         const RawNumber : string
         ) : string ;
var
   i0,i1 : Integer ;
begin
     i0 := 1 ;
     while (RawNumber[i0] = ' ') and (i0 < length(RawNumber)) do
           i0 := i0 + 1 ;
     i1 := length(RawNumber) ;
     while (RawNumber[i1] = ' ') and (i1 > 1) do i1 := i1 - 1 ;
     if i1 >= i0 then TidyNumber := Copy( RawNumber, i0, i1-i0+1 )
                 else TidyNumber := '?' ;
     end ;


function TXYPlotDisplay.PrinterPointsToPixels(
         PointSize : Integer
         ) : Integer ;
var
   PixelsPerInch : single ;
begin

     { Get height and width of page (in mm) and calculate
       the size of a pixel (in cm) }
     if Printer.Printers.Count > 0 then begin
        PixelsPerInch := GetDeviceCaps( printer.handle, LOGPIXELSX ) ;
        PrinterPointsToPixels := Trunc( (PointSize*PixelsPerInch) / 72. ) ;
        end
     else PrinterPointsToPixels := PointSize ;
     end ;


function TXYPlotDisplay.TickSpacing( Range : Single ) : Single ;
// -----------------------------------------
// Find a suitable integer axis tick spacing
// -----------------------------------------
const
    TickMultipliers : array[0..6] of Integer = (1,2,5,10,20,50,100) ;
var
    TickBase,TickSize : Single ;
    i : Integer ;
begin
    TickBase := 0.01*exp(Round(Log10(Abs(Range)))*ln(10.0)) ;
    for i := 0 to High(TickMultipliers) do begin
        TickSize := TickBase*TickMultipliers[i] ;
        if (Range/TickSize) <= 10 then Break ;
        end ;
    Result := TickSize ;
    end ;






end.
