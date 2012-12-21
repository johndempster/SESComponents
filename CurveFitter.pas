unit CurveFitter;
// -----------------------
// Non-linear curve fitter
// -----------------------
// (c) J. Dempster, University of Strathclyde, 2003
// 8-6-03
// 14.08.06

interface

uses
  SysUtils, Classes, COmCtrls, SHDocVw ;

const
     ChannelLimit = 7 ;
     LastParameter = 11 ;
     MaxBuf = 32768 ;
     MaxWork = 9999999 ;

type
    TWorkArray = Array[0..MaxWork] of Single ;
    TDataArray = Array[0..MaxBuf] of Single ;

    TCFEqnType = ( None,
                 Lorentzian,
                 Lorentzian2,
                 LorAndOneOverF,
                 Linear,
                 Parabola,
                 Exponential,
                 Exponential2,
                 Exponential3,
                 MEPCNoise,
                 EPC,
                 HHK,
                 HHNa,
                 Gaussian,
                 Gaussian2,
                 Gaussian3,
                 PDFExp,
                 PDFExp2,
                 PDFExp3,
                 PDFExp4,
                 PDFExp5,
                 Quadratic,
                 Cubic,
                 DecayingExp,
                 DecayingExp2,
                 DecayingExp3,
                 Boltzmann,
                 PowerFunc ) ;

    TPars = record
          Value : Array[0..LastParameter+1] of Single ;
          SD : Array[0..LastParameter+1] of Single ;
          Map : Array[0..LastParameter+1] of Integer ;
          end ;

  TCurveFitter = class(TComponent)
  private
    { Private declarations }
    FXUnits : string ;        // X data units
    FYUnits : string ;        // Y data units
    FEqnType : TCFEqnType ;     // Type of equation to be fitted

    // Equation parameters
    Pars : Array[0..LastParameter] of single ;       // Parameter values
    ParSDs : Array[0..LastParameter] of single ;     // Parameters st. devs
    AbsPars : Array[0..LastParameter] of boolean ;   // Positive only flags
    LogPars : Array[0..LastParameter] of boolean ;   // Log. transform flags
    FixedPars : Array[0..LastParameter] of boolean ; // Fixed parameter flags
    ParameterScaleFactors : Array[0..LastParameter] of single ;
    ParsSet : Boolean ;              { Initial parameters set for fit }

    // Data points of curve to be fitted
    nPoints : Integer ;                      // No. of data points
    XData : Array[0..MaxBuf] of Single ;     // X values
    YData : Array[0..MaxBuf] of Single ;     // Y values
    BinWidth : Array[0..MaxBuf] of Single ;  // Binwidth (if histogram)
    Normalised : boolean ;                   // Data normalised
    { Curve fitting }
    ResidualSDScaleFactor : single ;

    UseBinWidthsFlag : Boolean ;     { Use histogram bin widths in fit }
    ResidualSDValue : single ;       { Residual standard deviation }
    RValue : single ;                { Hamilton's R }
    DegreesOfFreedomValue : Integer ; { Statistical deg's of freedom }
    IterationsValue : Integer ;    // No. of iterations to achieve fit
    GoodFitFlag : Boolean ;        // Fit has been successful flag

    Procedure SetupNormalisation( xScale : single ; yScale : single ) ;
    function NormaliseParameter( Index : Integer ; Value : single ) : single ;
    function DenormaliseParameter( Index : Integer ; Value : single ) : single ;
    procedure SetParameter( Index : Integer ; Value : single ) ;
    function GetParameter( Index : Integer) : single ;
    function GetParameterSD( Index : Integer ) : single ;
    function GetLogParameter( Index : Integer ) : boolean ;
    function GetFixed( Index : Integer ) : boolean ;
    procedure SetFixed( Index : Integer ; Fixed : Boolean ) ;
    function GetParName( Index : Integer ) : string ;
    function GetParUnits( Index : Integer ) : string ;
    function GetNumParameters : Integer ;
    function GetName : String ;

    function PDFExpFunc( Pars : Array of single ; nExp : Integer ; X : Single ) : Single ;
    procedure PDFExpScaling(
              var AbsPars : Array of Boolean ;
              var LogPars : Array of Boolean ;
              var ParameterScaleFactors : Array of Single ;
              yScale : Single ;
              nExp : Integer ) ;

    procedure PDFExpNames( var ParNames : Array of String ; nExp : Integer ) ;
    procedure PDFExpUnits( var ParUnits : Array of String ; FXUnits : String ; nExp : Integer ) ;
    function GaussianFunc( Pars : Array of single ; nGaus : Integer ; X : Single ) : Single ;

    procedure ScaleData  ;
    procedure UnScaleParameters ;

    procedure SsqMin (
          var Pars : TPars ;
          nPoints,nPars,ItMax,NumSig,NSiqSq : LongInt ;
          Delta : Single ;
          var W,SLTJJ : Array of Single ;
          var ICONV,ITER : LongInt ;
          var SSQ : Single ;
          var F : Array of Single ) ;

    procedure FitFunc(
          Const FitPars :TPars ;
          nPoints : Integer ;
          nPars : Integer ;
          Var Residuals : Array of Single ;
          iStart : Integer
          ) ;


    function SSQCAL(
         const Pars : TPars ;
         nPoints : Integer ;
         nPars : Integer ;
         var Residuals : Array of Single ;
         iStart : Integer ;
         const W : Array of Single
         ) : Single ;

    procedure STAT(
          nPoints : Integer ;         { no. of residuals (observations) }
          nPars : Integer ;           { no. of fitted parameters }
          var F : Array of Single ;   { final values of the residuals (IN) }
          var Y : Array of Single ;   { Y Data (IN) }
          var W : Array of Single ;   { Y Data weights (IN) }
          var SLT : Array of Single ; { lower super triangle of
                                        J(TRANS)*J from SLTJJ in SSQMIN (IN) }
          var SSQ : Single;           { Final sum of squares of residuals (IN)
                                        Returned containing parameter corr. coeffs.
                                        as CX(1,1),CX(2,1),CX(2,2),CX(3,1)....CX(N,N)}
          var SDPars : Array of Single ; { OUT standard deviations of each parameter X }
          var SDMIN : Single ;         { OUT Minimised standard deviation }
          var R : Single ;               { OUT Hamilton's R }
          var XPAR : Array of Single     { IN Fitted parameter array }
          ) ;

    procedure MINV(
          var A : Array of Single ;
          N : LongInt ;
          var D : Single ;
          var L,M : Array of LongInt
          ) ;
    FUNCTION SQRT1 (
         R : single
         ) : single ;


    function IntLimitTo( Value, LowerLimit, UpperLimit : Integer ) : Integer ;
    function erf(x : Single ) : Single ;
    function FPower( x,y : Single ) : Single ;
    function SafeExp( x : single ) : single ;
    function MinInt( const Buf : array of LongInt ) : LongInt ;
    function MinFlt( const Buf : array of Single ) : Single ;
    function MaxInt( const Buf : array of LongInt ) : LongInt ;
    function MaxFlt( const Buf : array of Single ) : Single ;

    function GetFitResults : String ;

  protected
    { Protected declarations }
  public
    { Public declarations }

    constructor Create(AOwner : TComponent) ; override ;
    destructor Destroy ; override ;

    property XUnits : String Read FXUnits Write FXUnits ;
    property YUnits : String Read FYUnits Write FYUnits ;

    property Parameters[i : Integer] : single read GetParameter write SetParameter ;
    property ParameterSDs[i : Integer] : single read GetParameterSD ;

    property IsLogParameters[i : Integer] : boolean read GetLogParameter ;
    property FixedParameters[i : Integer] : boolean read GetFixed write SetFixed ;
    property ParNames[i : Integer] : string read GetParName ;
    property ParUnits[i : Integer] : string read GetParUnits ;


    procedure AddPoint( XValue : Single ; YValue : Single ) ;
    procedure ClearPoints ;

    function InitialGuess( Index : Integer ) : single ;
    function EquationValue( X : Single ) : Single ;                 { Return f(X) }
    procedure FitCurve ;

    procedure CopyResultsToWebBrowser( WebBrowser : TWebBrowser ) ;



  published
    { Published declarations }
    property Equation : TCFEqnType Read FEqnType Write FEqnType ;
    Property NumParameters : Integer Read GetNumParameters ;
    Property NumPoints : Integer Read nPoints ;
    Property ParametersSet : Boolean read ParsSet write ParsSet ;
    property GoodFit : Boolean read GoodFitFlag ;
    property DegreesOfFreedom : Integer read DegreesOfFreedomValue ;
    property R : single read RValue;
    property Iterations : Integer read IterationsValue ;
    property ResidualSD : single read ResidualSDValue ;
    property UseBinWidths : Boolean read UseBinWidthsFlag write UseBinWidthsFlag ;
    property EqnName : string read GetName ;
    property FitResults : String read GetFitResults ;
  end;

procedure Register;

implementation

  const
     MaxSingle = 1E38 ;



procedure Register;
begin
  RegisterComponents('Samples', [TCurveFitter]);
end;

constructor TCurveFitter.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin

     inherited Create(AOwner) ;

     FXUnits := '' ;
     FYUnits := '' ;
     nPoints := 0 ;

     end ;


destructor TCurveFitter.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     { Call inherited destructor }
     inherited Destroy ;

     end ;


procedure TCurveFitter.AddPoint(
          XValue : Single ;
          YValue : Single
          ) ;
// --------------------------------------------
// Add new point to X,Y data array to be fitted
// --------------------------------------------
begin
     if nPoints < High(XData) then begin
        XData[nPoints] := XValue ;
        YData[nPoints] := YValue ;
        Inc(nPoints) ;
        end ;
     end ;


procedure TCurveFitter.ClearPoints ;
// --------------------
// Clear X,Y data array
// --------------------
begin
     nPoints := 0 ;
     end ;


function TCurveFitter.GetName : String ;
{ -------------------------------
  Get the formula of the equation
  -------------------------------}
var
   Name : string ;
begin

     Case FEqnType of
          Lorentzian : begin
              Name := ' y(f) = S<sub>0</sub>/(1 + (f/f<sub>c</sub>)<sup>2</sub>)' ;
              end ;

          Lorentzian2 : Name := ' y(f) = S<sub>1</sub>/(1 + (f/f<sub>c1</sub>)<sup>2</sup>'
                                + ' + S<sub>2</sub>/(1 + (f/f<sub>c2</sub>)<sup>2</sup>)' ;

          LorAndOneOverF : Name := ' y(f) = S<sub>1</sub>/(1 + (f/F<sub>c1</sub>)<sup>2</sup>'
                                + 'S<sub>2</sub>/f<sup>2</sup> )' ;

          Linear : Name := ' y(x) = Mx + C' ;

          Parabola : Name := ' y(x) = V<sub>b</sub> + I<sub>ux</sub> - x<sup>2</sup>/N<sub>c</sub> ' ;

          Exponential : Name := ' y(t) = Aexp(-t/<Font face=symbol>t</Font>) + Ss ' ;

          Exponential2 : Name := ' y(t) = A<sub>1</sub>exp(-t/<Font face=symbol>t</Font><sub>1</sub>1)'
                                   + 'A<sub>2</sub>exp(-t/<Font face=symbol>t</Font><sub>2</sub>) + Ss ' ;

          Exponential3 : Name := 'y(t) = A<sub>1</sub>exp(-t/<Font face=symbol>t</Font><sub>1</sub>1)'
                                 + '+ A<sub>2</sub>exp(-t/<Font face=symbol>t</Font><sub>2</sub>)'
                                 + '+ A<sub>3</sub>exp(-t/<Font face=symbol>t</Font><sub>3</sub>)+ Ss ' ;

          EPC : Name := ' y(t) = A0.5(1+erf(x-x<sub>0</sub>)/<Font face=symbol>t</Font><sub>R</sub>)'
                        + 'exp(-(x-x<sub>0</sub>)/<Font face=symbol>t</Font><sub>D</sub>))' ;

          MEPCNoise : Name := ' y(f) = A/[1+(f<sup>2</sup>(1/F<sub>r</sub><sup>2</sup> '
                              + '+ 1/F<sub>d</sub><sup>2</sup>))'
                              + '+f<sup>4</sup>/(F<sub>r</sub><sup>2</sup>F<sub>d</sub><sup>2</sup>)]' ;

          HHK : Name := ' y(t) = A(1 - exp(-t/<Font face=symbol>t</Font><sub>M</sub>)<sup>P</sup>' ;

          HHNa : Name := ' y(t) = A[(1 - exp(-t/<Font face=symbol>t</Font><sub>M</sub>)<sup>P</sup>]'
                         + '[H<sub>inf</sub> - (H<sub>inf</sub>-1)exp(-t/<Font face=symbol>t</Font><sub>H</sub>)]' ;

          Gaussian : Name := ' y(x) = Peak exp(-(x-<Font face=symbol>m</Font>)<sup>2</sup>/'
                             + '(2<Font face=symbol>s</Font><sup>2</sup>) )' ;

          Gaussian2 : Name := ' y(x) = <Font face=symbol>S</Font><sub>i=1..2</sub>'
                              + 'Pk<sub>i</sub>exp(-(x-<Font face=symbol>m</Font><sub>i</sub>)<sup>2</sup>'
                              + '/(2<Font face=symbol>s</Font><sub>i</sub><sup>2</sup>) )' ;

          Gaussian3 : Name := ' y(x) = <Font face=symbol>S</Font><sub>i=1..3</sub>'
                              + 'Pk<sub>i</sub>exp(-(x-<Font face=symbol>m</Font><sub>i</sub>)<sup>2</sup>'
                              + '/(2<Font face=symbol>s</Font><sub>i</sub><sup>2</sup>) )' ;

          PDFExp : Name := ' y(t) = (A/<Font face=symbol>t</Font>)exp(-t/<Font face=symbol>t</Font>)' ;

          PDFExp2 : Name := ' p(t) = <Font face=symbol>S</Font><sub>i=1..2</sub>'
                            + '(A<sub>i</sub>/<Font face=symbol>t</Font><sub>i</sub>)'
                            + 'exp(-t/<Font face=symbol>t</Font><sub>i</sub>)' ;

          PDFExp3 : Name := ' p(t) = <Font face=symbol>S</Font><sub>i=1..3</sub>'
                            + '(A<sub>i</sub>/<Font face=symbol>t</Font><sub>i</sub>)'
                            + 'exp(-t/<Font face=symbol>t</Font><sub>i</sub>)' ;

          PDFExp4 : Name := ' p(t) = <Font face=symbol>S</Font><sub>i=1..4</sub>'
                            + '(A<sub>i</sub>/<Font face=symbol>t</Font><sub>i</sub>)'
                            + 'exp(-t/<Font face=symbol>t</Font><sub>i</sub>)' ;

          PDFExp5 : Name := ' p(t) = <Font face=symbol>S</Font><sub>i=1..5</sub>'
                            + '(A<sub>i</sub>/<Font face=symbol>t</Font><sub>i</sub>)'
                            + 'exp(-t/<Font face=symbol>t</Font><sub>i</sub>)' ;

          Quadratic : Name := ' y(x) = Ax<sup>2</sup> + Bx + C' ;

          Cubic : Name := 'y (x) = Ax<sup>3</sup> + Bx<sup>2</sup> + Cx + D' ;

          DecayingExp : Name := ' y(t) = Aexp(-t/<Font face=symbol>t</Font>)' ;

          DecayingExp2 : Name := ' y(t) = A<sub>1</sub>exp(-t/<Font face=symbol>t</Font><sub>1</sub>)'
                                 + ' + A<sub>2</sub>exp(-t/<Font face=symbol>t</Font><sub>2</sub>)' ;
          DecayingExp3 : Name := ' y(t) = A<sub>1</sub>exp(-t/<Font face=symbol>t</Font><sub>1</sub>)'
                                + ' + A<sub>2</sub>exp(-t/<Font face=symbol>t</Font><sub>2</sub>)'
                                + ' + A<sub>3</sub>exp(-t/<Font face=symbol>t</Font><sub>3</sub>)' ;

          Boltzmann : Name :=  'y(x) = y<sub>max</sub> / (1 + exp( -(x-x<sub>1/2</sub>)'
                              + '/x<sub>slp</sub>)) + y<sub>min</sub>' ;

          PowerFunc : Name := 'y(x) = Ax<sup>B</sup>' ;
          
          else Name := 'None' ;
          end ;


     Result := Name ;
     end ;


procedure TCurveFitter.CopyResultsToWebBrowser(
          WebBrowser : TWebBrowser
          ) ;
// -------------------------------------
// Copy results to HTML Viewer component
// -------------------------------------
var
     HTMLFileName : String ;
     HTMLFile : TextFile ;
     i : Integer ;
begin

      // Create file to hold results
      HTMLFileName := 'c:\curvefitter.htm' ;
      AssignFile( HTMLFile, HTMLFileName ) ;
      Rewrite( HTMLFile ) ;

      WriteLn( HTMLFile, '<HTML>' );
      WriteLn( HTMLFile, '<TITLE>Fit Results</TITLE>' ) ;

      if FEqnType <> None then begin
         // Fitted equation
         WriteLn( HTMLFile, GetName + '<br>' ) ;

         { Best fit parameters and standard error }
         for i := 0 to GetNumParameters-1 do begin
             if not FixedParameters[i] then
                WriteLn( HTMLFile, format(' %s = %.4g ± %.4g (sd) %s <br>',
                                  [ParNames[i],
                                   Parameters[i],
                                   ParameterSDs[i],
                                   ParUnits[i]] ) )
             else
                { Fixed parameter }
                WriteLn( HTMLFile, format(' %s = %.4g (fixed) %s <br>',
                                   [ParNames[i],
                                    Parameters[i],
                                    ParUnits[i]] ) ) ;
             end ;

         { Residual standard deviation }
         WriteLn( HTMLFile, format(' Residual S.D. = %.4g %s <br>',[ResidualSD,'' ] )) ;

         { Statistical degrees of freedom }
         WriteLn( HTMLFile, format(' Degrees of freedom = %d <br>',[DegreesOfFreedom]) );
         end ;

      // Close page
      WriteLn( HTMLFile, '</HTML>' );
      CloseFile( HTMLFile ) ;

      WebBrowser.Navigate( HTMLFileName ) ;

      end ;

     { Make sure plot is updated with changes }


function TCurveFitter.GetFitResults : String ;
// -------------------------------------
// Get fit results
// -------------------------------------
var
     s : String ;
     i : Integer ;
begin

      s := 'Fit Results<br>' ;

      if FEqnType <> None then begin
         // Fitted equation
         s := s + GetName + '<br>' ;

         { Best fit parameters and standard error }
         for i := 0 to GetNumParameters-1 do begin
             if not FixedParameters[i] then
                s := s + format(' %s = %.4g ± %.4g (sd) %s <br>',
                                  [ParNames[i],
                                   Parameters[i],
                                   ParameterSDs[i],
                                   ParUnits[i]] )
             else
                { Fixed parameter }
                s := s + format(' %s = %.4g (fixed) %s <br>',
                                   [ParNames[i],
                                    Parameters[i],
                                    ParUnits[i]] ) ;
             end ;

         { Residual standard deviation }
         s := s + format(' Residual S.D. = %.4g %s <br>',[ResidualSD,'' ] ) ;

         { Statistical degrees of freedom }
         s := s + format(' Degrees of freedom = %d <br>',[DegreesOfFreedom]) ;
         end ;

      Result := s ;

      end ;



function TCurveFitter.GetNumParameters ;
{ ------------------------------------
  Get number of parameters in equation
  ------------------------------------}
var
   nPars : Integer ;
begin
     Case FEqnType of
          Lorentzian : nPars := 2 ;
          Lorentzian2 : nPars := 4 ;
          LorAndOneOverF : nPars := 3 ;
          Linear : nPars := 2 ;
          Parabola : nPars := 3 ;
          Exponential : nPars := 3 ;
          Exponential2 : nPars := 5 ;
          Exponential3 : nPars := 7 ;
          EPC : nPars := 4 ;
          HHK : nPars := 3 ;
          HHNa : nPars := 5 ;
          MEPCNoise : nPArs := 3 ;
          Gaussian : nPars := 3 ;
          Gaussian2 : nPars := 6 ;
          Gaussian3 : nPars := 9 ;
          PDFExp : nPars := 2 ;
          PDFExp2 : nPars := 4 ;
          PDFExp3 : nPars := 6 ;
          PDFExp4 : nPars := 8 ;
          PDFExp5 : nPars := 10 ;
          Quadratic : nPars := 3 ;
          Cubic : nPars := 4 ;
          DecayingExp : nPars := 2 ;
          DecayingExp2 : nPars := 4 ;
          DecayingExp3 : nPars := 6 ;
          Boltzmann : nPars := 4 ;
          PowerFunc : nPars := 2 ;
          else nPars := 0 ;
          end ;
     Result := nPars ;
     end ;


function TCurveFitter.GetParameter(
         Index : Integer
         ) : single ;
{ ----------------------------
  Get function parameter value
  ----------------------------}
begin
     Index := IntLimitTo(Index,0,GetNumParameters-1) ;
     Result := Pars[Index] ;
     end ;


function TCurveFitter.GetParameterSD(
         Index : Integer
         ) : single ;
{ -----------------------------------------
  Get function parameter standard deviation
  -----------------------------------------}
begin
     Index := IntLimitTo(Index,0,GetNumParameters-1) ;
     Result := ParSDs[Index] ;
     end ;


function TCurveFitter.GetLogParameter(
         Index : Integer
         ) : boolean ;
{ --------------------------------------
  Read the parameter log transform array
  --------------------------------------}
begin
     Index := IntLimitTo(Index,0,GetNumParameters-1) ;
     Result := LogPars[Index] ;
     end ;


function TCurveFitter.GetFixed(
         Index : Integer
         ) : boolean ;
{ --------------------------------------
  Read the parameter fixed/unfixed array
  --------------------------------------}
begin
     Index := IntLimitTo(Index,0,GetNumParameters-1) ;
     Result := FixedPars[Index] ;
     end ;


procedure TCurveFitter.SetFixed(
         Index : Integer ;
         Fixed : Boolean
         ) ;
{ --------------------------------------
  Set the parameter fixed/unfixed array
  --------------------------------------}
begin
     Index := IntLimitTo(Index,0,GetNumParameters-1) ;
     FixedPars[Index] := Fixed ;
     end ;


procedure TCurveFitter.SetParameter(
          Index : Integer ;
          Value : single
          ) ;
{ -----------------------------
  Set function parameter value
  -----------------------------}
begin
     Index := IntLimitTo(Index,0,GetNumParameters-1) ;
     Pars[Index] := Value ;
     end ;


function TCurveFitter.GetParName(
         Index : Integer  { Parameter index number (IN) }
         ) : string ;
{ ---------------------------
  Get the name of a parameter
  ---------------------------}
var
   ParNames : Array[0..LastParameter] of string ;
begin
     Case FEqnType of
          Lorentzian : begin
                 ParNames[0] := 'S^-0' ;
                 ParNames[1] := 'f^-c' ;
                 end ;
          Lorentzian2 : begin
                 ParNames[0] := 'S<sub>1</sub>' ;
                 ParNames[1] := 'f<sub>c1</sub>' ;
                 ParNames[2] := 'S<sub>2</sub>' ;
                 ParNames[3] := 'f<sub>c2</sub>' ;
                 end ;
          LorAndOneOverF : begin
                 ParNames[0] := 'S<sub>1</sub>' ;
                 ParNames[1] := 'f<sub>c1</sub>' ;
                 ParNames[2] := 'S<sub>2</sub>' ;
                 end ;
          Linear : begin
                 ParNames[0] := 'C' ;
                 ParNames[1] := 'M' ;
                 end ;
          Parabola : begin
                 ParNames[0] := 'I<sub>u</sub>' ;
                 ParNames[1] := 'N<sub>c</sub>' ;
                 ParNames[2] := 'V<sub>b</sub>' ;
                 end ;
          Exponential : begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := '<Font face=symbol>t</Font>' ;
                 ParNames[2] := 'Ss' ;
                 end ;
          Exponential2 : begin
                 ParNames[0] := 'A<sub>1</sub>' ;
                 ParNames[1] := '<Font face=symbol>t</Font><sub>1</sub>' ;
                 ParNames[2] := 'A<sub>2</sub>' ;
                 ParNames[3] := '<Font face=symbol>t</Font><sub>2</sub>' ;
                 ParNames[4] := 'Ss' ;
                 end ;
          Exponential3 : begin
                 ParNames[0] := 'A<sub>1</sub>' ;
                 ParNames[1] := '<Font face=symbol>t</Font><sub>1</sub>' ;
                 ParNames[2] := 'A<sub>2</sub>' ;
                 ParNames[3] := '<Font face=symbol>t</Font><sub>2</sub>' ;
                 ParNames[4] := 'A<sub>3</sub>' ;
                 ParNames[5] := '<Font face=symbol>t</Font><sub>3</sub>' ;
                 ParNames[6] := 'Ss' ;
                 end ;
          EPC : begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := 'x<sub>0' ;
                 ParNames[2] := '<Font face=symbol>t</Font><sub>R</sub>' ;
                 ParNames[3] := '<Font face=symbol>t</Font><sub>D</sub>' ;
                 end ;
          HHK : begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := '<Font face=symbol>t</Font><sub>M</sub>' ;
                 ParNames[2] := 'P' ;
                 end ;
          HHNa : begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := '<Font face=symbol>t</Font><sub>M</sub>' ;
                 ParNames[2] := 'P' ;
                 ParNames[3] := 'H<sub>inf</sub>' ;
                 ParNames[4] := '<Font face=symbol>t</Font><sub>H</sub>' ;
                 end ;
          MEPCNoise : begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := 'F<sub>d</sub>' ;
                 ParNames[2] := 'F<sub>r</sub>' ;
                 end ;
          Gaussian : begin
                 ParNames[0] := '<Font face=symbol>m</Font>' ;
                 ParNames[1] := '<Font face=symbol>s</Font>' ;
                 ParNames[2] := 'Peak' ;
                 end ;
          Gaussian2 : begin
                 ParNames[0] := '<Font face=symbol>m</Font><sub>1</sub>' ;
                 ParNames[1] := '<Font face=symbol>s</Font><sub>1</sub>' ;
                 ParNames[2] := 'Pk<sub>1</sub>' ;
                 ParNames[3] := '<Font face=symbol>m</Font><sub>2</sub>' ;
                 ParNames[4] := '<Font face=symbol>s</Font><sub>2</sub>' ;
                 ParNames[5] := 'Pk<sub>2</sub>' ;
                 end ;
          Gaussian3 : begin
                 ParNames[0] := '<Font face=symbol>m</Font><sub>1</sub>' ;
                 ParNames[1] := '<Font face=symbol>s</Font><sub>1</sub>' ;
                 ParNames[2] := 'Pk<sub>1</sub>' ;
                 ParNames[3] := '<Font face=symbol>m</Font><sub>2</sub>' ;
                 ParNames[4] := '<Font face=symbol>s</Font><sub>2</sub>' ;
                 ParNames[5] := 'Pk<sub>2</sub>' ;
                 ParNames[6] := '<Font face=symbol>m</Font><sub>3</sub>' ;
                 ParNames[7] := '<Font face=symbol>s</Font><sub>3</sub>' ;
                 ParNames[8] := 'Pk<sub>3</sub>' ;
                 end ;

          PDFExp : PDFExpNames( ParNames, 1 ) ;

          PDFExp2 : PDFExpNames( ParNames, 2 ) ;

          PDFExp3 : PDFExpNames( ParNames, 3 ) ;

          PDFExp4 : PDFExpNames( ParNames, 4 ) ;

          PDFExp5 : PDFExpNames( ParNames, 5 ) ;

          Quadratic : begin
                 ParNames[0] := 'C' ;
                 ParNames[1] := 'B' ;
                 ParNames[2] := 'A' ;
                 end ;
          Cubic : begin
                 ParNames[0] := 'D' ;
                 ParNames[1] := 'C' ;
                 ParNames[2] := 'B' ;
                 ParNames[3] := 'A' ;
                 end ;

          DecayingExp : begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := '<Font face=symbol>t</Font>' ;
                 end ;
          DecayingExp2 : begin
                 ParNames[0] := 'A<sub>1</sub>' ;
                 ParNames[1] := '<Font face=symbol>t</Font><sub>1</sub>' ;
                 ParNames[2] := 'A<sub>2</sub>' ;
                 ParNames[3] := '<Font face=symbol>t</Font><sub>2</sub>' ;
                 end ;
          DecayingExp3 : begin
                 ParNames[0] := 'A<sub>1</sub>' ;
                 ParNames[1] := '<Font face=symbol>t</Font><sub>1</sub>' ;
                 ParNames[2] := 'A<sub>2</sub>' ;
                 ParNames[3] := '<Font face=symbol>t</Font><sub>2</sub>' ;
                 ParNames[4] := 'A<sub>3</sub>' ;
                 ParNames[5] := '<Font face=symbol>t</Font><sub>3</sub>' ;
                 end ;

          Boltzmann : begin
                 ParNames[0] := 'y<sub>max</sub>' ;
                 ParNames[1] := 'x<sub>1</sub>^-/<sub>2</sub>' ;
                 ParNames[2] := 'x<sub>slp</sub>' ;
                 ParNames[3] := 'y<sub>min</sub>' ;
                 end ;

          PowerFunc : Begin
                 ParNames[0] := 'A' ;
                 ParNames[1] := 'B' ;
                 end ;

          else begin
               end ;
          end ;
     if (Index >= 0) and (Index < GetNumParameters) then begin
        Result := ParNames[Index] ;
        end
     else Result := '?' ;
     end ;


procedure TCurveFitter.PDFExpNames
(
          var ParNames : Array of String ;
          nExp : Integer ) ;
{ --------------------------------
  Exponential PDF parameter names
  -------------------------------- }
var
   i : Integer ;
begin
     for i := 0 to nExp-1 do begin
         ParNames[2*i] := format('A<sub>%d</sub>',[i+1]) ;
         ParNames[2*i+1] := format('<Font face=symbol>t</Font><sub>%d</sub>',[i+1]) ;
         end ;
     end ;


function TCurveFitter.GetParUnits(
         Index : Integer  { Parameter index number (IN) }
         ) : string ;
{ ---------------------------
  Get the units of a parameter
  ---------------------------}
var
   ParUnits : Array[0..LastParameter] of string ;
begin
     Case FEqnType of
          Lorentzian : begin
                 ParUnits[0] := FYUnits + '<sup>2</sup>' ;
                 ParUnits[1] := FXUnits  ;
                 end ;
          Lorentzian2 : begin
                 ParUnits[0] := FYUnits + '<sup>2</sup>';
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits + '<sup>2</sup>';
                 ParUnits[3] := FXUnits  ;
                 end ;
          LorAndOneOverF : begin
                 ParUnits[0] := FYUnits + '<sup>2</sup>';
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits + '<sup>2</sup>';
                 end ;
          Linear : begin
                 ParUnits[0] := FYUnits  ;
                 ParUnits[1] := FYUnits + '/' + FXUnits ;
                 end ;
          Parabola : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := ' ' ;
                 ParUnits[2] := FYUnits ;
                 end ;
          Exponential : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 end ;
          Exponential2 : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 ParUnits[3] := FXUnits  ;
                 ParUnits[4] := FYUnits ;
                 end ;
          Exponential3 : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 ParUnits[3] := FXUnits  ;
                 ParUnits[4] := FYUnits  ;
                 ParUnits[5] := FXUnits ;
                 ParUnits[6] := FYUnits ;
                 end ;
          EPC : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits ;
                 ParUnits[2] := FXUnits ;
                 ParUnits[3] := FXUnits ;
                 end ;
          HHK : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits ;
                 ParUnits[2] := '' ;
                 end ;
          HHNa : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits ;
                 ParUnits[2] := '' ;
                 ParUnits[3] := '' ;
                 ParUnits[4] := FXUnits ;
                 end ;
          MEPCNoise : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FXUnits ;
                 end ;
          Gaussian : begin
                 ParUnits[0] := FXUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 end ;
          Gaussian2 : begin
                 ParUnits[0] := FXUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 ParUnits[3] := FXUnits ;
                 ParUnits[4] := FXUnits  ;
                 ParUnits[5] := FYUnits ;
                 end ;
          Gaussian3 : begin
                 ParUnits[0] := FXUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 ParUnits[3] := FXUnits ;
                 ParUnits[4] := FXUnits  ;
                 ParUnits[5] := FYUnits ;
                 ParUnits[6] := FXUnits ;
                 ParUnits[7] := FXUnits  ;
                 ParUnits[8] := FYUnits ;
                 end ;

          PDFExp : PDFExpUnits( ParUnits, FXUnits, 1 ) ;

          PDFExp2 : PDFExpUnits( ParUnits, FXUnits, 2 ) ;

          PDFExp3 : PDFExpUnits( ParUnits, FXUnits, 3 ) ;

          PDFExp4 : PDFExpUnits( ParUnits, FXUnits, 4 ) ;

          PDFExp5 : PDFExpUnits( ParUnits, FXUnits, 5 ) ;

          Quadratic : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FYUnits + '/' + FXUnits ;
                 ParUnits[2] := FYUnits + '/' + FXUnits + '<sup>2</sup>';
                 end ;

          Cubic : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FYUnits + '/' + FXUnits ;
                 ParUnits[2] := FYUnits + '/' + FXUnits + '<sup>2</sup>';
                 ParUnits[3] := FYUnits + '/' + FXUnits + '^3';
                 end ;

          DecayingExp : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 end ;

          DecayingExp2 : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 ParUnits[3] := FXUnits  ;
                 end ;

          DecayingExp3 : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FYUnits ;
                 ParUnits[3] := FXUnits  ;
                 ParUnits[4] := FYUnits  ;
                 ParUnits[5] := FXUnits ;
                 end ;

          Boltzmann : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 ParUnits[2] := FXUnits ;
                 ParUnits[3] := FYUnits  ;
                 end ;

          PowerFunc : begin
                 ParUnits[0] := FYUnits ;
                 ParUnits[1] := FXUnits  ;
                 end ;

          else begin
               end ;
          end ;
     if (Index >= 0) and (Index < GetNumParameters) then begin
        Result := ParUnits[Index] ;
        end
     else Result := '?' ;
     end ;


procedure TCurveFitter.PDFExpUnits(
          var ParUnits : Array of String ;
          FXUnits : String ;
          nExp : Integer ) ;
{ --------------------------------
  Exponential PDF parameter units
  -------------------------------- }
var
   i : Integer ;
begin
     for i := 0 to nExp-1 do begin
         ParUnits[2*i] := '%' ;
         ParUnits[2*i+1] := FXUnits ;
         end ;
     end ;


Function TCurveFitter.EquationValue(
         X : Single                   { X (IN) }
         ) : Single ;                 { Return f(X) }
{ ---------------------------------------------------
  Return value of equation with current parameter set
  ---------------------------------------------------}
var
   Y,A,A1,A2,Theta1,Theta2 : Single ;
   Area,Tau,Area1,Tau1,Area2,Tau2,Area3,Tau3 : single ;
begin

     Case FEqnType of

          Lorentzian : begin
             if Pars[1] <> 0.0 then begin
                A := X/Pars[1] ;
                Y := Pars[0] /( 1.0 + (A*A)) ;
                end
             else Y := 0.0 ;
             end ;

          Lorentzian2 : begin
             if (Pars[1] <> 0.0) and (Pars[3] <> 0.0)then begin
                A1 := X/Pars[1] ;
                A2 := X/Pars[3] ;
                Y := (Pars[0]/(1.0 + (A1*A1)))
                     + (Pars[2]/(1.0 + (A2*A2))) ;
                end
             else Y := 0.0 ;
             end ;

          LorAndOneOverF : begin
             if Pars[1] <> 0.0 then begin
                A := X/Pars[1] ;
                Y := (Pars[0] /( 1.0 + (A*A)))
                     + (Pars[2]/(X*X));
                end
             else Y := 0.0 ;
             end ;

          Linear : begin
             Y := Pars[0] + X*Pars[1] ;
             end ;

          Parabola : begin
             if Pars[1] <> 0.0 then begin
                Y :=  X*Pars[0]
                      - ((X*X)/Pars[1]) + Pars[2] ;
                end
             else Y := 0.0 ;
             end ;

          Exponential : begin
             Y := Pars[2] ;
             if Pars[1] <> 0.0 then Y := Y + Pars[0]*exp(-X/Abs(Pars[1])) ;
             end ;

          Exponential2 : begin
             Y := Pars[4];
             if Pars[1] <> 0.0 then Y := Y + Pars[0]*exp(-X/Abs(Pars[1])) ;
             if Pars[3] <> 0.0 then Y := Y + Pars[2]*exp(-X/Abs(Pars[3])) ;
             end ;

          Exponential3 : begin
             Y := Pars[6];
             if Pars[1] <> 0.0 then Y := Y + Pars[0]*exp(-X/Abs(Pars[1])) ;
             if Pars[3] <> 0.0 then Y := Y + Pars[2]*exp(-X/Abs(Pars[3])) ;
             if Pars[5] <> 0.0 then Y := Y + Pars[4]*exp(-X/Abs(Pars[5])) ;
             end ;

          EPC : begin
             if (Pars[2] <> 0.0) and (Pars[3] <> 0.0) then
                Y := Pars[0]*0.5*(1. + erf( (X-Pars[1])/Abs(Pars[2]) ))
                     *exp(-(X-Pars[1])/Abs(Pars[3]))
             else Y := 0.0 ;
             end ;

          HHK : begin
             if Pars[1] <> 0.0 then
                Y := Pars[0]*FPower( 1. - exp(-x/Abs(Pars[1])),Abs(Pars[2]) )
             else Y := 0.0 ;
             end ;

          HHNa : begin
             if (Pars[1] <> 0.0) and (Pars[4] <> 0.0) then
                Y := (Pars[0]*FPower( 1. - exp(-x/Abs(Pars[1])),Abs(Pars[2]) )) *
                     (Abs(Pars[3]) - (Abs(Pars[3]) - 1. )*exp(-x/Abs(Pars[4])) )
             else Y := 0.0 ;
             end ;

          MEPCNoise : begin
             if (Pars[1] <> 0.0) and (Pars[2] <> 0.0) then begin
                Theta2 := 1.0 / Pars[1] ;
                Theta1 := 1.0 / Pars[2] ;
                Y := (Pars[0]) /
                     (1.0 + (X*X*(Theta1*Theta1 + Theta2*Theta2))
                     + (X*X*X*X*Theta1*Theta1*Theta2*Theta2) ) ;
                end
             else Y := 0.0 ;
             end ;

          Gaussian : Y := GaussianFunc( Pars, 1, X ) ;
          Gaussian2 : Y := GaussianFunc( Pars, 2, X ) ;
          Gaussian3 : Y := GaussianFunc( Pars, 3, X ) ;

          PDFExp : Y := PDFExpFunc( Pars, 1, X ) ;
          PDFExp2 : Y := PDFExpFunc( Pars, 2, X ) ;
          PDFExp3 : Y := PDFExpFunc( Pars, 3, X ) ;
          PDFExp4 : Y := PDFExpFunc( Pars, 4, X ) ;
          PDFExp5 : Y := PDFExpFunc( Pars, 5, X ) ;

          Quadratic : begin
             Y := Pars[0] + X*Pars[1] + X*X*Pars[2] ;
             end ;
          Cubic : begin
             Y := Pars[0] + X*Pars[1] + X*X*Pars[2] + X*X*X*Pars[3] ;
             end ;

          DecayingExp : begin
             Y := 0.0 ;
             if Pars[1] <> 0.0 then Y := Y + Pars[0]*exp(-X/Abs(Pars[1])) ;
             end ;

          DecayingExp2 : begin
             Y := 0.0 ;
             if Pars[1] <> 0.0 then Y := Pars[0]*exp(-X/Abs(Pars[1])) ;
             if Pars[3] <> 0.0 then Y := Y + Pars[2]*exp(-X/Abs(Pars[3])) ;
             end ;

          DecayingExp3 : begin
             Y := 0.0 ;
             if Pars[1] <> 0.0 then Y := Y + Pars[0]*exp(-X/Abs(Pars[1])) ;
             if Pars[3] <> 0.0 then Y := Y + Pars[2]*exp(-X/Abs(Pars[3])) ;
             if Pars[5] <> 0.0 then Y := Y + Pars[4]*exp(-X/Abs(Pars[5])) ;
             end ;

          Boltzmann : begin
             if Pars[2] <> 0.0 then
                Y := Pars[0] / ( 1.0 + exp( -(X - pars[1])/Pars[2])) + Pars[3]
             else Y := 0.0 ;
             end ;

          PowerFunc : Begin
             Y := Pars[0]*FPower(x,Pars[1]) ;
             end ;

          else Y := 0. ;
          end ;

     Result := Y ;
     end ;


function TCurveFitter.PDFExpFunc(
         Pars : Array of single ;
         nExp : Integer ;
         X : Single ) : Single ;
{ ------------------------------------
  General exponential p.d.f. function
  ------------------------------------ }
var
   i,j : Integer ;
   y : Single ;
begin
     y := 0.0 ;
     for i := 0 to nExp-1 do begin
         j := 2*i ;
         if Pars[j+1] > 0.0 then y := y + Pars[j]/Pars[j+1]*SafeExp(-X/pars[j+1]) ;
         end ;
     Result := y ;
     end ;


function TCurveFitter.GaussianFunc(
         Pars : Array of single ;
         nGaus : Integer ;
         X : Single ) : Single ;
{ -------------------
  Gaussian function
  ------------------- }
var
   i,j : Integer ;
   z,Variance,y : Single ;
begin

     Y := 0.0 ;
     for i := 0 to nGaus-1 do begin
         j := 3*i ;
         z := X - Pars[j] ;
         Variance := Pars[j+1]*Pars[j+1] ;
         if Variance > 0.0 then Y := Y + Pars[j+2]*Exp( -(z*z)/(2.0*Variance) ) ;
         end ;
     Result := y ;
     end ;


procedure TCurveFitter.SetupNormalisation(
          xScale : single ;
          yScale : single
          ) ;
{ --------------------------------------------------------
  Determine scaling factors necessary to adjust parameters
  for data normalised to range 0-1
  --------------------------------------------------------}
begin

     { Scaling factor for residual standard deviation }
     ResidualSDScaleFactor := yScale ;

    { Set values for each equation type }
     Case FEqnType of
          Lorentzian : begin
                 AbsPars[0] := True ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;
                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;
                 end ;
          Lorentzian2 : begin
                 AbsPars[0] := True ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;
                 end ;
           LorAndOneOverF : begin
                 AbsPars[0] := True ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;
                 end ;
           Linear : begin

                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := False ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := yScale/xScale ;

                 end ;
           Parabola : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale/xScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := (xScale*xScale)/yScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;
                 end ;

           Exponential : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;
                 end ;

           Exponential2 : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;

                 AbsPars[4] := False ;
                 LogPars[4] := False ;
                 ParameterScaleFactors[4] := yScale ;
                 end ;

           Exponential3 : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;

                 AbsPars[4] := False ;
                 LogPars[4] := False ;
                 ParameterScaleFactors[4] := yScale ;

                 AbsPars[5] := True ;
                 LogPars[5] := False ;
                 ParameterScaleFactors[5] := xScale ;

                 AbsPars[6] := False ;
                 LogPars[6] := False ;
                 ParameterScaleFactors[6] := yScale ;
                 end ;

          EPC : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := False ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := xScale ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;
                 end ;

          HHK : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := 1. ;
                 end ;

          HHNa : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := 1. ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := 1. ;

                 AbsPars[4] := True ;
                 LogPars[4] := False ;
                 ParameterScaleFactors[4] := xScale ;
                 end ;

          MEPCNoise : begin
                 AbsPars[0] := True ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := xScale ;
                 end ;
          Gaussian : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := xScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;
                 end ;
          Gaussian2 : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := xScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := False ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;

                 AbsPars[4] := True ;
                 LogPars[4] := False ;
                 ParameterScaleFactors[4] := xScale ;

                 AbsPars[5] := True ;
                 LogPars[5] := False ;
                 ParameterScaleFactors[5] := yScale ;
                 end ;

          Gaussian3 : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := xScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := True ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := False ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;

                 AbsPars[4] := True ;
                 LogPars[4] := False ;
                 ParameterScaleFactors[4] := xScale ;

                 AbsPars[5] := True ;
                 LogPars[5] := False ;
                 ParameterScaleFactors[5] := yScale ;

                 AbsPars[6] := False ;
                 LogPars[6] := False ;
                 ParameterScaleFactors[6] := xScale ;

                 AbsPars[7] := True ;
                 LogPars[7] := False ;
                 ParameterScaleFactors[7] := xScale ;

                 AbsPars[8] := True ;
                 LogPars[8] := False ;
                 ParameterScaleFactors[8] := yScale ;
                 end ;

          PDFExp : PDFExpScaling(AbsPars,LogPars,ParameterScaleFactors,yScale,1) ;
          PDFExp2 : PDFExpScaling(AbsPars,LogPars,ParameterScaleFactors,yScale,2) ;
          PDFExp3 : PDFExpScaling(AbsPars,LogPars,ParameterScaleFactors,yScale,3) ;
          PDFExp4 : PDFExpScaling(AbsPars,LogPars,ParameterScaleFactors,yScale,4) ;
          PDFExp5 : PDFExpScaling(AbsPars,LogPars,ParameterScaleFactors,yScale,5) ;

           Quadratic : begin

                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := False ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := yScale/xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale/(xScale*xScale) ;
                 end ;

           Cubic : begin

                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := False ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := yScale/xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale/(xScale*xScale) ;

                 AbsPars[3] := False ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := yScale/(xScale*xScale*xScale) ;

                 end ;

           DecayingExp : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 end ;

           DecayingExp2 : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;

                 end ;

           DecayingExp3 : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := True ;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := yScale ;

                 AbsPars[3] := True ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := xScale ;

                 AbsPars[4] := False ;
                 LogPars[4] := False ;
                 ParameterScaleFactors[4] := yScale ;

                 AbsPars[5] := True ;
                 LogPars[5] := False ;
                 ParameterScaleFactors[5] := xScale ;

                 end ;

           Boltzmann : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := False;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := xScale ;

                 AbsPars[2] := False ;
                 LogPars[2] := False ;
                 ParameterScaleFactors[2] := xScale ;

                 AbsPars[3] := False ;
                 LogPars[3] := False ;
                 ParameterScaleFactors[3] := yScale ;

                 end ;

           PowerFunc : begin
                 AbsPars[0] := False ;
                 LogPars[0] := False ;
                 ParameterScaleFactors[0] := yScale ;

                 AbsPars[1] := False;
                 LogPars[1] := False ;
                 ParameterScaleFactors[1] := 1.0 ;
                 end ;

          end ;

     Normalised := True ;
     end ;


procedure TCurveFitter.PDFExpScaling(
          var AbsPars : Array of Boolean ;
          var LogPars : Array of Boolean ;
          var ParameterScaleFactors : Array of Single ;
          yScale : Single ;
          nExp : Integer ) ;
{ --------------------------------
  Exponential PDF scaling factors
  ------------------------------- }
var
   i,j : Integer ;
begin
     for i := 0 to nExp-1 do begin
         j := 2*i ;
         AbsPars[j] := True ;
         LogPars[j] := False ;
         ParameterScaleFactors[j] := yScale ;
         AbsPars[j+1] := false ;
         LogPars[j+1] := true ;
         ParameterScaleFactors[j+1] := 1.0 ;
         end ;
     end ;


function TCurveFitter.NormaliseParameter(
         Index : Integer ;           { Parameter Index (IN) }
         Value : single              { Parameter value (IN) }
         ) : single ;
{ -----------------------------------------------------------------
  Adjust a parameter to account for data normalisation to 0-1 range
  -----------------------------------------------------------------}
var
   NormValue : single ;
begin
     if (Index >= 0) and (Index<GetNumParameters) and Normalised then begin
        NormValue := Value * ParameterScaleFactors[Index] ;
        if AbsPars[Index] then NormValue := Abs(NormValue) ;
        if LogPars[Index] then NormValue := ln(NormValue) ;
        Result := NormValue ;
        end
     else Result := Value ; ;
     end ;


function TCurveFitter.DenormaliseParameter(
         Index : Integer ;           { Parameter Index (IN) }
         Value : single              { Parameter value (IN) }
         ) : single ;
{ ----------------------------------------
  Restore a parameter to actual data range
  ----------------------------------------}
var
   NormValue : single ;
begin
     if (Index >= 0) and (Index<GetNumParameters) and Normalised then begin
        NormValue := Value / ParameterScaleFactors[Index] ;
        if AbsPars[Index] then NormValue := Abs(NormValue) ;
        if LogPars[Index] then NormValue := exp(NormValue) ;
        Result := NormValue ;
        end
     else Result := Value ; ;
     end ;


function TCurveFitter.InitialGuess(
         Index : Integer          { Function parameter No. }
         ) : single ;
{ --------------------------------------------------------------
  Make an initial guess at parameter value based upon (X,Y) data
  pairs in Data
  --------------------------------------------------------------}
var
   i,j,iEnd,iY25,iY50,iY75,AtPeak,iBiggest,iStep : Integer ;
   xMin,xMax,yMin,yMax,x,y,yRange,XAtYMax,XAtYMin,Slope,XStart : Single ;
   YSum,XYSum,XMean : single ;
   Guess : Array[0..LastParameter] of single ;
   YPeak : Array[0..6] of single ;
   XStDev : Array[0..6] of single ;
   XAtYPeak : Array[0..6] of single ;
   OnPeak : Boolean ;
   nPeaks : Integer ;
begin

      iEnd := nPoints - 1 ;

      { Find Min./Max. limits of data }
      xMin := MaxSingle ;
      xMax := -xMin ;
      yMin := MaxSingle ;
      yMax := -yMin ;
      for i := 0 to iEnd do begin
         x := XData[i] ;
         y := YData[i] ;
         if xMin > x then xMin := x ;
         if xMax < x then xMax := x ;
         if yMin > y then begin
            yMin := y ;
            XAtYMin := x ;
            end ;
         if yMax < y then begin
            yMax := y ;
            XAtYMax := x ;
            end ;
         end ;

      { Find points which are 75%, 50% and 25% of yMax }
      for i := 0 to iEnd do begin
          y := YData[i] - yMin ;
          yRange := yMax - yMin ;
          if y > (yRange*0.75) then iY75 := i ;
          if y > (yRange*0.5) then iY50 := i ;
          if y > (yRange*0.25) then iY25 := i ;
          end ;

      { Find mean X value weighted by Y values }
      XYSum := 0.0 ;
      YSum := 0.0 ;
      for i := 0 to iEnd do begin
          XYSum := XYSum + YData[i]*XData[i] ;
          YSum := YSum + YData[i] ;
          end ;
      if YSum <> 0.0 then XMean := XYSum / YSum ;

     // Locate peaks and determine peak and width (for gaussian fits)

     nPeaks := 0 ;
     iStep := MaxInt([(iEnd + 1) div 20,1]) ;
     OnPeak := False ;
     for i := 0 to iEnd do begin

         { Get slope of line around data point (i) }
         Slope := YData[MinInt([i+iStep,iEnd])] - YData[MaxInt([i-iStep,0])] ;
         X := XData[i] ;
         Y := YData[i] ;

         // Rising slope of a peak detected when slope > 20% of peak Y value
         if (Slope > YMax*0.2) and (not OnPeak) then begin
            OnPeak := True ;
            YPeak[nPeaks] :=  0.0 ;
            XStart := X ;
            end ;

         // Find location and amplitude of peak
         if OnPeak then begin
            if YPeak[nPeaks] < Y then begin
               YPeak[nPeaks] := Y ;
               XAtYPeak[nPeaks] := X
               end ;
            // End of peak when downward slope > 20% of ma Y value
            if (Slope < (-YMax*0.2)) then begin
               OnPeak := False ;
               XStDev[nPeaks] := X - XStart ;
               nPeaks := MinInt([nPeaks+1,High(YPeak)]) ;
               end ;
            end ;
         end ;

      Case FEqnType of
           Lorentzian : begin
                  Guess[0] := YData[0] ;
                  Guess[1] := XData[iY50] ;
                  end ;
           Lorentzian2 : begin
                  Guess[0] := YData[0] ;
                  Guess[1] := XData[iY75] ;
                  Guess[2] := YData[0]/4.0 ;
                  Guess[3] := XData[iY25] ;
                  end ;
           LorAndOneOverF : begin
                  Guess[0] := YData[0]*0.75 ;
                  Guess[1] := XData[iY50] ;
                  Guess[2] := YData[0]*0.25 ;
                  end ;
           Linear : begin
                  Guess[0] := yMin ;
                  Guess[1] := (yMax - yMin) / (xMax - xMin);
                  end ;
           Parabola : begin
                  Guess[0] := (yMax - yMin) / (xMax - xMin);
                  Guess[1] := Guess[0]*0.1 ;
                  Guess[2] := yMin ;
                  end ;

           Exponential : begin
                  Guess[0] := YData[0] - YData[iEnd] ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 4.0 ;
                  Guess[2] := YData[iEnd] ;
                  end ;

           Exponential2 : begin
                  Guess[0] := YData[0] - YData[iEnd]*0.5 ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 20.0 ;
                  Guess[2] := YData[0] - YData[iEnd]*0.5 ;
                  Guess[3] := (XData[iEnd] - XData[0]) / 2.0 ;
                  Guess[4] := YData[iEnd] ;
                  end ;

           Exponential3 : begin
                  Guess[0] := YData[0] - YData[iEnd]*0.33 ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 20.0 ;
                  Guess[2] := YData[0] - YData[iEnd]*0.33 ;
                  Guess[3] := (XData[iEnd] - XData[0]) / 5.0 ;
                  Guess[4] := YData[0] - YData[iEnd]*0.33 ;
                  Guess[5] := (XData[iEnd] - XData[0]) / 1.0 ;
                  Guess[6] := YData[iEnd] ;
                  end ;

           EPC : begin
                  { Peak amplitude }
                  if Abs(yMax) > Abs(yMin) then begin
                     Guess[0] := yMax ;
                     AtPeak := Round(XAtYmax) ;
                     end
                  else begin
                     Guess[0] := yMin ;
                     AtPeak := Round(XAtYMin) ;
                     end ;
                  { Set initial latency to time of signal peak }
                  Guess[1] := XData[AtPeak] ;
                  { Rising time constant }
                  Guess[2] := (XData[1] - XData[0])*5.0 ;
                  { Decay time constant }
                  Guess[3] := (XData[iEnd] - XData[0]) / 4. ;
                  end ;

           HHK : begin
                  if Abs(yMax) > Abs(yMin) then Guess[0] := yMax
                                           else Guess[0] := yMin ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 6. ;
                  Guess[2] := 2. ;
                  end ;

           HHNa : begin
                  if Abs(yMax) > Abs(yMin) then Guess[0] := yMax
                                           else Guess[0] := yMin ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 10. ;
                  Guess[2] := 3. ;
                  Guess[3] := Abs( YData[iEnd]/Guess[0] ) ;
                  Guess[4] := (XData[iEnd] - XData[0]) / 3. ;
                  end ;

           MEPCNoise : begin
                  Guess[0] := YData[0] ;
                  Guess[1] := XData[iY50] ;
                  Guess[2] := Guess[1]*10.0 ;
                  end ;

           Gaussian : begin
                  iBiggest := 0 ;
                  for i := 0 to nPeaks-1 do if YPeak[i] >= YPeak[iBiggest] then begin
                      iBiggest := i ;
                      Guess[0] := XAtYPeak[i] ;
                      Guess[1] := XStDev[i] ;
                      Guess[2] := YPeak[i] ;
                      end ;
                  end ;

           Gaussian2 : begin
                  for j := 0 to 1 do begin
                      iBiggest := 0 ;
                      for i := 0 to nPeaks-1 do if YPeak[i] >= YPeak[iBiggest] then begin
                          iBiggest := i ;
                          Guess[3*j] := XAtYPeak[i] ;
                          Guess[3*j+1] := XStDev[i] ;
                          Guess[3*j+2] := YPeak[i] ;
                          end ;
                      YPeak[iBiggest] := 0.0 ;
                      end ;
                  end ;

           Gaussian3 : begin
                  for j := 0 to 2 do begin
                      iBiggest := 0 ;
                      for i := 0 to nPeaks-1 do if YPeak[i] >= YPeak[iBiggest] then begin
                          iBiggest := i ;
                          Guess[3*j] := XAtYPeak[i] ;
                          Guess[3*j+1] := XStDev[i] ;
                          Guess[3*j+2] := YPeak[i] ;
                          end ;
                      YPeak[iBiggest] := 0.0 ;
                      end ;
                  end ;
           PDFExp : begin
                  Guess[0] := 100.0 ;
                  Guess[1] := XMean ;
                  end ;
           PDFExp2 : begin
                  Guess[0] := 75.0 ;
                  Guess[1] := XMean*0.3 ;
                  Guess[2] := 25.0 ;
                  Guess[3] := XMean*3.0 ;
                  end ;
           PDFExp3 : begin
                  Guess[0] := 50.0 ;
                  Guess[1] := XMean*0.2 ;
                  Guess[2] := 25.0 ;
                  Guess[3] := XMean*5.0 ;
                  Guess[4] := 25.0 ;
                  Guess[5] := XMean*50.0 ;
                  end ;
           PDFExp4 : begin
                  Guess[0] := 50.0 ;
                  Guess[1] := XMean*0.2 ;
                  Guess[2] := 25.0 ;
                  Guess[3] := XMean*5.0 ;
                  Guess[4] := 15.0 ;
                  Guess[5] := XMean*50.0 ;
                  Guess[6] := 10.0 ;
                  Guess[7] := XMean*200.0 ;
                  end ;

           PDFExp5 : begin
                  Guess[0] := 50.0 ;
                  Guess[1] := XMean*0.2 ;
                  Guess[2] := 25.0 ;
                  Guess[3] := XMean*5.0 ;
                  Guess[4] := 10.0 ;
                  Guess[5] := XMean*50.0 ;
                  Guess[6] := 5.0 ;
                  Guess[7] := XMean*200.0 ;
                  Guess[8] := 5.0 ;
                  Guess[9] := XMean*500.0 ;
                  end ;


           Quadratic : begin
                  Guess[0] := yMin ;
                  Guess[1] := (yMax - yMin) / (xMax - xMin);
                  Guess[2] := Guess[1]*0.1 ;
                  end ;
           Cubic : begin
                  Guess[0] := yMin ;
                  Guess[1] := (yMax - yMin) / (xMax - xMin);
                  Guess[2] := Guess[1]*0.1 ;
                  Guess[3] := Guess[2]*0.1 ;
                  end ;

           DecayingExp : begin
                  Guess[0] := YData[0] - YData[iEnd] ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 4.0 ;
                  end ;

           DecayingExp2 : begin
                  Guess[0] := YData[0] - YData[iEnd]*0.5 ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 20.0 ;
                  Guess[2] := YData[0] - YData[iEnd]*0.5 ;
                  Guess[3] := (XData[iEnd] - XData[0]) / 2.0 ;
                  end ;

           DecayingExp3 : begin
                  Guess[0] := YData[0] - YData[iEnd]*0.33 ;
                  Guess[1] := (XData[iEnd] - XData[0]) / 20.0 ;
                  Guess[2] := YData[0] - YData[iEnd]*0.33 ;
                  Guess[3] := (XData[iEnd] - XData[0]) / 5.0 ;
                  Guess[4] := YData[0] - YData[iEnd]*0.33 ;
                  Guess[5] := (XData[iEnd] - XData[0]) / 1.0 ;
                  end ;

           Boltzmann : begin
                 Guess[0] := YMax - YMin ;
                 Guess[1] := (XMax + XMin) / 2.0 ;
                 Guess[2] := Guess[1]*0.25 ;
                 Guess[3] := YMin ;
                 end ;

           PowerFunc : begin
                 Guess[0] := YData[0] ;
                 if (YData[iEnd] > YData[0]) then Guess[1] := 2.0
                                             else Guess[1] := -2.0 ;
                 end ;
           end ;

      if (Index >= 0) and (Index<GetNumParameters)  then begin
         Result := Guess[Index] ;
         end
      else Result := 1.0 ;
      end ;



procedure TCurveFitter.FitCurve ;
// -----------------------------------
// Find curve which best fits X,Y data
// -----------------------------------
var
   NumSig,nSigSq,iConv,Maxiterations,i : Integer ;
   nVar,nFixed : Integer ;
   SSQ,DeltaMax : Single ;
   F,W : ^TDataArray ;
   sltjj : Array[0..300] of Single ;
   FitPars : TPars ;
begin

     { Create buffers for SSQMIN }
     New(F) ;
     New(W) ;

     try

        { Determine an initial set of parameter guesses }
        if not ParsSet then begin
           for i := 0 to GetNumParameters-1 do if not FixedPars[i] then
               Pars[i] := InitialGuess( i ) ;
           end ;

        { Scale X & Y data into 0-1 numerical range }
        ScaleData ;

        { Re-arrange parameters putting fixed parameters at end of array }
        nVar := 0 ;
        nFixed := GetNumParameters ;
        for i := 0 to GetNumParameters-1 do begin
            if FixedPars[i] then begin
               FitPars.Value[nFixed] := Pars[i] ;
               FitPars.Map[nFixed] := i ;
               Dec(nFixed) ;
               end
            else begin
               Inc(nVar) ;
               FitPars.Value[nVar] := Pars[i] ;
               FitPars.Map[nVar] := i ;
               end ;
            end ;

        { Set weighting array to unity }
        for i := 1 to nPoints do W^[i] := 1. ;

        NumSig := 5 ;
        nSigSq := 5 ;
        deltamax := 1E-16 ;
        maxiterations := 100 ;
        iconv := 0 ;
        if nVar > 0 then begin
           try
              ssqmin ( FitPars , nPoints, nVar, maxiterations,
                       NumSig,NSigSq,DeltaMax,
                       W^,SLTJJ,iConv,IterationsValue,SSQ,F^ )
           except
              { on EOverFlow do MessageDlg( ' Fit abandoned -FP Overflow !',
                                  mtWarning, [mbOK], 0 ) ;
               on EUnderFlow do MessageDlg( ' Fit abandoned -FP Underflow !',
                                  mtWarning, [mbOK], 0 ) ;
               on EZeroDivide do MessageDlg( ' Fit abandoned -FP Zero divide !',
                                  mtWarning, [mbOK], 0 ) ; }
               GoodFitFlag := False ;
               end ;

           { Calculate parameter and residual standard deviations
           (If the fit has been successful) }
           if iConv > 0 then begin
              if nPoints > nVar then begin
                 STAT( nPoints,nVar,F^,YData,W^,SLTJJ,SSQ,
                       FitPars.SD,ResidualSDValue,RValue,FitPars.Value ) ;
                 for i := 1 to nVar do Pars[FitPars.Map[i]] := FitPars.Value[i] ;
                 for i := 1 to nVar do ParSDs[FitPars.Map[i]] := FitPars.SD[i] ;
                 DegreesOfFreedomValue := nPoints-GetNumParameters ;
                 end
              else DegreesOfFreedomValue := 0 ;
               GoodFitFlag := True ;
              ParsSet := False ;
              end
           else GoodFitFlag := False ;
           end
        else GoodFitFlag := True ;

        { Return parameter scaling to normal }
        UnScaleParameters ;




     finally ;

        Dispose(W) ;
        Dispose(F) ;
        end ;

     end ;


procedure TCurveFitter.ScaleData  ;
{ ----------------------------------------------------------
  Scale Y data to lie in same range as X data
  (The iterative fitting routine is more stable when
  the X and Y data do not differ too much in numerical value)
  ----------------------------------------------------------}
var
   i,iEnd : Integer ;
   xMax,yMax,xScale,yScale,x,y,ySum : Single ;
begin

     iEnd := nPoints - 1 ;
     { Find absolute value limits of data }
     xMax := -MaxSingle ;
     yMax := -MaxSingle ;
     ySum := 0.0 ;
     for i := 0 to iEnd do begin
         x := Abs(XData[i]) ;
         y := Abs(YData[i]) ;
         if xMax < x then xMax := x ;
         if yMax < y then yMax := y ;
         ySum := ySum + y ;
         end ;

     {Calc. scaling factor}
     if xMax > 0. then xScale := 1./xMax
                  else xScale := 1. ;
     if yMax > 0. then yScale := 1./yMax
                  else yScale := 1. ;

     { Disable x,y scaling in special case of exponential prob. density functions }
     if (FEqnType = PDFExp) or
        (FEqnType = PDFExp2) or
        (FEqnType = PDFExp3) or
        (FEqnType = PDFExp4) or
        (FEqnType = PDFExp5) then begin
        xScale := 1.0 ;
        yScale := 1.0 ;
        end ;

     { Scale data to lie in same numerical range as X data }
     for i := 0 to iEnd do begin
         XData[i] := xScale * XData[i] ;
         YData[i] := yScale * YData[i] ;
         end ;


     { Set parameter scaling factors which adjust for
       data normalisation to 0-1 range }
     SetupNormalisation( xScale, yScale ) ;

     { Scale equation parameters }
     for i := 0 to GetNumParameters-1 do begin
         Pars[i] := NormaliseParameter(i,Pars[i]) ;
         end ;

     end ;


{ ----------------------------------------------------
  Correct best-fit parameters for effects of Y scaling
  ----------------------------------------------------}
procedure TCurveFitter.UnScaleParameters ;
var
   i : Integer ;
   UpperLimit,LowerLimit : single ;
begin
     for i := 0 to GetNumParameters-1 do begin

         { Don't denormalise a fixed parameter }
         if not FixedPars[i] then begin
            UpperLimit := DenormaliseParameter(i,Pars[i]+ParSDs[i]) ;
            LowerLimit := DenormaliseParameter(i,Pars[i]-ParSDs[i]) ;
            ParSDs[i] := Abs(UpperLimit - LowerLimit)*0.5 ;
            end ;
         { Denormalise parameter }
         Pars[i] := DenormaliseParameter(i,Pars[i]) ;
         end ;

     {Unscale residual standard deviation }
     ResidualSDValue := ResidualSDValue/ResidualSDScaleFactor ;

     end ;


procedure TCurveFitter.SsqMin (
          var Pars : TPars ;
          nPoints,nPars,ItMax,NumSig,NSiqSq : LongInt ;
          Delta : Single ;
          var W,SLTJJ : Array of Single ;
          var ICONV,ITER : LongInt ;
          var SSQ : Single ;
          var F : Array of Single ) ;

{
  SSQMIN routine based on an original FORTRAN routine written by
  Kenneth Brown and modified by S.H. Bryant

C
C       Work buffer structure
C
C      (1+N(N-1)/2)
C      :---------:------N*M----------:-----------:
C      1         JACSS               GRADSS      GRDEND
C
C                :--N--:             :----M------------:---N----:
C                      DELEND        FPLSS             DIAGSS   ENDSS
C                                                                :--->cont.
C                                                                FMNSS
C
C       :-------M------:--N-1---:
C       FMNSS          XBADSS   XBEND
C
C
C
C
C               SSQMIN   ------   VERSION II.
C
C       ORIGINAL SOURCE FOR SSQMIN WAS GIFT FROM K. BROWN, 3/19/76.
C       PROGRAM WAS MODIFIED A FOLLOWS:
C
C       1.      WEIGHTING VECTOR W(1) WAS ADDED SO THAT ALL RESIDUALS
C	EQUAL F(I) * SQRT1(W(I)).
C
C       2.      THE VARIABLE KOUT WHICH INDICATED ON EXIT WHETHER F(I)
C       WAS CALCULATED FROM UPDATED X(J) WAS REMOVED. IN
C       CONDITIONS WHERE KOUT =0 THE NEW F(I)'S AND AN UPDATED
C       SSQ IS OUTPUTTED . SSQ ( SUM WEIGHTED F(I) SQUARED )
C       WAS PUT INTO THE CALL STRING.
C
C       3.      A NEW ARRAY SLTJJ(K) WHICH CONTAINS THE SUPER LOWER
C       TRIANGLE OF JOCOBIAN (TRANSPOSE)*JACOBIAN WAS ADDED TO THE
C       CALL STRING. IT HAS THE SIZE N*(N+1)/2 AND IS USED FOR
C       CALCULATING THE STATSTICS OF THE FIT. STORAGE OF
C       ELEMENTS IS AS FOLLOWS:C(1,1),C(2,1),C(2,2),C(3,2),C(3,3),
C       C(4,1)........
C       NOTE THE AREA WORK (1) THROU WORK (JACM1) IN WHICH SLTJJ
C       IS INITALLY STORED IS WRITTEN OVER (DO 52) IN CHOLESKY
C       AND IS NOT AVAILABLE ON RETURN.
C
C       4.      A BUG DUE TO SUBSCRIPTING W(I) OUT OF BOUNDS WAS
C       CORRECTED IN MAY '79. THE CRITERION FOR SWITCHING FROM
C       FORWARD DIFFERENCES (ISW=1) TO CENTRAL DIFFERENCES
C       (ISW = 2) FOR THE PARTIAL DERIVATIVE ESTIMATES IS SET
C       IN STATEMENT 27 (ERL2.LT.GRCIT).GRCIT IS INITALIZED
C       TO 1.E-3 AS IN ORIGINAL PROGRAM. THE VARIABLE T IN
C       CHOLESKY WAS MADE TT TO AVIOD CONFUSION WITH ARRAY T.
C
C       SSQMIN -- IS A FINITE DIFFERENCE LEVENBERG-MARQUARDT LEAST
C       SQUARES ALGORTHM. GIVEN THE USER SUPPLIED INITIAL
C       ESTIMATE FOR X, SSQMIN FINDS THE MINIMUM OF
C       SUM ((F (X ,....,X ) ) ** 2)   J=1,2,.....M
C              J  1       N   J
C       BY A MODIFICATION OF THE LEVENBERG-MARQUARDT ALGORITHM
C       WHICH INCLUDES INTERNAL SCALING AND ELIMINATES THE
C       NEED FOR EXPLICIT DERIVATIVES. THE F (X ,...,X )
C                           J  1      N
C       CAN BE TAKEN TO BE THE RESIDUALS OBTAINED WHEN FITTING
C       NON-LINEAR MODEL, G, TO DATA Y IN THE LEAST SQUARES
C       SENSE ..., I.E.,TAKE
C               F (X ,...,X ) = G (X ,...,X ) - Y
C                J  1      N     J  1      N
C       REFERENCES:
C
C       BROWN,K.M. AND DENNIS,J.S. DERIVATIVE FREE ANALOGS OF
C       THE LEVENBERG-MARQUARDT AND GAUSS ALGORITHMS FOR
C       NON-LINEAR LEAST SQUARES APPROXIMATION. NUMERISCHE
C       MATHEMATIK 18:289 -297  (1972).
C       BROWN,K.M.  COMPUTER ORIENTED METHODS FOR FITTING
C       TABULAR DATA IN THE LINEAR AND NON-LINEAR LEAST SQUARES
C       SENSE.  TECHNICIAL REPORT NO. 72-13. DEPT..COMPUTER &
C       INFORM. SCIENCES; 114 LIND HALL, UNIVERSITY OF
C       MINNESOTA, MINNEAPOLIS, MINNESOTA  5545.
C
C       PARAMETERS :
C
C       X       REAL ARRAY WITH DIMENSION N.
C               INPUT --- INITIAL ESTIMATES
C               OUTPUT -- VALUES AT MIN (OR FINAL APPROXIMATION)
C
C       M       THE NUMBER OF RESIDUALS (OBSERVATIONS)
C
C       N       THE NUMBER OF UNKNOWN PARAMETERS
C
C       ITMAX   THE MAXIMUM NUMBER OF ITERATIONS TO BE ALLOWED
C               NOTE-- THE MAXIMUM NUMBER OF FUNCTION EVALUATIONS
C               ALLOWED IS ROUGHLY (N+1)*ITMAX  .
C
C       IPRINT  AN OUTPUT PARAMETER. IF IPRINT IS NON ZERO CONTROL
C               IS PASSED ONCE DURING EACH ITERATION TO SUBROUTINE
C               PRNOUT WHICH PRINTS INTERMEDIATE RESULTS (SEE BELOW)
C               IF IPRINT IS ZERO NO CALL IS MADE.
C
C       NUMSIG  FIRST CONVERGENCE CRITERION. CONVERGENCE CONDITION
C               SATISFIED IF ALL COMPONENTS OF TWO SUCCESSIVE
C               ITERATES AGREE TO NUMSIG DIGITS.
C
C       NSIGSQ  SECOND CONVERGENCE CRITERION. CONVERGENCE CONDITIONS
C               SATISFIED IF SUM OF SQUARES OF RESIDUALS FOR TWO
C               SUCCESSIVE ITERATIONS AGREE TO NSIGSQ DIGITS.
C
C       DELTA   THIRD CONVERGENCE CRITERION. CONVERGENCE CONDITIONS
C               SATISFIED IF THE EUCLIDEAN NORM OF THE APPROXIMATE
C               GRADIENT VECTOR IS LESS THAN DELTA.
C
C         ***************  NOTE  ********************************
C
C               THE ITERATION WILL TERMIATE ( CONVERGENCE WILL CONSIDERED
C               ACHIEVED ) IF ANY ONE OF THE THREE CONDITIONS IS SATISFIED.
C
C       RMACH   A REAL ARRAY OF LENGTH TWO WHICH IS DEPENDENT
C               UPON THE MACHINE SIGNIFICANCE;
C               SIG (MAXIMUM NUMBER OF SIGNIFICANT
C               DIGITS ) AND SHOULD BE COMPUTED AS FOLLOWS:
C
C               RMACH(1)= 5.0*10.0 **(-SIG+3)
C               RMACH(2)=10.0 **(-(SIG/2)-1)
C
C          WORK SCRATCH ARRAY OF LENGTH 2*M+(N*(N+2*M+9))/2
C               WHOSE CONTENTS ARE
C
C       1 TO JACM1      N*(N+1)/2       LOWER SUPER TRIANGLE OF
C                               JACOBIAN( TRANSPOSED )
C                               TIMES JACOBIAN
C
C       JACESS TO GRDM1         N*M     JACOBIAN MATRIX
C
C       JACSS TO DELEND         N       DELTA X
C
C       GRADSS TO GRDEND        N       GRADIENT
C
C       GRADSS TO DIAGM1        M       INCREMENTED FUNCTION VECTOR
C
C       DIAGSS TO ENDSS N       SCALING VECTOR
C
C       FMNSS TO XBADSS-1       M       DECREMENTED FUNCTION VECTOR
C
C       XBADSS TO XBEND N       LASTEST SINGULAR POINT
C
C               NOTE:
C               SEVERAL WORDS ARE USED FOR TWO DIFFERENT QUANTITIES (E.G.,
C               JACOBIAN AND DELTA X) SO THEY MAY NOT BE AVAILABLE
C               THROUGHOUT THE PROGRAM.
C
C       W       WEIGHTING VECTOR OF LENGTH M
C
C       SLTJJ   ARRAY OF LENGTH N*(N+1)/2 WHICH CONTAINS THE LOWER SUPER
C               TRIANGLE OF J(TRANS)*J RETAINED FROM WORK(1) THROUGH
C               WORK(JACM1) IN DO 30. ELEMENTS STORED SERIALLY AS C(1,1),
C               C(2,1),C(2,2),C(3,1),C(3,2),...,C(N,N). USED IN STATISTICS
C               SUBROUTINES FOR STANDARD DEVIATIONS AND CORRELATION
C               COEFFICIENTS OF PARAMETERS.
C
C       ICONV   AN INTEGER OUTPUT PARAMETER INDICATING SUCCESSFUL
C               CONVERGENCE OR FAILURE
C
C               .GT.  0  MEANS CONVERGENCE IN ITER ITERATION
C                  =  1  CONVERGENCE BY FIRST CRITERION
C                  =  2  CONVERGENCE BY SECOND CRITERION
C                  =  3  CONVERGENCE BY THIRD CRITERION
C               .EQ.  0  MEANS FAILURE TO CONVERGE IN ITMAX ITERATIONS
C               .EQ. -1  MEANS FAILURE TO CONVERGE IN ITER ITERATIONS
C                BECAUSE OF UNAVOIDABLE SINGULARITY WAS ENCOUNTERED
C
C          ITER AN INTEGER OUTPUT PARAMETER WHOSE VALUE IS THE NUMBER OF
C               ITERATIONS USED. THE NUMBER OF FUNCTION EVALUATIONS USED
C               IS ROUGHLY (N+1)*ITER.
C
C          SSQ  THE SUM OF THE SQUARES OF THE RESIDUALS FOR THE CURRENT
C               X AT RETURN.
C
C          F    A REAL ARRAY OF LENGTH M WHICH CONTAINS THE FINAL VALUE
C               OF THE RESIDUALS (THE F(I)'S) .
C
C
C       EXPLANATION OF PARAMETERS ----
C
C               X       CURRENT X VECTOR
C               N       NUMBER OF UNKNOWNS
C               ICONV   CONVERGENCE INDICATOR (SEE ABOVE)
C               ITER    NUMBER OF THE CURRENT ITERATION
C               SSQ     THE NUMBER OF THE SQUARES OF THE RESIDUALS FOR THE
C               CURRENT X
C               ERL2    THE EUCLICEAN NORM OF THE GRADIENT FOR THE CURRENT X
C               GRAD    THE REAL ARRAY OF LENGTH N CONTAINING THE GRADIENT
C               AT THE CURRENT X
C
C               NOTE ----
C
C               N AND ITER MUST NOT BE CHANGED IN PRNOUT
C               X AND ERL2 SHOULD NOT BE CAPRICIOUSLY CHANGED.
C
C
C
C       S.H. BRYANT ---- REVISION MAY 12, 1979  ----
C
C       DEPARTMENT OF PHARACOLOGY AND CELL BIOPHYSICS,
C       COLLEGE OF MEDICINE,
C       UNIVERSITY OF CINCINNATI,
C       231 BETHESDA AVE.,
C       CINCINNATI,
C       OHIO. 45267.
C       TELEPHONE 513/ 872-5621. }

{       Initialisation }


var
   i,j,jk,k,kk,l,jacss,jacm1,delend,GRADSS,GRDEND,GRDM1,FPLSS,FPLM1 : LongInt ;
   DIAGSS,DIAGM1,ENDSS,FMNSS,XBADSS,XBEND,IBAD,NP1,ISW : LongInt ;
   Iis,JS,LI,Jl,JM,KQ,JK1,LIM,JN,MJ : LongInt ;
   PREC,REL,DTST,DEPS,RELCON,RELSSQ,GCrit,ERL2,RN,OldSSQ,HH,XDABS,ParHold,SUM,TT : Single ;
   RHH,DNORM : Single ;
   Quit,Singular,retry,Converged : Boolean ;
   WorkSpaceSize : Integer ;
   Work : ^TWorkArray ;
begin

{ Set machine precision constants }
      PREC := 0.01 ;
      REL := 0.005 ;
      DTST := SQRT1(PREC) ;
      DEPS := SQRT1(REL) ;

      { Set convergence limits }
    {  RELCON := 10.**(-NUMSIG) ;
      RELSSQ := 10.**(-NSIGSQ) ; }
       RELCON := 1E-4 ;
       RELSSQ := 1E-4 ;

      { Set up pointers into WORK buffer }

        JACSS := 1+(nPars*(nPars+1)) div 2 ;
        JACM1 := JACSS-1 ;
        DELEND := JACM1 + nPars ;
        { Gradient }
        GRADSS := JACSS+nPars*nPoints ;
        GRDM1 := GRADSS-1 ;
        GRDEND := GRDM1 + nPars ;
        { Forward trial residuals }
        FPLSS := GRADSS ;
        FPLM1 := FPLSS-1 ;
        { Diagonal elements of Jacobian }
        DIAGSS := FPLSS + nPoints ;
        DIAGM1 := DIAGSS - 1 ;
        ENDSS := DIAGM1 + nPars ;
        { Reverse trial residuals }
        FMNSS := ENDSS + 1 ;
        XBADSS := FMNSS + nPoints ;
        XBEND := XBADSS + nPars - 1 ;
        ICONV := -5 ;
        ERL2 := 1.E35 ;
        GCRIT := 1.E-3 ;
        IBAD := -99 ;
        RN := 1. / nPars ;
        NP1 := nPars + 1 ;
        ISW := 1 ;
        ITER := 1 ;

        // Allocate work buffer
        WorkSpaceSize := ((2*nPoints) + (nPars*(nPars+2*nPoints+9)) div 2)*4 ;
        GetMem( Work, WorkSpaceSize ) ;

        { Iterative loop to find best fit parameter values }

        Quit := False ;
        While Not Quit do begin

            { Compute sum of squares
              SSQ :=  W * (Ydata - Yfunction)*(Ydata - Yfunction) }
            SSQ := SSQCAL(Pars,nPoints,nPars,F,1,W) ;

            { Convergence test - 2 Sum of squares nPointsatch to NSIGSQ figures }
            IF ITER <> 1 then begin {125}
                 IF ABS(SSQ-OLDSSQ) <= (RELSSQ*MaxFlt([ 0.5,SSQ])) then begin
                       ICONV := 2 ;
                       break ;
                       end ;
                 end ;
            OLDSSQ := SSQ ;{125}

            { Compute trial residuals by incrementing
              and decrementing X(j) by HH j := 1...N
              R  :=  Zi (Y(i) - Yfunc(i)) i := 1...M }
            K := JACM1 ;
            for J := 1 to nPars do begin

                  { Compute size of increment in parameter }
                  XDABS := ABS(Pars.Value[J]) ;
                  HH := REL*XDABS ;
                  if ISW = 2 then HH := HH*1.E3 ;
                  if HH <= PREC then HH := PREC ;

                  { Compute forward residuals Rf  :=  X(J)+dX(J) }
                  ParHold := Pars.Value[J] ;
                  Pars.Value[j] := Pars.Value[j] + HH ;
                  FITFUNC(Pars, nPoints, nPars, Work^,FPLSS) ;
                  Pars.Value[j] := ParHold ;

                  { ISW = 1 then skip reverse residuals }
                  IF ISW <> 1 then begin {GO TO 16 }
                         { Compute reverse residual Rr  :=  Pars[j]  -  dPars[j] }
                       Pars.Value[j] := ParHold - HH ;
                       FITFUNC(Pars, nPoints, nPars, Work^,FMNSS ) ;
                       Pars.Value[j] := ParHold ;

                       { Compute gradients (Central differences)
                       Store in JACSS  -  GRDM1
 		       SQRT1(W(j))(Rf(j)  -  Rr)j))/2HH
                       for j := 1..M and  X(i) i := 1..N }

                       L := ENDSS ;
                       RHH := 0.5/HH ;
                       KK := 0 ;
                       for I := FPLSS to DIAGM1 do begin
                           L := L + 1 ;
                           K := K + 1 ;
                           KK := KK + 1 ;
			   Work^[K] := SQRT1(W[KK])*(Work^[I] - Work^[L])*RHH ;
                           end ;
                       end
                  else begin
                        { 16 }
                       { Case of no reverse residuals
                       Forward difference
                       G := SQRT1(W(j)(Rf(j)  -  Ro(j))/HH
                       j := 1..M X(i) i := 1..N }

                       L := FPLM1 ;
                       RHH := 1./HH ;
                       for I := 1 to nPoints do begin
                           K := K + 1 ;
                           L := L + 1 ;
			   Work^[K] := (SQRT1(W[I])*Work^[L] - F[I])*RHH ;
                           end ;
                       end ;
                  end ;
        {20 }
{22      CONTINUE}

{C
C       G2 :=  Z W(j)* ((Rf(j) - Rr(j))/2HH) * Ro(j)
C          j := 1..M
C
C       ERL2  :=  Z G2
C          i := 1..N
C }
            ERL2 := 0. ;
            K := JACM1 ;
            for I := GRADSS to GRDEND do begin
                  SUM := 0. ;
                  for  J := 1 to nPoints do begin
                        K := K + 1 ;
                        SUM := SUM + Work^[K]*F[J] ;
                        end ;
                  Work^[I] := SUM ;
                  ERL2 := ERL2 + SUM*SUM ;
                  end ;

            ERL2 := SQRT1(ERL2) ;

            { Convergence test - 3 Euclidian norm < DELTA }
            IF(ERL2 <= DELTA) then begin
                 ICONV := 3 ;
                 break ;
                 end ;
            IF(ERL2 < GCRIT) then ISW := 2 ;

            { Compute summed cross - products of residual gradients
              Sik  :=  Z Gi(j) * Gk(j)   (i,k := 1...N)
             j := 1...M S11,S12,S22,S13,S23,S33,..... }
            repeat
                  Retry := False ;
                  L := 0 ;
                  Iis := JACM1 - nPoints ;
                  for I := 1 to nPars do begin
                      Iis := Iis + nPoints ;
                      JS := JACM1 ;
                      for J := 1 to I do begin
                          L := L + 1 ;
                          SUM := 0. ;
                          for K := 1 to nPoints do begin
                                LI := Iis + K ;
                                JS := JS + 1 ;
                                SUM := SUM + Work^[LI]*Work^[JS] ;
                                end ;
                          SLTJJ[L] := SUM ;
                          Work^[L] := SUM ;
                          end ;
                      end ;

                  { Compute normalised diagonal matrix
                   SQRT1(Sii)/( SQRT1(Zi (Sii)**2) ) i := 1..N }

                  L := 0 ;
                  J := 0 ;
                  DNORM := 0. ;
                  for I := DIAGSS to ENDSS do begin {34}
                      J := J + 1 ;
                      L := L + J ;
                      Work^[I] := SQRT1(Work^[L]) ;
                      DNORM := DNORM + Work^[L]*Work^[L] ;
                      end ;
                  DNORM := 1./SQRT1(MinFlt([DNORM,3.4E38])) ;
                  for I := DIAGSS to ENDSS do Work^[I] := Work^[I]*DNORM ;

                  { Add ERL2 * Nii i := 1..N
                    Diagonal elements of summed cross - products }

                  L := 0 ;
                  K := 0 ;
                  for J := DIAGSS to ENDSS do begin
                      K := K + 1 ;
                      L := L + K ;
                      Work^[L] := Work^[L] + ERL2*Work^[J] ;
                      IF(IBAD > 0) then Work^[L] := Work^[L]*1.5 + DEPS ;
                      end ;

                  JK := 1 ;
                  Singular := False ;
                  JK1 := 0 ;
                  for I := 1 to nPars do begin {52}
                      JL := JK ;
                      JM := 1 ;
                      for J := 1 to I do begin {52}
                          TT := Work^[JK] ;
                          IF(J <> 1) then begin
                               for K := JL to JK1 do begin
                                   TT := TT - Work^[K]*Work^[JM] ;
                                   JM := JM + 1 ;
                                   end ;
                               end ;
                          IF(I = J) then begin
                               IF (Work^[JK] + TT*RN) <= Work^[JK] then
                                  Singular := True ;{GO TO 76}
		               Work^[JK] := 1./SQRT1(TT) ;
                               end
                          else Work^[JK] := TT*Work^[JM] ;
                          JK1 := JK ;
                          JM := JM + 1 ;
                          JK := JK + 1 ;
                          end ;
                          if Singular then Break ;
                      end ;

                  if Singular then begin

                     { Singularity processing 76 }
                     IF IBAD >= 2 then ReTry := False {GO TO 92}
                     else if iBad < 0 then begin
                          iBad := 0 ;
                          ReTry := True ;
                          {IF(IBAD) 81,78,78 }
                          end
                     else begin
                          J := 0 ; {78}
                          ReTry := False ;
                          for I := XBADSS to XBEND do begin{80}
                              J := J + 1 ;
                              IF(ABS(Pars.Value[j] - Work^[I]) > MaxFlt(
                                          [DTST,ABS(Work^[I])*DTST]) ) then
                                              ReTry := True ;
                              end ; {80}
                          end ;
                     end ;

                  if ReTry then begin
                     J := 0 ; {82}
                     for I := XBADSS to XBEND do begin
                         J := J + 1 ;
                         Work^[I] := Pars.Value[j]
                         end ;
                     IBAD := IBAD + 1 ;
                     end ;
                  until not ReTry ;

            JK := 1 ;
            JL := JACM1 ;
            KQ := GRDM1 ;
            for I := 1 to nPars do begin {60}
                  KQ := KQ + 1 ;
                  TT := Work^[KQ] ;
                  IF JL <> JACM1 then begin
                     JK := JK + JL - 1 - JACM1 ;
                     LIM := I - 1 + JACM1 ;
                     for J := JL to LIM do begin
                         TT := TT - Work^[JK]*Work^[J] ;
                         JK := JK + 1 ;
                         end ;
                     end
                  else begin
                     IF(TT <> 0. ) then JL := JACM1 + I ;
                     JK := JK + I - 1 ;
                     end ;
                  Work^[JACM1 + I] := TT*Work^[JK] ;
                  JK := JK + 1 ;
                  end ; {60}

            for I := 1 to nPars do begin{66}
                  J := NP1 - I + JACM1 ;
                  JK := JK - 1 ;
                  JM := JK ;
                  JN := NP1 - I + 1 ;
                  TT := Work^[J] ;
                  IF (nPars >= JN) then begin {GO TO 64}
                     LI := nPars + JACM1 ;
                     for MJ := JN to nPars do begin
                         TT := TT - Work^[JM]*Work^[LI] ;
                         LI := LI - 1 ;
                         JM := JM - LI + JACM1 ;
                         end ;
                     end ; {64}
                  Work^[J] := TT*Work^[JM] ;
                  end ; {66}

            IF (IBAD <>  - 99 ) then IBAD := 0 ;
            J := JACM1 ;
            for I := 1 to nPars do begin {68}
                  J := J + 1 ;
                  Pars.Value[I] := Pars.Value[I] - Work^[J] ;
                  end ; {68}

            { Convergence condition  -  1
             Xnew  :=  Xold to NUMSIG places 5E - 20 V1.1 .5 in V1. }
            Converged := True ;
            J := JACM1 ;
            for I := 1 to nPars do begin {70}
                  J := J + 1 ;
                  IF ABS(Work^[J]) > (RELCON*MaXFlt([0.5,ABS(Pars.Value[I])])) then
                                  Converged := False ;
                  end ;

            if Converged then begin
                 ICONV := 1 ;
                 Quit := True ;
                 end ;

            ITER := ITER + 1 ;
            IF (ITER > ITMAX) then Quit := True ;
            end ;

        SSQ := SSQCAL(Pars,nPoints,nPars,F,1,W) ;
        Dispose(Work) ;
        end ;


function TCurveFitter.SSQCAL(
         const Pars : TPars ;
         nPoints : Integer ;
         nPars : Integer ;
         var Residuals : Array of Single ;
         iStart : Integer ;
         const W : Array of Single
         ) : Single ;

       { Compute sum of squares of residuals }
       { Enter with :
         Pars = Array of function parameters
         nPoints = Number of data points to be fitted
         nPars = Number of parameters in Pars
         Residuals = array of residual differences
         W = array of weights
         }
var
   I : LongInt ;
   SSQ : single ;
begin

	  FitFunc(Pars,nPoints,nPars,Residuals,iStart ) ;

    SSQ := 0. ;
    for I := 1 to nPoints do begin
        Residuals[I] := SQRT1(W[I])*Residuals[iStart+I-1] ;
        SSQ := SSQ + Sqr(Residuals[iStart+I-1]) ;
        end ;
    SSQCAL := SSQ ;
    end ;


procedure TCurveFitter.FitFunc(
          Const FitPars :TPars ;
          nPoints : Integer ;
          nPars : Integer ;
          Var Residuals : Array of Single ;
          iStart : Integer
          ) ;
var
   i : Integer ;
begin

     { Un-map parameters from compressed array to normal }
     for i := 1 to nPars do Pars[FitPars.Map[i]] := FitPars.Value[i] ;
     { Convert log-transformed parameters to normal }
     for i := 0 to nPars-1 do if LogPars[i] then Pars[i] := Exp(Pars[i]) ;

     if UseBinWidthsFlag then begin
        { Apply bin width multiplier when fitting probability density
          functions to histograms }
        for i := 0 to nPoints-1 do
            Residuals[iStart+I] := YData[I]
                                   - (BinWidth[i]*EquationValue(XData[I])) ;
        end
     else begin
        { Normal curve fitting }
        for i := 0 to nPoints-1 do
            Residuals[iStart+I] := YData[I]
                                   - EquationValue(XData[I]) ;
        end ;
     end ;


procedure TCurveFitter.STAT(
          nPoints : Integer ;         { no. of residuals (observations) }
          nPars : Integer ;           { no. of fitted parameters }
          var F : Array of Single ;   { final values of the residuals (IN) }
          var Y : Array of Single ;   { Y Data (IN) }
          var W : Array of Single ;   { Y Data weights (IN) }
          var SLT : Array of Single ; { lower super triangle of
                                        J(TRANS)*J from SLTJJ in SSQMIN (IN) }
          var SSQ : Single;           { Final sum of squares of residuals (IN)
                                        Returned containing parameter corr. coeffs.
                                        as CX(1,1),CX(2,1),CX(2,2),CX(3,1)....CX(N,N)}
          var SDPars : Array of Single ; { OUT standard deviations of each parameter X }
          var SDMIN : Single ;         { OUT Minimised standard deviation }
          var R : Single ;               { OUT Hamilton's R }
          var XPAR : Array of Single     { IN Fitted parameter array }
          ) ;
{C
C       J.DEMPSTER 1 - FEB - 82
C       Adapted from STAT by S.H. Bryant
CC      Subroutine to supply statistics for non - linear least -
C       squares fit of tabular data  by SSQMIN.
C       After minminsation takes J(TRANSPOSE)*J matrix from
C       ssqmin which is stored serially as a lower super tr -
C       angle in SLTJJ(1) through SLTJJ(JACM1). Creates full
C       matrix in C(N,N) which is then inverted to give the var -
C       iance/covariance martix from which standard deviances
C       and correlation coefficients are calculated by the
C       methods of Hamilton (1964).  Hamilton's R is calculated from
C       the data and theoretical values
C
C       Variables in call string:
C
C       M        - Integer no. of residuals (observations)
C       N        - Integer no. of fitted parameters
C       F        - Real array of length M which contains the
C                final values of the residuals
C       Y        - Real array of length M containing Y data
C       W        - Real weighting array of length M
C       SLT      - Real array of length N*(N + 1)/2
C                on input stores lower super triangle of
C                J(TRANS)*J from SLTJJ in SSQMIN
C                on return contains parameter corr. coeffs.
C                as CX(1,1),CX(2,1),CX(2,2),CX(3,1)....CX(N,N)
C       SSQ      - Final sum of squares of residuals
C       SDX      - REal array of length N containing the % standard
C                deviations of each parameter X
C       SDMIN    -        Minimised standard deviation
C       R        -        Hamilton's R
C       XPAR     -        Fitted parameter array
C
C
C       Requires matrix inversion srtn. MINV
C
        DIMENSION Y(M),SLT(1),SDX(N),C(8,8),A(64)
C
        REAL F(M),W(M),XPAR(N)
	INTEGER LROW(8),MCOL(8)
 }
 var
        I,J,L : LongInt ;
        LROW,MCOL : Array[0..8] of LongInt ;
        C : Array[1..8,1..8] of Single ;
        A : Array[0..80] of Single ;
        SUMP,YWGHT,DET : Single ;
 begin
	SDMIN := SQRT1( (SSQ/(nPoints - nPars)) ) ;
        SUMP := 0. ;
        for I := 1 to nPoints do begin
	    YWGHT := Y[I-1]*SQRT1(W[I]) ;
            SUMP := SUMP + Sqr(F[I] + YWGHT) ;
            end ;
        R := SQRT1(MinFlt([3.4E38,SSQ])/SUMP) ;

        { Restore J(TRANSP)*J and place in C(I,J) }

        L := 0 ;
        for I := 1 to nPars do begin
            for J := 1 to I do begin
                L := L + 1 ;
                C[I,J]  :=  SLT[L] ;
                end ;
            end ;

        for I := 1 to nPars do
            for J := 1 to nPars do
                IF (I < J) then C[I,J]  :=  C[J,I] ;

        { Invert C(I,J) }
        L := 0 ;
        for J := 1 to nPars do begin
            for I := 1 to nPars do begin
                L := L + 1 ;
                A[L] := C[I,J] ;
                end ;
            end ;

        MINV (A,nPars,DET,LROW,MCOL) ;

        L := 0 ;
        for J := 1 to nPars do begin
            for I := 1 to nPars do begin
                L := L + 1 ;
                C[I,J] := A[L] ;
                end ;
            end ;

        { Calculate std. dev. Pars[j] }

        for J  :=  1 to nPars do SDPars[j]  :=  SDMIN * SQRT1(ABS(C[J,J])) ;


{C	*** REMOVED since causing F.P. error and not used
C       Calculate correlation coefficients for
C       X(1) on Pars[j]. Return in lower super
C       triangle as X(1,1),X(2,2),X(3,1),X(3,2) ....
C

C	 L := 0
C	 DO 7 I := 1 to N
C	 DO 7 J := 1,I
C	 L := L + 1
C	 SLT(L) := C(I,J)/SQRT1(C(I,I)*C(J,J))
C7	 CONTINUE
	 RETURN}
         end ;


procedure TCurveFitter.MINV(
          var A : Array of Single ;
          N : LongInt ;
          var D : Single ;
          var L,M : Array of LongInt
          ) ;
{
C           A  -  INPUT MATRIX, DESTROYED IN COMPUTATION AND REPLACED BY
C               RESULTANT INVERSE.
C           N  -  ORDER OF MATRIX A
C           D  -  RESULTANT DETERMINANT
C           L  -  Work^ VECTOR OF LENGTH N
C           M  -  Work^ VECTOR OF LENGTH N
C
C        REMARKS
C           MATRIX A MUST BE A GENERAL MATRIX
C
C
C        METHOD
C           THE STANDARD GAUSS - JORDAN METHOD IS USED. THE DETERMINANT
C           IS ALSO CALCULATED. A DETERMINANT OF ZERO INDICATES THAT
C           THE MATRIX IS SINGULAR.
C
}
var
   NK,K,I,J,KK,IJ,IK,IZ,KI,KJ,JP,JQ,JR,JI,JK : LongInt ;
   BIGA,HOLD : Single ;
begin

      D := 1.0 ;
      NK :=  -N ;
      for K := 1 to N do begin {80}
          NK := NK + N ;
          L[K] := K ;
          M[K] := K ;
          KK := NK + K ;
          BIGA := A[KK] ;
          for J := K to N do begin{20}
              IZ := N*(J - 1) ;
              for I := K to N do begin {20}
                  IJ := IZ + I ;
                  IF( ABS(BIGA) -  ABS(A[IJ])) < 0. then begin {15,20,20}
                      BIGA := A[IJ] ;
                      L[K] := I ;
                      M[K] := J ;
                      end ;
                  end ;
              end ;

          { INTERCHANGE ROWS }

          J := L[K] ;
          IF(J - K) > 0. then begin {35,35,25}
               KI := K - N ;
               for I := 1 to N do begin {30}
                   KI := KI + N ;
                   HOLD :=  - A[KI] ;
                   JI := KI - K + J ;
                   A[KI] := A[JI] ;
                   A[JI]  := HOLD ;
                   end ; {30}
               end ;

          { INTERCHANGE COLUMNS }

          I := M[K] ; {35}
          IF(I - K) > 0. then begin
               JP := N*(I - 1) ;
               for J := 1 to N do begin {40}
                   JK := NK + J ;
                   JI := JP + J ;
                   HOLD :=  - A[JK] ;
                   A[JK] := A[JI] ;
                   A[JI]  := HOLD
                   end ;{40}
               end ;

         { DIVIDE COLUMN BY MINUS PIVOT (VALUE OF PIVOT ELEMENT IS
          CONTAINED IN BIGA }

          IF BIGA = 0. then begin
                  D := 0.0 ;
                  break ;
                  end ;

          for I := 1 to N do begin {55}
              IF(I - K) <> 0 then begin {50,55,50}
                   IK := NK + I ;
                   A[IK] := A[IK]/( -BIGA) ;
                   end ;
              end ; {55}

         { REDUCE MATRIX }

         for I := 1 to N do begin {65}
             IK := NK + I ;
             HOLD := A[IK] ;
             IJ := I - N ;
             for J := 1 to N do begin {65}
                 IJ := IJ + N ;
                 IF(I - K) <> 0 then begin {60,65,60}
                      IF(J - K) <> 0 then begin {62,65,62}
                           KJ := IJ - I + K ;
                           A[IJ] := HOLD*A[KJ] + A[IJ] ;
                           end ;
                      end ;
                 end ;
             end ; {65}

         { DIVIDE ROW BY PIVOT }

         KJ := K - N ;
         for J := 1 to N do begin {75}
             KJ := KJ + N ;
             IF(J <> K) then {70,75,70} A[KJ] := A[KJ]/BIGA ;
             end ; {75}

        { PRODUCT OF PIVOTS }

        D := D*BIGA ;

        { REPLACE PIVOT BY RECIPROCAL }

        A[KK] := 1.0/BIGA ;
        end ;

      { FINAL ROW AND COLUMN INTERCHANGE }

      K := N - 1 ;
      while (K>0) do begin {150,150,105}
              I := L[K] ;{105}
              IF(I - K) > 0 then begin {120,120,108}
                   JQ := N*(K - 1) ; {108}
                   JR := N*(I - 1) ;
                   for J := 1 to N do begin {110}
                       JK := JQ + J ;
                       HOLD := A[JK] ;
                       JI := JR + J ;
                       A[JK] :=  -A[JI] ;
                       A[JI] := HOLD ;
                       end ; {110}
                   end ;
              J := M[K] ;{120}
              IF(J - K) > 0 then begin {100,100,125}
                   KI := K - N ; {125}
                   for I := 1 to N do begin {130}
                       KI := KI + N ;
                       HOLD := A[KI] ;
                       JI := KI - K + J ;
                       A[KI] :=  -A[JI] ;
                       A[JI]  := HOLD ;
                       end ; {130}
                   end ;
              K := (K - 1) ;
              end ;

      end ;


FUNCTION TCurveFitter.SQRT1 (
         R : single
         ) : single ;
begin
     SQRT1  :=  SQRT( MINFlt([R,MaxSingle]) ) ;
     end ;


function TCurveFitter.MinInt(
         const Buf : array of LongInt { List of numbers (IN) }
         ) : LongInt ;                { Returns Minimum of Buf }
{ -------------------------------------------
  Return the smallest value in the array 'Buf'
  -------------------------------------------}
var
   i,Min : LongInt ;
begin
     Min := High(Min) ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;


function TCurveFitter.MinFlt(
         const Buf : array of Single { List of numbers (IN) }
         ) : Single ;                 { Returns minimum of Buf }
{ ---------------------------------------------------------
  Return the smallest value in the floating point  array 'Buf'
  ---------------------------------------------------------}
var
   i : Integer ;
   Min : Single ;
begin
     Min := MaxSingle ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;


function TCurveFitter.MaxInt(
         const Buf : array of LongInt  { List of numbers (IN) }
         ) : LongInt ;                 { Returns maximum of Buf }
{ ---------------------------------------------------------
  Return the largest long integer value in the array 'Buf'
  ---------------------------------------------------------}
var
   Max : LongInt ;
   i : Integer ;
begin
     Max:= -High(Max) ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;


function TCurveFitter.MaxFlt(
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



function TCurveFitter.IntLimitTo(
         Value : Integer ;       { Value to be tested (IN) }
         LowerLimit : Integer ;  { Lower limit (IN) }
         UpperLimit : Integer    { Upper limit (IN) }
         ) : Integer ;           { Return limited Value }
{ -------------------------------------------------------------------
  Make sure Value is kept within the limits LowerLimit and UpperLimit
  -------------------------------------------------------------------}
begin
     if Value < LowerLimit then Value := LowerLimit ;
     if Value > UpperLimit then Value := UpperLimit ;
     Result := Value ;
     end ;


function TCurveFitter.erf(x : Single ) : Single ;
{ --------------
  Error function
  --------------}
var
   t,z,y,erfx : single ;
begin
        if x < 10. then begin
	   z := abs( x )  ;
	   t := 1./( 1. + 0.5*z ) ;
	   y := t*exp( -z*z - 1.26551223 +
      	        t*(1.00002368 + t*(0.37409196 + t*(0.09678418 +
      	        t*( -0.18628806 + t*(0.27886807 + t*( -1.13520398 +
      	        t*(1.48851587 + t*( -0.82215223 + t*0.17087277 ))))))))) ;

           if ( x < 0. ) then y := 2. - y ;
	   erfx := 1. - y ;
           end
        else erfx := 1. ;
        Result := erfx ;
        end ;


function TCurveFitter.FPower(
         x,y : Single
         ) : Single ;
{ ----------------------------------
  Calculate x to the power y (x^^y)
  ----------------------------------}
begin
     if x > 0. then FPower := exp( ln(x)*y )
               else FPower := 0. ;
     end ;


function TCurveFitter.SafeExp( x : single ) : single ;
{ -------------------------------------------------------
  Exponential function which avoids underflow errors for
  large negative values of x
  -------------------------------------------------------}
const
     MinSingle = 1.5E-45 ;
var
   MinX : single ;
begin
     MinX := ln(MinSingle) + 1.0 ;
     if x < MinX then SafeExp := 0.0
                 else SafeExp := exp(x) ;
     end ;




end.
