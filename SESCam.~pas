unit SESCam;
{ ================================================================================
  SESCam - Camera Acquisition Component (c) J. Dempster, University of Strathclyde
  31/7/01 Started
  17/06/03 ....
  8/7/03 ...... Pixel width and lens magnification properties added
  29/7/03 ..... PixelDepth property added
  1/12/04 ..... Andor cameras added
  8/07/05 ..... Hamamatsu C4880/ITEX board updated
  05/06 ....... QImaging support added
  11/7/6 ...... Hamamatsu DCAM-SDK support added
  24/7/6 ...... Pixel width now scales correctly with bin factor changes
  14-9-06 ANdor_CheckROIBoundaries added to ensure that Andor circular buffer size is always even
  15-10-6 ..... IMAQ for 1394 updated to work with V2.02
  14-2-07 ..... PVCAMSession record added
                Virtual chip PentaMax options removed.
                Special I-PentaMax camera added (has memory buffer limit)
  14-9-07 ..... PCO SensiCam added
  25-1-08 ..... National Instrument IMAQ library support added (for analog video boards)
                IsLSM function added to report whether a camera index is a
                laser scanning microscope
  07-04-08 .... Error which caused misallocation of frame buffer when BINFACTOR
                changed fixed (causing memory alloc errors with Andor 1024x1024 camera)
  05.08.08 .... CameraTemperatureSetPoint property added
                (currently only functions for Andor cameras)
  21/01/09      AdditionalReadoutTime property added. Adds extra readout time during
                triggered exposures which is subtracted from exposure time.
                (Not supported by Andor and IMAQ)
  15/04/09 .... JD CCD imaging area checks no longer take place when image area set
                Now only when .framewidth and .frameheight properties requested
                and when NumFramesInBuffer set.
  16/04/09 .... FNumBytesPerFrameBuffer now always a multiple of Fnumbytesperframe
                Default CCD area limits check added to AllocateFrameBuffer

  19/05/09 .... JD .CameraFanOn and .CameraCoolingOn properties added
  21/05/09 .... JD X8 bin factor added for sensicam cameras
  07/09/09 .... JD .CameraRestartRequired property added. Set = TRUE when a change
                to a property (e.g. .DisableEMCCD) requires the camera to be restarted
                Hamamatsu Image-EM EMCDD can be disabled
  20/01/10 .... JD Error in AllocateBuffer for ITEX_C4880_10,ITEX_C4880_12 which
                caused stack overflow when camera opened fixed
  22/02/10 .... JD National Instrument IMAQDX library support added
  06/09/10 .... JD National Instrument IMAQDX library support now working
  07/09/10 .... JD .CCDClearPreExposure property added (functional only for PVCAM)
  29-10-10 .... JD Andor cameras readout amplifier and A/D converter channel can now be selected
 01.02.11 ....  JD .CCDPostExposureReadout property added. Exposure time in ext. trigger mode can
                now be shortened to account for post-exposure readout in cameras which do not support
                overlapped readout mode. (Current only supported in PVCAM)
 14/07/11 .... JD Adding DT Open Layers support
 30/07/12 .... JD IMAQDX_SetVideoMode removed from SetCameraADC to avoid frame size being set
                  incorrectly on program start for IMAQdx cameras

  ================================================================================ }
{$OPTIMIZATION OFF}
{$R 'sescam.dcr'}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, itex, imaq1394,
  pixelflyunit, SensiCamUnit, AndorUnit, HamDCAMUnit, Math,
  QCAMUnit, pvcam, imaqunit, nimaqdxunit, strutils, DTOpenLayersUnit ;

const
     { Interface cards supported }
     NoCamera8 = 0 ;
     NoCamera16 = 1 ;
     ITEX_CCIR = 2 ;
     ITEX_C4880_10 = 3 ;
     ITEX_C4880_12 = 4 ;
     RS_PVCAM = 5 ;
     RS_PVCAM_PENTAMAX = 6 ;
     DTOL = 7 ;
     RS_PVCAM_VC89 = 8 ;
     RS_PVCAM_VC68 = 9 ;
     RS_PVCAM_VC56 = 10 ;
     RS_PVCAM_VC51 = 11 ;
     RS_PVCAM_VC41 = 12 ;
     RS_PVCAM_VC38 = 13 ;
     RS_PVCAM_VC32 = 14 ;
     IMAQ_1394 = 15 ;
     PIXELFLY = 16 ;
     BioRad = 17 ;
     Andor = 18 ;
     UltimaLSM = 19 ;
     QCAM = 20 ;
     DCAM = 21 ;
     SENSICAM = 22 ;               // added by M.Ascherl 14.sept.2007
     IMAQ = 23 ;
     IMAQDX = 24 ;

     NumLabInterfaceTypes = 25 ;   // up from 22; M.Ascherl

     // Frame capture trigger modes
     CamFreeRun = 0 ;
     CamExtTrigger = 1 ;

     // Trigger types
     CamExposureTrigger = 0 ; // External trigger starts exposure
     CamReadoutTrigger = 1 ;  // External trigger starts readout

