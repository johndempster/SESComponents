unit Itex;
{ ================================================================================
  Interface unit for Imaging Technology ITEX library
  (c) J. Dempster, University of Strathclyde
  31/7/01 Started
  13/6/3
  1/2/5
  8/7/5 .... Higher performance frame transfer implemented using
             polling of frame grabber with 20 ms timed routine   

 ================================================================================ }
interface

uses sysutils, Dialogs, classes, mmsystem ;

Const
  VME_STD_MODE = 1 ;
  VME_EXT_MODE = 0 ;
  INQUIRE = -1 ;
  OFF = 0 ;
  ITEX_ON = 1 ;
  ITX_OFF = 0 ;
  ITX_ON = 1 ;
  ITX_SKIP = -1 ;
  ITX_SET = 0 ;
  ITX_GET = 1 ;
  ITX_BSWAP_OFF = 0 ;       // disable byteswap
  ITX_BSWAP_ON = 1 ;        // enable byteswap
  ITX_MBOARD = 0 ;          // mother board
  ITX_DBOARD = 1 ;          // daughter board
  ITX_TBOARD = 2 ;          // translator board
  SEQ0 = 100 ;
  SEQ1 = 101 ;
  SEQ2 = 102 ;
  SEQ3 = 103 ;
  SEQ4 = 104 ;
  SEQ5 = 105 ;
  SEQ6 = 106 ;
  SEQ7 = 107 ;
  SEQ8 = 108 ;
  SEQ9 = 109 ;
  ITX_MAXSYSTEMS = 8 ;

	ICP_FREEZE = 0 ;
	ICP_SNAP   = 2 ;
	ICP_GRAB   = 3 ;


ICP_FRAMEA0 = 0 ;
ICP_FRAMEA1 = 1 ;
ICP_FRAMEA = 2 ;
ICP_FRAMEB0 = 3 ;
ICP_FRAMEB1 = 4 ;
ICP_FRAMEB = 5 ;
ICP_FRAMERGB = 7 ;

ITX_INQUIRE = -1 ;
ITX_FREEZE_BITS = 0 ;
ITX_SNAP_BITS = 2 ;
ITX_GRAB_BITS = 3 ;


	ICP_PIX8        = 8 ;
	ICP_PIX16       = 16 ;
	ICP_PIX24       = 24;
	ICP_PIX32       = 32;




// ITEX Error ants
  ITX_NO_ERROR = 0 ;               // successfull operation */
  ITX_GEN_ERROR = -1 ;              // general/generic error */
  ITX_FILE_ERROR = -2 ;             // File I/O error */
  ITX_FORMAT_ERROR = -3 ;           // format error */
  ITX_ALLOC_ERROR = -4 ;            // memory allocation error */
  ITX_ACCESS_ERROR = -5 ;           // access error */
  ITX_MATH_ERROR = -6 ;             // math error */
  ITX_TIMEOUT = -7 ;                // time out error */
  ITX_BADARG = -8 ;                 // bad argument error */
  ITX_BADCNF = -9 ;                 // Bad configuration variable */
  ITX_BAD_MODCNF = -10 ;            // Bad MODCNF structure pointer */
  ITX_BAD_ROICNF = -11 ;            // Bad ROICNF structure pointer */
  ITX_BAD_IFILE = -12 ;             // Bad image file or filename */
  ITX_BAD_SPEED = -13 ;             // Bad Speed */
  ITX_BAD_ID = -14 ;                // Bad Module ID */
  ITX_DEALLOC_ERROR = -15 ;         // memory deallocation (free) error */
  ITX_BAD_SYS = -16 ;               // Bad system number (e.g. empty cnflist) */
  ITX_BAD_INTRID = -17 ;            // Invalid (disconnected) interrupt event id */
  ITX_OS_ERROR = -18 ;              // Host OS reported error */
  ITX_RESOURCE_BUSY = -19 ;         // Cannot obtain resource */
  ITX_DIAG_ERROR = -20 ;            // Itex Diagnostic System Error */
  IPL_ERROR = -21 ;                 // Itex Image Processing Library Error*/
  ITX_OBSOLETE = -22 ;              // Function is obsolete */
  ITX_WRONG_SERIALNO = -23 ;        // application - wrong serial#  */
  ITX_WRONG_OEMNO = -24 ;           // application - wrong OEM #            */
  ITX_PRODUCT_EXPIRED = -25 ;       // application - product expired        */
  ITX_PRODUCT_MAXCNT = -26 ;        // application - max execute count exceeded */
  ITX_SWP_BAD_AUTHCODE = -27 ;      // No valid authorization code found. */
  ITX_SWP_AUTH_FAULT = -28 ;        // General Software Protection Authorize fault */
  ITX_INVALID_DRIVER_HANDLE = -29 ;        // bad driver handle associated with ITex//s kernel mode driver (only for NT, OS/2, ...) */
  ITX_OS_NO_SUPPORT = -30 ;                // This operating system does not support this function */
  ITX_STRETCH_TO_FIT = -1 ;        // Used for decimation/zoom during display

