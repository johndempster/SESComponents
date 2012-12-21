unit imaq1394;
// -----------------------------------------------
// National Instruments IMAQ 1394 firewire cameras
// -----------------------------------------------
// 24-5-4 Working but not fully tested
// 20-3-5 Camera gain can now be set
// 15-10-6 Updated to work with IMAQ-1394 V2.02
// 24-07-07 GetImage updated to ignore invalid buffer count at start of image acquisition

interface
uses WinTypes,sysutils, classes, dialogs, mmsystem, math ;

const
     IMG1394_ATTR_BRIGHTNESS       = $0001 ;
     IMG1394_ATTR_AUTO_EXPOSURE    = $0002 ;
     IMG1394_ATTR_SHARPNESS        = $0003 ;
     IMG1394_ATTR_WHITE_BALANCE_U_B= $0004 ;
     IMG1394_ATTR_WHITE_BALANCE_V_R= $0005 ;
     IMG1394_ATTR_HUE              = $0006 ;
     IMG1394_ATTR_SATURATION       = $0007 ;
     IMG1394_ATTR_GAMMA            = $0008 ;
     IMG1394_ATTR_SHUTTER          = $0009 ;
     IMG1394_ATTR_GAIN             = $000A ;
     IMG1394_ATTR_IRIS             = $000B ;
     IMG1394_ATTR_FOCUS            = $000C ;
     IMG1394_ATTR_TEMPERATURE      = $000D ;
     IMG1394_ATTR_TRIGGER          = $000E ;
     IMG1394_ATTR_ZOOM             = $000F ;
     IMG1394_ATTR_PAN              = $0010 ;
     IMG1394_ATTR_TILT             = $0011 ;
     IMG1394_ATTR_OPTICAL_FILTER   = $0012 ;
     IMG1394_ATTR_VENDOR_NAME      = $0013 ;
     IMG1394_ATTR_MODEL_NAME       = $0014  ;
     IMG1394_ATTR_SERIAL_NO        = $0015  ;
     IMG1394_ATTR_MODEL_ID         = $0016  ;
     IMG1394_ATTR_VIDEO_FORMAT     = $0017 ;
     IMG1394_ATTR_VIDEO_MODE       = $0018 ;
     IMG1394_ATTR_VIDEO_FRAME_RATE = $0019 ;
     IMG1394_ATTR_IMAGE_REP        = $001A ;
     IMG1394_ATTR_TIMEOUT          = $001B ;
     IMG1394_ATTR_FORMAT7_UNIT_WIDTH      = $001C ;
     IMG1394_ATTR_FORMAT7_UNIT_HEIGHT      = $001D ;
     IMG1394_ATTR_UNIQUE_ID_LOW    = $001E;
     IMG1394_ATTR_UNIQUE_ID_HIGH   = $001F ;
     IMG1394_ATTR_LOST_BUFFER_NB   = $0020 ;
     IMG1394_ATTR_FORMAT7_LEFT     = $0021 ;
     IMG1394_ATTR_FORMAT7_TOP      = $0022 ;
     IMG1394_ATTR_FORMAT7_WIDTH    = $0023 ;
     IMG1394_ATTR_FORMAT7_HEIGHT   = $0024 ;
     IMG1394_ATTR_FORMAT7_COLORCODING      = $0025 ;
     IMG1394_ATTR_IMAGE_WIDTH      = $0026 ;
     IMG1394_ATTR_IMAGE_HEIGHT     = $0027 ;
     IMG1394_ATTR_BYTES_PER_PIXEL  = $0028 ;
     IMG1394_ATTR_FRAME_INTERVAL   = $0029 ;
     IMG1394_ATTR_FORMAT7_BYTES_PER_PACKET      = $002A ;
     IMG1394_ATTR_ABSOLUTE_BRIGHTNESS      = $0101 ;
     IMG1394_ATTR_ABSOLUTE_AUTO_EXPOSURE      = $0102 ;
     IMG1394_ATTR_ABSOLUTE_SHARPNESS      = $0103 ;
     IMG1394_ATTR_ABSOLUTE_WHITE_BALANCE      = $0104 ;
     IMG1394_ATTR_ABSOLUTE_HUE     = $0106 ;
     IMG1394_ATTR_ABSOLUTE_SATURATION      = $0107 ;
     IMG1394_ATTR_ABSOLUTE_GAMMA   = $0108 ;
     IMG1394_ATTR_ABSOLUTE_SHUTTER = $0109 ;
     IMG1394_ATTR_ABSOLUTE_GAIN    = $010A ;
     IMG1394_ATTR_ABSOLUTE_IRIS    = $010B ;
     IMG1394_ATTR_ABSOLUTE_FOCUS   = $010C ;
     IMG1394_ATTR_ABSOLUTE_TEMPERATURE      = $010D ;
     IMG1394_ATTR_ABSOLUTE_TRIGGER = $010E ;
     IMG1394_ATTR_ABSOLUTE_ZOOM    = $010F ;
     IMG1394_ATTR_ABSOLUTE_PAN     = $0110 ;
     IMG1394_ATTR_ABSOLUTE_TILT    = $0111 ;
     IMG1394_ATTR_ABSOLUTE_OPTICAL_FILTER      = $0112 ;
     IMG1394_ATTR_ROI_LEFT         = $011B ;
     IMG1394_ATTR_ROI_TOP          = $011C ;
     IMG1394_ATTR_ROI_WIDTH        = $011D ;
     IMG1394_ATTR_ROI_HEIGHT       = $011E ;
     IMG1394_ATTR_FORMAT7_SPEED    = $0121 ;
     IMG1394_ATTR_LAST_TRANSFERRED_BUFFER_NUM      = $0123 ;
     IMG1394_ATTR_FRAME_COUNT      = $0124 ;
     IMG1394_ATTR_ACQ_IN_PROGRESS  = $0125 ;
     IMG1394_ATTR_IGNORE_FIRST_FRAME      = $0126 ;
     IMG1394_ATTR_SHIFT_PIXEL_BITS = $0127 ;
     IMG1394_ATTR_SWAP_PIXEL_BYTES = $0128 ;
     IMG1394_ATTR_FORMAT7_UNIT_BYTES_PER_PACKET      = $0129 ;
     IMG1394_ATTR_FORMAT7_MAX_BYTES_PER_PACKET      = $012A ;
     IMG1394_ATTR_BITS_PER_PIXEL   = $012C ;
     IMG1394_ATTR_TRIGGER_DELAY    = $0202 ;
     IMG1394_ATTR_WHITE_SHADING_R  = $0203 ;
     IMG1394_ATTR_WHITE_SHADING_G  = $0204 ;
     IMG1394_ATTR_WHITE_SHADING_B  = $0205 ;
     IMG1394_ATTR_FRAME_RATE       = $0206 ;
     IMG1394_ATTR_ABSOLUTE_TRIGGER_DELAY      = $0207 ;
     IMG1394_ATTR_ABSOLUTE_FRAME_RATE      = $0208 ;
     IMG1394_ATTR_COLOR_FILTER_INQ = $0209 ;
     IMG1394_ATTR_COLOR_FILTER     = $020A ;
     IMG1394_ATTR_COLOR_FILTER_GAIN_R      = $020B ;
     IMG1394_ATTR_COLOR_FILTER_GAIN_G      = $020C ;
     IMG1394_ATTR_COLOR_FILTER_GAIN_B      = $020D;
     IMG1394_ATTR_FORMAT7_MAX_SPEED= $020E;
     IMG1394_ATTR_FORMAT7_PACKETS_PER_IMAGE      = $021B ;
     IMG1394_ATTR_BASE_ADDRESS     = $021D ;


