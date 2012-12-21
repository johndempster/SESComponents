{------------------------------------------------------------------------------}
{ FileName :                                                                   }
{     VP500lib.pas                                                             }
{ Description :                                                                }
{     32-bit Delphi language interface for accessing the library BLVP500.DLL.  }
{			This file contains functions prototypes, variables and constants         }
{			defined for controlling a VP500 from a Windows® application.   					 }
{ Author:                                                                      }
{     Franck GARNIER                                                           }
{                                                                              }
{ (c) Bio-Logic compagny                                                       }
{ August 2003                                                                  }
{                                                                              }
{------------------------------------------------------------------------------}
// 17.2.04 ... Modified to make BLVP500.dll functions dynamically loaded (J. Dempster)
// 22.3.04 ... Modified to supporr BVLP500 V1.1

unit VP500lib;

INTERFACE

{==============================================================================}
{ Error codes returned by the functions. 																			 }
{==============================================================================}
const
  //General error codes
  RSP_NO_ERROR                    =  0;   { Function succeeded }
  RSP_BLVP500_LIB_NOT_INIT        = -1;   { BLVP500 library not initialized }
  RSP_PARAMETERS_ERROR            = -2;   { Invalid parameters to function call }
  RSP_COMM_FAILED                 = -3;   { Communication between the VP500 and the GPIB board failed }
  RSP_UNEXPECTED_ERROR            = -4;   { Unexpected error }
  RSP_NOT_ALLOWED_CONT_ACQ_MODE  	= -5;  	{ Function not allowed in continuous acquisition mode }
  RSP_NOT_VCLAMP_MODE							= -6;		{ Function only allowed in V-Clamp and V-Track mode }

  //GPIB library error codes
  RSP_GPIB32_LOAD_LIB_FAILED      = -10;  { gpib-32.dll : LoadLibrary failed }
  RSP_GPIB32_GET_PROC_ADDR_FAILED = -11;  { gpib-32.dll : GetProcAddress failed }
  RSP_GPIB32_FREE_LIB_FAILED      = -12;  { gpib-32.dll : FreeLibrary failed }

  //VP500 & GPIB board error codes
  RSP_UNABLE_FIND_GPIB_BOARD      = -20;  { Unable to find the GPIB board }
  RSP_UNABLE_FIND_VP500           = -21;  { Unable to find the VP500 device }
  RSP_UNABLE_INIT_GPIB_BOARD      = -22;  { Unable to initialize the GPIB board }
  RSP_UNABLE_INIT_VP500           = -23;  { Unable to initialize the VP500 device }

  //Load firmware error codes
  RSP_UNABLE_CFG_VP500            = -30;  { Unable to configure VP500 }
  RSP_BAD_VP500_IDENT             = -31;  { Wrong VP500 identifier }
  RSP_LOAD_FIRMWARE_ERR           = -32;  { Error during the downloading of the firmware }
  RSP_CODE_SEG_ERR                = -33;  { Wrong VP500 code segment }
  RSP_FILE_NOT_FOUND              = -34;  { "VP500.bin" not found }
  RSP_FILE_ACCESS_ERR             = -35;  { "VP500.bin" access error }

  //Acquisition error codes
  RSP_ACQ_IN_PROGRESS             = -40;  { An acquisition is already in progress }
  RSP_ACQ_DATA_FAILED             = -41;  { Data acquisition on VP500 failed }
  RSP_GET_ADC1_DATA_FAILED        = -42;  { Get ADC1 data failed }
  RSP_GET_ADC2_DATA_FAILED        = -43;  { Get ADC2 data failed }
  RSP_ADC1_DATA_EXCEPTION         = -44;  { Exception occurred during treatment of ADC1 data }
  RSP_ADC2_DATA_EXCEPTION         = -45;  { Exception occurred during treatment of ADC2 data }

  //Stimulation error codes
  RSP_STIM_LOAD_FAILED						= -50; 	{ Can not load programmed stimulation in the VP500 }
  RSP_STIM_TRANSFER_FAILED				= -51;	{ Can not transfer programmed stimulation in the RAM of the VP500 }
  RSP_STIM_NOT_TRANSFERRED				= -52;  { Programmed stimulation not transferred in the RAM of the VP500 }
  RSP_NOT_ENOUGH_MEMORY						= -53;	{ Not enough memory in the VP500 (too many points to acquire) }
  RSP_ACQ_TIME_OUT                = -54;  { Acquisition time out }


