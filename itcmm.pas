unit itcmm;
  { =================================================================
  Instrutech ITC-16/18 Interface Library V1.0
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  =================================================================
  28/2/02
  15/3/02
  19/3/02 ... Completed, first released version
  1/8/02  ... ITC-16 now only has +/- 10.24V A/D voltage range
              Changes to various structures to match updated ITCMM.DLL
  21/8/02 ...
  6/12/02 ... Latest revision of ITCMM.DLL
  11/2/04 ... ITCMM_MemoryToDACAndDigitalOut can now wait for ext. trigger
              itcmm.dll now specifically loaded from program folder
  12/11/04 .. Two DAC output channels now supported
  04/04/07 ... Collection of last point in single sweep now assured
  19/12/11 ... D/A fifo now filled by ITCMM_GetADCSamples allowing
               record buffer to be increased to MaxADCSamples div 2 (4194304)
  27/8/12 ... ITCMM_WriteDACsAndDigitalPort and ITCMM_ReadADC now disabled when ADCActive = TRUE
  }

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,mmsystem, math;

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
            ExternalTriggerActiveHigh : Boolean ;
            CircularBuffer : Boolean
            ) : Boolean ;
  function ITCMM_StopADC : Boolean ;
  procedure ITCMM_GetADCSamples (
            OutBuf : Pointer ;
            var OutBufPointer : Integer
            ) ;
  procedure ITCMM_CheckSamplingInterval(
            var SamplingInterval : Double ;
            var Ticks : Cardinal
            ) ;

function  ITCMM_MemoryToDACAndDigitalOut(
          var DACValues : Array of SmallInt  ;
          NumDACChannels : Integer ;
          nPoints : Integer ;
          var DigValues : Array of SmallInt  ;
          DigitalInUse : Boolean ;
          WaitForExternalTrigger : Boolean
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


   function TrimChar( Input : Array of Char ) : string ;
   function MinInt( const Buf : array of LongInt ) : LongInt ;
   function MaxInt( const Buf : array of LongInt ) : LongInt ;

Procedure ITCMM_CheckError( Err : Cardinal ; ErrSource : String ) ;


implementation

uses SESLabIO ;

const

   FIFOMaxPoints = 16128 ;


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
       Mode : Cardinal ;                        //Mode: 0 - Internal Clock; 1 - Intrabox Clock; 2 External Clock
       U2F_File :Pointer ;			//U2F File name -> may be NULL
       SizeOfSpecificFunction : Cardinal ;	//Sizeof SpecificFunction
       SpecificFunction : Pointer ;     	//Specific for each device
       end ;

   TITC1600_Special_HWFunction = packed record
       Func : Cardinal ;      //HWFunction
       DSPType : Cardinal ;  //LCA for Interface side
       HOSTType : Cardinal ; //LCA for Interface side
       RACKType : Cardinal ; //LCA for Interface side
       end ;

   TITC18_Special_HWFunction = packed record
       Func : Cardinal ;          //HWFunction
       InterfaceData : Pointer ; //LCA for Interface side
       IsolatedData : Pointer ;  //LCA for Isolated side
       Reserved : Cardinal ;         // Added for new ITCMLL
       end ;

   TITCChannelInfo = packed record
      ModeNumberOfPoints : Cardinal ;
      ChannelType : Cardinal ;
      ChannelNumber : Cardinal ;
      Reserved0 : Cardinal ;  //0 - does not care; Use High speed if possible
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

      ExternalDecimation : Cardinal ;
      Reserved1 : Cardinal ;
      Reserved2 : Cardinal ;
      Reserved3 : Cardinal ;

      end ;

   TITCStatus = packed record
      CommandStatus : Cardinal ;
      RunningMode : Cardinal ;
      Overflow : Cardinal ;
      Clipping : Cardinal ;
      State : Cardinal ;
      Reserved0 : Cardinal ;
      Reserved1 : Cardinal ;
      Reserved2 : Cardinal ;
      TotalSeconds : Double ;
      RunSeconds : Double ;
      end ;

   // Specification for Acquisition Configuration record
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
      SamplingInterval : Double ;      //In Seconds. Note: may be calculated from channel setting
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
       RunningOption : Integer ;
       ResetFIFOs : Cardinal ;
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
                  sHWFunction : pointer ) : Cardinal ; cdecl ;

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
   //ITC_UpdateFIFOInformation : TITC_UpdateFIFOInformation ;

   LibraryHnd : THandle ;           // ITCMM DLL library file handle
   Device : Integer ;               // ITCMM device handle
   DeviceType : Cardinal ;          // ITC interface type (ITC16/ITC18)
   LibraryLoaded : boolean ;        // Libraries loaded flag
   DeviceInitialised : Boolean ;    // Indicates devices has been successfully initialised
   DeviceInfo : TGlobalDeviceInfo ; // ITC device hardware information

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
                                       // (used by ITCMM_GetADC+Samples)
   OutPointerSkipCount : Integer ;     // No. of points to ignore when FIFO read starts
   FDACVoltageRangeMax : Single ;      // Upper limit of D/A voltage range
   FDACMinValue : Integer ;            // Max. D/A integer value
   FDACMaxValue : Integer ;            // Min. D/A integer value
   FNumDACPoints : Integer ;
   FNumDACChannels : Integer ;         // No. of D/A channels in use
   FDACPointer : Integer ;             // No. output points written to FIFO

   FDACMinUpdateInterval : Single ;

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
   Config : TITCPublicConfig ;             // ITC interface configuration data

   ADCActive : Boolean ;                   // Indicates A/D conversion in progress



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
           Model := format( ' ITC-16 Detected : s/n %d',[DeviceInfo.MasterSerialNumber] )
        else if DeviceType = ITC18_ID then
           Model := format( ' ITC-18 Detected : s/n %d',[DeviceInfo.MasterSerialNumber] )
        else Model := 'Unknown' ;

        // Define available A/D voltage range options
        ADCVoltageRanges[0] := 10.24 ;
        ADCVoltageRanges[1] := 5.12 ;
        ADCVoltageRanges[2] := 2.048 ;
        ADCVoltageRanges[3] := 1.024 ;
        FADCVoltageRangeMax := ADCVoltageRanges[0] ;
        // ITC-16 does not have programmable A/D gain
        if DeviceType = ITC18_ID then NumADCVoltageRanges := 4
                                 else NumADCVoltageRanges := 1 ;

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
        ADCMinSamplingInterval := 5E-6 ;
        ADCMaxSamplingInterval := 0.065 ;
        FADCMinSamplingInterval := ADCMinSamplingInterval ;
        FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

