unit AndorSDK3Unit;
// -------------------------------
// Andor SDK V3 Interface library
// -------------------------------
// 02.05.13 Started
// 23.05.13 JD Tested with Zyla.
//          280MHZ (not 560 MHZ) is max. readout rate available
//          Unable to keep up image stream at highest rates
//          Unable to set cooling on
//          Overlap mode appears to have no effect

interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, messages, controls, math, strutils ;
const
    AndorSDK3MaxBufs = 10240 ;
    AndorSDK3AOIHeightSteps = 2 ;
type

TAndorSDK3Session = record
     CamHandle : Integer ;
     NumBytesPerFrame : Integer ;     // No. of bytes in image
     NumFramesInBuffer : Integer ;    // No. of images in circular transfer buffer
     FramePointer : Integer ;         // Current frame no.
     PFrameBuffer : PWordArray ;         // Pointer to start of image destination buffer
     pBuf : Array[0..AndorSDK3MaxBufs-1] of PWordArray ;    // Pointers to internal image buffers
     pBuf64 : Array[0..AndorSDK3MaxBufs-1] of PWordArray  ;  // Pointer aligned on 8 byte boundary
     NumBytesPerFrameBuffer : Int64 ;                // No. of bytes in image buffer
     NumFramesAcquired : Integer ;
     GetImageInUse : LongBool ;       // GetImage procedure running
     CapturingImages : LongBool ;     // Image capture in progress
     CameraOpen : LongBool ;          // Camera open for use
     TimeStart : single ;
     Temperature : Integer ;
     WorkingTemperature : Double ;

     FrameLeft : Integer ;            // Left pixel in CCD readout area
     FrameTop : Integer ;             // Top pixel in CCD eadout area
     FrameRight : Integer ;           // Width of CCD readout area
     FrameBottom : Integer ;          // Width of CCD readout area
     BinFactor : Integer ;             // Binning factor (1,2,4,8,16)

     AOIWidth : Integer ;
     AOIHeight : Integer ;
     AOIRowSpacing : Integer ;
     ImageEnd : Integer ;
     AOINumPixels : Integer ;

     ReadoutSpeed : Integer ;
     CameraMode : Integer ;
     LibFileName : String ;
     ReadoutRate : Integer ;
     ReadoutRateList : TStringList ;
     PixelEncodingList : TStringList ;
     ADCNum : Integer ;
     ADConverterList : TStringList ;
     BinFactorList : TStringList ;
     Mode : Integer ;
     ModeList : TStringList ;
     TemperatureSettingsList : TStringList ;
     NumCameraTaps : Integer ;
     end ;

PAndorSDK3Session = ^TAndorSDK3Session ;

TAT_InitialiseLibrary = Function() : Integer ; stdcall ;
TAT_FinaliseLibrary = Function() : Integer ; stdcall ;

TAT_Open = Function( CameraIndex : Integer ;
                     var AT_H : Integer
                     ) : Integer ; stdcall ;

TAT_Close = Function( AT_H : Integer ) : Integer ; stdcall ;

//typedef int  = Function(AT_EXP_CONV *FeatureCallback) : Integer ; stdcall ; = Function(AT_H : Integer ;, const AT_WC* Feature, void* Context) : Integer ; stdcall ;

TAT_RegisterFeatureCallback = Function(
                              CamHandle : Integer ;
                              const Feature : PWideChar ;
                              EvCallback : Pointer ;
                              Context : Pointer
                              ) : Integer ; stdcall ;

TAT_UnregisterFeatureCallback = Function(
                                CamHandle : Integer ;
                                const Feature : PWideChar ;
                                EvCallback : Pointer ;
                                Context : Pointer
                                ) : Integer ; stdcall ;

TAT_IsImplemented = Function(
                    CamHandle : Integer ;
                    const Feature : PWideChar ;
                    var Implemented : LongBool
                    ) : Integer ; stdcall ;
TAT_IsReadable = Function(
                 CamHandle : Integer ;
                 const Feature : PWideChar ;
                 var Readable : LongBool
                 ) : Integer ; stdcall ;

TAT_IsWritable = Function(
                 CamHandle : Integer ;
                 const Feature : PWideChar ;
                 var Writable : LongBool
                 ) : Integer ; stdcall ;

TAT_IsReadOnly = Function(
                 CamHandle : Integer ;
                 const Feature : PWideChar ;
                 var ReadOnly : LongBool
                 ) : Integer ; stdcall ;

TAT_SetInt = Function(
             CamHandle : Integer ;
             const Feature : PWideChar ;
             Value : Int64
             ) : Integer ; stdcall ;

TAT_GetInt = Function(
             CamHandle : Integer ;
             const Feature : PWideChar ;
             var Value : Int64
             ) : Integer ; stdcall ;

TAT_GetIntMax = Function(
                CamHandle : Integer ;
                const Feature : PWideChar ;
                var MaxValue : Int64
                ) : Integer ; stdcall ;

TAT_GetIntMin = Function(
                CamHandle : Integer ;
                const Feature : PWideChar ;
                var MinValue : Int64
                ) : Integer ; stdcall ;

TAT_SetFloat = Function(
               CamHandle : Integer ;
               const Feature : PWideChar ;
               Value : Double
               ) : Integer ; stdcall ;

TAT_GetFloat = Function(
               CamHandle : Integer ;
               const Feature : PWideChar ;
               var Value : Double
               ) : Integer ; stdcall ;

TAT_GetFloatMax = Function(
                  CamHandle : Integer ;
                  const Feature : PWideChar ;
                  var MaxValue : Double
                  ) : Integer ; stdcall ;

TAT_GetFloatMin = Function(
                  CamHandle : Integer ;
                  const Feature : PWideChar ;
                  var MinValue : Double
                  ) : Integer ; stdcall ;

TAT_SetBool = Function(
              CamHandle : Integer ;
              const Feature : PWideChar ;
              Value : LongBool
              ) : Integer ; stdcall ;

TAT_GetBool = Function(
              CamHandle : Integer ;
              const Feature : PWideChar ;
              var Value : LongBool
              ) : Integer ; stdcall ;

TAT_SetEnumerated = Function(
                    CamHandle : Integer ;
                    const Feature : PWideChar ;
                    Value : Integer
                    ) : Integer ; stdcall ;

TAT_SetEnumeratedString = Function(
                          CamHandle : Integer ;
                          const Feature : PWideChar ;
                          EnumString : PWideChar
                          ) : Integer ; stdcall ;

TAT_GetEnumerated = Function(
                    CamHandle : Integer ;
                    const Feature : PWideChar ;
                    var Value : Integer
                    ) : Integer ; stdcall ;

TAT_GetEnumeratedCount = Function(
                         CamHandle : Integer ;
                         const Feature : PWideChar ;
                         var Count : Integer
                         ) : Integer ; stdcall ;

TAT_IsEnumeratedIndexAvailable = Function(
                                 CamHandle : Integer ;
                                 const Feature : PWideChar ;
                                 Index : Integer ;
                                 var Available : LongBool
                                 ) : Integer ; stdcall ;

TAT_IsEnumeratedIndexImplemented = Function(
                                   CamHandle : Integer ;
                                   const Feature : PWideChar ;
                                   Index : Integer ;
                                   var Implemented : LongBool
                                   ) : Integer ; stdcall ;

TAT_GetEnumeratedString = Function(
                          CamHandle : Integer ;
                          const Feature : PWideChar ;
                          Index : Integer ;
                          str : PWideChar ;
                          StringLength : Integer
                          ) : Integer ; stdcall ;

                          

TAT_SetEnumIndex = Function(
                   CamHandle : Integer ;
                   const Feature : PWideChar ;
                   Value : Integer
                   ) : Integer ; stdcall ;

TAT_SetEnumString = Function(
                    CamHandle : Integer ;
                    const Feature : PWideChar ;
                    str : PWideChar
                    ) : Integer ; stdcall ;

TAT_GetEnumIndex = Function(
                   CamHandle : Integer ;
                   const Feature : PWideChar ;
                   var Value : Integer
                   ) : Integer ; stdcall ;

TAT_GetEnumCount = Function(
                   CamHandle : Integer ;
                   const Feature : PWideChar ;
                   var Count : Integer
                   ) : Integer ; stdcall ;
TAT_IsEnumIndexAvailable = Function(
                           CamHandle : Integer ;
                           const Feature : PWideChar ;
                           Index : Integer ;
                           var Available : LongBool
                           ) : Integer ; stdcall ;

TAT_IsEnumIndexImplemented = Function(
                             CamHandle : Integer ;
                             const Feature : PWideChar ;
                             Index : Integer ;
                             var Implemented : LongBool
                             ) : Integer ; stdcall ;

