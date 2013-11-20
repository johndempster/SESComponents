unit pvcam;
//  -------------------------------------------
// Princeton Instruments Camera Control module
// -------------------------------------------
// (c) John Dempster, Un
// 11/3/02 Virtual chip support added
// 10/10/03 pl_exp_init_seq in PVCAM_StartCapture now comes after call to
//          PVCAM_CheckFrameInterval since this procedure calls pl_exp_uninit_seq
// 12/05/06 Camera now closed properly in PVCAM_Close
// 18/06/06 Tested with CoolSnap FX (readout_time not supported)
// 24.07.06 Now uses PVCAM32.dll from Windows system folder
// 13.02.07 Support for Cascade EMCCD camera added
//          Temperature now read correctly
//          PVCAMSession record now added
//          Virtual chip modes disabled
// 21/01/09 AdditionalReadoutTime added to StartCapture
// 16/04/09 PVCAM_CheckROIBoundaries added
// 05/02/10 External triggering of photometric cameras now works in non-overlap mode
//          Exposure time of camera adjusted to allow for non-overlapped readout
//          after exposure.
// 07.09.10 JD CCD clear pre-exposure or pre-sequence now set explicitly
// 15.12.10 JD Camera now operates in frame transfer mode again
// 01.02.11 JD Exposure time in ext. trigger mode can now be shortened to
//             account for post-exposure readout in camera which do not support
//             overlap readout mode. Post exposure readout enabled by
//             PostExposureReadout = TRUE in StartCapture
//

{OPTIMIZATION OFF}
{$DEFINE USECONT}

interface
uses classes,math ;
const

//*********************** Class 2: Data types ********************************/
// Data type used by pl_get_param with attribute type (ATTR_TYPE).          */
        TYPE_CHAR_PTR = 13 ;     // char
        TYPE_INT8 = 12;         // signed char
        TYPE_UNS8 = 5 ;         // unsigned char
        TYPE_INT16 = 1 ;        // short
        TYPE_UNS16 = 6 ;        // unsigned short
        TYPE_INT32 = 2 ;         // long
        TYPE_UNS32 = 7 ;        // unsigned long
        TYPE_FLT64 = 4 ;        // double
        TYPE_ENUM = 9 ;         // Can be treat as unsigned long
        TYPE_BOOLEAN = 11 ;     // Boolean value
        TYPE_VOID_PTR = 14 ;     // ptr to void
        TYPE_VOID_PTR_PTR = 15 ; // void ptr to a ptr.

        CLASS0 = 0 ;      // Camera Communications
        CLASS1 = 1 ;      // Error Reporting
        CLASS2 = 2 ;      // Configuration/Setup
        CLASS3 = 3 ;      // Data Acuisition                              */
        CLASS4 = 4 ;      // Buffer Manipulation                          */
        CLASS5 = 5 ;      // Analysis                                     */
        CLASS6 = 6 ;      // Data Export                                  */
        CLASS29 = 29 ;    // Buffer Functions                             */
        CLASS30 = 30 ;    // Utility functions                            */
        CLASS31 = 31 ;    // Memory Functions                             */
        CLASS32 = 32 ;    // CCL Engine                                   */
        CLASS91 = 91 ;	 // RS170
        CLASS95	= 95 ;   // Virtual chip    


        PARAM_DD_INFO_LENGTH = ((CLASS0 shl 16) + (TYPE_INT16 shl 24) + 1) ;
        PARAM_DD_VERSION = ((CLASS0 shl 16) + (TYPE_UNS16 shl 24) + 2) ;
        PARAM_DD_RETRIES = ((CLASS0 shl 16) + (TYPE_UNS16 shl 24) + 3) ;
        PARAM_DD_TIMEOUT = ((CLASS0 shl 16) + (TYPE_UNS16 shl 24) + 4) ;

//* Camera Parameters Class 2 variables */

//* Class 2 (next available index for class two = 534) */

//* CCD skip parameters */
//* Min Block. amount to group on the shift register, to through way. */
        PARAM_MIN_BLOCK = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 60) ;
//* number of min block groups to use before valid data. */
        PARAM_NUM_MIN_BLOCK = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 61) ;
//* Strips per clear. Used to define how many clears to use for continous clears
//* and with clears to define the clear area at the beginning of an experiment
        PARAM_NUM_OF_STRIPS_PER_CLR = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 98) ;
//* Only applies to Thompson ST133 5Mhz
//* enables or disables anti-blooming.   */
        PARAM_ANTI_BLOOMING = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)  + 293) ;
//* This applies to ST133 1Mhz and 5Mhz and PentaMax V5 controllers. For the ST133 */
//* family this controls whether the BNC (not scan) is either not scan or shutter  */
//* for the PentaMax V5, this can be not scan, shutter, not ready, clearing, logic 0 */
//* logic 1, clearing, and not frame transfer image shift.                         */
//* See enum below for possible values                                             */
        PARAM_LOGIC_OUTPUT = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)  + 66) ;
//* Edge Trigger defines whether the external sync trigger is positive or negitive */
//* edge active. This is for the ST133 family (1 and 5 Mhz) and PentaMax V5.0.     */
//* see enum below for possible values.                                            */
        PARAM_EDGE_TRIGGER = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)  + 106) ;
//* Intensifier gain is currently only used by the PI-Max and has a range of 0-255 */
        PARAM_INTENSIFIER_GAIN = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 216) ;
//* Shutter, Gate, or Safe mode, for the PI-Max. */
        PARAM_SHTR_GATE_MODE = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)  + 217) ;
//* ADC offset setting. */
        PARAM_ADC_OFFSET = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 195) ;
//* CCD chip name.    */
        PARAM_CHIP_NAME = ((CLASS2 shl 16) + (TYPE_CHAR_PTR shl 24)  + 129) ;

        PARAM_COOLING_MODE = ((CLASS2 shl 16) + (TYPE_ENUM  shl 24)  + 214) ;
	PARAM_PREAMP_DELAY = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 502) ;
	PARAM_PREFLASH =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 503);
	PARAM_COLOR_MODE =   ((CLASS2 shl 16) + (TYPE_ENUM  shl 24)  + 504) ;
	PARAM_MPP_CAPABLE =  ((CLASS2 shl 16) + (TYPE_ENUM  shl 24)  + 224) ;
	PARAM_PREAMP_OFF_CONTROL = ((CLASS2 shl 16) + (TYPE_UNS32 shl 24)  + 507);
	PARAM_SERIAL_NUM =   ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 508) ;

//* CCD Dimensions and physical characteristics */
//* pre and post dummies of CCD. */
	PARAM_PREMASK =      ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 53) ;
	PARAM_PRESCAN =      ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 55);
	PARAM_POSTMASK =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 54) ;
	PARAM_POSTSCAN =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 56);
	PARAM_PIX_PAR_DIST = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 500);
	PARAM_PIX_PAR_SIZE = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 63);
	PARAM_PIX_SER_DIST = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 501);
	PARAM_PIX_SER_SIZE = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 62);
	PARAM_SUMMING_WELL = ((CLASS2 shl 16) + (TYPE_BOOLEAN shl 24)  + 505);
	PARAM_FWELL_CAPACITY = ((CLASS2 shl 16) + (TYPE_UNS32 shl 24)  + 506);
//* Y dimension of active area of CCD chip */
	PARAM_PAR_SIZE = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 57) ;
//* X dimension of active area of CCD chip */
	PARAM_SER_SIZE = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 58) ;

//* General parameters */
//* Is the controller on and running? */
        PARAM_CONTROLLER_ALIVE = ((CLASS2 shl 16) + (TYPE_BOOLEAN shl 24)+ 168) ;
//* Readout time of current ROI, in ms */
        PARAM_READOUT_TIME = ((CLASS2 shl 16) + (TYPE_FLT64 shl 24)  + 179) ;

//* CAMERA PARAMETERS (CLASS 2) */

	PARAM_CLEAR_CYCLES = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 97) ;
	PARAM_CLEAR_MODE = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)  + 523) ;
  PARAM_FRAME_CAPABLE = ((CLASS2 shl 16) + (TYPE_BOOLEAN shl 24)  + 509) ;
	PARAM_PMODE = ((CLASS2 shl 16) + (TYPE_ENUM  shl 24)  + 524) ;
	PARAM_CCS_STATUS = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 510) ;

//* This is the actual temperature of the detector. This is only a get, not a set */
	PARAM_TEMP = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 525) ;
//* This is the desired temperature to set. */
	PARAM_TEMP_SETPOINT =      ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 526) ;
	PARAM_CAM_FW_VERSION =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 532) ;
	PARAM_HEAD_SER_NUM_ALPHA = ((CLASS2 shl 16) + (TYPE_CHAR_PTR shl 24)  + 533) ;
        PARAM_PCI_FW_VERSION =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 534) ;

//* Exsposure mode, timed strobed etc, etc
	PARAM_EXPOSURE_MODE = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)  + 535) ;

//* SPEED TABLE PARAMETERS (CLASS 2)

        PARAM_BIT_DEPTH =    ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 511) ;
	PARAM_GAIN_INDEX =   ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 512) ;
	PARAM_SPDTAB_INDEX = ((CLASS2 shl 16) + (TYPE_INT16 shl 24)  + 513) ;
//* define which port (amplifier on shift register) to use. */
        PARAM_READOUT_PORT = ((CLASS2 shl 16) + (TYPE_ENUM shl 24) + 247) ;
	PARAM_PIX_TIME =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 516) ;

//* SHUTTER PARAMETERS (CLASS 2) */

	PARAM_SHTR_CLOSE_DELAY = ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 519) ;
	PARAM_SHTR_OPEN_DELAY =  ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 520) ;
	PARAM_SHTR_OPEN_MODE =   ((CLASS2 shl 16) + (TYPE_ENUM  shl 24)  + 521) ;
	PARAM_SHTR_STATUS =      ((CLASS2 shl 16) + (TYPE_ENUM  shl 24)  + 522) ;