//        FADCBufferLimit := High(TSmallIntArray)+1 ;
        FADCBufferLimit := MaxADCSamples div 2 ; //Old value 16128 ;
        ADCBufferLimit := FADCBufferLimit ;

        end ;

     Result := DeviceInitialised ;

     end ;


procedure ITCMM_LoadLibrary  ;
{ -------------------------------------
  Load ITCMM.DLL library into memory
  -------------------------------------}
begin

     { Load ITCMM interface DLL library }
     LibraryHnd := LoadLibrary(
                   PChar(ExtractFilePath(ParamStr(0)) + 'itcmm.DLL'));

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
        //@ITC_UpdateFIFOInformation :=ITCMM_GetDLLAddress(LibraryHnd,'ITC_UpdateFIFOInformation') ;
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
       MessageDlg('ITCMM.DLL- ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
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
   Err,Retry : Integer ;
   NumDevices : Cardinal ;
   Done : Boolean ;
begin
     DeviceInitialised := False ;

     if not LibraryLoaded then ITCMM_LoadLibrary ;

     if LibraryLoaded then begin

        // Determine type of ITC interface
        Err := ITC_Devices( ITC16_ID, NumDevices ) ;
        ITCMM_CheckError( Err, 'ITC_Devices' )  ;
        if Err <> ACQ_SUCCESS then exit
        else begin
           if NumDevices > 0 then begin
              // Set up for ITC-16
              DeviceType := ITC16_ID ;
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
              OutPointerSkipCount := -5 ;
              end
           else begin
              ITC_Devices( ITC18_ID, NumDevices ) ;
              if NumDevices > 0 then begin
                 // Set up for ITC-18
                 DeviceType := ITC18_ID ;
                 // Load ITC-16 FIFO sequencer codes
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
                 OutPointerSkipCount := -3 ;
                 end ;
              end ;
           end ;

        // Open device
        Done := False ;
        Retry := 0 ;
        While not Done do begin
           Err := ITC_OpenDevice( DeviceType, 0, NORMAL_MODE, Device ) ;
           if (Err = ACQ_SUCCESS) or (Retry >= 10) then Done := True ;
           Inc(Retry) ;
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
        New(ADCFIFO) ;
        New(DACFIFO) ;

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
          ExternalTriggerActiveHigh : Boolean ;   // External trigger is active high
          CircularBuffer : Boolean                { Repeated sampling into buffer (IN) }
          ) : Boolean ;                           { Returns TRUE indicating A/D started }
{ -----------------------------
  Start A/D converter sampling
  -----------------------------}

