unit SensiCamUnit;
// -----------------------------------------------
// PCO SensiCam cameras
// -----------------------------------------------
// 14 Sept. 2007 Started by Matthias Ascherl from TILL-Photonics,
// based on the PixelFly-Unit
// 22.05.08 Modified by J. Dempster to work with Gregor Zupancic's Sensicam in ext. trigger mode
//          Trigger is now active low (active high didn't work)
//          2 x readout time subtracted from exposure to ensure exposure is
//          completed before next frame trigger
// 21/01/09 AdditionalReadoutTime added to StartCapture
// 21/05/09 JD X8 bin factor added, SensiCam_CheckBinFactor procedure added


interface

uses WinTypes,sysutils, classes, dialogs, mmsystem ;

const
    MaxSensiCamBuffers = 16 ;
    SensiCamSlowExposureTime = 0.25 ;

type

TSensiCamSession = record
    BufNum           : Array[0..MaxSensiCamBuffers-1] of Integer ;
    BufSize          : Array[0..MaxSensiCamBuffers-1] of Integer ;
    PBuffer          : Array[0..MaxSensiCamBuffers-1] of Pointer ;
    NumBytesPerFrame : Integer ;
    NumFrames        : Integer ;
    PFrameBuffer     : Pointer ;
    BitsPerPixel     : Integer ;
    GetImageInUse    : Boolean ;
    CapturingImages  : Boolean ;
    CameraOpen       : Boolean ;
    NumBuffers       : Integer ;
    TriggerMode      : Integer ;
    ExposureTime     : Single ;
    FrameCounter     : Integer ;
    TimerProcInUse   : Boolean ;
    TimerID          : Integer ;
    end ;


PSensiCamSession = ^TSensiCamSession ;

TSet_Board  = function ( boardnr : integer) : integer; stdcall;
//set the current board to work with
//after selecting a board the first time, call SET_INIT(1..2) to initialize it
//boardnr: 0..9 selects PCI-Board set

TSet_Init   = function ( mode : integer) : integer; stdcall;
//resets or initialize the PCI-Board, the camera and all global values of the dll
//mode=0 : reset
//         frees memory
//         close dialog boxes
//         SET_INIT(0) should be called before you close your program

//mode=1 : init default
//mode=2 : init with values of registry (HKEY_CURRENT_USER\\software\\PCO\\Camera Settings

TGet_Status = function ( var camtype, eletemp, ccdtemp : integer) : integer; stdcall;
//reads out the connected camera LONG or FAST
//and the electronic and CCD temperature in °C
//version>3.21
//if camera with analog gain switch (*camtyp>>16)&0x0F == 0x01

TSet_COC    = function ( mode, trig,
                         roixmin, roixmax, roiymin, roiymax,
                         hbin, vbin : integer;
                         timevalues : pointer ): integer; stdCall;

// build an COC and load it into the camera
// mode = (typ&0xFFFF)+subtyp<<16
//version>3.21 and valid camera connected
// mode = (typ&0xFFFFFF)+subtyp<<16+gain<<8

// typ=0    : set LONG EXPOSURE camera (if camtyp=FAST return error WRONGVAL)
// subtyp=0 : sequential mode, busy out
// subtyp=1 : simultaneous mode, busy out
// subtyp=2 : sequential mode, busy out, exposure out
// subtyp=3 : simultaneous mode, exposure out

// typ=1    : set FAST SHUTTER camera  (if camtyp=LONG return error WRONGVAL)
// subtyp=0 : standard fast
// subtyp=1 : double fast, only for doubleshutter cameras, else returns WRONGVAL
// subtyp=2 : double long, only for doubleshutter cameras, else returns WRONGVAL
// subtyp=5 : fast shutter cycle mode

// gain=0   : normal analog gain
// gain=1   : extended analog gain

// trig=0 : continuos software triggering
// trig=1 : external trigger raising edge
// trig=2 : external trigger falling edge