type

  TSESCam = class(TComponent)
  private
    { Private declarations }
    FCameraType : Integer ;      // Type of lab. interface hardware
    FCameraName : string ;       // Name of interface
    FCameraModel : string ;      // Model
    FCameraMode : Integer ;       // Camera video mode
    FCameraADC : Integer ;        // Camera A/D converter
    FComPortUsed : Boolean ;     // Camera control port in use
    FComPort : Integer ;         // Camera control port
    FCCDType : string ;          // Type CCD in camera
    FCCDClearPreExposure : Boolean ; // Clear CCD before exposure
    FCCDPostExposureReadout : Boolean ; // CCD readout is after exposure
    FCameraAvailable : Boolean ; // Camera is available for use
    FCameraActive : Boolean ;    // Camera is in use

    FFrameWidthMax : Integer ;   // Maximum width of image frame (pixels)
    FFrameHeightMax : Integer ;  // Maximum height of image frame (pixels)

    FFrameLeft : Integer ;       // Left edge of image frame in use (pixels)
    FFrameRight : Integer ;      // Right edge of image frame in use (pixels)
    FFrameTop : Integer ;        // Top edge of image frame in use (pixels)
    FFrameBottom : Integer ;     // Bottom edge of image frame in use (pixels)

    FBinFactor : Integer ;       // Pixel binning factor
    FBinFactorMax : Integer ;       // Pixel binning factor
    FFrameWidth : Integer ;      // Width of image frame in use (binned pixels)
    FFrameHeight : Integer ;     // Height of image frame in use (binned pixels)
    FCCDRegionReadoutAvailable : Boolean ; // CCD sub-region readout supported

    FFrameInterval : Double ;    // Duration of selected frame time interval (s)
    FFrameIntervalMin : Single ; // Min. time interval between frames (s)
    FFrameIntervalMax : Single ; // Max. time interval between frames (s)
    FFrameReadoutTime : Double ;

    FReadoutSpeed : Integer ;        // Frame readout speed
    FReadoutTime : Double ;          // Time to read out frame (s)
    FAmpGain : Integer ;          // Camera amplifier gain
    FTriggerMode : Integer ;      // Frame capture trigger mode
    FTriggerType : Integer ;      // Camera trigger type
    FAdditionalReadoutTime : Double ; // Additional readout time

    FPixeldepth : Integer ;     // No. of bits per pixel
    FGreyLevelMin : Integer ;   // Minimum pixel grey level value
    FGreyLevelMax : Integer ;   // Maximum pixel grey level value
    FNumBytesPerPixel : Integer ;  // No. of storage bytes per pixel

    FLensMagnification : Single ;   // Camera lens magification factor
    FPixelWidth : Single ;          // Pixel width
    FPixelUnits : String ;          // Pixel width units

    FNumFramesInBuffer : Integer ;      // Frame buffer capacity (frames)
    FNumBytesInFrameBuffer : Integer ;  // No. of bytes in frame buffer
    FNumBytesPerFrame : Integer ;       // No. of bytes per frame
    PFrameBuffer : PByteArray ;         // Pointer to ring buffer to store acquired frames

    CameraInfo : TStringList ;
    CameraGainList : TStringList ;
    CameraReadoutSpeedList : TStringList ;
    CameraModeList : TStringList ;
    CameraADCList : TStringList ;

    FTemperature : Single ;
    FTemperatureSetPoint : Single ;
    FCameraCoolingOn : Boolean ;    // TRUE = Camera peltier cooling on
    FCameraFanMode : Integer ;      // 0=Off, 1=low, 2=high
    FDisableEMCCD : Boolean ;       // TRUE=EMCDD function disabled
    FCameraRestartRequired : Boolean ;     // TRUE=restart of camera required

    ImageAreaChanged : Boolean ;   // TRUE = image area has been changed

    ITEX : TITEX ;

    // PVCAM fields
    PVCAMSession : TPVCAMSession ;
    FFrameBufferHandle : THandle ;

    // IMAQ 1394 fields
    Session : TIMAQ1394Session ;
    FrameCounter : Integer ;

    // Pixelfly fields
    PixelFlySession : TPixelFlySession ;

    // SensiCam fields
    SensiCamSession : TSensiCamSession;

    // Andor fields
    AndorSession : TAndorSession ;

    // QImaging
    QCAMSession : TQCAMSession ;

    // Hamamatsu DCAM-API
    DCAMSession : TDCAMAPISession ;

    // National Instruments (IMAQ) session
    IMAQSession : TIMAQSession ;

    // National Instruments (IMAQDX) session
    IMAQDXSession : TIMAQDXSession ;

    // Data Translation Open Layers session
    DTOLSession : TDTOLSession ;

    procedure AllocateFrameBuffer ;
    procedure DeallocateFrameBuffer ;
    procedure SetFrameLeft( Value : Integer ) ;
    procedure SetFrameRight( Value : Integer ) ;
    procedure SetFrameTop( Value : Integer ) ;
    procedure SetFrameBottom( Value : Integer ) ;
    procedure SetBinFactor( Value : Integer ) ;
    function GetFrameWidth : Integer ;
    function GetFrameHeight : Integer ;
    procedure SetReadOutSpeed( Value : Integer ) ;
    procedure SetNumFramesInBuffer( Value : Integer ) ;
    function GetMaxFramesInBuffer : Integer ;
    procedure SetFrameInterval( Value : Double ) ;
    function GetReadOutTime : Double ;
    function GetPixelWidth : Single ;
    function LimitTo(
             Value : Integer ;
             LoLimit : Integer ;
             HiLimit : Integer ) : Integer ;

    procedure SetTemperature( Value : Single ) ;
    procedure SetCameraCoolingOn( Value : Boolean ) ;
    procedure SetCameraFanMode( Value : Integer ) ;
    procedure SetDisableEMCCD( Value : Boolean ) ;

    procedure SetCameraMode( Value : Integer ) ;
    procedure SetCameraADC( Value : Integer ) ;

  protected
    { Protected declarations }
  public
    { Public declarations }
    DebugIn : Integer ;
    DebugOut : Integer ;
    Constructor Create(AOwner : TComponent) ; override ;
    Destructor Destroy ; override ;
    procedure OpenCamera( InterfaceType : Integer ) ;
    procedure CloseCamera ;
    procedure ReadCamera ;
    procedure StartCapture ;
    procedure StopCapture ;
    procedure GetFrameBufferPointer( var FrameBuf : Pointer ) ;
    procedure GetLatestFrameNumber( var FrameNum : Integer ) ;
    function GetCameraName( Num : Integer ) : String ;
    procedure GetCameraNameList( List : TStrings ) ;
    procedure GetCameraTriggerModeList( List : TStrings ) ;
    procedure GetCameraGainList( List : TStrings ) ;
    procedure GetCameraReadoutSpeedList( List : TStrings ) ;
    procedure GetCameraModeList( List : TStrings ) ;
    procedure GetCameraADCList( List : TStrings ) ;
    procedure GetCameraInfo( List : TStrings ) ;
    function IsLSM( iCameraType : Integer ) : Boolean ;
    procedure SetCCDArea( FrameLeft : Integer ;
                          FrameTop : Integer ;
                          FrameRight : Integer ;
                          FrameBottom : Integer ) ;


  published
    { Published declarations }
    Property CameraType : Integer Read FCameraType ;
    Property CameraAvailable : Boolean Read FCameraAvailable ;
    Property CameraActive : Boolean Read FCameraActive ;
    Property CameraName : string read FCameraName ;
    Property CameraModel : string read FCameraModel ;
    Property ComPort : Integer read FComPort write FComPort ;
    Property ComPortUsed : Boolean read FComPortUsed ;
    Property CCDClearPreExposure : Boolean read FCCDClearPreExposure write FCCDClearPreExposure ;
    Property CCDPostExposureReadout : Boolean read FCCDPostExposureReadout write FCCDPostExposureReadout ;    
    Property FrameWidth : Integer Read GetFrameWidth ;
    Property FrameHeight : Integer Read GetFrameHeight ;
    Property FrameLeft : Integer Read FFrameLeft Write SetFrameLeft Default 0 ;
    Property FrameRight : Integer Read FFrameRight Write SetFrameRight Default 511 ;
    Property FrameTop : Integer Read FFrameTop Write SetFrameTop Default 0 ;
    Property FrameBottom : Integer Read FFrameBottom Write SetFrameBottom Default 511 ;
    Property BinFactor : Integer Read FBinFactor Write SetBinFactor Default 1 ;
    Property CCDRegionReadoutAvailable : Boolean Read FCCDRegionReadoutAvailable ;
    Property ReadoutSpeed : Integer Read FReadoutSpeed write SetReadoutSpeed ;
    Property ReadoutTime : Double Read GetReadoutTime ;
    Property AdditionalReadoutTime : Double
             read FAdditionalReadoutTime Write FAdditionalReadoutTime ;
    Property FrameInterval : Double Read FFrameInterval Write SetFrameInterval ;
    Property PixelDepth : Integer Read FPixelDepth ;
    Property GreyLevelMin : Integer Read FGreyLevelMin ;
    Property GreyLevelMax : Integer Read FGreyLevelMax ;

    Property TriggerMode : Integer Read FTriggerMode Write FTriggerMode ;
    Property TriggerType : Integer Read FTriggerType ;
    Property AmpGain : Integer Read FAmpGain Write FAmpGain ;
    Property NumBytesPerPixel : Integer Read FNumBytesPerPixel ;
    Property NumFramesInBuffer : Integer Read FNumFramesInBuffer Write SetNumFramesInBuffer ;
    Property MaxFramesInBuffer : Integer Read GetMaxFramesInBuffer ;

    Property FrameWidthMax : Integer Read FFrameWidthMax  ;
    Property FrameHeightMax : Integer Read FFrameHeightMax ;

    Property LensMagnification : Single Read FLensMagnification Write FLensMagnification ;
    Property PixelWidth : Single Read GetPixelWidth ;
    Property PixelUnits : String Read FPixelUnits ;

    Property CameraTemperature : Single Read FTemperature ;

    Property CameraTemperatureSetPoint : Single Read FTemperatureSetPoint
                                                Write SetTemperature ;

    Property CameraCoolingOn : Boolean Read FCameraCoolingOn write SetCameraCoolingOn ;
    Property CameraFanMode : Integer Read FCameraFanMode write SetCameraFanMode ;
    Property DisableEMCCD : Boolean read FDisableEMCCD write SetDisableEMCCD ;
    Property CameraRestartRequired : Boolean read FCameraRestartRequired ;

    Property CameraMode : Integer read FCameraMode write SetCameraMode ;
    Property CameraADC : Integer read FCameraADC write SetCameraADC ;

  end;

procedure Register;

implementation

uses hamc4880 ;

procedure Register;
begin
  RegisterComponents('Samples', [TSESCam]);
end;

constructor TSESCam.Create(AOwner : TComponent) ;
{ --------------------------------------------------
  Initialise component's internal objects and fields
  -------------------------------------------------- }
begin
     inherited Create(AOwner) ;

     FCameraType := NoCamera8 ; { No Camera }
     FCameraAvailable := False ;
     FCameraActive := False ;
     FComPortUsed := False ;
     FComPort := 1 ;
     FCameraMode := 0 ;
     FCameraADC := 0 ;

     FCCDType := 'Unknown' ;
     FCCDClearPreExposure := False ;
     FCCDPostExposureReadout := False ;

     FPixelDepth := 8 ;
     FGreyLevelMin := 0 ;
     FGreyLevelMax := 255 ;

     FLensMagnification := 1.0 ;
     FPixelWidth := 1.0 ;
     FPixelUnits := '' ;

     FFrameWidthMax := 512 ;
     FFrameWidth := FFrameWidthMax ;
     FFrameHeightMax := 512 ;
     FFrameHeight := FFrameHeightMax ;

     FCCDRegionReadoutAvailable := True ;
     FBinFactor := 1 ;
     FBinFactorMax := 64 ;

     FFrameLeft := 0 ;
     FFRameRight := FFrameWidthMax - 1 ;
     FFrameWidth := (FFrameRight - FFrameLeft + 1) div FBinFactor ;
     FFrameTop := 0 ;
     FFrameBottom :=  FFrameHeightMax - 1 ;
     FFrameHeight := (FFrameBottom - FFrameTop + 1) div FBinFactor ;

     FFrameInterval := 1.0 ;
     FFrameIntervalMin := 1.0 ;
     FFrameIntervalMax := 1.0 ;

     FNumFramesInBuffer := 20 ;
     FNumBytesInFrameBuffer := 0 ;
     PFrameBuffer := Nil ;

     // Digital camera default parameters
     FReadoutSpeed := 0 ;
     FAmpGain := 0 ;
     FTriggerMode := CamFreeRun ;
     FTriggerType := CamExposureTrigger ;
     FAdditionalReadoutTime := 0.0 ;
     FDisableEMCCD := False ;
     FCameraRestartRequired := False ;

     // Initialise ITEX control record
     ITEX.ConfigFileName := '' ;
     ITEX.PModHandle := Nil  ;
     ITEX.AModHandle := Nil  ;
     ITEX.GrabHandle := Nil ;
     ITEX.FrameWidth := 0 ;
     ITEX.FrameHeight := 0 ;
     ITEX.SystemInitialised := False ;

     IMAQDXSession.CameraOpen := False ;

     // Create camera information list
     CameraInfo := TStringList.Create ;

     // Create camera readout speed list
     CameraReadoutSpeedList := TStringList.Create ;

     // List of available camera gains
     CameragainList := TStringList.Create ;

     // List of available camera operating modes
     CameraModeList := TStringList.Create ;
     CameraModeList.Add(' ') ;

     // A/D converter list
     CameraADCList := TStringList.Create ;

     FTemperature := 0.0 ;
     FTemperatureSetPoint := -50.0 ;
     FCameraCoolingOn := True ;
     FCameraFanMode  := 1 ;         // Andor Low settings

     ImageAreaChanged := False ;

     end ;