var
   ch,Gain : Integer ;
   Ticks : Cardinal ;
   StartInfo : TITCStartInfo ;
   ChannelInfo : Array[0..7] of TITCChannelInfo ;
   ChannelData : TITCChannelData ;
   Err : Cardinal ;
   OK : Boolean ;

begin
     Result := False ;

     if not DeviceInitialised then ITCMM_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Stop any acquisition in progress
     ITCMM_StopADC ;

     // Make sure that dt is one of (1,10,20,50,100,...) us
     ITCMM_CheckSamplingInterval( dt, Ticks ) ;

     // Copy to internal storage
     FNumADCSamples := nSamples ;
     FNumADCChannels := nChannels ;
     FNumSamplesRequired := nChannels*nSamples ;
     FADCSamplingInterval := dt ;
     CyclicADCBuffer := CircularBuffer ;

     // Reset all existing channels
     Err := ITC_ResetChannels( Device ) ;
     ITCMM_CheckError( Err, 'ITC_ResetChannels' )  ;

     // Define new A/D input channels
     for ch := 0 to nChannels-1 do begin
            ChannelInfo[ch].ModeNumberOfPoints := 0 ;
            ChannelInfo[ch].ChannelType := D2H ;
            ChannelInfo[ch].ChannelNumber := ch ;
            ChannelInfo[ch].ErrorMode := 0 ;
            ChannelInfo[ch].ErrorState := 0 ;
            ChannelInfo[ch].FIFOPointer := ADCFIFO ;
            ChannelInfo[ch].FIFONumberOfPoints := 0 ;
            ChannelInfo[ch].ModeOfOperation := 0 ;
            ChannelInfo[ch].SizeOfModeParameters := 0 ;
            ChannelInfo[ch].ModeParameters := Nil ;
            ChannelInfo[ch].SamplingIntervalFlag := USE_TIME or US_SCALE;
            ChannelInfo[ch].SamplingRate :=  (dt*1E6) ;
            ChannelInfo[ch].StartOffset := 0.0 ;
            ChannelInfo[ch].Gain := 1.0 ;
            ChannelInfo[ch].Offset := 0.0 ;

            end ;

     // Load new channel settings
     Err := ITC_SetChannels( Device, nChannels, ChannelInfo ) ;
     ITCMM_CheckError( Err, 'ITC_SetChannels' )  ;

     // Update interface with new settings
     Err := ITC_UpdateChannels( Device ) ;
     ITCMM_CheckError( Err, 'ITC_UpdateChannels' )  ;

     Config.DigitalInputMode := 0 ;

     // Set external trigger polarity
     if ExternalTriggerActiveHigh then Config.ExternalTriggerMode := 1
                                  else Config.ExternalTriggerMode := 3 ;
     // Set external trigger
     if TriggerMode <> tmFreeRun then Config.ExternalTrigger := 1
                                 else Config.ExternalTrigger := 0 ;

     Config.EnableExternalClock := 0 ;
     Config.DACShiftValue := 0 ;
     Config.TriggerOutPosition := 0 ;
     Config.OutputEnable := 0 ;

     // Set A/D input gain for Ch.0
     Gain := Round(FADCVoltageRangeMax/ADCVoltageRange) ;
     if Gain = 1 then Config.InputRange := 0
     else if Gain = 2 then Config.InputRange := 1
     else if Gain = 5 then Config.InputRange := 2
     else Config.InputRange := 3 ;
     // Replicate gain setting for all other channels in use
     for ch := 1 to nChannels-1 do
         Config.InputRange := ((Config.InputRange and 3) shl (ch*2))
                              or Config.InputRange ;

     Config.TriggerOutPosition := 0 ;
     Config.OutputEnable := 0 ;

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
     Config.Sequence := @Sequence ;
     Config.SequenceLength := nChannels ;

     Config.SequenceLengthIn := 0 ;
     Config.SequenceIn := Nil ;

     Config.ResetFIFOFlag := 1 ;
     Config.ControlLight := 0 ;

     // Set sampling interval (THIS DOESN'T WORK AT THE MOMENT)
     Config.SamplingInterval := (dt) / nChannels ;

     Err := ITC_ConfigDevice( Device, Config ) ;
     ITCMM_CheckError( Err, 'ITC_ConfigDevice' )  ;

     // Clear A/D FIFO
     ChannelData.ChannelType := D2H or FLUSH_FIFO_COMMAND ;
     ChannelData.ChannelNumber := 0 ;
     ChannelData.Value := 0 ;
     Err := ITC_ReadWriteFIFO( Device, 1, ChannelData ) ;
     ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;

     // Start A/D sampling
     if TriggerMode <> tmWaveGen then begin
        // Free Run vs External Trigger of recording seeep
        if TriggerMode = tmExtTrigger then StartInfo.ExternalTrigger := 1
                                      else StartInfo.ExternalTrigger := 0 ;
        StartInfo.OutputEnable := -1 ;
        if CircularBuffer then begin
           StartInfo.StopOnOverFlow := 0 ;
           StartInfo.StopOnUnderRun := 0 ;
           end
        else begin
           StartInfo.StopOnOverFlow := 1 ;
          StartInfo.StopOnUnderRun := 1 ;
          end ;

        StartInfo.RunningOption:= 0 ;
        Err := ITC_Start( Device, StartInfo ) ;
        ITCMM_CheckError( Err, 'ITC_START' )  ;
        ADCActive := True ;
        OK := True ;
        end
     else OK := True ;

     OutPointer := OutPointerSkipCount ;

     DACPointer := 0 ; // Clear DAC FIFO update pointer ;

     Result := OK ;

     end ;


