unit Dd1200;
{ =================================================================
  WinWCP -Axon Instruments Digidata 1200 Interface Library V2.0
  (c) John Dempster, University of Strathclyde, All Rights Reserved
  13/5/97
  11/5/99 Win 32 version ... Now uses multimedia timer
  24/5/99 V2.0 Now use Win RT device driver to control Digidata 1200
  9/6/99 V2.0 Completed
  18/8/99 Multimedia timer now used to time D/A sweep intervals
  19/8/99 Internal ADCActive and DACActive flags added
  19/2/01 DD_ReadADC function added
  11/2/04 DD_ReadDigitalInputPort added
  13/11/04 Two DAC output channels now supported
           ADC & DAC timing is synchronous
           External waveform trigger now Gate 3 (rather than Digital I/P 0)
           16 bit ADC option removed
  26/11/04 Digital 1200 final tested and working
           IMPORTANT NOTE. Both D/A channels must have the SAME holding
           potential since the last two points in the D/A buffer are set
           to the D/A 0 value. (This is due to an unresolved problem with
           Digidata 1200's D/A FIFO.)
  17/11/04 Sampling interval of DD_READADC increased to avoid problems
           with very old Digidata 1200
  29/07/05 Now use TVicHW32 device driver to control Digidata 1200
  15.12.05 TVicHW32.DLL now called dynamically
  20.06.11 D/A channel number now kept within available number of channels in WriteDAC
           Returns zero if channel exceeds no. of available channels in ReadADC
  =================================================================}

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,
     mmsystem,HW_Types, math ;
const
     ADCBufSize = {32768} 4096*8 ;       // A/D buffer size (16 bit samples)
     SystemDMABufSize = ADCBufSize*2 ;   // DMA buffer size (bytes)
     ADCDMAChannel = 5 ;
     DACDMAChannel = 7 ;
     DMAWriteToMemory = 0 ;
     DMAReadFromMemory = 1 ;
     // Max. no. of samples allowed
     // (limited by DMA buffer in WinRT driver)
     dd1200_ADCBufferLimit = ADCBufSize ;

type
    TADCBuf = Array[0..ADCBufSize] of SmallInt ;
    PADCBuf = ^TADCBuf ;

    TOpenTVicHW = function : THANDLE; stdcall ;
    TOpenTVicHW32 = function ( HW32 : THANDLE;
                         ServiceName : PChar;
                         EntryPoint : PChar) : THANDLE; stdcall ;
    TCloseTVicHW32 = function (HW32 : THANDLE) : THANDLE; stdcall ;
    TGetActiveHW = function (HW32 : THANDLE) : BOOL; stdcall ;
    TGetHardAccess = function (HW32 : THANDLE) : BOOL; stdcall ;
    TSetHardAccess = procedure(HW32 : THANDLE; bNewValue : BOOL); stdcall ;
    TGetPortByte = function ( HW32 : THANDLE; PortAddr : DWORD) : Byte; stdcall ;
    TSetPortByte = procedure( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Byte); stdcall ;
    TGetPortWord = function ( HW32 : THANDLE; PortAddr : DWORD) : Word; stdcall ;
    TSetPortWord= procedure( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Word); stdcall ;
    TGetPortLong = function( HW32 : THANDLE; PortAddr : DWORD): LongInt; stdcall ;
    TSetPortLong= procedure( HW32 : THANDLE; PortAddr : DWORD; nNewValue : Longint); stdcall ;
    TMapPhysToLinear = function( HW32 : THANDLE; PhAddr : DWORD; PhSize: DWORD) : Pointer; stdcall ;
    TUnmapMemory = procedure( HW32 : THANDLE; PhAddr : DWORD; PhSize: DWORD); stdcall ;
    TGetLockedMemory = function( HW32 : THANDLE ): Pointer; stdcall ;
    TGetSysDmaBuffer = function( HW32 : THANDLE; BufReq : pDmaBufferRequest) : BOOL; stdcall ;
    TFreeDmaBuffer = function ( HW32 : THANDLE; BufReq : pDmaBufferRequest) : BOOL; stdcall ;

  procedure DD_LoadLibrary ;
  function DD_LoadProcedure(
           Hnd : THandle ;
           Name : string
           ) : Pointer ;

  procedure DD_InitialiseBoard ;
  procedure DD_ConfigureHardware( EmptyFlagIn : Integer ) ;

  function  DD_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;
  function DD_StopADC : Boolean ;
  procedure DD_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;
  procedure DD_SetADCClock(
            dt : Double ;
            WaitForExtTrigger : Boolean
            ) ;
  procedure DD_CheckSamplingInterval(
            var SamplingInterval : Double ;
            var Ticks : Cardinal ;
            var FrequencySource : Word
            ) ;

function  DD_MemoryToDAC(
          var DACValues : Array of SmallInt  ; // D/A values to be output
          NumDACChannels : Integer ;           // No. D/A channels
          NumDACPoints : Integer ;             // No. points per channel
          ExternalTrigger : Boolean ;          // External start of D/A sweep
          var ADCSamplingInterval : Double ;   // A/D sampling interval (s)
          NumADCChannels : Integer ;            // No. A/D channels
          NumADCPoints : Integer
          ) : Boolean ;

  procedure DD_ConvertToDACCodes(
            var DACBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nPoints : Integer
            ) ;
  procedure DD_SetDACClock(
            dt : single ; nChannels : Integer
            ) ;
  function DD_StopDAC : Boolean ;

  function DD_ReadADC( Chan : Integer ; ADCVoltageRange : Single ) : SmallInt ;

  procedure DD_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : SmallInt
            ) ;
  procedure DD_AddDigitalWaveformToDACBuf(
            var DigBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nPoints : Integer
            ) ;

  function DD_ReadDigitalInputPort : Integer ;

  function  DD_GetLabInterfaceInfo(
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


  function DD_GetMaxDACVolts : single ;
  procedure DD_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
  procedure DD_CloseLaboratoryInterface ;

  procedure DD_ProgramDMAChannel( DMAChannel : Integer ;
                                  DMABufReq : TDMABufferRequest ;
                                  DMADirection : Integer ;
                                  nBytes : LongInt ;
                                  AutoInitialise : boolean ) ;
  procedure DD_EnableDMAChannel( DMAChannel : Integer ) ;
  procedure DD_DisableDMAChannel( DMAChannel : Integer ) ;

   procedure SetBits( var Dest : Word ; Bits : Word ) ;
   procedure ClearBits( var Dest : Word ; Bits : Word ) ;


implementation

uses seslabio ;

const
     ClockPeriod = 2.5E-7 ; { 4MHz clock }
     DACVoltageRangeMax = 10.23 ;

     { Bit maps for DAC data at 00 (HEX) }

     DACINHIBITADC = $0001 ; {DAC bit 0 used to inhibit ADC   }
     DACDATAMASK = $FFF0 ; { Mask out the non-DAC bits }

     { Bit maps for ADC data at 00 (HEX) }

     ADCTAGMASK = $0001 ; { Mask for Tag bit in ADC word }
     ADCXTRIGMASK = $0002 ; { Mask for XTrig bit in ADC word }
     ADCDATAMASK = $FFF0 ; { Mask out the non-ADC bits }

     DIGIDATA1200ID = 2 ; { ID value for DD1200 }

     { Bit maps for ADC/DAC/Trig control regsiter at 08h (HEX) }
     ADCINHIBIT = $0080 ; { Enable ADC inhibit via DAC bit 0 }
     ADCGEARENABLE = $0020 ; { Enable ADC gearshift timing }
     { Enable/disable scanlist programming }
     ADCSCANLISTENABLE   = $10 ; {0000000000010000}
     ADCSCANLISTDISABLE  = $FFEF ; {1111111111101111}
     { Enable/disable split-click mode }
     AdcSplitClockEnable = $20 ; {0000000000100000}
     AdcSplitClockDisable = $FFDF ; {1111111111011111}

     ASYNCHDIGITALENABLE = $0008 ; { Enable asynch digital output }
     ADCASYNCDAC = $0004 ;    {Enable ADC asynchronous with DAC }
     DACCHAN1ENABLE = $0002 ; { Enable DAC channel 1 for output }
     DACCHAN0ENABLE = $0001 ; { Enable DAC channel 0 for output }

     { Constants for DMA/Interrupt configuration port at 0A (HEX) }

     INTERRUPTENABLE = $8000 ;{ Enable interrupt requests }
     INTERRUPTIRQ10 = $0000 ; { Enable interrupt via IRQ 10 }
     INTERRUPTIRQ11 = $2000 ;{ Enable interrupt via IRQ 11 }
     INTERRUPTIRQ12 = $4000 ; { Enable interrupt via IRQ 12 }
     INTERRUPTIRQ15 = $6000 ; { Enable interrupt via IRQ 15 }
     INTWHENADCDONE = $0800 ; { Enable interrupt when ADC done }
     INTWHENADCOVERRUN = $0400 ; { Enable interrupt on ADC overrun }
     INTWHENDMADONE = $0200 ; { Enable interrupt on DMA complete }
     INTWHENTIMER4DONE = $0100 ; { Enable interrupt on Timer 4 done }
     INTWHENTIMER3DONE = $0080 ; { Enable interrupt on Timer 3 done }
     INTWHENTIMER1DONE = $0040 ; { Enable interrupt on Timer 1 done }
     ADCSINGLEDMA = $0010 ; { Enable ADC single transfer mode }


     DMACHANNEL5 = $0001 ; { Use DMA channel 5 }
     DMACHANNEL6  = $0002 ; { Use DMA channel 6 }
     DMACHANNEL7 = $0003 ; { Use DMA channel 7 }
     DMAADCSHIFT = $1 ; { DMA channel shift for ADC }
     DMADACSHIFT = $4 ;{  DMA channel shift for DAC }

     { Bit maps for Scan list register at 0E (HEX) }

     SCANLASTENTRYFLAG = $8000 ; { Set this bit in last list entry }
     SCANCHANNELGAIN1 = $0000 ; { Gain bits for gain of 1 }
     SCANCHANNELGAIN2 = $2000 ; { Gain bits for gain of 2 }
     SCANCHANNELGAIN4 = $4000 ; { Gain bits for gain of 4 }
     SCANCHANNELGAIN8 = $6000 ; { Gain bits for gain of 8NULL }
     SCANCHANNELSHIFT = 256 ; { Shift for ADC channel number }

     {  Status code read from ADC/DAC status at 16 (HEX) }
     ADCOVERRUN	 = $0080 ; {ADC has overrun the FIFO }
     ADCDATAREADY = $0040 ; {ADC FIFO has one or more samples}
     DMATRANSFERDONE = $0020 ; {A DMA channel has reached TC}
     TIMER4DONE	 = $0004 ; {Timer channel 4 has reached TC}
     TIMER3DONE	 = $0002 ; {Timer channel 3 has reached TC}
     TIMER1DONE	 = $0001 ; {Timer channel 1 has reached TC}

     { Commands issued to the Clear register at 1A (HEX) }
     ADCSTARTCONVERT	 = $0080 ;
     RESETDMADONE	 = $0020 ;
     RESETADCFLAGS	 = $0010 ;
     RESET_SCAN_LIST	 = $10 ;
     RESET_XTRIG_TAG	 = $10 ;
     RESETDACFLAGS	 = $08 ;
     RESETTIMER4DONE	 = $04 ;
     RESETTIMER3DONE	 = $02 ;
     RESETTIMER1DONE	 = $01 ;
     RESETWHOLEBOARD	 = $7F ;

     { Bit-map for the registers accessed from the 9513 Command Port. }
     MASTERMODE   = $17 ;
     STATUSREG	  = $1F ;
     MODEREGISTER = $00 ;
     LOADREGISTER = $08 ;
     HOLDREGISTER = $10 ;

     { The following three constants need to be ORed with a counter selector. }
     MODE_REG	  = $00 ;
     LOAD_REG	  = $08 ;
     HOLD_REG	  = $10 ;
     CTR1_GRP	  = $01 ;
     CTR2_GRP	  = $02 ;
     CTR3_GRP	  = $03 ;
     CTR4_GRP	  = $04 ;
     CTR5_GRP	  = $05 ;

     { Commands for the 9513 Command Port. }
     ARM 	  = $20 ;
     LOADCOUNT	  = $40 ;
     LOADARM	  = $60 ;
     DISARM	  = $C0 ;
     CLEAROUT	  = $E0 ;
     SETOUT	  = $E8 ;
     SET16BITMODE  = $EF ;
     MASTERRESET   = $FF ;

     {Master mode configuration
c Set up the Master Mode Register :
c     15 : scaler control = BCD division.	1:BCD
c     14 : enable data pointer auto-increment.	1:Off
c     13 : data-bus width = 8 bits.		1:16-bit
c     12 : FOUT gate ON.			1:Off
c   11-8 : FOUT divider = divided by 16.	0000
c    7-4 : FOUT source = F1 (1MHZ oscillator).
c      3 : comparator 2 disabled.
c      2 : comparator 1 disabled.
    1-0 : Time of Day disabled. }

     MASTER = $f000 ;

     { Bit-maps for the 9513 counters. }
     COUNTER1 = $01;
     COUNTER2 = $02;
     COUNTER3 = $04;
     COUNTER4 = $08;
     COUNTER5 = $10;

     { Bit-maps for the counter output states in the 9513 Status register. }
     OUT1  = 2 * COUNTER1 ;
     OUT2  = 2 * COUNTER2 ;
     OUT3  = 2 * COUNTER3 ;
     OUT4  = 2 * COUNTER4 ;
     OUT5  = 2 * COUNTER5 ;

     TOGGLE = $2 ;
     REPEAT_COUNT = $20 ; {2#100000 }
     ACTIVE_HIGH_TC = $1 ;
     ACTIVE_HIGH_LEVEL_GATE = $8000 ;

     { Minimum timer counts (TC-toggled) for known versions of the board.
       333 kHz = 3 micro-second period @ 4 MHz TCToggled }
     MINACQCLOCK = 6  ;
     MAXCHANNEL	= 15 ;

     { Error code }
     ERROR_BAD = 1 ;
     ERROR_WARNING = 2 ;
     ERROR_BADKEY = 3 ;
     DIGI_OK  = 0 ;
     DIGI_ID_ERROR  = 1 ;
     DIGI_9513_ERROR  = 2 ;

     // System DMA controller constants

     DATATOBECOPIED = $2 ;
     DISABLEBUFFERALLOCATION = $4 ;
     DISABLEAUTOREMAP = $8 ;
     ALIGN64K = $10 ;
     ALIGN128K = $20 ;

     DMA5_PAGE = $8B ;
     DMA6_PAGE = $89 ;
     DMA7_PAGE = $8A ;
     DMA5_ADDRESS = $C4 ;
     DMA6_ADDRESS = $C8 ;
     DMA7_ADDRESS = $CC ;
     DMA5_COUNT = $C6 ;
     DMA6_COUNT = $CA ;
     DMA7_COUNT = $CE ;
     DMA_FLIPFLOP = $D8 ;
     DMA_MASK = $D4 ;
     DMA_MODE = $D6 ;
     DMA_STATUS = $D0 ;

     CH5_ON = 1 ;
     CH6_ON = 2 ;
     CH7_ON = 3 ;
     CH5_OFF = 5 ;
     CH6_OFF = 6 ;
     CH7_OFF = 7 ;
     CH5_TC = 2 ;
     CH6_TC = 4 ;
     CH7_TC = 8 ;
     CH5_WRITEMODE = $45 ;
     CH5_WRITEMODEA = $55 ;
     CH5_READMODE = $49 ;
     CH5_READMODEA = $59 ;
     CH6_WRITEMODE = $46 ;
     CH6_WRITEMODEA = $56 ;
     CH6_READMODE = $4A ;
     CH6_READMODEA = $5A ;
     CH7_WRITEMODE = $47 ;
     CH7_WRITEMODEA = $57 ;
     CH7_READMODE = $4B ;
     CH7_READMODEA = $5B ;

type

    TDD1200Registers = record
           Base : Cardinal ;
           DACData : Cardinal ;
           ADCData: Cardinal ;
           ID : Cardinal ;
           TimerData : Cardinal ;
           TimerControl : Cardinal ;
           Control : Cardinal ;
           DMAConfig : Cardinal ;
           DigitalIO : Cardinal ;
           ADCScanList : Cardinal ;
           T8254Channel0 : Cardinal ;
           T8254Channel1 : Cardinal ;
           T8254Channel2 : Cardinal ;
           T8254Control : Cardinal ;
           Status : Cardinal ;
           Reset : Cardinal ;
           end ;

var

   LibraryLoaded : Boolean ;           // DLL library loaded
   LibHandle : THandle ;               // Library file handle
   DevH : Integer ;                    // Virtual device driver handle
   ADCDMABufReq : TDmaBufferRequest ;  // A/D DMA buffer request record
   DACDMABufReq : TDmaBufferRequest ;  // D/A DMA buffer request record

   FADCVoltageRangeMax : single ;  { Max. positive A/D input voltage range}
   FADCMinValue : Integer ;
   FADCMaxValue : Integer ;
   FDACMinUpdateInterval : Double ;
   FADCMinSamplingInterval : single ;
   FADCMaxSamplingInterval : single ;

   DeviceInitialised : boolean ; { True if hardware has been initialised }
   IOPorts : TDD1200Registers ;
   ControlWord : Word ;
   ConfigWord : Word ;
   EmptyFlag : Integer ;

   CyclicADCBuffer : Boolean ;
   ADCSweepDone : Boolean ;
   EndOfADCBuf : Integer ;
   ADCPointer : Integer ;

   DefaultDigValue : Integer ;
   DigitalOutputRequired : Boolean ;

   { Global variable used by Win RT routines }
   ADCActive : Boolean ;
   DACActive : Boolean ;
   ADCBuf : PADCBuf ;
   DACBuf : PADCBuf ;

   OpenTVicHW : TOpenTVicHW ;
   OpenTVicHW32 : TOpenTVicHW32 ;
   CloseTVicHW32 : TCloseTVicHW32 ;
   GetPortByte : TGetPortByte ;
   SetPortByte : TSetPortByte ;
   GetPortWord : TGetPortWord ;
   SetPortWord : TSetPortWord ;
   GetPortLong : TGetPortLong ;
   SetPortLong : TSetPortLong ;
   MapPhysToLinear : TMapPhysToLinear ;
   UnmapMemory : TUnmapMemory ;
   GetLockedMemory : TGetLockedMemory ;
   GetSysDmaBuffer : TGetSysDmaBuffer ;
   FreeDmaBuffer : TFreeDmaBuffer ;


procedure DD_LoadLibrary  ;
// ----------------
// Load DLL library
// ----------------
begin
     { Load library }
     LibHandle := LoadLibrary( PCHar('TVicHW32.dll') ) ;
     if LibHandle <> 0 then begin

       { Get addresses of DLL procedure used }
        @OpenTVicHW := DD_LoadProcedure( LibHandle, '_OpenTVicHW@0' ) ;
        @OpenTVicHW32 := DD_LoadProcedure( LibHandle, '_OpenTVicHW32@12' ) ;
        @CloseTVicHW32 := DD_LoadProcedure( LibHandle, '_CloseTVicHW32@4' ) ;
        @GetPortByte := DD_LoadProcedure( LibHandle, '_GetPortByte@8' ) ;
        @SetPortByte := DD_LoadProcedure( LibHandle, '_SetPortByte@12' ) ;
        @GetPortWord := DD_LoadProcedure( LibHandle, '_GetPortWord@8' ) ;
        @SetPortWord := DD_LoadProcedure( LibHandle, '_SetPortWord@12' ) ;
        @GetPortLong := DD_LoadProcedure( LibHandle, '_GetPortLong@8' ) ;
        @SetPortLong := DD_LoadProcedure( LibHandle, '_SetPortLong@12' ) ;
        @MapPhysToLinear := DD_LoadProcedure( LibHandle, '_MapPhysToLinear@12' ) ;
        @UnmapMemory := DD_LoadProcedure( LibHandle, '_UnmapMemory@12' ) ;
        @GetLockedMemory := DD_LoadProcedure( LibHandle, '_GetLockedMemory@4' ) ;
        @GetSysDmaBuffer := DD_LoadProcedure( LibHandle, '_GetSysDmaBuffer@8' ) ;
        @FreeDmaBuffer := DD_LoadProcedure( LibHandle, '_FreeDmaBuffer@8' ) ;
        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'TVicHW32.dll library not found' ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function DD_LoadProcedure(
         Hnd : THandle ;       { Library DLL handle }
         Name : string         { Procedure name within DLL }
         ) : Pointer ;         { Return pointer to procedure }
var
   P : Pointer ;

begin
     P := GetProcAddress(Hnd,PChar(Name)) ;
     if {Integer(P) = Null} P = Nil then begin
        ShowMessage(format('TVicHW32.dll- %s not found',[Name])) ;
        end ;
     Result := P ;
     end ;



function  DD_GetLabInterfaceInfo(
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
   DeviceType : Word ;
begin

     Result := False ;
     if not DeviceInitialised then DD_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     // Get type of Digidata 1200
     DeviceType := GetPortWord( DevH, IOPorts.ID) ;

     DeviceType := DeviceType  and $3 ;
     case DeviceType of
          2 : Model := 'Digidata 1200 ' ;
          3 : Model := 'Digidata 1200A ' ;
          else Model := 'Digidata 1200? ' ;
          end ;

     { Determine available A/D voltage range options }

     ADCVoltageRanges[0] := 10.23 ;
     ADCVoltageRanges[1] := 5.125 ;
     ADCVoltageRanges[2] := 2.506 ;
     ADCVoltageRanges[3] := 1.253 ;
     NumADCVoltageRanges := 4 ;
     FADCVoltageRangeMax := ADCVoltageRanges[0] ;

     // A/D sample value range (12/16 bits)
     ADCMinValue := -2048 ;
     ADCMaxValue := -ADCMinValue - 1 ;
     FADCMinValue := ADCMinValue ;
     FADCMaxValue := ADCMaxValue ;

     { Upper limit of bipolar D/A voltage range }
     DACMaxVolts := 10.24 ;

     DACMinUpdateInterval := 2E-5 ;
     FDACMinUpdateInterval := DACMinUpdateInterval ;

     ADCMinSamplingInterval := 1E-5 ;
     ADCMaxSamplingInterval := 1000. ;
     FADCMinSamplingInterval := ADCMinSamplingInterval ;
     FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

     ADCBufferLimit := dd1200_ADCBufferLimit ;

     Result := True ;

     end ;


function  DD_GetMaxDACVolts : single ;
{ -----------------------------------------------------------------
  Return the maximum positive value of the D/A output voltage range
  -----------------------------------------------------------------}

begin
     Result := DACVoltageRangeMax ;
     end ;


procedure DD_InitialiseBoard ;
{ -------------------------------------------
  Initialise Digidata 1200 interface hardware
  -------------------------------------------}
const
  NumBufs = 10 ;

var
   Value : Word ;
   i : Integer ;
   DMAPageStart,DMAPageEnd : Integer ;
   DMABufReq : Array[0..9] of TDmaBufferRequest ;
   BufAllocated : Array[0..NumBufs-1] of Integer ;
   iBuf : Integer ;
   GoodBuffer : Boolean ;
   NumGoodBuffers : Integer ;
begin

     DeviceInitialised := False ;

     if not LibraryLoaded then DD_LoadLibrary ;
     if not LibraryLoaded then Exit ;

     { Define Digidata 1200 I/O port addresses }
     IOPorts.Base := $320 ;
     IOPorts.DACData := IOPorts.Base ;
     IOPorts.ADCData := IOPorts.Base ;
     IOPorts.ID  := IOPorts.Base + $2 ;
     IOPorts.TimerData := IOPorts.Base + $4;
     IOPorts.TimerControl := IOPorts.Base + $6;
     IOPorts.Control := IOPorts.Base + $8 ;
     IOPorts.DMAConfig := IOPorts.Base + $0A ;
     IOPorts.DigitalIO := IOPorts.Base +$0c ;
     IOPorts.ADCScanList := IOPorts.Base + $0E;
     IOPorts.T8254Channel0 := IOPorts.Base + $10 ;
     IOPorts.T8254Channel1 := IOPorts.Base + $12 ;
     IOPorts.T8254Channel2 := IOPorts.Base + $14 ;
     IOPorts.T8254Control := IOPorts.Base + $16 ;
     IOPorts.Status := IOPorts.Base + $18 ;
     IOPorts.Reset  := IOPorts.Base + $1A ;

     // Open Digidata 1200 virtual device driver
     DevH := OpenTVicHW ;
     if DevH = 0 then begin
        ShowMessage( 'Unable to open Digidata 1200 driver! ' ) ;
        Exit ;
        end ;

     // Allocate 2 DMA buffers contained within a single 128Kb page
     iBuf := 0 ;
     for i := 0 to High(DMABufReq) do BufAllocated[i] := 0 ;
     NumGoodBuffers := 0 ;
     repeat

        // Allocate A/D system DMA buffer
        GoodBuffer := True ;
        DMABufReq[iBuf].LengthOfBuffer := SystemDMABufSize ;
        DMABufReq[iBuf].AlignMask := 0 ;
        if not GetSysDmaBuffer( DevH, @DMABufReq[iBuf] ) then GoodBuffer := False ;

        // Check that DMA buffers lie within same 64KByte DMA page block
        DMAPageStart := DMABufReq[iBuf].PhysDmaAddress div $20000;
        DMAPageEnd := (DMABufReq[iBuf].PhysDmaAddress +
                       DMABufReq[iBuf].LengthOfBuffer-1) div $20000 ;
        if DMAPageStart <> DMAPageEnd then GoodBuffer := False ;
        //outputdebugString(PChar(format('ADC %d %d',[DMAPageStart,DMAPageEnd]))) ;

        if GoodBuffer then begin
           Inc(NumGoodBuffers) ;
           BufAllocated[iBuf] := NumGoodBuffers ;
           end
        else  BufAllocated[iBuf] := -1 ;
        Inc(iBuf) ;

        until (NumGoodBuffers >= 2) or (iBuf > High(DMABufReq)) ;

    // Allocate good buffers as A/D and D/A DMA buffers
    if NumGoodBuffers >= 2 then begin
       for i:= 0 to High(DMABufReq) do begin
           if BufAllocated[i] < 0 then begin
              // Free bad buffers
              FreeDMABuffer( DevH, @DMABufReq[i] ) ;
              end
           else if BufAllocated[i] = 1 then begin
              // Allocate A/D buffer
              ADCDMABufReq := DMABufReq[i] ;
              ADCBuf := PADCBuf(ADCDMABufReq.LinDmaAddress) ;
              end
           else if BufAllocated[i] = 2 then begin
              // Allocate D/A buffer
              DACDMABufReq := DMABufReq[i] ;
              DACBuf := PADCBuf(DACDMABufReq.LinDmaAddress) ;
              end ;
           end ;
       end
    else begin
       ShowMessage('Unable to allocate Digidata 1200 DMA buffers') ;
       // Free bad buffers
       for i:= 0 to High(DMABufReq) do if BufAllocated[i] < 0 then begin
           FreeDMABuffer( DevH, @DMABufReq[i] ) ;
           end ;
       CloseTVicHW32( DevH ) ;
       Exit ;
       end ;

    // Set buffer pointers

    { Send initialisation data to Digidata 1200 }
    SetPortWord(  DevH, IOPorts.Reset, RESETWHOLEBOARD ) ;

    { Set up the 9513 timer chip: master reset. Do I/O in 8-bit mode.
    then set to 16-bit mode. }
    SetPortByte( DevH, IOPorts.TimerControl, MASTERRESET ) ;
    SetPortByte( DevH, IOPorts.TimerControl, SET16BITMODE ) ;

    { Point the Data Pointer register at the Master Mode register. }
    SetPortWord(  DevH, IOPorts.TimerControl, MASTERMODE ) ;

             { Set up the Master Mode register:
 	      15  scaler control = BCD division
 	      14  enable data pointer auto-increment
 	      13  data-bus width = 16 bits
 	      12  FOUT gate OFF
 	    11-8  FOUT divider = divide by 16
 	     7-4  FOUT source = F1 (1 MHz oscillator)
 	       3  comparator 2 disabled
 	       2  comparator 1 disabled
 	     1-0  Time-of-Day disabled }

    Value := $6000 ; { 0110 0000 0000 0000 }
    SetPortWord(  DevH, IOPorts.TimerData, Value ) ;

    { Enable A/D sampling transfer using DMA channels 5 for A/D and 7 for D/A }
    ConfigWord := DMACHANNEL5 or (DMACHANNEL7*DMADACSHIFT) or ADCSINGLEDMA ;
    SetPortWord(  DevH, IOPorts.DMAConfig, ConfigWord ) ;

    { Enable D/A 0 and use COUNTER 1 to control it
     (Note the use of the variable "ControlWord" to keep the port settings }
    ControlWord := ADCASYNCDAC or DACCHAN0ENABLE ;
    SetPortWord(  DevH, IOPorts.Control, ControlWord ) ;

    { Clear D/A outputs }
    SetPortWord(  DevH, IOPorts.DACData, 0 ) ;

    DACActive := False ;
    DeviceInitialised := True ;

    end ;


procedure DD_ConfigureHardware(
          EmptyFlagIn : Integer ) ;
{ --------------------------
  Configure A/D empty flag
  -------------------------- }
begin
     EmptyFlag := EmptyFlagIn ;
     end ;


function DD_ADCToMemory(
          var HostADCBuf : Array of SmallInt  ;   { A/D sample buffer (OUT) }
          nChannels : Integer ;                   { Number of A/D channels (IN) }
          nSamples : Integer ;                    { Number of A/D samples ( per channel) (IN) }
          var dt : Double ;                       { Sampling interval (s) (IN) }
          ADCVoltageRange : Single ;              { A/D input voltage range (V) (IN) }
          TriggerMode : Integer ;                 { Trigger Mode (IN) }
          CircularBuffer : Boolean                { Repeated sampling into buffer (IN) }
          ) : Boolean ;                           { Returns TRUE indicating A/D started }
{ -----------------------------
  Start A/D converter sampling
  -----------------------------}

var
   Gain,GainBits,ChannelBits,i : Word ;
   ch : Integer ;
   dt1 : single ;
   NumBytesToTransfer : Integer ;
   WaitForExtTrigger : Boolean ;
begin

     Result := False ;
     if not DeviceInitialised then DD_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     { Disable A/D converter and DMA channel }
     { Stop COUNTER 2 which times A/D & D/A sampling }
     SetPortWord( DevH, IOPorts.TimerControl, DISARM or COUNTER2 ) ;
     SetPortWord( DevH, IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;

     { Inter-sample interval is channel group sampling interval
       divided by number of channels in group. Note that DT1 and DT
       are modified after SET_ADC_CLOCK_DIGIDATA to be precisely equal to an
       interval supported by the interface. }

     if TriggerMode = tmExtTrigger then WaitForExtTrigger := True
                                   else WaitForExtTrigger := False ;
     dt1 := dt / nChannels ;
     DD_SetADCClock( dt1, WaitForExtTrigger ) ;
     dt := dt1 * nChannels ;

     { Select a gain setting }
     Gain := Round( FADCVoltageRangeMax/ADCVoltageRange ) ;
     Case Gain of
          1 : GainBits := 0 ;
          2 : GainBits := 1 ;
          4 : GainBits := 2 ;
          8 : GainBits := 3 ;
          else GainBits := 0 ;
          end ;

     {Determine end of cyclic A/D buffer }
     EndOfADCBuf := nChannels*nSamples - 1 ;
     {Fill internal DMA buffer with empty flag }
     for i := 0 to EndOfADCBuf do begin
         ADCBuf[i] := EmptyFlag ;
         end ;

     { Initialise buffer pointer }
     ADCPointer := 0 ;

     { Program Digidata 1200 for A/D conversion }

     { Program channel gain/select list }
     SetBits( ControlWord, ADCSCANLISTENABLE ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     for ch := 0 to nChannels-1 do begin
         ChannelBits := ch or ($100*ch) or (GainBits*$2000) ;
         if ch = (nChannels-1) then ChannelBits := ChannelBits or $8000 ;
         SetPortWord( DevH, IOPorts.ADCScanList, ChannelBits ) ;
         end ;

     // Clear asynchronous A/D & D/A timing bit
     // (A/D and D/A both timed by Counter 2)
     SetBits( ControlWord, ADCASYNCDAC ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     ClearBits( ControlWord, ADCSCANLISTENABLE ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     { Reset A/D FIFO & scan list pointer (bit 4)
     9513 DONE3 flag (bit 1) }
     SetPortWord( DevH, IOPorts.Reset, RESET_SCAN_LIST ) ;

     { Enable DMA controller, ready for samples when they appear }
     NumBytesToTransfer := nChannels*nSamples*2 ;
     DD_ProgramDMAChannel( ADCDMAChannel,
                           ADCDMABufReq,
                           DMAWriteToMemory,
                           NumBytesToTransfer,
                           CircularBuffer ) ;

     // Set cyclic ADC buffer flag (used by DD_GetADCSamples)
     CyclicADCBuffer := CircularBuffer ;

     { Wait for external trigger pulse into GATE 3 }
     if WaitForExtTrigger then begin
        { External trigger mode }

	      SetPortWord( DevH, IOPorts.TimerControl, LOADCOUNT or COUNTER2 ) ;
	      SetPortWord( DevH, IOPorts.TimerControl, ARM or COUNTER2 ) ;

        { Enable split-clock mode (bit5) which connects OUT 3 to GATE 2 }
        SetBits( ControlWord, ADCSPLITCLOCKENABLE ) ;
	      SetPortWord( DevH, IOPorts.Control, ControlWord ) ;
 	      SetPortWord( DevH, IOPorts.TimerControl, ARM or COUNTER3 ) ;
        end
     else begin
        { Free run & waveform generation mode }

	      ClearBits( ControlWord, ADCSPLITCLOCKENABLE ) ;
	      SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

        // Start A/D conversion if in free run mode
        // (otherwise A/D+D/A conversion started by DD_MemoryToDac)
        if TriggerMode = tmFreeRun then begin
           SetPortWord( DevH, IOPorts.TimerControl, ARM or COUNTER2 ) ;
           end ;
        end ;

     { Set flag indicating that ADC is running }
     ADCActive := True ;
     Result := ADCActive ;
     ADCSweepDone := False ;

     end ;


procedure DD_SetADCClock(
          dt : Double ;
          WaitForExtTrigger : Boolean
          ) ;
{-------------------------------------------------------------
 Set ADC sampling clock
 A/D samples are timed using a 16 bit counter fed via dividers
 from a 0.25us clock. (The digidata 1200's 9513A time channel No.2 is used)
-------------------------------------------------------------}
var
   Mode2Bits,Mode3Bits,FrequencySource : Word ;
   Ticks : Cardinal ;
begin

     { Convert A/D sampling period from <dt> (in s) into
       clocks ticks, using a clock frequency which
       ensures that the number of ticks fits into the 9513A's
       16 bit counter register. }

     DD_CheckSamplingInterval( dt, Ticks, FrequencySource ) ;

     { Program Digidata 1200 for A/D conversion }

     { Set counter No. 2 mode register to:- repeated counts,
       frequency source period (set by ifreq_source):
       ACTIVE-HIGH terminal count toggled On/Off pulse }
	   Mode2bits := (FrequencySource + $A)*$100 or REPEAT_COUNT or ACTIVE_HIGH_TC ;

     { If external triggering requested, set Counter 2 (A/D sampling timer)
          to be gated by an ACTIVE-HIGH level from the terminal count of
          Counter 3. Set Counter 3 for a single count, triggered by an
          ACTIVE-HIGH LEVEL pulse on GATE 3. }

	   if WaitForExtTrigger then begin
        { Set up Channel 3 to to a single 2us count when
          the GATE 3 goes high and to toggle its OUT 3 line
          high when the terminal count is reached }
	      SetPortWord( DevH, IOPorts.TimerControl, DISARM or COUNTER3 ) ;
	      SetPortWord( DevH, IOPorts.TimerControl, CLEAROUT or 3 ) ;

	      Mode3Bits := $B00 or TOGGLE or ACTIVE_HIGH_LEVEL_GATE ;
	      SetPortWord( DevH, IOPorts.TimerControl, MODE_REG or CTR3_GRP ) ;
	      SetPortWord( DevH, IOPorts.TimerData, Mode3Bits ) ;
	      SetPortWord( DevH, IOPorts.TimerControl, LOAD_REG or CTR3_GRP ) ;
	      SetPortWord( DevH, IOPorts.TimerData, 3 ) ;
	      SetPortWord( DevH, IOPorts.TimerControl, LOADCOUNT or COUNTER3 ) ;

	      Mode2bits := Mode2bits or ACTIVE_HIGH_LEVEL_GATE ;
	      end ;

     { Set Counter 2's mode and load registers and initialise counter
      (If in External Trigger mode, gate Counter 2 with the GATE 2 input }

	   SetPortWord( DevH, IOPorts.TimerControl, MODE_REG or CTR2_GRP ) ;
	   SetPortWord( DevH, IOPorts.TimerData, Mode2bits ) ;
	   SetPortWord( DevH, IOPorts.TimerControl, LOAD_REG or CTR2_GRP ) ;
	   SetPortWord( DevH, IOPorts.TimerData, Ticks ) ;
	   SetPortWord( DevH, IOPorts.TimerControl, LOADCOUNT or COUNTER2 ) ;

     end ;


function DD_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
begin
     Result := False ;
     if not DeviceInitialised then DD_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     { Stop COUNTER 2 which times A/D samples }
     SetPortWord( DevH, IOPorts.TimerControl, DISARM or COUNTER2 ) ;
     SetPortWord( DevH, IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;

     { Disable DMA channel }
     DD_DisableDMAChannel( ADCDMACHannel ) ;

     ADCActive := False ;
     Result := ADCActive ;

     end ;


procedure DD_GetADCSamples(
          var OutBuf : Array of SmallInt ;  { Buffer to receive A/D samples }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
// --------------------------------------------------------- 
// Transfer latest A/D sample from internal to output buffer
// ---------------------------------------------------------
var
   n : Integer ;
begin

     if not ADCActive then Exit ;

     if CyclicADCBuffer then begin
        { Continuous circular A/D buffer }
        n := 0 ;
        While (ADCBuf^[ADCPointer] <> EmptyFlag) and (n < EndofADCBuf) do begin
              OutBuf[ADCPointer] := ADCBuf^[ADCPointer] shr 4 ;
              ADCBuf^[ADCPointer] := EmptyFlag ;
              Inc(ADCPointer) ;
              Inc(n) ;
              if ADCPointer > EndOfADCBuf then ADCPointer := 0 ;
              end ;
        OutBufPointer := ADCPointer ;

        end
     else begin
        { Single sweep }
        While (ADCBuf^[ADCPointer] <> EmptyFlag) and not ADCSweepDone do begin
              OutBuf[ADCPointer] := ADCBuf^[ADCPointer] shr 4 ;
              Inc(ADCPointer) ;
              if ADCPointer > EndOfADCBuf then ADCSweepDone := True ;
              if ADCSweepDone then ADCPointer := EndOfADCBuf ;
              end ;
         end ;
         //outputdebugString(PChar(format('%d ',[ADCPointer]))) ;
     OutBufPointer := ADCPointer ;

     end ;


procedure DD_CheckSamplingInterval(
          var SamplingInterval : Double ;
          var Ticks : Cardinal ;
          var FrequencySource : Word
          ) ;
{ ---------------------------------------------------
  Convert sampling period from <SamplingInterval> (in s) into
  clocks ticks, using a clock period which ensures that the no.
  of ticks fits into the 9513A's 16 bit counter register.
  Returns no. of ticks in "Ticks" and the clock frequency
  selection index in "FrequencySource
  ---------------------------------------------------}
var
   Scale : single ;
begin
	      Scale := 1. / 16. ;
        FrequencySource := 0 ;
        repeat
            Inc(FrequencySource) ;
            Scale := Scale*16. ;
	          Ticks := Round( SamplingInterval/(ClockPeriod*Scale) );
            until (Ticks <= 32767) or (FrequencySource >= 5) ;
	      SamplingInterval := Ticks*Scale*ClockPeriod ;
	      end ;


function  DD_MemoryToDAC(
          var DACValues : Array of SmallInt  ; // D/A values to be output
          NumDACChannels : Integer ;           // No. D/A channels
          NumDACPoints : Integer ;             // No. points per channel
          ExternalTrigger : Boolean ;          // External start of D/A sweep
          var ADCSamplingInterval : Double ;   // A/D sampling interval (s)
          NumADCChannels : Integer ;            // No. A/D channels
          NumADCPoints : Integer
          ) : Boolean ;
{ --------------------------------------------------------------
  Send a voltage waveform stored in DACBuf to the D/A converters
  --------------------------------------------------------------}
var
   i,i0,ch,NumBytesToTransfer : Integer ;
   NumPointsToCopy : Integer ;
   dt1 : Double ;
begin
     Result := False ;
    if not DeviceInitialised then DD_InitialiseBoard ;
    if not DeviceInitialised then Exit ;

    NumPointsToCopy := NumDACPoints*NumDACChannels ;

    { Copy D/A values into output buffer }
    if DigitalOutputRequired then begin
       // Digital bits already in lower 4 bits of DAC word
       for i := 0 to Min(NumPointsToCopy,ADCBufSize)-1 do
           DACBuf^[i] := (DACValues[i] shl 4) or (DACBuf^[i] and $F) ;
       end
    else begin
       for i := 0 to Min(NumPointsToCopy,ADCBufSize)-1 do
           DACBuf^[i] := (DACValues[i] shl 4) or (DefaultDigValue and $F) ;
        end ;
    DigitalOutputRequired := False ;

    // Fill up to end of buffer with last points in D/A channels
    i0 := (NumDACPoints-1)*NumDACChannels ;
    i := i0 + NumDACChannels ;
    ch := 0 ;
    while i < Min(NumADCChannels*NumADCPoints,ADCBufSize) do begin
        DACBuf^[i] :=  DACBuf^[i0+ch] ;
        Inc(ch) ;
        if ch >= NumDACChannels then ch := 0 ;
        Inc(i) ;
        end ;

    { Set up D/A subsystem to output this waveform }

    { *NOTE* DMA channel must be disabled BEFORE D/A FIFO is reset
             to avoid intermittent problems with initiating D/A sweep.
             Don't know why this is necessary 21/5/97 J.D. }
    DD_DisableDMAChannel( DACDMAChannel ) ;

    { Clear D/A FIFO buffer }
    SetPortWord( DevH, IOPorts.Reset, RESETDACFLAGS {or $229} ) ;

    // Synchronous digital output (from lower 4 bits of DAC word)
    SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

    { Disable DACs 0 and 1 }
    ClearBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
    { Note ... this disabling step seems to be necessary to make the
      D/A subsystem start reliably when repeating initiated }

    { Enable DAC channel 0 }
    SetPortWord( DevH, IOPorts.Control, ControlWord ) ;
    ControlWord := ControlWord or DACCHAN0ENABLE ;
    SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

    { Enable DAC channel 1 (if in use }
    if NumDACChannels > 1 then  begin
       ControlWord := ControlWord or DACCHAN1ENABLE ;
       SetPortWord( DevH, IOPorts.Control, ControlWord ) ;
       end ;

    { NOTE ... The above two stage enabling of DACs 0 and 1 ensure that
      the DACs take their data from in the DAC FIFO in the order 0,1,0,1...}

    { Set DACs to initial values }
    SetPortWord( DevH, IOPorts.DACData, DACBuf^[0] ) ;
    if NumDACChannels > 1 then SetPortWord( DevH, IOPorts.DACData, DACBuf^[1] ) ;

    // Clear asynchronous A/D & D/A timing bit
    // (A/D and D/A both timed by Counter 2)
    ClearBits( ControlWord, ADCASYNCDAC ) ;
    SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

    //outputdebugString(PChar(format('%d %d %d',[NumDACPoints,DACBuf^[i],DACBuf^[i+1]]))) ;
    { Enable DMA controller to transfer D/A values to Digidata 1200 }
    NumBytesToTransfer := Min(NumADCChannels*NumADCPoints,ADCBufSize)*2  ;
    DD_DisableDMAChannel( DACDMACHannel ) ;
    DD_ProgramDMAChannel( DACDMAChannel,
                          DACDMABufReq,
                          DMAReadFromMemory,
                          NumBytesToTransfer,
                          False ) ;

    if ExternalTrigger then begin
       { External DAC start trigger mode }

       // Called to ensure Clock 3 is programmed
       dt1 := ADCSamplingInterval / NumADCChannels ;
       DD_SetADCClock( dt1, ExternalTrigger ) ;
       ADCSamplingInterval := dt1 * NumADCChannels ;

       SetPortWord( DevH, IOPorts.TimerControl, LOADCOUNT or COUNTER2 ) ;
       SetPortWord( DevH, IOPorts.TimerControl, ARM or COUNTER2 ) ;
       { Enable split-clock mode (bit5) which connects OUT 3 to GATE 2 }
       SetBits( ControlWord, ADCSPLITCLOCKENABLE ) ;
       SetPortWord( DevH, IOPorts.Control, ControlWord ) ;
       SetPortWord( DevH, IOPorts.TimerControl, ARM or COUNTER3 ) ;
       end
    else begin
       { Start A/D + D/A clock (COUNTER2) }
       SetPortWord( DevH, IOPorts.TimerControl, ARM or COUNTER2 ) ;
       end ;

    DACActive := True ;
    Result := DACActive ;

    end ;


procedure DD_SetDACClock(
          dt : single ;
          nChannels : Integer
          ) ;
{ ----------------------------------------
  Set D/A output clock
  Enter with : dt = D/A update interval (s)
  ----------------------------------------}
var
   Ticks : Cardinal ;
   FrequencySource,ModeBits : Word ;
   dt1 : Double ;
begin
     { D/A outputs are timed using a 16 bit counter fed via dividers
      from a 0.25us clock. (The digidata 1200's 9513A time channel No.1 is used) }
     dt1 := dt / (nChannels) ;
     DD_CheckSamplingInterval( dt1, Ticks, FrequencySource ) ;

     { Set counter No. 1 mode register to:- repeated counts,
       frequency source period, ACTIVE-HIGH terminal count toggled On/Off pulse }

     ModeBits := (FrequencySource + $A)*$100 or REPEAT_COUNT or ACTIVE_HIGH_TC ;
     SetPortWord( DevH, IOPorts.TimerControl, MODE_REG or CTR1_GRP ) ;
     SetPortWord( DevH, IOPorts.TimerData, ModeBits ) ;
     SetPortWord( DevH, IOPorts.TimerControl, LOAD_REG or CTR1_GRP ) ;
     SetPortWord( DevH, IOPorts.TimerData, Ticks ) ;

     {Note clock does not start yet, ARM command needed }
     end ;


function DD_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin
     Result := False ;
     if not DeviceInitialised then DD_InitialiseBoard ;
     if not DeviceInitialised then Exit ;

     { Disable DACs 0 and 1 }
     ClearBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     { Stop COUNTER 2 which times A/D & D/A updates }
     SetPortWord( DevH, IOPorts.TimerControl, DISARM or COUNTER2 ) ;
     SetPortWord( DevH, IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;

     // Disconnect D/A update timing from A/D
     SetBits( ControlWord, ADCASYNCDAC ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     { Disable DMA controller }
     DD_DisableDMAChannel( DACDMAChannel ) ;

     // Clear D/A FIFO buffer }
     SetPortWord( DevH, IOPorts.Reset, RESETDACFLAGS {and $300} ) ;

     DACActive := False ;
     Result := DACActive ;

     end ;


function DD_ReadADC(
         Chan : Integer ;
         ADCVoltageRange : Single
         ) : SmallInt  ;
// --------------------------------
// Read selected A/D input channel
// --------------------------------
var
   i,OutPointer : Integer ;
   ADC : Array[0..MaxChannel] of SmallInt ;
   SamplingInterval : Double ;
begin
     Result := 0 ;
     if not DeviceInitialised then DD_InitialiseBoard ;
     if not DeviceInitialised then Exit ;
     if Chan > MaxChannel then Exit ;

     // Stop A/D conversions
     DD_StopADC ;

     // Keep within valid limits
     if Chan < 0 then Chan := 0 ;
     if Chan > MaxChannel then Chan := MaxChannel ;

     // Fill buffer with empty flags
     for i := 0 to MaxChannel do ADC[i] := EmptyFlag ;

     // Sample all channels as fast as possible
     SamplingInterval := 1E-5*(MaxChannel+1) ;
     DD_ADCToMemory( ADC,
                     MaxChannel+1,
                     1,
                     SamplingInterval,
                     ADCVoltageRange,
                     tmFreeRun,
                     False ) ;

     // Loop until all samples acquired
     while ADC[MaxChannel] = EmptyFlag do DD_GetADCSamples( ADC, OutPointer ) ;

     // Stop A/D conversions
     DD_StopADC ;

     // Return result
     Result := ADC[Chan] ;

     end ;


procedure DD_WriteDACsAndDigitalPort(
          var DACVolts : array of Single ;
          nChannels : Integer ;
          DigValue : SmallInt
          ) ;
{ ----------------------------------------------------
  Update D/A outputs with voltages suppled in DACVolts
  ----------------------------------------------------}
const
     MaxDACValue = 32767 ;
     MinDACValue = -32768 ;
var
   DACScale : single ;
   DACBuf : Array[0..1] of Integer ;
begin

     if not DeviceInitialised then DD_InitialiseBoard ;
     if not DeviceInitialised then Exit ;
     nChannels := Min(nChannels,2) ;

     DACScale := MaxDACValue/DACVoltageRangeMax ;

     { D/A 0 }
     DACBuf[0] := Round(DACVolts[0]*DACScale)  ;
     if DACBuf[0] > MaxDACValue then DACBuf[0] := MaxDACValue ;
     if DACBuf[0] < MinDACValue then DACBuf[0] := MinDACValue ;
     DACBuf[0] := (DACBuf[0] and $FFF0) or (DigValue and $F) ;

     { D/A 1 }
     if nChannels > 1 then begin
        DACBuf[1] := Round(DACVolts[1]*DACScale) ;
        if DACBuf[1] > MaxDACValue then DACBuf[1] := MaxDACValue ;
        if DACBuf[1] < MinDACValue then DACBuf[1] := MinDACValue ;
        DACBuf[1] := (DACBuf[1] and $FFF0) or (DigValue and $F) ;
        end ;

     { Keep dig. value for use by DD_MemoryToDAC }
     DefaultDigValue := DigValue ;

     { Stop any D/A activity }
     DD_StopDAC ;

     { Disable DAC channels }
     { Clear D/A FIFO buffer }
     SetPortWord( DevH, IOPorts.Reset, RESETDACFLAGS {or $229} ) ;

     ClearBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     { Enable DAC 0 }
     SetBits( ControlWord, DACCHAN0ENABLE ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     { Enable DAC 1 (if needed) }
     if nChannels > 1 then begin
        SetBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
        SetPortWord( DevH, IOPorts.Control, ControlWord ) ;
        end ;

        { NOTE ... Enabling the DACs in the order DAC0 then DAC1
          results in the DACs being written to in the order 0,1,0,1...
          see page 27 Digidata 1200 manual }

     { Make digital O/P synchronous with D/A output }
     ClearBits( ControlWord, ASYNCHDIGITALENABLE ) ;
     SetPortWord( DevH, IOPorts.Control, ControlWord ) ;

     { Write to DAC 0 }
     SetPortWord( DevH, IOPorts.DACData, DACBuf[0] ) ;
     { Write to DAC 1 }
     if nChannels > 1 then SetPortWord( DevH, IOPorts.DACData, DACBuf[1] ) ;
        //outputdebugString(PChar(format('%d %d',[DACBuf[0],DACBuf[1]]))) ;

     end ;


procedure DD_ConvertToDACCodes(
          var DACBuf : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer
          ) ;
{ ---------------------------------------------------------------------
  Convert D/A output integers (in -2048 .. 2047 range) to Digidata 1200
  DAC Code (located in upper 12 bits of 16 bit word
  ---------------------------------------------------------------------}
var
   i,iEnd : Integer ;
begin
     iEnd := (nChannels*nPoints)-1 ;
     for i := 0 to iEnd do DACBuf[i] := DACBuf[i] {shl 4} ;
     end ;


procedure DD_AddDigitalWaveformToDACBuf(
          var DigBuf : Array of SmallInt  ;
          nChannels : Integer ;
          nPoints : Integer
          ) ;
{ ------------------------------------------------------------------------
  Digital outputs 0,1,2,3 are derived from lower 4 bits of DAC word.
  This routine inserts lower 4 bits of digital output words (from DigBuf)
  into D/A output array (DACBuf)
  Enter with :
  DigBuf : Containing digital output values (4 lower bits of word)
  nChannels : No of D/A channels
  nPoints : No. of output values
  ------------------------------------------------------------------------}
var
   i,j : Integer ;
   LoNibble : Integer ;
begin
     j := 0 ;
     for i := 0 to nPoints-1 do begin
         if j >= dd1200_ADCBufferLimit then Break ;
         LoNibble := DigBuf[i] and $F ;
         DACBuf^[j] := LoNibble ;
         Inc(j) ;
         if nChannels > 1 then begin
            DACBuf^[j] := LoNibble ; //(DigBuf[i] shr 4) and $f ;
            Inc(j) ;
            end ;
         end ;
     DigitalOutputRequired := True ;
     end ;


function DD_ReadDigitalInputPort : Integer ;
// ---------------------
// Read digital I/P port
// ---------------------
var
     BitPattern : Word ;
begin

     Result := 0 ;
     if not DeviceInitialised then Exit ;

     BitPattern := GetPortWord( DevH, IOPorts.DigitalIO ) ;

     Result := BitPattern ;
     end ;


procedure DD_GetChannelOffsets(
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


procedure DD_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
begin

     if DACActive then DD_StopDAC ;
     if ADCActive then DD_StopADC ;

     { Release DMA buffers within driver }
     FreeDMABuffer( DevH, @ADCDMABufReq ) ;
     FreeDMABuffer( DevH, @DACDMABufReq ) ;

     // Close device driver
     CloseTVicHW32( DevH ) ;

     // Free DLL library
     if LibHandle <> 0 then FreeLibrary( LibHandle ) ;

     DeviceInitialised := False ;
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

procedure DD_ProgramDMAChannel( DMAChannel : Integer ;
                                DMABufReq : TDMABufferRequest ;
                                DMADirection : Integer ;
                                nBytes : LongInt ;
                                AutoInitialise : boolean ) ;
{ ----------------------------
  Program selected DMA channel
  ----------------------------}
type
    TDMA = record
         Page : Cardinal ;
         FlipFlop : Cardinal ;
         Address : Cardinal ;
         Count : Cardinal ;
         Mode : Cardinal ;
         Status : Cardinal ;
         Mask : Cardinal ;
         end ;
var
   DMA : TDMA ;
   ReadMode,WriteMode,ReadModeAutoInit,WriteModeAutoInit : Word ;
   WordAddress,NumWords,Page,Page1,Offset : Cardinal ;
begin

     { Set up appropriate port addresses and modes for selected DMA channel }

     case DMAChannel of
          5 : begin
              DMA.Page := DMA5_PAGE ;
              DMA.Mode := DMA_MODE ;
              DMA.FlipFlop := DMA_FLIPFLOP ;
              DMA.Address := DMA5_ADDRESS ;
              DMA.Count := DMA5_COUNT ;
              DMA.Status := DMA_STATUS ;
              DMA.Mask := DMA_MASK ;
              ReadMode := CH5_READMODE ;
              WriteMode := CH5_WRITEMODE ;
              ReadModeAutoInit := CH5_READMODEA ;
              WriteModeAutoInit := CH5_WRITEMODEA ;
              end ;

          6 : begin
              DMA.Page := DMA6_PAGE ;
              DMA.Mode := DMA_MODE ;
              DMA.FlipFlop := DMA_FLIPFLOP ;
              DMA.Address := DMA6_ADDRESS ;
              DMA.Count := DMA6_COUNT ;
              DMA.Status := DMA_STATUS ;
              DMA.Mask := DMA_MASK ;
              ReadMode := CH6_READMODE ;
              WriteMode := CH6_WRITEMODE ;
              ReadModeAutoInit := CH6_READMODEA ;
              WriteModeAutoInit := CH6_WRITEMODEA ;
              end ;

          else begin
              DMA.Page := DMA7_PAGE ;
              DMA.Mode := DMA_MODE ;
              DMA.FlipFlop := DMA_FLIPFLOP ;
              DMA.Address := DMA7_ADDRESS ;
              DMA.Count := DMA7_COUNT ;
              DMA.Status := DMA_STATUS ;
              DMA.Mask := DMA_MASK ;
              ReadMode := CH7_READMODE ;
              WriteMode := CH7_WRITEMODE ;
              ReadModeAutoInit := CH7_READMODEA ;
              WriteModeAutoInit := CH7_WRITEMODEA ;
              end ;

          end ;

     { Disable channel on DMA controller }
     DD_DisableDMAChannel( DMAChannel ) ;

     case DMADirection of
          DMAWriteToMemory : begin
             if AutoInitialise then SetPortByte( DevH, DMA.Mode,WriteModeAutoInit )
                               else SetPortByte( DevH, DMA.Mode,WriteMode ) ;
             end ;
          DMAReadFromMemory : begin
             if AutoInitialise then SetPortByte( DevH, DMA.Mode,ReadModeAutoInit )
                               else SetPortByte( DevH, DMA.Mode,ReadMode ) ;
             end ;
          end ;



     { Calculate word address for DMA controller }
     WordAddress := DMABufReq.PhysDmaAddress div 2 ;
     Page := WordAddress div $10000 ;
     Page1 := (WordAddress + (nBytes div 2) - 1) div $10000 ;
     if Page1 <> Page then begin
        ShowMessage('DMA Aborted! DMA Buffer spans 128Kb page boundary.') ;
        Exit ;
        end ;
     Offset := WordAddress - Page*$10000 ;
     Page := Page*2 ;

     { Write start address of DMA buffer (page:offset) to DMA controller }
     SetPortByte( DevH, DMA.Page, Page ) ;               { Write DMA page }
     SetPortByte( DevH, DMA.FlipFlop,1 ) ;               { Reset byte flip-flop }
     SetPortByte( DevH, DMA.Address, Offset ) ;          { Address (lo byte) }
     SetPortByte( DevH, DMA.Address, Offset div $100 ) ; {Address (hi byte)

     { Write no. of word to be transferred to controller
       (NOTE ... transferred as 16 bit word, NumWord-1 written to register }
     NumWords := (nBytes div 2) - 1 ;
     SetPortByte( DevH, DMA.FlipFlop,1 ) ; { Reset byte flip-flop }
     SetPortByte( DevH, DMA.Count, NumWords ) ;
     SetPortByte( DevH, DMA.Count, NumWords div $100 ) ;

     { Enable channel on DMA controller }
     DD_EnableDMAChannel( DMAChannel ) ;

     end ;


procedure DD_DisableDMAChannel( DMAChannel : Integer ) ;
{ -------------------
  Disable DMA channel
  -------------------}
begin
     case DMAChannel of
          5 : SetPortByte( DevH, DMA_MASK, CH5_OFF ) ;
          6 : SetPortByte( DevH, DMA_MASK, CH6_OFF ) ;
          7 : SetPortByte( DevH, DMA_MASK, CH7_OFF ) ;
          end ;
     end ;


procedure DD_EnableDMAChannel( DMAChannel : Integer ) ;
{ -------------------
  Enable DMA channel
  -------------------}
begin
     case DMAChannel of
          5 : SetPortByte( DevH, DMA_MASK, CH5_ON ) ;
          6 : SetPortByte( DevH, DMA_MASK, CH6_ON ) ;
          7 : SetPortByte( DevH, DMA_MASK, CH7_ON ) ;
          end ;
     end ;


initialization
    LibHandle := 0 ;
    LibraryLoaded := False ;
    DeviceInitialised := False ;
    IOPorts.Base := $320 ;
    ADCSweepDone := False ;
    ADCActive := False ;
    DefaultDigValue := 0 ;
    DigitalOutputRequired := False ;
    EmptyFlag := 32767 ;
end.
