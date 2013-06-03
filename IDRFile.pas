unit IDRFile;
// -------------------------------------------------
// WinFluor IDR file handling component
// (c) J. Dempster, University of Strathclyde, 2003
// -------------------------------------------------
// 5.8.03 ... .CreateFileFrom() now creates copy of EDR file
// 6.8.03 ... .IntensityScale and .IntensityOffset added
// 11.8.03 ... IntensityOffset forced to 0 when IntensityScale=1
// 24.9.03 ... IDR file offsets now stored as Int64 to permit files bigger than 2Gbyte
// 10.8.03 ... Event marker list added
// 9.12.03 ... IDR and EDR files can now have non-standard header sizes
// 12.3.04 ... User now has option of updating non-standard header size to normal value
// 9.06.04 ... EDR file header size increased to 2048
// 29.06.04 .. LineScan property added
// 08.06.05 .. Data folder created automatically if one does not exist
// 10.06.05 .. IMGDELAY=', FImageStartDelay added Delay before start of imaging
// 21.06.05 .. DATECR=, Creation date field added
// 23.06.05 .. WriteEnabled property added
//             File is now opened in read-only mode except when writing is required
// 05.08.05 .. CopyADCSamples added to CreateFileFrom
//             .SaveADC() method added
// 04.09.05 .. Channel.YMax and YMin now set when first IDR file opened
// 12.10.05 .. ADCNumScansInFile=0 fixed if scans exist in EDR file
// 28.02.06 .. Disk free space always reported as available on G
// 26.04.06 .. IDR file header size increased to 16000 bytes
//             No. of ROIs increased to 50
// 23.01.07 .. Max. no. of frame types increased to 9
// 22.01.07 .. Spectrum data properties added
// 08.05.07 .. Channel settings now acquired from EDR file
//             if EDR file exists bit IDR file indicates no channels or samples.
// 11.07.07 .. EventDisplayDuration property added
// 23.04.08 .. FrameTypeDivideFactor added
// 03.07.08 .. No. of frame types now made equal to no. frames in line scan files
// 22.01.09 .. Support for 4 byte pixel images addded
// 13.07.10 .. .LoadADCData now always fills buffer with required number of samples
//             padding upper and lower ends if necessary
//             .FileHeader property added returning string with IDR file header text
// 27.07.10 .. IDRFileRead now times out after 500ms if no data available
//             No. of frames listed in header now checked against file size
//             and can be corrected to match file size.
// 05.08.10 .. JD .LoadADCData can now return data for buffer request which are
//             completely outside data. (first or last data samples are returned
//             Event detector display settings now stored in IDR file header
// 26.07.11 .. JD FileSeek(..) replaced with IDRGetFileSize() for IDR file
//             because it was returning incorrect file size for files > 2Gbyte
// 24.07.12 .. DiskSpaceAvailable now works correctly for all drives
// 31.07.12 .. Max. no. of ROIs increased to 100
// 30.01.13 .. Z stack parameters (ZNUMSECTIONS,ZSTART,ZSPACING) added

interface

uses
  Classes, Types, Dialogs, Graphics, Controls, DateUtils, math, windows, mmsystem, SysUtils  ;

const
     MaxEqn = 9 ;                    // Upper limit of binding equations
     MaxFrameType = 8 ;              // Upper limit of frame types
     MaxFrameDivideFactor = 100 ; 
     MaxChannel = 7 ;                // Upper limit of A/D channels
     cMaxROIs = 100 ;                  // Upper limit of ROIs (raised from 50 30/7/12)
     MaxMarker = 20 ;               // Upper limit of event markers
     cNumIDRHeaderBytes = 32768 ;  // Old size = 4096 ;
     cNumEDRHeaderBytes = 2048 ; //
     MaxFrameWidth = 4096 ;
     MaxFrameHeight = 4096 ;
     MaxPixelsPerFrame = MaxFrameWidth*MaxFrameHeight ;
     MaxBytesPerFrame = MaxPixelsPerFrame*2 ;
     MaxWavelengthDivideFactor = 100 ;
     MaxLightSourceCycleLength = MaxWavelengthDivideFactor*(MaxFrameType+2) ;

     NoROI = -1 ;
     PointROI = 0 ;
     RectangleROI = 1 ;
     EllipseROI = 2 ;
     LineROI = 3 ;
     PolyLineROI = 4 ;
     PolygonROI = 5 ;
     ROIMaxPoints = 100 ;

type

TSmallIntArray = Array[0..99999999] of SmallInt ;
PSmallIntArray = ^TSmallIntArray ;
TIntArray = Array[0..MaxPixelsPerFrame-1] of Integer ;
PIntArray = ^TIntArray ;
TSingleArray = Array[0..MaxPixelsPerFrame-1] of Single ;
PSingleArray = ^TSingleArray ;
TPointArray = Array[0..MaxPixelsPerFrame-1] of TPoint ;
PPointArray = ^TPointArray ;


