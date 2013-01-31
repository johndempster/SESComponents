unit SESLabIO;
{ ================================================================================
  SESLabIO - Data Acquisition Component (c) J. Dempster, University of Strathclyde
  11/12/00 Digidata 132X interface support added
  19/02/01 ReadADC method now supported by all interfaces
  20/4/01  10V CED 1401 support removed
  11/10/01 Error which prevented selection of No Lab Interface (16 bit) option
           now fixed
  20/12/01 MinDACValue and MaxDACValue properties added to support cards such
           as the PCI-6035E which has 16 bit A/D but 12 bit D/A.
  17/3/02 .... Empty buffers now filled with pairs of positive/negative empty flags
               to avoid hang ups when buffer was filled with A/D values equal
               to empty flag.
  19/3/02 ... ITC16/18 support added
  15.7.02  Support for National Instruments E-Series digital outputs added (10 ms resolution)
           10 ms stimulus start timer now included within component
  17.7.02  DAC update interval now constrained to be 10ms when digitsl stimuli used
           with E-Series N.I. boards
  25.7.02  Support for ITC-16 and ITC-18 with old driver added
  25.11.02 Support from CED Micro1401 Mk2 added
           CED commands and DLL library now loaded from c:\1401 folder
  6/12/02 ... Changes to ITCMM support
  7/01/03 ... Support for each channel to have a different A/D voltage now added
              (currently for National Instruments interfaces only)
  30/1/03 ... Support for ITC-16 and ITC-18 using old (EPC-9 compatible) drivers added
  26/6/03 ... StartTimer now automatically stops/restarts existings timer
  03.02.04 .. Recording sweep trigger pulse can now be inverted (DACInvertTriggerLevel property)
  05.02.04 .. Stimulus output waveforms can now be triggered by a digital I/P pulse
              Bug in ReadADC (with National Instruments cards) corrected so that
              correct input voltage range is now used.
  16.02.04 .. Support for Biologic VP500 added
  25.03.04 .. StartTimer no longer waits for StimulusStarted to be cleared
              (fixes problem with WinEDR stimulus pulses)
  27.07.04 .. ADCExternalTriggerActiveHigh property added
  28.09.04  .. NI_ReadADC now works correctly when channel A/D voltages different
  25.10.04  .. CED 1401 ADC & DAC now synchronised internally
  11.11.04  .. NI A/D and D/A sweeps synchronised internally
  18.11.04  .. A/D & D/A Buffer sizes increased to 128 Kbyte
  07.03.05  .. DACRepeatWaveform property added
  14.04.05  .. National Instruments DAQmx support added
  21.07.05  .. A/D input mode (Differential, Single Ended) can now be set
  12.09.05  .. CED digital input read now works
  14.11.05  .. StartStimulus now works with all trigger modes (fixed problem with Chart)
  26.07.06 ... Original Win-RT driver now used again for Digidata 1200 support under Win 95/98/ME
               (unit = dd1200win98.pas)
  20.08.06 ... Stimulus timer tick counter now set to zero when stimulus repeat
               interval changed. This is ensures a full inter-record interval
               when stimulus protocol changes
  06.06.07 ... DACBufferLimit now varies depending on type of interface
               (set = ADCBufferLimit, except CED 1401)
  15.12.07 ... Support for Digidata 1440 added
  19.05.08 ... Support for Tecella Triton added
  02.0.08 .... .SetADCSamplingInterval bug with NIDAQ-MX cards which caused incorrect
               sampling interval to be set when large record sizes and short duration sweeps
               were selected fixed.
  19.08.08 ... .SetADCNumChannels & .SetADCSamplingInterval Error which lead to
               incorrect A/D sampling interval being reported (possibly introduced
               WinWCP V3.9.6-8) with NIDAQ-MX when sampling intervals shorter than
               board limits selected fixed.
  12.09.08 ... CED 1401 (10V added) interface option added
  12.05.10 ... Upper limit of A/D channels set to 128
  24.06.10 ... Lab. interface now opened using .OpenLabInterface
               and closed with .CloseLabInterface. National Instruments
               device # can now be selected
  25.06.10 ... Support for S series cards added (PCI-6110 etc.)
               DAC update rate now checked using NI_CheckDACUpdateInterval
  09.02.11 ... BUG FIX. Correct D/A voltage range now reported by .DACVoltageRange property
               (No longer reports A/D voltage range)
  02.03.11 ... DeviceExists() function added to check whether NI device hardware exist
  16/04/11 ... CED1401 support (CED1401.pas) bugs fixed (in Paris at ENP)
               DIGTIM command in Power 1401s now seems to operate in the same way as
               other 1401s, iDigShift now fixed at 0 in MemoryToDigital function
               LibrayLoaded flag now cleared by CED_CloseLaboratoryInterface
               when DLL library freed, preventing access violation when CED
               library loaded again.
  27/05/11 ... No. of A/D channels now set in .SetADCNumChannels
  08/06/11 ... DACHoldVoltage[chan] and DIGHoldingLevel properties added
  13/07/11 ... Special CED 1401 option CEDPOWER1401DIGSTIMOFFSET added to XML file
               For Power 1401s, determines whether
               No. of available A/D and D/A channel now returned by
               NIDAQMX_GetLabInterfaceInfo and CED_GetLabInterfaceInfo functions
  20/07/11 ... Stimulus Protocol execution list added
  19/08/11 ... SaveToXML() files can now be appended to existing files
  12/09/11 ... Stack overflow when ADCChannelInputNumber set fixed
               (caused by using ADCChannelInputNumber instead of FADCChannelInputNumber internally)
  15/09/11 ... FADCChannelYMin & FADCChannelYMax now initialised to min/max
               data range when lab. interface opened
  22/09/11 ... FADCVoltageRanges and FADCChannelVoltageRanges now stored in XML file
  30/09/11 ... OpenLabInterface() now closes interface before reopening to ensure
               .model is updated.
  14.10.11 .GetDeviceList added which returns DeviceList containing list of
           available lab. interface devices (only currently used with NI interfaces)
           No. of D/A channels now correctly updated when switching between
           NIDAQ (Trad) and NIDAQ-MX without D/A errors occurring
  07.11.11 OpenLabInterface now only called by .SetADCInputMode when
           interface is National Instruments
  13.12.11 .GetADCVoltageRanges() added
  20.12.11 To avoid OLE exceptions and access violations, LoadFromXML/SaveToXML
           now Coinitialise/Codeinitialize COM system before after creation of
           TXMLDocument. XMLDOC now an IXMLDocument rather than a TXMLDocument.
  16.01.12 GetElementFloat() now handles both ',' and '.' decimal separators
  15.6.2   CED 1401: Both A/D and D/A now have circular buffers and 8 Msamples limits
           Min. A/D sampling interval of CED140-plus & Micro 1401 increased to 5 us.
           .DACUpdateInterval now prevented from being set less than minimum
  27.08.12  .DIGHoldingLevel property moved from Published to Public to avoid
            holding level saved in XML file being overwritten
  20.09.12 DoNotSaveSettings property added. When DoNotSaveSettings is set TRUE
           interface settings are not saved to XML in .Destroy()
  ================================================================================ }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  mmsystem, math, xmldoc, xmlintf, strutils ;

const
     MaxDevices = 5 ;
     //MaxADCSamples = 131072 ;
     MaxADCSamples = 1048576*8 ;
     MaxADCChannels = 128 ;
     MaxDACChannels = 128 ;
     MaxADCVoltageRanges = 20 ;
     // A/D sampling sweep trigger modes
     tmFreeRun = 0 ;    // Start sampling immediately
     tmExtTrigger = 1 ; // Wait for external TTL trigger pulse
     tmWaveGen = 2 ;    // Simultaneous D/A waveform and A/D sampling

     imSingleEnded = 0  ; // Single ended A/D input mode
     imDifferential = 1 ; // Differential input mode
     imBNC2110 = 2 ;      // Standard mode for BNC-2110 panel (differential)
     imBNC2090 = 3 ;      // Standard mode for BNC 2090 panel (SE)
     imSingleEndedRSE = 4 ;          // Single Ended (grounded)

     { Interface cards supported }
     NoInterface12 = 0 ;
     NationalInstruments = 1 ;
     Digidata1200 = 2 ;
     CED1401_12 = 3 ;
     CED1401_16 = 4 ;
     NoInterface16 = 5 ;
     Digidata132X = 6 ;
     Instrutech = 7 ;
     ITC_16 = 8 ;
     ITC_18 = 9 ;
     VP500 = 10 ;
     NIDAQMX = 11 ;
     Digidata1440 = 12 ;
     Triton = 13 ;
     CED1401_10V = 14 ;
     WirelessEEG = 15 ;

     NumLabInterfaceTypes = 16 ;
     StimulusExtTriggerFlag = -1 ;  // Stimulus program started by external trig pulse.



type

  TSmallIntArray = Array[0..MaxADCSamples-1] of SmallInt ;
  PSmallIntArray = ^TSmallIntArray ;

  TIntArray = Array[0..MaxADCSamples-1] of Integer ;
  PIntArray = ^TIntArray ;

  TDoubleArray = Array[0..MaxADCSamples-1] of Double ;
  PDoubleArray = ^TDoubleArray ;

  TSingleArray = Array[0..MaxADCSamples-1] of Single ;
  PSingleArray = ^TSingleArray ;

  TLongIntArray = Array[0..MaxADCSamples-1] of LongInt ;
  PLongIntArray = ^TLongIntArray ;

  TBooleanArray = Array[0..MaxADCSamples-1] of Boolean ;
  PBooleanArray = ^TBooleanArray ;

  TSESLabIO = class(TComponent)
  private
    { Private declarations }
    FLabInterfaceType : Integer ;      // Type of lab. interface hardware
    FDeviceNumber : Integer ;          // Device number
    FLabInterfaceName : string ;       // Name of interface
    FLabInterfaceModel : string ;      // Model
    FLabInterfaceAvailable : Boolean ; // Interface hardware is available for use
    FADCInputMode : Integer ;             // A/D Input mode (Differential, SingleEnded)
    FDeviceList : TStringList ;        // Available devices

    FADCMinValue : Integer ;           // Lower limit of A/D sample value
    FADCMaxValue : Integer ;           // upper limit of A/D sample value

    FADCNumChannels : Integer ;        // Number of A/D channels being sampled
    FADCMaxChannels : Integer ;        // Number of A/D channels available.

    FADCNumSamples : Integer ;         // Number of A/D samples (per channel) to be acquired

    FADCSamplingInterval : Double ;    // Inter-sample interval (s) (per channel)
    FADCMaxSamplingInterval : Double ; // Max. valid interval (s)
    FADCMinSamplingInterval : Double ; // Min. valid interval (s)

    FADCTriggerMode : Integer ;          // A/D sweep trigger mode
    FADCExternalTriggerActiveHigh : Boolean ; // TRUE= Active high TTL External trigger
    FADCCircularBuffer : Boolean ;       // Continuous sampling flag using circular buffer

    FADCVoltageRanges : Array[0..MaxADCVoltageRanges-1] of single ;        // A/D input voltage ranges
    FADCNumVoltageRanges : Integer ;                    // Number of ranges available
    FADCVoltageRangeIndex : Integer ;                   // Current range in use
    FADCChannelVoltageRanges : Array[0..MaxADCChannels-1] of Single ;  // Channel A/D voltage range

    FADCBufferLimit : Integer ;                     // Max. number of samples in A/D buffer
    FADCActive : Boolean ;                          // A/D sampling in progress flag
    FADCEmptyFlag : Integer ;                       // Code indicating an unfilled data

    FADCChannelName : Array[0..MaxADCChannels-1] of String ;
    FADCChannelUnits : Array[0..MaxADCChannels-1] of String ;
    FADCChannelVoltsPerUnits : Array[0..MaxADCChannels-1] of Single ;
    FADCChannelGain : Array[0..MaxADCChannels-1] of Single ;
    FADCChannelUnitsPerBit : Array[0..MaxADCChannels-1] of Single ;
    FADCChannelZero : Array[0..MaxADCChannels-1] of Integer ;
    FADCChannelZeroAt : Array[0..MaxADCChannels-1] of Integer ;
    FADCChannelOffset : Array[0..MaxADCChannels-1] of Integer ;
    FADCChannelVisible : Array[0..MaxADCChannels-1] of Boolean ;
    FADCChannelYMin : Array[0..MaxADCChannels-1] of Single ;
    FADCChannelYMax : Array[0..MaxADCChannels-1] of Single ;
    FADCChannelInputNumber : Array[0..MaxADCChannels-1] of Integer ;

    FDACMinValue : Integer ;           // Lower limit of D/A sample value
    FDACMaxValue : Integer ;           // upper limit of D/A sample value

    FDACNumChannels : Integer ;          // Number A/D channels being sampled
    FDACMaxChannels : Integer ;          // Max. number of channels supported

    FDACNumSamples : Integer ;           // No. D/A values (per channel) in waveform
    FDACBufferLimit : Integer ;          // D/A buffer limit

    FDACUpdateInterval : Double ;         // DAC update interval in use
    FDACMinUpdateInterval : Double ;      // Smallest valid DAC update interval
    FDACVoltageRange : Single ;           // DAC output voltage range (+/-V)
    FDACActive : Boolean ;                // DAC output in progress flag
    FDACTriggerOnLevel : Integer ;        // Trigger pulse on level
    FDACTriggerOffLevel : Integer ;       // Trigger pulse off level
    FDACInvertTriggerLevel : Boolean ;    // Inverted trigger level
    FDACInitialPoints : Integer ;         // Initial points in D/A waveforms
    FDACRepeatedWaveform : Boolean ;
    FDACHoldingVoltage : Array[0..MaxDACChannels-1] of Single ;

    FDIGNumOutputs : Integer ;            // Number digital outputs available
    FDIGInterval : Integer ;
    FDIGActive : Boolean ;                // Digital output sweep active
    FDigMinUpdateInterval : Double ;      // Smallest valid digital update interval
    FDigMaxUpdateInterval : Double ;      // Smallest valid digital update interval
    FDigHoldingLevel : Integer ;          // Digital outputs holding levels

    { Default D/A and digital settings }
    FLastDACVolts : Array[0..MaxDACChannels-1] of Single ;
    FLastDACNumChannels : Integer ;
    FLastDigValue : Integer ;

    FStimulusTimerID : Integer ;        // Interval time ID number
    FStimulusDigitalEnabled : Boolean ; // Enable output of digital pulse pattern
    FStimulusTimeStarted : Single ;     // Time (s) last stimulus pulse started
    FStimulusTimerActive : Boolean ;    // TRUE = timer is running
    FStimulusTimerTicks : Integer ;     // Current timer tick count
    FStimulusStartTime : Integer ;      // Tick count to start stimulus at
    FStimulusStartOffset : Integer ;    // No. of digital points to ignore
    FTimerProcInUse : Boolean ;         // TimerProc handle running

    FStimulusExtTrigger : Boolean ;     // Stimulus waveforms wait for ext. trigger

    // Direct Brain Stimulator
    FDBSComPort : Integer ;             // Com port #
    FDBSPulseFrequency : Single ;       // Stimulus pulse frequency (Hz)
    FDBSPulseWidth : Single ;           // Stimulus pulse width (s)
    FDBSStimulusOn : Boolean ;          // Stimulus on flag
    FDBSSleepMode : Boolean ;           // Sleep mode flag

    // CED 1401 special flags
    FCEDPower1401DIGTIMCountShift : Integer ;

    ADCBuf : PSmallIntArray ;     // A/D sample storage buffer
    DACBuf : PSmallIntArray ;     // D/A waveform output buffer
    DigBuf : PSmallIntArray ;     // Digital output buffer
    DigWork : PSmallIntArray ;    // Working buffer for digital data

    SettingsFileName : String ;
    FDoNotSaveSettings : Boolean ; // If TRUE, do not save settings to SettingsFileName

    procedure SetDeviceNumber( DeviceNumber : Integer ) ;
    procedure SetLabInterfaceType( LabInterfaceType : Integer ) ;

    procedure SetADCNumSamples( Value : Integer ) ;
    procedure SetADCNumChannels( Value : Integer ) ;
    procedure SetADCSamplingInterval( Value : Double ) ;
    procedure SetADCVoltageRangeIndex( Value : Integer ) ;
    procedure SetADCVoltageRange( Value : Single ) ;
    procedure SetADCChannelVoltageRange( Channel : Integer ; Value : Single) ;
    procedure SetADCInputMode( Value : Integer ) ;

    procedure SetDACNumChannels( Value : Integer ) ;
    procedure SetDACNumSamples( Value : Integer ) ;
    procedure SetDACUpdateInterval( Value : Double ) ;

    function GetADCVoltageRange : Single ;
    function GetADCChannelOffset( Channel : Integer) : Integer ;
    function GetADCChannelVoltageRange( Channel : Integer) : Single ;



    function GetADCChannelName( Chan : Integer ): String ;
    function GetADCChannelUnits( Chan : Integer ): String ;
    function GetADCChannelVoltsPerUnits( Chan : Integer ) : Single ;
    function GetADCChannelGain( Chan : Integer ) : Single ;
    function GetADCChannelZero( Chan : Integer ) : Integer ;
    function GetADCChannelZeroAt( Chan : Integer ) : Integer ;
    function GetADCChannelUnitsPerBit( Chan : Integer ) : Single ;
    function GetADCChannelVisible( Chan : Integer ) : Boolean ;
    function GetADCChannelYMin( Chan : Integer ) : Single ;
    function GetADCChannelYMax( Chan : Integer ) : Single ;
    function GetADCChannelInputNumber( Chan : Integer ) : Integer ;

    procedure SetADCChannelName( Chan : Integer ; Value : String ) ;
    procedure SetADCChannelUnits( Chan : Integer ; Value : String ) ;
    procedure SetADCChannelVoltsPerUnits( Chan : Integer ; Value : Single ) ;
    procedure SetADCChannelGain( Chan : Integer ; Value : Single ) ;
    procedure SetADCChannelZero( Chan : Integer ; Value : Integer ) ;
    procedure SetADCChannelZeroAt( Chan : Integer ; Value : Integer ) ;
    procedure SetADCChannelUnitsPerBit( Chan : Integer ; Value : Single ) ;
    procedure SetADCChannelVisible( Chan : Integer ; Value : Boolean ) ;
    procedure SetADCChannelYMin( Chan : Integer ; Value : Single ) ;
    procedure SetADCChannelYMax( Chan : Integer ; Value : Single ) ;
    procedure SetADCChannelInputNumber( Chan : Integer ; Value : Integer ) ;

    function GetStimulusTimerPeriod : Single ;
    procedure SetStimulusTimerPeriod( Value : Single ) ;

    function GetTritonSource( Chan : Integer) : Integer ;
    procedure SetTritonSource( Chan : Integer ; Value : Integer) ;
    function GetTritonGain( Chan : Integer) : Integer ;
    procedure SetTritonGain( Chan : Integer ; Value : Integer) ;
    function GetTritonUserConfig : Integer ;
    procedure SetTritonUserConfig( Config : Integer ) ;

    procedure SetTritonDACStreamingEnabled(Enabled : Boolean ) ;
    function GetTritonDACStreamingEnabled : Boolean ;

    function GetTritonICLAMPOn : Boolean ;
    procedure SetTritonICLAMPOn( Value : Boolean ) ;
    function GetTritonNumChannels : Integer ;

    procedure TimerTickOperations ;
    procedure SetADCExternalTriggerActiveHigh( Value : Boolean ) ;

    function  IntLimit( Value : Integer ; LoLimit : Integer ; HiLimit : Integer
              ) : Integer ;
    function  FloatLimit( Value : Single ; LoLimit : Single ; HiLimit : Single
              ) : Single ;
    function GetLabInterfaceName( Num : Integer ) : String ;
    function GetDIGInputs : Integer ;

    function GetDACHoldingVoltage( Chan : Integer ) : Single ;
    procedure SetDACHoldingVoltage( Chan : Integer ; Value : Single ) ;

    function GetDIGHoldingLevel : Integer ;
    procedure SetDIGHoldingLevel( Value : Integer ) ;


    // XML procedures

    procedure AddElementFloat(
              ParentNode : IXMLNode ;
              NodeName : String ;
              Value : Single
              ) ;
    function GetElementFloat(
              ParentNode : IXMLNode ;
              NodeName : String ;
              var Value : Single
              ) : Boolean ;
    procedure AddElementInt(
              ParentNode : IXMLNode ;
              NodeName : String ;
              Value : Integer
              ) ;
    function GetElementInt(
              ParentNode : IXMLNode ;
              NodeName : String ;
              var Value : Integer
              ) : Boolean ;
    procedure AddElementBool(
              ParentNode : IXMLNode ;
              NodeName : String ;
              Value : Boolean
              ) ;
    function GetElementBool(
              ParentNode : IXMLNode ;
              NodeName : String ;
              var Value : Boolean
              ) : Boolean ;

    procedure AddElementText(
              ParentNode : IXMLNode ;
              NodeName : String ;
              Value : String
              ) ;
    function GetElementText(
              ParentNode : IXMLNode ;
              NodeName : String ;
              var Value : String
              ) : Boolean ;

    function FindXMLNode(
         const ParentNode : IXMLNode ;  // Node to be searched
         NodeName : String ;            // Element name to be found
         var ChildNode : IXMLNode ;     // Child Node of found element
         var NodeIndex : Integer        // ParentNode.ChildNodes Index #
                          // Starting index on entry, found index on exit
         ) : Boolean ;

    procedure LoadFromXMLFile1( FileName : String ) ;
    procedure SaveToXMLFile1( FileName : String ;
                             AppendData : Boolean
                             ) ;


  protected
    { Protected declarations }
  public
    { Public declarations }
    StimulusStartFlag : Boolean ;
    FOutPointer : Integer ;

    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
    procedure GetLabInterfaceTypes( List : TStrings ) ;
    procedure GetADCInputModes( List : TStrings ) ;
    procedure GetDeviceNumbers( List : TStrings ) ;
{    function DeviceExists( iDev : Integer ) : Boolean ;}

    procedure OpenLabInterface(
              InterfaceType : Integer ; // Lab. interface type
              var DeviceNumber : Integer ;
              var ADCInputMode : Integer
              ) ;

    procedure GetDeviceList(
              DeviceList : TStrings
              ) ;

    procedure CloseLabInterface ;


    procedure ADCStart ;
    procedure ADCStop ;
    procedure DACStart ;
    procedure DACDIGStart( StartAt : Integer ) ;
    procedure DACStop ;
    function ReadADC( Channel : Integer ) : Integer ;
    procedure WriteDACs( DACVolts : Array of single ; NumChannels : Integer ) ;
    procedure GetADCBuffer( var BufPointer : PSmallIntArray ) ;
    procedure GetDACBuffer( var BufPointer : PSmallIntArray ) ;
    procedure GetDIGBuffer( var BufPointer : PSmallIntArray ) ;
    procedure ADCBufferRefresh ;
    procedure WriteDig( DigByte : Integer ) ;
    procedure StartTimer ;
    procedure StopTimer ;
    function GetDACTriggerOnLevel : Integer ;
    function GetDACTriggerOffLevel : Integer ;
    function ExternalStimulusTrigger : Boolean ;
    procedure StartStimulus ;
    procedure DisableDMA_LabPC ;
    function GetDACVoltageRange(Chan : Integer): Single ;

    procedure TritonGetRegProperties(
          Reg : Integer ;
          var VMin : Single ;   // Lower limit of register values
          var VMax : Single ;   // Upper limit of register values
          var VStep : Single ;   // Smallest step size of values
          var CanBeDisabled : Boolean ; // Register can be disabled
          var Supported : Boolean
          ) ;

    procedure TritonGetReg(
              Reg : Integer ;
              Chan : Integer ;
              var Value : Single ;
              var PercentValue : Single ;
              var Units : String ;
              var Enabled : Boolean ) ;

    procedure TritonSetRegPercent(
              Reg : Integer ;
              Chan : Integer ;
              var PercentValue : single ) ;

    function TritonGetRegEnabled(
              Reg : Integer ;
              Chan : Integer ) : Boolean ;

    procedure TritonSetRegEnabled(
              Reg : Integer ;
              Chan : Integer ;
              Enabled : Boolean ) ;
    procedure SetTritonBesselFilter( Chan : Integer ;
                                     Value : Integer ;
                                     var CutOffFrequency : Single) ;

