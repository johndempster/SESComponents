unit vp500;
  { =================================================================
  Biologic VP500 Interface Library V1.0
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  =================================================================
  }

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem;

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

function  VP500_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean
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


   function TrimChar( Input : Array of Char ) : string ;
   function MinInt( const Buf : array of LongInt ) : LongInt ;
   function MaxInt( const Buf : array of LongInt ) : LongInt ;

Procedure VP500_CheckError( Err : Cardinal ; ErrSource : String ) ;


implementation

uses SESLabIO, vp500Lib ;

const
  VP500ADCMaxValue = 32767 ;
  VP500ADCVoltageMax = 0.2 ;
  VP500VMax = 0.2 ;
  VP500IMax = 5E-9 ;
  VP500NumSamplingIntervals = 8 ;
  VP500SamplingIntervals : Array[0..VP500NumSamplingIntervals-1] of Double
  = (1E-5, 2E-5, 5E-5, 1E-4, 2E-4, 5E-4, 1E-3, 2E-3 ) ;
  VP500NumAmplifierGains = 9 ;
  VP500AmplifierGains : Array[0..VP500NumAmplifierGains-1] of Single
  = (1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0 ) ;

var
   VP500Info : TBLVP500Infos ;      // VP500 information record
   VP500Data : TData ;              // VP500 Data information structure
   VP500HardwareConf : THardwareConf ; // VP500 settings
   VP500Stim : TStim ;              // Programmed stimulus definition record
   VScale : Single ;
   LibraryLoaded : boolean ;        // Libraries loaded flag
   DeviceInitialised : Boolean ;    // Indicates devices has been successfully initialised

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
   FNumDACPoints : Integer ;
   FNumDACChannels : Integer ;         // No. of D/A channels in use

   FDACMinUpdateInterval : Single ;

   DACFIFO : PSmallIntArray ;               // FIFO output storage buffer
   ADCFIFO : PSmallIntArray ;               // FIFO input storage buffer


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

     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     Model := ' Biologic VP500 '
              + String(VP500Info.LibVersion) + ' '
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
     FADCBufferLimit := 32768 ;
     ADCBufferLimit := FADCBufferLimit ;

     Result := DeviceInitialised ;

     end ;


procedure VP500_LoadLibrary  ;
{ -------------------------------------
  Load ITCMM.DLL library into memory
  -------------------------------------}
begin
     Exit ;
     { Load ITCMM interface DLL library }
     //LibraryHnd := LoadLibrary( PChar('itcmm.DLL'));

     { Get addresses of procedures in library }
//     if LibraryHnd > 0 then begin
//        LibraryLoaded := True ;
//        end
//     else begin
//          MessageDlg( ' Instrutech interface library (ITCMM.DLL) not found', mtWarning, [mbOK], 0 ) ;
//          LibraryLoaded := False ;
//          end ;
     end ;


