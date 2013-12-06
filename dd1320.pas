unit Dd1320;
{ =================================================================           *`*`
  Axon Instruments Digidata 1320 Interface Library V1.0
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  8/2/2001
  12/3/2001 Axoutils32.dll now loaded from c:\axon\libs (not \windows\system)
  24/10/01 ... ADCToMemory modified to fix failure to acquire in
               circular buffer mode that occurred after WinEDR V2.2.2
               posssibly due to switch to Delphi V5 compiler
  30/11/01 DigFill now set to correct final value to prevent
  spurious digital O/P changes between records
  12/4/02  c:\axon\axoscope8 and c:\axon\pclamp8 now searched for axdd132x.dll
           since Axon has removed it from system32 folder
  10.2.03  Problems using axDD132x.DLL library supplied with pCLAMP/AxoScope V9
           Now uses older axDD132x.DLL and axoutils32.dll supplied with WinWCP
  18.9.03  axdd132x.dll and axoutils32.dll now loaded from program folder
           DD132X_OpenDevice now tried twice since it didn't work first time
           after device is switched off and on.
  11.2.04  D/A waveform can now be made to wait for external trigger
  02.12.04 Two DAC channels can now be used
           Min. A/D sampling interval limited to above 4us
           No. of A/D samples per sweep increased to 65536
  15.04.05 DD132X_ReadADC now works
  01.09.07 DD132X_GetCalibrationData (rather DD132X_Calibrate) than now used in
           DD132X_InitialiseBoard to avoid "Unable to Calibrate error when WinWCP started)
  16.07.08 D/A output sweep now correctly disabled in ADCtoMemory (was causing spurious
           holding voltage settings when switching between seal test and recording window
           in WinEDR
  07.11.11 LoadLibrary now set to false when library unloaded by DD132X_CloseLaboratoryInterface
  18.11.11 Buffer size increased from 65536 to 1048576
  06.11.13 A/D input channels can now be mapped to different physical inputs
  18.11.13 MemoryToDACAndDigital now works in circular buffer mode
  02.12.13 MemoryToDACAndDigital now works with very large (150s/12Msamples) buffers
           Digital update interval now correct
  =================================================================}

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem,math;
const
     DD132X_MAX_AO_CHANNELS = 8 ;
     DD132X_MAX_AI_CHANNELS = 16 ;
     DD132X_MaxADCSamples = 1048576 ;//Old value 65536 ;
     DD132X_BufferSize = 1000000 ;
     DD132X_MaxSamplesPerSubBuf = 600 ;
     DD132X_NumBuffers = (DD132X_BufferSize div DD132X_MaxSamplesPerSubBuf) + 1 ;

     SecsToMicroSecs = 1E6 ;
     MasterClockPeriod = 1E-9 ;
     DefaultSamplingInterval = 1E-4 ;

     DD132X_PROTOCOL_STOPONTC = 1 ;
     DD132X_PROTOCOL_DIGITALOUTPUT = $0040 ;
     DD132X_PROTOCOL_NULLOUTPUT = $0050 ;
     DD132X_MAXAOCHANNELS = 8;
     DD132X_SCANLIST_SIZE = 64;
// constants for the uEquipmentStatus field.
     DD132X_STATUS_TERMINATOR      = $00000001;
     DD132X_STATUS_DRAM            = $00000002;
     DD132X_STATUS_EEPROM          = $00000004;
     DD132X_STATUS_INSCANLIST      = $00000008;
     DD132X_STATUS_OUTSCANLIST     = $00000010;
     DD132X_STATUS_CALIBRATION_MUX = $00000020;
     DD132X_STATUS_INPUT_FIFO      = $00000040;
     DD132X_STATUS_OUTPUT_FIFO     = $00000080;
     DD132X_STATUS_LINEFREQ_GEN    = $00000100;
     DD132X_STATUS_FPGA            = $00000200;
     DD132X_STATUS_ADC0            = $00000400;
     DD132X_STATUS_DAC0            = $00000800;
     DD132X_STATUS_DAC1            = $00001000;
// constants for SetDebugMsgLevel()
     DD132X_MSG_SHOWALL  = 0;
     DD132X_MSG_SHOWLESS = 1;
     DD132X_MSG_SHOWNONE = 2;


type
{$Z4}
    TDD132X_Triggering = (DD132X_StartImmediately,
                          DD132X_ExternalStart,
                          DD132X_LineTrigger ) ;
    TDD132X_AIDataBits = (DD132X_Bit0Data,
                         DD132X_Bit0ExtStart,
                         DD132X_Bit0Line,
                         DD132X_Bit0Tag,
                         DD132X_Bit0Tag_Bit1ExtStart,
                         DD132X_Bit0Tag_Bit1Line ) ;
{$Z1}
    TLongLong = packed record
                Lo : Cardinal ;
                Hi : Cardinal ;
                end ;

  procedure DD132X_InitialiseBoard ;
  procedure DD132X_LoadLibrary  ;
  procedure DD132X_ReportFailure( const ProcName : string ) ;

  procedure DD132X_ConfigureHardware(
            EmptyFlagIn : Integer ) ;

  function  DD132X_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            NumADCChannels : Integer ;
            NumADCSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean ;
            ADCChannelInputMap : Array of Integer
            ) : Boolean ;

  function DD132X_StopADC : Boolean ;

  procedure DD132X_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;

  procedure DD132X_CheckSamplingInterval(
            var SamplingInterval : Double ;
            var Ticks : Cardinal
            ) ;

