unit dd1440;
// ==================================================================
// Molecular devices Digidata 1440 Interface Library V1.0
//  (c) John Dempster, University of Strathclyde, All Rights Reserved
// ==================================================================
// 15.12.07
// 21.10.10 -10V glitch between stimulus sweeps which ocurred for
//          some sampling intervals fixed by disabling
//          stop on terminal count. A/D sampling after end of sweep
//          now continues into dump buffer. D/A waveform extended
//          up to limits of D/A buffer space. Max. A/D samples now
//          by 75% to accommodate this.

interface

  uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem, math ;

const DD1400_ANY_DEVICE      = -1 ;
const DD1400_MAX_AI_CHANNELS = 16;
const DD1400_MAX_AO_CHANNELS = 4;
const DD1400_MAX_TELEGRAPHS  = 4;
const DD1400_MAX_DO_CHANNELS = 16;

//========================================================================================
// Constants for the protocol.

const DD1400_FLAG_EXT_TRIGGER  = $0001;
const DD1400_FLAG_TAG_BIT0     = $0002;
const DD1400_FLAG_STOP_ON_TC   = $0004;
const DD1400_FLAG_SCOPE_OUT    = $0008;


// Active bits in the digital input stream.
const DD1400_BIT_EXT_TRIGGER = $0001;
const DD1400_BIT_EXT_TAG     = $0002;

// Error codes
const DD1400_ERROR                       = $01000000;
const DD1400_ERROR_OUTOFMEMORY           = $01000002;
const DD1400_ERROR_STARTACQ              = $01000006;
const DD1400_ERROR_STOPACQ               = $01000007;
const DD1400_ERROR_READDATA              = $01000009;
const DD1400_ERROR_WRITEDATA             = $0100000A;
const DD1400_ERROR_THREAD_START          = $0100000F;
const DD1400_ERROR_THREAD_TIMEOUT        = $01000010;
const DD1400_ERROR_THREAD_WAIT_ABANDONED = $01000011;
const DD1400_ERROR_OPEN_RAMWARE          = $01000013;
const DD1400_ERROR_DOWNLOAD              = $01000015;
const DD1400_ERROR_OPEN_FPGA             = $01000016;
const DD1400_ERROR_LOAD_FPGA             = $01000017;
const DD1400_ERROR_READ_RAMWARE          = $01000018;
const DD1400_ERROR_SIZE_RAMWARE          = $01000019;
const DD1400_ERROR_READ_FPGA             = $0100001A;
const DD1400_ERROR_SIZE_FPGA             = $0100001B;
const DD1400_ERROR_PIPE_NOT_FOUND        = $0100001E;
const DD1400_ERROR_OVERRUN               = $01000020;
const DD1400_ERROR_UNDERRUN              = $01000021;
const DD1400_ERROR_SETPROTOCOL           = $01000022;
const DD1400_ERROR_SETAOVALUE            = $01000023;
const DD1400_ERROR_SETDOVALUE            = $01000024;
const DD1400_ERROR_GETAIVALUE            = $01000025;
const DD1400_ERROR_GETDIVALUE            = $01000026;
const DD1400_ERROR_READTELEGRAPHS        = $01000027;
const DD1400_ERROR_READCALIBRATION       = $01000028;
const DD1400_ERROR_WRITECALIBRATION      = $01000029;
const DD1400_ERROR_READEEPROM            = $0100002A;
const DD1400_ERROR_WRITEEEPROM           = $0100002B;
const DD1400_ERROR_SETTHRESHOLD          = $0100002C;
const DD1400_ERROR_GETTHRESHOLD          = $0100002D;
const DD1400_ERROR_NOTPRESENT            = $0100002E;
const DD1400_ERROR_USB1NOTSUPPORTED      = $0100002F;

const DD1400_ERROR_DEVICEERROR           = $03000000;

const DD1400_ERROR_SYSERROR              = $02000000;

// All error codes from AXDD1400.DLL have one of these bits set.
const DD1400_ERROR_MASK                  = $FF000000;

type

TDATABUFFER = packed record
   uNumSamples : Cardinal ;      // Number of samples in this buffer.
   uFlags : Cardinal ;           // Flags discribing the data buffer.
   pnData : Pointer ;         // The buffer containing the data.
   psDataFlags : Pointer ;      // Byte Flags split out from the data buffer.
   pNextBuffer : Pointer ;      // Next buffer in the list.
   pPrevBuffer : Pointer ;      // Previous buffer in the list.
   end ;
PDATABUFFER = ^TDATABUFFER ;

//
// Define a linked list structure for holding floating point acquisition buffers.
//
TFLOATBUFFER = packed record
   uNumSamples : Cardinal ;  // Number of samples in this buffer.
   uFlags : Cardinal ;       // Flags discribing the data buffer.
   pfData : Pointer ;       // The buffer containing the data.
   pNextBuffer : Pointer ;          // Next buffer in the list.
   pPrevBuffer : Pointer ;          // Previous buffer in the list.
   end ;
PFLOATBUFFER = ^TFLOATBUFFER ;