function VP500_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within ITC16 DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('VP500.DLL- ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
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
   Err,Retry : Integer ;
   NumDevices : Cardinal ;
   Done : Boolean ;
begin
     DeviceInitialised := False ;

     //if not LibraryLoaded then VP500_LoadLibrary ;
      LibraryLoaded := True ;
     if LibraryLoaded then begin

        // Initialise VP500
        Err := VP500_InitLib ;
        VP500_CheckError( Err, 'VP500_InitLib' )  ;
        if Err <> RSP_NO_ERROR then exit ;

        // Get VP500 information
        Err := VP500_GetInfos( @VP500Info ) ;
        VP500_CheckError( Err, 'VP500_GetInfos' )  ;

        VScale := VP500ADCMaxValue / VP500ADCVoltageMax ;

        // Create A/D, D/A and digital O/P buffers
        New(ADCFIFO) ;
        New(DACFIFO) ;

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

var
   Err : Cardinal ;
   OK : Boolean ;
   NumBlocks : Integer ;
begin

     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Stop any acquisition in progress
     VP500_StopADC ;

     // Make sure that dt is one of valid intervals
     // (Also sets VP500SamplingIntervalIndex)
     VP500_CheckSamplingInterval( dt ) ;

     Err := VP500_GetHardwareConf( @VP500HardwareConf ) ;
     VP500_CheckError( Err, 'VP500_GetHardwareConf' ) ;

     // Set current and voltage -> 16 bit integer scaling factors
     VScale := VP500ADCMaxValue / VP500VMax ;
     IScale := VP500ADCMaxValue / VP500HardwareConf.AmplitudeMax ;

     // Set no. of samples/channel to be captured
     // (Must be multiple of VP500 block size)
     NumBlocks := nSamples div VP500BlockSize ;
     if (NumBlocks*VP500BlockSize) < nSamples then Inc(NumBlocks) ;
     // Set both punctual and programmed stimulation records
     VP500Data.LengthBufADC := NumBlocks*VP500BlockSize ;
     VP500Stim.LengthBufADC := NumBlocks*VP500BlockSize ;

     // Copy to internal storage
     FNumADCSamples := nSamples ;
     FNumADCChannels := nChannels ;
     FNumSamplesRequired := nChannels*nSamples ;
     FADCSamplingInterval := dt ;
     CyclicADCBuffer := CircularBuffer ;

     FADCSweepDone := False ;
     ADCActive := True ;

     end ;


function VP500_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
var
     Err : Cardinal ;
     i : Integer ;

begin

     if not DeviceInitialised then VP500_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     ADCActive := False ;
     Result := ADCActive ;

     end ;


procedure VP500_GetADCSamples(
          OutBuf : Pointer ;                { Pointer to buffer to receive A/D samples [In] }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
// -----------------------------------------
// Get A/D samples from ITC interface FIFO
// -----------------------------------------
var
   Err,i,OutPointerLimit : Integer ;
begin

     if not ADCActive then Exit ;

     if VP500TriggerMode = tmFreeRun then begin
        VP500Data.AuxAInput := True ;
        VP500Data.SamplingRate := VP500SamplingRateIndex ;
        VP500Data.ADC1Selection := 0 ;
        VP500Data.BufADC1 := ADC1Buf ;
        VP500Data.BufADC2 := ADC2Buf ;
        VP500_GetADCBuffers( VP500Data ) ;
        //outputdebugString(PChar(format('%d',[ChannelData.Value]))) ;
        end
     else if VP500TriggerMode = tmStimulus then begin
        VP500Stim.AuxAInput := True ;
        VP500Stim.SamplingRate := VP500SamplingRateIndex ;
        VP500Stim.ADC1Selection := 0 ;
        VP500Stim.LengthBufADC :=
        VP500Stim.BufADC1 := ADC1Buf ;
        VP500Stim.BufADC2 := ADC2Buf ;
        VP500_ApplyStim( VP500Stim ) ;
        end ;

     // Copy sample data from VP500 buffer to output buffer
     OutPointer := 0 ;
     for i := 0 to NbPtsBufADC1-1 do begin
         PSmallIntArray(OutBuf)^[OutPointer] := Round(IScale*ADC1Buf^[i]) ;
         Inc(OutPointer) ;
         PSmallIntArray(OutBuf)^[OutPointer] := Round(VScale*ADC2Buf^[i]) ;
         Inc(OutPointer) ;
         end ;

     OutBufPointer := OutPointer ;

     end ;


procedure VP500_CheckSamplingInterval(
          var SamplingInterval : Double
          ) ;
// ----------------------------------------
// Ensure a VP500 sampling interval is used
// ----------------------------------------
var
    Diff : Single ;  // Difference between supplied and valid intervals
    MinDiff : Single ;; // Minimum Diff.
begin
     Diff := 1E30 ;
     for i := 0 to VP500NumSamplingIntervals-1 do begin
         Diff := Abs(SamplingInterval -  VP500NumSamplingIntervals) ;
         if Diff < MinDiff then begin
            VP500SamplingIntervalIndex := i ;
            MinDiff := Diff ;
            end ;
         end ;

     VP500Data.SamplingRate := VP500SamplingIntervalIndex ;
     VP500Stim.SamplingRate := VP500SamplingIntervalIndex ;

     SamplingInterval := VP500SamplingIntervals[VP500SamplingIntervalIndex] ;

     end ;


function  VP500_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean
          ) : Boolean ;
{ --------------------------------------------------------------
  Send a voltage waveform stored in DACBuf to the D/A converters
  30/11/01 DigFill now set to correct final value to prevent
  spurious digital O/P changes between records
  --------------------------------------------------------------}
var
   i,ch,Err,iDACValue,iDigValue,iStep : Integer ;

begin

    if not DeviceInitialised then VP500_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

       { Stop any acquisition in progress }
       {if ADCActive then} ADCActive := VP500_StopADC ;

    // Create stimulus table from Ch.0 of DACValues waveform

    j := 0 ;
    VP500Stim.StimTabNb := 0 ;
    VP500Stim.StimTab[VP500Stim.StimTabNb].Amplitude := DACValues[0] / VScale ;
    for i := 0 to FNumADCSamples-1 do begin
        V := DACValues[j] / VScale ;
        if V <> VP500Stim.StimTab[VP500Stim.StimTabNb].Amplitude then begin
           if VP500Stim.StimTabNb < High(VP500Stim.StimTab) then begin
              Inc(VP500Stim.StimTabNb) ;
              VP500Stim.StimTab[VP500Stim.StimTabNb].Amplitude := V ;
              end ;
           end ;
        VP500Stim.StimTab[VP500Stim.StimTabNb].Duration :=
              VP500Stim.StimTab[VP500Stim.StimTabNb].Duration
              + Round(FSamplingInterval*1E6) ;
        j := j + nChannels ;
        end ;
    Inc(VP500Stim.StimTabNb) ;

    VP500Stim.RecDuration := VP500Stim.LengthBufADC*Round(FSamplingInterval*1E6) ;
    VP500Stim.InitialDelay := 0 ;

    {Save D/A sweep data }
    FNumDACPoints := nPoints ;
    FNumDACChannels := nChannels ;

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

     // Note. Since D/A sub-system of ITC boards is strictly linked
     // to A/D sub-system, this procedure does nothing
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
const
     MaxDACValue = 32767 ;
     MinDACValue = -32768 ;
var
   DACScale : single ;
   ch,DACValue,NumCh : Integer ;
   ChannelData : Array[0..4] of TITCChannelData ;
   Err : Integer ;
begin

     if not DeviceInitialised then VP500_InitialiseBoard ;

     if DeviceInitialised then begin

        // Scale from Volts to binary integer units
        DACScale := MaxDACValue/FDACVoltageRangeMax ;

        { Set up D/A channel values }
        NumCh := 0 ;
        for ch := 0 to nChannels-1 do begin
            // Correct for errors in hardware DAC scaling factor
            DACValue := Round(DACVolts[ch]*DACScale) ;
            // Keep within legitimate limits
            if DACValue > MaxDACValue then DACValue := MaxDACValue ;
            if DACValue < MinDACValue then DACValue := MinDACValue ;
            ChannelData[NumCh].ChannelType := H2D ;
            ChannelData[NumCh].ChannelNumber := ch ;
            ChannelData[NumCh].Value := DACValue ;
            Inc(NumCh) ;
            end ;

        // Set up digital O/P values
        ChannelData[NumCh].ChannelType := DIGITAL_OUTPUT ;
        ChannelData[NumCh].ChannelNumber := 0;
        ChannelData[NumCh].Value := DigValue ;
        Inc(NumCh) ;
        Err := ITC_AsyncIO( Device, NumCh, ChannelData ) ;
        VP500_CheckError( Err, 'ITC_AsyncIO' ) ;

        end ;


     end ;


function VP500_ReadADC(
         Channel : Integer // A/D channel
         ) : SmallInt ;
// ---------------------------
// Read Analogue input channel
// ---------------------------
var
   ChannelData : TITCChannelData ;
   Err : Integer ;
begin

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
var
   i : Integer ;
   Err : Cardinal ;
begin

     if not DeviceInitialised then Exit ;

     // Free library
     Err := VP500_FreeLib ;
     VP500_CheckError( Err, 'VP500_FreeLib' ) ;

     // Free A/D, D/A and digital O/P buffers
     Dispose(ADCFIFO) ;
     Dispose(DACFIFO) ;

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
          Err : Cardinal ;        // Error code
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
         RSP_PARAMETERS_ERROR : errName := 'Invalid parameters to function call ;
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

end.

end.
