unit HTMLLabel;
// ----------------------------------------------------------
//  Multi-line HTML label component (c) J. Dempster 2003
//  ----------------------------------------------------------
// 9.6.03
// 10.7.03 ... <FONT COLOR=#RRGGBB> added
//             LineSpacing property added
// 24.7.03 ... <FONT COLOR=#RRGGBB> now working correctly
//             Left, centre & right alignment now works
//             .LineHeight property added
// 04.05.06 .. No. of lines increased to 1000
// 05.09.06 .. ControlStyle set to opaque to minimise flicker

interface

uses
  SysUtils, Classes, Controls, StrUtils, Graphics, Types ;

type
  THTMLLabel = class(TGraphicControl)
  private
    { Private declarations }
    FCaption : String ;
    FAlignment : TAlignment ;
    FLineSpacing : Single ;
    BMap : TBitmap ;

    procedure WriteCaption( NewCaption : String ) ;
    procedure SetFace( CommandText : String ) ;
    procedure SetColor( CommandText : String ) ;
    function GetLineHeight : Integer ;
  protected
    { Public declarations }
    procedure Paint ; override ;




  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
  published
    { Published declarations }
    property Caption : String Read FCaption Write WriteCaption ;
    property Alignment : TAlignment read FAlignment write FAlignment ;
    Property LineSpacing : Single read FLineSpacing write FLineSpacing ;
    Property LineHeight : Integer read GetLineHeight ;
    property Height ;
    property Width  ;
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

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [THTMLLabel]);
end;

constructor THTMLLabel.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin

     inherited Create(AOwner) ;

     FAlignment := taCenter ;
     FLineSpacing := 1.0 ;
     FCaption := 'Label' ;
     BMap := TBitMap.Create ;

     { Set opaque background to minimise flicker when display updated }
     ControlStyle := ControlStyle + [csOpaque] ;

     end ;


destructor THTMLLabel.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     { Call inherited destructor }
     inherited Destroy ;

     BMap.Free ;

     end ;


procedure THTMLLabel.Paint ;
// ------------
// Display text
// ------------
const
    MaxLines = 1000 ;
type
     TState = (HTMLText, HTMLCommand, HTMLCommandEnd) ;
var
     iPointer : Integer ;
     LineSpacing : Integer ;
     c : String ;
     CommandText : String ;
     State : TState ;
     XPos : Integer ;
     YPos : Integer ;
     EndOfLine : Array[0..MaxLines-1] of TPoint ;
     Line : Integer ;
     i : Integer ;
     SrcRect : TRect ;
     DstRect : TRect ;
