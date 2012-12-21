unit PixelFlyUnit;
// -----------------------------------------------
// PCO PixelFly cameras
// -----------------------------------------------
// 23-6-4 Started
// 30-8-4 External Trigger mode now working correctly
// 2-9-4 Slow (>250ms) exposure mode added
// 21/01/09 AdditionalReadoutTime added to StartCapture


interface

uses WinTypes,sysutils, classes, dialogs, mmsystem ;

const
    MaxPixelFlyBuffers = 16 ;
    PixelflySlowExposureTime = 0.25 ;

type

TPixelFlySession = record
    Handle : Integer ;
    BufNum : Array[0..MaxPixelFlyBuffers-1] of Integer ;
    BufSize : Array[0..MaxPixelFlyBuffers-1] of Integer ;
    PBuffer : Array[0..MaxPixelFlyBuffers-1] of Pointer ;
    BitsPerPixel : Integer ;
    GetImageInUse : Boolean ;
    CameraOpen : Boolean ;
    CapturingImages : Boolean ;
    OldestUnReadBuf : Integer ;
    NumBuffers : Integer ;
    TriggerMode : Integer ;
    ExposureTime : Single ;
    NumBytesPerFrame : Integer ;
    NumFrames : Integer ;
    PFrameBuffer : Pointer ;
    FrameCounter : Integer ;
    TimerProcInUse : Boolean ;
    TimerID : Integer ;
    end ;
PPixelFlySession = ^TPixelFlySession ;

TPIXELFLY_INITBOARD = function(
             Board : Integer ;
             var Handle : Integer ) : Integer ; cdecl ;

TPIXELFLY_INITBOARDP = function(
             Board : Integer ;
             var Handle : Integer ) : Integer ; cdecl ;


TPIXELFLY_CLOSEBOARD = function(
              var Handle : Integer ) : Integer ; {cdecl} cdecl ;

TPIXELFLY_RESETBOARD = function(
              Handle : Integer) : Integer ; cdecl ;


TPIXELFLY_GETBOARDPAR = function(
               Handle : Integer ;
               var Buf : Array of Char ;
               Len : Integer ) : Integer ; cdecl ;


TPIXELFLY_SETMODE = function(
           Handle : Integer ;
           mode : Integer ;
           explevel : Integer ;
           exptime : Integer ;
           hbin : Integer ;
           vbin : Integer ;
           gain : Integer ;
           offset : Integer ;
           bit_pix : Integer ;
           shift  : Integer
           ) : Integer ; cdecl ;

TPIXELFLY_WRRDORION = function(
             Handle : Integer ;
             cmnd : Integer ;
             var Data : Integer
             ) : Integer ; cdecl ;

TPIXELFLY_SET_EXPOSURE = function(
                Handle : Integer ;
                Time : Integer
                ) : Integer ; cdecl ;


TPIXELFLY_TRIGGER_CAMERA = function(
                  Handle : Integer) : Integer ; cdecl ;

TPIXELFLY_START_CAMERA = function(
                Handle : Integer
                ) : Integer ; cdecl ;

TPIXELFLY_STOP_CAMERA = function(
                Handle : Integer
                ) : Integer ; cdecl ;

TPIXELFLY_GETSIZES = function(
            Handle : Integer ;
            var ccdxsize : Integer ;
            var ccdysize : Integer ;
            var actualxsize : Integer ;
            var actualysize : Integer ;
            var bit_pix : Integer
            ) : Integer ; cdecl ;


TPIXELFLY_READTEMPERATURE = function(
                   Handle : Integer ;
                   var ccd : Integer
                   ) : Integer ; cdecl ;


TPIXELFLY_READVERSION = function(
               Handle : Integer ;
               typ : Integer ;
               var Vers : Array of Char ;
               len : Integer
               ) : Integer ; cdecl ;


TPIXELFLY_GETBUFFER_STATUS = function(
                    Handle : Integer ;
                    bufnr : Integer ;
                    mode : Integer ;
                    var stat : Integer ;
                    len : Integer
                    ) : Integer ; cdecl ;

TPIXELFLY_ADD_BUFFER_TO_LIST = function(
                      Handle : Integer ;
                      bufnr : Integer ;
                      size : Integer ;
                      offset : Integer ;
                      data : Integer
                      ) : Integer ; cdecl ;


TPIXELFLY_REMOVE_BUFFER_FROM_LIST = function(
                           Handle : Integer ;
                           bufnr  : Integer
                           ) : Integer ; cdecl ;


TPIXELFLY_ALLOCATE_BUFFER = function(
                   Handle : Integer ;
                   var bufnr : Integer ;
                   var size  : Integer
                   ) : Integer ; cdecl ;


TPIXELFLY_FREE_BUFFER = function(
               Handle : Integer ;
               bufnr : Integer
               ) : Integer ; cdecl ;


TPIXELFLY_SETBUFFER_EVENT = function(
                   Handle : Integer ;
                   bufnr : Integer ;
                   var hPicEvent : Integer
                   ) : Integer ; cdecl ;


TPIXELFLY_MAP_BUFFER = function(
              Handle : Integer ;
              bufnr : Integer ;
              size : Integer ;
              offset : Integer ;
              var linadr : Pointer
              ) : Integer ; cdecl ;