// error types */
   WARNING = 1 ;                     // low incidence error */
   SEVERE = 2 ;                      // high incidence error */
   ABORT = 3 ;                       // abortive condition */
   MAX_ERRLVL = 3 ;                  // maximum error level value */

// error message display methods */
   ITX_NO_EMSG = 1 ;                 // don//t use error messages */
   ITX_DISP_EMSG = 2 ;               // display err messages as they occur */
   ITX_QUE_EMSG = 3 ;                // queue error messages */
   ITX_FILE_EMSG = 4 ;               // store errors msgs in a file */
   MAX_EMSG_STATE = 4 ;              // maximum error msg disp state value */

   AMDIG_PSIZE8 = 0 ;
   AMDIG_PSIZE10 = 1 ;
   AMDIG_PSIZE12 = 2 ;
   AMDIG_PSIZE16 = 3 ;

   FrameEmptyFlag = 32000 ;

type

TCP_COLOR =(
	ICP_MONO,
	ICP_RED,
	ICP_GREEN,
	ICP_BLUE,
	ICP_RGB,
	ICP_MONO_WORD_LO,
	ICP_MONO_WORD_HI,
	ICP_YCRCB,
	ICP_RGB_PLANAR,
	ICP_YCRCBMONO,
	ICP_RGB_PACK24
) ;

  TITEX = record
        ConfigFileName : string ;
        PModHandle : Pointer ;
        AModHandle : Pointer ;
        GrabHandle : Pointer ;
        FrameWidth : Word ;
        FrameHeight : Word ;
        FrameID : SmallInt ;
        FrameNum : Integer ;
        NumFrames : Integer ;
        NumFramesTotal : SmallInt  ;
        FrameBuf : Pointer ;
        NumBytesPerFrame : Integer ;
        NumBytesPerPixel : Integer ;
        CaptureInProgress : Boolean ;
        SystemInitialised : Boolean ;
        HostTransferPossible : Boolean ;
        TimerProcInUse : Boolean ;
        TimerID : Integer ;

        end ;
PITEX = ^TITEX ;

    TITX_HW_PARAMS = (
        ITX_HW_ART_REV,
        ITX_HW_ECO,
        ITX_HW_SERIAL_NUM,
        ITX_HW_DISP_KIND,
        ITX_BRD_KIND,   //* value of type ITX_BRD_TYPE */
        ITX_MAX_HW_PARAM ) ;

    TITX_BRD_TYPE = (
        ITX_BRD_NULL,
        ITX_BRD_PA,
        ITX_BRD_IMS,
        ITX_BRD_IMA,
        ITX_BRD_IML,
        ITX_BRD_ICVL,
        ITX_BRD_ICP,
        ITX_BRD_IMP,
        ITX_BRD_CMP,
        ITX_BRD_IMV,
        ITX_BRD_ICA,
	ITX_NUM_BRD_TYPES ) ;

Titx_init_sys = Function(
                SysNum : SmallInt
                ) : SmallInt ; stdcall ;
Titx_remove_sys = Function(
                  SysNum : SmallInt
                  ) : SmallInt ; stdcall ;
Titx_show_cnf = Function(
                PModule : Pointer
                ) : SmallInt ; stdcall ;
Titx_init = Function(
            PModule : Pointer
            ) : SmallInt ; stdcall ;

Titx_load_cnf = Function(
                itxpath : PChar
                ) : SmallInt ; stdcall ;

Titx_get_modcnf = Function(
                  PModule : Pointer ;
                  ModuleName : PChar ;
                  Location : SmallInt
                  ) : Pointer ; stdcall ;

Titx_get_brd_param = Function(
                     PModule : Pointer ;
                     ParamID : TITX_HW_PARAMS ;
                     var Result : Cardinal
                     ) : SmallInt ; stdcall ;

Titx_get_acq_dim = Function(
                   PModule : Pointer ;
                   var FrameWidth : Word ;
                   var FrameHeight : Word
                   ) : SmallInt ; stdcall ;

Titx_get_am = Function(
              AModule : Pointer
              ) : Pointer ; stdcall ;

Titx_grab = Function(
            PModule : Pointer ;
            Frame : SmallInt
            ) : SmallInt ; stdcall ;

Titx_grab_latest_seqnum = Function(
                          GrabID : Pointer ;
                          LockNum : Boolean ;
                          var Frame : Pointer ;
                          WaitNewer : Boolean
                          ) : Integer ; stdcall ;

Titx_imagefile_props = Function(
                       FileName : PChar ;
                       Source : Array of Byte ;
                       var dx : SmallInt ;
                       var dy : SmallInt ;
                       var ImageClass : SmallInt ;
                       var Bits : SmallInt ;
                       var Compress : SmallInt
                       ) : SmallInt ; stdcall ;

Titx_acqbits  = Function(
                PModule : Pointer ;
                FrameID : SmallInt ;
                Mode : SmallInt
                ) : SmallInt ; stdcall ;

Titx_snap = Function(
            PModule : Pointer ;
            Frame : SmallInt
            ) : SmallInt ; stdcall ;

Titx_wait_acq = Function(
                PModule : Pointer ;
                Frame : SmallInt
                ) : SmallInt ; stdcall ;