TAT_GetEnumStringByIndex = Function(
                           CamHandle : Integer ;
                           const Feature : PWideChar ;
                           Index : Integer ;
                           str : PWideChar ;
                           StringLength : Integer
                           ) : Integer ; stdcall ;

TAT_Command = Function(
              CamHandle : Integer ;
              Feature : PWideChar
              ) : Integer ; stdcall ;

TAT_SetString = Function(
                CamHandle : Integer ;
                const Feature : PWideChar ;
                str : PWideChar
                ) : Integer ; stdcall ;

TAT_GetString = Function(
                CamHandle : Integer ;
                const Feature : PWideChar ;
                str : PWideChar ;
                StringLength : Integer
                ) : Integer ; stdcall ;

TAT_GetStringMaxLength = Function(
                         CamHandle : Integer ;
                         const Feature : PWideChar ;
                         var MaxStringLength : Integer
                         ) : Integer ; stdcall ;

TAT_QueueBuffer = Function(
                  CamHandle : Integer ;
                  AT_U8 : Pointer ;
                  PtrSize : Integer
                  ) : Integer ; stdcall ;
TAT_WaitBuffer = Function(
                 CamHandle : Integer ;
                 var AT_U8 : Pointer ;
                 var PtrSize : Integer ;
                 Timeout : Cardinal
                 ) : Integer ; stdcall ;

TAT_Flush = Function(
            CamHandle : Integer
            ) : Integer ; stdcall ;

// Function calls

function AndorSDK3_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

function AndorSDK3_CheckDLLExists( DLLName : String ) : Boolean ;

procedure AndorSDK3_LoadLibrary(
          var Session : TAndorSDK3Session   // Camera session record  ;
          ) ;

function AndorSDK3_OpenCamera(
          var Session : TAndorSDK3Session ;   // Camera session record
          var FrameWidthMax : Integer ;      // Returns camera frame width
          var FrameHeightMax : Integer ;     // Returns camera frame width
          var BinFactorMax : Integer ;       // Maximum bin factor
          var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
          var PixelDepth : Integer ;         // Returns no. bits/pixel
          var PixelWidth : Single ;          // Returns pixel size (um)
          CameraInfo : TStringList         // Returns Camera details
          ) : LongBool ;

function AndorSDK3_PixelDepth( ADConverterList : TStringList ;
                               ADCNum : Integer ) : Integer ;

procedure AndorSDK3_CloseCamera(
          var Session : TAndorSDK3Session // Session record
          ) ;

procedure AndorSDK3_GetCameraGainList(
          var Session : TAndorSDK3Session ; // Session record
          CameraGainList : TStringList
          ) ;

procedure AndorSDK3_GetCameraReadoutSpeedList(
          var Session : TAndorSDK3Session ; // Session record
          CameraReadoutSpeedList : TStringList
          ) ;

procedure AndorSDK3_GetCameraModeList(
          var Session : TAndorSDK3Session ; // Session record
          List : TStringList
          ) ;

procedure AndorSDK3_GetCameraADCList(
          var Session : TAndorSDK3Session ; // Session record
          List : TStringList
          ) ;

procedure AndorSDK3_CheckROIBoundaries(
         var Session : TAndorSDK3Session ;   // Camera session record
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var  BinFactor : Integer ;   // Pixel binning factor (In)
         FrameWidthMax : Integer ;
         FrameHeightMax : Integer ;
         var FrameWidth : Integer ;
         var FrameHeight : Integer
         ) ;

function AndorSDK3_BinFactor( BinFactorList : TStringList ;
                              Index : Integer ) : Integer ;

function AndorSDK3_StartCapture(
         var Session : TAndorSDK3Session ;   // Camera session record
         var InterFrameTimeInterval : Double ;      // Frame exposure time
         AmpGain : Integer ;              // Camera amplifier gain index
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer ;      // No. of bytes/frame
         var ReadoutTime : Double        // Return frame readout time
         ) : LongBool ;

procedure AndorSDK3_UpdateCircularBufferSize(
          var Session : TAndorSDK3Session  ; // Camera session record
          FrameLeft : Integer ;
          FrameRight : Integer ;
          FrameTop : Integer ;
          FrameBottom : Integer ;
          BinFactor : Integer
          ) ;


function AndorSDK3_CheckFrameInterval(
          var Session : TAndorSDK3Session ;   // Camera session record
          FrameLeft : Integer ;   // Left edge of capture region (In)
          FrameRight : Integer ;  // Right edge of capture region( In)
          FrameTop : Integer ;    // Top edge of capture region( In)
          FrameBottom : Integer ; // Bottom edge of capture region (In)
          BinFactor : Integer ;   // Pixel binning factor (In)
          FrameWidthMax : Integer ;   // Max frame width (in)
          FrameHeightMax : Integer ;  // Max. frame height (in)
          Var FrameInterval : Double ;
          Var ReadoutTime : Double) : LongBool ;


procedure AndorSDK3_Wait( Delay : Single ) ;

procedure AndorSDK3_GetImage(
          var Session : TAndorSDK3Session  // Camera session record
          ) ;

procedure AndorSDK3_StopCapture(
          var Session : TAndorSDK3Session   // Camera session record
          ) ;

procedure AndorSDK3_SetTemperature(
          var Session : TAndorSDK3Session ; // Session record
          var TemperatureSetPoint : Single  // Required temperature
          ) ;

procedure AndorSDK3_SetCooling(
          var Session : TAndorSDK3Session ; // Session record
          CoolingOn : LongBool  // True = Cooling is on
          ) ;

procedure AndorSDK3_SetFanMode(
          var Session : TAndorSDK3Session ; // Session record
          FanMode : Integer  // 0 = Off, 1=low, 2=high
          ) ;

procedure AndorSDK3_SetCameraMode(
          var Session : TAndorSDK3Session ; // Session record
          Mode : Integer ) ;

procedure AndorSDK3_SetCameraADC(
          var Session : TAndorSDK3Session ; // Session record
          ADCNum : Integer ;
          var PixelDepth : Integer ;
          var GreyLevelMin : Integer ;
          var GreyLevelMax : Integer ) ;

procedure AndorSDK3_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;

function  AndorSDK3_GetChar(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : WideString ) : LongBool ;  // Returned value

function  AndorSDK3_GetInt64(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : Int64 ) : LongBool ;       // Returned value

function  AndorSDK3_SetInt64(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : Int64 ) : LongBool ;       // Returned value

function  AndorSDK3_GetDouble(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : Double ) : LongBool ;       // Returned value

function  AndorSDK3_SetDouble(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : Double ) : LongBool ;         // New value

function  AndorSDK3_GetBoolean(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : LongBool ) : LongBool ;       // Returned value

function  AndorSDK3_SetBoolean(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : LongBool ) : LongBool ;         // New value

function  AndorSDK3_GetEnumeratedList(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          List : TStringList                    // Returns list of available settings
           ) : LongBool ;  // Returned status

function  AndorSDK3_GetEnumerated(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : WideString                    // Returns setting
          ) : LongBool ;  // Returned status


function  AndorSDK3_SetEnumerated(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : WideString ) : LongBool ;     // New value

function  AndorSDK3_SetEnumeratedByIndex(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : Integer ) : LongBool ;        // New Index

implementation

uses SESCam ;