// roi... : values for area of interest, 32x32pixel quadrants
//    x   : range 1 to 40 (20)
//    y   : range 1 to 32 (15)

// hbin   : horizontal binning (1,2,4,8)
// vbin   : vertical binning (1,2,4,8,16,32)

// timevalues : Null terminated ASCII string
//              delay0,exposure0,delay0,exposur1 ... -1,-1
//              The pair -1,-1 must be last of the table
//              The LONG camera expects only one pair of timevalues
//              DOUBLE and DOUBLE LONG have no timevalues
//              FAST can have up to 100 pairs of timevalues
//              see SDK-manual for exact description
// changing the values of roi..., hbin and vbin changes also the size
// of the picture, which is send from the camera

TRun_COC    = function ( mode : integer): integer; stdCall;

TTest_COC   = function ( var mode, trig, roix1, roix2, roiy1, roiy2, hbin, vbin : integer;  COCTable : Pointer; var len : integer) : integer; stdcall;

TGet_Settings = function (var mode, trig, roix1, roix2, roiy1, roiy2, hbin, vbin :integer; var  table :Pointer{; var len : integer}) : integer; stdcall;

TStop_COC   = function ( mode : integer ): integer; stdCall;

TGet_Image_Status = function ( var status : integer ): integer; stdCall;
// reads out the status of the PCI-Buffer process
// *status Bit0 = 0 : no read image process is running
//                1 : read image process is running
//         Bit1 = 0 : 1 or 2 pictures are in PCI-Buffer
//                1 : no picture is in PCI-BUFFER
//         Bit2 = 0 : camera is idle, no exposure is running
//                1 : camera is busy, exposure is running or a picture
//                    is send from the camera to the PCI-Buffer

TGet_Image_Size = function ( var Image_width, Image_height : Integer): integer; stdcall;

TRead_Image_12Bit = function ( mode, width, height: integer; PictBuffer : Pointer): integer; stdcall;

TGet_CCD_Size  = function ( var value : integer) : integer; stdcall;

TGet_COCTime = function : single; stdcall;

TGet_BELTime = function : single; stdcall;

TGet_EXPTime = function : single; stdcall;

TGet_DELTime = function: single; stdcall;

TGet_Camera_CCD = function (board : integer; var ccdtype : integer) : integer; stdcall;

TClear_Board_Buffer = function (board : integer) : integer; stdcall;

TEnable_Message_Log = function (level : integer ; FileName  : PChar) : integer; stdcall;

// Externally called functions

procedure SensiCam_LoadLibrary  ;

function  SensiCam_GetDLLAddress(
          Handle : Integer ;
          const ProcName : string ) : Pointer ;

function  SensiCam_OpenCamera(
          var Session : TSensiCamSession ;
          var FrameWidthMax : Integer ;
          var FrameHeightMax : Integer ;
          var NumBytesPerPixel : Integer ;
          var PixelDepth : Integer ;
          var PixelWidth : Single ;
          CameraInfo : TStringList
          ) : Boolean ;

procedure SensiCam_CloseCamera(
          var Session : TSensiCamSession
          ) ;

procedure SensiCam_GetCameraGainList(
          CameraGainList : TStringList
          ) ;

function SensiCam_StartCapture(
         var Session : TSensiCamSession ;
         var ExposureTime : Double ;
         AdditionalReadoutTime : Double ;
         AmpGain : Integer ;
         ExternalTrigger : Integer ;
         FrameLeft : Integer ;
         FrameTop : Integer ;
         FrameWidth : Integer ;
         FrameHeight : Integer ;
         BinFactor : Integer ;
         PFrameBuffer : Pointer ;
         NumFramesInBuffer : Integer ;
         NumBytesPerFrame : Integer
         ) : Boolean ;

procedure SensiCam_TimerProc(
          uID,uMsg : SmallInt ;
          Session : PSensiCamSession ;
          dw1,dw2 : LongInt ) ; stdcall ;