begin

     // Set internal bitmap to same size as label
     BMap.Width := Width ;
     BMap.Height := Height ;

     // Set text background colour
     BMap.Canvas.Brush.Color := Color  ;
     BMap.Canvas.Font.Color := Font.Color ;
     Canvas.Brush.Color := Color  ;
     BMap.Canvas.FillRect( Rect(0,0,Width,ClientHeight) ) ;
     Canvas.FillRect( Canvas.ClipRect );

     // Assign text font
     BMap.Canvas.Font.Assign(Font);
     BMap.Canvas.Font.Color := Font.Color ;

     // Vertical line spacing
     LineSpacing := Round(FLineSpacing*BMap.Canvas.TextHeight('X')) ;

     // Parse caption text
     Line := 0 ;
     iPointer := 1 ;
     State := HTMLText ;
     XPos := 0 ;
     YPos := 0 ;
     While (iPointer <= Length(FCaption)) and (Line < MaxLines) do begin

          // Get character
          c := FCaption[iPointer] ;

          if c = '<' then begin
             State := HTMLCommand ;
             CommandText := '' ;
             end
          else if c = '>' then begin
             State := HTMLCommandEnd ;
             end ;

          Case State of

             HTMLCommand : begin
                 CommandText := CommandText + UpperCase(c) ;
                 end ;

             HTMLCommandEnd : Begin

                 CommandText := CommandText + UpperCase(c) ;

                 if CommandText = '<BR>' then begin
                    EndOfLine[Line] := BMap.Canvas.PenPos ;
                    // Go to new line
                    YPos := YPos + LineSpacing ;
                    XPos := 0 ;
                    Inc(Line) ;
                    end
                 else if CommandText = '<B>' then begin
                    // Apply bold text style
                    BMap.Canvas.Font.Style := BMap.Canvas.Font.Style + [fsBold] ;
                    end
                 else if CommandText = '</B>' then begin
                    // Remove bold text style
                    BMap.Canvas.Font.Style := BMap.Canvas.Font.Style - [fsBold] ;
                    end
                 else if CommandText = '<I>' then begin
                    // Apply italic text style
                    BMap.Canvas.Font.Style := BMap.Canvas.Font.Style + [fsItalic] ;
                    end
                 else if CommandText = '</I>' then begin
                    // Remove italic text style
                    BMap.Canvas.Font.Style := BMap.Canvas.Font.Style - [fsItalic] ;
                    end
                 else if CommandText = '<U>' then begin
                    // Apply underline text style
                    BMap.Canvas.Font.Style := BMap.Canvas.Font.Style + [fsUnderline] ;
                    end
                 else if CommandText = '</U>' then begin
                    // Remove underline text style
                    BMap.Canvas.Font.Style := BMap.Canvas.Font.Style - [fsUnderline] ;
                    end
                 else if CommandText = '<SUB>' then begin
                    // Shift to subscript position
                    YPos := YPos + (BMap.Canvas.TextHeight('X') div 3) ;
                    end
                 else if CommandText = '</SUB>' then begin
                    // Return to normal position
                    YPos := YPos - (BMap.Canvas.TextHeight('X') div 3) ;
                    end
                 else if CommandText = '<SUP>' then begin
                    // Shift to superscript position
                    YPos := YPos - (BMap.Canvas.TextHeight('X') div 3) ;
                    end
                 else if CommandText = '</SUP>' then begin
                    // Return to normal position
                    YPos := YPos + (BMap.Canvas.TextHeight('X') div 3) ;
                    end
                 else if Pos('<FONT', CommandText) > 0 then begin
                    // Set type face
                    SetFace( CommandText ) ;
                    SetColor( CommandText ) ;
                    end
                 else if CommandText = '</FONT>' then begin
                    // Set type face back to default
                    BMap.Canvas.Font.Name := Font.Name ;
                    end ;

                 CommandText := '' ;
                 State := HTMLText ;
                 end ;

             // Output text to label
             HTMLText : Begin
                 BMap.Canvas.TextOut( XPos, YPos, c ) ;
                 XPos := BMap.Canvas.PenPos.X ;
                 YPos := BMap.Canvas.PenPos.Y ;
                 end ;

             end ;

          Inc(iPointer) ;

          end ;

     EndOfLine[Line] := BMap.Canvas.PenPos ;

     Case FAlignment of

          // Centre each line of text within label
          taCenter : begin
            for i := 0 to Line do begin
                SrcRect.Left := 0 ;
                SrcRect.Top := EndOfLine[i].Y ;
                SrcRect.Right := EndOfLine[i].X ;
                SrcRect.Bottom := SrcRect.Top + LineSpacing - 1 ;
                DstRect :=  SrcRect ;
                DstRect.Left := (ClientWidth - (SrcRect.Right - SrcRect.Left)) div 2 ;
                DstRect.Right := DstRect.Left + SrcRect.Right - SrcRect.Left ;
                Canvas.CopyRect( DstRect, BMap.Canvas, SrcRect ) ;
                end ;
            end ;

          // Left justify lines
          taLeftJustify : Begin
             Canvas.Draw(0,0,BMap);
             end ;

          // Right justify lines
          taRightJustify : Begin
            for i := 0 to Line do begin
                SrcRect.Left := 0 ;
                SrcRect.Top := EndOfLine[i].Y ;
                SrcRect.Right := EndOfLine[i].X ;
                SrcRect.Bottom := SrcRect.Top + LineSpacing - 1 ;
                DstRect :=  SrcRect ;
                DstRect.Left := ClientWidth - (SrcRect.Right - SrcRect.Left) ;
                DstRect.Right := DstRect.Left + SrcRect.Right - SrcRect.Left ;
                Canvas.CopyRect( DstRect, BMap.Canvas, SrcRect ) ;
                end ;
            end ;

          end ;

     end ;


procedure THTMLLabel.SetFace(
          CommandText : String
          ) ;
// ------------
// Set typeface
// ------------
const
     Keyword = 'FACE=' ;
var
     iStart,iEnd : Integer ;
begin

     iStart := Pos( Keyword, CommandText ) ;
     if iStart > 0 then begin
        iStart := iStart + Length(Keyword) ;
        iEnd := Pos( ',', CommandText ) - 1 ;
        if iEnd <= 0 then iEnd := Pos( '>', CommandText ) - 1 ;
        BMap.Canvas.Font.Name := Trim(Copy(CommandText, iStart, iEnd-iStart+1)) ;
        end ;

     end ;


procedure THTMLLabel.SetColor(
          CommandText : String
          ) ;
// ---------------
// Set font colour
// ---------------
const
     Keyword = 'COLOR=' ;
var
     iStart,iEnd,ColorValue : Integer ;
begin
     // Is there a colour specifier in command text ?
     iStart := Pos( Keyword, CommandText ) ;

     // Extract and colour value and set font colour
     if iStart > 0 then begin

        // Extract colour specifier argument
        iStart := iStart + Length(Keyword) ;
        iEnd := Pos( ',', CommandText ) - 1 ;
        if iEnd <= 0 then iEnd := Pos( '>', CommandText ) - 1 ;
        CommandText := Trim(Copy(CommandText, iStart, iEnd-iStart+1)) ;

        // Find start of colour value (indicated by #)
        iStart := Pos( '#', CommandText ) + 1 ;

        // Generate RGB value

        // Red
        ColorValue := StrToInt('$' + Copy(CommandText,iStart,2)) ;
        // Green
        ColorValue := ColorValue + 256*StrToInt('$' + Copy(CommandText,iStart+2,2)) ;
        // Blue
        ColorValue := ColorValue + 256*256*StrToInt('$' + Copy(CommandText,iStart+4,2)) ;

        // Set font
        BMap.Canvas.Font.Color := TColor(ColorValue) ;

        end ;
     end ;


procedure THTMLLabel.WriteCaption(
          NewCaption : String
          ) ;
// --------------------
// Update label caption
// --------------------
begin
     FCaption := NewCaption ;
     Invalidate ;
     end ;

function THTMLLabel.GetLineHeight : Integer ;
// -----------------------------------------------
// Get height (in pixels) of line of text in label
// -----------------------------------------------
begin
     Result := Trunc(FLineSpacing*Canvas.TextHeight('X')) + 1 ;
     end ;


end.
