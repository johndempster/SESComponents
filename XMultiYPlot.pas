unit XMultiYPlot;
{ ================================================
  Line graph/histogram display component
  with multiple Y axes and common X axis
  (c) J. Dempster, University of Strathclyde, 2002
  ================================================
  24/4/02 Modified from XYPlotDisplay.pas
  9/7/03  .NumLines property added (returns no. of lines in plot)
  22/7/03 .NumLinesInPlot[PlotNum] property added
  21.03.05 .AddAnnotaton .ClearAnnotions added
  06.04.05 X axis label no longer overlaps tick numbers
  26.04.06 Up to 100 lines can now be plotted
  20.07.07 Vertical cursor readout now integrated with plot
  22.08.07 Floating point error when .Log10(x) presented with 0 prevented
  05.08.08 Plots can be deleted individually
  14.05.09 Memory access violation blocked in .GetPoint when 0 points in line
 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Clipbrd, printers, strutils ;

const
     MaxLines = 1000 ;
     MaxPlots = 10 ;
     MaxSingle = 3.4E38 ;
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
                     msOpenSquare, msOpenCircle, msOpenTriangle,
                     msSolidSquare, msSolidCircle, msSolidTriangle ) ;
    TAxisLaw = (axLinear,axLog,axSquareRoot) ;

    TCursorPos = record
                 Position : single ;
                 Color : TColor ;
                 LineNum : Integer ;
                 InUse : Boolean ;
                 Text : String ;
                 end ;

    { Axis description record }
    TAxis = record
      InUse : Boolean ;
      PlotNum : Integer ;
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
      Bottom : Integer ;
      Top : Integer ;
      end ;

    TLine = record
              PlotNum : Integer ;
              NumPoints : Integer ;
              Color : TColor ;
              MarkerStyle : TMarkerStyle ;
              LineStyle : TPenStyle ;
              LineType : TLineType ;
              XYBuf : PChar ;
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

  TXMultiYPlot = class(TGraphicControl)
  private
    { Private declarations }
    FPlotNum : Integer ;
    FNumPlots : Integer ;           // No. of separate Y axes on plot
    FNumLines : Integer ;           // Total no. of lines on all plots
    FLinesAvailable : Boolean ;
    FMaxPointsPerLine : Integer ;
    FLines : Array[0..MaxLines] of TLine ;
    FNumLinesInPlot : Array[0..MaxPlots] of Integer ;
    FXAxis : TAxis ;
    FYAxis : Array[0..MaxPlots-1] of TAxis ;
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
    FVertCursorActive : Boolean ;
    FVertCursorSelected : Integer ;
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

    FMarkerText : TStringList ;   // Marker text list

    Bitmap : TBitMap ;        // Display background bitmap (graphs/axes)

    { Property get/set methods }
    procedure SetPlotNum( Value : Integer ) ;
    function GetLinesAvailable : Boolean ;
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

    procedure SetLineStyle(   Line: Integer ; Value : TPenStyle )  ;
    function  GetLineStyle(   Line: Integer ) : TPenStyle ;
    procedure SetMarkerStyle( Line: Integer ; Value : TMarkerStyle )  ;
    function  GetMarkerStyle( Line: Integer ) : TMarkerStyle ;
    function GetNumLinesInPlot( PlotNum : Integer ) : Integer ;
    function GetPlotExists( PlotNum : Integer ) : Boolean ;

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

    function Log10( x : Single ) : Single ;
    function AntiLog10( x : Single ) : Single ;
    function IntLimitTo( Value : Integer ; Lo : Integer ; Hi : Integer ) : Integer ;
    function FloatLimitTo( Value : single ; Lo :  single ; Hi :  single) :  single ;
    function MaxFlt( const Buf : array of Single ) : Single ;
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

    // Create a new plot on display
    function CreatePlot : Integer ;

    // Clear all plots from display
    procedure ClearAllPlots ;
    procedure ClearPlot( PlotNum : Integer ) ;

    // Create a new line on plot
    function CreateLine(
             Color : TColor ;
             MarkerStyle : TMarkerStyle ;
             LineStyle : TPenStyle
              ) : Integer ;

    // Free all line objects in plot
    procedure ClearAllLines ;

    procedure ClearLinesInPlot( PlotNum : Integer ) ;

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

    // Create a new histogram object on plot
    function CreateHistogram : Integer ;
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
    function AddVerticalCursor( Color : TColor ; Text : String ) : Integer ;
    function FindNearestIndex( LineIndex : Integer ; iCursor : Integer ) : Integer ;

    function XToCanvasCoord( Value : single ) : Integer  ;
    function CanvasToXCoord( xPix : Integer ) : single  ;
    function YToCanvasCoord( iPlot : Integer ; Value : single ) : Integer  ;
    function CanvasToYCoord( iPlot : Integer ; yPix : Integer ) : single  ;


    procedure Print ;
    procedure ClearPrinterTitle ;
    procedure AddPrinterTitleLine( Line : string );
    procedure CopyImageToClipboard ;
    procedure CopyDataToClipboard ;
    procedure SortByX( Line : Integer ) ;

    procedure AddAnnotation ( XValue : Single ; Text : String ) ;
    procedure ClearAnnotations ;
    procedure DrawAnnotations( Canv : TCanvas ) ;

    property LineStyles[Line : Integer] : TPenStyle
             read GetLineStyle write SetLineStyle ;
    property VerticalCursors[ i : Integer ] : single
             read GetVertCursor write SetVertCursor ;
    property MarkerStyles[Line : Integer] : TMarkerStyle
             read GetMarkerStyle write SetMarkerStyle ;
    property PrinterTitleLines[ i : Integer ] : string
             read GetPrinterTitleLines write SetPrinterTitleLines ;
    property NumLinesInPlot[PlotNum : Integer] : Integer
             read GetNumLinesInPlot ;
    property PlotExists[PlotNum : Integer] : Boolean
             read GetPlotExists ;

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
    property PlotNum : Integer read FPlotNum write SetPlotNum ;
    property NumPlots : Integer read FNumPlots ;
    property NumLines : Integer read FNumLines ;
    property MaxPointsPerLine : Integer
             read FMaxPointsPerLine write FMaxPointsPerLine ;
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
  RegisterComponents('Samples', [TXMultiYPlot]);
  end;


constructor TXMultiYPlot.Create(AOwner : TComponent) ;
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

     FPlotNum := 0 ;
     FNumPlots := 0 ;
     FNumLines := 0 ;

     { Initialise all lines on plot to none }
     for i := 0 to MaxLines do begin
         FLines[i].PlotNum := 0 ;
         FLines[i].NumPoints := 0 ;
         FLines[i].XYBuf := Nil ;
         FLines[i].MarkerStyle := msOpenSquare ;
         FLines[i].LineStyle := psSolid ;
         FLines[i].LineType := ltNone ;
         FLines[i].Color := clBlack ;
         end ;

     { Initial X axis settings }
     FXAxis.Lo := 0.0 ;
     FXAxis.Hi := 1.0 ;
     FXAxis.Tick := 0.2 ;
     FXAxis.Law := axLinear ;
     FXAxis.Lab := 'X Axis' ;
     FXAxis.AutoRange := False ;

     { Initial Y axes settings }
     for i := 0 to High(FYAxis) do begin
        FYAxis[i].InUse := False ;
        FYAxis[i].PlotNum := i ;
        FYAxis[i].Lo := 0.0 ;
        FYAxis[i].Hi := 1.0 ;
        FYAxis[i].Tick := 0.2 ;
        FYAxis[i].Law := axLinear ;
        FYAxis[i].Lab := 'Y Axis' ;
        FYAxis[i].AutoRange := True ;
        end ;

     FYAxisLabelAtTop := False ;

     FScreenFontName := 'Arial' ;
     FScreenFontSize := 10 ;
     FOutputToScreen := False ;

     { Printer margins (mm), font name and size }
     FPrinterFontName := 'Arial' ;
     FPrinterFontSize := 10 ;
     FPrinterLeftMargin := (Printer.PageWidth*25)
                           div GetDeviceCaps( printer.handle, HORZSIZE ) ;
     FPrinterRightMargin := FPrinterLeftMargin ;
     FPrinterTopMargin := (Printer.PageHeight*25)
                           div GetDeviceCaps( printer.handle, VERTSIZE ) ;
     FPrinterBottomMargin := FPrinterTopMargin ;
     FPrinterDisableColor := False ;
     FPrinterLineWidth := 1 ;
     FPrinterMarkerSize := 5 ;

     FMetafileWidth := 500 ;
     FMetafileHeight := 400 ;

     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     FVertCursorActive := False ;
     FVertCursorSelected := -1 ;
     FOnCursorChange := Nil ;
     FLinesAvailable := False ;

     // Create marker text list
     FMarkerText := TStringList.Create ;

     end ;


