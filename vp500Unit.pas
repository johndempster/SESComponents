unit vp500Unit;
  { =================================================================
  Biologic VP500 Interface Library V1.0
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  =================================================================
  16/2/04
  23/3/04 ... Most functions working (not fully tested yet)
  5/04/04
  14/04/04 ...
  11/6/04 .... Updated for BLVP500.DLL V1.02
               Current clamp mode stimulus scaling now 1 mV = 10 pA
               D/A waveform now always defined to end of A/D record
  14/12/04 ... MemoryToDAC algorithm for decoding steps and ramps improved
  }

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem, vp500lib, math ;

var
  // VP500Lib.DLL functions
  VP500_GetInfos : TVP500_GetInfos ;
  VP500_InitLib : TVP500_InitLib ;
  VP500_FreeLib : TVP500_FreeLib ;
  VP500_TestTransfer : TVP500_TestTransfer ;
  VP500_SetWaveStimParams : TVP500_SetWaveStimParams ;
  VP500_GetWaveStimParams : TVP500_GetWaveStimParams ;
  VP500_StartWaveStim : TVP500_StartWaveStim ;
  VP500_StopWaveStim : TVP500_StopWaveStim ;
  VP500_SingleRamp : TVP500_SingleRamp ;
  VP500_SetVIHold : TVP500_SetVIHold ;
  VP500_GetVIHold : TVP500_GetVIHold;
  VP500_SetHardwareConf : TVP500_SetHardwareConf;
  VP500_GetHardwareConf : TVP500_GetHardwareConf ;
  VP500_GetVP500Status : TVP500_GetVP500Status ;
	VP500_GetADCBuffers : TVP500_GetADCBuffers;
  VP500_SetAcqParams : TVP500_SetAcqParams ;
  VP500_StartContinuousAcq : TVP500_StartContinuousAcq;
  VP500_StopContinuousAcq : TVP500_StopContinuousAcq;
  VP500_StartStim : TVP500_StartStim;
  VP500_StopStim : TVP500_StopStim;
  VP500_DoZap : TVP500_DoZap ;
  VP500_SetJunction : TVP500_SetJunction ;
  VP500_GetJunction : TVP500_GetJunction;
  VP500_CalcSealImpedance : TVP500_CalcSealImpedance ;
  VP500_Reinitialization : TVP500_Reinitialization ;
  VP500_SetCompensations : TVP500_SetCompensations;
  VP500_GetCompensations : TVP500_GetCompensations ;
  VP500_SetNeutralization : TVP500_SetNeutralization;
  VP500_GetNeutralization : TVP500_GetNeutralization;
  VP500_SetNeutralizationParams : TVP500_SetNeutralizationParams;
  VP500_GetNeutralizationParams : TVP500_GetNeutralizationParams;
  VP500_CFastNeutralization : TVP500_CFastNeutralization;
  VP500_CSlowNeutralization : TVP500_CSlowNeutralization;
  VP500_CCellNeutralization : TVP500_CCellNeutralization;
  VP500_LeakNeutralization : TVP500_LeakNeutralization;
  VP500_OptimizeNeutralization : TVP500_OptimizeNeutralization;
  VP500_CellParameters : TVP500_CellParameters;


  procedure VP500_InitialiseBoard ;
  procedure VP500_LoadLibrary  ;

  function VP500_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

  procedure VP500_ConfigureHardware(
            EmptyFlagIn : Integer ) ;

  function  VP500_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;
  function VP500_StopADC : Boolean ;
  procedure VP500_GetADCSamples (
            OutBuf : Pointer ;
            var OutBufPointer : Integer
            ) ;
  procedure VP500_CheckSamplingInterval(
            var SamplingInterval : Double
            ) ;

function  VP500_MemoryToDAC(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer
          ) : Boolean ;

function VP500_GetDACUpdateInterval : double ;

  function VP500_StopDAC : Boolean ;
  procedure VP500_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;

  function  VP500_GetLabInterfaceInfo(
            var Model : string ; { Laboratory interface model name/number }
            var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
            var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
            var ADCMinValue : Integer ; { Negative limit of binary ADC values }
            var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
            var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
            var NumADCVoltageRanges : Integer ; { No. of options in above list }
            var ADCBufferLimit : Integer ;      { Max. no. samples in A/D buffer }
            var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
            var DACMinUpdateInterval : Double {Min. D/A update interval }
            ) : Boolean ;

  function VP500_GetMaxDACVolts : single ;

  function VP500_ReadADC( Channel : Integer ) : SmallInt ;

  procedure VP500_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
  procedure VP500_CloseLaboratoryInterface ;

  procedure VP500_Wait( Delay : Single ) ;

   function TrimChar( Input : Array of Char ) : string ;
   function MinInt( const Buf : array of LongInt ) : LongInt ;
   function MaxInt( const Buf : array of LongInt ) : LongInt ;

Procedure VP500_CheckError( Err : Integer ; ErrSource : String ) ;


implementation

uses SESLabIO ;