//==============================================================================
//  Attribute limits
//==============================================================================
     IMG1394_VIDEO_FORMAT_MIN = 0 ;
     IMG1394_VIDEO_FORMAT_MAX = 7 ;
     IMG1394_VIDEO_MODE_MIN = 0 ;
     IMG1394_VIDEO_MODE_MAX = 7 ;
     IMG1394_VIDEO_FRAME_RATE_MIN = 0 ;
     IMG1394_VIDEO_FRAME_RATE_MAX = 7 ;
     IMG1394_DWORD_MIN =  0 ;
     IMG1394_DWORD_MAX             = $FFFFFFFF ;
     IMG1394_BITS_PER_PIXEL_MIN = 10 ;
     IMG1394_BITS_PER_PIXEL_MAX = 16 ;


//==============================================================================
//  Special keys used for attributes
//==============================================================================
     IMG1394_LASTBUFFER = IMG1394_DWORD_MAX ;
     IMG1394_IMMEDIATEBUFFER = IMG1394_DWORD_MAX - 1 ;
     IMG1394_AUTOMODE = IMG1394_DWORD_MAX ;
     IMG1394_ONEPUSHMODE = IMG1394_DWORD_MAX - 1 ;
     IMG1394_OFFMODE =  IMG1394_DWORD_MAX - 2 ;
     IMG1394_ABSOLUTEMODE = IMG1394_DWORD_MAX - 3 ;
     IMG1394_RELATIVEMODE = IMG1394_DWORD_MAX - 4 ;
     IMG1394_IGNOREMODE = IMG1394_DWORD_MAX - 5  ;


//==============================================================================
//  Plot flags
//==============================================================================
     IMG1394_PLOT_MONO_8           = $00000000 ;
     IMG1394_PLOT_INVERT           = $00000001 ;
     IMG1394_PLOT_COLOR_RGB24      = $00000002 ;
     IMG1394_PLOT_COLOR_RGB32      = $00000004 ;
     IMG1394_PLOT_MONO_10          = $00000008 ;
     IMG1394_PLOT_MONO_12          = $00000010 ;
     IMG1394_PLOT_MONO_14          = $00000020 ;
     IMG1394_PLOT_MONO_16          = $00000040 ;
     IMG1394_PLOT_MONO_32          = $00000080 ;
     IMG1394_PLOT_AUTO             = $00000100 ;