TPIXELFLY_UNMAP_BUFFER = function(
                Handle : Integer ;
                bufnr  : Integer
                ) : Integer ; cdecl ;


TPIXELFLY_SETORIONINT = function(
               Handle : Integer ;
               bufnr : Integer ;
               mode : Integer ;
               pBuf : Pointer ;
               len : Integer
               ) : Integer ; cdecl ;


TPIXELFLY_READEEPROM = function(
              Handle : Integer ;
              mode : Integer ;
              adr : Integer ;
              var data : Char
              ) : Integer ; cdecl ;

TPIXELFLY_WRITEEEPROM = function(
              Handle : Integer ;
              mode : Integer ;
              adr : Integer ;
              var data : Byte
              ) : Integer ; cdecl ;


TPIXELFLY_SETTIMEOUTS = function(
               Handle : Integer ;
               dman : Cardinal ;
               proc : Cardinal ;
               head : Cardinal
               ) : Integer ; cdecl ;

TPIXELFLY_SETDRIVER_EVENT = function(
                   Handle : Integer ;
                   mode : Integer ;
                   var hHeadEvent : Integer
                   ) : Integer ; cdecl ;

// Externally called functions

procedure PixelFly_LoadLibrary  ;

function  PixelFly_GetDLLAddress(
          Handle : Integer ;
          const ProcName : string ) : Pointer ;

function  PixelFly_OpenCamera(
          var Session : TPixelFlySession ;
          var FrameWidthMax : Integer ;
          var FrameHeightMax : Integer ;
          var NumBytesPerPixel : Integer ;
          var PixelDepth : Integer ;
          var PixelWidth : Single ;
          CameraInfo : TStringList
          ) : Boolean ;

procedure PixelFly_CloseCamera(
          var Session : TPixelFlySession
          ) ;

procedure PixelFly_GetCameraGainList(
          CameraGainList : TStringList
          ) ;