{==============================================================================}
{ Integer and real data types.                                                 }
{==============================================================================}
Type
  int8    = ShortInt;  { signed 8-bit    }
	int16   = SmallInt;  { signed 16-bit   }
	int32   = LongInt;   { signed 32-bit   }
  uint8   = byte;      { unsigned 8-bit  }
  uint16  = Word;	     { unsigned 16-bit }
  uint32  = Longword;  { unsigned 32-bit }

  Ptrint8   = ^int8;
  Ptrint16  = ^int16;
  Ptrint32  = ^int32;
  PtrUint8  = ^uint8;
  PtrUint16 = ^uint16;
  PtrUint32 = ^uint32;
  
  PtrSingle = ^single;
    
{==============================================================================}
{ Initialization and release of the library.                                   }
{==============================================================================}
{$IFNDEF BLVP500LIB}
  TVP500_InitLib = function : int32; stdcall ;
  TVP500_FreeLib = procedure ; stdcall ;
{$ENDIF}


{==============================================================================}
{ Test of the communication between the library and the VP500.                 }
{==============================================================================}
{$IFNDEF BLVP500LIB}
  TVP500_TestTransfer = function : int32; stdcall ;
{$ENDIF}

{==============================================================================}
{ VP500 informations.                                                           }
{==============================================================================}
Type
  TBLVP500Infos = packed record
    LibVersion          : array [0..7] of Char;   { Library version }
    FirmwareVersion     : array [0..7] of Char;   { Firmware version }
    CodeSegment         : uint16;                 { VP500 code segment }
    NMIInterruptMode    : boolean;                { NMI Interrupt Mode }
    Switch              : int32;                  { VP500 switch }
    Checksum            : int32;                  { VP500 checksum }
  end;
  PtrTBLVP500Infos = ^TBLVP500Infos;

{$IFNDEF BLVP500LIB}
   TVP500_GetInfos = function(pInfos: PtrTBLVP500Infos): int32; stdcall;
{$ENDIF}


{==============================================================================}
{ VP500 wave stimulator.                                                       }
{==============================================================================}
const
  //Wave direction : constants used by the field "Direction" in the record "TWStimParams"
  WS_UP         	 = 0;    { Wave direction : UP   }
  WS_DOWN       	 = 1;    { Wave direction : DOWN }
  WS_BOTH       	 = 2;    { Wave direction : BOTH }
  //Filter : constants used by the field "Filter" in the record "TWStimParams"
  WS_FILTER_FULL   = 0;
  WS_FILTER_10_KHZ = 1;
  WS_FILTER_1_KHZ  = 2;

Type
  TWStimParams = packed record
    Ramp        		: boolean;    { Wave type : TRUE->ramp  FALSE->pulse}
    Amplitude       : single;     { Signal amplitude -> mV in potential clamp mode }
    															{	................ -> nA in current clamp mode }
    Period          : uint32;     { Signal period (20µs) }
    TriggerOut      : boolean;    { Trigger out (BNC connector "[Stimulation] Trigger Out") }
    Direction       : uint8;      { Wave direction }
    Filter          : uint8;      { stimulation filter }
    ExternalStim    : boolean;    { External stimulation on BNC connector "[Command] Vin/Iin") }
    SendStimOut     : boolean;    { Send stimulation to the BNC connector "[Stimulation] Out" }
  end;
  PtrTWStimParams = ^TWStimParams;

	TSingleRamp = packed record
    Amplitude 	: single;     { Signal amplitude -> mV in potential clamp mode }
    													{	................ -> nA in current clamp mode }
    Length    	: uint32;     { Signal length (10µs) }
  end;
  PtrTSingleRamp = ^TSingleRamp;