//* I/O PARAMETERS (CLASS 2) */

	PARAM_IO_ADDR =      ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 527) ;
	PARAM_IO_TYPE =      ((CLASS2 shl 16) + (TYPE_ENUM shl 24)   + 528) ;
	PARAM_IO_DIRECTION = ((CLASS2 shl 16) + (TYPE_ENUM shl 24)   + 529) ;
	PARAM_IO_STATE =     ((CLASS2 shl 16) + (TYPE_FLT64 shl 24)  + 530) ;
	PARAM_IO_BITDEPTH =  ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)  + 531) ;

//* GAIN MULTIPLIER PARAMETERS (CLASS 2) */

  PARAM_GAIN_MULT_FACTOR =     ((CLASS2 shl 16) + (TYPE_UNS16 shl 24)     + 537) ;
  PARAM_GAIN_MULT_ENABLE =     ((CLASS2 shl 16) + (TYPE_BOOLEAN shl 24)   + 541) ;


//* ACQUISITION PARAMETERS (CLASS 3) (next available index for class three = 5) */

	PARAM_EXP_TIME =      ((CLASS3 shl 16) + (TYPE_UNS16 shl 24)  + 1) ;
	PARAM_EXP_RES =       ((CLASS3 shl 16) + (TYPE_ENUM shl 24)   + 2) ;
	PARAM_EXP_MIN_TIME =  ((CLASS3 shl 16) + (TYPE_FLT64 shl 24)  + 3) ;
	PARAM_EXP_RES_INDEX = ((CLASS3 shl 16) + (TYPE_UNS16 shl 24)  + 4) ;

//* PARAMETERS FOR  BEGIN and END of FRAME Interrupts */
        PARAM_BOF_EOF_ENABLE = ((CLASS3 shl 16) + (TYPE_ENUM shl 24)    + 5) ;
        PARAM_BOF_EOF_COUNT = ((CLASS3 shl 16) + (TYPE_UNS32 shl 24)   + 6) ;
        PARAM_BOF_EOF_CLR = ((CLASS3 shl 16) + (TYPE_BOOLEAN shl 24) + 7) ;

//* Test to see if hardware/software can perform circular buffer */
        PARAM_CIRC_BUFFER = ((CLASS3 shl 16) + (TYPE_BOOLEAN shl 24) + 299) ;


        OPEN_EXCLUSIVE = 0 ;
//************************** Class 2: Name/ID sizes *
        CCD_NAME_LEN = 17 ;         //* Includes space for the null terminator
        MAX_ALPHA_SER_NUM_LEN = 32 ; //* Includes space for the null terminator
// Class 1: Error message size
        ERROR_MSG_LEN = 255 ;  //* No error message will be longer than this */


//* Virtual Chip parameters

        // enable virtual chip. This can be set to true (enable) or false (disable).
        PARAM_VIRTUALCHIP_ENABLE = ((CLASS95 shl 16) + (TYPE_INT32 shl 24) + 254) ;
        // Allows y dimension information to be either set or retrieved
        PARAM_VIRTUALCHIP_Y_DIM = ((CLASS95 shl 16) + (TYPE_ENUM shl 24) + 255) ;
        // Allows x dimension information to be either set or retrieved.
        PARAM_VIRTUALCHIP_X_DIM = ((CLASS95 shl 16) + (TYPE_INT32 shl 24) + 256) ;
        // Allows number of frames per interrupt to be set.
        PARAM_VIRTUALCHIP_NUMBER_FRAMES_IRQ = ((CLASS95 shl 16) + (TYPE_INT32 shl 24) + 204);

type
{$MINENUMSIZE 2}

TPVCAMSession = record
    Handle : SmallInt ;
    CameraOpen : Boolean ;
    Temperature : Single ;
    end ;

// Class 0: Abort Exposure flags
TCCS = (CCS_NO_CHANGE,CCS_HALT,CCS_HALT_CLOSE_SHTR,CCS_CLEAR,
        CCS_CLEAR_CLOSE_SHTR,CCS_OPEN_SHTR,CCS_CLEAR_OPEN_SHTR ) ;

// Class 0: Readout status flags
TReadoutStatus = ( READOUT_NOT_ACTIVE,EXPOSURE_IN_PROGRESS,READOUT_IN_PROGRESS,
                   READOUT_COMPLETE,READOUT_FAILED,ACQUISITION_IN_PROGRESS ) ;

// Class 2: Cooling type flags
TCooling = ( NORMAL_COOL,CRYO_COOL );

// Class 2: MPP capability flags
TMPP = ( MPP_UNKNOWN,MPP_ALWAYS_OFF,MPP_ALWAYS_ON,MPP_SELECTABLE ) ;

// Class 2: Shutter flags
TShutter =( SHTR_FAULT,SHTR_OPENING,SHTR_OPEN,SHTR_CLOSING,SHTR_CLOSED,
        SHTR_UNKNOWN ) ;

// Class 2: Pmode constants
TPMode = ( PMODE_NORMAL,PMODE_FT,PMODE_MPP,PMODE_FT_MPP,
        PMODE_ALT_NORMAL,PMODE_ALT_FT,PMODE_ALT_MPP,PMODE_ALT_FT_MPP ) ;

// Class 2: Color support constants
TColorSupport = (COLOR_NONE,COLOR_DUMMY,COLOR_RGGB ) ;

// Class 2: Attribute IDs
{$MINENUMSIZE 2}
TParamAttribute = ( ATTR_CURRENT,ATTR_COUNT,ATTR_TYPE,ATTR_MIN,ATTR_MAX,ATTR_DEFAULT,
                    ATTR_INCREMENT,ATTR_ACCESS, ATTR_AVAIL ) ;

// Class 2: Access types
{$MINENUMSIZE 2}
TAttr_Access =  ( ACC_ERROR,ACC_READ_ONLY,ACC_READ_WRITE,ACC_EXIST_CHECK_ONLY,
                  ACC_WRITE_ONLY ) ;
//* This enum is used by the access Attribute

//      Class 2: I/O types
TIOType = (IO_TYPE_TTL,IO_TYPE_DAC ) ;

// Class 2: I/O direction flags
TIODirection = (IO_DIR_INPUT,IO_DIR_OUTPUT,IO_DIR_INPUT_OUTPUT ) ;

// Class 2: I/O port attributes
TIOAttribute = (IO_ATTR_DIR_FIXED,IO_ATTR_DIR_VARIABLE_ALWAYS_READ );

// Class 2: Trigger polarity
//* used with the PARAM_EDGE_TRIGGER parameter id.
TTriggerPolarity = (EDGE_0, EDGE_1, EDGE_TRIG_POS, EDGE_TRIG_NEG ) ;

// Class 2: Logic Output
//* used with the PARAM_LOGIC_OUTPUT parameter id.
TLogicOutput = ( OUTPUT_NOT_SCAN, OUTPUT_SHUTTER, OUTPUT_NOT_RDY, OUTPUT_LOGIC0,
                 OUTPUT_CLEARING, OUTPUT_NOT_FT_IMAGE_SHIFT, OUTPUT_RESERVED,
                 OUTPUT_LOGIC1 ) ;

// Class 2: PI-Max intensifer gating settings
//* used with the PARAM_SHTR_GATE_MODE parameter id.
TIntensifier = ( INTENSIFIER_SAFE, INTENSIFIER_GATING, INTENSIFIER_SHUTTER ) ;

// Class 2: Readout Port
//* used with the PARAM_READOUT_PORT parameter id.
TReadoutPort = (READOUT_PORT1, {st133 low noise} READOUT_PORT2 {st133 high capacity} ) ;

// Class 2: Anti Blooming
//* used with the PARAM_ANTI_BLOOMING parameter id.
TAntiBlooming = ( ANTIBLOOM_NOTUSED, ANTIBLOOM_INACTIVE, ANTIBLOOM_ACTIVE ) ;


// Class 3: Clearing mode flags
TClearMode = ( CLEAR_NEVER,CLEAR_PRE_EXPOSURE,CLEAR_PRE_SEQUENCE,CLEAR_POST_SEQUENCE,
               CLEAR_PRE_POST_SEQUENCE,CLEAR_PRE_EXPOSURE_POST_SEQ ) ;

// Class 3: Shutter mode flags
TShutterMode = ( OPEN_NEVER,OPEN_PRE_EXPOSURE,OPEN_PRE_SEQUENCE,OPEN_PRE_TRIGGER,
                 OPEN_NO_CHANGE ) ;

// Class 3: Exposure mode flags
TExposureMode = (TIMED_MODE,STROBED_MODE,BULB_MODE,TRIGGER_FIRST_MODE,FLASH_MODE,
                 VARIABLE_TIMED_MODE ) ;

// Class 3: Event constants
TEvent = ( EVENT_START_READOUT,EVENT_END_READOUT ) ;

// Class 3: EOF/BOF constants
TFrameIRQ = ( NO_FRAME_IRQS,BEGIN_FRAME_IRQS,END_FRAME_IRQS,BEGIN_END_FRAME_IRQS ) ;

// Class 3: Continuous Mode constants
TCircMode = (CIRC_NONE,CIRC_OVERWRITE,CIRC_NO_OVERWRITE );

// Class 3: Fast Exposure Resolution constants
TFastExposure = ( EXP_RES_ONE_MILLISEC,EXP_RES_ONE_MICROSEC ) ;