const
   EmptyFlag = $FFFF ;

   AT_INFINITE = $FFFFFFFF ;

   AT_CALLBACK_SUCCESS = 0;

   AT_TRUE = 1 ;
   AT_FALSE = 0 ;

   AT_SUCCESS = 0 ;
   AT_ERR_NOTINITIALISED = 1 ;
   AT_ERR_NOTIMPLEMENTED = 2 ;
   AT_ERR_READONLY = 3 ;
   AT_ERR_NOTREADABLE = 4 ;
   AT_ERR_NOTWRITABLE = 5 ;
   AT_ERR_OUTOFRANGE = 6 ;
   AT_ERR_INDEXNOTAVAILABLE = 7 ;
   AT_ERR_INDEXNOTIMPLEMENTED = 8 ;
   AT_ERR_EXCEEDEDMAXSTRINGLENGTH = 9 ;
   AT_ERR_CONNECTION = 10 ;
   AT_ERR_NODATA = 11 ;
   AT_ERR_INVALIDHANDLE = 12 ;
   AT_ERR_TIMEDOUT = 13;
   AT_ERR_BUFFERFULL = 14 ;
   AT_ERR_INVALIDSIZE = 15 ;
   AT_ERR_INVALIDALIGNMENT = 16 ;
   AT_ERR_COMM = 17 ;
   AT_ERR_STRINGNOTAVAILABLE = 18 ;
   AT_ERR_STRINGNOTIMPLEMENTED = 19 ;

   AT_ERR_NULL_FEATURE = 20 ;
   AT_ERR_NULL_HANDLE = 21 ;
   AT_ERR_NULL_IMPLEMENTED_VAR = 22 ;
   AT_ERR_NULL_READABLE_VAR = 23 ;
   AT_ERR_NULL_READONLY_VAR = 24 ;
   AT_ERR_NULL_WRITABLE_VAR = 25 ;
   AT_ERR_NULL_MINVALUE = 26;
   AT_ERR_NULL_MAXVALUE = 27 ;
   AT_ERR_NULL_VALUE = 28 ;
   AT_ERR_NULL_STRING = 29 ;
   AT_ERR_NULL_COUNT_VAR = 30;
   AT_ERR_NULL_ISAVAILABLE_VAR = 31;
   AT_ERR_NULL_MAXSTRINGLENGTH = 32;
   AT_ERR_NULL_EVCALLBACK = 33 ;
   AT_ERR_NULL_QUEUE_PTR = 34 ;
   AT_ERR_NULL_WAIT_PTR = 35 ;
   AT_ERR_NULL_PTRSIZE = 36 ;
   AT_ERR_NOMEMORY = 37 ;
   AT_ERR_DEVICEINUSE = 38 ;

   AT_ERR_HARDWARE_OVERFLOW = 100 ;

   AT_HANDLE_UNINITIALISED = -1 ;
   AT_HANDLE_SYSTEM = 1 ;


var


  LibraryHnd : THandle ;         // DLL library handle
  LibraryLoaded : LongBool ;      // DLL library loaded flag

  AT_InitialiseLibrary : TAT_InitialiseLibrary ;
  AT_FinaliseLibrary  : TAT_FinaliseLibrary;
  AT_Open : TAT_Open ;
  AT_Close : TAT_Close ;
  AT_RegisterFeatureCallback : TAT_RegisterFeatureCallback ;
  AT_UnregisterFeatureCallback  : TAT_UnregisterFeatureCallback;
  AT_IsImplemented : TAT_IsImplemented ;
  AT_IsReadable : TAT_IsReadable  ;
  AT_IsWritable : TAT_IsWritable  ;
  AT_IsReadOnly : TAT_IsReadOnly  ;
  AT_SetInt :TAT_SetInt ;
  AT_GetInt :TAT_GetInt ;
  AT_GetIntMax :TAT_GetIntMax ;
  AT_GetIntMin :TAT_GetIntMin ;
  AT_SetFloat :TAT_SetFloat ;
  AT_GetFloat :TAT_GetFloat ;
  AT_GetFloatMax :TAT_GetFloatMax ;
  AT_GetFloatMin :TAT_GetFloatMin ;
  AT_SetBool :TAT_SetBool ;
  AT_GetBool :TAT_GetBool ;
  AT_SetEnumerated :TAT_SetEnumerated ;
  AT_SetEnumeratedString :TAT_SetEnumeratedString ;
  AT_GetEnumerated :TAT_GetEnumerated ;
  AT_GetEnumeratedCount :TAT_GetEnumeratedCount ;
  AT_IsEnumeratedIndexAvailable : TAT_IsEnumeratedIndexAvailable ;
  AT_IsEnumeratedIndexImplemented : TAT_IsEnumeratedIndexImplemented ;
  AT_GetEnumeratedString : TAT_GetEnumeratedString ;
  AT_SetEnumIndex :TAT_SetEnumIndex ;
  AT_SetEnumString :TAT_SetEnumString ;
  AT_GetEnumIndex : TAT_GetEnumIndex ;
  AT_GetEnumCount :TAT_GetEnumCount ;
  AT_IsEnumIndexAvailable :TAT_IsEnumIndexAvailable ;
  AT_IsEnumIndexImplemented :TAT_IsEnumIndexImplemented ;
  AT_GetEnumStringByIndex :TAT_GetEnumStringByIndex ;
  AT_Command :TAT_Command;
  AT_SetString :TAT_SetString ;
  AT_GetString :TAT_GetString ;
  AT_GetStringMaxLength :TAT_GetStringMaxLength ;
  AT_QueueBuffer :TAT_QueueBuffer ;
  AT_WaitBuffer :TAT_WaitBuffer ;
  AT_Flush :TAT_Flush ;

procedure AndorSDK3_LoadLibrary(
          var Session : TAndorSDK3Session   // Camera session record
          ) ;

{ ---------------------------------------------
  Load camera interface DLL library into memory
  ---------------------------------------------}
const
    LibName = 'atcore.dll' ;
begin

     LibraryLoaded := False ;

     // Look for DLL initially in Winfluor folder
     Session.LibFileName := ExtractFilePath(ParamStr(0)) + LibName ;

     // Check that DLLs are available in WinFluor program folder
     if not AndorSDK3_CheckDLLExists( 'atcore.dll' ) then Exit ;
     if not AndorSDK3_CheckDLLExists( 'atblkbx.dll' ) then Exit ;
     if not AndorSDK3_CheckDLLExists( 'atcl_bitflow.dll' ) then Exit ;
     if not AndorSDK3_CheckDLLExists( 'atdevregcam.dll' ) then Exit ;

     { Load DLL camera interface library }
     LibraryHnd := LoadLibrary( PChar(Session.LibFileName));
     if LibraryHnd <= 0 then begin
        ShowMessage( 'Andor SDK3: Unable to open' + Session.LibFileName ) ;
        Exit ;
        end ;

     @AT_InitialiseLibrary := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_InitialiseLibrary') ;
     @AT_FinaliseLibrary := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_FinaliseLibrary') ;
     @AT_Open := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_Open') ;
     @AT_Close := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_Close') ;
     @AT_RegisterFeatureCallback := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_RegisterFeatureCallback') ;
     @AT_UnregisterFeatureCallback := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_UnregisterFeatureCallback') ;
     @AT_IsImplemented := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsImplemented') ;
     @AT_IsReadable := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsReadable') ;
     @AT_IsWritable := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsWritable') ;
     @AT_IsReadOnly := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsReadOnly') ;
     @AT_SetInt := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetInt') ;
     @AT_GetInt := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetInt') ;
     @AT_GetIntMax := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetIntMax') ;
     @AT_GetIntMin := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetIntMin') ;
     @AT_SetFloat := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetFloat') ;
     @AT_GetFloat := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetFloat') ;
     @AT_GetFloatMax := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetFloatMax') ;
     @AT_GetFloatMin := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetFloatMin') ;
     @AT_SetBool := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetBool') ;
     @AT_GetBool := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetBool') ;
     @AT_SetEnumerated := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetEnumerated') ;
     @AT_SetEnumeratedString := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetEnumeratedString') ;
     @AT_GetEnumerated := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetEnumerated') ;
     @AT_GetEnumeratedCount := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetEnumeratedCount') ;
     @AT_IsEnumeratedIndexAvailable := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsEnumeratedIndexAvailable') ;
     @AT_IsEnumeratedIndexImplemented := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsEnumeratedIndexImplemented') ;
     @AT_GetEnumeratedString := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetEnumeratedString') ;
     @AT_SetEnumIndex := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetEnumIndex') ;
     @AT_SetEnumString := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetEnumString') ;
     @AT_GetEnumIndex := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetEnumIndex') ;
     @AT_GetEnumCount := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetEnumCount') ;
     @AT_IsEnumIndexAvailable := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsEnumIndexAvailable') ;
     @AT_IsEnumIndexImplemented := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_IsEnumIndexImplemented') ;
     @AT_GetEnumStringByIndex := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetEnumStringByIndex') ;
     @AT_Command := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_Command') ;
     @AT_SetString := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_SetString') ;
     @AT_GetString := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetString') ;
     @AT_GetStringMaxLength := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_GetStringMaxLength') ;
     @AT_QueueBuffer := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_QueueBuffer') ;
     @AT_WaitBuffer := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_WaitBuffer') ;
     @AT_Flush := AndorSDK3_GetDLLAddress(LibraryHnd,'AT_Flush') ;

     LibraryLoaded := True ;

     end ;


function AndorSDK3_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then ShowMessage('atcore.dll: ' + ProcName + ' not found') ;
    end ;

function AndorSDK3_CheckDLLExists( DLLName : String ) : Boolean ;
// -------------------------------------------
// Check that a DLL present in WinFluor folder
// -------------------------------------------
var
    Source,Destination : String ;
    WinDir : Array[0..255] of Char ;
    SysDrive : String ;