{$IFNDEF BLVP500LIB}
  //Set wave stimulator parameters :
  TVP500_SetWaveStimParams = function( pWStimParams: PtrTWStimParams): int32 ; stdcall;
  //Get wave stimulator parameters :
   TVP500_GetWaveStimParams = function(pWStimParams: PtrTWStimParams): int32; stdcall;
  //Start wave stimulator :
  TVP500_StartWaveStim = function : int32; stdcall;
  //Stop wave stimulator :
  TVP500_StopWaveStim = function : int32; stdcall;

  //Generate a single ramp :
  TVP500_SingleRamp = function(pSRamp: PtrTSingleRamp): int32; stdcall;
{$ENDIF}


{==============================================================================}
{ VP500 holding potential/current.                                             }
{==============================================================================}
{$IFNDEF BLVP500LIB}
	//Set VIHold value (mV in potential clamp mode ; nA in current clamp mode)
  TVP500_SetVIHold  = function(VIHold: single): int32; stdcall;
	//Get VIHold value (mV in potential clamp mode ; nA in current clamp mode)
  TVP500_GetVIHold = function(pVIHold: PtrSingle): int32; stdcall;
{$ENDIF}


{==============================================================================}
{ VP500 hardware configuration.                                                }
{==============================================================================}
const
  //Clamp modes : constants used by the field "ClampMode" in the record "THardwareConf"
  VIMODE_V_CLAMP 			= 0;    { V-Clamp = Voltage clamp mode }
  VIMODE_IO      			= 1;    { Io      = voltage follower mode of the amplifier }
  VIMODE_I_CLAMP 			= 2;    { I-Clamp = Current clamp mode }
  VIMODE_V_TRACK 			= 3;    { V-Track = zero current voltage clamp }
  //Clamp speed (in current clamp mode): constants used by the field "ClampSpeed"
  //in the record "THardwareConf"
  VIMODE_SPEED_SLOW   = 0;		{ Slow time constant   }
  VIMODE_SPEED_MEDIUM = 1;    { Medium time constant }
  VIMODE_SPEED_FAST   = 2;    { Fast time constant   }
  //Amplifier stage filter : constants used by the field "AmplifierStageFilter"
  //in the record "THardwareConf"
  //WARNING : in VTrack mode, the amplifier stage filter is forced to AMPL_FILTER_100_HZ
  AMPL_FILTER_100_HZ 	= 0;    { cut-off frequency = 100 Hz }
  AMPL_FILTER_200_HZ	= 1;    { cut-off frequency = 200 Hz }
  AMPL_FILTER_500_HZ 	= 2;    { cut-off frequency = 500 Hz }
  AMPL_FILTER_1_KHZ  	= 3;    { cut-off frequency =  1 kHz }
  AMPL_FILTER_2_KHZ  	= 4;    { cut-off frequency =  2 kHz }
  AMPL_FILTER_5_KHZ  	= 5;    { cut-off frequency =  5 kHz }
  AMPL_FILTER_10_KHZ 	= 6;    { cut-off frequency = 10 kHz }
  AMPL_FILTER_20_KHZ 	= 7;    { cut-off frequency = 20 kHz }
  AMPL_FILTER_50_KHZ 	= 8;    { cut-off frequency = 50 kHz }
  //Amplifier stage gain : constants used by the field "AmplifierStageGain" in
  //the record "THardwareConf"
  AMPL_GAIN_1   			= 0;    { Amplifier gain: x1   }
  AMPL_GAIN_2   			= 1;    { Amplifier gain: x2   }
  AMPL_GAIN_5   			= 2;    { Amplifier gain: x5   }
  AMPL_GAIN_10  			= 3;    { Amplifier gain: x10  }
  AMPL_GAIN_20  			= 4;    { Amplifier gain: x20  }
  AMPL_GAIN_50  			= 5;    { Amplifier gain: x50  }
  AMPL_GAIN_100 			= 6;    { Amplifier gain: x100 }
  AMPL_GAIN_200 			= 7;    { Amplifier gain: x200 }
  AMPL_GAIN_500 			= 8;    { Amplifier gain: x500 }