TChannel = record
         xMin : single ;
         xMax : single ;
         yMin : single ;
         yMax : single ;
         xScale : single ;
         yScale : single ;
         Left : LongInt ;
         Right : LongInt ;
         Top : LongInt ;
         Bottom : LongInt ;
         TimeZero : single ;
         ADCZero : LongInt ;
         ADCZeroAt : LongInt ;
         ADCSCale : single ;
         ADCCalibrationFactor : single ;
         ADCCalibrationValue : single ;
         ADCAmplifierGain : single ;
         ADCUnits : string ;
         ADCName : string ;
         InUse : Boolean ;
         ChannelOffset : LongInt ;
         CursorIndex : LongInt ;
         ZeroIndex : LongInt ;
         CursorTime : single ;
         CursorValue : single ;
         Cursor0 : Integer ;
         Cursor1 : Integer ;
         TZeroCursor : Integer ;
         color : TColor ;
         end ;



     TROI = record
         InUse : Boolean ;
         Shape : Integer ;
         TopLeft : TPoint ;
         BottomRight : TPoint ;
         Centre : TPoint ;
         Width : Integer ;
         Height : Integer ;
         ZoomFactor : Single ;
         XY : Array[0..ROIMaxPoints-1] of TPoint ;
         NumPoints : Integer ;
         //PixelList : PPointArray ;
         //NumPixels : Integer ;
         end ;

  TBindingEquation = record
         InUse : Boolean ;
         Name : string ;
         Ion : string ;
         Units : string ;
         RMin : Single ;
         RMax : Single ;
         KEff : Single ;
         end ;

  TIDRFile = class(TComponent)
  private
    { Private declarations }
    FFileName : String ;           // Data file name
    FWriteEnabled : Boolean ;      // TRUE = file can be written to
    FIdent : String ;              // Comment line
    FYearCreated : Integer ;         // Creation date (year)
    FMonthCreated : Integer ;       // Creation date (month)
    FDayCreated : Integer ;         // Creation date (day)

    FLineScan : Boolean ;          // Line scan flag
    FLSTimeCoursePixel : Integer  ;  // Time course pixel
    FLSTimeCourseNumAvg : Integer ;  // No. of pixel on line averaged for time course
    FLSTimeCourseBackgroundPixel : Integer ;    // Background subtraction pixel
    FLSSubtractBackground : Boolean ; // Subtract background

    FImageStartDelay : Single ;
    FLineScanIntervalCorrectionFactor : Single ;
    FNumFrames : Integer ;   // No. of frames in data file
    FFrameWidth : Integer ;        // Image frame width (pixels)
    FFrameHeight : Integer ;       // Image frame height (pixels)
    FPixelDepth : Integer ;        // No. of bits per pixel
    FNumZSections : Integer ;         // No. of Z sections
    FZStart : Single ;                // Z position of first Z section
    FZSpacing : Single ;       // Spacing between Z sections
    FFrameInterval : Single ;      // Frame capture interval (s)
    FNumBytesPerFrame : Integer ;    // No. bytes per frame
    FNumPixelsPerFrame : Integer ; // No. of pixels per frame
    FNumBytesPerPixel : Integer ;  // No. of bytes per image pixel
    FGreyMin : Integer ;            // Minimum grey level
    FGreyMax : Integer ;            // Maximum intensity value
    FIntensityScale : Single ;      // Image intensity measurement scale factor
    FIntensityOffset : Single ;     // Image intensity measurement offset
    //GreyMax : Integer ;            // Maximum grey level
    FXResolution : Single ;         // Pixel width
    FYResolution : Single ;         // Pixel height
    FResolutionUnits : String ;     // Pixel width measurement units

    FNumIDRHeaderBytes : Integer ;  // No. of bytes in IDR file header
    FNumEDRHeaderBytes : Integer ;  // No. of bytes in EDR file header

    // Type of frame
    FNumFrameTypes : Integer ;                       // No. of frames types in file
    FFrameTypes : Array[0..MaxFrameType] of string ; // Frame type names
    FFrameTypeDivideFactor : Array[0..MaxFrameType] of Integer ; // Frame divide factor
    FFrameTypeCycle : Array[0..MaxLightSourceCycleLength-1] of Integer ;
    FFrameTypeCycleLength : Integer ;

    // Regions of interest within images
    FMaxROI : Integer ;                        // Highest ROI
    FROIs: Array[0..cMaxROIs] of TROI ;
    // Binding equations
    FMaxEquations : Integer ;                  // No. of equations
    FEquations : Array[0..MaxEqn] of TBindingEquation ;

    // Analogue signal channel parameters
    FADCMaxChannels : Integer ;
    Channels : Array[0..MaxChannel] of TChannel ;
    FADCNumScansInFile : Integer ;  // No. of A/D multi-channel scans in file
    FADCNumSamplesInFile : Integer ; // No. of A/D samples in file
    FADCNumChannels : Integer ;     // No. of A/D channels per scan
    FADCScanInterval : Single ;     // Time interval between A/D scans (s)
    FADCVoltageRange : Single ;     // A/D input voltage range
    FADCNumScansPerFrame : Integer ; // No. of scans per image frame
    FADCMaxValue : Integer ;         // Max. A/D sample value

    FNumMarkers : Integer ;
    FMarkerTime : Array[0..MaxMarker] of Single ;
    FMarkerText : Array[0..MaxMarker] of String ;

    // Spectrum data
    FSpectralDataFile : Boolean ;
    FSpectrumStartWavelength : Single ;
    FSpectrumEndWavelength : Single ;
    FSpectrumBandwidth : Single ;
    FSpectrumStepSize : Single ;

    // Event detection data
    FEventDisplayDuration : Single ;
    FEventDeadTime : Single ;
    FEventDetectionThreshold : Single ;
    FEventThresholdDuration : Single ;
    FEventDetectionThresholdPolarity : Integer ;
    FEventDetectionSource : Integer ;
    FEventROI : Integer ;
    FEventBackgROI : Integer ;
    FEventFixedBaseline : Boolean ;
    FEventRollingBaselinePeriod : Single ;
    FEventBaselineLevel : Integer ;
    FEventRatioExclusionThreshold : Integer ;
    FEventRatioTop : Integer ;
    FEventRatioBottom : Integer ;
    FEventRatioDisplayMax : Single ;
    FEventRatioRMax : Single ;
    FEventF0Wave : Integer ;
    FEventFLWave : Integer ;
    FEventF0Start : Integer ;
    FEventF0End : Integer ;
    FEventF0Constant : Single ;
    FEventF0UseConstant : Boolean ;
    FEventF0DisplayMax : Single ;
    FEventF0SubtractF0 : Boolean ;

    FIDRFileHandle : THandle ;       // .IDR (images) file handle
    FEDRFileHandle : Integer ;       // .EDR (A/D samples) file handle
    PInternalBuf : Pointer ;         // Internal frame buffer

    AsyncWriteBuf : Pointer ;       // Asynchronous write buffer pointer
    FAsyncWriteBufSize : Integer ;   // Size of Asynchronous write buffer (bytes)
    AsyncWriteOverlap : _Overlapped ;
    AsyncWriteInProgess : Boolean ;
    AsyncNumBytesToWrite : Integer ;
    FAsyncBufferOverflow : Boolean ;

    NoPreviousOpenFile : Boolean ;   // No file has been opened yet flag
    HeaderFull : Boolean ;
    Header : array[1..cNumIDRHeaderBytes] of ANSIchar ;
    
    Err : Boolean ;
    procedure GetIDRHeader ;
    procedure SaveIDRHeader ;
    function GetNumFramesInFile : Integer ;


    procedure GetEDRHeader ;
    procedure SaveEDRHeader ;
    function GetNumScansInEDRFile : Integer ;

    procedure AppendFloat(
              var Dest : array of ANSIchar;
              Keyword : string ;
              Value : Extended
              ) ;
    procedure ReadFloat(
              const Source : array of ANSIchar;
              Keyword : string ;
              var Value : Single ) ;
    procedure AppendInt(
              var Dest : array of ANSIchar;
              Keyword : string ;
              Value : LongInt
              ) ;
    procedure ReadInt(
              const Source : array of ANSIchar;
              Keyword : string ;
              var Value : LongInt
              ) ;
    procedure AppendLogical(
              var Dest : array of ANSIchar;
              Keyword : string ;
              Value : Boolean ) ;
    procedure ReadLogical(
              const Source : array of ANSIchar;
              Keyword : string ;
              var Value : Boolean
              ) ;
    procedure AppendString(
              var Dest : Array of ANSIchar;
              Keyword,
              Value : string
              ) ;
    procedure ReadString(
              const Source : Array of ANSIChar;
              Keyword : string ;
              var Value : string
              ) ;

    procedure CopyStringToArray( var Dest : array of ANSIChar ; Source : string ) ;
    procedure CopyArrayToString( var Dest : string ; var Source : array of ANSIChar ) ;

    procedure FindParameter(
              const Source : array of ANSIChar ;
              Keyword : string ;
              var Parameter : string ) ;

    function IntLimitTo( Value, LowerLimit, UpperLimit : Integer ) : Integer ;
    function ExtractFloat ( CBuf : string ; Default : Single) : single ;

    function ExtractInt ( CBuf : string ) : LongInt ;


    function GetFrameType( i : Integer ) : String ;

    function GetFrameTypeDivideFactor( i : Integer ) : Integer ;

    function GetEquation( i : Integer ) : TBindingEquation ;
    function GetMarkerTime( i : Integer ) : Single ;
    procedure SetMarkerTime( i : Integer ; Value : Single ) ;
    function GetMarkerText( i : Integer ) : String ;
    procedure SetMarkerText( i : Integer ; Value : String ) ;
    function GetADCChannel( i : Integer ) : TChannel ;
    function GetROI( i : Integer ) : TROI ;

    procedure SetADCChannel( i : Integer ; Value : TChannel ) ;
    procedure SetROI( i : Integer ; Value : TROI ) ;
    procedure SetEquation( i : Integer ; Value : TBindingEquation ) ;

    procedure SetPixelDepth( Value : Integer ) ;
    procedure SetFrameWidth( Value : Integer ) ;
    procedure SetFrameHeight( Value : Integer ) ;
    procedure SetADCVoltageRange( Value : Single ) ;
    procedure SetADCNumChannels( Value : Integer ) ;
    procedure ComputeFrameSize ;

    procedure SetFrameType( i : Integer ; Value : String ) ;
    procedure SetFrameTypeDivideFactor( i : Integer ; Value : Integer ) ;
    procedure SetWriteEnabled( Value : Boolean ) ;

    procedure SetAsyncWriteBufSize( Value : Integer ) ;

    function IDRFileCreate( FileName : String ) : Boolean ;
    function IDRFileOpen( FileName : String ; FileMode : Integer ) : Boolean ;
    function IDRFileWrite(
             pDataBuf : Pointer ;
             FileOffset : Int64 ;
             NumBytesToWrite : Integer
             ) : Integer ;
    function IDRAsyncFileWrite(
             pDataBuf : Pointer ;
             FileOffset : Int64 ;
             NumBytesToWrite : Integer
             ) : Integer ;
    function IDRFileRead(
             pDataBuf : Pointer ;
             FileOffset : Int64 ;
             NumBytesToRead : Integer
             ) : Integer ;

    function IDRGetFileSize : Int64 ;
    procedure IDRFileClose;


    function IsIDRFileOpen : Boolean ;

    function GetNumFramesPerSpectrum : Integer ;
    function GetNumFrameTypes : Integer ;
    procedure SetNumFrameTypes( Value : Integer ) ;

    function GetFileHeader : string ;

    function GetMaxROIInUse : Integer ;

  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;

    function CreateNewFile(
             FileName : String
             ) : Boolean ;
    function CreateFileFrom(
             FileName : String ;
             Source : TIDRFile ;
             CopyADCSamples : Boolean
             ) : Boolean ;
    function OpenFile( FileName : String ) : Boolean ;
    procedure CloseFile ;

    function LoadFrame( FrameNum : Integer ; FrameBuf : Pointer ) : Boolean ;
    function SaveFrame( FrameNum : Integer ; FrameBuf : Pointer ) : Boolean ;
    function LoadFrame32( FrameNum : Integer ; FrameBuf32 : PIntArray ) : Boolean ;
    function SaveFrame32( FrameNum : Integer ; FrameBuf32 : PIntArray ) : Boolean ;
    function AsyncSaveFrames( FrameNum : Integer ; NumFrames : Integer ; FrameBuf : Pointer ) : Boolean ;

    procedure UpdateNumFrames ;
    function DiskSpaceAvailable( NumFrames : Integer ) : Boolean ;

    function LoadADC(
             StartScan : Integer ;
             NumScans : Integer ;
             var ADCBuf : Array of SmallInt
             ) : Integer ;

    function SaveADC(
             StartScan : Integer ;
             NumScans : Integer ;
             var ADCBuf : Array of SmallInt
             ) : Integer ;


    procedure UpdateChannelScalingFactors(
              var Channels : Array of TChannel ;
              NumChannels : Integer ;
              ADCVoltageRange : Single ;
              ADCMaxValue : Integer ) ;

    function AddMarker( Time : Single ; Text : String ) : Boolean ;

   procedure CreateFramePointerList(
             var FrameList : PIntArray  ) ;

   function TypeOfFrame( FrameNum : Integer ) : Integer ;

   procedure CreateFrameTypeCycle(
          var FrameTypeCycle : Array of Integer ;
          var FrameTypeCycleLength : Integer ) ;


    property FrameType[ i : Integer ] : String
             read GetFrameType write SetFrameType ;

    property FrameTypeDivideFactor[ i : Integer ] : Integer
             read GetFrameTypeDivideFactor write SetFrameTypeDivideFactor ;

    property ADCChannel[ i : Integer ] : TChannel
             read GetADCChannel write SetADCChannel ;

    property ROI[ i : Integer ] : TROI
             read GetROI write SetROI ;

    property Equation[ i : Integer ] : TBindingEquation
             read GetEquation write SetEquation ;

    property MarkerTime[ i : Integer ] : Single read GetMarkerTime write SetMarkerTime ;
    property MarkerText[ i : Integer ] : String read GetMarkerText write SetMarkerText;

  published
    { Published declarations }
    Property FileName : String Read FFileName ;
    Property Open : Boolean Read IsIDRFileOpen ;
    Property EDRFileHandle : Integer Read FEDRFileHandle ;
    Property AsyncWriteBufSize : Integer Read FAsyncWriteBufSize
                                         Write SetAsyncWriteBufSize ;
    Property AsyncBufferOverflow : Boolean read FAsyncBufferOverflow ;
    Property Ident : String Read FIdent Write FIdent ;
    Property NumFrames : Integer read FNumFrames write FNumFrames ; //
    Property NumFrameTypes : Integer
             read GetNumFrameTypes write SetNumFrameTypes ;     // No. of types of frame


    Property FrameWidth : Integer read FFrameWidth write FFrameWidth;   // Image frame width (pixels)
    Property FrameHeight : Integer read FFrameHeight write FFrameHeight; // Image frame height (pixels)
    Property PixelDepth : Integer read FPixelDepth write SetPixelDepth ;   // No. of bits per pixel
    Property FrameInterval : Single read FFrameInterval write FFrameInterval;      // Frame capture interval (s)

    Property NumZSections : Integer read FNumZSections write FNumZSections ;
    Property ZSpacing : Single read FZSpacing write FZSpacing ;
    Property ZStart : Single read FZStart write FZStart ;

    Property NumBytesPerFrame : Integer read FNumBytesPerFrame ;  // No. bytes per frame
    Property NumPixelsPerFrame : Integer read FNumPixelsPerFrame ; // No. of pixels per frame
    Property NumBytesPerPixel : Integer read FNumBytesPerPixel ;  // No. of bytes per image pixel
    Property GreyMax : Integer read FGreyMax ;            // Maximum grey level
    Property IntensityScale : Single Read FIntensityScale Write FIntensityScale ;
    Property IntensityOffset : Single Read FIntensityOffset Write FIntensityOffset ;
    Property XResolution : Single read FXResolution write FXResolution ;  // Pixel width
    Property ResolutionUnits : String read FResolutionUnits write FResolutionUnits ;     // Pixel width measurement units
    Property NumIDRHeaderBytes : Integer Read FNumIDRHeaderBytes ;
    Property NumEDRHeaderBytes : Integer Read FNumEDRHeaderBytes ;

    Property ADCNumScansInFile : Integer Read FADCNumScansInFile Write FADCNumScansInFile ;  // No. of A/D multi-channel scans in file
    Property ADCNumChannels : Integer Read FADCNumChannels Write SetADCNumChannels ;
    Property ADCNumScansPerFrame : Integer Read FADCNumScansPerFrame write FADCNumScansPerFrame ;
    Property ADCMaxValue : Integer Read FADCMaxValue Write FADCMaxValue ;
    Property ADCSCanInterval : Single Read FADCSCanInterval Write FADCSCanInterval ;
    Property ADCVoltageRange : Single Read FADCVoltageRange Write SetADCVoltageRange ;
    Property ADCMaxChannels : Integer Read FADCMaxChannels ;
    Property MaxROI : Integer read FMaxROI ;
    Property MaxROIInUse : Integer read GetMaxROIInUse ;
    Property MaxEquations : Integer read FMaxEquations ;

    Property NumMarkers : Integer Read FNumMarkers ;
    Property LineScan : Boolean Read FLineScan Write FLineScan ;
    Property LSTimeCoursePixel : Integer read FLSTimeCoursePixel write FLSTimeCoursePixel ;
    Property LSTimeCourseNumAvg : Integer read FLSTimeCourseNumAvg write FLSTimeCourseNumAvg;
    Property LSTimeCourseBackgroundPixel : Integer  read FLSTimeCourseBackgroundPixel write FLSTimeCourseBackgroundPixel;
    Property LSSubtractBackground : Boolean read FLSSubtractBackground write FLSSubtractBackground;
    Property ImageStartDelay : Single
             read FImageStartDelay
             write FImageStartDelay ;
    Property LineScanIntervalCorrectionFactor : Single
             read FLineScanIntervalCorrectionFactor
             write FLineScanIntervalCorrectionFactor ;

    Property Year : Integer read FYearCreated ;
    Property Month : Integer read FMonthCreated ;
    Property Day : Integer read FDayCreated ;
    Property WriteEnabled : Boolean read FWriteEnabled write SetWriteEnabled ;
    Property SpectralDataFile : Boolean read FSpectralDataFile
                                        write FSpectralDataFile ;
    Property SpectrumStartWavelength : Single read FSpectrumStartWavelength
                                              write FSpectrumStartWavelength ;
    Property SpectrumEndWavelength : Single read FSpectrumEndWavelength
                                            write FSpectrumEndWavelength ;
    Property SpectrumBandwidth : Single read FSpectrumBandwidth
                                              write FSpectrumBandwidth ;
    Property SpectrumStepSize : Single read FSpectrumStepSize
                                              write FSpectrumStepSize ;
    Property NumFramesPerSpectrum : Integer read GetNumFramesPerSpectrum ;

    Property EventDisplayDuration : Single
             read FEventDisplayDuration write FEventDisplayDuration ;
    Property EventDeadTime : Single
             read FEventDeadTime write FEventDeadTime ;
    Property EventDetectionThreshold : Single
             read FEventDetectionThreshold write FEventDetectionThreshold ;
    Property EventThresholdDuration : Single
             read FEventThresholdDuration write FEventThresholdDuration ;
    Property EventDetectionThresholdPolarity : Integer
             read FEventDetectionThresholdPolarity write FEventDetectionThresholdPolarity ;
    Property EventDetectionSource : Integer
             read FEventDetectionSource write FEventDetectionSource ;
    Property EventROI : Integer
             read FEventROI write FEventROI ;
    Property EventBackgROI : Integer
             read FEventBackgROI write FEventBackgROI ;
    Property EventFixedBaseline : Boolean
             read FEventFixedBaseline write FEventFixedBaseline ;
    Property EventRollingBaselinePeriod : Single
             read FEventRollingBaselinePeriod write FEventRollingBaselinePeriod ;
    Property EventBaselineLevel : Integer
             read FEventBaselineLevel write FEventBaselineLevel ;
    Property EventRatioExclusionThreshold : Integer
             read FEventRatioExclusionThreshold write FEventRatioExclusionThreshold;
    Property EventRatioTop : Integer
             read FEventRatioTop write FEventRatioTop ;
    Property EventRatioBottom : Integer
             read FEventRatioBottom write FEventRatioBottom ;
    Property EventRatioDisplayMax : Single
             read FEventRatioDisplayMax write  FEventRatioDisplayMax ;
    Property EventRatioRMax : Single
             read FEventRatioRMax write FEventRatioRMax ;
    Property EventFLWave : Integer
             read FEventFLWave write FEventFLWave ;
    Property EventF0Wave : Integer 
             read FEventF0Wave write FEventF0Wave ;
    Property EventF0Start : Integer
             read FEventF0Start write FEventF0Start ;
    Property EventF0End : Integer
             read FEventF0End write FEventF0End ;
    Property EventF0Constant : Single
             read FEventF0Constant write FEventF0Constant ;
    Property EventF0UseConstant : Boolean
             read FEventF0UseConstant write FEventF0UseConstant ;
    Property EventF0DisplayMax : Single
             read FEventF0DisplayMax write FEventF0DisplayMax ;
    Property EventF0SubtractF0 : Boolean
             read FEventF0SubtractF0 write FEventF0SubtractF0 ;

    Property FrameTypeCycleLength : Integer read FFrameTypeCycleLength ;

    Property FileHeader : string read GetFileHeader ;

  end;

procedure Register;

implementation


constructor TIDRFile.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
var
     i : Integer ;