begin
     // Get system drive
     GetWindowsDirectory( WinDir, High(WinDir) ) ;
     SysDrive := ExtractFileDrive(String(WinDir)) ;
     Destination := ExtractFilePath(ParamStr(0)) + DLLName ;

     // Try to get file from win32 DLL folder of SDK
     if not FileExists(Destination) then begin
        Source := SysDrive + '\Program Files\Andor SDK3\win32\' + DLLName ;
        if FileExists(Source) then begin
           CopyFile( PChar(Source), PChar(Destination), False ) ;
           end ;
        end ;

     // Try to get file from main SDK3 folder
     if not FileExists(Destination) then begin
        Source := SysDrive + '\Program Files\Andor SDK3\' + DLLName ;
        if FileExists(Source) then begin
           CopyFile( PChar(Source), PChar(Destination), False ) ;
           end ;
        end ;

     // Try to get file from SOLIS folder
     if not FileExists(Destination) then begin
        Source := SysDrive + '\Program Files\Andor SOLIS\' + DLLName ;
        if FileExists(Source) then begin
           CopyFile( PChar(Source), PChar(Destination), False ) ;
           end ;
        end ;

     if FileExists(Destination) then Result := True
     else begin
        ShowMessage('Andor SDK3: ' + Destination + ' is missing!') ;
        Result := False ;
        end ;
     end ;


function AndorSDK3_OpenCamera(
          var Session : TAndorSDK3Session ;   // Camera session record
          var FrameWidthMax : Integer ;      // Returns camera frame width
          var FrameHeightMax : Integer ;     // Returns camera height width
          var BinFactorMax : Integer ;       // Maximum bin factor
          var NumBytesPerPixel : Integer ;   // Returns bytes/pixel
          var PixelDepth : Integer ;         // Returns no. bits/pixel
          var PixelWidth : Single ;          // Returns pixel size (um)
          CameraInfo : TStringList         // Returns Camera details
          ) : LongBool ;
// ---------------------
// Open Andor camera
// ---------------------
var
    Err : Integer ;
    i,j :Integer ;
    CCDTemperature : Integer ;
    ReadoutRate : Single ;
    CameraIndex : Integer ;
    wsValue : WideString ;
    iValue : Int64 ;
    dValue : Double ;
    bValue : LongBool ;
    s,sValue : string ;
    BadCode : Integer ;
begin

     Result := False ;
     CameraInfo.Clear ;

     // Load DLL libray
     if not LibraryLoaded then AndorSDK3_LoadLibrary(Session)  ;
     if not LibraryLoaded then begin
        CameraInfo.Add('Andor SDK3: Unable to load atcore.dll') ;
        Exit ;
        end ;

     // Initialise library
     Err := AT_InitialiseLibrary() ;
     AndorSDK3_CheckError( 'AT_InitialiseLibrary', Err ) ;
     if Err <> AT_SUCCESS then Exit ;

     // Get system properties (before opening camera)
     AndorSDK3_GetChar( AT_HANDLE_SYSTEM, 'SoftwareVersion', wsValue ) ;
     CameraInfo.Add( 'SDK Version: ' + wsValue ) ;
     AndorSDK3_GetInt64( AT_HANDLE_SYSTEM, 'DeviceCount', iValue ) ;
     CameraInfo.Add( format('No. of cameras detected: %d', [iValue] )) ;
     if iValue <= 0 Then Exit ;

     // Open camera
     CameraIndex := 0 ;
     AndorSDK3_CheckError( 'AT_Open',
                            AT_Open( CameraIndex, Session.CamHandle )) ;

     // Camera model info
     AndorSDK3_GetChar( Session.CamHandle, 'CameraModel', wsValue ) ;
     CameraInfo.Add( 'Camera Model: ' + wsValue ) ;
     AndorSDK3_GetChar( Session.CamHandle, 'FirmwareVersion', wsValue ) ;
     CameraInfo.Add( 'Firmware: ' + wsValue ) ;
     AndorSDK3_GetChar( Session.CamHandle, 'SerialNumber', wsValue ) ;
     CameraInfo.Add( 'Serial Number: ' + wsValue ) ;
     AndorSDK3_GetChar( Session.CamHandle, 'ControllerID', wsValue ) ;
     CameraInfo.Add( 'Controller: ' + wsValue ) ;

     // Interface
     AndorSDK3_GetChar( Session.CamHandle, 'InterfaceType', wsValue ) ;
     CameraInfo.Add( 'Interface: ' + wsValue ) ;
     // Determine number of camera taps (e.g. CL 10 Taps, CL 3 Taps)
     wsValue := LowerCase(wsValue) ;
     Val( MidStr( wsValue,Pos('cl',wsValue)+2, Pos('tap',wsValue)-Pos('cl',wsValue)-2 ),
          Session.NumCameraTaps, BadCode ) ;

     // Get image area
     AndorSDK3_GetInt64( Session.CamHandle, 'SensorHeight', iValue ) ;
     FrameHeightMax := Integer(iValue) ;
     AndorSDK3_GetInt64( Session.CamHandle, 'SensorWidth', iValue ) ;
     FrameWidthMax := Integer(iValue) ;

     // If not found, assume pixel size is 6.5 um
     if AndorSDK3_GetDouble(Session.CamHandle,'PixelHeight',dValue) then PixelWidth := dValue
                                                                    else PixelWidth := 6.5 ;

     CameraInfo.Add( format('CCD resolution: %d x %d (%.4g um)',[FrameWidthMax,FrameHeightMax,PixelWidth]));

     // Get list of available pixel encoding formats
     Session.PixelEncodingList := TStringList.Create ;
     AndorSDK3_GetEnumeratedList( Session.CamHandle,'PixelEncoding',Session.PixelEncodingList ) ;
     s := '' ;
     for i := 0 to Session.PixelEncodingList.Count-1 do begin
         sValue := Session.PixelEncodingList[i] ;
         if s = '' then s := 'Pixel Encoding: ' + sValue
                   else s := s + ', ' + sValue ;
         end ;
     CameraInfo.Add( s ) ;

     AndorSDK3_SetEnumerated( Session.CamHandle,'PixelEncoding', 'Mono12');

     // Get list of available A/D converters
     Session.ADConverterList := TStringList.Create  ;
     AndorSDK3_GetEnumeratedList( Session.CamHandle,'SimplePreAmpGainControl',
                                  Session.ADConverterList) ;
     s := '' ;
     for i := 0 to Session.ADConverterList.Count-1 do begin
         sValue := Session.ADConverterList[i] ;
         if s = '' then s := 'Pixel Depths: ' + sValue
                   else s := s + ', ' + sValue ;
         end ;
     CameraInfo.Add( s ) ;

     Session.ADCNum := 0 ;
     PixelDepth := AndorSDK3_PixelDepth(Session.ADConverterList,Session.ADCNum) ;
     NumBytesPerPixel := 2 ;

     // Get available readout rates
     s := '' ;
     Session.ReadoutRateList := TStringList.Create ;
     AndorSDK3_GetEnumeratedList( Session.CamHandle,'PixelReadoutRate',
                                  Session.ReadoutRateList) ;
     s := '' ;
     for i := 0 to Session.ReadoutRateList.Count-1 do begin
         sValue := Session.ReadoutRateList[i] ;
         if s = '' then s := 'Readout Rates: ' + sValue
                   else s := s + ', ' + sValue ;
         end ;
     CameraInfo.Add( s ) ;

     // Get available shutter modes
     s := '' ;
     Session.ModeList := TStringList.Create ;
     AndorSDK3_GetEnumeratedList( Session.CamHandle,'ElectronicShutteringMode',
                                  Session.ModeList) ;
     s := '' ;
     for i := 0 to Session.ModeList.Count-1 do begin
         sValue := Session.ModeList[i] ;
         if s = '' then s := 'Operating Modes: ' + sValue
                   else s := s + ', ' + sValue ;
         end ;
     CameraInfo.Add( s ) ;

     // Get list of available binning factors
     Session.BinFactorList := TStringList.Create ;
     AndorSDK3_GetEnumeratedList( Session.CamHandle,'AOIBinning',Session.BinFactorList ) ;
     s := '' ;
     BinFactorMax := 1 ;
     for i := 0 to Session.BinFactorList.Count-1 do begin
         sValue := Session.BinFactorList[i] ;
         iValue := AndorSDK3_BinFactor( Session.BinFactorList, i ) ;
         BinFactorMax := Max(BinFactorMax,iValue) ;
         if s = '' then s := 'Bin Factors: ' + sValue
                   else s := s + ', ' + sValue ;
         end ;
     CameraInfo.Add( s ) ;

     // Get list of available temperature settings
     Session.TemperatureSettingsList := TStringList.Create ;
     AndorSDK3_GetEnumeratedList( Session.CamHandle,'TemperatureControl',Session.TemperatureSettingsList ) ;
     s := '' ;
     for i := 0 to Session.TemperatureSettingsList.Count-1 do begin
         sValue := Session.TemperatureSettingsList[i] ;
         if s = '' then s := 'Temp Settings: ' + sValue
                   else s := s + ', ' + sValue ;
         end ;
     CameraInfo.Add( s ) ;

     AndorSDK3_GetBoolean( Session.CamHandle, 'FullAOIControl', bValue ) ;
     if bValue then s := 'Full area of interest control supported.'
               else s := 'Full area of interest control not supported.' ;
     CameraInfo.Add( s ) ;

    AndorSDK3_SetCooling( Session, True ) ;
    AndorSDK3_GetEnumerated(Session.CamHandle, 'TemperatureStatus', wsValue ) ;
    CameraInfo.Add( 'Temperature Status: ' + wsValue ) ;

     // Set buffer flags to unallocated
     for i := 0 to High(Session.pBuf) do Session.pBuf[i] := Nil ;

     Session.CameraOpen := True ;
     Session.CapturingImages := False ;
     Result := Session.CameraOpen ;

     end ;