Type
  THardwareConf = packed record
    ClampMode            : uint8;   { Clamp mode  }
    ClampSpeed           : uint8;   { Clamp speed }
    AmplifierStageFilter : uint8;   { Amplifier stage filter }
    AmplifierStageGain   : uint8;   { Amplifier stage gain   }
    HeadGainH            : boolean; { High (TRUE) or low head gain (FALSE) }
    HeadGainHigh         : double;  { High head gain value (Gohm) - READ ONLY }
    HeadGainLow          : double;  { Low head gain value (Gohm) - READ ONLY }
    TotalGain            : double;  { Total gain (mV/pA) = head gain x amplifier stage gain - READ ONLY }
    AmplitudeMax    		 : single;	{ Signal amplitude max -> mV in potential clamp mode - READ ONLY }
  															    {	.................... -> nA in current clamp mode   - READ ONLY }
    GPIBTimeOut          : uint8;   { GPIB timeout period }
  end;
  PtrTHardwareConf = ^THardwareConf;

{$IFNDEF BLVP500LIB}
  TVP500_SetHardwareConf = function(pHardwareConf: PtrTHardwareConf): int32; stdcall;
  TVP500_GetHardwareConf = function(pHardwareConf: PtrTHardwareConf): int32; stdcall;
{$ENDIF}


{==============================================================================}
{ VP500 status flags.                                                      		 }
{==============================================================================}
Type
  //VP500 status structure
  TVP500Status = packed record
    //Status flags:
    IHeadOverload 	 : boolean;   { IHead overload }
    VmOverload    	 : boolean;   { Vm overload }
    ADC1Overload  	 : boolean;   { ADC1 overload }
    ADC2Overload  	 : boolean;   { ADC2 overload }
    AcqADC1       	 : boolean;   { Acquisition on ADC1 }
    AcqADC2       	 : boolean;   { Acquisition on ADC2 }
    WaveStim      	 : boolean;   { Wave stimulator ON }
    TestSignal    	 : boolean;   { Test signal }
    InputTTL0     	 : boolean;   { Input TTL0 }
    InputTTL1     	 : boolean;   { Input TTL1 }
    InputTTL2    	 	 : boolean;		{ Input TTL2 }
    //Memory status:
    TotalBlocksNb 	 : int32;     { Number of memory blocks shared by ADC1 and ADC2 (1 block = 1024 points) }
  	ADC1FullBlocksNb : int32;			{ ADC1 : number of full blocks }
  	ADC2FullBlocksNb : int32;			{ ADC2 : number of full blocks }
  end;
  PtrTVP500Status = ^TVP500Status;

{$IFNDEF BLVP500LIB}
 TVP500_GetVP500Status = function(pStatus : PtrTVP500Status): int32; stdcall;

{$ENDIF}