TDD1440_Info = packed record
   VendorID : Word ;
   ProductID : Word ;
   SerialNumber : Cardinal ;
   Name : Array[0..31] of char ;
   FirmwareVersion : Array[0..15] of char ;
   InputBufferSamples : Cardinal ;
   OutputBufferSamples : Cardinal ;
   AIChannels : Cardinal ;
   AOChannels : Cardinal ;
   Telegraphs : Cardinal ;
   DOChannels : Cardinal ;           // (bits)
   MinSequencePeriodUS : Double ;
   MaxSequencePeriodUS : Double ;
   SequenceQuantaUS : Double ;
   MinPrequeueSamples : Cardinal ;
   MaxPrequeueSamples : Cardinal ;
   ScopeOutBit : Word ;
   USB1 : LongBool ;
   end ;

//==============================================================================================
// STRUCTURE: DD1400_Protocol
// PURPOSE:   Describes acquisition settings.
//

TDD1440_Protocol = packed record
   dSequencePeriodUS : Double ;       // Sequence interval in us.
   uFlags : Cardinal ;                // Boolean flags that control options.

   nScopeOutAIChannel : Integer ;     // Analog Input to generate "Scope Output" pulse
   nScopeOutThreshold : SmallInt ;    // "Scope Output"=on threshold level  [cnts]
   nScopeOutHysteresis : SmallInt ;   // "Scope Output"=on hysterisis delta [cnts]
   bScopeOutPolarity : ByteBool ;    // TRUE = positive polarity.

   // Inputs:
   uAIChannels : Cardinal ;
   anAIChannels: Array[0..DD1400_MAX_AI_CHANNELS-1] of Integer ;
   pAIBuffers : Pointer ;
   uAIBuffers : Cardinal ;
   bDIEnable : ByteBool ;
   bUnused1 : Array[1..3] of ByteBool ;        // (alignment padding)

   // Outputs:
   uAOChannels : Cardinal ;
   anAOChannels : Array[0..DD1400_MAX_AO_CHANNELS-1] of Integer ;
   pAOBuffers : Pointer ;
   uAOBuffers : Cardinal ;
   bDOEnable : ByteBool ;
   bUnused2 : Array[1..3] of ByteBool ;        // (alignment padding)

   uChunksPerSecond : Cardinal ;   // Granularity of data transfer.
   uTerminalCount : Cardinal ;     // If DD1400_FLAG_STOP_ON_TC this is the count.

   // DEBUG
   bSaveAI : ByteBool ;
   bSaveAO : ByteBool ;

   end ;

//==============================================================================================
// STRUCTURE: DD1400_Calibration
// PURPOSE:   Describes calibration constants for data correction.
//
TDD1440_Calibration = packed record

   anADCGains : Array[0..DD1400_MAX_AI_CHANNELS-1] of SmallInt ;    // Get/Set
   anADCOffsets : Array[0..DD1400_MAX_AI_CHANNELS-1] of SmallInt ;  // Get/Set

   afDACGains : Array[0..DD1400_MAX_AO_CHANNELS-1] of Single ;    // Get
   anDACOffsets : Array[0..DD1400_MAX_AO_CHANNELS-1] of SmallInt ;  // Get
   end ;

//==============================================================================================
// STRUCTURE: DD1400_PowerOnData
// PURPOSE:   Contains items that are set in the EEPROM of the DD1400 as power-on defaults.
//
TDD1440_PowerOnData = packed record
   uDigitalOuts : Cardinal ;
   anAnalogOuts : Array[0..DD1400_MAX_AO_CHANNELS-1] of SmallInt;
   end ;

//==============================================================================================
// STRUCTURE: Start acquisition info.
// PURPOSE:   To store the start acquisition time and precision, by querying a high resolution
//            timer before and after the start acquisition SCSI command.
//
TDD1440_StartAcqInfo = packed record
   StartTime : Integer ; // SYSTEMTIME? Stores the time and date of the begginning of the acquisition.
   n64PreStartAcq : Int64 ;   // Stores the high resolution counter before the acquisition start.
   n64PostStartAcq : Int64 ;  // Stores the high resolution counter after the acquisition start.
   end ;


TDD1440_Reset = Function : ByteBool ;  cdecl;

TDD1440_GetDeviceInfo = Function(

                        pInfo : Pointer
                        ) : ByteBool ;  cdecl;

TDD1440_SetSerialNumber = Function (
                          
                          uSerialNumber : cardinal
                          ) : ByteBool ;  cdecl;

TDD1440_GetBufferGranularity =   Function  : Cardinal ;  cdecl;

TDD1440_SetProtocol =   Function(
                        
                        var DD1400_Protocol : TDD1440_Protocol
                        //DD1400_Protocol : Pointer
                        ) : ByteBool ;  cdecl;

TDD1440_GetProtocol =   Function (

                        var DD1400_Protocol : TDD1440_Protocol
                        ) : ByteBool ;  cdecl;

TDD1440_StartAcquisition =   Function : ByteBool ;  cdecl;
TDD1440_StopAcquisition =   Function  : ByteBool ;  cdecl;
TDD1440_IsAcquiring =   Function  : ByteBool ;  cdecl;

TDD1440_GetAIPosition =   Function(
                          
                          var uSequences : Int64) : ByteBool ;  cdecl;
TDD1440_GetAOPosition =   Function(
                          var uSequences : Int64) : ByteBool ;  cdecl;

TDD1440_GetAIValue = Function(
                     
                     uAIChannel : Cardinal ;
                     var nValue : SmallInt
                      ) : ByteBool ;  cdecl;