destructor TXMultiYPlot.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
var
   i : Integer ;
begin
     { Destroy internal objects created by TScopeDisplay.Create }

     { Destroy internal objects created by .Create }
     Bitmap.Free ;

     FTitle.Free ;
    { FLinePen.Free ;}
     { Dispose of any x,y data buffers that have been allocated }
     for i := 0 to High(FLines) do
         if FLines[i].XYBuf <> Nil then FreeMem( FLines[i].XYBuf ) ;

     FMarkerText.Free ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


function TXMultiYPlot.CreatePlot : Integer ;
{ -----------------------------
  Create a new Y Axis sub-plot
  -----------------------------}
var
     NewPlotNum,i : Integer ;
begin

     NewPlotNum := 0 ;
     while (FYAxis[NewPlotNum].InUse = True)
           and (NewPlotNum < High(FYAxis)) do Inc(NewPlotNum) ;

     // Make it the current plot select for updating
     FPlotNum := NewPlotNum ;
     FYAxis[NewPlotNum].InUse := True ;

     // Number of plots in display
     FNumPlots := 0 ;
     for i := 0 to High(FYAxis) do if FYAxis[i].InUse = True then Inc(FNumPlots) ;

     // Return index number of new plot
     Result := NewPlotNum ;

     end ;


procedure TXMultiYPlot.ClearAllPlots ;
// ----------------------------
// Clear all plots from display
// ----------------------------
var
     i : Integer ;
begin
     // Clear plots
     for i := 0 to High(FYAxis) do FYAxis[i].InUse := False ;
     FNumPlots := 0 ;

     // Clear all lines since no plots to plot them on
     ClearAllLines ;

     // Request a display update
     Invalidate ;

     end ;


procedure TXMultiYPlot.ClearPlot( PlotNum : Integer ) ;
// -------------------
// Clear selected plot
// -------------------
begin
    if (PlotNum >= 0) and (PlotNum <= High(FYAxis)) then begin
        FYAxis[PlotNum].InUse := False ;
        ClearLinesInPlot(PlotNum) ;
        Invalidate ;
        end ;

    end ;


function TXMultiYPlot.CreateLine(
         Color : TColor ;
         MarkerStyle : TMarkerStyle ;
         LineStyle : TPenStyle
         ) : Integer ;
{ -----------------------------
  Create a new line on the plot
  -----------------------------}
var
    LineIndex : Integer ;
begin

     // Find unused line
     LineIndex := 0 ;
     while (FLines[LineIndex].XYBuf <> Nil)
           and (LineIndex < High(FLines)) do Inc(LineIndex) ;

     if FLines[LineIndex].XYBuf = Nil then begin
        { Allocate memory for x,y data points }
        GetMem(FLines[LineIndex].XYBuf, (FMaxPointsPerLine+10)*SizeOf(TXY) ) ;
        FLines[LineIndex].NumPoints := 0 ;
        FLines[LineIndex].PlotNum := FPlotNum ;
        FLines[LineIndex].LineStyle := LineStyle ;
        FLines[LineIndex].MarkerStyle := MarkerStyle ;
        FLines[LineIndex].LineType := ltLine ;
        FLines[LineIndex].Color := Color ;
        Result := LineIndex ;
        // Increment no. of lines on plot
        Inc(FNumLines) ;
        end
     else Result := -1 ;
     end ;


procedure TXMultiYPlot.ClearAllLines ;
{ ----------------
  Clear all lines
  ---------------- }
var
   i : Integer ;
begin
     for i := 0 to High(FLines) do
         if FLines[i].XYBuf <> Nil then begin
            FreeMem(FLines[i].XYBuf) ;
            FLines[i].XYBuf := Nil ;
            FLines[i].NumPoints := 0 ;
            end ;
     FNumLines := 0 ;
     end ;


procedure TXMultiYPlot.ClearLinesInPlot(
          PlotNum : Integer ) ;
{ ---------------
  Clear lines in selected plot
  ---------------- }
var
   i : Integer ;
begin
     for i := 0 to High(FLines) do
         if (FLines[i].XYBuf <> Nil) and
            (FLines[i].PlotNum = PlotNum) then begin
            FreeMem(FLines[i].XYBuf) ;
            FLines[i].XYBuf := Nil ;
            FLines[i].NumPoints := 0 ;
            end ;
     FNumLines := 0 ;
     end ;

procedure TXMultiYPlot.AddPoint(
          LineIndex : Integer ;    { Line to add point to }
          x : single ;             { x coord (axis units) }
          y : single               { y coord (axis units) }
          ) ;
{ ------------------------------
  Add a new point to end of line
  ------------------------------}
var
   pXY : pChar ;
begin
     if FLines[LineIndex].XYBuf <> Nil then begin
        pXY := FLines[LineIndex].XYBuf
               + FLines[LineIndex].NumPoints*SizeOf(TXY)  ;
        TXYPointer(pXY)^.x := x ;
        TXYPointer(pXY)^.y := y ;
        if FLines[LineIndex].NumPoints < FMaxPointsPerLine then
           Inc(FLines[LineIndex].NumPoints) ;
        end ;
     Invalidate ;
     end ;


function TXMultiYPlot.CreateHistogram : Integer ;
{ ----------------------------------
  Create a new histogram on the plot
  ----------------------------------}
var
     LineIndex : Integer ;
begin
     // Find unused line
     LineIndex := 0 ;
     while (FLines[LineIndex].XYBuf <> Nil)
           and (LineIndex < High(FLines)) do Inc(LineIndex) ;

     if FLines[LineIndex].XYBuf = Nil then begin
        { Allocate memory for data points }
        GetMem(FLines[LineIndex].XYBuf, FMaxPointsPerLine*SizeOf(THist) ) ;
        FLines[LineIndex].NumPoints := 0 ;
        FLines[LineIndex].PlotNum := FPlotNum ;
        FLines[LineIndex].LineType := ltHistogram ;
        Result := LineIndex ;
        end
     else Result := -1 ;
     end ;