{==============================================================================}
{ VP500 ADC buffers.                                                       		 }
{==============================================================================}
const
  //Sampling rate : constants used by the field "SamplingRate" in the record "TData"
	SAMPLING_RATE_100_KHZ = 0;  	{ 100 kHz }
	SAMPLING_RATE_50_KHZ  = 1;  	{  50 kHz }
	SAMPLING_RATE_20_KHZ  = 2;  	{  20 kHz }
	SAMPLING_RATE_10_KHZ  = 3;  	{  10 kHz }
	SAMPLING_RATE_5_KHZ   = 4;  	{   5 kHz }
	SAMPLING_RATE_2_KHZ   = 5;  	{   2 kHz }
	SAMPLING_RATE_1_KHZ   = 6;  	{   1 kHz }
	SAMPLING_RATE_500_HZ  = 7;  	{  500 Hz }
  //Data Selection of ADC1 buffer : constants used by the field "ADC1Selection"
  //in the record "TData".
  //In potential clamp mode VI=Vm (mV) ; in current clamp mode VI=Iout (pA)
  READ_VI               = 0;   	{ Read VI   }
  READ_AUX1             = 1;   	{ Read AUX1 }
  READ_AUX2             = 2;   	{ Read AUX2 }
  READ_AUX3             = 3;   	{ Read AUX3 }
  READ_AUX4             = 4;   	{ Read AUX4 }
  READ_VI_AUX1          = 5;   	{ Read VI and AUX1 }
  READ_VI_AUX2          = 6;   	{ Read VI and AUX2 }
  READ_VI_AUX3          = 7;   	{ Read VI and AUX3 }
  READ_VI_AUX4          = 8;   	{ Read VI and AUX4 }
  READ_AUX1_AUX2        = 9;   	{ Read AUX1 and AUX2 }
  READ_AUX1_AUX3        = 10;  	{ Read AUX1 and AUX3 }
  READ_AUX1_AUX4        = 11;  	{ Read AUX1 and AUX4 }
  READ_AUX2_AUX3        = 12;		{ Read AUX2 and AUX3 }
  READ_AUX2_AUX4 				= 13;  	{ Read AUX2 and AUX4 }
  READ_AUX3_AUX4 				= 14;  	{ Read AUX3 and AUX4 }

Type
  //Acquisition parameters structure
  TAcqParams = packed record
    SamplingRate  : uint8;     	{ Sampling rate (100kHz -> 500Hz) }
    ADC1Selection : uint8;      { Data acquired by ADC1 }
    AuxAInput 		: boolean;		{ Auxiliary input selection : Aux A (TRUE) or Aux B (FALSE) }
  end;
  PtrTAcqParams = ^TAcqParams;

  //Acquisition structure
  TData = packed record
    //Parameters:
    LengthBufADC 	: uint32;			{ Length of the buffers "BufADC1" and "BufADC2" }
    SynchData  		: boolean;    { Synchronise data in ADC buffers (only available if }
    														{ the continuous acquisition is NOT active and the   }
    														{ wave stimulator is ON). Only 1 block will be acquired. }
    //Result:
    BufADC1       : PtrSingle;	{ ADC1 buffer : contains multiplexed data (depending of "ADC1Selection") }
    BufADC2       : PtrSingle; 	{ ADC2 buffer : Iout (pA) in potential clamp mode }
    														{	...........   Vm   (mV) in current clamp mode }
    NbPtsBufADC1	: uint32;			{ Number of points put in the buffer "BufADC1" }
    NbPtsBufADC2	: uint32;			{ Number of points put in the buffer "BufADC2" }
  end;
  PtrTData = ^TData;

{$IFNDEF BLVP500LIB}
  //Set acquisition parameters
  TVP500_SetAcqParams = function(pAcqParams: PtrTAcqParams) : int32; stdcall;
  //Get ADC buffers
	TVP500_GetADCBuffers = function(pData: PtrTData): int32; stdcall;
  //Start continuous acquisition
  TVP500_StartContinuousAcq = function : int32; stdcall;
  //Stop continuous acquisition
  TVP500_StopContinuousAcq = function: int32; stdcall;
{$ENDIF}