TDD1440_GetDIValue = Function (
                     
                     var wValue : Word
                     ) : ByteBool ;  cdecl;

TDD1440_SetAOValue =   Function (
                       
                       uAOChannel : Cardinal ;
                       nValue : SmallInt ) : ByteBool ;  cdecl;
TDD1440_SetDOValue =   Function (

                       wValue : Word
                       ) : ByteBool ;  cdecl;

TDD1440_SetTrigThreshold =   Function (

                             nValue : SmallInt
                             ) : ByteBool ;  cdecl;
TDD1440_GetTrigThreshold =   Function (
                             
                             var nValue : SmallInt
                             ) : ByteBool ;  cdecl;

TDD1440_ReadTelegraphs =   Function (
                           
                           uFirstChannel : Cardinal ;
                           var pnValue : SmallInt ;
                           uValues : Cardinal
                           ) : ByteBool ;  cdecl;

TDD1440_GetTimeAtStartOfAcquisition =   procedure (

                                        var StartAcqInfo : TDD1440_StartAcqInfo
                                        ) ; cdecl;

TDD1440_GetCalibrationParams =   Function (
                                  
                                  var Params : TDD1440_Calibration
                                  ) : ByteBool ;  cdecl;

TDD1440_SetCalibrationParams = Function (
                               
                               const Params : TDD1440_Calibration
                               ) : ByteBool ;  cdecl;

TDD1440_GetPowerOnData = Function(
                         
                         var Data : TDD1440_PowerOnData
                         ) : ByteBool ;  cdecl;
TDD1440_SetPowerOnData =   Function (
                           
                           const Data : TDD1440_PowerOnData
                           )  : ByteBool ;  cdecl;

TDD1440_GetEepromParams =   Function (
                            
                            pvEepromImage : pointer ;
                            uBytes : Cardinal
                            )  : ByteBool ;  cdecl;
TDD1440_SetEepromParams =   Function (
                            
                            pvEepromImage : Pointer ;
                            uBytes : Cardinal
                            )  : ByteBool ;  cdecl;

TDD1440_GetLastErrorText =   Function(

                            pszMsg : PChar ;
                            uMsgLen : Cardinal
                            ) : ByteBool ;  cdecl;
TDD1440_GetLastError =   Function : Integer ;  cdecl;

// Find, Open & close device.

TDD1440_CountDevices = Function : cardinal ; cdecl ;

TDD1440_FindDevices = Function(
                      pInfo : Pointer ;
                      uMaxDevices : Cardinal ;
                      var Error : Integer ) : cardinal ; cdecl ;

TDD1440_GetErrorText = Function(
                       nError : Integer ;
                       pszMsg : PChar ;
                       uMsgLen : Integer ) : ByteBool ; cdecl ;

TDD1440_OpenDevice = Function(
                     uSerialNumber : Cardinal ;
                     var Error : Integer ) : Pointer ; cdecl ;

TDD1440_CloseDevice = procedure ;

// Utility functions

TDD1440_VoltsToDAC = Function(
                     var CalData : TDD1440_Calibration ;
                     uDAC : Cardinal ;
                     dVolts : Double ) : Integer ; cdecl {DAC_VALUE} ;

TDD1440_DACtoVolts = Function(
                     var CalData : TDD1440_Calibration ;
                     uDAC : Cardinal ;
                     nDAC : Integer ) : Double ;

TDD1440_VoltsToADC = Function(
                     dVolts : double
                     ) : Integer ; cdecl {ADC_VALUE} ;

TDD1440_ADCtoVolts = Function(
                     nADC : Integer ) : Double ; cdecl ;


  procedure DD1440_InitialiseBoard ;
  procedure DD1440_LoadLibrary  ;

  procedure DD1440_ConfigureHardware(
            EmptyFlagIn : Integer ) ;

  function  DD1440_ADCToMemory(
            HostADCBuf : Pointer ;
            NumADCChannels : Integer ;
            NumADCSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;

  function DD1440_StopADC : Boolean ;

  procedure DD1440_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;

  procedure DD1440_CheckSamplingInterval(
            var SamplingInterval : Double  ) ;

  function  DD1440_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ; // D/A output values
          NumDACChannels : Integer ;                // No. D/A channels
          NumDACPoints : Integer ;                  // No. points per channel
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : Boolean ;             // Output to digital outs
          ExternalTrigger : Boolean            // Wait for ext. trigger
          ) : Boolean ;                        // before starting output

  function DD1440_GetDACUpdateInterval : double ;

  function DD1440_StopDAC : Boolean ;

  procedure DD1440_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;

  function  DD1440_GetLabInterfaceInfo(
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

  function DD1440_GetMaxDACVolts : single ;

  function DD1440_ReadADC( Channel : Integer ) : SmallInt ;

  procedure DD1440_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;

  procedure DD1440_CloseLaboratoryInterface ;

  function  DD1440_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }



   function TrimChar( Input : Array of Char ) : string ;
   procedure DD1440_CheckError( OK : ByteBool ) ;


implementation

uses seslabio ;