begin

     inherited Create(AOwner) ;

     FIDRFileHandle := INVALID_HANDLE_VALUE ;
     FEDRFileHandle := -1 ;

     FNumIDRHeaderBytes :=  cNumIDRHeaderBytes ;
     FNumEDRHeaderBytes :=  cNumEDRHeaderBytes ;

     FFileName := '' ;

     FFrameWidth := 0 ;
     FFrameHeight := 0 ;
     FPixelDepth := 0 ;
     FNumFrames := 0 ;
     FLineScan := False ;
     FLSTimeCoursePixel := 0 ;
     FLSTimeCourseNumAvg := 1 ;
     FLSTimeCourseBackgroundPixel := 0 ;
     FLSSubtractBackground := False ;

     FImageStartDelay := 0.0 ;

     // Image intensity measurement scaling
     FIntensityScale := 1.0 ;
     FIntensityOffset := 0.0 ;

     FResolutionUnits := '' ;
     FXResolution := 1.0 ;
     FYResolution := 1.0 ;

    FNumZSections := 1 ;
    FZStart :=0.0 ;
    FZSpacing := 1.0 ;

     FMaxROI := cMaxROIs ;

     FIdent := '' ;

     // Clear marker list
     FNumMarkers := 0 ;

     // Frame type
     FNumFrameTypes := 1 ;
     for i := 0 to High(FFrameTypes) do begin
         FFrameTypes[i] := format('Fr.%d',[i]) ;
         FFrameTypeDivideFactor[i] := 1 ;
         end ;

     for i := 0 to High(FFrameTypeCycle) do FFrameTypeCycle[i] := 0 ;
     FFrameTypeCycleLength := 1 ;

     // Binding equations
     FMaxEquations := High(FEquations) + 1 ;
     for i := 0 to High(FEquations) do begin
         FEquations[i].InUse := False ;
         FEquations[i].Name := format('Eqn.%d',[i]) ;
         FEquations[i].Ion := '??' ;
         FEquations[i].Units := 'nM' ;
         FEquations[i].RMin := 1.0 ;
         FEquations[i].RMax := 2.0 ;
         FEquations[i].KEff := 1E-6 ;
         end ;

     // Analogue signal channels
     FADCMaxChannels := High(Channels) + 1 ;
     for i := 0 to High(Channels) do begin
         Channels[i].ADCZero := 0 ;
         Channels[i].ADCZeroAt := 0 ;
         Channels[i].ADCSCale := 1.0 ;
         Channels[i].ADCCalibrationFactor := 1.0 ;
         Channels[i].ADCAmplifierGain := 1.0 ;
         Channels[i].ADCUnits := 'mV' ;
         Channels[i].ADCName := format('Ch.%d',[i]) ;
         Channels[i].InUse := True ;
         Channels[i].ChannelOffset := i ;
         end ;

    // Flag indicates that no file with A/D samples has been opened
    NoPreviousOpenFile := True ;

    // Regions of interest
    for i := 0 to High(FROIs) do begin
        FROIs[i].InUse := False ;
        FROIs[i].Shape := PointROI ;
        FROIs[i].TopLeft := Point(0,0) ;
        FROIs[i].BottomRight := Point(0,0) ;
        FROIs[i].Centre := Point(0,0) ;
        FROIs[i].Width := 0 ;
        FROIs[i].Height := 0 ;
        FROIs[i].ZoomFactor := 0 ;
        FROIs[i].NumPoints := 0 ;
        end ;

     // Initial spectrum data
     FSpectralDataFile := False ;
     FSpectrumStartWavelength := 0.0 ;
     FSpectrumEndWavelength := 0.0 ;
     FSpectrumBandwidth := 0.0 ;
     FSpectrumStepSize := 0.0 ;

     FEventDisplayDuration := 1.0 ;

    FEventRatioExclusionThreshold := 0 ;
    FEventDeadTime := 1.0 ;
    FEventDetectionThreshold := 1000 ;
    FEventThresholdDuration := 0.0 ;
    FEventDetectionThresholdPolarity := 0  ;
    FEventDetectionSource := 0 ;
    FEventROI := 0 ;
    FEventBackgROI := 0 ;

    FEventFixedBaseline := True ;
    FEventRollingBaselinePeriod := 1.0 ;
    FEventBaselineLevel := 0 ;

    FEventRatioTop := 0 ;
    FEventRatioBottom := 1 ;
    FEventRatioDisplayMax := 10.0 ;
    FEventRatioRMax := 1.0 ; ;
    FEventFLWave := 0 ;
    FEventF0Wave := 0 ;
    FEventF0Start := 1 ;
    FEventF0End := 1 ;
    FEventF0Constant := 0.0 ;
    FEventF0UseConstant := False ;
    FEventF0DisplayMax := 10.0 ;
    FEventF0SubtractF0 := False  ;

     AsyncWriteBuf := Nil ;
     FAsyncBufferOverflow := False ;
     FAsyncWriteBufSize := 0 ;
     AsyncNumBytesToWrite := 0 ;

     // Create internal frame buffer
     GetMem( PInternalBuf, MaxBytesPerFrame ) ;

     end ;


destructor TIDRFile.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Close image file
     CloseFile ;

     // Free internal buffer
     FreeMem(PInternalBuf) ;

     // Free asynchronous write buffer
     if AsyncWriteBuf <> Nil then FreeMem(AsyncWriteBuf) ;

     { Call inherited destructor }
     inherited Destroy ;

     end ;


function TIDRFile.CreateNewFile(
         FileName : String        // Name of file to be created
          ) : Boolean ;           // Returns TRUE if file created OK
// ---------------------------
// Create empty IDR data file
// ---------------------------
var
    EDRFileName : String ;
    FilePath : String ;
    CurrentDate : TDateTime ;
begin

    Result := False ;

    if FIDRFileHandle <> INVALID_HANDLE_VALUE then begin
       ShowMessage( 'A file is aready open ' ) ;
       Exit ;
       end ;

    // Create directory for file (if one does not exist already)

    FilePath := ExtractFilePath(FileName) ;
    if not DirectoryExists(FilePath) then begin
       if not CreateDir(FilePath) then begin
          ShowMessage( 'Unable to create folder ' + FilePath ) ;
          Exit ;
          end
       else begin
          ShowMessage( 'Folder ' + FilePath + ' created!' ) ;
          end ;
       end ;

    // Create IDR file
    FFileName := FileName ;
    IDRFileCreate(FileName) ;

    if FIDRFileHandle = INVALID_HANDLE_VALUE then begin
       ShowMessage( 'Unable to create ' ) ;
       Exit ;
       end ;

    FWriteEnabled := True ;

    // Create EDR file
    EDRFileName :=  ChangeFileExt( FFileName, '.EDR' ) ;
    FEDRFileHandle := FileCreate( EDRFileName, fmOpenReadWrite ) ;
    if FEDRFileHandle < 0 then begin
       ShowMessage( 'Unable to create ' + EDRFileName ) ;
       Exit ;
       end ;

    // Set file header size to current default size
    FNumIDRHeaderBytes := cNumIDRHeaderBytes ;
    FNumEDRHeaderBytes := cNumEDRHeaderBytes ;
    FMaxROI := cMaxROIs ;

    // Compute size of frame
    ComputeFrameSize ;

    // Image intensity measurement scaling
    FIntensityScale := 1.0 ;
    FIntensityOffset := 0.0 ;

    FNumFrames := 0 ;
    FADCNumSamplesInFile := 0 ;
    FADCNumScansInFile := 0 ;
    FNumMarkers := 0 ;
    FIdent := '' ;

    // Date of creation
    CurrentDate := FileDateToDateTime(FileGetDate(FIDRFileHandle)) ;
    FYearCreated := YearOf(CurrentDate) ;
    FMonthCreated := MonthOfTheYear(CurrentDate) ;
    FDayCreated := DayofTheMonth(CurrentDate) ;

    Result := True ;

    end ;


function TIDRFile.CreateFileFrom(
         FileName : String ;      // Name of file to be created
         Source : TIDRFile ;      // Source IDR file
         CopyADCSamples : Boolean
          ) : Boolean ;           // Returns TRUE if file created OK
// ---------------------------
// Create empty IDR data file
// ---------------------------
var
    i : Integer ;
    EDRFileName : String ;
    ADCBuf : Array[0..MaxChannel] of SmallInt ;
begin

    Result := False ;

    if FIDRFileHandle <> INVALID_HANDLE_VALUE then begin
       ShowMessage( 'Unable to create: ' + FileName + 'Another file is aready open!' ) ;
       Exit ;
       end ;

    // Open file
    FFileName := FileName ;
    IDRFileCreate( FFileName ) ;
    if FIDRFileHandle = INVALID_HANDLE_VALUE then begin
       ShowMessage( 'TIDRFile: Unable to create ' + FFileName ) ;
       Exit ;
       end ;

    // Indicate that file can be written to
    FWriteEnabled := True ;

    // Initialise file header`
    FFrameWidth := Source.FrameWidth ;
    FFrameHeight := Source.FrameHeight ;
    FPixelDepth := Source.PixelDepth ;
    FFrameInterval := Source.FrameInterval ;
    FIntensityScale := Source.IntensityScale ;
    FIntensityOffset := Source.IntensityOffset ;
    FXResolution := Source.XResolution ;
    FResolutionUnits := Source.ResolutionUnits ;

    FNumZSections := Source.NumZSections ;
    FZStart := Source.ZStart ;
    FZSpacing := Source.ZSpacing ;

    // Set file header size to current default size
    FNumIDRHeaderBytes := cNumIDRHeaderBytes ;
    FNumEDRHeaderBytes := cNumEDRHeaderBytes ;
    FMaxROI := cMaxROIs ;

    // Compute size of frame
    ComputeFrameSize ;

    // Frame type
    FNumFrameTypes := Source.NumFrameTypes ;
    for i := 0 to FNumFrameTypes-1 do begin
        FFrameTypes[i] := Source.FrameType[i] ;
        FFrameTypeDivideFactor[i] := Source.FrameTypeDivideFactor[i] ;
        end ;

     // Create frame type cycle
     CreateFrameTypeCycle( FFrameTypeCycle, FFrameTypeCycleLength ) ;

     // Binding equations
    for i := 0 to High(FEquations) do FEquations[i] := Source.Equation[i] ;

    // Marker list
    FNumMarkers := Source.NumMarkers ;
    for i := 0 to Source.NumMarkers-1 do begin
         FMarkerTime[i] := Source.MarkerTime[i] ;
         FMarkerText[i] := Source.MarkerText[i] ;
         end ;

    // Analogue signal channels

    FADCNumChannels := Source.ADCNumChannels ;
    FADCNumScansPerFrame := Source.ADCNumScansPerFrame ;
    FADCNumScansInFile := Source.ADCNumScansInFile ;
    FADCMaxValue := Source.ADCMaxValue ;
    FADCSCanInterval := Source.ADCSCanInterval ;
    FADCVoltageRange := Source.ADCVoltageRange ;
    for i := 0 to FADCNumChannels-1 do Channels[i] := Source.ADCChannel[i] ;

    FSpectralDataFile := Source.SpectralDataFile ;
    FSpectrumStartWavelength := Source.SpectrumStartWavelength  ;
    FSpectrumEndWavelength := Source.SpectrumEndWavelength ;
    FSpectrumBandwidth := Source.SpectrumBandwidth ;
    FSpectrumStepSize := Source.SpectrumStepSize ;

    FEventDisplayDuration := Source.EventDisplayDuration ;
    FEventRatioExclusionThreshold := Source.EventRatioExclusionThreshold ;
    FEventDeadTime := Source.EventDeadTime ;
    FEventDetectionThreshold := Source.EventDetectionThreshold  ;
    FEventThresholdDuration := Source.EventThresholdDuration ;
    FEventDetectionThresholdPolarity := Source.EventDetectionThresholdPolarity  ;
    FEventDetectionSource := Source.EventDetectionSource ;
    FEventROI := Source.EventROI ;
    FEventBackgROI := Source.EventBackgROI ;

    FEventFixedBaseline := Source.EventFixedBaseline ;
    FEventBaselineLevel := Source.EventBaselineLevel ;
    FEventRollingBaselinePeriod := Source.EventRollingBaselinePeriod ;

    FEventRatioExclusionThreshold := Source.EventRatioExclusionThreshold ;
    FEventRatioTop  := Source.EventRatioTop ;
    FEventRatioBottom  := Source.EventRatioBottom ;
    FEventRatioDisplayMax  := Source.EventRatioDisplayMax ;
    FEventRatioRMax  := Source.EventRatioRMax ;
    FEventFLWave  := Source.EventFLWave ;
    FEventF0Wave  := Source.EventF0Wave ;
    FEventF0Start  := Source.EventF0Start ;
    FEventF0End  := Source.EventF0End ;
    FEventF0Constant  := Source.EventF0Constant ;
    FEventF0UseConstant  := Source.EventF0UseConstant ;
    FEventF0DisplayMax  := Source.EventF0DisplayMax ;
    FEventF0SubtractF0  := Source.EventF0SubtractF0  ;

    // Create EDR file
    EDRFileName :=  ChangeFileExt( FFileName, '.EDR' ) ;
    FEDRFileHandle := FileCreate( EDRFileName, fmOpenReadWrite ) ;
    if FEDRFileHandle < 0 then begin
       ShowMessage( 'Unable to create A/D data file: ' + EDRFileName ) ;
       Exit ;
       end ;

    if CopyADCSamples then begin
       // Copy A/D samples into EDR file
       if (FADCNumScansInFile > 0) and (FEDRFileHandle > 0) then begin
          // Move to end of header block
          FileSeek( Source.EDRFileHandle,FNumEDRHeaderBytes,0) ;
          FileSeek( FEDRFileHandle,FNumEDRHeaderBytes,0) ;
          for i := 1 to Source.ADCNumScansInFile do begin
              FileRead( Source.EDRFileHandle, ADCBuf, FADCNumChannels*2 ) ;
              FileWrite( FEDRFileHandle, ADCBuf, FADCNumChannels*2 ) ;
              end ;
          end ;
       end
    else begin
       FADCNumScansInFile := 0 ;
       end ;

    // Regions of interest
    for i := 0 to High(FROIs) do FROIs[i] := Source.ROI[i] ;

    FNumFrames := 0 ;
    Result := True ;

    end ;



function TIDRFile.OpenFile(
         FileName : String     // Name of IDR file (IN)
          ) : Boolean ;        // Returns TRUE if file open successful
// ---------------------------
// Open image file (READ ONLY)
// ---------------------------
var
     EDRFileName : String ;
     ch : Integer ;
begin

     if FIDRFileHandle <> INVALID_HANDLE_VALUE then begin
       ShowMessage( 'A file is aready open ' ) ;
       Exit ;
       end ;

     // Open IDR file (READ ONLY)
     FFileName := FileName ;
     IDRFileOpen( FFileName, fmOpenRead ) ;
     if FIDRFileHandle = INVALID_HANDLE_VALUE then begin
        ShowMessage( 'Unable to open ' + FileName ) ;
        Exit ;
        end ;
     FWriteEnabled := False ;

     // Load file header data
     GetIDRHeader ;

     // Create frame type cycle
     CreateFrameTypeCycle( FFrameTypeCycle, FFrameTypeCycleLength ) ;

     if FIntensityScale = 1.0 then FIntensityOffset := 0.0 ;

     // Open EDR file
     EDRFileName :=  ChangeFileExt( FFileName, '.EDR' ) ;
     if FileExists( EDRFileName ) then begin
        FEDRFileHandle := FileOpen( EDRFileName, fmOpenRead ) ;
        if (FADCNumChannels <= 0) or (FADCNumScansInFile <= 0) then GetEDRHeader ;
        FADCNumSamplesInFile := FADCNumScansInFile*FADCNumChannels ;
        if NoPreviousOpenFile then begin
           for ch := 0 to MaxChannel do begin
               Channels[ch].YMax := FADCMaxValue ;
               Channels[ch].YMin := -FADCMaxValue - 1;
               end ;
           NoPreviousOpenFile := False ;
           end ;
        end
     else begin
        FADCNumChannels := 0 ;
        end ;
     end ;