// Class 3: I/O Script Locations
TScript =( SCR_PRE_OPEN_SHTR,SCR_POST_OPEN_SHTR,SCR_PRE_FLASH,SCR_POST_FLASH,
           SCR_PRE_INTEGRATE,SCR_POST_INTEGRATE,SCR_PRE_READOUT,SCR_POST_READOUT,
           SCR_PRE_CLOSE_SHTR,SCR_POST_CLOSE_SHTR ) ;

TRegion = packed record
        s1 : Word ;
        s2 : Word ;
        sBin : Word ;
        p1 : Word ;
        p2 : Word ;
        pBin : Word ;
        end ;

// *** Function prototypes for calls to PVCAM32.DLL ***

//************* Class 0: Camera Communications Function Prototypes ************
Tpl_cam_check = function (
                hcam : SmallInt
                ) : Word ; stdcall ;
Tpl_cam_close = function (
                hcam : SmallInt
                ) : Word ; stdcall ;
Tpl_cam_get_diags = function (
                    hcam : SmallInt
                    ) : Word ; stdcall ;
Tpl_cam_get_name = function (
                   cam_num : SmallInt ;
                   cam_name : PChar
                   ) : Word ; stdcall ;
Tpl_cam_get_total = function(
                    var totl_cams : SmallInt
                    ) : Word ; stdcall ;
Tpl_cam_open = function (
               camera_name : PChar ;
               var hcam : SmallInt ;
               o_mode : SmallInt
               ) : Word ; stdcall ;
Tpl_dd_get_info = function(
                   hcam : SmallInt ;
                   bytes : SmallInt ;
                   var text : PChar ) : Word ; stdcall ;

Tpl_ddi_get_ver = function(
                  var version : Word
                  ) : Word ; stdcall ;

Tpl_exp_abort = function (
               hcam : SmallInt ;
               cam_state : SmallInt
               ) : Word ; stdcall ;
Tpl_exp_check_cont_status = function (
                            hcam : SmallInt ;
                            var status : SmallInt ;
                            var byte_cnt : Cardinal ;
                            var buffer_cnt : Cardinal
                            ) : Word ; stdcall ;
Tpl_exp_check_status = function (
                       hcam : SmallInt ;
                       var status : SmallInt ;
                       var byte_cnt : Cardinal
                       ) : Word ; stdcall ;
Tpl_exp_check_progress = function (
                         hcam : SmallInt ;
                         var status : SmallInt ;
                         var byte_cnt : Cardinal
                         ) : Word ; stdcall ;


//**************** Class 1: Error Reporting Function Prototypes ***************/

Tpl_error_code = function : SmallInt ; stdcall ;

Tpl_error_message = function (
                    err_code : SmallInt ;
                    msg : Pointer
                    ) : Word ; stdcall ;

//************** Class 2: Configuration/Setup Function Prototypes *************/

Tpl_pvcam_get_ver = function (
                    var version : Word
                    ) : Word ; stdcall ;
Tpl_pvcam_init = function  : Word ; stdcall ;

Tpl_pvcam_uninit = function  : Word ; stdcall ;

Tpl_get_param = function (
                hcam : SmallInt ;
                param_id : Cardinal ;
                param_attribute : TParamAttribute ;
                param_value : Pointer
                ) : Word ; stdcall ;

Tpl_set_param = function (
                hcam : SmallInt ;
                param_id : Cardinal ;
                param_value : Pointer
                ) : Word ; stdcall ;

Tpl_get_enum_param = function (
                     hcam : SmallInt ;
                     param_id : Cardinal ;
                     index : Cardinal ;
	             value : Pointer ;
                     var desc : PChar ;
                     length : Cardinal
                     ) : Word ; stdcall ;

Tpl_enum_str_length = function (
                      hcam : SmallInt ;
                      param_id : Cardinal ;
                      index : Cardinal ;
                      var length : Cardinal
                      ) : Word ; stdcall ;

//*************** Class 3: Data Acquisition Function Prototypes ***************/

Tpl_exp_init_seq = function  : Word ; stdcall ;

Tpl_exp_finish_seq = function (
                     hcam : SmallInt ;
                     var pixel_stream : Pointer ;
                     hbuf : SmallInt
                     ) : Word ; stdcall ;

Tpl_exp_get_driver_buffer = function (
                            hcam : SmallInt ;
                            var pixel_stream : Pointer ;
                            var byte_cnt : Cardinal
                            ) : Word ; stdcall ;

Tpl_exp_get_latest_frame = function (
                           hcam : SmallInt ;
                           frameptr : Pointer
                           ) : Word ; stdcall ;

Tpl_exp_get_oldest_frame = function (
                           hcam : SmallInt ;
                           frame : Pointer
                           ) : Word ; stdcall ;

Tpl_exp_set_cont_mode = function (
                        hcam : SmallInt ;
                        mode : TCircMode
                        ) : Word ; stdcall ;

Tpl_exp_setup_seq = function (
                    hcam : SmallInt ;
                    exp_total : Word ;
                    rgn_total : Word ;
                    rgn_array : Pointer ;
                    exp_mode : TExposureMode ;
                    exposure_time : Cardinal ;
                    Frame_Size : Pointer
                    ) : Word ; stdcall ;

Tpl_exp_start_cont = function (
                     hcam : SmallInt ;
                     pixel_stream : Pointer ;
                     size : Cardinal
                     ) : Word ; stdcall ;

Tpl_exp_start_seq = function (
                    hcam : SmallInt ;
                    pixel_stream : Pointer
                    ) : Word ; stdcall ;

Tpl_exp_stop_cont = function (
                    hcam : SmallInt ;
                    cam_state : SmallInt
                    ) : Word ; stdcall ;

Tpl_exp_uninit_seq = function  : Word ; stdcall ;

Tpl_exp_get_time_seq = function (
                       hcam : SmallInt ;
                       var exp_time : Word
                       ) : Word ; stdcall ;

Tpl_exp_set_time_seq = function (
                       hcam : SmallInt ;
                       exp_time : Word
                       ) : Word ; stdcall ;

Tpl_exp_unlock_oldest_frame = function (
                              hcam : SmallInt
                              ) : Word ; stdcall ;

Tpl_io_script_control = function (
                        hcam : SmallInt ;
                        addr : Word ;
                        state : Double ;
                        location : Cardinal
                        ) : Word ; stdcall ;

Tpl_io_clear_script_control = function (
                              hcam : SmallInt
                              ) : Word ; stdcall ;

Tpl_exp_setup_cont = function (		 // setup circular buffer
                     hcam : SmallInt ;      	 // camera handle
                     rgn_total : Word ;		 // number of regions of interest in image
                     Region : Pointer {var Region : Array of TRegion} ; // regions of interest
                     exp_mode : TExposureMode ;      // exposure mode (TIMEDMODE, etc...)
                     exposure_time : Cardinal ; 	 // exposure time in milliseconds/microseconds
                     Frame_Size : Pointer ;	 // Image size (bytes)
                     buffer_mode : TCircMode 	 // circular buffer mode(CIRC_OVERWRITE, etc...)
                     ) : Word ; stdcall ;

Tpl_exp_wait_start_xfer = function (
                          hcam : SmallInt ;
                          tlimit : Cardinal
                          ) : Word ; stdcall ;
Tpl_exp_wait_end_xfer = function (
                        hcam : SmallInt ;
                        tlimit : Cardinal
                        ) : Word ; stdcall ;

Tpl_vc_get_param = function (
                   hcam : SmallInt ;
                   param_id : Cardinal ;
                   param_attribute : TParamAttribute ;
                   param_value : Pointer
                   ) : Word ; stdcall ;

Tpl_vc_set_param = function (
                   hcam : SmallInt ;
                   param_id : Cardinal ;
                   param_value : Pointer
                   ) : Word ; stdcall ;

Tpl_vc_exp_setup_cont = function (		      // setup circular buffer
                        hcam : SmallInt ;      	      // camera handle
                        rgn_total : Word ;	      // number of regions of interest in image
                        Region : Pointer ;            // regions of interest
                        exp_mode : TExposureMode ;    // exposure mode (TIMEDMODE, etc...)
                        exposure_time : Cardinal ;    // exposure time in milliseconds/microseconds
                        Frame_Size : Pointer ;	      // Image size (bytes)
                        buffer_mode : TCircMode       // circular buffer mode(CIRC_OVERWRITE, etc...)
                        ) : Word ; stdcall ;

Tpl_vc_get_enum_param = function (
                        hcam : SmallInt ;
                        param_id : Cardinal ;
                        index : Cardinal ;
	                value : Pointer ;
                        var desc : PChar ;
                        length : Cardinal
                        ) : Word ; stdcall ;

Tpl_vc_get_plugin_description = function (
                                msg : PChar ) : Word ; stdcall ;
Tpl_vc_get_ver = function (
                 var Version : Word ) : Word ; stdcall ;

Tpl_vc_init_plugin = function : Word ; stdcall ;

Tpl_vc_uninit_plugin = function : Word ; stdcall ;

Tpl_vc_error_message = function (
                       err_code : SmallInt ;
                       msg : Pointer
                       ) : Word ; stdcall ;

Tpl_vc_error_code = function : SmallInt ; stdcall ;

tpl_ccd_set_pmode = function(
                    hcam : SmallInt ;
                    pmode : Word )  : SmallInt ; stdcall ;

tpl_ccd_get_pmode = function(
                    hcam : SmallInt ;
                    var pmode : Word )  : SmallInt ; stdcall ;