function AndorSDK3_PixelDepth( ADConverterList : TStringList ;
                               ADCNum : Integer ) : Integer ;

// ------------------------------------------------
// Determine integer pixel from ADConverter setting
// ------------------------------------------------
var
    BadCode : Integer ;
    s : string ;
begin
    if ADConverterList.Count > 0 then begin
       s := ADConverterList[ADCNum] ;
       Val( LeftStr(s,Pos('-',s)-1),Result, BadCode) ;
       if Result = 0 then Result := 16 ;
       end

    else Result := 16 ;
    end ;


procedure AndorSDK3_SetTemperature(
          var Session : TAndorSDK3Session ; // Session record
          var TemperatureSetPoint : Single  // Required temperature
          ) ;
// -------------------------------
// Set camera temperature set point
// --------------------------------
var
    TSet,TDiff,MinTDiff : Double ;
    i : Integer ;
    s,TNearest : Widestring ;
    BadCode : Integer ;
begin

     if not Session.CameraOpen then Exit ;

     MinTDiff := 1.0E30 ;
     for i := 0 to Session.TemperatureSettingsList.Count-1 do begin
         s := Session.TemperatureSettingsList[i] ;
         Val(s,TSet,BadCode) ;
         TDiff := Abs(TemperatureSetPoint-TSet) ;
         if TDiff <= MinTDiff then begin
            TNearest := s ;
            Session.WorkingTemperature := TSet ;
            MinTDiff := TDiff ;
            end ;
         end ;

     AndorSDK3_SetEnumerated( Session.CamHandle, 'TemperatureControl', TNearest ) ;
     TemperatureSetPoint := Session.WorkingTemperature ;

     end ;


procedure AndorSDK3_SetCooling(
          var Session : TAndorSDK3Session ; // Session record
          CoolingOn : LongBool  // True = Cooling is on
          ) ;
// -------------------
// Turn cooling on/off
// -------------------
var
    wsValue : WideString ;
begin
     if not Session.CameraOpen then Exit ;

     if not AndorSDK3_SetBoolean( Session.CamHandle, 'SensorCooling', CoolingOn ) then
        ShowMessage('Unable to set cooling');

     AndorSDK3_GetEnumerated(Session.CamHandle, 'TemperatureStatus', wsValue ) ;
     //outputdebugstring(pchar('TemperatureStatus: ' + wsValue )) ;

     end ;


procedure AndorSDK3_SetFanMode(
          var Session : TAndorSDK3Session ; // Session record
          FanMode : Integer  // 0 = Off, 1=low, 2=high
          ) ;
// -------------------
// Set camera fan mode
// -------------------
begin
     if not Session.CameraOpen then Exit ;
     case FanMode of
          0 : AndorSDK3_SetEnumerated( Session.CamHandle, 'FanSpeed', 'Off' ) ;
          1 : AndorSDK3_SetEnumerated( Session.CamHandle, 'FanSpeed', 'Low' ) ;
          else AndorSDK3_SetEnumerated( Session.CamHandle, 'FanSpeed', 'On' ) ;
          end ;

     end ;


procedure AndorSDK3_SetCameraMode(
          var Session : TAndorSDK3Session ; // Session record
          Mode : Integer ) ;
// --------------------
// Set camera CCD mode
// --------------------
begin
    if not Session.CameraOpen then Exit ;

    Mode := Min(Max(Mode,Session.ModeList.Count-1),0) ;
    Session.CameraMode := Mode ;
    AndorSDK3_SetEnumerated( Session.CamHandle, 'ElectronicShutteringMode', Session.ModeList[Mode] ) ;

    end ;


procedure AndorSDK3_SetCameraADC(
          var Session : TAndorSDK3Session ; // Session record
          ADCNum : Integer ;
          var PixelDepth : Integer ;
          var GreyLevelMin : Integer ;
          var GreyLevelMax : Integer ) ;
// ------------------------
// Set camera A/D converter
// ------------------------
var
    i : Integer ;
    Pixelformat : WideString ;
begin

   if not Session.CameraOpen then Exit ;

    ADCNum := Max(Min(ADCNum,Session.ADConverterList.Count-1),0) ;
    Session.ADCNum := ADCNum ;
    PixelDepth := 16 ;
    GreyLevelMin := 0 ;
    GreyLevelMax := 32767 ;
    if Session.ADConverterList.Count <= 0 then Exit ;

    AndorSDK3_SetEnumerated( Session.CamHandle,'SimplePreAmpGainControl', Session.ADConverterList[ADCNum] ) ;
    PixelDepth := AndorSDK3_PixelDepth(Session.ADConverterList,ADCNum) ;

    if PixelDepth <= 12 then PixelFormat := 'Mono12'
                        else PixelFormat := 'Mono16' ;
    AndorSDK3_SetEnumerated( Session.CamHandle,'PixelEncoding', PixelFormat ) ;

    // Calculate grey levels from pixel depth

    GreyLevelMax := 1 ;
    for i := 1 to PixelDepth do GreyLevelMax := GreyLevelMax*2 ;
    GreyLevelMax := GreyLevelMax - 1 ;
    GreyLevelMin := 0 ;

    end ;


procedure AndorSDK3_CloseCamera(
          var Session : TAndorSDK3Session // Session record
          ) ;
// ----------------
// Shut down camera
// ----------------
var
    Err : Integer ;
begin

    if not Session.CameraOpen then Exit ;

    // Stop capture if in progress
    if Session.CapturingImages then AndorSDK3_StopCapture( Session ) ;

    // Close camera
    AndorSDK3_CheckError( 'AT_Close', AT_Close( Session.CamHandle )) ;

    AndorSDK3_CheckError( 'AT_FinaliseLibrary', AT_FinaliseLibrary()) ;

    // Free DLL library
    if LibraryLoaded then FreeLibrary(libraryHnd) ;
    LibraryLoaded := False ;

    Session.GetImageInUse := False ;
    Session.CameraOpen := False ;

    // Free string lists
    Session.ReadoutRateList.Free ;
    Session.PixelEncodingList.Free ;
    Session.ADConverterList.Free ;
    Session.BinFactorList.Free ;
    Session.ModeList.Free ;
    Session.TemperatureSettingsList.Free ;

    end ;


procedure AndorSDK3_GetCameraGainList(
          var Session : TAndorSDK3Session ; // Session record
          CameraGainList : TStringList
          ) ;
// --------------------------------------------
// Get list of available camera amplifier gains
// --------------------------------------------
var
    NumGains : Integer ;
    wsValue : WideString ;
begin

    CameraGainList.Clear ;
    CameraGainList.Add('n/a') ;

    end ;

procedure AndorSDK3_GetCameraReadoutSpeedList(
          var Session : TAndorSDK3Session ; // Session record
          CameraReadoutSpeedList : TStringList
          ) ;
// -------------------------------
// Get camera pixel readout speeds
// -------------------------------
begin

     // Get list of available rates
     CameraReadoutSpeedList.Assign( Session.ReadoutRateList ) ;

     end ;


procedure AndorSDK3_GetCameraModeList(
          var Session : TAndorSDK3Session ; // Session record
          List : TStringList
          ) ;
// -----------------------------------------
// Return list of available camera CCD mode
// -----------------------------------------
begin

     // Get list of available modes
     List.Assign( Session.ModeList ) ;

    end ;