function PixelFly_StartCapture(
         var Session : TPixelFlySession ;
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

procedure PixelFly_TimerProc(
          uID,uMsg : SmallInt ;
          Session : PPixelFlySession ;
          dw1,dw2 : LongInt ) ; stdcall ;


procedure PixelFly_GetImage(
          var Session : TPixelFlySession ;
          FrameBuf : Pointer ;
          NumFrames : Integer ;
          NumBytesPerFrame : Integer ;
          var FrameCounter : Integer ) ;

procedure PixelFly_GetImageSlow(
          var Session : TPixelFlySession
          ) ;

procedure PixelFly_GetImageFast(
          var Session : TPixelFlySession
          ) ;


procedure PixelFly_StopCapture(
         var Session : TPixelFlySession
          ) ;

procedure PixelFlyCheckFrameInterval(
          FrameWidthMax : Integer ;
          BinFactor : Integer ;
          TriggerMode : Integer ;
          var FrameInterval : Double ;
          var ReadoutTime : Double ) ;


procedure PixelFly_CheckError(
          FuncName : String ;
          ErrNum : Integer
          ) ;


function PixelFly_CharArrayToString(
         cBuf : Array of Char
         ) : String ;

var

  PIXELFLY_INITBOARD : TPIXELFLY_INITBOARD ;
  PIXELFLY_INITBOARDP : TPIXELFLY_INITBOARDP ;
  PIXELFLY_CLOSEBOARD : TPIXELFLY_CLOSEBOARD ;
  PIXELFLY_RESETBOARD : TPIXELFLY_RESETBOARD ;
  PIXELFLY_GETBOARDPAR : TPIXELFLY_GETBOARDPAR ;
  PIXELFLY_SETMODE : TPIXELFLY_SETMODE ;
  PIXELFLY_WRRDORION : TPIXELFLY_WRRDORION ;
  PIXELFLY_SET_EXPOSURE : TPIXELFLY_SET_EXPOSURE ;
  PIXELFLY_TRIGGER_CAMERA : TPIXELFLY_TRIGGER_CAMERA ;
  PIXELFLY_START_CAMERA  : TPIXELFLY_START_CAMERA ;
  PIXELFLY_STOP_CAMERA : TPIXELFLY_STOP_CAMERA ;
  PIXELFLY_GETSIZES : TPIXELFLY_GETSIZES ;
  PIXELFLY_READTEMPERATURE : TPIXELFLY_READTEMPERATURE ;
  PIXELFLY_READVERSION : TPIXELFLY_READVERSION ;
  PIXELFLY_GETBUFFER_STATUS : TPIXELFLY_GETBUFFER_STATUS ;
  PIXELFLY_ADD_BUFFER_TO_LIST : TPIXELFLY_ADD_BUFFER_TO_LIST ;
  PIXELFLY_REMOVE_BUFFER_FROM_LIST : TPIXELFLY_REMOVE_BUFFER_FROM_LIST ;
  PIXELFLY_ALLOCATE_BUFFER : TPIXELFLY_ALLOCATE_BUFFER ;
  PIXELFLY_FREE_BUFFER : TPIXELFLY_FREE_BUFFER ;
  PIXELFLY_SETBUFFER_EVENT : TPIXELFLY_SETBUFFER_EVENT ;
  PIXELFLY_MAP_BUFFER : TPIXELFLY_MAP_BUFFER ;
  PIXELFLY_UNMAP_BUFFER : TPIXELFLY_UNMAP_BUFFER ;
  PIXELFLY_SETORIONINT : TPIXELFLY_SETORIONINT ;
  PIXELFLY_READEEPROM : TPIXELFLY_READEEPROM ;
  PIXELFLY_WRITEEEPROM : TPIXELFLY_WRITEEEPROM ;
  PIXELFLY_SETTIMEOUTS : TPIXELFLY_SETTIMEOUTS ;
  PIXELFLY_SETDRIVER_EVENT : TPIXELFLY_SETDRIVER_EVENT ;

implementation

uses sescam ;

const
  HW_TRIGGER = 0 ;
  SW_TRIGGER = 1 ;

  ASYNC_SHUTTER = $10 ;
  DOUBLE_SHUTTER =$20 ;
  VIDEO_MODE = $30 ;
  AUTO_EXPOSURE = $40 ;

  WIDEPIXEL = 8 ;

  VBIN_1X = 0 ;
  VBIN_2X = 1 ;
  VBIN_4X = 2 ;
  VBIN_420LINES = 8 ;

//defines for hbin setting
  HBIN_1X = 0 ;
  HBIN_2X = 1 ;
  HBIN_4X = 2 ;

  PCC_BUF_STAT_WRITE = $1 ;      // Buffer is filling or waiting to be filled
  PCC_BUF_STAT_WRITE_DONE = $2 ; // Buffer is full
  PCC_BUF_STAT_QUEUED = $4 ;     // Buffer is in list ;
  PCC_BUF_STAT_CANCELLED = $8 ;  // Buffer transfer cancelled
  PCC_BUF_STAT_SELECT = $10 ;    // Buffer event enabled
  PCC_BUF_STAT_SELECT_DONE = $20 ;    // Buffer event done
  PCC_BUF_STAT_REMOVED = $40 ;   // Buffer removed from list

//buffer errorflags
  PCC_BUF_STAT_ERROR = $F000 ;
  PCC_BUF_STAT_BURST_ERROR = $1000 ;
  PCC_BUF_STAT_SIZE_ERROR = $2000 ;
  PCC_BUF_STAT_PCI_ERROR = $4000 ;
  PCC_BUF_STAT_TIMEOUT_ERROR = $8000 ;





var
    LibraryHnd : THandle ;         // PCCAM32.DLL library handle
    LibraryLoaded : boolean ;      // PCCAM32.DLL library loaded flag
    ProcNum : Integer ;

procedure PixelFly_LoadLibrary  ;
{ -------------------------------------
  Load PCCAM.DLL library into memory
  -------------------------------------}
var
    LibFileName : string ;
begin

     { Load PCCAM interface DLL library }
     LibFileName := 'PCCAM.DLL' ;
     LibraryHnd := LoadLibrary( PChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin

        @PIXELFLY_INITBOARD := PixelFly_GetDLLAddress(LibraryHnd,'INITBOARD') ;
        @PIXELFLY_INITBOARDP := PixelFly_GetDLLAddress(LibraryHnd,'INITBOARDP') ;
        @PIXELFLY_CLOSEBOARD := PixelFly_GetDLLAddress(LibraryHnd,'CLOSEBOARD') ;
        @PIXELFLY_RESETBOARD := PixelFly_GetDLLAddress(LibraryHnd,'RESETBOARD') ;
        @PIXELFLY_GETBOARDPAR := PixelFly_GetDLLAddress(LibraryHnd,'GETBOARDPAR') ;
        @PIXELFLY_SETMODE := PixelFly_GetDLLAddress(LibraryHnd,'SETMODE') ;
        @PIXELFLY_WRRDORION := PixelFly_GetDLLAddress(LibraryHnd,'WRRDORION') ;
        @PIXELFLY_SET_EXPOSURE := PixelFly_GetDLLAddress(LibraryHnd,'SET_EXPOSURE') ;
        @PIXELFLY_TRIGGER_CAMERA := PixelFly_GetDLLAddress(LibraryHnd,'TRIGGER_CAMERA') ;
        @PIXELFLY_START_CAMERA := PixelFly_GetDLLAddress(LibraryHnd,'START_CAMERA') ;
        @PIXELFLY_STOP_CAMERA := PixelFly_GetDLLAddress(LibraryHnd,'STOP_CAMERA') ;
        @PIXELFLY_GETSIZES := PixelFly_GetDLLAddress(LibraryHnd,'GETSIZES') ;
        @PIXELFLY_READTEMPERATURE := PixelFly_GetDLLAddress(LibraryHnd,'READTEMPERATURE') ;
        @PIXELFLY_READVERSION := PixelFly_GetDLLAddress(LibraryHnd,'READVERSION') ;
        @PIXELFLY_GETBUFFER_STATUS := PixelFly_GetDLLAddress(LibraryHnd,'GETBUFFER_STATUS') ;
        @PIXELFLY_ADD_BUFFER_TO_LIST := PixelFly_GetDLLAddress(LibraryHnd,'ADD_BUFFER_TO_LIST') ;
        @PIXELFLY_REMOVE_BUFFER_FROM_LIST := PixelFly_GetDLLAddress(LibraryHnd,'REMOVE_BUFFER_FROM_LIST') ;
        @PIXELFLY_ALLOCATE_BUFFER := PixelFly_GetDLLAddress(LibraryHnd,'ALLOCATE_BUFFER') ;
        @PIXELFLY_FREE_BUFFER := PixelFly_GetDLLAddress(LibraryHnd,'FREE_BUFFER') ;
        @PIXELFLY_SETBUFFER_EVENT := PixelFly_GetDLLAddress(LibraryHnd,'SETBUFFER_EVENT') ;
        @PIXELFLY_MAP_BUFFER := PixelFly_GetDLLAddress(LibraryHnd,'MAP_BUFFER') ;
        @PIXELFLY_UNMAP_BUFFER := PixelFly_GetDLLAddress(LibraryHnd,'UNMAP_BUFFER') ;
        @PIXELFLY_SETORIONINT := PixelFly_GetDLLAddress(LibraryHnd,'SETORIONINT') ;
        @PIXELFLY_READEEPROM := PixelFly_GetDLLAddress(LibraryHnd,'READEEPROM') ;
        @PIXELFLY_WRITEEEPROM := PixelFly_GetDLLAddress(LibraryHnd,'WRITEEEPROM') ;
        @PIXELFLY_SETTIMEOUTS := PixelFly_GetDLLAddress(LibraryHnd,'SETTIMEOUTS') ;
        @PIXELFLY_SETDRIVER_EVENT := PixelFly_GetDLLAddress(LibraryHnd,'SETDRIVER_EVENT') ;
        LibraryLoaded := True ;
        end
     else begin
          MessageDlg( 'PixelFly: ' + LibFileName + ' not found!', mtWarning, [mbOK], 0 ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function PixelFly_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within PCCAM.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('PCCAM.DLL: ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
    end ;


function PixelFly_OpenCamera(
          var Session : TPixelFlySession ;   // Camera session record
          var FrameWidthMax : Integer ;      // Returns camera frame width
          var FrameHeightMax : Integer ;     // Returns camera height width
          var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
          var PixelDepth : Integer ;         // Returns no. bits/pixel
          var PixelWidth : Single ;          // Returns pixel size (um)
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;
// ---------------------
// Open PixelFly camera
// ---------------------
var
    Err : Integer ;
    cBuf : Array[0..79] of Char ;
    s : String ;
    i,j :Integer ;
    CCDTemperature : Integer ;
    CCDXSize : Integer ;
    CCDYSize : Integer ;
    ActualXSize : Integer ;
    ActualYSize : Integer ;
    c : Char ;
begin

     Result := False ;

     // Load DLL libray
     if not LibraryLoaded then PixelFly_LoadLibrary  ;
     if not LibraryLoaded then Exit ;

     // Initialise board & return handle
     Err := PIXELFLY_INITBOARD( 0, Session.Handle ) ;
     PixelFly_CheckError( 'INITBOARD', Err ) ;
     if Err <> 0 then Exit ;

     CameraInfo.Add('PCO PixelFly') ;

     // Get version no.
     for i := 1 to 6 do begin
     Err := PIXELFLY_READVERSION( Session.Handle,
                                  i,
                                  cBuf,
                                  High(cBuf) ) ;
     s := 'Version: ' +  PixelFly_CharArrayToString( cBuf ) ;
     //CameraInfo.Add(s) ;
     end ;

     Err := PIXELFLY_GETSIZES( Session.Handle,
                               CCDXSize,
                               CCDYSize,
                               ActualXSize,
                               ActualYSize,
                               Session.BitsPerPixel ) ;
     PixelFly_CheckError( 'GETSIZES', Err ) ;
     FrameWidthMax := ActualXSize ;
     FrameHeightMax := ActualYSize ;

     // No. of bytes per pixel
     PixelDepth := Session.BitsPerPixel ;
     if PixelDepth > 8 then NumBytesPerPixel := 2
                       else NumBytesPerPixel := 1 ;

     // Pixel size (um)
     if FrameWidthMax = 640 then PixelWidth := 9.9        // VGA
     else if FrameWidthMax = 1280 then PixelWidth := 6.7 // Scientific
     else if FrameWidthMax = 1360 then PixelWidth := 4.65 // Hi-Res
     else if FrameWidthMax = 1392 then PixelWidth := 6.45 // QE
     else PixelWidth := 1.0 ;

     CameraInfo.Add(format('Frame: %d x %d pixels',[FrameWidthMax,FrameHeightMax])) ;
     CameraInfo.Add(format('Pixel width: %.3f um',[PixelWidth])) ;
     CameraInfo.Add(format('Pixel depth: %d bits',[PixelDepth])) ;



     Err := PIXELFLY_READTEMPERATURE( Session.Handle, CCDTemperature ) ;
     PixelFly_CheckError( 'READTEMPERATURE', Err ) ;
     CameraInfo.Add(format('CCD Temperature: %d',[CCDTemperature])) ;

     Session.GetImageInUse := False ;
     Session.CapturingImages := False ;
     Session.GetImageInUse := False ;

     Session.CameraOpen := True ;
     Result := Session.CameraOpen ;


     Session.TimerID := -1 ;
     Session.TimerProcInUse := False ;

     ProcNum := 0 ;

     end ;


procedure PixelFly_CloseCamera(
          var Session : TPixelFlySession // Session record
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
          PixelFly_CheckError( 'STOP_CAMERA',
                               PIXELFLY_STOP_CAMERA( Session.Handle ) ) ;
          end ;

       // Close camera
       PixelFly_CheckError( 'CLOSEBOARD',
                            PIXELFLY_CLOSEBOARD( Session.Handle ) ) ;

       // Stop timer (if still running)
       if Session.TimerID >= 0 then begin
          timeKillEvent( Session.TimerID ) ;
          Session.TimerID := -1 ;
          end ;

       end ;

    Session.GetImageInUse := False ;
    Session.CameraOpen := False ;
    Session.CapturingImages := False ;

    end ;


procedure PixelFly_GetCameraGainList(
          CameraGainList : TStringList
          ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
begin
    CameraGainList.Add( ' Low ' ) ;
    CameraGainList.Add( ' High ' ) ;
    end ;


function PixelFly_StartCapture(
         var Session : TPixelFlySession ;   // Camera session record
         var ExposureTime : Double ;      // Frame exposure time
         AdditionalReadoutTime : Double ;
         AmpGain : Integer ;              // Camera amplifier gain index
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer       // No. of bytes/frame
         ) : Boolean ;
// -------------------
// Start frame capture
// -------------------
const
     MaxExposureTimeTicks = 65535 ;
     TimerTickInterval = 20 ; // Timer tick resolution (ms)

var
    Err : Integer ;
    i : Integer ;
    ExposureTimeTicks : Integer ;
    Mode : Integer ;
    HBin : Integer ;
    VBin : Integer ;
    ReadoutTime : Double ;
begin

     // Disable timer if it is running
     if Session.TimerID >= 0 then begin
        timeKillEvent( Session.TimerID ) ;
        Session.TimerID := -1 ;
        end ;

     // Check exposure time to get readout time
     PixelFlyCheckFrameInterval( FrameWidth,
                                 BinFactor,
                                 ExternalTrigger,
                                 ExposureTime,
                                 ReadoutTime ) ;

     // Internal/external triggering of frame capture

     if ExternalTrigger = CamFreeRun then begin
        // Exposure triggered internally at timed intervals
        Mode := VIDEO_MODE or SW_TRIGGER ;
        // Exposure time in ms
        ExposureTimeTicks := Round(ExposureTime*1E3) ;
        ExposureTime := ExposureTimeTicks/1E3 ;
        Session.NumBuffers := 16 ;
        Session.TriggerMode := camFreeRun ;
        Session.ExposureTime := ExposureTime ;
        end
     else if ExposureTime >= PixelflySlowExposureTime then begin
        // Externally trigger exposures (slow)
        Mode := VIDEO_MODE or HW_TRIGGER ;
        // Camera re-start time must be subtracted from exposure
        ExposureTimeTicks := Round((ExposureTime - ReadoutTime - 0.15 - AdditionalReadoutTime)*1E3) ;
        Session.NumBuffers := 2 ;
        Session.TriggerMode := CamExtTrigger ;
        Session.ExposureTime := ExposureTime ;
        end
     else begin
        // Externally trigger exposures (fast)
        Mode := ASYNC_SHUTTER or HW_TRIGGER ;
        // Readout time must be subtracted from exposure time
        // since readout and exposure not overlapped in ASYNC_SHUTTER mode
        ExposureTimeTicks := Round((ExposureTime-ReadoutTime-0.001 - AdditionalReadoutTime)*1E6) ;
        // Keep exposure within min/max limits
        // (Max. exposure = 65.535 ms)
        if ExposureTimeTicks > MaxExposureTimeTicks then
           ExposureTimeTicks := MaxExposureTimeTicks ;
        if ExposureTimeTicks < 10 then ExposureTimeTicks := 10 ;
        Session.NumBuffers := 8 ;
        Session.TriggerMode := CamExtTrigger ;
        Session.ExposureTime := ExposureTime ;
        end ;

     // Frame exposure time

     // Pixel binning factor (X1 or X2)
     if BinFactor = 2 then begin
        HBin := HBIN_2X ;
        VBin := VBIN_2X ;
        end
     else if BinFactor = 4 then begin
        HBin := HBIN_4X ;
        VBin := VBIN_4X ;
        end
     else begin
        HBin := HBIN_1X ;
        VBin := VBIN_1X ;
        end ;

     Err := PIXELFLY_SETMODE( Session.Handle,
                              Mode,
                              0,
                              ExposureTimeTicks,
                              HBin,
                              VBin,
                              AmpGain,
                              0,
                              Session.BitsPerPixel,
                              0 ) ;
     PixelFly_CheckError( 'SETMODE', Err ) ;
     if Err <> 0 then Exit ;

     // Allocate pixelfly camera buffers

     Session.NumBytesPerFrame := NumBytesPerFrame ;
     Session.NumFrames := NumFramesInBuffer ;
     Session.PFrameBuffer := PFrameBuffer ;
     Session.FrameCounter := 0 ;

     for i := 0 to Session.NumBuffers-1 do begin

         // Allocate buffer
         Session.BufNum[i] := -1 ;
         Session.BufSize[i] := NumBytesPerFrame ;
         Err := PIXELFLY_ALLOCATE_BUFFER( Session.Handle,
                                          Session.BufNum[i],
                                          Session.BufSize[i] ) ;
         PixelFly_CheckError( 'ALLOCATE_BUFFER', Err ) ;
         if Err <> 0 then Break ;

         // Map buffer into user address space
         Err := PIXELFLY_MAP_BUFFER( Session.Handle,
                                     Session.BufNum[i],
                                     NumBytesPerFrame,
                                     0,
                                     Session.PBuffer[i] ) ;
         PixelFly_CheckError( 'MAP_BUFFER', Err ) ;
         if Err <> 0 then Break ;

         // Add buffer to camera buffer queue
         Err := PIXELFLY_ADD_BUFFER_TO_LIST( Session.Handle,
                                             Session.BufNum[i],
                                             NumBytesPerFrame,
                                             0,
                                             0 ) ;
         PixelFly_CheckError( 'ADD_BUFFER_TO_LIST', Err ) ;
         if Err <> 0 then Break ;

         end ;

     // Start camera
     Err := PIXELFLY_START_CAMERA( Session.Handle ) ;
     PixelFly_CheckError( 'START_CAMERA', Err ) ;
     if Err <> 0 then Exit ;

     // Start frame acquisition monitor procedure
     Session.TimerProcInUse := False ;
     Session.TimerID := TimeSetEvent( TimerTickInterval,
                                      TimerTickInterval,
                                      @PixelFly_TimerProc,
                                      Cardinal(@Session),
                                      TIME_PERIODIC ) ;


     if ExternalTrigger = CamFreeRun then begin
        Err := PIXELFLY_TRIGGER_CAMERA( Session.Handle ) ;
        PixelFly_CheckError( 'TRIGGER_CAMERA', Err ) ;
        end ;

     Session.CapturingImages := True ;
     Session.OldestUnReadBuf := 0 ;

     Result := True ;

     end;


procedure PixelFly_TimerProc(
          uID,uMsg : SmallInt ;
          Session : PPixelFlySession ;
          dw1,dw2 : LongInt ) ; stdcall ;
{ ----------------------------------------------
  Timer scheduled events, called a 10ms intervals
  ---------------------------------------------- }
var
    Err : Integer ;
    BufPointer : Pointer ;
    t0 : Integer ;
begin

    if Session^.TimerProcInUse then Exit ;
    Session^.TimerProcInUse := True ;

    if (Session^.TriggerMode = CamExtTrigger) and
       (Session^.ExposureTime >= PixelFlySlowExposureTime) then begin
       PixelFly_GetImageSlow ( Session^ ) ;
       end
    else begin
       PixelFly_GetImageFast( Session^ ) ;
       end ;

    Session^.TimerProcInUse := False ;
    end ;


procedure PixelFly_GetImage(
          var Session : TPixelFlySession ; // Camera session record
          FrameBuf : Pointer ;             // Pointer to frame storage buffer
          NumFrames : Integer ;            // No. frames in storage buffer
          NumBytesPerFrame : Integer ;     // No. of bytes / frame
          var FrameCounter : Integer       // frame counter
          ) ;
begin

    end ;



procedure PixelFly_GetImageFast(
          var Session : TPixelFlySession // Camera session record
          ) ;
// -------------------------------------------------------------------------
// Transfer images from camera buffer into main frame buffer
// (Free run trigger mode and external trigger mode for short exposure times
// -------------------------------------------------------------------------
var
    Err : Integer ;
    t0 :Integer ;
    iBuf : Integer ;
    i : Integer ;
    BufStatus : Integer ;
    PFromBuf : Pointer ;
    PToBuf : Pointer ;
    ReadCounter : Integer ;
begin

    if Session.GetImageInUse or (not Session.CapturingImages) then Exit ;
    Session.GetImageInUse := True ;
    //t0 := timegettime ;

    ReadCounter := 0 ;
    while ReadCounter < Session.NumBuffers do begin

        // Get buffer status
        Err := PIXELFLY_GETBUFFER_STATUS( Session.Handle,
                                          Session.BufNum[Session.OldestUnReadBuf],
                                          0,
                                          BufStatus,
                                          4 ) ;

        // Break copy loop when first un-full buffer encountered
        if (BufStatus and PCC_BUF_STAT_WRITE_DONE) = 0 then Break ;

        //   outputdebugString(PChar(format('%d %d %d',[iBuf,ProcNum,FrameCounter]))) ;

        // Copy image from camera buffer to main frame buffer
        PFromBuf := Session.PBuffer[Session.OldestUnReadBuf] ;
        PToBuf := Pointer( Integer(Session.PFrameBuffer) + Session.FrameCounter*Session.NumBytesPerFrame ) ;
        for i := 0 to Session.NumBytesPerFrame-1 do
            PByteArray(PToBuf)[i] := PByteArray(PFromBuf)[i] ;

        // Return buffer to camera buffer queue
        Err := PIXELFLY_ADD_BUFFER_TO_LIST( Session.Handle,
                                            Session.BufNum[Session.OldestUnReadBuf],
                                            Session.NumBytesPerFrame,
                                            0,
                                            0 ) ;
        PixelFly_CheckError( 'ADD_BUFFER_TO_LIST', Err ) ;

        // Increment frame buffer pointer
        Inc(Session.FrameCounter) ;
        if Session.FrameCounter >= Session.NumFrames then Session.FrameCounter := 0 ;

        // Increment oldest un-read camera buffer counter
        Inc(Session.OldestUnReadBuf) ;
        if Session.OldestUnReadBuf >= Session.NumBuffers then
           Session.OldestUnReadBuf := 0 ;

        Inc(ReadCounter) ;

        end ;

    Session.GetImageInUse := False ;

    end ;


procedure PixelFly_GetImageSlow(
          var Session : TPixelFlySession // Camera session record
          ) ;
// -------------------------------------------------------------------------
// Transfer images from camera buffer into main frame buffer
// External trigger mode with long exposure times
// -------------------------------------------------------------------------
var
    Err : Integer ;
    t0 :Integer ;
    iBuf : Integer ;
    i : Integer ;
    BufStatus : Integer ;
    PFromBuf : Pointer ;
    PToBuf : Pointer ;
begin

    if Session.GetImageInUse or (not Session.CapturingImages) then Exit ;
    Session.GetImageInUse := True ;
    //t0 := timegettime ;

    // Get buffer status
    Err := PIXELFLY_GETBUFFER_STATUS( Session.Handle,
                                          Session.BufNum[0],
                                          0,
                                          BufStatus,
                                          4 ) ;

//outputdebugString(PChar(format('%x %d',[BufStatus,FrameCounter]))) ;

    // Exit if frame not available
    if (BufStatus and PCC_BUF_STAT_WRITE_DONE) = 0 then begin
       Session.GetImageInUse := False ;
       Exit ;
       end ;

    // Copy image from camera buffer to main frame buffer
    PFromBuf := Session.PBuffer[0] ;
    PToBuf := Pointer( Integer(Session.PFrameBuffer) + Session.FrameCounter*Session.NumBytesPerFrame ) ;
    for i := 0 to Session.NumBytesPerFrame-1 do
        PByteArray(PToBuf)[i] := PByteArray(PFromBuf)[i] ;

    // Increment frame buffer pointer
    Inc(Session.FrameCounter) ;
    if Session.FrameCounter >= Session.NumFrames then Session.FrameCounter := 0 ;

    // Stop frame capture
    PixelFly_CheckError( 'STOP_CAMERA',
                         PIXELFLY_STOP_CAMERA( Session.Handle ) ) ;

    // Free all Pixelfly camera buffers
    for iBuf := 0 to Session.NumBuffers-1 do begin
        PixelFly_CheckError( 'GETBUFFER_STATUS',
                             PIXELFLY_GETBUFFER_STATUS( Session.Handle,
                                                        Session.BufNum[iBuf],
                                                        0,
                                                        BufStatus,
                                                        4 )) ;
        if (BufStatus and PCC_BUF_STAT_QUEUED) <> 0 then begin
           PixelFly_CheckError( 'REMOVE_BUFFER_FROM_LIST',
                    PIXELFLY_REMOVE_BUFFER_FROM_LIST( Session.Handle,
                                                      Session.BufNum[iBuf] )) ;
           end ;
        end ;

    // Add buffers back to queue
    for iBuf := 0 to Session.NumBuffers-1 do begin

         // Add buffer to camera buffer queue
         Err := PIXELFLY_ADD_BUFFER_TO_LIST( Session.Handle,
                                             Session.BufNum[iBuf],
                                             Session.NumBytesPerFrame,
                                             0,
                                             0 ) ;
         PixelFly_CheckError( 'ADD_BUFFER_TO_LIST', Err ) ;
         if Err <> 0 then Break ;

         end ;

    // Start camera again
    Err := PIXELFLY_START_CAMERA( Session.Handle ) ;
    PixelFly_CheckError( 'START_CAMERA', Err ) ;

    Session.GetImageInUse := False ;

    end ;



procedure PixelFly_StopCapture(
          var Session : TPixelFlySession   // Camera session record
          ) ;
// ------------------
// Stop frame capture
// ------------------
var
    Err : Integer ;
    iBuf : Integer ;
    BufStatus : Integer ;
begin

     if not Session.CapturingImages then Exit ;

     // Stop frame capture
     PixelFly_CheckError( 'STOP_CAMERA',
                          PIXELFLY_STOP_CAMERA( Session.Handle ) ) ;
     Session.CapturingImages := False ;

     // Free pixelfly camera buffers
     for iBuf := 0 to Session.NumBuffers-1 do begin

        // Get buffer status
        PixelFly_CheckError( 'GETBUFFER_STATUS',
                             PIXELFLY_GETBUFFER_STATUS( Session.Handle,
                                                        Session.BufNum[iBuf],
                                                        0,
                                                        BufStatus,
                                                        4 )) ;

        // Remove buffer if still in list
        if (BufStatus and PCC_BUF_STAT_QUEUED) <> 0 then begin
           PixelFly_CheckError( 'REMOVE_BUFFER_FROM_LIST',
                    PIXELFLY_REMOVE_BUFFER_FROM_LIST( Session.Handle,
                                                      Session.BufNum[iBuf] )) ;
           end ;

        // Un-map buffer
        PixelFly_CheckError( 'UNMAP_BUFFER',
                             PIXELFLY_UNMAP_BUFFER( Session.Handle,
                                                   Session.BufNum[iBuf] )) ;
        // Free buffer
        PixelFly_CheckError( 'FREE_BUFFER',
                             PIXELFLY_FREE_BUFFER( Session.Handle,
                                                   Session.BufNum[iBuf] )) ;

        end ;

     end;


procedure PixelFlyCheckFrameInterval( FrameWidthMax : Integer ;
                                      BinFactor : Integer ;
                                      TriggerMode : Integer ;
                                      var FrameInterval : Double ;
                                      var ReadoutTime : Double ) ;
// -----------------------
// Return CCD readout time
// -----------------------
begin

    if FrameWidthMax <= 640 then begin
       // VGA resolution cameras
       case BinFactor of
          1 : ReadoutTime := 0.0253 ;
          2 : ReadoutTime := 0.0133 ;
          end ;
       end
    else if FrameWidthMax <= 1280 then begin
       // Scientific resolution cameras
       case BinFactor of
          1 : ReadoutTime := 0.0803 ;
          2 : ReadoutTime := 0.0408 ;
          end ;
       end
    else begin
       // Hi resolution cameras
       case BinFactor of
          1 : ReadoutTime := 0.1045 ;
          2 : ReadoutTime := 0.053 ;
          end ;
       end ;

    if FrameInterval < ReadoutTime then FrameInterval := ReadoutTime ;


    if (TriggerMode <> CamFreeRun) and (FrameInterval < 0.1) then begin
       FrameInterval := 0.1 ;
       ReadoutTime := 0.1 ;
       end ;

    end ;


procedure PixelFly_CheckError(
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
      -1 : Report := 'Initialisation Failed. No camera connected.' ;
      -2 : Report := 'Function timed out.' ;
      -3 : Report := 'Wrong parameter.' ;
      -4 : Report := 'Unable to locate PCI card or driver.' ;
      -5 : Report := 'Wrong operating system.' ;
      -6 : Report := 'No or wrong driver installed.' ;
      -7 : Report := 'I/O function failed.' ;
      -9 : Report := 'Invalid camera mode.' ;
      -11 : Report := 'Device is held by another process.' ;
      -12 : Report := 'Error reading or writing data to board.' ;
      -13 : Report := 'Wrong driver function.' ;
      -101 : Report := 'Timeout in driver function.';
      -102 : Report := 'Board is held by another process.' ;
      -103 : Report := 'Wrong board type.' ;
      -104 : Report := 'Cannot match process handle to a board.';
      -105 : Report := 'Failed to init PCI.' ;
      -106 : Report := 'No board found.';
      -107 : Report := 'Read configuration registers failed.';
      -108 : Report := 'Board has wrong configuration.' ;
      -110 : Report := 'Camera is busy.' ;
      -111 : Report := 'Board is not idle.';
      -112 : Report := 'Wrong parameter sent.';
      -113 : Report := 'Head is disconnected.';
      -116 : Report := 'Board initialisation FPGA failed.' ;
      -117 : Report := 'Board initialisation NVRAM failed.' ;
      -121 : Report := 'Not enough I/O buffer space for return values.';
      -130 : Report := 'Picture buffer not prepared for transfer.';
      -131 : Report := 'Picture buffer in use.';
      -132 : Report := 'Picture buffer held by another process.';
      -133 : Report := 'Picture buffer not found.';
      -134 : Report := 'Picture buffer cannot be freed.';
      -135 : Report := 'Cannot allocate more picture buffers.';
      -136 : Report := 'No memory left for picture buffers.';
      -137 : Report := 'Memory reserve failed.';
      -138 : Report := 'Memory commit failed.';
      -139 : Report := 'Allocate internal memory LUT failed.';
      -140 : Report := 'Allocate internal memory PAGETAB failed.';
      -148 : Report := 'Event not available.';
      -149 : Report := 'Delete event failed.';
      -156 : Report := 'Enable interrupts failed.';
      -157 : Report := 'Disable interrupts failed.';
      -158 : Report := 'No interrupt connected to board.';
      -164 : Report := 'Time-out in DMA.';
      -165 : Report := 'No DMA buffer found.';
      -166 : Report := 'Locking of pages failed.';
      -167 : Report := 'Unlocking of pages failed.';
      -168 : Report := 'DMA buffer size too small.';
      -169 : Report := 'PCI bus error in DMA.';
      -170 : Report := 'DMA is running, command not allowed.';
      -228 : Report := 'Get processor failed.';
      -230 : Report := 'Wrong processor found.';
      -231 : Report := 'Wrong processor size.';
      -232 : Report := 'Wrong processotr device.';
      -233 : Report := 'Read flash failed.';

      else Report := '' ;
      end ;

    MessageDlg( format( 'PIXELFLY: %s (%d) %s',
                        [FuncName,ErrNum,Report] ),
                mtWarning, [mbOK], 0 ) ;

    end ;


function PixelFly_CharArrayToString(
         cBuf : Array of Char
         ) : String ;
// ---------------------------------
// Convert character array to string
// ---------------------------------
var
     i : Integer ;
begin
     i := 0 ;
     Result := '' ;
     while (cBuf[i] <> #0) and (i <= High(cBuf)) do begin
         Result := Result + cBuf[i] ;
         Inc(i) ;
         end ;
     end ;



end.