{==============================================================================}
{ VP500 progammed stimulations. 																 							 }
{==============================================================================}
type
  TDigitalOutput = packed record
    Duration	: uint32;		{ Duration of the "true" level (ms) }
  	Output	 	: uint16;		{ Digital outputs to activate : bit0 -> digital output 1 }
		                      { ...........................   bit1 -> digital output 2 }
                          { ...........................   ........................ }
                          { ...........................   bit8 -> digital output 9 }
  end;

  TBasicStim = packed record
    Ramp				: boolean;	{ TRUE->Ramp ; FALSE->Pulse }
    Duration		: uint32;		{ Duration of the basic stimulation (µs) }
    Amplitude		: single;		{ PULSE : Amplitude of the basic stimulation }
    												{ RAMP : Amplitude to reach by the basic stimulation }
														{ 	-> mV in potential clamp mode }
    												{		-> nA in current clamp mode }
  end;
	TBasicStimTab = array[0..99] of TBasicStim;
	PtrTBasicStimTab = ^TBasicStimTab;

  //Programmed stimulations structure
	TStim = packed record
  	//Stimlations :
	  StimTab 					: TBasicStimTab;	{ Array of basic stimulations }
  	StimTabNb					: uint8; 					{ Number of valid basic stimulations in the array "StimTab" }
    RecDuration				: uint32;					{ Total recording duration (10µs), included InitialDelay }
    InitialDelay			: uint32;					{ Initial delay before stimulations (10µs) }
    //Digital outputs :
    DigitalOutput			: TDigitalOutput;	{ Digital outputs }
    //Result
    NbBlocksToAcq     : uint32;         { Number of blocks to acquire for each ADC }
  end;
  PtrTStim = ^TStim;

{$IFNDEF BLVP500LIB}
   //Start programmed stimulations
  TVP500_StartStim  = function (pStim: PtrTStim): int32; stdcall;
  //Stop programmed stimulations
  TVP500_StopStim = function : Int32 ; stdcall;

{$ENDIF}


{==============================================================================}
{ VP500 seal (only available in potential clamp mode).												 }
{==============================================================================}
type
  //Seal impedance structure
	TSealImpedance = packed record
    //Parameters:
    Amplitude     : single;   { Signal amplitude (mV) }
    Period        : uint32;   { Signal period (20µs) }
    DirectionUp   : boolean;  { Signal direction: up (TRUE) or down (FALSE) }
    //Result:
    SealImpedance	: single;		{ Seal impedance (Mohm) - READ ONLY }
  end;
  PtrTSealImpedance = ^TSealImpedance;

{$IFNDEF BLVP500LIB}
  //Apply zap -> ZapDuration (10µs) [min = 10µs; max = 1500µs]
  TVP500_DoZap = function(ZapDuration: uint16): int32; stdcall;
  //Set junction potential compensation (mV)
  TVP500_SetJunction = function(val: single): int32; stdcall;
  //Get junction potential compensation (mV)
  TVP500_GetJunction = function(pVal: PtrSingle): int32; stdcall;
  //Determination of the seal impedance
  TVP500_CalcSealImpedance = function(pSealImpedance: PtrTSealImpedance): int32; stdcall;
{$ENDIF}


{==============================================================================}
{ VP500 compensations and neutralizations. 						 							 					 }
{==============================================================================}
const
  //Delay of series resistance compensation loop: constants used by the field
  //"TauPercentRs" in the record "TCompensations" :
  DELAY_1_MICROS   = 0;   { delay 1 µs }
  DELAY_3_MICROS   = 1;   { delay 3 µs }
  DELAY_7_MICROS   = 2;   { delay 7 µs }
  DELAY_10_MICROS  = 3;   { delay 10 µs }
  DELAY_20_MICROS  = 4;   { delay 20 µs }
  DELAY_30_MICROS  = 5;   { delay 30 µs }
  DELAY_60_MICROS  = 6;   { delay 60 µs }
  DELAY_100_MICROS = 7;   { delay 100 µs }

