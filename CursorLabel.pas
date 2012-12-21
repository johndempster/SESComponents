unit CursorLabel;
{ ----------------------------------------------------------
  Display  cursor label component (c) J. Dempster 2002
  ----------------------------------------------------------
  Multi-line label used to display cursor readout values
  6.6.02
  }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TCursorLabel = class(TGraphicControl)
  private
    { Private declarations }
    FLines : TStringList ;    // Lines of text displayed by label
    FFont : TFont ;           // Typeface used to display text
    FAlignment : TAlignment ; // Alignment of text within label
  protected
    { Protected declarations }
    procedure Paint ; override ;

  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
    procedure Clear ;
    procedure Add( s : string ) ;

  published
    { Published declarations }
    //Property Font : TFont Read FFont Write FFont ;
    property Alignment : TAlignment read FAlignment write FAlignment ;
    property Height default 150 ;
    property Width default 200 ;
    property AutoSize ;
    property Color ;
    property Font ;
    property HelpContext ;
    property Hint ;
    property Left ;
    property Name ;
    property ShowHint ;
    property Top ;
    property Visible ;
    //property NumLines : Integer ; Read FNumLines Write FNumLines ;

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TCursorLabel]);
end;

constructor TCursorLabel.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin

     inherited Create(AOwner) ;

     // Create string list to hold lines of text
     FLines := TStringList.Create ;
     FLines.Add('Cursor') ;

     FAlignment := taCenter ;

     end ;

destructor TCursorLabel.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     FLines.Free ;

     { Call inherited destructor }
     inherited Destroy ;
     end ;


procedure TCursorLabel.Paint ;
// ------------
// Display text
// ------------
var
     i,MaxWidth,y,x,xMid : Integer ;
begin


     // Adjust height of label
     Height := FLines.Count*Canvas.TextHeight('X') + 1 ;
     if Height <= 0 then Height := Canvas.TextHeight('X') + 1 ;

     // Set text background colour
     Canvas.Brush.Color := Color  ;
     Canvas.FillRect( Rect(0,0,Width-1,Height-1) ) ;

     // Adjust width of label to accomodate text
     MaxWidth := 0 ;
     for i := 0 to FLines.Count-1 do
         if MaxWidth < Canvas.TextWidth(FLines.Strings[i]) then
            MaxWidth := Canvas.TextWidth(FLines.Strings[i]) ;
     MaxWidth := MaxWidth + Canvas.TextWidth('XX') ;
     if Width < MaxWidth then Width := MaxWidth ;

     // Display lines of text (centred)
     y := 0 ;
     xMid := Width div 2 ;
     for i := 0 to FLines.Count-1 do begin

         case FAlignment of
              taCenter : Begin
                x := xMid - Canvas.TextWidth(FLines.Strings[i]) div 2 ;
                end ;
              taLeftJustify : Begin
                x := Canvas.TextWidth('X') ;
                end ;
              taRightJustify : Begin
                x := Width - Canvas.TextWidth(FLines.Strings[i]+'X') ;
                end ;
              end ;

         Canvas.TextOut(x,y,FLines.Strings[i]) ;
         y := y + Canvas.TextHeight(FLines.Strings[i]) ;
         end ;

     end ;


procedure TCursorLabel.Clear ;
// -----------------------
// Clear all lines of text
// -----------------------
begin
     FLines.Clear ;

     end ;


procedure TCursorLabel.Add(
          s : string ) ;
// -------------------------
// Add line of text to label
// -------------------------
begin
     FLines.Add(s) ;
     end ;


end.