//============================================================================
//  Error Codes Enumeration
//============================================================================
     IMG1394_ERR_GOOD = 0 ; // success
     IMG1394_ERR_EMEM              = $BFF68000 ; // Not enough memory
     IMG1394_ERR_EDRV              = $BFF68001 ; // Cannot load the driver
     IMG1394_ERR_TIMO              = $BFF68002 ; // Time out
     IMG1394_ERR_NIMP              = $BFF68003 ; // Function not implemented yet
     IMG1394_ERR_INTL              = $BFF68004 ; // Internal error
     IMG1394_ERR_BMOD              = $BFF68005 ; // Invalid combination of format, video mode, and frame rate for this camera
     IMG1394_ERR_INIT              = $BFF68006 ; // Session not initialized
     IMG1394_ERR_BATT              = $BFF68007 ; // Bad attribute
     IMG1394_ERR_FTNP              = $BFF68008 ; // Feature not present in the camera
     IMG1394_ERR_ESYS              = $BFF68009 ; // System error
     IMG1394_ERR_HEAP              = $BFF6800A ; // Allocation error
     IMG1394_ERR_UNINITIALIZED     = $BFF6800B ; // Allocator is not initialized
     IMG1394_ERR_ORNG              = $BFF6800C ; // Value is out of range
     IMG1394_ERR_BCAM              = $BFF6800D ; // Bad camera file
     IMG1394_ERR_BSID              = $BFF6800E ; // Invalid Session ID
     IMG1394_ERR_NSUP              = $BFF6800F ; // Attribute not supported by the camera
     IMG1394_ERR_INVF              = $BFF68010 ; // Format is invalid
     IMG1394_ERR_INVM              = $BFF68011 ; // Video mode is invalid
     IMG1394_ERR_INVR              = $BFF68012 ; // Frame rate is invalid
     IMG1394_ERR_INVC              = $BFF68013 ; // Color ID is invalid
     IMG1394_ERR_NOAP              = $BFF68014 ; // No acquisition in progress
     IMG1394_ERR_AOIP              = $BFF68015 ; // Acquisition is already in progress
     IMG1394_ERR_IRES              = $BFF68016 ; // Insufficient resources available for the required video mode
     IMG1394_ERR_TBUF              = $BFF68017 ; // Too many buffers used
     IMG1394_ERR_INVP              = $BFF68018 ; // Invalid parameter
     IMG1394_ERR_NSAT              = $BFF68019 ; // Non-writable attribute
     IMG1394_ERR_NGAT              = $BFF6801A ; // Non-readable attribute
     IMG1394_ERR_CMNF              = $BFF6801B ; // Camera not found
     IMG1394_ERR_CRMV              = $BFF6801C ; // Camera has been removed
     IMG1394_ERR_BNRD              = $BFF6801D ; // Buffer not ready
     IMG1394_ERR_BRST              = $BFF6801E ; // A bus reset occured in the middle of a transaction
     IMG1394_ERR_NLIC              = $BFF6801F ; // Unlicensed copy of NI-IMAQ for IEEE 1394
     IMG1394_ERR_NDLL              = $BFF68020 ; // CVI only error. DLL could not be found
     IMG1394_ERR_NFNC              = $BFF68021 ; // CVI only error. Function not found in DLL
     IMG1394_ERR_NOSR              = $BFF68022 ; // CVI only error. No resource available
     IMG1394_ERR_NCFG              = $BFF68023 ; // Session not configured
     IMG1394_ERR_IOER              = $BFF68024 ; // I/O error
     IMG1394_ERR_CAIU              = $BFF68025 ; // Camera is already in use
     IMG1394_ERR_BAD_POINTER       = $BFF68026 ; // Bad pointer. The pointer may be NULL when it should be non-NULL, or it may be non-NULL when it should be NULL.
     IMG1394_ERR_EXCEPTION         = $BFF68027 ; // An exception has occured. Check the NI-PAL debug log for more information.
     IMG1394_ERR_BAD_DEVICE_TYPE   = $BFF68028 ; // The type of device is invalid. Unable to create an instance.
     IMG1394_ERR_ASYNC_READ        = $BFF68029 ; // Unable to perform asychronous register read. The device may be busy or broken.
     IMG1394_ERR_ASYNC_WRITE       = $BFF6802A ; // Unable to perform asychronous register write. The device may be busy or broken.
     IMG1394_ERR_VIDEO_NOT_SUPPORTED = $BFF6802B ; // The combination of video format, mode, and rate is not supported for this camera. Please consult your camera documentation.
     IMG1394_ERR_BUFFER_INDEX      = $BFF6802C ; // The index into the buffer list is incorrect. Reconfigure and try again.
     IMG1394_ERR_BAD_USER_ROI      = $BFF6802D ; // The camera cannot acquire the user ROI. Resize and try again.
     IMG1394_ERR_BUFFER_LIST_ALREADY_LOCKED = $BFF6802E ; // The buffer list is already locked. Reconfigure the acquisition and try again.
     IMG1394_ERR_BUFFER_LIST_NOT_LOCKED = $BFF6802F ; // There is no buffer list. Reconfigure the acquisition and try again.
     IMG1394_ERR_RESOURCES_ALREADY_ALLOCATED = $BFF68030 ; // The isochronous resources have already been allocated. Reconfigure the acquisition and try again.
     IMG1394_ERR_BUFFER_LIST_EMPTY = $BFF68031 ; // The buffer list is empty. Add at least one buffer.
     IMG1394_ERR_FLAG_1            = $BFF68032 ; // For format 7: The combination of speed, image position, image size, and color coding is incorrect.
     IMG1394_ERR_BUFFER_NOT_AVAILABLE = $BFF68033 ; // The requested buffer is unavailable. The contents of the current buffer has been overwritten by the acquistion.
     IMG1394_ERR_IMAGE_REP_NOT_SUPPORTED = $BFF68034 ; // The requested image representation is not supported for the current color coding.
     IMG1394_ERR_BAD_OCCURRENCE    = $BFF68035 ; // The given occurrence is not valid. Unable to complete image acquistion.


    IMG1394_StandardFormats : Array[0..7] of String = (
    'VGA non-compressed format',
    'Super VGA non-compressed format #1',
    'Super VGA non-compressed format #2',
    'Unknown',
    'Unknown',
    'Unknown',
    'Still image format',
    'Partial image size format' ) ;

    IMG1394_StandardFrameRates : Array[0..7] of Double = (
    1.875,
    3.75,
    7.5,
    15.0,
    30.0,
    60.0,
    1.0,
    1.0 ) ;

type

//==============================================================================
//  Attribute ranges
//==============================================================================
    TTriggerPolarity = (
    IMG1394_TRIG_POLAR_ACTIVEL,
    IMG1394_TRIG_POLAR_ACTIVEH,
    IMG1394_TRIG_POLAR_DEFAULT ) ;

    TTriggerMode = (
    IMG1394_TRIG_DISABLE,
    IMG1394_TRIG_MODE0,
    IMG1394_TRIG_MODE1,
    IMG1394_TRIG_MODE2,
    IMG1394_TRIG_MODE3,
    IMG1394_TRIG_MODE4,
    IMG1394_TRIG_MODE5 ) ;

    TColorCoding  = (
    IMG1394_COLORID_DEFAULT,
    IMG1394_COLORID_MONO8,
    IMG1394_COLORID_YUV411,
    IMG1394_COLORID_YUV422,
    IMG1394_COLORID_YUV444,
    IMG1394_COLORID_RGB8,
    IMG1394_COLORID_MONO16,
    IMG1394_COLORID_RGB16,
    IMG1394_COLORID_SIGNED_MONO16,
    IMG1394_COLORID_SIGNED_RGB16,
    IMG1394_COLORID_RAW8,
    IMG1394_COLORID_RAW16
    );


    TColorFilter  = (
    IMG1394_COLOR_FILTER_NONE,
    IMG1394_COLOR_FILTER_GBGB_RGRG,
    IMG1394_COLOR_FILTER_GRGR_BGBG,
    IMG1394_COLOR_FILTER_BGBG_GRGR,
    IMG1394_COLOR_FILTER_RGRG_GBGB
    );


    TEvent  = (
    IMG1394_EVENT_FRAME_DONE,
    IMG1394_EVENT_CAMERA_ATTACHED,
    IMG1394_EVENT_CAMERA_DETACHED,
    IMG1394_EVENT_ALL
    );

    TSpeed  = (
    IMG1394_SPEED_DEFAULT,
    IMG1394_SPEED_100,
    IMG1394_SPEED_200,
    IMG1394_SPEED_400,
    IMG1394_SPEED_800,
    IMG1394_SPEED_1600,
    IMG1394_SPEED_3200
    );

    TImageRepresentation  = (
    IMG1394_IMAGEREP_DEFAULT,
    IMG1394_IMAGEREP_RAW,
    IMG1394_IMAGEREP_MONO8,
    IMG1394_IMAGEREP_MONO16,
    IMG1394_IMAGEREP_RGB32,
    IMG1394_IMAGEREP_RGB64
    );

    TOnOverwrite  = (
    IMG1394_ONOVERWRITE_GET_OLDEST,
    IMG1394_ONOVERWRITE_GET_NEXT_ITERATION,
    IMG1394_ONOVERWRITE_FAIL,
    IMG1394_ONOVERWRITE_GET_NEWEST
    );

    TCameraMode  = (
    IMG1394_CAMERA_MODE_CONTROLLER,
    IMG1394_CAMERA_MODE_LISTENER
    );

    TInterfacFileFlags  = (
    IMG1394_INTERFACE_CONNECTED = $1,
    IMG1394_INTERFACE_DIRTY = $2
    );

    TVideoMode = packed record
      Format : Cardinal ;
      Mode : Cardinal ;
      FrameRate : Cardinal ;
      VideoModeName : Array[0..63] of Char ;
      end ;

    TFeature = packed record
        Min : Cardinal ;
        Max : Cardinal ;
        AutoMode : Cardinal ;
        OnePush : Cardinal ;
        Enable : Cardinal ;
        Attribute : Cardinal ;
        Current_Value : Cardinal ;
        Default_Value : Cardinal ;
        Readable : Cardinal ;
        OnOff : Cardinal ;
        FeatureName : Array[0..63] of Char ;
        end ;

    TFeature2 = packed record
      Enable : Cardinal ;
      iAbsolute : Cardinal ;
      OnePush : Cardinal ;
      Readable : Cardinal ;
      OnOff : Cardinal ;
      Auto : Cardinal ;
      Manual : Cardinal ;
      Relative_Min_Value : Cardinal ;
      Relative_Max_Value : Cardinal ;
      Relative_Current_Value : Cardinal ;
      Relative_Default_Value : Cardinal ;
      Relative_Attribute : Cardinal ;
      Absolute_Min_Value : Double ;
      Absolute_Max_Value : Double ;
      Absolute_Current_Value : Double ;
      Absolute_Default_Value : Double ;
      Absolute_Attribute : Cardinal ;
      FeatureName : Array[0..63] of Char ;
      end ;

    TImageRect = packed record
      top : Integer ;
      left : Integer ;
      height : Integer ;
      width : Integer ;
      end ;

    TIntefaceFile = packed record
      iType : Cardinal ;
      Version : Cardinal ;
      Flags : Cardinal ;
      SerialNumberHi : Cardinal ;
      SerialNumberLo : Cardinal ;
      InterfaceName : Array[0..63] of Char ;
      VendorName : Array[0..63] of Char ;
      ModelName : Array[0..63] of Char ;
      CameraFileName : Array[0..63] of Char ;
      end ;

    TCameraFile = packed record
      iType : Cardinal ;
      Version : Cardinal ;
      FileName : Array[0..63] of Char ;
      end ;

    TIMAQ1394Session = packed record
    ID : Integer ;
    Format : Cardinal ;
    Mode : Cardinal ;
    VideoModes : Array[0..199] of TVideoMode ;
    NumVideoModes : Cardinal ;
    MonoVideoModes : Array[0..199] of TVideoMode ;
    NumMonoVideoModes : Cardinal ;
    pFrameBuffer : Pointer ;
    FrameCounter : Integer ;
    NumFramesInBuffer : Integer ;
    NumBytesPerFrame : Integer ;
    IMAQFrameCounter : Integer ;
    GetImageInUse : Boolean ;
    AcquisitionInProgress : Boolean ;
    end ;