type
  TCompensations = packed record
  	PercentBoost : uint8;		{ Cell capacitance compensation (%) : precharging circuit (boost) }
    PercentRs		 : uint8;   { Pipette resistance compensation (%) : series resistance compensation }
    TauPercentRs : uint8;   { Series resistance lag }
  end;
  PtrTCompensations = ^TCompensations;

  TLimits = packed record
  	Max : single;
    Min : single;
  end;

  TNeutralization = packed record
  	CFast			 : single;		{ Fast capacitance neutralization (pF) }
    TauFast 	 : single;    { (µs) }
    CSlow   	 : single;    { Slow capacitance neutralization (pF) }
    TauSlow 	 : single;    { (ms) }
    CCell   	 : single;    { Cell capacitance neutralization (pF) }
    TauCell 	 : single;		{ (ms) }
    Leak			 : single;    { Leak neutralization (nS) }
    //Read only fields :
    CFast_L	 	 : TLimits;		{ CFast limits 	 (pF) - READ ONLY }
    TauFast_L	 : TLimits;	  { TauFast limits (µs) - READ ONLY }
    CSlow_L    : TLimits;   { CSlow limits 	 (pF) - READ ONLY }
    TauSlow_L  : TLimits;   { TauSlow limits (ms) - READ ONLY }
    CCell_L    : TLimits;   { CCell limits 	 (pF) - READ ONLY }
    TauCell_L  : TLimits;   { TauCell limits (ms) - READ ONLY }
    Leak_L		 : TLimits;   { Leak limits 	 (nS) - READ ONLY }
  end;
  PtrTNeutralization = ^TNeutralization;

  TNeutralizationParams = packed record
  	MaxPassNb_CFast_CSlow	: uint32;		{ Number of iterations in the hybrid algorithms }
    																	{ of C-Fast and C_Slow                          }
  	MaxPassNb_CCell_COpt	: uint32; 	{ Number of iterations in the hybrid algorithms }
    																	{ of C-Cell and C_Opt                           }
    PercentLeakComp				: uint8;		{ %leak compensation }
    AutoOff_AccessR				: boolean;  { Automatic reset the series resistance compensation }
    																	{ when the amplifier starts to oscillate             }
    ClampRatio						: single;   { Clamp ratio : Rs/(Rs + Rm)                    }
    																	{ Proportion of the command voltage lost in the }
                                      { series resistance before the preparation.     }
    EquivalentRes					: single;		{ Equivalent resistance (Mohm) : Rs.Rm/(Rs+Rm)	}
    																	{ Ratio of the capacitive current time constant }
                                      { to the condenser capacity. 										}
  end;
  PtrTNeutralizationParams = ^TNeutralizationParams;

{$IFNDEF BLVP500LIB}
  //Reinitialization of compensations and neutralizations
  TVP500_Reinitialization = function: int32; stdcall;

  //Manual compensations :
  TVP500_SetCompensations = function(pComp: PtrTCompensations): int32; stdcall;
  TVP500_GetCompensations = function(pComp: PtrTCompensations): int32; stdcall;
  //Manual neutralizations :
  TVP500_SetNeutralization = function(pNeutr: PtrTNeutralization): int32; stdcall;
  TVP500_GetNeutralization = function(pNeutr: PtrTNeutralization): int32; stdcall;

  //Neutralization parameters :
  TVP500_SetNeutralizationParams = function(pNParams: PtrTNeutralizationParams): int32; stdcall;
  TVP500_GetNeutralizationParams = function(pNParams: PtrTNeutralizationParams): int32; stdcall;
  //Automatic neutralization of Cfast :
  TVP500_CFastNeutralization = function: int32; stdcall;
  //Automatic neutralization of Cslow :
  TVP500_CSlowNeutralization = function: int32; stdcall;
  //Automatic neutralization of Ccell and leak :
  TVP500_CCellNeutralization = function: int32; stdcall;
  //Automatic neutralization of leak:
  TVP500_LeakNeutralization = function: int32; stdcall;
  //Automatic optimisation of neutralization of Ccell and leak :
  TVP500_OptimizeNeutralization = function: int32; stdcall;
{$ENDIF}


{==============================================================================}
{ VP500 cell parameters. 						 							 					 									 }
{==============================================================================}
type
	TCellParameters = packed record
    Rs : single;		{ Serial resistance (Mohm) }
  	Cm : single; 		{ Membrane capacitance (pF) }
    Rm : single;	 	{ Membrane resistance (Mohm) }
  end;
  PtrTCellParameters = ^TCellParameters;

{$IFNDEF BLVP500LIB}
  //Detection of cell parameters :
  TVP500_CellParameters = function(pCellParameters: PtrTCellParameters): int32; stdcall;
{$ENDIF}

IMPLEMENTATION

end.