procedure TritonAutoCompensation(
          UseCFast  : Boolean ;
          UseCslowA  : Boolean ;
          UseCslowB : Boolean ;
          UseCslowC : Boolean ;
          UseCslowD : Boolean ;
          UseAnalogLeakCompensation : Boolean ;
          UseDigitalLeakCompensation : Boolean ;
          UseDigitalArtefactSubtraction : Boolean ;
          CompensationCoeff : Single ;
          VHold : Single ;
          THold : Single ;
          VStep : Single ;
          TStep : Single
          ) ;

    procedure TritonJPAutoZero ;

    procedure TritonZap(
              Duration : Double ;
              Amplitude : Double ;
              ChanNum : Integer
              ) ;

    function SettingsFileExists : Boolean ;

    procedure TritonGetSourceList( cbSourceList : TStrings ) ;
    procedure TritonGetGainList( cbGainList : TStrings ) ;
    procedure TritonGetUserConfigList( cbList : TStrings ) ;
    procedure TritonCalibrate ;
    function TritonIsCalibrated : Boolean ;

    procedure TritonAutoArtefactRemovalEnable( Enabled : Boolean ) ;
    procedure TritonDigitalLeakSubtractionEnable( Chan : Integer ; Enabled : Boolean ) ;

    procedure LoadFromXMLFile( FileName : String ) ;
    procedure SaveToXMLFile( FileName : String ;
                             AppendData : Boolean
                             ) ;

    function GetDBSStimulus : Boolean ;
    Procedure SetDBSStimulus( Value : Boolean ) ;
    function GetDBSSleepMode : Boolean ;
    Procedure SetDBSSleepMode( Value : Boolean ) ;
    function GetDBSWirelessChannel : Integer ;
    function GetDBSFrequency : Single ;
    Procedure SetDBSFrequency( Value : Single ) ;
    function GetDBSPulseWidth : Single ;
    Procedure SetDBSPulseWidth( Value : Single ) ;
    function GetDBSSamplingRate : Single ;
    function GetDBSNumFramesLost : Integer ;

    procedure GetADCVoltageRanges(
              var Ranges : Array of Single ;
              var NumRanges : Integer ) ;


    Property ADCChannelOffset[ i : Integer ] : Integer
                                            Read GetADCChannelOffset ;

    Property ADCChannelVoltageRange[ i : Integer ] : Single
                                            Read GetADCChannelVoltageRange
                                            Write SetADCChannelVoltageRange ;

    Property ADCChannelName[Chan : Integer] : String
             Read GetADCChannelName write SetADCChannelName ;
    Property ADCChannelUnits[Chan : Integer] : String
             Read GetADCChannelUnits write SetADCChannelUnits ;
    Property ADCChannelVoltsPerUnit[Chan : Integer] : Single
             Read GetADCChannelVoltsPerUnits write SetADCChannelVoltsPerUnits ;
    Property ADCChannelGain[Chan : Integer] : Single
             Read GetADCChannelGain Write SetADCChannelGain ;
    Property ADCChannelZero[Chan : Integer] : Integer
             Read GetADCChannelZero Write SetADCChannelZero ;
    Property ADCChannelZeroAt[Chan : Integer] : Integer
             Read GetADCChannelZeroAt Write SetADCChannelZeroAt ;
    Property ADCChannelUnitsPerBit[Chan : Integer] : Single
             Read GetADCChannelUnitsPerBit Write SetADCChannelUnitsPerBit ;
    Property ADCChannelVisible[Chan : Integer] : Boolean
             Read GetADCChannelVisible Write SetADCChannelVisible ;
    Property ADCChannelYMin[Chan : Integer] : Single
             Read GetADCChannelYMin Write SetADCChannelYMin ;
    Property ADCChannelYMax[Chan : Integer] : Single
             Read GetADCChannelYMax Write SetADCChannelYMax ;
    Property ADCChannelInputNumber[Chan : Integer] : Integer
             Read GetADCChannelInputNumber Write SetADCChannelInputNumber ;


    Property DACVoltageRange[Chan : Integer ] : Single
                                            Read GetDACVoltageRange ;

    Property DACHoldingVoltage[ i : Integer ] : Single
                                            Read GetDACHoldingVoltage
                                            Write SetDACHoldingVoltage ;

    Property TritonSource[ Chan : Integer ] : Integer
                                            Read GetTritonSource
                                            write SetTritonSource ;

    Property TritonGain[ Chan : Integer ] : Integer
                                            Read GetTritonGain
                                            write SetTritonGain ;
    Property DIGHoldingLevel : Integer
                               Read GetDIGHoldingLevel
                               Write SetDIGHoldingLevel ;

    Property DoNotSaveSettings : Boolean
                                 Read FDoNotSaveSettings
                                 Write FDoNotSaveSettings ;

  published

    { Published declarations }
    Property LabInterfaceType : Integer Read FLabInterfaceType write SetLabInterfaceType stored false ;
    Property DeviceNumber : Integer Read FDeviceNumber write SetDeviceNumber stored false ;
    Property ADCInputMode : Integer Read FADCInputMode Write SetADCInputMode stored false ;
    Property LabInterfaceAvailable : Boolean Read FLabInterfaceAvailable stored false ;
    Property LabInterfaceName : string read FLabInterfaceName stored false ;
    Property LabInterfaceModel : string read FLabInterfaceModel stored false ;

    Property ADCNumChannels : Integer Read FADCNumChannels Write SetADCNumChannels  stored false ;
    Property ADCMaxChannels : Integer Read FADCMaxChannels ;

    Property ADCNumSamples : Integer Read FADCNumSamples Write SetADCNumSamples
                                     Default 512 ;
    Property ADCMinValue : Integer Read FADCMinValue ;
    Property ADCMaxValue : Integer Read FADCMaxValue ;
    Property ADCSamplingInterval : Double Read FADCSamplingInterval
                                          Write SetADCSamplingInterval stored false ;
    Property ADCMinSamplingInterval : Double Read FADCMinSamplingInterval stored false ;
    Property ADCMaxSamplingInterval : Double Read FADCMaxSamplingInterval stored false ;
    Property ADCVoltageRange : Single Read GetADCVoltageRange
                                      Write SetADCVoltageRange stored false ;
    Property ADCNumVoltageRanges : Integer Read FADCNumVoltageRanges ;
    Property ADCVoltageRangeIndex : Integer Read FADCVoltageRangeIndex
                                            Write SetADCVoltageRangeIndex stored false ;
    Property ADCTriggerMode : Integer Read FADCTriggerMode
                                      Write FADCTriggerMode stored false ;
    Property ADCExternalTriggerActiveHigh : Boolean
             read FADCExternalTriggerActiveHigh
             write SetADCExternalTriggerActiveHigh stored false ;
    Property ADCCircularBuffer : Boolean Read FADCCircularBuffer
                                         Write FADCCircularBuffer stored false ;
    Property ADCBufferLimit : Integer Read FADCBufferLimit ;
    Property ADCActive : Boolean Read FADCActive ;
    Property ADCEmptyFlag : Integer Read FADCEmptyFlag ;


    Property DACActive : Boolean Read FDACActive ;
    Property DACMinValue : Integer Read FDACMinValue ;
    Property DACMaxValue : Integer Read FDACMaxValue ;

    Property DACNumChannels : Integer Read FDACNumChannels Write SetDACNumChannels
                                      Default 2 ;
    Property DACMaxChannels : Integer Read FDACMaxChannels ;
    Property DACNumSamples : Integer Read FDACNumSamples Write SetDACNumSamples
                                     Default 512 ;
    Property DACBufferLimit : Integer Read FDACBufferLimit ;
    Property DACMinUpdateInterval : Double Read FDACMinUpdateInterval ;

    Property DACUpdateInterval : Double Read FDACUpdateInterval
                                        Write SetDACUpdateInterval ;

    Property DACTriggerOnLevel : Integer Read GetDACTriggerOnLevel ;
    Property DACTriggerOffLevel : Integer Read GetDACTriggerOffLevel ;
    Property DACInvertTriggerLevel : Boolean Read FDACInvertTriggerLevel
                                             Write  FDACInvertTriggerLevel ;
    Property DACInitialPoints : Integer Read FDACInitialPoints ;
    Property DACRepeatWaveform : Boolean Read FDACRepeatedWaveform
                                           Write FDACRepeatedWaveform ;
    Property DIGNumOutputs : Integer Read FDIGNumOutputs ;
    Property DIGInterval : Integer Read FDIGInterval ;
    Property DigMinUpdateInterval : Double Read FDigMinUpdateInterval ;
    Property DIGInputs : Integer Read GetDIGInputs ;

    Property TimerPeriod : Single Read GetStimulusTimerPeriod Write SetStimulusTimerPeriod ;
    Property DigitalStimulusEnabled : Boolean Read FStimulusDigitalEnabled Write FStimulusDigitalEnabled ;
    Property TimerActive : Boolean Read FStimulusTimerActive ;
    Property StimulusTime : Single Read FStimulusTimeStarted ;
    Property DigitalStimulusStart : Integer Read FStimulusStartOffset Write FStimulusStartOffset;

    Property TritonNumChannels : Integer
                                 Read GetTritonNumChannels ;

    Property TritonUserConfig : Integer Read GetTritonUserConfig write SetTritonUserConfig ;
    Property TritonDACStreamingEnabled : Boolean Read GetTritonDACStreamingEnabled
                                                 write SetTritonDACStreamingEnabled ;

    Property TritonICLAMPOn : Boolean Read GetTritonICLAMPOn
                                      Write SetTritonICLAMPOn ;

    Property DBSStimulus : Boolean
             read GetDBSStimulus write SetDBSStimulus stored false ;
    Property DBSSleepMode : Boolean
             read GetDBSSleepMode write SetDBSSleepMode stored false ;
    Property DBSWirelessChannel : Integer
             read GetDBSWirelessChannel ;
    Property DBSFrequency : Single
             read GetDBSFrequency write SetDBSFrequency stored false ;
    Property DBSPulseWidth : Single
             read GetDBSPulseWidth write SetDBSPulseWidth stored false ;
    Property DBSSamplingRate : Single read GetDBSSamplingRate ;
    Property DBSNumFramesLost : Integer read GetDBSNumFramesLost ;
  end;

procedure Register;

procedure TimerProc(
          uID,uMsg : SmallInt ; User : TSESLabIO ; dw1,dw2 : LongInt ) ; stdcall ;


implementation

uses NatInst, CED1401, dd1200, dd1200win98, dd1320,
     itcmm, itclib, vp500Unit, nidaqmxunit, dd1440, tritonunit,wirelesseegunit,ActiveX ;