PIMAQ1394Session = ^TIMAQ1394Session ;


Timaq1394AttributeInquiry = function (
                      SessionID : Integer ;
                      Attribute : Cardinal ;
                      Var MinimumValue : Cardinal ;
                      Var maximumValue : Cardinal ;
                      Var readable : Cardinal ;
                      Var autoMode : Cardinal ;
                      Var enable : Cardinal
                      ) : Integer ; stdcall ;

Timaq1394CameraOpen = function(
                     camera_name : PChar ;
                     Var SESSION_ID : Integer
                     ) : Integer ; stdcall ;

Timaq1394CameraOpen2 = function(
                       camera_name : PChar ;
                       Mode : TCameraMode ;
                       Var SESSION_ID : Integer
                       ) : Integer ; stdcall ;

Timaq1394Close = function(
                     SESSION_ID : Integer
                     ) : Integer ; stdcall ;


Timaq1394ConfigEventMessage = function (
                      SessionID : Integer ;
                      event : Integer ;
                      var windowHandle : Integer ;
                      windowsMessageNumber : Integer ;
                      Parameter : Pointer ) : Integer ; stdcall ;

Timaq1394GetAttribute = function (
                        SessionID : Integer ;
                        Attribute : Cardinal ;
                        PValue : Pointer
                        ) : Integer ; stdcall ;

Timaq1394GetBuffer = function (
                   SessionID : Integer ;
                  ImageIndex : Cardinal ;
                  Var Buffer : Pointer
                  ) : Integer ; stdcall ;

Timaq1394GetBuffer2 = function (
                   SessionID : Integer ;
                   BufferNumberDesired : Cardinal ;
                   var BufferNumberActual : Cardinal ;
                   OnOverwrite : TOnOverwrite ;
                   Var Buffer : Pointer
                  ) : Integer ; stdcall ;

Timaq1394ConfigureAcquisition = function (
                   SessionID : Integer ;
                   Continuous : Cardinal ;
                   Number_ofImages : Cardinal ;
                   Rect : TImageRect
                   ) : Integer ; stdcall ;

Timaq1394GetFeatures = function (
                       SessionID : Integer ;
                       Feature : Pointer ;
                       var Feature_array_size : Cardinal
                       ) : Integer ; stdcall ;

Timaq1394GetFeatures2 = function (
                       SessionID : Integer ;
                       Feature : Pointer ;
                       var Feature_array_size : Cardinal
                       ) : Integer ; stdcall ;

Timaq1394GetImage  = function (
                     SessionID : Integer ;
                     ImageIndex : Cardinal ;
                     Image : Pointer
                     ) : Integer ; stdcall ;

Timaq1394GetVideoModes  = function (
                     SessionID : Integer ;
                     VideoMode : Pointer ;
                     var videoMode_array_size : Cardinal ;
                     var CurrentMode: Cardinal
                     ) : Integer ; stdcall ;

Timaq1394Grab  = function (
                 SessionID : Integer ;
                 var Buffer : Pointer
                 ) : Integer ; stdcall ;

Timaq1394Grab2  = function (
                 SessionID : Integer ;
                 waitForNextBuffer : Cardinal ;
                 var bufferNumberActual : Cardinal ;
                 var Buffer : Pointer
                 ) : Integer ; stdcall ;

Timaq1394GrabImage = function (
                 SessionID : Integer ;
                 Image : Pointer  ) : Integer ; stdcall ;

Timaq1394Plot = function (
                GUIHNDL : THandle ;
                Buffer : Pointer ;
                bufferOffsetLeft : Cardinal ;
                BufferOffsetTop : Cardinal ;
                pixelWidth_of_buffer : Cardinal ;
                pixelHeight_of_buffer : Cardinal ;
                XPosition_inWindow : SmallInt ;
                YPosition_inWindow : Cardinal ;
                Flags : Cardinal  ) : Integer ; stdcall ;