procedure TXMultiYPlot.AddBin(
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
   pXY : pChar ;
begin
     if FLines[LineIndex].XYBuf <> Nil then begin
        pXY := FLines[LineIndex].XYBuf
               + FLines[LineIndex].NumPoints*SizeOf(THist)  ;
        THistPointer(pXY)^.Lo := Lo ;
        THistPointer(pXY)^.Mid := Mid ;
        THistPointer(pXY)^.Hi := Hi ;
        THistPointer(pXY)^.y := y ;
        if FLines[LineIndex].NumPoints < FMaxPointsPerLine then
           Inc(FLines[LineIndex].NumPoints) ;
        end ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetNumPointsInLine(
         LineIndex : Integer
         ) : Integer ;
{ -------------------------------------------------
  Returns the number of points in the selected line
  ------------------------------------------------- }
begin
     Result := FLines[LineIndex].NumPoints ;
     end ;


procedure TXMultiYPlot.Paint ;
{ ---------------------------
  Draw plot on control canvas
  ---------------------------}
var
   i,L : Integer ;
begin

     Bitmap.Canvas.Font.Name := FScreenFontName ;
     Bitmap.Canvas.Font.Size := FScreenFontSize ;

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

        // Draw text annotations at bottom of plot
        DrawAnnotations( Bitmap.Canvas ) ;

        // Copy from internal bitmap to control
        Canvas.CopyRect( Canvas.ClipRect,
                         Bitmap.Canvas,
                         Canvas.ClipRect) ;

        { Vertical Cursors }
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then
            DrawVerticalCursor(i) ;

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


procedure TXMultiYPlot.ClearVerticalCursors ;
{ -----------------------------
  Remove all vertical cursors
  -----------------------------}
var
   i : Integer ;
begin
     for i := 0 to High(VertCursors) do VertCursors[i].InUse := False ;
     end ;


function TXMultiYPlot.AddVerticalCursor(
         Color : TColor ;
         Text : String
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
       Result := iCursor ;
       end
    else begin
         { Return -1 if no cursors available }
         Result := -1 ;
         end ;
    end ;


procedure TXMultiYPlot.DrawVerticalCursor(
          iCurs : Integer
          ) ;
{ -----------------------
  Draw vertical cursor
 ------------------------}
var
   xPix : Integer ;
   iLine,iPlot,L,idx : Integer ;
   SavedPen : TPenRecall ;
   SavedFont : TFontRecall ;
   s : String ;
   x,y : Single ;
begin

     // Save pen & font
     SavedPen := TPenRecall.Create( Canvas.Pen ) ;
     SavedFont := TFontRecall.Create( Canvas.Font ) ;

     Canvas.Pen.color := VertCursors[iCurs].Color ;
     Canvas.Font.Color := VertCursors[iCurs].Color ;

     VertCursors[iCurs].Position := FloatLimitTo( VertCursors[iCurs].Position,
                                                  FXAxis.Lo, FXAxis.Hi ) ;
     xPix := XToCanvasCoord( VertCursors[iCurs].Position ) ;

     Canvas.polyline( [Point(xPix,FTop),Point(xPix,FBottom)]);

     // Plot cursor label

     for iPlot := 0 to FNumPlots-1 do begin
         // Find first line on plot
         iLine := -1 ;
         for L := 0 to FNumLines-1 do if FLines[L].PlotNum = iPlot then begin
            iLine := L ;
            Break ;
            end ;

         if iLine >= 0 then begin
            if ANSIContainsText(VertCursors[iCurs].Text,'?r') then begin
               // Display signal value at cursor
               idx := FindNearestIndex(iLine,iCurs) ;
               GetPoint(iLine,idx,x,y) ;
               if iPlot = 0 then begin
                  if ANSIContainsText(VertCursors[iCurs].Text,'?ri') then begin
                     s := format('i=%d, t=%.5g, %.5g',[idx,x,y]) ;
                     end
                  else s := format('t=%.5g, %.5g',[x,y]) ;
                  end
               else s := format('%.5g',[y]) ;
               end
            else s := VertCursors[iCurs].Text ;
            Canvas.TextOut( xPix - Canvas.TextWidth(s) div 2,
                            FYAxis[iPlot].Bottom + 1,
                            s ) ;
            end ;

        end ;

    // Restore pen
    SavedPen.Free ;
    SavedFont.Free ;

    end ;



function TXMultiYPlot.FindNearestIndex(
         LineIndex : Integer ;
         iCursor : Integer
         ) : Integer ;
{ -------------------------------------------------------
  Find the nearest point/bin index to the cursor position
  -------------------------------------------------------}
var
   Nearest,i : Integer ;
   Diff,MinDiff,X : single ;
   pXY : pChar ;
begin
     X := VertCursors[iCursor].Position ;
     MinDiff := MaxSingle ;
     Nearest := 0 ;

     if FLines[LineIndex].LineType = ltHistogram then begin
        { Find nearest histogram bin }
        for i := 0 to FLines[LineIndex].NumPoints-1 do begin
            pXY := FLines[LineIndex].XYBuf + SizeOf(THist)*i  ;
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
            pXY := FLines[LineIndex].XYBuf + SizeOf(TXY)*i ;
            Diff := Abs(X - TXYPointer(pXY)^.x) ;
            if  Diff < MinDiff then begin
               Nearest := i ;
               MinDiff := Diff ;
               end ;
            end ;
        end ;
     Result := Nearest ;
     end ;


procedure TXMultiYPlot.GetPoint(
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
        (FLines[LineIndex].LineType = ltLine) and
        (Flines[LineIndex].NumPoints > 0) then begin
        BufIndex := IntLimitTo( BufIndex, 0, Flines[LineIndex].NumPoints-1) ;
        pXY := FLines[LineIndex].XYBuf + SizeOf(TXY)*BufIndex  ;
        x := TXYPointer(pXY)^.x ;
        y := TXYPointer(pXY)^.y ;
        end
     else begin
        x := 0.0 ;
        y := 0.0 ;
        end ;
     end ;

procedure TXMultiYPlot.GetBin(
          LineIndex : Integer ;         { Line on plot [In] }
          BufIndex : Integer ;          { Index within line data buffer [In] }
          var Lo,Mid,Hi,y : single ) ;  { Returned Lo,Mid,Hi,y bin data }
{ ------------------------------------------------------
  Get the data values for a selected histogram bin
  ------------------------------------------------------ }
var
   pXY : pChar ;
begin
     LineIndex := IntLimitTo( LineIndex, 0, High(FLines) ) ;
     if (FLines[LineIndex].XYBuf <> Nil) and
        (FLines[LineIndex].LineType = ltHistogram) then begin
        BufIndex := IntLimitTo( BufIndex, 0, Flines[LineIndex].NumPoints-1 ) ;
        pXY := FLines[LineIndex].XYBuf + SizeOf(THist)*BufIndex  ;
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

procedure TXMultiYPlot.MouseDown(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;

begin
     Inherited MouseDown( Button, Shift, X, Y ) ;
     if (FVertCursorSelected > -1) then FVertCursorActive := True ;
     end ;


procedure TXMultiYPlot.MouseUp(
          Button: TMouseButton;
          Shift: TShiftState;
          X, Y: Integer
          ) ;
begin
     Inherited MouseUp( Button, Shift, X, Y ) ;
     FVertCursorActive := false ;
     end ;


procedure TXMultiYPlot.MouseMove(
          Shift: TShiftState;
          X, Y: Integer) ;
{ --------------------------------------------------------
  Select/deselect cursors as mouse is moved over display
  -------------------------------------------------------}
const
     Margin = 4 ;
var
   XPosition,i : Integer ;
begin
     Inherited MouseMove( Shift, X, Y ) ;

     if FVertCursorActive and (FVertCursorSelected > -1) then begin

        { Move the currently activated cursor to a new position }
        VertCursors[FVertCursorSelected].Position := CanvasToXCoord( X ) ;

        // Copy background graph from internal bitmap to control
        Canvas.CopyRect( Canvas.ClipRect,
                         Bitmap.Canvas,
                         Canvas.ClipRect) ;

        DrawVerticalCursor( FVertCursorSelected ) ;

        { Notify a change in cursors }
        if Assigned(OnCursorChange) then OnCursorChange(Self) ;

        end
     else begin
        { Find the active vertical cursor (if any) }
        FVertCursorSelected := -1 ;
        for i := 0 to High(VertCursors) do if VertCursors[i].InUse then begin
            XPosition := XToCanvasCoord( VertCursors[i].Position ) ;
            if Abs(X - XPosition) <= Margin then FVertCursorSelected := i ;
            end ;
        end ;

        { Set type of cursor icon }
     if FVertCursorSelected > -1 then Cursor := crSizeWE
                                 else Cursor := crDefault ;
     end ;


procedure TXMultiYPlot.CopyImageToClipboard ;
{ ---------------------------------------------
  Copy plot to clipboard as a Windows metafile
  ---------------------------------------------}
var
   TMF : TMetafile ;
   TMFC : TMetafileCanvas ;
   KeepLineWidth : Integer ;
begin

     Cursor := crHourglass ;

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
            // Draw text annotations at bottom of plot
            DrawAnnotations( TMFC ) ;

        finally
            { Free metafile canvas. Note this copies plot into metafile object }
            TMFC.Free ;
            end ;
        { Copy metafile to clipboard }
        Clipboard.Assign(TMF) ;

     finally
        Cursor := crDefault ;
        FLineWidth := KeepLineWidth ;
        end ;

     end ;


procedure TXMultiYPlot.CopyDataToClipboard ;
{ -------------------------------------------------------
  Copy plot data points to clipboard as table of Tab text
  ------------------------------------------------------- }
var
   L,i,NumPointsMax,BufSize,NumLines : Integer ;
   x,y,BinLo,BinMid,BinHi,Sum : Single ;
   BinY : Array[0..MaxLines] of Single ;
   YScale : Array[0..MaxLines] of Single ;
   pXY,CopyBuf : pChar ;
   First,Histogram : Boolean ;
begin

     Screen.Cursor := crHourglass ;

     // Open clipboard preventing others acceessing it
     Clipboard.Open ;

     try

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
        CopyBuf[0] := Char(0) ;

        { Initialisations for cumulative and/or percentage histograms }
        for L := 0 to High(FLines) do if FLines[L].XYBuf <> Nil then begin
            // Initialise cumulative Y value
            BinY[L] := 0.0 ;
            // Calculate percentage scale factor }
            if FHistogramPercentage then begin
               Sum := 0.0 ;
               for i := 0 to FLines[L].NumPoints-1 do begin
                   pXY := FLines[L].XYBuf + (i*SizeOf(THist))  ;
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
                      pXY := FLines[L].XYBuf + (i*SizeOf(TXY))  ;
                      x := TXYPointer(pXY)^.x ;
                      y := TXYPointer(pXY)^.y ;
                      StrCat( CopyBuf, PChar(format('%.5g'#9'%.5g',[x,y]))) ;
                      end
                   else StrCat( CopyBuf, #9 ) ;
                   end
                else begin
                   { Add a histogram bin }
                   if (i < FLines[L].NumPoints) then begin
                      pXY := FLines[L].XYBuf + (i*SizeOf(THist))  ;
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


procedure TXMultiYPlot.DrawAxes(
          Canv : TCanvas  {canvas on which the axes are to be drawn.}
          ) ;
{ ---------------
  Draw plot axes
  --------------- }
var
   i,xPix,yPix : Integer ;
   yLabelxPos,yLabelyPos,yPos,PlotHeight,NumPlots,MaxWidth : Integer ;
   CharWidth, CharHeight : Integer ;
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

        // Dimensions of a single character on canvas
        CharWidth := Canv.TextWidth('X') ;
        CharHeight := Canv.TextHeight('X') ;

        { Find appropriate axis ranges if required }
        if FXAxis.AutoRange then DefineAxis( FXAxis, 'X' ) ;
        { Ensure that axes ranges are valid }
        CheckAxis( FXAxis ) ;

        { Create X axis tick list }
        CreateTickList( XTickList, Canv, FXAxis ) ;
        FRight := FRight - XTickList.MaxWidth ;

        if not FYAxisLabelAtTop then begin
           YLabelXPos := FLeft ;
           FLeft := FLeft + CharHeight ;
           end ;

        { Shift left margin to leave space for Y axis tick values }
        MaxWidth := 0 ;
        for i := 0 to High(FYAxis) do if  FYAxis[i].InUse then begin
            CreateTickList( YTickList, Canv, FYAxis[i] ) ;
            if YTickList.MaxWidth > MaxWidth then
               MaxWidth := YTickList.MaxWidth ;
            end ;
        FLeft := FLeft + MaxWidth + CharWidth*2 ;

        { Shift bottom margin to leave space for X axis label }
        FBottom := FBottom - 2*CharHeight ;

        // Draw X axis label
        xPix := ( FLeft + FRight - Canv.TextWidth(FXAxis.Lab) ) div 2 ;
        Canv.TextOut( xPix, FBottom, FXAxis.Lab ) ;

        { Shift bottom margin to leave space for X axis tick values }
        FBottom := FBottom - Canv.TextHeight(FXAxis.Lab) - XTickList.MaxHeight  ;

        // Determine number of separate plots
        NumPlots := 0 ;
        for i := 0 to High(FYAxis) do
            if FYAxis[i].InUse then Inc(NumPlots) ;

        // Set vertical placement of each plot

        PlotHeight := (FBottom - FTop) div NumPlots ;
        YPos := FBottom ;
        for i := 0 to High(FYAxis) do if FYAxis[i].InUse then begin

            FYAxis[i].Bottom := YPos ;
            FYAxis[i].Top := YPos - PlotHeight + CharHeight ;
            if FYAxisLabelAtTop then
               FYAxis[i].Top := FYAxis[i].Top + CharHeight ;
            YPos := YPos - PlotHeight ;
            Inc(NumPlots) ;
            end ;

        { Set thickness of line to be used to draw axes }
        Canv.Pen.Width := FLineWidth ;

        { Draw X axis }
        If FyAxis[0].Law = axLog Then Temp := FBottom
        Else Temp := FloatLimitTo( 0.0, FBottom, FTop ) ;

        FXAxis.Position := FBottom {YToCanvasCoord( 0, Temp )} ;
        Canv.polyline( [ Point( FLeft, FXAxis.Position ),
                         Point( FRight,FXAxis.Position ) ] ) ;

        { Create X axis tick list }
        CreateTickList( XTickList, Canv, FXAxis ) ;

        { Draw calibration ticks on X and Y Axes }
        DrawTicks( XTickList, Canv, FXAxis, FXAxis.Position, 'X') ;

        // Draw Y axes
        for i := 0 to High(FYAxis) do if FYAxis[i].InUse then begin

            if FYAxis[i].AutoRange then DefineAxis( FYAxis[i], 'Y' ) ;

            CheckAxis( FYAxis[i] ) ;

           { Draw Y Axis label  }
           if FYAxisLabelAtTop then YLabelYPos := FYAxis[i].Top ;

           { Draw Y axis }
           If FxAxis.Law <> axLinear Then Temp := FXAxis.Lo
           else Temp := FloatLimitTo( 0.0, FXAxis.Lo, FXAxis.Hi ) ;
           FYAxis[i].Position := XToCanvasCoord( Temp ) ;
           Canv.polyline( [point(FYAxis[i].Position, FYAxis[i].Top),
                           point(FYAxis[i].Position, FYAxis[i].Bottom)]) ;

           // Draw Y axes ticks
           CreateTickList( YTickList, Canv, FYAxis[i] ) ;
           DrawTicks( YTickList, Canv, FYAxis[i], FYAxis[i].Position, 'Y') ;

           { Plot Y axis label }
           if FyAxisLabelAtTop then begin
              { Plot label at top of Y axis }
              Canv.TextOut( FYAxis[i].Position, YLabelYPos, FYAxis[i].Lab ) ;
              end
           else begin
              { Plot label along Y axis, rotated 90 degrees }
              yPix := ((FYAxis[i].Bottom - FYAxis[i].Top) div 2) + FYAxis[i].Top
                      + Canv.TextWidth( FYAxis[i].Lab ) div 2 ;
              TextOutRotated( Canv, YLabelXPos, yPix, FYAxis[i].Lab, 90 ) ;
              end ;

           end ;
     finally

        XTickList.Mantissa.Free ;
        XTickList.Exponent.Free ;
        YTickList.Mantissa.Free ;
        YTickList.Exponent.Free ;

        end ;

     End ;


procedure TXMultiYPlot.DefineAxis(
          var Axis : TAxis ;         { Axis description record (OUT) }
          AxisType : char            { Type of axis 'X' or 'Y' (IN) }
          ) ;
{ -------------------------------------------------------
  Find a suitable min/max range and ticks for a plot axis
  -------------------------------------------------------}
var
   R,Max,Min,MinPositive,Sign,Range,Start,Step,YSum,YScale : Single ;
   L,i,NumPoints : Integer ;
   pXY : pChar ;
begin

     { Find max./min. range of data }
     Min := MaxSingle ;
     Max := -MaxSingle ;
     MinPositive := MaxSingle ;
     NumPoints := 0 ;
     for L := 0 to High(FLines) do if
         (FLines[L].XYBuf <> Nil) and
         ((FLines[L].PlotNum = Axis.PlotNum) or (AxisType = 'X'))then begin
         // NOTE. X axis limits obtained from ALL plots
         // Y Axis limits only from lines associated with specific Axis

         { Compute percentage scale factor, if this is a histogram with a % Y axis }
         if (FLines[L].LineType = ltHistogram) and FHistogramPercentage then begin
            YScale := 0.0 ;
            For i := 0 To FLines[L].NumPoints-1 do begin
                pXY := FLines[L].XYBuf + i*SizeOf(THist)  ;
                YScale := YScale + THistPointer(pXY)^.y ;
                end ;
            YScale := 100.0 / YScale ;
            end
         else YScale := 1.0 ;

         YSum := 0.0 ;
         For i := 0 To FLines[L].NumPoints-1 do begin
             if FLines[L].LineType = ltHistogram then begin
                 { Histogram data }
                 pXY := FLines[L].XYBuf + i*SizeOf(THist)  ;
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
                 pXY := FLines[L].XYBuf + i*SizeOf(TXY)  ;
                 If AxisType = 'X' Then R := TXYPointer(pXY)^.x
                                   else R := TXYPointer(pXY)^.y ;
                 end ;

             If R < Min Then Min := R ;
             If R > Max Then Max := R ;
             If (R > 0) And (R <= MinPositive) Then MinPositive := R ;
             Inc(NUmPoints) ;

             end ;

         end ;

    if NumPoints = 0 then begin
       Min := 0.0 ;
       Max := 1.0 ;
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

           If Abs(Axis.Hi) <= 1E-20 Then
              { If Upper limit is (or is close to zero) set to zero }
              Axis.Hi := 0.
           Else begin
              { Otherwise ... }
              If Axis.Hi < 0. Then begin
                 { Make positive for processing }
                 Axis.Hi := -Axis.Hi ;
                 Sign := -1. ;
                 end
              else Sign := 1. ;

              Start := AntiLog10(Int(log10(axis.Hi))) ;
              if Start > Axis.Hi then Start := Start * 0.1 ;
              Step := 1. ;
              While (Step*Start) < Axis.Hi do Step := Step + 1. ;
              Axis.Hi := Start*Step ;
              end ;

           { Set lower limit of axis }

           If Abs(Axis.Lo) <= 1E-20 Then
              { If lower limit is (or is close to zero) set to zero }
              Axis.Lo := 0.
           else begin
              { Otherwise ... }
              If Axis.Lo < 0. Then begin
                 { Make positive for processing }
                 Axis.Lo := -Axis.Lo ;
                Sign := -1. ;
                end
                else Sign := 1. ;

              Start := AntiLog10(Int(log10(axis.Lo))) ;
              if Start > Axis.Lo then Start := Start * 0.1 ;
              Step := 1. ;
              While (Step*Start) <= Axis.Lo do Step := Step + 1. ;
              if Sign > 0. then Step := Step - 1. ;
              Axis.Lo := Start*Step*Sign ;
              end ;

           { Use zero as one of the limits, if the range of data points
             is not to narrow. }

           If (Axis.Hi > 0. ) And (Axis.Lo > 0. ) And
              ( Abs( (Axis.Hi - Axis.Lo)/Axis.Hi ) > 0.1 ) Then Axis.Lo := 0.
           Else If (Axis.Hi < 0. ) And (Axis.Lo < 0. ) And
              ( Abs( (Axis.Lo - Axis.Hi)/Axis.Lo ) > 0.1 ) Then Axis.Hi := 0. ;


           { Choose a tick interval ( 1, 2, 2.5, 5 ) }

           Range := Abs(Axis.Hi - Axis.Lo) ;
           Axis.Tick := antilog10( Int(log10( Range/5. )) - 1. ) ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2. ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2.5 ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2. ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2. ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2.5 ;
           end ;

        {* Square root axis *}
        axSquareRoot : begin
           { Set upper limit of axis }
           Start := AntiLog10(Int(log10(axis.Hi))) ;
           if Start > Axis.Hi then Start := Start * 0.1 ;
           Step := 1. ;
           While (Step*Start) < Axis.Hi do Step := Step + 1. ;
           Axis.Hi := Start*Step ;

           { Set lower limit of axis }
           Axis.Lo := MinPositive ;
           Start := AntiLog10(Int(log10(axis.Lo))) ;
           if Start > Axis.Lo then Start := Start * 0.1 ;
           Step := 1. ;
           While (Step*Start) <= Axis.Lo do Step := Step + 1. ;
           Axis.Lo := Start*(Step-1) ;

           { Choose a tick interval ( 1, 2, 2.5, 5 ) }
           Range := Abs(Axis.Hi - Axis.Lo) ;
           Axis.Tick := antilog10( Int(log10( Range/5. )) - 1. ) ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2. ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2.5 ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2. ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2. ;
           if Range/Axis.Tick > 6. then Axis.Tick := Axis.Tick*2.5 ;

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


procedure TXMultiYPlot.DrawMarkers(
          Canv : TCanvas ; { Canvas on which line is to be drawn (OUT) }
          MarkerSize : Integer
          ) ;
{ ----------------------
   Draw markers on plot
  ----------------------}
var
   xPix,yPix,i,L,iPlot : Integer ;
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

            // Get plot to draw line on
            iPlot := FLines[L].PlotNum ;

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
                 msOpenSquare, msOpenCircle, msOpenTriangle : begin
                     Canv.Brush.Style := bsClear ;
                     end ;
                 msSolidSquare, msSolidCircle, msSolidTriangle : begin
                     Canv.brush.style := bsSolid ;
                     end ;
                 end ;

            if FLines[L].MarkerStyle <> msNone then begin
               for i := 0 to FLines[L].NumPoints-1 do begin
                   pXY := FLines[L].XYBuf + (i*SizeOf(TXY))  ;
                   x := TXYPointer(pXY)^.x ;
                   y := TXYPointer(pXY)^.y ;
                   if (FXAxis.Lo <= x) and (x <= FXAxis.Hi) and
                      (FYAxis[iPlot].Lo <= y) and (y <= FYAxis[iPlot].Hi) then begin
                      xPix := XToCanvasCoord( x ) ;
                      yPix := YToCanvasCoord( iPlot, y ) ;
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


procedure TXMultiYPlot.DrawMarkerShape(
          Canv : TCanvas ;
          xPix,yPix : Integer ;
          const LineInfo : TLine ;
          MarkerSize : Integer
          ) ;
var
   HalfSize : Integer ;
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
          end ;
     end ;


procedure TXMultiYPlot.DrawLines(
          Canv : TCanvas  { Canvas on which line is to be drawn (OUT) }
          ) ;
{ -------------------
   Draw lines on plot
  -------------------}
var
   xPix,yPix,i,L,iPlot : Integer ;
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

            // Get plot to draw line on
            iPlot := FLines[L].PlotNum ;

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
                   pXY := FLines[L].XYBuf + (i*SizeOf(TXY))  ;
                   x := TXYPointer(pXY)^.x ;
                   y := TXYPointer(pXY)^.y ;

                   { Check that point is on plot }
                   if (x < FXAxis.Lo ) or (x > FXAxis.Hi) or
                      (y < FYAxis[iPlot].Lo ) or (y > FYAxis[iPlot].Hi)
                      then OutOfRange := True
                   else OutOfRange := False ;

                   { Plot point if within axes range }
                   if not OutOfRange then begin
                      xPix := XToCanvasCoord( x ) ;
                      yPix := YToCanvasCoord( iPlot, y ) ;
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


procedure TXMultiYPlot.DrawHistograms(
          Canv : TCanvas  { Canvas on which line is to be drawn (OUT) }
          ) ;
{ ----------------------------------
   Draw histogram bars lines on plot
  ----------------------------------}
var
   xPixLo,xPixHi,yPix,yPix0, i,L, iPlot : Integer ;
   BinLo,BinHi,BinY,YScale,Sum : single ;
   SavePen : TPen ;
   SaveBrush : TBrush ;
   pXY : pChar ;
   FirstBin, OffYAxis : boolean ;
begin
     { Create objects }
     SavePen := TPen.Create ;
     SaveBrush := TBrush.Create ;

     try
        { Save current pen/brush settings }
        SavePen.Assign(Canv.Pen) ;
        SaveBrush.Assign(Canv.Brush) ;

        for L := 0 to High(FLines) do
            if  (FLines[L].XYBuf <> Nil)
            and (FLines[L].LineType = ltHistogram) then begin

            // Get plot to draw histogram on
            iPlot := FLines[L].PlotNum ;

            { Set bin fill style }
            if (FOutputToScreen = False) and FPrinterDisableColor then
               Canv.Brush.Color := clBlack
            else Canv.Brush.Color := FHistogramFillColor ;

            Canv.Brush.Color := FHistogramFillColor ;
            Canv.Brush.Style := FHistogramFillStyle ;

            { Set line colour }
            Canv.Pen.Color := clBlack ;

            { Set bottom of bar at Y=0.0, unless log axis }
            if FYAxis[iPlot].Law = axLog then
               yPix0 := FBottom
            else yPix0 := YToCanvasCoord( iPlot, 0.0 ) ;

            { If a percentage histogram is required,
              calculate scaling factor to convert to % }
            if FHistogramPercentage then begin
               Sum := 0.0 ;
               for i := 0 to FLines[L].NumPoints-1 do begin
                   pXY := FLines[L].XYBuf + (i*SizeOf(THist))  ;
                   Sum := Sum + THistPointer(pXY)^.y ;
                   end ;
               YScale := 100.0 / Sum ;
               end
            else YScale := 1.0 ;

            FirstBin := True ;
            BinY := 0.0 ;
            for i := 0 to FLines[L].NumPoints-1 do begin

                pXY := FLines[L].XYBuf + (i*SizeOf(THist))  ;
                BinLo := THistPointer(pXY)^.Lo ;
                BinHi := THistPointer(pXY)^.Hi ;

                if FHistogramCumulative then BinY := BinY + THistPointer(pXY)^.y*YScale
                                        else BinY :=THistPointer(pXY)^.y*YScale ;

                if (BinLo >= FXAxis.Lo) and (BinHi <= FXAxis.Hi) then begin

                   { Keep bin Y value to limits of plot, but determine
                     whether it has gone off scale }

                   OffYAxis := False ;
                   if BinY < FYAxis[iPlot].Lo then begin
                      BinY := FYAxis[iPlot].Lo ;
                      OffYAxis := True ;
                      end ;
                   if BinY > FYAxis[iPlot].Hi then begin
                      BinY := FYAxis[iPlot].Hi ;
                      OffYAxis := True ;
                      end ;

                   { Convert to window coordinates }
                   xPixLo := XToCanvasCoord( BinLo ) ;
                   xPixHi := XToCanvasCoord( BinHi ) ;
                   yPix :=   YToCanvasCoord( iPlot, BinY ) ;

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
     finally
            { Dispose of objects }
            SavePen.Free ;
            SaveBrush.Free ;
            end ;
     end ;


procedure TXMultiYPlot.Print ;
{ -----------------------
  Print hard copy of plot
  -----------------------}
var
   i,KeepLineWidth : Integer ;
begin

     Printer.BeginDoc ;
     Cursor := crHourglass ;

     try
        Printer.Canvas.Pen.Color := clBlack ;
        Printer.Canvas.Font.Name := FPrinterFontName ;
        Printer.Canvas.font.size := FPrinterFontSize ;
        KeepLineWidth := FLineWidth ;
        FLineWidth := PrinterPointsToPixels(FPrinterLineWidth) ;

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
        // Draw text annotations at bottom of plot
        DrawAnnotations( Printer.Canvas ) ;

     finally

        { Close down printer }
        FLineWidth := KeepLineWidth ;
        Printer.EndDoc ;
        Cursor := crDefault ;
        end ;

     end ;


procedure TXMultiYPlot.CodedTextOut(
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


procedure TXMultiYPlot.ClearPrinterTitle ;
{ -------------------------
  Clear printer title lines
  -------------------------}
begin
     FTitle.Clear ;
     end ;


procedure TXMultiYPlot.AddPrinterTitleLine(
          Line : string
          );
{ ---------------------------
  Add a line to printer title
  ---------------------------}
begin
     FTitle.Add( Line ) ;
     end ;


function TXMultiYPlot.XToCanvasCoord(
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
procedure TXMultiYPlot.CheckAxis(
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
                If Axis.Lo1 <= 0. Then Axis.Lo1 := Axis.Hi1 * 0.01 ;
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


function TXMultiYPlot.CanvasToXCoord(
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


function TXMultiYPlot.YToCanvasCoord(
         iPlot : Integer ; // Y axis selected for display
         Value : single    // Value of Y data point
         ) : Integer  ;    // Returns pixel coord. in canvas
begin

     { Calculate Axes data-->pixel scaling factors }
     if FYAxis[iPlot].Hi1 <> FYAxis[iPlot].Lo1 then
        FYAxis[iPlot].Scale := Abs(FYAxis[iPlot].Bottom - FYAxis[iPlot].Top) /
                               Abs(FYAxis[iPlot].Hi1 - FYAxis[iPlot].Lo1)
     else FYAxis[iPlot].Scale := 1.0 ;

     case FYAxis[iPlot].Law of
          axLog : Value := log10(Value) ;
          axSquareRoot : Value := sqrt(Value) ;
          end ;

     Result := Round( FYAxis[iPlot].Bottom
                      - (Value - FYAxis[iPlot].Lo1)*FYAxis[iPlot].Scale ) ;

     end ;


function TXMultiYPlot.CanvasToYCoord(
         iPlot : Integer ; // Plot axis selected for display
         yPix : Integer
         ) : single  ;
var
   Value : single ;
begin
     { Calculate Axes data-->pixel scaling factors }
     if FYAxis[iPlot].Hi1 <> FYAxis[iPlot].Lo1 then
        FYAxis[iPlot].Scale := Abs(FYAxis[iPlot].Bottom - FYAxis[iPlot].Top) /
                               Abs(FYAxis[iPlot].Hi1 - FYAxis[iPlot].Lo1)
     else FYAxis[iPlot].Scale := 1.0 ;

     FYAxis[iPlot].Scale := Abs(FBottom - FTop) /
                            Abs(FYAxis[iPlot].Hi1 - FYAxis[iPlot].Lo1) ;
     Value := (FYAxis[iPlot].Bottom - yPix)/FYAxis[iPlot].Scale + FYAxis[iPlot].Lo1 ;

     case FYAxis[iPlot].Law of
          axLog : Value := Antilog10(Value) ;
          axSquareRoot : Value:= Sqr(Value) ;
          end ;

     Result := Value ;
     end ;


procedure TXMultiYPlot.TextOutRotated(
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


procedure TXMultiYPlot.CreateTickList(
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
     TickList.Mantissa.Clear ;
     TickList.Exponent.Clear ;

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
                 xEnd := MaxFlt( [Abs(Axis.Lo),Abs(Axis.Hi)] ) ;
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
              x := Axis.Hi ;
              While x >= Axis.Lo do begin
                    if x >= Axis.Lo then AddTick(TickList,Axis,x,True ) ;
                    x := x - Axis.tick ;
                    end ;
              end ;

          end ;

     { Calculate width of widest tick }
     CalculateTicksWidth( TickList, Canv ) ;
     { Calculate height of highest tick }
     CalculateTicksHeight( TickList, Canv ) ;
     end ;


procedure TXMultiYPlot.CalculateTicksWidth(
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
procedure TXMultiYPlot.CalculateTicksHeight(
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


procedure TXMultiYPlot.DrawTicks(
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

     { Create tick list }
     CreateTickList( TickList, Canv, Axis ) ;

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
                yPix := YToCanvasCoord( Axis.PlotNum, Value[i] ) ;
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


procedure TXMultiYPlot.AddTick(
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


procedure TXMultiYPlot.SortByX(
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
                   pXY := FLines[Line].XYBuf + (Current*SizeOf(TXY))  ;
                   pXYp1 := FLines[Line].XYBuf + ((Current+1)*SizeOf(TXY))  ;
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


procedure TXMultiYPlot.SetPlotNum( Value : Integer ) ;
{ -------------------------------------
  Select plot number for active change
  ------------------------------------ }
begin
     if (Value >=0) and (Value<=High(FYAxis)) then begin
        if FYAxis[Value].InUse then FPlotNum := Value
                               else FPlotNum := 0 ;
        end ;
     end ;


function TXMultiYPlot.GetLinesAvailable : Boolean ;
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


procedure TXMultiYPlot.SetXAxisMin( Value : single ) ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     FXAxis.Lo := Value ;
     Invalidate ;
     end ;

function TXMultiYPlot.GetXAxisMin : single ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     Result := FXAxis.Lo ;
     end ;

     
procedure TXMultiYPlot.SetXAxisMax( Value : single ) ;
{ ---------------------------
  Set Maximum of X axis range
  ---------------------------}
begin
     FXAxis.Hi := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetXAxisMax : single ;
{ ---------------------------
  Set Maximum of X axis range
  ---------------------------}
begin
     Result := FXAxis.Hi ;
     end ;

procedure TXMultiYPlot.SetXAxisTick( Value : single ) ;
{ --------------------------------
  Set tick spacing of X axis range
  --------------------------------}
begin
     FXAxis.Tick := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetXAxisTick : single ;
{ --------------------------------
  Set tick spacing of X axis range
  --------------------------------}
begin
     Result := FXAxis.Tick ;
     end ;


procedure TXMultiYPlot.SetXAxisLaw( Value : TAxisLaw ) ;
{ ----------------------------------------------
  Set linear/log/square root law of X axis range
  ----------------------------------------------}
begin
     FXAxis.Law := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetXAxisLaw : TAxisLaw ;
{ ----------------------------------------------
  Get linear/log/square root law of X axis range
  ----------------------------------------------}
begin
     Result := FXAxis.Law ;
     end ;


procedure TXMultiYPlot.SetXAxisAutoRange( Value : Boolean ) ;
{ -----------------------------------------
  Set automatic range setting flag of X axis
  -----------------------------------------}
begin
     FXAxis.AutoRange := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetXAxisAutoRange : Boolean ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FXAxis.AutoRange ;
     end ;


procedure TXMultiYPlot.SetXAxisLabel( Value : string ) ;
{ ----------------
  Set X axis label
  ----------------}
begin
     FXAxis.Lab := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetXAxisLabel : string ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FXAxis.Lab ;
     end ;


procedure TXMultiYPlot.SetYAxisMin( Value : single ) ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     FYAxis[FPlotNum].Lo := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetYAxisMin : single ;
{ ---------------------------
  Set minimum of X axis range
  ---------------------------}
begin
     Result := FYAxis[FPlotNum].Lo ;
     end ;

     
procedure TXMultiYPlot.SetYAxisMax( Value : single ) ;
{ ---------------------------
  Set Maximum of Y axis range
  ---------------------------}
begin
     FYAxis[FPlotNum].Hi := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetYAxisMax : single ;
{ ---------------------------
  Set Maximum of Y axis range
  ---------------------------}
begin
     Result := FYAxis[FPlotNum].Hi ;
     end ;

procedure TXMultiYPlot.SetYAxisTick( Value : single ) ;
{ --------------------------------
  Set tick spacing of Y axis range
  --------------------------------}
begin
     FYAxis[FPlotNum].Tick := Value ;
     Invalidate ;
     end ;

function TXMultiYPlot.GetYAxisTick : single ;
{ --------------------------------
  Set tick spacing of Y axis range
  --------------------------------}
begin
     Result := FYAxis[FPlotNum].Tick ;
     end ;

procedure TXMultiYPlot.SetYAxisLaw( Value : TAxisLaw ) ;
{ ----------------------------------------------
  Set linear/log/square root law of Y axis range
  ----------------------------------------------}
begin
     FYAxis[FPlotNum].Law := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetYAxisLaw : TAxisLaw ;
{ ----------------------------------------------
  Get linear/log/square root law of Y axis range
  ----------------------------------------------}
begin
     Result := FYAxis[FPlotNum].Law ;
     end ;


procedure TXMultiYPlot.SetYAxisAutoRange( Value : Boolean ) ;
{ -----------------------------------------
  Set automatic range setting flag of X axis
  -----------------------------------------}
begin
     FYAxis[FPlotNum].AutoRange := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetYAxisAutoRange : Boolean ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FYAxis[FPlotNum].AutoRange ;
     end ;


procedure TXMultiYPlot.SetYAxisLabel( Value : string ) ;
{ ----------------
  Set X axis label
  ----------------}
begin
     FYAxis[FPlotNum].Lab := Value ;
     Invalidate ;
     end ;


function TXMultiYPlot.GetYAxisLabel : string ;
{ -----------------------------------------
  Get automatic range setting flag of X axis
  -----------------------------------------}
begin
     Result := FYAxis[FPlotNum].Lab ;
     end ;

procedure TXMultiYPlot.SetScreenFontName(
          Value : string
          ) ;
{ -----------------------
  Set screen font name
  ----------------------- }
begin
     FScreenFontName := Value ;
     end ;


function TXMultiYPlot.GetScreenFontName : string ;
{ -----------------------
  Get screen font name
  ----------------------- }
begin
     Result := FScreenFontName ;
     end ;


procedure TXMultiYPlot.SetPrinterFontName(
          Value : string
          ) ;
{ -----------------------
  Set printer font name
  ----------------------- }
begin
     FPrinterFontName := Value ;
     end ;


function TXMultiYPlot.GetPrinterFontName : string ;
{ -----------------------
  Get printer font name
  ----------------------- }
begin
     Result := FPrinterFontName ;
     end ;


procedure TXMultiYPlot.SetPrinterLeftMargin(
          Value : Integer                    { Left margin (mm) }
          ) ;
{ -----------------------
  Set printer left margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     FPrinterLeftMargin := (Printer.PageWidth*Value)
                           div GetDeviceCaps( printer.handle, HORZSIZE ) ;
     end ;


function TXMultiYPlot.GetPrinterLeftMargin : integer ;
{ ----------------------------------------
  Get printer left margin (returned in mm)
  ---------------------------------------- }
begin
     Result := (FPrinterLeftMargin*GetDeviceCaps(Printer.Handle,HORZSIZE))
               div Printer.PageWidth ;
     end ;


procedure TXMultiYPlot.SetPrinterRightMargin(
          Value : Integer                    { Right margin (mm) }
          ) ;
{ -----------------------
  Set printer Right margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     FPrinterRightMargin := (Printer.PageWidth*Value)
                           div GetDeviceCaps( printer.handle, HORZSIZE ) ;
     end ;


function TXMultiYPlot.GetPrinterRightMargin : integer ;
{ ----------------------------------------
  Get printer Right margin (returned in mm)
  ---------------------------------------- }
begin
     Result := (FPrinterRightMargin*GetDeviceCaps(Printer.Handle,HORZSIZE))
               div Printer.PageWidth ;
     end ;


procedure TXMultiYPlot.SetPrinterTopMargin(
          Value : Integer                    { Top margin (mm) }
          ) ;
{ -----------------------
  Set printer Top margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     FPrinterTopMargin := (Printer.PageHeight*Value)
                           div GetDeviceCaps( printer.handle, VERTSIZE ) ;
     end ;


function TXMultiYPlot.GetPrinterTopMargin : integer ;
{ ----------------------------------------
  Get printer Top margin (returned in mm)
  ---------------------------------------- }
begin
     Result := (FPrinterTopMargin*GetDeviceCaps(Printer.Handle,VERTSIZE))
               div Printer.PageHeight ;
     end ;


procedure TXMultiYPlot.SetPrinterBottomMargin(
          Value : Integer                    { Bottom margin (mm) }
          ) ;
{ -----------------------
  Set printer Bottom margin
  ----------------------- }
begin
     { Printer pixel height (mm) }
     FPrinterBottomMargin := (Printer.PageHeight*Value)
                           div GetDeviceCaps( printer.handle, VERTSIZE ) ;
     end ;


function TXMultiYPlot.GetPrinterBottomMargin : integer ;
{ ----------------------------------------
  Get printer Bottom margin (returned in mm)
  ---------------------------------------- }
begin
     Result := (FPrinterBottomMargin*GetDeviceCaps(Printer.Handle,VERTSIZE))
               div Printer.PageHeight ;
     end ;


function TXMultiYPlot.GetPrinterTitleCount : Integer ;
{ --------------------------------------------
  Get the number of lines in the printer title
  -------------------------------------------- }
begin
     Result := FTitle.Count ;
     end ;


procedure TXMultiYPlot.SetPrinterTitleLines(
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


function TXMultiYPlot.GetPrinterTitleLines(
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


procedure TXMultiYPlot.SetVertCursor(
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


function TXMultiYPlot.GetVertCursor(
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


procedure TXMultiYPlot.SetLineStyle(
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


function TXMultiYPlot.GetLineStyle(
         Line: Integer            { Line # }
         ) : TPenStyle ;
{ ----------------------
  Get line drawing style
  ----------------------}
begin
     Line := IntLimitTo(Line,0,High(FLines)) ;
     Result := FLines[Line].LineStyle ;
     end ;


procedure TXMultiYPlot.SetMarkerStyle(
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


function TXMultiYPlot.GetMarkerStyle(
        Line: Integer            { Line # }
        ) : TMarkerStyle ;
{ ----------------------
  Get line drawing style
  ----------------------}
begin
     Line := IntLimitTo(Line,0,High(FLines)) ;
     Result := FLines[Line].MarkerStyle ;
     end ;


function TXMultiYPlot.GetNumLinesInPlot(
         PlotNum : Integer
         ) : Integer ;
{ ------------------------------------
  Get no. of lines in plot # <PlotNum>
  ------------------------------------}
var
    NumPlots : Integer ;
    i : Integer ;
begin
     NumPlots := 0 ;
     for i := 0 to High(Flines) do begin
         if (FLines[i].XYBuf <> Nil) and
            (FLines[i].PlotNum = PlotNum) then Inc(NumPlots) ;
         end ;
     Result := NumPlots ;
     end ;


function TXMultiYPlot.GetPlotExists(
         PlotNum : Integer
         ) : Boolean ;
{ ------------------------------------
  Return TRUE if plot # exists
  ------------------------------------}
begin
     if (PlotNum >= 0) and (PlotNum <= High(FYAxis)) then begin
        Result := FYAxis[PlotNum].InUse ;
        end
     else Result := False ;
     end ;



{ ===================================================
  Miscellaneous support functions
  =================================================== }

function TXMultiYPlot.Log10(
         x : Single
         ) : Single ;
{ -----------------------------------
  Return the logarithm (base 10) of x
  -----------------------------------}
begin
     if x > 1E-30 then Log10 := ln(x) / ln(10. )
                  else x := -30.0 ;
     end ;


function TXMultiYPlot.AntiLog10(
         x : single
         )  : Single ;
{ ---------------------------------------
  Return the antilogarithm (base 10) of x
  ---------------------------------------}
begin
     AntiLog10 := exp( x * ln( 10. ) ) ;
     end ;

function TXMultiYPlot.IntLimitTo(
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


function TXMultiYPlot.FloatLimitTo(
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


function TXMultiYPlot.MaxFlt(
         const Buf : array of Single { List of numbers (IN) }
         ) : Single ;                { Returns maximum of Buf }
{ ---------------------------------------------------------
  Return the largest floating point value in the array 'Buf'
  ---------------------------------------------------------}
var
   i : Integer ;
   Max : Single ;
begin
     Max:= -MaxSingle ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;


function TXMultiYPlot.ExtractInt (
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


function TXMultiYPlot.TidyNumber(
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


function TXMultiYPlot.PrinterPointsToPixels(
         PointSize : Integer
         ) : Integer ;
var
   PixelsPerInch : single ;
begin

     { Get height and width of page (in mm) and calculate
       the size of a pixel (in cm) }
     PixelsPerInch := GetDeviceCaps( printer.handle, LOGPIXELSX ) ;
     PrinterPointsToPixels := Trunc( (PointSize*PixelsPerInch) / 72. ) ;
     end ;

procedure TXMultiYPlot.AddAnnotation (
          XValue : Single ;        // Marker display point
          Text : String             // Marker text
                    ) ;
// ------------------------------------
// Add marker text at bottom of display
// ------------------------------------
begin

    FMarkerText.AddObject( Text, TObject(XValue) ) ;
    Invalidate ;
    end ;


procedure TXMultiYPlot.ClearAnnotations ;
// ----------------------
// Clear marker text list
// ----------------------
begin
     FMarkerText.Clear ;
     Invalidate ;
     end ;

procedure TXMultiYPlot.DrawAnnotations(
          Canv : TCanvas ) ;
// ------------------------
// Draw annotations on plot
// ------------------------
var
    i : Integer ;
    xPix,xEndPix,yPix : Integer ;
    x : Single ;
begin

     // Marker text
     xEndPix := Low(xPix) ;
     for i := 0 to FMarkerText.Count-1 do begin
         x := Single(FMarkerText.Objects[i]) ;
         if (x >= FXAxis.Lo) and (x <= FXAxis.Hi ) then begin
            // Coord of start/end of label
            xPix := XToCanvasCoord( x ) ;
            // Ensure labels do not overlap
            if xPix > xEndPix then begin
               yPix := FYAxis[0].Bottom - Canv.TextHeight('X') - 1
               end
            else begin
               yPix := yPix - Canvas.TextHeight('X') ;
               end ;
            // Plot label
            Canv.TextOut( xPix, yPix, FMarkerText.Strings[i] );
            // Keep location end of label
            xEndPix :=  xPix + Canv.TextWidth(FMarkerText.Strings[i])

            end ;
         end ;

     end ;

end.