const
     { ------------------------- }
     EmptyFlag = 32767 ;
     //ChannelLimit = 15 ;
     StimulusTimerTickInterval = 10 ; // Timer tick resolution (ms)


procedure Register;
begin
  RegisterComponents('Samples', [TSESLabIO]);
end;


constructor TSESLabIO.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
var
   i : Integer ;
begin
     inherited Create(AOwner) ;

     New(ADCBuf) ;
     New(DACBuf) ;
     New(DigBuf) ;
     New(DigWork) ;

     FLabInterfaceType := NoInterface12 ; { No Interface }

     FDeviceNumber := 1 ;
     FDeviceList := TStringList.Create ;
     FDeviceList.Add('') ;

     //LabInterfaceType := FLabInterfaceType  ;
     FLabInterfaceAvailable := False ;
     FADCMinValue := -2047 ;
     FADCMaxValue := 2048 ;

     FADCMaxChannels := 16 ;
     FADCNumChannels := 1 ;
     for i := 0 to High(FADCChannelOffset) do FADCChannelOffset[i] := i ;
     FADCNumSamples := 512 ;
     FADCActive := False ;
     FADCTriggerMode := tmFreeRun ;
     ADCExternalTriggerActiveHigh := False ;
     FADCInputMode := imSingleEnded ;
     FADCSamplingInterval := 0.01 ;

     { A/D converter voltage ranges }
     for i := 0 to MaxADCVoltageRanges-1 do FADCVoltageRanges[i] := 1.0 ;
     FADCNumVoltageRanges := 1 ;
     FADCVoltageRangeIndex := 0 ;
     for i := 0 to MaxADCChannels-1 do begin
        FADCChannelName[i] := format('Ch.%d',[i]) ;
        FADCChannelVoltageRanges[i] := 10.0 ;
        FADCChannelUnits[i] := 'mV' ;
        FADCChannelVoltsPerUnits[i] := 0.001 ;
        FADCChannelGain[i] := 1.0 ;
        FADCChannelZero[i] := 0 ;
        FADCChannelZeroAt[i] := -1 ;
        FADCChannelUnitsPerBit[i] :=
            FADCChannelVoltageRanges[i] /
            (FADCChannelVoltsPerUnits[i]*FADCChannelGain[i]*(FADCMaxValue+1)) ;
        FADCChannelVisible[i] := True ;
        FADCChannelYMin[i] := FADCMinValue ;
        FADCChannelYMax[i] := FADCMaxValue ;
        FADCChannelInputNumber[i] := i ;
        end ;

     FDACMaxChannels := 2 ;
     FDACMinValue := -2047 ;
     FDACMaxValue := 2048 ;
     FDACNumChannels := 2 ;
     FDACNumSamples := 512 ;
     FDACActive := False ;
     FADCEmptyFlag := EmptyFlag ;
     FDACInvertTriggerLevel := False ;
     FDACRepeatedWaveform := False ;

     for i := 0 to High(FDACHoldingVoltage) do FDACHoldingVoltage[i] := 0.0 ;

     for i := 0 to High(FLastDACVolts) do FLastDACVolts[i] := 0.0 ;
     FLastDACNumChannels := 1 ;
     FLastDigValue := 0 ;

     FDigMaxUpdateInterval := 1000.0 ;
     FDIGHoldingLevel := 0 ;
     FDIGActive := False ;
     FOutPointer := 0 ;
     // Initialise stimulus timer
     FStimulusTimerActive := False ;
     FStimulusStartOffset := 0 ;
     FTimerProcInUse := False ;

     FStimulusExtTrigger := False ;
     StimulusStartFlag := False ;

    // Default settings for DBS/EEG unit
    FDBSPulseFrequency := 1.0  ;       // Stimulus pulse frequency (Hz)
    FDBSPulseWidth := 1E-3 ;           // Stimulus pulse width (s)
    FDBSComPort := 0;
    FDBSStimulusOn := False ;
    FDBSSleepMode := False ;

    // Default settings for CED Power 1401 DIGTIM count shift
    FCEDPower1401DIGTIMCountShift := 1 ;

     // Load settings
     SettingsFileName := ExtractFilePath(ParamStr(0)) + 'lab interface settings.xml' ;
     if FileExists( SettingsFileName ) then LoadFromXMLFile( SettingsFileName ) ;
     FDoNotSaveSettings := False ; // When TRUE do not save settings to SettingsFileName when component is destroyed

     // Initialise laboratory interface hardware
     OpenLabInterface( FLabInterfaceType,
                       FDeviceNumber,
                       FADCInputMode ) ;

     end ;


destructor TSESLabIO.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Save amplifier settings
     if not FDoNotSaveSettings then SaveToXMLFile( SettingsFileName, False ) ;

     // Close down interface
     CloseLabInterface ;

     { Destroy internal objects created by TSESLabIO.Create }
     Dispose(ADCBuf) ;
     Dispose(DACBuf) ;
     Dispose(DigBuf) ;
     Dispose(DigWork) ;

     FDeviceList.Free ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


function TSESLabIO.GetLabInterfaceName( Num : Integer ) : String ;
{ -------------------------------------
  Get name of laboratory interface unit
  ------------------------------------- }
begin
     case Num of
       NoInterface12 : Result := 'No Lab. Interface (12 bit)' ;
       NoInterface16 : Result := 'No Lab. Interface (16 bit)' ;
       NationalInstruments : Result := 'National Instruments (NIDAQ Trad.)' ;
       Digidata1200 : Result := 'Axon Instruments (Digidata 1200)' ;
       CED1401_12 : Result := 'CED 1401 (12 bit)(5V)' ;
       CED1401_16 : Result := 'CED 1401 (16 bit)(5V)' ;
       Digidata132X : Result := 'Axon Instruments (Digidata 132X)' ;
       Instrutech : Result := 'Instrutech ITC-16/18 (New drivers)' ;
       ITC_16 : Result := 'Instrutech ITC-16 (Old drivers)' ;
       ITC_18 : Result := 'Instrutech ITC-18 (Old drivers)' ;
       VP500 : Result := 'Biologic VP500' ;
       NIDAQMX : Result := 'National Instruments (NIDAQ-MX)' ;
       Digidata1440 : Result := 'Molecular Devices Digidata 1440' ;
       Triton : Result := 'Tecella Triton/Triton+/Pico' ;
       CED1401_10V : Result := 'CED1401 (16 bit)(10V)' ;
       WirelessEEG : Result := 'SIPBS: Wireless EEG transceiver' ;
       end ;
     end ;


procedure TSESLabIO.OpenLabInterface(
          InterfaceType : Integer ; // Lab. interface type
          var DeviceNumber : Integer ;   // device number
          var ADCInputMode : Integer
          ) ;
// --------------------
//  Open lab interface
//  -------------------
var
     i : Integer ;
begin

     // Close existing interface
     CloseLabInterface ;

     { Initialise lab. interface hardware }
     FLabInterfaceType := InterfaceType ;
     FDeviceNumber := DeviceNumber ;
     FADCInputMode := ADCInputMode ;
     FLabInterfaceModel := 'Unknown' ;
     FADCBufferLimit := High(TSmallIntArray)+1 ;
     FDACBufferLimit := High(TSmallIntArray)+1 ;

     case FLabInterfaceType of

       { No interface 12 bit A/D data}
       NoInterface12 : begin
          FLabInterfaceName := 'No Lab. Interface' ;
          FADCMinValue := -2048 ;
          FADCMaxValue := 2047 ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          FADCVoltageRanges[0] := 5.0 ;
          FADCNumVoltageRanges := 1 ;
          FADCMinSamplingInterval := 1E-5 ;
          FADCMaxSamplingInterval := 1000 ;
          FDACMinUpdateInterval := 1E-3 ;
          FDACVoltageRange := 5.0 ;
          FDACMinUpdateInterval := 1E-3 ;
          FDIGNumOutputs := 8 ; { No. of digital outputs }
          FDIGInterval := 1 ;
          FDigMinUpdateInterval := 1E-3 ;
          FDigMaxUpdateInterval := 1000.0 ;
          FDACTriggerOnLevel := FDACMaxValue ;
          FDACTriggerOffLevel := 0 ;
          FDACInitialPoints := 5 ;
          FLabInterfaceAvailable := True ;
          end ;

       { No interface 16 bit A/D data}
       NoInterface16 : begin
          FLabInterfaceName := 'No Lab. Interface (16 bit)' ;
          FADCMinValue := -32768 ;
          FADCMaxValue := 32767 ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          FADCVoltageRanges[0] := 5.0 ;
          FADCNumVoltageRanges := 1 ;
          FADCMinSamplingInterval := 1E-5 ;
          FADCMaxSamplingInterval := 1000 ;
          FDACMinUpdateInterval := 1E-3 ;
          FDACVoltageRange := 5.0 ;
          FDACMinUpdateInterval := 1E-3 ;
          FDIGNumOutputs := 8 ; { No. of digital outputs }
          FDIGInterval := 1 ;
          FDigMinUpdateInterval := 1E-3 ;
          FDigMaxUpdateInterval := 1000.0 ;
          FDACTriggerOnLevel := FDACMaxValue ;
          FDACTriggerOffLevel := 0 ;
          FDACInitialPoints := 5 ;
          FLabInterfaceAvailable := True ;
          end ;

       NationalInstruments : begin
          FLabInterfaceName := 'National Instruments (NIDAQ)' ;
          FLabInterfaceAvailable := NI_GetLabInterfaceInfo(
                                    FDeviceList,
                                    DeviceNumber,
                                    FADCInputMode,
                                    FLabInterfaceModel,
                                    FADCMaxChannels,
                                    FADCMinSamplingInterval,FADCMaxSamplingInterval,
                                    FADCMinValue, FADCMaxValue,
                                    FDACMaxChannels,FDACMinValue, FDACMaxValue,
                                    FADCVoltageRanges,FADCNumVoltageRanges,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval,
                                    FDigMinUpdateInterval,
                                    FDigMaxUpdateInterval,
                                    FDIGInterval,
                                    FADCBufferLimit ) ;

          FDeviceNumber := DeviceNumber ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 8 ; { No. of digital outputs }
             //FDIGInterval := 2 ;
             FDACTriggerOnLevel := 0 ;
             FDACTriggerOffLevel := IntLimit( Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                              FDACMinValue,FDACMaxValue) ;
             FDACInitialPoints := 5 ;
             end ;
          end ;

       Digidata1200 : begin
          FLabInterfaceName := 'Axon Instruments (Digidata 1200)' ;
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_ConfigureHardware( FADCEmptyFlag ) ;
             FLabInterfaceAvailable := DD_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
             end
          else begin
             DD98_ConfigureHardware( FADCEmptyFlag ) ;
             FLabInterfaceAvailable := DD98_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
             end ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                   FDACMinValue,FDACMaxValue) ;
             FDACTriggerOffLevel := 0 ;
             FDACInitialPoints := 5 ;

             end ;
          end ;

       CED1401_12 : begin
          FLabInterfaceName := 'CED 1401 (12 bit)(5V)' ;
          CED_ConfigureHardware( 12, FADCEmptyFlag, 5.0 ) ;
          FLabInterfaceAvailable := CED_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMaxChannels,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACMaxChannels,
                                    FDACBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDIGNumOutputs := 8 ; { No. of digital outputs }
             FDIGInterval := 1 ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := 0 ;
             FDACTriggerOffLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                    FDACMinValue,FDACMaxValue) ;

             FDACInitialPoints := 0 ;

             end ;
          end ;

       CED1401_16, CED1401_10V : begin
          if FLabInterfaceType = CED1401_16 then begin
             FLabInterfaceName := 'CED1401 (5V ADC/DAC range)' ;
             CED_ConfigureHardware( 16, FADCEmptyFlag, 5.0 ) ;
             end
          else begin
             FLabInterfaceName := 'CED1401 (10V ADC/DAC range)' ;
             CED_ConfigureHardware( 16, FADCEmptyFlag, 10.0 ) ;
             end ;
          FLabInterfaceAvailable := CED_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMaxChannels,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACMaxChannels,
                                    FDACBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             // DAC buffer set to 1/3 of ADCBufferLimit because 256 KB CED1401-plus
             // does not have sufficient memory
//             FDACBufferLimit := FADCBufferLimit div 3 ;
             FDIGNumOutputs := 8 ; { No. of digital outputs }
             FDIGInterval := 1 ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := 0 ;
             FDACTriggerOffLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                    FDACMinValue,FDACMaxValue) ;
             FDACInitialPoints := 0 ;

             end ;
          end ;

       Digidata132X : begin
          FLabInterfaceName := 'Axon Instruments (Digidata 132X)' ;
          DD132X_ConfigureHardware( FADCEmptyFlag ) ;
          FLabInterfaceAvailable := DD132X_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                   FDACMinValue,FDACMaxValue) ;
             FDACTriggerOffLevel := 0 ;
             { Note. no initial points in D/A waveforms because A/D and D/A
               runs synchronously }
             FDACInitialPoints := 0 ;
             end ;
          end ;

       Instrutech : begin
          FLabInterfaceName := 'Instrutech ITC-16/18 (New Driver)' ;
          ITCMM_ConfigureHardware( FADCEmptyFlag ) ;
          FLabInterfaceAvailable := ITCMM_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDACMaxChannels := 4 ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                   FDACMinValue,FDACMaxValue) ;
             FDACTriggerOffLevel := 0 ;
             { Note. no initial points in D/A waveforms because A/D and D/A
               runs synchronously }
             FDACInitialPoints := 0 ;
             end ;
          end ;

       ITC_16, ITC_18 : begin

          if FLabInterfaceType = ITC_16 then begin
             // Configure library for ITC-16
             FLabInterfaceName := 'Instrutech ITC-16 (Old Driver)' ;
             ITC_ConfigureHardware( 0, FADCEmptyFlag ) ;
             end
          else begin
             // Configure library for ITC-18
             FLabInterfaceName := 'Instrutech ITC-18 (Old Driver)' ;
             ITC_ConfigureHardware( 1, FADCEmptyFlag ) ;
             end ;

          FLabInterfaceAvailable := ITC_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACMaxChannels := 4 ;
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                   FDACMinValue,FDACMaxValue) ;
             FDACTriggerOffLevel := 0 ;
             { Note. no initial points in D/A waveforms because A/D and D/A
               runs synchronously }
             FDACInitialPoints := 0 ;
             end ;
          end ;

       VP500 : begin
          FLabInterfaceName := 'Biologic VP500' ;
          VP500_ConfigureHardware( FADCEmptyFlag ) ;
          FLabInterfaceAvailable := VP500_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := FDACMaxValue ;
             FDACTriggerOffLevel := 0 ;
             { Note. no initial points in D/A waveforms because A/D and D/A
               runs synchronously }
             FDACInitialPoints := 0 ;
             end ;
          end ;

        NIDAQMX : begin
          FLabInterfaceName := 'National Instruments (NIDAQ-MX)' ;
          FLabInterfaceAvailable := NIMX_GetLabInterfaceInfo(
                                    FDeviceList,
                                    DeviceNumber,
                                    FADCInputMode,
                                    FLabInterfaceModel,
                                    FADCMaxChannels,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue, FADCMaxValue,
                                    FDACMaxChannels,FDACMinValue, FDACMaxValue,
                                    FADCVoltageRanges,FADCNumVoltageRanges,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval,
                                    FDigMinUpdateInterval,
                                    FDigMaxUpdateInterval,
                                    FDIGInterval,
                                    FADCBufferLimit ) ;

          FDeviceNumber := DeviceNumber ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 8 ; { No. of digital outputs }
             //FDIGInterval := 2 ;
             FDACTriggerOnLevel := 0 ;
             FDACTriggerOffLevel := IntLimit( Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                              FDACMinValue,FDACMaxValue) ;
             FDACInitialPoints := 0 ;
             end ;
          end ;

       Digidata1440 : begin
          FLabInterfaceName := 'Molecular Devices (Digidata 1440)' ;
          DD1440_ConfigureHardware( FADCEmptyFlag ) ;
          FLabInterfaceAvailable := DD1440_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                   FDACMinValue,FDACMaxValue) ;
             FDACTriggerOffLevel := 0 ;
             { Note. no initial points in D/A waveforms because A/D and D/A
               runs synchronously }
             FDACInitialPoints := 0 ;
             end ;
          end ;

       Triton : begin
          FLabInterfaceName := 'Tecella Triton' ;
          Triton_ConfigureHardware( FADCEmptyFlag ) ;
          FLabInterfaceAvailable := Triton_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMaxChannels,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          if FLabInterfaceAvailable then begin
             FDACBufferLimit := FADCBufferLimit ;
             FDIGNumOutputs := 4 ; { No. of digital outputs }
             FDIGInterval := FDACBufferLimit ;
             FDigMinUpdateInterval := FDACMinUpdateInterval ;
             FDigMaxUpdateInterval := 1000.0 ;
             FDACTriggerOnLevel := IntLimit(Round((FDACMaxValue*4.99)/FDACVoltageRange),
                                   FDACMinValue,FDACMaxValue) ;
             FDACTriggerOffLevel := 0 ;
             { Note. no initial points in D/A waveforms because A/D and D/A
               runs synchronously }
             FDACInitialPoints := 0 ;
             end ;
          end ;

       WirelessEEG : begin
          FLabInterfaceName := 'Wireless EEG' ;
          FLabInterfaceAvailable := WirelessEEG_GetLabInterfaceInfo(
                                    FLabInterfaceModel,
                                    FADCMinSamplingInterval,
                                    FADCMaxSamplingInterval,
                                    FADCMinValue,
                                    FADCMaxValue,
                                    FADCVoltageRanges,
                                    FADCNumVoltageRanges,
                                    FADCBufferLimit,
                                    FDACVoltageRange,
                                    FDACMinUpdateInterval ) ;
          end ;

       end ;

     { Set type to no interface if selected one is not available }
     if not FLabInterfaceAvailable then begin
          FLabInterfaceType := NoInterface12 ;
          FLabInterfaceName := 'No Lab. Interface (12 bit)' ;
          FADCMinValue := -2048 ;
          FADCMaxValue := 2047 ;
          FDACMinValue := FADCMinValue ;
          FDACMaxValue := FADCMaxValue ;
          FADCVoltageRanges[0] := 5.0 ;
          FADCNumVoltageRanges := 1 ;
          FADCMinSamplingInterval := 1E-5 ;
          FADCMaxSamplingInterval := 1000 ;
          FDACMinUpdateInterval := 1E-3 ;
          FDACVoltageRange := 5.0 ;
          FDACMinUpdateInterval := 1E-3 ;
          FDIGNumOutputs := 8 ; { No. of digital outputs }
          FDIGInterval := 1 ;
          FDigMinUpdateInterval := FDACMinUpdateInterval ;
          FDigMaxUpdateInterval := 1000.0 ;
          FDACTriggerOnLevel := FDACMaxValue ;
          FDACTriggerOffLevel := 0 ;
          end ;

     // Set all channel A/D voltage ranges and display limits to default value
     //FADCVoltageRangeIndex := 0 ;
     for i := 0 to MaxADCVoltageRanges-1 do begin
         FADCChannelYMin[i] := FADCMinValue ;
         FADCChannelYMax[i] := FADCMaxValue ;
         FADCChannelVoltageRanges[i] := Max(Min(FADCChannelVoltageRanges[i],
                                        FADCVoltageRanges[0]),
                                        FADCVoltageRanges[FADCNumVoltageRanges-1]) ;
         end ;

     // Set D/A output holding levels
     WriteDACs( FDACHoldingVoltage, FDACMaxChannels ) ;
     WriteDIG( FDIGHoldingLevel ) ;

     end ;