destructor TSESCam.Destroy ;
{ ------------------------------------
   Tidy up when component is destroyed
   ----------------------------------- }
begin

     // Shut down camera/frame grabber
     CloseCamera ;

     DeallocateFrameBuffer ;
     {if PFrameBuffer <> Nil then FreeMem(PFrameBuffer) ;
     PFrameBuffer := Nil ;}

     CameraInfo.Free ;
     CameraReadoutSpeedList.Free ;
     CameraGainList.Free ;
     CameraModeList.Free ;
     CameraADCList.Free ;

     { Call inherited destructor }
     inherited Destroy ;
     end ;


function TSESCam.GetCameraName( Num : Integer ) : String ;
{ -------------------------------------
  Get name of laboratory interface unit
  ------------------------------------- }
begin
     case Num of
       NoCamera8 : Result := 'No Camera (8 bit)' ;
       NoCamera16 : Result := 'No Camera (16 bit)' ;
       ITEX_CCIR : Result := 'PCVISON/CCIR video' ;
       ITEX_C4880_10 : Result := 'Hamamatsu C4880-81 (10 bit)' ;
       ITEX_C4880_12 : Result := 'Hamamatsu C4880-81 (12 bit)' ;
       RS_PVCAM : Result := 'Photometrics/Princeton PVCAM' ;
       RS_PVCAM_PENTAMAX : Result := 'Princeton I-PentaMax (PVCAM)' ;
       DTOL : Result := 'Data Translation Frame Grabber' ;
       RS_PVCAM_VC89 : Result := 'Not in use' ;
       RS_PVCAM_VC68 : Result := 'Not in use' ;
       RS_PVCAM_VC56 : Result := 'Not in use' ;
       RS_PVCAM_VC41 : Result := 'Not in use' ;
       RS_PVCAM_VC38 : Result := 'Not in use' ;
       RS_PVCAM_VC32 : Result := 'Not in use' ;
       IMAQ_1394 : Result := 'National Instruments (IMAQ-1394)' ;
       PIXELFLY : Result := 'PCO Pixelfly' ;
       BioRad : Result := 'BioRad Radiance/MRC 1024' ;
       UltimaLSM : Result := 'Praire Technology Ultima' ;
       Andor : Result := 'Andor iXon/Luca ' ;
       QCAM : Result := 'QImaging QCAM-API' ;
       DCAM : Result := 'Hamamatsu DCAM' ;
       SENSICAM : Result := 'PCO SensiCam';
       IMAQ : Result := 'National Instruments (IMAQ)' ;
       IMAQDX : Result := 'National Instruments (IMAQ-DX)' ;

       end ;
     end ;


procedure TSESCam.GetCameraNameList( List : TStrings ) ;
// -------------------------------------------
// Get list of available camera/interface list
// -------------------------------------------
var
     i : Integer ;
begin
     List.Clear ;
     for i := 0 to NumLabInterfaceTypes-1 do
         List.Add(GetCameraName( i )) ;
     end ;


procedure TSESCam.GetCameraTriggerModeList( List : TStrings ) ;
// -------------------------------------------
// Get list of available camera triggering modes
// -------------------------------------------
begin
     List.Clear ;
     List.Add( 'Free Run' ) ;
     List.Add( 'Ext. Trigger' ) ;
     List.Add( 'Ext. Start' ) ;
     end ;


procedure TSESCam.OpenCamera(
          InterfaceType : Integer
          ) ;
{ ------------------------------------------------
  Set type of camera/frame grabber hardware in use
  ------------------------------------------------ }
var
     ReadoutRate : Integer ;
     i : Integer ;
