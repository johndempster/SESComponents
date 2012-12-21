unit ValidatedEdit;
{ ----------------------------------------------------------
  Validated Edit box component (c) J. Dempster 1999
  ----------------------------------------------------------
  Numeric parameter edit box which ensures user-entered numbers
  are kept within specified limits
  28/10/99 ... Now handles both comma and period as decimal separator
  13/2/02 .... Invalid floating point values now trapped by LimitTo method
  25/8/03 .... Out of bounds error with empty edit box fixed
  01/09/5 .... Design-time Value property now retained correctly
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
      FLoLimitSet : Boolean ;
      FHiLimit : single ;
      FHiLimitSet : Boolean ;
      FUnits : string ;
      FFormatString : string ;
      FScale : single ;
      procedure UpdateEditBox ;
      procedure SetValue( Value : single ) ;
      function GetValue : single ;
      procedure SetScale( Value : single ) ;
      procedure SetUnits( Value : string ) ;
      procedure SetFormatString( Value : string ) ;
      procedure SetLoLimit( Value : Single ) ;

      procedure SetHiLimit( Value : Single ) ;

      procedure ReadEditBox ;
      function LimitTo( Value : single ) : single ;

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
    property Scale : single read FScale write SetScale  ;
    property Units : string read FUnits write SetUnits  ;
    property NumberFormat : string
             read FFormatString write SetFormatString  ;
    property LoLimit : single read FLoLimit write SetLoLimit ;
    property HiLimit : single read FHiLimit write SetHiLimit  ;

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
     FLoLimit := -1E30 ;
     FHiLimit := 1E30 ;
     FLoLimitSet := False ;
     FHiLimitSet := False ;
     FScale := 1.0 ;
     FFormatString := '%.4g' ;
     FUnits := '' ;

     end ;


procedure TValidatedEdit.SetValue(
          Value : single
          ) ;
{ -----------------------------------------------
  Set the current numerical value in the edit box
  -----------------------------------------------}
begin
     FValue := LimitTo( Value ) ;
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


procedure TValidatedEdit.SetLoLimit(
          Value : Single
          ) ;
{ -------------------------------------------------
  Set the lower limit of the value stored in the edit box
  -------------------------------------------------}
begin
     FLoLimit := Value ;
     FLoLimitSet := True ;
     UpdateEditBox ;
     Invalidate ;
     end ;


procedure TValidatedEdit.SetHiLimit(
          Value : Single
          ) ;
{ -------------------------------------------------
  Set the upper limit of the value stored in the edit box
  -------------------------------------------------}
begin
     FHiLimit := Value ;
     FHiLimitSet := True ;
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
     FValue := FValue*FScale ;
     ExtractFloat( text, FValue ) ;     FValue := LimitTo( FValue / FScale ) ;
     end ;


function TValidatedEdit.LimitTo(
         Value : single           { Value to be checked }
         ) : single ;              { Return limited value }
{ --------------------------------
  Limit Value to the range Lo - Hi
  --------------------------------}
begin

    // Exit if limits have not been set
    Result := Value ;

    if FLoLimitSet then begin
       try if Value < FLoLimit then Value := FLoLimit ;
       Except
          On EInvalidOp do Value := FLoLimit ;
          end ;
       end ;

    if FHiLimitSet then begin
       try if Value > FHiLimit then Value := FHiLimit ;
       Except
           On EInvalidOp do Value := FHiLimit ;
           end ;
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

     if Length(CBuf) = 0 then Exit ;

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