const
    DD1440_MaxADCSamples = 32768*16 ;
    NumPointsPerBuf = 256 ;
    MaxBufs = (DD1440_MaxADCSamples div NumPointsPerBuf) + 2 ;
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

   FADCSweepDone : Boolean ;

   FADCBuf : Integer ;        // A/D buffer pointer
   FADCPointer : Integer ;    // A/D sample pointer
   FOutPointer : Integer ;    // A/D sample pointer in O/P buffer
   FNumSamplesRequired : Integer ; // No. of A/D samples to be acquired ;


   ADCActive : Boolean ;  // A/D sampling in progress flag
   DACActive : Boolean ;  // D/A output in progress flag

   Err : Integer ;                           // Error number returned by Digidata
   ErrorMsg : Array[0..80] of char ;         // Error messages returned by Digidata

   LibraryHnd : THandle ;         // axDD1440.dll library handle
   LibraryLoaded : boolean ;      // Libraries loaded flag
   Protocol : TDD1440_Protocol ;  // Digidata command protocol
   NumDevices : Integer ;
   DeviceInfo : Array[0..7] of TDD1440_Info ;

   Calibration : TDD1440_Calibration ; // Calibration parameters

   FDACValues : PSmallIntArray ;
   ADCDumpBuf : PSmallIntArray ;
   ADCBufs : Array[0..MaxBufs-1] of TDATABUFFER ;
   DACBufs : Array[0..MaxBufs-1] of TDATABUFFER ;

  DD1440_CountDevices : TDD1440_CountDevices ;
  DD1440_FindDevices : TDD1440_FindDevices ;
  DD1440_GetErrorText : TDD1440_GetErrorText ;
  DD1440_OpenDevice : TDD1440_OpenDevice ;
  DD1440_CloseDevice : TDD1440_CloseDevice;
  DD1440_VoltsToDAC : TDD1440_VoltsToDAC ;
  DD1440_DACtoVolts : TDD1440_DACtoVolts;
  DD1440_VoltsToADC : TDD1440_VoltsToADC ;
  DD1440_ADCtoVolts : TDD1440_ADCtoVolts ;
  DD1440_Reset : TDD1440_Reset ;
  DD1440_GetDeviceInfo : TDD1440_GetDeviceInfo ;
  DD1440_SetSerialNumber : TDD1440_SetSerialNumber ;
  DD1440_GetBufferGranularity : TDD1440_GetBufferGranularity;
  DD1440_SetProtocol : TDD1440_SetProtocol ;
  DD1440_GetProtocol : TDD1440_GetProtocol;
  DD1440_StartAcquisition : TDD1440_StartAcquisition ;
  DD1440_StopAcquisition : TDD1440_StopAcquisition ;
  DD1440_IsAcquiring : TDD1440_IsAcquiring ;
  DD1440_GetAIPosition : TDD1440_GetAIPosition;
  DD1440_GetAOPosition : TDD1440_GetAOPosition;
  DD1440_GetAIValue : TDD1440_GetAIValue ;
  DD1440_GetDIValue : TDD1440_GetDIValue ;
  DD1440_SetAOValue : TDD1440_SetAOValue ;
  DD1440_SetDOValue : TDD1440_SetDOValue ;
  DD1440_SetTrigThreshold : TDD1440_SetTrigThreshold ;
  DD1440_GetTrigThreshold : TDD1440_GetTrigThreshold ;
  DD1440_ReadTelegraphs : TDD1440_ReadTelegraphs ;
  DD1440_GetTimeAtStartOfAcquisition : TDD1440_GetTimeAtStartOfAcquisition ;
  DD1440_GetCalibrationParams : TDD1440_GetCalibrationParams ;
  DD1440_SetCalibrationParams : TDD1440_SetCalibrationParams;
  DD1440_GetPowerOnData : TDD1440_GetPowerOnData ;
  DD1440_SetPowerOnData : TDD1440_SetPowerOnData ;
  DD1440_GetEepromParams : TDD1440_GetEepromParams ;
  DD1440_SetEepromParams : TDD1440_SetEepromParams;
  DD1440_GetLastErrorText : TDD1440_GetLastErrorText ;
  DD1440_GetLastError : TDD1440_GetLastError ;

// Find, Open & close device.