Titx_snap_async = Function(
                  PModule : Pointer ;
                  Frame : SmallInt
                  ) : SmallInt ; stdcall ;

Titx_read_area = Function(
                 PModule : Pointer ;
                 Frame : SmallInt ;
                 x : SmallInt ;
                 y : SmallInt ;
                 dx : SmallInt ;
                 dy : SmallInt ;
                 Buf : PByteArray
                 ) : SmallInt ; stdcall ;


Titx_host_grab = Function(
                 PModule : Pointer ;
                 Dest : PByteArray ;
                 NumFrames : Integer
                 ) : Pointer ; stdcall ;

Titx_host_grab_area = Function(
                      PModule : Pointer ;
                      x : SmallInt ;
                      y : SmallInt ;
                      dx : SmallInt ;
                      dy : SmallInt ;
                      Dest : PByteArray ;
                      NumFrames : Integer
                      ) : Pointer ; stdcall ;

Titx_host_grab_lock = Function(
                      GrabID : Pointer ;
                      SeqNum : Integer
                      ) : SmallInt ; stdcall ;

Titx_host_grab_release = Function(
                         GrabID : Pointer ;
                         SeqNum : Integer
                         ) : SmallInt ; stdcall ;

Titx_host_grab_stop = Function(
                      GrabID : Pointer
                      ) : SmallInt ; stdcall ;


Titx_host_snap = Function(
                 PModule : Pointer ;
                 Dest : PByteArray
                 ) : SmallInt ; stdcall ;

Titx_host_snap_area = Function(
                      PModule : Pointer ;
                      x : SmallInt ;
                      y : SmallInt ;
                      dx : SmallInt ;
                      dy : SmallInt ;
                      Dest : Array of Byte
                      ) : SmallInt ; stdcall ;

Titx_host_trig_read = Function(
                      PModule : Pointer ;
                      Dest : Array of Byte
                      ) : SmallInt ; stdcall ;

Titx_host_trig_snap = Function(
                      PModule : Pointer ;
                      Dest : Array of Byte
                      ) : SmallInt ; stdcall ;

Titx_host_wait_trig = Function(
                      PModule : Pointer ;
                      Dest : Array of Byte ;
                      WaitTime : Integer
                      ) : SmallInt ; stdcall ;

Titx_host_start_acq = Function(
                      PModule : Pointer ;
                      x : SmallInt ;
                      y : SmallInt ;
                      dx : SmallInt ;
                      dy : SmallInt ;
                      Dest : Array of Byte ;
                      RingNumFrames : Integer ;
                      TotalNumFrames : Integer
                      ) : Integer ; stdcall ;

Titx_host_start_dualtap_acq = Function(
                              PModule : Pointer ;
                              x : SmallInt ;
                              y : SmallInt ;
                              dx : SmallInt ;
                              dy : SmallInt ;
                              Dest : Array of Byte ;
                              RingNumFrames : Integer ;
                              TotalNumFrames : Integer
                              ) : Integer ; stdcall ;

Titx_host_frame_seqnum = Function(
                         GrabID : Pointer ;
                         RingFrameNumber : Integer
                         ) : Integer ; stdcall ;

Titx_host_wait_acq = Function(
                     GrabID : Pointer ;
                     SeqenceNumber : Integer ;
                     TimeOutMiliSec : Integer ;
                     LockFrame : Integer ;
                     Buff : Array of Integer
                     ) : Integer ; stdcall ;

Titx_read_performance = Function(
                        PModule : Pointer
                        ) : Single ; stdcall ;

Titx_select_cam_port = Function(
                       PModule : Pointer ;
                       Port : SmallInt
                       ) : SmallInt ; stdcall ;

Titx_set_port_camera = Function(
                       PModule : Pointer ;
                       CameraName : PChar ;
                       Port : SmallInt
                       ) : SmallInt ; stdcall ;

Titx_strcpy  = Function(
               OutStr : PChar ;
               InStr : PChar
               ) : PChar ; stdcall ;

Titx_get_modname = Function(
                   PModule : Pointer
                   ) : Integer ; stdcall ;

Titx_create_host_frame = Function(
                         PModule : Pointer ;
                         FrameID : SmallInt ;
                         NumFrames : Integer
                         ) : SmallInt ; stdcall ;

Titx_delete_all_hframes = Function(
                          PModule : Pointer
                          ) : SmallInt ; stdcall ;

Titx_host_frame_lock = Function(
                       PModule : Pointer ;
                       FrameID : SmallInt ;
                       FrameNum : Integer
                       ) : Pointer ; stdcall ;

Titx_host_frame_unlock = Procedure(
                       PModule : Pointer ;
                       FrameID : SmallInt ;
                       FramNum : Integer ;
                       FramePointer : Pointer
                       ) ; stdcall ;


Ticp_create_frame = Function(
                    PModule : Pointer ;
                    dx : SmallInt ;
                    dy : SmallInt ;
                    Depth : SmallInt ;
                    Color : SmallInt
                    ) : SmallInt ; stdcall ;

Ticp_delete_frame = Function(
                    PModule : Pointer ;
                    FrameID : SmallInt
                    ) : SmallInt ; stdcall ;