procedure SensiCam_GetImageFast(
          var Session : TSensiCamSession
          ) ;

procedure SensiCam_StopCapture(
         var Session : TSensiCamSession
          ) ;

procedure SensiCamCheckFrameInterval( var Session : TSensiCamSession;   // Camera session record
                                      FrameWidthMax : Integer ;
                                      BinFactor : Integer ;
                                      TriggerMode : Integer ;
                                      var FrameInterval : Double ;
                                      var ReadoutTime : Double ) ;

procedure SensiCam_CheckBinFactor(
          var BinFactor : Integer ) ;

procedure SensiCam_CheckError(
          FuncName : String ;
          ErrNum : Integer
          ) ;


var

  SET_INIT           : TSet_init ;
  GET_Status         : TGet_Status ;
  GET_CCD_SIZE       : TGet_CCD_SIZE ;
  GET_IMAGE_SIZE     : TGET_IMAGE_SIZE;
  RUN_COC            : TRun_COC;
  STOP_COC           : TSTOP_COC;
  TEST_COC           : TTEST_COC;  
  SET_COC            : TSET_COC;
  GET_SETTINGS       : TGET_SETTINGS;
  GET_COCTime        : TGET_COCTime;
  Get_ExpTime        : TGet_ExpTime;
  Get_BelTime        : TGet_BelTime;
  Get_DelTime        : TGet_DelTime;
  GET_CAMERA_CCD     : TGET_Camera_CCD;
  GET_IMAGE_STATUS   : TGET_IMAGE_STATUS;
  READ_IMAGE_12BIT   : TREAD_IMAGE_12BIT;
  Clear_Board_Buffer : TClear_Board_Buffer;
  Enable_Message_Log : TEnable_Message_Log ;
implementation

uses sescam ;

const
  HW_TRIGGER = 1 ;
  SW_TRIGGER = 0 ;

  VBIN_1X = 1 ;
  VBIN_2X = 2 ;
  VBIN_4X = 4 ;
  VBIN_8X = 8 ;

  //defines for hbin setting
  HBIN_1X = 1 ;
  HBIN_2X = 2 ;
  HBIN_4X = 4 ;
  HBIN_8X = 8 ;


var
    LibraryHnd    : THandle ;         // SENNTCAM.DLL library handle
    LibraryLoaded : boolean ;      // SENNTCAM.DLL library loaded flag
    ProcNum       : Integer ;

    CameraCCDType : integer;       // save cameratype on camera_open
    COCPos        : Integer;       // current position in the COC list
    COCList       : Array of byte; // COC list, holds the current COC



procedure WriteToCOCList(textstring : string);
var i : integer;
begin
  for i := 1 to length(textstring) do
  begin
    COCList[COCPos] := ord(textstring[i]);
    inc(cocpos);
  end;
end;


procedure ClearCOCList;
begin
  FillChar(COCList[0],Length(COCList),0); // clear the list with zeros
end;


procedure MakeCOCList(textstring:string);
begin
  COCPos := 0;
  ClearCOCList;
  WriteToCOCList(TextString);
end;


procedure SensiCam_LoadLibrary  ;
{ -------------------------------------
  Load SENNTCAM.DLL library into memory
  -------------------------------------}
var
    LibFileName : string ;