function  DD1440_GetLabInterfaceInfo(
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

     if not DeviceInitialised then DD1440_InitialiseBoard ;
     if not DeviceInitialised then begin
        Result := DeviceInitialised ;
        Exit ;
        end ;

     { Get type of Digidata 1320 }


     { Get device model and firmware details }
     Model := TrimChar(DeviceInfo[0].Name) + ' V' +
              TrimChar(DeviceInfo[0].FirmwareVersion) + ' firmware)';

     // Define available A/D voltage range options
     ADCVoltageRanges[0] := 10.0 ;
     NumADCVoltageRanges := 1 ;
     FADCVoltageRangeMax := ADCVoltageRanges[0] ;

     // A/D sample value range (16 bits)
     ADCMinValue := -32678 ;
     ADCMaxValue := -ADCMinValue - 1 ;
     FADCMinValue := ADCMinValue ;
     FADCMaxValue := ADCMaxValue ;

     // Min./max. A/D sampling intervals

     // Note. min. sampling interval is 1.2X greater than MinSequencePeriodUS
     // to avoid overshoot on DAC update at highest sampling rates. DAC
     // possibly has inadequate response rate for 250kHz updates.

     ADCMinSamplingInterval := 1.2*DeviceInfo[0].MinSequencePeriodUS*1E-6 ;

     ADCMaxSamplingInterval := DeviceInfo[0].MaxSequencePeriodUS*1E-6 ;
     FADCMinSamplingInterval := ADCMinSamplingInterval ;
     FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

     ADCBufferLimit := Min( DeviceInfo[0].InputBufferSamples,DD1440_MaxADCSamples ) ;
     // A/D sample buffer limit reduced to 75% of maz. to allow for
     // dump buffer at end of sweeps
     ADCBufferLimit := 256*(round(ADCBufferLimit*0.75) div 256) ;

     // Upper limit of bipolar D/A voltage range
     DACMaxVolts := 10.0 ;
     FDACVoltageRangeMax := 10.0 ;
     DACMinUpdateInterval := 4E-6 ;
     FDACMinUpdateInterval := DACMinUpdateInterval ;

     GetMem( FDACValues, DD1440_MaxADCSamples*4*2 ) ;
     GetMem( ADCDumpBuf, DD1440_MaxADCSamples*2 ) ;

     Result := DeviceInitialised ;

     end ;


procedure DD1440_LoadLibrary  ;
{ -------------------------------------
  Load AXDD1440.DLL library into memory
  -------------------------------------}
var
     DD1440Path : String ; // AxDD1440.DLL file path
begin

     // Support DLLs loaded from program folder
     //AxoutilsPath := ExtractFilePath(ParamStr(0)) + 'Axdd1400.DLL' ;
     //AxoUtils32Hnd := LoadLibrary(PChar(AxoutilsPath)) ;

     DD1440Path := ExtractFilePath(ParamStr(0)) + 'DD1440.DLL' ;

     // Load utilities DLL
 //    Axoutils32Hnd := LoadLibrary( PChar(AxoutilsPath));
 //    if Axoutils32Hnd <= 0 then
 //       ShowMessage( format('%s library not found',[AxoutilsPath])) ;

     // Load main library
     LibraryHnd := LoadLibrary(PChar(DD1440Path)) ;
     if LibraryHnd <= 0 then
        ShowMessage( format('%s library not found',[DD1440Path])) ;

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin

        @DD1440_CountDevices := DD1440_LoadProcedure(LibraryHnd,'DD1440_CountDevices') ;
        @DD1440_FindDevices := DD1440_LoadProcedure(LibraryHnd,'DD1440_FindDevices') ;
        @DD1440_GetErrorText := DD1440_LoadProcedure(LibraryHnd,'DD1440_GetErrorText') ;
        @DD1440_OpenDevice := DD1440_LoadProcedure(LibraryHnd,'DD1440_OpenDevice') ;
        @DD1440_CloseDevice := DD1440_LoadProcedure(LibraryHnd,'DD1440_CloseDevice') ;
        @DD1440_VoltsToDAC := DD1440_LoadProcedure(LibraryHnd,'DD1440_VoltsToDAC') ;
        @DD1440_DACtoVolts := DD1440_LoadProcedure(LibraryHnd,'DD1440_DACtoVolts') ;
        @DD1440_VoltsToADC := DD1440_LoadProcedure(LibraryHnd,'DD1440_VoltsToADC') ;
        @DD1440_ADCtoVolts := DD1440_LoadProcedure(LibraryHnd,'DD1440_ADCtoVolts') ;

        @DD1440_GetTrigThreshold  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetTrigThreshold') ;
        @DD1440_SetTrigThreshold  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetTrigThreshold') ;
        @DD1440_SetDOValue  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetDOValue') ;
        @DD1440_SetAOValue  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetAOValue') ;
        @DD1440_GetDIValue  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetDIValue') ;
        @DD1440_GetAIValue  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetAIValue') ;
        @DD1440_GetAOPosition  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetAOPosition') ;
        @DD1440_GetAIPosition  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetAIPosition') ;
        @DD1440_IsAcquiring  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_IsAcquiring') ;
        @DD1440_StopAcquisition  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_StopAcquisition') ;
        @DD1440_StartAcquisition  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_StartAcquisition') ;
        @DD1440_GetProtocol  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetProtocol') ;
        @DD1440_SetProtocol  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetProtocol') ;
//        @DD1440_GetBufferGranularity  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetBufferGranularity') ;
        @DD1440_SetSerialNumber  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetSerialNumber') ;
        @DD1440_GetDeviceInfo  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetDeviceInfo') ;
//        @DD1440_Reset  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_Reset') ;
        @DD1440_ReadTelegraphs  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_ReadTelegraphs') ;
        @DD1440_GetTimeAtStartOfAcquisition  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetTimeAtStartOfAcquisition') ;
        @DD1440_GetCalibrationParams  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetCalibrationParams') ;
        @DD1440_SetCalibrationParams  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetCalibrationParams') ;
        @DD1440_SetPowerOnData  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetPowerOnData') ;
        @DD1440_GetPowerOnData  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetPowerOnData') ;
        @DD1440_GetEepromParams  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetEepromParams') ;
        @DD1440_SetEepromParams  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_SetEepromParams') ;
        @DD1440_GetLastErrorText  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetLastErrorText') ;
        @DD1440_GetLastError  := DD1440_LoadProcedure( LibraryHnd, 'DD1440_GetLastError') ;
        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'DD1440.DLL library not found' ) ;
          LibraryLoaded := False ;
          end ;
     end ;