procedure TIDRFile.CloseFile ;
{ -----------------
   Close IDR file
   ---------------- }
begin

     // Close image file
     if FIDRFileHandle <> INVALID_HANDLE_VALUE then begin
        SaveIDRHeader ;
        IDRFileClose ;
        FIDRFileHandle := INVALID_HANDLE_VALUE ;
        end ;

     if FEDRFileHandle > 0 then begin
        SaveEDRHeader ;
        FileClose( FEDRFileHandle ) ;
        FEDRFileHandle := -1 ;
        end ;
     end ;


function TIDRFile.IsIDRFileOpen : Boolean ;
// -------------------------------
// Return TRUE if IDR file is open
// -------------------------------
begin
    if FIDRFileHandle <> INVALID_HANDLE_VALUE then Result := True
                                              else Result := False ;
    end ;

function TIDRFile.GetNumFramesPerSpectrum : Integer ;
// --------------------------
// No. of frames per spectrum
// --------------------------
begin
    if FSpectrumStepSize > 0.0 then begin
       Result := Max(Round(
                 (FSpectrumEndWavelength - FSpectrumStartWavelength) /
                  FSpectrumStepSize)+1,
                  1) ;
       end
    else Result := 1 ;

    end ;


function TIDRFile.GetNumFrameTypes : Integer ;
// ----------------------------
// Return number of frame types
// ----------------------------
begin
     if FSpectralDataFile then Result := GetNumFramesPerSpectrum
                          else Result := FNumFrameTypes ;
     end ;

procedure TIDRFile.SetNumFrameTypes( Value : Integer ) ;
// -------------------------
// Set number of frame types
// -------------------------
begin

    FNumFrameTypes := Value ;

    // Create frame type cycle
     CreateFrameTypeCycle( FFrameTypeCycle, FFrameTypeCycleLength ) ;

    end ;

procedure TIDRFile.GetIDRHeader ;
// ------------------------
// Load IDR data file header
// ------------------------
var

   i,j,ch,NumBytesInHeader : Integer ;
   iValue : Integer ;
   NumMarkers : Integer ;
   MarkerTime : Single ;
   MarkerText : String ;
   FileDate : TDateTime ;
   NumFrameActual : Integer ;
   NumBytesPerFrame : Integer ;
   NumBytesInFile : Int64 ;
begin

     // Read file header
     IDRFileRead( @Header, 0, Sizeof(Header) ) ;

     { Get default size of file header }
     FNumIDRHeaderBytes := cNumIDRHeaderBytes ;
     { Get size of file header for this file }
     ReadInt( Header, 'NBH=', FNumIDRHeaderBytes ) ;

     // File creation date

     FYearCreated := 0 ;
     FMonthCreated := 0 ;
     FDayCreated := 0 ;
     ReadInt( Header, 'YEAR=', FYearCreated ) ;
     ReadInt( Header, 'MONTH=', FMonthCreated ) ;
     ReadInt( Header, 'DAY=', FDayCreated ) ;

     // Frame parameters
     ReadFloat( Header, 'FI=', FFrameInterval ) ;
     ReadInt( Header, 'FW=', FFrameWidth ) ;

     ReadInt( Header, 'FH=', FFrameHeight ) ;

     ReadInt( Header, 'NBPP=', FNumBytesPerPixel ) ;
     ReadInt( Header, 'NF=', FNumFrames ) ;

     ReadInt(Header, 'ZNUMS=',FNumZSections) ;
     FNumZSections := Max(FNumZSections,1) ;
     ReadFloat( Header, 'ZSTART=',FZStart) ;
     ReadFloat( Header, 'ZSPACING=',FZSpacing) ;

     // Correct number of frames list in file header
     NumBytesPerFrame := FFrameHeight*FFrameWidth*FNumBytesPerPixel ;
     FNumBytesPerFrame := NumBytesPerFrame ;
     // Prevent divide by zero exception
     if NumBytesPerFrame > 0 then begin
        NumBytesInFile := IDRGetFileSize ;
        NumFrameActual := Integer( (NumBytesInFile - Int64(FNumIDRHeaderBytes))
                                   div Int64(NumBytesPerFrame) ) ;
        outputdebugstring(pchar(format('Numbytesinfile=%d,NumFramesActual=%d,NumFrames=%d'
        ,[NumBytesInFile,NumFrameActual,FNumFrames])));
{        if NumFrameActual <> FNumFrames then begin
           if MessageDlg(
              format('No. of frames (%d) does not match size of file (%d). Correct?',
              [FNumFrames,NumFrameActual]),
              mtConfirmation,[mbYes,mbNo], 0 ) = mrYes then FNumFrames := NumFrameActual ;
           end ;}
        end;

     // Line scan flag
     ReadLogical( Header, 'LINESCAN=', FLineScan ) ;
     // Line scan interval correction factor
     FImageStartDelay := 0.0 ;
     ReadFloat( Header, 'IMGDELAY=', FImageStartDelay ) ;

     ReadInt( Header, 'LSTCPIX=',FLSTimeCoursePixel);               // 5.8.10 JD
     ReadInt( Header, 'LSTCNAVG=',FLSTimeCourseNumAvg);
     ReadInt( Header, 'LSTCBKPIX=',FLSTimeCourseBackgroundPixel);
     ReadLogical( Header, 'LSTCBKSUB=',FLSSubtractBackground) ;

     ReadInt( Header, 'GRMAX=', FGreyMax ) ;
     if FGreyMax = 0 then FGreyMax := 4095 ;

     i := 1 ;
     FPixelDepth := 0 ;
     while i < (FGreyMax+1) do begin
        i := i*2 ;
        Inc(FPixelDepth) ;
        end ;

     ReadInt( Header, 'PIXDEP=', FPixelDepth ) ;

     FIntensityScale := 1.0 ;
     ReadFloat( Header, 'ISCALE=', FIntensityScale ) ;
     FIntensityOffset := 0.0 ;
     ReadFloat( Header, 'IOFFSET=', FIntensityOffset ) ;

     // Pixel width
     FXResolution := 1.0 ;
     ReadFloat( Header, 'XRES=', FXResolution ) ;
     if FXResolution = 0.0 then FXResolution := 1.0 ;

     // Pixel width units
     FResolutionUnits := '' ;
     ReadString( Header, 'RESUNITS=', FResolutionUnits ) ;

     FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
     FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

     // Types of frame
     ReadInt( Header, 'NFTYP=', FNumFrameTypes ) ;
     for i := 0 to FNumFrameTypes-1 do begin
         ReadString( Header, format('FTYP%d=',[i]),FFrameTypes[i] ) ;
         FFrameTypeDivideFactor[i] := 1 ;
         ReadInt( Header, format('FTYPDF%d=',[i]),FFrameTypeDivideFactor[i] ) ;
         end ;

     if NumFrameTypes <= 0 then begin
        FNumFrameTypes := 1 ;
        FFrameTypes[0] := 'Unknown' ;
        end ;

     // Ensure no. of frame types equal to no. frames for line scans
     if FLineScan and (NumFrameTypes < NumFrames) then begin
        NumFrameTypes := NumFrames ;
        for i := 0 to FNumFrameTypes-1 do begin
            FFrameTypes[i] := format('Ch.%d',[i+1]) ;
            FFrameTypeDivideFactor[i] := 1 ;
            end ;
        end ;

     // A/D channel settings
     ReadInt( Header, 'ADCNC=', FADCNumChannels ) ;
     ReadInt( Header, 'ADCNSPF=', FADCNumScansPerFrame ) ;
     ReadInt( Header, 'ADCNSC=', FADCNumScansInFile ) ;
     ReadInt( Header, 'ADCMAX=', FADCMaxValue ) ;
     ReadFloat( Header, 'ADCSI=', FADCSCanInterval ) ;

     if FADCSCanInterval = 0.0 then begin
        if FADCNumScansPerFrame > 0 then
           FADCSCanInterval := FFrameInterval/FADCNumScansPerFrame
        else FADCSCanInterval := 1.0 ;
        FADCSCanInterval := Trunc(FADCSCanInterval/0.0001)*0.0001 ;
        end ;

     ReadFloat( Header, 'ADCVR=', FADCVoltageRange ) ;
     if Abs(FADCVoltageRange) < 1E-3 then FADCVoltageRange := 10.0 ;
     for ch := 0 to FADCNumChannels-1 do begin
         ReadInt(    Header, format('CIN%d=',[ch]), Channels[ch].ChannelOffset) ;
         ReadString( Header, format('CU%d=',[ch]), Channels[ch].ADCUnits ) ;
         ReadString( Header, format('CN%d=',[ch]), Channels[ch].ADCName ) ;
         ReadFloat( Header, format('CCF%d=',[ch]), Channels[ch].ADCCalibrationFactor ) ;
         ReadFloat( Header, format('CAG%d=',[ch]), Channels[ch].ADCAmplifierGain ) ;
         ReadFloat( Header, format('CSC%d=',[ch]), Channels[ch].ADCScale) ;
         end ;

     // Update A/D channel scaling factors
     UpdateChannelScalingFactors( Channels,
                                  FADCNumChannels,
                                  FADCVoltageRange,
                                  FADCMaxValue )  ;

     // Fluophore binding equation table
     for i := 0 to High(FEquations) do begin
         ReadLogical( Header, format('EQNUSE%d=',[i]), FEquations[i].InUse) ;
         ReadString( Header, format('EQNNAM%d=',[i]), FEquations[i].Name) ;
         ReadString( Header, format('EQNION%d=',[i]), FEquations[i].Ion) ;
         ReadString( Header, format('EQNUN%d=',[i]), FEquations[i].Units) ;
         ReadFloat( Header, format('EQNRMAX%d=',[i]), FEquations[i].RMax) ;
         ReadFloat( Header, format('EQNRMIN%d=',[i]), FEquations[i].RMin) ;
         ReadFloat( Header, format('EQNKEFF%d=',[i]), FEquations[i].KEff) ;
         end ;

     // Regions of Interest

     // Determine space for ROIs in this file
     if FNumIDRHeaderBytes = cNumIDRHeaderBytes then FMaxROI := cMaxROIs
                                                else FMaxROI := 10 ;

     for i := 0 to FMaxROI do begin
         FROIs[i].InUse := False ;
         ReadLogical( Header, format('ROIUSE%d=',[i]),FROIs[i].InUse ) ;
         if FROIs[i].InUse then begin
            ReadInt( Header, format('ROISHP%d=',[i]), iValue ) ;
            FROIs[i].Shape := iValue ;
            ReadInt( Header, format('ROITLX%d=',[i]), FROIs[i].TopLeft.x ) ;
            ReadInt( Header, format('ROITLY%d=',[i]), FROIs[i].TopLeft.y ) ;
            ReadInt( Header, format('ROIBRX%d=',[i]), FROIs[i].BottomRight.x ) ;
            ReadInt( Header, format('ROIBRY%d=',[i]), FROIs[i].BottomRight.y ) ;
            FROIs[i].Centre.x := (FROIs[i].TopLeft.x + FROIs[i].BottomRight.x) div 2 ;
            FROIs[i].Centre.y := (FROIs[i].TopLeft.y + FROIs[i].BottomRight.y) div 2 ;
            FROIs[i].Width := Abs(FROIs[i].BottomRight.x - FROIs[i].TopLeft.x ) ;
            FROIs[i].Height := Abs(FROIs[i].BottomRight.y - FROIs[i].TopLeft.y ) ;
            ReadInt( Header, format('ROINP%d=',[i]), FROIs[i].NumPoints ) ;
            for j := 0 to FROIs[i].NumPoints-1 do begin
                ReadInt( Header, format('ROI%dX%d=',[i,j]), FROIs[i].XY[j].X ) ;
                ReadInt( Header, format('ROI%dY%d=',[i,j]), FROIs[i].XY[j].Y ) ;
                end ;
            end ;
         end ;

     // Read experiment comment line
     FIdent := '' ;
     ReadString( Header, 'ID=', FIdent ) ;

     // Spectrum data
     ReadLogical( Header, 'SPECDATAFILE=',FSpectralDataFile ) ;
     ReadFloat( Header, 'SPECSTARTW=',FSpectrumStartWavelength)  ;
     ReadFloat( Header, 'SPECENDW',FSpectrumEndWavelength) ;
     ReadFloat( Header, 'SPECBW=',FSpectrumBandwidth) ;
     ReadFloat( Header, 'SPECSTEP=',FSpectrumStepSize) ;

     // Event data
    ReadFloat( Header, 'EVDISPD=',FEventDisplayDuration ) ;

    ReadInt(Header, 'EVREXCLT=',FEventRatioExclusionThreshold) ; // 5.8.10 JD
    ReadFloat( Header, 'EVDEADT=',FEventDeadTime) ;
    ReadFloat(Header, 'EVTHRESH=',FEventDetectionThreshold) ;
    ReadFloat( Header, 'EVTHRDUR=',FEventThresholdDuration) ;
    ReadInt(Header, 'EVTHRPOL=',FEventDetectionThresholdPolarity)  ;
    ReadInt(Header, 'EVDETSRC=',FEventDetectionSource) ;
    ReadInt(Header, 'EVROI=',FEventROI) ;
    ReadInt(Header, 'EVBACKGROI=',FEventBackgROI) ;
    ReadLogical(Header,'EVBASEFX=',FEventFixedBaseline) ;
    ReadInt(Header, 'EVBASELEV=',FEventBaselineLevel) ;
    ReadFloat( Header, 'EVBASRL=',FEventRollingBaselinePeriod) ;

    ReadInt(Header, 'EVRTOP=',FEventRatioTop) ;                  // Event detector settings
    ReadInt(Header, 'EVRBOT=',FEventRatioBottom) ;
    ReadFloat( Header, 'EVRDMAX=',FEventRatioDisplayMax) ;
    ReadFloat( Header, 'EVRMAX=',FEventRatioRMax) ; ;
    ReadInt(Header, 'EVFLWAVE=',FEventFLWave) ;
    ReadInt(Header, 'EVF0WAVE=',FEventF0Wave) ;
    ReadInt(Header, 'EVF0STA=',FEventF0Start) ;
    ReadInt(Header, 'EVF0END=',FEventF0End) ;
    ReadFloat( Header, 'EVF0CONS=',FEventF0Constant) ;
    ReadLogical(Header,'EVF0USEC=',FEventF0UseConstant) ;
    ReadFloat( Header, 'EVF0DMAX=',FEventF0DisplayMax) ;
    ReadLogical(Header,'EVF0SUBF0=',FEventF0SubtractF0)  ;


     { Read Markers }
     FNumMarkers := 0 ;
     ReadInt( Header, 'MKN=', FNumMarkers ) ;
     for i := 0 to FNumMarkers-1 do begin
         ReadFloat( Header, format('MKTIM%d=',[i]), FMarkerTime[i] ) ;
         ReadString( Header, format('MKTXT%d=',[i]), FMarkerText[i] ) ;
         end ;

     end ;