begin

     { Load SENNTCAM interface DLL library }
     LibFileName := 'SENNTCAM.DLL' ;          // only NT-based systems; no check if we are running win 9x
     LibraryHnd := LoadLibrary( PChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin

        @SET_INIT := SensiCam_GetDLLAddress(LibraryHnd,'SET_INIT') ;
        @GET_STATUS := SensiCam_GetDLLAddress(LibraryHnd,'GET_STATUS') ;
        @SET_COC := SensiCam_GetDLLAddress(LibraryHnd,'SET_COC') ;
        @RUN_COC := SensiCam_GetDLLAddress(LibraryHnd,'RUN_COC') ;
        @STOP_COC := SensiCam_GetDLLAddress(LibraryHnd,'STOP_COC') ;
        @TEST_COC := SensiCam_GetDLLAddress(LibraryHnd,'TEST_COC') ;
        @GET_CAMERA_CCD := SensiCam_GetDLLAddress(LibraryHnd,'GET_CAMERA_CCD') ;
        @GET_CCD_SIZE := SensiCam_GetDLLAddress(LibraryHnd,'GET_CCD_SIZE') ;
        @GET_IMAGE_SIZE := SensiCam_GetDLLAddress(LibraryHnd,'GET_IMAGE_SIZE') ;
        @GET_CAMERA_CCD := SensiCam_GetDLLAddress(LibraryHnd,'GET_CAMERA_CCD');
        @GET_IMAGE_STATUS := SensiCam_GetDLLAddress(LibraryHnd,'GET_IMAGE_STATUS');
        @READ_IMAGE_12BIT := SensiCam_GetDLLAddress(LibraryHnd,'READ_IMAGE_12BIT');
        @Clear_Board_Buffer := SensiCam_GetDLLAddress(LibraryHnd,'CLEAR_BOARD_BUFFER');
        @GET_COCTime  := SensiCam_GetDLLAddress(LibraryHnd,'GET_COCTIME');
        @GET_SETTINGS  := SensiCam_GetDLLAddress(LibraryHnd,'GET_SETTINGS');
        @GET_BelTime  := SensiCam_GetDLLAddress(LibraryHnd,'GET_BELTIME');
        @GET_ExpTime  := SensiCam_GetDLLAddress(LibraryHnd,'GET_EXPTIME');
        @GET_DELTime  := SensiCam_GetDLLAddress(LibraryHnd,'GET_DELTIME');
        @Enable_Message_Log := SensiCam_GetDLLAddress(LibraryHnd,'ENABLE_MESSAGE_LOG');
        LibraryLoaded := True ;
        end
     else begin
          MessageDlg( 'SensiCam: ' + LibFileName + ' not found!', mtWarning, [mbOK], 0 ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function SensiCam_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within SENNTCAM.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('SENNTCAM.DLL: ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
    end ;


function SensiCam_OpenCamera(
          var Session : TSensiCamSession ;   // Camera session record
          var FrameWidthMax : Integer ;      // Returns camera frame width
          var FrameHeightMax : Integer ;     // Returns camera height width
          var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
          var PixelDepth : Integer ;         // Returns no. bits/pixel
          var PixelWidth : Single ;          // Returns pixel size (um)
          CameraInfo : TStringList           // Returns Camera details
          ) : Boolean ;
// ---------------------
// Open SensiCam camera
// ---------------------
var
    Err            : Integer ;
    i              : Integer ;
    CCDTemperature : Integer ;
    ActualXSize    : Integer ;
    ActualYSize    : Integer ;

begin

     Result := False ;

     // Load DLL libray
     if not LibraryLoaded then SensiCam_LoadLibrary  ;
     if not LibraryLoaded then Exit ;

     // Initialise board and camera
     Err := Set_Init(1) ; // for now we assume that there is only one board installed
     SensiCam_CheckError( 'SET_INIT', Err ) ;
     if Err <> 0 then Exit ;

     CameraInfo.Add('PCO SensiCam') ;

     Err := Get_CCD_SIZE( i );
     Case i of
        307200 : begin        // VGA
                   CameraCCDType := 1;  //bw VGA
                   CameraInfo.Add('VGA')
                 end;
       1310720 : begin        // SVGA
                   CameraCCDType := 2;  //bw SVGA
                   CameraInfo.Add('SVGA')
                 end;
       1431040 : begin        // QE
                   CameraCCDType := 17;  //bw QE
                   CameraInfo.Add('QE')
                 end;
       1006008 : begin        // EM?!
                   CameraCCDType := 32;  //bw EM
                   CameraInfo.Add('EM')
                 end;
     end;

     // Get the actual dimensions
     Err := Get_Image_Size ( ActualXSize, ActualYSize );
     SensiCam_CheckError( 'GETSIZES', Err ) ;

     Session.BitsPerPixel := 12;         // currently we only do 12bit depth
     PixelDepth := Session.BitsPerPixel ;
     NumBytesPerPixel := 2;

     FrameWidthMax := ActualXSize ;
     FrameHeightMax := ActualYSize ;

     // Pixel size (um)
     if FrameWidthMax = 640 then PixelWidth := 9.9        // VGA
     else if FrameWidthMax = 1280 then PixelWidth := 6.7  // SVGA
     else if FrameWidthMax = 1004 then PixelWidth := 8.0  // EM
     else if FrameWidthMax = 1392 then PixelWidth := 6.45 // QE
     else PixelWidth := 1.0 ;

     CameraInfo.Add(format('Frame: %d x %d pixels',[FrameWidthMax,FrameHeightMax])) ;
     CameraInfo.Add(format('Pixel width: %.3f um',[PixelWidth])) ;
     CameraInfo.Add(format('Pixel depth: %d bits',[PixelDepth])) ;

     //get the CCD temperature
     Err := GET_Status( i, i, CCDTemperature ) ; // we just want the ccd-temp
     SensiCam_CheckError( 'READTEMPERATURE', Err ) ;

     CameraInfo.Add(format('CCD Temperature: %d',[CCDTemperature])) ;

     Session.GetImageInUse := False ;
     Session.CapturingImages := False ;

     Session.CameraOpen := True ;
     Result := Session.CameraOpen ;


     Session.TimerID := -1 ;
     Session.TimerProcInUse := False ;

     ProcNum := 0 ;
     SetLength(COClist,500);  //COC List mit 500 bytes allokieren

//     SensiCam_CheckError( 'Enable_Message_Log (start)',
//                          Enable_Message_Log( $3F, PChar('sensicam log.txt'))) ;

     end ;


procedure SensiCam_CloseCamera(
          var Session : TSensiCamSession // Session record
          ) ;
// ----------------
// Shut down camera
// ----------------
var
    Err : Integer ;

begin

    if Session.CameraOpen then begin

       // Stop camera
       if Session.CapturingImages then begin

          SensiCam_CheckError( 'STOP_CAMERA',
                               STOP_COC( 0 ) ) ;
          end ;

//          SensiCam_CheckError( 'Enable_Message_Log (stop)',
//                                Enable_Message_Log( $0, PChar('sensicam log.txt')))
                                 ;

       // Close camera
       SensiCam_CheckError( 'CLOSEBOARD',
                            Set_Init( 0 ) ) ;

       FreeLibrary (LibraryHnd);
       // Stop timer (if still running)
       if Session.TimerID >= 0 then begin
          timeKillEvent( Session.TimerID ) ;
          Session.TimerID := -1 ;
          end ;

       end ;

    Session.GetImageInUse := False ;
    Session.CameraOpen := False ;
    Session.CapturingImages := False ;
    CameraCCDType := -1;  //no camera
    COCList := nil;
    end ;


procedure SensiCam_GetCameraGainList(
          CameraGainList : TStringList
          ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
begin
   If CameraCCDType = 17 then begin  // only the QE gains are supported (VGA doesn't have a gain mode)
     CameraGainList.Add( ' normal ' ) ;
     CameraGainList.Add( ' extended analog gain' ) ;
     CameraGainList.Add( ' Low light mode' ) ;     
   end;
  end ;


function SensiCam_StartCapture(
         var Session : TSensiCamSession ;   // Camera session record
         var ExposureTime : Double ;      // Frame exposure time    (in seconds)
         AdditionalReadoutTime : Double ; // Additional readout time (s)
         AmpGain : Integer ;              // Camera amplifier gain index
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4)
         PFrameBuffer : Pointer ;         // Pointer to start of  buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer       // No. of bytes/frame
         ) : Boolean ;
// -------------------
// Start frame capture
// -------------------
const
    TimerTickInterval = 10; //20 ; // Timer tick resolution (ms)

var
    Err               : Integer ;
    i                 : Integer ;
    trig              : Integer;
    Mode              : Integer ;
    HBin              : Integer ;
    VBin              : Integer ;
    width,height      : integer;
    CamStatus         : Integer;
    ReadoutTime,
    rot               : Double ;

begin
     // Disable timer if it is running
     if Session.TimerID >= 0 then begin
       timeKillEvent( Session.TimerID ) ;
       Session.TimerID := -1 ;
       end ;

     // clear grabber memory and stop camera
     err := STOP_COC(0);
     SensiCam_CheckError( 'StartCamera:STOP_COC', err );

     // Pixel binning factor (X1 or X2)
     if BinFactor = 2 then begin
        HBin := HBIN_2X ;
        VBin := VBIN_2X ;
        end
     else if BinFactor = 4 then begin
        HBin := HBIN_4X ;
        VBin := VBIN_4X ;
        end
     else if BinFactor = 8 then begin
        HBin := HBIN_8X ;
        VBin := VBIN_8X ;
        end
     else begin
        HBin := HBIN_1X ;
        VBin := VBIN_1X ;
        end ;

     // calculate readout time (in ms)
     ReadoutTime := 62 ;
     Case CameraCCDType of
        1  :  case vBin of
             1   : ReadoutTime := 38 ; //VGA; Readout time full chip divided vbinning (in milliseconds)
             2,4,8 : ReadoutTime := 20 ; // binning 4 doesn't gain speed over 2x bin
           end;
    17  :  case binfactor of
             1   : ReadoutTime := 110 ; //QE; Readout time full chip divided vbinning (in milliseconds)
             2,4,8 : ReadoutTime := 55 ; // binning 4 doesn't gain speed over 2x bin
              end;
       32  : begin end;  //EM
        2  : begin end;  //SVGA
     end;
     ReadoutTime := 62 ;
     Mode := 0;         // LongExposure, normal gain, sequential (non overlapped), busy out

     if cameraCCDType = 17 then   // if it's a QE check what Gain mode is set
       Case AmpGain of
          0 : Mode := 0;        // normal Gain + LongExposure, sequential (non overlapped), busy out
          1 : Mode := 1 * 256;  // extended analog gain + LongExposure, sequential (non overlapped), busy out
          2 : Mode := 3 * 256;  // Low Light mode + LongExposure, sequential (non overlapped), busy out
       end;

     // Internal/external triggering of frame capture
     if ExternalTrigger = CamFreeRun then begin
        // Exposure triggered internally at timed intervals
        trig := 0;          // trigger each frame with software
        // Exposure time in ms
        Session.NumBuffers := 8;
        Session.TriggerMode := camFreeRun;
        Session.ExposureTime := Round(( ExposureTime * 1000 ) - ReadoutTime );
        end
     else begin
        // Exposure triggered externally via TTL pulses
        trig := 2;          // trigger each frame with external falling edge
                            // Changed from rising edge because this didn't
                            // work with Gregor Zupancic's Sensicam
        // Exposure time in ms
        Session.NumBuffers := 16;
        Session.TriggerMode := CamExtTrigger ;
        Session.ExposureTime := Round(( (ExposureTime - AdditionalReadoutTime)* 1000 )
                                      - 2*ReadoutTime - 1 );
        // Exposure reduced by 2 readout times to ensure exposure + readout is less
        // than frame trigger interval
        end;
     //safety check
     if Session.ExposureTime < 1 then Session.ExposureTime := 1;

     // built the text string for the camera control operation code (COC)
     MakeCOCList( '0,' + FloatToStr(Session.ExposureTime) + ',-1,-1' );

     // Set camera parameters depending on the camera model
     Case CameraCCDType of
        1  : err := Set_COC (Mode, Trig ,1, 20, 1, 15, hbin, vbin, COCList);  //VGA
       17  : err := Set_COC (Mode, Trig ,1, 43, 1, 33, hbin, vbin, COCList);  //QE
       32  : err := Set_COC (Mode, Trig ,1, 32, 1, 33, hbin, vbin, COCList);  //EM
        2  : err := Set_COC (Mode, Trig ,1, 40, 1, 32, hbin, vbin, COCList);  //SVGA
     end;
     SensiCam_CheckError( 'StartCamera:SET_COC', Err );

     if Err <> 0 then Exit ;

     // Setup SensiCam camera buffer
     Session.NumBytesPerFrame := NumBytesPerFrame ;
     Session.NumFrames := NumFramesInBuffer ;
     Session.PFrameBuffer := PFrameBuffer ;
     Session.FrameCounter := 0 ;

     for i := 0 to Session.NumBuffers - 1 do begin

       // Allocate buffer
       Session.BufNum[i] := -1 ;
       Session.BufSize[i] := NumBytesPerFrame ;
       end;

     // Start frame acquisition monitor procedure
     Session.TimerProcInUse := False ;
     Session.TimerID := TimeSetEvent( TimerTickInterval,
                                      TimerTickInterval,
                                      @SensiCam_TimerProc,
                                      Cardinal(@Session),
                                      TIME_PERIODIC );

     // start camera; continuous mode/frames (0) or single mode/frame (4)
     Err := RUN_COC( 0 );
     SensiCam_CheckError( 'RUN_COC', Err );

     Session.CapturingImages := True ;

     Result := True ;

     end;


procedure SensiCam_TimerProc(
          uID,uMsg : SmallInt ;
          Session : PSensiCamSession ;
          dw1,dw2 : LongInt ) ; stdcall ;
{ ----------------------------------------------
  Timer scheduled events, called a 10ms intervals
  ---------------------------------------------- }
var
    Err : Integer ;

begin

    if Session^.TimerProcInUse then Exit ;
    Session^.TimerProcInUse := True ;

    SensiCam_GetImageFast (Session^);

    Session^.TimerProcInUse := False ;
    end ;



procedure SensiCam_GetImageFast(
          var Session : TSensiCamSession // Camera session record
          ) ;
// -------------------------------------------------------------------------
// Transfer images from camera buffer into main frame buffer
// (Free run trigger mode and external trigger mode for short exposure times
// -------------------------------------------------------------------------
var
    Err          : Integer ;
    width,height : Integer ;
    CamStatus    : Integer;

begin

    if Session.GetImageInUse or (not Session.CapturingImages) then Exit ;
    Session.GetImageInUse := true ;

    // get image status; is image already in buffer
    err := Get_Image_Status ( Camstatus ) ;
    SensiCam_CheckError( 'GetImageFast: GET_IMAGE_STATUS', Err ) ;

    // if no Image available then exit
    if (Camstatus and 2 <> 0) and (Camstatus and 1 <> 0) then begin
      Session.GetImageInUse := false ;
      exit;
    end;

    // get the current image size
    err := Get_Image_Size(width, height);
    SensiCam_CheckError( 'GetImageFast: GET_IMAGE_SIZE', Err ) ;
    if err <> 0 then begin
      Session.GetImageInUse := false ;
      exit;
    end;

    // transfer the image(s) form the grabber to main memory
    Repeat
      err := Read_Image_12Bit(0, width, height,
                              Pointer( Integer(Session.PFrameBuffer) +
                              Session.FrameCounter * Session.NumBytesPerFrame ));

      if err = 0 then begin
        Inc(Session.FrameCounter) ;
        if Session.FrameCounter >= Session.NumFrames then Session.FrameCounter := 0;
      end;

    until err <> 0 ;  // read all frames that are on the grabber board; err = 100 (<> 0) -> no image available

    Session.GetImageInUse := False ;
    end ;



procedure SensiCam_StopCapture(
          var Session : TSensiCamSession   // Camera session record
          ) ;
// ------------------
// Stop frame capture
// ------------------
var
    Err : Integer ;
    BufStatus : Integer ;
begin

     if not Session.CapturingImages then Exit ;

     // Stop frame capture
     SensiCam_CheckError( 'STOP_CAMERA',
                          STOP_COC( 0 ) ) ;  // this command stops the camera and also clears all buffers on then grabber
     Session.CapturingImages := False ;
     Session.GetImageInUse := False ;
  end;


procedure SensiCamCheckFrameInterval( var Session : TSensiCamSession;   // Camera session record
                                      FrameWidthMax : Integer ;
                                      BinFactor : Integer ;
                                      TriggerMode : Integer ;
                                      var FrameInterval : Double ;     // in seconds
                                      var ReadoutTime : Double ) ;     // in seconds
// -----------------------
// Return CCD readout time
// -----------------------

var
    err : integer;
begin

 // SensiCam_CheckError( 'CheckFrameInterval: FrameInterval ' + FloatToStr(FrameInterval), 999 ) ;
  Case CameraCCDType of
     1  :  case binfactor of
             1   : ReadoutTime := 0.038 ; //VGA; Readout time full chip divided vbinning (in milliseconds)
             2,4,8 : ReadoutTime := 0.020 ; // binning 4 doesn't gain speed over 2x bin
           end;
    17  :  case binfactor of
             1   : ReadoutTime := 0.110 ; //QE; Readout time full chip divided vbinning (in milliseconds)
             2,4,8 : ReadoutTime := 0.055 ; // binning 4 doesn't gain speed over 2x bin
           end;
    32  : begin end;  //EM
     2  : begin end;  //SVGA
  end;

  if FrameInterval < ReadoutTime then FrameInterval := ReadoutTime;

  end ;


procedure SensiCam_CheckBinFactor(
          var BinFactor : Integer
          ) ;
// --------------------------------
// Limit bin factor to valid values
// --------------------------------
begin
    case BinFactor of
         3 : BinFactor := 2 ;
         5,6,7 : BinFactor := 4 ;
         end ;
    end ;


procedure SensiCam_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;
// ------------
// Report error
// ------------
var
    Report : string ;
begin

    if ErrNum = 0 then Exit ;

    Case ErrNum of
      -1 : Report := 'initialization failed; no camera connected';
      -2 : Report := 'timeout in any function';
      -3 : Report := 'function call with wrong parameter';
      -4 : Report := 'cannot locate PCI card or card driver';
      -5 : Report := 'cannot allocate DMA buffer';
      -6 : Report := 'reserved';
      -7 : Report :='DMA timeout';
      -8 : Report :='invalid camera mode';
      -9 : Report :='no driver installed';
      -10 : Report :='no PCI bios found';
      -11 : Report :='device is hold by another process';
      -12 : Report :='error in reading or writing data to board';
      -13 : Report :='wrong driver function';
      -20 : Report :='LOAD_COC error (camera runs program memory)';
      -21 : Report :='too many values in COC';
      -22 : Report :='CCD temperature or electronics temperature out of range';
      -23 : Report :='buffer allocate error';
      -24 : Report :='READ_IMAGE error';
      -25 : Report :='set/reset buffer flags is failed';
      -26 : Report :='buffer is used';
      -27 : Report :='call to a Macintosh function is failed';
      -28 : Report :='DMA error';
      -29 : Report :='cannot open file';
      -30 : Report :='registry error';
      -31 : Report :='open dialog error';
      -32 : Report := 'needs newer called vxd or dll';
      // warnings
      100 : Report := 'no image in PCI buffer';
      101 : Report := 'picture too dark';
      102 : Report := 'picture too bright';
      103 : Report := 'one or more values changed';
      104 : Report := 'buffer for builded string too short';

      else Report := '' ;
      end ;

    MessageDlg( format( 'SensiCam: %s (%d) %s',
                        [FuncName,ErrNum,Report] ),
                mtWarning, [mbOK], 0 ) ;

    end ;


end.
