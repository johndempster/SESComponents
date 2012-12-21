unit Dd1200Win98;
{ =================================================================
  WinWCP -Axon Instruments Digidata 1200 Interface Library
  WINDOWS 98, 95, ME Version
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
  =================================================================}

interface

uses WinTypes,Dialogs, SysUtils, WinProcs,
     winrt, winrtdriver, winrtctl, winrtdimitem,mmsystem;
const
     ADCBufSize = 32768 ;
     // Max. no. of samples allowed
     // (limited by DMA buffer in WinRT driver)
     dd1200_ADCBufferLimit = 30208 ;

type
    TADCBuf = Array[0..ADCBufSize] of SmallInt ;
    PADCBuf = ^TADCBuf ;

  procedure DD98_InitialiseBoard ;
  procedure DD98_ConfigureHardware( EmptyFlagIn : Integer ) ;

  function  DD98_ADCToMemory(
            var HostADCBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nSamples : Integer ;
            var dt : Double ;
            ADCVoltageRange : Single ;
            TriggerMode : Integer ;
            CircularBuffer : Boolean
            ) : Boolean ;
  function DD98_StopADC : Boolean ;
  procedure DD98_GetADCSamples (
            var OutBuf : Array of SmallInt ;
            var OutBufPointer : Integer
            ) ;
  procedure DD98_SetADCClock(
            dt : Double ;
            WaitForExtTrigger : Boolean
            ) ;
  procedure DD98_CheckSamplingInterval(
            var SamplingInterval : Double ;
            var Ticks : Cardinal ;
            var FrequencySource : Word
            ) ;