const
  VP500ADCMaxValue = 32767 ;
  VP500ADCVoltageMax = 10.0 ;
  VP500VMax = 10.0 ;
  VP500IMax = 5E-9 ;
  VP500BlockSize = 1024 ;
  VP500NumSamplingIntervals = 8 ;
  VP500SamplingIntervals : Array[0..VP500NumSamplingIntervals-1] of Double
  = (1E-5, 2E-5, 5E-5, 1E-4, 2E-4, 5E-4, 1E-3, 2E-3 ) ;
  VP500NumAmplifierGains = 9 ;
  VP500AmplifierGains : Array[0..VP500NumAmplifierGains-1] of Single
  = (1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0 ) ;
  ADCBufSize = 32768 ;

type
    TVP500SingleArray = Array[0..32767] of Single ;
    PVP500SingleArray = ^TVP500SingleArray ;
    TStimLevel = record
      V : Single ;
      Duration : Single ;
      end ;
    TStimLevels = array[0..32767] of TStimLevel ;
    PStimLevels = ^TStimLevels ;

var
   VP500Info : TBLVP500Infos ;      // VP500 information record
   VP500Data : TData ;              // VP500 Data information structure
   VP500HardwareConf : THardwareConf ; // VP500 settings
   VP500AcqParams : TAcqParams ;      // VP500 acquisition parameter settings
   VP500Stim : TStim ;              // Programmed stimulus definition record
   VP500Status : TVP500Status ;     // VP500 status flags
   VP500DecimationFactor : Integer ; // A/D sample decimation factor
   ADCBufPointer : Integer ;
   VScale : Single ;
   IScale : Single ;
   VP500ADCUpperLimit : Integer ;
   VP500ADCLowerLimit : Integer ;
   VP500_GetADCSamplesInUse : Boolean ;
   VP500TriggerMode : Integer ;
   LibraryLoaded : boolean ;        // Libraries loaded flag
   LibraryHnd : Integer ;           // DLL library file handle
   DeviceInitialised : Boolean ;    // Indicates devices has been successfully initialised
   Ticks0 : Integer ;

   FADCVoltageRangeMax : Single ;      // Upper limit of A/D input voltage range
   FADCMinValue : Integer ;            // Max. A/D integer value
   FADCMaxValue : Integer ;            // Min. A/D integer value
   FADCSamplingInterval : Double ;     // A/D sampling interval in current use (s)
   FADCMinSamplingInterval : Single ;  // Minimum valid A/D sampling interval (s)
   FADCMaxSamplingInterval : Single ;  // Maximum valid A/D sampling interval (s)
   FADCBufferLimit : Integer ;         // Number of samples in A/D input buffer
   CyclicADCBuffer : Boolean ;         // Circular (non-stop) A/D sampling mode
   EmptyFlag : SmallInt ;              // Value of A/D buffer empty flag
   FNumADCSamples : Integer ;          // No. of A/D samples per channel to acquire
   FNumADCChannels : Integer ;         // No. of A/D channels to acquired
   FNumSamplesRequired : Integer ;     // Total no. of A/D samples to acquired
   OutPointer : Integer ;              // Pointer to last A/D sample transferred
                                       // (used by VP500_GetADCSamples)
   FDACVoltageRangeMax : Single ;      // Upper limit of D/A voltage range
   FDACMinValue : Integer ;            // Max. D/A integer value
   FDACMaxValue : Integer ;            // Min. D/A integer value

   FDACMinUpdateInterval : Single ;

   VBuf : PVP500SingleArray ;          // Cell voltage buffer pointer
   IBuf : PVP500SingleArray ;          // Cell current buffer pointer
   StimLevels : PStimLevels ;          // Stimulus levels buffer

   ADCActive : Boolean ;                   // Indicates A/D conversion in progress
   FADCSweepDone : Boolean ;               // Indicates completion of an A/D sweep


function  VP500_GetLabInterfaceInfo(
            var Model : string ; { Laboratory interface model name/number }
            var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
            var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
            var ADCMinValue : Integer ; { Negative limit of binary ADC values }
            var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
            var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
            var NumADCVoltageRanges : Integer ; { No. of options in above list }
            var ADCBufferLimit : Integer ;      { Max. no. samples in A/D buffer }
            var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
            var DACMinUpdateInterval : Double {Min. D/A update interval }
            ) : Boolean ;
{ --------------------------------------------
  Get information about the interface hardware
  -------------------------------------------- }

begin
     Result := False ;
     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     Model := ' Biologic VP500 Lib:'
              + String(VP500Info.LibVersion) + ' Firmware:'
              + String(VP500Info.FirmwareVersion) ;

     // Define available A/D voltage range options
     NumADCVoltageRanges := 1 ;
     ADCVoltageRanges[0] := VP500VMax ;
     FADCVoltageRangeMax := ADCVoltageRanges[0] ;

     // A/D sample value range (16 bits)
     ADCMinValue := -(VP500ADCMaxValue+1) ;
     ADCMaxValue := -ADCMinValue - 1 ;
     FADCMinValue := ADCMinValue ;
     FADCMaxValue := ADCMaxValue ;

     // Min./max. A/D sampling intervals
     ADCMinSamplingInterval := VP500SamplingIntervals[0] ;
     ADCMaxSamplingInterval := VP500SamplingIntervals[VP500NumSamplingIntervals-1] ;
     FADCMinSamplingInterval := ADCMinSamplingInterval ;
     FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

     // Upper limit of bipolar D/A voltage range
     DACMaxVolts := VP500VMax ;
     FDACVoltageRangeMax := DACMaxVolts ;
     DACMinUpdateInterval := ADCMinSamplingInterval ;
     FDACMinUpdateInterval := DACMinUpdateInterval ;

     FADCBufferLimit := High(TSmallIntArray)+1 ;
     FADCBufferLimit := 32768 ; //30720 ;//
     ADCBufferLimit := FADCBufferLimit ;

     Result := DeviceInitialised ;

     end ;