{function pl_exp_unravel(
         hcam : SmallInt ;		//* Handle Of the Camera	*/
         exposure : Word ;		//* -1 for All, otherwise exposure to unravel */
         void_ptr pixel_stream,	        //* Buffer that holds the date...(User or Driver)	*/
         rgn_total : Word ;		       //* Number Of Regions	*/
         rgn_const_ptr rgn_array ; //* Array Of Regions	*/
         var array_list : Word ) : Word ; stdcall ;	//* Array Of Pointers, In the Same Order as regions	*/}

//************* Class 4: Buffer Manipulation Function Prototypes **************/
{Tpl_buf_init = function : Word ; stdcall ;
Tpl_buf_uninit = function : Word ; stdcall ;

function pl_buf_alloc(
         var hbuf : SmallInt ;
         exp_total : SmallInt ;
         bit_depth : SmallInt ;
         rgn_total : SmallInt ;
         rgn_const_ptr rgn) : Word ; stdcall ;
function pl_buf_get_bits(
         hbuf : SmallInt ;
         var bit_depth : SmallInt ) : Word ; stdcall ;
function pl_buf_get_exp_date(
         hbuf : SmallInt ;
         exp_num : SmallInt ;
         var year : SmallInt ;
         var month : Byte ;
         var day : Byte ;
         var hour : Byte ;
         var min : Byte ;
         var sec : Byte ;
         var msec : Word ) : Word ; stdcall ;
function pl_buf_get_exp_time(
         hbuf : SmallInt ;
         exp_num : SmallInt ;
         var exp_msec : Cardinal ) : Word ; stdcall ;
function pl_buf_get_exp_total(
         hbuf : SmallInt ;
         var total_exps : SmallInt ) : Word ; stdcall ;
function pl_buf_get_img_bin(
         himg : SmallInt ;
         var ibin : SmallInt ;
         var jbin : SmallInt ) : Word ; stdcall ;
function pl_buf_get_img_handle(
         hbuf : SmallInt ;
         exp_num : SmallInt ;
         img_num : SmallInt ;
         var himg : SmallInt ) : Word ; stdcall ;
function pl_buf_get_img_ofs(
         himg : SmallInt ;
         var s_ofs : SmallInt ;
         var p_ofs : SmallInt ) : Word ; stdcall ;
function pl_buf_get_img_ptr(
         himg : SmallInt ;
         var img_addr :Pointer
         ) : Word ; stdcall ;
function pl_buf_get_img_size(
         himg : SmallInt ;
         var x_size : SmallInt ;
         var y_size : SmallInt ) : Word ; stdcall ;
function pl_buf_get_img_total(
         hbuf : SmallInt ;
         var totl_imgs : SmallInt ) : Word ; stdcall ;
function pl_buf_get_size(
         hbuf : SmallInt ;
         var buf_size : Integer ) : Word ; stdcall ;
function pl_buf_free(
         hbuf : SmallInt ) : Word ; stdcall ;
function pl_buf_set_exp_date(
         hbuf : SmallInt ;
         exp_num : SmallInt ;
         year : SmallInt ;
         month : Byte ;
         day : Byte ;
         hour : Byte ;
         min : Byte ;
         sec : Byte ;
         msec: SmallInt ) : Word ; stdcall ;  }


// *** Function calls to this unit ***

function PVCAM_OpenCamera(
         var Session : TPVCAMSession ;
         ReadoutSpeedIndex : Integer ;    // Readout speed index
         var FrameWidth : Integer ;       // Width of image frame (Returned)
         var FrameHeight : Integer ;      // Height of image frame (Returned)
         var RNumBytesPerPixel : Integer ; // No. of bytes per pixel data value (Returned)
         var GreyLevelMax : Integer ;      // Maximum grey level value (Returned)
         var PixelWidth : Single ;        // Pixel size (um) (Returned)
         var PixelDepth : Integer ;       // Bits / pixel (Returned)
         CameraInfo : TStrings           // Camera information
         ) : Boolean ;                    // Returned True if camera opened successfully

procedure PVCAM_LoadLibrary  ;

function PVCAM_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;


procedure PVCAM_CloseCamera(
          var Session : TPVCAMSession ) ;

procedure PVCAM_CheckROIBoundaries(
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var  BinFactor : Integer ;           // Pixel binning factor (In)
         FrameWidthMax : Integer ;            // Max. width
         FrameHeightMax : Integer ;           // Max height
         var FrameWidth : Integer ;           // Image width after binning/regioning
         var FrameHeight : Integer            // Image height
         ) ;
          

function PVCAM_CheckFrameInterval(
          var Session : TPVCAMSession ;
          FrameLeft : Integer ;   // Left edge of capture region (In)
          FrameRight : Integer ;  // Right edge of capture region( In)
          FrameTop : Integer ;    // Top edge of capture region( In)
          FrameBottom : Integer ; // Bottom edge of capture region (In)
          BinFactor : Integer ;   // Pixel binning factor (In)
          ReadoutSpeedIndex : Integer ; // Readout speed index # (In)
          Var FrameInterval : Double ;
          Var ReadoutTime : Double) : Boolean ;

procedure PVCAM_GetCameraReadoutSpeedList(
          var Session : TPVCAMSession ;
          CameraReadoutSpeedList : TStringList ) ;

procedure PVCAM_GetCameraGainList(
          var Session : TPVCAMSession ;
          CameraGainList : TStringList ) ;

function PVCAM_StartCapture(
         var Session : TPVCAMSession ;
         FrameLeft : Integer ;              // Left edge of capture region (In)
         FrameRight : Integer ;             // Right edge of capture region( In)
         FrameTop : Integer ;               // Top edge of capture region( In)
         FrameBottom : Integer ;            // Bottom edge of capture region (In)
         BinFactor : Integer ;              // Pixel binning factor (In)
         FrameBuffer : Pointer ;            // Frame storage buffer (In)
         NumBytesInFrameBuffer : Cardinal ; // Size of storage buffer (In)
         var FrameInterval : Double ;       // Duration of interval used (In/Ret)
         AdditionalReadoutTime : Double ;  // Additional readout time
         AmpGain : Integer ;               // Amplifier gain  (In)
         var FrameWidth : Integer ;         // Width of image frame (Out)
         var FrameHeight : Integer ;        // Height of image frame (Out)
         TriggerMode : Integer ;            // Frame capture trigger mode
         ReadoutSpeedIndex : Integer ;       // Camera readout speed option
         ClearCCDPreExposure : Boolean ;     // TRUE = clear CCD before exposure
         PostExposureReadout : Boolean     // TRUE = readout after exposure
                                            // Ext. trig mode only
         ) : Boolean ;                      // True = captured started

function PVCAM_StopCapture(
         var Session : TPVCAMSession
         ) : Boolean ;

function PVCAM_GetLatestFrameNumber(
         var Session : TPVCAMSession
         ) : Integer ;

procedure PVCAM_DisplayErrorMessage(
          Source : string ) ;
procedure PVCAM_VC_DisplayErrorMessage(
          Source : string ) ;
function PVCAM_CharArrayToString( CBuf : Array of Char ) : String ;


var
    // PVCAM32.DLL function variables
    pl_cam_check : Tpl_cam_check ;
    pl_cam_close : Tpl_cam_close ;
    pl_cam_get_diags : Tpl_cam_get_diags ;
    pl_cam_get_name : Tpl_cam_get_name ;
    pl_cam_get_total : Tpl_cam_get_total ;
    pl_cam_open : Tpl_cam_open ;
    pl_dd_get_info : Tpl_dd_get_info ;
    pl_ddi_get_ver : Tpl_ddi_get_ver ;
    pl_exp_abort : Tpl_exp_abort ;
    pl_exp_check_cont_status : Tpl_exp_check_cont_status ;
    pl_exp_check_status : Tpl_exp_check_status ;
    pl_exp_check_progress : Tpl_exp_check_progress ;
    pl_error_code : Tpl_error_code  ;
    pl_error_message : Tpl_error_message ;
    pl_pvcam_get_ver : Tpl_pvcam_get_ver ;
    pl_pvcam_init : Tpl_pvcam_init ;
    pl_pvcam_uninit : Tpl_pvcam_uninit ;
    pl_get_param : Tpl_get_param ;
    pl_set_param : Tpl_set_param ;
    pl_get_enum_param : Tpl_get_enum_param ;
    pl_enum_str_length : Tpl_enum_str_length ;
    pl_exp_init_seq : Tpl_exp_init_seq ;
    pl_exp_finish_seq : Tpl_exp_finish_seq ;
    pl_exp_get_driver_buffer : Tpl_exp_get_driver_buffer ;
    pl_exp_get_latest_frame : Tpl_exp_get_latest_frame ;
    pl_exp_get_oldest_frame : Tpl_exp_get_oldest_frame ;
    pl_exp_set_cont_mode : Tpl_exp_set_cont_mode ;
    pl_exp_setup_seq : Tpl_exp_setup_seq ;
    pl_exp_start_cont : Tpl_exp_start_cont ;
    pl_exp_start_seq : Tpl_exp_start_seq ;
    pl_exp_stop_cont : Tpl_exp_stop_cont ;
    pl_exp_uninit_seq : Tpl_exp_uninit_seq ;
    pl_exp_get_time_seq : Tpl_exp_get_time_seq ;
    pl_exp_set_time_seq : Tpl_exp_set_time_seq ;
    pl_exp_unlock_oldest_frame : Tpl_exp_unlock_oldest_frame ;
    pl_io_script_control : Tpl_io_script_control ;
    pl_io_clear_script_control : Tpl_io_clear_script_control ;
    pl_exp_setup_cont : Tpl_exp_setup_cont ;
    pl_exp_wait_start_xfer : Tpl_exp_wait_start_xfer ;
    pl_exp_wait_end_xfer : Tpl_exp_wait_end_xfer ;
    pl_vc_get_param : Tpl_vc_get_param ;
    pl_vc_set_param : Tpl_vc_set_param ;
    pl_vc_exp_setup_cont : Tpl_vc_exp_setup_cont ;
    pl_vc_get_enum_param : Tpl_vc_get_enum_param ;
    pl_vc_get_plugin_description : Tpl_vc_get_plugin_description ;
    pl_vc_get_ver : Tpl_vc_get_ver ;
    pl_vc_init_plugin : Tpl_vc_init_plugin ;
    pl_vc_uninit_plugin : Tpl_vc_uninit_plugin ;
    pl_vc_error_message : Tpl_vc_error_message ;
    pl_vc_error_code : Tpl_vc_error_code ;
    pl_ccd_set_pmode : tpl_ccd_set_pmode ;
    pl_ccd_get_pmode : tpl_ccd_get_pmode ;



implementation

uses WinTypes,sysutils, dialogs, sescam  ;
//uses Dialogs, SysUtils, WinProcs,mmsystem;

var


    LibraryHnd : THandle ;         // PVCAM32.DLL library handle
    LibraryLoaded : boolean ;      // PVCAM32.DLL library loaded flag

    FrameWidthMax : Integer ;               // Max. width of image frame
    FrameHeightMax : Integer ;              // Max. height of image frame
    FrameRegion : Array[0..10] of TRegion ; // CCD region to be captured
    NumBytesPerPixel : Integer ;            // No. of bytes in image pixel
    NumBytesPerFrame : Cardinal ;           // No. of bytes in image
    NumBytesPerSequence : Cardinal ;        // No. of bytes in image sequence buffer
    FrameBufferStart : Pointer ;            // Pointer to start of current frame

    CameraStatus : SmallInt ;
    FrameIntervals : Array[0..100] of Double ;
    ExposureResolution : Double ;



function PVCAM_OpenCamera(
         var Session : TPVCAMSession ;    // Camera session record
         ReadoutSpeedIndex : Integer ;    // Readout speed index
         var FrameWidth : Integer ;       // Width of image frame (Returned)
         var FrameHeight : Integer ;      // Height of image frame (Returned)
         var RNumBytesPerPixel : Integer ; // No. of bytes per pixel data value (Returned)
         var GreyLevelMax : Integer ;      // Maximum grey level value (Returned)
         var PixelWidth : Single ;        // Pixel size (um) (Returned)
         var PixelDepth : Integer ;       // Bits / pixel (Returned)
         CameraInfo : TStrings           // Camera information
         ) : Boolean ;                    // Returned True if camera opened successfully
//
// Open Camera
// -----------
var
     NumCameras : SmallInt ;
     TempName : Array[0..99] of char ;
     OK,OK1 : Boolean ;
     NumPars,Value : Word ;
     DBValue,FrameInterval,ReadoutTime : Double ;
     i,LongValue : Cardinal ;
     DWValue : Cardinal ;
     Temperature : SmallInt ;
     Available,CircularBufferSupported,FrameTransferCapable,MultGainEnabled : Word ;
begin

     Result := False ;
     Session.CameraOpen := False ;

     // Always two bytes per pixel
     NumBytesPerPixel := 2 ;
     RNumBytesPerPixel := NumBytesPerPixel ;
     ExposureResolution := 0.001 ;

     // Load PVCAM32.DLL library (if necessary)
     if not LibraryLoaded then PVCAM_LoadLibrary ;
     if not LibraryLoaded then Exit ;

     // Initialise PVCAM library
     if pl_pvcam_init = 0 then begin
        PVCAM_DisplayErrorMessage( 'pl_pvcam_init' ) ;
        Exit ;
        end ;

     // Get PVCAM library version number
     if pl_pvcam_get_ver( Value ) <> 0 then begin
        CameraInfo.Add( format('PVCAM V%d.%d.%d Initialised',
                        [Value div $100,(Value and $F0) div $10,Value and $F])) ;
        end
     else CameraInfo.Add('PVCAM: V?.?.? Initialised! ') ;

     // Get virtual device driver version number
     if pl_ddi_get_ver( Value ) <> 0 then begin
        CameraInfo.Add( format('Device driver: V%d.%d.%d',
                        [Value div $100,(Value and $F0) div $10,Value and $F])) ;
        end
     else CameraInfo.Add('Device driver: V?.?.? ') ;

     // Get number of cameras
     pl_cam_get_total(NumCameras) ;
     if NumCameras > 0 then begin
        pl_cam_get_name( 0, TempName ) ;
        CameraInfo.Add('Camera: '+ PVCAM_CharArrayToString(TempName) ) ;
        end
     else begin
        ShowMessage( 'PVCAM: No cameras available!' ) ;
        CameraInfo.Add('PVCAM: No camera available.') ;
        Exit ;
        end ;

     // Open camera
     Session.CameraOpen := False ;
     if pl_cam_open( TempName, Session.Handle, OPEN_EXCLUSIVE ) = 0 then begin
        ShowMessage('PVCAM: Unable to open camera!') ;
        CameraInfo.Add('PVCAM: Unable to open camera!') ;
        Exit ;
        end ;
     Session.CameraOpen := True ;

     // Check diagnostics
     if pl_cam_get_diags( Session.Handle ) <> 0 then CameraInfo.Add('Camera Diagnostics OK ') ;
     PVCAM_DisplayErrorMessage( 'pl_cam_get_diags ' ) ;

     // CCD type
     pl_get_param( Session.Handle, PARAM_CHIP_NAME, ATTR_AVAIL, @Available ) ;
     PVCAM_DisplayErrorMessage( 'pl_get_param(PARAM_CHIP_NAME,ATTR_AVAIL) ' ) ;
     if Available = 0 then CameraInfo.Add( 'PARAM_CHIP_NAME not available' )
     else begin
        pl_get_param( Session.Handle, PARAM_CHIP_NAME, ATTR_CURRENT, @TempName ) ;
        CameraInfo.Add( 'CCD= ' + PVCAM_CharArrayToString(TempName)) ;
        end ;

     //PCI card firmware version number
     Available := 0 ;
     pl_get_param( Session.Handle, PARAM_PCI_FW_VERSION, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        pl_get_param( Session.Handle, PARAM_PCI_FW_VERSION, ATTR_CURRENT, @Value ) ;
        CameraInfo.Add( format('PCI card firmware V%.2f',[Value/100.0])) ;
        end ;

     //Camera firmware version number
     Available := 0 ;
     pl_get_param( Session.Handle, PARAM_CAM_FW_VERSION, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        pl_get_param( Session.Handle, PARAM_CAM_FW_VERSION, ATTR_CURRENT, @Value ) ;
        CameraInfo.Add( format('Camera Firmware V%.2f',[Value/100.0])) ;
        end ;

     //Camera temperature
     pl_get_param( Session.Handle, PARAM_TEMP, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        pl_get_param( Session.Handle, PARAM_TEMP, ATTR_CURRENT, @Temperature ) ;
        CameraInfo.Add( format('Camera Temperature %.1f C',[Temperature*0.01])) ;
        end ;

     // Get frame size
        pl_get_param( Session.Handle, PARAM_SER_SIZE, ATTR_CURRENT, @Value ) ;
        PVCAM_DisplayErrorMessage( 'pl_get_param(PARAM_SER_SIZE) ' ) ;
        FrameWidth := Value ;
        FrameWidthMax := Value ;
        pl_get_param( Session.Handle, PARAM_PAR_SIZE, ATTR_CURRENT, @Value ) ;
        PVCAM_DisplayErrorMessage( 'pl_get_param(PARAM_PAR_SIZE) ' ) ;
        FrameHeight := Value ;
        FrameHeightMax := Value ;

     // Calculate bit depth and grey scale range
     Value := 1 ;
     pl_get_param( Session.Handle, PARAM_BIT_DEPTH, ATTR_CURRENT, @Value ) ;
     PixelDepth := Value ;
     GreyLevelMax := 1 ;
     for i := 1 to Value do GreyLevelMax := GreyLevelMax*2 ;
         GreyLevelMax := GreyLevelMax - 1 ;

     // Get pixel size (um)
     pl_get_param( Session.Handle, PARAM_PIX_PAR_DIST, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        pl_get_param( Session.Handle, PARAM_PIX_PAR_DIST, ATTR_CURRENT, @Value ) ;
        PixelWidth := Value*0.001 ;
        end
     else PixelWidth := 10.0 ;

     CameraInfo.Add( format('Frame: width=%d, height=%d, bit depth=%d, pixel = %.3g um',
                     [FrameWidthMax,FrameHeightMax,PixelDepth,PixelWidth])) ;

     // TEMP. FIX!! PVCAM returning incorrect value
     //GreyLevelMax := 4095 ;

     // Check that continuous capture using circular buffer is supported
     pl_get_param( Session.Handle, PARAM_CIRC_BUFFER, ATTR_AVAIL, @CircularBufferSupported ) ;
     if CircularBufferSupported <> 0 then begin
          pl_get_param( Session.Handle, PARAM_CIRC_BUFFER, ATTR_CURRENT, @CircularBufferSupported ) ;
          if CircularBufferSupported = 0 then
             CameraInfo.Add( 'Continuous capture not supported!' ) ;
          end ;

     pl_get_param( Session.Handle, PARAM_FRAME_CAPABLE, ATTR_AVAIL, @FrameTransferCapable ) ;
     if FrameTransferCapable <> 0 then begin
        pl_get_param( Session.Handle, PARAM_FRAME_CAPABLE, ATTR_CURRENT, @FrameTransferCapable ) ;
        if FrameTransferCapable = 0 then CameraInfo.Add( 'Frame transfer mode not available' ) ;
        end ;

     // Set camera Logic Output to monitor indicate CCD exposure period (LO=HIGH)
     // (Used to gate intensifier during readout/wavelength change)
     pl_get_param( Session.Handle, PARAM_LOGIC_OUTPUT, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        LongValue := Cardinal(OUTPUT_SHUTTER) ;
        if pl_set_param( Session.Handle, PARAM_LOGIC_OUTPUT, @LongValue ) = 0 then
           CameraInfo.Add( 'PARAM_LOGIC_OUTPUT=OUTPUT_SHUTTER not set!' ) ;
        end ;

     // Set CCD clear mode to clear pre-sequence to ensure that frame transfer mode will work
     pl_get_param( Session.Handle, PARAM_CLEAR_MODE, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        LongValue := Cardinal(CLEAR_PRE_sequence) ;
        pl_set_param( Session.Handle, PARAM_CLEAR_MODE, @LongValue ) ;
        end ;

     // Set camera into frame transfer mode
     pl_ccd_set_pmode( Session.Handle, Word(PMODE_FT)) ;
     pl_ccd_get_pmode( Session.Handle, Value ) ;
     PVCAM_DisplayErrorMessage( 'pl_ccd_get_pmode' ) ;
     case TPMode(Value) of
          PMODE_NORMAL : CameraInfo.Add( 'CCD readout in normal mode!' ) ;
          PMODE_FT : CameraInfo.Add( 'CCD readout in Frame Transfer mode!' ) ;
          PMODE_MPP : CameraInfo.Add( 'CCD readout in MPP mode!' ) ;
          PMODE_FT_MPP : CameraInfo.Add( 'CCD readout in Frame Transfer MPP mode!' ) ;
          PMODE_ALT_NORMAL : CameraInfo.Add( 'CCD readout in alternate normal mode!' ) ;
          PMODE_ALT_FT : CameraInfo.Add( 'CCD readout in alternate Frame Transfer mode!' ) ;
          PMODE_ALT_MPP : CameraInfo.Add( 'CCD readout in alternate MPP mode!' ) ;
          PMODE_ALT_FT_MPP : CameraInfo.Add( 'CCD readout in alternate Frame Transfer MPP mode!' ) ;
          end ;


    // Set readout speed of camera
    if pl_set_param( Session.Handle, PARAM_SPDTAB_INDEX, @ReadoutSpeedIndex ) = 0 then begin
       ShowMessage('ERROR: Unable to select readout speed. Camera may be switched off!') ;
       Exit ;
       end ;

     // Check if multipler gain available
     pl_get_param( Session.Handle, PARAM_GAIN_MULT_ENABLE, ATTR_AVAIL, @MultGainEnabled ) ;
     if MultGainEnabled <> 0 then begin
        pl_get_param( Session.Handle, PARAM_GAIN_MULT_ENABLE, ATTR_CURRENT, @MultGainEnabled ) ;
        end ;
     if MultGainEnabled <> 0 then CameraInfo.Add('EMCCD Multiplier available') ;

     // Discover frame readout time
     PVCAM_CheckFrameInterval( Session,
                               0, FrameWidthMax-1,
                               0, FrameHeightMax-1,
                               1,
                               ReadoutSpeedIndex,
                               FrameInterval,
                               ReadoutTime ) ;
     CameraInfo.Add( format( ' Readout time %.3g ms', [ReadoutTime*1000.0] )) ;

     Result := True ;

     end ;


procedure PVCAM_LoadLibrary  ;
{ -------------------------------------
  Load PVCAM32.DLL library into memory
  -------------------------------------}
var
    LibFileName : string ;
    VC32LibraryHnd : THandle ;
    ProgDir : String ;
begin

     // Get program file directory
     ProgDir := ExtractFilePath(ParamStr(0)) ;

     { Load PVCAM32 interface DLL library }
     LibFileName := {ProgDir +} 'PVCAM32.DLL' ;
     LibraryHnd := LoadLibrary( PChar(LibFileName));

     { Get addresses of procedures in library }
     if LibraryHnd > 0 then begin
        @pl_cam_check :=PVCAM_GetDLLAddress(LibraryHnd,'pl_cam_check') ;
        @pl_cam_close :=PVCAM_GetDLLAddress(LibraryHnd,'pl_cam_close') ;
        @pl_cam_get_diags :=PVCAM_GetDLLAddress(LibraryHnd,'pl_cam_get_diags') ;
        @pl_cam_get_name :=PVCAM_GetDLLAddress(LibraryHnd,'pl_cam_get_name') ;
        @pl_cam_get_total :=PVCAM_GetDLLAddress(LibraryHnd,'pl_cam_get_total') ;
        @pl_cam_open :=PVCAM_GetDLLAddress(LibraryHnd,'pl_cam_open') ;
        @pl_dd_get_info :=PVCAM_GetDLLAddress(LibraryHnd,'pl_dd_get_info') ;
        @pl_ddi_get_ver :=PVCAM_GetDLLAddress(LibraryHnd,'pl_ddi_get_ver') ;
        @pl_exp_abort :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_abort') ;
        @pl_exp_check_cont_status :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_check_cont_status') ;
        @pl_exp_check_status :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_check_status') ;
        @pl_exp_check_progress :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_check_progress') ;
        @pl_error_code :=PVCAM_GetDLLAddress(LibraryHnd,'pl_error_code') ;
        @pl_error_message :=PVCAM_GetDLLAddress(LibraryHnd,'pl_error_message') ;
        @pl_pvcam_get_ver :=PVCAM_GetDLLAddress(LibraryHnd,'pl_pvcam_get_ver');
        @pl_pvcam_init :=PVCAM_GetDLLAddress(LibraryHnd,'pl_pvcam_init');
        @pl_pvcam_uninit :=PVCAM_GetDLLAddress(LibraryHnd,'pl_pvcam_uninit');
        @pl_get_param :=PVCAM_GetDLLAddress(LibraryHnd,'pl_get_param');
        @pl_set_param  :=PVCAM_GetDLLAddress(LibraryHnd,'pl_set_param');
        @pl_get_enum_param :=PVCAM_GetDLLAddress(LibraryHnd,'pl_get_enum_param');
        //@pl_enum_str_length :=PVCAM_GetDLLAddress(LibraryHnd,'pl_enum_str_length');
        @pl_exp_init_seq :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_init_seq');
        @pl_exp_finish_seq :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_finish_seq');
        @pl_exp_get_driver_buffer :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_finish_seq');
        @pl_exp_get_latest_frame :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_get_latest_frame');
        @pl_exp_get_oldest_frame :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_get_oldest_frame');
        @pl_exp_set_cont_mode :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_set_cont_mode');
        @pl_exp_setup_seq :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_setup_seq');
        @pl_exp_start_cont :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_start_cont');
        @pl_exp_start_seq :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_start_seq');
        @pl_exp_stop_cont :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_stop_cont');
        @pl_exp_uninit_seq  :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_uninit_seq');
        @pl_exp_get_time_seq :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_get_time_seq');
        @pl_exp_set_time_seq :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_set_time_seq');
        @pl_exp_unlock_oldest_frame :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_unlock_oldest_frame');
        @pl_io_script_control :=PVCAM_GetDLLAddress(LibraryHnd,'pl_io_script_control');
        @pl_io_clear_script_control :=PVCAM_GetDLLAddress(LibraryHnd,'pl_io_clear_script_control');
        @pl_exp_setup_cont :=PVCAM_GetDLLAddress(LibraryHnd,'pl_exp_setup_cont');
        @pl_ccd_set_pmode :=PVCAM_GetDLLAddress(LibraryHnd,'pl_ccd_set_pmode');
        @pl_ccd_get_pmode :=PVCAM_GetDLLAddress(LibraryHnd,'pl_ccd_get_pmode');

        LibraryLoaded := True ;
        end
     else begin
          ShowMessage( 'PVCAM: ' + LibFileName + ' not found!' ) ;
          LibraryLoaded := False ;
          end ;

     end ;


function PVCAM_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within PVCAM32.DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       ShowMessage('PVCAM32.DLL: ' + ProcName + ' not found') ;
    end ;



procedure PVCAM_GetCameraReadoutSpeedList(
          var Session : TPVCAMSession ;    // Camera session record
          CameraReadoutSpeedList : TStringList ) ;
// ------------------------------------
// Get list of available readout speeds
// ------------------------------------
var
    i,Value,LastIndex : Word ;
    OK : Boolean ;
begin

    if not LibraryLoaded then Exit ;

    // No. of entries in speed table
    if pl_get_param( Session.Handle, PARAM_SPDTAB_INDEX, ATTR_MAX, @LastIndex ) = 0 then begin
       PVCAM_DisplayErrorMessage( 'pl_get_param(PARAM_SPDTAB_INDEX) ' ) ;
       Exit ;
       end ;

    for i := 0 to LastIndex do begin

        // Select speed table option
        if pl_set_param( Session.Handle, PARAM_SPDTAB_INDEX, @i ) = 0 then begin
           PVCAM_DisplayErrorMessage( 'pl_set_param(PARAM_SPDTAB_INDEX) ' ) ;
           Exit ;
           end ;

        // Get pixel readout time (ns)
        if pl_get_param( Session.Handle, PARAM_PIX_TIME, ATTR_CURRENT, @Value ) = 0 then begin
           PVCAM_DisplayErrorMessage( 'pl_get_param(PARAM_PIX_TIME) ' ) ;
           Exit ;
           end ;

        if (Value > 0) then CameraReadoutSpeedList.Add( format( ' %3g MHz',[1000.0/Value]))
                       else CameraReadoutSpeedList.Add( 'Error' ) ;

        end ;

    end ;


procedure PVCAM_GetCameraGainList(
          var Session : TPVCAMSession ;    // Camera session record
          CameraGainList : TStringList ) ;
// ------------------------------------
// Get list of available camera gains
// ------------------------------------
var
    i,Value,LastIndex : Word ;
    MultGainEnabled : Boolean ;
begin

     if not LibraryLoaded then Exit ;

     // Check if multipler gain available
     pl_get_param( Session.Handle, PARAM_GAIN_MULT_ENABLE, ATTR_AVAIL, @MultGainEnabled ) ;
     if MultGainEnabled then begin
        pl_get_param( Session.Handle, PARAM_GAIN_MULT_ENABLE, ATTR_CURRENT, @MultGainEnabled ) ;
        end ;

     // Get upper limit of gain range

     LastIndex := 0 ;
     if MultGainEnabled then begin
        pl_get_param( Session.Handle, PARAM_GAIN_MULT_FACTOR, ATTR_MAX, @LastIndex ) ;
        end
     else begin
        pl_get_param( Session.Handle, PARAM_GAIN_INDEX, ATTR_MAX, @LastIndex ) ;
        end ;

     // Create list of gains
     // (If more than 100 gain values, use 1-100%)

     CameraGainList.Clear ;
     if LastIndex > 99 then begin
        for i := 1 to 100 do CameraGainList.Add( format( ' %d%%',[i])) ;
        end
     else if LastIndex > 0 then begin
        for i := 1 to LastIndex do CameraGainList.Add( format( ' X%d',[i])) ;
        end
     else CameraGainList.Add(' X1 ') ;

    end ;


procedure PVCAM_CloseCamera(
          var Session : TPVCAMSession    // Camera session record ;
          ) ;
// ----------------------------
// Close down camera sub-system
// ----------------------------
begin

    if not LibraryLoaded then Exit ;

    // Close camera
    if Session.CameraOpen then pl_cam_close( Session.Handle ) ;
    Session.CameraOpen := False ;

    // Un-initialise PVCAM library
    pl_pvcam_uninit ;
    //PVCAM_DisplayErrorMessage( 'pl_pvcam_uninit ' ) ;

    end ;



procedure PVCAM_CheckROIBoundaries(
         var FrameLeft : Integer ;            // Left pixel in CCD readout area
         var FrameRight : Integer ;           // Right pixel in CCD eadout area
         var FrameTop : Integer ;             // Top of CCD readout area
         var FrameBottom : Integer ;          // Bottom of CCD readout area
         var  BinFactor : Integer ;           // Pixel binning factor (In)
         FrameWidthMax : Integer ;            // Max. width
         FrameHeightMax : Integer ;           // Max height
         var FrameWidth : Integer ;           // Image width after binning/regioning
         var FrameHeight : Integer            // Image height
         ) ;
// -------------------------------
// Ensure ROI boundaries are valid
// -------------------------------
begin

    FrameLeft := Min(Max(FrameLeft,0),FrameWidthMax-1) ;
    FrameTop := Min(Max(FrameTop,0),FrameHeightMax-1) ;
    FrameRight := Min(Max(FrameRight,0),FrameWidthMax-1) ;
    FrameBottom := Min(Max(FrameBottom,0),FrameHeightMax-1) ;
    if FrameLeft >= FrameRight then FrameRight := FrameLeft + BinFactor - 1 ;
    if FrameTop >= FrameBottom then FrameBottom := FrameBottom + BinFactor - 1 ;
    if FrameRight >= FrameWidthMax then FrameRight := FrameWidthMax - BinFactor ;
    if FrameBottom >= FrameHeightMax then FrameBottom := FrameHeightMax - BinFactor ;

    FrameLeft := (FrameLeft div BinFactor)*BinFactor ;
    FrameTop := (FrameTop div BinFactor)*BinFactor ;
    FrameRight := (FrameRight div BinFactor)*BinFactor + (BinFactor-1) ;
    FrameBottom := (FrameBottom div BinFactor)*BinFactor + (BinFactor-1) ;

    // Ensure frame width is a multiple of 2
    // (Odd frame widths cause image to shift sideways)
    FrameWidth := ((FrameRight - FrameLeft) div BinFactor) + 1 ;
    if ((FrameWidth mod 2) <> 0) and (FrameWidth > 1) then begin
       Dec(FrameWidth) ;
       FrameRight := FrameLeft + FrameWidth*BinFactor - 1 ;
       end ;

    // Ensure right/bottom edge does not exceed frame

    if FrameRight >= FrameWidthMax then FrameRight := FrameRight - BinFactor ;
    FrameWidth := ((FrameRight - FrameLeft) div BinFactor) + 1 ;

    if FrameBottom >= FrameHeightMax then FrameBottom := FrameBottom - BinFactor ;
    FrameHeight := ((FrameBottom - FrameTop) div BinFactor) + 1 ;

    end ;


function PVCAM_CheckFrameInterval(
          var Session : TPVCAMSession ;    // Camera session record
          FrameLeft : Integer ;   // Left edge of capture region (In)
          FrameRight : Integer ;  // Right edge of capture region( In)
          FrameTop : Integer ;    // Top edge of capture region( In)
          FrameBottom : Integer ; // Bottom edge of capture region (In)
          BinFactor : Integer ;   // Pixel binning factor (In)
          ReadoutSpeedIndex : Integer ; // Readout speed index # (In)
   //       TriggerMode : Integer ;       // Frame capture trigger mode (In)
          Var FrameInterval : Double ;
          Var ReadoutTime : Double) : Boolean ;
// ---------------------------------
// Ensure that inter-frame is valid
// ---------------------------------
var
     Value : Word ;
     OverHeadFactor : Single ;
     Available : Word ;
     DBValue : Double ;
     PixelReadoutTime : Word ;
begin

     if not LibraryLoaded then Exit ;

     // Set frame capture region
     FrameRegion[0].s1 := FrameLeft ;
     FrameRegion[0].s2 := FrameRight ;
     FrameRegion[0].sBin := BinFactor ;
     FrameRegion[0].p1 := FrameTop ;
     FrameRegion[0].p2 := FrameBottom ;
     FrameRegion[0].pBin := BinFactor ;

     // Set readout speed of camera
     if pl_set_param( Session.Handle, PARAM_SPDTAB_INDEX, @ReadoutSpeedIndex ) = 0 then Exit ;

     // Discover frame readout time

     // Initialise sequence capture
     pl_exp_init_seq ;
     PVCAM_DisplayErrorMessage( 'pl_exp_init_seq ') ;

     pl_exp_setup_cont( Session.Handle,
                        1,
                        @FrameRegion,
                        TIMED_MODE,
                        1000,
                        @NumBytesPerFrame,
                        CIRC_OVERWRITE ) ;
     PVCAM_DisplayErrorMessage( 'pl_exp_setup_cont ') ;

     // Get readout time from camera
     ReadoutTime := 0.0 ;
     pl_get_param( Session.Handle, PARAM_READOUT_TIME, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
           pl_get_param( Session.Handle, PARAM_READOUT_TIME, ATTR_CURRENT, @ReadoutTime ) ;
           ReadoutTime := ReadoutTime*0.001 {+ 0.001} ;
           end ;

     // Estimate readout time from pixel read time
     if ReadoutTime <= 0.0 then begin
        pl_get_param( Session.Handle, PARAM_PIX_TIME, ATTR_AVAIL, @Available ) ;
        if Available <> 0 then begin
              pl_get_param( Session.Handle, PARAM_PIX_TIME, ATTR_CURRENT, @PixelReadoutTime ) ;
              ReadoutTime := (PixelReadoutTime*1.1)*
                             (({FrameRight - FrameLeft+1}FrameWidthMax) {div BinFactor})*
                             ((FrameBottom - FrameTop+1) div BinFactor)*1E-9 ;
              end ;
        ReadoutTime := ReadoutTime {+ 2E-3} ;
        end ;

     // Shut down sequence acquisition
     pl_exp_uninit_seq ;
     PVCAM_DisplayErrorMessage( 'pl_exp_uninit_seq ') ;

     // Prevent frame interval from being less than readout time

     if FrameInterval < (ReadoutTime {+ 0.002}) then FrameInterval := ReadoutTime {+ 0.002} ;

     ExposureResolution := 0.001 ; // 1 ms exposure resolution
     FrameInterval := Round(FrameInterval/ExposureResolution)*ExposureResolution ;

     Result := True ;

     end ;


function PVCAM_StartCapture(
         var Session : TPVCAMSession ;    // Camera session record
         FrameLeft : Integer ;              // Left edge of capture region (In)
         FrameRight : Integer ;             // Right edge of capture region( In)
         FrameTop : Integer ;               // Top edge of capture region( In)
         FrameBottom : Integer ;            // Bottom edge of capture region (In)
         BinFactor : Integer ;              // Pixel binning factor (In)
         FrameBuffer : Pointer ;            // Frame storage buffer (In)
         NumBytesInFrameBuffer : Cardinal ; // Size of storage buffer (In)
         var FrameInterval : Double ;       // Duration of interval used (In/Ret)
         AdditionalReadoutTime : Double ;  // Additional readout time
         AmpGain : Integer ;               // Amplifier gain  (In)
         var FrameWidth : Integer ;         // Width of image frame (Out)
         var FrameHeight : Integer ;        // Height of image frame (Out)
         TriggerMode : Integer ;            // Frame capture trigger mode
         ReadoutSpeedIndex : Integer ;       // Camera readout speed option
         ClearCCDPreExposure : Boolean ;      // TRUE = Clear CCD before exposure
         PostExposureReadout : Boolean     // TRUE = readout after exposure
                                            // Ext. trig mode only
         ) : Boolean ;                      // True = captured started
//
// Start continuous capture into buffer
// --------------------------------

var
    ii,NumFramesIRQ : Integer ;
    i,NumFrames : Cardinal ;
    VCEnable : LongBool ;
    Available : Word ;
    LongValue : DWord ;
    ReadoutTime : Double ;
    Gain,MaxGain : Word ;
    ScaleFactor : Single ;
    MultGainEnabled : Word ;
    Temperature : SmallInt ;
    ExposureTime : Double ;
    Err : Word ;
begin

    Result := False ;
    if not LibraryLoaded then Exit ;

    FrameBufferStart := FrameBuffer ;

    FrameRegion[0].s1 := FrameLeft ;
    FrameRegion[0].s2 := FrameRight ;
    FrameRegion[0].sBin := BinFactor ;
    FrameRegion[0].p1 := FrameTop ;
    FrameRegion[0].p2 := FrameBottom ;
    FrameRegion[0].pBin := BinFactor ;

    FrameWidth := ((FrameRight - FrameLeft +1) div BinFactor) ;
    FrameHeight := ((FrameBottom - FrameTop +1)  div BinFactor) ;

    NumBytesPerFrame := (2*FrameWidth*FrameHeight) ;
    NumFrames := NumBytesInFrameBuffer div NumBytesPerFrame ;

//outputdebugString(PChar(format('LRTB %d %d %d %d',[FrameLeft,FrameRight,FrameTop,FrameBottom]))) ;
//outputdebugString(PChar(format('WH,NB %d %d %d',[FRameWidth,FrameHeight,NumBytesPerFrame]))) ;

    // Set readout speed of camera
    if pl_set_param( Session.Handle, PARAM_SPDTAB_INDEX, @ReadoutSpeedIndex ) = 0 then begin
       PVCAM_DisplayErrorMessage( 'pl_set_param(PARAM_SPDTAB_INDEX) ' ) ;
       Exit ;
       end ;

     //Camera temperature
     pl_get_param( Session.Handle, PARAM_TEMP, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        pl_get_param( Session.Handle, PARAM_TEMP, ATTR_CURRENT, @Temperature ) ;
        Session.Temperature := Temperature*0.01 ;
        end ;

    // Set up for continous acquisition

    // Ensure that the inter-frame interval is valid
    PVCAM_CheckFrameInterval( Session,
                              FrameLeft, FrameRight,
                              FrameTop, FrameBottom,
                              BinFactor,
                              ReadoutSpeedIndex,
                              FrameInterval,
                              ReadoutTime ) ;

     // Check if multipler gain is available
     pl_get_param( Session.Handle, PARAM_GAIN_MULT_ENABLE, ATTR_AVAIL, @MultGainEnabled ) ;
     if MultGainEnabled <> 0 then begin
        pl_get_param( Session.Handle, PARAM_GAIN_MULT_ENABLE, ATTR_CURRENT, @MultGainEnabled ) ;
        end ;

    // Set camera gain
    if MultGainEnabled <> 0 then begin
       // Use EMCCD multiplier gain if available
       pl_get_param( Session.Handle, PARAM_GAIN_MULT_FACTOR, ATTR_MAX, @MaxGain ) ;
       if MaxGain > 99 then ScaleFactor := MaxGain/100.0
                       else ScaleFactor := 1.0 ;
       Gain := Min(Max(Round(AmpGain*ScaleFactor),1),MaxGain) ;
       pl_set_param( Session.Handle, PARAM_GAIN_MULT_FACTOR, @Gain ) ;
       end
     else begin
       // Otherwise use standard gain
       pl_get_param( Session.Handle, PARAM_GAIN_INDEX, ATTR_MAX, @MaxGain ) ;
       if MaxGain > 99 then ScaleFactor := MaxGain/100.0
                       else ScaleFactor := 1.0 ;
       Gain := Min(Max(Round(AmpGain*ScaleFactor),1),MaxGain) ;
       pl_set_param( Session.Handle, PARAM_GAIN_INDEX, @Gain ) ;
       end ;

     // Set CCD clear mode to clear pre-sequence or clear pre-exposure JD 7.09.10
     // if camera is in ext. trigger mode
     pl_get_param( Session.Handle, PARAM_CLEAR_MODE, ATTR_AVAIL, @Available ) ;
     if Available <> 0 then begin
        if ClearCCDPreExposure and ( TriggerMode <> CamFreeRun) then LongValue := Cardinal(CLEAR_PRE_EXPosure)
                                                                else LongValue := Cardinal(CLEAR_PRE_Sequence) ;
        pl_set_param( Session.Handle, PARAM_CLEAR_MODE, @LongValue ) ;
        end ;

    // Set CCD to frame transfer mode
    // (15.12.10 Set to PMODE_FT again to obtain max. speed in free run)
    pl_ccd_set_pmode( Session.Handle, Word(PMODE_FT)) ;

    // Initialise sequence capture
    // (note pl_exp_init_seq must come after PVCAM_CheckFrameInterval)

    pl_exp_init_seq ;
    PVCAM_DisplayErrorMessage( 'pl_exp_init_seq ' ) ;

    // Set up for free run or externally triggered capture modes

       // Normal CCD readout mode
       // -----------------------
    if TriggerMode = CamFreeRun then begin
       // Free run mode
       Err := pl_exp_setup_cont( Session.Handle,
                                   1,
                                   @FrameRegion,
                                   TIMED_MODE,
                                   Round(FrameInterval/ExposureResolution),
                                   @NumBytesPerFrame,
                                   CIRC_OVERWRITE ) ;
       PVCAM_DisplayErrorMessage( 'pl_exp_setup_cont (TIMED_MODE)' ) ;
//       outputdebugString(PChar(format('WH,NB %d %d %d',[FRameWidth,FrameHeight,NumBytesPerFrame]))) ;
       end
    else begin
       // Triggered mode
       // Note addition readout time can be added by user (via WinFluor setup dialog)
       ExposureTime := FrameInterval
                       - 0.001            { Allow for CCD readout time}
                       - AdditionalReadoutTime ; { Additional user defined readout time}
       // If post-exposure readout shorten exposure to account for readout
       if PostExposureReadout then ExposureTime := ExposureTime - ReadoutTime ;
       // No shorter than 1ms exposure
       ExposureTime := Max(ExposureTime,0.001) ;

       Err := pl_exp_setup_cont( Session.Handle,
                                   1,
                                   @FrameRegion,
                                   STROBED_MODE{BULB_MODE},
                                   Round(ExposureTime/ExposureResolution),
                                   @NumBytesPerFrame,
                                   CIRC_OVERWRITE ) ;
       PVCAM_DisplayErrorMessage( 'pl_exp_setup_cont (STROBED_MODE)' ) ;
       end ;

    // Begin acquisition
    if Err <> 0 then begin
       pl_exp_start_cont( Session.Handle, FrameBuffer, NumBytesInFrameBuffer ) ;
       PVCAM_DisplayErrorMessage( 'pl_exp_start_cont ' ) ;
       end ;

    // Initialise buffer
    for i := 1 to NumFrames do begin
        ii := (NumBytesPerFrame div 2)*i -1 ;
        PWordArray(FrameBuffer)^[ii] := 32767 ;
        PWordArray(FrameBuffer)^[ii-1] := 0 ;
        end ;

    If Err <> 0 then Result := True ;

    end ;


function PVCAM_StopCapture(
         var Session : TPVCAMSession     // Camera session record
         ) : Boolean ;
//
// Stop continuous capture into buffer
// -----------------------------------
var
     VCEnable : LongBool ;
begin

    if not LibraryLoaded then Exit ;

    // Stop continuous capture
    pl_exp_stop_cont( Session.Handle, 0 ) ;
    PVCAM_DisplayErrorMessage( 'pl_exp_stop_cont' ) ;

    // Uninitialise frame sequence system
    pl_exp_uninit_seq ;
    PVCAM_DisplayErrorMessage( 'pl_exp_uninit_seq' ) ;

    end ;


function PVCAM_GetLatestFrameNumber(
         var Session : TPVCAMSession    // Camera session record
         ) : Integer ;
var
    FrameNum : Integer ;
    LatestFramePointer : Pointer ;
    Err : Word ;
begin

    if not LibraryLoaded then Exit ;

    Err := pl_exp_get_latest_frame( Session.Handle, LatestFramePointer ) ;
    PVCAM_DisplayErrorMessage( 'pl_exp_get_latest_frame ' ) ;

    if Err <> 0 then begin
       FrameNum := (Integer(LatestFramePointer) - Integer(FrameBufferStart)) div NumBytesPerFrame ;
       Result := Integer(LatestFramePointer){FrameNum} ;
       end
    else begin
       MessageDlg( 'PVCAM: Error getting frame #',mtWarning, [mbOK], 0 ) ;
       Result := 0 ;
       end ;
    end ;


procedure PVCAM_DisplayErrorMessage(
          Source : string ) ;
var
     ErrCode : SmallInt ;
     ErrMessage : Array[0..255] of Char ;
     s : String ;
begin

   if not LibraryLoaded then Exit ;

   ErrCode := pl_error_code ;
   if ErrCode <> 0 then begin
      pl_error_message( ErrCode, @ErrMessage ) ;
      s := PVCAM_CharArrayToString(ErrMessage) ;
      ShowMessage( Source + ' ' + s ) ;
      end ;

   end ;


procedure PVCAM_VC_DisplayErrorMessage(
          Source : string ) ;
var
     ErrCode : SmallInt ;
     ErrMessage : Array[0..255] of Char ;
     s : String ;
begin

   if not LibraryLoaded then Exit ;

   ErrCode := pl_vc_error_code ;
   if ErrCode <> 0 then begin
      pl_vc_error_message( ErrCode, @ErrMessage ) ;
      s := PVCAM_CharArrayToString(ErrMessage) ;
      ShowMessage( Source + ' ' + s ) ;
      end ;

   end ;


function PVCAM_CharArrayToString( CBuf : Array of Char ) : String ;
var
    i : Integer ;
    s : String ;
begin
    i := 0 ;
    s := '' ;
    while (CBuf[i] <> #0) and (i <= High(CBuf)) do begin
        s := s + CBuf[i] ;
        Inc(i) ;
        end ;
    Result := s ;
    end ;


Initialization
   LibraryLoaded := False ;

end.