function ITCMM_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
var
     Status : TITCStatus ;
     Dummy : TITCStartInfo ;
     Err : Cardinal ;
     ChannelData : TITCChannelData ;

begin
     Result := False ;
     if not DeviceInitialised then ITCMM_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     { Stop ITC interface (both A/D and D/A) }
     Status.CommandStatus := READ_RUNNINGMODE ;
     Err := ITC_GetState( Device, Status ) ;
     ITCMM_CheckError( Err, 'ITC_GetState' ) ;
     if Status.RunningMode <> DEAD_STATE then begin
        ITC_Stop( Device, Dummy ) ;
        ITCMM_CheckError( Err, 'ITC_Stop' ) ;
        end ;

     // Determine number of samples available in FIFOs

     ChannelData.ChannelType := D2H ;
     ChannelData.ChannelNumber := 0 ;
     ChannelData.Value := 0 ;
     Err := ITC_GetDataAvailable( Device, 1, ChannelData ) ;
     ITCMM_CheckError(Err,'ITC_GetDataAvailable') ;

        //outputdebugString(PChar(format('%d',[ChannelData.Value]))) ;

     // Read A/D samples from FIFO
     ChannelData.DataPointer := ADCFIFO ;
     if ChannelData.Value > 0 then begin
        Err := ITC_ReadWriteFIFO( Device, 1, ChannelData ) ;
        ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;
        end ;

     ADCActive := False ;
     Result := ADCActive ;

     end ;