begin

     { Initialise lab. interface hardware }
     FCameraType := InterfaceType ;
     FCameraModel := 'Unknown' ;
     FCameraMode := 0 ;
     FComPortUsed := False ;

     // default settings
     FNumBytesPerPixel := 1 ;
     FPixelDepth :=  8 ;
     FGreyLevelMin := 0 ;
     FGreyLevelMax := $FF ;
     FPixelWidth := 1.0 ;
     FPixelUnits := '' ;
     FTriggerType := CamExposureTrigger ;

     CameraGainList.Clear ;
     CameraGainList.Add( '1 ' ) ;

     CameraReadoutSpeedList.Clear ;
     CameraReadoutSpeedList.Add( ' n/a ' ) ;

     case FCameraType of

       NoCamera8 : begin
          FCameraName := 'No Camera' ;
          FNumBytesPerPixel := 1 ;
          FPixelDepth :=  8 ;
          FGreyLevelMin := 0 ;
          FGreyLevelMax := $FF ;
          FPixelWidth := 1.0 ;
          FPixelUnits := '' ;
          FTriggerType := CamExposureTrigger ;
          end ;

       NoCamera16 : begin
          FCameraName := 'No Camera' ;
          FNumBytesPerPixel := 2 ;
          FPixelDepth :=  16 ;
          FGreyLevelMin := 0 ;
          FGreyLevelMax := $FFFF ;
          FPixelWidth := 1.0 ;
          FPixelUnits := '' ;
          FTriggerType := CamExposureTrigger ;
          end ;

       ITEX_CCIR : begin
          FCameraName := GetCameraName( ITEX_CCIR ) ;
          CameraInfo.Clear ;
          CameraInfo.Add( 'Camera Type: ' + FCameraName ) ;
          //ITEX.ConfigFileName := 'c:\itex41\config\ccir.cnf' ;
          ITEX.ConfigFileName := 'ccir.cnf' ;
          CameraInfo.Add( 'Config file: ' + ITEX.ConfigFileName ) ;
          ITEX.HostTransferPossible := False ;

          FNumBytesPerPixel := 1 ;
          FCameraAvailable := ITEX_OpenFrameGrabber(
                              ITEX,
                              CameraInfo,
                              FNumBytesPerPixel,
                              True ) ;

          FFrameWidthMax := ITEX.FrameWidth ;
          FFrameHeightMax := ITEX.FrameHeight ;

          FPixelDepth :=  8 ;
          FGreyLevelMin := 0 ;
          FGreyLevelMax := 255 ;

          FBinFactor := 1 ;
          FBinFactorMax := 1 ;

          FPixelWidth := 1.0 ;
          FPixelUnits := '' ;

          // Fixed frame interval
          FFrameInterval := 1.0/25.0 ;
          FFrameIntervalMin := FFrameInterval ;
          FFrameIntervalMax := FFrameInterval ;

          FReadoutSpeed := 0 ;
          FTriggerType := CamExposureTrigger ;

          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          // Open Hamamatsu C4880 with ITEX RS422 frame grabber

          FCameraName := GetCameraName( FCameraType ) ;
          //ITEX.ConfigFileName := 'c:\itex41\config\camdb\hamc4880.cnf' ;
          ITEX.ConfigFileName := 'hamc4880.cnf' ;
          ITEX.HostTransferPossible := False ;
          FComPortUsed := True ;
          FNumBytesPerPixel := 2 ;

          // Initialise frame grabber
          FCameraAvailable := ITEX_OpenFrameGrabber(
                              ITEX,
                              CameraInfo,
                              FNumBytesPerPixel,
                              False ) ;
          FFrameWidthMax := ITEX.FrameWidth ;
          FFrameHeightMax := ITEX.FrameHeight ;
          FBinFactorMax := 16 ;
          FGreyLevelMin := 0 ;
          FCCDRegionReadoutAvailable := True ;

          if FCameraType = ITEX_C4880_10 then begin
             FPixelDepth :=  16 ;
             FGreyLevelMax := (32768*2) -1;
             ReadoutRate := FastReadout ;
             end
          else begin
             FPixelDepth :=  16 ;
             FGreyLevelMax := (32768*2) -1 ;
             ReadoutRate := SlowReadout ;
             end ;

          FPixelWidth := 9.9 ;
          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;

          // Initialise camera
          C4880_OpenCamera( FComPort, ReadoutRate, CameraInfo ) ;

          C4880_GetCameraGainList( CameraGainList ) ;

          end ;

       IMAQ_1394 : begin

          CameraInfo.Clear ;
          FCameraAvailable := IMAQ1394_OpenCamera(
                              Session,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             IMAQ1394_GetCameraGainList( CameraGainList ) ;

             // Get camera readout speed options
             CameraModeList.Clear ;
             IMAQ1394_GetCameraVideoMode( Session, True, CameraModeList ) ;
             FReadoutSpeed := 1 ;
             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FCCDRegionReadoutAvailable := False ;
             // Get frame readout speed
         {    IMAQ1394_CheckFrameInterval( 0,FFrameWidthMax-1,
                                       0,FFrameHeightMax-1,
                                       1,
                                       FFrameInterval, FReadoutTime ) ;  }

             FBinFactor := 1 ;
             FBinFactorMax := 1 ;

             end ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelWidth := 15.0 ;
          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;

          end ;

       PIXELFLY : begin

          CameraInfo.Clear ;
          FCameraAvailable := PixelFly_OpenCamera(
                              PixelFlySession,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              FPixelWidth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             PixelFly_GetCameraGainList( CameraGainList ) ;

             // Get camera readout speed options
             FReadoutSpeed := 1 ;
             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FBinFactorMax := 2 ;
             FCCDRegionReadoutAvailable := False ;

             end ;

          FFrameWidth := FFrameWidthMax ;
          FFrameHeight := FFrameHeightMax ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelWidth := 15.0 ;
          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;

          end ;


       SENSICAM : begin

          CameraInfo.Clear ;
          FCameraAvailable := SENSICAM_OpenCamera(
                              SENSICAMSession,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              FPixelWidth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             SENSICAM_GetCameraGainList( CameraGainList ) ;  // no gains supported yet

             // Get camera readout speed options
             FReadoutSpeed := 1 ;
             // Calculate grey levels from pixel depth
             FPixelDepth :=  12 ;
             FGreyLevelMax := 4095; //FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FBinFactor := 1 ;
             FBinFactorMax := 8 ;    // symmetrical;
             FCCDRegionReadoutAvailable := False ;
             FFrameInterval := 0.100 ;
            { SensicamCheckFrameInterval( SensicamSession,
                                         FFrameWidthMax-1,
                                         FBinFactor,
                                         FTriggerMode,
                                         FFrameInterval,
                                         FReadoutTime ) ;
             }
             end ;

          FFrameWidth := FFrameWidthMax ;
          FFrameHeight := FFrameHeightMax ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelWidth := 15.0 ;
          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;

          end ;


       RS_PVCAM,RS_PVCAM_PENTAMAX : begin

          CameraInfo.Clear ;
          FCameraAvailable := PVCAM_OpenCamera(
                              PVCAMSession,
                              FReadoutSpeed,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FGreyLevelMax,
                              FPixelWidth,
                              FPixelDepth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             PVCAM_GetCameraGainList( PVCAMSession,CameraGainList ) ;

             // Get camera readout speed options
             CameraReadoutSpeedList.Clear ;
             PVCAM_GetCameraReadoutSpeedList( PVCAMSession,CameraReadoutSpeedList ) ;
             FCCDRegionReadoutAvailable := True ;
             FFrameInterval := 0.1 ;
             // Get frame readout speed
             PVCAM_CheckFrameInterval( PVCAMSession,
                                       0,FFrameWidthMax-1,
                                       0,FFrameHeightMax-1,
                                       1,
                                       FReadoutSpeed,
                                       FFrameInterval,
                                       FReadoutTime ) ;

             end ;


          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 100.0 ;

          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;

          end ;

       BioRad : begin
          FCameraName := 'BioRad Radiance/MRC 1024' ;
          FNumBytesPerPixel := 1 ;
          FPixelDepth :=  8 ;
          FGreyLevelMin := 0 ;
          FGreyLevelMax := $FF ;
          FPixelWidth := 1.0 ;
          FPixelUnits := '' ;
          FTriggerType := CamExposureTrigger ;
          end ;

       ANDOR : begin

          CameraInfo.Clear ;
          AndorSession.ADChannel := FCameraADC ;
          AndorSession.CameraMode := FCameraMode ;
          FCameraAvailable := Andor_OpenCamera(
                              AndorSession,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              FPixelWidth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             Andor_GetCameraGainList( CameraGainList ) ;

             Andor_GetCameraModeList( CameraModeList ) ;

             Andor_GetCameraADCList( CameraADCList ) ;

             // List of readout speeds
             Andor_GetCameraReadoutSpeedList( AndorSession, CameraReadoutSpeedList ) ;
             FReadoutSpeed := 0 ;
             AndorSession.ReadoutSpeed := FReadoutSpeed ;

             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FBinFactorMax := 4 ;
             FCCDRegionReadoutAvailable := True ;

             // Set temperature set point
             Andor_SetTemperature( AndorSession, FTemperatureSetPoint ) ;
             Andor_SetCooling( AndorSession, FCameraCoolingOn ) ;
             Andor_SetFanMode( AndorSession, FCameraFanMode ) ;
             Andor_SetCameraMode( AndorSession, FCameraMode ) ;

             end ;


          FFrameWidth := FFrameWidthMax ;
          FFrameHeight := FFrameHeightMax ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelUnits := 'um' ;
          FTriggerType := CamReadoutTrigger ;

          end ;

       UltimaLSM : begin
          FCameraName := 'Prairie Technology Ultima' ;
          FNumBytesPerPixel := 1 ;
          FPixelDepth :=  2048 ;
          FGreyLevelMin := 0 ;
          FGreyLevelMax := 2047 ;
          FPixelWidth := 1.0 ;
          FPixelUnits := '' ;
          FTriggerType := CamExposureTrigger ;
          end ;

       QCAM : begin

          CameraInfo.Clear ;
          FCameraAvailable := QCAMAPI_OpenCamera(
                              QCAMSession,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              FPixelWidth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             QCAMAPI_GetCameraGainList( QCAMSession, CameraGainList ) ;

             // List of readout speeds
             QCAMAPI_GetCameraReadoutSpeedList( QCAMSession, CameraReadoutSpeedList ) ;
             FReadoutSpeed := 0 ;

             // Get camera readout speed options

             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FBinFactorMax := 8 ;
             FCCDRegionReadoutAvailable := True ;

             end ;

          FFrameWidth := FFrameWidthMax ;
          FFrameHeight := FFrameHeightMax ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelUnits := 'um' ;
          //FTriggerType := CamReadoutTrigger ;
          FTriggerType := CamExposureTrigger ;

          end ;

       DCAM : begin

          CameraInfo.Clear ;
          FCameraAvailable := DCAMAPI_OpenCamera(
                              DCAMSession,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              FPixelWidth,
                              FBinFactorMax,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             DCAMAPI_GetCameraGainList( DCAMSession, CameraGainList ) ;

             // List of readout speeds
             DCAMAPI_GetCameraReadoutSpeedList( DCAMSession, CameraReadoutSpeedList ) ;
             FReadoutSpeed := 0 ;

             // Get camera readout speed options

             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FCCDRegionReadoutAvailable := True ;

             if ANSIContainsText(DCAMSession.CameraModel, 'C9100') then begin
                FTriggerType := CamReadoutTrigger ;
                end
             else FTriggerType := CamExposureTrigger ;

             end ;

          FFrameWidth := FFrameWidthMax ;
          FFrameHeight := FFrameHeightMax ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;

          end ;

       IMAQ : begin

          CameraInfo.Clear ;
          FCameraAvailable := IMAQ_OpenCamera(
                              IMAQSession,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             IMAQ_GetCameraGainList( CameraGainList ) ;

             // Get camera readout speed options
             FReadoutSpeed := 1 ;
             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FCCDRegionReadoutAvailable := True ;
             // Get frame readout speed
             IMAQ_CheckFrameInterval( IMAQSession, FFrameInterval ) ;

             FBinFactor := 1 ;
             FBinFactorMax := 1 ;
             FFrameWidth := FFrameWidthMax ;
             FFrameHeight := FFrameHeightMax ;

             end ;
          end ;

       IMAQDX : begin

          CameraInfo.Clear ;
         
          FCameraAvailable := IMAQDX_OpenCamera(
                              IMAQDXSession,
                              FCameraMode,
                              FCameraADC,
                              FFrameWidthMax,
                              FFrameHeightMax,
                              FNumBytesPerPixel,
                              FPixelDepth,
                              FBinFactorMax,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             CameraGainList.Clear ;
             IMAQDX_GetCameraGainList( CameraGainList ) ;

             // Get camera readout speed options
             CameraModeList.Clear ;
             IMAQDX_GetCameraVideoModeList( IMAQDXSession, CameraModeList ) ;

             IMAQDX_GetCameraPixelFormatList( IMAQDXSession, CameraADCList ) ;

             FReadoutSpeed := 1 ;
             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FCCDRegionReadoutAvailable := True ;
             // Get frame readout speed
             IMAQDX_CheckFrameInterval( IMAQDXSession, FFrameInterval ) ;

             FBinFactor := 1 ;
//             FBinFactorMax := 8 ;
             FFrameWidth := FFrameWidthMax ;
             FFrameHeight := FFrameHeightMax ;

             end ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelWidth := 15.0 ;
          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;
          ImageAreaChanged := True ;

          end ;

       DTOL : begin

          CameraInfo.Clear ;
          FCameraAvailable := DTOL_OpenCamera(
                              DTOLSession,
                              CameraInfo ) ;

          if FCameraAvailable then begin

             FFrameWidthMax := DTOLSession.FrameWidthMax ;
             FFrameHeightMax := DTOLSession.FrameHeightMax ;
             FNumBytesPerPixel := DTOLSession.NumBytesPerPixel ;
             FPixelDepth := DTOLSession.PixelDepth ;

             CameraGainList.Clear ;
             DTOL_GetCameraGainList( CameraGainList ) ;

             // Get camera readout speed options
             CameraModeList.Clear ;
             DTOL_GetCameraVideoModeList( DTOLSession, CameraModeList ) ;

             FReadoutSpeed := 1 ;
             // Calculate grey levels from pixel depth
             FGreyLevelMax := 1 ;
             for i := 1 to FPixelDepth do FGreyLevelMax := FGreyLevelMax*2 ;
             FGreyLevelMax := FGreyLevelMax - 1 ;
             FGreyLevelMin := 0 ;
             FCCDRegionReadoutAvailable := True ;
             // Get frame readout speed
             DTOL_CheckFrameInterval( DTOLSession, FTriggerMode, FFrameInterval ) ;

             FBinFactor := 1 ;
             FBinFactorMax := 1 ;
             FFrameWidth := FFrameWidthMax ;
             FFrameHeight := FFrameHeightMax ;

             end ;

          FFrameIntervalMin := 1E-3 ;
          FFrameIntervalMax := 1000.0 ;

          FPixelWidth := 15.0 ;
          FPixelUnits := 'um' ;
          FTriggerType := CamExposureTrigger ;
          ImageAreaChanged := True ;
          end ;
       end ;

     if FCameraAvailable then begin

        FFrameLeft := 0 ;
        FFrameRight := FFrameWidthMax - 1 ;
        FFrameTop := 0 ;
        FFrameBottom := FFrameHeightMax - 1 ;
        FFrameWidth := FFrameWidthMax div FBinFactor ;
        FFrameHeight := FFrameHeightMax div FBinFactor ;

        // Allocate internal frame buffer
        AllocateFrameBuffer ;
        ImageAreaChanged := False ;
        end ;
     end ;


procedure TSESCam.ReadCamera ;
// -----------------------
// Read frames from camera
// -----------------------
begin

     if FCameraAvailable then begin

        case FCameraType of

            NoCamera8 : begin

              end ;

            NoCamera16 : begin

              end ;

            ITEX_CCIR : begin
              end ;

            ITEX_C4880_10,ITEX_C4880_12 : begin
              end ;

            RS_PVCAM,RS_PVCAM_PENTAMAX : begin
              end ;

            IMAQ_1394 : begin
              IMAQ1394_GetImage( Session ) ;
              end ;

            PIXELFLY : begin
{              PixelFly_GetImage( PixelFlySession,
                                 PFrameBuffer,
                                 FNumFramesInBuffer,
                                 FNumBytesPerFrame,
                                 FrameCounter ) ;}

              end ;

            SENSICAM : Begin
               SensiCAM_GetImageFast ( SensicamSession );
              end;

            ANDOR : begin
              Andor_GetImage( AndorSession ) ;
              end ;

            QCAM : begin
              QCAMAPI_GetImage( QCAMSession ) ;
              end ;

            DCAM : begin
              DCAMAPI_GetImage( DCAMSession ) ;
              end ;

            IMAQ : begin
              IMAQ_GetImage( IMAQSession ) ;
              end ;

            IMAQDX : begin
              IMAQDX_GetImage( IMAQDXSession ) ;
              end ;

            DTOL : begin
              DTOL_GetImage( DTOLSession ) ;
              end ;

            end ;
        end ;

     end ;


procedure TSESCam.CloseCamera ;
{ -------------------------------------
  Close camera/frame grabber sub-system
  ------------------------------------- }
begin

     if FCameraAvailable then begin

        case FCameraType of

            NoCamera8 : begin
              FCameraName := 'No Camera' ;
              end ;

            NoCamera16 : begin
              FCameraName := 'No Camera' ;
              end ;

            ITEX_CCIR : begin
              ITEX_CloseFrameGrabber( ITEX ) ;
              end ;

            ITEX_C4880_10,ITEX_C4880_12 : begin
              C4880_CloseCamera ;
              ITEX_CloseFrameGrabber( ITEX ) ;
              end ;

            RS_PVCAM,RS_PVCAM_PENTAMAX : begin
              PVCAM_CloseCamera(PVCAMSession) ;
              FCameraAvailable := False ;
              end ;

            IMAQ_1394 : begin
              IMAQ1394_CloseCamera( Session ) ;
              end ;

            PIXELFLY : begin
              PixelFly_CloseCamera( PixelFlySession ) ;
              end ;

            Sensicam : begin
              Sensicam_CloseCamera ( SensicamSession );
              end;

            ANDOR : begin
              Andor_CloseCamera( AndorSession ) ;
              end ;

            QCAM : begin
              QCAMAPI_CloseCamera( QCAMSession ) ;
              end ;

            DCAM : begin
              DCAMAPI_CloseCamera( DCAMSession ) ;
              end ;

            IMAQ : begin
              IMAQ_CloseCamera( IMAQSession ) ;
              end ;

            IMAQDX : begin
              IMAQDX_CloseCamera( IMAQDXSession ) ;
              end ;

            DTOL : begin
              DTOL_CloseCamera( DTOLSession ) ;
              end ;

            end ;

        end ;

     if PFrameBuffer <> Nil then DeallocateFrameBuffer ;
     FCameraAvailable := False ;

     end ;


procedure TSESCam.AllocateFrameBuffer ;
// -----------------------------------------
// Allocate/reallocate internal frame buffer
// -----------------------------------------
begin

    // Default checks (in case checks not implemented for camera)

    FFrameLeft := Min(Max(FFrameLeft,0),FFrameWidthMax-1) ;
    FFrameTop := Min(Max(FFrameTop,0),FFrameHeightMax-1) ;
    FFrameRight := Min(Max(FFrameRight,0),FFrameWidthMax-1) ;
    FFrameBottom := Min(Max(FFrameBottom,0),FFrameHeightMax-1) ;
    if FFrameLeft >= FFrameRight then FFrameRight := FFrameLeft + FBinFactor - 1 ;
    if FFrameTop >= FFrameBottom then FFrameBottom := FFrameBottom + FBinFactor - 1 ;
    if FFrameRight >= FFrameWidthMax then FFrameRight := FFrameWidthMax - FBinFactor ;
    if FFrameBottom >= FFrameHeightMax then FFrameBottom := FFrameHeightMax - FBinFactor ;

    FFrameLeft := (FFrameLeft div FBinFactor)*FBinFactor ;
    FFrameTop := (FFrameTop div FBinFactor)*FBinFactor ;
    FFrameRight := (FFrameRight div FBinFactor)*FBinFactor + (FBinFactor-1) ;
    FFrameBottom := (FFrameBottom div FBinFactor)*FBinFactor + (FBinFactor-1) ;

    // Ensure right/bottom edge does not exceed frame

    if FFrameRight >= FFrameWidthMax then FFrameRight := FFrameRight - BinFactor ;
    FFrameWidth := ((FFrameRight - FFrameLeft) div FBinFactor) + 1 ;

    if FFrameBottom >= FFrameHeightMax then FFrameBottom := FFrameBottom - FBinFactor ;
    FFrameHeight := ((FFrameBottom - FFrameTop) div FBinFactor) + 1 ;

      case FCameraType of

          ITEX_CCIR : begin
              FFrameLeft := (FFrameLeft div 8)*8 ;
              FFrameWidth := ((FFrameRight - FFrameLeft + 1) div 16)*16 ;
              FFrameRight := FFrameLeft + FFrameWidth - 1 ;
              end ;

          ITEX_C4880_10,ITEX_C4880_12 : begin
              FFrameWidth := (FFrameWidth div 4)*4 ;
              FFrameRight := FFrameLeft + (FBinFactor*FFrameWidth) - 1 ;
              end ;

          RS_PVCAM,RS_PVCAM_PENTAMAX : begin
              PVCAM_CheckROIBoundaries(   FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FBinFactor,
                                          FFrameWidthMax,
                                          FFrameHeightMax,
                                          FFrameWidth,
                                          FFrameHeight,
                                          ) ;
               end ;

          ANDOR : begin
              ANDOR_CheckROIBoundaries(   AndorSession,
                                          FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FBinFactor,
                                          FFrameWidthMax,
                                          FFrameHeightMax,
                                          FFrameWidth,
                                          FFrameHeight,
                                          ) ;
               end ;

          QCAM : begin
              QCAMAPI_CheckROIBoundaries( QCAMSession,
                                          FReadoutSpeed,
                                          FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FBinFactor,
                                          FFrameWidth,
                                          FFrameHeight,
                                          FTriggerMode,
                                          FFrameInterval,
                                          FReadoutTime ) ;
              end ;
          DCAM : begin
              DCAMAPI_CheckROIBoundaries( DCAMSession,
                                          FReadoutSpeed,
                                          FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FBinFactor,
                                          FFrameWidth,
                                          FFrameHeight,
                                          FFrameInterval,
                                          FReadoutTime ) ;
              end ;

          IMAQ : begin
              IMAQ_CheckROIBoundaries( IMAQSession,
                                          FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FFrameWidth,
                                          FFrameHeight ) ;
              end ;

          IMAQDX : begin
              IMAQDX_CheckROIBoundaries( IMAQDXSession,
                                          FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FBinFactor,
                                          FFrameWidth,
                                          FFrameHeight ) ;
              end ;

          DTOL : begin
              DTOL_CheckROIBoundaries( DTOLSession,
                                          FFrameLeft,
                                          FFrameRight,
                                          FFrameTop,
                                          FFrameBottom,
                                          FFrameWidth,
                                          FFrameHeight ) ;
              end ;
          end ;

     FNumBytesPerFrame := FFrameWidth*FFrameHeight*FNumBytesPerPixel ;
     FNumBytesInFrameBuffer := FNumBytesPerFrame*FNumFramesInBuffer ;

     //outputdebugString(PChar(format('NBiFB %d %d',[FNumBytesInFrameBuffer,FNumBytesPerFrame]))) ;

     DeallocateFrameBuffer ;

     if FNumBytesInFrameBuffer > 0 then GetMem( PFrameBuffer, FNumBytesInFrameBuffer + 4096 ) ;

     ImageAreaChanged := False ;

     end ;


procedure TSESCam.DeallocateFrameBuffer ;
// --------------------------------
// Deallocate internal frame buffer
// --------------------------------
begin
     if PFrameBuffer <> Nil then begin
        FreeMem( PFrameBuffer ) ;
        PFrameBuffer := Nil ;
        end ;
     end ;


procedure TSESCam.StartCapture ;
{ --------------------
  Start frame capture
  -------------------- }
var
     ReadoutRate : Integer ;
begin

     //AllocateFrameBuffer ;

     if FAmpGain < 0 then FAmpGain := 0 ;

     case FCameraType of

       ITEX_CCIR : begin
          FCameraActive := ITEX_StartCapture( ITEX,
                           FFrameLeft,
                           FFrameRight,
                           FFrameTop,
                           FFrameBottom,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FFrameWidth,
                           FFrameHeight ) ;

          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          // Start frame grabber
          FCameraActive := ITEX_StartCapture( ITEX,
                           0,
                           ((FFrameRight - FFrameLeft + 1) div FBinFactor)-1,
                           0,
                           ((FFrameBottom - FFrameTop + 1) div FBinFactor)-1,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FFrameWidth,
                           FFrameHeight ) ;
          FFrameRight := FFrameLeft + FFrameWidth*FBinFactor - 1 ;
          // Select camera readout rate
          if FCameraType = ITEX_C4880_10 then ReadoutRate := FastReadout
                                         else ReadoutRate := SlowReadout ;
          // Start camera
          FCameraActive := C4880_StartCapture(
                           ReadoutRate,
                           FFrameInterval,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           FReadoutTime ) ;

          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          FCameraActive := PVCAM_StartCapture( PVCAMSession,
                                               FFrameLeft,
                                               FFrameRight,
                                               FFrameTop,
                                               FFrameBottom,
                                               FBinFactor,
                                               PFrameBuffer,
                                               FNumBytesInFrameBuffer,
                                               FFrameInterval,
                                               FAdditionalReadoutTime,
                                               FAmpGain,
                                               FFrameWidth,
                                               FFrameHeight,
                                               FTriggerMode,
                                               FReadoutSpeed,
                                               FCCDClearPreExposure,
                                               FCCDPostExposureReadout ) ;
          FTemperature := PVCAMSession.Temperature ;
          end ;

       IMAQ_1394 : begin
          FCameraActive := IMAQ1394_StartCapture(
                           Session,
                           FFrameInterval,
                           FAdditionalReadoutTime,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame
                           ) ;
          FrameCounter := 0 ;
          end ;

       PIXELFLY : begin
          FCameraActive := PixelFly_StartCapture(
                           PixelFlySession,
                           FFrameInterval,
                           FAdditionalReadoutTime,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame
                           ) ;
          FrameCounter := 0 ;
          end ;

      SENSICAM : begin
          FCameraActive := SENSICAM_StartCapture(
                           SENSICAMSession,
                           FFrameInterval,       // this should be the ExposureTime ?
                           FAdditionalReadoutTime,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame
                           ) ;
          FrameCounter := 0 ;
          end ;



       ANDOR : begin
          // Note Andor cameras do not support additional readout time
          FCameraActive := Andor_StartCapture(
                           AndorSession,
                           FFrameInterval,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame,
                           FReadoutTime
                           ) ;
          FrameCounter := 0 ;
          FTemperature := AndorSession.Temperature ;
          end ;

       QCAM : begin
          FCameraActive := QCAMAPI_StartCapture(
                           QCAMSession,
                           FFrameInterval,
                           FAdditionalReadoutTime,
                           FAmpGain,
                           FReadoutSpeed,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameRight,
                           FFrameTop,
                           FFrameBottom,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame,
                           FCCDClearPreExposure
                           ) ;
          FrameCounter := 0 ;
          FTemperature := QCAMSession.Temperature ;
          end ;

       DCAM : begin
          FCameraActive := DCAMAPI_StartCapture(
                           DCAMSession,
                           FFrameInterval,
                           FAdditionalReadoutTime,
                           FAmpGain,
                           FReadoutSpeed,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameRight,
                           FFrameTop,
                           FFrameBottom,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame,
                           FDisableEMCCD
                           ) ;
          FrameCounter := 0 ;
          //FTemperature := QCAMSession.Temperature ;
          end ;

       IMAQ : begin
          FCameraActive := IMAQ_StartCapture(
                           IMAQSession,
                           FFrameInterval,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame
                           ) ;
          FrameCounter := 0 ;
          end ;

       IMAQDX : begin
          FCameraActive := IMAQDX_StartCapture(
                           IMAQDXSession,
                           FFrameInterval,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame
                           ) ;
          FrameCounter := 0 ;
          end ;

       DTOL : begin
          FCameraActive := DTOL_StartCapture(
                           DTOLSession,
                           FFrameInterval,
                           FAmpGain,
                           FTriggerMode,
                           FFrameLeft,
                           FFrameTop,
                           FFrameWidth*FBinFactor,
                           FFrameHeight*FBinFactor,
                           FBinFactor,
                           PFrameBuffer,
                           FNumFramesInBuffer,
                           FNumBytesPerFrame
                           ) ;
          FrameCounter := 0 ;
          end ;

       end ;

     FCameraRestartRequired := False ;

     end ;


procedure TSESCam.StopCapture ;
{ --------------------
  Stop frame capture
  -------------------- }
begin

     if not FCameraActive then Exit ;

     case FCameraType of

       ITEX_CCIR : begin
          FCameraActive := ITEX_StopCapture( ITEX ) ;
          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          C4880_StopCapture ;
          FCameraActive := ITEX_StopCapture( ITEX ) ;
          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          PVCAM_StopCapture(PVCAMSession) ;
          FCameraActive := False ;
          end ;

       IMAQ_1394 : begin
          IMAQ1394_StopCapture( Session ) ;
          FCameraActive := False ;
          end ;

       PIXELFLY : begin
          PixelFly_StopCapture( PixelFlySession ) ;
          FCameraActive := False ;
          end ;

       Sensicam : Begin
          SensiCam_StopCapture( SensiCamSession ) ;
          FCameraActive := False ;
          end;

       ANDOR : begin
          Andor_StopCapture( AndorSession ) ;
          FCameraActive := False ;
          end ;

       QCAM : begin
          QCAMAPI_StopCapture( QCAMSession ) ;
          FCameraActive := False ;
          end ;

       DCAM : begin
          DCAMAPI_StopCapture( DCAMSession ) ;
          FCameraActive := False ;
          end ;

       IMAQ : begin
          IMAQ_StopCapture( IMAQSession ) ;
          FCameraActive := False ;
          end ;

       IMAQDX : begin
          IMAQDX_StopCapture( IMAQDXSession ) ;
          FCameraActive := False ;
          end ;

       DTOL : begin
          DTOL_StopCapture( DTOLSession ) ;
          FCameraActive := False ;
          end ;

       end ;
     end ;


procedure TSESCam.GetLatestFrameNumber( var FrameNum : Integer ) ;
begin
     case FCameraType of

       ITEX_CCIR : begin
          FrameNum := ITEX_GetLatestFrameNumber( ITEX ) ;
          end ;
       RS_PVCAM,RS_PVCAM_PENTAMAX : Begin
          FrameNum :=  PVCAM_GetLatestFrameNumber(PVCAMSession) ;
          end ;
       end ;
     end ;


procedure TSESCam.GetFrameBufferPointer( var FrameBuf : Pointer ) ;
begin
     FrameBuf := PFrameBuffer ;
     end ;


procedure TSESCam.SetFrameTop( Value : Integer ) ;
// ----------------------------------
// Set Top edge of camera image frame
// ----------------------------------
begin

     if not FCameraActive then begin
        FFrameTop := Value ;
        ImageAreaChanged := True ;
        end ;

     end ;


procedure TSESCam.SetFrameBottom( Value : Integer ) ;
// -------------------------------------
// Set bottom edge of camera image frame
// -------------------------------------
begin

     if not FCameraActive then begin
        FFrameBottom := Value ;
        ImageAreaChanged := True ;
        end ;

     end ;


procedure TSESCam.SetBinFactor( Value : Integer ) ;
// -------------------------
// Set pixel binning factor
// ------------------------
begin

     if not FCameraActive then begin
        FBinFactor := LimitTo( Value, 1, FBinFactorMax ) ;
        case FCameraType of
            Sensicam : SensiCam_CheckBinFactor(FBinFactor) ;
            end ;
        ImageAreaChanged := True ;
        end ;

     end ;


procedure TSESCam.SetFrameLeft( Value : Integer ) ;
// -----------------------------------
// Set left edge of camera image frame
// -----------------------------------
begin

     if not FCameraActive then begin
        FFrameLeft := Value ;
        ImageAreaChanged := True ;
        end ;

     end ;


procedure TSESCam.SetFrameRight( Value : Integer ) ;
// -----------------------------------
// Set right edge of camera image frame
// -----------------------------------
begin

     if not FCameraActive then begin
        FFrameRight := Value ;
        ImageAreaChanged := True ;
        end ;

     end ;


function TSESCam.GetFrameWidth : Integer ;
// --------------------------
// Get pixel width of camera image
// ---------------------------
begin

     if (not FCameraActive) and ImageAreaChanged then AllocateFrameBuffer ;
     Result := FFrameWidth ;

     end ;


function TSESCam.GetFrameHeight : Integer ;
// --------------------------
// Get pixel height of camera image
// ---------------------------
begin

     if (not FCameraActive) and ImageAreaChanged then AllocateFrameBuffer ;
     Result := FFrameHeight ;

     end ;


procedure TSESCam.SetReadOutSpeed( Value : Integer ) ;
// -------------------------------
// Set camera read out speed index
// -------------------------------
begin

     FReadoutSpeed := Max(Min(Value,CameraReadoutSpeedList.Count-1),0) ;

     case FCameraType of
       ITEX_CCIR : begin
          end ;
       ITEX_C4880_10,ITEX_C4880_12 : begin
          end ;
       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          end ;
       Andor : begin
          AndorSession.ReadoutSpeed := FReadoutSpeed ;
          end ;
       end ;
     end ;


function TSESCam.GetReadOutTime : Double ;
// -------------------------------
// Get camera frame readout time (s)
// -------------------------------
begin
     // Set frame interval (updates FReadoutTime)
     // If camera is in use latest time
     if not FCameraActive then SetFrameInterval( FFrameInterval ) ;
     Result := FReadoutTime ;
     end ;


procedure TSESCam.SetFrameInterval( Value : Double ) ;
// ---------------------------------
// Set time interval between frames
// ---------------------------------
var
     ReadoutRate : Integer ;
begin

     FFrameInterval := Value ;

     case FCameraType of

       ITEX_CCIR : begin
          // CCIR frame interval is fixed
          FFrameInterval := FFrameIntervalMin ;
          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          if FCameraType = ITEX_C4880_10 then ReadoutRate := FastReadout
                                         else ReadoutRate := SlowReadout ;
       {   C4880_CheckFrameInterval( FFrameLeft,
                                    FFrameTop,
                                    FFrameWidth*FBinFactor,
                                    FFrameHeight*FBinFactor,
                                    FBinFactor,
                                    ReadoutRate,
                                    FFrameInterval,
                                    FReadoutTime ) ;}
          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          PVCAM_CheckFrameInterval( PVCAMSession,
                                    FFrameLeft,
                                    FFrameRight,
                                    FFrameTop,
                                    FFrameBottom,
                                    FBinFactor,
                                    FReadoutSpeed,
                                    FFrameInterval,
                                    FReadoutTime ) ;
          end ;

       PIXELFLY : begin
          PixelFlyCheckFrameInterval( FFrameWidthMax,
                                      FBinFactor,
                                      FTriggerMode,
                                      FFrameInterval,
                                      FReadoutTime ) ;
          end ;

       SensiCam : Begin
          SensiCamCheckFrameInterval( SensicamSession,
                                      FFrameWidthMax,
                                      FBinFactor,
                                      FTriggerMode,
                                      FFrameInterval,
                                      FReadoutTime ) ;
          end ;


       IMAQ_1394 : begin
          IMAQ1394_CheckFrameInterval( Session, FFrameInterval ) ;
          end ;

       ANDOR : begin
          Andor_CheckFrameInterval( AndorSession,
                                    FFrameLeft,
                                    FFrameRight,
                                    FFrameTop,
                                    FFrameBottom,
                                    FBinFactor,
                                    FFrameInterval,
                                    FReadoutTime ) ;
          end ;

       QCAM : begin
          QCAMAPI_CheckROIBoundaries( QCAMSession,
                                      FReadoutSpeed,
                                      FFrameLeft,
                                      FFrameRight,
                                      FFrameTop,
                                      FFrameBottom,
                                      FBinFactor,
                                      FFrameWidth,
                                      FFrameHeight,
                                      FTriggerMode,
                                      FFrameInterval,
                                      FReadoutTime ) ;
          end ;

       DCAM : begin
          DCAMAPI_CheckROIBoundaries( DCAMSession,
                                      FReadoutSpeed,
                                      FFrameLeft,
                                      FFrameRight,
                                      FFrameTop,
                                      FFrameBottom,
                                      FBinFactor,
                                      FFrameWidth,
                                      FFrameHeight,
                                      FFrameInterval,
                                      FReadoutTime ) ;
          end ;

       IMAQ : begin
          IMAQ_CheckFrameInterval( IMAQSession, FFrameInterval ) ;
          end ;

       IMAQDX : begin
          //IMAQDX_CheckFrameInterval( IMAQDXSession, FFrameInterval ) ;
          end ;

       DTOL : begin
          DTOL_CheckFrameInterval( DTOLSession,
                                   FTriggerMode,
                                   FFrameInterval ) ;
          end ;

       end ;
     end ;


procedure TSESCam.SetNumFramesInBuffer( Value : Integer ) ;
// ---------------------------------------------
// Set number of frames in internal image buffer
// ---------------------------------------------
var
     OldValue : Integer ;
begin
     if not FCameraActive then begin
        OldValue := FNumFramesInBuffer ;
        FNumFramesInBuffer := LimitTo( Value, 2, 10000 ) ;
        {if OldValue <> FNumFramesInBuffer then }AllocateFrameBuffer ;
        end ;
     end ;


function TSESCam.GetMaxFramesInBuffer : Integer ;
// -----------------------------------------------------------
// Return max. nunber of frames allowed in camera frame buffer
// -----------------------------------------------------------
var
     NumPixelsPerFrame : Integer ;
begin

     NumPixelsPerFrame := FFrameWidth*FFrameHeight ;

     case FCameraType of

        RS_PVCAM_PENTAMAX : Begin
          // Pentamax has limited buffer size
          Result :=  (4194304 div (NumPixelsPerFrame*FNumBytesPerPixel))-1 ;
          Result := Min( Result, 36) ;
          end ;

        PIXELFLY : begin
          Result := 8 ;
          end ;

        Andor : begin
           Result :=  (20000000 div (NumPixelsPerFrame*FNumBytesPerPixel))-1 ;
           if Result > 36 then Result := 36 ;
           end ;

        RS_PVCAM : begin
           Result :=  (20000000 div (NumPixelsPerFrame*FNumBytesPerPixel))-1 ;
           end ;

        DCAM : begin
           Result :=  (40000000 div (NumPixelsPerFrame*FNumBytesPerPixel))-1 ;
           end ;

        IMAQ : begin
           Result :=  (20000000 div (NumPixelsPerFrame*FNumBytesPerPixel))-1 ;
           end ;

        QCAM : begin
           Result :=  High(QCAMSession.FrameList)+1 ;
           end ;

        DTOL : begin
           Result := DTOLSession.MaxFrames ;
           end ;

        else begin
           Result := 32 ;
           end ;
        end ;
     end ;


function TSESCam.GetPixelWidth : Single ;
// --------------------------------------------------
// Return width of camera pixel (after magnification)
// --------------------------------------------------
begin
     if FLensMagnification > 0.0 then Result := (FPixelWidth*FBinFactor) / FLensMagnification
                                 else Result := FPixelWidth ;
     end ;


function TSESCam.LimitTo(
         Value : Integer ;
         LoLimit : Integer ;
         HiLimit : Integer ) : Integer ;
//
// Constrain <value> to lie within <LoLimit> to <HiLimit> range
// ------------------------------------------------------------
begin
     if Value < LoLimit then Result := LoLimit
                        else Result := Value ;
     if Value > HiLimit then Result := HiLimit
                        else Result := Value ;
     end ;


procedure TSESCam.GetCameraGainList( List : TStrings ) ;
//
// Get list of available camera amplifier gains
//
var
     i : Integer ;
begin
     List.Clear ;
     for i := 0 to CameraGainList.Count-1 do
         List.Add(CameraGainList[i]) ;
     end ;


procedure TSESCam.GetCameraReadoutSpeedList( List : TStrings ) ;
// -------------------------------------------
// Get list of available camera readout speeds
// -------------------------------------------
var
     i : Integer ;
begin

     case FCameraType of
          Andor : Andor_GetCameraReadoutSpeedList( AndorSession, CameraReadoutSpeedList ) ;
          end ;

     List.Clear ;
     for i := 0 to CameraReadoutSpeedList.Count-1 do
         List.Add(CameraReadoutSpeedList[i]) ;

     end ;


procedure TSESCam.GetCameraModeList( List : TStrings ) ;
// -------------------------------------------
// Get list of available camera operating modes
// -------------------------------------------
var
     i : Integer ;
begin
     List.Clear ;
     for i := 0 to CameraModeList.Count-1 do
         List.Add(CameraModeList[i]) ;

     // Ensure list is not empty
     if List.Count < 1 then List.Add(' ') ;

     end ;


procedure TSESCam.GetCameraADCList( List : TStrings ) ;
// -------------------------------------------
// Get list of available camera A/D converters
// -------------------------------------------
var
     i : Integer ;
begin
     List.Clear ;
     for i := 0 to CameraADCList.Count-1 do
         List.Add(CameraADCList[i]) ;

     // Ensure list is not empty
     if List.Count < 1 then List.Add(' ') ;

     end ;


procedure TSESCam.GetCameraInfo( List : TStrings ) ;
// ----------------------
// Get camera information
// ----------------------
var
     i : Integer ;
begin
     List.Clear ;
     for i := 0 to CameraInfo.Count-1 do
         List.Add(CameraInfo[i]) ;
     end ;


function TSESCam.IsLSM( iCameraType : Integer ) : Boolean ;
//
// Return TRUE if supplied camera type is a laser scanning microscope
//
begin

     case iCameraType of
          BioRad,UltimaLSM : Result := True ;
          else Result := False ;
          end ;

     end ;


procedure TSESCam.SetCCDArea( FrameLeft : Integer ;
                              FrameTop : Integer ;
                              FrameRight : Integer ;
                              FrameBottom : Integer ) ;
// ----------------------
// Set CCD imaging region
// ----------------------
begin

    FFrameRight := FrameRight ;
    FFrameLeft := FrameLeft ;
    FFrameTop := FrameTop ;
    FFrameBottom := FrameBottom ;
    ImageAreaChanged := True ;

    end ;


procedure TSESCam.SetTemperature(
          Value : Single
          ) ;
// --------------------------------
// Set camera temperature set point
// --------------------------------
begin


     FTemperatureSetPoint :=  Value ;

     if FCameraActive then Exit ;

     case FCameraType of

       ITEX_CCIR : begin
          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          end ;

       IMAQ_1394 : begin
          end ;

       PIXELFLY : begin
          end ;

       Sensicam : Begin
          end;

       ANDOR : begin
          Andor_SetTemperature( AndorSession, FTemperatureSetPoint ) ;
          end ;

       QCAM : begin
          end ;

       DCAM : begin
          end ;

       IMAQ : begin
          end ;

       IMAQDX : begin
          end ;

       DTOL : begin
          end ;

       end ;
     end ;


procedure TSESCam.SetCameraCoolingOn(
          Value : Boolean
          ) ;
// --------------------------------
// Set camera cooling on/off
// --------------------------------
begin


     FCameraCoolingOn :=  Value ;

     if FCameraActive then Exit ;

     case FCameraType of

       ITEX_CCIR : begin
          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          end ;

       IMAQ_1394 : begin
          end ;

       PIXELFLY : begin
          end ;

       Sensicam : Begin
          end;

       ANDOR : begin
          Andor_SetCooling( AndorSession, Value ) ;
          end ;

       QCAM : begin
          QCAMAPI_SetCooling( QCAMSession, Value ) ;
          end ;

       DCAM : begin
          end ;

       IMAQ : begin
          end ;

       IMAQDX : begin
          end ;

       DTOL : begin
          end ;

       end ;
     end ;


procedure TSESCam.SetCameraFanMode(
          Value : Integer
          ) ;
// --------------------------------
// Set camera fan on/off
// --------------------------------
begin

     FCameraFanMode :=  Value ;

     if FCameraActive then Exit ;

     case FCameraType of

       ITEX_CCIR : begin
          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          end ;

       IMAQ_1394 : begin
          end ;

       PIXELFLY : begin
          end ;

       Sensicam : Begin
          end;

       ANDOR : begin
          Andor_SetFanMode( AndorSession, FCameraFanMode ) ;
          end ;

       QCAM : begin
          end ;

       DCAM : begin
          end ;

       IMAQ : begin
          end ;

       IMAQDX : begin
          end ;

       DTOL : begin
          end ;

       end ;
     end ;


procedure TSESCam.SetDisableEMCCD(
          Value : Boolean
          ) ;
// --------------------------------
// Enable/disable EMCDD function
// --------------------------------
var
    AmpType : Integer ;
begin

     FDisableEMCCD := Value ;
     FCameraRestartRequired := True ;

     if FCameraActive then Exit ;

     case FCameraType of

       ITEX_CCIR : begin
          end ;

       ITEX_C4880_10,ITEX_C4880_12 : begin
          end ;

       RS_PVCAM,RS_PVCAM_PENTAMAX : begin
          end ;

       IMAQ_1394 : begin
          end ;

       PIXELFLY : begin
          end ;

       Sensicam : Begin
          end;

       ANDOR : begin
          if FDisableEMCCD then AmpType := 1
                           else AmpType := 0 ;
          //Andor_SetOutputAmplifier( AndorSession, AmpType ) ;
          AndorSession.DisableEMCCD := FDisableEMCCD ;
          end ;

       QCAM : begin
          end ;

       DCAM : begin
          end ;

       IMAQ : begin
          end ;

       IMAQDX : begin
          end ;

       DTOL : begin
          end ;

       end ;
     end ;


procedure TSESCam.SetCameraMode( Value : Integer ) ;
// ---------------------
// Set camera video mode
// ---------------------
begin

     FCameraMode := Value ;

     case FCameraType of
       IMAQDX : begin
          IMAQDX_SetVideoMode( IMAQDXSession,
          Value,
          FCameraADC,
          FFrameWidthMax,
          FFrameHeightMax,
          FNumBytesPerPixel,
          FPixelDepth,
          FGreyLevelMin,
          FGreyLevelMax ) ;
          FFrameWidth := FFrameWidthMax ;
          FFrameHeight := FFrameHeightMax ;
          FFrameLeft := 0 ;
          FFrameTop := 0 ;
          end ;

       ANDOR : begin
         Andor_SetCameraMode( AndorSession, FCameraMode ) ;
         end ;
       end ;

    end ;


procedure TSESCam.SetCameraADC( Value : Integer ) ;
// ------------------------
// Set camera A/D converter
// ------------------------
begin

     FCameraADC := Value ;

     case FCameraType of

       ANDOR : begin
         Andor_SetCameraADC( AndorSession,
                             FCameraADC,
                             FPixelDepth,
                             FGreyLevelMin,
                             FGreyLevelMax ) ;
         end ;
       end ;

    end ;



end.