function  DD98_MemoryToDAC(
          var DACValues : Array of SmallInt  ; // D/A values to be output
          NumDACChannels : Integer ;           // No. D/A channels
          NumDACPoints : Integer ;             // No. points per channel
          ExternalTrigger : Boolean ;          // External start of D/A sweep
          var ADCSamplingInterval : Double ;   // A/D sampling interval (s)
          NumADCChannels : Integer ;            // No. A/D channels
          NumADCPoints : Integer
          ) : Boolean ;

  procedure DD98_ConvertToDACCodes(
            var DACBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nPoints : Integer
            ) ;
  procedure DD98_SetDACClock(
            dt : single ; nChannels : Integer
            ) ;
  function DD98_StopDAC : Boolean ;

  function DD98_ReadADC( Chan : Integer ; ADCVoltageRange : Single ) : SmallInt ;

  procedure DD98_WriteDACsAndDigitalPort(
            var DACVolts : array of Single ;
            nChannels : Integer ;
            DigValue : SmallInt
            ) ;
  procedure DD98_AddDigitalWaveformToDACBuf(
            var DigBuf : Array of SmallInt  ;
            nChannels : Integer ;
            nPoints : Integer
            ) ;

  function DD98_ReadDigitalInputPort : Integer ;

  function  DD98_GetLabInterfaceInfo(
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


  function DD98_GetMaxDACVolts : single ;
  procedure DD98_GetChannelOffsets(
            var Offsets : Array of Integer ;
            NumChannels : Integer
            ) ;
  procedure DD98_CloseLaboratoryInterface ;


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

type

    TDD1200Registers = record
           Base : Word ;
           DACData : Word ;
           ADCData: Word ;
           ID : Word ;
           TimerData : Word ;
           TimerControl : Word ;
           Control : Word ;
           DMAConfig : Word ;
           DigitalIO : Word ;
           ADCScanList : Word ;
           T8254Channel0 : Word ;
           T8254Channel1 : Word ;
           T8254Channel2 : Word ;
           T8254Control : Word ;
           Status : Word ;
           Reset : Word ;
           end ;

var
   ADCSingleDev : tWinRT ; { Win RT device for single A/D sweep }
   ADCCyclicDev : tWinRT ; { Win RT device for cyclic A/D sweep }

   ADCDev : tWinrt;        { Win RT A/D device in use }
   DACDev : tWinrt ;       { Win RT object for D/A output }

   ADCDMASingleInfo : tWinRT_DMA_BUFFER_INFORMATION ;
   ADCDMACyclicInfo : tWinRT_DMA_BUFFER_INFORMATION ;
   DACDMAInfo : tWinRT_DMA_BUFFER_INFORMATION ;

   WinRTConfig : tWINRT_FULL_CONFIGURATION ;

   FADCVoltageRangeMax : single ;  { Max. positive A/D input voltage range}
   FADCMinValue : Integer ;
   FADCMaxValue : Integer ;
   FDACMinUpdateInterval : Double ;
   MaxDACBufPoints : Integer ;
   FADCMinSamplingInterval : single ;
   FADCMaxSamplingInterval : single ;

   FADCBufferLimit : Integer ;    { Upper limit (samples) of A/D buffer }

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

function  DD98_GetLabInterfaceInfo(
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

     if not DeviceInitialised then DD98_InitialiseBoard ;

     { Get type of Digidata 1200 }
     if DeviceInitialised then begin
        with ADCDev do begin
             clear();
             Inp([rtfword],IOPorts.ID,DeviceType) ;
             DeclEnd;
             ProcessBuffer;
             end ;

        DeviceType := DeviceType  and $3 ;
        case DeviceType of
          2 : Model := 'Digidata 1200 ' ;
          3 : Model := 'Digidata 1200A ' ;
          else Model := 'Digidata 1200? ' ;
          end ;

        { Get I/O port settings }

        Model := Model + format('IO=%xh DMA=5,7',
                                [WinRTConfig.PortStart[0]
                                 ]) ;

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

       DACMinUpdateInterval := 1E-5 ;
       FDACMinUpdateInterval := DACMinUpdateInterval ;

       ADCMinSamplingInterval := 3.5E-6 ;
       ADCMaxSamplingInterval := 1000. ;
       FADCMinSamplingInterval := ADCMinSamplingInterval ;
       FADCMaxSamplingInterval := ADCMaxSamplingInterval ;

       ADCBufferLimit := dd1200_ADCBufferLimit ;
       end ;

     Result := DeviceInitialised ;

     end ;


function  DD98_GetMaxDACVolts : single ;
{ -----------------------------------------------------------------
  Return the maximum positive value of the D/A output voltage range
  -----------------------------------------------------------------}

begin
     Result := DACVoltageRangeMax ;
     end ;


procedure DD98_InitialiseBoard ;
{ -------------------------------------------
  Initialise Digidata 1200 interface hardware
  -------------------------------------------}
var
   Length : INteger ;
   Value : Word ;
   LenDMAInfo : Integer ;
   OK : Boolean ;
begin
     DeviceInitialised := False ;

     { Define Digidata 1200 I/O port addresses }
     IOPorts.Base := 0 ;
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


     { Open Digidata 1200 D/A converter I/O port driver }
     OK := True ;
     DACDev := Nil ;
     try
        DACDev := tWinrt.create(0, FALSE);
     except
        MessageDlg( 'Unable to find Digidata 1200 driver! ',mtWarning, [mbOK], 0 ) ;
        OK := False ;
        end ;

     { Set up single sweep D/A output DMA buffer }
     if OK then begin
        if WinRTSetupDMABuffer( DACDev.Handle, DACDMAInfo, LenDMAInfo ) then begin
           DACBuf := PADCBuf(DACDMAInfo.pVirtualAddress) ;
           MaxDACBufPoints := DACDMAInfo.Length div 2 ;
           end
        else begin
           MessageDlg( 'ERROR! Cannot open DAC DMA buffer',mtWarning, [mbOK], 0 ) ;
           OK := False ;
           end ;
        end ;

     { Open Digidata 1200 single sweep A/D converter I/O port driver }
     if OK then begin
        try
           ADCSingleDev := Nil ;
           ADCSingleDev := tWinrt.create(1, FALSE);
        except
           MessageDlg( 'ERROR! Cannot open ADC DMA Device!',mtWarning, [mbOK], 0 ) ;
           OK := False ;
           end ;
        end ;

     if OK then begin
        { Set up A/D input DMA buffer }
        if WinRTSetupDMABuffer(ADCSingleDev.Handle,ADCDMASingleInfo,LenDMAInfo) then
           ADCBuf := PADCBuf(ADCDMASingleInfo.pVirtualAddress)
        else begin
           MessageDlg( 'ERROR! Cannot open ADC DMA buffer',mtWarning, [mbOK], 0 ) ;
           OK := False ;
           end ;
        end ;

     { Open Digidata 1200 cyclic A/D converter I/O port driver }
     if OK then begin
        try
           ADCCyclicDev := Nil ;
           ADCCyclicDev := tWinrt.create(2, FALSE);
        except
           MessageDlg( 'ERROR! Cannot open cyclic ADC DMA Device!',mtWarning, [mbOK], 0 ) ;
           OK := False ;
           end ;
        end ;

     if OK then begin
        { Set up A/D input DMA buffer }
        if WinRTSetupDMABuffer( ADCCyclicDev.Handle, ADCDMACyclicInfo, LenDMAInfo ) then begin
           ADCBuf := PADCBuf(ADCDMACyclicInfo.pVirtualAddress) ;
           FADCBufferLimit := (ADCDMACyclicInfo.Length div 2) ;
           end
        else begin
           MessageDlg( 'ERROR! Cannot open Cyclic ADC DMA buffer',mtWarning, [mbOK], 0 ) ;
           OK := False ;
           end ;
        end ;

     if OK then begin
        { Select single sweep A/D as default }
        ADCDev := ADCSingleDev ;
        ADCBuf := PADCBuf(ADCDMASingleInfo.pVirtualAddress) ;
        CyclicADCBuffer := False ;

        { Get I/O port settings }
        WinRTGetFullConfiguration( ADCDev.Handle, WinRTConfig, Length ) ;

        { Send initialisation data to Digidata 1200 }
        with ADCDev do begin
             clear();
             outp([rtfword],IOPorts.Reset, RESETWHOLEBOARD );

             { Set up the 9513 timer chip: master reset. Do I/O in 8-bit mode.
             then set to 16-bit mode. }
             Outp( [],IOPorts.TimerControl, MASTERRESET ) ;
             Outp( [],IOPorts.TimerControl, SET16BITMODE ) ;

             { Point the Data Pointer register at the Master Mode register. }
             Outp([rtfword],IOPorts.TimerControl, MASTERMODE ) ;

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
             Outp([rtfword],IOPorts.TimerData, Value ) ;

             { Enable A/D sampling transfer using DMA channels 5 for A/D and 7 for D/A }
             ConfigWord := DMACHANNEL5 or (DMACHANNEL7*DMADACSHIFT) or ADCSINGLEDMA ;
             Outp( [rtfword], IOPorts.DMAConfig, ConfigWord ) ;

             { Enable D/A 0 and use COUNTER 1 to control it
      	     (Note the use of the variable "ControlWord" to keep the port settings }
             ControlWord := ADCASYNCDAC or DACCHAN0ENABLE ;
  	         Outp([rtfword], IOPorts.Control, ControlWord ) ;

             { Clear D/A outputs }
	           Outp([rtfword], IOPorts.DACData, 0 ) ;

             DeclEnd;
             ProcessBuffer;
             end ;

        DACActive := False ;
        DeviceInitialised := True ;

        end ;
     end ;


procedure DD98_ConfigureHardware(
          EmptyFlagIn : Integer ) ;
{ --------------------------------------------------------------------------
  Configure A/D empty flag
  -------------------------------------------------------------------------- }
begin
     EmptyFlag := EmptyFlagIn ;
     end ;


function DD98_ADCToMemory(
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

     if not DeviceInitialised then DD98_InitialiseBoard ;

     { Disable A/D converter and DMA channel }
     with ADCDev do begin
        clear();

        { Stop COUNTER 2 which times A/D & D/A sampling }
        Outp( [rtfword], IOPorts.TimerControl, DISARM or COUNTER2 ) ;
        Outp( [rtfword], IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;
        { Disable DMA controller }
        DMAFlush ;
        DeclEnd;
        ProcessBuffer;
	      end ;

     { Select type of recording
       Single sweep = A/D samping terminates when buffer is full
       Cyclic = A/D sampling continues at beginning when buffer is full }

     if CircularBuffer then begin
        ADCDev := ADCCyclicDev ;
        ADCBuf := PADCBuf(ADCDMACyclicInfo.pVirtualAddress) ;
        CyclicADCBuffer := True ;
        end
     else begin
        ADCDev := ADCSingleDev ;
        ADCBuf := PADCBuf(ADCDMASingleInfo.pVirtualAddress) ;
        CyclicADCBuffer := False ;
        end ;

     { Inter-sample interval is channel group sampling interval
       divided by number of channels in group. Note that DT1 and DT
       are modified after SET_ADC_CLOCK_DIGIDATA to be precisely equal to an
       interval supported by the interface. }

     if TriggerMode = tmExtTrigger then WaitForExtTrigger := True
                                   else WaitForExtTrigger := False ;
     dt1 := dt / nChannels ;
     DD98_SetADCClock( dt1, WaitForExtTrigger ) ;
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

     with ADCDev do begin
        clear();

        { Program channel gain/select list }

        SetBits( ControlWord, ADCSCANLISTENABLE ) ;
        outp([rtfword], IOPorts.Control, ControlWord ) ;

        for ch := 0 to nChannels-1 do begin
            ChannelBits := ch or ($100*ch) or (GainBits*$2000) ;
            if ch = (nChannels-1) then ChannelBits := ChannelBits or $8000 ;
            outp( [rtfword], IOPorts.ADCScanList, ChannelBits ) ;
            end ;

        // Clear asynchronous A/D & D/A timing bit
        // (A/D and D/A both timed by Counter 2)
        SetBits( ControlWord, ADCASYNCDAC ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

        ClearBits( ControlWord, ADCSCANLISTENABLE ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

        { Reset A/D FIFO & scan list pointer (bit 4)
          9513 DONE3 flag (bit 1) }
        Outp( [rtfword],IOPorts.Reset, RESET_SCAN_LIST ) ;

        { Enable DMA controller, ready for samples when they appear }
        NumBytesToTransfer := nChannels*nSamples*2 ;
        DMAStart( false, NumBytesToTransfer ) ;

        { Wait for external trigger pulse into GATE 3 }
        if WaitForExtTrigger then begin
           { External trigger mode }
	         Outp( [rtfword], IOPorts.TimerControl, LOADCOUNT or COUNTER2 ) ;
	         Outp( [rtfword], IOPorts.TimerControl, ARM or COUNTER2 ) ;

           { Enable split-clock mode (bit5) which connects OUT 3 to GATE 2 }
           SetBits( ControlWord, ADCSPLITCLOCKENABLE ) ;
	         Outp( [rtfword], IOPorts.Control, ControlWord ) ;
 	         Outp( [rtfword], IOPorts.TimerControl, ARM or COUNTER3 ) ;
           end
        else begin
           { Free run & waveform generation mode }
	         ClearBits( ControlWord, ADCSPLITCLOCKENABLE ) ;
	         Outp( [rtfword], IOPorts.Control, ControlWord ) ;
           // Start A/D conversion if in free run mode
           // (otherwise A/D+D/A conversion started by DD98_MemoryToDac)
           if TriggerMode = tmFreeRun then begin
              Outp( [rtfword], IOPorts.TimerControl, ARM or COUNTER2 ) ;
              end ;
           end ;

        // Update DD1200 driver
        DeclEnd;
        ProcessBuffer;

        end ;

     { Set flag indicating that ADC is running }
     ADCActive := True ;
     Result := ADCActive ;
     ADCSweepDone := False ;
     end ;


procedure DD98_SetADCClock(
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

     DD98_CheckSamplingInterval( dt, Ticks, FrequencySource ) ;

     { Program Digidata 1200 for A/D conversion }

     with ADCDev do begin
        clear();

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
	         Outp( [rtfword], IOPorts.TimerControl, DISARM or COUNTER3 ) ;
	         Outp( [rtfword], IOPorts.TimerControl, CLEAROUT or 3 ) ;

	         Mode3Bits := $B00 or TOGGLE or ACTIVE_HIGH_LEVEL_GATE ;
	         Outp( [rtfword], IOPorts.TimerControl, MODE_REG or CTR3_GRP ) ;
	         Outp( [rtfword], IOPorts.TimerData, Mode3Bits ) ;
	         Outp( [rtfword], IOPorts.TimerControl, LOAD_REG or CTR3_GRP ) ;
	         Outp( [rtfword], IOPorts.TimerData, 3 ) ;
	         Outp( [rtfword], IOPorts.TimerControl, LOADCOUNT or COUNTER3 ) ;

	         Mode2bits := Mode2bits or ACTIVE_HIGH_LEVEL_GATE ;
	         end ;

        { Set Counter 2's mode and load registers and initialise counter
         (If in External Trigger mode, gate Counter 2 with the GATE 2 input }

	      Outp( [rtfword], IOPorts.TimerControl, MODE_REG or CTR2_GRP ) ;
	      Outp( [rtfword], IOPorts.TimerData, Mode2bits ) ;
	      Outp( [rtfword], IOPorts.TimerControl, LOAD_REG or CTR2_GRP ) ;
	      Outp( [rtfword], IOPorts.TimerData, Ticks ) ;
	      Outp( [rtfword], IOPorts.TimerControl, LOADCOUNT or COUNTER2 ) ;

        DeclEnd;
        ProcessBuffer;
	      end ;

     end ;


function DD98_StopADC : Boolean ;  { Returns False indicating A/D stopped }
{ -------------------------------
  Reset A/D conversion sub-system
  -------------------------------}
begin

     if not DeviceInitialised then DD98_InitialiseBoard ;

     { Stop A/D conversions }

     with ADCDev do begin
        clear();
        { Stop COUNTER 2 which times A/D samples }
        Outp( [rtfword], IOPorts.TimerControl, DISARM or COUNTER2 ) ;
        Outp( [rtfword], IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;
        { Disable DMA controller }
        DMAFlush ;
        DeclEnd;
        ProcessBuffer;
	      end ;

     ADCActive := False ;
     Result := ADCActive ;

     end ;


procedure DD98_GetADCSamples(
          var OutBuf : Array of SmallInt ;  { Buffer to receive A/D samples }
          var OutBufPointer : Integer       { Latest sample pointer [OUT]}
          ) ;
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
     OutBufPointer := ADCPointer ;

     end ;


procedure DD98_CheckSamplingInterval(
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


function  DD98_MemoryToDAC(
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
   dt1 : Double ;
begin

    if not DeviceInitialised then DD98_InitialiseBoard ;

    { Copy D/A values into output buffer }
    if DigitalOutputRequired then begin
       // Digital bits already in lower 4 bits of DAC word
       for i := 0 to NumDACPoints*NumDACChannels-1 do
           DACBuf^[i] := (DACValues[i] shl 4) or (DACBuf^[i] and $F) ;
       end
    else begin
       for i := 0 to NumDACPoints*NumDACChannels-1 do
           DACBuf^[i] := (DACValues[i] shl 4) or (DefaultDigValue and $F) ;
        end ;
    DigitalOutputRequired := False ;

    // Fill up to end of buffer with last points in D/A channels
    i0 := (NumDACPoints-1)*NumDACChannels ;
    i := i0 + NumDACChannels ;
    ch := 0 ;
    while i < NumADCPoints*NumADCChannels do begin
        DACBuf^[i] :=  DACBuf^[i0+ch] ;
        Inc(ch) ;
        if ch >= NumDACChannels then ch := 0 ;
        Inc(i) ;
        end ;

    // Set both last points to D/A channel 0
    // NOTE. The last two D/A points in the DMA output buffer
    // intermittently get swapped over when the DMA sweep ends
    // BOTH channels are set to D/A 0 to ensure that at least this
    // is always correct.
    for i := (NumADCPoints*NumADCChannels) - NumDACChannels
             to (NumADCPoints*NumADCChannels) - 1 do DACBuf^[i] :=  DACBuf^[i0] ;

    { Set up D/A subsystem to output this waveform }
    with DACDev do begin
         clear();

         { *NOTE* DMA channel must be disabled BEFORE D/A FIFO is reset
             to avoid intermittent problems with initiating D/A sweep.
             Don't know why this is necessary 21/5/97 J.D. }
         DMAFlush ;

         { Clear D/A FIFO buffer }
         Outp( [rtfword], IOPorts.Reset, RESETDACFLAGS {or $229} ) ;

         // Synchronous digital output (from lower 4 bits of DAC word)
         Outp( [rtfword], IOPorts.Control, ControlWord ) ;

         { Disable DACs 0 and 1 }
         ClearBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
         { Note ... this disabling step seems to be necessary to make the
            D/A subsystem start reliably when repeating initiated }

         { Enable DAC channel 0 }
         Outp( [rtfword], IOPorts.Control, ControlWord ) ;
         ControlWord := ControlWord or DACCHAN0ENABLE ;
         Outp( [rtfword], IOPorts.Control, ControlWord ) ;
         { Enable DAC channel 1 (if in use }
         if NumDACChannels > 1 then  begin
             ControlWord := ControlWord or DACCHAN1ENABLE ;
             Outp( [rtfword], IOPorts.Control, ControlWord ) ;
             end ;

         { NOTE ... The above two stage enabling of DACs 0 and 1 ensure that
            the DACs take their data from in the DAC FIFO in the order 0,1,0,1...}

         { Set DACs to initial values }
         Outp( [rtfword], IOPorts.DACData, DACBuf^[0] ) ;
         if NumDACChannels > 1 then Outp( [rtfword], IOPorts.DACData, DACBuf^[1] ) ;

        // Clear asynchronous A/D & D/A timing bit
        // (A/D and D/A both timed by Counter 2)
        ClearBits( ControlWord, ADCASYNCDAC ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

         DeclEnd;
         ProcessBuffer;
         end ;

    //outputdebugString(PChar(format('%d %d %d',[NumDACPoints,DACBuf^[i],DACBuf^[i+1]]))) ;
    { Enable DMA controller to transfer D/A values to Digidata 1200 }
    NumBytesToTransfer := NumADCChannels*NumADCpoints*2  ;
    with DACDev do begin
         clear();
         DMAFlush ;
         DMAStart( True, NumBytesToTransfer ) ;
         DeclEnd;
         ProcessBuffer;
         end ;

    if ExternalTrigger then begin
       { External DAC start trigger mode }

       // Called to ensure Clock 3 is programmed
       dt1 := ADCSamplingInterval / NumADCChannels ;
       DD98_SetADCClock( dt1, ExternalTrigger ) ;
       ADCSamplingInterval := dt1 * NumADCChannels ;

       with ADCDev do begin
           clear();
	         Outp( [rtfword], IOPorts.TimerControl, LOADCOUNT or COUNTER2 ) ;
	         Outp( [rtfword], IOPorts.TimerControl, ARM or COUNTER2 ) ;
           { Enable split-clock mode (bit5) which connects OUT 3 to GATE 2 }
           SetBits( ControlWord, ADCSPLITCLOCKENABLE ) ;
	         Outp( [rtfword], IOPorts.Control, ControlWord ) ;
 	         Outp( [rtfword], IOPorts.TimerControl, ARM or COUNTER3 ) ;
           DeclEnd;
           ProcessBuffer;
           end ;
       end
    else begin
       { Start A/D + D/A clock (COUNTER2) }
       with ADCDev do begin
            clear();
            Outp( [rtfword], IOPorts.TimerControl, ARM or COUNTER2 ) ;
            DeclEnd;
            ProcessBuffer;
            end ;
       end ;

    DACActive := True ;
    Result := DACActive ;

    end ;


procedure DD98_SetDACClock(
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
     DD98_CheckSamplingInterval( dt1, Ticks, FrequencySource ) ;

     { Set counter No. 1 mode register to:- repeated counts,
       frequency source period, ACTIVE-HIGH terminal count toggled On/Off pulse }

     ModeBits := (FrequencySource + $A)*$100 or REPEAT_COUNT or ACTIVE_HIGH_TC ;
     with ADCDev do begin
        clear();
        Outp( [rtfword], IOPorts.TimerControl, MODE_REG or CTR1_GRP ) ;
        Outp( [rtfword], IOPorts.TimerData, ModeBits ) ;
        Outp( [rtfword], IOPorts.TimerControl, LOAD_REG or CTR1_GRP ) ;
        Outp( [rtfword], IOPorts.TimerData, Ticks ) ;
        DeclEnd;
        ProcessBuffer;
        end ;

     {Note clock does not start yet, ARM command needed }
     end ;


function DD98_StopDAC : Boolean ;
{ ---------------------------------
  Disable D/A conversion sub-system
  ---------------------------------}
begin

     if not DeviceInitialised then DD98_InitialiseBoard ;

         { Disable DACs 0 and 1 }
     with DACDev do begin
        clear();

        ClearBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;
        DeclEnd;
        ProcessBuffer;
        end ;

     with DACDev do begin
        clear();
        { Stop COUNTER 2 which times A/D & D/A updates }
        Outp( [rtfword], IOPorts.TimerControl, DISARM or COUNTER2 ) ;
        Outp( [rtfword], IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;

        // Disconnect D/A update timing from A/D
        SetBits( ControlWord, ADCASYNCDAC ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

        //Outp( [rtfword], IOPorts.TimerControl, CLEAROUT or COUNTER2 ) ;

        { Disable DMA controller }
        DMAFlush ;

        { Clear D/A FIFO buffer }
        Outp( [rtfword], IOPorts.Reset, RESETDACFLAGS {and $300} ) ;

        DeclEnd;
        ProcessBuffer;
        end ;

     DACActive := False ;
     Result := DACActive ;

     end ;


function DD98_ReadADC(
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

     if not DeviceInitialised then DD98_InitialiseBoard ;
 
     // Stop A/D conversions
     DD98_StopADC ;

     // Keep within valid limits
     if Chan < 0 then Chan := 0 ;
     if Chan > MaxChannel then Chan := MaxChannel ;

     // Fill buffer with empty flags
     for i := 0 to MaxChannel do ADC[i] := EmptyFlag ;

     // Sample all channels as fast as possible
     SamplingInterval := 1E-5*(MaxChannel+1) ;
     DD98_ADCToMemory( ADC,
                     MaxChannel+1,
                     1,
                     SamplingInterval,
                     ADCVoltageRange,
                     tmFreeRun,
                     False ) ;

     // Loop until all samples acquired
     while ADC[MaxChannel] = EmptyFlag do DD98_GetADCSamples( ADC, OutPointer ) ;

     // Return result
     Result := ADC[Chan] ;

     end ;


procedure DD98_WriteDACsAndDigitalPort(
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

     if not DeviceInitialised then DD98_InitialiseBoard ;

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

     { Keep dig. value for use by DD98_MemoryToDAC }
     DefaultDigValue := DigValue ;

     { Stop any D/A activity }
     DD98_StopDAC ;

     { Disable DAC channels }
     with ADCDev do begin
        clear();

        { Clear D/A FIFO buffer }
        Outp( [rtfword], IOPorts.Reset, RESETDACFLAGS {or $229} ) ;

        ClearBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

        { Enable DAC 0 }
        SetBits( ControlWord, DACCHAN0ENABLE ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

        { Enable DAC 1 (if needed) }
        if nChannels > 1 then begin
           SetBits( ControlWord, DACCHAN0ENABLE or DACCHAN1ENABLE ) ;
           Outp( [rtfword], IOPorts.Control, ControlWord ) ;
           end ;

        { NOTE ... Enabling the DACs in the order DAC0 then DAC1
          results in the DACs being written to in the order 0,1,0,1...
          see page 27 Digidata 1200 manual }

        { Make digital O/P synchronous with D/A output }
        ClearBits( ControlWord, ASYNCHDIGITALENABLE ) ;
        Outp( [rtfword], IOPorts.Control, ControlWord ) ;

        { Write to DAC 0 }
        Outp( [rtfword], IOPorts.DACData, DACBuf[0] ) ;
        { Write to DAC 1 }
        if nChannels > 1 then Outp( [rtfword], IOPorts.DACData, DACBuf[1] ) ;
        //outputdebugString(PChar(format('%d %d',[DACBuf[0],DACBuf[1]]))) ;
        DeclEnd;
        ProcessBuffer;
        end ;

     end ;


procedure DD98_ConvertToDACCodes(
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


procedure DD98_AddDigitalWaveformToDACBuf(
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
     for i := 0 to nPoints do begin
         LoNibble := DigBuf[i] and $F ;
         DACBuf^[j] := LoNibble ;
         Inc(j) ;
         if nChannels > 1 then begin
            DACBuf^[j] := LoNibble ;
            Inc(j) ;
            end ;
         end ;
     DigitalOutputRequired := True ;
     end ;


function DD98_ReadDigitalInputPort : Integer ;
// ---------------------
// Read digital I/P port
// ---------------------
var
     BitPattern : Word ;
begin

     Result := 0 ;
     if not DeviceInitialised then Exit ;

     BitPattern := 0 ;
     with ADCDev do begin
          clear();
          Inp([rtfword],IOPorts.DigitalIO,BitPattern) ;
          DeclEnd;
          ProcessBuffer;
          end ;

     Result := BitPattern ;
     end ;


procedure DD98_GetChannelOffsets(
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


procedure DD98_CloseLaboratoryInterface ;
{ -----------------------------------
  Shut down lab. interface operations
  ----------------------------------- }
var
   DMAInfoLen : Integer ;
begin

     if DACActive then DD98_StopDAC ;

     if ADCActive then DD98_StopADC ;

     { Release DMA buffer within driver and shut down Win RT devices }

     { A/D single sweep }
     if ADCSingleDev <> Nil then begin
        WinRTFreeDMABuffer( ADCSingleDev.Handle,ADCDMASingleInfo, DMAInfoLen ) ;
        ADCSingleDev.Destroy ;
        ADCSingleDev := Nil ;
        end ;

     { A/D cyclic }
     if ADCCyclicDev <> Nil then begin
        WinRTFreeDMABuffer( ADCCyclicDev.Handle, ADCDMACyclicInfo, DMAInfoLen ) ;
        ADCCyclicDev.Destroy ;
        ADCCyclicDev := Nil ;
        end ;

     { D/A  output }
     if DACDev <> Nil then begin
        WinRTFreeDMABuffer( DACDev.Handle, DACDMAInfo, DMAInfoLen ) ;
        DACDev.Destroy ;
        DACDev := Nil ;
        end ;

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


initialization
    DeviceInitialised := False ;
    IOPorts.Base := $320 ;
    ADCSweepDone := False ;
    ADCActive := False ;
    DefaultDigValue := 0 ;
    DigitalOutputRequired := False ;
    EmptyFlag := 32767 ;
end.