procedure AndorSDK3_GetCameraADCList(
          var Session : TAndorSDK3Session ; // Session record
          List : TStringList
          ) ;
// ---------------------------------
// Get list of A/D converter options
// ----------------------------------
var
    NumADCs : Integer ;
    wsValue : WideString ;
begin

     // Get list of available ADCs
     List.Assign( Session.ADConverterList ) ;

    end ;


procedure AndorSDK3_CheckROIBoundaries(
          var Session : TAndorSDK3Session ;   // Camera session record
          var FrameLeft : Integer ;            // Left pixel in CCD readout area
          var FrameRight : Integer ;           // Right pixel in CCD eadout area
          var FrameTop : Integer ;             // Top of CCD readout area
          var FrameBottom : Integer ;          // Bottom of CCD readout area
          var  BinFactor : Integer ;   // Pixel binning factor (In)
          FrameWidthMax : Integer ;
          FrameHeightMax : Integer ;
          var FrameWidth : Integer ;
          var FrameHeight : Integer
          ) ;
// -------------------------------------------------------------
// Check that a valid set of CCD region boundaries have been set
// -------------------------------------------------------------
const
    MaxTries = 10 ;
var
    nCount : Integer ;
    Done : LongBool ;
    i64Value : Int64 ;
    i,Diff,MinDiff,iNearest,NearestBinFactor,iValue : Integer ;
    AOIWidthSteps : Integer ;
begin
    if not Session.CameraOpen then Exit ;

    // Set to nearest valid bin factor
    iNearest := 0 ;
    NearestBinFactor := 1 ;
    MinDiff := High(MinDiff) ;
    for i := 0 to Session.BinFactorList.Count-1 do begin
        iValue := AndorSDK3_BinFactor( Session.BinFactorList, i ) ;
        Diff := Abs(BinFactor - iValue) ;
        if  Diff <= MinDiff then begin
           iNearest := i ;
           NearestBinFactor := iValue ;
           MinDiff := Diff ;
           end ;
        end ;
    BinFactor := NearestBinFactor ;

    // Set binning factors
    AndorSDK3_SetEnumerated( Session.CamHandle, 'AOIBinning', WideString(format('%dx%d',[BinFactor,BinFactor])));
    // Note. Used AOIBinning property. AOIHBin and AOIVBin do not seem to work

    FrameWidth := (FrameRight - FrameLeft + 1) div BinFactor ;
    FrameHeight := (FrameBottom - FrameTop + 1 ) div BinFactor ;

    // Force frame width to be divisible by camera link transfer buffer granularity
    AOIWidthSteps := Max(Session.NumCameraTaps*4,1) ;
    FrameWidth := (FrameWidth div AOIWidthSteps)*AOIWidthSteps ;

    // Force frame height to be even
    FrameHeight := (FrameHeight div AndorSDK3AOIHeightSteps)*AndorSDK3AOIHeightSteps ;

    // Set width
    AndorSDK3_SetInt64( Session.CamHandle, 'AOIWidth', Int64(FrameWidth)) ;
    AndorSDK3_GetInt64( Session.CamHandle, 'AOIWidth', i64Value) ;
    FrameWidth := i64Value ;
    Session.AOIWidth := FrameWidth  ;

    // Set left edge of AOI
    AndorSDK3_SetInt64( Session.CamHandle, 'AOILeft', Int64(FrameLeft+1) ) ;
    AndorSDK3_GetInt64( Session.CamHandle, 'AOILeft', i64Value ) ;
    FrameLeft := i64Value - 1 ;

    // Set height
    AndorSDK3_SetInt64( Session.CamHandle, 'AOIHeight', Int64(FrameHeight)) ;
    AndorSDK3_GetInt64( Session.CamHandle, 'AOIHeight', i64Value ) ;
    FrameHeight := i64Value ;
    Session.AOIHeight := FrameHeight ;

    // Set top of AOI
    AndorSDK3_SetInt64( Session.CamHandle, 'AOITop', Int64(FrameTop+1) ) ;
    AndorSDK3_GetInt64( Session.CamHandle, 'AOITop', i64Value ) ;
    FrameTop := i64Value - 1 ;

    AndorSDK3_GetInt64( Session.CamHandle, 'AOIStride', i64Value ) ;

    if (i64Value div 2)<> Session.AOIWidth  then ShowMessage(
        format('Rowspacing=%d, Width=%d',[i64Value div 2,Session.AOIWidth]));

   end ;


function AndorSDK3_BinFactor( BinFactorList : TStringList ;
                              Index : Integer ) : Integer ;
// ------------------------------------------------
// Return bin factor from list of available factors
// ------------------------------------------------
var
    s : string ;
    BadCode : Integer ;
begin
     Result := 1 ;
     if BinFactorList.Count > 0 then begin
        Index := Max(Min(Index,BinFactorList.Count-1),0) ;
        s := BinFactorList[Index] ;
        Val(LeftStr(LowerCase(s),Pos('x',s)-1),Result,BadCode) ;
        end ;
     Result := Max(Result,1) ;   
     end ;

function AndorSDK3_StartCapture(
         var Session : TAndorSDK3Session ;   // Camera session record
         var InterFrameTimeInterval : Double ;      // Frame exposure time
         AmpGain : Integer ;              // Camera amplifier gain index
         ExternalTrigger : Integer ;      // Trigger mode
         FrameLeft : Integer ;            // Left pixel in CCD readout area
         FrameTop : Integer ;             // Top pixel in CCD eadout area
         FrameWidth : Integer ;           // Width of CCD readout area
         FrameHeight : Integer ;          // Width of CCD readout area
         BinFactor : Integer ;             // Binning factor (1,2,4,8,16)
         PFrameBuffer : Pointer ;         // Pointer to start of ring buffer
         NumFramesInBuffer : Integer ;    // No. of frames in ring buffer
         NumBytesPerFrame : Integer ;      // No. of bytes/frame
         var ReadoutTime : Double        // Return frame readout time
         ) : LongBool ;
// -------------------
// Start frame capture
// -------------------
const
     TimerTickInterval = 20 ; // Timer tick resolution (ms)

var
    i,Err : Integer ;
    TrigMode : Integer ;
    iFrameBuffer : Integer ;
    NumBytesPerImage,i64Value : Int64 ;
    Acquiring : LongBool ;
    dValue,ExposureTime,TRead : Double ;
    PixelFormat : WideString ;
begin

     if not Session.CameraOpen then Exit ;

     Session.TimeStart := TimeGetTime*0.001 ;

     // Read sensor temperature
     AndorSDK3_GetDouble( Session.CamHandle, 'SensorTemperature', dValue ) ;
     Session.Temperature := Round(dValue) ;

     // Set binning factors
     AndorSDK3_SetEnumerated( Session.CamHandle, 'AOIBinning', WideString(format('%dx%d',[BinFactor,BinFactor])));
     // Note. Used AOIBinning property. AOIHBin and AOIVBin do not seem to work

     // Size of AOI (in super-pixels)
     Session.AOIWidth := FrameWidth div BinFactor ;
     Session.AOIHeight := FrameHeight div BinFactor ;

     // Set image area
     AndorSDK3_SetInt64( Session.CamHandle,'AOIWidth', Int64(Session.AOIWidth)) ;
     AndorSDK3_SetInt64( Session.CamHandle, 'AOILeft', Int64(FrameLeft+1) ) ;
     AndorSDK3_SetInt64( Session.CamHandle, 'AOIHeight', Int64(Session.AOIHeight)) ;
     AndorSDK3_SetInt64( Session.CamHandle, 'AOITop', Int64(FrameTop+1) ) ;

     // Set trigger mode
     if ExternalTrigger = CamFreeRun then begin
        AndorSDK3_SetEnumerated( Session.CamHandle, 'TriggerMode', 'Internal' ) ;
        end
     else begin
        AndorSDK3_SetEnumerated( Session.CamHandle, 'TriggerMode', 'External' ) ;
        end ;

     // Get no. bytes in image
     Session.AOINumPixels := Session.AOIHeight*Session.AOIWidth ;
     Session.NumBytesPerFrameBuffer := Session.AOINumPixels*2 ;
     Session.ImageEnd := Session.AOINumPixels - 1 ;
     Session.NumFramesInBuffer := NumFramesInBuffer ;

     // Get no. of bytes per row of pixels in buffers
     AndorSDK3_GetInt64( Session.CamHandle,'AOIStride', i64Value ) ;
     Session.AOIRowSpacing := (i64Value div 2) ;

     // Create camera image buffers
     AndorSDK3_CheckError( 'AT_Flush',AT_Flush( Session.CamHandle )) ;
     iFrameBuffer := Cardinal(PFrameBuffer) ;
     for i := 0 to NumFramesInBuffer-1 do begin
         Session.pBuf64[i] := Ptr( iFrameBuffer ) ;
         iFrameBuffer := iFrameBuffer + Session.NumBytesPerFrameBuffer ;
         AT_QueueBuffer( Session.CamHandle, Session.pBuf64[i],Session.NumBytesPerFrameBuffer ) ;
         // Fill 2 pixels at end of each image with empty flags
         Session.pBuf64[i]^[Session.ImageEnd] :=  EmptyFlag ;
         Session.pBuf64[i]^[Session.ImageEnd-1] := 0 ;
         end ;

     Session.PFrameBuffer := PFrameBuffer ;

     // Set camera A/D converter
     AndorSDK3_SetEnumerated( Session.CamHandle,'SimplePreAmpGainControl',
                                     Session.ADConverterList[Session.ADCNum] ) ;
     // Pixel encoding
     if AndorSDK3_PixelDepth(Session.ADConverterList,Session.ADCNum) <= 12 then PixelFormat := 'Mono12'
                                                                           else PixelFormat := 'Mono16' ;
     AndorSDK3_SetEnumerated( Session.CamHandle,'PixelEncoding', PixelFormat ) ;

     // Set readout speed
