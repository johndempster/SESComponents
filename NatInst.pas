unit NatInst;
{ =================================================================
  National Instruments Interface Library V1.1
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  12/2/97 V1.1 Dynamic DLL loading now used.
  5/3/98 V1.2 DMA support can now be disabled
  2/4/98 V1.2a Set_DAQ_Device_Info now only called (by NIADCToMemory)
         when required
  31/5/98 V1.2b Disable DMA code added to MemoryToDAC to avoid -10609
          error when MemoryToDAC called before ADCToMemory
  14/6/99 NI_MemoryToDAC ... NumRepeats replaced by Cyclic
  22/6/99 NI_InitialiseBoard added
  20/11/99 Board list updated to 244 (NIDAQ V6.1)
  21/12/99 ADCToMemory now works with Pci-1200 (NIDAQ Error -10403)
  20/1/2000 ADCToMemory now works with Lab-PC1200/AI (58) (NIDAQ Error -10403)
  4/1/2001 Errors in NI_CheckSamplingInterval corrected
  7/3/2001 -10697 error with E-Series boards when dt>3 ms fixed
  11/10/01 PCI-6052 and PCI-6035 now has correct voltage ranges
           +/- 5,0.5,0.05 V
  6/12/01 Hang-up problem with 16 bit boards fixed (NI_GetLabInterfaceInfo)
  20/12/01 MinDACValue and MaxDACValue properties added to support cards such
           as the PCI-6035E which has 16 bit A/D but 12 bit D/A.
  21.5.02  Support for -AI variants of N.I. cards (which lack D/A converters) added
  15.7.02  Support for E-Series digital outputs added (10 ms resolution)
  17.7.02  DAC update interval now constrained to be 10ms when digitsl stimuli used
           with E-Series N.I. boards
  26.11.02 +/-10V A/D input voltage range now supported
           Corrections made to a number of A/D voltage ranges for a number of cards
  16.12.02 Support for DAQCard 6036E added(NIDAQ 6.9.3)
  7.1.02   A/D voltage range of individual channels can now be set
           (not supported by Lab-PC/PC-1200 series boards)
  16.4.03  Support for PCI-6014E added
  27.4.03  Single 1 ms 5V DAC 1 sync. pulse now produced with E-Series boards
           (rather than series of pulse as produced by Lab-PC series
  21.1.04  Support for DaqCard-6023/4 added
  9.02.04  D/A and digital stimulus waveforms can now be started
           by external trigger pulse
           Resolution of A/D and D/A now reported in Model name
  23.03.04 External triggering of waveform output now works correctly
           with E Series boards
  30.07.04 Support for Active High & Low External triggering added
  06.10.04 E Series A/D and D/A sweeps now synchronised via RTSI bus
           E Series Digital output routines updated
  07.03.05 RepeatWaveform option added to NI_MemoryToDAC
  21.07.05 A/D input mode can be set to differential or NRSE
  04.11.05 MemoryToDAC .. DAC output points now limited to available buffer size
  11.02.08 All Lab-PC boards now use interrupt for A/D data transfers
           (fixes glitches caused by byte DMA transfer of word data
  08.03.10 DAQCard 6036E DAC update rate now correctly set to 1 ms.
  25.06.10 Support for S series cards added (PCI-6110 etc.)
           DAC update rate now checked using NI_CheckDACUpdateInterval
  // 08.09.10 DeviceNumber kept within 1-9 range
  02.03.11 D/A output to PCI-6110 now has correct timebase
           NI_DeviceExists function added.
  07.03.11 If selected device does not exist, another is chosen when
           interface is opened.
  22.08.11 A/D inputs can now be mapped to selected input channels using
           ADCChannelInputNumber
  23.08.11 Now report number of analog input channels
  14.10.11 NI_GetLabInterfaceInfo now returns DeviceList containing list
           available NI devices and
           DACMaxChannels the max. number of D/A channels
  =================================================================}

interface

uses WinTypes,Dialogs, SysUtils, WinProcs, NIDAQCNS, math, classes, strutils ;

  function NI_InitialiseBoard : Boolean ;
  procedure NI_LoadNIDAQLibrary  ;
  function NI_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }


  function NI_ADCToMemory(
            var ADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var SamplingInterval : Double ;
            ADCVoltageRanges : Array of Single ;
            TriggerMode : Integer ;
            ADCExternalTriggerActiveHigh : Boolean ;
            CircularBuffer : Boolean ;
            ADCInputMode : Integer ;
            ADCChannelInputNumber : Array of Integer // A/D input channel map
            ) : Boolean ;

  function NI_StopADC : Boolean ;

  function NI_MemoryToDAC(
            var DACBuf : Array of SmallInt  ;
            nChannels : SmallInt ;
            nPoints : Integer ;
            UpdateInterval : Double ;
            RepeatWaveform : Boolean
            ) : Boolean ;

  function NI_StopDAC : Boolean ;

  procedure NI_WriteDACs(
            DACVolts : array of Single ;
            nChannels : Integer
            ) ;

  procedure NI_GetDeviceList(
            var DeviceList : TStringList
            ) ;

  function  NI_GetLabInterfaceInfo(
            var DeviceList : TStringList ;  
            var DeviceNumber : Integer ;  // Device #
            var ADCInputMode : Integer ;  // Analog input mode
            var Model : string ; { Laboratory interface model name/number }
            var ADCMaxChannels : Integer ; // No. of A/D channels
            var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
            var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
            var ADCMinValue : Integer ; { Negative limit of binary ADC values }
            var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
            var DACMaxChannels : Integer ; // No. of D/A channels
            var DACMinValue : Integer ; { Negative limit of binary DAC values }
            var DACMaxValue : Integer ; { Positive limit of binary DAC values }
            var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
            var NumADCVoltageRanges : Integer ; { No. of options in above list }
            var DACMaxVolts : Single ; { Positive limit of bipolar D/A voltage range }
            var DACMinUpdateInterval : Double ; {Min. D/A update interval }
            var DigMinUpdateInterval : Double ;{Min. digital update interval }
            var DigMaxUpdateInterval : Double ;{Min. digital update interval }
            var DigUpdateStep : Integer ; // Digital output step interval
            var ADCBufferLimit : Integer // Max. no. of A/D samples/buffer
            ) : Boolean ;

  function NI_ReadADC(
           Channel : Integer ;
           ADCVoltageRange : Single ;
           ADCInputMode : Integer
           ) : Integer ;

  procedure NI_CheckError(
            Err : Integer
            ) ;
  procedure NI_CheckSamplingInterval(
            var SamplingInterval : double ;
            NumADCChannels : Integer ;
            var TimeBase : SmallInt ;
            var ClockTicks : Word
            )  ;

  procedure NI_CheckDACUpdateInterval(
            var UpdateInterval : double ;  { Update interval (IN/OUT) }
            NumDACChannels : Integer
            )  ;
  function  NI_MemoryToDigitalPortHandshake(
            var Buf : Array of SmallInt  ;
            nBytes : Integer ;
            var WorkBuf : Array of SmallInt
            ) : Boolean ;

  procedure NI_StopDIG ;

  procedure NI_WriteToDigitalOutPutPort(
            Pattern : Integer
            ) ;

  function NI_ReadDigitalInputPort : Integer ;

  function NI_MemoryToDig(
          PDigBufIn : Pointer ;               // pointer to digital output buffer
          nPoints : Integer ;
          UpdateInterval : Double ;
          PDigWork : Pointer                // pointer to digital output work buffer
          ): Boolean ;                      { Returns TRUE=D/A active }

  procedure NI_UpdateDigOutput ;

  procedure NI_ArmStimulusTriggerInput ;
  function NI_StimulusTriggerInputState : Boolean ;

  procedure NI_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
  procedure NI_ReportFailure(
            const ProcName : string
            ) ;
  function NI_IsLabInterfaceAvailable : boolean ;

  function NI_GetValidExternalTriggerPolarity(
         Value : Boolean // TRUE=Active High, False=Active Low
         ) : Boolean ;

  procedure NI_CloseLaboratoryInterface ;
  function  IntLimit( Value : Integer ; LoLimit : Integer ; HiLimit : Integer
          ) : Integer ;

  procedure NI_DisableDMA_LabPC ;
  function NI_DeviceExists( iDev : Integer  ) : Boolean ;
  function NI_GetADCInputModeCode( ADCInputMode : Integer ) : SmallInt ;

implementation

uses SESLabIO ;
const

     ND_INTERRUPTS          = 19600;
     ND_DATA_XFER_MODE_AI   = 14000;
     ND_UP_TO_1_DMA_CHANNEL = 35200 ;
     ND_UP_TO_2_DMA_CHANNELS = 35300 ;
     DigPortGroup = 1 ;
     AsDigInputPort = 0 ;
     AsDigOutputPort = 1 ;

     TimeBasePeriod : Array[-3..5] of Single
     = (5E-8, 1.0, 2E-7, 1E-6, 1E-6, 1E-5, 1E-4, 1E-3, 1E-2 ) ;

type


   { NIDAQ.DLL procedure NI_ variables }
    pi16 = ^SmallInt ;
    PSmallInt = ^SmallInt ;
    PLongInt = ^LongInt ;

    TAI_Read = function (
               device : SmallInt ;
               chan : SmallInt ;
               gain : SmallInt;
               var value : SmallInt
               ) : SmallInt  ; stdcall ;
    TAI_VScale = function(
                 Device : SmallInt ;
                 Chan : SmallInt;
                 Gain : SmallInt ;
                 GainAdjust : Double ;
                 Offset : Double ;
                 Reading : SmallInt ;
                 var Voltage : Double
                 ) : SmallInt  ; stdcall ;

    TAI_Configure = function(
                  Device : SmallInt ;
                  Chan : SmallInt ;
                  InputMode : SmallInt ;
                  InputRange : SmallInt ;
                  Polarity : SmallInt ;
                  DriveAIS : SmallInt
                  ) : SmallInt  ; stdcall ;

    TAO_Write  = function(
                 device : SmallInt ;
                 chan : SmallInt ;
                 value : SmallInt
                 ) : SmallInt  ; stdcall  ;
    TAO_Update  = function(
                  device : SmallInt
                  ) : SmallInt  ; stdcall  ;
    TAO_VScale = function(
                 device : SmallInt ;
                 chan : SmallInt;
                 voltage : Double;
                 var value : SmallInt
                 ) : SmallInt  ; stdcall  ;
    TAO_VWrite = function(
                 device : SmallInt ;
                 chan : SmallInt;
                 voltage : Double
                 ) : SmallInt  ; stdcall  ;
    TDIG_Block_Clear = function(
                       device, grp : SmallInt
                       ) : SmallInt  ; stdcall  ;
    TDIG_Block_Check = function(
                       device, grp : SmallInt ;
                       var Remaining : Cardinal
                       ) : SmallInt  ; stdcall  ;

    TDIG_Block_Out = function(
                     device : SmallInt ;
                     grp : SmallInt;
                     buffer : Pointer;
                     cnt : Longint
                     ) : SmallInt  ; stdcall  ;
    TDIG_SCAN_Setup = function(
                      device : SmallInt ;
                      grp : SmallInt ;
                      numPorts : SmallInt;
                      portList : PSmallInt;
                      direction : SmallInt
                      ) : SmallInt  ; stdcall  ;
    TDIG_Prt_Config  = function(
                       device : SmallInt ;
                       port : SmallInt ;
                       latch_mode : SmallInt ;
                       direction : SmallInt
                       ) : SmallInt  ; stdcall  ;
    TDIG_Out_Port  = function (
                     device : SmallInt ;
                     port : SmallInt ;
                     pattern : Integer
                     ) : SmallInt  ; stdcall  ;
    TDIG_In_Port  = function (
                    device : SmallInt ;
                    port : SmallInt ;
                    Var pattern : Integer
                    ) : SmallInt  ; stdcall  ;
    TDAQ_Clear =  function(
                  device : SmallInt
                  ) : SmallInt  ; stdcall  ;
    TDAQ_Config = function(
                  device : SmallInt ;
                  StartTrig : SmallInt ;
                  ExtConv : SmallInt
                  ) : SmallInt  ; stdcall  ;
    TDAQ_DB_Config = function(
                     device: SmallInt ;
                     dbMode : SmallInt) :
                     SmallInt  ; stdcall  ;
    TDAQ_Rate = function(
                rate : Double;
                units : SmallInt;
                var timebase : SmallInt;
                var sampleInt : Word)
                : SmallInt  ; stdcall  ;

    TDAQ_Start = function(
                 device: SmallInt ;
                 chan : SmallInt ;
                 gain : SmallInt ;
                 buffer : Pointer;
                 cnt : Longint ;
                 timebase : SmallInt ;
                 sampInt : Word
                 ) : SmallInt  ; stdcall  ;
    TInit_DA_Brds = function(
                    device : SmallInt;
                    var brdCode : SmallInt
                    ) : SmallInt  ; stdcall  ;

    TLab_ISCAN_Start = function(
                       device: SmallInt ;
                       numChans: SmallInt ;
                       gain : SmallInt;
                       buffer : Pointer;
                       cnt : Longint;
                       timebase : SmallInt;
                       sampleInt : Word ;
                       scanInt : Word
                       ) : SmallInt  ; stdcall  ;
    TSCAN_Setup  = function(
                   device: SmallInt ;
                   num_chans : SmallInt;
                   chans : PSmallInt ;
                   gains : PSmallInt
                   ) : SmallInt  ; stdcall  ;
    TSCAN_Start  = function(
                   device : SmallInt;
                   buffer : Pointer;
                   cnt : Longint;
                   tb1 : SmallInt;
                   si1 : Word;
                   tb2 : SmallInt;
                   si2 : Word
                   ) : SmallInt  ; stdcall  ;
    TWFM_Rate = function(
                rate : Double;
                units : SmallInt;
                var timebase : SmallInt;
                var updateInterval : Cardinal
                ) : SmallInt  ; stdcall  ;
    TWFM_ClockRate = function(
                     device : SmallInt ;
                     group : SmallInt ;
                     whickClock : SmallInt ;
                     timebase : SmallInt;
                     updateInterval : Cardinal ;
                     mode : SmallInt
                     ) : SmallInt  ; stdcall  ;
    TWFM_Load = function(
                device : SmallInt ;
                numChans : SmallInt;
                chanVect : PSmallInt;
                buffer : PSmallInt;
                count : LongInt ;
                iterations : Longint;
                mode : SmallInt
                ) : SmallInt  ; stdcall  ;
    TWFM_Group_Control = function(
                         device : SmallInt ;
                         group : SmallInt ;
                         operation : SmallInt
                         ) : SmallInt  ; stdcall  ;
    TWFM_Check = function(
                 device : SmallInt ;
                 channel : SmallInt;
                 var status : SmallInt;
                 var pointsDone : Cardinal ;
                 var itersDone : Cardinal
                 ) : SmallInt  ; stdcall  ;
    TAO_Configure = function(
                    device : SmallInt ;
                    chan : SmallInt ;
                    outputPolarity : SmallInt ;
                    intOrExtRef : SmallInt;
                    refVoltage : Double;
                    updateMode : SmallInt
                    ) : SmallInt  ; stdcall  ;
    TSet_DAQ_Device_Info = function (
                           device : SmallInt;
                           infoType : LongInt ;
                           infoVal : LongInt
                           ) : SmallInt  ; stdcall  ;

    TSelect_Signal = function (
                     Device : SmallInt ;
                     Signal : Cardinal ;
                     SignalSource : Cardinal ;
                     SourceSpec : Cardinal  ) : SmallInt  ; stdcall  ;
    TGPCTR_Change_Parameter  = function (
                     Device : SmallInt ;
                     gpctrNum : Cardinal ;
                     paramID : Cardinal ;
                     paramValue : Cardinal ) : SmallInt  ; stdcall  ;
    TGPCTR_Control  = function (
                     Device : SmallInt ;
                     gpctrNum : Cardinal ;
                     Action : Cardinal ) : SmallInt  ; stdcall  ;
    TGPCTR_Set_Application  = function (
                     Device : SmallInt ;
                     gpctrNum : Cardinal ;
                     Application : Cardinal ) : SmallInt  ; stdcall  ;
    TGPCTR_Watch   = function (
                     Device : SmallInt ;
                     gpctrNum : Cardinal ;
                     entityID : Cardinal ;
                     var entityValue : Cardinal) : SmallInt  ; stdcall  ;

    TICTR_READ   = function (
                   Device : SmallInt ;
                   Counter : SmallInt ;
                   var Count : Word ) : SmallInt  ; stdcall  ;

    TICTR_Reset   = function (
                   Device : SmallInt ;
                   Counter : SmallInt ;
                   State : Word ) : SmallInt  ; stdcall  ;

    TICTR_Setup   = function (
                   Device : SmallInt ;
                   Counter : SmallInt ;
                   Mode : SmallInt ;
                   Count : Word ;
                   BinBCD : SmallInt ) : SmallInt  ; stdcall  ;

    TGet_DAQ_Device_Info = function(
                    device : SmallInt;
                    infoType : LongInt ;
                    var infoVal : LongInt
                    ) : SmallInt  ; stdcall  ;


var
   Init_DA_Brds : TInit_DA_Brds ;
   DAQ_Clear : TDAQ_Clear ;
   DAQ_Config : TDAQ_Config ;
   DAQ_DB_Config : TDAQ_DB_Config ;
   DAQ_Start : TDAQ_Start ;
   DAQ_Rate : TDAQ_Rate ;
   Lab_ISCAN_Start : TLab_ISCAN_Start ;
   SCAN_Setup : TSCAN_Setup ;
   SCAN_Start : TSCAN_Start ;
   WFM_Rate : TWFM_Rate ;
   WFM_ClockRate : TWFM_ClockRate ;
   WFM_Load : TWFM_Load ;
   WFM_Group_Control : TWFM_Group_Control ;
   WFM_Check : TWFM_Check ;
   AI_VScale : TAI_VScale ;
   AO_Configure : TAO_Configure ;
   AO_Write : TAO_Write ;
   AI_Configure : TAI_Configure ;
   AO_Update : TAO_Update ;
   AO_VScale : TAO_VScale ;
   AO_VWrite : TAO_VWrite ;
   DIG_Block_Clear : TDIG_Block_Clear ;
   DIG_Block_Check : TDIG_Block_Check ;
   DIG_Block_Out : TDIG_Block_Out ;
   DIG_SCAN_Setup : TDIG_SCAN_Setup ;
   DIG_Prt_Config : TDIG_Prt_Config ;
   DIG_Out_Port : TDIG_Out_Port ;
   DIG_In_Port : TDIG_In_Port ;
   AI_Read : TAI_Read ;
   Set_DAQ_Device_Info : TSet_DAQ_Device_Info ;
   Select_Signal : TSelect_Signal ;
   GPCTR_Change_Parameter : TGPCTR_Change_Parameter ;
   GPCTR_Control : TGPCTR_Control ;
   GPCTR_Set_Application : TGPCTR_Set_Application ;
   GPCTR_Watch : TGPCTR_Watch ;
   ICTR_Read : TICTR_Read ;
   ICTR_Reset : TICTR_Reset ;
   ICTR_Setup : TICTR_Setup ;
   Get_DAQ_Device_Info : TGet_DAQ_Device_Info ;

   NIBoardInitialised : Boolean ;
   BoardTypeNumber : SmallInt ;     { Board type in use }
   Device : Integer ;          // Device in use
   DigIOHandshakingSupported : Boolean ;  // True = Board type is in Lab-PC family
   LabPCTypeBoard : Boolean ;
   FADCVoltageRangeMax : single ;  { Max. positive A/D input voltage range}
   FADCMaxValue : Integer ;               // Max. A/D sample value
   FADCMinValue : Integer ;               // Min. A/D sample value
   FADCMinSamplingInterval : single ;     // Smallest value A/D sampling interval (s)
   FADCMaxSamplingInterval : single ;     // Largest value A/D sampling interval (s)
   FADCBufferLimit : Integer ;

   FDACMaxVolts : Single ;
   FDACMinUpdateInterval : Double ;
   FDACMaxUpdateInterval : Double ;
   FDACMaxValue : Integer ;
   FDACMinValue : Integer ;

   NIDAQLoaded : boolean ; { True if NIDAQ.DLL procedure NI_ loaded }
   ADCTransferModeInUse : Integer ;
   SSeriesBoard : Boolean ;
   ADCActive : Boolean ;     { A/D sampling inn progress flag }
   ADCTimeBase : SmallInt ;
   DACActive : Boolean ;     { D/A output in progress flag }
   DACHardwareAvailable : Boolean  ; // D/A output hardware available
   DACWarningDelivered : Boolean ;
   DigActive : Boolean ;
   DACDigActive : Boolean ;          // TRUE = Combined DAC/digital output active
   DigNumBytes : Integer ;

   PDACBuf : PSmallIntArray ;
   PDigBuf : PSmallIntArray ;
   DACDigNumPoints : Integer ;
   DACDigPointer : Integer ;
   DACDigNumDACChannels : Integer ;

procedure NI_GetDeviceList(
          var DeviceList : TStringList
          ) ;
const
    MaxDevices = 5 ;
// --------------------------------
// Return list of available devices
// --------------------------------
var
    iDev,Err : SmallInt ;
    BrdType : Integer ;
begin

   DeviceList.Clear ;
   if not NIDAQLoaded then NI_LoadNIDAQLibrary ;
   if not NIDAQLoaded then Exit ;

   // Determine number of boards installed
   for iDev := 1 to MaxDevices do begin
       Err := Get_DAQ_Device_Info( iDev, ND_DEVICE_TYPE_CODE, BrdType ) ;
       if Err = 0 then begin
          DeviceList.Add(format('Device %d',[iDev])) ;
          end ;
       end ;
    end ;


function  NI_GetLabInterfaceInfo(
          var DeviceList : TStringList ;
          var DeviceNumber : Integer ;  // Device #
          var ADCInputMode : Integer ;  // Analog input mode
          var Model : string ; { Laboratory interface model name/number }
          var ADCMaxChannels : Integer ; // No. of A/D channels
          var ADCMinSamplingInterval : Double ; { Smallest sampling interval }
          var ADCMaxSamplingInterval : Double ; { Largest sampling interval }
          var ADCMinValue : Integer ; { Negative limit of binary ADC values }
          var ADCMaxValue : Integer ; { Positive limit of binary ADC values }
          var DACMaxChannels : Integer ; // No. of D/A channels
          var DACMinValue : Integer ; { Negative limit of binary DAC values }
          var DACMaxValue : Integer ; { Positive limit of binary DAC values }
          var ADCVoltageRanges : Array of single ; { A/D voltage range option list }
          var NumADCVoltageRanges : Integer ; { No. of options in above list }
          var DACMaxVolts : Single ;{ Positive limit of bipolar D/A voltage range }
          var DACMinUpdateInterval : Double ; {Min. D/A update interval }
          var DigMinUpdateInterval : Double ; {Min. digital update interval }
          var DigMaxUpdateInterval : Double ; {Min. digital update interval }
          var DigUpdateStep : Integer ; // Digital output step interval
          var ADCBufferLimit : Integer  // Max. no. of A/D samples/buffer
          ) : Boolean ;
var
   BoardName : array[0..400] of String[16] ;
   MinInterval : array[0..400] of single ;
   MinDACInterval : array[0..400] of single ;
   iValue16 : SmallInt ;
   Voltage : Double ;
   i : Integer ;
   Err : SmallInt ;
   ADCResolution,DACResolution : Integer ;
   ADCInputModes : Array[0..2] of Integer ;
   ADCModeCode : SmallInt ;
   iDev : Integer ;
   NoDevicesAvailable : Boolean ;
begin

    // Find an available device

     Result := False ;

    // Find list of an available devices
    NI_GetDeviceList( DeviceList ) ;
    if DeviceList.Count < 1 then begin
       ShowMessage('No National Instruments interface cards detected!') ;
       exit ;
       end ;

    // Check selected device
    DeviceNumber := Min(Max(1,DeviceNumber),DeviceList.Count) ;
    Device := StrToInt( RightStr(DeviceList.Strings[DeviceNumber-1],1)) ;
    if not NI_DeviceExists(Device) then begin
       ShowMessage(format('Unable to detect Device %d',[Device])) ;
       exit ;
       end ;

     for i := 0 to High(MinInterval) do begin
         MinInterval[i] := 1E-5 ;
         MinDACInterval[i] := 1E-4 ;
         end ;

     // Initialise board name array
     for i := 0 to High(BoardName) do
         BoardName[i] := format('Unknown (%d)',[i]) ;

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     // Get a usable A/D input mode

     ADCModeCode := NI_GetADCInputModeCode( ADCInputMode ) ;
     Err := AI_Configure( Device,-1,ADCModeCode,0,0,0) ;
     if Err <> 0 then begin
        ADCInputModes[0] := imDifferential ;
        ADCInputModes[1] := imSingleEnded ;
        ADCInputModes[2] := imSingleEndedRSE ;
        i := 0 ;
        while (Err <> 0) and (i <= High(ADCInputModes)) do begin
           ADCInputMode := ADCInputModes[i] ;
           ADCModeCode := NI_GetADCInputModeCode( ADCInputMode ) ;
           Err := AI_Configure( Device,-1,ADCModeCode,0,0,0) ;
           Inc(i) ;
           end ;
        ShowMessage('WARNING! This A/D input mode not supported by this device.') ;
        end ;

     // Set max. no. of input channels
     if ADCInputMode = imDifferential then ADCMaxChannels := 8
                                      else ADCMaxChannels := 16 ;

        BoardName[0] :=  'AT-MIO-16L-9' ;
        MinInterval[0] := 1E-5 ;
        BoardName[1] :=  'AT-MIO-16L-15' ;
        MinInterval[1] := 1E-5 ;
        BoardName[2] :=  'AT-MIO-16L-25' ;
        MinInterval[2] := 1E-5 ;
        BoardName[3] := '?' ;
        MinInterval[3] := 1E-5 ;
        BoardName[4] :=  'AT-MIO-16H-9' ;
        MinInterval[4] := 1E-5 ;
        BoardName[5] :=  'AT-MIO-16H-15' ;
        MinInterval[5] := 1E-5 ;
        BoardName[6] :=  'AT-MIO-16H-25' ;
        MinInterval[6] := 1E-5 ;
        BoardName[7] :=  'PC-DIO-24' ;
        MinInterval[7] := 1E-5 ;
        BoardName[8] :=  'AT-DIO-32F' ;
        MinInterval[8] := 1E-5 ;
        BoardName[9] := '?' ;
        MinInterval[9] := 1E-5 ;
        BoardName[10] :=  'EISA-A2000' ;
        MinInterval[10] := 1E-6 ;
        BoardName[11] :=  'AT-MIO-16F-5' ;
        MinInterval[11] := 1E-5 ;
        BoardName[12] :=  'PC-DIO-96/PnP' ;
        MinInterval[12] := 1E-5 ;
        BoardName[13] :=  'PC-LPM-16' ;
        MinInterval[13] := 2E-5 ;
        BoardName[14] :=  'PC-TIO-10' ;
        MinInterval[14] := 1E-5 ;
        BoardName[15] :=  'AT-AO-6' ;
        MinInterval[15] := 1E-5 ;
        BoardName[16] :=  'AT-A2150S' ;
        MinInterval[16] := 1E-5 ;
        BoardName[17] :=  'AT-DSP2200 ' ;
        MinInterval[17] := 1E-5 ;
        BoardName[18] :=  'AT-DSP2200 ' ;
        MinInterval[18] := 1E-5 ;
        BoardName[19] :=  'AT-MIO-16X' ;
        MinInterval[19] := 1E-5 ;
        BoardName[20] :=  'AT-MIO-64F-5' ;
        MinInterval[20] := 1E-5 ;
        BoardName[21] :=  'AT-MIO-16DL-9' ;
        MinInterval[21] := 1E-5 ;
        BoardName[22] :=  'AT-MIO-16DL-25' ;
        MinInterval[22] := 1E-5 ;
        BoardName[23] :=  'AT-MIO-16DH-9' ;
        MinInterval[23] := 1E-5 ;
        BoardName[24] :=  'AT-MIO-16DH-25' ;
        MinInterval[24] := 1E-5 ;
        BoardName[25] :=  'AT-MIO-16E-2' ;
        MinInterval[25] := 1E-5 ;
        BoardName[26] :=  'AT-AO-10' ;
        MinInterval[26] := 1E-5 ;
        BoardName[27] :=  'AT-A2150C' ;
        MinInterval[27] := 1E-5 ;

        BoardName[28] :=  'Lab-PC+' ;
        MinInterval[28] := 1./82500. ;
        MinDACInterval[28] := 1E-4 ;

        BoardName[29] := '?' ;
        MinInterval[29] := 1./82500. ;
        BoardName[30] :=  'SCXI-1200' ;
        MinInterval[30] := 1E-5 ;
        BoardName[31] :=  'DAQCard-700' ;
        MinInterval[31] := 1E-5 ;
        BoardName[32] :=  'NEC-MIO-16E-4' ;
        MinInterval[32] := 1E-5 ;

        BoardName[33] :=  'DAQPad-1200' ;
        MinInterval[33] := 1E-5 ;
        MinDACInterval[33] := 1E-3 ;

        BoardName[34] :=  'DAQCard-DIO-24' ;
        MinInterval[34] := 1E-5 ;

        BoardName[36] :=  'AT-MIO-16E-10' ;
        MinInterval[36] := 1E-5 ;

        BoardName[37] :=  'AT-MIO-16DE-10' ;
        MinInterval[37] := 1E-5 ;

        BoardName[38] :=  'AT-MIO-64E-3' ;
        MinInterval[38] := 1E-5 ;

        BoardName[39] :=  'AT-MIO-16XE-50' ;
        MinInterval[39] := 1E-5 ;
        BoardName[40] :=  'NEC-AI-16E-4' ;
        MinInterval[40] := 1E-5 ;
        BoardName[41] :=  'NEC-MIO-16XE-50' ;
        MinInterval[41] := 1E-5 ;
        BoardName[42] :=  'NEC-AI-16XE-50' ;
        MinInterval[42] := 1E-5 ;
        BoardName[43] :=  'DAQPad-MIO-16XE-50' ;
        MinInterval[43] := 1E-5 ;
        BoardName[44] :=  'AT-MIO-16E-1' ;
        MinInterval[44] := 1E-5 ;
        BoardName[45] :=  'PC-OPDIO-16' ;
        MinInterval[45] := 1E-5 ;
        BoardName[46] :=  'PC-AO-2DC' ;
        MinInterval[46] := 1E-5 ;
        BoardName[47] :=  'DAQCard-AO-2DC' ;
        MinInterval[47] := 1E-5 ;
        BoardName[48] :=  'DAQCard-1200' ;
        MinInterval[48] := 1E-5 ;
        MinDACInterval[48] := 1E-3 ;
        BoardName[49] :=  'DAQCard-500' ;
        MinInterval[49] := 1E-5 ;
        BoardName[50] :=  'AT-MIO-16XE-10' ;
        MinInterval[50] := 1E-5 ;
        BoardName[51] :=  'AT-AI-16XE-10' ;
        MinInterval[51] := 1E-5 ;
        BoardName[52] :=  'DAQCard-AI-16XE-50' ;
        MinInterval[52] := 1E-5 ;
        BoardName[53] :=  'DAQCard-AI-16E-4' ;
        MinInterval[53] := 1E-5 ;
        BoardName[54] :=  'DAQCard-516' ;
        MinInterval[54] := 1E-5 ;
        BoardName[55] :=  'PC-516' ;
        MinInterval[55] := 1E-5 ;
        BoardName[56] :=  'PC-LPM-16PnP' ;
        MinInterval[56] := 1E-5 ;

        BoardName[57] :=  'Lab-PC-1200' ;
        MinInterval[57] := 1E-5 ;
        MinDACInterval[57] := 1E-4 ;

        BoardName[58] :=  'Lab-PC-1200/AI' ;
        MinInterval[58] := 1E-5 ;

        BoardName[59] :=  'Unknown' ;
        MinInterval[59] := 1E-5 ;
        BoardName[60] :=  'Unknown' ;
        MinInterval[60] := 1E-5 ;
        BoardName[61] :=  'VXI-AO-48XDC' ;
        MinInterval[61] := 1E-5 ;
        BoardName[62] :=  'VXI-DIO-128' ;
        MinInterval[62] := 1E-5 ;
        BoardName[65] :=  'PC-DIO-24/PnP' ;
        MinInterval[65] := 1E-5 ;
        BoardName[66] :=  'PC-DIO-96/PnP' ;
        MinInterval[66] := 1E-5 ;
        BoardName[67] :=  'AT-DIO-32HS' ;
        MinInterval[67] := 1E-5 ;
        BoardName[69] :=  'DAQArb AT-5411' ;
        MinInterval[69] := 1E-5 ;

        BoardName[75] :=  'DAQPad-6507/8.' ;
        MinInterval[75] := 1E-5 ;
        BoardName[76] :=  'DAQPad-6020E for USB' ;
        MinInterval[76] := 1E-5 ;
        BoardName[88] :=  'DAQCard-6062E' ;
        MinInterval[88] := 1E-5 ;
        BoardName[89] :=  'DAQCard-6715' ;
        MinInterval[89] := 1E-5 ;

        BoardName[90] :=  'DAQCard-6023E' ;
        MinInterval[90] := 5E-6 ;
        MinDACInterval[90] := 1E-3 ;

        BoardName[91] :=  'DAQCard-6024E' ;
        MinInterval[91] := 5E-6 ;
        MinDACInterval[91] := 1E-3 ;

        BoardName[200] :=  'PCI-DIO-96' ;
        MinInterval[200] := 1E-5 ;

        BoardName[201] :=  'PCI-1200' ;
        MinInterval[201] := 1E-5 ;
        MinDACInterval[201] := 1E-4 ;

        BoardName[202] :=  'PCI-MIO-16XE-50' ;
        MinInterval[202] := 1E-5 ;
        MinDACInterval[202] := 1E-5 ;

        BoardName[203] :=  'PCI-5102' ;
        MinInterval[203] := 1E-5 ;
        MinDACInterval[203] := 1E-5 ;

        BoardName[204] :=  'PCI-MIO-16E-1' ;
        MinInterval[204] := 1E-5 ;
        MinDACInterval[204] := 1E-5 ;

        BoardName[205] :=  'PCI-MIO-16E-1' ;
        MinInterval[205] := 1E-5 ;
        MinDACInterval[205] := 1E-5 ;

        BoardName[206] :=  'PCI-MIO-16E-4' ;
        MinInterval[206] := 1E-5 ;
        MinDACInterval[206] := 1E-5 ;

        BoardName[207] :=  'PXI-6070E' ;
        MinInterval[207] := 1E-5 ;
        MinDACInterval[207] := 1E-5 ;

        BoardName[208] :=  'PXI-6040E' ;
        MinInterval[208] := 1E-5 ;
        MinDACInterval[208] := 1E-5 ;

        BoardName[211] :=  'PCI-DIO-32HS' ;
        MinInterval[211] := 1E-5 ;

        BoardName[212] :=  'DAQArb PCI-5411' ;
        MinInterval[212] := 1E-5 ;

        BoardName[220] :=  'PCI-6031E (MIO-64XE-10)' ;
        MinInterval[220] := 1E-5 ;

        BoardName[221] :=  'PCI-6032E (AI-16XE-10)' ;
        MinInterval[221] := 1E-5 ;

        BoardName[222] :=  'PCI-6033E (AI-64XE-10)' ;
        MinInterval[222] := 1E-5 ;
        BoardName[223] :=  'PCI-6071E (MIO-64E-1)' ;
        MinInterval[223] := 1E-5 ;

        BoardName[233] :=  'PCI-4451' ;
        MinInterval[233] := 1E-5 ;
        BoardName[234] :=  'PCI-4452' ;
        MinInterval[234] := 1E-5 ;
        BoardName[235] :=  'PCI-4551' ;
        MinInterval[235] := 1E-5 ;
        BoardName[236] :=  'PPCI-4552' ;
        MinInterval[236] := 1E-5 ;

        BoardName[240] :=  'PXI-6508' ;
        MinInterval[240] := 1E-5 ;

        BoardName[241] :=  'PCI-6110E' ;
        MinInterval[241] := 2E-7 ;
        MinDACInterval[241] := 1E-6 ;

        BoardName[244] :=  'PCI-6110E' ;
        MinInterval[244] := 2E-7 ;

        BoardName[256] :=  'PCI-650' ;
        MinInterval[256] := 1E-5 ;
        BoardName[257] :=  'PXI-6503' ;
        MinInterval[257] := 1E-5 ;
        BoardName[258] :=  'PXI-6071E' ;
        MinInterval[258] := 1E-5 ;
        BoardName[259] :=  'PXI-6031E' ;
        MinInterval[259] := 1E-5 ;
        BoardName[261] :=  'PCI-6711' ;
        MinInterval[261] := 1E-5 ;
        BoardName[262] :=  'PCI-6711' ;
        MinInterval[262] := 1E-5 ;
        BoardName[263] :=  'PCI-6713' ;
        MinInterval[263] := 1E-5 ;
        BoardName[264] :=  'PXI-6713' ;
        MinInterval[264] := 1E-5 ;
        BoardName[265] :=  'PCI-6704' ;
        MinInterval[265] := 1E-5 ;
        BoardName[266] :=  'PXI-6704' ;
        MinInterval[266] := 1E-5 ;
        BoardName[267] :=  'PCI-6023E' ;
        MinInterval[267] := 1E-5 ;
        BoardName[268] :=  'PXI-6023E' ;
        MinInterval[268] := 1E-5 ;

        BoardName[269] :=  'PCI-6024E' ;
        MinInterval[269] := 1E-5 ;
        MinDACInterval[269] := 1E-3 ;

        BoardName[270] :=  'PXI-6024E' ;
        MinInterval[270] := 1E-5 ;
        MinDACInterval[270] := 1E-3 ;

        BoardName[271] :=  'PCI-6025E' ;
        MinInterval[271] := 1E-5 ;
        BoardName[272] :=  'PXI-6025E' ;
        MinInterval[272] := 1E-5 ;
        BoardName[273] :=  'PCI-6052E' ;
        MinInterval[273] := 1E-5 ;
        BoardName[274] :=  'PXI-6052E' ;
        MinInterval[274] := 1E-5 ;
        BoardName[275] :=  'DAQPad-6070E' ;
        MinInterval[275] := 1E-5 ;
        BoardName[276] :=  'DAQPad-6052E' ;
        MinInterval[276] := 1E-5 ;
        BoardName[285] :=  'PCI-6527' ;
        MinInterval[285] := 1E-5 ;
        BoardName[286] :=  'PXI-6527' ;
        MinInterval[286] := 1E-5 ;
        BoardName[308] :=  'PCI-6601' ;
        MinInterval[308] := 1E-5 ;
        BoardName[311] :=  'PCI-6703' ;
        MinInterval[311] := 1E-5 ;
        BoardName[314] :=  'PCI-6034E' ;
        MinInterval[314] := 1E-5 ;
        BoardName[315] :=  'PXI-6034E' ;
        MinInterval[315] := 1E-3 ;
        BoardName[316] :=  'PCI-6035E' ;
        MinInterval[316] := 5E-6 ;
        MinDACInterval[316] := 1E-3 ;
        BoardName[317] :=  'PXI-6035E' ;
        MinInterval[317] := 1E-3 ;
        MinDACInterval[317] := 1E-3 ;
        BoardName[318] :=  'PXI-6703' ;
        MinInterval[318] := 1E-5 ;
        BoardName[319] :=  'PXI-6608' ;
        MinInterval[319] := 1E-5 ;
        BoardName[320] :=  'PCI-4453' ;
        MinInterval[320] := 1E-5 ;
        BoardName[321] :=  'PCI-4454' ;
        MinInterval[321] := 1E-5 ;
        BoardName[327] :=  'PCI-6608' ;
        MinInterval[327] := 1E-5 ;
        // Added 16.12.02 for NIDAQ 6.9.3
        BoardName[329] :=  'NI 6222(PCI)' ;
        MinInterval[329] := 1E-5 ;
        BoardName[330] :=  'NI 6222(PXI)' ;
        MinInterval[330] := 1E-5 ;
        BoardName[331] :=  'NI 6224 (Ethernet)' ;
        MinInterval[331] := 1E-5 ;
        BoardName[332] :=  'DAQPad-6052E (USB)' ;
        MinInterval[332] := 1E-5 ;
        BoardName[335] :=  'NI 4472 (PXI/CompactPCI)' ;
        MinInterval[335] := 1E-5 ;

        BoardName[338] :=  'PCI-6115' ;
        MinInterval[338] := 2E-7 ;
        MinDACInterval[338] := 2E-7 ;

        BoardName[339] :=  'PXI-6115' ;
        MinInterval[339] := 2E-7 ;
        MinDACInterval[339] := 2E-7 ;

        BoardName[340] :=  'PCI-6120' ;
        MinInterval[340] := 2E-7 ;
        MinDACInterval[340] := 2E-7 ;

        BoardName[341] :=  'PXI-6120' ;
        MinInterval[341] := 2E-7 ;
        MinDACInterval[341] := 2E-7 ;

        BoardName[342] :=  'NI 4472 (PCI)' ;
        MinInterval[342] := 1E-5 ;
        BoardName[347] :=  'NI 4472 (IEEE-1394)' ;
        MinInterval[347] := 1E-5 ;

        BoardName[348] :=  'DAQCard 6036E ' ;
        MinInterval[348] := 1E-5 ;
        MinDACInterval[348] := 1E-3 ;

        BoardName[367] :=  'PCI 6014E' ;
        MinInterval[367] := 5E-6 ;

        { Determine available of A/D voltage range options }
        LabPCTypeBoard := False ;
        SSeriesBoard := False ;
        case BoardTypeNumber of
          0..2,21..22 : begin
              { ATMIO-16L boards }
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 1.0 ;
              ADCVoltageRanges[2] := 0.1 ;
              ADCVoltageRanges[3] := 0.02 ;
              FADCVoltageRangeMax := ADCVoltageRanges[0] ;
              NumADCVoltageRanges := 4 ;
              end ;
          4..6,23..24 : begin
              { ATMIO-16H boards }
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 5.0 ;
              ADCVoltageRanges[2] := 2.5 ;
              ADCVoltageRanges[3] := 1.25 ;
              NumADCVoltageRanges := 4 ;
              FADCVoltageRangeMax := ADCVoltageRanges[0] ;
              end ;
          19,39,41..43,204 : begin
              { ATMIO-16X,PCI-MIO-16XE-10 boards (16 bit)}
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 5.0 ;
              ADCVoltageRanges[2] := 2.0 ;
              ADCVoltageRanges[3] := 1.0 ;
              ADCVoltageRanges[4] := 0.5 ;
              ADCVoltageRanges[5] := 0.1 ;
              FADCVoltageRangeMax := ADCVoltageRanges[0] ;
              NumADCVoltageRanges := 6 ;
              end ;
          202 : begin
              { PCI-MIO-16XE-50 boards (16 bit)}
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 5.0 ;
              ADCVoltageRanges[2] := 1.0 ;
              ADCVoltageRanges[3] := 0.1 ;
              FADCVoltageRangeMax := ADCVoltageRanges[0] ;
              NumADCVoltageRanges := 4 ;
              end ;
          13,56 : begin
              { PC-LPM-16 boards }
              ADCVoltageRanges[0] := 5.0 ;
              NumADCVoltageRanges := 1 ;
              end ;
          267..272,314..317,348,367, 91 : begin
              { DAQCard, 6014E 6023E, 6024E, 6025E, 6034E, 6035E, 6036E boards }
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 5.0 ;
              ADCVoltageRanges[2] := 0.5 ;
              ADCVoltageRanges[3] := 0.05 ;
              FADCVoltageRangeMax := ADCVoltageRanges[1] ;
              NumADCVoltageRanges := 4 ;
              end ;
          9,28,31,33,48,49,57,58,201 : Begin
              // Lab-PC type boards
              ADCVoltageRanges[0] := 5.0 ;
              ADCVoltageRanges[1] := 2.5 ;
              ADCVoltageRanges[2] := 1.0 ;
              ADCVoltageRanges[3] := 0.5 ;
              ADCVoltageRanges[4] := 0.25 ;
              ADCVoltageRanges[5] := 0.1 ;
              ADCVoltageRanges[6] := 0.05 ;
              FADCVoltageRangeMax := ADCVoltageRanges[0] ;
              NumADCVoltageRanges := 7 ;
              LabPCTypeBoard := True ;
              end ;
          241,244,338-341 : begin
              { PCI-61XX series }
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 5.0 ;
              ADCVoltageRanges[2] := 2 ;
              ADCVoltageRanges[3] := 1.0 ;
              ADCVoltageRanges[4] := 0.5 ;
              ADCVoltageRanges[5] := 0.2 ;
              FADCVoltageRangeMax := ADCVoltageRanges[0] ;
              NumADCVoltageRanges := 6 ;
              ADCMaxChannels := 4 ;
              SSeriesBoard := True ;
              end ;
          else begin
              { All other boards }
              ADCVoltageRanges[0] := 10.0 ;
              ADCVoltageRanges[1] := 5.0 ;
              ADCVoltageRanges[2] := 2.5 ;
              ADCVoltageRanges[3] := 1.0 ;
              ADCVoltageRanges[4] := 0.5 ;
              ADCVoltageRanges[5] := 0.25 ;
              ADCVoltageRanges[6] := 0.1 ;
              ADCVoltageRanges[7] := 0.05 ;
              FADCVoltageRangeMax := ADCVoltageRanges[1] ;
              NumADCVoltageRanges := 8 ;
              end ;
          end ;

        { Determine limits of ADC binary integer values (12/16 bit) }
        AI_VScale ( Device, 0, 1, 1.0, 0.0, 2047, Voltage) ;
        if (Voltage < (0.5*FADCVoltageRangeMax)) then ADCMaxValue := 32767
                                                  else ADCMaxValue := 2047 ;
        ADCMinValue := -ADCMaxValue -1 ;
        FADCMinValue := ADCMinValue ;
        FADCMaxValue := ADCMaxValue ;

        { Determine limits of DAC binary integer values (12/16 bit) }
        Err := AO_VScale ( Device, 0, 4.9, iValue16 ) ;
        if Err = -10403 then DACHardwareAvailable := False
                        else DACHardwareAvailable := True ;
        DACWarningDelivered := DACHardwareAvailable ;
        if iValue16 > 2047 then DACMaxValue := 32767
                           else DACMaxValue := 2047 ;
        DACMinValue := -DACMaxValue - 1 ;
        FDACMinValue := DACMinValue ;
        FDACMaxValue := DACMaxValue ;
        if DACHardwareAvailable then DACMaxChannels := 2
                                else  DACMaxChannels := 0 ;

        { Determine upper limit of bipolar D/A voltage range }
        AO_VScale( device, 0, 4.9, iValue16 ) ;
        if iValue16 > (FDACMaxValue div 2) then DACMaxVolts := 5.0
                                           else DACMaxVolts := 10.0 ;
        FDACMaxVolts := DACMaxVolts ;

        DACMinUpdateInterval := MinDACInterval[BoardTypeNumber] ;
        FDACMinUpdateInterval := DACMinUpdateInterval ;

        // Interface cards which support digital I/O handshaking
        case BoardTypeNumber of
             9,13,28,31,33,49,57,58,201 : DigIOHandshakingSupported := True ;
             else DigIOHandshakingSupported := False ;
             end ;

        // Set minimum digital output update interval
        if DigIOHandshakingSupported then begin
           DigMinUpdateInterval := FDACMinUpdateInterval ;
           DigMaxUpdateInterval := 1000. ;
           DigUpdateStep := 2 ;
           end
        else begin
           // NOTE update interval fixed at 10 ms
           DigMinUpdateInterval := 1E-2 ;
           DigMaxUpdateInterval := DigMinUpdateInterval ;
           DigUpdateStep := 100000 ;
           end ;

        if BoardTypeNumber >= 0 then begin
           if FADCMaxValue = 32767 then ADCResolution := 16
                                   else ADCResolution := 12 ;
           if FDACMaxValue = 32767 then DACResolution := 16
                                   else DACResolution := 12 ;

           Model := format('Model: %s (%d) A/D=%dbit %.3gV D/A=%dbit %.3gV',
                    [BoardName[BoardTypeNumber],
                    BoardTypeNumber,
                    ADCResolution,
                    FADCVoltageRangeMax,
                    DACResolution,
                    FDACMaxVolts
                    ]) ;

           ADCMinSamplingInterval := MinInterval[BoardTypeNumber] ;
           ADCMaxSamplingInterval := 1000. ;
           FADCMinSamplingInterval := ADCMinSamplingInterval ;
           FADCMaxSamplingInterval := ADCMaxSamplingInterval ;
          end
        else Model := format('Not an N.I. card (%d)',[BoardTypeNumber]) ;

        // If LabPC/1200 board limit size of buffer
        if LabPCTypeBoard then ADCBufferLimit := 64512
                          else ADCBufferLimit := MaxADCSamples ;

        FADCBufferLimit := ADCBufferLimit ;

     Result := NIBoardInitialised ;
     end ;


function NI_GetADCInputModeCode( ADCInputMode : Integer ) : SmallInt ;
// --------------------------
// Return A/D input mode code
// --------------------------
begin
     // Set A/D input mode
     if (ADCInputMode = imDifferential) or
        (ADCInputMode = imBNC2110) then Result := 0     // Differential
     else if ADCInputMode = imSingleEndedRSE then Result := 1
     else Result := 2 ; // NRSE
     end ;


function NI_InitialiseBoard : Boolean ;
{ --------------------------------------
  Initialise hardware and NI-DAQ library
  -------------------------------------- }
var
    Err : SmallInt ;
begin

   { Clear A/D and D/A in progress flags }
   ADCActive := False ;
   DACActive := False ;
   DigActive := False ;
   DACDigActive := False ;
   Result := False ;

   if not NIDAQLoaded then NI_LoadNIDAQLibrary ;
   if not NIDAQLoaded then Exit ;

   { If the board type is not known ... get it now, and reset card }
   Err := -1 ;
   if BoardTypeNumber < 0 then Err := Init_DA_Brds( Device, BoardTypeNumber ) ;
   if Err <> 0 then begin
      BoardTypeNumber := -1 ;
      Exit ;
      end ;

   { Set port 0 to output, mode 0 }
   NI_CheckError( DIG_Prt_Config( Device, 0, 0, AsDigOutputPort )) ;

   Result := True ;

   end ;


{ --------------------------------------------------------
  Load NIDAQ.DLL library into memory
  --------------------------------------------------------}
procedure NI_LoadNIDAQLibrary  ;
var
   Hnd : THandle ;
begin
     { Load library }
     Hnd := LoadLibrary( PCHar('NIDAQ32.DLL') ) ;
     if Hnd <> 0 then begin
       { Get addresses of procedure NI_s used }
        @Init_DA_Brds := NI_LoadProcedure( Hnd, 'Init_DA_Brds' ) ;
       { @Init_DA_Brds := GetProcAddress(Hnd,PChar('Init_DA_Brds')) ;}
        @DAQ_Clear := NI_LoadProcedure( Hnd,'DAQ_Clear') ;
        @DAQ_Config := NI_LoadProcedure( Hnd,'DAQ_Config') ;
        @DAQ_DB_Config := NI_LoadProcedure( Hnd,'DAQ_DB_Config') ;
        @DAQ_Start := NI_LoadProcedure( Hnd,'DAQ_Start') ;
        @DAQ_Rate := NI_LoadProcedure( Hnd,'DAQ_Rate') ;
        @Lab_ISCAN_Start := NI_LoadProcedure( Hnd,'Lab_ISCAN_Start') ;
        @SCAN_Setup := NI_LoadProcedure( Hnd,'SCAN_Setup') ;
        @SCAN_Start := NI_LoadProcedure( Hnd,'SCAN_Start') ;
        @WFM_Rate := NI_LoadProcedure( Hnd,'WFM_Rate') ;
        @WFM_ClockRate := NI_LoadProcedure( Hnd,'WFM_ClockRate') ;
        @WFM_Load := NI_LoadProcedure( Hnd,'WFM_Load') ;
        @WFM_Group_Control := NI_LoadProcedure( Hnd,'WFM_Group_Control') ;
        @WFM_Check := NI_LoadProcedure( Hnd,'WFM_Check') ;
        @AI_VScale := NI_LoadProcedure( Hnd,'AI_VScale') ;
        @AO_Configure := NI_LoadProcedure( Hnd,'AO_Configure') ;
        @AO_Write := NI_LoadProcedure( Hnd,'AO_Write') ;
        @AI_Configure := NI_LoadProcedure( Hnd,'AI_Configure') ;
        @AO_Update := NI_LoadProcedure( Hnd,'AO_Update') ;
        @AO_VScale := NI_LoadProcedure( Hnd,'AO_VScale') ;
        @AO_VWrite := NI_LoadProcedure( Hnd,'AO_VWrite') ;
        @DIG_Block_Clear := NI_LoadProcedure( Hnd,'DIG_Block_Clear') ;
        @DIG_Block_Check := NI_LoadProcedure( Hnd,'DIG_Block_Check') ;
        @DIG_Block_Out := NI_LoadProcedure( Hnd,'DIG_Block_Out') ;
        @DIG_SCAN_Setup := NI_LoadProcedure( Hnd,'DIG_SCAN_Setup') ;
        @DIG_Prt_Config := NI_LoadProcedure( Hnd,'DIG_Prt_Config') ;
        @DIG_Out_Port := NI_LoadProcedure( Hnd,'DIG_Out_Port') ;
        @DIG_In_Port := NI_LoadProcedure( Hnd,'DIG_In_Port') ;
        @AI_Read := NI_LoadProcedure( Hnd,'AI_Read') ;
        @Set_DAQ_Device_Info := NI_LoadProcedure( Hnd,'Set_DAQ_Device_Info') ;
        @Select_Signal := NI_LoadProcedure( Hnd,'Select_Signal') ;
        @GPCTR_Change_Parameter := NI_LoadProcedure( Hnd,'GPCTR_Change_Parameter') ;
        @GPCTR_Control := NI_LoadProcedure( Hnd,'GPCTR_Control') ;
        @GPCTR_Set_Application := NI_LoadProcedure( Hnd,'GPCTR_Set_Application') ;
        @GPCTR_Watch := NI_LoadProcedure( Hnd,'GPCTR_Watch') ;
        @ICTR_Read := NI_LoadProcedure( Hnd,'ICTR_Read') ;
        @ICTR_Reset := NI_LoadProcedure( Hnd,'ICTR_Reset') ;
        @ICTR_Setup := NI_LoadProcedure( Hnd,'ICTR_Setup') ;
        @Get_DAQ_Device_Info := NI_LoadProcedure( Hnd,'Get_DAQ_Device_Info') ;
        NIDAQLoaded := True ;
        end
     else begin
          //MessageDlg( 'NIDAQ32.DLL library not found', mtWarning, [mbOK], 0 ) ;
          NIDAQLoaded := False ;
          end ;

     end ;


{ ----------------------------
  Get address of DLL procedure
  ----------------------------}
function NI_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }
var
   P : Pointer ;