procedure TSESLabIO.GetDeviceList(
          DeviceList : TStrings
          ) ;
// ---------------------------------------
// Get list of available interface devices
// ---------------------------------------
var
    i : Integer ;
begin
    DeviceList.Clear ;
    for i := 0 to FDeviceList.Count-1 do begin
       DeviceList.Add(FDeviceList.Strings[i]) ;
       end ;
    end ;


procedure TSESLabIO.CloseLabInterface ;
// --------------------------
// Close laboratory interface
// --------------------------
begin
     if not FLabInterfaceAvailable then Exit ;

     // Stop stimulus timer
     StopTimer ;

     { Shut down lab. interface }
     case FLabInterfaceType of
          NationalInstruments : begin
             NI_CloseLaboratoryInterface ;
             end ;
          Digidata1200 : begin
             if Win32Platform = VER_PLATFORM_WIN32_NT then DD_CloseLaboratoryInterface
                                                      else DD98_CloseLaboratoryInterface ;
             end ;
          CED1401_12, CED1401_16, CED1401_10V : begin
             CED_CloseLaboratoryInterface ;
             end ;
          Digidata132X : begin
             DD132X_CloseLaboratoryInterface ;
             end ;
          Instrutech : begin
             ITCMM_CloseLaboratoryInterface ;
             end ;
          ITC_16, ITC_18 : begin
             ITC_CloseLaboratoryInterface ;
             end ;
          VP500 : begin
             VP500_CloseLaboratoryInterface ;
             end ;
          NIDAQMX : begin
             NIMX_CloseLaboratoryInterface ;
             end ;
          Digidata1440 : begin
             DD1440_CloseLaboratoryInterface ;
             end ;
          Triton : begin
             Triton_CloseLaboratoryInterface ;
             end ;
          WirelessEEG : begin
             end ;

          end ;

     end ;


procedure TSESLabIO.ADCStart ;
{ ----------------------
  Start A/D sampling
  ---------------------- }

var
   i,j : Integer ;
   WaitForExtTrigger : Boolean ;
begin
     if not FLabInterfaceAvailable then Exit ;

     { Fill buffer with empty flag }
     j := 0 ;
     for i := 1 to (FADCNumChannels*FADCNumSamples) div 2 do begin
        ADCBuf^[j] := EmptyFlag ;
        Inc(j) ;
        ADCBuf^[j] := -EmptyFlag ;
        Inc(j) ;
        end ;

     // Set wait for external trigger flag
     case FADCTriggerMode of
          tmFreeRun : WaitForExtTrigger := False ;
          tmWaveGen,tmExtTrigger : WaitForExtTrigger := True ;
          else WaitForExtTrigger := False ;
          end ;

     case FLabInterfaceType of
       NationalInstruments : begin
          NI_ADCToMemory( ADCBuf^, FADCNumChannels, FADCNumSamples,
                          FADCSamplingInterval,
                          FADCChannelVoltageRanges,
                          FADCTriggerMode,
                          FADCExternalTriggerActiveHigh,
                          FADCCircularBuffer,
                          FADCInputMode,
                          FADCChannelInputNumber ) ;
          end ;

       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_ADCToMemory( ADCBuf^,
                          FADCNumChannels,
                          FADCNumSamples,
                          FADCSamplingInterval,
                          FADCVoltageRanges[FADCVoltageRangeIndex],
                          FADCTriggerMode,
                          FADCCircularBuffer ) ;
             end
          else begin
             DD98_ADCToMemory( ADCBuf^,
                          FADCNumChannels,
                          FADCNumSamples,
                          FADCSamplingInterval,
                          FADCVoltageRanges[FADCVoltageRangeIndex],
                          FADCTriggerMode,
                          FADCCircularBuffer ) ;
             end ;
          end ;

       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_ADCToMemory( ADCBuf^,
                           FADCNumChannels,
                           FADCNumSamples,
                           FADCSamplingInterval,
                           FADCVoltageRanges[FADCVoltageRangeIndex],
                           FADCTriggerMode,
                           FADCExternalTriggerActiveHigh,
                           FADCCircularBuffer ) ;

          end ;

       Digidata132X : begin
          DD132X_ADCToMemory( ADCBuf^,
                              FADCNumChannels,
                              FADCNumSamples,
                              FADCSamplingInterval,
                              FADCVoltageRanges[FADCVoltageRangeIndex],
                              FADCTriggerMode,
                              FADCCircularBuffer ) ;
          end ;

       Instrutech : begin
          ITCMM_ADCToMemory( ADCBuf^,
                             FADCNumChannels,
                             FADCNumSamples,
                             FADCSamplingInterval,
                             FADCVoltageRanges[FADCVoltageRangeIndex],
                             FADCTriggerMode,
                             FADCExternalTriggerActiveHigh,
                             FADCCircularBuffer ) ;
          end ;

       ITC_16, ITC_18 : begin
          ITC_ADCToMemory( ADCBuf^,
                           FADCNumChannels,
                           FADCNumSamples,
                           FADCSamplingInterval,
                           FADCVoltageRanges[FADCVoltageRangeIndex],
                           FADCTriggerMode,
                           FADCCircularBuffer ) ;
          end ;

       VP500 : begin
          VP500_ADCToMemory( ADCBuf^, FADCNumChannels, FADCNumSamples,
                           FADCSamplingInterval,
                           FADCVoltageRanges[FADCVoltageRangeIndex],
                           FADCTriggerMode, FADCCircularBuffer ) ;
          end ;

       NIDAQMX : begin
          NIMX_ADCToMemory( ADCBuf^,
                            FADCNumChannels,
                            FADCNumSamples,
                            FADCSamplingInterval,
                            FADCChannelVoltageRanges,
                            FADCTriggerMode,
                            FADCExternalTriggerActiveHigh,
                            FADCCircularBuffer,
                            FADCInputMode ,
                            FADCChannelInputNumber) ;
          end ;

       Digidata1440 : begin
          DD1440_ADCToMemory( ADCBuf,
                              FADCNumChannels,
                              FADCNumSamples,
                              FADCSamplingInterval,
                              FADCVoltageRanges[FADCVoltageRangeIndex],
                              FADCTriggerMode,
                              FADCCircularBuffer ) ;
          end ;

       Triton : begin
          Triton_ADCToMemory( ADCBuf^,
                              FADCNumChannels,
                              FADCNumSamples,
                              FADCSamplingInterval,
                              FADCVoltageRanges[FADCVoltageRangeIndex],
                              FADCTriggerMode,
                              FADCCircularBuffer ) ;
          end ;

       WirelessEEG : begin
          WirelessEEG_ADCToMemory( ADCBuf^,
                              FADCNumChannels,
                              FADCNumSamples,
                              FADCSamplingInterval,
                              FADCVoltageRanges[FADCVoltageRangeIndex],
                              FADCTriggerMode,
                              FADCCircularBuffer ) ;
          end ;

       end ;
     FADCActive := True ;
     end ;


procedure TSESLabIO.ADCStop ;
{ ----------------------
  Terminate A/D sampling
  ---------------------- }
begin

     if not FLabInterfaceAvailable then Exit ;
     if not FADCActive then Exit ;

     case FLabInterfaceType of
       NationalInstruments : begin
          NI_StopADC ;
          end ;

       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then DD_StopADC
                                                    else DD98_StopADC ;
          end ;

       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_StopADC ;
          end ;

       Digidata132X : begin
          DD132X_StopADC ;
          end ;

       Instrutech : begin
          ITCMM_StopADC ;
          end ;

       VP500 : begin
          VP500_StopADC ;
          end ;

       NIDAQMX : begin
          NIMX_StopADC ;
          end ;

       Digidata1440 : begin
          DD1440_StopADC ;
          end ;

       Triton : begin
          Triton_StopADC ;
          end ;

       WirelessEEG : begin
          end ;


       end ;
     FADCActive := False ;
     end ;


procedure TSESLabIO.DACStart ;
{ -------------------------
  Start D/A waveform output
  ------------------------- }
begin
     if not FLabInterfaceAvailable then Exit ;

     // Repeated waveform mode not available when trigger mode is tmWaveGen
     if FADCTriggerMode = tmWaveGen then FDACRepeatedWaveform := False ;

     case FLabInterfaceType of
          NationalInstruments : begin
             NI_MemoryToDAC( DACBuf^,
                             FDACNumChannels,
                             FDACNumSamples,
                             FDACUpdateInterval,
                             FDACRepeatedWaveform) ;
             end ;

          Digidata1200 : begin
             if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
                DD_MemoryToDAC( DACBuf^,
                             FDACNumChannels,
                             FDACNumSamples,
                             FStimulusExtTrigger,
                             FADCSamplingInterval,
                             FADCNumChannels,
                             FADCNumSamples )  ;
                end
             else begin
                DD98_MemoryToDAC( DACBuf^,
                             FDACNumChannels,
                             FDACNumSamples,
                             FStimulusExtTrigger,
                             FADCSamplingInterval,
                             FADCNumChannels,
                             FADCNumSamples )  ;
                end ;
             end ;

          CED1401_12, CED1401_16, CED1401_10V : begin
             CED_MemoryToDAC( DACBuf^,
                              FDACNumChannels,
                              FDACNumSamples,
                              FDACUpdateInterval,
                              FADCTriggerMode,
                              FStimulusExtTrigger,
                              FDACRepeatedWaveform
                              ) ;
             end ;

          Digidata132X : begin
             DD132X_MemoryToDACAndDigitalOut( DACBuf^,
                                              FDACNumChannels,
                                              FDACNumSamples,
                                              DigBuf^,
                                              False,
                                              FStimulusExtTrigger ) ;
             end ;

          Instrutech : begin
             ITCMM_MemoryToDACAndDigitalOut( DACBuf^,
                                             FDACNumChannels,
                                             FDACNumSamples,
                                             DigBuf^,
                                             False,
                                             FStimulusExtTrigger ) ;
             end ;

       ITC_16, ITC_18 : begin
             ITC_MemoryToDACAndDigitalOut( DACBuf^,
                                           FDACNumChannels,
                                           FDACNumSamples,
                                           DigBuf^,
                                           False,
                                           FStimulusExtTrigger ) ;
             end ;

       VP500 : begin
             VP500_MemoryToDAC( DACBuf^,
                                FDACNumChannels,
                                FDACNumSamples ) ;
             end ;

       NIDAQMX : begin
             NIMX_MemoryToDAC( DACBuf^,
                               FDACNumChannels,
                               FDACNumSamples,
                               FDACUpdateInterval,
                               FStimulusExtTrigger,
                               FDACRepeatedWaveform) ;
             end ;

       Digidata1440 : begin
             DD1440_MemoryToDACAndDigitalOut( DACBuf^,
                                              FDACNumChannels,
                                              FDACNumSamples,
                                              DigBuf^,
                                              False,
                                              FStimulusExtTrigger ) ;
             end ;

       Triton : begin
             Triton_MemoryToDACAndDigitalOut( DACBuf^,
                                 FDACNumChannels,
                                 FDACNumSamples,
                                 FDACUpdateInterval,
                                 DigBuf^,
                                 False ) ;
             end ;

       WirelessEEG : begin
          end ;
             
          end ;
     FDACActive := True ;
     end ;


procedure TSESLabIO.DACDIGStart(
          StartAt : Integer     { Start Digital O/P at sample }
          ) ;
{ -------------------------
  Start D/A waveform output
  ------------------------- }
begin

     if not FLabInterfaceAvailable then Exit ;

     case FLabInterfaceType of
          NationalInstruments : begin
             NI_MemoryToDig ( DIGBuf,
                              FDACNumSamples,
                              FDACUpdateInterval,
                              DigWork ) ;
             NI_MemoryToDAC( DACBuf^,
                             FDACNumChannels,
                             FDACNumSamples,
                             FDACUpdateInterval,
                             False) ;
             end ;

          Digidata1200 : begin
             if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
                DD_AddDigitalWaveformToDACBuf( DIGBuf^,
                                               FDACNumChannels,
                                               FDACNumSamples) ;
                DD_MemoryToDAC( DACBuf^,
                                FDACNumChannels,
                                FDACNumSamples,
                                FStimulusExtTrigger,
                                FADCSamplingInterval,
                                FADCNumChannels,
                                FADCNumSamples )  ;
                end
             else begin
                DD98_AddDigitalWaveformToDACBuf( DIGBuf^,
                                               FDACNumChannels,
                                               FDACNumSamples) ;
                DD98_MemoryToDAC( DACBuf^,
                                FDACNumChannels,
                                FDACNumSamples,
                                FStimulusExtTrigger,
                                FADCSamplingInterval,
                                FADCNumChannels,
                                FADCNumSamples )  ;
                end ;
             end ;

          CED1401_12, CED1401_16, CED1401_10V : begin
             CED_MemoryToDigitalPort( DIGBuf^,FDACNumSamples,FDACUpdateInterval,
                                      StartAt,FCEDPower1401DIGTIMCountShift) ;
             CED_MemoryToDAC(DACBuf^,
                             FDACNumChannels,
                             FDACNumSamples,
                             FDACUpdateInterval,
                             FADCTriggerMode,
                             FStimulusExtTrigger,
                             False) ;
             end ;

          Digidata132X : begin
             DD132X_MemoryToDACAndDigitalOut( DACBuf^,
                                              FDACNumChannels,
                                              FDACNumSamples,
                                              DigBuf^,
                                              True,
                                              FStimulusExtTrigger ) ;
             end ;

          Instrutech : begin
             ITCMM_MemoryToDACAndDigitalOut( DACBuf^,
                                             FDACNumChannels,
                                             FDACNumSamples,
                                             DigBuf^,
                                             True,
                                             FStimulusExtTrigger ) ;
             end ;

          ITC_16, ITC_18 : begin
             ITC_MemoryToDACAndDigitalOut( DACBuf^,
                                           FDACNumChannels,
                                           FDACNumSamples,
                                           DigBuf^,
                                           True,
                                           FStimulusExtTrigger ) ;
             end ;

          VP500 : begin
             VP500_MemoryToDAC( DACBuf^,
                                FDACNumChannels,
                                FDACNumSamples ) ;
             end ;

          NIDAQMX : begin
             NIMX_MemoryToDig ( DIGBuf^,
                                FDACNumSamples,
                                FDACUpdateInterval,
                                FDACRepeatedWaveform ) ;
             NIMX_MemoryToDAC( DACBuf^,
                               FDACNumChannels,
                               FDACNumSamples,
                               FDACUpdateInterval,
                               FStimulusExtTrigger,
                               FDACRepeatedWaveform ) ;
             end ;

          Digidata1440 : begin
             DD1440_MemoryToDACAndDigitalOut( DACBuf^,
                                              FDACNumChannels,
                                              FDACNumSamples,
                                              DigBuf^,
                                              True,
                                              FStimulusExtTrigger ) ;
             end ;

          Triton : begin
             Triton_MemoryToDACAndDigitalOut( DACBuf^,
                                 FDACNumChannels,
                                 FDACNumSamples,
                                 FDACUpdateInterval,
                                 DigBuf^,
                                 TRue ) ;
             end ;

       WirelessEEG : begin
          end ;

          end ;
     FDACActive := True ;
     FDIGActive := True ;
     end ;



procedure TSESLabIO.DACStop ;
{ ----------------------
  Terminate D/A update
  ---------------------- }