procedure TIDRFile.SaveIDRHeader ;
// ------------------------
// Save IDR data file header
// ------------------------
var
   i,j,ch : Integer ;
begin

     if FIDRFileHandle = INVALID_HANDLE_VALUE then Exit ;
     HeaderFull := False ;

     if not FWriteEnabled then SetWriteEnabled(True) ;

     // Initialise empty header buffer with zero bytes
     for i := 1 to sizeof(Header) do Header[i] := chr(0) ;

     // File creation date
     AppendInt( Header, 'YEAR=', FYearCreated ) ;
     AppendInt( Header, 'MONTH=', FMonthCreated ) ;
     AppendInt( Header, 'DAY=', FDayCreated ) ;

     { Get size of file header for this file }
     AppendInt( Header, 'NBH=', FNumIDRHeaderBytes ) ;

     // Frame parameters
     AppendFloat( Header, 'FI=', FFrameInterval ) ;
     AppendInt( Header, 'FW=', FFrameWidth ) ;
     AppendInt( Header, 'FH=', FFrameHeight ) ;
     AppendInt( Header, 'NBPP=', FNumBytesPerPixel ) ;
     AppendInt( Header, 'PIXDEP=', FPixelDepth ) ;

     AppendInt(Header, 'ZNUMS=',FNumZSections) ;
     AppendFloat( Header, 'ZSTART=',FZStart) ;
     AppendFloat( Header, 'ZSPACING=',FZSpacing) ;

     // Line scan flag
     AppendLogical( Header, 'LINESCAN=', FLineScan ) ;
     AppendFloat( Header, 'IMGDELAY=', FImageStartDelay ) ;

     AppendInt( Header, 'LSTCPIX=',FLSTimeCoursePixel);               // 5.8.10 JD
     AppendInt( Header, 'LSTCNAVG=',FLSTimeCourseNumAvg);
     AppendInt( Header, 'LSTCBKPIX=',FLSTimeCourseBackgroundPixel);
     AppendLogical( Header, 'LSTCBKSUB=',FLSSubtractBackground) ;

     AppendFloat( Header, 'ISCALE=', FIntensityScale ) ;
     AppendFloat( Header, 'IOFFSET=', FIntensityOffset ) ;

     // Get number of frames in file ;
     //FNumFrames := GetNumFramesInFile ;
     AppendInt( Header, 'NF=', FNumFrames ) ;

     AppendInt( Header, 'GRMAX=', FGreyMax ) ;

     AppendFloat( Header, 'XRES=', FXResolution ) ;

     AppendString( Header, 'RESUNITS=', FResolutionUnits ) ;

     // Types of frame
     AppendInt( Header, 'NFTYP=', FNumFrameTypes ) ;
     for i := 0 to FNumFrameTypes-1 do begin
         AppendString( Header, format('FTYP%d=',[i]),FFrameTypes[i] ) ;
         AppendInt( Header, format('FTYPDF%d=',[i]),FFrameTypeDivideFactor[i] ) ;
         end ;

     // A/D channel settings
     AppendInt( Header, 'ADCNC=', FADCNumChannels ) ;
     AppendInt( Header, 'ADCNSPF=', FADCNumScansPerFrame ) ;
     AppendInt( Header, 'ADCNSC=', FADCNumScansInFile ) ;
     AppendInt( Header, 'ADCMAX=', FADCMaxValue ) ;
     AppendFloat( Header, 'ADCSI=', FADCSCanInterval ) ;

     AppendFloat( Header, 'ADCVR=', FADCVoltageRange ) ;
     for ch := 0 to FADCNumChannels-1 do begin
        AppendInt(    Header, format('CIN%d=',[ch]), Channels[ch].ChannelOffset) ;
        AppendString( Header, format('CU%d=',[ch]), Channels[ch].ADCUnits ) ;
        AppendString( Header, format('CN%d=',[ch]), Channels[ch].ADCName ) ;
        AppendFloat( Header, format('CCF%d=',[ch]), Channels[ch].ADCCalibrationFactor ) ;
        AppendFloat( Header, format('CAG%d=',[ch]), Channels[ch].ADCAmplifierGain ) ;
        AppendFloat( Header, format('CSC%d=',[ch]), Channels[ch].ADCScale) ;
        end ;

     // Fluophore binding equation table
     for i := 0 to High(FEquations) do begin
         AppendLogical( Header, format('EQNUSE%d=',[i]), FEquations[i].InUse) ;
         AppendString( Header, format('EQNNAM%d=',[i]), FEquations[i].Name) ;
         AppendString( Header, format('EQNION%d=',[i]), FEquations[i].Ion) ;
         AppendString( Header, format('EQNUN%d=',[i]), FEquations[i].Units) ;
         AppendFloat( Header, format('EQNRMAX%d=',[i]), FEquations[i].RMax) ;
         AppendFloat( Header, format('EQNRMIN%d=',[i]), FEquations[i].RMin) ;
         AppendFloat( Header, format('EQNKEFF%d=',[i]), FEquations[i].KEff) ;
         end ;

     // Regions of Interest
     for i := 0 to FMaxROI do if FROIs[i].InUse then begin
         AppendLogical( Header, format('ROIUSE%d=',[i]),FROIs[i].InUse ) ;
         AppendInt( Header, format('ROISHP%d=',[i]), Integer(FROIs[i].Shape) ) ;
         AppendInt( Header, format('ROITLX%d=',[i]), FROIs[i].TopLeft.x ) ;
         AppendInt( Header, format('ROITLY%d=',[i]), FROIs[i].TopLeft.y ) ;
         AppendInt( Header, format('ROIBRX%d=',[i]), FROIs[i].BottomRight.x ) ;
         AppendInt( Header, format('ROIBRY%d=',[i]), FROIs[i].BottomRight.y ) ;
         AppendInt( Header, format('ROINP%d=',[i]), FROIs[i].NumPoints ) ;
         for j := 0 to FROIs[i].NumPoints-1 do begin
             AppendInt( Header, format('ROI%dX%d=',[i,j]), FROIs[i].XY[j].X ) ;
             AppendInt( Header, format('ROI%dY%d=',[i,j]), FROIs[i].XY[j].Y ) ;
             end ;
         end ;

     // Spectrum data
     AppendLogical( Header, 'SPECDATAFILE=',FSpectralDataFile ) ;
     AppendFloat( Header, 'SPECSTARTW=',FSpectrumStartWavelength)  ;
     AppendFloat( Header, 'SPECENDW',FSpectrumEndWavelength) ;
     AppendFloat( Header, 'SPECBW=',FSpectrumBandwidth) ;
     AppendFloat( Header, 'SPECSTEP=',FSpectrumStepSize) ;

     // Event data
     AppendFloat( Header, 'EVDISPD=',FEventDisplayDuration ) ;
    AppendFloat( Header, 'EVDEADT=',FEventDeadTime) ;            // 6.8.10 JD
    AppendFloat(Header, 'EVTHRESH=',FEventDetectionThreshold) ;
    AppendFloat( Header, 'EVTHRDUR=',FEventThresholdDuration) ;
    AppendInt(Header, 'EVTHRPOL=',FEventDetectionThresholdPolarity)  ;
    AppendInt(Header, 'EVDETSRC=',FEventDetectionSource) ;
    AppendInt(Header, 'EVROI=',FEventROI) ;
    AppendInt(Header, 'EVBACKGROI=',FEventBackgROI) ;
    AppendLogical(Header,'EVBASEFX=',FEventFixedBaseline) ;
    AppendInt(Header, 'EVBASELEV=',FEventBaselineLevel) ;
    AppendFloat( Header, 'EVBASRL=',FEventRollingBaselinePeriod) ;

    AppendInt(Header, 'EVREXCLT=',FEventRatioExclusionThreshold) ;
    AppendInt(Header, 'EVRTOP=',FEventRatioTop) ;                  // Event detector settings
    AppendInt(Header, 'EVRBOT=',FEventRatioBottom) ;
    AppendFloat( Header, 'EVRDMAX=',FEventRatioDisplayMax) ;
    AppendFloat( Header, 'EVRMAX=',FEventRatioRMax) ; ;
    AppendInt(Header, 'EVFLWAVE=',FEventFLWave) ;
    AppendInt(Header, 'EVF0WAVE=',FEventF0Wave) ;
    AppendInt(Header, 'EVF0STA=',FEventF0Start) ;
    AppendInt(Header, 'EVF0END=',FEventF0End) ;
    AppendFloat( Header, 'EVF0CONS=',EventF0Constant) ;
    AppendLogical(Header,'EVF0USEC=',FEventF0UseConstant) ;
    AppendFloat( Header, 'EVF0DMAX=',FEventF0DisplayMax) ;
    AppendLogical(Header,'EVF0SUBF0=',FEventF0SubtractF0)  ;

     // Append experiment comment line
     AppendString( Header, 'ID=', FIdent ) ;

     // Save markers to header
     AppendInt( Header, 'MKN=', FNumMarkers ) ;
     for i := 0 to FNumMarkers-1 do begin
         AppendFloat( Header, format('MKTIM%d=',[i]),FMarkerTime[i]) ;
         AppendString( Header, format('MKTXT%d=',[i]), FMarkerText[i] ) ;
         end ;

     // Write header at start of data file
     if IDRFileWrite( @Header, 0, FNumIDRHeaderBytes ) <> FNumIDRHeaderBytes then
        ShowMessage( 'WinFluor data file header write failed ' ) ;

     if HeaderFull then ShowMessage('WinFluor data file header capacity exceeded') ;

//          n := 0 ;
//     for i:= 1 to High(Header) do if Header[i] <> #0 then Inc(n) ;
//     OutputdebugString(pchar(format('Header size=%d',[n])));
//     ShowMessage(format('Header size=%d',[n]));


     end ;


function TIDRFile.LoadFrame(
         FrameNum : Integer ;             // Frame # to load
         FrameBuf : Pointer ) : Boolean ; // Frame buffer pointer
// -------------------------------
// Load image frame from data file
// -------------------------------
var
    FileOffset : Int64 ;
begin

     Result := False ;
     if (FrameNum > 0) and (FrameNum <= FNumFrames) and
        (FIDRFileHandle <> INVALID_HANDLE_VALUE) then begin

        FileOffset := Int64(FrameNum-1)*Int64(FNumBytesPerFrame) + Int64(FNumIDRHeaderBytes) ;
        if IDRFileRead( FrameBuf, FileOffset, FNumBytesPerFrame )
           = FNumBytesPerFrame then Result := True ;

        end ;

     end ;


function TIDRFile.LoadFrame32(
         FrameNum : Integer ;             // Frame # to load
         FrameBuf32 : PIntArray ) : Boolean ; // Frame buffer pointer
// ---------------------------------------------------
// Load image from data file and copy to 32 bit buffer
// ---------------------------------------------------
var
    i : Integer ;
begin
        for i := 0 to FNumPixelsPerFrame-1 do
            PWordArray(PInternalBuf)^[i] := 0 ;

     Result := True ;
     // Load raw frame from file
     Result := LoadFrame( FrameNum, PInternalBuf ) ;
     if not Result then Exit ;

     if FNumBytesPerPixel > 2 then begin
        // 32 bit images
        for i := 0 to FNumPixelsPerFrame-1 do
            FrameBuf32^[i] := PIntArray(PInternalBuf)^[i] ;
        end
     else if FNumBytesPerPixel > 1 then begin
        // 16 bit images
        for i := 0 to FNumPixelsPerFrame-1 do
            FrameBuf32^[i] := PWordArray(PInternalBuf)^[i] ;
        end
     else begin
        // 8 bit images
        for i := 0 to FNumPixelsPerFrame-1 do
            FrameBuf32^[i] := PByteArray(PInternalBuf)^[i] ;
        end ;

     end ;



function TIDRFile.SaveFrame(
         FrameNum : Integer ;              // Frame # to be written
         FrameBuf : Pointer ) : Boolean ;  // Pointer to image buffer
// -------------------------------
// Save image frame to data file
// -------------------------------
var
    FileOffset : Int64 ;
begin

     Result := False ;
     if (FrameNum <= 0) or (FIDRFileHandle = INVALID_HANDLE_VALUE) then Exit ;

     FileOffset := Int64(FrameNum-1)*Int64(FNumBytesPerFrame) + FNumIDRHeaderBytes ;
     if IDRFileWrite(FrameBuf,FileOffset,FNumBytesPerFrame) = FNumBytesPerFrame then begin
        FNumFrames := Max(FNumFrames,FrameNum) ;
        Result := True ;
        end ;

     end ;


function TIDRFile.SaveFrame32(
         FrameNum : Integer ;             // Frame # to save
         FrameBuf32 : PIntArray ) : Boolean ; // Frame buffer pointer
// ---------------------------------------------------
// Save image from 32 bit buffer to data file
// ---------------------------------------------------
var
    i : Integer ;