Timaq1394PlotDC = function (
                GUIHNDL : THandle ;
                Buffer : Pointer ;
                bufferOffsetLeft : Cardinal ;
                BufferOffsetTop : Cardinal ;
                pixelWidth_of_buffer : Cardinal ;
                pixelHeight_of_buffer : Cardinal ;
                XPosition_inWindow : SmallInt ;
                YPosition_inWindow : Cardinal ;
                Flags : Cardinal  ) : Integer ; stdcall ;

Timaq1394SetAttribute = function (
                        SessionID : Integer ;
                        Attribute : Cardinal ;
                        Value : Cardinal
                        ) : Integer ; stdcall ;

Timaq1394SetupGrab = function (
                     SessionID : Integer ;
                     Rect : TRect
                     ) : Integer ; stdcall ;

Timaq1394SetupSequence = function (
                     SessionID : Integer ;
                     var Buffers : Pointer ;
                     number_ofImages : Cardinal ;
                     skipCount : Integer ;
                     Rect : TRect ) : Integer ; stdcall ;

Timaq1394SetupSequenceImage = function (
                     SessionID : Integer ;
                     var Buffers : Pointer ;
                     number_ofImages : Cardinal ;
                     skipCount : Integer ;
                     Rect : TRect ) : Integer ; stdcall ;

Timaq1394ShowError = function (
                     IMAQ_ERR : Integer ;
                     var TextMessage : Array of Char ;
                     textLength : Cardinal ) : Integer ; stdcall ;

Timaq1394Snap = function (
                SessionID : Integer ;
                Buffer : Pointer ;
                Rect : TRect ) : Integer ; stdcall ;

Timaq1394SnapImage = function (
                SessionID : Integer ;
                Buffer : Pointer ;
                Rect : TRect ) : Integer ; stdcall ;

Timaq1394ClearAcquisition = function (
                SessionID : Integer
                ) : Integer ; stdcall ;


Timaq1394StartAcquisition = function (
                SessionID : Integer
                ) : Integer ; stdcall ;

Timaq1394StopAcquisition = function (
                SessionID : Integer
                ) : Integer ; stdcall ;

Timaq1394TriggerConfigure = function (
                SessionID : Integer ;
                Polarity : Cardinal ;
                TimeOut : Cardinal ;
                TriggerMode : Cardinal ;
                OptionalParameter : Cardinal
                ) : Integer ; stdcall ;

Timaq1394InstallCallback  = function (
                SessionID : Integer ;
                Event : Cardinal ;
                callBackFunction : Pointer ;
                Parameter : Pointer
                ) : Integer ; stdcall ;

function IMAQ1394_OpenCamera(
          var Session : TIMAQ1394Session ;
          var FrameWidthMax : Integer ;
          var FrameHeightMax : Integer ;
          var NumBytesPerPixel : Integer ;
          var PixelDepth : Integer ;
          CameraInfo : TStringList
          ) : Boolean ;

procedure IMAQ1394_CloseCamera(
          var Session : TIMAQ1394Session
          ) ;