begin

     if not FDACActive then Exit ;

     case FLabInterfaceType of
       NationalInstruments : begin
          NI_StopDAC ;
          if FDIGActive then NI_StopDig ;
          end ;

       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then DD_StopDAC
                                                    else DD98_StopDAC ;
          end ;

       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_StopDAC ;
          if FDIGActive then CED_StopDig ;
          end ;

       Digidata132X : begin
          DD132X_StopDAC ;
          end ;

       Instrutech : begin
          ITCMM_StopDAC ;
          end ;

       ITC_16, ITC_18 : begin
          ITC_StopDAC ;
          end ;

       VP500 : begin
          VP500_StopDAC ;
          end ;

       NIDAQMX : begin
          NIMX_StopDAC ;
          if FDIGActive then NIMX_StopDig ;
          end ;

       Digidata1440 : begin
          DD1440_StopDAC ;
          end ;

       Triton : begin
          Triton_StopDAC ;
          end ;

       WirelessEEG : begin
          end ;

       end ;
     FDACActive := False ;
     FDIGActive := False ;
     end ;


function TSESLabIO.ReadADC(
         Channel : Integer
         ) : Integer ;
{ ----------------------------
  Read A/D on selected channel
  ---------------------------- }
begin

     Result := 0 ;
     if not FLabInterfaceAvailable then Exit ;

     case FLabInterfaceType of
       NationalInstruments : begin
          Result := NI_ReadADC( FADCChannelInputNumber[Channel],
                                FADCChannelVoltageRanges[FADCChannelInputNumber[Channel]],
                                FADCInputMode ) ;
          end ;
       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             Result := DD_ReadADC( Channel, FADCVoltageRanges[FADCVoltageRangeIndex]) ;
             end
          else begin
             Result := DD98_ReadADC( Channel, FADCVoltageRanges[FADCVoltageRangeIndex]) ;
             end ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          Result := CED_ReadADC( Channel ) ;
          end ;
       Digidata132X : begin
          Result := DD132X_ReadADC( Channel ) ;
          end ;

       Instrutech : begin
          Result := ITCMM_ReadADC( Channel ) ;
          end ;

       ITC_16, ITC_18 : begin
          Result := ITC_ReadADC( Channel,
                                 FADCVoltageRanges[FADCVoltageRangeIndex]) ;
          end ;
       VP500 : begin
          Result := VP500_ReadADC( Channel ) ;
          end ;
       NIDAQMX : begin
          Result := NIMX_ReadADC( FADCChannelInputNumber[Channel],
                                  FADCChannelVoltageRanges[FADCChannelInputNumber[Channel]],
                                  FADCInputMode ) ;
          end ;

       Digidata1440 : begin
          Result := DD1440_ReadADC( Channel ) ;
          end ;

       Triton : begin
          Result := Triton_ReadADC( Channel ) ;
          end ;

       WirelessEEG : begin
          end ;

       else Result := 0 ;
       end ;
     end ;


procedure TSESLabIO.WriteDACs(
          DACVolts : Array of single ;
          NumChannels : Integer ) ;
{ -----------------------
  Write to D/A converters
  ----------------------- }
var
   ch : Integer ;
begin

     if not FLabInterfaceAvailable then Exit ;

     { Retain DAC values }
     for ch := 0 to NumChannels-1 do FLastDACVolts[ch] := DACVolts[ch] ;
     FLastDACNumChannels := NumChannels ;

     case FLabInterfaceType of
       NationalInstruments : begin
          NI_WriteDACs( DACVolts, NumChannels ) ;
          end ;
       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
             end
          else begin
             DD98_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
             end ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_WriteDACs( DACVolts, NumChannels ) ;
          end ;
       Digidata132X : begin
          DD132X_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
          end ;
       Instrutech : begin
          ITCMM_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
          end ;
       ITC_16, ITC_18 : begin
          ITC_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
          end ;

       VP500 : begin
          VP500_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
          end ;
       NIDAQMX : begin
          NIMX_WriteDACs( DACVolts, NumChannels ) ;
          end ;

       Digidata1440 : begin
          DD1440_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
          end ;

       Triton: begin
          Triton_WriteDACsAndDigitalPort(FLastDACVolts,FLastDACNumChannels,FLastDigValue) ;
          end ;

       end ;
     end ;


procedure TSESLabIO.GetADCBuffer(
          var BufPointer : PSmallIntArray  { Pointer to A/D data buffer }
          ) ;
{ ---------------------------------------------------
  Return pointer to start of internal A/D data buffer
  --------------------------------------------------- }
begin
     BufPointer := ADCBuf ;
     end ;


procedure TSESLabIO.GetDACBuffer(
          var BufPointer : PSmallIntArray
          ) ;
{ ---------------------------------------------------
  Return pointer to start of internal D/A data buffer
  --------------------------------------------------- }
begin
     BufPointer := DACBuf ;
     end ;


procedure TSESLabIO.GetDIGBuffer(
          var BufPointer : PSmallIntArray
          ) ;
{ -------------------------------------------------------
  Return pointer to start of internal digital data buffer
  ------------------------------------------------------- }
begin
     BufPointer := DigBuf ;
     end ;


procedure TSESLabIO.ADCBufferRefresh ;
{ -------------------------------------------------------
  Return pointer to start of internal digital data buffer
  ------------------------------------------------------- }
begin


   if FTimerProcInUse then Exit ;

   if FStimulusStartTime = StimulusExtTriggerFlag then begin
      // Stimulus triggered by 5V/10ms trigger pulse
      StimulusStartFlag := ExternalStimulusTrigger ;
      end ;

   case FLabInterfaceType of
       NationalInstruments : begin
          end ;
       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_GetADCSamples( ADCBuf^, FOutPointer ) ;
             end
          else begin
             DD98_GetADCSamples( ADCBuf^, FOutPointer ) ;
             end ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          if FADCActive then CED_GetADCSamples( ADCBuf^, FOutPointer ) ;
          end ;
       Digidata132X : begin
          DD132X_GetADCSamples( ADCBuf^, FOutPointer ) ;
          end ;
       Instrutech : begin
          ITCMM_GetADCSamples( ADCBuf, FOutPointer ) ;
          end ;
       ITC_16, ITC_18 : begin
          ITC_GetADCSamples( ADCBuf, FOutPointer ) ;
          end ;
       VP500 : begin
          VP500_GetADCSamples( ADCBuf, FOutPointer ) ;
          end ;
       NIDAQMX : begin
          NIMX_GetADCSamples( ADCBuf^, FOutPointer ) ;
          end ;
       Digidata1440 : begin
          DD1440_GetADCSamples( ADCBuf^, FOutPointer ) ;
          end ;

       Triton : begin
          Triton_GetADCSamples( ADCBuf^, FOutPointer ) ;
          end ;

       WirelessEEG : begin
          WirelessEEG_GetADCSamples( ADCBuf^, FOutPointer ) ;
          end ;

       end ;

     end ;


procedure TSESLabIO.GetLabInterfaceTypes(
          List : TStrings
          ) ;
{ ---------------------------------------------
  Return list of names of laboratory interfaces
  --------------------------------------------- }
var
   i : Integer ;
begin
     List.Clear ;
     for i := 0 to NumLabInterfaceTypes-1 do begin
         List.Addobject(GetLabInterfaceName(i),TObject(i)) ;
         end ;
     end ;


procedure TSESLabIO.GetADCInputModes(
          List : TStrings
          ) ;
{ ---------------------------------------------
  Return list of names of A/D input modes
  --------------------------------------------- }
begin
     List.Clear ;
     case FLabInterfaceType of
       NationalInstruments,NIDAQMX : begin
         List.Add(' Single Ended (NRSE)' ) ;
         List.Add(' Differential' ) ;
         List.Add(' BNC-2110 (Diff)' ) ;
         List.Add(' BNC-2090 (SE)' ) ;
         List.Add(' Single Ended (RSE)') ;
         end ;
       else begin
         List.Add(' Single Ended' ) ;
         end ;
       end ;
     end ;


procedure TSESLabIO.GetDeviceNumbers(
          List : TStrings
          ) ;
// ------------------
// Return device list
// ------------------
begin
     List.Clear ;
     case FLabInterfaceType of
       NationalInstruments : begin
         List.Add(' Device=1' ) ;
         List.Add(' Device=2' ) ;
         List.Add(' Device=3' ) ;
         List.Add(' Device=4' ) ;
         List.Add(' Device=5' ) ;
         end ;
       NIDAQMX : begin
         List.Add(' Dev1' ) ;
         List.Add(' Dev2' ) ;
         List.Add(' Dev3' ) ;
         List.Add(' Dev4' ) ;
         List.Add(' Dev5') ;
         end ;
       else begin
         List.Add(' ' ) ;
         end ;
       end ;
     end ;


{function TSESLabIO.DeviceExists( iDev : Integer ) : Boolean ;
// ----------------------------
// Return TRUE if device exists
// ----------------------------
begin

     case FLabInterfaceType of
       NationalInstruments : Result := NI_DeviceExists( IDev, True ) ;
       NIDAQMX : Result := NIMX_DeviceExists( IDev,true ) ;
       else begin
         Result := True ;
         end ;
       end ;
     end ;}


procedure TSESLabIO.WriteDig(
          DigByte : Integer
          ) ;
{ -------------------------
  Write to digital O/P port
  ------------------------- }
begin
     { Keep digital O/P bits }
     FLastDigValue := DigByte ;

     case FLabInterfaceType of
       NationalInstruments : begin
          NI_WriteToDigitalOutPutPort( DigByte ) ;
          end ;
       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
             end
          else begin
             DD98_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
             end ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_WriteToDigitalOutPutPort( DigByte ) ;
          end ;
       Digidata132X : begin
          DD132X_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
          end ;
       Instrutech : begin
          ITCMM_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
          end ;
       ITC_16, ITC_18 : begin
          ITC_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
          end ;
       VP500 : begin
          VP500_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
          end ;
       NIDAQMX : begin
          NIMX_WriteToDigitalOutPutPort( DigByte ) ;
          end ;
       Digidata1440 : begin
          DD1440_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
          end ;
       Triton : begin
          Triton_WriteDACsAndDigitalPort( FLastDACVolts, FLastDACNumChannels, DigByte ) ;
          end ;

       WirelessEEG : begin
          end ;
          

       end ;
     end ;


procedure TSESLabIO.SetDeviceNumber( DeviceNumber : Integer ) ;
// ------------------
// Set device number
// ------------------
begin
     OpenLabInterface( FLabInterfaceType,
                       DeviceNumber,
                       FADCInputMode ) ;
     end ;


procedure TSESLabIO.SetLabInterfaceType( LabInterfaceType : Integer ) ;
// -----------------------
// Set lab. interface type
// -----------------------
begin

     OpenLabInterface( LabInterfaceType,
                       FDeviceNumber,
                       FADCInputMode ) ;

     end ;


procedure TSESLabIO.SetADCNumChannels( Value : Integer ) ;
// ---------------------------------
// Set the number A/D input channels
// ---------------------------------
begin

     FADCNumChannels := IntLimit(Value,1,FADCMaxChannels) ;

     // Ensure sampling interval remains valid
     SetADCSamplingInterval( FADCSamplingInterval ) ;

     { Create array of integer offsets for location of each A/D channel
       within sample data block }
     case FLabInterfaceType of
       NationalInstruments : begin
          NI_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
             end
          else begin
             DD98_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
             end ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       Digidata132X : begin
          DD132X_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       Instrutech : begin
          ITCMM_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       ITC_16, ITC_18 : begin
          ITC_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       VP500 : begin
          FADCNumChannels := 2 ; // Fixed at 2 channels
          VP500_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       NIDAQMX : begin
          NIMX_GetChannelOffsets( FADCInputMode,
                                  FADCChannelOffset,
                                  FADCNumChannels ) ;
          end ;
       Digidata1440 : begin
          DD1440_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;
       Triton : begin
          FADCNumChannels := Max(FADCNumChannels,2) ; // Must be at least 2 channels
          Triton_GetChannelOffsets( FADCChannelOffset, FADCNumChannels ) ;
          end ;

       WirelessEEG : begin
          end ;

       end ;

     end ;


procedure TSESLabIO.SetADCNumSamples( Value : Integer ) ;
// -------------------------------------------------
// Set no. of A/D samples per channel to be acquired
// -------------------------------------------------
begin
     FADCNumSamples := IntLimit(Value,1,FADCBufferLimit div FADCNumChannels) ;
     end ;


procedure TSESLabIO.SetADCSamplingInterval( Value : Double ) ;
// -------------------------
// Set A/D sampling interval
// -------------------------
var
   TimeBase : SmallInt ;
   PreScale,ClockTicks,FrequencySource : Word ;
   DD_Ticks : Cardinal ;
begin

     FADCSamplingInterval := Value ;

     // Keep within valid hardware limits
 //    FADCSamplingInterval := FADCNumChannels*FloatLimit( FADCSamplingInterval/FADCNumChannels,
 //                                                        FADCMinSamplingInterval,
//                                                         FADCMaxSamplingInterval) ;

     case FLabInterfaceType of
       NationalInstruments : begin

          NI_CheckSamplingInterval( FADCSamplingInterval,
                                    FADCNumChannels,
                                    TimeBase,ClockTicks);

          end ;
       Digidata1200 : begin
          FADCSamplingInterval := FADCSamplingInterval / FADCNumChannels ;
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          if Win32Platform = VER_PLATFORM_WIN32_NT  then begin
             DD_CheckSamplingInterval(FADCSamplingInterval,DD_Ticks,FrequencySource);
             end
          else begin
             DD98_CheckSamplingInterval(FADCSamplingInterval,DD_Ticks,FrequencySource);
             end ;
          FADCSamplingInterval := FADCSamplingInterval * FADCNumChannels ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          FADCSamplingInterval := FADCSamplingInterval / FADCNumChannels ;
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          CED_CheckSamplingInterval(FADCSamplingInterval,PreScale,ClockTicks);
          FADCSamplingInterval := FADCSamplingInterval * FADCNumChannels ;
          end ;
       Digidata132X : begin
          FADCSamplingInterval := FADCSamplingInterval / FADCNumChannels ;
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          DD132X_CheckSamplingInterval(FADCSamplingInterval,DD_Ticks);
          FADCSamplingInterval := FADCSamplingInterval * FADCNumChannels ;
          end ;
       Instrutech : begin
          ITCMM_CheckSamplingInterval(FADCSamplingInterval,DD_Ticks);
          end ;
       ITC_16, ITC_18 : begin
          FADCSamplingInterval := FADCSamplingInterval / FADCNumChannels ;
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          ITC_CheckSamplingInterval(FADCSamplingInterval,DD_Ticks);
          FADCSamplingInterval := FADCSamplingInterval * FADCNumChannels ;
          end ;
       VP500 : begin
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          VP500_CheckSamplingInterval(FADCSamplingInterval);
          end ;
       NIDAQMX : begin
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval*FADCNumChannels),
                                            FADCMaxSamplingInterval*FADCNumChannels) ;
          NIMX_CheckADCSamplingInterval(FADCSamplingInterval,FADCNumChannels,FADCInputMode);
          end ;
       Digidata1440 : begin
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          DD1440_CheckSamplingInterval(FADCSamplingInterval);
          end ;
       Triton : begin
          FADCSamplingInterval := Min( Max( FADCSamplingInterval,
                                            FADCMinSamplingInterval),
                                            FADCMaxSamplingInterval) ;
          Triton_CheckSamplingInterval(FADCSamplingInterval);
          end ;

       WirelessEEG : begin
          WirelessEEG_CheckSamplingInterval( FADCSamplingInterval) ;
          end ;
          

       end ;

     end ;


procedure TSESLabIO.SetADCVoltageRangeIndex( Value : Integer ) ;
// ------------------------------
// Set A/D voltage range by index
// ------------------------------
var
   i : Integer ;
begin

     FADCVoltageRangeIndex := IntLimit(Value,0,FADCNumVoltageRanges-1) ;

     // Set all channels to this value
     for i := 0 to MaxADCChannels-1 do
         FADCChannelVoltageRanges[i] := FADCVoltageRanges[FADCVoltageRangeIndex] ;

     end ;


procedure TSESLabIO.SetADCVoltageRange( Value : Single ) ;
// ---------------------------------------------------------
// Set A/D input voltage range of all channels to same value
// ---------------------------------------------------------
var
   i : Integer ;
begin

     // Get nearest valid range
     for i := 0 to FADCNumVoltageRanges-1 do begin
         if Abs(FADCVoltageRanges[i] - Value) <  0.01 then FADCVoltageRangeIndex := i ;
         end ;

     // Set all channels to this value
     for i := 0 to High(FADCChannelVoltageRanges) do
         FADCChannelVoltageRanges[i] := FADCVoltageRanges[FADCVoltageRangeIndex] ;

     end ;


function TSESLabIO.GetADCVoltageRange : Single ;
// ----------------------------
// Read A/D input voltage range
// ----------------------------
begin
     Result := FADCVoltageRanges[FADCVoltageRangeIndex] ;
     end ;

function TSESLabIO.GetDACVoltageRange(Chan : Integer) : Single ;
// -----------------------------------------
// Read D/A output voltage range upper limit
// -----------------------------------------
begin
     case FLabInterfaceType of
        Triton : Result := Triton_GetMaxDACVolts(Chan) ;
        else begin
           Result := FDACVoltageRange ;
           end ;
        end ;
     end ;



function TSESLabIO.GetADCChannelOffset(
         Channel : Integer
         ) : Integer ;
{ --------------------------------------------------------------------------
  Get offset within multi-channel sample data block for selected A/D channel
  -------------------------------------------------------------------------- }
begin
     Channel := IntLimit( Channel, 0, High(FADCChannelOffset) ) ;
     Result := FADCChannelOffset[Channel] ;
     end ;