begin

     // Create 8/16 image frame

     if FNumBytesPerPixel > 2 then begin
        // 32 bit images
        for i := 0 to FNumPixelsPerFrame-1 do
            PIntArray(PInternalBuf)^[i] := FrameBuf32^[i] ;
           end
     else if FNumBytesPerPixel > 1 then begin
        // 16 bit images
        for i := 0 to FNumPixelsPerFrame-1 do
            PWordArray(PInternalBuf)^[i] := FrameBuf32^[i] ;
           end
     else begin
        // 8 bit images
        for i := 0 to FNumPixelsPerFrame-1 do
            PByteArray(PInternalBuf)^[i] := FrameBuf32^[i] ;
        end ;

     // Save raw frame to file
     Result := SaveFrame( FrameNum, PInternalBuf ) ;

     end ;


function TIDRFile.AsyncSaveFrames(
         FrameNum : Integer ;              // Starting Frame # to be written
         NumFrames : Integer ;             // Number of frames to be written
         FrameBuf : Pointer ) : Boolean ;  // Pointer to image buffer
// ------------------------------------------------------
// Save image frames to data file (asynchronous transfer)
// ------------------------------------------------------
var
    FileOffset : Int64 ;
    NumBytesToWrite : Integer ;
begin

     Result := False ;
     if (FrameNum <= 0) or (FIDRFileHandle = INVALID_HANDLE_VALUE) then Exit ;

     NumBytesToWrite := FNumBytesPerFrame*NumFrames ;

     FileOffset := Int64(FrameNum-1)*Int64(FNumBytesPerFrame) + FNumIDRHeaderBytes ;
     IDRAsyncFileWrite(FrameBuf,FileOffset,NumBytesToWrite) ;

     FNumFrames := FNumFrames + NumFrames ;

     Result := True ;

     end ;

procedure TIDRFile.UpdateNumFrames ;
// -----------------------------------
// Update the number of frames in file
// -----------------------------------
begin
     //FNumFrames := GetNumFramesInFile ;
     end ;


function TIDRFile.GetNumFramesInFile : Integer ;
// ---------------------------------
// Get number of frames in data file
// ---------------------------------
var
    NumFrames : Int64 ;
begin
     if FIDRFileHandle <> INVALID_HANDLE_VALUE then begin
        if FNumBytesPerFrame > 0 then begin
           NumFrames := (IDRGetFileSize - Int64(FNumIDRHeaderBytes))
                        div Int64(FNumBytesPerFrame) ;
           Result := Max( Integer(NumFrames), 0 ) ;
           end
        else Result := 0 ;
        end
     else Result := 0 ;
     end ;


function  TIDRFile.LoadADC(
          StartScan : Integer ;               // First A/D channel scan to be loaded
          NumScans : Integer ;                // No. of A/D channel scans to load
          var ADCBuf : Array of SmallInt     // A/D sample buffer to be filled with samples
          ) : Integer ;                       // Returns no. of scans loaded
// -----------------------------------
// Load A/D samples from EDR data file
// -----------------------------------
var
     FileOffset : Int64 ;
     NumBytes,NumBytesRead : Integer ;
     FirstAvailableScan,NumScansAvailable,iShift : Integer ;
     i,jFrom,jTo,ch : Integer ;
     TempBuf : pSmallIntArray ;
begin

     Result := 0 ;
     if FEDRFileHandle < 0 then Exit ;
     if FADCNumChannels <= 0 then Exit ;

     // Read scans available in file
     FirstAvailableScan :=  Min(Max(StartScan,0),FADCNumScansInFile-1) ;
     NumScansAvailable := Min(StartScan + NumScans, FADCNumScansInFile) - FirstAvailableScan ;
     FileOffset := Int64((FirstAvailableScan*FADCNumChannels*2) + FNumEDRHeaderBytes) ;
     NumBytes :=  NumScansAvailable*FADCNumChannels*2 ;
     FileSeek( FEDRFileHandle,FileOffset,0) ;
     NumBytesRead := FileRead( FEDRFileHandle, ADCBuf,NumBytes) ;

     // Pad ends of buffer if insufficient scans available
     if (StartScan <> FirstAvailableScan) or
        (NumScansAvailable <> NumScans) then begin
        iShift := FirstAvailableScan - StartScan ;
        // Create and copy data to temp buf.
        GetMem( TempBuf, NumScans*FADCNumChannels*2 ) ;
        for i := 0 to NumScans*FADCNumChannels-1 do TempBuf[i] := ADCBuf[i] ;
        // Shift data
        for i := NumScans-1 downto 0 do begin
            jFrom := Min(Max(i-iShift,0),NumScansAvailable-1)*FADCNumChannels ;
            jTo := i*FADCNumChannels ;
            for ch := 0 to FADCNumChannels-1 do ADCBuf[jTo+ch] :=  TempBuf[jFrom+ch] ;
            end ;
        FreeMem(TempBuf) ;
        end ;

     Result := NumScans ;

     end ;


function  TIDRFile.SaveADC(
          StartScan : Integer ;               // First A/D channel scan to be saved
          NumScans : Integer ;                // No. of A/D channel scans to save
          var ADCBuf : Array of SmallInt     // A/D sample buffer to saved to file
          ) : Integer ;                       // Returns no. of scans saved
// -----------------------------------
// Save A/D samples to EDR data file
// -----------------------------------
var
     FileOffset : Int64 ;
     NumBytes,NumBytesRead : Integer ;
begin

     Result := 0 ;
     if FEDRFileHandle < 0 then Exit ;
     if FADCNumChannels <= 0 then Exit ;

     FileOffset := Int64((StartScan*FADCNumChannels*2) + FNumEDRHeaderBytes) ;
     NumBytes :=  NumScans*FADCNumChannels*2 ;

     FileSeek( FEDRFileHandle,FileOffset,0) ;
     NumBytesRead := FileWrite( FEDRFileHandle, ADCBuf,NumBytes) ;
     Result := NumBytesRead div (FADCNumChannels*2) ;

     end ;




procedure TIDRFile.SaveEDRHeader ;
{ ---------------------------------------
  Save file header data to EDR data file
  ---------------------------------------}
var
   Header : array[1..cNumEDRHeaderBytes] of ANSIChar ;
   i : Integer ;
   ch : Integer ;
begin

     if FEDRFileHandle < 0 then Exit ;

     // Ensure files are write enabled
     if not FWriteEnabled then SetWriteEnabled(True) ;

     { Initialise empty header buffer with zero bytes }
     for i := 1 to sizeof(Header) do Header[i] := chr(0) ;

     AppendFloat( Header, 'VER=',1.0 );

     // 13/2/02 Added to distinguish between 12 and 16 bit data files
     AppendInt( Header, 'ADCMAX=', FADCMaxValue ) ;

     { Number of bytes in file header }
     AppendInt( Header, 'NBH=', FNumEDRHeaderBytes ) ;

     AppendInt( Header, 'NC=', FADCNumChannels ) ;

     // A/D converter input voltage range
     AppendFloat( Header, 'AD=', FADCVoltageRange ) ;

     if FEDRFileHandle > 0 then
        FADCNumSamplesInFile := (FileSeek(EDRFileHandle,0,2)
                                 + 1 - FNumEDRHeaderBytes) div 2 ;

     if FADCNumChannels > 0 then begin
        FADCNumScansInFile := FADCNumSamplesInFile div FADCNumChannels ;
        end
     else FADCNumScansInFile := 1 ;

     AppendInt( Header, 'NP=', FADCNumSamplesInFile ) ;

     AppendFloat( Header, 'DT=',FADCScanInterval );

     for ch := 0 to FADCNumChannels-1 do begin
         AppendInt( Header, format('YO%d=',[ch]), Channels[ch].ChannelOffset) ;
         AppendString( Header, format('YU%d=',[ch]), Channels[ch].ADCUnits ) ;
         AppendString( Header, format('YN%d=',[ch]), Channels[ch].ADCName ) ;
         AppendFloat(Header,format('YCF%d=',[ch]),Channels[ch].ADCCalibrationFactor) ;
         AppendFloat( Header, format('YAG%d=',[ch]), Channels[ch].ADCAmplifierGain) ;
         AppendInt( Header, format('YZ%d=',[ch]), Channels[ch].ADCZero) ;
         AppendInt( Header, format('YR%d=',[ch]), Channels[ch].ADCZeroAt) ;
         end ;

     { Experiment identification line }
     //AppendString( Header, 'ID=', fHDR.IdentLine ) ;

     { Save the original file backed up flag }
     AppendLogical( Header, 'BAK=', False ) ;

     FileSeek( EDRFileHandle, 0, 0 ) ;
     if FileWrite(EDRFileHandle,Header,Sizeof(Header)) <> Sizeof(Header) then
        ShowMessage( 'EDR File Header Write Failed ' ) ;

     end ;


procedure TIDRFile.GetEDRHeader ;
// ------------------------
// Load EDR data file header
// ------------------------
var
   Header : array[1..cNumEDRHeaderBytes] of ANSIChar ;
   i,ch,NumBytesInHeader : Integer ;
begin

     if FEDRFileHandle < 0 then Exit ;

     FileSeek( FEDRFileHandle, 0, 0 ) ;
     if FileRead( FEDRFileHandle, Header, Sizeof(Header) ) < Sizeof(Header) then Exit ;

     // 13/2/02 Added to distinguish between 12 and 16 bit data files
     ReadInt( Header, 'ADCMAX=', FADCMaxValue ) ;

     FNumEDRHeaderBytes := cNumEDRHeaderBytes ;
     ReadInt( Header, 'NBH=', FNumEDRHeaderBytes ) ;
     FNumEDRHeaderBytes := cNumEDRHeaderBytes  ;

     ReadInt( Header, 'NC=', FADCNumChannels ) ;
     if FADCNumChannels <= 0 then Exit ;

     // A/D converter input voltage range
     ReadFloat( Header, 'AD=', FADCVoltageRange ) ;

     ReadInt( Header, 'NP=', FADCNumSamplesInFile ) ;
     FADCNumScansInFile := FADCNumSamplesInFile div Max(FADCNumChannels,1) ;

     ReadFloat( Header, 'DT=',FADCScanInterval );

     for ch := 0 to FADCNumChannels-1 do begin
         ReadInt( Header, format('YO%d=',[ch]), Channels[ch].ChannelOffset) ;
         ReadString( Header, format('YU%d=',[ch]), Channels[ch].ADCUnits ) ;
         ReadString( Header, format('YN%d=',[ch]), Channels[ch].ADCName ) ;
         ReadFloat(Header,format('YCF%d=',[ch]),Channels[ch].ADCCalibrationFactor) ;
         ReadFloat( Header, format('YAG%d=',[ch]), Channels[ch].ADCAmplifierGain) ;
         ReadInt( Header, format('YZ%d=',[ch]), Channels[ch].ADCZero) ;
         ReadInt( Header, format('YR%d=',[ch]), Channels[ch].ADCZeroAt) ;
         end ;

     // Update A/D channel scaling factors
     UpdateChannelScalingFactors( Channels,
                                  FADCNumChannels,
                                  FADCVoltageRange,
                                  FADCMaxValue )  ;

     end ;


function TIDRFile.GetNumScansInEDRFile : Integer ;
// ------------------------------------
// Get number of A/D scans in data file
// ------------------------------------
var
     NumSamplesInFile : Integer ;
begin

     if EDRFileHandle > 0 then begin

        NumSamplesInFile := (FileSeek(EDRFileHandle,0,2)
                             + 1 - FNumEDRHeaderBytes) div 2 ;

        Result := NumSamplesInFile div Max(FADCNumChannels,1) ;
        end
     else Result := 0 ;
     end ;


procedure TIDRFile.UpdateChannelScalingFactors(
          var Channels : Array of TChannel ;
          NumChannels : Integer ;
          ADCVoltageRange : Single ;
          ADCMaxValue : Integer
          ) ;
// ------------------------------
// Update channel scaling factors
// ------------------------------
var
   ch : Integer ;
begin

     for ch := 0 to NumChannels-1 do begin

         // Ensure that calibration factor is non-zero
         if Channels[ch].ADCCalibrationFactor = 0.0 then
            Channels[ch].ADCCalibrationFactor := 0.001 ;

         // Ensure that amplifier gain is non-zero
         if Channels[ch].ADCAmplifierGain = 0.0 then
            Channels[ch].ADCAmplifierGain := 1.0 ;

         // Calculate bits->units scaling factor
         Channels[ch].ADCScale := ADCVoltageRange /
                                (Channels[ch].ADCCalibrationFactor*
                                 Channels[ch].ADCAmplifierGain
                                 *(ADCMaxValue+1) ) ;
         end ;
     end ;


function TIDRFile.GetFrameType( i : Integer ) : String ;
{ ---------------------
  Get frame type label
  ---------------------}
begin
     if SpectralDataFile then begin
         Result :=format('%.0f(%.0f) nm ',
                  [ FSpectrumStartWavelength + (i*FSpectrumStepSize),
                    FSpectrumBandwidth]) ;
         end
     else begin
         Result := FFrameTypes[IntLimitTo(i,0,MaxFrameType)] ;
         end ;

     end ;


function TIDRFile.GetFrameTypeDivideFactor( i : Integer ) : Integer ;
{ ----------------------------
  Get frame type divide factor
  ----------------------------}
begin
     if SpectralDataFile then begin
         Result := 1 ;
         end
     else begin
         Result := FFrameTypeDivideFactor[IntLimitTo(i,0,MaxFrameType)] ;
         end ;

     end ;


function TIDRFile.GetEquation( i : Integer ) : TBindingEquation ;
{ ---------------------------
  Get binding equation
  ---------------------------}
begin
     Result := FEquations[IntLimitTo(i,0,MaxEqn)] ;
     end ;


function TIDRFile.GetMarkerTime( i : Integer ) : Single ;
{ ----------------------
  Get event marker time
  ----------------------}
begin
     if (i >= 0) and (i < FNumMarkers) then Result := FMarkerTime[i]
                                       else Result := 0.0 ;
     end ;


procedure TIDRFile.SetMarkerTime(
          i : Integer ;
          Value : Single )  ;
{ ----------------------
  Set event marker time
  ----------------------}
begin
     if (i >= 0) and (i < FNumMarkers) then FMarkerTime[i] := Value ;
     end ;