function  DD1440_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }
{ ----------------------------
  Get address of DLL procedure
  ----------------------------}
var
   P : Pointer ;
begin
     P := GetProcAddress(Hnd,PChar(Name)) ;
     if P = Nil then begin
        ShowMessage(format('DD1440.DLL- %s not found',[Name])) ;
        end ;
     Result := P ;
     end ;




function  DD1440_GetMaxDACVolts : single ;
{ -----------------------------------------------------------------
  Return the maximum positive value of the D/A output voltage range
  -----------------------------------------------------------------}

begin
     Result := FDACVoltageRangeMax ;
     end ;


procedure DD1440_InitialiseBoard ;
{ -------------------------------------------
  Initialise Digidata 1200 interface hardware
  -------------------------------------------}
var
   ch : Integer ;
begin

     DeviceInitialised := False ;

     if not LibraryLoaded then DD1440_LoadLibrary ;
     if not LibraryLoaded then Exit ;

     // Determine number of available DD1440s
     NumDevices := DD1440_CountDevices ;

     if NumDevices <= 0 then begin
        ShowMessage('No Digidata 1440 devices available!') ;
        exit ;
        end ;

     // Get information from DD1440 devices
     DD1440_FindDevices(@DeviceInfo, High(DeviceInfo)+1, Err ) ;
     if Err <> 0 then begin
        DD1440_CheckError(True) ;
        Exit ;
        end ;

     DD1440_OpenDevice( DeviceInfo[0].SerialNumber, Err ) ;
     if Err <> 0 then begin
        DD1440_CheckError(True) ;
        Exit ;
        end ;

     // Get calibration parameters
     DD1440_GetCalibrationParams( Calibration ) ;
     for ch := 0 to High(Calibration.afDACGains) do
         if Calibration.afDACGains[ch] = 0.0 then Calibration.afDACGains[ch] := 1.0 ;
     DACActive := False ;

     DeviceInitialised := True ;

     end ;


procedure DD1440_ConfigureHardware(
          EmptyFlagIn : Integer ) ;
{ --------------------------------------------------------------------------

  -------------------------------------------------------------------------- }
begin
     EmptyFlag := EmptyFlagIn ;
     end ;


function DD1440_ADCToMemory(
          HostADCBuf : Pointer  ;   { A/D sample buffer (OUT) }
          NumADCChannels : Integer ;                   { Number of A/D channels (IN) }
          NumADCSamples : Integer ;                    { Number of A/D samples ( per channel) (IN) }
          var dt : Double ;                       { Sampling interval (s) (IN) }
          ADCVoltageRange : Single ;              { A/D input voltage range (V) (IN) }
          TriggerMode : Integer ;                 { A/D sweep trigger mode (IN) }
          CircularBuffer : Boolean                { Repeated sampling into buffer (IN) }
          ) : Boolean ;                           { Returns TRUE indicating A/D started }
{ -----------------------------
  Start A/D converter sampling
  -----------------------------}

var
   i : Word ;
   ch,nBufs,nPoints,iPrev,iNext : Integer ;
   ADCPointer : Pointer ;