function TSESLabIO.GetADCChannelVoltageRange(
         Channel : Integer
         ) : Single ;
{ -------------------------------------------------
  Get A/D input voltage range for selected channel
  ------------------------------------------------- }
begin
     Channel := IntLimit( Channel, 0,  MaxADCChannels-1 ) ;
     Result := FADCChannelVoltageRanges[Channel] ;
     end ;


procedure TSESLabIO.SetADCChannelVoltageRange(
         Channel : Integer ;                   // Channel to be updated
         Value : Single                        // New A/D voltage range
         ) ;
{ -------------------------------------------------
  Set A/D input voltage range for selected channel
  ------------------------------------------------- }
var
    i : Integer ;
begin

     // Get nearest valid range
     for i := 0 to FADCNumVoltageRanges-1 do begin
         if Abs(FADCVoltageRanges[i] - Value) <  0.01 then FADCVoltageRangeIndex := i ;
         end ;

     // Set selected A/D channel
     Channel := IntLimit( Channel, 0, MaxADCChannels-1 ) ;
     FADCChannelVoltageRanges[Channel] := FADCVoltageRanges[FADCVoltageRangeIndex] ;

     end ;


procedure TSESLabIO.GetADCVoltageRanges(
          var Ranges : Array of Single ;
          var NumRanges : Integer ) ;
// --------------------------------------------------
// Return array of available A/D input voltage ranges
// --------------------------------------------------
var
    i : Integer ;
begin
    for i := 0 to Min(FADCNumVoltageRanges-1,High(Ranges)) do
        Ranges[i] := FADCVoltageRanges[i] ;
    NumRanges := Min(FADCNumVoltageRanges,High(Ranges)+1) ;
    end ;


function TSESLabIO.GetADCChannelName( Chan : Integer ): String ;
//
// Get A/D channel name
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelName[Chan] ;
    end ;


function TSESLabIO.GetADCChannelUnits( Chan : Integer ): String ;
//
// Get A/D channel units
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelUnits[Chan] ;
    end ;


function TSESLabIO.GetADCChannelVoltsPerUnits( Chan : Integer ) : Single ;
//
// Get base scale factor of A/D channel signal (Volts per Unit)
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelVoltsPerUnits[Chan] ;
    end ;


function TSESLabIO.GetADCChannelGain( Chan : Integer ) : Single ;
//
// Get amplifier gain of A/D channel
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelGain[Chan] ;
    end ;


function TSESLabIO.GetADCChannelZero( Chan : Integer ) : Integer ;
//
// Get zero level of A/D channel
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelZero[Chan] ;
    end ;


function TSESLabIO.GetADCChannelZeroAt( Chan : Integer ) : Integer ;
//
// Get source of zero level of A/D channel (-1
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelZeroAt[Chan] ;
    end ;


function TSESLabIO.GetADCChannelVisible( Chan : Integer ) : Boolean ;
//
// Get A/D channel display flag
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelVisible[Chan] ;
    end ;


function TSESLabIO.GetADCChannelYMin( Chan : Integer ) : Single ;
//
// Get display lower limit for channel
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelYMin[Chan] ;
    end ;


function TSESLabIO.GetADCChannelYMax( Chan : Integer ) : Single ;
//
// Get display upper limit for channel
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelYMax[Chan] ;
    end ;


function TSESLabIO.GetADCChannelInputNumber( Chan : Integer ) : Integer ;
// -----------------------------------------------------------
// Get actual analog input number for selected logical channel
// -----------------------------------------------------------
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelInputNumber[Chan] ;
    end ;


function TSESLabIO.GetADCChannelUnitsPerBit( Chan : Integer ) : Single ;
//
// Get conversion factor from ADC value to A/D channel units (Units/bit)
//
begin
    Chan := Min(Max(0,Chan),MaxADCChannels-1) ;
    Result := FADCChannelUnitsPerBit[Chan] ;
    end ;


procedure TSESLabIO.SetADCChannelName( Chan : Integer ; Value : String ) ;
// ---------------------
// Set A/D channel Name
// ---------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelName[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelUnits( Chan : Integer ; Value : String ) ;
// ---------------------
// Set A/D channel units
// ---------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelUnits[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelVoltsPerUnits( Chan : Integer ; Value : Single ) ;
// ------------------------------
// Set A/D channel Volts per unit
// ------------------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       if Value = 0.0 then Value := 1.0 ;
       FADCChannelVoltsPerUnits[Chan] := Value ;
       FADCChannelUnitsPerBit[Chan] :=
            FADCChannelVoltageRanges[Chan] /
            (FADCChannelVoltsPerUnits[Chan]*FADCChannelGain[Chan]*(FADCMaxValue+1)) ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelGain( Chan : Integer ; Value : Single ) ;
// ---------------------
// Set A/D channel gain
// ---------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       if Value = 0.0 then Value := 1.0 ;
       if Abs(FADCChannelGain[Chan]) < 1E-10 then FADCChannelGain[Chan] := 1.0 ;
       if FADCMaxValue = 0 then FADCMaxValue := 2047 ;
       FADCChannelGain[Chan] := Value ;
       FADCChannelUnitsPerBit[Chan] :=
            FADCChannelVoltageRanges[Chan] /
            (FADCChannelVoltsPerUnits[Chan]*FADCChannelGain[Chan]*(FADCMaxValue+1)) ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelZero( Chan : Integer ; Value : Integer ) ;
// --------------------------
// Set A/D channel zero level
// --------------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelZero[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelZeroAt( Chan : Integer ; Value : Integer ) ;
// --------------------------
// Set A/D channel zero level
// --------------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelZeroAt[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelUnitsPerBit( Chan : Integer ; Value : Single ) ;
// -----------------------------
// Set A/D channel units per bit
// -----------------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelUnitsPerBit[Chan] := Value ;
       FADCChannelVoltsPerUnits[Chan] :=
            FADCChannelVoltageRanges[Chan] /
            (FADCChannelUnitsPerBit[Chan]*FADCChannelGain[Chan]*(FADCMaxValue+1)) ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelVisible( Chan : Integer ; Value : Boolean ) ;
// -----------------------------
// Set A/D channel on display flag
// -----------------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelVisible[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelYMin( Chan : Integer ; Value : Single ) ;
// ---------------------
// Set display lower limit for channel
// ---------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelYMin[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelYMax( Chan : Integer ; Value : Single ) ;
// ---------------------
// Set display upper limit for channel
// ---------------------
begin
    if (Chan >= 0) and (Chan < MaxADCChannels) then begin
       FADCChannelYMax[Chan] := Value ;
       end ;
    end ;


procedure TSESLabIO.SetADCChannelInputNumber( Chan : Integer ; Value : Integer ) ;
// -----------------------------------------------------------
// Set actual analog input number for selected logical channel
// -----------------------------------------------------------
begin

     if (Chan >= 0) and (Chan < MaxADCChannels) then begin
        case FLabInterfaceType of
            NationalInstruments,NIDAQMX : FADCChannelInputNumber[Chan] :=
                                            Max(Min(FADCMaxChannels-1,Value),0) ;
            else FADCChannelInputNumber[Chan] := Chan ;
            end ;
        end ;

    end ;



procedure TSESLabIO.SetADCInputMode( Value : Integer ) ;
// ------------------
// Set A/D input mode
// ------------------

begin

     case FLabInterfaceType of
        NationalInstruments,NIDAQMX : begin
           OpenLabInterface( FLabInterfaceType,
                             FDeviceNumber,
                             Value ) ;
           end ;
        else FADCInputMode := imSingleEnded ;
        end ;
     end ;


procedure TSESLabIO.SetDACNumChannels( Value : Integer ) ;
// -----------------------------------------------------
// Set the number of D/A output channels in the waveform
// -----------------------------------------------------
begin
     FDACNumChannels := IntLimit(Value,1,FDACMaxChannels) ;
     end ;


procedure TSESLabIO.SetDACNumSamples( Value : Integer ) ;
// ------------------------------------------------------------------
// Set the number of D/A output samples (per channel) in the waveform
// ------------------------------------------------------------------
begin
     FDACNumSamples := IntLimit(Value,1,FDACBufferLimit div FDACNumChannels) ;
     end ;


procedure TSESLabIO.SetDACUpdateInterval( Value : Double ) ;
// ------------------------------------
// Set the D/A waveform update interval
// ------------------------------------
var
   PreScale,ClockTicks : Word ;
begin

     FDACUpdateInterval := Max(Value,FDACMinUpdateInterval) ;

     case FLabInterfaceType of
       NationalInstruments : begin
          // NOTE. This code ensures that D/A update interval is fixed at 10 ms
          // when a digital stimulus pattern is being outputed using an E-series board 17.7.02
          if FStimulusDigitalEnabled then begin
             FDACUpdateInterval := FloatLimit( FDACUpdateInterval,
                                               FDigMinUpdateInterval,
                                               FDigMaxUpdateInterval) ;
             end
          else
             NI_CheckDACUpdateInterval(FDACUpdateInterval,FDACNumChannels) ;
          end ;
       Digidata1200 : begin
          FDACUpdateInterval := (FADCSamplingInterval*FDACNumChannels)/FADCNumChannels ;
          //DD_CheckSamplingInterval(FDACUpdateInterval,DD_Ticks,FrequencySource);
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          CED_CheckSamplingInterval(FDACUpdateInterval,PreScale,ClockTicks);
          end ;
       Digidata132X : begin
          FDACUpdateInterval := FADCSamplingInterval ;
          if FStimulusDigitalEnabled then begin
             FDACUpdateInterval := (FADCSamplingInterval*(FDACNumChannels+1))/FADCNumChannels ;
             end
          else begin
             FDACUpdateInterval := (FADCSamplingInterval*FDACNumChannels)/FADCNumChannels ;
             end ;
          end ;
       Instrutech : begin
          FDACUpdateInterval := FADCSamplingInterval ;
          end ;
       ITC_16, ITC_18 : begin
          FDACUpdateInterval := FADCSamplingInterval ;
          end ;
       VP500 : begin
          FDACUpdateInterval := FADCSamplingInterval ;
          end ;
       NIDAQMX : begin
          NIMX_CheckDACSamplingInterval(FDACUpdateInterval, FDACNumChannels ) ;
          end ;
       Digidata1440 : begin
          FDACUpdateInterval := FADCSamplingInterval ;
     {     if FStimulusDigitalEnabled then begin
             FDACUpdateInterval := (FADCSamplingInterval*(FDACNumChannels+1))/FADCNumChannels ;
             end
          else begin
             FDACUpdateInterval := (FADCSamplingInterval*FDACNumChannels)/FADCNumChannels ;
             end ;      }
          end ;

       Triton : begin
          Triton_CheckSamplingInterval(FADCSamplingInterval) ;
          FDACUpdateInterval := FADCSamplingInterval ;
          end ;
          
       WirelessEEG : begin
          end ;

       end ;
     end ;


function TSESLabIO.GetDIGInputs : Integer ;
// ---------------------------
// Get digital input port bits
// ---------------------------
var
     Bits : Integer ;
begin

     Bits := 0 ;

     case FLabInterfaceType of
       NationalInstruments : begin
          Bits := NI_ReadDigitalInputPort ;
          end ;
       Digidata1200 : begin
          if Win32Platform = VER_PLATFORM_WIN32_NT  then Bits := DD_ReadDigitalInputPort
                                                    else Bits := DD98_ReadDigitalInputPort ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          Bits := CED_ReadDigitalInputPort ;
          end ;
       Digidata132X : begin
          end ;
       Instrutech : begin
          end ;
       ITC_16, ITC_18 : begin
          end ;
       VP500 : begin
          end ;
       NIDAQMX : begin
          Bits := NIMX_ReadDigitalInputPort ;
          end ;
       Digidata1440 : begin
          end ;

       Triton : begin
          end ;

       WirelessEEG : begin
          end ;
          
       end ;
     Result := Bits ;
     end ;


function TSESLabIO.GetDACHoldingVoltage( Chan : Integer ) : Single ;
// --------------------------------------
// Return holding voltage for D/A channel
// --------------------------------------
begin
    if (Chan >= 0) and (Chan < FDACMaxChannels) then begin
       Result := FDACHoldingVoltage[Chan] ;
       end
    else Result := 0.0 ;
    end ;


procedure TSESLabIO.SetDACHoldingVoltage( Chan : Integer ; Value : Single ) ;
// --------------------------------------
// Set holding voltage for D/A channel
// --------------------------------------
begin
    if (Chan >= 0) and (Chan < High(FDACHoldingVoltage)) then begin
       FDACHoldingVoltage[Chan] := Value ;
       if not FDACActive then WriteDACS( FDACHoldingVoltage, FDACMaxChannels ) ;
       end ;
    end ;


function TSESLabIO.GetDIGHoldingLevel : Integer ;
// --------------------------------------
// Return digital output holding voltage
// --------------------------------------
begin
    Result := FDIGHoldingLevel ;
    end ;


procedure TSESLabIO.SetDIGHoldingLevel( Value : Integer ) ;
// --------------------------------------
// Set holding voltage for D/A channel
// --------------------------------------
begin
       FDIGHoldingLevel := Value ;
       if not FDIGActive then WriteDIG( FDIGHoldingLevel ) ;
       end ;


procedure TSESLabIO.SetStimulusTimerPeriod(
          Value : Single // Timer interval (s)
          ) ;
// -----------------------------------------
// Set time interval between stimulus pulses
// -----------------------------------------
var
    OldStimulusStartTime : Integer ;
begin

     // Note. Value = StimulusExtTriggerFlag indicates that the start of the
     // stimulus waveform is triggered by a digital input pulse
     if Value = StimulusExtTriggerFlag then begin
        FStimulusStartTime := Round(Value) ;
        FStimulusExtTrigger := True ;
        case FLabInterfaceType of
             NationalInstruments : NI_ArmStimulusTriggerInput ;
             CED1401_12, CED1401_16, CED1401_10V : CED_ArmStimulusTriggerInput ;
             //NIDAQMX : NIMX_ArmStimulusTriggerInput ;
             end ;
        end
     else begin
        // Timed stimulus start
        OldStimulusStartTime := FStimulusStartTime ;
        FStimulusStartTime := Round((Value*1E3)/StimulusTimerTickInterval) ;
        // Clear timer tick counter if timer period has changed
        // (This ensures that a full inter-pulse period occurs
        //  when the inter record interval is changed 20.08.06)
        if FStimulusStartTime <> OldStimulusStartTime then begin
           FStimulusTimerTicks := 0 ;
           end ;

        FStimulusExtTrigger := False ;
        end ;
     StimulusStartFlag := False ;
     end ;


function TSESLabIO.GetStimulusTimerPeriod : Single ;
// -----------------------------------------
// Get time interval between stimulus pulses
// -----------------------------------------
begin
     Result := FStimulusStartTime*StimulusTimerTickInterval*1E-3 ;
     end ;


procedure TSESLabIO.StartTimer ;
// ------------------------------
// Start periodic stimulus timer
// -----------------------------
begin

     if FStimulusTimerActive then begin
        timeKillEvent( FStimulusTimerID ) ;
        FStimulusTimerActive := False ;
        end ;

     // Set to maximum value to force immediate stimulus pulse
     FStimulusTimerTicks := High(FStimulusTimerTicks) ;

     // Start clock
     FStimulusTimerID := TimeSetEvent( StimulusTimerTickInterval,
                                       StimulusTimerTickInterval,
                                       @TimerProc,
                                       Cardinal(Self),
                                       TIME_PERIODIC ) ;

     FStimulusTimerActive := True ;
     end ;


procedure TSESLabIO.StopTimer ;
// ----------------------------
// Stop periodic stimulus timer
// ----------------------------
begin

     if FStimulusTimerActive then begin
        timeKillEvent( FStimulusTimerID ) ;
        FStimulusTimerActive := False ;
        end ;

     // Ensure external stimulus trigger flag is cleared
     FStimulusExtTrigger := False ;

     end ;


procedure TSESLabIO.TimerTickOperations ;
// ---------------------------------------------
// Operations to be carried out every timer tick
// ---------------------------------------------
begin
     case FLabInterfaceType of
       NationalInstruments : begin
          NI_UpdateDigOutput ;
          end ;
       end ;

     end ;


function TSESLabIO.ExternalStimulusTrigger : Boolean ;
// -----------------------------------------
// Read external stimulus trigger line state
// -----------------------------------------
var
     Triggered : Boolean ;
begin

     Triggered := False ;
     case FLabInterfaceType of
       NationalInstruments : begin
          Triggered := NI_StimulusTriggerInputState ;
          end ;
       Digidata1200 : begin
          // Bit 0 of digital I/P port used as trigger
          // (Note bit 0 must be high for more than 10 ms)
          //if (DD_ReadDigitalInputPort and 1) <> 0 then Triggered := True ;
          Triggered := True ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          Triggered := CED_StimulusTriggerInputState ;
          end ;
       Digidata132X : begin
          Triggered := True ;         // Triggering handled by DD132X_MemoryToDAC
          end ;
       Instrutech : begin
          Triggered := True ;         // Triggering handled by ITCMM_MemoryToDAC
          end ;
       ITC_16, ITC_18 : begin
          Triggered := True ;         // Triggering handled by ITC16_MemoryToDAC
          end ;

       VP500 : begin
          Triggered := True ;         // Not implemented
          end ;

       NIDAQMX : begin
          //Triggered := NIMX_StimulusTriggerInputState ;
          Triggered := True ;
          end ;

       Digidata1440 : begin
          Triggered := True ;         // Triggering handled by DD132X_MemoryToDAC
          end ;

       Triton : begin
          Triggered := True ;
          end ;

       WirelessEEG : begin
          end ;
          
       end ;

     Result := Triggered ;
     end ;