Ticp_delete_all_frames = Function(
                         PModule : Pointer
                        ) : SmallInt ; stdcall ;



Ticp_start_ping_pong = Function(
                       PModule : Pointer ;
                       Frame1 : SmallInt ;
                       Frame2 : SmallInt ;
                       RecordMode : SmallInt
                       ) : SmallInt ; stdcall ;

Ticp_stop_ping_pong = Function(
                      PModule : Pointer
                      ) : SmallInt ; stdcall ;

Ticp_get_active_ubm_frame  = Function(
                             PModule : Pointer ;
                             Context : Integer ;
                             var CurrentFrame : SmallInt
                             ) : SmallInt ; stdcall ;

Ticp_acq_addr_status  = Function(
                        PModule : Pointer
                        ) : SmallInt ; stdcall ;

Ticp_acq_pending  = Function(
                    PModule : Pointer
                    ) : SmallInt ; stdcall ;

Ticp_clr_frame = Function(
                 PModule : Pointer ;
                 FrameID : SmallInt ;
                 Value : Integer
                 ) : SmallInt ; stdcall ;

Ticp_clr_area = Function(
                 PModule : Pointer ;
                 FrameID : SmallInt ;
                 x : SmallInt ;
                 y  : SmallInt ;
                 dx : SmallInt ;
                 dy : SmallInt ;
                 Value : Integer
                 ) : SmallInt ; stdcall ;

Ticp_rpix = Function(
                 PModule : Pointer ;
                 FrameID : SmallInt ;
                 x : SmallInt ;
                 y  : SmallInt
                 ) : Integer ; stdcall ;

Tamdig_hact = Function(
              PModule : Pointer ;
              Size : SmallInt
              ) : SmallInt ; stdcall ;

Tamdig_vact = Function(
              PModule : Pointer ;
              Size : SmallInt
              ) : SmallInt ; stdcall ;

Tamdig_psize = Function(
               PModule : Pointer ;
               Size : SmallInt
               ) : SmallInt ; stdcall ;


function ITEX_StartCapture(
         var ITEX : TITEX ;
         FrameLeft : Integer ;
         FrameRight : Integer ;
         FrameTop : Integer ;
         FrameBottom : Integer ;
         FrameBuf : Pointer ;
         NumFrames : Integer ;
         var FrameWidth : Integer ;
         var FrameHeight : Integer
         ) : Boolean ;

procedure ITEX_TimerProc(
          uID,uMsg : SmallInt ;
          ITEX : PITEX ;
          dw1,dw2 : LongInt ) ; stdcall ;

function ITEX_StopCapture(
         var ITEX : TITEX ) : Boolean ;

function ITEX_OpenFrameGrabber(
         var ITEX : TITEX ;
         CameraInfo : TStringList ;
         NumBytesPerPixel : Integer ;
         PCVision : Boolean
         ) : Boolean ;

procedure ITEX_LoadLibrary  ;

function ITEX_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;


procedure ITEX_CloseFrameGrabber( var ITEX : TITEX )  ;

function ITEX_GetLatestFrameNumber( var ITEX : TITEX ) : Integer ;



var
  ITX_init_sys : Titx_init_sys ;
  ITX_remove_sys : Titx_remove_sys ;
  ITX_show_cnf : Titx_show_cnf  ;
  ITX_init : Titx_init ;
  ITX_load_cnf : Titx_load_cnf ;
  ITX_get_modcnf  : Titx_get_modcnf  ;
  ITX_get_brd_param  : Titx_get_brd_param  ;
  ITX_get_acq_dim  : Titx_get_acq_dim  ;
  ITX_get_am  : Titx_get_am  ;
  ITX_grab : Titx_grab ;
  ITX_read_area : TITX_read_area ;
  ITX_grab_latest_seqnum : Titx_grab_latest_seqnum ;
  ITX_imagefile_props : Titx_imagefile_props ;
  ITX_snap : Titx_snap ;
  ITX_snap_async : Titx_snap_async ;
  ITX_wait_acq : TITX_wait_acq ;
  ITX_acqbits : Titx_acqbits ;
  ITX_host_grab  : Titx_host_grab  ;
  ITX_host_grab_area : Titx_host_grab_area  ;
  ITX_host_grab_lock  : Titx_host_grab_lock  ;
  ITX_host_grab_release : Titx_host_grab_release  ;
  ITX_host_grab_stop : Titx_host_grab_stop  ;
  ITX_host_snap : Titx_host_snap ;
  ITX_host_snap_area : Titx_host_snap_area ;
  ITX_host_trig_read : Titx_host_trig_read ;
  ITX_host_trig_snap : Titx_host_trig_snap ;
  ITX_host_wait_trig : Titx_host_wait_trig ;
  ITX_host_start_acq : Titx_host_start_acq ;
  ITX_host_start_dualtap_acq  :Titx_host_start_dualtap_acq ;
  ITX_host_frame_seqnum : Titx_host_frame_seqnum ;
  ITX_host_wait_acq : Titx_host_wait_acq ;
  ITX_read_performance : Titx_read_performance ;
  ITX_select_cam_port : Titx_select_cam_port ;
  ITX_set_port_camera : Titx_set_port_camera ;
  ITX_strcpy : Titx_strcpy ;
  ITX_get_modname : Titx_get_modname ;
  ITX_create_host_frame : Titx_create_host_frame ;
  ITX_delete_all_hframes : Titx_delete_all_hframes ;

  ITX_host_frame_lock : Titx_host_frame_lock ;
  ITX_host_frame_unlock : Titx_host_frame_unlock ;

  ICP_create_frame : TICP_create_frame ;
  icp_delete_frame : Ticp_delete_frame ;
  icp_delete_all_frames : Ticp_delete_all_frames ;

  ICP_start_ping_pong : Ticp_start_ping_pong ;
  ICP_stop_ping_pong : Ticp_stop_ping_pong ;
  ICP_get_active_ubm_frame : Ticp_get_active_ubm_frame ;
  icp_acq_addr_status : Ticp_acq_addr_status ;
  icp_clr_frame : Ticp_clr_frame ;
  icp_clr_area : Ticp_clr_area ;
  icp_acq_pending : Ticp_acq_pending ;
  icp_rpix : Ticp_rpix ;


  amdig_hact : Tamdig_hact ;
  amdig_vact : Tamdig_vact ;
  amdig_psize : Tamdig_psize ;

  LibraryLoaded : Boolean ;