begin
     Result := False ;
     if not DeviceInitialised then DD1440_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Initialise A/D buffer pointers used by DD1440_GetADCSamples
     FADCPointer := 0 ;
     FADCBuf := 0 ;
     FOutPointer := 0 ;
     FNumSamplesRequired := NumADCChannels*NumADCSamples ;
     FADCSweepDone := False ;

     // Clear protocol flags
     Protocol.uFlags := 0 ;

     // Sampling interval
     Protocol.dSequencePeriodUS := dt*1E6 ;

     // Set analog input channels
     Protocol.uAIChannels := NumADCChannels ;
     for ch := 0 to Protocol.uAIChannels-1 do Protocol.anAIChannels[ch] := ch ;

     // Allocate A/D data Buffers

     Protocol.pAIBuffers := @ADCBufs ;

     ADCPointer := HostADCBuf ;
     nPoints := FNumSamplesRequired ;
     nBufs := 0 ;
     while nPoints > 0 do begin

        ADCBufs[nBufs].pnData := ADCPointer ;
        ADCBufs[nBufs].uNumSamples := Min(nPoints,NumPointsPerBuf) ;
        ADCBufs[nBufs].uFlags := 0 ;
        ADCBufs[nBufs].psDataFlags := Nil ;

        // Pointer to data
        ADCPointer := Pointer( Cardinal(ADCPointer) + (ADCBufs[nBufs].uNumSamples*2) ) ;

        nPoints :=  nPoints - ADCBufs[nBufs].uNumSamples ;

        Inc(nBufs) ;

        if nBufs > High(ADCBufs) then Break ;

        // Pointer to data
        ADCPointer := Pointer( Cardinal(ADCPointer) + (ADCBufs[nBufs].uNumSamples*2) ) ;

        nPoints :=  nPoints - ADCBufs[nBufs].uNumSamples ;

        Inc(nBufs) ;

        // Add end of sweep dump buffer if not in circular collection mode
        // (All samples after terminal count are dumped here rather than
        //  placed by host buffer)
        if (nPoints = 0) and (not CircularBuffer) then begin
           ADCBufs[nBufs].pnData := ADCDumpBuf ;
           ADCBufs[nBufs].uNumSamples := DeviceInfo[0].InputBufferSamples ;
           ADCBufs[nBufs].uFlags := 0 ;
           ADCBufs[nBufs].psDataFlags := Nil ;
           Inc(nBufs) ;
           end ;

        end ;

     // Previous/Next buffer pointers
     for i := 0 to nBufs-1 do begin
         iPrev := i-1 ;
         if iPrev < 0 then iPrev := nBufs-1 ;
         ADCBufs[i].pPrevBuffer := Pointer( Cardinal(@ADCBufs) + (iPrev*SizeOf(TDATABuffer)) ) ;
         iNext := i+1 ;
         if iNext >= nBufs then iNext := 0 ;
         ADCBufs[i].pNextBuffer := Pointer( Cardinal(@ADCBufs) + (iNext*SizeOf(TDATABuffer)) ) ;
         end ;

     // No. of buffers to collect
     Protocol.uAIBuffers := nBufs ;

     // No digital input
     Protocol.bDIEnable := False ;

     // Clear any existing analog output channels & buffers
     Protocol.uAOChannels := 0 ;
     Protocol.uAOBuffers := 0 ;
     Protocol.bDOEnable := False ;
     Protocol.uChunksPerSecond := 20 ;
     Protocol.uTerminalCount := NumADCSamples ;

     // Stop on terminal count no longer used because it caused spurious -10V
     // output to DAC 0 at end of sweep with some sampling intervals
     //if not CircularBuffer then Protocol.uFlags := Protocol.uFlags or DD1400_FLAG_STOP_ON_TC ;

     // Enable external start of sweep
     if TriggerMode = tmExtTrigger then Protocol.uFlags := Protocol.uFlags or DD1400_FLAG_EXT_TRIGGER ;

     // Start acquisition if waveform generation not required
     if TriggerMode <> tmWaveGen then begin
        // Send protocol to device
        DD1440_CheckError(DD1440_SetProtocol(Protocol)) ;
        // Start A/D conversion
        DD1440_CheckError(DD1440_StartAcquisition) ;
        end ;

     end ;


function DD1440_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
begin
     Result := False ;
     if not DeviceInitialised then DD1440_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Stop A/D input (and D/A output) if in progress
     if DD1440_IsAcquiring then DD1440_StopAcquisition ;

     ADCActive := False ;
     DACActive := False ;  // Since A/D and D/A are synchronous D/A stops too
     Result := ADCActive ;

     end ;


procedure DD1440_GetADCSamples(
          var OutBuf : Array of SmallInt ;  { Buffer to receive A/D samples }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
begin

     //DD1440_GetAIPosition(  n64 ) ;
     //outputdebugstring(pchar(format( '%d',[n64]))) ;
     end ;


procedure DD1440_CheckSamplingInterval(
          var SamplingInterval : Double ) ;
{ ---------------------------------------------------
  Convert sampling period from <SamplingInterval> (in s) into
  clocks ticks, Returns no. of ticks in "Ticks"
  ---------------------------------------------------}
begin

  SamplingInterval := Max(Round(SamplingInterval/(DeviceInfo[0].SequenceQuantaUS*1E-6)),1) ;
  SamplingInterval := SamplingInterval*DeviceInfo[0].SequenceQuantaUS*1E-6 ;

  SamplingInterval := Max( SamplingInterval, DeviceInfo[0].MinSequencePeriodUS*1E-6 ) ;
  SamplingInterval := Min( SamplingInterval, DeviceInfo[0].MaxSequencePeriodUS*1E-6 ) ;

	end ;


function  DD1440_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          NumDACChannels : Integer ;
          NumDACPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean ;
          ExternalTrigger : Boolean
          ) : Boolean ;
{ --------------------------------------------------------------
  Send a voltage waveform stored in DACBuf to the D/A converters
  30/11/01 DigFill now set to correct final value to prevent
  spurious digital O/P changes between records
  --------------------------------------------------------------}
var
   i,ii,ch,NumSamplesPerBuffer,iPrev,iNext : Integer ;
   iDAC,nBufs,iValue,nPoints : Integer ;
   DACPointer : PSmallIntArray ;
   NumBuffers : Integer ;
   DigitalNum : Integer ;
   nChannels : Integer ;
   NumPointsPerDACBuf : Integer ;