function TIDRFile.GetMarkerText( i : Integer ) : String ;
{ ----------------------
  Get event marker text
  ----------------------}
begin
     if (i >= 0) and (i < FNumMarkers) then Result := FMarkerText[i]
                                       else Result := '' ;
     end ;


procedure TIDRFile.SetMarkerText(
         i : Integer ;
         Value : String
         ) ;
{ ----------------------
  Get event marker text
  ----------------------}
begin
     if (i >= 0) and (i < FNumMarkers) then FMarkerText[i] := Value ;
     end ;


function TIDRFile.GetADCChannel( i : Integer ) : TChannel ;
// -----------------------------------------
// Get analogue input channel definition
// -----------------------------------------
begin
     Result := Channels[IntLimitTo(i,0,MaxChannel)] ;
     end ;


function TIDRFile.GetROI( i : Integer ) : TROI ;
// ----------------------
// Get region of interest
// ----------------------
begin
     Result := FROIs[IntLimitTo(i,0,FMaxROI)] ;
     end ;


procedure TIDRFile.SetADCChannel( i : Integer ;
                                  Value : TChannel ) ;
// -----------------------------------------
// Set analogue input channel definition
// -----------------------------------------
begin
     Channels[IntLimitTo(i,0,MaxChannel)] := Value ;
     // Update A/D channel scaling factors
     UpdateChannelScalingFactors( Channels,
                                  FADCNumChannels,
                                  FADCVoltageRange,
                                  FADCMaxValue )  ;
     end ;


procedure TIDRFile.SetROI( i : Integer ;
                           Value : TROI ) ;
// ----------------------
// Set region of interest
// ----------------------
begin
     FROIs[IntLimitTo(i,0,FMaxROI)] := Value ;
     end ;


procedure TIDRFile.SetPixelDepth( Value : Integer ) ;
// ---------------
// Set pixel depth
// ---------------
begin
     FPixelDepth := IntLimitTo( Value, 1, 32 ) ;
     ComputeFrameSize ;
     end ;


procedure TIDRFile.SetFrameWidth( Value : Integer ) ;
// ---------------
// Set frame width
// ---------------
begin
     FFrameWidth := IntLimitTo( Value, 0, $10000 ) ;
     ComputeFrameSize ;
     end ;


procedure TIDRFile.SetFrameHeight( Value : Integer ) ;
// ---------------
// Set frame height
// ---------------
begin
     FFrameHeight := IntLimitTo( Value, 0, $10000 ) ;
     ComputeFrameSize ;
     end ;


procedure TIDRFile.SetADCVoltageRange( Value : Single ) ;
// ---------------------------
// Set A/D input voltage range
// ---------------------------
begin
     FADCVoltageRange := Value ;
     // Update A/D channel scaling factors
     UpdateChannelScalingFactors( Channels,
                                  FADCNumChannels,
                                  FADCVoltageRange,
                                  FADCMaxValue )  ;
     end ;


procedure TIDRFile.SetADCNumChannels( Value : Integer ) ;
// ---------------------------
// Set no. of A/D input channels
// ---------------------------
var
     ch : Integer ;
begin
     FADCNumChannels := IntLimitTo( Value, 0, MaxChannel+1)  ;

     // Temporary to ensure correct channel sequence
     for ch := 0 to FADCNumChannels-1 do Channels[ch].ChannelOffset := ch ;

     // Update A/D channel scaling factors
     UpdateChannelScalingFactors( Channels,
                                  FADCNumChannels,
                                  FADCVoltageRange,
                                  FADCMaxValue )  ;
     end ;


function TIDRFile.AddMarker(
         Time : Single ;         // Event time (s)
         Text : String           // Marker text
         ) : Boolean ;           // Returns TRUE if marker added to list
// ------------------------------
// Add a new event marker to list
// ------------------------------
begin
     if (FNumMarkers-1) < MaxMarker then begin
        FMarkerTime[FNumMarkers] := Time ;
        FMarkerText[FNumMarkers] := Text ;
        Inc(FNumMarkers) ;
        Result := True ;
        end
     else Result := False ;
     end ;


procedure TIDRFile.ComputeFrameSize ;
// ------------------------------------------
// Compute frame size when properties changed
// ------------------------------------------
var
     i : Integer ;
begin

     if FPixelDepth > 16 then FNumBytesPerPixel := 4
     else if FPixelDepth > 8 then FNumBytesPerPixel := 2
                             else FNumBytesPerPixel := 1 ;

     FNumPixelsPerFrame := FFrameWidth*FFrameHeight ;
     FNumBytesPerFrame := FNumPixelsPerFrame*FNumBytesPerPixel ;

     FGreyMax := 1 ;
     for i := 1 to FPixelDepth do FGreyMax := FGreyMax*2 ;
     FGreyMax := FGreyMax - 1 ;

     end ;


procedure TIDRFile.SetFrameType( i : Integer ;
                                 Value : String ) ;
{ ---------------------
  Set frame type label
  ---------------------}
begin
     FFrameTypes[IntLimitTo(i,0,MaxFrameType)] := Value ;
     end ;


procedure TIDRFile.SetFrameTypeDivideFactor( i : Integer ;
                                             Value : Integer ) ;
{ ----------------------------
  Set frame type divide factor
  ----------------------------}
begin

     FFrameTypeDivideFactor[IntLimitTo(i,0,MaxFrameType)] := Value ;

     // Create frame type cycle
     CreateFrameTypeCycle( FFrameTypeCycle, FFrameTypeCycleLength ) ;

     end ;


procedure TIDRFile.SetWriteEnabled( Value : Boolean ) ;
// ---------------------------
// Set file write enabled mode
// ---------------------------
begin

    if FIDRFileHandle = INVALID_HANDLE_VALUE then Exit ;

    IDRFileClose ;
    if FEDRFileHandle > 0 then FileClose( FEDRFileHandle ) ;

    FWriteEnabled := Value ;
    if FWriteEnabled then FileMode := fmOpenReadWrite
                     else FileMode := fmOpenRead ;

    // Open files in selected mode
    IDRFileOpen( FFileName, FileMode ) ;

    FEDRFileHandle := FileOpen( ChangeFileExt( FFileName, '.EDR' ), FileMode ) ;

    end ;


procedure TIDRFile.SetEquation( i : Integer ;
                                Value : TBindingEquation ) ;
{ ---------------------------
  Set binding equation
  ---------------------------}
begin
     FEquations[IntLimitTo(i,0,MaxEqn)] := Value ;
     end ;


procedure TIDRFile.SetAsyncWriteBufSize( Value : Integer ) ;
// -----------------------------------------------
// Set size of internal asynchronous write buffer
// -----------------------------------------------
begin
    if AsyncWriteBuf <> Nil then FreeMem(AsyncWriteBuf) ;
    FAsyncWriteBufSize := Value ;
    GetMem( AsyncWriteBuf, FAsyncWriteBufSize ) ;
    end ;


function TIDRFile.GetFileHeader : string ;
// ---------------
// Get file header
// ---------------
var
    s : string ;
    i : Integer ;