//     if not AndorSDK3_SetEnumerated( Session.CamHandle,'PixelReadoutRate',
//                                     Session.ReadoutRateList[Session.ReadoutSpeed] ) then
//        ShowMessage('Unable to set PixelReadoutRate= ' + Session.ReadoutRateList[Session.ReadoutSpeed]) ;

     // Set shutter mode
     AndorSDK3_SetEnumerated( Session.CamHandle,'ElectronicShutteringMode',
                                     Session.ModeList[Session.Mode] ) ;

     // Set imaging/readout overlap mode (to allow maximum frame rate)
//     if not AndorSDK3_SetBoolean( Session.CamHandle, 'Overlap', True ) then
//        ShowMessage('Unable to set camera into Overlap mode');
      AndorSDK3_SetBoolean( Session.CamHandle, 'Overlap', False ) ;

     // Set to continuous image acquisition
     AndorSDK3_SetEnumerated( Session.CamHandle, 'CycleMode', 'Continuous' ) ;

     // Set accumulate count to capture single frames
     AndorSDK3_SetInt64( Session.CamHandle, 'AccumulateCount', Int64(1)) ;

     // Set exposure time
     AndorSDK3_GetDouble( Session.CamHandle, 'ReadoutTime', TRead ) ;
     ReadoutTime := TRead*2.0 ;
     // NOTE! Exposure time first to minimum then to required time to ensure that
     // that frame rate is updated correctly. Not clear why this is necessary.
     AndorSDK3_SetDouble( Session.CamHandle, 'ExposureTime', TRead ) ;
     if ExternalTrigger = CamFreeRun then ExposureTime := InterFrameTimeInterval - TRead
                                     else ExposureTime := InterFrameTimeInterval - TRead - 2E-4 ;
     AndorSDK3_SetDouble( Session.CamHandle, 'ExposureTime',  ExposureTime ) ;

     // Start capture
     AndorSDK3_CheckError( 'AT_Command=AcquisitionStart',
                           AT_Command( Session.CamHandle, 'AcquisitionStart')) ;

     AndorSDK3_GetBoolean( Session.CamHandle, 'CameraAcquiring', Acquiring ) ;
     if not Acquiring then ShowMessage('Camera not acquiring') ;
     // Start frame acquisition monitor procedure

     Session.FramePointer := 0 ;
     Session.NumFramesAcquired := 0 ;
     Session.NumFramesInBuffer := NumFramesInBuffer ;
     Session.CapturingImages := True ;
     Session.GetImageInUse := False ;

     Result := True ;

     end;


procedure AndorSDK3_UpdateCircularBufferSize(
          var Session : TAndorSDK3Session  ; // Camera session record
          FrameLeft : Integer ;
          FrameRight : Integer ;
          FrameTop : Integer ;
          FrameBottom : Integer ;
          BinFactor : Integer
          ) ;
// -----------------------------------------------------------------
// Update size of circular camera image buffer if image size changed
// -----------------------------------------------------------------
begin
     // Get number of images within camera circular image buffer
     // (Only of frame size has changed, to save time)
     if (Session.FrameLeft <> FrameLeft) or
        (Session.FrameTop <> FrameTop) or
        (Session.FrameRight <> FrameRight) or
        (Session.FrameBottom <> FrameBottom) or
        (Session.BinFactor <> BinFactor) then begin

        Session.FrameTop := FrameTop ;
        Session.FrameLeft := FrameLeft ;
        Session.FrameBottom := FrameBottom ;
        Session.FrameRight := FrameRight ;
        Session.BinFactor := BinFactor ;

        end ;
     end ;


procedure AndorSDK3_Wait( Delay : Single ) ;
var
  T : Integer ;
  TExit : Integer ;
begin
    T := TimeGetTime ;
    TExit := T + Round(Delay*1E3) ;
    while T < TExit do begin
       T := TimeGetTime ;
       end ;
    end ;


function AndorSDK3_CheckFrameInterval(
          var Session : TAndorSDK3Session ;   // Camera session record
          FrameLeft : Integer ;   // Left edge of capture region (In)
          FrameRight : Integer ;  // Right edge of capture region( In)
          FrameTop : Integer ;    // Top edge of capture region( In)
          FrameBottom : Integer ; // Bottom edge of capture region (In)
          BinFactor : Integer ;   // Pixel binning factor (In)
          FrameWidthMax : Integer ;   // Max frame width (in)
          FrameHeightMax : Integer ;  // Max. frame height (in)
          Var FrameInterval : Double ;
          Var ReadoutTime : Double ) : LongBool ;
// ----------------------------------------
// Check that inter-frame interval is valid
// ----------------------------------------
var
    TRead : Double ;
    TempWidth,TempHeight : Integer ;
begin

     if not Session.CameraOpen then Exit ;

     ANDORSDK3_CheckROIBoundaries( Session,
                                   FrameLeft,
                                   FrameRight,
                                   FrameTop,
                                   FrameBottom,
                                   BinFactor,
                                   FrameWidthMax,
                                   FrameHeightMax,
                                   TempWidth,
                                   TempHeight,
                                   ) ;

     AndorSDK3_GetDouble( Session.CamHandle, 'ReadoutTime', TRead ) ;
     ReadoutTime := (2*TRead) + 1E-4 ;
     FrameInterval := Max(FrameInterval,ReadoutTime) ;

     end ;


procedure AndorSDK3_GetImage(
          var Session : TAndorSDK3Session  // Camera session record
          ) ;
// ------------------------------------------------------
// Transfer images from Andor driverbuffer to main buffer
// ------------------------------------------------------
var
    NumFramesAcquired,MaxFramesPerCall,NumBytes,err : Integer ;
    PImageBuffer : Pointer ;
    pBuf : PWordArray ;
    pRBuf : Pointer ;
    Done,Acquiring : LongBool ;
begin

    if not Session.CameraOpen then Exit ;
    if Session.GetImageInUse then Exit ;
    Session.GetImageInUse := True ;

    // Transfer acquired buffers into output
    // Wait 1ms when first unacquired buffer encountered
    repeat
      Err := AT_WaitBuffer( Session.CamHandle, pRBuf, NumBytes, 1 ) ;
      until Err = AT_ERR_TIMEDOUT ;

    Done := False ;
    NumFramesAcquired := 0 ;
    MaxFramesPerCall := Session.NumFramesInBuffer div 2 ;
    repeat
      // Get pointer to next internal image buffer in list
      pBuf := Session.pBuf64[Session.FramePointer] ;
      if (pBuf^[Session.ImageEnd] <> EmptyFlag) or
         (pBuf^[Session.ImageEnd-1] <> 0) then begin
         AT_QueueBuffer( Session.CamHandle, pBuf, Session.NumBytesPerFrameBuffer ) ;
         Inc(Session.FramePointer) ;
         if Session.FramePointer >= Session.NumFramesInBuffer then Session.FramePointer := 0 ;
         Inc(Session.NumFramesAcquired) ;
         Inc(NumFramesAcquired) ;
         if NumFramesAcquired >= MaxFramesPerCall then Done := True ;
         end
      else Done := True ;
      until Done ;
    //outputdebugstring(pchar(format('%d %d %d',[Session.FramePointer,NumFramesAcquired,MaxFramesPerCall])));
    Session.GetImageInUse := False ;

    end ;


procedure AndorSDK3_StopCapture(
          var Session : TAndorSDK3Session   // Camera session record
          ) ;