function IMAQ1394_StartCapture(
         var Session : TIMAQ1394Session ;
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

procedure IMAQ1394_StopCapture(
          var Session : TIMAQ1394Session              // Camera session #
          ) ;

procedure IMAQ1394_GetImage(
          var Session : TIMAQ1394Session
          ) ;

procedure IMAQ1394_GetCameraGainList( CameraGainList : TStringList ) ;

procedure IMAQ1394_GetCameraVideoMode(
          var Session : TIMAQ1394Session ;
          MonoOnly : Boolean ;
          CameraVideoModeList : TStringList
          ) ;

function IMAQ1394_CheckFrameInterval(
          var Session : TIMAQ1394Session ;
          var FrameInterval : Double ) : Integer ;

procedure IMAQ1394_LoadLibrary  ;
function IMAQ1394_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

function IMAQ1394_GetStringAttribute(
         var Session : TIMAQ1394Session ;
         AttributeID : Integer
         ) : String ;

function IMAQ1394_GetIntAttribute(
         var Session : TIMAQ1394Session ;
         AttributeID : Integer
         ) : Integer ;

procedure IMAQ1394_SetIntAttribute(
          var Session : TIMAQ1394Session ;
          AttributeID : Integer ;
          Value : Cardinal
          )  ;

procedure IMAQ1394_CheckError( ErrNum : Integer ) ;

function IMAQ1394_CharArrayToString( cBuf : Array of Char ) : String ;

var
   Imaq1394AttributeInquiry : Timaq1394AttributeInquiry ;
   Imaq1394CameraOpen : Timaq1394CameraOpen ;
   Imaq1394CameraOpen2 : Timaq1394CameraOpen2 ;
   Imaq1394Close : Timaq1394Close ;
   imaq1394ConfigEventMessage : Timaq1394ConfigEventMessage ;
   imaq1394GetAttribute : Timaq1394GetAttribute ;
   imaq1394GetBuffer : Timaq1394GetBuffer ;
   imaq1394GetBuffer2 : Timaq1394GetBuffer2 ;
   imaq1394ConfigureAcquisition : Timaq1394ConfigureAcquisition ;
   imaq1394GetFeatures : Timaq1394GetFeatures ;
   imaq1394GetFeatures2 : Timaq1394GetFeatures2 ;
   imaq1394GetImage : Timaq1394GetImage ;
   imaq1394GetVideoModes : Timaq1394GetVideoModes ;
   imaq1394Grab : Timaq1394Grab ;
   imaq1394Grab2 : Timaq1394Grab2 ;
   imaq1394GrabImage : Timaq1394GrabImage ;
   imaq1394Plot : Timaq1394Plot ;
   imaq1394PlotDC : Timaq1394PlotDC ;
   imaq1394SetAttribute : Timaq1394SetAttribute ;
   imaq1394SetupGrab : Timaq1394SetupGrab ;
   imaq1394SetupSequence : Timaq1394SetupSequence ;
   imaq1394SetupSequenceImage : Timaq1394SetupSequenceImage ;
   imaq1394ShowError : Timaq1394ShowError ;
   imaq1394Snap : Timaq1394Snap ;
   imaq1394SnapImage : Timaq1394SnapImage ;
   imaq1394ClearAcquisition : Timaq1394ClearAcquisition ;
   imaq1394StartAcquisition : Timaq1394StartAcquisition ;
   imaq1394StopAcquisition : Timaq1394StopAcquisition ;
   imaq1394TriggerConfigure : Timaq1394TriggerConfigure ;
   imaq1394InstallCallback  : Timaq1394InstallCallback ;

implementation

uses sescam ;
var
    LibraryHnd : THandle ;         // PVCAM32.DLL library handle
    LibraryLoaded : boolean ;      // PVCAM32.DLL library loaded flag
    Buf : Array[0..10000000] of Byte ;

procedure IMAQ1394_LoadLibrary  ;
{ -------------------------------------
  Load IMAQ1394.DLL library into memory
  -------------------------------------}
var
    LibFileName : string ;
begin

     { Load PVCAM32 interface DLL library }
     LibFileName := 'IMAQ1394.DLL' ;
     LibraryHnd := LoadLibrary( PChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @Imaq1394AttributeInquiry := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394AttributeInquiry') ;
        @Imaq1394CameraOpen := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394CameraOpen') ;
        @Imaq1394CameraOpen2 := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394CameraOpen2') ;
        @Imaq1394Close := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394Close') ;
        @Imaq1394GetFeatures := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetFeatures') ;
        @Imaq1394GetFeatures2 := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetFeatures2') ;
        @imaq1394ConfigEventMessage := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394ConfigEventMessage') ;
        @imaq1394GetAttribute := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetAttribute') ;
        @imaq1394GetBuffer := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetBuffer') ;
        @imaq1394GetBuffer2 := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetBuffer2') ;
        @imaq1394ConfigureAcquisition := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394ConfigureAcquisition') ;
        @imaq1394GetImage := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetImage') ;
        @imaq1394GetVideoModes := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GetVideoModes') ;
        @imaq1394Grab := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394Grab') ;
        @imaq1394Grab2 := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394Grab2') ;
        @imaq1394GrabImage := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394GrabImage') ;
        @imaq1394Plot := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394Plot') ;
        @imaq1394PlotDC := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394PlotDC') ;
        @imaq1394SetAttribute := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394SetAttribute') ;
        @imaq1394SetupGrab := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394SetupGrab') ;
        @imaq1394SetupSequence := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394SetupSequence') ;
        @imaq1394SetupSequenceImage:= IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394SetupSequenceImage') ;
        @imaq1394ShowError := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394ShowError') ;
        @imaq1394Snap := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394Snap') ;
        @imaq1394SnapImage:= IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394SnapImage') ;
        @imaq1394ClearAcquisition := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394ClearAcquisition') ;
        @imaq1394StartAcquisition := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394StartAcquisition') ;
        @imaq1394StopAcquisition := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394StopAcquisition') ;
        @imaq1394TriggerConfigure := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394TriggerConfigure') ;
        @imaq1394InstallCallback := IMAQ1394_GetDLLAddress(LibraryHnd,'imaq1394InstallCallback') ;
        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'IMAQ1394: ' + LibFileName + ' not found!' ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function IMAQ1394_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within PVCAM32.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       ShowMessage('IMAQ1394.DLL: ' + ProcName + ' not found') ;
    end ;


function IMAQ1394_OpenCamera(
          var Session : TIMAQ1394Session ;   // Camera session
          var FrameWidthMax : Integer ;  // Returns camera frame width
          var FrameHeightMax : Integer ; // Returns camera height width
          var NumBytesPerPixel : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer ;       // Returns no. bits/pixel
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;
// ---------------------
// Open firewire camera
// ---------------------
var
    Vendor : String ;
    Model : String ;
    Err : Integer ;
    Features : Array[0..199] of TFeature2 ;
    NumFeatures : Cardinal ;
    i,j :Integer ;
    iFormat : Integer ;
    Supported : Boolean ;
    s : String ;
begin

     Result := False ;

     // Load DLL libray
     if not LibraryLoaded then IMAQ1394_LoadLibrary  ;
     if not LibraryLoaded then Exit ;

     // Open camera
     Err := Imaq1394CameraOpen2( 'cam0', IMG1394_CAMERA_MODE_CONTROLLER, Session.ID ) ;
     IMAQ1394_CheckError( Err ) ;
     if Err <> 0 then Exit ;

     // Get name of camera
     Vendor := IMAQ1394_GetStringAttribute( Session, IMG1394_ATTR_VENDOR_NAME ) ;
     Model := IMAQ1394_GetStringAttribute( Session, IMG1394_ATTR_MODEL_NAME ) ;
     CameraInfo.Add('Camera: ' + Vendor + ' ' + Model ) ;

     NumBytesPerPixel := IMAQ1394_GetIntAttribute( Session, IMG1394_ATTR_BYTES_PER_PIXEL ) ;
     PixelDepth := 8*NumBytesPerPixel ;
     FrameWidthMax := IMAQ1394_GetIntAttribute( Session, IMG1394_ATTR_IMAGE_WIDTH ) ;
     FrameHeightMax := IMAQ1394_GetIntAttribute( Session, IMG1394_ATTR_IMAGE_HEIGHT ) ;
     CameraInfo.Add(format('Image size: %d x %d pixels (%d bits/pixel)',
                    [FrameWidthMax,FrameHeightMax,PixelDepth])) ;

     // Clear mode name field
     for i := 0 to High(Session.VideoModes) do
        for j := 0 to High(Session.VideoModes[i].VideoModeName) do
            Session.VideoModes[i].VideoModeName[j] := #0 ;

     // Get video modes supported by camera
     IMAQ1394_CheckError( imaq1394GetVideoModes( Session.ID,
                                                 Nil,
                                                 Session.NumVideoModes,
                                                 Session.Mode )) ;
     IMAQ1394_CheckError( imaq1394GetVideoModes( Session.ID,
                                                 @Session.VideoModes,
                                                 Session.NumVideoModes,
                                                 Session.Mode )) ;

     // Get Monochrome video modes
     Session.NumMonoVideoModes := 0 ;
     for i := 0 to Session.NumVideoModes-1 do begin
         if Pos('mono',
            LowerCase(IMAQ1394_CharArrayToString( Session.VideoModes[i].VideoModeName))) > 0 then begin
            Session.MonoVideoModes[Session.NumMonoVideoModes] := Session.VideoModes[i] ;
            Session.NumMonoVideoModes := Session.NumMonoVideoModes + 1 ;
            end ;
         end ;

     // Get current video format and mode of camera
     Session.Format := IMAQ1394_GetIntAttribute( Session, IMG1394_ATTR_VIDEO_FORMAT ) ;
     Session.Mode := IMAQ1394_GetIntAttribute( Session, IMG1394_ATTR_VIDEO_MODE ) ;

     // Report supported camera formats
     CameraInfo.Add( '' );
     CameraInfo.Add( 'Formats supported: ' );
     for iFormat := 0 to IMG1394_VIDEO_FORMAT_MAX do begin
         Supported := False ;
         for i := 0 to Session.NumVideoModes-1 do
             if Session.VideoModes[i].Format = iFormat then Supported := True ;
         if Supported then begin
            s := format('%s (%d)',[IMG1394_StandardFormats[iFormat],iFormat] ) ;
            if iFormat = Session.Format then s := s + ' *' ;
            CameraInfo.Add(s) ;
            end ;
         end ;

    // Clear feature name field
    for i := 0 to High(Features) do
        for j := 0 to High(Features[i].FeatureName) do
            Features[i].FeatureName[j] := #0 ;

    // Get list camera features
    IMAQ1394_CheckError( imaq1394GetFeatures2( Session.ID, Nil, NumFeatures )) ;
    IMAQ1394_CheckError( imaq1394GetFeatures2( Session.ID, @Features, NumFeatures )) ;

     CameraInfo.Add( '' );
     CameraInfo.Add( 'Features supported: ' );

    // Report features
     for i := 0 to NumFeatures-1 do if Features[i].Enable = 1 then begin
         if Features[i].iAbsolute = 1 then begin
            s := format('%s = %.4g (%.4g-%.4g, def=%4g) ',
                 [ IMAQ1394_CharArrayToString( Features[i].FeatureName),
                 Features[i].Absolute_Current_Value,
                 Features[i].Absolute_Min_Value,
                 Features[i].Absolute_Max_Value,
                 Features[i].Absolute_Default_Value]) ;
                 end
         else begin
            s := format('%s = %d (%d-%d, def=%d) ',
                 [ IMAQ1394_CharArrayToString( Features[i].FeatureName),
                 Features[i].Relative_Current_Value,
                 Features[i].Relative_Min_Value,
                 Features[i].Relative_Max_Value,
                 Features[i].Relative_Default_Value]) ;
                 end ;

         CameraInfo.Add( s ) ;
         end ;

     // Clear flags
     Session.AcquisitionInProgress := False ;
     Result := True ;

     end ;


function IMAQ1394_GetStringAttribute(
         var Session : TIMAQ1394Session ;
         AttributeID : Integer
         ) : String ;
// -----------------------------------
// Return string type camera attribute
// -----------------------------------
var
     cBuf : Array[0..255] of Char ;
     i : Integer ;
begin

    for i := 0 to High(CBuf) do CBuf[i] := #0 ;
    iMaq1394GetAttribute( Session.ID, AttributeID , @CBuf) ;
    Result := '' ;
    for i := 0 to High(CBuf) do if CBuf[i] <> #0 then Result := Result + CBuf[i] ;
    End ;


function IMAQ1394_GetIntAttribute(
         var Session : TIMAQ1394Session ;
         AttributeID : Integer
         ) : Integer ;
// -----------------------------------
// Return string type camera attribute
// -----------------------------------
var
     Value : Cardinal ;
     i : Integer ;
begin
    iMaq1394GetAttribute( Session.ID, AttributeID , @Value ) ;
    Result := Value ;
    End ;


procedure IMAQ1394_SetIntAttribute(
          var Session : TIMAQ1394Session ;
          AttributeID : Integer ;
          Value : Cardinal
          )  ;
// -----------------------------------
// Set integer type camera attribute
// -----------------------------------
begin
    IMAQ1394_CheckError( iMaq1394SetAttribute( Session.ID, AttributeID , Value )) ;
    End ;


procedure IMAQ1394_CloseCamera(
          var Session : TIMAQ1394Session     // Camera session #
          ) ;
// ----------------
// Shut down camera
// ----------------
begin

    // Stop any acquisition
    IMAQ1394_StopCapture( Session ) ;

    // Close session
    IMAQ1394_CheckError( imaq1394Close( Session.ID )) ;

    end ;


function IMAQ1394_StartCapture(
         var Session : TIMAQ1394Session ;          // Camera session #
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
     cNumIMAQbuffers = 16 ;
var
    Err : Integer ;
    ImageArea : TImageRect ;
    FrameRateNum : Cardinal ;
begin

    // Stop any acquisition which is in progress
    if Session.AcquisitionInProgress then begin
       // Clear acquisition settings
       IMAQ1394_CheckError(imaq1394StopAcquisition( Session.ID )) ;
       Session.AcquisitionInProgress := false ;
       end ;

    // Clear acquisition settings
    IMAQ1394_CheckError(imaq1394ClearAcquisition( Session.ID )) ;

     // Internal/external triggering of frame capture
     if ExternalTrigger = CamFreeRun then begin
        end
     else begin
        end ;

     // Set camera gain
     IMAQ1394_SetIntAttribute( Session,
                               IMG1394_ATTR_GAIN,
                               AmpGain ) ;

     // Set frame acquisition rate
     // (Note. must be done before call to imaq1394ConfigureAcquisition)
     FrameRateNum := IMAQ1394_CheckFrameInterval( Session, ExposureTime ) ;
     IMAQ1394_SetIntAttribute( Session,
                               IMG1394_ATTR_VIDEO_FRAME_RATE,
                               FrameRateNum ) ;

     // Configure acquisition
     ImageArea.Left := FrameLeft ;
     ImageArea.Top := FrameTop ;
     ImageArea.Width := FrameWidth ;
     ImageArea.Height := FrameHeight ;
     IMAQ1394_CheckError( imaq1394ConfigureAcquisition(
                          Session.ID,
                          1,
                          cNumIMAQbuffers,
                          ImageArea )) ;

     // Initialise frame ring buffer
     Session.pFrameBuffer := pFrameBuffer ;
     Session.NumFramesInBuffer := NumFramesInBuffer ;
     Session.FrameCounter := 0 ;
     Session.IMAQFrameCounter := 0 ;
     Session.NumBytesPerFrame := NumBytesPerFrame ;

     // Start acquiring images
     IMAQ1394_CheckError( imaq1394StartAcquisition( Session.ID )) ;

     Result := True ;
     Session.AcquisitionInProgress := True ;
     Session.GetImageInUse := False ;

     end;


procedure IMAQ1394_StopCapture(
          var Session : TIMAQ1394Session            // Camera session #
          ) ;
// ------------------
// Stop frame capture
// ------------------
begin

     if not Session.AcquisitionInProgress then Exit ;

     // Stop acquisition
     IMAQ1394_CheckError( imaq1394StopAcquisition( Session.ID )) ;

     Session.AcquisitionInProgress := False ;

     end;


procedure IMAQ1394_GetImage(
          var Session : TIMAQ1394Session
          ) ;
// -----------------------------------------------------
// Copy images from IMAQ buffer to circular frame buffer
// -----------------------------------------------------
var
    BufPointer : Pointer ;
    i,NumCopied : Cardinal ;
    LatestFrameTransferred : Integer ;
    ActualFrameNum : Cardinal ;
    Err : Integer ;
    t0 :Integer ;
    AcqInProgress :Integer ;

begin

    if Session.GetImageInUse then Exit ;
    Session.GetImageInUse := True ;
    t0 := timegettime ;

    // Get latest cumulative frame number acquired
    imaq1394GetAttribute( Session.ID,
                          IMG1394_ATTR_LAST_TRANSFERRED_BUFFER_NUM,
                          @LatestFrameTransferred ) ;

   //outputdebugString(PChar(format('latest frame transferred %d ',[LatestFrameTransferred]))) ;

    // Exit if latest buffer no. is invalid
    if LatestFrameTransferred < 0 then begin
        Session.GetImageInUse := False ;
       Exit ;
       end ;

    NumCopied := 0 ;
    while (LatestFrameTransferred > Session.IMAQFrameCounter) and
          (NumCopied < Session.NumFramesInBuffer) do begin

          // Copy image from internal buffer to circular FrameBuf
          BufPointer := Pointer( Integer(Session.pFrameBuffer) +
                                 Session.FrameCounter*Session.NumBytesPerFrame ) ;
          Err := imaq1394GetBuffer2( Session.ID,
                                     Session.IMAQFrameCounter,
                                     ActualFrameNum,
                                     IMG1394_ONOVERWRITE_GET_NEWEST,
                                     BufPointer );
          IMAQ1394_CheckError( Err ) ;

     //     outputdebugString(PChar(format('%d %d',[Session.FrameCounter,Buf[0]]))) ;

          // Increment frame counters
          Inc(Session.IMAQFrameCounter) ;
          Inc(Session.FrameCounter) ;
          if Session.FrameCounter >= Session.NumFramesInBuffer then Session.FrameCounter := 0 ;

          // Increment number of frame transferred this call
          Inc(NumCopied) ;

          end ;

    Session.GetImageInUse := False ;

    end ;


procedure IMAQ1394_GetCameraGainList( CameraGainList : TStringList ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
var
    i : Integer ;
begin
    CameraGainList.Clear ;
    for i := 1 to 255 do CameraGainList.Add( format( '%d',[i] )) ;
    end ;


procedure IMAQ1394_GetCameraVideoMode(
          var Session : TIMAQ1394Session ;
          MonoOnly : Boolean ;
          CameraVideoModeList : TStringList
          ) ;
// -------------------------------------------
// Get list of available camera readout speeds
// -------------------------------------------
var
    i : Integer ;
    iFormat : Integer ;
    iMode : Integer ;
    Found : Boolean ;
begin

   if MonoOnly then begin
        // Monochrome modes
        for iFormat := 0 to IMG1394_VIDEO_FORMAT_MAX do
            for iMode := 0 to IMG1394_VIDEO_MODE_MAX do begin
                Found := False ;
                for i := 0 to Session.NumMonoVideoModes-1 do
                    if (Session.MonoVideoModes[i].Format = iFormat) and
                       (Session.MonoVideoModes[i].Mode = iMode) and
                       not Found then begin
                       CameraVideoModeList.Add( IMAQ1394_CharArrayToString(
                                                Session.MonoVideoModes[i].VideoModeName ) ) ;
                       Found := True ;
                       end ;
                end ;
        end
   else begin
        // All modes
        for iFormat := 0 to IMG1394_VIDEO_FORMAT_MAX do
            for iMode := 0 to IMG1394_VIDEO_MODE_MAX do begin
                Found := False ;
                for i := 0 to Session.NumVideoModes-1 do
                    if (Session.VideoModes[i].Format = iFormat) and
                       (Session.VideoModes[i].Mode = iMode) and
                       not Found then begin
                       CameraVideoModeList.Add( IMAQ1394_CharArrayToString(
                                                Session.VideoModes[i].VideoModeName ) ) ;
                       Found := True ;
                       end ;
                end ;
        end ;
    end ;


function IMAQ1394_CheckFrameInterval(
         var Session : TIMAQ1394Session ;
         var FrameInterval : Double
         ) : Integer ;
//
// Check that selected frame interval is valid
// -------------------------------------------
//
var
    FrameRate : Double ; // Frame acquisition rate (Hz)
    Diff : Double ; // Difference between required and standard rate
    MinDiff : Double ; // Minimum difference
    NearestRate : Integer ; // Index of nearest standard frame rate
    FrameRateNum : Integer ;
    i : Integer ;
begin

     if  FrameInterval <> 0.0 then FrameRate := 1.0 / FrameInterval
                              else FrameRate := 0.0 ;

     MinDiff := 1E30 ;
     for i := 0 to Session.NumVideoModes do begin
         if (Session.VideoModes[i].Format = Session.Format) and
            (Session.VideoModes[i].Mode = Session.Mode) then begin
            FrameRateNum := Session.VideoModes[i].FrameRate ;
            Diff := Abs(IMG1394_StandardFrameRates[FrameRateNum] - FrameRate) ;
            if Diff < MinDiff then begin
               NearestRate := FrameRateNum ;
               MinDiff := Diff ;
               end ;
            end ;
         end ;
     Result := NearestRate ;
     FrameInterval := 1.0 / IMG1394_StandardFrameRates[NearestRate] ;

     end ;


procedure IMAQ1394_CheckError( ErrNum : Integer ) ;
// ------------
// Report error
// ------------
var
    cBuf : Array[0..255] of Char ;
    i : Integer ;
    s : string ;
begin
    if ErrNum <> 0 then begin
       for i := 0 to High(cBuf) do cBuf[i] := #0 ;
       imaq1394ShowError ( ErrNum, cBuf, High(cBuf) ) ;
       s := '' ;
       for i := 0 to High(cBuf) do if cBuf[i] <> #0 then s := s + cBuf[i] ;
       MessageDlg( 'IMAQ1394: ' + s, mtWarning, [mbOK], 0 ) ;
       end ;
    end ;


function IMAQ1394_CharArrayToString(
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
