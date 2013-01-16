unit DTOpenLayersUnits;
// --------------------------------------------------------------
// Data Translation DT-Open Layers image capture library support
// --------------------------------------------------------------

interface

uses WinTypes,sysutils, classes, dialogs, mmsystem, math, strutils ;

const

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
   OLC_FG_SECTION_PASSTHRU	= $00000010;
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
	 OLC_FG_IC_DOES_COLOR					= $215;


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

    TDTOLSession = packed record
        DeviceID : DWord ;
        LibraryLoaded : Boolean ;
        LibraryHnd : Integer ;
        end ;

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
	     {OLT_FG_DEV_MEM} MemType : Word ;	// Type of device memory from which the frame was created */
	     Width : Word ;			// Number of pixels per line */
	     Height : Word ;			// Number of lines per frame */
	     BytesPerSample : Word ;		// Number of bytes/pixel element */
	     SamplesPerPixel : Word ;		// Number of pixel elements per pixel (ie: RGB color pixel has 3 elements) */
	     HorizontalPitch : Word ;		// Number of pixels between sequentially pixels */
	     VerticalPitch : Word ;		// Number of pixels between the first pixels in sequential rows */
	     BitsPerSample : Word ;		// Number of bits in each element that make up a pixel */
    	 {OLT_FG_JUSTIFY_KEY} BitJustification  : Word ; // Specifies whether bits in pixel element are right or left justified
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


TOlImgCloseDevice= function(
                   DeviceId : DWord
                   ) : DWord ; cdecl ;

TOlImgGetDeviceCount= function(
                      var Count : Integer
                      ) : DWord ; cdecl ;

TOlImgGetDeviceInfo= function(
                     var DevList : TOLT_IMGDEVINFO ;
                     ListSize : DWord
                     ) : DWord ; cdecl ;

TOlImgGetStatusMessage= function(
                        {OLT_APISTATUS} Status : DWord ;
                        MessageBuf : PChar ;
                        iBufSize : DWord
                        ) : DWord ; cdecl ;

TOlImgOpenDevice= function(
                  Alias : PChar ;
                  var DevId : DWord
                  ) : DWord ; cdecl ;

TOlImgReset= function(
             DeviceId : DWord
             ) : DWord ; cdecl ;

TOlImgQueryDeviceCaps= function(
                       DeviceId : DWord ;
                       Key : DWord ;
                       pData : Pointer ;
                       DataSize : DWord
                       ) : DWord ; cdecl ;

TOlImgQueryTimeoutPeriod= function(
                          DeviceId : DWord ;
                          var Period : DWord
                          ) : DWord ; cdecl ;

TOlImgSetTimeoutPeriod= function(
                        DeviceId : DWord ;
                        Period : DWord ;
                        var ActualPeriod : DWord
                        ) : DWord ; cdecl ;

TOlFgAcquireFrameToDevice= function(
                           DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord
                           ) : DWord ; cdecl ;

TOlFgAcquireFrameToHost= function(
                         DeviceID: DWord;
                         {OLT_FG_FRAME_ID} FrameId: DWord ;
                         pBuffer : Pointer ;
                         BufSize : DWord
                         ) : DWord ; cdecl ;

TOlFgAsyncAcquireFrameToDevice= function(
                                DeviceID: DWord;
                                {OLT_FG_FRAME_ID} FrameId: DWord ;
                      					{LPOLT_FG_ACQJOB_ID} lpJobId : DWord
                                ) : DWord ; cdecl ;

TOlFgAsyncAcquireFrameToHost= function(
                              DeviceID: DWord;
                              {OLT_FG_FRAME_ID} FrameId: DWord ;
                              pBuffer : Pointer ;
                              BufSize : DWord;
                    					{LPOLT_FG_ACQJOB_ID} var JobId : DWord
                              ) : DWord ; cdecl ;

TOlFgCancelAsyncAcquireJob= function(
                            DeviceID: DWord;
                            {OLT_FG_ACQJOB_ID} JobId : DWord ;
                            {LPOLT_APISTATUS} var JobStatus : Dword
                            ) : DWord ; cdecl ;

TOlFgEnableBasedSourceMode= function(
                            DeviceID: DWord;
                            Enable : LongBool ;
                            BasedSource : Word
                            ) : DWord ; cdecl ;

TOlFgIsAsyncAcquireJobDone= function(
                            DeviceID: DWord;
                            {OLT_FG_ACQJOB_ID} JobId : DWord ;
                            var Done : LongBool ;
                  					var {LPOLT_APISTATUS} lpJobStatus : Dword ;
                            var BytesWrittenToHost : DWord
                            ) : DWord ; cdecl ;

