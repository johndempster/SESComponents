unit itcmm;
  { =================================================================
  Instrutech ITC-16/18 Interface Library V1.0
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  =================================================================}

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem;

  procedure ITCMM_InitialiseBoard ;
  procedure ITCMM_LoadLibrary  ;

  function ITCMM_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

  procedure ITCMM_ConfigureHardware(
            EmptyFlagIn : Integer ) ;

  function  ITCMM_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;
  function ITCMM_StopADC : Boolean ;
  procedure ITCMM_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;
  procedure ITCMM_CheckSamplingInterval(
            var SamplingInterval : Double ;
            var Ticks : Cardinal
            ) ;

function  ITCMM_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean
          ) : Boolean ;

function ITCMM_GetDACUpdateInterval : double ;

  function ITCMM_StopDAC : Boolean ;
  procedure ITCMM_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : Integer
            ) ;

  function  ITCMM_GetLabInterfaceInfo(
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

  function ITCMM_GetMaxDACVolts : single ;

  function ITCMM_ReadADC( Channel : Integer ) : SmallInt ;

  procedure ITCMM_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
  procedure ITCMM_CloseLaboratoryInterface ;


   procedure SetBits( var Dest : Word ; Bits : Word ) ;
   procedure ClearBits( var Dest : Word ; Bits : Word ) ;
   function TrimChar( Input : Array of Char ) : string ;
   function MinInt( const Buf : array of LongInt ) : LongInt ;
   function MaxInt( const Buf : array of LongInt ) : LongInt ;

Procedure ITCMM_CheckError( Err : Cardinal ; ErrSource : String ) ;


implementation

uses SESLabIO ;

const
   MAX_DEVICE_TYPE_NUMBER = 4 ;
   ITC16_ID = 0 ;
   ITC16_MAX_DEVICE_NUMBER= 16 ;
   ITC18_ID = 1 ;
   ITC18_MAX_DEVICE_NUMBER = 16 ;
   ITC1600_ID = 2 ;
   ITC1600_MAX_DEVICE_NUMBER = 16 ;
   ITC00_ID = 3 ;
   ITC00_MAX_DEVICE_NUMBER = 16 ;
   ITC_MAX_DEVICE_NUMBER = 16 ;
   NORMAL_MODE = 0 ;
   SMART_MODE = 1 ;
   D2H = $00 ; //Input
   H2D = $01 ;	//Output
   DIGITAL_INPUT = $02 ;		//Digital Input
   DIGITAL_OUTPUT = $03	;	//Digital Output
   AUX_INPUT = $04 ;		//Aux Input
   AUX_OUTPUT = $05 ;		//Aux Output
//STUB -> check the correct number
   NUMBER_OF_D2H_CHANNELS = 32 ;			//ITC1600: 8+F+S0+S1+4(AUX) == 15 * 2 = 30
   NUMBER_OF_H2D_CHANNELS = 15 ;			//ITC1600: 4+F+S0+S1 == 7 * 2 = 14 + 1-Host-Aux

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

//STUB: Check the numbers
   ITC1600_NUMBEROFCHANNELS = 47 ;			//15 + 32
   ITC1600_NUMBEROFINPUTS = 32 ;			//(8 AD + 1 Temp + 4 Aux + 3 Dig) * 2
   ITC1600_NUMBEROFOUTPUTS = 15	;		//(4 + 3) * 2 + 1

   ITC1600_NUMBEROFADCINPUTS = 16 ;			//8+8
   ITC1600_NUMBEROFDACOUTPUTS = 8 ;			//4+4
   ITC1600_NUMBEROFDIGINPUTS = 6 ;			//F+S+S * 2
   ITC1600_NUMBEROFDIGOUTPUTS = 6 ;			//F+S+S * 2
   ITC1600_NUMBEROFAUXINPUTS = 8 ;			//4+4
   ITC1600_NUMBEROFAUXOUTPUTS = 1 ;			//On Host
   ITC1600_NUMBEROFTEMPINPUTS = 2 ;			//1+1
   ITC1600_NUMBEROFINPUTGROUPS = 8 ;		//
   ITC1600_NUMBEROFOUTPUTGROUPS = 5 ;		//(DAC, SD) + (DAC, SD) + FD + FD + HOST

//***************************************************************************
//ITC1600 CHANNELS

//DACs
   ITC1600_DA0 = 0 ;		//RACK0
   ITC1600_DA1 = 1 ;
   ITC1600_DA2 = 2 ;
   ITC1600_DA3 = 3 ;
   ITC1600_DA4 = 4 ;		//RACK1
   ITC1600_DA5 = 5 ;
   ITC1600_DA6 = 6 ;
   ITC1600_DA7 = 7;

//Digital outputs
   ITC1600_DOF0 = 8 ;		//RACK0
   ITC1600_DOS00 = 9 ;
   ITC1600_DOS01 = 10 ;
   ITC1600_DOF1 = 11 ;		//RACK1
   ITC1600_DOS10 = 12 ;
   ITC1600_DOS11 = 13 ;
   ITC1600_HOST = 14 ;

//ADCs
   ITC1600_AD0 = 0 ;		//RACK0
   ITC1600_AD1 = 1 ;
   ITC1600_AD2 = 2 ;
   ITC1600_AD3 = 3 ;
   ITC1600_AD4 = 4 ;
   ITC1600_AD5 = 5 ;
   ITC1600_AD6 = 6 ;
   ITC1600_AD7 = 7 ;

   ITC1600_AD8 = 8 ;		//RACK1
   ITC1600_AD9 = 9 ;
   ITC1600_AD10 = 10 ;
   ITC1600_AD11 = 11 ;
   ITC1600_AD12 = 12 ;
   ITC1600_AD13 = 13 ;
   ITC1600_AD14 = 14 ;
   ITC1600_AD15 = 15 ;

//Slow ADCs
   ITC1600_SAD0 = 16 ;		//RACK0
   ITC1600_SAD1 = 17 ;
   ITC1600_SAD2 = 18 ;
   ITC1600_SAD3 = 19 ;
   ITC1600_SAD4 = 20 ;		//RACK1
   ITC1600_SAD5 = 21 ;
   ITC1600_SAD6 = 22 ;
   ITC1600_SAD7 = 23 ;

//Temperature
   ITC1600_TEM0 = 24 ;		//RACK0
   ITC1600_TEM1 = 25 ;		//RACK1

//Digital inputs
   ITC1600_DIF0 = 26 ;		//RACK0
   ITC1600_DIS00 = 27 ;
   ITC1600_DIS01 = 28 ;
   ITC1600_DIF1 = 29 ;		//RACK1
   ITC1600_DIS10 = 31 ;
   ITC1600_DIS11 = 32 ;

   ITC18_STANDARD_FUNCTION = 0 ;
   ITC18_PHASESHIFT_FUNCTION = 1 ;
   ITC18_DYNAMICCLAMP_FUNCTION = 2 ;
   ITC18_SPECIAL_FUNCTION = 3 ;

   ITC1600_STANDARD_FUNCTION = 0 ;

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

   ITC_EMPTY = 0 ;
   ITC_RESERVE = $80000000 ;
   ITC_INIT_FLAG = $00008000 ;
   ITC_FUNCTION_MASK = $00000FFF ;

   RUN_STATE = $10 ;
   ERROR_STATE = $80000000 ;
   DEAD_STATE = $00 ;
   EMPTY_INPUT = $01 ;
   EMPTY_OUTPUT = $02 ;

   USE_FREQUENCY = $0 ;
   USE_TIME = $1 ;
   USE_TICKS = $2 ;
   NO_SCALE = $0 ;
   MS_SCALE = $4 ;
   US_SCALE = $8 ;
   NS_SCALE = $C ;

   READ_TOTALTIME = $01 ;
   READ_RUNTIME = $02 ;
   READ_ERRORS = $04 ;
   READ_RUNNINGMODE = $08 ;
   READ_OVERFLOW = $10 ;
   READ_CLIPPING = $20 ;

   RESET_FIFO_COMMAND = $10000 ;
   PRELOAD_FIFO_COMMAND = $20000 ;
   LAST_FIFO_COMMAND = $40000 ;
   FLUSH_FIFO_COMMAND = $80000 ;


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

//Specification for Hardware Configuration
   THWFunction = packed record
       Mode : Cardinal ; //Mode: 0 - Internal Clock; 1 - Intrabox Clock; 2 External Clock
       U2F_File :Pointer ;							//U2F File name -> may be NULL
       SizeOfSpecificFunction : Cardinal ;	//Sizeof SpecificFunction
       SpecificFunction : Pointer ;     	//Specific for each device
       end ;

   TITC1600_Special_HWFunction = packed record
       Func : Cardinal ; //HWFunction
       DSPType : Cardinal ;  //LCA for Interface side
       HOSTType : Cardinal ; //LCA for Interface side
       RACKType : Cardinal ; //LCA for Interface side
       end ;

   TITC18_Special_HWFunction = packed record
       Func : Cardinal ;     //HWFunction
       InterfaceData : Pointer ; //LCA for Interface side
       IsolatedData : Pointer ;  //LCA for Isolated side
       end ;

   TITCChannelInfo = packed record
      ModeNumberOfPoints : Cardinal ;
      ChannelType : Cardinal ;
      ChannelNumber : Cardinal ;
      ScanNumber : Cardinal ;  //0 - does not care; Use High speed if possible
      ErrorMode : Cardinal ;   //See ITC_STOP_XX..XX definition for Error Modes
      ErrorState : Cardinal ;
      FIFOPointer : Pointer ;
      FIFONumberOfPoints : Cardinal ; //In Points
      ModeOfOperation : Cardinal ;
      SizeOfModeParameters  : Cardinal ;
      ModeParameters : Pointer ;
      SamplingIntervalFlag  : Cardinal ; //See flags above
      SamplingRate : Double ; //See flags above
      StartOffset : Double ;  //Seconds
      Gain : Double ;         //Times
      Offset : Double ;       //Volts
      end ;

   TITCStatus = packed record
      CommandStatus : Cardinal ;
      RunningMode : Cardinal ;
      Overflow : Cardinal ;
      Clipping : Cardinal ;
      TotalSeconds : Double ;
      RunSeconds : Double ;
      end ;

//Specification for Acquisition Configuration
   TITCPublicConfig = packed record

      DigitalInputMode : Cardinal ;     //Bit 0: Latch Enable, Bit 1: Invert. For ITC1600; See AES doc.
      ExternalTriggerMode : Cardinal ;	//Bit 0: Transition, Bit 1: Invert
      ExternalTrigger : Cardinal ;	//Enable
      EnableExternalClock : Cardinal ;	//Enable

      DACShiftValue : Cardinal ;	//For ITC18 Only. Needs special LCA
      InputRange : Cardinal ;           //AD0.. AD7
      TriggerOutPosition : Cardinal ;
      OutputEnable : Integer ;

      SequenceLength : Cardinal ;      //In/Out for ITC16/18; Out for ITC1600
      Sequence : Pointer ;	       //In/Out for ITC16/18; Out for ITC1600
      SequenceLengthIn : Cardinal ;    //For ITC1600 only
      SequenceIn : Pointer ;	       //For ITC1600 only

      ResetFIFOFlag : Cardinal ;       //Reset FIFO Pointers / Total Number of points in NORMALMODE
      ControlLight : Cardinal ;
      SamplingInterval : Double ;	//In Seconds. Note: may be calculated from channel setting
      end ;

   TITCChannelData = packed record
      ChannelType : Cardinal ;	  //Channel Type + Command
      ChannelNumber : Cardinal ;  //Channel Number
      Value : Integer ;  	  //Number of points OR Data Value
      DataPointer : Pointer ; 	  //Data
      end ;

   TITCSingleScanData = packed record
      ChannelType : Cardinal ;	  //Channel Type
      ChannelNumber : Cardinal ;  //Channel Number
      IntegrationPeriod : Double ;
      DecimateMode : Cardinal ;
      end ;


   TVersionInfo = packed record
       Major : Integer ;
       Minor : Integer ;
       Description : Array[0..79] of char ;
       Date : Array[0..79] of char ;
       end ;

   TGlobalDeviceInfo = packed record
       DeviceType : Cardinal ;
       DeviceNumber : Cardinal ;
       PrimaryFIFOSize : Cardinal ;    //In Points
       SecondaryFIFOSize : Cardinal ;  //In Points

       LoadedFunction : Cardinal ;
       SoftKey : Cardinal ;
       Mode : Cardinal ;
       MasterSerialNumber : Cardinal ;

       SecondarySerialNumber : Cardinal ;
       HostSerialNumber : Cardinal ;
       NumberOfDACs : Cardinal ;
       NumberOfADCs : Cardinal ;

       NumberOfDOs : Cardinal ;
       NumberOfDIs : Cardinal ;
       NumberOfAUXOs : Cardinal ;
       NumberOfAUXIs : Cardinal ;

       Reserved0 : Cardinal ;
       Reserved1 : Cardinal ;
       Reserved2 : Cardinal ;
       Reserved3 : Cardinal ;
       end ;

   TITCStartInfo = packed record
       ExternalTrigger : Integer ;  //-1 - do not change
       OutputEnable : Integer ;     //-1 - do not change
       StopOnOverflow : Integer ;   //-1 - do not change
       StopOnUnderrun : Integer ;   //-1 - do not change
       DontUseTimerThread : Integer ;
       Reserved1 : Cardinal ;
       Reserved2 : Cardinal ;
       Reserved3 : Cardinal ;
       StartTime : Double ;
       StopTime : Double ;
       end ;

   TITCLimited = packed record
       ChannelType : Cardinal ;
       ChannelNumber : Cardinal ;
       SamplingIntervalFlag : Cardinal ;  //See flags above
       SamplingRate : Double ;            //See flags above
       TimeIntervalFlag : Cardinal ;      //See flags above
       Time : Double ;                    //See flags above
       DecimationMode : Cardinal ;
       Data : Pointer ;
       end ;

// *** DLL libray function templates ***

TITC_Devices = Function (
               DeviceType : Cardinal ;
               Var DeviceNumber : Cardinal ) : Cardinal ; cdecl ;

TITC_GetDeviceHandle = Function(
                       DeviceType  : Cardinal ;
                       DeviceNumber : Cardinal ;
                       Var DeviceHandle : Integer ) : Cardinal ; cdecl ;

TITC_GetDeviceType = Function(
                     DeviceHandle : Integer ;
                     Var DeviceType : Cardinal ;
                     Var DeviceNumber : Cardinal ) : Cardinal ; cdecl ;

TITC_OpenDevice = Function (
                  DeviceType : Cardinal ;
                  DeviceNumber : Cardinal ;
                  Mode : Cardinal ;
                  Var DeviceHandle : Integer ) : Cardinal ; cdecl ;

TITC_CloseDevice = Function(
                   DeviceHandle : Integer ) : Cardinal ; cdecl ;

TITC_InitDevice = Function(
                  DeviceHandle : Integer ;
                  {Var} sHWFunction : pointer {THWFunction} ) : Cardinal ; cdecl ;

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//M
//M					STATIC INFORMATION FUNCTIONs
//M
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

TITC_GetDeviceInfo = Function(
                     DeviceHandle : Integer ;
                     Var DeviceInfo : TGlobalDeviceInfo ) : Cardinal ; cdecl ;

TITC_GetVersions = Function(
                   DeviceHandle : Integer ;
                   Var ThisDriverVersion : TVersionInfo ;
                   Var KernelLevelDriverVersion : TVersionInfo ;
                   Var HardwareVersion: TVersionInfo )  : Cardinal ; cdecl ;

TITC_GetSerialNumbers = Function(
                        DeviceHandle : Integer ;
                        Var HostSerialNumber : Integer ;
                        Var MasterBoxSerialNumber : Integer ;
                        Var SlaveBoxSerialNumber : Integer )  : Cardinal ; cdecl ;

TITC_GetStatusText = Function(
                     DeviceHandle : Integer ;
                     Status : Integer ;
                     Text : PChar ;
                     MaxCharacters : Cardinal ) : Cardinal ; cdecl ;

TITC_SetSoftKey = Function(
                  DeviceHandle : Integer ;
                  SoftKey : Cardinal ) : Cardinal ; cdecl ;

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//M
//M					DYNAMIC INFORMATION FUNCTIONs
//M
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

TITC_GetState = Function(
                DeviceHandle : Integer ;
                Var sParam : TITCStatus ) : Cardinal ; cdecl ;

TITC_SetState = Function(
                DeviceHandle : Integer ;
                Var sParam : TITCStatus ): Cardinal ; cdecl ;

TITC_GetFIFOInformation = Function(
                          DeviceHandle : Integer ;
                          NumberOfChannels : Cardinal ;
                          Var ChannelData : Array of TITCChannelData ) : Cardinal ; cdecl ;

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//M

//M					CONFIGURATION FUNCTIONs
//M
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

TITC_ResetChannels = Function(
                     DeviceHandle : Integer ) : Cardinal ; cdecl ;

TITC_SetChannels = Function(
                   DeviceHandle : Integer ;
                   NumberOfChannels : Cardinal ;
                   Var Channels : Array of TITCChannelInfo ) : Cardinal ; cdecl ;

TITC_UpdateChannels = Function(
                      DeviceHandle : Integer ) : Cardinal ; cdecl ;

TITC_GetChannels = Function(
                   DeviceHandle : Integer ;
		   NumberOfChannels : Cardinal ;
		   Var Channels : Array of TITCChannelInfo ): Cardinal ; cdecl ;

TITC_ConfigDevice = Function(
                    DeviceHandle : Integer ;
                    Var ITCConfig : TITCPublicConfig ): Cardinal ; cdecl ;


TITC_Start = Function(
             DeviceHandle : Integer ;
             Var StartInfo : TITCStartInfo ) : Cardinal ; cdecl ;

TITC_Stop = Function(
            DeviceHandle : Integer ;
            Var StartInfo : TITCStartInfo ) : Cardinal ; cdecl ;

TITC_UpdateNow = Function(
                 DeviceHandle : Integer ;
                 Var StartInfo : TITCStartInfo ) : Cardinal ; cdecl ;

TITC_SingleScan = Function(
                  DeviceHandle : Integer ;
                  NumberOfChannels : Cardinal ;
                  Var Data : Array of TITCSingleScanData ) : Cardinal ; cdecl ;

TITC_AsyncIO = Function(
               DeviceHandle : Integer ;
               NumberOfChannels : Cardinal ;
               Var Data : Array of TITCChannelData ) : Cardinal ; cdecl ;

//***************************************************************************

TITC_GetDataAvailable = Function(
                        DeviceHandle : Integer ;
                        NumberOfChannels : Cardinal ;
                        Var Data : Array of TITCChannelData ) : Cardinal ; cdecl ;

TITC_UpdateFIFOPosition = Function(
                          DeviceHandle : Integer ;
                          NumberOfChannels : Cardinal ;
                          Var Data : Array of TITCChannelData ) : Cardinal ; cdecl ;

TITC_ReadWriteFIFO = Function(
                     DeviceHandle : Integer ;
                     NumberOfChannels : Cardinal ;
                     Var Data : Array of TITCChannelData ) : Cardinal ; cdecl ;

TITC_UpdateFIFOInformation = Function(
                             DeviceHandle : Integer ;
                             NumberOfChannels : Cardinal ;
                             Var Data : Array of TITCChannelData ) : Cardinal ; cdecl ;

var
   ITC_Devices : TITC_Devices ;
   ITC_GetDeviceHandle : TITC_GetDeviceHandle ;
   ITC_GetDeviceType : TITC_GetDeviceType ;
   ITC_OpenDevice : TITC_OpenDevice ;
   ITC_CloseDevice : TITC_CloseDevice ;
   ITC_InitDevice : TITC_InitDevice ;
   ITC_GetDeviceInfo : TITC_GetDeviceInfo ;
   ITC_GetVersions : TITC_GetVersions ;
   ITC_GetSerialNumbers : TITC_GetSerialNumbers ;
   ITC_GetStatusText : TITC_GetStatusText ;
   ITC_SetSoftKey : TITC_SetSoftKey ;
   ITC_GetState : TITC_GetState ;
   ITC_SetState : TITC_SetState ;
   ITC_GetFIFOInformation : TITC_GetFIFOInformation ;
   ITC_ResetChannels : TITC_ResetChannels ;
   ITC_SetChannels : TITC_SetChannels ;
   ITC_UpdateChannels : TITC_UpdateChannels ;
   ITC_GetChannels : TITC_GetChannels ;
   ITC_ConfigDevice : TITC_ConfigDevice ;
   ITC_Start : TITC_Start ;
   ITC_Stop : TITC_Stop ;
   ITC_UpdateNow : TITC_UpdateNow ;
   ITC_SingleScan : TITC_SingleScan ;
   ITC_AsyncIO : TITC_AsyncIO ;
   ITC_GetDataAvailable : TITC_GetDataAvailable ;
   ITC_UpdateFIFOPosition : TITC_UpdateFIFOPosition ;
   ITC_ReadWriteFIFO : TITC_ReadWriteFIFO ;
   ITC_UpdateFIFOInformation : TITC_UpdateFIFOInformation ;

LibraryHnd : THandle ;         // ITCMM DLL library handle
DVPLibraryHnd : THandle ;
Device : Integer ;             // ITCMM device handle
DeviceType : Cardinal ;        // ITC interface type (ITC16/ITC18)
LibraryLoaded : boolean ;      // Libraries loaded flag
DeviceInitialised : Boolean ;
DeviceInfo : TGlobalDeviceInfo ; // ITC device hardware information

FADCVoltageRangeMax : Single ;  // Upper limit of A/D input voltage range
FADCMinValue : Integer ;        // Max. A/D integer value
FADCMaxValue : Integer ;        // Min. A/D integer value
FADCSamplingInterval : Double ;
FADCMinSamplingInterval : Single ;
FADCMaxSamplingInterval : Single ;
FADCBufferLimit : Integer ;
CyclicADCBuffer : Boolean ;
EmptyFlag : SmallInt ;
FNumADCSamples : Integer ;
FNumADCChannels : Integer ;
FNumSamplesRequired : Integer ;
OutPointer : Integer ;

FDACVoltageRangeMax : Single ;  // Upper limit of D/A voltage range
FDACMinValue : Integer ;        // Max. D/A integer value
FDACMaxValue : Integer ;        // Min. D/A integer value
FNumDACPoints : Integer ;
FNumDACChannels : Integer ;

FDACMinUpdateInterval : Single ;

DACFIFO : Array[0..3] of PSmallIntArray ;   // D/A waveform storage buffers
ADCFIFO : Array[0..7] of PSmallIntArray ;   // A/D sample storage buffers
ADCPointer : Array[0..7] of Integer ;       // A/D FIFO latest sample pointer
DIGFIFO : PSmallIntArray ;                  // Digital O/P buffer
DefaultDigValue : Integer ;

ADCActive : Boolean ;
FADCSweepDone : Boolean ;
DACActive : Boolean ;


function  ITCMM_GetLabInterfaceInfo(
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

     if not DeviceInitialised then ITCMM_InitialiseBoard ;

     { Get type of Digidata 1320 }
     if DeviceInitialised then begin

        { Get device model and serial number }
        if DeviceType = ITC16_ID then
           Model := format( ' ITC-16 s/n %d',[DeviceInfo.MasterSerialNumber] )
        else if DeviceType = ITC18_ID then
           Model := format( ' ITC-18 s/n %d',[DeviceInfo.MasterSerialNumber] )
        else Model := 'Unknown' ;

        // Define available A/D voltage range options
        ADCVoltageRanges[0] := 10.24 ;
        ADCVoltageRanges[1] := 5.12 ;
        ADCVoltageRanges[2] := 2.06 ;
        ADCVoltageRanges[3] := 1.03 ;
        NumADCVoltageRanges := 4 ;
        FADCVoltageRangeMax := ADCVoltageRanges[0] ;

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

        FADCBufferLimit := High(TSmallIntArray) ;
        ADCBufferLimit := FADCBufferLimit ;

        end ;

     Result := DeviceInitialised ;

     end ;

procedure ITCMM_LoadLibrary  ;
{ -------------------------------------
  Load ITCMM.DLL library into memory
  -------------------------------------}
begin

     { Load ITC-16 interface DLL library }
     LibraryHnd := LoadLibrary( PChar('itcmm.DLL'));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @ITC_Devices :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_Devices') ;
        @ITC_GetDeviceHandle :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetDeviceHandle') ;
        @ITC_GetDeviceType :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetDeviceType') ;
        @ITC_OpenDevice :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_OpenDevice') ;
        @ITC_CloseDevice :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_CloseDevice') ;
        @ITC_InitDevice :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_InitDevice') ;
        @ITC_GetDeviceInfo :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetDeviceInfo') ;
        @ITC_GetVersions :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetVersions') ;
        @ITC_GetSerialNumbers :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetSerialNumbers') ;
        @ITC_GetStatusText :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetStatusText') ;
        @ITC_SetSoftKey :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_SetSoftKey') ;
        @ITC_GetState :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetState') ;
        @ITC_SetState :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_SetState') ;
        @ITC_GetFIFOInformation :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetFIFOInformation') ;
        @ITC_ResetChannels :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_ResetChannels') ;
        @ITC_SetChannels :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_SetChannels') ;
        @ITC_UpdateChannels :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_UpdateChannels') ;
        @ITC_GetChannels :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetChannels') ;
        @ITC_ConfigDevice :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_ConfigDevice') ;
        @ITC_Start :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_Start') ;
        @ITC_Stop :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_Stop') ;
        @ITC_UpdateNow :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_UpdateNow') ;
        @ITC_SingleScan :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_SingleScan') ;
        @ITC_AsyncIO :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_AsyncIO') ;
        @ITC_GetDataAvailable :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_GetDataAvailable') ;
        @ITC_UpdateFIFOPosition :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_UpdateFIFOPosition') ;
        @ITC_ReadWriteFIFO :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_ReadWriteFIFO') ;
        @ITC_UpdateFIFOInformation :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_UpdateFIFOInformation') ;
        LibraryLoaded := True ;
        end
     else begin
          MessageDlg( ' Instrutech interface library (ITCMM.DLL) not found', mtWarning, [mbOK], 0 ) ;
          LibraryLoaded := False ;
          end ;
     end ;


function ITCMM_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within ITC16 DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('ITC16.DLL- ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
    end ;


function  ITCMM_GetMaxDACVolts : single ;
{ -----------------------------------------------------------------
  Return the maximum positive value of the D/A output voltage range
  -----------------------------------------------------------------}

begin
     Result := FDACVoltageRangeMax ;
     end ;


procedure ITCMM_InitialiseBoard ;
{ -------------------------------------------
  Initialise Instrutech interface hardware
  -------------------------------------------}
var
   i,Err : Integer ;
   NumDevices : Cardinal ;
begin
     DeviceInitialised := False ;

     if not LibraryLoaded then ITCMM_LoadLibrary ;

     if LibraryLoaded then begin

        // Determine type of ITC interface
        Err := ITC_Devices( ITC16_ID, NumDevices ) ;
        ITCMM_CheckError( Err, 'ITC_Devices' )  ;
        if Err <> ACQ_SUCCESS then exit
        else begin
           if NumDevices > 0 then DeviceType := ITC16_ID
           else begin
              ITC_Devices( ITC18_ID, NumDevices ) ;
              if NumDevices > 0 then DeviceType := ITC18_ID ;
              end ;
           end ;
        DeviceType := ITC18_ID ;

        // Open device
        Err := ITC_OpenDevice( DeviceType, 0, SMART_MODE, Device ) ;
        if Err = Error_DeviceIsBusy then begin
           MessageDlg( 'ITC : Device is busy, trying again', mtError, [mbOK], 0) ;
           Err := ITC_OpenDevice( DeviceType, 0, SMART_MODE, Device ) ;
           end ;
        ITCMM_CheckError( Err, 'ITC_OpenDevice' )  ;

        if Err <> ACQ_SUCCESS then exit ;

        // Initialise interface hardware
        Err := ITC_InitDevice( Device, Nil ) ;
        ITCMM_CheckError( Err, 'ITC_InitDevice' )  ;

        // Get device information
        Err := ITC_GetDeviceInfo( Device, DeviceInfo ) ;
        ITCMM_CheckError( Err, 'ITC_DeviceInfo' )  ;

        // Create A/D, D/A and digital O/P buffers
        for i := 0 to High(ADCFIFO) do New(ADCFIFO[i]) ;
        for i := 0 to High(DACFIFO) do New(DACFIFO[i]) ;
        New(DIGFIFO) ;

        DeviceInitialised := True ;

        end ;
     end ;


procedure ITCMM_ConfigureHardware(
          EmptyFlagIn : Integer ) ;
{ --------------------------------------------------------------------------

  -------------------------------------------------------------------------- }
begin
     EmptyFlag := EmptyFlagIn ;
     end ;


function ITCMM_ADCToMemory(
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
   i,j : Word ;
   ch,iBuf : Integer ;
   Ticks : Cardinal ;
   StartInfo : TITCStartInfo ;
   ChannelInfo : Array[0..7] of TITCChannelInfo ;
   ChannelData : Array[0..7] of TITCChannelData ;
   Err : Cardinal ;
   OK : Boolean ;
   Config : TITCPublicConfig ;
   ADCSeq : Array[0..7] of Cardinal ;
begin

     if not DeviceInitialised then ITCMM_InitialiseBoard ;

     if DeviceInitialised then begin

        // Stop any acquisition in progress
        ITCMM_StopADC ;

        // Copy to internal storage
        FNumADCSamples := nSamples ;
        FNumADCChannels := nChannels ;
        FNumSamplesRequired := nChannels*nSamples ;
        FADCSamplingInterval := dt ;
        CyclicADCBuffer := CircularBuffer ;

        Config.DigitalInputMode := 0 ;
        Config.ExternalTriggerMode := 2 ;
        Config.ExternalTrigger := 0 ;
        Config.EnableExternalClock := 0 ;
        Config.DACShiftValue := 0 ;
        Config.TriggerOutPosition := 0 ;
        Config.OutputEnable := 0 ;
        Config.SequenceLength := nChannels ;
        for ch := 0 to nChannels-1 do begin
            ADCSeq[ch] := ch ;
            end ;
        Config.Sequence := @ADCSeq ;
        Config.SequenceLength := 0 ;
        Config.Sequence := Nil ;
        Config.SequenceLengthIn := 0 ;
        Config.SequenceIn := Nil ;
        Config.ResetFIFOFlag := 1 ;
        Config.ControlLight := 0 ;
        Config.SamplingInterval := dt ;
        Err := ITC_ConfigDevice( Device, Config ) ;
        ITCMM_CheckError( Err, 'ITC_ConfigDevice' )  ;


        // Reset all existing channels
        Err := ITC_ResetChannels( Device ) ;
        ITCMM_CheckError( Err, 'ITC_ResetChannels' )  ;

        // Make sure that dt is an integer number of microsecs
        ITCMM_CheckSamplingInterval( dt, Ticks ) ;

        // Define new A/D input channels
        for ch := 0 to nChannels-1 do begin
            ChannelInfo[ch].ModeNumberOfPoints := 0 ;
            ChannelInfo[ch].ChannelType := D2H ;
            ChannelInfo[ch].ChannelNumber := ch ;
            ChannelInfo[ch].ScanNumber := 0 ;
            if CyclicADCBuffer then ChannelInfo[ch].ErrorMode := 0
                               else ChannelInfo[ch].ErrorMode := ITC_STOP_ALL_ON_OVERFLOW ;
            ChannelInfo[ch].ErrorState := 0 ;
            ChannelInfo[ch].FIFOPointer := Nil ;
            ChannelInfo[ch].FIFONumberOfPoints := nSamples ;
            ChannelInfo[ch].ModeOfOperation := 0 ;
            ChannelInfo[ch].SizeOfModeParameters := 0 ;
            ChannelInfo[ch].ModeParameters := 0 ;
            ChannelInfo[ch].SamplingIntervalFlag := USE_TIME or US_SCALE;
            ChannelInfo[ch].SamplingRate := dt*1E6 ;
            ChannelInfo[ch].StartOffset := 0.0 ;
            ChannelInfo[ch].Gain := ADCVoltageRange / FADCVoltageRangeMax ;
            ChannelInfo[ch].Offset := 0.0 ;

            end ;

        // Load new channel settings
        Err := ITC_SetChannels( Device, nChannels, ChannelInfo ) ;
        ITCMM_CheckError( Err, 'ITC_SetChannels' )  ;

        // Update interface with new settings
        Err := ITC_UpdateChannels( Device ) ;
        ITCMM_CheckError( Err, 'ITC_UpdateChannels' )  ;

        // Clear A/D FIFOs
        for ch := 0 to FNumADCChannels-1 do begin
            ChannelData[ch].ChannelType := D2H or FLUSH_FIFO_COMMAND ;
            ChannelData[ch].ChannelNumber := ch ;
            ChannelData[ch].Value := 0 ;
            end ;
        Err := ITC_ReadWriteFIFO( Device, FNumADCChannels, ChannelData ) ;
        ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;

        // Start A/D sampling
        if TriggerMode <> tmWaveGen then begin
           // Free Run vs External Trigger of recording seeep
           if TriggerMode = tmExtTrigger then StartInfo.ExternalTrigger := 1
                                         else StartInfo.ExternalTrigger := 0 ;
           StartInfo.OutputEnable := -1 ;
           StartInfo.StopOnOverFlow := -1 ;
           StartInfo.StopOnUnderRun := -1 ;
           StartInfo.DontUseTimerThread := -1 ;
           Err := ITC_Start( Device, StartInfo ) ;
           ITCMM_CheckError( Err, 'ITC_START' )  ;
           ADCActive := True ;
           OK := True ;
           end
        else OK := True ;
        OutPointer := 0 ;
        Result := OK ;
        end ;


     FADCSweepDone := False ;

     end ;


function ITCMM_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
var
     Status : TITCStatus ;
     Dummy : TITCStartInfo ;
     Err : Cardinal ;
begin

     if not DeviceInitialised then ITCMM_InitialiseBoard ;

     { Stop ITC interface (both A/D and D/A) }
     if DeviceInitialised then begin
        Status.CommandStatus := READ_RUNNINGMODE ;
        Err := ITC_GetState( Device, Status ) ;
        ITCMM_CheckError( Err, 'ITC_GetState' ) ;
        if Status.RunningMode <> DEAD_STATE then begin
           ITC_Stop( Device, Dummy ) ;
           ITCMM_CheckError( Err, 'ITC_Stop' ) ;
           end ;
        end ;

     ADCActive := False ;
     DACActive := False ;  // Since A/D and D/A are synchronous D/A stops too
     Result := ADCActive ;

     end ;


procedure ITCMM_GetADCSamples(
          var OutBuf : Array of SmallInt ;  { Buffer to receive A/D samples }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
// -----------------------------------------
// Get A/D samples from ITC interface FIFOS
// -----------------------------------------
var
   Err,ch,i : Integer ;
   ChannelData : Array[0..7] of TITCChannelData ;
   NumCompleteChannelGroups : Integer ;
   Status : TITCStatus ;
begin

     if ADCActive then begin

        // Determine number of samples available in FIFOs

        NumCompleteChannelGroups := High(NumCompleteChannelGroups) ;
        for ch := 0 to FNumADCChannels-1 do begin
            ChannelData[ch].ChannelType := D2H ;
            ChannelData[ch].ChannelNumber := ch ;
            ChannelData[ch].Value := 0 ;
            end ;
        Err := ITC_GetDataAvailable( Device, FNumADCChannels, ChannelData ) ;
        ITCMM_CheckError(Err,'ITC_GetDataAvailable') ;
          { for ch := 0 to FNumADCChannels-1 do begin
               outputdebugString(PChar(format('%d %d',[ch,ChannelData[ch].Value]))) ;
               end ;}

        Status.CommandStatus := READ_RUNNINGMODE ;
        Err := ITC_GetState( Device, Status ) ;
        ITCMM_CheckError(Err,'ITC_GetState') ;
        outputdebugString(PChar(format('%x',[Status.RunningMode]))) ;

        NumCompleteChannelGroups := High(NumCompleteChannelGroups) ;
        for ch := 0 to FNumADCChannels-1 do begin
            if NumCompleteChannelGroups > ChannelData[ch].Value then
               NumCompleteChannelGroups:= ChannelData[ch].Value ;
            end ;
        NumCompleteChannelGroups := ChannelData[0].Value ;

        // Read A/D samples from FIFO
        for ch := 0 to FNumADCChannels-1 do begin
            ChannelData[ch].ChannelType := D2H ;
            ChannelData[ch].ChannelNumber := ch ;
            ChannelData[ch].Value := NumCompleteChannelGroups ;
            ChannelData[ch].DataPointer := ADCFIFO[ch] ;
            end ;
        Err := ITC_ReadWriteFIFO( Device, FNumADCChannels, ChannelData ) ;
        ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;

        // Interleave samples from A/D FIFO buffers into O/P buffer
        if not CyclicADCBuffer then begin
           // Single sweep
           for i :=  0 to NumCompleteChannelGroups-1 do begin
               for ch := 0 to FNumADCChannels-1 do begin
                   OutBuf[OutPointer] := ADCFIFO[ch]^[i] ;
                   Inc(OutPointer) ;
                   end ;
               end ;
           if Outpointer >= (FNumSamplesRequired) then FADCSweepDone := True ;
           OutBufPointer := MinInt([OutPointer,(FNumSamplesRequired-1)]) ;
           end
        else begin
           // Cyclic buffer
           for i :=  0 to NumCompleteChannelGroups-1 do begin
               for ch := 0 to FNumADCChannels-1 do begin
                   OutBuf[OutPointer] := ADCFIFO[ch]^[i] ;
                   Inc(OutPointer) ;
                   if Outpointer >= FNumSamplesRequired then Outpointer := 0 ;
                   end ;
               end ;
           end ;

        end ;

     end ;


procedure ITCMM_CheckSamplingInterval(
          var SamplingInterval : Double ;
          var Ticks : Cardinal
          ) ;
{ ---------------------------------------------------
  Convert sampling period from <SamplingInterval> (in s) into
  clocks ticks, Returns no. of ticks in "Ticks"
  ---------------------------------------------------}
const
    SecsToMicrosecs = 1E6 ;
var
    TicksRequired,Multiplier,iStep : Cardinal ;
    Steps : Array[0..4] of Cardinal ;

begin
     Steps[0] := 1 ;
     Steps[1] := 2 ;
     Steps[2] := 4 ;
     Steps[3] := 5 ;
     Steps[4] := 8 ;

     TicksRequired := Round(SamplingInterval*SecsToMicrosecs) ;

     iStep := 0 ;
     Multiplier := 1 ;
     Ticks := Steps[iStep]*Multiplier ;
     while Ticks < TicksRequired do begin
          Ticks := Steps[iStep]*Multiplier ;
          if iStep = High(Steps) then begin
             Multiplier := Multiplier*10 ;
             iStep := 0 ;
             end
          else Inc(iStep) ;
          end ;

     SamplingInterval := Ticks/SecsToMicrosecs ;
     end ;


function  ITCMM_MemoryToDACAndDigitalOut(
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
   i,j,ch,DACValue,Err : Integer ;
   StartInfo : TITCStartInfo ;
   ChannelInfo : Array[0..7] of TITCChannelInfo ;
   ChannelData : Array[0..7] of TITCChannelData ;
   State : TITCStatus ;
begin

    if not DeviceInitialised then ITCMM_InitialiseBoard ;

    if DeviceInitialised then begin

       { Stop any acquisition in progress }
       {if ADCActive then} ADCActive := ITCMM_StopADC ;

       // Copy D/A values into D/A FIFO buffers
       for ch := 0 to nChannels-1 do begin
           j := ch ;
           for i := 0 to nPoints-1 do begin
               DACFIFO[ch]^[i] := DACValues[j] ;
               j := j + nChannels ;
               end ;
           end ;

       // Define D/A output channels
       for ch := 0 to nChannels-1 do begin
           ChannelInfo[ch].ChannelType := H2D ;
           ChannelInfo[ch].ChannelNumber := ch ;
           ChannelInfo[ch].ScanNumber := 0 ;
           ChannelInfo[ch].ErrorMode := {ITC_STOP_ALL_ON_UNDERRUN}0 ;
           ChannelInfo[ch].ErrorState := 0 ;
           ChannelInfo[ch].FIFOPointer := DACFIFO[ch] ;
           ChannelInfo[ch].FIFONumberOfPoints := nPoints ;
           ChannelInfo[ch].ModeOfOperation := 0 ;
           ChannelInfo[ch].SizeOfModeParameters := 0 ;
           ChannelInfo[ch].ModeParameters := 0 ;
           ChannelInfo[ch].SamplingIntervalFlag := USE_TIME or US_SCALE;
           ChannelInfo[ch].SamplingRate := FADCSamplingInterval*1E6 ;
           ChannelInfo[ch].StartOffset := 0.0 ;
           ChannelInfo[ch].Gain := 1.0 ;
           ChannelInfo[ch].Offset := 0.0 ;
           end ;

       // Add digital output channel
       if DigitalInUse then begin
           for i := 0 to nPoints-1 do DigFIFO^[i] := DigValues[i] ;
           ChannelInfo[0].ChannelType := DIGITAL_OUTPUT ;
           ChannelInfo[0].ChannelNumber := 0 ;
           ChannelInfo[0].ScanNumber := 0 ;
           ChannelInfo[0].ErrorMode := ITC_STOP_ALL_ON_OVERFLOW ;
           ChannelInfo[0].ErrorState := 0 ;
           ChannelInfo[0].FIFOPointer := DigFIFO ;
           ChannelInfo[0].FIFONumberOfPoints := nPoints ;
           ChannelInfo[0].ModeOfOperation := 0 ;
           ChannelInfo[0].SizeOfModeParameters := 0 ;
           ChannelInfo[0].ModeParameters := 0 ;
           ChannelInfo[0].SamplingIntervalFlag := USE_TIME or US_SCALE;
           ChannelInfo[0].SamplingRate := FADCSamplingInterval*1E6 ;
           ChannelInfo[0].StartOffset := 0.0 ;
           ChannelInfo[0].Gain := 1.0 ;
           ChannelInfo[0].Offset := 0.0 ;

           end ;

       // Load new channel settings
       Err := ITC_SetChannels( Device, {nChannels}1, ChannelInfo ) ;
       ITCMM_CheckError( Err, 'ITC_SetChannels' )  ;

       // Update interface with new settings
       Err := ITC_UpdateChannels( Device ) ;
       ITCMM_CheckError(Err,'ITC_UpdateChannels') ;

       // Write D/A samples to FIFO
       for ch := 0 to nChannels-1 do begin
          ChannelData[ch].ChannelType := H2D or RESET_FIFO_COMMAND or PRELOAD_FIFO_COMMAND {or LAST_FIFO_COMMAND} ;
          ChannelData[ch].ChannelNumber := ch ;
          ChannelData[ch].Value := nPoints ;
          ChannelData[ch].DataPointer := DACFIFO[ch] ;
          end ;

       Err := ITC_ReadWriteFIFO( Device, {nChannels}1, ChannelData ) ;
       ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;

       {Save D/A sweep data }
       FNumDACPoints := nPoints ;
       FNumDACChannels := nChannels ;

       // Start combined A/D & D/A sweep
       StartInfo.ExternalTrigger := 0 ;   // Start sweep immediately
       StartInfo.OutputEnable := 1 ;      // Enable D/A output on interface
       StartInfo.StopOnOverFlow := -1 ;
       StartInfo.StopOnUnderRun := -1 ;
       StartInfo.DontUseTimerThread := -1 ;
       Err := ITC_Start( Device, StartInfo ) ;
       ITCMM_CheckError( Err, 'ITC_Start' ) ;
       DACActive := True ;
       ADCActive := True ;

       end ;

    Result := DACActive ;
    end ;


function ITCMM_GetDACUpdateInterval : double ;
{ -----------------------
  Get D/A update interval
  -----------------------}
begin
     Result := FADCSamplingInterval ;
     { NOTE. DAC update interval is constrained to be the same
       as A/D sampling interval (set by ITCMM_ADCtoMemory. }
     end ;


function ITCMM_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin

     if not DeviceInitialised then ITCMM_InitialiseBoard ;

     DACActive := False ;
     Result := DACActive ;

     end ;


procedure ITCMM_WriteDACsAndDigitalPort(
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

     if not DeviceInitialised then ITCMM_InitialiseBoard ;

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
        ChannelData[NumCh].ChannelNumber := 0 ;
        ChannelData[NumCh].Value := DigValue ;
        Inc(NumCh) ;

        Err := ITC_AsyncIO( Device, NumCh, ChannelData ) ;
        ITCMM_CheckError( Err, 'ITC_AsyncIO' ) ;

        { Keep dig. value for use by DD132X_MemoryToDAC }
        DefaultDigValue := DigValue ;
        end ;


     end ;


function ITCMM_ReadADC(
         Channel : Integer // A/D channel
         ) : SmallInt ;
// ---------------------------
// Read Analogue input channel
// ---------------------------
var
   ChannelData : TITCChannelData ;
   Err : Integer ;
begin

     if not DeviceInitialised then ITCMM_InitialiseBoard ;

     if DeviceInitialised then begin
        ChannelData.ChannelType := D2H ;
        ChannelData.ChannelNumber := Channel ;
        Err := ITC_AsyncIO( Device, 1, ChannelData ) ;
        ITCMM_CheckError( Err, 'ITC_AsyncIO' ) ;
        Result := ChannelData.Value ;
        end ;

     end ;


procedure ITCMM_GetChannelOffsets(
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


procedure ITCMM_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
var
   i : Integer ;
   Err : Cardinal ;
begin

     if DeviceInitialised then begin

        { Stop any acquisition in progress }
        ITCMM_StopADC ;

        { Close connection with interface }
        Err := ITC_CloseDevice( Device  ) ;

        // Free A/D, D/A and digital O/P buffers
        for i := 0 to High(ADCFIFO) do Dispose(ADCFIFO[i]) ;
        for i := 0 to High(DACFIFO) do Dispose(DACFIFO[i]) ;
        Dispose(DIGFIFO) ;

        DeviceInitialised := False ;
        DACActive := False ;
        ADCActive := False ;
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

Procedure ITCMM_CheckError(
          Err : Cardinal ;        // Error code
          ErrSource : String ) ;  // Name of procedure which returned Err
// ----------------------------------------------
// Report type and source of ITC interface error
// ----------------------------------------------
var
   ErrName : string ;
begin

   if Err <> ACQ_SUCCESS then begin

     Case Err of
        Error_DeviceIsNotSupported : ErrName := 'DeviceIsNotSupported' ;
        Error_UserVersionID : ErrName := 'UserVersionID' ;
        Error_KernelVersionID : ErrName := 'KernelVersionID' ;
        Error_DSPVersionID : ErrName := 'DSPVersionID' ;
        Error_TimerIsRunning : ErrName := 'TimerIsRunning' ;
        Error_TimerIsDead : ErrName := 'TimerIsDead' ;
        Error_TimerIsWeak : ErrName := 'TimerIsWeak' ;
        Error_MemoryAllocation : ErrName := 'MemoryAllocation' ;
        Error_MemoryFree : ErrName := 'MemoryFree' ;
        Error_MemoryError : ErrName := 'MemoryError' ;
        Error_MemoryExist : ErrName := 'MemoryExist' ;
        Warning_AcqIsRunning : ErrName := 'AcqIsRunning' ;
        Error_TIMEOUT : ErrName := 'TIMEOUT' ;
        Error_OpenRegistry : ErrName := 'OpenRegistry' ;
        Error_WriteRegistry : ErrName := 'WriteRegistry' ;
        Error_ReadRegistry : ErrName := 'ReadRegistry' ;
        Error_ParamRegistry : ErrName := 'ParamRegistry' ;
        Error_CloseRegistry : ErrName := 'CloseRegistry' ;
        Error_Open : ErrName := 'Open' ;
        Error_Close : ErrName := 'Close' ;
        Error_DeviceIsBusy : ErrName := 'DeviceIsBusy' ;
        Error_AreadyOpen : ErrName := 'AreadyOpen' ;
        Error_NotOpen : ErrName := 'NotOpen' ;
        Error_NotInitialized  : ErrName := 'NotInitialized' ;
        Error_Parameter : ErrName := 'Parameter' ;
        Error_ParameterSize : ErrName := 'ParameterSize' ;
        Error_Config : ErrName := 'Config' ;
        Error_InputMode : ErrName := 'InputMode' ;
        Error_OutputMode : ErrName := 'OutputMode' ;
        Error_Direction : ErrName := 'Direction' ;
        Error_ChannelNumber : ErrName := 'ChannelNumber' ;
        Error_SamplingRate : ErrName := 'SamplingRate' ;
        Error_StartOffset : ErrName := 'StartOffset' ;
        Error_Software : ErrName := 'Software' ;
        else ErrName := 'Unknown' ;
        end ;

     MessageDlg( 'Error ' + ErrName + ' in ' + ErrSource, mtError, [mbOK], 0) ;
     end ;

   end ;

end.