implementation

uses WinTypes ;


procedure ITEX_LoadLibrary  ;
{ ---------------------------------
  Load itex.DLL library into memory
  ---------------------------------}
var
    LibFileName : string ;
    FileName : string ;
    LibraryHnd : THandle ;
begin

     // Load ITEX interface DLL library
     LibFileName := '' ;
     if FileExists('c:\itex41\lib\itxco10.dll') then
        LibFileName := 'c:\itex41\lib\itxco10.dll'
     else if FileExists('c:\itex33\lib\itxco10.dll') then
        LibFileName := 'c:\itex33\lib\itxco10.dll' ;
//     else begin
//        FileName := ExtractFilePath(ParamStr(0)) + '\itxco10.dll' ;
//        if FileExists(FileName) then LibFileName := FileName ;
//        end ;

     LibraryHnd := LoadLibrary(PChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @ITX_init_sys :=ITEX_GetDLLAddress(LibraryHnd,'itx_init_sys') ;
        @ITX_remove_sys :=ITEX_GetDLLAddress(LibraryHnd,'itx_remove_sys') ;
        @ITX_show_cnf :=ITEX_GetDLLAddress(LibraryHnd,'itx_show_cnf') ;
        @ITX_init :=ITEX_GetDLLAddress(LibraryHnd,'itx_init') ;
        @ITX_load_cnf :=ITEX_GetDLLAddress(LibraryHnd,'itx_load_cnf') ;
        @ITX_get_modcnf :=ITEX_GetDLLAddress(LibraryHnd,'itx_get_modcnf') ;
        @ITX_get_brd_param :=ITEX_GetDLLAddress(LibraryHnd,'itx_get_brd_param') ;
        @ITX_get_acq_dim :=ITEX_GetDLLAddress(LibraryHnd,'itx_get_acq_dim') ;
        @ITX_get_am  :=ITEX_GetDLLAddress(LibraryHnd,'itx_get_am') ;
        @ITX_grab :=ITEX_GetDLLAddress(LibraryHnd,'itx_grab') ;
        @ITX_grab_latest_seqnum :=ITEX_GetDLLAddress(LibraryHnd,'itx_grab_latest_seqnum') ;
        @ITX_imagefile_props :=ITEX_GetDLLAddress(LibraryHnd,'itx_imagefile_props') ;
        @ITX_snap :=ITEX_GetDLLAddress(LibraryHnd,'itx_snap') ;
        @ITX_wait_acq :=ITEX_GetDLLAddress(LibraryHnd,'itx_wait_acq') ;
        @ITX_snap_async :=ITEX_GetDLLAddress(LibraryHnd,'itx_snap_async') ;
        @ITX_acqbits :=ITEX_GetDLLAddress(LibraryHnd,'itx_acqbits') ;
        @ITX_read_area :=ITEX_GetDLLAddress(LibraryHnd,'itx_read_area') ;
        @ITX_host_grab :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_grab') ;
        @ITX_host_grab_area :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_grab_area') ;
        @ITX_host_grab_lock :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_grab_lock') ;
        @ITX_host_grab_release :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_grab_release') ;
        @ITX_host_grab_stop :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_grab_stop') ;
        @ITX_host_snap :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_snap') ;
        @ITX_host_snap_area :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_snap_area') ;
        @ITX_host_trig_read :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_trig_read') ;
        @ITX_host_trig_snap :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_trig_snap') ;
        @ITX_host_wait_trig :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_wait_trig') ;
        @ITX_host_start_acq :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_start_acq') ;
        @ITX_host_frame_seqnum :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_frame_seqnum') ;
        @ITX_host_wait_acq :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_wait_acq') ;
        @ITX_read_performance :=ITEX_GetDLLAddress(LibraryHnd,'itx_read_performance') ;
        @ITX_select_cam_port :=ITEX_GetDLLAddress(LibraryHnd,'itx_select_cam_port') ;
        @ITX_set_port_camera :=ITEX_GetDLLAddress(LibraryHnd,'itx_set_port_camera') ;
        @ITX_strcpy :=ITEX_GetDLLAddress(LibraryHnd,'itx_strcpy') ;
        @ITX_get_modname :=ITEX_GetDLLAddress(LibraryHnd,'itx_get_modname') ;
        @ITX_create_host_frame :=ITEX_GetDLLAddress(LibraryHnd,'itx_create_host_frame') ;
        @ITX_delete_all_hframes :=ITEX_GetDLLAddress(LibraryHnd,'itx_delete_all_hframes') ;
        @ITX_host_frame_lock :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_frame_lock') ;
        @ITX_host_frame_unlock :=ITEX_GetDLLAddress(LibraryHnd,'itx_host_frame_unlock') ;
        @ICP_create_frame :=ITEX_GetDLLAddress(LibraryHnd,'icp_create_frame') ;
        @icp_delete_frame :=ITEX_GetDLLAddress(LibraryHnd,'icp_delete_frame') ;
        @icp_delete_all_frames :=ITEX_GetDLLAddress(LibraryHnd,'icp_delete_all_frames') ;
        @ICP_start_ping_pong :=ITEX_GetDLLAddress(LibraryHnd,'icp_start_ping_pong') ;
        @ICP_stop_ping_pong :=ITEX_GetDLLAddress(LibraryHnd,'icp_stop_ping_pong') ;
        @ICP_get_active_ubm_frame :=ITEX_GetDLLAddress(LibraryHnd,'icp_get_active_ubm_frame') ;
        @icp_acq_addr_status :=ITEX_GetDLLAddress(LibraryHnd,'icp_acq_addr_status') ;
        @icp_clr_frame :=ITEX_GetDLLAddress(LibraryHnd,'icp_clr_frame') ;
        @icp_clr_area :=ITEX_GetDLLAddress(LibraryHnd,'icp_clr_area') ;
        @icp_rpix :=ITEX_GetDLLAddress(LibraryHnd,'icp_rpix') ;
        @icp_acq_pending :=ITEX_GetDLLAddress(LibraryHnd,'icp_acq_pending') ;

        @amdig_hact := ITEX_GetDLLAddress(LibraryHnd,'amdig_hact') ;
        @amdig_vact := ITEX_GetDLLAddress(LibraryHnd,'amdig_vact') ;
        @amdig_psize := ITEX_GetDLLAddress(LibraryHnd,'amdig_psize') ;        

        LibraryLoaded := True ;
        end
     else begin
          MessageDlg( LibFileName + ' not found!', mtWarning, [mbOK], 0 ) ;
          LibraryLoaded := False ;
          end ;


     end ;


function ITEX_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// ---------------------------------------------
// Get address of procedure within ITEX library
// ---------------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       MessageDlg('itxco10.DLL: ' + ProcName + ' not found',mtWarning,[mbOK],0) ;
    end ;


function ITEX_OpenFrameGrabber(
         var ITEX : TITEX ;
         CameraInfo : TStringList ;    // Camera information (OUT)
         NumBytesPerPixel : Integer ;  // Bytes per pixel
         PCVision : Boolean            // PCVISION board in use
         ) : Boolean ;
// -----------------------------------
// Initialise frame grabber sub-system
// -----------------------------------
var
     dwValue : Cardinal ;
     NumW,NumH : SmallInt ;
begin

     Result := False ;

     // Load ITEX interface library (if necessary)
     if not LibraryLoaded then ITEX_LoadLibrary ;
     if not LibraryLoaded then Exit ;

     // Load camera configuration from file
     if itx_load_cnf(PChar(ITEX.ConfigFileName)) <> ITX_NO_ERROR then begin
        MessageDlg('Could not load config file ' + ITEX.ConfigFileName,
        mtInformation,[mbOk], 0);
        Exit ;
        end ;

     // Initialise system
     if itx_init_sys(0) <> ITX_NO_ERROR then begin
        MessageDlg('System Initialisation failed!', mtInformation,[mbOk], 0) ;
        ITEX.SystemInitialised := False ;
        Exit ;
        end
     else ITEX.SystemInitialised := True ;

     // Get pointer to frame grabber module
     if PCVision then ITEX.PModHandle := itx_get_modcnf( Nil, Nil, SEQ0 )
                 else ITEX.PModHandle := itx_get_modcnf( Nil, 'ICP', SEQ0 ) ;
     if ITEX.PModHandle = Nil then begin
        MessageDlg('Frame grabber module not found!', mtInformation,[mbOk], 0);
        Exit ;
        end ;

     // Get pointer to acquisition module
     ITEX.AModHandle := itx_get_am( ITEX.PModHandle ) ;
     if ITEX.AModHandle = Nil then begin
        MessageDlg('Acquisition module not found!', mtInformation,[mbOk], 0);
        Exit ;
        end ;

     // Get camera frame dimensions
     if itx_get_acq_dim( ITEX.PModHandle, ITEX.FrameWidth, ITEX.FrameHeight ) <> ITX_NO_ERROR then
        MessageDlg('Error reading camera frame dimensions ',mtInformation,[mbOk], 0);

     // Create a camera frame
     ITEX.NumBytesPerPixel := NumBytesPerPixel ;

     if itx_get_brd_param( ITEX.PModHandle, ITX_BRD_KIND, dwValue ) = ITX_NO_ERROR then
        CameraInfo.Add(format('Frame grabber board type = %d',[dwValue])) ;

     if itx_get_brd_param( ITEX.PModHandle, ITX_HW_SERIAL_NUM, dwValue ) = ITX_NO_ERROR then
        CameraInfo.Add(format('Frame grabber Serial #%d',[dwValue])) ;

     // Enable DMA-based transfer if available
     if PCVision then ITEX.HostTransferPossible := True
                 else ITEX.HostTransferPossible := False ;

     // Clear frame polling timer fields
     ITEX.TimerID := -1 ;
     ITEX.TimerProcInUse := False ;

     CameraInfo.Add(
     format('Frame size w=%d, h=%d',[ITEX.FrameWidth,ITEX.FrameHeight])) ;

     Result := True ;

     end ;


procedure ITEX_CloseFrameGrabber( var ITEX : TITEX )  ;
// -----------------------------------
// Shut down frame grabber sub-system
// -----------------------------------
begin
     if ITEX.SystemInitialised then begin

        // Delete any existing frames
        icp_delete_all_frames(ITEX.PModHandle) ;

        itx_remove_sys(0) ;
        ITEX.SystemInitialised := False ;
        ITEX.PModHandle := Nil ;
        ITEX.AModHandle := Nil ;
        end ;

     // Stop timer (if still running)
     if ITEX.TimerID >= 0 then begin
        timeKillEvent( ITEX.TimerID ) ;
        ITEX.TimerID := -1 ;
        end ;

     end ;


function ITEX_StartCapture(
         var ITEX : TITEX ;
         FrameLeft : Integer ;        // Left edge of capture region
         FrameRight : Integer ;       // Right edge of capture region
         FrameTop : Integer ;         // Top edge of capture region
         FrameBottom : Integer ;      // Bottom edge of capture region
         FrameBuf : Pointer ;         // Pointer to frame storage buffer
         NumFrames : Integer ;        // No. frames in storage buffer
         var FrameWidth : Integer ;   // Frame width (OUT)
         var FrameHeight : Integer    // Frame height (OUT)
         ) : Boolean ;
// ------------------------------------------
// Start capture of images into frame buffer
// ------------------------------------------
const
     TimerTickInterval = 20 ; // Timer tick resolution (ms)
begin

     // Ensure frame limits are valid for use with frame grabber hardware
     if (FrameLeft mod 8) <> 0 then
        MessageDlg(
        'ITEX_StartCapture : FrameLeft must be multiple of 8!',
        mtInformation,[mbOk], 0) ;

     FrameWidth := FrameRight - FrameLeft + 1 ;
     FrameWidth := (FrameWidth div 4)*4 ;
     FrameHeight := FrameBottom - FrameTop + 1 ;
     ITEX.FrameWidth := FrameWidth ;
     ITEX.FrameHeight := FrameHeight ;

     // Delete any existing frames
     icp_delete_all_frames(ITEX.PModHandle) ;

     // Create a camera frame
     if (ITEX.NumBytesPerPixel < 2) then begin
        // 2 byte pixels
        ITEX.FrameID := ICP_Create_Frame(
                        ITEX.PModHandle,
                        ITEX.FrameWidth,
                        ITEX.FrameHeight,
                        8,
                        0 ) ;
        end
     else begin
        // Single byte pixels
        ITEX.FrameID := ICP_Create_Frame(
                          ITEX.PModHandle,
                          ITEX.FrameWidth,
                          ITEX.FrameHeight,
                          16,
                          0 ) ;
        end ;

     // Clear camera frame
     icp_clr_frame( ITEX.PModHandle, ITEX.FrameID, FrameEmptyFlag ) ;

  {   if (FrameWidth mod 16) <> 0 then
        MessageDlg(
        'ITEX_StartCapture : FrameWidth must be multiple of 16!',
        mtInformation,[mbOk], 0) ;}

     // Set frame width and height within acquisition module
     amdig_hact( ITEX.AModHandle, FrameWidth-1 ) ;
     amdig_vact( ITEX.AModHandle, FrameHeight-1 ) ;
     amdig_psize( ITEX.AModHandle, AMDIG_PSIZE12 ) ;

     Result := False ;

     if FrameBuf = Nil then begin
        MessageDlg('ITEX_StartCapture failed! (Frame buffer not allocated)', mtInformation,[mbOk], 0) ;
        exit ;
        end ;

     if ITEX.PModHandle = Nil then begin
        MessageDlg('ITEX_StartCapture failed! (No PModule)', mtInformation,[mbOk], 0) ;
        exit ;
        end ;

     if ITEX.HostTransferPossible then begin
        // If DMA transfer to host buffer possible - use it
        // ------------------------------------------------
        if ITEX.GrabHandle = Nil then  begin
           ITEX.GrabHandle := itx_host_grab_area(
                              ITEX.PModHandle,
                              SmallInt(FrameLeft),
                              SmallInt(FrameTop),
                              SmallInt(FrameRight - FrameLeft + 1),
                              SmallInt(FrameBottom - FrameTop + 1),
                              FrameBuf,
                              NumFrames ) ;
           if ITEX.GrabHandle = Nil then
               MessageDlg('ITEX_StartCapture failed! (itx_host_grab failed)', mtInformation,[mbOk], 0)
           else Result := True ;

           end ;
        end
     else begin

        // DMA transfer not available -
        // Monitor frame buffer at 20ms intervals
        // and read frame-by-frame from ITEX_TimerProc
        // --------------------------------------------------------------
        ITEX.NumFrames := NumFrames ;
        ITEX.FrameNum := 0 ;
        ITEX.NumBytesPerFrame := FrameWidth*FrameHeight*ITEX.NumBytesPerPixel ;
        ITEX.FrameBuf := FrameBuf ;

        // Clear buffer in frame grabber memory
        icp_clr_frame( ITEX.PModHandle, ITEX.FrameID, FrameEmptyFlag ) ;

        // Disable timer if it is running
        if ITEX.TimerID >= 0 then begin
           timeKillEvent( ITEX.TimerID ) ;
           ITEX.TimerID := -1 ;
           end ;

        // Start frame acquisition monitor procedure
        ITEX.TimerProcInUse := False ;
        ITEX.TimerID := TimeSetEvent( TimerTickInterval,
                                      TimerTickInterval,
                                      @ITEX_TimerProc,
                                      Cardinal(@ITEX),
                                      TIME_PERIODIC ) ;

        // Start continuous frame capture into buffer on frame grabber card
        itx_acqbits( ITEX.PModHandle, ITEX.FrameID, ITX_GRAB_BITS ) ;

        Result := True ;
        end ;

     ITEX.CaptureInProgress := True ;
     end ;


function ITEX_StopCapture(
         var ITEX : TITEX ) : Boolean ;
// ------------------------------------------
// Stop capture of images into frame buffer
// ------------------------------------------
begin

     if ITEX.HostTransferPossible then begin
        // Disable continuous frame capture & transfer
        if ITEX.GrabHandle <> Nil then begin
           itx_host_grab_stop( ITEX.GrabHandle ) ;
           ITEX.GrabHandle := Nil ;
           end ;
        end
     else begin
        // Stop continuous frame capture within card
        itx_acqbits( ITEX.PModHandle, ITEX.FrameID, ITX_FREEZE_BITS ) ;

        // Disable timer if it is running
        if ITEX.TimerID >= 0 then begin
           timeKillEvent( ITEX.TimerID ) ;
           ITEX.TimerID := -1 ;
           end ;

        end ;

     ITEX.CaptureInProgress := False ;
     Result := ITEX.CaptureInProgress ;

     end ;


function  ITEX_GetLatestFrameNumber( var ITEX : TITEX ) : Integer ;
// ------------------------------------------
// Stop capture of images into frame buffer
// ------------------------------------------
var
     FramePointer : Pointer ;
begin
     if ITEX.GrabHandle <> Nil then
        Result := itx_grab_latest_seqnum( ITEX.GrabHandle, False, FramePointer, False )
     else Result := -1 ;
     end ;


procedure ITEX_TimerProc(
          uID,uMsg : SmallInt ;
          ITEX : PITEX ;
          dw1,dw2 : LongInt ) ; stdcall ;
{ -----------------------------------------------------------------
  Frame monitor and read polling procedure, called at 20ms intervals
  ----------------------------------------------------------------- }
var
    Err : Integer ;
    FramePointer : Pointer ;
    EndPixel : Integer ;
begin
    // Quit if DMA transfer possible (should not have been called)
    if ITEX^.HostTransferPossible then Exit ;

    // Prevent multiple entry
    if ITEX^.TimerProcInUse then Exit ;

    // Set in use flag
    ITEX^.TimerProcInUse := True ;

    // Read last pixel in frame
    // (Non-zero indicates frame available)
    EndPixel := icp_rpix( ITEX^.PModHandle,
                          ITEX^.FrameID,
                          ITEX^.FrameWidth-1,
                          ITEX^.FrameHeight-1 ) ;

    // If frame available transfer to host frame buffer
    if EndPixel <> FrameEmptyFlag then begin
       FramePointer := Pointer(ITEX^.FrameNum*ITEX^.NumBytesPerFrame + Integer(ITEX^.FrameBuf)) ;
       itx_read_area( ITEX^.PModHandle,
                      ITEX^.FrameID,
                      0,
                      0,
                      ITEX^.FrameWidth,
                      ITEX^.FrameHeight,
                      FramePointer ) ;
       Inc(ITEX^.FrameNum) ;
       if ITEX^.FrameNum >= ITEX^.NumFrames then ITEX^.FrameNum := 0 ;
       // Clear buffer in frame grabber memory
       icp_clr_frame( ITEX^.PModHandle, ITEX^.FrameID, FrameEmptyFlag ) ;
       end ;

    ITEX^.TimerProcInUse := False ;

    end ;



Initialization
    LibraryLoaded := False ;

end.