TOlFgQueryBasedSourceMode= function(
                           DeviceID: DWord;
                           var Enable : LongBool ;
                           var BasedSource : Word
                           ) : DWord ; cdecl ;

TOlFgQueryInputCaps= function(
                      DeviceID: DWord;
                      {OLT_FG_INPUT_CAP_KEY} Key : DWord ;
                      Data : Pointer ;
                      DataSize : DWord
                      ) : DWord ; cdecl ;

TOlFgQueryInputControlValue= function(
                             DeviceID: DWord;
                             Source : Word ;
                             {OLT_FG_INPUT_CONTROL} Control : DWord ;
                    				var Data : DWord ) : DWord ; cdecl ;

TOlFgQueryInputVideoSource= function(
                            DeviceID: DWord;
                            var Source : Word
                            ) : DWord ; cdecl ;

TOlFgQueryMultipleTriggerInfo= function(
                               DeviceID: DWord;
                               var {POLT_FG_TRIGGER} Trigger : DWord;
                      				 var TriggerOnLowToHigh : DWord;
                               var Mode : DWord
                               ) : DWord ; cdecl ;

TOlFgQueryTriggerInfo= function(
                       DeviceID: DWord;
                       var Trigger : DWord;
                       var lpTriggerOnLowToHigh : LongBool
                       ) : DWord ; cdecl ;

TOlFgReadInputLUT= function(
                    DeviceID: DWord;
                    Ilut : Word;
                    Start : DWord;
                    Count : DWord;
                    pLutData : Pointer;
					          LutDataSize : DWord
                    ) : DWord ; cdecl ;

TOlFgSetInputControlValue= function(
                           DeviceID: DWord;
                           Source : Word;
                           {OLT_FG_INPUT_CONTROL} Control : Word;
					                 NewData : Integer ;
                           var OldData : Integer
                           ) : DWord ; cdecl ;

TOlFgSetInputVideoSource= function(
                          DeviceID: DWord;
                          NewSource : Word;
                          Var OldSource : Word
                          ) : DWord ; cdecl ;

TOlFgSetMultipleTriggerInfo= function(
                              DeviceID: DWord;
                              {OLT_FG_TRIGGER} NewTrigger : DWord;
                     					TriggerOnLowToHigh : LongBool ;
                              {OLT_FG_TRIGGER_MODE} NewMode : DWord;
                    					var OldTrigger : DWord;
                              var WasTriggerOnLowToHigh : LongBool ;
                    					var OldMode  : DWord
                              ) : DWord ; cdecl ;

TOlFgSetTriggerInfo= function(
                     DeviceID: DWord;
                     {OLT_FG_TRIGGER} NewTrigger : DWord;
                     TriggerOnLowToHigh : LongBool ;
					           var OldTrigger : DWord;
                     var WasTriggerOnLowToHigh : LongBool
                     ) : DWord ; cdecl ;

TOlFgStartEventCounter= function(
                        DeviceID: DWord;
                        {OLT_FG_EVENT} Event : DWord;
                        Count : DWord;
                        bWaitForTrigger : LongBool ;
					              bTriggerOnLowToHigh : LongBool ;
                        bOutputHighOnEvent : LongBool
                        ) : DWord ; cdecl ;

TOlFgStopEventCounter= function(
                       DeviceID: DWord
                       ) : DWord ; cdecl ;

TOlFgWriteInputLUT= function(
                    DeviceID: DWord;
                    Ilut : Word;
                    Start : DWord;
                    Count : DWord;
                    var LutData : DWord
                    ) : DWord ; cdecl ;

TOlFgPing= function(
           DeviceID: DWord;
           PulseWidth : Double ;
           PulseIsHigh : LongBool ;
           WaitForTrigger : LongBool ;
					 TriggerOnLowToHigh : LongBool
           ) : DWord ; cdecl ;

TOlFgQueryCameraControlCaps= function(
                             DeviceID: DWord;
                             {OLT_FG_CAMCTL_CAP_KEY} Key: DWord;
                             pData : Pointer ;
					                   ulDataSize: DWord
                             ) : DWord ; cdecl ;

TOlFgSetDigitalOutputMask= function(
                           DeviceID: DWord;
                           NewMask: DWord;
                           var Oldmask: DWord
                           ) : DWord ; cdecl ;

TOlFgAllocateBuiltInFrame= function(
                           DeviceID: DWord;
                           {OLT_FG_DEV_MEM} MemType: DWord;
                           BufNum: Word;
					                 var {LPOLT_FG_FRAME_ID} FrameId
                           ) : DWord ; cdecl ;

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
                    ) : DWord ; cdecl ;