begin
    Result := False ;
    if not DeviceInitialised then DD1440_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

    { Stop any acquisition in progress }
    if DD1440_IsAcquiring then DD1440_StopAcquisition ;

    // Define D/A output channels
    Protocol.uAOChannels := NumDACChannels ;
    for ch := 0 to Protocol.uAOChannels-1 do Protocol.anAOChannels[ch] := ch ;

    // If digital O/P required ensure that at least two D/A channels
    // are in use. Use Ch.1 for digital O/P
    if DigitalInUse then Protocol.bDOEnable := True
                    else Protocol.bDOEnable := False ;

    // Copy D/A values into output buffer
    // Note buffer is filled to end with data.
    nPoints := 0 ;
    nChannels :=  NumDACChannels ;
    if DigitalInUse then Inc(nChannels) ; // No of output channels
    for i := 0 to (DeviceInfo[0].OutputBufferSamples div nChannels)-1 do begin
        ii := Min(i,NumDACPoints-1) ;
        for ch := 0 to NumDACChannels-1 do begin
            iValue := Round( DACValues[(ii*NumDACChannels)+ch]/Calibration.afDACGains[ch]) ;
            FDACValues^[nPoints] := iValue - Calibration.anDACOffsets[ch];
            Inc(nPoints) ;
            end ;
        if DigitalInUse then begin
           FDACValues^[nPoints] := DigValues[ii] ;
           Inc(nPoints) ;
           end ;
        end ;

     DACPointer := FDACValues ;
     nBufs := 0 ;
     NumPointsPerDACBuf := 300 ;
     while nPoints > 0 do begin

        DACBufs[nBufs].pnData := DACPointer ;
        DACBufs[nBufs].uNumSamples := NumPointsPerBuf ; // Min(nPoints, NumPointsPerBuf) ;
        DACBufs[nBufs].uFlags := 0 ;
        DACBufs[nBufs].psDataFlags := Nil ;

        // Pointer to data
        DACPointer := Pointer( Cardinal(DACPointer) + (DACBufs[nBufs].uNumSamples*2) ) ;

        nPoints :=  nPoints - DACBufs[nBufs].uNumSamples ;

        Inc(nBufs) ;

        if nBufs > High(DACBufs) then Break ;

        end ;

     // Previous/Next buffer pointers
     for i := 0 to nBufs-1 do begin
         iPrev := i-1 ;
         if iPrev < 0 then iPrev := nBufs-1 ;
         DACBufs[i].pPrevBuffer := Pointer( Cardinal(@DACBufs) + (iPrev*SizeOf(TDATABuffer)) ) ;
         iNext := i+1 ;
         if iNext >= nBufs then iNext := 0 ;
         DACBufs[i].pNextBuffer := Pointer( Cardinal(@DACBufs) + (iNext*SizeOf(TDATABuffer)) ) ;
         end ;

     // No. of buffers to output
     Protocol.uAOBuffers := nBufs ;
     Protocol.pAOBuffers := @DACBufs ;

    // If ExternalTrigger flag is set make D/A output wait for
    // TTL pulse on Trigger In line
    // otherwise set acquisition sweep triggering to start immediately
    if ExternalTrigger then
       Protocol.uFlags := Protocol.uFlags or DD1400_FLAG_EXT_TRIGGER ;

    // Download protocol to DD132X
    DD1440_SetProtocol(  Protocol ) ;
    DD1440_StartAcquisition ;

    Result := DACActive ;

    end ;


function DD1440_GetDACUpdateInterval : double ;
{ -----------------------
  Get D/A update interval
  -----------------------}
begin

     // DAC update interval is same as A/D sampling interval
     Result := Protocol.dSequencePeriodUS*1E-6 ;

     end ;


function DD1440_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin
     Result := False ;
     if not DeviceInitialised then DD1440_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     DACActive := False ;
     Result := DACActive ;

     end ;


procedure DD1440_WriteDACsAndDigitalPort(
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

     if not DeviceInitialised then DD1440_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Scale from Volts to binary integer units
     DACScale := MaxDACValue/FDACVoltageRangeMax ;

     { Update D/A channels }
     for ch := 0 to nChannels-1 do begin
         // Correct for errors in hardware DAC scaling factor
         DACValue := Round(DACVolts[ch]*DACScale/Calibration.afDACGains[ch]) ;
         // Correct for DAC zero offset
         DACValue := DACValue - Calibration.anDACOffsets[ch];
         // Keep within legitimate limits
         if DACValue > MaxDACValue then DACValue := MaxDACValue ;
         if DACValue < MinDACValue then DACValue := MinDACValue ;
         // Output D/A value
         SmallDACValue := DACValue ;
         DD1440_SetAOValue(  ch, SmallDACValue ) ;

         end ;

     // Set digital outputs
     DD1440_SetDOValue(  DigValue ) ;

     end ;


function DD1440_ReadADC(
         Channel : Integer // A/D channel
         ) : SmallInt ;
// ---------------------------
// Read Analogue input channel
// ---------------------------
var
   Value : SmallInt ;
begin

     Value := 0 ;
     Result := Value ;
     if not DeviceInitialised then DD1440_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     DD1440_GetAIValue( Channel, Value ) ;
     Result := Value ;

     end ;


procedure DD1440_GetChannelOffsets(
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


procedure DD1440_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
begin

     if not DeviceInitialised then Exit ;



     DD1440_CloseDevice ;

     // Free DLL libraries
     if LibraryHnd > 0 then FreeLibrary( LibraryHnd ) ;
//     if AxoUtils32Hnd > 0 then FreeLibrary( AxoUtils32Hnd ) ;

     FreeMem( FDACValues ) ;
     FreeMem (ADCDumpBuf ) ;

     DeviceInitialised := False ;
     DACActive := False ;
     ADCActive := False ;

     end ;


procedure DD1440_CheckError(
          OK : ByteBool ) ;
{ ------------------------------------------------
  Check error code and display message if required
  ------------------------------------------------ }
begin

     if not OK then begin
        DD1440_GetLastErrorText(  ErrorMsg, High(ErrorMsg)+1 ) ;
        ShowMessage( TrimChar(ErrorMsg) ) ;
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


end.