procedure TimerProc(
          uID,uMsg : SmallInt ; User : TSESLabIO ; dw1,dw2 : LongInt ) ; stdcall ;
{ ----------------------------------------------
  Timer scheduled events, called a 10ms intervals
  ---------------------------------------------- }
begin

   if User.FTimerProcInUse then Exit ;
   User.FTimerProcInUse := True ;


   if User.FStimulusStartTime <> StimulusExtTriggerFlag then begin
      // Stimulus output at timed intervals
      // ----------------------------------
      if (User.FStimulusTimerTicks >= User.FStimulusStartTime) then begin
         // Save time that this stimulus pulse started
         User.FStimulusTimeStarted := GetTickCount*0.001 ;
         { Reset counter for next sweep }
         User.FStimulusTimerTicks := 0 ;
         User.StimulusStartFlag := True ;
         end
      else begin
         { Increment voltage program inter-pulse timer (10ms ticks) }
         Inc(User.FStimulusTimerTicks) ;
         end ;
      end ;

   // Call operations to be run on each timer tick
   User.TimerTickOperations ;

   User.FTimerProcInUse := False ;

   end ;


procedure TSESLabIO.StartStimulus ;
// -----------------------------------------
// Start D/A and digital waveform generation
// -----------------------------------------
begin

      if StimulusStartFlag = False then Exit ;

      if FStimulusDigitalEnabled then DACDIGStart( FStimulusStartOffset )
      else DACStart ;

      StimulusStartFlag := False ;

      end ;


function  TSESLabIO.GetDACTriggerOnLevel : Integer ;
// ------------------------------------------------------
// Returns DAC ON level for recording sweep trigger pulse
// ------------------------------------------------------
begin
     if FDACInvertTriggerLevel then Result := FDACTriggerOffLevel
                               else Result := FDACTriggerOnLevel ;
     end ;


function  TSESLabIO.GetDACTriggerOffLevel : Integer ;
// ------------------------------------------------------
// Returns DAC OFF level for recording sweep trigger pulse
// ------------------------------------------------------
begin
     if FDACInvertTriggerLevel then Result := FDACTriggerOnLevel
                               else Result := FDACTriggerOffLevel ;
     end ;


procedure TSESLabIO.SetADCExternalTriggerActiveHigh(
          Value : Boolean ) ;
// ------------------------------------------------------------------------
// Set External Trigger input Active High (Value=TRUE) or Low (Value=False)
// ------------------------------------------------------------------------
begin

     case FLabInterfaceType of
       NationalInstruments : begin
          FADCExternalTriggerActiveHigh := NI_GetValidExternalTriggerPolarity(Value) ;
          end ;
       Digidata1200 : begin
          FADCExternalTriggerActiveHigh := True ;
          end ;
       CED1401_12, CED1401_16, CED1401_10V : begin
          FADCExternalTriggerActiveHigh := Value ;
          end ;
       Digidata132X : begin
          FADCExternalTriggerActiveHigh := True ;
          end ;
       Instrutech : begin
          FADCExternalTriggerActiveHigh := Value ;
          end ;
       ITC_16, ITC_18 : begin
          FADCExternalTriggerActiveHigh := True ;
          end ;

       VP500 : begin
          FADCExternalTriggerActiveHigh := True ;
          end ;

       NIDAQMX : begin
          FADCExternalTriggerActiveHigh := NIMX_GetValidExternalTriggerPolarity(Value) ;
          end ;
       Digidata1440 : begin
          FADCExternalTriggerActiveHigh := True ;
          end ;

       Triton : begin
          FADCExternalTriggerActiveHigh := True ;
          end ;

       WirelessEEG : begin
          end ;

       end ;
     end ;