procedure VP500_LoadLibrary  ;
{ -------------------------------------
  Load BVP500.DLL library into memory
  -------------------------------------}
begin

     LibraryLoaded := False ;

     { Load BVP500.DLL interface DLL library }
     LibraryHnd := LoadLibrary( PChar(ExtractFilePath(ParamStr(0)) + 'BLVP500.DLL' ));
     if LibraryHnd <= 0 then begin
        MessageDlg( ' VP500 interface library (BLVP500.DLL) not found', mtWarning, [mbOK], 0 ) ;
        Exit ;
        end ;

     { Get addresses of procedures in library }
     @VP500_GetInfos :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetInfos') ;
     @VP500_InitLib :=VP500_GetDLLAddress(LibraryHnd,'VP500_InitLib') ;
     @VP500_FreeLib :=VP500_GetDLLAddress(LibraryHnd,'VP500_FreeLib') ;
     @VP500_TestTransfer :=VP500_GetDLLAddress(LibraryHnd,'VP500_TestTransfer') ;
     @VP500_SetWaveStimParams :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetWaveStimParams') ;
     @VP500_GetWaveStimParams :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetWaveStimParams') ;
     @VP500_StartWaveStim :=VP500_GetDLLAddress(LibraryHnd,'VP500_StartWaveStim') ;
     @VP500_StopWaveStim :=VP500_GetDLLAddress(LibraryHnd,'VP500_StopWaveStim') ;
     @VP500_SingleRamp :=VP500_GetDLLAddress(LibraryHnd,'VP500_SingleRamp') ;
     @VP500_SetVIHold :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetVIHold') ;
     @VP500_GetVIHold :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetVIHold') ;
     @VP500_SetHardwareConf :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetHardwareConf') ;
     @VP500_GetHardwareConf :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetHardwareConf') ;
     @VP500_GetVP500Status :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetVP500Status') ;
     @VP500_SetAcqParams :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetAcqParams') ;
     @VP500_GetADCBuffers :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetADCBuffers') ;
     @VP500_StartContinuousAcq :=VP500_GetDLLAddress(LibraryHnd,'VP500_StartContinuousAcq') ;
     @VP500_StopContinuousAcq :=VP500_GetDLLAddress(LibraryHnd,'VP500_StopContinuousAcq') ;
     @VP500_StartStim :=VP500_GetDLLAddress(LibraryHnd,'VP500_StartStim') ;
     @VP500_StopStim :=VP500_GetDLLAddress(LibraryHnd,'VP500_StopStim') ;
     @VP500_DoZap :=VP500_GetDLLAddress(LibraryHnd,'VP500_DoZap') ;
     @VP500_SetJunction :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetJunction') ;
     @VP500_GetJunction :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetJunction') ;
     @VP500_CalcSealImpedance :=VP500_GetDLLAddress(LibraryHnd,'VP500_CalcSealImpedance') ;
     @VP500_Reinitialization :=VP500_GetDLLAddress(LibraryHnd,'VP500_Reinitialization') ;
     @VP500_SetCompensations :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetCompensations') ;
     @VP500_GetCompensations :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetCompensations') ;
     @VP500_SetNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetNeutralization') ;
     @VP500_GetNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetNeutralization') ;
     @VP500_SetNeutralizationParams :=VP500_GetDLLAddress(LibraryHnd,'VP500_SetNeutralizationParams') ;
     @VP500_GetNeutralizationParams :=VP500_GetDLLAddress(LibraryHnd,'VP500_GetNeutralizationParams') ;
     @VP500_CFastNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_CFastNeutralization') ;
     @VP500_CSlowNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_CSlowNeutralization') ;
     @VP500_CCellNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_CCellNeutralization') ;
     @VP500_LeakNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_LeakNeutralization') ;
     @VP500_OptimizeNeutralization :=VP500_GetDLLAddress(LibraryHnd,'VP500_OptimizeNeutralization') ;
     @VP500_CellParameters :=VP500_GetDLLAddress(LibraryHnd,'VP500_CellParameters') ;

     LibraryLoaded := True ;

     end ;