begin
    s := '' ;
    i := 1 ;
    while (Header[i] <> #0) and (i <= High(Header)) do begin
       s := s + Header[i] ;
       Inc(i) ;
       end ;
    Result := s ;
    end ;


function TIDRFile.GetMaxROIInUse : Integer ;
// -------------------------
// Return highest ROI in use
// -------------------------
var
    i : Integer ;
begin
    Result := 0 ;
    for i := 0 to cMaxROIs do begin
        if FROIs[i].InUse then Result := i ;
        end ;
        end ;

procedure TIDRFile.AppendFloat(
          var Dest : Array of ANSIChar;
          Keyword : string ;
          Value : Extended ) ;
{ --------------------------------------------------------
  Append a floating point parameter line
  'Keyword' = 'Value' on to end of the header text array
  --------------------------------------------------------}
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, format( '%.6g',[Value] ) ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;


procedure TIDRFile.ReadFloat(
          const Source : Array of ANSIChar;
          Keyword : string ;
          var Value : Single ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := ExtractFloat( Parameter, 1. ) ;
     end ;


procedure TIDRFile.AppendInt(
          var Dest : Array of ANSIChar;
          Keyword : string ;
          Value : LongInt ) ;
{ -------------------------------------------------------
  Append a long integer point parameter line
  'Keyword' = 'Value' on to end of the header text array
  ------------------------------------------------------ }
begin
     CopyStringToArray( Dest, Keyword ) ;
     CopyStringToArray( Dest, InttoStr( Value ) ) ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;


procedure TIDRFile.ReadInt(
          const Source : Array of ANSIChar;
          Keyword : string ;
          var Value : LongInt ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := ExtractInt( Parameter ) ;
     end ;

{ Append a text string parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure TIDRFile.AppendString(
          var Dest : Array of ANSIChar;
          Keyword, Value : string ) ;
begin
CopyStringToArray( Dest, Keyword ) ;
CopyStringToArray( Dest, Value ) ;
CopyStringToArray( Dest, chr(13) + chr(10) ) ;
end ;

procedure TIDRFile.ReadString(
          const Source : Array of ANSIChar;
          Keyword : string ;
          var Value : string ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if Parameter <> '' then Value := Parameter  ;
     end ;

{ Append a boolean True/False parameter line
  'Keyword' = 'Value' on to end of the header text array}

procedure TIDRFile.AppendLogical(
          var Dest : Array of ANSIChar;
          Keyword : string ;
          Value : Boolean ) ;
begin
     CopyStringToArray( Dest, Keyword ) ;
     if Value = True then CopyStringToArray( Dest, 'T' )
                     else CopyStringToArray( Dest, 'F' )  ;
     CopyStringToArray( Dest, chr(13) + chr(10) ) ;
     end ;

procedure TIDRFile.ReadLogical(
          const Source : Array of ANSIChar;
          Keyword : string ;
          var Value : Boolean ) ;
var
   Parameter : string ;
begin
     FindParameter( Source, Keyword, Parameter ) ;
     if pos('T',Parameter) > 0 then Value := True
                               else Value := False ;
     end ;


procedure TIDRFile.CopyStringToArray(
          var Dest : array of ANSIChar ;
          Source : string ) ;
var
   i,j : Integer ;
begin

     { Find end of character array }
     j := 0 ;
     while (Dest[j] <> chr(0)) and (j < High(Dest) ) do j := j + 1 ;

     if (j + length(Source)) < High(Dest) then
     begin
          for i := 1 to length(Source) do
          begin
               Dest[j] := Source[i] ;
               j := j + 1 ;
               end ;
          end
     else HeaderFull := True ;

     end ;

procedure TIDRFile.CopyArrayToString(
          var Dest : string ;
          var Source : array of ANSIChar ) ;
var
   i : Integer ;
begin
     Dest := '' ;
     for i := 0 to High(Source) do begin
         Dest := Dest + Source[i] ;
         end ;
     end ;


procedure TIDRFile.FindParameter(
          const Source : array of ANSIChar ;
          Keyword : string ;
          var Parameter : string ) ;
var
s,k : integer ;
Found : boolean ;
begin

     { Search for the string 'keyword' within the
       array 'Source' }

     s := 0 ;
     k := 1 ;
     Found := False ;
     while (not Found) and (s < High(Source)) do
     begin
          if Source[s] = Keyword[k] then
          begin
               k := k + 1 ;
               if k > length(Keyword) then Found := True
               end
               else k := 1;
         s := s + 1;
         end ;


    { Copy parameter value into string 'Parameter'
      to be returned to calling routine }

    Parameter := '' ;
    if Found then
    begin
        while (Source[s] <> chr(13)) and (s < High(Source)) do
        begin
             Parameter := Parameter + Source[s] ;
             s := s + 1
             end ;
        end ;
    end ;


function TIDRFile.IntLimitTo(
         Value : Integer ;       { Value to be tested (IN) }
         LowerLimit : Integer ;  { Lower limit (IN) }
         UpperLimit : Integer    { Upper limit (IN) }
         ) : Integer ;           { Return limited Value }
{ -------------------------------------------------------------------
  Make sure Value is kept within the limits LowerLimit and UpperLimit
  -------------------------------------------------------------------}
begin
     if Value < LowerLimit then Value := LowerLimit ;
     if Value > UpperLimit then Value := UpperLimit ;
     Result := Value ;
     end ;


function TIDRFile.ExtractFloat (
         CBuf : string ;     { ASCII text to be processed }
         Default : Single    { Default value if text is not valid }
         ) : single ;
{ -------------------------------------------------------------------
  Extract a floating point number from a string which
  may contain additional non-numeric text
  28/10/99 ... Now handles both comma and period as decimal separator
  -------------------------------------------------------------------}

var
   CNum : string ;
   i : integer ;
   Done,NumberFound : Boolean ;
begin
     { Extract number from othr text which may be around it }
     CNum := '' ;
     Done := False ;
     NumberFound := False ;
     i := 1 ;
     repeat
         if CBuf[i] in ['0'..'9', 'E', 'e', '+', '-', '.', ',' ] then begin
            CNum := CNum + CBuf[i] ;
            NumberFound := True ;
            end
         else if NumberFound then Done := True ;
         Inc(i) ;
         if i > Length(CBuf) then Done := True ;
         until Done ;

     { Correct for use of comma/period as decimal separator }
     if (DECIMALSEPARATOR = '.') and (Pos(',',CNum) <> 0) then
        CNum[Pos(',',CNum)] := DECIMALSEPARATOR ;
     if (DECIMALSEPARATOR = ',') and (Pos('.',CNum) <> 0) then
        CNum[Pos('.',CNum)] := DECIMALSEPARATOR ;

     { Convert number from ASCII to real }
     try
        if Length(CNum)>0 then ExtractFloat := StrToFloat( CNum )
                          else ExtractFloat := Default ;
     except
        on E : EConvertError do ExtractFloat := Default ;
        end ;
     end ;


function TIDRFile.ExtractInt ( CBuf : string ) : longint ;
{ ---------------------------------------------------
  Extract a 32 bit integer number from a string which
  may contain additional non-numeric text
  ---------------------------------------------------}

Type
    TState = (RemoveLeadingWhiteSpace, ReadNumber) ;
var CNum : string ;
    i : integer ;
    Quit : Boolean ;
    State : TState ;

begin
     CNum := '' ;
     i := 1;
     Quit := False ;
     State := RemoveLeadingWhiteSpace ;
     while not Quit do begin

           case State of

                { Ignore all non-numeric characters before number }
                RemoveLeadingWhiteSpace : begin
                   if CBuf[i] in ['0'..'9','+','-'] then State := ReadNumber
                                                    else i := i + 1 ;
                   end ;

                { Copy number into string CNum }
                ReadNumber : begin
                    {End copying when a non-numeric character
                    or the end of the string is encountered }
                    if CBuf[i] in ['0'..'9','E','e','+','-','.'] then begin
                       CNum := CNum + CBuf[i] ;
                       i := i + 1 ;
                       end
                    else Quit := True ;
                    end ;
                else end ;

           if i > Length(CBuf) then Quit := True ;
           end ;
     try


        ExtractInt := StrToInt( CNum ) ;
     except
        ExtractInt := 1 ;
        end ;
     end ;

function TIDRFile.DiskSpaceAvailable(
         NumFrames : Integer
         ) : Boolean ;
// ------------------------------------------------
// Determine if there is enough disk space for file
// ------------------------------------------------
const
     DriverLetterList = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ;
var
    DriveLetter : String ;
    SpaceRequired : Int64 ;
    FreeSpace : Int64 ;
    DiskIndex : Byte ;

begin

     // Get drive
     DriveLetter := UpperCase(ExtractFileDrive(FFileName)) ;
     DiskIndex := Pos( DriveLetter, DriverLetterList ) ;
     if DiskIndex > 0 then FreeSpace := DiskFree(DiskIndex) ;

     SpaceRequired := Int64(FFrameWidth) *
                      Int64(FFrameHeight) *
                      Int64(FNumBytesPerPixel) ;
     SpaceRequired := SpaceRequired*Int64(NumFrames) ;
     SpaceRequired := SpaceRequired + Int64(1000000) ;

     if FreeSpace >  SpaceRequired then Result := True
                                   else Result := False ;

     //if Uppercase(DriveLetter[1]) = 'G' then Result := True ;

     end ;


function TIDRFile.IDRFileCreate(
         FileName : String
         ) : Boolean ;
// ---------------------------------------
// Create file for asynchronous read/write
// ---------------------------------------
begin

    // Create file
    FIDRFileHandle :=  CreateFile( PChar(FileName),
                                   GENERIC_WRITE	or GENERIC_READ,
                                   FILE_SHARE_READ,
                                   Nil,
                                   CREATE_ALWAYS,
                                   FILE_ATTRIBUTE_NORMAL or
                                   FILE_FLAG_OVERLAPPED or
                                   FILE_FLAG_WRITE_THROUGH,
                                   0 ) ;

    FAsyncBufferOverflow := False ;
    AsyncWriteInProgess := False ;

    // Create frame type cycle
    CreateFrameTypeCycle( FFrameTypeCycle, FFrameTypeCycleLength ) ;

    end ;


function TIDRFile.IDRFileOpen(
         FileName : String ;
         FileMode : Integer
         ) : Boolean ;
// ---------------------------------------
// Create file for asynchronous read/write
// ---------------------------------------
var
    AccessMode : DWord ;
begin

    // Set file access mode
    if FileMode = fmOpenReadWrite then AccessMode := GENERIC_WRITE	or GENERIC_READ
                                  else AccessMode := GENERIC_READ ;

    // Create file
    FIDRFileHandle :=  CreateFile( PChar(FileName),
                                   AccessMode,
                                   FILE_SHARE_READ,
                                   Nil,
                                   OPEN_EXISTING,
                                   FILE_ATTRIBUTE_NORMAL or
                                   FILE_FLAG_OVERLAPPED or
                                   FILE_FLAG_WRITE_THROUGH,
                                   0 ) ;

    FAsyncBufferOverflow := False ;
    AsyncWriteInProgess := False ;

    end ;


function TIDRFile.IDRFileWrite(
         pDataBuf : Pointer ;
         FileOffset : Int64 ;
         NumBytesToWrite : Integer
         ) : Integer ;
// ----------------------------
// Write to file (synchronous)
// ----------------------------
var
     NumBytesWritten : Cardinal ;
     i : Integer ;
     Overlap : _Overlapped ;
begin

    // Wait for any existing asynchronous writes to complete
    if AsyncWriteInProgess then begin
       GetOverlappedResult( FIDRFileHandle,
                            AsyncWriteOverlap,
                            NumBytesWritten,
                            True ) ;
       end ;

    // Set file offset point in overlap structure
    Overlap.Offset := FileOffset and $FFFFFFFF ;
    Overlap.OffsetHigh := (FileOffset shr 32) and $FFFFFFFF ;
    Overlap.hEvent := 0 ;

    // Request write to file
    WriteFile( FIDRFileHandle,
               PByteArray(pDataBuf)^,
               NumBytesToWrite,
               NumBytesWritten,
               @Overlap
               ) ;

    // Wait for write to complete
    GetOverlappedResult( FIDRFileHandle,
                         Overlap,
                         NumBytesWritten,
                         True ) ;

    Result := NumBytesWritten ;
    FAsyncBufferOverflow := False ;
    AsyncWriteInProgess := False ;

    end ;


function TIDRFile.IDRAsyncFileWrite(
         pDataBuf : Pointer ;
         FileOffset : Int64 ;
         NumBytesToWrite : Integer
         ) : Integer ;
// ----------------------------
// Write to file (asynchronous)
// ----------------------------
var
     NumBytesWritten : Cardinal ;
     i,t0,t1,t2 : Integer ;
     OK : Boolean ;
     Err : Integer ;
begin

    // Check for buffer overflow
    FAsyncBufferOverflow := False ;
    if AsyncWriteInProgess then begin
       GetOverlappedResult( FIDRFileHandle,
                            AsyncWriteOverlap,
                            NumBytesWritten,
                            False ) ;
       if NumBytesWritten <> AsyncNumBytesToWrite then FAsyncBufferOverflow := True ;
       end ;

    // Set file offset point in overlap structure
    AsyncWriteOverlap.Offset := FileOffset and $FFFFFFFF ;
    AsyncWriteOverlap.OffsetHigh := (FileOffset shr 32) and $FFFFFFFF ;
    AsyncWriteOverlap.hEvent := 0 ;

    // Increase size of write buffer if it is too small
    if NumBytesToWrite > FAsyncWriteBufSize then begin
        FAsyncWriteBufSize := NumBytesToWrite ;
        FreeMem( AsyncWriteBuf ) ;
        GetMem( AsyncWriteBuf, FAsyncWriteBufSize ) ;
        end ;

    t0 := timegettime ;
    // Copy into internal buffer
    for i := 0 to NumBytesToWrite-1 do
        PByteArray(AsyncWriteBuf)^[i] := PByteArray(pDataBuf)^[i] ;
    t1 := timegettime ;


    // Write to file
    OK := WriteFile( FIDRFileHandle,
                      PByteArray(AsyncWriteBuf)^,
                      NumBytesToWrite,
                      NumBytesWritten,
                      @AsyncWriteOverlap
                      ) ;
     Err := GetLastError();

    t2 := timegettime ;
       GetOverlappedResult( FIDRFileHandle,
                            AsyncWriteOverlap,
                            NumBytesWritten,
                            False ) ;

   outputdebugString(PChar(format('t %d %d %d',[t1-t0,t2-t1,NumBytesWritten]))) ;

    AsyncWriteInProgess := True ;
    AsyncNumBytesToWrite := NumBytesToWrite ;
    Result := NumBytesWritten ;

    end ;


function TIDRFile.IDRFileRead(
         pDataBuf : Pointer ;
         FileOffset : Int64 ;
         NumBytesToRead : Integer
         ) : Integer ;
// ------------------
// Read from to file
// ------------------
var
     NumBytesRead,NumBytesWritten : Cardinal ;
     i : Integer ;
     Overlap : _Overlapped ;
     Done : Boolean ;
     TTimeOut : Integer ;
begin

    // Wait for any existing asynchronous writes to complete
    if AsyncWriteInProgess then begin
       GetOverlappedResult( FIDRFileHandle,
                            AsyncWriteOverlap,
                            NumBytesWritten,
                            True ) ;
       end ;

    // Set file offset point in overlap structure
    Overlap.Offset := FileOffset and $FFFFFFFF ;
    Overlap.OffsetHigh := (FileOffset shr 32) and $FFFFFFFF ;
    Overlap.hEvent := 0 ;

    // Request read of data from file
    Err := ReadFile( FIDRFileHandle,
              PByteArray(pDataBuf)^,
              NumBytesToRead,
              NumBytesRead,
              @Overlap
              ) ;

    // Wait for read to complete
    Done := False ;
    TTimeOut := TimeGetTime + 500 ;
    While (not Done) and (TimeGetTime < TTimeOut) do begin
       Done := GetOverlappedResult( FIDRFileHandle,
                                    Overlap,
                                    NumBytesRead,
                                    False ) ;
       end ;

    If not Done then NumBytesRead := 0 ;
    Result := NumBytesRead ;

    end ;

function TIDRFile.IDRGetFileSize : Int64 ;
// -----------------------
// Return size of IDR file
// -----------------------
var
    LoWord,HiWord : DWord ;
begin

    LoWord := GetFileSize( FIDRFileHandle, @HiWord ) ;
    Result := LoWord ;
    Result := Result + Int64(HiWord) shl $10000 ;
    end ;


procedure TIDRFile.IDRFileClose ;
// -----------------------------
// Close asynchronous write file
// -----------------------------
var
     NumBytesWritten : Cardinal ;
begin

    if FIDRFileHandle = INVALID_HANDLE_VALUE then Exit ;

    // Wait for any existing asynchronous writes to complete
    if AsyncWriteInProgess then begin
       GetOverlappedResult( FIDRFileHandle,
                            AsyncWriteOverlap,
                            NumBytesWritten,
                            True ) ;
       end ;

     // Close file
     CloseHandle( FIDRFileHandle ) ;

     FIDRFileHandle := INVALID_HANDLE_VALUE ;
     AsyncWriteInProgess := False ;

     end ;


procedure TIDRFile.CreateFramePointerList(
          var FrameList : pIntArray ) ;
// ------------------------------------------------------------------
// Return multi-wavelength/multi-rate group -> frame no. pointer list
// ------------------------------------------------------------------
var
     i,j,iFrame,iFrameType : Integer ;
     FrameTypeCycleLength, LastSlow : Integer ;
     FrameTypeCycle : Array[0..(MaxFrameDivideFactor*(MaxFrameType+1))] of Integer ;
     LatestFrame : Array[0..MaxFrameType+1] of Integer ;
begin

    // Determine last slow frame
    i := 0 ;
    LastSlow := 0 ;
    while (FFrameTypeDivideFactor[i] > 1) and (i < FNumFrameTypes) do begin
          LastSlow := i ;
          Inc(i) ;
          end ;

    // Add one cycle of slow rate wavelengths
    FrameTypeCycleLength := 0 ;
    for i := 0 to LastSlow do begin
        FrameTypeCycle[FrameTypeCycleLength] := i ;
        Inc(FrameTypeCycleLength) ;
        end ;

    // Add DivideFactor cycle of fast frames
    for j := 1 to FFrameTypeDivideFactor[0] do begin
        for i := LastSlow+1 to FNumFrameTypes-1 do begin
            FrameTypeCycle[FrameTypeCycleLength] := i ;
            Inc(FrameTypeCycleLength) ;
            end ;
         end ;

    // Initialise empty frame list
    for i := 0 to FNumFrames*FNumFrameTypes-1 do FrameList[i] := -1 ;

    // Add frame type acquired at each frame
    for iFrame := 0 to FNumFrames-1 do begin
        iFrameType := FrameTypeCycle[iFrame mod FrameTypeCycleLength] ;
        FrameList[iFrame*FNumFrameTypes + iFrameType] := iFrame + 1 ;
        end ;

    // Set first entries
    for iFrameType := 0 to FNumFrameTypes-1 do LatestFrame[iFrameType] := iFrameType + 1 ;

    // Update remaining empty entries with latest available frame
    for iFrameType := 0 to FNumFrameTypes-1 do begin
        for iFrame := 0 to FNumFrames-1 do begin
           j := iFrame*FNumFrameTypes + iFrameType ;
           if FrameList[j] >= 0 then LatestFrame[iFrameType] := FrameList[j]
                                else FrameList[j] := LatestFrame[iFrameType] ;
           end ;
        end ;

    end ;


procedure TIDRFile.CreateFrameTypeCycle(
          var FrameTypeCycle : Array of Integer ;
          var FrameTypeCycleLength : Integer ) ;
// ------------------------------------------------------------------
// Return multi-wavelength/multi-rate frame type cycle
// ------------------------------------------------------------------
var
     i,j,iFrame,iFrameType : Integer ;
     LastSlow : Integer ;
begin

    // Determine last slow frame
    i := 0 ;
    LastSlow := 0 ;
    while (FFrameTypeDivideFactor[i] > 1) and (i < FNumFrameTypes) do begin
          LastSlow := i ;
          Inc(i) ;
          end ;

    // Add one cycle of slow rate wavelengths
    FrameTypeCycleLength := 0 ;
    for i := 0 to LastSlow do begin
        FrameTypeCycle[FrameTypeCycleLength] := i ;
        Inc(FrameTypeCycleLength) ;
        end ;

    // Add DivideFactor cycle of fast frames
    for j := 1 to FFrameTypeDivideFactor[0] do begin
        for i := LastSlow+1 to FNumFrameTypes-1 do begin
            FrameTypeCycle[FrameTypeCycleLength] := i ;
            Inc(FrameTypeCycleLength) ;
            end ;
         end ;

    end ;

function TIDRFile.TypeOfFrame( FrameNum : Integer ) : Integer ;
// ------------------------------
// Return type of frame # FrameNum
// -------------------------------
begin
    Result := FFrameTypeCycle[(FrameNum - 1) mod FFrameTypeCycleLength] ;
    end ;

procedure Register;
begin
  RegisterComponents('Samples', [TIDRFile]);
end;

end.
