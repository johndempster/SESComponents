unit RangeEdit;
{ ----------------------------------------------------------
  Range Edit box component (c) J. Dempster 1999
  ----------------------------------------------------------
  Numeric parameter edit box for entering a low - high limit range
  (e.g. 1-10) User-entered data kept within specified limits
  28/10/99 ... Now handles both comma and period as decimal separator
  }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TRangeEdit = class(TCustomEdit)
  private
    { Private declarations }
      FLoValue : single ;
      FHiValue : single ;
      FLoLimit : single ;
      FHiLimit : single ;
      FUnits : string ;
      FFormatString : string ;
      FScale : single ;

      procedure UpdateEditBox ;
      procedure SetLoValue(
                Value : single
                ) ;
      procedure SetHiValue(
                Value : single
                ) ;

      function GetLoValue : single ;
      function GetHiValue : single ;

      procedure SetScale(
                Value : single
                ) ;
      procedure SetUnits(
                Value : string
                ) ;
      procedure SetFormatString(
                Value : string
                ) ;
      procedure ReadEditBox ;          
      function LimitTo(
               Value : single ;          { Value to be checked }
               Lo : single ;             { Lower limit }
               Hi : single               { Upper limit }
               ) : single ;

      function ExtractListOfFloats (
         const CBuf : string ;
         var Values : Array of Single ;
         PositiveOnly : Boolean
         ) : Integer ;


  protected
    { Protected declarations }
    procedure KeyPress(
              var Key : Char
              ) ; override ;
  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
  published
    { Published declarations }
    property OnKeyPress ;
    property AutoSelect ;
    property AutoSize ;
    property BorderStyle ;
    property Color ;
    property Font ;
    property Height ;
    property HelpContext ;
    property HideSelection ;
    property Hint ;
    property Left ;
    property Name ;
    property ShowHint ;
    property Top ;
    property Text ;
    property Visible ;
    property Width ;
    property LoValue : single read GetLoValue write SetLoValue  ;
    property HiValue : single read GetHiValue write SetHiValue  ;
    property LoLimit : single read FLoLimit write FLoLimit  ;
    property HiLimit : single read FHiLimit write FHiLimit  ;
    property Scale : single read FScale write SetScale  ;
    property Units : string read FUnits write SetUnits  ;
    property NumberFormat : string
             read FFormatString write SetFormatString  ;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TRangeEdit]);
end;


constructor TRangeEdit.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin
     inherited Create(AOwner) ;

     FScale := 1.0 ;
     FUnits := '' ;
     FLoLimit := 0.0 ;
     FHiLimit := 1E30 ;
     FFormatString := '%.f - %.f' ;
     FLoValue := 0.0 ;
     FHiValue := 0.0 ;
     end ;


procedure TRangeEdit.SetLoValue(
          Value : single
          ) ;
{ -------------------------------------------------
  Set the current lower range limit in the edit box
  -------------------------------------------------}
begin
     FLoValue := LimitTo( Value, FLoLimit, FHiLimit ) ;
     UpdateEditBox ;
     Invalidate ;
     end ;


procedure TRangeEdit.SetHiValue(
          Value : single
          ) ;
{ -------------------------------------------------
  Set the current upper range limit in the edit box
  -------------------------------------------------}
begin
     FHiValue := LimitTo( Value, FLoLimit, FHiLimit ) ;
     UpdateEditBox ;
     Invalidate ;
     end ;



function TRangeEdit.GetLoValue : single ;
{ -----------------------------------------------
  Get the current lower range limit in the edit box
  -----------------------------------------------}
begin
     ReadEditBox ;
     Result := FLoValue ;
     end ;


function TRangeEdit.GetHiValue : single ;
{ -----------------------------------------------
  Get the current upper range limit in the edit box
  -----------------------------------------------}
begin
     ReadEditBox ;
     Result := FHiValue ;
     end ;


procedure TRangeEdit.SetScale(
          Value : single
          ) ;
{ --------------------------------------------
  Set the interval -> edit box scaling factor
  --------------------------------------------}
begin
     FScale := Value ;
     UpdateEditBox ;
     Invalidate ;
     end ;


procedure TRangeEdit.SetUnits(
          Value : string
          ) ;
{ -------------------------------------------------
  Set the units of the value stored in the edit box
  -------------------------------------------------}
begin
     FUnits := Value ;
     UpdateEditBox ;
     Invalidate ;
     end ;

procedure TRangeEdit.SetFormatString(
          Value : string
          ) ;
{ -------------------------------------------------
  Set the units of the value stored in the edit box
  -------------------------------------------------}
