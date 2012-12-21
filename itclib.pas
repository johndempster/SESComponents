unit itclib;
  { =================================================================
  Instrutech ITC-16/18 Interface Library for original driver
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  =================================================================
  24.01.03 Tested and working with ITC-18
  03.02.03 Tested and working with ITC-16
  11/2/04 ... ITC_MemoryToDACAndDigitalOut can now wait for ext. trigger
              itclib.dll now specifically loaded from program folder
  04/04/07 ... Collection of last point in single sweep now assured
  16/01/12 ... D/A fifo now filled by ITC_GetADCSamples allowing
               record buffer to be increased to MaxADCSamples div 2 (4194304)
  27/8/12 ... ITC_WriteDACsAndDigitalPort and ITC_ReadADC now disabled when ADCActive = TRUE
  }

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem,math;

  procedure ITC_InitialiseBoard ;
  procedure ITC_LoadLibrary  ;

  function ITC_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

procedure ITC_ConfigureHardware(
          ITCInterfaceType : Integer ;
          EmptyFlagIn : Integer ) ;

  function  ITC_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;
  function ITC_StopADC : Boolean ;
  procedure ITC_GetADCSamples (
            OutBuf : Pointer ;
            var OutBufPointer : Integer
            ) ;
  procedure ITC_CheckSamplingInterval(
            var SamplingInterval : Double ;
            var Ticks : Cardinal
            ) ;