// ------------------
// Stop frame capture
// ------------------
var
    i,Err : Integer ;
begin

     if not Session.CameraOpen then Exit ;
     if not Session.CapturingImages then Exit ;

     // Stop capture
     AndorSDK3_CheckError( 'AT_Command:AcquisitionStop',
                           AT_Command( Session.CamHandle, 'AcquisitionStop' )) ;

     // Flush buffers
     AndorSDK3_CheckError( 'AT_Flush',AT_Flush( Session.CamHandle )) ;

     Session.CapturingImages := False ;

     end;


procedure AndorSDK3_CheckError(
          FuncName : String ;   // Name of function called
          ErrNum : Integer      // Error # returned by function
          ) ;
// ------------
// Report error
// ------------
var
    Report : string ;
begin
    if ErrNum <> AT_SUCCESS then
       ShowMessage(format('%s Err=%d',[FuncName,ErrNum])) ;
    end ;


function  AndorSDK3_GetChar(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : WideString ) : LongBool ;  // Returned value
// -----------------------------------
// Get current value of a text feature
// -----------------------------------
var
    wcFeature : PWideChar ;
    Implemented,Readable : LongBool ;
    MaxLength : Integer ;
begin
    Value := '' ;
    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsReadable( CamHandle, PWideCHar(Feature), Readable ) ;
    if not Readable then Exit ;

    AT_GetStringMaxLength( CamHandle, PWideCHar(Feature), MaxLength ) ;
    SetLength( Value, MaxLength ) ;
    AT_GetString( CamHandle, PWideChar(Feature), PWideChar(Value), MaxLength ) ;
    Value := WideString( PWideChar(Value)) ;
    Result := True ;

    end ;


function  AndorSDK3_GetInt64(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : Int64 ) : LongBool ;       // Returned value
// ----------------------------------------------
// Get current value of an integer number feature
// ----------------------------------------------
var
    wcFeature : PWideChar ;
    Implemented,Readable : LongBool ;
begin
    Value := 0 ;
    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsReadable( CamHandle, PWideCHar(Feature), Readable ) ;
    if not Readable then Exit ;

    AT_GetInt( CamHandle, PWideChar(Feature), Value ) ;

    Result := True ;

    end ;


function  AndorSDK3_SetInt64(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : Int64 ) : LongBool ;       // Returned value
// ----------------------------------------------
// Set current value of an integer number feature
// ----------------------------------------------
var
    wcFeature : PWideChar ;
    Implemented,Writable : LongBool ;
    Err : Integer ;
begin

    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsWritable( CamHandle, PWideCHar(Feature), Writable ) ;
    //if not Writable then Exit ;

    Err := AT_SetInt( CamHandle, PWideChar(Feature), Value ) ;
    //outputdebugstring(pchar(format('%s %d',[Feature,Err]))) ;
    Result := True ;

    end ;


function  AndorSDK3_GetDouble(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                  // Feature name
          var Value : Double ) : LongBool ;       // Returned value
// --------------------------------------------------------------
// Get current value of an double precision number camera feature
// --------------------------------------------------------------
var
    wcFeature : PWideChar ;
    Implemented,Readable : LongBool ;
begin
    Value := 0 ;
    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsReadable( CamHandle, PWideCHar(Feature), Readable ) ;
    if not Readable then Exit ;

    AT_GetFloat( CamHandle, PWideChar(Feature), Value ) ;

    Result := True ;

    end ;

function  AndorSDK3_SetDouble(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;              // Feature name
          Value : Double ) : LongBool ;       // Returned value
// --------------------------------------------------------------
// Get current value of an double precision number camera feature
// --------------------------------------------------------------
var
    wcFeature : PWideChar ;
    Implemented,Writable : LongBool ;
begin

    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsWritable( CamHandle, PWideCHar(Feature), Writable ) ;
    if not Writable then Exit ;

    AT_SetFloat( CamHandle, PWideChar(Feature), Value ) ;

    Result := True ;

    end ;


function  AndorSDK3_GetBoolean(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : LongBool ) : LongBool ;       // Returned value
// -------------------------------------------------
// Get current value of a TRUE/FALSE camera feature
// -------------------------------------------------
var
    wcFeature : PWideChar ;
    Implemented,Readable : LongBool ;
begin
    Value := False ;
    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsReadable( CamHandle, PWideCHar(Feature), Readable ) ;
    if not Readable then Exit ;

    AT_GetBool( CamHandle, PWideChar(Feature), Value ) ;

    Result := True ;

    end ;

function  AndorSDK3_SetBoolean(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;              // Feature name
          Value : LongBool ) : LongBool ;       // Returned value
// -------------------------------------------------
// Get current value of a TRUE/FALSE camera feature
// -------------------------------------------------
var
    Implemented,Writable : LongBool ;
    Err : Integer ;
begin

    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    AT_IsWritable( CamHandle, PWideCHar(Feature), Writable ) ;
    if not Writable then Exit ;

    Err := AT_SetBool( CamHandle, PWideChar(Feature), Value ) ;
    //if Err <> AT_SUCCESS then ShowMessage('Unable to set '+ Feature) ;

    Result := True ;

    end ;


function  AndorSDK3_GetEnumeratedList(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          List : TStringList                    // Returns list of available settings
           ) : LongBool ;  // Returned value
// -----------------------------------
// Get current value of a text feature
// -----------------------------------
var
    wcFeature : PWideChar ;
    Implemented,IndexImplemented,Available : LongBool ;
    i,MaxLength,NumIndices,Err : Integer ;
    Value : WideString ;
begin

    List.Clear ;
    List.Add('n/a') ;
    Result := False ;

    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;

    // Get number of indices
    Err := AT_GetEnumeratedCount( CamHandle, PWideChar(Feature), NumIndices ) ;
    if Err <> AT_SUCCESS then exit ;

    List.Clear ;
    for i := 0 to NumIndices-1 do begin
        AT_IsEnumeratedIndexImplemented( CamHandle, PWideCHar(Feature), i, IndexImplemented ) ;
        if IndexImplemented then begin
           MaxLength := 255 ;
           SetLength( Value, MaxLength ) ;
           AT_GetEnumeratedString( CamHandle, PWideChar(Feature), i, PWideChar(Value), MaxLength ) ;
           Value := WideString( PWideChar(Value)) ;
           List.Add(Value) ;
           Result := True ;
           end ;
         end ;

    if List.Count <= 0 then List.Add('n/a') ;

    end ;


function  AndorSDK3_GetEnumerated(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          var Value : WideString                    // Returns setting
          ) : LongBool ;  // Returned status
// -----------------------------------------
// Get current value of an enumerated feature
// ------------------------------------------
var
    wcFeature : PWideChar ;
    Implemented,IndexImplemented,Available : LongBool ;
    Index,MaxLength,NumIndices,Err : Integer ;
begin

    Result := False ;
    Value := '' ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;

    AT_GetEnumerated( CamHandle, PWideCHar(Feature), Index ) ;
    MaxLength := 255 ;
    SetLength( Value, MaxLength ) ;
    AT_GetEnumeratedString( CamHandle, PWideChar(Feature), Index, PWideChar(Value), MaxLength ) ;
    Value := WideString( PWideChar(Value)) ;

    end ;


function  AndorSDK3_SetEnumerated(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : WideString ) : LongBool ;  // Returned value
// -----------------------------------------
// Set value of an enumerated camera feature
// -----------------------------------------
var
    wcFeature : PWideChar ;
    Implemented : LongBool ;
    Err : Integer ;
begin

    Result := False ;
    AT_IsImplemented( CamHandle, PWideCHar(Feature), Implemented ) ;
    if not Implemented then Exit ;
    if Value = 'n/a' then Exit ;
    Err := AT_SetEnumeratedString( CamHandle, PWideChar(Feature), PWideChar(Value) ) ;
    if Err = AT_SUCCESS then Result := True ;
    end ;


function  AndorSDK3_SetEnumeratedByIndex(
          CamHandle : Integer ;                 // Camera handle
          Feature : WideString ;                // Feature name
          Value : Integer ) : LongBool ;        // New Index
// -----------------------------------------
// Set value of an enumerated camera feature
// -----------------------------------------
var
    Implemented,Available : LongBool ;
begin

    Result := False ;
    AT_IsEnumeratedIndexImplemented( CamHandle, PWideCHar(Feature), Value, Implemented ) ;
    if not Implemented then Exit ;
    AT_IsEnumeratedIndexAvailable( CamHandle, PWideCHar(Feature), Value, Available ) ;
    if not Available then Exit ;

    AT_SetEnumerated( CamHandle, PWideChar(Feature), Value ) ;

    Result := True ;

    end ;


end.