begin
     P := GetProcAddress(Hnd,PChar(Name)) ;
     if {Integer(P) = Null} P = Nil then begin
        MessageDlg(format('NIDAQ32.DLL- %s not found',[Name]),mtWarning,[mbOK],0) ;
        end ;
     Result := P ;
     end ;


procedure NI_ReportFailure(
          const ProcName : string
          ) ;
begin
     MessageDlg('NIDAQ.DLL- ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
     end ;


function NI_IsLabInterfaceAvailable : boolean ;
{ ------------------------------------------------------------
  Check to see if a lab. interface library is available
  ------------------------------------------------------------}
begin
     NI_IsLabInterfaceAvailable := NI_InitialiseBoard ;
     end ;


{ -----------------------------
  Start A/D converter sampling
  -----------------------------}
function NI_ADCToMemory(
          var ADCBuf : Array of SmallInt  ;  { A/D sample buffer (OUT) }
          nChannels : Integer ;              { Number of A/D channels (IN) }
          nSamples : Integer ;               { Number of A/D samples ( per channel) (IN) }
          var SamplingInterval : Double ;    { Sampling interval (s) (IN) }
          ADCVoltageRanges : Array of Single ;{ A/D input voltage range for each channel (V) (IN) }
          TriggerMode : Integer ;             // Sweep trigger mode
          ADCExternalTriggerActiveHigh : Boolean ;
          CircularBuffer : Boolean ;          { Repeated sampling into buffer (IN) }
          ADCInputMode : Integer ;            // A/D input mode
          ADCChannelInputNumber : Array of Integer  // A/D input channel map
          ) : Boolean ;                      { Returns TRUE indicating A/D started }

var
   ch : Integer ;                           // Selected channel
   Gain : array[0..15] of SmallInt ;        // Channel gain selection array
   GainVector : array[0..15] of SmallInt ;  // Channel Gain selection array (in NI order)
   ChanVector : array[0..15] of SmallInt ;  // Channel number selection array
   TimeBase : SmallInt ;                    // A/D Clock time base
   ClockTicks : Word ;                      // No. clock ticks
   ADCModeCode : SmallInt ;
begin

     Result := False ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     DAQ_Clear(Device) ; { Reset Data acquisition sub-system }

     // Disable DMA update with Lab-PC type devices.
     // (to avoid problems with byte DMA updating of word data)
     if LabPCTypeBoard then NI_DisableDMA_LabPC ;

     { Determine sampling clock time-base and number of ticks }
     NI_CheckSamplingInterval( SamplingInterval,nChannels,Timebase,ClockTicks) ;
     ADCTimeBase := Timebase ;

     { Set recording trigger mode }
     case TriggerMode of
        // External trigger mode
        tmExtTrigger : Begin
            NI_CheckError(DAQ_Config( Device,1,0)) ;
            if not LabPCTypeBoard then begin
               if ADCExternalTriggerActiveHigh then begin
                  NI_CheckError( Select_Signal ( Device,
                                                 ND_IN_START_TRIGGER,
                                                 ND_PFI_0,
                                                 ND_LOW_TO_HIGH)) ;
                  end
               else begin
                  NI_CheckError( Select_Signal( Device,
                                                ND_IN_START_TRIGGER,
                                                ND_PFI_0,
                                                ND_HIGH_TO_LOW)) ;
                  end ;
               end ;
            end ;

        // Stimulus-locked trigger mode
        tmWaveGen : Begin
            NI_CheckError(DAQ_Config( Device,1,0)) ;
            // Trigger A/D sweep from WFTRIG (D/A sweep start) output via RTSI bus
            if not LabPCTypeBoard then begin
               NI_CheckError(Select_Signal( Device,
                                            ND_RTSI_0,
                                            ND_OUT_START_TRIGGER,
                                            ND_LOW_TO_HIGH)) ;
               NI_CheckError(Select_Signal( Device,
                                            ND_IN_START_TRIGGER,
                                            ND_RTSI_0,
                                            ND_LOW_TO_HIGH)) ;
               end ;
            end ;

        // Free run trigger mode
        else begin
             NI_CheckError(DAQ_Config( Device,0,0)) ;
             end ;
        end ;

     {If in 'CircularBuffer' mode set A/D converter to continue
      indefinitely filling ADC buffer }
     if CircularBuffer then NI_CheckError(DAQ_DB_Config(Device, 1))
                       else NI_CheckError(DAQ_DB_Config(Device, 0)) ;

     // Set A/D input mode
     ADCModeCode := NI_GetADCInputModeCode( ADCInputMode ) ;
     NI_CheckError(AI_Configure( Device,
                                 -1,
                                 ADCModeCode,
                                 0,
                                 0,
                                 0)) ;

     { Set internal gain for A/D converter's programmable amplifier }
     for ch := 0 to nChannels-1 do begin
         Gain[ch] := Trunc( (FADCVoltageRangeMax+0.001) / ADCVoltageRanges[ch] ) ;
         if Gain[ch] < 1 then Gain[ch] := -1 ;  // Adjust Gain=0.5 to Gain=-1
         end ;

     if nChannels < 2 then begin
        { Single A/D channel sampling }
        Ch := 0 ;
        NI_CheckError(DAQ_Start(Device,Ch,Gain[0],
                             @ADCBuf,nSamples,Timebase,ClockTicks )) ;
        end
     else begin
        { Multiple A/D channel sampling }
        if LabPCTypeBoard then begin
           { Multi-channel A/D conversion for LAB-PC-like cards }
           NI_CheckError(LAB_ISCAN_Start( Device, nChannels, Gain[0], @ADCBuf,
                           nSamples*nChannels,TimeBase,ClockTicks,0));
           end
        else begin
           { Multi-channel A/D conversion for cards with Channel/Gain lists }
           { Note ... channels are acquired in descending order }
           // Mapping between logical channel number and actual A/D input
           // obtained from ADCChannelInputNumber array (22/8/11)
           for ch := 0 to nChannels-1 do begin
               ChanVector[ch] := ADCChannelInputNumber[nChannels-ch-1] ;
               GainVector[ch] := Gain[ch] ;
               end ;
           NI_CheckError(SCAN_Setup( Device, nChannels,@ChanVector, @GainVector ) );
           if SSeriesBoard then begin
              // Simultaneous sampling devices use scan timebase for timing
              NI_CheckError(SCAN_Start( Device, @ADCBuf, nSamples*nChannels,
                            TimeBase+1,0,TimeBase,ClockTicks)) ;
              end
           else begin
              // E-series and other devices
              NI_CheckError(SCAN_Start( Device, @ADCBuf, nSamples*nChannels,
                             TimeBase,ClockTicks,TimeBase+1,0)) ;
              end ;
           end ;
        end ;

     ADCActive := True ;
     Result := ADCActive ;
     end ;


function NI_StopADC : Boolean ;      { Returns FALSE = A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
begin

     Result := False ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     DAQ_Clear(Device) ;

     ADCActive := False ;
     Result := ADCActive ;

     end ;


{ ---------------------------------------------------------
  Check sampling interval to make sure it lies within valid
  range and adjust it to match sample clock settings
  ---------------------------------------------------------}
procedure NI_CheckSamplingInterval(
          var SamplingInterval : double ;  { Sampling interval (IN/OUT) }
          NumADCChannels : Integer ;
          var TimeBase : SmallInt ;        { Clock timebase code (OUT) }
          var ClockTicks : Word            { No. clock ticks (OUT) }
          )  ;
var
   ClockInterval : array[-3..5] of Single ;
begin

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     // Divide by no. of channe;s if not simultaneous sampling ADC
     if not SSeriesBoard then SamplingInterval := SamplingInterval/NumADCChannels ;

     // Limit sampling interval to working range
     SamplingInterval := Min( Max( SamplingInterval,
                                   FADCMinSamplingInterval),
                                   FADCMaxSamplingInterval) ;

     { Determine sampling clock time-base and number of ticks }
     DAQ_Rate (SamplingInterval,1,Timebase,ClockTicks ) ;
     ClockInterval[-3] := 5E-8 ;
     ClockInterval[-1] := 2E-7 ;
     ClockInterval[0] := 1E-6 ;
     ClockInterval[1] := 1E-6 ;
     ClockInterval[2] := 1E-5 ;
     ClockInterval[3] := 1E-4 ;
     ClockInterval[4] := 1E-3 ;
     ClockInterval[5] := 1E-2 ;

     if LabPCTypeBoard then begin
        // Force Lab-PC to have 1MHz timebase
        TimeBase := 1 ;
        if SamplingInterval > 0.06 then SamplingInterval := 0.06 ;
        ClockTicks := Round( SamplingInterval / ClockInterval[TimeBase] ) ;
        end
     else begin
        // (7/3/01) Timebase shifted to next lower frequency when Clockticks greater
        // than 2000 to fix -10697 error with E-Series boards when Scan_Start called
        // with ClockTicks over 3000
        if (ClockTicks > 2000) and (Timebase < 5) then begin
           Inc(Timebase) ;
           ClockTicks := ClockTicks div 10 ;
           end ;
        end ;

     SamplingInterval := ClockTicks * ClockInterval[TimeBase] ;

     // Divide by no. of channe;s if not simultaneous sampling ADC
     if not SSeriesBoard then SamplingInterval := SamplingInterval*NumADCChannels ;

     end ;


procedure NI_CheckDACUpdateInterval(
          var UpdateInterval : double ;  { Update interval (IN/OUT) }
          NumDACChannels : Integer
          )  ;
{ ---------------------------------------------------------
  Check DAC update interval to make sure it lies within valid
  range and adjust it to match sample clock settings
  ---------------------------------------------------------}
var
   ClockInterval : array[-3..5] of Single ;
   TimeBase : SmallInt ;        { Clock timebase code (OUT) }
   ClockTicks : Cardinal ;           { No. clock ticks (OUT) }

begin

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     // Limit sampling interval to working range
     if  UpdateInterval < FDACMinUpdateInterval then
         UpdateInterval := FDACMinUpdateInterval ;

     { Determine sampling clock time-base and number of ticks }
     NI_CheckError(WFM_Rate( UpdateInterval, 1,Timebase,ClockTicks));
     ClockInterval[-3] := 5E-8 ;
     ClockInterval[-1] := 2E-7 ;
     ClockInterval[0] := 1E-6 ;
     ClockInterval[1] := 1E-6 ;
     ClockInterval[2] := 1E-5 ;
     ClockInterval[3] := 1E-4 ;
     ClockInterval[4] := 1E-3 ;
     ClockInterval[5] := 1E-2 ;

     if LabPCTypeBoard then begin
        // Force Lab-PC to have 1MHz timebase
        TimeBase := 1 ;
        if UpdateInterval > 0.06 then UpdateInterval := 0.06 ;
        ClockTicks := Round( UpdateInterval / ClockInterval[TimeBase] ) ;
        end ;

     UpdateInterval := (ClockTicks * ClockInterval[TimeBase]) ;

     end ;


procedure NI_CheckError(
          Err : Integer
          ) ;
{ --------------------------------------------------------------
  Warn User if the NIDAQ Lab. interface library returns an error
  --------------------------------------------------------------}
begin

     if Err <> 0 then MessageDlg(' Lab. Interface Error = ' +
                                   format('%d',[Err]),
                                   mtWarning, [mbOK], 0 ) ;
     end ;


function NI_MemoryToDAC(
          var DACBuf : Array of SmallInt  ; { D/A output data buffer (IN) }
          nChannels : SmallInt ;            { No. of D/A channels (IN) }
          nPoints : Integer ;               { No. of D/A output values (IN) }
          UpdateInterval : Double ;          { D/A output interval (s) (IN) }
          RepeatWaveform : Boolean         // TRUE = Repeat waveform until stoped
          ): Boolean ;                      { Returns TRUE=D/A active }
{ --------------------------
  Start D/A converter output
  --------------------------}
const
    TriggerValue = 2047 ;
var
   TimeBase : SmallInt ;
   ClockTicks,nDACValues : Cardinal ;
   Channels : array[0..7] of SmallInt ;
   i,j : Integer ;
   DACValue : SmallInt ;
   NumRepeats : Integer ;
begin
     Result := False ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     // Quit if no D/A output facilities available
     if not DACHardwareAvailable then begin
        if not DACWarningDelivered then begin
           MessageDlg( 'D/A output not supported by this card', mtWarning, [mbOK], 0 ) ;
           DACWarningDelivered := True ;
           end ;
        DACActive := False ;
        Result := DACActive ;
        Exit ;
        end ;

     if DACActive then NI_StopDAC ;

     { Set D/A update clock }
     NI_CheckError(WFM_Rate( UpdateInterval, 1,Timebase,ClockTicks));
     ClockTicks := Round( UpdateInterval / TimeBasePeriod[ADCTimeBase] ) ;
     NI_CheckError(WFM_ClockRate(Device,1,0,ADCTimeBase,ClockTicks,0));

     { Set up D/A channel selection array }
     for i := 0 to High(Channels) do Channels[i] := i ;

     nPoints := Min( nPoints, FADCBufferLimit div nChannels ) ;

     if LabPCTypeBoard and (nChannels = 2) then begin
        // Insert 5V recording start pulses into DAC1 channel
        j := 1 ;
        DACValue := 0 ;
        for i := 1 to nPoints do begin
            if DACValue = 0 then DACValue := TriggerValue
                            else DACValue := 0 ;
            DACBuf[j] := DACValue ;
            j := j + nChannels ;
            end ;
        DACBuf[((nPoints-1)*nChannels) + 1] := 0 ;
        end ;

     if RepeatWaveform then NumRepeats := 0
                       else NumRepeats := 1 ;

     { Load D/A data into output buffer }
     nDACValues := nPoints*nChannels ;
     NI_CheckError( WFM_Load( Device,
                              nChannels,
                              @Channels[0],
                              @DACBuf[0],
                              nDACValues,
                              NumRepeats,
                              0)) ;

     { Begin D/A output sequence }
     NI_CheckError(WFM_Group_Control(Device,1,1)) ;

     DACActive := True ;

     Result := DACActive ;

     end ;


function NI_StopDAC : Boolean ;    { Returns FALSE = D/A stopped }
{ ---------------
  Stop D/A output
  --------------- }
begin
     Result := False ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     // Quit if no D/A output facilities available
     if not DACHardwareAvailable then Exit ;

     WFM_Group_Control(Device,1,0) ;

     DACActive := False ;
     Result := DACActive ;
     end ;


procedure NI_WriteDACs(
          DACVolts : array of Single ;
          nChannels : Integer ) ;
{ --------------------------------------
  Write values to D/A converter outputs
  -------------------------------------}
var
   iDACValue,ch : Integer ;
   iDACValue16 : SmallInt ;
begin

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     // Quit if no D/A output facilities available
     if not DACHardwareAvailable then Exit ;

     NI_StopDAC ;

     { Output the final D/A values }
     for ch := 0 to nChannels-1 do begin
         NI_CheckError( AO_Configure( Device, ch, 0, 0, 10., 1 ) ) ;
         iDACValue := Round((DACVolts[ch]*FDACMaxValue)/FDACMaxVolts) ;
         iDACValue16 := IntLimit( iDACValue, FDACMinValue, FDACMaxValue ) ;
         NI_CheckError(AO_Write(Device,ch,iDACValue16)) ;
         end ;
     NI_CheckError( AO_Update(Device) ) ;
     end ;


function NI_GetMaxDACVolts : single ;
var
   iDACValue : SmallInt ;
begin
     Result := 1.0 ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     { Determine D/A output voltage range (+/-5V or +/-10V) }
     NI_CheckError( AO_VScale( device, 0, 4.9, iDACValue ) ) ;
     if iDACValue > 2000 then Result := 5.
                         else Result := 10. ;
     end ;


function NI_MemoryToDigitalPortHandshake(
          var Buf : Array of SmallInt  ;
          nBytes : Integer ;
          var WorkBuf : Array of SmallInt
          ) : Boolean ;
{ ----------------------------------------------
  Copy bytes in DigBuf to digital output port 0
  ---------------------------------------------}
var
     PortList : Array[0..4] of Integer ;
     j : Integer ;
begin
     Result := False ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     { Clear any existing block transfers }
     Dig_Block_Clear( Device, DigPortGroup ) ;

     { Clear port assignments to group 0 }
     PortList[0] := 0 ;
     Dig_SCAN_Setup( Device, DigPortGroup, 0, @PortList, AsDigOutputPort ) ;


     { Copy every 2nd digital byte into digital O/P buffer beca }
     j := 0 ;
     DigNumBytes := 0 ;
     While j < nBytes do begin
           WorkBuf[DigNumBytes] := Buf[j] ;
           Inc(DigNumBytes) ;
           j := j + 2 ;
           end ;

     { Clear port assignments to group 0 }
     PortList[0] := 0 ;
     Dig_SCAN_Setup( Device, DigPortGroup, 0, @PortList, AsDigOutputPort ) ;
     { Note ... No CheckError because an error occurs when group
       is cleared and none has been assigned 4.9.0 }

     { Assign port 0 to group 1 as an output port }
     NI_CheckError(Dig_SCAN_Setup(Device,DigPortGroup,1,@PortList,AsDigOutputPort)) ;

     { Initiate a block transfer from DigBuf to port 0 }
     NI_CheckError(Dig_Block_Out( Device, DigPortGroup, @WorkBuf, DigNumBytes )) ;
     { The timing of the transfer is determined by the High/Low
       status of the ACK* pin on the I/O connector (pin PC6)
       This pin should be connected to the sync. pulse O/P (DAC1) }

     DigActive := True ;
     Result := DigActive ;
     end ;


procedure NI_StopDIG ;
{ ---------------------------------------------------------------
  Stop digital port waveform output (cancels MemoryToDigitalPort)
  ---------------------------------------------------------------}
var
   PortList : Array[0..4] of Integer ;
begin

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;     

     { Clear any existing block transfers }
     if DigActive then begin
        Dig_Block_Clear( Device, DigPortGroup ) ;
       { Clear port assignments to group 0 }
       PortList[0] := 0 ;
       Dig_SCAN_Setup( Device, DigPortGroup, 0, @PortList, AsDigOutputPort ) ;
       end ;

     DigActive := False ;

     end ;


procedure NI_WriteToDigitalOutPutPort(
          Pattern : Integer
          ) ;
{ ----------------------
  Update digital port 0
  ---------------------}
var
   PortList : Array[0..4] of Integer ;
begin

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;
     
     { Clear any existing block transfers }
     if DigActive then Dig_Block_Clear( Device, DigPortGroup ) ;

     { Clear port assignments to group 0 }
     PortList[0] := 0 ;
     Dig_SCAN_Setup( Device, DigPortGroup, 0, @PortList, AsDigOutputPort ) ;
     { Note ... No CheckError because an error occurs when group
       is cleared and none has been assigned 4.9.0 }

      { Set port 0 to output, mode 0 }
     DIG_Prt_Config( Device, 0, 0, AsDigOutputPort ) ;
     { NOTE No NI_CheckError because an error occurs here but doesn't
       seem to affect operation 24/8/99 }

     { Send the byte pattern }
     NI_CheckError(DIG_Out_Port( Device, 0, Pattern )) ;
     end ;


function NI_MemoryToDig(
          PDigBufIn : Pointer ;               // pointer to digital output buffer
          nPoints : Integer ;
          UpdateInterval : Double ;         // Update interval (s)
          PDigWork : Pointer                // pointer to digital output work buffer
          ): Boolean ;
// ------------------------------------------------------
// Start digital pattern output
// ------------------------------------------------------
var
   PortList : Array[0..4] of Integer ;

begin
     Result := False ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;
     
     if DigIOHandshakingSupported then begin
        // Digital output timing derived from D/A 1 synch. channel
        // for boards supports timing of digital I/O using ACK handshaking line
        NI_MemoryToDigitalPortHandshake( PSmallIntArray(PDigBufIn)^,
                                         nPoints,
                                         PSmallIntArray(PDiGWork)^) ;

        end
     else begin

        // Digital output using 10 ms software timer for all other boards
        DACDigNumPoints := nPoints ;
        DACDigPointer := 0 ;
        PDigBuf := PSmallIntArray(PDigBufIn) ;

        if DACActive then NI_StopDAC ;

        { Clear any existing block transfers }
        if DigActive then Dig_Block_Clear( Device, DigPortGroup ) ;

        { Clear port assignments to group 0 }
        PortList[0] := 0 ;
        Dig_SCAN_Setup( Device, DigPortGroup, 0, @PortList, AsDigOutputPort ) ;

        { Set port 0 to output, mode 0 }
        DIG_Prt_Config( Device, 0, 0, AsDigOutputPort ) ;

        DACDigActive := True ;

        end ;

     end ;


procedure NI_UpdateDigOutput ;
{ ----------------------------
  Update DAC and digital ports
  ----------------------------}
begin

     if (not DigIOHandshakingSupported) and
        (DACDigActive and (DACDigPointer < DACDigNumPoints)) then begin

        // update digital outputs
        NI_CheckError(DIG_Out_Port( Device, 0, PDigBuf^[DACDigPointer] )) ;

        Inc(DACDigPointer) ;

        if DACDigPointer = DACDigNumPoints then DACDigActive := False ;

        end ;

     end ;


function NI_ReadDigitalInputPort : Integer ;
{ ----------------------------
  Read state of digital port 0
  ----------------------------}
var
   Pattern : Integer ;
   PortNum : SmallInt ;
begin
     Result := 0 ;
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;
     
     // Set digital I/P port
     // Port 1 (B) used as I/P port with Lab-PC type boards
     // Port 0 all other borads
     if LabPCTypeBoard then PortNum := 1
                       else PortNum := 0 ;
     DIG_Prt_Config( Device, PortNum, 0, AsDigInputPort ) ;

     { Read the byte pattern }
     NI_CheckError(DIG_In_Port( Device, PortNum, Pattern )) ;
     Result := Pattern ;

     end ;


function NI_ReadADC(
         Channel : Integer ;       { A/D channel to be read (IN) }
         ADCVoltageRange : Single ; { A/D converter input voltage range (V) (IN) }
         ADCInputMode : Integer     // A/D input mode (differential,single-ended)
         ) : Integer ;
// ---------------------------------
// Read value from A/D input channel
// ---------------------------------
var
   ADCReading : SmallInt ; // Integer A/D value
   Gain: SmallInt ;        // A/D amplifier gain setting
   ADCModeCode : SmallInt ;
begin

     Result := 0 ;

     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     ADCModeCode := NI_GetADCInputModeCode( ADCInputMode ) ;

     NI_CheckError(AI_Configure( Device,
                                 -1,
                                 ADCModeCode,
                                 0,
                                 0,
                                 0)) ;

     { Set internal gain for A/D converter's programmable amplifier }

     Gain := Trunc( (FADCVoltageRangeMax+0.001) / ADCVoltageRange ) ;
     if Gain < 1 then Gain := -1 ;

     NI_CheckError( AI_Read( 1, Channel, Gain, ADCReading ) ) ;
     NI_ReadADC := ADCReading ;
     end ;


procedure NI_ArmStimulusTriggerInput ;
// --------------------------------------------
// Arm external stimulus waveform trigger input (PFI 9)
// --------------------------------------------
begin

     if not LabPCTypeBoard then begin
        // Setup General purpose counter (E-Series and other boards)
        // To act as trigger flip/flop
        NI_CheckError(GPCTR_Control(Device, ND_COUNTER_0, ND_RESET)) ;
        NI_CheckError(GPCTR_Set_Application(Device, ND_COUNTER_0, ND_SINGLE_TRIG_PULSE_GNR));
        NI_CheckError(GPCTR_Change_Parameter(Device, ND_COUNTER_0, ND_COUNT_1, 400000 ));
        NI_CheckError(GPCTR_Change_Parameter(Device, ND_COUNTER_0, ND_COUNT_2, 400000 ));
        NI_CheckError(GPCTR_Change_Parameter(Device, ND_COUNTER_0, ND_GATE, ND_PFI_1 ));
        NI_CheckError(GPCTR_Change_Parameter(Device, ND_COUNTER_0,ND_GATE_POLARITY,ND_LOW_TO_HIGH));
        NI_CheckError(GPCTR_Control(Device, ND_COUNTER_0, ND_PROGRAM));
        end ;

     end ;


function NI_StimulusTriggerInputState : Boolean ;
// --------------------------------------------------------
// Return state of external stimulus waveform trigger input
// --------------------------------------------------------
var
     Status : Cardinal ;
begin

     if LabPCTypeBoard then begin
        // Lab-PC/PC-1200 boards
        // Triggered by TTL_High on Bit 7, Digital Port B (pin 29)
        // (Note. Pulse >= 10ms required)
        if (NI_ReadDigitalInputPort and $80) <> 0 then Result := True
                                                  else Result := False ;
        end
     else begin
        // E-Series and other boards
        // Trigger by TTL-High pulse on PFI1/TRIG2
        NI_CheckError(GPCTR_Watch(Device, ND_COUNTER_0, ND_ARMED, Status )) ;
        if Status = ND_YES then Result := False
        else begin
             // Counter has been triggered ... Rearm and return TRUE
             NI_ArmStimulusTriggerInput ;
             Result := True ;
             end ;
        end ;
     end ;


procedure NI_GetChannelOffsets(
          var Offsets : Array of Integer ;
          NumChannels : Integer
          ) ;
var
   ch : Integer ;
begin
     for ch := 0 to NumChannels-1 do Offsets[ch] := NumChannels - 1 - ch ;
     end ;


function NI_GetValidExternalTriggerPolarity(
         Value : Boolean // TRUE=Active High, False=Active Low
         ) : Boolean ;
// -----------------------------------------------------------------------
// Check that the selected External Trigger polarity is supported by board
// -----------------------------------------------------------------------
begin
    // Lab-PC boards only support Active-High triggering
    if LabPCTypeBoard then Result := True
                      else Result := Value ;
    end ;


procedure NI_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
begin
     if not NIBoardInitialised then NIBoardInitialised := NI_InitialiseBoard ;
     if not NIBoardInitialised then Exit ;

     if DACActive then DACActive := NI_StopDAC ;

     if ADCActive then ADCActive := NI_StopADC ;

     end ;


function  IntLimit(
          Value : Integer ;
          LoLimit : Integer ;
          HiLimit : Integer
          ) : Integer ;
{ -------------------------------------------------------------
  Return integer Value constrained within range LoLimit-HiLimit
  ------------------------------------------------------------- }
begin
     if Value > HiLimit then Value := HiLimit ;
     if Value < LoLimit then Value := LoLimit ;
     Result := Value ;
     end ;

procedure NI_DisableDMA_LabPC ;
begin

     case BoardTypeNumber of
        9,28,33,48,57,58,201 : NI_CheckError( Set_DAQ_Device_Info( Device,
                                    ND_DATA_XFER_MODE_AI,
                                    ND_INTERRUPTS ) )
        end ;
     end ;

function NI_DeviceExists( iDev : Integer  ) : Boolean ;
// -------------------------------
// Return TRUE if device available
// -------------------------------
var
    Err,BoardTypeNumber,iDev16 : SmallInt ;

begin

    Result := False ;

    if not NIDAQLoaded then NI_LoadNIDAQLibrary ;
    if not NIDAQLoaded then Exit ;

    iDev16 := iDev ;
    { If the board type is not known ... get it now, and reset card }
    Err := -1 ;
    Err := Init_DA_Brds( iDev, BoardTypeNumber ) ;
    if Err = 0 then Result := True

    end ;


initialization
    NIBoardInitialised := False ;
    BoardTypeNumber := -2 ;
    NIDAQLoaded := False ;
end.
