unit ValEdit;
{ ----------------------------------------------------------
  Validated Edit box component (c) J. Dempster 1999
  ----------------------------------------------------------
  Numeric parameter edit box which ensures user-entered numbers
  are kept within specified limits
  28/10/99 ... Now handles both comma and period as decimal separator
  13/2/02 .... Invalid floating point values now trapped by LimitTo method
  }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TValidatedEdit = class(TCustomEdit)
  private
    { Private declarations }
      FValue : single ;
      FLoLimit : single ;
      FHiLimit : single ;
      FUnits : string ;
      FFormatString : string ;
      FScale : single ;
      procedure UpdateEditBox ;
      procedure SetValue(
                Value : single
                ) ;
      function GetValue : single ;

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

      procedure ExtractFloat (
          CBuf : string ;
          var Value : Single
          ) ;

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
    property Value : single read GetValue write SetValue  ;
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
  RegisterComponents('Samples', [TValidatedEdit]);
end;


constructor TValidatedEdit.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin
     inherited Create(AOwner) ;

     FScale := 1.0 ;
     FUnits := '' ;
     FLoLimit := -1E29 ;
     FHiLimit := 1E29 ;
     FFormatString := '%g' ;
     FValue := 0.0 ;
     end ;


procedure TValidatedEdit.SetValue(
          Value : single
          ) ;
{ -----------------------------------------------
  Set the current numerical value in the edit box
  -----------------------------------------------}
begin
     FValue := LimitTo( Value, FLoLimit, FHiLimit ) ;
     UpdateEditBox ;
     Invalidate ;
     end ;


function TValidatedEdit.GetValue : single ;
{ -----------------------------------------------
  Get the current numerical value in the edit box
  -----------------------------------------------}
begin
     ReadEditBox ;
     Result := FValue ;
     end ;



procedure TValidatedEdit.SetScale(
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

procedure TValidatedEdit.SetUnits(
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

procedure TValidatedEdit.SetFormatString(
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


procedure TValidatedEdit.UpdateEditBox ;
{ ------------------------------------
  Update the edit box with a new value
  -----------------------------------}
begin
     text := ' ' + format( FFormatString, [FValue*FScale] ) + ' ' + FUnits  ;
     end ;


procedure TValidatedEdit.KeyPress(
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

procedure TValidatedEdit.ReadEditBox ;
{ -----------------------------------------------
  Read the edit box and convert to floating point
  -----------------------------------------------}
begin
     ExtractFloat( text, FValue ) ;
     FValue := FValue / FScale ;
     // if (FValue < LoLimit) or (FValue > HiLimit) then Beep ;
     FValue := LimitTo( FValue, LoLimit, HiLimit ) ;

     end ;


function TValidatedEdit.LimitTo(
         Value : single ;          { Value to be checked }
         Lo : single ;             { Lower limit }
         Hi : single               { Upper limit }
         ) : single ;              { Return limited value }
{ --------------------------------
  Limit Value to the range Lo - Hi
  --------------------------------}
begin
     //outputdebugString(PChar(format('%.4g ',[Value]))) ;

    try
        if Value < Lo then Value := Lo ;
     Except
        On EInvalidOp do Value := Lo ;
        end ;

     try        if Value > Hi then Value := Hi ;
     Except
        On EInvalidOp do Value := Hi ;
        end ;
     Result := Value ;
     end ;


procedure TValidatedEdit.ExtractFloat (
          CBuf : string ;        { ASCII text to be processed }
          var Value : Single     { Default value if text is not valid }
          ) ;
{ -------------------------------------------------------------------
  Extract a floating point number from a string which
  may contain additional non-numeric text
  28/10/99 ... Now handles both comma and period as decimal separator
  -------------------------------------------------------------------}

var
   CNum : string ;
   i : integer ;
   Done,NumberFound : Boolean ;
begin
     { Extract number from other text which may be around it }
     CNum := '' ;
     Done := False ;
     NumberFound := False ;
     i := 1 ;
     repeat
         if CBuf[i] in ['0'..'9', 'E', 'e', '+', '-', '.', ',' ] then begin
            CNum := CNum + CBuf[i] ;
            NumberFound := True ;
            end
         else if NumberFound then Done := True ;
         Inc(i) ;
         if i > Length(CBuf) then Done := True ;
         until Done ;

     { Correct for use of comma/period as decimal separator }
     if (DECIMALSEPARATOR = '.') and (Pos(',',CNum) <> 0) then
        CNum[Pos(',',CNum)] := DECIMALSEPARATOR ;
     if (DECIMALSEPARATOR = ',') and (Pos('.',CNum) <> 0) then
        CNum[Pos('.',CNum)] := DECIMALSEPARATOR ;

     { Convert number from ASCII to real }
     try
        if Length(CNum)>0 then Value := StrToFloat( CNum ) ;
     except
        on E : EConvertError do ;
        end ;
end ;


end.