procedure ITCMM_GetADCSamples(
          OutBuf : Pointer ;                { Pointer to buffer to receive A/D samples [In] }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
// -----------------------------------------
// Get A/D samples from ITC interface FIFO
// -----------------------------------------
var
   i,OutPointerLimit : Integer ;
   ChannelData : TITCChannelData ;
   Err : Integer ;
begin

     if ADCActive then begin

        // Determine number of samples available in FIFO
        ChannelData.ChannelType := D2H ;
        ChannelData.ChannelNumber := 0 ;
        ChannelData.Value := 0 ;
        ITCMM_CheckError( ITC_GetDataAvailable( Device, 1, ChannelData),
                          'ITC_GetDataAvailable' ) ;

        //outputdebugString(PChar(format('%d',[ChannelData.Value]))) ;

        // Read A/D samples from FIFO
        ChannelData.DataPointer := ADCFIFO ;

        if ChannelData.Value > 1 then begin

           // Interleave samples from A/D FIFO buffers into O/P buffer
           if not CyclicADCBuffer then begin

              OutPointerLimit := FNumSamplesRequired - 1 ;

              // Ensure FIFO buffer is not emptied if sweep not completed
              if (OutPointer + ChannelData.Value) < OutPointerLimit then begin
                 ChannelData.Value := ChannelData.Value -1 ;
                 end ;

              // Read data from FIFO
              ITCMM_CheckError( ITC_ReadWriteFIFO( Device, 1, ChannelData ),
                                'ITC_ReadWriteFIFO') ;

              for i :=  0 to ChannelData.Value-1 do begin
                  if (OutPointer >= 0) and (OutPointer <= OutPointerLimit) then
                     PSmallIntArray(OutBuf)^[OutPointer] := ADCFIFO^[i] ;
                  Inc(OutPointer) ;
                  end ;

              OutBufPointer := Min(OutPointer,OutPointerLimit) ;
              end
           else begin

              // Ensure FIFO buffer is not emptied
              ChannelData.Value := ChannelData.Value -1 ;

              // Read data from FIFO
              ITCMM_CheckError( ITC_ReadWriteFIFO( Device, 1, ChannelData ),
                                'ITC_ReadWriteFIFO') ;

              // Cyclic buffer
              for i :=  0 to ChannelData.Value-1 do begin
                  if OutPointer >= 0 then PSmallIntArray(OutBuf)^[OutPointer] := ADCFIFO^[i] ;
                  Inc(OutPointer) ;
                  if Outpointer >= FNumSamplesRequired then Outpointer := 0 ;
                  end ;
              OutBufPointer := OutPointer ;
              end ;

           // Write D/A waveform to FIFO.

           if (ChannelData.Value > 0) and (DACPointer > 0) and
              (DACPointer < FNumSamplesRequired) then begin
              ChannelData.ChannelType := H2D ;
              ChannelData.Value := Min(ChannelData.Value,FNumSamplesRequired-DACPointer) ;
              ChannelData.DataPointer := Pointer(Cardinal(DACFIFO) + DACPointer*2);
              DACPointer := DACPointer + ChannelData.Value ;
              Err := ITC_ReadWriteFIFO( Device, 1, ChannelData ) ;
              ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;
              //outputdebugstring(pchar(format('%d %d',[DACPointer,ChannelData.Value])));
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
    MaxTicksAllowed = 50000 ; // 50 ms upper limit
    SecsToMicrosecs = 1E6 ;
var
    TicksRequired,Multiplier,iStep : Cardinal ;
    Steps : Array[0..4] of Cardinal ;
    i : Integer ;
begin

     // Ensure sampling interval remains within supported limits
     if SamplingInterval < FADCMinSamplingInterval then
        SamplingInterval := FADCMinSamplingInterval ;
     if SamplingInterval > FADCMaxSamplingInterval then
        SamplingInterval := FADCMaxSamplingInterval ;

     // Set to nearest valid 1,2,4,5,8 increment
     Steps[0] := 1 ;
     Steps[1] := 2 ;
     Steps[2] := 4 ;
     Steps[3] := 5 ;
     Steps[4] := 8 ;

     TicksRequired := Round(SamplingInterval*SecsToMicrosecs) ;

     iStep := 0 ;
     Multiplier := 1 ;
     Ticks := Steps[iStep]*Multiplier ;
     while (Ticks < Min(TicksRequired,MaxTicksAllowed)) do begin
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
          var DACValues : Array of SmallInt  ; // D/A output values
          NumDACChannels : Integer ;                // No. D/A channels
          nPoints : Integer ;                  // No. points per channel
          var DigValues : Array of SmallInt  ; // Digital port values
          DigitalInUse : Boolean ;             // Output to digital outs
          WaitForExternalTrigger : Boolean     // Wait for ext. trigger
          ) : Boolean ;
{ --------------------------------------------------------------
  Send a voltage waveform stored in DACBuf to the D/A converters
  30/11/01 DigFill now set to correct final value to prevent
  spurious digital O/P changes between records
  --------------------------------------------------------------}
var
   i,k,ch,Err,iFIFO : Integer ;
   StartInfo : TITCStartInfo ;
   ChannelData : TITCChannelData ;
   DACChannel : Array[0..15] of Cardinal ;
   ADCChannel : Array[0..15] of Cardinal ;
   NumOutChannels : Integer ;              // No. of DAC + Digital output channels
   LastFIFOSample : Integer ;              // Last sample index in FIFO
   InCh, OutCh : Integer ;
   iDAC, iDig : Integer ;
   Step,Counter : Single ;