function  DD132X_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          NumDACChannels : Integer ;
          NumDACPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean ;
          ExternalTrigger : Boolean ;
          RepeatWaveform  : Boolean
          ) : Boolean ;

  function DD132X_GetDACUpdateInterval : double ;

  function DD132X_StopDAC : Boolean ;

  procedure DD132X_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;

  function  DD132X_GetLabInterfaceInfo(
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

  function DD132X_GetMaxDACVolts : single ;

  function DD132X_ReadADC( Channel : Integer ) : SmallInt ;

  procedure DD132X_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;

  procedure DD132X_CloseLaboratoryInterface ;


   procedure SetBits( var Dest : Word ; Bits : Word ) ;
   procedure ClearBits( var Dest : Word ; Bits : Word ) ;
   function TrimChar( Input : Array of Char ) : string ;
   procedure DD132X_CheckError( Error : Integer ) ;
   procedure DD132X_FillOutputBufferWithDefaultValues ;

implementation

uses SESLabIO ;

type
    TDD132X_Info = packed record
       Length : Cardinal ;
       Adaptor : Byte ;
       Target: Byte ;
       ImageType: Byte ;
       ResetType: Byte ;
       Manufacturer : Array[1..16] of ANSIchar ;
       Name : Array[1..32] of ANSIchar ;
       ProductVersion : Array[1..8] of ANSIchar ;
       FirmwareVersion : Array[1..16] of ANSIchar ;
       InputBufferSize : Cardinal ;
       OutputBufferSize : Cardinal ;
       SerialNumber : Cardinal ;
       ClockResolution : Cardinal ;
       MinClockTicks : Cardinal ;
       MaxClockTicks : Cardinal ;
       Unused: Array[1..280] of Byte ;
       end ;

TDATABUFFER = packed record
   uNumSamples : Cardinal ;      // Number of samples in this buffer.
   uFlags : Cardinal ;           // Flags discribing the data buffer.
   pnData : Pointer ;         // The buffer containing the data.
   psDataFlags : Pointer ;      // Byte Flags split out from the data buffer.
   pNextBuffer : Pointer ;      // Next buffer in the list.
   pPrevBuffer : Pointer ;      // Previous buffer in the list.
   end ;
PDATABUFFER = ^TDATABUFFER ;


TDD132X_Protocol = packed record
              Length : Cardinal ;
              SampleInterval : Double ;
              Flags : Cardinal ;
              DD132X_Triggering : TDD132X_Triggering ;
              DD132X_AIDataBits : TDD132X_AIDataBits ;
              uAIChannels : Cardinal ;
              anAIChannels : Array[0..DD132X_SCANLIST_SIZE-1] of Integer ;
              pAIBuffers : PDataBuffer ;
              uAIBuffers : Cardinal ;
              uAOChannels : Cardinal ;
              anAOChannels : Array[0..DD132X_SCANLIST_SIZE-1] of Integer ;
              pAOBuffers : PDataBuffer ;
              uAOBuffers : Cardinal ;
              uTerminalCount : Int64 ;//TLongLong ;
              Unused : Array[1..264] of Byte ;
              end ;

TDD132X_PowerOnData = packed record
       Length : Cardinal ;
       DigitalOuts : Cardinal ;
       anAnalogOuts : Array[1..DD132X_MAXAOCHANNELS] of SmallInt ;
       end ;

TDD132X_CalibrationData = packed record
       Length : Cardinal ;             // Size of this structure in bytes.
       EquipmentStatus : Cardinal ;    // Bit mask of equipment status flags.
       ADCGainRatio : Double ;     // ADC 0 gain-ratio
       ADCOffset : SmallInt ;      // ADC 0  zero offset
       Unused1 : Array[1..46] of Byte ; // Unused space for more ADCs
       NumberOfDACs : Word ;      // total number of DACs on board
       Unused2 : Array[1..6] of Byte ; // Alignment bytes.
       anDACOffset : Array[0..DD132X_MAXAOCHANNELS-1] of SmallInt ;  // DAC 0 zero offset
       adDACGainRatio : Array[0..DD132X_MAXAOCHANNELS-1] of double ; // DAC 0 gain-ratio
       Unused4 : Array[1..104] of Byte ; // Alignment bytes.
       end ;

TDD132X_FindDevices = Function(var Info : TDD132X_Info ;
                              MaxDevices : Cardinal ;
                              var Error : Integer ) : Integer ; stdcall ;
TDD132X_OpenDevice = Function(Adaptor : Byte ;
                             Target : Byte ;
                             var Error : Integer ) : Integer ; stdcall ;
TDD132X_OpenDeviceEx = Function(Adaptor : Byte ;
                               Target : Byte ;
                               const Ramware : Byte ;
                               ImageSize : Cardinal ;
                               var Error : Integer ) : Integer ; stdcall ;
TDD132X_CloseDevice = Function( Device : Integer ;
                               var Error : Integer ) : WordBool ; stdcall ;
TDD132X_GetDeviceInfo = Function( Device : Integer ;
                                 var DD132X_Info ;
                                 var Error : Integer ) : WordBool ; stdcall ;
TDD132X_Reset = Function( Device : Integer ;
                         var Error : Integer ) : WordBool ; stdcall ;

TDD132X_DownloadRAMware = Function( Device : Integer ;
                                   const RAMware : Byte ;
                                   ImageSize : Cardinal ;
                                   var Error : Integer ) : WordBool ; stdcall ;
// Get/set acquisition protocol information.
TDD132X_SetProtocol = Function( Device : Integer ;
                                var Protocol : TDD132X_Protocol ;
                                var Error : Integer ) : WordBool ; stdcall ;
TDD132X_GetProtocol = Function( Device : Integer ;
                                var Protocol : TDD132X_Protocol ;
                                var Error : Integer ) : WordBool ; stdcall ;
// Start/stop acquisition.
TDD132X_StartAcquisition = Function( Device : Integer ;
                                     var Error : Integer ) : WordBool ; stdcall ;
TDD132X_StopAcquisition = Function( Device : Integer ;
                                    var Error : Integer ) : WordBool ; stdcall ;
TDD132X_IsAcquiring = Function( Device : Integer ) : WordBool ; stdcall ;

// Monitor progress of the acquisition.
TDD132X_GetAcquisitionPosition = Function( Device : Integer ;
                                          var SampleCount : Int64 ;
                                          var Error : Integer ) : WordBool ; stdcall ;
TDD132X_GetNumSamplesOutput = Function( Device : Integer ;
                                       var SampleCount : longInt ;
                                       var Error : Integer ) : WordBool ; stdcall ;

// Single read/write operations.
TDD132X_GetAIValue = Function( Device : Integer ;
                              Channel : Cardinal ;
                              var Value : SmallInt ;
                              var Error : Integer ) : WordBool ; stdcall ;
TDD132X_GetDIValues = Function( Device : Integer ;
                                var Value : DWORD ;
                                var Error : Integer ) : WordBool ; stdcall ;
TDD132X_PutAOValue = Function( Device : Integer ;
                              Channel : Cardinal ;
                              Value : SmallInt ;
                              var Error : Integer ) : WordBool ; stdcall ;
TDD132X_PutDOValues = Function( Device : Integer ;
                              Value : DWORD ;
                              var Error : Integer ) : WordBool ; stdcall ;
TDD132X_GetTelegraphs = Function( Device : Integer ;
                                 FirstChannel : Cardinal ;
                                 var Value : SmallInt ;
                                 Values : Cardinal ;
                                 var Error : Integer ) : WordBool ; stdcall ;

// Calibration & EEPROM interraction.
TDD132X_SetPowerOnOutputs = Function( Device : Integer ;
                                     const PowerOnData : TDD132X_PowerOnData ;
                                     var Error : Integer ) : WordBool ; stdcall ;
TDD132X_GetPowerOnOutputs = Function( Device : Integer ;
                                     var PowerOnData : TDD132X_PowerOnData ;
                                     var Error : Integer ) : WordBool ; stdcall ;
TDD132X_Calibrate = Function( Device : Integer ;
                                     var CalibrationData : TDD132X_CalibrationData ;
                                     var Error : Integer ) : WordBool ; stdcall ;

TDD132X_GetCalibrationData = Function( Device : Integer ;
                                       var CalibrationData : TDD132X_CalibrationData ;
                                       var Error : Integer ) : WordBool ; stdcall ;

// Diagnostic functions.
TDD132X_GetLastErrorText = Function( Device : Integer ;
                                     var Msg : Array of ANSIchar ;
                                     MsgLen : Cardinal ;
                                     var Error : Integer ) : WordBool ; stdcall ;
TDD132X_SetDebugMsgLevel = Function( Device : Integer ;
                                    var Msg : Array of ANSIchar ;
                                    Level : Cardinal ;
                                    var Error : Integer ) : WordBool ; stdcall ;

var

   FADCVoltageRangeMax : single ;    // Max. positive A/D input voltage range
   FADCMinValue : Integer ;          // Max. binary A/D sample value
   FADCMaxValue : Integer ;          // Min. binary A/D sample value
   FDACMinUpdateInterval : Double ;  // Min. D/A update interval (s)

   FADCMinSamplingInterval : single ;  // Min. A/D sampling interval (s)
   FADCMaxSamplingInterval : single ;  // Max. A/D sampling interval (s)

   FDACVoltageRangeMax : single ;      // Max. D/A voltage range (+/-V)

   DeviceInitialised : boolean ; { True if hardware has been initialised }
   EmptyFlag : Integer ;

//   CyclicADCBuffer : Boolean ;
   FADCSweepDone : Boolean ;

   FOutPointer : Integer ;    // A/D sample pointer in O/P buffer
   FNumSamplesRequired : Integer ; // No. of A/D samples to be acquired ;
   FCircularBuffer : Boolean ;     // TRUE = repeated buffer fill mode
   AIBuf : PSmallIntArray ;
   AIFlags : PSmallIntArray ;
   AIPointer : Integer ;
   AIBufNumSamples : Integer ;        // Input buffer size (no. samples)

   NumOutChannels : Integer ;          // No. of channels in O/P buffer
   NumOutPoints : Integer ;            // No. of time points in O/P buffer
   OutPointer : Integer ;              // Pointer to latest value written to AOBuf
   AORepeatWaveform : Boolean ;      // TRUE = repeated output DAC/DIG waveform
   OutValues : PSmallIntArray ;

   AOBuf : PSmallIntArray ;
   AOPointer : Integer ;
   AOBufNumSamples : Integer ;        // Output buffer size (no. samples)
   AONumSamplesOutput : Integer ;
   DACDefaultValue : Array[0..DD132X_MAX_AO_CHANNELS-1] of SmallInt ;
   DIGDefaultValue : Integer ;

   DeviceInfo : TDD132X_Info ;     // DD132X Device information structure
   CalibrationData : TDD132X_CalibrationData ; // DD132X calibration information

   ADCActive : Boolean ;  // A/D sampling in progress flag
   DACActive : Boolean ;  // D/A output in progress flag

   Err : Integer ;                           // Error number returned by Digidata
   OK :Boolean ;                            // Successful operation flag
   ErrorMsg : Array[0..80] of ANSIchar ;         // Error messages returned by Digidata
   AIBufs : Array[0..DD132X_NumBuffers-1] of TDataBuffer ; // D/A data buffer definition records
   AOBufs : Array[0..DD132X_NumBuffers-1] of TDataBuffer ; // A/D sample buffer definition records

// Address pointers to DLL procedures & functions
DD132X_FindDevices : TDD132X_FindDevices ;
DD132X_OpenDevice : TDD132X_OpenDevice ;
DD132X_OpenDeviceEx : TDD132X_OpenDeviceEx ;
DD132X_CloseDevice : TDD132X_CloseDevice ;
DD132X_GetDeviceInfo : TDD132X_GetDeviceInfo ;
DD132X_Reset : TDD132X_Reset ;
DD132X_DownloadRAMware : TDD132X_DownloadRAMware ;
DD132X_SetProtocol : TDD132X_SetProtocol ;
DD132X_GetProtocol : TDD132X_GetProtocol ;
DD132X_StartAcquisition : TDD132X_StartAcquisition ;
DD132X_StopAcquisition : TDD132X_StopAcquisition ;
DD132X_IsAcquiring : TDD132X_IsAcquiring ;
DD132X_GetAcquisitionPosition : TDD132X_GetAcquisitionPosition ;
DD132X_GetNumSamplesOutput : TDD132X_GetNumSamplesOutput ;
DD132X_GetAIValue : TDD132X_GetAIValue ;
DD132X_GetDIValues : TDD132X_GetDIValues ;
DD132X_PutAOValue : TDD132X_PutAOValue ;
DD132X_PutDOValues : TDD132X_PutDOValues ;
DD132X_GetTelegraphs : TDD132X_GetTelegraphs ;
DD132X_SetPowerOnOutputs : TDD132X_SetPowerOnOutputs ;
DD132X_GetPowerOnOutputs : TDD132X_GetPowerOnOutputs ;
DD132X_Calibrate : TDD132X_Calibrate ;
DD132X_GetCalibrationData : TDD132X_GetCalibrationData ;
DD132X_GetLastErrorText : TDD132X_GetLastErrorText ;
DD132X_SetDebugMsgLevel : TDD132X_SetDebugMsgLevel ;

LibraryHnd : THandle ;         // axdd132x.dll library handle
Axoutils32Hnd : THandle ;      // Axoutils.dll library handle
Device : THandle ;             // Digidata device handle
LibraryLoaded : boolean ;      // Libraries loaded flag
Protocol : TDD132X_Protocol ;  // Digidata command protocol



function  DD132X_GetLabInterfaceInfo(
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

     if not DeviceInitialised then DD132X_InitialiseBoard ;
     if not DeviceInitialised then begin
        Result := DeviceInitialised ;
        Exit ;
        end ;

     { Get type of Digidata 1320 }

     { Get device model and firmware details }
     Model := TrimChar(DeviceInfo.Name) + ' V' +
              TrimChar(DeviceInfo.ProductVersion) + ' (' +
              TrimChar(DeviceInfo.FirmwareVersion) + ' firmware)';

     // Define available A/D voltage range options
     ADCVoltageRanges[0] := 10.0 ;
     NumADCVoltageRanges := 1 ;
     FADCVoltageRangeMax := ADCVoltageRanges[0] ;

     // A/D sample value range (16 bits)
     ADCMinValue := -32678 ;
     ADCMaxValue := -ADCMinValue - 1 ;
     FADCMinValue := ADCMinValue ;
     FADCMaxValue := ADCMaxValue ;

     // Upper limit of bipolar D/A voltage range
     DACMaxVolts := 10.0 ;
     FDACVoltageRangeMax := 10.0 ;
     DACMinUpdateInterval := 4E-6 ;
     FDACMinUpdateInterval := DACMinUpdateInterval ;

     // Min./max. A/D sampling intervals
     ADCMinSamplingInterval := 4E-6 ;
     ADCMaxSamplingInterval := 100.0 ;
     FADCMinSamplingInterval := ADCMinSamplingInterval ;
     FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

     Result := DeviceInitialised ;

     end ;


procedure DD132X_LoadLibrary  ;
{ -------------------------------------
  Load AXDD132X.DLL library into memory
  -------------------------------------}
var
     AxoutilsPath : String ; // AxoUtils.DLL file path
     AxDD132xPath : String ; // AxDD132x.DLL file path
begin

     // Support DLLs loaded from program folder
     AxoutilsPath := ExtractFilePath(ParamStr(0)) + 'Axoutils32.DLL' ;
     AxDD132xPath := ExtractFilePath(ParamStr(0)) + 'AxDD132x.DLL' ;

     // Load utilities DLL
     Axoutils32Hnd := LoadLibrary( PChar(AxoutilsPath));
     if Axoutils32Hnd <= 0 then
        ShowMessage( format('%s library not found',[AxoutilsPath])) ;

     // Load main library
     LibraryHnd := LoadLibrary(PChar(AxDD132xPath)) ;
     if LibraryHnd <= 0 then
        ShowMessage( format('%s library not found',[AxDD132xPath])) ;

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @DD132X_FindDevices := GetProcAddress(LibraryHnd,'DD132X_FindDevices') ;
        if @DD132X_FindDevices = Nil then DD132X_ReportFailure('DD132X_FindDevices') ;
        @DD132X_OpenDevice := GetProcAddress(LibraryHnd,'DD132X_OpenDevice') ;
        if @DD132X_OpenDevice = Nil then DD132X_ReportFailure('DD132X_OpenDevice') ;
        @DD132X_OpenDeviceEx := GetProcAddress(LibraryHnd,'DD132X_OpenDeviceEx') ;
        if @DD132X_OpenDeviceEx = Nil then DD132X_ReportFailure('DD132X_OpenDeviceEx') ;
        @DD132X_CloseDevice := GetProcAddress(LibraryHnd,'DD132X_CloseDevice') ;
        if @DD132X_CloseDevice = Nil then DD132X_ReportFailure('DD132X_CloseDevice') ;
        @DD132X_GetDeviceInfo := GetProcAddress(LibraryHnd,'DD132X_GetDeviceInfo') ;
        if @DD132X_GetDeviceInfo = Nil then DD132X_ReportFailure('DD132X_GetDeviceInfo') ;
        @DD132X_Reset := GetProcAddress(LibraryHnd,'DD132X_Reset') ;
        if @DD132X_Reset = Nil then DD132X_ReportFailure('DD132X_Reset') ;
        @DD132X_DownloadRAMware := GetProcAddress(LibraryHnd,'DD132X_DownloadRAMware') ;
        if @DD132X_DownloadRAMware = Nil then DD132X_ReportFailure('DD132X_DownloadRAMware') ;
        @DD132X_SetProtocol := GetProcAddress(LibraryHnd,'DD132X_SetProtocol') ;
        if @DD132X_SetProtocol = Nil then DD132X_ReportFailure('DD132X_SetProtocol') ;
        @DD132X_GetProtocol := GetProcAddress(LibraryHnd,'DD132X_GetProtocol') ;
        if @DD132X_GetProtocol = Nil then DD132X_ReportFailure('DD132X_GetProtocol') ;
        @DD132X_StartAcquisition := GetProcAddress(LibraryHnd,'DD132X_StartAcquisition') ;
        if @DD132X_StartAcquisition = Nil then DD132X_ReportFailure('DD132X_StartAcquisition') ;
        @DD132X_StopAcquisition := GetProcAddress(LibraryHnd,'DD132X_StopAcquisition') ;
        if @DD132X_StopAcquisition = Nil then DD132X_ReportFailure('DD132X_StopAcquisition') ;
        @DD132X_IsAcquiring := GetProcAddress(LibraryHnd,'DD132X_IsAcquiring') ;
        if @DD132X_IsAcquiring = Nil then DD132X_ReportFailure('DD132X_IsAcquiring') ;
        @DD132X_GetAcquisitionPosition := GetProcAddress(LibraryHnd,'DD132X_GetAcquisitionPosition') ;
        if @DD132X_GetAcquisitionPosition = Nil then DD132X_ReportFailure('DD132X_GetAcquisitionPosition') ;
        @DD132X_GetNumSamplesOutput := GetProcAddress(LibraryHnd,'DD132X_GetNumSamplesOutput') ;
        if @DD132X_GetNumSamplesOutput = Nil then DD132X_ReportFailure('DD132X_GetNumSamplesOutput') ;
        @DD132X_GetAIValue := GetProcAddress(LibraryHnd,'DD132X_GetAIValue') ;
        if @DD132X_GetAIValue = Nil then DD132X_ReportFailure('DD132X_GetAIValue') ;
        @DD132X_GetDIValues := GetProcAddress(LibraryHnd,'DD132X_GetDIValues') ;
        if @DD132X_GetDIValues = Nil then DD132X_ReportFailure('DD132X_GetDIValues') ;
        @DD132X_PutAOValue := GetProcAddress(LibraryHnd,'DD132X_PutAOValue') ;
        if @DD132X_PutAOValue = Nil then DD132X_ReportFailure('DD132X_PutAOValue') ;
        @DD132X_PutDOValues := GetProcAddress(LibraryHnd,'DD132X_PutDOValues') ;
        if @DD132X_PutDOValues = Nil then DD132X_ReportFailure('DD132X_PutDOValues') ;
        @DD132X_GetTelegraphs := GetProcAddress(LibraryHnd,'DD132X_GetTelegraphs') ;
        if @DD132X_GetTelegraphs = Nil then DD132X_ReportFailure('DD132X_GetTelegraphs') ;
        @DD132X_SetPowerOnOutputs := GetProcAddress(LibraryHnd,'DD132X_SetPowerOnOutputs') ;
        if @DD132X_SetPowerOnOutputs = Nil then DD132X_ReportFailure('DD132X_SetPowerOnOutputs') ;
        @DD132X_GetPowerOnOutputs := GetProcAddress(LibraryHnd,'DD132X_GetPowerOnOutputs') ;
        if @DD132X_GetPowerOnOutputs = Nil then DD132X_ReportFailure('DD132X_GetPowerOnOutputs') ;
        @DD132X_Calibrate := GetProcAddress(LibraryHnd,'DD132X_Calibrate') ;
        if @DD132X_Calibrate = Nil then DD132X_ReportFailure('DD132X_Calibrate') ;
        @DD132X_GetCalibrationData := GetProcAddress(LibraryHnd,'DD132X_GetCalibrationData') ;
        if @DD132X_GetCalibrationData = Nil then DD132X_ReportFailure('DD132X_GetCalibrationData') ;

        @DD132X_GetLastErrorText := GetProcAddress(LibraryHnd,'DD132X_GetLastErrorText') ;
        if @DD132X_GetLastErrorText = Nil then DD132X_ReportFailure('DD132X_GetLastErrorText') ;
        @DD132X_SetDebugMsgLevel := GetProcAddress(LibraryHnd,'DD132X_SetDebugMsgLevel') ;
        if @DD132X_SetDebugMsgLevel = Nil then DD132X_ReportFailure('DD132X_SetDebugMsgLevel') ;
        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'AXDD132X.DLL library not found' ) ;
          LibraryLoaded := False ;
          end ;
     end ;


procedure DD132X_ReportFailure(
          const ProcName : string
          ) ;
begin
     ShowMessage('AxDD132x.DLL- ' + ProcName + ' not found.') ;
     end ;


function  DD132X_GetMaxDACVolts : single ;
{ -----------------------------------------------------------------
  Return the maximum positive value of the D/A output voltage range
  -----------------------------------------------------------------}

begin
     Result := FDACVoltageRangeMax ;
     end ;


procedure DD132X_InitialiseBoard ;
{ -------------------------------------------
  Initialise Digidata 132X interface hardware
  -------------------------------------------}
var
   ch : Integer ;
   NumTrys : Integer ;
begin

     DeviceInitialised := False ;

     if not LibraryLoaded then DD132X_LoadLibrary ;
     if not LibraryLoaded then Exit ;

     { Find Digidata 132X devices on SCSI bus and retrieve info. }
     DeviceInfo.Length := SizeOf(DeviceInfo) ;
     DD132X_FindDevices(DeviceInfo, 1, Err ) ;
     if Err <> 0 then begin
        DD132X_CheckError(Err) ;
        Exit ;
        end ;

     // Open Digidata 1320X device for use
     // (Note. Try twice to because it sometimes doesn't work first time
     //  after 1320 is switched on)
     NumTrys := 0 ;
     while ((Err <> 0) and (NumTrys < 2)) or (NumTrys = 0) do begin
        Device := DD132X_OpenDevice( DeviceInfo.Adaptor,DeviceInfo.Target,Err ) ;
        Inc(NumTrys) ;
        end ;
     if Err <> 0 then begin
        ShowMessage( 'Unable to open Digidata 132x!') ;
        Exit ;
        end ;

     DACActive := False ;
     // Set A/D & D/A sampling interval (microseconds)
     Protocol.SampleInterval := Round(DefaultSamplingInterval*SecsToMicrosecs) ;

     // Get D/A calibration factors from Digidata interface
     CalibrationData.Length := Sizeof(CalibrationData) ;
     OK := DD132X_GetCalibrationData( Device, CalibrationData, Err ) ;
     if not OK then DD132X_CheckError(Err) ;

     // Set output buffers to default values
     NumOutChannels := CalibrationData.NumberOfDACs + 1 ;
     for ch := 0 to CalibrationData.NumberOfDACs-1 do DACDefaultValue[ch] := -CalibrationData.anDACOffset[ch];
     DIGDefaultValue := 0 ;

     AIBuf := Nil ;
     AIFlags := Nil ;
     AOBuf := Nil ;
     OutValues := Nil ;

     DeviceInitialised := True ;

     end ;


procedure DD132X_ConfigureHardware(
          EmptyFlagIn : Integer ) ;
{ --------------------------------------------------------------------------

  -------------------------------------------------------------------------- }
begin
     EmptyFlag := EmptyFlagIn ;
     end ;


function DD132X_ADCToMemory(
          var HostADCBuf : Array of SmallInt  ;   { A/D sample buffer (OUT) }
          NumADCChannels : Integer ;                   { Number of A/D channels (IN) }
          NumADCSamples : Integer ;                    { Number of A/D samples ( per channel) (IN) }
          var dt : Double ;                       { Sampling interval (s) (IN) }
          ADCVoltageRange : Single ;              { A/D input voltage range (V) (IN) }
          TriggerMode : Integer ;                 { A/D sweep trigger mode (IN) }
          CircularBuffer : Boolean ;               { Repeated sampling into buffer (IN) }
          ADCChannelInputMap : Array of Integer // Physical A/D input channel map
          ) : Boolean ;                           { Returns TRUE indicating A/D started }
{ -----------------------------
  Start A/D converter sampling
  -----------------------------}

var
   i,iPointer,iFlagPointer, iPrev,iNext : Integer ;
   NumSamplesPerSubBuf : Integer ;
   ch : Integer ;
begin
     Result := False ;
     if not DeviceInitialised then DD132X_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Stop any acquisition in progress
     if DD132X_IsAcquiring(Device) then begin
        OK := DD132X_StopAcquisition(Device,Err) ;
        if not OK then DD132X_CheckError(Err) ;
        end ;

     { Select type of recording
          Single sweep = A/D samping terminates when buffer is full
          Cyclic = A/D sampling continues at beginning when buffer is full }
     FCircularBuffer := CircularBuffer ;

     // Set A/D sampling interval (in microseconds)
     Protocol.SampleInterval := Round((dt*1E6)/NumADCChannels) ;

     // Set triggering for A/D sampling
     if TriggerMode = tmExtTrigger then Protocol.DD132X_Triggering := DD132X_ExternalStart
                                   else Protocol.DD132X_Triggering := DD132X_StartImmediately ;

     { Ensure that bit 0 of A/D data word is zero
         (by setting it to unused tag input). So that empty flag cannot occur
         in A/D sample stream }
     Protocol.DD132X_AIDataBits := DD132X_Bit0Tag ;

     // Set up analogue input channel scan list
     Protocol.uAIChannels := NumADCChannels ;
     for ch := 0 to NumADCChannels-1 do Protocol.anAIChannels[ch] := ADCChannelInputMap[ch] ;

     // Allocate A/D input buffers

     // Make sub-buffer contain multiple of both input and output channels
     NumSamplesPerSubBuf := DD132X_MaxSamplesPerSubBuf*NumADCChannels*NumOutChannels ;

//     AIBufNumSamples := (DeviceInfo.InputBufferSize div NumSamplesPerSubBuf)*NumSamplesPerSubBuf ;
     AIBufNumSamples := (DD132X_BufferSize div NumSamplesPerSubBuf)*NumSamplesPerSubBuf ;
     if AIBuf <> Nil then FreeMem(AIBuf) ;
     GetMem( AIBuf, AIBufNumSamples*2 ) ;
     for i := 0 to AIBufNumSamples-1 do AIBuf^[i] := EmptyFlag ;
     if AIFlags <> Nil then FreeMem(AIFlags) ;
     GetMem( AIFlags, AIBufNumSamples*2 ) ;
     Protocol.pAIBuffers := @AIBufs ;

     iPointer := Cardinal(AIBuf) ;
     iFlagPointer := Cardinal(AIFlags) ;
     Protocol.uAIBuffers := Min( AIBufNumSamples div NumSamplesPerSubBuf, High(AIBufs)+1 );
     for i := 0 to Protocol.uAIBuffers-1 do begin
        AIBufs[i].pnData := Pointer(iPointer) ;
        AIBufs[i].uNumSamples := NumSamplesPerSubBuf ;
        AIBufs[i].uFlags := 0 ;
        AIBufs[i].psDataFlags := Pointer(iFlagPointer) ;
        iPointer := iPointer + NumSamplesPerSubBuf*2  ;
        iFlagPointer := iFlagPointer + NumSamplesPerSubBuf*2  ;
        end ;

     // Previous/Next buffer pointers
     for i := 0 to Protocol.uAIBuffers-1 do begin
         iPrev := i-1 ;
         if iPrev < 0 then iPrev := Protocol.uAIBuffers-1 ;
         AIBufs[i].pPrevBuffer := Pointer( Cardinal(@AIBufs) + (iPrev*SizeOf(TDATABuffer)) ) ;
         iNext := i+1 ;
         if iNext >= Protocol.uAIBuffers then iNext := 0 ;
         AIBufs[i].pNextBuffer := Pointer( Cardinal(@AIBufs) + (iNext*SizeOf(TDATABuffer)) ) ;
         end ;

     // Allocate AO buffer


     //AOBufNumSamples := (DeviceInfo.OutputBufferSize div NumSamplesPerSubBuf)*NumSamplesPerSubBuf ;
     AOBufNumSamples := (DD132X_BufferSize div NumSamplesPerSubBuf)*NumSamplesPerSubBuf ;
     if AOBuf <> Nil then FreeMem(AOBuf) ;
     GetMem( AOBuf, AOBufNumSamples*2 ) ;
     Protocol.pAOBuffers := @AOBufs ;

     iPointer := Cardinal(AOBuf) ;
     Protocol.uAOBuffers := Min( AOBufNumSamples div NumSamplesPerSubBuf, High(AOBufs)+1 );
     for i := 0 to Protocol.uAOBuffers-1 do begin
        AOBufs[i].pnData := Pointer(iPointer) ;
        AOBufs[i].uNumSamples := NumSamplesPerSubBuf ;
        AOBufs[i].uFlags := 0 ;
        AOBufs[i].psDataFlags := Nil ;
        iPointer := iPointer + NumSamplesPerSubBuf*2  ;
        end ;

     // Previous/Next buffer pointers
     for i := 0 to Protocol.uAOBuffers-1 do begin
         iPrev := i-1 ;
         if iPrev < 0 then iPrev := Protocol.uAOBuffers-1 ;
         AOBufs[i].pPrevBuffer := Pointer( Cardinal(@AOBufs) + (iPrev*SizeOf(TDATABuffer)) ) ;
         iNext := i+1 ;
         if iNext >= Protocol.uAOBuffers then iNext := 0 ;
         AOBufs[i].pNextBuffer := Pointer( Cardinal(@AOBufs) + (iNext*SizeOf(TDATABuffer)) ) ;
         end ;

     // Enable all analog O/P channels and digital channel
     Protocol.uAOChannels := NumOutChannels ;
     for ch := 0 to Protocol.uAOChannels-2 do Protocol.anAOChannels[ch] := ch ;
     Protocol.anAOChannels[Protocol.uAOChannels-1] := DD132X_PROTOCOL_DIGITALOUTPUT ;

     Protocol.uTerminalCount := 0 ;// 100000000 ;//100000 ;
     // Enable external start of sweep
     Protocol.Flags := 0 ;

     // Start acquisition if waveform generation not required
     if TriggerMode <> tmWaveGen then begin

        // Allocate internal output waveform buffer
        if OutValues <> Nil then FreeMem(OutValues) ;
        NumOutPoints := 5000*NumOutChannels ;
        GetMem( OutValues, NumOutPoints*2 ) ;

        // Clear any existing waveform from output buffer
        DD132X_FillOutputBufferWithDefaultValues ;

        if TriggerMode = tmExtTrigger then Protocol.DD132X_Triggering := DD132X_ExternalStart
                                      else Protocol.DD132X_Triggering := DD132X_StartImmediately ;

        // Download protocol to Digidata interface
        Protocol.Length := SizeOf(Protocol) ;
        OK := DD132X_SetProtocol( Device, Protocol, Err ) ;
        if not OK then DD132X_CheckError(Err) ;

        // Start A/D conversion
        OK := DD132X_StartAcquisition( Device, Err ) ;
        if not OK then DD132X_CheckError(Err) ;

        ADCActive := True ;
        DACActive := False ;

        end ;

     // Initialise A/D buffer pointers used by DD132X_GetADCSamples
     FOutPointer := 0 ;
     AIPointer := 0 ;
     AOPointer := 0 ;
     OutPointer := 0 ;
     FNumSamplesRequired := NumADCChannels*NumADCSamples ;
     FADCSweepDone := False ;

     end ;


function DD132X_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
begin

     if not DeviceInitialised then DD132X_InitialiseBoard ;

     { Stop A/D conversions }
     if DeviceInitialised then begin
        OK := DD132X_IsAcquiring(Device) ;
        if OK then begin
           OK := DD132X_StopAcquisition( Device, Err ) ;
           if not OK then DD132X_CheckError(Err) ;
           end ;
        end ;

     ADCActive := False ;
     DACActive := False ;  // Since A/D and D/A are synchronous D/A stops too
     Result := ADCActive ;

     end ;


procedure DD132X_GetADCSamples(
          var OutBuf : Array of SmallInt ;  { Buffer to receive A/D samples }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
var
    i,MaxOutPointer,NewPoints,NewSamples,NewAONumSamplesOutput,Err : Integer ;
begin

     if not ADCActive then exit ;

     // Transfer new A/D samples to host buffer

     // Determine number of samples acquired
     i := AIPointer + Protocol.uAIChannels - 1 ;
     NewSamples := 0 ;
     while AIBuf^[i] <> EmptyFlag do begin
        i := i + Protocol.uAIChannels ;
        if i >= AIBufNumSamples then i := Protocol.uAIChannels - 1 ;
        NewSamples := NewSamples + Protocol.uAIChannels ;
        end ;
          //outputdebugstring(pchar(format( 'Newsamples=%d',[NewSamples]))) ;

     if FCircularBuffer then begin
        // Circular buffer mode
        for i := 1 to NewSamples do begin
            OutBuf[FOutPointer] := AIBuf^[AIPointer]  ;
            AIBuf^[AIPointer] := EmptyFlag ;
            Inc(AIPointer) ;
            if AIPointer = AIBufNumSamples then AIPointer := 0 ;
            Inc(FOutPointer) ;
            if FOutPointer >= FNumSamplesRequired then FOutPointer := 0 ;
            end ;
        end
     else begin
        // Single sweep mode
        for i := 1 to NewSamples do if
            (FOutPointer < FNumSamplesRequired) then begin
            OutBuf[FOutPointer] := AIBuf[AIPointer]  ;
            AIBuf^[AIPointer] := EmptyFlag ;
            Inc(AIPointer) ;
            if AIPointer = AIBufNumSamples then AIPointer := 0 ;
            Inc(FOutPointer) ;
            end ;

        end ;
     OutBufPointer := FOutPointer ;

     // Update D/A + Dig output buffer
     if DACActive then begin
       // Copy into transfer buffer
       DD132X_GetNumSamplesOutput( Device, NewAONumSamplesOutput, Err);
       MaxOutPointer := NumOutPoints - 1 ;

       NewPoints := NewAONumSamplesOutput - AONumSamplesOutput ;
       AONumSamplesOutput :=  NewAONumSamplesOutput ;
       for i := 0 to NewPoints{*NumOutChannels}-1 do begin
          AOBuf^[AOPointer] := OutValues^[OutPointer] ;
          Inc(AOPointer) ;
          if AOPointer >= AOBufNumSamples then AOPointer := 0 ;
          Inc(OutPointer) ;
          if OutPointer > MaxOutPointer then begin
             if AORepeatWaveform then OutPointer := 0
                                 else OutPointer := OutPointer - NumOutChannels ;
             end ;
          end ;
        end ;

     end ;


procedure DD132X_CheckSamplingInterval(
          var SamplingInterval : Double ;
          var Ticks : Cardinal
          ) ;
{ ---------------------------------------------------
  Convert sampling period from <SamplingInterval> (in s) into
  clocks ticks, Returns no. of ticks in "Ticks"
  ---------------------------------------------------}
begin
  SamplingInterval := Min(Max(SamplingInterval,FADCMinSamplingInterval),
                           FADCMaxSamplingInterval) ;
  Ticks := Round(SamplingInterval*SecsToMicrosecs) ;
  SamplingInterval := Ticks/SecsToMicrosecs ;
	end ;


function  DD132X_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          NumDACChannels : Integer ;
          NumDACPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean ;
          ExternalTrigger : Boolean ;
          RepeatWaveform  : Boolean
          ) : Boolean ;
{ --------------------------------------------------------------
  Send a voltage waveform stored in DACBuf to the D/A converters
  30/11/01 DigFill now set to correct final value to prevent
  spurious digital O/P changes between records
  --------------------------------------------------------------}
var
   i,ch,iTo,iFrom,DigCh,MaxOutPointer : Integer ;
   t,tstep : single ;
begin

    Result := False ;
    if not DeviceInitialised then DD132X_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

    // Stop any acquisition in progress
    if DD132X_IsAcquiring(Device) then DD132X_StopAcquisition(Device,Err) ;

    // Allocate internal output waveform buffer
    // Ensure buffer is a multiple of no. out channels
    NumOutPoints := ((NumDACPoints*Protocol.uAIChannels) div NumOutChannels)*NumOutChannels ;
    if OutValues <> Nil then FreeMem(OutValues) ;
    GetMem( OutValues, NumOutPoints*2 ) ;

    // Copy D/A & digital values into internal buffer
    DigCh := NumOutChannels - 1 ;
    tStep := 1.0 / Protocol.uAIChannels ;
    ch := 0 ;
    for iTo := 0 to NumOutPoints-1 do begin
        iFrom := Round(iTo*tStep) ;
        if ch < NumDACChannels then begin
           OutValues[iTo] := Round( DACValues[(iFrom*NumDACChannels)+ch]/CalibrationData.adDACGainRatio[ch])
                                - CalibrationData.anDACOffset[ch];
           end
        else OutValues[iTo] := DACDefaultValue[ch] ;

        if ch = DigCh then begin
           if DigitalInUse then OutValues^[iTo] := DigValues[iFrom]
                           else OutValues^[iTo] := DIGDefaultValue ;
           end ;

        Inc(ch) ;
        if ch >= NumOutChannels then ch := 0 ;
//        t := t + tStep ;

        end ;

    // Download protocol to DD132X and start/restart acquisition

    // If ExternalTrigger flag is set make D/A output wait for
    // TTL pulse on Trigger In line
    // otherwise set acquisition sweep triggering to start immediately
    if ExternalTrigger then Protocol.DD132X_Triggering := DD132X_ExternalStart
                       else Protocol.DD132X_Triggering := DD132X_StartImmediately ;

    // Fill buffer with data from new waveform
    OutPointer := 0 ;
    MaxOutPointer := NumOutPoints - 1 ;
    for i := 0 to AOBufNumSamples-1 do begin
        AOBuf^[i] := OutValues^[OutPointer] ;
        Inc(OutPointer) ;
        if OutPointer > MaxOutPointer then begin
           if RepeatWaveform then OutPointer := 0
                             else OutPointer := OutPointer - NumOutChannels ;
           end ;
        end ;

    if ExternalTrigger then Protocol.DD132X_Triggering := DD132X_ExternalStart
                       else Protocol.DD132X_Triggering := DD132X_StartImmediately ;

     Protocol.uAOChannels := NumOutChannels ;
     for ch := 0 to Protocol.uAOChannels-2 do Protocol.anAOChannels[ch] := ch ;
     Protocol.anAOChannels[Protocol.uAOChannels-1] := DD132X_PROTOCOL_DIGITALOUTPUT ;

    // Load protocol
    OK := DD132X_SetProtocol( Device, Protocol, Err ) ;
    if not OK then DD132X_CheckError(Err) ;

    // Fill A/D input buffer with empty flags
    for i := 0 to AIBufNumSamples-1 do AIBuf^[i] := EmptyFlag ;

    // Start
    OK := DD132X_StartAcquisition( Device, Err ) ;
    if not OK then DD132X_CheckError(Err) ;
    DD132X_GetNumSamplesOutput( Device, AONumSamplesOutput, Err);

    AIPointer := 0 ;
    AOPointer := 0 ;

    ADCActive := True ;

    AORepeatWaveform := RepeatWaveform ;
    DACActive := True ;
    Result := DACActive ;

    end ;



function DD132X_GetDACUpdateInterval : double ;
{ -----------------------
  Get D/A update interval
  -----------------------}
begin
     Result := (Protocol.SampleInterval*Protocol.uAIChannels)/SecsToMicrosecs ;
     { NOTE. DD132X interfaces only have one clock for both A/D and D/A
       timing. Thus DAC update interval is constrained to be the same
       as A/D sampling interval (set by DD132X_ADC_to_Memory_. }
     end ;


function DD132X_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin

     if not DeviceInitialised then DD132X_InitialiseBoard ;

     DACActive := False ;
     Result := DACActive ;

     end ;


procedure DD132X_WriteDACsAndDigitalPort(
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
   ch,DACValue : Integer ;
   SmallDACValue : SmallInt ;
begin

     if not DeviceInitialised then DD132X_InitialiseBoard ;
     if not DeviceInitialised then exit ;

     // Scale from Volts to binary integer units
     DACScale := MaxDACValue/FDACVoltageRangeMax ;

     { Update D/A channels }
     for ch := 0 to Min(nChannels,DD132X_MAX_AO_CHANNELS)-1 do begin
         // Correct for errors in hardware DAC scaling factor
         DACValue := Round(DACVolts[ch]*DACScale/CalibrationData.adDACGainRatio[ch]) ;
         // Correct for DAC zero offset
         DACValue := DACValue - CalibrationData.anDACOffset[ch];
         // Keep within legitimate limits
         if DACValue > MaxDACValue then DACValue := MaxDACValue ;
         if DACValue < MinDACValue then DACValue := MinDACValue ;
         // Output D/A value
         SmallDACValue := DACValue ;
         if not ADCActive then begin
            OK := DD132X_PutAOValue( Device, ch, SmallDACValue, Err ) ;
            if not OK then  DD132X_CheckError(Err) ;
            end ;
         DACDefaultValue[ch] := SmallDACValue ;

         end ;

     // Set digital outputs
     if not ADCActive then begin
        OK := DD132X_PutDOValues( Device, DigValue, Err ) ;
        if not OK then DD132X_CheckError(Err) ;
        end ;
     DIGDefaultValue := DigValue ;

     // Stop/restart acquisition to flush output buffer
     if ADCActive {DD132X_IsAcquiring(Device)} then begin
        OK := DD132X_StopAcquisition(Device,Err) ;
        if not OK then DD132X_CheckError(Err) ;
        // Fill D/A & digital O/P buffers with default values
        DD132X_FillOutputBufferWithDefaultValues ;
        //
//        Protocol.Length := SizeOf(Protocol) ;
//        OK := DD132X_SetProtocol( Device, Protocol, Err ) ;
//        if not OK then DD132X_CheckError(Err) ;

        OK := DD132X_StartAcquisition(Device,Err) ;
        if not OK then DD132X_CheckError(Err) ;
        AIPointer := 0 ;
        AOPointer := 0 ;
        OutPointer := 0 ;
        end ;

     end ;


function DD132X_ReadADC(
         Channel : Integer // A/D channel
         ) : SmallInt ;
// ---------------------------
// Read Analogue input channel
// ---------------------------
var
   Value : SmallInt ;
   OK : Boolean ;
begin

     Value := 0 ;
     Result := Value ;
     if not DeviceInitialised then DD132X_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     OK := DD132X_GetAIValue( Device, Channel, Value, Err ) ;
     if not OK then DD132X_CheckError(Err) ;
     Result := Value ;

     end ;


procedure DD132X_GetChannelOffsets(
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


procedure DD132X_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
begin

     if not DeviceInitialised then Exit ;

     { Stop any acquisition in progress }
     if DD132X_IsAcquiring(Device) then begin
        OK := DD132X_StopAcquisition(Device,Err) ;
        if not OK then DD132X_CheckError(Err) ;
        end ;

     { Close connection with Digidata 132X device }
     DD132X_CloseDevice( Device, Err ) ;
     if Err <> 0 then DD132X_CheckError(Err) ;

     // Free DLL libraries
     if LibraryHnd > 0 then FreeLibrary( LibraryHnd ) ;
     LibraryLoaded := False ;
     if AxoUtils32Hnd > 0 then FreeLibrary( AxoUtils32Hnd ) ;

     if OutValues <> Nil then FreeMem( OutValues ) ;
     OutValues := Nil ;
     if AOBuf <> Nil then FreeMem( AOBuf ) ;
     AOBuf := Nil ;
     if AIBuf <> Nil then FreeMem( AIBuf ) ;
     AIBuf := Nil ;
     if AIFlags <> Nil then FreeMem( AIFlags ) ;
     AIFlags := Nil ;

     DeviceInitialised := False ;
     DACActive := False ;
     ADCActive := False ;

     end ;


procedure DD132X_CheckError(
          Error : Integer ) ;
{ ------------------------------------------------
  Check error code and display message if required
  ------------------------------------------------ }
const
     DD132X_ERROR_ASPINOTFOUND  = 1;
     DD132X_ERROR_OUTOFMEMORY   = 2;
     DD132X_ERROR_NOTDD132X     = 3;
     DD132X_ERROR_RAMWAREOPEN   = 4;
     DD132X_ERROR_RAMWAREREAD   = 5;
     DD132X_ERROR_RAMWAREWRITE  = 6;
     DD132X_ERROR_RAMWARESTART  = 7;
     DD132X_ERROR_SETAIPROTOCOL = 8;
     DD132X_ERROR_SETAOPROTOCOL = 9;
     DD132X_ERROR_STARTACQ      = 10;
     DD132X_ERROR_STOPACQ       = 11;
     DD132X_ERROR_READDATA      = 12;
     DD132X_ERROR_WRITEDATA     = 13;
     DD132X_ERROR_CALIBRATION   = 14;
     DD132X_ERROR_ASPIERROR     = 1000;
     DD132X_ERROR_CANTCOMPLETE  = 9999;
begin
     if Err <> 0 then begin
        DD132X_GetLastErrorText( Device, ErrorMsg, High(ErrorMsg)+1, Err ) ;
        ShowMessage( TrimChar(ErrorMsg) ) ;
        end ;

     end ;

procedure SetBits( var Dest : Word ; Bits : Word ) ;
{ ---------------------------------------------------
  Set the bits indicated in "Bits" in the word "Dest"
  ---------------------------------------------------}
begin
     Dest := Dest or Bits ;
     end ;


procedure ClearBits( var Dest : Word ; Bits : Word ) ;
{ ---------------------------------------------------
  Clear the bits indicated in "Bits" in the word "Dest"
  ---------------------------------------------------}
var
   NotBits : Word ;
begin
     NotBits := not Bits ;
     Dest := Dest and NotBits ;
     end ;

function TrimChar( Input : Array of ANSIChar ) : string ;
var
   i : Integer ;
   pInput : PANSIChar ;
begin
     pInput := @Input ;
     Result := '' ;
     for i := 0 to StrLen(pInput)-1 do Result := Result + Input[i] ;
     end ;


procedure DD132X_FillOutputBufferWithDefaultValues ;
// --------------------------------------
// Fill output buffer with default values
// --------------------------------------
var
    i,ch,DIGChannel : Integer ;
begin

    // refill input buffer with empty flags
    for i := 0 to AIBufNumSamples-1 do AIBuf^[i] := Emptyflag ;

    // Circular transfer buffer
    ch := 0 ;
    DIGChannel := NumOutChannels - 1 ;
    for i := 0 to AOBufNumSamples-1 do begin
        if ch < DIGChannel then begin
           AOBuf^[i] := DACDefaultValue[ch] ;
           inc(ch) ;
           end
        else begin
           AOBuf^[i] := DIGDefaultValue ;
           ch := 0 ;
           end ;
        end ;

    // Output buffer
    ch := 0 ;
    DIGChannel := NumOutChannels - 1 ;
    for i := 0 to NumOutPoints-1 do begin
        if ch < DIGChannel then begin
           OutValues^[i] := DACDefaultValue[ch] ;
           inc(ch) ;
           end
        else begin
           OutValues^[i] := DIGDefaultValue ;
           ch := 0 ;
           end ;
        end ;

    end ;


initialization
    DeviceInitialised := False ;
    FADCSweepDone := False ;
    ADCActive := False ;
    EmptyFlag := 32767 ;
end.