function VP500_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within BVP500.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('BVP500.DLL- ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
    end ;


function  VP500_GetMaxDACVolts : single ;
{ -----------------------------------------------------------------
  Return the maximum positive value of the D/A output voltage range
  -----------------------------------------------------------------}
begin
     Result := FDACVoltageRangeMax ;
     end ;


procedure VP500_InitialiseBoard ;
{ -----------------------------------
  Initialise VP500 interface hardware
  -----------------------------------}
var
   Err : Integer ;
begin

     DeviceInitialised := False ;
     LibraryLoaded := False ;
     if not LibraryLoaded then VP500_LoadLibrary ;

     if LibraryLoaded then begin

        // Initialise VP500
        Err := VP500_InitLib ;
        VP500_CheckError( Err, 'VP500_InitLib' )  ;
        if Err <> RSP_NO_ERROR then exit ;

        // Get VP500 information
        VP500_CheckError( VP500_GetInfos( @VP500Info ),
                          'VP500_GetInfos' )  ;

        // Test communications with VP500
        VP500_CheckError( VP500_TestTransfer,
                          'VP500_TestTransfer' )  ;

        // Initialise VP500
        VP500_CheckError( VP500_Reinitialization,
                          'VP500_Reinitialization' )  ;

       // Set GPIB timeout to 100 ms
       VP500_CheckError( VP500_GetHardwareConf( @VP500HardwareConf ),
                         'VP500_GetHardwareConf' ) ;
       VP500HardwareConf.GPIBTimeOut := 9 ; // 100 ms
       VP500_CheckError( VP500_SetHardwareConf( @VP500HardwareConf ),
                         'VP500_SetHardwareConf' ) ;

        // Start & stop acquisition (to force occasional error at this point)
        VP500_CheckError( VP500_StartContinuousAcq, 'VP500 Error!' ) ;
        VP500_StopContinuousAcq ;

        VP500DecimationFactor := 1 ;
        ADCBufPointer := 0 ;

        // Create A/D, D/A and stimulus level buffers
        New(VBuf) ;
        New(IBuf) ;
        New(StimLevels) ;

        DeviceInitialised := True ;

        end ;
     end ;


procedure VP500_ConfigureHardware(
          EmptyFlagIn : Integer ) ;
{ --------------------------------------------------------------------------

  -------------------------------------------------------------------------- }
begin
     EmptyFlag := EmptyFlagIn ;
     end ;


function VP500_ADCToMemory(
          var HostADCBuf : Array of SmallInt  ;   { A/D sample buffer (OUT) }
          nChannels : Integer ;                   { Number of A/D channels (IN) }
          nSamples : Integer ;                    { Number of A/D samples ( per channel) (IN) }
          var dt : Double ;                       { Sampling interval (s) (IN) }
          ADCVoltageRange : Single ;              { A/D input voltage range (V) (IN) }
          TriggerMode : Integer ;                 { A/D sweep trigger mode (IN) }
          CircularBuffer : Boolean                { Repeated sampling into buffer (IN) }
          ) : Boolean ;                           { Returns TRUE indicating A/D started }
{ -----------------------------
  Start A/D converter sampling
  -----------------------------}


begin
     Result := False ;
     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Stop any acquisition in progress
     VP500_StopADC ;

     // Make sure that dt is one of valid intervals
     // (Also sets VP500SamplingIntervalIndex)
     VP500_CheckSamplingInterval( dt ) ;

     // Get VP500 settings
     VP500_CheckError( VP500_GetHardwareConf( @VP500HardwareConf ),
                       'VP500_GetHardwareConf' ) ;

     // Set current and voltage -> 16 bit integer scaling factors
     VScale := VP500ADCMaxValue / (VP500VMax*20.0) ;
     IScale := ((VP500ADCMaxValue)*VP500HardwareConf.TotalGain*1E-3)/VP500VMax ;
     VP500ADCUpperLimit := VP500ADCMaxValue - 2 ;
     VP500ADCLowerLimit := -VP500ADCUpperLimit ;

     // Set acquisition parameters
     VP500AcqParams.AuxAInput := True ;
     VP500AcqParams.ADC1Selection := 0 ;
     VP500_CheckError( VP500_SetAcqParams(@VP500AcqParams),
                       'VP500_SetAcqParams' ) ;

     // Copy to internal storage
     FNumADCSamples := nSamples ;
     FNumADCChannels := nChannels ;
     FNumSamplesRequired := nChannels*nSamples ;
     FADCSamplingInterval := dt ;

     CyclicADCBuffer := CircularBuffer ;

     // Set trigger mode
     VP500TriggerMode := TriggerMode ;

     // Start acquisition immediately if in free run mode
     if VP500TriggerMode = tmFreeRun then begin
        // Free run acquisition
        VP500_CheckError( VP500_StartContinuousAcq,
                          'VP500_StartContinuousAcq' ) ;
        ADCActive := True ;
        end
     else ADCActive := False ;

     ADCBufPointer := 0 ;
     OutPointer := 0 ;           // Sample output pointer
     FADCSweepDone := False ;

     VP500_GetADCSamplesInUse := False ;
     Ticks0 := TimeGetTime ;

     end ;


function VP500_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
begin
     Result := False ;
     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit ;
     if not ADCActive then Exit ;

     if VP500TriggerMode = tmWaveGen then begin
        VP500_CheckError( VP500_StopStim,'VP500_StopStim' ) ;
        end
     else begin
        VP500_CheckError( VP500_StopContinuousAcq,'VP500_StopContinuousAcq' ) ;
        end ;

     ADCActive := False ;
     VP500_GetADCSamplesInUse := False ;
     Result := ADCActive ;

     end ;


procedure VP500_GetADCSamples(
          OutBuf : Pointer ;                { Pointer to buffer to receive A/D samples [In] }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
// ------------------------------------
// Get A/D samples from VP500 interface
// ------------------------------------
var
   OutPointerLimit,y : Integer ;
   NumSamplesAcquired : Integer ;
   NumBlocks : Integer ;
   Done : Boolean ;
   Err : Integer ;
begin

     if not ADCActive then begin
        VP500_GetADCSamplesInUse := False ;
        Exit ;
        end ;

     if VP500_GetADCSamplesInUse then begin
        Exit ;
        end ;

     VP500_GetADCSamplesInUse := True ;

     VP500_CheckError( VP500_GetVP500Status( @VP500Status ),
                       'VP500_GetVP500Status' ) ;
     if (VP500Status.ADC1FullBlocksNb < 1) or
        (VP500Status.ADC2FullBlocksNb < 1) then begin
        VP500_GetADCSamplesInUse := False ;
        Exit ;
        end ;

     NumBlocks := MinInt( [ VP500Status.ADC1FullBlocksNb,
                             VP500Status.ADC2FullBlocksNb]) ;

     VP500Data.LengthBufADC := NumBlocks*1024*2 ;
     VP500Data.LengthBufADC := MinInt( [VP500Data.LengthBufADC,ADCBufSize] ) ;
     VP500Data.LengthBufADC := (VP500Data.LengthBufADC div 1024)*1024 ;

     // Select buffers for voltage/current clamp modes
     if VP500HardwareConf.ClampMode = VIMODE_V_CLAMP then begin
        VP500Data.BufADC1 := Pointer(VBuf) ;
        VP500Data.BufADC2 := Pointer(IBuf) ;
        end
     else begin
        VP500Data.BufADC1 := Pointer(IBuf) ;
        VP500Data.BufADC2 := Pointer(VBuf) ;
        end ;

     VP500Data.SynchData := False ;
     Err := VP500_GetADCBuffers( @VP500Data ) ;
     if Err <> 0 then begin
        //outputdebugString(PChar(format('%d %d',[VP500Status.ADC1FullBlocksNb,Err]))) ;
        end ;
     NumSamplesAcquired := VP500Data.nbPtsBufADC1 ;

     // Copy sample data from VP500 buffer to output buffer
     if not CyclicADCBuffer then begin
        // Acquire single sweep
        Done := False ;
        OutPointerLimit := FNumSamplesRequired - 1 ;
        While not Done do begin
            // Get current channel (keep within limits exclude EmptyFlag value
            y := Round(IScale*IBuf^[ADCBufPointer]) ;
            if y > VP500ADCUpperLimit then y := VP500ADCUpperLimit ;
            if y < VP500ADCLowerLimit then y := VP500ADCLowerLimit ;
            PSmallIntArray(OutBuf)^[OutPointer] := y ;
            if OutPointer < OutPointerLimit then Inc(OutPointer) ;
            // Get voltage channel (keep within limits exclude EmptyFlag value
            if FNumADCChannels > 1 then begin
               y := Round(VScale*VBuf^[ADCBufPointer]) ;
               if y > VP500ADCUpperLimit then y := VP500ADCUpperLimit ;
               if y < VP500ADCLowerLimit then y := VP500ADCLowerLimit ;
               PSmallIntArray(OutBuf)^[OutPointer] := y ;
               if OutPointer < OutPointerLimit then Inc(OutPointer) ;
               end ;
            ADCBufPointer := ADCBufPointer + VP500DecimationFactor ;
            if (ADCBufPointer >= NumSamplesAcquired) or
               (OutPointer = OutPointerLimit) then Done := True ;
            end ;
        if OutPointer >= OutPointerLimit then FADCSweepDone := True ;

        end
     else begin
        // Cyclic buffer
        Done := False ;
        While not Done do begin
            // Get current channel (keep within limits exclude EmptyFlag value
            y := Round(IScale*IBuf^[ADCBufPointer]) ;
            if y > VP500ADCUpperLimit then y := VP500ADCUpperLimit ;
            if y < VP500ADCLowerLimit then y := VP500ADCLowerLimit ;
            PSmallIntArray(OutBuf)^[OutPointer] := y ;
            Inc(OutPointer) ;
            // Get voltage channel (keep within limits exclude EmptyFlag value
            if FNumADCChannels > 1 then begin
               y := Round(VScale*VBuf^[ADCBufPointer]) ;
               if y > VP500ADCUpperLimit then y := VP500ADCUpperLimit ;
               if y < VP500ADCLowerLimit then y := VP500ADCLowerLimit ;
               PSmallIntArray(OutBuf)^[OutPointer] := y ;
               Inc(OutPointer) ;
               end ;
            if OutPointer >= FNumSamplesRequired then OutPointer := 0 ;
            ADCBufPointer := ADCBufPointer + VP500DecimationFactor ;
            if (ADCBufPointer >= NumSamplesAcquired) then Done := True ;
            end ;
        end ;

     OutBufPointer := OutPointer ;
     ADCBufPointer := ADCBufPointer - NumSamplesAcquired ;

     VP500_GetADCSamplesInUse := False ;

     end ;


procedure VP500_CheckSamplingInterval(
          var SamplingInterval : Double
          ) ;
// ---------------------------------------------
// Ensure a validVP500 sampling interval is used
// ---------------------------------------------
var
    SamplingIntervalIndex : Integer ;
    Done : Boolean ;
begin

     // NOTE! Sampling rate limited to 50 kHz max.
     SamplingIntervalIndex := 1 ;
     Done := False ;
     While not Done do begin
         VP500DecimationFactor := Round( SamplingInterval /
                                         VP500SamplingIntervals[SamplingIntervalIndex]) ;
         if (VP500DecimationFactor < 32) or
            (SamplingIntervalIndex = (VP500NumSamplingIntervals-1)) then
            Done := True
         else Inc(SamplingIntervalIndex) ;
         end ;

     VP500DecimationFactor := MaxInt( [VP500DecimationFactor,1] ) ;
     SamplingInterval := VP500SamplingIntervals[SamplingIntervalIndex] *
                         VP500DecimationFactor  ;
     VP500AcqParams.SamplingRate := SamplingIntervalIndex ;

     end ;


function  VP500_MemoryToDAC(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer
          ) : Boolean ;

{ --------------------------------------------------------------
  Send a voltage waveform stored in DACValues to the D/A converters
  NOTE Only DAC channel 0 supported
  --------------------------------------------------------------}
var
   i : Integer ;
   iLev : Integer ;
   NumLevels : Integer ;
   NumShortLevels : Integer ;
   iStartLev : Integer ;
   ShortLevelLimit : Single ;
   TSum : Single ;
   dt : Single ;
   V : Single ;
   DACScale : Single ;
   iStim : Integer ;
   RampsInUse : Boolean ;
begin
    Result := False ;
    if not DeviceInitialised then VP500_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

    // Set scaling factors for voltage- or current-clamp mode

    if (VP500HardwareConf.ClampMode = VIMODE_V_CLAMP) or
       (VP500HardwareConf.ClampMode = VIMODE_V_TRACK) then begin
       // Voltage-clamp mode scale settings
       DACScale := VScale ;
       end
    else begin
       // Current clamp mode scale settings (1 mV = 10 pA)
       DACScale := VScale*100.0 ;
       end ;

    // Create stimulus levels table from Ch.0 of DACValues waveform

    // Create list of voltage levels within DAC buffer
    dt := FADCSamplingInterval*1E6 ;
    StimLevels^[0].V := (DACValues[0]/DACScale) ;
    StimLevels^[0].Duration := dt ;
    iLev := 0 ;
    for i := 1 to nPoints-1 do begin
        V := DACValues[i*nChannels]/DACScale ;
        if StimLevels^[iLev].V <> V then begin
           Inc(iLev) ;
           StimLevels^[iLev].V := V ;
           StimLevels^[iLev].Duration := dt ;
           end
        else begin
           StimLevels^[iLev].Duration := StimLevels^[iLev].Duration + dt ;
           end ;
        end ;
    NumLevels := iLev + 1 ;
    StimLevels^[NumLevels].Duration := 1E30 ;

    // Clear stimulus table
    for i := 0 to High(VP500Stim.StimTab) do begin
        VP500Stim.StimTab[i].Amplitude := 0.0 ;
        VP500Stim.StimTab[i].Duration := 0 ;
        VP500Stim.StimTab[i].Ramp := False ;
        end ;

    // Create stimulus table from voltage level list

    iStim := 0 ;
    ShortLevelLimit := 4*dt ;
    TSum := 0.0 ;
    NumShortLevels := 0 ;
    iStartLev := 0 ;
    for iLev := 0 to NumLevels-1 do begin

        if iStim > High(VP500Stim.StimTab) then Break ;

        if StimLevels^[iLev].Duration >= ShortLevelLimit then begin
           // Add long levels directly to stimulus table
           VP500Stim.StimTab[iStim].Amplitude := StimLevels^[iLev].V ;
           VP500Stim.StimTab[iStim].Duration := Round(StimLevels^[iLev].Duration) ;
           VP500Stim.StimTab[iStim].Ramp := False ;
           Inc(iStim) ;
           end
        else begin
           // Accumulate runs of short levels
           TSum := TSum + StimLevels^[iLev].Duration ;
           if NumShortLevels = 0 then iStartLev := iLev ;
           Inc(NumShortLevels) ;

           // If next level is a long level process existing series of short steps
           if StimLevels^[iLev+1].Duration >= ShortLevelLimit then begin
              // Add beginning of ramp or short pulse
              VP500Stim.StimTab[iStim].Amplitude := StimLevels^[iStartLev].V ;
              VP500Stim.StimTab[iStim].Duration := Round(StimLevels^[iStartLev].Duration) ;
              VP500Stim.StimTab[iStim].Ramp := False ;
              Inc(iStim) ;
              // If more than 1 short level, treat them as a ramp
              if NumShortLevels > 1 then begin
                 VP500Stim.StimTab[iStim].Amplitude := StimLevels^[iLev].V ;
                 VP500Stim.StimTab[iStim].Duration := Round(TSum - StimLevels^[iStartLev].Duration) ;
                 VP500Stim.StimTab[iStim].Ramp := true ;
                 Inc(iStim) ;
                 end ;
              // Reset short level run counters
              TSum := 0.0 ;
              NumShortLevels := 0 ;
              end ;
           end ;
        end ;

    // If supplied DAC waveform has fewer points than A/D buffer extend it
    if nPoints < FNumADCSamples then begin
       VP500Stim.StimTab[iStim].Amplitude := VP500Stim.StimTab[iStim-1].Amplitude ;
       VP500Stim.StimTab[iStim].Ramp := False ;
       VP500Stim.StimTab[iStim].Duration := Round((FNumADCSamples - nPoints)*dt) ;
       Inc(iStim) ;
       end ;

    // No. of stimulus segments and  blocks to acquire
    VP500Stim.StimTabNb := iStim ;
    VP500Stim.NbBlocksToAcq := (FNumADCSamples*VP500DecimationFactor) div 1024 ;

    // Determine and set duration of stimulus
    VP500Stim.RecDuration := 0 ;
    RampsInUse := False ;
    for iStim := 0 to VP500Stim.StimTabNb-1 do begin
        VP500Stim.RecDuration := VP500Stim.RecDuration + VP500Stim.StimTab[iStim].Duration ;
        if VP500Stim.StimTab[iStim].Ramp then RampsInUse := True ;
        end ;
    VP500Stim.RecDuration := (VP500Stim.RecDuration div 10) ;

    //outputdebugString(PChar(format('%d %d',[Round(FADCSamplingInterval*nPoints*1E5),
    //                                        VP500Stim.RecDuration]))) ;

    // Ramp stimuli seem to need a longer GBIP timeout (12) to work avoid
    // an error when VP500_StartStim called. The following code switches from
    // short timeout (100ms) required to avoid long pauses in acquisition
    // 16.12.04

    if RampsInUse then begin
       if VP500HardwareConf.GPIBTimeOut <> 12 then begin
          VP500HardwareConf.GPIBTimeOut := 12 ;
          VP500_CheckError( VP500_SetHardwareConf( @VP500HardwareConf ),
                            'VP500_SetHardwareConf' ) ;
          end ;
       end
    else begin
       if VP500HardwareConf.GPIBTimeOut <> 9 then begin
          VP500HardwareConf.GPIBTimeOut := 9 ; // 100 ms
          VP500_CheckError( VP500_SetHardwareConf( @VP500HardwareConf ),
                            'VP500_SetHardwareConf' ) ;
          end ;
       end ;


    VP500Stim.InitialDelay := 0 ;
    VP500_CheckError( VP500_StartStim( @VP500Stim ), 'VP500_StartStim' ) ;

    ADCActive := True ;
    Result := ADCActive ;

    end ;


function VP500_GetDACUpdateInterval : double ;
{ -----------------------
  Get D/A update interval
  -----------------------}
begin
     Result := FADCSamplingInterval ;
     { NOTE. DAC update interval is constrained to be the same
       as A/D sampling interval (set by VP500_ADCtoMemory. }
     end ;


function VP500_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin

     // Note. Since stimulus waveform generation of VP500  is linked
     // to A/D sampling, this procedure terminates both
    Result := False ;
    if not DeviceInitialised then VP500_InitialiseBoard ;
    if not DeviceInitialised then Exit ;
    if not ADCActive then Exit ;

     if VP500TriggerMode = tmWaveGen then begin
        VP500_CheckError( VP500_StopStim, 'VP500_StopStim' ) ;
        end
     else begin
        VP500_CheckError( VP500_StopContinuousAcq, 'VP500_StopContinuousAcq' ) ;
        end ;

     ADCActive := False ;
     Result := False ;

     end ;


procedure VP500_WriteDACsAndDigitalPort(
          var DACVolts : array of Single ;
          nChannels : Integer ;
          DigValue : Integer
          ) ;
{ ----------------------------------------------------
  Update D/A outputs with voltages suppled in DACVolts
  and TTL digital O/P with bit pattern in DigValue
  ----------------------------------------------------}
begin

     if not DeviceInitialised then VP500_InitialiseBoard ;
     exit ;



     end ;


function VP500_ReadADC(
         Channel : Integer // A/D channel
         ) : SmallInt ;
// ---------------------------
// Read Analogue input channel
// ---------------------------
begin
     Result := 0 ;
     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit

     end ;


procedure VP500_GetChannelOffsets(
          var Offsets : Array of Integer ;
          NumChannels : Integer
          ) ;
{ --------------------------------------------------------
  Returns the order in which analog channels are acquired
  and stored in the A/D data buffers
  --------------------------------------------------------}
var
   ch : Integer ;
begin
     for ch := 0 to NumChannels-1 do Offsets[ch] := ch ;
     end ;


procedure VP500_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
begin

     if not DeviceInitialised then Exit ;

     // Free library
     VP500_FreeLib ;
     //VP500_CheckError( Err, 'VP500_FreeLib' ) ;

     // Free A/D and D/A buffers
     Dispose(VBuf) ;
     Dispose(IBuf) ;
     Dispose(StimLevels) ;

     DeviceInitialised := False ;
     ADCActive := False ;

     end ;


function TrimChar( Input : Array of Char ) : string ;
var
   i : Integer ;
   pInput : PChar ;
begin
     pInput := @Input ;
     Result := '' ;
     for i := 0 to StrLen(pInput)-1 do Result := Result + Input[i] ;
     end ;


{ -------------------------------------------
  Return the smallest value in the array 'Buf'
  -------------------------------------------}
function MinInt(
         const Buf : array of LongInt { List of numbers (IN) }
         ) : LongInt ;                { Returns Minimum of Buf }
var
   i,Min : LongInt ;
begin
     Min := High(Min) ;
     for i := 0 to High(Buf) do
         if Buf[i] < Min then Min := Buf[i] ;
     Result := Min ;
     end ;

{ -------------------------------------------
  Return the largest value in the array 'Buf'
  -------------------------------------------}
function MaxInt(
         const Buf : array of LongInt { List of numbers (IN) }
         ) : LongInt ;                { Returns Maximum of Buf }
var
   i,Max : LongInt ;
begin
     Max := -High(Max) ;
     for i := 0 to High(Buf) do
         if Buf[i] > Max then Max := Buf[i] ;
     Result := Max ;
     end ;


Procedure VP500_CheckError(
          Err : Integer ;         // Error code
          ErrSource : String ) ;  // Name of procedure which returned Err
// ----------------------------------------------
// Report type and source of ITC interface error
// ----------------------------------------------
var
   ErrName : string ;
begin

   if Err <> RSP_NO_ERROR then begin
     Case Err of
         RSP_BLVP500_LIB_NOT_INIT : errName := 'BLVP500 library not initialized ' ;
         RSP_PARAMETERS_ERROR : errName := 'Invalid parameters to function call' ;
         RSP_COMM_FAILED : errName := 'Communication between the VP500 and the GPIB board failed ' ;
         RSP_UNEXPECTED_ERROR : errName := 'Unexpected error ' ;
         RSP_NOT_ALLOWED_CONT_ACQ_MODE : errName := 'Function not allowed in continuous acquisition mode ' ;
         RSP_NOT_VCLAMP_MODE : errName := 'Function only allowed in V-Clamp and V-Track mode ' ;
         RSP_GPIB32_LOAD_LIB_FAILED : errName := 'gpib-32.dll : LoadLibrary failed ' ;
         RSP_GPIB32_GET_PROC_ADDR_FAILED : errName := 'gpib-32.dll : GetProcAddress failed ' ;
         RSP_GPIB32_FREE_LIB_FAILED : errName := 'gpib-32.dll : FreeLibrary failed ' ;
         RSP_UNABLE_FIND_GPIB_BOARD : errName := 'Unable to find the GPIB board ' ;
         RSP_UNABLE_FIND_VP500 : errName := 'Unable to find the VP500 device ' ;
         RSP_UNABLE_INIT_GPIB_BOARD : errName := 'Unable to initialize the GPIB board ' ;
         RSP_UNABLE_INIT_VP500 : errName := 'Unable to initialize the VP500 device ' ;
         RSP_UNABLE_CFG_VP500 : errName := 'Unable to configure VP500 ' ;
         RSP_BAD_VP500_IDENT : errName := 'Wrong VP500 identifier ' ;
         RSP_LOAD_FIRMWARE_ERR : errName := 'Error during the downloading of the firmware ' ;
         RSP_CODE_SEG_ERR : errName := 'Wrong VP500 code segment ' ;
         RSP_FILE_NOT_FOUND : errName := 'VP500.bin not found ' ;
         RSP_FILE_ACCESS_ERR : errName := 'VP500.bin access error ' ;
         RSP_ACQ_IN_PROGRESS : errName := 'An acquisition is already in progress ' ;
         RSP_ACQ_DATA_FAILED : errName := 'Data acquisition on VP500 failed ' ;
         RSP_GET_ADC1_DATA_FAILED : errName := 'Get ADC1 data failed ' ;
         RSP_GET_ADC2_DATA_FAILED : errName := 'Get ADC2 data failed ' ;
         RSP_ADC1_DATA_EXCEPTION : errName := 'Exception occurred during treatment of ADC1 data ' ;
         RSP_ADC2_DATA_EXCEPTION : errName := 'Exception occurred during treatment of ADC2 data ' ;
         RSP_STIM_LOAD_FAILED : errName := 'Can not load programmed stimulation in the VP500 ' ;
         RSP_STIM_TRANSFER_FAILED : errName := 'Can not transfer programmed stimulation in the RAM of the VP500 ' ;
         RSP_STIM_NOT_TRANSFERRED : errName := 'Programmed stimulation not transferred in the RAM of the VP500 ' ;
         RSP_NOT_ENOUGH_MEMORY : errName := 'Not enough memory in the VP500 (too many points to acquire) ' ;
         RSP_ACQ_TIME_OUT : errName := 'Acquisition time out ' ;

        else ErrName := 'Unknown' ;
        end ;

     MessageDlg( 'Error ' + ErrName + ' in ' + ErrSource, mtError, [mbOK], 0) ;
     //outputdebugString(PChar('Error ' + ErrName + ' in ' + ErrSource));
     end ;

   end ;

procedure VP500_Wait( Delay : Single ) ;
var
  T : Integer ;
  TExit : Integer ;
begin
    T := TimeGetTime ;
    TExit := T + Round(Delay*1E3) ;
    while T < TExit do begin
       T := TimeGetTime ;
       end ;
    end ;

end.