begin
     Result := False ;
    if not DeviceInitialised then ITCMM_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

    { Stop any acquisition in progress }
    ADCActive := ITCMM_StopADC ;

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
    // (Note. Config and Sequence already contains data entered by ITCMM_ADCToMemory)

    if FNumADCChannels < NumOutChannels then begin
       // No. of output channels exceed input
       // -----------------------------------

       // Configure sequence memory
       Config.SequenceLength := FNumADCChannels*NumOutChannels ;
       InCh := 0 ;
       OutCh := 0 ;
       for k := 0 to Config.SequenceLength-1 do begin
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
           iDAC := Min( Trunc(Counter),nPoints-1 ) ;
           for ch := 0 to NumDACChannels-1 do if iFIFO <= LastFIFOSample then begin
               DACFIFO^[iFIFO] := DACValues[iDAC*NumDACChannels+ch] ;
               Inc(iFIFO) ;
               end ;

           // Copy digital values
           if DigitalInUse then begin
              iDig := Min( Trunc(Counter),nPoints-1) ;
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
       Config.SequenceLength := FNumADCChannels ;
       for ch := 0 to FNumADCChannels-1 do begin
           Sequence[ch] := Sequence[ch] or DACChannel[ch] ;
           end ;
       Sequence[FNumADCChannels-1] := Sequence[FNumADCChannels-1] or OUTPUT_UPDATE ;

       // Copy D/A values into D/A FIFO buffers
       for i := 0 to FNumADCSamples-1 do begin

           iDAC := Min( i, nPoints-1 ) ;
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

    outputdebugstring(pchar(format('%d',[iFIFO])));

    Config.Sequence := @Sequence ;
    Config.SequenceLengthIn := 0 ;
    Config.SequenceIn := Nil ;

    Config.ResetFIFOFlag := 1 ;
    Config.ControlLight := 0 ;
    Config.SamplingInterval := FADCSamplingInterval ;
    Err := ITC_ConfigDevice( Device, Config ) ;
    ITCMM_CheckError( Err, 'ITC_ConfigDevice' )  ;

    // Write D/A samples to FIFO
    ChannelData.ChannelType := H2D or RESET_FIFO_COMMAND or PRELOAD_FIFO_COMMAND {or LAST_FIFO_COMMAND} ;
    ChannelData.ChannelNumber := 0 ;
    ChannelData.Value :=  Min(FNumADCSamples*FNumADCChannels,FIFOMaxPoints) ;
    ChannelData.DataPointer := DACFIFO ;
    Err := ITC_ReadWriteFIFO( Device, 1, ChannelData ) ;
    ITCMM_CheckError(Err,'ITC_ReadWriteFIFO') ;

    {Save D/A sweep data }
    DACPointer := Min(FNumADCSamples*FNumADCChannels,FIFOMaxPoints)  ;
    FNumDACPoints := nPoints ;
    FNumDACChannels := NumDACChannels ;

    // Start combined A/D & D/A sweep
    if WaitForExternalTrigger then StartInfo.ExternalTrigger := 1
                              else StartInfo.ExternalTrigger := 0 ;
    StartInfo.OutputEnable := 1 ;      // Enable D/A output on interface
    StartInfo.StopOnOverFlow := 1 ;    // Stop FIFO on A/D overflow
    StartInfo.StopOnUnderRun := 1 ;    // Stop FIFO on D/A underrun
    StartInfo.RunningOption := 0 ;
    Err := ITC_Start( Device, StartInfo ) ;
    ITCMM_CheckError( Err, 'ITC_Start' ) ;

    ADCActive := True ;
    Result := ADCActive ;

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

     // Note. Since D/A sub-system of ITC boards is strictly linked
     // to A/D sub-system, this procedure does nothing
     Result := False ;

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
     if not DeviceInitialised then Exit ;
     if ADCActive then Exit ;

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
     ITCMM_CheckError( Err, 'ITC_AsyncIO' ) ;

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
     Result := 0 ;
     if not DeviceInitialised then ITCMM_InitialiseBoard ;
     if not DeviceInitialised then Exit ;
     if ADCActive then Exit ;

     ChannelData.ChannelType := D2H ;
     ChannelData.ChannelNumber := Channel ;
     Err := ITC_AsyncIO( Device, 1, ChannelData ) ;
     ITCMM_CheckError( Err, 'ITC_AsyncIO' ) ;
     Result := ChannelData.Value ;

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
begin

     if not DeviceInitialised then Exit ;

     { Stop any acquisition in progress }
     ITCMM_StopADC ;

     { Close connection with interface }
     ITC_CloseDevice( Device  ) ;

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
     //outputdebugString(PChar('Error ' + ErrName + ' in ' + ErrSource));
     end ;

   end ;

end.