TOlFgDestroyFrame= function(
                   DeviceID: DWord;
                   {OLT_FG_FRAME_ID} FrameId : DWord
                   ) : DWord ; cdecl ;

TOlFgMapFrame= function(
               DeviceID: DWord;
               {OLT_FG_FRAME_ID} FrameId : DWord ;
               pFrameInfo : Pointer
               ) : DWord ; cdecl ;

TOlFgQueryFrameInfo= function(
                      DeviceID: DWord;
                      {OLT_FG_FRAME_ID} FrameId : DWord ;
                      pFrameInfo : Pointer
                      ) : DWord ; cdecl ;

TOlFgQueryMemoryCaps= function(
                      DeviceID: DWord;
                      {OLT_FG_MEM_CAP_KEY} Key : DWord ;
                      pData : Pointer ;
            					DataSize : Dword
                      ) : DWord ; cdecl ;

TOlFgReadContiguousPixels= function(
                           DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                          Count: DWord ;
                          pBuffer : Pointer ;
                          BufSize: DWord
                          ) : DWord ; cdecl ;

TOlFgReadFrameRect= function(
                    DeviceID: DWord;
                    {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                    Width: DWord ;
                    Height: DWord ;
                          pBuffer : Pointer ;
                          BufSize: DWord
                    ) : DWord ; cdecl ;

TOlFgReadPixelList= function(
                    DeviceID: DWord;
                    {OLT_FG_FRAME_ID} FrameId : DWord ;
					          Count: DWord ;
                    pPointList : Pointer ;
                          pBuffer : Pointer ;
                          BufSize: DWord
                    ) : DWord ; cdecl ;

TOlFgUnmapFrame= function(
                 DeviceID: DWord;
                 {OLT_FG_FRAME_ID} FrameId : DWord ;
                  VirtAddr : Pointer
                 ) : DWord ; cdecl ;

TOlFgWriteContiguousPixels= function(
                            DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                          Count: DWord ;
                          pPixelData : Pointer
                            ) : DWord ; cdecl ;

TOlFgWriteFrameRect= function(
                     DeviceID: DWord;
                           {OLT_FG_FRAME_ID} FrameId : DWord ;
                  				X: DWord ;
                          Y: DWord ;
                     Width: DWord ;
                     Height: DWord ;
                     pPixelData : Pointer
                     ) : DWord ; cdecl ;

TOlFgWritePixelList= function(
                      DeviceID: DWord;
                      {OLT_FG_FRAME_ID} FrameId: DWord;
					            Count: DWord ;
                      pPointList : Pointer ;
                      pcPixelData : Pointer
                      ) : DWord ; cdecl ;

TOlFgQueryLinearMemoryCaps= function(
                            DeviceID: DWord;
                            {OLT_FG_FRAME_ID} FrameId : DWord ;
                            pData : Pointer ;
					                  DataSize: DWord
                            ) : DWord ; cdecl ;

TOlFgAsyncAcquireMultipleToLinear= function(
                                   DeviceID: DWord;
                                   Count : Integer ;
					                         Offset : Integer ;
                                   var AcqJobId : DWord
                                   ) : DWord ; cdecl ;

TOlFgAcquireMultipleToDevice= function(
                              DeviceID: DWord;
                              Count : DWord ;
                              var FrameIdList : DWord
                              ) : DWord ; cdecl ;

TOlFgAsyncAcquireMultipleToDevice= function(
                                   DeviceID: DWord;
                                   Count : DWord ;
                          				 var FrameIdList : DWord ;
                                   var AcqJobId : DWord
                                  ) : DWord ; cdecl ;

TOlFgSetPassthruSimScaling= function(
                            DeviceID: DWord;
                            lpRequested : DWord ;
                            lpActual : DWord
                            ) : DWord ; cdecl ;

TOlFgStartSyncPassthruDirect= function(
                              DeviceID: DWord;
                              hwnd : THandle
                              ) : DWord ; cdecl ;

TOlFgStartAsyncPassthruDirect= function(
                               DeviceID: DWord;
                               hwnd : THandle;
                               var PassJobId : DWord
                               ) : DWord ; cdecl ;

TOlFgStartSyncPassthruBitmap= function(
                              DeviceID: DWord;
                              hwnd : THandle;
                              FrameId : DWord
                              ) : DWord ; cdecl ;

TOlFgStartAsyncPassthruBitmap= function(
                               DeviceID: DWord;
                               hwnd : THandle;
                               FrameId : DWord ;
                               var PassJobId : DWord
                               ) : DWord ; cdecl ;

TOlFgSetPassthruSourceOrigin= function(
                              DeviceID: DWord;
                              pSourceOrigin : Pointer
                              ) : DWord ; cdecl ;

TOlFgQueryPassthruSourceOrigin= function(
                                DeviceID: DWord;
                                SourceOrigin : Pointer
                                ) : DWord ; cdecl ;

TOlFgSetPassthruScaling= function(
                         DeviceID: DWord;
                         var Requested : DWord ;
                         var Actual : DWord
                         ) : DWord ; cdecl ;

TOlFgQueryPassthruScaling= function(
                           DeviceID: DWord;
                           var Actual : DWord
                           ) : DWord ; cdecl ;

TOlFgStopAsyncPassthru= function(
                        DeviceID: DWord;
                        PassJobId : DWord ;
                        var JobStatus : DWord
                        ) : DWord ; cdecl ;

TOlFgQueryPassthruCaps= function(
                        DeviceID: DWord;
                        Key : DWord ;
                        pData : Pointer ;
                        DataSize : DWord
                        ) : DWord ; cdecl ;

TOlFgExtendPassthruPalette= function(
                            DeviceID: DWord;
                            Start : Integer ;
                            Count : Integer ;
                            pRGBTripleArray : Pointer
                            ) : DWord ; cdecl ;

TOlFgLoadDefaultPassthruLut= function(
                             DeviceID: DWord
                             ) : DWord ; cdecl ;

TOlFgLoadPassthruLut= function(
                      DeviceID: DWord;
                            Start : Integer ;
                            Count : Integer ;
                            pRGBTripleArray : Pointer
                      ) : DWord ; cdecl ;



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

function DTOL_AttributeAvailable(
         var Session : TDTOLSession ;
         AttributeName : PChar ;
         CheckWritable : Boolean
         ) : Boolean ;

procedure DTOL_CheckError( ErrNum : Integer ) ;

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


implementation


procedure DTOL_LoadLibrary(
          var Session : TDTOLSession
          )  ;
// ----------------------------------------------------------
//  Load library into memory
// ----------------------------------------------------------
var
    LibFileName : string ;
begin

     { Load interface DLL library }
     LibFileName := '.DLL' ;
     Session.LibraryHnd := LoadLibrary( PChar(LibFileName));

     { Get addresses of procedures in library }
     if Session.LibraryHnd <= 0 then begin
        ShowMessage( 'DT-Open Layer: ' + LibFileName + ' not found!' ) ;
        Session.LibraryLoaded := False ;
        Exit ;
        end ;

    @OlImgCloseDevice := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgCloseDevice') ;
    @OlImgGetDeviceCount := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgGetDeviceCount') ;
    @OlImgGetDeviceInfo := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgGetDeviceInfo') ;
    @OlImgGetStatusMessage := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgGetStatusMessage') ;
    @OlImgOpenDevice := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgOpenDevice') ;
    @OlImgReset := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgReset') ;
    @OlImgQueryDeviceCaps := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgQueryDeviceCaps') ;
    @OlImgQueryTimeoutPeriod := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgQueryTimeoutPeriod') ;
    @OlImgSetTimeoutPeriod := DTOL_GetDLLAddress(Session.LibraryHnd,'OlImgSetTimeoutPeriod') ;
    @OlFgAcquireFrameToDevice := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAcquireFrameToDevice') ;
    @OlFgAcquireFrameToHost := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAcquireFrameToHost') ;
    @OlFgAsyncAcquireFrameToDevice := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAsyncAcquireFrameToDevice') ;
    @OlFgAsyncAcquireFrameToHost := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAsyncAcquireFrameToHost') ;
    @OlFgCancelAsyncAcquireJob := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgCancelAsyncAcquireJob') ;
    @OlFgEnableBasedSourceMode := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgEnableBasedSourceMode') ;
    @OlFgIsAsyncAcquireJobDone := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgIsAsyncAcquireJobDone') ;
    @OlFgQueryBasedSourceMode := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryBasedSourceMode') ;
    @OlFgQueryInputCaps := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryInputCaps') ;
    @OlFgQueryInputControlValue := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryInputControlValue') ;
    @OlFgQueryInputVideoSource := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryInputVideoSource') ;
    @OlFgQueryMultipleTriggerInfo := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryMultipleTriggerInfo') ;
    @OlFgQueryTriggerInfo := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryTriggerInfo') ;
    @OlFgReadInputLUT := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgReadInputLUT') ;
    @OlFgSetInputControlValue := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetInputControlValue') ;
    @OlFgSetInputVideoSource := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetInputVideoSource') ;
    @OlFgSetMultipleTriggerInfo := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetMultipleTriggerInfo') ;
    @OlFgSetTriggerInfo := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetTriggerInfo') ;
    @OlFgStartEventCounter := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgStartEventCounter') ;
    @OlFgStopEventCounter := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgStopEventCounter') ;
    @OlFgWriteInputLUT := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgWriteInputLUT') ;
    @OlFgPing := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgPing') ;
    @OlFgQueryCameraControlCaps := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryCameraControlCaps') ;
    @OlFgSetDigitalOutputMask := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetDigitalOutputMask') ;
    @OlFgAllocateBuiltInFrame := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAllocateBuiltInFrame') ;
    @OlFgCopyFrameRect := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgCopyFrameRect') ;
    @OlFgDestroyFrame := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgDestroyFrame') ;
    @OlFgMapFrame := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgMapFrame') ;
    @OlFgQueryFrameInfo := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryFrameInfo') ;
    @OlFgQueryMemoryCaps := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryMemoryCaps') ;
    @OlFgReadContiguousPixels := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgReadContiguousPixels') ;
    @OlFgReadFrameRect := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgReadFrameRect') ;
    @OlFgReadPixelList := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgReadPixelList') ;
    @OlFgUnmapFrame := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgUnmapFrame') ;
    @OlFgWriteContiguousPixels := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgWriteContiguousPixels') ;
    @OlFgWriteFrameRect := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgWriteFrameRect') ;
    @OlFgWritePixelList := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgWritePixelList') ;
    @OlFgQueryLinearMemoryCaps := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryLinearMemoryCaps') ;
    @OlFgAsyncAcquireMultipleToLinear := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAsyncAcquireMultipleToLinear') ;
    @OlFgAcquireMultipleToDevice := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAcquireMultipleToDevice') ;
    @OlFgAsyncAcquireMultipleToDevice := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgAsyncAcquireMultipleToDevice') ;

    @OlFgSetPassthruSimScaling := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetPassthruSimScaling') ;
    @OlFgStartSyncPassthruDirect := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgStartSyncPassthruDirect') ;
    @OlFgStartAsyncPassthruDirect := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgStartAsyncPassthruDirect') ;
    @OlFgStartSyncPassthruBitmap := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgStartSyncPassthruBitmap') ;
    @OlFgSetPassthruSourceOrigin := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetPassthruSourceOrigin') ;
    @OlFgQueryPassthruSourceOrigin := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryPassthruSourceOrigin') ;
    @OlFgSetPassthruScaling := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgSetPassthruScaling') ;
    @OlFgQueryPassthruScaling := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryPassthruScaling') ;
    @OlFgStopAsyncPassthru := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgStopAsyncPassthru') ;
    @OlFgQueryPassthruCaps := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgQueryPassthruCaps') ;
    @OlFgExtendPassthruPalette := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgExtendPassthruPalette') ;
    @OlFgLoadDefaultPassthruLut := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgLoadDefaultPassthruLut') ;
    @OlFgLoadPassthruLut := DTOL_GetDLLAddress(Session.LibraryHnd,'OlFgLoadPassthruLut') ;


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
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin

     // Load DLL libray
     if not Session.LibraryLoaded then DTOL_LoadLibrary(Session)  ;
     if not Session.LibraryLoaded then Exit ;

    end ;


procedure DTOL_CloseCamera(
          var Session : TDTOLSession     // Camera session #
          ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin

    // Unload library
    if Session.LibraryLoaded then begin
       FreeLibrary(Session.LibraryHnd) ;
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
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


procedure DTOL_StopCapture(
          var Session : TDTOLSession              // Camera session #
          ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


procedure DTOL_GetImage(
          var Session : TDTOLSession
          ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
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
          var FrameInterval : Double ) : Integer ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


procedure DTOL_CheckROIBoundaries( var Session : TDTOLSession ;
                                   var FFrameLeft : Integer ;
                                   var FFrameRight : Integer ;
                                   var FFrameTop : Integer ;
                                   var FFrameBottom : Integer ;
                                   var FFrameWidth : Integer ;
                                   var FFrameHeight : Integer
                                   ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


function DTOL_AttributeAvailable(
         var Session : TDTOLSession ;
         AttributeName : PChar ;
         CheckWritable : Boolean
         ) : Boolean ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


procedure DTOL_CheckError( ErrNum : Integer ) ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;


function DTOL_CharArrayToString( cBuf : Array of Char ) : String ;
// ----------------------------------------------------------
//
// ----------------------------------------------------------
begin
    end ;



end.