function  ITC_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ; // D/A output values
          NumDACChannels : Integer ;                // No. D/A channels
          nPoints : Integer ;                  // No. points per channel
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : Boolean ;             // Output to digital outs
          WaitForExtTrigger : Boolean          // Ext. trigger mode
          ) : Boolean ;

  function ITC_GetDACUpdateInterval : double ;

  function ITC_StopDAC : Boolean ;
  procedure ITC_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;

  function  ITC_GetLabInterfaceInfo(
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

  function ITC_GetMaxDACVolts : single ;

  function ITC_ReadADC( Channel : Integer ;
                        ADCVoltageRange : Single ) : SmallInt ;

  procedure ITC_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;

  procedure ITC_CloseLaboratoryInterface ;


   function TrimChar( Input : Array of Char ) : string ;
   function MinInt( const Buf : array of LongInt ) : LongInt ;
   function MaxInt( const Buf : array of LongInt ) : LongInt ;

Procedure ITC_CheckError( Err : Cardinal ; ErrSource : String ) ;


implementation

uses SESLabIO, forms ;

const

   FIFOMaxPoints = 16128 ;

   ITC16_ID = 0 ;
   ITC18_ID = 1 ;
   MaxADCChannels = 7 ;

   ITC_MINIMUM_TICKS = 5 ;
   ITC_MAXIMUM_TICKS = 65535 ;


   DIGITAL_INPUT = $02 ;		//Digital Input
   DIGITAL_OUTPUT = $03	;	//Digital Output
   AUX_INPUT = $04 ;		//Aux Input
   AUX_OUTPUT = $05 ;		//Aux Output

   ITC_NUMBEROFADCINPUTS = 8 ;
//STUB -> Move this object to the Registry
   ITC18_SOFTWARE_SEQUENCE_SIZE	= 4096 ;
//STUB ->Verify
   ITC16_SOFTWARE_SEQUENCE_SIZE	= 1024 ;

   ITC18_NUMBEROFCHANNELS = 16 ;			//4 + 8 + 2 + 1 + 1
   ITC18_NUMBEROFOUTPUTS = 7 ;			//4 + 2 + 1
   ITC18_NUMBEROFINPUTS = 9 ;			//8 + 1

   ITC18_NUMBEROFADCINPUTS = 8 ;
   ITC18_NUMBEROFDACOUTPUTS = 4 ;
   ITC18_NUMBEROFDIGINPUTS = 1 ;
   ITC18_NUMBEROFDIGOUTPUTS = 2 ;
   ITC18_NUMBEROFAUXINPUTS = 0 ;
   ITC18_NUMBEROFAUXOUTPUTS = 1 ;

   ITC18_DA_CH_MASK = $3 ;			//4 DA Channels
   ITC18_DO0_CH = $4 ;			//DO0
   ITC18_DO1_CH = $5 ;			//DO1
   ITC18_AUX_CH = $6 ;			//AUX

   ITC16_NUMBEROFCHANNELS = 14 ;			//4 + 8 + 1 + 1
   ITC16_NUMBEROFOUTPUTS = 5 ;			//4 + 1
   ITC16_NUMBEROFINPUTS = 9 ;			//8 + 1
   ITC16_DO_CH = 4 ;

   ITC16_NUMBEROFADCINPUTS = 8 ;
   ITC16_NUMBEROFDACOUTPUTS = 4 ;
   ITC16_NUMBEROFDIGINPUTS = 1 ;
   ITC16_NUMBEROFDIGOUTPUTS = 1 ;
   ITC16_NUMBEROFAUXINPUTS = 0 ;
   ITC16_NUMBEROFAUXOUTPUTS = 0 ;


//***************************************************************************
//Overflow/Underrun Codes
   ITC_READ_OVERFLOW_H = $01 ;
   ITC_WRITE_UNDERRUN_H = $02 ;
   ITC_READ_OVERFLOW_S = $10 ;
   ITC_WRITE_UNDERRUN_S = $20 ;

   ITC_STOP_CH_ON_OVERFLOW = $0001 ;	//Stop One Channel
   ITC_STOP_CH_ON_UNDERRUN = $0002 ;

   ITC_STOP_CH_ON_COUNT = $1000 ;
   ITC_STOP_PR_ON_COUNT = $2000 ;

   ITC_STOP_DR_ON_OVERFLOW = $0100 ;	//Stop One Direction
   ITC_STOP_DR_ON_UNDERRUN = $0200 ;

   ITC_STOP_ALL_ON_OVERFLOW = $1000 ;	//Stop System (Hardware STOP)
   ITC_STOP_ALL_ON_UNDERRUN = $2000 ;
   //***************************************************************************
//Software Keys MSB
   PaulKey = $5053 ;
   HekaKey = $4845 ;
   UicKey = $5543 ;
   InstruKey = $4954 ;
   AlexKey = $4142  ;

   EcellKey = $4142 ;
   SampleKey = $5470 ;
   TestKey = $4444 ;
   TestSuiteKey = $5453 ;


   RESET_FIFO_COMMAND = $10000 ;
   PRELOAD_FIFO_COMMAND = $20000 ;
   LAST_FIFO_COMMAND = $40000 ;
   FLUSH_FIFO_COMMAND = $80000 ;

   // ITC-16 FIFO sequence codes
   // --------------------------
   ITC16_INPUT_AD0 = $7 ;
   ITC16_INPUT_AD1 = $6 ;
   ITC16_INPUT_AD2 = $5 ;
   ITC16_INPUT_AD3 = $4 ;
   ITC16_INPUT_AD4 = $3 ;
   ITC16_INPUT_AD5 = $2 ;
   ITC16_INPUT_AD6 = $1 ;
   ITC16_INPUT_AD7 = $0 ;
   ITC16_INPUT_DIGITAL =$20 ;
   ITC16_INPUT_UPDATE = $0 ;

   ITC16_TICKINTERVAL = 1E-6 ;



   ITC16_OUTPUT_DA0 = $18 ;
   ITC16_OUTPUT_DA1 = $10 ;
   ITC16_OUTPUT_DA2 = $08 ;
   ITC16_OUTPUT_DA3 = $0 ;
   ITC16_OUTPUT_DIGITAL = $40 ;
   ITC16_OUTPUT_UPDATE = $0 ;

   // ITC-18 FIFO sequence codes
   // --------------------------
   ITC18_INPUT_AD0 = $0000 ;
   ITC18_INPUT_AD1 = $0080 ;
   ITC18_INPUT_AD2 = $0100 ;
   ITC18_INPUT_AD3 = $0180 ;
   ITC18_INPUT_AD4 = $0200 ;
   ITC18_INPUT_AD5 = $0280 ;
   ITC18_INPUT_AD6 = $0300 ;
   ITC18_INPUT_AD7 = $0380 ;
   ITC18_INPUT_UPDATE = $4000 ;

   ITC18_OUTPUT_DA0 = $0000 ;
   ITC18_OUTPUT_DA1 = $0800 ;
   ITC18_OUTPUT_DA2 = $1000 ;
   ITC18_OUTPUT_DA3 = $1800 ;
   ITC18_OUTPUT_DIGITAL0 = $2000 ;
   ITC18_OUTPUT_DIGITAL1 = $2800 ;
   ITC18_OUTPUT_UPDATE = $8000 ;

   ITC18_TICKINTERVAL = 1.25E-6 ;


   // Error flags
   ACQ_SUCCESS = 0 ;
   Error_DeviceIsNotSupported = $0001000 ; //1000 0000 0000 0001 0000 0000 0000
   Error_UserVersionID = $80001000 ;
   Error_KernelVersionID = $81001000 ;
   Error_DSPVersionID = $82001000;
   Error_TimerIsRunning = $8CD01000 ;
   Error_TimerIsDead = $8CD11000 ;
   Error_TimerIsWeak = $8CD21000 ;
   Error_MemoryAllocation = $80401000 ;
   Error_MemoryFree = $80411000 ;
   Error_MemoryError = $80421000 ;
   Error_MemoryExist = $80431000 ;
   Warning_AcqIsRunning = $80601000 ;
   Error_TIMEOUT = $80301000 ;
   Error_OpenRegistry = $8D101000 ;
   Error_WriteRegistry = $8DC01000 ;
   Error_ReadRegistry = $8DB01000 ;
   Error_ParamRegistry = $8D701000 ;
   Error_CloseRegistry = $8D201000 ;
   Error_Open = $80101000 ;
   Error_Close = $80201000 ;
   Error_DeviceIsBusy = $82601000 ;
   Error_AreadyOpen = $80111000 ;
   Error_NotOpen = $80121000 ;
   Error_NotInitialized = $80D01000 ;
   Error_Parameter = $80701000 ;
   Error_ParameterSize = $80A01000 ;
   Error_Config = $89001000 ;
   Error_InputMode = $80611000 ;
   Error_OutputMode = $80621000 ;
   Error_Direction = $80631000 ;
   Error_ChannelNumber = $80641000 ;
   Error_SamplingRate = $80651000 ;
   Error_StartOffset = $80661000 ;
   Error_Software = $8FF01000  ;



type


// *** DLL libray function templates ***

// Interface procedures for the Instrutech ITC16.
//
// Copyright (c) 1991, 1996 Instrutech Corporation, Great Neck, NY, USA
//
// Created by SKALAR Instruments, Seattle, WA, USA


// Application interface functions
//
// Functions that return a status return 0 if the function succeeds,
// and a non-zero value if the function fails. The status values
// can be interpreted by ITC16_GetStatusText.

// Set the type of interface in use (ITC_16, ITC_18)
TITC_SetInterfaceType = Function(
                        InterfaceType : Integer
                        ) : Cardinal ; cdecl ;

// Function ITC16_GetStatusText
//
// Translate a status value to a text string. The translated string
// is written into "text" with maximum length "length" characters.

TITC_GetStatusText = Function (
                       Device : Pointer ;
                       Status : Cardinal ;
                       Text : PChar ;
                       Length : Cardinal
                       ) : Cardinal ; cdecl ;

// Return the size of the structure that defines the device.
TITC_GetStructureSize = Function : Cardinal ; cdecl ;

// Initialize the device hardware.
TITC_Initialize = Function(
                  Device : Pointer
                  ) : Cardinal ; cdecl ;

// Open the device driver.
TITC_Open = Function(
            Device : Pointer
            ) : Cardinal ; cdecl ;

// Close the device and free resources associated with it.
TITC_Close = Function(
             Device : Pointer
             ) : Cardinal ; cdecl ;

// Return the size of the  FIFO memory, measured in samples.
TITC_GetFIFOSize = Function(
                   Device : Pointer
                   ) : Cardinal ; cdecl ;

// Set the sampling rate.
TITC_SetSamplingInterval = Function(
                           Device : Pointer ;
                           Interval : Cardinal
                           ) : Cardinal ; cdecl ;

// An array of length instructions is written out to the sequence RAM.
// Acquisition must be stopped to write to the sequence RAM.
// length - The number of entries for the sequence memory.
// Set the sampling rate.
TITC_SetSequence = Function(
                   Device : Pointer ;
                   SequenceLength : Cardinal ;
                   var Sequence : Array of Cardinal ) : Cardinal ; cdecl ;

// This routine must be called before acquisition can be performed after power
// up, and after each call to Stop.  The FIFOs are reset and enabled.
TITC_InitializeAcquisition = Function(
                             Device : Pointer
                             ) : Cardinal ; cdecl ;

// Initiate acquisition.  Data acquisition will stop on
// A/D FIFO overflow. D/A output will stop on D/A FIFO underflow.
// D/A output will be enabled only if 'output_enable' is non-zero.
// External triggering may be specified with a non-zero value in
// 'external_trigger'. Otherwise acquisition will start immediately.
TITC_Start = Function(
             Device : Pointer ;
             ExternalTrigger : Cardinal ;
             OutPutEnable : Cardinal
             ) : Cardinal ; cdecl ;


// Return the number of FIFO entries available for writing.
TITC_GetFIFOWriteAvailable = Function(
                             Device : Pointer ;
                             var NumAvailable : Cardinal
                             ) : Cardinal ; cdecl ;


// The buffer of(length) entries is written to the ITC16.
// Any value from 1 to the value returned by ITC16_GetFIFOWriteAvailable may
// be used as the length argument.
TITC_WriteFIFO = Function(
                 Device : Pointer ;
                 NumEntries : Cardinal ;
                 OutBuf : Pointer
                 ) : Cardinal ; cdecl ;


// Return the number of acquired samples not yet read out of the FIFO.
// The "overflow" value is set to zero if FIFO overflow has not occurred,
// and a non-zero value if input FIFO overflow has occurred.
TITC_GetFIFOReadAvailable = Function(
                            Device : Pointer ;
                            var NumAvailable : Cardinal
                            ) : Cardinal ; cdecl ;


// The buffer is filled with length entries from the ITC16.
// Any value from 1 to the value returned by ITC16_GetFIFOReadAvailable may
// be used as the length argument.
TITC_ReadFIFO = Function(
                Device : Pointer ;
                NumEntries : Cardinal ;
                InBuf : Pointer
                ) : Cardinal ; cdecl ;


// Return the state of the clipping bit and clear the latch.
TITC_IsClipping = Function(
                  Device : Pointer ;
                  var IsClipping : Cardinal
                  ) : Cardinal ; cdecl ;


// The 'overflow' parameter is set to zero if input FIFO overflow has
// not occurred, and non-zero if input FIFO overflow has occurred.
TITC_GetFIFOOverflow = Function(
                       Device : Pointer ;
                       var OverFlow : Cardinal
                       ) : Cardinal ; cdecl ;


// End acquisition immediately.
TITC_Stop = Function(
            Device : Pointer
            ) : Cardinal ; cdecl ;


// Return a status value that corresponds to "FIFO Overflow".
TITC_GetStatusOverflow = Function(
                         Device : Pointer
                         ) : Cardinal ; cdecl ;

// Release the driver.
// Only of use under Microsoft Windows.
TITC_Release = Function(
               Device : Pointer
               ) : Cardinal ; cdecl ;

// Reserve the driver.
// Only of use under Microsoft Windows.
TITC_Reserve = Function(
               Device : Pointer ;
               var Busy : Cardinal
               ) : Cardinal ; cdecl ;

TITC_SetRange = Function(
                Device : Pointer ;
                var ADRange : Array of Cardinal
                ) : Cardinal ; cdecl ;



var
   ITC_SetInterfaceType : TITC_SetInterfaceType ;
   ITC_GetStatusText : TITC_GetStatusText ;
   ITC_GetStructureSize : TITC_GetStructureSize ;
   ITC_Initialize : TITC_Initialize ;
   ITC_Open : TITC_Open ;
   ITC_Close : TITC_Close ;
   ITC_GetFIFOSize :TITC_GetFIFOSize ;
   ITC_SetSamplingInterval : TITC_SetSamplingInterval ;
   ITC_SetSequence : TITC_SetSequence ;
   ITC_InitializeAcquisition : TITC_InitializeAcquisition ;
   ITC_Start : TITC_Start ;
   ITC_GetFIFOWriteAvailable : TITC_GetFIFOWriteAvailable ;
   ITC_WriteFIFO : TITC_WriteFIFO ;
   ITC_GetFIFOReadAvailable : TITC_GetFIFOReadAvailable ;
   ITC_ReadFIFO : TITC_ReadFIFO ;
   ITC_IsClipping : TITC_IsClipping ;
   ITC_GetFIFOOverflow :TITC_GetFIFOOverflow ;
   ITC_Stop :TITC_Stop ;
   ITC_GetStatusOverflow : TITC_GetStatusOverflow ;
   ITC_Release : TITC_Release ;
   ITC_Reserve : TITC_Reserve ;
   ITC_SetRange : TITC_SetRange ;


   LibraryHnd : THandle ;           // ITCLIB.DLL library file handle
   Device : Pointer ;               // Pointer to device strutcure
   InterfaceType : Cardinal ;          // ITC interface type (ITC16/ITC18)
   LibraryLoaded : boolean ;        // Libraries loaded flag
   DeviceInitialised : Boolean ;    // Indicates devices has been successfully initialised

   //FADCMaxChannel : Integer ;                   // Upper limit of A/D channel numbers
   FADCVoltageRanges : Array[0..15] of Single ; // A/D input voltage range options
   FNumADCVoltageRanges : Integer ;             // No. of available A/D voltage ranges
   //FADCVoltageRangeMax : Single ;               // Upper limit of A/D input voltage range
   FADCMinValue : Integer ;                     // Max. A/D integer value
   FADCMaxValue : Integer ;                     // Min. A/D integer value
   FADCSamplingInterval : Double ;              // A/D sampling interval
   FADCMinSamplingInterval : Single ;           // Min. A/D sampling interval
   FADCMaxSamplingInterval : Single ;           // Max. A/D sampling interval
   FADCBufferLimit : Integer ;                  // Upper limit of A/D sample buffer
   CyclicADCBuffer : Boolean ;                  // Continuous cyclic A/D buffer mode flag
   EmptyFlag : SmallInt ;                       // Empty A/D buffer indicator value
   FNumADCSamples : Integer ;                   // No. A/D samples/channel/sweep
   FNumADCChannels : Integer ;                  // No. A/D channels/sweep
   FNumSamplesRequired : Integer ;
   OutPointer : Integer ;              // Pointer to last A/D sample transferred
                                       // (used by ITC_GetADCSamples)
   OutPointerSkipCount : Integer ;     // No. of points to ignore when FIFO read starts


   FDACVoltageRangeMax : Single ;  // Upper limit of D/A voltage range
   FDACMinValue : Integer ;        // Max. D/A integer value
   FDACMaxValue : Integer ;        // Min. D/A integer value
   FNumDACPoints : Integer ;
   FNumDACChannels : Integer ;

   FDACMinUpdateInterval : Single ;
   FTickInterval : Double ;                 // A/D clock tick resolution (s)
   FTicksPerSample : Cardinal ;             // Current no. ticks per A/D sample

   DACFIFO : PSmallIntArray ;               // FIFO output storage buffer
   DACPointer : Integer ;                   // FIFO DAC write pointer
   ADCFIFO : PSmallIntArray ;               // FIFO input storage buffer

   // FIFO sequencer codes in use
   INPUT_AD0 : Integer ;
   INPUT_AD1 : Integer ;
   INPUT_AD2 : Integer ;
   INPUT_AD3 : Integer ;
   INPUT_AD4 : Integer ;
   INPUT_AD5 : Integer ;
   INPUT_AD6 : Integer ;
   INPUT_AD7 : Integer ;
   INPUT_UPDATE : Integer ;
   OUTPUT_DA0 : Integer ;
   OUTPUT_DA1 : Integer ;
   OUTPUT_DA2 : Integer ;
   OUTPUT_DA3 : Integer ;
   OUTPUT_DIGITAL : Integer ;
   OUTPUT_UPDATE : Integer ;
   Sequence : Array[0..16] of Cardinal ;   // FIFO input/output control sequence

   ADCActive : Boolean ;                   // Indicates A/D conversion in progress
   DACActive : Boolean ;



function  ITC_GetLabInterfaceInfo(
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
var
     i : Integer ;
begin

     if not DeviceInitialised then ITC_InitialiseBoard ;

     if DeviceInitialised then begin

        { Get device model and serial number }
        if InterfaceType = ITC16_ID then Model := ' ITC-16 '
        else if InterfaceType = ITC18_ID then Model := ' ITC-18 '
        else Model := 'Unknown' ;

        // Define available A/D voltage range options
        for i := 0 to FNumADCVoltageRanges-1 do
            ADCVoltageRanges[i] := FADCVoltageRanges[i] ;
        NumADCVoltageRanges := FNumADCVoltageRanges ;

        // A/D sample value range (16 bits)
        ADCMinValue := -32678 ;
        ADCMaxValue := -ADCMinValue - 1 ;
        FADCMinValue := ADCMinValue ;
        FADCMaxValue := ADCMaxValue ;

        // Upper limit of bipolar D/A voltage range
        DACMaxVolts := 10.25 ;
        FDACVoltageRangeMax := 10.25 ;
        DACMinUpdateInterval := 2.5E-6 ;
        FDACMinUpdateInterval := DACMinUpdateInterval ;

        // Min./max. A/D sampling intervals
        ADCMinSamplingInterval := 2.5E-6 ;
        ADCMaxSamplingInterval := 100.0 ;
        FADCMinSamplingInterval := ADCMinSamplingInterval ;
        FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

        //FADCBufferLimit := High(TSmallIntArray)+1 ;
        //FADCBufferLimit := 16128 ;
        FADCBufferLimit := MaxADCSamples div 2 ; //Old value 16128 ;
        ADCBufferLimit := FADCBufferLimit ;

        end ;

     Result := DeviceInitialised ;

     end ;


procedure ITC_LoadLibrary  ;
{ -------------------------------------
  Load ITCLIB.DLL library into memory
  -------------------------------------}
begin

     { Load ITCLIB interface DLL library }
     LibraryHnd := LoadLibrary(
                   PChar(ExtractFilePath(ParamStr(0)) + 'itclib.dll'));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @ITC_SetInterfaceType :=ITC_GetDLLAddress(LibraryHnd,'ITC_SetInterfaceType') ;
        @ITC_GetStatusText :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetStatusText') ;
        @ITC_GetStructureSize :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetStructureSize') ;
        @ITC_Initialize :=ITC_GetDLLAddress(LibraryHnd,'ITC_Initialize') ;
        @ITC_Open :=ITC_GetDLLAddress(LibraryHnd,'ITC_Open') ;
        @ITC_Close :=ITC_GetDLLAddress(LibraryHnd,'ITC_Close') ;
        @ITC_GetFIFOSize :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetFIFOSize') ;
        @ITC_SetSamplingInterval :=ITC_GetDLLAddress(LibraryHnd,'ITC_SetSamplingInterval') ;
        @ITC_SetSequence :=ITC_GetDLLAddress(LibraryHnd,'ITC_SetSequence') ;
        @ITC_InitializeAcquisition :=ITC_GetDLLAddress(LibraryHnd,'ITC_InitializeAcquisition') ;
        @ITC_GetFIFOWriteAvailable :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetFIFOWriteAvailable') ;
        @ITC_WriteFIFO :=ITC_GetDLLAddress(LibraryHnd,'ITC_WriteFIFO') ;
        @ITC_GetFIFOReadAvailable :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetFIFOReadAvailable') ;
        @ITC_ReadFIFO :=ITC_GetDLLAddress(LibraryHnd,'ITC_ReadFIFO') ;
        @ITC_IsClipping :=ITC_GetDLLAddress(LibraryHnd,'ITC_IsClipping') ;
        @ITC_Start :=ITC_GetDLLAddress(LibraryHnd,'ITC_Start') ;
        @ITC_GetFIFOOverflow :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetFIFOOverflow') ;
        @ITC_Stop :=ITC_GetDLLAddress(LibraryHnd,'ITC_Stop') ;
        @ITC_GetStatusOverflow :=ITC_GetDLLAddress(LibraryHnd,'ITC_GetStatusOverflow') ;
        @ITC_Release :=ITC_GetDLLAddress(LibraryHnd,'ITC_Release') ;
        @ITC_Reserve :=ITC_GetDLLAddress(LibraryHnd,'ITC_Reserve') ;
        @ITC_SetRange :=ITC_GetDLLAddress(LibraryHnd,'ITC_SetRange') ;
        LibraryLoaded := True ;
        end
     else begin
          MessageDlg( ' Instrutech interface library (ITCLIB.DLL) not found', mtWarning, [mbOK], 0 ) ;
          LibraryLoaded := False ;
          end ;
     end ;


function ITC_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within ITCLIB.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('ITCLIB.DLL- ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
    end ;


function  ITC_GetMaxDACVolts : single ;
// -----------------------------------------------------------------
//  Return the maximum positive value of the D/A output voltage range
//  -----------------------------------------------------------------
begin
     Result := FDACVoltageRangeMax ;
     end ;


procedure ITC_InitialiseBoard ;
{ -------------------------------------------
  Initialise Instrutech interface hardware
  -------------------------------------------}
var
   Size,Err : Integer ;
begin
     DeviceInitialised := False ;

     if not LibraryLoaded then ITC_LoadLibrary ;

     if LibraryLoaded then begin

        // Determine type of ITC interface
        if InterfaceType = ITC16_ID then begin
           // Load ITC-16 FIFO sequencer codes
          INPUT_AD0 := ITC16_INPUT_AD0 ;
          INPUT_AD1 := ITC16_INPUT_AD1 ;
          INPUT_AD2 := ITC16_INPUT_AD2 ;
          INPUT_AD3 := ITC16_INPUT_AD3 ;
          INPUT_AD4 := ITC16_INPUT_AD4 ;
          INPUT_AD5 := ITC16_INPUT_AD5 ;
          INPUT_AD6 := ITC16_INPUT_AD6 ;
          INPUT_AD7 := ITC16_INPUT_AD7 ;
          INPUT_UPDATE := ITC16_INPUT_UPDATE ;
          OUTPUT_DA0 := ITC16_OUTPUT_DA0 ;
          OUTPUT_DA1 := ITC16_OUTPUT_DA1 ;
          OUTPUT_DA2 := ITC16_OUTPUT_DA2 ;
          OUTPUT_DA3 := ITC16_OUTPUT_DA3 ;
          OUTPUT_DIGITAL := ITC16_OUTPUT_DIGITAL ;
          OUTPUT_UPDATE := ITC16_OUTPUT_UPDATE ;

          // Define available A/D voltage range options
          FADCVoltageRanges[0] := 10.24 ;
          FNumADCVoltageRanges := 1 ;

          FTickInterval := ITC16_TICKINTERVAL ;
          // No. of invalid samples in FIFO when started
          OutPointerSkipCount := -5 ;

          end
       else begin
          // Load ITC-18 FIFO sequencer codes
          INPUT_AD0 := ITC18_INPUT_AD0 ;
          INPUT_AD1 := ITC18_INPUT_AD1 ;
          INPUT_AD2 := ITC18_INPUT_AD2 ;
          INPUT_AD3 := ITC18_INPUT_AD3 ;
          INPUT_AD4 := ITC18_INPUT_AD4 ;
          INPUT_AD5 := ITC18_INPUT_AD5 ;
          INPUT_AD6 := ITC18_INPUT_AD6 ;
          INPUT_AD7 := ITC18_INPUT_AD7 ;
          INPUT_UPDATE := ITC18_INPUT_UPDATE ;
          OUTPUT_DA0 := ITC18_OUTPUT_DA0 ;
          OUTPUT_DA1 := ITC18_OUTPUT_DA1 ;
          OUTPUT_DA2 := ITC18_OUTPUT_DA2 ;
          OUTPUT_DA3 := ITC18_OUTPUT_DA3 ;
          OUTPUT_DIGITAL := ITC18_OUTPUT_DIGITAL1 ;
          OUTPUT_UPDATE := ITC18_OUTPUT_UPDATE ;

          // Define available A/D voltage range options
          FADCVoltageRanges[0] := 10.24 ;
          FADCVoltageRanges[1] := 5.12 ;
          FADCVoltageRanges[2] := 2.048 ;
          FADCVoltageRanges[3] := 1.024 ;
          FNumADCVoltageRanges := 4 ;

          FTickInterval := ITC18_TICKINTERVAL ;
          // No. of invalid samples in FIFO when started
          OutPointerSkipCount := -3 ;


          end ;

        // Set type of interface
        ITC_SetInterfaceType ( InterfaceType ) ;

        // Allocate device control structure
        Size := ITC_GetStructureSize ;
        if Device <> Nil then FreeMem( Device ) ;
        GetMem( Device, Size ) ;

        // Open device
        Err := ITC_Open( Device ) ;
        ITC_CheckError( Err, 'ITC_Open' )  ;
        if Err <> ACQ_SUCCESS then exit ;

        // Initialise interface hardware
        Err := ITC_Initialize( Device ) ;
        ITC_CheckError( Err, 'ITC_Initialize' )  ;

        // Create A/D, D/A and digital O/P buffers
        New(ADCFIFO) ;
        New(DACFIFO) ;

        DeviceInitialised := True ;

        end ;
     end ;


procedure ITC_ConfigureHardware(
          ITCInterfaceType : Integer ;
          EmptyFlagIn : Integer ) ;
// -------------------------------------
// Configure library for interface type
// --------------------------------------
begin

     InterfaceType := ITCInterfaceType ;

     // Initialise board
     ITC_InitialiseBoard ;

     EmptyFlag := EmptyFlagIn ;

     end ;


function ITC_ADCToMemory(
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
   i,ch : Integer ;
   ExternalTrigger : Integer ;
   OutputEnable : Integer ;
   Err : Cardinal ;
   OK : Boolean ;
   ADRange : Array[0..ITC18_NUMBEROFADCINPUTS-1] of Cardinal ;
begin
     Result := False ;

     if not DeviceInitialised then ITC_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Stop any acquisition in progress
     if ADCActive or DACActive then begin
        Err := ITC_Stop( Device ) ;
        ITC_CheckError( Err, 'ITC_Stop' )  ;
        end ;

     // Make sure that dt is an integer number of microsecs
     dt := dt / nChannels ;
     ITC_CheckSamplingInterval( dt, FTicksPerSample ) ;
     dt := dt*nChannels ;

     // Copy to internal storage
     FNumADCSamples := nSamples ;
     FNumADCChannels := nChannels ;
     FNumSamplesRequired := nChannels*nSamples ;
     FADCSamplingInterval := dt ;
     CyclicADCBuffer := CircularBuffer ;

     // Set A/D input voltage range for all channels
     for i := 0 to FNumADCVoltageRanges do
         if ADCVoltageRange = FADCVoltageRanges[i] then begin
            for ch := 0 to High(ADRange) do ADRange[ch] := i ;
            end ;
     Err := ITC_SetRange( Device, ADRange ) ;
     ITC_CheckError( Err, 'ITC_SetRange' )  ;

     // Set up FIFO acquisition sequence for A/D input channels
     for ch := 0 to nChannels-1 do begin
         if ch = 0 then Sequence[ch] := INPUT_AD0 ;
         if ch = 1 then Sequence[ch] := INPUT_AD1 ;
         if ch = 2 then Sequence[ch] := INPUT_AD2 ;
         if ch = 3 then Sequence[ch] := INPUT_AD3 ;
         if ch = 4 then Sequence[ch] := INPUT_AD4 ;
         if ch = 5 then Sequence[ch] := INPUT_AD5 ;
         if ch = 6 then Sequence[ch] := INPUT_AD6 ;
         if ch = 7 then Sequence[ch] := INPUT_AD7 ;
         if ch = (nChannels-1) then Sequence[ch] := Sequence[ch] or INPUT_UPDATE ;
         end ;

     // Download sequence to interface
     Err := ITC_SetSequence( Device, nChannels, Sequence ) ;
     ITC_CheckError( Err, 'ITC_SetSequence' )  ;

     // Set sampling interval
     Err := ITC_SetSamplingInterval( Device, FTicksPerSample ) ;
     ITC_CheckError( Err, 'ITC_SetSamplingInterval' )  ;

     // Initialise A/D FIFO
     Err := ITC_InitializeAcquisition( Device ) ;
     ITC_CheckError( Err, 'ITC_InitializeAcquisition' )  ;

     // Start A/D sampling
     if TriggerMode <> tmWaveGen then begin
        // Free Run vs External Trigger of recording seeep
        if TriggerMode = tmExtTrigger then ExternalTrigger := 1
                                      else ExternalTrigger := 0 ;
        OutputEnable := 0 ;
        Err := ITC_Start( Device,
                          ExternalTrigger,
                          OutputEnable ) ;
        ITC_CheckError( Err, 'ITC_START' )  ;

        OK := True ;

        end
     else OK := True ;

     // Initialise A/D buffer output pointer
     OutPointer := OutPointerSkipCount ;

     ADCActive := OK ;
     Result := OK ;

     end ;


function ITC_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
var
     Err : Cardinal ;
begin
     Result := False ;
     if not DeviceInitialised then ITC_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     { Stop ITC interface (both A/D and D/A) }

     Err := ITC_Stop( Device ) ;
     ITC_CheckError( Err, 'ITC_Stop' ) ;

     ADCActive := False ;
     DACActive := False ;  // Since A/D and D/A are synchronous D/A stops too
     Result := ADCActive ;

     end ;


procedure ITC_GetADCSamples(
          OutBuf : Pointer ;                { Pointer to buffer to receive A/D samples [In] }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
// -----------------------------------------
// Get A/D samples from ITC interface FIFO
// -----------------------------------------
var
   Err,i,OutPointerLimit,NumSamplesToWrite : Integer ;
   NumSamples : Cardinal ;
begin

     if not ADCActive then Exit ;

     // Determine number of samples available in FIFO
     ITC_CheckError( ITC_GetFIFOReadAvailable( Device, NumSamples),
                     'ITC_GetFIFOReadAvailable (ITC_GetADCSamples)') ;

        //outputdebugString(PChar(format('%d',[NumSamples]))) ;

     // Read A/D samples from FIFO
     // (NOTE! It is essential to leave at least one sample
     //  in the FIFO to avoid terminating A/D sampling)

     if NumSamples > 1 then begin

        // Interleave samples from A/D FIFO buffers into O/P buffer
        if not CyclicADCBuffer then begin
           // Single sweep
           OutPointerLimit := FNumSamplesRequired - 1 ;

           // Ensure FIFO buffer is not emptied if sweep not completed
           if (OutPointer + NumSamples) < OutPointerLimit then begin
              NumSamples := NumSamples -1 ;
              end ;

           // Read FIFO
           ITC_CheckError( ITC_ReadFIFO( Device, NumSamples, ADCFIFO ),
                           'ITC_ReadFIFO (ITC_GetADCSamples)') ;

           for i :=  0 to NumSamples-1 do begin
               if (OutPointer >= 0) and (OutPointer <= OutPointerLimit) then
               PSmallIntArray(OutBuf)^[OutPointer] := ADCFIFO^[i] ;
               Inc(OutPointer) ;
               end ;

           OutBufPointer := Min(OutPointer,OutPointerLimit) ;
           end
        else begin

           // Ensure FIFO buffer is not emptied (which stops sampling)
           NumSamples := NumSamples - 1 ;

           // Read FIFO
           ITC_CheckError( ITC_ReadFIFO( Device, NumSamples, ADCFIFO ),
                           'ITC_ReadFIFO (ITC_GetADCSamples)') ;

           // Cyclic buffer
           for i :=  0 to NumSamples-1 do begin
               if OutPointer >= 0 then PSmallIntArray(OutBuf)^[OutPointer] := ADCFIFO^[i] ;
               Inc(OutPointer) ;
               if Outpointer >= FNumSamplesRequired then Outpointer := 0 ;
               end ;
           OutBufPointer := OutPointer ;
           end ;

        if (DACPointer > 0) and (DACPointer < FNumSamplesRequired) then begin
           NumSamplesToWrite := Min(NumSamples,FNumSamplesRequired-DACPointer) ;
           Err := ITC_WriteFIFO( Device, NumSamplesToWrite, @DACFIFO^[DACPointer] ) ;
           ITC_CheckError(Err,'ITC_WriteFIFO') ;
           DACPointer := DACPointer + NumSamplesToWrite ;
           //outputdebugstring(pchar(format('%d %d',[DACPointer,ChannelData.Value])));
           end ;

        end ;

     end ;


procedure ITC_CheckSamplingInterval(
          var SamplingInterval : Double ;
          var Ticks : Cardinal
          ) ;
{ ---------------------------------------------------
  Convert sampling period from <SamplingInterval> (in s) into
  clocks ticks, Returns no. of ticks in "Ticks"
  ---------------------------------------------------}
begin
     Ticks := Round( SamplingInterval / FTickInterval ) ;
     Ticks := MaxInt([MinInt([Ticks,ITC_MAXIMUM_TICKS]),ITC_MINIMUM_TICKS]);
     SamplingInterval :=  Ticks*FTickInterval ;
     end ;


function  ITC_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          NumDACChannels : Integer ;
          nPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean ;
          WaitForExtTrigger : Boolean              // Ext. trigger mode
          ) : Boolean ;
{ --------------------------------------------------------------
  Send a voltage waveform stored in DACBuf to the D/A converters
  30/11/01 DigFill now set to correct final value to prevent
  spurious digital O/P changes between records
  --------------------------------------------------------------}
var
   i,k,ch,Err,iFIFO : Integer ;
   DACChannel : Array[0..15] of Cardinal ;
   ADCChannel : Array[0..15] of Cardinal ;
   NumOutChannels : Integer ;              // No. of DAC + Digital output channels
   LastFIFOSample : Integer ;              // Last sample index in FIFO
   InCh, OutCh : Integer ;
   iDAC, iDig : Integer ;
   Step,Counter : Single ;
   SequenceLength : Cardinal ;
   NumSamplesToWrite : Cardinal ;
   ExternalTrigger : Cardinal ;
   OutputEnable : Cardinal ;
begin
    Result := False ;
    if not DeviceInitialised then ITC_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

    { Stop any acquisition in progress }
    ADCActive := ITC_StopADC ;

    // Get A/D channel sequence codes
    for ch := 0 to FNumADCChannels-1 do ADCChannel[Ch] := Sequence[Ch] ;

    // Set up DAC channel O/P sequence codes
    for ch := 0 to High(DACChannel) do DACChannel[ch] := OUTPUT_DA0 ;
    if NumDACChannels > 1 then DACChannel[1] := OUTPUT_DA1 ;
    if NumDACChannels > 2 then DACChannel[2] := OUTPUT_DA2 ;
    if NumDACChannels > 3 then DACChannel[3] := OUTPUT_DA3 ;
    NumOutChannels := NumDACChannels ;
    if DigitalInUse then begin
       DACChannel[NumDACChannels] := OUTPUT_DIGITAL ;
       NumOutChannels := NumDACChannels + 1 ;
       end ;

    // Incorporate codes into FIFO control sequence
    // (Note. Config and Se0qence already contains data entered by ITC_ADCToMemory)

    if FNumADCChannels < NumOutChannels then begin
       // No. of output channels exceed input
       // -----------------------------------

       // Configure sequence memory
       SequenceLength := FNumADCChannels*NumOutChannels ;
       InCh := 0 ;
       OutCh := 0 ;
       for k := 0 to SequenceLength-1 do begin
           Sequence[k] := ADCChannel[InCh] or DACChannel[OutCh] ;
           // D/A channel update
           if OutCh = (NumOutChannels-1) then begin
              Sequence[k] := Sequence[k] or OUTPUT_UPDATE ;
              OutCh := 0 ;
              end
           else Inc(OutCh) ;

           // A/D channel update
           if InCh = (FNumADCChannels-1) then begin
              Sequence[k] := Sequence[k] or INPUT_UPDATE ;
              InCh := 0 ;
              end
           else Inc(InCh) ;
           end ;

       // DAC / Dig buffer step interval
       Step := NumOutChannels / FNumADCChannels ;

       // Copy D/A values into D/A FIFO buffers
       iFIFO := 0 ;
       Counter := 0.0 ;
       LastFIFOSample := FNumADCChannels*FNumADCSamples - 1 ;
       While iFIFO <= LastFIFOSample do begin

           // Copy D/A values
           iDAC := MinInt( [Trunc(Counter),nPoints-1] ) ;
           for ch := 0 to NumDACChannels-1 do if iFIFO <= LastFIFOSample then begin
               DACFIFO^[iFIFO] := DACValues[iDAC*NumDACChannels+ch] ;
               Inc(iFIFO) ;
               end ;

           // Copy digital values
           if DigitalInUse then begin
              iDig := MinInt( [Trunc(Counter),nPoints-1]) ;
              if iFIFO <= LastFIFOSample then begin
                 DACFIFO^[iFIFO] := DigValues[iDig] ;
                 Inc(iFIFO) ;
                 end ;
              end ;

           Counter := Counter + Step ;
           end ;

       end
    else begin
       // No. of input channels equal or exceed outputs
       // ---------------------------------------------

       // Configure sequence memory
       SequenceLength := FNumADCChannels ;
       for ch := 0 to FNumADCChannels-1 do begin
           Sequence[ch] := Sequence[ch] or DACChannel[ch] ;
           end ;
       Sequence[FNumADCChannels-1] := Sequence[FNumADCChannels-1] or OUTPUT_UPDATE ;

       // Copy D/A values into D/A FIFO buffers
       for i := 0 to FNumADCSamples-1 do begin

           iDAC := MinInt( [i, nPoints-1 ] ) ;
           iFIFO := i*FNumADCChannels ;

           // Copy D/A values
           for ch := 0 to FNumADCChannels-1 do begin
               if ch < NumOutChannels then
                  DACFIFO^[iFIFO+ch] := DACValues[iDAC*NumDACChannels+ch]
               else DACFIFO^[iFIFO+ch] := DACValues[iDAC*NumDACChannels] ;
               end ;

           // Copy digital values
           if DigitalInUse then begin
              DACFIFO^[iFIFO+NumDACChannels] := DigValues[iDAC] ;
              end ;

           end ;

       end ;

    // Download sequence to interface
    Err := ITC_SetSequence( Device, SequenceLength, Sequence ) ;
    ITC_CheckError( Err, 'ITC_SetSequence' )  ;

    // Initialise A/D FIFO
    Err := ITC_InitializeAcquisition( Device ) ;
    ITC_CheckError( Err, 'ITC_InitializeAcquisition' )  ;

    // Write D/A samples to FIFO
    NumSamplesToWrite := Min(FNumADCSamples*FNumADCChannels,FIFOMaxPoints) ;
    Err := ITC_WriteFIFO( Device, NumSamplesToWrite, DACFIFO ) ;
    ITC_CheckError(Err,'ITC_WriteFIFO') ;

    {Save D/A sweep data }
    DACPointer := Min(FNumADCSamples*FNumADCChannels,FIFOMaxPoints)  ;
    FNumDACPoints := nPoints ;
    FNumDACChannels := NumDACChannels ;

    // Set sampling interval
    Err := ITC_SetSamplingInterval( Device, FTicksPerSample ) ;
    ITC_CheckError( Err, 'ITC_SetSamplingInterval' )  ;

    // Start combined A/D & D/A sweep
    if WaitForExtTrigger then ExternalTrigger := 1
                         else ExternalTrigger := 0 ;
    OutputEnable := 1 ;      // Enable D/A output on interface
    Err := ITC_Start( Device,
                      ExternalTrigger,
                      OutputEnable ) ;
    ITC_CheckError( Err, 'ITC_Start' ) ;

    DACActive := True ;
    ADCActive := True ;
    Result := DACActive ;

    end ;


function ITC_GetDACUpdateInterval : double ;
{ -----------------------
  Get D/A update interval
  -----------------------}
begin
     Result := FADCSamplingInterval ;
     { NOTE. DAC update interval is constrained to be the same
       as A/D sampling interval (set by ITC_ADCtoMemory. }
     end ;


function ITC_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin

     if not DeviceInitialised then ITC_InitialiseBoard ;

     DACActive := False ;
     Result := DACActive ;

     end ;


procedure ITC_WriteDACsAndDigitalPort(
          var DACVolts : array of Single ; // D/A voltage settings [In]
          nChannels : Integer ;            // No. D/A channels to be updated [In]
          DigValue : Integer               // Digital bit valuues [In]
          ) ;
{ ----------------------------------------------------
  Update D/A outputs with voltages suppled in DACVolts
  and TTL digital O/P with bit pattern in DigValue
  ----------------------------------------------------}
const
     NumBlocks = 4;
     MaxDACValue = 32767 ;
     MinDACValue = -32768 ;
var
   DACScale : single ;
   i,ch,DACValue : Integer ;
   Err : Integer ;                  // ITC error number
   iFIFO : Integer ;                // DACFIFO index
   iSEQ : Integer ;                 // Sequence array index
   SequenceLength : Cardinal ;      // No. of elements in sequence
   NumSamplesToWrite : Cardinal ;   // No. of samples to be output to DACs/Digital
   NumSamplesAcquired : Cardinal ;  // No. of A/D samples acquired so far
   ExternalTrigger : Cardinal ;     // Wait for external trigger flag (1=ext)
   OutputEnable : Cardinal ;        // Enable D/A outputs during sweep (1=enable)

begin

     if not DeviceInitialised then ITC_InitialiseBoard ;
     if not DeviceInitialised then Exit ;
     if ADCActive then Exit ;

     // Stop A/D sampling if it running
     if ADCActive then ITC_StopADC ;

     // Scale from Volts to binary integer units
     DACScale := MaxDACValue/FDACVoltageRangeMax ;

     { Fill output FIFO with D/A and digital values  }
     iFIFO := 0 ;
     for i := 0 to NumBlocks-1 do begin
         for ch := 0 to nChannels-1 do begin
             DACValue := Round(DACVolts[ch]*DACScale) ;
             // Keep within legitimate limits
             if DACValue > MaxDACValue then DACValue := MaxDACValue ;
             if DACValue < MinDACValue then DACValue := MinDACValue ;
             DACFIFO^[iFIFO] := DACValue ;
             Inc(iFIFO) ;
             end ;
         DACFIFO^[iFIFO] := DigValue ;
         Inc(iFIFO) ;
         end ;
     NumSamplesToWrite := iFIFO ;

     // Set up FIFO acquisition sequence for A/D input channels
     iSeq := 0 ;
     // Add D/A channels
     for ch := 0 to nChannels-1 do begin
         if ch = 0 then Sequence[iSeq] := INPUT_AD0 or OUTPUT_DA0 or INPUT_UPDATE ;
         if ch = 1 then Sequence[iSeq] := INPUT_AD0 or OUTPUT_DA1 or INPUT_UPDATE ;
         if ch = 2 then Sequence[iSeq] := INPUT_AD0 or OUTPUT_DA2 or INPUT_UPDATE ;
         if ch = 3 then Sequence[iSeq] := INPUT_AD0 or OUTPUT_DA3 or INPUT_UPDATE ;
         Inc(iSeq) ;
         end ;
     // Add digital channel
     Sequence[iSeq] := INPUT_AD0 or OUTPUT_DIGITAL or OUTPUT_UPDATE or INPUT_UPDATE ;
     SequenceLength :=  iSeq + 1 ;

     // Download sequence to interface
     Err := ITC_SetSequence( Device, SequenceLength, Sequence ) ;
     ITC_CheckError( Err, 'ITC_SetSequence' )  ;

     // Initialise A/D-D/A FIFO
     Err := ITC_InitializeAcquisition( Device ) ;
     ITC_CheckError( Err, 'ITC_InitializeAcquisition' )  ;

     // Write D/A samples to FIFO
     Err := ITC_WriteFIFO( Device, NumSamplesToWrite, DACFIFO ) ;
     ITC_CheckError(Err,'ITC_WriteFIFO') ;

     // Set sampling interval
     Err := ITC_SetSamplingInterval( Device, 100 ) ;
     ITC_CheckError( Err, 'ITC_SetSamplingInterval' )  ;

     // Start combined A/D & D/A sweep
     ExternalTrigger := 0 ;   // Start sweep immediately
     OutputEnable := 1 ;      // Enable D/A output on interface
     Err := ITC_Start( Device,
                       ExternalTrigger,
                       OutputEnable ) ;
     ITC_CheckError( Err, 'ITC_Start' ) ;

     // Wait till all channels output
     NumSamplesAcquired := 0 ;
     while NumSamplesAcquired < (NumSamplesToWrite div 2) do begin
           Err := ITC_GetFIFOReadAvailable( Device, NumSamplesAcquired ) ;
           ITC_CheckError(Err,'ITC_GetFIFOReadAvailable') ;
           end ;
     Err := ITC_ReadFIFO( Device, NumSamplesAcquired, DACFIFO ) ;
     ITC_CheckError(Err,'ITC_ReadFIFO') ;

     // Stop A/D + D/A sampling
     ITC_StopADC ;

     end ;


function ITC_ReadADC(
         Channel : Integer ;       // A/D channel
         ADCVoltageRange : Single  // A/D input voltage range
         ) : SmallInt ;
// ---------------------------
// Read Analogue input channel
// ---------------------------
const
     NumSamples = 8 ;
var
   ADRange : Array[0..ITC18_NUMBEROFADCINPUTS-1] of Cardinal ;
   i,ch : Integer ;
   Err : Integer ;
   NumSamplesNeeded : Cardinal ;   // No. of samples to be acquired
   NumSamplesAcquired : Cardinal ;  // No. of A/D samples acquired so far
   ExternalTrigger : Cardinal ;
   OutputEnable : Cardinal ;

begin

     if not DeviceInitialised then ITC_InitialiseBoard ;
     if ADCActive then Exit ;

     if DeviceInitialised then begin

        // Stop A/D sampling if it running
        if ADCActive then ITC_StopADC ;

        // Set A/D input voltage range for all channels
        for i := 0 to FNumADCVoltageRanges do
            if ADCVoltageRange = FADCVoltageRanges[i] then begin
               for ch := 0 to High(ADRange) do ADRange[ch] := i ;
               end ;
        Err := ITC_SetRange( Device, ADRange ) ;
        ITC_CheckError( Err, 'ITC_SetRange' )  ;

        // Set up FIFO acquisition sequence for A/D input channels
        case Channel of
             0 : Sequence[0] := INPUT_AD0 ;
             1 : Sequence[0] := INPUT_AD1 ;
             2 : Sequence[0] := INPUT_AD2 ;
             3 : Sequence[0] := INPUT_AD3 ;
             4 : Sequence[0] := INPUT_AD4 ;
             5 : Sequence[0] := INPUT_AD5 ;
             6 : Sequence[0] := INPUT_AD6 ;
             7 : Sequence[0] := INPUT_AD7 ;
             end ;
        Sequence[0] := Sequence[0] or INPUT_UPDATE ;

        // Download sequence to interface
        Err := ITC_SetSequence( Device, 1, Sequence ) ;
        ITC_CheckError( Err, 'ITC_SetSequence' )  ;

        // Set sampling interval (50 ticks, 50-75 us)
        Err := ITC_SetSamplingInterval( Device, 50 ) ;
        ITC_CheckError( Err, 'ITC_SetSamplingInterval' )  ;

        // Initialise A/D FIFO
        Err := ITC_InitializeAcquisition( Device ) ;
        ITC_CheckError( Err, 'ITC_InitializeAcquisition' )  ;

        // Start A/D sampling
        ExternalTrigger := 0 ;
        OutputEnable := 0 ;
        Err := ITC_Start( Device,
                          ExternalTrigger,
                          OutputEnable ) ;
        ITC_CheckError( Err, 'ITC_START' )  ;

       // Wait till channels acquired
        NumSamplesAcquired := 0 ;
        NumSamplesNeeded := (-OutPointerSkipCount) + 2 ;
        while NumSamplesAcquired < NumSamplesNeeded do begin
              Err := ITC_GetFIFOReadAvailable( Device, NumSamplesAcquired ) ;
              ITC_CheckError(Err,'ITC_GetFIFOReadAvailable') ;
              end ;
        Err := ITC_ReadFIFO( Device, NumSamplesAcquired, ADCFIFO ) ;
        ITC_CheckError(Err,'ITC_ReadFIFO') ;

        // Stop A/D + D/A sampling
        ITC_StopADC ;

        // Return value for selected channel
        Result := ADCFIFO^[-OutPointerSkipCount] ;

        end
     else Result := 0 ;


     end ;


procedure ITC_GetChannelOffsets(
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


procedure ITC_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
begin

     if DeviceInitialised then begin

        { Stop any acquisition in progress }
        ITC_StopADC ;

        { Close connection with interface }
        ITC_Close( Device  ) ;

        // Free device control strucutre
        if Device <> Nil then FreeMem( Device ) ;

        // Free A/D, D/A and digital O/P buffers
        Dispose(ADCFIFO) ;
        Dispose(DACFIFO) ;

        // Free DLL library
        FreeLibrary( LibraryHnd ) ;

        DeviceInitialised := False ;
        DACActive := False ;
        ADCActive := False ;
        end ;

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


Procedure ITC_CheckError(
          Err : Cardinal ;        // Error code
          ErrSource : String ) ;  // Name of procedure which returned Err
// ----------------------------------------------
// Report type and source of ITC interface error
// ----------------------------------------------
const
   MAX_SIZE = 100 ;
var
   MsgBuf: array[0..MAX_SIZE] of char;
begin

   if Err <> ACQ_SUCCESS then begin
      ITC_GetStatusText( device, Err, MsgBuf, MAX_SIZE);
      MessageDlg( ErrSource + ' - ' + StrPas(MsgBuf), mtError, [mbOK], 0) ;
     end ;

   end ;

Initialization
    Device := Nil ;
    LibraryHnd := 0 ;
    InterfaceType := 0 ;
end.