begin
     FFormatString := Value ;
     UpdateEditBox ;
     Invalidate ;
     end ;


procedure TRangeEdit.UpdateEditBox ;
{ ------------------------------------
  Update the edit box with a new value
  -----------------------------------}
begin
     text := ' ' + format( FFormatString, [FLoValue*FScale,FHiValue*FScale] )
             + ' ' + FUnits  ;
     end ;


procedure TRangeEdit.KeyPress(
          var Key : Char
          ) ;
begin

     inherited KeyPress( Key ) ;

     if Key = chr(13) then begin
        ReadEditBox ;
        UpdateEditBox ;
        Invalidate ;
        end ;
     end ;


procedure TRangeEdit.ReadEditBox ;
{ -----------------------------------------------
  Read the edit box and convert to floating point
  -----------------------------------------------}
var
   Values : Array[0..10] of Single ;
   Temp : Single ;
   nValues : Integer ;
begin
     FLoValue := LoLimit ;
     FHiValue := HiLimit ;
     nValues := ExtractListofFloats( text, Values, True ) ;
     if nValues =1 then begin
        FLoValue := Values[0] ;
        FHiValue := Values[0] ;
        end
     else if nValues >=2 then begin
        FLoValue := Values[0] ;
        FHiValue := Values[1] ;
        end ;

     if FLoValue > FHiValue then begin
        Temp := FLoValue ;
        FLoValue := FHiValue ;
        FHiValue := Temp ;
        end ;

     { Scale values back to internal scaling }
     if FScale <> 0.0 then begin
        FLoValue := FLoValue / FScale ;
        FHiValue := FHiValue / FScale ;
        end ;

     { Keep within allowed limits }
     FLoValue := LimitTo( FLoValue, FLoLimit, FHiLimit ) ;
     FHiValue := LimitTo( FHiValue, FLoLimit, FHiLimit ) ;

     end ;



function TRangeEdit.LimitTo(
         Value : single ;          { Value to be checked }
         Lo : single ;             { Lower limit }
         Hi : single               { Upper limit }
         ) : single ;              { Return limited value }
{ --------------------------------
  Limit Value to the range Lo - Hi
  --------------------------------}
begin
     if Value < Lo then Value := Lo ;
     if Value > Hi then Value := Hi ;
     Result := Value ;
     end ;


function TRangeEdit.ExtractListOfFloats (
         const CBuf : string ;
         var Values : Array of Single ;
         PositiveOnly : Boolean
         ) : Integer ;
{ -------------------------------------------------------------
  Extract a series of floating point number from a string which
  may contain additional non-numeric text
  ---------------------------------------}

var
   CNum : string ;
   i,nValues : integer ;
   EndOfNumber : Boolean ;
begin
     nValues := 0 ;
     CNum := '' ;
     for i := 1 to length(CBuf) do begin

         { If character is numeric ... add it to number string }
         if PositiveOnly then begin
            { Minus sign is treated as a number separator }
            if CBuf[i] in ['0'..'9', 'E', 'e', '.', ',' ] then begin
               CNum := CNum + CBuf[i] ;
               EndOfNumber := False ;
               end
            else EndOfNumber := True ;
            end
         else begin
            { Positive or negative numbers }
            if CBuf[i] in ['0'..'9', 'E', 'e', '.', '-', ',' ] then begin
               CNum := CNum + CBuf[i] ;
               EndOfNumber := False ;
               end
            else EndOfNumber := True ;
            end ;

         { If all characters are finished ... check number }
         if i = length(CBuf) then EndOfNumber := True ;

         if (EndOfNumber) and (Length(CNum) > 0)
            and (nValues <= High(Values)) then begin
              try
                 { Correct for use of comma/period as decimal separator }
                 if (DECIMALSEPARATOR = '.') and (Pos(',',CNum) <> 0) then
                    CNum[Pos(',',CNum)] := DECIMALSEPARATOR ;
                 if (DECIMALSEPARATOR = ',') and (Pos('.',CNum) <> 0) then
                    CNum[Pos('.',CNum)] := DECIMALSEPARATOR ;
                 { Convert to floatinf point }
                 Values[nValues] := StrToFloat( CNum ) ;
                 CNum := '' ;
                 Inc(nValues) ;
              except
                    on E : EConvertError do CNum := '' ;
                    end ;
              end ;
         end ;
     { Return number of values extracted }
     Result := nValues ;
     end ;


end.
