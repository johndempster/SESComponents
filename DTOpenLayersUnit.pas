unit DTOpenLayersUnit;
// --------------------------------------------------------------
// Data Translation DT-Open Layers image capture library support
// --------------------------------------------------------------

interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, math, strutils ;

const

    DTOLMaxBuffers = 256 ;

{=======================================================================++
||	Copyright (C) 1994.         Data Translation, Inc., 100 Locke    ||
||	Drive, Marlboro, Massachusetts 01752-1192.			 ||
||									 ||
||	All rights reserved.  This software is furnished to purchaser	 ||
||	under a license for use on a single computer system and can be	 ||
||	copied (with the inclusion of DTI's copyright notice) only for	 ||
||	use in such system, except as may be otherwise provided in	 ||
||	writing by Data Translation, Inc., 100 Locke Drive, Marlboro,	 ||
||	Massachusetts 01752-1192.					 ||
||									 ||
||	The information in this document is subject to change without	 ||
||	notice and should not be construed as a commitment by Data	 ||
||	Translation, Inc.  Data Translation, Inc. assumes no		 ||
||	responsibility for any errors that may appear in this document.	 ||
||									 ||
||	Data Translation cannot assume any responsibility for the use	 ||
||	of any portion of this software on any equipment not supplied	 ||
||	by Data Translation, Inc.					 ||
||									 ||
++=======================================================================*/
}


// DT-Open Layers Severity Levels */
	 OLC_IMG_SEV_NORMAL = 0;
	 OLC_IMG_SEV_INFO = 1;
	 OLC_IMG_SEV_WARNING = 2;
	 OLC_IMG_SEV_ERROR = 4;

// Imaging Device Capability ("DC") Keys */
	 OLC_IMG_DC_UNKNOWN = 0;
	 OLC_IMG_DC_OL_SIGNATURE = 1;
	 OLC_IMG_DC_DEVICE_ID = 2;
	 OLC_IMG_DC_DEVICE_NAME = 3;
	 OLC_IMG_DC_OL_DEVICE_TYPE = 4;
	 OLC_IMG_DC_SECTIONS = 5;
	 OLC_IMG_DC_LINEAR_MEM_SIZE = 6;
	 OLC_IMG_DC_DEVICE_MEM_SIZE = 7;

// DT-Open Layers imaging device signature; returned by OLC_IMG_DC_OL_SIGNATURE dev cap query */
   OLC_IMG_DEV_SIGNATURE = 	$44544F4C ;

// Imaging device types; returned by OLC_IMG_DC_OL_DEVICE_TYPE dev cap query */
	 OLC_IMG_DEV_BOGUS = 0;
	 OLC_IMG_DEV_MONO_FRAME_GRABBER = 1;
	 OLC_IMG_DEV_COLOR_FRAME_GRABBER = 2;


//=======================================================================*/
//==================  Monochrome Frame Grabbers  =======================*/
//=======================================================================*/


// Device Section bit flags for use with value returned by OLC_IMG_DC_SECTIONS dev */
//   cap query.  These flags should be used when the device type returned by the   */
//   OLC_IMG_DC_OL_DEVICE_TYPE dev cap query equals OLC_IMG_DEV_MONO_FRAME_GRABBER */

   OLC_FG_SECTION_INPUT	= $00000001;
   OLC_FG_SECTION_CAMCTL	= $00000002;
   OLC_FG_SECTION_MEMORY	= $00000004;
   OLC_FG_SECTION_LINEAR	= $00000008;
   OLC_FG_SECTION_PASSTHRU = $00000010;
   OLC_FG_SECTION_DDI		= $00000020;



// Mono Frame Grabber Input Capability ("IC") Keys */
	 OLC_FG_IC_UNKNOWN						= $0000;
	 OLC_FG_IC_INPUT_SOURCE_COUNT			= $0001;
	 OLC_FG_IC_ILUT_COUNT					= $0008;
	 OLC_FG_IC_MAX_ILUT_INDEX				= $0009;
	 OLC_FG_IC_MAX_ILUT_VALUE				= $000A;
	 OLC_FG_IC_MAX_FRAME_SIZE				= $0010;
	 OLC_FG_IC_PIXEL_DEPTH					= $0018;
	 OLC_FG_IC_FRAME_TYPE_LIMITS			= $0020;
	 OLC_FG_IC_DOES_INPUT_FILTER			= $0100;
	 OLC_FG_IC_INPUT_FILTER_LIMITS			= $0101;
	 OLC_FG_IC_DOES_PROG_A2D				= $0110;
	 OLC_FG_IC_BLACK_LEVEL_LIMITS			= $0113;
	 OLC_FG_IC_WHITE_LEVEL_LIMITS			= $0115;
	 OLC_FG_IC_DOES_VIDEO_SELECT			= $0120;
	 OLC_FG_IC_VIDEO_TYPE_LIMITS			= $0121;
	 OLC_FG_IC_CSYNC_SOURCE_LIMITS			= $0122;
	 OLC_FG_IC_CSYNC_THRESH_LIST_LIMITS		= $0123;
	 OLC_FG_IC_CSYNC_THRESH_LIST			= $0124;
	 OLC_FG_IC_DOES_ACTIVE_VIDEO			= $0130;
	 OLC_FG_IC_CLAMP_START_LIMITS			= $0131;
	 OLC_FG_IC_CLAMP_END_LIMITS				= $0132;
	 OLC_FG_IC_ACTIVE_PIXEL_LIMITS			= $0133;
	 OLC_FG_IC_ACTIVE_WIDTH_LIMITS			= $0134;
	 OLC_FG_IC_ACTIVE_LINE_LIMITS			= $0135;
	 OLC_FG_IC_ACTIVE_HEIGHT_LIMITS			= $0136;
	 OLC_FG_IC_BACK_PORCH_START_LIMITS		= $0137;
	 OLC_FG_IC_TOTAL_PIX_PER_LINE_LIMITS	= $0138;
	 OLC_FG_IC_TOTAL_LINES_PER_FLD_LIMITS	= $0139;
	 OLC_FG_IC_DOES_SYNC_SENTINEL			= $0140;
	 OLC_FG_IC_SYNC_SENTINEL_TYPE_LIMITS	= $0141;
	 OLC_FG_IC_DOES_FRAME_SELECT			= $0150;
	 OLC_FG_IC_FRAME_TOP_LIMITS				= $0151;
	 OLC_FG_IC_FRAME_LEFT_LIMITS			= $0152;
	 OLC_FG_IC_FRAME_WIDTH_LIMITS			= $0153;
	 OLC_FG_IC_FRAME_HEIGHT_LIMITS			= $0154;
	 OLC_FG_IC_FRAME_HINC_LIMITS			= $0155;
	 OLC_FG_IC_FRAME_VINC_LIMITS			= $0156;
	 OLC_FG_IC_DOES_PIXEL_CLOCK				= $0160;
	 OLC_FG_IC_CLOCK_FREQ_LIMITS			= $0161;
	 OLC_FG_IC_CLOCK_SOURCE_LIMITS			= $0162;
	 OLC_FG_IC_DOES_EVENT_COUNTING			= $0170;
	 OLC_FG_IC_EVENT_TYPE_LIMITS			= $0171;
	 OLC_FG_IC_EVENT_COUNT_LIMITS			= $0172;
	 OLC_FG_IC_DOES_TRIGGER					= $0180;
	 OLC_FG_IC_TRIGGER_TYPE_LIMITS			= $0181;
	 OLC_FG_IC_MULT_TRIGGER_TYPE_LIMITS		= $0182;
	 OLC_FG_IC_MULT_TRIGGER_MODE_LIMITS		= $0183;
	 OLC_FG_IC_SINGLE_FRAME_OPS				= $0200;
	 OLC_FG_IC_MULT_FRAME_OPS				= $0201;
     OLC_FG_IC_DOES_QUERY_INPUT_FILTER		= $0202;
	 OLC_FG_IC_DOES_QUERY_PROG_A2D			= $0203;
	 OLC_FG_IC_DOES_QUERY_VIDEO_SELECT		= $0204;
	 OLC_FG_IC_DOES_QUERY_SYNC_SENTINEL		= $0205;
	 OLC_FG_IC_DOES_QUERY_FRAME_SELECT		= $0206;
	 OLC_FG_IC_DOES_QUERY_PIXEL_CLOCK		= $0207;
	 OLC_FG_IC_DOES_QUERY_ACTIVE_VIDEO		= $0208;
	 OLC_FG_IC_DOES_DRAW_ACQUIRED_FRAME		= $0209;
	 OLC_FG_IC_STROBE_PULSE_WIDTH_LIST_LIMITS = $0210;
	 OLC_FG_IC_STROBE_PULSE_WIDTH_LIST		= $0211;
	 OLC_FG_IC_STROBE_TYPE_LIMITS			= $0212;
	 OLC_FG_IC_DOES_DRAW_ACQUIRED_FRAME_EX	= $0213;
	 OLC_FG_IC_DOES_STROBE					= $214;
	 OLC_FG_IC_DOES_COLOR			 		= $215;


// Single Frame Acquire Operations bit masks.  Used when testing return from */
//   OLC_FG_IC_SINGLE_FRAME_OPS IC query.                                    */

   OLC_FG_ACQ_FRAME		= $00000001;	// Supports single frame acquisitions */
   OLC_FG_ACQ_SUBFRAME		= $00000002;	// Supports single sub frame acquisitions */
   OLC_FG_ACQ_FRAME_TO_FIT	= $00000004;	// Supports single frame to fit acquisitions */



// multiple Frame Acquire Operations bit masks.  Used when testing return from */
//   OLC_FG_IC_MULT_FRAME_OPS IC query.                                    */

   OLC_FG_ACQ_MULTIPLE			= $00000001;	// Supports Multiple frame acquisitions to device */
   OLC_FG_ACQ_CONSECUTIVE		= $00000002;	// Supports Consecutive frame acquisitions to device */

// Input Controls */
	 OLC_FG_CTL_UNKNOWN		= $0000;
	 OLC_FG_CTL_ILUT		= $0001;
	 OLC_FG_CTL_FRAME_TYPE		= $0002;
	 OLC_FG_CTL_INPUT_FILTER	= $0100;
	 OLC_FG_CTL_BLACK_LEVEL		= $0111;
	 OLC_FG_CTL_WHITE_LEVEL		= $0113;
	 OLC_FG_CTL_VIDEO_TYPE		= $0120;
	 OLC_FG_CTL_VARSCAN_FLAGS	= $0121;
	 OLC_FG_CTL_CSYNC_SOURCE	= $0122;
	 OLC_FG_CTL_CSYNC_THRESH	= $0123;
	 OLC_FG_CTL_CLAMP_START		= $0130;
	 OLC_FG_CTL_CLAMP_END		= $0131;
	 OLC_FG_CTL_FIRST_ACTIVE_PIXEL	= $0132;
	 OLC_FG_CTL_ACTIVE_PIXEL_COUNT	= $0133;
	 OLC_FG_CTL_FIRST_ACTIVE_LINE	= $0134;
	 OLC_FG_CTL_ACTIVE_LINE_COUNT	= $0135;
	 OLC_FG_CTL_TOTAL_PIX_PER_LINE	= $0136;
	 OLC_FG_CTL_TOTAL_LINES_PER_FLD	= $0137;
	 OLC_FG_CTL_BACK_PORCH_START	= $0138;
	 OLC_FG_CTL_FRAME_TOP		= $0150;
	 OLC_FG_CTL_FRAME_LEFT		= $0151;
	 OLC_FG_CTL_FRAME_WIDTH		= $0152;
	 OLC_FG_CTL_FRAME_HEIGHT	= $0153;
	 OLC_FG_CTL_HOR_FRAME_INC	= $0154;
	 OLC_FG_CTL_VER_FRAME_INC	= $0155;
	 OLC_FG_CTL_CLOCK_FREQ		= $0160;
	 OLC_FG_CTL_CLOCK_SOURCE	= $0161;
	 OLC_FG_CTL_CLOCK_FLAGS		= $0162;
	 OLC_FG_CTL_SYNC_SENTINEL	= $0170;
	 OLC_FG_CTL_HSYNC_INSERT_POS	= $0171;
	 OLC_FG_CTL_HSYNC_SEARCH_POS	= $0172;
	 OLC_FG_CTL_VSYNC_INSERT_POS	= $0173;
	 OLC_FG_CTL_VSYNC_SEARCH_POS	= $0174;


// Input Filter Type bit masks */
   OLC_FG_FILT_AC_NONE			= $00000001;	// Can do AC coupled, with no filter */
   OLC_FG_FILT_AC_50			= $00000002;	// Can do AC coupled, with 50 Hz (4.43 MHz) filter */
   OLC_FG_FILT_AC_60			= $00000004;	// Can do AC coupled, with 60 Hz (3.58 MHz) filter */
   OLC_FG_FILT_DC_NONE			= $00000008;	// Can do DC coupled, with no filter */


// Input Video Type bit masks */
   OLC_FG_VID_COMPOSITE		= $00000001;	// Frame Grabber can acquire from composite video source */
   OLC_FG_VID_VARSCAN			= $00000002;	// Frame Grabber can acquire from variable scan video source */

// Variable Scan Input Flags bit masks */
   OLC_FG_VS_LINE_ON_LO_TO_HI		= $00000001;	// Set if lo-to-hi transitions on the var. scan. line */
								//    sync line are considered a "sync" indication.   */
   OLC_FG_VS_FIELD_ON_LO_TO_HI		= $00000002;	// Set if lo-to-hi transitions on the var. scan. field */
								//    sync line are considered a "sync" indication.    */

   OLC_FG_CSYNC_CURRENT_SRC		= $00000001;	// Driver can get CSYNC from current input source */
   OLC_FG_CSYNC_SPECIFIC_SRC		= $00000002;	// Driver can get CSYNC from any input source */
   OLC_FG_CSYNC_EXTERNAL_LINE		= $00000004;	// Driver can get CSYNC from external sync line */

// Input Clock Source bit masks */
   OLC_FG_CLOCK_INTERNAL			= $00000001;	// Frame Grabber can generate timing for video input */
   OLC_FG_CLOCK_EXTERNAL			= $00000002;	// Frame Grabber can utilize an external clock for input timing */


// Input Clock Flags bit masks */
   OLC_FG_CLOCK_EXT_ON_LO_TO_HI		= $00000001;	// Set if lo-to-hi transitions on the external clock line are */
								//     considered a "clock"                                   */


// Sync Sentinel type bit masks */
   OLC_FG_SYNC_SENTINEL_FIXED			= $00000001;	// Frame Grabber has Sync Sentinel but has fixed settings */
   OLC_FG_SYNC_SENTINEL_VARIABLE		= $00000002;	// Frame Grabber has Sync Sentinel and settings can be set by the user */

// Event bit masks */
   OLC_FG_EC_FRAME				= $00000001;	// Driver can count frame events */
   OLC_FG_EC_FIELD				= $00000002;	// Driver can count field events */
   OLC_FG_EC_EXT_HI_TO_LO			= $00000004;	// Driver can count high-to-low transitions on an external line */
   OLC_FG_EC_EXT_LO_TO_HI			= $00000008;	// Driver can count low-to-high transitions on an external line */


// Input trigger bit masks */
   OLC_FG_TRIG_EXTERNAL_LINE		= $00000001;	// Frame grabber supports externally triggered acquisitions */
   OLC_FG_TRIG_EVENT			= $00000002;	// Frame grabber supports event triggered acquisitions */
   OLC_FG_TRIG_ONE_EVENT_DELAY		= $00000004;	// Frame grabber supports acquisitions triggered on the event after the event counter fires */


// Multiple frame acquire trigger mode bit masks */
   OLC_FG_MODE_START			= $00000001;	// Frame grabber can start a series of multiple acquisitions with a single trigger */
   OLC_FG_MODE_EACH			= $00000002;	// Frame grabber can acquire a series of where each image in the series requires a trigger */


// Input "Frame" type bit masks */
   OLC_FG_FRM_IL_FRAME_EVEN		= $00000001	; // Interlaced frame - acquisition on next even field */
   OLC_FG_FRM_IL_FRAME_ODD			= $00000002	; // Interlaced frame - acquisition on next odd field */
   OLC_FG_FRM_IL_FRAME_NEXT		= $00000004	; // Interlaced frame - acquisition on next field */
   OLC_FG_FRM_FIELD_EVEN			= $00000008	; // Single field - acquisition on next even field */
   OLC_FG_FRM_FIELD_ODD			= $00000010	; // Single field - acquisition on next odd field */
   OLC_FG_FRM_FIELD_NEXT			= $00000020	; // Single field - acquisition on next field */
   OLC_FG_FRM_NON_INTERLACED		= $00000040	; // Non-Interlaced frame - acquisition on next frame */


// Events */
				OLC_FG_EVENT_FIELD = 0 ;		// Event is End of Field (vsync) */
				OLC_FG_EVENT_EXT_HI_TO_LO = 1 ;	// Event is Low-to-High transition on external event line */
				OLC_FG_EVENT_EXT_LO_TO_HI	= 2 ;// Event is High-to-Low transition on external event line */

// Triggers */
        OLC_FG_TRIGGER_NONE = 1;		// There is no hw trigger; sw trigger */
				OLC_FG_TRIGGER_EXTERNAL_LINE = 2 ;		// Trigger on external trigger line */
				OLC_FG_TRIGGER_EVENT = 3 ;			// Trigger on event counter signal */
				OLC_FG_TRIGGER_ONE_EVENT_DELAY = 4 ;		// Trigger on next event after event counter fires */

// Triggers */
        OLC_FG_TRIGMODE_TO_START = 1 ;	// Single trigger starts multiple acquire */
        OLC_FG_TRIGMODE_FOR_EACH = 2 ;	// One trigger for each acquisition in series */

// Strobes */
	OLC_FG_STROBE_NOW= 1 ;
	OLC_FG_STROBE_FRAME_BASED= 2 ;
	OLC_FG_STROBE_FIELD_BASED= 4 ;

// pixel element bit justification enumerations */
	 OLC_FG_JUSTIFY_RIGHT = 0 ;
	 OLC_FG_JUSTIFY_LEFT = 1 ;

// Mono Frame Grabber Linear Memory Capability ("LC") Keys */
	 OLC_FG_LC_UNKNOWN = 0 ;
	 OLC_FG_LC_OPS = 1 ;
	 OLC_FG_LC_LINSIZE = 2;
	 OLC_FG_LC_LINBASE32 = 3;

// Linear memory operation bit masks */
   OLC_FG_LINOP_MULTACQ		= $00000001;


// Mono Frame Grabber Camera Control Capability ("CC") Keys */
	 OLC_FG_CC_UNKNOWN = 0; //
	 OLC_FG_CC_DIG_OUT_COUNT = 1; //
	 OLC_FG_CC_PULSE_OPS = 2 ; //
	 OLC_FG_CC_PULSE_RANGE = 3 ; //
	 OLC_FG_CC_PULSE_RANGE_EXT = 4 ;

// Pulse operation bit masks */
   OLC_FG_PULSE_PING		= $00000001;

// PassthruEx flags */
   OLC_FG_PASSTHRU_DONT_OVERWRITE			= $00000001;	// Dont overwrite a buffer before it's  reset */

// Mono Frame Grabber Passthru Capability ("PC") Keys */
	 OLC_FG_PC_UNKNOWN = 0;
	 OLC_FG_PC_DOES_PASSTHRU			= $0100;
	 OLC_FG_PC_PASSTHRU_MODE_LIMITS		= $0101;
	 OLC_FG_PC_DOES_SOURCE_ORIGIN		= $0110;
	 OLC_FG_PC_SRC_ORIGIN_X_LIMITS		= $0111;
	 OLC_FG_PC_SRC_ORIGIN_Y_LIMITS		= $0112;
	 OLC_FG_PC_DOES_SCALING				= $0120;
	 OLC_FG_PC_SCALE_HEIGHT_LIMITS		= $0121;
	 OLC_FG_PC_SCALE_WIDTH_LIMITS		= $0122;
	 OLC_FG_PC_DOES_PASSTHRU_LUT		= $0123;
	 OLC_FG_PC_MAX_PLUT_INDEX			= $0124;
	 OLC_FG_PC_MAX_PLUT_VALUE			= $0125;
	 OLC_FG_PC_MAX_PALETTE_INDEX		= $0126;
	 OLC_FG_PC_MAX_PALETTE_VALUE		= $0127;
	 OLC_FG_PC_DOES_PASSTHRU_SNAPSHOT	= $0128;

   OLC_FG_PASSTHRU_ASYNC_DIRECT    = $00000001;		// Driver provides direct to display asynchronous passthru */
   OLC_FG_PASSTHRU_SYNC_DIRECT     = $00000002;		// Driver provides direct to display synchronous passthru */
   OLC_FG_PASSTHRU_ASYNC_BITMAP    = $00000004;		// Driver provides bitmap to display asynchronous passthru */
   OLC_FG_PASSTHRU_SYNC_BITMAP     = $00000008;		// Driver provides bitmap to display synchronous passthru */
   OLC_FG_PASSTHRU_ASYNC_BITMAP_EX  = $00000010;		// Driver provides bitmap to display asynchronous passthruex */

// Mono Frame Grabber Memory Capability ("MC") Keys */
	 OLC_FG_MC_UNKNOWN = 0 ;
	 OLC_FG_MC_MEMORY_TYPES = 1 ;
	 OLC_FG_MC_VOL_COUNT = 2 ;
	 OLC_FG_MC_NONVOL_COUNT = 3 ;

// Memory Type Bit Masks */
   OLC_FG_MEM_VOLATILE			= $00000001;		// Driver provides volatile frames */
   OLC_FG_MEM_NON_VOLATILE			= $00000002;		// Driver provides non-volatile frames */

// Used to indicate that next available built-in frame should be allocated. */
   OLC_FG_NEXT_FRAME	= $ffff;


// Memory Types */
    OLC_FG_DEV_MEM_VOLATILE = 1 ;
    OLC_FG_DEV_MEM_NONVOLATILE = 2 ;


// Frame info flags */
   OLC_FG_FRAME_CAN_MAP	= $0001 ;

	OLC_FG_DDI_UNKNOWN = 0;
	OLC_FG_DDI_FAST_PASSTHRU = 1;
	OLC_FG_DDI_OVERLAYS = 2;
	OLC_FG_DDI_TRANSLUCENT_OVERLAYS = 3;
	OLC_FG_DDI_COLOR_OVERLAY = 4;
	OLC_FG_DDI_MULTIPLE_SURFACES = 5;
	OLC_FG_DDI_COLOR_KEY_CONTROL = 6;
	OLC_FG_DDI_OVERLAY_ON_FRAME = 7;
	OLC_FG_DDI_USER_SURFACE_PTR = 8;
	OLC_FG_DDI_PASSTHRU_SYNC_EVENT = 9 ;

// OlFgAddOverlayToFrame Flags */
   OLC_SS_OPAQUE			= $00;
  OLC_SS_TRANSLUCENT		= $01;

// Number of circular buffers
   OLC_FG_MAX_FRAMES		= $1000;


//=======================================================================*/
//==================  Status Code Definitions  ==========================*/
//=======================================================================*/

// Masks for parsing status values */
OLC_STATUS_CODE_MASK		= $00000fff ;
OLC_STATUS_SEV_MASK		= $07000000 ;
OLC_STATUS_IS_APISTATUS_MASK	= $10000000 ;
OLC_STATUS_IS_OL_MASK		= $80000000 ;

// Status Code Severity Levels - bit masks */
OLC_STATUS_SEV_SHIFT =		24;
//OLC_STATUS_SEV_ERROR_MASK	( (ULNG) (((ULNG)OLC_IMG_SEV_ERROR) << OLC_STATUS_SEV_SHIFT) )
//OLC_STATUS_SEV_WARNING_MASK	( (ULNG) (((ULNG)OLC_IMG_SEV_WARNING) << OLC_STATUS_SEV_SHIFT) )
//OLC_STATUS_SEV_INFO_MASK	( (ULNG) (((ULNG)OLC_IMG_SEV_INFO) << OLC_STATUS_SEV_SHIFT) )


// Macros for creating DT-Open Layers API status codes */
{OL_MAKE_APISTATUS(Sev, Code, OlMask)							\
		( (OLT_APISTATUS) ( ((ULNG)(Sev) & OLC_STATUS_SEV_MASK) |			\
				    ((ULNG)(Code) & OLC_STATUS_CODE_MASK) |			\
				    (ULNG) (OlMask) |						\
				    OLC_STATUS_IS_APISTATUS_MASK ) )

OL_MAKE_OL_ERROR_APISTATUS(Code)	( OL_MAKE_APISTATUS(OLC_STATUS_SEV_ERROR_MASK, (Code; OLC_STATUS_IS_OL_MASK) )
OL_MAKE_OL_INFO_APISTATUS(Code)		( OL_MAKE_APISTATUS(OLC_STATUS_SEV_INFO_MASK, (Code; OLC_STATUS_IS_OL_MASK) )
OL_MAKE_OL_WARNING_APISTATUS(Code)	( OL_MAKE_APISTATUS(OLC_STATUS_SEV_WARNING_MASK, (Code; OLC_STATUS_IS_OL_MASK) )


// Macros for creating non-OL status codes with OL format */
OL_MAKE_NONOL_ERROR_APISTATUS(Code)	( OL_MAKE_APISTATUS(OLC_STATUS_SEV_ERROR_MASK, (Code; 0L) )
OL_MAKE_NONOL_INFO_APISTATUS(Code)	( OL_MAKE_APISTATUS(OLC_STATUS_SEV_INFO_MASK, (Code; 0L) )
OL_MAKE_NONOL_WARNING_APISTATUS(Code)	( OL_MAKE_APISTATUS(OLC_STATUS_SEV_WARNING_MASK, (Code; 0L) )}



// Normal completion status */
OLC_STS_NORMAL = 0 ;

// DT-Open Layers general errors (= $1 -> = $ff) */
OLC_STS_NOSHARE		= $1;		// Device is in use and not shareable */
OLC_STS_NOMEM		= $2;		// Unable to allocate required memory */
OLC_STS_NOMEMLOCK	= $3;		// Unable to lock down required memory */
OLC_STS_RANGE		= $4;		// Argument out of range */
OLC_STS_STRUCTSIZ	= $5;		// Structure is wrong size */
OLC_STS_NULL		= $6;		// Attempt to follow NULL pointer or HANDLE */
OLC_STS_BUSY		= $7;		// Device is BUSY and can not process requested */
									//    operation                                 */
OLC_STS_BUFSIZ		= $8;		// Output buffer was not the correct size */
OLC_STS_UNSUPKEY	= $9;		// Unsupported Key Indicator */
OLC_STS_NOASYNC		= $a;		// Unable to accept asynchronous I/O request - queue is */
									//    probably full                                     */
OLC_STS_TIMEOUT		= $b;		// Operation timed out */
OLC_STS_GRANULARITY	= $c;		// Argument within linear range, but not on legal */
									//    increment                                   */
OLC_STS_NODRIVERS	= $d;		// No OL imaging devices installed in system */
OLC_STS_NOOPENDEVICE	= $e;		// Unable to open required device driver */
OLC_STS_NOCLOSEDEVICE	= $f;		// Unable to close specified device driver */
OLC_STS_GETSTATUSFAIL	= $10;	// Unable to retreive status from specified device driver */
OLC_STS_NONOLSTATUS	= $11;	// The specified status was not an OL status code and could not be translated */
OLC_STS_UNKNOWNSTATUS	= $12;	// The specified status appears to be an unknown OL status */
OLC_STS_LOADSTRERR	= $13;	// LoadString failed, unable to load required string. */
OLC_STS_SYSERROR	= $14;	// Internal driver error. */
OLC_STS_FIFO_OVERFLOW	= $15;	// Internal FIFO overflow. */
OLC_STS_FIELD_OVERFLOW	= $16;	// Internal field overflow. */


// General DT-Open Layers Informational status codes (= $1 -> = $ff; */
OLC_STS_PENDING		= $1;	// Job is pending and has not started executing */
OLC_STS_ACTIVE		= $2;	// Job has started executing, but has not completed */
OLC_STS_CANCELJOB	= $3;	// Job was canceled prior to completion */


// General DT-Open Layers warnings (= $1 -> = $ff; */
OLC_STS_CLIP		= $1;	// A data value exceeded the legal range and was */
OLC_STS_NONOLMSG	= $2;	// A unit opened for DT-Open Layers received a message  */
									//     that was not handled.  The message was passed to */
									//     DefDriverProc(;.                                 */
OLC_STS_LOADSTRWARN	= $3;	// LoadString failed, unable to load intended string.  Default string used. */




// DT-Open Layers frame grabber errors (= $100 -> = $1ff; */
OLC_STS_UNSUPMEMTYPE		= $100;	// Memory type not known or supported by this */
										//    driver                                  */
OLC_STS_FRAMENOTAVAILABLE	= $102;	// Frame not available */
OLC_STS_INVALIDFRAMEID		= $103;	// Frame identifier is invalid */
OLC_STS_INVALIDFRAMEHANDLE	= $104;	// Frame handle is not valid */
OLC_STS_INVALIDFRAMERECT	= $105;	// Invalid frame rectangle */
OLC_STS_FRAMENOTALLOCATED	= $106;	// Frame not allocated */
OLC_STS_MAPERROR		= $107;	// Unable to map frame */
OLC_STS_UNMAPERROR		= $108;	// Unable to unmap frame */
OLC_STS_FRAMEISMAPPED		= $109;	// Frame is currently mapped */
OLC_STS_FRAMENOTMAPPED		= $10a;	// Frame is not mapped */
OLC_STS_FRAMELIMITEXCEEDED	= $10b;	// Frame boundary exceeded */
OLC_STS_FRAMEWIDTH		= $10c;	// Frame width is illegal for current */
										//    acquisition setup               */
OLC_STS_CLAMP			= $10d;	// Clamp area is illegal for current */
										//    acquisition setup              */
OLC_STS_VERTICALINC		= $10e;	// Vertical frame increment is illegal for */
										//    current acquisition setup            */
OLC_STS_FIRSTACTPIX		= $10f;	// First active pixel position is illegal for */
                                                                                //    current acquisition setup               */
OLC_STS_ACTPIXCOUNT		= $110;	// Active pixel count is illegal for current */
										//     acquisition setup                     */
OLC_STS_FRAMELEFT		= $111;	// Left side of frame is illegal for current */
										//     acquisition setup                     */
OLC_STS_FRAMETOP		= $112;	// Top of frame is illegal for current */
                                                                                //    acquisition setup                */
OLC_STS_FRAMEHEIGHT		= $113;	// Frame height is illegal for current */
                                                                                //    acquisition setup                */
OLC_STS_ACTLINECOUNT		= $114;	// Active line count is illegal for current */
										//     acquisition setup                    */
OLC_STS_HSYNCSEARCHPOS		= $115;	// Horizontal sync search position is illegal */
										//     for current acquisition setup          */
OLC_STS_VSYNCSEARCHPOS		= $116;	// Vertical sync search position is illegal */
										//     for current acquisition setup        */
OLC_STS_INPUTSOURCE   		= $117;	// Returned if input source channel out of */
                                                                                //    range                                */
OLC_STS_CONTROL       		= $118;	// Returned if set input control function value */
										//     is undefined.                            */
OLC_STS_LUT           		= $119;	// Returned if LUT value out of range */
OLC_STS_BWINVERSION           	= $11a;	// Returned if Black Level > White Level */
OLC_STS_WHITELEVEL           	= $11b;	// Returned if white level cannot be set */
OLC_STS_INTERLACEDHGTGRAN	= $11c;	// Returned if frame height granularity is   */
										//     illegal when frame type is interlaced */
OLC_STS_INTERLACEDTOPGRAN	= $11d;	// Returned if frame top granularity is illegal */
										//     when frame type is interlaced            */
OLC_STS_INVALIDJOBHANDLE	= $11e;	// Returned if job handle is invalid */
OLC_STS_MODECONFLICT		= $11f;	// Returned if attempted operation conflicts with current mode of operation  */
OLC_STS_INVALIDHWND		= $120;	// Invalid window handle */
OLC_STS_INVALIDWNDALIGN	= $121;	// Invalid window alignment */
OLC_STS_PALETTESIZE		= $122;	// Invalid system palette size */
OLC_STS_NODCI			= $123;	// DCI could not be properly accessed */
OLC_STS_PASSTHRULUTRANGE	= $124; // Invalid range passed to PMLut */
OLC_STS_PASSTHRUPALRANGE  = $125; // Invalid range passed to extend palette during passthru */

// DT-Open Layers Frame Grabber DDI Error status codes (= $126 -> = $131; */
OLC_STS_SYS_RES					= $126; // System resource error */
OLC_STS_INVALID_SURFACE_HANDLE	= $127; // Surface Handle invalid */
OLC_STS_FIXED_COLOR				= $128; // Key color can't be changed */
OLC_STS_INVALID_FLAGS			= $129; // Some of the flags are illegal */
OLC_STS_NO_MORE_SURFACE			= $12A; // Driver's Max surfaces reached */
OLC_STS_PASSTHRU_STOPPED		= $12B; // Not in passthru mode */
OLC_STS_NO_DDI					= $12C; // DDI not supported */
OLC_STS_SURFACE_TOO_SMALL		= $12D; // Surface chosen was too small */
OLC_STS_PITCH_TOO_SMALL			= $12E; // Pitch declared was too small */
OLC_STS_NO_IMAGE_IN_FRAME		= $12F; // Pitch declared was too small */
OLC_STS_INVALID_SURFACE_DC		= $130; // Surface Handle DC */
OLC_STS_SURFACE_NOT_SET			= $131; // Surface selected yet */

OLC_STS_NO_VIDEO_SIGNAL   = $132; // No video was detected on the front end */

// The following macros can be used to test successful completion of OLIMGAPI functions */
//OlImgIsOkay(sc)		( (sc) == OLC_STS_NORMAL )
//OlImgIsError(sc)	( ((sc) & OLC_STATUS_SEV_ERROR_MASK) == OLC_STATUS_SEV_ERROR_MASK )
//OlImgIsWarning(sc)	( ((sc) & OLC_STATUS_SEV_WARNING_MASK) == OLC_STATUS_SEV_WARNING_MASK )
//OlImgIsInfo(sc)		( ((sc) & OLC_STATUS_SEV_INFO_MASK) == OLC_STATUS_SEV_INFO_MASK )

	OLC_QUERY_CONTROL_MIN			= $0;
	OLC_QUERY_CONTROL_MAX			= $1;
	OLC_QUERY_CONTROL_GRANULARITY	= $2;
	OLC_QUERY_CONTROL_NOMINAL		= $3;
	OLC_QUERY_CAPABILITY = $4				;
	OLC_QUERY_CONFIGURATION = $5				;
	OLC_CONFIGURE_CONTROL = $6				;
	OLC_READ_CONTROL = $7					;
	OLC_WRITE_CONTROL = $8					;

	OLC_SIGNAL_UNSUPPORTED =$0	;
	OLC_MONO_SIGNAL	 = $1		;
	OLC_YC_SIGNAL	 = $2		;
	OLC_COMPOSITE_SIGNAL  = $3	;
	OLC_RGB_SIGNAL  = $4			;
	OLC_TRIPLE_MONO_SIGNAL  = $5	;
	OLC_DUAL_MONO_SIGNAL  = $6	;


  OLT_CHANNEL_ID = 0 ;

	OLC_IMAGE_UNSUPPORTED	= 0;
	OLC_IMAGE_MONO = $1			;
	OLC_IMAGE_YUV = $2			;
	OLC_IMAGE_RGB	 = $3		;
	OLC_IMAGE_RGB_16  = $4		;
	OLC_IMAGE_RGB_15  = $5		;
	OLC_IMAGE_RGB_24  = $6		;
	OLC_IMAGE_RGB_32  = $7 ;

	OLC_COLOR_UNSUPPORTED	= $0;
	OLC_SET_BRIGHTNESS		 = $1 ;
	OLC_SET_CONTRAST		 = $2 ;
	OLC_SET_V_SAT			 = $3 ;
	OLC_SET_U_SAT			 = $4 ;
	OLC_SET_HUE				 = $5 ;
	OLC_SET_RED_LEVEL		 = $6 ;
	OLC_SET_GREEN_LEVEL		 = $7 ;
	OLC_SET_BLUE_LEVEL		 = $8 ;
	OLC_SET_RED_REF			 = $9 ;
	OLC_SET_GREEN_REF		 = $10 ;
	OLC_SET_BLUE_REF		 = $11 ;
	OLC_SET_RED_OFF			 = $12 ;
	OLC_SET_GREEN_OFF		 = $13 ;
	OLC_SET_BLUE_OFF = $14 ;


	OLC_SYNC_MASTER_UNSUPPORTED	= $00;
	OLC_SYNC_MASTER_ENABLE = $1		;

	OLC_COLOR_INTERFACE_UNSUPPORTED					= $00;
	OLC_QUERY_COLOR_INTERFACE_SIGNAL_TYPE = $1 ;
	OLC_QUERY_COLOR_INTERFACE_STORAGE_MODE = $2 ;
	OLC_QUERY_COLOR_INTERFACE_IMAGE_PARAMETER = $3 ;
	OLC_QUERY_COLOR_INTERFACE_HARDWARE_SCALING = $4 ;
	OLC_QUERY_COLOR_INTERFACE_DIGITAL_IO = $5 ;
	OLC_QUERY_COLOR_INTERFACE_DRAW_ACQUIRED_FRAME = $6 ;
	OLC_QUERY_COLOR_INTERFACE_SYNC_MASTER_MODE = $7 ;
	OLC_QUERY_COLOR_INTERFACE_EXTRACT_FRAME = $8 ;
	OLC_QUERY_COLOR_INTERFACE_DRAW_BUFFER = $9 ;

//     's to simplify SetInputControlValue -> CSYNC for RGB Frame Grabbers
     OLC_RVID0_CSYNC		 = $00000002	; // Sync on channel 0 Red
     OLC_GVID0_CSYNC		 = $00010002	; // Sync on channel 0 Green - default
     OLC_BVID0_CSYNC		 = $00020002	; // Sync on channel 0 Blue
     OLC_RVID1_CSYNC		 = $00030002	; // Sync on channel 1 Red
     OLC_GVID1_CSYNC		 = $00040002	; // Sync on channel 1 Green
     OLC_BVID1_CSYNC		 = $00050002	; // Sync on channel 1 Blue

 //     's to simplify ReadILut/WriteILut for RGB Frame Grabbers
     OLC_RVID0_ILUT	 = $0000	; // channel 0 Red
     OLC_GVID0_ILUT	 = $0001	; // channel 0 Green
     OLC_BVID0_ILUT	 = $0002	; // channel 0 Blue
     OLC_RVID1_ILUT	 = $0003	; // channel 0 Red
     OLC_GVID1_ILUT	 = $0004	; // channel 0 Green
     OLC_BVID1_ILUT	 = $0005	; // channel 1 Blue
     OLC_RGB0_ILUT	 = $0006	; // channel 0 RGB write only
     OLC_RGB1_ILUT	 = $0007	; // channel 1 RGB write only

    	OLC_EF_EXTRACT_1ST			    = $01 ;
    	OLC_EF_EXTRACT_2ND			    = $02 ;
    	OLC_EF_EXTRACT_3RD			    = $04 ;
    	OLC_EF_EXTRACT_ALL			    = $07 ;
    	OLC_EF_BUILD_INTERLACED_FRAME   = $08 ;

//=======================================================================*/
//========================  Type Defintitions  ==========================*/
//=======================================================================*/

// "IDs" used by imaging devices */
//DECLARE_OL_IMG_ID(type)		DECLARE_OL_HDL(IMG, type, ID)

// Imaging Device ID */
//DECLARE_OL_IMG_ID(DEV);

// Image Device Info */
OLC_MAX_ALIAS_STR_SIZE =		20 ;
OLC_MAX_DEVICE_NAME_STR_SIZE	= 20 ;
OLC_MAX_STATUS_MESSAGE_SIZE	= 256 ;


type

    TOLT_IMGDEVINFO = packed record
    	 StructSize : Cardinal ;
	     DeviceType : DWord ;
    	 DeviceId : Cardinal ;
	     Alias : Array[0..OLC_MAX_ALIAS_STR_SIZE-1] of Char ;
    	 DeviceName : Array[0..OLC_MAX_DEVICE_NAME_STR_SIZE-1] of Char ;
       // The following 2 items are recent additions to allow the user to query memory sucessfully allocated by the driver
       HostDeviceMemSize : DWord ;   // Size of the Device linear memory in bytes
       HostLinearMemSize : DWord ;   // Size of the host linear memory in bytes
       end ;
       POLT_IMGDEVINFO = ^TOLT_IMGDEVINFO ;

    TOLT_FG_FRAME_INFO = packed record
	     StructSize : DWord ;		// Size of structure; filled in by caller */
	     BaseAddress : Pointer ;		// Pointer to first pixel in buffer */
	     Flags : DWord ;			// Flags defining certain frame characteristics */
	     {OLT_FG_DEV_MEM} MemType : DWord ;	// Type of device memory from which the frame was created */
	     Width : Word ;			// Number of pixels per line */
	     Height : Word ;			// Number of lines per frame */
	     BytesPerSample : Word ;		// Number of bytes/pixel element */
	     SamplesPerPixel : Word ;		// Number of pixel elements per pixel (ie: RGB color pixel has 3 elements) */
	     HorizontalPitch : Word ;		// Number of pixels between sequentially pixels */
	     VerticalPitch : Word ;		// Number of pixels between the first pixels in sequential rows */
	     BitsPerSample : Word ;		// Number of bits in each element that make up a pixel */
    	 {OLT_FG_JUSTIFY_KEY} BitJustification  : Word ; // Specifies whether bits in pixel element are right or left justified
       Pad : Array[1..6] of Byte ;
       end ;

    TDTOLSession = packed record
        DeviceID : DWord ;
        JobID : DWord ;
        CameraOpen : Boolean ;
        LibraryLoaded : Boolean ;
        ColourSupported : Boolean ;
        AcquisitionInProgress : Boolean ;
        SyncHandle : THandle ;
        OLFG32Hnd : Integer ;
        OLIMG32Hnd : Integer ;
        DTCOLORSDKHnd : Integer ;
        FrameHeightMax : Integer ;
        FrameWidthMax : Integer ;
        NumBytesPerPixel : Integer ;
        PixelDepth : Integer ;
        CameraFrameRate : Single ;
        Left : DWord ;
        Top : DWord ;
        Width : DWord ;
        Height : DWord ;
        NumBytesPerFrame : DWord ;
        MaxMemoryBuffers : Integer ;
        FrameID : Array[0..DTOLMaxBuffers-1] of DWord ;
        FrameAllocated : Array[0..DTOLMaxBuffers-1] of Boolean ;
        FrameCounts : Array[0..DTOLMaxBuffers-1] of DWord ;
        FrameCountsOld : Array[0..DTOLMaxBuffers-1] of DWord ;
        FrameInfo : Array [0..DTOLMaxBuffers-1] of TOLT_FG_FRAME_INFO ;
        pFrameBuffer : Pointer ;
        NumFrames : Integer ;
        MaxFrames : Integer ;
        WaitingForFrame : Integer ;
        end ;

    TOLT_LNG_RNG = packed record
    	 Min : Integer ;			// Minimum value in range */
	     Max : Integer ;			// Maximum value in range */
	     Granularity : Integer ;		// Increment between consecutive units */
	     Nominal : Integer			// Nominal/Default value in range */
       end ;

    // Segmented linear range of long integers */
    TOLT_SEG_LNG_RANGE = packed record
    	 SegmentCount : DWord ;		// Number of segments in this segmented linear range */
	     Range : TOLT_LNG_RNG;		// Description of overall range */
       end ;

    // Linear Range of doubles */
    TOLT_DBL_RANGE = packed record
 	    Min : Double ;			// Minimum value in range */
	    Max : Double ;			// Maximum value in range */
	    Granularity : Double ;		// Increment between consecutive units */
	    Nominal : Double ;		// Nominal/Default value in range */
      end ;

    // Segmented linear range of doubles */
    TOLT_SEG_DBL_RANGE = packed record
    	 SegmentCount : DWord ;		// Number of segments in this segmented linear range */
    	 Range : TOLT_DBL_RANGE ;		// Description of overall range */
       end ;

    // Non-linear range of long integers */
    TOLT_NL_LNG_RNG = packed record
    	 Min : Integer ;			// Minimum value in range */
	     Max : Integer ;			// Maximum value in range */
	     Nominal : Integer ;			// Nominal/Default value in range */
       end ;

    // Rectangle Data Type */
    TOLT_RECT = packed record
    	 x  : Integer ;
       y : Integer ;			// Upper-left corner */
	     Width : Integer ;			// Number of columns */
	     Height : Integer ;			// Number of rows */
       end ;

    // List data types */
    TOLT_LIST_LIMITS = packed record
    	 Count  : Integer ;			// Number of elements in list */
	     Min  : Integer ;			// Minimum value in range */
	     Max  : Integer ;			// Maximum value in range */
	     Nominal  : Integer ;			// Nominal/Default value in range */
       end ;

// Single Frame Acquire Operations Data Type.  This is the data type returned */
//   by the OLC_FG_IC_SINGLE_FRAME_OPS IC query.                              */
    TOLT_FG_SINGLE_FRAME_OPS = packed record
    	 ToDevSync : DWord ;		// Synchronous acquisitions to device memory */
	     ToDevAsync : DWord ;		// Asynchronous acquisitions to device memory */
	     ToHostSync : DWord ;		// Synchronous acquisitions to host memory */
	     ToHostAsync : DWord ;		// Asynchronous acquisitions to host memory */
       end ;


// Multiple Frame Acquire Operations Data Type.  This is the data type returned */
//   by the OLC_FG_IC_MULT_FRAME_OPS IC query.                              */
    TOLT_FG_MULT_FRAME_OPS = packed record
    	ToDevSync : DWord ;		// Synchronous acquisitions to device memory */
	    ToDevAsync : DWord ;		// Asynchronous acquisitions to device memory */
	    ToHostSync : DWord ;		// Synchronous acquisitions to host memory */
	    ToHostAsync : DWord ;		// Asynchronous acquisitions to host memory */
      end ;

    TOLT_SCALE_PARAM   = packed record
      hscale : Word ;
      vscale : Word ;
      end ;

// User's Buffer information
    TOLT_BUFFER_INFO = packed record
      StructSize : LongInt ;	// Size of structure; filled in by caller
	    BufferAddr : Pointer ;	// Pointer to the user allocated memory
	    BufferSize : LongInt ;	// Size (bytes) of buffer point to by BufferAddr
	    Width : LongInt ;		// Number of pixels per line
	    Height : LongInt ;		// Number of lines per frame
	    PixelDepth : LongInt ;	// How many byter per pixel
	    Flags : LongInt ;		// Flags defining certain Buffer characteristics
	    Reserved : LongInt ;		// Reserved for future use
      end ;

TOlImgCloseDevice= function(
                   DeviceId : DWord
                   ) : DWord ; stdcall ;

TOlImgGetDeviceCount= function(
                      var Count : Integer
                      ) : Word ; stdcall ;

TOlImgGetDeviceInfo= function(
                     pDevInfo : Pointer ;
                     ListSize : DWord
                     ) : DWord ; stdcall ;

TOlImgGetStatusMessage= function(
                        {OLT_APISTATUS} Status : DWord ;
                        MessageBuf : PChar ;
                        iBufSize : DWord
                        ) : DWord ; stdcall ;

TOlImgOpenDevice= function(
                  Alias : PChar ;
                  var DevId : DWord
                  ) : DWord ; stdcall ;

TOlImgReset= function(
             DeviceId : DWord
             ) : DWord ; stdcall ;

TOlImgQueryDeviceCaps= function(
                       DeviceId : DWord ;
                       Key : DWord ;
                       pData : Pointer ;
                       DataSize : DWord
                       ) : DWord ; stdcall ;

TOlImgQueryTimeoutPeriod= function(
                          DeviceId : DWord ;
                          var Period : DWord
                          ) : DWord ; stdcall ;

TOlImgSetTimeoutPeriod= function(
                        DeviceId : DWord ;
                        Period : DWord ;
                        var ActualPeriod : DWord
                        ) : DWord ; stdcall ;

TOlFgAcquireFrameToDevice= function(
                           DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord
                           ) : DWord ; stdcall ;

TOlFgAcquireFrameToHost= function(
                         DeviceID: DWord;
                         {OLT_FG_FRAME_ID} FrameId: DWord ;
                         pBuffer : Pointer ;
                         BufSize : DWord
                         ) : DWord ; stdcall ;

TOlFgAsyncAcquireFrameToDevice= function(
                                DeviceID: DWord;
                                {OLT_FG_FRAME_ID} FrameId: DWord ;
                      					{LPOLT_FG_ACQJOB_ID} lpJobId : DWord
                                ) : DWord ; stdcall ;

TOlFgAsyncAcquireFrameToHost= function(
                              DeviceID: DWord;
                              {OLT_FG_FRAME_ID} FrameId: DWord ;
                              pBuffer : Pointer ;
                              BufSize : DWord;
                    					{LPOLT_FG_ACQJOB_ID} var JobId : DWord
                              ) : DWord ; stdcall ;

TOlFgCancelAsyncAcquireJob= function(
                            DeviceID: DWord;
                            {OLT_FG_ACQJOB_ID} JobId : DWord ;
                            {LPOLT_APISTATUS} var JobStatus : Dword
                            ) : DWord ; stdcall ;

TOlFgEnableBasedSourceMode= function(
                            DeviceID: DWord;
                            Enable : LongBool ;
                            BasedSource : Word
                            ) : DWord ; stdcall ;

TOlFgIsAsyncAcquireJobDone= function(
                            DeviceID: DWord;
                            {OLT_FG_ACQJOB_ID} JobId : DWord ;
                            var Done : LongBool ;
                  					var {LPOLT_APISTATUS} lpJobStatus : Dword ;
                            var BytesWrittenToHost : DWord
                            ) : DWord ; stdcall ;

TOlFgQueryBasedSourceMode= function(
                           DeviceID: DWord;
                           var Enable : LongBool ;
                           var BasedSource : Word
                           ) : DWord ; stdcall ;

TOlFgQueryInputCaps= function(
                      DeviceID: DWord;
                      {OLT_FG_INPUT_CAP_KEY} Key : DWord ;
                      pData : Pointer ;
                      DataSize : DWord
                      ) : DWord ; stdcall ;

TOlFgQueryInputControlValue= function(
                             DeviceID: DWord;
                             Source : Word ;
                             {OLT_FG_INPUT_CONTROL} Control : DWord ;
                    				var Data : DWord ) : DWord ; stdcall ;

TOlFgQueryInputVideoSource= function(
                            DeviceID: DWord;
                            var Source : Word
                            ) : DWord ; stdcall ;

TOlFgQueryMultipleTriggerInfo= function(
                               DeviceID: DWord;
                               var {POLT_FG_TRIGGER} Trigger : DWord;
                      				 var TriggerOnLowToHigh : DWord;
                               var Mode : DWord
                               ) : DWord ; stdcall ;

TOlFgQueryTriggerInfo= function(
                       DeviceID: DWord;
                       var Trigger : DWord;
                       var lpTriggerOnLowToHigh : LongBool
                       ) : DWord ; stdcall ;

TOlFgReadInputLUT= function(
                    DeviceID: DWord;
                    Ilut : Word;
                    Start : DWord;
                    Count : DWord;
                    pLutData : Pointer;
					          LutDataSize : DWord
                    ) : DWord ; stdcall ;

TOlFgSetInputControlValue= function(
                           DeviceID: DWord;
                           Source : Word;
                           {OLT_FG_INPUT_CONTROL} Control : Word;
					                 NewData : Integer ;
                           var OldData : Integer
                           ) : DWord ; stdcall ;

TOlFgSetInputVideoSource= function(
                          DeviceID: DWord;
                          NewSource : Word;
                          Var OldSource : Word
                          ) : DWord ; stdcall ;

TOlFgSetMultipleTriggerInfo= function(
                              DeviceID: DWord;
                              {OLT_FG_TRIGGER} NewTrigger : DWord;
                     					TriggerOnLowToHigh : WordBool ;
                              {OLT_FG_TRIGGER_MODE} NewMode : DWord;
                    					var OldTrigger : DWord;
                              var WasTriggerOnLowToHigh : WordBool ;
                    					var OldMode  : DWord
                              ) : DWord ; stdcall ;

TOlFgSetTriggerInfo= function(
                     DeviceID: DWord;
                     {OLT_FG_TRIGGER} NewTrigger : DWord;
                     TriggerOnLowToHigh : WordBool ;
					           var OldTrigger : DWord;
                     var WasTriggerOnLowToHigh : wordBool
                     ) : DWord ; stdcall ;

TOlFgStartEventCounter= function(
                        DeviceID: DWord;
                        {OLT_FG_EVENT} Event : DWord;
                        Count : DWord;
                        bWaitForTrigger : LongBool ;
					              bTriggerOnLowToHigh : LongBool ;
                        bOutputHighOnEvent : LongBool
                        ) : DWord ; stdcall ;

TOlFgStopEventCounter= function(
                       DeviceID: DWord
                       ) : DWord ; stdcall ;

TOlFgWriteInputLUT= function(
                    DeviceID: DWord;
                    Ilut : Word;
                    Start : DWord;
                    Count : DWord;
                    var LutData : DWord
                    ) : DWord ; stdcall ;

TOlFgPing= function(
           DeviceID: DWord;
           PulseWidth : Double ;
           PulseIsHigh : LongBool ;
           WaitForTrigger : LongBool ;
					 TriggerOnLowToHigh : LongBool
           ) : DWord ; stdcall ;

TOlFgQueryCameraControlCaps= function(
                             DeviceID: DWord;
                             {OLT_FG_CAMCTL_CAP_KEY} Key: DWord;
                             pData : Pointer ;
					                   ulDataSize: DWord
                             ) : DWord ; stdcall ;

TOlFgSetDigitalOutputMask= function(
                           DeviceID: DWord;
                           NewMask: DWord;
                           var Oldmask: DWord
                           ) : DWord ; stdcall ;

TOlFgAllocateBuiltInFrame= function(
                           DeviceID: DWord;
                           {OLT_FG_DEV_MEM} MemType: DWord;
                           BufNum: Word;
					                 {LPOLT_FG_FRAME_ID} pFrameId : Pointer
                           ) : DWord ; stdcall ;

TOlFgCopyFrameRect= function(
                    DeviceID: DWord;
                    {OLT_FG_FRAME_ID} SourceFrameId : DWord ;
					          SrcLeft : DWord ;
                    SrcTop : DWord ;
                    SrcWidth : DWord ;
                    Srcheight : DWord ;
					          {OLT_FG_FRAME_ID} DestFrameId : DWord ;
                    DestLeft : DWord ;
                    DestTop : DWord
                    ) : DWord ; stdcall ;

TOlFgDestroyFrame= function(
                   DeviceID: DWord;
                   {OLT_FG_FRAME_ID} FrameId : DWord
                   ) : DWord ; stdcall ;

TOlFgMapFrame= function(
               DeviceID: DWord;
               {OLT_FG_FRAME_ID} FrameId : DWord ;
               var FrameInfo : TOLT_FG_FRAME_INFO
               ) : DWord ; stdcall ;

TOlFgQueryFrameInfo= function(
                      DeviceID: DWord;
                      {OLT_FG_FRAME_ID} FrameId : DWord ;
                      pFrameInfo : Pointer
                      ) : DWord ; stdcall ;

TOlFgQueryMemoryCaps= function(
                      DeviceID: DWord;
                      {OLT_FG_MEM_CAP_KEY} Key : DWord ;
                      pData : Pointer ;
            					DataSize : Dword
                      ) : DWord ; stdcall ;

TOlFgReadContiguousPixels= function(
                           DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                          Count: DWord ;
                          pBuffer : Pointer ;
                          BufSize: DWord
                          ) : DWord ; stdcall ;

TOlFgReadFrameRect= function(
                    DeviceID: DWord;
                    {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                    Width: DWord ;
                    Height: DWord ;
                          pBuffer : Pointer ;
                          BufSize: DWord
                    ) : DWord ; stdcall ;

TOlFgReadPixelList= function(
                    DeviceID: DWord;
                    {OLT_FG_FRAME_ID} FrameId : DWord ;
					          Count: DWord ;
                    pPointList : Pointer ;
                          pBuffer : Pointer ;
                          BufSize: DWord
                    ) : DWord ; stdcall ;

TOlFgUnmapFrame= function(
                 DeviceID: DWord;
                 {OLT_FG_FRAME_ID} FrameId : DWord ;
                  VirtAddr : Pointer
                 ) : DWord ; stdcall ;

TOlFgWriteContiguousPixels= function(
                            DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                          Count: DWord ;
                          pPixelData : Pointer
                            ) : DWord ; stdcall ;

TOlFgWriteFrameRect= function(
                     DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                     Width: DWord ;
                     Height: DWord ;
                     pPixelData : Pointer
                     ) : DWord ; stdcall ;

TOlFgWritePixelList= function(
                      DeviceID: DWord;
                      {OLT_FG_FRAME_ID} FrameId: DWord;
					            Count: DWord ;
                      pPointList : Pointer ;
                      pcPixelData : Pointer
                      ) : DWord ; stdcall ;

TOlFgQueryLinearMemoryCaps= function(
                            DeviceID: DWord;
                            {OLT_FG_FRAME_ID} FrameId : DWord ;
                            pData : Pointer ;
					                  DataSize: DWord
                            ) : DWord ; stdcall ;

TOlFgAsyncAcquireMultipleToLinear= function(
                                   DeviceID: DWord;
                                   Count : Integer ;
					                         Offset : Integer ;
                                   var AcqJobId : DWord
                                   ) : DWord ; stdcall ;

TOlFgAcquireMultipleToDevice= function(
                              DeviceID: DWord;
                              Count : DWord ;
                              var FrameIdList : DWord
                              ) : DWord ; stdcall ;

TOlFgAsyncAcquireMultipleToDevice= function(
                                   DeviceID: DWord;
                                   Count : DWord ;
                          				 var FrameIdList : DWord ;
                                   var AcqJobId : DWord
                                  ) : DWord ; stdcall ;

TOlFgSetPassthruSimScaling= function(
                            DeviceID: DWord;
                            lpRequested : DWord ;
                            lpActual : DWord
                            ) : DWord ; stdcall ;

TOlFgStartSyncPassthruDirect= function(
                              DeviceID: DWord;
                              hwnd : THandle
                              ) : DWord ; stdcall ;

TOlFgStartAsyncPassthruDirect= function(
                               DeviceID: DWord;
                               hwnd : THandle;
                               var PassJobId : DWord
                               ) : DWord ; stdcall ;

TOlFgStartSyncPassthruBitmap= function(
                              DeviceID: DWord;
                              hwnd : THandle;
                              FrameId : DWord
                              ) : DWord ; stdcall ;

TOlFgStartAsyncPassthruBitmap= function(
                               DeviceID: DWord;
                               hwnd : THandle;
                               FrameId : DWord ;
                               var PassJobId : DWord
                               ) : DWord ; stdcall ;

TOlFgSetPassthruSourceOrigin= function(
                              DeviceID: DWord;
                              pSourceOrigin : Pointer
                              ) : DWord ; stdcall ;

TOlFgQueryPassthruSourceOrigin= function(
                                DeviceID: DWord;
                                SourceOrigin : Pointer
                                ) : DWord ; stdcall ;

TOlFgSetPassthruScaling= function(
                         DeviceID: DWord;
                         var Requested : DWord ;
                         var Actual : DWord
                         ) : DWord ; stdcall ;

TOlFgQueryPassthruScaling= function(
                           DeviceID: DWord;
                           var Actual : DWord
                           ) : DWord ; stdcall ;

TOlFgStopAsyncPassthru= function(
                        DeviceID: DWord;
                        PassJobId : DWord ;
                        var JobStatus : DWord
                        ) : DWord ; stdcall ;

TOlFgQueryPassthruCaps= function(
                        DeviceID: DWord;
                        Key : DWord ;
                        pData : Pointer ;
                        DataSize : DWord
                        ) : DWord ; stdcall ;

TOlFgExtendPassthruPalette= function(
                            DeviceID: DWord;
                            Start : Integer ;
                            Count : Integer ;
                            pRGBTripleArray : Pointer
                            ) : DWord ; stdcall ;

TOlFgLoadDefaultPassthruLut= function(
                             DeviceID: DWord
                             ) : DWord ; stdcall ;

TOlFgLoadPassthruLut= function(
                      DeviceID: DWord;
                            Start : Integer ;
                            Count : Integer ;
                            pRGBTripleArray : Pointer
                      ) : DWord ; stdcall ;

TOlFgStartAsyncPassthruEx= function(
                           DeviceID : DWord;
                           hWnd : THandle ;
                           pFrameList : Pointer ;
                           pFrameCount : Pointer ;
                           Count : DWord ;
                           phEvent : Pointer ;
                           Flags : DWord ;
                           pPassJobId : Pointer
                           ) : DWord ; stdcall ;

TDtColorSignalType= function(
                    DeviceID : DWord ;
                    Channel  : DWord;
                    Control : DWord ;
                    var Mode : Dword
                    ) : DWord ; stdcall ;

TDtColorStorageMode= function(
                     DeviceID : DWord ;
                     Channel  : DWord;
                     Control : DWord ;
                     var image_mode : DWord
                     ) : DWord ; stdcall ;

TDtColorImageParameters= function(
                         DeviceID : DWord ;
                         Channel  : DWord;
                         Control : DWord ;
                         var Color  : DWord ;
                         var value  : DWord
                         ) : DWord ; stdcall ;

TDtColorHardwareScaling= function(
                         DeviceID : DWord ;
                         Channel  : DWord;
                         Control : DWord ;
                         var ScaleValue : TOLT_SCALE_PARAM
                         ) : DWord ; stdcall ;

TDtColorDigitalIOControl= function(
                          DeviceID : DWord ;
                          Control : DWord ;
                          Value : Dword
                          ) : DWord ; stdcall ;

TDtColorDrawAcquiredFrame= function(
                           DeviceID : DWord ;
                           HWND : Thandle ;
                           FrameId : DWord
                           ) : DWord ; stdcall ;

TDtColorSyncMasterMode= function(
                        DeviceID : DWord ;
                        Channel  : DWord;
                        Control : DWord ;
                        var Action : Dword ;
                        Value : Dword
                        ) : DWord ; stdcall ;

TDtColorQueryInterface= function(
                        DeviceID : DWord ;
                        var Intface : Dword
                        ) : DWord ; stdcall ;

TDtColorExtractFrametoBuffer= function(
                              DeviceID : DWord ;
                              FrameId : DWord ;
                              lpBuffer : Pointer ;
                              Flags : Dword
                              ) : DWord ; stdcall ;

TDtColorDrawBuffer= function(
                    DeviceID : DWord ;
                    HWND : Thandle ;
                    lpBuffer : Pointer
                    ) : DWord ; stdcall ;


// ----------------------
// Library function calls
// ----------------------

function DTOL_OpenCamera(
          var Session : TDTOLSession ;   // Camera session
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;

procedure DTOL_CloseCamera(
          var Session : TDTOLSession     // Camera session #
          ) ;

procedure DTOL_SetVideoMode(
          var Session : TDTOLSession ;
          Mode : Integer ;               // Video mode
          var FrameWidthMax : Integer ;  // Returns camera frame width
          var FrameHeightMax : Integer ; // Returns camera height width
          var NumBytesPerPixel : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer         // Returns no. bits/pixel
          ) ;

function DTOL_GetVideoMode(
          var Session : TDTOLSession ) : Integer ;

function DTOL_StartCapture(
         var Session : TDTOLSession ;
         var ExposureTime : Double ;
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

procedure DTOL_StopCapture(
          var Session : TDTOLSession              // Camera session #
          ) ;

procedure DTOL_GetImage(
          var Session : TDTOLSession
          ) ;

procedure DTOL_GetCameraGainList( CameraGainList : TStringList ) ;

procedure DTOL_GetCameraVideoModeList(
          var Session : TDTOLSession ;
          List : TStringList ) ;

function DTOL_CheckFrameInterval(
          var Session : TDTOLSession ;
          TriggerMode : Integer ;
          var FrameInterval : Double ) : Integer ;

procedure DTOL_LoadLibrary(
          var Session : TDTOLSession
          )  ;

function DTOL_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;

procedure DTOL_CheckROIBoundaries( var Session : TDTOLSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;

procedure DTOL_CheckError(
          Command : String ;
          ErrNum : Integer ) ;

function DTOL_CharArrayToString( cBuf : Array of Char ) : String ;

var

  OlImgCloseDevice : TOlImgCloseDevice;
  OlImgGetDeviceCount : TOlImgGetDeviceCount;
  OlImgGetDeviceInfo : TOlImgGetDeviceInfo;
  OlImgGetStatusMessage : TOlImgGetStatusMessage;
  OlImgOpenDevice : TOlImgOpenDevice;
  OlImgReset : TOlImgReset;
  OlImgQueryDeviceCaps : TOlImgQueryDeviceCaps;
  OlImgQueryTimeoutPeriod : TOlImgQueryTimeoutPeriod;
  OlImgSetTimeoutPeriod : TOlImgSetTimeoutPeriod;
  OlFgAcquireFrameToDevice : TOlFgAcquireFrameToDevice;
  OlFgAcquireFrameToHost : TOlFgAcquireFrameToHost;
  OlFgAsyncAcquireFrameToDevice : TOlFgAsyncAcquireFrameToDevice;
  OlFgAsyncAcquireFrameToHost : TOlFgAsyncAcquireFrameToHost;
  OlFgCancelAsyncAcquireJob : TOlFgCancelAsyncAcquireJob;
  OlFgEnableBasedSourceMode : TOlFgEnableBasedSourceMode;
  OlFgIsAsyncAcquireJobDone : TOlFgIsAsyncAcquireJobDone;
  OlFgQueryBasedSourceMode : TOlFgQueryBasedSourceMode;
  OlFgQueryInputCaps : TOlFgQueryInputCaps;
  OlFgQueryInputControlValue : TOlFgQueryInputControlValue;
  OlFgQueryInputVideoSource : TOlFgQueryInputVideoSource;
  OlFgQueryMultipleTriggerInfo : TOlFgQueryMultipleTriggerInfo;
  OlFgQueryTriggerInfo : TOlFgQueryTriggerInfo;
  OlFgReadInputLUT : TOlFgReadInputLUT ;
  OlFgSetInputControlValue : TOlFgSetInputControlValue;
  OlFgSetInputVideoSource : TOlFgSetInputVideoSource ;
  OlFgSetMultipleTriggerInfo : TOlFgSetMultipleTriggerInfo ;
  OlFgSetTriggerInfo : TOlFgSetTriggerInfo ;
  OlFgStartEventCounter : TOlFgStartEventCounter ;
  OlFgStopEventCounter : TOlFgStopEventCounter ;
  OlFgWriteInputLUT : TOlFgWriteInputLUT ;
  OlFgPing : TOlFgPing ;
  OlFgQueryCameraControlCaps : TOlFgQueryCameraControlCaps ;
  OlFgSetDigitalOutputMask : TOlFgSetDigitalOutputMask ;
  OlFgAllocateBuiltInFrame : TOlFgAllocateBuiltInFrame ;
  OlFgCopyFrameRect : TOlFgCopyFrameRect ;
  OlFgDestroyFrame : TOlFgDestroyFrame ;
  OlFgMapFrame : TOlFgMapFrame ;
  OlFgQueryFrameInfo : TOlFgQueryFrameInfo ;
  OlFgQueryMemoryCaps : TOlFgQueryMemoryCaps ;
  OlFgReadContiguousPixels : TOlFgReadContiguousPixels ;
  OlFgReadFrameRect : TOlFgReadFrameRect ;
  OlFgReadPixelList : TOlFgReadPixelList ;
  OlFgUnmapFrame : TOlFgUnmapFrame ;
  OlFgWriteContiguousPixels : TOlFgWriteContiguousPixels ;
  OlFgWriteFrameRect : TOlFgWriteFrameRect ;
  OlFgWritePixelList : TOlFgWritePixelList ;
  OlFgQueryLinearMemoryCaps : TOlFgQueryLinearMemoryCaps ;
  OlFgAsyncAcquireMultipleToLinear : TOlFgAsyncAcquireMultipleToLinear ;
  OlFgAcquireMultipleToDevice : TOlFgAcquireMultipleToDevice ;
  OlFgAsyncAcquireMultipleToDevice : TOlFgAsyncAcquireMultipleToDevice ;

  OlFgSetPassthruSimScaling : TOlFgSetPassthruSimScaling ;
  OlFgStartSyncPassthruDirect : TOlFgStartSyncPassthruDirect;
  OlFgStartAsyncPassthruDirect : TOlFgStartAsyncPassthruDirect;
  OlFgStartSyncPassthruBitmap : TOlFgStartSyncPassthruBitmap;
  OlFgStartAsyncPassthruBitmap : TOlFgStartAsyncPassthruBitmap;
  OlFgSetPassthruSourceOrigin : TOlFgSetPassthruSourceOrigin;
  OlFgQueryPassthruSourceOrigin : TOlFgQueryPassthruSourceOrigin;
  OlFgSetPassthruScaling : TOlFgSetPassthruScaling;
  OlFgQueryPassthruScaling : TOlFgQueryPassthruScaling;
  OlFgStopAsyncPassthru : TOlFgStopAsyncPassthru;
  OlFgQueryPassthruCaps : TOlFgQueryPassthruCaps;
  OlFgExtendPassthruPalette : TOlFgExtendPassthruPalette;
  OlFgLoadDefaultPassthruLut : TOlFgLoadDefaultPassthruLut;
  OlFgLoadPassthruLut : TOlFgLoadPassthruLut ;
  OlFgStartAsyncPassthruEx : TOlFgStartAsyncPassthruEx ;

  DtColorSignalType : TDtColorSignalType ;
  DtColorStorageMode :  TDtColorStorageMode ;
  DtColorImageParameters :  TDtColorImageParameters ;
  DtColorHardwareScaling :  TDtColorHardwareScaling ;
  DtColorDigitalIOControl :  TDtColorDigitalIOControl ;
  DtColorDrawAcquiredFrame :   TDtColorDrawAcquiredFrame ;
  DtColorSyncMasterMode :  TDtColorSyncMasterMode ;
  DtColorQueryInterface :  TDtColorQueryInterface ;
  DtColorExtractFrametoBuffer :   TDtColorExtractFrametoBuffer ;
  DtColorDrawBuffer :  TDtColorDrawBuffer  ;

implementation

uses sescam ;

procedure DTOL_LoadLibrary(
          var Session : TDTOLSession
          )  ;
// ----------------------------------------------------------
//  Load library into memory
// ----------------------------------------------------------
var
    LibFileName : string ;
begin

     if Session.LibraryLoaded then Exit ;

     // Load OLIMG32.DLL library
     LibFileName := 'OLIMG32.DLL' ;
     Session.OLIMG32Hnd := LoadLibrary(PChar(LibFileName));

     { Get addresses of procedures in library }
     if Session.OLIMG32Hnd <= 0 then begin
        ShowMessage( 'DT-Open Layer: ' + LibFileName + ' not found!' ) ;
        Exit ;
        end ;

    @OlImgCloseDevice := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgCloseDevice') ;
    @OlImgGetDeviceCount := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgGetDeviceCount') ;
    @OlImgGetDeviceInfo := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgGetDeviceInfo') ;
    @OlImgGetStatusMessage := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgGetStatusMessage') ;
    @OlImgOpenDevice := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgOpenDevice') ;
    @OlImgReset := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgReset') ;
    @OlImgQueryDeviceCaps := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgQueryDeviceCaps') ;
    @OlImgQueryTimeoutPeriod := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgQueryTimeoutPeriod') ;
    @OlImgSetTimeoutPeriod := DTOL_GetDLLAddress(Session.OLIMG32Hnd,'OlImgSetTimeoutPeriod') ;

     // Load OLFG32.DLL library

     LibFileName := 'OLFG32.DLL' ;
     Session.OLFG32Hnd := LoadLibrary(PChar(LibFileName));

     { Get addresses of procedures in library }
     if Session.OLFG32Hnd <= 0 then begin
        ShowMessage( 'DT-Open Layer: ' + LibFileName + ' not found!' ) ;
        Exit ;
        end ;

    @OlFgAcquireFrameToDevice := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAcquireFrameToDevice') ;
    @OlFgAcquireFrameToHost := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAcquireFrameToHost') ;
    @OlFgAsyncAcquireFrameToDevice := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAsyncAcquireFrameToDevice') ;
    @OlFgAsyncAcquireFrameToHost := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAsyncAcquireFrameToHost') ;
    @OlFgCancelAsyncAcquireJob := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgCancelAsyncAcquireJob') ;
    @OlFgEnableBasedSourceMode := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgEnableBasedSourceMode') ;
    @OlFgIsAsyncAcquireJobDone := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgIsAsyncAcquireJobDone') ;
    @OlFgQueryBasedSourceMode := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryBasedSourceMode') ;
    @OlFgQueryInputCaps := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryInputCaps') ;
    @OlFgQueryInputControlValue := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryInputControlValue') ;
    @OlFgQueryInputVideoSource := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryInputVideoSource') ;
    @OlFgQueryMultipleTriggerInfo := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryMultipleTriggerInfo') ;
    @OlFgQueryTriggerInfo := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryTriggerInfo') ;
    @OlFgReadInputLUT := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgReadInputLUT') ;
    @OlFgSetInputControlValue := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetInputControlValue') ;
    @OlFgSetInputVideoSource := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetInputVideoSource') ;
    @OlFgSetMultipleTriggerInfo := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetMultipleTriggerInfo') ;
    @OlFgSetTriggerInfo := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetTriggerInfo') ;
    @OlFgStartEventCounter := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStartEventCounter') ;
    @OlFgStopEventCounter := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStopEventCounter') ;
    @OlFgWriteInputLUT := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgWriteInputLUT') ;
    @OlFgPing := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgPing') ;
    @OlFgQueryCameraControlCaps := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryCameraControlCaps') ;
    @OlFgSetDigitalOutputMask := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetDigitalOutputMask') ;
    @OlFgAllocateBuiltInFrame := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAllocateBuiltInFrame') ;
    @OlFgCopyFrameRect := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgCopyFrameRect') ;
    @OlFgDestroyFrame := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgDestroyFrame') ;
    @OlFgMapFrame := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgMapFrame') ;
    @OlFgQueryFrameInfo := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryFrameInfo') ;
    @OlFgQueryMemoryCaps := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryMemoryCaps') ;
    @OlFgReadContiguousPixels := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgReadContiguousPixels') ;
    @OlFgReadFrameRect := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgReadFrameRect') ;
    @OlFgReadPixelList := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgReadPixelList') ;
    @OlFgUnmapFrame := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgUnmapFrame') ;
    @OlFgWriteContiguousPixels := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgWriteContiguousPixels') ;
    @OlFgWriteFrameRect := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgWriteFrameRect') ;
    @OlFgWritePixelList := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgWritePixelList') ;
    @OlFgQueryLinearMemoryCaps := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryLinearMemoryCaps') ;
    @OlFgAsyncAcquireMultipleToLinear := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAsyncAcquireMultipleToLinear') ;
    @OlFgAcquireMultipleToDevice := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAcquireMultipleToDevice') ;
    @OlFgAsyncAcquireMultipleToDevice := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgAsyncAcquireMultipleToDevice') ;

    @OlFgSetPassthruSimScaling := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetPassthruSimScaling') ;
    @OlFgStartSyncPassthruDirect := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStartSyncPassthruDirect') ;
    @OlFgStartAsyncPassthruDirect := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStartAsyncPassthruDirect') ;
    @OlFgStartSyncPassthruBitmap := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStartSyncPassthruBitmap') ;
    @OlFgSetPassthruSourceOrigin := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetPassthruSourceOrigin') ;
    @OlFgQueryPassthruSourceOrigin := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryPassthruSourceOrigin') ;
    @OlFgSetPassthruScaling := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgSetPassthruScaling') ;
    @OlFgQueryPassthruScaling := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryPassthruScaling') ;
    @OlFgStopAsyncPassthru := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStopAsyncPassthru') ;
    @OlFgQueryPassthruCaps := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgQueryPassthruCaps') ;
    @OlFgExtendPassthruPalette := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgExtendPassthruPalette') ;
    @OlFgLoadDefaultPassthruLut := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgLoadDefaultPassthruLut') ;
    @OlFgLoadPassthruLut := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgLoadPassthruLut') ;
    @OlFgStartAsyncPassthruEx := DTOL_GetDLLAddress(Session.OLFG32Hnd,'OlFgStartAsyncPassthruEx') ;

     // Load DTCOLORSDK.DLL library
     LibFileName := 'DTCOLORSDK.DLL' ;
     Session.DTCOLORSDKHnd := LoadLibrary(PChar(LibFileName));

     { Get addresses of procedures in library }
     if Session.DTCOLORSDKHnd <= 0 then begin
        ShowMessage( 'DT-Open Layer: ' + LibFileName + ' not found!' ) ;
        Exit ;
        end ;


    @DtColorSignalType := DTOL_GetDLLAddress(Session.DTCOLORSDKHnd,'DtColorSignalType') ;
{  DtColorSignalType : TDtColorSignalType ;
  DtColorStorageMode :  TDtColorStorageMode ;
  DtColorImageParameters :  TDtColorImageParameters ;
  DtColorHardwareScaling :  TDtColorHardwareScaling ;
  DtColorDigitalIOControl :  TDtColorDigitalIOControl ;
  DtColorDrawAcquiredFrame :   TDtColorDrawAcquiredFrame ;
  DtColorSyncMasterMode :  TDtColorSyncMasterMode ;
  DtColorQueryInterface :  TDtColorQueryInterface ;
  DtColorExtractFrametoBuffer :   TDtColorExtractFrametoBuffer ;
  DtColorDrawBuffer :  TDtColorDrawBuffer  ;}

    Session.LibraryLoaded := True ;

    end ;


function DTOL_GetDLLAddress(
         Handle : Integer ;
         const ProcName : string ) : Pointer ;
// -----------------------------------------
// Get address of procedure within DLL
// -----------------------------------------
begin
    Result := GetProcAddress(Handle,PChar(ProcName)) ;
    if Result = Nil then
       ShowMessage('DT-Open Layers: ' + ProcName + ' not found') ;
    end ;



function DTOL_OpenCamera(
          var Session : TDTOLSession ;   // Camera session
          CameraInfo : TStringList         // Returns Camera details
          ) : Boolean ;
// --------------------
// Open camera for use
// --------------------
const
    MaxDevices = 10 ;
var
    i,NumCameras : Integer ;
    DeviceInfo : Array[0..MaxDevices] of TOLT_IMGDEVINFO ;
    DeviceAlias,DeviceName : String ;
    LNGRange : TOLT_LNG_RNG ;
    NewVideoSource,OldVideoSource : Word ;
    SupportFeatures,DeviceType : DWord ;
    FrameInfo : TOLT_FG_FRAME_INFO ;
    vIDEOmODE , FrameID : DWord ;
    s : string ;
begin

     Session.CameraOpen := False ;

     CameraInfo.Clear ;

     // Load DLL libray
     DTOL_LoadLibrary(Session)  ;
     if not Session.LibraryLoaded then Exit ;


     DTOL_CheckError( 'DTOL_OpenCamera:OlImgGetDeviceCount',
                      OlImgGetDeviceCount(NumCameras)) ;

     if NumCameras <= 0 then begin
        ShowMessage('DTOL: No cameras available!') ;
        Exit ;
        end ;

     // Get device info
     for i := 0 to MaxDevices-1 do DeviceInfo[i].StructSize := SizeOf(TOLT_IMGDEVINFO) ;
     DTOL_CheckError( 'DTOL_OpenCamera:OlImgGetDeviceInfo',
                      OlImgGetDeviceInfo(@DeviceInfo,SizeOf(DeviceInfo)));

     CameraInfo.Add(format('No. of cameras available: %d',[NumCameras])) ;
    if NumCameras > 1 then begin
       for i := 0 to NumCameras-1 do begin
         DeviceAlias := DeviceInfo[i].Alias ;
         DeviceName := DeviceInfo[i].DeviceName ;
         CameraInfo.Add( format('Dev%d: %s (%s)',
                        [i,DeviceAlias,DeviceName])) ;
         end ;
       end ;

    // Open first available camera
    DTOL_CheckError( 'DTOL_OpenCamera:OlImgOpenDevice',
                     OlImgOpenDevice( DeviceInfo[0].Alias,
                                      Session.DeviceID));

    DeviceAlias := DeviceInfo[0].Alias ;
    DeviceName := DeviceInfo[0].DeviceName ;
    s := 'Dev0: ' + DeviceAlias + '(' + DeviceName + '): ' ;
    DTOL_CheckError( 'DTOL_OpenCamera:OlImgQueryDeviceCaps(OLC_IMG_DC_OL_DEVICE_TYPE)',
                     OlImgQueryDeviceCaps( Session.DeviceID,
                                          OLC_IMG_DC_OL_DEVICE_TYPE,
                                          @DeviceType,
                                          SizeOf(DeviceType))) ;
    if DeviceType = OLC_IMG_DEV_COLOR_FRAME_GRABBER then begin
       Session.ColourSupported := True ;
       CameraInfo.Add(s  + 'Colour frame grabber') ;
       end
    else begin
       CameraInfo.Add(s+ 'Monochrome frame grabber') ;
       Session.ColourSupported := False ;
       end ;

    // Does the board support passthru
    DTOL_CheckError( 'DTOL_OpenCamera:OlImgQueryDeviceCaps(OLC_IMG_DC_SECTIONS)',
                     OlImgQueryDeviceCaps( Session.DeviceID,
                                          OLC_IMG_DC_SECTIONS,
                                          @SupportFeatures,
                                          SizeOf(SupportFeatures))) ;
    if (SupportFeatures and OLC_FG_SECTION_PASSTHRU) = 0 then begin
       CameraInfo.Add('WARNING: Pass through video feature NOT supported!') ;
       end ;
    if (SupportFeatures and OLC_FG_SECTION_MEMORY) = 0 then begin
       CameraInfo.Add('WARNING: Device memory management NOT supported!') ;
       end ;

    // Memory management
    DTOL_CheckError( 'DTOL_OpenCamera:OlFgQueryMemoryCaps(OLC_FG_MC_VOL_COUNT)',
                     OlFgQueryMemoryCaps( Session.DeviceID,
                                         OLC_FG_MC_VOL_COUNT,
                                         @Session.MaxFrames,
                                         SizeOf(Session.MaxFrames))) ;
    // Can't seem to use last two buffer, so no. buffers reduced by 2
    Session.MaxFrames := Session.MaxFrames - 2 ;
    CameraInfo.Add( format('No. of frame buffers supported: %d',
                    [Session.MaxFrames] )) ;

    // Set to input 0
    NewVideoSource := 0 ;
    DTOL_CheckError( 'DTOL_OpenCamera:OlFgSetInputVideoSource',
                     OlFgSetInputVideoSource( Session.DeviceID,
                                              NewVideoSource,
                                              OldVideoSource)) ;

    if Session.ColourSupported then begin
       VideoMode := OLC_MONO_SIGNAL ;
      DTOL_CheckError( 'DTOL_OpenCamera:DtColorSignalType(',
                       DtColorSignalType( Session.DeviceID,
                                          NewVideoSource,
                                          OLC_WRITE_CONTROL,
                                          VideoMode )) ;
      end ;

    // Pixel Depth
    DTOL_CheckError( 'DTOL_OpenCamera:OlFgQueryInputCaps(OLC_FG_IC_PIXEL_DEPTH)',
                     OlFgQueryInputCaps( Session.DeviceID,
                                         OLC_FG_IC_PIXEL_DEPTH,
                                         @Session.NumBytesPerPixel,
                                         SizeOf(Session.NumBytesPerPixel))) ;
    Session.PixelDepth := Session.NumBytesPerPixel*8 ;

    DTOL_CheckError( 'DTOL_OpenCamera:OlFgAllocateBuiltInFrame',
                     OlFgAllocateBuiltInFrame( Session.DeviceID,
                                               OLC_FG_DEV_MEM_VOLATILE,
                                               OLC_FG_NEXT_FRAME,
                                               @FrameID )) ;

    FrameInfo.StructSize := SizeOf(FrameInfo) ;
    DTOL_CheckError( 'DTOL_OpenCamera:OlFgQueryFrameInfo',
                     OlFgQueryFrameInfo( Session.DeviceID,
                                         FrameID,
                                         @FrameInfo )) ;
    Session.FrameWidthMax := FrameInfo.Width ;
    Session.FrameHeightMax := FrameInfo.Height ;

    DTOL_CheckError( 'DTOL_OpenCamera:OlFgDestroyFrame',
                     OlFgDestroyFrame( Session.DeviceID,
                                       FrameID)) ;

    // Clear frame buffers
    for i := 0 to High(Session.FrameID) do Session.FrameAllocated[i] := False ;

    CameraInfo.Add(format('Frame Size: %d x %d (%d bits)',
                   [ Session.FrameWidthMax,
                     Session.FrameHeightMax,
                     Session.PixelDepth])) ;

    if Session.FrameWidthMax > 640 then begin
       Session.CameraFrameRate := 25.0 ;
       CameraInfo.Add('CCIR: 25 frames/sec') ;
       end
    else begin
        Session.CameraFrameRate := 30.0 ;
       CameraInfo.Add('CCIR: 30 frames/sec') ;
       end ;

    Result := True ;
    Session.CameraOpen := True ;

    end ;


procedure DTOL_CloseCamera(
          var Session : TDTOLSession     // Camera session #
          ) ;
// ----------------------------------
// Close camera and unload libraries
// ----------------------------------
begin

    // Stop image capture and clear allocated frames
    DTOL_StopCapture( Session ) ;

    if Session.CameraOpen then begin
       DTOL_CheckError( 'OlImgCloseDevice',
                        OlImgCloseDevice(Session.DeviceID)) ;
       Session.CameraOpen := False ;
       end ;

    // Unload library
    if Session.LibraryLoaded then begin
       FreeLibrary(Session.OLFG32Hnd) ;
       FreeLibrary(Session.OLIMG32Hnd) ;
       FreeLibrary(Session.DTCOLORSDKHnd) ;
       Session.LibraryLoaded := False ;
       end ;

    end ;


procedure DTOL_SetVideoMode(
          var Session : TDTOLSession ;
          Mode : Integer ;               // Video mode
          var FrameWidthMax : Integer ;  // Returns camera frame width
          var FrameHeightMax : Integer ; // Returns camera height width
          var NumBytesPerPixel : Integer ; // Returns bytes/pixel
          var PixelDepth : Integer         // Returns no. bits/pixel
          ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


function DTOL_GetVideoMode(
          var Session : TDTOLSession ) : Integer ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


function DTOL_StartCapture(
         var Session : TDTOLSession ;
         var ExposureTime : Double ;
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
// ------------------------
// Start Image Acquisition
// ------------------------
var
    i : integer ;
    BufferID : DWord ;
    NewTriggerType,OldTriggerType : DWord ;
    OldTriggerLowToHigh : WordBool ;
    OldTriggerMode : Dword ;
begin

    // Stop image capture and clear allocated frames
    DTOL_StopCapture( Session ) ;

    // Update session data
    Session.NumFrames := NumFramesInBuffer ;
    Session.pFrameBuffer := PFrameBuffer ;
    Session.Left := FrameLeft ;
    Session.Width := FrameWidth ;
    Session.Top := FrameTop ;
    Session.Height := FrameHeight ;
    Session.NumBytesPerFrame := FrameWidth*FrameHeight*Session.NumBytesPerPixel ;

    // Create image capture buffers
    for i := 0 to NumFramesInBuffer-1 do begin
        // Allocate new frame
        DTOL_CheckError( 'DTOL_StartCapture:OlFgAllocateBuiltInFrame',
                         OlFgAllocateBuiltInFrame( Session.DeviceID,
                                                   OLC_FG_DEV_MEM_VOLATILE,
                                                   OLC_FG_NEXT_FRAME,
                                                   @BufferID )) ;
       // Map frame into host address space
       // Pointer to buffer returned in FrameInfo[i]
       Session.FrameInfo[i].StructSize := SizeOf(TOLT_FG_FRAME_INFO) ;
       DTOL_CheckError( 'DTOL_GetImage:OlFgMapFrame',
                        OlFgMapFrame( Session.DeviceID,
                                      BufferID,
                                      Session.FrameInfo[i] )) ;

        Session.FrameID[i] := BufferID ;
        Session.FrameAllocated[i] := True ;

        // Clear frame buffer image count
        Session.FrameCounts[i] := 0 ;
        Session.FrameCountsOld[i] := 0 ;
        Session.WaitingForFrame := 0 ;
        end ;

     // Set External Trigger mode
     if ExternalTrigger = CamFreeRun then begin
        NewTriggerType := OLC_FG_TRIGGER_NONE
        end
     else begin
        NewTriggerType := OLC_FG_TRIGGER_EXTERNAL_LINE ;
        end ;

     DTOL_CheckError( 'DTOL_StartCapture:OlFgSetMultipleTriggerInfo',
                      OlFgSetMultipleTriggerInfo( Session.DeviceID,
                      NewTriggerType,
                      True,
                      OLC_FG_TRIGMODE_FOR_EACH,
                      OldTriggerType,
                      OldTriggerLowToHigh,
                      OldTriggerMode )) ;

{     DTOL_CheckError( 'OlFgSetTriggerInfo',
                      OlFgSetTriggerInfo( Session.DeviceID,
                                          NewTrigger,
                                          True,
                                          OldTrigger,
                                          OldTriggerLowToHigh )) ;}

    // Start image capture
    DTOL_CheckError( 'DTOL_StartCapture:OlFgStartAsyncPassthruEx',
                     OlFgStartAsyncPassthruEx( Session.DeviceID,
                                               0,
                                               @Session.FrameID,
                                               @Session.FrameCounts,
                                               Session.NumFrames,
                                               @Session.SyncHandle,
                                               0, {Over-write frames when full}
                                               @Session.JobID )) ;

    Result := True ;
    Session.AcquisitionInProgress := True ;

    end ;


procedure DTOL_StopCapture(
          var Session : TDTOLSession              // Camera session #
          ) ;
// -------------------
// Stop frame capture
// -------------------
var
    i : Integer ;
    JobStatus : Dword ;
begin

    if not Session.CameraOpen then Exit ;
    if not Session.AcquisitionInProgress then Exit ;

    // Stop acquisition
    DTOL_CheckError( 'DTOL_StopCapture:OlFgStopAsyncPassthru',
                     OlFgStopAsyncPassthru( Session.DeviceID,
                                            Session.JobID,
                                            JobStatus )) ;

    // Destroy existing frame
    for i := 0 to High(Session.FrameAllocated) do
        if Session.FrameAllocated[i] then begin

        // Un-map from host address space
        DTOL_CheckError( 'DTOL_StopCapture:OlFgUnmapFrame',
                         OlFgUnmapFrame( Session.DeviceID,
                                         Session.FrameID[i],
                                         Session.FrameInfo[i].BaseAddress)) ;
        // Destroy frame
        DTOL_CheckError( 'DTOL_StopCapture:OlFgDestroyFrame',
                         OlFgDestroyFrame( Session.DeviceID,
                                           Session.FrameID[i])) ;

        Session.FrameAllocated[i] := False ;
        end ;

    Session.AcquisitionInProgress := False ;

    end ;


procedure DTOL_GetImage(
          var Session : TDTOLSession
          ) ;
// ----------------------------------------------------
// Transfer new images from camera to host frame buffer
// ----------------------------------------------------
var
    iFrame,iFrom,iTo,iLine,iPix : Integer ;
    NumNewFrames,FirstNewFrame : Integer ;
    pToBuf,pFromBuf : PByteArray ;
    JobStatus : DWord ;
    FrameInfo : TOLT_FG_FRAME_INFO ;
begin

     if not Session.CameraOpen then Exit ;
     if not Session.AcquisitionInProgress then Exit ;

     // Find new frames since last call

     iFrame := Session.WaitingForFrame ;
     NumNewFrames := 0 ;
     FirstNewFrame := -1 ;
     While (Session.FrameCounts[iFrame] <> Session.FrameCountsOld[iFrame]) or
           (NumNewFrames > (Session.NumFrames div 2)) do begin
           if FirstNewFrame < 0 then FirstNewFrame := iFrame ;
           Session.FrameCountsOld[iFrame] := Session.FrameCounts[iFrame] ;
           Inc(iFrame) ;
           if iFrame >= Session.NumFrames then iFrame := 0 ;
           Inc(NumNewFrames) ;
           end ;
    Session.WaitingForFrame := iFrame ;
     //outputdebugString(PChar(format('Frame %d %d',[Session.WaitingForFrame,FirstnewFrame]))) ;

    // Copy frames to output buffer
    iFrame := FirstNewFrame ;
    while NumNewFrames > 0 do begin

       // To/from buffer pointers
       pToBuf := Pointer(Cardinal(Session.pFrameBuffer) + (Session.NumBytesPerFrame*iFrame)) ;
       pFromBuf := Session.FrameInfo[iFrame].BaseAddress ;

       iTo := 0 ;
       iFrom := (Session.Top*Session.FrameWidthMax) + Session.Left ;
       for iLine := Session.Top to Session.Top + Session.Height - 1 do begin
           for iPix := Session.Left to Session.Left + Session.Width -1 do begin
              iFrom := iLine*Session.FrameWidthMax + iPix ;
              pToBuf^[iTo] := pFromBuf^[iFrom] ;
              Inc(iTo) ;
              end ;
           end ;

       Inc(iFrame) ;
       if iFrame >= Session.NumFrames then iFrame := 0 ;
       Dec(NumNewFrames)
       end ;

    end ;


procedure DTOL_GetCameraGainList( CameraGainList : TStringList ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


procedure DTOL_GetCameraVideoModeList(
          var Session : TDTOLSession ;
          List : TStringList ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


function DTOL_CheckFrameInterval(
          var Session : TDTOLSession ;
          TriggerMode : Integer ;
          var FrameInterval : Double ) : Integer ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin

    if not Session.CameraOpen then Exit ;

    if TriggerMode = camFreeRun then begin
       // Fixed rate in free run mode
       FrameInterval := 1.0/Session.CameraFrameRate ;
       end
    else begin
       // Can be no faster than twice the fixed frame interval
       FrameInterval := Max(FrameInterval, 2.0/Session.CameraFrameRate ) ;
       end ;

    end ;


procedure DTOL_CheckROIBoundaries( var Session : TDTOLSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;
// --------------------------------------------------
// Keep selected region within valid image boundaries
// --------------------------------------------------
begin

    if not Session.CameraOpen then Exit ;

    FFrameLeft := Min(Max(FFrameLeft,0),Session.FrameWidthMax-1) ;
    FFrameRight := Min(Max(FFrameRight,FFrameLeft),Session.FrameWidthMax-1) ;
    FFrameWidth := FFrameRight - FFrameLeft + 1 ;

    FFrameTop := Min(Max(FFrameTop,0),Session.FrameHeightMax-1) ;
    FFrameBottom := Min(Max(FFrameBottom,FFrameTop),Session.FrameHeightMax-1) ;
    FFrameHeight := FFrameBottom - FFrameTop + 1 ;

    end ;


procedure DTOL_CheckError(
          Command : String ;
          ErrNum : Integer
          ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
var
    s : String ;
begin

    ErrNum := ErrNum and $FFFF ;

    if ErrNum = 0 then Exit ;

    Case ErrNum of
      OLC_STS_NOSHARE	:	s := 'Device is in use and not shareable' ;
      OLC_STS_NOMEM : s := ' Unable to allocate required memory ' ;
      OLC_STS_NOMEMLOCK	 : s := ' Unable to lock down required memory ' ;
      OLC_STS_RANGE : s := ' Argument out of range ' ;
      OLC_STS_STRUCTSIZ	 : s := ' Structure is wrong size ' ;
      OLC_STS_NULL : s := ' Attempt to follow NULL pointer or HANDLE ' ;
      OLC_STS_BUSY : s := ' Device is BUSY and can not process requested ' ;
      OLC_STS_BUFSIZ : s := ' Output buffer was not the correct size ' ;
      OLC_STS_UNSUPKEY : s := ' Unsupported Key Indicator ' ;
      OLC_STS_NOASYNC : s := ' Unable to accept asynchronous I/O request - queue is probably full' ;
      OLC_STS_TIMEOUT : s := ' Operation timed out ' ;
      OLC_STS_GRANULARITY	 : s := ' Argument within linear range, but not on legal increment' ;
      OLC_STS_NODRIVERS	 : s := ' No OL imaging devices installed in system ' ;
      OLC_STS_NOOPENDEVICE	 : s := ' Unable to open required device driver ' ;
      OLC_STS_NOCLOSEDEVICE	 : s := ' Unable to close specified device driver ' ;
      OLC_STS_GETSTATUSFAIL	 : s := ' Unable to retreive status from specified device driver ' ;
      OLC_STS_NONOLSTATUS	 : s := ' The specified status was not an OL status code and could not be translated ' ;
      OLC_STS_UNKNOWNSTATUS	 : s := ' The specified status appears to be an unknown OL status ' ;
      OLC_STS_LOADSTRERR	 : s := ' LoadString failed, unable to load required string. ' ;
      OLC_STS_SYSERROR	 : s := ' Internal driver error. ' ;
      OLC_STS_FIFO_OVERFLOW	 : s := ' Internal FIFO overflow. ' ;
      OLC_STS_FIELD_OVERFLOW	 : s := ' Internal field overflow. ' ;
      // General DT-Open Layers Informational status codes ( : s := $1 -> :  $ff; ' ;
//      OLC_STS_PENDING : s := ' Job is pending and has not started executing ' ;
//      OLC_STS_ACTIVE : s := ' Job has started executing, but has not completed ' ;
//      OLC_STS_CANCELJOB	 : s := ' Job was canceled prior to completion ' ;
      // General DT-Open Layers warnings ( : s := $1 -> :  $ff; ' ;
//      OLC_STS_CLIP : s := ' A data value exceeded the legal range and was ' ;
//      OLC_STS_NONOLMSG	 : s := ' A unit opened for DT-Open Layers received a message that was not handled.  The message was passed to DefDriverProc() ' ;
//      OLC_STS_LOADSTRWARN	 : s := ' LoadString failed, unable to load intended string.  Default string used. ' ;
      // DT-Open Layers frame grabber errors ( : s := $100 -> :  $1ff; ' ;
      OLC_STS_UNSUPMEMTYPE : s := ' Memory type not known or supported by this driver' ;
      OLC_STS_FRAMENOTAVAILABLE	 : s := ' Frame not available ' ;
      OLC_STS_INVALIDFRAMEID : s := ' Frame identifier is invalid ' ;
      OLC_STS_INVALIDFRAMEHANDLE : s := ' Frame handle is not valid ' ;
      OLC_STS_INVALIDFRAMERECT	 : s := ' Invalid frame rectangle ' ;
      OLC_STS_FRAMENOTALLOCATED	 : s := ' Frame not allocated ' ;
      OLC_STS_MAPERROR : s := ' Unable to map frame ' ;
      OLC_STS_UNMAPERROR : s := ' Unable to unmap frame ' ;
      OLC_STS_FRAMEISMAPPED : s := ' Frame is currently mapped ' ;
      OLC_STS_FRAMENOTMAPPED : s := ' Frame is not mapped ' ;
      OLC_STS_FRAMELIMITEXCEEDED	 : s := ' Frame boundary exceeded ' ;
      OLC_STS_FRAMEWIDTH : s := ' Frame width is illegal for current acquisition setup' ;
      OLC_STS_CLAMP	 : s := ' Clamp area is illegal for current acquisition setup' ;
      OLC_STS_VERTICALINC : s := ' Vertical frame increment is illegal for current acquisition setup' ;
      OLC_STS_FIRSTACTPIX : s := ' First active pixel position is illegal for current acquisition setup' ;
      OLC_STS_ACTPIXCOUNT : s := ' Active pixel count is illegal for current  acquisition setup' ;
      OLC_STS_FRAMELEFT : s := ' Left side of frame is illegal for current acquisition setup' ;
      OLC_STS_FRAMETOP : s := ' Top of frame is illegal for current acquisition setup' ;
      OLC_STS_FRAMEHEIGHT : s := ' Frame height is illegal for current acquisition setup ' ;
      OLC_STS_ACTLINECOUNT : s := ' Active line count is illegal for current acquisition setup' ;
      OLC_STS_HSYNCSEARCHPOS : s := ' Horizontal sync search position is illegal for current acquisition setup' ;
      OLC_STS_VSYNCSEARCHPOS : s := ' Vertical sync search position is illegal for current acquisition setup' ;
      OLC_STS_INPUTSOURCE    : s := ' Returned if input source channel out of range' ;
      OLC_STS_CONTROL        : s := ' Returned if set input control function value is undefined.' ;
      OLC_STS_LUT            : s := ' Returned if LUT value out of range ' ;
      OLC_STS_BWINVERSION : s := ' Returned if Black Level > White Level ' ;
      OLC_STS_WHITELEVEL  : s := ' Returned if white level cannot be set ' ;
      OLC_STS_INTERLACEDHGTGRAN	 : s := ' Returned if frame height granularity is illegal when frame type is interlaced  ' ;
      OLC_STS_INTERLACEDTOPGRAN	 : s := ' Returned if frame top granularity is illegal when frame type is interlaced' ;
      OLC_STS_INVALIDJOBHANDLE	 : s := ' Returned if job handle is invalid ' ;
      OLC_STS_MODECONFLICT : s := ' Returned if attempted operation conflicts with current mode of operation  ' ;
      OLC_STS_INVALIDHWND : s := ' Invalid window handle ' ;
      OLC_STS_INVALIDWNDALIGN	 : s := ' Invalid window alignment ' ;
      OLC_STS_PALETTESIZE : s := ' Invalid system palette size ' ;
      OLC_STS_NODCI	 : s :=	' DCI could not be properly accessed ' ;
      OLC_STS_PASSTHRULUTRANGE	 : s := ' Invalid range passed to PMLut ' ;
      OLC_STS_PASSTHRUPALRANGE  :  s := ' Invalid range passed to extend palette during passthru ' ;
      // DT-Open Layers Frame Grabber DDI Error status codes ( : s := $126 -> :  $131; ' ;
      OLC_STS_SYS_RES			 : s := ' System resource error ' ;
      OLC_STS_INVALID_SURFACE_HANDLE	 : s := ' Surface Handle invalid ' ;
      OLC_STS_FIXED_COLOR		 : s := ' Key color can''t be changed ' ;
      OLC_STS_INVALID_FLAGS	 : s := ' Some of the flags are illegal ' ;
      OLC_STS_NO_MORE_SURFACE	 : s := ' Driver''s Max surfaces reached ' ;
      OLC_STS_PASSTHRU_STOPPED : s := ' Not in passthru mode ' ;
      OLC_STS_NO_DDI			 : s := ' DDI not supported ' ;
      OLC_STS_SURFACE_TOO_SMALL : s := ' Surface chosen was too small ' ;
      OLC_STS_PITCH_TOO_SMALL	 : s := ' Pitch declared was too small ' ;
      OLC_STS_NO_IMAGE_IN_FRAME : s := ' Pitch declared was too small ' ;
      OLC_STS_INVALID_SURFACE_DC : s := ' Surface Handle DC ' ;
      OLC_STS_SURFACE_NOT_SET	 : s := ' Surface selected yet ' ;
      OLC_STS_NO_VIDEO_SIGNAL   : s :=  ' No video was detected on the front end ' ;
      end ;

    ShowMessage(Command + ' : ' + s) ;

    end ;


function DTOL_CharArrayToString( cBuf : Array of Char ) : String ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;



end.