function  TSESLabIO.IntLimit(
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


function  TSESLabIO.FloatLimit(
          Value : Single ;
          LoLimit : Single ;
          HiLimit : Single
          ) : Single ;
{ --------------------------------------------------------------------
  Return floating point Value constrained within range LoLimit-HiLimit
  -------------------------------------------------------------------- }
begin
     if Value > HiLimit then Value := HiLimit ;
     if Value < LoLimit then Value := LoLimit ;
     Result := Value ;
     end ;

procedure TSESLabIO.DisableDMA_LabPC ;
begin
     case FLabInterfaceType of
       NationalInstruments : NI_DisableDMA_LabPC ;
       end ;
     end ;


procedure TSESLabIO.TritonGetRegProperties(
          Reg : Integer ;
          var VMin : Single ;   // Lower limit of register values
          var VMax : Single ;   // Upper limit of register values
          var VStep : Single ;   // Smallest step size of values
          var CanBeDisabled : Boolean ; // Register can be disabled
          var Supported : Boolean       // Register is supported by hardware
          ) ;
// -------------------------------------------------------
// Get properties of selected patch clamp control register
// -------------------------------------------------------
begin

     case FLabInterfaceType of
       Triton : TritonGetRegisterProperties( Reg, VMin, VMax, VStep, CanBeDisabled,Supported ) ;
       end ;
     end ;


procedure TSESLabIO.TritonGetReg(
          Reg : Integer ;
          Chan : Integer ;
          var Value : Single ;
          var PercentValue : Single ;
          var Units : String ;
          var Enabled : Boolean ) ;
var
    dbVal,dbPercentVal : Double ;
begin
     dbVal := 0.0 ;
     dbPercentVal := 0.0 ;
     case FLabInterfaceType of
       Triton : TritonGetRegister( Reg, Chan, dbVal, dbPercentVal, Units,Enabled ) ;
       end ;
     Value := dbVal ;
     PercentValue := dbPercentVal ;

     end ;


procedure TSESLabIO.TritonSetRegPercent(
          Reg : Integer ;
          Chan : Integer ;
          var PercentValue : Single ) ;
var
    DbValue : Double ;
begin
     DbValue := PercentValue ;
     case FLabInterfaceType of
       Triton : TritonSetRegisterPercent( Reg, Chan, DbValue ) ;
       end ;
     end ;


function TSESLabIO.TritonGetRegEnabled(
          Reg : Integer ;
          Chan : Integer ) : Boolean ;
// ---------------------------------------------
// Get enabled/disabled state of Triton register
// ---------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Result := TritonGetRegisterEnabled( Reg, Chan ) ;
       else Result := False ;
       end ;
     end ;


procedure TSESLabIO.TritonSetRegEnabled(
              Reg : Integer ;
              Chan : Integer ;
              Enabled : Boolean ) ;
// ---------------------------------------------
// Set enabled/disabled state of Triton register
// ---------------------------------------------
begin
     case FLabInterfaceType of
       Triton : TritonSetRegisterEnabled( Reg, Chan, Enabled ) ;
       end ;
     end ;

procedure TSESLabIO.SetTritonSource(
         Chan : Integer ;                   // Channel to be updated
         Value : Integer                       // New source
         ) ;
// -------------------------------------------------
//  Set Triton patch clamp input source for selected channel
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : TritonSetSource( Chan, Value ) ;
       end ;
     end ;


function TSESLabIO.GetTritonSource(
         Chan : Integer                        // New source
         ) : Integer ;
// -------------------------------------------------
//  Get Triton patch clamp input source for selected channel
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Result := TritonGetSource( Chan ) ;
       else Result := 0 ;
       end ;
     end ;


procedure TSESLabIO.SetTritonGain(
         Chan : Integer ;                   // Channel to be updated
         Value : Integer                       // New source
         ) ;
// -------------------------------------------------
//  Set Triton patch clamp gain for selected channel
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : TritonSetGain( Chan, Value ) ;
       end ;
     end ;


function TSESLabIO.GetTritonGain(
         Chan : Integer                        // New gain
         ) : Integer ;
// -------------------------------------------------
//  Get Triton patch clamp gain for selected channel
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Result := TritonGetGain( Chan ) ;
       else Result := 0 ;
       end ;
     end ;


procedure TSESLabIO.SetTritonUserConfig(
         Config : Integer         // Config number
         ) ;
// ------------------------
//  Set Triton user config
// ------------------------
begin
     case FLabInterfaceType of
       Triton : TritonSetUserConfig( Config ) ;
       end ;
     end ;


function TSESLabIO.GetTritonUserConfig(
         ) : Integer ;
// ------------------------
//  Get Triton user config
// ------------------------
begin
     case FLabInterfaceType of
       Triton : Result := TritonGetUserConfig ;
       else Result := 0 ;
       end ;
     end ;


procedure TSESLabIO.SetTritonDACStreamingEnabled(
          Enabled : Boolean ) ;
// ------------------------
//  Set Triton DAC streaming
// ------------------------
begin
     case FLabInterfaceType of
       Triton : TritonSetDACStreamingEnabled( Enabled ) ;
       end ;
     end ;


function TSESLabIO.GetTritonDACStreamingEnabled : Boolean ;
// ------------------------
//  Get Triton user config
// ------------------------
begin
     case FLabInterfaceType of
       Triton : Result := TritonGetDACStreamingEnabled ;
       else Result := False ;
       end ;
     end ;


procedure TSESLabIO.SetTritonBesselFilter(
         Chan : Integer ;                   // Channel to be updated
         Value : Integer ;                   // New source
         var CutOffFrequency : Single
         ) ;
// -------------------------------------------------
//  Set Triton patch clamp low pass filter for selected channel
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : TritonSetBesselFilter( Chan, Value, CutOffFrequency ) ;
       end ;
     end ;

function TSESLabIO.GetTritonNumChannels : Integer ;
// -----------------------------------------
// Get Triton number of patch clamp channels
// -----------------------------------------
begin
     case FLabInterfaceType of
       Triton : Result := TritonGetNumChannels ;
       else Result := 1 ;
       end ;
     end ;


procedure TSESLabIO.TritonAutoArtefactRemovalEnable( Enabled : Boolean ) ;
// -------------------------------------
// Enable/disable auto arterfact removal
// -------------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_AutoArtefactRemovalEnable(Enabled) ;
       end ;
    end ;


procedure TSESLabIO.TritonDigitalLeakSubtractionEnable( Chan : Integer ; Enabled : Boolean ) ;
// -------------------------------------
// Enable/disable digital leak subtraction
// -------------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_DigitalLeakSubtractionEnable(Chan,Enabled) ;
       end ;
    end ;


procedure TSESLabIO.TritonAutoCompensation(
          UseCFast  : Boolean ;
          UseCslowA  : Boolean ;
          UseCslowB : Boolean ;
          UseCslowC : Boolean ;
          UseCslowD : Boolean ;
          UseAnalogLeakCompensation : Boolean ;
          UseDigitalLeakCompensation : Boolean ;
          UseDigitalArtefactSubtraction : Boolean ;
          CompensationCoeff : Single ;
          VHold : Single ;
          THold : Single ;
          VStep : Single ;
          TStep : Single
          ) ;
// -------------------------------------------------
//  Set Triton patch clamp compensation
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : TritonAutoCompensate( UseCFast,
                                      UseCslowA,
                                      UseCslowB,
                                      UseCslowC,
                                      UseCslowD,
                                      UseAnalogLeakCompensation,
                                      UseDigitalLeakCompensation,
                                      UseDigitalArtefactSubtraction,
                                      CompensationCoeff,
                                      VHold,
                                      VStep,
                                      VStep,
                                      TStep ) ;
       end ;
     end ;


procedure TSESLabIO.TritonJPAutoZero ;
// -------------------------------------------------
//  Set Triton junction potential zero
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : TritonJP_AutoZero ;
       end ;
     end ;


procedure TSESLabIO.TritonZap(
              Duration : Double ;
              Amplitude : Double ;
              ChanNum : Integer
              ) ;
// -------------------------------------------------
//  Zap selected channel
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_Zap( Duration, Amplitude, ChanNum ) ;
       end ;
     end ;


procedure TSESLabIO.TritonGetSourceList( cbSourceList : TStrings ) ;
// -------------------------------------------------
//  Get Triton source list
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_GetSourceList( cbSourceList ) ;
       end ;
     end ;

procedure TSESLabIO.TritonGetGainList( cbGainList : TStrings ) ;
// -------------------------------------------------
//  Get Triton source list
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_GetGainList( cbGainList ) ;
       end ;
     end ;


procedure TSESLabIO.TritonGetUserConfigList( cbList : TStrings ) ;
// -------------------------------------------------
//  Get Triton source list
// -------------------------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_GetUserConfigList( cbList ) ;
       end ;
     end ;

procedure TSESLabIO.TritonCalibrate ;
// -------------------------------
//  Calibrate Tecella patch clamp
// -------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_Calibrate ;
       end ;
     end ;


function TSESLabIO.TritonIsCalibrated : Boolean ;
// -------------------------------
//  Check if Tecella patch clamp is calibrated
// -------------------------------
begin
     Result := False ;
     case FLabInterfaceType of
       Triton : Result := Triton_IsCalibrated ;
       end ;
     end ;

function TSESLabIO.GetTritonICLAMPOn : Boolean ;
// -------------------------------------------
//  Return TRUE if Triton ICLAMPOn mode is set
// -------------------------------------------
begin
     Result := False ;
     case FLabInterfaceType of
       Triton : Result := Triton_GetTritonICLAMPOn ;
       end ;
     end ;

procedure TSESLabIO.SetTritonICLAMPOn(
          Value : Boolean
          ) ;
// --------------------------------
//  Set Triton ICLAMPOn mode
// --------------------------------
begin
     case FLabInterfaceType of
       Triton : Triton_SetTritonICLAMPOn(Value) ;
       end ;
     end ;


function TSESLabIO.GetDBSStimulus : Boolean ;
// ------------------------
// Get DBS stimulator state
// ------------------------
begin
     case FLabInterfaceType of
       WirelessEEG : WirelessEEG_CheckStimulatorOn(FDBSStimulusOn) ;
       end ;
    Result := FDBSStimulusOn ;
    end ;


Procedure TSESLabIO.SetDBSStimulus( Value : Boolean ) ;
// ------------------------
// Set DBS stimulator state
// ------------------------
begin
     case FLabInterfaceType of
       WirelessEEG : WirelessEEG_SetStimulatorOn( Value ) ;
       end ;

    end ;


function TSESLabIO.GetDBSSleepMode : Boolean ;
// ------------------------
// Get DBS sleep state
// ------------------------
begin
     Result := FDBSSleepMode ;
     case FLabInterfaceType of
       WirelessEEG : Result := FDBSSleepMode ; // WirelessEEG_GetSleepMode ;
       end ;
     end ;


Procedure TSESLabIO.SetDBSSleepMode( Value : Boolean ) ;
// -----------------------------
// Set DBS stimulator sleep mode
// -----------------------------
begin
     FDBSSleepMode := Value ;
     case FLabInterfaceType of
       WirelessEEG : WirelessEEG_SetSleepMode( Value ) ;
       end ;

     end ;


function TSESLabIO.GetDBSWirelessChannel : Integer ;
// -----------------------------
// Return wireless channel number
// -----------------------------
begin
     case FLabInterfaceType of
       WirelessEEG : Result := WirelessEEG_GetWirelessChannel ;
       else Result := 0  ;
       end ;
    end ;


function TSESLabIO.GetDBSFrequency : Single ;
// -----------------------------------
// Return DBS stimulus pulse frequency
// -----------------------------------
begin
     case FLabInterfaceType of
       WirelessEEG : begin
      //    if WirelessEEG_GetPulseFrequency > 0.0 then Result := WirelessEEG_GetPulseFrequency ;
          end ;
       end ;
    Result := FDBSPulseFrequency ;
    end ;


Procedure TSESLabIO.SetDBSFrequency( Value : Single ) ;
// -----------------------------------
// Set DBS stimulus pulse frequency
// -----------------------------------
begin
     FDBSPulseFrequency := Value ;
     // Ensure pulse width is less than 50% pulse interval
     if FDBSPulseWidth > 0.0 then
        FDBSPulseFrequency := Min(FDBSPulseFrequency,0.5/FDBSPulseWidth) ;
     case FLabInterfaceType of
       WirelessEEG : WirelessEEG_SetPulseFrequency( FDBSPulseFrequency ) ;
       end ;
    end ;


function TSESLabIO.GetDBSPulseWidth : Single ;
// -----------------------------------
// Return DBS stimulus pulse frequency
// -----------------------------------
begin
     case FLabInterfaceType of
       WirelessEEG : begin
    //      if WirelessEEG_GetPulseWidth > 0.0 then Result := WirelessEEG_GetPulseWidth ;
          end ;
       end ;
    Result := FDBSPulseWidth ;
    end ;


    Procedure TSESLabIO.SetDBSPulseWidth( Value : Single ) ;
// -----------------------------------
// Set DBS stimulus pulse width
// -----------------------------------
begin
     FDBSPulseWidth := Value ;
     // Ensure pulse width is less than 50% pulse interval
     if FDBSPulseFrequency > 0.0 then
        FDBSPulseWidth := Min(FDBSPulseWidth,0.5/FDBSPulseFrequency) ;
     case FLabInterfaceType of
       WirelessEEG : WirelessEEG_SetPulseWidth( FDBSPulseWidth ) ;
       end ;
    end ;

function TSESLabIO.GetDBSSamplingRate : Single ;
begin
     Result := 0.0 ;
     case FLabInterfaceType of
       WirelessEEG : Result := WirelessEEG_GetSamplingRate ;
       end ;
    end ;


function TSESLabIO.GetDBSNumFramesLost : Integer ;
begin
     Result := 0 ;
     case FLabInterfaceType of
       WirelessEEG : Result := Max(WirelessEEG_GetNumFramesLost,0) ;
       end ;
    end ;


// XML methods
// -----------


procedure TSESLabIO.SaveToXMLFile(
          FileName : String ;      // File name to save data to
          AppendData : Boolean      // Add XML data to end of file if TRUE
          ) ;
// ----------------------------------
// Save interface settings to XML file
// ----------------------------------
begin

    CoInitialize(Nil) ;
    SaveToXMLFile1( FileName, AppendData ) ;
    CoUnInitialize ;
    end ;


procedure TSESLabIO.SaveToXMLFile1(
          FileName : String ;      // File name to save data to
          AppendData : Boolean      // Add XML data to end of file if TRUE
          ) ;
// ----------------------------------
// Save interface settings to XML file (internal)
// ----------------------------------
var
   iNode,ProtNode : IXMLNode;
   i : Integer ;
   s : TStringList ;
   XMLDoc : IXMLDocument ;
begin

    XMLDoc := TXMLDocument.Create(Nil);
    XMLDoc.Active := True ;

    // Clear document
    XMLDoc.ChildNodes.Clear ;

    // Add record name
    ProtNode := XMLDoc.AddChild( 'LABINTERFACESETTINGS' ) ;

    AddElementInt( ProtNode, 'INTERFACETYPE', FLabInterfaceType ) ;
    AddElementInt( ProtNode, 'DEVICENUMBER', FDeviceNumber ) ;
    AddElementInt( ProtNode, 'ADCINPUTMODE', FADCInputMode ) ;
    AddElementInt( ProtNode, 'ADCNUMCHANNELS', FADCNumChannels ) ;
    //AddElementInt( ProtNode, 'ADCMAXCHANNELS', FADCMaxChannels ) ;
    AddElementInt( ProtNode, 'ADCNUMSamples', FADCNumSamples ) ;

    // A/D voltage ranges
    AddElementInt( ProtNode, 'ADCVOLTAGERANGEINDEX', FADCVoltageRangeIndex ) ;
    for i := 0 to MaxADCVoltageRanges-1 do begin
        iNode := ProtNode.AddChild( 'ADCVOLTAGERANGE' ) ;
        AddElementInt( iNode, 'NUMBER', i ) ;
        AddElementFloat( iNode, 'RANGE', FADCVoltageRanges[i] ) ;
        end ;

    //AddElementInt( ProtNode, 'DACMAXCHANNELS', FDACMaxChannels ) ;

    for i := 0 to FADCMaxChannels-1 do begin
        iNode := ProtNode.AddChild( 'ADCCHANNEL' ) ;
        AddElementInt( iNode, 'NUMBER', i ) ;
        AddElementText( iNode, 'NAME', FADCChannelName[i] ) ;
        AddElementText( iNode, 'UNITS', FADCChannelUnits[i] ) ;
        AddElementFloat( iNode, 'VOLTSPERUNIT', FADCChannelVoltsPerUnits[i] ) ;
        AddElementFloat( iNode, 'GAIN', FADCChannelGain[i] ) ;
        AddElementFloat( iNode, 'UNITSPERBIT', FADCChannelUnitsPerBit[i] ) ;
        AddElementInt( iNode, 'ZEROLEVEL', FADCChannelZero[i] ) ;
        AddElementInt( iNode, 'ZEROAT', FADCChannelZeroAt[i] ) ;
        AddElementInt( iNode, 'CHANNELOFFSET', FADCChannelOffset[i] ) ;
        AddElementBool( iNode, 'VISIBLE', FADCChannelVisible[i] ) ;
        AddElementFloat( iNode, 'DISPLAYMIN', FADCChannelYMin[i] ) ;
        AddElementFloat( iNode, 'DISPLAYMAX', FADCChannelYMax[i] ) ;
        AddElementInt( iNode, 'INPUTNUMBER', FADCChannelInputNumber[i] ) ;
        AddElementFloat( iNode, 'ADCVOLTAGERANGE', FADCChannelVoltageRanges[i] ) ;
        end ;

    // D/A channels
    for i := 0 to FDACMaxChannels-1 do begin
        iNode := ProtNode.AddChild( 'DACCHANNEL' ) ;
        AddElementInt( iNode, 'NUMBER', i ) ;
        AddElementFloat( iNode, 'HOLDINGVOLTAGE', FDACHoldingVoltage[i] ) ;
        end ;

    AddElementInt( ProtNode, 'DIGHOLDINGLEVEL', FDigHoldingLevel ) ;

    // Direct brain stimulator settings
    iNode := ProtNode.AddChild( 'DIRECTBRAINSTIMULATOR' ) ;
    AddElementInt( iNode, 'COMPORT', FDBSComPort ) ;
    AddElementFloat( iNode, 'PULSEWIDTH', FDBSPulseWidth ) ;
    AddElementFloat( iNode, 'PULSEFREQUENCY', FDBSPulseFrequency ) ;
    AddElementBool( iNode, 'STIMULUSON', FDBSStimulusOn ) ;
    AddElementBool( iNode, 'SLEEPMODE', FDBSSleepMode ) ;

    // CED 1401 special settings
    AddElementInt( ProtNode, 'CEDPOWER1401DIGTIMCOUNTSHIFT', FCEDPower1401DIGTIMCountShift ) ;

     s := TStringList.Create;
     if not AppendData then begin
        // Save XML data to file
        s.Assign(xmlDoc.XML) ;
     //sl.Insert(0,'<!DOCTYPE ns:mys SYSTEM "myXML.dtd">') ;
        s.Insert(0,'<?xml version="1.0"?>') ;
        s.SaveToFile( FileName ) ;
        end
     else begin
        // Append to existing XML file
        s.LoadFromFile(FileName);
        for i := 0 to xmlDoc.XML.Count-1 do begin
             s.Add(xmlDoc.XML.Strings[i]) ;
             end ;
        s.SaveToFile( FileName ) ;
        end ;
     s.Free ;

     XMLDoc.Active := False ;
     XMLDoc := Nil ; //.Free ;
    end ;


function TSESLabIO.SettingsFileExists : Boolean ;
//
// Return TRUE if XML settings file exists
// ---------------------------------------
begin
      Result := FileExists( SettingsFileName ) ;
      end ;


procedure TSESLabIO.LoadFromXMLFile(
          FileName : String                    // XML protocol file
          ) ;
// ----------------------------------
// Load settings from XML file
// ----------------------------------
begin
    CoInitialize(Nil) ;
    LoadFromXMLFile1( FileName ) ;
    CoUnInitialize ;
    end ;

procedure TSESLabIO.LoadFromXMLFile1(
          FileName : String                    // XML protocol file
          ) ;
// ----------------------------------
// Load settings from XML file (internal)
// ----------------------------------
var
   iNode,ProtNode : IXMLNode;
   i : Integer ;

   NodeIndex : Integer ;
   XMLDoc : IXMLDocument ;

begin

    XMLDoc := TXMLDocument.Create(Nil) ;

    XMLDOC.Active := False ;

    XMLDOC.LoadFromFile( FileName ) ;
    XMLDoc.Active := True ;

//    for i := 0 to  xmldoc.DocumentElement.ChildNodes.Count-1 do
//        OutputDebugString( PChar(String(xmldoc.DocumentElement.ChildNodes[i].NodeName))) ;

    // <LABINTERFACESETTINGS> is not the root node, search for it
    if xmldoc.DocumentElement.NodeName = 'LABINTERFACESETTINGS' then begin
       ProtNode := xmldoc.DocumentElement ;
       end
    else begin
       NodeIndex := 0 ;
       FindXMLNode(xmldoc.DocumentElement,'LABINTERFACESETTINGS',ProtNode,NodeIndex);
       end ;

    GetElementInt( ProtNode, 'INTERFACETYPE', FLabInterfaceType ) ;
    GetElementInt( ProtNode, 'DEVICENUMBER', FDeviceNumber ) ;
    GetElementInt( ProtNode, 'ADCINPUTMODE', FADCInputMode ) ;
    GetElementInt( ProtNode, 'ADCNUMCHANNELS', FADCNumChannels ) ;
    //GetElementInt( ProtNode, 'ADCMAXCHANNELS', FADCMaxChannels ) ;
    GetElementInt( ProtNode, 'ADCNUMSamples', FADCNumSamples ) ;

    // A/D input voltage ranges

    GetElementInt( ProtNode, 'ADCVOLTAGERANGEINDEX', FADCVoltageRangeIndex ) ;
    NodeIndex := 0 ;
    While FindXMLNode(ProtNode,'ADCVOLTAGERANGE',iNode,NodeIndex) do begin
        GetElementInt( iNode, 'NUMBER', i ) ;
        if (i >= 0) and (i < MaxADCVoltageRanges) then begin
           GetElementFloat( iNode, 'RANGE', FADCVoltageRanges[i] ) ;
           end ;
        Inc(NodeIndex) ;
        end ;

    //GetElementInt( ProtNode, 'DACMAXCHANNELS', FDACMaxChannels ) ;

    // Get A/D channels

    NodeIndex := 0 ;
    While FindXMLNode(ProtNode,'ADCCHANNEL',iNode,NodeIndex) do begin
        GetElementInt( iNode, 'NUMBER', i ) ;
        if (i >= 0) and (i < FADCMaxChannels) then begin
           GetElementText( iNode, 'NAME', FADCChannelName[i] ) ;
           GetElementText( iNode, 'UNITS', FADCChannelUnits[i] ) ;
           GetElementFloat( iNode, 'VOLTSPERUNIT', FADCChannelVoltsPerUnits[i] ) ;
           GetElementFloat( iNode, 'GAIN', FADCChannelGain[i] ) ;
           GetElementFloat( iNode, 'UNITSPERBIT', FADCChannelUnitsPerBit[i] ) ;
           GetElementInt( iNode, 'ZEROLEVEL', FADCChannelZero[i] ) ;
           GetElementInt( iNode, 'ZEROAT', FADCChannelZeroAt[i] ) ;
           GetElementInt( iNode, 'CHANNELOFFSET', FADCChannelOffset[i] ) ;
           GetElementBool( iNode, 'VISIBLE', FADCChannelVisible[i] ) ;
           GetElementFloat( iNode, 'DISPLAYMIN', FADCChannelYMin[i] ) ;
           GetElementFloat( iNode, 'DISPLAYMAX', FADCChannelYMax[i] ) ;
           GetElementInt( iNode, 'INPUTNUMBER', FADCChannelInputNumber[i] ) ;
           FADCChannelVoltageRanges[i] := FADCVoltageRangeIndex ;
           GetElementFloat( iNode, 'ADCVOLTAGERANGE', FADCChannelVoltageRanges[i] ) ;
           end ;
        Inc(NodeIndex) ;
        end ;

    // D/A channels
    NodeIndex := 0 ;
    While FindXMLNode(ProtNode,'DACCHANNEL',iNode,NodeIndex) do begin
        GetElementInt( iNode, 'NUMBER', i ) ;
        if (i >= 0) and (i < FDACMaxChannels) then begin
           GetElementFloat( iNode, 'HOLDINGVOLTAGE', FDACHoldingVoltage[i] ) ;
           end ;
        Inc(NodeIndex) ;
        end ;

    // Digital outputs
    GetElementInt( ProtNode, 'DIGHOLDINGLEVEL', FDigHoldingLevel ) ;


    // Direct brain stimulator settings
    NodeIndex := 0 ;
    While FindXMLNode(ProtNode,'DIRECTBRAINSTIMULATOR',iNode,NodeIndex) do begin
       GetElementInt( iNode, 'COMPORT', FDBSComPort ) ;
       GetElementFloat( iNode, 'PULSEWIDTH', FDBSPulseWidth ) ;
       GetElementFloat( iNode, 'PULSEFREQUENCY', FDBSPulseFrequency ) ;
       GetElementBool( iNode, 'STIMULUSON', FDBSStimulusOn ) ;
       GetElementBool( iNode, 'SLEEPMODE', FDBSSleepMode ) ;
       Inc(NodeIndex) ;
       end ;

    // CED 1401 special settings
    GetElementInt( ProtNode, 'CEDPOWER1401DIGTIMCOUNTSHIFT', FCEDPower1401DIGTIMCountShift ) ;
    if FCEDPower1401DIGTIMCountShift <> 0 then FCEDPower1401DIGTIMCountShift := 1 ;

    XMLDoc.Active := False ;
    XMLDoc := Nil ;

    end ;

procedure TSESLabIO.AddElementFloat(
          ParentNode : IXMLNode ;
          NodeName : String ;
          Value : Single
          ) ;
// -------------------------------
// Add element with value to node
// -------------------------------
var
   ChildNode : IXMLNode;
begin

    ChildNode := ParentNode.AddChild( NodeName ) ;
    ChildNode.Text := format('%.10g',[Value]) ;

    end ;


function TSESLabIO.GetElementFloat(
         ParentNode : IXMLNode ;
         NodeName : String ;
         var Value : Single
          ) : Boolean ;
// ---------------------
// Get value of element
// ---------------------
var
   ChildNode : IXMLNode;
   OldValue : Single ;
   NodeIndex : Integer ;
   s : string ;
begin
    Result := False ;
    OldValue := Value ;
    NodeIndex := 0 ;
    if FindXMLNode(ParentNode,NodeName,ChildNode,NodeIndex) then begin
       // Correct for use of comma/period as decimal separator }
       s := ChildNode.Text ;
       if (DECIMALSEPARATOR = '.') then s := ANSIReplaceText(s , ',',DECIMALSEPARATOR);
       if (DECIMALSEPARATOR = ',') then s := ANSIReplaceText( s, '.',DECIMALSEPARATOR);
       try
          Value := StrToFloat(s) ;
          Result := True ;
       except
          Value := OldValue ;
          Result := False ;
          end ;
       end ;

    end ;


procedure TSESLabIO.AddElementInt(
          ParentNode : IXMLNode ;
          NodeName : String ;
          Value : Integer
          ) ;
// -------------------------------
// Add element with value to node
// -------------------------------
var
   ChildNode : IXMLNode;
begin

    ChildNode := ParentNode.AddChild( NodeName ) ;
    ChildNode.Text := format('%d',[Value]) ;

    end ;


function TSESLabIO.GetElementInt(
          ParentNode : IXMLNode ;
          NodeName : String ;
          var Value : Integer
          ) : Boolean ;
// ---------------------
// Get value of element
// ---------------------
var
   ChildNode : IXMLNode;
   NodeIndex : Integer ;
   OldValue : Integer ;
begin
    Result := False ;
    OldValue := Value ;
    NodeIndex := 0 ;
    if FindXMLNode(ParentNode,NodeName,ChildNode,NodeIndex) then begin
       try
          Value := StrToInt(ChildNode.Text) ;
          Result := True ;
       except
          Value := OldValue ;
          Result := False ;
          end ;
       end ;
    end ;


procedure TSESLabIO.AddElementBool(
          ParentNode : IXMLNode ;
          NodeName : String ;
          Value : Boolean
          ) ;
// -------------------------------
// Add element with value to node
// -------------------------------
var
   ChildNode : IXMLNode;
begin

    ChildNode := ParentNode.AddChild( NodeName ) ;
    if Value = True then ChildNode.Text := 'T'
                    else ChildNode.Text := 'F' ;

    end ;


function TSESLabIO.GetElementBool(
          ParentNode : IXMLNode ;
          NodeName : String ;
          var Value : Boolean
          ) : Boolean ;
// ---------------------
// Get value of element
// ---------------------
var
   ChildNode : IXMLNode;
   NodeIndex : Integer ;
begin
    Result := False ;
    NodeIndex := 0 ;
    if FindXMLNode(ParentNode,NodeName,ChildNode,NodeIndex) then begin
       if ANSIContainsText(ChildNode.Text,'T') then Value := True
                                               else  Value := False ;
       Result := True ;
       end ;

    end ;


procedure TSESLabIO.AddElementText(
          ParentNode : IXMLNode ;
          NodeName : String ;
          Value : String
          ) ;
// -------------------------------
// Add element with value to node
// -------------------------------
var
   ChildNode : IXMLNode;
begin

    ChildNode := ParentNode.AddChild( NodeName ) ;
    ChildNode.Text := Value ;

    end ;


function TSESLabIO.GetElementText(
          ParentNode : IXMLNode ;
          NodeName : String ;
          var Value : String
          ) : Boolean ;
// ---------------------
// Get value of element
// ---------------------
var
   ChildNode : IXMLNode;
   NodeIndex : Integer ;
begin

    Result := False ;
    NodeIndex := 0 ;
    if FindXMLNode(ParentNode,NodeName,ChildNode,NodeIndex) then begin
       Value := ChildNode.Text ;
       Result := True ;
       end ;

    end ;


function TSESLabIO.FindXMLNode(
         const ParentNode : IXMLNode ;  // Node to be searched
         NodeName : String ;            // Element name to be found
         var ChildNode : IXMLNode ;     // Child Node of found element
         var NodeIndex : Integer        // ParentNode.ChildNodes Index #
                                        // Starting index on entry, found index on exit
         ) : Boolean ;
// -------------
// Find XML node
// -------------
var
    i : Integer ;
begin

    Result := False ;
    for i := NodeIndex to ParentNode.ChildNodes.Count-1 do begin
      if ParentNode.ChildNodes[i].NodeName = WideString(NodeName) then begin
         Result := True ;
         ChildNode := ParentNode.ChildNodes[i] ;
         NodeIndex := i ;
         Break ;
         end ;
      end ;
    end ;




end.
